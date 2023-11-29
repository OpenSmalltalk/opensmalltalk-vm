//
//  sqSqueakOSXApplication.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-10.
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright (c) 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
 MIT License
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.

 The end-user documentation included with the redistribution, if any, must include the following acknowledgment: 
 "This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com) 
 and its contributors", in the same place and form as other third-party acknowledgments. 
 Alternately, this acknowledgment may appear in the software itself, in the same form and location as other 
 such third-party acknowledgments.
 */
//

#include "sqSCCSVersion.h"

#import "sqSqueakOSXApplication.h"
#import "sqSqueakOSXFileDirectoryInterface.h"
#import "sqSqueakOSXInfoPlistInterface.h"
#import "sqSqueakOSXSoundCoreAudio.h"
#import "sqSqueakSoundCoreAudioAPI.h"
#import "sqSqueakOSXApplication+imageReadWrite.h"
#import "sqSqueakOSXApplication+attributes.h"
#import "sqSqueakOSXViewFactory.h"
#import "SqueakOSXAppDelegate.h"

extern SqueakOSXAppDelegate *gDelegateApp;

#if !defined(IMAGE_DIALECT_NAME)
# if NewspeakVM
#	define IMAGE_DIALECT_NAME "Newspeak"
#	define DEFAULT_IMAGE_NAME "newspeak.image"
#	define IMAGE_ENV_NAME "NEWSPEAK_IMAGE"
# elif PharoVM
#	define IMAGE_DIALECT_NAME "Pharo"
#	define DEFAULT_IMAGE_NAME "Pharo.image"
#	define IMAGE_ENV_NAME "PHARO_IMAGE"
# else 
#	define IMAGE_DIALECT_NAME "Squeak"
#	define DEFAULT_IMAGE_NAME "squeak.image"
#	define IMAGE_ENV_NAME "SQUEAK_IMAGE"
# endif
#endif

#ifdef PharoVM
# define VMOPTION(arg) "--"arg
# define VMOPTIONOBJ(arg) @"--"arg
# define VMOPTIONLEN(n) (1+n)
#else
# define VMOPTION(arg) "-"arg
# define VMOPTIONOBJ(arg) @"-"arg
# define VMOPTIONLEN(n) (n)
#endif

usqInt gMaxHeapSize = 512*1024*1024;

#if defined(__GNUC__) && ( defined(i386) || defined(__i386) || defined(__i386__)  \
|| defined(i486) || defined(__i486) || defined (__i486__) \
|| defined(intel) || defined(x86) || defined(i86pc) \
|| defined(__x86_64__))
void fldcw(unsigned int cw)
{
	__asm__("fldcw %0" :: "m"(cw));
}
#else
# define fldcw(cw)
#endif

#if defined(__GNUC__) && ( defined(ppc) || defined(__ppc) || defined(__ppc__)  \
|| defined(POWERPC) || defined(__POWERPC) || defined (__POWERPC__) )
void mtfsfi(unsigned long long fpscr)
{
	__asm__("lfd   f0, %0" :: "m"(fpscr));
	__asm__("mtfsf 0xff, f0");
}
#else
void mtfsfi(unsigned long long fpscr) {}

# define mtfsfi(fpscr)
#endif

static char *getVersionInfo(int verbose);

@implementation sqSqueakOSXApplication 
@synthesize squeakCursor;
@synthesize aboutWindow;

- (void) setupFloat {
	fldcw(0x12bf);	/* signed infinity, round to nearest, REAL8, disable intrs, disable signals */
	mtfsfi((unsigned long long ) 0);		/* disable signals, IEEE mode, round to nearest */
}

- (sqSqueakFileDirectoryInterface *) newFileDirectoryInterfaceInstance {
	return [[sqSqueakOSXFileDirectoryInterface alloc] init];
}

- (sqSqueakInfoPlistInterface *) newSqSqueakInfoPlistInterfaceCreation {
	return [[sqSqueakOSXInfoPlistInterface alloc] init];
}

