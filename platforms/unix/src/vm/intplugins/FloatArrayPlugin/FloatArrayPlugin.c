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
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halt(void);
static int msg(char *s);
#pragma export on
EXPORT(int) primitiveAddFloatArray(void);
EXPORT(int) primitiveAddScalar(void);
EXPORT(int) primitiveAt(void);
EXPORT(int) primitiveAtPut(void);
EXPORT(int) primitiveDivFloatArray(void);
EXPORT(int) primitiveDivScalar(void);
EXPORT(int) primitiveDotProduct(void);
EXPORT(int) primitiveEqual(void);
EXPORT(int) primitiveHashArray(void);
EXPORT(int) primitiveMulFloatArray(void);
EXPORT(int) primitiveMulScalar(void);
EXPORT(int) primitiveSubFloatArray(void);
EXPORT(int) primitiveSubScalar(void);
EXPORT(int) primitiveSum(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"FloatArrayPlugin 19 March 2005 (i)"
#else
	"FloatArrayPlugin 19 March 2005 (e)"
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

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}


/*	Primitive. Add the receiver and the argument, both FloatArrays and store the result into the receiver. */

EXPORT(int) primitiveAddFloatArray(void) {
    int length;
    int i;
    int rcvr;
    float *argPtr;
    float *rcvrPtr;
    int arg;

	arg = interpreterProxy->stackObjectValue(0);
	rcvr = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isWords(arg));
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	if (interpreterProxy->failed()) {
		return null;
	}
	length = interpreterProxy->stSizeOf(arg);
	interpreterProxy->success(length == (interpreterProxy->stSizeOf(rcvr)));
	if (interpreterProxy->failed()) {
		return null;
	}
	rcvrPtr = ((float *) (interpreterProxy->firstIndexableField(rcvr)));
	argPtr = ((float *) (interpreterProxy->firstIndexableField(arg)));
	for (i = 0; i <= (length - 1); i += 1) {
		rcvrPtr[i] = ((rcvrPtr[i]) + (argPtr[i]));
	}
	interpreterProxy->pop(1);
}


/*	Primitive. Add the argument, a scalar value to the receiver, a FloatArray */

EXPORT(int) primitiveAddScalar(void) {
    int i;
    int rcvr;
    float *rcvrPtr;
    double value;
    int length;

	value = interpreterProxy->stackFloatValue(0);
	rcvr = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	if (interpreterProxy->failed()) {
		return null;
	}
	length = interpreterProxy->stSizeOf(rcvr);
	rcvrPtr = ((float *) (interpreterProxy->firstIndexableField(rcvr)));
	for (i = 0; i <= (length - 1); i += 1) {
		rcvrPtr[i] = ((rcvrPtr[i]) + value);
	}
	interpreterProxy->pop(1);
}

EXPORT(int) primitiveAt(void) {
    int rcvr;
    double floatValue;
    int index;
    float *floatPtr;

	index = interpreterProxy->stackIntegerValue(0);
	rcvr = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	interpreterProxy->success((index > 0) && (index <= (interpreterProxy->slotSizeOf(rcvr))));
	if (interpreterProxy->failed()) {
		return null;
	}
	floatPtr = interpreterProxy->firstIndexableField(rcvr);
	floatValue = ((double) (floatPtr[index - 1]) );
	interpreterProxy->pop(2);
	interpreterProxy->pushFloat(floatValue);
}

EXPORT(int) primitiveAtPut(void) {
    double floatValue;
    int rcvr;
    int index;
    int value;
    float *floatPtr;

	value = interpreterProxy->stackValue(0);
	if ((value & 1)) {
		floatValue = ((double) ((value >> 1)) );
	} else {
		floatValue = interpreterProxy->floatValueOf(value);
	}
	index = interpreterProxy->stackIntegerValue(1);
	rcvr = interpreterProxy->stackObjectValue(2);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	interpreterProxy->success((index > 0) && (index <= (interpreterProxy->slotSizeOf(rcvr))));
	if (interpreterProxy->failed()) {
		return null;
	}
	floatPtr = interpreterProxy->firstIndexableField(rcvr);
	floatPtr[index - 1] = (((float) floatValue));
	if (!(interpreterProxy->failed())) {
		interpreterProxy->popthenPush(3, value);
	}
}


/*	Primitive. Add the receiver and the argument, both FloatArrays and store the result into the receiver. */

