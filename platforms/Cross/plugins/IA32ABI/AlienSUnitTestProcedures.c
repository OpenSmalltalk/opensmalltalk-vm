/*
 *  AlienSUnitTestProcedures.c
 *  IA32ABI
 *
 *  Created by John M McIntosh on 02/12/08.

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


*
 */
#include "sq.h"

#include "AlienSUnitTestProcedures.h"

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/************ Test functions for the foreign function interface **************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

/* test passing characters */
EXPORT(char) ffiTestChars(char c1, char c2, char c3, char c4) {
printf("4 characters came in as\nc1 = %c (%x)\nc2 = %c (%x)\nc3 = %c (%x)\nc4 = %c (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4);
return c1+c2+c3+c4;
}

/* test passing shorts */
EXPORT(short) ffiTestShorts(short c1, short c2, short c3, short c4) {
printf("4 shorts came in as\ns1 = %d (%x)\ns2 = %d (%x)\ns3 = %d (%x)\ns4 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4);
return  c1+c2+c3+c4;
}

/* test passing ints */
EXPORT(int) ffiTestInts(int c1, int c2, int c3, int c4) {
printf("4 ints came in as\ni1 = %d (%x)\ni2 = %d (%x)\ni3 = %d (%x)\ni4 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4);
return  c1+c2+c3+c4;
}

EXPORT(int) ffiTestInts8(int c1, int c2, int c3, int c4, int c5, int c6, int c7, int c8) {
printf("8 ints came in as\ni1 = %d (%x)\ni2 = %d (%x)\ni3 = %d (%x)\ni4 = %d (%x)\ni5 = %d (%x)\ni6 = %d (%x)\ni7 = %d (%x)\ni8 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4, c5, c5, c6, c6, c7, c7, c8, c8);
return  c1+c2+c3+c4+c5+c6+c7+c8;
}


/* test passing and returning floats */
EXPORT(float) ffiTestFloats(float f1, float f2) {
printf("The two floats are %f and %f\n", f1, f2);
return (float) (f1 + f2);
}

/* test passing and returning float & integer */
EXPORT(float) ffiTestFloatAndInteger(float f1, int c1) {
	printf("The float  %f and integer %i\n", f1, c1);
	return (float) (f1 + c1);
}

EXPORT(float) ffiTestIntegerAndFloat(int c1, float f1) {
	printf("The integer %i and float  %f\n", c1, f1);
	return (float) (f1 + c1);
}

EXPORT(float) ffiTestFloats7(float f1, float f2, float f3, float f4, float f5, float f6, float f7) {
printf("The 7 floats are %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7);
return (float) (f1 + f2 + f3 + f4 + f5 + f6 + f7);
}

EXPORT(float) ffiTestFloats13(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13) {
printf("The 13 floats are %f %f %f %f %f %f %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13);
return (float) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13);
}

EXPORT(float) ffiTestFloats14(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13, float f14) {
printf("The 14 floats are %f %f %f %f %f %f %f %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14);
return (float) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13 + f14);
}

EXPORT(double) ffiTestDoubles14(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14) {
printf("The 14 double are %f %f %f %f %f %f %f %f %f %f %f %f %f %f \n", f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14);
return (double) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13 + f14);
}

/* test passing and returning doubles */
EXPORT(double) ffiTestDoubles(double d1, double d2) {
printf("The two floats are %f and %f\n", (float)d1, (float)d2);
return d1+d2;
}

/* test passing and returning strings */
EXPORT(char*) ffiPrintString(char *string) {
printf("%s\n", string);
return string;
}

/* test passing and returning 64bit structures */
EXPORT(ffiTestPoint2) ffiTestStruct64(ffiTestPoint2 pt1, ffiTestPoint2 pt2) {
ffiTestPoint2 result;
printf("pt1.x = %d\npt1.y = %d\npt2.x = %d\npt2.y = %d\n",
pt1.x, pt1.y, pt2.x, pt2.y);
result.x = pt1.x + pt2.x;
result.y = pt1.y + pt2.y;
return result;
}

/* test passing and returning large structures */
EXPORT(ffiTestPoint4) ffiTestStructBig(ffiTestPoint4 pt1, ffiTestPoint4 pt2) {
ffiTestPoint4 result;
printf("pt1.x = %d\npt1.y = %d\npt1.z = %d\npt1.w = %d\n",
pt1.x, pt1.y, pt1.z, pt1.w);
printf("pt2.x = %d\npt2.y = %d\npt2.z = %d\npt2.w = %d\n",
pt2.x, pt2.y, pt2.z, pt2.w);
result.x = pt1.x + pt2.x;
result.y = pt1.y + pt2.y;
result.z = pt1.z + pt2.z;
result.w = pt1.w + pt2.w;
return result;
}

/* test passing and returning pointers */
EXPORT(ffiTestPoint4*) ffiTestPointers(ffiTestPoint4 *pt1, ffiTestPoint4 *pt2) {
ffiTestPoint4 *result;
printf("pt1.x = %d\npt1.y = %d\npt1.z = %d\npt1.w = %d\n",
pt1->x, pt1->y, pt1->z, pt1->w);
printf("pt2.x = %d\npt2.y = %d\npt2.z = %d\npt2.w = %d\n",
pt2->x, pt2->y, pt2->z, pt2->w);
result = (ffiTestPoint4*) malloc(sizeof(ffiTestPoint4));
result->x = pt1->x + pt2->x;
result->y = pt1->y + pt2->y;
result->z = pt1->z + pt2->z;
result->w = pt1->w + pt2->w;
return result;
}

/* test passing and returning longlongs */
EXPORT(LONGLONG) ffiTestLongLong(LONGLONG i1, LONGLONG i2) {
return i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLonga1(char c1, LONGLONG i1, LONGLONG i2) {
return c1 + i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLonga2(char c1, char c2, LONGLONG i1, LONGLONG i2) {
return c1 + c2 + i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLong8(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, LONGLONG i1, LONGLONG i2) {
return c1+c2+c3+c4+c5+c6+c7+c8+i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLong9a1(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9, LONGLONG i1, LONGLONG i2) {
return c1+c2+c3+c4+c5+c6+c7+c8+c9+i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLong10a2(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9, char c10, LONGLONG i1, LONGLONG i2) {
return c1+c2+c3+c4+c5+c6+c7+c8+c9+c10+i1 + i2;
}
