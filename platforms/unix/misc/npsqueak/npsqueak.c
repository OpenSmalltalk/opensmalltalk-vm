/* -*- Mode: C; tab-width: 8; -*-
 *
 * Browser Plugin for Squeak on Unix platforms
 * 
 * Author:  Bert Freudenberg <bert@isg.cs.uni-magdeburg.de>
 *
 * Last edited: Mon 04 Mar 2002 17:37:52 by bert on balloon
 *
 * History:
 *          Mar 2002 - moved to ~/.npsqueak dir
 *          Nov 2000 - browserPipes interface replaces X events
 *          Apr 2000 - url requests through browser
 *          Nov 1999 - report attributes to vm
 *          Aug 99   - initial version 
 */

#define XP_UNIX
#include <npapi.h>

#include <stdio.h>
#include <unistd.h>
#include <limits.h>
#include <signal.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/stat.h>
#include <X11/Xlib.h>
#include <X11/Intrinsic.h>
#include <X11/StringDefs.h>

#define DEBUG

#ifdef DEBUG
static void DPRINT(char *format, ...)
{
  static int debug= 42;
  if (42 == debug) 
    debug= (NULL != getenv("NPSQUEAK_DEBUG"));

  if (!debug) 
    {
      return;
    }
  else
    {
      static FILE *file= 0;
      if (!file) 
	{
	  file= fopen("/tmp/npsqueak.log", "a+");
	  fprintf(file, "=== START PLUGIN ===\n");
	}

      {
	va_list ap;
	va_start(ap, format);
	vfprintf(file, format, ap);
	va_end(ap);
	fflush(file);
      }
    }
}
#else
static int DPRINT(char *, ...) { }
#endif

/***********************************************************************
 * Plugin instance data
 ***********************************************************************/

#define CMD_BROWSER_WINDOW 1
#define CMD_GET_URL        2
#define CMD_POST_URL       3
#define CMD_RECEIVE_DATA   4

#define MAX_STREAMS 128

#define SQUEAK_READ  0
#define PLUGIN_WRITE 1
#define PLUGIN_READ  2
#define SQUEAK_WRITE 3

/* plugin state */
typedef struct SqueakPlugin {
  NPP instance;                    /* plugin instance */
  pid_t pid;                       /* the child process pid */
  Display *display;
  Window nswindow;                 /* the netscape window */
  Window sqwindow;                 /* the Squeak window */
  XtInputId input;                 /* handler for command pipe */
  Bool embedded;                   /* false if we have the whole window */
  char **argv;                     /* the commandline for Squeak vm */
  int  argc;
  char vmName[PATH_MAX];
  char imageName[PATH_MAX];
  int pipes[4];                    /* 4 ends of 2 pipes */
  char* srcUrl;                    /* set by browser in first NewStream */
  char* srcFilename;
  int   srcId;                     /* if requested */
} SqueakPlugin;

/* URL notify data */
typedef struct SqueakStream {
  int id;                          /* request id (0 if finished)  */
} SqueakStream;

/***********************************************************************
 * Prototypes
 ***********************************************************************/

static int CheckFile(char *filename);
static int GetBaseDir(char *basedir);
static void DeliverFile(SqueakPlugin *, int id, const char* fname);
static void SetWindow(SqueakPlugin*, Window window, int width, int height);
static void SetUpWindow(SqueakPlugin*);
static void Run(SqueakPlugin*);
static void GetUrl(SqueakPlugin*);
static void PostUrl(SqueakPlugin*);
static void DestroyCallback(Widget widget, SqueakPlugin *, XtPointer calldata);
static void InputCallback(SqueakPlugin *, int *source, XtInputId*);

/***********************************************************************
 * Plugin registration
 ***********************************************************************/

char*
NPP_GetMIMEDescription(void)
{
  return("application/x-squeak-source:sts:Squeak source"
	 ";application/x-squeak-object:sqo:Squeak object"
	 ";application/x-squeak-project:pr:Squeak project");
}

