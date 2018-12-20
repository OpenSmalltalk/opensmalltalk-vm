/* -*- Mode: C; tab-width: 8; -*-
 *
 * Browser Plugin for Squeak on Unix platforms
 * 
 * Author:  Bert Freudenberg
 *
 * Last edited: 2005-03-17 12:15:48 by piumarta on squeak.hpl.hp.com
 *
 * History:
 *          Jan 2005 - looking for image and npsqueakrun in system and home dir
 *                     kill squeak window when destroyed
 *          Apr 2004 - (ikp) handle imageName and failureUrl tags
 *          Oct 2002 - system-wide install
 *          Sep 2002 - create hard links for streamed files
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

#undef DEBUG 

#if defined (DEBUG)
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
static void DPRINT(char *format, ...) { }
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
  char *failureUrl;
} SqueakPlugin;

/* URL notify data */
typedef struct SqueakStream {
  int id;                          /* request id (0 if finished)  */
} SqueakStream;

/***********************************************************************
 * Prototypes
 ***********************************************************************/

static void DeliverFile(SqueakPlugin *, int id, const char* fname);
static void SetWindow(SqueakPlugin*, Window window, int width, int height);
static void SetUpWindow(SqueakPlugin*);
static void SetUpSqueakWindow(SqueakPlugin*);
static void Run(SqueakPlugin*);
static void GetUrl(SqueakPlugin*);
static void PostUrl(SqueakPlugin*);
static void DestroyCallback(Widget widget, SqueakPlugin *, XtPointer calldata);
static void InputCallback(SqueakPlugin *, int *source, XtInputId*);

static char* NPN_StrDup(const char* s)
{
  return strcpy(NPN_MemAlloc(strlen(s) + 1), s);
}


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
      " <a href=\"mailto:Ian.Piumarta@squeakland.org\">Ian Piumarta</a>"
      " and others.";
    break;
  default:
    return NPERR_GENERIC_ERROR;
  }
  return NPERR_NO_ERROR;
}



/***********************************************************************
 * search filename in list of dirs and write path into result 
 * returns 0 if filename not found  
 ***********************************************************************/ 

static char*
findFileInPaths(char* result, char *filename, int dirn, char *dirv[PATH_MAX]){
  int i;
  char path[PATH_MAX];

  for(i= 0; i < dirn; i++){
    DPRINT("NP: search \"%s\" in \"%s\" \n",filename,dirv[i]);

    strcpy(path, dirv[i]);
    strcat(path, filename); 
    if (access(path, R_OK) == 0){ 
      DPRINT("NP:  \"%s\" in \"%s\" found\n",filename,dirv[i]);
      return strcpy(result, path);
    }
  }
  DPRINT("NP: nothing found\n");
  return 0;
}


/***********************************************************************
 * Plugin loading and termination
 ***********************************************************************/ 

static int
IgnoreErrors(Display *display, XErrorEvent *evt)
{
  DPRINT("NP: X Error ignored.\n");
  return 1;
}


