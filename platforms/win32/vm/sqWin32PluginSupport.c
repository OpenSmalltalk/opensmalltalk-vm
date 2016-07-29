/* Plugin support primitives */
#include <windows.h>
#include "sq.h"
#include "../plugins/FilePlugin/FilePlugin.h"

/* from VM */
sqInt methodArgumentCount(void);

#ifdef DO_DPRINTF
#define DPRINTF(x) DPRINTF x
#else
#define DPRINTF(x)
#endif

DWORD g_WM_QUIT_SESSION = 0; /* Request to quit squeak session */
DWORD g_WM_BWND_SIZE = 0;    /* Browser window size changed */
DWORD g_WM_REQUEST_DATA = 0; /* Request data from browser */
DWORD g_WM_POST_DATA = 0;    /* Post data to browser */
DWORD g_WM_RECEIVE_DATA = 0; /* Receive data from browser */
DWORD g_WM_INVALIDATE = 0;   /* Invalidate portion of window */
DWORD g_WM_BROWSER_PIPE = 0; /* Browser pipe */
DWORD g_WM_CLIENT_PIPE = 0;  /* Client pipe */


sqInt stackObjectValue(sqInt);
sqInt stackIntegerValue(sqInt);
sqInt isBytes(sqInt);
sqInt byteSizeOf(sqInt);
void *firstIndexableField(sqInt);
sqInt push(sqInt);
sqInt pop(sqInt);
sqInt positive32BitIntegerFor(sqInt);
sqInt nilObject(void);
sqInt instantiateClassindexableSize(sqInt, sqInt);
sqInt classByteArray(void);
sqInt fileRecordSize(void);
SQFile *fileValueOf(sqInt);
sqInt failed(void);
sqInt pushBool(sqInt);
sqInt getFullScreenFlag(void);

void pluginGetURLRequest(int id, void* urlIndex, int urlSize, 
			 void* targetIndex, int targetSize);
void pluginPostURLRequest(int id, void* urlIndex, int urlSize, 
			  void* targetIndex, int targetSize, 
			  void* postDataIndex, int postDataSize);

typedef struct sqStreamRequest {
	char *localName;
	int semaIndex;
	int state;
} sqStreamRequest;

#define MAX_REQUESTS 128
static sqStreamRequest *requests[MAX_REQUESTS];

static HANDLE hBrowserPipe = NULL;
static HANDLE hClientReadEnd = NULL;
static HANDLE hClientWriteEnd = NULL;

static int isFileURL(int urlOop) {
  int urlLen;
  char *urlPtr;
  urlLen = byteSizeOf(urlOop);
  urlPtr = firstIndexableField(urlOop);
  while(*urlPtr == ' ' && urlLen) {
    urlPtr++;
    urlLen--;
  }
  if(urlLen < 5) return 0;
  return _strnicmp("file:", urlPtr, 5) == 0;
}

/*
  primitivePluginBrowserReady
  Return true if a connection to the browser
  has been established. Only necessary if some
  sort of asynchronous communications are used.
*/
EXPORT(int) primitivePluginBrowserReady(void)
{
  if(!fBrowserMode) {
    /* fast failure is better when not in browser */
    DPRINTF(("fBrowserMode == 0\n"));
    return primitiveFail();
  }
  pop(1);
  pushBool(hBrowserPipe != NULL);
  return 1;
}


/*
  primitivePluginRequestUrlStream: url with: semaIndex
  Request a URL from the browser. Signal semaIndex
  when the result of the request can be queried.
  Returns a handle used in subsequent calls to plugin
  stream functions.
*/
EXPORT(int) primitivePluginRequestURLStream(void)
{
  sqStreamRequest *req;
  int id, url, length, semaIndex;

  if(!browserWindow) return primitiveFail();
  for(id=0; id<MAX_REQUESTS;id++) {
    if(!requests[id]) break;
  }
  if(id >= MAX_REQUESTS) return primitiveFail();
  
  semaIndex = stackIntegerValue(0);
  url = stackObjectValue(1);
  if(failed()) return 0;

  if(!isBytes(url)) return primitiveFail();
  if(isFileURL(url)) return primitiveFail();

  req = calloc(1, sizeof(sqStreamRequest));
  if(!req) return primitiveFail();
  req->localName = NULL;
  req->semaIndex = semaIndex;
  req->state = -1;
  requests[id] = req;

  length = byteSizeOf(url);
  pluginGetURLRequest(id, firstIndexableField(url), length, NULL, 0);
  pop(3);
  push(positive32BitIntegerFor(id));
  return 1;
}