NPError
NPP_GetValue(void *instance, NPPVariable variable, void *value)
{
  switch (variable) {
  case NPPVpluginNameString:
    *((char **)value)= "Squeak";
    break;
  case NPPVpluginDescriptionString:
    *((char **)value) =
      "<a href=\"http://squeak.org/\">Squeak</a> is a modern open source"
      " Smalltalk environment. The Squeak Plugin handles Squeaklets.<P>"
      "The Squeak Plugin for Unix was developed by"
      " <a href=\"mailto:bert@freudenbergs.de\">Bert Freudenberg</a>,"
      " it uses the Squeak VM developed by"
      " <a href=\"mailto:Ian.Piumarta@inria.fr\">Ian Piumarta</a>"
      " and many others.";
    break;
  default:
    return NPERR_GENERIC_ERROR;
  }
  return NPERR_NO_ERROR;
}

/***********************************************************************
 * Plugin loading and termination
 ***********************************************************************/

NPError 
NPP_New(NPMIMEType pluginType, NPP instance, uint16 mode, int16 argc,
		char* argn[], char* argv[], NPSavedData* saved)
{
  SqueakPlugin *plugin;
  char basedir[PATH_MAX];
  if (instance == NULL)
    return NPERR_INVALID_INSTANCE_ERROR;
  plugin= (SqueakPlugin*) NPN_MemAlloc(sizeof(SqueakPlugin));
  if (!plugin)
    return NPERR_OUT_OF_MEMORY_ERROR;
  plugin->argv= (char**) NPN_MemAlloc(sizeof(char*) * (16+2*argc));
  if (!plugin->argv)
    return NPERR_OUT_OF_MEMORY_ERROR;
  /* Default settings */
  if (!GetBaseDir(basedir)) {
    fprintf(stderr, "Squeak Plugin: You may want to set NPSQUEAK_DIR.\n");
    return NPERR_GENERIC_ERROR;
  }
  plugin->instance= instance;
  plugin->pid= 0;
  plugin->nswindow= 0;
  plugin->sqwindow= 0;
  plugin->display= NULL;
  plugin->input= 0;
  plugin->embedded= (mode == NP_EMBED);
  plugin->srcUrl= NULL;
  plugin->srcFilename= NULL;
  plugin->srcId= -1;
  strcpy(plugin->vmName, basedir);
  strcat(plugin->vmName, "squeakvm");
  strcpy(plugin->imageName, basedir);
  strcat(plugin->imageName, "image/SqueakPlugin.image");
  plugin->argv[0]= plugin->vmName;
  plugin->argv[1]= "-display";
  plugin->argv[2]= ":0";             /* inserted later */
  plugin->argv[3]= "-browserPipes";
  plugin->argv[4]= "0";              /* inserted later */
  plugin->argv[5]= "0";              /* inserted later */
  plugin->argv[6]= plugin->imageName; 
  plugin->argv[7]= "";               /* empty document file on cmdline! */ 
  plugin->argc= 8;
  if (plugin->embedded) {
    int i;
    for (i= 0; i < argc; i++) {
      plugin->argv[plugin->argc++]= argn[i];
      plugin->argv[plugin->argc++]= argv[i] ? argv[i] : "";
      if (strcasecmp("SRC", argn[i]) == 0)
	plugin->srcUrl= strdup(argv[i]);
    }
    if (!plugin->srcUrl)
      plugin->srcUrl= strdup(""); /* we were embedded without a SRC */
  } else {
    /* if not embedded srcUrl will be set in NewStream */
    plugin->srcUrl= NULL;
  }
  plugin->argv[plugin->argc]= 0; 
  if (pipe(&plugin->pipes[SQUEAK_READ])
      || pipe(&plugin->pipes[PLUGIN_READ])) {
    perror("Squeak Plugin: Creating pipes failed");
    return NPERR_GENERIC_ERROR;
  }
  if (!CheckFile(plugin->vmName) || !CheckFile(plugin->imageName))
    return NPERR_GENERIC_ERROR;
  instance->pdata= (void*) plugin;
  return NPERR_NO_ERROR;
}

