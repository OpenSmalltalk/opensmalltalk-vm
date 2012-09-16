/* Automatically generated from Squeak on 15 September 2012 4:47:57 pm 
   by VMMaker 4.10.2
 */

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
#include "CroquetPlugin.h"

#include "sqMemoryAccess.h"


/*** Constants ***/

/*** Function Prototypes ***/
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static sqInt halt(void);
#pragma export on
EXPORT(sqInt) primitiveARC4Transform(void);
EXPORT(sqInt) primitiveGatherEntropy(void);
EXPORT(sqInt) primitiveInplaceHouseHolderInvert(void);
EXPORT(sqInt) primitiveMD5Transform(void);
EXPORT(sqInt) primitiveOrthoNormInverseMatrix(void);
EXPORT(sqInt) primitiveTransformDirection(void);
EXPORT(sqInt) primitiveTransformMatrixWithInto(void);
EXPORT(sqInt) primitiveTransformVector3(void);
EXPORT(sqInt) primitiveTransposeMatrix(void);
EXPORT(sqInt) primitiveTriBoxIntersects(void);
EXPORT(sqInt) setInterpreter(struct VirtualMachine*anInterpreter);
#pragma export off
static void* stackMatrix(sqInt index);
static void* stackVector3(sqInt index);
static sqInt transformMatrixwithinto(float *src, float *arg, float *dst);
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"CroquetPlugin 15 September 2012 (i)"
#else
	"CroquetPlugin 15 September 2012 (e)"
#endif
;



/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}

static sqInt halt(void) {
	;
}


/*	Perform an ARC4 transform of input.
	Arguments:
		buffer		<ByteArray> transformed data
		startIndex 	<Integer>	start of transform
		stopIndex	<Integer>	end of transform
		m			<ByteArray>	key stream data
		x			<Integer>	key state value
		y			<Integer>	key state value
	Return value:
		x@y - updated key state value
	 */

EXPORT(sqInt) primitiveARC4Transform(void) {
    sqInt a;
    sqInt b;
    sqInt bufOop;
    sqInt bufSize;
    unsigned char *buffer;
    sqInt i;
    unsigned char *m;
    sqInt mOop;
    sqInt mask;
    sqInt ptOop;
    sqInt startIndex;
    sqInt stopIndex;
    sqInt x;
    sqInt xOop;
    sqInt y;
    sqInt yOop;

	if (!((interpreterProxy->methodArgumentCount()) == 6)) {
		return interpreterProxy->primitiveFail();
	}
	y = interpreterProxy->stackIntegerValue(0);
	x = interpreterProxy->stackIntegerValue(1);
	mOop = interpreterProxy->stackObjectValue(2);
	stopIndex = interpreterProxy->stackIntegerValue(3);
	startIndex = interpreterProxy->stackIntegerValue(4);
	bufOop = interpreterProxy->stackObjectValue(5);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!((interpreterProxy->isBytes(mOop)) && (interpreterProxy->isBytes(bufOop)))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->byteSizeOf(mOop)) == 256)) {
		return interpreterProxy->primitiveFail();
	}
	bufSize = interpreterProxy->byteSizeOf(bufOop);
	if (!((startIndex > 0) && (startIndex <= bufSize))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((stopIndex > startIndex) && (stopIndex <= bufSize))) {
		return interpreterProxy->primitiveFail();
	}
	m = interpreterProxy->firstIndexableField(mOop);
	buffer = interpreterProxy->firstIndexableField(bufOop);
	for (i = (startIndex - 1); i <= (stopIndex - 1); i += 1) {
		x = (x + 1) & 255;
		a = m[x];
		y = (y + a) & 255;
		b = m[y];
		m[x] = b;
		m[y] = a;
		mask = m[(a + b) & 255];
		buffer[i] = ((buffer[i]) ^ mask);
	}
	ptOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classPoint(), 0);
	interpreterProxy->pushRemappableOop(ptOop);
	xOop = interpreterProxy->positive32BitIntegerFor(x);
	interpreterProxy->pushRemappableOop(xOop);
	yOop = interpreterProxy->positive32BitIntegerFor(y);
	xOop = interpreterProxy->popRemappableOop();
	ptOop = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(0, ptOop, xOop);
	interpreterProxy->storePointerofObjectwithValue(1, ptOop, yOop);
	interpreterProxy->pop((interpreterProxy->methodArgumentCount()) + 1);
	interpreterProxy->push(ptOop);
}


