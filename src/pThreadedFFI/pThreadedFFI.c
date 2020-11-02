#include "pharovm/pThreadedFFI/pThreadedFFI.h"
#include "pharovm/pThreadedFFI/worker.h"

Worker *mainThreadWorker = NULL;

EXPORT(sqInt)
runMainThreadWorker() {
    mainThreadWorker = worker_newSpawning(false);
	worker_run(mainThreadWorker);
    return 1;
}
