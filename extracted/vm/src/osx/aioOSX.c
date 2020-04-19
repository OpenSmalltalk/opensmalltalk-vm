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
#include "sqaio.h"
#include "sqMemoryFence.h"

#include <sys/types.h>
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

#define INCOMING_EVENTS_SIZE	50

typedef struct _AioOSXDescriptor {

	int fd;
	void* clientData;
	aioHandler readHandlerFn;
	aioHandler writeHandlerFn;
	struct _AioOSXDescriptor* next;

} AioOSXDescriptor;

AioOSXDescriptor* descriptorList = NULL;

AioOSXDescriptor* AioOSXDescriptor_find(int fd);
void AioOSXDescriptor_remove(int fd);


int kqueueDescriptor;

int signal_pipe_fd[2];

void heartbeat_poll_enter(long microSeconds);
void heartbeat_poll_exit(long microSeconds);

static int aio_handle_events(struct kevent* changes, int numberOfChanges, long microSecondsTimeout);
static void aio_flush_pipe(int fd);

volatile int aio_requests = 0;
volatile int aio_responses = 0;

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

	if(fcntl(signal_pipe_fd[0], F_SETFL, O_NONBLOCK) !=0){
	    logErrorFromErrno("pipe - fcntl");
	}

	EV_SET(&pipeEvent, signal_pipe_fd[0], EVFILT_READ, EV_ADD, 0, 0, NULL);
	aio_handle_events(&pipeEvent, 1, 0);
}

/*
 * I process the changes and then process the events calling the handlers
 * if there is one.
 *
 * I return if messages has been processed.
 * Also I clean up the pipe if there are notifications.
 */

static int
aio_handle_events(struct kevent* changes, int numberOfChanges, long microSecondsTimeout){

	struct kevent incomingEvents[INCOMING_EVENTS_SIZE];
	int keventReturn;

	struct timespec timeout;

	timeout.tv_nsec = (microSecondsTimeout % 1000000) * 1000;
	timeout.tv_sec = microSecondsTimeout / 1000000;

	//I notify the heartbeat of a pause
	heartbeat_poll_enter(microSecondsTimeout);

	keventReturn = kevent(kqueueDescriptor, changes, numberOfChanges, incomingEvents, INCOMING_EVENTS_SIZE, &timeout);

	//I notify the heartbeat of the end of the pause
	heartbeat_poll_exit(microSecondsTimeout);

	if(keventReturn == -1){
		if(errno != EINTR){
			logErrorFromErrno("kevent");
		}
		return 0;
	}

	if(keventReturn == 0){
		sqLowLevelMFence();
		if(aio_requests != aio_responses)
			logError("Unbalanced AIO Requests - Req: %d - Res: %d", aio_requests, aio_responses);

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

	aio_flush_pipe(signal_pipe_fd[0]);

	sqLowLevelMFence();
	if(aio_requests != aio_responses)
		logError("Unbalanced AIO Requests - Req: %d - Res: %d", aio_requests, aio_responses);

	return 1;
}

static void
aio_flush_pipe(int fd){

	int bytesRead;
	char buf[1024];

	do {
		bytesRead = read(fd, &buf, 1024);

		if(bytesRead == -1){

			if(errno == EAGAIN || errno == EWOULDBLOCK){
				return;
			}

			logErrorFromErrno("pipe - read");

			return;
		}

		aio_responses += bytesRead;

	} while(bytesRead > 0);
}


EXPORT(void)
aioFini(void){

}

EXPORT(long)
aioPoll(long microSeconds){
	return aio_handle_events(NULL, 0, microSeconds);
}

EXPORT(void)
aioInterruptPoll(){
	int n;

	n = write(signal_pipe_fd[1], "1", 1);
	if(n != 1){
		logErrorFromErrno("write to pipe");
	}

	aio_requests += 1;
	sqLowLevelMFence();
}

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

	aio_handle_events(newEvents, cant, 0);
}

EXPORT(void)
aioDisable(int fd){
	aioSuspend(fd, AIO_RWX);
	AioOSXDescriptor_remove(fd);
}

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

	aio_handle_events(newEvents, 2, 0);
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
