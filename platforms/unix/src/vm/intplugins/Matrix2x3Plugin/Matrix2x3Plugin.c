/* Automatically generated from Squeak on #(19 March 2005 10:09 am) */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"

#define true 1
#define false 0
#define null 0  /* using 'null' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
#undef EXPORT
// was #undef EXPORT(returnType) but screws NorCroft cc
#define EXPORT(returnType) static returnType
#endif

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)


/*** Constants ***/

/*** Function Prototypes ***/
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halt(void);
static float * loadArgumentMatrix(int matrix);
static int loadArgumentPoint(int point);
static int matrix2x3ComposeMatrixwithinto(const float *m1, const float *m2, float *m3);
static int matrix2x3InvertPoint(float *m);
static int matrix2x3TransformPoint(float *m);
static int msg(char *s);
static int okayIntValue(int value);
#pragma export on
EXPORT(int) primitiveComposeMatrix(void);
EXPORT(int) primitiveInvertPoint(void);
EXPORT(int) primitiveInvertRectInto(void);
EXPORT(int) primitiveIsIdentity(void);
EXPORT(int) primitiveIsPureTranslation(void);
EXPORT(int) primitiveTransformPoint(void);
EXPORT(int) primitiveTransformRectInto(void);
#pragma export off
static int roundAndStoreResultPoint(int nItemsToPop);
static int roundAndStoreResultRectx0y0x1y1(int dstOop, double x0, double y0, double x1, double y1);
#pragma export on
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static double m23ArgX;
static double m23ArgY;
static double m23ResultX;
static double m23ResultY;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"Matrix2x3Plugin 19 March 2005 (i)"
#else
	"Matrix2x3Plugin 19 March 2005 (e)"
#endif
;



/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}

static int halt(void) {
	;
}


/*	Load the argument matrix */

static float * loadArgumentMatrix(int matrix) {
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!((interpreterProxy->isWords(matrix)) && ((interpreterProxy->slotSizeOf(matrix)) == 6))) {
		interpreterProxy->primitiveFail();
		return null;
	}
	return ((float *) (interpreterProxy->firstIndexableField(matrix)));
}


/*	Load the argument point into m23ArgX and m23ArgY */

static int loadArgumentPoint(int point) {
    int oop;
    int isInt;

	if (interpreterProxy->failed()) {
		return null;
	}
	if (!((interpreterProxy->fetchClassOf(point)) == (interpreterProxy->classPoint()))) {
		return interpreterProxy->primitiveFail();
	}
	oop = interpreterProxy->fetchPointerofObject(0, point);
	isInt = (oop & 1);
	if (!(isInt || (interpreterProxy->isFloatObject(oop)))) {
		return interpreterProxy->primitiveFail();
	}
	if (isInt) {
		m23ArgX = (oop >> 1);
	} else {
		m23ArgX = interpreterProxy->floatValueOf(oop);
	}
	oop = interpreterProxy->fetchPointerofObject(1, point);
	isInt = (oop & 1);
	if (!(isInt || (interpreterProxy->isFloatObject(oop)))) {
		return interpreterProxy->primitiveFail();
	}
	if (isInt) {
		m23ArgY = (oop >> 1);
	} else {
		m23ArgY = interpreterProxy->floatValueOf(oop);
	}
}


/*	Multiply matrix m1 with m2 and store the result into m3. */

static int matrix2x3ComposeMatrixwithinto(const float *m1, const float *m2, float *m3) {
    double a13;
    double a22;
    double a12;
    double a21;
    double a11;
    double a23;

	a11 = ((m1[0]) * (m2[0])) + ((m1[1]) * (m2[3]));
	a12 = ((m1[0]) * (m2[1])) + ((m1[1]) * (m2[4]));
	a13 = (((m1[0]) * (m2[2])) + ((m1[1]) * (m2[5]))) + (m1[2]);
	a21 = ((m1[3]) * (m2[0])) + ((m1[4]) * (m2[3]));
	a22 = ((m1[3]) * (m2[1])) + ((m1[4]) * (m2[4]));
	a23 = (((m1[3]) * (m2[2])) + ((m1[4]) * (m2[5]))) + (m1[5]);
	m3[0] = (((float) a11));
	m3[1] = (((float) a12));
	m3[2] = (((float) a13));
	m3[3] = (((float) a21));
	m3[4] = (((float) a22));
	m3[5] = (((float) a23));
}


