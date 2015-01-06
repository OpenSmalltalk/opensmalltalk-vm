//
//  squeakSUnitTester.m
//  SqueakObjectiveC
//
//  Created by John M McIntosh on 9/25/08.
/* Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
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

#import "squeakSUnitTester.h"


@implementation squeakSUnitTester
- (char) test0char {
	return 'A';
}
- (int) test0int {
	return -1;
}
- (short) test0short {
	return 0xFFFF;
}
- (long) test0long {
	return 0xFFFFFFFF;
}
- (long long) test0longlong {
	return 0xFFFFFFFFFFFFFFFFLL;
}
- (unsigned char) test0unsignedchar{
	return 'A';
}
- (unsigned int) test0unsignedint{
	return 0xFFFFFFFF;
}
- (unsigned short) test0unsignedshort {
	return 0xFFFF;
}
- (unsigned long) test0unsignedlong{
	return 0xFFFFFFFF;
}
- (unsigned long long) test0unsignedlonglong {
	return 0xFFFFFFFFFFFFFFFFLL;
}
- (float) test0float {
	return 8.8f;
}
- (double) test0double {
	return 8.8;
}
- (void) test0void {
}
- (char *) test0charpointer {
	static char* squeak = "squeak";
	return squeak;
}
- (squeakSUnitTester *) test0object {
	return [squeakSUnitTester new];
}
- (Class) test0class {
	return [squeakSUnitTester class];
}
- (SEL) test0methodselector {
	SEL selector;
	selector = NSSelectorFromString(
									@"initWithBitmapDataPlanes:pixelsWide:pixelsHigh:bitsPerSample:samplesPerPixel:hasAlpha:isPlanar:colorSpaceName:bytesPerRow:bitsPerPixel:");
	return selector;
}
- (CGRect) test0CGRect {
CGRect foo;
	foo.origin.x = 1.0;
foo.origin.y = 2.0;
foo.size.width = 3.0;
foo.size.height = 4.0;
return foo;
	}
	
	- (char) test0char: (char *)ignore {
return 'A';
		}
		- (int) test0int: (char *)ignore {
return -1;
}
- (short) test0short: (char *)ignore {
			return 0xFFFF;
}
- (long) test0long: (char *)ignore {
return 0xFFFFFFFF;
				}
				- (long long) test0longlong: (char *)ignore {
	  return 0xFFFFFFFFFFFFFFFFLL;
}
- (unsigned char) test0unsignedchar: (char *)ignore{
		  return 'A';
		  }
	  - (unsigned int) test0unsignedint: (char *)ignore{
return 0xFFFFFFFF;
		  }
		  - (unsigned short) test0unsignedshort: (char *)ignore {
return 0xFFFF;
			  }
			  - (unsigned long) test0unsignedlong: (char *)ignore{
return 0xFFFFFFFF;
				  }
				  - (unsigned long long) test0unsignedlonglong: (char *)ignore {
return 0xFFFFFFFFFFFFFFFFLL;
}
- (float) test0float: (char *)ignore {
return 8.8f;
	}
	- (double) test0double: (char *)ignore {
	return 8.8;
}
- (void) test0void: (char *)ignore {
}
- (char *) test0charpointer: (char *)ignore {
static char* squeak = "squeak";
return squeak;
	}
	- (squeakSUnitTester *) test0object: (char *)ignore {
return [squeakSUnitTester new];
		}
		- (Class) test0class: (char *)ignore {
		return [squeakSUnitTester class];
		}
		- (SEL) test0methodselector: (char *)ignore {
		SEL selector;
		selector = NSSelectorFromString(
		@"initWithBitmapDataPlanes:pixelsWide:pixelsHigh:bitsPerSample:samplesPerPixel:hasAlpha:isPlanar:colorSpaceName:bytesPerRow:bitsPerPixel:");
return selector;
			}
			- (CGRect) test0CGRect: (char *)ignore {
		 CGRect foo;
		 foo.origin.x = 1.0;
				foo.origin.y = 2.0;
foo.size.width = 3.0;
foo.size.height = 4.0;
					return foo;
					}
					
					- (char) test0char: (char *)ignore two: (char *) ignore2 {
return 'A';
}
- (int) test0int: (char *)ignore two: (char *) ignore2 {
return -1;
}
- (short) test0short: (char *)ignore  two: (char *) ignore2{
return 0xFFFF;
}
- (long) test0long: (char *)ignore  two: (char *) ignore2{
	return 0xFFFFFFFF;
}
- (long long) test0longlong: (char *)ignore  two: (char *) ignore2{
		return 0xFFFFFFFFFFFFFFFFLL;
}
- (unsigned char) test0unsignedchar: (char *)ignore two: (char *) ignore2{
			return 'A';
}
- (unsigned int) test0unsignedint: (char *)ignore two: (char *) ignore2{
return 0xFFFFFFFF;
				}
				- (unsigned short) test0unsignedshort: (char *)ignore  two: (char *) ignore2{
					return 0xFFFF;
}
- (unsigned long) test0unsignedlong: (char *)ignore two: (char *) ignore2{
return 0xFFFFFFFF;
}
- (unsigned long long) test0unsignedlonglong: (char *)ignore  two: (char *) ignore2{
return 0xFFFFFFFFFFFFFFFFLL;
	}
	- (float) test0float: (char *)ignore  two: (char *) ignore2{
return 8.8f;
}
- (double) test0double: (char *)ignore  two: (char *) ignore2{
		return 8.8;
}
- (void) test0void: (char *)ignore  two: (char *) ignore2{
			}
			- (char *) test0charpointer: (char *)ignore  two: (char *) ignore2{
static char* squeak = "squeak";
				return squeak;
				}
				- (squeakSUnitTester *) test0object: (char *)ignore two: (char *) ignore2 {
				return [squeakSUnitTester new];
				}
				- (Class) test0class: (char *)ignore two: (char *) ignore2 {
				return [squeakSUnitTester class];
}
- (SEL) test0methodselector: (char *)ignore  two: (char *) ignore2 {
					SEL selector;
selector = NSSelectorFromString(
 @"initWithBitmapDataPlanes:pixelsWide:pixelsHigh:bitsPerSample:samplesPerPixel:hasAlpha:isPlanar:colorSpaceName:bytesPerRow:bitsPerPixel:");
return selector;
	 }
	 - (CGRect) test0CGRect: (char *)ignore  two: (char *) ignore2 {
CGRect foo;
foo.origin.x = 1.0;
		 foo.origin.y = 2.0;
foo.size.width = 3.0;
foo.size.height = 4.0;
return foo;
}

- (char) test0char: (char *)ignore two: (char *) ignore2 three: (char *) ignore3 {
return 'A';
}
- (int) test0int: (char *)ignore two: (char *) ignore2  three: (char *) ignore3 {
return -1;
}
- (short) test0short: (char *)ignore  two: (char *) ignore2 three: (char *) ignore3 {
	return 0xFFFF;
}
- (long) test0long: (char *)ignore  two: (char *) ignore2 three: (char *) ignore3 {
return 0xFFFFFFFF;
		}
		- (long long) test0longlong: (char *)ignore  two: (char *) ignore2 three: (char *) ignore3 {
return 0xFFFFFFFFFFFFFFFFLL;
			}
			- (unsigned char) test0unsignedchar: (char *)ignore two: (char *) ignore2 three: (char *) ignore3 {
return 'A';
}
- (unsigned int) test0unsignedint: (char *)ignore two: (char *) ignore2 three: (char *) ignore3 {
return 0xFFFFFFFF;
}
	- (unsigned short) test0unsignedshort: (char *)ignore  two: (char *) ignore2 three: (char *) ignore3 {
		return 0xFFFF;
}
- (unsigned long) test0unsignedlong: (char *)ignore two: (char *) ignore2 three: (char *) ignore3 {
return 0xFFFFFFFF;
}
- (unsigned long long) test0unsignedlonglong: (char *)ignore  two: (char *) ignore2 three: (char *) ignore3 {
return 0xFFFFFFFFFFFFFFFFLL;
}
- (float) test0float: (char *)ignore  two: (char *) ignore2 three: (char *) ignore3 {
	return 8.8f;
}
- (double) test0double: (char *)ignore  two: (char *) ignore2 three: (char *) ignore3 {
		return 8.8;
		}
		- (void) test0void: (char *)ignore  two: (char *) ignore2 three: (char *) ignore3 {
}
- (char *) test0charpointer: (char *)ignore  two: (char *) ignore2 three: (char *) ignore3 {
			static char* squeak = "squeak";
			return squeak;
			}
			- (squeakSUnitTester *) test0object: (char *)ignore two: (char *) ignore2  three: (char *) ignore3 {
return [squeakSUnitTester new];
				}
				- (Class) test0class: (char *)ignore two: (char *) ignore2  three: (char *) ignore3 {
return [squeakSUnitTester class];
}
- (SEL) test0methodselector: (char *)ignore  two: (char *) ignore2  three: (char *) ignore3 {
SEL selector;
	selector = NSSelectorFromString(
@"initWithBitmapDataPlanes:pixelsWide:pixelsHigh:bitsPerSample:samplesPerPixel:hasAlpha:isPlanar:colorSpaceName:bytesPerRow:bitsPerPixel:");
return selector;
}
- (CGRect) test0CGRect: (char *)ignore  two: (char *) ignore2  three: (char *) ignore3  {
CGRect foo;
foo.origin.x = 1.0;
	foo.origin.y = 2.0;
foo.size.width = 3.0;
foo.size.height = 4.0;
return foo;
}

- (char) test1char: (char) ignore {
return ignore;
}
- (int) test1int: (int) ignore {
return ignore;
}
- (short) test1short: (short) ignore {
return ignore;
}
- (long) test1long: (long) ignore {
	return ignore;
}
- (long long) test1longlong: (long long) ignore {
return ignore;
		}
		- (unsigned char) test1unsignedchar: (unsigned char) ignore {
			return ignore;
}
- (unsigned int) test1unsignedint: (unsigned int) ignore {
return ignore;
}
- (unsigned short) test1unsignedshort: (unsigned short) ignore {
	return ignore;
}
- (unsigned long) test1unsignedlong: (unsigned long) ignore {
return ignore;
		}
		- (unsigned long long) test1unsignedlonglong: (unsigned long long) ignore {
return ignore;
			}
			- (float) test1float: (float) ignore {
return ignore;
}
- (double) test1double: (double) ignore {
				return ignore;
				}
			- (char *) test1charpointer: (char *) ignore {
return ignore;
}
- (squeakSUnitTester *) test1object: (squeakSUnitTester *) ignore {
return ignore;
}
- (Class) test1class: (Class) ignore {
return ignore;
}
- (SEL) test1methodselector: (SEL) ignore {
return ignore;
}
- (CGRect) test1CGRect: (CGRect) ignore {
return ignore;
}

- (char) test2char: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2 {
return 'A';
}
- (int) test2int: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2 {
return -1;
}
- (short) test2short: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2{
return 0xFFFF;
}
- (long) test2long: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2{
return 0xFFFFFFFF;
	}
	- (long long) test2longlong: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2{
return 0xFFFFFFFFFFFFFFFFLL;
}
- (unsigned char) test2unsignedchar: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2{
return 'A';
}
- (unsigned int) test2unsignedint: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2{
return 0xFFFFFFFF;
}
- (unsigned short) test2unsignedshort: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2{
return 0xFFFF;
}
- (unsigned long) test2unsignedlong: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2{
	return 0xFFFFFFFF;
}
- (unsigned long long) test2unsignedlonglong: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2{
return 0xFFFFFFFFFFFFFFFFLL;
}
- (float) test2float: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2{
	return 8.8f;
	}
	- (double) test2double: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2{
	return 8.8;
	}
	- (void) test2void: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2{
}
- (char *) test2charpointer: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2{
static char* squeak = "squeak";
return squeak;
}
- (squeakSUnitTester *) test2object: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2 {
return [squeakSUnitTester new];
}
- (Class) test2class: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2 {
return [squeakSUnitTester class];
	}
	- (SEL) test2methodselector: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2 {
SEL selector;
selector = NSSelectorFromString(
		@"initWithBitmapDataPlanes:pixelsWide:pixelsHigh:bitsPerSample:samplesPerPixel:hasAlpha:isPlanar:colorSpaceName:bytesPerRow:bitsPerPixel:");
return selector;
}
- (CGRect) test2CGRect: (squeakSUnitTester *) ignore two: (squeakSUnitTester *) ignore2 {
CGRect foo;
	foo.origin.x = 1.0;
foo.origin.y = 2.0;
foo.size.width = 3.0;
foo.size.height = 4.0;
return foo;
}

- (oneway void) testQualifier0v {
		}
- (oneway void) testQualifier1v: (squeakSUnitTester *)ignore {
}
- (oneway void) testQualifier2v: (squeakSUnitTester *)ignore two:  (squeakSUnitTester *)ignore2;{
	}
	- (oneway void) testQualifier3v: (squeakSUnitTester *)ignore two:  (squeakSUnitTester *)ignore2  three: (squeakSUnitTester *)ignore3 {
}
- (squeakSUnitTester *) testQualifier1io: (inout squeakSUnitTester *)ignore {
		return ignore;
}
- (squeakSUnitTester *) testQualifier2io: (inout squeakSUnitTester *)ignore two:  (inout squeakSUnitTester *)ignore2  {
return ignore2;
}
- (squeakSUnitTester *) testQualifier3io: (inout squeakSUnitTester *)ignore two:  (inout squeakSUnitTester *)ignore2  three: (inout squeakSUnitTester *)ignore3
{
return ignore3;
}
- (squeakSUnitTester *) testQualifier1i: (in squeakSUnitTester *)ignore {
return ignore;
	}
	- (squeakSUnitTester *) testQualifier2i: (in squeakSUnitTester *)ignore two:  (in squeakSUnitTester *)ignore2  {
return ignore2;
}
- (squeakSUnitTester *) testQualifier3i: (in squeakSUnitTester *)ignore two:  (in squeakSUnitTester *)ignore2  three: (in squeakSUnitTester *)ignore3
{
return ignore3;
}
- (squeakSUnitTester *) testQualifier1o: (out squeakSUnitTester *)ignore {
return ignore;
}
- (squeakSUnitTester *) testQualifier2o: (out squeakSUnitTester *)ignore two:  (out squeakSUnitTester *)ignore2  {
return ignore2;
}
- (squeakSUnitTester *) testQualifier3o: (out squeakSUnitTester *)ignore two:  (out squeakSUnitTester *)ignore2  three: (out squeakSUnitTester *)ignore3
{
return ignore3;
}
- (squeakSUnitTester *) testQualifier1r: (inout byref  squeakSUnitTester *)ignore {
return ignore;
}
- (squeakSUnitTester *) testQualifier2r: (inout byref  squeakSUnitTester *)ignore two:  (inout byref  squeakSUnitTester *)ignore2  {
return ignore2;
}
- (squeakSUnitTester *) testQualifier3r: (inout byref  squeakSUnitTester *)ignore two:  (inout byref  squeakSUnitTester *)ignore2  three: (inout byref  squeakSUnitTester *)ignore3
{
return ignore3;
}


@end
