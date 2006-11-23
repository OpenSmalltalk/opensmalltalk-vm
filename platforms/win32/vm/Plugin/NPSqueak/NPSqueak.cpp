//
// npshell.cpp - Plug-in methods called from Netscape.
//

#include <windows.h>
#include <string.h>
#include <stdio.h>
#include <process.h>
#include "npapi.h"

#include "../sqWin32Plugin.h"

static char* NPN_StrDup(const char* s)
{
  return strcpy((char* )NPN_MemAlloc(strlen(s) + 1), s);
}

 char *prefix="SQK";  /*prefix for temporary files*/

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
//helper function if file for url exists
//


sqStreamRequest squeakRequests[MAX_STREAMS];
static int streamCount=0;
void RegisterNewRequest (int id, char* url)
{
   if(streamCount < MAX_STREAMS) {
	squeakRequests[streamCount].url = NPN_StrDup(url);
	squeakRequests[streamCount].id = id;
	squeakRequests[streamCount].file = 0;
	squeakRequests[streamCount].localName = 0;
	DPRINT("NP:  streamRequest registered for %s (id: %d)as nr: %i\n",squeakRequests[streamCount].url,id,streamCount);
	streamCount++;
	return;
    }
   else{
     MessageBox(0, "Maximum number of requests reached", "Squeak Plugin", MB_OK);

   }
DPRINT("NP:  streamRequest notregistered for %d\n",id);
}

void UnregisterRequest (int id, char* url)
{
   for(int i=0; (i < streamCount && i < MAX_STREAMS); i++) {
      if(squeakRequests[i].id == id)  {
	DPRINT("NP:  streamRequest unregistered for %s (id:%d)\n",url,id);
	NPN_MemFree(squeakRequests[i].url);
	squeakRequests[i].id = -1;
	squeakRequests[i].localName = 0;
	streamCount--;
	return;
      }
    } 
   DPRINT("NP: unreg streamRequest not found for %s (id:%d)\n",url,id);
}

sqStreamRequest* RequestForId (int id)
{
   for(int i=0; (i < streamCount && i < MAX_STREAMS); i++) {
      if(squeakRequests[i].id == id)  {
	DPRINT("NP:  streamRequest found for %s (id: %d)\n",squeakRequests[i].url,id);
	return &squeakRequests[i]; 
      }
    }
   DPRINT("NP: streamRequest not found for %d\n",id);
   return 0;
}


void StoreLocalNameForID (char* fname, int id)
{
   for(int i=0; (i < streamCount && i < MAX_STREAMS); i++) {
      if(squeakRequests[i].id == id)  {
	DPRINT("NP:  storing filename %s for(id: %d)\n",fname,id);
	squeakRequests[i].localName = fname; 
	return;
      }
    }
   DPRINT("NP: no request found for %s (id:%d)\n",fname,id);
}

void StoreLocalNameForUrl (char* fname, char *url)
{
   for(int i=0; (i < streamCount && i < MAX_STREAMS); i++) {
      if(squeakRequests[i].url && (stricmp(squeakRequests[i].url,url)== 0))  {
	DPRINT("NP:  storing filename %s for(url: %s)\n",fname,url);
	squeakRequests[i].localName = fname; 
	return;
      }
    }
   DPRINT("NP: no request found for %s (url:%s)\n",fname,url);
}