/*	Invert the pre-loaded argument point by the given matrix */

static int matrix2x3InvertPoint(float *m) {
    double detY;
    double y;
    double detX;
    double x;
    double det;

	x = m23ArgX - (m[2]);
	y = m23ArgY - (m[5]);
	det = ((m[0]) * (m[4])) - ((m[1]) * (m[3]));
	if (det == 0.0) {
		return interpreterProxy->primitiveFail();
	}
	det = 1.0 / det;
	detX = (x * (m[4])) - ((m[1]) * y);
	detY = ((m[0]) * y) - (x * (m[3]));
	m23ResultX = detX * det;
	m23ResultY = detY * det;
}


/*	Transform the pre-loaded argument point by the given matrix */

static int matrix2x3TransformPoint(float *m) {
	m23ResultX = ((m23ArgX * (m[0])) + (m23ArgY * (m[1]))) + (m[2]);
	m23ResultY = ((m23ArgX * (m[3])) + (m23ArgY * (m[4]))) + (m[5]);
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

static int okayIntValue(int value) {
	return (value >= (((double) -1073741824 ))) && (m23ResultX <= (((double) 1073741823 )));
}

EXPORT(int) primitiveComposeMatrix(void) {
    int result;
    float * m3;
    float * m2;
    float * m1;
    int matrix;
    int matrix1;
    int matrix2;

	/* begin loadArgumentMatrix: */
	matrix = result = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		m3 = null;
		goto l1;
	}
	if (!((interpreterProxy->isWords(matrix)) && ((interpreterProxy->slotSizeOf(matrix)) == 6))) {
		interpreterProxy->primitiveFail();
		m3 = null;
		goto l1;
	}
	m3 = ((float *) (interpreterProxy->firstIndexableField(matrix)));
l1:	/* end loadArgumentMatrix: */;
	/* begin loadArgumentMatrix: */
	matrix1 = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		m2 = null;
		goto l2;
	}
	if (!((interpreterProxy->isWords(matrix1)) && ((interpreterProxy->slotSizeOf(matrix1)) == 6))) {
		interpreterProxy->primitiveFail();
		m2 = null;
		goto l2;
	}
	m2 = ((float *) (interpreterProxy->firstIndexableField(matrix1)));
l2:	/* end loadArgumentMatrix: */;
	/* begin loadArgumentMatrix: */
	matrix2 = interpreterProxy->stackObjectValue(2);
	if (interpreterProxy->failed()) {
		m1 = null;
		goto l3;
	}
	if (!((interpreterProxy->isWords(matrix2)) && ((interpreterProxy->slotSizeOf(matrix2)) == 6))) {
		interpreterProxy->primitiveFail();
		m1 = null;
		goto l3;
	}
	m1 = ((float *) (interpreterProxy->firstIndexableField(matrix2)));
l3:	/* end loadArgumentMatrix: */;
	if (interpreterProxy->failed()) {
		return null;
	}
	matrix2x3ComposeMatrixwithinto(m1, m2, m3);
	interpreterProxy->pop(3);
	interpreterProxy->push(result);
}

EXPORT(int) primitiveInvertPoint(void) {
    float * matrix;
    int matrix1;

	loadArgumentPoint(interpreterProxy->stackObjectValue(0));
	/* begin loadArgumentMatrix: */
	matrix1 = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		matrix = null;
		goto l1;
	}
	if (!((interpreterProxy->isWords(matrix1)) && ((interpreterProxy->slotSizeOf(matrix1)) == 6))) {
		interpreterProxy->primitiveFail();
		matrix = null;
		goto l1;
	}
	matrix = ((float *) (interpreterProxy->firstIndexableField(matrix1)));
l1:	/* end loadArgumentMatrix: */;
	if (interpreterProxy->failed()) {
		return null;
	}
	matrix2x3InvertPoint(matrix);
	if (!(interpreterProxy->failed())) {
		/* begin roundAndStoreResultPoint: */
		m23ResultX += 0.5;
		m23ResultY += 0.5;
		if (!((m23ResultX >= (((double) -1073741824 ))) && (m23ResultX <= (((double) 1073741823 ))))) {
			interpreterProxy->primitiveFail();
			goto l2;
		}
		if (!((m23ResultY >= (((double) -1073741824 ))) && (m23ResultX <= (((double) 1073741823 ))))) {
			interpreterProxy->primitiveFail();
			goto l2;
		}
		interpreterProxy->pop(2);
		interpreterProxy->push(interpreterProxy->makePointwithxValueyValue(((int) m23ResultX ), ((int) m23ResultY )));
	l2:	/* end roundAndStoreResultPoint: */;
	}
}

