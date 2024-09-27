#ifndef _SqueakVM_H
#define _SqueakVM_H

/* We expect interp.h to define VM_PROXY_MAJOR & VM_PROXY_MINOR, and other
 * defines such as STACKVM, appropriately for the VM generated with it.
 */
#include "interp.h"

#if SPURVM
# define VM_VERSION "5.0"
#else
# define VM_VERSION "4.5"
#endif

#ifndef VM_PROXY_MAJOR
/* Increment the following number if you change the order of
   functions listed or if you remove functions */
# define VM_PROXY_MAJOR 1
#endif

#ifndef VM_PROXY_MINOR
/* Increment the following number if you add functions at the end */
# if SPURVM
#	define VM_PROXY_MINOR 13
# else
#	define VM_PROXY_MINOR 12
# endif
#endif

#include "sqMemoryAccess.h"

#if VM_PROXY_MINOR > 8
// Primitive error codes; see interp.h
# define PrimNoErr 0

/* VMCallbackContext opaque type avoids all including setjmp.h & vmCallback.h */
typedef struct _VMCallbackContext *vmccp;
#endif

typedef sqInt (*CompilerHook)(void);

struct VirtualMachine* sqGetInterpreterProxy(void);

typedef struct VirtualMachine {
	sqInt (*minorVersion)(void);
	sqInt (*majorVersion)(void);

	/* InterpreterProxy methodsFor: 'stack access' */

	sqInt  (*pop)(sqInt nItems);
	sqInt  (*popthenPush)(sqInt nItems, sqInt oop);
	sqInt  (*push)(sqInt object);
	sqInt  (*pushBool)(sqInt trueOrFalse);
	sqInt  (*pushFloat)(double f);
	sqInt  (*pushInteger)(sqInt integerValue);
	double (*stackFloatValue)(sqInt offset);
	sqInt  (*stackIntegerValue)(sqInt offset);
	sqInt  (*stackObjectValue)(sqInt offset);
	sqInt  (*stackValue)(sqInt offset);

	/* InterpreterProxy methodsFor: 'object access' */

	sqInt  (*argumentCountOf)(sqInt methodPointer);
	void  *(*arrayValueOf)(sqInt oop);
	sqInt  (*byteSizeOf)(sqInt oop);
	void  *(*fetchArrayofObject)(sqInt fieldIndex, sqInt objectPointer);
	sqInt  (*fetchClassOf)(sqInt oop);
	double (*fetchFloatofObject)(sqInt fieldIndex, sqInt objectPointer);
	sqInt  (*fetchIntegerofObject)(sqInt fieldIndex, sqInt objectPointer);
	sqInt  (*fetchPointerofObject)(sqInt fieldIndex, sqInt oop);
#if OLD_FOR_REFERENCE
/*  sqInt  (*fetchWordofObject)(sqInt fieldFieldIndex, sqInt oop); *
 * has been rescinded as of VMMaker 3.8 and the 64bitclean VM      *
 * work. To support old plugins we keep a valid function in        *
 * the same location in the VM struct but rename it to             *
 * something utterly horrible to scare off the natives. A new      *
 * equivalent but 64 bit valid function is added as                *
 * 'fetchLong32OfObject'                                           */
	sqInt  (*obsoleteDontUseThisFetchWordofObject)(sqInt fieldFieldIndex, sqInt oop);
#else /* since there is no legacy plugin problem back to 3.8 we repurpose... */
	void   (*error)(const char *);
#endif
	void  *(*firstFixedField)(sqInt oop);
	void  *(*firstIndexableField)(sqInt oop);
	sqInt  (*literalofMethod)(sqInt offset, sqInt methodPointer);
	sqInt  (*literalCountOf)(sqInt methodPointer);
	sqInt  (*methodArgumentCount)(void);
	sqInt  (*methodPrimitiveIndex)(void);
	sqInt  (*primitiveIndexOf)(sqInt methodPointer);
	sqInt  (*sizeOfSTArrayFromCPrimitive)(void *cPtr);
	sqInt  (*slotSizeOf)(sqInt oop);
	sqInt  (*stObjectat)(sqInt array, sqInt fieldIndex);
	sqInt  (*stObjectatput)(sqInt array, sqInt fieldIndex, sqInt value);
	sqInt  (*stSizeOf)(sqInt oop);
	sqInt  (*storeIntegerofObjectwithValue)(sqInt fieldIndex, sqInt oop, sqInt integer);
	sqInt  (*storePointerofObjectwithValue)(sqInt fieldIndex, sqInt oop, sqInt valuePointer);

	/* InterpreterProxy methodsFor: 'testing' */

	sqInt (*isKindOf)(sqInt oop, char *aString);
	sqInt (*isMemberOf)(sqInt oop, char *aString);
	sqInt (*isBytes)(sqInt oop);
	sqInt (*isFloatObject)(sqInt oop);
	sqInt (*isIndexable)(sqInt oop);
	sqInt (*isIntegerObject)(sqInt oop);
	sqInt (*isIntegerValue)(sqInt intValue);
	sqInt (*isPointers)(sqInt oop);
	sqInt (*isWeak)(sqInt oop);
	sqInt (*isWords)(sqInt oop);
	sqInt (*isWordsOrBytes)(sqInt oop);

	/* InterpreterProxy methodsFor: 'converting' */

	sqInt  (*booleanValueOf)(sqInt obj);
	sqInt  (*checkedIntegerValueOf)(sqInt intOop);
	sqInt  (*floatObjectOf)(double aFloat);
	double (*floatValueOf)(sqInt oop);
	sqInt  (*integerObjectOf)(sqInt value);
	sqInt  (*integerValueOf)(sqInt oop);
	sqInt  (*positive32BitIntegerFor)(unsigned int integerValue);
	usqInt (*positive32BitValueOf)(sqInt oop);

	/* InterpreterProxy methodsFor: 'special objects' */

	sqInt (*characterTable)(void);
	sqInt (*displayObject)(void);
	sqInt (*falseObject)(void);
	sqInt (*nilObject)(void);
	sqInt (*trueObject)(void);

	/* InterpreterProxy methodsFor: 'special classes' */

	sqInt (*classArray)(void);
	sqInt (*classBitmap)(void);
	sqInt (*classByteArray)(void);
	sqInt (*classCharacter)(void);
	sqInt (*classFloat)(void);
	sqInt (*classLargePositiveInteger)(void);
	sqInt (*classPoint)(void);
	sqInt (*classSemaphore)(void);
	sqInt (*classSmallInteger)(void);
	sqInt (*classString)(void);

	/* InterpreterProxy methodsFor: 'instance creation' */

	sqInt (*cloneObject)(sqInt oop);
	sqInt (*instantiateClassindexableSize)(sqInt classPointer, sqInt size);
	sqInt (*makePointwithxValueyValue)(sqInt xValue, sqInt yValue);
	sqInt (*popRemappableOop)(void);
	sqInt (*pushRemappableOop)(sqInt oop);

	/* InterpreterProxy methodsFor: 'other' */

	sqInt (*becomewith)(sqInt array1, sqInt array2);
	sqInt (*byteSwapped)(sqInt w);
	sqInt (*failed)(void);
	sqInt (*fullDisplayUpdate)(void);
	void (*fullGC)(void);
	void (*incrementalGC)(void);
	sqInt (*primitiveFail)(void);
	sqInt (*showDisplayBitsLeftTopRightBottom)(sqInt aForm, sqInt l, sqInt t, sqInt r, sqInt b);
	sqInt (*signalSemaphoreWithIndex)(sqInt semaIndex);
	sqInt (*success)(sqInt aBoolean);
	sqInt (*superclassOf)(sqInt classPointer);

# if VM_PROXY_MINOR > 13
	/* Reuse these now that Cog provides a production JIT. */
	sqInt (*statNumGCs)(void);
	sqInt (*stringForCString)(char *nullTerminatedCString);
# else
	/* InterpreterProxy methodsFor: 'compiler' */

	CompilerHook *(*compilerHookVector)(void);
	sqInt         (*setCompilerInitialized)(sqInt initFlag);
# endif

#if VM_PROXY_MINOR > 1

	/* InterpreterProxy methodsFor: 'BitBlt support' */

	sqInt (*loadBitBltFrom)(sqInt bbOop);
	sqInt (*copyBits)(void);
	sqInt (*copyBitsFromtoat)(sqInt leftX, sqInt rightX, sqInt yValue);

#endif

#if VM_PROXY_MINOR > 2

	sqInt (*classLargeNegativeInteger)(void);
	sqInt (*signed32BitIntegerFor)(sqInt integerValue);
	int   (*signed32BitValueOf)(sqInt oop);
	sqInt (*includesBehaviorThatOf)(sqInt aClass, sqInt aSuperClass);
	sqInt (*primitiveMethod)(void);

	/* InterpreterProxy methodsFor: 'FFI support' */

	sqInt (*classExternalAddress)(void);
	sqInt (*classExternalData)(void);
	sqInt (*classExternalFunction)(void);
	sqInt (*classExternalLibrary)(void);
	sqInt (*classExternalStructure)(void);
	void *(*ioLoadModuleOfLength)(sqInt modIndex, sqInt modLength);
	void *(*ioLoadSymbolOfLengthFromModule)(sqInt fnIndex, sqInt fnLength, void *handle);
	sqInt (*isInMemory)(sqInt address);

#endif

#if VM_PROXY_MINOR > 3

	void *(*ioLoadFunctionFrom)(char *fnName, char *modName);
	unsigned int (*ioMicroMSecs)(void);

#endif

#if VM_PROXY_MINOR > 4

#  if !defined(sqLong)
#   if _MSC_VER
#     define sqLong __int64
#     define usqLong unsigned __int64
#   else
#     define sqLong long long
#     define usqLong unsigned long long
#   endif
#  endif

	sqInt  (*positive64BitIntegerFor)(usqLong integerValue);
	usqLong(*positive64BitValueOf)(sqInt oop);
	sqInt  (*signed64BitIntegerFor)(sqLong integerValue);
	sqLong (*signed64BitValueOf)(sqInt oop);

#endif

#if VM_PROXY_MINOR > 5
	sqInt (*isArray)(sqInt oop);
	void (*forceInterruptCheck)(void);
#endif

#if VM_PROXY_MINOR > 6
	sqInt  (*fetchLong32ofObject)(sqInt fieldFieldIndex, sqInt oop);
	sqInt  (*getThisSessionID)(void);
	sqInt  (*ioFilenamefromStringofLengthresolveAliases)(char* aCharBuffer, char* filenameIndex, sqInt filenameLength, sqInt resolveFlag);
	sqInt  (*vmEndianness)(void);	
#endif

#if VM_PROXY_MINOR > 7
  /* New methods for proxy version 1.8 */

  /* callbackEnter: Re-enter the interpreter loop for a callback.
     Arguments:
       callbackID: Pointer to a location receiving the callback ID
                   used in callbackLeave
     Returns: True if successful, false otherwise */
  sqInt (*callbackEnter)(sqInt *callbackID);

#if OLD_FOR_REFERENCE
  /* N.B. callbackLeave is only ever called from the interpreter.  Further, it
   * and callbackEnter are obsoleted by Alien/FFI callbacks that are simpler
   * and faster.
   */
  /* callbackLeave: Leave the interpreter from a previous callback
     Arguments:
       callbackID: The ID of the callback received from callbackEnter()
     Returns: True if succcessful, false otherwise. */
  sqInt (*callbackLeave)(sqInt  callbackID);
#else
  sqInt  (*primitiveFailForwithSecondary)(sqInt failCode, sqLong secondaryCode);
#endif

  /* addGCRoot: Add a variable location to the garbage collector.
     The contents of the variable location will be updated accordingly.
     Arguments:
       varLoc: Pointer to the variable location
     Returns: True if successful, false otherwise. */
  sqInt (*addGCRoot)(sqInt *varLoc);

  /* removeGCRoot: Remove a variable location from the garbage collector.
     Arguments:
       varLoc: Pointer to the variable location
     Returns: True if successful, false otherwise.
  */
  sqInt (*removeGCRoot)(sqInt *varLoc);
#endif

#if VM_PROXY_MINOR > 8
	/* See interp.h and above for standard error codes. */
	sqInt  (*primitiveFailFor)(sqInt code);
	void  *(*setInterruptCheckChain)(void (*aFunction)(void));
	sqInt  (*classAlien)(void);
	sqInt  (*classUnsafeAlien)(void);
# if OLD_FOR_REFERENCE /* slot repurposed for storeLong32ofObjectwithValue */
	sqInt  (*sendInvokeCallbackStackRegistersJmpbuf)(sqInt thunkPtrAsInt, sqInt stackPtrAsInt, sqInt regsPtrAsInt, sqInt jmpBufPtrAsInt);
# else
	usqInt  (*storeLong32ofObjectwithValue)(sqInt index, sqInt oop, usqInt); 
# endif
	sqInt  (*reestablishContextPriorToCallback)(sqInt callbackContext);
	sqInt *(*getStackPointer)(void);
	sqInt  (*isOopImmutable)(sqInt oop);
	sqInt  (*isOopMutable)(sqInt oop);
#endif

#if VM_PROXY_MINOR > 9
# if VM_PROXY_MINOR > 13 /* OS Errors available in primitives; easy return forms */
  sqInt  (*methodReturnBool)(sqInt);
  sqInt  (*methodReturnFloat)(double);
  sqInt  (*methodReturnInteger)(sqInt);
  sqInt  (*methodReturnString)(const char *);
#	define returnSelf() methodReturnValue(0)
# else
  sqInt  (*methodArg)  (sqInt index); /* These ended up never being used. */
  sqInt  (*objectArg)  (sqInt index);
  sqInt  (*integerArg) (sqInt index);
  double (*floatArg)   (sqInt index);
# endif
  sqInt  (*methodReturnValue) (sqInt oop);
  sqInt  (*topRemappableOop)  (void);
#endif

#if VM_PROXY_MINOR > 10
  void *(*disownVM)(sqInt flags);
  sqInt	(*ownVM)(void *vmThreadHandle);
  void  (*addHighPriorityTickee)(void (*ticker)(void), unsigned periodms);
  void  (*addSynchronousTickee)(void (*ticker)(void), unsigned periodms, unsigned roundms);
  usqLong (*utcMicroseconds)(void);
  void (*tenuringIncrementalGC)(void);
  sqInt (*isYoung) (sqInt anOop);
  sqInt (*isKindOfClass)(sqInt oop, sqInt aClass);
  sqInt (*primitiveErrorTable)(void);
  sqInt (*primitiveFailureCode)(void);
  sqInt (*instanceSizeOf)(sqInt aClass);
#endif

#if VM_PROXY_MINOR > 11
/* VMCallbackContext opaque type avoids all including setjmp.h & vmCallback.h */
  sqInt (*sendInvokeCallbackContext)(vmccp);
  sqInt (*returnAsThroughCallbackContext)(sqInt, vmccp, sqInt);
  sqIntptr_t  (*signedMachineIntegerValueOf)(sqInt);
  sqIntptr_t  (*stackSignedMachineIntegerValue)(sqInt);
  usqIntptr_t (*positiveMachineIntegerValueOf)(sqInt);
  usqIntptr_t (*stackPositiveMachineIntegerValue)(sqInt);
  sqInt	 (*getInterruptPending)(void);
  char  *(*cStringOrNullFor)(sqInt);
  void  *(*startOfAlienData)(sqInt);
  usqInt (*sizeOfAlienData)(sqInt);
  sqInt  (*signalNoResume)(sqInt);
#endif

#if VM_PROXY_MINOR > 12 /* Spur */
  sqInt (*isImmediate)(sqInt objOop);
  sqInt (*characterObjectOf)(int charCode);
  sqInt (*characterValueOf)(sqInt objOop);
  sqInt (*isCharacterObject)(sqInt objOop);
  sqInt (*isCharacterValue)(int charCode);
  sqInt (*isPinned)(sqInt objOop);
  sqInt (*pinObject)(sqInt objOop);
  sqInt (*unpinObject)(sqInt objOop);
#endif

#if VM_PROXY_MINOR > 13 /* OS Errors available in primitives; easy return forms (see above) */
  sqInt  (*primitiveFailForOSError)(sqLong osErrorCode);
  sqInt  (*methodReturnReceiver)(void);
  sqInt  (*primitiveFailForFFIExceptionat)(usqLong exceptionCode, usqInt pc);
#endif

#if VM_PROXY_MINOR > 14 /* SmartSyntaxPlugin validation rewrite support */
  sqInt  (*isBooleanObject)(sqInt oop);
  sqInt  (*isPositiveMachineIntegerObject)(sqInt);
#endif
#if VM_PROXY_MINOR > 15 /* Spur integer and float array classes */
  sqInt (*classDoubleByteArray)(void);
  sqInt (*classWordArray)(void);
  sqInt (*classDoubleWordArray)(void);
  sqInt (*classFloat32Array)(void);
  sqInt (*classFloat64Array)(void);
#endif
#if VM_PROXY_MINOR > 16 /* Spur isShorts, isLong64s testing, hash etc */
  sqInt (*isShorts)(sqInt oop);
  sqInt (*isLong64s)(sqInt oop);
  sqInt (*identityHashOf)(sqInt oop);
  sqInt (*isWordsOrShorts)(sqInt oop);	/* for SoundPlugin et al */
  sqInt (*bytesPerElement)(sqInt oop);	/* for SocketPugin et al */
  sqInt (*fileTimesInUTC)(void);		/* for FilePlugin et al */
#endif
} VirtualMachine;

