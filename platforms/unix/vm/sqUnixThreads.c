/****************************************************************************
*   PROJECT: Unix (pthreads) thread support code for Stack & Cog VM
*   FILE:    sqUnixThreads.c
*   CONTENT: 
*
*   AUTHOR:  Eliot Miranda
*   ADDRESS: 
*   EMAIL:   eliot@teleplace.com
*   RCSID:   $Id$
*
*****************************************************************************/

#include "sq.h"

#include <errno.h>
#include <pthread.h>

/* This is for sqVirtualMachine.h's default ownVM implementation. */
sqInt
amInVMThread() { return ioOSThreadsEqual(ioCurrentOSThread(),getVMThread()); }

void
ioInitThreads()
{
	extern void ioInitExternalSemaphores(void);
	ioVMThread = ioCurrentOSThread();
	ioInitExternalSemaphores();
}

/* this for testing crash dumps */
static sqInt
indirect(long p)
{
	return p > 99
		? indirect(p - 100), indirect(p - 50) /* evade tail recursion opt */
		: *(sqInt *)p;
}

sqInt
crashInThisOrAnotherThread(sqInt inThisThread)
{
	if (inThisThread)
		return indirect(0);
	else {
		pthread_t newThread;

		(void)pthread_create(
				&newThread,					/* pthread_t *new_thread_ID */ 
				0,							/* const pthread_attr_t *attr */
				(void *(*)(void *))indirect,/* void * (*thread_execp)(void *) */
				(void *)300					/* void *arg */);
		sleep(1);
	}
	return 0;
}
