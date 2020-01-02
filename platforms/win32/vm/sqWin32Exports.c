#include <stdio.h>
#include "interp.h"
#include "sqMemoryAccess.h"

char * GetAttributeString(sqInt id);
#if !NewspeakVM
int win32JoystickDebugInfo(void);
int win32JoystickDebugPrintRawValues(void);
int win32JoystickDebugPrintAlternativeValues(void);
#endif
#ifndef NO_NETWORK
int win32DebugPrintSocketState(void);
#endif
sqInt primitivePluginBrowserReady(void);
sqInt primitivePluginRequestURLStream(void);
sqInt primitivePluginRequestURL(void);
sqInt primitivePluginPostURL(void);
sqInt primitivePluginRequestFileHandle(void);
sqInt primitivePluginDestroyRequest(void);
sqInt primitivePluginRequestState(void);
sqInt primitiveDnsInfo(void);

extern void* stWindow;
extern void* firstMessageHook;
extern void* preMessageHook;
extern int fUseOpenGL;

#define XFN(export) {"", #export, (void*)export},
#define XFND(export,depth) {"", #export "\000" depth, (void*)export},
#define XVAR(export) {"", #export, &export},

void *os_exports[][3] = {
	XFN(GetAttributeString)
#if !NewspeakVM
	XFN(win32JoystickDebugInfo)
	XFN(win32JoystickDebugPrintRawValues)
	XFN(win32JoystickDebugPrintAlternativeValues)
#endif
#ifndef NO_NETWORK
	XFN(win32DebugPrintSocketState)
#endif
	XFND(primitivePluginBrowserReady,"\377")
	XFND(primitivePluginRequestURLStream,"\001")
	XFND(primitivePluginRequestURL,"\001")
	XFND(primitivePluginPostURL,"\001")
	XFND(primitivePluginRequestFileHandle,"\000")
	XFND(primitivePluginDestroyRequest,"\000")
	XFND(primitivePluginRequestState,"\000")
	XFND(primitiveDnsInfo,"\377")
	XFN(printf)
	XVAR(stWindow)
	XVAR(firstMessageHook)
	XVAR(preMessageHook)
	XVAR(fUseOpenGL)
	{NULL,NULL, NULL}
};