NPError 
NPP_Destroy(NPP instance, NPSavedData** save)
{
  SqueakPlugin *plugin;
  if (!instance)
    return NPERR_INVALID_INSTANCE_ERROR;
  plugin= (SqueakPlugin*) instance->pdata;
  if (plugin) {
    int i;
    if (plugin->pid) {
      kill(plugin->pid, SIGTERM);
      plugin->pid= 0;
    }
    if (plugin->input) {
      XtRemoveInput(plugin->input);
    }
    for (i=0; i<4; i++)
      if (plugin->pipes[i]) {
	close(plugin->pipes[i]);
	plugin->pipes[i]= 0;
      }
    if (plugin->srcUrl) {
      NPN_MemFree(plugin->srcUrl);
      plugin->srcUrl= NULL;
    }
    if (plugin->srcFilename) {
      NPN_MemFree(plugin->srcFilename);
      plugin->srcFilename= NULL;
    }
    NPN_MemFree(plugin);
  }
  instance->pdata= NULL;
  return NPERR_NO_ERROR;
}

/***********************************************************************
 * Plugin events we need to handle
 ***********************************************************************/

NPError 
NPP_SetWindow(NPP instance, NPWindow *pNPWindow)
{
  SqueakPlugin *plugin;
  if (!instance)
    return NPERR_INVALID_INSTANCE_ERROR;
  plugin= (SqueakPlugin*) instance->pdata;
  if (!plugin)
    return NPERR_GENERIC_ERROR;
  if (pNPWindow == NULL) 
    return NPERR_NO_ERROR;

  if (!plugin->display) {
    /* first time only */
    plugin->display= ((NPSetWindowCallbackStruct *)pNPWindow->ws_info)->display;
  }
  SetWindow(plugin, (Window) pNPWindow->window, 
		  pNPWindow->width, pNPWindow->height);
  if (!plugin->pid)
    Run(plugin);
  return NPERR_NO_ERROR;
}


NPError 
NPP_NewStream(NPP instance, NPMIMEType type, NPStream *stream, NPBool seekable, uint16 *stype)
{
  SqueakPlugin *plugin= (SqueakPlugin*) instance->pdata;
  DPRINT("NP: NewStream(%s, id=%i)\n", stream->url, 
	   stream->notifyData ? ((SqueakStream*) stream->notifyData)->id : -1);
  if (!stream->notifyData && !plugin->srcUrl) {
    /* We did not request this stream, so it is our SRC file. */
    plugin->srcUrl= strdup(stream->url);
    plugin->argv[plugin->argc++]= "SRC";
    plugin->argv[plugin->argc++]= plugin->srcUrl;
    DPRINT("NP:   got srcUrl=%s\n", plugin->srcUrl);
    Run(plugin);
  }
    
  *stype= NP_ASFILEONLY;          /* We want the file after download */
  return NPERR_NO_ERROR;
}


NPError 
NPP_DestroyStream(NPP instance, NPStream *stream, NPError reason)
{
  /* We'll clean up in URLNotify */
  DPRINT("NP: DestroyStream(%s, id=%i)\n", stream->url, 
	 stream->notifyData ? ((SqueakStream*) stream->notifyData)->id : -1);
  return NPERR_NO_ERROR;
}


void 
NPP_StreamAsFile(NPP instance, NPStream *stream, const char* fname)
{
  int id= stream->notifyData ? ((SqueakStream*) stream->notifyData)->id : -1;
  SqueakPlugin *plugin= (SqueakPlugin*) instance->pdata;
  DPRINT("NP: StreamAsFile(%s, id=%i)\n", stream->url, id);
  DPRINT("NP:   fname=%s\n", fname ? fname : "<NULL>");
  if (!plugin || !fname) return;

  if (!stream->notifyData && !plugin->srcFilename) {
    /* We did not request this stream, so it is our SRC file. */
    plugin->srcFilename= strdup(fname);
    DPRINT("NP:   got srcFilename=%s\n", plugin->srcFilename);
    if (plugin->srcId >= 0) {
      /* plugin wanted it already */
      DeliverFile(plugin, plugin->srcId, plugin->srcFilename);
      plugin->srcId= -1;
    }
    return;
  }

  DeliverFile(plugin, id, fname);

  /* signal URLNotify that we're done */
  ((SqueakStream*) stream->notifyData)->id= -1;
}