/*	Primitive. Gather good random entropy from a system source. */

EXPORT(sqInt) primitiveGatherEntropy(void) {
    sqInt bufOop;
    void *bufPtr;
    sqInt bufSize;
    sqInt okay;

	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	bufOop = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->isBytes(bufOop))) {
		return interpreterProxy->primitiveFail();
	}
	bufSize = interpreterProxy->byteSizeOf(bufOop);
	bufPtr = interpreterProxy->firstIndexableField(bufOop);
	okay = ioGatherEntropy(bufPtr, bufSize);
	if (!(okay)) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop((interpreterProxy->methodArgumentCount()) + 1);
	interpreterProxy->pushBool(1);
}


/*	Primitive. Perform an inplace house holder matrix inversion */

EXPORT(sqInt) primitiveInplaceHouseHolderInvert(void) {
    double beta;
    double d[4][4];
    sqInt i;
    sqInt j;
    sqInt k;
    double m[4][4];
    sqInt r;
    float *rcvr;
    double s;
    double sigma;
    double sum;
    double x[4][4] = { {1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {0, 0, 0, 1} };

	;
	rcvr = stackMatrix(0);
	for (i = 0; i <= 3; i += 1) {
		for (j = 0; j <= 3; j += 1) {
			(m[i])[j] = (rcvr[(i * 4) + j]);
		}
	}
	for (j = 0; j <= 3; j += 1) {
		sigma = 0.0;
		for (i = j; i <= 3; i += 1) {
			sigma += ((m[i])[j]) * ((m[i])[j]);
		}
		if (sigma < 1.0e-10) {
			return interpreterProxy->primitiveFail();
		}
		if (((m[j])[j]) < 0.0) {
			s = sqrt(sigma);
		} else {
			s = 0.0 - (sqrt(sigma));
		}
		for (r = 0; r <= 3; r += 1) {
			(d[j])[r] = s;
		}
		beta = 1.0 / ((s * ((m[j])[j])) - sigma);
		(m[j])[j] = (((m[j])[j]) - s);
		for (k = (j + 1); k <= 3; k += 1) {
			sum = 0.0;
			for (i = j; i <= 3; i += 1) {
				sum += ((m[i])[j]) * ((m[i])[k]);
			}
			sum = sum * beta;
			for (i = j; i <= 3; i += 1) {
				(m[i])[k] = (((m[i])[k]) + (((m[i])[j]) * sum));
			}
		}
		for (r = 0; r <= 3; r += 1) {
			sum = 0.0;
			for (i = j; i <= 3; i += 1) {
				sum += ((x[i])[r]) * ((m[i])[j]);
			}
			sum = sum * beta;
			for (i = j; i <= 3; i += 1) {
				(x[i])[r] = (((x[i])[r]) + (sum * ((m[i])[j])));
			}
		}
	}
	for (r = 0; r <= 3; r += 1) {
		for (i = 3; i >= 0; i += -1) {
			for (j = (i + 1); j <= 3; j += 1) {
				(x[i])[r] = (((x[i])[r]) - (((x[j])[r]) * ((m[i])[j])));
			}
			(x[i])[r] = (((x[i])[r]) / ((d[i])[r]));
		}
	}
	for (i = 0; i <= 3; i += 1) {
		for (j = 0; j <= 3; j += 1) {
			rcvr[(i * 4) + j] = (((float) ((x[i])[j])));
		}
	}
}


/*	Perform an MD5 transform of input */

EXPORT(sqInt) primitiveMD5Transform(void) {
    sqInt bufOop;
    unsigned int *buffer;
    unsigned int *hash;
    sqInt hashOop;

	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	hashOop = interpreterProxy->stackObjectValue(0);
	if (!((interpreterProxy->isWords(hashOop)) && ((interpreterProxy->slotSizeOf(hashOop)) == 4))) {
		return interpreterProxy->primitiveFail();
	}
	hash = interpreterProxy->firstIndexableField(hashOop);
	bufOop = interpreterProxy->stackObjectValue(1);
	if (!((interpreterProxy->isWords(bufOop)) && ((interpreterProxy->slotSizeOf(bufOop)) == 16))) {
		return interpreterProxy->primitiveFail();
	}
	buffer = interpreterProxy->firstIndexableField(bufOop);
	MD5Transform(hash, buffer);
	interpreterProxy->pop((interpreterProxy->methodArgumentCount()) + 1);
	interpreterProxy->push(bufOop);
}

EXPORT(sqInt) primitiveOrthoNormInverseMatrix(void) {
    float *dst;
    sqInt dstOop;
    double rx;
    double ry;
    double rz;
    float *src;
    sqInt srcOop;
    double x;
    double y;
    double z;

	if (!((interpreterProxy->methodArgumentCount()) == 0)) {
		return interpreterProxy->primitiveFail();
	}
	srcOop = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!((interpreterProxy->isWords(srcOop)) && ((interpreterProxy->slotSizeOf(srcOop)) == 16))) {
		return interpreterProxy->primitiveFail();
	}

	/* reload srcOop in case of GC */

	dstOop = interpreterProxy->clone(srcOop);
	srcOop = interpreterProxy->stackObjectValue(0);
	src = interpreterProxy->firstIndexableField(srcOop);

	/* Transpose upper 3x3 matrix */
	/* dst at: 0 put: (src at: 0). */

	dst = interpreterProxy->firstIndexableField(dstOop);
	dst[1] = (src[4]);
	dst[2] = (src[8]);
	dst[4] = (src[1]);
	dst[6] = (src[9]);
	dst[8] = (src[2]);
	dst[9] = (src[6]);
	x = src[3];
	y = src[7];
	z = src[11];
	rx = ((x * (dst[0])) + (y * (dst[1]))) + (z * (dst[2]));
	ry = ((x * (dst[4])) + (y * (dst[5]))) + (z * (dst[6]));
	rz = ((x * (dst[8])) + (y * (dst[9]))) + (z * (dst[10]));
	dst[3] = (((float) (0.0 - rx)));
	dst[7] = (((float) (0.0 - ry)));
	dst[11] = (((float) (0.0 - rz)));
	interpreterProxy->pop(1);
	interpreterProxy->push(dstOop);
}

