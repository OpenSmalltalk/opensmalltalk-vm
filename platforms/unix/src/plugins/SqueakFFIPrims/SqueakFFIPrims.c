/* Automatically generated from Squeak on #(18 March 2005 7:42:55 pm) */

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
#include "sqFFI.h"

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)


/*** Constants ***/
#define FFIAtomicTypeMask 251658240
#define FFIAtomicTypeShift 24
#define FFIErrorAddressNotFound 13
#define FFIErrorAttemptToPassVoid 14
#define FFIErrorBadAddress 11
#define FFIErrorBadArg 3
#define FFIErrorBadArgs 2
#define FFIErrorBadAtomicType 5
#define FFIErrorBadExternalFunction 17
#define FFIErrorBadExternalLibrary 16
#define FFIErrorBadReturn 10
#define FFIErrorCallType 9
#define FFIErrorCoercionFailed 6
#define FFIErrorGenericError 0
#define FFIErrorIntAsPointer 4
#define FFIErrorInvalidPointer 18
#define FFIErrorModuleNotFound 15
#define FFIErrorNoModule 12
#define FFIErrorNotFunction 1
#define FFIErrorStructSize 8
#define FFIErrorWrongType 7
#define FFIFlagAtomic 262144
#define FFIFlagPointer 131072
#define FFIFlagStructure 65536
#define FFIStructSizeMask 65535
#define FFITypeBool 1
#define FFITypeDoubleFloat 13
#define FFITypeSignedByte 3
#define FFITypeSignedChar 11
#define FFITypeSignedInt 7
#define FFITypeSignedLongLong 9
#define FFITypeSignedShort 5
#define FFITypeSingleFloat 12
#define FFITypeUnsignedByte 2
#define FFITypeVoid 0