EXPORT(int) primitiveInvertRectInto(void) {
    double minX;
    int dstOop;
    double cornerY;
    double cornerX;
    double originY;
    double originX;
    double maxY;
    int srcOop;
    double minY;
    double maxX;
    float * matrix;
    int matrix1;

	dstOop = interpreterProxy->stackObjectValue(0);
	srcOop = interpreterProxy->stackObjectValue(1);
	/* begin loadArgumentMatrix: */
	matrix1 = interpreterProxy->stackObjectValue(2);
	if (interpreterProxy->failed()) {
		matrix = null;
		goto l1;
	}
	if (!((interpreterProxy->isWords(matrix1)) && ((interpreterProxy->slotSizeOf(matrix1)) == 6))) {
		interpreterProxy->primitiveFail();
		matrix = null;
		goto l1;
	}
	matrix = ((float *) (interpreterProxy->firstIndexableField(matrix1)));
l1:	/* end loadArgumentMatrix: */;
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!((interpreterProxy->fetchClassOf(srcOop)) == (interpreterProxy->fetchClassOf(dstOop)))) {
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->isPointers(srcOop))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->slotSizeOf(srcOop)) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	loadArgumentPoint(interpreterProxy->fetchPointerofObject(0, srcOop));
	if (interpreterProxy->failed()) {
		return null;
	}
	originX = m23ArgX;
	originY = m23ArgY;
	matrix2x3InvertPoint(matrix);
	minX = maxX = m23ResultX;

	/* Load bottom-right point */

	minY = maxY = m23ResultY;
	loadArgumentPoint(interpreterProxy->fetchPointerofObject(1, srcOop));
	if (interpreterProxy->failed()) {
		return null;
	}
	cornerX = m23ArgX;
	cornerY = m23ArgY;
	matrix2x3InvertPoint(matrix);
	minX = ((minX < m23ResultX) ? minX : m23ResultX);
	maxX = ((maxX < m23ResultX) ? m23ResultX : maxX);
	minY = ((minY < m23ResultY) ? minY : m23ResultY);

	/* Load top-right point */

	maxY = ((maxY < m23ResultY) ? m23ResultY : maxY);
	m23ArgX = cornerX;
	m23ArgY = originY;
	matrix2x3InvertPoint(matrix);
	minX = ((minX < m23ResultX) ? minX : m23ResultX);
	maxX = ((maxX < m23ResultX) ? m23ResultX : maxX);
	minY = ((minY < m23ResultY) ? minY : m23ResultY);

	/* Load bottom-left point */

	maxY = ((maxY < m23ResultY) ? m23ResultY : maxY);
	m23ArgX = originX;
	m23ArgY = cornerY;
	matrix2x3InvertPoint(matrix);
	minX = ((minX < m23ResultX) ? minX : m23ResultX);
	maxX = ((maxX < m23ResultX) ? m23ResultX : maxX);
	minY = ((minY < m23ResultY) ? minY : m23ResultY);
	maxY = ((maxY < m23ResultY) ? m23ResultY : maxY);
	if (!(interpreterProxy->failed())) {
		dstOop = roundAndStoreResultRectx0y0x1y1(dstOop, minX, minY, maxX, maxY);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(3);
		interpreterProxy->push(dstOop);
	}
}

EXPORT(int) primitiveIsIdentity(void) {
    float * matrix;
    int matrix1;

	/* begin loadArgumentMatrix: */
	matrix1 = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		matrix = null;
		goto l1;
	}
	if (!((interpreterProxy->isWords(matrix1)) && ((interpreterProxy->slotSizeOf(matrix1)) == 6))) {
		interpreterProxy->primitiveFail();
		matrix = null;
		goto l1;
	}
	matrix = ((float *) (interpreterProxy->firstIndexableField(matrix1)));
l1:	/* end loadArgumentMatrix: */;
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	interpreterProxy->pushBool(((((((matrix[0]) == (((float) 1.0))) && ((matrix[1]) == (((float) 0.0)))) && ((matrix[2]) == (((float) 0.0)))) && ((matrix[3]) == (((float) 0.0)))) && ((matrix[4]) == (((float) 1.0)))) && ((matrix[5]) == (((float) 0.0))));
}

