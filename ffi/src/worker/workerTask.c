#include "workerTask.h"

#include <stdio.h>
#include <ffi.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

/* newWorkerTask
 *  creates a new WorkerTask.
 *  IMPORTANT: is responsibility of the caller to free the created task
 */
WorkerTask *worker_task_new(void *externalFunction, ffi_cif *cif, void *parameters, void *returnHolder, int semaphoreIndex) {
    WorkerTask *task = malloc(sizeof(WorkerTask));
    
    task->type = CALLOUT;
    task->anExternalFunction = externalFunction;
    task->cif = (ffi_cif*) cif;
    task->parametersAddress = parameters;
    task->returnHolderAddress = returnHolder;
    task->semaphoreIndex = semaphoreIndex;
    task->queueHandle = NULL;
    
    return task;
}

WorkerTask *worker_task_new_callback(CallbackInvocation* invocation) {
    WorkerTask *task = malloc(sizeof(WorkerTask));
    task->callbackSemaphore = invocation->payload;
    
    task->type = CALLBACK_RETURN;
    return task;
}

void worker_task_release(WorkerTask *task) {
    free(task);
}