EXPORT(sqInt) primitiveTransformDirection(void) {
    float *matrix;
    double rx;
    double ry;
    double rz;
    sqInt v3Oop;
    float *vertex;
    double x;
    double y;
    double z;

	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	v3Oop = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!((interpreterProxy->isWords(v3Oop)) && ((interpreterProxy->slotSizeOf(v3Oop)) == 3))) {
		return interpreterProxy->primitiveFail();
	}
	vertex = interpreterProxy->firstIndexableField(v3Oop);
	matrix = stackMatrix(1);
	if (matrix == null) {
		return interpreterProxy->primitiveFail();
	}
	x = vertex[0];
	y = vertex[1];
	z = vertex[2];
	rx = ((x * (matrix[0])) + (y * (matrix[1]))) + (z * (matrix[2]));
	ry = ((x * (matrix[4])) + (y * (matrix[5]))) + (z * (matrix[6]));
	rz = ((x * (matrix[8])) + (y * (matrix[9]))) + (z * (matrix[10]));
	v3Oop = interpreterProxy->clone(v3Oop);
	vertex = interpreterProxy->firstIndexableField(v3Oop);
	vertex[0] = (((float) rx));
	vertex[1] = (((float) ry));
	vertex[2] = (((float) rz));
	interpreterProxy->pop(2);
	interpreterProxy->push(v3Oop);
}


/*	Transform two matrices into the third */

