//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// This is the big one - sqRPCMain.c
// This is where it all starts - see main().

// define this to get lots of debug notifiers
//#define DEBUG

#include "oslib/os.h"
#include "oslib/osbyte.h"
#include "oslib/osfscontrol.h"
#include "oslib/wimp.h"
#include "oslib/wimpspriteop.h"
#include "oslib/colourtrans.h"
#include "oslib/territory.h"
#include "sq.h"
#include "sqArguments.h"
#include <kernel.h>
#include <stdarg.h>


/*** Variables -- Imported from Virtual Machine ***/

/*** Variables -- image and path names ***/
char			imageName[MAXDIRNAMELENGTH]; /* full path to image */
char			vmPath[MAXDIRNAMELENGTH]; /* full path to interpreter's directory */

/*** Variables -- RPC Related ***/
char			sqTaskName[10] = "Squeak\0\0\0\0";
int				sqTaskNameLength = 10;
wimp_t			Task_Handle;
char validationString[] = "Siconbar";

os_dynamic_area_no	SqueakObjectSpaceDA;
extern os_dynamic_area_no	SqueakDisplayDA;
wimp_MESSAGE_LIST(8)	importantWimpMessages;
wimp_version_no		actualOSLevel;
os_error		privateErr;
char			versionString[20];
static			FILE *logfile= 0;
static			unsigned int *timerValPtr;

/* argument handling stuff  -- see c.sqArgument */
int 			numOptionsVM;
char			*(vmOptions[MAX_OPTIONS]);
int 			numOptionsImage;
char			*(imageOptions[MAX_OPTIONS]);

int				headlessFlag = 0;
int				helpMe = 0;
int				versionMe = 0;
int				swapMeta = 0;
int				objectHeadroom = 4*1024*1024;
char			*windowLabel, *taskNameArg;
int				useDAMemory = 0;

vmArg args[] = {
		{ ARG_FLAG,   &headlessFlag, "-headless" },
		{ ARG_FLAG,   &helpMe, "-help" },
		{ ARG_FLAG,   &versionMe, "-version" },
		{ ARG_FLAG,   &useDAMemory, "-useDA" },
		{ ARG_FLAG,   &swapMeta,  "-swapmeta"},
		{ ARG_UINT,   &objectHeadroom, "-memory:"},
		{ ARG_STRING, &windowLabel, "-windowlabel:"},
		{ ARG_STRING, &taskNameArg, "-taskname:"},
		{ ARG_NONE, NULL, NULL }
	};

/*** Functions ***/
extern void		SetupPaletteTable(void);
extern void		setFPStatus(int stat);

int openLogStream(void) {
	if ((int)logfile < 0) {
		/* negative num means we couldn't open !reporter or any logfile
		 * so don't log stuff */
		return 0;
	}
	if (!logfile) {
		/* try to open fake file Report: for the !Reporter logging */
		logfile= fopen("Report:", "w+");
	}
	if (!logfile) {
		/* No Report: so try an ordinary log file */
		#define LogName "Squeak/vmlog\0"
		char *logPath;
		logPath = (char*)malloc(strlen(vmPath) + strlen(LogName) + 2);
		if (logPath == NULL) {
			logfile = (FILE *)-1;
			return 0;
		}
		sprintf(logPath, "%s^.%s", vmPath, LogName);
		logfile= fopen(logPath, "a+");
		free(logPath);
	}
	if (!logfile) {
		/* if still no file handle, we stop trying and
		 * set file to -1 as a flag */
		logfile = (FILE *)-1;
		return 0;
	}
	return (int)logfile;
}
/* override printf()
 * - see also the #define printf repprintf in sqPlatforSpecific.h
 */
int repprintf(const char * format, ...) {
int charsPrinted;
va_list ap;
	if (!openLogStream()) return 0;
	va_start(ap, format);
	charsPrinted = vfprintf(logfile, format, ap);
	va_end(ap);
	fflush(logfile);

	return charsPrinted;
}

