/* -*- Mode: C; tab-width: 8; -*-
 *
 * Browser Plugin for Squeak on Unix platforms
 * 
 * Author:  Bert Freudenberg
 *
 *
 * History:
			Oct 2006 - Mods by johnmci@smalltalkconsulting.com to fit quartz carbon mac vm backend
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
 
	March 10th, 2007 - JMM add feature to enable debug printing
	March 12th, 2007 - JMM remove aio logic, revert to simple pipe for I/O to avoid race
					 -		Try to make clipping and drawing work for both safari and firefox. 
  
    */
 
#define TARGET_CARBON   1
#import <WebKit/npapi.h>
#import <WebKit/npfunctions.h>
#import <WebKit/npruntime.h>
#include <stdio.h>
#include <unistd.h>
#include <limits.h>
#include <signal.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <pthread.h>
#include <Math.h>


static int gDebugPrintIsOn=0;

static void DPRINT(char *format, ...)
{  
	 if (!gDebugPrintIsOn) 
		return;
	va_list ap;
	va_start(ap, format);
	vfprintf(stderr, format, ap);
	va_end(ap);

}

/***********************************************************************
 * Plugin instance data
 ***********************************************************************/
#define CMD_GET_URL        2
#define CMD_POST_URL       3
#define CMD_RECEIVE_DATA   4
#define CMD_SHARED_MEMORY  5
#define CMD_EVENT		   7
#define CMD_SET_CURSOR	   8

#define MAX_STREAMS 128

#define SQUEAK_READ  0
#define PLUGIN_WRITE 1
#define PLUGIN_READ  2
#define SQUEAK_WRITE 3

extern NPNetscapeFuncs* browser;

typedef struct SqueakSharedMemoryBlock {
	int		written;
	int		top;
	int		right;
	int		bottom;
	int		left;
	char	screenBits[];
} SqueakSharedMemoryBlock;

/* plugin state */
typedef struct SqueakPlugin {
  NPP		instance;                    /* plugin instance */
  pid_t		pid;                       /* the child process pid */
  NP_Port	*display;
  SqueakSharedMemoryBlock		*sharedMemoryBlock;                 /* the Squeak window */
  int		sharedMemoryfd;
  char		sharedMemoryName[256];
  CGColorSpaceRef colorspace;
  int		width;
  int		height;
  int		rowBytes;
  NPRect    clipRect;    /* Clipping rectangle in port coordinates */
  Rect		portRect;
  Boolean	embedded;                   /* false if we have the whole window */
  Boolean	buttonIsDown;
  Boolean   hasCursor;
  Boolean	customCursor;
  char		**argv;                     /* the commandline for Squeak vm */
  int		argc;
  char		vmName[PATH_MAX];
  char		imageName[PATH_MAX];
  int		pipes[4];                    /* 4 ends of 2 pipes */
  char*		srcUrl;                    /* set by browser in first NewStream */
  char*		srcFilename;
  int		srcId;                     /* if requested */
//  pthread_mutex_t   SleepLock;
//  pthread_cond_t    SleepLockCondition;
  pthread_mutex_t	readPipeMutex;      /* mutex just in case */ 
//  pthread_t			SqueakPThread;
  EventLoopTimerUPP	eventLoopTimerUPP;	/* timer proc address */
  EventLoopTimerRef  eventLoopTimerRef; /* timer event thread */
  int		threadPleaseStop;
  char*		failureUrl;
  Cursor macCursor;
} SqueakPlugin;

/* URL notify data */
typedef struct SqueakStream {
   int id;                          /* request id (-1 if finished)  */
   char *fname;                     /* file name when streaming */
   int fd;                          /* file descriptor when streaming */
} SqueakStream;

static int sharedMemIDIncremental=0;
static int gWindowMaxLength;

/***********************************************************************
 * Prototypes
 ***********************************************************************/

static void DeliverFile(SqueakPlugin *, int id, const char* fname);
static void SetWindow(SqueakPlugin*,  NPWindow *window, int width, int height);
static void SetUpSqueakWindow(SqueakPlugin*);
static void Run(SqueakPlugin*);
static void GetUrl(SqueakPlugin*);
static void PostUrl(SqueakPlugin*);
static void browserProcessCommand(SqueakPlugin *plugin,int cmd);
static void setWindowLogic(SqueakPlugin *plugin, int width, int height);
static void	getCStringForInfoString(char *cString,char *infoString,int maxLength, CFStringBuiltInEncodings encoding);
static CFTypeRef getRefForInfoString(char *infoString);
static int	getNumberForInfoString(char *infoString);
void drawToScreen(SqueakPlugin *plugin);

static char* NPN_StrDup(const char* s)
{
  return strcpy(browser->memalloc(strlen(s) + 1), s);
}
/***********************************************************************
 * search filename in list of dirs and write path into result 
 * returns 0 if filename not found  
 ***********************************************************************/ 

