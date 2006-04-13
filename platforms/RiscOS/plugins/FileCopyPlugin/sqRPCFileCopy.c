/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@rowledge.org & http://www.rowledge.org/tim                        */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  other machines not yet tested.                                        */
/*                       sqRPCFileCopy.c                                  */
/*  hook up to RiscOS file copy to preserve filetypes etc                 */
/**************************************************************************/

/* To recompile this reliably you will need    */           
/* OSLib -  http://ro-oslib.sourceforge.net/   */
/* Castle/AcornC/C++, the Acorn TCPIPLib       */
/* and a little luck                           */
/* debugging stuff; can probably be deleted */
//#define DEBUG
#include "oslib/os.h"
#include "oslib/osfile.h"
#include "oslib/osfscontrol.h"
#include "sq.h"

char fromname[MAXDIRNAMELENGTH];
char toname[MAXDIRNAMELENGTH];

/*** Functions ***/
sqInt sqCopyFilesizetosize(char *srcName, sqInt srcNameSize, char *dstName, sqInt dstNameSize) {
	os_error *e;


	osfscontrol_copy_flags flag = osfscontrol_COPY_FORCE;
		PRINTF(("\\t platcopy called\n"));

	if (!canonicalizeFilenameToString(srcName, srcNameSize, fromname))
		return false;

	if (!canonicalizeFilenameToString(dstName, dstNameSize, toname))
		return false;

		PRINTF(("\\t platcopy names ok\n"));

	e = xosfscontrol_copy(
		(char const *)fromname,
		(char const *)toname,
		flag,
		(bits)0,(bits)0,(bits)0,(bits)0,(osfscontrol_descriptor *)0 );

	if (e != NULL) return false;
	PRINTF(("\\t platcopy ok\n"));

	return true;
}



