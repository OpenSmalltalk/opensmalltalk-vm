//
//  sqSqueakOSXInfoPlistInterface.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-12.
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
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

#import "sqSqueakOSXInfoPlistInterface.h"

extern int gSqueakUseFileMappedMMAP;

@implementation sqSqueakOSXInfoPlistInterface
@synthesize SqueakDebug,SqueakQuitOnQuitAppleEvent,
	SqueakMaxHeapSize,SqueakUnTrustedDirectory,SqueakTrustedDirectory,SqueakResourceDirectory,
	SqueakPluginsBuiltInOrLocalOnly,SqueakExplicitWindowOpenNeeded,SqueakUIFlushPrimaryDeferNMilliseconds,SqueakNumStackPages,SqueakEdenBytes,
	SqueakUIFadeForFullScreenInSeconds;

- (void) setOverrideSqueakNumStackPages: (NSNumber *) v {
	self.SqueakNumStackPages = [v integerValue];
}

- (void) setOverrideSqueakEdenBytes: (NSNumber *) v {
	self.SqueakEdenBytes = [v integerValue];
}

- (void) setOverrideSqueakDebug: (NSNumber *) v {
	self.SqueakDebug = [v integerValue];
}

- (void) setOverrideSqueakQuitOnQuitAppleEvent: (NSNumber *) v {
	self.SqueakQuitOnQuitAppleEvent = [v boolValue];
}

- (void) setOverrideSqueakUseFileMappedMMAP: (NSNumber *) v {
	self.SqueakUseFileMappedMMAP = [v boolValue];
	gSqueakUseFileMappedMMAP = [v boolValue] == YES;
}

- (void) setOverrideSqueakPluginsBuiltInOrLocalOnly: (NSNumber *) v {
	self.SqueakPluginsBuiltInOrLocalOnly = [v boolValue];
}

- (void) setOverrideSqueakExplicitWindowOpenNeeded: (NSNumber *) v {
	self.SqueakExplicitWindowOpenNeeded = [v boolValue];
}

- (void) setOverrideSqueakMaxHeapSize: (NSNumber *) v {
	self.SqueakMaxHeapSize = [v unsignedIntValue];
}

- (void) setOverrideSqueakUIFadeForFullScreenInSeconds: (NSNumber *) v {
	self.SqueakUIFadeForFullScreenInSeconds = [v floatValue];
}

- (void) setOverrideSqueakUIFlushPrimaryDeferNMilliseconds: (NSNumber *) v {
	self.SqueakUIFlushPrimaryDeferNMilliseconds = [v doubleValue]/1000.0;
}

- (void) setOverrideSqueakUnTrustedDirectory: (NSString *) v {
	self.SqueakUnTrustedDirectory = [self expandNSStringIntoNSURL: v doOptionalSqueakLandLogic: YES];
	const char *dataInFileSystemRep = [[NSFileManager defaultManager] fileSystemRepresentationWithPath: [self.SqueakUnTrustedDirectory path]];
	extern char gSqueakUntrustedDirectoryName[];
	strlcpy(gSqueakUntrustedDirectoryName, dataInFileSystemRep, PATH_MAX);
	strlcat(gSqueakUntrustedDirectoryName,"/",PATH_MAX);
}

- (void) setOverrideSqueakTrustedDirectory: (NSString *) v {
	self.SqueakTrustedDirectory = [self expandNSStringIntoNSURL: v doOptionalSqueakLandLogic: YES];
	const char *dataInFileSystemRep = [[NSFileManager defaultManager] fileSystemRepresentationWithPath: [self.SqueakTrustedDirectory path]];
	extern char gSqueakTrustedDirectoryName[];
	strlcpy(gSqueakTrustedDirectoryName, dataInFileSystemRep, PATH_MAX);
	strlcat(gSqueakTrustedDirectoryName,"/",PATH_MAX);
}

