#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>

#include <pharoClient.h>
#include <pharo.h>

//TODO: This needs to be put in VM_PARAMETERS
int flagVMRunOnWorkerThread = 0;

int runVMThread(void* p){
    VM_PARAMETERS *parameters = (VM_PARAMETERS*)p;

    if(!initPharoVM(parameters->imageFile, parameters->vmParams, parameters->vmParamsCount, parameters->imageParams, parameters->imageParamsCount)) {
        logError("Error opening image file: %s\n", parameters->imageFile);
        exit(-1);
    }
    setFlagVMRunOnWorkerThread(flagVMRunOnWorkerThread);
    
    runInterpreter();
}

int runOnMainThread(VM_PARAMETERS *parameters) {
    logDebug("Running VM on main thread\n");
    runVMThread((void *)parameters);
    return 0;
}

int runOnWorkerThread(VM_PARAMETERS *parameters) {
    pthread_attr_t tattr;
    pthread_t thread_id;
    size_t size;

    logDebug("Running VM on worker thread\n");
    
    /*
     * I have to get the attributes of the main thread
     * to get the max stack size.
     * We need to set this value to the newly created thread,
     * as the created threads does not auto-grow.
     */
    pthread_attr_init(&tattr);
    pthread_attr_getstacksize(&tattr, &size);

    logDebug("Stack size: %ld\n", size);


    if(pthread_attr_setstacksize(&tattr, size * 4)){
        perror("Setting thread stack size");
        exit(-1);
    }

    if(pthread_create(&thread_id, &tattr, runVMThread, parameters)){
        perror("Spawning the VM thread");
        exit(-1);
    }

    pthread_detach(thread_id);

    /**
     * I will now wait if any plugin wants to run stuff in the main thread.
     * This is used by the ThreadedFFI plugin to run a worker in the main thread.
     * This runner is used to create and handle UI operations, required by OSX.
     */

    return mainThreadLoop();
}

int main(int argc, char* argv[], char** env){

	installErrorHandlers();

	setProcessArguments(argc, argv);
	setProcessEnvironmentVector(env);

	VM_PARAMETERS parameters;
	char buffer[4096+1];

	parseArguments(argc, argv, &parameters);

	logInfo("Opening Image: %s\n", parameters.imageFile);

	//This initialization is required because it makes awful, awful, awful code to calculate
	//the location of the machine code.
	//Luckily, it can be cached.
	osCogStackPageHeadroom();

	getcwd(buffer, sizeof(buffer));
	logDebug("Working Directory %s", buffer);

	LOG_SIZEOF(int);
	LOG_SIZEOF(long);
	LOG_SIZEOF(long long);
	LOG_SIZEOF(void*);
	LOG_SIZEOF(sqInt);
	LOG_SIZEOF(sqLong);
	LOG_SIZEOF(float);
	LOG_SIZEOF(double);

    return flagVMRunOnWorkerThread
        ? runOnWorkerThread(&parameters)
        : runOnMainThread(&parameters);
}

void printVersion(){
	printf("%s\n", getVMVersion());
	printf("Built from: %s\n", getSourceVersion());
}
