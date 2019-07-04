/*
 *  AlienSUnitTestProcedures.h
 *  IA32ABI
 *
 *  Created by John M McIntosh on 02/12/08.
 *  Copyright 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.

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
 

 */
#include "sqVirtualMachine.h"

#pragma export on

typedef struct ffiTestPoint2 {
int x;
int y;
} ffiTestPoint2;

typedef struct ffiTestPoint4 {
int x;
int y;
int z;
int w;
} ffiTestPoint4;

#define LONGLONG long long

EXPORT(char) ffiTestChars(char c1, char c2, char c3, char c4);
EXPORT(short) ffiTestShorts(short c1, short c2, short c3, short c4);
EXPORT(int) ffiTestInts(int c1, int c2, int c3, int c4);
EXPORT(int) ffiTestInts8(int c1, int c2, int c3, int c4, int c5, int c6, int c7, int c8);
EXPORT(float) ffiTestFloats(float f1, float f2);
EXPORT(float) ffiTestFloatAndInteger(float f1, int c1);
EXPORT(float) ffiTestIntegerAndFloat(int c1, float f1);
EXPORT(float) ffiTestFloats7(float f1, float f2, float f3, float f4, float f5, float f6, float f7);
EXPORT(float) ffiTestFloats13(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13);
EXPORT(float) ffiTestFloats14(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13, float f14);
EXPORT(double) ffiTestDoubles14(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14);
EXPORT(double) ffiTestDoubles(double d1, double d2);
EXPORT(char *) ffiPrintString(char *string);
EXPORT(ffiTestPoint2) ffiTestStruct64(ffiTestPoint2 pt1, ffiTestPoint2 pt2);
EXPORT(ffiTestPoint4) ffiTestStructBig(ffiTestPoint4 pt1, ffiTestPoint4 pt2);
EXPORT(ffiTestPoint4*) ffiTestPointers(ffiTestPoint4 *pt1, ffiTestPoint4 *pt2);
EXPORT(LONGLONG) ffiTestLongLong(LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLong8(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLong9a1(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9, LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLong10a2(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9,  char c10, LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLonga1(char c1, LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLonga2(char c1, char c2, LONGLONG i1, LONGLONG i2);
#pragma export off

