/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@rowledge.org & http://www.rowledge.org/tim                        */
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




void* ioFindExternalFunctionIn(char *symbol, void* moduleHandle) {
/* find the function named symbol in the known loaded module moduleHandle */
int fnIndex= 0;
void* address;
const char * foundName;

	PRINTF(( "\\t ioFindExternalFunctionIn: %s", symbol));

	while ( (address = (void*)rink_enum_named((rink_seghandle)moduleHandle, &fnIndex, &foundName)), fnIndex >= 0) {
		if ( strcmp(foundName, symbol) == 0) {
			PRINTF(( "found %s\n",foundName));
			return address;
		} 
	}

	/* failed to find the function... */
	PRINTF(( " did not find: %s\n", symbol));
	return (void*)NULL;
}

void* ioLoadModule(char *modName) {
/* a routine to load a segment(module). Takes a pointer to the name
 * of the directory the code and links files are stored in
 */
extern char vmPath[];
const rink_version *Version;
const _kernel_oserror * e;
rink_seghandle moduleHandle;
char codeName[MAXDIRNAMELENGTH];
const rink_check CheckBlock = {"SqueakSO", 100, 0};


	/* make filename of the code */
	sprintf(codeName, "%splugins.%s", vmPath, modName);
	PRINTF(( "\\t Load: %s\n",codeName));

	/* load the segment... */
	if((e = rink_load(&CheckBlock, codeName, &moduleHandle)) != NULL) {
		PRINTF(( "\\t Plugin load failed: %s\n", codeName));
		return (void*)NULL;
	}
	
	/* OK, let's have a look at the version of the segment we've just
	 * loaded. It might be nice to check them to see that it's acceptable.
	 * It is a bad plan to alter the returned structure.
	 */
	Version = rink_readversion(moduleHandle);
	/* report the version */
	PRINTF(("\\t Plugin version: %d:%d\n", Version->main, Version->code));

	return (void*)moduleHandle;
}

sqInt ioFreeModule(void* moduleHandle) {
	PRINTF(( "\\t Plugin unload %d\n", moduleHandle));
	rink_unload((rink_seghandle)moduleHandle);
	return 1;
}



