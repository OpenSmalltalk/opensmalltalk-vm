#include "pharovm/pharo.h"
#include "pharovm/semaphores/platformSemaphore.h"

/*
 * This Functions are private to the implementation
 */
PlatformSemaphore semaphore_new(long initialValue);
int semaphore_wait(PlatformSemaphore sem);
int semaphore_signal(PlatformSemaphore sem);
int semaphore_release(PlatformSemaphore sem);


#ifndef __APPLE__

PlatformSemaphore
semaphore_new(long initialValue){
	PlatformSemaphore wrapper = malloc(sizeof(sem_t));
    int returnCode;

    returnCode = sem_init(wrapper, 0, initialValue);

    if(returnCode != 0){
        return NULL;
    }

    return wrapper;
}


int
semaphore_wait(PlatformSemaphore sem){
    int returnCode;
    while((returnCode = sem_wait(sem)) == -1  && errno == EINTR);
    return returnCode;
}

int
semaphore_signal(PlatformSemaphore sem){
    return sem_post(sem);
}

int
semaphore_release(PlatformSemaphore sem){
    sem_destroy(sem);
    free(sem);
    return 0;
}

#else

PlatformSemaphore
semaphore_new(long initialValue){
    return dispatch_semaphore_create(initialValue);
}

int
semaphore_wait(PlatformSemaphore sem){
	dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER );
    return 0;
}

int
semaphore_signal(PlatformSemaphore sem){
    dispatch_semaphore_signal(sem);
    return 0;
}

int
semaphore_release(PlatformSemaphore sem){
    /* https://developer.apple.com/documentation/dispatch/1496328-dispatch_release
      If your app is built with a deployment target of macOS 10.8 and later or iOS v6.0 and
      later, dispatch queues are typically managed by ARC, so you do not need to retain or release
      the dispatch queues.
      TODO: No idea if this applies (need to check later), but this is crashing the system.
    dispatch_release(sem);
     */
    return 0;
}

#endif

int
platform_semaphore_wait(Semaphore *semaphore){
	return semaphore_wait((PlatformSemaphore)semaphore->handle);
}

int
platform_semaphore_signal(Semaphore *semaphore){
	return semaphore_signal((PlatformSemaphore)semaphore->handle);
}

void
platform_semaphore_free(Semaphore *semaphore){
	semaphore_release((PlatformSemaphore)semaphore->handle);
	free(semaphore);
}

EXPORT(Semaphore*)
platform_semaphore_new(int initialValue) {
	Semaphore *semaphore = (Semaphore *) malloc(sizeof(Semaphore));
	semaphore->handle = (void *) semaphore_new(initialValue);
	semaphore->wait = platform_semaphore_wait;
	semaphore->signal = platform_semaphore_signal;
	semaphore->free = platform_semaphore_free;
	return semaphore;
}
