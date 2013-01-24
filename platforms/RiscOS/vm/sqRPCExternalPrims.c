//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// This is sqRPCExternalPrims.c
// It connects Squeak to the external plugins in the plugins directory
// within the application.
// It relies upon 'rink' by Ben Summers, Nick Clark and Tom Hughes - Thanks!

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