/* also deal with fprintf in the same manner. Ignore the stream specified */
int repfprintf(FILE *strm, const char * format, ...) {
int charsPrinted;
va_list ap;
	if (!openLogStream()) return 0;
	va_start(ap, format);
	charsPrinted = vfprintf(logfile, format, ap);
	va_end(ap);
	fflush(logfile);

	return charsPrinted;
}

/*** RPC-related Functions ***/
void platReportError( os_error * e) {
/* Use the RiscOS Error dialogue to notify users of some problem */
	wimp_report_error( e, wimp_ERROR_BOX_CANCEL_ICON |
		 wimp_ERROR_BOX_HIGHLIGHT_CANCEL |
		 wimp_ERROR_BOX_SHORT_TITLE ,
		 sqTaskName);
}


void platReportFatalError( os_error * e) {
/* Report an error considered fatal */
	PRINTF(("\\t Fatal Error: %s\n", e->errmess));
	platReportError(e);
	exit(e->errnum);
}

char*rinkMalloc(size_t size) {
        PRINTF(("\\t rink alloc %d\n", (int)size));
	return malloc(size);
}

int platAllocateMemory( int amount) {
os_error * e;
int daSizeLimit, daSize;
byte * daBaseAddress;

	PRINTF(("\\t platAllocateMemory requesting: %08x\n", amount));
	/* work out the size of dynamic area allowed to see if we can use a large
	 * application space allocation. On RISC OS 4 or if Aemulor is running
	 * on RISC OS 5, we can't. We also have the -useDA cmdline flag */
	if ((e = xos_read_dynamic_area(
				os_DYNAMIC_AREA_APPLICATION_SPACE,
				&daBaseAddress,
				&daSize,
				&daSizeLimit
			)) != NULL) {
		platReportFatalError(e);
		return false;
	}
 	PRINTF(("\\t platAllocateMemory DA size check: %08x @ %08x\n", (int)daSizeLimit, (int)daBaseAddress));

	if (useDAMemory || (daSizeLimit <= 0x1BF8000) ) {
		/* RISC OS 4 or Aemulor is preventing a large application slot,
		 * or useDAMemory is set, so use a DA instead */
		if ((e = xosdynamicarea_create (
					os_DYNAMIC_AREA_APPLICATION_SPACE,
					amount,
					(byte const*)-1,
					(bits)128,
					-1,
					NULL,
					NULL,
					"Squeak ObjectSpace",
					&SqueakObjectSpaceDA,
					&daBaseAddress,
					&daSizeLimit
				)) !=NULL) {
			platReportFatalError(e);
			return false;
		};
		PRINTF(("\\t platAllocateMemory DA \n"));
	} else {
		/* Looks like we can use a large application slot so
		 * just malloc the memory */
		daBaseAddress = malloc(amount);
		if ( daBaseAddress == NULL) {
			privateErr.errnum = 0;
			sprintf(privateErr.errmess, "Unable to allocate Object Memory\n");
			platReportFatalError(&privateErr);
			return false;
		}
	}

	PRINTF(("\\t platAllocateMemory(%d) at %0x\n", amount, (int)daBaseAddress));

	return (int)daBaseAddress;
}


void setTimer(void) {
/* Initialise the MillisecondTimer value address
*/
_kernel_swi_regs regs;
	_kernel_swi(/* MillisecondTimer_Val_Ptr*/ 0x58101, &regs, &regs);
	timerValPtr = (unsigned int *)(regs.r[0]);
}