EXPORT(int) primitiveDivFloatArray(void) {
    int length;
    int i;
    int rcvr;
    float *argPtr;
    float *rcvrPtr;
    int arg;

	arg = interpreterProxy->stackObjectValue(0);
	rcvr = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isWords(arg));
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	if (interpreterProxy->failed()) {
		return null;
	}
	length = interpreterProxy->stSizeOf(arg);
	interpreterProxy->success(length == (interpreterProxy->stSizeOf(rcvr)));
	if (interpreterProxy->failed()) {
		return null;
	}
	rcvrPtr = ((float *) (interpreterProxy->firstIndexableField(rcvr)));

	/* Check if any of the argument's values is zero */

	argPtr = ((float *) (interpreterProxy->firstIndexableField(arg)));
	for (i = 0; i <= (length - 1); i += 1) {
		if ((longAt(argPtr + i)) == 0) {
			return interpreterProxy->primitiveFail();
		}
	}
	for (i = 0; i <= (length - 1); i += 1) {
		rcvrPtr[i] = ((rcvrPtr[i]) / (argPtr[i]));
	}
	interpreterProxy->pop(1);
}


/*	Primitive. Add the argument, a scalar value to the receiver, a FloatArray */

EXPORT(int) primitiveDivScalar(void) {
    double value;
    int length;
    int i;
    int rcvr;
    double inverse;
    float *rcvrPtr;

	value = interpreterProxy->stackFloatValue(0);
	rcvr = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (value == 0.0) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	if (interpreterProxy->failed()) {
		return null;
	}
	length = interpreterProxy->stSizeOf(rcvr);
	rcvrPtr = ((float *) (interpreterProxy->firstIndexableField(rcvr)));
	inverse = 1.0 / value;
	for (i = 0; i <= (length - 1); i += 1) {
		rcvrPtr[i] = ((rcvrPtr[i]) * inverse);
	}
	interpreterProxy->pop(1);
}


/*	Primitive. Compute the dot product of the receiver and the argument.
	The dot product is defined as the sum of the products of the individual elements. */

EXPORT(int) primitiveDotProduct(void) {
    int length;
    double result;
    int i;
    int rcvr;
    float *argPtr;
    float *rcvrPtr;
    int arg;

	arg = interpreterProxy->stackObjectValue(0);
	rcvr = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isWords(arg));
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	if (interpreterProxy->failed()) {
		return null;
	}
	length = interpreterProxy->stSizeOf(arg);
	interpreterProxy->success(length == (interpreterProxy->stSizeOf(rcvr)));
	if (interpreterProxy->failed()) {
		return null;
	}
	rcvrPtr = ((float *) (interpreterProxy->firstIndexableField(rcvr)));
	argPtr = ((float *) (interpreterProxy->firstIndexableField(arg)));
	result = 0.0;
	for (i = 0; i <= (length - 1); i += 1) {
		result += (rcvrPtr[i]) * (argPtr[i]);
	}
	interpreterProxy->pop(2);
	interpreterProxy->pushFloat(result);
}

EXPORT(int) primitiveEqual(void) {
    int length;
    int i;
    int rcvr;
    float *argPtr;
    float *rcvrPtr;
    int arg;

	arg = interpreterProxy->stackObjectValue(0);
	rcvr = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isWords(arg));
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	length = interpreterProxy->stSizeOf(arg);
	if (!(length == (interpreterProxy->stSizeOf(rcvr)))) {
		return interpreterProxy->pushBool(0);
	}
	rcvrPtr = ((float *) (interpreterProxy->firstIndexableField(rcvr)));
	argPtr = ((float *) (interpreterProxy->firstIndexableField(arg)));
	for (i = 0; i <= (length - 1); i += 1) {
		if (!((rcvrPtr[i]) == (argPtr[i]))) {
			return interpreterProxy->pushBool(0);
		}
	}
	return interpreterProxy->pushBool(1);
}

EXPORT(int) primitiveHashArray(void) {
    int i;
    int rcvr;
    int *rcvrPtr;
    int length;
    int result;

	rcvr = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	if (interpreterProxy->failed()) {
		return null;
	}
	length = interpreterProxy->stSizeOf(rcvr);
	rcvrPtr = ((int *) (interpreterProxy->firstIndexableField(rcvr)));
	result = 0;
	for (i = 0; i <= (length - 1); i += 1) {
		result += rcvrPtr[i];
	}
	interpreterProxy->pop(1);
	return interpreterProxy->pushInteger(result & 536870911);
}


/*	Primitive. Add the receiver and the argument, both FloatArrays and store the result into the receiver. */

EXPORT(int) primitiveMulFloatArray(void) {
    int length;
    int i;
    int rcvr;
    float *argPtr;
    float *rcvrPtr;
    int arg;

	arg = interpreterProxy->stackObjectValue(0);
	rcvr = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isWords(arg));
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	if (interpreterProxy->failed()) {
		return null;
	}
	length = interpreterProxy->stSizeOf(arg);
	interpreterProxy->success(length == (interpreterProxy->stSizeOf(rcvr)));
	if (interpreterProxy->failed()) {
		return null;
	}
	rcvrPtr = ((float *) (interpreterProxy->firstIndexableField(rcvr)));
	argPtr = ((float *) (interpreterProxy->firstIndexableField(arg)));
	for (i = 0; i <= (length - 1); i += 1) {
		rcvrPtr[i] = ((rcvrPtr[i]) * (argPtr[i]));
	}
	interpreterProxy->pop(1);
}


