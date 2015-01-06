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

extern int gSqueakUseFileMappedMMAP;

@implementation sqSqueakIPhoneInfoPlistInterface
- (void) parseInfoPlist {
	NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
	[super parseInfoPlist];
    
	self.SqueakUseFileMappedMMAP = YES;
	gSqueakUseFileMappedMMAP = 1;
 	
	[pool drain];
	
}

- (NSString *)stringFromInfo:(NSString *)key defaultValue:(NSString *)defaultValue{
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *value = info[key];
    if(value != nil)
        return value;
    else
        return defaultValue;
}
                          
- (BOOL) imageIsWriteable {
	NSString *value = [self stringFromInfo:@"ImageIsWritable" defaultValue:@"YES"];
    return [value boolValue];
}

- (BOOL) useScrollingView {
	NSString *value = [self stringFromInfo:@"ImageIsScrollable" defaultValue:@"NO"];
    return [value boolValue];
}

- (NSInteger) memorySize {
    //Default value is 64M (for now)
	NSString *value = [self stringFromInfo:@"VMMemorySize" defaultValue:@"67108864"];
	return [value integerValue];
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
