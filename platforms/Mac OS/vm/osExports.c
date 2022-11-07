/* note: this file is only a backward compatible wrapper
   for the old-style "platform.exports" definitions.
   If your platform has migrated to the new exports
   style you may as well insert the exports right here */

#include "sqVirtualMachine.h"
#include "sqMemoryAccess.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"

#include <stdio.h>
#include "sqMacUIEvents.h"
#if !NewspeakVM
# include "SerialPlugin.h"
#endif

/* duh ... this is ugly */
#define XFN(export) {"", #export, (void*)export},
#define XFEN(export,name) {"", name, (void*)export},
#define XFNDF(export,depth,flags) {"", #export "\000" depth flags, (void*)export},

WindowPtr getSTWindow(void);
void setMessageHook(eventMessageHook theHook);
void setPostMessageHook(eventMessageHook theHook);
const char *getAttributeString(sqInt id);
#if !NewspeakVM
int serialPortSetControl(int portNum,int control, char *data);
int serialPortIsOpen(int portNum);
int serialPortNames(int portNum, char *portName, char *inName, char *outName);
#endif
Boolean IsKeyDown(void);
sqInt primitivePluginBrowserReady(void);
#ifdef ENABLE_URL_FETCH
sqInt primitivePluginDestroyRequest(void);
sqInt primitivePluginRequestFileHandle(void);
sqInt primitivePluginRequestState(void);
sqInt primitivePluginRequestURL(void);
sqInt primitivePluginRequestURLStream(void);
sqInt primitivePluginPostURL(void);
#endif

void *os_exports[][3] = {
	XFN(getSTWindow)
	XFN(setMessageHook)
	XFN(setPostMessageHook)
	XFN(getAttributeString)
	XFEN(getAttributeString,"GetAttributeString") // backwards compatibility for UnixOSProcessPlugin
	XFN(recordDragDropEvent)
#if !NewspeakVM
	XFN(serialPortSetControl)
	XFN(serialPortIsOpen)
	XFN(serialPortClose)
	XFN(serialPortCount)
	XFN(serialPortNames)
	XFN(serialPortOpen)
	XFN(serialPortReadInto)
	XFN(serialPortWriteFrom)
#endif
	XFN(IsKeyDown)
	XFN(getUIToLock)
/* Plugin support primitives
   We should make these primitives a proper plugin
   but right now we just need the exports. */
	XFNDF(primitivePluginBrowserReady,"\377","\000")
#ifdef ENABLE_URL_FETCH
	XFNDF(primitivePluginRequestURLStream,"\001","\000")
	XFNDF(primitivePluginRequestURL,"\001","\000")
	XFNDF(primitivePluginPostURL,"\001","\000")
	XFNDF(primitivePluginRequestFileHandle,"\000","\000")
	XFNDF(primitivePluginDestroyRequest,"\000","\000")
	XFNDF(primitivePluginRequestState,"\000","\000")
#endif
	{NULL, NULL, NULL}
};