/*	Primitive. Add the argument, a scalar value to the receiver, a FloatArray */

EXPORT(int) primitiveMulScalar(void) {
    int i;
    int rcvr;
    float *rcvrPtr;
    double value;
    int length;

	value = interpreterProxy->stackFloatValue(0);
	rcvr = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	if (interpreterProxy->failed()) {
		return null;
	}
	length = interpreterProxy->stSizeOf(rcvr);
	rcvrPtr = ((float *) (interpreterProxy->firstIndexableField(rcvr)));
	for (i = 0; i <= (length - 1); i += 1) {
		rcvrPtr[i] = ((rcvrPtr[i]) * value);
	}
	interpreterProxy->pop(1);
}


/*	Primitive. Add the receiver and the argument, both FloatArrays and store the result into the receiver. */

EXPORT(int) primitiveSubFloatArray(void) {
    int length;
    int i;
    int rcvr;
    float *argPtr;
    float *rcvrPtr;
    int arg;

	arg = interpreterProxy->stackObjectValue(0);
	rcvr = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isWords(arg));
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	if (interpreterProxy->failed()) {
		return null;
	}
	length = interpreterProxy->stSizeOf(arg);
	interpreterProxy->success(length == (interpreterProxy->stSizeOf(rcvr)));
	if (interpreterProxy->failed()) {
		return null;
	}
	rcvrPtr = ((float *) (interpreterProxy->firstIndexableField(rcvr)));
	argPtr = ((float *) (interpreterProxy->firstIndexableField(arg)));
	for (i = 0; i <= (length - 1); i += 1) {
		rcvrPtr[i] = ((rcvrPtr[i]) - (argPtr[i]));
	}
	interpreterProxy->pop(1);
}


/*	Primitive. Add the argument, a scalar value to the receiver, a FloatArray */

EXPORT(int) primitiveSubScalar(void) {
    int i;
    int rcvr;
    float *rcvrPtr;
    double value;
    int length;

	value = interpreterProxy->stackFloatValue(0);
	rcvr = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	if (interpreterProxy->failed()) {
		return null;
	}
	length = interpreterProxy->stSizeOf(rcvr);
	rcvrPtr = ((float *) (interpreterProxy->firstIndexableField(rcvr)));
	for (i = 0; i <= (length - 1); i += 1) {
		rcvrPtr[i] = ((rcvrPtr[i]) - value);
	}
	interpreterProxy->pop(1);
}


/*	Primitive. Find the sum of each float in the receiver, a FloatArray, and stash the result into the argument Float. */

EXPORT(int) primitiveSum(void) {
    int i;
    double sum;
    int rcvr;
    float *rcvrPtr;
    int length;

	rcvr = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isWords(rcvr));
	if (interpreterProxy->failed()) {
		return null;
	}
	length = interpreterProxy->stSizeOf(rcvr);
	rcvrPtr = ((float *) (interpreterProxy->firstIndexableField(rcvr)));
	sum = 0.0;
	for (i = 0; i <= (length - 1); i += 1) {
		sum += rcvrPtr[i];
	}
	interpreterProxy->popthenPush(1, interpreterProxy->floatObjectOf(sum));
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


void* FloatArrayPlugin_exports[][3] = {
	{"FloatArrayPlugin", "primitiveAtPut", (void*)primitiveAtPut},
	{"FloatArrayPlugin", "primitiveMulScalar", (void*)primitiveMulScalar},
	{"FloatArrayPlugin", "primitiveDivScalar", (void*)primitiveDivScalar},
	{"FloatArrayPlugin", "primitiveDotProduct", (void*)primitiveDotProduct},
	{"FloatArrayPlugin", "primitiveAddScalar", (void*)primitiveAddScalar},
	{"FloatArrayPlugin", "primitiveEqual", (void*)primitiveEqual},
	{"FloatArrayPlugin", "primitiveSubScalar", (void*)primitiveSubScalar},
	{"FloatArrayPlugin", "primitiveDivFloatArray", (void*)primitiveDivFloatArray},
	{"FloatArrayPlugin", "primitiveMulFloatArray", (void*)primitiveMulFloatArray},
	{"FloatArrayPlugin", "primitiveSum", (void*)primitiveSum},
	{"FloatArrayPlugin", "primitiveAddFloatArray", (void*)primitiveAddFloatArray},
	{"FloatArrayPlugin", "primitiveSubFloatArray", (void*)primitiveSubFloatArray},
	{"FloatArrayPlugin", "primitiveAt", (void*)primitiveAt},
	{"FloatArrayPlugin", "getModuleName", (void*)getModuleName},
	{"FloatArrayPlugin", "primitiveHashArray", (void*)primitiveHashArray},
	{"FloatArrayPlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

