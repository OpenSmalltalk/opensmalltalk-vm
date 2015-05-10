//
//  sqSqueakMainApplication+vmAndImagePath.m
//  
//
//  Created by John M McIntosh on 5/22/08.
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
 
 V1.05b1 use alloc form of NSURL
 */

//

#import "sqSqueakMainApplication+vmAndImagePath.h"
#import "sqSqueakAppDelegate.h"

extern sqSqueakAppDelegate *gDelegateApp;

@implementation sqSqueakMainApplication (vmAndImagePath) 

- (void) setVMPathFromApplicationDirectory {
    // in the default case return /Applications otherwise the path the .app is contained in
	self.vmPathStringURL = [NSURL fileURLWithPath: [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]];
}

- (BOOL) ImageNameIsEmpty {
	if (self.imageNameURL) 
		return NO;
	return YES;
}

- (const char *) getImageName {
	return [[[self.imageNameURL path] precomposedStringWithCanonicalMapping] UTF8String];
}

- (void) imageNameGet:(char *) sqImageName length:(sqInt)length {
	//sqImageName is actually the address of where to put the data
	//length is how many bytes the target can hold
	if (!sqImageName) 
		return;
	
	*sqImageName = 0x00;
	if (length > 0)
		strncpy(sqImageName, [self getImageName],(size_t) length); //This does not need to be strlcpy since the data is not null terminated
	/* ok do we need to check for length of getImageName? 
	 if length > strlen(getImageName) then it fills with 0x00
	 if length < strlen(getImageName) then we get a partial string and no trailing /0
	 if length == strlen(getImageName) then we get the string and no trailing /0 which is what is desired. */
}

- (void) imageNamePut:(const char *) sqImageName {
	
	if (!sqImageName) 
		return;
	self.imageNameURL = [NSURL fileURLWithPath: @(sqImageName) isDirectory: NO];
}

- (const char *) getVMPath {
    return [[[[self vmPathStringURL] path] precomposedStringWithCanonicalMapping] UTF8String];
}

- (void) vmPathGet:(char *) sqVMPath length:(sqInt)length {
	//sqVMPath is actually the address of where to put the data
	//length is how many bytes the target can hold
	
	if (!sqVMPath) 
		return;
	*sqVMPath = 0x00;
	if (length > 0) {
		strlcpy(sqVMPath, [self getVMPath], (size_t) length);
		sqVMPath[length-1] = '/'; // BUG length here is 1 offset, so need to subtract 1 to add on the '/' which is +1 via VMPathLength
	}
}
@end