EXPORT(sqInt) primitiveTransformMatrixWithInto(void) {
    float *m1;
    float *m2;
    float *m3;

	m3 = stackMatrix(0);
	m2 = stackMatrix(1);
	m1 = stackMatrix(2);
	if (((m1 == null) || (m2 == null)) || (m3 == null)) {
		return interpreterProxy->primitiveFail();
	}
	if (m2 == m3) {
		return interpreterProxy->primitiveFail();
	}
	transformMatrixwithinto(m1, m2, m3);
	interpreterProxy->pop(3);
}

EXPORT(sqInt) primitiveTransformVector3(void) {
    float *matrix;
    double rw;
    double rx;
    double ry;
    double rz;
    sqInt v3Oop;
    float *vertex;
    double x;
    double y;
    double z;

	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	v3Oop = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!((interpreterProxy->isWords(v3Oop)) && ((interpreterProxy->slotSizeOf(v3Oop)) == 3))) {
		return interpreterProxy->primitiveFail();
	}
	vertex = interpreterProxy->firstIndexableField(v3Oop);
	matrix = stackMatrix(1);
	if (matrix == null) {
		return interpreterProxy->primitiveFail();
	}
	x = vertex[0];
	y = vertex[1];
	z = vertex[2];
	rx = (((x * (matrix[0])) + (y * (matrix[1]))) + (z * (matrix[2]))) + (matrix[3]);
	ry = (((x * (matrix[4])) + (y * (matrix[5]))) + (z * (matrix[6]))) + (matrix[7]);
	rz = (((x * (matrix[8])) + (y * (matrix[9]))) + (z * (matrix[10]))) + (matrix[11]);
	rw = (((x * (matrix[12])) + (y * (matrix[13]))) + (z * (matrix[14]))) + (matrix[15]);
	v3Oop = interpreterProxy->clone(v3Oop);
	vertex = interpreterProxy->firstIndexableField(v3Oop);
	if (rw == 1.0) {
		vertex[0] = (((float) rx));
		vertex[1] = (((float) ry));
		vertex[2] = (((float) rz));
	} else {
		if (rw == 0.0) {
			rw = 0.0;
		} else {
			rw = 1.0 / rw;
		}
		vertex[0] = (((float) (rx * rw)));
		vertex[1] = (((float) (ry * rw)));
		vertex[2] = (((float) (rz * rw)));
	}
	interpreterProxy->pop(2);
	interpreterProxy->push(v3Oop);
}

EXPORT(sqInt) primitiveTransposeMatrix(void) {
    float *dst;
    sqInt dstOop;
    float *src;
    sqInt srcOop;

	if (!((interpreterProxy->methodArgumentCount()) == 0)) {
		return interpreterProxy->primitiveFail();
	}
	srcOop = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!((interpreterProxy->isWords(srcOop)) && ((interpreterProxy->slotSizeOf(srcOop)) == 16))) {
		return interpreterProxy->primitiveFail();
	}

	/* reload srcOop in case of GC */

	dstOop = interpreterProxy->clone(srcOop);
	srcOop = interpreterProxy->stackObjectValue(0);
	src = interpreterProxy->firstIndexableField(srcOop);

	/* dst at: 0 put: (src at: 0). */

	dst = interpreterProxy->firstIndexableField(dstOop);
	dst[1] = (src[4]);
	dst[2] = (src[8]);
	dst[3] = (src[12]);
	dst[4] = (src[1]);
	dst[6] = (src[9]);
	dst[7] = (src[13]);
	dst[8] = (src[2]);
	dst[9] = (src[6]);
	dst[11] = (src[14]);
	dst[12] = (src[3]);
	dst[13] = (src[7]);
	dst[14] = (src[11]);
	interpreterProxy->pop(1);
	interpreterProxy->push(dstOop);
}


/*	Primitive. Answer whether an AABB intersects with a given triangle */