/*** Function Prototypes ***/
static int addressOfstartingAtsize(int rcvr, int byteOffset, int byteSize);
static int atomicTypeOf(int value);
static int ffiArgByValue(int oop);
static int ffiArgumentSpecClass(int oop, int argSpec, int argClass);
static int ffiAtomicArgByReferenceClass(int oop, int oopClass);
static int ffiAtomicStructByReferenceClass(int oop, int oopClass);
static int ffiCallWithFlagsAndTypes(int address, int callType, int argTypeArray);
static int ffiCallWithFlagsArgsAndTypesOfSize(int address, int callType, int argArray, int argTypeArray, int nArgs);
static int ffiCalloutToWithFlags(int address, int callType);
static int ffiCheckReturnWith(int retSpec, int retClass);
static int ffiContentsOfHandleerrCode(int oop, int errCode);
static int ffiCreateLongLongReturn(int isSigned);
static int ffiCreateReturn(int retVal);
static int ffiCreateReturnOop(int retVal);
static int ffiCreateReturnPointer(int retVal);
static int ffiCreateReturnStruct(void);
static int ffiFail(int reason);
static double ffiFloatValueOf(int oop);
static int ffiGetLastError(void);
static int ffiIntegerValueOf(int oop);
static int ffiLoadCalloutAddress(int lit);
static int ffiLoadCalloutAddressFrom(int oop);
static int ffiLoadCalloutModule(int module);
static int ffiPushPointerContentsOf(int oop);
static int ffiPushSignedLongLongOop(int oop);
static int ffiPushStructureContentsOf(int oop);
static int ffiPushUnsignedLongLongOop(int oop);
static int ffiPushVoid(int ignored);
static int ffiReturnCStringFrom(int cPointer);
static int ffiSetLastError(int errCode);
static int ffiValidateExternalDataAtomicType(int oop, int atomicType);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halt(void);
static int isAtomicType(int typeSpec);
static int msg(char *s);
#pragma export on
EXPORT(int) primitiveCallout(void);
EXPORT(int) primitiveCalloutWithArgs(void);
EXPORT(int) primitiveFFIAllocate(void);
EXPORT(int) primitiveFFIDoubleAt(void);
EXPORT(int) primitiveFFIDoubleAtPut(void);
EXPORT(int) primitiveFFIFloatAt(void);
EXPORT(int) primitiveFFIFloatAtPut(void);
EXPORT(int) primitiveFFIFree(void);
EXPORT(int) primitiveFFIGetLastError(void);
EXPORT(int) primitiveFFIIntegerAt(void);
EXPORT(int) primitiveFFIIntegerAtPut(void);
EXPORT(int) primitiveForceLoad(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
/*** Variables ***/
static int ffiArgClass;
static int ffiArgHeader;
static int ffiArgSpec;
static int ffiArgSpecSize;
static int ffiLastError;
static int ffiRetClass;
static int ffiRetHeader;
static int ffiRetOop;
static int ffiRetSpec;
static int ffiRetSpecSize;

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"SqueakFFIPrims 18 March 2005 (i)"
#else
	"SqueakFFIPrims 18 March 2005 (e)"
#endif
;


static int addressOfstartingAtsize(int rcvr, int byteOffset, int byteSize) {
    int addr;
    int rcvrClass;
    int rcvrSize;

	if (!(interpreterProxy->isBytes(rcvr))) {
		return interpreterProxy->primitiveFail();
	}
	if (!(byteOffset > 0)) {
		return interpreterProxy->primitiveFail();
	}
	rcvrClass = interpreterProxy->fetchClassOf(rcvr);
	rcvrSize = interpreterProxy->byteSizeOf(rcvr);
	if (rcvrClass == (interpreterProxy->classExternalAddress())) {
		if (!(rcvrSize == 4)) {
			return interpreterProxy->primitiveFail();
		}

		/* don't you dare to read from object memory! */

		addr = interpreterProxy->fetchWordofObject(0, rcvr);
		if ((addr == 0) || (interpreterProxy->isInMemory(addr))) {
			return interpreterProxy->primitiveFail();
		}
	} else {
		if (!(((byteOffset + byteSize) - 1) <= rcvrSize)) {
			return interpreterProxy->primitiveFail();
		}
		addr = ((int) (interpreterProxy->firstIndexableField(rcvr)));
	}
	addr = (addr + byteOffset) - 1;
	return addr;
}

static int atomicTypeOf(int value) {
	return ((unsigned) (value & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
}


/*	Support for generic callout. Prepare an argument by value for a callout. */

static int ffiArgByValue(int oop) {
    int intValue;
    double floatValue;
    int atomicType;
    int oopClass;
    int oopClass1;


	/* check if the range is valid */

	atomicType = ((unsigned) (ffiArgHeader & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
	if ((atomicType < 0) || (atomicType > FFITypeDoubleFloat)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadAtomicType;
		return interpreterProxy->primitiveFail();
	}
	if (atomicType < FFITypeSingleFloat) {
		if ((((unsigned) atomicType) >> 1) == (((unsigned) FFITypeSignedLongLong) >> 1)) {

			/* ffi support code must coerce longlong */

			intValue = oop;
		} else {
			/* begin ffiIntegerValueOf: */
			if ((oop & 1)) {
				intValue = (oop >> 1);
				goto l1;
			}
			if (oop == (interpreterProxy->nilObject())) {
				intValue = 0;
				goto l1;
			}
			if (oop == (interpreterProxy->falseObject())) {
				intValue = 0;
				goto l1;
			}
			if (oop == (interpreterProxy->trueObject())) {
				intValue = 1;
				goto l1;
			}
			oopClass = interpreterProxy->fetchClassOf(oop);
			if (oopClass == (interpreterProxy->classFloat())) {
				intValue = ((int) (interpreterProxy->floatValueOf(oop)) );
				goto l1;
			}
			if (oopClass == (interpreterProxy->classCharacter())) {
				intValue = interpreterProxy->fetchIntegerofObject(0, oop);
				goto l1;
			}
			intValue = interpreterProxy->signed32BitValueOf(oop);
		l1:	/* end ffiIntegerValueOf: */;
		}
		if (interpreterProxy->failed()) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorCoercionFailed;
			return interpreterProxy->primitiveFail();
		}
		switch (atomicType) {
		case 0:
			ffiFail(FFIErrorAttemptToPassVoid);
			break;
		case 1:
			ffiPushUnsignedInt(intValue);
			break;
		case 2:
			ffiPushUnsignedByte(intValue);
			break;
		case 3:
			ffiPushSignedByte(intValue);
			break;
		case 4:
			ffiPushUnsignedShort(intValue);
			break;
		case 5:
			ffiPushSignedShort(intValue);
			break;
		case 6:
			ffiPushUnsignedInt(intValue);
			break;
		case 7:
			ffiPushSignedInt(intValue);
			break;
		case 8:
			ffiPushUnsignedLongLongOop(intValue);
			break;
		case 9:
			ffiPushSignedLongLongOop(intValue);
			break;
		case 10:
			ffiPushUnsignedChar(intValue);
			break;
		case 11:
			ffiPushSignedChar(intValue);
			break;
		}
	} else {
		/* begin ffiFloatValueOf: */
		oopClass1 = interpreterProxy->fetchClassOf(oop);
		if (oopClass1 == (interpreterProxy->classFloat())) {
			floatValue = interpreterProxy->floatValueOf(oop);
			goto l2;
		}
		floatValue = ((double) (ffiIntegerValueOf(oop)) );
	l2:	/* end ffiFloatValueOf: */;
		if (interpreterProxy->failed()) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorCoercionFailed;
			return interpreterProxy->primitiveFail();
		}
		if (atomicType == FFITypeSingleFloat) {
			ffiPushSingleFloat(floatValue);
		} else {
			ffiPushDoubleFloat(floatValue);
		}
	}
	return 0;
}


/*	Callout support. Prepare the given oop as argument.
	argSpec defines the compiled spec for the argument.
	argClass (if non-nil) defines the required (super)class for the argument. */

static int ffiArgumentSpecClass(int oop, int argSpec, int argClass) {
    int oopClass;
    int nilOop;
    int valueOop;
    int isStruct;
    int ptrClass;
    int ptrValue;
    int ptrAddress;
    int atomicType;
    int valueOop1;
    int atomicType1;
    int isString;
    int specType;
    int ptrType;
    int specOop;
    int spec;
    int intValue;
    double floatValue;
    int atomicType2;
    int oopClass2;
    int oopClass1;


	/* Prefetch class (we'll need it) */

	oopClass = interpreterProxy->fetchClassOf(oop);

	/* Do the necessary type checks */

	nilOop = interpreterProxy->nilObject();
	if (!(argClass == nilOop)) {
		if (!(interpreterProxy->includesBehaviorThatOf(argClass, interpreterProxy->classExternalStructure()))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorWrongType;
			return interpreterProxy->primitiveFail();
		}
		if (!((nilOop == oop) || (interpreterProxy->includesBehaviorThatOf(oopClass, argClass)))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorCoercionFailed;
			return interpreterProxy->primitiveFail();
		}
	}
	isStruct = 0;
	if (!(((oop & 1)) || (oop == nilOop))) {
		if (interpreterProxy->isPointers(oop)) {
			isStruct = interpreterProxy->includesBehaviorThatOf(oopClass, interpreterProxy->classExternalStructure());
			if (!((argClass == nilOop) || (isStruct))) {
				/* begin ffiFail: */
				ffiLastError = FFIErrorCoercionFailed;
				return interpreterProxy->primitiveFail();
			}
		}
	}
	if (isStruct) {
		valueOop = interpreterProxy->fetchPointerofObject(0, oop);
	} else {
		valueOop = oop;
	}

	/* Fetch and check the contents of the compiled spec */

	ffiArgClass = argClass;
	if ((argSpec & 1)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		return null;
	}
	if (!(interpreterProxy->isWords(argSpec))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		return null;
	}
	ffiArgSpecSize = interpreterProxy->slotSizeOf(argSpec);
	if (ffiArgSpecSize == 0) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		return null;
	}
	ffiArgSpec = ((int) (interpreterProxy->firstIndexableField(argSpec)));

	/* Do the actual preparation of the argument */
	/* Note: Order is important since FFIFlagStructure + FFIFlagPointer is used to represent 'typedef void* VoidPointer' and VoidPointer really is *struct* not pointer. */

	ffiArgHeader = longAt(ffiArgSpec);
	if (ffiArgHeader & FFIFlagStructure) {
		if (!(isStruct)) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorCoercionFailed;
			return interpreterProxy->primitiveFail();
		}
		if (ffiArgHeader & FFIFlagAtomic) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorWrongType;
			return interpreterProxy->primitiveFail();
		}
		/* begin ffiPushStructureContentsOf: */
		ptrValue = valueOop;
		ptrClass = interpreterProxy->fetchClassOf(ptrValue);
		if (ptrClass == (interpreterProxy->classExternalAddress())) {
			ptrAddress = interpreterProxy->fetchWordofObject(0, ptrValue);
			if (interpreterProxy->isInMemory(ptrAddress)) {
				/* begin ffiFail: */
				ffiLastError = FFIErrorInvalidPointer;
				return interpreterProxy->primitiveFail();
			}
			return ffiPushStructureOfLength(ptrAddress, ((int*) ffiArgSpec), ffiArgSpecSize);
		}
		if (ptrClass == (interpreterProxy->classByteArray())) {
			if (!((interpreterProxy->byteSizeOf(ptrValue)) == (ffiArgHeader & FFIStructSizeMask))) {
				/* begin ffiFail: */
				ffiLastError = FFIErrorStructSize;
				return interpreterProxy->primitiveFail();
			}
			ptrAddress = ((int) (interpreterProxy->firstIndexableField(ptrValue)));
			if (!(ffiArgHeader & FFIFlagPointer)) {
				return ffiPushStructureOfLength(ptrAddress, ((int*) ffiArgSpec), ffiArgSpecSize);
			}
			if (!((ffiArgHeader & FFIStructSizeMask) == 4)) {
				/* begin ffiFail: */
				ffiLastError = FFIErrorStructSize;
				return interpreterProxy->primitiveFail();
			}
			ptrAddress = interpreterProxy->fetchWordofObject(0, ptrValue);
			if (interpreterProxy->isInMemory(ptrAddress)) {
				/* begin ffiFail: */
				ffiLastError = FFIErrorInvalidPointer;
				return interpreterProxy->primitiveFail();
			}
			return ffiPushPointer(ptrAddress);
		}
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadArg;
		return interpreterProxy->primitiveFail();
	}
	if (ffiArgHeader & FFIFlagPointer) {
		if ((oop & 1)) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorIntAsPointer;
			return interpreterProxy->primitiveFail();
		}
		if (oop == (interpreterProxy->nilObject())) {
			return ffiPushPointer(null);
		}
		if (ffiArgHeader & FFIFlagAtomic) {
			if (isStruct) {
				/* begin ffiAtomicStructByReference:Class: */
				if (!(oopClass == (interpreterProxy->classExternalData()))) {
					/* begin ffiFail: */
					ffiLastError = FFIErrorCoercionFailed;
					return interpreterProxy->primitiveFail();
				}
				atomicType = ((unsigned) (ffiArgHeader & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
				if (atomicType != FFITypeVoid) {
					/* begin ffiValidateExternalData:AtomicType: */
					ptrType = interpreterProxy->fetchPointerofObject(1, oop);
					if ((ptrType & 1)) {
						/* begin ffiFail: */
						ffiLastError = FFIErrorWrongType;
						interpreterProxy->primitiveFail();
						goto l1;
					}
					if (!(interpreterProxy->isPointers(ptrType))) {
						/* begin ffiFail: */
						ffiLastError = FFIErrorWrongType;
						interpreterProxy->primitiveFail();
						goto l1;
					}
					if ((interpreterProxy->slotSizeOf(ptrType)) < 2) {
						/* begin ffiFail: */
						ffiLastError = FFIErrorWrongType;
						interpreterProxy->primitiveFail();
						goto l1;
					}
					specOop = interpreterProxy->fetchPointerofObject(0, ptrType);
					if ((specOop & 1)) {
						/* begin ffiFail: */
						ffiLastError = FFIErrorWrongType;
						interpreterProxy->primitiveFail();
						goto l1;
					}
					if (!(interpreterProxy->isWords(specOop))) {
						/* begin ffiFail: */
						ffiLastError = FFIErrorWrongType;
						interpreterProxy->primitiveFail();
						goto l1;
					}
					if ((interpreterProxy->slotSizeOf(specOop)) == 0) {
						/* begin ffiFail: */
						ffiLastError = FFIErrorWrongType;
						interpreterProxy->primitiveFail();
						goto l1;
					}
					spec = interpreterProxy->fetchWordofObject(0, specOop);
					if (!(spec & FFIFlagAtomic)) {
						/* begin ffiFail: */
						ffiLastError = FFIErrorWrongType;
						interpreterProxy->primitiveFail();
						goto l1;
					}
					specType = ((unsigned) (spec & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
					if (specType != atomicType) {
						if (!((atomicType > FFITypeBool) && (atomicType < FFITypeSingleFloat))) {
							/* begin ffiFail: */
							ffiLastError = FFIErrorCoercionFailed;
							interpreterProxy->primitiveFail();
							goto l1;
						}
						if (!((((unsigned) atomicType) >> 1) == (((unsigned) specType) >> 1))) {
							/* begin ffiFail: */
							ffiLastError = FFIErrorCoercionFailed;
							interpreterProxy->primitiveFail();
							goto l1;
						}
					}
				l1:	/* end ffiValidateExternalData:AtomicType: */;
					if (interpreterProxy->failed()) {
						return null;
					}
				}
				valueOop1 = interpreterProxy->fetchPointerofObject(0, oop);
				return ffiPushPointerContentsOf(valueOop1);
			} else {
				/* begin ffiAtomicArgByReference:Class: */
				atomicType1 = ((unsigned) (ffiArgHeader & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
				if (atomicType1 == FFITypeBool) {
					/* begin ffiFail: */
					ffiLastError = FFIErrorCoercionFailed;
					return interpreterProxy->primitiveFail();
				}
				if ((((unsigned) atomicType1) >> 1) == (((unsigned) FFITypeSignedChar) >> 1)) {
					isString = interpreterProxy->includesBehaviorThatOf(oopClass, interpreterProxy->classString());
					if (isString) {
						return ffiPushStringOfLength(((int) (interpreterProxy->firstIndexableField(oop))), interpreterProxy->byteSizeOf(oop));
					}
					atomicType1 = FFITypeUnsignedByte;
				}
				if ((atomicType1 == FFITypeVoid) || ((((unsigned) atomicType1) >> 1) == (((unsigned) FFITypeSignedByte) >> 1))) {
					if (oopClass == (interpreterProxy->classByteArray())) {
						return ffiPushPointer(((int) (interpreterProxy->firstIndexableField(oop))));
					}
					isString = interpreterProxy->includesBehaviorThatOf(oopClass, interpreterProxy->classString());
					if (isString) {
						return ffiPushPointer(((int) (interpreterProxy->firstIndexableField(oop))));
					}
					if (!(atomicType1 == FFITypeVoid)) {
						/* begin ffiFail: */
						ffiLastError = FFIErrorCoercionFailed;
						return interpreterProxy->primitiveFail();
					}
				}
				if ((atomicType1 <= FFITypeSignedInt) || (atomicType1 == FFITypeSingleFloat)) {
					if (interpreterProxy->isWords(oop)) {
						return ffiPushPointer(((int) (interpreterProxy->firstIndexableField(oop))));
					}
				}
				/* begin ffiFail: */
				ffiLastError = FFIErrorCoercionFailed;
				return interpreterProxy->primitiveFail();
			}
		}
		if (!(isStruct)) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorCoercionFailed;
			return interpreterProxy->primitiveFail();
		}
		return ffiPushPointerContentsOf(valueOop);
	}
	if (ffiArgHeader & FFIFlagAtomic) {
		/* begin ffiArgByValue: */
		atomicType2 = ((unsigned) (ffiArgHeader & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
		if ((atomicType2 < 0) || (atomicType2 > FFITypeDoubleFloat)) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorBadAtomicType;
			interpreterProxy->primitiveFail();
			goto l4;
		}
		if (atomicType2 < FFITypeSingleFloat) {
			if ((((unsigned) atomicType2) >> 1) == (((unsigned) FFITypeSignedLongLong) >> 1)) {
				intValue = valueOop;
			} else {
				/* begin ffiIntegerValueOf: */
				if ((valueOop & 1)) {
					intValue = (valueOop >> 1);
					goto l3;
				}
				if (valueOop == (interpreterProxy->nilObject())) {
					intValue = 0;
					goto l3;
				}
				if (valueOop == (interpreterProxy->falseObject())) {
					intValue = 0;
					goto l3;
				}
				if (valueOop == (interpreterProxy->trueObject())) {
					intValue = 1;
					goto l3;
				}
				oopClass2 = interpreterProxy->fetchClassOf(valueOop);
				if (oopClass2 == (interpreterProxy->classFloat())) {
					intValue = ((int) (interpreterProxy->floatValueOf(valueOop)) );
					goto l3;
				}
				if (oopClass2 == (interpreterProxy->classCharacter())) {
					intValue = interpreterProxy->fetchIntegerofObject(0, valueOop);
					goto l3;
				}
				intValue = interpreterProxy->signed32BitValueOf(valueOop);
			l3:	/* end ffiIntegerValueOf: */;
			}
			if (interpreterProxy->failed()) {
				/* begin ffiFail: */
				ffiLastError = FFIErrorCoercionFailed;
				interpreterProxy->primitiveFail();
				goto l4;
			}
			switch (atomicType2) {
			case 0:
				ffiFail(FFIErrorAttemptToPassVoid);
				break;
			case 1:
				ffiPushUnsignedInt(intValue);
				break;
			case 2:
				ffiPushUnsignedByte(intValue);
				break;
			case 3:
				ffiPushSignedByte(intValue);
				break;
			case 4:
				ffiPushUnsignedShort(intValue);
				break;
			case 5:
				ffiPushSignedShort(intValue);
				break;
			case 6:
				ffiPushUnsignedInt(intValue);
				break;
			case 7:
				ffiPushSignedInt(intValue);
				break;
			case 8:
				ffiPushUnsignedLongLongOop(intValue);
				break;
			case 9:
				ffiPushSignedLongLongOop(intValue);
				break;
			case 10:
				ffiPushUnsignedChar(intValue);
				break;
			case 11:
				ffiPushSignedChar(intValue);
				break;
			}
		} else {
			/* begin ffiFloatValueOf: */
			oopClass1 = interpreterProxy->fetchClassOf(valueOop);
			if (oopClass1 == (interpreterProxy->classFloat())) {
				floatValue = interpreterProxy->floatValueOf(valueOop);
				goto l2;
			}
			floatValue = ((double) (ffiIntegerValueOf(valueOop)) );
		l2:	/* end ffiFloatValueOf: */;
			if (interpreterProxy->failed()) {
				/* begin ffiFail: */
				ffiLastError = FFIErrorCoercionFailed;
				interpreterProxy->primitiveFail();
				goto l4;
			}
			if (atomicType2 == FFITypeSingleFloat) {
				ffiPushSingleFloat(floatValue);
			} else {
				ffiPushDoubleFloat(floatValue);
			}
		}
	l4:	/* end ffiArgByValue: */;
		return 0;
	}
	/* begin ffiFail: */
	ffiLastError = FFIErrorWrongType;
	return interpreterProxy->primitiveFail();
}


/*	Support for generic callout. Prepare a pointer reference to an atomic type for callout. Note: for type 'void*' we allow either one of ByteArray/String/Symbol or wordVariableSubclass. */

static int ffiAtomicArgByReferenceClass(int oop, int oopClass) {
    int atomicType;
    int isString;

	atomicType = ((unsigned) (ffiArgHeader & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
	if (atomicType == FFITypeBool) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorCoercionFailed;
		return interpreterProxy->primitiveFail();
	}
	if ((((unsigned) atomicType) >> 1) == (((unsigned) FFITypeSignedChar) >> 1)) {
		isString = interpreterProxy->includesBehaviorThatOf(oopClass, interpreterProxy->classString());
		if (isString) {
			return ffiPushStringOfLength(((int) (interpreterProxy->firstIndexableField(oop))), interpreterProxy->byteSizeOf(oop));
		}
		atomicType = FFITypeUnsignedByte;
	}
	if ((atomicType == FFITypeVoid) || ((((unsigned) atomicType) >> 1) == (((unsigned) FFITypeSignedByte) >> 1))) {
		if (oopClass == (interpreterProxy->classByteArray())) {
			return ffiPushPointer(((int) (interpreterProxy->firstIndexableField(oop))));
		}
		isString = interpreterProxy->includesBehaviorThatOf(oopClass, interpreterProxy->classString());
		if (isString) {
			return ffiPushPointer(((int) (interpreterProxy->firstIndexableField(oop))));
		}
		if (!(atomicType == FFITypeVoid)) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorCoercionFailed;
			return interpreterProxy->primitiveFail();
		}
	}
	if ((atomicType <= FFITypeSignedInt) || (atomicType == FFITypeSingleFloat)) {
		if (interpreterProxy->isWords(oop)) {
			return ffiPushPointer(((int) (interpreterProxy->firstIndexableField(oop))));
		}
	}
	/* begin ffiFail: */
	ffiLastError = FFIErrorCoercionFailed;
	return interpreterProxy->primitiveFail();
}


/*	Support for generic callout. Prepare an external pointer reference to an atomic type for callout. */

static int ffiAtomicStructByReferenceClass(int oop, int oopClass) {
    int atomicType;
    int valueOop;
    int specType;
    int ptrType;
    int specOop;
    int spec;

	if (!(oopClass == (interpreterProxy->classExternalData()))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorCoercionFailed;
		return interpreterProxy->primitiveFail();
	}

	/* no type checks for void pointers */

	atomicType = ((unsigned) (ffiArgHeader & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
	if (atomicType != FFITypeVoid) {
		/* begin ffiValidateExternalData:AtomicType: */
		ptrType = interpreterProxy->fetchPointerofObject(1, oop);
		if ((ptrType & 1)) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorWrongType;
			interpreterProxy->primitiveFail();
			goto l1;
		}
		if (!(interpreterProxy->isPointers(ptrType))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorWrongType;
			interpreterProxy->primitiveFail();
			goto l1;
		}
		if ((interpreterProxy->slotSizeOf(ptrType)) < 2) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorWrongType;
			interpreterProxy->primitiveFail();
			goto l1;
		}
		specOop = interpreterProxy->fetchPointerofObject(0, ptrType);
		if ((specOop & 1)) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorWrongType;
			interpreterProxy->primitiveFail();
			goto l1;
		}
		if (!(interpreterProxy->isWords(specOop))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorWrongType;
			interpreterProxy->primitiveFail();
			goto l1;
		}
		if ((interpreterProxy->slotSizeOf(specOop)) == 0) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorWrongType;
			interpreterProxy->primitiveFail();
			goto l1;
		}
		spec = interpreterProxy->fetchWordofObject(0, specOop);
		if (!(spec & FFIFlagAtomic)) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorWrongType;
			interpreterProxy->primitiveFail();
			goto l1;
		}
		specType = ((unsigned) (spec & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
		if (specType != atomicType) {
			if (!((atomicType > FFITypeBool) && (atomicType < FFITypeSingleFloat))) {
				/* begin ffiFail: */
				ffiLastError = FFIErrorCoercionFailed;
				interpreterProxy->primitiveFail();
				goto l1;
			}
			if (!((((unsigned) atomicType) >> 1) == (((unsigned) specType) >> 1))) {
				/* begin ffiFail: */
				ffiLastError = FFIErrorCoercionFailed;
				interpreterProxy->primitiveFail();
				goto l1;
			}
		}
	l1:	/* end ffiValidateExternalData:AtomicType: */;
		if (interpreterProxy->failed()) {
			return null;
		}
	}
	valueOop = interpreterProxy->fetchPointerofObject(0, oop);
	return ffiPushPointerContentsOf(valueOop);
}


/*	Generic callout. Does the actual work. */

static int ffiCallWithFlagsAndTypes(int address, int callType, int argTypeArray) {
    int oop;
    int i;
    int argTypes;
    int nArgs;
    int stackIndex;
    int argType;
    int argClass;
    int argSpec;

	if (!(ffiSupportsCallingConvention(callType))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorCallType;
		return interpreterProxy->primitiveFail();
	}

	/* Fetch return type and args */

	argTypes = argTypeArray;
	argType = interpreterProxy->fetchPointerofObject(0, argTypes);
	argSpec = interpreterProxy->fetchPointerofObject(0, argType);
	argClass = interpreterProxy->fetchPointerofObject(1, argType);
	/* begin ffiCheckReturn:With: */
	if (!(argClass == (interpreterProxy->nilObject()))) {
		if (!(interpreterProxy->includesBehaviorThatOf(argClass, interpreterProxy->classExternalStructure()))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorBadReturn;
			interpreterProxy->primitiveFail();
			goto l1;
		}
	}
	ffiRetClass = argClass;
	if ((argSpec & 1)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		goto l1;
	}
	if (!(interpreterProxy->isWords(argSpec))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		goto l1;
	}
	ffiRetSpecSize = interpreterProxy->slotSizeOf(argSpec);
	if (ffiRetSpecSize == 0) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		goto l1;
	}
	ffiRetSpec = ((int) (interpreterProxy->firstIndexableField(argSpec)));
	ffiRetHeader = longAt(ffiRetSpec);
	if (!(ffiRetHeader & FFIFlagAtomic)) {
		if (ffiRetClass == (interpreterProxy->nilObject())) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorBadReturn;
			interpreterProxy->primitiveFail();
			goto l1;
		}
	}
	if (!(ffiCanReturn(((int*) ffiRetSpec), ffiRetSpecSize))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadReturn;
		interpreterProxy->primitiveFail();
	}
l1:	/* end ffiCheckReturn:With: */;
	if (interpreterProxy->failed()) {
		return 0;
	}
	ffiRetOop = argType;
	nArgs = interpreterProxy->methodArgumentCount();

	/* stack index goes downwards */

	stackIndex = nArgs - 1;
	for (i = 1; i <= nArgs; i += 1) {
		argType = interpreterProxy->fetchPointerofObject(i, argTypes);
		argSpec = interpreterProxy->fetchPointerofObject(0, argType);
		argClass = interpreterProxy->fetchPointerofObject(1, argType);
		oop = interpreterProxy->stackValue(stackIndex);
		ffiArgumentSpecClass(oop, argSpec, argClass);
		if (interpreterProxy->failed()) {
			return 0;
		}
		stackIndex -= 1;
	}
	return ffiCalloutToWithFlags(address, callType);
}


/*	Generic callout. Does the actual work. */

static int ffiCallWithFlagsArgsAndTypesOfSize(int address, int callType, int argArray, int argTypeArray, int nArgs) {
    int oop;
    int i;
    int argTypes;
    int argType;
    int argClass;
    int argSpec;

	if (!(ffiSupportsCallingConvention(callType))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorCallType;
		return interpreterProxy->primitiveFail();
	}

	/* Fetch return type and args */

	argTypes = argTypeArray;
	argType = interpreterProxy->fetchPointerofObject(0, argTypes);
	argSpec = interpreterProxy->fetchPointerofObject(0, argType);
	argClass = interpreterProxy->fetchPointerofObject(1, argType);
	/* begin ffiCheckReturn:With: */
	if (!(argClass == (interpreterProxy->nilObject()))) {
		if (!(interpreterProxy->includesBehaviorThatOf(argClass, interpreterProxy->classExternalStructure()))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorBadReturn;
			interpreterProxy->primitiveFail();
			goto l1;
		}
	}
	ffiRetClass = argClass;
	if ((argSpec & 1)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		goto l1;
	}
	if (!(interpreterProxy->isWords(argSpec))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		goto l1;
	}
	ffiRetSpecSize = interpreterProxy->slotSizeOf(argSpec);
	if (ffiRetSpecSize == 0) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		goto l1;
	}
	ffiRetSpec = ((int) (interpreterProxy->firstIndexableField(argSpec)));
	ffiRetHeader = longAt(ffiRetSpec);
	if (!(ffiRetHeader & FFIFlagAtomic)) {
		if (ffiRetClass == (interpreterProxy->nilObject())) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorBadReturn;
			interpreterProxy->primitiveFail();
			goto l1;
		}
	}
	if (!(ffiCanReturn(((int*) ffiRetSpec), ffiRetSpecSize))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadReturn;
		interpreterProxy->primitiveFail();
	}
l1:	/* end ffiCheckReturn:With: */;
	if (interpreterProxy->failed()) {
		return 0;
	}
	ffiRetOop = argType;
	for (i = 1; i <= nArgs; i += 1) {
		argType = interpreterProxy->fetchPointerofObject(i, argTypes);
		argSpec = interpreterProxy->fetchPointerofObject(0, argType);
		argClass = interpreterProxy->fetchPointerofObject(1, argType);
		oop = interpreterProxy->fetchPointerofObject(i - 1, argArray);
		ffiArgumentSpecClass(oop, argSpec, argClass);
		if (interpreterProxy->failed()) {
			return 0;
		}
	}
	return ffiCalloutToWithFlags(address, callType);
}