/*
  primitivePluginRequestURL: url target: target semaIndex: semaIndex
  Request a URL into the given target.
*/
EXPORT(int) primitivePluginRequestURL(void)
{
  sqStreamRequest *req;
  int url, urlLength;
  int target, targetLength;
  int id, semaIndex;

  if(!browserWindow) return primitiveFail();
  for(id=0; id<MAX_REQUESTS;id++) {
    if(!requests[id]) break;
  }

  if(id >= MAX_REQUESTS) return primitiveFail();

  semaIndex = stackIntegerValue(0);
  target = stackObjectValue(1);
  url = stackObjectValue(2);

  if(failed()) return 0;
  if(!isBytes(url) || !isBytes(target)) return primitiveFail();
  if(isFileURL(url)) return primitiveFail();

  urlLength = byteSizeOf(url);
  targetLength = byteSizeOf(target);

  req = calloc(1, sizeof(sqStreamRequest));
  if(!req) return primitiveFail();
  req->localName = NULL;
  req->semaIndex = semaIndex;
  req->state = -1;
  requests[id] = req;

  pluginGetURLRequest(id, firstIndexableField(url), urlLength, 
		      firstIndexableField(target), targetLength);
  pop(4);
  push(positive32BitIntegerFor(id));
  return 1;
}

/*
  primitivePluginPostURL: url target: target data: data semaIndex: semaIndex
  Post data to a URL.
*/
EXPORT(int) primitivePluginPostURL(void)
{
  sqStreamRequest *req;
  int url, urlLength;
  int target, targetLength;
  int data, dataLength;
  int id, semaIndex;

  if(!browserWindow) return primitiveFail();
  if(methodArgumentCount() != 4) return primitiveFail();
  for(id=0; id<MAX_REQUESTS;id++) {
    if(!requests[id]) break;
  }

  if(id >= MAX_REQUESTS) return primitiveFail();

  semaIndex = stackIntegerValue(0);
  data = stackObjectValue(1);
  target = stackObjectValue(2);
  url = stackObjectValue(3);

  if(failed()) return 0;
  if(!isBytes(url) || !isBytes(data)) return primitiveFail();
  if(isFileURL(url)) return primitiveFail();

  if(target == nilObject()) {
    target = 0;
    targetLength = 0;
  } else {
    if(!isBytes(target)) return primitiveFail();
    targetLength = byteSizeOf(target);
  }

  urlLength = byteSizeOf(url);
  dataLength = byteSizeOf(data);

  req = calloc(1, sizeof(sqStreamRequest));
  if(!req) return primitiveFail();
  req->localName = NULL;
  req->semaIndex = semaIndex;
  req->state = -1;
  requests[id] = req;

  pluginPostURLRequest(id, 
		firstIndexableField(url), urlLength, 
		target ? (firstIndexableField(target)) : NULL, targetLength,
		firstIndexableField(data), dataLength);
  pop(4);
  push(positive32BitIntegerFor(id));
  return 1;
}

/* 
   primitivePluginRequestFileHandle: id
   After a URL file request has been successfully
   completed, return a file handle for the received
   data. Note: The file handle must be read-only for
   security reasons.
*/

EXPORT(int) primitivePluginRequestFileHandle(void)
{
  sqStreamRequest *req;
  int id, fileHandle;

  id = stackIntegerValue(0);
  if(failed()) return 0;
  if(id < 0 || id >= MAX_REQUESTS) return primitiveFail();
  req = requests[id];
  if(!req || !req->localName) return primitiveFail();
  fileHandle = nilObject();
  if(req->localName) {
#if 0
    MessageBox(NULL, req->localName, "Creating file handle for:", MB_OK);
#endif
    fileHandle = instantiateClassindexableSize(classByteArray(), fileRecordSize());
    fBrowserMode = false;
    sqFileOpen(fileValueOf(fileHandle),req->localName,strlen(req->localName),0);
    fBrowserMode = true;
    if(failed()) return 0;
  }
  pop(2);
  push(fileHandle);
  return 1;
}

/*
  primitivePluginDestroyRequest: id
  Destroy a request that has been issued before.
*/
EXPORT(int) primitivePluginDestroyRequest(void)
{
  sqStreamRequest *req;
  int id;

  id = stackIntegerValue(0);
  if(id < 0 || id >= MAX_REQUESTS) return primitiveFail();
  req = requests[id];
  if(req) {
    if(req->localName) free(req->localName);
    free(req);
  }
  requests[id] = NULL;
  pop(1);
  return 1;
}

