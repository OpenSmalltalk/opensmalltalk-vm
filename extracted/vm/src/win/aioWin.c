#include "pharovm/pharo.h"
#include "sqaio.h"

#include "windows.h"

typedef struct _AioFileDescriptor {

	int fd;
	void* clientData;
	int flags;
	int mask;
	aioHandler handlerFn;

	HANDLE readEvent;
	HANDLE writeEvent;

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

	WSACloseEvent(found->readEvent);
	WSACloseEvent(found->writeEvent);

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
		handles[index] = element->readEvent;
		index++;

		handles[index] = element->writeEvent;
		index++;
		element = element->next;
	}

}

void aioFileDescriptor_signal_withHandle(HANDLE event){

	AioFileDescriptor* element = fileDescriptorList;

	while(element){

		if(element->readEvent == event){

			/**
			 * The event should be reset once it has been processed.
			 */
			WSAResetEvent(element->readEvent);

			if(element->mask == 0) {
				return;
			}
			//We set the event to 0 so it is not recalled after
			WSAEventSelect(element->fd, element->readEvent, 0);

			element->handlerFn(element->fd, element->clientData, AIO_R);
			return;
		}

		if(element->writeEvent == event){

			/**
			 * The event should be reset once it has been processed.
			 */
			WSAResetEvent(element->writeEvent);

			if(element->mask == 0) {
				return;
			}
			//We set the event to 0 so it is not recalled after
			WSAEventSelect(element->fd, element->writeEvent, 0);

			element->handlerFn(element->fd, element->clientData, AIO_W);
			return;
		}

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
		aioFileDescriptor->next = NULL;
	}

	aioFileDescriptor->fd = fd;
	aioFileDescriptor->clientData = clientData;
	aioFileDescriptor->flags = flags;
	aioFileDescriptor->readEvent = (HANDLE)WSACreateEvent();
	aioFileDescriptor->writeEvent = (HANDLE)WSACreateEvent();
	aioFileDescriptor->mask = 0;

	WSAEventSelect(aioFileDescriptor->fd, aioFileDescriptor->writeEvent, 0);
	WSAEventSelect(aioFileDescriptor->fd, aioFileDescriptor->readEvent, 0);

	u_long iMode = 1;
	int iResult;

	iResult = ioctlsocket(fd, FIONBIO, &iMode);
	if (iResult != NO_ERROR)
		perror("ioctlsocket(FIONBIO, 1)");

}

EXPORT(void) aioHandle(int fd, aioHandler handlerFn, int mask){
	AioFileDescriptor * aioFileDescriptor;
	char buf[100];

	aioFileDescriptor = aioFileDescriptor_find(fd);

	if(!aioFileDescriptor){
		return;
	}

	aioFileDescriptor->handlerFn = handlerFn;
	aioFileDescriptor->mask = mask;

	/**
	 * Remember to reset the event once is processed
	 */

	if(mask & AIO_R){
		WSAEventSelect(aioFileDescriptor->fd, aioFileDescriptor->readEvent, FD_READ | FD_ACCEPT | FD_OOB | FD_CLOSE);
		//This recv will always generates a WOULDBLOCK, but this is needed to generate the correct event in Windows.
		recv(aioFileDescriptor->fd, (void*)buf, 100, MSG_PEEK);
		return;
	}

	if(mask & AIO_W){
		WSAEventSelect(aioFileDescriptor->fd, aioFileDescriptor->writeEvent, FD_WRITE);
		return;
	}

}

EXPORT(void) aioSuspend(int fd, int mask){
	/**
	 * TODO: It is not used, so we don't implement it now
	 */
	printf("No implemented");
}

EXPORT(void) aioDisable(int fd){
	aioFileDescriptor_remove(fd);
}

EXPORT(long) aioPoll(long microSeconds){

	HANDLE* handlesToQuery;
	DWORD returnValue;
	long signaledIndex;
	AioFileDescriptor* signaled;

	//We require two events per socket
	int size = aioFileDescriptor_size() * 2;

	handlesToQuery = malloc(sizeof(HANDLE) * (size+1));
	aioFileDescriptor_fillHandles(handlesToQuery);

	/*
	 * We pass the interrupt event as the last handler
	 */
	handlesToQuery[size] = interruptEvent;

	heartbeat_poll_enter(microSeconds);

	returnValue = WaitForMultipleObjectsEx(size + 1, handlesToQuery, FALSE, microSeconds / 1000, FALSE);

	if(returnValue == WAIT_TIMEOUT){
		heartbeat_poll_exit(microSeconds);
		free(handlesToQuery);
		return 0;
	}

	if(returnValue == WAIT_FAILED){
		perror("aioPoll");
		logError("Error aioPoll: %ld", GetLastError());
		heartbeat_poll_exit(microSeconds);
		free(handlesToQuery);
		return 0;
	}

	signaledIndex = returnValue - WAIT_OBJECT_0;

	heartbeat_poll_exit(microSeconds);

	/*
	 * If it is the first is the interrupt event that we use to break the poll.
	 * If it is interrupted we don't need to process, but we need to clear the interrupt event
	 * As the WaitForMultipleObjects signals in the order it find it, if it arrives to the last handle
	 * there are no events in the other handles
	 */
	if(signaledIndex == size){
		ResetEvent(interruptEvent);
		free(handlesToQuery);
		return 0;
	}

	for(int i=0; i < size; i++){
		if(WaitForSingleObject(handlesToQuery[i], 0) == WAIT_OBJECT_0) {
			aioFileDescriptor_signal_withHandle(handlesToQuery[i]);
		}
	}

	free(handlesToQuery);

	return 1;
}

EXPORT(void) aioInterruptPoll(){
	SetEvent(interruptEvent);
}