/*	Go out, call this guy and create the return value */

static int ffiCalloutToWithFlags(int address, int callType) {
    int retVal;
    int oop;
    int retOop;
    int structSize;
    int oop1;
    int atomicType;
    int retOop1;
    int atomicType1;
    int value;
    int byteSize;
    int shift;
    int mask;

	if (ffiRetHeader & FFIFlagPointer) {
		retVal = ffiCallAddressOfWithPointerReturn(address, callType);
		return ffiCreateReturnPointer(retVal);
	}
	if (ffiRetHeader & FFIFlagStructure) {
		ffiCallAddressOfWithStructReturn(address, callType, ((int*) ffiRetSpec), ffiRetSpecSize);
		/* begin ffiCreateReturnStruct */
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->pop((interpreterProxy->methodArgumentCount()) + 1);
		structSize = ffiRetHeader & FFIStructSizeMask;
		interpreterProxy->pushRemappableOop(ffiRetClass);
		oop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), structSize);
		ffiStoreStructure(((int) (interpreterProxy->firstIndexableField(oop))), structSize);
		ffiRetClass = interpreterProxy->popRemappableOop();
		interpreterProxy->pushRemappableOop(oop);
		retOop = interpreterProxy->instantiateClassindexableSize(ffiRetClass, 0);
		oop = interpreterProxy->popRemappableOop();
		interpreterProxy->storePointerofObjectwithValue(0, retOop, oop);
		return interpreterProxy->push(retOop);
	}
	retVal = ffiCallAddressOfWithReturnType(address, callType, ffiRetHeader);
	/* begin ffiCreateReturn: */
	if (interpreterProxy->failed()) {
		return null;
	}
	atomicType = ((unsigned) (ffiRetHeader & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
	if (atomicType <= FFITypeVoid) {
		return interpreterProxy->pop(interpreterProxy->methodArgumentCount());
	}
	interpreterProxy->pop((interpreterProxy->methodArgumentCount()) + 1);
	interpreterProxy->pushRemappableOop(ffiRetClass);
	/* begin ffiCreateReturnOop: */
	atomicType1 = ((unsigned) (ffiRetHeader & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
	if (atomicType1 == FFITypeBool) {
		byteSize = ffiRetHeader & FFIStructSizeMask;
		if (byteSize == 4) {
			value = retVal;
		} else {
			value = retVal & ((1 << (byteSize * 8)) - 1);
		}
		if (value == 0) {
			retOop1 = interpreterProxy->falseObject();
			goto l1;
		} else {
			retOop1 = interpreterProxy->trueObject();
			goto l1;
		}
	}
	if (atomicType1 <= FFITypeSignedInt) {
		if (atomicType1 <= FFITypeSignedShort) {
			shift = (((unsigned) atomicType1) >> 1) * 8;
			value = retVal & ((1 << shift) - 1);
			if (atomicType1 & 1) {
				mask = 1 << (shift - 1);
				value = (value & (mask - 1)) - (value & mask);
			}
			retOop1 = ((value << 1) | 1);
			goto l1;
		}
		if (atomicType1 & 1) {
			retOop1 = interpreterProxy->signed32BitIntegerFor(retVal);
			goto l1;
		} else {
			retOop1 = interpreterProxy->positive32BitIntegerFor(retVal);
			goto l1;
		}
	}
	if (atomicType1 < FFITypeSingleFloat) {
		if ((((unsigned) atomicType1) >> 1) == (((unsigned) FFITypeSignedLongLong) >> 1)) {
			retOop1 = ffiCreateLongLongReturn(atomicType1 & 1);
			goto l1;
		} else {
			retOop1 = interpreterProxy->fetchPointerofObject(retVal & 255, interpreterProxy->characterTable());
			goto l1;
		}
	}
	retOop1 = interpreterProxy->floatObjectOf(ffiReturnFloatValue());
l1:	/* end ffiCreateReturnOop: */;
	ffiRetClass = interpreterProxy->popRemappableOop();
	if (ffiRetClass == (interpreterProxy->nilObject())) {
		return interpreterProxy->push(retOop1);
	}
	interpreterProxy->pushRemappableOop(retOop1);
	retOop1 = interpreterProxy->instantiateClassindexableSize(ffiRetClass, 0);
	oop1 = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(0, retOop1, oop1);
	return interpreterProxy->push(retOop1);
}


/*	Make sure we can return an object of the given type */

static int ffiCheckReturnWith(int retSpec, int retClass) {
	if (!(retClass == (interpreterProxy->nilObject()))) {
		if (!(interpreterProxy->includesBehaviorThatOf(retClass, interpreterProxy->classExternalStructure()))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorBadReturn;
			return interpreterProxy->primitiveFail();
		}
	}
	ffiRetClass = retClass;
	if ((retSpec & 1)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		return null;
	}
	if (!(interpreterProxy->isWords(retSpec))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		return null;
	}
	ffiRetSpecSize = interpreterProxy->slotSizeOf(retSpec);
	if (ffiRetSpecSize == 0) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		return null;
	}
	ffiRetSpec = ((int) (interpreterProxy->firstIndexableField(retSpec)));
	ffiRetHeader = longAt(ffiRetSpec);
	if (!(ffiRetHeader & FFIFlagAtomic)) {
		if (ffiRetClass == (interpreterProxy->nilObject())) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorBadReturn;
			return interpreterProxy->primitiveFail();
		}
	}
	if (!(ffiCanReturn(((int*) ffiRetSpec), ffiRetSpecSize))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadReturn;
		interpreterProxy->primitiveFail();
	}
	return 0;
}


/*	Make sure that the given oop is a valid external handle */

static int ffiContentsOfHandleerrCode(int oop, int errCode) {
	if ((oop & 1)) {
		/* begin ffiFail: */
		ffiLastError = errCode;
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->isBytes(oop))) {
		/* begin ffiFail: */
		ffiLastError = errCode;
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->byteSizeOf(oop)) == 4)) {
		/* begin ffiFail: */
		ffiLastError = errCode;
		return interpreterProxy->primitiveFail();
	}
	return interpreterProxy->fetchWordofObject(0, oop);
}