NPError 
NPP_New(NPMIMEType pluginType, NPP instance, uint16 mode, int16 argc,
		char* argn[], char* argv[], NPSavedData* saved)
{
  SqueakPlugin *plugin;

  char imagename[PATH_MAX];
  char *failureUrl= 0;

  if (instance == NULL)
    return NPERR_INVALID_INSTANCE_ERROR;
  plugin= (SqueakPlugin*) NPN_MemAlloc(sizeof(SqueakPlugin));
  if (!plugin)
    return NPERR_OUT_OF_MEMORY_ERROR;
  plugin->argv= (char**) NPN_MemAlloc(sizeof(char*) * (16 + 2 * argc));
  if (!plugin->argv)
    return NPERR_OUT_OF_MEMORY_ERROR;

  /* Default settings */
  strcpy(imagename, "SqueakPlugin.image"); 

  plugin->instance=    instance;
  plugin->pid=         0;
  plugin->nswindow=    0;
  plugin->sqwindow=    0;
  plugin->display=     NULL;
  plugin->input=       0;
  plugin->embedded=    (mode == NP_EMBED);
  plugin->srcUrl=      NULL;
  plugin->srcFilename= NULL;
  plugin->srcId=       -1;
  plugin->failureUrl=  0;
  plugin->argv[0]=     NPN_StrDup(plugin->vmName);
  plugin->argv[1]=     NPN_StrDup("-display");
  plugin->argv[2]=     NULL;             /* inserted later */
  plugin->argv[3]=     NPN_StrDup("-browserPipes");
  plugin->argv[4]=     NULL;             /* inserted later */
  plugin->argv[5]=     NULL;             /* inserted later */
  plugin->argv[7]=     NPN_StrDup("");   /* empty document file on cmdline! */ 
  plugin->argc=        8;

  if (plugin->embedded) {
    int i;
    for (i= 0; i < argc; i++) {
      if (!strcasecmp(argn[i], "imagename"))
	{
	  strcpy(imagename, argv[i]);
	}
      else if (!strcasecmp(argn[i], "failureurl"))
	failureUrl= argv[i];
      plugin->argv[plugin->argc++]= NPN_StrDup(argn[i]);
      plugin->argv[plugin->argc++]= NPN_StrDup(argv[i] ? argv[i] : "");
      if (strcasecmp("SRC", argn[i]) == 0)
	plugin->srcUrl= NPN_StrDup(argv[i]);
    }
    if (!plugin->srcUrl)
      plugin->srcUrl= NPN_StrDup(""); /* we were embedded without a SRC */

    
    /* find npsqueakrun and image */
    {
      char user_bin_dir[PATH_MAX];
      char user_img_dir[PATH_MAX];
      char* home= getenv("HOME");
      if (home == 0) {
	fprintf(stderr, "Squeak Plugin: No home directory?!\n");
	return NPERR_GENERIC_ERROR;
      }
      strcpy(user_bin_dir, home);
      strcat(user_bin_dir, "/.npsqueak/");
      
      strcpy(user_img_dir, home);
      strcat(user_img_dir, "/.npsqueak/");
      
      {
	char* bin_dir_v[PATH_MAX]= {user_bin_dir,
				    SYSTEM_BIN_DIR"/"};
	if (findFileInPaths(plugin->vmName, NPSQUEAKRUN, 2 , bin_dir_v) == 0){
	  fprintf(stderr, "Squeak Plugin: npsqueakrun not found!\n");
	  return NPERR_GENERIC_ERROR;
	}
      }

      {
	char* img_dir_v[PATH_MAX]= {user_img_dir, SYSTEM_IMG_DIR"/"};
	if (findFileInPaths(plugin->imageName, imagename, 2, img_dir_v) == 0){
	  fprintf(stderr, "Squeak Plugin: Image file not found: %s\n", 
		  imagename);
	  if (failureUrl){
	    fprintf(stderr, "Squeak Plugin: going to failure URL: %s\n", 
		    failureUrl);
	    plugin->failureUrl= NPN_StrDup(failureUrl);
	  }else {
	    fprintf(stderr, "Squeak Plugin: no failure URL: \n");
	    return NPERR_GENERIC_ERROR;
	  }
	}
	plugin->argv[6]= NPN_StrDup(plugin->imageName); 
      }
    }
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
  DPRINT("NP: Created pipes (VM read: %d <- %d, NP read: %d <- %d)\n", 
	 plugin->pipes[SQUEAK_READ],
	 plugin->pipes[PLUGIN_WRITE],
	 plugin->pipes[PLUGIN_READ],
	 plugin->pipes[SQUEAK_WRITE]);
  instance->pdata= (void*) plugin;
  return NPERR_NO_ERROR;
}

NPError 
NPP_Destroy(NPP instance, NPSavedData** save)
{
  SqueakPlugin *plugin;
  DPRINT("NP: NPP_Destroy\n");
  if (!instance)
    return NPERR_INVALID_INSTANCE_ERROR;
  plugin= (SqueakPlugin*) instance->pdata;
  if (plugin) {
    int i;
    if (plugin->sqwindow && plugin->display) {
      DPRINT("NP: DestroyWindow %x\n", 
	     plugin->sqwindow);
      XSetErrorHandler(IgnoreErrors);
      XSync(plugin->display,0);
      XKillClient(plugin->display, plugin->sqwindow);
      XSync(plugin->display,0);
    }
    if (plugin->pid) {
      DPRINT("NP: kill 0x%i\n", plugin->pid);
      kill(plugin->pid, SIGTERM);
      plugin->pid= 0;
    }
    if (plugin->input) {
      XtRemoveInput(plugin->input);
    }
    for (i= 0; i < 4; i++)
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
    if (plugin->failureUrl) {
      NPN_MemFree(plugin->failureUrl);
      plugin->failureUrl= NULL;
    }
    if (plugin->argv) {
      for (i= 0; i < plugin->argc; i++) {
	if (plugin->argv[i])
	  NPN_MemFree(plugin->argv[i]);
      }
      plugin->argc= 0;
      NPN_MemFree(plugin->argv);
      plugin->argv= NULL;
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
  if (plugin->failureUrl) {
    DPRINT("NP: opening failure URL");
    NPN_GetURL(plugin->instance, plugin->failureUrl, "_self");
    return NPERR_NO_ERROR;
  }
  if (pNPWindow == NULL) 
    return NPERR_NO_ERROR;
  
  if (!plugin->display) {
    /* first time only */
    plugin->display= 
      ((NPSetWindowCallbackStruct *)pNPWindow->ws_info)->display;
  }
  SetWindow(plugin, (Window) pNPWindow->window, 
	    pNPWindow->width, pNPWindow->height);
  if (!plugin->pid)
    Run(plugin);
  return NPERR_NO_ERROR;
}

NPError 
NPP_NewStream(NPP instance, NPMIMEType type, 
	      NPStream *stream, NPBool seekable, uint16 *stype)
{
  SqueakPlugin *plugin= (SqueakPlugin*) instance->pdata;
  DPRINT("NP: NewStream(%s, id=%i)\n", stream->url,
	 stream->notifyData ? ((SqueakStream*) stream->notifyData)->id : -1);
  
  if (!stream->notifyData && !plugin->srcUrl) {
    /* We did not request this stream, so it is our SRC file. */
    plugin->srcUrl= NPN_StrDup(stream->url);
    plugin->argv[plugin->argc++]= NPN_StrDup("SRC");
    plugin->argv[plugin->argc++]= NPN_StrDup(plugin->srcUrl);
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
  char lname[PATH_MAX];
  SqueakPlugin *plugin= (SqueakPlugin*) instance->pdata;
  DPRINT("NP: StreamAsFile(%s, id=%i)\n", stream->url, id);
  DPRINT("NP:   fname=%s\n", fname ? fname : "<NULL>");
  if (!plugin || !fname) return;

  /* need to copy file because it might be deleted after return */
  strncpy(lname, fname, PATH_MAX);
  strcat(lname, "$");
  DPRINT("NP:  lname=%s\n", lname);
  if (-1 == link(fname, lname))
    DPRINT("NP:   Link failed: %s\n", strerror(errno));
  fname= lname;

  if (!stream->notifyData && !plugin->srcFilename) {
    /* We did not request this stream, so it is our SRC file. */
    plugin->srcFilename= NPN_StrDup(fname);
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
NPP_Write(NPP instance, NPStream *stream, 
	  int32 offset, int32 len, void *buffer)
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
  if (plugin->pid || !plugin->nswindow || !plugin->srcUrl ||plugin->failureUrl)
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
    plugin->argv[2]= NPN_StrDup(DisplayString(plugin->display));
    sprintf(tmp1, "%i", plugin->pipes[SQUEAK_READ]);
    plugin->argv[4]= NPN_StrDup(tmp1);
    sprintf(tmp2, "%i", plugin->pipes[SQUEAK_WRITE]);
    plugin->argv[5]= NPN_StrDup(tmp2);
    DPRINT("NP(child): Running Squeak VM with arguments\n");
    {
      int i;
      for (i= 1; i<plugin->argc; i++)
	DPRINT("    %s\n", plugin->argv[i]);
    }
    /* this is from the XLib manual ... */
    if ((fcntl(ConnectionNumber(plugin->display), F_SETFD, FD_CLOEXEC)) == -1)
      DPRINT("NP: Cannot disinherit X connection fd\n");
    DPRINT("NP(child): trying %s\n", plugin->vmName);
    execv(plugin->vmName, plugin->argv);
    /* ~/.npsqueak/npsqueakrun could not be executed */
    strcpy(plugin->vmName, SYSTEM_BIN_DIR "/" NPSQUEAKRUN);
    NPN_MemFree(plugin->argv[0]);
    plugin->argv[0]= NPN_StrDup(plugin->vmName);
    DPRINT("NP(child): trying %s\n", plugin->vmName);
    execv(plugin->vmName, plugin->argv);
    /* npsqueakrun could not be executed either */
    fprintf(stderr, "Squeak Plugin: running \"%s\"\n", plugin->vmName);
    perror("Squeak execv() failed");
    _exit(1);
  } else {
    /* establish communication via command pipes */
    XtAppContext app= XtDisplayToApplicationContext(plugin->display);
    plugin->input= XtAppAddInput(app,
				 plugin->pipes[PLUGIN_READ],
				 (XtPointer) XtInputReadMask,
				 (XtInputCallbackProc) InputCallback,
				 plugin);
  
    /* send browser window */
    DPRINT("NP: Sending browser window=0x%X\n", plugin->nswindow);
    SendInt(plugin, plugin->nswindow);
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


static void
SetUpSqueakWindow(SqueakPlugin *plugin)
{
  Receive(plugin, &plugin->sqwindow, 4);
  DPRINT("NP: got squeak window=0x%X\n", plugin->sqwindow);
  DPRINT("NP: resizing squeak window\n");
  {
    XWindowAttributes attr;
    XGetWindowAttributes(plugin->display, plugin->nswindow, &attr);
    XResizeWindow(plugin->display, plugin->sqwindow, attr.width, attr.height);
  }
  DPRINT("NP: mapping squeak window\n");
  XMapWindow(plugin->display, plugin->sqwindow);
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
  if (!plugin->sqwindow)
    {
      /* read sqwindow */
      SetUpSqueakWindow(plugin);
      return;
    }
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
    DPRINT("NP: GetUrl(%s, %s)\n", url, target ? target : "NULL");
    if (strcmp(url, plugin->srcUrl)==0) {
      if (plugin->srcFilename)
	DeliverFile(plugin, id, plugin->srcFilename);
      else
	plugin->srcId= id;
    } else {
      SqueakStream* notifyData= 
	(SqueakStream*) NPN_MemAlloc(sizeof(SqueakStream));
      if (!notifyData) { 
	fprintf(stderr, "Squeak Plugin (GetUrl): alloc failed\n");
      } else {
	DPRINT("NP: GetURLNotify(%s, id=%i)\n", url, id);
	notifyData->id= id;
	NPN_GetURLNotify(plugin->instance, url, target, notifyData);
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
    SqueakStream* notifyData= 
      (SqueakStream*) NPN_MemAlloc(sizeof(SqueakStream));
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
