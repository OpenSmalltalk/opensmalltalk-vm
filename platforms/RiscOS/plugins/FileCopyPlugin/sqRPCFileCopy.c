/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
/*  Known to work on RiscOS 3.7 for StrongARM RPCs, other machines        */
/*  not yet tested.                                                       */
/*                       sqRPCfileCopy.c                                  */
/*  Copying files  via OS calls                                           */
/**************************************************************************/
#include "os.h"
#include "osfile.h"
#include "osfscontrol.h"
#include "sq.h"

#define MAXDIRNAMELENGTH 1024

/*** Functions ***/
int sqCopyFilesizetosize(char *srcName, int srcNameSize, char *dstName, int dstNameSize) {
	os_error *e;
	char fromname[MAXDIRNAMELENGTH];
	char toname[MAXDIRNAMELENGTH];
	osfscontrol_copy_flags flag = osfscontrol_COPY_FORCE;

	if( srcNameSize > MAXDIRNAMELENGTH) return false;
	sqFilenameFromString( fromname, (int)srcName, srcNameSize);
	if( dstNameSize > MAXDIRNAMELENGTH) return false;
	sqFilenameFromString( toname, (int)dstName, dstNameSize);

	e = xosfscontrol_copy(
		(char const *)fromname,
		(char const *)toname,
		flag,
		(bits)0,(bits)0,(bits)0,(bits)0,(osfscontrol_descriptor *)0 );
	if (e != NULL) return false;
	return true;
}



