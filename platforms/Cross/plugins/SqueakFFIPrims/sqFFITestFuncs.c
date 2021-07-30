/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/************ Test functions for the foreign function interface **************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
#ifndef NO_FFI_TEST
# include "sq.h"

# define LONGLONG sqLong /* should be 64 bits */

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

typedef struct ffiSmallStruct1 {
   unsigned char x;
   unsigned char y;
} ffiSmallStruct1;


typedef struct ffiTestBiggerStruct {
	long long x;
	long long y;
	long long z;
	long long w;
  	long long r;
	long long s;
  	long long t;
  	long long u;
} ffiTestBiggerStruct;
/*
 * test returning struct by value
 * clang --shared -Os -o libalientest.dylib alientest.c
 * objdump --disassemble libalientest.dylib
 */

typedef struct Sd2 {double a,b;} ffiTestSd2;
typedef struct Sf2 {float a,b;} ffiTestSf2;
typedef struct Sl2 {long long a,b;} ffiTestSl2;
typedef struct Si2 {int a,b;} ffiTestSi2;
typedef struct Ss2 {short a,b;} ffiTestSs2;
typedef struct Ssi {short a; int b;} ffiTestSsi;
typedef struct Sfi {float a; int b;} ffiTestSfi;
typedef struct Sfd {float a; double b;} ffiTestSfd;
typedef struct Sdi {double a; int b;} ffiTestSdi;
typedef struct Ssf {short a; float b;} ffiTestSsf;
typedef struct SsSsi {short a; struct Ssi b;} ffiTestSsSsi;
typedef struct SsSsf {short a; struct Ssf b;} ffiTestSsSsf;
typedef struct Sf2d {float a,b; double c;} ffiTestSf2d;
typedef struct Sfdf {float a; double b; float c;} ffiTestSfdf;
typedef struct Ss2i {short a,b; int c;} ffiTestSs2i;
typedef struct Ssis {short a; int b; short c;} ffiTestSsis;
typedef struct Ssls {short a; long long b; short c;} ffiTestSsls;
typedef struct Sslf {short a; long long b; float c;} ffiTestSslf;
typedef struct Sf4 {float a,b,c,d;} ffiTestSf4;
typedef struct Ss4 {short a,b,c,d;} ffiTestSs4;
typedef struct SSdi5 {struct Sdi a,b,c,d,e;} ffiTestSSdi5; /* a structure longer than 8 eightBytes */

typedef union  Ufi {float a; int b;} ffiTestUfi;
typedef union  Ufd {float a; double b;} ffiTestUfd;
typedef union  UdSi2 {double a; struct Si2 b;} ffiTestUdSi2;

typedef struct SUfdUfi {union Ufd a; union Ufi b;} ffiTestSUfdUfi;
typedef struct SUfdUdSi2 {union Ufd a; union UdSi2 b;} ffiTestSUfdUdSi2;

#pragma export on

