#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "sqVirtualMachine.h"

/*** Function prototypes ***/

/* InterpreterProxy methodsFor: 'stack access' */
int pop(int nItems);
int popthenPush(int nItems, int oop);
int push(int object);
int pushBool(int trueOrFalse);
int pushFloat(double f);
int pushInteger(int integerValue);
double stackFloatValue(int offset);
int stackIntegerValue(int offset);
int stackObjectValue(int offset);
int stackValue(int offset);

/*** variables ***/

extern int (*compilerHooks[])();
extern int setCompilerInitialized(int flagValue);

/* InterpreterProxy methodsFor: 'object access' */
int argumentCountOf(int methodPointer);
void * arrayValueOf(int oop);
int byteSizeOf(int oop);
void * fetchArrayofObject(int fieldIndex, int objectPointer);
int fetchClassOf(int oop);
double fetchFloatofObject(int fieldIndex, int objectPointer);
int fetchIntegerofObject(int fieldIndex, int objectPointer);
int fetchPointerofObject(int index, int oop);
int fetchWordofObject(int fieldIndex, int oop);
void * firstFixedField(int oop);
void * firstIndexableField(int oop);
int literalofMethod(int offset, int methodPointer);
int literalCountOf(int methodPointer);
int methodArgumentCount(void);
int methodPrimitiveIndex(void);
int primitiveMethod(void);
int primitiveIndexOf(int methodPointer);
int sizeOfSTArrayFromCPrimitive(void *cPtr);
int slotSizeOf(int oop);
int stObjectat(int array, int index);
int stObjectatput(int array, int index, int value);
int stSizeOf(int oop);
int storeIntegerofObjectwithValue(int index, int oop, int integer);
int storePointerofObjectwithValue(int index, int oop, int valuePointer);


/* InterpreterProxy methodsFor: 'testing' */
int isKindOf(int oop, char *aString);
int isMemberOf(int oop, char *aString);
int isBytes(int oop);
int isFloatObject(int oop);
int isIndexable(int oop);
int isIntegerObject(int objectPointer);
int isIntegerValue(int intValue);
int isPointers(int oop);
int isWeak(int oop);
int isWords(int oop);
int isWordsOrBytes(int oop);
int includesBehaviorThatOf(int aClass, int aSuperClass);
int isArray(int oop);

/* InterpreterProxy methodsFor: 'converting' */
int booleanValueOf(int obj);
int checkedIntegerValueOf(int intOop);
int floatObjectOf(double aFloat);
double floatValueOf(int oop);
int integerObjectOf(int value);
int integerValueOf(int oop);
int positive32BitIntegerFor(int integerValue);
int positive32BitValueOf(int oop);
int signed32BitIntegerFor(int integerValue);
int signed32BitValueOf(int oop);
int positive64BitIntegerFor(squeakInt64 integerValue);
squeakInt64 positive64BitValueOf(int oop);
int signed64BitIntegerFor(squeakInt64 integerValue);
squeakInt64 signed64BitValueOf(int oop);

/* InterpreterProxy methodsFor: 'special objects' */
int characterTable(void);
int displayObject(void);
int falseObject(void);
int nilObject(void);
int trueObject(void);


/* InterpreterProxy methodsFor: 'special classes' */
int classArray(void);
int classBitmap(void);
int classByteArray(void);
int classCharacter(void);
int classFloat(void);
int classLargePositiveInteger(void);
int classLargeNegativeInteger(void);
int classPoint(void);
int classSemaphore(void);
int classSmallInteger(void);
int classString(void);


/* InterpreterProxy methodsFor: 'instance creation' */
int clone(int oop);
int instantiateClassindexableSize(int classPointer, int size);
int makePointwithxValueyValue(int xValue, int yValue);
int popRemappableOop(void);
int pushRemappableOop(int oop);


/* InterpreterProxy methodsFor: 'other' */
int becomewith(int array1, int array2);
int byteSwapped(int w);
int failed(void);
int fullDisplayUpdate(void);
int fullGC(void);
int incrementalGC(void);
int primitiveFail(void);
int showDisplayBitsLeftTopRightBottom(int aForm, int l, int t, int r, int b);
int signalSemaphoreWithIndex(int semaIndex);
int success(int aBoolean);
int superclassOf(int classPointer);
int ioMicroMSecs(void);
int forceInterruptCheck(void);