EXPORT(int) primitiveIsPureTranslation(void) {
    float * matrix;
    int matrix1;

	/* begin loadArgumentMatrix: */
	matrix1 = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		matrix = null;
		goto l1;
	}
	if (!((interpreterProxy->isWords(matrix1)) && ((interpreterProxy->slotSizeOf(matrix1)) == 6))) {
		interpreterProxy->primitiveFail();
		matrix = null;
		goto l1;
	}
	matrix = ((float *) (interpreterProxy->firstIndexableField(matrix1)));
l1:	/* end loadArgumentMatrix: */;
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	interpreterProxy->pushBool(((((matrix[0]) == (((float) 1.0))) && ((matrix[1]) == (((float) 0.0)))) && ((matrix[3]) == (((float) 0.0)))) && ((matrix[4]) == (((float) 1.0))));
}

EXPORT(int) primitiveTransformPoint(void) {
    float * matrix;
    int matrix1;

	loadArgumentPoint(interpreterProxy->stackObjectValue(0));
	/* begin loadArgumentMatrix: */
	matrix1 = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		matrix = null;
		goto l1;
	}
	if (!((interpreterProxy->isWords(matrix1)) && ((interpreterProxy->slotSizeOf(matrix1)) == 6))) {
		interpreterProxy->primitiveFail();
		matrix = null;
		goto l1;
	}
	matrix = ((float *) (interpreterProxy->firstIndexableField(matrix1)));
l1:	/* end loadArgumentMatrix: */;
	if (interpreterProxy->failed()) {
		return null;
	}
	matrix2x3TransformPoint(matrix);
	/* begin roundAndStoreResultPoint: */
	m23ResultX += 0.5;
	m23ResultY += 0.5;
	if (!((m23ResultX >= (((double) -1073741824 ))) && (m23ResultX <= (((double) 1073741823 ))))) {
		interpreterProxy->primitiveFail();
		goto l2;
	}
	if (!((m23ResultY >= (((double) -1073741824 ))) && (m23ResultX <= (((double) 1073741823 ))))) {
		interpreterProxy->primitiveFail();
		goto l2;
	}
	interpreterProxy->pop(2);
	interpreterProxy->push(interpreterProxy->makePointwithxValueyValue(((int) m23ResultX ), ((int) m23ResultY )));
l2:	/* end roundAndStoreResultPoint: */;
}

EXPORT(int) primitiveTransformRectInto(void) {
    double minX;
    int dstOop;
    double cornerY;
    double cornerX;
    double originY;
    double originX;
    double maxY;
    int srcOop;
    double minY;
    double maxX;
    float * matrix;
    int matrix1;

	dstOop = interpreterProxy->stackObjectValue(0);
	srcOop = interpreterProxy->stackObjectValue(1);
	/* begin loadArgumentMatrix: */
	matrix1 = interpreterProxy->stackObjectValue(2);
	if (interpreterProxy->failed()) {
		matrix = null;
		goto l1;
	}
	if (!((interpreterProxy->isWords(matrix1)) && ((interpreterProxy->slotSizeOf(matrix1)) == 6))) {
		interpreterProxy->primitiveFail();
		matrix = null;
		goto l1;
	}
	matrix = ((float *) (interpreterProxy->firstIndexableField(matrix1)));
l1:	/* end loadArgumentMatrix: */;
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!((interpreterProxy->fetchClassOf(srcOop)) == (interpreterProxy->fetchClassOf(dstOop)))) {
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->isPointers(srcOop))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->slotSizeOf(srcOop)) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	loadArgumentPoint(interpreterProxy->fetchPointerofObject(0, srcOop));
	if (interpreterProxy->failed()) {
		return null;
	}
	originX = m23ArgX;
	originY = m23ArgY;
	matrix2x3TransformPoint(matrix);
	minX = maxX = m23ResultX;

	/* Load bottom-right point */

	minY = maxY = m23ResultY;
	loadArgumentPoint(interpreterProxy->fetchPointerofObject(1, srcOop));
	if (interpreterProxy->failed()) {
		return null;
	}
	cornerX = m23ArgX;
	cornerY = m23ArgY;
	matrix2x3TransformPoint(matrix);
	minX = ((minX < m23ResultX) ? minX : m23ResultX);
	maxX = ((maxX < m23ResultX) ? m23ResultX : maxX);
	minY = ((minY < m23ResultY) ? minY : m23ResultY);

	/* Load top-right point */

	maxY = ((maxY < m23ResultY) ? m23ResultY : maxY);
	m23ArgX = cornerX;
	m23ArgY = originY;
	matrix2x3TransformPoint(matrix);
	minX = ((minX < m23ResultX) ? minX : m23ResultX);
	maxX = ((maxX < m23ResultX) ? m23ResultX : maxX);
	minY = ((minY < m23ResultY) ? minY : m23ResultY);

	/* Load bottom-left point */

	maxY = ((maxY < m23ResultY) ? m23ResultY : maxY);
	m23ArgX = originX;
	m23ArgY = cornerY;
	matrix2x3TransformPoint(matrix);
	minX = ((minX < m23ResultX) ? minX : m23ResultX);
	maxX = ((maxX < m23ResultX) ? m23ResultX : maxX);
	minY = ((minY < m23ResultY) ? minY : m23ResultY);
	maxY = ((maxY < m23ResultY) ? m23ResultY : maxY);
	dstOop = roundAndStoreResultRectx0y0x1y1(dstOop, minX, minY, maxX, maxY);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(3);
		interpreterProxy->push(dstOop);
	}
}