static char* findFileInPaths(char* result, char *filename, int dirn, char *dirv[PATH_MAX]){
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

static CFTypeRef getRefForInfoString(char *infoString) {
	static CFBundleRef  myBundle = NULL;
	static CFDictionaryRef myDictionary = NULL;
	static CFStringRef	bundleID = NULL;
	CFStringRef	stringRef = NULL,infoStringKey;	
	
	if (bundleID == NULL) {
		bundleID= CFStringCreateWithCString(NULL,"org.squeak.SqueakPlugin",kCFStringEncodingMacRoman);
		myBundle = CFBundleGetBundleWithIdentifier(bundleID);
		if (myBundle == NULL) 
			return NULL;
		myDictionary = CFBundleGetInfoDictionary(myBundle);
	}
	if (myDictionary == NULL) 
		return NULL ;
	infoStringKey = CFStringCreateWithCString(NULL,infoString,kCFStringEncodingMacRoman);
	stringRef = CFDictionaryGetValue(myDictionary,infoStringKey);
	CFRelease(infoStringKey);
	return stringRef;
}

static void	getCStringForInfoString(char *cString,char *infoString,int maxLength, CFStringBuiltInEncodings encoding) {
	CFStringRef	stringRef = getRefForInfoString(infoString);
	
	if (stringRef) 
			CFStringGetCString (stringRef, cString, maxLength, encoding);
}

static int	getNumberForInfoString(char *infoString) {
	CFNumberRef	numberRef = getRefForInfoString(infoString);
	long number;
    if (numberRef == NULL) 
		return 0;
	CFNumberGetValue(numberRef,kCFNumberLongType,(long *) &number);
	return number;
}

/***********************************************************************
 * Plugin loading and termination
 ***********************************************************************/ 

NPError 
NPP_New(NPMIMEType pluginType, NPP instance, uint16 mode, int16 argc,
		char* argn[], char* argv[], NPSavedData* saved)
{
  SqueakPlugin *plugin;

  char imagename[PATH_MAX];
  char *failureUrl= 0;

  if (instance == NULL)
    return NPERR_INVALID_INSTANCE_ERROR;
  plugin= (SqueakPlugin*) browser->memalloc(sizeof(SqueakPlugin));
  if (!plugin)
    return NPERR_OUT_OF_MEMORY_ERROR;
  plugin->argv= (char**) browser->memalloc(sizeof(char*) * (9 + 2 * argc));
  if (!plugin->argv)
    return NPERR_OUT_OF_MEMORY_ERROR;

  /* Default settings */
  getCStringForInfoString(imagename,"SqueakImageName",PATH_MAX, kCFStringEncodingUTF8);
  gDebugPrintIsOn = getNumberForInfoString("SqueakDebug");
  gWindowMaxLength = getNumberForInfoString("SqueakWindowMaxLength");
  if (gWindowMaxLength == 0) 
		gWindowMaxLength = 2048;
		
	
 if (sharedMemIDIncremental == 0) {
	extern void srandomdev(void) __attribute__((weak_import));
	if (srandomdev == NULL)
		srandom(time(NULL));
	else
		srandomdev();
	sharedMemIDIncremental = random();
 }

  plugin->instance=    instance;
  plugin->pid=         0;
  plugin->sharedMemoryBlock=    0;
  plugin->sharedMemoryfd	= 0;
  *plugin->sharedMemoryName = 0x00;
  plugin->colorspace		= NULL;
  plugin->buttonIsDown = false;
  plugin->display=     NULL;
  plugin->embedded=    (mode == NP_EMBED);
  plugin->hasCursor =  true;
  plugin->customCursor = false;
  plugin->srcUrl=      NULL;
  plugin->srcFilename= NULL;
  plugin->srcId=       -1;
  plugin->failureUrl=  0;
  plugin->argv[0]=     NPN_StrDup("squeakvm");
  plugin->argv[1]=     NPN_StrDup("-headless");
  plugin->argv[2]=     NPN_StrDup("-browserPipes");
  plugin->argv[3]=     NULL;             /* inserted later */
  plugin->argv[4]=     NULL;             /* inserted later */
  plugin->argv[5]=     NULL;             /* inserted later */
  plugin->argv[6]=     NPN_StrDup("");   /* empty document file on cmdline! */ 
  plugin->argc=        7;
//  plugin->SqueakPThread = 0;
  plugin->threadPleaseStop = 0;
  plugin->eventLoopTimerRef = NULL;
  plugin->eventLoopTimerUPP = NULL;
  if (plugin->embedded) {
    int i;
    for (i= 0; i < argc; i++) {
      if (!strcasecmp(argn[i], "imagename")) {
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
		char squeakVMPath[PATH_MAX+1],squeakVMName[256];
		getCStringForInfoString(squeakVMPath,"SqueakVMPath",PATH_MAX, kCFStringEncodingUTF8);
		getCStringForInfoString(squeakVMName,"SqueakVMName",256, kCFStringEncodingUTF8);
	
		char* bin_dir_v[PATH_MAX]= {squeakVMPath,
			"/Users/johnmci/Documents/Squeak3.8.0/build/Development/Squeak VM Opt.app/Contents/MacOS/"};
		if (findFileInPaths(plugin->vmName, squeakVMName, 2 , bin_dir_v) == 0){
		  fprintf(stderr, "Squeak Plugin: VM not found!\n");
		  return NPERR_GENERIC_ERROR;
		} else {
			plugin->argv[0]= NPN_StrDup(plugin->vmName); 
		}
	}

	{
		char imagePath[PATH_MAX+1];
		getCStringForInfoString(imagePath,"SqueakImagePath",PATH_MAX, kCFStringEncodingUTF8);

		char* img_dir_v[PATH_MAX]= {imagePath};
		if (findFileInPaths(plugin->imageName, imagename, 1, img_dir_v) == 0){
			  fprintf(stderr, "Squeak Plugin: Image file not found: %s\n", imagename);
			  if (failureUrl){
				fprintf(stderr, "Squeak Plugin: going to failure URL: %s\n", failureUrl);
				plugin->failureUrl= NPN_StrDup(failureUrl);
			  }else {
				fprintf(stderr, "Squeak Plugin: no failure URL: \n");
				return NPERR_GENERIC_ERROR;
			  } 
		}  
	}

	plugin->argv[5]= NPN_StrDup(plugin->imageName); 
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
  fcntl(plugin->pipes[PLUGIN_WRITE], F_SETFL, O_NONBLOCK);
  //signal(SIGPIPE,SIG_IGN);
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
	plugin->threadPleaseStop = 1;
    if (plugin->pid) {
      DPRINT("NP: kill 0x%i\n", plugin->pid);
      kill(plugin->pid, SIGTERM);
      plugin->pid= 0;
    }
    for (i= 0; i < 4; i++)
      if (plugin->pipes[i]) {
		close(plugin->pipes[i]);
		plugin->pipes[i]= 0;
      }
    if (plugin->srcUrl) {
      browser->memfree(plugin->srcUrl);
      plugin->srcUrl= NULL;
    }
    if (plugin->srcFilename) {
      browser->memfree(plugin->srcFilename);
      plugin->srcFilename= NULL;
    }
    if (plugin->failureUrl) {
      browser->memfree(plugin->failureUrl);
      plugin->failureUrl= NULL;
    }
    if (plugin->argv) {
      for (i= 0; i < plugin->argc; i++) {
	if (plugin->argv[i])
	  browser->memfree(plugin->argv[i]);
      }
      plugin->argc= 0;
      browser->memfree(plugin->argv);
      plugin->argv= NULL;
    }

	if (plugin->sharedMemoryfd) {
		int possibleError;
		DPRINT("NP: destroy memory ID %i at %i \n", plugin->sharedMemoryfd,plugin->sharedMemoryBlock);
		munmap(plugin->sharedMemoryBlock,gWindowMaxLength*gWindowMaxLength*4+20);
		close(plugin->sharedMemoryfd);
		possibleError = shm_unlink(plugin->sharedMemoryName);
		plugin->sharedMemoryBlock = 0;
		plugin->sharedMemoryfd = 0;
	}
	
/*	if (plugin->SqueakPThread) { /* take event timer down 
		int err;
        err = pthread_cancel(plugin->SqueakPThread);
       if (err == 0 )
			pthread_join(plugin->SqueakPThread,NULL);
		pthread_mutex_destroy(&plugin->SleepLock);
        pthread_cond_destroy(&plugin->SleepLockCondition);
	} */
	
	if (plugin->eventLoopTimerRef) { /* take event timer down */
		RemoveEventLoopTimer(plugin->eventLoopTimerRef);
		DisposeEventLoopTimerUPP(plugin->eventLoopTimerUPP);
		pthread_mutex_destroy(&plugin->readPipeMutex);
		plugin->eventLoopTimerRef = NULL;
		plugin->eventLoopTimerUPP = NULL;
	}

    browser->memfree(plugin);
  }
  instance->pdata= NULL;
  return NPERR_NO_ERROR;
}


void NP_Shutdown(void)
{

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
    plugin->display= pNPWindow->window;
  }
  if (pNPWindow->clipRect.top == 0 &&
	pNPWindow->clipRect.left == 0 &&
	pNPWindow->clipRect.bottom == 0 &&
	pNPWindow->clipRect.right == 0)
		return NPERR_NO_ERROR;
	
  if (!plugin->pid)
    Run(plugin);
  plugin->clipRect = pNPWindow->clipRect;
  SetWindow(plugin, pNPWindow, pNPWindow->width, pNPWindow->height);
  return NPERR_NO_ERROR;
}

NPError 
NPP_NewStream(NPP instance, NPMIMEType type, 
	      NPStream *stream, NPBool seekable, uint16 *stype)
{
  SqueakPlugin *plugin= (SqueakPlugin*) instance->pdata;
  DPRINT("NP: NPP_NewStream(%s, id=%i)\n", stream->url,
	 stream->notifyData ? ((SqueakStream*) stream->notifyData)->id : -1);
  
  if (!stream->notifyData && !plugin->srcUrl) {
    /* We did not request this stream, so it is our SRC file. */
    plugin->srcUrl= NPN_StrDup(stream->url);
    plugin->argv[plugin->argc++]= NPN_StrDup("SRC");
    plugin->argv[plugin->argc++]= NPN_StrDup(plugin->srcUrl);
    DPRINT("NP:   got srcUrl=%s\n", plugin->srcUrl);
    Run(plugin);
  }
   if (stream->notifyData && ((SqueakStream*) stream->notifyData)->fd)
     *stype= NP_NORMAL;              /* We stream ourselfes */
   else
     *stype= NP_ASFILEONLY;          /* We want the file after download */
 
  
  return NPERR_NO_ERROR;
}


NPError 
NPP_DestroyStream(NPP instance, NPStream *stream, NPError reason)
{
  /* We'll clean up in URLNotify */
  DPRINT("NP: NPP_DestroyStream(%s, id=%i)\n", stream->url, 
	 stream->notifyData ? ((SqueakStream*) stream->notifyData)->id : -1);
  return NPERR_NO_ERROR;
}


void 
NPP_StreamAsFile(NPP instance, NPStream *stream, const char* fname)
{
  int id= stream->notifyData ? ((SqueakStream*) stream->notifyData)->id : -1;
        CFStringRef 	filePath;
        CFURLRef 	    sillyThing;
		char			pathName[PATH_MAX+1],lname[PATH_MAX+1];
  SqueakPlugin *plugin= (SqueakPlugin*) instance->pdata;

  DPRINT("NP: StreamAsFile(%s, id=%i)\n", stream->url, id);
  DPRINT("NP:   fname=%s\n", fname ? fname : "<NULL>");

  pathName[0] = 0x00;
  if (!plugin || !fname) return;
   if (strncmp(fname,(char *) &"/",1) == 0) {
	strncpy(pathName,fname, PATH_MAX);
   } else {
	filePath   = CFStringCreateWithBytes(kCFAllocatorDefault,(const UInt8 *)fname,strlen(fname),kCFStringEncodingMacRoman,false);
	sillyThing = CFURLCreateWithFileSystemPath (kCFAllocatorDefault,filePath,kCFURLHFSPathStyle,false);
	CFRelease(filePath);
	filePath = CFURLCopyFileSystemPath (sillyThing, kCFURLPOSIXPathStyle);
	CFRelease(sillyThing);
	CFStringGetCString (filePath, pathName,PATH_MAX, kCFStringEncodingUTF8);
	CFRelease(filePath);
  }
  
  /* need to copy file because it might be deleted after return */
  strncpy(lname, pathName, PATH_MAX);
  strcat(lname, "$");
  DPRINT("NP:  lname=%s\n", lname);
  if (-1 == link(pathName, lname))
    DPRINT("NP:   Link failed: %s\n", strerror(errno));
  strcpy(pathName, lname);
	
  if (!stream->notifyData && !plugin->srcFilename) {
    /* We did not request this stream, so it is our SRC file. */
		
    plugin->srcFilename= NPN_StrDup(pathName);
    DPRINT("NP:   got srcFilename=%s\n", plugin->srcFilename);
    if (plugin->srcId >= 0) {
      /* plugin wanted it already */
      DeliverFile(plugin, plugin->srcId, plugin->srcFilename);
      plugin->srcId= -1;
    }
    return;
  }

  DeliverFile(plugin, id, pathName);

  /* signal URLNotify that we're done */
  ((SqueakStream*) stream->notifyData)->id= -1;
  ((SqueakStream*) stream->notifyData)->fname= NPN_StrDup(pathName);
}

void
NPP_URLNotify(NPP instance, const char* url, NPReason reason, void* notifyData)
{
  int id= notifyData ? ((SqueakStream*) notifyData)->id : -1;
  int ok= reason == NPRES_DONE;
  SqueakPlugin *plugin= (SqueakPlugin*) instance->pdata;
  DPRINT("NP: NPP_URLNotify(%s, id=%i, ok=%i)\n", url, id, ok);
 	 (reason == NPRES_DONE ? "NPRES_DONE" : 
 	  (reason == NPRES_USER_BREAK ? "NPRES_USER_BREAK" :
 	   (reason == NPRES_NETWORK_ERR ? "NPRES_NETWORK_ERR" :
 	    "<unknown>")),
	 id, ok);

  if (notifyData)
    {
      if (-1 != id && ok && !((SqueakStream*)notifyData)->fname)
	{
	  /* Work around netscape/firefox bug */
	  char tmppath[255];
	  int tmpfd; 
	  DPRINT("NP:  Netscape bug: did not get url as file\n");
	  sprintf(tmppath, "/tmp/npsqueak-%d-XXXXXX", (unsigned)getpid());
	  tmpfd = mkstemp(tmppath);
	  if (-1 == tmpfd)
	    perror("Squeak plugin tmp file open failed");
	  else
	    {
	      ((SqueakStream*)notifyData)->fname= NPN_StrDup(tmppath);
	      ((SqueakStream*)notifyData)->fd= tmpfd;
	      DPRINT("NP:   Trying again as stream (%s)\n", tmppath);
	      DPRINT("NP: NPN_GetURLNotify(%s, id=%i)\n", url, id);
	      NPN_GetURLNotify(plugin->instance, url, NULL, notifyData);
	      return;
	    }
	}
      if (((SqueakStream*)notifyData)->fd)
	{ 
	  char lname[PATH_MAX];
	  close(((SqueakStream*)notifyData)->fd);
	  DPRINT("NP:  Netscape bug workaround successful!\n");
	  /* need to add $ so VM deletes file after finishing */
	  strncpy(lname, ((SqueakStream*)notifyData)->fname, PATH_MAX);
	  strcat(lname, "$");
 	  DPRINT("NP:  lname=%s\n", lname);
 	  if (-1 == rename(((SqueakStream*)notifyData)->fname, lname))
 	    DPRINT("NP:   Rename failed: %s\n", strerror(errno));
 	  DeliverFile(plugin, id, lname);
 	  id= -1;
 	}
       if (((SqueakStream*)notifyData)->fname)
			browser->memfree(((SqueakStream*)notifyData)->fname);
       browser->memfree(notifyData);
     }
  if (!plugin || -1 == id) return;

  DeliverFile(plugin, id, NULL);
}

NPError NPP_GetValue(NPP instance, NPPVariable variable, void *value)
{
       return NPERR_GENERIC_ERROR;
}

NPError NPP_SetValue(NPP instance, NPNVariable variable, void *value)
{
    return NPERR_GENERIC_ERROR;
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

/* jref
NPP_GetJavaClass()
{
  return NULL;
} */


int32 
NPP_WriteReady(NPP instance, NPStream *stream)
{
  return 16384;
}


int32 
NPP_Write(NPP instance, NPStream *stream, 
	  int32 offset, int32 len, void *buffer)
{
  DPRINT("NP: NPP_Write(%s, %d)\n", stream->url, len);
  SqueakStream* sqStream= (SqueakStream*) stream->notifyData;
  if (sqStream && sqStream->fd)
    {
      int n;
      do {
	n= write(sqStream->fd, buffer, len);
	DPRINT("NP:  writing to %s - wrote %d bytes\n", sqStream->fname, n);
      } while (n == -1 && errno == EINTR);
      return n;
    }
  else
    DPRINT("NP:  ignored\n");
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
  } while (n == -1 && (errno == EINTR || errno == EAGAIN));
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
  int retry=0;
  
  do {
    n= write(plugin->pipes[PLUGIN_WRITE], buf, count);
	if (n == -1 && errno == EAGAIN)  {
		retry++;
		if (retry > 20)
			return;
		}
		
  } while (n == -1 && (errno == EINTR  || errno == EAGAIN));
  if (n == -1)
    perror("Squeak plugin write failed:");
  if (n < count)
    fprintf(stderr, "Squeak plugin wrote too few data to pipe\n");
}



void
SendInt(SqueakPlugin *plugin, int value)
{
  Send(plugin, &value, 4);
}


static void 
DeliverFile(SqueakPlugin *plugin, int id, const char* fname)
{
  int ok= fname != NULL;
	DPRINT("NP:   Send RECEIVE_DATA id=%i ok=%i filename %s\n", id, ok,fname);
 
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

/*  Ok look every 10 milliseconds, 100 second we consider drawing, 
but use pipeReadThrottle flag to only read pipe 1/2 the time, say 50 times a second*/

/* void forkedSleepLoop(SqueakPlugin *plugin) {
	int n,err;
	int cmd;
	static bool pipeReadThrottle=true;
	static const int realTimeToWait=10;
	
	while(true) {
		if (plugin->threadPleaseStop) return;
		
		pthread_mutex_lock(&plugin->readPipeMutex);
		if (pipeReadThrottle) {
			n = read(plugin->pipes[PLUGIN_READ], &cmd, 4);
		} else {
			n = -1;
		}
		pipeReadThrottle = !pipeReadThrottle;
		drawToScreen(plugin);
		if (n == -1) {
			struct timespec tspec;
			
			pthread_mutex_unlock(&plugin->readPipeMutex);
			
			tspec.tv_sec=  realTimeToWait / 1000;
			tspec.tv_nsec= (realTimeToWait % 1000)*1000000;
    
			err = pthread_mutex_lock(&plugin->SleepLock);
			err = pthread_cond_timedwait_relative_np(&plugin->SleepLockCondition,&plugin->SleepLock,&tspec);	
			err = pthread_mutex_unlock(&plugin->SleepLock); 
		} else {
			browserProcessCommand(plugin,cmd);
			pthread_mutex_unlock(&plugin->readPipeMutex);
		}
	}
}
*/

static pascal void eventLoopPolling (EventLoopTimerRef theTimer,SqueakPlugin *plugin) {
	int n; 
	int cmd;

	/* Not sure if the lock is needed, but disaster if we run this routine on two cpus at the same time */
	
	pthread_mutex_lock(&plugin->readPipeMutex);
	drawToScreen(plugin);
	n= read(plugin->pipes[PLUGIN_READ], &cmd, 4);
	if (n == -1) {
		pthread_mutex_unlock(&plugin->readPipeMutex);
		return;
	}
	browserProcessCommand(plugin,cmd);
	pthread_mutex_unlock(&plugin->readPipeMutex);
}

void eventLoopParasite(SqueakPlugin *plugin) {
	int error;
	
	pthread_mutex_init(&plugin->readPipeMutex, NULL);
//	pthread_mutex_init(&plugin->SleepLock, 0);
//	pthread_cond_init(&plugin->SleepLockCondition,0);
//	err = pthread_create(&plugin->SqueakPThread,0,(void *) forkedSleepLoop, plugin);
					
	plugin->eventLoopTimerUPP = NewEventLoopTimerUPP((EventLoopTimerProcPtr)&eventLoopPolling);
	error = InstallEventLoopTimer (GetMainEventLoop(),
                       10*kEventDurationMillisecond,
                       kEventDurationMillisecond,
                       plugin->eventLoopTimerUPP,
                       plugin,&plugin->eventLoopTimerRef);
}

static void 
Run(SqueakPlugin *plugin)
{
  if (plugin->pid || !plugin->srcUrl ||plugin->failureUrl)
    return;
	
	fcntl(plugin->pipes[PLUGIN_READ], F_SETFL, O_NONBLOCK);
	eventLoopParasite(plugin);

	if (*plugin->sharedMemoryName == 0x00) {
		sharedMemIDIncremental++;
		sprintf(plugin->sharedMemoryName,"%i",42+plugin->pid+sharedMemIDIncremental);
		plugin->sharedMemoryfd = shm_open(plugin->sharedMemoryName,O_RDWR | O_CREAT,S_IRUSR+S_IWUSR);
		if (plugin->sharedMemoryfd < 0) {
			plugin->sharedMemoryfd = 0;
			perror("NP: shared memory shm_open failed\n");
			return;
		}
		ftruncate(plugin->sharedMemoryfd,gWindowMaxLength*gWindowMaxLength*4+20);
		plugin->sharedMemoryBlock= mmap(0, (gWindowMaxLength*gWindowMaxLength*4)+20, PROT_READ | PROT_WRITE, MAP_SHARED, plugin->sharedMemoryfd,0);
		DPRINT("NP: shared memory mmap memory fd %i at %i \n", plugin->sharedMemoryfd,plugin->sharedMemoryBlock);
		if (plugin->sharedMemoryBlock == MAP_FAILED) {  
			perror("NP: shared memory mmap failed %i\n");
			plugin->sharedMemoryBlock = NULL;
			close(plugin->sharedMemoryfd);
			shm_unlink(plugin->sharedMemoryName);
			*plugin->sharedMemoryName = 0x00;
			plugin->sharedMemoryfd = 0;
			return;
		}
	}

  DPRINT("NP: Thunder into fork\n");
  plugin->pid= fork();
  
  if (plugin->pid == -1) {
    perror("Squeak fork() failed");
    plugin->pid= 0;
    return;
  }
  DPRINT("NP: fork() -> %i\n", plugin->pid);
  if (plugin->pid == 0) {
    char tmp1[16], tmp2[16];
	sprintf(tmp1, "%i", plugin->pipes[SQUEAK_READ]);
    plugin->argv[3]= NPN_StrDup(tmp1);
    sprintf(tmp2, "%i", plugin->pipes[SQUEAK_WRITE]);
    plugin->argv[4]= NPN_StrDup(tmp2);
    DPRINT("NP(child): Running Squeak VM with arguments\n");
    {
      int i;
      for (i= 1; i<plugin->argc; i++)
		DPRINT("    %s\n", plugin->argv[i]);
    }
	plugin->argv[plugin->argc] = 0;
    execv(plugin->vmName, plugin->argv);
    /* npsqueakrun could not be executed either */
    fprintf(stderr, "Squeak Plugin: running \"%s\"\n", plugin->vmName);
    perror("Squeak execv() failed");
    _exit(1);
  } else {
  }
}


static void
SetWindow(SqueakPlugin *plugin,  NPWindow *window, int width, int height)
{
	NPRect    clipRect;
	clipRect = window->clipRect;
	
  DPRINT("NP: SetWindow(0x%X, %i@%i clip tlbr %i %i %i %i  v %i h %i)\n", window, width, height,
  clipRect.top,
  clipRect.left,
  clipRect.bottom,
  clipRect.right,
  window->y,
  window->x);

	/* New window */
	setWindowLogic(plugin,width,height);
}

static void setWindowLogic(SqueakPlugin *plugin, int width, int height) {
	int		totalBytes;
	CMProfileRef sysprof = NULL;
  
		// Get the Systems Profile for the main display
	if (plugin->colorspace == 0) {
		if (CMGetSystemProfile(&sysprof) == noErr) {
			// Create a colorspace with the systems profile
			plugin->colorspace = CGColorSpaceCreateWithPlatformColorSpace(sysprof);
			CMCloseProfile(sysprof);
		} else 
			plugin->colorspace = CGColorSpaceCreateDeviceRGB();
	}

	plugin->width = width > gWindowMaxLength ? gWindowMaxLength : width;
	plugin->height = height > gWindowMaxLength ? gWindowMaxLength : height;
	plugin->rowBytes = (plugin->width*4*8 + 7)/8;
	totalBytes = plugin->height*plugin->rowBytes;
						
	DPRINT("NP: setWindowLogic(width %i height %i rowbytes %i memory at id %i at %i)\n", plugin->width, plugin->height, plugin->rowBytes,plugin->sharedMemoryfd,plugin->sharedMemoryBlock);
	SendInt(plugin,CMD_SHARED_MEMORY);
	SendInt(plugin,plugin->sharedMemoryfd);
	SendInt(plugin,plugin->width);
	SendInt(plugin,plugin->height);
	SendInt(plugin,plugin->rowBytes);
}

static void 
browserProcessCommand(SqueakPlugin *plugin,int cmd)
{

  switch (cmd) {
  case CMD_GET_URL: 
    GetUrl(plugin);
    break;
  case CMD_SHARED_MEMORY: 
	break;
  case CMD_POST_URL: 
    PostUrl(plugin);
    break;
  case CMD_SET_CURSOR:
	{
		Receive(plugin, &plugin->macCursor, sizeof(Cursor));
		if (plugin->threadPleaseStop)
			return;
		plugin->customCursor = true;
		if (plugin->hasCursor) 
			SetCursor(&plugin->macCursor);
	}
	break;
  default:
    fprintf(stderr, "Unknown command from Squeak: %i\n", cmd);
  }
}


static const void *get_byte_pointer(void *bitmap)
{
    return (void *) bitmap;
}

static CGDataProviderDirectAccessCallbacks gProviderCallbacks = {
    get_byte_pointer,
    NULL,
    NULL,
    NULL
};

CG_EXTERN CGImageRef CGBitmapContextCreateImage(CGContextRef c) AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER;

void drawToScreenActual(SqueakPlugin *plugin,int top, int left, int bottom, int right);

void drawToScreen(SqueakPlugin *plugin) {
	int			 left,right,top,bottom;	
	
	if (plugin->sharedMemoryBlock == 0) 
		return;
		
	if (!plugin->sharedMemoryBlock->written)
		return;

	left = plugin->sharedMemoryBlock->left;
	right = plugin->sharedMemoryBlock->right;
	top = plugin->sharedMemoryBlock->top;
	bottom = plugin->sharedMemoryBlock->bottom;
	drawToScreenActual(plugin,top,left,bottom,right);
	
}

void drawToScreenActual(SqueakPlugin *plugin,int top, int left, int bottom, int right) {
	CGRect		 targetDrawArea,clipToWindowInterior;
	CGImageRef	 mySubimage;
	CGContextRef context,aBitMapContextRef;
	CGDataProviderRef provider;

	
	
	if (plugin->sharedMemoryBlock == 0) 
		return;
		
	if (!plugin->sharedMemoryBlock->written)
		return;

	DPRINT("NP: CMD_DRAW_CLIP(tlbr %i %i %i %i)\n", top, left, bottom, right);
	aBitMapContextRef = CGBitmapContextCreate(plugin->sharedMemoryBlock->screenBits+top*plugin->rowBytes+left*4,
		right-left, bottom-top,8,plugin->rowBytes,plugin->colorspace,kCGImageAlphaNoneSkipFirst);
	if (aBitMapContextRef == NULL) 
		return;
		
	if (CGBitmapContextCreateImage == NULL || true) {
		provider = CGDataProviderCreateDirectAccess(CGBitmapContextGetData(aBitMapContextRef),CGBitmapContextGetBytesPerRow(aBitMapContextRef)*CGBitmapContextGetHeight(aBitMapContextRef),&gProviderCallbacks);
		if(provider == NULL)
			return;
		mySubimage = CGImageCreate(CGBitmapContextGetWidth(aBitMapContextRef), CGBitmapContextGetHeight(aBitMapContextRef), 
					CGBitmapContextGetBitsPerComponent(aBitMapContextRef),
					CGBitmapContextGetBitsPerPixel(aBitMapContextRef), 
					CGBitmapContextGetBytesPerRow(aBitMapContextRef), plugin->colorspace, kCGImageAlphaNoneSkipFirst, provider, NULL, 0, kCGRenderingIntentDefault);
		CGDataProviderRelease(provider);
	} else {
		mySubimage = CGBitmapContextCreateImage(aBitMapContextRef);
	}

	CFRelease(aBitMapContextRef);
	if (mySubimage == NULL) 
		return;
	
	if (plugin->threadPleaseStop) return;
	QDBeginCGContext (plugin->display->port,&context);
	if (context == NULL) 
		return;
	
	GetPortBounds( plugin->display->port, &plugin->portRect );

	/* portRect on safari is always 0,0, but it's non-zero on FireFox
	also firefox *seems* to want "-2*plugin->portRect.top" to get clip right (sigh?) */

	/* First clip to window, based on x,y lower left */
	clipToWindowInterior = CGRectMake(plugin->portRect.left+plugin->clipRect.left,
			plugin->portRect.bottom-plugin->clipRect.bottom-plugin->portRect.top-plugin->portRect.top,
			plugin->clipRect.right-plugin->clipRect.left, plugin->clipRect.bottom-plugin->clipRect.top);

	if (plugin->threadPleaseStop) return;
	CGContextClipToRect(context, clipToWindowInterior);
	
	/* now change the the coordinate system as we figure out where to draw */ 
	
	if (plugin->threadPleaseStop) return;
	CGContextTranslateCTM(context, (float) 0-plugin->display->portx+plugin->portRect.left, 
		(float)(plugin->portRect.bottom - plugin->portRect.top)+plugin->display->porty-plugin->portRect.top);
	
	targetDrawArea = CGRectMake(left,0-bottom, right-left, bottom-top);
	
	if (plugin->threadPleaseStop) return;
	CGContextDrawImage(context, targetDrawArea, mySubimage);
	if (plugin->threadPleaseStop) return;
	CGContextFlush(context);
	if (plugin->threadPleaseStop) return;
	QDEndCGContext(plugin->display->port,&context);
	CFRelease(mySubimage);
	
	// Set written flag back to false so VM can continue, note VM does have 1 second timeout anyway */
	
	plugin->sharedMemoryBlock->written = 0;
	msync(plugin->sharedMemoryBlock,20,MS_SYNC);

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
    url= browser->memalloc(urlSize+1);
    Receive(plugin, url, urlSize);
    url[urlSize]= 0;
  } else url= NULL;
  /* Read target from pipe */
  Receive(plugin, &targetSize, 4);
  if (targetSize > 0) {
    target= browser->memalloc(targetSize+1);
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
	(SqueakStream*) browser->memalloc(sizeof(SqueakStream));
      if (!notifyData) { 
	fprintf(stderr, "Squeak Plugin (GetUrl): alloc failed\n");
      } else {
 	DPRINT("NP: NPN_GetURLNotify(%s, id=%i)\n", url, id);
 	notifyData->id= id;
 	notifyData->fname= NULL;
 	notifyData->fd= 0; 
	if (plugin->threadPleaseStop) return;
	NPN_GetURLNotify(plugin->instance, url, target, notifyData);
      }
    }
  }

  if (url) browser->memfree(url);
  if (target) browser->memfree(target);
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
    url= browser->memalloc(urlSize+1);
    Receive(plugin, url, urlSize);
    url[urlSize]= 0;
  } else url= NULL;
  /* Read target from pipe */
  Receive(plugin, &targetSize, 4);
  if (targetSize > 0) {
    target= browser->memalloc(targetSize+1);
    Receive(plugin, target, targetSize);
    target[targetSize]= 0;
  } else target= NULL;
  /* Read post data from pipe */
  Receive(plugin, &dataSize, 4);
  if (dataSize > 0) {
    data= browser->memalloc(dataSize);
    Receive(plugin, data, dataSize);
  } else data= NULL;

  if (errno) {
    perror("Squeak Plugin (PostUrl)");
  } else {
    SqueakStream* notifyData= 
      (SqueakStream*) browser->memalloc(sizeof(SqueakStream));
    if (!notifyData) { 
      fprintf(stderr, "Squeak Plugin (PostUrl): alloc failed\n");
    } else {
      DPRINT("NP: NPN_PostURLNotify(%s, id=%i)\n", url, id);
      notifyData->id= id;
	  if (plugin->threadPleaseStop) return;
      NPN_PostURLNotify(plugin->instance, url, target, 
			dataSize, data, FALSE, notifyData);
    }
  }

  if (url) browser->memfree(url);
  if (target) browser->memfree(target);
  if (data) browser->memfree(data);
}

