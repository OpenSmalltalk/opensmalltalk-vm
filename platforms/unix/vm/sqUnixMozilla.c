/* sqUnixMozilla.c -- support for Squeak Netscape plugin
 *
 * Author: Bert Freudenberg <bert@isg.cs.uni-magdeburg.de>
 * 
 * Based on Andreas Raab's sqWin32PluginSupport
 * 
 * Notes: The plugin display stuff is in sqXWindow.c.
 *        There, pluginInit(), pluginExit() and pluginHandleEvent()
 *        must be called.
 *
 * File renamed (because `Plugin' is a `magic word' to configure and
 * the build Makefile) by Ian.Piumarta@INRIA.Fr
 */

#include "sq.h"

#ifndef HEADLESS

#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <unistd.h>

#undef DEBUG

#ifdef DEBUG
#  define FPRINTF(X) fprintf X
#else
#  define FPRINTF(X)
#endif

/* from sqXWindow.c */
extern Display* stDisplay;
extern Window   stWindow;
extern Window   browserWindow;

/* from interpret.c */
int stackObjectValue(int);
int stackIntegerValue(int);
int isBytes(int);
int byteSizeOf(int);
void *firstIndexableField(int);
int push(int);
int pop(int);
int positive32BitIntegerFor(int);
int nilObject();
int instantiateClassindexableSize(int, int);
int classByteArray();
int failed();
int pushBool(int);

/* protos */
void pluginGetURLRequest(int id, char* url, int urlSize,
       char* target, int targetSize);
void pluginPostURLRequest(int id, char* url, int urlSize, 
        char* target, int targetSize, 
        char* postData, int postDataSize);

typedef struct sqStreamRequest {
  char *localName;
  int semaIndex;
  int state;
} sqStreamRequest;

#define MAX_REQUESTS 128

#define SQUEAK_READ 0
#define SQUEAK_WRITE 1

static sqStreamRequest *requests[MAX_REQUESTS];

static int pipes[2] = {0, 0};             /* read/write descriptors */

static Atom XA_SET_PIPES;                 /* ClientMessage types */
static Atom XA_BROWSER_WINDOW;
static Atom XA_GET_URL;
static Atom XA_POST_URL;
static Atom XA_RECEIVE_DATA;

/*
  primitivePluginBrowserReady
  Return true if a connection to the browser
  has been established. Only necessary if some
  sort of asynchronous communications are used.
*/
int primitivePluginBrowserReady()
{
  pop(1);
  pushBool(pipes[SQUEAK_WRITE] != 0);
  return 1;
}


/*
  primitivePluginRequestUrlStream: url with: semaIndex
  Request a URL from the browser. Signal semaIndex
  when the result of the request can be queried.
  Returns a handle used in subsequent calls to plugin
  stream functions.
  Note: A request id is the index into requests[].
*/
int primitivePluginRequestURLStream()
{
  sqStreamRequest *req;
  int id, url, length, semaIndex;

  if (!pipes[SQUEAK_WRITE]) return primitiveFail();

  FPRINTF((stderr, "primitivePluginRequestURLStream()\n"));

  for (id=0; id<MAX_REQUESTS; id++) {
    if (!requests[id]) break;
  }
  if (id >= MAX_REQUESTS) return primitiveFail();

  semaIndex = stackIntegerValue(0);
  url = stackObjectValue(1);
  if (failed()) return 0;

  if (!isBytes(url)) return primitiveFail();

  req = calloc(1, sizeof(sqStreamRequest));
  if (!req) return primitiveFail();
  req->localName = NULL;
  req->semaIndex = semaIndex;
  req->state = -1;
  requests[id] = req;

  length = byteSizeOf(url);
  pluginGetURLRequest(id, firstIndexableField(url), length, NULL, 0);
  pop(3);
  push(positive32BitIntegerFor(id));
  FPRINTF((stderr, "  request id: %i\n", id));
  return 1;
}

