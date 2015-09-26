//
//  sqSqueakMainApplication+imageReadWrite.m
//
//  Created by John M McIntosh on 5/22/08.
//
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
 */
//

#import "sqSqueakMainApplication+imageReadWrite.h"

#ifdef SPURVM
#  include <sys/stat.h>
#else
#import "sqMacV2Memory.h"
#endif

@implementation sqSqueakMainApplication (imageReadWrite) 
- (void) findImageViaBundleOrPreferences {
}

- (BOOL) readImageIntoMemory {
			@autoreleasepool {
	const char * characterPathForImage = (const char *) [[NSFileManager defaultManager] fileSystemRepresentationWithPath: [self.imageNameURL path]];
	sqImageFile f;
	if (!characterPathForImage)  {
		return NO;
	}
	f = sqImageFileOpen(characterPathForImage, "rb");
	if (f == 0) {
		fprintf(stderr, "Failed to open image named %s", characterPathForImage);
		exit(-1);
	}

#ifdef SPURVM
    extern sqInt highBit(usqInt);
    usqInt memory = 0;
    {
        struct stat sb;
        stat(characterPathForImage, &sb);

        off_t size = (long)sb.st_size;
        size = 1 << highBit(size-1);
        size = size + size / 4;
        memory =  size + size / 4;
    }
#else
    usqInt memory = sqGetAvailableMemory();
#endif
	readImageFromFileHeapSizeStartingAt(f, memory, (squeakFileOffsetType) 0);  //This is a VM Callback
	sqImageFileClose(f);
            }
	return YES;
}
@end
