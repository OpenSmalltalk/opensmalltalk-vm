/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  other machines not yet tested.                                        */
/*                       sqRPCExternalPrims.c                             */
/* hook up to RiscOS external code modules using 'rink'                   */
/**************************************************************************/

/* To recompile this reliably you will need    */           
/* OSLib -  http://ro-oslib.sourceforge.net/   */
/* Castle/AcornC/C++, the Acorn TCPIPLib       */
/* and a little luck                           */
// define this to get lots of debug notifiers
//#define DEBUG

#include "oslib/os.h"
#include "sq.h"
#include <kernel.h>
#include "rink.h"




int ioFindExternalFunctionIn(char *symbol, int moduleHandle) {
/* find the function named symbol in the known loaded module moduleHandle */
int fnIndex= 0, address;
const char * foundName;

	PRINTF(( "ioFindExternalFunctionIn: %s", symbol));

	while ( (address = (int)rink_enum_named((rink_seghandle)moduleHandle, &fnIndex, &foundName)), fnIndex >= 0) {
		if ( strcmp(foundName, symbol) == 0) {
			PRINTF(( "found: %s",foundName));
			return address;
		} 
	}

	/* failed to find the function... */
	PRINTF(( " did not find: %s", symbol));
	return 0;
}

int ioLoadModule(char *modName) {
/* a routine to load a segment(module). Takes a pointer to the name
 * of the directory the code and links files are stored in
 */
extern char vmPath[];
const rink_version *Version;
const _kernel_oserror * e;
rink_seghandle moduleHandle;
char codeName[256];
const rink_check CheckBlock = {"SqueakSO", 100, 0};


	/* make filename of the code */
	sprintf(codeName, "%splugins.%s", vmPath, modName);
	PRINTF(( "Load: %s",modName));

	/* load the segment... */
	if((e = rink_load(&CheckBlock, codeName, &moduleHandle)) != NULL) {
		PRINTF(( "Plugin load failed: %s", codeName));
		return 0;
	}
	
	/* OK, let's have a look at the version of the segment we've just
	 * loaded. It might be nice to check them to see that it's acceptable.
	 * It is a bad plan to alter the returned structure.
	 */
	Version = rink_readversion(moduleHandle);
	/* report the version */
	PRINTF(("Plugin version: %d:%d", Version->main, Version->code));

	return (int)moduleHandle;
}

int ioFreeModule(int moduleHandle) {
	PRINTF(( "Plugin unload %d", moduleHandle));
	rink_unload((rink_seghandle)moduleHandle);
	return 1;
}



