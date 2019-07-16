#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>

#include <pharoClient.h>
#include <pharo.h>

char* params[2] = {"pharo","--headless"};
char** imageParams;
int imageParamCount;
char* image;

int main(int argc, char* argv[]){


	parseArguments(argc, argv);

	printf("Opening Image: %s\n", image);

	if(!initPharoVM(image, params, 2, imageParams, imageParamCount)){
		fprintf(stderr, "Error opening image file: %s\n", image);
		return -1;
	}
	runInterpreter(NULL);
}

void parseArguments(int argc, char* argv[]){
	char* defaultImage = "Pharo.image";
	char* fullPath;

	//I get the VM location from the argv[0]
	fullPath = alloca(FILENAME_MAX);
	fullPath = getFullPath(argv[0], fullPath, FILENAME_MAX);
	setVMPath(fullPath);

	if(argc == 1){
		image = defaultImage;
		imageParams = NULL;
		imageParamCount = 0;

		if(!fileExists(image)){
			openFileDialog("Choose image file", "", "image", &image, defaultImage);
		}
	}else{
		image = argv[1];
		imageParams = malloc(sizeof(char*)* (argc - 1) );
		memcpy(imageParams, argv+2, sizeof(char*)* (argc - 2));
		imageParamCount = argc - 2;
		imageParams[argc - 2] = NULL;
	}

}
