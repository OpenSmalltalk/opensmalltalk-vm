/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Plugin.h
*   CONTENT: Generic Squeak Plugin Header
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*   RCSID:   $Id: sqWin32Plugin.h,v 1.1 2001/02/10 08:51:40 anonymous Exp $
*
*   NOTES:
*
*****************************************************************************/
#ifndef SQ_WIN32_PLUGIN_H
#define SQ_WIN32_PLUGIN_H

#define MAX_STREAMS 128

typedef struct sqStreamRequest {
  char *url;
  char *localName;
  FILE *file; /* file */
  int id;
  int state;
} sqStreamRequest;

typedef struct SqueakPlugin {
  PROCESS_INFORMATION processInfo;
  HWND hWnd;
  WNDPROC prevWindowProc;
  void *cbData;

  HANDLE hParentReadEnd;
  HANDLE hParentWriteEnd;

  HANDLE hClientPipe;

  char vmName[MAX_PATH];
  char imageName[MAX_PATH];
  char *vmParams;
  char *params;
  int paramSize;
  int memory;

  /* stream requests */
  sqStreamRequest requests[MAX_STREAMS];
  int maxStreams;
} SqueakPlugin;

#ifdef __cplusplus
extern "C" {
#endif
  void DPRINT(char *format, ...);
  void SqueakPluginInitialize(void);
  SqueakPlugin *SqueakPluginNew(HANDLE hPluginModule, void *cbData);
  int SqueakPluginDestroy(SqueakPlugin *squeak);
  int SqueakPluginActive(SqueakPlugin *squeak);
  int SqueakPluginRun(SqueakPlugin *squeak, HWND hWnd, int terminateOld);
  int SqueakPluginResize(SqueakPlugin *squeak, HWND hWnd);

  void SqueakPluginSetVM(SqueakPlugin *squeak, char *vmName);
  void SqueakPluginSetVMParams(SqueakPlugin *squeak, char *params);
  void SqueakPluginSetImage(SqueakPlugin *squeak, char *imageName);
  void SqueakPluginSetMemory(SqueakPlugin *squeak, char *memoryString);
  void SqueakPluginAddParam(SqueakPlugin *squeak, char *name, char *value);

  void SqueakPluginRequestStream(void *cbData, char *url, char *target, int id);
  void SqueakPluginPostData(void *instance, char *url, char *target, char *data, int id);
  void SqueakPluginStreamFile(SqueakPlugin *squeak, char *url, char *localName, int id);
  void SqueakPluginNotify(SqueakPlugin *squeak, int id, char *url, int ok);
  void SqueakPluginStreamState(SqueakPlugin *squeak, char *url, int ok);

  void SqueakPluginSetIEMode();

#ifdef __cplusplus
}
#endif

#endif
