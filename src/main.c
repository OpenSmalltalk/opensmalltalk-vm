#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>

#include <pharoClient.h>
#include <pharo.h>

int runThread(void* p){

	VM_PARAMETERS *parameters = (VM_PARAMETERS*)p;

	if(!initPharoVM(parameters->imageFile, parameters->vmParams, parameters->vmParamsCount, parameters->imageParams, parameters->imageParamsCount)){
		logError("Error opening image file: %s\n", parameters->imageFile);
		exit(-1);
	}
	runInterpreter();
}

void* mainThreadWorker = NULL;

void* getMainThreadWorker(){
	return mainThreadWorker;
}


int main(int argc, char* argv[], char** env){

	void*(*pworker_newSpawning)(bool);
	void*(*pworker_run)(void*);

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

	pthread_attr_t tattr;
	pthread_t thread_id;

	pthread_attr_init(&tattr);

	size_t size;
	pthread_attr_getstacksize(&tattr, &size);

	printf("%ld\n", size);

    if(pthread_attr_setstacksize(&tattr, size*4)){
		perror("Thread attr");
    }

	if(pthread_create(&thread_id, &tattr, runThread, &parameters)){
		perror("Thread creation");
	}

	pthread_detach(thread_id);

	void* module = ioLoadModule("PThreadedPlugin");

	pworker_newSpawning = dlsym(module, "worker_newSpawning");
	pworker_run = dlsym(module, "worker_run");

	logInfo("worker_newSpawning: %p worker_run: %p\n",pworker_newSpawning, pworker_run);

	mainThreadWorker = pworker_newSpawning(false);

	logInfo("worker: %p ", mainThreadWorker);

	pworker_run(mainThreadWorker);
}

void printVersion(){
	printf("%s\n", getVMVersion());
	printf("Built from: %s\n", getSourceVersion());
}