EXPORT(ffiTestSd2)  ffiTestInitSd2  (double    a,double    b)
{ ffiTestSd2 v = {a,b};
	return v;
}
EXPORT(ffiTestSf2)  ffiTestInitSf2  (float     a,float     b)
{ ffiTestSf2 v = {a,b};
	return v;
}
EXPORT(ffiTestSl2)  ffiTestInitSl2  (long long a,long long b)
{ ffiTestSl2 v = {a,b};
	return v;
}
EXPORT(ffiTestSi2)  ffiTestInitSi2  (int       a,int       b)
{ ffiTestSi2 v = {a,b};
	return v;
}
EXPORT(ffiTestSs2)  ffiTestInitSs2  (short     a,short     b)
{ ffiTestSs2 v = {a,b};
	return v;
}
EXPORT(ffiTestSsi)  ffiTestInitSsi  (short     a,int       b)
{ ffiTestSsi v = {a,b};
	return v;
}
EXPORT(ffiTestSfi)  ffiTestInitSfi  (float     a,int       b)
{ ffiTestSfi v = {a,b};
	return v;
}
EXPORT(ffiTestSfd)  ffiTestInitSfd  (float     a,double    b)
{ ffiTestSfd v = {a,b};
	return v;
}
EXPORT(ffiTestSdi)  ffiTestInitSdi  (double    a,int       b)
{ ffiTestSdi v = {a,b};
	return v;
}
EXPORT(ffiTestSsf)  ffiTestInitSsf  (short     a,float     b)
{ ffiTestSsf v = {a,b};
	return v;
}
EXPORT(ffiTestSsSsi)ffiTestInitSsSsi(short     a,struct Ssi b)
{ ffiTestSsSsi v = {a,b};
	return v;
}
EXPORT(ffiTestSsSsf)ffiTestInitSsSsf(short     a,struct Ssf b)
{ ffiTestSsSsf v = {a,b};
	return v;
}
EXPORT(ffiTestSslf) ffiTestInitSslf (short     a,long long b, float  c)
{ ffiTestSslf v = {a,b,c};
	return v;
}
EXPORT(ffiTestSf2d) ffiTestInitSf2d (float     a,float     b, double c)
{ ffiTestSf2d v = {a,b,c};
	return v;
}
EXPORT(ffiTestSfdf) ffiTestInitSfdf (float     a,double    b, float  c)
{ ffiTestSfdf v = {a,b,c};
	return v;
}
EXPORT(ffiTestSs2i) ffiTestInitSs2i (short     a,short     b, int    c)
{ ffiTestSs2i v = {a,b,c};
	return v;
}
EXPORT(ffiTestSsis) ffiTestInitSsis (short     a,int       b, short  c)
{ ffiTestSsis v = {a,b,c};
	return v;
}
EXPORT(ffiTestSsls) ffiTestInitSsls (short     a,long long b, short  c)
{ ffiTestSsls v = {a,b,c};
	return v;
}
EXPORT(ffiTestSf4)  ffiTestInitSf4  (float     a,float     b, float  c,float d)
{ ffiTestSf4 v = {a,b,c,d};
	return v;
}
EXPORT(ffiTestSs4)  ffiTestInitSs4  (short     a,short     b, short  c,short d)
{ ffiTestSs4 v = {a,b,c,d};
	return v;
}
EXPORT(ffiTestSSdi5)ffiTestInitSSdi5(struct Sdi a,struct Sdi b,struct Sdi c, struct Sdi d,struct Sdi e)
{ ffiTestSSdi5 v = {a,b,c,d,e};
	return v;
}

EXPORT(ffiTestUfi)  ffiTestInitUfi_f(float  a)
{ ffiTestUfi v; v.a=a;
	return v;
}
EXPORT(ffiTestUfi)  ffiTestInitUfi_i(int    b)
{ ffiTestUfi v; v.b=b;
	return v;
}
EXPORT(ffiTestUfd)  ffiTestInitUfd_f(float  a)
{ ffiTestUfd v; v.a=a;
	return v;
}
EXPORT(ffiTestUfd)  ffiTestInitUfd_d(double b)
{ ffiTestUfd v; v.b=b;
	return v;
}
EXPORT(ffiTestUdSi2) ffiTestInitUdSi2_d(double a)
{ ffiTestUdSi2 v; v.a=a;
	return v;
}
EXPORT(ffiTestUdSi2) ffiTestInitUdSi2_ii(int a,int b)
{ ffiTestUdSi2 v; v.b.a=a; v.b.b=b;
	return v;
}
EXPORT(ffiTestSUfdUfi)  ffiTestInitSUfdUfi  (union Ufd a,union Ufi b)
{ ffiTestSUfdUfi v = {a,b};
	return v;
}
EXPORT(ffiTestSUfdUdSi2)  ffiTestInitSUfdUdSi2  (union Ufd a,union UdSi2 b)
{ ffiTestSUfdUdSi2 v = {a,b};
	return v;
}

