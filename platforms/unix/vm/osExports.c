#include "sqMemoryAccess.h"

#define XFN(export) {"", #export, (void*)export},
#define XFND(export,depth) {"", #export "\000" depth, (void*)export},

char * GetAttributeString(sqInt id);
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
  XFN(GetAttributeString)
#if !defined(HEADLESS)
	XFND(primitivePluginBrowserReady,"\377")
	XFND(primitivePluginRequestURLStream,"\001")
	XFND(primitivePluginRequestURL,"\001")
	XFND(primitivePluginPostURL,"\001")
	XFND(primitivePluginRequestFileHandle,"\000")
	XFND(primitivePluginDestroyRequest,"\000")
	XFND(primitivePluginRequestState,"\000")
	XFN(ioGetDisplay)
	XFN(ioGetWindow)
#endif
  { 0, 0, 0 }
};
