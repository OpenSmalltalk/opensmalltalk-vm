/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  other machines not yet tested.                                        */
/*                       sqRPCMain.c                                      */
/* OS interface stuff, commandline option handling and so on              */
/**************************************************************************/

/* To recompile this reliably you will need    */           
/* OSLib -  http://ro-oslib.sourceforge.net/   */
/* Castle/AcornC/C++, the Acorn TCPIPLib       */
/* and a little luck                           */
// define this to get lots of debug notifiers
//#define DEBUG

#include "oslib/os.h"
#include "oslib/osbyte.h"
#include "oslib/osfscontrol.h"
#include "oslib/wimp.h"
#include "oslib/wimpspriteop.h"
#include "oslib/colourtrans.h"
#include "sq.h"
#include "sqArguments.h"
#include <kernel.h>
#include <stdarg.h>

#define longAt(i) (*((int *) (i)))

/*** Variables -- Imported from Virtual Machine ***/

/*** Variables -- image and path names ***/
#define IMAGE_NAME_SIZE 300
char		imageName[IMAGE_NAME_SIZE + 1];  /* full path to image */

#define VMPATH_SIZE 300
char		vmPath[VMPATH_SIZE + 1];  /* full path to interpreter's directory */

#ifndef MIN
#define MIN( a, b )   ( ( (a) < (b) ) ? (a) : (b) )
#define MAX( a, b )   ( ( (a) > (b) ) ? (a) : (b) )
#endif

/*** Variables -- RPC Related ***/
extern wimp_w			sqWindowHandle;
char			sqTaskName[] = "Squeak!";
wimp_t			Task_Handle;
os_dynamic_area_no	SqueakObjectSpaceDA;
extern os_dynamic_area_no	SqueakDisplayDA;
wimp_MESSAGE_LIST(8)	importantWimpMessages;
wimp_version_no		actualOSLevel;
os_error		privateErr;
char			versionString[20];
static			FILE *logfile= 0;

/* argument handling stuff  -- see c.sqArgument */
int 			numOptionsVM;
char			*(vmOptions[MAX_OPTIONS]);
int 			numOptionsImage;
char			*(imageOptions[MAX_OPTIONS]);

int			headlessFlag = 0;
int			helpMe = 0;
int			versionMe = 0;
int			swapMeta = 0;
int			objectHeadroom = 4*1024*1024;
char * windowLabel = &imageName[0];

vmArg args[] = {
		{ ARG_FLAG,   &headlessFlag, "-headless" },
		{ ARG_FLAG,   &helpMe, "-help" },
		{ ARG_FLAG,   &versionMe, "-version" },
		{ ARG_FLAG,   &swapMeta,  "-swapMeta"},
		{ ARG_UINT,   &objectHeadroom, "-memory:"},
		{ ARG_STRING, &windowLabel, "-windowlabel:"},
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
		logfile= fopen("Report:", "a+");
	}
	if (!logfile) {
		/* No Report: so try an ordinary log file */
		char logPath[VMPATH_SIZE];
		sprintf(logPath, "%sSqueak/vmlog", vmPath);
		logfile= fopen(logPath, "a+");
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

int platAllocateMemory( int amount) {
os_error * e;
int daSizeLimit;
byte * daBaseAddress;
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
	}

	PRINTF(("\\t platAllocateMemory(%d) at %0x", amount, (int)daBaseAddress));

	return (int)daBaseAddress;
}

int platMallocChunk(int size) {
	int chunk;
	chunk = (int) malloc(size);
	if ( chunk ==  NULL) return -1;
	return chunk;
}

void setTimer(void) {
/* Initialise the TimerMod timer
*/
_kernel_swi_regs regs;
	_kernel_swi(/* Timer_Start*/ 0x490C0, &regs, &regs);
}


