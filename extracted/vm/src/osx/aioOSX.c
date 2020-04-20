/*
 * I am a new implementation of AIO using kqueue for OSX
 *
 * This version is supposed to work correctly with pipes and also
 * it is supposed to be faster and cheaper.
 *
 * Sometimes... I think it is too good to be true...
 *
 */

#include "sqaio.h"
#include "pharovm/debug.h"
#include "pharovm/semaphores/platformSemaphore.h"
#include "sqaio.h"
#include "sqMemoryFence.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/event.h>
#include <sys/time.h>
#include <errno.h>

#include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>


#ifndef NULL
# define NULL	0
#endif

#ifndef true
# define true	1
#endif

#ifndef false
# define false	0
#endif


#define INCOMING_EVENTS_SIZE	50

/*
 * This is the struct that I am keeping for the registered FD
 */
typedef struct _AioOSXDescriptor {

	int fd;
	void* clientData;
	aioHandler readHandlerFn;
	aioHandler writeHandlerFn;
	struct _AioOSXDescriptor* next;

} AioOSXDescriptor;

/*
 * I have to keep a list of the registered FDs as the operations are divided in two functions
 * I only need to use the aioHandle, but I need information from the aioEnable
 */
AioOSXDescriptor* descriptorList = NULL;

/*
 * I can access the elements in the list
 */
AioOSXDescriptor* AioOSXDescriptor_find(int fd);
void AioOSXDescriptor_remove(int fd);

/*
 * This is kqueue used in the poll of the events.
 */
int kqueueDescriptor;

/*
 * This is the pipe used to notify of interruptions in the AIO process.
 */
int signal_pipe_fd[2];

/*
 * These functions are used to notify the heartbeat if we are entering and leaving a long pause.
 * Maybe the heartbeat want to stop if we are in a long pause.
 */
void heartbeat_poll_enter(long microSeconds);
void heartbeat_poll_exit(long microSeconds);

static int aio_handle_events(struct kevent* changes, int numberOfChanges, long microSecondsTimeout, int flushingPipe);
static void aio_flush_pipe(int fd);

/*
 * This is important, the AIO poll should only do a long pause if there is no pending signals for semaphores.
 * Check ExternalSemaphores to understand this function.
 */
int isPendingSemaphores();

/*
 * The access to the pendingInterruption variable is done through the use of a mutex
 */
Semaphore * interruptFIFOMutex;
volatile int pendingInterruption = 0;

/*
 * I initialize the AIO infrastructure
 */
EXPORT(void)
aioInit(void){
	struct kevent pipeEvent;

	if((kqueueDescriptor = kqueue()) < 0) {
		logErrorFromErrno("kqueue");
	}

	if (pipe(signal_pipe_fd) != 0) {
	    logErrorFromErrno("pipe");
	    exit(-1);
	}

	int arg;
	if ((arg = fcntl(signal_pipe_fd[0], F_GETFL, 0)) < 0)
		logErrorFromErrno("fcntl(F_GETFL)");
	if (fcntl(signal_pipe_fd[0], F_SETFL, arg | O_NONBLOCK | O_ASYNC) < 0)
		logErrorFromErrno("fcntl(F_SETFL, O_ASYNC)");

	if ((arg = fcntl(signal_pipe_fd[1], F_GETFL, 0)) < 0)
		logErrorFromErrno("fcntl(F_GETFL)");
	if (fcntl(signal_pipe_fd[1], F_SETFL, arg | O_NONBLOCK | O_ASYNC | O_APPEND) < 0)
		logErrorFromErrno("fcntl(F_SETFL, O_ASYNC)");


	interruptFIFOMutex = platform_semaphore_new(1);

	EV_SET(&pipeEvent, signal_pipe_fd[0], EVFILT_READ, EV_ADD | EV_POLL, 0, 0, NULL);
	aio_handle_events(&pipeEvent, 1, 0, false);
}

/*
 * I process the changes and then process the events calling the handlers
 * if there is one.
 *
 * I return if messages has been processed.
 * Also I clean up the pipe if there are notifications.
 */