- (void) doHeadlessSetup {
	//No super call here as we've already set headless from command line or info.plist
	extern BOOL gSqueakHeadless;    
    // Notice that setActivationPolicy: is available in OSX 10.6 and later
    if ([NSApp respondsToSelector:@selector(setActivationPolicy:)]) {
        if (gSqueakHeadless) {
            [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
        } else {
            [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
            [NSApp activateIgnoringOtherApps:YES];
        }
    } else {
        if (gSqueakHeadless) {
            NSLog( @"For OSX older than 10.6 there is no support for headless");
            [self ioExit];
        } else {
                // nothing in particular to do. 
        }
    }
}

- (void) doMemorySetup {
	gMaxHeapSize =  ((sqSqueakOSXInfoPlistInterface*) self.infoPlistInterfaceLogic).SqueakMaxHeapSize;
}

- (void) setupSoundLogic {
	self.soundInterfaceLogic = AUTORELEASEOBJ([[sqSqueakOSXSoundCoreAudio alloc] init]);
 	[(sqSqueakOSXSoundCoreAudio *) self.soundInterfaceLogic soundInitOverride];

	snd_Start(2644, 22050, 1, 0);
	char silence[10576];
	bzero(&silence, sizeof(silence));
	snd_PlaySamplesFromAtLength(2644,(usqInt * ) &silence,0);
	[self.soundInterfaceLogic snd_Stop_Force];
}

- (void) parseUnixArgs {
	[super parseUnixArgs];
	NSProcessInfo *p = [NSProcessInfo processInfo];
	[self parseArgs: [p arguments]];
	[self parseEnv: [p environment]];
}

- (int) parseArgument: (NSString *) argData peek: (char *) peek
{
	if ([argData isEqualToString: @"--"]) {
		return 1;
	}

	/* Options with no arguments */

	NS_DURING;
		if ([argData compare:  VMOPTIONOBJ("psn_") options: NSLiteralSearch range: NSMakeRange(0,5)] == NSOrderedSame) {
			return 1;
		}
		if ([argData isEqualToString: @"-NSDocumentRevisionsDebugMode"]) {
			return 1;
		}
	NS_HANDLER;
	NS_ENDHANDLER;

	if ([argData isEqualToString: VMOPTIONOBJ("help")]) {
		[self usage];
		exit(0);
		return 1;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("version")]) {
		printf("%s\n", getVersionInfo(0));
		exit(0);
		return 1;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("blockonerror")]) {
		extern int blockOnError;
		blockOnError = true;
		return 1;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("blockonwarn")]) {
		extern int blockOnError;
		extern sqInt erroronwarn;
		erroronwarn = blockOnError = true;
		return 1;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("exitonwarn")]) {
		extern sqInt erroronwarn;
		erroronwarn = true;
		return 1;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("headless")]) {
		extern BOOL gSqueakHeadless;
		gSqueakHeadless = YES;
		sqCurrentOSXRequestedViewType = SQ_OSX_REQUESTED_VIEW_TYPE_NONE;
		return 1;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("headfull")]) {
		extern BOOL gSqueakHeadless;
		gSqueakHeadless = NO;
		sqCurrentOSXRequestedViewType = SQ_OSX_REQUESTED_VIEW_TYPE_ANY;
		return 1;
	}
    if ([argData isEqualToString: VMOPTIONOBJ("nohandlers")]) {
		extern BOOL gNoSignalHandlers;
        gNoSignalHandlers = YES;
        return 1;
    }
	if ([argData isEqualToString: VMOPTIONOBJ("timephases")]) {
		extern void printPhaseTime(int);
		printPhaseTime(1);
		return 1;
	}

#ifdef USE_OPENGL
	if ([argData isEqualToString: VMOPTIONOBJ("opengl")]) {
		sqCurrentOSXRequestedViewType = SQ_OSX_REQUESTED_VIEW_TYPE_OPENGL;
		return 1;
	}
#endif
#ifdef USE_CORE_GRAPHICS
	if ([argData isEqualToString: VMOPTIONOBJ("core-graphics")]) {
		sqCurrentOSXRequestedViewType = SQ_OSX_REQUESTED_VIEW_TYPE_CORE_GRAPHICS;
		return 1;
	}
#endif
#ifdef USE_METAL
	if ([argData isEqualToString: VMOPTIONOBJ("metal")]) {
		sqCurrentOSXRequestedViewType = SQ_OSX_REQUESTED_VIEW_TYPE_METAL;
		return 1;
	}
#endif

#if defined(AIO_DEBUG)
	if ([argData isEqualToString: VMOPTIONOBJ("aiolog")]) {
		extern long aioDebugLogging;
		aioDebugLogging = 1;
		return 1;
	}
