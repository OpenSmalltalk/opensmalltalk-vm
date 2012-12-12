#include <stdio.h>

#define XFN(export) {"", #export, (void*)export}
#define XFN2(plugin, export) {#plugin, #export, (void*)plugin##_##export}

char * GetAttributeString(int id);
#if !defined(HEADLESS)
int   primitivePluginBrowserReady(void);
int   primitivePluginRequestURLStream(void);
int   primitivePluginRequestURL(void);
int   primitivePluginPostURL(void);
int   primitivePluginRequestFileHandle(void);
int   primitivePluginDestroyRequest(void);
int   primitivePluginRequestState(void);
void *ioGetDisplay(void);
void *ioGetWindow(void);
#endif

void *os_exports[][3]=
{
  XFN(GetAttributeString)
#if !defined(HEADLESS)
  XFN(primitivePluginBrowserReady),
  XFN(primitivePluginRequestURLStream),
  XFN(primitivePluginRequestURL),
  XFN(primitivePluginPostURL),
  XFN(primitivePluginRequestFileHandle),
  XFN(primitivePluginDestroyRequest),
  XFN(primitivePluginRequestState),
  XFN(ioGetDisplay),
  XFN(ioGetWindow),
#endif
  { 0, 0, 0 }
};
