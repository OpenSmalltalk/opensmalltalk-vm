typedef struct ffiTestPoint2
{
  int x;
  int y;
} ffiTestPoint2;

typedef struct ffiTestPoint4
{
  int x;
  int y;
  int z;
  int w;
} ffiTestPoint4;

extern char ffiTestChars(char c1, char c2, char c3, char c4);
extern short ffiTestShorts(short c1, short c2, short c3, short c4);
extern int ffiTestInts(int c1, int c2, int c3, int c4);
extern int ffiTestInts8(int c1, int c2, int c3, int c4, int c5, int c6, int c7, int c8);
extern int ffiTestInts9(int c1, int c2, int c3, int c4, int c5, int c6, int c7, int c8, int c9);
extern float ffiTestFloats(float f1, float f2);
extern float ffiTestFloats7(float f1, float f2, float f3, float f4, float f5, float f6, float f7);
extern float ffiTestFloats13(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13);
extern float ffiTestFloats15(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13, float f14, float f15);
extern double ffiTestDoubles(double d1, double d2);
extern double ffiTestDoubles15(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14, double f15);
extern char *ffiPrintString(char *string);
extern ffiTestPoint2 ffiTestStruct64(ffiTestPoint2 pt1, ffiTestPoint2 pt2);
extern ffiTestPoint4 ffiTestStructBig(ffiTestPoint4 pt1, ffiTestPoint4 pt2);
extern ffiTestPoint4 *ffiTestPointers(ffiTestPoint4 *pt1, ffiTestPoint4 *pt2);
extern long long ffiTestLongLong(long long i1, long long i2);