/*	Create a longlong return value from a previous call out */

static int ffiCreateLongLongReturn(int isSigned) {
    int highWord;
    int nBytes;
    unsigned char *ptr;
    int largeClass;
    int largeInt;
    int i;
    int lowWord;

	lowWord = ffiLongLongResultLow();
	highWord = ffiLongLongResultHigh();
	if (isSigned) {
		if ((highWord == 0) && (lowWord >= 0)) {
			return interpreterProxy->signed32BitIntegerFor(lowWord);
		}
		if ((highWord == -1) && (lowWord < 0)) {
			return interpreterProxy->signed32BitIntegerFor(lowWord);
		}
		if (highWord < 0) {
			largeClass = interpreterProxy->classLargeNegativeInteger();
			lowWord = ~lowWord;
			highWord = ~highWord;
			if (lowWord == -1) {
				highWord += 1;
			}
			lowWord += 1;
		} else {
			largeClass = interpreterProxy->classLargePositiveInteger();
		}
	} else {
		if (highWord == 0) {
			return interpreterProxy->positive32BitIntegerFor(lowWord);
		}
		largeClass = interpreterProxy->classLargePositiveInteger();
	}
	nBytes = 8;
	if (!(highWord & (255 << 24))) {
		nBytes = 7;
		if (highWord < (1 << 16)) {
			nBytes = 6;
		}
		if (highWord < (1 << 8)) {
			nBytes = 5;
		}
		if (highWord == 0) {
			nBytes = 4;
		}
	}
	largeInt = interpreterProxy->instantiateClassindexableSize(largeClass, nBytes);
	if (!(interpreterProxy->isBytes(largeInt))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadReturn;
		return interpreterProxy->primitiveFail();
	}
	ptr = interpreterProxy->firstIndexableField(largeInt);
	for (i = 4; i <= (nBytes - 1); i += 1) {
		ptr[i] = ((((unsigned) highWord) >> ((i - 4) * 8)) & 255);
	}
	ptr[3] = ((((unsigned) lowWord) >> 24) & 255);
	ptr[2] = ((((unsigned) lowWord) >> 16) & 255);
	ptr[1] = ((((unsigned) lowWord) >> 8) & 255);
	ptr[0] = (lowWord & 255);
	return largeInt;
}


/*	Generic callout support. Create an atomic return value from an external function call */