static int
aio_handle_events(struct kevent* changes, int numberOfChanges, long microSecondsTimeout, int flushingPipe){

	struct kevent incomingEvents[INCOMING_EVENTS_SIZE];
	int keventReturn;

	struct timespec timeout;

	//I notify the heartbeat of a pause
	heartbeat_poll_enter(microSecondsTimeout);


	timeout.tv_nsec = (microSecondsTimeout % 1000000) * 1000;
	timeout.tv_sec = microSecondsTimeout / 1000000;
	keventReturn = kevent(kqueueDescriptor, changes, numberOfChanges, incomingEvents, INCOMING_EVENTS_SIZE, &timeout);

	//I notify the heartbeat of the end of the pause
	heartbeat_poll_exit(microSecondsTimeout);

	if(keventReturn == -1){
		if(errno != EINTR){
			logErrorFromErrno("kevent");
		}
		return 0;
	}

	if(flushingPipe)
		aio_flush_pipe(signal_pipe_fd[0]);

	if(keventReturn == 0){
		sqLowLevelMFence();
		if(flushingPipe)
			return 1;

		return 0;
	}

	for(int index = 0; index < keventReturn; index++){
		//First I check if the event is an error in the registration
		if((incomingEvents[index].flags & EV_ERROR) && (incomingEvents[index].flags & EV_ADD)){
			int previousErrno = errno;

			logError("Error registering FD: %d", (int) incomingEvents[index].ident);
			errno = incomingEvents[index].data;
			logErrorFromErrno("Registering event");
			errno = previousErrno;
		}else{
			//If the event is not of the signal pipe I process them
			if(incomingEvents[index].ident != signal_pipe_fd[0]){
				//If not is a regular registered FD
				AioOSXDescriptor *descriptor = (AioOSXDescriptor*)incomingEvents[index].udata;

				if((incomingEvents[index].filter & EVFILT_READ) == EVFILT_READ){
					if(descriptor->readHandlerFn)
						descriptor->readHandlerFn(incomingEvents[index].ident, descriptor->clientData, AIO_R);
				}

				if((incomingEvents[index].filter & EVFILT_WRITE) == EVFILT_WRITE){
					if(descriptor->writeHandlerFn)
						descriptor->writeHandlerFn(incomingEvents[index].ident, descriptor->clientData, AIO_W);
				}
			}
		}
	}

	return 1;
}

/*
 * A helper function to clean the signaling pipe.
 */
static void
aio_flush_pipe(int fd){

	int bytesRead;
	char buf[1024];

	interruptFIFOMutex->wait(interruptFIFOMutex);
	if(pendingInterruption){
		pendingInterruption = false;
	}

	do {
		bytesRead = read(fd, &buf, 1024);

		if(bytesRead == -1){

			if(errno == EAGAIN || errno == EWOULDBLOCK){
				interruptFIFOMutex->signal(interruptFIFOMutex);
				return;
			}

			logErrorFromErrno("pipe - read");

			interruptFIFOMutex->signal(interruptFIFOMutex);
			return;
		}

	} while(bytesRead > 0);

	interruptFIFOMutex->signal(interruptFIFOMutex);
}

/*
 * There is no implementation of the shutdown.
 */
EXPORT(void)
aioFini(void){

}

/*
 * This is the entry point to the aioPoll
 * The parameter is the maximum time the poll will stop.
 * The pause can be smaller if there are pending interruptions or pending signals to semaphores
 * from external semaphores.
 * Also if there is IO operations it will return ASAP.
 */
EXPORT(long)
aioPoll(long microSeconds){

	long timeout;

	interruptFIFOMutex->wait(interruptFIFOMutex);

	if(pendingInterruption || isPendingSemaphores()){
		timeout = 0;
	}else{
		timeout = microSeconds;
	}

	if(pendingInterruption){
		pendingInterruption = false;
	}

	interruptFIFOMutex->signal(interruptFIFOMutex);


	return aio_handle_events(NULL, 0, timeout, true);
}

/*
 * With this is is possible to interrupt a long AIO poll.
 * The external semaphores uses this function to interrupt the poll loop.
 */
EXPORT(void)
aioInterruptPoll(){
	int n;

	n = write(signal_pipe_fd[1], "1", 1);
	if(n != 1){
		logErrorFromErrno("write to pipe");
	}
	fsync(signal_pipe_fd[1]);

	interruptFIFOMutex->wait(interruptFIFOMutex);
	pendingInterruption = true;
	interruptFIFOMutex->signal(interruptFIFOMutex);
}

/*
 * I am part of the API of AIO
 * I enable the FD to use AIO.
 * The possible flags are here: AIO_EXT if the FD is external (and we should not change its properties).
 * This function should be call to each FD to use.
 */