# if (defined(SQUEAK_BUILTIN_PLUGIN) || defined(FOR_SVM_C)) \
	&& !defined(SQ_USE_GLOBAL_STRUCT) // Prevent the interpereter seeing these
/*** Function prototypes ***/

/* InterpreterProxy methodsFor: 'stack access' */
sqInt  pop(sqInt nItems);
sqInt  popthenPush(sqInt nItems, sqInt oop);
sqInt  push(sqInt object);
sqInt  pushBool(sqInt trueOrFalse);
sqInt  pushFloat(double f);
sqInt  pushInteger(sqInt integerValue);
double stackFloatValue(sqInt offset);
sqInt  stackIntegerValue(sqInt offset);
sqInt  stackObjectValue(sqInt offset);
sqInt  stackValue(sqInt offset);

/*** variables ***/

/* InterpreterProxy methodsFor: 'object access' */
sqInt  argumentCountOf(sqInt methodPointer);
void  *arrayValueOf(sqInt oop);
sqInt  byteSizeOf(sqInt oop);
void  *fetchArrayofObject(sqInt fieldIndex, sqInt objectPointer);
sqInt  fetchClassOf(sqInt oop);
double fetchFloatofObject(sqInt fieldIndex, sqInt objectPointer);
sqInt  fetchIntegerofObject(sqInt fieldIndex, sqInt objectPointer);
sqInt  fetchPointerofObject(sqInt index, sqInt oop);
#if OLD_FOR_REFERENCE /* slot repurposed for error */
/* sqInt  fetchWordofObject(sqInt fieldIndex, sqInt oop);     *
 * has been rescinded as of VMMaker 3.8 and the 64bitclean VM *
 * work. To support old plugins we keep a valid function in   *
 * the same location in the VM struct but rename it to        *
 * something utterly horrible to scare off the natives. A new *
 * equivalent but 64 bit valid function is added as           *
 * 'fetchLong32OfObject'                                      */
