/*
 * Squeak plugin functions for Plan9.
 *
 * Author: Alex Franchuk (alex.franchuk@gmail.com)
 */

#include "sq.h"
#include <stdio.h>

/* ioLoadModule:
	Load a module from disk.
	WARNING: this always loads a *new* module. Don't even attempt to find
	a loaded one.
	WARNING: never primitiveFail() within, just return 0
*/
void *ioLoadModule(char *pluginName) {
	return 0;
}

/* ioFindExternalFunctionIn:
	Find the function with the given name in the moduleHandle.
	WARNING: never primitiveFail() within, just return 0.
*/
void *ioFindExternalFunctionIn(char *lookupName, void *moduleHandle) {
	return 0;
}

/* ioFreeModule:
	Free the module with the associated handle.
	WARNING: never primitiveFail() within, just return 0.
*/
sqInt ioFreeModule(void *moduleHandle) {
	return 0;
}
