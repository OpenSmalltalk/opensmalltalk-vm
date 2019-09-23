#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>

#include <pharoClient.h>
#include <pharo.h>

int
pharovm_mainWithParameters(pharovm_parameters_t *parameters)
{
	// HACK: In some cases we need to add an explicit --interactive option to the image.
	pharovm_error_code_t error = pharovm_parameters_ensureInteractiveImageParameter(parameters);
	if (error) {
		return 1;
	}

	if(parameters->isDefaultImage && parameters->defaultImageCount == 0) {
		printf("No image has been specified, and no default image has been found.\n");
		pharovm_printUsageTo(stdout);
		return 0;
	}
	installErrorHandlers();

	setProcessArguments(parameters->processArgc, parameters->processArgv);
	setProcessEnvironmentVector(parameters->environmentVector);

	logInfo("Opening Image: %s\n", parameters->imageFileName);

	// FIXME: check the error code of this, and non-portability with Windows issues.
	char buffer[4096+1];
	memset(buffer, 0, sizeof(buffer));
	getcwd(buffer, sizeof(buffer) - 1);
	logDebug("Working Directory %s", buffer);

	LOG_SIZEOF(int);
	LOG_SIZEOF(long);
	LOG_SIZEOF(long long);
	LOG_SIZEOF(void*);
	LOG_SIZEOF(sqInt);
	LOG_SIZEOF(sqLong);
	LOG_SIZEOF(float);
	LOG_SIZEOF(double);

	if(!initPharoVM(parameters->imageFileName, &parameters->vmParameters, &parameters->imageParameters)) {
		logError("Error opening image file: %s\n", parameters->imageFileName);
		return -1;
	}

	runInterpreter();

	return 0;
}

int pharovm_main(int argc, const char** argv, const char** env)
{
	pharovm_parameters_t parameters = {};
	parameters.processArgc = argc;
	parameters.processArgv = argv;
	parameters.environmentVector = env;

	// Did we succeed on parsing the parameters?
	pharovm_error_code_t error = pharovm_parameters_parse(argc, argv, &parameters);
	if(error) {
		if(error == PHAROVM_ERROR_EXIT_WITH_SUCCESS) return 0;
		return 1;
	}

	if(parameters.isDefaultImage && parameters.defaultImageCount > 1) {
		printf(
"Multiple images that can be executed by this VM have been found. Please select\n"
"one of them explicitly as a command line argument.\n");
		return 0;
	}

	int exitCode = pharovm_mainWithParameters(&parameters);
	pharovm_parameters_destroy(&parameters);
	return exitCode;
}

void printVersion(){
	printf("%s\n", getVMVersion());
	printf("Built from: %s\n", getSourceVersion());
}