int InitRiscOS(void) {
/* Initialise RiscOS for desktop wimp program use */
os_error * e;
extern  wimp_icon_create sqIconBarIcon;
extern void		GetDisplayParameters(void);
extern void		SetupWindowTitle(void);
extern void		SetDefaultPointer(void);
extern void		InitRootWindow(void);
extern void		initialiseSoundPollword(void);

	SetDefaultPointer();
	importantWimpMessages.messages[0] = message_MODE_CHANGE;
	importantWimpMessages.messages[1] = message_CLAIM_ENTITY;
	importantWimpMessages.messages[2] = message_DATA_REQUEST;
	importantWimpMessages.messages[3] = message_DATA_SAVE;
	importantWimpMessages.messages[4] = message_DATA_LOAD;
	importantWimpMessages.messages[5] = message_DATA_SAVE_ACK;
	importantWimpMessages.messages[6] = message_WINDOW_INFO;

/* set the taskname */
	if ( taskNameArg != NULL){
		strncpy(sqTaskName, taskNameArg, sqTaskNameLength );
	}

	if ((e = xwimp_initialise (wimp_VERSION_RO38,
					sqTaskName,
					(wimp_message_list*)&importantWimpMessages,
					&actualOSLevel,
					&Task_Handle)) != NULL) {
		platReportFatalError( e);
		return false;
	}
	SqueakDisplayDA =SqueakObjectSpaceDA = (os_dynamic_area_no)NULL;

/* strictly speaking we need to find the width of the chosen icon and give
 * wimp_creat_icon the larger of that and width (below). Oh and respond
 * to the message Message_FontChanged by recalculating it and using
 * wimp_resize_icon(wimp_ICON_BAR, icon id, x/y, x/y). */
	sqIconBarIcon.w = wimp_ICON_BAR_RIGHT;
	sqIconBarIcon.icon.extent.x0 = 0;
	sqIconBarIcon.icon.extent.y0 = -16;
	sqIconBarIcon.icon.extent.x1 = wimptextop_string_width(sqTaskName, 0);
	sqIconBarIcon.icon.extent.y1 = 84;
	sqIconBarIcon.icon.flags =
			wimp_ICON_INDIRECTED
			| wimp_ICON_TEXT
			| wimp_ICON_SPRITE
			| wimp_ICON_HCENTRED
			| 0x17000000   /* colour flags */
			| (wimp_BUTTON_CLICK
				<<wimp_ICON_BUTTON_TYPE_SHIFT ) ;
	sqIconBarIcon.icon.data.indirected_text_and_sprite.text = sqTaskName;
	sqIconBarIcon.icon.data.indirected_text_and_sprite.validation =
		validationString;  /* NB validation string has to be a global, not local to initRiscOS ! */
	sqIconBarIcon.icon.data.indirected_text_and_sprite.size =
		strlen(validationString);

	wimp_create_icon(&sqIconBarIcon);

	SetupPaletteTable();
	GetDisplayParameters();
	InitRootWindow();
	SetupWindowTitle();

	setFPStatus(0);
	setTimer();
	initialiseSoundPollword();

	return true;
}

/*** I/O Primitives ***/

sqInt ioBeep(void) {
	os_writec((char)7);
	return true;
}

sqInt ioExit(void) {
	exit(1);
	return 1;
}

int ioAssertion(void) {
	return 1;
}

void exit_function(void) {
/* do we need to do any special tidy up here ? RiscOS needs to kill the
   pointer bitmap and release the dynamic areas
*/
extern void ioShutdownAllModules(void);
extern void SetDefaultPointer(void);
extern void shutdownSoundPollword(void);

	ioShutdownAllModules();

	SetDefaultPointer();
	if (SqueakObjectSpaceDA != (os_dynamic_area_no)NULL)
		xosdynamicarea_delete ( SqueakObjectSpaceDA );
	if (SqueakDisplayDA != (os_dynamic_area_no)NULL)
		xosdynamicarea_delete ( SqueakDisplayDA );
	PRINTF(("\\t exiting Squeak\n"));
	if ( (int)logfile > 0) fclose( logfile);
	shutdownSoundPollword();
}

usqInt millisecondTimerValue(void) {
/* return the raw unsigned value of the millsecond time for internal VM use */
	return (usqInt)*timerValPtr;
}

unsigned int microsecondsvalue(void) {
/* return the microsecond value (ignoring wrap arounds etc) for debug timer
 * purposes. We may consider trying a real uSec timer sometime
 */
	return 1000 * millisecondTimerValue();
}

