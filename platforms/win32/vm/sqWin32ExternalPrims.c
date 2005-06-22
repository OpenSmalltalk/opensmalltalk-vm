/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32ExternalPrims.c
*   CONTENT: External (named) primitive support
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*   RCSID:   $Id$
*
*   NOTES:
*     1) Currently, we're looking for DLLs named either sample.dll or sample32.dll
*
*****************************************************************************/
#include <windows.h>
#include <stdio.h>
#include <assert.h>
#include "sq.h"

HANDLE tryLoading(TCHAR *prefix, TCHAR *baseName, TCHAR *postfix)
{
  TCHAR libName[300];
  HANDLE h;

  lstrcpy(libName,prefix);
  lstrcat(libName,baseName);
  lstrcat(libName,postfix);
  h = LoadLibrary(libName);
#ifndef NDEBUG
  if(h == NULL)
    printLastError(TEXT("LoadLibrary failed"));
#endif
  return h;
}

/* Return the module entry for the given module name */
void *ioLoadModule(char *pluginName)
{
	HANDLE handle;
	TCHAR *name;

#ifdef UNICODE
	name = toUnicode(pluginName);
#else
	name = pluginName;
#endif

	handle = tryLoading(TEXT(""),name,TEXT(""));
	if(handle) return handle;
	handle = tryLoading(TEXT(""),name,TEXT(".dll"));
	if(handle) return handle;
	handle = tryLoading(TEXT(""),name,TEXT("32.dll"));
	if(handle) return handle;
	handle = tryLoading(imagePath,name,TEXT(""));
	if(handle) return handle;
	handle = tryLoading(imagePath,name,TEXT(".dll"));
	if(handle) return handle;
	handle = tryLoading(imagePath,name,TEXT("32.dll"));
	if(handle) return handle;
	return 0;
}

void *ioFindExternalFunctionIn(char *lookupName, void *moduleHandle)
{
#ifdef UNICODE
	return GetProcAddress((HANDLE)moduleHandle, toUnicode(lookupName));
#else
	return GetProcAddress((HANDLE)moduleHandle, lookupName);
#endif
}

sqInt ioFreeModule(void *moduleHandle)
{
	return FreeLibrary((HANDLE) moduleHandle);
}
