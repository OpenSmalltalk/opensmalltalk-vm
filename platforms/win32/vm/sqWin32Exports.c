#include <stdio.h>

int win32JoystickDebugInfo(void);
int win32JoystickDebugPrintRawValues(void);
int win32JoystickDebugPrintAlternativeValues(void);
int win32DebugPrintSocketState(void);
int primitivePluginBrowserReady(void);
int primitivePluginRequestURLStream(void);
int primitivePluginRequestURL(void);
int primitivePluginPostURL(void);
int primitivePluginRequestFileHandle(void);
int primitivePluginDestroyRequest(void);
int primitivePluginRequestState(void);

extern void* stWindow;
extern void* firstMessageHook;
extern void* preMessageHook;
extern int fUseOpenGL;

void *os_exports[][3] = {
  {"","win32JoystickDebugInfo", win32JoystickDebugInfo},
  {"","win32JoystickDebugPrintRawValues", win32JoystickDebugPrintRawValues},
  {"","win32JoystickDebugPrintAlternativeValues", win32JoystickDebugPrintAlternativeValues},
  {"","win32DebugPrintSocketState", win32DebugPrintSocketState},
  {"","primitivePluginBrowserReady", primitivePluginBrowserReady},
  {"","primitivePluginRequestURLStream", primitivePluginRequestURLStream},
  {"","primitivePluginRequestURL", primitivePluginRequestURL},
  {"","primitivePluginPostURL", primitivePluginPostURL},
  {"","primitivePluginRequestFileHandle", primitivePluginRequestFileHandle},
  {"","primitivePluginDestroyRequest", primitivePluginDestroyRequest},
  {"","primitivePluginRequestState", primitivePluginRequestState},
  {"", "printf", printf},
  {"","stWindow", &stWindow},
  {"","firstMessageHook", &firstMessageHook},
  {"","preMessageHook", &preMessageHook},
  {"","fUseOpenGL", &fUseOpenGL},
  {NULL,NULL, NULL}
};

