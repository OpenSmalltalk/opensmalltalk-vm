//
//  sqSqueakOSXInfoPlistInterface.h
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

#import "sqSqueakInfoPlistInterface.h"
#import "sq.h"

@interface sqSqueakOSXInfoPlistInterface : sqSqueakInfoPlistInterface {
	NSInteger	SqueakDebug;
	BOOL		SqueakQuitOnQuitAppleEvent;
	BOOL		SqueakPluginsBuiltInOrLocalOnly;
	BOOL		SqueakExplicitWindowOpenNeeded;
	usqInt		SqueakMaxHeapSize;
	NSURL		*SqueakUnTrustedDirectory;
	NSURL		*SqueakTrustedDirectory;
	NSURL		*SqueakResourceDirectory;
	NSTimeInterval	SqueakUIFlushPrimaryDeferNMilliseconds;
	float		SqueakUIFadeForFullScreenInSeconds;
	NSInteger	SqueakMouseMappings[4][4];
	NSInteger	SqueakBrowserMouseMappings[4][4];
	NSInteger		SqueakNumStackPages;
	NSInteger		SqueakEdenBytes;
}
@property (nonatomic,assign) NSInteger	SqueakDebug;
@property (nonatomic,assign) NSInteger	SqueakNumStackPages;
@property (nonatomic,assign) NSInteger	SqueakEdenBytes;
@property (nonatomic,assign) BOOL	SqueakQuitOnQuitAppleEvent;
@property (nonatomic,assign) BOOL	SqueakPluginsBuiltInOrLocalOnly;
@property (nonatomic,assign) BOOL	SqueakExplicitWindowOpenNeeded;
@property (nonatomic,assign) usqInt	SqueakMaxHeapSize;
@property (nonatomic,strong) NSURL*		SqueakUnTrustedDirectory;
@property (nonatomic,strong) NSURL*		SqueakTrustedDirectory;
@property (nonatomic,strong) NSURL*		SqueakResourceDirectory;
@property (nonatomic,assign) NSTimeInterval	SqueakUIFlushPrimaryDeferNMilliseconds;
@property (nonatomic,assign) float		SqueakUIFadeForFullScreenInSeconds;

- (void) setInfoPlistNumberValueFrom: (NSDictionary*) dict key: (NSString *) key  default: (NSInteger) number using: (SEL) selector;
- (void) setInfoPlistFloatNumberValueFrom: (NSDictionary*) dict key: (NSString *) key  default: (float) number using: (SEL) selector;
- (void) setInfoPlistBooleanValueFrom: (NSDictionary*) dict key: (NSString *) key  default: (BOOL) defaultBool using: (SEL) selector;
- (void) setInfoPlistNumberValueForMouseX: (NSInteger) x Y: (NSInteger) y from: (NSDictionary*) dict key: (NSString *) key  default: (NSInteger) number browser: (BOOL) browser;
- (NSURL *) expandNSStringIntoNSURL: (NSString*) originalPath doOptionalSqueakLandLogic: (BOOL) isetoysonastick;
- (NSString *) fixupNonAbsolutePath: (NSString *) partialPathString;
- (void) setOverrideSqueakImageName: (NSString *) v;
- (NSInteger) getSqueakMouseMappingsAt: (NSInteger) i by: (NSInteger) j;
- (NSInteger) getSqueakBrowserMouseMappingsAt: (NSInteger) i by: (NSInteger) j;
  
@end