/*
  primitivePluginRequestURL: url target: target semaIndex: semaIndex
  Request a URL into the given target.
*/
int primitivePluginRequestURL()
{
  sqStreamRequest *req;
  int url, urlLength;
  int target, targetLength;
  int id, semaIndex;

  if (!browserWindow) return primitiveFail();
  for (id=0; id<MAX_REQUESTS; id++) {
    if (!requests[id]) break;
  }

  if (id >= MAX_REQUESTS) return primitiveFail();

  semaIndex = stackIntegerValue(0);
  target = stackObjectValue(1);
  url = stackObjectValue(2);

  if (failed()) return 0;
  if (!isBytes(url) || !isBytes(target)) return primitiveFail();

  urlLength = byteSizeOf(url);
  targetLength = byteSizeOf(target);

  req = calloc(1, sizeof(sqStreamRequest));
  if(!req) return primitiveFail();
  req->localName = NULL;
  req->semaIndex = semaIndex;
  req->state = -1;
  requests[id] = req;

  pluginGetURLRequest(id, firstIndexableField(url), urlLength, firstIndexableField(target), targetLength);
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

int primitivePluginRequestFileHandle()
{
  sqStreamRequest *req;
  int id, fileHandle;
#if 1 /* TPR- problems with accessing  fileRecordSixe, fileValueOf and sqFileOpen */
  id = stackIntegerValue(0);
  if (failed()) return 0;
  if (id < 0 || id >= MAX_REQUESTS) return primitiveFail();
  req = requests[id];
  if (!req || !req->localName) return primitiveFail();
  fileHandle = nilObject();
  if (req->localName) {
    int fRS, fVO, sFO;
    FPRINTF((stderr, "Creating file handle for %s\n", req->localName));
    fRS = ioLoadFunctionFrom("fileRecordSize", "FilePlugin");
    fVO = ioLoadFunctionFrom("fileValueOf", "FilePlugin");
    sFO = ioLoadFunctionFrom("sqFileOpen", "FilePlugin");
    if ( !fRS || !fVO || !sFO) return primitiveFail(); /* TPR - is this the right way to fail here? */
    fileHandle = instantiateClassindexableSize(classByteArray(), ((int(*)(void))fRS)());
    ((int(*)(int, int, int, int))sFO)( ((int(*)(int))fVO)(fileHandle),(int)req->localName, strlen(req->localName), 0);
    if (failed()) return 0;
  }
  pop(2);
  push(fileHandle);
  return 1;
#else
	return primitiveFail();
#endif  
}

/*
  primitivePluginDestroyRequest: id
  Destroy a request that has been issued before.
*/
int primitivePluginDestroyRequest()
{
  sqStreamRequest *req;
  int id;

  id = stackIntegerValue(0);
  if (id < 0 || id >= MAX_REQUESTS) return primitiveFail();
  req = requests[id];
  if (req) {
    if (req->localName) free(req->localName);
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

int primitivePluginRequestState()
{
  sqStreamRequest *req;
  int id;

  id = stackIntegerValue(0);
  if (id < 0 || id >= MAX_REQUESTS) return primitiveFail();
  req = requests[id];
  if (!req) return primitiveFail();
  pop(2);
  if (req->state == -1) push(nilObject());
  else pushBool(req->state);
  return 1;
}


/*
  pluginSendEvent:
  Send a notification message to the plugin
 */
void pluginSendEvent(Atom message_type, long data0)
{
  XClientMessageEvent event;
 
  event.type = ClientMessage;
  event.display = stDisplay;
  event.window = browserWindow;
  event.message_type = message_type;
  event.format = 32;
  event.data.l[0] = data0;

  XSendEvent(stDisplay, browserWindow, True, 
	     0, (XEvent*) &event);
}


/*
  pluginReceiveData:
  Called in response to a XA_RECEIVE_DATA message.
  Retrieves the data file name and signals the semaphore.
  Parameters:
    event->data.l[0] - request id
    event->data.l[1] - request successful
*/
void pluginReceiveData(XClientMessageEvent *event)
{
  char *localName = NULL;
  int id = event->data.l[0];
  int ok = event->data.l[1];

  FPRINTF((stderr, " receiving data id: %i state %i\n", id, ok));

  if (ok == 1) {
    int n, length = 0;
    n = read(pipes[SQUEAK_READ], &length, 4);
    if (n==4 && length) {
      localName = malloc(length+1);
      read(pipes[SQUEAK_READ], localName, length);
      localName[length] = 0;
      FPRINTF((stderr, "  got filename %s\n", localName));
    }
  }
  if (id >= 0 && id < MAX_REQUESTS) {
    sqStreamRequest *req = requests[id];
    if (req) {
      req->localName = localName;
      req->state = ok;
      FPRINTF((stderr, " signaling semaphore, state=%i\n", ok));
      /*  synchronizedSignalSemaphoreWithIndex(req->semaIndex);*/
      signalSemaphoreWithIndex(req->semaIndex);
    }
  }
}



/*
  pluginGetURLRequest:
  Notify plugin to get the specified url into target
*/
void pluginGetURLRequest(int id, char* url, int urlSize, char* target, int targetSize)
{

  int written;

  if (!pipes[SQUEAK_WRITE]) {
    fprintf(stderr, "Cannot submit URL request -- there is no connection to a browser\n");
    return;
  }

  /* This makes the plugin aware of the request */
  pluginSendEvent(XA_GET_URL, id);

  written = write(pipes[SQUEAK_WRITE], &urlSize, 4);
  if (written != 4) perror("Failed to write url size");
  if (urlSize > 0) {
    written = write(pipes[SQUEAK_WRITE], url, urlSize);
    if (written != urlSize) perror("Failed to write url request");
  }
  written = write(pipes[SQUEAK_WRITE], &targetSize, 4);
  if (written != 4) perror("Failed to write target size");
  if (targetSize > 0) {
    written = write(pipes[SQUEAK_WRITE], target, targetSize);
    if (written != targetSize) perror("Failed to write url request");
  }
}


/*
  pluginPostURLRequest:
  Notify plugin to post data to the specified url and get result into target
*/
void pluginPostURLRequest(int id, char* url, int urlSize, 
                  char* target, int targetSize, 
                  char* postData, int postDataSize)
{
  int written;
  
  if (!pipes[SQUEAK_WRITE]) {
    fprintf(stderr, "Cannot submit URL post request -- there is no connection to a browser\n");
    return;
  }

  /* This makes the plugin aware of the request */
  pluginSendEvent(XA_POST_URL, id);

  written = write(pipes[SQUEAK_WRITE], &urlSize, 4);
  if (written != 4) perror("Failed to write url size");
  if (urlSize > 0) {
    written = write(pipes[SQUEAK_WRITE], url, urlSize);
    if (written != urlSize) perror("Failed to write url request");
  }

  written = write(pipes[SQUEAK_WRITE], &targetSize, 4);
  if (written != 4) perror("Failed to write url size");
  if (targetSize > 0) {
    written = write(pipes[SQUEAK_WRITE], target, targetSize);
    if (written != targetSize) perror("Failed to write target request");
  }

  written = write(pipes[SQUEAK_WRITE], &postDataSize, 4);
  if (written != 4) perror("Failed to write post data size");
  if (postDataSize > 0) {
    written = write(pipes[SQUEAK_WRITE], postData, postDataSize);
    if (written != postDataSize) perror("Failed to write data request");
  }
}


/***************************************************************
 * Functions called from sqXWindow.c
 ***************************************************************/

/*
  pluginInit:
  Register the communication events for the plugin.
  Note: Must be called after stDisplay has been opened, but
  before the Squeak window is created.
*/
void pluginInit()
{
  XA_SET_PIPES = XInternAtom(stDisplay, "SQUEAK_SET_PIPES", False);
  XA_BROWSER_WINDOW = XInternAtom(stDisplay, "SQUEAK_BROWSER_WINDOW", False);
  XA_GET_URL = XInternAtom(stDisplay, "SQUEAK_GET_URL", False);
  XA_POST_URL = XInternAtom(stDisplay, "SQUEAK_POST_URL", False);
  XA_RECEIVE_DATA = XInternAtom(stDisplay, "SQUEAK_RECEIVE_DATA", False);
}


/*
  pluginExit:
  Clean up when Squeak is about to quit.
*/
void pluginExit()
{
}


/*
  pluginHandleEvent:
  Handle events sent by the plugin
*/
void pluginHandleEvent(XClientMessageEvent *event)
{
  if (event->type != ClientMessage || event->window != stWindow) return;
  if (event->message_type == XA_RECEIVE_DATA) {
    /* Data is coming in */
    pluginReceiveData(event);
  } else if (event->message_type == XA_BROWSER_WINDOW) {
    /* Parent window has changed () */
    browserWindow = (Window) event->data.l[0];
    FPRINTF((stderr, " got browser window\n"));
  } else if (event->message_type == XA_SET_PIPES) {
    /* Pipes for communication with plugin */
    pipes[SQUEAK_READ] = event->data.l[0];
    pipes[SQUEAK_WRITE] = event->data.l[1];
    FPRINTF((stderr, " got pipes\n"));
  }
}

#endif /* HEADLESS */


