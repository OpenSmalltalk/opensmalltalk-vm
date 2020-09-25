#include "pharovm/pThreadedFFI/pThreadedFFI.h"
#include "pharovm/pThreadedFFI/worker.h"

Worker *mainThreadWorker = NULL;

sqInt
runInMainThread() {
    worker_run(mainThreadWorker);
    return 1;
}

sqInt
initMainThreadWorker(void) {
    mainThreadWorker = worker_newSpawning(false);
    mainThread_schedule(runInMainThread);
    return 1;
}