int16 Mac_NPP_HandleEvent(NPP instance, void *rawEvent);

int16 NPP_HandleEvent(NPP instance, void *rawEvent) {
	return Mac_NPP_HandleEvent(instance,rawEvent);
}

int16 Mac_NPP_HandleEvent(NPP instance, void *rawEvent) 
{
	EventRecord *eventPtr = (EventRecord*) rawEvent;
	SqueakPlugin *plugin= (SqueakPlugin*) instance->pdata;
	Point zot,prezot;
	int	handled=0;
	
	if (plugin->pid == 0) return 0;	
	if (eventPtr == NULL) return false;

	SetOrigin(plugin->display->portx, plugin->display->porty);
	//QDGlobalToLocalPoint(plugin->display->port,(Point *) &eventPtr->where);
	prezot = eventPtr->where;
	zot.v = 0;
	zot.h = 0;
	QDGlobalToLocalPoint(plugin->display->port,&zot);
	eventPtr->where.v = eventPtr->where.v  + zot.v; // -  plugin->display->porty;
	eventPtr->where.h = eventPtr->where.h  + zot.h; // -  plugin->display->portx;
	
	if (!(eventPtr->what == nullEvent)) {
		 DPRINT("NP: handelEventL %i where v %i h %i, modifiers %i plugin-cliprect v %i h %i  portxy v %i h %i\n",
		 eventPtr->what,eventPtr->where.v,eventPtr->where.h,eventPtr->modifiers,
		 plugin->clipRect.top,plugin->clipRect.left, 
		 plugin->display->porty,plugin->display->portx);
		 handled = 1;
	}
	if (eventPtr->what == mouseUp) {
		plugin->buttonIsDown = false;
		handled = 1;
	}
		
	if (eventPtr->what == mouseDown) {
		plugin->buttonIsDown = true;
		 DPRINT("NP: handelEventL cmd %i option %i control %i shift %i\n",eventPtr->modifiers & cmdKey, 
		 eventPtr->modifiers & optionKey, 
		 eventPtr->modifiers & controlKey, 
		 eventPtr->modifiers & shiftKey);
		handled = 1;
	}

	if (eventPtr->what == nullEvent)
		eventPtr->modifiers = checkForModifierKeys(plugin);
		
	if (eventPtr->what == activateEvt) {
		DPRINT("NP: handelEventL activate\n %i %i",eventPtr->message,eventPtr->modifiers & activeFlag);
		if (eventPtr->modifiers & activeFlag) {
		}
		return 1;
	}
	if (eventPtr->what == updateEvt) {
		/* Draw the entire screen, don't ask VM, that is too slow */
		 WindowPtr window;
		 RgnHandle clip;
		 Rect clipRect;
		 GrafPtr  oldPort;
		 
		 
		 window = (WindowPtr)eventPtr->message;
		 BeginUpdate( window );

		 GetPort(&oldPort);
		 SetPort(GetWindowPort(window));
		 
		 clip = NewRgn();
		 GetClip(clip);
		 GetRegionBounds(clip,&clipRect);
		 
		pthread_mutex_lock(&plugin->readPipeMutex);
		plugin->sharedMemoryBlock->written = 1;
		/* if (clipRect.top == 0 && clipRect.left == 0 && clipRect.bottom == 0 && clipRect.right == 0) {
			clipRect.top = 0;
			clipRect.left = 0;
			clipRect.bottom = plugin->height;
			clipRect.right = plugin->width;
			ClipRect(&clipRect);
		 } */
		 drawToScreenActual(plugin,clipRect.top,clipRect.left,clipRect.bottom, clipRect.right);
		 pthread_mutex_unlock(&plugin->readPipeMutex);
		 
		 EndUpdate( window );
		 DisposeRgn(clip);
		 SetPort(oldPort);
		 DPRINT("NP: handelEventL update (clip tlbr %i %i %i %i) \n", clipRect.top,clipRect.left,clipRect.bottom, clipRect.right);
		handled = 1;
	}
	
	if (eventPtr->what == getFocusEvent) {}
	if (eventPtr->what == loseFocusEvent) {}
	if (eventPtr->what == adjustCursorEvent) {
		plugin->hasCursor = eventPtr->modifiers;
		if (eventPtr->modifiers) {
			if (plugin->customCursor)
				SetCursor(&plugin->macCursor);
		} else {
			InitCursor();
		}
		 DPRINT("NP: adjust cursor  %i\n",plugin->hasCursor);
		return 1;
	}
	
	if (eventPtr->what == keyDown) {
		handled = 1;
	}
	if (eventPtr->what == keyUp) {
		handled = 1;
	}
	if (eventPtr->what == autoKey) {
		handled = 1;
	}
	
	SendInt(plugin, CMD_EVENT);
	Send(plugin, rawEvent, sizeof(struct EventRecord));
	return 	handled;  // 
}


