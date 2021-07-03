//
//  sqSqueakMainApplication+attributes.m
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

#import "sqSqueakMainApplication+attributes.h"
#import "sqSqueakMainApplication+vmAndImagePath.h"
#if STACKVM
#include "sqSCCSVersion.h"
#endif

extern struct VirtualMachine* interpreterProxy;

@implementation sqSqueakMainApplication (attributes)

- (void) getAttribute:(sqInt)indexNumber into:(char *) byteArrayIndex length:(sqInt)length {
	//indexNumber is a postive/negative number
	//byteArrayIndex is actually the address of where to put the data
	//length is how many bytes the target can hold
	if(!byteArrayIndex)
		return;
	*byteArrayIndex = 0x00;
	if (length > 0)
		strncpy(byteArrayIndex, [self getAttribute: indexNumber], (size_t) length); //This does not need to be strlcpy
}

- (char *) interpreterVersionString {
	static char data[255];
	bzero(data,sizeof(data));
	strlcat(data,interpreterVersion,sizeof(data));
	strlcat(data," ",sizeof(data));
	NSString *versionString =[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"];

	if (versionString == nil)
		return data;
	const char *versonStringAsCString =  [versionString cStringUsingEncoding: [self currentVMEncoding]];

	if (versonStringAsCString == nil)
		return data;

	strlcat(data,versonStringAsCString,sizeof(data));

	return data;
}

- (const char *) getAttribute:(sqInt)indexNumber {
	//indexNumber is a postive/negative number
	if (indexNumber < 0) /* VM argument */ {
        if (-indexNumber <= numVMArgs)
			return (char *) [[self.commandLineArguments objectAtIndex: -indexNumber] cStringUsingEncoding:[self currentVMEncoding]];
	}
#if BUILD_FOR_OSX
	else if (indexNumber >= 2 && indexNumber <= 1000) {
        if (indexNumber < ([self.commandLineArguments count] - numVMArgs))
			return (char *) [[self.commandLineArguments objectAtIndex: indexNumber+numVMArgs] cStringUsingEncoding:[self currentVMEncoding]];
	}
#endif
	else {
		switch (indexNumber) {
			case 0:
                return [[[[NSBundle mainBundle] executablePath] precomposedStringWithCanonicalMapping] UTF8String];

			case 1:
				return [self getImageName];

            case 1004:  /* Interpreter version string */
				return [self interpreterVersionString];

            case 1009: {/* source tree version info */
#if STACKVM
				return sourceVersionString(' ');
#else
                static char data[255];
                bzero(data,sizeof(data));
                strlcat(data,interpreterVersion,sizeof(data));
                strlcat(data," ",sizeof(data));
                NSString *versionString =[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"];
                if (versionString == nil)
                    return data;
                const char *versonStringAsCString =  [ versionString cStringUsingEncoding: [self currentVMEncoding]];
                if (versonStringAsCString == nil)
                    return data;
                strlcat(data,versonStringAsCString,sizeof(data));
                return data;
#endif
            }
			case 1201: /* macintosh file name size */
				return "255";

			case 1202: /* macintosh file error peek */
				return "0";

			default: {
				int indexOfArg = indexNumber - 1;
				if (indexOfArg < [self.argsArguments count]) {
					return (char *) [[self.argsArguments objectAtIndex: (NSUInteger) indexOfArg] cStringUsingEncoding:[self currentVMEncoding]];
				}
			}
		}
	}
	interpreterProxy->success(false);
	return "";
}
@end