EXPORT(void)
aioEnable(int fd, void *clientData, int flags){
	AioOSXDescriptor * descriptor;

	descriptor = AioOSXDescriptor_find(fd);

	if(descriptor == NULL){
		descriptor = malloc(sizeof(AioOSXDescriptor));
		descriptor->readHandlerFn = NULL;
		descriptor->writeHandlerFn = NULL;
		descriptor->next = descriptorList;
		descriptorList = descriptor;
	}

	descriptor->fd = fd;
	descriptor->clientData = clientData;

	if ((flags & AIO_EXT) != AIO_EXT) {
		/*
		 * enable non-blocking asynchronous i/o and delivery of SIGIO
		 * to the active process
		 */
		int	arg;

		if (fcntl(fd, F_SETOWN, getpid()) < 0)
			logErrorFromErrno("fcntl(F_SETOWN, getpid())");
		if ((arg = fcntl(fd, F_GETFL, 0)) < 0)
			logErrorFromErrno("fcntl(F_GETFL)");
		if (fcntl(fd, F_SETFL, arg | O_NONBLOCK | O_ASYNC) < 0)
			logErrorFromErrno("fcntl(F_SETFL, O_ASYNC)");
	}
}

/*
 * This function is part of the API
 * This is used to suspend the receive of events.
 * The mask parameter says which handlers to suspend, it can be any combinatio of
 *
 * - AIO_R
 * - AIO_W
 */
EXPORT(void)
aioSuspend(int fd, int mask){
	int cant = 0;
	int nextIndex = 0;

	struct kevent newEvents[2];

	AioOSXDescriptor *descriptor = AioOSXDescriptor_find(fd);

	if(descriptor == NULL){
		logWarn("Suspending a FD that is not present: %d - IGNORING", fd);
		return;
	}

	if((mask & AIO_R) == AIO_R){
		descriptor->readHandlerFn = NULL;

		EV_SET(&newEvents[nextIndex], fd, EVFILT_READ, EV_DELETE, 0, 0, descriptor);

		nextIndex++;
		cant++;
	}

	if((mask & AIO_W) == AIO_W){
		descriptor->writeHandlerFn = NULL;

		EV_SET(&newEvents[nextIndex], fd, EVFILT_WRITE, EV_DELETE, 0, 0, descriptor);

		nextIndex++;
		cant++;
	}

	aio_handle_events(newEvents, cant, 0, false);
}

/*
 * I disable all the events of a given FD and I forget about it!
 */
EXPORT(void)
aioDisable(int fd){
	aioSuspend(fd, AIO_RWX);
	AioOSXDescriptor_remove(fd);
}

/*
 * This function is part of the API
 * This is used to enable the receive of events.
 * The mask parameter says which handlers to receive with this handle, it can be any combination of:
 *
 * - AIO_R
 * - AIO_W
 *
 * Once the event arrives and the handle is notified, it will be disabled.
 * If the same event is desired again, it should be re-register.
 */

EXPORT(void)
aioHandle(int fd, aioHandler handlerFn, int mask){
	struct kevent newEvents[2];

	AioOSXDescriptor *descriptor = AioOSXDescriptor_find(fd);

	if(descriptor == NULL){
		logWarn("Enabling a FD that is not present: %d - IGNORING", fd);
		return;
	}

	int hasRead = (mask & AIO_R) == AIO_R;
	int hasWrite = (mask & AIO_W) == AIO_W;

	descriptor->readHandlerFn = hasRead ? handlerFn : NULL;
	EV_SET(&newEvents[0], fd, EVFILT_READ, hasRead?(EV_ADD | EV_ONESHOT):EV_DELETE, 0, 0, descriptor);

	descriptor->writeHandlerFn = hasWrite ? handlerFn : NULL;
	EV_SET(&newEvents[1], fd, EVFILT_WRITE, hasWrite?(EV_ADD | EV_ONESHOT):EV_DELETE, 0, 0, descriptor);

	aio_handle_events(newEvents, 2, 0, false);
}

AioOSXDescriptor* AioOSXDescriptor_find(int fd){
	AioOSXDescriptor* found;

	found = descriptorList;
	while(found != NULL){
		if(found->fd == fd)
			return found;
		found = found->next;
	}

	return NULL;
}

void AioOSXDescriptor_remove(int fd){
	AioOSXDescriptor* found;
	AioOSXDescriptor* prev = NULL;

	found = descriptorList;

	while(found != NULL){

		if(found->fd == fd){
			if(descriptorList == found){
				descriptorList = found->next;
			}else{
				prev->next = found->next;
			}
			free(found);
			return;
		}
		prev = found;
		found = found->next;
	}

}