sqInt  obsoleteDontUseThisFetchWordofObject(sqInt index, sqInt oop);
#endif
sqInt  fetchLong32ofObject(sqInt index, sqInt oop); 
void  *firstFixedField(sqInt oop);
void  *firstIndexableField(sqInt oop);
sqInt  literalofMethod(sqInt offset, sqInt methodPointer);
sqInt  literalCountOf(sqInt methodPointer);
sqInt  methodArgumentCount(void);
sqInt  methodPrimitiveIndex(void);
sqInt  primitiveMethod(void);
sqInt  primitiveIndexOf(sqInt methodPointer);
sqInt  sizeOfSTArrayFromCPrimitive(void *cPtr);
sqInt  slotSizeOf(sqInt oop);
sqInt  stObjectat(sqInt array, sqInt index);
sqInt  stObjectatput(sqInt array, sqInt index, sqInt value);
sqInt  stSizeOf(sqInt oop);
sqInt  storeIntegerofObjectwithValue(sqInt index, sqInt oop, sqInt integer);
sqInt  storePointerofObjectwithValue(sqInt index, sqInt oop, sqInt valuePointer);


/* InterpreterProxy methodsFor: 'testing' */
sqInt isKindOf(sqInt oop, char *aString);
sqInt isMemberOf(sqInt oop, char *aString);
sqInt isBytes(sqInt oop);
sqInt isFloatObject(sqInt oop);
sqInt isIndexable(sqInt oop);
sqInt isIntegerObject(sqInt oop);
sqInt isIntegerValue(sqInt intValue);
sqInt isPointers(sqInt oop);
sqInt isWeak(sqInt oop);
sqInt isWords(sqInt oop);
sqInt isWordsOrBytes(sqInt oop);
sqInt includesBehaviorThatOf(sqInt aClass, sqInt aSuperClass);
#if VM_PROXY_MINOR > 10
sqInt isKindOfClass(sqInt oop, sqInt aClass);
sqInt primitiveErrorTable(void);
sqInt primitiveFailureCode(void);
sqInt instanceSizeOf(sqInt aClass);
void tenuringIncrementalGC(void);
#endif
sqInt isArray(sqInt oop);
sqInt isOopMutable(sqInt oop);
sqInt isOopImmutable(sqInt oop);

