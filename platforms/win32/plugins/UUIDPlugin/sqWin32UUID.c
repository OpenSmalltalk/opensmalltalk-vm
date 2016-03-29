/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32UUID.c
*   CONTENT: UUID support
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: 
*   EMAIL:   Andreas.Raab@gmx.de
*
*****************************************************************************/
#include <windows.h>
#include <ole2.h>
#include "sq.h"

int
sqUUIDInit(void) { return 1; }

int
sqUUIDShutdown(void) { return 1; }

#if defined(SQUEAK_BUILTIN_PLUGIN)
# define FAIL() primitiveFail()
#else
extern struct VirtualMachine *interpreterProxy;
# define FAIL() interpreterProxy->primitiveFail()
#endif

int
MakeUUID(char *location) {
	if (CoCreateGuid((GUID*)location) == S_OK)
		return 1;
	FAIL();
	return 0;
}

