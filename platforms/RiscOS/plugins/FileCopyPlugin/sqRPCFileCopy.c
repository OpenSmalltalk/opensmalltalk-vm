/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  other machines not yet tested.                                        */
/*                       sqRPCFileCopy.c                                  */
/*  hook up to RiscOS file copy to preserve filtypes etc                  */
/**************************************************************************/

/* To recompile this reliably you will need    */           
/* OSLib -  http://ro-oslib.sourceforge.net/   */
/* Castle/AcornC/C++, the Acorn TCPIPLib       */
/* and a little luck                           */
#include "oslib/os.h"
#include "oslib/osfile.h"
#include "oslib/osfscontrol.h"
#include "sq.h"

#define MAXDIRNAMELENGTH 1024
/* debugging stuff; can probably be deleted */
//#define DEBUG

#ifdef DEBUG
#define FPRINTF(s)\
{\
	extern os_error privateErr;\
	extern void platReportError( os_error * e);\
	privateErr.errnum = (bits)0;\
	sprintf s;\
	platReportError((os_error *)&privateErr);\
};
#else
# define FPRINTF(X)
#endif

/*** Functions ***/
int sqCopyFilesizetosize(char *srcName, int srcNameSize, char *dstName, int dstNameSize) {
	os_error *e;
	char fromname[MAXDIRNAMELENGTH];
	char toname[MAXDIRNAMELENGTH];
	osfscontrol_copy_flags flag = osfscontrol_COPY_FORCE;
		FPRINTF((privateErr.errmess, "platcopy called\n"));

	if( srcNameSize > MAXDIRNAMELENGTH) return false;
	sqFilenameFromString( fromname, (int)srcName, srcNameSize);
	if( dstNameSize > MAXDIRNAMELENGTH) return false;
	sqFilenameFromString( toname, (int)dstName, dstNameSize);
		FPRINTF((privateErr.errmess, "platcopy names ok\n"));

	e = xosfscontrol_copy(
		(char const *)fromname,
		(char const *)toname,
		flag,
		(bits)0,(bits)0,(bits)0,(bits)0,(osfscontrol_descriptor *)0 );
	if (e != NULL) return false;
		FPRINTF((privateErr.errmess, "platcopy ok\n"));
	return true;
}