EXPORT(sqInt) primitiveTriBoxIntersects(void) {
    float*maxCorner;
    float*minCorner;
    sqInt result;
    float*v0;
    float*v1;
    float*v2;

	if (!((interpreterProxy->methodArgumentCount()) == 5)) {
		return interpreterProxy->primitiveFail();
	}
	v2 = stackVector3(0);
	v1 = stackVector3(1);
	v0 = stackVector3(2);
	maxCorner = stackVector3(3);
	minCorner = stackVector3(4);
	result = triBoxOverlap(minCorner, maxCorner, v0, v1, v2);
	if (result < 0) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->pop(6);
	interpreterProxy->pushBool(result);
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(sqInt) setInterpreter(struct VirtualMachine*anInterpreter) {
    sqInt ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}


/*	Load a 4x4 transformation matrix from the interpreter stack.
	Return a pointer to the matrix data if successful, nil otherwise. */

static void* stackMatrix(sqInt index) {
    sqInt oop;

	oop = interpreterProxy->stackObjectValue(index);
	if (oop == null) {
		return null;
	}
	if ((interpreterProxy->isWords(oop)) && ((interpreterProxy->slotSizeOf(oop)) == 16)) {
		return interpreterProxy->firstIndexableField(oop);
	}
	return null;
}


/*	Load a Vector3 from the interpreter stack.
	Return a pointer to the float data if successful, nil otherwise. */

static void* stackVector3(sqInt index) {
    sqInt oop;

	oop = interpreterProxy->stackObjectValue(index);
	if (oop == null) {
		return null;
	}
	if ((interpreterProxy->isWords(oop)) && ((interpreterProxy->slotSizeOf(oop)) == 3)) {
		return interpreterProxy->firstIndexableField(oop);
	}
	return null;
}


/*	Transform src with arg into dst.
	It is allowed that src == dst but not arg == dst */

static sqInt transformMatrixwithinto(float *src, float *arg, float *dst) {
    float c1;
    float c2;
    float c3;
    float c4;
    sqInt i;
    float *m1;
    float *m2;
    float *m3;

	m1 = ((float *) src);
	m2 = ((float *) arg);
	m3 = ((float *) dst);
	for (i = 0; i <= 3; i += 1) {

		/* Compute next row */

		c1 = ((((m1[0]) * (m2[0])) + ((m1[1]) * (m2[4]))) + ((m1[2]) * (m2[8]))) + ((m1[3]) * (m2[12]));
		c2 = ((((m1[0]) * (m2[1])) + ((m1[1]) * (m2[5]))) + ((m1[2]) * (m2[9]))) + ((m1[3]) * (m2[13]));
		c3 = ((((m1[0]) * (m2[2])) + ((m1[1]) * (m2[6]))) + ((m1[2]) * (m2[10]))) + ((m1[3]) * (m2[14]));

		/* Store result */

		c4 = ((((m1[0]) * (m2[3])) + ((m1[1]) * (m2[7]))) + ((m1[2]) * (m2[11]))) + ((m1[3]) * (m2[15]));
		m3[0] = c1;
		m3[1] = c2;
		m3[2] = c3;
		m3[3] = c4;
		m1 += 4;
		m3 += 4;
	}
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* CroquetPlugin_exports[][3] = {
	{"CroquetPlugin", "primitiveTransformMatrixWithInto", (void*)primitiveTransformMatrixWithInto},
	{"CroquetPlugin", "primitiveMD5Transform", (void*)primitiveMD5Transform},
	{"CroquetPlugin", "primitiveTriBoxIntersects", (void*)primitiveTriBoxIntersects},
	{"CroquetPlugin", "primitiveTransformVector3", (void*)primitiveTransformVector3},
	{"CroquetPlugin", "primitiveGatherEntropy", (void*)primitiveGatherEntropy},
	{"CroquetPlugin", "primitiveTransposeMatrix", (void*)primitiveTransposeMatrix},
	{"CroquetPlugin", "primitiveInplaceHouseHolderInvert", (void*)primitiveInplaceHouseHolderInvert},
	{"CroquetPlugin", "setInterpreter", (void*)setInterpreter},
	{"CroquetPlugin", "primitiveOrthoNormInverseMatrix", (void*)primitiveOrthoNormInverseMatrix},
	{"CroquetPlugin", "getModuleName", (void*)getModuleName},
	{"CroquetPlugin", "primitiveTransformDirection", (void*)primitiveTransformDirection},
	{"CroquetPlugin", "primitiveARC4Transform", (void*)primitiveARC4Transform},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

