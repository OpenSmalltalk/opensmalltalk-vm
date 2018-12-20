/* ffi-test-main.c -- try hard to break the FFI from C
 * 
 * Author: Ian.Piumarta@INRIA.Fr
 * 
 * Based on a similar test suite in libffi, which contains the following text...
 * 
 * Copyright (c) 1996, 1997, 1998, 2002, 2003  Red Hat, Inc.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * ``Software''), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL CYGNUS SOLUTIONS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <float.h>

#include "sqFFI.h"

#if 0
# define DPRINTF(ARGS)	printf ARGS
# define puts(ARG)	puts(ARG)
#else
# define DPRINTF(ARGS)
# define puts(ARG)
#endif

#if 1
# define long_double double
# define Lf "f"
#else
# define long_double long double
# define Lf "Lf"
#endif

#define CHECK(x) !(x) ? fail(__FILE__, __LINE__) : 0 

static int failed= 0;

static int fail(char *file, int line)
{
  fprintf(stderr, "%s: failed at line %d\n", file, line);
  ++failed;
//exit(EXIT_FAILURE);
  return 0;
}

#define MAX_ARGS 256

static size_t my_strlen(char *s)	{ return strlen(s); }

static int promotion(signed char sc, signed short ss, unsigned char uc, unsigned short us)
{
  int r= (int)sc + (int)ss + (int)uc + (int)us;
  return r;
}

static signed char return_sc(signed char sc)		{ return sc; }
static unsigned char return_uc(unsigned char uc)	{ return uc; }
static long long return_ll(long long ll)		{ return ll; }

static int floating(int a, float b, double c, long_double d, int e)
{
  int i;
  DPRINTF(("%d %f %f %"Lf" %d\n", a, (double)b, c, d, e));
  i= (int)((float)a/b + ((float)c/(float)d));
  return i;
}

static float many(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13, float f14, float f15)
{
  DPRINTF(("%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f\n",
	 (double)f1, (double)f2, (double)f3, (double)f4, (double)f5, 
	 (double)f6, (double)f7, (double)f8, (double)f9, (double)f10,
	 (double)f11, (double)f12, (double)f13, (double)f14, (double)f15));
  return ((f1/f2+f3/f4+f5/f6+f7/f8+f9/f10+f11/f12+f13/f14) * f15);
}

static double dblit(float f)		{ return f/3.0; }
static long_double ldblit(float f)	{ return (long_double)(((long_double)f)/ (long_double)3.0); }


#define TYPE(T,S)	((FFIType##T << FFIAtomicTypeShift) | (S) | FFIFlagAtomic)

typedef struct { unsigned char uc;  double d;  unsigned int ui; } test_structure_1;

static int spec_structure_1[]= {
  FFIFlagStructure | sizeof(test_structure_1),
  TYPE(UnsignedChar,4), TYPE(DoubleFloat,8), TYPE(UnsignedInt,4)
};

static test_structure_1 struct1(test_structure_1 ts)
{
  DPRINTF(("%d %f %d\n", ts.uc, ts.d, ts.ui));
  ts.uc++;  ts.d--;  ts.ui++;  return ts;
}

typedef struct { double d1;  double d2;} test_structure_2;

static int spec_structure_2[]= {
  FFIFlagStructure | sizeof(test_structure_2),
  TYPE(DoubleFloat,8), TYPE(DoubleFloat,8)
};

static test_structure_2 struct2(test_structure_2 ts)
{
  ts.d1--;  ts.d2--;  return ts;
}

typedef struct { int si; } test_structure_3;

static int spec_structure_3[]= {
  FFIFlagStructure | sizeof(test_structure_3),
  TYPE(SignedInt,4)
};

static test_structure_3 struct3(test_structure_3 ts)
{
  ts.si= -(ts.si*2);  return ts;
}

typedef struct { unsigned ui1;  unsigned ui2;  unsigned ui3; } test_structure_4;

static int spec_structure_4[]= {
  FFIFlagStructure | sizeof(test_structure_4),
  TYPE(UnsignedInt,4), TYPE(UnsignedInt,4), TYPE(UnsignedInt,4)
};

static test_structure_4 struct4(test_structure_4 ts)
{
  ts.ui3= ts.ui1 * ts.ui2 * ts.ui3; return ts;
}

typedef struct { char c1;  char c2; } test_structure_5;

static int spec_structure_5[]= {
  FFIFlagStructure | sizeof(test_structure_5),
  TYPE(SignedChar,1), TYPE(SignedChar,1)
};

static test_structure_5 struct5(test_structure_5 ts1, test_structure_5 ts2)
{
  DPRINTF(("%d %d %d %d\n", ts1.c1, ts1.c2, ts2.c1, ts2.c2));
  ts1.c1 += ts2.c1;  ts1.c2 -= ts2.c2; return ts1;
}

typedef struct { float f;  double d; } test_structure_6;

static int spec_structure_6[]= {
  FFIFlagStructure | sizeof(test_structure_6),
  TYPE(SingleFloat,4), TYPE(DoubleFloat,8)
};

static test_structure_6 struct6 (test_structure_6 ts)
{
  ts.f += 1;  ts.d += 1;  return ts;
}

typedef struct { float f1;  float f2;  double d; } test_structure_7;

static int spec_structure_7[]= {
  FFIFlagStructure | sizeof(test_structure_7),
  TYPE(SingleFloat,4), TYPE(SingleFloat,4), TYPE(DoubleFloat,8)
};

static test_structure_7 struct7 (test_structure_7 ts)
{
  ts.f1 += 1;  ts.f2 += 1;  ts.d += 1;  return ts;
}

typedef struct { float f1;  float f2;  float f3;  float f4; } test_structure_8;

static int spec_structure_8[]= {
  FFIFlagStructure | sizeof(test_structure_8),
  TYPE(SingleFloat,4), TYPE(SingleFloat,4), TYPE(SingleFloat,4), TYPE(SingleFloat,4)
};

static test_structure_8 struct8 (test_structure_8 ts)
{
  ts.f1 += 1; ts.f2 += 1; ts.f3 += 1; ts.f4 += 1;  return ts;
}

typedef struct { float f;  int i; } test_structure_9;

static int spec_structure_9[]= {
  FFIFlagStructure | sizeof(test_structure_9),
  TYPE(SingleFloat,4), TYPE(SignedInt,4)
};

static test_structure_9 struct9 (test_structure_9 ts)
{
  ts.f += 1;  ts.i += 1;  return ts;
}

#define SPEC(S)	spec_##S, (sizeof(spec_##S) / sizeof(int))

#define GO(T,F)	ffiCallAddressOfWithReturnType((int)(F), FFICallTypeCDecl, \
					       (T) << FFIAtomicTypeShift)

#define GOS(S,F) ffiCallAddressOfWithStructReturn((int)(F), FFICallTypeCDecl, SPEC(S))

void ctests(void)
{
  CHECK(sizeof(char) == 1);
  CHECK(sizeof(short) == 2);
  CHECK(sizeof(int) == 4);
  CHECK(sizeof(long) == 4);
  CHECK(sizeof(long long) == 8);
  CHECK(sizeof(float) == 4);
  CHECK(sizeof(double) == 8);
  CHECK(sizeof(long_double) == 8);	//xxx BOGUS BOGUS BOGUS BOGUS BOGUS

  puts("long long tests...");
  {
    long long ll, rll;
    for (ll= 0LL;  ll < 100LL;  ++ll)
      {
	ffiInitialize();
	ffiPushSignedLongLong(ll % 0x100000000, ll / 0x100000000);
	GO(FFITypeSignedLongLong, return_ll);
	rll= ffiLongLongResultHigh() * 0x100000000LL + ffiLongLongResultLow();
	ffiCleanup();
	DPRINTF(("%lld %lld\n", ll, rll));
	CHECK(rll == ll);
      }

    for (ll= 55555555555000LL; ll < 55555555555100LL; ll++)
      {
	ffiInitialize();
	ffiPushSignedLongLong(ll % 0x100000000, ll / 0x100000000);
	GO(FFITypeSignedLongLong, return_ll);
	rll= ffiLongLongResultHigh() * 0x100000000LL + ffiLongLongResultLow();
	ffiCleanup();
	CHECK(rll == ll);
      }
  }
  puts("char tests...");
  {
    signed char sc;
    unsigned char uc;
    int rint;
    for (sc= (signed char)-127;  sc < (signed char)127;  ++sc)
      {
	ffiInitialize();
	ffiPushSignedChar(sc);
	rint= GO(FFITypeSignedInt, return_sc);
	ffiCleanup();
	CHECK(rint == (int)sc);
      }
    for (uc= (unsigned char)'\x00';  uc < (unsigned char)'\xff';  ++uc)
      {
	ffiInitialize();
	ffiPushUnsignedChar(uc);
	rint= GO(FFITypeSignedInt, return_uc);
	ffiCleanup();
	CHECK(rint == (int)uc);
      }
  }
  puts("long double tests...");
  {
    float f= 3.14159;
    long_double ld;

    DPRINTF(("%"Lf"\n", ldblit(f)));
    ld= 666;
    ffiInitialize();
    ffiPushSingleFloat(f);
    GO(FFITypeDoubleFloat, ldblit);
    ld= ffiReturnFloatValue();
    ffiCleanup();
    DPRINTF(("%"Lf", %"Lf", %"Lf", %"Lf"\n", ld, ldblit(f), ld - ldblit(f), (long_double)LDBL_EPSILON));
    /* These are not always the same!! Check for a reasonable delta */
    CHECK(ld - ldblit(f) < LDBL_EPSILON);
  }
  puts("float arg tests...");
  {
    int si1= 6;
    float f= 3.14159;
    double d= (double)1.0/(double)3.0;
    long_double ld= 2.71828182846L;
    int si2= 10;
    int rint;
    floating(si1, f, d, ld, si2);
    ffiInitialize();
    ffiPushSignedInt(si1);
    ffiPushSingleFloat(f);
    ffiPushDoubleFloat(d);
    ffiPushDoubleFloat(ld);
    ffiPushSignedInt(si2);
    rint= GO(FFITypeSignedInt, floating);
    ffiCleanup();
    DPRINTF(("%d vs %d\n", (int)rint, floating(si1, f, d, ld, si2)));
    CHECK(rint == floating(si1, f, d, ld, si2));
  }
  puts("double return tests...");
  {
    float f= 3.14159;
    double d;
    ffiInitialize();
    ffiPushSingleFloat(f);
    GO(FFITypeDoubleFloat, dblit);
    d= ffiReturnFloatValue();
    ffiCleanup();
    CHECK(d - dblit(f) < DBL_EPSILON);
  }
  puts("strlen tests...");
  {
    char *s= "a";
    int rint;
    ffiInitialize();
    ffiPushPointer((int)s);
    rint= GO(FFITypeSignedInt, my_strlen);
    ffiCleanup();
    CHECK(rint == 1);
    s= "1234567";
    ffiInitialize();
    ffiPushPointer((int)s);
    rint= GO(FFITypeSignedInt, my_strlen);
    ffiCleanup();
    CHECK(rint == 7);
    s= "1234567890123456789012345";
    ffiInitialize();
    ffiPushPointer((int)s);
    rint= GO(FFITypeSignedInt, my_strlen);
    ffiCleanup();
    CHECK(rint == 25);
  }
  puts("many arg tests...");
  {
    unsigned long ul;
    float f, ff;
    float fa[15];
    
    for (ul= 0;  ul < 15;  ++ul)
      fa[ul]= (float)ul;

    ff= many(fa[0], fa[1], fa[2], fa[3], fa[4], fa[5], fa[6], fa[7], fa[8], fa[9], fa[10], fa[11], fa[12], fa[13], fa[14]);

    ffiInitialize();
    for (ul= 0;  ul < 15;  ++ul)
      ffiPushSingleFloat(fa[ul]);
    GO(FFITypeSingleFloat, many);
    f= ffiReturnFloatValue();
    ffiCleanup();
    CHECK(f - ff < FLT_EPSILON);
  }
  puts("promotion tests...");
  {
    signed char sc;
    unsigned char uc;
    signed short ss;
    unsigned short us;
    int rint;
    for (sc= (signed char)-127;  sc <= (signed char)120;  sc += 1)
      for (ss= -30000;  ss <= 30000;  ss += 10000)
	for (uc= (unsigned char)0;  uc <= (unsigned char)200;  uc += 20)
	  for (us= 0;  us <= 60000;  us += 10000)
	    {
	      ffiInitialize();
	      ffiPushSignedChar(sc);
	      ffiPushSignedShort(ss);
	      ffiPushUnsignedChar(uc);
	      ffiPushUnsignedShort(us);
	      rint= GO(FFITypeSignedInt, promotion);
	      ffiCleanup();
	      CHECK((int)rint == (signed char)sc + (signed short)ss
		    + (unsigned char)uc + (unsigned short)us);
	    }
  }
  puts("struct tests...");
  {
    test_structure_1 ts1_arg, ts1_result;
    ts1_arg.uc= '\x01';
    ts1_arg.d= 3.14159;
    ts1_arg.ui= 555;
    ffiInitialize();
    CHECK(ffiCanReturn(SPEC(structure_1)));
    ffiPushStructureOfLength((int)&ts1_arg, SPEC(structure_1));
    GOS(structure_1, struct1);
    ffiStoreStructure((int)&ts1_result, sizeof(ts1_result));
    ffiCleanup();
    DPRINTF(("%d %g\n", ts1_result.ui, ts1_result.d));
    CHECK(ts1_result.ui == 556);
    CHECK(ts1_result.d == 3.14159 - 1);
  }
  {
    test_structure_2 ts2_arg, ts2_result;
    ts2_arg.d1= 5.55;
    ts2_arg.d2= 6.66;
    DPRINTF(("%g\n", ts2_result.d1));	/*xxx this is junk!*/
    DPRINTF(("%g\n", ts2_result.d2));
    ffiInitialize();
    CHECK(ffiCanReturn(SPEC(structure_2)));
    ffiPushStructureOfLength((int)&ts2_arg, SPEC(structure_2));
    GOS(structure_2, struct2);
    ffiStoreStructure((int)&ts2_result, sizeof(ts2_result));
    ffiCleanup();
    DPRINTF(("%g\n", ts2_result.d1));
    DPRINTF(("%g\n", ts2_result.d2));
    CHECK(ts2_result.d1 == 5.55 - 1);
    CHECK(ts2_result.d2 == 6.66 - 1);
  }
  {
    int compare_value;
    test_structure_3 ts3_arg, ts3_result;
    ts3_arg.si= -123;
    compare_value= ts3_arg.si;
    ffiInitialize();
    CHECK(ffiCanReturn(SPEC(structure_3)));
    ffiPushStructureOfLength((int)&ts3_arg, SPEC(structure_3));
    GOS(structure_3, struct3);
    ffiStoreStructure((int)&ts3_result, sizeof(ts3_result));
    ffiCleanup();
    DPRINTF(("%d %d\n", ts3_result.si, -(compare_value*2)));
    CHECK(ts3_result.si == -(ts3_arg.si*2));
  }
  {
    test_structure_4 ts4_arg, ts4_result;
    ts4_arg.ui1= 2;
    ts4_arg.ui2= 3;
    ts4_arg.ui3= 4;
    ffiInitialize();
    CHECK(ffiCanReturn(SPEC(structure_4)));
    ffiPushStructureOfLength((int)&ts4_arg, SPEC(structure_4));
    GOS(structure_4, struct4);
    ffiStoreStructure((int)&ts4_result, sizeof(ts4_result));
    ffiCleanup();
    CHECK(ts4_result.ui3 == 2U * 3U * 4U);
  }
  {
    test_structure_5 ts5_arg1, ts5_arg2, ts5_result;
    ts5_arg1.c1= 2;
    ts5_arg1.c2= 6;
    ts5_arg2.c1= 5;
    ts5_arg2.c2= 3;
    struct5(ts5_arg1, ts5_arg2);
    ts5_arg1.c1= 2;
    ts5_arg1.c2= 6;
    ts5_arg2.c1= 5;
    ts5_arg2.c2= 3;
    ffiInitialize();
    CHECK(ffiCanReturn(SPEC(structure_5)));
    ffiPushStructureOfLength((int)&ts5_arg1, SPEC(structure_5));
    ffiPushStructureOfLength((int)&ts5_arg2, SPEC(structure_5));
    GOS(structure_5, struct5);
    ffiStoreStructure((int)&ts5_result, sizeof(ts5_result));
    ffiCleanup();
    DPRINTF(("%d %d\n", ts5_result.c1, ts5_result.c2));
    CHECK(ts5_result.c1 == 7 && ts5_result.c2 == 3);
  }
  {
    test_structure_6 ts6_arg, ts6_result;
    ts6_arg.f= 5.55f;
    ts6_arg.d= 6.66;
    DPRINTF(("%g\n", ts6_arg.f));
    DPRINTF(("%g\n", ts6_arg.d));
    ffiInitialize();
    CHECK(ffiCanReturn(SPEC(structure_6)));
    ffiPushStructureOfLength((int)&ts6_arg, SPEC(structure_6));
    GOS(structure_6, struct6);
    ffiStoreStructure((int)&ts6_result, sizeof(ts6_result));
    ffiCleanup();
    DPRINTF(("%g\n", ts6_result.f));
    DPRINTF(("%g\n", ts6_result.d));
    CHECK(ts6_result.f == 5.55f + 1);
    CHECK(ts6_result.d == 6.66 + 1);
  }
  {
    test_structure_7 ts7_arg, ts7_result;
    ts7_arg.f1= 5.55f;
    ts7_arg.f2= 55.5f;
    ts7_arg.d= 6.66;
    DPRINTF(("%g\n", ts7_arg.f1));
    DPRINTF(("%g\n", ts7_arg.f2));
    DPRINTF(("%g\n", ts7_arg.d));
    ffiInitialize();
    CHECK(ffiCanReturn(SPEC(structure_7)));
    ffiPushStructureOfLength((int)&ts7_arg, SPEC(structure_7));
    GOS(structure_7, struct7);
    ffiStoreStructure((int)&ts7_result, sizeof(ts7_result));
    ffiCleanup();
    DPRINTF(("%g\n", ts7_result.f1));
    DPRINTF(("%g\n", ts7_result.f2));
    DPRINTF(("%g\n", ts7_result.d));
    CHECK(ts7_result.f1 == 5.55f + 1);
    CHECK(ts7_result.f2 == 55.5f + 1);
    CHECK(ts7_result.d == 6.66 + 1);
  }
  {
    test_structure_8 ts8_arg, ts8_result;
    ts8_arg.f1= 5.55f;
    ts8_arg.f2= 55.5f;
    ts8_arg.f3= -5.55f;
    ts8_arg.f4= -55.5f;
    DPRINTF(("%g\n", ts8_arg.f1));
    DPRINTF(("%g\n", ts8_arg.f2));
    DPRINTF(("%g\n", ts8_arg.f3));
    DPRINTF(("%g\n", ts8_arg.f4));
    ffiInitialize();
    CHECK(ffiCanReturn(SPEC(structure_8)));
    ffiPushStructureOfLength((int)&ts8_arg, SPEC(structure_8));
    GOS(structure_8, struct8);
    ffiStoreStructure((int)&ts8_result, sizeof(ts8_result));
    ffiCleanup();
    DPRINTF(("%g\n", ts8_result.f1));
    DPRINTF(("%g\n", ts8_result.f2));
    DPRINTF(("%g\n", ts8_result.f3));
    DPRINTF(("%g\n", ts8_result.f4));
    CHECK(ts8_result.f1 == 5.55f + 1);
    CHECK(ts8_result.f2 == 55.5f + 1);
    CHECK(ts8_result.f3 == -5.55f + 1);
    CHECK(ts8_result.f4 == -55.5f + 1);
  }
  {
    test_structure_9 ts9_arg, ts9_result;
    ts9_arg.f= 5.55f;
    ts9_arg.i= 5;
    DPRINTF(("%g\n", ts9_arg.f));
    DPRINTF(("%d\n", ts9_arg.i));

    ffiInitialize();
    CHECK(ffiCanReturn(SPEC(structure_9)));
    ffiPushStructureOfLength((int)&ts9_arg, SPEC(structure_9));
    GOS(structure_9, struct9);
    ffiStoreStructure((int)&ts9_result, sizeof(ts9_result));
    ffiCleanup();
    DPRINTF(("%g\n", ts9_result.f));
    DPRINTF(("%d\n", ts9_result.i));
    CHECK(ts9_result.f == 5.55f + 1);
    CHECK(ts9_result.i == 5 + 1);
  }
}