/* InterpreterProxy methodsFor: 'converting' */
sqInt  booleanValueOf(sqInt obj);
sqInt  checkedIntegerValueOf(sqInt intOop);
sqInt  floatObjectOf(double aFloat);
double floatValueOf(sqInt oop);
sqInt  integerObjectOf(sqInt value);
sqInt  integerValueOf(sqInt oop);
sqInt  positive32BitIntegerFor(unsigned int integerValue);
usqInt  positive32BitValueOf(sqInt oop);
sqInt  signed32BitIntegerFor(sqInt integerValue);
int    signed32BitValueOf(sqInt oop);
sqInt  positive64BitIntegerFor(usqLong integerValue);
usqLong positive64BitValueOf(sqInt oop);
sqInt  signed64BitIntegerFor(sqLong integerValue);
sqLong signed64BitValueOf(sqInt oop);
sqIntptr_t   signedMachineIntegerValueOf(sqInt);
sqIntptr_t   stackSignedMachineIntegerValue(sqInt);
usqIntptr_t  positiveMachineIntegerValueOf(sqInt);
usqIntptr_t  stackPositiveMachineIntegerValue(sqInt);

/* InterpreterProxy methodsFor: 'special objects' */
sqInt characterTable(void);
sqInt displayObject(void);
sqInt falseObject(void);
sqInt nilObject(void);
sqInt trueObject(void);