- (void) setOverrideSqueakResourceDirectory: (NSString *) v {
	if (!v) 
		return;
	self.SqueakResourceDirectory = [self expandNSStringIntoNSURL: v doOptionalSqueakLandLogic: YES];
}

- (void) setOverrideSqueakImageName: (NSString *) v {
	if (!v) 
		return;
	extern char imageName[];
	strlcpy(imageName,[v UTF8String],PATH_MAX); 
}

- (NSInteger) getSqueakMouseMappingsAt: (NSInteger) i by: (NSInteger) j {
	return SqueakMouseMappings[i][j];
}
   
- (NSInteger) getSqueakBrowserMouseMappingsAt: (NSInteger) i by: (NSInteger) j {
	return SqueakBrowserMouseMappings[i][j];
}

- (void) setInfoPlistNSStringValueFrom: (NSDictionary*) dict key: (NSString *) key  default: (NSString*) defaultString using: (SEL) selector{
	NSString *str = dict[key];
	str = (str) ? str : defaultString;
	[self performSelectorOnMainThread: selector withObject: str waitUntilDone: YES];
}

- (void) setInfoPlistNumberValueFrom: (NSDictionary*) dict key: (NSString *) key  default: (NSInteger) defaultInteger using: (SEL) selector{
	NSNumber *num = dict[key];
	num = (num) ? num : @(defaultInteger);
	[self performSelectorOnMainThread: selector withObject: num waitUntilDone: YES];
}

- (void) setInfoPlistFloatNumberValueFrom: (NSDictionary*) dict key: (NSString *) key  default: (float) defaultFloat using: (SEL) selector{
	NSNumber *num = dict[key];
	num = (num) ? num : @(defaultFloat);
	[self performSelectorOnMainThread: selector withObject: num waitUntilDone: YES];
}

- (void) setInfoPlistBooleanValueFrom: (NSDictionary*) dict key: (NSString *) key  default: (BOOL) defaultBool using: (SEL) selector{
	NSNumber *num = dict[key];
	num = (num) ? num : @(defaultBool);
	[self performSelectorOnMainThread: selector withObject: num waitUntilDone: YES];
}

- (void) setInfoPlistNumberValueForMouseX: (NSInteger) x Y: (NSInteger) y from: (NSDictionary*) dict key: (NSString *) key  default: (NSInteger) number browser: (BOOL) browser {
	NSNumber *num = dict[key];
	NSInteger numberAsInteger = (num) ? [num integerValue] : number;
	if (browser) {
		SqueakBrowserMouseMappings[x][y] = numberAsInteger;
	} else {
		SqueakMouseMappings[x][y] = numberAsInteger;
	}
}

- (NSURL *) expandNSStringIntoNSURL: (NSString*) originalPath doOptionalSqueakLandLogic: (BOOL) isetoysonastick {
	
	NSString *checkFortilda = [originalPath stringByStandardizingPath];
	
	if (isetoysonastick) {
		NSString *standardizedString;
		BOOL isAbsolutePath = [checkFortilda isAbsolutePath];
		if (!isAbsolutePath) {
			NSString *filePath = [self fixupNonAbsolutePath: checkFortilda];	
			standardizedString = [filePath stringByStandardizingPath];
		} else {
			standardizedString = checkFortilda;
		}
		return [NSURL fileURLWithPath: standardizedString];
	}
	
	return  [NSURL fileURLWithPath: checkFortilda];
}

- (NSString *) fixupNonAbsolutePath: (NSString *) partialPathString {
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *resourcePath = [mainBundle resourcePath];
	NSString *actualPath = [resourcePath stringByAppendingPathComponent: partialPathString];
	return actualPath ;
}


