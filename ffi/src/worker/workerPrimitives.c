#include "worker.h"
#include "pharovm/macros.h"

/* primitiveCreateWorker
 *   creates a new worker and set the address in the external address that exists in the worker instance.
 *
 *   receiver: worker instance <TFWorker>
 *
 */
PrimitiveWithDepth(primitiveCreateWorker, 2) {
    Worker *worker;
    sqInt receiver;

    receiver = getReceiver();
    checkFailed();

    worker = worker_new();

    if(worker == NULL){
    	failed();
    	return;
    }

    setHandler(receiver, worker);
    checkFailed();

    primitiveEnd();
}

/* primitiveCreateWorker
 *   release the worker and store NULL in the external address that exists in the worker instance.
 *
 *   receiver: worker instance <TFWorker>
 *
 */
PrimitiveWithDepth(primitiveReleaseWorker, 2) {
    Worker *worker;
    sqInt receiver;

    receiver = getReceiver();
    checkFailed();

    worker = getHandler(receiver);
    checkFailed();

    worker_release(worker);

    setHandler(receiver, NULL);
    checkFailed();

    primitiveEnd();
}




/* primitivePerformWorkerCall
 *
 *  receiver: A worker <TFWorker>
 *
 *  arguments:
 *  3 - externalFunction        <ExternalAddress>
 *  2 - arguments               <ExternalAddress>
 *  1 - returnHolder            <ExternalAddress>
 *  0 - semaphoreIndex          <Integer>
 */
// This is just because arguments are placed in order in stack, then they are inverse. And is confusing ;)
#define PARAM_EXTERNAL_FUNCTION     3
#define PARAM_ARGUMENTS             2
#define PARAM_RETURN_HOLDER         1
#define PARAM_SEMAPHORE_INDEX       0
PrimitiveWithDepth(primitivePerformWorkerCall, 2) {
    void *cif;
    void *externalFunction;
    void *parameters;
    void *returnHolder;
    sqInt semaphoreIndex;
    WorkerTask *task;
    Worker *worker;
    sqInt receiver;

    semaphoreIndex = stackIntegerValue(PARAM_SEMAPHORE_INDEX);
    checkFailed();

    returnHolder = readAddress(stackValue(PARAM_RETURN_HOLDER));
    checkFailed();

    parameters = readAddress(stackValue(PARAM_ARGUMENTS));
    checkFailed();

    externalFunction = getHandler(stackValue(PARAM_EXTERNAL_FUNCTION));
    checkFailed();

    //Getting the function CIF of LibFFI
    cif = getHandler(fetchPointerofObject(1, stackValue(PARAM_EXTERNAL_FUNCTION)));
    checkFailed();

    receiver = getReceiver();
    checkFailed();

    worker = (Worker *)getHandler(receiver);
    checkFailed();

    task = worker_task_new(externalFunction, cif, parameters, returnHolder, semaphoreIndex);
    checkFailed();

    worker_dispatch_callout(worker, task);
    checkFailed();

    primitiveEnd();
}