EXPORT(ffiTestSd2)  ffiTestReturnSd2  ()
{ return ffiTestInitSd2(1.0 ,2.0 ); }
EXPORT(ffiTestSf2)  ffiTestReturnSf2  ()
{ return ffiTestInitSf2(1.0f,2.0f); }
EXPORT(ffiTestSl2)  ffiTestReturnSl2  ()
{ return ffiTestInitSl2(1LL,2LL); }
EXPORT(ffiTestSi2)  ffiTestReturnSi2  ()
{ return ffiTestInitSi2(1,2); }
EXPORT(ffiTestSs2)  ffiTestReturnSs2  ()
{ return ffiTestInitSs2(1,2); }
EXPORT(ffiTestSfi)  ffiTestReturnSfi  ()
{ return ffiTestInitSfi(1.0f,2); }
EXPORT(ffiTestSfd)  ffiTestReturnSfd  ()
{ return ffiTestInitSfd(1.0f,2.0); }
EXPORT(ffiTestSdi)  ffiTestReturnSdi  ()
{ return ffiTestInitSdi(1.0,2); }
EXPORT(ffiTestSsf)  ffiTestReturnSsf  ()
{ return ffiTestInitSsf(1,2.0); }
EXPORT(ffiTestSsi)  ffiTestReturnSsi  ()
{ return ffiTestInitSsi(1,2); }
EXPORT(ffiTestSsSsi)ffiTestReturnSsSsi()
{ return ffiTestInitSsSsi(1,ffiTestInitSsi(2,3)); }
EXPORT(ffiTestSsSsf)ffiTestReturnSsSsf()
{ return ffiTestInitSsSsf(1,ffiTestInitSsf(2,3.0f)); }
EXPORT(ffiTestSf2d) ffiTestReturnSf2d ()
{ return ffiTestInitSf2d(1.0f,2.0f,3.0); }
EXPORT(ffiTestSfdf) ffiTestReturnSfdf ()
{ return ffiTestInitSfdf(1.0f,2.0,3.0f); }
EXPORT(ffiTestSs2i) ffiTestReturnSs2i ()
{ return ffiTestInitSs2i(1,2,3); }
EXPORT(ffiTestSsis) ffiTestReturnSsis ()
{ return ffiTestInitSsis(1,2,3); }
EXPORT(ffiTestSsls) ffiTestReturnSsls ()
{ return ffiTestInitSsls(1,2LL,3); }
EXPORT(ffiTestSslf) ffiTestReturnSslf ()
{ return ffiTestInitSslf(1,2LL,3.0f); }
EXPORT(ffiTestSf4)  ffiTestReturnSf4  ()
{ return ffiTestInitSf4(1.0f,2.0f,3.0f,4.0f); }
EXPORT(ffiTestSs4)  ffiTestReturnSs4  ()
{ return ffiTestInitSs4(1,2,3,4); }
EXPORT(ffiTestSSdi5)ffiTestReturnSSdi5()
{ return ffiTestInitSSdi5(ffiTestInitSdi(1.0,1),ffiTestInitSdi(2.0,2),
						  ffiTestInitSdi(3.0,3),ffiTestInitSdi(4.0,4),
						  ffiTestInitSdi(5.0,5));
}