/* InterpreterProxy methodsFor: 'special classes' */
sqInt classArray(void);
sqInt classBitmap(void);
sqInt classByteArray(void);
sqInt classCharacter(void);
sqInt classFloat(void);
sqInt classLargePositiveInteger(void);
sqInt classLargeNegativeInteger(void);
sqInt classPoint(void);
sqInt classSemaphore(void);
sqInt classSmallInteger(void);
sqInt classString(void);


/* InterpreterProxy methodsFor: 'instance creation' */
sqInt cloneObject(sqInt oop);
sqInt instantiateClassindexableSize(sqInt classPointer, sqInt size);
sqInt makePointwithxValueyValue(sqInt xValue, sqInt yValue);
sqInt popRemappableOop(void);
sqInt pushRemappableOop(sqInt oop);


/* InterpreterProxy methodsFor: 'other' */
sqInt becomewith(sqInt array1, sqInt array2);
sqInt byteSwapped(sqInt w);
sqInt failed(void);
sqInt fullDisplayUpdate(void);
void fullGC(void);
void incrementalGC(void);
sqInt primitiveFail(void);
sqInt primitiveFailFor(sqInt reasonCode);
sqInt showDisplayBitsLeftTopRightBottom(sqInt aForm, sqInt l, sqInt t, sqInt r, sqInt b);
sqInt signalSemaphoreWithIndex(sqInt semaIndex);
sqInt success(sqInt aBoolean);
sqInt superclassOf(sqInt classPointer);
unsigned int ioMicroMSecs(void);
usqLong  ioUTCMicroseconds(void);
usqLong  ioUTCMicrosecondsNow(void);
void forceInterruptCheck(void);
sqInt getThisSessionID(void);
sqInt ioFilenamefromStringofLengthresolveAliases(char* aCharBuffer, char* filenameIndex, sqInt filenameLength, sqInt resolveFlag);
sqInt vmEndianness(void);	
sqInt getInterruptPending(void);
void  error(const char *);