/*
  primitivePluginRequestState: id
  Return true if the operation was successfully completed.
  Return false if the operation was aborted.
  Return nil if the operation is still in progress.
*/
EXPORT(int) primitivePluginRequestState(void)
{
  sqStreamRequest *req;
  int id;

  id = stackIntegerValue(0);
  if(id < 0 || id >= MAX_REQUESTS) return primitiveFail();
  req = requests[id];
  if(!req) return primitiveFail();
  pop(2);
  if(req->state == -1) push(nilObject());
  pushBool(req->state);
  return 1;
}

void pluginReceiveData(MSG *msg)
{
  sqStreamRequest *req;
  char *localName;
  int id, ok, length;
  DWORD nBytes;
  
  id = msg->wParam;
  ok = msg->lParam;
  
  length = 0;
  ReadFile(hClientReadEnd, &length, 4, &nBytes, NULL);
  if(length) {
    localName = malloc(length+1);
    ReadFile(hClientReadEnd, localName, length, &nBytes, NULL);
    localName[length] = 0;
  } else localName = NULL;
  if(!ok && localName) {
    free(localName);
    localName = NULL;
  }
  if(id >= 0 && id < MAX_REQUESTS) {
    req = requests[id];
    if(req) {
      req->localName = localName;
      req->state = ok;
      synchronizedSignalSemaphoreWithIndex(req->semaIndex);
    }
  }
}

void pluginGetURLRequest(int id, void* urlIndex, int urlSize, 
			 void* targetIndex, int targetSize)
{
  int ok;
  DWORD dwWritten;
  
  if(!hBrowserPipe) {
    warnPrintf("Cannot submit URL request -- there is no connection to a browser\n");
    return;
  }

  /* This makes the plugin aware of the request */
  PostMessage(browserWindow, g_WM_REQUEST_DATA, id, 0);

  SetLastError(0);
  ok = WriteFile(hBrowserPipe, &urlSize, 4, &dwWritten, NULL);
  if(!ok || dwWritten != 4)
    printLastError("Failed to write url size");
  if(urlSize > 0) {
    ok = WriteFile(hBrowserPipe, urlIndex, urlSize, &dwWritten, NULL);
    if(!ok || dwWritten != urlSize)
      printLastError("Failed to write url request");
  }
  ok = WriteFile(hBrowserPipe, &targetSize, 4, &dwWritten, NULL);
  if(!ok || dwWritten != 4)
    printLastError("Failed to write target size");
  if(targetSize > 0) {
    ok = WriteFile(hBrowserPipe, targetIndex, targetSize, &dwWritten, NULL);
    if(!ok || dwWritten != targetSize)
      printLastError("Failed to write url request");
  }
}

void pluginPostURLRequest(int id, void* urlIndex, int urlSize, 
			  void* targetIndex, int targetSize, 
			  void* postDataIndex, int postDataSize)
{
  int ok;
  DWORD dwWritten;

  if(!hBrowserPipe) {
    warnPrintf("Cannot submit URL post request -- there is no connection to a browser\n");
    return;
  }

  /* This makes the plugin aware of the request */
  PostMessage(browserWindow, g_WM_POST_DATA, id, 0);
  
  SetLastError(0);
  ok = WriteFile(hBrowserPipe, &urlSize, 4, &dwWritten, NULL);
  if(!ok || dwWritten != 4)
    printLastError("Failed to write url size");
  if(urlSize > 0) {
    ok = WriteFile(hBrowserPipe, urlIndex, urlSize, &dwWritten, NULL);
    if(!ok || dwWritten != urlSize)
      printLastError("Failed to write url request");
  }

  ok = WriteFile(hBrowserPipe, &targetSize, 4, &dwWritten, NULL);
  if(!ok || dwWritten != 4)
    printLastError("Failed to write url size");
  if(targetSize > 0) {
    ok = WriteFile(hBrowserPipe, targetIndex, targetSize, &dwWritten, NULL);
    if(!ok || dwWritten != targetSize)
      printLastError("Failed to write target request");
  }

  ok = WriteFile(hBrowserPipe, &postDataSize, 4, &dwWritten, NULL);
  if(!ok || dwWritten != 4)
    printLastError("Failed to write post data size");
  if(postDataSize > 0) {
    ok = WriteFile(hBrowserPipe, postDataIndex, postDataSize, &dwWritten, NULL);
    if(!ok || dwWritten != postDataSize)
      printLastError("Failed to write data request");
  }
}

