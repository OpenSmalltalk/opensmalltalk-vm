#ifndef __PSEMAPHORE__
#define __PSEMAPHORE__

typedef struct __Semaphore {
	void *handle;
	int (*wait)(struct __Semaphore *semaphore);
	int (*signal)(struct __Semaphore *semaphore);
	void (*free)(struct __Semaphore *semaphore);
} Semaphore;

#endif // ifndef __PSEMAPHORE__
