#include <stdio.h>
/* duh ... this is ugly */

#define XFN(export) {"", #export, (void*)export},
#define XFN2(plugin, export) {#plugin, #export, (void*)plugin##_##export}

int primitivePluginBrowserReady(void);
int primitivePluginRequestURLStream(void);
int primitivePluginRequestURL(void);
int primitivePluginPostURL(void);
int primitivePluginRequestFileHandle(void);
int primitivePluginDestroyRequest(void);
int primitivePluginRequestState(void);

void *os_exports[][3] = {
	XFN(primitivePluginBrowserReady)
	XFN(primitivePluginRequestURLStream)
	XFN(primitivePluginRequestURL)
	XFN(primitivePluginPostURL)
	XFN(primitivePluginRequestFileHandle)
	XFN(primitivePluginDestroyRequest)
	XFN(primitivePluginRequestState)
	{NULL, NULL, NULL}
};

