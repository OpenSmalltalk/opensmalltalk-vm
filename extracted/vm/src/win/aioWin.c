#include "pharo.h"
#include "sqaio.h"

#include "windows.h"

typedef struct _AioFileDescriptor {

	int fd;
	void* clientData;
	int flags;
	int mask;
	aioHandler handlerFn;
	HANDLE handle;

	struct _AioFileDescriptor* next;

} AioFileDescriptor;

AioFileDescriptor* fileDescriptorList = NULL;

HANDLE interruptEvent;

AioFileDescriptor * aioFileDescriptor_new(){

	AioFileDescriptor* last;
	AioFileDescriptor* aNewFD = malloc(sizeof(AioFileDescriptor));

	if(fileDescriptorList == NULL){
		fileDescriptorList = aNewFD;
		return aNewFD;
	}

	last = fileDescriptorList;

	while(last->next != NULL){
		last = last->next;
	}

	last->next = aNewFD;
	return aNewFD;
}

AioFileDescriptor * aioFileDescriptor_find(int fd){

	AioFileDescriptor* found;

	if(fileDescriptorList == NULL){
		return NULL;
	}

	found = fileDescriptorList;

	while(found != NULL && found->fd != fd){
		found = found->next;
	}

	return found;
}

void aioFileDescriptor_remove(int fd){

	AioFileDescriptor* found;
	AioFileDescriptor* previous;

	if(fileDescriptorList == NULL){
		return;
	}

	found = fileDescriptorList;
	previous = NULL;

	while(found != NULL && found->fd != fd){
		previous = found;
		found = found->next;
	}

	if(!found) {
		return;
	}

	if(previous == NULL){
		fileDescriptorList = found->next;
	}else{
		previous->next = found->next;
	}

	WSACloseEvent(found->handle);

	free(found);
}

long aioFileDescriptor_size(){
	AioFileDescriptor* element = fileDescriptorList;
	long count = 0;

	while(element){
		count++;
		element = element->next;
	}

	return count;
}

void aioFileDescriptor_fillHandles(HANDLE* handles){
	AioFileDescriptor* element = fileDescriptorList;
	long index = 0;

	while(element){
		handles[index] = element->handle;
		index++;
		element = element->next;
	}

}

void aioFileDescriptor_signal_atIndex(long signaledIndex){

	AioFileDescriptor* element = fileDescriptorList;
	long count = 0;

	while(element){

		if(count == signaledIndex){

			/**
			 * The event should be reset once it has been processed.
			 */
			WSAResetEvent(element->handle);

			fd_set read;
			fd_set write;
			fd_set error;

			FD_ZERO(&read);
			FD_ZERO(&write);
			FD_ZERO(&error);

			struct timeval tm;

			tm.tv_sec = 0;
			tm.tv_usec = 0;

			if(element->mask & AIO_R){
				FD_SET(element->fd, &read);
			}

			if(element->mask & AIO_W){
				FD_SET(element->fd, &write);
			}

			if(element->mask & AIO_X){
				FD_SET(element->fd, &error);
			}

			select(element->fd + 1, &read, &write, &error, &tm);

			if(FD_ISSET(element->fd, &read)){
				element->handlerFn(element->fd, element->clientData, AIO_R);
			}
			if(FD_ISSET(element->fd, &write)){
				element->handlerFn(element->fd, element->clientData, AIO_W);
			}
			if(FD_ISSET(element->fd, &error)){
				element->handlerFn(element->fd, element->clientData, AIO_X);
			}
		}

		count++;
		element = element->next;
	}
}

EXPORT(void) aioInit(void){
	interruptEvent = CreateEventW(NULL, TRUE, FALSE, L"InterruptEvent");
	if(!interruptEvent){
		perror("CreateEventEx");
		exit(1);
	}
}

EXPORT(void) aioFini(void){
	CloseHandle(interruptEvent);
}

EXPORT(void) aioEnable(int fd, void *clientData, int flags){
	AioFileDescriptor * aioFileDescriptor;

	aioFileDescriptor = aioFileDescriptor_find(fd);
	if(!aioFileDescriptor){
		aioFileDescriptor = aioFileDescriptor_new();
	}

	aioFileDescriptor->fd = fd;
	aioFileDescriptor->clientData = clientData;
	aioFileDescriptor->flags = flags;
	aioFileDescriptor->handle = (HANDLE)WSACreateEvent();
	WSAEventSelect(aioFileDescriptor->fd, aioFileDescriptor->handle, 0);

	aioFileDescriptor->next = NULL;


	u_long iMode = 1;
	int iResult;

	iResult = ioctlsocket(fd, FIONBIO, &iMode);
	if (iResult != NO_ERROR)
		perror("ioctlsocket(FIONBIO, 1)");

}

EXPORT(void) aioHandle(int fd, aioHandler handlerFn, int mask){
	AioFileDescriptor * aioFileDescriptor;
	aioFileDescriptor = aioFileDescriptor_find(fd);

	aioFileDescriptor->handlerFn = handlerFn;
	aioFileDescriptor->mask = mask;

	/**
	 * Remember to reset the event once is processed
	 */

	WSAEventSelect(aioFileDescriptor->fd, aioFileDescriptor->handle, FD_READ | FD_WRITE | FD_CLOSE | FD_OOB | FD_ACCEPT | FD_CONNECT);

}

EXPORT(void) aioSuspend(int fd, int mask){
	/**
	 * TODO: It is not used, so we don't implement it now
	 */
}

EXPORT(void) aioDisable(int fd){
	aioFileDescriptor_remove(fd);
}

EXPORT(long) aioPoll(long microSeconds){

	int size = aioFileDescriptor_size();
	HANDLE* handlesToQuery;
	DWORD returnValue;
	long signaledIndex;
	AioFileDescriptor* signaled;

	handlesToQuery = malloc(sizeof(HANDLE) * (size+1));
	aioFileDescriptor_fillHandles(handlesToQuery);

	/*
	 * We pass the interrupt event as the last handler
	 */
	handlesToQuery[size] = interruptEvent;

	returnValue = WaitForMultipleObjectsEx(size + 1, handlesToQuery, FALSE, microSeconds / 1000, FALSE);

	if(returnValue == WAIT_TIMEOUT){
		return 0;
	}

	if(returnValue == WAIT_FAILED){
		perror("aioPoll");
		logError("Error aioPoll: %ld", GetLastError());
		return 0;
	}

	signaledIndex = returnValue - WAIT_OBJECT_0;


	/*
	 * If it is the first is the interrupt event that we use to break the poll.
	 * If it is interrupted we don't need to process, but we need to clear the interrupt event
	 * As the WaitForMultipleObjects signals in the order it find it, if it arrives to the last handle
	 * there are no events in the other handles
	 */
	if(signaledIndex == size){
		ResetEvent(interruptEvent);
		return 0;
	}

	aioFileDescriptor_signal_atIndex(signaledIndex);

	return 1;
}

EXPORT(void) aioInterruptPoll(){
	SetEvent(interruptEvent);
}


EXPORT(void) aioWaitIfInPoll(){

}
