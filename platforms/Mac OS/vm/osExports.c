/* note: this file is only a backward compatible wrapper
   for the old-style "platform.exports" definitions.
   If your platform has migrated to the new exports
   style you may as well insert the exports right here */

#include "sqVirtualMachine.h"
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
#define XFND(export,depth) {"", #export "\000" depth, (void*)export},

WindowPtr getSTWindow(void);
void setMessageHook(eventMessageHook theHook);
void setPostMessageHook(eventMessageHook theHook);
char * GetAttributeString(int id);
#if !NewspeakVM
int serialPortSetControl(int portNum,int control, char *data);
int serialPortIsOpen(int portNum);
int serialPortNames(int portNum, char *portName, char *inName, char *outName);
#endif
Boolean IsKeyDown(void);
int primitivePluginBrowserReady(void);
#ifdef ENABLE_URL_FETCH
int primitivePluginDestroyRequest(void);
int primitivePluginRequestFileHandle(void);
int primitivePluginRequestState(void);
int primitivePluginRequestURL(void);
int primitivePluginRequestURLStream(void);
int primitivePluginPostURL(void);
#endif

void *os_exports[][3] = {
	XFN(getSTWindow)
	XFN(setMessageHook)
	XFN(setPostMessageHook)
	XFN(GetAttributeString)
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
	XFND(primitivePluginBrowserReady,"\377")
#ifdef ENABLE_URL_FETCH
	XFND(primitivePluginRequestURLStream,"\001")
	XFND(primitivePluginRequestURL,"\001")
	XFND(primitivePluginPostURL,"\001")
	XFND(primitivePluginRequestFileHandle,"\000")
	XFND(primitivePluginDestroyRequest,"\000")
	XFND(primitivePluginRequestState,"\000")
#endif
	{NULL, NULL, NULL}
};
