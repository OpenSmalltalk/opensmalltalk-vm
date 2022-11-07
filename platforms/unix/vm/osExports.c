#include "sqMemoryAccess.h"

#define XFN(export) {"", #export, (void*)export},
#define XFEN(export,name) {"", name, (void*)export},
#define XFNDF(export,depth,flags) {"", #export "\000" depth flags, (void*)export},

const char *getAttributeString(sqInt id);
#if !defined(HEADLESS)
sqInt   primitivePluginBrowserReady(void);
sqInt   primitivePluginRequestURLStream(void);
sqInt   primitivePluginRequestURL(void);
sqInt   primitivePluginPostURL(void);
sqInt   primitivePluginRequestFileHandle(void);
sqInt   primitivePluginDestroyRequest(void);
sqInt   primitivePluginRequestState(void);
void *ioGetDisplay(void);
void *ioGetWindow(void);
#endif

void *os_exports[][3]=
{
	XFN(getAttributeString) // Used by e.g. UnixOSProcessPlugin
	XFEN(getAttributeString,"GetAttributeString") // backwards compatibility for UnixOSProcessPlugin
#if !defined(HEADLESS)
	XFNDF(primitivePluginBrowserReady,"\377","\000")
	XFNDF(primitivePluginRequestURLStream,"\001","\000")
	XFNDF(primitivePluginRequestURL,"\001","\000")
	XFNDF(primitivePluginPostURL,"\001","\000")
	XFNDF(primitivePluginRequestFileHandle,"\000","\000")
	XFNDF(primitivePluginDestroyRequest,"\000","\000")
	XFNDF(primitivePluginRequestState,"\000","\000")
	XFN(ioGetDisplay)
	XFN(ioGetWindow)
#endif
	{ 0, 0, 0 }
};