sqInt ioMicroMSecs(void) {
/* The
   function ioMicroMSecs() is used only to collect timing statistics
   for the garbage collector and other VM facilities. (The function
   name is meant to suggest that the function is based on a clock
   with microsecond accuracy, even though the times it returns are
   in units of milliseconds.) This clock must have enough precision to
   provide accurate timings, and normally isn't called frequently
   enough to slow down the VM. Thus, it can use a more expensive clock
   that ioMSecs().
   This has to be a separate function because it is involved in the
   function table in sqVirtualMachine.c
*/
	return millisecondTimerValue();

}

sqInt ioSeconds(void) {
/*	  Unix epoch to Smalltalk epoch conversion.
	(Date newDay: 1 year: 1970) asSeconds
			- (Date newDay: 1 year: 1901) asSeconds
	is
			2177452800
	limit is about 2057ad - this may cause problems...
	Add the timezone offset in seconds; this seems to be a change from
	log practice, no idea how it wasn't already needed.
*/
char * tzName;
int tzOffset;
	xterritory_read_current_time_zone( &tzName, &tzOffset);
	return  (int)((unsigned long)time(NULL) + 2177452800uL + (tzOffset/100));
}

/*** Image File Naming ***/

void setDefaultImageName(void) {
#define DefImName "Squeak/image\0"
	sprintf(imageName, "%s%s", vmPath, DefImName);
	PRINTF(("\\t Default image name: %s\n", imageName));
}

void sqStringFromFilename( char * sqString, char*fileName, int sqSize) {
/* copy chars TO a Squeak String FROM a C filename char array.
 * You may transform the characters as needed as long as the string length
 * stays the same . The sqString and fileName can be the same address */
int i;
char c;
	PRINTF(("sqRPCMain: sqStringFromFilename - %s\n",fileName));

	for (i = 0; i < sqSize; i++) {
		c =  *fileName++; ;
		if ( c =='.') c = '/';
		else if (c=='/') c = '.';
		*((char *) (sqString + i)) = c;
	}
}

int canonicalizeFilename(char * inString, char * outString) {
/* run a RISC OS format filename through canonicalize to make it correct */
int spare;
os_error * e;

	if ((e = xosfscontrol_canonicalise_path (inString, outString, (char const *) NULL, (char const *)NULL, MAXDIRNAMELENGTH, &spare)) != null) {
		return false;
	}
	return true;
}

int canonicalizeFilenameToString(char * sqString, int sqSize, char * cString) {
/* copy chars from a Squeak String to a C filename char array.
 * You may transform the characters as needed - in this case go from unix like
 * path to RISC OS & then canonicalize
 */
int i;
char c;
char temp[MAXDIRNAMELENGTH];

	for (i = 0; i < sqSize; i++) {
		c =  *((char *) (sqString + i));
		if ( c =='.') c = '/';
		else if (c=='/') c = '.';
		temp[i] = c;
	}
	temp[i] = 0;

	 return canonicalizeFilename(temp, cString) ;
}

sqInt imageNameSize(void) {
	return strlen(imageName);
}

sqInt imageNameGetLength(sqInt sqImageNameIndex, sqInt length) {
int count;

	count = strlen(imageName);
	count = (length < count) ? length : count;

	/* copy the file name into the Squeak string */
	sqStringFromFilename( (char *)sqImageNameIndex, imageName, count);
}

sqInt imageNamePutLength(sqInt sqImageNameIndex, sqInt length) {
extern void SetupWindowTitle(void);

	if (!canonicalizeFilenameToString((char*)sqImageNameIndex, length, imageName)) return false;

	SetupWindowTitle();
	return length;
}

char * getImageName(void) {
	return imageName;
}

void dummyWimpPoll(void) {
/* quick wimp_poll to allow icon to appear and for interactivity
   during loading */
wimp_event_no wimpPollEvent;
wimp_block wimpPollBlock;
int wimpPollWord;
	do xwimp_poll((wimp_MASK_POLLWORD| wimp_MASK_GAIN | wimp_MASK_LOSE | wimp_MASK_MESSAGE | wimp_MASK_RECORDED | wimp_SAVE_FP) , &wimpPollBlock,  &wimpPollWord, (wimp_event_no*)&wimpPollEvent);
	while (wimpPollEvent != wimp_NULL_REASON_CODE);
}

