/* Automatically generated from Squeak on #(19 March 2005 10:08:55 am) */

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
static int cSquaredDistanceFromto(int *  aPoint, int *  bPoint);
static int cSubstAngleFactorFromto(int startDegreeNumber, int endDegreeNumber);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halt(void);
static int majorNO(void);
static int minorNO(void);
static int msg(char *s);
#pragma export on
EXPORT(int) primSameClassAbsoluteStrokeDistanceMyPoints_otherPoints_myVectors_otherVectors_mySquaredLengths_otherSquaredLengths_myAngles_otherAngles_maxSizeAndReferenceFlag_rowBase_rowInsertRemove_rowInsertRemoveCount(void);
EXPORT(int) primVersionNO(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
static int sqAssert(int aBool);
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"GeniePlugin v2.0 19 March 2005 (i)"
#else
	"GeniePlugin v2.0 19 March 2005 (e)"
#endif
;



/*	arguments are pointer to ints paired as x,y coordinates of points */

static int cSquaredDistanceFromto(int *  aPoint, int *  bPoint) {
	int bPointY;
	int aPointY;
	int bPointX;
	int yDiff;
	int aPointX;
	int xDiff;

	aPointX = aPoint[0];
	aPointY = aPoint[1];
	bPointX = bPoint[0];
	bPointY = bPoint[1];
	xDiff = bPointX - aPointX;
	yDiff = bPointY - aPointY;
	return (xDiff * xDiff) + (yDiff * yDiff);
}

static int cSubstAngleFactorFromto(int startDegreeNumber, int endDegreeNumber) {
	int absDiff;

	absDiff = abs(endDegreeNumber - startDegreeNumber);
	if (absDiff > 180) {
		absDiff = 360 - absDiff;
	}
	return ((unsigned) (absDiff * absDiff) >> 6);
}


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

static int majorNO(void) {
	return 2;
}

static int minorNO(void) {
	return 0;
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

EXPORT(int) primSameClassAbsoluteStrokeDistanceMyPoints_otherPoints_myVectors_otherVectors_mySquaredLengths_otherSquaredLengths_myAngles_otherAngles_maxSizeAndReferenceFlag_rowBase_rowInsertRemove_rowInsertRemoveCount(void) {
	int remove;
	int forReference;
	int *  myAngles;
	int insert;
	int insertRemove;
	int jM1;
	int *  rowBase;
	int otherPointsSize;
	int *  otherPoints;
	int mySquaredLengthsSize;
	int jM1T2;
	int myPointsSize;
	int *  rowInsertRemoveCount;
	int otherSquaredLengthsSize;
	int *  otherVectors;
	int *  otherSquaredLengths;
	int *  otherAngles;
	int *  rowInsertRemove;
	int substBase;
	int insertBase;
	int otherVectorsSize;
	int maxSize;
	int additionalMultiInsertRemoveCost;
	int *  mySquaredLengths;
	int removeBase;
	int i;
	int iM1;
	int maxDist;
	int jLimiT;
	int myVectorsSize;
	int insertRemoveCount;
	int rowBaseSize;
	int j;
	int subst;
	int *  myPoints;
	int *  myVectors;
	int iM1T2;
	int base;
	int myPointsOop;
	int otherPointsOop;
	int myVectorsOop;
	int otherVectorsOop;
	int mySquaredLengthsOop;
	int otherSquaredLengthsOop;
	int myAnglesOop;
	int otherAnglesOop;
	int maxSizeAndRefFlag;
	int rowBaseOop;
	int rowInsertRemoveOop;
	int rowInsertRemoveCountOop;
	int _return_value;

	myPointsOop = interpreterProxy->stackValue(11);
	otherPointsOop = interpreterProxy->stackValue(10);
	myVectorsOop = interpreterProxy->stackValue(9);
	otherVectorsOop = interpreterProxy->stackValue(8);
	mySquaredLengthsOop = interpreterProxy->stackValue(7);
	otherSquaredLengthsOop = interpreterProxy->stackValue(6);
	myAnglesOop = interpreterProxy->stackValue(5);
	otherAnglesOop = interpreterProxy->stackValue(4);
	maxSizeAndRefFlag = interpreterProxy->stackIntegerValue(3);
	rowBaseOop = interpreterProxy->stackValue(2);
	rowInsertRemoveOop = interpreterProxy->stackValue(1);
	rowInsertRemoveCountOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (interpreterProxy->failed()) {
		msg("failed 1");
		return null;
	}
	interpreterProxy->success(((((((((((interpreterProxy->isWords(myPointsOop)) && (interpreterProxy->isWords(otherPointsOop))) && (interpreterProxy->isWords(myVectorsOop))) && (interpreterProxy->isWords(otherVectorsOop))) && (interpreterProxy->isWords(mySquaredLengthsOop))) && (interpreterProxy->isWords(otherSquaredLengthsOop))) && (interpreterProxy->isWords(myAnglesOop))) && (interpreterProxy->isWords(otherAnglesOop))) && (interpreterProxy->isWords(rowBaseOop))) && (interpreterProxy->isWords(rowInsertRemoveOop))) && (interpreterProxy->isWords(rowInsertRemoveCountOop)));
	if (interpreterProxy->failed()) {
		msg("failed 2");
		return null;
	}
	interpreterProxy->success((interpreterProxy->isMemberOf(myPointsOop, "PointArray")) && (interpreterProxy->isMemberOf(otherPointsOop, "PointArray")));
	if (interpreterProxy->failed()) {
		msg("failed 3");
		return null;
	}
	myPoints = interpreterProxy->firstIndexableField(myPointsOop);
	otherPoints = interpreterProxy->firstIndexableField(otherPointsOop);
	myVectors = interpreterProxy->firstIndexableField(myVectorsOop);
	otherVectors = interpreterProxy->firstIndexableField(otherVectorsOop);
	mySquaredLengths = interpreterProxy->firstIndexableField(mySquaredLengthsOop);
	otherSquaredLengths = interpreterProxy->firstIndexableField(otherSquaredLengthsOop);
	myAngles = interpreterProxy->firstIndexableField(myAnglesOop);
	otherAngles = interpreterProxy->firstIndexableField(otherAnglesOop);
	rowBase = interpreterProxy->firstIndexableField(rowBaseOop);
	rowInsertRemove = interpreterProxy->firstIndexableField(rowInsertRemoveOop);

	/* PointArrays */

	rowInsertRemoveCount = interpreterProxy->firstIndexableField(rowInsertRemoveCountOop);
	myPointsSize = ((unsigned) (interpreterProxy->stSizeOf(myPointsOop)) >> 1);
	otherPointsSize = ((unsigned) (interpreterProxy->stSizeOf(otherPointsOop)) >> 1);
	myVectorsSize = ((unsigned) (interpreterProxy->stSizeOf(myVectorsOop)) >> 1);

	/* IntegerArrays */

	otherVectorsSize = ((unsigned) (interpreterProxy->stSizeOf(otherVectorsOop)) >> 1);
	mySquaredLengthsSize = interpreterProxy->stSizeOf(mySquaredLengthsOop);
	otherSquaredLengthsSize = interpreterProxy->stSizeOf(otherSquaredLengthsOop);
	rowBaseSize = interpreterProxy->stSizeOf(rowBaseOop);
	interpreterProxy->success(((rowBaseSize == (interpreterProxy->stSizeOf(rowInsertRemoveOop))) && (rowBaseSize == (interpreterProxy->stSizeOf(rowInsertRemoveCountOop)))) && (rowBaseSize > otherVectorsSize));
	if (interpreterProxy->failed()) {
		msg("failed 4");
		return null;
	}
	interpreterProxy->success((((((mySquaredLengthsSize >= (myVectorsSize - 1)) && (myPointsSize >= myVectorsSize)) && (otherSquaredLengthsSize >= (otherVectorsSize - 1))) && (otherPointsSize >= otherVectorsSize)) && ((interpreterProxy->stSizeOf(myAnglesOop)) >= (myVectorsSize - 1))) && ((interpreterProxy->stSizeOf(otherAnglesOop)) >= (otherVectorsSize - 1)));
	if (interpreterProxy->failed()) {
		msg("failed 5");
		return null;
	}
	forReference = maxSizeAndRefFlag & 1;
	maxSize = ((unsigned) maxSizeAndRefFlag >> 1);
	maxDist = ((unsigned) 1 << 29);
	if (forReference) {
		additionalMultiInsertRemoveCost = 0;
	} else {
		additionalMultiInsertRemoveCost = ((unsigned) (maxSize * maxSize) >> 10);
	}
	rowBase[0] = 0;
	rowInsertRemove[0] = 0;
	rowInsertRemoveCount[0] = 2;
	insertRemove = 0 - additionalMultiInsertRemoveCost;
	jLimiT = otherVectorsSize;
	if (!((otherPointsSize >= (jLimiT - 1)) && (otherSquaredLengthsSize >= (jLimiT - 1)))) {
		interpreterProxy->primitiveFail();
		return null;
	}
	for (j = 1; j <= jLimiT; j += 1) {
		jM1 = j - 1;
		insertRemove = (insertRemove + (((unsigned) ((otherSquaredLengths[jM1]) + (cSquaredDistanceFromto(otherPoints + (((unsigned) jM1 << 1)), myPoints))) >> 7))) + additionalMultiInsertRemoveCost;
		rowInsertRemove[j] = insertRemove;
		rowBase[j] = (insertRemove * j);
		rowInsertRemoveCount[j] = (j + 1);
	}
	insertRemove = (rowInsertRemove[0]) - additionalMultiInsertRemoveCost;
	for (i = 1; i <= myVectorsSize; i += 1) {
		iM1 = i - 1;
		iM1T2 = ((unsigned) iM1 << 1);
		substBase = rowBase[0];
		insertRemove = (insertRemove + (((unsigned) ((mySquaredLengths[iM1]) + (cSquaredDistanceFromto(myPoints + iM1T2, otherPoints))) >> 7))) + additionalMultiInsertRemoveCost;
		rowInsertRemove[0] = insertRemove;
		rowBase[0] = (insertRemove * i);
		rowInsertRemoveCount[0] = (i + 1);
		jLimiT = otherVectorsSize;
		for (j = 1; j <= jLimiT; j += 1) {
			jM1 = j - 1;
			jM1T2 = ((unsigned) jM1 << 1);
			removeBase = rowBase[j];
			insertBase = rowBase[jM1];
			remove = ((unsigned) ((mySquaredLengths[iM1]) + (cSquaredDistanceFromto(myPoints + iM1T2, otherPoints + (((unsigned) j << 1))))) >> 7);
			if ((insertRemove = rowInsertRemove[j]) == 0) {
				removeBase += remove;
			} else {
				removeBase = (removeBase + insertRemove) + (remove * (rowInsertRemoveCount[j]));
				remove += insertRemove;
			}
			insert = ((unsigned) ((otherSquaredLengths[jM1]) + (cSquaredDistanceFromto(otherPoints + jM1T2, myPoints + (((unsigned) i << 1))))) >> 7);
			if ((insertRemove = rowInsertRemove[jM1]) == 0) {
				insertBase += insert;
			} else {
				insertBase = (insertBase + insertRemove) + (insert * (rowInsertRemoveCount[jM1]));
				insert += insertRemove;
			}
			if (forReference) {
				substBase = maxDist;
			} else {
				subst = ((unsigned) (((cSquaredDistanceFromto(otherVectors + jM1T2, myVectors + iM1T2)) + (cSquaredDistanceFromto(otherPoints + jM1T2, myPoints + iM1T2))) * (16 + (cSubstAngleFactorFromto(otherAngles[jM1], myAngles[iM1])))) >> 11);
				substBase += subst;
			}
			if ((substBase <= removeBase) && (substBase <= insertBase)) {
				base = substBase;
				insertRemove = 0;
				insertRemoveCount = 1;
			} else {
				if (removeBase <= insertBase) {
					base = removeBase;
					insertRemove = remove + additionalMultiInsertRemoveCost;
					insertRemoveCount = (rowInsertRemoveCount[j]) + 1;
				} else {
					base = insertBase;
					insertRemove = insert + additionalMultiInsertRemoveCost;
					insertRemoveCount = (rowInsertRemoveCount[jM1]) + 1;
				}
			}
			substBase = rowBase[j];
			rowBase[j] = (((base < maxDist) ? base : maxDist));
			rowInsertRemove[j] = (((insertRemove < maxDist) ? insertRemove : maxDist));
			rowInsertRemoveCount[j] = insertRemoveCount;
		}
		insertRemove = rowInsertRemove[0];
	}
	_return_value = interpreterProxy->integerObjectOf(base);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(13, _return_value);
	return null;
}


/*	majorNO * 1000 + minorNO */

EXPORT(int) primVersionNO(void) {
	int _return_value;

	_return_value = interpreterProxy->integerObjectOf(((2 * 1000) + 0));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
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

static int sqAssert(int aBool) {
	/* missing DebugCode */;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* GeniePlugin_exports[][3] = {
	{"GeniePlugin", "primVersionNO", (void*)primVersionNO},
	{"GeniePlugin", "primSameClassAbsoluteStrokeDistanceMyPoints_otherPoints_myVectors_otherVectors_mySquaredLengths_otherSquaredLengths_myAngles_otherAngles_maxSizeAndReferenceFlag_rowBase_rowInsertRemove_rowInsertRemoveCount", (void*)primSameClassAbsoluteStrokeDistanceMyPoints_otherPoints_myVectors_otherVectors_mySquaredLengths_otherSquaredLengths_myAngles_otherAngles_maxSizeAndReferenceFlag_rowBase_rowInsertRemove_rowInsertRemoveCount},
	{"GeniePlugin", "getModuleName", (void*)getModuleName},
	{"GeniePlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