void
NPP_URLNotify(NPP instance, const char* url, NPReason reason, void* notifyData)
{
  int id= notifyData ? ((SqueakStream*) notifyData)->id : -1;
  int ok= reason == NPRES_DONE;
  SqueakPlugin *plugin= (SqueakPlugin*) instance->pdata;
  DPRINT("NP: URLNotify(%s, id=%i, ok=%i)\n", url, id, ok);
  if (notifyData) NPN_MemFree(notifyData);
  if (!plugin || -1 == id) return;

  DeliverFile(plugin, id, NULL);
}

/***********************************************************************
 * Plugin stubs
 ***********************************************************************/


NPError
NPP_Initialize(void)
{
  return NPERR_NO_ERROR;
}


void
NPP_Shutdown(void)
{
}


/* We don't have an associated java class */

jref
NPP_GetJavaClass()
{
  return NULL;
}

/* We don't really stream */

int32 
NPP_WriteReady(NPP instance, NPStream *stream)
{
  return 0X0FFFFFFF;
}


int32 
NPP_Write(NPP instance, NPStream *stream, int32 offset, int32 len, void *buffer)
{
  return len;
}


/* We don't print */

void 
NPP_Print(NPP instance, NPPrint* printInfo)
{
}


/***********************************************************************
 * Our functions
 ***********************************************************************/

static int
CheckFile(char *filename)
{
  struct stat statBuf;
  if (stat(filename, &statBuf)) {
    perror("Squeak Plugin");
    fprintf(stderr, "  '%s'\n", filename);
    return 0;
  }
  return 1;
}

static int
GetBaseDir(char *basedir)
{
  char* ev;
  ev= getenv("NPSQUEAK_DIR");
  if (ev) {
    strcpy(basedir, ev);
    if (basedir[strlen(basedir)-1] != '/') 
      strcat(basedir, "/");
  } else {
    ev= getenv("HOME");
    if (ev) {
      strcpy(basedir, ev);
      strcat(basedir, "/.npsqueak/");
    } else {
      basedir[0]= '\0';
      fprintf(stderr, "Squeak Plugin: could not find Squeak directory.\n");
      return 0;		
    }
  }
  return CheckFile(basedir);
}


/* Read from command pipe. */
static void
Receive(SqueakPlugin *plugin, void *buf, size_t count)
{
  ssize_t n;
  do {
    n= read(plugin->pipes[PLUGIN_READ], buf, count);
  } while (n == -1 && errno == EINTR);
  if (n == -1)
    perror("Squeak plugin pipe read failed:");
  if (n < count)
    fprintf(stderr, "Squeak plugin read too few data from pipe\n");
}


/* Write to command pipe. */
static void
Send(SqueakPlugin *plugin, const void *buf, size_t count)
{
  ssize_t n;
  do {
    n= write(plugin->pipes[PLUGIN_WRITE], buf, count);
  } while (n == -1 && errno == EINTR);
  if (n == -1)
    perror("Squeak plugin write failed:");
  if (n < count)
    fprintf(stderr, "Squeak plugin wrote too few data to pipe\n");
}

static void
SendInt(SqueakPlugin *plugin, int value)
{
  Send(plugin, &value, 4);
}


static void 
DeliverFile(SqueakPlugin *plugin, int id, const char* fname)
{
  int ok= fname != NULL;
  DPRINT("NP:   Send RECEIVE_DATA id=%i state=%i\n", id, ok);

  errno= 0;
  SendInt(plugin, CMD_RECEIVE_DATA);
  SendInt(plugin, id);
  SendInt(plugin, ok);

  if (ok) {
    int length= strlen(fname);
    SendInt(plugin, length);
    Send(plugin, fname, length);
  }

  if (errno)
    perror("Squeak Plugin (StreamAsFile)");
}