/*** Image file reading and writing - do in chunks with a wimp-poll ***/
#define CHUNK_SIZE 64 * 1024
size_t sqImageFileRead(void *ptr, size_t sz, size_t count, sqImageFile f) {
int remaining, actuallyRead=0;
unsigned char *dstPtr;
	remaining = sz * count;
	dstPtr = (unsigned char *)ptr;

	PRINTF(("\\t start loading image\n"));
	while (remaining >= CHUNK_SIZE) {
		actuallyRead = fread(dstPtr, (size_t)1, (size_t)CHUNK_SIZE, f);
		/* if we didnt read enough, return an error case */
		if ( actuallyRead != CHUNK_SIZE) {
			return 0;
		}
		dstPtr += CHUNK_SIZE;
		remaining -= CHUNK_SIZE;
		dummyWimpPoll();
	}

	actuallyRead = fread(dstPtr, (size_t)1, (size_t)remaining, f);
	/* if we didnt read enough, return an error case */
	if ( actuallyRead != remaining) {
		return 0;
	}
	/* return the number of bytes read */
	PRINTF(("\\t finish loading image\n"));

	return count;
}

size_t sqImageFileWrite(void *ptr, size_t sz, size_t count, sqImageFile f) {
int remaining, actuallyWritten=0;
unsigned char *dstPtr;
	remaining = sz * count;
	dstPtr = (unsigned char *)ptr;

	while (remaining >= CHUNK_SIZE) {
		actuallyWritten = fwrite(dstPtr, (size_t)1, (size_t)CHUNK_SIZE, f);
		/* if we didnt write enough, return an error case */
		if ( actuallyWritten != CHUNK_SIZE) return 0;
		dstPtr += CHUNK_SIZE;
		remaining -= CHUNK_SIZE;
		/* drop this for now; it seems to clash with
		 * the threading of Oregano at least, causing loss
		 * of the image !!
		 dummyWimpPoll();
		 */
	}

	/* update the window title to reflect the new image name, if that *
	 * is what it is showing */
	if (actualOSLevel >= 380) {
		extern wimp_w windowHandleFromIndex(int windowIndex);
		xwimp_force_redraw_furniture(windowHandleFromIndex(1), wimp_FURNITURE_TITLE);
	}

	actuallyWritten = fwrite(dstPtr, (size_t)1, (size_t)remaining, f);
	/* if we didnt write enough, return an error case */
	if ( actuallyWritten != remaining) return 0;
	/* return the number of bytes written */
	return count;
}



/*** VM Home Directory Path ***/

sqInt vmPathSize(void) {
	return strlen(vmPath);
}

sqInt vmPathGetLength(sqInt sqVMPathIndex, sqInt length) {
int count;

	count = strlen(vmPath);
	count = (length < count) ? length : count;

	/* copy the file name into the Squeak string */
	sqStringFromFilename( (char *)sqVMPathIndex, vmPath, count);
	return count;
}


/* null version */
sqInt ioDisablePowerManager(sqInt disableIfNonZero) {
return 0;
}

/*** Profiling place holders ***/

sqInt clearProfile(void) {}

sqInt dumpProfile(void) {}

sqInt startProfiling(void) {}

sqInt stopProfiling(void) {}

/*** System Attributes ***/
char * osVersionString(void) {
	sprintf(versionString, "%-3.2f", actualOSLevel/100.0);
	return versionString;
}

char * getAttributeString(sqInt id) {
	/* This is a hook for getting various status strings back from
	   the OS. In particular, it allows Squeak to be passed arguments
	   such as the name of a file to be processed. Command line options
	   can be reported this way as well.
	   Fail the prim if the id is not of a valid attribute
	*/
char * tmp;
extern char VMVersion[];

	switch ((int)id) {
		case 0: return vmPath; break;
		case 1: return imageName; break;
		case 1001: return "RiscOS"; break;
		case 1002: return osVersionString(); break;
		case 1003: return "ARM"; break;
		case 1004: return  (char *)interpreterVersion; break;
		case 1005: return  "RiscOS"; break;
		case 1006: return  VMVersion; break;
		default: break;
	}
	if ((id < 0) && ( -id < numOptionsVM)) {
			tmp = vmOptions[-id];
			if (*tmp) return tmp;
	}
	if ((id > 1) &&(id <= numOptionsImage)) {
		// we have an offset of 1 for + ids in
		// order to accommodate the vmPath at 0
		tmp = imageOptions[id-1];
		if (*tmp) return tmp;
	}
	/* fail the prim to ensure we return nil instead of an empty string */
	success(false);
	return "";
}

