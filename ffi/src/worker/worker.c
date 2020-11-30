#include "pThreadedFFI.h"
#include "worker.h"

#include <stdio.h>
#include <ffi.h>
#include <pthread.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

#include "pharovm/semaphores/pharoSemaphore.h"
#include "pharovm/semaphores/platformSemaphore.h"
#include "pharovm/threadSafeQueue/threadSafeQueue.h"

#ifdef __APPLE__
# include <dispatch/dispatch.h>
#endif

struct __Worker {
	Runner runner;

    pthread_t threadId;
    TSQueue *taskQueue;

    //I need to identify when the callbacks come from another thread different than the runner.
    pthread_t selfThread;

    struct __Worker *next;
};

WorkerTask *worker_next_call(Worker *worker);

void worker_enter_callback(Runner* runner, CallbackInvocation* invocation){

	Worker *worker = (Worker*)runner;

	/*
	 * As I have to detect if the callback is in the same thread or not, I will use the payload.
	 * If the callback is in the same thread that the runner I have to call the worker_run loop
	 * so I can have reentrant calls.
	 * If the callback is in another thread, the payload will have a platform semaphore.
	 * With this semaphore I can wait until the callback come back.
	 */

	if(invocation->payload == NULL){
		worker_run(worker);
		return;
	}

	Semaphore* s = (Semaphore*)invocation->payload;
	s->wait(s);
	s->free(s);

	return;
}

void worker_callback_return(Runner* worker, CallbackInvocation *invocation){
    WorkerTask *task = worker_task_new_callback(invocation);
    worker_add_call((Worker*)worker, task);
}

void worker_callback_prepare(Runner* worker, CallbackInvocation *invocation){
	// If we are in the same thread that the runner, I will just put NULL, this is a mark to the process to handle callbacks from other threads.
	// If the thread is other, I will put a platform semaphore, so the callback invocator can wait on it, and the runner loop signals it.

	if(((Worker*)worker)->selfThread == pthread_self()){
		invocation->payload = NULL;
	}else{
		invocation->payload = platform_semaphore_new(0);
	}
}


static void executeWorkerTask(Worker *worker, WorkerTask *task);


Worker *worker_newSpawning(int spawn) {
    Worker *worker = (Worker *)malloc(sizeof(Worker));
    
    worker->next = NULL;
    worker->threadId = 0;
    worker->selfThread = NULL;
    worker->taskQueue = threadsafe_queue_new(platform_semaphore_new(0));
    worker->runner.callbackEnterFunction = worker_enter_callback;
    worker->runner.callbackExitFunction = worker_callback_return;
    worker->runner.callbackPrepareInvocation = worker_callback_prepare;
    worker->runner.callbackStack = NULL;

    if(spawn){
    	if (pthread_create(&(worker->threadId), NULL, worker_run, (void *)worker) != 0) {
    		perror("pthread_create() error");
    		return NULL;
    	}

    	pthread_detach(worker->threadId);
    }

    return worker;
}

Worker *worker_new(){
	return worker_newSpawning(true);
}

void worker_release(Worker *worker) {
    threadsafe_queue_free(worker->taskQueue);
    free(worker);
}

inline void worker_dispatch_callout(Worker *worker, WorkerTask *task) {
    worker_add_call(worker, task);
}

void worker_add_call(Worker *worker, WorkerTask *task) {
    threadsafe_queue_put(worker->taskQueue, task);
}

WorkerTask *worker_next_call(Worker *worker) {
	return (WorkerTask *)threadsafe_queue_take(worker->taskQueue);
}

void *worker_run(void *aWorker) {
    WorkerTask *task = NULL;
    Worker* worker = (Worker*)aWorker;

    worker->selfThread = pthread_self();

    while(true) {
        task = worker_next_call(worker);
        if (task) {
            if (task->type == CALLOUT) {
            	executeWorkerTask((Worker *)worker, task);
            } else if (task->type == CALLBACK_RETURN) {
                // stop consuming tasks and return
            	/*
            	 * If we have a semaphore we signal it, if not we return
            	 * This is to handle callbacks from different threads.
            	 * I have to return if the callback is in the same thread that the worker (when it is a result of a call in a callout)
            	 * If the callback is from another thread, just we need to signal the semaphore.
            	 */

            	if(task->callbackSemaphore){
            		Semaphore* callbackSemaphore = (Semaphore*)task->callbackSemaphore;
            		callbackSemaphore->signal(callbackSemaphore);
            	}else{
                   	return NULL;
            	}
            } else {
                fprintf(stderr, "Unsupported task type: %d", task->type);
                perror("");
            }
        } else {
            perror("No callbacks in the queue");
        }
    }
    
    return NULL;
}

void executeWorkerTask(Worker *worker, WorkerTask *task) {
    
    ffi_call(
             task->cif,
             task->anExternalFunction,
             task->returnHolderAddress,
             task->parametersAddress);
    
    signalSemaphoreWithIndex(task->semaphoreIndex);
}
