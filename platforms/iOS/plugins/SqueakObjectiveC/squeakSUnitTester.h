//
//  squeakSUnitTester.h
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
//

@interface squeakSUnitTester : NSObject 
	- (char) test0char;
- (int) test0int;
- (short) test0short;
- (long) test0long;
- (long long) test0longlong;
- (unsigned char) test0unsignedchar;
- (unsigned int) test0unsignedint;
- (unsigned short) test0unsignedshort;
- (unsigned long) test0unsignedlong;
- (unsigned long long) test0unsignedlonglong;
- (float) test0float;
- (double) test0double;
- (void) test0void;
- (char *) test0charpointer;
- (squeakSUnitTester *) test0object;
- (Class) test0class;
- (SEL) test0methodselector;
- (CGRect) test0CGRect;

- (char) test0char: (char *) ignore;
- (int) test0int: (char *) ignore;
- (short) test0short: (char *) ignore;
- (long) test0long: (char *) ignore;
- (long long) test0longlong: (char *) ignore;
- (unsigned char) test0unsignedchar: (char *) ignore;
- (unsigned int) test0unsignedint: (char *) ignore;
- (unsigned short) test0unsignedshort: (char *) ignore;
- (unsigned long) test0unsignedlong: (char *) ignore;
- (unsigned long long) test0unsignedlonglong: (char *) ignore;
- (float) test0float: (char *) ignore;
- (double) test0double: (char *) ignore;
- (void) test0void: (char *) ignore;
- (char *) test0charpointer: (char *) ignore;
- (squeakSUnitTester *) test0object: (char *) ignore;
- (Class) test0class: (char *) ignore;
- (SEL) test0methodselector: (char *) ignore;
- (CGRect) test0CGRect: (char *) ignore;

- (char) test0char: (char *) ignore two: (char *) ignore2;
	- (int) test0int: (char *) ignore two: (char *) ignore2;
	   - (short) test0short: (char *) ignore two: (char *) ignore2;
- (long) test0long: (char *) ignore two: (char *) ignore2;
- (long long) test0longlong: (char *) ignore two: (char *) ignore2;
- (unsigned char) test0unsignedchar: (char *) ignore two: (char *) ignore2;
- (unsigned int) test0unsignedint: (char *) ignore two: (char *) ignore2;
- (unsigned short) test0unsignedshort: (char *) ignore two: (char *) ignore2;
- (unsigned long) test0unsignedlong: (char *) ignore two: (char *) ignore2;
- (unsigned long long) test0unsignedlonglong: (char *) ignore two: (char *) ignore2;
- (float) test0float: (char *) ignore two: (char *) ignore2;
- (double) test0double: (char *) ignore two: (char *) ignore2;
- (void) test0void: (char *) ignore two: (char *) ignore2;
- (char *) test0charpointer: (char *) ignore two: (char *) ignore2;
- (squeakSUnitTester *) test0object: (char *) ignore two: (char *) ignore2;
- (Class) test0class: (char *) ignore two: (char *) ignore2;
- (SEL) test0methodselector: (char *) ignore two: (char *) ignore2;
- (CGRect) test0CGRect: (char *) ignore two: (char *) ignore2;
											  
											  - (char) test0char: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (int) test0int: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (short) test0short: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (long) test0long: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (long long) test0longlong: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
																		   - (unsigned char) test0unsignedchar: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (unsigned int) test0unsignedint: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (unsigned short) test0unsignedshort: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
																					 - (unsigned long) test0unsignedlong: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (unsigned long long) test0unsignedlonglong: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (float) test0float: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (double) test0double: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (void) test0void: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (char *) test0charpointer: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
																		   - (squeakSUnitTester *) test0object: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (Class) test0class: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (SEL) test0methodselector: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;
- (CGRect) test0CGRect: (char *) ignore two: (char *) ignore2 three: (char *) ignore3;

