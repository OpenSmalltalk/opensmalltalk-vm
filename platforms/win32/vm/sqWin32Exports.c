#include <stdio.h>
#include "interp.h"
#include "sqMemoryAccess.h"

const char *getAttributeString(sqInt id);
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

extern void *stWindow;
extern void *firstMessageHook;
extern void *preMessageHook;
extern int fUseOpenGL;

#define XFN(export) {"", #export, (void*)export},
#define XFEN(export,name) {"", name, (void*)export},
#define XFNDF(export,depth,flags) {"", #export "\000" depth flags, (void*)export},
#define XVAR(export) {"", #export, &export},

void *os_exports[][3] = {
	XFN(getAttributeString)
	XFEN(getAttributeString,"GetAttributeString") // backwards compatibility for UnixOSProcessPlugin
#ifndef NO_NETWORK
	XFN(win32DebugPrintSocketState)
#endif
	XFNDF(primitivePluginBrowserReady,"\377","\000")
	XFNDF(primitivePluginRequestURLStream,"\001","\000")
	XFNDF(primitivePluginRequestURL,"\001","\000")
	XFNDF(primitivePluginPostURL,"\001","\000")
	XFNDF(primitivePluginRequestFileHandle,"\000","\000")
	XFNDF(primitivePluginDestroyRequest,"\000","\000")
	XFNDF(primitivePluginRequestState,"\000","\000")
	XFNDF(primitiveDnsInfo,"\377","\000")
	XFN(printf)
	XVAR(stWindow)
	XVAR(firstMessageHook)
	XVAR(preMessageHook)
	XVAR(fUseOpenGL)
	{NULL,NULL, NULL}
};
