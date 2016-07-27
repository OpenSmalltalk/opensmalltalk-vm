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
#include <windows.h>
#include <stdio.h>
#include <assert.h>
#include "sq.h"

HANDLE tryLoading(TCHAR *baseName, TCHAR *postfix)
{
  TCHAR* libName = NULL;
  HANDLE h = NULL;
  int postfix_sz = _tcslen(postfix);

  if (postfix_sz == 0) {
    /* no need to copy */
    libName = baseName;
  } else {
    libName = (TCHAR*) alloca((_tcslen(baseName) + postfix_sz + 1) * sizeof(TCHAR));
    lstrcpy(libName, baseName);
    lstrcat(libName, postfix);
  }
  h = LoadLibrary(libName);
  if (h == NULL
#ifdef NDEBUG /* in production ignore errors for non-existent modules */
   && GetLastError() != ERROR_MOD_NOT_FOUND
#endif
      )
    vprintLastError(TEXT("LoadLibrary(%s)"), libName);
  return h;
}

/* Return the module entry for the given module name */
void *ioLoadModule(char *pluginName)
{
  HANDLE handle = NULL;
  BOOL found = FALSE;
  TCHAR* name = NULL;

  UTF8_TO_TCHAR(pluginName, name);
  /*
    Try a few search paths for the module. Note that tryLoading/LoadLibrary
    already take care of tying to load with appended .dll path, so we don't
    need to do that on our own.
  */
#define _TRY_MODULE(NAME, SUFFIX) if (found || (handle = tryLoading(NAME, SUFFIX))) found = TRUE

  /* Search for module in the default path */
  _TRY_MODULE(name, TEXT(""));
  _TRY_MODULE(name, TEXT("32"));

  if (found) return handle;

  /* Also search in the image path */
  SetDllDirectory(imagePath);
  _TRY_MODULE(name, TEXT(""));
  _TRY_MODULE(name, TEXT("32"));
  SetDllDirectory(NULL);

#undef _TRY_MODULE

  return handle;
}

#if SPURVM
void *
ioFindExternalFunctionInAccessorDepthInto(char *lookupName, void *moduleHandle,
											sqInt *accessorDepthPtr)
{
	void *f;
	char buffer[256];

# ifdef UNICODE
	f = GetProcAddress(moduleHandle, toUnicode(lookupName));
# else
	f = GetProcAddress(moduleHandle, lookupName);
# endif
	if (f && accessorDepthPtr) {
		void *accessorDepthVarPtr;
		snprintf(buffer,256,"%sAccessorDepth",lookupName);
# ifdef UNICODE
		accessorDepthVarPtr = GetProcAddress(moduleHandle, toUnicode(buffer));
# else
		accessorDepthVarPtr = GetProcAddress(moduleHandle, buffer);
# endif
		/* The Slang machinery assumes accessor depth defaults to -1, which
		 * means "no accessor depth".  It saves space not outputting -1 depths.
		 */
		*accessorDepthPtr = accessorDepthVarPtr
								? *(signed char *)accessorDepthVarPtr
								: -1;
	}
	return f;
}
#else /* SPURVM */
void *
ioFindExternalFunctionIn(char *lookupName, void *moduleHandle)
{
# ifdef UNICODE
	return GetProcAddress((HANDLE)moduleHandle, toUnicode(lookupName));
# else
	return GetProcAddress((HANDLE)moduleHandle, lookupName);
# endif
}
#endif /* SPURVM */

sqInt ioFreeModule(void *moduleHandle)
{
	return FreeLibrary((HANDLE) moduleHandle);
}