int InitRiscOS(void) {
/* Initialise RiscOS for desktop wimp program use */
os_error * e;
extern  wimp_icon_create sqIconBarIcon;
	importantWimpMessages.messages[0] = message_MODE_CHANGE;
	importantWimpMessages.messages[1] = message_CLAIM_ENTITY;
	importantWimpMessages.messages[2] = message_DATA_REQUEST;
	importantWimpMessages.messages[3] = message_DATA_SAVE;
	importantWimpMessages.messages[4] = message_DATA_LOAD;
	importantWimpMessages.messages[5] = message_DATA_SAVE_ACK;

	if ((e = xwimp_initialise (wimp_VERSION_RO35,
					sqTaskName,
					(wimp_message_list*)&importantWimpMessages,
					&actualOSLevel,
					&Task_Handle)) != NULL) {
		platReportFatalError( e);
		return false;
	}
	SqueakDisplayDA =SqueakObjectSpaceDA = (os_dynamic_area_no)NULL;
 
	sqIconBarIcon.w = (wimp_w)-1;
	sqIconBarIcon.icon.extent.x0 = 0;
	sqIconBarIcon.icon.extent.y0 = 0;
	sqIconBarIcon.icon.extent.x1 = 68;
	sqIconBarIcon.icon.extent.y1 = 68;
	sqIconBarIcon.icon.flags = wimp_ICON_INDIRECTED
				| wimp_ICON_SPRITE
				| wimp_ICON_HCENTRED
				| wimp_ICON_VCENTRED
				| (wimp_BUTTON_CLICK
					<<wimp_ICON_BUTTON_TYPE_SHIFT ) ;
	sqIconBarIcon.icon.data.indirected_sprite.id = (osspriteop_id )&sqTaskName;
	sqIconBarIcon.icon.data.indirected_sprite.area = (osspriteop_area *)1;
	sqIconBarIcon.icon.data.indirected_sprite.size = 7;
	wimp_create_icon(&sqIconBarIcon);

	SetupPaletteTable();

	setFPStatus(0);

	setTimer();

return true;
}

/*** I/O Primitives ***/

int ioBeep(void) {
	os_writec((char)7);
	return true;
}

int ioExit(void) {
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

	ioShutdownAllModules();

	SetDefaultPointer();
	if (SqueakObjectSpaceDA != (os_dynamic_area_no)NULL)
		xosdynamicarea_delete ( SqueakObjectSpaceDA );
	if (SqueakDisplayDA != (os_dynamic_area_no)NULL)
		xosdynamicarea_delete ( SqueakDisplayDA );
	PRINTF(("\\t exiting Squeak\n"));
	if ( (int)logfile > 0) fclose( logfile);
}

int ioMicroMSecs(void) {
/* The
   function ioMicroMSecs() is used only to collect timing statistics
   for the garbage collector and other VM facilities. (The function
   name is meant to suggest that the function is based on a clock
   with microsecond accuracy, even though the times it returns are
   in units of milliseconds.) This clock must have enough precision to
   provide accurate timings, and normally isn't called frequently
   enough to slow down the VM. Thus, it can use a more expensive clock
   that ioMSecs().
*/
_kernel_swi_regs regs;
	_kernel_swi(/* Timer_Value*/ 0x490C2, &regs, &regs);
	return (regs.r[0] * 1000) + (int)(regs.r[1] / 1000);

}

int ioSeconds(void) {
/*	  Unix epoch to Smalltalk epoch conversion.
	(Date newDay: 1 year: 1970) asSeconds
			- (Date newDay: 1 year: 1901) asSeconds
	is
			2177452800
	limit is about 2057ad - this may cause problems...
*/
	return  (int)((unsigned long)time(NULL) + 2177452800uL);
}

/*** Image File Naming ***/