NPError
NPN_GetURL(NPP instance, const char* url, const char* window)
{
	return browser->geturl( instance, url, window);
}

NPError
NPN_GetURLNotify(NPP instance, const char* url, const char* window, void* notifyData)
{
	int navMinorVers = browser->version & 0xFF;
	if (navMinorVers < NPVERS_HAS_NOTIFICATION)
	  return NPERR_INCOMPATIBLE_VERSION_ERROR;
	return browser->geturlnotify (instance, url, window, notifyData);
}

NPError
NPN_PostURL(NPP instance, const char* url, const char* window,
	     uint32 len, const char* buf, NPBool file)
{
	return browser->posturl (instance,
					url, window, len, buf, file);
}

NPError
NPN_PostURLNotify(NPP instance, const char* url, const char* window,
	     uint32 len, const char* buf, NPBool file, void* notifyData)
{
	int navMinorVers = browser->version & 0xFF;
	if (navMinorVers < NPVERS_HAS_NOTIFICATION)
	  return NPERR_INCOMPATIBLE_VERSION_ERROR;
	return browser->posturlnotify (instance,
					 url, window, len, buf, file, notifyData);
}

int checkForModifierKeys(SqueakPlugin *plugin) {
	enum {
			/* modifier keys */
		kVirtualCapsLockKey = 0x039,
		kVirtualShiftKey = 0x038,
		kVirtualControlKey = 0x03B,
		kVirtualOptionKey = 0x03A,
		kVirtualRShiftKey = 0x03C,
		kVirtualRControlKey = 0x03E,
		kVirtualROptionKey = 0x03D,
		kVirtualCommandKey = 0x037
	};
	KeyMap theKeys;
	unsigned char *keybytes;
	int result;
	
	GetKeys(theKeys);
	keybytes = (unsigned char *) theKeys;
	result  = plugin->buttonIsDown ?  0 : btnState ;
	result += ((keybytes[kVirtualCapsLockKey>>3] & (1 << (kVirtualCapsLockKey&7))) != 0) ? alphaLock : 0;
	result += ((keybytes[kVirtualShiftKey>>3] & (1 << (kVirtualShiftKey&7))) != 0)       ? shiftKey : 0;
	result += ((keybytes[kVirtualControlKey>>3] & (1 << (kVirtualControlKey&7))) != 0)   ? controlKey : 0;
	result += ((keybytes[kVirtualOptionKey>>3] & (1 << (kVirtualOptionKey&7))) != 0)     ? optionKey : 0;
	result += ((keybytes[kVirtualRShiftKey>>3] & (1 << (kVirtualRShiftKey&7))) != 0)       ? shiftKey : 0;
	result += ((keybytes[kVirtualRControlKey>>3] & (1 << (kVirtualRControlKey&7))) != 0)   ? controlKey : 0;
	result += ((keybytes[kVirtualROptionKey>>3] & (1 << (kVirtualROptionKey&7))) != 0)     ? optionKey : 0;
	result += ((keybytes[kVirtualCommandKey>>3] & (1 << (kVirtualCommandKey&7))) != 0)   ? cmdKey : 0;
	
	return result;
}