static int ffiCreateReturn(int retVal) {
    int oop;
    int atomicType;
    int retOop;
    int atomicType1;
    int value;
    int byteSize;
    int shift;
    int mask;

	if (interpreterProxy->failed()) {
		return null;
	}

	/* void returns self */

	atomicType = ((unsigned) (ffiRetHeader & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
	if (atomicType <= FFITypeVoid) {
		return interpreterProxy->pop(interpreterProxy->methodArgumentCount());
	}
	interpreterProxy->pop((interpreterProxy->methodArgumentCount()) + 1);
	interpreterProxy->pushRemappableOop(ffiRetClass);
	/* begin ffiCreateReturnOop: */
	atomicType1 = ((unsigned) (ffiRetHeader & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
	if (atomicType1 == FFITypeBool) {
		byteSize = ffiRetHeader & FFIStructSizeMask;
		if (byteSize == 4) {
			value = retVal;
		} else {
			value = retVal & ((1 << (byteSize * 8)) - 1);
		}
		if (value == 0) {
			retOop = interpreterProxy->falseObject();
			goto l1;
		} else {
			retOop = interpreterProxy->trueObject();
			goto l1;
		}
	}
	if (atomicType1 <= FFITypeSignedInt) {
		if (atomicType1 <= FFITypeSignedShort) {
			shift = (((unsigned) atomicType1) >> 1) * 8;
			value = retVal & ((1 << shift) - 1);
			if (atomicType1 & 1) {
				mask = 1 << (shift - 1);
				value = (value & (mask - 1)) - (value & mask);
			}
			retOop = ((value << 1) | 1);
			goto l1;
		}
		if (atomicType1 & 1) {
			retOop = interpreterProxy->signed32BitIntegerFor(retVal);
			goto l1;
		} else {
			retOop = interpreterProxy->positive32BitIntegerFor(retVal);
			goto l1;
		}
	}
	if (atomicType1 < FFITypeSingleFloat) {
		if ((((unsigned) atomicType1) >> 1) == (((unsigned) FFITypeSignedLongLong) >> 1)) {
			retOop = ffiCreateLongLongReturn(atomicType1 & 1);
			goto l1;
		} else {
			retOop = interpreterProxy->fetchPointerofObject(retVal & 255, interpreterProxy->characterTable());
			goto l1;
		}
	}
	retOop = interpreterProxy->floatObjectOf(ffiReturnFloatValue());
l1:	/* end ffiCreateReturnOop: */;
	ffiRetClass = interpreterProxy->popRemappableOop();
	if (ffiRetClass == (interpreterProxy->nilObject())) {
		return interpreterProxy->push(retOop);
	}
	interpreterProxy->pushRemappableOop(retOop);
	retOop = interpreterProxy->instantiateClassindexableSize(ffiRetClass, 0);
	oop = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(0, retOop, oop);
	return interpreterProxy->push(retOop);
}


/*	Callout support. Return the appropriate oop for the given atomic value */

static int ffiCreateReturnOop(int retVal) {
    int atomicType;
    int value;
    int byteSize;
    int shift;
    int mask;

	atomicType = ((unsigned) (ffiRetHeader & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
	if (atomicType == FFITypeBool) {
		byteSize = ffiRetHeader & FFIStructSizeMask;
		if (byteSize == 4) {
			value = retVal;
		} else {
			value = retVal & ((1 << (byteSize * 8)) - 1);
		}
		if (value == 0) {
			return interpreterProxy->falseObject();
		} else {
			return interpreterProxy->trueObject();
		}
	}
	if (atomicType <= FFITypeSignedInt) {
		if (atomicType <= FFITypeSignedShort) {

			/* # of significant bits */

			shift = (((unsigned) atomicType) >> 1) * 8;
			value = retVal & ((1 << shift) - 1);
			if (atomicType & 1) {
				mask = 1 << (shift - 1);
				value = (value & (mask - 1)) - (value & mask);
			}
			return ((value << 1) | 1);
		}
		if (atomicType & 1) {
			return interpreterProxy->signed32BitIntegerFor(retVal);
		} else {
			return interpreterProxy->positive32BitIntegerFor(retVal);
		}
	}
	if (atomicType < FFITypeSingleFloat) {
		if ((((unsigned) atomicType) >> 1) == (((unsigned) FFITypeSignedLongLong) >> 1)) {
			return ffiCreateLongLongReturn(atomicType & 1);
		} else {
			return interpreterProxy->fetchPointerofObject(retVal & 255, interpreterProxy->characterTable());
		}
	}
	return interpreterProxy->floatObjectOf(ffiReturnFloatValue());
}


/*	Generic callout support. Create a pointer return value from an external function call */

static int ffiCreateReturnPointer(int retVal) {
    int *ptr;
    int oop;
    int atomicType;
    int retOop;
    int classOop;

	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop((interpreterProxy->methodArgumentCount()) + 1);
	if (ffiRetClass == (interpreterProxy->nilObject())) {
		atomicType = ((unsigned) (ffiRetHeader & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
		if ((((unsigned) atomicType) >> 1) == (((unsigned) FFITypeSignedChar) >> 1)) {
			return ffiReturnCStringFrom(retVal);
		}
		interpreterProxy->pushRemappableOop(ffiRetOop);
		oop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classExternalAddress(), 4);
		ptr = interpreterProxy->firstIndexableField(oop);
		ptr[0] = retVal;
		interpreterProxy->pushRemappableOop(oop);
		retOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classExternalData(), 0);

		/* external address */

		oop = interpreterProxy->popRemappableOop();
		interpreterProxy->storePointerofObjectwithValue(0, retOop, oop);

		/* return type */

		oop = interpreterProxy->popRemappableOop();
		interpreterProxy->storePointerofObjectwithValue(1, retOop, oop);
		return interpreterProxy->push(retOop);
	}
	interpreterProxy->pushRemappableOop(ffiRetClass);
	if (ffiRetHeader & FFIFlagStructure) {
		classOop = interpreterProxy->classByteArray();
	} else {
		classOop = interpreterProxy->classExternalAddress();
	}
	oop = interpreterProxy->instantiateClassindexableSize(classOop, 4);
	ptr = interpreterProxy->firstIndexableField(oop);
	ptr[0] = retVal;

	/* return class */

	ffiRetClass = interpreterProxy->popRemappableOop();
	interpreterProxy->pushRemappableOop(oop);
	retOop = interpreterProxy->instantiateClassindexableSize(ffiRetClass, 0);

	/* external address */

	oop = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(0, retOop, oop);
	return interpreterProxy->push(retOop);
}


/*	Generic callout support. Create a structure return value from an external function call */

static int ffiCreateReturnStruct(void) {
    int oop;
    int retOop;
    int structSize;

	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop((interpreterProxy->methodArgumentCount()) + 1);
	structSize = ffiRetHeader & FFIStructSizeMask;
	interpreterProxy->pushRemappableOop(ffiRetClass);
	oop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), structSize);
	ffiStoreStructure(((int) (interpreterProxy->firstIndexableField(oop))), structSize);
	ffiRetClass = interpreterProxy->popRemappableOop();
	interpreterProxy->pushRemappableOop(oop);
	retOop = interpreterProxy->instantiateClassindexableSize(ffiRetClass, 0);
	oop = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(0, retOop, oop);
	return interpreterProxy->push(retOop);
}

static int ffiFail(int reason) {
	ffiLastError = reason;
	return interpreterProxy->primitiveFail();
}


/*	Support for generic callout. Return a float value that is coerced as C would do. */

static double ffiFloatValueOf(int oop) {
    int oopClass;

	oopClass = interpreterProxy->fetchClassOf(oop);
	if (oopClass == (interpreterProxy->classFloat())) {
		return interpreterProxy->floatValueOf(oop);
	}
	return ((double) (ffiIntegerValueOf(oop)) );
}

static int ffiGetLastError(void) {
	return ffiLastError;
}


/*	Support for generic callout. Return an integer value that is coerced as C would do. */

static int ffiIntegerValueOf(int oop) {
    int oopClass;

	if ((oop & 1)) {
		return (oop >> 1);
	}
	if (oop == (interpreterProxy->nilObject())) {
		return 0;
	}
	if (oop == (interpreterProxy->falseObject())) {
		return 0;
	}
	if (oop == (interpreterProxy->trueObject())) {
		return 1;
	}
	oopClass = interpreterProxy->fetchClassOf(oop);
	if (oopClass == (interpreterProxy->classFloat())) {
		return ((int) (interpreterProxy->floatValueOf(oop)) );
	}
	if (oopClass == (interpreterProxy->classCharacter())) {
		return interpreterProxy->fetchIntegerofObject(0, oop);
	}
	return interpreterProxy->signed32BitValueOf(oop);
}


/*	Load the address of the foreign function from the given object */

static int ffiLoadCalloutAddress(int lit) {
    int *ptr;
    int address;
    int addressPtr;


	/* Make sure it's an external handle */

	addressPtr = interpreterProxy->fetchPointerofObject(0, lit);
	/* begin ffiContentsOfHandle:errCode: */
	if ((addressPtr & 1)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadAddress;
		address = interpreterProxy->primitiveFail();
		goto l1;
	}
	if (!(interpreterProxy->isBytes(addressPtr))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadAddress;
		address = interpreterProxy->primitiveFail();
		goto l1;
	}
	if (!((interpreterProxy->byteSizeOf(addressPtr)) == 4)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadAddress;
		address = interpreterProxy->primitiveFail();
		goto l1;
	}
	address = interpreterProxy->fetchWordofObject(0, addressPtr);
l1:	/* end ffiContentsOfHandle:errCode: */;
	if (interpreterProxy->failed()) {
		return 0;
	}
	if (address == 0) {
		if ((interpreterProxy->slotSizeOf(lit)) < 5) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorNoModule;
			return interpreterProxy->primitiveFail();
		}
		address = ffiLoadCalloutAddressFrom(lit);
		if (interpreterProxy->failed()) {
			return 0;
		}
		ptr = interpreterProxy->firstIndexableField(addressPtr);
		ptr[0] = address;
	}
	return address;
}


/*	Load the function address for a call out to an external function */

static int ffiLoadCalloutAddressFrom(int oop) {
    int moduleHandle;
    int address;
    int functionName;
    int module;
    int functionLength;

	module = interpreterProxy->fetchPointerofObject(4, oop);
	moduleHandle = ffiLoadCalloutModule(module);
	if (interpreterProxy->failed()) {
		return 0;
	}
	functionName = interpreterProxy->fetchPointerofObject(3, oop);
	if (!(interpreterProxy->isBytes(functionName))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadExternalFunction;
		return interpreterProxy->primitiveFail();
	}
	functionLength = interpreterProxy->byteSizeOf(functionName);
	address = interpreterProxy->ioLoadSymbolOfLengthFromModule(((int) (interpreterProxy->firstIndexableField(functionName))), functionLength, moduleHandle);
	if ((interpreterProxy->failed()) || (address == 0)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorAddressNotFound;
		return interpreterProxy->primitiveFail();
	}
	return address;
}


/*	Load the given module and return its handle */

static int ffiLoadCalloutModule(int module) {
    int moduleHandle;
    int moduleHandlePtr;
    int theClass;
    int *ptr;
    int ffiModuleName;
    int moduleLength;
    int rcvr;

	if (interpreterProxy->isBytes(module)) {
		ffiModuleName = module;
		moduleLength = interpreterProxy->byteSizeOf(ffiModuleName);
		moduleHandle = interpreterProxy->ioLoadModuleOfLength(((int) (interpreterProxy->firstIndexableField(ffiModuleName))), moduleLength);
		if (interpreterProxy->failed()) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorModuleNotFound;
			return interpreterProxy->primitiveFail();
		}
		return moduleHandle;
	}
	rcvr = interpreterProxy->stackValue(interpreterProxy->methodArgumentCount());
	theClass = interpreterProxy->fetchClassOf(rcvr);
	if (!(interpreterProxy->includesBehaviorThatOf(theClass, interpreterProxy->classExternalLibrary()))) {
		return 0;
	}
	moduleHandlePtr = interpreterProxy->fetchPointerofObject(0, rcvr);
	/* begin ffiContentsOfHandle:errCode: */
	if ((moduleHandlePtr & 1)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadExternalLibrary;
		moduleHandle = interpreterProxy->primitiveFail();
		goto l1;
	}
	if (!(interpreterProxy->isBytes(moduleHandlePtr))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadExternalLibrary;
		moduleHandle = interpreterProxy->primitiveFail();
		goto l1;
	}
	if (!((interpreterProxy->byteSizeOf(moduleHandlePtr)) == 4)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadExternalLibrary;
		moduleHandle = interpreterProxy->primitiveFail();
		goto l1;
	}
	moduleHandle = interpreterProxy->fetchWordofObject(0, moduleHandlePtr);
l1:	/* end ffiContentsOfHandle:errCode: */;
	if (interpreterProxy->failed()) {
		return 0;
	}
	if (moduleHandle == 0) {
		ffiModuleName = interpreterProxy->fetchPointerofObject(1, rcvr);
		if (!(interpreterProxy->isBytes(ffiModuleName))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorBadExternalLibrary;
			return interpreterProxy->primitiveFail();
		}
		moduleLength = interpreterProxy->byteSizeOf(ffiModuleName);
		moduleHandle = interpreterProxy->ioLoadModuleOfLength(((int) (interpreterProxy->firstIndexableField(ffiModuleName))), moduleLength);
		if (interpreterProxy->failed()) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorModuleNotFound;
			return interpreterProxy->primitiveFail();
		}
		ptr = interpreterProxy->firstIndexableField(moduleHandlePtr);
		ptr[0] = moduleHandle;
	}
	return moduleHandle;
}


/*	Push the contents of the given external structure */

static int ffiPushPointerContentsOf(int oop) {
    int ptrClass;
    int ptrValue;
    int ptrAddress;

	ptrValue = oop;
	ptrClass = interpreterProxy->fetchClassOf(ptrValue);
	if (ptrClass == (interpreterProxy->classExternalAddress())) {

		/* Don't you dare to pass pointers into object memory */

		ptrAddress = interpreterProxy->fetchWordofObject(0, ptrValue);
		if (interpreterProxy->isInMemory(ptrAddress)) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorInvalidPointer;
			return interpreterProxy->primitiveFail();
		}
		return ffiPushPointer(ptrAddress);
	}
	if (ptrClass == (interpreterProxy->classByteArray())) {
		ptrAddress = ((int) (interpreterProxy->firstIndexableField(ptrValue)));
		return ffiPushPointer(ptrAddress);
	}
	/* begin ffiFail: */
	ffiLastError = FFIErrorBadArg;
	return interpreterProxy->primitiveFail();
}