void sqStringFromFilename( int sqString, char*fileName, int sqSize) {
// copy chars TO a Squeak String FROM a C filename char array.
// You may transform the characters as needed
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

void sqFilenameFromString(char*fileName, int sqString, int sqSize) {
// copy chars from a Squeak String to a C filename char array.
// You may transform the characters as needed
int i;
int junk;
char c;
char temp[1000];
os_error * e;

	for (i = 0; i < sqSize; i++) {
		c =  *((char *) (sqString + i));
		if ( c =='.') c = '/';
		else if (c=='/') c = '.';
		temp[i] = c;
	}
	temp[i] = 0;
	if ((e = xosfscontrol_canonicalise_path (temp, fileName, (char const *) NULL, (char const *)NULL, 1000, &junk)) != null) {
		// when canonicalizing filenames we can get errors like
		//   no disc
		//   bad use of ^
		//   bad name
		// etc
		// just copy the ugly string to the destination for now
		strcpy(fileName, temp);
		PRINTF(("sqRPCMain: sqFilenameFromString canon fail - %s\n",temp));
		// debugging-> platReportError(e);
	}
	PRINTF(("sqRPCMain: sqFilenameFromString - %s\n",temp));
}

int imageNameSize(void) {
	return strlen(imageName);
}

int imageNameGetLength(int sqImageNameIndex, int length) {
int count;

	count = strlen(imageName);
	count = (length < count) ? length : count;

	/* copy the file name into the Squeak string */
	sqStringFromFilename( sqImageNameIndex, imageName, count);
}

int imageNamePutLength(int sqImageNameIndex, int length) {
int count;
	count = (IMAGE_NAME_SIZE < length) ? IMAGE_NAME_SIZE : length;

	/* copy the file name into a null-terminated C string */
	sqFilenameFromString( imageName, sqImageNameIndex, count);

	return count;
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
		xwimp_force_redraw_furniture(sqWindowHandle, wimp_FURNITURE_TITLE);
	}

	actuallyWritten = fwrite(dstPtr, (size_t)1, (size_t)remaining, f);
	/* if we didnt write enough, return an error case */
	if ( actuallyWritten != remaining) return 0;
	/* return the number of bytes written */
	return count;
}



/*** VM Home Directory Path ***/

int vmPathSize(void) {
	return strlen(vmPath);
}

int vmPathGetLength(int sqVMPathIndex, int length) {
int count;

	count = strlen(vmPath);
	count = (length < count) ? length : count;

	/* copy the file name into the Squeak string */
	sqStringFromFilename( sqVMPathIndex, vmPath, count);
	return count;
}


/* null version */
int ioDisablePowerManager(int disableIfNonZero) {
return 0;
}

/*** Profiling place holders ***/

int clearProfile(void) {}

int dumpProfile(void) {}

int startProfiling(void) {}

int stopProfiling(void) {}

/*** System Attributes ***/
char * osVersionString(void) {
	sprintf(versionString, "%-3.2f", actualOSLevel/100.0);
	return versionString;
}

char * getAttributeString(int id) {
	/* This is a hook for getting various status strings back from
	   the OS. In particular, it allows Squeak to be passed arguments
	   such as the name of a file to be processed. Command line options
	   can be reported this way as well.
	   Fail the prim if the id is not of a valid attribute
	*/
char * tmp;

	switch (id) {
		case 0: return vmPath; break;
		case 1: return imageName; break;
		case 1001: return "RiscOS"; break;
		case 1002: return osVersionString(); break;
		case 1003: return "ARM"; break;
		case 1004: return  (char *)interpreterVersion; break;
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

int attributeSize(int id) {
	return strlen(getAttributeString(id));
}

int getAttributeIntoLength(int id, int byteArrayIndex, int length) {
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

void decodePath(char *srcptr, char * dstPtr) {
os_error * e;
int spare;

	/* do the actual canonicalisation */
	if ((e = xosfscontrol_canonicalise_path (srcptr, dstPtr, (char const *) null, (char const *)null, VMPATH_SIZE, &spare)) != null) {
		platReportFatalError(e);
		return;
	}
}

void decodeVMPath(char *srcptr) {
char * endChar;

	decodePath(srcptr, vmPath);
	/* find the last dir separator in the string and zap it with *
	 * a dirsep and null to make the end of the string. */
	endChar = strrchr( vmPath, '.');
	if (endChar) *(++endChar) = null;
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

	/* read the image file and allocate memory for Squeak heap */
	f = fopen(imageName, "rb");
	PRINTF(("\\t Starting Squeak with image file: %s\n", imageName));
	if (f == NULL) {
		/* give a RPC error message if image file is not found */
		extern char VMVersion[];
		privateErr.errnum = (bits)0;
		sprintf(privateErr.errmess, "Could not open the Squeak image file '%s' (Squeak version: %s)", imageName, VMVersion);
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