/*
  pluginSetBrowserPipe:
  Called in response to a g_WM_BROWSER_PIPE message.
  Sets up the write end of a pipe for a client.
  Parameters:
  wParam - Process handle of the plugin
  lParam - Pipe handle of the write end for the plugin.
  Note: This method also installs the read end for the client
  by posting back the process/pipe handle for the client side.
*/
void pluginSetBrowserPipe(MSG *msg)
{
  DPRINTF(("New browser pipe: %x\n",msg->lParam));
  if(hBrowserPipe) CloseHandle(hBrowserPipe);
  hBrowserPipe = (HANDLE) msg->lParam;
  if(!CreatePipe(&hClientReadEnd, &hClientWriteEnd, NULL, 4096))
    printLastError("CreatePipe failed");
  
  /* And pass our the write end back to the plugin */
  PostMessage(browserWindow, g_WM_CLIENT_PIPE, (WPARAM) GetCurrentProcess(), (LPARAM) hClientWriteEnd);
}

/*
  pluginExit:
  Clean up when Squeak is about to quit.
*/
void pluginExit(void)
{
  if(hClientReadEnd) CloseHandle(hClientReadEnd);
  if(hClientWriteEnd) CloseHandle(hClientWriteEnd);
  if(hBrowserPipe) CloseHandle(hBrowserPipe);
}

/*
	pluginInit:
	Register the communication events for the plugin.
*/

void pluginInit(void)
{
  g_WM_QUIT_SESSION = RegisterWindowMessage(TEXT("SqueakQuitSession"));
  g_WM_BWND_SIZE = RegisterWindowMessage(TEXT("SqueakSetBrowserWindowSize"));
  g_WM_REQUEST_DATA = RegisterWindowMessage(TEXT("SqueakRequestData"));
  g_WM_POST_DATA = RegisterWindowMessage(TEXT("SqueakPostData"));
  g_WM_RECEIVE_DATA = RegisterWindowMessage(TEXT("SqueakReceiveData"));
  g_WM_INVALIDATE = RegisterWindowMessage(TEXT("SqueakInvalidateRect"));
  g_WM_BROWSER_PIPE = RegisterWindowMessage(TEXT("SqueakBrowserPipe"));
  g_WM_CLIENT_PIPE = RegisterWindowMessage(TEXT("SqueakClientPipe"));
}

/*
  pluginHandleEvent:
  Handle an event that is likely to be sent by the plugin
  (e.g., the hWnd of this message is NULL).
*/
void pluginHandleEvent(MSG *msg)
{
  DPRINTF(("Checking for plugin message (%x)\n",msg->message));
  DPRINTF(("\tg_WM_QUIT_SESSION: %x\n",g_WM_QUIT_SESSION));
  DPRINTF(("\tg_WM_BWND_SIZE: %x\n",g_WM_BWND_SIZE));
  DPRINTF(("\tg_WM_REQUEST_DATA: %x\n",g_WM_REQUEST_DATA));
  DPRINTF(("\tg_WM_POST_DATA: %x\n",g_WM_POST_DATA));
  DPRINTF(("\tg_WM_RECEIVE_DATA: %x\n",g_WM_RECEIVE_DATA));
  DPRINTF(("\tg_WM_INVALIDATE: %x\n",g_WM_INVALIDATE));
  DPRINTF(("\tg_WM_BROWSER_PIPE: %x\n",g_WM_BROWSER_PIPE));
  DPRINTF(("\tg_WM_CLIENT_PIPE: %x\n",g_WM_CLIENT_PIPE));

  /* Messages posted from a different process */
  if(msg->message == g_WM_QUIT_SESSION) exit(0);
  if(msg->message == g_WM_INVALIDATE) {
    if(!getFullScreenFlag() && IsWindow(browserWindow)) {
      /* adjust to size of browser window */
      RECT r;
      GetClientRect(browserWindow, &r);
      SetWindowPos(stWindow, NULL, 0, 0, (r.right-r.left), (r.bottom-r.top), SWP_NOMOVE | SWP_NOZORDER);
    }
    /* Invalidation */
    InvalidateRect(stWindow, NULL, FALSE);
  } else if(msg->message == g_WM_BWND_SIZE) {
    /* Window position changed */
    if(!getFullScreenFlag()) {
      SetWindowPos(stWindow, NULL, 0, 0, msg->wParam, msg->lParam, SWP_NOMOVE | SWP_NOZORDER);
    }
  } else if(msg->message == g_WM_RECEIVE_DATA) {
    /* Data is coming in */
    pluginReceiveData(msg);
  } else if(msg->message == g_WM_BROWSER_PIPE) {
    /* Browser communicates write end */
    pluginSetBrowserPipe(msg);
  }
}
