/****************************************************************************
*   PROJECT: Squeak foreign function interface
*   FILE:    sqFFI.h
*   CONTENT: Declarations for the foreign function interface's surface support
			 plus optional declaration of the sqFFITestFuncs.c test suite.
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   andreasr@wdi.disney.com
*
*   NOTES:
*
*****************************************************************************/
#ifndef SQ_FFI_H
#define SQ_FFI_H

#include "sqMemoryAccess.h"

/* Set the log file name for logging call-outs */
int ffiLogFileNameOfLength(void *nameIndex, int nameLength);
int ffiLogCallOfLength(void *nameIndex, int nameLength);

/* The following are for creating, manipulating, and destroying
 * "manual surfaces".  These are surfaces that are managed by Squeak code,
 * which has manual control over the memory location where the image data is
 * stored (the pointer used may be obtained via FFI calls, or other means).
 *
 * Upon creation, no memory is allocated for the surface.  Squeak code is 
 * responsible for passing in a pointer to the memory to use.  It is OK to set 
 * the pointer to different values, or to NULL.  If the pointer is NULL, then
 * BitBlt calls to ioLockSurface() will fail.
 *
 * createManualFunction() returns a non-negative surface ID if successful, and
 * -1 otherwise.  The other return true for success, and false for failure.
 */   
#include "../SurfacePlugin/SurfacePlugin.h"

void initSurfacePluginFunctionPointers();
void initManualSurfaceFunctionPointers
	(fn_ioRegisterSurface, fn_ioUnregisterSurface, fn_ioFindSurface);
int createManualSurface
	(int width, int height, int rowPitch, int depth, int isMSB);
int destroyManualSurface(int surfaceID);
int setManualSurfacePointer(int surfaceID, void* ptr);


# ifndef NO_FFI_TEST
// Declarations of test functions & types for the foreign function interface

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

