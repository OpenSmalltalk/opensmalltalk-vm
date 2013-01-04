/* Automatically generated from Squeak on 4 January 2013 12:29:04 am 
   by VMMaker 4.10.8
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
#include "b3d.h"
#include "b3d.h"

#include "sqMemoryAccess.h"


/*** Constants ***/
#define AmbientPart 0
#define DiffusePart 4
#define EmissionAlpha 15
#define EmissionBlue 14
#define EmissionGreen 13
#define EmissionRed 12
#define FlagAmbientPart 256
#define FlagAttenuated 4
#define FlagDiffusePart 512
#define FlagDirectional 2
#define FlagHasSpot 8
#define FlagM44Identity 1
#define FlagM44NoPerspective 2
#define FlagM44NoTranslation 4
#define FlagPositional 1
#define FlagSpecularPart 1024
#define InAllMask 1365
#define InBackBit 1024
#define InBottomBit 64
#define InFrontBit 256
#define InLeftBit 1
#define InRightBit 4
#define InTopBit 16
#define MaterialShininess 16
#define MaterialSize 17
#define OutAllMask 2730
#define OutBackBit 2048
#define OutBottomBit 128
#define OutFrontBit 512
#define OutLeftBit 2
#define OutRightBit 8
#define OutTopBit 32
#define PrimLightAttenuationConstant 18
#define PrimLightAttenuationLinear 19
#define PrimLightAttenuationSquared 20
#define PrimLightDirection 15
#define PrimLightDirectionX 15
#define PrimLightDirectionY 16
#define PrimLightDirectionZ 17
#define PrimLightFlags 21
#define PrimLightPositionX 12
#define PrimLightPositionY 13
#define PrimLightPositionZ 14
#define PrimLightSize 32
#define PrimTypeMax 6
#define PrimVertexSize 16
#define PrimVtxClipFlags 13
#define PrimVtxColor32 12
#define PrimVtxNormal 3
#define PrimVtxNormalX 3
#define PrimVtxNormalY 4
#define PrimVtxNormalZ 5
#define PrimVtxPosition 0
#define PrimVtxPositionX 0
#define PrimVtxPositionY 1
#define PrimVtxPositionZ 2
#define PrimVtxRasterPosW 11
#define PrimVtxRasterPosX 8
#define PrimVtxRasterPosY 9
#define PrimVtxRasterPosZ 10
#define PrimVtxTexCoordU 6
#define PrimVtxTexCoordV 7
#define PrimVtxTexCoords 6
#define SpecularPart 8
#define SpotLightDeltaCos 24
#define SpotLightExponent 25
#define SpotLightMinCos 22
#define VBTrackAmbient 1
#define VBTrackDiffuse 2
#define VBTrackEmission 8
#define VBTrackSpecular 4
#define VBTwoSidedLighting 64
#define VBUseLocalViewer 128
#define VBVtxHasNormals 16

/*** Function Prototypes ***/
static sqInt analyzeMatrix3x3Length(float *m);
static sqInt analyzeMatrix(float *m);
#pragma export on
EXPORT(sqInt) b3dClipPolygon(void);
EXPORT(sqInt) b3dComputeMinIndexZ(void);
EXPORT(sqInt) b3dComputeMinZ(void);
EXPORT(sqInt) b3dDetermineClipFlags(void);
EXPORT(sqInt) b3dInitPrimitiveObject(void);
EXPORT(sqInt) b3dInitializeRasterizerState(void);
EXPORT(sqInt) b3dInplaceHouseHolderInvert(void);
EXPORT(sqInt) b3dLoadIndexArray(void);
EXPORT(sqInt) b3dLoadVertexBuffer(void);
EXPORT(sqInt) b3dMapVertexBuffer(void);
EXPORT(sqInt) b3dOrthoNormInverseMatrix(void);
EXPORT(sqInt) b3dPrimitiveNextClippedTriangle(void);
EXPORT(sqInt) b3dPrimitiveObjectSize(void);
EXPORT(sqInt) b3dPrimitiveTextureSize(void);
EXPORT(sqInt) b3dRasterizerVersion(void);
EXPORT(sqInt) b3dShadeVertexBuffer(void);
EXPORT(sqInt) b3dShaderVersion(void);
EXPORT(sqInt) b3dStartRasterizer(void);
EXPORT(sqInt) b3dTransformDirection(void);
EXPORT(sqInt) b3dTransformMatrixWithInto(void);
EXPORT(sqInt) b3dTransformPoint(void);
EXPORT(sqInt) b3dTransformPrimitiveNormal(void);
EXPORT(sqInt) b3dTransformPrimitivePosition(void);
EXPORT(sqInt) b3dTransformPrimitiveRasterPosition(void);
EXPORT(sqInt) b3dTransformVertexBuffer(void);
EXPORT(sqInt) b3dTransformerVersion(void);
EXPORT(sqInt) b3dTransposeMatrix(void);
#pragma export off
static sqInt clipPolygoncountwithmask(int *vtxArray, sqInt vtxCount, int *tempVtxArray, sqInt outMask);
static sqInt clipPolygonBackFromtocount(int *buf1, int *buf2, sqInt n);
static sqInt clipPolygonBottomFromtocount(int *buf1, int *buf2, sqInt n);
static sqInt clipPolygonFrontFromtocount(int *buf1, int *buf2, sqInt n);
static sqInt clipPolygonLeftFromtocount(int *buf1, int *buf2, sqInt n);
static sqInt clipPolygonRightFromtocount(int *buf1, int *buf2, sqInt n);
static sqInt clipPolygonTopFromtocount(int *buf1, int *buf2, sqInt n);
static sqInt computeSpecularDirection(void);
static double computeSpotFactor(void);
static sqInt determineClipFlagscount(void *vtxArray, sqInt count);
static double dotProductOfFloatwithDouble(float * v1, double *v2);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static sqInt halt(void);
#pragma export on
EXPORT(sqInt) initialiseModule(void);
#pragma export off
static sqInt interpolateFromtoatinto(float *last, float *next, double t, float *out);
static double inverseLengthOfDouble(double * aVector);
static double inverseLengthOfFloat(float * aVector);
static sqInt loadObjectsFrom(sqInt stackIndex);
static sqInt loadRasterizerState(sqInt stackIndex);
static sqInt loadTextureinto(sqInt textureOop, B3DTexture *destPtr);
static sqInt loadTexturesFrom(sqInt stackIndex);
static sqInt loadViewportFrom(sqInt stackIndex);
static sqInt mapVBofSizeinto(void *vtxArray, sqInt vtxCount, sqInt boxArray);
#pragma export on
EXPORT(sqInt) moduleUnloaded(char *aModuleName);
EXPORT(sqInt) primitiveSetBitBltPlugin(void);
#pragma export off
static double processIndexedofSizeidxArrayidxSize(float *vtxArray, sqInt vtxSize, int *idxArray, sqInt idxSize);
static sqInt processIndexedIDXofSizeidxArrayidxSize(float *vtxArray, sqInt vtxSize, int *idxArray, sqInt idxSize);
static double processNonIndexedofSize(float *vtxArray, sqInt vtxSize);
static sqInt processNonIndexedIDXofSize(float *vtxArray, sqInt vtxSize);
#pragma export on
EXPORT(sqInt) setInterpreter(struct VirtualMachine*anInterpreter);
#pragma export off
static sqInt shadeVertex(void);
static sqInt stackLightArrayValue(sqInt stackIndex);
static void * stackMaterialValue(sqInt stackIndex);
static void* stackMatrix(sqInt index);
static void* stackPrimitiveIndexArrayofSizevalidateforVertexSize(sqInt stackIndex, sqInt nItems, sqInt aBool, sqInt maxIndex);
static void* stackPrimitiveVertex(sqInt index);
static void* stackPrimitiveVertexArrayofSize(sqInt index, sqInt nItems);
static sqInt storeObjectsInto(sqInt stackIndex);
static sqInt transformMatrixwithinto(float *src, float *arg, float *dst);
static sqInt transformPrimitiveNormalbyrescale(float *pVertex, float *matrix, sqInt rescale);
static sqInt transformPrimitivePositionby(float *pVertex, float *matrix);
static sqInt transformPrimitivePositionFastby(float *pVertex, float *matrix);
static sqInt transformPrimitivePositionFasterby(float *pVertex, float *matrix);
static sqInt transformPrimitiveRasterPositionby(float *pVertex, float *matrix);
static sqInt transformVBcountbyandflags(float *vtxArray, sqInt vtxCount, float *modelViewMatrix, float *projectionMatrix, sqInt flags);
static void* vbLoadArraysize(sqInt oop, sqInt count);
/*** Variables ***/
static char bbPluginName[256] = "BitBltPlugin";
static sqInt copyBitsFn;

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static double l2vDirection[3];
static double l2vDistance;
static double l2vSpecDir[3];
static sqInt lightFlags;
static double lightScale;
static float* litVertex;
static sqInt loadBBFn;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"B3DEnginePlugin (i)"
#else
	"B3DEnginePlugin (e)"
#endif
;
static float* primLight;
static float* primMaterial;
static B3DRasterizerState state;
static sqInt vbFlags;
static B3DPrimitiveViewport viewport;
static double vtxInColor[4];
static double vtxOutColor[4];



/*	Check if the matrix scales normals to non-unit length. */

static sqInt analyzeMatrix3x3Length(float *m) {
    double det;

	det = (((((((m[0]) * (m[5])) * (m[10])) - (((m[2]) * (m[5])) * (m[8]))) + (((m[4]) * (m[9])) * (m[2]))) - (((m[6]) * (m[9])) * (m[0]))) + (((m[8]) * (m[1])) * (m[6]))) - (((m[10]) * (m[1])) * (m[4]));
	return (det < 0.99) || (det > 1.01);
}


/*	Analyze the matrix and return the appropriate flags */

static sqInt analyzeMatrix(float *m) {
    sqInt flags;

	flags = 0;
	if (((m[12]) == 0.0) && (((m[13]) == 0.0) && (((m[14]) == 0.0) && ((m[15]) == 1.0)))) {

		/* Check translation */

		flags = flags | FlagM44NoPerspective;
		if (((m[3]) == 0.0) && (((m[7]) == 0.0) && ((m[11]) == 0.0))) {

			/* Check for identity */

			flags = flags | FlagM44NoTranslation;
			if (((m[0]) == 1.0) && (((m[5]) == 1.0) && (((m[10]) == 1.0) && (((m[1]) == 0.0) && (((m[2]) == 0.0) && (((m[4]) == 0.0) && (((m[6]) == 0.0) && (((m[8]) == 0.0) && ((m[9]) == 0.0))))))))) {
				flags = flags | FlagM44Identity;
			}
		}
	}
	return flags;
}


/*	Primitive. Clip the polygon given in the vertexArray using the temporary vertex array which is assumed to have sufficient size. */

EXPORT(sqInt) b3dClipPolygon(void) {
    sqInt count;
    sqInt outMask;
    int *tempVtxArray;
    int *vtxArray;
    sqInt vtxCount;

	if (!((interpreterProxy->methodArgumentCount()) == 4)) {
		return interpreterProxy->primitiveFail();
	}
	outMask = interpreterProxy->stackIntegerValue(0);
	vtxCount = interpreterProxy->stackIntegerValue(2);
	vtxArray = stackPrimitiveVertexArrayofSize(3, vtxCount + 4);
	tempVtxArray = stackPrimitiveVertexArrayofSize(1, vtxCount + 4);
	if ((vtxArray == null) || ((tempVtxArray == null) || (interpreterProxy->failed()))) {
		return interpreterProxy->primitiveFail();
	}
	vtxArray -= PrimVertexSize;
	tempVtxArray -= PrimVertexSize;
	count = clipPolygoncountwithmask(vtxArray, vtxCount, tempVtxArray, outMask);
	interpreterProxy->pop(5);
	interpreterProxy->pushInteger(count);
}


/*	Primitive. Compute and return the index for the minimal z value of all objects in the vertex buffer. */

