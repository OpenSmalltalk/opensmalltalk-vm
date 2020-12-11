#ifndef __PLATFORM_SEMAPHORE__
#define __PLATFORM_SEMAPHORE__

#include "pharovm/semaphores/pSemaphore.h"
#include "pharovm/pharo.h"

#include <stdlib.h>

#if defined(_WIN32)

#include <windows.h>

typedef HANDLE PlatformSemaphore;
#define isValidSemaphore(aSemaphore) (aSemaphore != NULL)

#elif !defined(__APPLE__)
// I am a normal unix
#include <pthread.h>
#include <semaphore.h>
#include <errno.h>

typedef sem_t* PlatformSemaphore;
#define isValidSemaphore(aSemaphore) (aSemaphore != NULL)

#else
// I am OSX
#include <dispatch/dispatch.h>

typedef dispatch_semaphore_t PlatformSemaphore;
#define isValidSemaphore(aSemaphore) (1)
#endif // ifndef __APPLE__

EXPORT(Semaphore) *platform_semaphore_new(int initialValue);
EXPORT(void) platform_semaphore_free(Semaphore *semaphore);
EXPORT(int) platform_semaphore_signal(Semaphore *semaphore);
EXPORT(int) platform_semaphore_wait(Semaphore *semaphore);

#endif // ifndef __PLATFORM_SEMAPHORE__
