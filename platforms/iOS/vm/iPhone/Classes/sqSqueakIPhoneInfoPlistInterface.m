//
//  sqSqueakIPhoneInfoPlistInterface
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 9/1/08.
/*
Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
Copyright (c) 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
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

Sept-02-08  1.03b1  setup useScrollingView
*/
//

#import "sqSqueakIPhoneInfoPlistInterface.h"

NSString * kwriteable_preferenceKey = @"writeable_preference";
NSString * kscrollableView_preferenceKey = @"scrollableView_preference";
NSString * kmemorySize_preferenceKey = @"memorySize_preference";

 extern int gSqueakUseFileMappedMMAP;

@implementation sqSqueakIPhoneInfoPlistInterface
- (void) parseInfoPlist {
	@autoreleasepool {

		[super parseInfoPlist];
		
		self.SqueakUseFileMappedMMAP = YES;
		gSqueakUseFileMappedMMAP = 1;
		
		NSString *testValue = [defaults stringForKey: kwriteable_preferenceKey];
		
		if (testValue == nil) {
			// no default values have been set, create them here based on what's in our Settings bundle info
        //
        NSString *pathStr = [[NSBundle mainBundle] bundlePath];
        NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
        NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];
			
        NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
        NSArray *prefSpecifierArray = settingsDict[@"PreferenceSpecifiers"];

        NSDictionary *prefItem;
			NSString	*writeable_preferenceDefault = @"YES";
			NSString	*scrollableView_preferenceDefault= @"NO";
			NSString	*memorySize_preferenceDefault=@"33554432";
        for (prefItem in prefSpecifierArray)	{
				NSString *keyValueStr = prefItem[@"Key"];
				id defaultValue = prefItem[@"DefaultValue"];
			
				if ([keyValueStr isEqualToString: kwriteable_preferenceKey]) {
					writeable_preferenceDefault = defaultValue;
				}

				if ([keyValueStr isEqualToString: kscrollableView_preferenceKey]) {
					scrollableView_preferenceDefault = defaultValue;
				}

				if ([keyValueStr isEqualToString: kmemorySize_preferenceKey]) {
					memorySize_preferenceDefault = defaultValue;
				}
			}
			
        // since no default values have been set (i.e. no preferences file created), create it here
        NSDictionary *appDefaults =  @{kwriteable_preferenceKey: writeable_preferenceDefault,
										  kscrollableView_preferenceKey: scrollableView_preferenceDefault,
										  kmemorySize_preferenceKey: memorySize_preferenceDefault};
        
        [[NSUserDefaults standardUserDefaults] registerDefaults: appDefaults];
        [[NSUserDefaults standardUserDefaults] synchronize];
		}
	}
	
}

- (BOOL) imageIsWriteable {
	return [defaults boolForKey: kwriteable_preferenceKey];
}

- (BOOL) useScrollingView {
	return [defaults boolForKey: kscrollableView_preferenceKey];
}

- (NSInteger) memorySize {
	return [defaults integerForKey: kmemorySize_preferenceKey];
}

- (NSString *)stringFromInfo:(NSString *)key defaultValue:(NSString *)defaultValue{
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *value = info[key];
    if(value != nil)
        return value;
    else
        return defaultValue;
}

- (BOOL) useWorkerThread {
	NSString *value = [self stringFromInfo:@"VMWorkerThread" defaultValue:@"NO"];
    return [value boolValue];
}

- (BOOL) useWebViewAsUI {
	NSString *value = [self stringFromInfo:@"WebViewAsUI" defaultValue:@"NO"];
    return [value boolValue];
}
@end