/*	Push a longlong type (e.g., a 64bit integer).
	Note: Coercions from float are *not* supported. */

static int ffiPushSignedLongLongOop(int oop) {
    int highWord;
    int oopClass;
    unsigned char *ptr;
    int length;
    int i;
    int lowWord;
    int negative;

	if (oop == (interpreterProxy->nilObject())) {
		return ffiPushSignedLongLong(0, 0);
	}
	if (oop == (interpreterProxy->falseObject())) {
		return ffiPushSignedLongLong(0, 0);
	}
	if (oop == (interpreterProxy->trueObject())) {
		return ffiPushSignedLongLong(0, 1);
	}
	if ((oop & 1)) {
		lowWord = (oop >> 1);
		if (lowWord < 0) {
			highWord = -1;
		} else {
			highWord = 0;
		}
	} else {
		oopClass = interpreterProxy->fetchClassOf(oop);
		if (oopClass == (interpreterProxy->classLargePositiveInteger())) {
			negative = 0;
		} else {
			if (oopClass == (interpreterProxy->classLargeNegativeInteger())) {
				negative = 1;
			} else {
				/* begin ffiFail: */
				ffiLastError = FFIErrorCoercionFailed;
				return interpreterProxy->primitiveFail();
			}
		}
		if (!(interpreterProxy->isBytes(oop))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorCoercionFailed;
			return interpreterProxy->primitiveFail();
		}
		length = interpreterProxy->byteSizeOf(oop);
		if (length > 8) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorCoercionFailed;
			return interpreterProxy->primitiveFail();
		}
		lowWord = highWord = 0;
		ptr = interpreterProxy->firstIndexableField(oop);
		for (i = 0; i <= ((((length < 4) ? length : 4)) - 1); i += 1) {
			lowWord += (ptr[i]) << (i * 8);
		}
		for (i = 0; i <= (length - 5); i += 1) {
			highWord += (ptr[i + 4]) << (i * 8);
		}
		if (negative) {
			lowWord = ~lowWord;
			highWord = ~highWord;
			if (lowWord == -1) {
				highWord += 1;
			}
			lowWord += 1;
		}
	}
	return ffiPushSignedLongLong(lowWord, highWord);
}


/*	Push the contents of the given external structure */

static int ffiPushStructureContentsOf(int oop) {
    int ptrClass;
    int ptrValue;
    int ptrAddress;

	ptrValue = oop;
	ptrClass = interpreterProxy->fetchClassOf(ptrValue);
	if (ptrClass == (interpreterProxy->classExternalAddress())) {

		/* There is no way we can make sure the structure is valid.
		But we can at least check for attempts to pass pointers to ST memory. */

		ptrAddress = interpreterProxy->fetchWordofObject(0, ptrValue);
		if (interpreterProxy->isInMemory(ptrAddress)) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorInvalidPointer;
			return interpreterProxy->primitiveFail();
		}
		return ffiPushStructureOfLength(ptrAddress, ((int*) ffiArgSpec), ffiArgSpecSize);
	}
	if (ptrClass == (interpreterProxy->classByteArray())) {
		if (!((interpreterProxy->byteSizeOf(ptrValue)) == (ffiArgHeader & FFIStructSizeMask))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorStructSize;
			return interpreterProxy->primitiveFail();
		}
		ptrAddress = ((int) (interpreterProxy->firstIndexableField(ptrValue)));
		if (!(ffiArgHeader & FFIFlagPointer)) {
			return ffiPushStructureOfLength(ptrAddress, ((int*) ffiArgSpec), ffiArgSpecSize);
		}
		if (!((ffiArgHeader & FFIStructSizeMask) == 4)) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorStructSize;
			return interpreterProxy->primitiveFail();
		}
		ptrAddress = interpreterProxy->fetchWordofObject(0, ptrValue);
		if (interpreterProxy->isInMemory(ptrAddress)) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorInvalidPointer;
			return interpreterProxy->primitiveFail();
		}
		return ffiPushPointer(ptrAddress);
	}
	/* begin ffiFail: */
	ffiLastError = FFIErrorBadArg;
	return interpreterProxy->primitiveFail();
}


/*	Push a longlong type (e.g., a 64bit integer).
	Note: Coercions from float are *not* supported. */

static int ffiPushUnsignedLongLongOop(int oop) {
    int highWord;
    unsigned char *ptr;
    int length;
    int i;
    int lowWord;

	if (oop == (interpreterProxy->nilObject())) {
		return ffiPushUnsignedLongLong(0, 0);
	}
	if (oop == (interpreterProxy->falseObject())) {
		return ffiPushUnsignedLongLong(0, 0);
	}
	if (oop == (interpreterProxy->trueObject())) {
		return ffiPushUnsignedLongLong(0, 1);
	}
	if ((oop & 1)) {
		lowWord = (oop >> 1);
		if (lowWord < 0) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorCoercionFailed;
			return interpreterProxy->primitiveFail();
		}
		highWord = 0;
	} else {
		if (!((interpreterProxy->fetchClassOf(oop)) == (interpreterProxy->classLargePositiveInteger()))) {
			return interpreterProxy->primitiveFail();
		}
		if (!(interpreterProxy->isBytes(oop))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorCoercionFailed;
			return interpreterProxy->primitiveFail();
		}
		length = interpreterProxy->byteSizeOf(oop);
		if (length > 8) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorCoercionFailed;
			return interpreterProxy->primitiveFail();
		}
		lowWord = highWord = 0;
		ptr = interpreterProxy->firstIndexableField(oop);
		for (i = 0; i <= ((((length < 4) ? length : 4)) - 1); i += 1) {
			lowWord += (ptr[i]) << (i * 8);
		}
		for (i = 0; i <= (length - 5); i += 1) {
			highWord += (ptr[i + 4]) << (i * 8);
		}
	}
	return ffiPushUnsignedLongLong(lowWord, highWord);
}


/*	This is a fallback in case somebody tries to pass a 'void' value.
	We could simply ignore the argument but I think it's better to let
	the caller know what he did */

static int ffiPushVoid(int ignored) {
	/* begin ffiFail: */
	ffiLastError = FFIErrorAttemptToPassVoid;
	return interpreterProxy->primitiveFail();
}


/*	Create a Smalltalk string from a zero terminated C string */

static int ffiReturnCStringFrom(int cPointer) {
    int strOop;
    int i;
    char *cString;
    int strLen;
    char *strPtr;

	if (cPointer == null) {
		return interpreterProxy->push(interpreterProxy->nilObject());
	}
	cString = ((char *) cPointer);
	strLen = 0;
	while (!((cString[strLen]) == 0)) {
		strLen += 1;
	}
	strOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), strLen);
	strPtr = interpreterProxy->firstIndexableField(strOop);
	for (i = 0; i <= (strLen - 1); i += 1) {
		strPtr[i] = (cString[i]);
	}
	return interpreterProxy->push(strOop);
}

static int ffiSetLastError(int errCode) {
	return ffiLastError = errCode;
}


/*	Validate if the given oop (an instance of ExternalData) can be passed as a pointer to the given atomic type. */

static int ffiValidateExternalDataAtomicType(int oop, int atomicType) {
    int specType;
    int ptrType;
    int specOop;
    int spec;

	ptrType = interpreterProxy->fetchPointerofObject(1, oop);
	if ((ptrType & 1)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->isPointers(ptrType))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		return interpreterProxy->primitiveFail();
	}
	if ((interpreterProxy->slotSizeOf(ptrType)) < 2) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		return interpreterProxy->primitiveFail();
	}
	specOop = interpreterProxy->fetchPointerofObject(0, ptrType);
	if ((specOop & 1)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->isWords(specOop))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		return interpreterProxy->primitiveFail();
	}
	if ((interpreterProxy->slotSizeOf(specOop)) == 0) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		return interpreterProxy->primitiveFail();
	}
	spec = interpreterProxy->fetchWordofObject(0, specOop);
	if (!(spec & FFIFlagAtomic)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		return interpreterProxy->primitiveFail();
	}
	specType = ((unsigned) (spec & FFIAtomicTypeMask)) >> FFIAtomicTypeShift;
	if (specType != atomicType) {
		if (!((atomicType > FFITypeBool) && (atomicType < FFITypeSingleFloat))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorCoercionFailed;
			return interpreterProxy->primitiveFail();
		}
		if (!((((unsigned) atomicType) >> 1) == (((unsigned) specType) >> 1))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorCoercionFailed;
			return interpreterProxy->primitiveFail();
		}
	}
	return 0;
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