/* InterpreterProxy methodsFor: 'BitBlt support' */
int loadBitBltFrom(int bbOop);
int copyBits(void);
int copyBitsFromtoat(int leftX, int rightX, int yValue);

/* InterpreterProxy methodsFor: 'FFI support' */
int classExternalAddress(void);
int classExternalData(void);
int classExternalFunction(void);
int classExternalLibrary(void);
int classExternalStructure(void);
int ioLoadModuleOfLength(int moduleNameIndex, int moduleNameLength);
int ioLoadSymbolOfLengthFromModule(int functionNameIndex, int functionNameLength, int moduleHandle);
int isInMemory(int address);

int ioLoadFunctionFrom(char *fnName, char *modName);

struct VirtualMachine *VM = NULL;

static int majorVersion(void) {
	return VM_PROXY_MAJOR;
}

static int minorVersion(void) {
	return VM_PROXY_MINOR;
}

static CompilerHook *compilerHookVector(void) {
  return compilerHooks;
}


struct VirtualMachine* sqGetInterpreterProxy(void)
{
	if(VM) return VM;
	VM = (struct VirtualMachine *) calloc(1, sizeof(VirtualMachine));
	/* Initialize Function pointers */
	VM->majorVersion = majorVersion;
	VM->minorVersion = minorVersion;


	/* InterpreterProxy methodsFor: 'stack access' */
	VM->pop = pop;
	VM->popthenPush = popthenPush;
	VM->push = push;
	VM->pushBool = pushBool;
	VM->pushFloat = pushFloat;
	VM->pushInteger = pushInteger;
	VM->stackFloatValue = stackFloatValue;
	VM->stackIntegerValue = stackIntegerValue;
	VM->stackObjectValue = stackObjectValue;
	VM->stackValue = stackValue;
	

	/* InterpreterProxy methodsFor: 'object access' */
	VM->argumentCountOf = argumentCountOf;
	VM->arrayValueOf = arrayValueOf;
	VM->byteSizeOf = byteSizeOf;
	VM->fetchArrayofObject = fetchArrayofObject;
	VM->fetchClassOf = fetchClassOf;
	VM->fetchFloatofObject = fetchFloatofObject;
	VM->fetchIntegerofObject = fetchIntegerofObject;
	VM->fetchPointerofObject = fetchPointerofObject;
	VM->fetchWordofObject = fetchWordofObject;
	VM->firstFixedField = firstFixedField;
	VM->firstIndexableField = firstIndexableField;
	VM->literalofMethod = literalofMethod;
	VM->literalCountOf = literalCountOf;
	VM->methodArgumentCount = methodArgumentCount;
	VM->methodPrimitiveIndex = methodPrimitiveIndex;
	VM->primitiveIndexOf = primitiveIndexOf;
	VM->primitiveMethod = primitiveMethod;
	VM->sizeOfSTArrayFromCPrimitive = sizeOfSTArrayFromCPrimitive;
	VM->slotSizeOf = slotSizeOf;
	VM->stObjectat = stObjectat;
	VM->stObjectatput = stObjectatput;
	VM->stSizeOf = stSizeOf;
	VM->storeIntegerofObjectwithValue = storeIntegerofObjectwithValue;
	VM->storePointerofObjectwithValue = storePointerofObjectwithValue;
	

	/* InterpreterProxy methodsFor: 'testing' */
	VM->isKindOf = isKindOf;
	VM->isMemberOf = isMemberOf;
	VM->isBytes = isBytes;
	VM->isFloatObject = isFloatObject;
	VM->isIndexable = isIndexable;
	VM->isIntegerObject = isIntegerObject;
	VM->isIntegerValue = isIntegerValue;
	VM->isPointers = isPointers;
	VM->isWeak = isWeak;
	VM->isWords = isWords;
	VM->isWordsOrBytes = isWordsOrBytes;