static void 
Run(SqueakPlugin *plugin)
{
  if (plugin->pid || !plugin->nswindow || !plugin->srcUrl)
    return;
  
  plugin->pid= fork();
  
  if (plugin->pid == -1) {
    perror("Squeak fork() failed");
    plugin->pid= 0;
    return;
  }
  DPRINT("NP: fork() -> %i\n", plugin->pid);
  if (plugin->pid == 0) {
    char tmp1[16], tmp2[16];
    plugin->argv[2]= DisplayString(plugin->display);
    sprintf(tmp1, "%i", plugin->pipes[SQUEAK_READ]);
    plugin->argv[4]= tmp1;
    sprintf(tmp2, "%i", plugin->pipes[SQUEAK_WRITE]);
    plugin->argv[5]= tmp2;
    {
      int i;
      for (i= 0; i<plugin->argc; i++)
	DPRINT("  %s\n", plugin->argv[i]);
    }
    /* this is from the XLib manual ... */
    if ((fcntl(ConnectionNumber(plugin->display), F_SETFD, FD_CLOEXEC)) == -1)
      DPRINT("NP: Cannot disinherit X connection fd\n");
    execv(plugin->vmName, plugin->argv);
    fprintf(stderr, "Squeak Plugin: running \"%s\"\n", plugin->vmName);
    perror("Squeak execv() failed");
    exit(1);
  } 
  DPRINT("NP: Sending nswindow=0x%X\n", plugin->nswindow);
  /* send browser window */
  SendInt(plugin, plugin->nswindow);
  /* wait for Squeak window opened */
  DPRINT("NP: waiting for sqwindow\n");
  Receive(plugin, &plugin->sqwindow, 4);
  DPRINT("NP: got sqwindow=0x%X\n", plugin->sqwindow);
  {
    XWindowAttributes attr;
    XGetWindowAttributes(plugin->display, plugin->nswindow, &attr);
    XResizeWindow(plugin->display, plugin->sqwindow, attr.width, attr.height);
  }
  DPRINT("NP: Reparenting to plugin window 0x%X\n", plugin->nswindow);
  XReparentWindow(plugin->display, plugin->sqwindow, plugin->nswindow, 0, 0);
  XMapWindow(plugin->display, plugin->sqwindow);
  /* establish communication via command pipes */
  {
    XtAppContext app= XtDisplayToApplicationContext(plugin->display);
    plugin->input= XtAppAddInput(app,
				 plugin->pipes[PLUGIN_READ],
				 (XtPointer) XtInputReadMask,
				 (XtInputCallbackProc) InputCallback,
				 plugin);
  }
}


static void
SetWindow(SqueakPlugin *plugin, Window window, int width, int height)
{
  DPRINT("NP: SetWindow(0x%X, %i@%i)\n", window, width, height);
  if (plugin->nswindow == window) {
    XResizeWindow(plugin->display, plugin->nswindow, width, height);
  } else {
    /* New window */
    plugin->nswindow= window;
    SetUpWindow(plugin);
    if (plugin->sqwindow) {
      DPRINT("NP: Reparenting to plugin window 0x%X\n", plugin->nswindow);
      XReparentWindow(plugin->display, plugin->sqwindow, plugin->nswindow, 0, 0);
      XMapWindow(plugin->display, plugin->sqwindow);
      /* notify Squeak */
      SendInt(plugin, CMD_BROWSER_WINDOW);
      SendInt(plugin, plugin->nswindow);
    }
  }
  if (plugin->sqwindow)
    XResizeWindow(plugin->display, plugin->sqwindow, width, height);
}


static void
SetUpWindow(SqueakPlugin *plugin)
{
  Widget w= XtWindowToWidget(plugin->display, plugin->nswindow);
  DPRINT("NP: SetUpWindow(0x%X)\n", plugin->nswindow);
  XSelectInput(plugin->display, plugin->nswindow, 0); 
  if (plugin->embedded) {
    /* need to capture destroys when page is re-layouted */
    XtAddCallback(w, XtNdestroyCallback, 
		  (XtCallbackProc) DestroyCallback, plugin);
  }
}

static int
IgnoreErrors(Display *display, XErrorEvent *evt)
{
  DPRINT("NP: X Error ignored.\n");
  return 1;
}

static void
DestroyCallback(Widget widget, SqueakPlugin *plugin, XtPointer data)
{
  int (*previous)(Display *, XErrorEvent *);

  DPRINT("NP: DestroyCallback()\n");

  /* Ignore errors due to the window being closed */
  XSync(plugin->display, False);
  previous= XSetErrorHandler(IgnoreErrors);

  /* Save Squeak window from being destroyed by page re-layout */
  DPRINT("NP: Reparenting to root window\n");
  XUnmapWindow(plugin->display, plugin->sqwindow);
  XReparentWindow(plugin->display, plugin->sqwindow,
		  DefaultRootWindow(plugin->display), 0, 0);

  /* Report errors */
  XSync(plugin->display, False);
  XSetErrorHandler(previous);
}

