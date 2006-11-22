//
// npshell.cpp - Plug-in methods called from Netscape.
//

#include <windows.h>
#include <string.h>
#include <stdio.h>
#include "npapi.h"

#include "../sqWin32Plugin.h"

HANDLE hPluginModule = NULL;

BOOL APIENTRY DllMain( HANDLE hModule, 
                       DWORD  ul_reason_for_call, 
                       LPVOID lpReserved
					 )
{

	if(!hPluginModule)
		hPluginModule = hModule;
    switch (ul_reason_for_call)
	{
		case DLL_PROCESS_ATTACH:
		case DLL_THREAD_ATTACH:
		case DLL_THREAD_DETACH:
		case DLL_PROCESS_DETACH:
			break;
    }
    return TRUE;
}

//
// NPP_New - Create a new plug-in instance.
//
NPError NP_LOADDS NPP_New(NPMIMEType pluginType,
                          NPP pInstance,
                          uint16 mode,
                          int16 argc,
                          char* argn[],
                          char* argv[],
                          NPSavedData* saved)
{ SqueakPlugin *squeak;
  int i;

  if(pInstance == NULL)
        return NPERR_INVALID_INSTANCE_ERROR;

  squeak = SqueakPluginNew(hPluginModule, pInstance);
  if(!squeak)
    return NPERR_OUT_OF_MEMORY_ERROR;

  if(strncmp(NPN_UserAgent(pInstance), "Microsoft Internet Explorer", 27) == 0)
	  SqueakPluginSetIEMode();

  for(i=0;i<argc;i++) {
	  if(stricmp(argn[i],"imageName") == 0) {
		  SqueakPluginSetImage(squeak, argv[i]);
	  }
	  if(stricmp(argn[i],"vmName") == 0) {
		  SqueakPluginSetVM(squeak, argv[i]);
	  }
	  if(stricmp(argn[i],"win32Params") == 0) {
		  SqueakPluginSetVMParams(squeak, argv[i]);
	  }
	  /* Pass all other args directly */
	  SqueakPluginAddParam(squeak, argn[i], argv[i]);
  }

  pInstance->pdata = (void *)squeak;

  return NPERR_NO_ERROR;
}

//
// NPP_Destroy - Destroy our plug-in instance.
//
NPError NP_LOADDS NPP_Destroy (NPP pInstance, NPSavedData** save)
{	SqueakPlugin *squeak;

	if(pInstance == NULL)
		return NPERR_INVALID_INSTANCE_ERROR;

	squeak = (SqueakPlugin*) pInstance->pdata;
	SqueakPluginDestroy(squeak);
	pInstance->pdata = NULL;
	return NPERR_NO_ERROR;
}

//
// NPP_SetWindow - A window was created, resized, or destroyed.
//
NPError NP_LOADDS NPP_SetWindow (NPP pInstance, NPWindow* pNPWindow)
{ SqueakPlugin *squeak;
  HWND hWnd;

  if(pInstance == NULL)
    return NPERR_INVALID_INSTANCE_ERROR;

  if(pNPWindow == NULL)
    return NPERR_GENERIC_ERROR;

  hWnd = (HWND)(DWORD)pNPWindow->window;
  squeak = (SqueakPlugin*) pInstance->pdata;
  if(squeak == NULL)
	  return NPERR_GENERIC_ERROR;

  if(hWnd == NULL) // spurious entry
    return NPERR_NO_ERROR;

  if(SqueakPluginActive(squeak)) {
	SqueakPluginResize(squeak, hWnd);
  } else {
	SqueakPluginRun(squeak, hWnd, 1);
  }
  return NPERR_NO_ERROR;
}

//
// NPP_NewStream - A new stream was created.
//
NPError NP_LOADDS NPP_NewStream(NPP pInstance,
                                NPMIMEType type,
                                NPStream* stream, 
                                NPBool seekable,
                                uint16* stype)
{
  SqueakPlugin *squeak = (SqueakPlugin*) pInstance->pdata;
  if(squeak) {
	  *stype = NP_ASFILE;
  }
  return NPERR_NO_ERROR;
}


//
// NPP_WriteReady - Returns amount of data we can handle for the next NPP_Write
//                             
int32 NP_LOADDS NPP_WriteReady (NPP pInstance, NPStream *stream)
{
	if(pInstance == NULL)
		return NPERR_INVALID_INSTANCE_ERROR;
	return 0x0FFFFFFF;
}


//
// NPP_Write - Here is some data. Return -1 to abort stream.
// 
int32 NP_LOADDS NPP_Write (NPP pInstance, NPStream *stream, int32 offset, int32 len, void *buffer)
{
  return len;
}

//
// NPP_DestroyStream - Stream is done, but audio may still be playing.
// 
NPError NP_LOADDS NPP_DestroyStream (NPP pInstance, NPStream *stream, NPError reason)
{
  SqueakPlugin *squeak = (SqueakPlugin*) pInstance->pdata;
  if(squeak) {
	SqueakPluginStreamState(squeak,(char*)  stream->url, reason == NPRES_DONE);
  }
  return NPERR_NO_ERROR;
}


/**** Unused stubs ***/
NPError NPP_Initialize(void)
{
	SqueakPluginInitialize();
	return NPERR_NO_ERROR;
}

void NPP_Shutdown(void)
{
}

jref NP_LOADDS NPP_GetJavaClass (void)
{
  return NULL;
}

void NP_LOADDS NPP_StreamAsFile (NPP pInstance, NPStream* stream, const char* fname)
{
  SqueakPlugin *squeak = (SqueakPlugin*) pInstance->pdata;
  if(squeak) {
	  SqueakPluginStreamFile(squeak, (char*) stream->url, (char*)fname);
  }
}


void NP_LOADDS NPP_Print (NPP pInstance, NPPrint* printInfo)
{
}

void NP_LOADDS
NPP_URLNotify(NPP pInstance, const char* url, NPReason reason, void* notifyData)
{
  SqueakPlugin *squeak = (SqueakPlugin*) pInstance->pdata;
  if(squeak) {
	  SqueakPluginNotify(squeak, (int)notifyData, (char*) url, reason == NPRES_DONE);
  }
}

#ifdef __cplusplus
extern "C" {
#endif

extern int ieMode;

#ifdef __cplusplus
}
#endif

void SqueakPluginRequestStream(void *instance, char *url, char *target, int id)
{
	NPError err;
	if(ieMode)
		err = NPN_GetURL((NPP)instance, url, target);
	else
		err = NPN_GetURLNotify((NPP)instance, url, target, (void*) id);
}

void SqueakPluginPostData(void *instance, char *url, char *target, char *data, int id)
{
	NPError err;
	if(ieMode)
		err = NPN_PostURL((NPP)instance, url, target, data ? strlen(data) : 0, data, 0);
	else
		err = NPN_PostURLNotify((NPP)instance, url, target, data ? strlen(data) : 0, data, 0, (void*) id);
}