EXPORT(double) ffiTestSumSfd(ffiTestSfd x)
{ return (double) x.a + (double) x.b ; }
EXPORT(double) ffiTestSumSfd_2(ffiTestSfd x,ffiTestSfd y)
{ return ffiTestSumSfd(x) + ffiTestSumSfd(y); }
EXPORT(double) ffiTestSumSfd_4(ffiTestSfd x,ffiTestSfd y,ffiTestSfd z,ffiTestSfd t)
{ return ffiTestSumSfd_2(x,y) + ffiTestSumSfd_2(z,t); }
EXPORT(double) ffiTestSumfWithSfd_4(float f,ffiTestSfd x,ffiTestSfd y,ffiTestSfd z,ffiTestSfd t)
{ return ((double) f) + ffiTestSumSfd_2(x,y) + ffiTestSumSfd_2(z,t); } /* consume 1 float register with first argument */
EXPORT(double) ffiTestSumSdi(ffiTestSdi x)
{ return (double) x.a + (double) x.b ; }
EXPORT(double) ffiTestSumSdi_2(ffiTestSdi x,ffiTestSdi y)
{ return ffiTestSumSdi(x) + ffiTestSumSdi(y); }
EXPORT(double) ffiTestSumSdi_4(ffiTestSdi x,ffiTestSdi y,ffiTestSdi z,ffiTestSdi t)
{ return ffiTestSumSdi_2(x,y) + ffiTestSumSdi_2(z,t); }
EXPORT(double) ffiTestSumdiWithSdi_4(double a,int b,ffiTestSdi x,ffiTestSdi y,ffiTestSdi z,ffiTestSdi t)
{ return a + ((double) b) + ffiTestSumSdi_2(x,y) + ffiTestSumSdi_2(z,t); } /* consume one int and 1 float register with 1st two arguments */
EXPORT(double) ffiTestSumdWithSdi_4(double a,ffiTestSdi x,ffiTestSdi y,ffiTestSdi z,ffiTestSdi t)
{ return a + ffiTestSumSdi_2(x,y) + ffiTestSumSdi_2(z,t); } /* consume one float register with 1st argument */
EXPORT(double) ffiTestSumiWithSdi_4(int b,ffiTestSdi x,ffiTestSdi y,ffiTestSdi z,ffiTestSdi t)
{ return ((double) b) + ffiTestSumSdi_2(x,y) + ffiTestSumSdi_2(z,t); } /* consume one int register with 1st argument */
EXPORT(double) ffiTestSumSSdi5(ffiTestSSdi5 x)
{ return ffiTestSumSdi_4(x.a,x.b,x.c,x.d) + ffiTestSumSdi(x.e) ; }

EXPORT(double) ffiTestSumSslf(ffiTestSslf x)
{ return (double) x.a + (double) x.b + (double) x.c ; }
EXPORT(double) ffiTestSumSslf_2(ffiTestSslf x,ffiTestSslf y)
{ return ffiTestSumSslf(x) + ffiTestSumSslf(y); }
EXPORT(double) ffiTestSumSslf_4(ffiTestSslf x,ffiTestSslf y,ffiTestSslf z,ffiTestSslf t)
{ return ffiTestSumSslf_2(x,y) + ffiTestSumSslf_2(z,t); }

EXPORT(double) ffiTestSumSUfdUfi_f(ffiTestSUfdUfi x)
{return (double) x.a.a + (double) x.b.a; }; /* sum the float parts */
EXPORT(double) ffiTestSumSUfdUdSi2_d(ffiTestSUfdUdSi2 x)
{return x.a.b + x.b.a; }; /* sum the double parts */

