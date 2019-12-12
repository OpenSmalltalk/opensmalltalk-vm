#ifndef __PLATFORM_SEMAPHORE__
#define __PLATFORM_SEMAPHORE__

#include "pSemaphore.h"
#include "pharovm/pharo.h"

#include <stdlib.h>

#ifndef __APPLE__
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

#endif // ifndef __PLATFORM_SEMAPHORE__