#endif
#if (STACKVM || NewspeakVM) && !COGVM
	if ([argData isEqualToString: VMOPTIONOBJ("sendtrace")]) {
		extern volatile int sendTrace;
		sendTrace = 1;
		return 1;
	}
#endif
#if COGVM
	if ([argData isEqualToString: VMOPTIONOBJ("logplugin")]) {
		extern char *primTracePluginName;
		primTracePluginName = peek;
		return 2;
	}
	if ([argData compare: VMOPTIONOBJ("trace") options: NSLiteralSearch range: NSMakeRange(0,VMOPTIONLEN(6))] == NSOrderedSame) {
		extern int traceFlags;

		if ([argData length] == VMOPTIONLEN(6)) {
			traceFlags = 1;
			return 1;
		}
		if ([argData length] <= VMOPTIONLEN(7)
		 || [argData characterAtIndex: VMOPTIONLEN(6)] != '='
		 || !isdigit([argData characterAtIndex: VMOPTIONLEN(7)]))
			return 0;

		traceFlags = atoi([argData UTF8String] + VMOPTIONLEN(7));
		return 1;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("tracestores")]) {
		extern sqInt traceStores;
		traceStores = 1;
		return 1;
	}
#endif
#if STACKVM
	if ([argData isEqualToString: VMOPTIONOBJ("noheartbeat")]) {
		extern sqInt suppressHeartbeatFlag;
		suppressHeartbeatFlag = 1;
		return 1;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("warnpid")]) {
		extern sqInt warnpid;
		warnpid = getpid();
		return 1;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("reportheadroom")]
	 || [argData isEqualToString: VMOPTIONOBJ("rh")]) {
		extern sqInt reportStackHeadroom;
		reportStackHeadroom = 1;
		return 1;
	}
#endif
#if SPURVM
	if ([argData isEqualToString: VMOPTIONOBJ("logscavenge")]) {
		extern void openScavengeLog(void);
		openScavengeLog();
		return 1;
	}
#endif

	/* Options with arguments */
	if (!peek)
		return 0;

	if ([argData isEqualToString: VMOPTIONOBJ("memory")]) {
		gMaxHeapSize = (usqInt) [self strtobkmg: peek];
		return 2;
	}

    if ([argData isEqualToString: @"-NSDocumentRevisionsDebugMode"]) {
        return 2;
    }

#if STACKVM || NewspeakVM
	if ([argData isEqualToString: VMOPTIONOBJ("breaksel")]) {
		extern void setBreakSelector(char *);
		setBreakSelector(peek);
		return 2;
	}
#endif
#if STACKVM
	if ([argData isEqualToString: VMOPTIONOBJ("breakmnu")]) {
		extern void setBreakMNUSelector(char *);
		setBreakMNUSelector(peek);
		return 2;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("eden")]) {
		extern sqInt desiredEdenBytes;
		desiredEdenBytes = [self strtobkmg: peek]; 
		return 2;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("leakcheck")]) {
		extern sqInt checkForLeaks;
		checkForLeaks = atoi(peek);		 
		return 2;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("stackpages")]) {
		extern sqInt desiredNumStackPages;
		desiredNumStackPages = atoi(peek);		 
		return 2;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("numextsems")]) {
		ioSetMaxExtSemTableSize(atoi(peek));
		return 2;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("pollpip")]) {
		extern sqInt pollpip;
		pollpip = atoi(peek);		 
		return 2;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("failonffiexception")]) {
		extern sqInt ffiExceptionResponse;
		ffiExceptionResponse = 1;
		return 1;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("nofailonffiexception")]) {
		extern sqInt ffiExceptionResponse;
		ffiExceptionResponse = -1;
		return 1;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("debugfailonffiexception")]) {
		extern sqInt wait_for_debugger_to_attach_on_ffi_exception;
		wait_for_debugger_to_attach_on_ffi_exception = 1;
		printf("pid %d\n", getpid());
		return 1;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("eventtrace")]) {
		extern sqInt eventTraceMask;
		eventTraceMask = atoi(peek);		 
		return 2;
	}
