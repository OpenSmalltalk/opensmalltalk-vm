/**************************************************************************/
/*  A Squeak plugin for unix machines by Tim Rowledge                     */
/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
/*                       sqUnixfileCopy.c                                 */
/*  Copying files via OS calls                                            */
/**************************************************************************/
#include "sq.h"
#include <stdlib.h>

#define MAXDIRNAMELENGTH 1024

/*** Functions ***/
int sqCopyFilesizetosize(char *srcName, int srcNameSize, char *dstName, int dstNameSize) {
	char fromname[MAXDIRNAMELENGTH];
	char toname[MAXDIRNAMELENGTH];
	char *cmdLine;

	if( srcNameSize > MAXDIRNAMELENGTH) return false;
	sqFilenameFromString( fromname, (int)srcName, srcNameSize);
	if( dstNameSize > MAXDIRNAMELENGTH) return false;
	sqFilenameFromString( toname, (int)dstName, dstNameSize);

	cmdLine = (char *)malloc((size_t)(dstNameSize + srcNameSize + 20));
	if( cmdLine == NULL) return false;

	sprintf(cmdLine, "cp %s %s", fromname, toname);

	/* is there any useful error code that could be checked for here? */
	system(cmdLine);

	free(cmdLine);
	return true;
}



