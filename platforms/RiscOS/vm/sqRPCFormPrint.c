/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
/*  Known to work on RiscOS 3.7 for StrongARM RPCs, other machines        */
/*  not yet tested.                                                       */
/*                       sqRPCFormPrint.c                                 */
/*  Print a Form - except we can't do thatright now. Another day maybe    */
/**************************************************************************/

#include "sq.h"

int ioFormPrint(int bitsAddr, int width, int height, int depth, double hScale, double vScale, int landscapeFlag) {
	/* experimental: print a form with the given bitmap, width, height, and depth at the given horizontal and vertical scales in the given orientation */
		printf("ioFormPrint width %d height %d depth %d hScale %f vScale %f landscapeFlag %d\n", width, height, depth, hScale, vScale, landscapeFlag);
		bitsAddr;
	return true;
}