#endif /* STACKVM */
#if COGVM
	if ([argData isEqualToString: VMOPTIONOBJ("codesize")]) {
		extern sqInt desiredCogCodeSize;
		desiredCogCodeSize = [self strtobkm: peek];		 
		return 2;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("cogmaxlits")]) {
		extern sqInt maxLiteralCountForCompile;
		maxLiteralCountForCompile = [self strtobkm: peek];		 
		return 2;
	}
	if ([argData isEqualToString: VMOPTIONOBJ("cogminjumps")]) {
		extern sqInt minBackwardJumpCountForCompile;
		minBackwardJumpCountForCompile = [self strtobkm: peek];		 
		return 2;
	}
#endif /* COGVM */
#if SPURVM
	if ([argData isEqualToString: VMOPTIONOBJ("maxoldspace")]) {
		extern usqInt maxOldSpaceSize;
		maxOldSpaceSize = (usqInt)[self strtobkmg: peek];		 
		return 2;
	}
#endif
#if 0 /* Not sure if encoding is an issue with the Cocoa VM. eem 2015-11-30 */
	if ([argData isEqualToString: VMOPTIONOBJ("pathenc")]) {
		setEncodingType(peek);
		return 2;
	}
#endif
	return 0;
}


- (void) parseArgs: (NSArray *) args {
	numVMArgs = 0;
    commandLineArguments = [args copyWithZone:null];
    argsArguments = [[NSMutableArray alloc] initWithCapacity: [args count]];

    if ([args count] < 2)
        return;
    NSMutableArray *revisedArgs = AUTORELEASEOBJ([args mutableCopyWithZone: NULL]);
    [revisedArgs removeObjectAtIndex:0];

    NSUInteger i,result;
    BOOL optionsCompleted = NO;
    for (i=0; i<[revisedArgs count]; i++) {
        NSString *argData = revisedArgs[i];

        NSString *peek = (i == ([revisedArgs count] - 1)) ? @"" : revisedArgs[i+1];

        if ([argData isEqualToString: @"-NSDocumentRevisionsDebugMode"]) {
            //This is an Xcode debug option, skip it for us
            i++;
            continue;
        }
        if ([argData compare: @"--"] == NSOrderedSame) {
            optionsCompleted = YES;
            continue;
        }
        if (!optionsCompleted && ![[argData substringToIndex: 1] isEqualToString: @"-"]) {
            optionsCompleted = YES;

            //guessing first parameter as image name
            if ([argData compare: @"--"] != NSOrderedSame) {
                [self setImageNamePathIfItWasReadable:argData];
            } else {
                continue;
            }
        }
        if (optionsCompleted) {
            [self.argsArguments addObject: argData];
        } else {
            result = [self parseArgument: argData peek: peek.UTF8String];
            if (result == 0)			/* option not recognised */ {
                fprintf(stderr, "unknown option: %s\n", [argData UTF8String]);
                [self usage];
                exit(1);
            }
            if (result == 2)
                i++;
			numVMArgs = i + 1;
        }
    }
}

- (long long) strtobkm: (const char *) str {
	char *suffix;
	long long value = strtoll(str, &suffix, 10);
	switch (*suffix) {
		case 'k': case 'K':
		return value * 1024LL;
		case 'm': case 'M':
		return value * 1024LL*1024LL;
    }
	return value;
}

- (usqLong) strtobkmg: (const char *) str {
	char *suffix;
	usqLong value = strtoull(str, &suffix, 10);
	switch (*suffix) {
		case 'k': case 'K':
		return value * 1024ULL;
		case 'm': case 'M':
		return value * 1024ULL*1024ULL;
		case 'g': case 'G':
		return value * 1024ULL*1024ULL*1024ULL;
    }
	return value;
}

- (void) parseEnv: (NSDictionary *) env {
	NSString *imageNameString = env[@"SQUEAK_IMAGE"];
	if (imageNameString) {
		[(sqSqueakOSXInfoPlistInterface*) self.infoPlistInterfaceLogic setOverrideSqueakImageName: imageNameString];
	}
	NSString *memoryString = env[@"SQUEAK_MEMORY"];
	if (memoryString) {
		gMaxHeapSize = (usqInt) [self strtobkmg: [memoryString UTF8String]];
	}
}

- (void) usage {
	extern char **argVec;
	printf("Usage: %s [<option>...] [<imageName> [<argument>...]]\n", argVec[0]);
	printf("       %s [<option>...] -- [<argument>...]\n", argVec[0]);
	[self printUsage];
	printf("\nNotes:\n");
	//printf("  <imageName> defaults to `%s'.\n", DEFAULT_IMAGE_NAME);
	printf("  <imageName> defaults to `" DEFAULT_IMAGE_NAME "'.\n");
	[self printUsageNotes];
	// exit(1);
}