EXPORT(sqInt) b3dComputeMinIndexZ(void) {
    int *idxArray;
    sqInt idxSize;
    sqInt minIndex;
    sqInt primType;
    float *vtxArray;
    sqInt vtxSize;

	if (!((interpreterProxy->methodArgumentCount()) == 5)) {
		return interpreterProxy->primitiveFail();
	}
	idxSize = interpreterProxy->stackIntegerValue(0);
	vtxSize = interpreterProxy->stackIntegerValue(2);
	primType = interpreterProxy->stackIntegerValue(4);
	if (interpreterProxy->failed()) {
		return null;
	}
	vtxArray = stackPrimitiveVertexArrayofSize(3, vtxSize);
	idxArray = stackPrimitiveIndexArrayofSizevalidateforVertexSize(1, idxSize, 1, vtxSize);
	if ((vtxArray == null) || ((idxArray == null) || (interpreterProxy->failed()))) {
		return interpreterProxy->primitiveFail();
	}
	if ((primType < 1) || (primType > 6)) {
		return interpreterProxy->primitiveFail();
	}
	if (primType <= 3) {
		minIndex = processNonIndexedIDXofSize(vtxArray, vtxSize);
	} else {
		minIndex = processIndexedIDXofSizeidxArrayidxSize(vtxArray, vtxSize, idxArray, idxSize);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(6);
		interpreterProxy->pushInteger(minIndex);
	}
}


/*	Primitive. Compute and return the minimal z value of all objects in the vertex buffer. */

EXPORT(sqInt) b3dComputeMinZ(void) {
    int *idxArray;
    sqInt idxSize;
    double minZ;
    sqInt primType;
    float *vtxArray;
    sqInt vtxSize;

	if (!((interpreterProxy->methodArgumentCount()) == 5)) {
		return interpreterProxy->primitiveFail();
	}
	idxSize = interpreterProxy->stackIntegerValue(0);
	vtxSize = interpreterProxy->stackIntegerValue(2);
	primType = interpreterProxy->stackIntegerValue(4);
	if (interpreterProxy->failed()) {
		return null;
	}
	vtxArray = stackPrimitiveVertexArrayofSize(3, vtxSize);
	idxArray = stackPrimitiveIndexArrayofSizevalidateforVertexSize(1, idxSize, 1, vtxSize);
	if ((vtxArray == null) || ((idxArray == null) || (interpreterProxy->failed()))) {
		return interpreterProxy->primitiveFail();
	}
	if ((primType < 1) || (primType > 6)) {
		return interpreterProxy->primitiveFail();
	}
	if (primType <= 3) {
		minZ = processNonIndexedofSize(vtxArray, vtxSize);
	} else {
		minZ = processIndexedofSizeidxArrayidxSize(vtxArray, vtxSize, idxArray, idxSize);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(6);
		interpreterProxy->pushFloat(minZ);
	}
}


/*	Primitive. Determine the clipping flags for all vertices. */

EXPORT(sqInt) b3dDetermineClipFlags(void) {
    sqInt result;
    void *vtxArray;
    sqInt vtxCount;

	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	vtxCount = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	vtxArray = stackPrimitiveVertexArrayofSize(1, vtxCount);
	if ((vtxArray == null) || (interpreterProxy->failed())) {
		return interpreterProxy->primitiveFail();
	}
	result = determineClipFlagscount(vtxArray, vtxCount);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(3);
		interpreterProxy->pushInteger(result);
	}
}

EXPORT(sqInt) b3dInitPrimitiveObject(void) {
    int *idxArray;
    sqInt idxSize;
    void *primObj;
    sqInt primOop;
    sqInt primSize;
    sqInt primitive;
    sqInt textureIndex;
    int *vtxArray;
    sqInt vtxSize;

	if (!((interpreterProxy->methodArgumentCount()) == 8)) {
		return interpreterProxy->primitiveFail();
	}
	textureIndex = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	loadViewportFrom(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	vtxSize = interpreterProxy->stackIntegerValue(4);
	vtxArray = stackPrimitiveVertexArrayofSize(5, vtxSize);
	if (vtxArray == null) {
		return interpreterProxy->primitiveFail();
	}
	idxSize = interpreterProxy->stackIntegerValue(2);
	idxArray = stackPrimitiveIndexArrayofSizevalidateforVertexSize(3, idxSize, 1, vtxSize);
	if (idxArray == null) {
		return interpreterProxy->primitiveFail();
	}
	primitive = interpreterProxy->stackIntegerValue(6);
	if ((primitive < 1) || (primitive > PrimTypeMax)) {
		return interpreterProxy->primitiveFail();
	}
	if (!((primitive == 3) || ((primitive == 5) || (primitive == 6)))) {
		return interpreterProxy->primitiveFail();
	}
	primOop = interpreterProxy->stackObjectValue(7);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->isWords(primOop))) {
		return interpreterProxy->primitiveFail();
	}
	primObj = interpreterProxy->firstIndexableField(primOop);

	/* Do the work */

	primSize = interpreterProxy->byteSizeOf(primOop);
	if (primitive == 3) {
		if (b3dAddPolygonObject((void*) primObj, primSize, B3D_FACE_RGB, textureIndex, (B3DPrimitiveVertex*) vtxArray, vtxSize, &viewport) != B3D_NO_ERROR) {
			return interpreterProxy->primitiveFail();
		}
	}
	if (primitive == 5) {
		if (b3dAddIndexedTriangleObject((void*) primObj, primSize, B3D_FACE_RGB, textureIndex, (B3DPrimitiveVertex*) vtxArray, vtxSize, (B3DInputFace*) idxArray, idxSize / 3, &viewport) != B3D_NO_ERROR) {
			return interpreterProxy->primitiveFail();
		}
	}
	if (primitive == 6) {
		if (b3dAddIndexedQuadObject((void*) primObj, primSize, B3D_FACE_RGB, textureIndex, (B3DPrimitiveVertex*) vtxArray, vtxSize, (B3DInputQuad*) idxArray, idxSize / 4, &viewport) != B3D_NO_ERROR) {
			return interpreterProxy->primitiveFail();
		}
	}
	interpreterProxy->pop(9);
	interpreterProxy->push(primOop);
}


/*	Primitive. Initialize the primitive level objects of the given rasterizer. */

EXPORT(sqInt) b3dInitializeRasterizerState(void) {
    void *obj;
    sqInt objLen;
    sqInt objOop;
    sqInt stateOop;

	if (!((interpreterProxy->methodArgumentCount()) == 0)) {
		return interpreterProxy->primitiveFail();
	}
	stateOop = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!((interpreterProxy->isPointers(stateOop)) && ((interpreterProxy->slotSizeOf(stateOop)) >= 7))) {
		return interpreterProxy->primitiveFail();
	}
	objOop = interpreterProxy->fetchPointerofObject(0, stateOop);
	if (((objOop & 1)) || (!(interpreterProxy->isWords(objOop)))) {
		return interpreterProxy->primitiveFail();
	}
	objLen = interpreterProxy->byteSizeOf(objOop);
	obj = interpreterProxy->firstIndexableField(objOop);
	if (b3dInitializeFaceAllocator(obj, objLen) != B3D_NO_ERROR) {
		return interpreterProxy->primitiveFail();
	}
	objOop = interpreterProxy->fetchPointerofObject(1, stateOop);
	if (((objOop & 1)) || (!(interpreterProxy->isWords(objOop)))) {
		return interpreterProxy->primitiveFail();
	}
	objLen = interpreterProxy->byteSizeOf(objOop);
	obj = interpreterProxy->firstIndexableField(objOop);
	if (b3dInitializeEdgeAllocator(obj, objLen) != B3D_NO_ERROR) {
		return interpreterProxy->primitiveFail();
	}
	objOop = interpreterProxy->fetchPointerofObject(2, stateOop);
	if (((objOop & 1)) || (!(interpreterProxy->isWords(objOop)))) {
		return interpreterProxy->primitiveFail();
	}
	objLen = interpreterProxy->byteSizeOf(objOop);
	obj = interpreterProxy->firstIndexableField(objOop);
	if (b3dInitializeAttrAllocator(obj, objLen) != B3D_NO_ERROR) {
		return interpreterProxy->primitiveFail();
	}
	objOop = interpreterProxy->fetchPointerofObject(3, stateOop);
	if (((objOop & 1)) || (!(interpreterProxy->isWords(objOop)))) {
		return interpreterProxy->primitiveFail();
	}
	objLen = interpreterProxy->byteSizeOf(objOop);
	obj = interpreterProxy->firstIndexableField(objOop);
	if (b3dInitializeAET(obj, objLen) != B3D_NO_ERROR) {
		return interpreterProxy->primitiveFail();
	}
	objOop = interpreterProxy->fetchPointerofObject(4, stateOop);
	if (((objOop & 1)) || (!(interpreterProxy->isWords(objOop)))) {
		return interpreterProxy->primitiveFail();
	}
	objLen = interpreterProxy->byteSizeOf(objOop);
	obj = interpreterProxy->firstIndexableField(objOop);
	if (b3dInitializeEdgeList(obj, objLen) != B3D_NO_ERROR) {
		return interpreterProxy->primitiveFail();
	}
	objOop = interpreterProxy->fetchPointerofObject(5, stateOop);
	if (((objOop & 1)) || (!(interpreterProxy->isWords(objOop)))) {
		return interpreterProxy->primitiveFail();
	}
	objLen = interpreterProxy->byteSizeOf(objOop);
	obj = interpreterProxy->firstIndexableField(objOop);
	if (b3dInitializeFillList(obj, objLen) != B3D_NO_ERROR) {
		return interpreterProxy->primitiveFail();
	}
}


/*	Primitive. Perform an inplace house holder matrix inversion */

EXPORT(sqInt) b3dInplaceHouseHolderInvert(void) {
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


/*	Primitive. Load the given index array into the receiver.
	NOTE: dstStart is a zero-based index. */

EXPORT(sqInt) b3dLoadIndexArray(void) {
    sqInt count;
    sqInt dstArray;
    int *dstPtr;
    sqInt dstSize;
    sqInt dstStart;
    sqInt i;
    sqInt idx;
    sqInt maxValue;
    sqInt srcArray;
    int *srcPtr;
    sqInt vtxOffset;

	vtxOffset = interpreterProxy->stackIntegerValue(0);
	maxValue = interpreterProxy->stackIntegerValue(1);
	count = interpreterProxy->stackIntegerValue(2);
	srcArray = interpreterProxy->stackObjectValue(3);
	dstStart = interpreterProxy->stackIntegerValue(4);
	dstArray = interpreterProxy->stackObjectValue(5);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->isWords(srcArray))) {
		return interpreterProxy->primitiveFail();
	}
	if ((interpreterProxy->slotSizeOf(srcArray)) < count) {
		return interpreterProxy->primitiveFail();
	}

	/* Check dstArray */

	srcPtr = ((int*) (interpreterProxy->firstIndexableField(srcArray)));

	/* Check if there is enough room left in dstArray */

	dstSize = interpreterProxy->slotSizeOf(dstArray);
	if ((dstStart + count) > dstSize) {
		return interpreterProxy->primitiveFail();
	}

	/* Do the actual work */

	dstPtr = ((int *) (interpreterProxy->firstIndexableField(dstArray)));
	for (i = 0; i <= (count - 1); i += 1) {
		idx = srcPtr[i];
		if ((idx < 1) || (idx > maxValue)) {
			return interpreterProxy->primitiveFail();
		}
		dstPtr[dstStart + i] = (idx + vtxOffset);
	}
	interpreterProxy->pop(7);
	interpreterProxy->pushInteger(count);
}


/*	Primitive. Load the data into the given vertex buffer.
	NOTE: dstStart is a zero-based index. */

EXPORT(sqInt) b3dLoadVertexBuffer(void) {
    int *colorPtr;
    sqInt count;
    int *defaultColor;
    int *defaultNormal;
    int *defaultTexCoords;
    int *defaultVtx;
    int *dstPtr;
    sqInt dstStart;
    sqInt i;
    int *normalPtr;
    int *pVtx;
    int *texPtr;
    int *vtxPtr;

	defaultVtx = stackPrimitiveVertex(0);
	count = interpreterProxy->stackIntegerValue(1);
	texPtr = vbLoadArraysize(interpreterProxy->stackObjectValue(2), 2 * count);
	colorPtr = vbLoadArraysize(interpreterProxy->stackObjectValue(3), count);
	normalPtr = vbLoadArraysize(interpreterProxy->stackObjectValue(4), 3 * count);
	vtxPtr = vbLoadArraysize(interpreterProxy->stackObjectValue(5), 3 * count);
	dstStart = interpreterProxy->stackIntegerValue(6);

	/* Check for all problems above */

	dstPtr = stackPrimitiveVertexArrayofSize(7, dstStart + count);
	if ((dstPtr == null) || ((defaultVtx == null) || (interpreterProxy->failed()))) {
		return interpreterProxy->primitiveFail();
	}
	if (normalPtr == null) {
		defaultNormal = defaultVtx + PrimVtxNormal;
	} else {
		defaultNormal = normalPtr;
	}
	if (texPtr == null) {
		defaultTexCoords = defaultVtx + PrimVtxTexCoords;
	} else {
		defaultTexCoords = texPtr;
	}
	if (colorPtr == null) {
		defaultColor = defaultVtx + PrimVtxColor32;
	} else {
		defaultColor = colorPtr;
	}
	pVtx = dstPtr + (dstStart * PrimVertexSize);
	for (i = 0; i <= (count - 1); i += 1) {
		pVtx[PrimVtxPositionX] = (vtxPtr[0]);
		pVtx[PrimVtxPositionY] = (vtxPtr[1]);
		pVtx[PrimVtxPositionZ] = (vtxPtr[2]);
		pVtx[PrimVtxNormalX] = (defaultNormal[0]);
		pVtx[PrimVtxNormalY] = (defaultNormal[1]);
		pVtx[PrimVtxNormalZ] = (defaultNormal[2]);
		pVtx[PrimVtxColor32] = (defaultColor[0]);
		pVtx[PrimVtxTexCoordU] = (defaultTexCoords[0]);
		pVtx[PrimVtxTexCoordV] = (defaultTexCoords[1]);
		pVtx += PrimVertexSize;
		vtxPtr += 3;
		if (!(normalPtr == null)) {
			defaultNormal += 3;
		}
		if (!(colorPtr == null)) {
			defaultColor += 1;
		}
		if (!(texPtr == null)) {
			defaultTexCoords += 2;
		}
	}
	interpreterProxy->pop(9);
	interpreterProxy->pushInteger(count);
}


