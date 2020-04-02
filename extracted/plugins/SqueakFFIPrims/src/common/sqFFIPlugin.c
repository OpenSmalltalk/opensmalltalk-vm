/****************************************************************************
*   PROJECT: Squeak threaded foreign function interface
*   FILE:    sqFFIPlugin.c
*   CONTENT: C support code for the threaded FFIPlugin
*
*   AUTHOR:  Eliot Miranda
*
*****************************************************************************/

#include <stdio.h>
#include <stdlib.h> /* proto for alloca in MINGW */
#if !_WIN32 && !__FreeBSD__ && !__OpenBSD__
# include <alloca.h>
#endif
#include <string.h>

#ifdef _MSC_VER
# include <windows.h>
# define alloca _alloca
#endif

#include "pharovm/debug.h"

/* this is a stub through which floating-point register arguments can be loaded
 * prior to an FFI call proper.  e.g. on the PowerPC this would be declared as
 *	extern void loadFloatRegs(double, double, double, double,
 *	                          double, double, double, double);
 * and called with the appropriate values necessary to load the floating-point
 * argument registers.  Immediately after the actual call is made, using the
 * undisturbed register contents created by the call of loadFloatRegs.
 */
void
loadFloatRegs(void) { return; }

int
ffiLogCallOfLength(void *nameIndex, int nameLength)
{
    logTrace("%.*s\n", nameLength, (char *)nameIndex);
	return 1;
}
