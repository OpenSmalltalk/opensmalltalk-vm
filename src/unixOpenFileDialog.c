#include "pharo.h"

int openFileDialog(char const * aTitle,
                   char const * aDefaultPathAndFile,
                   char const * filter,
                   char ** selectedFile,
				   char const * defaultFile){
	//The default implementation does not do nothing!
	//It keeps the defaultFile.

	*selectedFile = defaultFile;

	return false;
}