/*	Store the result of a previous operation.
	Fail if we cannot represent the result as SmallInteger */

static int roundAndStoreResultPoint(int nItemsToPop) {
	m23ResultX += 0.5;
	m23ResultY += 0.5;
	if (!((m23ResultX >= (((double) -1073741824 ))) && (m23ResultX <= (((double) 1073741823 ))))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((m23ResultY >= (((double) -1073741824 ))) && (m23ResultX <= (((double) 1073741823 ))))) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop(nItemsToPop);
	interpreterProxy->push(interpreterProxy->makePointwithxValueyValue(((int) m23ResultX ), ((int) m23ResultY )));
}


/*	Check, round and store the result of a rectangle operation */

static int roundAndStoreResultRectx0y0x1y1(int dstOop, double x0, double y0, double x1, double y1) {
    double maxX;
    int rectOop;
    int cornerOop;
    double maxY;
    double minY;
    int originOop;
    double minX;

	minX = x0 + 0.5;
	if (!((minX >= (((double) -1073741824 ))) && (m23ResultX <= (((double) 1073741823 ))))) {
		return interpreterProxy->primitiveFail();
	}
	maxX = x1 + 0.5;
	if (!((maxX >= (((double) -1073741824 ))) && (m23ResultX <= (((double) 1073741823 ))))) {
		return interpreterProxy->primitiveFail();
	}
	minY = y0 + 0.5;
	if (!((minY >= (((double) -1073741824 ))) && (m23ResultX <= (((double) 1073741823 ))))) {
		return interpreterProxy->primitiveFail();
	}
	maxY = y1 + 0.5;
	if (!((maxY >= (((double) -1073741824 ))) && (m23ResultX <= (((double) 1073741823 ))))) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pushRemappableOop(dstOop);
	originOop = interpreterProxy->makePointwithxValueyValue(((int) minX ), ((int) minY ));
	interpreterProxy->pushRemappableOop(originOop);
	cornerOop = interpreterProxy->makePointwithxValueyValue(((int) maxX ), ((int) maxY ));
	originOop = interpreterProxy->popRemappableOop();
	rectOop = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(0, rectOop, originOop);
	interpreterProxy->storePointerofObjectwithValue(1, rectOop, cornerOop);
	return rectOop;
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter) {
    int ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* Matrix2x3Plugin_exports[][3] = {
	{"Matrix2x3Plugin", "primitiveTransformPoint", (void*)primitiveTransformPoint},
	{"Matrix2x3Plugin", "primitiveIsIdentity", (void*)primitiveIsIdentity},
	{"Matrix2x3Plugin", "primitiveTransformRectInto", (void*)primitiveTransformRectInto},
	{"Matrix2x3Plugin", "primitiveInvertPoint", (void*)primitiveInvertPoint},
	{"Matrix2x3Plugin", "primitiveComposeMatrix", (void*)primitiveComposeMatrix},
	{"Matrix2x3Plugin", "getModuleName", (void*)getModuleName},
	{"Matrix2x3Plugin", "primitiveIsPureTranslation", (void*)primitiveIsPureTranslation},
	{"Matrix2x3Plugin", "primitiveInvertRectInto", (void*)primitiveInvertRectInto},
	{"Matrix2x3Plugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