- (void) parseInfoPlist {
	@autoreleasepool {
	
		NSBundle *mainBundle = [NSBundle mainBundle];
		NSDictionary *dict = [mainBundle infoDictionary]; 
		
		[self setInfoPlistNumberValueFrom: dict key: @"SqueakNumStackPages" default: 0 using: @selector(setOverrideSqueakNumStackPages:)];
		[self setInfoPlistNumberValueFrom: dict key: @"SqueakEdenBytes" default: 0 using: @selector(setOverrideSqueakEdenBytes:)];

		[self setInfoPlistNumberValueFrom: dict key: @"SqueakDebug" default: 0 using: @selector(setOverrideSqueakDebug:)];
		[self setInfoPlistBooleanValueFrom: dict key: @"SqueakQuitOnQuitAppleEvent" default: NO using: @selector(setOverrideSqueakQuitOnQuitAppleEvent:)];
		[self setInfoPlistBooleanValueFrom: dict key: @"SqueakUseFileMappedMMAP" default: NO using: @selector(setOverrideSqueakUseFileMappedMMAP:)];
		[self setInfoPlistNumberValueFrom: dict key: @"SqueakMaxHeapSize" default: 512*1024*1024 using: @selector(setOverrideSqueakMaxHeapSize:)];
		[self setInfoPlistNumberValueFrom: dict key: @"SqueakUIFlushPrimaryDeferNMilliseconds" default: 20 using: @selector(setOverrideSqueakUIFlushPrimaryDeferNMilliseconds:)];
		[self setInfoPlistFloatNumberValueFrom: dict key: @"SqueakUIFadeForFullScreenInSeconds" default: 1.5 using: @selector(setOverrideSqueakUIFadeForFullScreenInSeconds:)];

	[self setInfoPlistNSStringValueFrom: dict key: @"SqueakUnTrustedDirectory" default: @"/foobar/tooBar/forSqueak/bogus/" using: @selector(setOverrideSqueakUnTrustedDirectory:)];
	[self setInfoPlistNSStringValueFrom: dict key: @"SqueakTrustedDirectory" default: @"/foobar/tooBar/forSqueak/bogus/" using: @selector(setOverrideSqueakTrustedDirectory:)];
	[self setInfoPlistNSStringValueFrom: dict key: @"SqueakResourceDirectory" default: NULL using: @selector(setSqueakResourceDirectory:)];
	[self setInfoPlistBooleanValueFrom: dict key: @"SqueakPluginsBuiltInOrLocalOnly" default: YES using: @selector(setOverrideSqueakPluginsBuiltInOrLocalOnly:)];
	[self setInfoPlistBooleanValueFrom: dict key: @"SqueakExplicitWindowOpenNeeded" default: NO using: @selector(setOverrideSqueakExplicitWindowOpenNeeded:)];
	[self setInfoPlistNSStringValueFrom: dict key: @"SqueakImageName" default: @"Squeak.image" using: @selector(setOverrideSqueakImageName:)];
	[self setInfoPlistNumberValueForMouseX: 0 Y: 1 from: dict key: @"SqueakMouseNoneButton1" default: 1 browser: NO];
	[self setInfoPlistNumberValueForMouseX: 0 Y: 2 from: dict key: @"SqueakMouseNoneButton2" default: 3 browser: NO];
	[self setInfoPlistNumberValueForMouseX: 0 Y: 3 from: dict key: @"SqueakMouseNoneButton3" default: 2 browser: NO];
	[self setInfoPlistNumberValueForMouseX: 1 Y: 1 from: dict key: @"SqueakMouseCmdButton1" default: 3 browser: NO];
	[self setInfoPlistNumberValueForMouseX: 1 Y: 2 from: dict key: @"SqueakMouseCmdButton2" default: 3 browser: NO];
	[self setInfoPlistNumberValueForMouseX: 1 Y: 3 from: dict key: @"SqueakMouseCmdButton3" default: 2 browser: NO];
	[self setInfoPlistNumberValueForMouseX: 2 Y: 1 from: dict key: @"SqueakMouseOptionButton1" default: 2 browser: NO];
	[self setInfoPlistNumberValueForMouseX: 2 Y: 2 from: dict key: @"SqueakMouseOptionButton2" default: 3 browser: NO];
	[self setInfoPlistNumberValueForMouseX: 2 Y: 3 from: dict key: @"SqueakMouseOptionButton3" default: 2 browser: NO];
	[self setInfoPlistNumberValueForMouseX: 3 Y: 1 from: dict key: @"SqueakMouseControlButton1" default: 1 browser: NO];
	[self setInfoPlistNumberValueForMouseX: 3 Y: 2 from: dict key: @"SqueakMouseControlButton2" default: 3 browser: NO];
	[self setInfoPlistNumberValueForMouseX: 3 Y: 3 from: dict key: @"SqueakMouseControlButton3" default: 2 browser: NO];
	[self setInfoPlistNumberValueForMouseX: 0 Y: 1 from: dict key: @"SqueakBrowserMouseNoneButton1" default: 1 browser: YES];
	[self setInfoPlistNumberValueForMouseX: 0 Y: 2 from: dict key: @"SqueakBrowserMouseNoneButton2" default: 3 browser: YES];
	[self setInfoPlistNumberValueForMouseX: 0 Y: 3 from: dict key: @"SqueakBrowserMouseNoneButton3" default: 2 browser: YES];
	[self setInfoPlistNumberValueForMouseX: 1 Y: 1 from: dict key: @"SqueakBrowserMouseCmdButton1" default: 3 browser: YES];
	[self setInfoPlistNumberValueForMouseX: 1 Y: 2 from: dict key: @"SqueakBrowserMouseCmdButton2" default: 3 browser: YES];
	[self setInfoPlistNumberValueForMouseX: 1 Y: 3 from: dict key: @"SqueakBrowserMouseCmdButton3" default: 2 browser: YES];
	[self setInfoPlistNumberValueForMouseX: 2 Y: 1 from: dict key: @"SqueakBrowserMouseOptionButton1" default: 2 browser: YES];
	[self setInfoPlistNumberValueForMouseX: 2 Y: 2 from: dict key: @"SqueakBrowserMouseOptionButton2" default: 3 browser: YES];
	[self setInfoPlistNumberValueForMouseX: 2 Y: 3 from: dict key: @"SqueakBrowserMouseOptionButton3" default: 2 browser: YES];
	[self setInfoPlistNumberValueForMouseX: 3 Y: 1 from: dict key: @"SqueakBrowserMouseControlButton1" default: 1 browser: YES];
	[self setInfoPlistNumberValueForMouseX: 3 Y: 2 from: dict key: @"SqueakBrowserMouseControlButton2" default: 3 browser: YES];
	[self setInfoPlistNumberValueForMouseX: 3 Y: 3 from: dict key: @"SqueakBrowserMouseControlButton3" default: 2 browser: YES];
    
    /* There are two possibilities for running headless. 
     Scenario 1: If the user does not care about a “little flash” that happens when starting the VM, then it just needs to invoke the VM from command line sending the argument -headless. 
     Scenario 2: If the user does care about the “flash”, it needs to set the LSBackgroundOnly property to true in the Info.plist. Then, just start the VM normally (no need of -headless).
     Notice that the processing of the -headless happens before this. So if gSqueakHeadless is true (Scenario 1) we cannot override it. The following lines are to support the uncessary -headless for Scenario 2.
  */
    extern BOOL gSqueakHeadless;
    if(!gSqueakHeadless) {
        gSqueakHeadless = [[mainBundle objectForInfoDictionaryKey:@"LSBackgroundOnly"] boolValue];
    }
    }
}

@end

/*
 @"SqueakWindowAttribute" NO
 @"SqueakWindowHasTitle" NO
 @"SqueakFloatingWindowGetsFocus" NO
 @"SqueakEncodingType" NO
 SqueakUIFlushPrimaryDeferNMilliseconds
 SqueakUIFlushSecondaryCleanupDelayMilliseconds
 SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds
*/
		
		
