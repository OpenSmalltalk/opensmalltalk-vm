/* last edited: 2003-01-29 21:48:36 by piumarta on emilia.inria.fr
 */

#if !defined(NO_FFI_TEST)

#include <stdio.h>
#include <stdlib.h>

#if !defined(LONGLONG)
# define LONGLONG long long
#endif

#if 0
# define DPRINTF(ARGS) printf ARGS
#else
# define DPRINTF(ARGS)
#endif

#include "ffi-test.h"


char ffiTestChars(char c1, char c2, char c3, char c4)
{
  DPRINTF(("4 characters came in as\nc1 = %c (%x)\nc2 = %c (%x)\nc3 = %c (%x)\nc4 = %c (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4));
  return 'C';
}


short ffiTestShorts(short c1, short c2, short c3, short c4)
{
  DPRINTF(("4 shorts came in as\ns1 = %d (%x)\ns2 = %d (%x)\ns3 = %d (%x)\ns4 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4));
  return -42;
}


int ffiTestInts(int c1, int c2, int c3, int c4)
{
  DPRINTF(("4 ints came in as\ni1 = %d (%x)\ni2 = %d (%x)\ni3 = %d (%x)\ni4 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4));
  return 42;
}


int ffiTestInts8(int c1, int c2, int c3, int c4, int c5, int c6, int c7, int c8)
{
  DPRINTF(("4 ints came in as\ni1 = %d (%x)\ni2 = %d (%x)\ni3 = %d (%x)\ni4 = %d (%x)\ni5 = %d (%x)\ni6 = %d (%x)\ni7 = %d (%x)\ni8 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4, c5, c5, c6, c6, c7, c7, c8, c8));
  return 42;
}


int ffiTestInts9(int c1, int c2, int c3, int c4, int c5, int c6, int c7, int c8, int c9)
{
  DPRINTF(("4 ints came in as\ni1 = %d (%x)\ni2 = %d (%x)\ni3 = %d (%x)\ni4 = %d (%x)\ni5 = %d (%x)\ni6 = %d (%x)\ni7 = %d (%x)\ni8 = %d (%x)\ni9 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4, c5, c5, c6, c6, c7, c7, c8, c8, c9, c9));
  return 42;
}


float ffiTestFloats(float f1, float f2)
{
  DPRINTF(("The two floats are %f and %f\n", (double)f1, (double)f2));
  return (float) (f1 + f2);
}


float ffiTestFloats7(float f1, float f2, float f3, float f4, float f5, float f6, float f7)
{
  DPRINTF(("The 7 floats are %f %f %f %f %f %f %f\n", (double)f1, (double)f2, (double)f3, (double)f4, (double)f5, (double)f6, (double)f7));
  return (float) (f1 + f2 + f3 + f4 + f5 + f6 + f7);
}


float ffiTestFloats13(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13)
{
  DPRINTF(("The 13 floats are %f %f %f %f %f %f %f %f %f %f %f %f %f\n", (double)f1, (double)f2, (double)f3, (double)f4, (double)f5, (double)f6, (double)f7, (double)f8, (double)f9, (double)f10, (double)f11, (double)f12, (double)f13));
  return (float) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13);
}


float ffiTestFloats15(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13, float f14, float f15)
{
  DPRINTF(("The 15 floats are %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f\n", (double)f1, (double)f2, (double)f3, (double)f4, (double)f5, (double)f6, (double)f7, (double)f8, (double)f9, (double)f10, (double)f11, (double)f12, (double)f13, (double)f14, (double)f15));
  return (float) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13 + f14 + f15);
}


double ffiTestDoubles(double d1, double d2)
{
  DPRINTF(("The two doubles are %f and %f\n", d1, d2));
  return d1+d2;
}


double ffiTestDoubles15(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14, double f15)
{
  DPRINTF(("The 15 doubles are %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15));
  return (double) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13 + f14 + f15);
}


char *ffiPrintString(char *string)
{
  DPRINTF(("%s\n", string));
  return string;
}


ffiTestPoint2 ffiTestStruct64(ffiTestPoint2 pt1, ffiTestPoint2 pt2)
{
  ffiTestPoint2 result;
  DPRINTF(("pt1.x = %d\npt1.y = %d\npt2.x = %d\npt2.y = %d\n",
	 pt1.x, pt1.y, pt2.x, pt2.y));
  result.x = pt1.x + pt2.x;
  result.y = pt1.y + pt2.y;
  return result;
}


ffiTestPoint4 ffiTestStructBig(ffiTestPoint4 pt1, ffiTestPoint4 pt2)
{
  ffiTestPoint4 result;
  DPRINTF(("pt1.x = %d\npt1.y = %d\npt1.z = %d\npt1.w = %d\n",
	 pt1.x, pt1.y, pt1.z, pt1.w));
  DPRINTF(("pt2.x = %d\npt2.y = %d\npt2.z = %d\npt2.w = %d\n",
	 pt2.x, pt2.y, pt2.z, pt2.w));
  result.x = pt1.x + pt2.x;
  result.y = pt1.y + pt2.y;
  result.z = pt1.z + pt2.z;
  result.w = pt1.w + pt2.w;
  return result;
}


ffiTestPoint4 *ffiTestPointers(ffiTestPoint4 *pt1, ffiTestPoint4 *pt2)
{
  ffiTestPoint4 *result;
  DPRINTF(("pt1.x = %d\npt1.y = %d\npt1.z = %d\npt1.w = %d\n",
	 pt1->x, pt1->y, pt1->z, pt1->w));
  DPRINTF(("pt2.x = %d\npt2.y = %d\npt2.z = %d\npt2.w = %d\n",
	 pt2->x, pt2->y, pt2->z, pt2->w));
  result = (ffiTestPoint4*) malloc(sizeof(ffiTestPoint4));
  result->x = pt1->x + pt2->x;
  result->y = pt1->y + pt2->y;
  result->z = pt1->z + pt2->z;
  result->w = pt1->w + pt2->w;
  return result;
}


LONGLONG ffiTestLongLong(LONGLONG i1, LONGLONG i2)
{
  DPRINTF(("longlong %lld %lld\n", i1, i2));
  return i1 + i2;
}


#endif /* !NO_FFI_TEST */
