#ifdef HAVE_CONFIG_H
#include "config.h" /* this must happen before including std libraries */
#endif
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <setjmp.h>

#define FOR_SVM_C
#include "sqVirtualMachine.h"
#include "sqAssert.h"


struct VirtualMachine *VM = NULL;

static sqInt majorVersion(void) { return VM_PROXY_MAJOR; }

static sqInt minorVersion(void) { return VM_PROXY_MINOR; }

#if !IMMUTABILITY
static sqInt isNonIntegerObject(sqInt objectPointer)
{
	return !isIntegerObject(objectPointer);
}
#endif

#if STACKVM
extern void *setInterruptCheckChain(void (*aFunction)(void));
#else
void (*setInterruptCheckChain(void (*aFunction)(void)))() { return 0; }
#endif

/* InterpreterProxy methodsFor: 'BitBlt support' */
sqInt loadBitBltFrom(sqInt bbOop);
sqInt copyBits(void);
sqInt copyBitsFromtoat(sqInt leftX, sqInt rightX, sqInt yValue);

#if VM_PROXY_MINOR > 10
extern sqInt disownVM(sqInt flags);
extern sqInt ownVM(sqInt threadIdAndFlags);
#endif // VM_PROXY_MINOR > 10
extern sqInt isYoung(sqInt);

/* High-priority and synchronous ticker function support. */
void addHighPriorityTickee(void (*ticker)(void), unsigned periodms);
void addSynchronousTickee(void (*ticker)(void), unsigned periodms, unsigned roundms);

#if SPURVM // For now these are here; perhaps they're better in the VM.
static sqInt
interceptFetchIntegerofObject(sqInt fieldIndex, sqInt objectPointer)
{
	if (fieldIndex == 0
	 && isCharacterObject(objectPointer))
		return characterValueOf(objectPointer);

	return fetchIntegerofObject(fieldIndex, objectPointer);
}
#endif

sqInt  fetchIntegerofObject(sqInt fieldIndex, sqInt objectPointer);
struct VirtualMachine* sqGetInterpreterProxy(void)
{
	if(VM) return VM;
	VM = (struct VirtualMachine *)calloc(1, sizeof(VirtualMachine));
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
#if SPURVM
	VM->fetchIntegerofObject = interceptFetchIntegerofObject;
#else
	VM->fetchIntegerofObject = fetchIntegerofObject;
#endif
	VM->fetchPointerofObject = fetchPointerofObject;
#if OLD_FOR_REFERENCE // slot repurposed for error
	VM->obsoleteDontUseThisFetchWordofObject = obsoleteDontUseThisFetchWordofObject;
#else
	VM->error = error;
#endif
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
	VM->cloneObject = cloneObject;
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

#if VM_PROXY_MINOR <= 13 // reused in 14 and above