static char **optionStrings = 0;
static int count = 0;

static void
option(char *optionString)
{
	// This is used at start-up, so no need to check.
	optionStrings = realloc(optionStrings, sizeof(char *) * ++count);
	optionStrings[count - 1] = optionString;
}

static void
extendOption(const char *extension)
{
	char *opt = optionStrings[count - 1];
	int len = strlen(opt);
	char *newopt = malloc(len + strlen(extension) + 1);
	strcpy(newopt, opt);
	strcpy(newopt + len, extension);
	optionStrings[count - 1] = newopt;
}

static int
sortStrings(const char **a, const char **b)
{ return strcmp(*b,*a); } // N.B. reversed sort

static void
printOptionStrings()
{
	qsort(optionStrings,
			count,
			sizeof(char *),
			(int (*)(const void*,const void*))sortStrings);
	while (--count >= 0)
		printf(optionStrings[count]);
}

- (void) printUsage {
	int i;
	printf("%s\n","\nCommon <option>s:");
	printf("%s\n", "  "VMOPTION("help")"                 print this help message, then exit");

	option("  "VMOPTION("memory")" <size>[kmg]   use fixed heap size (added to image size)\n");
    option("  "VMOPTION("nohandlers")"           disable sigsegv & sigusr1 handlers\n");
	option("  "VMOPTION("timephases")"           print start load and run times\n");
#if STACKVM || NewspeakVM
	option("  "VMOPTION("breaksel")" selector    set breakpoint on send of selector\n");
#endif
#if STACKVM
	option("  "VMOPTION("failonffiexception")"   when in an FFI callout primitive catch exceptions and fail the primitive\n");
	option("  "VMOPTION("breakmnu")" selector    set breakpoint on MNU of selector\n");
	option("  "VMOPTION("eden")" <size>[kmg]     set eden memory to bytes\n");
	option("  "VMOPTION("leakcheck")" num        check for leaks in the heap\n");
	option("  "VMOPTION("stackpages")" num       use n stack pages\n");
	option("  "VMOPTION("numextsems")" num       make the external semaphore table num in size\n");
	option("  "VMOPTION("noheartbeat")"          disable the heartbeat for VM debugging. disables input\n");
	option("  "VMOPTION("pollpip")" (0|1)        output on each poll for input\n");
	option("  "VMOPTION("eventtrace")" mask      print input events with types in mask to stderr\n");
	const char *eventtraceFlagsMeanings[] = EVENT_TYPE_MASKS_INIT;
	i = 0;
	while (eventtraceFlagsMeanings[i]) {
		extendOption("    ");
		extendOption(eventtraceFlagsMeanings[i++]);
		extendOption("\n");
	}
#endif
#if STACKVM || NewspeakVM
# if COGVM
	option("  "VMOPTION("logplugin")" name       only log primitives in plugin\n");
	option("  "VMOPTION("trace")"[=flags]        enable tracing (optionally to a specific value)\n");
	extern const char *traceFlagsMeanings[];
	i = 0;
	while (traceFlagsMeanings[i]) {
		extendOption("    ");
		extendOption(traceFlagsMeanings[i++]);
		extendOption("\n");
	}
# else
	option("  "VMOPTION("sendtrace")"            enable send tracing\n");
# endif
	option("  "VMOPTION("warnpid")"              print pid in warnings\n");
#endif
#if COGVM
	option("  "VMOPTION("codesize")" <size>[mk]  set machine code memory to bytes\n");
	option("  "VMOPTION("tracestores")"          enable store tracing (assert check stores)\n");
	option("  "VMOPTION("cogmaxlits")" <n>       set max number of literals for methods to be compiled to machine code\n");
	option("  "VMOPTION("cogminjumps")" <n>      set min number of backward jumps for interpreted methods to be considered for compilation to machine code\n");
	option("  "VMOPTION("reportheadroom")"       report unused stack headroom on exit\n");
#endif
#if SPURVM
	option("  "VMOPTION("maxoldspace")" <size>[kmg]  set max size of old space memory to bytes\n");
	option("  "VMOPTION("logscavenge")"          log scavenging to scavenge.log\n");
#endif
#if 0 /* Not sure if encoding is an issue with the Cocoa VM. eem 2015-11-30 */
	option("  "VMOPTION("pathenc")" <enc>        set encoding for pathnames (default: %s)\n",
		getEncodingType([self currentVMEncoding]));
#endif
	option("  "VMOPTION("headless")"             run in headless (no window) mode (default: false)\n");
	option("  "VMOPTION("headfull")"             run in headful (window) mode (default: true)\n");

#ifdef USE_OPENGL
	option("  "VMOPTION("opengl")"               use OpenGL for drawing the VM window. Must be the first argument.\n");
#endif
#ifdef USE_CORE_GRAPHICS
	option("  "VMOPTION("core-graphics")"        use CoreGraphics for drawing the VM window. Must be the first argument.\n");
#endif
#ifdef USE_METAL
	option("  "VMOPTION("metal")"                use Metal for drawing the VM window. Must be the first argument.\n");
#endif

	option("  "VMOPTION("version")"              print version information, then exit\n");

	option("  "VMOPTION("blockonerror")"         on error or segv block, not exit.  useful for attaching gdb/lldb\n");
	option("  "VMOPTION("blockonwarn")"          on warning block, don't warn.  useful for attaching gdb/lldb\n");
	option("  "VMOPTION("exitonwarn")"           treat warnings as errors, exiting on warn\n");
#if defined(AIO_DEBUG)
	option("  "VMOPTION("aiolog")"               print async io logging info\n");
#endif
	printOptionStrings();
}

