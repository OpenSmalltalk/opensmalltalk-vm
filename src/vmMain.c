#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>

#include <pharoClient.h>
#include <pharo.h>

int
pharovm_mainWithParameters(const pharovm_parameters_t *parameters)
{
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
	
	int exitCode = pharovm_mainWithParameters(&parameters);
	pharovm_parameters_destroy(&parameters);
	return exitCode;
}

void printVersion(){
	printf("%s\n", getVMVersion());
	printf("Built from: %s\n", getSourceVersion());
}