	VM->compilerHookVector= 0;
	VM->setCompilerInitialized= 0;

#endif

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

#if VM_PROXY_MINOR > 6
	VM->fetchLong32ofObject = fetchLong32ofObject;
	VM->getThisSessionID = getThisSessionID;
	VM->ioFilenamefromStringofLengthresolveAliases = ioFilenamefromStringofLengthresolveAliases;
	VM->vmEndianness = vmEndianness;
#endif

#if VM_PROXY_MINOR > 7
	VM->callbackEnter = callbackEnter;
# if OLD_FOR_REFERENCE
  /* N.B. callbackLeave is only ever called from the interpreter.  Further, it
   * and callbackEnter are obsoleted by Alien/FFI callbacks that are simpler
   * and faster.
   */
	VM->callbackLeave = callbackLeave;
# elif VM_PROXY_MINOR > 16
	VM->primitiveFailForwithSecondary = primitiveFailForwithSecondary;
# endif
	VM->addGCRoot = addGCRoot;
	VM->removeGCRoot = removeGCRoot;
#endif

#if VM_PROXY_MINOR > 8
	VM->primitiveFailFor    = primitiveFailFor;
	VM->setInterruptCheckChain = setInterruptCheckChain;
	VM->classAlien          = classAlien;
	VM->classUnsafeAlien    = classUnsafeAlien;
	VM->sendInvokeCallbackStackRegistersJmpbuf = sendInvokeCallbackStackRegistersJmpbuf;
	VM->reestablishContextPriorToCallback = reestablishContextPriorToCallback;
	VM->getStackPointer     = (sqInt *(*)(void))getStackPointer;
	VM->isOopImmutable = isOopImmutable;
	VM->isOopMutable   = isOopMutable;
#endif

#if VM_PROXY_MINOR > 9
# if VM_PROXY_MINOR > 13 // OS Errors available in primitives; easy return forms
	VM->methodReturnBool = methodReturnBool;
	VM->methodReturnFloat = methodReturnFloat;
	VM->methodReturnInteger = methodReturnInteger;
	VM->methodReturnReceiver = methodReturnReceiver;
	VM->methodReturnString = methodReturnString;
# else
	VM->methodArg = methodArg;
	VM->objectArg = objectArg;
	VM->integerArg = integerArg;
	VM->floatArg = floatArg;
# endif
	VM->methodReturnValue = methodReturnValue;
	VM->topRemappableOop = topRemappableOop;
#endif

#if VM_PROXY_MINOR > 10
	VM->disownVM = disownVM;
	VM->ownVM = ownVM;
	VM->addHighPriorityTickee = addHighPriorityTickee;
	VM->addSynchronousTickee = addSynchronousTickee;
	VM->utcMicroseconds = ioUTCMicroseconds;
	VM->tenuringIncrementalGC = tenuringIncrementalGC;
	VM->isYoung = isYoung;
	VM->isKindOfClass = isKindOfClass;
	VM->primitiveErrorTable = primitiveErrorTable;
	VM->primitiveFailureCode = primitiveFailureCode;
	VM->instanceSizeOf = instanceSizeOf;
#endif

#if VM_PROXY_MINOR > 11
	VM->sendInvokeCallbackContext = sendInvokeCallbackContext;
	VM->returnAsThroughCallbackContext = returnAsThroughCallbackContext;
	VM->signedMachineIntegerValueOf = signedMachineIntegerValueOf;
	VM->stackSignedMachineIntegerValue = stackSignedMachineIntegerValue;
	VM->positiveMachineIntegerValueOf = positiveMachineIntegerValueOf;
	VM->stackPositiveMachineIntegerValue = stackPositiveMachineIntegerValue;
	VM->getInterruptPending = getInterruptPending;
	VM->cStringOrNullFor = cStringOrNullFor;
	VM->startOfAlienData = startOfAlienData;
	VM->sizeOfAlienData = sizeOfAlienData;
	VM->signalNoResume = signalNoResume;
#endif

#if VM_PROXY_MINOR > 12 // Spur
	VM->isImmediate = isImmediate;
	VM->characterObjectOf = characterObjectOf;
	VM->characterValueOf = characterValueOf;
	VM->isCharacterObject = isCharacterObject;
	VM->isCharacterValue = isCharacterValue;
	VM->isPinned = isPinned;
	VM->pinObject = pinObject;
	VM->unpinObject = unpinObject;
#endif

#if VM_PROXY_MINOR > 13 // More Spur + OS Errors available via prim error code
	VM->statNumGCs = statNumGCs;
	VM->stringForCString = stringForCString;
	VM->primitiveFailForOSError = primitiveFailForOSError;
	VM->primitiveFailForFFIExceptionat = primitiveFailForFFIExceptionat;
#endif

#if VM_PROXY_MINOR > 14 // SmartSyntaxPlugin validation rewrite support
	VM->isBooleanObject = isBooleanObject ;
	VM->isPositiveMachineIntegerObject = isPositiveMachineIntegerObject;
#endif
#if VM_PROXY_MINOR > 15 // Spur integer and float array classes
	VM->classDoubleByteArray = classDoubleByteArray;
	VM->classWordArray = classWordArray;
	VM->classDoubleWordArray = classDoubleWordArray;
	VM->classFloat32Array = classFloat32Array;
	VM->classFloat64Array = classFloat64Array;
#endif
#if VM_PROXY_MINOR > 16 // Spur isShorts and isLong64s testing support, hash
	VM->isShorts = isShorts;
	VM->isLong64s = isLong64s;
	VM->identityHashOf = identityHashOf;
	VM->isWordsOrShorts = isWordsOrShorts;
	VM->bytesPerElement = bytesPerElement;
	VM->fileTimesInUTC = fileTimesInUTC;
#endif
	return VM;
}