static int isAtomicType(int typeSpec) {
	return typeSpec & FFIFlagAtomic;
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}


/*	IMPORTANT: IF YOU CHANGE THE NAME OF THIS METHOD YOU MUST CHANGE
		Interpreter>>primitiveCalloutToFFI
	TO REFLECT THE CHANGE. */
/*	Perform a function call to a foreign function.
	Only invoked from method containing explicit external call spec. */

EXPORT(int) primitiveCallout(void) {
    int litClass;
    int address;
    int argTypes;
    int nArgs;
    int meth;
    int lit;
    int flags;
    int oop;
    int i;
    int argTypes1;
    int nArgs1;
    int stackIndex;
    int argType;
    int argClass;
    int argSpec;

	ffiLastError = FFIErrorGenericError;

	/* Look if the method is itself a callout function */

	lit = null;
	meth = interpreterProxy->primitiveMethod();
	if (!((interpreterProxy->literalCountOf(meth)) > 0)) {
		return interpreterProxy->primitiveFail();
	}
	lit = interpreterProxy->literalofMethod(0, meth);
	litClass = interpreterProxy->fetchClassOf(lit);
	if (!(interpreterProxy->includesBehaviorThatOf(litClass, interpreterProxy->classExternalFunction()))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorNotFunction;
		return interpreterProxy->primitiveFail();
	}
	address = ffiLoadCalloutAddress(lit);
	if (interpreterProxy->failed()) {
		return 0;
	}
	flags = interpreterProxy->fetchIntegerofObject(1, lit);
	if (interpreterProxy->failed()) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadArgs;
		return interpreterProxy->primitiveFail();
	}

	/* must be array of arg types */

	argTypes = interpreterProxy->fetchPointerofObject(2, lit);
	if (!(interpreterProxy->isArray(argTypes))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadArgs;
		return interpreterProxy->primitiveFail();
	}

	/* must be argumentCount+1 arg types */

	nArgs = interpreterProxy->slotSizeOf(argTypes);
	if (!(nArgs == ((interpreterProxy->methodArgumentCount()) + 1))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadArgs;
		return interpreterProxy->primitiveFail();
	}
	ffiInitialize();
	/* begin ffiCall:WithFlags:AndTypes: */
	if (!(ffiSupportsCallingConvention(flags))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorCallType;
		interpreterProxy->primitiveFail();
		goto l1;
	}
	argTypes1 = argTypes;
	argType = interpreterProxy->fetchPointerofObject(0, argTypes1);
	argSpec = interpreterProxy->fetchPointerofObject(0, argType);
	argClass = interpreterProxy->fetchPointerofObject(1, argType);
	/* begin ffiCheckReturn:With: */
	if (!(argClass == (interpreterProxy->nilObject()))) {
		if (!(interpreterProxy->includesBehaviorThatOf(argClass, interpreterProxy->classExternalStructure()))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorBadReturn;
			interpreterProxy->primitiveFail();
			goto l2;
		}
	}
	ffiRetClass = argClass;
	if ((argSpec & 1)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		goto l2;
	}
	if (!(interpreterProxy->isWords(argSpec))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		goto l2;
	}
	ffiRetSpecSize = interpreterProxy->slotSizeOf(argSpec);
	if (ffiRetSpecSize == 0) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		goto l2;
	}
	ffiRetSpec = ((int) (interpreterProxy->firstIndexableField(argSpec)));
	ffiRetHeader = longAt(ffiRetSpec);
	if (!(ffiRetHeader & FFIFlagAtomic)) {
		if (ffiRetClass == (interpreterProxy->nilObject())) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorBadReturn;
			interpreterProxy->primitiveFail();
			goto l2;
		}
	}
	if (!(ffiCanReturn(((int*) ffiRetSpec), ffiRetSpecSize))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadReturn;
		interpreterProxy->primitiveFail();
	}
l2:	/* end ffiCheckReturn:With: */;
	if (interpreterProxy->failed()) {
		goto l1;
	}
	ffiRetOop = argType;
	nArgs1 = interpreterProxy->methodArgumentCount();
	stackIndex = nArgs1 - 1;
	for (i = 1; i <= nArgs1; i += 1) {
		argType = interpreterProxy->fetchPointerofObject(i, argTypes1);
		argSpec = interpreterProxy->fetchPointerofObject(0, argType);
		argClass = interpreterProxy->fetchPointerofObject(1, argType);
		oop = interpreterProxy->stackValue(stackIndex);
		ffiArgumentSpecClass(oop, argSpec, argClass);
		if (interpreterProxy->failed()) {
			goto l1;
		}
		stackIndex -= 1;
	}
	ffiCalloutToWithFlags(address, flags);
l1:	/* end ffiCall:WithFlags:AndTypes: */;
	ffiCleanup();
	return 0;
}


/*	Perform a function call to a foreign function.
	Only invoked from ExternalFunction>>invokeWithArguments: */

EXPORT(int) primitiveCalloutWithArgs(void) {
    int litClass;
    int address;
    int argTypes;
    int nArgs;
    int lit;
    int flags;
    int argArray;
    int oop;
    int i;
    int argTypes1;
    int argType;
    int argClass;
    int argSpec;

	ffiLastError = FFIErrorGenericError;

	/* Look if the method is itself a callout function */

	lit = null;
	lit = interpreterProxy->stackValue(interpreterProxy->methodArgumentCount());
	litClass = interpreterProxy->fetchClassOf(lit);
	if (!(interpreterProxy->includesBehaviorThatOf(litClass, interpreterProxy->classExternalFunction()))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorNotFunction;
		return interpreterProxy->primitiveFail();
	}
	address = ffiLoadCalloutAddress(lit);
	if (interpreterProxy->failed()) {
		return null;
	}
	flags = interpreterProxy->fetchIntegerofObject(1, lit);
	if (interpreterProxy->failed()) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadArgs;
		return interpreterProxy->primitiveFail();
	}

	/* must be array of arg types */

	argTypes = interpreterProxy->fetchPointerofObject(2, lit);
	if (!(interpreterProxy->isArray(argTypes))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadArgs;
		return interpreterProxy->primitiveFail();
	}
	nArgs = interpreterProxy->slotSizeOf(argTypes);
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadArgs;
		return interpreterProxy->primitiveFail();
	}
	argArray = interpreterProxy->stackValue(0);
	if (!(interpreterProxy->isArray(argArray))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadArgs;
		return interpreterProxy->primitiveFail();
	}
	if (!(nArgs == ((interpreterProxy->slotSizeOf(argArray)) + 1))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadArgs;
		return interpreterProxy->primitiveFail();
	}
	ffiInitialize();
	/* begin ffiCall:WithFlags:Args:AndTypes:OfSize: */
	if (!(ffiSupportsCallingConvention(flags))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorCallType;
		interpreterProxy->primitiveFail();
		goto l1;
	}
	argTypes1 = argTypes;
	argType = interpreterProxy->fetchPointerofObject(0, argTypes1);
	argSpec = interpreterProxy->fetchPointerofObject(0, argType);
	argClass = interpreterProxy->fetchPointerofObject(1, argType);
	/* begin ffiCheckReturn:With: */
	if (!(argClass == (interpreterProxy->nilObject()))) {
		if (!(interpreterProxy->includesBehaviorThatOf(argClass, interpreterProxy->classExternalStructure()))) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorBadReturn;
			interpreterProxy->primitiveFail();
			goto l2;
		}
	}
	ffiRetClass = argClass;
	if ((argSpec & 1)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		goto l2;
	}
	if (!(interpreterProxy->isWords(argSpec))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		goto l2;
	}
	ffiRetSpecSize = interpreterProxy->slotSizeOf(argSpec);
	if (ffiRetSpecSize == 0) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorWrongType;
		interpreterProxy->primitiveFail();
		goto l2;
	}
	ffiRetSpec = ((int) (interpreterProxy->firstIndexableField(argSpec)));
	ffiRetHeader = longAt(ffiRetSpec);
	if (!(ffiRetHeader & FFIFlagAtomic)) {
		if (ffiRetClass == (interpreterProxy->nilObject())) {
			/* begin ffiFail: */
			ffiLastError = FFIErrorBadReturn;
			interpreterProxy->primitiveFail();
			goto l2;
		}
	}
	if (!(ffiCanReturn(((int*) ffiRetSpec), ffiRetSpecSize))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadReturn;
		interpreterProxy->primitiveFail();
	}
l2:	/* end ffiCheckReturn:With: */;
	if (interpreterProxy->failed()) {
		goto l1;
	}
	ffiRetOop = argType;
	for (i = 1; i <= (nArgs - 1); i += 1) {
		argType = interpreterProxy->fetchPointerofObject(i, argTypes1);
		argSpec = interpreterProxy->fetchPointerofObject(0, argType);
		argClass = interpreterProxy->fetchPointerofObject(1, argType);
		oop = interpreterProxy->fetchPointerofObject(i - 1, argArray);
		ffiArgumentSpecClass(oop, argSpec, argClass);
		if (interpreterProxy->failed()) {
			goto l1;
		}
	}
	ffiCalloutToWithFlags(address, flags);
l1:	/* end ffiCall:WithFlags:Args:AndTypes:OfSize: */;
	ffiCleanup();
	return 0;
}


/*	Primitive. Allocate an object on the external heap. */

EXPORT(int) primitiveFFIAllocate(void) {
    int addr;
    int *ptr;
    int oop;
    int byteSize;

	byteSize = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	addr = ffiAlloc(byteSize);
	if (addr == 0) {
		return interpreterProxy->primitiveFail();
	}
	oop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classExternalAddress(), 4);
	ptr = interpreterProxy->firstIndexableField(oop);
	ptr[0] = addr;
	interpreterProxy->pop(2);
	return interpreterProxy->push(oop);
}


/*	Return a (signed or unsigned) n byte integer from the given byte offset. */

EXPORT(int) primitiveFFIDoubleAt(void) {
    int addr;
    int byteOffset;
    double floatValue;
    int rcvr;

	byteOffset = interpreterProxy->stackIntegerValue(0);
	rcvr = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return 0;
	}
	addr = addressOfstartingAtsize(rcvr, byteOffset, 8);
	if (interpreterProxy->failed()) {
		return 0;
	}
	((int*)(&floatValue))[0] = ((int*)addr)[0];
	((int*)(&floatValue))[1] = ((int*)addr)[1];
	interpreterProxy->pop(2);
	return interpreterProxy->pushFloat(floatValue);
}


/*	Return a (signed or unsigned) n byte integer from the given byte offset. */

