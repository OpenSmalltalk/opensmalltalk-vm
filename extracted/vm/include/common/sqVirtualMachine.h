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
#	define VM_PROXY_MINOR 15
# else
#	define VM_PROXY_MINOR 12
# endif
#endif

#include "sqMemoryAccess.h"

#if VM_PROXY_MINOR > 8
# define PrimNoErr 0
# define PrimErrGenericFailure 1
# define PrimErrBadReceiver 2
# define PrimErrBadArgument 3
# define PrimErrBadIndex 4
# define PrimErrBadNumArgs 5
# define PrimErrInappropriate 6
# define PrimErrUnsupported 7
# define PrimErrNoModification 8
# define PrimErrNoMemory 9
# define PrimErrNoCMemory 10
# define PrimErrNotFound 11
# define PrimErrBadMethod 12
# define PrimErrNamedInternal 13
# define PrimErrObjectMayMove 14

/* VMCallbackContext opaque type avoids all including setjmp.h & vmCallback.h */
typedef struct _VMCallbackContext *vmccp;
#endif

typedef sqInt (*CompilerHook)();

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
/*  sqInt  (*fetchWordofObject)(sqInt fieldFieldIndex, sqInt oop); *
 * has been rescinded as of VMMaker 3.8 and the 64bitclean VM      *
 * work. To support old plugins we keep a valid function in        *
 * the same location in the VM struct but rename it to             *
 * something utterly horrible to scare off the natives. A new      *
 * equivalent but 64 bit valid function is added as                *
 * 'fetchLong32OfObject'                                           */
	sqInt  (*obsoleteDontUseThisFetchWordofObject)(sqInt fieldFieldIndex, sqInt oop);
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

	sqInt (*clone)(sqInt oop);
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
	void *(*ioLoadSymbolOfLengthFromModule)(sqInt fnIndex, sqInt fnLength, sqInt handle);
	sqInt (*isInMemory)(sqInt address);

#endif

#if VM_PROXY_MINOR > 3

	void *(*ioLoadFunctionFrom)(char *fnName, char *modName);
	sqInt (*ioMicroMSecs)(void);

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

  /* callbackLeave: Leave the interpreter from a previous callback
     Arguments:
       callbackID: The ID of the callback received from callbackEnter()
     Returns: True if succcessful, false otherwise. */
  sqInt (*callbackLeave)(sqInt  callbackID);

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
	void (*(*setInterruptCheckChain)(void (*aFunction)(void)))();
	sqInt  (*classAlien)(void);
	sqInt  (*classUnsafeAlien)(void);
	sqInt  (*sendInvokeCallbackStackRegistersJmpbuf)(sqInt thunkPtrAsInt, sqInt stackPtrAsInt, sqInt regsPtrAsInt, sqInt jmpBufPtrAsInt);
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
  sqInt  (*methodReturnString)(char *);
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
# if !SPURVM
#	define DisownVMLockOutFullGC 1
# endif
  sqInt	(*disownVM)(sqInt flags);
  sqInt	(*ownVM)   (sqInt threadIdAndFlags);
  void  (*addHighPriorityTickee)(void (*ticker)(void), unsigned periodms);
  void  (*addSynchronousTickee)(void (*ticker)(void), unsigned periodms, unsigned roundms);
  volatile usqLong (*utcMicroseconds)(void);
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
  sqInt (*returnAsThroughCallbackContext)(int, vmccp, sqInt);
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

  sqInt (*ptEnterInterpreterFromCallback)(vmccp);
  sqInt (*ptExitInterpreterToCallback)(vmccp);
  sqInt (*ptDisableCogIt)(void*);

  sqInt (*isNonImmediate)(sqInt oop);

  sqInt (*platformSemaphoreNew)(int initialValue);

  sqInt (*scheduleInMainThread)(sqInt (*closure)());

} VirtualMachine;

#endif /* _SqueakVM_H */