sqInt attributeSize(sqInt id) {
	return strlen(getAttributeString(id));
}

sqInt getAttributeIntoLength(sqInt id, sqInt byteArrayIndex, sqInt length) {
char *srcPtr, *dstPtr, *end;
int charsToMove;

	srcPtr = getAttributeString(id);
	charsToMove = strlen(srcPtr);
	if (charsToMove > length) {
		charsToMove = length;
	}

	dstPtr = (char *) byteArrayIndex;
	end = srcPtr + charsToMove;
	while (srcPtr < end) {
		*dstPtr++ = *srcPtr++;
	}
	return charsToMove;
}

/* Commandline option processing */
void helpMessage(char * progname, char * helpname) {
char runHelp[256];
FILE * f;
	sprintf(runHelp, "%s%s", progname, helpname);
	f = fopen(runHelp, "r");
	if (f != NULL) {
		fclose(f);
		sprintf(runHelp, "chain:Filer_Run %s%s\n", progname, helpname);
		system(runHelp);
	}
}

void versionMessage(char * progname) {
extern char VMVersion[];
	privateErr.errnum = (bits)0;
	sprintf(privateErr.errmess, "This is version %s of %s.!Squeak\n", VMVersion, progname);
	platReportError((os_error *)&privateErr);
}

char * decodeVMPath(char *srcptr) {
/* canonicalize the program name and chop off at the last dirsep to
 * make a path for the vm directory. This is  set right at the beginning of
 * run and never changed */
char * endChar;

	canonicalizeFilename(srcptr, vmPath);
	/* find the last dir separator in the string and zap it with *
	 * a dirsep and null to make the end of the string. */
	endChar = strrchr( vmPath, '.');
	if (endChar) *(++endChar) = null;
	PRINTF(("\\t vmPath: %s\n", vmPath));
	return vmPath;
}

/*** Main ***/

int main(int argc,  char  *argv[]) {
FILE *f;
extern void initGlobalStructure(void);
extern void setMetaKeyOptions(int swap);
	parseArguments( argv, argc, args);

	if (versionMe) versionMessage(vmPath);
	if (helpMe) helpMessage(vmPath, "!Help");

	atexit(exit_function);   // setup a clean exit function

	InitRiscOS();
	initGlobalStructure();

	dummyWimpPoll();

	/* read the image file and allocate memory for Squeak heap
	    - the image name has been set to the path parsed by c.sqArgument
	    - if no filename was passed in, the default is to expect an image
	      file (Squeak/image) inside the application directory */
	f = fopen(imageName, "rb");
	PRINTF(("\\t Starting Squeak with image file: %s\n", imageName));
	if (f == NULL) {
		/* give a RPC error message if image file is not found */
		extern char VMVersion[];
		privateErr.errnum = (bits)0;
		sprintf(privateErr.errmess, "Could not open the Squeak image file '%s' (Squeak version: %s)", imageName, VMVersion);
		printf("Squeak version: %s was unable to find and open the image file supposedly at %s\n", VMVersion, imageName);
		printf("If you simply tried to run the !Squeak application, it will have attempted to run a default image within the application directory which is not usually present\n");
		platReportError((os_error *)&privateErr);
		helpMessage(vmPath, "!ImName");
		ioExit();
	}

	setMetaKeyOptions(swapMeta);

	readImageFromFileHeapSize(f, objectHeadroom);
	fclose(f);

	/* run Squeak */
	PRINTF(("\\t start running image\n"));

	interpret();
}

