/**************************************************************************/
/*  sqUnixFileCopy -- Copying files via OS calls                          */
/**************************************************************************/
#include "sq.h"
#include <stdlib.h>


/*** Functions ***/
int sqCopyFilesizetosize(char *srcName, int srcNameSize, char *dstName, int dstNameSize) {
        char *fromname, *toname;
	char *cmdLine;
	int retval;

	fromname=malloc(srcNameSize+1);
	if(fromname == NULL) return false;
	toname=malloc(dstNameSize+1);
	if(toname == NULL) {
	     free(fromname);
	     return -1;
	}

	sqFilenameFromString(fromname, srcName, srcNameSize);
	sqFilenameFromString(toname, dstName, dstNameSize);
	

	cmdLine = (char *)malloc((size_t)(dstNameSize + srcNameSize + 20));
	if( cmdLine == NULL) {
	     free(fromname);
	     free(toname);
	     return -1;
	}
	

	sprintf(cmdLine, "cp -p %s %s", fromname, toname);
	
	retval = system(cmdLine);

	free(fromname);
	free(toname);
	free(cmdLine);

	if(retval)
	     return -1;  /* there was an error in the cp */
	else
	     return 0;   /* all went well */
}



