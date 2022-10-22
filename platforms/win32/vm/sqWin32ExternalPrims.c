/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32ExternalPrims.c
*   CONTENT: External (named) primitive support
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*   NOTES:
*     1) Currently, we're looking for DLLs named either sample.dll or sample32.dll
*
*****************************************************************************/

#include <Windows.h>
#include <stdio.h>
#include <string.h>
#include <tchar.h>
#include "sq.h"
#include "sqAssert.h"

static HANDLE
tryLoading(TCHAR *prefix, TCHAR *baseName, TCHAR *postfix)
{
  TCHAR libName[300];
  HANDLE h;

  lstrcpy(libName,prefix);
  lstrcat(libName,baseName);
  lstrcat(libName,postfix);
  h = LoadLibrary(libName);
  if (h == NULL
#ifdef NDEBUG /* in production ignore errors for non-existent modules */
   && GetLastError() != ERROR_MOD_NOT_FOUND
#endif
      )
    vprintLastError(TEXT("LoadLibrary(%s)"), libName);
  return h;
}

/* Return the module entry for the given module name, or null if not found */
void *
ioLoadModule(char *pluginName)
{
	HANDLE handle;
	TCHAR *name;
	int nameLen = pluginName ? (int)strlen(pluginName) : 0;
	int endsInDLL = nameLen > 4 && !strcmp(pluginName + nameLen - 4, ".dll");

#if _UNICODE
	int len = MultiByteToWideChar(CP_UTF8, 0, pluginName, nameLen + 1, NULL, 0);
	if (len <= 0)
		return 0; /* invalid UTF8 ? */
	name = alloca(len * sizeof(WCHAR));
	if (!MultiByteToWideChar(CP_UTF8, 0, pluginName, nameLen + 1, name, len))
		return 0;
#else
	name = pluginName;
#endif

	if ((handle = tryLoading(TEXT(""),name,TEXT(""))))
		return handle;
	if (!endsInDLL) {
		if ((handle = tryLoading(TEXT(""),name,TEXT(".dll"))))
			return handle;
		if ((handle = tryLoading(TEXT(""),name,TEXT("32.dll"))))
			return handle;
	}
#if 0
	// According to the WIN32 documentation the first directory searched for
	// dlls is "The directory from which the application loaded.". This is a
	// little ambiguous but is indeed the vmPath. So there is no need to search
	// explicitly the vmPath directory. The preceding call has done this. Hence
	// the following is redundant and ifdefed out, commented for reference.
	if ((handle = tryLoading(vmPath,name,TEXT(""))))
		return handle;
	if (!endsInDLL) {
		if ((handle = tryLoading(vmPath,name,TEXT(".dll"))))
			return handle;
		if ((handle = tryLoading(vmPath,name,TEXT("32.dll"))))
			return handle;
	}
	if (!_tcscmp(imagePath,vmPath))
		return 0;
#endif
	if ((handle = tryLoading(imagePath,name,TEXT(""))))
		return handle;
	if (!endsInDLL) {
		if ((handle = tryLoading(imagePath,name,TEXT(".dll"))))
			return handle;
		if ((handle = tryLoading(imagePath,name,TEXT("32.dll"))))
			return handle;
	}
	return 0;
}

#if SPURVM
void *
ioFindExternalFunctionInMetadataInto(char *lookupName, void *moduleHandle,
											sqInt *metadataPtr)
{
	void *f;
	char buffer[256];

	f = GetProcAddress(moduleHandle, lookupName);
	if (f && metadataPtr) {
		void *metadataVarPtr;
		snprintf(buffer,256,"%sMetadata",lookupName);
		metadataVarPtr = GetProcAddress(moduleHandle, buffer);
		/* The Slang machinery assumes accessor depth defaults to -1, which
		 * means "no accessor depth".  It saves space not outputting null metadata.
		 */
		*metadataPtr = metadataVarPtr
								? *(SpurPrimitiveMetadataType *)metadataVarPtr
								: NullSpurMetadata;
		assert(validSpurPrimitiveMetadata(*metadataPtr));
	}
	return f;
}
#else /* SPURVM */
void *
ioFindExternalFunctionIn(char *lookupName, void *moduleHandle)
{
	return GetProcAddress((HANDLE)moduleHandle, lookupName);
}
#endif /* SPURVM */

sqInt
ioFreeModule(void *moduleHandle)
{ return FreeLibrary((HANDLE) moduleHandle); }
