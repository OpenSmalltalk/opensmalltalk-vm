/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32ExternalPrims.c
*   CONTENT: External (named) primitive support
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*   RCSID:   $Id: sqWin32ExternalPrims.c,v 1.1 2001/10/24 23:14:28 rowledge Exp $
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
int ioLoadModule(char *pluginName)
{
	HANDLE handle;
	TCHAR *name;

#ifdef UNICODE
	name = toUnicode(pluginName);
#else
	name = pluginName;
#endif

	handle = tryLoading(TEXT(""),name,TEXT(""));
	if(handle) return (int) handle;
	handle = tryLoading(TEXT(""),name,TEXT(".dll"));
	if(handle) return (int) handle;
	handle = tryLoading(TEXT(""),name,TEXT("32.dll"));
	if(handle) return (int) handle;
	handle = tryLoading(imagePath,name,TEXT(""));
	if(handle) return (int) handle;
	handle = tryLoading(imagePath,name,TEXT(".dll"));
	if(handle) return (int) handle;
	handle = tryLoading(imagePath,name,TEXT("32.dll"));
	if(handle) return (int) handle;
	return 0;
}

int ioFindExternalFunctionIn(char *lookupName, int moduleHandle)
{
#ifdef UNICODE
	return (int) GetProcAddress((HANDLE)moduleHandle, toUnicode(lookupName));
#else
	return (int) GetProcAddress((HANDLE)moduleHandle, lookupName);
#endif
}

int ioFreeModule(int moduleHandle)
{
	return FreeLibrary((HANDLE) moduleHandle);
}
