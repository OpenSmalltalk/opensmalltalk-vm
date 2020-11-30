#include "pThreadedFFI.h"
#include "worker.h"

Worker *mainThreadWorker = NULL;

EXPORT(sqInt)
runMainThreadWorker() {
    mainThreadWorker = worker_newSpawning(false);
	worker_run(mainThreadWorker);
    return 1;
}
