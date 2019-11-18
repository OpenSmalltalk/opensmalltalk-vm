#include "pharo.h"
#include "parameters.h"
#include <getopt.h>
#include <unistd.h>
#include "debug.h"

void printVersion();
void printUsage();

int findImageNameIndex(int argc, char* argv[]){

	//The first parameters is the executable name
	for(int i=1; i < argc; i ++){
		if(strcmp(argv[i], "--") == 0 || (strncmp("--",argv[i],2) != 0)){
			return i;
		}
	}

	// I didn't find it.
	return argc;
}

void splitVMAndImageParameters(int argc, char* argv[], VM_PARAMETERS* parameters){

	int imageNameIndex = findImageNameIndex(argc, argv);
	int numberParametersVM = imageNameIndex;
	int numberImageParameters = argc - imageNameIndex - 1;

	if(numberImageParameters < 0)
		numberImageParameters = 0;

	//We get the image file name
	if(imageNameIndex == argc || strcmp("--", argv[imageNameIndex]) == 0){
		parameters->imageFile = DEFAULT_IMAGE_NAME;
		parameters->isDefaultImage = true;
		parameters->hasBeenSelectedByUser = false;
	}else{
		parameters->imageFile = argv[imageNameIndex];
		parameters->isDefaultImage = false;
		parameters->hasBeenSelectedByUser = false;
	}

	//Copy image parameters

	parameters->imageParams = malloc(sizeof(void*) * numberImageParameters);
	parameters->imageParamsCount = numberImageParameters;
	for(int i=0; i < numberImageParameters; i++){
		parameters->imageParams[i] = argv[imageNameIndex + i + 1];
	}

	//Copy vm parameters
	//We have to guarantee that the VM parameters includes --headless
	//As it is checked by the image.

	parameters->vmParams = malloc(sizeof(void*) * (numberParametersVM +1));
	parameters->vmParamsCount = numberParametersVM + 1;
	for(int i=0; i < numberParametersVM; i++){
		parameters->vmParams[i] = argv[i];
	}
	parameters->vmParams[numberParametersVM] = "--headless";
}


void logParameters(VM_PARAMETERS* parameters){
	char buffer[4096];

	logDebug("ImageFile: %s", parameters->imageFile);
	logDebug("Is default Image: %d", parameters->isDefaultImage);
	logDebug("Has been selected: %d", parameters->hasBeenSelectedByUser);

	logDebug("vmParamsCount: %d", parameters->vmParamsCount);

	buffer[0] = 0;
	for(int i=0; i < parameters->vmParamsCount; i++){
		strcat(buffer, parameters->vmParams[i]);
		strcat(buffer, " ");
	}

	logDebug("vmParams: %s", buffer);

	logDebug("imageParamsCount: %d", parameters->imageParamsCount);

	buffer[0] = 0;
	for(int i=0; i < parameters->imageParamsCount; i++){
		strcat(buffer, parameters->imageParams[i]);
		strcat(buffer, " ");
	}

	logDebug("imageParams: %s", buffer);
}

int isConsole(){
#if WIN64
	return GetStdHandle(STD_INPUT_HANDLE) != NULL;
#else
	return false;
#endif
}

void processImageFileName(VM_PARAMETERS* parameters){
	if(parameters->isDefaultImage){
		if(!fileExists(parameters->imageFile)){
			if(!openFileDialog("Choose image file", "", "image", &(parameters->imageFile), DEFAULT_IMAGE_NAME)){
				printUsage();
				exit(1);
			}

			parameters->hasBeenSelectedByUser = true;
		}
		//If there are no parameters, we are next to the launch of the VM, we need to add the interactive flag
		//As we always have two parameters (the --headless)
		if(parameters->vmParamsCount == 2 && parameters->imageParamsCount == 0 && !isConsole()){
			parameters->imageParams = malloc(sizeof(void*));
			parameters->imageParamsCount = 1;
			parameters->imageParams[0] = "--interactive";
		}
	}
}

void printUsage(){
	printf("Usage: %s [<option>...] [<imageName> [<argument>...]]\n", VM_NAME);
	printf("       %s [<option>...] -- [<argument>...]\n", VM_NAME);
	printf("\n");
	printf("Common <option>s:\n");
	printf("  --help                 print this help message, then exit\n");
	printf("  --headless             run in headless (no window) mode (default: true)\n");
    printf("  --worker               run in worker thread (default: false)\n");
	printf("  --logLevel=<level>     Sets the log level (ERROR, WARN, INFO or DEBUG)\n");
	printf("  --version              print version information, then exit\n");
	printf("\n");
	printf("Notes:\n");
	printf("\n");
	printf("  <imageName> defaults to `Pharo.image'.\n");
	printf("  <argument>s are ignored, but are processed by the Pharo image.\n");
	printf("  Precede <arguments> by `--' to use default image.\n");
}

typedef void (*OPTION_PROCESS_FUNCTION)(char*);

extern int flagVMRunOnWorkerThread;
void processWorkerOption(char* value) {
    flagVMRunOnWorkerThread = 1;
}

void processLogLevelOption(char* value){

	int intValue = 0;

	intValue = strtol(value, NULL, 10);

	if(intValue == 0){
		printf("Invalid option for logLevel: %s\n", value);
		printUsage();
		exit(1);
	}

	logLevel(intValue);
}

void processHelpOption(char* value){
	printUsage();
	exit(0);
}

void processPrintVersionOption(char* value){
	printVersion();
	exit(0);
}

static struct option long_options[] = {
	{"headless", no_argument, 0,  0 },
    {"worker", no_argument, 0,  0 },
	{"help", no_argument, 0,  0 },
	{"logLevel", required_argument, 0, 0},
	{"version", no_argument, 0, 0},
	{0, 0, 0, 0 }
};

static OPTION_PROCESS_FUNCTION optionHandlers[] = {
    0, /* No processing needed */
    processWorkerOption,
    processHelpOption,
    processLogLevelOption,
    processPrintVersionOption};

void processVMOptions(VM_PARAMETERS* parameters){

	int option_index = 0;
	char r;
	OPTION_PROCESS_FUNCTION processFunction;


	while((r = getopt_long(parameters->vmParamsCount, parameters->vmParams, "", long_options, &option_index))!=-1){
		// We have an invalid option
		if(r == '?'){
			printUsage();
			exit(1);
		}

		if(optionHandlers[option_index])
			optionHandlers[option_index](optarg);
	}
}

void parseArguments(int argc, char* argv[], VM_PARAMETERS* parameters){
	char* fullPath;

	splitVMAndImageParameters(argc, argv, parameters);

	//I get the VM location from the argv[0]
	fullPath = alloca(FILENAME_MAX);
	fullPath = getFullPath(argv[0], fullPath, FILENAME_MAX);
	setVMPath(fullPath);

	processImageFileName(parameters);

	processVMOptions(parameters);

	logParameters(parameters);
}