	/* InterpreterProxy methodsFor: 'converting' */
	VM->booleanValueOf = booleanValueOf;
	VM->checkedIntegerValueOf = checkedIntegerValueOf;
	VM->floatObjectOf = floatObjectOf;
	VM->floatValueOf = floatValueOf;
	VM->integerObjectOf = integerObjectOf;
	VM->integerValueOf = integerValueOf;
	VM->positive32BitIntegerFor = positive32BitIntegerFor;
	VM->positive32BitValueOf = positive32BitValueOf;

	/* InterpreterProxy methodsFor: 'special objects' */
	VM->characterTable = characterTable;
	VM->displayObject = displayObject;
	VM->falseObject = falseObject;
	VM->nilObject = nilObject;
	VM->trueObject = trueObject;
	

	/* InterpreterProxy methodsFor: 'special classes' */
	VM->classArray = classArray;
	VM->classBitmap = classBitmap;
	VM->classByteArray = classByteArray;
	VM->classCharacter = classCharacter;
	VM->classFloat = classFloat;
	VM->classLargePositiveInteger = classLargePositiveInteger;
	VM->classPoint = classPoint;
	VM->classSemaphore = classSemaphore;
	VM->classSmallInteger = classSmallInteger;
	VM->classString = classString;
	

	/* InterpreterProxy methodsFor: 'instance creation' */
	VM->clone = clone;
	VM->instantiateClassindexableSize = instantiateClassindexableSize;
	VM->makePointwithxValueyValue = makePointwithxValueyValue;
	VM->popRemappableOop = popRemappableOop;
	VM->pushRemappableOop = pushRemappableOop;
	

	/* InterpreterProxy methodsFor: 'other' */
	VM->becomewith = becomewith;
	VM->byteSwapped = byteSwapped;
	VM->failed = failed;
	VM->fullDisplayUpdate = fullDisplayUpdate;
	VM->fullGC = fullGC;
	VM->incrementalGC = incrementalGC;
	VM->primitiveFail = primitiveFail;
	VM->showDisplayBitsLeftTopRightBottom = showDisplayBitsLeftTopRightBottom;
	VM->signalSemaphoreWithIndex = signalSemaphoreWithIndex;
	VM->success = success;
	VM->superclassOf = superclassOf;

	VM->compilerHookVector= compilerHookVector;
	VM->setCompilerInitialized= setCompilerInitialized;

#if VM_PROXY_MINOR > 1
	/* InterpreterProxy methodsFor: 'BitBlt support' */
	VM->loadBitBltFrom = loadBitBltFrom;
	VM->copyBits = copyBits;
	VM->copyBitsFromtoat = copyBitsFromtoat;
#endif

#if VM_PROXY_MINOR > 2
	/* InterpreterProxy methodsFor: 'FFI support' */
	VM->classExternalAddress = classExternalAddress;
	VM->classExternalData = classExternalData;
	VM->classExternalFunction = classExternalFunction;
	VM->classExternalLibrary = classExternalLibrary;
	VM->classExternalStructure = classExternalStructure;
	VM->ioLoadModuleOfLength = ioLoadModuleOfLength;
	VM->ioLoadSymbolOfLengthFromModule = ioLoadSymbolOfLengthFromModule;
	VM->isInMemory = isInMemory;
	VM->signed32BitIntegerFor = signed32BitIntegerFor;
	VM->signed32BitValueOf = signed32BitValueOf;
	VM->includesBehaviorThatOf = includesBehaviorThatOf;
	VM->classLargeNegativeInteger = classLargeNegativeInteger;
#endif

#if VM_PROXY_MINOR > 3
	VM->ioLoadFunctionFrom = ioLoadFunctionFrom;
	VM->ioMicroMSecs = ioMicroMSecs;
#endif

#if VM_PROXY_MINOR > 4
	VM->positive64BitIntegerFor = positive64BitIntegerFor;
	VM->positive64BitValueOf = positive64BitValueOf;
	VM->signed64BitIntegerFor = signed64BitIntegerFor;
	VM->signed64BitValueOf = signed64BitValueOf;
#endif

#if VM_PROXY_MINOR > 5
	VM->isArray = isArray;
	VM->forceInterruptCheck = forceInterruptCheck;
#endif
	return VM;
}

