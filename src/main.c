#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>

#include <pharoClient.h>
#include <pharo.h>

int main(int argc, char* argv[]){

	VM_PARAMETERS parameters;
	char buffer[4096+1];

	parseArguments(argc, argv, &parameters);

	logInfo("Opening Image: %s\n", parameters.imageFile);

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

	if(!initPharoVM(parameters.imageFile, parameters.vmParams, parameters.vmParamsCount, parameters.imageParams, parameters.imageParamsCount)){
		logError("Error opening image file: %s\n", parameters.imageFile);
		return -1;
	}
	runInterpreter();
}

void printVersion(){
	printf("%s\n", getVMVersion());
	printf("Built from: %s\n", getSourceVersion());
}