EXPORT(int) primitiveFFIDoubleAtPut(void) {
    int addr;
    int byteOffset;
    double floatValue;
    int rcvr;
    int floatOop;

	floatOop = interpreterProxy->stackValue(0);
	if ((floatOop & 1)) {
		floatValue = ((double) ((floatOop >> 1)));
	} else {
		floatValue = ((double) (interpreterProxy->floatValueOf(floatOop)));
	}
	byteOffset = interpreterProxy->stackIntegerValue(1);
	rcvr = interpreterProxy->stackObjectValue(2);
	if (interpreterProxy->failed()) {
		return 0;
	}
	addr = addressOfstartingAtsize(rcvr, byteOffset, 8);
	if (interpreterProxy->failed()) {
		return 0;
	}
	((int*)addr)[0] = ((int*)(&floatValue))[0];
	((int*)addr)[1] = ((int*)(&floatValue))[1];
	interpreterProxy->pop(3);
	return interpreterProxy->push(floatOop);
}


/*	Return a (signed or unsigned) n byte integer from the given byte offset. */

EXPORT(int) primitiveFFIFloatAt(void) {
    int addr;
    int byteOffset;
    float floatValue;
    int rcvr;

	byteOffset = interpreterProxy->stackIntegerValue(0);
	rcvr = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return 0;
	}
	addr = addressOfstartingAtsize(rcvr, byteOffset, 4);
	if (interpreterProxy->failed()) {
		return 0;
	}
	((int*)(&floatValue))[0] = ((int*)addr)[0];
	interpreterProxy->pop(2);
	return interpreterProxy->pushFloat(floatValue);
}


/*	Return a (signed or unsigned) n byte integer from the given byte offset. */

EXPORT(int) primitiveFFIFloatAtPut(void) {
    int addr;
    int byteOffset;
    float floatValue;
    int rcvr;
    int floatOop;

	floatOop = interpreterProxy->stackValue(0);
	if ((floatOop & 1)) {
		floatValue = ((float) ((floatOop >> 1)));
	} else {
		floatValue = ((float) (interpreterProxy->floatValueOf(floatOop)));
	}
	byteOffset = interpreterProxy->stackIntegerValue(1);
	rcvr = interpreterProxy->stackObjectValue(2);
	if (interpreterProxy->failed()) {
		return 0;
	}
	addr = addressOfstartingAtsize(rcvr, byteOffset, 4);
	if (interpreterProxy->failed()) {
		return 0;
	}
	((int*)addr)[0] = ((int*)(&floatValue))[0];
	interpreterProxy->pop(3);
	return interpreterProxy->push(floatOop);
}


/*	Primitive. Free the object pointed to on the external heap. */

EXPORT(int) primitiveFFIFree(void) {
    int addr;
    int *ptr;
    int oop;

	oop = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!((interpreterProxy->fetchClassOf(oop)) == (interpreterProxy->classExternalAddress()))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->byteSizeOf(oop)) == 4)) {
		return interpreterProxy->primitiveFail();
	}
	ptr = interpreterProxy->firstIndexableField(oop);

	/* Don't you dare to free Squeak's memory! */

	addr = ptr[0];
	if ((addr == 0) || (interpreterProxy->isInMemory(addr))) {
		return interpreterProxy->primitiveFail();
	}
	ffiFree(addr);
	return ptr[0] = 0;
}


/*	Primitive. Return the error code from a failed call to the foreign function interface. */

EXPORT(int) primitiveFFIGetLastError(void) {
	interpreterProxy->pop(1);
	return interpreterProxy->pushInteger(ffiLastError);
}


/*	Return a (signed or unsigned) n byte integer from the given byte offset. */

EXPORT(int) primitiveFFIIntegerAt(void) {
    int addr;
    int isSigned;
    int byteOffset;
    int value;
    int byteSize;
    int rcvr;
    int mask;

	isSigned = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	byteSize = interpreterProxy->stackIntegerValue(1);
	byteOffset = interpreterProxy->stackIntegerValue(2);
	rcvr = interpreterProxy->stackObjectValue(3);
	if (interpreterProxy->failed()) {
		return 0;
	}
	if (!((byteOffset > 0) && ((byteSize == 1) || ((byteSize == 2) || (byteSize == 4))))) {
		return interpreterProxy->primitiveFail();
	}
	addr = addressOfstartingAtsize(rcvr, byteOffset, byteSize);
	if (interpreterProxy->failed()) {
		return 0;
	}
	if (byteSize < 4) {
		if (byteSize == 1) {
			value = byteAt(addr);
		} else {
			value = *((short int *) addr);
		}
		if (isSigned) {
			mask = 1 << ((byteSize * 8) - 1);
			value = (value & (mask - 1)) - (value & mask);
		}
		value = ((value << 1) | 1);
	} else {
		value = longAt(addr);
		if (isSigned) {
			value = interpreterProxy->signed32BitIntegerFor(value);
		} else {
			value = interpreterProxy->positive32BitIntegerFor(value);
		}
	}
	interpreterProxy->pop(4);
	return interpreterProxy->push(value);
}


/*	Store a (signed or unsigned) n byte integer at the given byte offset. */

EXPORT(int) primitiveFFIIntegerAtPut(void) {
    int addr;
    int max;
    int isSigned;
    int byteOffset;
    int value;
    int valueOop;
    int byteSize;
    int rcvr;

	isSigned = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	byteSize = interpreterProxy->stackIntegerValue(1);
	valueOop = interpreterProxy->stackValue(2);
	byteOffset = interpreterProxy->stackIntegerValue(3);
	rcvr = interpreterProxy->stackObjectValue(4);
	if (interpreterProxy->failed()) {
		return 0;
	}
	if (!((byteOffset > 0) && ((byteSize == 1) || ((byteSize == 2) || (byteSize == 4))))) {
		return interpreterProxy->primitiveFail();
	}
	addr = addressOfstartingAtsize(rcvr, byteOffset, byteSize);
	if (interpreterProxy->failed()) {
		return 0;
	}
	if (isSigned) {
		value = interpreterProxy->signed32BitValueOf(valueOop);
	} else {
		value = interpreterProxy->positive32BitValueOf(valueOop);
	}
	if (interpreterProxy->failed()) {
		return 0;
	}
	if (byteSize < 4) {
		if (isSigned) {
			max = 1 << ((8 * byteSize) - 1);
			if (value >= max) {
				return interpreterProxy->primitiveFail();
			}
			if (value < (0 - max)) {
				return interpreterProxy->primitiveFail();
			}
		} else {
			if (value >= (1 << (8 * byteSize))) {
				return interpreterProxy->primitiveFail();
			}
		}
		if (byteSize == 1) {
			byteAtput(addr, value);
		} else {
			*((short int *) addr) = value;
		}
	} else {
		longAtput(addr, value);
	}
	interpreterProxy->pop(5);
	return interpreterProxy->push(valueOop);
}


/*	Primitive. Force loading the receiver (an instance of ExternalLibrary). */

EXPORT(int) primitiveForceLoad(void) {
    int theClass;
    int moduleHandlePtr;
    int moduleHandle;
    int *ptr;
    int rcvr;
    int ffiModuleName;
    int moduleLength;

	ffiLastError = FFIErrorGenericError;
	if (!((interpreterProxy->methodArgumentCount()) == 0)) {
		return interpreterProxy->primitiveFail();
	}
	rcvr = interpreterProxy->stackValue(0);
	theClass = interpreterProxy->fetchClassOf(rcvr);
	if (!(interpreterProxy->includesBehaviorThatOf(theClass, interpreterProxy->classExternalLibrary()))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadExternalLibrary;
		return interpreterProxy->primitiveFail();
	}
	moduleHandlePtr = interpreterProxy->fetchPointerofObject(0, rcvr);
	/* begin ffiContentsOfHandle:errCode: */
	if ((moduleHandlePtr & 1)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadExternalLibrary;
		moduleHandle = interpreterProxy->primitiveFail();
		goto l1;
	}
	if (!(interpreterProxy->isBytes(moduleHandlePtr))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadExternalLibrary;
		moduleHandle = interpreterProxy->primitiveFail();
		goto l1;
	}
	if (!((interpreterProxy->byteSizeOf(moduleHandlePtr)) == 4)) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadExternalLibrary;
		moduleHandle = interpreterProxy->primitiveFail();
		goto l1;
	}
	moduleHandle = interpreterProxy->fetchWordofObject(0, moduleHandlePtr);
l1:	/* end ffiContentsOfHandle:errCode: */;
	if (interpreterProxy->failed()) {
		return 0;
	}
	ffiModuleName = interpreterProxy->fetchPointerofObject(1, rcvr);
	if (!(interpreterProxy->isBytes(ffiModuleName))) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorBadExternalLibrary;
		return interpreterProxy->primitiveFail();
	}
	moduleLength = interpreterProxy->byteSizeOf(ffiModuleName);
	moduleHandle = interpreterProxy->ioLoadModuleOfLength(((int) (interpreterProxy->firstIndexableField(ffiModuleName))), moduleLength);
	if (interpreterProxy->failed()) {
		/* begin ffiFail: */
		ffiLastError = FFIErrorModuleNotFound;
		return interpreterProxy->primitiveFail();
	}
	ptr = interpreterProxy->firstIndexableField(moduleHandlePtr);
	ptr[0] = moduleHandle;
	return 0;
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


void* SqueakFFIPrims_exports[][3] = {
	{"SqueakFFIPrims", "primitiveFFIAllocate", (void*)primitiveFFIAllocate},
	{"SqueakFFIPrims", "primitiveFFIFree", (void*)primitiveFFIFree},
	{"SqueakFFIPrims", "primitiveFFIFloatAt", (void*)primitiveFFIFloatAt},
	{"SqueakFFIPrims", "primitiveFFIFloatAtPut", (void*)primitiveFFIFloatAtPut},
	{"SqueakFFIPrims", "primitiveCalloutWithArgs", (void*)primitiveCalloutWithArgs},
	{"SqueakFFIPrims", "primitiveCallout", (void*)primitiveCallout},
	{"SqueakFFIPrims", "primitiveFFIDoubleAtPut", (void*)primitiveFFIDoubleAtPut},
	{"SqueakFFIPrims", "primitiveFFIDoubleAt", (void*)primitiveFFIDoubleAt},
	{"SqueakFFIPrims", "primitiveFFIIntegerAtPut", (void*)primitiveFFIIntegerAtPut},
	{"SqueakFFIPrims", "primitiveFFIGetLastError", (void*)primitiveFFIGetLastError},
	{"SqueakFFIPrims", "getModuleName", (void*)getModuleName},
	{"SqueakFFIPrims", "primitiveForceLoad", (void*)primitiveForceLoad},
	{"SqueakFFIPrims", "primitiveFFIIntegerAt", (void*)primitiveFFIIntegerAt},
	{"SqueakFFIPrims", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

