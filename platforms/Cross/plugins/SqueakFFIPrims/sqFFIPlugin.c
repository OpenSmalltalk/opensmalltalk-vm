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
#if !WIN32 && !__FreeBSD__ && !__OpenBSD__
# include <alloca.h>
#endif
#include <string.h>

#ifdef _MSC_VER
# include <windows.h>
# define alloca _alloca
#endif

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

static FILE *ffiLogFile = NULL;

int
ffiLogFileNameOfLength(void *nameIndex, int nameLength)
{
	if (nameIndex && nameLength) {
		char *fileName;
		FILE *fp;

		if (!(fileName = alloca(nameLength+1)))
			return 0;
		strncpy(fileName, nameIndex, nameLength);
		fileName[nameLength] = 0;
		/* attempt to open the file and if we can't, fail */
		if (!(fp = fopen(fileName, "at")))
			return 0;
		/* close the old log file if needed and use the new one */
		if (ffiLogFile)
			fclose(ffiLogFile);
		ffiLogFile = fp;
		fprintf(ffiLogFile, "------- Log started -------\n");
		fflush(fp);
	}
	else {
		if (ffiLogFile)
			fclose(ffiLogFile);
		ffiLogFile = NULL;
	}
	return 1;
}

int
ffiLogCallOfLength(void *nameIndex, int nameLength)
{
    if (!ffiLogFile)
		return 0;
    fprintf(ffiLogFile, "%.*s\n", nameLength, (char *)nameIndex);
    fflush(ffiLogFile);
	return 1;
}