/* InterpreterProxy methodsFor: 'FFI support' */
sqInt classExternalAddress(void);
sqInt classExternalData(void);
sqInt classExternalFunction(void);
sqInt classExternalLibrary(void);
sqInt classExternalStructure(void);
void *ioLoadModuleOfLength(sqInt moduleNameIndex, sqInt moduleNameLength);
void *ioLoadSymbolOfLengthFromModule(sqInt functionNameIndex, sqInt functionNameLength, void *moduleHandle);
sqInt isInMemory(sqInt address);
sqInt classAlien(void); /* Alien FFI */
sqInt classUnsafeAlien(void); /* Alien FFI */
sqInt *getStackPointer(void);  /* Newsqueak FFI */
void *startOfAlienData(sqInt);
usqInt sizeOfAlienData(sqInt);
sqInt signalNoResume(sqInt);
#if VM_PROXY_MINOR > 8
sqInt *getStackPointer(void);  /* Alien FFI */
# if OLD_FOR_REFERENCE /* slot repurposed for storeLong32ofObjectwithValue */
sqInt sendInvokeCallbackStackRegistersJmpbuf(sqInt thunkPtrAsInt, sqInt stackPtrAsInt, sqInt regsPtrAsInt, sqInt jmpBufPtrAsInt); /* Alien FFI */
# else
usqInt  storeLong32ofObjectwithValue(sqInt index, sqInt oop, usqInt); 
# endif
sqInt reestablishContextPriorToCallback(sqInt callbackContext); /* Alien FFI */
sqInt sendInvokeCallbackContext(vmccp);
sqInt returnAsThroughCallbackContext(sqInt, vmccp, sqInt);
#endif /* VM_PROXY_MINOR > 8 */
#if VM_PROXY_MINOR > 12 /* Spur */
sqInt isImmediate(sqInt oop);
sqInt isCharacterObject(sqInt oop);
sqInt isCharacterValue(int charCode);
sqInt characterObjectOf(int charCode);
sqInt characterValueOf(sqInt oop);
sqInt isPinned(sqInt objOop);
sqInt pinObject(sqInt objOop);
sqInt unpinObject(sqInt objOop);
char *cStringOrNullFor(sqInt);
#endif
#if VM_PROXY_MINOR > 13 /* More Spur + OS Errors available via prim error code */
sqInt statNumGCs(void);
sqInt stringForCString(char *);
sqInt primitiveFailForOSError(sqLong);
sqInt primitiveFailForFFIExceptionat(usqLong exceptionCode, usqInt pc);
#endif
#if VM_PROXY_MINOR > 14 /* SmartSyntaxPlugin validation rewrite support */
sqInt isBooleanObject(sqInt oop);
sqInt isPositiveMachineIntegerObject(sqInt oop);
#endif
#if VM_PROXY_MINOR > 15 /* Spur integer and float array classes */
sqInt classDoubleByteArray(void);
sqInt classWordArray(void);
sqInt classDoubleWordArray(void);
sqInt classFloat32Array(void);
sqInt classFloat64Array(void);
#endif
#if VM_PROXY_MINOR > 16 /* Spur isShorts and isLong64s testing support, hash */
sqInt isShorts(sqInt);
sqInt isLong64s(sqInt);
sqInt identityHashOf(sqInt);
sqInt isWordsOrShorts(sqInt);
sqInt bytesPerElement(sqInt);
sqInt fileTimesInUTC(void);
sqInt primitiveFailForwithSecondary(sqInt reasonCode,sqLong extraErrorCode);
#endif

void *ioLoadFunctionFrom(char *fnName, char *modName);


/* Proxy declarations for v1.8 */
#if NewspeakVM
static sqInt
callbackEnter(sqInt *callbackID) { return 0; }
static sqInt
callbackLeave(sqInt callbackID) { return 0; }
#else
sqInt callbackEnter(sqInt *callbackID);
sqInt callbackLeave(sqInt  callbackID);
#endif
sqInt addGCRoot(sqInt *varLoc);
sqInt removeGCRoot(sqInt *varLoc);

/* Proxy declarations for v1.10 */
# if VM_PROXY_MINOR > 13 /* OS Errors available in primitives; easy return forms */
sqInt  methodReturnBool(sqInt);
sqInt  methodReturnFloat(double);
sqInt  methodReturnInteger(sqInt);
sqInt  methodReturnReceiver(void);
sqInt  methodReturnString(const char *);
# else
sqInt methodArg(sqInt index);
sqInt objectArg(sqInt index);
sqInt integerArg(sqInt index);
double floatArg(sqInt index);
#endif
sqInt methodReturnValue(sqInt oop);
sqInt topRemappableOop(void);

# endif
#endif /* _SqueakVM_H */