int IsRegisteredRequest (int id)
{
   for(int i=0; (i < streamCount && i < MAX_STREAMS); i++) {
      if(squeakRequests[i].id == id)  {
	return 1;
      }
    } 
   return 0;
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
  sqStreamRequest *streamRequest=0;
  int id = (int) stream->notifyData;

  DPRINT("NP: NPP_NewStream(%s, id=%i)\n", stream->url, id);

  streamRequest = RequestForId (id);

  if(squeak) {
     if(streamRequest && streamRequest->file)*stype = NP_NORMAL;
     else *stype = NP_ASFILEONLY;
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
	return 16384;
}


//
// NPP_Write - Here is some data. Return -1 to abort stream.
// 
int32 NP_LOADDS NPP_Write (NPP pInstance, NPStream *stream, int32 offset, int32 len, void *buffer)
{
 sqStreamRequest *streamRequest= 0;
 streamRequest = RequestForId ((int)stream->notifyData);

 if(!streamRequest){
	DPRINT("NP: unknowRequest for writing\n");
	return len;
   }
  DPRINT("NP:  writing for request %s \n", streamRequest->localName);

  if (streamRequest && streamRequest->file)
    {
      int n;
      n= fwrite(buffer, 1, len, streamRequest->file);
      DPRINT("NP:  writing to %s - wrote %d bytes of %d\n", streamRequest->localName, n,len);
      return n;
    }
  else
    DPRINT("NP:  ignored\n");
  return len;
}

//
// NPP_DestroyStream - Stream is done, but audio may still be playing.
// 
NPError NP_LOADDS NPP_DestroyStream (NPP pInstance, NPStream *stream, NPError reason)
{
  SqueakPlugin *squeak = (SqueakPlugin*) pInstance->pdata;
  DPRINT("NP: NPP_DestroyStream(%s, id=%i)\n", stream->url,(int) stream->notifyData);
 
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

//
//erase all the temporary created files, because of the Netscape/Firefox bug
//

void  CleanupTemporaryFiles()
{
  WIN32_FIND_DATA findData;
  HANDLE hFind;
  DWORD dwError;

  char temppath[1024];
  char tempfile[1030];

  GetTempPath(1024,temppath);
  strcpy(tempfile,temppath);
  strcat(tempfile,prefix);
  strcat(tempfile,"*");  
  DPRINT ("tmpfile: %s\n",   tempfile);
  hFind = FindFirstFile(tempfile, &findData);
  if (hFind == INVALID_HANDLE_VALUE) 
  {
    DPRINT ("Invalid File Handle. GetLastError reports %d\n", 
            GetLastError ());    
  } 
  else 
  {
    strcpy(tempfile,temppath);
    strcat(tempfile,findData.cFileName);
    DPRINT ("The first file found is %s\n", 
            tempfile);
    DeleteFile(tempfile);

      while (FindNextFile(hFind, &findData) != 0) 
      {
	strcpy(tempfile,temppath);
	strcat(tempfile,findData.cFileName);
	DeleteFile(tempfile);
        DPRINT ("Next file name is %s.\n", tempfile);
      }
    
      dwError = GetLastError();
      FindClose(hFind);
      if (dwError != ERROR_NO_MORE_FILES) 
      {
         DPRINT ("FindNextFile error. Error is %u.\n", dwError);
      } 
  }
}

void NPP_Shutdown(void)
{
   CleanupTemporaryFiles();


}

jref NP_LOADDS NPP_GetJavaClass (void)
{
  return NULL;
}

void NP_LOADDS NPP_StreamAsFile (NPP pInstance, NPStream* stream, const char* fname)
{
  SqueakPlugin *squeak = (SqueakPlugin*) pInstance->pdata;
  int id = (int)stream->notifyData;

  DPRINT("NP: StreamAsFile(%s) (id: %i)\n", stream->url,id);
  DPRINT("NP:   fname=%s\n", fname ? fname : "<NULL>");

  StoreLocalNameForID ((char*) fname, id );

  if(squeak) {
	  SqueakPluginStreamFile(squeak, (char*) stream->url, (char*)fname, id);
  }
}


void NP_LOADDS NPP_Print (NPP pInstance, NPPrint* printInfo)
{
}

void NP_LOADDS
NPP_URLNotify(NPP pInstance, const char* url, NPReason reason, void* notifyData)
{
  int id= (int)notifyData;
  int ok= reason == NPRES_DONE;
  sqStreamRequest *streamRequest=0;
  
  SqueakPlugin *squeak = (SqueakPlugin*) pInstance->pdata;


   DPRINT("NP: NPP_URLNotify(%s, reason=%s, id=%i, ok=%i)\n", url,
	 (reason == NPRES_DONE ? "NPRES_DONE" : 
	  (reason == NPRES_USER_BREAK ? "NPRES_USER_BREAK" :
		   (reason == NPRES_NETWORK_ERR ? "NPRES_NETWORK_ERR" :
	    "<unknown>"))),
	 id, ok);

 streamRequest = RequestForId (id);
   if(!streamRequest){
	DPRINT("NP: unknowRequest\n");
	return;
   }


  if (streamRequest)
    {
      DPRINT("NP:  streamRequestor after search %d localName:%s\n",streamRequest,streamRequest->localName);

          if (-1 != id && ok && !(streamRequest)->localName)
	{
	  /* Work around netscape/firefox bug */
	  char tmpname[1024];
	  char temppath[1024];
	  FILE *tmpfd; 
	  DPRINT("NP:  Netscape bug: did not get url as file\n");
	
	  GetTempPath(1024,temppath);
	
	  if (!(GetTempFileName(temppath, prefix,0,tmpname)))
	    {
	      MessageBox(0, "Temporary File Creation failed \n(in netscape/firefox bug workaround)", "Squeak Plugin", MB_OK);
	      DPRINT("NP: Squeak plugin tmp file open failed\n");
	    }
	  else
	    {
	      DPRINT("NP:  open new tmp file(%s)!\n",tmpname);
	      tmpfd = fopen(tmpname,"w+b");
	      (streamRequest)->localName= NPN_StrDup(tmpname);
	      (streamRequest)->file= tmpfd;
	      DPRINT("NP:   Trying again as stream (%s)\n", tmpname);
	      DPRINT("NP: NPN_GetURLNotify(%s, id=%i)\n", url, id);
	      NPN_GetURLNotify(pInstance, url, NULL, notifyData);
	      return;
	    }
	}
      if ((streamRequest)->file)
	{ 
	  DPRINT("NP:  closing tmp file!\n");
	  fclose((streamRequest)->file);
	  (streamRequest)->file = 0;
	  DPRINT("NP:  Netscape bug workaround successful!\n");
	  if(squeak) {
	    SqueakPluginStreamFile(squeak, (char*) url, streamRequest->localName ,id);
	  }	  
	}
      DPRINT("NP:   free memory\n" );
      if (streamRequest->localName)
		NPN_MemFree(streamRequest->localName);
		NPN_MemFree(notifyData);
    }

 if (squeak)
 {
   DPRINT("NP:   notifying squeak\n" );
   UnregisterRequest (id, (char*) url);
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
	
	RegisterNewRequest (id, url);
	NPError err;
	if(ieMode)
	    err = NPN_GetURL((NPP)instance, url, target);
	else	
	{
	    DPRINT("NP:  GetURLNotify %s (id %d)\n", url,id);
	    err = NPN_GetURLNotify((NPP)instance, url, target, (void*) id);
	}
}

void SqueakPluginPostData(void *instance, char *url, char *target, char *data, int id)
{
	NPError err;
	if(ieMode)
	    err = NPN_PostURL((NPP)instance, url, target, data ? strlen(data) : 0, data, 0);
	else
	    err = NPN_PostURLNotify((NPP)instance, url, target, data ? strlen(data) : 0, data, 0, (void*) id);
}
