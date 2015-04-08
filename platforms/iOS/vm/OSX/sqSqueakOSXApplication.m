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


#import "sqSqueakOSXApplication.h"
#import "sqSqueakOSXFileDirectoryInterface.h"
#import "sqSqueakOSXInfoPlistInterface.h"
#import "sqSqueakOSXSoundCoreAudio.h"
#import "sqSqueakSoundCoreAudioAPI.h"

usqInt	gMaxHeapSize=512*1024*1024;

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


@implementation sqSqueakOSXApplication 
@synthesize squeakHasCursor,squeakCursor;

- (void) setupFloat {
	fldcw(0x12bf);	/* signed infinity, round to nearest, REAL8, disable intrs, disable signals */
	mtfsfi((unsigned long long ) 0);		/* disable signals, IEEE mode, round to nearest */
}

- (sqSqueakFileDirectoryInterface *) newFileDirectoryInterfaceInstance {
	return [sqSqueakOSXFileDirectoryInterface new];
}

- (sqSqueakInfoPlistInterface *) newSqSqueakInfoPlistInterfaceCreation {
	return [sqSqueakOSXInfoPlistInterface new];
}

- (void) doHeadlessSetup {
	[super doHeadlessSetup];
	extern BOOL gSqueakHeadless;
	if (gSqueakHeadless) 
		return;
#warning untested
	ProcessSerialNumber psn = { 0, kCurrentProcess };
	ProcessInfoRec info;
	bzero(&info, sizeof(ProcessInfoRec));
	info.processInfoLength = sizeof(ProcessInfoRec);
	GetProcessInformation(&psn,&info);
	if ((info.processMode & modeOnlyBackground) && TransformProcessType != NULL) {
		OSStatus returnCode = TransformProcessType(& psn, kProcessTransformToForegroundApplication);
#pragma unused(returnCode)
		SetFrontProcess(&psn);		
	}
}

- (void) doMemorySetup {
	gMaxHeapSize =  ((sqSqueakOSXInfoPlistInterface*) self.infoPlistInterfaceLogic).SqueakMaxHeapSize;
}

- (void) setupSoundLogic {
	self.soundInterfaceLogic = [sqSqueakOSXSoundCoreAudio new];
 	[(sqSqueakOSXSoundCoreAudio *) self.soundInterfaceLogic soundInitOverride];

	snd_Start(2644, 22050, 1, 0);
	char slience[10576];
	bzero(&slience, sizeof(slience));
	snd_PlaySamplesFromAtLength(2644,(usqInt * ) &slience,0);
	[self.soundInterfaceLogic snd_Stop_Force];
}

- (void) parseUnixArgs {
	NSProcessInfo *p = [NSProcessInfo processInfo];
	[self parseArgs: [p arguments]];
	[self parseEnv: [p environment]];
}

- (NSInteger) parseArgument: (NSString *) argData peek: (NSString *) peek {
	
	if ([argData compare: @"--"] == NSOrderedSame) {
		return 1;
	}

	NS_DURING;
		if ([argData compare:  @"-psn_" options: NSLiteralSearch range: NSMakeRange(0,5)] == NSOrderedSame) {
			return 1;
		}
	NS_HANDLER;
	NS_ENDHANDLER;
	
	if ([argData compare: @"-help"] == NSOrderedSame) {
		[self usage];
		return 1;
	}
	if ([argData compare: @"-headless"] == NSOrderedSame) {
		extern BOOL gSqueakHeadless;
		gSqueakHeadless = YES;
		return 1;
	}
	if ([argData compare: @"-memory"] == NSOrderedSame) {
		gMaxHeapSize = (usqInt) [self strtobkm: [peek UTF8String]];
		return 2;
	}
	return 0;
}

- (void) parseArgs: (NSArray *) args{
		  
	argsArguments = [[NSMutableArray alloc] initWithCapacity: [args count]];
	
	if ([args count] < 2) 
		return;
	NSMutableArray *revisedArgs = [args mutableCopyWithZone: NULL];
	[revisedArgs removeObjectAtIndex:0];
	
	NSUInteger i,result;
	BOOL optionsCompleted = NO;
	for (i=0; i<[revisedArgs count]; i++) {
		NSString *argData = [revisedArgs objectAtIndex:i];
		NSString *peek = (i == ([revisedArgs count] - 1)) ? @"" : [revisedArgs objectAtIndex:i+1];
		if ([argData compare: @"--"] == NSOrderedSame) {
			optionsCompleted = YES;
			continue;
		}
		if (!optionsCompleted && [[argData substringToIndex: 1] compare: @"-"] != NSOrderedSame) {
			optionsCompleted = YES;
			continue;
		}
		if (optionsCompleted) {
			[self.argsArguments addObject: argData];
		} else {
			result = [self parseArgument: argData peek: peek];
			if (result == 0)			/* option not recognised */ {
				fprintf(stderr, "unknown option: %s\n", [argData UTF8String]);
//				[self usage];
			}
			if (result == 2)
				i++;
		}
		
	}
	[revisedArgs release];
}

- (long long) strtobkm: (const char *) str {
	char *suffix;
	long long value= strtoll(str, &suffix, 10);
	switch (*suffix)
    {
		case 'k': case 'K':
			value*= 1024LL;
			break;
		case 'm': case 'M':
			value*= 1024LL*1024LL;
			break;
    }
	return value;
}

- (void) parseEnv: (NSDictionary *) env {
#warning untested!
	NSString *imageNameString = [env objectForKey: @"SQUEAK_IMAGE"];
	if (imageNameString) {
		[(sqSqueakOSXInfoPlistInterface*) self.infoPlistInterfaceLogic setOverrideSqueakImageName: imageNameString];
	}
	NSString *memoryString = [env objectForKey: @"SQUEAK_MEMORY"];
	if (memoryString) {
		gMaxHeapSize = (usqInt) [self strtobkm: [memoryString UTF8String]];
	}
}
   
- (void) usage {
	printf("Usage: [<option>...] [<imageName> [<argument>...]]\n");
	printf("       [<option>...] -- [<argument>...]\n");
	[self printUsage];
	printf("\nNotes:\n");
	printf("  <imageName> defaults to `Squeak.image'.\n");
	[self printUsageNotes];
	exit(1);
}

- (void) printUsage {
	printf("\nCommon <option>s:\n");
	printf("  -help                 print this help message, then exit\n");
	printf("  -memory <size>[mk]    use fixed heap size (added to image size)\n");
	printf("  -headless             run in headless (no window) mode (default: false)\n");
}

- (void) printUsageNotes
{
	printf("  If `-memory' is not specified then the heap will grow dynamically.\n");
	printf("  <argument>s are ignored, but are processed by the Squeak image.\n");
	printf("  The first <argument> normally names a Squeak `script' to execute.\n");
	printf("  Precede <arguments> by `--' to use default image.\n");
}

- (BOOL) isImageFile: (NSString *) filePath
{
 	NSFileManager *dfm = [NSFileManager defaultManager];
	BOOL isDirectory;
	
	[dfm fileExistsAtPath: filePath isDirectory: &isDirectory];

	if (isDirectory) 
		return NO;

	BOOL fileIsReadable = [[NSFileManager defaultManager] isReadableFileAtPath: filePath];
	
	if (fileIsReadable == NO)
		return NO;

	if ([[[filePath lastPathComponent] pathExtension] compare: @"image" options: NSCaseInsensitiveSearch] ==   NSOrderedSame)
		return YES;
	
	return NO;
}

@end