/* This lives here for now but belongs somewhere else.
 * platforms/Cross/vm/sqStuff.c??
 */
#ifndef MUSL
#define STDOUT_STACK_SZ 5
static int stdoutStackIdx = -1;
static FILE stdoutStack[STDOUT_STACK_SZ];
#endif

/* N.B. As of cygwin 1.5.25 fopen("crash.dmp","a") DOES NOT WORK!  crash.dmp
 * contains garbled output as if the file pointer gets set to the start of the
 * file, not the end.  So we synthesize our own append mode.
 */
#if __MINGW32__
# include <io.h>
static FILE *
fopen_for_append(char *filename)
{
	FILE *f = !access(filename, F_OK) /* access is bass ackwards */
		? fopen(filename,"r+")
		: fopen(filename,"w+");
	if (f)
		_fseeki64(f,0,SEEK_END);
	return f;
}
#elif defined(_WIN32)
# define fopen_for_append(filename) fopen(filename,"a+t")
#else
# define fopen_for_append(filename) fopen(filename,"a+")
#endif

#ifndef MUSL
void
pushOutputFile(char *filenameOrStdioIndex)
{
#ifndef STDOUT_FILENO
# define STDOUT_FILENO 1
# define STDERR_FILENO 2
#endif

	FILE *output;

	if (stdoutStackIdx + 2 >= STDOUT_STACK_SZ) {
		fprintf(stderr,"output file stack is full.\n");
		return;
	}
	switch ((usqInt)filenameOrStdioIndex) {
	case STDOUT_FILENO: output = stdout; break;
	case STDERR_FILENO: output = stderr; break;
	default:
		if (!(output = fopen_for_append(filenameOrStdioIndex))) {
			fprintf(stderr,
					"could not open \"%s\" for writing.\n",
					filenameOrStdioIndex);
			return;
		}
	}
	stdoutStack[++stdoutStackIdx] = *stdout;
	*stdout = *output;
}

void
popOutputFile()
{
	if (stdoutStackIdx < 0) {
		fprintf(stderr,"output file stack is empty.\n");
		return;
	}
	fflush(stdout);
	if (fileno(stdout) > STDERR_FILENO) {
		/* as of Feb 2011 with fclose@@GLIBC_2.1 under e.g. CentOS 5.3, fclose
		 * hangs in _IO_un_link_internal.  This hack avoids that.
		 */
#if __linux__
		close(fileno(stdout));
#else
		fclose(stdout);
#endif
	}
	*stdout = stdoutStack[stdoutStackIdx--];
}
#endif

void
printPhaseTime(int phase)
{
	static	int printTimes;
	static	usqLong lastusecs;
			usqLong nowusecs, usecs;

	if (phase == 1) {
		time_t nowt;
		struct tm nowtm;
		printTimes = 1;
		nowt = time(0);
		nowtm = *localtime(&nowt);
		printf("started at %s", asctime(&nowtm));
		lastusecs = ioUTCMicrosecondsNow();
		return;
	}

	if (!printTimes) return;

	nowusecs = ioUTCMicrosecondsNow();
	usecs = nowusecs - lastusecs;
	lastusecs = nowusecs;
#define m 1000000ULL
#define k 1000ULL
#define ul(v) (unsigned long)(v)
	if (phase == 2)
		printf("loaded in %lu.%03lus\n", ul(usecs/m), ul((usecs % m + k/2)/k));
	if (phase == 3) {
		printTimes = 0; /* avoid repeated printing if error during exit */
		if (usecs >= 1ULL<<32)
			printf("ran for a long time\n");
		else
			printf("ran for %lu.%03lus\n", ul(usecs/m), ul((usecs % m + k/2)/k));
	}
#undef m
#undef k
}