EXPORT(char) ffiTestChars(char c1, char c2, char c3, char c4);
EXPORT(short) ffiTestShorts(short c1, short c2, short c3, short c4);
EXPORT(int) ffiTestInts(int c1, int c2, int c3, int c4);
EXPORT(int) ffiTestInts8(int c1, int c2, int c3, int c4, int c5, int c6, int c7, int c8);
EXPORT(float) ffiTestFloats(float f1, float f2);
EXPORT(float) ffiTestFloats7(float f1, float f2, float f3, float f4, float f5, float f6, float f7);
EXPORT(float) ffiTestFloats13(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13);
EXPORT(float) ffiTestFloats14(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13, float f14);
EXPORT(double) ffiTestDoubles9(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9);
EXPORT(double) ffiTestDoubles14(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14);
EXPORT(double) ffiTestMixedFloatsAndDouble(float f1, double d1, float f2, float f3);
EXPORT(double) ffiTestMixedDoublesIntAndStruct(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, int i1, ffiTestPoint4 pt);
EXPORT(double) ffiTestDoubles(double d1, double d2);
EXPORT(char *) ffiPrintString(char *string);
EXPORT(ffiTestPoint2) ffiTestStruct64(ffiTestPoint2 pt1, ffiTestPoint2 pt2);
EXPORT(ffiTestPoint4) ffiTestStructBig(ffiTestPoint4 pt1, ffiTestPoint4 pt2);
EXPORT(ffiTestBiggerStruct) ffiTestStructBigger(ffiTestPoint4 pt1, ffiTestPoint4 pt2);
EXPORT(ffiTestPoint4*) ffiTestPointers(ffiTestPoint4 *pt1, ffiTestPoint4 *pt2);
EXPORT(ffiSmallStruct1) ffiTestSmallStructReturn(void);
EXPORT(int) ffiTestMixedIntAndStruct(int i1, ffiTestPoint2 pt1, ffiTestPoint2 pt2);
EXPORT(int) ffiTestMixedIntAndStruct2(int i1, ffiTestPoint4 pt2);
EXPORT(int) ffiTestMixedIntAndStruct3(int i1, ffiSmallStruct1 pt2);
EXPORT(LONGLONG) ffiTestLongLong(LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLong8(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLong8a1(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9, LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLong8a2(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9,  char c10, LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLonga1(char c1, LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLonga2(char c1, char c2, LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLonga3(char c1, LONGLONG i1, char c2);
#pragma export off


/* test passing characters */
EXPORT(char) ffiTestChars(char c1, char c2, char c3, char c4)
{
	printf("4 characters came in as\nc1 = %c (%x)\nc2 = %c (%x)\nc3 = %c (%x)\nc4 = %c (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4);
	return c1+c2;
}

/* test passing shorts */
EXPORT(short) ffiTestShorts(short c1, short c2, short c3, short c4)
{
	printf("4 shorts came in as\ns1 = %d (%x)\ns2 = %d (%x)\ns3 = %d (%x)\ns4 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4);
	return c1+c2;
}

/* test passing ints */
EXPORT(int) ffiTestInts(int c1, int c2, int c3, int c4)
{
	printf("4 ints came in as\ni1 = %d (%x)\ni2 = %d (%x)\ni3 = %d (%x)\ni4 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4);
	return c1+c2;
}

EXPORT(int) ffiTest4IntSum(int c1, int c2, int c3, int c4)
{
	return c1+c2+c3+c4;
}

EXPORT(int) ffiTestInts8(int c1, int c2, int c3, int c4, int c5, int c6, int c7, int c8)
{
	printf("8 ints came in as\ni1 = %d (%x)\ni2 = %d (%x)\ni3 = %d (%x)\ni4 = %d (%x)\ni5 = %d (%x)\ni6 = %d (%x)\ni7 = %d (%x)\ni8 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4, c5, c5, c6, c6, c7, c7, c8, c8);
	return 42;
}

EXPORT(int) ffiTest8IntSum(int c1, int c2, int c3, int c4, int c5, int c6, int c7, int c8)
{
	printf("8 ints came in as\ni1 = %d (%x)\ni2 = %d (%x)\ni3 = %d (%x)\ni4 = %d (%x)\ni5 = %d (%x)\ni6 = %d (%x)\ni7 = %d (%x)\ni8 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4, c5, c5, c6, c6, c7, c7, c8, c8);
	return c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8;
}

EXPORT(long) ffiTest4LongSum(long c1, long c2, long c3, long c4)
{
	return c1+c2+c3+c4;
}

EXPORT(long) ffiTestLongs8(long c1, long c2, long c3, long c4, long c5, long c6, long c7, long c8)
{
	printf("8 longs came in as\ni1 = %ld (%lx)\ni2 = %ld (%lx)\ni3 = %ld (%lx)\ni4 = %ld (%lx)\ni5 = %ld (%lx)\ni6 = %ld (%lx)\ni7 = %ld (%lx)\ni8 = %ld (%lx)\n", c1, c1, c2, c2, c3, c3, c4, c4, c5, c5, c6, c6, c7, c7, c8, c8);
	return 42;
}

EXPORT(long) ffiTest8longSum(long c1, long c2, long c3, long c4, long c5, long c6, long c7, long c8)
{
	printf("8 longs came in as\ni1 = %ld (%lx)\ni2 = %ld (%lx)\ni3 = %ld (%lx)\ni4 = %ld (%lx)\ni5 = %ld (%lx)\ni6 = %ld (%lx)\ni7 = %ld (%lx)\ni8 = %ld (%lx)\n", c1, c1, c2, c2, c3, c3, c4, c4, c5, c5, c6, c6, c7, c7, c8, c8);
	return c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8;
}

EXPORT(long long) ffiTest4LongLongSum(long long c1, long long c2, long long c3, long long c4)
{
	return c1+c2+c3+c4;
}

EXPORT(long long) ffiTestLongLongs8(long long c1, long long c2, long long c3, long long c4, long long c5, long long c6, long long c7, long long c8)
{
	printf("8 long longs came in as\ni1 = %lld (%llx)\ni2 = %lld (%llx)\ni3 = %lld (%llx)\ni4 = %lld (%llx)\ni5 = %lld (%llx)\ni6 = %lld (%llx)\ni7 = %lld (%llx)\ni8 = %lld (%llx)\n", c1, c1, c2, c2, c3, c3, c4, c4, c5, c5, c6, c6, c7, c7, c8, c8);
	return 42;
}

EXPORT(long long) ffiTest8LongLongSum(long long c1, long long c2, long long c3, long long c4, long long c5, long long c6, long long c7, long long c8)
{
	printf("8 long longs came in as\ni1 = %lld (%llx)\ni2 = %lld (%llx)\ni3 = %lld (%llx)\ni4 = %lld (%llx)\ni5 = %lld (%llx)\ni6 = %lld (%llx)\ni7 = %lld (%llx)\ni8 = %lld (%llx)\n", c1, c1, c2, c2, c3, c3, c4, c4, c5, c5, c6, c6, c7, c7, c8, c8);
	return c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8;
}

/* test passing and returning floats */
EXPORT(float) ffiTestFloats(float f1, float f2)
{
	printf("The two floats are %f and %f\n", f1, f2);
	return (float) (f1 + f2);
}

EXPORT(float) ffiTestFloats7(float f1, float f2, float f3, float f4, float f5, float f6, float f7)
{
	printf("The 7 floats are %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7);
	return (float) (f1 + f2 + f3 + f4 + f5 + f6 + f7);
}

EXPORT(float) ffiTestFloats13(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13)
{
	printf("The 13 floats are %f %f %f %f %f %f %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13);
	return (float) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13);
}

EXPORT(float) ffiTestFloats14(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13, float f14)
{
	printf("The 14 floats are %f %f %f %f %f %f %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13);
	return (float) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13 + f14);
}

EXPORT(double) ffiTestDoubles9(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9)
{
	printf("The 9 doubles are %f %f %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7, f8, f9);
	return (double) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9);
}

EXPORT(double) ffiTestDoubles14(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14)
{
	printf("The 14 double are %f %f %f %f %f %f %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13);
	return (double) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13 + f14);
}

EXPORT(double) ffiTestMixedFloatsAndDouble(float f1, double d1, float f2, float f3)
{
  printf("The four floats are %f %f %f %f\n", f1, d1, f2, f3);   
  return f1 + d1 + f2 + f3;
}

EXPORT(double) ffiTestMixedDoublesAndLongs(double d1, long l1, double d2, long l2, double d3, long l3, double d4, long l4, double d5, long l5, double d6, long l6, double d7, long l7, double d8, long l8, double d9, long l9, double dA, long lA)
{
  printf("the arguments came in as %f %ld %f %ld %f %ld %f %ld %f %ld %f %ld %f %ld %f %ld %f %ld %f %ld\n",
		d1, l1, d2, l2, d3, l3, d4, l4, d5, l5, d6, l6, d7, l7, d8, l8, d9, l9, dA, lA);
  return d1 + l1 + d2 + l2 + d3 + l3 + d4 + l4 + d5 + l5 + d6 + l6 + d7 + l7 + d8 + l8 + d9 + l9 + dA + lA;
}

/* test passing and returning doubles */
EXPORT(double) ffiTestDoubles(double d1, double d2)
{
	printf("The two floats are %f and %f\n", (float)d1, (float)d2);
	return d1+d2;
}

/* test passing and returning strings */
EXPORT(char*) ffiPrintString(char *string)
{
	printf("%s\n", string);
	return string;
}

/* test passing and returning 64bit structures */
EXPORT(ffiTestPoint2) ffiTestStruct64(ffiTestPoint2 pt1, ffiTestPoint2 pt2)
{
	ffiTestPoint2 result;
	printf("pt1.x = %d\npt1.y = %d\npt2.x = %d\npt2.y = %d\n",
			pt1.x, pt1.y, pt2.x, pt2.y);
	result.x = pt1.x + pt2.x;
	result.y = pt1.y + pt2.y;
	return result;
}

/* test passing and returning large structures */
EXPORT(ffiTestPoint4) ffiTestStructBig(ffiTestPoint4 pt1, ffiTestPoint4 pt2)
{
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

EXPORT(ffiTestBiggerStruct) ffiTestStructBigger(ffiTestPoint4 pt1, ffiTestPoint4 pt2)
{
	ffiTestBiggerStruct result;

	result.x = pt1.x;
	result.y = pt1.y;
	result.z = pt1.z;
	result.w = pt1.w;
	result.r = pt2.x;
	result.s = pt2.y;	
	result.t = pt2.z;
	result.u = pt2.w;
	
	return( result );
}

/* test passing and returning pointers */
EXPORT(ffiTestPoint4*) ffiTestPointers(ffiTestPoint4 *pt1, ffiTestPoint4 *pt2)
{
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

/* test returning small structure (uses registers on some platforms) */
EXPORT(ffiSmallStruct1) ffiTestSmallStructReturn(void)
{
	ffiSmallStruct1 result;
	result.x = 3;
	result.y = 4;
	return result;
}

EXPORT(int) ffiTestMixedIntAndStruct(int i1, ffiTestPoint2 pt1, ffiTestPoint2 pt2)
{
   int result;
	printf("int1 = %d\n", i1);
   printf("pt1.x = %d\npt1.y = %d\n", pt1.x, pt1.y);
   printf("pt2.x = %d\npt2.y = %d\n", pt2.x, pt2.y);
   result = i1 + pt1.x + pt1.y + pt2.x + pt2.y;
   return result;
}

EXPORT(int) ffiTestMixedIntAndStruct2(int i1, ffiTestPoint4 pt2)
{
   int result;
   printf("int1 = %d\n", i1);
   printf("pt2.x = %d\npt2.y = %d\npt2.z = %d\npt2.w = %d\n",
           pt2.x, pt2.y, pt2.z, pt2.w);
   result = i1 + pt2.x + pt2.y + pt2.z + pt2.w;
   return result;
}

EXPORT(int) ffiTestMixedIntAndStruct3(int i1, ffiSmallStruct1 pt2)
{
   int result;
   printf("int1 = %d\n", i1);
   printf("pt2.x = %d\npt2.y = %d\n", pt2.x, pt2.y);
   result = i1 + pt2.x + pt2.y;
   return result;
}

EXPORT(double) ffiTestMixedDoublesIntAndStruct(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, int i1, ffiTestPoint4 pt)
{
	printf("The 9 doubles are %f %f %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7, f8, f9);
   printf("int1 = %d\n", i1);
   printf("pt.x = %d\npt.y = %d\npt.z = %d\npt.w = %d\n",
           pt.x, pt.y, pt.z, pt.w);   
	return (double) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + i1 + pt.x + pt.y + pt.z + pt.w);
}

/* test passing and returning longlongs */
EXPORT(LONGLONG) ffiTestLongLong(LONGLONG i1, LONGLONG i2)
{
	return i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLonga1(char c1, LONGLONG i1, LONGLONG i2)
{
	return c1 + i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLonga2(char c1, char c2, LONGLONG i1, LONGLONG i2)
{
	return c1 + c2 + i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLonga3(char c1, LONGLONG i1, char c2)
{
	return c1 + i1 + c2;
}

EXPORT(LONGLONG) ffiTestLongLong8(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, LONGLONG i1, LONGLONG i2)
{
	return c1+c2+c3+c4+c5+c6+c7+c8+i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLong8a1(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9, LONGLONG i1, LONGLONG i2)
{
	return c1+c2+c3+c4+c5+c6+c7+c8+c9+i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLong8a2(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9, char c10, LONGLONG i1, LONGLONG i2)
{
	return c1+c2+c3+c4+c5+c6+c7+c8+c9+c10+i1 + i2;
}

#endif /* NO_FFI_TEST */
