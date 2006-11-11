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
#include <sys/shm.h>
#include "sqaio.h"


#define DEBUG 

#if defined (DEBUG)
static void DPRINT(char *format, ...)
{
  static int debug= 43;
  
  if (42 == debug) 
    debug= (NULL != getenv("NPSQUEAK_DEBUG"));
  
  if (!debug) 
    {
      return;
    }
  else
    {
      {
	va_list ap;
	va_start(ap, format);
	vfprintf(stderr, format, ap);
	va_end(ap);
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
#define CMD_SHARED_MEMORY  5
#define CMD_DRAW_CLIP	   6
#define CMD_EVENT		   7
#define CMD_SET_CURSOR	   8

#define MAX_STREAMS 128

#define SQUEAK_READ  0
#define PLUGIN_WRITE 1
#define PLUGIN_READ  2
#define SQUEAK_WRITE 3
extern NPNetscapeFuncs* browser;

/* plugin state */
typedef struct SqueakPlugin {
  NPP instance;                    /* plugin instance */
  pid_t pid;                       /* the child process pid */
  NP_Port	*display;
  void		*sharedMemoryBlock;                 /* the Squeak window */
  int		sharedMemID;
  CGContextRef sharedBrowserBitMapContextRef;
  CGContextRef context;
  int		width;
  int		height;
  NPRect    clipRect;    /* Clipping rectangle in port coordinates */
  Rect		portRect;
  Boolean embedded;                   /* false if we have the whole window */
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
   int id;                          /* request id (-1 if finished)  */
   char *fname;                     /* file name when streaming */
   int fd;                          /* file descriptor when streaming */
} SqueakStream;

static struct timeval	 startUpTime;

/***********************************************************************
 * Prototypes
 ***********************************************************************/

static void DeliverFile(SqueakPlugin *, int id, const char* fname);
static void SetWindow(SqueakPlugin*,  NPWindow *window, int width, int height);
static void SetUpSqueakWindow(SqueakPlugin*);
static void Run(SqueakPlugin*);
static void GetUrl(SqueakPlugin*);
static void PostUrl(SqueakPlugin*);
static void browserProcessCommand(SqueakPlugin *plugin);
void setWindowLogic(SqueakPlugin *plugin, int width, int height);


static char* NPN_StrDup(const char* s)
{
  return strcpy(browser->memalloc(strlen(s) + 1), s);
}

/*
 * NP_GetMIMEDescription
 *	- Netscape needs to know about this symbol
 *	- Netscape uses the return value to identify when an object instance
 *	  of this plugin should be created.
 */
char * NPP_GetMIMEDescription(void);
#pragma export on
char *
NP_GetMIMEDescription(void);
#pragma export off
char *
NP_GetMIMEDescription(void)
{
	return NPP_GetMIMEDescription();
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
  strcpy(imagename, "SqueakPlugin.image"); 

  plugin->instance=    instance;
  plugin->pid=         0;
  plugin->sharedMemoryBlock=    0;
  plugin->sharedMemID= 0;
  plugin->sharedBrowserBitMapContextRef = 0;
  plugin->context = 0;
  plugin->display=     NULL;
  plugin->embedded=    (mode == NP_EMBED);
  plugin->srcUrl=      NULL;
  plugin->srcFilename= NULL;
  plugin->srcId=       -1;
  plugin->failureUrl=  0;
  plugin->argv[0]=     NPN_StrDup("squeakvm");
  plugin->argv[1]=     NPN_StrDup("-headfull");
  plugin->argv[2]=     NPN_StrDup("-browserPipes");
  plugin->argv[3]=     NULL;             /* inserted later */
  plugin->argv[4]=     NULL;             /* inserted later */
  plugin->argv[5]=     NULL;             /* inserted later */
  plugin->argv[6]=     NPN_StrDup("");   /* empty document file on cmdline! */ 
  plugin->argc=        7;

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
			"/Users/johnmci/Documents/Squeak3.8.0/build/Development/Squeak VM Opt.app/Contents/MacOS/",
			"/Applications/SqueakLand/Squeak/Internet/Squeak VM Opt.app/Contents/MacOS/"};
		if (findFileInPaths(plugin->vmName, "Squeak VM Opt", 3 , bin_dir_v) == 0){
		  fprintf(stderr, "Squeak Plugin: VM not found!\n");
		  return NPERR_GENERIC_ERROR;
		} else {
			plugin->argv[0]= NPN_StrDup(plugin->vmName); 
		}
      }

	{
		char* img_dir_v[PATH_MAX]= {user_img_dir,"/Applications/SqueakLand/Squeak/Internet/" };
		if (findFileInPaths(plugin->imageName, imagename, 2, img_dir_v) == 0){
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
  return NPERR_NO_ERROR;
}

NPError 
NPP_Destroy(NPP instance, NPSavedData** save)
{
  SqueakPlugin *plugin;
  struct shmid_ds	SharedMemDS;
  
  DPRINT("NP: NPP_Destroy\n");
  if (!instance)
    return NPERR_INVALID_INSTANCE_ERROR;
  plugin= (SqueakPlugin*) instance->pdata;
  if (plugin) {
    int i;
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

	shmdt(plugin->sharedMemoryBlock);
	shmctl(plugin->sharedMemID,IPC_STAT,&SharedMemDS);
	shmctl(plugin->sharedMemID,IPC_RMID,NULL);             //remove the segment so the key  and memory can be reused
	DPRINT("NP: destroy memory ID %i at %i \n", plugin->sharedMemID,plugin->sharedMemoryBlock);

    browser->memfree(plugin);
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
    plugin->display= pNPWindow->window;
  }
  if (!plugin->pid)
    Run(plugin);
  plugin->clipRect = pNPWindow->clipRect;
  SetWindow(plugin, pNPWindow->window, pNPWindow->width, pNPWindow->height);
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
		char			pathName[4096],lname[4096];
  SqueakPlugin *plugin= (SqueakPlugin*) instance->pdata;

  DPRINT("NP: StreamAsFile(%s, id=%i)\n", stream->url, id);
  DPRINT("NP:   fname=%s\n", fname ? fname : "<NULL>");

  pathName[0] = 0x00;
  if (!plugin || !fname) return;

	filePath   = CFStringCreateWithBytes(kCFAllocatorDefault,(const UInt8 *)fname,strlen(fname),kCFStringEncodingMacRoman,false);
	sillyThing = CFURLCreateWithFileSystemPath (kCFAllocatorDefault,filePath,kCFURLHFSPathStyle,false);
	CFRelease(filePath);
	filePath = CFURLCopyFileSystemPath (sillyThing, kCFURLPOSIXPathStyle);
	CFRelease(sillyThing);
	CFStringGetCString (filePath, pathName,4096, kCFStringEncodingUTF8);
	CFRelease(filePath);
  
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
  if (count == 44444) 
	DPRINT("NP: Read 4 bytes %i\n",*(int*)buf);
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
  } while (n == -1 && (errno == EINTR  || errno == EAGAIN));
  if (count == 44444) 
	DPRINT("NP: Send 4 bytes %i\n",*(int*)buf);
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
	DPRINT("NP:   Send RECEIVE_DATA id=%i ok=%i\n", id, ok);
 
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

static void npHandler(int fd, void *data, int flags)
{
  SqueakPlugin *plugin = (SqueakPlugin *) data;
  browserProcessCommand(plugin);
  aioHandle(plugin->pipes[PLUGIN_READ], npHandler, AIO_RX);
  aioPoll(0);

}

void forceInterruptCheck(int ignore) {};

static void 
Run(SqueakPlugin *plugin)
{
  if (plugin->pid || !plugin->srcUrl ||plugin->failureUrl)
    return;
	
	DPRINT("NP: Setup aio logic \n");
	gettimeofday(&startUpTime, 0);

	aioEnable(plugin->pipes[PLUGIN_READ], plugin, AIO_EXT); 
	aioHandle(plugin->pipes[PLUGIN_READ], npHandler, AIO_RX);

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
	
  DPRINT("NP: SetWindow(0x%X, %i@%i tlbr %i %i %i %i)\n", window, width, height,
  clipRect.top,
  clipRect.left,
  clipRect.bottom,
  clipRect.right);

	/* New window */
	setWindowLogic(plugin,width,height);
}

void setWindowLogic(SqueakPlugin *plugin, int width, int height) {
	int rowBytes,totalBytes;
	CGColorSpaceRef colorspace;
  
  {
		// Get the Systems Profile for the main display
	CMProfileRef sysprof = NULL;
	if (CMGetSystemProfile(&sysprof) == noErr) {
		// Create a colorspace with the systems profile
		colorspace = CGColorSpaceCreateWithPlatformColorSpace(sysprof);
		CMCloseProfile(sysprof);
	} else 
		colorspace = CGColorSpaceCreateDeviceRGB();
  }

	rowBytes = (((((width * 32) + 31) / 32) * 4) & 0x1FFF);
	totalBytes = height*rowBytes;
					
	if (plugin->sharedMemID) {
		struct shmid_ds	SharedMemDS;
		shmdt(plugin->sharedMemoryBlock);
		shmctl(plugin->sharedMemID,IPC_STAT,&SharedMemDS);
		DPRINT("NP: setWindowLogic delete memory ID %i at %i \n", plugin->sharedMemID,plugin->sharedMemoryBlock);
	}
	plugin->sharedMemID=shmget(47382+plugin->pid,totalBytes,IPC_CREAT | 0666); 
	
	plugin->sharedMemoryBlock=shmat(plugin->sharedMemID,0,0666);
	if (plugin->sharedMemoryBlock == (void*) -1) {
		DPRINT("NP: setWindowLogic shmat failed\n");
			return;
	}
	
	plugin->width = width;
	plugin->height = height;
	DPRINT("NP: setWindowLogic(width %i height %i rowbytes %i memory at id %i at %i)\n", width, height, rowBytes,plugin->sharedMemID,plugin->sharedMemoryBlock);
	SendInt(plugin,CMD_SHARED_MEMORY);
	SendInt(plugin,plugin->sharedMemID);
	SendInt(plugin,width);
	SendInt(plugin,height);
	SendInt(plugin,rowBytes);
	if (plugin->context)
		CFRelease(plugin->context);
	plugin->context = NULL;
	if (plugin->sharedBrowserBitMapContextRef)
		CFRelease(plugin->sharedBrowserBitMapContextRef);
	plugin->sharedBrowserBitMapContextRef = NULL;
	plugin->sharedBrowserBitMapContextRef = CGBitmapContextCreate (plugin->sharedMemoryBlock,width,height,8,rowBytes,colorspace,kCGImageAlphaNoneSkipFirst);
	CreateCGContextForPort(plugin->display->port,&plugin->context); 
	
	//  Adjust for any SetOrigin calls on qdPort
    SyncCGContextOriginWithPort( plugin->context, plugin->display->port );

    //  Move the CG origin to the upper left of the port
    GetPortBounds( plugin->display->port, &plugin->portRect );

    CGContextTranslateCTM( plugin->context, 0, (float)(plugin->portRect.bottom - plugin->portRect.top) );
	{	
		CGRect	clip2;
		clip2 = CGRectMake(plugin->portRect.left,plugin->portRect.top,plugin->portRect.right-plugin->portRect.left, plugin->portRect.bottom-plugin->portRect.top);
		CGContextClipToRect(plugin->sharedBrowserBitMapContextRef, clip2);
	}

    DPRINT("NP: NewContext %i\n",  plugin->sharedBrowserBitMapContextRef);
    	
}

static void 
browserProcessCommand(SqueakPlugin *plugin)
{
  int cmd;

  Receive(plugin, &cmd, 4);
  switch (cmd) {
  case CMD_GET_URL: 
    GetUrl(plugin);
    break;
  case CMD_SHARED_MEMORY: 
      {
		  /* setup shared memory*/
		  struct shmid_ds SharedMemDS;
		  int sharedMemID;
			
		  Receive(plugin, &sharedMemID, 4);
		  shmctl(sharedMemID,IPC_STAT,&SharedMemDS);
		  DPRINT("NP: CMD_SHARED_MEMORY drop existing with id %i \n",sharedMemID);
		  if (SharedMemDS.shm_nattch==0) {
			shmctl(plugin->sharedMemID,IPC_RMID,NULL);  
			DPRINT("NP: CMD_SHARED_MEMORY destroy memory id %i \n",sharedMemID);
		}
	  }
      break;
  case CMD_DRAW_CLIP:
		{
			int left,right,top,bottom;
			CGImageRef myImage,mySubimage;
			CGRect		imageclip,targetclip;
			
			Receive(plugin, &left, 4);
			Receive(plugin, &right, 4);
			Receive(plugin, &top, 4);
			Receive(plugin, &bottom, 4);

			//DPRINT("NP: CMD_DRAW_CLIP(tlbr %i %i %i %i)\n", top, left, bottom, right);
  
			imageclip = CGRectMake(left,top, right-left, bottom-top);
			targetclip = CGRectMake(left,(0-plugin->height)+(plugin->height-bottom), right-left, bottom-top);

			if (plugin->sharedBrowserBitMapContextRef == NULL)
				return;
			myImage = CGBitmapContextCreateImage(plugin->sharedBrowserBitMapContextRef);
			if (myImage == NULL) 
				return;
					
			mySubimage = CGImageCreateWithImageInRect (myImage, imageclip); 

			CGContextDrawImage(plugin->context, targetclip, mySubimage);
			CGContextFlush(plugin->context);
			CFRelease(myImage);
			if (mySubimage)
				CFRelease(mySubimage);
		}

		break;
  case CMD_POST_URL: 
    PostUrl(plugin);
    break;
  case CMD_SET_CURSOR:
	{
		Cursor macCursor;
		Receive(plugin, &macCursor, sizeof(Cursor));
		SetCursor(&macCursor);
	}
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

int gButtonIsDown;

int16 Mac_NPP_HandleEvent(NPP instance, void *rawEvent) 
{
	EventRecord *eventPtr = (EventRecord*) rawEvent;
	SqueakPlugin *plugin= (SqueakPlugin*) instance->pdata;
	CGrafPtr   port;
	GetPort(&port);
	  
	aioPoll(0);
 
	if (plugin->pid == 0) return 0;
	
	if (eventPtr == NULL) return false;

	QDGlobalToLocalPoint(port,(Point *) &eventPtr->where);

	if (!(eventPtr->what == 0)) {
		 DPRINT("NP: handelEventL %i where v %i h %i, modifiers %i\n",eventPtr->what,eventPtr->where.v,eventPtr->where.h,eventPtr->modifiers);
	}
	if (eventPtr->what == mouseUp)
		gButtonIsDown = false;
		
	if (eventPtr->what == mouseDown)
		gButtonIsDown = true;

	if (eventPtr->what == nullEvent)
		eventPtr->modifiers = checkForModifierKeys();
		
	SendInt(plugin, CMD_EVENT);
	Send(plugin, rawEvent, sizeof(struct EventRecord));
	return 1;
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

int ioMicroMSecs(void)
{
  struct timeval now;
  gettimeofday(&now, 0);
  if ((now.tv_usec-= startUpTime.tv_usec) < 0) {
    now.tv_usec+= 1000000;
    now.tv_sec-= 1;
  }
  now.tv_sec-= startUpTime.tv_sec;
  return (now.tv_usec / 1000 + now.tv_sec * 1000);
}


int ioMSecs() {
    return ioMicroMSecs();
}


int checkForModifierKeys() {
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
	result  = gButtonIsDown ?  0 : btnState ;
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

