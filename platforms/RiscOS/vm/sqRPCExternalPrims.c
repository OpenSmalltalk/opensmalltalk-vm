/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
/*  Known to work on RiscOS 3.7 for StrongARM RPCs, other machines        */
/*  not yet tested.                                                       */
/*                       sqRPCExternalPrims.c                             */
/* hook up to RiscOS external code modules using 'rink'                   */
/**************************************************************************/
#include "oslib/os.h"
#include "sq.h"
#include <kernel.h>
#include "rink.h"

// define this to get lots of debug notifiers
//#define dbg
#ifdef dbg
#define FPRINTF(s)\
{\
	extern os_error privateErr;\
	extern void platReportError( os_error * e);\
	privateErr.errnum = (bits)0;\
	sprintf s;\
	platReportError((os_error *)&privateErr);\
};
#else
#define FPRINTF(s) 
#endif



int ioFindExternalFunctionIn(char *symbol, int moduleHandle) {
// find the function named symbol in the known loaded module moduleHandle
int fnIndex, address;
char * foundName;
	fnIndex = 0;
	FPRINTF((privateErr.errmess, "ioFindExternalFunctionIn: (%d)%s", strlen(symbol), symbol));

	do {
		address = (int)rink_enum_named((rink_seghandle)moduleHandle, &fnIndex, &foundName);

		if ( strcmp(foundName, symbol) == 0) {
			return address;
		} 
	} while(fnIndex >= 0);
	// failed to find the function...
	FPRINTF((privateErr.errmess, " did not find: %s",foundName));
	return 0;
}

int ioLoadModule(char *modName) {
// a routine to load a segment(module). Takes a pointer to the name
// of the directory the code and links files are stored in
extern char vmPath[];
rink_version *Version;
_kernel_oserror * e;
rink_seghandle moduleHandle;
char codeName[256];
char linksName[256];
rink_check CheckBlock;


	// make filename of the code and links
	sprintf(codeName, "%splugins.%s.Code", vmPath, modName);
	sprintf(linksName, "%splugins.%s.Links", vmPath, modName);
	FPRINTF((privateErr.errmess, "Load: %s",modName));
	
	// set up the check block
	strcpy(CheckBlock.id, "SqueakSO");
	CheckBlock.main_version = 100;
	CheckBlock.code_version = 0;
	
	// load the segment...
	if((e = rink_load(codeName, linksName, &moduleHandle, &CheckBlock)) != NULL) {
		FPRINTF((privateErr.errmess, "Plugin load failed: %s", codeName));
		return 0;
	}
	
	// OK, let's have a look at the version of the segment we've just loaded.
	// It might be nice to check them to see that it's acceptable.
	// It is a bad plan to alter the returned structure.
	Version = rink_readversion(moduleHandle);
	// report the version
	//FPRINTF( (privateErr.errmess, "Plugin version: %d:%d", Version->main, Version->code));

	return (int)moduleHandle;
}

int ioFreeModule(int moduleHandle) {
	FPRINTF( (privateErr.errmess, "Plugin unload %d", moduleHandle));
	rink_unload((rink_seghandle)moduleHandle);
	return 1;
}