static void 
InputCallback(SqueakPlugin *plugin, int *source, XtInputId* id)
{
  int cmd;
  DPRINT("NP: InputCallback()\n");
  Receive(plugin, &cmd, 4);
  switch (cmd) {
  case CMD_GET_URL: 
    GetUrl(plugin);
    break;
  case CMD_POST_URL: 
    PostUrl(plugin);
    break;
  default:
    fprintf(stderr, "Unknown command from Squeak: %i\n", cmd);
  }
}


static void
GetUrl(SqueakPlugin *plugin)
{
  char *url, *target;
  int id, urlSize, targetSize;

  errno= 0;
  Receive(plugin, &id, 4);
  /* Read URL from pipe */
  Receive(plugin, &urlSize, 4);
  if (urlSize > 0) {
    url= NPN_MemAlloc(urlSize+1);
    Receive(plugin, url, urlSize);
    url[urlSize]= 0;
  } else url= NULL;
  /* Read target from pipe */
  Receive(plugin, &targetSize, 4);
  if (targetSize > 0) {
    target= NPN_MemAlloc(targetSize+1);
    Receive(plugin, target, targetSize);
    target[targetSize]= 0;
  } else target= NULL;

  if (errno) {
    perror("Squeak Plugin (GetUrl)");
  } else {
    if (strcmp(url, plugin->srcUrl)==0) {
      if (plugin->srcFilename)
	DeliverFile(plugin, id, plugin->srcFilename);
      else
	plugin->srcId= id;
    } else {
      SqueakStream* notifyData= (SqueakStream*) NPN_MemAlloc(sizeof(SqueakStream));
      if (!notifyData) { 
	fprintf(stderr, "Squeak Plugin (GetUrl): alloc failed\n");
      } else {
	DPRINT("NP: GetURLNotify(%s, id=%i)\n", url, id);
	notifyData->id= id;
	NPN_GetURLNotify(plugin->instance, url, target, notifyData);
	DPRINT("NP: GetURLNotify() returned\n");
      }
    }
  }

  if (url) NPN_MemFree(url);
  if (target) NPN_MemFree(target);
}

static void
PostUrl(SqueakPlugin *plugin)
{
  char *url, *target, *data;
  int id, urlSize, targetSize, dataSize;

  errno= 0;
  Receive(plugin, &id, 4);
  /* Read URL from pipe */
  Receive(plugin, &urlSize, 4);
  if (urlSize > 0) {
    url= NPN_MemAlloc(urlSize+1);
    Receive(plugin, url, urlSize);
    url[urlSize]= 0;
  } else url= NULL;
  /* Read target from pipe */
  Receive(plugin, &targetSize, 4);
  if (targetSize > 0) {
    target= NPN_MemAlloc(targetSize+1);
    Receive(plugin, target, targetSize);
    target[targetSize]= 0;
  } else target= NULL;
  /* Read post data from pipe */
  Receive(plugin, &dataSize, 4);
  if (dataSize > 0) {
    data= NPN_MemAlloc(dataSize);
    Receive(plugin, data, dataSize);
  } else data= NULL;

  if (errno) {
    perror("Squeak Plugin (PostUrl)");
  } else {
    SqueakStream* notifyData= (SqueakStream*) NPN_MemAlloc(sizeof(SqueakStream));
    if (!notifyData) { 
      fprintf(stderr, "Squeak Plugin (PostUrl): alloc failed\n");
    } else {
      DPRINT("NP: PostURLNotify(%s, id=%i)\n", url, id);
      notifyData->id= id;
      NPN_PostURLNotify(plugin->instance, url, target, 
			dataSize, data, FALSE, notifyData);
    }
  }

  if (url) NPN_MemFree(url);
  if (target) NPN_MemFree(target);
  if (data) NPN_MemFree(data);
}