- (void) printUsageNotes
{
#if SPURVM
	printf("  If '"VMOPTION("memory")"' or '-maxoldspace' are not specified then the heap will grow dynamically.\n");
#else
	printf("  If '"VMOPTION("memory")"' is not specified then the heap will grow dynamically.\n");
#endif
	printf("  <argument>s are ignored, but are processed by the Squeak image.\n");
	printf("  The first <argument> normally names a Squeak `script' to execute.\n");
	printf("  Precede <arguments> by `--' to use default image.\n");
}

- (BOOL) isImageFile: (NSString *) filePath
{
	return [gDelegateApp isImageFile: filePath];
}

@end

static char *
getVersionInfo(int verbose)
{
#if STACKVM
  extern char *__interpBuildInfo;
# define INTERP_BUILD __interpBuildInfo
# if COGVM
  extern char *__cogitBuildInfo;
# endif
#else
# define INTERP_BUILD interpreterVersion
#endif
  extern char vmBuildString[];
  CFStringRef versionString;
  char *info = (char *)malloc(4096);
  info[0] = '\0';

#if SPURVM
# if BytesPerOop == 8
#	define ObjectMemory " Spur 64-bit"
# else
#	define ObjectMemory " Spur"
# endif
#else
# define ObjectMemory
#endif
#if defined(NDEBUG)
# define BuildVariant "Production" ObjectMemory
#elif DEBUGVM
# define BuildVariant "Debug" ObjectMemory
# else
# define BuildVariant "Assert" ObjectMemory
#endif

  if (verbose)
    sprintf(info+strlen(info), IMAGE_DIALECT_NAME " VM version: ");
  sprintf(info+strlen(info), "%s ", VM_VERSION);
  if ((versionString = CFBundleGetValueForInfoDictionaryKey(
						CFBundleGetMainBundle(),
						CFSTR("CFBundleVersion"))))
#if 0 /* Not sure if encoding is an issue with the Cocoa VM. eem 2015-11-30 */
    CFStringGetCString(versionString, info+strlen(info), 4095-strlen(info), gCurrentVMEncoding);
#else
    CFStringGetCString(versionString, info+strlen(info), 4095-strlen(info), kCFStringEncodingUTF8);
#endif
  sprintf(info+strlen(info), " %s [" BuildVariant " %s VM]\n", vmBuildString, getAttributeString(1003)); // 1003 == processor
  if (verbose)
    sprintf(info+strlen(info), "Built from: ");
  sprintf(info+strlen(info), "%s\n", INTERP_BUILD);
#if COGVM
  if (verbose)
    sprintf(info+strlen(info), "With: ");
  sprintf(info+strlen(info), "%s\n", __cogitBuildInfo); /* __cogitBuildInfo */
#endif
  if (verbose)
    sprintf(info+strlen(info), "Revision: ");
  sprintf(info+strlen(info), "%s\n", sourceVersionString('\n'));
  return info;
}