char *ffiPrintString(char *string);
char  ffiTestIndirection(char *p);
int ffiTest4IntSum(int c1, int c2, int c3, int c4);
int ffiTest8IntSum(int c1, int c2, int c3, int c4, int c5, int c6, int c7, int c8);
long ffiTest4LongSum(long c1, long c2, long c3, long c4);
long ffiTest8longSum(long c1, long c2, long c3, long c4, long c5, long c6, long c7, long c8);
long long ffiTest4LongLongSum(long long c1, long long c2, long long c3, long long c4);
long long ffiTest8LongLongSum(long long c1, long long c2, long long c3, long long c4, long long c5, long long c6, long long c7, long long c8);
ffiTestSd2  ffiTestInitSd2  (double    a,double    b);
ffiTestSf2  ffiTestInitSf2  (float     a,float     b);
ffiTestSl2  ffiTestInitSl2  (long long a,long long b);
ffiTestSi2  ffiTestInitSi2  (int       a,int       b);
ffiTestSs2  ffiTestInitSs2  (short     a,short     b);
ffiTestSsi  ffiTestInitSsi  (short     a,int       b);
ffiTestSfi  ffiTestInitSfi  (float     a,int       b);
ffiTestSfd  ffiTestInitSfd  (float     a,double    b);
ffiTestSdi  ffiTestInitSdi  (double    a,int       b);
ffiTestSsf  ffiTestInitSsf  (short     a,float     b);
ffiTestSsSsi ffiTestInitSsSsi(short     a,struct Ssi b);
ffiTestSsSsf ffiTestInitSsSsf(short     a,struct Ssf b);
ffiTestSslf ffiTestInitSslf (short     a,long long b, float  c);
ffiTestSf2d ffiTestInitSf2d (float     a,float     b, double c);
ffiTestSfdf ffiTestInitSfdf (float     a,double    b, float  c);
ffiTestSs2i ffiTestInitSs2i (short     a,short     b, int    c);
ffiTestSsis ffiTestInitSsis (short     a,int       b, short  c);
ffiTestSsls ffiTestInitSsls (short     a,long long b, short  c);
ffiTestSf4  ffiTestInitSf4  (float     a,float     b, float  c,float d);
ffiTestSs4  ffiTestInitSs4  (short     a,short     b, short  c,short d);
ffiTestSSdi5 ffiTestInitSSdi5(struct Sdi a,struct Sdi b,struct Sdi c, struct Sdi d,struct Sdi e);
ffiTestUfi  ffiTestInitUfi_f(float  a);
ffiTestUfi  ffiTestInitUfi_i(int    b);
ffiTestUfd  ffiTestInitUfd_f(float  a);
ffiTestUfd  ffiTestInitUfd_d(double b);
ffiTestUdSi2 ffiTestInitUdSi2_d(double a);
ffiTestUdSi2 ffiTestInitUdSi2_ii(int a,int b);
ffiTestSUfdUfi  ffiTestInitSUfdUfi  (union Ufd a,union Ufi b);
ffiTestSUfdUdSi2  ffiTestInitSUfdUdSi2  (union Ufd a,union UdSi2 b);
ffiTestSd2  ffiTestReturnSd2  ();
ffiTestSf2  ffiTestReturnSf2  ();
ffiTestSl2  ffiTestReturnSl2  ();
ffiTestSi2  ffiTestReturnSi2  ();
ffiTestSs2  ffiTestReturnSs2  ();
ffiTestSfi  ffiTestReturnSfi  ();
ffiTestSfd  ffiTestReturnSfd  ();
ffiTestSdi  ffiTestReturnSdi  ();
ffiTestSsf  ffiTestReturnSsf  ();
ffiTestSsi  ffiTestReturnSsi  ();
ffiTestSsSsi ffiTestReturnSsSsi();
ffiTestSsSsf ffiTestReturnSsSsf();
ffiTestSf2d ffiTestReturnSf2d ();
ffiTestSfdf ffiTestReturnSfdf ();
ffiTestSs2i ffiTestReturnSs2i ();
ffiTestSsis ffiTestReturnSsis ();
ffiTestSsls ffiTestReturnSsls ();
ffiTestSslf ffiTestReturnSslf ();
ffiTestSf4  ffiTestReturnSf4  ();
ffiTestSs4  ffiTestReturnSs4  ();
ffiTestSSdi5 ffiTestReturnSSdi5();
double ffiTestSumSfd(ffiTestSfd x);
double ffiTestSumSfd_2(ffiTestSfd x,ffiTestSfd y);
double ffiTestSumSfd_4(ffiTestSfd x,ffiTestSfd y,ffiTestSfd z,ffiTestSfd t);
double ffiTestSumfWithSfd_4(float f,ffiTestSfd x,ffiTestSfd y,ffiTestSfd z,ffiTestSfd t);
double ffiTestSumSdi(ffiTestSdi x);
double ffiTestSumSdi_2(ffiTestSdi x,ffiTestSdi y);
double ffiTestSumSdi_4(ffiTestSdi x,ffiTestSdi y,ffiTestSdi z,ffiTestSdi t);
double ffiTestSumdiWithSdi_4(double a,int b,ffiTestSdi x,ffiTestSdi y,ffiTestSdi z,ffiTestSdi t);
double ffiTestSumdWithSdi_4(double a,ffiTestSdi x,ffiTestSdi y,ffiTestSdi z,ffiTestSdi t);
double ffiTestSumiWithSdi_4(int b,ffiTestSdi x,ffiTestSdi y,ffiTestSdi z,ffiTestSdi t);
double ffiTestSumSSdi5(ffiTestSSdi5 x);
double ffiTestSumSslf(ffiTestSslf x);
double ffiTestSumSslf_2(ffiTestSslf x,ffiTestSslf y);
double ffiTestSumSslf_4(ffiTestSslf x,ffiTestSslf y,ffiTestSslf z,ffiTestSslf t);
double ffiTestSumSUfdUfi_f(ffiTestSUfdUfi x);
double ffiTestSumSUfdUdSi2_d(ffiTestSUfdUdSi2 x);
char ffiTestChars(char c1, char c2, char c3, char c4);
short ffiTestShorts(short c1, short c2, short c3, short c4);
int ffiTestInts(int c1, int c2, int c3, int c4);
int ffiTestInts8(int c1, int c2, int c3, int c4, int c5, int c6, int c7, int c8);
float ffiTestFloats(float f1, float f2);
float ffiTestFloats7(float f1, float f2, float f3, float f4, float f5, float f6, float f7);
float ffiTestFloats13(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13);
float ffiTestFloats14(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13, float f14);
double ffiTestDoubles9(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9);
double ffiTestDoubles14(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14);
double ffiTestMixedFloatsAndDouble(float f1, double d1, float f2, float f3);
double ffiTestMixedDoublesIntAndStruct(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, int i1, ffiTestPoint4 pt);
double ffiTestDoubles(double d1, double d2);
ffiTestPoint2 ffiTestStruct64(ffiTestPoint2 pt1, ffiTestPoint2 pt2);
ffiTestPoint4 ffiTestStructBig(ffiTestPoint4 pt1, ffiTestPoint4 pt2);
ffiTestBiggerStruct ffiTestStructBigger(ffiTestPoint4 pt1, ffiTestPoint4 pt2);
ffiTestPoint4* ffiTestPointers(ffiTestPoint4 *pt1, ffiTestPoint4 *pt2);
ffiSmallStruct1 ffiTestSmallStructReturn(void);
int ffiTestMixedIntAndStruct(int i1, ffiTestPoint2 pt1, ffiTestPoint2 pt2);
int ffiTestMixedIntAndStruct2(int i1, ffiTestPoint4 pt2);
int ffiTestMixedIntAndStruct3(int i1, ffiSmallStruct1 pt2);
sqLong ffiTestLongLong(sqLong i1, sqLong i2);
sqLong ffiTestLongLong8(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, sqLong i1, sqLong i2);
long long ffiTestLongLongs8(long long c1, long long c2, long long c3, long long c4, long long c5, long long c6, long long c7, long long c8);
sqLong ffiTestLongLong8a1(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9, sqLong i1, sqLong i2);
sqLong ffiTestLongLong8a2(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9,  char c10, sqLong i1, sqLong i2);
sqLong ffiTestLongLonga1(char c1, sqLong i1, sqLong i2);
sqLong ffiTestLongLonga2(char c1, char c2, sqLong i1, sqLong i2);
sqLong ffiTestLongLonga3(char c1, sqLong i1, char c2);
double ffiTestMixedDoublesAndLongs(double d1, long l1, double d2, long l2, double d3, long l3, double d4, long l4, double d5, long l5, double d6, long l6, double d7, long l7, double d8, long l8, double d9, long l9, double dA, long lA);
# endif // NO_FFI_TEST
#endif // SQ_FFI_H