- (char) test1char: (char) ignore;
- (int) test1int: (int) ignore;
- (short) test1short: (short) ignore;
- (long) test1long: (long) ignore;
- (long long) test1longlong: (long long) ignore;
- (unsigned char) test1unsignedchar: (unsigned char) ignore;
- (unsigned int) test1unsignedint: (unsigned int) ignore;
- (unsigned short) test1unsignedshort: (unsigned short) ignore;
- (unsigned long) test1unsignedlong: (unsigned long) ignore;
- (unsigned long long) test1unsignedlonglong: (unsigned long long) ignore;
- (float) test1float: (float) ignore;
- (double) test1double: (double) ignore;
- (char *) test1charpointer: (char *) ignore;
- (squeakSUnitTester *) test1object: (squeakSUnitTester *) ignore;
- (Class) test1class: (Class) ignore;
- (SEL) test1methodselector: (SEL) ignore;
- (CGRect) test1CGRect: (CGRect) ignore;

- (char) test2char: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2;
- (int) test2int: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2;
- (short) test2short: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2;
- (long) test2long: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2;
- (long long) test2longlong: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2;
- (unsigned char) test2unsignedchar: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2;
- (unsigned int) test2unsignedint: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2;
- (unsigned short) test2unsignedshort: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2;
- (unsigned long) test2unsignedlong: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2;
- (unsigned long long) test2unsignedlonglong: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2;
- (float) test2float: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2;
- (double) test2double: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2;
- (void) test2void: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2;
- (char *) test2charpointer: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2;
- (squeakSUnitTester *) test2object: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2;
- (Class) test2class: (squeakSUnitTester *)ignore two: (squeakSUnitTester *) ignore2;
- (SEL) test2methodselector: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2 ;
- (CGRect) test2CGRect: (squeakSUnitTester *)ignore  two: (squeakSUnitTester *) ignore2 ;

- (oneway void) testQualifier0v;
- (oneway void) testQualifier1v: (squeakSUnitTester *)ignore;
- (oneway void) testQualifier2v: (squeakSUnitTester *)ignore two:  (squeakSUnitTester *)ignore2;
- (oneway void) testQualifier3v: (squeakSUnitTester *)ignore two:  (squeakSUnitTester *)ignore2  three: (squeakSUnitTester *)ignore3;
- (squeakSUnitTester *) testQualifier1io: (inout squeakSUnitTester *)ignore;
- (squeakSUnitTester *) testQualifier2io: (inout squeakSUnitTester *)ignore two:  (inout squeakSUnitTester *)ignore2;
- (squeakSUnitTester *) testQualifier3io: (inout squeakSUnitTester *)ignore two:  (inout squeakSUnitTester *)ignore2  three: (inout squeakSUnitTester *)ignore3;
- (squeakSUnitTester *) testQualifier1i: (in squeakSUnitTester *)ignore;
- (squeakSUnitTester *) testQualifier2i: (in squeakSUnitTester *)ignore two:  (in squeakSUnitTester *)ignore2;
- (squeakSUnitTester *) testQualifier3i: (in squeakSUnitTester *)ignore two:  (in squeakSUnitTester *)ignore2  three: (in squeakSUnitTester *)ignore3;
- (squeakSUnitTester *) testQualifier1o: (out squeakSUnitTester *)ignore;
- (squeakSUnitTester *) testQualifier2o: (out squeakSUnitTester *)ignore two:  (out squeakSUnitTester *)ignore2;
- (squeakSUnitTester *) testQualifier3o: (out squeakSUnitTester *)ignore two:  (out squeakSUnitTester *)ignore2  three: (out squeakSUnitTester *)ignore3;
- (squeakSUnitTester *) testQualifier1r: (inout byref squeakSUnitTester *)ignore;
- (squeakSUnitTester *) testQualifier2r: (inout byref  squeakSUnitTester *)ignore two:  (inout byref  squeakSUnitTester *)ignore2;
- (squeakSUnitTester *) testQualifier3r: (inout byref  squeakSUnitTester *)ignore two:  (inout byref  squeakSUnitTester *)ignore2  three: (inout byref  squeakSUnitTester *)ignore3;

@end