#define C(C)	ffiPushSignedChar(C)
#define S(S)	ffiPushSignedShort(S)
#define I(I)	ffiPushSignedInt(I)
#define F(F)	ffiPushSingleFloat(F)
#define D(D)	ffiPushDoubleFloat(D)
#define P(P)	ffiPushPointer(P)
#define GO(T,F)	ffiCallAddressOfWithReturnType((int)(F), FFICallTypeCDecl, \
					       (T) << FFIAtomicTypeShift)

static void assert(int pred, const char *gripe)
{
  if (pred) return;
  fprintf(stderr, "%s\n", gripe);
  exit(1);
}

#include "ffi-test.h"

void stests(void)
{
  double d;
  char *s;

  ffiInitialize(); C('A'); C(65); C(65); C(1);
  GO(FFITypeSignedInt, ffiTestChars);
  ffiCleanup();

  ffiInitialize(); S('A'); S(65); S(65); S(1);
  GO(FFITypeSignedInt, ffiTestShorts);
  ffiCleanup();

  ffiInitialize(); I('A'); I(65); I(65); I(1);
  GO(FFITypeSignedInt, ffiTestInts);
  ffiCleanup();

  ffiInitialize(); F(65); F(65.0);
  GO(FFITypeSingleFloat, ffiTestFloats);
  d= ffiReturnFloatValue();
  ffiCleanup();
  DPRINTF(("%f\n", d));
  assert(d == 130.0, "single floats don't work");

  ffiInitialize(); D(41.0L); D(1);
  GO(FFITypeDoubleFloat, ffiTestDoubles);
  d= ffiReturnFloatValue();
  ffiCleanup();
  assert(d == 42.0, "problem with doubles");

  /*xxx this does not really test strings, but the corresponding call
    in the image's FFITester does */
  ffiInitialize();
  P((int)"Hello World!");
  s= (char *)ffiCallAddressOfWithPointerReturn((int)ffiPrintString, FFICallTypeCDecl);
  ffiCleanup();
  assert(!strcmp(s, "Hello World!"), "Problem with strings");

  {
    int spec[]= { FFIFlagStructure | 8,
		  TYPE(SignedInt,4), TYPE(SignedInt,4) };
    ffiTestPoint2 pt1= { 1, 2 }, pt2= { 3, 4 }, pt3;
    ffiInitialize();
    assert(ffiCanReturn((int *)&spec, 3), "cannot return struct");
    ffiPushStructureOfLength((int)&pt1, (int *)&spec, 3);
    ffiPushStructureOfLength((int)&pt2, (int *)&spec, 3);
    ffiCallAddressOfWithStructReturn((int)ffiTestStruct64, FFICallTypeCDecl, spec, 3);
    ffiStoreStructure((int)&pt3, sizeof(pt3));
    ffiCleanup();
    assert((pt3.x == 4) && (pt3.y == 6), "Problem passing 64bit structures");
  }

  {
    int spec[]= { FFIFlagStructure | 16,
		  TYPE(SignedInt,4), TYPE(SignedInt,4),
		  TYPE(SignedInt,4), TYPE(SignedInt,4) };
    ffiTestPoint4 pt1= { 1, 2, 3, 4 }, pt2= { 5, 6, 7, 8 }, pt3= { 9, 10, 11, 12 };
    ffiInitialize();
    assert(ffiCanReturn((int *)&spec, 3), "cannot return struct");
    ffiPushStructureOfLength((int)&pt1, (int *)&spec, 5);
    ffiPushStructureOfLength((int)&pt2, (int *)&spec, 5);
    ffiPushStructureOfLength((int)&pt3, (int *)&spec, 5);
    ffiCallAddressOfWithStructReturn((int)ffiTestStructBig, FFICallTypeCDecl, spec, 5);
    ffiStoreStructure((int)&pt3, sizeof(pt3));
    ffiCleanup();
    assert((pt3.x == 6) && (pt3.y == 8) && (pt3.z == 10) && (pt3.w == 12),
	   "Problem passing large structures");
  }

  {
    ffiTestPoint4 pt1= { 1, 2, 3, 4 }, pt2= { 5, 6, 7, 8 }, *pt3;
    ffiInitialize();
    ffiPushPointer((int)&pt1);
    ffiPushPointer((int)&pt2);
    pt3= (ffiTestPoint4 *)
      ffiCallAddressOfWithPointerReturn((int)ffiTestPointers, 0);
    ffiCleanup();
    assert((pt3->x == 6) && (pt3->y == 8) && (pt3->z == 10) && (pt3->w == 12),
	   "Problem passing pointers");
    free((void *)pt3);
  }
}


extern void ffiDoAssertions(void);


int main()
{
# define report(who)								\
  printf("%s %s (%d failed)\n", failed ? "FAILED" : "passed", who, failed);

  failed= 0;  ffiDoAssertions();  report("ffi assertions");
  failed= 0;  stests();		  report("FFITester support check");
  failed= 0;  ctests();		  report("C test suite");

  return 0;
}
