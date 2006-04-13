/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@rowledge.org & http://www.rowledge.org/tim                        */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  other machines not yet tested.                                        */
/*                       sqRPCFormPrint.c                                 */
/*  Print a Form - except we can't do thatright now. Another day maybe    */
/**************************************************************************/


/* To recompile this reliably you will need    */           
/* OSLib -  http://ro-oslib.sourceforge.net/   */
/* Castle/AcornC/C++, the Acorn TCPIPLib       */
/* and a little luck                           */
// define this to get lots of debug notifiers
//#define DEBUG
#include "sq.h"


sqInt ioFormPrint(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth, double hScale, double vScale, sqInt landscapeFlag) {
	/* experimental: print a form with the given bitmap, width, height, and depth at the given horizontal and vertical scales in the given orientation */
		PRINTF(("ioFormPrint width %d height %d depth %d hScale %f vScale %f landscapeFlag %d\n", width, height, depth, hScale, vScale, landscapeFlag));
		bitsAddr;
	return true;
}