/*	Primitive. Determine the bounds for all vertices in the vertex buffer. */

EXPORT(sqInt) b3dMapVertexBuffer(void) {
    sqInt boxArray;
    void *vtxArray;
    sqInt vtxCount;

	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}
	boxArray = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(((interpreterProxy->fetchClassOf(boxArray)) == (interpreterProxy->classArray())) && ((interpreterProxy->slotSizeOf(boxArray)) == 4))) {
		return interpreterProxy->primitiveFail();
	}
	vtxCount = interpreterProxy->stackIntegerValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	vtxArray = stackPrimitiveVertexArrayofSize(2, vtxCount);
	if ((vtxArray == null) || (interpreterProxy->failed())) {
		return interpreterProxy->primitiveFail();
	}
	mapVBofSizeinto(vtxArray, vtxCount, boxArray);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(3);
	}
}

EXPORT(sqInt) b3dOrthoNormInverseMatrix(void) {
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


/*	Primitive. Return the next clipped triangle from the vertex buffer and return its index. */

EXPORT(sqInt) b3dPrimitiveNextClippedTriangle(void) {
    sqInt firstIndex;
    sqInt i;
    sqInt idx1;
    sqInt idx2;
    sqInt idx3;
    int *idxArray;
    sqInt idxCount;
    sqInt triMask;
    int *vtxArray;
    sqInt vtxCount;

	if (!((interpreterProxy->methodArgumentCount()) == 5)) {
		return interpreterProxy->primitiveFail();
	}
	idxCount = interpreterProxy->stackIntegerValue(0);
	vtxCount = interpreterProxy->stackIntegerValue(2);
	firstIndex = interpreterProxy->stackIntegerValue(4);
	if (interpreterProxy->failed()) {
		return null;
	}
	vtxArray = stackPrimitiveVertexArrayofSize(3, vtxCount);
	idxArray = stackPrimitiveIndexArrayofSizevalidateforVertexSize(1, idxCount, 1, vtxCount);
	if ((vtxArray == null) || ((idxArray == null) || (interpreterProxy->failed()))) {
		return interpreterProxy->primitiveFail();
	}
	idxArray -= 1;
	vtxArray -= PrimVertexSize;
	for (i = firstIndex; i <= idxCount; i += 3) {
		idx1 = idxArray[i];
		idx2 = idxArray[i + 1];
		idx3 = idxArray[i + 2];
		if (!((idx1 == 0) || ((idx2 == 0) || (idx3 == 0)))) {

			/* Check if tri is completely inside */

			triMask = (vtxArray[(idx1 * PrimVertexSize) + PrimVtxClipFlags]) & ((vtxArray[(idx2 * PrimVertexSize) + PrimVtxClipFlags]) & (vtxArray[(idx3 * PrimVertexSize) + PrimVtxClipFlags]));
			if (!((InAllMask & triMask) == InAllMask)) {

				/* Tri is not completely inside -> needs clipping. */

				if (triMask & OutAllMask) {

					/* tri is completely outside. Store all zeros */

					idxArray[i] = 0;
					idxArray[i + 1] = 0;
					idxArray[i + 2] = 0;
				} else {

					/* tri must be partially clipped. */

					interpreterProxy->pop(6);
					interpreterProxy->pushInteger(i);
					return null;
				}
			}
		}
	}
	interpreterProxy->pop(6);
	interpreterProxy->pushInteger(0);
}


/*	Primitive. Return the minimal number of words needed for a primitive object. */

EXPORT(sqInt) b3dPrimitiveObjectSize(void) {
    sqInt objSize;

	objSize = (((sqInt) (sizeof(B3DPrimitiveObject) + sizeof(B3DPrimitiveVertex)) >> 2)) + 1;
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(objSize);
}


/*	Primitive. Return the minimal number of words needed for a primitive object. */

EXPORT(sqInt) b3dPrimitiveTextureSize(void) {
    sqInt objSize;

	objSize = (((sqInt) (sizeof(B3DTexture)) >> 2)) + 1;
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(objSize);
}


/*	Primitive. Return the version of the rasterizer. */

EXPORT(sqInt) b3dRasterizerVersion(void) {
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(1);
}


/*	Primitive. Shade all the vertices in the vertex buffer using the given array of primitive light sources. Return true on success. */

EXPORT(sqInt) b3dShadeVertexBuffer(void) {
    sqInt i;
    sqInt j;
    sqInt lightArray;
    sqInt lightCount;
    float *vtxArray;
    sqInt vtxCount;
    sqInt lightOop;
    sqInt rgba;
    sqInt a;
    sqInt b;
    sqInt g;
    sqInt r;

	vbFlags = interpreterProxy->stackIntegerValue(0);
	primMaterial = stackMaterialValue(1);
	lightArray = stackLightArrayValue(2);
	vtxCount = interpreterProxy->stackIntegerValue(3);
	vtxArray = stackPrimitiveVertexArrayofSize(4, vtxCount);
	if ((vtxArray == null) || ((primMaterial == null) || (interpreterProxy->failed()))) {
		return interpreterProxy->primitiveFail();
	}
	litVertex = vtxArray;

	/* Go over all vertices */

	lightCount = interpreterProxy->slotSizeOf(lightArray);
	for (i = 1; i <= vtxCount; i += 1) {

		/* Load the primitive vertex */

		/* begin loadPrimitiveVertex */
		rgba = (((int*) litVertex))[PrimVtxColor32];
		vtxInColor[2] = ((rgba & 255) * (1.0 / 255.0));
		rgba = ((usqInt) rgba) >> 8;
		vtxInColor[1] = ((rgba & 255) * (1.0 / 255.0));
		rgba = ((usqInt) rgba) >> 8;
		vtxInColor[0] = ((rgba & 255) * (1.0 / 255.0));
		rgba = ((usqInt) rgba) >> 8;
		vtxInColor[3] = ((rgba & 255) * (1.0 / 255.0));
		if (vbFlags & VBTrackEmission) {

			/* Load color from vertex */

			vtxOutColor[0] = ((vtxInColor[0]) + (primMaterial[EmissionRed]));
			vtxOutColor[1] = ((vtxInColor[1]) + (primMaterial[EmissionGreen]));
			vtxOutColor[2] = ((vtxInColor[2]) + (primMaterial[EmissionBlue]));
			vtxOutColor[3] = ((vtxInColor[3]) + (primMaterial[EmissionAlpha]));
		} else {
			vtxOutColor[0] = (primMaterial[EmissionRed]);
			vtxOutColor[1] = (primMaterial[EmissionGreen]);
			vtxOutColor[2] = (primMaterial[EmissionBlue]);
			vtxOutColor[3] = (primMaterial[EmissionAlpha]);
		}
		for (j = 0; j <= (lightCount - 1); j += 1) {

			/* Fetch the light source */

			/* begin fetchLightSource:ofObject: */
			lightOop = interpreterProxy->fetchPointerofObject(j, lightArray);
			primLight = interpreterProxy->firstIndexableField(lightOop);
			/* begin loadPrimitiveLightSource */
			lightFlags = (((int*) primLight))[PrimLightFlags];
			shadeVertex();
		}
		/* begin storePrimitiveVertex */
		r = ((sqInt)((vtxOutColor[0]) * 255));
		r = (((((r < 255) ? r : 255)) < 0) ? 0 : (((r < 255) ? r : 255)));
		g = ((sqInt)((vtxOutColor[1]) * 255));
		g = (((((g < 255) ? g : 255)) < 0) ? 0 : (((g < 255) ? g : 255)));
		b = ((sqInt)((vtxOutColor[2]) * 255));
		b = (((((b < 255) ? b : 255)) < 0) ? 0 : (((b < 255) ? b : 255)));
		a = ((sqInt)((vtxOutColor[3]) * 255));
		a = (((((a < 255) ? a : 255)) < 0) ? 0 : (((a < 255) ? a : 255)));
		(((int*) litVertex))[PrimVtxColor32] = (b + ((g + ((r + (a << 8)) << 8)) << 8));
		litVertex += PrimVertexSize;
	}
	interpreterProxy->pop(6);
	interpreterProxy->pushBool(1);
}


/*	Return the current shader version. */

EXPORT(sqInt) b3dShaderVersion(void) {
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(1);
}


/*	Primitive. Start the rasterizer. */

EXPORT(sqInt) b3dStartRasterizer(void) {
    sqInt errCode;

	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}
	if (!(loadRasterizerState(2))) {
		return interpreterProxy->primitiveFail();
	}
	loadTexturesFrom(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	loadObjectsFrom(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	errCode = b3dMainLoop(&state, B3D_NO_ERROR);
	storeObjectsInto(1);
	interpreterProxy->pop(4);
	interpreterProxy->pushInteger(errCode);
}

EXPORT(sqInt) b3dTransformDirection(void) {
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

EXPORT(sqInt) b3dTransformMatrixWithInto(void) {
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

EXPORT(sqInt) b3dTransformPoint(void) {
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


/*	Transform the normal of the given primitive vertex using the argument matrix and rescale the normal if necessary. */

EXPORT(sqInt) b3dTransformPrimitiveNormal(void) {
    float *matrix;
    float *pVertex;
    sqInt rescale;

	rescale = interpreterProxy->stackValue(0);
	if (!(rescale == (interpreterProxy->nilObject()))) {
		rescale = interpreterProxy->booleanValueOf(rescale);
	}
	matrix = stackMatrix(1);
	pVertex = stackPrimitiveVertex(2);
	if ((matrix == null) || (pVertex == null)) {
		return interpreterProxy->primitiveFail();
	}
	if ((rescale != 1) && (rescale != 0)) {
		rescale = analyzeMatrix3x3Length(matrix);
	}
	transformPrimitiveNormalbyrescale(pVertex, matrix, rescale);
	interpreterProxy->pop(3);
}


/*	Transform the position of the given primitive vertex the given matrix
	and store the result back inplace. */

EXPORT(sqInt) b3dTransformPrimitivePosition(void) {
    float *matrix;
    float *pVertex;

	matrix = stackMatrix(0);
	pVertex = stackPrimitiveVertex(1);
	if ((matrix == null) || (pVertex == null)) {
		return interpreterProxy->primitiveFail();
	}
	transformPrimitivePositionby(pVertex, matrix);
	interpreterProxy->pop(2);
}


/*	Transform the position of the given primitive vertex the given matrix
	and store the result in homogenous coordinates at rasterPos. */

EXPORT(sqInt) b3dTransformPrimitiveRasterPosition(void) {
    float *matrix;
    float *pVertex;

	matrix = stackMatrix(0);
	pVertex = stackPrimitiveVertex(1);
	if ((matrix == null) || (pVertex == null)) {
		return interpreterProxy->primitiveFail();
	}
	transformPrimitiveRasterPositionby(pVertex, matrix);
	interpreterProxy->pop(2);
}


/*	Transform an entire vertex buffer using the supplied modelview and projection matrix. */

EXPORT(sqInt) b3dTransformVertexBuffer(void) {
    sqInt flags;
    float *modelViewMatrix;
    float *projectionMatrix;
    float *vtxArray;
    sqInt vtxCount;

	flags = interpreterProxy->stackIntegerValue(0);
	projectionMatrix = stackMatrix(1);
	modelViewMatrix = stackMatrix(2);
	vtxCount = interpreterProxy->stackIntegerValue(3);
	vtxArray = stackPrimitiveVertexArrayofSize(4, vtxCount);
	if (((projectionMatrix == null) || (modelViewMatrix == null)) || (vtxArray == null)) {
		return interpreterProxy->primitiveFail();
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	transformVBcountbyandflags(vtxArray, vtxCount, modelViewMatrix, projectionMatrix, flags);
	interpreterProxy->pop(5);
}


/*	Return the current version of the transformer */

EXPORT(sqInt) b3dTransformerVersion(void) {
	interpreterProxy->pop(1);
	interpreterProxy->pushInteger(1);
}

EXPORT(sqInt) b3dTransposeMatrix(void) {
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

static sqInt clipPolygoncountwithmask(int *vtxArray, sqInt vtxCount, int *tempVtxArray, sqInt outMask) {
    sqInt count;

	if (outMask == OutLeftBit) {
		return clipPolygonLeftFromtocount(tempVtxArray, vtxArray, vtxCount);
	}
	if (outMask == OutRightBit) {
		return clipPolygonRightFromtocount(tempVtxArray, vtxArray, vtxCount);
	}
	if (outMask == OutTopBit) {
		return clipPolygonTopFromtocount(tempVtxArray, vtxArray, vtxCount);
	}
	if (outMask == OutBottomBit) {
		return clipPolygonBottomFromtocount(tempVtxArray, vtxArray, vtxCount);
	}
	if (outMask == OutFrontBit) {
		return clipPolygonFrontFromtocount(tempVtxArray, vtxArray, vtxCount);
	}
	if (outMask == OutBackBit) {
		return clipPolygonBackFromtocount(tempVtxArray, vtxArray, vtxCount);
	}
	count = vtxCount;
	count = clipPolygonLeftFromtocount(vtxArray, tempVtxArray, count);
	if (count == 0) {
		return 0;
	}
	count = clipPolygonRightFromtocount(tempVtxArray, vtxArray, count);
	if (count == 0) {
		return 0;
	}
	count = clipPolygonTopFromtocount(vtxArray, tempVtxArray, count);
	if (count == 0) {
		return 0;
	}
	count = clipPolygonBottomFromtocount(tempVtxArray, vtxArray, count);
	if (count == 0) {
		return 0;
	}
	count = clipPolygonFrontFromtocount(vtxArray, tempVtxArray, count);
	if (count == 0) {
		return 0;
	}
	count = clipPolygonBackFromtocount(tempVtxArray, vtxArray, count);
	return count;
}

static sqInt clipPolygonBackFromtocount(int *buf1, int *buf2, sqInt n) {
    sqInt i;
    sqInt inLast;
    sqInt inNext;
    sqInt j;
    int *last;
    int *next;
    sqInt outIndex;
    double t;

	outIndex = 0;
	last = buf1 + (n * PrimVertexSize);
	next = buf1 + PrimVertexSize;
	inLast = (last[PrimVtxClipFlags]) & InBackBit;
	for (i = 1; i <= n; i += 1) {
		inNext = (next[PrimVtxClipFlags]) & InBackBit;
		if (!(inLast == inNext)) {

			/* Passes clip boundary */

			t = (((((float *) last))[PrimVtxRasterPosZ]) - ((((float *) last))[PrimVtxRasterPosW])) / ((((((float *) next))[PrimVtxRasterPosW]) - ((((float *) last))[PrimVtxRasterPosW])) - (((((float *) next))[PrimVtxRasterPosZ]) - ((((float *) last))[PrimVtxRasterPosZ])));
			outIndex += 1;
			interpolateFromtoatinto(((float *) last), ((float *) next), t, ((float*) (buf2 + (outIndex * PrimVertexSize))));
		}
		if (inNext) {
			outIndex += 1;
			for (j = 0; j <= (PrimVertexSize - 1); j += 1) {
				buf2[(outIndex * PrimVertexSize) + j] = (next[j]);
			}
		}
		last = next;
		inLast = inNext;
		next += PrimVertexSize;
	}
	return outIndex;
}

static sqInt clipPolygonBottomFromtocount(int *buf1, int *buf2, sqInt n) {
    sqInt i;
    sqInt inLast;
    sqInt inNext;
    sqInt j;
    int *last;
    int *next;
    sqInt outIndex;
    double t;

	outIndex = 0;
	last = buf1 + (n * PrimVertexSize);
	next = buf1 + PrimVertexSize;
	inLast = (last[PrimVtxClipFlags]) & InBottomBit;
	for (i = 1; i <= n; i += 1) {
		inNext = (next[PrimVtxClipFlags]) & InBottomBit;
		if (!(inLast == inNext)) {

			/* Passes clip boundary */

			t = (0.0 - (((((float *) last))[PrimVtxRasterPosY]) + ((((float *) last))[PrimVtxRasterPosW]))) / ((((((float *) next))[PrimVtxRasterPosW]) - ((((float *) last))[PrimVtxRasterPosW])) + (((((float *) next))[PrimVtxRasterPosY]) - ((((float *) last))[PrimVtxRasterPosY])));
			outIndex += 1;
			interpolateFromtoatinto(((float *) last), ((float *) next), t, ((float*) (buf2 + (outIndex * PrimVertexSize))));
		}
		if (inNext) {
			outIndex += 1;
			for (j = 0; j <= (PrimVertexSize - 1); j += 1) {
				buf2[(outIndex * PrimVertexSize) + j] = (next[j]);
			}
		}
		last = next;
		inLast = inNext;
		next += PrimVertexSize;
	}
	return outIndex;
}

static sqInt clipPolygonFrontFromtocount(int *buf1, int *buf2, sqInt n) {
    sqInt i;
    sqInt inLast;
    sqInt inNext;
    sqInt j;
    int *last;
    int *next;
    sqInt outIndex;
    double t;

	outIndex = 0;
	last = buf1 + (n * PrimVertexSize);
	next = buf1 + PrimVertexSize;
	inLast = (last[PrimVtxClipFlags]) & InFrontBit;
	for (i = 1; i <= n; i += 1) {
		inNext = (next[PrimVtxClipFlags]) & InFrontBit;
		if (!(inLast == inNext)) {

			/* Passes clip boundary */

			t = (0.0 - (((((float *) last))[PrimVtxRasterPosZ]) + ((((float *) last))[PrimVtxRasterPosW]))) / ((((((float *) next))[PrimVtxRasterPosW]) - ((((float *) last))[PrimVtxRasterPosW])) + (((((float *) next))[PrimVtxRasterPosZ]) - ((((float *) last))[PrimVtxRasterPosZ])));
			outIndex += 1;
			interpolateFromtoatinto(((float *) last), ((float *) next), t, ((float*) (buf2 + (outIndex * PrimVertexSize))));
		}
		if (inNext) {
			outIndex += 1;
			for (j = 0; j <= (PrimVertexSize - 1); j += 1) {
				buf2[(outIndex * PrimVertexSize) + j] = (next[j]);
			}
		}
		last = next;
		inLast = inNext;
		next += PrimVertexSize;
	}
	return outIndex;
}

static sqInt clipPolygonLeftFromtocount(int *buf1, int *buf2, sqInt n) {
    sqInt i;
    sqInt inLast;
    sqInt inNext;
    sqInt j;
    int *last;
    int *next;
    sqInt outIndex;
    double t;

	outIndex = 0;
	last = buf1 + (n * PrimVertexSize);
	next = buf1 + PrimVertexSize;
	inLast = (last[PrimVtxClipFlags]) & InLeftBit;
	for (i = 1; i <= n; i += 1) {
		inNext = (next[PrimVtxClipFlags]) & InLeftBit;
		if (!(inLast == inNext)) {

			/* Passes clip boundary */

			t = (0.0 - (((((float *) last))[PrimVtxRasterPosX]) + ((((float *) last))[PrimVtxRasterPosW]))) / ((((((float *) next))[PrimVtxRasterPosW]) - ((((float *) last))[PrimVtxRasterPosW])) + (((((float *) next))[PrimVtxRasterPosX]) - ((((float *) last))[PrimVtxRasterPosX])));
			outIndex += 1;
			interpolateFromtoatinto(((float *) last), ((float *) next), t, ((float*) (buf2 + (outIndex * PrimVertexSize))));
		}
		if (inNext) {
			outIndex += 1;
			for (j = 0; j <= (PrimVertexSize - 1); j += 1) {
				buf2[(outIndex * PrimVertexSize) + j] = (next[j]);
			}
		}
		last = next;
		inLast = inNext;
		next += PrimVertexSize;
	}
	return outIndex;
}

static sqInt clipPolygonRightFromtocount(int *buf1, int *buf2, sqInt n) {
    sqInt i;
    sqInt inLast;
    sqInt inNext;
    sqInt j;
    int *last;
    int *next;
    sqInt outIndex;
    double t;

	outIndex = 0;
	last = buf1 + (n * PrimVertexSize);
	next = buf1 + PrimVertexSize;
	inLast = (last[PrimVtxClipFlags]) & InRightBit;
	for (i = 1; i <= n; i += 1) {
		inNext = (next[PrimVtxClipFlags]) & InRightBit;
		if (!(inLast == inNext)) {

			/* Passes clip boundary */

			t = (((((float *) last))[PrimVtxRasterPosX]) - ((((float *) last))[PrimVtxRasterPosW])) / ((((((float *) next))[PrimVtxRasterPosW]) - ((((float *) last))[PrimVtxRasterPosW])) - (((((float *) next))[PrimVtxRasterPosX]) - ((((float *) last))[PrimVtxRasterPosX])));
			outIndex += 1;
			interpolateFromtoatinto(((float *) last), ((float *) next), t, ((float*) (buf2 + (outIndex * PrimVertexSize))));
		}
		if (inNext) {
			outIndex += 1;
			for (j = 0; j <= (PrimVertexSize - 1); j += 1) {
				buf2[(outIndex * PrimVertexSize) + j] = (next[j]);
			}
		}
		last = next;
		inLast = inNext;
		next += PrimVertexSize;
	}
	return outIndex;
}

static sqInt clipPolygonTopFromtocount(int *buf1, int *buf2, sqInt n) {
    sqInt i;
    sqInt inLast;
    sqInt inNext;
    sqInt j;
    int *last;
    int *next;
    sqInt outIndex;
    double t;

	outIndex = 0;
	last = buf1 + (n * PrimVertexSize);
	next = buf1 + PrimVertexSize;
	inLast = (last[PrimVtxClipFlags]) & InTopBit;
	for (i = 1; i <= n; i += 1) {
		inNext = (next[PrimVtxClipFlags]) & InTopBit;
		if (!(inLast == inNext)) {

			/* Passes clip boundary */

			t = (((((float *) last))[PrimVtxRasterPosY]) - ((((float *) last))[PrimVtxRasterPosW])) / ((((((float *) next))[PrimVtxRasterPosW]) - ((((float *) last))[PrimVtxRasterPosW])) - (((((float *) next))[PrimVtxRasterPosY]) - ((((float *) last))[PrimVtxRasterPosY])));
			outIndex += 1;
			interpolateFromtoatinto(((float *) last), ((float *) next), t, ((float*) (buf2 + (outIndex * PrimVertexSize))));
		}
		if (inNext) {
			outIndex += 1;
			for (j = 0; j <= (PrimVertexSize - 1); j += 1) {
				buf2[(outIndex * PrimVertexSize) + j] = (next[j]);
			}
		}
		last = next;
		inLast = inNext;
		next += PrimVertexSize;
	}
	return outIndex;
}


/*	Computes
		l2vSpecDir := l2vSpecDir - vtx position safelyNormalized.
	 */

static sqInt computeSpecularDirection(void) {
    double scale;

	scale = inverseLengthOfFloat(litVertex + PrimVtxPosition);
	l2vSpecDir[0] = ((l2vSpecDir[0]) - ((litVertex[PrimVtxPositionX]) * scale));
	l2vSpecDir[1] = ((l2vSpecDir[1]) - ((litVertex[PrimVtxPositionY]) * scale));
	l2vSpecDir[2] = ((l2vSpecDir[2]) - ((litVertex[PrimVtxPositionZ]) * scale));
}


/*	Compute the spot factor for a spot light */

static double computeSpotFactor(void) {
    double cosAngle;
    double deltaCos;
    double minCos;

	cosAngle = dotProductOfFloatwithDouble(primLight + PrimLightDirection, l2vDirection);
	cosAngle = 0.0 - cosAngle;
	minCos = primLight[SpotLightMinCos];
	if (cosAngle < minCos) {
		return 0.0;
	}
	deltaCos = primLight[SpotLightDeltaCos];
	if (deltaCos <= 1.0e-5) {

		/* No delta -- a sharp boundary between on and off.
		Since off has already been determined above, we are on */

		return 1.0;
	}
	cosAngle = (cosAngle - minCos) / deltaCos;
	return pow(cosAngle,(primLight[SpotLightExponent]));
}

static sqInt determineClipFlagscount(void *vtxArray, sqInt count) {
    sqInt flags;
    sqInt fullMask;
    sqInt i;
    float *vtxPtr;
    double w;
    double w2;
    double x;
    double y;
    double z;

	vtxPtr = ((float *) vtxArray);
	fullMask = InAllMask + OutAllMask;
	for (i = 1; i <= count; i += 1) {
		w = vtxPtr[PrimVtxRasterPosW];
		w2 = 0.0 - w;
		flags = 0;
		x = vtxPtr[PrimVtxRasterPosX];
		if (x >= w2) {
			flags = flags | InLeftBit;
		} else {
			flags = flags | OutLeftBit;
		}
		if (x <= w) {
			flags = flags | InRightBit;
		} else {
			flags = flags | OutRightBit;
		}
		y = vtxPtr[PrimVtxRasterPosY];
		if (y >= w2) {
			flags = flags | InBottomBit;
		} else {
			flags = flags | OutBottomBit;
		}
		if (y <= w) {
			flags = flags | InTopBit;
		} else {
			flags = flags | OutTopBit;
		}
		z = vtxPtr[PrimVtxRasterPosZ];
		if (z >= w2) {
			flags = flags | InFrontBit;
		} else {
			flags = flags | OutFrontBit;
		}
		if (z <= w) {
			flags = flags | InBackBit;
		} else {
			flags = flags | OutBackBit;
		}
		fullMask = fullMask & flags;
		(((int *) vtxPtr))[PrimVtxClipFlags] = flags;
		vtxPtr += PrimVertexSize;
	}
	return fullMask;
}

static double dotProductOfFloatwithDouble(float * v1, double *v2) {
	return (((v1[0]) * (v2[0])) + ((v1[1]) * (v2[1]))) + ((v1[2]) * (v2[2]));
}


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

EXPORT(sqInt) initialiseModule(void) {
	loadBBFn = interpreterProxy->ioLoadFunctionFrom("loadBitBltFrom", bbPluginName);
	copyBitsFn = interpreterProxy->ioLoadFunctionFrom("copyBitsFromtoat", bbPluginName);
	return (loadBBFn != 0) && (copyBitsFn != 0);
}


/*	Interpolate the primitive vertices last/next at the parameter t */

static sqInt interpolateFromtoatinto(float *last, float *next, double t, float *out) {
    double delta;
    sqInt flags;
    unsigned int lastValue;
    unsigned int newValue;
    unsigned int nextValue;
    unsigned int rgbaLast;
    unsigned int rgbaNext;
    double w;
    double w2;
    double x;
    double y;
    double z;

	delta = (next[PrimVtxRasterPosX]) - (last[PrimVtxRasterPosX]);
	x = (last[PrimVtxRasterPosX]) + (delta * t);
	out[PrimVtxRasterPosX] = (((float) x));
	delta = (next[PrimVtxRasterPosY]) - (last[PrimVtxRasterPosY]);
	y = (last[PrimVtxRasterPosY]) + (delta * t);
	out[PrimVtxRasterPosY] = (((float) y));
	delta = (next[PrimVtxRasterPosZ]) - (last[PrimVtxRasterPosZ]);
	z = (last[PrimVtxRasterPosZ]) + (delta * t);
	out[PrimVtxRasterPosZ] = (((float) z));
	delta = (next[PrimVtxRasterPosW]) - (last[PrimVtxRasterPosW]);
	w = (last[PrimVtxRasterPosW]) + (delta * t);
	out[PrimVtxRasterPosW] = (((float) w));
	w2 = 0.0 - w;
	flags = 0;
	if (x >= w2) {
		flags = flags | InLeftBit;
	} else {
		flags = flags | OutLeftBit;
	}
	if (x <= w) {
		flags = flags | InRightBit;
	} else {
		flags = flags | OutRightBit;
	}
	if (y >= w2) {
		flags = flags | InBottomBit;
	} else {
		flags = flags | OutBottomBit;
	}
	if (y <= w) {
		flags = flags | InTopBit;
	} else {
		flags = flags | OutTopBit;
	}
	if (z >= w2) {
		flags = flags | InFrontBit;
	} else {
		flags = flags | OutFrontBit;
	}
	if (z <= w) {
		flags = flags | InBackBit;
	} else {
		flags = flags | OutBackBit;
	}
	(((int *) out))[PrimVtxClipFlags] = flags;
	rgbaLast = (((unsigned int *) last))[PrimVtxColor32];
	lastValue = rgbaLast & 255;
	rgbaLast = ((usqInt) rgbaLast) >> 8;
	rgbaNext = (((unsigned int *) next))[PrimVtxColor32];
	nextValue = rgbaNext & 255;
	rgbaNext = ((usqInt) rgbaNext) >> 8;
	delta = (((int) (nextValue - lastValue))) * t;
	newValue = ((sqInt)(lastValue + delta));
	lastValue = rgbaLast & 255;
	rgbaLast = ((usqInt) rgbaLast) >> 8;
	nextValue = rgbaNext & 255;
	rgbaNext = ((usqInt) rgbaNext) >> 8;
	delta = (((int) (nextValue - lastValue))) * t;
	newValue += (((sqInt)(lastValue + delta))) << 8;
	lastValue = rgbaLast & 255;
	rgbaLast = ((usqInt) rgbaLast) >> 8;
	nextValue = rgbaNext & 255;
	rgbaNext = ((usqInt) rgbaNext) >> 8;
	delta = (((int) (nextValue - lastValue))) * t;
	newValue += (((sqInt)(lastValue + delta))) << 16;
	lastValue = rgbaLast & 255;
	nextValue = rgbaNext & 255;
	delta = (((int) (nextValue - lastValue))) * t;
	newValue += (((sqInt)(lastValue + delta))) << 24;
	(((unsigned int*) out))[PrimVtxColor32] = newValue;
	delta = (next[PrimVtxTexCoordU]) - (last[PrimVtxTexCoordU]);
	out[PrimVtxTexCoordU] = (((float) ((last[PrimVtxTexCoordU]) + (delta * t))));
	delta = (next[PrimVtxTexCoordV]) - (last[PrimVtxTexCoordV]);
	out[PrimVtxTexCoordV] = (((float) ((last[PrimVtxTexCoordV]) + (delta * t))));
}

static double inverseLengthOfDouble(double * aVector) {
    double scale;

	scale = (((aVector[0]) * (aVector[0])) + ((aVector[1]) * (aVector[1]))) + ((aVector[2]) * (aVector[2]));
	if ((scale == 0.0) || (scale == 1.0)) {
		return scale;
	}
	return 1.0 / (sqrt(scale));
}

static double inverseLengthOfFloat(float * aVector) {
    double scale;

	scale = (((aVector[0]) * (aVector[0])) + ((aVector[1]) * (aVector[1]))) + ((aVector[2]) * (aVector[2]));
	if ((scale == 0.0) || (scale == 1.0)) {
		return scale;
	}
	return 1.0 / (sqrt(scale));
}

static sqInt loadObjectsFrom(sqInt stackIndex) {
    sqInt arrayOop;
    sqInt arraySize;
    sqInt i;
    B3DPrimitiveObject **objArray;
    sqInt objOop;
    B3DPrimitiveObject *objPtr;

	arrayOop = interpreterProxy->stackObjectValue(stackIndex);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!((interpreterProxy->fetchClassOf(arrayOop)) == (interpreterProxy->classArray()))) {
		return interpreterProxy->primitiveFail();
	}
	arraySize = interpreterProxy->slotSizeOf(arrayOop);
	if (arraySize > (state.nObjects)) {
		return interpreterProxy->primitiveFail();
	}
	objArray = state.objects;
	for (i = 0; i <= (arraySize - 1); i += 1) {
		objOop = interpreterProxy->fetchPointerofObject(i, arrayOop);
		if (((objOop & 1)) || (!(interpreterProxy->isWords(objOop)))) {
			return interpreterProxy->primitiveFail();
		}
		objPtr = ((B3DPrimitiveObject*) (interpreterProxy->firstIndexableField(objOop)));
		if (objPtr->magic != B3D_PRIMITIVE_OBJECT_MAGIC) {
			return interpreterProxy->primitiveFail();
		}
		objPtr->__oop__ = objOop;
		objArray[i] = objPtr;
	}
}


/*	Load the rasterizer state from the given stack index. */

static sqInt loadRasterizerState(sqInt stackIndex) {
    sqInt obj;
    sqInt objLen;
    void *objPtr;
    sqInt stateOop;

	if ((copyBitsFn == 0) || (loadBBFn == 0)) {

		/* We need loadBitBltFrom/copyBits here so try to load it implicitly */

		if (!(initialiseModule())) {
			return 0;
		}
	}
	stateOop = interpreterProxy->stackObjectValue(stackIndex);
	if (interpreterProxy->failed()) {
		return 0;
	}
	if (!((interpreterProxy->isPointers(stateOop)) && ((interpreterProxy->slotSizeOf(stateOop)) >= 10))) {
		return 0;
	}
	obj = interpreterProxy->fetchPointerofObject(0, stateOop);
	if (((obj & 1)) || (!(interpreterProxy->isWords(obj)))) {
		return 0;
	}
	objPtr = interpreterProxy->firstIndexableField(obj);
	state.faceAlloc = objPtr;
	obj = interpreterProxy->fetchPointerofObject(1, stateOop);
	if (((obj & 1)) || (!(interpreterProxy->isWords(obj)))) {
		return 0;
	}
	objPtr = interpreterProxy->firstIndexableField(obj);
	state.edgeAlloc = objPtr;
	obj = interpreterProxy->fetchPointerofObject(2, stateOop);
	if (((obj & 1)) || (!(interpreterProxy->isWords(obj)))) {
		return 0;
	}
	objPtr = interpreterProxy->firstIndexableField(obj);
	state.attrAlloc = objPtr;
	obj = interpreterProxy->fetchPointerofObject(3, stateOop);
	if (((obj & 1)) || (!(interpreterProxy->isWords(obj)))) {
		return 0;
	}
	objPtr = interpreterProxy->firstIndexableField(obj);
	state.aet = objPtr;
	obj = interpreterProxy->fetchPointerofObject(4, stateOop);
	if (((obj & 1)) || (!(interpreterProxy->isWords(obj)))) {
		return 0;
	}
	objPtr = interpreterProxy->firstIndexableField(obj);
	state.addedEdges = objPtr;
	obj = interpreterProxy->fetchPointerofObject(5, stateOop);
	if (((obj & 1)) || (!(interpreterProxy->isWords(obj)))) {
		return 0;
	}
	objPtr = interpreterProxy->firstIndexableField(obj);
	state.fillList = objPtr;
	obj = interpreterProxy->fetchPointerofObject(6, stateOop);
	if (obj == (interpreterProxy->nilObject())) {
		state.nObjects = 0;
		state.objects = NULL;
	} else {
		if (((obj & 1)) || (!(interpreterProxy->isWords(obj)))) {
			return 0;
		}
		objLen = interpreterProxy->slotSizeOf(obj);
		objPtr = interpreterProxy->firstIndexableField(obj);
		state.objects = (B3DPrimitiveObject **)objPtr;
		state.nObjects = objLen;
	}
	obj = interpreterProxy->fetchPointerofObject(7, stateOop);
	if (obj == (interpreterProxy->nilObject())) {
		state.nTextures = 0;
		state.textures = NULL;
	} else {
		if (((obj & 1)) || (!(interpreterProxy->isWords(obj)))) {
			return 0;
		}
		objLen = interpreterProxy->byteSizeOf(obj);
		objPtr = interpreterProxy->firstIndexableField(obj);
		state.textures = (B3DTexture *)objPtr;
		state.nTextures = objLen / sizeof(B3DTexture);
	}
	obj = interpreterProxy->fetchPointerofObject(8, stateOop);
	if (obj == (interpreterProxy->nilObject())) {
		state.spanSize = 0;
		state.spanBuffer = NULL;
	} else {
		if (!((interpreterProxy->fetchClassOf(obj)) == (interpreterProxy->classBitmap()))) {
			return 0;
		}
		objLen = interpreterProxy->slotSizeOf(obj);
		objPtr = interpreterProxy->firstIndexableField(obj);
		state.spanBuffer = (unsigned int *)objPtr;
		state.spanSize = objLen;
	}
	obj = interpreterProxy->fetchPointerofObject(9, stateOop);
	if (obj == (interpreterProxy->nilObject())) {
		state.spanDrawer = NULL;
	} else {
		if (!(((int (*) (int))loadBBFn)(obj))) {
			return 0;
		}
		state.spanDrawer = (b3dDrawBufferFunction) copyBitsFn;
	}
	return !(interpreterProxy->failed());
}


/*	Note: This still uses the old-style textures */

static sqInt loadTextureinto(sqInt textureOop, B3DTexture *destPtr) {
    void *bitsPtr;
    sqInt form;
    sqInt formBits;
    sqInt formDepth;
    sqInt formHeight;
    sqInt formWidth;
    sqInt texEnvMode;
    sqInt texInterpolate;
    sqInt texWrap;

	form = textureOop;
	if (!(interpreterProxy->isPointers(form))) {
		return 0;
	}
	if ((interpreterProxy->slotSizeOf(form)) < 8) {
		return 0;
	}
	formBits = interpreterProxy->fetchPointerofObject(0, form);
	formWidth = interpreterProxy->fetchIntegerofObject(1, form);
	formHeight = interpreterProxy->fetchIntegerofObject(2, form);
	formDepth = interpreterProxy->fetchIntegerofObject(3, form);
	texWrap = interpreterProxy->booleanValueOf(interpreterProxy->fetchPointerofObject(5, form));
	texInterpolate = interpreterProxy->booleanValueOf(interpreterProxy->fetchPointerofObject(6, form));
	texEnvMode = interpreterProxy->fetchIntegerofObject(7, form);
	if (interpreterProxy->failed()) {
		return 0;
	}
	if ((formWidth < 1) || ((formHeight < 1) || (formDepth != 32))) {
		return 0;
	}
	if (!((interpreterProxy->fetchClassOf(formBits)) == (interpreterProxy->classBitmap()))) {
		return 0;
	}
	if (!((interpreterProxy->byteSizeOf(formBits)) == ((formWidth * formHeight) * 4))) {
		return 0;
	}
	if ((texEnvMode < 0) || (texEnvMode > 1)) {
		return 0;
	}

	/* Set the texture parameters */

	bitsPtr = interpreterProxy->firstIndexableField(formBits);
	return b3dLoadTexture(destPtr, formWidth, formHeight, formDepth, (unsigned int*) bitsPtr, 0, NULL) == B3D_NO_ERROR;
}

static sqInt loadTexturesFrom(sqInt stackIndex) {
    sqInt arrayOop;
    B3DTexture *destPtr;
    sqInt i;
    sqInt n;
    sqInt textureOop;

	arrayOop = interpreterProxy->stackObjectValue(stackIndex);
	if (!((interpreterProxy->fetchClassOf(arrayOop)) == (interpreterProxy->classArray()))) {
		return interpreterProxy->primitiveFail();
	}
	n = interpreterProxy->slotSizeOf(arrayOop);
	n = ((n < (state.nTextures)) ? n : (state.nTextures));
	for (i = 0; i <= (n - 1); i += 1) {
		destPtr = state.textures + i;
		textureOop = interpreterProxy->fetchPointerofObject(i, arrayOop);
		if (!(loadTextureinto(textureOop, destPtr))) {
			return interpreterProxy->primitiveFail();
		}
	}
	return 0;
}


/*	Load the viewport from the given stack index */

static sqInt loadViewportFrom(sqInt stackIndex) {
    sqInt oop;
    sqInt p1;
    sqInt p2;
    sqInt x0;
    sqInt x1;
    sqInt y0;
    sqInt y1;

	oop = interpreterProxy->stackObjectValue(stackIndex);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->isPointers(oop))) {
		return interpreterProxy->primitiveFail();
	}
	if ((interpreterProxy->slotSizeOf(oop)) < 2) {
		return interpreterProxy->primitiveFail();
	}
	p1 = interpreterProxy->fetchPointerofObject(0, oop);
	p2 = interpreterProxy->fetchPointerofObject(1, oop);
	if (!((interpreterProxy->fetchClassOf(p1)) == (interpreterProxy->classPoint()))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->fetchClassOf(p2)) == (interpreterProxy->classPoint()))) {
		return interpreterProxy->primitiveFail();
	}
	x0 = interpreterProxy->fetchIntegerofObject(0, p1);
	y0 = interpreterProxy->fetchIntegerofObject(1, p1);
	x1 = interpreterProxy->fetchIntegerofObject(0, p2);
	y1 = interpreterProxy->fetchIntegerofObject(1, p2);
	if (interpreterProxy->failed()) {
		return null;
	}
	viewport.x0 = x0;
	viewport.y0 = y0;
	viewport.x1 = x1;
	viewport.y1 = y1;
	return 0;
}

static sqInt mapVBofSizeinto(void *vtxArray, sqInt vtxCount, sqInt boxArray) {
    double bottom;
    sqInt flags;
    sqInt floatOop;
    sqInt i;
    double left;
    sqInt oop;
    double right;
    double top;
    float *vtxPtr;
    double w;
    double x;
    double y;

	vtxPtr = ((float *) vtxArray);
	for (i = 1; i <= vtxCount; i += 1) {
		flags = (((int *) vtxPtr))[PrimVtxClipFlags];
		w = vtxPtr[PrimVtxRasterPosW];
		if (!(w == 0.0)) {
			w = 1.0 / w;
		}
		if ((flags & OutLeftBit) != 0) {
			x = -1.0;
		} else {
			if ((flags & OutRightBit) != 0) {
				x = 1.0;
			} else {
				x = (vtxPtr[PrimVtxRasterPosX]) * w;
			}
		}
		if ((flags & OutTopBit) != 0) {
			y = -1.0;
		} else {
			if ((flags & OutBottomBit) != 0) {
				y = 1.0;
			} else {
				y = (vtxPtr[PrimVtxRasterPosY]) * w;
			}
		}
		if (i == 1) {
			left = (right = x);
			top = (bottom = y);
		}
		if (x < left) {
			left = x;
		}
		if (x > right) {
			right = x;
		}
		if (y < top) {
			top = y;
		}
		if (y > bottom) {
			bottom = y;
		}
		vtxPtr += PrimVertexSize;
	}
	oop = boxArray;
	interpreterProxy->pushRemappableOop(oop);
	floatOop = interpreterProxy->floatObjectOf(left);
	oop = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(0, oop, floatOop);
	interpreterProxy->pushRemappableOop(oop);
	floatOop = interpreterProxy->floatObjectOf(top);
	oop = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(1, oop, floatOop);
	interpreterProxy->pushRemappableOop(oop);
	floatOop = interpreterProxy->floatObjectOf(right);
	oop = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(2, oop, floatOop);
	interpreterProxy->pushRemappableOop(oop);
	floatOop = interpreterProxy->floatObjectOf(bottom);
	oop = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(3, oop, floatOop);
}


/*	The module with the given name was just unloaded.
	Make sure we have no dangling references. */

EXPORT(sqInt) moduleUnloaded(char *aModuleName) {
	if ((strcmp(aModuleName, bbPluginName)) == 0) {

		/* BitBlt just shut down. How nasty. */

		loadBBFn = 0;
		copyBitsFn = 0;
	}
}


/*	Primitive. Set the BitBlt plugin to use. */

EXPORT(sqInt) primitiveSetBitBltPlugin(void) {
    sqInt i;
    sqInt length;
    sqInt needReload;
    sqInt pluginName;
    char *ptr;


	/* Must be string to work */

	pluginName = interpreterProxy->stackValue(0);
	if (!(interpreterProxy->isBytes(pluginName))) {
		return interpreterProxy->primitiveFail();
	}
	length = interpreterProxy->byteSizeOf(pluginName);
	if (length >= 256) {
		return interpreterProxy->primitiveFail();
	}
	ptr = interpreterProxy->firstIndexableField(pluginName);
	needReload = 0;
	for (i = 0; i <= (length - 1); i += 1) {

		/* Compare and store the plugin to be used */

		if (!((bbPluginName[i]) == (ptr[i]))) {
			bbPluginName[i] = (ptr[i]);
			needReload = 1;
		}
	}
	if (!((bbPluginName[length]) == 0)) {
		bbPluginName[length] = 0;
		needReload = 1;
	}
	if (needReload) {
		if (!(initialiseModule())) {
			return interpreterProxy->primitiveFail();
		}
	}
	interpreterProxy->pop(1);
}

static double processIndexedofSizeidxArrayidxSize(float *vtxArray, sqInt vtxSize, int *idxArray, sqInt idxSize) {
    sqInt i;
    sqInt index;
    double minZ;
    float *vtxPtr;
    double wValue;
    double zValue;

	minZ = 10.0;
	for (i = 1; i <= idxSize; i += 1) {
		index = idxArray[i];
		if (index > 0) {
			vtxPtr = vtxArray + ((index - 1) * PrimVertexSize);
			zValue = vtxPtr[PrimVtxRasterPosZ];
			wValue = vtxPtr[PrimVtxRasterPosW];
			if (!(wValue == 0.0)) {
				zValue = zValue / wValue;
			}
			if (zValue < minZ) {
				minZ = zValue;
			}
		}
	}
	return minZ;
}

static sqInt processIndexedIDXofSizeidxArrayidxSize(float *vtxArray, sqInt vtxSize, int *idxArray, sqInt idxSize) {
    sqInt i;
    sqInt index;
    sqInt minIndex;
    double minZ;
    float *vtxPtr;
    double wValue;
    double zValue;

	minZ = 10.0;
	minIndex = 0;
	for (i = 1; i <= idxSize; i += 1) {
		index = idxArray[i];
		if (index > 0) {
			vtxPtr = vtxArray + ((index - 1) * PrimVertexSize);
			zValue = vtxPtr[PrimVtxRasterPosZ];
			wValue = vtxPtr[PrimVtxRasterPosW];
			if (!(wValue == 0.0)) {
				zValue = zValue / wValue;
			}
			if ((minIndex == 0) || (zValue < minZ)) {
				minIndex = i;
				minZ = zValue;
			}
		}
	}
	return minIndex;
}

static double processNonIndexedofSize(float *vtxArray, sqInt vtxSize) {
    sqInt i;
    double minZ;
    float *vtxPtr;
    double wValue;
    double zValue;

	minZ = 10.0;
	vtxPtr = vtxArray;
	for (i = 1; i <= vtxSize; i += 1) {
		zValue = vtxPtr[PrimVtxRasterPosZ];
		wValue = vtxPtr[PrimVtxRasterPosW];
		if (!(wValue == 0.0)) {
			zValue = zValue / wValue;
		}
		if (zValue < minZ) {
			minZ = zValue;
		}
	}
	return minZ;
}

static sqInt processNonIndexedIDXofSize(float *vtxArray, sqInt vtxSize) {
    sqInt i;
    sqInt minIndex;
    double minZ;
    float *vtxPtr;
    double wValue;
    double zValue;

	minZ = 10.0;
	minIndex = 0;
	vtxPtr = vtxArray;
	for (i = 1; i <= vtxSize; i += 1) {
		zValue = vtxPtr[PrimVtxRasterPosZ];
		wValue = vtxPtr[PrimVtxRasterPosW];
		if (!(wValue == 0.0)) {
			zValue = zValue / wValue;
		}
		if ((minIndex == 0) || (zValue < minZ)) {
			minIndex = i;
			minZ = zValue;
		}
	}
	return minIndex;
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

static sqInt shadeVertex(void) {
    double cosAngle;
    double specularFactor;
    double aPart;
    double bPart;
    double gPart;
    double rPart;
    double aPart1;
    double bPart1;
    double gPart1;
    double rPart1;
    double aPart2;
    double bPart2;
    double gPart2;
    double rPart2;
    double scale;

	/* begin computeDirection */
	if (lightFlags & FlagPositional) {
		l2vDirection[0] = ((litVertex[PrimVtxPositionX]) - (primLight[PrimLightPositionX]));
		l2vDirection[1] = ((litVertex[PrimVtxPositionY]) - (primLight[PrimLightPositionY]));
		l2vDirection[2] = ((litVertex[PrimVtxPositionZ]) - (primLight[PrimLightPositionZ]));
		l2vDistance = (((l2vDirection[0]) * (l2vDirection[0])) + ((l2vDirection[1]) * (l2vDirection[1]))) + ((l2vDirection[2]) * (l2vDirection[2]));
		if (!((l2vDistance == 0.0) || (l2vDistance == 1.0))) {
			l2vDistance = sqrt(l2vDistance);
			scale = -1.0 / l2vDistance;
		}
		l2vDirection[0] = ((l2vDirection[0]) * scale);
		l2vDirection[1] = ((l2vDirection[1]) * scale);
		l2vDirection[2] = ((l2vDirection[2]) * scale);
	} else {
		if (lightFlags & FlagDirectional) {
			l2vDirection[0] = (primLight[PrimLightDirectionX]);
			l2vDirection[1] = (primLight[PrimLightDirectionY]);
			l2vDirection[2] = (primLight[PrimLightDirectionZ]);
		}
	}
	/* begin computeAttenuation */
	lightScale = 1.0;
	if (lightFlags & FlagAttenuated) {
		lightScale = 1.0 / ((primLight[PrimLightAttenuationConstant]) + (l2vDistance * ((primLight[PrimLightAttenuationLinear]) + (l2vDistance * (primLight[PrimLightAttenuationSquared])))));
	}
	if (lightFlags & FlagHasSpot) {
		lightScale = lightScale * (computeSpotFactor());
	}
	if (lightScale > 0.001) {

		/* Compute the ambient part */

		if (lightFlags & FlagAmbientPart) {
			/* begin addPart:from:trackFlag:scale: */
			if (vbFlags & VBTrackAmbient) {
				rPart = ((vtxInColor[0]) * ((primLight + AmbientPart)[0])) * lightScale;
				gPart = ((vtxInColor[1]) * ((primLight + AmbientPart)[1])) * lightScale;
				bPart = ((vtxInColor[2]) * ((primLight + AmbientPart)[2])) * lightScale;
				aPart = ((vtxInColor[3]) * ((primLight + AmbientPart)[3])) * lightScale;
			} else {
				rPart = (((primMaterial + AmbientPart)[0]) * ((primLight + AmbientPart)[0])) * lightScale;
				gPart = (((primMaterial + AmbientPart)[1]) * ((primLight + AmbientPart)[1])) * lightScale;
				bPart = (((primMaterial + AmbientPart)[2]) * ((primLight + AmbientPart)[2])) * lightScale;
				aPart = (((primMaterial + AmbientPart)[3]) * ((primLight + AmbientPart)[3])) * lightScale;
			}
			vtxOutColor[0] = ((vtxOutColor[0]) + rPart);
			vtxOutColor[1] = ((vtxOutColor[1]) + gPart);
			vtxOutColor[2] = ((vtxOutColor[2]) + bPart);
			vtxOutColor[3] = ((vtxOutColor[3]) + aPart);
		}
		if (lightFlags & FlagDiffusePart) {

			/* Compute angle from light->vertex to vertex normal */


			/* For one-sided lighting negate cosAngle if necessary */

			cosAngle = dotProductOfFloatwithDouble(litVertex + PrimVtxNormal, l2vDirection);
			if (((vbFlags & VBTwoSidedLighting) == 0) && (cosAngle < 0.0)) {
				cosAngle = 0.0 - cosAngle;
			}
			if (cosAngle > 0.0) {
				/* begin addPart:from:trackFlag:scale: */
				if (vbFlags & VBTrackDiffuse) {
					rPart1 = ((vtxInColor[0]) * ((primLight + DiffusePart)[0])) * (lightScale * cosAngle);
					gPart1 = ((vtxInColor[1]) * ((primLight + DiffusePart)[1])) * (lightScale * cosAngle);
					bPart1 = ((vtxInColor[2]) * ((primLight + DiffusePart)[2])) * (lightScale * cosAngle);
					aPart1 = ((vtxInColor[3]) * ((primLight + DiffusePart)[3])) * (lightScale * cosAngle);
				} else {
					rPart1 = (((primMaterial + DiffusePart)[0]) * ((primLight + DiffusePart)[0])) * (lightScale * cosAngle);
					gPart1 = (((primMaterial + DiffusePart)[1]) * ((primLight + DiffusePart)[1])) * (lightScale * cosAngle);
					bPart1 = (((primMaterial + DiffusePart)[2]) * ((primLight + DiffusePart)[2])) * (lightScale * cosAngle);
					aPart1 = (((primMaterial + DiffusePart)[3]) * ((primLight + DiffusePart)[3])) * (lightScale * cosAngle);
				}
				vtxOutColor[0] = ((vtxOutColor[0]) + rPart1);
				vtxOutColor[1] = ((vtxOutColor[1]) + gPart1);
				vtxOutColor[2] = ((vtxOutColor[2]) + bPart1);
				vtxOutColor[3] = ((vtxOutColor[3]) + aPart1);
			}
		}
	}
	if ((lightFlags & FlagSpecularPart) && ((primMaterial[MaterialShininess]) > 0.0)) {

		/* Compute specular part */

		l2vSpecDir[0] = (l2vDirection[0]);
		l2vSpecDir[1] = (l2vDirection[1]);
		l2vSpecDir[2] = (l2vDirection[2]);
		if (vbFlags & VBUseLocalViewer) {
			computeSpecularDirection();
		} else {
			l2vSpecDir[2] = ((l2vSpecDir[2]) - 1.0);
		}
		cosAngle = dotProductOfFloatwithDouble(litVertex + PrimVtxNormal, l2vSpecDir);
		if (cosAngle > 0.0) {

			/* Normalize the angle */


			/* cosAngle should be somewhere between 0 and 1.
			If not, then the vertex normal was not normalized */

			cosAngle = cosAngle * (inverseLengthOfDouble(l2vSpecDir));
			if (cosAngle > 1.0) {
				specularFactor = pow(cosAngle,(primMaterial[MaterialShininess]));
			} else {
				if (cosAngle == 0.0) {
					specularFactor = 1.0;
				} else {
					specularFactor = pow(cosAngle,(primMaterial[MaterialShininess]));
				}
			}
			/* begin addPart:from:trackFlag:scale: */
			if (vbFlags & VBTrackSpecular) {
				rPart2 = ((vtxInColor[0]) * ((primLight + SpecularPart)[0])) * specularFactor;
				gPart2 = ((vtxInColor[1]) * ((primLight + SpecularPart)[1])) * specularFactor;
				bPart2 = ((vtxInColor[2]) * ((primLight + SpecularPart)[2])) * specularFactor;
				aPart2 = ((vtxInColor[3]) * ((primLight + SpecularPart)[3])) * specularFactor;
			} else {
				rPart2 = (((primMaterial + SpecularPart)[0]) * ((primLight + SpecularPart)[0])) * specularFactor;
				gPart2 = (((primMaterial + SpecularPart)[1]) * ((primLight + SpecularPart)[1])) * specularFactor;
				bPart2 = (((primMaterial + SpecularPart)[2]) * ((primLight + SpecularPart)[2])) * specularFactor;
				aPart2 = (((primMaterial + SpecularPart)[3]) * ((primLight + SpecularPart)[3])) * specularFactor;
			}
			vtxOutColor[0] = ((vtxOutColor[0]) + rPart2);
			vtxOutColor[1] = ((vtxOutColor[1]) + gPart2);
			vtxOutColor[2] = ((vtxOutColor[2]) + bPart2);
			vtxOutColor[3] = ((vtxOutColor[3]) + aPart2);
		}
	}
}


/*	Load an Array of B3DPrimitiveLights from the given stack index */

static sqInt stackLightArrayValue(sqInt stackIndex) {
    sqInt array;
    sqInt arraySize;
    sqInt i;
    sqInt oop;

	array = interpreterProxy->stackObjectValue(stackIndex);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!((interpreterProxy->fetchClassOf(array)) == (interpreterProxy->classArray()))) {
		return interpreterProxy->primitiveFail();
	}
	arraySize = interpreterProxy->slotSizeOf(array);
	for (i = 0; i <= (arraySize - 1); i += 1) {
		oop = interpreterProxy->fetchPointerofObject(i, array);
		if ((oop & 1)) {
			return interpreterProxy->primitiveFail();
		}
		if (!((interpreterProxy->isWords(oop)) && ((interpreterProxy->slotSizeOf(oop)) == PrimLightSize))) {
			return interpreterProxy->primitiveFail();
		}
	}
	return array;
}


/*	Load a B3DMaterial from the given stack index */

static void * stackMaterialValue(sqInt stackIndex) {
    sqInt oop;

	oop = interpreterProxy->stackObjectValue(stackIndex);
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((interpreterProxy->isWords(oop)) && ((interpreterProxy->slotSizeOf(oop)) == MaterialSize)) {
		return interpreterProxy->firstIndexableField(oop);
	}
	return null;
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


/*	Load a primitive index array from the interpreter stack.
	If aBool is true then check that all the indexes are in the range (1,maxIndex).
	Return a pointer to the index data if successful, nil otherwise. */

static void* stackPrimitiveIndexArrayofSizevalidateforVertexSize(sqInt stackIndex, sqInt nItems, sqInt aBool, sqInt maxIndex) {
    sqInt i;
    int *idxPtr;
    sqInt index;
    sqInt oop;
    sqInt oopSize;

	oop = interpreterProxy->stackObjectValue(stackIndex);
	if (oop == null) {
		return null;
	}
	if (!(interpreterProxy->isWords(oop))) {
		return null;
	}
	oopSize = interpreterProxy->slotSizeOf(oop);
	if (oopSize < nItems) {
		return null;
	}
	idxPtr = ((int *) (interpreterProxy->firstIndexableField(oop)));
	if (aBool) {
		for (i = 0; i <= (nItems - 1); i += 1) {
			index = idxPtr[i];
			if ((index < 0) || (index > maxIndex)) {
				return null;
			}
		}
	}
	return idxPtr;
}


/*	Load a primitive vertex from the interpreter stack.
	Return a pointer to the vertex data if successful, nil otherwise. */

static void* stackPrimitiveVertex(sqInt index) {
    sqInt oop;

	oop = interpreterProxy->stackObjectValue(index);
	if (oop == null) {
		return null;
	}
	if ((interpreterProxy->isWords(oop)) && ((interpreterProxy->slotSizeOf(oop)) == PrimVertexSize)) {
		return interpreterProxy->firstIndexableField(oop);
	}
	return null;
}


/*	Load a primitive vertex array from the interpreter stack.
	Return a pointer to the vertex data if successful, nil otherwise. */

static void* stackPrimitiveVertexArrayofSize(sqInt index, sqInt nItems) {
    sqInt oop;
    sqInt oopSize;

	oop = interpreterProxy->stackObjectValue(index);
	if (oop == null) {
		return null;
	}
	if (interpreterProxy->isWords(oop)) {
		oopSize = interpreterProxy->slotSizeOf(oop);
		if (((oopSize >= nItems) * PrimVertexSize) && ((oopSize % PrimVertexSize) == 0)) {
			return interpreterProxy->firstIndexableField(oop);
		}
	}
	return null;
}

static sqInt storeObjectsInto(sqInt stackIndex) {
    sqInt arrayOop;
    sqInt arraySize;
    sqInt i;
    sqInt objOop;

	arrayOop = interpreterProxy->stackObjectValue(stackIndex);
	arraySize = state.nObjects;
	for (i = 0; i <= (arraySize - 1); i += 1) {
		objOop = state.objects[i]->__oop__;
		interpreterProxy->storePointerofObjectwithValue(i, arrayOop, objOop);
	}
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


/*	Transform the normal of the given primitive vertex */

static sqInt transformPrimitiveNormalbyrescale(float *pVertex, float *matrix, sqInt rescale) {
    double dot;
    double rx;
    double ry;
    double rz;
    double x;
    double y;
    double z;

	x = pVertex[PrimVtxNormalX];
	y = pVertex[PrimVtxNormalY];
	z = pVertex[PrimVtxNormalZ];
	rx = ((x * (matrix[0])) + (y * (matrix[1]))) + (z * (matrix[2]));
	ry = ((x * (matrix[4])) + (y * (matrix[5]))) + (z * (matrix[6]));
	rz = ((x * (matrix[8])) + (y * (matrix[9]))) + (z * (matrix[10]));
	if (rescale) {
		dot = ((rx * rx) + (ry * ry)) + (rz * rz);
		if (dot < 1.0e-20) {
			rx = (ry = (rz = 0.0));
		} else {
			if (!(dot == 1.0)) {
				dot = 1.0 / (sqrt(dot));
				rx = rx * dot;
				ry = ry * dot;
				rz = rz * dot;
			}
		}
	}
	pVertex[PrimVtxNormalX] = (((float) rx));
	pVertex[PrimVtxNormalY] = (((float) ry));
	pVertex[PrimVtxNormalZ] = (((float) rz));
}


/*	Transform the normal of the given primitive vertex */

static sqInt transformPrimitivePositionby(float *pVertex, float *matrix) {
    double rw;
    double rx;
    double ry;
    double rz;
    double x;
    double y;
    double z;

	x = pVertex[PrimVtxPositionX];
	y = pVertex[PrimVtxPositionY];
	z = pVertex[PrimVtxPositionZ];
	rx = (((x * (matrix[0])) + (y * (matrix[1]))) + (z * (matrix[2]))) + (matrix[3]);
	ry = (((x * (matrix[4])) + (y * (matrix[5]))) + (z * (matrix[6]))) + (matrix[7]);
	rz = (((x * (matrix[8])) + (y * (matrix[9]))) + (z * (matrix[10]))) + (matrix[11]);
	rw = (((x * (matrix[12])) + (y * (matrix[13]))) + (z * (matrix[14]))) + (matrix[15]);
	if (rw == 1.0) {
		pVertex[PrimVtxPositionX] = (((float) rx));
		pVertex[PrimVtxPositionY] = (((float) ry));
		pVertex[PrimVtxPositionZ] = (((float) rz));
	} else {
		if (rw == 0.0) {
			rw = 0.0;
		} else {
			rw = 1.0 / rw;
		}
		pVertex[PrimVtxPositionX] = (((float) (rx * rw)));
		pVertex[PrimVtxPositionY] = (((float) (ry * rw)));
		pVertex[PrimVtxPositionZ] = (((float) (rz * rw)));
	}
}


/*	Transform the position of the given primitive vertex assuming that 
	matrix a41 = a42 = a43 = 0.0 and a44 = 1.0 */

static sqInt transformPrimitivePositionFastby(float *pVertex, float *matrix) {
    double rx;
    double ry;
    double rz;
    double x;
    double y;
    double z;

	x = pVertex[PrimVtxPositionX];
	y = pVertex[PrimVtxPositionY];
	z = pVertex[PrimVtxPositionZ];
	rx = (((x * (matrix[0])) + (y * (matrix[1]))) + (z * (matrix[2]))) + (matrix[3]);
	ry = (((x * (matrix[4])) + (y * (matrix[5]))) + (z * (matrix[6]))) + (matrix[7]);
	rz = (((x * (matrix[8])) + (y * (matrix[9]))) + (z * (matrix[10]))) + (matrix[11]);
	pVertex[PrimVtxPositionX] = (((float) rx));
	pVertex[PrimVtxPositionY] = (((float) ry));
	pVertex[PrimVtxPositionZ] = (((float) rz));
}


/*	Transform the position of the given primitive vertex assuming that 
	matrix a14 = a24 = a34 = a41 = a42 = a43 = 0.0 and a44 = 1.0 */

static sqInt transformPrimitivePositionFasterby(float *pVertex, float *matrix) {
    double rx;
    double ry;
    double rz;
    double x;
    double y;
    double z;

	x = pVertex[PrimVtxPositionX];
	y = pVertex[PrimVtxPositionY];
	z = pVertex[PrimVtxPositionZ];
	rx = ((x * (matrix[0])) + (y * (matrix[1]))) + (z * (matrix[2]));
	ry = ((x * (matrix[4])) + (y * (matrix[5]))) + (z * (matrix[6]));
	rz = ((x * (matrix[8])) + (y * (matrix[9]))) + (z * (matrix[10]));
	pVertex[PrimVtxPositionX] = (((float) rx));
	pVertex[PrimVtxPositionY] = (((float) ry));
	pVertex[PrimVtxPositionZ] = (((float) rz));
}


/*	Transform the normal of the given primitive vertex */

static sqInt transformPrimitiveRasterPositionby(float *pVertex, float *matrix) {
    double rw;
    double rx;
    double ry;
    double rz;
    double x;
    double y;
    double z;

	x = pVertex[PrimVtxPositionX];
	y = pVertex[PrimVtxPositionY];
	z = pVertex[PrimVtxPositionZ];
	rx = (((x * (matrix[0])) + (y * (matrix[1]))) + (z * (matrix[2]))) + (matrix[3]);
	ry = (((x * (matrix[4])) + (y * (matrix[5]))) + (z * (matrix[6]))) + (matrix[7]);
	rz = (((x * (matrix[8])) + (y * (matrix[9]))) + (z * (matrix[10]))) + (matrix[11]);
	rw = (((x * (matrix[12])) + (y * (matrix[13]))) + (z * (matrix[14]))) + (matrix[15]);
	pVertex[PrimVtxRasterPosX] = (((float) rx));
	pVertex[PrimVtxRasterPosY] = (((float) ry));
	pVertex[PrimVtxRasterPosZ] = (((float) rz));
	pVertex[PrimVtxRasterPosW] = (((float) rw));
}


/*	Transform the entire vertex array by the given matrices */
/*	TODO: Check the actual trade-offs between vtxCount and analyzing */

static sqInt transformVBcountbyandflags(float *vtxArray, sqInt vtxCount, float *modelViewMatrix, float *projectionMatrix, sqInt flags) {
    sqInt hasNormals;
    sqInt i;
    sqInt mvFlags;
    float *pVertex;
    sqInt prFlags;
    sqInt rescale;

	mvFlags = analyzeMatrix(modelViewMatrix);
	prFlags = analyzeMatrix(projectionMatrix);
	pVertex = ((float *) vtxArray);

	/* Check if we have to rescale the normals */

	hasNormals = flags & VBVtxHasNormals;
	if (hasNormals) {
		if (mvFlags & FlagM44Identity) {
			rescale = 0;
		} else {
			rescale = analyzeMatrix3x3Length(modelViewMatrix);
		}
	}
	if ((mvFlags & FlagM44NoPerspective) && (prFlags == 0)) {

		/* Modelview matrix has no perspective part and projection is not optimized */

		if ((mvFlags == FlagM44NoTranslation) == 0) {

			/* Modelview matrix with translation */

			for (i = 1; i <= vtxCount; i += 1) {
				if (hasNormals) {
					transformPrimitiveNormalbyrescale(pVertex, modelViewMatrix, rescale);
				}
				transformPrimitivePositionFastby(pVertex, modelViewMatrix);
				transformPrimitiveRasterPositionby(pVertex, projectionMatrix);
				pVertex += PrimVertexSize;
			}
		} else {

			/* Modelview matrix without translation */

			for (i = 1; i <= vtxCount; i += 1) {
				if (hasNormals) {
					transformPrimitiveNormalbyrescale(pVertex, modelViewMatrix, rescale);
				}
				transformPrimitivePositionFasterby(pVertex, modelViewMatrix);
				transformPrimitiveRasterPositionby(pVertex, projectionMatrix);
				pVertex += PrimVertexSize;
			}
		}
		return null;
	}
	if ((mvFlags & prFlags) & FlagM44Identity) {

		/* If both are identity matrices just copy entries */

		for (i = 1; i <= vtxCount; i += 1) {
			pVertex[PrimVtxRasterPosX] = (pVertex[PrimVtxPositionX]);
			pVertex[PrimVtxRasterPosY] = (pVertex[PrimVtxPositionY]);
			pVertex[PrimVtxRasterPosZ] = (pVertex[PrimVtxPositionZ]);
			pVertex[PrimVtxRasterPosW] = 1.0;
			pVertex += PrimVertexSize;
		}
		return null;
	}
	if (mvFlags & FlagM44Identity) {

		/* If model view matrix is identity just perform projection */

		for (i = 1; i <= vtxCount; i += 1) {
			transformPrimitiveRasterPositionby(pVertex, projectionMatrix);
			pVertex += PrimVertexSize;
		}
		return null;
	}
	if (prFlags & FlagM44Identity) {

		/* If projection matrix is identity just transform and copy.
		Note: This case is not very likely so it's not been unrolled. */

		for (i = 1; i <= vtxCount; i += 1) {
			if (hasNormals) {
				transformPrimitiveNormalbyrescale(pVertex, modelViewMatrix, rescale);
			}
			if (mvFlags == (FlagM44NoPerspective + FlagM44NoPerspective)) {
				transformPrimitivePositionFasterby(pVertex, modelViewMatrix);
			} else {
				if (mvFlags == FlagM44NoPerspective) {
					transformPrimitivePositionFastby(pVertex, modelViewMatrix);
				} else {
					transformPrimitivePositionby(pVertex, modelViewMatrix);
				}
			}
			pVertex[PrimVtxRasterPosX] = (pVertex[PrimVtxPositionX]);
			pVertex[PrimVtxRasterPosY] = (pVertex[PrimVtxPositionY]);
			pVertex[PrimVtxRasterPosZ] = (pVertex[PrimVtxPositionZ]);
			pVertex[PrimVtxRasterPosW] = 1.0;
			pVertex += PrimVertexSize;
		}
		return null;
	}
	for (i = 1; i <= vtxCount; i += 1) {
		if (hasNormals) {
			transformPrimitiveNormalbyrescale(pVertex, modelViewMatrix, rescale);
		}
		transformPrimitivePositionby(pVertex, modelViewMatrix);
		transformPrimitiveRasterPositionby(pVertex, projectionMatrix);
		pVertex += PrimVertexSize;
	}
}


/*	Load the word based array of size count from the given oop */

static void* vbLoadArraysize(sqInt oop, sqInt count) {
	if (oop == null) {
		interpreterProxy->primitiveFail();
		return null;
	}
	if (oop == (interpreterProxy->nilObject())) {
		return null;
	}
	if (!(interpreterProxy->isWords(oop))) {
		interpreterProxy->primitiveFail();
		return null;
	}
	if (!((interpreterProxy->slotSizeOf(oop)) == count)) {
		interpreterProxy->primitiveFail();
		return null;
	}
	return interpreterProxy->firstIndexableField(oop);
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* Squeak3D_exports[][3] = {
	{"Squeak3D", "b3dShaderVersion", (void*)b3dShaderVersion},
	{"Squeak3D", "b3dTransformPrimitiveNormal", (void*)b3dTransformPrimitiveNormal},
	{"Squeak3D", "b3dClipPolygon", (void*)b3dClipPolygon},
	{"Squeak3D", "b3dOrthoNormInverseMatrix", (void*)b3dOrthoNormInverseMatrix},
	{"Squeak3D", "b3dTransformVertexBuffer", (void*)b3dTransformVertexBuffer},
	{"Squeak3D", "b3dComputeMinZ", (void*)b3dComputeMinZ},
	{"Squeak3D", "b3dInitializeRasterizerState", (void*)b3dInitializeRasterizerState},
	{"Squeak3D", "b3dDetermineClipFlags", (void*)b3dDetermineClipFlags},
	{"Squeak3D", "getModuleName", (void*)getModuleName},
	{"Squeak3D", "setInterpreter", (void*)setInterpreter},
	{"Squeak3D", "b3dTransformPrimitiveRasterPosition", (void*)b3dTransformPrimitiveRasterPosition},
	{"Squeak3D", "primitiveSetBitBltPlugin", (void*)primitiveSetBitBltPlugin},
	{"Squeak3D", "b3dTransformMatrixWithInto", (void*)b3dTransformMatrixWithInto},
	{"Squeak3D", "b3dStartRasterizer", (void*)b3dStartRasterizer},
	{"Squeak3D", "b3dShadeVertexBuffer", (void*)b3dShadeVertexBuffer},
	{"Squeak3D", "b3dRasterizerVersion", (void*)b3dRasterizerVersion},
	{"Squeak3D", "b3dInitPrimitiveObject", (void*)b3dInitPrimitiveObject},
	{"Squeak3D", "b3dLoadVertexBuffer", (void*)b3dLoadVertexBuffer},
	{"Squeak3D", "b3dTransformDirection", (void*)b3dTransformDirection},
	{"Squeak3D", "moduleUnloaded", (void*)moduleUnloaded},
	{"Squeak3D", "b3dPrimitiveTextureSize", (void*)b3dPrimitiveTextureSize},
	{"Squeak3D", "b3dComputeMinIndexZ", (void*)b3dComputeMinIndexZ},
	{"Squeak3D", "b3dMapVertexBuffer", (void*)b3dMapVertexBuffer},
	{"Squeak3D", "initialiseModule", (void*)initialiseModule},
	{"Squeak3D", "b3dTransformerVersion", (void*)b3dTransformerVersion},
	{"Squeak3D", "b3dTransposeMatrix", (void*)b3dTransposeMatrix},
	{"Squeak3D", "b3dPrimitiveNextClippedTriangle", (void*)b3dPrimitiveNextClippedTriangle},
	{"Squeak3D", "b3dTransformPoint", (void*)b3dTransformPoint},
	{"Squeak3D", "b3dTransformPrimitivePosition", (void*)b3dTransformPrimitivePosition},
	{"Squeak3D", "b3dPrimitiveObjectSize", (void*)b3dPrimitiveObjectSize},
	{"Squeak3D", "b3dLoadIndexArray", (void*)b3dLoadIndexArray},
	{"Squeak3D", "b3dInplaceHouseHolderInvert", (void*)b3dInplaceHouseHolderInvert},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

