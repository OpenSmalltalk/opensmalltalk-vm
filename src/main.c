#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>

#include <pharoClient.h>
#include <pharo.h>

int main(int argc, char* argv[]){

	VM_PARAMETERS parameters;

	parseArguments(argc, argv, &parameters);

	logInfo("Opening Image: %s\n", parameters.imageFile);

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
