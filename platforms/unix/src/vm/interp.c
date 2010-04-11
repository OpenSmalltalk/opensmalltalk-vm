/* Automatically generated from Squeak on 10 April 2010 7:46:19 pm 
   by VMMaker 4.0.3
 */
#define SQ_USE_GLOBAL_STRUCT 1

#include "sq.h"
#include <setjmp.h>

#ifndef allocateMemoryMinimumImageFileHeaderSize
 /* Called by Interpreter>>allocateMemory:minimum:imageFile:headerSize: */
 /* Default definition if not previously defined in config.h */
 #define allocateMemoryMinimumImageFileHeaderSize(heapSize, minimumMemory, fileStream, headerSize) \
    sqAllocateMemory(minimumMemory, heapSize)
#endif

#ifndef sqImageFileReadEntireImage
 /* Called by Interpreter>>sqImage:read:size:length: */
 /* Default definition if not previously defined in config.h */
 #define sqImageFileReadEntireImage(memoryAddress, elementSize,  length, fileStream) \
    sqImageFileRead(memoryAddress, elementSize,  length, fileStream)
#endif

#ifndef error
 /* error() function called from Interpreter */
 /* Default definition if not previously defined in config.h */
 #define error(str) defaultErrorProc(str)
#endif

#ifndef ioMicroSecondClock
 /* Called by Interpreter>>primitiveMicrosecondClock and GC methods */
 /* Default definition if not previously defined in config.h */
 #define ioMicroSecondClock ioMSecs
#endif

#ifndef ioUtcWithOffset
 /* Called by Interpreter>>primitiveUtcWithOffset */
 /* Default definition if not previously defined in config.h */
 #define ioUtcWithOffset(clock, offset) setMicroSecondsandOffset(clock, offset)
#endif

#include "sqMemoryAccess.h"

sqInt printCallStack(void);
void defaultErrorProc(char *s) {
	/* Print an error message and exit. */
	static sqInt printingStack = false;

	printf("\n%s\n\n", s);
	if (!printingStack) {
		/* flag prevents recursive error when trying to print a broken stack */
		printingStack = true;
		printCallStack();
	}
	exit(-1);
}

/*** Constants ***/
#define ActiveProcessIndex 1
#define AllButHashBits 3758227455U
#define AllButMarkBit 2147483647U
#define AllButMarkBitAndTypeMask 2147483644
#define AllButRootBit 3221225471U
#define AllButTypeMask 4294967292U
#define AtCacheFixedFields 4
#define AtCacheFmt 3
#define AtCacheMask 28
#define AtCacheOop 1
#define AtCacheSize 2
#define AtCacheTotalSize 64
#define AtPutBase 32
#define BaseHeaderSize 4
#define BlockArgumentCountIndex 3
#define Byte0Mask 255
#define Byte1Mask 65280
#define Byte1Shift 8
#define Byte1ShiftNegated -8
#define Byte2Mask 16711680
#define Byte3Mask 4278190080U
#define Byte3Shift 24
#define Byte3ShiftNegated -24
#define Byte4Mask 0
#define Byte4Shift 0
#define Byte4ShiftNegated 0
#define Byte5Mask 0
#define Byte5Shift 0
#define Byte5ShiftNegated 0
#define Byte6Mask 0
#define Byte7Mask 0
#define Byte7Shift 0
#define Byte7ShiftNegated 0
#define Bytes3to0Mask 0
#define Bytes7to4Mask 0
#define BytesPerWord 4
#define CacheProbeMax 3
#define CallerIndex 0
#define CharacterTable 24
#define CharacterValueIndex 0
#define ClassArray 7
#define ClassBitmap 4
#define ClassBlockClosure 36
#define ClassBlockContext 11
#define ClassByteArray 26
#define ClassCharacter 19
#define ClassExternalAddress 43
#define ClassExternalData 45
#define ClassExternalFunction 46
#define ClassExternalLibrary 47
#define ClassExternalStructure 44
#define ClassFloat 9
#define ClassInteger 5
#define ClassLargeNegativeInteger 42
#define ClassLargePositiveInteger 13
#define ClassMessage 15
#define ClassMethodContext 10
#define ClassPoint 12
#define ClassSemaphore 18
#define ClassString 6
#define ClosureFirstCopiedValueIndex 3
#define ClosureIndex 4
#define ClosureNumArgsIndex 2
#define ClosureOuterContextIndex 0
#define ClosureStartPCIndex 1
#define CompactClassMask 126976
#define CompactClasses 28
#define ConstMinusOne -1
#define ConstOne 3
#define ConstTwo 5
#define ConstZero 1
#define CrossedX 258
#define CtxtTempFrameStart 6
#define DoAssertionChecks 0
#define DoBalanceChecks 0
#define Done 4
#define EndOfRun 257
#define ExcessSignalsIndex 2
#define ExternalObjectsArray 38
#define ExtraRootSize 2048
#define FalseObject 1
#define FirstLinkIndex 0
#define GCTopMarker 3
#define HashBits 536739840
#define HashBitsOffset 17
#define HeaderIndex 0
#define HeaderTypeClass 1
#define HeaderTypeFree 2
#define HeaderTypeGC 2
#define HeaderTypeShort 3
#define HeaderTypeSizeAndClass 0
#define HomeIndex 5
#define InitialIPIndex 4
#define InstanceSpecificationIndex 2
#define InstructionPointerIndex 1
#define InterpreterSourceVersion "4.0.3"
#define LargeContextBit 262144
#define LargeContextSize 252
#define LastLinkIndex 1
#define LiteralStart 1
#define LongSizeMask 4294967292U
#define MarkBit 2147483648U
#define MaxExternalPrimitiveTableSize 4096
#define MaxJumpBuf 32
#define MaxPrimitiveIndex 575
#define MessageArgumentsIndex 1
#define MessageDictionaryIndex 1
#define MessageLookupClassIndex 2
#define MessageSelectorIndex 0
#define MethodArrayIndex 1
#define MethodCacheClass 2
#define MethodCacheEntries 512
#define MethodCacheEntrySize 8
#define MethodCacheMask 4088
#define MethodCacheMethod 3
#define MethodCacheNative 5
#define MethodCachePrim 4
#define MethodCachePrimFunction 6
#define MethodCacheSelector 1
#define MethodCacheSize 4096
#define MethodIndex 3
#define MillisecondClockMask 536870911
#define MyListIndex 3
#define NextLinkIndex 0
#define NilContext 1
#define NilObject 0
#define PrimitiveExternalCallIndex 117
#define PriorityIndex 2
#define ProcessListsIndex 0
#define ProcessSignalingLowSpace 22
#define ReceiverIndex 5
#define RootBit 1073741824
#define RootTableRedZone 2400
#define RootTableSize 2500
#define SchedulerAssociation 3
#define SelectorAboutToReturn 48
#define SelectorCannotInterpret 34
#define SelectorCannotReturn 21
#define SelectorDoesNotUnderstand 20
#define SelectorMustBeBoolean 25
#define SelectorRunWithIn 49
#define SelectorStart 2
#define SemaphoresToSignalSize 500
#define SenderIndex 0
#define ShiftForWord 2
#define Size4Bit 0
#define SizeMask 252
#define SmallContextSize 92
#define SpecialSelectors 23
#define StackPointerIndex 2
#define StartField 1
#define StartObj 2
#define StreamArrayIndex 0
#define StreamIndexIndex 1
#define StreamReadLimitIndex 2
#define StreamWriteLimitIndex 3
#define SuperclassIndex 0
#define SuspendedContextIndex 1
#define TempFrameStart 6
#define TheDisplay 14
#define TheFinalizationSemaphore 41
#define TheInterruptSemaphore 30
#define TheLowSpaceSemaphore 17
#define TheTimerSemaphore 29
#define TrueObject 2
#define TypeMask 3
#define Upward 3
#define ValueIndex 1
#define WordMask 4294967295U
#define XIndex 0
#define YIndex 1

/*** Function Prototypes ***/
sqInt accessibleObjectAfter(sqInt oop);
sqInt activateNewClosureMethod(sqInt blockClosure);
sqInt activateNewMethod(void);
#pragma export on
EXPORT(sqInt) addGCRoot(sqInt *varLoc);
#pragma export off
sqInt addNewMethodToCache(void);
sqInt addToExternalPrimitiveTable(void *functionAddress);
sqInt adjustAllOopsBy(sqInt bytesToShift);
sqInt allYoungand(sqInt array1, sqInt array2);
sqInt allocateChunk(sqInt byteSize);
sqInt allocateOrRecycleContext(sqInt needsLarge);
sqInt argumentCountOf(sqInt methodPointer);
void * arrayValueOf(sqInt arrayOop);
sqInt asciiOfCharacter(sqInt characterObj);
sqInt balancedStackafterPrimitivewithArgs(sqInt delta, sqInt primIdx, sqInt nArgs);
sqInt beRootIfOld(sqInt oop);
sqInt becomewith(sqInt array1, sqInt array2);
sqInt becomewithtwoWaycopyHash(sqInt array1, sqInt array2, sqInt twoWayFlag, sqInt copyHashFlag);
sqInt biasToGrow(void);
sqInt booleanValueOf(sqInt obj);
sqInt byteSizeOf(sqInt oop);
sqInt byteSwapByteObjectsFromto(sqInt startOop, sqInt stopAddr);
sqInt byteSwapped(sqInt w);
sqInt bytesPerWord(void);
sqInt callExternalPrimitive(void * functionID);
#pragma export on
EXPORT(sqInt) callInterpreter(void);
EXPORT(sqInt) callbackEnter(sqInt *callbackID);
EXPORT(sqInt) callbackLeave(sqInt cbID);
#pragma export off
sqInt changeClassOfto(sqInt rcvr, sqInt argClass);
sqInt characterForAscii(sqInt ascii);
sqInt characterTable(void);
sqInt checkForInterrupts(void);
sqInt checkImageVersionFromstartingAt(sqImageFile  f, squeakFileOffsetType  imageOffset);
sqInt checkedIntegerValueOf(sqInt intOop);
sqInt checkedLongAt(sqInt byteAddress);
sqInt classArray(void);
sqInt classBitmap(void);
sqInt classByteArray(void);
sqInt classCharacter(void);
sqInt classExternalAddress(void);
sqInt classExternalData(void);
sqInt classExternalFunction(void);
sqInt classExternalLibrary(void);
sqInt classExternalStructure(void);
sqInt classFloat(void);
sqInt classLargeNegativeInteger(void);
sqInt classLargePositiveInteger(void);
sqInt classNameOfIs(sqInt aClass, char * className);
sqInt classPoint(void);
sqInt classSemaphore(void);
sqInt classSmallInteger(void);
sqInt classString(void);
sqInt clone(sqInt oop);
sqInt commonAt(sqInt stringy);
sqInt commonAtPut(sqInt stringy);
sqInt commonVariableatcacheIndex(sqInt rcvr, sqInt index, sqInt atIx);
sqInt compare31or32Bitsequal(sqInt obj1, sqInt obj2);
sqInt compilerCreateActualMessagestoringArgs(sqInt aMessage, sqInt argArray);
sqInt compilerFlushCache(sqInt aCompiledMethod);
sqInt compilerMapFromto(sqInt memStart, sqInt memEnd);
sqInt compilerMark(void);
sqInt compilerPostGC(void);
sqInt compilerPostSnapshot(void);
sqInt compilerPreGC(sqInt fullGCFlag);
sqInt compilerPreSnapshot(void);
sqInt compilerProcessChange(void);
sqInt compilerProcessChangeto(sqInt oldProc, sqInt newProc);
sqInt compilerTranslateMethod(void);
sqInt containOnlyOopsand(sqInt array1, sqInt array2);
sqInt contexthasSender(sqInt thisCntx, sqInt aContext);
sqInt copyBits(void);
sqInt copyBitsFromtoat(sqInt x0, sqInt x1, sqInt y);
sqInt copyObjtoSegmentaddrstopAtsaveOopAtheaderAt(sqInt oop, sqInt segmentWordArray, sqInt lastSeg, sqInt stopAddr, sqInt oopPtr, sqInt hdrPtr);
sqInt createActualMessageTo(sqInt aClass);
sqInt dispatchFunctionPointer(void * aFunctionPointer);
sqInt dispatchFunctionPointerOnin(sqInt primIdx, void *primTable[]);
sqInt displayBitsOfLeftTopRightBottom(sqInt aForm, sqInt l, sqInt t, sqInt r, sqInt b);
sqInt displayObject(void);
sqInt doPrimitiveDivby(sqInt rcvr, sqInt arg);
sqInt doPrimitiveModby(sqInt rcvr, sqInt arg);
sqInt dummyReferToProxy(void);
#pragma export on
EXPORT(sqInt) dumpImage(char * fileName);
#pragma export off
sqInt executeNewMethodFromCache(void);
sqInt failed(void);
sqInt falseObject(void);
void * fetchArrayofObject(sqInt fieldIndex, sqInt objectPointer);
sqInt fetchClassOf(sqInt oop);
sqInt fetchClassOfNonInt(sqInt oop);
double fetchFloatofObject(sqInt fieldIndex, sqInt objectPointer);
sqInt fetchIntegerofObject(sqInt fieldIndex, sqInt objectPointer);
sqInt fetchLong32ofObject(sqInt fieldIndex, sqInt oop);
sqInt fetchPointerofObject(sqInt fieldIndex, sqInt oop);
sqInt fetchStackPointerOf(sqInt aContext);
sqInt fetchWordLengthOf(sqInt objectPointer);
sqInt finalizeReference(usqInt oop);
sqInt findClassOfMethodforReceiver(sqInt meth, sqInt rcvr);
sqInt findNewMethodInClass(sqInt class);
sqInt findObsoleteNamedPrimitivelength(char * functionName, sqInt functionLength);
sqInt findSelectorOfMethodforReceiver(sqInt meth, sqInt rcvr);
sqInt firstAccessibleObject(void);
char * firstFixedField(sqInt oop);
char * firstIndexableField(sqInt oop);
sqInt floatObjectOf(double  aFloat);
double floatValueOf(sqInt oop);
sqInt flushExternalPrimitiveOf(sqInt methodPtr);
sqInt flushExternalPrimitives(void);
sqInt forceInterruptCheck(void);
sqInt fullDisplayUpdate(void);
sqInt fullGC(void);
sqInt fwdTableInit(sqInt blkSize);
sqInt fwdTableSize(sqInt blkSize);
sqInt getCurrentBytecode(void);
sqInt getFullScreenFlag(void);
sqInt getInterruptCheckCounter(void);
sqInt getInterruptKeycode(void);
sqInt getInterruptPending(void);
sqInt getLongFromFileswap(sqImageFile  aFile, sqInt swapFlag);
sqInt getNextWakeupTick(void);
sqInt getSavedWindowSize(void);
sqInt getThisSessionID(void);
sqInt growObjectMemory(usqInt delta);
sqInt imageFormatBackwardCompatibilityVersion(void);
sqInt imageFormatForwardCompatibilityVersion(void);
sqInt imageSegmentVersion(void);
sqInt incCompBody(void);
sqInt incCompMakeFwd(void);
sqInt incCompMove(sqInt bytesFreed);
sqInt includesBehaviorThatOf(sqInt aClass, sqInt aSuperclass);
sqInt incrementalGC(void);
sqInt initCompilerHooks(void);
sqInt initializeInterpreter(sqInt bytesToShift);
sqInt initializeMemoryFirstFree(usqInt firstFree);
sqInt initializeObjectMemory(sqInt bytesToShift);
sqInt installinAtCacheatstring(sqInt rcvr, sqInt * cache, sqInt atIx, sqInt stringy);
sqInt instantiateClassindexableSize(sqInt classPointer, sqInt size);
sqInt instantiateContextsizeInBytes(sqInt classPointer, sqInt sizeInBytes);
sqInt instantiateSmallClasssizeInBytes(sqInt classPointer, sqInt sizeInBytes);
sqInt integerObjectOf(sqInt value);
sqInt integerValueOf(sqInt objectPointer);
sqInt interpret(void);
sqInt ioFilenamefromStringofLengthresolveAliases(char * aCharBuffer, char * aFilenameString, sqInt filenameLength, sqInt aBoolean);
sqInt isKindOf(sqInt oop, char * className);
sqInt isMemberOf(sqInt oop, char * className);
sqInt isArray(sqInt oop);
sqInt isBigEnder(void);
sqInt isBytes(sqInt oop);
sqInt isExcessiveAllocationRequestshift(sqInt size, sqInt bits);
sqInt isFloatObject(sqInt oop);
sqInt isHandlerMarked(sqInt aContext);
sqInt isInMemory(sqInt address);
sqInt isIndexable(sqInt oop);
sqInt isIntegerObject(sqInt objectPointer);
sqInt isIntegerValue(sqInt intValue);
sqInt isPointers(sqInt oop);
sqInt isWeak(sqInt oop);
sqInt isWords(sqInt oop);
sqInt isWordsOrBytes(sqInt oop);
sqInt isWordsOrBytesNonInt(sqInt oop);
sqInt lastPointerOf(sqInt oop);
sqInt lengthOf(sqInt oop);
sqInt literalofMethod(sqInt offset, sqInt methodPointer);
sqInt literalCountOf(sqInt methodPointer);
sqInt loadBitBltFrom(sqInt bb);
sqInt loadInitialContext(void);
sqInt lookupMethodInClass(sqInt class);
sqInt lowestFreeAfter(sqInt chunk);
sqInt makePointwithxValueyValue(sqInt xValue, sqInt yValue);
sqInt mapPointersInObjectsFromto(sqInt memStart, sqInt memEnd);
sqInt markAndTrace(sqInt oop);
sqInt markAndTraceInterpreterOops(void);
sqInt markPhase(void);
sqInt methodArgumentCount(void);
sqInt methodPrimitiveIndex(void);
#pragma export on
EXPORT(sqInt) moduleUnloaded(char * aModuleName);
#pragma export off
sqInt nilObject(void);
sqInt nonWeakFieldsOf(sqInt oop);
sqInt noteAsRootheaderLoc(sqInt oop, sqInt headerLoc);
sqInt nullCompilerHook(void);
sqInt objectAfter(sqInt oop);
sqInt obsoleteDontUseThisFetchWordofObject(sqInt fieldIndex, sqInt oop);
sqInt okayFields(sqInt oop);
sqInt okayOop(sqInt signedOop);
sqInt oopHasAcceptableClass(sqInt signedOop);
sqInt oopHasOkayClass(sqInt signedOop);
sqInt pop(sqInt nItems);
sqInt popthenPush(sqInt nItems, sqInt oop);
double popFloat(void);
sqInt popRemappableOop(void);
sqInt popStack(void);
sqInt positive32BitIntegerFor(sqInt integerValue);
sqInt positive32BitValueOf(sqInt oop);
sqInt positive64BitIntegerFor(sqLong integerValue);
sqLong positive64BitValueOf(sqInt oop);
sqInt possibleRootStoreIntovalue(sqInt oop, sqInt valueObj);
sqInt postGCAction(void);
sqInt prepareForwardingTableForBecomingwithtwoWay(sqInt array1, sqInt array2, sqInt twoWayFlag);
sqInt primitiveAdd(void);
sqInt primitiveArctan(void);
sqInt primitiveArrayBecome(void);
sqInt primitiveArrayBecomeOneWay(void);
sqInt primitiveArrayBecomeOneWayCopyHash(void);
sqInt primitiveAsFloat(void);
sqInt primitiveAsOop(void);
sqInt primitiveAt(void);
sqInt primitiveAtEnd(void);
sqInt primitiveAtPut(void);
sqInt primitiveBeCursor(void);
sqInt primitiveBeDisplay(void);
sqInt primitiveBeep(void);
sqInt primitiveBitAnd(void);
sqInt primitiveBitOr(void);
sqInt primitiveBitShift(void);
sqInt primitiveBitXor(void);
sqInt primitiveBlockCopy(void);
sqInt primitiveBytesLeft(void);
sqInt primitiveCalloutToFFI(void);
sqInt primitiveChangeClass(void);
#pragma export on
EXPORT(sqInt) primitiveChangeClassWithClass(void);
#pragma export off
sqInt primitiveClass(void);
sqInt primitiveClipboardText(void);
sqInt primitiveClone(void);
sqInt primitiveClosureCopyWithCopiedValues(void);
sqInt primitiveClosureValue(void);
sqInt primitiveClosureValueNoContextSwitch(void);
sqInt primitiveClosureValueWithArgs(void);
sqInt primitiveConstantFill(void);
sqInt primitiveCopyObject(void);
sqInt primitiveDeferDisplayUpdates(void);
#pragma export on
EXPORT(sqInt) primitiveDisablePowerManager(void);
#pragma export off
sqInt primitiveDiv(void);
sqInt primitiveDivide(void);
sqInt primitiveDoNamedPrimitiveWithArgs(void);
sqInt primitiveDoPrimitiveWithArgs(void);
sqInt primitiveEqual(void);
sqInt primitiveEquivalent(void);
sqInt primitiveExecuteMethod(void);
sqInt primitiveExecuteMethodArgsArray(void);
sqInt primitiveExitToDebugger(void);
sqInt primitiveExp(void);
sqInt primitiveExponent(void);
sqInt primitiveExternalCall(void);
sqInt primitiveFail(void);
sqInt primitiveFindHandlerContext(void);
sqInt primitiveFindNextUnwindContext(void);
sqInt primitiveFloatAdd(void);
sqInt primitiveFloatAddtoArg(sqInt rcvrOop, sqInt argOop);
sqInt primitiveFloatDivide(void);
sqInt primitiveFloatDividebyArg(sqInt rcvrOop, sqInt argOop);
sqInt primitiveFloatEqual(void);
sqInt primitiveFloatEqualtoArg(sqInt rcvrOop, sqInt argOop);
sqInt primitiveFloatGreaterthanArg(sqInt rcvrOop, sqInt argOop);
sqInt primitiveFloatGreaterOrEqual(void);
sqInt primitiveFloatGreaterOrEqualtoArg(sqInt rcvrOop, sqInt argOop);
sqInt primitiveFloatGreaterThan(void);
sqInt primitiveFloatLessthanArg(sqInt rcvrOop, sqInt argOop);
sqInt primitiveFloatLessOrEqual(void);
sqInt primitiveFloatLessOrEqualtoArg(sqInt rcvrOop, sqInt argOop);
sqInt primitiveFloatLessThan(void);
sqInt primitiveFloatMultiply(void);
sqInt primitiveFloatMultiplybyArg(sqInt rcvrOop, sqInt argOop);
sqInt primitiveFloatNotEqual(void);
sqInt primitiveFloatSubtract(void);
sqInt primitiveFloatSubtractfromArg(sqInt rcvrOop, sqInt argOop);
sqInt primitiveFlushCache(void);
sqInt primitiveFlushCacheByMethod(void);
sqInt primitiveFlushCacheSelective(void);
sqInt primitiveFlushExternalPrimitives(void);
sqInt primitiveForceDisplayUpdate(void);
#pragma export on
EXPORT(sqInt) primitiveForceTenure(void);
#pragma export off
sqInt primitiveFormPrint(void);
sqInt primitiveFractionalPart(void);
sqInt primitiveFullGC(void);
sqInt primitiveGetAttribute(void);
sqInt primitiveGetNextEvent(void);
sqInt primitiveGreaterOrEqual(void);
sqInt primitiveGreaterThan(void);
#pragma export on
EXPORT(sqInt) primitiveImageFormatVersion(void);
#pragma export off
sqInt primitiveImageName(void);
sqInt primitiveIncrementalGC(void);
sqInt primitiveIndexOf(sqInt methodPointer);
sqInt primitiveIndexOfMethodHeader(sqInt methodHeader);
sqInt primitiveInputSemaphore(void);
sqInt primitiveInputWord(void);
sqInt primitiveInstVarAt(void);
sqInt primitiveInstVarAtPut(void);
sqInt primitiveInstVarsPutFromStack(void);
sqInt primitiveIntegerAt(void);
sqInt primitiveIntegerAtPut(void);
#pragma export on
EXPORT(sqInt) primitiveInterpreterSourceVersion(void);
#pragma export off
sqInt primitiveInterruptSemaphore(void);
sqInt primitiveInvokeObjectAsMethod(void);
#pragma export on
EXPORT(sqInt) primitiveIsRoot(void);
EXPORT(sqInt) primitiveIsYoung(void);
#pragma export off
sqInt primitiveKbdNext(void);
sqInt primitiveKbdPeek(void);
sqInt primitiveLessOrEqual(void);
sqInt primitiveLessThan(void);
sqInt primitiveListBuiltinModule(void);
sqInt primitiveListExternalModule(void);
sqInt primitiveLoadImageSegment(void);
sqInt primitiveLoadInstVar(void);
sqInt primitiveLogN(void);
sqInt primitiveLowSpaceSemaphore(void);
sqInt primitiveMakePoint(void);
sqInt primitiveMarkHandlerMethod(void);
sqInt primitiveMarkUnwindMethod(void);
sqInt primitiveMethod(void);
#pragma export on
EXPORT(sqInt) primitiveMicrosecondClock(void);
#pragma export off
sqInt primitiveMillisecondClock(void);
sqInt primitiveMod(void);
sqInt primitiveMouseButtons(void);
sqInt primitiveMousePoint(void);
sqInt primitiveMultiply(void);
sqInt primitiveNew(void);
sqInt primitiveNewMethod(void);
sqInt primitiveNewWithArg(void);
sqInt primitiveNext(void);
sqInt primitiveNextInstance(void);
sqInt primitiveNextObject(void);
sqInt primitiveNextPut(void);
sqInt primitiveNoop(void);
sqInt primitiveNotEqual(void);
sqInt primitiveObjectAt(void);
sqInt primitiveObjectAtPut(void);
sqInt primitiveObjectPointsTo(void);
sqInt primitiveObsoleteIndexedPrimitive(void);
sqInt primitivePerform(void);
sqInt primitivePerformAt(sqInt lookupClass);
sqInt primitivePerformInSuperclass(void);
sqInt primitivePerformWithArgs(void);
#pragma export on
EXPORT(sqInt) primitivePlatformSourceVersion(void);
#pragma export off
sqInt primitivePushFalse(void);
sqInt primitivePushMinusOne(void);
sqInt primitivePushNil(void);
sqInt primitivePushOne(void);
sqInt primitivePushSelf(void);
sqInt primitivePushTrue(void);
sqInt primitivePushTwo(void);
sqInt primitivePushZero(void);
sqInt primitiveQuit(void);
sqInt primitiveQuo(void);
sqInt primitiveRelinquishProcessor(void);
sqInt primitiveResponse(void);
sqInt primitiveResume(void);
#pragma export on
EXPORT(sqInt) primitiveRootTable(void);
EXPORT(sqInt) primitiveRootTableAt(void);
#pragma export off
sqInt primitiveScanCharacters(void);
#pragma export on
EXPORT(sqInt) primitiveScreenDepth(void);
#pragma export off
sqInt primitiveScreenSize(void);
sqInt primitiveSecondsClock(void);
sqInt primitiveSetDisplayMode(void);
sqInt primitiveSetFullScreen(void);
#pragma export on
EXPORT(sqInt) primitiveSetGCBiasToGrow(void);
EXPORT(sqInt) primitiveSetGCBiasToGrowGCLimit(void);
EXPORT(sqInt) primitiveSetGCSemaphore(void);
#pragma export off
sqInt primitiveSetInterruptKey(void);
sqInt primitiveShortAt(void);
sqInt primitiveShortAtPut(void);
sqInt primitiveShowDisplayRect(void);
sqInt primitiveSignal(void);
sqInt primitiveSignalAtBytesLeft(void);
sqInt primitiveSignalAtMilliseconds(void);
sqInt primitiveSine(void);
sqInt primitiveSize(void);
sqInt primitiveSnapshot(void);
sqInt primitiveSnapshotEmbedded(void);
sqInt primitiveSomeInstance(void);
sqInt primitiveSomeObject(void);
sqInt primitiveSpecialObjectsOop(void);
sqInt primitiveSquareRoot(void);
sqInt primitiveStoreImageSegment(void);
sqInt primitiveStoreStackp(void);
sqInt primitiveStringAt(void);
sqInt primitiveStringAtPut(void);
sqInt primitiveStringReplace(void);
sqInt primitiveSubtract(void);
sqInt primitiveSuspend(void);
sqInt primitiveTerminateTo(void);
sqInt primitiveTestDisplayDepth(void);
sqInt primitiveTimesTwoPower(void);
sqInt primitiveTruncated(void);
sqInt primitiveUnloadModule(void);
#pragma export on
EXPORT(sqInt) primitiveUtcWithOffset(void);
#pragma export off
sqInt primitiveVMParameter(void);
sqInt primitiveVMPath(void);
#pragma export on
EXPORT(sqInt) primitiveVMVersion(void);
#pragma export off
sqInt primitiveValue(void);
sqInt primitiveValueUninterruptably(void);
sqInt primitiveValueWithArgs(void);
sqInt primitiveWait(void);
sqInt primitiveYield(void);
sqInt print(char * s);
sqInt printAllStacks(void);
sqInt printCallStack(void);
sqInt printCallStackOf(sqInt aContext);
sqInt printNameOfClasscount(sqInt classOop, sqInt cnt);
sqInt printNum(sqInt n);
sqInt printStringOf(sqInt oop);
sqInt printUnbalancedStack(sqInt primIdx);
sqInt push(sqInt object);
sqInt pushBool(sqInt trueOrFalse);
sqInt pushFloat(double  f);
sqInt pushInteger(sqInt integerValue);
sqInt pushRemappableOop(sqInt oop);
sqInt putLongtoFile(sqInt aWord, sqImageFile  aFile);
sqInt readImageFromFileHeapSizeStartingAt(sqImageFile  f, usqInt desiredHeapSize, squeakFileOffsetType  imageOffset);
sqInt readableFormat(sqInt imageVersion);
sqInt remap(sqInt oop);
sqInt removeFirstLinkOfList(sqInt aList);
#pragma export on
EXPORT(sqInt) removeGCRoot(sqInt *varLoc);
#pragma export off
sqInt restoreHeadersFromtofromandtofrom(sqInt firstIn, sqInt lastIn, sqInt hdrBaseIn, sqInt firstOut, sqInt lastOut, sqInt hdrBaseOut);
sqInt resume(sqInt aProcess);
sqInt reverseDisplayFromto(sqInt startIndex, sqInt endIndex);
sqInt rewriteMethodCacheSelclassprimIndex(sqInt selector, sqInt class, sqInt localPrimIndex);
sqInt rewriteMethodCacheSelclassprimIndexprimFunction(sqInt selector, sqInt class, sqInt localPrimIndex, void * localPrimAddress);
sqInt setCompilerInitialized(sqInt newFlag);
sqInt setFullScreenFlag(sqInt value);
sqInt setInterruptCheckCounter(sqInt value);
sqInt setInterruptKeycode(sqInt value);
sqInt setInterruptPending(sqInt value);
sqInt setMicroSecondsandOffset(sqLong * microSeconds, int * utcOffset);
sqInt setNextWakeupTick(sqInt value);
sqInt setSavedWindowSize(sqInt value);
sqInt showDisplayBitsLeftTopRightBottom(sqInt aForm, sqInt l, sqInt t, sqInt r, sqInt b);
sqInt signalSemaphoreWithIndex(sqInt index);
sqInt signed32BitIntegerFor(int integerValue);
int signed32BitValueOf(sqInt oop);
sqInt signed64BitIntegerFor(sqLong integerValue);
sqLong signed64BitValueOf(sqInt oop);
sqInt sizeBitsOf(sqInt oop);
sqInt sizeOfSTArrayFromCPrimitive(void * cPtr);
sqInt slotSizeOf(sqInt oop);
sqInt snapshot(sqInt embedded);
sqInt splObj(sqInt index);
sqInt stObjectat(sqInt array, sqInt index);
sqInt stObjectatput(sqInt array, sqInt index, sqInt value);
sqInt stSizeOf(sqInt oop);
double stackFloatValue(sqInt offset);
sqInt stackIntegerValue(sqInt offset);
sqInt stackObjectValue(sqInt offset);
sqInt stackValue(sqInt offset);
sqInt storeIntegerofObjectwithValue(sqInt fieldIndex, sqInt objectPointer, sqInt integerValue);
sqInt storePointerofObjectwithValue(sqInt fieldIndex, sqInt oop, sqInt valuePointer);
sqInt success(sqInt successValue);
sqInt sufficientSpaceAfterGC(usqInt minFree);
sqInt sufficientSpaceToAllocate(usqInt bytes);
sqInt superclassOf(sqInt classPointer);
sqInt sweepPhase(void);
sqInt synchronousSignal(sqInt aSemaphore);
sqInt transferTo(sqInt aProc);
sqInt trueObject(void);
sqInt updatePointersInRangeFromto(sqInt memStart, sqInt memEnd);
sqInt updatePointersInRootObjectsFromto(sqInt memStart, sqInt memEnd);
sqInt validateRoots(void);
sqInt verifyCleanHeaders(void);
sqInt vmEndianness(void);
sqInt wakeHighestPriority(void);
sqInt wordSwapped(sqInt w);
sqInt writeImageFile(sqInt imageBytes);
sqInt writeImageFileIO(sqInt imageBytes);
/*** Variables ***/
struct foo {
sqInt successFlag;
sqInt specialObjectsOop;
sqInt nilObj;
sqInt argumentCount;
sqInt trueObj;
sqInt falseObj;
sqInt interruptCheckCounter;
sqInt remapBufferCount;
sqInt nextPollTick;
sqInt primitiveIndex;
sqInt messageSelector;
sqInt allocationCount;
sqInt compilerInitialized;
sqInt rootTableCount;
sqInt allocationsBetweenGCs;
sqInt lkupClass;
sqInt lowSpaceThreshold;
sqInt receiver;
sqInt signalLowSpace;
sqInt lastHash;
sqInt jmpDepth;
sqInt freeContexts;
sqInt pendingFinalizationSignals;
sqInt freeLargeContexts;
sqInt statMarkCount;
sqInt reclaimableContextCount;
sqInt nextWakeupTick;
sqInt extraRootCount;
sqInt semaphoresToSignalCountA;
sqInt newNativeMethod;
sqInt interruptKeycode;
sqInt methodClass;
sqInt receiverClass;
sqInt statMkFwdCount;
sqInt semaphoresToSignalCountB;
sqInt statCompMoveCount;
sqInt statSweepCount;
sqInt fullScreenFlag;
sqInt semaphoresUseBufferA;
sqInt interruptPending;
sqInt statRootTableOverflows;
sqInt tenuringThreshold;
sqInt gcBiasToGrow;
sqInt statIncrGCs;
sqInt statTenures;
sqInt statFullGCs;
sqInt gcBiasToGrowGCLimit;
sqInt statShrinkMemory;
sqInt forceTenureFlag;
sqInt deferDisplayUpdates;
sqInt statGrowMemory;
sqInt savedWindowSize;
sqInt shrinkThreshold;
sqInt totalObjectCount;
sqInt interruptChecksEveryNms;
sqInt statpendingFinalizationSignals;
sqInt statSpecialMarkCount;
sqInt gcSemaphoreIndex;
sqInt weakRootCount;
sqInt statRootTableCount;
sqInt statAllocationCount;
sqInt statSurvivorCount;
sqInt lastTick;
sqInt jmpMax;
sqInt interruptCheckCounterFeedBackReset;
sqInt globalSessionID;
sqInt remapBuffer[26];
sqLong statGCTime;
sqLong statIGCDeltaTime;
sqInt headerTypeBytes[4];
usqInt gcBiasToGrowThreshold;
usqInt growHeadroom;
sqLong statFullGCMSecs;
usqInt fwdTableLast;
sqLong statIncrGCMSecs;
sqInt processSignalingLowSpace;
sqInt semaphoresToSignalB[501];
sqInt semaphoresToSignalA[501];
sqInt atCache[65];
usqInt method;
usqInt theHomeContext;
usqInt stackPointer;
usqInt instructionPointer;
long methodCache[4097];
void *primitiveFunctionPointer;
usqInt newMethod;
sqInt rootTable[2501];
usqInt memoryLimit;
sqInt weakRoots[2625];
sqInt* extraRoots[2049];
usqInt endOfMemory;
usqInt compEnd;
usqInt compStart;
usqInt freeBlock;
usqInt activeContext;
void *externalPrimitiveTable[4097];
sqInt suspendedCallbacks[33];
jmp_buf jmpBuf[33];
usqInt youngStart;
sqInt primFailCode;
sqInt suspendedMethods[33];
usqInt fwdTableNext;
 } fum;
struct foo * foo = &fum;

sqInt extraVMMemory;
const char *interpreterVersion = "Squeak3.10.2 of '5 June 2008' [latest update: #7179]";
sqInt (*compilerHooks[16])();
const char* obsoleteNamedPrimitiveTable[][3] = {
{ "gePrimitiveMergeFillFrom", "B2DPlugin", "primitiveMergeFillFrom" },
{ "gePrimitiveSetClipRect", "B2DPlugin", "primitiveSetClipRect" },
{ "gePrimitiveDoProfileStats", "B2DPlugin", "primitiveDoProfileStats" },
{ "gePrimitiveAddCompressedShape", "B2DPlugin", "primitiveAddCompressedShape" },
{ "gePrimitiveFinishedProcessing", "B2DPlugin", "primitiveFinishedProcessing" },
{ "gePrimitiveGetBezierStats", "B2DPlugin", "primitiveGetBezierStats" },
{ "gePrimitiveSetDepth", "B2DPlugin", "primitiveSetDepth" },
{ "gePrimitiveAbortProcessing", "B2DPlugin", "primitiveAbortProcessing" },
{ "gePrimitiveGetTimes", "B2DPlugin", "primitiveGetTimes" },
{ "gePrimitiveNextActiveEdgeEntry", "B2DPlugin", "primitiveNextActiveEdgeEntry" },
{ "gePrimitiveAddBezier", "B2DPlugin", "primitiveAddBezier" },
{ "gePrimitiveRenderScanline", "B2DPlugin", "primitiveRenderScanline" },
{ "gePrimitiveAddBezierShape", "B2DPlugin", "primitiveAddBezierShape" },
{ "gePrimitiveAddLine", "B2DPlugin", "primitiveAddLine" },
{ "gePrimitiveRenderImage", "B2DPlugin", "primitiveRenderImage" },
{ "gePrimitiveGetAALevel", "B2DPlugin", "primitiveGetAALevel" },
{ "gePrimitiveRegisterExternalEdge", "B2DPlugin", "primitiveRegisterExternalEdge" },
{ "gePrimitiveInitializeBuffer", "B2DPlugin", "primitiveInitializeBuffer" },
{ "gePrimitiveAddRect", "B2DPlugin", "primitiveAddRect" },
{ "gePrimitiveInitializeProcessing", "B2DPlugin", "primitiveInitializeProcessing" },
{ "gePrimitiveAddBitmapFill", "B2DPlugin", "primitiveAddBitmapFill" },
{ "gePrimitiveGetClipRect", "B2DPlugin", "primitiveGetClipRect" },
{ "gePrimitiveGetFailureReason", "B2DPlugin", "primitiveGetFailureReason" },
{ "gePrimitiveNextGlobalEdgeEntry", "B2DPlugin", "primitiveNextGlobalEdgeEntry" },
{ "gePrimitiveNextFillEntry", "B2DPlugin", "primitiveNextFillEntry" },
{ "gePrimitiveSetColorTransform", "B2DPlugin", "primitiveSetColorTransform" },
{ "gePrimitiveDisplaySpanBuffer", "B2DPlugin", "primitiveDisplaySpanBuffer" },
{ "gePrimitiveGetOffset", "B2DPlugin", "primitiveGetOffset" },
{ "gePrimitiveAddPolygon", "B2DPlugin", "primitiveAddPolygon" },
{ "gePrimitiveNeedsFlush", "B2DPlugin", "primitiveNeedsFlush" },
{ "gePrimitiveAddOval", "B2DPlugin", "primitiveAddOval" },
{ "gePrimitiveSetAALevel", "B2DPlugin", "primitiveSetAALevel" },
{ "gePrimitiveCopyBuffer", "B2DPlugin", "primitiveCopyBuffer" },
{ "gePrimitiveAddActiveEdgeEntry", "B2DPlugin", "primitiveAddActiveEdgeEntry" },
{ "gePrimitiveGetCounts", "B2DPlugin", "primitiveGetCounts" },
{ "gePrimitiveSetOffset", "B2DPlugin", "primitiveSetOffset" },
{ "gePrimitiveAddGradientFill", "B2DPlugin", "primitiveAddGradientFill" },
{ "gePrimitiveChangedActiveEdgeEntry", "B2DPlugin", "primitiveChangedActiveEdgeEntry" },
{ "gePrimitiveRegisterExternalFill", "B2DPlugin", "primitiveRegisterExternalFill" },
{ "gePrimitiveGetDepth", "B2DPlugin", "primitiveGetDepth" },
{ "gePrimitiveSetEdgeTransform", "B2DPlugin", "primitiveSetEdgeTransform" },
{ "gePrimitiveNeedsFlushPut", "B2DPlugin", "primitiveNeedsFlushPut" },
{ "primitiveFloatArrayAt", "FloatArrayPlugin", "primitiveAt" },
{ "primitiveFloatArrayMulFloatArray", "FloatArrayPlugin", "primitiveMulFloatArray" },
{ "primitiveFloatArrayAddScalar", "FloatArrayPlugin", "primitiveAddScalar" },
{ "primitiveFloatArrayDivFloatArray", "FloatArrayPlugin", "primitiveDivFloatArray" },
{ "primitiveFloatArrayDivScalar", "FloatArrayPlugin", "primitiveDivScalar" },
{ "primitiveFloatArrayHash", "FloatArrayPlugin", "primitiveHashArray" },
{ "primitiveFloatArrayAtPut", "FloatArrayPlugin", "primitiveAtPut" },
{ "primitiveFloatArrayMulScalar", "FloatArrayPlugin", "primitiveMulScalar" },
{ "primitiveFloatArrayAddFloatArray", "FloatArrayPlugin", "primitiveAddFloatArray" },
{ "primitiveFloatArraySubScalar", "FloatArrayPlugin", "primitiveSubScalar" },
{ "primitiveFloatArraySubFloatArray", "FloatArrayPlugin", "primitiveSubFloatArray" },
{ "primitiveFloatArrayEqual", "FloatArrayPlugin", "primitiveEqual" },
{ "primitiveFloatArrayDotProduct", "FloatArrayPlugin", "primitiveDotProduct" },
{ "m23PrimitiveInvertRectInto", "Matrix2x3Plugin", "primitiveInvertRectInto" },
{ "m23PrimitiveTransformPoint", "Matrix2x3Plugin", "primitiveTransformPoint" },
{ "m23PrimitiveIsPureTranslation", "Matrix2x3Plugin", "primitiveIsPureTranslation" },
{ "m23PrimitiveComposeMatrix", "Matrix2x3Plugin", "primitiveComposeMatrix" },
{ "m23PrimitiveTransformRectInto", "Matrix2x3Plugin", "primitiveTransformRectInto" },
{ "m23PrimitiveIsIdentity", "Matrix2x3Plugin", "primitiveIsIdentity" },
{ "m23PrimitiveInvertPoint", "Matrix2x3Plugin", "primitiveInvertPoint" },
{ "primitiveDeflateBlock", "ZipPlugin", "primitiveDeflateBlock" },
{ "primitiveDeflateUpdateHashTable", "ZipPlugin", "primitiveDeflateUpdateHashTable" },
{ "primitiveUpdateGZipCrc32", "ZipPlugin", "primitiveUpdateGZipCrc32" },
{ "primitiveInflateDecompressBlock", "ZipPlugin", "primitiveInflateDecompressBlock" },
{ "primitiveZipSendBlock", "ZipPlugin", "primitiveZipSendBlock" },
{ "primitiveFFTTransformData", "FFTPlugin", "primitiveFFTTransformData" },
{ "primitiveFFTScaleData", "FFTPlugin", "primitiveFFTScaleData" },
{ "primitiveFFTPermuteData", "FFTPlugin", "primitiveFFTPermuteData" },
{ NULL, NULL, NULL }
};
char* obsoleteIndexedPrimitiveTable[][3] = {
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ "BitBltPlugin", "primitiveCopyBits", NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ "BitBltPlugin", "primitiveDrawLoop", NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ "JoystickTabletPlugin", "primitiveReadJoystick", NULL },
{ "BitBltPlugin", "primitiveWarpBits", NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ "FilePlugin", "primitiveFileAtEnd", NULL },
{ "FilePlugin", "primitiveFileClose", NULL },
{ "FilePlugin", "primitiveFileGetPosition", NULL },
{ "FilePlugin", "primitiveFileOpen", NULL },
{ "FilePlugin", "primitiveFileRead", NULL },
{ "FilePlugin", "primitiveFileSetPosition", NULL },
{ "FilePlugin", "primitiveFileDelete", NULL },
{ "FilePlugin", "primitiveFileSize", NULL },
{ "FilePlugin", "primitiveFileWrite", NULL },
{ "FilePlugin", "primitiveFileRename", NULL },
{ "FilePlugin", "primitiveDirectoryCreate", NULL },
{ "FilePlugin", "primitiveDirectoryDelimitor", NULL },
{ "FilePlugin", "primitiveDirectoryLookup", NULL },
{ "FilePlugin", "primitiveDirectoryDelete", NULL },
{ "FilePlugin", "primitiveDirectoryGetMacTypeAndCreator", NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ "FilePlugin", "primitiveDirectorySetMacTypeAndCreator", NULL },
{ "SoundPlugin", "primitiveSoundStart", NULL },
{ "SoundPlugin", "primitiveSoundStartWithSemaphore", NULL },
{ "SoundPlugin", "primitiveSoundStop", NULL },
{ "SoundPlugin", "primitiveSoundAvailableSpace", NULL },
{ "SoundPlugin", "primitiveSoundPlaySamples", NULL },
{ "SoundPlugin", "primitiveSoundPlaySilence", NULL },
{ "SoundGenerationPlugin", "primitiveWaveTableSoundMix", NULL },
{ "SoundGenerationPlugin", "primitiveFMSoundMix", NULL },
{ "SoundGenerationPlugin", "primitivePluckedSoundMix", NULL },
{ "SoundGenerationPlugin", "primitiveSampledSoundMix", NULL },
{ "SoundGenerationPlugin", "primitiveMixFMSound", NULL },
{ "SoundGenerationPlugin", "primitiveMixPluckedSound", NULL },
{ "SoundGenerationPlugin", "primitiveOldSampledSoundMix", NULL },
{ "SoundGenerationPlugin", "primitiveApplyReverb", NULL },
{ "SoundGenerationPlugin", "primitiveMixLoopedSampledSound", NULL },
{ "SoundGenerationPlugin", "primitiveMixSampledSound", NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ "SoundPlugin", "primitiveSoundInsertSamples", NULL },
{ "SoundPlugin", "primitiveSoundStartRecording", NULL },
{ "SoundPlugin", "primitiveSoundStopRecording", NULL },
{ "SoundPlugin", "primitiveSoundGetRecordingSampleRate", NULL },
{ "SoundPlugin", "primitiveSoundRecordSamples", NULL },
{ "SoundPlugin", "primitiveSoundSetRecordLevel", NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ "SocketPlugin", "primitiveInitializeNetwork", NULL },
{ "SocketPlugin", "primitiveResolverStartNameLookup", NULL },
{ "SocketPlugin", "primitiveResolverNameLookupResult", NULL },
{ "SocketPlugin", "primitiveResolverStartAddressLookup", NULL },
{ "SocketPlugin", "primitiveResolverAddressLookupResult", NULL },
{ "SocketPlugin", "primitiveResolverAbortLookup", NULL },
{ "SocketPlugin", "primitiveResolverLocalAddress", NULL },
{ "SocketPlugin", "primitiveResolverStatus", NULL },
{ "SocketPlugin", "primitiveResolverError", NULL },
{ "SocketPlugin", "primitiveSocketCreate", NULL },
{ "SocketPlugin", "primitiveSocketDestroy", NULL },
{ "SocketPlugin", "primitiveSocketConnectionStatus", NULL },
{ "SocketPlugin", "primitiveSocketError", NULL },
{ "SocketPlugin", "primitiveSocketLocalAddress", NULL },
{ "SocketPlugin", "primitiveSocketLocalPort", NULL },
{ "SocketPlugin", "primitiveSocketRemoteAddress", NULL },
{ "SocketPlugin", "primitiveSocketRemotePort", NULL },
{ "SocketPlugin", "primitiveSocketConnectToPort", NULL },
{ "SocketPlugin", "primitiveSocketListenWithOrWithoutBacklog", NULL },
{ "SocketPlugin", "primitiveSocketCloseConnection", NULL },
{ "SocketPlugin", "primitiveSocketAbortConnection", NULL },
{ "SocketPlugin", "primitiveSocketReceiveDataBufCount", NULL },
{ "SocketPlugin", "primitiveSocketReceiveDataAvailable", NULL },
{ "SocketPlugin", "primitiveSocketSendDataBufCount", NULL },
{ "SocketPlugin", "primitiveSocketSendDone", NULL },
{ "SocketPlugin", "primitiveSocketAccept", NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ "MiscPrimitivePlugin", "primitiveDecompressFromByteArray", NULL },
{ "MiscPrimitivePlugin", "primitiveCompareString", NULL },
{ "MiscPrimitivePlugin", "primitiveConvert8BitSigned", NULL },
{ "MiscPrimitivePlugin", "primitiveCompressToByteArray", NULL },
{ "SerialPlugin", "primitiveSerialPortOpen", NULL },
{ "SerialPlugin", "primitiveSerialPortClose", NULL },
{ "SerialPlugin", "primitiveSerialPortWrite", NULL },
{ "SerialPlugin", "primitiveSerialPortRead", NULL },
{ NULL, NULL, NULL },
{ "MiscPrimitivePlugin", "primitiveTranslateStringWithTable", NULL },
{ "MiscPrimitivePlugin", "primitiveFindFirstInString", NULL },
{ "MiscPrimitivePlugin", "primitiveIndexOfAsciiInString", NULL },
{ "MiscPrimitivePlugin", "primitiveFindSubstring", NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ "MIDIPlugin", "primitiveMIDIClosePort", NULL },
{ "MIDIPlugin", "primitiveMIDIGetClock", NULL },
{ "MIDIPlugin", "primitiveMIDIGetPortCount", NULL },
{ "MIDIPlugin", "primitiveMIDIGetPortDirectionality", NULL },
{ "MIDIPlugin", "primitiveMIDIGetPortName", NULL },
{ "MIDIPlugin", "primitiveMIDIOpenPort", NULL },
{ "MIDIPlugin", "primitiveMIDIParameterGetOrSet", NULL },
{ "MIDIPlugin", "primitiveMIDIRead", NULL },
{ "MIDIPlugin", "primitiveMIDIWrite", NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ "AsynchFilePlugin", "primitiveAsyncFileClose", NULL },
{ "AsynchFilePlugin", "primitiveAsyncFileOpen", NULL },
{ "AsynchFilePlugin", "primitiveAsyncFileReadResult", NULL },
{ "AsynchFilePlugin", "primitiveAsyncFileReadStart", NULL },
{ "AsynchFilePlugin", "primitiveAsyncFileWriteResult", NULL },
{ "AsynchFilePlugin", "primitiveAsyncFileWriteStart", NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ "JoystickTabletPlugin", "primitiveGetTabletParameters", NULL },
{ "JoystickTabletPlugin", "primitiveReadTablet", NULL },
{ "ADPCMCodecPlugin", "primitiveDecodeMono", NULL },
{ "ADPCMCodecPlugin", "primitiveDecodeStereo", NULL },
{ "ADPCMCodecPlugin", "primitiveEncodeMono", NULL },
{ "ADPCMCodecPlugin", "primitiveEncodeStereo", NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL },
{ NULL, NULL, NULL }
};
sqInt imageFormatVersionNumber = 6502;
void* showSurfaceFn;
struct VirtualMachine* interpreterProxy;
void *primitiveTable[577] = {
	/* 0*/ (void *)primitiveFail,
	/* 1*/ (void *)primitiveAdd,
	/* 2*/ (void *)primitiveSubtract,
	/* 3*/ (void *)primitiveLessThan,
	/* 4*/ (void *)primitiveGreaterThan,
	/* 5*/ (void *)primitiveLessOrEqual,
	/* 6*/ (void *)primitiveGreaterOrEqual,
	/* 7*/ (void *)primitiveEqual,
	/* 8*/ (void *)primitiveNotEqual,
	/* 9*/ (void *)primitiveMultiply,
	/* 10*/ (void *)primitiveDivide,
	/* 11*/ (void *)primitiveMod,
	/* 12*/ (void *)primitiveDiv,
	/* 13*/ (void *)primitiveQuo,
	/* 14*/ (void *)primitiveBitAnd,
	/* 15*/ (void *)primitiveBitOr,
	/* 16*/ (void *)primitiveBitXor,
	/* 17*/ (void *)primitiveBitShift,
	/* 18*/ (void *)primitiveMakePoint,
	/* 19*/ (void *)primitiveFail,
	/* 20*/ (void *)primitiveFail,
	/* 21*/ (void *)primitiveFail,
	/* 22*/ (void *)primitiveFail,
	/* 23*/ (void *)primitiveFail,
	/* 24*/ (void *)primitiveFail,
	/* 25*/ (void *)primitiveFail,
	/* 26*/ (void *)primitiveFail,
	/* 27*/ (void *)primitiveFail,
	/* 28*/ (void *)primitiveFail,
	/* 29*/ (void *)primitiveFail,
	/* 30*/ (void *)primitiveFail,
	/* 31*/ (void *)primitiveFail,
	/* 32*/ (void *)primitiveFail,
	/* 33*/ (void *)primitiveFail,
	/* 34*/ (void *)primitiveFail,
	/* 35*/ (void *)primitiveFail,
	/* 36*/ (void *)primitiveFail,
	/* 37*/ (void *)primitiveFail,
	/* 38*/ (void *)primitiveFail,
	/* 39*/ (void *)primitiveFail,
	/* 40*/ (void *)primitiveAsFloat,
	/* 41*/ (void *)primitiveFloatAdd,
	/* 42*/ (void *)primitiveFloatSubtract,
	/* 43*/ (void *)primitiveFloatLessThan,
	/* 44*/ (void *)primitiveFloatGreaterThan,
	/* 45*/ (void *)primitiveFloatLessOrEqual,
	/* 46*/ (void *)primitiveFloatGreaterOrEqual,
	/* 47*/ (void *)primitiveFloatEqual,
	/* 48*/ (void *)primitiveFloatNotEqual,
	/* 49*/ (void *)primitiveFloatMultiply,
	/* 50*/ (void *)primitiveFloatDivide,
	/* 51*/ (void *)primitiveTruncated,
	/* 52*/ (void *)primitiveFractionalPart,
	/* 53*/ (void *)primitiveExponent,
	/* 54*/ (void *)primitiveTimesTwoPower,
	/* 55*/ (void *)primitiveSquareRoot,
	/* 56*/ (void *)primitiveSine,
	/* 57*/ (void *)primitiveArctan,
	/* 58*/ (void *)primitiveLogN,
	/* 59*/ (void *)primitiveExp,
	/* 60*/ (void *)primitiveAt,
	/* 61*/ (void *)primitiveAtPut,
	/* 62*/ (void *)primitiveSize,
	/* 63*/ (void *)primitiveStringAt,
	/* 64*/ (void *)primitiveStringAtPut,
	/* 65*/ (void *)primitiveNext,
	/* 66*/ (void *)primitiveNextPut,
	/* 67*/ (void *)primitiveAtEnd,
	/* 68*/ (void *)primitiveObjectAt,
	/* 69*/ (void *)primitiveObjectAtPut,
	/* 70*/ (void *)primitiveNew,
	/* 71*/ (void *)primitiveNewWithArg,
	/* 72*/ (void *)primitiveArrayBecomeOneWay,
	/* 73*/ (void *)primitiveInstVarAt,
	/* 74*/ (void *)primitiveInstVarAtPut,
	/* 75*/ (void *)primitiveAsOop,
	/* 76*/ (void *)primitiveStoreStackp,
	/* 77*/ (void *)primitiveSomeInstance,
	/* 78*/ (void *)primitiveNextInstance,
	/* 79*/ (void *)primitiveNewMethod,
	/* 80*/ (void *)primitiveBlockCopy,
	/* 81*/ (void *)primitiveValue,
	/* 82*/ (void *)primitiveValueWithArgs,
	/* 83*/ (void *)primitivePerform,
	/* 84*/ (void *)primitivePerformWithArgs,
	/* 85*/ (void *)primitiveSignal,
	/* 86*/ (void *)primitiveWait,
	/* 87*/ (void *)primitiveResume,
	/* 88*/ (void *)primitiveSuspend,
	/* 89*/ (void *)primitiveFlushCache,
	/* 90*/ (void *)primitiveMousePoint,
	/* 91*/ (void *)primitiveTestDisplayDepth,
	/* 92*/ (void *)primitiveSetDisplayMode,
	/* 93*/ (void *)primitiveInputSemaphore,
	/* 94*/ (void *)primitiveGetNextEvent,
	/* 95*/ (void *)primitiveInputWord,
	/* 96*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 97*/ (void *)primitiveSnapshot,
	/* 98*/ (void *)primitiveStoreImageSegment,
	/* 99*/ (void *)primitiveLoadImageSegment,
	/* 100*/ (void *)primitivePerformInSuperclass,
	/* 101*/ (void *)primitiveBeCursor,
	/* 102*/ (void *)primitiveBeDisplay,
	/* 103*/ (void *)primitiveScanCharacters,
	/* 104*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 105*/ (void *)primitiveStringReplace,
	/* 106*/ (void *)primitiveScreenSize,
	/* 107*/ (void *)primitiveMouseButtons,
	/* 108*/ (void *)primitiveKbdNext,
	/* 109*/ (void *)primitiveKbdPeek,
	/* 110*/ (void *)primitiveEquivalent,
	/* 111*/ (void *)primitiveClass,
	/* 112*/ (void *)primitiveBytesLeft,
	/* 113*/ (void *)primitiveQuit,
	/* 114*/ (void *)primitiveExitToDebugger,
	/* 115*/ (void *)primitiveChangeClass,
	/* 116*/ (void *)primitiveFlushCacheByMethod,
	/* 117*/ (void *)primitiveExternalCall,
	/* 118*/ (void *)primitiveDoPrimitiveWithArgs,
	/* 119*/ (void *)primitiveFlushCacheSelective,
	/* 120*/ (void *)primitiveCalloutToFFI,
	/* 121*/ (void *)primitiveImageName,
	/* 122*/ (void *)primitiveNoop,
	/* 123*/ (void *)primitiveValueUninterruptably,
	/* 124*/ (void *)primitiveLowSpaceSemaphore,
	/* 125*/ (void *)primitiveSignalAtBytesLeft,
	/* 126*/ (void *)primitiveDeferDisplayUpdates,
	/* 127*/ (void *)primitiveShowDisplayRect,
	/* 128*/ (void *)primitiveArrayBecome,
	/* 129*/ (void *)primitiveSpecialObjectsOop,
	/* 130*/ (void *)primitiveFullGC,
	/* 131*/ (void *)primitiveIncrementalGC,
	/* 132*/ (void *)primitiveObjectPointsTo,
	/* 133*/ (void *)primitiveSetInterruptKey,
	/* 134*/ (void *)primitiveInterruptSemaphore,
	/* 135*/ (void *)primitiveMillisecondClock,
	/* 136*/ (void *)primitiveSignalAtMilliseconds,
	/* 137*/ (void *)primitiveSecondsClock,
	/* 138*/ (void *)primitiveSomeObject,
	/* 139*/ (void *)primitiveNextObject,
	/* 140*/ (void *)primitiveBeep,
	/* 141*/ (void *)primitiveClipboardText,
	/* 142*/ (void *)primitiveVMPath,
	/* 143*/ (void *)primitiveShortAt,
	/* 144*/ (void *)primitiveShortAtPut,
	/* 145*/ (void *)primitiveConstantFill,
	/* 146*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 147*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 148*/ (void *)primitiveClone,
	/* 149*/ (void *)primitiveGetAttribute,
	/* 150*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 151*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 152*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 153*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 154*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 155*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 156*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 157*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 158*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 159*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 160*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 161*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 162*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 163*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 164*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 165*/ (void *)primitiveIntegerAt,
	/* 166*/ (void *)primitiveIntegerAtPut,
	/* 167*/ (void *)primitiveYield,
	/* 168*/ (void *)primitiveCopyObject,
	/* 169*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 170*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 171*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 172*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 173*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 174*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 175*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 176*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 177*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 178*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 179*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 180*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 181*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 182*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 183*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 184*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 185*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 186*/ (void *)primitiveFail,
	/* 187*/ (void *)primitiveFail,
	/* 188*/ (void *)primitiveExecuteMethodArgsArray,
	/* 189*/ (void *)primitiveExecuteMethod,
	/* 190*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 191*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 192*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 193*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 194*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 195*/ (void *)primitiveFindNextUnwindContext,
	/* 196*/ (void *)primitiveTerminateTo,
	/* 197*/ (void *)primitiveFindHandlerContext,
	/* 198*/ (void *)primitiveMarkUnwindMethod,
	/* 199*/ (void *)primitiveMarkHandlerMethod,
	/* 200*/ (void *)primitiveClosureCopyWithCopiedValues,
	/* 201*/ (void *)primitiveClosureValue,
	/* 202*/ (void *)primitiveClosureValue,
	/* 203*/ (void *)primitiveClosureValue,
	/* 204*/ (void *)primitiveClosureValue,
	/* 205*/ (void *)primitiveClosureValue,
	/* 206*/ (void *)primitiveClosureValueWithArgs,
	/* 207*/ (void *)primitiveFail,
	/* 208*/ (void *)primitiveFail,
	/* 209*/ (void *)primitiveFail,
	/* 210*/ (void *)primitiveAt,
	/* 211*/ (void *)primitiveAtPut,
	/* 212*/ (void *)primitiveSize,
	/* 213*/ (void *)primitiveFail,
	/* 214*/ (void *)primitiveFail,
	/* 215*/ (void *)primitiveFail,
	/* 216*/ (void *)primitiveFail,
	/* 217*/ (void *)primitiveFail,
	/* 218*/ (void *)primitiveDoNamedPrimitiveWithArgs,
	/* 219*/ (void *)primitiveFail,
	/* 220*/ (void *)primitiveFail,
	/* 221*/ (void *)primitiveClosureValueNoContextSwitch,
	/* 222*/ (void *)primitiveClosureValueNoContextSwitch,
	/* 223*/ (void *)primitiveFail,
	/* 224*/ (void *)primitiveFail,
	/* 225*/ (void *)primitiveFail,
	/* 226*/ (void *)primitiveFail,
	/* 227*/ (void *)primitiveFail,
	/* 228*/ (void *)primitiveFail,
	/* 229*/ (void *)primitiveFail,
	/* 230*/ (void *)primitiveRelinquishProcessor,
	/* 231*/ (void *)primitiveForceDisplayUpdate,
	/* 232*/ (void *)primitiveFormPrint,
	/* 233*/ (void *)primitiveSetFullScreen,
	/* 234*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 235*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 236*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 237*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 238*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 239*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 240*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 241*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 242*/ (void *)primitiveFail,
	/* 243*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 244*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 245*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 246*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 247*/ (void *)primitiveSnapshotEmbedded,
	/* 248*/ (void *)primitiveInvokeObjectAsMethod,
	/* 249*/ (void *)primitiveArrayBecomeOneWayCopyHash,
	/* 250*/ (void *)clearProfile,
	/* 251*/ (void *)dumpProfile,
	/* 252*/ (void *)startProfiling,
	/* 253*/ (void *)stopProfiling,
	/* 254*/ (void *)primitiveVMParameter,
	/* 255*/ (void *)primitiveInstVarsPutFromStack,
	/* 256*/ (void *)primitivePushSelf,
	/* 257*/ (void *)primitivePushTrue,
	/* 258*/ (void *)primitivePushFalse,
	/* 259*/ (void *)primitivePushNil,
	/* 260*/ (void *)primitivePushMinusOne,
	/* 261*/ (void *)primitivePushZero,
	/* 262*/ (void *)primitivePushOne,
	/* 263*/ (void *)primitivePushTwo,
	/* 264*/ (void *)primitiveLoadInstVar,
	/* 265*/ (void *)primitiveLoadInstVar,
	/* 266*/ (void *)primitiveLoadInstVar,
	/* 267*/ (void *)primitiveLoadInstVar,
	/* 268*/ (void *)primitiveLoadInstVar,
	/* 269*/ (void *)primitiveLoadInstVar,
	/* 270*/ (void *)primitiveLoadInstVar,
	/* 271*/ (void *)primitiveLoadInstVar,
	/* 272*/ (void *)primitiveLoadInstVar,
	/* 273*/ (void *)primitiveLoadInstVar,
	/* 274*/ (void *)primitiveLoadInstVar,
	/* 275*/ (void *)primitiveLoadInstVar,
	/* 276*/ (void *)primitiveLoadInstVar,
	/* 277*/ (void *)primitiveLoadInstVar,
	/* 278*/ (void *)primitiveLoadInstVar,
	/* 279*/ (void *)primitiveLoadInstVar,
	/* 280*/ (void *)primitiveLoadInstVar,
	/* 281*/ (void *)primitiveLoadInstVar,
	/* 282*/ (void *)primitiveLoadInstVar,
	/* 283*/ (void *)primitiveLoadInstVar,
	/* 284*/ (void *)primitiveLoadInstVar,
	/* 285*/ (void *)primitiveLoadInstVar,
	/* 286*/ (void *)primitiveLoadInstVar,
	/* 287*/ (void *)primitiveLoadInstVar,
	/* 288*/ (void *)primitiveLoadInstVar,
	/* 289*/ (void *)primitiveLoadInstVar,
	/* 290*/ (void *)primitiveLoadInstVar,
	/* 291*/ (void *)primitiveLoadInstVar,
	/* 292*/ (void *)primitiveLoadInstVar,
	/* 293*/ (void *)primitiveLoadInstVar,
	/* 294*/ (void *)primitiveLoadInstVar,
	/* 295*/ (void *)primitiveLoadInstVar,
	/* 296*/ (void *)primitiveLoadInstVar,
	/* 297*/ (void *)primitiveLoadInstVar,
	/* 298*/ (void *)primitiveLoadInstVar,
	/* 299*/ (void *)primitiveLoadInstVar,
	/* 300*/ (void *)primitiveLoadInstVar,
	/* 301*/ (void *)primitiveLoadInstVar,
	/* 302*/ (void *)primitiveLoadInstVar,
	/* 303*/ (void *)primitiveLoadInstVar,
	/* 304*/ (void *)primitiveLoadInstVar,
	/* 305*/ (void *)primitiveLoadInstVar,
	/* 306*/ (void *)primitiveLoadInstVar,
	/* 307*/ (void *)primitiveLoadInstVar,
	/* 308*/ (void *)primitiveLoadInstVar,
	/* 309*/ (void *)primitiveLoadInstVar,
	/* 310*/ (void *)primitiveLoadInstVar,
	/* 311*/ (void *)primitiveLoadInstVar,
	/* 312*/ (void *)primitiveLoadInstVar,
	/* 313*/ (void *)primitiveLoadInstVar,
	/* 314*/ (void *)primitiveLoadInstVar,
	/* 315*/ (void *)primitiveLoadInstVar,
	/* 316*/ (void *)primitiveLoadInstVar,
	/* 317*/ (void *)primitiveLoadInstVar,
	/* 318*/ (void *)primitiveLoadInstVar,
	/* 319*/ (void *)primitiveLoadInstVar,
	/* 320*/ (void *)primitiveLoadInstVar,
	/* 321*/ (void *)primitiveLoadInstVar,
	/* 322*/ (void *)primitiveLoadInstVar,
	/* 323*/ (void *)primitiveLoadInstVar,
	/* 324*/ (void *)primitiveLoadInstVar,
	/* 325*/ (void *)primitiveLoadInstVar,
	/* 326*/ (void *)primitiveLoadInstVar,
	/* 327*/ (void *)primitiveLoadInstVar,
	/* 328*/ (void *)primitiveLoadInstVar,
	/* 329*/ (void *)primitiveLoadInstVar,
	/* 330*/ (void *)primitiveLoadInstVar,
	/* 331*/ (void *)primitiveLoadInstVar,
	/* 332*/ (void *)primitiveLoadInstVar,
	/* 333*/ (void *)primitiveLoadInstVar,
	/* 334*/ (void *)primitiveLoadInstVar,
	/* 335*/ (void *)primitiveLoadInstVar,
	/* 336*/ (void *)primitiveLoadInstVar,
	/* 337*/ (void *)primitiveLoadInstVar,
	/* 338*/ (void *)primitiveLoadInstVar,
	/* 339*/ (void *)primitiveLoadInstVar,
	/* 340*/ (void *)primitiveLoadInstVar,
	/* 341*/ (void *)primitiveLoadInstVar,
	/* 342*/ (void *)primitiveLoadInstVar,
	/* 343*/ (void *)primitiveLoadInstVar,
	/* 344*/ (void *)primitiveLoadInstVar,
	/* 345*/ (void *)primitiveLoadInstVar,
	/* 346*/ (void *)primitiveLoadInstVar,
	/* 347*/ (void *)primitiveLoadInstVar,
	/* 348*/ (void *)primitiveLoadInstVar,
	/* 349*/ (void *)primitiveLoadInstVar,
	/* 350*/ (void *)primitiveLoadInstVar,
	/* 351*/ (void *)primitiveLoadInstVar,
	/* 352*/ (void *)primitiveLoadInstVar,
	/* 353*/ (void *)primitiveLoadInstVar,
	/* 354*/ (void *)primitiveLoadInstVar,
	/* 355*/ (void *)primitiveLoadInstVar,
	/* 356*/ (void *)primitiveLoadInstVar,
	/* 357*/ (void *)primitiveLoadInstVar,
	/* 358*/ (void *)primitiveLoadInstVar,
	/* 359*/ (void *)primitiveLoadInstVar,
	/* 360*/ (void *)primitiveLoadInstVar,
	/* 361*/ (void *)primitiveLoadInstVar,
	/* 362*/ (void *)primitiveLoadInstVar,
	/* 363*/ (void *)primitiveLoadInstVar,
	/* 364*/ (void *)primitiveLoadInstVar,
	/* 365*/ (void *)primitiveLoadInstVar,
	/* 366*/ (void *)primitiveLoadInstVar,
	/* 367*/ (void *)primitiveLoadInstVar,
	/* 368*/ (void *)primitiveLoadInstVar,
	/* 369*/ (void *)primitiveLoadInstVar,
	/* 370*/ (void *)primitiveLoadInstVar,
	/* 371*/ (void *)primitiveLoadInstVar,
	/* 372*/ (void *)primitiveLoadInstVar,
	/* 373*/ (void *)primitiveLoadInstVar,
	/* 374*/ (void *)primitiveLoadInstVar,
	/* 375*/ (void *)primitiveLoadInstVar,
	/* 376*/ (void *)primitiveLoadInstVar,
	/* 377*/ (void *)primitiveLoadInstVar,
	/* 378*/ (void *)primitiveLoadInstVar,
	/* 379*/ (void *)primitiveLoadInstVar,
	/* 380*/ (void *)primitiveLoadInstVar,
	/* 381*/ (void *)primitiveLoadInstVar,
	/* 382*/ (void *)primitiveLoadInstVar,
	/* 383*/ (void *)primitiveLoadInstVar,
	/* 384*/ (void *)primitiveLoadInstVar,
	/* 385*/ (void *)primitiveLoadInstVar,
	/* 386*/ (void *)primitiveLoadInstVar,
	/* 387*/ (void *)primitiveLoadInstVar,
	/* 388*/ (void *)primitiveLoadInstVar,
	/* 389*/ (void *)primitiveLoadInstVar,
	/* 390*/ (void *)primitiveLoadInstVar,
	/* 391*/ (void *)primitiveLoadInstVar,
	/* 392*/ (void *)primitiveLoadInstVar,
	/* 393*/ (void *)primitiveLoadInstVar,
	/* 394*/ (void *)primitiveLoadInstVar,
	/* 395*/ (void *)primitiveLoadInstVar,
	/* 396*/ (void *)primitiveLoadInstVar,
	/* 397*/ (void *)primitiveLoadInstVar,
	/* 398*/ (void *)primitiveLoadInstVar,
	/* 399*/ (void *)primitiveLoadInstVar,
	/* 400*/ (void *)primitiveLoadInstVar,
	/* 401*/ (void *)primitiveLoadInstVar,
	/* 402*/ (void *)primitiveLoadInstVar,
	/* 403*/ (void *)primitiveLoadInstVar,
	/* 404*/ (void *)primitiveLoadInstVar,
	/* 405*/ (void *)primitiveLoadInstVar,
	/* 406*/ (void *)primitiveLoadInstVar,
	/* 407*/ (void *)primitiveLoadInstVar,
	/* 408*/ (void *)primitiveLoadInstVar,
	/* 409*/ (void *)primitiveLoadInstVar,
	/* 410*/ (void *)primitiveLoadInstVar,
	/* 411*/ (void *)primitiveLoadInstVar,
	/* 412*/ (void *)primitiveLoadInstVar,
	/* 413*/ (void *)primitiveLoadInstVar,
	/* 414*/ (void *)primitiveLoadInstVar,
	/* 415*/ (void *)primitiveLoadInstVar,
	/* 416*/ (void *)primitiveLoadInstVar,
	/* 417*/ (void *)primitiveLoadInstVar,
	/* 418*/ (void *)primitiveLoadInstVar,
	/* 419*/ (void *)primitiveLoadInstVar,
	/* 420*/ (void *)primitiveLoadInstVar,
	/* 421*/ (void *)primitiveLoadInstVar,
	/* 422*/ (void *)primitiveLoadInstVar,
	/* 423*/ (void *)primitiveLoadInstVar,
	/* 424*/ (void *)primitiveLoadInstVar,
	/* 425*/ (void *)primitiveLoadInstVar,
	/* 426*/ (void *)primitiveLoadInstVar,
	/* 427*/ (void *)primitiveLoadInstVar,
	/* 428*/ (void *)primitiveLoadInstVar,
	/* 429*/ (void *)primitiveLoadInstVar,
	/* 430*/ (void *)primitiveLoadInstVar,
	/* 431*/ (void *)primitiveLoadInstVar,
	/* 432*/ (void *)primitiveLoadInstVar,
	/* 433*/ (void *)primitiveLoadInstVar,
	/* 434*/ (void *)primitiveLoadInstVar,
	/* 435*/ (void *)primitiveLoadInstVar,
	/* 436*/ (void *)primitiveLoadInstVar,
	/* 437*/ (void *)primitiveLoadInstVar,
	/* 438*/ (void *)primitiveLoadInstVar,
	/* 439*/ (void *)primitiveLoadInstVar,
	/* 440*/ (void *)primitiveLoadInstVar,
	/* 441*/ (void *)primitiveLoadInstVar,
	/* 442*/ (void *)primitiveLoadInstVar,
	/* 443*/ (void *)primitiveLoadInstVar,
	/* 444*/ (void *)primitiveLoadInstVar,
	/* 445*/ (void *)primitiveLoadInstVar,
	/* 446*/ (void *)primitiveLoadInstVar,
	/* 447*/ (void *)primitiveLoadInstVar,
	/* 448*/ (void *)primitiveLoadInstVar,
	/* 449*/ (void *)primitiveLoadInstVar,
	/* 450*/ (void *)primitiveLoadInstVar,
	/* 451*/ (void *)primitiveLoadInstVar,
	/* 452*/ (void *)primitiveLoadInstVar,
	/* 453*/ (void *)primitiveLoadInstVar,
	/* 454*/ (void *)primitiveLoadInstVar,
	/* 455*/ (void *)primitiveLoadInstVar,
	/* 456*/ (void *)primitiveLoadInstVar,
	/* 457*/ (void *)primitiveLoadInstVar,
	/* 458*/ (void *)primitiveLoadInstVar,
	/* 459*/ (void *)primitiveLoadInstVar,
	/* 460*/ (void *)primitiveLoadInstVar,
	/* 461*/ (void *)primitiveLoadInstVar,
	/* 462*/ (void *)primitiveLoadInstVar,
	/* 463*/ (void *)primitiveLoadInstVar,
	/* 464*/ (void *)primitiveLoadInstVar,
	/* 465*/ (void *)primitiveLoadInstVar,
	/* 466*/ (void *)primitiveLoadInstVar,
	/* 467*/ (void *)primitiveLoadInstVar,
	/* 468*/ (void *)primitiveLoadInstVar,
	/* 469*/ (void *)primitiveLoadInstVar,
	/* 470*/ (void *)primitiveLoadInstVar,
	/* 471*/ (void *)primitiveLoadInstVar,
	/* 472*/ (void *)primitiveLoadInstVar,
	/* 473*/ (void *)primitiveLoadInstVar,
	/* 474*/ (void *)primitiveLoadInstVar,
	/* 475*/ (void *)primitiveLoadInstVar,
	/* 476*/ (void *)primitiveLoadInstVar,
	/* 477*/ (void *)primitiveLoadInstVar,
	/* 478*/ (void *)primitiveLoadInstVar,
	/* 479*/ (void *)primitiveLoadInstVar,
	/* 480*/ (void *)primitiveLoadInstVar,
	/* 481*/ (void *)primitiveLoadInstVar,
	/* 482*/ (void *)primitiveLoadInstVar,
	/* 483*/ (void *)primitiveLoadInstVar,
	/* 484*/ (void *)primitiveLoadInstVar,
	/* 485*/ (void *)primitiveLoadInstVar,
	/* 486*/ (void *)primitiveLoadInstVar,
	/* 487*/ (void *)primitiveLoadInstVar,
	/* 488*/ (void *)primitiveLoadInstVar,
	/* 489*/ (void *)primitiveLoadInstVar,
	/* 490*/ (void *)primitiveLoadInstVar,
	/* 491*/ (void *)primitiveLoadInstVar,
	/* 492*/ (void *)primitiveLoadInstVar,
	/* 493*/ (void *)primitiveLoadInstVar,
	/* 494*/ (void *)primitiveLoadInstVar,
	/* 495*/ (void *)primitiveLoadInstVar,
	/* 496*/ (void *)primitiveLoadInstVar,
	/* 497*/ (void *)primitiveLoadInstVar,
	/* 498*/ (void *)primitiveLoadInstVar,
	/* 499*/ (void *)primitiveLoadInstVar,
	/* 500*/ (void *)primitiveLoadInstVar,
	/* 501*/ (void *)primitiveLoadInstVar,
	/* 502*/ (void *)primitiveLoadInstVar,
	/* 503*/ (void *)primitiveLoadInstVar,
	/* 504*/ (void *)primitiveLoadInstVar,
	/* 505*/ (void *)primitiveLoadInstVar,
	/* 506*/ (void *)primitiveLoadInstVar,
	/* 507*/ (void *)primitiveLoadInstVar,
	/* 508*/ (void *)primitiveLoadInstVar,
	/* 509*/ (void *)primitiveLoadInstVar,
	/* 510*/ (void *)primitiveLoadInstVar,
	/* 511*/ (void *)primitiveLoadInstVar,
	/* 512*/ (void *)primitiveLoadInstVar,
	/* 513*/ (void *)primitiveLoadInstVar,
	/* 514*/ (void *)primitiveLoadInstVar,
	/* 515*/ (void *)primitiveLoadInstVar,
	/* 516*/ (void *)primitiveLoadInstVar,
	/* 517*/ (void *)primitiveLoadInstVar,
	/* 518*/ (void *)primitiveLoadInstVar,
	/* 519*/ (void *)primitiveLoadInstVar,
	/* 520*/ (void *)primitiveFail,
	/* 521*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 522*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 523*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 524*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 525*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 526*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 527*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 528*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 529*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 530*/ (void *)primitiveFail,
	/* 531*/ (void *)primitiveFail,
	/* 532*/ (void *)primitiveFail,
	/* 533*/ (void *)primitiveFail,
	/* 534*/ (void *)primitiveFail,
	/* 535*/ (void *)primitiveFail,
	/* 536*/ (void *)primitiveFail,
	/* 537*/ (void *)primitiveFail,
	/* 538*/ (void *)primitiveFail,
	/* 539*/ (void *)primitiveFail,
	/* 540*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 541*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 542*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 543*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 544*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 545*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 546*/ (void *)primitiveFail,
	/* 547*/ (void *)primitiveFail,
	/* 548*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 549*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 550*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 551*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 552*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 553*/ (void *)primitiveObsoleteIndexedPrimitive,
	/* 554*/ (void *)primitiveFail,
	/* 555*/ (void *)primitiveFail,
	/* 556*/ (void *)primitiveFail,
	/* 557*/ (void *)primitiveFail,
	/* 558*/ (void *)primitiveFail,
	/* 559*/ (void *)primitiveFail,
	/* 560*/ (void *)primitiveFail,
	/* 561*/ (void *)primitiveFail,
	/* 562*/ (void *)primitiveFail,
	/* 563*/ (void *)primitiveFail,
	/* 564*/ (void *)primitiveFail,
	/* 565*/ (void *)primitiveFail,
	/* 566*/ (void *)primitiveFail,
	/* 567*/ (void *)primitiveFail,
	/* 568*/ (void *)primitiveFail,
	/* 569*/ (void *)primitiveFail,
	/* 570*/ (void *)primitiveFlushExternalPrimitives,
	/* 571*/ (void *)primitiveUnloadModule,
	/* 572*/ (void *)primitiveListBuiltinModule,
	/* 573*/ (void *)primitiveListExternalModule,
	/* 574*/ (void *)primitiveFail,
	/* 575*/ (void *)primitiveFail,
 0 };
usqInt memory;



/*	Return the accessible object following the given object or 
	free chunk in the heap. Return nil when heap is exhausted. */

sqInt accessibleObjectAfter(sqInt oop) {
register struct foo * foo = &fum;
    sqInt obj;
    sqInt sz;
    sqInt header;
    sqInt sz1;
    sqInt header1;

	/* begin objectAfter: */
	if (DoAssertionChecks) {
		if ((((usqInt) oop)) >= (((usqInt) foo->endOfMemory))) {
			error("no objects after the end of memory");
		}
	}
	if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
		sz1 = (longAt(oop)) & AllButTypeMask;
	} else {
		/* begin sizeBitsOf: */
		header1 = longAt(oop);
		if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
			sz1 = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
			goto l2;
		} else {
			sz1 = header1 & SizeMask;
			goto l2;
		}
	l2:	/* end sizeBitsOf: */;
	}
	obj = (oop + sz1) + (foo->headerTypeBytes[(longAt(oop + sz1)) & TypeMask]);
	while ((((usqInt) obj)) < (((usqInt) foo->endOfMemory))) {
		if (!(((longAt(obj)) & TypeMask) == HeaderTypeFree)) {
			return obj;
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) obj)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(obj)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(obj)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(obj);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(obj - (BytesPerWord * 2))) & LongSizeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		obj = (obj + sz) + (foo->headerTypeBytes[(longAt(obj + sz)) & TypeMask]);
	}
	return null;
}


/*	Similar to activateNewMethod but for Closure and newMethod. */

sqInt activateNewClosureMethod(sqInt blockClosure) {
register struct foo * foo = &fum;
    sqInt newContext;
    sqInt where;
    sqInt methodHeader;
    sqInt outerContext;
    sqInt theBlockClosure;
    sqInt closureMethod;
    sqInt i;
    sqInt numCopied;
    sqInt oop;
    sqInt tmp;

	if (DoAssertionChecks) {
		okayOop(blockClosure);
	}
	outerContext = longAt((blockClosure + BaseHeaderSize) + (ClosureOuterContextIndex << ShiftForWord));
	if (DoAssertionChecks) {
		okayOop(outerContext);
	}
	closureMethod = longAt((outerContext + BaseHeaderSize) + (MethodIndex << ShiftForWord));
	methodHeader = longAt((closureMethod + BaseHeaderSize) + (HeaderIndex << ShiftForWord));
	/* begin pushRemappableOop: */
	foo->remapBuffer[foo->remapBufferCount += 1] = blockClosure;

	/* All for one, and one for all! */
	/* allocateOrRecycleContext: may cause a GC; restore blockClosure and refetch outerContext et al */

	newContext = allocateOrRecycleContext(methodHeader & LargeContextBit);
	/* begin popRemappableOop */
	oop = foo->remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	theBlockClosure = oop;
	outerContext = longAt((theBlockClosure + BaseHeaderSize) + (ClosureOuterContextIndex << ShiftForWord));

	/* Assume: newContext will be recorded as a root if necessary by the
	 call to newActiveContext: below, so we can use unchecked stores. */

	numCopied = (fetchWordLengthOf(theBlockClosure)) - ClosureFirstCopiedValueIndex;
	where = newContext + BaseHeaderSize;
	longAtput(where + (SenderIndex << ShiftForWord), foo->activeContext);
	longAtput(where + (InstructionPointerIndex << ShiftForWord), longAt((theBlockClosure + BaseHeaderSize) + (ClosureStartPCIndex << ShiftForWord)));
	longAtput(where + (StackPointerIndex << ShiftForWord), (((foo->argumentCount + numCopied) << 1) | 1));
	longAtput(where + (MethodIndex << ShiftForWord), longAt((outerContext + BaseHeaderSize) + (MethodIndex << ShiftForWord)));
	longAtput(where + (ClosureIndex << ShiftForWord), theBlockClosure);
	longAtput(where + (ReceiverIndex << ShiftForWord), longAt((outerContext + BaseHeaderSize) + (ReceiverIndex << ShiftForWord)));
	for (i = 1; i <= foo->argumentCount; i += 1) {
		longAtput(where + ((ReceiverIndex + i) << ShiftForWord), longAt(foo->stackPointer - ((foo->argumentCount - i) * BytesPerWord)));
	}
	where = (newContext + BaseHeaderSize) + (((ReceiverIndex + 1) + foo->argumentCount) << ShiftForWord);
	for (i = 0; i <= (numCopied - 1); i += 1) {
		longAtput(where + (i << ShiftForWord), longAt((theBlockClosure + BaseHeaderSize) + ((i + ClosureFirstCopiedValueIndex) << ShiftForWord)));
	}
	/* begin pop: */
	foo->stackPointer -= (foo->argumentCount + 1) * BytesPerWord;
	/* begin newActiveContext: */
	/* begin storeContextRegisters: */
	longAtput((foo->activeContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
	longAtput((foo->activeContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), (((((((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) - TempFrameStart) + 1) << 1) | 1));
	if ((((usqInt) newContext)) < (((usqInt) foo->youngStart))) {
		beRootIfOld(newContext);
	}
	foo->activeContext = newContext;
	/* begin fetchContextRegisters: */
	tmp = longAt((newContext + BaseHeaderSize) + (MethodIndex << ShiftForWord));
	if ((tmp & 1)) {
		tmp = longAt((newContext + BaseHeaderSize) + (HomeIndex << ShiftForWord));
		if ((((usqInt) tmp)) < (((usqInt) foo->youngStart))) {
			beRootIfOld(tmp);
		}
	} else {
		tmp = newContext;
	}
	foo->theHomeContext = tmp;
	foo->receiver = longAt((tmp + BaseHeaderSize) + (ReceiverIndex << ShiftForWord));
	foo->method = longAt((tmp + BaseHeaderSize) + (MethodIndex << ShiftForWord));
	tmp = ((longAt((newContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord))) >> 1);
	foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
	tmp = ((longAt((newContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord))) >> 1);
	foo->stackPointer = (newContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * BytesPerWord);
}

sqInt activateNewMethod(void) {
register struct foo * foo = &fum;
    sqInt initialIP;
    sqInt newContext;
    sqInt where;
    sqInt methodHeader;
    sqInt tempCount;
    sqInt i;
    sqInt nilOop;
    sqInt tmp;

	methodHeader = longAt((foo->newMethod + BaseHeaderSize) + (HeaderIndex << ShiftForWord));
	newContext = allocateOrRecycleContext(methodHeader & LargeContextBit);
	initialIP = ((LiteralStart + ((((usqInt) methodHeader) >> 10) & 255)) * BytesPerWord) + 1;

	/* Assume: newContext will be recorded as a root if necessary by the
	 call to newActiveContext: below, so we can use unchecked stores. */

	tempCount = (((usqInt) methodHeader) >> 19) & 63;
	where = newContext + BaseHeaderSize;
	longAtput(where + (SenderIndex << ShiftForWord), foo->activeContext);
	longAtput(where + (InstructionPointerIndex << ShiftForWord), ((initialIP << 1) | 1));
	longAtput(where + (StackPointerIndex << ShiftForWord), ((tempCount << 1) | 1));
	longAtput(where + (MethodIndex << ShiftForWord), foo->newMethod);
	longAtput(where + (ClosureIndex << ShiftForWord), foo->nilObj);
	for (i = 0; i <= foo->argumentCount; i += 1) {
		longAtput(where + ((ReceiverIndex + i) << ShiftForWord), longAt(foo->stackPointer - ((foo->argumentCount - i) * BytesPerWord)));
	}
	nilOop = foo->nilObj;
	for (i = ((foo->argumentCount + 1) + ReceiverIndex); i <= (tempCount + ReceiverIndex); i += 1) {
		longAtput(where + (i << ShiftForWord), nilOop);
	}
	/* begin pop: */
	foo->stackPointer -= (foo->argumentCount + 1) * BytesPerWord;
	foo->reclaimableContextCount += 1;
	/* begin newActiveContext: */
	/* begin storeContextRegisters: */
	longAtput((foo->activeContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
	longAtput((foo->activeContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), (((((((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) - TempFrameStart) + 1) << 1) | 1));
	if ((((usqInt) newContext)) < (((usqInt) foo->youngStart))) {
		beRootIfOld(newContext);
	}
	foo->activeContext = newContext;
	/* begin fetchContextRegisters: */
	tmp = longAt((newContext + BaseHeaderSize) + (MethodIndex << ShiftForWord));
	if ((tmp & 1)) {
		tmp = longAt((newContext + BaseHeaderSize) + (HomeIndex << ShiftForWord));
		if ((((usqInt) tmp)) < (((usqInt) foo->youngStart))) {
			beRootIfOld(tmp);
		}
	} else {
		tmp = newContext;
	}
	foo->theHomeContext = tmp;
	foo->receiver = longAt((tmp + BaseHeaderSize) + (ReceiverIndex << ShiftForWord));
	foo->method = longAt((tmp + BaseHeaderSize) + (MethodIndex << ShiftForWord));
	tmp = ((longAt((newContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord))) >> 1);
	foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
	tmp = ((longAt((newContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord))) >> 1);
	foo->stackPointer = (newContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * BytesPerWord);
}


/*	Add the given variable location to the extra roots table */

EXPORT(sqInt) addGCRoot(sqInt *varLoc) {
register struct foo * foo = &fum;
	if (foo->extraRootCount >= ExtraRootSize) {
		return 0;
	}
	foo->extraRoots[foo->extraRootCount += 1] = varLoc;
	return 1;
}


/*	Add the given entry to the method cache.
	The policy is as follows:
		Look for an empty entry anywhere in the reprobe chain.
		If found, install the new entry there.
		If not found, then install the new entry at the first probe position
			and delete the entries in the rest of the reprobe chain.
		This has two useful purposes:
			If there is active contention over the first slot, the second
				or third will likely be free for reentry after ejection.
			Also, flushing is good when reprobe chains are getting full. */

sqInt addNewMethodToCache(void) {
register struct foo * foo = &fum;
    sqInt p;
    sqInt probe;
    sqInt hash;

	foo->compilerInitialized && (compilerTranslateMethod());

	/* drop low-order zeros from addresses */

	hash = foo->messageSelector ^ foo->lkupClass;
	foo->primitiveFunctionPointer = primitiveTable[foo->primitiveIndex];
	for (p = 0; p <= (CacheProbeMax - 1); p += 1) {
		probe = (((usqInt) hash) >> p) & MethodCacheMask;
		if ((foo->methodCache[probe + MethodCacheSelector]) == 0) {
			foo->methodCache[probe + MethodCacheSelector] = foo->messageSelector;
			foo->methodCache[probe + MethodCacheClass] = foo->lkupClass;
			foo->methodCache[probe + MethodCacheMethod] = foo->newMethod;
			foo->methodCache[probe + MethodCachePrim] = foo->primitiveIndex;
			foo->methodCache[probe + MethodCacheNative] = foo->newNativeMethod;
			foo->methodCache[probe + MethodCachePrimFunction] = (((long) foo->primitiveFunctionPointer));
			return null;
		}
	}

	/* first probe */

	probe = hash & MethodCacheMask;
	foo->methodCache[probe + MethodCacheSelector] = foo->messageSelector;
	foo->methodCache[probe + MethodCacheClass] = foo->lkupClass;
	foo->methodCache[probe + MethodCacheMethod] = foo->newMethod;
	foo->methodCache[probe + MethodCachePrim] = foo->primitiveIndex;
	foo->methodCache[probe + MethodCacheNative] = foo->newNativeMethod;
	foo->methodCache[probe + MethodCachePrimFunction] = (((long) foo->primitiveFunctionPointer));
	for (p = 1; p <= (CacheProbeMax - 1); p += 1) {
		probe = (((usqInt) hash) >> p) & MethodCacheMask;
		foo->methodCache[probe + MethodCacheSelector] = 0;
	}
}


/*	Add the given function address to the external primitive table and return the index where it's stored. This function doesn't need to be fast since it is only called when an external primitive has been looked up (which takes quite a bit of time itself). So there's nothing specifically complicated here.
	Note: Return index will be one-based (ST convention) */

sqInt addToExternalPrimitiveTable(void *functionAddress) {
register struct foo * foo = &fum;
    sqInt i;

	for (i = 0; i <= (MaxExternalPrimitiveTableSize - 1); i += 1) {
		if ((foo->externalPrimitiveTable[i]) == 0) {
			foo->externalPrimitiveTable[i] = functionAddress;
			return i + 1;
		}
	}
	return 0;
}


/*	Adjust all oop references by the given number of bytes. This 
	is done just after reading in an image when the new base 
	address of the object heap is different from the base address 
	in the image. */
/*	di 11/18/2000 - return number of objects found */

sqInt adjustAllOopsBy(sqInt bytesToShift) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt totalObjects;
    sqInt newClassOop;
    sqInt fieldOop;
    sqInt classHeader;
    sqInt fieldAddr;
    sqInt sz;
    sqInt header;

	if (bytesToShift == 0) {
		return 300000;
	}
	totalObjects = 0;
	oop = memory + (foo->headerTypeBytes[(longAt(memory)) & TypeMask]);
	while ((((usqInt) oop)) < (((usqInt) foo->endOfMemory))) {
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			totalObjects += 1;
			/* begin adjustFieldsAndClassOf:by: */
			if (bytesToShift == 0) {
				goto l1;
			}
			fieldAddr = oop + (lastPointerOf(oop));
			while ((((usqInt) fieldAddr)) > (((usqInt) oop))) {
				fieldOop = longAt(fieldAddr);
				if (!((fieldOop & 1))) {
					longAtput(fieldAddr, fieldOop + bytesToShift);
				}
				fieldAddr -= BytesPerWord;
			}
			if (((longAt(oop)) & TypeMask) != HeaderTypeShort) {
				classHeader = longAt(oop - BytesPerWord);
				newClassOop = (classHeader & AllButTypeMask) + bytesToShift;
				longAtput(oop - BytesPerWord, newClassOop | (classHeader & TypeMask));
			}
		l1:	/* end adjustFieldsAndClassOf:by: */;
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) oop)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(oop);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
				goto l2;
			} else {
				sz = header & SizeMask;
				goto l2;
			}
		l2:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz) + (foo->headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	}
	return totalObjects;
}


/*	Return true if all the oops in both arrays, and the arrays 
	themselves, are in the young object space. */

sqInt allYoungand(sqInt array1, sqInt array2) {
register struct foo * foo = &fum;
    sqInt fieldOffset;
    sqInt fmt;
    sqInt sz;
    sqInt methodHeader;
    sqInt contextSize;
    sqInt header;
    sqInt sp;
    sqInt type;
    sqInt header1;

	if ((((usqInt) array1)) < (((usqInt) foo->youngStart))) {
		return 0;
	}
	if ((((usqInt) array2)) < (((usqInt) foo->youngStart))) {
		return 0;
	}
	/* begin lastPointerOf: */
	header = longAt(array1);
	fmt = (((usqInt) header) >> 8) & 15;
	if (fmt <= 4) {
		if ((fmt == 3) && ((((((usqInt) header) >> 12) & 31) == 13) || ((((((usqInt) header) >> 12) & 31) == 14) || (((((usqInt) header) >> 12) & 31) == 4)))) {
			/* begin fetchStackPointerOf: */
			sp = longAt((array1 + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
			if (!((sp & 1))) {
				contextSize = 0;
				goto l1;
			}
			contextSize = (sp >> 1);
		l1:	/* end fetchStackPointerOf: */;
			fieldOffset = (CtxtTempFrameStart + contextSize) * BytesPerWord;
			goto l4;
		}
		/* begin sizeBitsOfSafe: */
		header1 = longAt(array1);
		/* begin rightType: */
		if ((header1 & SizeMask) == 0) {
			type = HeaderTypeSizeAndClass;
			goto l2;
		} else {
			if ((header1 & CompactClassMask) == 0) {
				type = HeaderTypeClass;
				goto l2;
			} else {
				type = HeaderTypeShort;
				goto l2;
			}
		}
	l2:	/* end rightType: */;
		if (type == HeaderTypeSizeAndClass) {
			sz = (longAt(array1 - (BytesPerWord * 2))) & AllButTypeMask;
			goto l3;
		} else {
			sz = header1 & SizeMask;
			goto l3;
		}
	l3:	/* end sizeBitsOfSafe: */;
		fieldOffset = sz - BaseHeaderSize;
		goto l4;
	}
	if (fmt < 12) {
		fieldOffset = 0;
		goto l4;
	}
	methodHeader = longAt(array1 + BaseHeaderSize);
	fieldOffset = (((((usqInt) methodHeader) >> 10) & 255) * BytesPerWord) + BaseHeaderSize;
l4:	/* end lastPointerOf: */;
	while (fieldOffset >= BaseHeaderSize) {
		if ((((usqInt) (longAt(array1 + fieldOffset)))) < (((usqInt) foo->youngStart))) {
			return 0;
		}
		if ((((usqInt) (longAt(array2 + fieldOffset)))) < (((usqInt) foo->youngStart))) {
			return 0;
		}
		fieldOffset -= BytesPerWord;
	}
	return 1;
}


/*	Allocate a chunk of the given size. Sender must be sure that  the requested size includes enough space for the header  word(s).  */
/*	Details: To limit the time per incremental GC, do one every so many allocations. The number is settable via primitiveVMParameter to tune your memory system */

sqInt allocateChunk(sqInt byteSize) {
register struct foo * foo = &fum;
    sqInt newFreeSize;
    sqInt newChunk;
    sqInt enoughSpace;
    usqInt minFree;
    sqInt lastSavedProcess;
    sqInt currentProc;
    sqInt sched;
    sqInt oop;

	if (foo->allocationCount >= foo->allocationsBetweenGCs) {
		incrementalGC();
	}
	/* begin sufficientSpaceToAllocate: */
	minFree = (foo->lowSpaceThreshold + byteSize) + BaseHeaderSize;
	if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((usqInt) minFree))) {
		enoughSpace = 1;
		goto l1;
	} else {
		enoughSpace = sufficientSpaceAfterGC(minFree);
		goto l1;
	}
l1:	/* end sufficientSpaceToAllocate: */;
	if (!(enoughSpace)) {
		foo->signalLowSpace = 1;

		/* disable additional interrupts until lowSpaceThreshold is reset by image */

		foo->lowSpaceThreshold = 0;
		/* begin saveProcessSignalingLowSpace */
		lastSavedProcess = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ProcessSignalingLowSpace << ShiftForWord));
		if (lastSavedProcess == foo->nilObj) {
			sched = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord));
			currentProc = longAt((sched + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
			/* begin storePointer:ofObject:withValue: */
			oop = foo->specialObjectsOop;
			if ((((usqInt) oop)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(oop, currentProc);
			}
			longAtput((oop + BaseHeaderSize) + (ProcessSignalingLowSpace << ShiftForWord), currentProc);
		}
		/* begin forceInterruptCheck */
		foo->interruptCheckCounter = -1000;
		foo->nextPollTick = 0;
	}
	if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) < (((usqInt) (byteSize + BaseHeaderSize)))) {
		error("out of memory");
	}
	newFreeSize = ((longAt(foo->freeBlock)) & AllButTypeMask) - byteSize;
	newChunk = foo->freeBlock;

	/* Assume: client will initialize object header of free chunk, so following is not needed: */
	/* self setSizeOfFree: newChunk to: byteSize. */

	foo->freeBlock += byteSize;
	/* begin setSizeOfFree:to: */
	longAtput(foo->freeBlock, (newFreeSize & AllButTypeMask) | HeaderTypeFree);
	foo->allocationCount += 1;
	return newChunk;
}


/*	Return a recycled context or a newly allocated one if none is available for recycling. */

sqInt allocateOrRecycleContext(sqInt needsLarge) {
register struct foo * foo = &fum;
    sqInt cntxt;

	if (needsLarge == 0) {
		if (foo->freeContexts != NilContext) {
			cntxt = foo->freeContexts;
			foo->freeContexts = longAt((cntxt + BaseHeaderSize) + (0 << ShiftForWord));
			return cntxt;
		}
	} else {
		if (foo->freeLargeContexts != NilContext) {
			cntxt = foo->freeLargeContexts;
			foo->freeLargeContexts = longAt((cntxt + BaseHeaderSize) + (0 << ShiftForWord));
			return cntxt;
		}
	}
	if (needsLarge == 0) {
		cntxt = instantiateContextsizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassMethodContext << ShiftForWord)), SmallContextSize);
	} else {
		cntxt = instantiateContextsizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassMethodContext << ShiftForWord)), LargeContextSize);
	}
	longAtput((cntxt + BaseHeaderSize) + (4 << ShiftForWord), foo->nilObj);
	return cntxt;
}

sqInt argumentCountOf(sqInt methodPointer) {
	return (((usqInt) (longAt((methodPointer + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 25) & 15;
}


/*	Return the address of first indexable field of resulting array object, or fail if the instance variable does not contain an indexable bytes or words object. */
/*	Note: May be called by translated primitive code. */

void * arrayValueOf(sqInt arrayOop) {
	if ((!((arrayOop & 1))) && (((arrayOop & 1) == 0) && (isWordsOrBytesNonInt(arrayOop)))) {
		return pointerForOop(arrayOop + BaseHeaderSize);
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
}


/*	Returns an integer object */

sqInt asciiOfCharacter(sqInt characterObj) {
register struct foo * foo = &fum;
    sqInt ccIndex;
    sqInt cl;

	/* begin assertClassOf:is: */
	if ((characterObj & 1)) {
		foo->successFlag = 0;
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(characterObj))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(characterObj - BaseHeaderSize)) & AllButTypeMask;
	} else {
		cl = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassCharacter << ShiftForWord)))) && foo->successFlag;
l1:	/* end assertClassOf:is: */;
	if (foo->successFlag) {
		return longAt((characterObj + BaseHeaderSize) + (CharacterValueIndex << ShiftForWord));
	} else {
		return ConstZero;
	}
}


/*	Return true if the stack is still balanced after executing primitive primIndex with nArgs args. Delta is 'stackPointer - activeContext' which is a relative measure for the stack pointer (so we don't have to relocate it during the primitive) */

sqInt balancedStackafterPrimitivewithArgs(sqInt delta, sqInt primIdx, sqInt nArgs) {
register struct foo * foo = &fum;
	if ((primIdx >= 81) && (primIdx <= 88)) {
		return 1;
	}
	if (foo->successFlag) {
		return ((foo->stackPointer - foo->activeContext) + (nArgs * BytesPerWord)) == delta;
	}
	return (foo->stackPointer - foo->activeContext) == delta;
}


/*	If this object is old, mark it as a root (because a new object 
	may be stored into it) */

sqInt beRootIfOld(sqInt oop) {
register struct foo * foo = &fum;
    sqInt header;

	if (((((usqInt) oop)) < (((usqInt) foo->youngStart))) && (!((oop & 1)))) {
		/* begin noteAsRoot:headerLoc: */
		header = longAt(oop);
		if ((header & RootBit) == 0) {
			if (foo->rootTableCount < RootTableRedZone) {
				foo->rootTableCount += 1;
				foo->rootTable[foo->rootTableCount] = oop;
				longAtput(oop, header | RootBit);
			} else {
				if (foo->rootTableCount < RootTableSize) {
					foo->rootTableCount += 1;
					foo->rootTable[foo->rootTableCount] = oop;
					longAtput(oop, header | RootBit);
					foo->allocationCount = foo->allocationsBetweenGCs + 1;
				}
			}
		}
	}
}

sqInt becomewith(sqInt array1, sqInt array2) {
	return becomewithtwoWaycopyHash(array1, array2, 1, 1);
}


/*	All references to each object in array1 are swapped with all references to the corresponding object in array2. That is, all pointers to one object are replaced with with pointers to the other. The arguments must be arrays of the same length. 
	Returns true if the primitive succeeds. */
/*	Implementation: Uses forwarding blocks to update references as done in compaction. */

sqInt becomewithtwoWaycopyHash(sqInt array1, sqInt array2, sqInt twoWayFlag, sqInt copyHashFlag) {
register struct foo * foo = &fum;
    sqInt oop2;
    sqInt hdr1;
    sqInt hdr2;
    sqInt fieldOffset;
    sqInt oop1;
    sqInt fwdHeader;
    sqInt fwdBlock;
    sqInt fwdHeader1;
    sqInt fwdBlock1;
    sqInt fmt;
    sqInt sz;
    sqInt methodHeader;
    sqInt contextSize;
    sqInt header;
    sqInt sp;
    sqInt type;
    sqInt header1;
    sqInt oop21;
    sqInt hdr11;
    sqInt fwdBlock2;
    sqInt hdr21;
    sqInt oop11;
    sqInt fwdHeader2;
    sqInt fwdBlock11;

	if (!(((array1 & 1) == 0) && (((((usqInt) (longAt(array1))) >> 8) & 15) == 2))) {
		return 0;
	}
	if (!(((array2 & 1) == 0) && (((((usqInt) (longAt(array2))) >> 8) & 15) == 2))) {
		return 0;
	}
	if (!((lastPointerOf(array1)) == (lastPointerOf(array2)))) {
		return 0;
	}
	if (!(containOnlyOopsand(array1, array2))) {
		return 0;
	}
	if (!(prepareForwardingTableForBecomingwithtwoWay(array1, array2, twoWayFlag))) {
		return 0;
	}
	if (allYoungand(array1, array2)) {
		mapPointersInObjectsFromto(foo->youngStart, foo->endOfMemory);
	} else {
		mapPointersInObjectsFromto(memory, foo->endOfMemory);
	}
	if (twoWayFlag) {
		/* begin restoreHeadersAfterBecoming:with: */
		/* begin lastPointerOf: */
		header = longAt(array1);
		fmt = (((usqInt) header) >> 8) & 15;
		if (fmt <= 4) {
			if ((fmt == 3) && ((((((usqInt) header) >> 12) & 31) == 13) || ((((((usqInt) header) >> 12) & 31) == 14) || (((((usqInt) header) >> 12) & 31) == 4)))) {
				/* begin fetchStackPointerOf: */
				sp = longAt((array1 + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
				if (!((sp & 1))) {
					contextSize = 0;
					goto l1;
				}
				contextSize = (sp >> 1);
			l1:	/* end fetchStackPointerOf: */;
				fieldOffset = (CtxtTempFrameStart + contextSize) * BytesPerWord;
				goto l4;
			}
			/* begin sizeBitsOfSafe: */
			header1 = longAt(array1);
			/* begin rightType: */
			if ((header1 & SizeMask) == 0) {
				type = HeaderTypeSizeAndClass;
				goto l2;
			} else {
				if ((header1 & CompactClassMask) == 0) {
					type = HeaderTypeClass;
					goto l2;
				} else {
					type = HeaderTypeShort;
					goto l2;
				}
			}
		l2:	/* end rightType: */;
			if (type == HeaderTypeSizeAndClass) {
				sz = (longAt(array1 - (BytesPerWord * 2))) & AllButTypeMask;
				goto l3;
			} else {
				sz = header1 & SizeMask;
				goto l3;
			}
		l3:	/* end sizeBitsOfSafe: */;
			fieldOffset = sz - BaseHeaderSize;
			goto l4;
		}
		if (fmt < 12) {
			fieldOffset = 0;
			goto l4;
		}
		methodHeader = longAt(array1 + BaseHeaderSize);
		fieldOffset = (((((usqInt) methodHeader) >> 10) & 255) * BytesPerWord) + BaseHeaderSize;
	l4:	/* end lastPointerOf: */;
		while (fieldOffset >= BaseHeaderSize) {
			oop1 = longAt(array1 + fieldOffset);
			oop2 = longAt(array2 + fieldOffset);
			if (!(oop1 == oop2)) {
				/* begin restoreHeaderOf: */
				fwdHeader = longAt(oop1);
				fwdBlock = (fwdHeader & AllButMarkBitAndTypeMask) << 1;
				if (DoAssertionChecks) {
					if ((fwdHeader & MarkBit) == 0) {
						error("attempting to restore the header of an object that has no forwarding block");
					}
					/* begin fwdBlockValidate: */
					if (!(((((usqInt) fwdBlock)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock & 3) == 0)))) {
						error("invalid fwd table entry");
					}
				}
				longAtput(oop1, longAt(fwdBlock + BytesPerWord));
				/* begin restoreHeaderOf: */
				fwdHeader1 = longAt(oop2);
				fwdBlock1 = (fwdHeader1 & AllButMarkBitAndTypeMask) << 1;
				if (DoAssertionChecks) {
					if ((fwdHeader1 & MarkBit) == 0) {
						error("attempting to restore the header of an object that has no forwarding block");
					}
					/* begin fwdBlockValidate: */
					if (!(((((usqInt) fwdBlock1)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock1)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock1 & 3) == 0)))) {
						error("invalid fwd table entry");
					}
				}
				longAtput(oop2, longAt(fwdBlock1 + BytesPerWord));
				hdr1 = longAt(oop1);
				hdr2 = longAt(oop2);
				longAtput(oop1, (hdr1 & AllButHashBits) | (hdr2 & HashBits));
				longAtput(oop2, (hdr2 & AllButHashBits) | (hdr1 & HashBits));
			}
			fieldOffset -= BytesPerWord;
		}
	} else {
		/* begin restoreHeadersAfterForwardBecome: */
		fwdBlock2 = ((foo->endOfMemory + BaseHeaderSize) + 7) & (WordMask - 7);
		flag("Dan");
		fwdBlock2 += BytesPerWord * 4;
		while ((((usqInt) fwdBlock2)) <= (((usqInt) foo->fwdTableNext))) {
			oop11 = longAt(fwdBlock2 + (BytesPerWord * 2));
			oop21 = longAt(fwdBlock2);
			/* begin restoreHeaderOf: */
			fwdHeader2 = longAt(oop11);
			fwdBlock11 = (fwdHeader2 & AllButMarkBitAndTypeMask) << 1;
			if (DoAssertionChecks) {
				if ((fwdHeader2 & MarkBit) == 0) {
					error("attempting to restore the header of an object that has no forwarding block");
				}
				/* begin fwdBlockValidate: */
				if (!(((((usqInt) fwdBlock11)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock11)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock11 & 3) == 0)))) {
					error("invalid fwd table entry");
				}
			}
			longAtput(oop11, longAt(fwdBlock11 + BytesPerWord));
			if (copyHashFlag) {
				hdr11 = longAt(oop11);
				hdr21 = longAt(oop21);
				longAtput(oop21, (hdr21 & AllButHashBits) | (hdr11 & HashBits));
			}
			fwdBlock2 += BytesPerWord * 4;
		}
	}
	initializeMemoryFirstFree(foo->freeBlock);
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
	foo->nextPollTick = 0;
	return 1;
}

sqInt biasToGrow(void) {
register struct foo * foo = &fum;
    usqInt growSize;

	growSize = (((sqInt) (foo->growHeadroom * 3) >> 1)) - ((longAt(foo->freeBlock)) & AllButTypeMask);
	if (growSize > 0) {
		growObjectMemory(growSize);
	}
}


/*	convert true and false (Smalltalk) to true or false(C) */

sqInt booleanValueOf(sqInt obj) {
register struct foo * foo = &fum;
	if (obj == foo->trueObj) {
		return 1;
	}
	if (obj == foo->falseObj) {
		return 0;
	}
	foo->successFlag = 0;
	return null;
}

sqInt byteSizeOf(sqInt oop) {
    sqInt slots;
    sqInt header;
    sqInt sz;

	flag("Dan");
	if ((oop & 1)) {
		return 0;
	}
	/* begin slotSizeOf: */
	if ((oop & 1)) {
		slots = 0;
		goto l1;
	}
	/* begin lengthOf: */
	header = longAt(oop);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz = header & SizeMask;
	}
	sz -= header & Size4Bit;
	if (((((usqInt) header) >> 8) & 15) <= 4) {
		slots = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
		goto l2;
	}
	if (((((usqInt) header) >> 8) & 15) < 8) {
		slots = ((usqInt) (sz - BaseHeaderSize)) >> 2;
		goto l2;
	} else {
		slots = (sz - BaseHeaderSize) - (((((usqInt) header) >> 8) & 15) & 3);
		goto l2;
	}
	slots = null;
l2:	/* end lengthOf: */;
l1:	/* end slotSizeOf: */;
	if (((((usqInt) (longAt(oop))) >> 8) & 15) >= 8) {
		return slots;
	} else {
		return slots * ( 4);
	}
}


/*	Byte-swap the words of all bytes objects in a range of the 
	image, including Strings, ByteArrays, and CompiledMethods. 
	This returns these objects to their original byte ordering 
	after blindly byte-swapping the entire image. For compiled 
	methods, byte-swap only their bytecodes part. */

sqInt byteSwapByteObjectsFromto(sqInt startOop, sqInt stopAddr) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt methodHeader;
    sqInt wordAddr;
    sqInt fmt;
    sqInt stopAddr1;
    sqInt addr;
    sqInt stopAddr2;
    sqInt addr1;
    sqInt sz;
    sqInt header;

	oop = startOop;
	while ((((usqInt) oop)) < (((usqInt) stopAddr))) {
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			fmt = (((usqInt) (longAt(oop))) >> 8) & 15;
			if (fmt >= 8) {
				wordAddr = oop + BaseHeaderSize;
				if (fmt >= 12) {
					methodHeader = longAt(oop + BaseHeaderSize);
					wordAddr = (wordAddr + BytesPerWord) + (((((usqInt) methodHeader) >> 10) & 255) * BytesPerWord);
				}
				/* begin reverseBytesFrom:to: */
				stopAddr1 = oop + (sizeBitsOf(oop));
				flag("Dan");
				addr = wordAddr;
				while ((((usqInt) addr)) < (((usqInt) stopAddr1))) {
					longAtput(addr, byteSwapped(longAt(addr)));
					addr += BytesPerWord;
				}
			}
			if ((fmt == 6) && (BytesPerWord == 8)) {
				wordAddr = oop + BaseHeaderSize;
				/* begin reverseWordsFrom:to: */
				stopAddr2 = oop + (sizeBitsOf(oop));
				addr1 = wordAddr;
				while ((((usqInt) addr1)) < (((usqInt) stopAddr2))) {
					longAtput(addr1, wordSwapped(longAt(addr1)));
					addr1 += BytesPerWord;
				}
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) oop)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(oop);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz) + (foo->headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	}
}


/*	Answer the given integer with its bytes in the reverse order. */

sqInt byteSwapped(sqInt w) {
	if (BytesPerWord == 4) {
		return ((((((usqInt) w >> 24)) & Byte0Mask) + ((((usqInt) w >> 8)) & Byte1Mask)) + ((((usqInt) w << 8)) & Byte2Mask)) + ((((usqInt) w << 24)) & Byte3Mask);
	} else {
		return ((((((((((usqInt) w << 0)) & Byte0Mask) + ((((usqInt) w << 0)) & Byte1Mask)) + ((((usqInt) w >> 24)) & Byte2Mask)) + ((((usqInt) w >> 8)) & Byte3Mask)) + ((((usqInt) w << 8)) & Byte4Mask)) + ((((usqInt) w << 24)) & Byte5Mask)) + ((((usqInt) w << 0)) & Byte6Mask)) + ((((usqInt) w << 0)) & Byte7Mask);
	}
}


/*	Answer the size of an object memory word in bytes. */

sqInt bytesPerWord(void) {
	return BytesPerWord;
}


/*	Call the external plugin function identified. In the VM this is an address, see 	InterpreterSimulator for it's version.  */

sqInt callExternalPrimitive(void * functionID) {
	dispatchFunctionPointer(functionID);
}


/*	External call into the interpreter */

EXPORT(sqInt) callInterpreter(void) {
	interpret();
}


/*	Re-enter the interpreter for executing a callback */

EXPORT(sqInt) callbackEnter(sqInt *callbackID) {
register struct foo * foo = &fum;
    sqInt result;
    sqInt activeProc;
    sqInt priority;
    sqInt processList;
    sqInt processLists;
    sqInt lastLink;

	if (foo->primitiveIndex == 0) {
		return 0;
	}
	if (foo->jmpDepth >= foo->jmpMax) {
		return 0;
	}

	/* Suspend the currently active process */

	foo->jmpDepth += 1;
	activeProc = longAt(((longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord))) + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
	foo->suspendedCallbacks[foo->jmpDepth] = activeProc;
	foo->suspendedMethods[foo->jmpDepth] = foo->newMethod;
	transferTo(wakeHighestPriority());
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
	foo->nextPollTick = 0;
	result = setjmp(foo->jmpBuf[foo->jmpDepth]);
	if (result == 0) {
		callbackID[0] = foo->jmpDepth;
		interpret();
	}
	activeProc = longAt(((longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord))) + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
	/* begin putToSleep: */
	priority = ((longAt((activeProc + BaseHeaderSize) + (PriorityIndex << ShiftForWord))) >> 1);
	processLists = longAt(((longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord))) + BaseHeaderSize) + (ProcessListsIndex << ShiftForWord));
	processList = longAt((processLists + BaseHeaderSize) + ((priority - 1) << ShiftForWord));
	/* begin addLastLink:toList: */
	if ((longAt((processList + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord))) == foo->nilObj) {
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) processList)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(processList, activeProc);
		}
		longAtput((processList + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord), activeProc);
	} else {
		lastLink = longAt((processList + BaseHeaderSize) + (LastLinkIndex << ShiftForWord));
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) lastLink)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(lastLink, activeProc);
		}
		longAtput((lastLink + BaseHeaderSize) + (NextLinkIndex << ShiftForWord), activeProc);
	}
	/* begin storePointer:ofObject:withValue: */
	if ((((usqInt) processList)) < (((usqInt) foo->youngStart))) {
		possibleRootStoreIntovalue(processList, activeProc);
	}
	longAtput((processList + BaseHeaderSize) + (LastLinkIndex << ShiftForWord), activeProc);
	/* begin storePointer:ofObject:withValue: */
	if ((((usqInt) activeProc)) < (((usqInt) foo->youngStart))) {
		possibleRootStoreIntovalue(activeProc, processList);
	}
	longAtput((activeProc + BaseHeaderSize) + (MyListIndex << ShiftForWord), processList);
	activeProc = foo->suspendedCallbacks[foo->jmpDepth];

	/* see comment above */

	foo->newMethod = foo->suspendedMethods[foo->jmpDepth];
	transferTo(activeProc);
	foo->jmpDepth -= 1;
	return 1;
}


/*	Leave from a previous callback */

EXPORT(sqInt) callbackLeave(sqInt cbID) {
register struct foo * foo = &fum;
	if (foo->primitiveIndex == 0) {
		return 0;
	}
	if (!(cbID == foo->jmpDepth)) {
		return 0;
	}
	if (cbID < 1) {
		return 0;
	}
	longjmp(foo->jmpBuf[foo->jmpDepth], 1);
}


/*	Change the class of the receiver into the class specified by the argument given that the format of the receiver matches the format of the argument. Fail if receiver or argument are SmallIntegers, or the receiver is an instance of a compact class and the argument isn't, or when the argument's class is compact and the receiver isn't, or when the format of the receiver is different from the format of the argument's class, or when the arguments class is fixed and the receiver's size differs from the size that an instance of the argument's class should have. */
/*	Check what the format of the class says */

sqInt changeClassOfto(sqInt rcvr, sqInt argClass) {
register struct foo * foo = &fum;
    sqInt classHdr;
    sqInt byteSize;
    sqInt ccIndex;
    sqInt sizeHiBits;
    sqInt argFormat;
    sqInt rcvrFormat;
    sqInt i;


	/* Low 2 bits are 0 */
	/* Compute the size of instances of the class (used for fixed field classes only) */

	classHdr = (longAt((argClass + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1;
	sizeHiBits = ((usqInt) (classHdr & 393216)) >> 9;
	classHdr = classHdr & 131071;

	/* size in bytes -- low 2 bits are 0 */
	/* Check the receiver's format against that of the class */

	byteSize = (classHdr & SizeMask) + sizeHiBits;
	argFormat = (((usqInt) classHdr) >> 8) & 15;
	rcvrFormat = (((usqInt) (longAt(rcvr))) >> 8) & 15;
	if (!(argFormat == rcvrFormat)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (argFormat < 2) {
		if (!((byteSize - BaseHeaderSize) == (byteSizeOf(rcvr)))) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	if (((longAt(rcvr)) & TypeMask) == HeaderTypeShort) {
		ccIndex = classHdr & CompactClassMask;
		if (ccIndex == 0) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
		longAtput(rcvr, ((longAt(rcvr)) & (~CompactClassMask)) | ccIndex);
	} else {
		longAtput(rcvr - BaseHeaderSize, argClass | ((longAt(rcvr)) & TypeMask));
		if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(rcvr, argClass);
		}
	}
	/* begin flushMethodCache */
	for (i = 1; i <= MethodCacheSize; i += 1) {
		foo->methodCache[i] = 0;
	}
	for (i = 1; i <= AtCacheTotalSize; i += 1) {
		foo->atCache[i] = 0;
	}
}


/*	Arg must lie in range 0-255! */

sqInt characterForAscii(sqInt ascii) {
	return longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CharacterTable << ShiftForWord))) + BaseHeaderSize) + (ascii << ShiftForWord));
}

sqInt characterTable(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (CharacterTable << ShiftForWord));
}


/*	Check for possible interrupts and handle one if necessary. */

sqInt checkForInterrupts(void) {
register struct foo * foo = &fum;
    sqInt now;
    sqInt sema;
    sqInt xSize;
    sqInt xArray;
    sqInt index;
    sqInt i;
    sqInt sema1;

	now = (ioMSecs()) & MillisecondClockMask;
	if (!(foo->interruptCheckCounter < -100)) {
		if ((now - foo->lastTick) < foo->interruptChecksEveryNms) {
			foo->interruptCheckCounterFeedBackReset += 10;
		} else {
			if (foo->interruptCheckCounterFeedBackReset <= 1000) {
				foo->interruptCheckCounterFeedBackReset = 1000;
			} else {
				foo->interruptCheckCounterFeedBackReset -= 12;
			}
		}
	}
	foo->interruptCheckCounter = foo->interruptCheckCounterFeedBackReset;
	if (foo->signalLowSpace) {

		/* reset flag */

		foo->signalLowSpace = 0;
		sema = longAt((foo->specialObjectsOop + BaseHeaderSize) + (TheLowSpaceSemaphore << ShiftForWord));
		if (!(sema == foo->nilObj)) {
			synchronousSignal(sema);
		}
	}
	if (now < foo->lastTick) {
		foo->nextPollTick = (foo->nextPollTick - MillisecondClockMask) - 1;
	}
	if (now >= foo->nextPollTick) {
		ioProcessEvents();

		/* msecs to wait before next call to ioProcessEvents.  
			Note that strictly speaking we might need to update  
			'now' at this point since ioProcessEvents could take a  
			very long time on some platforms */

		foo->nextPollTick = now + 200;
	}
	if (foo->interruptPending) {

		/* reset interrupt flag */

		foo->interruptPending = 0;
		sema = longAt((foo->specialObjectsOop + BaseHeaderSize) + (TheInterruptSemaphore << ShiftForWord));
		if (!(sema == foo->nilObj)) {
			synchronousSignal(sema);
		}
	}
	if (foo->nextWakeupTick != 0) {
		if (now < foo->lastTick) {
			foo->nextWakeupTick = (foo->nextWakeupTick - MillisecondClockMask) - 1;
		}
		if (now >= foo->nextWakeupTick) {

			/* set timer interrupt to 0 for 'no timer' */

			foo->nextWakeupTick = 0;
			sema = longAt((foo->specialObjectsOop + BaseHeaderSize) + (TheTimerSemaphore << ShiftForWord));
			if (!(sema == foo->nilObj)) {
				synchronousSignal(sema);
			}
		}
	}
	if (foo->pendingFinalizationSignals > 0) {
		sema = longAt((foo->specialObjectsOop + BaseHeaderSize) + (TheFinalizationSemaphore << ShiftForWord));
		if ((fetchClassOf(sema)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassSemaphore << ShiftForWord)))) {
			synchronousSignal(sema);
		}
		foo->pendingFinalizationSignals = 0;
	}
	if ((foo->semaphoresToSignalCountA > 0) || (foo->semaphoresToSignalCountB > 0)) {
		/* begin signalExternalSemaphores */
		foo->semaphoresUseBufferA = !foo->semaphoresUseBufferA;
		xArray = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ExternalObjectsArray << ShiftForWord));
		xSize = stSizeOf(xArray);
		if (foo->semaphoresUseBufferA) {
			for (i = 1; i <= foo->semaphoresToSignalCountB; i += 1) {
				index = foo->semaphoresToSignalB[i];
				if (index <= xSize) {
					sema1 = longAt((xArray + BaseHeaderSize) + ((index - 1) << ShiftForWord));
					if ((fetchClassOf(sema1)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassSemaphore << ShiftForWord)))) {
						synchronousSignal(sema1);
					}
				}
			}
			foo->semaphoresToSignalCountB = 0;
		} else {
			for (i = 1; i <= foo->semaphoresToSignalCountA; i += 1) {
				index = foo->semaphoresToSignalA[i];
				if (index <= xSize) {
					sema1 = longAt((xArray + BaseHeaderSize) + ((index - 1) << ShiftForWord));
					if ((fetchClassOf(sema1)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassSemaphore << ShiftForWord)))) {
						synchronousSignal(sema1);
					}
				}
			}
			foo->semaphoresToSignalCountA = 0;
		}
	}
	foo->lastTick = now;
}


/*	Read and verify the image file version number and return true if the the given image file needs to be byte-swapped. As a side effect, position the file stream just after the version number of the image header. This code prints a warning and does a hard-exit if it cannot find a valid version number. */
/*	This code is based on C code by Ian Piumarta. */

sqInt checkImageVersionFromstartingAt(sqImageFile  f, squeakFileOffsetType  imageOffset) {
    sqInt version;
    sqInt firstVersion;

	sqImageFileSeek(f, imageOffset);
	version = firstVersion = getLongFromFileswap(f, 0);
	if ((version == imageFormatVersionNumber) || ((version == (imageFormatForwardCompatibilityVersion())) || (version == (imageFormatBackwardCompatibilityVersion())))) {
		return 0;
	}
	sqImageFileSeek(f, imageOffset);
	version = getLongFromFileswap(f, 1);
	if ((version == imageFormatVersionNumber) || ((version == (imageFormatForwardCompatibilityVersion())) || (version == (imageFormatBackwardCompatibilityVersion())))) {
		return 1;
	}
	if (imageOffset == 0) {
		sqImageFileSeek(f, 512);
		version = getLongFromFileswap(f, 0);
		if ((version == imageFormatVersionNumber) || ((version == (imageFormatForwardCompatibilityVersion())) || (version == (imageFormatBackwardCompatibilityVersion())))) {
			return 0;
		}
		sqImageFileSeek(f, 512);
		version = getLongFromFileswap(f, 1);
		if ((version == imageFormatVersionNumber) || ((version == (imageFormatForwardCompatibilityVersion())) || (version == (imageFormatBackwardCompatibilityVersion())))) {
			return 1;
		}
	}
	print("This interpreter (vers. ");
	printNum(imageFormatVersionNumber);
	print(") cannot read image file (vers. ");
	printNum(firstVersion);
	print(").");
	/* begin cr */
	printf("\n");
	print("Press CR to quit...");
	getchar();
	ioExit();
}


/*	Note: May be called by translated primitive code. */

sqInt checkedIntegerValueOf(sqInt intOop) {
	if ((intOop & 1)) {
		return (intOop >> 1);
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return 0;
	}
}


/*	Assumes zero-based array indexing. For testing in Smalltalk, this method should be overridden in a subclass. */

sqInt checkedLongAt(sqInt byteAddress) {
register struct foo * foo = &fum;
	/* begin checkAddress: */
	if ((((usqInt) byteAddress)) < (((usqInt) memory))) {
		error("bad address: negative");
	}
	if ((((usqInt) byteAddress)) >= (((usqInt) foo->memoryLimit))) {
		error("bad address: past end of heap");
	}
	/* begin checkAddress: */
	if ((((usqInt) (byteAddress + 3))) < (((usqInt) memory))) {
		error("bad address: negative");
	}
	if ((((usqInt) (byteAddress + 3))) >= (((usqInt) foo->memoryLimit))) {
		error("bad address: past end of heap");
	}
	return longAt(byteAddress);
}

sqInt classArray(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassArray << ShiftForWord));
}

sqInt classBitmap(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassBitmap << ShiftForWord));
}

sqInt classByteArray(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassByteArray << ShiftForWord));
}

sqInt classCharacter(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassCharacter << ShiftForWord));
}

sqInt classExternalAddress(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassExternalAddress << ShiftForWord));
}

sqInt classExternalData(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassExternalData << ShiftForWord));
}

sqInt classExternalFunction(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassExternalFunction << ShiftForWord));
}

sqInt classExternalLibrary(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassExternalLibrary << ShiftForWord));
}

sqInt classExternalStructure(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassExternalStructure << ShiftForWord));
}

sqInt classFloat(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord));
}

sqInt classLargeNegativeInteger(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargeNegativeInteger << ShiftForWord));
}

sqInt classLargePositiveInteger(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargePositiveInteger << ShiftForWord));
}


/*	Check if aClass's name is className */

sqInt classNameOfIs(sqInt aClass, char * className) {
    sqInt length;
    char * srcName;
    sqInt name;
    sqInt i;

	if ((lengthOf(aClass)) <= 6) {
		return 0;
	}
	name = longAt((aClass + BaseHeaderSize) + (6 << ShiftForWord));
	if (!(((name & 1) == 0) && (((((usqInt) (longAt(name))) >> 8) & 15) >= 8))) {
		return 0;
	}
	length = stSizeOf(name);
	srcName = ((char *) (arrayValueOf(name)));
	for (i = 0; i <= (length - 1); i += 1) {
		if (!((srcName[i]) == (className[i]))) {
			return 0;
		}
	}
	return (className[length]) == 0;
}

sqInt classPoint(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassPoint << ShiftForWord));
}

sqInt classSemaphore(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassSemaphore << ShiftForWord));
}

sqInt classSmallInteger(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
}

sqInt classString(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassString << ShiftForWord));
}


/*	Return a shallow copy of the given object. May cause GC */
/*	Assume: Oop is a real object, not a small integer. */

sqInt clone(sqInt oop) {
register struct foo * foo = &fum;
    sqInt remappedOop;
    usqInt fromIndex;
    usqInt bytes;
    sqInt newChunk;
    sqInt extraHdrBytes;
    sqInt newOop;
    sqInt toIndex;
    usqInt lastFrom;
    sqInt hash;
    sqInt header;
    sqInt oop1;
    sqInt header1;
    sqInt newFreeSize;
    sqInt newChunk1;
    sqInt enoughSpace;
    usqInt minFree;
    sqInt lastSavedProcess;
    sqInt currentProc;
    sqInt sched;
    sqInt oop2;

	extraHdrBytes = foo->headerTypeBytes[(longAt(oop)) & TypeMask];
	/* begin sizeBitsOf: */
	header1 = longAt(oop);
	if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
		bytes = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
		goto l1;
	} else {
		bytes = header1 & SizeMask;
		goto l1;
	}
l1:	/* end sizeBitsOf: */;

	/* allocate space for the copy, remapping oop in case of a GC */

	bytes += extraHdrBytes;
	/* begin pushRemappableOop: */
	foo->remapBuffer[foo->remapBufferCount += 1] = oop;
	if (!(sufficientSpaceToAllocate(2500 + bytes))) {
		return 0;
	}
	/* begin allocateChunk: */
	if (foo->allocationCount >= foo->allocationsBetweenGCs) {
		incrementalGC();
	}
	/* begin sufficientSpaceToAllocate: */
	minFree = (foo->lowSpaceThreshold + bytes) + BaseHeaderSize;
	if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((usqInt) minFree))) {
		enoughSpace = 1;
		goto l2;
	} else {
		enoughSpace = sufficientSpaceAfterGC(minFree);
		goto l2;
	}
l2:	/* end sufficientSpaceToAllocate: */;
	if (!(enoughSpace)) {
		foo->signalLowSpace = 1;
		foo->lowSpaceThreshold = 0;
		/* begin saveProcessSignalingLowSpace */
		lastSavedProcess = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ProcessSignalingLowSpace << ShiftForWord));
		if (lastSavedProcess == foo->nilObj) {
			sched = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord));
			currentProc = longAt((sched + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
			/* begin storePointer:ofObject:withValue: */
			oop2 = foo->specialObjectsOop;
			if ((((usqInt) oop2)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(oop2, currentProc);
			}
			longAtput((oop2 + BaseHeaderSize) + (ProcessSignalingLowSpace << ShiftForWord), currentProc);
		}
		/* begin forceInterruptCheck */
		foo->interruptCheckCounter = -1000;
		foo->nextPollTick = 0;
	}
	if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) < (((usqInt) (bytes + BaseHeaderSize)))) {
		error("out of memory");
	}
	newFreeSize = ((longAt(foo->freeBlock)) & AllButTypeMask) - bytes;
	newChunk1 = foo->freeBlock;
	foo->freeBlock += bytes;
	/* begin setSizeOfFree:to: */
	longAtput(foo->freeBlock, (newFreeSize & AllButTypeMask) | HeaderTypeFree);
	foo->allocationCount += 1;
	newChunk = newChunk1;
	/* begin popRemappableOop */
	oop1 = foo->remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	remappedOop = oop1;

	/* loop below uses pre-increment */

	toIndex = newChunk - BytesPerWord;
	fromIndex = (remappedOop - extraHdrBytes) - BytesPerWord;
	lastFrom = fromIndex + bytes;
	while (fromIndex < lastFrom) {
		longAtput(toIndex += BytesPerWord, longAt(fromIndex += BytesPerWord));
	}

	/* convert from chunk to oop */
	/* fix base header: compute new hash and clear Mark and Root bits */

	newOop = newChunk + extraHdrBytes;
	/* begin newObjectHash */
	foo->lastHash = (13849 + (27181 * foo->lastHash)) & 65535;
	hash = foo->lastHash;

	/* use old ccIndex, format, size, and header-type fields */

	header = (longAt(newOop)) & 131071;
	header = header | ((hash << 17) & 536739840);
	longAtput(newOop, header);
	return newOop;
}


/*	This code is called if the receiver responds primitively to at:.
	If this is so, it will be installed in the atCache so that subsequent calls of at:
	or next may be handled immediately in bytecode primitive routines. */

sqInt commonAt(sqInt stringy) {
register struct foo * foo = &fum;
    sqInt atIx;
    sqInt rcvr;
    sqInt result;
    sqInt index;
    sqInt sp;
    sqInt sp1;


	/* Sets successFlag */

	index = positive32BitValueOf(longAt(foo->stackPointer));
	rcvr = longAt(foo->stackPointer - (1 * BytesPerWord));
	if (!(foo->successFlag && (!((rcvr & 1))))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if ((foo->messageSelector == (longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((16 * 2) << ShiftForWord)))) && (foo->lkupClass == (fetchClassOfNonInt(rcvr)))) {

		/* Index into atCache = 4N, for N = 0 ... 7 */

		atIx = rcvr & AtCacheMask;
		if (!((foo->atCache[atIx + AtCacheOop]) == rcvr)) {
			installinAtCacheatstring(rcvr, foo->atCache, atIx, stringy);
		}
		if (foo->successFlag) {
			result = commonVariableatcacheIndex(rcvr, index, atIx);
		}
		if (foo->successFlag) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * BytesPerWord), result);
			foo->stackPointer = sp;
			return null;
		}
	}
	foo->successFlag = 1;
	result = stObjectat(rcvr, index);
	if (foo->successFlag) {
		if (stringy) {
			result = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CharacterTable << ShiftForWord))) + BaseHeaderSize) + (((result >> 1)) << ShiftForWord));
		}
		/* begin pop:thenPush: */
		longAtput(sp1 = foo->stackPointer - (((foo->argumentCount + 1) - 1) * BytesPerWord), result);
		foo->stackPointer = sp1;
		return null;
	}
}


/*	This code is called if the receiver responds primitively to at:Put:.
	If this is so, it will be installed in the atPutCache so that subsequent calls of at:
	or  next may be handled immediately in bytecode primitive routines. */

sqInt commonAtPut(sqInt stringy) {
register struct foo * foo = &fum;
    sqInt value;
    sqInt atIx;
    sqInt rcvr;
    sqInt index;
    sqInt valToPut;
    sqInt fmt;
    sqInt stSize;
    sqInt fixedFields;
    sqInt sp;
    sqInt sp1;

	value = longAt(foo->stackPointer);

	/* Sets successFlag */

	index = positive32BitValueOf(longAt(foo->stackPointer - (1 * BytesPerWord)));
	rcvr = longAt(foo->stackPointer - (2 * BytesPerWord));
	if (!(foo->successFlag && (!((rcvr & 1))))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if ((foo->messageSelector == (longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((17 * 2) << ShiftForWord)))) && (foo->lkupClass == (fetchClassOfNonInt(rcvr)))) {

		/* Index into atPutCache */

		atIx = (rcvr & AtCacheMask) + AtPutBase;
		if (!((foo->atCache[atIx + AtCacheOop]) == rcvr)) {
			installinAtCacheatstring(rcvr, foo->atCache, atIx, stringy);
		}
		if (foo->successFlag) {
			/* begin commonVariable:at:put:cacheIndex: */
			stSize = foo->atCache[atIx + AtCacheSize];
			if (((((usqInt) index)) >= (((usqInt) 1))) && ((((usqInt) index)) <= (((usqInt) stSize)))) {
				fmt = foo->atCache[atIx + AtCacheFmt];
				if (fmt <= 4) {
					fixedFields = foo->atCache[atIx + AtCacheFixedFields];
					/* begin storePointer:ofObject:withValue: */
					if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
						possibleRootStoreIntovalue(rcvr, value);
					}
					longAtput((rcvr + BaseHeaderSize) + (((index + fixedFields) - 1) << ShiftForWord), value);
					goto l1;
				}
				if (fmt < 8) {
					valToPut = positive32BitValueOf(value);
					if (foo->successFlag) {
						long32Atput((rcvr + BaseHeaderSize) + ((index - 1) << 2), valToPut);
					}
					goto l1;
				}
				if (fmt >= 16) {
					valToPut = asciiOfCharacter(value);
					if (!(foo->successFlag)) {
						goto l1;
					}
				} else {
					valToPut = value;
				}
				if ((valToPut & 1)) {
					valToPut = (valToPut >> 1);
					if (!((valToPut >= 0) && (valToPut <= 255))) {
						/* begin primitiveFail */
						foo->successFlag = 0;
						goto l1;
					}
					byteAtput((rcvr + BaseHeaderSize) + (index - 1), valToPut);
					goto l1;
				}
			}
			/* begin primitiveFail */
			foo->successFlag = 0;
		l1:	/* end commonVariable:at:put:cacheIndex: */;
		}
		if (foo->successFlag) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * BytesPerWord), value);
			foo->stackPointer = sp;
			return null;
		}
	}
	foo->successFlag = 1;
	if (stringy) {
		stObjectatput(rcvr, index, asciiOfCharacter(value));
	} else {
		stObjectatput(rcvr, index, value);
	}
	if (foo->successFlag) {
		/* begin pop:thenPush: */
		longAtput(sp1 = foo->stackPointer - (((foo->argumentCount + 1) - 1) * BytesPerWord), value);
		foo->stackPointer = sp1;
		return null;
	}
}


/*	This code assumes the receiver has been identified at location atIx in the atCache. */

sqInt commonVariableatcacheIndex(sqInt rcvr, sqInt index, sqInt atIx) {
register struct foo * foo = &fum;
    sqInt fmt;
    sqInt result;
    sqInt stSize;
    sqInt fixedFields;

	stSize = foo->atCache[atIx + AtCacheSize];
	if (((((usqInt) index)) >= (((usqInt) 1))) && ((((usqInt) index)) <= (((usqInt) stSize)))) {
		fmt = foo->atCache[atIx + AtCacheFmt];
		if (fmt <= 4) {
			fixedFields = foo->atCache[atIx + AtCacheFixedFields];
			return longAt((rcvr + BaseHeaderSize) + (((index + fixedFields) - 1) << ShiftForWord));
		}
		if (fmt < 8) {
			result = long32At((rcvr + BaseHeaderSize) + ((index - 1) << 2));
			result = positive32BitIntegerFor(result);
			return result;
		}
		if (fmt >= 16) {
			return longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CharacterTable << ShiftForWord))) + BaseHeaderSize) + ((byteAt((rcvr + BaseHeaderSize) + (index - 1))) << ShiftForWord));
		} else {
			return (((byteAt((rcvr + BaseHeaderSize) + (index - 1))) << 1) | 1);
		}
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
}


/*	May set success to false */
/*	First compare two ST integers... */

sqInt compare31or32Bitsequal(sqInt obj1, sqInt obj2) {
	if (((obj1 & 1)) && ((obj2 & 1))) {
		return obj1 == obj2;
	}
	return (positive32BitValueOf(obj1)) == (positive32BitValueOf(obj2));
}

sqInt compilerCreateActualMessagestoringArgs(sqInt aMessage, sqInt argArray) {
	return compilerHooks[14](aMessage, argArray);
}

sqInt compilerFlushCache(sqInt aCompiledMethod) {
	return compilerHooks[2](aCompiledMethod);
}

sqInt compilerMapFromto(sqInt memStart, sqInt memEnd) {
	return compilerHooks[4](memStart, memEnd);
}

sqInt compilerMark(void) {
	return compilerHooks[9]();
}

sqInt compilerPostGC(void) {
	return compilerHooks[5]();
}

sqInt compilerPostSnapshot(void) {
	return compilerHooks[8]();
}

sqInt compilerPreGC(sqInt fullGCFlag) {
	return compilerHooks[3](fullGCFlag);
}

sqInt compilerPreSnapshot(void) {
	return compilerHooks[7]();
}

sqInt compilerProcessChange(void) {
	return compilerHooks[6]();
}

sqInt compilerProcessChangeto(sqInt oldProc, sqInt newProc) {
	return compilerHooks[6](oldProc, newProc);
}

sqInt compilerTranslateMethod(void) {
	return compilerHooks[1]();
}


/*	Return true if neither array contains a small integer. You 
	can't become: integers! */

sqInt containOnlyOopsand(sqInt array1, sqInt array2) {
    sqInt fieldOffset;
    sqInt fmt;
    sqInt sz;
    sqInt methodHeader;
    sqInt contextSize;
    sqInt header;
    sqInt sp;
    sqInt type;
    sqInt header1;

	/* begin lastPointerOf: */
	header = longAt(array1);
	fmt = (((usqInt) header) >> 8) & 15;
	if (fmt <= 4) {
		if ((fmt == 3) && ((((((usqInt) header) >> 12) & 31) == 13) || ((((((usqInt) header) >> 12) & 31) == 14) || (((((usqInt) header) >> 12) & 31) == 4)))) {
			/* begin fetchStackPointerOf: */
			sp = longAt((array1 + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
			if (!((sp & 1))) {
				contextSize = 0;
				goto l1;
			}
			contextSize = (sp >> 1);
		l1:	/* end fetchStackPointerOf: */;
			fieldOffset = (CtxtTempFrameStart + contextSize) * BytesPerWord;
			goto l4;
		}
		/* begin sizeBitsOfSafe: */
		header1 = longAt(array1);
		/* begin rightType: */
		if ((header1 & SizeMask) == 0) {
			type = HeaderTypeSizeAndClass;
			goto l2;
		} else {
			if ((header1 & CompactClassMask) == 0) {
				type = HeaderTypeClass;
				goto l2;
			} else {
				type = HeaderTypeShort;
				goto l2;
			}
		}
	l2:	/* end rightType: */;
		if (type == HeaderTypeSizeAndClass) {
			sz = (longAt(array1 - (BytesPerWord * 2))) & AllButTypeMask;
			goto l3;
		} else {
			sz = header1 & SizeMask;
			goto l3;
		}
	l3:	/* end sizeBitsOfSafe: */;
		fieldOffset = sz - BaseHeaderSize;
		goto l4;
	}
	if (fmt < 12) {
		fieldOffset = 0;
		goto l4;
	}
	methodHeader = longAt(array1 + BaseHeaderSize);
	fieldOffset = (((((usqInt) methodHeader) >> 10) & 255) * BytesPerWord) + BaseHeaderSize;
l4:	/* end lastPointerOf: */;
	while (fieldOffset >= BaseHeaderSize) {
		if (((longAt(array1 + fieldOffset)) & 1)) {
			return 0;
		}
		if (((longAt(array2 + fieldOffset)) & 1)) {
			return 0;
		}
		fieldOffset -= BytesPerWord;
	}
	return 1;
}


/*	Does thisCntx have aContext in its sender chain? */

sqInt contexthasSender(sqInt thisCntx, sqInt aContext) {
    sqInt s;
    sqInt nilOop;

	if (thisCntx == aContext) {
		return 0;
	}
	nilOop = foo->nilObj;
	s = longAt((thisCntx + BaseHeaderSize) + (SenderIndex << ShiftForWord));
	while (!(s == nilOop)) {
		if (s == aContext) {
			return 1;
		}
		s = longAt((s + BaseHeaderSize) + (SenderIndex << ShiftForWord));
	}
	return 0;
}


/*	This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin:=copyBits
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided */

sqInt copyBits(void) {
    void * fn;

	fn = ioLoadFunctionFrom("copyBits", "BitBltPlugin");
	if (fn == 0) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	return ((sqInt (*)(void))fn)();
}


/*	This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin:=copyBitsFrom:to:at:
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided */

sqInt copyBitsFromtoat(sqInt x0, sqInt x1, sqInt y) {
    void * fn;

	fn = ioLoadFunctionFrom("copyBitsFromtoat", "BitBltPlugin");
	if (fn == 0) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	return ((sqInt (*)(sqInt, sqInt, sqInt))fn)(x0, x1, y);
}


/*	Copy this object into the segment beginning at lastSeg.
	Install a forwarding pointer, and save oop and header.
	Fail if out of space.  Return the next segmentAddr if successful. */
/*	Copy the object... */

sqInt copyObjtoSegmentaddrstopAtsaveOopAtheaderAt(sqInt oop, sqInt segmentWordArray, sqInt lastSeg, sqInt stopAddr, sqInt oopPtr, sqInt hdrPtr) {
register struct foo * foo = &fum;
    sqInt bodySize;
    sqInt extraSize;
    sqInt hdrAddr;
    sqInt out;
    sqInt lastIn;
    sqInt in;
    sqInt header;

	flag("Dan");
	if (!(foo->successFlag)) {
		return lastSeg;
	}
	extraSize = foo->headerTypeBytes[(longAt(oop)) & TypeMask];
	/* begin sizeBitsOf: */
	header = longAt(oop);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		bodySize = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
		goto l1;
	} else {
		bodySize = header & SizeMask;
		goto l1;
	}
l1:	/* end sizeBitsOf: */;
	if ((((usqInt) ((lastSeg + extraSize) + bodySize))) >= (((usqInt) stopAddr))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin transfer:from:to: */
	flag("Dan");
	in = (oop - extraSize) - BytesPerWord;
	lastIn = in + ((((sqInt) (extraSize + bodySize) >> 2)) * BytesPerWord);
	out = (lastSeg + BytesPerWord) - BytesPerWord;
	while ((((usqInt) in)) < (((usqInt) lastIn))) {
		longAtput(out += BytesPerWord, longAt(in += BytesPerWord));
	}
	hdrAddr = (lastSeg + BytesPerWord) + extraSize;
	longAtput(hdrAddr, (longAt(hdrAddr)) & (AllButRootBit - MarkBit));
	/* begin forward:to:savingOopAt:andHeaderAt: */
	longAtput(oopPtr, oop);
	longAtput(hdrPtr, longAt(oop));
	longAtput(oop, (((lastSeg + BytesPerWord) + extraSize) - segmentWordArray) + HeaderTypeFree);
	return (lastSeg + extraSize) + bodySize;
}


/*	Bundle up the selector, arguments and lookupClass into a Message object. 
	In the process it pops the arguments off the stack, and pushes the message object. 
	This can then be presented as the argument of e.g. #doesNotUnderstand:. 
	ikp 11/20/1999 03:59 -- added hook for external runtime compilers. */
/*	remap lookupClass in case GC happens during allocation */

sqInt createActualMessageTo(sqInt aClass) {
register struct foo * foo = &fum;
    sqInt message;
    sqInt lookupClass;
    sqInt argumentArray;
    sqInt count;
    sqInt src;
    sqInt out;
    sqInt lastIn;
    sqInt in;
    sqInt sp;
    sqInt oop;
    sqInt oop1;
    sqInt valuePointer;

	/* begin pushRemappableOop: */
	foo->remapBuffer[foo->remapBufferCount += 1] = aClass;

	/* remap argumentArray in case GC happens during allocation */

	argumentArray = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassArray << ShiftForWord)), foo->argumentCount);
	/* begin pushRemappableOop: */
	foo->remapBuffer[foo->remapBufferCount += 1] = argumentArray;
	message = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassMessage << ShiftForWord)), 0);
	/* begin popRemappableOop */
	oop = foo->remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	argumentArray = oop;
	/* begin popRemappableOop */
	oop1 = foo->remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	lookupClass = oop1;
	beRootIfOld(argumentArray);
	if (foo->compilerInitialized) {
		compilerCreateActualMessagestoringArgs(message, argumentArray);
	} else {
		/* begin transfer:from:to: */
		count = foo->argumentCount;
		src = foo->stackPointer - ((foo->argumentCount - 1) * BytesPerWord);
		flag("Dan");
		in = src - BytesPerWord;
		lastIn = in + (count * BytesPerWord);
		out = (argumentArray + BaseHeaderSize) - BytesPerWord;
		while ((((usqInt) in)) < (((usqInt) lastIn))) {
			longAtput(out += BytesPerWord, longAt(in += BytesPerWord));
		}
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((foo->argumentCount - 1) * BytesPerWord), message);
		foo->stackPointer = sp;
	}
	foo->argumentCount = 1;
	/* begin storePointer:ofObject:withValue: */
	valuePointer = foo->messageSelector;
	if ((((usqInt) message)) < (((usqInt) foo->youngStart))) {
		possibleRootStoreIntovalue(message, valuePointer);
	}
	longAtput((message + BaseHeaderSize) + (MessageSelectorIndex << ShiftForWord), valuePointer);
	/* begin storePointer:ofObject:withValue: */
	if ((((usqInt) message)) < (((usqInt) foo->youngStart))) {
		possibleRootStoreIntovalue(message, argumentArray);
	}
	longAtput((message + BaseHeaderSize) + (MessageArgumentsIndex << ShiftForWord), argumentArray);
	if ((lastPointerOf(message)) >= ((MessageLookupClassIndex * BytesPerWord) + BaseHeaderSize)) {
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) message)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(message, lookupClass);
		}
		longAtput((message + BaseHeaderSize) + (MessageLookupClassIndex << ShiftForWord), lookupClass);
	}
}

sqInt dispatchFunctionPointer(void * aFunctionPointer) {
	((void (*)(void))aFunctionPointer)();
}


/*	Call the primitive at index primIdx in the primitiveTable. */

sqInt dispatchFunctionPointerOnin(sqInt primIdx, void *primTable[]) {
	return dispatchFunctionPointer(primTable[primIdx]);
}


/*	Repaint the portion of the Smalltalk screen bounded by the affected rectangle. Used to synchronize the screen after a Bitblt to the Smalltalk Display object. */

sqInt displayBitsOfLeftTopRightBottom(sqInt aForm, sqInt l, sqInt t, sqInt r, sqInt b) {
register struct foo * foo = &fum;
    sqInt surfaceHandle;
    sqInt left;
    sqInt right;
    sqInt w;
    sqInt h;
    sqInt dispBitsIndex;
    sqInt bottom;
    sqInt d;
    sqInt displayObj;
    sqInt dispBits;
    sqInt top;
    sqInt successValue;

	displayObj = longAt((foo->specialObjectsOop + BaseHeaderSize) + (TheDisplay << ShiftForWord));
	if (!(aForm == displayObj)) {
		return null;
	}
	/* begin success: */
	successValue = (((displayObj & 1) == 0) && (((((usqInt) (longAt(displayObj))) >> 8) & 15) <= 4)) && ((lengthOf(displayObj)) >= 4);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		dispBits = longAt((displayObj + BaseHeaderSize) + (0 << ShiftForWord));
		w = fetchIntegerofObject(1, displayObj);
		h = fetchIntegerofObject(2, displayObj);
		d = fetchIntegerofObject(3, displayObj);
	}
	if (l < 0) {
		left = 0;
	} else {
		left = l;
	}
	if (r > w) {
		right = w;
	} else {
		right = r;
	}
	if (t < 0) {
		top = 0;
	} else {
		top = t;
	}
	if (b > h) {
		bottom = h;
	} else {
		bottom = b;
	}
	if (!((left <= right) && (top <= bottom))) {
		return null;
	}
	if (foo->successFlag) {
		if ((dispBits & 1)) {
			surfaceHandle = (dispBits >> 1);
			if (showSurfaceFn == 0) {
				showSurfaceFn = ioLoadFunctionFrom("ioShowSurface", "SurfacePlugin");
				if (showSurfaceFn == 0) {
					/* begin success: */
					foo->successFlag = 0 && foo->successFlag;
					return null;
				}
			}
			((sqInt (*)(sqInt, sqInt, sqInt, sqInt, sqInt))showSurfaceFn)(surfaceHandle, left, top, right-left, bottom-top);
		} else {

			/* index in memory byte array */

			dispBitsIndex = dispBits + BaseHeaderSize;
			ioShowDisplay(dispBitsIndex, w, h, d, left, right, top, bottom);
		}
	}
}

sqInt displayObject(void) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (TheDisplay << ShiftForWord));
}


/*	Rounds negative results towards negative infinity, rather than zero. */

sqInt doPrimitiveDivby(sqInt rcvr, sqInt arg) {
register struct foo * foo = &fum;
    sqInt integerRcvr;
    sqInt integerArg;
    sqInt result;
    sqInt posRcvr;
    sqInt posArg;
    sqInt successValue;

	if (((rcvr & arg) & 1) != 0) {
		integerRcvr = (rcvr >> 1);
		integerArg = (arg >> 1);
		/* begin success: */
		foo->successFlag = (integerArg != 0) && foo->successFlag;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
	}
	if (!(foo->successFlag)) {
		return 1;
	}
	if (integerRcvr > 0) {
		if (integerArg > 0) {
			result = integerRcvr / integerArg;
		} else {
			posArg = 0 - integerArg;
			result = 0 - ((integerRcvr + (posArg - 1)) / posArg);
		}
	} else {
		posRcvr = 0 - integerRcvr;
		if (integerArg > 0) {
			result = 0 - ((posRcvr + (integerArg - 1)) / integerArg);
		} else {
			posArg = 0 - integerArg;
			result = posRcvr / posArg;
		}
	}
	/* begin success: */
	successValue = 
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
		(((((int) result)) ^ ((((int) result)) << 1)) >= 0)
# else
		((result >= -1073741824) && (result <= 1073741823))
# endif  // SQ_HOST32
	;
	foo->successFlag = successValue && foo->successFlag;
	return result;
}

sqInt doPrimitiveModby(sqInt rcvr, sqInt arg) {
register struct foo * foo = &fum;
    sqInt integerRcvr;
    sqInt integerResult;
    sqInt integerArg;
    sqInt successValue;

	if (((rcvr & arg) & 1) != 0) {
		integerRcvr = (rcvr >> 1);
		integerArg = (arg >> 1);
		/* begin success: */
		foo->successFlag = (integerArg != 0) && foo->successFlag;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
	}
	if (!(foo->successFlag)) {
		return 1;
	}

	/* ensure that the result has the same sign as the integerArg */

	integerResult = integerRcvr % integerArg;
	if (integerArg < 0) {
		if (integerResult > 0) {
			integerResult += integerArg;
		}
	} else {
		if (integerResult < 0) {
			integerResult += integerArg;
		}
	}
	/* begin success: */
	successValue = 
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
		(((((int) integerResult)) ^ ((((int) integerResult)) << 1)) >= 0)
# else
		((integerResult >= -1073741824) && (integerResult <= 1073741823))
# endif  // SQ_HOST32
	;
	foo->successFlag = successValue && foo->successFlag;
	return integerResult;
}

sqInt dummyReferToProxy(void) {
	interpreterProxy = interpreterProxy;
}


/*	Dump the entire image out to the given file. Intended for debugging only. */

EXPORT(sqInt) dumpImage(char * fileName) {
    sqImageFile f;
    sqInt dataSize;
    sqInt result;

	f = sqImageFileOpen(fileName, "wb");
	if (f == null) {
		return -1;
	}
	dataSize = foo->endOfMemory - memory;
	result = sqImageFileWrite(pointerForOop(memory), sizeof(unsigned char), dataSize, f);
	sqImageFileClose(f);
	return result;
}


/*	execute a method found in the mCache - which means that 
	primitiveIndex & primitiveFunctionPointer are already set. Any sender 
	needs to have previously sent findMethodInClass: or equivalent */

sqInt executeNewMethodFromCache(void) {
register struct foo * foo = &fum;
    sqInt nArgs;
    sqInt delta;

	if (foo->primitiveIndex > 0) {
		if (DoBalanceChecks) {
			nArgs = foo->argumentCount;
			delta = foo->stackPointer - foo->activeContext;
		}
		foo->successFlag = 1;
		dispatchFunctionPointer(foo->primitiveFunctionPointer);
		if (DoBalanceChecks) {
			if (!(balancedStackafterPrimitivewithArgs(delta, foo->primitiveIndex, nArgs))) {
				printUnbalancedStack(foo->primitiveIndex);
			}
		}
		if (foo->successFlag) {
			return null;
		}
	}
	activateNewMethod();
	/* begin quickCheckForInterrupts */
	if ((foo->interruptCheckCounter -= 1) <= 0) {
		checkForInterrupts();
	}
}

sqInt failed(void) {
	return !foo->successFlag;
}

sqInt falseObject(void) {
	return foo->falseObj;
}


/*	Fetch the instance variable at the given index of the given object. Return the address of first indexable field of resulting array object, or fail if the instance variable does not contain an indexable bytes or words object. */
/*	Note: May be called by translated primitive code. */

void * fetchArrayofObject(sqInt fieldIndex, sqInt objectPointer) {
    sqInt arrayOop;

	arrayOop = longAt((objectPointer + BaseHeaderSize) + (fieldIndex << ShiftForWord));
	/* begin arrayValueOf: */
	if ((!((arrayOop & 1))) && (((arrayOop & 1) == 0) && (isWordsOrBytesNonInt(arrayOop)))) {
		return pointerForOop(arrayOop + BaseHeaderSize);
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
	return null;
}

sqInt fetchClassOf(sqInt oop) {
register struct foo * foo = &fum;
    sqInt ccIndex;

	if ((oop & 1)) {
		return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
	}
	ccIndex = (((usqInt) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		return (longAt(oop - BaseHeaderSize)) & AllButTypeMask;
	} else {
		return longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
	}
}

sqInt fetchClassOfNonInt(sqInt oop) {
    sqInt ccIndex;

	ccIndex = (((usqInt) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		return (longAt(oop - BaseHeaderSize)) & AllButTypeMask;
	} else {
		return longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
	}
}


/*	Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float. */
/*	Note: May be called by translated primitive code. */

double fetchFloatofObject(sqInt fieldIndex, sqInt objectPointer) {
    sqInt floatOop;

	floatOop = longAt((objectPointer + BaseHeaderSize) + (fieldIndex << ShiftForWord));
	return floatValueOf(floatOop);
}


/*	Note: May be called by translated primitive code. */

sqInt fetchIntegerofObject(sqInt fieldIndex, sqInt objectPointer) {
    sqInt intOop;

	intOop = longAt((objectPointer + BaseHeaderSize) + (fieldIndex << ShiftForWord));
	/* begin checkedIntegerValueOf: */
	if ((intOop & 1)) {
		return (intOop >> 1);
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return 0;
	}
	return null;
}


/*	 index by 32-bit units, and return a 32-bit value. Intended to replace fetchWord:ofObject: */

sqInt fetchLong32ofObject(sqInt fieldIndex, sqInt oop) {
	return long32At((oop + BaseHeaderSize) + (fieldIndex << 2));
}


/*	index by word size, and return a pointer as long as the word size */

sqInt fetchPointerofObject(sqInt fieldIndex, sqInt oop) {
	return longAt((oop + BaseHeaderSize) + (fieldIndex << ShiftForWord));
}


/*	Return the stackPointer of a Context or BlockContext. */

sqInt fetchStackPointerOf(sqInt aContext) {
    sqInt sp;

	sp = longAt((aContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
	if (!((sp & 1))) {
		return 0;
	}
	return (sp >> 1);
}


/*	NOTE: this gives size appropriate for fetchPointer: n, but not in general for, eg, fetchLong32, etc. */

sqInt fetchWordLengthOf(sqInt objectPointer) {
    sqInt sz;
    sqInt header;

	/* begin sizeBitsOf: */
	header = longAt(objectPointer);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(objectPointer - (BytesPerWord * 2))) & LongSizeMask;
		goto l1;
	} else {
		sz = header & SizeMask;
		goto l1;
	}
l1:	/* end sizeBitsOf: */;
	return ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
}


/*	During sweep phase we have encountered a weak reference. 
	Check if  its object has gone away (or is about to) and if so, signal a 
	semaphore.  */
/*	Do *not* inline this in sweepPhase - it is quite an unlikely 
	case to run into a weak reference */

sqInt finalizeReference(usqInt oop) {
register struct foo * foo = &fum;
    sqInt oopGone;
    sqInt lastField;
    sqInt firstField;
    usqInt weakOop;
    sqInt chunk;
    sqInt i;
    sqInt fmt;
    sqInt sz;
    sqInt methodHeader;
    sqInt contextSize;
    sqInt header;
    sqInt sp;
    sqInt type;
    sqInt header1;

	firstField = BaseHeaderSize + ((nonWeakFieldsOf(oop)) << ShiftForWord);
	/* begin lastPointerOf: */
	header = longAt(oop);
	fmt = (((usqInt) header) >> 8) & 15;
	if (fmt <= 4) {
		if ((fmt == 3) && ((((((usqInt) header) >> 12) & 31) == 13) || ((((((usqInt) header) >> 12) & 31) == 14) || (((((usqInt) header) >> 12) & 31) == 4)))) {
			/* begin fetchStackPointerOf: */
			sp = longAt((oop + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
			if (!((sp & 1))) {
				contextSize = 0;
				goto l1;
			}
			contextSize = (sp >> 1);
		l1:	/* end fetchStackPointerOf: */;
			lastField = (CtxtTempFrameStart + contextSize) * BytesPerWord;
			goto l4;
		}
		/* begin sizeBitsOfSafe: */
		header1 = longAt(oop);
		/* begin rightType: */
		if ((header1 & SizeMask) == 0) {
			type = HeaderTypeSizeAndClass;
			goto l2;
		} else {
			if ((header1 & CompactClassMask) == 0) {
				type = HeaderTypeClass;
				goto l2;
			} else {
				type = HeaderTypeShort;
				goto l2;
			}
		}
	l2:	/* end rightType: */;
		if (type == HeaderTypeSizeAndClass) {
			sz = (longAt(oop - (BytesPerWord * 2))) & AllButTypeMask;
			goto l3;
		} else {
			sz = header1 & SizeMask;
			goto l3;
		}
	l3:	/* end sizeBitsOfSafe: */;
		lastField = sz - BaseHeaderSize;
		goto l4;
	}
	if (fmt < 12) {
		lastField = 0;
		goto l4;
	}
	methodHeader = longAt(oop + BaseHeaderSize);
	lastField = (((((usqInt) methodHeader) >> 10) & 255) * BytesPerWord) + BaseHeaderSize;
l4:	/* end lastPointerOf: */;
	for (i = firstField; i <= lastField; i += BytesPerWord) {

		/* ar 1/18/2005: Added oop < youngStart test to make sure we're not testing
			objects in non-GCable region. This could lead to a forward reference in
			old space with the oop pointed to not being marked and thus treated as free. */

		weakOop = longAt(oop + i);
		if (!((weakOop == foo->nilObj) || (((weakOop & 1)) || (weakOop < foo->youngStart)))) {
			if (weakOop < oop) {
				chunk = weakOop - (foo->headerTypeBytes[(longAt(weakOop)) & TypeMask]);
				oopGone = ((longAt(chunk)) & TypeMask) == HeaderTypeFree;
			} else {
				oopGone = ((longAt(weakOop)) & MarkBit) == 0;
			}
			if (oopGone) {
				longAtput(oop + i, foo->nilObj);
				/* begin signalFinalization: */
				/* begin forceInterruptCheck */
				foo->interruptCheckCounter = -1000;
				foo->nextPollTick = 0;
				foo->pendingFinalizationSignals += 1;
			}
		}
	}
}

sqInt findClassOfMethodforReceiver(sqInt meth, sqInt rcvr) {
register struct foo * foo = &fum;
    sqInt currClass;
    sqInt methodArray;
    sqInt classDictSize;
    sqInt classDict;
    sqInt i;
    sqInt done;
    sqInt sz;
    sqInt header;
    sqInt ccIndex;
    sqInt ccIndex1;

	/* begin fetchClassOf: */
	if ((rcvr & 1)) {
		currClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l2;
	}
	ccIndex = (((usqInt) (longAt(rcvr))) >> 12) & 31;
	if (ccIndex == 0) {
		currClass = (longAt(rcvr - BaseHeaderSize)) & AllButTypeMask;
		goto l2;
	} else {
		currClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l2;
	}
l2:	/* end fetchClassOf: */;
	done = 0;
	while (!(done)) {
		classDict = longAt((currClass + BaseHeaderSize) + (MessageDictionaryIndex << ShiftForWord));
		/* begin fetchWordLengthOf: */
		/* begin sizeBitsOf: */
		header = longAt(classDict);
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(classDict - (BytesPerWord * 2))) & LongSizeMask;
			goto l1;
		} else {
			sz = header & SizeMask;
			goto l1;
		}
	l1:	/* end sizeBitsOf: */;
		classDictSize = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
		methodArray = longAt((classDict + BaseHeaderSize) + (MethodArrayIndex << ShiftForWord));
		i = 0;
		while (i < (classDictSize - SelectorStart)) {
			if (meth == (longAt((methodArray + BaseHeaderSize) + (i << ShiftForWord)))) {
				return currClass;
			}
			i += 1;
		}
		currClass = longAt((currClass + BaseHeaderSize) + (SuperclassIndex << ShiftForWord));
		done = currClass == foo->nilObj;
	}
	/* begin fetchClassOf: */
	if ((rcvr & 1)) {
		return longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
	}
	ccIndex1 = (((usqInt) (longAt(rcvr))) >> 12) & 31;
	if (ccIndex1 == 0) {
		return (longAt(rcvr - BaseHeaderSize)) & AllButTypeMask;
	} else {
		return longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex1 - 1) << ShiftForWord));
	}
	return null;
}


/*	Find the compiled method to be run when the current 
	messageSelector is sent to the given class, setting the values 
	of 'newMethod' and 'primitiveIndex'. */

sqInt findNewMethodInClass(sqInt class) {
register struct foo * foo = &fum;
    sqInt ok;
    sqInt probe;
    sqInt hash;

	/* begin lookupInMethodCacheSel:class: */
	hash = foo->messageSelector ^ class;
	probe = hash & MethodCacheMask;
	if (((foo->methodCache[probe + MethodCacheSelector]) == foo->messageSelector) && ((foo->methodCache[probe + MethodCacheClass]) == class)) {
		foo->newMethod = foo->methodCache[probe + MethodCacheMethod];
		foo->primitiveIndex = foo->methodCache[probe + MethodCachePrim];
		foo->newNativeMethod = foo->methodCache[probe + MethodCacheNative];
		foo->primitiveFunctionPointer = ((void *) (foo->methodCache[probe + MethodCachePrimFunction]));
		ok = 1;
		goto l1;
	}
	probe = (((usqInt) hash) >> 1) & MethodCacheMask;
	if (((foo->methodCache[probe + MethodCacheSelector]) == foo->messageSelector) && ((foo->methodCache[probe + MethodCacheClass]) == class)) {
		foo->newMethod = foo->methodCache[probe + MethodCacheMethod];
		foo->primitiveIndex = foo->methodCache[probe + MethodCachePrim];
		foo->newNativeMethod = foo->methodCache[probe + MethodCacheNative];
		foo->primitiveFunctionPointer = ((void *) (foo->methodCache[probe + MethodCachePrimFunction]));
		ok = 1;
		goto l1;
	}
	probe = (((usqInt) hash) >> 2) & MethodCacheMask;
	if (((foo->methodCache[probe + MethodCacheSelector]) == foo->messageSelector) && ((foo->methodCache[probe + MethodCacheClass]) == class)) {
		foo->newMethod = foo->methodCache[probe + MethodCacheMethod];
		foo->primitiveIndex = foo->methodCache[probe + MethodCachePrim];
		foo->newNativeMethod = foo->methodCache[probe + MethodCacheNative];
		foo->primitiveFunctionPointer = ((void *) (foo->methodCache[probe + MethodCachePrimFunction]));
		ok = 1;
		goto l1;
	}
	ok = 0;
l1:	/* end lookupInMethodCacheSel:class: */;
	if (!(ok)) {
		lookupMethodInClass(class);
		foo->lkupClass = class;
		addNewMethodToCache();
	}
}


/*	Search the obsolete named primitive table for the given function.
	Return the index if it's found, -1 otherwise. */

sqInt findObsoleteNamedPrimitivelength(char * functionName, sqInt functionLength) {
    sqInt chIndex;
    const char * entry;
    sqInt index;

	index = 0;
	while (1) {
		entry = obsoleteNamedPrimitiveTable[index][0];
		if (entry == null) {
			return -1;
		}
		;
		chIndex = 0;
		while (((entry[chIndex]) == (functionName[chIndex])) && (chIndex < functionLength)) {
			chIndex += 1;
		}
		if ((chIndex == functionLength) && ((entry[chIndex]) == 0)) {
			return index;
		}
		index += 1;
	}
}

sqInt findSelectorOfMethodforReceiver(sqInt meth, sqInt rcvr) {
register struct foo * foo = &fum;
    sqInt currClass;
    sqInt methodArray;
    sqInt classDictSize;
    sqInt classDict;
    sqInt i;
    sqInt done;
    sqInt sz;
    sqInt header;
    sqInt ccIndex;

	/* begin fetchClassOf: */
	if ((rcvr & 1)) {
		currClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l2;
	}
	ccIndex = (((usqInt) (longAt(rcvr))) >> 12) & 31;
	if (ccIndex == 0) {
		currClass = (longAt(rcvr - BaseHeaderSize)) & AllButTypeMask;
		goto l2;
	} else {
		currClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l2;
	}
l2:	/* end fetchClassOf: */;
	done = 0;
	while (!(done)) {
		classDict = longAt((currClass + BaseHeaderSize) + (MessageDictionaryIndex << ShiftForWord));
		/* begin fetchWordLengthOf: */
		/* begin sizeBitsOf: */
		header = longAt(classDict);
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(classDict - (BytesPerWord * 2))) & LongSizeMask;
			goto l1;
		} else {
			sz = header & SizeMask;
			goto l1;
		}
	l1:	/* end sizeBitsOf: */;
		classDictSize = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
		methodArray = longAt((classDict + BaseHeaderSize) + (MethodArrayIndex << ShiftForWord));
		i = 0;
		while (i <= (classDictSize - SelectorStart)) {
			if (meth == (longAt((methodArray + BaseHeaderSize) + (i << ShiftForWord)))) {
				return longAt((classDict + BaseHeaderSize) + ((i + SelectorStart) << ShiftForWord));
			}
			i += 1;
		}
		currClass = longAt((currClass + BaseHeaderSize) + (SuperclassIndex << ShiftForWord));
		done = currClass == foo->nilObj;
	}
	return foo->nilObj;
}


/*	Return the first accessible object in the heap. */

sqInt firstAccessibleObject(void) {
register struct foo * foo = &fum;
    sqInt obj;
    sqInt sz;
    sqInt header;

	obj = memory + (foo->headerTypeBytes[(longAt(memory)) & TypeMask]);
	while ((((usqInt) obj)) < (((usqInt) foo->endOfMemory))) {
		if (!(((longAt(obj)) & TypeMask) == HeaderTypeFree)) {
			return obj;
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) obj)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(obj)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(obj)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(obj);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(obj - (BytesPerWord * 2))) & LongSizeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		obj = (obj + sz) + (foo->headerTypeBytes[(longAt(obj + sz)) & TypeMask]);
	}
	error("heap is empty");
}

char * firstFixedField(sqInt oop) {
	return pointerForOop(oop + BaseHeaderSize);
}


/*	NOTE: copied in InterpreterSimulator, so please duplicate any changes */

char * firstIndexableField(sqInt oop) {
register struct foo * foo = &fum;
    sqInt fmt;
    sqInt totalLength;
    sqInt hdr;
    sqInt fixedFields;
    sqInt sz;
    sqInt class;
    sqInt classFormat;
    sqInt ccIndex;

	hdr = longAt(oop);
	fmt = (((usqInt) hdr) >> 8) & 15;
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz = hdr & SizeMask;
	}
	sz -= hdr & Size4Bit;
	if (fmt <= 4) {
		totalLength = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
		goto l1;
	}
	if (fmt < 8) {
		totalLength = ((usqInt) (sz - BaseHeaderSize)) >> 2;
		goto l1;
	} else {
		totalLength = (sz - BaseHeaderSize) - (fmt & 3);
		goto l1;
	}
l1:	/* end lengthOf:baseHeader:format: */;
	/* begin fixedFieldsOf:format:length: */
	if ((fmt > 4) || (fmt == 2)) {
		fixedFields = 0;
		goto l2;
	}
	if (fmt < 2) {
		fixedFields = totalLength;
		goto l2;
	}
	/* begin fetchClassOf: */
	if ((oop & 1)) {
		class = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l3;
	}
	ccIndex = (((usqInt) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(oop - BaseHeaderSize)) & AllButTypeMask;
		goto l3;
	} else {
		class = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l3;
	}
l3:	/* end fetchClassOf: */;
	classFormat = (longAt((class + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1;
	fixedFields = (((((usqInt) classFormat) >> 11) & 192) + ((((usqInt) classFormat) >> 2) & 63)) - 1;
l2:	/* end fixedFieldsOf:format:length: */;
	if (fmt < 8) {
		if (fmt == 6) {
			return pointerForOop((oop + BaseHeaderSize) + (fixedFields << 2));
		}
		return pointerForOop((oop + BaseHeaderSize) + (fixedFields << ShiftForWord));
	} else {
		return pointerForOop((oop + BaseHeaderSize) + fixedFields);
	}
}

sqInt floatObjectOf(double  aFloat) {
    sqInt newFloatObj;

	flag("Dan");
	newFloatObj = instantiateSmallClasssizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)), 8 + BaseHeaderSize);
	storeFloatAtfrom(newFloatObj + BaseHeaderSize, aFloat);
	return newFloatObj;
}


/*	Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float. */
/*	Note: May be called by translated primitive code. */

double floatValueOf(sqInt oop) {
register struct foo * foo = &fum;
    double  result;
    sqInt ccIndex;
    sqInt cl;

	flag("Dan");
	/* begin assertClassOf:is: */
	if ((oop & 1)) {
		foo->successFlag = 0;
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(oop - BaseHeaderSize)) & AllButTypeMask;
	} else {
		cl = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) && foo->successFlag;
l1:	/* end assertClassOf:is: */;
	if (foo->successFlag) {
		;
		fetchFloatAtinto(oop + BaseHeaderSize, result);
	} else {
		result = 0.0;
	}
	return result;
}


/*	methodPtr is a CompiledMethod containing an external primitive. Flush the function address and session ID of the CM */

sqInt flushExternalPrimitiveOf(sqInt methodPtr) {
    sqInt lit;

	if (!(((((usqInt) (longAt((methodPtr + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 10) & 255) > 0)) {
		return null;
	}
	lit = longAt((methodPtr + BaseHeaderSize) + ((0 + LiteralStart) << ShiftForWord));
	if (!((((lit & 1) == 0) && (((((usqInt) (longAt(lit))) >> 8) & 15) == 2)) && ((lengthOf(lit)) == 4))) {
		return null;
	}
	longAtput((lit + BaseHeaderSize) + (2 << ShiftForWord), ConstZero);
	longAtput((lit + BaseHeaderSize) + (3 << ShiftForWord), ConstZero);
}


/*	Flush the references to external functions from plugin 
	primitives. This will force a reload of those primitives when 
	accessed next. 
	Note: We must flush the method cache here so that any 
	failed primitives are looked up again. */

sqInt flushExternalPrimitives(void) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt primIdx;
    sqInt primBits;
    sqInt sz;
    sqInt header;
    sqInt i;
    sqInt i1;
    sqInt i2;

	oop = memory + (foo->headerTypeBytes[(longAt(memory)) & TypeMask]);
	while ((((usqInt) oop)) < (((usqInt) foo->endOfMemory))) {
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			if (((((usqInt) (longAt(oop))) >> 8) & 15) >= 12) {
				/* begin primitiveIndexOf: */
				primBits = (((usqInt) (longAt((oop + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 1) & 268435967;
				primIdx = (primBits & 511) + (((usqInt) primBits) >> 19);
				if (primIdx == PrimitiveExternalCallIndex) {
					flushExternalPrimitiveOf(oop);
				}
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) oop)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(oop);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz) + (foo->headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	}
	/* begin flushMethodCache */
	for (i = 1; i <= MethodCacheSize; i += 1) {
		foo->methodCache[i] = 0;
	}
	for (i = 1; i <= AtCacheTotalSize; i += 1) {
		foo->atCache[i] = 0;
	}
	/* begin flushObsoleteIndexedPrimitives */
	for (i1 = 1; i1 <= MaxPrimitiveIndex; i1 += 1) {
		(obsoleteIndexedPrimitiveTable[i1])[2] = null;
	}
	/* begin flushExternalPrimitiveTable */
	for (i2 = 0; i2 <= (MaxExternalPrimitiveTableSize - 1); i2 += 1) {
		foo->externalPrimitiveTable[i2] = 0;
	}
}


/*	force an interrupt check ASAP - setting interruptCheckCounter to a large -ve number is used as a flag to skip messing with the feedback mechanism and nextPollTick resetting makes sure that ioProcess gets called as near immediately as we can manage */

sqInt forceInterruptCheck(void) {
register struct foo * foo = &fum;
	foo->interruptCheckCounter = -1000;
	foo->nextPollTick = 0;
}


/*	Repaint the entire smalltalk screen, ignoring the affected rectangle. Used in some platform's code when the Smalltalk window is brought to the front or uncovered. */

sqInt fullDisplayUpdate(void) {
    sqInt w;
    sqInt h;
    sqInt displayObj;

	displayObj = longAt((foo->specialObjectsOop + BaseHeaderSize) + (TheDisplay << ShiftForWord));
	if ((((displayObj & 1) == 0) && (((((usqInt) (longAt(displayObj))) >> 8) & 15) <= 4)) && ((lengthOf(displayObj)) >= 4)) {
		w = fetchIntegerofObject(1, displayObj);
		h = fetchIntegerofObject(2, displayObj);
		displayBitsOfLeftTopRightBottom(displayObj, 0, 0, w, h);
		ioForceDisplayUpdate();
	}
}


/*	Do a mark/sweep garbage collection of the entire object memory. Free inaccessible objects but do not move them. */

sqInt fullGC(void) {
register struct foo * foo = &fum;
    sqLong startTime;
    sqInt oop;
    sqInt i;
    sqInt sz;

	if (DoAssertionChecks) {
		reverseDisplayFromto(0, 7);
	}
	/* begin preGCAction: */
	if (foo->compilerInitialized) {
		compilerPreGC(1);
	} else {
		/* begin storeContextRegisters: */
		longAtput((foo->activeContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput((foo->activeContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), (((((((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) - TempFrameStart) + 1) << 1) | 1));
	}
	startTime = ioMicroSecondClock();
	foo->statSweepCount = foo->statMarkCount = foo->statMkFwdCount = foo->statCompMoveCount = 0;
	/* begin clearRootsTable */
	for (i = 1; i <= foo->rootTableCount; i += 1) {
		oop = foo->rootTable[i];
		longAtput(oop, (longAt(oop)) & AllButRootBit);
		foo->rootTable[i] = 0;
	}
	foo->rootTableCount = 0;

	/* process all of memory */

	foo->youngStart = memory;
	markPhase();
	foo->totalObjectCount = sweepPhase();
	/* begin fullCompaction */
	foo->compStart = lowestFreeAfter(memory);
	if (foo->compStart == foo->freeBlock) {
		initializeMemoryFirstFree(foo->freeBlock);
		goto l1;
	}
	if ((sz = fwdTableSize(8)) < foo->totalObjectCount) {
		growObjectMemory(((foo->totalObjectCount - sz) + 10000) * 8);
	}
	while (foo->compStart < foo->freeBlock) {
		foo->compStart = incCompBody();
	}
l1:	/* end fullCompaction */;
	foo->allocationCount = 0;
	foo->statFullGCs += 1;
	foo->statGCTime = ioMicroSecondClock();
	foo->statFullGCMSecs += foo->statGCTime - startTime;
	/* begin capturePendingFinalizationSignals */
	foo->statpendingFinalizationSignals = foo->pendingFinalizationSignals;

	/* reset the young object boundary */

	foo->youngStart = foo->freeBlock;
	postGCAction();
	if (DoAssertionChecks) {
		reverseDisplayFromto(0, 7);
	}
}


/*	Set the limits for a table of two- or three-word forwarding blocks above the last used oop. The pointer fwdTableNext moves up to fwdTableLast. Used for compaction of memory and become-ing objects. Returns the number of forwarding blocks available. */

sqInt fwdTableInit(sqInt blkSize) {
register struct foo * foo = &fum;
	/* begin setSizeOfFree:to: */
	longAtput(foo->freeBlock, (BaseHeaderSize & AllButTypeMask) | HeaderTypeFree);

	/* make a fake free chunk at endOfMemory for use as a sentinal in memory scans */

	foo->endOfMemory = foo->freeBlock + BaseHeaderSize;
	/* begin setSizeOfFree:to: */
	longAtput(foo->endOfMemory, (BaseHeaderSize & AllButTypeMask) | HeaderTypeFree);
	foo->fwdTableNext = ((foo->endOfMemory + BaseHeaderSize) + 7) & (WordMask - 7);
	flag("Dan");

	/* last forwarding table entry */
	/* return the number of forwarding blocks available */

	foo->fwdTableLast = foo->memoryLimit - blkSize;
	return (foo->fwdTableLast - foo->fwdTableNext) / blkSize;
}


/*	Estimate the number of forwarding blocks available for compaction */

sqInt fwdTableSize(sqInt blkSize) {
register struct foo * foo = &fum;
    sqInt eom;
    sqInt fwdFirst;
    sqInt fwdLast;


	/* use all memory free between freeBlock and memoryLimit for forwarding table */
	/* Note: Forward blocks must be quadword aligned. */

	eom = foo->freeBlock + BaseHeaderSize;
	fwdFirst = ((eom + BaseHeaderSize) + 7) & (WordMask - 7);
	flag("Dan");

	/* last forwarding table entry */
	/* return the number of forwarding blocks available */

	fwdLast = foo->memoryLimit - blkSize;
	return (fwdLast - fwdFirst) / blkSize;
}


/*	currentBytecode will be private to the main dispatch loop in the generated code. This method allows the currentBytecode to be retrieved from global variables. */

sqInt getCurrentBytecode(void) {
	return byteAt(foo->instructionPointer);
}

sqInt getFullScreenFlag(void) {
	return foo->fullScreenFlag;
}

sqInt getInterruptCheckCounter(void) {
	return foo->interruptCheckCounter;
}

sqInt getInterruptKeycode(void) {
	return foo->interruptKeycode;
}

sqInt getInterruptPending(void) {
	return foo->interruptPending;
}


/*	Answer the next word read from aFile, byte-swapped according to the swapFlag. */

sqInt getLongFromFileswap(sqImageFile  aFile, sqInt swapFlag) {
    sqInt w;

	w = 0;
	sqImageFileRead(&w, sizeof(w), 1, aFile);
	if (swapFlag) {
		return byteSwapped(w);
	} else {
		return w;
	}
}

sqInt getNextWakeupTick(void) {
	return foo->nextWakeupTick;
}

sqInt getSavedWindowSize(void) {
	return foo->savedWindowSize;
}


/*	return the global session ID value */

sqInt getThisSessionID(void) {
	return foo->globalSessionID;
}


/*	Attempt to grow the object memory by the given delta 
	amount  */

sqInt growObjectMemory(usqInt delta) {
register struct foo * foo = &fum;
    usqInt limit;

	if (!(isExcessiveAllocationRequestshift(delta, 0))) {
		foo->statGrowMemory += 1;
		limit = sqGrowMemoryBy(foo->memoryLimit, delta);
		if (!(limit == foo->memoryLimit)) {

			/* remove a tad for safety */

			foo->memoryLimit = limit - 24;
			initializeMemoryFirstFree(foo->freeBlock);
		}
	}
}


/*	This VM is backwards-compatible with the immediately preceeding pre-closure version, and will allow loading images (or image segments) of that version. */

sqInt imageFormatBackwardCompatibilityVersion(void) {
	if (BytesPerWord == 4) {
		return 6502;
	} else {
		return 68000;
	}
}


/*	This VM is forwards-compatible with the immediately following closure version, and
	 will write the new version number in snapshots if the closure creation bytecode is used. */

sqInt imageFormatForwardCompatibilityVersion(void) {
	if (BytesPerWord == 4) {
		return 6504;
	} else {
		return 68002;
	}
}


/*	a more complex version that tells both the word reversal and the endianness of the machine it came from.  Low half of word is 6502.  Top byte is top byte of #doesNotUnderstand: on this machine. ($d on the Mac or $s on the PC) */

sqInt imageSegmentVersion(void) {
    sqInt wholeWord;


	/* first data word, 'does'  */

	wholeWord = longAt((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SelectorDoesNotUnderstand << ShiftForWord))) + BaseHeaderSize);
	return imageFormatVersionNumber | (wholeWord & 4278190080U);
}


/*	Move objects to consolidate free space into one big chunk. Return the newly created free chunk. */

sqInt incCompBody(void) {
register struct foo * foo = &fum;
    sqInt bytesFreed;

	fwdTableInit(BytesPerWord * 2);

	/* update pointers to point at new oops */

	bytesFreed = incCompMakeFwd();
	mapPointersInObjectsFromto(foo->youngStart, foo->endOfMemory);
	return incCompMove(bytesFreed);
}


/*	Create and initialize forwarding blocks for all non-free objects  
	following compStart. If the supply of forwarding blocks is exhausted,  
	set compEnd to the first chunk above the area to be 
	compacted; otherwise, set it to endOfMemory. Return the number of 
	bytes to be freed. */

sqInt incCompMakeFwd(void) {
register struct foo * foo = &fum;
    sqInt bytesFreed;
    sqInt fwdBlock;
    sqInt newOop;
    sqInt oop;
    sqInt originalHeader;
    sqInt originalHeaderType;
    sqInt sz;
    sqInt fwdBlock1;
    sqInt realHeader;
    sqInt header;
    sqInt sz1;
    sqInt header1;

	bytesFreed = 0;
	oop = foo->compStart + (foo->headerTypeBytes[(longAt(foo->compStart)) & TypeMask]);
	while ((((usqInt) oop)) < (((usqInt) foo->endOfMemory))) {
		foo->statMkFwdCount += 1;
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			bytesFreed += (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin fwdBlockGet: */
			foo->fwdTableNext += BytesPerWord * 2;
			if (foo->fwdTableNext <= foo->fwdTableLast) {
				fwdBlock = foo->fwdTableNext;
				goto l1;
			} else {
				fwdBlock = null;
				goto l1;
			}
		l1:	/* end fwdBlockGet: */;
			if (fwdBlock == null) {
				foo->compEnd = oop - (foo->headerTypeBytes[(longAt(oop)) & TypeMask]);
				return bytesFreed;
			}
			newOop = oop - bytesFreed;
			/* begin initForwardBlock:mapping:to:withBackPtr: */
			originalHeader = longAt(oop);
			if (DoAssertionChecks) {
				if (fwdBlock == null) {
					error("ran out of forwarding blocks in become");
				}
				if ((originalHeader & MarkBit) != 0) {
					error("object already has a forwarding table entry");
				}
			}
			originalHeaderType = originalHeader & TypeMask;
			longAtput(fwdBlock, newOop);
			longAtput(fwdBlock + BytesPerWord, originalHeader);
			if (0) {
				longAtput(fwdBlock + (BytesPerWord * 2), oop);
			}
			longAtput(oop, (((usqInt) fwdBlock) >> 1) | (MarkBit | originalHeaderType));
		}
		/* begin objectAfterWhileForwarding: */
		header = longAt(oop);
		if ((header & MarkBit) == 0) {
			/* begin objectAfter: */
			if (DoAssertionChecks) {
				if ((((usqInt) oop)) >= (((usqInt) foo->endOfMemory))) {
					error("no objects after the end of memory");
				}
			}
			if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
				sz1 = (longAt(oop)) & AllButTypeMask;
			} else {
				/* begin sizeBitsOf: */
				header1 = longAt(oop);
				if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
					sz1 = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
					goto l2;
				} else {
					sz1 = header1 & SizeMask;
					goto l2;
				}
			l2:	/* end sizeBitsOf: */;
			}
			oop = (oop + sz1) + (foo->headerTypeBytes[(longAt(oop + sz1)) & TypeMask]);
			goto l3;
		}
		fwdBlock1 = (header & AllButMarkBitAndTypeMask) << 1;
		if (DoAssertionChecks) {
			/* begin fwdBlockValidate: */
			if (!(((((usqInt) fwdBlock1)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock1)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock1 & 3) == 0)))) {
				error("invalid fwd table entry");
			}
		}
		realHeader = longAt(fwdBlock1 + BytesPerWord);
		if ((realHeader & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
		} else {
			sz = realHeader & SizeMask;
		}
		oop = (oop + sz) + (foo->headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	l3:	/* end objectAfterWhileForwarding: */;
	}
	foo->compEnd = foo->endOfMemory;
	return bytesFreed;
}


/*	Move all non-free objects between compStart and compEnd to their new  
	locations, restoring their headers in the process. Create a new free  
	block at the end of memory. Return the newly created free chunk.  */
/*	Note: The free block used by the allocator always must be the last free  
	block in memory. It may take several compaction passes to make all  
	free space bubble up to the end of memory. */

sqInt incCompMove(sqInt bytesFreed) {
register struct foo * foo = &fum;
    sqInt newFreeChunk;
    sqInt target;
    sqInt sz;
    sqInt fwdBlock;
    sqInt newOop;
    usqInt lastWord;
    usqInt w;
    sqInt oop;
    sqInt next;
    usqInt firstWord;
    sqInt header;
    sqInt bytesToMove;
    sqInt header1;
    sqInt sz2;
    sqInt fwdBlock1;
    sqInt realHeader;
    sqInt header2;
    sqInt sz1;
    sqInt header11;

	newOop = null;
	oop = foo->compStart + (foo->headerTypeBytes[(longAt(foo->compStart)) & TypeMask]);
	while ((((usqInt) oop)) < (((usqInt) foo->compEnd))) {
		foo->statCompMoveCount += 1;
		/* begin objectAfterWhileForwarding: */
		header2 = longAt(oop);
		if ((header2 & MarkBit) == 0) {
			/* begin objectAfter: */
			if (DoAssertionChecks) {
				if ((((usqInt) oop)) >= (((usqInt) foo->endOfMemory))) {
					error("no objects after the end of memory");
				}
			}
			if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
				sz1 = (longAt(oop)) & AllButTypeMask;
			} else {
				/* begin sizeBitsOf: */
				header11 = longAt(oop);
				if ((header11 & TypeMask) == HeaderTypeSizeAndClass) {
					sz1 = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
					goto l2;
				} else {
					sz1 = header11 & SizeMask;
					goto l2;
				}
			l2:	/* end sizeBitsOf: */;
			}
			next = (oop + sz1) + (foo->headerTypeBytes[(longAt(oop + sz1)) & TypeMask]);
			goto l3;
		}
		fwdBlock1 = (header2 & AllButMarkBitAndTypeMask) << 1;
		if (DoAssertionChecks) {
			/* begin fwdBlockValidate: */
			if (!(((((usqInt) fwdBlock1)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock1)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock1 & 3) == 0)))) {
				error("invalid fwd table entry");
			}
		}
		realHeader = longAt(fwdBlock1 + BytesPerWord);
		if ((realHeader & TypeMask) == HeaderTypeSizeAndClass) {
			sz2 = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
		} else {
			sz2 = realHeader & SizeMask;
		}
		next = (oop + sz2) + (foo->headerTypeBytes[(longAt(oop + sz2)) & TypeMask]);
	l3:	/* end objectAfterWhileForwarding: */;
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			fwdBlock = ((longAt(oop)) & AllButMarkBitAndTypeMask) << 1;
			if (DoAssertionChecks) {
				/* begin fwdBlockValidate: */
				if (!(((((usqInt) fwdBlock)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock & 3) == 0)))) {
					error("invalid fwd table entry");
				}
			}
			newOop = longAt(fwdBlock);
			header = longAt(fwdBlock + BytesPerWord);
			longAtput(oop, header);

			/* move the oop (including any extra header words)  */

			bytesToMove = oop - newOop;
			/* begin sizeBitsOf: */
			header1 = longAt(oop);
			if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
				goto l1;
			} else {
				sz = header1 & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
			firstWord = oop - (foo->headerTypeBytes[(longAt(oop)) & TypeMask]);
			lastWord = (oop + sz) - BaseHeaderSize;
			target = firstWord - bytesToMove;
			for (w = firstWord; w <= lastWord; w += BytesPerWord) {
				longAtput(target, longAt(w));
				target += BytesPerWord;
			}
		}
		oop = next;
	}
	if (newOop == null) {
		oop = foo->compStart + (foo->headerTypeBytes[(longAt(foo->compStart)) & TypeMask]);
		if ((((longAt(oop)) & TypeMask) == HeaderTypeFree) && ((objectAfter(oop)) == (foo->compEnd + (foo->headerTypeBytes[(longAt(foo->compEnd)) & TypeMask])))) {
			newFreeChunk = oop;
		} else {
			newFreeChunk = foo->freeBlock;
		}
	} else {
		newFreeChunk = newOop + (sizeBitsOf(newOop));
		/* begin setSizeOfFree:to: */
		longAtput(newFreeChunk, (bytesFreed & AllButTypeMask) | HeaderTypeFree);
	}
	if (DoAssertionChecks) {
		if (!((objectAfter(newFreeChunk)) == (foo->compEnd + (foo->headerTypeBytes[(longAt(foo->compEnd)) & TypeMask])))) {
			error("problem creating free chunk after compaction");
		}
	}
	if ((objectAfter(newFreeChunk)) == foo->endOfMemory) {
		initializeMemoryFirstFree(newFreeChunk);
	} else {
		initializeMemoryFirstFree(foo->freeBlock);
	}
	return newFreeChunk;
}


/*	Return the equivalent of 
		aClass includesBehavior: aSuperclass.
	Note: written for efficiency and better inlining (only 1 temp) */

sqInt includesBehaviorThatOf(sqInt aClass, sqInt aSuperclass) {
register struct foo * foo = &fum;
    sqInt theClass;

	if (((theClass = aClass) == aSuperclass) || (aSuperclass == foo->nilObj)) {
		return 1;
	}
	do {
		if ((theClass = longAt((theClass + BaseHeaderSize) + (SuperclassIndex << ShiftForWord))) == aSuperclass) {
			return 1;
		}
	} while(theClass != foo->nilObj);
	return 0;
}


/*	Do a mark/sweep garbage collection of just the young object 
	area of object memory (i.e., objects above youngStart), using 
	the root table to identify objects containing pointers to 
	young objects from the old object area. */

sqInt incrementalGC(void) {
register struct foo * foo = &fum;
    sqInt weDidGrow;
    sqInt survivorCount;
    sqInt i;
    sqLong startTime;
    sqInt oop;
    sqInt i1;
    sqInt growth;

	if (foo->rootTableCount >= RootTableSize) {
		foo->statRootTableOverflows += 1;
		return fullGC();
	}
	if (DoAssertionChecks) {
		reverseDisplayFromto(8, 15);
		validateRoots();
		/* begin validate */
	}
	/* begin preGCAction: */
	if (foo->compilerInitialized) {
		compilerPreGC(0);
	} else {
		/* begin storeContextRegisters: */
		longAtput((foo->activeContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput((foo->activeContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), (((((((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) - TempFrameStart) + 1) << 1) | 1));
	}
	startTime = ioMicroSecondClock();
	foo->weakRootCount = 0;
	foo->statSweepCount = foo->statMarkCount = foo->statMkFwdCount = foo->statCompMoveCount = 0;
	markPhase();
	for (i = 1; i <= foo->weakRootCount; i += 1) {
		finalizeReference(foo->weakRoots[i]);
	}
	survivorCount = sweepPhase();
	/* begin incrementalCompaction */
	if (foo->compStart == foo->freeBlock) {
		initializeMemoryFirstFree(foo->freeBlock);
	} else {
		incCompBody();
	}
	foo->statAllocationCount = foo->allocationCount;
	foo->allocationCount = 0;
	foo->statIncrGCs += 1;
	foo->statGCTime = ioMicroSecondClock();
	foo->statIGCDeltaTime = foo->statGCTime - startTime;
	foo->statIncrGCMSecs += foo->statIGCDeltaTime;
	/* begin capturePendingFinalizationSignals */
	foo->statpendingFinalizationSignals = foo->pendingFinalizationSignals;
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
	foo->nextPollTick = 0;
	foo->statRootTableCount = foo->rootTableCount;
	foo->statSurvivorCount = survivorCount;
	weDidGrow = 0;
	if (((survivorCount > foo->tenuringThreshold) || (foo->rootTableCount >= RootTableRedZone)) || (foo->forceTenureFlag == 1)) {
		foo->forceTenureFlag = 0;
		foo->statTenures += 1;
		/* begin clearRootsTable */
		for (i1 = 1; i1 <= foo->rootTableCount; i1 += 1) {
			oop = foo->rootTable[i1];
			longAtput(oop, (longAt(oop)) & AllButRootBit);
			foo->rootTable[i1] = 0;
		}
		foo->rootTableCount = 0;
		if ((foo->freeBlock < foo->growHeadroom) && (foo->gcBiasToGrow > 0)) {
			biasToGrow();
			weDidGrow = 1;
		}
		foo->youngStart = foo->freeBlock;
	}
	postGCAction();
	if (DoAssertionChecks) {
		validateRoots();
		/* begin validate */
		reverseDisplayFromto(8, 15);
	}
	if (weDidGrow) {
		/* begin biasToGrowCheckGCLimit */
		growth = (foo->youngStart - memory) - foo->gcBiasToGrowThreshold;
		if (growth < 0) {
			foo->gcBiasToGrowThreshold = foo->youngStart - memory;
		}
		if (growth > foo->gcBiasToGrowGCLimit) {
			fullGC();
			foo->gcBiasToGrowThreshold = foo->youngStart - memory;
		}
	}
}


/*	Initialize hooks for the 'null compiler' */

sqInt initCompilerHooks(void) {
	compilerHooks[1]= nullCompilerHook;
	compilerHooks[2]= nullCompilerHook;
	compilerHooks[3]= nullCompilerHook;
	compilerHooks[4]= nullCompilerHook;
	compilerHooks[5]= nullCompilerHook;
	compilerHooks[6]= nullCompilerHook;
	compilerHooks[7]= nullCompilerHook;
	compilerHooks[8]= nullCompilerHook;
	compilerHooks[9]= nullCompilerHook;
	compilerHooks[10]= nullCompilerHook;
	compilerHooks[11]= nullCompilerHook;
	compilerHooks[12]= nullCompilerHook;
	compilerHooks[13]= nullCompilerHook;
	compilerHooks[14]= nullCompilerHook;
	foo->compilerInitialized = 0;
}


/*	Initialize Interpreter state before starting execution of a new image. */

sqInt initializeInterpreter(sqInt bytesToShift) {
register struct foo * foo = &fum;
    sqInt i;
    sqInt sched;
    sqInt proc;
    sqInt activeCntx;
    sqInt tmp;

	interpreterProxy = sqGetInterpreterProxy();
	dummyReferToProxy();
	initializeObjectMemory(bytesToShift);
	initCompilerHooks();
	foo->activeContext = foo->nilObj;
	foo->theHomeContext = foo->nilObj;
	foo->method = foo->nilObj;
	foo->receiver = foo->nilObj;
	foo->messageSelector = foo->nilObj;
	foo->newMethod = foo->nilObj;
	foo->methodClass = foo->nilObj;
	foo->lkupClass = foo->nilObj;
	foo->receiverClass = foo->nilObj;
	foo->newNativeMethod = foo->nilObj;
	/* begin flushMethodCache */
	for (i = 1; i <= MethodCacheSize; i += 1) {
		foo->methodCache[i] = 0;
	}
	for (i = 1; i <= AtCacheTotalSize; i += 1) {
		foo->atCache[i] = 0;
	}
	/* begin loadInitialContext */
	sched = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord));
	proc = longAt((sched + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
	foo->activeContext = longAt((proc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord));
	if ((((usqInt) foo->activeContext)) < (((usqInt) foo->youngStart))) {
		beRootIfOld(foo->activeContext);
	}
	/* begin fetchContextRegisters: */
	activeCntx = foo->activeContext;
	tmp = longAt((activeCntx + BaseHeaderSize) + (MethodIndex << ShiftForWord));
	if ((tmp & 1)) {
		tmp = longAt((activeCntx + BaseHeaderSize) + (HomeIndex << ShiftForWord));
		if ((((usqInt) tmp)) < (((usqInt) foo->youngStart))) {
			beRootIfOld(tmp);
		}
	} else {
		tmp = activeCntx;
	}
	foo->theHomeContext = tmp;
	foo->receiver = longAt((tmp + BaseHeaderSize) + (ReceiverIndex << ShiftForWord));
	foo->method = longAt((tmp + BaseHeaderSize) + (MethodIndex << ShiftForWord));
	tmp = ((longAt((activeCntx + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord))) >> 1);
	foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
	tmp = ((longAt((activeCntx + BaseHeaderSize) + (StackPointerIndex << ShiftForWord))) >> 1);
	foo->stackPointer = (activeCntx + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * BytesPerWord);
	foo->reclaimableContextCount = 0;
	/* begin initialCleanup */
	if (((longAt(foo->activeContext)) & RootBit) == 0) {
		goto l1;
	}
	longAtput(foo->activeContext, (longAt(foo->activeContext)) & AllButRootBit);
	flushExternalPrimitives();
l1:	/* end initialCleanup */;
	foo->interruptCheckCounter = 0;
	foo->interruptCheckCounterFeedBackReset = 1000;
	foo->interruptChecksEveryNms = 1;
	foo->nextPollTick = 0;
	foo->nextWakeupTick = 0;
	foo->lastTick = 0;

	/* cmd-. as used for Mac but no other OS */

	foo->interruptKeycode = 2094;
	foo->interruptPending = 0;
	foo->semaphoresUseBufferA = 1;
	foo->semaphoresToSignalCountA = 0;
	foo->semaphoresToSignalCountB = 0;
	foo->deferDisplayUpdates = 0;
	foo->pendingFinalizationSignals = 0;
	foo->globalSessionID = 0;
	while (foo->globalSessionID == 0) {
		foo->globalSessionID = time(NULL) + ioMSecs();
	}
	foo->jmpDepth = 0;
	foo->jmpMax = MaxJumpBuf;
}


/*	Initialize endOfMemory to the top of oop storage space, reserving some space for forwarding blocks, and create the freeBlock from which space is allocated. Also create a fake free chunk at endOfMemory to act as a sentinal for memory scans.  */
/*	Note: The amount of space reserved for forwarding blocks should be chosen to ensure that incremental compactions can usually be done in a single pass. However, there should be enough forwarding blocks so a full compaction can be done in a reasonable number of passes, say ten. (A full compaction requires N object-moving passes, where N = number of non-garbage objects / number of forwarding blocks). 
	di 11/18/2000 Re totalObjectCount: Provide a margin of one byte per object to be used for forwarding pointers at GC time. Since fwd blocks are 8 bytes, this means an absolute worst case of 8 passes to compact memory. In most cases it will be adequate to do compaction in a single pass.  */

sqInt initializeMemoryFirstFree(usqInt firstFree) {
register struct foo * foo = &fum;
    usqInt fwdBlockBytes;

	fwdBlockBytes = foo->totalObjectCount & ((WordMask - BytesPerWord) + 1);
	if (!((((usqInt) (foo->memoryLimit - fwdBlockBytes))) >= (((usqInt) (firstFree + BaseHeaderSize))))) {
		fwdBlockBytes = foo->memoryLimit - (firstFree + BaseHeaderSize);
	}
	foo->endOfMemory = foo->memoryLimit - fwdBlockBytes;
	foo->freeBlock = firstFree;
	/* begin setSizeOfFree:to: */
	longAtput(foo->freeBlock, ((foo->endOfMemory - firstFree) & AllButTypeMask) | HeaderTypeFree);
	/* begin setSizeOfFree:to: */
	longAtput(foo->endOfMemory, (BaseHeaderSize & AllButTypeMask) | HeaderTypeFree);
	if (DoAssertionChecks) {
		if (!((foo->freeBlock < foo->endOfMemory) && (foo->endOfMemory < foo->memoryLimit))) {
			error("error in free space computation");
		}
		if (!((foo->endOfMemory + (foo->headerTypeBytes[(longAt(foo->endOfMemory)) & TypeMask])) == foo->endOfMemory)) {
			error("header format must have changed");
		}
		if (!((objectAfter(foo->freeBlock)) == foo->endOfMemory)) {
			error("free block not properly initialized");
		}
	}
}


/*	Initialize object memory variables at startup time. Assume endOfMemory is initially set (by the image-reading code) to the end of the last object in the image. Initialization redefines endOfMemory to be the end of the object allocation area based on the total available memory, but reserving some space for forwarding blocks. */
/*	Assume: image reader initializes the following variables:
		memory
		endOfMemory
		memoryLimit
		specialObjectsOop
		lastHash
	 */
/*	di 11/18/2000 fix slow full GC */

sqInt initializeObjectMemory(sqInt bytesToShift) {
register struct foo * foo = &fum;

	/* image may be at a different address; adjust oops for new location */

	foo->youngStart = foo->endOfMemory;
	foo->totalObjectCount = adjustAllOopsBy(bytesToShift);
	initializeMemoryFirstFree(foo->endOfMemory);

	/* heavily used special objects */

	foo->specialObjectsOop += bytesToShift;
	foo->nilObj = longAt((foo->specialObjectsOop + BaseHeaderSize) + (NilObject << ShiftForWord));
	foo->falseObj = longAt((foo->specialObjectsOop + BaseHeaderSize) + (FalseObject << ShiftForWord));
	foo->trueObj = longAt((foo->specialObjectsOop + BaseHeaderSize) + (TrueObject << ShiftForWord));
	foo->rootTableCount = 0;
	foo->freeContexts = NilContext;
	foo->freeLargeContexts = NilContext;
	foo->allocationCount = 0;
	foo->lowSpaceThreshold = 0;
	foo->signalLowSpace = 0;
	foo->compStart = 0;
	foo->compEnd = 0;
	foo->fwdTableNext = 0;
	foo->fwdTableLast = 0;
	foo->remapBufferCount = 0;

	/* do incremental GC after this many allocations */

	foo->allocationsBetweenGCs = 4000;

	/* tenure all suriving objects if count is over this threshold */

	foo->tenuringThreshold = 2000;

	/* four megabyte of headroom when growing */

	foo->growHeadroom = (4 * 1024) * 1024;

	/* eight megabyte of free space before shrinking */
	/* garbage collection statistics */

	foo->shrinkThreshold = (8 * 1024) * 1024;
	foo->statFullGCs = 0;
	foo->statFullGCMSecs = 0;
	foo->statIncrGCs = 0;
	foo->statIncrGCMSecs = 0;
	foo->statTenures = 0;
	foo->statRootTableOverflows = 0;
	foo->statGrowMemory = 0;
	foo->statShrinkMemory = 0;
	foo->forceTenureFlag = 0;
	foo->gcBiasToGrow = 0;
	foo->gcBiasToGrowGCLimit = 0;
	foo->extraRootCount = 0;
}


/*	Install the oop of this object in the given cache (at or atPut), along with
	its size, format and fixedSize */

sqInt installinAtCacheatstring(sqInt rcvr, sqInt * cache, sqInt atIx, sqInt stringy) {
register struct foo * foo = &fum;
    sqInt fmt;
    sqInt totalLength;
    sqInt hdr;
    sqInt fixedFields;
    sqInt sz;
    sqInt class;
    sqInt classFormat;
    sqInt ccIndex;

	hdr = longAt(rcvr);
	fmt = (((usqInt) hdr) >> 8) & 15;
	if ((fmt == 3) && ((((((usqInt) hdr) >> 12) & 31) == 13) || ((((((usqInt) hdr) >> 12) & 31) == 14) || (((((usqInt) hdr) >> 12) & 31) == 4)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(rcvr - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz = hdr & SizeMask;
	}
	sz -= hdr & Size4Bit;
	if (fmt <= 4) {
		totalLength = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
		goto l1;
	}
	if (fmt < 8) {
		totalLength = ((usqInt) (sz - BaseHeaderSize)) >> 2;
		goto l1;
	} else {
		totalLength = (sz - BaseHeaderSize) - (fmt & 3);
		goto l1;
	}
l1:	/* end lengthOf:baseHeader:format: */;
	/* begin fixedFieldsOf:format:length: */
	if ((fmt > 4) || (fmt == 2)) {
		fixedFields = 0;
		goto l2;
	}
	if (fmt < 2) {
		fixedFields = totalLength;
		goto l2;
	}
	/* begin fetchClassOf: */
	if ((rcvr & 1)) {
		class = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l3;
	}
	ccIndex = (((usqInt) (longAt(rcvr))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(rcvr - BaseHeaderSize)) & AllButTypeMask;
		goto l3;
	} else {
		class = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l3;
	}
l3:	/* end fetchClassOf: */;
	classFormat = (longAt((class + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1;
	fixedFields = (((((usqInt) classFormat) >> 11) & 192) + ((((usqInt) classFormat) >> 2) & 63)) - 1;
l2:	/* end fixedFieldsOf:format:length: */;
	cache[atIx + AtCacheOop] = rcvr;
	if (stringy) {
		cache[atIx + AtCacheFmt] = (fmt + 16);
	} else {
		cache[atIx + AtCacheFmt] = fmt;
	}
	cache[atIx + AtCacheFixedFields] = fixedFields;
	cache[atIx + AtCacheSize] = (totalLength - fixedFields);
}


/*	NOTE: This method supports the backward-compatible split instSize field of the 
	class format word. The sizeHiBits will go away and other shifts change by 2 
	when the split fields get merged in an (incompatible) image change. */

sqInt instantiateClassindexableSize(sqInt classPointer, sqInt size) {
register struct foo * foo = &fum;
    sqInt newObj;
    sqInt header3;
    sqInt binc;
    sqInt hdrSize;
    sqInt cClass;
    sqInt byteSize;
    sqInt bm1;
    sqInt header1;
    sqInt classFormat;
    sqInt hash;
    sqInt fillWord;
    sqInt sizeHiBits;
    sqInt header2;
    sqInt format;
    sqInt newObj1;
    usqInt end;
    sqInt remappedClassOop;
    usqInt i;
    sqInt oop;
    sqInt newFreeSize;
    sqInt newChunk;
    sqInt enoughSpace;
    usqInt minFree;
    sqInt lastSavedProcess;
    sqInt currentProc;
    sqInt sched;
    sqInt oop1;

	if (DoAssertionChecks) {
		if (size < 0) {
			error("cannot have a negative indexable field count");
		}
	}
	/* begin newObjectHash */
	foo->lastHash = (13849 + (27181 * foo->lastHash)) & 65535;
	hash = foo->lastHash;

	/* Low 2 bits are 0 */

	classFormat = (longAt((classPointer + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1;
	header1 = (classFormat & 130816) | ((hash << HashBitsOffset) & HashBits);
	header2 = classPointer;
	header3 = 0;
	sizeHiBits = ((usqInt) (classFormat & 393216)) >> 9;

	/* compact class field from format word */

	cClass = header1 & CompactClassMask;

	/* size in bytes -- low 2 bits are 0 */
	/* Note this byteSize comes from the format word of the class which is pre-shifted
		to 4 bytes per field.  Need another shift for 8 bytes per word... */

	byteSize = (classFormat & (SizeMask + Size4Bit)) + sizeHiBits;
	byteSize = byteSize << (ShiftForWord - 2);
	format = (((usqInt) classFormat) >> 8) & 15;
	flag("sizeLowBits");
	if (format < 8) {
		if (format == 6) {
			bm1 = BytesPerWord - 1;

			/* round up */

			byteSize = ((byteSize + (size * 4)) + bm1) & LongSizeMask;

			/* odd bytes */
			/* extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits) */

			binc = bm1 - (((size * 4) + bm1) & bm1);
			header1 = header1 | (binc & 4);
		} else {

			/* Arrays and 64-bit bitmaps */

			byteSize += size * BytesPerWord;
		}
	} else {
		bm1 = BytesPerWord - 1;

		/* round up */

		byteSize = ((byteSize + size) + bm1) & LongSizeMask;

		/* odd bytes */
		/* low bits of byte size go in format field */

		binc = bm1 - ((size + bm1) & bm1);

		/* extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits) */

		header1 = header1 | ((binc & 3) << 8);
		header1 = header1 | (binc & 4);
	}
	if (byteSize > 255) {
		header3 = byteSize;
		header1 = header1;
	} else {
		header1 = header1 | byteSize;
	}
	if (header3 > 0) {
		hdrSize = 3;
	} else {
		if (cClass == 0) {
			hdrSize = 2;
		} else {
			hdrSize = 1;
		}
	}
	if (format <= 4) {
		fillWord = foo->nilObj;
	} else {
		fillWord = 0;
	}
	/* begin allocate:headerSize:h1:h2:h3:doFill:with: */
	if (hdrSize > 1) {
		/* begin pushRemappableOop: */
		foo->remapBuffer[foo->remapBufferCount += 1] = header2;
	}
	/* begin allocateChunk: */
	if (foo->allocationCount >= foo->allocationsBetweenGCs) {
		incrementalGC();
	}
	/* begin sufficientSpaceToAllocate: */
	minFree = (foo->lowSpaceThreshold + (byteSize + ((hdrSize - 1) * BytesPerWord))) + BaseHeaderSize;
	if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((usqInt) minFree))) {
		enoughSpace = 1;
		goto l1;
	} else {
		enoughSpace = sufficientSpaceAfterGC(minFree);
		goto l1;
	}
l1:	/* end sufficientSpaceToAllocate: */;
	if (!(enoughSpace)) {
		foo->signalLowSpace = 1;
		foo->lowSpaceThreshold = 0;
		/* begin saveProcessSignalingLowSpace */
		lastSavedProcess = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ProcessSignalingLowSpace << ShiftForWord));
		if (lastSavedProcess == foo->nilObj) {
			sched = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord));
			currentProc = longAt((sched + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
			/* begin storePointer:ofObject:withValue: */
			oop1 = foo->specialObjectsOop;
			if ((((usqInt) oop1)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(oop1, currentProc);
			}
			longAtput((oop1 + BaseHeaderSize) + (ProcessSignalingLowSpace << ShiftForWord), currentProc);
		}
		/* begin forceInterruptCheck */
		foo->interruptCheckCounter = -1000;
		foo->nextPollTick = 0;
	}
	if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) < (((usqInt) ((byteSize + ((hdrSize - 1) * BytesPerWord)) + BaseHeaderSize)))) {
		error("out of memory");
	}
	newFreeSize = ((longAt(foo->freeBlock)) & AllButTypeMask) - (byteSize + ((hdrSize - 1) * BytesPerWord));
	newChunk = foo->freeBlock;
	foo->freeBlock += byteSize + ((hdrSize - 1) * BytesPerWord);
	/* begin setSizeOfFree:to: */
	longAtput(foo->freeBlock, (newFreeSize & AllButTypeMask) | HeaderTypeFree);
	foo->allocationCount += 1;
	newObj1 = newChunk;
	if (hdrSize > 1) {
		/* begin popRemappableOop */
		oop = foo->remapBuffer[foo->remapBufferCount];
		foo->remapBufferCount -= 1;
		remappedClassOop = oop;
	}
	if (hdrSize == 3) {
		longAtput(newObj1, header3 | HeaderTypeSizeAndClass);
		longAtput(newObj1 + BytesPerWord, remappedClassOop | HeaderTypeSizeAndClass);
		longAtput(newObj1 + (BytesPerWord * 2), header1 | HeaderTypeSizeAndClass);
		newObj1 += BytesPerWord * 2;
	}
	if (hdrSize == 2) {
		longAtput(newObj1, remappedClassOop | HeaderTypeClass);
		longAtput(newObj1 + BytesPerWord, header1 | HeaderTypeClass);
		newObj1 += BytesPerWord;
	}
	if (hdrSize == 1) {
		longAtput(newObj1, header1 | HeaderTypeShort);
	}
	if (1) {
		end = newObj1 + byteSize;
		i = newObj1 + BytesPerWord;
		while (i < end) {
			longAtput(i, fillWord);
			i += BytesPerWord;
		}
	}
	if (DoAssertionChecks) {
		okayOop(newObj1);
		oopHasOkayClass(newObj1);
		if (!((objectAfter(newObj1)) == foo->freeBlock)) {
			error("allocate bug: did not set header of new oop correctly");
		}
		if (!((objectAfter(foo->freeBlock)) == foo->endOfMemory)) {
			error("allocate bug: did not set header of freeBlock correctly");
		}
	}
	newObj = newObj1;
	return newObj;
}


/*	This version of instantiateClass assumes that the total object 
	size is under 256 bytes, the limit for objects with only one or 
	two header words. Note that the size is specified in bytes 
	and should include four bytes for the base header word. */

sqInt instantiateContextsizeInBytes(sqInt classPointer, sqInt sizeInBytes) {
register struct foo * foo = &fum;
    sqInt hdrSize;
    sqInt header1;
    sqInt hash;
    sqInt header2;
    sqInt newObj;
    usqInt end;
    sqInt remappedClassOop;
    usqInt i;
    sqInt oop;
    sqInt newFreeSize;
    sqInt newChunk;
    sqInt enoughSpace;
    usqInt minFree;
    sqInt lastSavedProcess;
    sqInt currentProc;
    sqInt sched;
    sqInt oop1;

	/* begin newObjectHash */
	foo->lastHash = (13849 + (27181 * foo->lastHash)) & 65535;
	hash = foo->lastHash;
	header1 = ((hash << HashBitsOffset) & HashBits) | ((longAt((classPointer + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1);
	header2 = classPointer;
	if ((header1 & CompactClassMask) > 0) {
		hdrSize = 1;
	} else {
		hdrSize = 2;
	}
	if (sizeInBytes <= SizeMask) {
		header1 += sizeInBytes - (header1 & SizeMask);
	} else {

		/* Zero the size field of header1 if large */

		hdrSize = 3;
		header1 -= header1 & SizeMask;
	}
	flag("Dan");
	/* begin allocate:headerSize:h1:h2:h3:doFill:with: */
	if (hdrSize > 1) {
		/* begin pushRemappableOop: */
		foo->remapBuffer[foo->remapBufferCount += 1] = header2;
	}
	/* begin allocateChunk: */
	if (foo->allocationCount >= foo->allocationsBetweenGCs) {
		incrementalGC();
	}
	/* begin sufficientSpaceToAllocate: */
	minFree = (foo->lowSpaceThreshold + (sizeInBytes + ((hdrSize - 1) * BytesPerWord))) + BaseHeaderSize;
	if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((usqInt) minFree))) {
		enoughSpace = 1;
		goto l1;
	} else {
		enoughSpace = sufficientSpaceAfterGC(minFree);
		goto l1;
	}
l1:	/* end sufficientSpaceToAllocate: */;
	if (!(enoughSpace)) {
		foo->signalLowSpace = 1;
		foo->lowSpaceThreshold = 0;
		/* begin saveProcessSignalingLowSpace */
		lastSavedProcess = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ProcessSignalingLowSpace << ShiftForWord));
		if (lastSavedProcess == foo->nilObj) {
			sched = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord));
			currentProc = longAt((sched + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
			/* begin storePointer:ofObject:withValue: */
			oop1 = foo->specialObjectsOop;
			if ((((usqInt) oop1)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(oop1, currentProc);
			}
			longAtput((oop1 + BaseHeaderSize) + (ProcessSignalingLowSpace << ShiftForWord), currentProc);
		}
		/* begin forceInterruptCheck */
		foo->interruptCheckCounter = -1000;
		foo->nextPollTick = 0;
	}
	if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) < (((usqInt) ((sizeInBytes + ((hdrSize - 1) * BytesPerWord)) + BaseHeaderSize)))) {
		error("out of memory");
	}
	newFreeSize = ((longAt(foo->freeBlock)) & AllButTypeMask) - (sizeInBytes + ((hdrSize - 1) * BytesPerWord));
	newChunk = foo->freeBlock;
	foo->freeBlock += sizeInBytes + ((hdrSize - 1) * BytesPerWord);
	/* begin setSizeOfFree:to: */
	longAtput(foo->freeBlock, (newFreeSize & AllButTypeMask) | HeaderTypeFree);
	foo->allocationCount += 1;
	newObj = newChunk;
	if (hdrSize > 1) {
		/* begin popRemappableOop */
		oop = foo->remapBuffer[foo->remapBufferCount];
		foo->remapBufferCount -= 1;
		remappedClassOop = oop;
	}
	if (hdrSize == 3) {
		longAtput(newObj, LargeContextSize | HeaderTypeSizeAndClass);
		longAtput(newObj + BytesPerWord, remappedClassOop | HeaderTypeSizeAndClass);
		longAtput(newObj + (BytesPerWord * 2), header1 | HeaderTypeSizeAndClass);
		newObj += BytesPerWord * 2;
	}
	if (hdrSize == 2) {
		longAtput(newObj, remappedClassOop | HeaderTypeClass);
		longAtput(newObj + BytesPerWord, header1 | HeaderTypeClass);
		newObj += BytesPerWord;
	}
	if (hdrSize == 1) {
		longAtput(newObj, header1 | HeaderTypeShort);
	}
	if (0) {
		end = newObj + sizeInBytes;
		i = newObj + BytesPerWord;
		while (i < end) {
			longAtput(i, 0);
			i += BytesPerWord;
		}
	}
	if (DoAssertionChecks) {
		okayOop(newObj);
		oopHasOkayClass(newObj);
		if (!((objectAfter(newObj)) == foo->freeBlock)) {
			error("allocate bug: did not set header of new oop correctly");
		}
		if (!((objectAfter(foo->freeBlock)) == foo->endOfMemory)) {
			error("allocate bug: did not set header of freeBlock correctly");
		}
	}
	return newObj;
}


/*	This version of instantiateClass assumes that the total object 
	size is under 256 bytes, the limit for objects with only one or 
	two header words. Note that the size is specified in bytes 
	and should include 4 or 8 bytes for the base header word. 
	NOTE this code will only work for sizes that are an integral number of words
		(like not a 32-bit LargeInteger in a 64-bit system). 
	May cause a GC.
	Note that the created small object IS NOT FILLED and must be completed before returning it to Squeak. Since this call is used in routines that do jsut that we are safe. Break this rule and die. */

sqInt instantiateSmallClasssizeInBytes(sqInt classPointer, sqInt sizeInBytes) {
register struct foo * foo = &fum;
    sqInt hdrSize;
    sqInt header1;
    sqInt hash;
    sqInt header2;
    sqInt newObj;
    usqInt end;
    sqInt remappedClassOop;
    usqInt i;
    sqInt oop;
    sqInt newFreeSize;
    sqInt newChunk;
    sqInt enoughSpace;
    usqInt minFree;
    sqInt lastSavedProcess;
    sqInt currentProc;
    sqInt sched;
    sqInt oop1;

	if (!((sizeInBytes & (BytesPerWord - 1)) == 0)) {
		error("size must be integral number of words");
	}
	/* begin newObjectHash */
	foo->lastHash = (13849 + (27181 * foo->lastHash)) & 65535;
	hash = foo->lastHash;
	header1 = ((hash << HashBitsOffset) & HashBits) | ((longAt((classPointer + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1);
	header2 = classPointer;
	if ((header1 & CompactClassMask) > 0) {
		hdrSize = 1;
	} else {
		hdrSize = 2;
	}
	header1 += sizeInBytes - (header1 & (SizeMask + Size4Bit));
	/* begin allocate:headerSize:h1:h2:h3:doFill:with: */
	if (hdrSize > 1) {
		/* begin pushRemappableOop: */
		foo->remapBuffer[foo->remapBufferCount += 1] = header2;
	}
	/* begin allocateChunk: */
	if (foo->allocationCount >= foo->allocationsBetweenGCs) {
		incrementalGC();
	}
	/* begin sufficientSpaceToAllocate: */
	minFree = (foo->lowSpaceThreshold + (sizeInBytes + ((hdrSize - 1) * BytesPerWord))) + BaseHeaderSize;
	if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((usqInt) minFree))) {
		enoughSpace = 1;
		goto l1;
	} else {
		enoughSpace = sufficientSpaceAfterGC(minFree);
		goto l1;
	}
l1:	/* end sufficientSpaceToAllocate: */;
	if (!(enoughSpace)) {
		foo->signalLowSpace = 1;
		foo->lowSpaceThreshold = 0;
		/* begin saveProcessSignalingLowSpace */
		lastSavedProcess = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ProcessSignalingLowSpace << ShiftForWord));
		if (lastSavedProcess == foo->nilObj) {
			sched = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord));
			currentProc = longAt((sched + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
			/* begin storePointer:ofObject:withValue: */
			oop1 = foo->specialObjectsOop;
			if ((((usqInt) oop1)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(oop1, currentProc);
			}
			longAtput((oop1 + BaseHeaderSize) + (ProcessSignalingLowSpace << ShiftForWord), currentProc);
		}
		/* begin forceInterruptCheck */
		foo->interruptCheckCounter = -1000;
		foo->nextPollTick = 0;
	}
	if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) < (((usqInt) ((sizeInBytes + ((hdrSize - 1) * BytesPerWord)) + BaseHeaderSize)))) {
		error("out of memory");
	}
	newFreeSize = ((longAt(foo->freeBlock)) & AllButTypeMask) - (sizeInBytes + ((hdrSize - 1) * BytesPerWord));
	newChunk = foo->freeBlock;
	foo->freeBlock += sizeInBytes + ((hdrSize - 1) * BytesPerWord);
	/* begin setSizeOfFree:to: */
	longAtput(foo->freeBlock, (newFreeSize & AllButTypeMask) | HeaderTypeFree);
	foo->allocationCount += 1;
	newObj = newChunk;
	if (hdrSize > 1) {
		/* begin popRemappableOop */
		oop = foo->remapBuffer[foo->remapBufferCount];
		foo->remapBufferCount -= 1;
		remappedClassOop = oop;
	}
	if (hdrSize == 3) {
		longAtput(newObj, 0 | HeaderTypeSizeAndClass);
		longAtput(newObj + BytesPerWord, remappedClassOop | HeaderTypeSizeAndClass);
		longAtput(newObj + (BytesPerWord * 2), header1 | HeaderTypeSizeAndClass);
		newObj += BytesPerWord * 2;
	}
	if (hdrSize == 2) {
		longAtput(newObj, remappedClassOop | HeaderTypeClass);
		longAtput(newObj + BytesPerWord, header1 | HeaderTypeClass);
		newObj += BytesPerWord;
	}
	if (hdrSize == 1) {
		longAtput(newObj, header1 | HeaderTypeShort);
	}
	if (0) {
		end = newObj + sizeInBytes;
		i = newObj + BytesPerWord;
		while (i < end) {
			longAtput(i, 0);
			i += BytesPerWord;
		}
	}
	if (DoAssertionChecks) {
		okayOop(newObj);
		oopHasOkayClass(newObj);
		if (!((objectAfter(newObj)) == foo->freeBlock)) {
			error("allocate bug: did not set header of new oop correctly");
		}
		if (!((objectAfter(foo->freeBlock)) == foo->endOfMemory)) {
			error("allocate bug: did not set header of freeBlock correctly");
		}
	}
	return newObj;
}

sqInt integerObjectOf(sqInt value) {
	return (value << 1) + 1;
}


/*	Translator produces 'objectPointer >> 1' */

sqInt integerValueOf(sqInt objectPointer) {
	if ((objectPointer & 2147483648U) != 0) {
		return ((((usqInt) (objectPointer & 2147483647U)) >> 1) - 1073741823) - 1;
	} else {
		return ((usqInt) objectPointer) >> 1;
	}
}


/*	This is the main interpreter loop. It normally loops forever, fetching and executing bytecodes. When running in the context of a browser plugin VM, however, it must return control to the browser periodically. This should done only when the state of the currently running Squeak thread is safely stored in the object heap. Since this is the case at the moment that a check for interrupts is performed, that is when we return to the browser if it is time to do so. Interrupt checks happen quite frequently. */

sqInt interpret(void) {
register struct foo * foo = &fum;
    sqInt localReturnValue;
    sqInt localReturnContext;
    sqInt localHomeContext;
    char* localSP;
    char* localIP;
    sqInt currentBytecode;

	browserPluginInitialiseIfNeeded();
	/* begin internalizeIPandSP */
	localIP = pointerForOop(foo->instructionPointer);
	localSP = pointerForOop(foo->stackPointer);
	localHomeContext = foo->theHomeContext;
	/* begin fetchNextBytecode */
	currentBytecode = byteAtPointer(++localIP);
	while (1) {
		switch (currentBytecode) {
		case 0:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((0 & 15) << ShiftForWord)));
			}
;
			break;
		case 1:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((1 & 15) << ShiftForWord)));
			}
;
			break;
		case 2:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((2 & 15) << ShiftForWord)));
			}
;
			break;
		case 3:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((3 & 15) << ShiftForWord)));
			}
;
			break;
		case 4:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((4 & 15) << ShiftForWord)));
			}
;
			break;
		case 5:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((5 & 15) << ShiftForWord)));
			}
;
			break;
		case 6:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((6 & 15) << ShiftForWord)));
			}
;
			break;
		case 7:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((7 & 15) << ShiftForWord)));
			}
;
			break;
		case 8:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((8 & 15) << ShiftForWord)));
			}
;
			break;
		case 9:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((9 & 15) << ShiftForWord)));
			}
;
			break;
		case 10:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((10 & 15) << ShiftForWord)));
			}
;
			break;
		case 11:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((11 & 15) << ShiftForWord)));
			}
;
			break;
		case 12:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((12 & 15) << ShiftForWord)));
			}
;
			break;
		case 13:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((13 & 15) << ShiftForWord)));
			}
;
			break;
		case 14:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((14 & 15) << ShiftForWord)));
			}
;
			break;
		case 15:
			/* pushReceiverVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + ((15 & 15) << ShiftForWord)));
			}
;
			break;
		case 16:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((16 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 17:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((17 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 18:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((18 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 19:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((19 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 20:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((20 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 21:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((21 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 22:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((22 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 23:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((23 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 24:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((24 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 25:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((25 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 26:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((26 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 27:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((27 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 28:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((28 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 29:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((29 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 30:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((30 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 31:
			/* pushTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + (((31 & 15) + TempFrameStart) << ShiftForWord)));
			}
;
			break;
		case 32:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((32 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 33:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((33 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 34:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((34 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 35:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((35 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 36:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((36 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 37:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((37 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 38:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((38 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 39:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((39 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 40:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((40 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 41:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((41 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 42:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((42 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 43:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((43 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 44:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((44 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 45:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((45 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 46:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((46 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 47:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((47 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 48:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((48 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 49:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((49 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 50:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((50 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 51:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((51 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 52:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((52 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 53:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((53 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 54:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((54 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 55:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((55 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 56:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((56 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 57:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((57 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 58:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((58 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 59:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((59 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 60:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((60 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 61:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((61 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 62:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((62 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 63:
			/* pushLiteralConstantBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + (((63 & 31) + LiteralStart) << ShiftForWord)));
			}
;
			break;
		case 64:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((64 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 65:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((65 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 66:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((66 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 67:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((67 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 68:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((68 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 69:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((69 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 70:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((70 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 71:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((71 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 72:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((72 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 73:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((73 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 74:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((74 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 75:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((75 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 76:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((76 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 77:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((77 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 78:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((78 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 79:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((79 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 80:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((80 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 81:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((81 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 82:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((82 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 83:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((83 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 84:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((84 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 85:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((85 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 86:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((86 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 87:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((87 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 88:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((88 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 89:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((89 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 90:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((90 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 91:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((91 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 92:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((92 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 93:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((93 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 94:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((94 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 95:
			/* pushLiteralVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + (((95 & 31) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
			}
;
			break;
		case 96:
			/* storeAndPopReceiverVariableBytecode */
			{
				sqInt rcvr;
				sqInt top;
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				rcvr = foo->receiver;
				top = longAtPointer(localSP);
				if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput((rcvr + BaseHeaderSize) + ((96 & 7) << ShiftForWord), top);
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 97:
			/* storeAndPopReceiverVariableBytecode */
			{
				sqInt rcvr;
				sqInt top;
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				rcvr = foo->receiver;
				top = longAtPointer(localSP);
				if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput((rcvr + BaseHeaderSize) + ((97 & 7) << ShiftForWord), top);
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 98:
			/* storeAndPopReceiverVariableBytecode */
			{
				sqInt rcvr;
				sqInt top;
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				rcvr = foo->receiver;
				top = longAtPointer(localSP);
				if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput((rcvr + BaseHeaderSize) + ((98 & 7) << ShiftForWord), top);
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 99:
			/* storeAndPopReceiverVariableBytecode */
			{
				sqInt rcvr;
				sqInt top;
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				rcvr = foo->receiver;
				top = longAtPointer(localSP);
				if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput((rcvr + BaseHeaderSize) + ((99 & 7) << ShiftForWord), top);
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 100:
			/* storeAndPopReceiverVariableBytecode */
			{
				sqInt rcvr;
				sqInt top;
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				rcvr = foo->receiver;
				top = longAtPointer(localSP);
				if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput((rcvr + BaseHeaderSize) + ((100 & 7) << ShiftForWord), top);
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 101:
			/* storeAndPopReceiverVariableBytecode */
			{
				sqInt rcvr;
				sqInt top;
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				rcvr = foo->receiver;
				top = longAtPointer(localSP);
				if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput((rcvr + BaseHeaderSize) + ((101 & 7) << ShiftForWord), top);
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 102:
			/* storeAndPopReceiverVariableBytecode */
			{
				sqInt rcvr;
				sqInt top;
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				rcvr = foo->receiver;
				top = longAtPointer(localSP);
				if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput((rcvr + BaseHeaderSize) + ((102 & 7) << ShiftForWord), top);
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 103:
			/* storeAndPopReceiverVariableBytecode */
			{
				sqInt rcvr;
				sqInt top;
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				rcvr = foo->receiver;
				top = longAtPointer(localSP);
				if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput((rcvr + BaseHeaderSize) + ((103 & 7) << ShiftForWord), top);
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 104:
			/* storeAndPopTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				longAtput((localHomeContext + BaseHeaderSize) + (((104 & 7) + TempFrameStart) << ShiftForWord), longAtPointer(localSP));
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 105:
			/* storeAndPopTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				longAtput((localHomeContext + BaseHeaderSize) + (((105 & 7) + TempFrameStart) << ShiftForWord), longAtPointer(localSP));
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 106:
			/* storeAndPopTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				longAtput((localHomeContext + BaseHeaderSize) + (((106 & 7) + TempFrameStart) << ShiftForWord), longAtPointer(localSP));
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 107:
			/* storeAndPopTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				longAtput((localHomeContext + BaseHeaderSize) + (((107 & 7) + TempFrameStart) << ShiftForWord), longAtPointer(localSP));
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 108:
			/* storeAndPopTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				longAtput((localHomeContext + BaseHeaderSize) + (((108 & 7) + TempFrameStart) << ShiftForWord), longAtPointer(localSP));
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 109:
			/* storeAndPopTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				longAtput((localHomeContext + BaseHeaderSize) + (((109 & 7) + TempFrameStart) << ShiftForWord), longAtPointer(localSP));
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 110:
			/* storeAndPopTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				longAtput((localHomeContext + BaseHeaderSize) + (((110 & 7) + TempFrameStart) << ShiftForWord), longAtPointer(localSP));
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 111:
			/* storeAndPopTemporaryVariableBytecode */
			{
				flag("requires currentBytecode to be expanded to a constant");
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				longAtput((localHomeContext + BaseHeaderSize) + (((111 & 7) + TempFrameStart) << ShiftForWord), longAtPointer(localSP));
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 112:
			/* pushReceiverBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, foo->receiver);
			}
;
			break;
		case 113:
			/* pushConstantTrueBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, foo->trueObj);
			}
;
			break;
		case 114:
			/* pushConstantFalseBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, foo->falseObj);
			}
;
			break;
		case 115:
			/* pushConstantNilBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, foo->nilObj);
			}
;
			break;
		case 116:
			/* pushConstantMinusOneBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, ConstMinusOne);
			}
;
			break;
		case 117:
			/* pushConstantZeroBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, ConstZero);
			}
;
			break;
		case 118:
			/* pushConstantOneBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, ConstOne);
			}
;
			break;
		case 119:
			/* pushConstantTwoBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, ConstTwo);
			}
;
			break;
		case 120:
			/* returnReceiver */
			{
				sqInt closureOrNil;
				sqInt context;
				/* begin sender */
				context = localHomeContext;
				while ((closureOrNil = longAt((context + BaseHeaderSize) + (ClosureIndex << ShiftForWord))) != foo->nilObj) {
					context = longAt((closureOrNil + BaseHeaderSize) + (ClosureOuterContextIndex << ShiftForWord));
				}
				localReturnContext = longAt((context + BaseHeaderSize) + (SenderIndex << ShiftForWord));
				localReturnValue = foo->receiver;
				/* goto commonReturn */
			}
;
			
		commonReturn:
			/* commonReturn */
			{
				sqInt contextOfCaller;
				sqInt localCntx;
				sqInt localVal;
				sqInt unwindMarked;
				sqInt thisCntx;
				sqInt nilOop;
				sqInt meth;
				sqInt pIndex;
				sqInt header;
				sqInt header1;
				sqInt primBits;
				sqInt tmp;
				/* inline:  */;
				nilOop = foo->nilObj;
				thisCntx = foo->activeContext;
				localCntx = localReturnContext;
				localVal = localReturnValue;
				if ((localCntx == nilOop) || ((longAt((localCntx + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord))) == nilOop)) {
					/* begin internalCannotReturn: */
					/* begin internalPush: */
					longAtPointerput(localSP += BytesPerWord, foo->activeContext);
					/* begin internalPush: */
					longAtPointerput(localSP += BytesPerWord, localVal);
					foo->messageSelector = longAt((foo->specialObjectsOop + BaseHeaderSize) + (SelectorCannotReturn << ShiftForWord));
					foo->argumentCount = 1;
					goto normalSend;
					goto l42;
				}
				thisCntx = longAt((foo->activeContext + BaseHeaderSize) + (SenderIndex << ShiftForWord));
				while (!(thisCntx == localCntx)) {
					if (thisCntx == nilOop) {
						/* begin internalCannotReturn: */
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->activeContext);
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, localVal);
						foo->messageSelector = longAt((foo->specialObjectsOop + BaseHeaderSize) + (SelectorCannotReturn << ShiftForWord));
						foo->argumentCount = 1;
						goto normalSend;
						goto l42;
					}
					/* begin isUnwindMarked: */
					header = longAt(thisCntx);
					if (!(((((usqInt) header) >> 12) & 31) == 14)) {
						unwindMarked = 0;
						goto l43;
					}
					meth = longAt((thisCntx + BaseHeaderSize) + (MethodIndex << ShiftForWord));
					/* begin primitiveIndexOf: */
					primBits = (((usqInt) (longAt((meth + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 1) & 268435967;
					pIndex = (primBits & 511) + (((usqInt) primBits) >> 19);
					unwindMarked = pIndex == 198;
				l43:	/* end isUnwindMarked: */;
					if (unwindMarked) {
						/* begin internalAboutToReturn:through: */
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->activeContext);
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, localVal);
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, thisCntx);
						foo->messageSelector = longAt((foo->specialObjectsOop + BaseHeaderSize) + (SelectorAboutToReturn << ShiftForWord));
						foo->argumentCount = 2;
						goto normalSend;
						goto l42;
					}
					thisCntx = longAt((thisCntx + BaseHeaderSize) + (SenderIndex << ShiftForWord));
				}
				thisCntx = foo->activeContext;
				while (!(thisCntx == localCntx)) {
					contextOfCaller = longAt((thisCntx + BaseHeaderSize) + (SenderIndex << ShiftForWord));
					longAtput((thisCntx + BaseHeaderSize) + (SenderIndex << ShiftForWord), nilOop);
					longAtput((thisCntx + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), nilOop);
					if (foo->reclaimableContextCount > 0) {
						foo->reclaimableContextCount -= 1;
						/* begin recycleContextIfPossible: */
						if ((((usqInt) thisCntx)) >= (((usqInt) foo->youngStart))) {
							header1 = longAt(thisCntx);
							if (((((usqInt) header1) >> 12) & 31) == 14) {
								if ((header1 & SizeMask) == SmallContextSize) {
									longAtput((thisCntx + BaseHeaderSize) + (0 << ShiftForWord), foo->freeContexts);
									foo->freeContexts = thisCntx;
								}
								if ((header1 & SizeMask) == LargeContextSize) {
									longAtput((thisCntx + BaseHeaderSize) + (0 << ShiftForWord), foo->freeLargeContexts);
									foo->freeLargeContexts = thisCntx;
								}
							}
						}
					}
					thisCntx = contextOfCaller;
				}
				foo->activeContext = thisCntx;
				if ((((usqInt) thisCntx)) < (((usqInt) foo->youngStart))) {
					beRootIfOld(thisCntx);
				}
				/* begin internalFetchContextRegisters: */
				tmp = longAt((thisCntx + BaseHeaderSize) + (MethodIndex << ShiftForWord));
				if ((tmp & 1)) {
					tmp = longAt((thisCntx + BaseHeaderSize) + (HomeIndex << ShiftForWord));
					if ((((usqInt) tmp)) < (((usqInt) foo->youngStart))) {
						beRootIfOld(tmp);
					}
				} else {
					tmp = thisCntx;
				}
				localHomeContext = tmp;
				foo->receiver = longAt((tmp + BaseHeaderSize) + (ReceiverIndex << ShiftForWord));
				foo->method = longAt((tmp + BaseHeaderSize) + (MethodIndex << ShiftForWord));
				tmp = ((longAt((thisCntx + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord))) >> 1);
				localIP = pointerForOop(((foo->method + tmp) + BaseHeaderSize) - 2);
				tmp = ((longAt((thisCntx + BaseHeaderSize) + (StackPointerIndex << ShiftForWord))) >> 1);
				localSP = pointerForOop((thisCntx + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * BytesPerWord));
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, localVal);
			}
;
		l42:	/* end case */;
			break;
		case 121:
			/* returnTrue */
			{
				sqInt closureOrNil;
				sqInt context;
				/* begin sender */
				context = localHomeContext;
				while ((closureOrNil = longAt((context + BaseHeaderSize) + (ClosureIndex << ShiftForWord))) != foo->nilObj) {
					context = longAt((closureOrNil + BaseHeaderSize) + (ClosureOuterContextIndex << ShiftForWord));
				}
				localReturnContext = longAt((context + BaseHeaderSize) + (SenderIndex << ShiftForWord));
				localReturnValue = foo->trueObj;
				goto commonReturn;
			}
;
			break;
		case 122:
			/* returnFalse */
			{
				sqInt closureOrNil;
				sqInt context;
				/* begin sender */
				context = localHomeContext;
				while ((closureOrNil = longAt((context + BaseHeaderSize) + (ClosureIndex << ShiftForWord))) != foo->nilObj) {
					context = longAt((closureOrNil + BaseHeaderSize) + (ClosureOuterContextIndex << ShiftForWord));
				}
				localReturnContext = longAt((context + BaseHeaderSize) + (SenderIndex << ShiftForWord));
				localReturnValue = foo->falseObj;
				goto commonReturn;
			}
;
			break;
		case 123:
			/* returnNil */
			{
				sqInt closureOrNil;
				sqInt context;
				/* begin sender */
				context = localHomeContext;
				while ((closureOrNil = longAt((context + BaseHeaderSize) + (ClosureIndex << ShiftForWord))) != foo->nilObj) {
					context = longAt((closureOrNil + BaseHeaderSize) + (ClosureOuterContextIndex << ShiftForWord));
				}
				localReturnContext = longAt((context + BaseHeaderSize) + (SenderIndex << ShiftForWord));
				localReturnValue = foo->nilObj;
				goto commonReturn;
			}
;
			break;
		case 124:
			/* returnTopFromMethod */
			{
				sqInt closureOrNil;
				sqInt context;
				/* begin sender */
				context = localHomeContext;
				while ((closureOrNil = longAt((context + BaseHeaderSize) + (ClosureIndex << ShiftForWord))) != foo->nilObj) {
					context = longAt((closureOrNil + BaseHeaderSize) + (ClosureOuterContextIndex << ShiftForWord));
				}
				localReturnContext = longAt((context + BaseHeaderSize) + (SenderIndex << ShiftForWord));
				localReturnValue = longAtPointer(localSP);
				goto commonReturn;
			}
;
			break;
		case 125:
			/* returnTopFromBlock */
			{
				localReturnContext = longAt((foo->activeContext + BaseHeaderSize) + (CallerIndex << ShiftForWord));
				localReturnValue = longAtPointer(localSP);
				goto commonReturn;
			}
;
			break;
		case 126:
		case 127:
			/* unknownBytecode */
			{
				error("Unknown bytecode");
			}
;
			break;
		case 128:
			/* extendedPushBytecode */
			{
				sqInt descriptor;
				sqInt variableIndex;
				sqInt variableType;
				descriptor = byteAtPointer(++localIP);
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				variableType = (((usqInt) descriptor) >> 6) & 3;
				variableIndex = descriptor & 63;
				if (variableType == 0) {
					/* begin pushReceiverVariable: */
					/* begin internalPush: */
					longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + (variableIndex << ShiftForWord)));
					goto l1;
				}
				if (variableType == 1) {
					/* begin pushTemporaryVariable: */
					/* begin internalPush: */
					longAtPointerput(localSP += BytesPerWord, longAt((localHomeContext + BaseHeaderSize) + ((variableIndex + TempFrameStart) << ShiftForWord)));
					goto l1;
				}
				if (variableType == 2) {
					/* begin pushLiteralConstant: */
					/* begin internalPush: */
					longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + ((variableIndex + LiteralStart) << ShiftForWord)));
					goto l1;
				}
				if (variableType == 3) {
					/* begin pushLiteralVariable: */
					/* begin internalPush: */
					longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + ((variableIndex + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
					goto l1;
				}
			}
;
		l1:	/* end case */;
			break;
		case 129:
			/* extendedStoreBytecode */
			{
				sqInt association;
				sqInt descriptor;
				sqInt variableIndex;
				sqInt variableType;
				sqInt oop;
				sqInt valuePointer;
				sqInt valuePointer1;
				descriptor = byteAtPointer(++localIP);
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				variableType = (((usqInt) descriptor) >> 6) & 3;
				variableIndex = descriptor & 63;
				if (variableType == 0) {
					/* begin storePointer:ofObject:withValue: */
					oop = foo->receiver;
					valuePointer = longAtPointer(localSP);
					if ((((usqInt) oop)) < (((usqInt) foo->youngStart))) {
						possibleRootStoreIntovalue(oop, valuePointer);
					}
					longAtput((oop + BaseHeaderSize) + (variableIndex << ShiftForWord), valuePointer);
					goto l2;
				}
				if (variableType == 1) {
					longAtput((localHomeContext + BaseHeaderSize) + ((variableIndex + TempFrameStart) << ShiftForWord), longAtPointer(localSP));
					goto l2;
				}
				if (variableType == 2) {
					error("illegal store");
				}
				if (variableType == 3) {
					association = longAt((foo->method + BaseHeaderSize) + ((variableIndex + LiteralStart) << ShiftForWord));
					/* begin storePointer:ofObject:withValue: */
					valuePointer1 = longAtPointer(localSP);
					if ((((usqInt) association)) < (((usqInt) foo->youngStart))) {
						possibleRootStoreIntovalue(association, valuePointer1);
					}
					longAtput((association + BaseHeaderSize) + (ValueIndex << ShiftForWord), valuePointer1);
					goto l2;
				}
			}
;
		l2:	/* end case */;
			break;
		case 130:
			/* extendedStoreAndPopBytecode */
			{
				sqInt association;
				sqInt descriptor;
				sqInt variableIndex;
				sqInt variableType;
				sqInt oop;
				sqInt valuePointer;
				sqInt valuePointer1;
				/* begin extendedStoreBytecode */
				descriptor = byteAtPointer(++localIP);
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				variableType = (((usqInt) descriptor) >> 6) & 3;
				variableIndex = descriptor & 63;
				if (variableType == 0) {
					/* begin storePointer:ofObject:withValue: */
					oop = foo->receiver;
					valuePointer = longAtPointer(localSP);
					if ((((usqInt) oop)) < (((usqInt) foo->youngStart))) {
						possibleRootStoreIntovalue(oop, valuePointer);
					}
					longAtput((oop + BaseHeaderSize) + (variableIndex << ShiftForWord), valuePointer);
					goto l3;
				}
				if (variableType == 1) {
					longAtput((localHomeContext + BaseHeaderSize) + ((variableIndex + TempFrameStart) << ShiftForWord), longAtPointer(localSP));
					goto l3;
				}
				if (variableType == 2) {
					error("illegal store");
				}
				if (variableType == 3) {
					association = longAt((foo->method + BaseHeaderSize) + ((variableIndex + LiteralStart) << ShiftForWord));
					/* begin storePointer:ofObject:withValue: */
					valuePointer1 = longAtPointer(localSP);
					if ((((usqInt) association)) < (((usqInt) foo->youngStart))) {
						possibleRootStoreIntovalue(association, valuePointer1);
					}
					longAtput((association + BaseHeaderSize) + (ValueIndex << ShiftForWord), valuePointer1);
					goto l3;
				}
			l3:	/* end extendedStoreBytecode */;
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 131:
			/* singleExtendedSendBytecode */
			{
				sqInt descriptor;
				descriptor = byteAtPointer(++localIP);
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((descriptor & 31) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((usqInt) descriptor) >> 5;
				/* goto normalSend */
			}
;
			
		normalSend:
			/* normalSend */
			{
				sqInt rcvr;
				sqInt ccIndex;
				/* inline:  */;
				rcvr = longAtPointer(localSP - (foo->argumentCount * BytesPerWord));
				/* begin fetchClassOf: */
				if ((rcvr & 1)) {
					foo->lkupClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
					goto l44;
				}
				ccIndex = (((usqInt) (longAt(rcvr))) >> 12) & 31;
				if (ccIndex == 0) {
					foo->lkupClass = (longAt(rcvr - BaseHeaderSize)) & AllButTypeMask;
					goto l44;
				} else {
					foo->lkupClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
					goto l44;
				}
			l44:	/* end fetchClassOf: */;
				foo->receiverClass = foo->lkupClass;
				/* goto commonSend */
			}
;
			
		commonSend:
			/* commonSend */
			{
				sqInt ok;
				sqInt probe;
				sqInt hash;
				sqInt nArgs;
				sqInt delta;
				sqInt localPrimIndex;
				sqInt oop;
				sqInt newContext;
				sqInt where;
				sqInt methodHeader;
				sqInt tempCount;
				sqInt needsLarge;
				sqInt i;
				sqInt argCount2;
				sqInt activeCntx;
				sqInt valuePointer;
				sqInt valuePointer1;
				sqInt tmp;
				/* begin internalFindNewMethod */
				/* begin lookupInMethodCacheSel:class: */
				hash = foo->messageSelector ^ foo->lkupClass;
				probe = hash & MethodCacheMask;
				if (((foo->methodCache[probe + MethodCacheSelector]) == foo->messageSelector) && ((foo->methodCache[probe + MethodCacheClass]) == foo->lkupClass)) {
					foo->newMethod = foo->methodCache[probe + MethodCacheMethod];
					foo->primitiveIndex = foo->methodCache[probe + MethodCachePrim];
					foo->newNativeMethod = foo->methodCache[probe + MethodCacheNative];
					foo->primitiveFunctionPointer = ((void *) (foo->methodCache[probe + MethodCachePrimFunction]));
					ok = 1;
					goto l45;
				}
				probe = (((usqInt) hash) >> 1) & MethodCacheMask;
				if (((foo->methodCache[probe + MethodCacheSelector]) == foo->messageSelector) && ((foo->methodCache[probe + MethodCacheClass]) == foo->lkupClass)) {
					foo->newMethod = foo->methodCache[probe + MethodCacheMethod];
					foo->primitiveIndex = foo->methodCache[probe + MethodCachePrim];
					foo->newNativeMethod = foo->methodCache[probe + MethodCacheNative];
					foo->primitiveFunctionPointer = ((void *) (foo->methodCache[probe + MethodCachePrimFunction]));
					ok = 1;
					goto l45;
				}
				probe = (((usqInt) hash) >> 2) & MethodCacheMask;
				if (((foo->methodCache[probe + MethodCacheSelector]) == foo->messageSelector) && ((foo->methodCache[probe + MethodCacheClass]) == foo->lkupClass)) {
					foo->newMethod = foo->methodCache[probe + MethodCacheMethod];
					foo->primitiveIndex = foo->methodCache[probe + MethodCachePrim];
					foo->newNativeMethod = foo->methodCache[probe + MethodCacheNative];
					foo->primitiveFunctionPointer = ((void *) (foo->methodCache[probe + MethodCachePrimFunction]));
					ok = 1;
					goto l45;
				}
				ok = 0;
			l45:	/* end lookupInMethodCacheSel:class: */;
				if (!(ok)) {
					/* begin externalizeIPandSP */
					foo->instructionPointer = oopForPointer(localIP);
					foo->stackPointer = oopForPointer(localSP);
					foo->theHomeContext = localHomeContext;
					lookupMethodInClass(foo->lkupClass);
					/* begin internalizeIPandSP */
					localIP = pointerForOop(foo->instructionPointer);
					localSP = pointerForOop(foo->stackPointer);
					localHomeContext = foo->theHomeContext;
					addNewMethodToCache();
				}
				/* begin internalExecuteNewMethod */
				localPrimIndex = foo->primitiveIndex;
				if (localPrimIndex > 0) {
					if ((localPrimIndex > 255) && (localPrimIndex < 520)) {
						if (localPrimIndex >= 264) {
							/* begin internalPop:thenPush: */
							oop = longAt(((longAtPointer(localSP)) + BaseHeaderSize) + ((localPrimIndex - 264) << ShiftForWord));
							longAtPointerput(localSP -= (1 - 1) * BytesPerWord, oop);
							goto l46;
						} else {
							if (localPrimIndex == 256) {
								goto l46;
							}
							if (localPrimIndex == 257) {
								/* begin internalPop:thenPush: */
								longAtPointerput(localSP -= (1 - 1) * BytesPerWord, foo->trueObj);
								goto l46;
							}
							if (localPrimIndex == 258) {
								/* begin internalPop:thenPush: */
								longAtPointerput(localSP -= (1 - 1) * BytesPerWord, foo->falseObj);
								goto l46;
							}
							if (localPrimIndex == 259) {
								/* begin internalPop:thenPush: */
								longAtPointerput(localSP -= (1 - 1) * BytesPerWord, foo->nilObj);
								goto l46;
							}
							/* begin internalPop:thenPush: */
							longAtPointerput(localSP -= (1 - 1) * BytesPerWord, (((localPrimIndex - 261) << 1) | 1));
							goto l46;
						}
					} else {
						/* begin externalizeIPandSP */
						foo->instructionPointer = oopForPointer(localIP);
						foo->stackPointer = oopForPointer(localSP);
						foo->theHomeContext = localHomeContext;
						if (DoBalanceChecks) {
							nArgs = foo->argumentCount;
							delta = foo->stackPointer - foo->activeContext;
						}
						foo->successFlag = 1;
						dispatchFunctionPointer(foo->primitiveFunctionPointer);
						if (DoBalanceChecks) {
							if (!(balancedStackafterPrimitivewithArgs(delta, localPrimIndex, nArgs))) {
								printUnbalancedStack(localPrimIndex);
							}
						}
						/* begin internalizeIPandSP */
						localIP = pointerForOop(foo->instructionPointer);
						localSP = pointerForOop(foo->stackPointer);
						localHomeContext = foo->theHomeContext;
						if (foo->successFlag) {
							browserPluginReturnIfNeeded();
							goto l46;
						}
					}
				}
				/* begin internalActivateNewMethod */
				methodHeader = longAt((foo->newMethod + BaseHeaderSize) + (HeaderIndex << ShiftForWord));
				needsLarge = methodHeader & LargeContextBit;
				if ((needsLarge == 0) && (foo->freeContexts != NilContext)) {
					newContext = foo->freeContexts;
					foo->freeContexts = longAt((newContext + BaseHeaderSize) + (0 << ShiftForWord));
				} else {
					/* begin externalizeIPandSP */
					foo->instructionPointer = oopForPointer(localIP);
					foo->stackPointer = oopForPointer(localSP);
					foo->theHomeContext = localHomeContext;
					newContext = allocateOrRecycleContext(needsLarge);
					/* begin internalizeIPandSP */
					localIP = pointerForOop(foo->instructionPointer);
					localSP = pointerForOop(foo->stackPointer);
					localHomeContext = foo->theHomeContext;
				}
				tempCount = (((usqInt) methodHeader) >> 19) & 63;
				where = newContext + BaseHeaderSize;
				longAtput(where + (SenderIndex << ShiftForWord), foo->activeContext);
				longAtput(where + (InstructionPointerIndex << ShiftForWord), (((((LiteralStart + ((((usqInt) methodHeader) >> 10) & 255)) * BytesPerWord) + 1) << 1) | 1));
				longAtput(where + (StackPointerIndex << ShiftForWord), ((tempCount << 1) | 1));
				longAtput(where + (MethodIndex << ShiftForWord), foo->newMethod);
				longAtput(where + (ClosureIndex << ShiftForWord), foo->nilObj);
				argCount2 = foo->argumentCount;
				for (i = 0; i <= argCount2; i += 1) {
					longAtput(where + ((ReceiverIndex + i) << ShiftForWord), longAtPointer(localSP - ((argCount2 - i) * BytesPerWord)));
				}
				methodHeader = foo->nilObj;
				for (i = ((argCount2 + 1) + ReceiverIndex); i <= (tempCount + ReceiverIndex); i += 1) {
					longAtput(where + (i << ShiftForWord), methodHeader);
				}
				/* begin internalPop: */
				localSP -= (argCount2 + 1) * BytesPerWord;
				foo->reclaimableContextCount += 1;
				/* begin internalNewActiveContext: */
				/* begin internalStoreContextRegisters: */
				activeCntx = foo->activeContext;
				/* begin storePointerUnchecked:ofObject:withValue: */
				valuePointer = (((((oopForPointer(localIP)) + 2) - (foo->method + BaseHeaderSize)) << 1) | 1);
				longAtput((activeCntx + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), valuePointer);
				/* begin storePointerUnchecked:ofObject:withValue: */
				valuePointer1 = (((((((usqInt) ((oopForPointer(localSP)) - (activeCntx + BaseHeaderSize))) >> ShiftForWord) - TempFrameStart) + 1) << 1) | 1);
				longAtput((activeCntx + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), valuePointer1);
				if ((((usqInt) newContext)) < (((usqInt) foo->youngStart))) {
					beRootIfOld(newContext);
				}
				foo->activeContext = newContext;
				/* begin internalFetchContextRegisters: */
				tmp = longAt((newContext + BaseHeaderSize) + (MethodIndex << ShiftForWord));
				if ((tmp & 1)) {
					tmp = longAt((newContext + BaseHeaderSize) + (HomeIndex << ShiftForWord));
					if ((((usqInt) tmp)) < (((usqInt) foo->youngStart))) {
						beRootIfOld(tmp);
					}
				} else {
					tmp = newContext;
				}
				localHomeContext = tmp;
				foo->receiver = longAt((tmp + BaseHeaderSize) + (ReceiverIndex << ShiftForWord));
				foo->method = longAt((tmp + BaseHeaderSize) + (MethodIndex << ShiftForWord));
				tmp = ((longAt((newContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord))) >> 1);
				localIP = pointerForOop(((foo->method + tmp) + BaseHeaderSize) - 2);
				tmp = ((longAt((newContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord))) >> 1);
				localSP = pointerForOop((newContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * BytesPerWord));
				/* begin internalQuickCheckForInterrupts */
				if ((foo->interruptCheckCounter -= 1) <= 0) {
					/* begin externalizeIPandSP */
					foo->instructionPointer = oopForPointer(localIP);
					foo->stackPointer = oopForPointer(localSP);
					foo->theHomeContext = localHomeContext;
					checkForInterrupts();
					browserPluginReturnIfNeeded();
					/* begin internalizeIPandSP */
					localIP = pointerForOop(foo->instructionPointer);
					localSP = pointerForOop(foo->stackPointer);
					localHomeContext = foo->theHomeContext;
				}
			l46:	/* end internalExecuteNewMethod */;
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
			}
;
			break;
		case 132:
			/* doubleExtendedDoAnythingBytecode */
			{
				sqInt byte2;
				sqInt opType;
				sqInt byte3;
				sqInt top;
				sqInt oop;
				sqInt oop1;
				sqInt oop2;
				byte2 = byteAtPointer(++localIP);
				byte3 = byteAtPointer(++localIP);
				opType = ((usqInt) byte2) >> 5;
				if (opType == 0) {
					foo->messageSelector = longAt((foo->method + BaseHeaderSize) + ((byte3 + LiteralStart) << ShiftForWord));
					foo->argumentCount = byte2 & 31;
					goto normalSend;
					goto l4;
				}
				if (opType == 1) {
					foo->messageSelector = longAt((foo->method + BaseHeaderSize) + ((byte3 + LiteralStart) << ShiftForWord));
					foo->argumentCount = byte2 & 31;
					goto commonSupersend;
					goto l4;
				}
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				if (opType == 2) {
					/* begin pushReceiverVariable: */
					/* begin internalPush: */
					longAtPointerput(localSP += BytesPerWord, longAt((foo->receiver + BaseHeaderSize) + (byte3 << ShiftForWord)));
					goto l4;
				}
				if (opType == 3) {
					/* begin pushLiteralConstant: */
					/* begin internalPush: */
					longAtPointerput(localSP += BytesPerWord, longAt((foo->method + BaseHeaderSize) + ((byte3 + LiteralStart) << ShiftForWord)));
					goto l4;
				}
				if (opType == 4) {
					/* begin pushLiteralVariable: */
					/* begin internalPush: */
					longAtPointerput(localSP += BytesPerWord, longAt(((longAt((foo->method + BaseHeaderSize) + ((byte3 + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord)));
					goto l4;
				}
				if (opType == 5) {
					top = longAtPointer(localSP);
					/* begin storePointer:ofObject:withValue: */
					oop = foo->receiver;
					if ((((usqInt) oop)) < (((usqInt) foo->youngStart))) {
						possibleRootStoreIntovalue(oop, top);
					}
					longAtput((oop + BaseHeaderSize) + (byte3 << ShiftForWord), top);
					goto l4;
				}
				if (opType == 6) {
					top = longAtPointer(localSP);
					/* begin internalPop: */
					localSP -= 1 * BytesPerWord;
					/* begin storePointer:ofObject:withValue: */
					oop1 = foo->receiver;
					if ((((usqInt) oop1)) < (((usqInt) foo->youngStart))) {
						possibleRootStoreIntovalue(oop1, top);
					}
					longAtput((oop1 + BaseHeaderSize) + (byte3 << ShiftForWord), top);
					goto l4;
				}
				if (opType == 7) {
					top = longAtPointer(localSP);
					/* begin storePointer:ofObject:withValue: */
					oop2 = longAt((foo->method + BaseHeaderSize) + ((byte3 + LiteralStart) << ShiftForWord));
					if ((((usqInt) oop2)) < (((usqInt) foo->youngStart))) {
						possibleRootStoreIntovalue(oop2, top);
					}
					longAtput((oop2 + BaseHeaderSize) + (ValueIndex << ShiftForWord), top);
					goto l4;
				}
			}
;
		l4:	/* end case */;
			break;
		case 133:
			/* singleExtendedSuperBytecode */
			{
				sqInt descriptor;
				descriptor = byteAtPointer(++localIP);
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((descriptor & 31) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((usqInt) descriptor) >> 5;
				/* goto commonSupersend */
			}
;
			
		commonSupersend:
			/* superclassSend */
			{
				sqInt rcvr;
				sqInt classPointer;
				sqInt ccIndex;
				/* inline:  */;
				/* begin superclassOf: */
				classPointer = longAt(((longAt((foo->method + BaseHeaderSize) + (((((((usqInt) (longAt((foo->method + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 10) & 255) - 1) + LiteralStart) << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord));
				foo->lkupClass = longAt((classPointer + BaseHeaderSize) + (SuperclassIndex << ShiftForWord));
				rcvr = longAtPointer(localSP - (foo->argumentCount * BytesPerWord));
				/* begin fetchClassOf: */
				if ((rcvr & 1)) {
					foo->receiverClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
					goto l47;
				}
				ccIndex = (((usqInt) (longAt(rcvr))) >> 12) & 31;
				if (ccIndex == 0) {
					foo->receiverClass = (longAt(rcvr - BaseHeaderSize)) & AllButTypeMask;
					goto l47;
				} else {
					foo->receiverClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
					goto l47;
				}
			l47:	/* end fetchClassOf: */;
				goto commonSend;
			}
;
			break;
		case 134:
			/* secondExtendedSendBytecode */
			{
				sqInt descriptor;
				descriptor = byteAtPointer(++localIP);
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((descriptor & 63) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((usqInt) descriptor) >> 6;
				goto normalSend;
			}
;
			break;
		case 135:
			/* popStackBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 136:
			/* duplicateTopBytecode */
			{
				sqInt object;
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin internalPush: */
				object = longAtPointer(localSP);
				longAtPointerput(localSP += BytesPerWord, object);
			}
;
			break;
		case 137:
			/* pushActiveContextBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				foo->reclaimableContextCount = 0;
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, foo->activeContext);
			}
;
			break;
		case 138:
			/* pushNewArrayBytecode */
			{
				sqInt popValues;
				sqInt array;
				sqInt i;
				sqInt size;
				size = byteAtPointer(++localIP);
				popValues = size > 127;
				size = size & 127;
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin externalizeIPandSP */
				foo->instructionPointer = oopForPointer(localIP);
				foo->stackPointer = oopForPointer(localSP);
				foo->theHomeContext = localHomeContext;
				array = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassArray << ShiftForWord)), size);
				/* begin internalizeIPandSP */
				localIP = pointerForOop(foo->instructionPointer);
				localSP = pointerForOop(foo->stackPointer);
				localHomeContext = foo->theHomeContext;
				if (popValues) {
					for (i = 0; i <= (size - 1); i += 1) {
						longAtput((array + BaseHeaderSize) + (i << ShiftForWord), longAtPointer(localSP - (((size - i) - 1) * BytesPerWord)));
					}
					/* begin internalPop: */
					localSP -= size * BytesPerWord;
				}
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, array);
			}
;
			break;
		case 139:
			/* unknownBytecode */
			{
				error("Unknown bytecode");
			}
;
			break;
		case 140:
			/* pushRemoteTempLongBytecode */
			{
				sqInt tempVectorIndex;
				sqInt remoteTempIndex;
				sqInt tempVector;
				remoteTempIndex = byteAtPointer(++localIP);
				tempVectorIndex = byteAtPointer(++localIP);
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin pushRemoteTemp:inVectorAt: */
				tempVector = longAt((localHomeContext + BaseHeaderSize) + ((tempVectorIndex + TempFrameStart) << ShiftForWord));
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, longAt((tempVector + BaseHeaderSize) + (remoteTempIndex << ShiftForWord)));
			}
;
			break;
		case 141:
			/* storeRemoteTempLongBytecode */
			{
				sqInt tempVectorIndex;
				sqInt remoteTempIndex;
				sqInt tempVector;
				sqInt valuePointer;
				remoteTempIndex = byteAtPointer(++localIP);
				tempVectorIndex = byteAtPointer(++localIP);
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin storeRemoteTemp:inVectorAt: */
				tempVector = longAt((localHomeContext + BaseHeaderSize) + ((tempVectorIndex + TempFrameStart) << ShiftForWord));
				/* begin storePointer:ofObject:withValue: */
				valuePointer = longAtPointer(localSP);
				if ((((usqInt) tempVector)) < (((usqInt) foo->youngStart))) {
					possibleRootStoreIntovalue(tempVector, valuePointer);
				}
				longAtput((tempVector + BaseHeaderSize) + (remoteTempIndex << ShiftForWord), valuePointer);
			}
;
			break;
		case 142:
			/* storeAndPopRemoteTempLongBytecode */
			{
				sqInt tempVectorIndex;
				sqInt remoteTempIndex;
				sqInt tempVector;
				sqInt valuePointer;
				/* begin storeRemoteTempLongBytecode */
				remoteTempIndex = byteAtPointer(++localIP);
				tempVectorIndex = byteAtPointer(++localIP);
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin storeRemoteTemp:inVectorAt: */
				tempVector = longAt((localHomeContext + BaseHeaderSize) + ((tempVectorIndex + TempFrameStart) << ShiftForWord));
				/* begin storePointer:ofObject:withValue: */
				valuePointer = longAtPointer(localSP);
				if ((((usqInt) tempVector)) < (((usqInt) foo->youngStart))) {
					possibleRootStoreIntovalue(tempVector, valuePointer);
				}
				longAtput((tempVector + BaseHeaderSize) + (remoteTempIndex << ShiftForWord), valuePointer);
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			}
;
			break;
		case 143:
			/* pushClosureCopyCopiedValuesBytecode */
			{
				sqInt numArgs;
				sqInt numArgsNumCopied;
				sqInt newClosure;
				sqInt blockSize;
				sqInt i;
				sqInt numCopied;
				sqInt initialIP;
				sqInt newClosure1;
				if (BytesPerWord == 4) {
					imageFormatVersionNumber = 6504;
				} else {
					imageFormatVersionNumber = 68002;
				}
				numArgsNumCopied = byteAtPointer(++localIP);
				numArgs = numArgsNumCopied & 15;
				numCopied = ((usqInt) numArgsNumCopied >> 4);
				blockSize = (byteAtPointer(++localIP)) << 8;
				blockSize += byteAtPointer(++localIP);
				/* begin externalizeIPandSP */
				foo->instructionPointer = oopForPointer(localIP);
				foo->stackPointer = oopForPointer(localSP);
				foo->theHomeContext = localHomeContext;
				/* begin closureNumArgs:instructionPointer:numCopiedValues: */
				initialIP = ((oopForPointer(localIP)) + 2) - (foo->method + BaseHeaderSize);
				newClosure1 = instantiateSmallClasssizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassBlockClosure << ShiftForWord)), (BytesPerWord * (ClosureFirstCopiedValueIndex + numCopied)) + BaseHeaderSize);
				longAtput((newClosure1 + BaseHeaderSize) + (ClosureStartPCIndex << ShiftForWord), ((initialIP << 1) | 1));
				longAtput((newClosure1 + BaseHeaderSize) + (ClosureNumArgsIndex << ShiftForWord), ((numArgs << 1) | 1));
				newClosure = newClosure1;
				/* begin internalizeIPandSP */
				localIP = pointerForOop(foo->instructionPointer);
				localSP = pointerForOop(foo->stackPointer);
				localHomeContext = foo->theHomeContext;
				longAtput((newClosure + BaseHeaderSize) + (ClosureOuterContextIndex << ShiftForWord), foo->activeContext);
				foo->reclaimableContextCount = 0;
				if (numCopied > 0) {
					for (i = 0; i <= (numCopied - 1); i += 1) {
						longAtput((newClosure + BaseHeaderSize) + ((i + ClosureFirstCopiedValueIndex) << ShiftForWord), longAtPointer(localSP - (((numCopied - i) - 1) * BytesPerWord)));
					}
					/* begin internalPop: */
					localSP -= numCopied * BytesPerWord;
				}
				localIP += blockSize;
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				/* begin internalPush: */
				longAtPointerput(localSP += BytesPerWord, newClosure);
			}
;
			break;
		case 144:
			/* shortUnconditionalJump */
			{
				sqInt offset;
				/* begin jump: */
				offset = (144 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAtPointer(localIP);
			}
;
			break;
		case 145:
			/* shortUnconditionalJump */
			{
				sqInt offset;
				/* begin jump: */
				offset = (145 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAtPointer(localIP);
			}
;
			break;
		case 146:
			/* shortUnconditionalJump */
			{
				sqInt offset;
				/* begin jump: */
				offset = (146 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAtPointer(localIP);
			}
;
			break;
		case 147:
			/* shortUnconditionalJump */
			{
				sqInt offset;
				/* begin jump: */
				offset = (147 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAtPointer(localIP);
			}
;
			break;
		case 148:
			/* shortUnconditionalJump */
			{
				sqInt offset;
				/* begin jump: */
				offset = (148 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAtPointer(localIP);
			}
;
			break;
		case 149:
			/* shortUnconditionalJump */
			{
				sqInt offset;
				/* begin jump: */
				offset = (149 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAtPointer(localIP);
			}
;
			break;
		case 150:
			/* shortUnconditionalJump */
			{
				sqInt offset;
				/* begin jump: */
				offset = (150 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAtPointer(localIP);
			}
;
			break;
		case 151:
			/* shortUnconditionalJump */
			{
				sqInt offset;
				/* begin jump: */
				offset = (151 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAtPointer(localIP);
			}
;
			break;
		case 152:
		case 153:
		case 154:
		case 155:
		case 156:
		case 157:
		case 158:
		case 159:
			/* shortConditionalJump */
			{
				sqInt offset;
				sqInt boolean;
				/* begin jumplfFalseBy: */
				offset = (currentBytecode & 7) + 1;
				boolean = longAtPointer(localSP);
				if (boolean == foo->falseObj) {
					/* begin jump: */
					localIP = (localIP + offset) + 1;
					currentBytecode = byteAtPointer(localIP);
				} else {
					if (!(boolean == foo->trueObj)) {
						foo->messageSelector = longAt((foo->specialObjectsOop + BaseHeaderSize) + (SelectorMustBeBoolean << ShiftForWord));
						foo->argumentCount = 0;
						goto normalSend;
						goto l5;
					}
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
				}
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			l5:	/* end jumplfFalseBy: */;
			}
;
			break;
		case 160:
		case 161:
		case 162:
		case 163:
		case 164:
		case 165:
		case 166:
		case 167:
			/* longUnconditionalJump */
			{
				sqInt offset;
				offset = (((currentBytecode & 7) - 4) * 256) + (byteAtPointer(++localIP));
				localIP += offset;
				if (offset < 0) {
					/* begin internalQuickCheckForInterrupts */
					if ((foo->interruptCheckCounter -= 1) <= 0) {
						/* begin externalizeIPandSP */
						foo->instructionPointer = oopForPointer(localIP);
						foo->stackPointer = oopForPointer(localSP);
						foo->theHomeContext = localHomeContext;
						checkForInterrupts();
						browserPluginReturnIfNeeded();
						/* begin internalizeIPandSP */
						localIP = pointerForOop(foo->instructionPointer);
						localSP = pointerForOop(foo->stackPointer);
						localHomeContext = foo->theHomeContext;
					}
				}
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
			}
;
			break;
		case 168:
		case 169:
		case 170:
		case 171:
			/* longJumpIfTrue */
			{
				sqInt offset;
				sqInt boolean;
				/* begin jumplfTrueBy: */
				offset = ((currentBytecode & 3) * 256) + (byteAtPointer(++localIP));
				boolean = longAtPointer(localSP);
				if (boolean == foo->trueObj) {
					/* begin jump: */
					localIP = (localIP + offset) + 1;
					currentBytecode = byteAtPointer(localIP);
				} else {
					if (!(boolean == foo->falseObj)) {
						foo->messageSelector = longAt((foo->specialObjectsOop + BaseHeaderSize) + (SelectorMustBeBoolean << ShiftForWord));
						foo->argumentCount = 0;
						goto normalSend;
						goto l6;
					}
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
				}
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			l6:	/* end jumplfTrueBy: */;
			}
;
			break;
		case 172:
		case 173:
		case 174:
		case 175:
			/* longJumpIfFalse */
			{
				sqInt offset;
				sqInt boolean;
				/* begin jumplfFalseBy: */
				offset = ((currentBytecode & 3) * 256) + (byteAtPointer(++localIP));
				boolean = longAtPointer(localSP);
				if (boolean == foo->falseObj) {
					/* begin jump: */
					localIP = (localIP + offset) + 1;
					currentBytecode = byteAtPointer(localIP);
				} else {
					if (!(boolean == foo->trueObj)) {
						foo->messageSelector = longAt((foo->specialObjectsOop + BaseHeaderSize) + (SelectorMustBeBoolean << ShiftForWord));
						foo->argumentCount = 0;
						goto normalSend;
						goto l7;
					}
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
				}
				/* begin internalPop: */
				localSP -= 1 * BytesPerWord;
			l7:	/* end jumplfFalseBy: */;
			}
;
			break;
		case 176:
			/* bytecodePrimAdd */
			{
				sqInt rcvr;
				sqInt arg;
				sqInt result;
				rcvr = longAtPointer(localSP - (1 * BytesPerWord));
				arg = longAtPointer(localSP - (0 * BytesPerWord));
				if (((rcvr & arg) & 1) != 0) {
					result = ((rcvr >> 1)) + ((arg >> 1));
					if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
						(((((int) result)) ^ ((((int) result)) << 1)) >= 0)
# else
						((result >= -1073741824) && (result <= 1073741823))
# endif  // SQ_HOST32
					) {
						/* begin internalPop:thenPush: */
						longAtPointerput(localSP -= (2 - 1) * BytesPerWord, ((result << 1) | 1));
						/* begin fetchNextBytecode */
						currentBytecode = byteAtPointer(++localIP);
						goto l8;
					}
				} else {
					foo->successFlag = 1;
					/* begin externalizeIPandSP */
					foo->instructionPointer = oopForPointer(localIP);
					foo->stackPointer = oopForPointer(localSP);
					foo->theHomeContext = localHomeContext;
					primitiveFloatAddtoArg(rcvr, arg);
					/* begin internalizeIPandSP */
					localIP = pointerForOop(foo->instructionPointer);
					localSP = pointerForOop(foo->stackPointer);
					localHomeContext = foo->theHomeContext;
					if (foo->successFlag) {
						/* begin fetchNextBytecode */
						currentBytecode = byteAtPointer(++localIP);
						goto l8;
					}
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((0 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l8:	/* end case */;
			break;
		case 177:
			/* bytecodePrimSubtract */
			{
				sqInt rcvr;
				sqInt arg;
				sqInt result;
				rcvr = longAtPointer(localSP - (1 * BytesPerWord));
				arg = longAtPointer(localSP - (0 * BytesPerWord));
				if (((rcvr & arg) & 1) != 0) {
					result = ((rcvr >> 1)) - ((arg >> 1));
					if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
						(((((int) result)) ^ ((((int) result)) << 1)) >= 0)
# else
						((result >= -1073741824) && (result <= 1073741823))
# endif  // SQ_HOST32
					) {
						/* begin internalPop:thenPush: */
						longAtPointerput(localSP -= (2 - 1) * BytesPerWord, ((result << 1) | 1));
						/* begin fetchNextBytecode */
						currentBytecode = byteAtPointer(++localIP);
						goto l9;
					}
				} else {
					foo->successFlag = 1;
					/* begin externalizeIPandSP */
					foo->instructionPointer = oopForPointer(localIP);
					foo->stackPointer = oopForPointer(localSP);
					foo->theHomeContext = localHomeContext;
					primitiveFloatSubtractfromArg(rcvr, arg);
					/* begin internalizeIPandSP */
					localIP = pointerForOop(foo->instructionPointer);
					localSP = pointerForOop(foo->stackPointer);
					localHomeContext = foo->theHomeContext;
					if (foo->successFlag) {
						/* begin fetchNextBytecode */
						currentBytecode = byteAtPointer(++localIP);
						goto l9;
					}
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((1 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l9:	/* end case */;
			break;
		case 178:
			/* bytecodePrimLessThan */
			{
				sqInt rcvr;
				sqInt aBool;
				sqInt arg;
				sqInt bytecode;
				sqInt offset;
				sqInt bytecode1;
				sqInt offset1;
				sqInt bytecode2;
				sqInt offset2;
				rcvr = longAtPointer(localSP - (1 * BytesPerWord));
				arg = longAtPointer(localSP - (0 * BytesPerWord));
				if (((rcvr & arg) & 1) != 0) {
					;
					/* begin booleanCheat: */
					bytecode1 = byteAtPointer(++localIP);
					/* begin internalPop: */
					localSP -= 2 * BytesPerWord;
					if ((bytecode1 < 160) && (bytecode1 > 151)) {
						if (rcvr < arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l10;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode1 - 151)) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l10;
						}
					}
					if (bytecode1 == 172) {
						offset1 = byteAtPointer(++localIP);
						if (rcvr < arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l10;
						} else {
							/* begin jump: */
							localIP = (localIP + offset1) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l10;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					if (rcvr < arg) {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->falseObj);
					}
					goto l10;
				}
				foo->successFlag = 1;
				aBool = primitiveFloatLessthanArg(rcvr, arg);
				if (foo->successFlag) {
					/* begin booleanCheat: */
					bytecode2 = byteAtPointer(++localIP);
					/* begin internalPop: */
					localSP -= 2 * BytesPerWord;
					if ((bytecode2 < 160) && (bytecode2 > 151)) {
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l10;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode2 - 151)) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l10;
						}
					}
					if (bytecode2 == 172) {
						offset2 = byteAtPointer(++localIP);
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l10;
						} else {
							/* begin jump: */
							localIP = (localIP + offset2) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l10;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					if (aBool) {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->falseObj);
					}
					goto l10;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((2 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l10:	/* end case */;
			break;
		case 179:
			/* bytecodePrimGreaterThan */
			{
				sqInt rcvr;
				sqInt aBool;
				sqInt arg;
				sqInt bytecode;
				sqInt offset;
				sqInt bytecode1;
				sqInt offset1;
				sqInt bytecode2;
				sqInt offset2;
				rcvr = longAtPointer(localSP - (1 * BytesPerWord));
				arg = longAtPointer(localSP - (0 * BytesPerWord));
				if (((rcvr & arg) & 1) != 0) {
					;
					/* begin booleanCheat: */
					bytecode1 = byteAtPointer(++localIP);
					/* begin internalPop: */
					localSP -= 2 * BytesPerWord;
					if ((bytecode1 < 160) && (bytecode1 > 151)) {
						if (rcvr > arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l11;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode1 - 151)) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l11;
						}
					}
					if (bytecode1 == 172) {
						offset1 = byteAtPointer(++localIP);
						if (rcvr > arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l11;
						} else {
							/* begin jump: */
							localIP = (localIP + offset1) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l11;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					if (rcvr > arg) {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->falseObj);
					}
					goto l11;
				}
				foo->successFlag = 1;
				aBool = primitiveFloatGreaterthanArg(rcvr, arg);
				if (foo->successFlag) {
					/* begin booleanCheat: */
					bytecode2 = byteAtPointer(++localIP);
					/* begin internalPop: */
					localSP -= 2 * BytesPerWord;
					if ((bytecode2 < 160) && (bytecode2 > 151)) {
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l11;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode2 - 151)) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l11;
						}
					}
					if (bytecode2 == 172) {
						offset2 = byteAtPointer(++localIP);
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l11;
						} else {
							/* begin jump: */
							localIP = (localIP + offset2) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l11;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					if (aBool) {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->falseObj);
					}
					goto l11;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((3 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l11:	/* end case */;
			break;
		case 180:
			/* bytecodePrimLessOrEqual */
			{
				sqInt rcvr;
				sqInt aBool;
				sqInt arg;
				sqInt bytecode;
				sqInt offset;
				sqInt bytecode1;
				sqInt offset1;
				sqInt bytecode2;
				sqInt offset2;
				rcvr = longAtPointer(localSP - (1 * BytesPerWord));
				arg = longAtPointer(localSP - (0 * BytesPerWord));
				if (((rcvr & arg) & 1) != 0) {
					;
					/* begin booleanCheat: */
					bytecode1 = byteAtPointer(++localIP);
					/* begin internalPop: */
					localSP -= 2 * BytesPerWord;
					if ((bytecode1 < 160) && (bytecode1 > 151)) {
						if (rcvr <= arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l12;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode1 - 151)) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l12;
						}
					}
					if (bytecode1 == 172) {
						offset1 = byteAtPointer(++localIP);
						if (rcvr <= arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l12;
						} else {
							/* begin jump: */
							localIP = (localIP + offset1) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l12;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					if (rcvr <= arg) {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->falseObj);
					}
					goto l12;
				}
				foo->successFlag = 1;
				aBool = primitiveFloatLessOrEqualtoArg(rcvr, arg);
				if (foo->successFlag) {
					/* begin booleanCheat: */
					bytecode2 = byteAtPointer(++localIP);
					/* begin internalPop: */
					localSP -= 2 * BytesPerWord;
					if ((bytecode2 < 160) && (bytecode2 > 151)) {
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l12;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode2 - 151)) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l12;
						}
					}
					if (bytecode2 == 172) {
						offset2 = byteAtPointer(++localIP);
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l12;
						} else {
							/* begin jump: */
							localIP = (localIP + offset2) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l12;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					if (aBool) {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->falseObj);
					}
					goto l12;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((4 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l12:	/* end case */;
			break;
		case 181:
			/* bytecodePrimGreaterOrEqual */
			{
				sqInt rcvr;
				sqInt aBool;
				sqInt arg;
				sqInt bytecode;
				sqInt offset;
				sqInt bytecode1;
				sqInt offset1;
				sqInt bytecode2;
				sqInt offset2;
				rcvr = longAtPointer(localSP - (1 * BytesPerWord));
				arg = longAtPointer(localSP - (0 * BytesPerWord));
				if (((rcvr & arg) & 1) != 0) {
					;
					/* begin booleanCheat: */
					bytecode1 = byteAtPointer(++localIP);
					/* begin internalPop: */
					localSP -= 2 * BytesPerWord;
					if ((bytecode1 < 160) && (bytecode1 > 151)) {
						if (rcvr >= arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l13;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode1 - 151)) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l13;
						}
					}
					if (bytecode1 == 172) {
						offset1 = byteAtPointer(++localIP);
						if (rcvr >= arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l13;
						} else {
							/* begin jump: */
							localIP = (localIP + offset1) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l13;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					if (rcvr >= arg) {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->falseObj);
					}
					goto l13;
				}
				foo->successFlag = 1;
				aBool = primitiveFloatGreaterOrEqualtoArg(rcvr, arg);
				if (foo->successFlag) {
					/* begin booleanCheat: */
					bytecode2 = byteAtPointer(++localIP);
					/* begin internalPop: */
					localSP -= 2 * BytesPerWord;
					if ((bytecode2 < 160) && (bytecode2 > 151)) {
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l13;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode2 - 151)) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l13;
						}
					}
					if (bytecode2 == 172) {
						offset2 = byteAtPointer(++localIP);
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l13;
						} else {
							/* begin jump: */
							localIP = (localIP + offset2) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l13;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					if (aBool) {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->falseObj);
					}
					goto l13;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((5 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l13:	/* end case */;
			break;
		case 182:
			/* bytecodePrimEqual */
			{
				sqInt rcvr;
				sqInt aBool;
				sqInt arg;
				sqInt bytecode;
				sqInt offset;
				sqInt bytecode1;
				sqInt offset1;
				rcvr = longAtPointer(localSP - (1 * BytesPerWord));
				arg = longAtPointer(localSP - (0 * BytesPerWord));
				if (((rcvr & arg) & 1) != 0) {
					/* begin booleanCheat: */
					bytecode = byteAtPointer(++localIP);
					/* begin internalPop: */
					localSP -= 2 * BytesPerWord;
					if ((bytecode < 160) && (bytecode > 151)) {
						if (rcvr == arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l14;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode - 151)) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l14;
						}
					}
					if (bytecode == 172) {
						offset = byteAtPointer(++localIP);
						if (rcvr == arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l14;
						} else {
							/* begin jump: */
							localIP = (localIP + offset) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l14;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					if (rcvr == arg) {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->falseObj);
					}
					goto l14;
				}
				foo->successFlag = 1;
				aBool = primitiveFloatEqualtoArg(rcvr, arg);
				if (foo->successFlag) {
					/* begin booleanCheat: */
					bytecode1 = byteAtPointer(++localIP);
					/* begin internalPop: */
					localSP -= 2 * BytesPerWord;
					if ((bytecode1 < 160) && (bytecode1 > 151)) {
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l14;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode1 - 151)) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l14;
						}
					}
					if (bytecode1 == 172) {
						offset1 = byteAtPointer(++localIP);
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l14;
						} else {
							/* begin jump: */
							localIP = (localIP + offset1) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l14;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					if (aBool) {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->falseObj);
					}
					goto l14;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((6 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l14:	/* end case */;
			break;
		case 183:
			/* bytecodePrimNotEqual */
			{
				sqInt rcvr;
				sqInt aBool;
				sqInt arg;
				sqInt bytecode;
				sqInt offset;
				sqInt bytecode1;
				sqInt offset1;
				rcvr = longAtPointer(localSP - (1 * BytesPerWord));
				arg = longAtPointer(localSP - (0 * BytesPerWord));
				if (((rcvr & arg) & 1) != 0) {
					/* begin booleanCheat: */
					bytecode = byteAtPointer(++localIP);
					/* begin internalPop: */
					localSP -= 2 * BytesPerWord;
					if ((bytecode < 160) && (bytecode > 151)) {
						if (rcvr != arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l15;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode - 151)) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l15;
						}
					}
					if (bytecode == 172) {
						offset = byteAtPointer(++localIP);
						if (rcvr != arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l15;
						} else {
							/* begin jump: */
							localIP = (localIP + offset) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l15;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					if (rcvr != arg) {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->falseObj);
					}
					goto l15;
				}
				foo->successFlag = 1;
				aBool = primitiveFloatEqualtoArg(rcvr, arg);
				if (foo->successFlag) {
					/* begin booleanCheat: */
					bytecode1 = byteAtPointer(++localIP);
					/* begin internalPop: */
					localSP -= 2 * BytesPerWord;
					if ((bytecode1 < 160) && (bytecode1 > 151)) {
						if (!aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l15;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode1 - 151)) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l15;
						}
					}
					if (bytecode1 == 172) {
						offset1 = byteAtPointer(++localIP);
						if (!aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l15;
						} else {
							/* begin jump: */
							localIP = (localIP + offset1) + 1;
							currentBytecode = byteAtPointer(localIP);
							goto l15;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					if (!aBool) {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtPointerput(localSP += BytesPerWord, foo->falseObj);
					}
					goto l15;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((7 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l15:	/* end case */;
			break;
		case 184:
			/* bytecodePrimMultiply */
			{
				sqInt rcvr;
				sqInt arg;
				sqInt result;
				rcvr = longAtPointer(localSP - (1 * BytesPerWord));
				arg = longAtPointer(localSP - (0 * BytesPerWord));
				if (((rcvr & arg) & 1) != 0) {
					rcvr = (rcvr >> 1);
					arg = (arg >> 1);
					result = rcvr * arg;
					if (((arg == 0) || ((result / arg) == rcvr)) && (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
	(((((int) result)) ^ ((((int) result)) << 1)) >= 0)
# else
	((result >= -1073741824) && (result <= 1073741823))
# endif  // SQ_HOST32
)) {
						/* begin internalPop:thenPush: */
						longAtPointerput(localSP -= (2 - 1) * BytesPerWord, ((result << 1) | 1));
						/* begin fetchNextBytecode */
						currentBytecode = byteAtPointer(++localIP);
						goto l16;
					}
				} else {
					foo->successFlag = 1;
					/* begin externalizeIPandSP */
					foo->instructionPointer = oopForPointer(localIP);
					foo->stackPointer = oopForPointer(localSP);
					foo->theHomeContext = localHomeContext;
					primitiveFloatMultiplybyArg(rcvr, arg);
					/* begin internalizeIPandSP */
					localIP = pointerForOop(foo->instructionPointer);
					localSP = pointerForOop(foo->stackPointer);
					localHomeContext = foo->theHomeContext;
					if (foo->successFlag) {
						/* begin fetchNextBytecode */
						currentBytecode = byteAtPointer(++localIP);
						goto l16;
					}
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((8 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l16:	/* end case */;
			break;
		case 185:
			/* bytecodePrimDivide */
			{
				sqInt rcvr;
				sqInt arg;
				sqInt result;
				rcvr = longAtPointer(localSP - (1 * BytesPerWord));
				arg = longAtPointer(localSP - (0 * BytesPerWord));
				if (((rcvr & arg) & 1) != 0) {
					rcvr = (rcvr >> 1);
					arg = (arg >> 1);
					if ((arg != 0) && ((rcvr % arg) == 0)) {
						result = rcvr / arg;
						if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
							(((((int) result)) ^ ((((int) result)) << 1)) >= 0)
# else
							((result >= -1073741824) && (result <= 1073741823))
# endif  // SQ_HOST32
						) {
							/* begin internalPop:thenPush: */
							longAtPointerput(localSP -= (2 - 1) * BytesPerWord, ((result << 1) | 1));
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							goto l17;
						}
					}
				} else {
					foo->successFlag = 1;
					/* begin externalizeIPandSP */
					foo->instructionPointer = oopForPointer(localIP);
					foo->stackPointer = oopForPointer(localSP);
					foo->theHomeContext = localHomeContext;
					primitiveFloatDividebyArg(rcvr, arg);
					/* begin internalizeIPandSP */
					localIP = pointerForOop(foo->instructionPointer);
					localSP = pointerForOop(foo->stackPointer);
					localHomeContext = foo->theHomeContext;
					if (foo->successFlag) {
						/* begin fetchNextBytecode */
						currentBytecode = byteAtPointer(++localIP);
						goto l17;
					}
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((9 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l17:	/* end case */;
			break;
		case 186:
			/* bytecodePrimMod */
			{
				sqInt mod;
				foo->successFlag = 1;
				mod = doPrimitiveModby(longAtPointer(localSP - (1 * BytesPerWord)), longAtPointer(localSP - (0 * BytesPerWord)));
				if (foo->successFlag) {
					/* begin internalPop:thenPush: */
					longAtPointerput(localSP -= (2 - 1) * BytesPerWord, ((mod << 1) | 1));
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					goto l18;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((10 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l18:	/* end case */;
			break;
		case 187:
			/* bytecodePrimMakePoint */
			{
				sqInt pt;
				sqInt rcvr;
				sqInt argument;
				sqInt pointResult;
				sqInt pointResult1;
				sqInt valuePointer;
				sqInt pointResult2;
				sqInt valuePointer1;
				sqInt valuePointer2;
				sqInt sp;
				foo->successFlag = 1;
				/* begin externalizeIPandSP */
				foo->instructionPointer = oopForPointer(localIP);
				foo->stackPointer = oopForPointer(localSP);
				foo->theHomeContext = localHomeContext;
				/* begin primitiveMakePoint */
				argument = longAt(foo->stackPointer);
				rcvr = longAt(foo->stackPointer - (1 * BytesPerWord));
				if ((rcvr & 1)) {
					if ((argument & 1)) {
						/* begin makePointwithxValue:yValue: */
						pointResult = instantiateSmallClasssizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassPoint << ShiftForWord)), 3 * BytesPerWord);
						longAtput((pointResult + BaseHeaderSize) + (XIndex << ShiftForWord), ((((rcvr >> 1)) << 1) | 1));
						longAtput((pointResult + BaseHeaderSize) + (YIndex << ShiftForWord), ((((argument >> 1)) << 1) | 1));
						pt = pointResult;
					} else {
						/* begin makePointwithxValue:yValue: */
						pointResult1 = instantiateSmallClasssizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassPoint << ShiftForWord)), 3 * BytesPerWord);
						longAtput((pointResult1 + BaseHeaderSize) + (XIndex << ShiftForWord), ((((rcvr >> 1)) << 1) | 1));
						longAtput((pointResult1 + BaseHeaderSize) + (YIndex << ShiftForWord), ((0 << 1) | 1));
						pt = pointResult1;
						/* begin storePointer:ofObject:withValue: */
						valuePointer = longAt(foo->stackPointer - (0 * BytesPerWord));
						if ((((usqInt) pt)) < (((usqInt) foo->youngStart))) {
							possibleRootStoreIntovalue(pt, valuePointer);
						}
						longAtput((pt + BaseHeaderSize) + (1 << ShiftForWord), valuePointer);
					}
				} else {
					if (!((fetchClassOf(rcvr)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord))))) {
						/* begin success: */
						foo->successFlag = 0 && foo->successFlag;
						goto l20;
					}
					/* begin makePointwithxValue:yValue: */
					pointResult2 = instantiateSmallClasssizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassPoint << ShiftForWord)), 3 * BytesPerWord);
					longAtput((pointResult2 + BaseHeaderSize) + (XIndex << ShiftForWord), ((0 << 1) | 1));
					longAtput((pointResult2 + BaseHeaderSize) + (YIndex << ShiftForWord), ((0 << 1) | 1));
					pt = pointResult2;
					/* begin storePointer:ofObject:withValue: */
					valuePointer1 = longAt(foo->stackPointer - (1 * BytesPerWord));
					if ((((usqInt) pt)) < (((usqInt) foo->youngStart))) {
						possibleRootStoreIntovalue(pt, valuePointer1);
					}
					longAtput((pt + BaseHeaderSize) + (0 << ShiftForWord), valuePointer1);
					/* begin storePointer:ofObject:withValue: */
					valuePointer2 = longAt(foo->stackPointer - (0 * BytesPerWord));
					if ((((usqInt) pt)) < (((usqInt) foo->youngStart))) {
						possibleRootStoreIntovalue(pt, valuePointer2);
					}
					longAtput((pt + BaseHeaderSize) + (1 << ShiftForWord), valuePointer2);
				}
				/* begin pop:thenPush: */
				longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), pt);
				foo->stackPointer = sp;
			l20:	/* end primitiveMakePoint */;
				/* begin internalizeIPandSP */
				localIP = pointerForOop(foo->instructionPointer);
				localSP = pointerForOop(foo->stackPointer);
				localHomeContext = foo->theHomeContext;
				if (foo->successFlag) {
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					goto l19;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((11 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l19:	/* end case */;
			break;
		case 188:
			/* bytecodePrimBitShift */
			{
				sqInt integerArgument;
				sqInt shifted;
				sqInt integerReceiver;
				sqInt integerPointer;
				sqInt object;
				sqInt sp;
				sqInt top;
				sqInt top2;
				sqInt top1;
				foo->successFlag = 1;
				/* begin externalizeIPandSP */
				foo->instructionPointer = oopForPointer(localIP);
				foo->stackPointer = oopForPointer(localSP);
				foo->theHomeContext = localHomeContext;
				/* begin primitiveBitShift */
				/* begin popInteger */
				/* begin popStack */
				top = longAt(foo->stackPointer);
				foo->stackPointer -= BytesPerWord;
				integerPointer = top;
				/* begin checkedIntegerValueOf: */
				if ((integerPointer & 1)) {
					integerArgument = (integerPointer >> 1);
					goto l22;
				} else {
					/* begin primitiveFail */
					foo->successFlag = 0;
					integerArgument = 0;
					goto l22;
				}
			l22:	/* end checkedIntegerValueOf: */;
				/* begin popPos32BitInteger */
				/* begin popStack */
				top1 = longAt(foo->stackPointer);
				foo->stackPointer -= BytesPerWord;
				top2 = top1;
				integerReceiver = positive32BitValueOf(top2);
				if (foo->successFlag) {
					if (integerArgument >= 0) {
						/* begin success: */
						foo->successFlag = (integerArgument <= 31) && foo->successFlag;
						shifted = integerReceiver << integerArgument;
						/* begin success: */
						foo->successFlag = ((((usqInt) shifted) >> integerArgument) == integerReceiver) && foo->successFlag;
					} else {
						/* begin success: */
						foo->successFlag = (integerArgument >= -31) && foo->successFlag;
						shifted = ((integerArgument < 0) ? ((usqInt) integerReceiver >> -integerArgument) : ((usqInt) integerReceiver << integerArgument));
					}
				}
				if (foo->successFlag) {
					/* begin push: */
					object = positive32BitIntegerFor(shifted);
					longAtput(sp = foo->stackPointer + BytesPerWord, object);
					foo->stackPointer = sp;
				} else {
					/* begin unPop: */
					foo->stackPointer += 2 * BytesPerWord;
				}
				/* begin internalizeIPandSP */
				localIP = pointerForOop(foo->instructionPointer);
				localSP = pointerForOop(foo->stackPointer);
				localHomeContext = foo->theHomeContext;
				if (foo->successFlag) {
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					goto l21;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((12 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l21:	/* end case */;
			break;
		case 189:
			/* bytecodePrimDiv */
			{
				sqInt quotient;
				foo->successFlag = 1;
				quotient = doPrimitiveDivby(longAtPointer(localSP - (1 * BytesPerWord)), longAtPointer(localSP - (0 * BytesPerWord)));
				if (foo->successFlag) {
					/* begin internalPop:thenPush: */
					longAtPointerput(localSP -= (2 - 1) * BytesPerWord, ((quotient << 1) | 1));
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					goto l23;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((13 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l23:	/* end case */;
			break;
		case 190:
			/* bytecodePrimBitAnd */
			{
				sqInt integerArgument;
				sqInt integerReceiver;
				sqInt object;
				sqInt sp;
				sqInt top;
				sqInt top1;
				sqInt top2;
				sqInt top11;
				foo->successFlag = 1;
				/* begin externalizeIPandSP */
				foo->instructionPointer = oopForPointer(localIP);
				foo->stackPointer = oopForPointer(localSP);
				foo->theHomeContext = localHomeContext;
				/* begin primitiveBitAnd */
				/* begin popPos32BitInteger */
				/* begin popStack */
				top1 = longAt(foo->stackPointer);
				foo->stackPointer -= BytesPerWord;
				top = top1;
				integerArgument = positive32BitValueOf(top);
				/* begin popPos32BitInteger */
				/* begin popStack */
				top11 = longAt(foo->stackPointer);
				foo->stackPointer -= BytesPerWord;
				top2 = top11;
				integerReceiver = positive32BitValueOf(top2);
				if (foo->successFlag) {
					/* begin push: */
					object = positive32BitIntegerFor(integerReceiver & integerArgument);
					longAtput(sp = foo->stackPointer + BytesPerWord, object);
					foo->stackPointer = sp;
				} else {
					/* begin unPop: */
					foo->stackPointer += 2 * BytesPerWord;
				}
				/* begin internalizeIPandSP */
				localIP = pointerForOop(foo->instructionPointer);
				localSP = pointerForOop(foo->stackPointer);
				localHomeContext = foo->theHomeContext;
				if (foo->successFlag) {
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					goto l24;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((14 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l24:	/* end case */;
			break;
		case 191:
			/* bytecodePrimBitOr */
			{
				sqInt integerArgument;
				sqInt integerReceiver;
				sqInt object;
				sqInt sp;
				sqInt top;
				sqInt top1;
				sqInt top2;
				sqInt top11;
				foo->successFlag = 1;
				/* begin externalizeIPandSP */
				foo->instructionPointer = oopForPointer(localIP);
				foo->stackPointer = oopForPointer(localSP);
				foo->theHomeContext = localHomeContext;
				/* begin primitiveBitOr */
				/* begin popPos32BitInteger */
				/* begin popStack */
				top1 = longAt(foo->stackPointer);
				foo->stackPointer -= BytesPerWord;
				top = top1;
				integerArgument = positive32BitValueOf(top);
				/* begin popPos32BitInteger */
				/* begin popStack */
				top11 = longAt(foo->stackPointer);
				foo->stackPointer -= BytesPerWord;
				top2 = top11;
				integerReceiver = positive32BitValueOf(top2);
				if (foo->successFlag) {
					/* begin push: */
					object = positive32BitIntegerFor(integerReceiver | integerArgument);
					longAtput(sp = foo->stackPointer + BytesPerWord, object);
					foo->stackPointer = sp;
				} else {
					/* begin unPop: */
					foo->stackPointer += 2 * BytesPerWord;
				}
				/* begin internalizeIPandSP */
				localIP = pointerForOop(foo->instructionPointer);
				localSP = pointerForOop(foo->stackPointer);
				localHomeContext = foo->theHomeContext;
				if (foo->successFlag) {
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					goto l25;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((15 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l25:	/* end case */;
			break;
		case 192:
			/* bytecodePrimAt */
			{
				sqInt atIx;
				sqInt rcvr;
				sqInt result;
				sqInt index;
				sqInt fmt;
				sqInt result1;
				sqInt stSize;
				sqInt fixedFields;
				index = longAtPointer(localSP);
				rcvr = longAtPointer(localSP - (1 * BytesPerWord));
				foo->successFlag = (!((rcvr & 1))) && ((index & 1));
				if (foo->successFlag) {
					atIx = rcvr & AtCacheMask;
					if ((foo->atCache[atIx + AtCacheOop]) == rcvr) {
						/* begin commonVariableInternal:at:cacheIndex: */
						stSize = foo->atCache[atIx + AtCacheSize];
						if (((((usqInt) ((index >> 1)))) >= (((usqInt) 1))) && ((((usqInt) ((index >> 1)))) <= (((usqInt) stSize)))) {
							fmt = foo->atCache[atIx + AtCacheFmt];
							if (fmt <= 4) {
								fixedFields = foo->atCache[atIx + AtCacheFixedFields];
								result = longAt((rcvr + BaseHeaderSize) + (((((index >> 1)) + fixedFields) - 1) << ShiftForWord));
								goto l27;
							}
							if (fmt < 8) {
								result1 = long32At((rcvr + BaseHeaderSize) + ((((index >> 1)) - 1) << 2));
								/* begin externalizeIPandSP */
								foo->instructionPointer = oopForPointer(localIP);
								foo->stackPointer = oopForPointer(localSP);
								foo->theHomeContext = localHomeContext;
								result1 = positive32BitIntegerFor(result1);
								/* begin internalizeIPandSP */
								localIP = pointerForOop(foo->instructionPointer);
								localSP = pointerForOop(foo->stackPointer);
								localHomeContext = foo->theHomeContext;
								result = result1;
								goto l27;
							}
							if (fmt >= 16) {
								result = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CharacterTable << ShiftForWord))) + BaseHeaderSize) + ((byteAt((rcvr + BaseHeaderSize) + (((index >> 1)) - 1))) << ShiftForWord));
								goto l27;
							} else {
								result = (((byteAt((rcvr + BaseHeaderSize) + (((index >> 1)) - 1))) << 1) | 1);
								goto l27;
							}
						}
						/* begin primitiveFail */
						foo->successFlag = 0;
					l27:	/* end commonVariableInternal:at:cacheIndex: */;
						if (foo->successFlag) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							/* begin internalPop:thenPush: */
							longAtPointerput(localSP -= (2 - 1) * BytesPerWord, result);
							goto l26;
						}
					}
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((16 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l26:	/* end case */;
			break;
		case 193:
			/* bytecodePrimAtPut */
			{
				sqInt value;
				sqInt atIx;
				sqInt rcvr;
				sqInt index;
				sqInt valToPut;
				sqInt fmt;
				sqInt stSize;
				sqInt fixedFields;
				value = longAtPointer(localSP);
				index = longAtPointer(localSP - (1 * BytesPerWord));
				rcvr = longAtPointer(localSP - (2 * BytesPerWord));
				foo->successFlag = (!((rcvr & 1))) && ((index & 1));
				if (foo->successFlag) {
					atIx = (rcvr & AtCacheMask) + AtPutBase;
					if ((foo->atCache[atIx + AtCacheOop]) == rcvr) {
						/* begin commonVariable:at:put:cacheIndex: */
						stSize = foo->atCache[atIx + AtCacheSize];
						if (((((usqInt) ((index >> 1)))) >= (((usqInt) 1))) && ((((usqInt) ((index >> 1)))) <= (((usqInt) stSize)))) {
							fmt = foo->atCache[atIx + AtCacheFmt];
							if (fmt <= 4) {
								fixedFields = foo->atCache[atIx + AtCacheFixedFields];
								/* begin storePointer:ofObject:withValue: */
								if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
									possibleRootStoreIntovalue(rcvr, value);
								}
								longAtput((rcvr + BaseHeaderSize) + (((((index >> 1)) + fixedFields) - 1) << ShiftForWord), value);
								goto l29;
							}
							if (fmt < 8) {
								valToPut = positive32BitValueOf(value);
								if (foo->successFlag) {
									long32Atput((rcvr + BaseHeaderSize) + ((((index >> 1)) - 1) << 2), valToPut);
								}
								goto l29;
							}
							if (fmt >= 16) {
								valToPut = asciiOfCharacter(value);
								if (!(foo->successFlag)) {
									goto l29;
								}
							} else {
								valToPut = value;
							}
							if ((valToPut & 1)) {
								valToPut = (valToPut >> 1);
								if (!((valToPut >= 0) && (valToPut <= 255))) {
									/* begin primitiveFail */
									foo->successFlag = 0;
									goto l29;
								}
								byteAtput((rcvr + BaseHeaderSize) + (((index >> 1)) - 1), valToPut);
								goto l29;
							}
						}
						/* begin primitiveFail */
						foo->successFlag = 0;
					l29:	/* end commonVariable:at:put:cacheIndex: */;
						if (foo->successFlag) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAtPointer(++localIP);
							/* begin internalPop:thenPush: */
							longAtPointerput(localSP -= (3 - 1) * BytesPerWord, value);
							goto l28;
						}
					}
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((17 * 2) << ShiftForWord));
				foo->argumentCount = 2;
				goto normalSend;
			}
;
		l28:	/* end case */;
			break;
		case 194:
			/* bytecodePrimSize */
			{
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((18 * 2) << ShiftForWord));
				foo->argumentCount = 0;
				goto normalSend;
			}
;
			break;
		case 195:
			/* bytecodePrimNext */
			{
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((19 * 2) << ShiftForWord));
				foo->argumentCount = 0;
				goto normalSend;
			}
;
			break;
		case 196:
			/* bytecodePrimNextPut */
			{
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((20 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
			break;
		case 197:
			/* bytecodePrimAtEnd */
			{
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((21 * 2) << ShiftForWord));
				foo->argumentCount = 0;
				goto normalSend;
			}
;
			break;
		case 198:
			/* bytecodePrimEquivalent */
			{
				sqInt rcvr;
				sqInt arg;
				sqInt bytecode;
				sqInt offset;
				rcvr = longAtPointer(localSP - (1 * BytesPerWord));
				arg = longAtPointer(localSP - (0 * BytesPerWord));
				/* begin booleanCheat: */
				bytecode = byteAtPointer(++localIP);
				/* begin internalPop: */
				localSP -= 2 * BytesPerWord;
				if ((bytecode < 160) && (bytecode > 151)) {
					if (rcvr == arg) {
						/* begin fetchNextBytecode */
						currentBytecode = byteAtPointer(++localIP);
						goto l30;
					} else {
						/* begin jump: */
						localIP = (localIP + (bytecode - 151)) + 1;
						currentBytecode = byteAtPointer(localIP);
						goto l30;
					}
				}
				if (bytecode == 172) {
					offset = byteAtPointer(++localIP);
					if (rcvr == arg) {
						/* begin fetchNextBytecode */
						currentBytecode = byteAtPointer(++localIP);
						goto l30;
					} else {
						/* begin jump: */
						localIP = (localIP + offset) + 1;
						currentBytecode = byteAtPointer(localIP);
						goto l30;
					}
				}
				localIP -= 1;
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
				if (rcvr == arg) {
					/* begin internalPush: */
					longAtPointerput(localSP += BytesPerWord, foo->trueObj);
				} else {
					/* begin internalPush: */
					longAtPointerput(localSP += BytesPerWord, foo->falseObj);
				}
			l30:	/* end booleanCheat: */;
			}
;
			break;
		case 199:
			/* bytecodePrimClass */
			{
				sqInt rcvr;
				sqInt oop;
				sqInt ccIndex;
				rcvr = longAtPointer(localSP);
				/* begin internalPop:thenPush: */
				/* begin fetchClassOf: */
				if ((rcvr & 1)) {
					oop = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
					goto l31;
				}
				ccIndex = (((usqInt) (longAt(rcvr))) >> 12) & 31;
				if (ccIndex == 0) {
					oop = (longAt(rcvr - BaseHeaderSize)) & AllButTypeMask;
					goto l31;
				} else {
					oop = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
					goto l31;
				}
			l31:	/* end fetchClassOf: */;
				longAtPointerput(localSP -= (1 - 1) * BytesPerWord, oop);
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
			}
;
			break;
		case 200:
			/* bytecodePrimBlockCopy */
			{
				sqInt rcvr;
				sqInt hdr;
				sqInt successValue;
				sqInt initialIP;
				sqInt newContext;
				sqInt context;
				sqInt methodContext;
				sqInt contextSize;
				sqInt header;
				sqInt oop;
				sqInt sp;
				rcvr = longAtPointer(localSP - (1 * BytesPerWord));
				foo->successFlag = 1;
				hdr = longAt(rcvr);
				/* begin success: */
				successValue = (((((usqInt) hdr) >> 12) & 31) == 13) || ((((((usqInt) hdr) >> 12) & 31) == 14) || (((((usqInt) hdr) >> 12) & 31) == 4));
				foo->successFlag = successValue && foo->successFlag;
				if (foo->successFlag) {
					/* begin externalizeIPandSP */
					foo->instructionPointer = oopForPointer(localIP);
					foo->stackPointer = oopForPointer(localSP);
					foo->theHomeContext = localHomeContext;
					/* begin primitiveBlockCopy */
					context = longAt(foo->stackPointer - (1 * BytesPerWord));
					if (((longAt((context + BaseHeaderSize) + (MethodIndex << ShiftForWord))) & 1)) {
						methodContext = longAt((context + BaseHeaderSize) + (HomeIndex << ShiftForWord));
					} else {
						methodContext = context;
					}
					/* begin sizeBitsOf: */
					header = longAt(methodContext);
					if ((header & TypeMask) == HeaderTypeSizeAndClass) {
						contextSize = (longAt(methodContext - (BytesPerWord * 2))) & LongSizeMask;
						goto l33;
					} else {
						contextSize = header & SizeMask;
						goto l33;
					}
				l33:	/* end sizeBitsOf: */;
					context = null;
					/* begin pushRemappableOop: */
					foo->remapBuffer[foo->remapBufferCount += 1] = methodContext;
					newContext = instantiateContextsizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassBlockContext << ShiftForWord)), contextSize);
					/* begin popRemappableOop */
					oop = foo->remapBuffer[foo->remapBufferCount];
					foo->remapBufferCount -= 1;
					methodContext = oop;
					initialIP = (((((foo->instructionPointer + 1) + 3) - (foo->method + BaseHeaderSize)) << 1) | 1);
					longAtput((newContext + BaseHeaderSize) + (InitialIPIndex << ShiftForWord), initialIP);
					longAtput((newContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), initialIP);
					/* begin storeStackPointerValue:inContext: */
					longAtput((newContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), ((0 << 1) | 1));
					longAtput((newContext + BaseHeaderSize) + (BlockArgumentCountIndex << ShiftForWord), longAt(foo->stackPointer - (0 * BytesPerWord)));
					longAtput((newContext + BaseHeaderSize) + (HomeIndex << ShiftForWord), methodContext);
					longAtput((newContext + BaseHeaderSize) + (SenderIndex << ShiftForWord), foo->nilObj);
					/* begin pop:thenPush: */
					longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), newContext);
					foo->stackPointer = sp;
					/* begin internalizeIPandSP */
					localIP = pointerForOop(foo->instructionPointer);
					localSP = pointerForOop(foo->stackPointer);
					localHomeContext = foo->theHomeContext;
				}
				if (!(foo->successFlag)) {
					foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((24 * 2) << ShiftForWord));
					foo->argumentCount = 1;
					goto normalSend;
					goto l32;
				}
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
			}
;
		l32:	/* end case */;
			break;
		case 201:
			/* bytecodePrimValue */
			{
				sqInt maybeBlock;
				sqInt rcvrClass;
				sqInt ccIndex;
				maybeBlock = longAtPointer(localSP);
				foo->argumentCount = 0;
				foo->successFlag = 1;
				if ((maybeBlock & 1) == 0) {
					/* begin fetchClassOfNonInt: */
					ccIndex = (((usqInt) (longAt(maybeBlock))) >> 12) & 31;
					if (ccIndex == 0) {
						rcvrClass = (longAt(maybeBlock - BaseHeaderSize)) & AllButTypeMask;
						goto l35;
					} else {
						rcvrClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
						goto l35;
					}
				l35:	/* end fetchClassOfNonInt: */;
					if (rcvrClass == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassBlockClosure << ShiftForWord)))) {
						/* begin externalizeIPandSP */
						foo->instructionPointer = oopForPointer(localIP);
						foo->stackPointer = oopForPointer(localSP);
						foo->theHomeContext = localHomeContext;
						primitiveClosureValue();
						/* begin internalizeIPandSP */
						localIP = pointerForOop(foo->instructionPointer);
						localSP = pointerForOop(foo->stackPointer);
						localHomeContext = foo->theHomeContext;
					} else {
						if (rcvrClass == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassBlockContext << ShiftForWord)))) {
							/* begin externalizeIPandSP */
							foo->instructionPointer = oopForPointer(localIP);
							foo->stackPointer = oopForPointer(localSP);
							foo->theHomeContext = localHomeContext;
							primitiveValue();
							/* begin internalizeIPandSP */
							localIP = pointerForOop(foo->instructionPointer);
							localSP = pointerForOop(foo->stackPointer);
							localHomeContext = foo->theHomeContext;
						} else {
							foo->successFlag = 0;
						}
					}
				}
				if (!(foo->successFlag)) {
					foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((25 * 2) << ShiftForWord));
					goto normalSend;
					goto l34;
				}
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
			}
;
		l34:	/* end case */;
			break;
		case 202:
			/* bytecodePrimValueWithArg */
			{
				sqInt maybeBlock;
				sqInt rcvrClass;
				sqInt ccIndex;
				maybeBlock = longAtPointer(localSP - (1 * BytesPerWord));
				foo->argumentCount = 1;
				foo->successFlag = 1;
				if ((maybeBlock & 1) == 0) {
					/* begin fetchClassOfNonInt: */
					ccIndex = (((usqInt) (longAt(maybeBlock))) >> 12) & 31;
					if (ccIndex == 0) {
						rcvrClass = (longAt(maybeBlock - BaseHeaderSize)) & AllButTypeMask;
						goto l37;
					} else {
						rcvrClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
						goto l37;
					}
				l37:	/* end fetchClassOfNonInt: */;
					if (rcvrClass == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassBlockClosure << ShiftForWord)))) {
						/* begin externalizeIPandSP */
						foo->instructionPointer = oopForPointer(localIP);
						foo->stackPointer = oopForPointer(localSP);
						foo->theHomeContext = localHomeContext;
						primitiveClosureValue();
						/* begin internalizeIPandSP */
						localIP = pointerForOop(foo->instructionPointer);
						localSP = pointerForOop(foo->stackPointer);
						localHomeContext = foo->theHomeContext;
					} else {
						if (rcvrClass == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassBlockContext << ShiftForWord)))) {
							/* begin externalizeIPandSP */
							foo->instructionPointer = oopForPointer(localIP);
							foo->stackPointer = oopForPointer(localSP);
							foo->theHomeContext = localHomeContext;
							primitiveValue();
							/* begin internalizeIPandSP */
							localIP = pointerForOop(foo->instructionPointer);
							localSP = pointerForOop(foo->stackPointer);
							localHomeContext = foo->theHomeContext;
						} else {
							foo->successFlag = 0;
						}
					}
				}
				if (!(foo->successFlag)) {
					foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((26 * 2) << ShiftForWord));
					goto normalSend;
					goto l36;
				}
				/* begin fetchNextBytecode */
				currentBytecode = byteAtPointer(++localIP);
			}
;
		l36:	/* end case */;
			break;
		case 203:
			/* bytecodePrimDo */
			{
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((27 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
			break;
		case 204:
			/* bytecodePrimNew */
			{
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((28 * 2) << ShiftForWord));
				foo->argumentCount = 0;
				goto normalSend;
			}
;
			break;
		case 205:
			/* bytecodePrimNewWithArg */
			{
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((29 * 2) << ShiftForWord));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
			break;
		case 206:
			/* bytecodePrimPointX */
			{
				sqInt rcvr;
				sqInt ccIndex;
				sqInt cl;
				foo->successFlag = 1;
				rcvr = longAtPointer(localSP);
				/* begin assertClassOf:is: */
				if ((rcvr & 1)) {
					foo->successFlag = 0;
					goto l39;
				}
				ccIndex = (((usqInt) (longAt(rcvr))) >> 12) & 31;
				if (ccIndex == 0) {
					cl = (longAt(rcvr - BaseHeaderSize)) & AllButTypeMask;
				} else {
					cl = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
				}
				/* begin success: */
				foo->successFlag = (cl == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassPoint << ShiftForWord)))) && foo->successFlag;
			l39:	/* end assertClassOf:is: */;
				if (foo->successFlag) {
					/* begin internalPop:thenPush: */
					longAtPointerput(localSP -= (1 - 1) * BytesPerWord, longAt((rcvr + BaseHeaderSize) + (XIndex << ShiftForWord)));
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					goto l38;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((30 * 2) << ShiftForWord));
				foo->argumentCount = 0;
				goto normalSend;
			}
;
		l38:	/* end case */;
			break;
		case 207:
			/* bytecodePrimPointY */
			{
				sqInt rcvr;
				sqInt ccIndex;
				sqInt cl;
				foo->successFlag = 1;
				rcvr = longAtPointer(localSP);
				/* begin assertClassOf:is: */
				if ((rcvr & 1)) {
					foo->successFlag = 0;
					goto l41;
				}
				ccIndex = (((usqInt) (longAt(rcvr))) >> 12) & 31;
				if (ccIndex == 0) {
					cl = (longAt(rcvr - BaseHeaderSize)) & AllButTypeMask;
				} else {
					cl = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
				}
				/* begin success: */
				foo->successFlag = (cl == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassPoint << ShiftForWord)))) && foo->successFlag;
			l41:	/* end assertClassOf:is: */;
				if (foo->successFlag) {
					/* begin internalPop:thenPush: */
					longAtPointerput(localSP -= (1 - 1) * BytesPerWord, longAt((rcvr + BaseHeaderSize) + (YIndex << ShiftForWord)));
					/* begin fetchNextBytecode */
					currentBytecode = byteAtPointer(++localIP);
					goto l40;
				}
				foo->messageSelector = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SpecialSelectors << ShiftForWord))) + BaseHeaderSize) + ((31 * 2) << ShiftForWord));
				foo->argumentCount = 0;
				goto normalSend;
			}
;
		l40:	/* end case */;
			break;
		case 208:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((208 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 208) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 209:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((209 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 209) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 210:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((210 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 210) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 211:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((211 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 211) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 212:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((212 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 212) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 213:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((213 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 213) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 214:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((214 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 214) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 215:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((215 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 215) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 216:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((216 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 216) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 217:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((217 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 217) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 218:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((218 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 218) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 219:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((219 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 219) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 220:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((220 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 220) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 221:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((221 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 221) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 222:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((222 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 222) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 223:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((223 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 223) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 224:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((224 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 224) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 225:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((225 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 225) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 226:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((226 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 226) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 227:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((227 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 227) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 228:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((228 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 228) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 229:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((229 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 229) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 230:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((230 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 230) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 231:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((231 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 231) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 232:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((232 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 232) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 233:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((233 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 233) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 234:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((234 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 234) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 235:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((235 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 235) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 236:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((236 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 236) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 237:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((237 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 237) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 238:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((238 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 238) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 239:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((239 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 239) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 240:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((240 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 240) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 241:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((241 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 241) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 242:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((242 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 242) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 243:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((243 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 243) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 244:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((244 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 244) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 245:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((245 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 245) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 246:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((246 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 246) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 247:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((247 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 247) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 248:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((248 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 248) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 249:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((249 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 249) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 250:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((250 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 250) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 251:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((251 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 251) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 252:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((252 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 252) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 253:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((253 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 253) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 254:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((254 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 254) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 255:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt((foo->method + BaseHeaderSize) + (((255 & 15) + LiteralStart) << ShiftForWord));
				foo->argumentCount = ((((usqInt) 255) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		}
	}

	/* undo the pre-increment of IP before returning */

	localIP -= 1;
	/* begin externalizeIPandSP */
	foo->instructionPointer = oopForPointer(localIP);
	foo->stackPointer = oopForPointer(localSP);
	foo->theHomeContext = localHomeContext;
}


/*	the vm has to convert aFilenameString via any canonicalization and char-mapping and put the result in aCharBuffer.
Note the resolveAliases flag - this is an awful artefact of OSX and Apples demented alias handling. When opening a file, the flag must be  true, when closing or renaming it must be false. Sigh. */

sqInt ioFilenamefromStringofLengthresolveAliases(char * aCharBuffer, char * aFilenameString, sqInt filenameLength, sqInt aBoolean) {
	sqGetFilenameFromString(aCharBuffer, aFilenameString, filenameLength, aBoolean);
}


/*	Support for external primitives. */

sqInt isKindOf(sqInt oop, char * className) {
register struct foo * foo = &fum;
    sqInt oopClass;
    sqInt ccIndex;

	/* begin fetchClassOf: */
	if ((oop & 1)) {
		oopClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		oopClass = (longAt(oop - BaseHeaderSize)) & AllButTypeMask;
		goto l1;
	} else {
		oopClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	while (!(oopClass == foo->nilObj)) {
		if (classNameOfIs(oopClass, className)) {
			return 1;
		}
		oopClass = longAt((oopClass + BaseHeaderSize) + (SuperclassIndex << ShiftForWord));
	}
	return 0;
}


/*	Support for external primitives */

sqInt isMemberOf(sqInt oop, char * className) {
register struct foo * foo = &fum;
    sqInt oopClass;
    sqInt ccIndex;

	/* begin fetchClassOf: */
	if ((oop & 1)) {
		oopClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		oopClass = (longAt(oop - BaseHeaderSize)) & AllButTypeMask;
		goto l1;
	} else {
		oopClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	return classNameOfIs(oopClass, className);
}


/*	Answer true if this is an indexable object with pointer elements, e.g., an array */

sqInt isArray(sqInt oop) {
	return ((oop & 1) == 0) && (((((usqInt) (longAt(oop))) >> 8) & 15) == 2);
}


/*	Answer true (non-zero) if running on a big endian machine. */

sqInt isBigEnder(void) {
    static sqInt endianness = -1;
    sqInt len;
    sqInt anInt;
    char * cString;
    sqInt i;

	if (!(endianness == -1)) {
		return endianness;
	}
	len = sizeof(anInt);
	cString = (char *) &anInt;
	i = 0;
	while (i < len) {
		cString[i] = i;
		i += 1;
	}
	endianness = anInt & 255;
	return endianness;
}


/*	Answer true if the argument contains indexable bytes. See comment in formatOf: */
/*	Note: Includes CompiledMethods. */

sqInt isBytes(sqInt oop) {
	return ((oop & 1) == 0) && (((((usqInt) (longAt(oop))) >> 8) & 15) >= 8);
}


/*	Answer true if size is greater than (((2 raisedTo: 31) - 1) >> bits). Used
	to limit size of allocation requests to 31 bit integer maximum to prevent
	arithmetic overflow in subsequent calculations. Always answers false
	in interpreter simulation.

	Assumes that sizeof(int) is 4 for all platforms. */

sqInt isExcessiveAllocationRequestshift(sqInt size, sqInt bits) {
    sqInt shiftCount;
    int int32;

	int32 = size;
	shiftCount = 0;
	if (int32 < 0) {
		return 1;
	}
	while (shiftCount < bits) {
		int32 = int32 << 1;
		if (int32 < 0) {
			return 1;
		}
		shiftCount += 1;
	}
	return 0;
}

sqInt isFloatObject(sqInt oop) {
	return (fetchClassOf(oop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)));
}


/*	Is this a MethodContext whose meth has a primitive number of 199? */
/*	NB: the use of a primitive number for marking the method is pretty grungy, but it is simple to use for a test sytem, not too expensive and we don't actually have the two spare method header bits we need. We can probably obtain them when the method format is changed.
	NB 2: actually, the jitter will probably implement the prim to actually mark the volatile frame by changing the return function pointer. */

sqInt isHandlerMarked(sqInt aContext) {
    sqInt meth;
    sqInt pIndex;
    sqInt header;
    sqInt primBits;

	header = longAt(aContext);
	if (!(((((usqInt) header) >> 12) & 31) == 14)) {
		return 0;
	}
	meth = longAt((aContext + BaseHeaderSize) + (MethodIndex << ShiftForWord));
	/* begin primitiveIndexOf: */
	primBits = (((usqInt) (longAt((meth + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 1) & 268435967;
	pIndex = (primBits & 511) + (((usqInt) primBits) >> 19);
	return pIndex == 199;
}


/*	Return true if the given address is in ST object memory */

sqInt isInMemory(sqInt address) {
	return ((((usqInt) address)) >= (((usqInt) memory))) && ((((usqInt) address)) < (((usqInt) foo->endOfMemory)));
}

sqInt isIndexable(sqInt oop) {
	return ((((usqInt) (longAt(oop))) >> 8) & 15) >= 2;
}

sqInt isIntegerObject(sqInt objectPointer) {
	return (objectPointer & 1) > 0;
}


/*	Return true if the given value can be represented as a Smalltalk integer value. */
/*	Use a shift and XOR to set the sign bit if and only if the top two bits of the given
	value are the same, then test the sign bit. Note that the top two bits are equal for
	exactly those integers in the range that can be represented in 31-bits or 63-bits.

	Operands are coerced to machine integer size so the test will work with 64 bit
	images on 32 bit hosts. When running on a 32 bit host, the cast to int has little
	or no performance impact for either 32 bit or 64 bit images.

	On a 64 bit host, the shift and XOR test is replaced by an explicit range check,
	which provides the best performance for both 32 bit and 64 bit images.

	If the range of small integers is enlarged for 64 bit images, this method must
	be updated accordingly. */

sqInt isIntegerValue(sqInt intValue) {
	return 
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
		(((((int) intValue)) ^ ((((int) intValue)) << 1)) >= 0)
# else
		((intValue >= -1073741824) && (intValue <= 1073741823))
# endif  // SQ_HOST32
	;
}


/*	Answer true if the argument has only fields that can hold oops. See comment in formatOf: */

sqInt isPointers(sqInt oop) {
	return ((oop & 1) == 0) && (((((usqInt) (longAt(oop))) >> 8) & 15) <= 4);
}


/*	Answer true if the argument has only weak fields that can hold oops. See comment in formatOf: */

sqInt isWeak(sqInt oop) {
	return ((oop & 1) == 0) && (((((usqInt) (longAt(oop))) >> 8) & 15) == 4);
}


/*	Answer true if the argument contains only indexable words (no oops). See comment in formatOf: */

sqInt isWords(sqInt oop) {
	return ((oop & 1) == 0) && (((((usqInt) (longAt(oop))) >> 8) & 15) == 6);
}


/*	Answer true if the contains only indexable words or bytes (no oops). See comment in formatOf: */
/*	Note: Excludes CompiledMethods. */

sqInt isWordsOrBytes(sqInt oop) {
	return ((oop & 1) == 0) && (isWordsOrBytesNonInt(oop));
}


/*	Answer true if the contains only indexable words or bytes (no oops). See comment in formatOf: */
/*	Note: Excludes CompiledMethods. */

sqInt isWordsOrBytesNonInt(sqInt oop) {
    sqInt fmt;

	fmt = (((usqInt) (longAt(oop))) >> 8) & 15;
	return (fmt == 6) || ((fmt >= 8) && (fmt <= 11));
}


/*	Return the byte offset of the last pointer field of the given object.  
	Works with CompiledMethods, as well as ordinary objects. 
	Can be used even when the type bits are not correct. */

sqInt lastPointerOf(sqInt oop) {
    sqInt fmt;
    sqInt sz;
    sqInt methodHeader;
    sqInt contextSize;
    sqInt header;
    sqInt sp;
    sqInt type;
    sqInt header1;

	header = longAt(oop);
	fmt = (((usqInt) header) >> 8) & 15;
	if (fmt <= 4) {
		if ((fmt == 3) && ((((((usqInt) header) >> 12) & 31) == 13) || ((((((usqInt) header) >> 12) & 31) == 14) || (((((usqInt) header) >> 12) & 31) == 4)))) {
			/* begin fetchStackPointerOf: */
			sp = longAt((oop + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
			if (!((sp & 1))) {
				contextSize = 0;
				goto l1;
			}
			contextSize = (sp >> 1);
		l1:	/* end fetchStackPointerOf: */;
			return (CtxtTempFrameStart + contextSize) * BytesPerWord;
		}
		/* begin sizeBitsOfSafe: */
		header1 = longAt(oop);
		/* begin rightType: */
		if ((header1 & SizeMask) == 0) {
			type = HeaderTypeSizeAndClass;
			goto l2;
		} else {
			if ((header1 & CompactClassMask) == 0) {
				type = HeaderTypeClass;
				goto l2;
			} else {
				type = HeaderTypeShort;
				goto l2;
			}
		}
	l2:	/* end rightType: */;
		if (type == HeaderTypeSizeAndClass) {
			sz = (longAt(oop - (BytesPerWord * 2))) & AllButTypeMask;
			goto l3;
		} else {
			sz = header1 & SizeMask;
			goto l3;
		}
	l3:	/* end sizeBitsOfSafe: */;
		return sz - BaseHeaderSize;
	}
	if (fmt < 12) {
		return 0;
	}
	methodHeader = longAt(oop + BaseHeaderSize);
	return (((((usqInt) methodHeader) >> 10) & 255) * BytesPerWord) + BaseHeaderSize;
}


/*	Return the number of indexable bytes or words in the given object. Assume the argument is not an integer. For a CompiledMethod, the size of the method header (in bytes) should be subtracted from the result. */

sqInt lengthOf(sqInt oop) {
    sqInt header;
    sqInt sz;

	header = longAt(oop);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz = header & SizeMask;
	}
	sz -= header & Size4Bit;
	if (((((usqInt) header) >> 8) & 15) <= 4) {
		return ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
	}
	if (((((usqInt) header) >> 8) & 15) < 8) {
		return ((usqInt) (sz - BaseHeaderSize)) >> 2;
	} else {
		return (sz - BaseHeaderSize) - (((((usqInt) header) >> 8) & 15) & 3);
	}
	return null;
}

sqInt literalofMethod(sqInt offset, sqInt methodPointer) {
	return longAt((methodPointer + BaseHeaderSize) + ((offset + LiteralStart) << ShiftForWord));
}

sqInt literalCountOf(sqInt methodPointer) {
	return (((usqInt) (longAt((methodPointer + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 10) & 255;
}


/*	This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin:=loadBitBltFrom
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided */

sqInt loadBitBltFrom(sqInt bb) {
    void * fn;

	fn = ioLoadFunctionFrom("loadBitBltFrom", "BitBltPlugin");
	if (fn == 0) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	return ((sqInt (*)(sqInt))fn)(bb);
}

sqInt loadInitialContext(void) {
register struct foo * foo = &fum;
    sqInt sched;
    sqInt proc;
    sqInt activeCntx;
    sqInt tmp;

	sched = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord));
	proc = longAt((sched + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
	foo->activeContext = longAt((proc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord));
	if ((((usqInt) foo->activeContext)) < (((usqInt) foo->youngStart))) {
		beRootIfOld(foo->activeContext);
	}
	/* begin fetchContextRegisters: */
	activeCntx = foo->activeContext;
	tmp = longAt((activeCntx + BaseHeaderSize) + (MethodIndex << ShiftForWord));
	if ((tmp & 1)) {
		tmp = longAt((activeCntx + BaseHeaderSize) + (HomeIndex << ShiftForWord));
		if ((((usqInt) tmp)) < (((usqInt) foo->youngStart))) {
			beRootIfOld(tmp);
		}
	} else {
		tmp = activeCntx;
	}
	foo->theHomeContext = tmp;
	foo->receiver = longAt((tmp + BaseHeaderSize) + (ReceiverIndex << ShiftForWord));
	foo->method = longAt((tmp + BaseHeaderSize) + (MethodIndex << ShiftForWord));
	tmp = ((longAt((activeCntx + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord))) >> 1);
	foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
	tmp = ((longAt((activeCntx + BaseHeaderSize) + (StackPointerIndex << ShiftForWord))) >> 1);
	foo->stackPointer = (activeCntx + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * BytesPerWord);
	foo->reclaimableContextCount = 0;
}

sqInt lookupMethodInClass(sqInt class) {
register struct foo * foo = &fum;
    sqInt dictionary;
    sqInt currentClass;
    sqInt found;
    sqInt rclass;
    sqInt oop;
    sqInt oop1;
    sqInt methodArray;
    sqInt mask;
    sqInt wrapAround;
    sqInt length;
    sqInt nextSelector;
    sqInt index;
    sqInt sz;
    sqInt primBits;
    sqInt header;

	currentClass = class;
	while (currentClass != foo->nilObj) {
		dictionary = longAt((currentClass + BaseHeaderSize) + (MessageDictionaryIndex << ShiftForWord));
		if (dictionary == foo->nilObj) {
			/* begin pushRemappableOop: */
			foo->remapBuffer[foo->remapBufferCount += 1] = currentClass;
			createActualMessageTo(class);
			/* begin popRemappableOop */
			oop = foo->remapBuffer[foo->remapBufferCount];
			foo->remapBufferCount -= 1;
			currentClass = oop;
			foo->messageSelector = longAt((foo->specialObjectsOop + BaseHeaderSize) + (SelectorCannotInterpret << ShiftForWord));
			return lookupMethodInClass(longAt((currentClass + BaseHeaderSize) + (SuperclassIndex << ShiftForWord)));
		}
		/* begin lookupMethodInDictionary: */
		/* begin fetchWordLengthOf: */
		/* begin sizeBitsOf: */
		header = longAt(dictionary);
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(dictionary - (BytesPerWord * 2))) & LongSizeMask;
			goto l1;
		} else {
			sz = header & SizeMask;
			goto l1;
		}
	l1:	/* end sizeBitsOf: */;
		length = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
		mask = (length - SelectorStart) - 1;
		if ((foo->messageSelector & 1)) {
			index = (mask & ((foo->messageSelector >> 1))) + SelectorStart;
		} else {
			index = (mask & ((((usqInt) (longAt(foo->messageSelector))) >> 17) & 4095)) + SelectorStart;
		}
		wrapAround = 0;
		while (1) {
			nextSelector = longAt((dictionary + BaseHeaderSize) + (index << ShiftForWord));
			if (nextSelector == foo->nilObj) {
				found = 0;
				goto l2;
			}
			if (nextSelector == foo->messageSelector) {
				methodArray = longAt((dictionary + BaseHeaderSize) + (MethodArrayIndex << ShiftForWord));
				foo->newMethod = longAt((methodArray + BaseHeaderSize) + ((index - SelectorStart) << ShiftForWord));
				if (((((usqInt) (longAt(foo->newMethod))) >> 8) & 15) >= 12) {
					/* begin primitiveIndexOf: */
					primBits = (((usqInt) (longAt((foo->newMethod + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 1) & 268435967;
					foo->primitiveIndex = (primBits & 511) + (((usqInt) primBits) >> 19);
					if (foo->primitiveIndex > MaxPrimitiveIndex) {
						foo->primitiveIndex = 0;
					}
				} else {
					foo->primitiveIndex = 248;
				}
				found = 1;
				goto l2;
			}
			index += 1;
			if (index == length) {
				if (wrapAround) {
					found = 0;
					goto l2;
				}
				wrapAround = 1;
				index = SelectorStart;
			}
		}
	l2:	/* end lookupMethodInDictionary: */;
		if (found) {
			return foo->methodClass = currentClass;
		}
		currentClass = longAt((currentClass + BaseHeaderSize) + (SuperclassIndex << ShiftForWord));
	}
	if (foo->messageSelector == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (SelectorDoesNotUnderstand << ShiftForWord)))) {
		error("Recursive not understood error encountered");
	}
	/* begin pushRemappableOop: */
	foo->remapBuffer[foo->remapBufferCount += 1] = class;
	createActualMessageTo(class);
	/* begin popRemappableOop */
	oop1 = foo->remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	rclass = oop1;
	foo->messageSelector = longAt((foo->specialObjectsOop + BaseHeaderSize) + (SelectorDoesNotUnderstand << ShiftForWord));
	return lookupMethodInClass(rclass);
}


/*	Return the first free block after the given chunk in memory. */

sqInt lowestFreeAfter(sqInt chunk) {
register struct foo * foo = &fum;
    sqInt oopHeader;
    sqInt oop;
    sqInt oopHeaderType;
    sqInt oopSize;

	oop = chunk + (foo->headerTypeBytes[(longAt(chunk)) & TypeMask]);
	while ((((usqInt) oop)) < (((usqInt) foo->endOfMemory))) {
		oopHeader = longAt(oop);
		oopHeaderType = oopHeader & TypeMask;
		if (oopHeaderType == HeaderTypeFree) {
			return oop;
		} else {
			if (oopHeaderType == HeaderTypeSizeAndClass) {
				oopSize = (longAt(oop - (BytesPerWord * 2))) & AllButTypeMask;
			} else {
				oopSize = oopHeader & SizeMask;
			}
		}
		oop = (oop + oopSize) + (foo->headerTypeBytes[(longAt(oop + oopSize)) & TypeMask]);
	}
	error("expected to find at least one free object");
}


/*	make a Point xValue@yValue.
We know both will be integers so no value nor root checking is needed */

sqInt makePointwithxValueyValue(sqInt xValue, sqInt yValue) {
    sqInt pointResult;

	pointResult = instantiateSmallClasssizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassPoint << ShiftForWord)), 3 * BytesPerWord);
	longAtput((pointResult + BaseHeaderSize) + (XIndex << ShiftForWord), ((xValue << 1) | 1));
	longAtput((pointResult + BaseHeaderSize) + (YIndex << ShiftForWord), ((yValue << 1) | 1));
	return pointResult;
}


/*	Use the forwarding table to update the pointers of all non-free objects in the given range of memory. Also remap pointers in root objects which may contains pointers into the given memory range, and don't forget to flush the method cache based on the range */

sqInt mapPointersInObjectsFromto(sqInt memStart, sqInt memEnd) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt i;
    sqInt oop1;
    sqInt i1;
    sqInt probe;
    sqInt i2;

	/* begin compilerMapHookFrom:to: */
	if (foo->compilerInitialized) {
		compilerMapFromto(memStart, memEnd);
	}
	/* begin mapInterpreterOops */
	foo->nilObj = remap(foo->nilObj);
	foo->falseObj = remap(foo->falseObj);
	foo->trueObj = remap(foo->trueObj);
	foo->specialObjectsOop = remap(foo->specialObjectsOop);
	if (!(foo->compilerInitialized)) {
		foo->stackPointer -= foo->activeContext;
		foo->activeContext = remap(foo->activeContext);
		foo->stackPointer += foo->activeContext;
		foo->theHomeContext = remap(foo->theHomeContext);
	}
	foo->instructionPointer -= foo->method;
	foo->method = remap(foo->method);
	foo->instructionPointer += foo->method;
	foo->receiver = remap(foo->receiver);
	foo->messageSelector = remap(foo->messageSelector);
	foo->newMethod = remap(foo->newMethod);
	foo->methodClass = remap(foo->methodClass);
	foo->lkupClass = remap(foo->lkupClass);
	foo->receiverClass = remap(foo->receiverClass);
	for (i1 = 1; i1 <= foo->remapBufferCount; i1 += 1) {
		oop1 = foo->remapBuffer[i1];
		if (!((oop1 & 1))) {
			foo->remapBuffer[i1] = (remap(oop1));
		}
	}
	for (i1 = 1; i1 <= foo->jmpDepth; i1 += 1) {
		oop1 = foo->suspendedCallbacks[i1];
		if (!((oop1 & 1))) {
			foo->suspendedCallbacks[i1] = (remap(oop1));
		}
		oop1 = foo->suspendedMethods[i1];
		if (!((oop1 & 1))) {
			foo->suspendedMethods[i1] = (remap(oop1));
		}
	}
	for (i = 1; i <= foo->extraRootCount; i += 1) {
		oop = (foo->extraRoots[i])[0];
		if (!((oop & 1))) {
			(foo->extraRoots[i])[0] = (remap(oop));
		}
	}
	/* begin flushMethodCacheFrom:to: */
	probe = 0;
	for (i2 = 1; i2 <= MethodCacheEntries; i2 += 1) {
		if (!((foo->methodCache[probe + MethodCacheSelector]) == 0)) {
			if ((((((((usqInt) (foo->methodCache[probe + MethodCacheSelector]))) >= (((usqInt) memStart))) && ((((usqInt) (foo->methodCache[probe + MethodCacheSelector]))) < (((usqInt) memEnd)))) || (((((usqInt) (foo->methodCache[probe + MethodCacheClass]))) >= (((usqInt) memStart))) && ((((usqInt) (foo->methodCache[probe + MethodCacheClass]))) < (((usqInt) memEnd))))) || (((((usqInt) (foo->methodCache[probe + MethodCacheMethod]))) >= (((usqInt) memStart))) && ((((usqInt) (foo->methodCache[probe + MethodCacheMethod]))) < (((usqInt) memEnd))))) || (((((usqInt) (foo->methodCache[probe + MethodCacheNative]))) >= (((usqInt) memStart))) && ((((usqInt) (foo->methodCache[probe + MethodCacheNative]))) < (((usqInt) memEnd))))) {
				foo->methodCache[probe + MethodCacheSelector] = 0;
			}
		}
		probe += MethodCacheEntrySize;
	}
	for (i2 = 1; i2 <= AtCacheTotalSize; i2 += 1) {
		foo->atCache[i2] = 0;
	}
	updatePointersInRootObjectsFromto(memStart, memEnd);
	updatePointersInRangeFromto(memStart, memEnd);
}


/*	Mark all objects reachable from the given one.
	Trace from the given object even if it is old.
	Do not trace if it is already marked.
	Mark it only if it is a young object. */
/*	Tracer state variables:
		child		object being examined
		field		next field of child to examine
		parentField	field where child was stored in its referencing object */

sqInt markAndTrace(sqInt oop) {
register struct foo * foo = &fum;
    sqInt action;
    sqInt lastFieldOffset;
    sqInt statMarkCountLocal;
    sqInt header;
    sqInt typeBits;
    sqInt childType;
    sqInt type;
    sqInt header1;
    sqInt oop1;
    sqInt lastFieldOffset1;
    sqInt header2;
    sqInt fmt;
    sqInt sz;
    sqInt methodHeader;
    sqInt contextSize;
    sqInt header3;
    sqInt sp;
    sqInt type1;
    sqInt header11;
    sqInt fmt1;
    sqInt sz1;
    sqInt methodHeader1;
    sqInt contextSize1;
    sqInt header4;
    sqInt sp1;
    sqInt type2;
    sqInt header12;
    sqInt child;
    sqInt parentField;
    sqInt field;
    usqInt youngStartLocal;

	header = longAt(oop);
	if (!((header & MarkBit) == 0)) {
		return 0;
	}
	header = (header & AllButTypeMask) | HeaderTypeGC;
	if ((((usqInt) oop)) >= (((usqInt) foo->youngStart))) {
		header = header | MarkBit;
	}
	longAtput(oop, header);
	parentField = GCTopMarker;
	child = oop;
	if (((((usqInt) (longAt(oop))) >> 8) & 15) == 4) {

		/* And remember as weak root */

		lastFieldOffset = (nonWeakFieldsOf(oop)) << ShiftForWord;
		foo->weakRootCount += 1;
		foo->weakRoots[foo->weakRootCount] = oop;
	} else {
		/* begin lastPointerOf: */
		header3 = longAt(oop);
		fmt = (((usqInt) header3) >> 8) & 15;
		if (fmt <= 4) {
			if ((fmt == 3) && ((((((usqInt) header3) >> 12) & 31) == 13) || ((((((usqInt) header3) >> 12) & 31) == 14) || (((((usqInt) header3) >> 12) & 31) == 4)))) {
				/* begin fetchStackPointerOf: */
				sp = longAt((oop + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
				if (!((sp & 1))) {
					contextSize = 0;
					goto l7;
				}
				contextSize = (sp >> 1);
			l7:	/* end fetchStackPointerOf: */;
				lastFieldOffset = (CtxtTempFrameStart + contextSize) * BytesPerWord;
				goto l10;
			}
			/* begin sizeBitsOfSafe: */
			header11 = longAt(oop);
			/* begin rightType: */
			if ((header11 & SizeMask) == 0) {
				type1 = HeaderTypeSizeAndClass;
				goto l8;
			} else {
				if ((header11 & CompactClassMask) == 0) {
					type1 = HeaderTypeClass;
					goto l8;
				} else {
					type1 = HeaderTypeShort;
					goto l8;
				}
			}
		l8:	/* end rightType: */;
			if (type1 == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - (BytesPerWord * 2))) & AllButTypeMask;
				goto l9;
			} else {
				sz = header11 & SizeMask;
				goto l9;
			}
		l9:	/* end sizeBitsOfSafe: */;
			lastFieldOffset = sz - BaseHeaderSize;
			goto l10;
		}
		if (fmt < 12) {
			lastFieldOffset = 0;
			goto l10;
		}
		methodHeader = longAt(oop + BaseHeaderSize);
		lastFieldOffset = (((((usqInt) methodHeader) >> 10) & 255) * BytesPerWord) + BaseHeaderSize;
	l10:	/* end lastPointerOf: */;
	}
	field = oop + lastFieldOffset;
	action = StartField;
	youngStartLocal = foo->youngStart;

	/* run the tracer state machine until all objects reachable from oop are marked */

	statMarkCountLocal = foo->statMarkCount;
	while (!(action == Done)) {
		statMarkCountLocal += 1;
		if (action == StartField) {
			/* begin startField */
			child = longAt(field);
			typeBits = child & TypeMask;
			if ((typeBits & 1) == 1) {
				field -= BytesPerWord;
				action = StartField;
				goto l2;
			}
			if (typeBits == 0) {
				longAtput(field, parentField);
				parentField = field;
				action = StartObj;
				goto l2;
			}
			if (typeBits == 2) {
				if ((child & CompactClassMask) != 0) {
					child = child & AllButTypeMask;
					/* begin rightType: */
					if ((child & SizeMask) == 0) {
						childType = HeaderTypeSizeAndClass;
						goto l1;
					} else {
						if ((child & CompactClassMask) == 0) {
							childType = HeaderTypeClass;
							goto l1;
						} else {
							childType = HeaderTypeShort;
							goto l1;
						}
					}
				l1:	/* end rightType: */;
					longAtput(field, child | childType);
					action = Upward;
					goto l2;
				} else {
					child = longAt(field - BytesPerWord);
					child = child & AllButTypeMask;
					longAtput(field - BytesPerWord, parentField);
					parentField = (field - BytesPerWord) | 1;
					action = StartObj;
					goto l2;
				}
			}
		l2:	/* end startField */;
		}
		if (action == StartObj) {
			/* begin startObj */
			oop1 = child;
			if ((((usqInt) oop1)) < (((usqInt) youngStartLocal))) {
				field = oop1;
				action = Upward;
				goto l6;
			}
			header2 = longAt(oop1);
			if ((header2 & MarkBit) == 0) {
				if (((((usqInt) (longAt(oop1))) >> 8) & 15) == 4) {
					lastFieldOffset1 = (nonWeakFieldsOf(oop1)) << ShiftForWord;
				} else {
					/* begin lastPointerOf: */
					header4 = longAt(oop1);
					fmt1 = (((usqInt) header4) >> 8) & 15;
					if (fmt1 <= 4) {
						if ((fmt1 == 3) && ((((((usqInt) header4) >> 12) & 31) == 13) || ((((((usqInt) header4) >> 12) & 31) == 14) || (((((usqInt) header4) >> 12) & 31) == 4)))) {
							/* begin fetchStackPointerOf: */
							sp1 = longAt((oop1 + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
							if (!((sp1 & 1))) {
								contextSize1 = 0;
								goto l11;
							}
							contextSize1 = (sp1 >> 1);
						l11:	/* end fetchStackPointerOf: */;
							lastFieldOffset1 = (CtxtTempFrameStart + contextSize1) * BytesPerWord;
							goto l14;
						}
						/* begin sizeBitsOfSafe: */
						header12 = longAt(oop1);
						/* begin rightType: */
						if ((header12 & SizeMask) == 0) {
							type2 = HeaderTypeSizeAndClass;
							goto l12;
						} else {
							if ((header12 & CompactClassMask) == 0) {
								type2 = HeaderTypeClass;
								goto l12;
							} else {
								type2 = HeaderTypeShort;
								goto l12;
							}
						}
					l12:	/* end rightType: */;
						if (type2 == HeaderTypeSizeAndClass) {
							sz1 = (longAt(oop1 - (BytesPerWord * 2))) & AllButTypeMask;
							goto l13;
						} else {
							sz1 = header12 & SizeMask;
							goto l13;
						}
					l13:	/* end sizeBitsOfSafe: */;
						lastFieldOffset1 = sz1 - BaseHeaderSize;
						goto l14;
					}
					if (fmt1 < 12) {
						lastFieldOffset1 = 0;
						goto l14;
					}
					methodHeader1 = longAt(oop1 + BaseHeaderSize);
					lastFieldOffset1 = (((((usqInt) methodHeader1) >> 10) & 255) * BytesPerWord) + BaseHeaderSize;
				l14:	/* end lastPointerOf: */;
				}
				header2 = header2 & AllButTypeMask;
				header2 = (header2 | MarkBit) | HeaderTypeGC;
				longAtput(oop1, header2);
				field = oop1 + lastFieldOffset1;
				action = StartField;
				goto l6;
			} else {
				field = oop1;
				action = Upward;
				goto l6;
			}
		l6:	/* end startObj */;
		}
		if (action == Upward) {
			/* begin upward */
			if ((parentField & 1) == 1) {
				if (parentField == GCTopMarker) {
					header1 = (longAt(field)) & AllButTypeMask;
					/* begin rightType: */
					if ((header1 & SizeMask) == 0) {
						type = HeaderTypeSizeAndClass;
						goto l3;
					} else {
						if ((header1 & CompactClassMask) == 0) {
							type = HeaderTypeClass;
							goto l3;
						} else {
							type = HeaderTypeShort;
							goto l3;
						}
					}
				l3:	/* end rightType: */;
					longAtput(field, header1 | type);
					action = Done;
					goto l5;
				} else {
					child = field;
					field = parentField - 1;
					parentField = longAt(field);
					header1 = longAt(field + BytesPerWord);
					/* begin rightType: */
					if ((header1 & SizeMask) == 0) {
						type = HeaderTypeSizeAndClass;
						goto l4;
					} else {
						if ((header1 & CompactClassMask) == 0) {
							type = HeaderTypeClass;
							goto l4;
						} else {
							type = HeaderTypeShort;
							goto l4;
						}
					}
				l4:	/* end rightType: */;
					longAtput(field, child | type);
					field += BytesPerWord;
					header1 = header1 & AllButTypeMask;
					longAtput(field, header1 | type);
					action = Upward;
					goto l5;
				}
			} else {
				child = field;
				field = parentField;
				parentField = longAt(field);
				longAtput(field, child);
				field -= BytesPerWord;
				action = StartField;
				goto l5;
			}
		l5:	/* end upward */;
		}
	}
	foo->statMarkCount = statMarkCountLocal;
}


/*	Mark and trace all oops in the interpreter's state. */
/*	Assume: All traced variables contain valid oops. */

sqInt markAndTraceInterpreterOops(void) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt i;

	/* begin compilerMarkHook */
	if (foo->compilerInitialized) {
		compilerMark();
	}
	markAndTrace(foo->specialObjectsOop);
	if (foo->compilerInitialized) {
		markAndTrace(foo->receiver);
		markAndTrace(foo->method);
	} else {
		markAndTrace(foo->activeContext);
	}
	markAndTrace(foo->messageSelector);
	markAndTrace(foo->newMethod);
	markAndTrace(foo->methodClass);
	markAndTrace(foo->lkupClass);
	markAndTrace(foo->receiverClass);
	for (i = 1; i <= foo->remapBufferCount; i += 1) {
		oop = foo->remapBuffer[i];
		if (!((oop & 1))) {
			markAndTrace(oop);
		}
	}
	for (i = 1; i <= foo->jmpDepth; i += 1) {
		oop = foo->suspendedCallbacks[i];
		if (!((oop & 1))) {
			markAndTrace(oop);
		}
		oop = foo->suspendedMethods[i];
		if (!((oop & 1))) {
			markAndTrace(oop);
		}
	}
}


/*	Mark phase of the mark and sweep garbage collector. Set 
	the mark bits of all reachable objects. Free chunks are 
	untouched by this process. */
/*	Assume: All non-free objects are initially unmarked. Root 
	objects were unmarked when they were made roots. (Make 
	sure this stays true!!). */

sqInt markPhase(void) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt i;

	foo->freeContexts = NilContext;

	/* trace the interpreter's objects, including the active stack 
	and special objects array */

	foo->freeLargeContexts = NilContext;
	markAndTraceInterpreterOops();

	/* trace the roots */

	foo->statSpecialMarkCount = foo->statMarkCount;
	for (i = 1; i <= foo->rootTableCount; i += 1) {
		oop = foo->rootTable[i];
		markAndTrace(oop);
	}
	for (i = 1; i <= foo->extraRootCount; i += 1) {
		oop = (foo->extraRoots[i])[0];
		if (!((oop & 1))) {
			markAndTrace(oop);
		}
	}
}

sqInt methodArgumentCount(void) {
	return foo->argumentCount;
}

sqInt methodPrimitiveIndex(void) {
	return foo->primitiveIndex;
}


/*	The module with the given name was just unloaded. 
	Make sure we have no dangling references. */

EXPORT(sqInt) moduleUnloaded(char * aModuleName) {
	if ((strcmp(aModuleName, "SurfacePlugin")) == 0) {
		showSurfaceFn = 0;
	}
}


/*	For access from BitBlt module */

sqInt nilObject(void) {
	return foo->nilObj;
}


/*	Return the number of non-weak fields in oop (i.e. the number of fixed fields).
	Note: The following is copied from fixedFieldsOf:format:length: since we do know
	the format of the oop (e.g. format = 4) and thus don't need the length. */

sqInt nonWeakFieldsOf(sqInt oop) {
register struct foo * foo = &fum;
    sqInt class;
    sqInt classFormat;
    sqInt ccIndex;

	if (!(((((usqInt) (longAt(oop))) >> 8) & 15) == 4)) {
		error("Called fixedFieldsOfWeak: with a non-weak oop");
	}
	/* begin fetchClassOf: */
	if ((oop & 1)) {
		class = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(oop - BaseHeaderSize)) & AllButTypeMask;
		goto l1;
	} else {
		class = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	classFormat = (longAt((class + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1;
	return (((((usqInt) classFormat) >> 11) & 192) + ((((usqInt) classFormat) >> 2) & 63)) - 1;
}


/*	Record that the given oop in the old object area points to an 
	object in the young area. 
	HeaderLoc is usually = oop, but may be an addr in a 
	forwarding block. */

sqInt noteAsRootheaderLoc(sqInt oop, sqInt headerLoc) {
register struct foo * foo = &fum;
    sqInt header;

	header = longAt(headerLoc);
	if ((header & RootBit) == 0) {
		if (foo->rootTableCount < RootTableRedZone) {
			foo->rootTableCount += 1;
			foo->rootTable[foo->rootTableCount] = oop;
			longAtput(headerLoc, header | RootBit);
		} else {
			if (foo->rootTableCount < RootTableSize) {
				foo->rootTableCount += 1;
				foo->rootTable[foo->rootTableCount] = oop;
				longAtput(headerLoc, header | RootBit);
				foo->allocationCount = foo->allocationsBetweenGCs + 1;
			}
		}
	}
}


/*	This should never be called: either the compiler is uninitialised (in which case the hooks should never be reached) or the compiler initialisation should have replaced all the hook with their external implementations. */

sqInt nullCompilerHook(void) {
	error("uninitialised compiler hook called");
	return 0;
}


/*	Return the object or free chunk immediately following the 
	given object or free chunk in memory. Return endOfMemory 
	when enumeration is complete. */

sqInt objectAfter(sqInt oop) {
register struct foo * foo = &fum;
    sqInt sz;
    sqInt header;

	if (DoAssertionChecks) {
		if ((((usqInt) oop)) >= (((usqInt) foo->endOfMemory))) {
			error("no objects after the end of memory");
		}
	}
	if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
		sz = (longAt(oop)) & AllButTypeMask;
	} else {
		/* begin sizeBitsOf: */
		header = longAt(oop);
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
			goto l1;
		} else {
			sz = header & SizeMask;
			goto l1;
		}
	l1:	/* end sizeBitsOf: */;
	}
	return (oop + sz) + (foo->headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
}


/*	This message is deprecated but supported for a while via a tweak to sqVirtualMachine.[ch] Use fetchLong32, fetchLong64 or fetchPointer instead for new code */

sqInt obsoleteDontUseThisFetchWordofObject(sqInt fieldIndex, sqInt oop) {
	return long32At((oop + BaseHeaderSize) + (fieldIndex << 2));
}


/*	If this is a pointers object, check that its fields are all okay oops. */

sqInt okayFields(sqInt oop) {
register struct foo * foo = &fum;
    sqInt c;
    sqInt fieldOop;
    sqInt i;
    sqInt ccIndex;

	if ((oop == null) || (oop == 0)) {
		return 1;
	}
	if ((oop & 1)) {
		return 1;
	}
	okayOop(oop);
	oopHasOkayClass(oop);
	if (!(((oop & 1) == 0) && (((((usqInt) (longAt(oop))) >> 8) & 15) <= 4))) {
		return 1;
	}
	/* begin fetchClassOf: */
	if ((oop & 1)) {
		c = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		c = (longAt(oop - BaseHeaderSize)) & AllButTypeMask;
		goto l1;
	} else {
		c = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	if ((c == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassMethodContext << ShiftForWord)))) || (c == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassBlockContext << ShiftForWord))))) {
		i = (CtxtTempFrameStart + (fetchStackPointerOf(oop))) - 1;
	} else {
		i = (lengthOf(oop)) - 1;
	}
	while (i >= 0) {
		fieldOop = longAt((oop + BaseHeaderSize) + (i << ShiftForWord));
		if (!((fieldOop & 1))) {
			okayOop(fieldOop);
			oopHasOkayClass(fieldOop);
		}
		i -= 1;
	}
}


/*	Verify that the given oop is legitimate. Check address, header, and size but not class. */

sqInt okayOop(sqInt signedOop) {
register struct foo * foo = &fum;
    sqInt unusedBit;
    usqInt oop;
    sqInt fmt;
    sqInt sz;
    sqInt type;
    sqInt header;


	/* address and size checks */

	oop = ((usqInt) signedOop);
	if ((oop & 1)) {
		return 1;
	}
	if (!(oop < foo->endOfMemory)) {
		error("oop is not a valid address");
	}
	if (!((oop % BytesPerWord) == 0)) {
		error("oop is not a word-aligned address");
	}
	/* begin sizeBitsOf: */
	header = longAt(oop);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
		goto l1;
	} else {
		sz = header & SizeMask;
		goto l1;
	}
l1:	/* end sizeBitsOf: */;
	if (!((oop + sz) < foo->endOfMemory)) {
		error("oop size would make it extend beyond the end of memory");
	}
	type = (longAt(oop)) & TypeMask;
	if (type == HeaderTypeFree) {
		error("oop is a free chunk, not an object");
	}
	if (type == HeaderTypeShort) {
		if (((((usqInt) (longAt(oop))) >> 12) & 31) == 0) {
			error("cannot have zero compact class field in a short header");
		}
	}
	if (type == HeaderTypeClass) {
		if (!((oop >= BytesPerWord) && (((longAt(oop - BytesPerWord)) & TypeMask) == type))) {
			error("class header word has wrong type");
		}
	}
	if (type == HeaderTypeSizeAndClass) {
		if (!((oop >= (BytesPerWord * 2)) && ((((longAt(oop - (BytesPerWord * 2))) & TypeMask) == type) && (((longAt(oop - BytesPerWord)) & TypeMask) == type)))) {
			error("class header word has wrong type");
		}
	}
	fmt = (((usqInt) (longAt(oop))) >> 8) & 15;
	if ((fmt == 5) || (fmt == 7)) {
		error("oop has an unknown format type");
	}
	unusedBit = 536870912;
	if (BytesPerWord == 8) {
		unusedBit = unusedBit << 16;
		unusedBit = unusedBit << 16;
	}
	if (!(((longAt(oop)) & unusedBit) == 0)) {
		error("unused header bit 30 is set; should be zero");
	}
	if ((((longAt(oop)) & RootBit) == 1) && (oop >= foo->youngStart)) {
		error("root bit is set in a young object");
	}
	return 1;
}


/*	Similar to oopHasOkayClass:, except that it only returns true or false. */

sqInt oopHasAcceptableClass(sqInt signedOop) {
register struct foo * foo = &fum;
    usqInt oopClass;
    usqInt oop;
    sqInt behaviorFormatBits;
    sqInt oopFormatBits;
    sqInt formatMask;

	if ((signedOop & 1)) {
		return 1;
	}
	oop = ((usqInt) signedOop);
	if (!(oop < foo->endOfMemory)) {
		return 0;
	}
	if (!((oop % BytesPerWord) == 0)) {
		return 0;
	}
	if (!((oop + (sizeBitsOf(oop))) < foo->endOfMemory)) {
		return 0;
	}
	oopClass = ((usqInt) (fetchClassOf(oop)));
	if ((oopClass & 1)) {
		return 0;
	}
	if (!(oopClass < foo->endOfMemory)) {
		return 0;
	}
	if (!((oopClass % BytesPerWord) == 0)) {
		return 0;
	}
	if (!((oopClass + (sizeBitsOf(oopClass))) < foo->endOfMemory)) {
		return 0;
	}
	if (!((((oopClass & 1) == 0) && (((((usqInt) (longAt(oopClass))) >> 8) & 15) <= 4)) && ((lengthOf(oopClass)) >= 3))) {
		return 0;
	}
	if (((oop & 1) == 0) && (((((usqInt) (longAt(oop))) >> 8) & 15) >= 8)) {

		/* ignore extra bytes size bits */

		formatMask = 3072;
	} else {
		formatMask = 3840;
	}
	behaviorFormatBits = ((longAt((oopClass + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1) & formatMask;
	oopFormatBits = (longAt(oop)) & formatMask;
	if (!(behaviorFormatBits == oopFormatBits)) {
		return 0;
	}
	return 1;
}


/*	Attempt to verify that the given oop has a reasonable behavior. The class must be a valid, non-integer oop and must not be nilObj. It must be a pointers object with three or more fields. Finally, the instance specification field of the behavior must match that of the instance. */

sqInt oopHasOkayClass(sqInt signedOop) {
    usqInt oop;
    usqInt oopClass;
    sqInt behaviorFormatBits;
    sqInt oopFormatBits;
    sqInt formatMask;

	oop = ((usqInt) signedOop);
	okayOop(oop);
	oopClass = ((usqInt) (fetchClassOf(oop)));
	if ((oopClass & 1)) {
		error("a SmallInteger is not a valid class or behavior");
	}
	okayOop(oopClass);
	if (!((((oopClass & 1) == 0) && (((((usqInt) (longAt(oopClass))) >> 8) & 15) <= 4)) && ((lengthOf(oopClass)) >= 3))) {
		error("a class (behavior) must be a pointers object of size >= 3");
	}
	if (((oop & 1) == 0) && (((((usqInt) (longAt(oop))) >> 8) & 15) >= 8)) {

		/* ignore extra bytes size bits */

		formatMask = 3072;
	} else {
		formatMask = 3840;
	}
	behaviorFormatBits = ((longAt((oopClass + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1) & formatMask;
	oopFormatBits = (longAt(oop)) & formatMask;
	if (!(behaviorFormatBits == oopFormatBits)) {
		error("object and its class (behavior) formats differ");
	}
	return 1;
}


/*	Note: May be called by translated primitive code. */

sqInt pop(sqInt nItems) {
register struct foo * foo = &fum;
	foo->stackPointer -= nItems * BytesPerWord;
}

sqInt popthenPush(sqInt nItems, sqInt oop) {
register struct foo * foo = &fum;
    sqInt sp;

	longAtput(sp = foo->stackPointer - ((nItems - 1) * BytesPerWord), oop);
	foo->stackPointer = sp;
}


/*	Note: May be called by translated primitive code. */

double popFloat(void) {
register struct foo * foo = &fum;
    double  result;
    sqInt top;
    sqInt top1;
    sqInt ccIndex;
    sqInt cl;

	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	top = top1;
	/* begin assertClassOf:is: */
	if ((top & 1)) {
		foo->successFlag = 0;
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(top))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(top - BaseHeaderSize)) & AllButTypeMask;
	} else {
		cl = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) && foo->successFlag;
l1:	/* end assertClassOf:is: */;
	if (foo->successFlag) {
		;
		fetchFloatAtinto(top + BaseHeaderSize, result);
	}
	return result;
}


/*	Pop and return the possibly remapped object from the remap buffer. */

sqInt popRemappableOop(void) {
register struct foo * foo = &fum;
    sqInt oop;

	oop = foo->remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	return oop;
}

sqInt popStack(void) {
register struct foo * foo = &fum;
    sqInt top;

	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	return top;
}


/*	Note - integerValue is interpreted as POSITIVE, eg, as the result of
		Bitmap>at:, or integer>bitAnd:. */

sqInt positive32BitIntegerFor(sqInt integerValue) {
register struct foo * foo = &fum;
    sqInt newLargeInteger;

	if (integerValue >= 0) {
		if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
			(((((int) integerValue)) ^ ((((int) integerValue)) << 1)) >= 0)
# else
			((integerValue >= -1073741824) && (integerValue <= 1073741823))
# endif  // SQ_HOST32
		) {
			return ((integerValue << 1) | 1);
		}
	}
	if (BytesPerWord == 4) {
		newLargeInteger = instantiateSmallClasssizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargePositiveInteger << ShiftForWord)), BaseHeaderSize + 4);
	} else {
		newLargeInteger = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargePositiveInteger << ShiftForWord)), 4);
	}
	byteAtput((newLargeInteger + BaseHeaderSize) + 3, (((usqInt) integerValue) >> 24) & 255);
	byteAtput((newLargeInteger + BaseHeaderSize) + 2, (((usqInt) integerValue) >> 16) & 255);
	byteAtput((newLargeInteger + BaseHeaderSize) + 1, (((usqInt) integerValue) >> 8) & 255);
	byteAtput((newLargeInteger + BaseHeaderSize) + 0, integerValue & 255);
	return newLargeInteger;
}


/*	Convert the given object into an integer value.
	The object may be either a positive ST integer or a four-byte LargePositiveInteger. */

sqInt positive32BitValueOf(sqInt oop) {
register struct foo * foo = &fum;
    sqInt value;
    sqInt sz;
    sqInt header;
    sqInt sz1;
    sqInt ccIndex;
    sqInt cl;

	if ((oop & 1)) {
		value = (oop >> 1);
		if (value < 0) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
		return value;
	}
	/* begin assertClassOf:is: */
	if ((oop & 1)) {
		foo->successFlag = 0;
		goto l2;
	}
	ccIndex = (((usqInt) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(oop - BaseHeaderSize)) & AllButTypeMask;
	} else {
		cl = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargePositiveInteger << ShiftForWord)))) && foo->successFlag;
l2:	/* end assertClassOf:is: */;
	if (foo->successFlag) {
		/* begin lengthOf: */
		header = longAt(oop);
		/* begin lengthOf:baseHeader:format: */
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz1 = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
		} else {
			sz1 = header & SizeMask;
		}
		sz1 -= header & Size4Bit;
		if (((((usqInt) header) >> 8) & 15) <= 4) {
			sz = ((usqInt) (sz1 - BaseHeaderSize)) >> ShiftForWord;
			goto l1;
		}
		if (((((usqInt) header) >> 8) & 15) < 8) {
			sz = ((usqInt) (sz1 - BaseHeaderSize)) >> 2;
			goto l1;
		} else {
			sz = (sz1 - BaseHeaderSize) - (((((usqInt) header) >> 8) & 15) & 3);
			goto l1;
		}
		sz = null;
	l1:	/* end lengthOf: */;
		if (!(sz == 4)) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	if (foo->successFlag) {
		return (((byteAt((oop + BaseHeaderSize) + 0)) + ((byteAt((oop + BaseHeaderSize) + 1)) << 8)) + ((byteAt((oop + BaseHeaderSize) + 2)) << 16)) + ((byteAt((oop + BaseHeaderSize) + 3)) << 24);
	}
}


/*	Note - integerValue is interpreted as POSITIVE, eg, as the result of
		Bitmap>at:, or integer>bitAnd:. */

sqInt positive64BitIntegerFor(sqLong integerValue) {
    sqInt value;
    sqInt newLargeInteger;
    sqInt highWord;
    sqInt sz;
    sqInt i;

	if ((sizeof(integerValue)) == 4) {
		return positive32BitIntegerFor(integerValue);
	}

	/* shift is coerced to usqInt otherwise */

	highWord = integerValue >> 32;
	if (highWord == 0) {
		return positive32BitIntegerFor(integerValue);
	}
	sz = 5;
	if (!((highWord = ((usqInt) highWord) >> 8) == 0)) {
		sz += 1;
	}
	if (!((highWord = ((usqInt) highWord) >> 8) == 0)) {
		sz += 1;
	}
	if (!((highWord = ((usqInt) highWord) >> 8) == 0)) {
		sz += 1;
	}
	newLargeInteger = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargePositiveInteger << ShiftForWord)), sz);
	for (i = 0; i <= (sz - 1); i += 1) {
		value = (integerValue >> (i * 8)) & 255;
		byteAtput((newLargeInteger + BaseHeaderSize) + i, value);
	}
	return newLargeInteger;
}


/*	Convert the given object into an integer value.
	The object may be either a positive ST integer or a eight-byte LargePositiveInteger. */

sqLong positive64BitValueOf(sqInt oop) {
register struct foo * foo = &fum;
    sqLong value;
    sqInt szsqLong;
    sqInt sz;
    sqInt i;
    sqInt ccIndex;
    sqInt cl;
    sqInt header;
    sqInt sz1;

	if ((oop & 1)) {
		value = (oop >> 1);
		if (value < 0) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
		return value;
	}
	/* begin assertClassOf:is: */
	if ((oop & 1)) {
		foo->successFlag = 0;
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(oop - BaseHeaderSize)) & AllButTypeMask;
	} else {
		cl = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargePositiveInteger << ShiftForWord)))) && foo->successFlag;
l1:	/* end assertClassOf:is: */;
	if (!(foo->successFlag)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	szsqLong = sizeof(sqLong);
	/* begin lengthOf: */
	header = longAt(oop);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz1 = header & SizeMask;
	}
	sz1 -= header & Size4Bit;
	if (((((usqInt) header) >> 8) & 15) <= 4) {
		sz = ((usqInt) (sz1 - BaseHeaderSize)) >> ShiftForWord;
		goto l2;
	}
	if (((((usqInt) header) >> 8) & 15) < 8) {
		sz = ((usqInt) (sz1 - BaseHeaderSize)) >> 2;
		goto l2;
	} else {
		sz = (sz1 - BaseHeaderSize) - (((((usqInt) header) >> 8) & 15) & 3);
		goto l2;
	}
	sz = null;
l2:	/* end lengthOf: */;
	if (sz > szsqLong) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	value = 0;
	for (i = 0; i <= (sz - 1); i += 1) {
		value += (((sqLong) (byteAt((oop + BaseHeaderSize) + i)))) << (i * 8);
	}
	return value;
}


/*	oop is an old object. If valueObj is young, mark the object as a root. */

sqInt possibleRootStoreIntovalue(sqInt oop, sqInt valueObj) {
register struct foo * foo = &fum;
    sqInt header;

	if (((((usqInt) valueObj)) >= (((usqInt) foo->youngStart))) && (!((valueObj & 1)))) {
		/* begin noteAsRoot:headerLoc: */
		header = longAt(oop);
		if ((header & RootBit) == 0) {
			if (foo->rootTableCount < RootTableRedZone) {
				foo->rootTableCount += 1;
				foo->rootTable[foo->rootTableCount] = oop;
				longAtput(oop, header | RootBit);
			} else {
				if (foo->rootTableCount < RootTableSize) {
					foo->rootTableCount += 1;
					foo->rootTable[foo->rootTableCount] = oop;
					longAtput(oop, header | RootBit);
					foo->allocationCount = foo->allocationsBetweenGCs + 1;
				}
			}
		}
	}
}


/*	Mark the active and home contexts as roots if old. This 
	allows the interpreter to use storePointerUnchecked to 
	store into them. */

sqInt postGCAction(void) {
register struct foo * foo = &fum;
    sqInt delta;
    sqInt limit;

	if (foo->compilerInitialized) {
		compilerPostGC();
	} else {
		if ((((usqInt) foo->activeContext)) < (((usqInt) foo->youngStart))) {
			beRootIfOld(foo->activeContext);
		}
		if ((((usqInt) foo->theHomeContext)) < (((usqInt) foo->youngStart))) {
			beRootIfOld(foo->theHomeContext);
		}
	}
	if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) > (((usqInt) foo->shrinkThreshold))) {
		/* begin shrinkObjectMemory: */
		delta = ((longAt(foo->freeBlock)) & AllButTypeMask) - foo->growHeadroom;
		foo->statShrinkMemory += 1;
		limit = sqShrinkMemoryBy(foo->memoryLimit, delta);
		if (!(limit == foo->memoryLimit)) {
			foo->memoryLimit = limit - 24;
			initializeMemoryFirstFree(foo->freeBlock);
		}
	}
	/* begin signalSemaphoreWithIndex: */
	if (foo->gcSemaphoreIndex <= 0) {
		goto l1;
	}
	if (foo->semaphoresUseBufferA) {
		if (foo->semaphoresToSignalCountA < SemaphoresToSignalSize) {
			foo->semaphoresToSignalCountA += 1;
			foo->semaphoresToSignalA[foo->semaphoresToSignalCountA] = foo->gcSemaphoreIndex;
		}
	} else {
		if (foo->semaphoresToSignalCountB < SemaphoresToSignalSize) {
			foo->semaphoresToSignalCountB += 1;
			foo->semaphoresToSignalB[foo->semaphoresToSignalCountB] = foo->gcSemaphoreIndex;
		}
	}
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
	foo->nextPollTick = 0;
l1:	/* end signalSemaphoreWithIndex: */;
}


/*	Ensure that there are enough forwarding blocks to 
	accomodate this become, then prepare forwarding blocks for 
	the pointer swap. Return true if successful. */
/*	Details: Doing a GC might generate enough space for 
	forwarding blocks if we're short. However, this is an 
	uncommon enough case that it is better handled by primitive 
	fail code at the Smalltalk level. */
/*	Important note on multiple references to same object  - since the preparation of
	fwdBlocks is NOT idempotent we get VM crashes if the same object is referenced more
	than once in such a way as to require multiple fwdBlocks.
	oop1 forwardBecome: oop1 is ok since only a single fwdBlock is needed.
	oop1 become: oop1 would fail because the second fwdBlock woudl not have the actual object
	header but rather the mutated ref to the first fwdBlock.
	Further problems can arise with an array1 or array2 that refer multiply to the same 
	object. This would notbe expected input for programmer writen code but might arise from
	automatic usage such as in ImageSegment loading.
	To avoid the simple and rather common case of oop1 become*: oop1, we skip such pairs
	and simply avoid making fwdBlocks - it is redundant anyway */

sqInt prepareForwardingTableForBecomingwithtwoWay(sqInt array1, sqInt array2, sqInt twoWayFlag) {
register struct foo * foo = &fum;
    sqInt entriesNeeded;
    sqInt oop2;
    sqInt fwdBlock;
    sqInt entriesAvailable;
    sqInt fwdBlkSize;
    sqInt fieldOffset;
    sqInt oop1;
    sqInt originalHeader;
    sqInt originalHeaderType;
    sqInt originalHeader1;
    sqInt originalHeaderType1;
    sqInt fmt;
    sqInt sz;
    sqInt methodHeader;
    sqInt contextSize;
    sqInt header;
    sqInt sp;
    sqInt type;
    sqInt header1;


	/* need enough entries for all oops */
	/* Note: Forward blocks must be quadword aligned - see fwdTableInit:. */

	entriesNeeded = ((sqInt) (lastPointerOf(array1)) >> 2);
	if (twoWayFlag) {
		entriesNeeded = entriesNeeded * 2;
		fwdBlkSize = BytesPerWord * 2;
	} else {
		fwdBlkSize = BytesPerWord * 4;
	}
	entriesAvailable = fwdTableInit(fwdBlkSize);
	if (entriesAvailable < entriesNeeded) {
		initializeMemoryFirstFree(foo->freeBlock);
		return 0;
	}
	/* begin lastPointerOf: */
	header = longAt(array1);
	fmt = (((usqInt) header) >> 8) & 15;
	if (fmt <= 4) {
		if ((fmt == 3) && ((((((usqInt) header) >> 12) & 31) == 13) || ((((((usqInt) header) >> 12) & 31) == 14) || (((((usqInt) header) >> 12) & 31) == 4)))) {
			/* begin fetchStackPointerOf: */
			sp = longAt((array1 + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
			if (!((sp & 1))) {
				contextSize = 0;
				goto l4;
			}
			contextSize = (sp >> 1);
		l4:	/* end fetchStackPointerOf: */;
			fieldOffset = (CtxtTempFrameStart + contextSize) * BytesPerWord;
			goto l6;
		}
		/* begin sizeBitsOfSafe: */
		header1 = longAt(array1);
		/* begin rightType: */
		if ((header1 & SizeMask) == 0) {
			type = HeaderTypeSizeAndClass;
			goto l5;
		} else {
			if ((header1 & CompactClassMask) == 0) {
				type = HeaderTypeClass;
				goto l5;
			} else {
				type = HeaderTypeShort;
				goto l5;
			}
		}
	l5:	/* end rightType: */;
		if (type == HeaderTypeSizeAndClass) {
			sz = (longAt(array1 - (BytesPerWord * 2))) & AllButTypeMask;
			goto l3;
		} else {
			sz = header1 & SizeMask;
			goto l3;
		}
	l3:	/* end sizeBitsOfSafe: */;
		fieldOffset = sz - BaseHeaderSize;
		goto l6;
	}
	if (fmt < 12) {
		fieldOffset = 0;
		goto l6;
	}
	methodHeader = longAt(array1 + BaseHeaderSize);
	fieldOffset = (((((usqInt) methodHeader) >> 10) & 255) * BytesPerWord) + BaseHeaderSize;
l6:	/* end lastPointerOf: */;
	while (fieldOffset >= BaseHeaderSize) {
		oop1 = longAt(array1 + fieldOffset);

		/* if oop1 == oop2, no need to do any work for this pair.
			May still be other entries in the arrays though so keep looking */

		oop2 = longAt(array2 + fieldOffset);
		if (!(oop1 == oop2)) {
			/* begin fwdBlockGet: */
			foo->fwdTableNext += fwdBlkSize;
			if (foo->fwdTableNext <= foo->fwdTableLast) {
				fwdBlock = foo->fwdTableNext;
				goto l2;
			} else {
				fwdBlock = null;
				goto l2;
			}
		l2:	/* end fwdBlockGet: */;
			/* begin initForwardBlock:mapping:to:withBackPtr: */
			originalHeader1 = longAt(oop1);
			if (DoAssertionChecks) {
				if (fwdBlock == null) {
					error("ran out of forwarding blocks in become");
				}
				if ((originalHeader1 & MarkBit) != 0) {
					error("object already has a forwarding table entry");
				}
			}
			originalHeaderType1 = originalHeader1 & TypeMask;
			longAtput(fwdBlock, oop2);
			longAtput(fwdBlock + BytesPerWord, originalHeader1);
			if (!twoWayFlag) {
				longAtput(fwdBlock + (BytesPerWord * 2), oop1);
			}
			longAtput(oop1, (((usqInt) fwdBlock) >> 1) | (MarkBit | originalHeaderType1));
			if (twoWayFlag) {
				/* begin fwdBlockGet: */
				foo->fwdTableNext += fwdBlkSize;
				if (foo->fwdTableNext <= foo->fwdTableLast) {
					fwdBlock = foo->fwdTableNext;
					goto l1;
				} else {
					fwdBlock = null;
					goto l1;
				}
			l1:	/* end fwdBlockGet: */;
				/* begin initForwardBlock:mapping:to:withBackPtr: */
				originalHeader = longAt(oop2);
				if (DoAssertionChecks) {
					if (fwdBlock == null) {
						error("ran out of forwarding blocks in become");
					}
					if ((originalHeader & MarkBit) != 0) {
						error("object already has a forwarding table entry");
					}
				}
				originalHeaderType = originalHeader & TypeMask;
				longAtput(fwdBlock, oop1);
				longAtput(fwdBlock + BytesPerWord, originalHeader);
				if (!twoWayFlag) {
					longAtput(fwdBlock + (BytesPerWord * 2), oop2);
				}
				longAtput(oop2, (((usqInt) fwdBlock) >> 1) | (MarkBit | originalHeaderType));
			}
		}
		fieldOffset -= BytesPerWord;
	}
	return 1;
}

sqInt primitiveAdd(void) {
register struct foo * foo = &fum;
    sqInt integerResult;
    sqInt sp;

	/* begin pop2AndPushIntegerIfOK: */
	integerResult = (stackIntegerValue(1)) + (stackIntegerValue(0));
	if (foo->successFlag) {
		if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
			(((((int) integerResult)) ^ ((((int) integerResult)) << 1)) >= 0)
# else
			((integerResult >= -1073741824) && (integerResult <= 1073741823))
# endif  // SQ_HOST32
		) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), ((integerResult << 1) | 1));
			foo->stackPointer = sp;
		} else {
			foo->successFlag = 0;
		}
	}
}

sqInt primitiveArctan(void) {
register struct foo * foo = &fum;
    double  rcvr;

	rcvr = popFloat();
	if (foo->successFlag) {
		pushFloat(atan(rcvr));
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
	}
}


/*	We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors. */

sqInt primitiveArrayBecome(void) {
register struct foo * foo = &fum;
    sqInt rcvr;
    sqInt arg;
    sqInt successValue;

	arg = longAt(foo->stackPointer);
	rcvr = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin success: */
	successValue = becomewithtwoWaycopyHash(rcvr, arg, 1, 1);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 1 * BytesPerWord;
	}
}


/*	We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors. */

sqInt primitiveArrayBecomeOneWay(void) {
register struct foo * foo = &fum;
    sqInt rcvr;
    sqInt arg;
    sqInt successValue;

	arg = longAt(foo->stackPointer);
	rcvr = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin success: */
	successValue = becomewithtwoWaycopyHash(rcvr, arg, 0, 1);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 1 * BytesPerWord;
	}
}


/*	Similar to primitiveArrayBecomeOneWay but accepts a third argument whether to copy
	the receiver's identity hash over the argument's identity hash. */

sqInt primitiveArrayBecomeOneWayCopyHash(void) {
register struct foo * foo = &fum;
    sqInt copyHashFlag;
    sqInt rcvr;
    sqInt arg;
    sqInt successValue;

	/* begin booleanValueOf: */
	if ((longAt(foo->stackPointer)) == foo->trueObj) {
		copyHashFlag = 1;
		goto l1;
	}
	if ((longAt(foo->stackPointer)) == foo->falseObj) {
		copyHashFlag = 0;
		goto l1;
	}
	foo->successFlag = 0;
	copyHashFlag = null;
l1:	/* end booleanValueOf: */;
	arg = longAt(foo->stackPointer - (1 * BytesPerWord));
	rcvr = longAt(foo->stackPointer - (2 * BytesPerWord));
	/* begin success: */
	successValue = becomewithtwoWaycopyHash(rcvr, arg, 0, copyHashFlag);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
	}
}

sqInt primitiveAsFloat(void) {
register struct foo * foo = &fum;
    sqInt arg;
    sqInt integerPointer;
    sqInt top;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer = top;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		arg = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		arg = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	if (foo->successFlag) {
		pushFloat(((double) arg));
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
	}
}

sqInt primitiveAsOop(void) {
register struct foo * foo = &fum;
    sqInt thisReceiver;
    sqInt sp;

	thisReceiver = longAt(foo->stackPointer);
	/* begin success: */
	foo->successFlag = (!((thisReceiver & 1))) && foo->successFlag;
	if (foo->successFlag) {
		/* begin pop:thenPushInteger: */
		longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), ((((((usqInt) (longAt(thisReceiver))) >> 17) & 4095) << 1) | 1));
		foo->stackPointer = sp;
	}
}

sqInt primitiveAt(void) {
	commonAt(0);
}

sqInt primitiveAtEnd(void) {
register struct foo * foo = &fum;
    sqInt stream;
    sqInt index;
    sqInt limit;
    sqInt sp;
    sqInt sp1;
    sqInt top;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	stream = top;
	foo->successFlag = (((stream & 1) == 0) && (((((usqInt) (longAt(stream))) >> 8) & 15) <= 4)) && ((lengthOf(stream)) >= (StreamReadLimitIndex + 1));
	if (foo->successFlag) {
		index = fetchIntegerofObject(StreamIndexIndex, stream);
		limit = fetchIntegerofObject(StreamReadLimitIndex, stream);
	}
	if (foo->successFlag) {
		/* begin pushBool: */
		if (index >= limit) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
	}
}

sqInt primitiveAtPut(void) {
	commonAtPut(0);
}


/*	Set the cursor to the given shape. The Mac only supports 16x16 pixel cursors. Cursor offsets are handled by Smalltalk. */

sqInt primitiveBeCursor(void) {
register struct foo * foo = &fum;
    sqInt offsetY;
    sqInt extentX;
    sqInt offsetObj;
    sqInt bitsObj;
    sqInt maskBitsIndex;
    sqInt offsetX;
    sqInt cursorBitsIndex;
    sqInt cursorObj;
    sqInt extentY;
    sqInt ourCursor;
    sqInt i;
    sqInt maskObj;
    sqInt depth;
    sqInt successValue;
    sqInt successValue1;
    sqInt successValue2;
    sqInt successValue3;
    sqInt successValue4;
    sqInt successValue5;
    sqInt successValue6;
    sqInt successValue7;
    sqInt successValue8;
    sqInt successValue9;
    sqInt successValue10;
    sqInt successValue11;
    sqInt successValue12;

	flag("Dan");
	if (BytesPerWord == 8) {
		/* begin pop: */
		foo->stackPointer -= foo->argumentCount * BytesPerWord;
		return null;
	}
	if (foo->argumentCount == 0) {
		cursorObj = longAt(foo->stackPointer);
		maskBitsIndex = null;
	}
	if (foo->argumentCount == 1) {
		cursorObj = longAt(foo->stackPointer - (1 * BytesPerWord));
		maskObj = longAt(foo->stackPointer);
	}
	/* begin success: */
	foo->successFlag = (foo->argumentCount < 2) && foo->successFlag;
	/* begin success: */
	successValue11 = (((cursorObj & 1) == 0) && (((((usqInt) (longAt(cursorObj))) >> 8) & 15) <= 4)) && ((lengthOf(cursorObj)) >= 5);
	foo->successFlag = successValue11 && foo->successFlag;
	if (foo->successFlag) {
		bitsObj = longAt((cursorObj + BaseHeaderSize) + (0 << ShiftForWord));
		extentX = fetchIntegerofObject(1, cursorObj);
		extentY = fetchIntegerofObject(2, cursorObj);
		depth = fetchIntegerofObject(3, cursorObj);
		offsetObj = longAt((cursorObj + BaseHeaderSize) + (4 << ShiftForWord));
	}
	/* begin success: */
	successValue12 = (((offsetObj & 1) == 0) && (((((usqInt) (longAt(offsetObj))) >> 8) & 15) <= 4)) && ((lengthOf(offsetObj)) >= 2);
	foo->successFlag = successValue12 && foo->successFlag;
	if (foo->successFlag) {
		offsetX = fetchIntegerofObject(0, offsetObj);
		offsetY = fetchIntegerofObject(1, offsetObj);
		if ((foo->argumentCount == 0) && (depth == 32)) {
			/* begin success: */
			successValue = (extentX > 0) && (extentY > 0);
			foo->successFlag = successValue && foo->successFlag;
			/* begin success: */
			successValue1 = (offsetX >= (extentX * -1)) && (offsetX <= 0);
			foo->successFlag = successValue1 && foo->successFlag;
			/* begin success: */
			successValue2 = (offsetY >= (extentY * -1)) && (offsetY <= 0);
			foo->successFlag = successValue2 && foo->successFlag;
			cursorBitsIndex = bitsObj + BaseHeaderSize;
			/* begin success: */
			successValue3 = (((bitsObj & 1) == 0) && (((((usqInt) (longAt(bitsObj))) >> 8) & 15) == 6)) && ((lengthOf(bitsObj)) == (extentX * extentY));
			foo->successFlag = successValue3 && foo->successFlag;
			;
		} else {
			/* begin success: */
			successValue4 = (extentX == 16) && ((extentY == 16) && (depth == 1));
			foo->successFlag = successValue4 && foo->successFlag;
			/* begin success: */
			successValue5 = (offsetX >= -16) && (offsetX <= 0);
			foo->successFlag = successValue5 && foo->successFlag;
			/* begin success: */
			successValue6 = (offsetY >= -16) && (offsetY <= 0);
			foo->successFlag = successValue6 && foo->successFlag;
			/* begin success: */
			successValue7 = (((bitsObj & 1) == 0) && (((((usqInt) (longAt(bitsObj))) >> 8) & 15) == 6)) && ((lengthOf(bitsObj)) == 16);
			foo->successFlag = successValue7 && foo->successFlag;
			cursorBitsIndex = bitsObj + BaseHeaderSize;
			;
		}
	}
	if (foo->argumentCount == 1) {
		/* begin success: */
		successValue10 = (((maskObj & 1) == 0) && (((((usqInt) (longAt(maskObj))) >> 8) & 15) <= 4)) && ((lengthOf(maskObj)) >= 5);
		foo->successFlag = successValue10 && foo->successFlag;
		if (foo->successFlag) {
			bitsObj = longAt((maskObj + BaseHeaderSize) + (0 << ShiftForWord));
			extentX = fetchIntegerofObject(1, maskObj);
			extentY = fetchIntegerofObject(2, maskObj);
			depth = fetchIntegerofObject(3, maskObj);
		}
		if (foo->successFlag) {
			/* begin success: */
			successValue8 = (extentX == 16) && ((extentY == 16) && (depth == 1));
			foo->successFlag = successValue8 && foo->successFlag;
			/* begin success: */
			successValue9 = (((bitsObj & 1) == 0) && (((((usqInt) (longAt(bitsObj))) >> 8) & 15) == 6)) && ((lengthOf(bitsObj)) == 16);
			foo->successFlag = successValue9 && foo->successFlag;
			maskBitsIndex = bitsObj + BaseHeaderSize;
		}
	}
	if (foo->successFlag) {
		if (foo->argumentCount == 0) {
			if (depth == 32) {
				if (!(ioSetCursorARGB(cursorBitsIndex, extentX, extentY, offsetX, offsetY))) {
					/* begin success: */
					foo->successFlag = 0 && foo->successFlag;
					return null;
				}
			} else {
				ioSetCursor(cursorBitsIndex, offsetX, offsetY);
			}
		} else {
			ioSetCursorWithMask(cursorBitsIndex, maskBitsIndex, offsetX, offsetY);
		}
		/* begin pop: */
		foo->stackPointer -= foo->argumentCount * BytesPerWord;
	}
}


/*	Record the system Display object in the specialObjectsTable. */

sqInt primitiveBeDisplay(void) {
register struct foo * foo = &fum;
    sqInt rcvr;
    sqInt oop;
    sqInt successValue;

	rcvr = longAt(foo->stackPointer);
	/* begin success: */
	successValue = (((rcvr & 1) == 0) && (((((usqInt) (longAt(rcvr))) >> 8) & 15) <= 4)) && ((lengthOf(rcvr)) >= 4);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		/* begin storePointer:ofObject:withValue: */
		oop = foo->specialObjectsOop;
		if ((((usqInt) oop)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(oop, rcvr);
		}
		longAtput((oop + BaseHeaderSize) + (TheDisplay << ShiftForWord), rcvr);
	}
}


/*	make the basic beep noise */

sqInt primitiveBeep(void) {
	ioBeep();
}

sqInt primitiveBitAnd(void) {
register struct foo * foo = &fum;
    sqInt integerArgument;
    sqInt integerReceiver;
    sqInt object;
    sqInt sp;
    sqInt top;
    sqInt top1;
    sqInt top2;
    sqInt top11;

	/* begin popPos32BitInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	top = top1;
	integerArgument = positive32BitValueOf(top);
	/* begin popPos32BitInteger */
	/* begin popStack */
	top11 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	top2 = top11;
	integerReceiver = positive32BitValueOf(top2);
	if (foo->successFlag) {
		/* begin push: */
		object = positive32BitIntegerFor(integerReceiver & integerArgument);
		longAtput(sp = foo->stackPointer + BytesPerWord, object);
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}

sqInt primitiveBitOr(void) {
register struct foo * foo = &fum;
    sqInt integerArgument;
    sqInt integerReceiver;
    sqInt object;
    sqInt sp;
    sqInt top;
    sqInt top1;
    sqInt top2;
    sqInt top11;

	/* begin popPos32BitInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	top = top1;
	integerArgument = positive32BitValueOf(top);
	/* begin popPos32BitInteger */
	/* begin popStack */
	top11 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	top2 = top11;
	integerReceiver = positive32BitValueOf(top2);
	if (foo->successFlag) {
		/* begin push: */
		object = positive32BitIntegerFor(integerReceiver | integerArgument);
		longAtput(sp = foo->stackPointer + BytesPerWord, object);
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}

sqInt primitiveBitShift(void) {
register struct foo * foo = &fum;
    sqInt integerArgument;
    sqInt shifted;
    sqInt integerReceiver;
    sqInt integerPointer;
    sqInt object;
    sqInt sp;
    sqInt top;
    sqInt top2;
    sqInt top1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer = top;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		integerArgument = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerArgument = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	/* begin popPos32BitInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	top2 = top1;
	integerReceiver = positive32BitValueOf(top2);
	if (foo->successFlag) {
		if (integerArgument >= 0) {
			/* begin success: */
			foo->successFlag = (integerArgument <= 31) && foo->successFlag;
			shifted = integerReceiver << integerArgument;
			/* begin success: */
			foo->successFlag = ((((usqInt) shifted) >> integerArgument) == integerReceiver) && foo->successFlag;
		} else {
			/* begin success: */
			foo->successFlag = (integerArgument >= -31) && foo->successFlag;
			shifted = ((integerArgument < 0) ? ((usqInt) integerReceiver >> -integerArgument) : ((usqInt) integerReceiver << integerArgument));
		}
	}
	if (foo->successFlag) {
		/* begin push: */
		object = positive32BitIntegerFor(shifted);
		longAtput(sp = foo->stackPointer + BytesPerWord, object);
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}

sqInt primitiveBitXor(void) {
register struct foo * foo = &fum;
    sqInt integerArgument;
    sqInt integerReceiver;
    sqInt object;
    sqInt sp;
    sqInt top;
    sqInt top1;
    sqInt top2;
    sqInt top11;

	/* begin popPos32BitInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	top = top1;
	integerArgument = positive32BitValueOf(top);
	/* begin popPos32BitInteger */
	/* begin popStack */
	top11 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	top2 = top11;
	integerReceiver = positive32BitValueOf(top2);
	if (foo->successFlag) {
		/* begin push: */
		object = positive32BitIntegerFor(integerReceiver ^ integerArgument);
		longAtput(sp = foo->stackPointer + BytesPerWord, object);
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}

sqInt primitiveBlockCopy(void) {
register struct foo * foo = &fum;
    sqInt initialIP;
    sqInt newContext;
    sqInt context;
    sqInt methodContext;
    sqInt contextSize;
    sqInt header;
    sqInt oop;
    sqInt sp;

	context = longAt(foo->stackPointer - (1 * BytesPerWord));
	if (((longAt((context + BaseHeaderSize) + (MethodIndex << ShiftForWord))) & 1)) {
		methodContext = longAt((context + BaseHeaderSize) + (HomeIndex << ShiftForWord));
	} else {
		methodContext = context;
	}
	/* begin sizeBitsOf: */
	header = longAt(methodContext);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		contextSize = (longAt(methodContext - (BytesPerWord * 2))) & LongSizeMask;
		goto l1;
	} else {
		contextSize = header & SizeMask;
		goto l1;
	}
l1:	/* end sizeBitsOf: */;

	/* context is no longer needed and is not preserved across allocation */
	/* remap methodContext in case GC happens during allocation */

	context = null;
	/* begin pushRemappableOop: */
	foo->remapBuffer[foo->remapBufferCount += 1] = methodContext;
	newContext = instantiateContextsizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassBlockContext << ShiftForWord)), contextSize);
	/* begin popRemappableOop */
	oop = foo->remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	methodContext = oop;

	/* Was instructionPointer + 3, but now it's greater by 1 due to preIncrement */
	/* Assume: have just allocated a new context; it must be young.
	 Thus, can use uncheck stores. See the comment in fetchContextRegisters. */

	initialIP = (((((foo->instructionPointer + 1) + 3) - (foo->method + BaseHeaderSize)) << 1) | 1);
	longAtput((newContext + BaseHeaderSize) + (InitialIPIndex << ShiftForWord), initialIP);
	longAtput((newContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), initialIP);
	/* begin storeStackPointerValue:inContext: */
	longAtput((newContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), ((0 << 1) | 1));
	longAtput((newContext + BaseHeaderSize) + (BlockArgumentCountIndex << ShiftForWord), longAt(foo->stackPointer - (0 * BytesPerWord)));
	longAtput((newContext + BaseHeaderSize) + (HomeIndex << ShiftForWord), methodContext);
	longAtput((newContext + BaseHeaderSize) + (SenderIndex << ShiftForWord), foo->nilObj);
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), newContext);
	foo->stackPointer = sp;
}


/*	Reports bytes available at this moment. For more meaningful 
	results, calls to this primitive should be preceeded by a full 
	or incremental garbage collection. */

sqInt primitiveBytesLeft(void) {
register struct foo * foo = &fum;
    sqInt aBool;
    sqInt sp;
    sqInt integerVal;
    sqInt sp1;

	if (foo->argumentCount == 0) {
		/* begin pop:thenPushInteger: */
		longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), ((((longAt(foo->freeBlock)) & AllButTypeMask) << 1) | 1));
		foo->stackPointer = sp;
		return null;
	}
	if (foo->argumentCount == 1) {
		/* begin booleanValueOf: */
		if ((longAt(foo->stackPointer)) == foo->trueObj) {
			aBool = 1;
			goto l1;
		}
		if ((longAt(foo->stackPointer)) == foo->falseObj) {
			aBool = 0;
			goto l1;
		}
		foo->successFlag = 0;
		aBool = null;
	l1:	/* end booleanValueOf: */;
		if (!(foo->successFlag)) {
			return null;
		}
		/* begin pop:thenPushInteger: */
		integerVal = ((longAt(foo->freeBlock)) & AllButTypeMask) + (sqMemoryExtraBytesLeft(aBool));
		longAtput(sp1 = foo->stackPointer - ((2 - 1) * BytesPerWord), ((integerVal << 1) | 1));
		foo->stackPointer = sp1;
		return null;
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
	return null;
}


/*	Perform a function call to a foreign function.
	Only invoked from method containing explicit external call spec.
	Due to this we use the pluggable prim mechanism explicitly here
	(the first literal of any FFI spec'ed method is an ExternalFunction
	and not an array as used in the pluggable primitive mechanism). */

sqInt primitiveCalloutToFFI(void) {
    static char *moduleName = "SqueakFFIPrims";
    static void *function = 0;
    static char *functionName = "primitiveCallout";

	if (function == 0) {
		function = ioLoadExternalFunctionOfLengthFromModuleOfLength(oopForPointer(functionName), 16, oopForPointer(moduleName), 14);
		if (function == 0) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	return ((sqInt (*)(void))function)();
}


/*	Primitive. Change the class of the receiver into the class of the argument given that the format of the receiver matches the format of the argument's class. Fail if receiver or argument are SmallIntegers, or the receiver is an instance of a compact class and the argument isn't, or when the argument's class is compact and the receiver isn't, or when the format of the receiver is different from the format of the argument's class, or when the arguments class is fixed and the receiver's size differs from the size that an instance of the argument's class should have. */

sqInt primitiveChangeClass(void) {
register struct foo * foo = &fum;
    sqInt rcvr;
    sqInt arg;
    sqInt argClass;
    sqInt oop;
    sqInt oop1;
    sqInt ccIndex;

	if (!(foo->argumentCount == 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackObjectValue: */
	oop = longAt(foo->stackPointer - (0 * BytesPerWord));
	if ((oop & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		arg = null;
		goto l1;
	}
	arg = oop;
l1:	/* end stackObjectValue: */;
	/* begin stackObjectValue: */
	oop1 = longAt(foo->stackPointer - (1 * BytesPerWord));
	if ((oop1 & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		rcvr = null;
		goto l2;
	}
	rcvr = oop1;
l2:	/* end stackObjectValue: */;
	/* begin fetchClassOf: */
	if ((arg & 1)) {
		argClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l3;
	}
	ccIndex = (((usqInt) (longAt(arg))) >> 12) & 31;
	if (ccIndex == 0) {
		argClass = (longAt(arg - BaseHeaderSize)) & AllButTypeMask;
		goto l3;
	} else {
		argClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l3;
	}
l3:	/* end fetchClassOf: */;
	changeClassOfto(rcvr, argClass);
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 1 * BytesPerWord;
	}
	return null;
}


/*	Primitive. Change the class of the receiver into the class of the argument given that the format of the receiver matches the format of the argument's class. Fail if receiver or argument are SmallIntegers, or the receiver is an instance of a compact class and the argument isn't, or when the argument's class is compact and the receiver isn't, or when the format of the receiver is different from the format of the argument's class, or when the arguments class is fixed and the receiver's size differs from the size that an instance of the argument's class should have. */

EXPORT(sqInt) primitiveChangeClassWithClass(void) {
register struct foo * foo = &fum;
    sqInt rcvr;
    sqInt argClass;
    sqInt oop;
    sqInt oop1;

	if (!(foo->argumentCount == 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackObjectValue: */
	oop = longAt(foo->stackPointer - (0 * BytesPerWord));
	if ((oop & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		argClass = null;
		goto l1;
	}
	argClass = oop;
l1:	/* end stackObjectValue: */;
	/* begin stackObjectValue: */
	oop1 = longAt(foo->stackPointer - (1 * BytesPerWord));
	if ((oop1 & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		rcvr = null;
		goto l2;
	}
	rcvr = oop1;
l2:	/* end stackObjectValue: */;
	changeClassOfto(rcvr, argClass);
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 1 * BytesPerWord;
	}
	return null;
}

sqInt primitiveClass(void) {
register struct foo * foo = &fum;
    sqInt instance;
    sqInt oop;
    sqInt sp;
    sqInt ccIndex;

	instance = longAt(foo->stackPointer);
	/* begin pop:thenPush: */
	/* begin fetchClassOf: */
	if ((instance & 1)) {
		oop = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(instance))) >> 12) & 31;
	if (ccIndex == 0) {
		oop = (longAt(instance - BaseHeaderSize)) & AllButTypeMask;
		goto l1;
	} else {
		oop = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * BytesPerWord), oop);
	foo->stackPointer = sp;
}


/*	When called with a single string argument, post the string to 
	the clipboard. When called with zero arguments, return a 
	string containing the current clipboard contents. */

sqInt primitiveClipboardText(void) {
register struct foo * foo = &fum;
    sqInt sz;
    sqInt s;
    sqInt sp;

	if (foo->argumentCount == 1) {
		s = longAt(foo->stackPointer);
		if (!(((s & 1) == 0) && (((((usqInt) (longAt(s))) >> 8) & 15) >= 8))) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
		if (foo->successFlag) {
			sz = stSizeOf(s);
			clipboardWriteFromAt(sz, s + BaseHeaderSize, 0);
			/* begin pop: */
			foo->stackPointer -= 1 * BytesPerWord;
		}
	} else {
		sz = clipboardSize();
		if (!(sufficientSpaceToAllocate(sz))) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
		s = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassString << ShiftForWord)), sz);
		clipboardReadIntoAt(sz, s + BaseHeaderSize, 0);
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), s);
		foo->stackPointer = sp;
	}
}


/*	Return a shallow copy of the receiver. */

sqInt primitiveClone(void) {
register struct foo * foo = &fum;
    sqInt newCopy;
    sqInt sp;

	newCopy = clone(longAt(foo->stackPointer));
	if (newCopy == 0) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), newCopy);
	foo->stackPointer = sp;
}

sqInt primitiveClosureCopyWithCopiedValues(void) {
register struct foo * foo = &fum;
    sqInt numCopiedValues;
    sqInt numArgs;
    sqInt copiedValues;
    sqInt newClosure;
    sqInt i;
    sqInt integerPointer;
    sqInt successValue;
    sqInt sz;
    sqInt initialIP;
    sqInt newClosure1;
    sqInt sp;
    sqInt header;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		numArgs = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		numArgs = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	copiedValues = longAt(foo->stackPointer);
	/* begin success: */
	successValue = (fetchClassOf(copiedValues)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassArray << ShiftForWord)));
	foo->successFlag = successValue && foo->successFlag;
	if (!(foo->successFlag)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin fetchWordLengthOf: */
	/* begin sizeBitsOf: */
	header = longAt(copiedValues);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(copiedValues - (BytesPerWord * 2))) & LongSizeMask;
		goto l2;
	} else {
		sz = header & SizeMask;
		goto l2;
	}
l2:	/* end sizeBitsOf: */;
	numCopiedValues = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
	/* begin closureNumArgs:instructionPointer:numCopiedValues: */
	initialIP = (foo->instructionPointer + 2) - (foo->method + BaseHeaderSize);
	newClosure1 = instantiateSmallClasssizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassBlockClosure << ShiftForWord)), (BytesPerWord * (ClosureFirstCopiedValueIndex + numCopiedValues)) + BaseHeaderSize);
	longAtput((newClosure1 + BaseHeaderSize) + (ClosureStartPCIndex << ShiftForWord), ((initialIP << 1) | 1));
	longAtput((newClosure1 + BaseHeaderSize) + (ClosureNumArgsIndex << ShiftForWord), ((numArgs << 1) | 1));
	newClosure = newClosure1;
	longAtput((newClosure + BaseHeaderSize) + (ClosureOuterContextIndex << ShiftForWord), longAt(foo->stackPointer - (2 * BytesPerWord)));
	if (numCopiedValues > 0) {
		copiedValues = longAt(foo->stackPointer);
		for (i = 0; i <= (numCopiedValues - 1); i += 1) {
			longAtput((newClosure + BaseHeaderSize) + ((i + ClosureFirstCopiedValueIndex) << ShiftForWord), longAt((copiedValues + BaseHeaderSize) + (i << ShiftForWord)));
		}
	}
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((3 - 1) * BytesPerWord), newClosure);
	foo->stackPointer = sp;
}

sqInt primitiveClosureValue(void) {
register struct foo * foo = &fum;
    sqInt blockClosure;
    sqInt outerContext;
    sqInt closureMethod;
    sqInt blockArgumentCount;

	blockClosure = longAt(foo->stackPointer - (foo->argumentCount * BytesPerWord));
	blockArgumentCount = ((longAt((blockClosure + BaseHeaderSize) + (ClosureNumArgsIndex << ShiftForWord))) >> 1);
	if (!(foo->argumentCount == blockArgumentCount)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	outerContext = longAt((blockClosure + BaseHeaderSize) + (ClosureOuterContextIndex << ShiftForWord));
	if (!(((outerContext & 1) == 0) && ((((((usqInt) (longAt(outerContext))) >> 12) & 31) == 13) || ((((((usqInt) (longAt(outerContext))) >> 12) & 31) == 14) || (((((usqInt) (longAt(outerContext))) >> 12) & 31) == 4))))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}

	/* Check if the closure's method is actually a CompiledMethod. */

	closureMethod = longAt((outerContext + BaseHeaderSize) + (MethodIndex << ShiftForWord));
	if (!(((closureMethod & 1) == 0) && (((((usqInt) (longAt(closureMethod))) >> 8) & 15) >= 12))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	activateNewClosureMethod(blockClosure);
	/* begin quickCheckForInterrupts */
	if ((foo->interruptCheckCounter -= 1) <= 0) {
		checkForInterrupts();
	}
}


/*	An exact clone of primitiveClosureValue except that this version will not
	 check for interrupts on stack overflow. */

sqInt primitiveClosureValueNoContextSwitch(void) {
register struct foo * foo = &fum;
    sqInt blockClosure;
    sqInt outerContext;
    sqInt closureMethod;
    sqInt blockArgumentCount;

	blockClosure = longAt(foo->stackPointer - (foo->argumentCount * BytesPerWord));
	blockArgumentCount = ((longAt((blockClosure + BaseHeaderSize) + (ClosureNumArgsIndex << ShiftForWord))) >> 1);
	if (!(foo->argumentCount == blockArgumentCount)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	outerContext = longAt((blockClosure + BaseHeaderSize) + (ClosureOuterContextIndex << ShiftForWord));
	if (!(((outerContext & 1) == 0) && ((((((usqInt) (longAt(outerContext))) >> 12) & 31) == 13) || ((((((usqInt) (longAt(outerContext))) >> 12) & 31) == 14) || (((((usqInt) (longAt(outerContext))) >> 12) & 31) == 4))))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}

	/* Check if the closure's method is actually a CompiledMethod. */

	closureMethod = longAt((outerContext + BaseHeaderSize) + (MethodIndex << ShiftForWord));
	if (!(((closureMethod & 1) == 0) && (((((usqInt) (longAt(closureMethod))) >> 8) & 15) >= 12))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	activateNewClosureMethod(blockClosure);
}

sqInt primitiveClosureValueWithArgs(void) {
register struct foo * foo = &fum;
    sqInt cntxSize;
    sqInt blockClosure;
    sqInt outerContext;
    sqInt arraySize;
    sqInt closureMethod;
    sqInt argumentArray;
    sqInt blockArgumentCount;
    sqInt index;
    sqInt sp;
    sqInt sz;
    sqInt header;
    sqInt sz1;
    sqInt header1;
    sqInt top;

	argumentArray = longAt(foo->stackPointer);
	if (!(((argumentArray & 1) == 0) && (((((usqInt) (longAt(argumentArray))) >> 8) & 15) == 2))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin fetchWordLengthOf: */
	/* begin sizeBitsOf: */
	header = longAt(argumentArray);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(argumentArray - (BytesPerWord * 2))) & LongSizeMask;
		goto l1;
	} else {
		sz = header & SizeMask;
		goto l1;
	}
l1:	/* end sizeBitsOf: */;
	arraySize = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
	/* begin fetchWordLengthOf: */
	/* begin sizeBitsOf: */
	header1 = longAt(foo->activeContext);
	if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(foo->activeContext - (BytesPerWord * 2))) & LongSizeMask;
		goto l2;
	} else {
		sz1 = header1 & SizeMask;
		goto l2;
	}
l2:	/* end sizeBitsOf: */;
	cntxSize = ((usqInt) (sz1 - BaseHeaderSize)) >> ShiftForWord;
	if (!(((((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) + arraySize) < cntxSize)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	blockClosure = longAt(foo->stackPointer - (foo->argumentCount * BytesPerWord));
	blockArgumentCount = ((longAt((blockClosure + BaseHeaderSize) + (ClosureNumArgsIndex << ShiftForWord))) >> 1);
	if (!(arraySize == blockArgumentCount)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	outerContext = longAt((blockClosure + BaseHeaderSize) + (ClosureOuterContextIndex << ShiftForWord));
	if (!(((outerContext & 1) == 0) && ((((((usqInt) (longAt(outerContext))) >> 12) & 31) == 13) || ((((((usqInt) (longAt(outerContext))) >> 12) & 31) == 14) || (((((usqInt) (longAt(outerContext))) >> 12) & 31) == 4))))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}

	/* Check if the closure's method is actually a CompiledMethod. */

	closureMethod = longAt((outerContext + BaseHeaderSize) + (MethodIndex << ShiftForWord));
	if (!(((closureMethod & 1) == 0) && (((((usqInt) (longAt(closureMethod))) >> 8) & 15) >= 12))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	index = 1;
	while (index <= arraySize) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, longAt((argumentArray + BaseHeaderSize) + ((index - 1) << ShiftForWord)));
		foo->stackPointer = sp;
		index += 1;
	}
	foo->argumentCount = arraySize;
	activateNewClosureMethod(blockClosure);
	/* begin quickCheckForInterrupts */
	if ((foo->interruptCheckCounter -= 1) <= 0) {
		checkForInterrupts();
	}
}


/*	Fill the receiver, which must be an indexable bytes or words 
	objects, with the given integer value. */

sqInt primitiveConstantFill(void) {
register struct foo * foo = &fum;
    sqInt rcvr;
    sqInt rcvrIsBytes;
    sqInt fillValue;
    usqInt end;
    usqInt i;
    sqInt successValue;
    sqInt successValue1;

	fillValue = positive32BitValueOf(longAt(foo->stackPointer));
	rcvr = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin success: */
	successValue1 = ((rcvr & 1) == 0) && (isWordsOrBytesNonInt(rcvr));
	foo->successFlag = successValue1 && foo->successFlag;
	rcvrIsBytes = ((rcvr & 1) == 0) && (((((usqInt) (longAt(rcvr))) >> 8) & 15) >= 8);
	if (rcvrIsBytes) {
		/* begin success: */
		successValue = (fillValue >= 0) && (fillValue <= 255);
		foo->successFlag = successValue && foo->successFlag;
	}
	if (foo->successFlag) {
		end = rcvr + (sizeBitsOf(rcvr));
		i = rcvr + BaseHeaderSize;
		if (rcvrIsBytes) {
			while (i < end) {
				byteAtput(i, fillValue);
				i += 1;
			}
		} else {
			while (i < end) {
				long32Atput(i, fillValue);
				i += 4;
			}
		}
		/* begin pop: */
		foo->stackPointer -= 1 * BytesPerWord;
	}
}


/*	Primitive. Copy the state of the receiver from the argument. 
		Fail if receiver and argument are of a different class. 
		Fail if the receiver or argument are non-pointer objects.
		Fail if receiver and argument have different lengths (for indexable objects).
	 */

sqInt primitiveCopyObject(void) {
register struct foo * foo = &fum;
    sqInt rcvr;
    sqInt arg;
    sqInt length;
    sqInt i;
    sqInt oop;
    sqInt oop1;
    sqInt header;
    sqInt sz;

	if (!(foo->argumentCount == 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackObjectValue: */
	oop = longAt(foo->stackPointer - (0 * BytesPerWord));
	if ((oop & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		arg = null;
		goto l1;
	}
	arg = oop;
l1:	/* end stackObjectValue: */;
	/* begin stackObjectValue: */
	oop1 = longAt(foo->stackPointer - (1 * BytesPerWord));
	if ((oop1 & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		rcvr = null;
		goto l2;
	}
	rcvr = oop1;
l2:	/* end stackObjectValue: */;
	if (!foo->successFlag) {
		return null;
	}
	if (!(((rcvr & 1) == 0) && (((((usqInt) (longAt(rcvr))) >> 8) & 15) <= 4))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (!((fetchClassOf(rcvr)) == (fetchClassOf(arg)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin lengthOf: */
	header = longAt(rcvr);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(rcvr - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz = header & SizeMask;
	}
	sz -= header & Size4Bit;
	if (((((usqInt) header) >> 8) & 15) <= 4) {
		length = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
		goto l3;
	}
	if (((((usqInt) header) >> 8) & 15) < 8) {
		length = ((usqInt) (sz - BaseHeaderSize)) >> 2;
		goto l3;
	} else {
		length = (sz - BaseHeaderSize) - (((((usqInt) header) >> 8) & 15) & 3);
		goto l3;
	}
	length = null;
l3:	/* end lengthOf: */;
	if (!(length == (lengthOf(arg)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	for (i = 0; i <= (length - 1); i += 1) {
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(rcvr, longAt((arg + BaseHeaderSize) + (i << ShiftForWord)));
		}
		longAtput((rcvr + BaseHeaderSize) + (i << ShiftForWord), longAt((arg + BaseHeaderSize) + (i << ShiftForWord)));
	}
	/* begin pop: */
	foo->stackPointer -= 1 * BytesPerWord;
}


/*	Set or clear the flag that controls whether modifications of 
	the Display object are propagated to the underlying 
	platform's screen. */

sqInt primitiveDeferDisplayUpdates(void) {
register struct foo * foo = &fum;
    sqInt flag;

	flag = longAt(foo->stackPointer);
	if (flag == foo->trueObj) {
		foo->deferDisplayUpdates = 1;
	} else {
		if (flag == foo->falseObj) {
			foo->deferDisplayUpdates = 0;
		} else {
			/* begin primitiveFail */
			foo->successFlag = 0;
		}
	}
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 1 * BytesPerWord;
	}
}


/*	Pass in a non-negative value to disable the architectures powermanager if any, zero to enable. This is a named (not numbered) primitive in the null module (ie the VM) */

EXPORT(sqInt) primitiveDisablePowerManager(void) {
register struct foo * foo = &fum;
    sqInt integer;
    sqInt integerPointer;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		integer = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integer = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	if (foo->successFlag) {
		ioDisablePowerManager(integer);
		/* begin pop: */
		foo->stackPointer -= 1 * BytesPerWord;
	}
}

sqInt primitiveDiv(void) {
register struct foo * foo = &fum;
    sqInt quotient;
    sqInt sp;

	quotient = doPrimitiveDivby(longAt(foo->stackPointer - (1 * BytesPerWord)), longAt(foo->stackPointer));
	/* begin pop2AndPushIntegerIfOK: */
	if (foo->successFlag) {
		if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
			(((((int) quotient)) ^ ((((int) quotient)) << 1)) >= 0)
# else
			((quotient >= -1073741824) && (quotient <= 1073741823))
# endif  // SQ_HOST32
		) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), ((quotient << 1) | 1));
			foo->stackPointer = sp;
		} else {
			foo->successFlag = 0;
		}
	}
}

sqInt primitiveDivide(void) {
register struct foo * foo = &fum;
    sqInt integerArgument;
    sqInt integerReceiver;
    sqInt integerPointer;
    sqInt integerPointer1;
    sqInt sp;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		integerReceiver = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerReceiver = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	/* begin stackIntegerValue: */
	integerPointer1 = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer1 & 1)) {
		integerArgument = (integerPointer1 >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerArgument = 0;
		goto l2;
	}
l2:	/* end checkedIntegerValueOf: */;
	if ((integerArgument != 0) && ((integerReceiver % integerArgument) == 0)) {
		/* begin pop2AndPushIntegerIfOK: */
		if (foo->successFlag) {
			if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
				(((((int) (integerReceiver / integerArgument))) ^ ((((int) (integerReceiver / integerArgument))) << 1)) >= 0)
# else
				(((integerReceiver / integerArgument) >= -1073741824) && ((integerReceiver / integerArgument) <= 1073741823))
# endif  // SQ_HOST32
			) {
				/* begin pop:thenPush: */
				longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), (((integerReceiver / integerArgument) << 1) | 1));
				foo->stackPointer = sp;
			} else {
				foo->successFlag = 0;
			}
		}
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
	}
}


/*	Simulate an primitiveExternalCall invocation (e.g. for the Debugger).  Do not cache anything.
	 e.g. ContextPart>>tryNamedPrimitiveIn: aCompiledMethod for: aReceiver withArgs: arguments */

sqInt primitiveDoNamedPrimitiveWithArgs(void) {
register struct foo * foo = &fum;
    sqInt functionLength;
    void (*addr)();
    sqInt methodHeader;
    sqInt moduleLength;
    sqInt moduleName;
    sqInt methodArg;
    sqInt functionName;
    sqInt arraySize;
    sqInt spec;
    sqInt argumentArray;
    sqInt index;
    sqInt successValue;
    sqInt header;
    sqInt sz;
    sqInt sp;
    sqInt sp1;
    sqInt sz1;
    sqInt header1;
    sqInt successValue1;
    sqInt oop;
    sqInt oop1;
    sqInt ccIndex;
    sqInt cl;
    sqInt successValue2;
    sqInt header2;
    sqInt sz2;
    sqInt oop2;
    sqInt cntxSize;

	argumentArray = longAt(foo->stackPointer);
	if (!(((argumentArray & 1) == 0) && (((((usqInt) (longAt(argumentArray))) >> 8) & 15) == 2))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin fetchWordLengthOf: */
	/* begin sizeBitsOf: */
	header1 = longAt(argumentArray);
	if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(argumentArray - (BytesPerWord * 2))) & LongSizeMask;
		goto l2;
	} else {
		sz1 = header1 & SizeMask;
		goto l2;
	}
l2:	/* end sizeBitsOf: */;
	arraySize = ((usqInt) (sz1 - BaseHeaderSize)) >> ShiftForWord;
	/* begin success: */
	/* begin roomToPushNArgs: */
	if (((longAt((foo->method + BaseHeaderSize) + (HeaderIndex << ShiftForWord))) & LargeContextBit) != 0) {
		cntxSize = (((sqInt) LargeContextSize >> 2)) - ReceiverIndex;
	} else {
		cntxSize = (((sqInt) SmallContextSize >> 2)) - ReceiverIndex;
	}
	successValue1 = ((((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) + arraySize) <= cntxSize;
	foo->successFlag = successValue1 && foo->successFlag;
	/* begin stackObjectValue: */
	oop = longAt(foo->stackPointer - (2 * BytesPerWord));
	if ((oop & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		methodArg = null;
		goto l3;
	}
	methodArg = oop;
l3:	/* end stackObjectValue: */;
	if (!(foo->successFlag)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (!(((((usqInt) (longAt(methodArg))) >> 8) & 15) >= 12)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	methodHeader = longAt((methodArg + BaseHeaderSize) + (HeaderIndex << ShiftForWord));
	if (!(((((usqInt) methodHeader) >> 10) & 255) > 2)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin assertClassOf:is: */
	oop1 = spec = longAt((methodArg + BaseHeaderSize) + (1 << ShiftForWord));
	if ((oop1 & 1)) {
		foo->successFlag = 0;
		goto l4;
	}
	ccIndex = (((usqInt) (longAt(oop1))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(oop1 - BaseHeaderSize)) & AllButTypeMask;
	} else {
		cl = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassArray << ShiftForWord)))) && foo->successFlag;
l4:	/* end assertClassOf:is: */;
	if (!(foo->successFlag && (((lengthOf(spec)) == 4) && ((primitiveIndexOfMethodHeader(methodHeader)) == 117)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (!(((((usqInt) methodHeader) >> 25) & 15) == arraySize)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	moduleName = longAt((spec + BaseHeaderSize) + (0 << ShiftForWord));
	if (moduleName == foo->nilObj) {
		moduleLength = 0;
	} else {
		/* begin success: */
		successValue = ((moduleName & 1) == 0) && (((((usqInt) (longAt(moduleName))) >> 8) & 15) >= 8);
		foo->successFlag = successValue && foo->successFlag;
		/* begin lengthOf: */
		header = longAt(moduleName);
		/* begin lengthOf:baseHeader:format: */
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(moduleName - (BytesPerWord * 2))) & LongSizeMask;
		} else {
			sz = header & SizeMask;
		}
		sz -= header & Size4Bit;
		if (((((usqInt) header) >> 8) & 15) <= 4) {
			moduleLength = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
			goto l1;
		}
		if (((((usqInt) header) >> 8) & 15) < 8) {
			moduleLength = ((usqInt) (sz - BaseHeaderSize)) >> 2;
			goto l1;
		} else {
			moduleLength = (sz - BaseHeaderSize) - (((((usqInt) header) >> 8) & 15) & 3);
			goto l1;
		}
		moduleLength = null;
	l1:	/* end lengthOf: */;
		;
	}
	functionName = longAt((spec + BaseHeaderSize) + (1 << ShiftForWord));
	/* begin success: */
	successValue2 = ((functionName & 1) == 0) && (((((usqInt) (longAt(functionName))) >> 8) & 15) >= 8);
	foo->successFlag = successValue2 && foo->successFlag;
	/* begin lengthOf: */
	header2 = longAt(functionName);
	/* begin lengthOf:baseHeader:format: */
	if ((header2 & TypeMask) == HeaderTypeSizeAndClass) {
		sz2 = (longAt(functionName - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz2 = header2 & SizeMask;
	}
	sz2 -= header2 & Size4Bit;
	if (((((usqInt) header2) >> 8) & 15) <= 4) {
		functionLength = ((usqInt) (sz2 - BaseHeaderSize)) >> ShiftForWord;
		goto l5;
	}
	if (((((usqInt) header2) >> 8) & 15) < 8) {
		functionLength = ((usqInt) (sz2 - BaseHeaderSize)) >> 2;
		goto l5;
	} else {
		functionLength = (sz2 - BaseHeaderSize) - (((((usqInt) header2) >> 8) & 15) & 3);
		goto l5;
	}
	functionLength = null;
l5:	/* end lengthOf: */;
	if (!(foo->successFlag)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	addr = ioLoadExternalFunctionOfLengthFromModuleOfLength(functionName + BaseHeaderSize, functionLength, moduleName + BaseHeaderSize, moduleLength);
	if (addr == 0) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin pop: */
	foo->stackPointer -= 1 * BytesPerWord;
	foo->argumentCount = arraySize;
	index = 1;
	while (index <= arraySize) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, longAt((argumentArray + BaseHeaderSize) + ((index - 1) << ShiftForWord)));
		foo->stackPointer = sp;
		index += 1;
	}
	/* begin pushRemappableOop: */
	foo->remapBuffer[foo->remapBufferCount += 1] = argumentArray;
	foo->lkupClass = foo->nilObj;
	callExternalPrimitive(addr);
	/* begin popRemappableOop */
	oop2 = foo->remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	argumentArray = oop2;
	if (!(foo->successFlag)) {
		/* begin pop:thenPush: */
		longAtput(sp1 = foo->stackPointer - ((arraySize - 1) * BytesPerWord), argumentArray);
		foo->stackPointer = sp1;
		foo->argumentCount = 3;
	}
}

sqInt primitiveDoPrimitiveWithArgs(void) {
register struct foo * foo = &fum;
    sqInt cntxSize;
    sqInt primIdx;
    sqInt arraySize;
    sqInt argumentArray;
    sqInt index;
    sqInt sp;
    sqInt sp1;
    sqInt sp2;
    sqInt sz;
    sqInt objectPointer;
    sqInt sz1;
    sqInt integerPointer;
    sqInt oop;
    sqInt header;
    sqInt header1;

	argumentArray = longAt(foo->stackPointer);
	/* begin fetchWordLengthOf: */
	/* begin sizeBitsOf: */
	header = longAt(argumentArray);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(argumentArray - (BytesPerWord * 2))) & LongSizeMask;
		goto l2;
	} else {
		sz = header & SizeMask;
		goto l2;
	}
l2:	/* end sizeBitsOf: */;
	arraySize = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
	/* begin fetchWordLengthOf: */
	objectPointer = foo->activeContext;
	/* begin sizeBitsOf: */
	header1 = longAt(objectPointer);
	if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(objectPointer - (BytesPerWord * 2))) & LongSizeMask;
		goto l3;
	} else {
		sz1 = header1 & SizeMask;
		goto l3;
	}
l3:	/* end sizeBitsOf: */;
	cntxSize = ((usqInt) (sz1 - BaseHeaderSize)) >> ShiftForWord;
	/* begin success: */
	foo->successFlag = (((((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) + arraySize) < cntxSize) && foo->successFlag;
	if (!(((argumentArray & 1) == 0) && (((((usqInt) (longAt(argumentArray))) >> 8) & 15) == 2))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		primIdx = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		primIdx = 0;
		goto l1;
	}
	primIdx = null;
l1:	/* end stackIntegerValue: */;
	if (!(foo->successFlag)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin pop: */
	foo->stackPointer -= 2 * BytesPerWord;
	foo->primitiveIndex = primIdx;
	foo->argumentCount = arraySize;
	index = 1;
	while (index <= foo->argumentCount) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, longAt((argumentArray + BaseHeaderSize) + ((index - 1) << ShiftForWord)));
		foo->stackPointer = sp;
		index += 1;
	}
	/* begin pushRemappableOop: */
	foo->remapBuffer[foo->remapBufferCount += 1] = argumentArray;
	foo->lkupClass = foo->nilObj;
	primitiveResponse();
	/* begin popRemappableOop */
	oop = foo->remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	argumentArray = oop;
	if (!(foo->successFlag)) {
		/* begin pop: */
		foo->stackPointer -= arraySize * BytesPerWord;
		/* begin pushInteger: */
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + BytesPerWord, ((primIdx << 1) | 1));
		foo->stackPointer = sp1;
		/* begin push: */
		longAtput(sp2 = foo->stackPointer + BytesPerWord, argumentArray);
		foo->stackPointer = sp2;
		foo->argumentCount = 2;
	}
}

sqInt primitiveEqual(void) {
register struct foo * foo = &fum;
    sqInt integerArgument;
    sqInt result;
    sqInt integerReceiver;
    sqInt top;
    sqInt top1;
    sqInt sp;
    sqInt sp1;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerArgument = top;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerReceiver = top1;
	/* begin compare31or32Bits:equal: */
	if (((integerReceiver & 1)) && ((integerArgument & 1))) {
		result = integerReceiver == integerArgument;
		goto l1;
	}
	result = (positive32BitValueOf(integerReceiver)) == (positive32BitValueOf(integerArgument));
l1:	/* end compare31or32Bits:equal: */;
	/* begin checkBooleanResult: */
	if (foo->successFlag) {
		/* begin pushBool: */
		if (result) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}


/*	is the receiver the same object as the argument? */

sqInt primitiveEquivalent(void) {
register struct foo * foo = &fum;
    sqInt otherObject;
    sqInt thisObject;
    sqInt top;
    sqInt top1;
    sqInt sp;
    sqInt sp1;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	otherObject = top;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	thisObject = top1;
	/* begin pushBool: */
	if (thisObject == otherObject) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
		foo->stackPointer = sp;
	} else {
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
		foo->stackPointer = sp1;
	}
}


/*	receiver, args, then method are on top of stack. Execute method against receiver and args */

sqInt primitiveExecuteMethod(void) {
register struct foo * foo = &fum;
    sqInt top;
    sqInt successValue;
    sqInt primBits;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	foo->newMethod = top;
	/* begin primitiveIndexOf: */
	primBits = (((usqInt) (longAt((foo->newMethod + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 1) & 268435967;
	foo->primitiveIndex = (primBits & 511) + (((usqInt) primBits) >> 19);
	/* begin success: */
	successValue = (foo->argumentCount - 1) == ((((usqInt) (longAt((foo->newMethod + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 25) & 15);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		foo->argumentCount -= 1;
		/* begin executeNewMethod */
		if (foo->primitiveIndex > 0) {
			primitiveResponse();
			if (foo->successFlag) {
				goto l1;
			}
		}
		activateNewMethod();
		/* begin quickCheckForInterrupts */
		if ((foo->interruptCheckCounter -= 1) <= 0) {
			checkForInterrupts();
		}
	l1:	/* end executeNewMethod */;
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
	}
}


/*	receiver, argsArray, then method are on top of stack.  Execute method against receiver and args */

sqInt primitiveExecuteMethodArgsArray(void) {
register struct foo * foo = &fum;
    sqInt argCnt;
    sqInt argumentArray;
    sqInt methodArgument;
    sqInt top;
    sqInt top1;
    sqInt dst;
    sqInt out;
    sqInt lastIn;
    sqInt in;
    sqInt primBits;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	methodArgument = top;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	argumentArray = top1;
	if (!(((methodArgument & 1) == 0) && ((((((usqInt) (longAt(foo->newMethod))) >> 8) & 15) >= 12) && (((argumentArray & 1) == 0) && (((((usqInt) (longAt(argumentArray))) >> 8) & 15) == 2))))) {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	argCnt = (((usqInt) (longAt((methodArgument + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 25) & 15;
	if (!(argCnt == (fetchWordLengthOf(argumentArray)))) {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin transfer:from:to: */
	dst = foo->stackPointer + BytesPerWord;
	flag("Dan");
	in = (argumentArray + BaseHeaderSize) - BytesPerWord;
	lastIn = in + (argCnt * BytesPerWord);
	out = dst - BytesPerWord;
	while ((((usqInt) in)) < (((usqInt) lastIn))) {
		longAtput(out += BytesPerWord, longAt(in += BytesPerWord));
	}
	/* begin unPop: */
	foo->stackPointer += argCnt * BytesPerWord;
	foo->newMethod = methodArgument;
	/* begin primitiveIndexOf: */
	primBits = (((usqInt) (longAt((foo->newMethod + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 1) & 268435967;
	foo->primitiveIndex = (primBits & 511) + (((usqInt) primBits) >> 19);
	foo->argumentCount = argCnt;
	/* begin executeNewMethod */
	if (foo->primitiveIndex > 0) {
		primitiveResponse();
		if (foo->successFlag) {
			goto l1;
		}
	}
	activateNewMethod();
	/* begin quickCheckForInterrupts */
	if ((foo->interruptCheckCounter -= 1) <= 0) {
		checkForInterrupts();
	}
l1:	/* end executeNewMethod */;
	foo->successFlag = 1;
}

sqInt primitiveExitToDebugger(void) {
	error("Exit to debugger at user request");
}


/*	Computes E raised to the receiver power. */

sqInt primitiveExp(void) {
register struct foo * foo = &fum;
    double  rcvr;

	rcvr = popFloat();
	if (foo->successFlag) {
		pushFloat(exp(rcvr));
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
	}
}


/*	Exponent part of this float. */

sqInt primitiveExponent(void) {
register struct foo * foo = &fum;
    double  rcvr;
    double  frac;
    int  pwr;
    sqInt sp;

	rcvr = popFloat();
	if (foo->successFlag) {
		frac = frexp(rcvr, &pwr);
		/* begin pushInteger: */
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, (((pwr - 1) << 1) | 1));
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
	}
}


/*	Call an external primitive. The external primitive methods 
	contain as first literal an array consisting of: 
	* The module name (String | Symbol) 
	* The function name (String | Symbol) 
	* The session ID (SmallInteger) [OBSOLETE] 
	* The function index (Integer) in the externalPrimitiveTable 
	For fast failures the primitive index of any method where the 
	external prim is not found is rewritten in the method cache 
	with zero. This allows for ultra fast responses as long as the 
	method stays in the cache. 
	The fast failure response relies on lkupClass being properly 
	set. This is done in 
	#addToMethodCacheSel:class:method:primIndex: to 
	compensate for execution of methods that are looked up in a 
	superclass (such as in primitivePerformAt). 
	With the latest modifications (e.g., actually flushing the 
	function addresses from the VM), the session ID is obsolete. 
	But for backward compatibility it is still kept around. Also, a 
	failed lookup is reported specially. If a method has been 
	looked up and not been found, the function address is stored 
	as -1 (e.g., the SmallInteger -1 to distinguish from 
	16rFFFFFFFF which may be returned from the lookup). 
	It is absolutely okay to remove the rewrite if we run into any 
	problems later on. It has an approximate speed difference of 
	30% per failed primitive call which may be noticable but if, 
	for any reasons, we run into problems (like with J3) we can 
	always remove the rewrite. 
	 */

sqInt primitiveExternalCall(void) {
register struct foo * foo = &fum;
    sqInt functionLength;
    void * addr;
    sqInt moduleLength;
    sqInt moduleName;
    sqInt functionName;
    sqInt index;
    sqInt lit;
    sqInt successValue;
    sqInt header;
    sqInt sz;
    sqInt successValue1;
    sqInt successValue2;
    sqInt header1;
    sqInt sz1;

	/* begin success: */
	foo->successFlag = (((((usqInt) (longAt((foo->newMethod + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 10) & 255) > 0) && foo->successFlag;
	if (!(foo->successFlag)) {
		return null;
	}

	/* Check if it's an array of length 4 */

	lit = longAt((foo->newMethod + BaseHeaderSize) + ((0 + LiteralStart) << ShiftForWord));
	/* begin success: */
	successValue1 = (((lit & 1) == 0) && (((((usqInt) (longAt(lit))) >> 8) & 15) == 2)) && ((lengthOf(lit)) == 4);
	foo->successFlag = successValue1 && foo->successFlag;
	if (!(foo->successFlag)) {
		return null;
	}
	index = longAt((lit + BaseHeaderSize) + (3 << ShiftForWord));
	/* begin checkedIntegerValueOf: */
	if ((index & 1)) {
		index = (index >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l2;
	}
l2:	/* end checkedIntegerValueOf: */;
	if (!(foo->successFlag)) {
		return null;
	}
	if (index < 0) {
		rewriteMethodCacheSelclassprimIndex(foo->messageSelector, foo->lkupClass, 0);
		/* begin success: */
		foo->successFlag = 0 && foo->successFlag;
		return null;
	}
	if ((index > 0) && (index <= MaxExternalPrimitiveTableSize)) {
		addr = foo->externalPrimitiveTable[index - 1];
		if (addr != 0) {
			rewriteMethodCacheSelclassprimIndexprimFunction(foo->messageSelector, foo->lkupClass, 1000 + index, addr);
			callExternalPrimitive(addr);
			return null;
		}
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	longAtput((lit + BaseHeaderSize) + (2 << ShiftForWord), ConstZero);
	longAtput((lit + BaseHeaderSize) + (3 << ShiftForWord), ConstZero);
	moduleName = longAt((lit + BaseHeaderSize) + (0 << ShiftForWord));
	if (moduleName == foo->nilObj) {
		moduleLength = 0;
	} else {
		/* begin success: */
		successValue = ((moduleName & 1) == 0) && (((((usqInt) (longAt(moduleName))) >> 8) & 15) >= 8);
		foo->successFlag = successValue && foo->successFlag;
		/* begin lengthOf: */
		header = longAt(moduleName);
		/* begin lengthOf:baseHeader:format: */
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(moduleName - (BytesPerWord * 2))) & LongSizeMask;
		} else {
			sz = header & SizeMask;
		}
		sz -= header & Size4Bit;
		if (((((usqInt) header) >> 8) & 15) <= 4) {
			moduleLength = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
			goto l1;
		}
		if (((((usqInt) header) >> 8) & 15) < 8) {
			moduleLength = ((usqInt) (sz - BaseHeaderSize)) >> 2;
			goto l1;
		} else {
			moduleLength = (sz - BaseHeaderSize) - (((((usqInt) header) >> 8) & 15) & 3);
			goto l1;
		}
		moduleLength = null;
	l1:	/* end lengthOf: */;
		;
	}
	functionName = longAt((lit + BaseHeaderSize) + (1 << ShiftForWord));
	/* begin success: */
	successValue2 = ((functionName & 1) == 0) && (((((usqInt) (longAt(functionName))) >> 8) & 15) >= 8);
	foo->successFlag = successValue2 && foo->successFlag;
	/* begin lengthOf: */
	header1 = longAt(functionName);
	/* begin lengthOf:baseHeader:format: */
	if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(functionName - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz1 = header1 & SizeMask;
	}
	sz1 -= header1 & Size4Bit;
	if (((((usqInt) header1) >> 8) & 15) <= 4) {
		functionLength = ((usqInt) (sz1 - BaseHeaderSize)) >> ShiftForWord;
		goto l3;
	}
	if (((((usqInt) header1) >> 8) & 15) < 8) {
		functionLength = ((usqInt) (sz1 - BaseHeaderSize)) >> 2;
		goto l3;
	} else {
		functionLength = (sz1 - BaseHeaderSize) - (((((usqInt) header1) >> 8) & 15) & 3);
		goto l3;
	}
	functionLength = null;
l3:	/* end lengthOf: */;
	if (!(foo->successFlag)) {
		return null;
	}

	/* Addr ~= 0 indicates we have a compat match later */

	addr = 0;
	if (moduleLength == 0) {

		/* The returned value is the index into the obsolete primitive table. 
			If the index is found, use the 'C-style' version of the lookup.  */

		index = findObsoleteNamedPrimitivelength((pointerForOop(functionName)) + BaseHeaderSize, functionLength);
		if (!(index < 0)) {
			addr = ioLoadFunctionFrom(((char*) ((obsoleteNamedPrimitiveTable[index])[2])), ((char*) ((obsoleteNamedPrimitiveTable[index])[1])));
		}
	}
	if (addr == 0) {
		addr = ioLoadExternalFunctionOfLengthFromModuleOfLength(functionName + BaseHeaderSize, functionLength, moduleName + BaseHeaderSize, moduleLength);
	}
	if (addr == 0) {
		index = -1;
	} else {
		index = addToExternalPrimitiveTable(addr);
	}
	/* begin success: */
	foo->successFlag = (index >= 0) && foo->successFlag;
	longAtput((lit + BaseHeaderSize) + (3 << ShiftForWord), ((index << 1) | 1));
	if (foo->successFlag && (addr != 0)) {
		rewriteMethodCacheSelclassprimIndexprimFunction(foo->messageSelector, foo->lkupClass, 1000 + index, addr);
		callExternalPrimitive(addr);
	} else {
		rewriteMethodCacheSelclassprimIndex(foo->messageSelector, foo->lkupClass, 0);
	}
}

sqInt primitiveFail(void) {
	foo->successFlag = 0;
}


/*	Primitive. Search up the context stack for the next method context marked for exception handling starting at the receiver. Return nil if none found */

sqInt primitiveFindHandlerContext(void) {
register struct foo * foo = &fum;
    sqInt thisCntx;
    sqInt nilOop;
    sqInt sp;
    sqInt top;
    sqInt sp1;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	thisCntx = top;
	nilOop = foo->nilObj;
	do {
		if (isHandlerMarked(thisCntx)) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, thisCntx);
			foo->stackPointer = sp;
			return null;
		}
		thisCntx = longAt((thisCntx + BaseHeaderSize) + (SenderIndex << ShiftForWord));
	} while(!(thisCntx == nilOop));
	/* begin push: */
	longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->nilObj);
	foo->stackPointer = sp1;
	return null;
}


/*	Primitive. Search up the context stack for the next method context marked for unwind handling from the receiver up to but not including the argument. Return nil if none found. */

sqInt primitiveFindNextUnwindContext(void) {
register struct foo * foo = &fum;
    sqInt aContext;
    sqInt unwindMarked;
    sqInt thisCntx;
    sqInt nilOop;
    sqInt sp;
    sqInt top;
    sqInt oop;
    sqInt sp1;
    sqInt meth;
    sqInt pIndex;
    sqInt header;
    sqInt top1;
    sqInt primBits;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	aContext = top;
	/* begin fetchPointer:ofObject: */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	oop = top1;
	thisCntx = longAt((oop + BaseHeaderSize) + (SenderIndex << ShiftForWord));
	nilOop = foo->nilObj;
	while (!((thisCntx == aContext) || (thisCntx == nilOop))) {
		/* begin isUnwindMarked: */
		header = longAt(thisCntx);
		if (!(((((usqInt) header) >> 12) & 31) == 14)) {
			unwindMarked = 0;
			goto l1;
		}
		meth = longAt((thisCntx + BaseHeaderSize) + (MethodIndex << ShiftForWord));
		/* begin primitiveIndexOf: */
		primBits = (((usqInt) (longAt((meth + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 1) & 268435967;
		pIndex = (primBits & 511) + (((usqInt) primBits) >> 19);
		unwindMarked = pIndex == 198;
	l1:	/* end isUnwindMarked: */;
		if (unwindMarked) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, thisCntx);
			foo->stackPointer = sp;
			return null;
		}
		thisCntx = longAt((thisCntx + BaseHeaderSize) + (SenderIndex << ShiftForWord));
	}
	/* begin push: */
	longAtput(sp1 = foo->stackPointer + BytesPerWord, nilOop);
	foo->stackPointer = sp1;
	return null;
}

sqInt primitiveFloatAdd(void) {
register struct foo * foo = &fum;
	return primitiveFloatAddtoArg(longAt(foo->stackPointer - (1 * BytesPerWord)), longAt(foo->stackPointer));
}

sqInt primitiveFloatAddtoArg(sqInt rcvrOop, sqInt argOop) {
register struct foo * foo = &fum;
    double rcvr;
    double arg;

	/* begin loadFloatOrIntFrom: */
	if ((rcvrOop & 1)) {
		rcvr = ((double) ((rcvrOop >> 1)) );
		goto l1;
	}
	if ((fetchClassOfNonInt(rcvrOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		rcvr = floatValueOf(rcvrOop);
		goto l1;
	}
	foo->successFlag = 0;
l1:	/* end loadFloatOrIntFrom: */;
	/* begin loadFloatOrIntFrom: */
	if ((argOop & 1)) {
		arg = ((double) ((argOop >> 1)) );
		goto l2;
	}
	if ((fetchClassOfNonInt(argOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		arg = floatValueOf(argOop);
		goto l2;
	}
	foo->successFlag = 0;
l2:	/* end loadFloatOrIntFrom: */;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
		pushFloat(rcvr + arg);
	}
}

sqInt primitiveFloatDivide(void) {
register struct foo * foo = &fum;
	return primitiveFloatDividebyArg(longAt(foo->stackPointer - (1 * BytesPerWord)), longAt(foo->stackPointer));
}

sqInt primitiveFloatDividebyArg(sqInt rcvrOop, sqInt argOop) {
register struct foo * foo = &fum;
    double rcvr;
    double arg;

	/* begin loadFloatOrIntFrom: */
	if ((rcvrOop & 1)) {
		rcvr = ((double) ((rcvrOop >> 1)) );
		goto l1;
	}
	if ((fetchClassOfNonInt(rcvrOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		rcvr = floatValueOf(rcvrOop);
		goto l1;
	}
	foo->successFlag = 0;
l1:	/* end loadFloatOrIntFrom: */;
	/* begin loadFloatOrIntFrom: */
	if ((argOop & 1)) {
		arg = ((double) ((argOop >> 1)) );
		goto l2;
	}
	if ((fetchClassOfNonInt(argOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		arg = floatValueOf(argOop);
		goto l2;
	}
	foo->successFlag = 0;
l2:	/* end loadFloatOrIntFrom: */;
	if (foo->successFlag) {
		/* begin success: */
		foo->successFlag = (arg != 0.0) && foo->successFlag;
		if (foo->successFlag) {
			/* begin pop: */
			foo->stackPointer -= 2 * BytesPerWord;
			pushFloat(rcvr / arg);
		}
	}
}

sqInt primitiveFloatEqual(void) {
register struct foo * foo = &fum;
    sqInt aBool;
    sqInt sp;
    sqInt sp1;

	aBool = primitiveFloatEqualtoArg(longAt(foo->stackPointer - (1 * BytesPerWord)), longAt(foo->stackPointer));
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
		/* begin pushBool: */
		if (aBool) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

sqInt primitiveFloatEqualtoArg(sqInt rcvrOop, sqInt argOop) {
register struct foo * foo = &fum;
    double rcvr;
    double arg;

	/* begin loadFloatOrIntFrom: */
	if ((rcvrOop & 1)) {
		rcvr = ((double) ((rcvrOop >> 1)) );
		goto l1;
	}
	if ((fetchClassOfNonInt(rcvrOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		rcvr = floatValueOf(rcvrOop);
		goto l1;
	}
	foo->successFlag = 0;
l1:	/* end loadFloatOrIntFrom: */;
	/* begin loadFloatOrIntFrom: */
	if ((argOop & 1)) {
		arg = ((double) ((argOop >> 1)) );
		goto l2;
	}
	if ((fetchClassOfNonInt(argOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		arg = floatValueOf(argOop);
		goto l2;
	}
	foo->successFlag = 0;
l2:	/* end loadFloatOrIntFrom: */;
	if (foo->successFlag) {
		return rcvr == arg;
	}
}

sqInt primitiveFloatGreaterthanArg(sqInt rcvrOop, sqInt argOop) {
register struct foo * foo = &fum;
    double rcvr;
    double arg;

	/* begin loadFloatOrIntFrom: */
	if ((rcvrOop & 1)) {
		rcvr = ((double) ((rcvrOop >> 1)) );
		goto l1;
	}
	if ((fetchClassOfNonInt(rcvrOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		rcvr = floatValueOf(rcvrOop);
		goto l1;
	}
	foo->successFlag = 0;
l1:	/* end loadFloatOrIntFrom: */;
	/* begin loadFloatOrIntFrom: */
	if ((argOop & 1)) {
		arg = ((double) ((argOop >> 1)) );
		goto l2;
	}
	if ((fetchClassOfNonInt(argOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		arg = floatValueOf(argOop);
		goto l2;
	}
	foo->successFlag = 0;
l2:	/* end loadFloatOrIntFrom: */;
	if (foo->successFlag) {
		return rcvr > arg;
	}
}

sqInt primitiveFloatGreaterOrEqual(void) {
register struct foo * foo = &fum;
    sqInt aBool;
    sqInt sp;
    sqInt sp1;

	aBool = primitiveFloatGreaterOrEqualtoArg(longAt(foo->stackPointer - (1 * BytesPerWord)), longAt(foo->stackPointer));
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
		/* begin pushBool: */
		if (aBool) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

sqInt primitiveFloatGreaterOrEqualtoArg(sqInt rcvrOop, sqInt argOop) {
register struct foo * foo = &fum;
    double rcvr;
    double arg;

	/* begin loadFloatOrIntFrom: */
	if ((rcvrOop & 1)) {
		rcvr = ((double) ((rcvrOop >> 1)) );
		goto l1;
	}
	if ((fetchClassOfNonInt(rcvrOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		rcvr = floatValueOf(rcvrOop);
		goto l1;
	}
	foo->successFlag = 0;
l1:	/* end loadFloatOrIntFrom: */;
	/* begin loadFloatOrIntFrom: */
	if ((argOop & 1)) {
		arg = ((double) ((argOop >> 1)) );
		goto l2;
	}
	if ((fetchClassOfNonInt(argOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		arg = floatValueOf(argOop);
		goto l2;
	}
	foo->successFlag = 0;
l2:	/* end loadFloatOrIntFrom: */;
	if (foo->successFlag) {
		return rcvr >= arg;
	}
}

sqInt primitiveFloatGreaterThan(void) {
register struct foo * foo = &fum;
    sqInt aBool;
    sqInt sp;
    sqInt sp1;

	aBool = primitiveFloatGreaterthanArg(longAt(foo->stackPointer - (1 * BytesPerWord)), longAt(foo->stackPointer));
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
		/* begin pushBool: */
		if (aBool) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

sqInt primitiveFloatLessthanArg(sqInt rcvrOop, sqInt argOop) {
register struct foo * foo = &fum;
    double rcvr;
    double arg;

	/* begin loadFloatOrIntFrom: */
	if ((rcvrOop & 1)) {
		rcvr = ((double) ((rcvrOop >> 1)) );
		goto l1;
	}
	if ((fetchClassOfNonInt(rcvrOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		rcvr = floatValueOf(rcvrOop);
		goto l1;
	}
	foo->successFlag = 0;
l1:	/* end loadFloatOrIntFrom: */;
	/* begin loadFloatOrIntFrom: */
	if ((argOop & 1)) {
		arg = ((double) ((argOop >> 1)) );
		goto l2;
	}
	if ((fetchClassOfNonInt(argOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		arg = floatValueOf(argOop);
		goto l2;
	}
	foo->successFlag = 0;
l2:	/* end loadFloatOrIntFrom: */;
	if (foo->successFlag) {
		return rcvr < arg;
	}
}

sqInt primitiveFloatLessOrEqual(void) {
register struct foo * foo = &fum;
    sqInt aBool;
    sqInt sp;
    sqInt sp1;

	aBool = primitiveFloatLessOrEqualtoArg(longAt(foo->stackPointer - (1 * BytesPerWord)), longAt(foo->stackPointer));
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
		/* begin pushBool: */
		if (aBool) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

sqInt primitiveFloatLessOrEqualtoArg(sqInt rcvrOop, sqInt argOop) {
register struct foo * foo = &fum;
    double rcvr;
    double arg;

	/* begin loadFloatOrIntFrom: */
	if ((rcvrOop & 1)) {
		rcvr = ((double) ((rcvrOop >> 1)) );
		goto l1;
	}
	if ((fetchClassOfNonInt(rcvrOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		rcvr = floatValueOf(rcvrOop);
		goto l1;
	}
	foo->successFlag = 0;
l1:	/* end loadFloatOrIntFrom: */;
	/* begin loadFloatOrIntFrom: */
	if ((argOop & 1)) {
		arg = ((double) ((argOop >> 1)) );
		goto l2;
	}
	if ((fetchClassOfNonInt(argOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		arg = floatValueOf(argOop);
		goto l2;
	}
	foo->successFlag = 0;
l2:	/* end loadFloatOrIntFrom: */;
	if (foo->successFlag) {
		return rcvr <= arg;
	}
}

sqInt primitiveFloatLessThan(void) {
register struct foo * foo = &fum;
    sqInt aBool;
    sqInt sp;
    sqInt sp1;

	aBool = primitiveFloatLessthanArg(longAt(foo->stackPointer - (1 * BytesPerWord)), longAt(foo->stackPointer));
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
		/* begin pushBool: */
		if (aBool) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

sqInt primitiveFloatMultiply(void) {
register struct foo * foo = &fum;
	return primitiveFloatMultiplybyArg(longAt(foo->stackPointer - (1 * BytesPerWord)), longAt(foo->stackPointer));
}

sqInt primitiveFloatMultiplybyArg(sqInt rcvrOop, sqInt argOop) {
register struct foo * foo = &fum;
    double rcvr;
    double arg;

	/* begin loadFloatOrIntFrom: */
	if ((rcvrOop & 1)) {
		rcvr = ((double) ((rcvrOop >> 1)) );
		goto l1;
	}
	if ((fetchClassOfNonInt(rcvrOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		rcvr = floatValueOf(rcvrOop);
		goto l1;
	}
	foo->successFlag = 0;
l1:	/* end loadFloatOrIntFrom: */;
	/* begin loadFloatOrIntFrom: */
	if ((argOop & 1)) {
		arg = ((double) ((argOop >> 1)) );
		goto l2;
	}
	if ((fetchClassOfNonInt(argOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		arg = floatValueOf(argOop);
		goto l2;
	}
	foo->successFlag = 0;
l2:	/* end loadFloatOrIntFrom: */;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
		pushFloat(rcvr * arg);
	}
}

sqInt primitiveFloatNotEqual(void) {
register struct foo * foo = &fum;
    sqInt aBool;
    sqInt sp;
    sqInt sp1;

	aBool = primitiveFloatEqualtoArg(longAt(foo->stackPointer - (1 * BytesPerWord)), longAt(foo->stackPointer));
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
		/* begin pushBool: */
		if (!aBool) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

sqInt primitiveFloatSubtract(void) {
register struct foo * foo = &fum;
	return primitiveFloatSubtractfromArg(longAt(foo->stackPointer - (1 * BytesPerWord)), longAt(foo->stackPointer));
}

sqInt primitiveFloatSubtractfromArg(sqInt rcvrOop, sqInt argOop) {
register struct foo * foo = &fum;
    double rcvr;
    double arg;

	/* begin loadFloatOrIntFrom: */
	if ((rcvrOop & 1)) {
		rcvr = ((double) ((rcvrOop >> 1)) );
		goto l1;
	}
	if ((fetchClassOfNonInt(rcvrOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		rcvr = floatValueOf(rcvrOop);
		goto l1;
	}
	foo->successFlag = 0;
l1:	/* end loadFloatOrIntFrom: */;
	/* begin loadFloatOrIntFrom: */
	if ((argOop & 1)) {
		arg = ((double) ((argOop >> 1)) );
		goto l2;
	}
	if ((fetchClassOfNonInt(argOop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord)))) {
		arg = floatValueOf(argOop);
		goto l2;
	}
	foo->successFlag = 0;
l2:	/* end loadFloatOrIntFrom: */;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
		pushFloat(rcvr - arg);
	}
}


/*	Clear the method lookup cache. This must be done after every programming change. */

sqInt primitiveFlushCache(void) {
register struct foo * foo = &fum;
    sqInt i;
    sqInt aCompiledMethod;

	/* begin flushMethodCache */
	for (i = 1; i <= MethodCacheSize; i += 1) {
		foo->methodCache[i] = 0;
	}
	for (i = 1; i <= AtCacheTotalSize; i += 1) {
		foo->atCache[i] = 0;
	}
	/* begin compilerFlushCacheHook: */
	aCompiledMethod = null;
	if (foo->compilerInitialized) {
		compilerFlushCache(aCompiledMethod);
	}
}


/*	The receiver is a compiledMethod.  Clear all entries in the method lookup cache that refer to this method, presumably because it has been redefined, overridden or removed. */

sqInt primitiveFlushCacheByMethod(void) {
register struct foo * foo = &fum;
    sqInt oldMethod;
    sqInt probe;
    sqInt i;

	oldMethod = longAt(foo->stackPointer);
	probe = 0;
	for (i = 1; i <= MethodCacheEntries; i += 1) {
		if ((foo->methodCache[probe + MethodCacheMethod]) == oldMethod) {
			foo->methodCache[probe + MethodCacheSelector] = 0;
		}
		probe += MethodCacheEntrySize;
	}
	/* begin compilerFlushCacheHook: */
	if (foo->compilerInitialized) {
		compilerFlushCache(oldMethod);
	}
}


/*	The receiver is a message selector.  Clear all entries in the method lookup cache with this selector, presumably because an associated method has been redefined. */

sqInt primitiveFlushCacheSelective(void) {
register struct foo * foo = &fum;
    sqInt probe;
    sqInt i;
    sqInt selector;

	selector = longAt(foo->stackPointer);
	probe = 0;
	for (i = 1; i <= MethodCacheEntries; i += 1) {
		if ((foo->methodCache[probe + MethodCacheSelector]) == selector) {
			foo->methodCache[probe + MethodCacheSelector] = 0;
		}
		probe += MethodCacheEntrySize;
	}
}


/*	Primitive. Flush all the existing external primitives in the image thus forcing a reload on next invokation. */

sqInt primitiveFlushExternalPrimitives(void) {
	return flushExternalPrimitives();
}


/*	On some platforms, this primitive forces enqueued display updates to be processed immediately. On others, it does nothing. */

sqInt primitiveForceDisplayUpdate(void) {
	ioForceDisplayUpdate();
}


/*	Set force tenure flag to true, this forces a tenure operation on the next incremental GC */

EXPORT(sqInt) primitiveForceTenure(void) {
	foo->forceTenureFlag = 1;
}


/*	On platforms that support it, this primitive prints the receiver, assumed to be a Form, to the default printer. */

sqInt primitiveFormPrint(void) {
register struct foo * foo = &fum;
    sqInt pixelsPerWord;
    sqInt rcvr;
    sqInt w;
    sqInt h;
    sqInt wordsPerLine;
    sqInt landscapeFlag;
    sqInt bitsArraySize;
    double  vScale;
    sqInt ok;
    sqInt bitsArray;
    sqInt depth;
    double  hScale;
    sqInt fmt;
    sqInt sz;
    sqInt header;

	/* begin booleanValueOf: */
	if ((longAt(foo->stackPointer)) == foo->trueObj) {
		landscapeFlag = 1;
		goto l2;
	}
	if ((longAt(foo->stackPointer)) == foo->falseObj) {
		landscapeFlag = 0;
		goto l2;
	}
	foo->successFlag = 0;
	landscapeFlag = null;
l2:	/* end booleanValueOf: */;
	vScale = floatValueOf(longAt(foo->stackPointer - (1 * BytesPerWord)));
	hScale = floatValueOf(longAt(foo->stackPointer - (2 * BytesPerWord)));
	rcvr = longAt(foo->stackPointer - (3 * BytesPerWord));
	if ((rcvr & 1)) {
		/* begin success: */
		foo->successFlag = 0 && foo->successFlag;
	}
	if (foo->successFlag) {
		if (!((((rcvr & 1) == 0) && (((((usqInt) (longAt(rcvr))) >> 8) & 15) <= 4)) && ((lengthOf(rcvr)) >= 4))) {
			/* begin success: */
			foo->successFlag = 0 && foo->successFlag;
		}
	}
	if (foo->successFlag) {
		bitsArray = longAt((rcvr + BaseHeaderSize) + (0 << ShiftForWord));
		w = fetchIntegerofObject(1, rcvr);
		h = fetchIntegerofObject(2, rcvr);
		depth = fetchIntegerofObject(3, rcvr);
		if (!((w > 0) && (h > 0))) {
			/* begin success: */
			foo->successFlag = 0 && foo->successFlag;
		}
		pixelsPerWord = 32 / depth;
		wordsPerLine = (w + (pixelsPerWord - 1)) / pixelsPerWord;
		if ((!((rcvr & 1))) && (((bitsArray & 1) == 0) && (isWordsOrBytesNonInt(bitsArray)))) {
			/* begin byteLengthOf: */
			header = longAt(bitsArray);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(bitsArray - (BytesPerWord * 2))) & AllButTypeMask;
			} else {
				sz = header & SizeMask;
			}
			fmt = (((usqInt) header) >> 8) & 15;
			if (fmt < 8) {
				bitsArraySize = sz - BaseHeaderSize;
				goto l1;
			} else {
				bitsArraySize = (sz - BaseHeaderSize) - (fmt & 3);
				goto l1;
			}
		l1:	/* end byteLengthOf: */;
			/* begin success: */
			foo->successFlag = (bitsArraySize == ((wordsPerLine * h) * 4)) && foo->successFlag;
		} else {
			/* begin success: */
			foo->successFlag = 0 && foo->successFlag;
		}
	}
	if (foo->successFlag) {
		if (BytesPerWord == 8) {
			ok = ioFormPrint(bitsArray + 8, w, h, depth, hScale, vScale, landscapeFlag);
		} else {
			ok = ioFormPrint(bitsArray + 4, w, h, depth, hScale, vScale, landscapeFlag);
		}
		/* begin success: */
		foo->successFlag = ok && foo->successFlag;
	}
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 3 * BytesPerWord;
	}
}

sqInt primitiveFractionalPart(void) {
register struct foo * foo = &fum;
    double  rcvr;
    double  trunc;
    double  frac;

	rcvr = popFloat();
	if (foo->successFlag) {
		frac = modf(rcvr, &trunc);
		pushFloat(frac);
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
	}
}


/*	Do a full garbage collection and return the number of bytes available (including swap space if dynamic memory management is supported). */

sqInt primitiveFullGC(void) {
register struct foo * foo = &fum;
    sqInt integerValue;
    sqInt sp;

	/* begin pop: */
	foo->stackPointer -= 1 * BytesPerWord;
	incrementalGC();
	fullGC();
	/* begin pushInteger: */
	integerValue = ((longAt(foo->freeBlock)) & AllButTypeMask) + (sqMemoryExtraBytesLeft(1));
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, ((integerValue << 1) | 1));
	foo->stackPointer = sp;
}


/*	Fetch the system attribute with the given integer ID. The 
	result is a string, which will be empty if the attribute is not 
	defined. */

sqInt primitiveGetAttribute(void) {
register struct foo * foo = &fum;
    sqInt attr;
    sqInt sz;
    sqInt s;
    sqInt sp;
    sqInt integerPointer;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		attr = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		attr = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	if (foo->successFlag) {
		sz = attributeSize(attr);
	}
	if (foo->successFlag) {
		s = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassString << ShiftForWord)), sz);
		getAttributeIntoLength(attr, s + BaseHeaderSize, sz);
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), s);
		foo->stackPointer = sp;
	}
}


/*	Primitive. Return the next input event from the VM event queue. */

sqInt primitiveGetNextEvent(void) {
register struct foo * foo = &fum;
    sqInt value;
    int evtBuf[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };
    sqInt arg;
    sqInt i;
    sqInt oop;

	;
	arg = longAt(foo->stackPointer);
	if (!((((arg & 1) == 0) && (((((usqInt) (longAt(arg))) >> 8) & 15) == 2)) && ((slotSizeOf(arg)) == 8))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	ioGetNextEvent(((sqInputEvent*) evtBuf));
	if (!(foo->successFlag)) {
		return null;
	}
	/* begin storeInteger:ofObject:withValue: */
	if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
		(((((int) (evtBuf[0]))) ^ ((((int) (evtBuf[0]))) << 1)) >= 0)
# else
		(((evtBuf[0]) >= -1073741824) && ((evtBuf[0]) <= 1073741823))
# endif  // SQ_HOST32
	) {
		longAtput((arg + BaseHeaderSize) + (0 << ShiftForWord), (((evtBuf[0]) << 1) | 1));
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
	}
	if (!(foo->successFlag)) {
		return null;
	}
	/* begin storeInteger:ofObject:withValue: */
	if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
		(((((int) ((evtBuf[1]) & MillisecondClockMask))) ^ ((((int) ((evtBuf[1]) & MillisecondClockMask))) << 1)) >= 0)
# else
		((((evtBuf[1]) & MillisecondClockMask) >= -1073741824) && (((evtBuf[1]) & MillisecondClockMask) <= 1073741823))
# endif  // SQ_HOST32
	) {
		longAtput((arg + BaseHeaderSize) + (1 << ShiftForWord), ((((evtBuf[1]) & MillisecondClockMask) << 1) | 1));
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
	}
	if (!(foo->successFlag)) {
		return null;
	}
	for (i = 2; i <= 7; i += 1) {
		value = evtBuf[i];
		if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
			(((((int) value)) ^ ((((int) value)) << 1)) >= 0)
# else
			((value >= -1073741824) && (value <= 1073741823))
# endif  // SQ_HOST32
		) {
			/* begin storeInteger:ofObject:withValue: */
			if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
				(((((int) value)) ^ ((((int) value)) << 1)) >= 0)
# else
				((value >= -1073741824) && (value <= 1073741823))
# endif  // SQ_HOST32
			) {
				longAtput((arg + BaseHeaderSize) + (i << ShiftForWord), ((value << 1) | 1));
			} else {
				/* begin primitiveFail */
				foo->successFlag = 0;
			}
		} else {
			/* begin pushRemappableOop: */
			foo->remapBuffer[foo->remapBufferCount += 1] = arg;
			value = positive32BitIntegerFor(value);
			/* begin popRemappableOop */
			oop = foo->remapBuffer[foo->remapBufferCount];
			foo->remapBufferCount -= 1;
			arg = oop;
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) arg)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(arg, value);
			}
			longAtput((arg + BaseHeaderSize) + (i << ShiftForWord), value);
		}
	}
	if (!(foo->successFlag)) {
		return null;
	}
	/* begin pop: */
	foo->stackPointer -= 1 * BytesPerWord;
}

sqInt primitiveGreaterOrEqual(void) {
register struct foo * foo = &fum;
    sqInt integerArgument;
    sqInt integerReceiver;
    sqInt integerPointer;
    sqInt integerPointer1;
    sqInt top;
    sqInt top1;
    sqInt sp;
    sqInt sp1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer = top;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		integerArgument = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerArgument = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	/* begin popInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer1 = top1;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer1 & 1)) {
		integerReceiver = (integerPointer1 >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerReceiver = 0;
		goto l2;
	}
l2:	/* end checkedIntegerValueOf: */;
	/* begin checkBooleanResult: */
	if (foo->successFlag) {
		/* begin pushBool: */
		if (integerReceiver >= integerArgument) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}

sqInt primitiveGreaterThan(void) {
register struct foo * foo = &fum;
    sqInt integerArgument;
    sqInt integerReceiver;
    sqInt integerPointer;
    sqInt integerPointer1;
    sqInt top;
    sqInt top1;
    sqInt sp;
    sqInt sp1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer = top;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		integerArgument = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerArgument = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	/* begin popInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer1 = top1;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer1 & 1)) {
		integerReceiver = (integerPointer1 >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerReceiver = 0;
		goto l2;
	}
l2:	/* end checkedIntegerValueOf: */;
	/* begin checkBooleanResult: */
	if (foo->successFlag) {
		/* begin pushBool: */
		if (integerReceiver > integerArgument) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}


/*	Answer an integer identifying the type of image. The image version number may
	identify the format of the image (e.g. 32 or 64-bit word size) or specific requirements
	of the image (e.g. block closure support required).
	
	This is a named (not numbered) primitive in the null module (ie the VM) */

EXPORT(sqInt) primitiveImageFormatVersion(void) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt sp;

	/* begin pop:thenPush: */
	oop = positive32BitIntegerFor(imageFormatVersionNumber);
	longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), oop);
	foo->stackPointer = sp;
}


/*	When called with a single string argument, record the string as the current image file name. When called with zero arguments, return a string containing the current image file name. */

sqInt primitiveImageName(void) {
register struct foo * foo = &fum;
    sqInt okToRename;
    sqInt sz;
    sqInt s;
    void * sCRIfn;
    sqInt sp;
    sqInt ccIndex;
    sqInt cl;

	if (foo->argumentCount == 1) {
		sCRIfn = ioLoadFunctionFrom("secCanRenameImage", "SecurityPlugin");
		if (sCRIfn != 0) {
			okToRename =  ((sqInt (*)(void))sCRIfn)();
			if (!(okToRename)) {
				/* begin primitiveFail */
				foo->successFlag = 0;
				return null;
			}
		}
		s = longAt(foo->stackPointer);
		/* begin assertClassOf:is: */
		if ((s & 1)) {
			foo->successFlag = 0;
			goto l1;
		}
		ccIndex = (((usqInt) (longAt(s))) >> 12) & 31;
		if (ccIndex == 0) {
			cl = (longAt(s - BaseHeaderSize)) & AllButTypeMask;
		} else {
			cl = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		}
		/* begin success: */
		foo->successFlag = (cl == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassString << ShiftForWord)))) && foo->successFlag;
	l1:	/* end assertClassOf:is: */;
		if (foo->successFlag) {
			sz = stSizeOf(s);
			imageNamePutLength(s + BaseHeaderSize, sz);
			/* begin pop: */
			foo->stackPointer -= 1 * BytesPerWord;
		}
	} else {
		sz = imageNameSize();
		s = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassString << ShiftForWord)), sz);
		imageNameGetLength(s + BaseHeaderSize, sz);
		/* begin pop: */
		foo->stackPointer -= 1 * BytesPerWord;
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, s);
		foo->stackPointer = sp;
	}
}


/*	Do a quick, incremental garbage collection and return the number of bytes immediately available. (Note: more space may be made available by doing a full garbage collection. */

sqInt primitiveIncrementalGC(void) {
register struct foo * foo = &fum;
    sqInt integerValue;
    sqInt sp;

	/* begin pop: */
	foo->stackPointer -= 1 * BytesPerWord;
	incrementalGC();
	/* begin pushInteger: */
	integerValue = ((longAt(foo->freeBlock)) & AllButTypeMask) + (sqMemoryExtraBytesLeft(0));
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, ((integerValue << 1) | 1));
	foo->stackPointer = sp;
}


/*	Note: We now have 10 bits of primitive index, but they are in two places
	for temporary backward compatibility.  The time to unpack is negligible,
	since the reconstituted full index is stored in the method cache. */

sqInt primitiveIndexOf(sqInt methodPointer) {
    sqInt primBits;

	primBits = (((usqInt) (longAt((methodPointer + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 1) & 268435967;
	return (primBits & 511) + (((usqInt) primBits) >> 19);
}


/*	Note: We now have 10 bits of primitive index, but they are in two places
	for temporary backward compatibility.  The time to unpack is negligible,
	 since the derived primitive function pointer is stored in the method cache. */

sqInt primitiveIndexOfMethodHeader(sqInt methodHeader) {
    sqInt primBits;

	primBits = ((usqInt) methodHeader) >> 1;
	return (primBits & 511) + ((((usqInt) primBits) >> 19) & 512);
}


/*	Register the input semaphore. The argument is an index into the ExternalObjectsArray part of the specialObjectsArray and must have been allocated via 'Smalltalk registerExternalObject: the Semaphore'  */

sqInt primitiveInputSemaphore(void) {
register struct foo * foo = &fum;
    sqInt arg;

	arg = longAt(foo->stackPointer);
	if ((arg & 1)) {
		ioSetInputSemaphore((arg >> 1));
		if (foo->successFlag) {
			/* begin pop: */
			foo->stackPointer -= 1 * BytesPerWord;
		}
		return null;
	}
}


/*	Return an integer indicating the reason for the most recent input interrupt. */

sqInt primitiveInputWord(void) {
register struct foo * foo = &fum;
    sqInt sp;

	/* begin pop:thenPushInteger: */
	longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), ((0 << 1) | 1));
	foo->stackPointer = sp;
}

sqInt primitiveInstVarAt(void) {
register struct foo * foo = &fum;
    sqInt value;
    sqInt rcvr;
    sqInt fmt;
    sqInt totalLength;
    sqInt hdr;
    sqInt index;
    sqInt fixedFields;
    sqInt sp;
    sqInt integerPointer;
    sqInt sz;
    sqInt class;
    sqInt classFormat;
    sqInt ccIndex;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		index = (integerPointer >> 1);
		goto l4;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l4;
	}
l4:	/* end checkedIntegerValueOf: */;
	rcvr = longAt(foo->stackPointer - (1 * BytesPerWord));
	if (foo->successFlag) {
		hdr = longAt(rcvr);
		fmt = (((usqInt) hdr) >> 8) & 15;
		/* begin lengthOf:baseHeader:format: */
		if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(rcvr - (BytesPerWord * 2))) & LongSizeMask;
		} else {
			sz = hdr & SizeMask;
		}
		sz -= hdr & Size4Bit;
		if (fmt <= 4) {
			totalLength = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
			goto l2;
		}
		if (fmt < 8) {
			totalLength = ((usqInt) (sz - BaseHeaderSize)) >> 2;
			goto l2;
		} else {
			totalLength = (sz - BaseHeaderSize) - (fmt & 3);
			goto l2;
		}
	l2:	/* end lengthOf:baseHeader:format: */;
		/* begin fixedFieldsOf:format:length: */
		if ((fmt > 4) || (fmt == 2)) {
			fixedFields = 0;
			goto l3;
		}
		if (fmt < 2) {
			fixedFields = totalLength;
			goto l3;
		}
		/* begin fetchClassOf: */
		if ((rcvr & 1)) {
			class = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
			goto l5;
		}
		ccIndex = (((usqInt) (longAt(rcvr))) >> 12) & 31;
		if (ccIndex == 0) {
			class = (longAt(rcvr - BaseHeaderSize)) & AllButTypeMask;
			goto l5;
		} else {
			class = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
			goto l5;
		}
	l5:	/* end fetchClassOf: */;
		classFormat = (longAt((class + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1;
		fixedFields = (((((usqInt) classFormat) >> 11) & 192) + ((((usqInt) classFormat) >> 2) & 63)) - 1;
	l3:	/* end fixedFieldsOf:format:length: */;
		if (!((index >= 1) && (index <= fixedFields))) {
			foo->successFlag = 0;
		}
	}
	if (foo->successFlag) {
		/* begin subscript:with:format: */
		if (fmt <= 4) {
			value = longAt((rcvr + BaseHeaderSize) + ((index - 1) << ShiftForWord));
			goto l1;
		}
		if (fmt < 8) {
			value = positive32BitIntegerFor(long32At((rcvr + BaseHeaderSize) + ((index - 1) << 2)));
			goto l1;
		} else {
			value = (((byteAt((rcvr + BaseHeaderSize) + (index - 1))) << 1) | 1);
			goto l1;
		}
	l1:	/* end subscript:with:format: */;
	}
	if (foo->successFlag) {
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * BytesPerWord), value);
		foo->stackPointer = sp;
	}
}

sqInt primitiveInstVarAtPut(void) {
register struct foo * foo = &fum;
    sqInt rcvr;
    sqInt fmt;
    sqInt newValue;
    sqInt totalLength;
    sqInt hdr;
    sqInt index;
    sqInt fixedFields;
    sqInt sp;
    sqInt integerPointer;
    sqInt sz;
    sqInt class;
    sqInt classFormat;
    sqInt valueToStore;
    sqInt ccIndex;

	newValue = longAt(foo->stackPointer);
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		index = (integerPointer >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l2;
	}
l2:	/* end checkedIntegerValueOf: */;
	rcvr = longAt(foo->stackPointer - (2 * BytesPerWord));
	if (foo->successFlag) {
		hdr = longAt(rcvr);
		fmt = (((usqInt) hdr) >> 8) & 15;
		/* begin lengthOf:baseHeader:format: */
		if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(rcvr - (BytesPerWord * 2))) & LongSizeMask;
		} else {
			sz = hdr & SizeMask;
		}
		sz -= hdr & Size4Bit;
		if (fmt <= 4) {
			totalLength = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
			goto l1;
		}
		if (fmt < 8) {
			totalLength = ((usqInt) (sz - BaseHeaderSize)) >> 2;
			goto l1;
		} else {
			totalLength = (sz - BaseHeaderSize) - (fmt & 3);
			goto l1;
		}
	l1:	/* end lengthOf:baseHeader:format: */;
		/* begin fixedFieldsOf:format:length: */
		if ((fmt > 4) || (fmt == 2)) {
			fixedFields = 0;
			goto l3;
		}
		if (fmt < 2) {
			fixedFields = totalLength;
			goto l3;
		}
		/* begin fetchClassOf: */
		if ((rcvr & 1)) {
			class = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
			goto l4;
		}
		ccIndex = (((usqInt) (longAt(rcvr))) >> 12) & 31;
		if (ccIndex == 0) {
			class = (longAt(rcvr - BaseHeaderSize)) & AllButTypeMask;
			goto l4;
		} else {
			class = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
			goto l4;
		}
	l4:	/* end fetchClassOf: */;
		classFormat = (longAt((class + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1;
		fixedFields = (((((usqInt) classFormat) >> 11) & 192) + ((((usqInt) classFormat) >> 2) & 63)) - 1;
	l3:	/* end fixedFieldsOf:format:length: */;
		if (!((index >= 1) && (index <= fixedFields))) {
			foo->successFlag = 0;
		}
	}
	if (foo->successFlag) {
		/* begin subscript:with:storing:format: */
		if (fmt <= 4) {
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(rcvr, newValue);
			}
			longAtput((rcvr + BaseHeaderSize) + ((index - 1) << ShiftForWord), newValue);
		} else {
			if (fmt < 8) {
				valueToStore = positive32BitValueOf(newValue);
				if (foo->successFlag) {
					long32Atput((rcvr + BaseHeaderSize) + ((index - 1) << 2), valueToStore);
				}
			} else {
				if (!((newValue & 1))) {
					foo->successFlag = 0;
				}
				valueToStore = (newValue >> 1);
				if (!((valueToStore >= 0) && (valueToStore <= 255))) {
					foo->successFlag = 0;
				}
				if (foo->successFlag) {
					byteAtput((rcvr + BaseHeaderSize) + (index - 1), valueToStore);
				}
			}
		}
	}
	if (foo->successFlag) {
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * BytesPerWord), newValue);
		foo->stackPointer = sp;
	}
}


/*	Note:  this primitive has been decommissioned.  It is only here for short-term compatibility with an internal 2.3beta-d image that used this.  It did not save much time and it complicated several things.  Plus Jitter will do it right anyway. */

sqInt primitiveInstVarsPutFromStack(void) {
register struct foo * foo = &fum;
    sqInt rcvr;
    sqInt i;
    sqInt offsetBits;


	/* Mark dirty so stores below can be unchecked */

	rcvr = longAt(foo->stackPointer - (foo->argumentCount * BytesPerWord));
	if ((((usqInt) rcvr)) < (((usqInt) foo->youngStart))) {
		beRootIfOld(rcvr);
	}
	for (i = 0; i <= (foo->argumentCount - 1); i += 1) {
		if ((i & 3) == 0) {
			offsetBits = positive32BitValueOf(longAt((foo->newMethod + BaseHeaderSize) + (((((sqInt) i >> 2)) + LiteralStart) << ShiftForWord)));
		}
		longAtput((rcvr + BaseHeaderSize) + ((offsetBits & 255) << ShiftForWord), longAt(foo->stackPointer - (i * BytesPerWord)));
		offsetBits = ((usqInt) offsetBits) >> 8;
	}
	/* begin pop: */
	foo->stackPointer -= foo->argumentCount * BytesPerWord;
}


/*	Return the 32bit signed integer contents of a words receiver */

sqInt primitiveIntegerAt(void) {
register struct foo * foo = &fum;
    sqInt value;
    sqInt rcvr;
    sqInt addr;
    sqInt sz;
    int intValue;
    sqInt index;
    sqInt sp;
    sqInt object;
    sqInt sp1;
    sqInt integerPointer;
    sqInt header;
    sqInt sz1;
    sqInt successValue;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		index = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l1;
	}
	index = null;
l1:	/* end stackIntegerValue: */;
	rcvr = longAt(foo->stackPointer - (1 * BytesPerWord));
	if ((rcvr & 1)) {
		/* begin success: */
		foo->successFlag = 0 && foo->successFlag;
		return null;
	}
	if (!(((rcvr & 1) == 0) && (((((usqInt) (longAt(rcvr))) >> 8) & 15) == 6))) {
		/* begin success: */
		foo->successFlag = 0 && foo->successFlag;
		return null;
	}
	/* begin lengthOf: */
	header = longAt(rcvr);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(rcvr - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz1 = header & SizeMask;
	}
	sz1 -= header & Size4Bit;
	if (((((usqInt) header) >> 8) & 15) <= 4) {
		sz = ((usqInt) (sz1 - BaseHeaderSize)) >> ShiftForWord;
		goto l2;
	}
	if (((((usqInt) header) >> 8) & 15) < 8) {
		sz = ((usqInt) (sz1 - BaseHeaderSize)) >> 2;
		goto l2;
	} else {
		sz = (sz1 - BaseHeaderSize) - (((((usqInt) header) >> 8) & 15) & 3);
		goto l2;
	}
	sz = null;
l2:	/* end lengthOf: */;
	/* begin success: */
	successValue = (index >= 1) && (index <= sz);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {

		/* for zero indexing */

		addr = ((rcvr + BaseHeaderSize) - 4) + (index * 4);
		value = intAt(addr);
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
		if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
			(((((int) value)) ^ ((((int) value)) << 1)) >= 0)
# else
			((value >= -1073741824) && (value <= 1073741823))
# endif  // SQ_HOST32
		) {
			/* begin pushInteger: */
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, ((value << 1) | 1));
			foo->stackPointer = sp;
		} else {

			/* 32 bit int may have been stored in 32 or 64 bit sqInt */

			intValue = value;
			/* begin push: */
			object = signed32BitIntegerFor(intValue);
			longAtput(sp1 = foo->stackPointer + BytesPerWord, object);
			foo->stackPointer = sp1;
		}
	}
}


/*	Return the 32bit signed integer contents of a words receiver */

sqInt primitiveIntegerAtPut(void) {
register struct foo * foo = &fum;
    sqInt value;
    sqInt rcvr;
    sqInt addr;
    sqInt valueOop;
    sqInt sz;
    sqInt index;
    sqInt sp;
    sqInt integerPointer;
    sqInt header;
    sqInt sz1;

	valueOop = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		index = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l1;
	}
	index = null;
l1:	/* end stackIntegerValue: */;
	rcvr = longAt(foo->stackPointer - (2 * BytesPerWord));
	if ((rcvr & 1)) {
		/* begin success: */
		foo->successFlag = 0 && foo->successFlag;
		return null;
	}
	if (!(((rcvr & 1) == 0) && (((((usqInt) (longAt(rcvr))) >> 8) & 15) == 6))) {
		/* begin success: */
		foo->successFlag = 0 && foo->successFlag;
		return null;
	}
	/* begin lengthOf: */
	header = longAt(rcvr);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(rcvr - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz1 = header & SizeMask;
	}
	sz1 -= header & Size4Bit;
	if (((((usqInt) header) >> 8) & 15) <= 4) {
		sz = ((usqInt) (sz1 - BaseHeaderSize)) >> ShiftForWord;
		goto l2;
	}
	if (((((usqInt) header) >> 8) & 15) < 8) {
		sz = ((usqInt) (sz1 - BaseHeaderSize)) >> 2;
		goto l2;
	} else {
		sz = (sz1 - BaseHeaderSize) - (((((usqInt) header) >> 8) & 15) & 3);
		goto l2;
	}
	sz = null;
l2:	/* end lengthOf: */;
	if (!((index >= 1) && (index <= sz))) {
		/* begin success: */
		foo->successFlag = 0 && foo->successFlag;
		return null;
	}
	if ((valueOop & 1)) {
		value = (valueOop >> 1);
	} else {
		value = signed32BitValueOf(valueOop);
	}
	if (foo->successFlag) {

		/* for zero indexing */

		addr = ((rcvr + BaseHeaderSize) - 4) + (index * 4);
		value = intAtput(addr, value);
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((3 - 1) * BytesPerWord), valueOop);
		foo->stackPointer = sp;
	}
}


/*	Answer a string corresponding to the version of the interpreter source. This
	represents the version level of the Smalltalk source code (interpreter and various
	plugins) that is translated to C by a CCodeGenerator, as distinct from the external
	platform source code, typically written in C and managed separately for each platform.
	This is a named (not numbered) primitive in the null module (ie the VM) */

EXPORT(sqInt) primitiveInterpreterSourceVersion(void) {
register struct foo * foo = &fum;
    void * p;
    sqInt versionString;
    sqInt len;
    char * cString;
    sqInt sp;

	cString = InterpreterSourceVersion;
	len = strlen(cString);
	versionString = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassString << ShiftForWord)), len);
	/* begin arrayValueOf: */
	if ((!((versionString & 1))) && (((versionString & 1) == 0) && (isWordsOrBytesNonInt(versionString)))) {
		p = pointerForOop(versionString + BaseHeaderSize);
		goto l1;
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
l1:	/* end arrayValueOf: */;
	strncpy(p, cString, len);
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), versionString);
	foo->stackPointer = sp;
}


/*	Register the user interrupt semaphore. If the argument is 
	not a Semaphore, unregister the current interrupt 
	semaphore.  */

sqInt primitiveInterruptSemaphore(void) {
register struct foo * foo = &fum;
    sqInt arg;
    sqInt oop;
    sqInt oop1;
    sqInt valuePointer;
    sqInt top;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	arg = top;
	if ((fetchClassOf(arg)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassSemaphore << ShiftForWord)))) {
		/* begin storePointer:ofObject:withValue: */
		oop = foo->specialObjectsOop;
		if ((((usqInt) oop)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(oop, arg);
		}
		longAtput((oop + BaseHeaderSize) + (TheInterruptSemaphore << ShiftForWord), arg);
	} else {
		/* begin storePointer:ofObject:withValue: */
		oop1 = foo->specialObjectsOop;
		valuePointer = foo->nilObj;
		if ((((usqInt) oop1)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(oop1, valuePointer);
		}
		longAtput((oop1 + BaseHeaderSize) + (TheInterruptSemaphore << ShiftForWord), valuePointer);
	}
}


/*	Primitive. 'Invoke' an object like a function, sending the special message 
		run: originalSelector with: arguments in: aReceiver.
	 */

sqInt primitiveInvokeObjectAsMethod(void) {
register struct foo * foo = &fum;
    sqInt runReceiver;
    sqInt runSelector;
    sqInt lookupClass;
    sqInt runArgs;
    sqInt newReceiver;
    sqInt count;
    sqInt src;
    sqInt out;
    sqInt lastIn;
    sqInt in;
    sqInt sp;
    sqInt sp1;
    sqInt sp2;
    sqInt sp3;
    sqInt ccIndex;

	runArgs = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassArray << ShiftForWord)), foo->argumentCount);
	beRootIfOld(runArgs);
	/* begin transfer:from:to: */
	count = foo->argumentCount;
	src = foo->stackPointer - ((foo->argumentCount - 1) * BytesPerWord);
	flag("Dan");
	in = src - BytesPerWord;
	lastIn = in + (count * BytesPerWord);
	out = (runArgs + BaseHeaderSize) - BytesPerWord;
	while ((((usqInt) in)) < (((usqInt) lastIn))) {
		longAtput(out += BytesPerWord, longAt(in += BytesPerWord));
	}
	runSelector = foo->messageSelector;
	runReceiver = longAt(foo->stackPointer - (foo->argumentCount * BytesPerWord));
	/* begin pop: */
	foo->stackPointer -= (foo->argumentCount + 1) * BytesPerWord;
	newReceiver = foo->newMethod;
	foo->messageSelector = longAt((foo->specialObjectsOop + BaseHeaderSize) + (SelectorRunWithIn << ShiftForWord));
	foo->argumentCount = 3;
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, newReceiver);
	foo->stackPointer = sp;
	/* begin push: */
	longAtput(sp1 = foo->stackPointer + BytesPerWord, runSelector);
	foo->stackPointer = sp1;
	/* begin push: */
	longAtput(sp2 = foo->stackPointer + BytesPerWord, runArgs);
	foo->stackPointer = sp2;
	/* begin push: */
	longAtput(sp3 = foo->stackPointer + BytesPerWord, runReceiver);
	foo->stackPointer = sp3;
	/* begin fetchClassOf: */
	if ((newReceiver & 1)) {
		lookupClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(newReceiver))) >> 12) & 31;
	if (ccIndex == 0) {
		lookupClass = (longAt(newReceiver - BaseHeaderSize)) & AllButTypeMask;
		goto l1;
	} else {
		lookupClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	findNewMethodInClass(lookupClass);
	executeNewMethodFromCache();
	foo->successFlag = 1;
}


/*	Primitive. Answer whether the argument to the primitive is a root for young space */

EXPORT(sqInt) primitiveIsRoot(void) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt sp;
    sqInt sp1;
    sqInt oop1;

	/* begin stackObjectValue: */
	oop1 = longAt(foo->stackPointer - (0 * BytesPerWord));
	if ((oop1 & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		oop = null;
		goto l1;
	}
	oop = oop1;
l1:	/* end stackObjectValue: */;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= (foo->argumentCount + 1) * BytesPerWord;
		/* begin pushBool: */
		if ((longAt(oop)) & RootBit) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}


/*	Primitive. Answer whether the argument to the primitive resides in young space. */

EXPORT(sqInt) primitiveIsYoung(void) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt trueOrFalse;
    sqInt oop1;
    sqInt sp;
    sqInt sp1;

	/* begin stackObjectValue: */
	oop1 = longAt(foo->stackPointer - (0 * BytesPerWord));
	if ((oop1 & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		oop = null;
		goto l1;
	}
	oop = oop1;
l1:	/* end stackObjectValue: */;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= (foo->argumentCount + 1) * BytesPerWord;
		/* begin pushBool: */
		trueOrFalse = (((usqInt) oop)) >= (((usqInt) foo->youngStart));
		if (trueOrFalse) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}


/*	Obsolete on virtually all platforms; old style input polling code.
	Return the next keycode and remove it from the input buffer. The low byte is the 8-bit ISO character. The next four bits are the Smalltalk modifier bits <cmd><option><ctrl><shift>. */

sqInt primitiveKbdNext(void) {
register struct foo * foo = &fum;
    sqInt keystrokeWord;
    sqInt sp;
    sqInt sp1;

	/* begin pop: */
	foo->stackPointer -= 1 * BytesPerWord;
	keystrokeWord = ioGetKeystroke();
	if (keystrokeWord >= 0) {
		/* begin pushInteger: */
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, ((keystrokeWord << 1) | 1));
		foo->stackPointer = sp;
	} else {
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->nilObj);
		foo->stackPointer = sp1;
	}
}


/*	Obsolete on virtually all platforms; old style input polling code.
	Return the next keycode and without removing it from the input buffer. The low byte is the 8-bit ISO character. The next four bits are the Smalltalk modifier bits <cmd><option><ctrl><shift>. */

sqInt primitiveKbdPeek(void) {
register struct foo * foo = &fum;
    sqInt keystrokeWord;
    sqInt sp;
    sqInt sp1;

	/* begin pop: */
	foo->stackPointer -= 1 * BytesPerWord;
	keystrokeWord = ioPeekKeystroke();
	if (keystrokeWord >= 0) {
		/* begin pushInteger: */
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, ((keystrokeWord << 1) | 1));
		foo->stackPointer = sp;
	} else {
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->nilObj);
		foo->stackPointer = sp1;
	}
}

sqInt primitiveLessOrEqual(void) {
register struct foo * foo = &fum;
    sqInt integerArgument;
    sqInt integerReceiver;
    sqInt integerPointer;
    sqInt integerPointer1;
    sqInt top;
    sqInt top1;
    sqInt sp;
    sqInt sp1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer = top;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		integerArgument = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerArgument = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	/* begin popInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer1 = top1;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer1 & 1)) {
		integerReceiver = (integerPointer1 >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerReceiver = 0;
		goto l2;
	}
l2:	/* end checkedIntegerValueOf: */;
	/* begin checkBooleanResult: */
	if (foo->successFlag) {
		/* begin pushBool: */
		if (integerReceiver <= integerArgument) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}

sqInt primitiveLessThan(void) {
register struct foo * foo = &fum;
    sqInt integerArgument;
    sqInt integerReceiver;
    sqInt integerPointer;
    sqInt integerPointer1;
    sqInt top;
    sqInt top1;
    sqInt sp;
    sqInt sp1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer = top;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		integerArgument = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerArgument = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	/* begin popInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer1 = top1;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer1 & 1)) {
		integerReceiver = (integerPointer1 >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerReceiver = 0;
		goto l2;
	}
l2:	/* end checkedIntegerValueOf: */;
	/* begin checkBooleanResult: */
	if (foo->successFlag) {
		/* begin pushBool: */
		if (integerReceiver < integerArgument) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}


/*	Primitive. Return the n-th builtin module name. */

sqInt primitiveListBuiltinModule(void) {
register struct foo * foo = &fum;
    sqInt nameOop;
    char * moduleName;
    sqInt length;
    sqInt index;
    sqInt i;
    sqInt sp;
    sqInt integerPointer;
    sqInt sp1;

	if (!(foo->argumentCount == 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		index = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l1;
	}
	index = null;
l1:	/* end stackIntegerValue: */;
	if (index <= 0) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	moduleName = ioListBuiltinModule(index);
	if (moduleName == null) {
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, foo->nilObj);
		foo->stackPointer = sp;
		return null;
	}
	length = strlen(moduleName);
	nameOop = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassString << ShiftForWord)), length);
	for (i = 0; i <= (length - 1); i += 1) {
		byteAtput((nameOop + BaseHeaderSize) + i, moduleName[i]);
	}
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
	foo->nextPollTick = 0;
	/* begin pop:thenPush: */
	longAtput(sp1 = foo->stackPointer - ((2 - 1) * BytesPerWord), nameOop);
	foo->stackPointer = sp1;
}


/*	Primitive. Return the n-th loaded external module name. */

sqInt primitiveListExternalModule(void) {
register struct foo * foo = &fum;
    sqInt nameOop;
    char * moduleName;
    sqInt length;
    sqInt index;
    sqInt i;
    sqInt sp;
    sqInt integerPointer;
    sqInt sp1;

	if (!(foo->argumentCount == 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		index = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l1;
	}
	index = null;
l1:	/* end stackIntegerValue: */;
	if (index <= 0) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	moduleName = ioListLoadedModule(index);
	if (moduleName == null) {
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, foo->nilObj);
		foo->stackPointer = sp;
		return null;
	}
	length = strlen(moduleName);
	nameOop = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassString << ShiftForWord)), length);
	for (i = 0; i <= (length - 1); i += 1) {
		byteAtput((nameOop + BaseHeaderSize) + i, moduleName[i]);
	}
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
	foo->nextPollTick = 0;
	/* begin pop:thenPush: */
	longAtput(sp1 = foo->stackPointer - ((2 - 1) * BytesPerWord), nameOop);
	foo->stackPointer = sp1;
}


/*	This primitive is called from Squeak as...
		<imageSegment> loadSegmentFrom: aWordArray outPointers: anArray. */
/*	This primitive will load a binary image segment created by primitiveStoreImageSegment.  It expects the outPointer array to be of the proper size, and the wordArray to be well formed.  It will return as its value the original array of roots, and the erstwhile segmentWordArray will have been truncated to a size of zero.  If this primitive should fail, the segmentWordArray will, sadly, have been reduced to an unrecognizable and unusable jumble.  But what more could you have done with it anyway? */

sqInt primitiveLoadImageSegment(void) {
register struct foo * foo = &fum;
    sqInt doingClass;
    sqInt extraSize;
    usqInt fieldPtr;
    sqInt fieldOop;
    usqInt lastOut;
    usqInt lastPtr;
    sqInt segmentWordArray;
    sqInt mapOop;
    sqInt hdrTypeBits;
    usqInt segOop;
    sqInt data;
    sqInt outPointerArray;
    usqInt endSeg;
    sqInt header;
    usqInt outPtr;
    sqInt addr;
    sqInt addr1;
    sqInt sp;
    sqInt sz;
    sqInt header1;
    sqInt sz1;
    sqInt header2;

	if (DoAssertionChecks) {
		verifyCleanHeaders();
	}
	outPointerArray = longAt(foo->stackPointer);
	lastOut = outPointerArray + (lastPointerOf(outPointerArray));
	segmentWordArray = longAt(foo->stackPointer - (1 * BytesPerWord));

	/* Essential type checks */

	endSeg = (segmentWordArray + (sizeBitsOf(segmentWordArray))) - BaseHeaderSize;
	if (!((((((usqInt) (longAt(outPointerArray))) >> 8) & 15) == 2) && (((((usqInt) (longAt(segmentWordArray))) >> 8) & 15) == 6))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	data = longAt(segmentWordArray + BaseHeaderSize);
	if (!(((data & 65535) == imageFormatVersionNumber) || (((data & 65535) == (imageFormatForwardCompatibilityVersion())) || ((data & 65535) == (imageFormatBackwardCompatibilityVersion()))))) {
		/* begin reverseBytesFrom:to: */
		flag("Dan");
		addr1 = segmentWordArray + BaseHeaderSize;
		while ((((usqInt) addr1)) < (((usqInt) (endSeg + BytesPerWord)))) {
			longAtput(addr1, byteSwapped(longAt(addr1)));
			addr1 += BytesPerWord;
		}
		data = longAt(segmentWordArray + BaseHeaderSize);
		if (!(((data & 65535) == imageFormatVersionNumber) || (((data & 65535) == (imageFormatForwardCompatibilityVersion())) || ((data & 65535) == (imageFormatBackwardCompatibilityVersion()))))) {
			/* begin reverseBytesFrom:to: */
			flag("Dan");
			addr = segmentWordArray + BaseHeaderSize;
			while ((((usqInt) addr)) < (((usqInt) (endSeg + BytesPerWord)))) {
				longAtput(addr, byteSwapped(longAt(addr)));
				addr += BytesPerWord;
			}
			if (DoAssertionChecks) {
				verifyCleanHeaders();
			}
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	if (!((((usqInt) data) >> 16) == (((usqInt) (imageSegmentVersion())) >> 16))) {

		/* Oop of first embedded object */

		segOop = ((segmentWordArray + BaseHeaderSize) + BytesPerWord) + (foo->headerTypeBytes[(longAt((segmentWordArray + BaseHeaderSize) + BytesPerWord)) & TypeMask]);
		byteSwapByteObjectsFromto(segOop, endSeg + BytesPerWord);
	}
	segOop = ((segmentWordArray + BaseHeaderSize) + BytesPerWord) + (foo->headerTypeBytes[(longAt((segmentWordArray + BaseHeaderSize) + BytesPerWord)) & TypeMask]);
	while (segOop <= endSeg) {
		if (((longAt(segOop)) & TypeMask) <= 1) {
			fieldPtr = segOop - BytesPerWord;
			doingClass = 1;
		} else {
			fieldPtr = segOop + BaseHeaderSize;
			doingClass = 0;
		}

		/* last field */

		lastPtr = segOop + (lastPointerOf(segOop));
		if (lastPtr > endSeg) {
			if (DoAssertionChecks) {
				verifyCleanHeaders();
			}
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
		while (!(fieldPtr > lastPtr)) {
			fieldOop = longAt(fieldPtr);
			if (doingClass) {
				hdrTypeBits = (longAt(fieldPtr)) & TypeMask;
				fieldOop -= hdrTypeBits;
			}
			if ((fieldOop & 1)) {
				fieldPtr += BytesPerWord;
			} else {
				if (!((fieldOop & 3) == 0)) {
					/* begin primitiveFail */
					foo->successFlag = 0;
					return null;
				}
				if ((fieldOop & 2147483648U) == 0) {
					mapOop = fieldOop + segmentWordArray;
				} else {
					outPtr = outPointerArray + (fieldOop & 2147483647U);
					if (outPtr > lastOut) {
						/* begin primitiveFail */
						foo->successFlag = 0;
						return null;
					}
					mapOop = longAt(outPtr);
				}
				if (doingClass) {
					longAtput(fieldPtr, mapOop + hdrTypeBits);
					fieldPtr += 8;
					doingClass = 0;
				} else {
					longAtput(fieldPtr, mapOop);
					fieldPtr += BytesPerWord;
				}
				if (segOop < foo->youngStart) {
					possibleRootStoreIntovalue(segOop, mapOop);
				}
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) segOop)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(segOop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(segOop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header1 = longAt(segOop);
			if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(segOop - (BytesPerWord * 2))) & LongSizeMask;
				goto l1;
			} else {
				sz = header1 & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		segOop = (segOop + sz) + (foo->headerTypeBytes[(longAt(segOop + sz)) & TypeMask]);
	}
	segOop = ((segmentWordArray + BaseHeaderSize) + BytesPerWord) + (foo->headerTypeBytes[(longAt((segmentWordArray + BaseHeaderSize) + BytesPerWord)) & TypeMask]);
	while (segOop <= endSeg) {
		if (!(oopHasAcceptableClass(segOop))) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}

		/* first field */

		fieldPtr = segOop + BaseHeaderSize;

		/* last field */
		/* Go through all oops, remapping them... */

		lastPtr = segOop + (lastPointerOf(segOop));
		while (!(fieldPtr > lastPtr)) {
			fieldOop = longAt(fieldPtr);
			if (!(oopHasAcceptableClass(fieldOop))) {
				/* begin primitiveFail */
				foo->successFlag = 0;
				return null;
			}
			fieldPtr += BytesPerWord;
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) segOop)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(segOop)) & TypeMask) == HeaderTypeFree) {
			sz1 = (longAt(segOop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header2 = longAt(segOop);
			if ((header2 & TypeMask) == HeaderTypeSizeAndClass) {
				sz1 = (longAt(segOop - (BytesPerWord * 2))) & LongSizeMask;
				goto l2;
			} else {
				sz1 = header2 & SizeMask;
				goto l2;
			}
		l2:	/* end sizeBitsOf: */;
		}
		segOop = (segOop + sz1) + (foo->headerTypeBytes[(longAt(segOop + sz1)) & TypeMask]);
	}
	extraSize = foo->headerTypeBytes[(longAt(segmentWordArray)) & TypeMask];
	hdrTypeBits = (longAt(segmentWordArray)) & TypeMask;
	if (extraSize == 8) {
		longAtput(segmentWordArray - extraSize, (BaseHeaderSize + BytesPerWord) + hdrTypeBits);
	} else {
		header = longAt(segmentWordArray);
		longAtput(segmentWordArray, ((header - (header & SizeMask)) + BaseHeaderSize) + BytesPerWord);
	}
	if (DoAssertionChecks) {
		verifyCleanHeaders();
	}
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((3 - 1) * BytesPerWord), ((segmentWordArray + BaseHeaderSize) + BytesPerWord) + (foo->headerTypeBytes[(longAt((segmentWordArray + BaseHeaderSize) + BytesPerWord)) & TypeMask]));
	foo->stackPointer = sp;
}

sqInt primitiveLoadInstVar(void) {
register struct foo * foo = &fum;
    sqInt thisReceiver;
    sqInt top;
    sqInt sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	thisReceiver = top;
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, longAt((thisReceiver + BaseHeaderSize) + ((foo->primitiveIndex - 264) << ShiftForWord)));
	foo->stackPointer = sp;
}


/*	Natural log. */

sqInt primitiveLogN(void) {
register struct foo * foo = &fum;
    double  rcvr;

	rcvr = popFloat();
	if (foo->successFlag) {
		pushFloat(log(rcvr));
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
	}
}


/*	Register the low-space semaphore. If the argument is not a 
	Semaphore, unregister the current low-space Semaphore. */

sqInt primitiveLowSpaceSemaphore(void) {
register struct foo * foo = &fum;
    sqInt arg;
    sqInt oop;
    sqInt oop1;
    sqInt valuePointer;
    sqInt top;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	arg = top;
	if ((fetchClassOf(arg)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassSemaphore << ShiftForWord)))) {
		/* begin storePointer:ofObject:withValue: */
		oop = foo->specialObjectsOop;
		if ((((usqInt) oop)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(oop, arg);
		}
		longAtput((oop + BaseHeaderSize) + (TheLowSpaceSemaphore << ShiftForWord), arg);
	} else {
		/* begin storePointer:ofObject:withValue: */
		oop1 = foo->specialObjectsOop;
		valuePointer = foo->nilObj;
		if ((((usqInt) oop1)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(oop1, valuePointer);
		}
		longAtput((oop1 + BaseHeaderSize) + (TheLowSpaceSemaphore << ShiftForWord), valuePointer);
	}
}

sqInt primitiveMakePoint(void) {
register struct foo * foo = &fum;
    sqInt pt;
    sqInt rcvr;
    sqInt argument;
    sqInt pointResult;
    sqInt pointResult1;
    sqInt valuePointer;
    sqInt pointResult2;
    sqInt valuePointer1;
    sqInt valuePointer2;
    sqInt sp;

	argument = longAt(foo->stackPointer);
	rcvr = longAt(foo->stackPointer - (1 * BytesPerWord));
	if ((rcvr & 1)) {
		if ((argument & 1)) {
			/* begin makePointwithxValue:yValue: */
			pointResult = instantiateSmallClasssizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassPoint << ShiftForWord)), 3 * BytesPerWord);
			longAtput((pointResult + BaseHeaderSize) + (XIndex << ShiftForWord), ((((rcvr >> 1)) << 1) | 1));
			longAtput((pointResult + BaseHeaderSize) + (YIndex << ShiftForWord), ((((argument >> 1)) << 1) | 1));
			pt = pointResult;
		} else {
			/* begin makePointwithxValue:yValue: */
			pointResult1 = instantiateSmallClasssizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassPoint << ShiftForWord)), 3 * BytesPerWord);
			longAtput((pointResult1 + BaseHeaderSize) + (XIndex << ShiftForWord), ((((rcvr >> 1)) << 1) | 1));
			longAtput((pointResult1 + BaseHeaderSize) + (YIndex << ShiftForWord), ((0 << 1) | 1));
			pt = pointResult1;
			/* begin storePointer:ofObject:withValue: */
			valuePointer = longAt(foo->stackPointer - (0 * BytesPerWord));
			if ((((usqInt) pt)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(pt, valuePointer);
			}
			longAtput((pt + BaseHeaderSize) + (1 << ShiftForWord), valuePointer);
		}
	} else {
		if (!((fetchClassOf(rcvr)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord))))) {
			/* begin success: */
			foo->successFlag = 0 && foo->successFlag;
			return null;
		}
		/* begin makePointwithxValue:yValue: */
		pointResult2 = instantiateSmallClasssizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassPoint << ShiftForWord)), 3 * BytesPerWord);
		longAtput((pointResult2 + BaseHeaderSize) + (XIndex << ShiftForWord), ((0 << 1) | 1));
		longAtput((pointResult2 + BaseHeaderSize) + (YIndex << ShiftForWord), ((0 << 1) | 1));
		pt = pointResult2;
		/* begin storePointer:ofObject:withValue: */
		valuePointer1 = longAt(foo->stackPointer - (1 * BytesPerWord));
		if ((((usqInt) pt)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(pt, valuePointer1);
		}
		longAtput((pt + BaseHeaderSize) + (0 << ShiftForWord), valuePointer1);
		/* begin storePointer:ofObject:withValue: */
		valuePointer2 = longAt(foo->stackPointer - (0 * BytesPerWord));
		if ((((usqInt) pt)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(pt, valuePointer2);
		}
		longAtput((pt + BaseHeaderSize) + (1 << ShiftForWord), valuePointer2);
	}
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), pt);
	foo->stackPointer = sp;
}


/*	Primitive. Mark the method for exception handling. The primitive must fail after marking the context so that the regular code is run. */

sqInt primitiveMarkHandlerMethod(void) {
	/* begin primitiveFail */
	foo->successFlag = 0;
	return null;
}


/*	Primitive. Mark the method for exception unwinding. The primitive must fail after marking the context so that the regular code is run. */

sqInt primitiveMarkUnwindMethod(void) {
	/* begin primitiveFail */
	foo->successFlag = 0;
	return null;
}


/*	Return the method an external primitive was defined in */

sqInt primitiveMethod(void) {
	return foo->newMethod;
}


/*	This is a named (not numbered) primitive in the null module (ie the VM) */

EXPORT(sqInt) primitiveMicrosecondClock(void) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt sp;

	/* begin pop:thenPush: */
	oop = positive64BitIntegerFor(ioMicroSecondClock());
	longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), oop);
	foo->stackPointer = sp;
}


/*	Return the value of the millisecond clock as an integer. Note that the millisecond clock wraps around periodically. On some platforms it can wrap daily. The range is limited to SmallInteger maxVal / 2 to allow delays of up to that length without overflowing a SmallInteger. */

sqInt primitiveMillisecondClock(void) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt sp;

	/* begin pop:thenPush: */
	oop = ((((ioMSecs()) & MillisecondClockMask) << 1) | 1);
	longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), oop);
	foo->stackPointer = sp;
}

sqInt primitiveMod(void) {
register struct foo * foo = &fum;
    sqInt mod;
    sqInt sp;

	mod = doPrimitiveModby(longAt(foo->stackPointer - (1 * BytesPerWord)), longAt(foo->stackPointer));
	/* begin pop2AndPushIntegerIfOK: */
	if (foo->successFlag) {
		if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
			(((((int) mod)) ^ ((((int) mod)) << 1)) >= 0)
# else
			((mod >= -1073741824) && (mod <= 1073741823))
# endif  // SQ_HOST32
		) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), ((mod << 1) | 1));
			foo->stackPointer = sp;
		} else {
			foo->successFlag = 0;
		}
	}
}


/*	Obsolete on virtually all platforms; old style input polling code.
	Return the mouse button state. The low three bits encode the state of the <red><yellow><blue> mouse buttons. The next four bits encode the Smalltalk modifier bits <cmd><option><ctrl><shift>. */

sqInt primitiveMouseButtons(void) {
register struct foo * foo = &fum;
    sqInt buttonWord;
    sqInt sp;

	/* begin pop: */
	foo->stackPointer -= 1 * BytesPerWord;
	buttonWord = ioGetButtonState();
	/* begin pushInteger: */
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, ((buttonWord << 1) | 1));
	foo->stackPointer = sp;
}


/*	Obsolete on virtually all platforms; old style input polling code.
	Return a Point indicating current position of the mouse. Note that mouse coordinates may be negative if the mouse moves above or to the left of the top-left corner of the Smalltalk window. */

sqInt primitiveMousePoint(void) {
register struct foo * foo = &fum;
    sqInt y;
    sqInt x;
    sqInt pointWord;
    sqInt object;
    sqInt sp;
    sqInt pointResult;

	/* begin pop: */
	foo->stackPointer -= 1 * BytesPerWord;
	pointWord = ioMousePoint();
	/* begin signExtend16: */
	if ((((((usqInt) pointWord) >> 16) & 65535) & 32768) == 0) {
		x = (((usqInt) pointWord) >> 16) & 65535;
		goto l1;
	} else {
		x = ((((usqInt) pointWord) >> 16) & 65535) - 65536;
		goto l1;
	}
l1:	/* end signExtend16: */;
	/* begin signExtend16: */
	if (((pointWord & 65535) & 32768) == 0) {
		y = pointWord & 65535;
		goto l2;
	} else {
		y = (pointWord & 65535) - 65536;
		goto l2;
	}
l2:	/* end signExtend16: */;
	/* begin push: */
	/* begin makePointwithxValue:yValue: */
	pointResult = instantiateSmallClasssizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassPoint << ShiftForWord)), 3 * BytesPerWord);
	longAtput((pointResult + BaseHeaderSize) + (XIndex << ShiftForWord), ((x << 1) | 1));
	longAtput((pointResult + BaseHeaderSize) + (YIndex << ShiftForWord), ((y << 1) | 1));
	object = pointResult;
	longAtput(sp = foo->stackPointer + BytesPerWord, object);
	foo->stackPointer = sp;
}

sqInt primitiveMultiply(void) {
register struct foo * foo = &fum;
    sqInt integerRcvr;
    sqInt integerResult;
    sqInt integerArg;
    sqInt integerPointer;
    sqInt integerPointer1;
    sqInt sp;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		integerRcvr = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerRcvr = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	/* begin stackIntegerValue: */
	integerPointer1 = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer1 & 1)) {
		integerArg = (integerPointer1 >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerArg = 0;
		goto l2;
	}
l2:	/* end checkedIntegerValueOf: */;
	if (foo->successFlag) {

		/* check for C overflow by seeing if computation is reversible */

		integerResult = integerRcvr * integerArg;
		if ((integerArg == 0) || ((integerResult / integerArg) == integerRcvr)) {
			/* begin pop2AndPushIntegerIfOK: */
			if (foo->successFlag) {
				if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
					(((((int) integerResult)) ^ ((((int) integerResult)) << 1)) >= 0)
# else
					((integerResult >= -1073741824) && (integerResult <= 1073741823))
# endif  // SQ_HOST32
				) {
					/* begin pop:thenPush: */
					longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), ((integerResult << 1) | 1));
					foo->stackPointer = sp;
				} else {
					foo->successFlag = 0;
				}
			}
		} else {
			/* begin primitiveFail */
			foo->successFlag = 0;
		}
	}
}


/*	Allocate a new fixed-size instance. Fail if the allocation would leave less than lowSpaceThreshold bytes free. May cause a GC */

sqInt primitiveNew(void) {
register struct foo * foo = &fum;
    sqInt spaceOkay;
    sqInt class;
    sqInt object;
    sqInt sp;
    sqInt format;
    usqInt minFree;
    usqInt minFree1;


	/* The following may cause GC! */

	class = longAt(foo->stackPointer);
	/* begin sufficientSpaceToInstantiate:indexableSize: */
	format = (((usqInt) ((longAt((class + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1)) >> 8) & 15;
	if ((0 > 0) && (format < 2)) {
		spaceOkay = 0;
		goto l1;
	}
	if (format < 8) {
		if (isExcessiveAllocationRequestshift(0, ShiftForWord)) {
			spaceOkay = 0;
			goto l1;
		}
		/* begin sufficientSpaceToAllocate: */
		minFree = (foo->lowSpaceThreshold + (2500 + (0 * BytesPerWord))) + BaseHeaderSize;
		if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((usqInt) minFree))) {
			spaceOkay = 1;
			goto l2;
		} else {
			spaceOkay = sufficientSpaceAfterGC(minFree);
			goto l2;
		}
	l2:	/* end sufficientSpaceToAllocate: */;
		goto l1;
	} else {
		if (isExcessiveAllocationRequestshift(0, 0)) {
			spaceOkay = 0;
			goto l1;
		}
		/* begin sufficientSpaceToAllocate: */
		minFree1 = (foo->lowSpaceThreshold + (2500 + 0)) + BaseHeaderSize;
		if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((usqInt) minFree1))) {
			spaceOkay = 1;
			goto l3;
		} else {
			spaceOkay = sufficientSpaceAfterGC(minFree1);
			goto l3;
		}
	l3:	/* end sufficientSpaceToAllocate: */;
		goto l1;
	}
l1:	/* end sufficientSpaceToInstantiate:indexableSize: */;
	/* begin success: */
	foo->successFlag = spaceOkay && foo->successFlag;
	if (foo->successFlag) {
		/* begin push: */
		object = instantiateClassindexableSize(popStack(), 0);
		longAtput(sp = foo->stackPointer + BytesPerWord, object);
		foo->stackPointer = sp;
	}
}

sqInt primitiveNewMethod(void) {
register struct foo * foo = &fum;
    sqInt theMethod;
    sqInt class;
    sqInt literalCount;
    sqInt bytecodeCount;
    sqInt i;
    sqInt size;
    sqInt header;
    sqInt top;
    sqInt integerPointer;
    sqInt top1;
    sqInt top2;
    sqInt sp;
    sqInt valuePointer;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	header = top;
	/* begin popInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer = top1;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		bytecodeCount = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		bytecodeCount = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	/* begin success: */
	foo->successFlag = ((header & 1)) && foo->successFlag;
	if (!(foo->successFlag)) {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
		return null;
	}
	/* begin popStack */
	top2 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	class = top2;
	size = ((((((usqInt) header) >> 10) & 255) + 1) * BytesPerWord) + bytecodeCount;
	theMethod = instantiateClassindexableSize(class, size);
	longAtput((theMethod + BaseHeaderSize) + (HeaderIndex << ShiftForWord), header);
	literalCount = (((usqInt) header) >> 10) & 255;
	for (i = 1; i <= literalCount; i += 1) {
		/* begin storePointer:ofObject:withValue: */
		valuePointer = foo->nilObj;
		if ((((usqInt) theMethod)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(theMethod, valuePointer);
		}
		longAtput((theMethod + BaseHeaderSize) + (i << ShiftForWord), valuePointer);
	}
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, theMethod);
	foo->stackPointer = sp;
}


/*	Allocate a new indexable instance. Fail if the allocation would leave less than lowSpaceThreshold bytes free. */

sqInt primitiveNewWithArg(void) {
register struct foo * foo = &fum;
    sqInt spaceOkay;
    sqInt class;
    usqInt size;
    sqInt oop;
    sqInt sp;
    sqInt format;
    usqInt minFree;
    usqInt minFree1;

	size = positive32BitValueOf(longAt(foo->stackPointer));
	class = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin success: */
	foo->successFlag = (size >= 0) && foo->successFlag;
	if (foo->successFlag) {
		/* begin sufficientSpaceToInstantiate:indexableSize: */
		format = (((usqInt) ((longAt((class + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1)) >> 8) & 15;
		if ((size > 0) && (format < 2)) {
			spaceOkay = 0;
			goto l1;
		}
		if (format < 8) {
			if (isExcessiveAllocationRequestshift(size, ShiftForWord)) {
				spaceOkay = 0;
				goto l1;
			}
			/* begin sufficientSpaceToAllocate: */
			minFree = (foo->lowSpaceThreshold + (2500 + (size * BytesPerWord))) + BaseHeaderSize;
			if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((usqInt) minFree))) {
				spaceOkay = 1;
				goto l2;
			} else {
				spaceOkay = sufficientSpaceAfterGC(minFree);
				goto l2;
			}
		l2:	/* end sufficientSpaceToAllocate: */;
			goto l1;
		} else {
			if (isExcessiveAllocationRequestshift(size, 0)) {
				spaceOkay = 0;
				goto l1;
			}
			/* begin sufficientSpaceToAllocate: */
			minFree1 = (foo->lowSpaceThreshold + (2500 + size)) + BaseHeaderSize;
			if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((usqInt) minFree1))) {
				spaceOkay = 1;
				goto l3;
			} else {
				spaceOkay = sufficientSpaceAfterGC(minFree1);
				goto l3;
			}
		l3:	/* end sufficientSpaceToAllocate: */;
			goto l1;
		}
	l1:	/* end sufficientSpaceToInstantiate:indexableSize: */;
		/* begin success: */
		foo->successFlag = spaceOkay && foo->successFlag;
		class = longAt(foo->stackPointer - (1 * BytesPerWord));
	}
	if (foo->successFlag) {
		/* begin pop:thenPush: */
		oop = instantiateClassindexableSize(class, size);
		longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), oop);
		foo->stackPointer = sp;
	}
}


/*	PrimitiveNext will succeed only if the stream's array is in the atCache.
	Otherwise failure will lead to proper message lookup of at: and
	subsequent installation in the cache if appropriate. */

sqInt primitiveNext(void) {
register struct foo * foo = &fum;
    sqInt stream;
    sqInt atIx;
    sqInt array;
    sqInt result;
    sqInt index;
    sqInt limit;
    sqInt sp;

	stream = longAt(foo->stackPointer);
	if (!((((stream & 1) == 0) && (((((usqInt) (longAt(stream))) >> 8) & 15) <= 4)) && ((lengthOf(stream)) >= (StreamReadLimitIndex + 1)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	array = longAt((stream + BaseHeaderSize) + (StreamArrayIndex << ShiftForWord));
	index = fetchIntegerofObject(StreamIndexIndex, stream);
	limit = fetchIntegerofObject(StreamReadLimitIndex, stream);
	atIx = array & AtCacheMask;
	if (!((index < limit) && ((foo->atCache[atIx + AtCacheOop]) == array))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	index += 1;

	/* Above may cause GC, so can't use stream, array etc. below it */

	result = commonVariableatcacheIndex(array, index, atIx);
	if (foo->successFlag) {
		stream = longAt(foo->stackPointer);
		/* begin storeInteger:ofObject:withValue: */
		if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
			(((((int) index)) ^ ((((int) index)) << 1)) >= 0)
# else
			((index >= -1073741824) && (index <= 1073741823))
# endif  // SQ_HOST32
		) {
			longAtput((stream + BaseHeaderSize) + (StreamIndexIndex << ShiftForWord), ((index << 1) | 1));
		} else {
			/* begin primitiveFail */
			foo->successFlag = 0;
		}
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), result);
		foo->stackPointer = sp;
		return null;
	}
}

sqInt primitiveNextInstance(void) {
register struct foo * foo = &fum;
    sqInt object;
    sqInt instance;
    sqInt sp;
    sqInt classPointer;
    sqInt thisClass;
    sqInt thisObj;
    sqInt ccIndex;
    sqInt ccIndex1;

	object = longAt(foo->stackPointer);
	/* begin instanceAfter: */
	/* begin fetchClassOf: */
	if ((object & 1)) {
		classPointer = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l3;
	}
	ccIndex1 = (((usqInt) (longAt(object))) >> 12) & 31;
	if (ccIndex1 == 0) {
		classPointer = (longAt(object - BaseHeaderSize)) & AllButTypeMask;
		goto l3;
	} else {
		classPointer = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex1 - 1) << ShiftForWord));
		goto l3;
	}
l3:	/* end fetchClassOf: */;
	thisObj = accessibleObjectAfter(object);
	while (!(thisObj == null)) {
		/* begin fetchClassOf: */
		if ((thisObj & 1)) {
			thisClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
			goto l2;
		}
		ccIndex = (((usqInt) (longAt(thisObj))) >> 12) & 31;
		if (ccIndex == 0) {
			thisClass = (longAt(thisObj - BaseHeaderSize)) & AllButTypeMask;
			goto l2;
		} else {
			thisClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
			goto l2;
		}
	l2:	/* end fetchClassOf: */;
		if (thisClass == classPointer) {
			instance = thisObj;
			goto l1;
		}
		thisObj = accessibleObjectAfter(thisObj);
	}
	instance = foo->nilObj;
l1:	/* end instanceAfter: */;
	if (instance == foo->nilObj) {
		/* begin primitiveFail */
		foo->successFlag = 0;
	} else {
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * BytesPerWord), instance);
		foo->stackPointer = sp;
	}
}


/*	Return the object following the receiver in the heap. Return the SmallInteger zero when there are no more objects. */

sqInt primitiveNextObject(void) {
register struct foo * foo = &fum;
    sqInt object;
    sqInt instance;
    sqInt sp;
    sqInt sp1;

	object = longAt(foo->stackPointer);
	instance = accessibleObjectAfter(object);
	if (instance == null) {
		/* begin pop:thenPushInteger: */
		longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * BytesPerWord), ((0 << 1) | 1));
		foo->stackPointer = sp;
	} else {
		/* begin pop:thenPush: */
		longAtput(sp1 = foo->stackPointer - (((foo->argumentCount + 1) - 1) * BytesPerWord), instance);
		foo->stackPointer = sp1;
	}
}


/*	PrimitiveNextPut will succeed only if the stream's array is in the atPutCache.
	Otherwise failure will lead to proper message lookup of at:put: and
	subsequent installation in the cache if appropriate. */

sqInt primitiveNextPut(void) {
register struct foo * foo = &fum;
    sqInt value;
    sqInt stream;
    sqInt atIx;
    sqInt array;
    sqInt index;
    sqInt limit;
    sqInt sp;
    sqInt valToPut;
    sqInt fmt;
    sqInt stSize;
    sqInt fixedFields;

	value = longAt(foo->stackPointer);
	stream = longAt(foo->stackPointer - (1 * BytesPerWord));
	if (!((((stream & 1) == 0) && (((((usqInt) (longAt(stream))) >> 8) & 15) <= 4)) && ((lengthOf(stream)) >= (StreamReadLimitIndex + 1)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	array = longAt((stream + BaseHeaderSize) + (StreamArrayIndex << ShiftForWord));
	index = fetchIntegerofObject(StreamIndexIndex, stream);
	limit = fetchIntegerofObject(StreamWriteLimitIndex, stream);
	atIx = (array & AtCacheMask) + AtPutBase;
	if (!((index < limit) && ((foo->atCache[atIx + AtCacheOop]) == array))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	index += 1;
	/* begin commonVariable:at:put:cacheIndex: */
	stSize = foo->atCache[atIx + AtCacheSize];
	if (((((usqInt) index)) >= (((usqInt) 1))) && ((((usqInt) index)) <= (((usqInt) stSize)))) {
		fmt = foo->atCache[atIx + AtCacheFmt];
		if (fmt <= 4) {
			fixedFields = foo->atCache[atIx + AtCacheFixedFields];
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) array)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(array, value);
			}
			longAtput((array + BaseHeaderSize) + (((index + fixedFields) - 1) << ShiftForWord), value);
			goto l1;
		}
		if (fmt < 8) {
			valToPut = positive32BitValueOf(value);
			if (foo->successFlag) {
				long32Atput((array + BaseHeaderSize) + ((index - 1) << 2), valToPut);
			}
			goto l1;
		}
		if (fmt >= 16) {
			valToPut = asciiOfCharacter(value);
			if (!(foo->successFlag)) {
				goto l1;
			}
		} else {
			valToPut = value;
		}
		if ((valToPut & 1)) {
			valToPut = (valToPut >> 1);
			if (!((valToPut >= 0) && (valToPut <= 255))) {
				/* begin primitiveFail */
				foo->successFlag = 0;
				goto l1;
			}
			byteAtput((array + BaseHeaderSize) + (index - 1), valToPut);
			goto l1;
		}
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
l1:	/* end commonVariable:at:put:cacheIndex: */;
	if (foo->successFlag) {
		/* begin storeInteger:ofObject:withValue: */
		if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
			(((((int) index)) ^ ((((int) index)) << 1)) >= 0)
# else
			((index >= -1073741824) && (index <= 1073741823))
# endif  // SQ_HOST32
		) {
			longAtput((stream + BaseHeaderSize) + (StreamIndexIndex << ShiftForWord), ((index << 1) | 1));
		} else {
			/* begin primitiveFail */
			foo->successFlag = 0;
		}
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), value);
		foo->stackPointer = sp;
		return null;
	}
}


/*	A placeholder for primitives that haven't been implemented or are being withdrawn gradually. Just absorbs any arguments and returns the receiver. */

sqInt primitiveNoop(void) {
register struct foo * foo = &fum;
	/* begin pop: */
	foo->stackPointer -= foo->argumentCount * BytesPerWord;
}

sqInt primitiveNotEqual(void) {
register struct foo * foo = &fum;
    sqInt integerArgument;
    sqInt result;
    sqInt integerReceiver;
    sqInt top;
    sqInt top1;
    sqInt sp;
    sqInt sp1;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerArgument = top;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerReceiver = top1;
	result = !(compare31or32Bitsequal(integerReceiver, integerArgument));
	/* begin checkBooleanResult: */
	if (foo->successFlag) {
		/* begin pushBool: */
		if (result) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}


/*	Defined for CompiledMethods only */

sqInt primitiveObjectAt(void) {
register struct foo * foo = &fum;
    sqInt thisReceiver;
    sqInt index;
    sqInt sp;
    sqInt integerPointer;
    sqInt top;
    sqInt top1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer = top;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		index = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l1;
	}
	index = null;
l1:	/* end popInteger */;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	thisReceiver = top1;
	/* begin success: */
	foo->successFlag = (index > 0) && foo->successFlag;
	/* begin success: */
	foo->successFlag = (index <= (((((usqInt) (longAt((thisReceiver + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 10) & 255) + LiteralStart)) && foo->successFlag;
	if (foo->successFlag) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, longAt((thisReceiver + BaseHeaderSize) + ((index - 1) << ShiftForWord)));
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}


/*	Defined for CompiledMethods only */

sqInt primitiveObjectAtPut(void) {
register struct foo * foo = &fum;
    sqInt newValue;
    sqInt thisReceiver;
    sqInt index;
    sqInt sp;
    sqInt top;
    sqInt integerPointer;
    sqInt top1;
    sqInt top2;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	newValue = top;
	/* begin popInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer = top1;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		index = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l1;
	}
	index = null;
l1:	/* end popInteger */;
	/* begin popStack */
	top2 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	thisReceiver = top2;
	/* begin success: */
	foo->successFlag = (index > 0) && foo->successFlag;
	/* begin success: */
	foo->successFlag = (index <= (((((usqInt) (longAt((thisReceiver + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 10) & 255) + LiteralStart)) && foo->successFlag;
	if (foo->successFlag) {
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) thisReceiver)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(thisReceiver, newValue);
		}
		longAtput((thisReceiver + BaseHeaderSize) + ((index - 1) << ShiftForWord), newValue);
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, newValue);
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 3 * BytesPerWord;
	}
}

sqInt primitiveObjectPointsTo(void) {
register struct foo * foo = &fum;
    sqInt thang;
    sqInt rcvr;
    sqInt lastField;
    sqInt i;
    sqInt top;
    sqInt top1;
    sqInt sp;
    sqInt sp1;
    sqInt sp2;
    sqInt sp3;
    sqInt sp4;
    sqInt sp5;
    sqInt fmt;
    sqInt sz;
    sqInt methodHeader;
    sqInt contextSize;
    sqInt header;
    sqInt sp6;
    sqInt type;
    sqInt header1;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	thang = top;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	rcvr = top1;
	if ((rcvr & 1)) {
		/* begin pushBool: */
		if (0) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
		return null;
	}
	/* begin lastPointerOf: */
	header = longAt(rcvr);
	fmt = (((usqInt) header) >> 8) & 15;
	if (fmt <= 4) {
		if ((fmt == 3) && ((((((usqInt) header) >> 12) & 31) == 13) || ((((((usqInt) header) >> 12) & 31) == 14) || (((((usqInt) header) >> 12) & 31) == 4)))) {
			/* begin fetchStackPointerOf: */
			sp6 = longAt((rcvr + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
			if (!((sp6 & 1))) {
				contextSize = 0;
				goto l1;
			}
			contextSize = (sp6 >> 1);
		l1:	/* end fetchStackPointerOf: */;
			lastField = (CtxtTempFrameStart + contextSize) * BytesPerWord;
			goto l4;
		}
		/* begin sizeBitsOfSafe: */
		header1 = longAt(rcvr);
		/* begin rightType: */
		if ((header1 & SizeMask) == 0) {
			type = HeaderTypeSizeAndClass;
			goto l2;
		} else {
			if ((header1 & CompactClassMask) == 0) {
				type = HeaderTypeClass;
				goto l2;
			} else {
				type = HeaderTypeShort;
				goto l2;
			}
		}
	l2:	/* end rightType: */;
		if (type == HeaderTypeSizeAndClass) {
			sz = (longAt(rcvr - (BytesPerWord * 2))) & AllButTypeMask;
			goto l3;
		} else {
			sz = header1 & SizeMask;
			goto l3;
		}
	l3:	/* end sizeBitsOfSafe: */;
		lastField = sz - BaseHeaderSize;
		goto l4;
	}
	if (fmt < 12) {
		lastField = 0;
		goto l4;
	}
	methodHeader = longAt(rcvr + BaseHeaderSize);
	lastField = (((((usqInt) methodHeader) >> 10) & 255) * BytesPerWord) + BaseHeaderSize;
l4:	/* end lastPointerOf: */;
	for (i = BaseHeaderSize; i <= lastField; i += BytesPerWord) {
		if ((longAt(rcvr + i)) == thang) {
			/* begin pushBool: */
			if (1) {
				/* begin push: */
				longAtput(sp2 = foo->stackPointer + BytesPerWord, foo->trueObj);
				foo->stackPointer = sp2;
			} else {
				/* begin push: */
				longAtput(sp3 = foo->stackPointer + BytesPerWord, foo->falseObj);
				foo->stackPointer = sp3;
			}
			return null;
		}
	}
	/* begin pushBool: */
	if (0) {
		/* begin push: */
		longAtput(sp4 = foo->stackPointer + BytesPerWord, foo->trueObj);
		foo->stackPointer = sp4;
	} else {
		/* begin push: */
		longAtput(sp5 = foo->stackPointer + BytesPerWord, foo->falseObj);
		foo->stackPointer = sp5;
	}
}


/*	Primitive. Invoke an obsolete indexed primitive. */

sqInt primitiveObsoleteIndexedPrimitive(void) {
register struct foo * foo = &fum;
    void * functionAddress;
    char * pluginName;
    char * functionName;

	functionAddress = ((void *) ((obsoleteIndexedPrimitiveTable[foo->primitiveIndex])[2]));
	if (!(functionAddress == null)) {
		return ((sqInt (*)(void))functionAddress)();
	}
	pluginName = (obsoleteIndexedPrimitiveTable[foo->primitiveIndex])[0];
	functionName = (obsoleteIndexedPrimitiveTable[foo->primitiveIndex])[1];
	if ((pluginName == null) && (functionName == null)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	functionAddress = ioLoadFunctionFrom(functionName, pluginName);
	if (!(functionAddress == 0)) {
		(obsoleteIndexedPrimitiveTable[foo->primitiveIndex])[2] = (((char*) functionAddress));
		return ((sqInt (*)(void))functionAddress)();
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
	return null;
}

sqInt primitivePerform(void) {
register struct foo * foo = &fum;
    sqInt lookupClass;
    sqInt performSelector;
    sqInt performMethod;
    sqInt i;
    sqInt newReceiver;
    sqInt selectorIndex;
    sqInt successValue;
    sqInt fieldIndex;
    sqInt oop;
    sqInt valuePointer;
    sqInt oop1;
    sqInt valuePointer1;
    sqInt count;
    sqInt fromOop;
    sqInt toOop;
    sqInt toIndex;
    sqInt fromIndex;
    sqInt lastFrom;
    sqInt ccIndex;

	performSelector = foo->messageSelector;
	performMethod = foo->newMethod;
	foo->messageSelector = longAt(foo->stackPointer - ((foo->argumentCount - 1) * BytesPerWord));

	/* NOTE: the following lookup may fail and be converted to #doesNotUnderstand:, so we must adjust argumentCount and slide args now, so that would work. */
	/* Slide arguments down over selector */

	newReceiver = longAt(foo->stackPointer - (foo->argumentCount * BytesPerWord));
	foo->argumentCount -= 1;
	selectorIndex = (((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) - foo->argumentCount;
	/* begin transfer:fromIndex:ofObject:toIndex:ofObject: */
	count = foo->argumentCount;
	fromOop = foo->activeContext;
	toOop = foo->activeContext;
	flag("Dan");
	fromIndex = fromOop + ((selectorIndex + 1) * BytesPerWord);
	toIndex = toOop + (selectorIndex * BytesPerWord);
	lastFrom = fromIndex + (count * BytesPerWord);
	while ((((usqInt) fromIndex)) < (((usqInt) lastFrom))) {
		fromIndex += BytesPerWord;
		toIndex += BytesPerWord;
		longAtput(toIndex, longAt(fromIndex));
	}
	/* begin pop: */
	foo->stackPointer -= 1 * BytesPerWord;
	/* begin fetchClassOf: */
	if ((newReceiver & 1)) {
		lookupClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(newReceiver))) >> 12) & 31;
	if (ccIndex == 0) {
		lookupClass = (longAt(newReceiver - BaseHeaderSize)) & AllButTypeMask;
		goto l1;
	} else {
		lookupClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	findNewMethodInClass(lookupClass);
	if (((((usqInt) (longAt(foo->newMethod))) >> 8) & 15) >= 12) {
		/* begin success: */
		successValue = ((((usqInt) (longAt((foo->newMethod + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 25) & 15) == foo->argumentCount;
		foo->successFlag = successValue && foo->successFlag;
	}
	if (foo->successFlag) {
		executeNewMethodFromCache();
		foo->successFlag = 1;
	} else {
		for (i = 1; i <= foo->argumentCount; i += 1) {
			/* begin storePointer:ofObject:withValue: */
			fieldIndex = ((foo->argumentCount - i) + 1) + selectorIndex;
			oop = foo->activeContext;
			valuePointer = longAt((foo->activeContext + BaseHeaderSize) + (((foo->argumentCount - i) + selectorIndex) << ShiftForWord));
			if ((((usqInt) oop)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(oop, valuePointer);
			}
			longAtput((oop + BaseHeaderSize) + (fieldIndex << ShiftForWord), valuePointer);
		}
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
		/* begin storePointer:ofObject:withValue: */
		oop1 = foo->activeContext;
		valuePointer1 = foo->messageSelector;
		if ((((usqInt) oop1)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(oop1, valuePointer1);
		}
		longAtput((oop1 + BaseHeaderSize) + (selectorIndex << ShiftForWord), valuePointer1);
		foo->argumentCount += 1;
		foo->newMethod = performMethod;
		foo->messageSelector = performSelector;
	}
}


/*	Common routine used by perform:withArgs: and perform:withArgs:inSuperclass: */
/*	NOTE:  The case of doesNotUnderstand: is not a failure to perform.
	The only failures are arg types and consistency of argumentCount. */

sqInt primitivePerformAt(sqInt lookupClass) {
register struct foo * foo = &fum;
    sqInt cntxSize;
    sqInt performArgCount;
    sqInt performSelector;
    sqInt arraySize;
    sqInt performMethod;
    sqInt argumentArray;
    sqInt index;
    sqInt sz;
    sqInt header;
    sqInt sz1;
    sqInt header1;
    sqInt sp;
    sqInt sp1;
    sqInt sp2;
    sqInt top;
    sqInt top1;

	argumentArray = longAt(foo->stackPointer);
	if (!(((argumentArray & 1) == 0) && (((((usqInt) (longAt(argumentArray))) >> 8) & 15) == 2))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (foo->successFlag) {
		/* begin fetchWordLengthOf: */
		/* begin sizeBitsOf: */
		header = longAt(argumentArray);
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(argumentArray - (BytesPerWord * 2))) & LongSizeMask;
			goto l1;
		} else {
			sz = header & SizeMask;
			goto l1;
		}
	l1:	/* end sizeBitsOf: */;
		arraySize = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
		/* begin fetchWordLengthOf: */
		/* begin sizeBitsOf: */
		header1 = longAt(foo->activeContext);
		if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
			sz1 = (longAt(foo->activeContext - (BytesPerWord * 2))) & LongSizeMask;
			goto l2;
		} else {
			sz1 = header1 & SizeMask;
			goto l2;
		}
	l2:	/* end sizeBitsOf: */;
		cntxSize = ((usqInt) (sz1 - BaseHeaderSize)) >> ShiftForWord;
		/* begin success: */
		foo->successFlag = (((((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) + arraySize) < cntxSize) && foo->successFlag;
	}
	if (!(foo->successFlag)) {
		return null;
	}
	performSelector = foo->messageSelector;
	performMethod = foo->newMethod;

	/* pop the arg array and the selector, then push the args out of the array, as if they were on the stack */

	performArgCount = foo->argumentCount;
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	foo->messageSelector = top1;
	index = 1;
	while (index <= arraySize) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, longAt((argumentArray + BaseHeaderSize) + ((index - 1) << ShiftForWord)));
		foo->stackPointer = sp;
		index += 1;
	}
	foo->argumentCount = arraySize;
	findNewMethodInClass(lookupClass);
	if (((((usqInt) (longAt(foo->newMethod))) >> 8) & 15) >= 12) {
		/* begin success: */
		foo->successFlag = (((((usqInt) (longAt((foo->newMethod + BaseHeaderSize) + (HeaderIndex << ShiftForWord)))) >> 25) & 15) == foo->argumentCount) && foo->successFlag;
	}
	if (foo->successFlag) {
		executeNewMethodFromCache();
		foo->successFlag = 1;
	} else {
		/* begin pop: */
		foo->stackPointer -= foo->argumentCount * BytesPerWord;
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->messageSelector);
		foo->stackPointer = sp1;
		/* begin push: */
		longAtput(sp2 = foo->stackPointer + BytesPerWord, argumentArray);
		foo->stackPointer = sp2;
		foo->messageSelector = performSelector;
		foo->newMethod = performMethod;
		foo->argumentCount = performArgCount;
	}
}

sqInt primitivePerformInSuperclass(void) {
register struct foo * foo = &fum;
    sqInt rcvr;
    sqInt currentClass;
    sqInt lookupClass;
    sqInt sp;
    sqInt top;
    sqInt ccIndex;

	lookupClass = longAt(foo->stackPointer);
	rcvr = longAt(foo->stackPointer - (foo->argumentCount * BytesPerWord));
	/* begin fetchClassOf: */
	if ((rcvr & 1)) {
		currentClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(rcvr))) >> 12) & 31;
	if (ccIndex == 0) {
		currentClass = (longAt(rcvr - BaseHeaderSize)) & AllButTypeMask;
		goto l1;
	} else {
		currentClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	while (currentClass != lookupClass) {
		currentClass = longAt((currentClass + BaseHeaderSize) + (SuperclassIndex << ShiftForWord));
		if (currentClass == foo->nilObj) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	primitivePerformAt(lookupClass);
	if (!(foo->successFlag)) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, lookupClass);
		foo->stackPointer = sp;
	}
}

sqInt primitivePerformWithArgs(void) {
register struct foo * foo = &fum;
    sqInt rcvr;
    sqInt lookupClass;
    sqInt ccIndex;

	rcvr = longAt(foo->stackPointer - (foo->argumentCount * BytesPerWord));
	/* begin fetchClassOf: */
	if ((rcvr & 1)) {
		lookupClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(rcvr))) >> 12) & 31;
	if (ccIndex == 0) {
		lookupClass = (longAt(rcvr - BaseHeaderSize)) & AllButTypeMask;
		goto l1;
	} else {
		lookupClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	primitivePerformAt(lookupClass);
}


/*	Answer a string corresponding to the version of the external platform source
	code, typically written in C and managed separately for each platform.
	This is a named (not numbered) primitive in the null module (ie the VM) */

EXPORT(sqInt) primitivePlatformSourceVersion(void) {
register struct foo * foo = &fum;
    void * p;
    sqInt versionString;
    sqInt len;
    sqInt sp;

	
# ifdef PLATFORM_SOURCE_VERSION  // version level of platform support code
	len = strlen(PLATFORM_SOURCE_VERSION);
	versionString = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassString << ShiftForWord)), len);
	/* begin arrayValueOf: */
	if ((!((versionString & 1))) && (((versionString & 1) == 0) && (isWordsOrBytesNonInt(versionString)))) {
		p = pointerForOop(versionString + BaseHeaderSize);
		goto l1;
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
l1:	/* end arrayValueOf: */;
	strncpy(p, PLATFORM_SOURCE_VERSION, len);
# else
	/* begin primitiveFail */
	foo->successFlag = 0;
	return null;
# endif  // PLATFORM_SOURCE_VERSION
	
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), versionString);
	foo->stackPointer = sp;
}

sqInt primitivePushFalse(void) {
register struct foo * foo = &fum;
    sqInt top;
    sqInt sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, foo->falseObj);
	foo->stackPointer = sp;
}

sqInt primitivePushMinusOne(void) {
register struct foo * foo = &fum;
    sqInt top;
    sqInt sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, ConstMinusOne);
	foo->stackPointer = sp;
}

sqInt primitivePushNil(void) {
register struct foo * foo = &fum;
    sqInt top;
    sqInt sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, foo->nilObj);
	foo->stackPointer = sp;
}

sqInt primitivePushOne(void) {
register struct foo * foo = &fum;
    sqInt top;
    sqInt sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, ConstOne);
	foo->stackPointer = sp;
}


/*		no-op, really...
	thisReceiver := self popStack.
	self push: thisReceiver
 */

sqInt primitivePushSelf(void) {
}

sqInt primitivePushTrue(void) {
register struct foo * foo = &fum;
    sqInt top;
    sqInt sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
	foo->stackPointer = sp;
}

sqInt primitivePushTwo(void) {
register struct foo * foo = &fum;
    sqInt top;
    sqInt sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, ConstTwo);
	foo->stackPointer = sp;
}

sqInt primitivePushZero(void) {
register struct foo * foo = &fum;
    sqInt top;
    sqInt sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, ConstZero);
	foo->stackPointer = sp;
}

sqInt primitiveQuit(void) {
	ioExit();
}


/*	Rounds negative results towards zero. */

sqInt primitiveQuo(void) {
register struct foo * foo = &fum;
    sqInt integerRcvr;
    sqInt integerResult;
    sqInt integerArg;
    sqInt integerPointer;
    sqInt integerPointer1;
    sqInt sp;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		integerRcvr = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerRcvr = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	/* begin stackIntegerValue: */
	integerPointer1 = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer1 & 1)) {
		integerArg = (integerPointer1 >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		integerArg = 0;
		goto l2;
	}
l2:	/* end checkedIntegerValueOf: */;
	/* begin success: */
	foo->successFlag = (integerArg != 0) && foo->successFlag;
	if (foo->successFlag) {
		if (integerRcvr > 0) {
			if (integerArg > 0) {
				integerResult = integerRcvr / integerArg;
			} else {
				integerResult = 0 - (integerRcvr / (0 - integerArg));
			}
		} else {
			if (integerArg > 0) {
				integerResult = 0 - ((0 - integerRcvr) / integerArg);
			} else {
				integerResult = (0 - integerRcvr) / (0 - integerArg);
			}
		}
	}
	/* begin pop2AndPushIntegerIfOK: */
	if (foo->successFlag) {
		if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
			(((((int) integerResult)) ^ ((((int) integerResult)) << 1)) >= 0)
# else
			((integerResult >= -1073741824) && (integerResult <= 1073741823))
# endif  // SQ_HOST32
		) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), ((integerResult << 1) | 1));
			foo->stackPointer = sp;
		} else {
			foo->successFlag = 0;
		}
	}
}


/*	Relinquish the processor for up to the given number of microseconds. The exact behavior of this primitive is platform dependent. */

sqInt primitiveRelinquishProcessor(void) {
register struct foo * foo = &fum;
    sqInt microSecs;
    sqInt integerPointer;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		microSecs = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		microSecs = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	if (foo->successFlag) {
		ioRelinquishProcessorForMicroseconds(microSecs);
		/* begin pop: */
		foo->stackPointer -= 1 * BytesPerWord;
	}
}


/*	NB: tpr removed the timer checks here and moved them to the primitiveExternalCall method.
	We make the possibly unwarranted assumption that numbered prims are quick and external prims are slow. */

sqInt primitiveResponse(void) {
register struct foo * foo = &fum;
    sqInt primIdx;
    sqInt nArgs;
    sqInt delta;

	if (DoBalanceChecks) {
		nArgs = foo->argumentCount;
		delta = foo->stackPointer - foo->activeContext;
	}
	primIdx = foo->primitiveIndex;

	/* self dispatchOn: primitiveIndex in: primitiveTable. */

	foo->successFlag = 1;
	dispatchFunctionPointerOnin(primIdx, primitiveTable);
	if (DoBalanceChecks) {
		if (!(balancedStackafterPrimitivewithArgs(delta, primIdx, nArgs))) {
			printUnbalancedStack(primIdx);
		}
	}

	/* clear out primIndex so VM knows we're no longer in primitive */

	foo->primitiveIndex = 0;
	return foo->successFlag;
}


/*	put this process on the scheduler's lists thus allowing it to proceed next time there is a chance for processes of it's priority level */

sqInt primitiveResume(void) {
register struct foo * foo = &fum;
    sqInt proc;


	/* rcvr */
	/* self success: ((self fetchClassOf: proc) = (self splObj: ClassProcess)). */

	proc = longAt(foo->stackPointer);
	if (foo->successFlag) {
		resume(proc);
	}
}


/*	Primitive. Answer a copy (snapshot) element of the root table.
	The primitive can cause GC itself and if so the return value may
	be inaccurate - in this case one should guard the read operation
	by looking at the gc counter statistics. */

EXPORT(sqInt) primitiveRootTable(void) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt sz;
    sqInt i;
    sqInt valuePointer;
    sqInt sp;

	sz = foo->rootTableCount;

	/* can cause GC */

	oop = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassArray << ShiftForWord)), sz);
	if (sz > foo->rootTableCount) {
		sz = foo->rootTableCount;
	}
	for (i = 1; i <= sz; i += 1) {
		/* begin storePointer:ofObject:withValue: */
		valuePointer = foo->rootTable[i];
		if ((((usqInt) oop)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(oop, valuePointer);
		}
		longAtput((oop + BaseHeaderSize) + ((i - 1) << ShiftForWord), valuePointer);
	}
	/* begin pop: */
	foo->stackPointer -= (foo->argumentCount + 1) * BytesPerWord;
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, oop);
	foo->stackPointer = sp;
}


/*	Primitive. Answer the nth element of the root table.
	This primitive avoids the creation of an extra array;
	it is intended for enumerations of the form:
		index := 1.
		[root := Smalltalk rootTableAt: index.
		root == nil] whileFalse:[index := index + 1].
	 */

EXPORT(sqInt) primitiveRootTableAt(void) {
register struct foo * foo = &fum;
    sqInt index;
    sqInt integerPointer;
    sqInt successValue;
    sqInt sp;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		index = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	/* begin success: */
	successValue = (index > 0) && (index <= foo->rootTableCount);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= (foo->argumentCount + 1) * BytesPerWord;
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, foo->rootTable[index]);
		foo->stackPointer = sp;
	}
}


/*	The character scanner primitive. */

sqInt primitiveScanCharacters(void) {
register struct foo * foo = &fum;
    sqInt scanStopIndex;
    sqInt sourceString;
    sqInt rcvr;
    sqInt glyphIndex;
    sqInt scanXTable;
    sqInt nextDestX;
    sqInt maxGlyph;
    sqInt scanStartIndex;
    sqInt scanLastIndex;
    sqInt scanRightX;
    sqInt kernDelta;
    sqInt scanMap;
    sqInt ascii;
    sqInt stops;
    sqInt nilOop;
    sqInt stopReason;
    sqInt scanDestX;
    sqInt sourceX;
    sqInt sourceX2;
    sqInt sp;
    sqInt sp1;
    sqInt integerPointer;
    sqInt oop;
    sqInt integerPointer1;
    sqInt oop1;
    sqInt integerPointer2;
    sqInt integerPointer3;
    sqInt oop2;
    sqInt sp2;

	if (!(foo->argumentCount == 6)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		kernDelta = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		kernDelta = 0;
		goto l1;
	}
	kernDelta = null;
l1:	/* end stackIntegerValue: */;
	/* begin stackObjectValue: */
	oop = longAt(foo->stackPointer - (1 * BytesPerWord));
	if ((oop & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		stops = null;
		goto l2;
	}
	stops = oop;
l2:	/* end stackObjectValue: */;
	if (!(((stops & 1) == 0) && (((((usqInt) (longAt(stops))) >> 8) & 15) == 2))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (!((slotSizeOf(stops)) >= 258)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackIntegerValue: */
	integerPointer1 = longAt(foo->stackPointer - (2 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer1 & 1)) {
		scanRightX = (integerPointer1 >> 1);
		goto l3;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		scanRightX = 0;
		goto l3;
	}
	scanRightX = null;
l3:	/* end stackIntegerValue: */;
	/* begin stackObjectValue: */
	oop1 = longAt(foo->stackPointer - (3 * BytesPerWord));
	if ((oop1 & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		sourceString = null;
		goto l4;
	}
	sourceString = oop1;
l4:	/* end stackObjectValue: */;
	if (!(((sourceString & 1) == 0) && (((((usqInt) (longAt(sourceString))) >> 8) & 15) >= 8))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackIntegerValue: */
	integerPointer2 = longAt(foo->stackPointer - (4 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer2 & 1)) {
		scanStopIndex = (integerPointer2 >> 1);
		goto l5;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		scanStopIndex = 0;
		goto l5;
	}
	scanStopIndex = null;
l5:	/* end stackIntegerValue: */;
	/* begin stackIntegerValue: */
	integerPointer3 = longAt(foo->stackPointer - (5 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer3 & 1)) {
		scanStartIndex = (integerPointer3 >> 1);
		goto l6;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		scanStartIndex = 0;
		goto l6;
	}
	scanStartIndex = null;
l6:	/* end stackIntegerValue: */;
	if (!((scanStartIndex > 0) && ((scanStopIndex > 0) && (scanStopIndex <= (byteSizeOf(sourceString)))))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackObjectValue: */
	oop2 = longAt(foo->stackPointer - (6 * BytesPerWord));
	if ((oop2 & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		rcvr = null;
		goto l7;
	}
	rcvr = oop2;
l7:	/* end stackObjectValue: */;
	if (!((((rcvr & 1) == 0) && (((((usqInt) (longAt(rcvr))) >> 8) & 15) <= 4)) && ((slotSizeOf(rcvr)) >= 4))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	scanDestX = fetchIntegerofObject(0, rcvr);
	scanLastIndex = fetchIntegerofObject(1, rcvr);
	scanXTable = longAt((rcvr + BaseHeaderSize) + (2 << ShiftForWord));
	scanMap = longAt((rcvr + BaseHeaderSize) + (3 << ShiftForWord));
	if (!((((scanXTable & 1) == 0) && (((((usqInt) (longAt(scanXTable))) >> 8) & 15) == 2)) && (((scanMap & 1) == 0) && (((((usqInt) (longAt(scanMap))) >> 8) & 15) == 2)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (!((slotSizeOf(scanMap)) == 256)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (!(foo->successFlag)) {
		return null;
	}

	/* Okay, here we go. We have eliminated nearly all failure 
	conditions, to optimize the inner fetches. */

	maxGlyph = (slotSizeOf(scanXTable)) - 2;
	scanLastIndex = scanStartIndex;
	nilOop = foo->nilObj;
	while (scanLastIndex <= scanStopIndex) {

		/* Known to be okay since stops size >= 258 */

		ascii = byteAt((sourceString + BaseHeaderSize) + (scanLastIndex - 1));
		if (!((stopReason = longAt((stops + BaseHeaderSize) + (ascii << ShiftForWord))) == nilOop)) {
			if (!(
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
				(((((int) scanDestX)) ^ ((((int) scanDestX)) << 1)) >= 0)
# else
				((scanDestX >= -1073741824) && (scanDestX <= 1073741823))
# endif  // SQ_HOST32
			)) {
				/* begin primitiveFail */
				foo->successFlag = 0;
				return null;
			}
			/* begin storeInteger:ofObject:withValue: */
			if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
				(((((int) scanDestX)) ^ ((((int) scanDestX)) << 1)) >= 0)
# else
				((scanDestX >= -1073741824) && (scanDestX <= 1073741823))
# endif  // SQ_HOST32
			) {
				longAtput((rcvr + BaseHeaderSize) + (0 << ShiftForWord), ((scanDestX << 1) | 1));
			} else {
				/* begin primitiveFail */
				foo->successFlag = 0;
			}
			/* begin storeInteger:ofObject:withValue: */
			if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
				(((((int) scanLastIndex)) ^ ((((int) scanLastIndex)) << 1)) >= 0)
# else
				((scanLastIndex >= -1073741824) && (scanLastIndex <= 1073741823))
# endif  // SQ_HOST32
			) {
				longAtput((rcvr + BaseHeaderSize) + (1 << ShiftForWord), ((scanLastIndex << 1) | 1));
			} else {
				/* begin primitiveFail */
				foo->successFlag = 0;
			}
			/* begin pop: */
			foo->stackPointer -= 7 * BytesPerWord;
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, stopReason);
			foo->stackPointer = sp;
			return null;
		}

		/* fail if the glyphIndex is out of range */

		glyphIndex = fetchIntegerofObject(ascii, scanMap);
		if ((!foo->successFlag) || ((glyphIndex < 0) || (glyphIndex > maxGlyph))) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
		sourceX = fetchIntegerofObject(glyphIndex, scanXTable);

		/* Above may fail if non-integer entries in scanXTable */

		sourceX2 = fetchIntegerofObject(glyphIndex + 1, scanXTable);
		if (!foo->successFlag) {
			return null;
		}
		nextDestX = (scanDestX + sourceX2) - sourceX;
		if (nextDestX > scanRightX) {
			if (!(
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
				(((((int) scanDestX)) ^ ((((int) scanDestX)) << 1)) >= 0)
# else
				((scanDestX >= -1073741824) && (scanDestX <= 1073741823))
# endif  // SQ_HOST32
			)) {
				/* begin primitiveFail */
				foo->successFlag = 0;
				return null;
			}
			/* begin storeInteger:ofObject:withValue: */
			if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
				(((((int) scanDestX)) ^ ((((int) scanDestX)) << 1)) >= 0)
# else
				((scanDestX >= -1073741824) && (scanDestX <= 1073741823))
# endif  // SQ_HOST32
			) {
				longAtput((rcvr + BaseHeaderSize) + (0 << ShiftForWord), ((scanDestX << 1) | 1));
			} else {
				/* begin primitiveFail */
				foo->successFlag = 0;
			}
			/* begin storeInteger:ofObject:withValue: */
			if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
				(((((int) scanLastIndex)) ^ ((((int) scanLastIndex)) << 1)) >= 0)
# else
				((scanLastIndex >= -1073741824) && (scanLastIndex <= 1073741823))
# endif  // SQ_HOST32
			) {
				longAtput((rcvr + BaseHeaderSize) + (1 << ShiftForWord), ((scanLastIndex << 1) | 1));
			} else {
				/* begin primitiveFail */
				foo->successFlag = 0;
			}
			/* begin pop: */
			foo->stackPointer -= 7 * BytesPerWord;
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, longAt((stops + BaseHeaderSize) + ((CrossedX - 1) << ShiftForWord)));
			foo->stackPointer = sp1;
			return null;
		}
		scanDestX = nextDestX + kernDelta;
		scanLastIndex += 1;
	}
	if (!(
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
		(((((int) scanDestX)) ^ ((((int) scanDestX)) << 1)) >= 0)
# else
		((scanDestX >= -1073741824) && (scanDestX <= 1073741823))
# endif  // SQ_HOST32
	)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin storeInteger:ofObject:withValue: */
	if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
		(((((int) scanDestX)) ^ ((((int) scanDestX)) << 1)) >= 0)
# else
		((scanDestX >= -1073741824) && (scanDestX <= 1073741823))
# endif  // SQ_HOST32
	) {
		longAtput((rcvr + BaseHeaderSize) + (0 << ShiftForWord), ((scanDestX << 1) | 1));
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
	}
	/* begin storeInteger:ofObject:withValue: */
	if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
		(((((int) scanStopIndex)) ^ ((((int) scanStopIndex)) << 1)) >= 0)
# else
		((scanStopIndex >= -1073741824) && (scanStopIndex <= 1073741823))
# endif  // SQ_HOST32
	) {
		longAtput((rcvr + BaseHeaderSize) + (1 << ShiftForWord), ((scanStopIndex << 1) | 1));
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
	}
	/* begin pop: */
	foo->stackPointer -= 7 * BytesPerWord;
	/* begin push: */
	longAtput(sp2 = foo->stackPointer + BytesPerWord, longAt((stops + BaseHeaderSize) + ((EndOfRun - 1) << ShiftForWord)));
	foo->stackPointer = sp2;
	return null;
}


/*	Return a SmallInteger indicating the current depth of the OS screen. Negative values are used to imply LSB type pixel format an there is some support in the VM for handling either MSB or LSB */

EXPORT(sqInt) primitiveScreenDepth(void) {
register struct foo * foo = &fum;
    sqInt depth;
    sqInt sp;

	depth = ioScreenDepth();
	if (!foo->successFlag) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin pop:thenPushInteger: */
	longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), ((depth << 1) | 1));
	foo->stackPointer = sp;
}


/*	Return a point indicating the current size of the Smalltalk window. Currently there is a limit of 65535 in each direction because the point is encoded into a single 32bit value in the image header. This might well become a problem one day */

sqInt primitiveScreenSize(void) {
register struct foo * foo = &fum;
    sqInt pointWord;
    sqInt object;
    sqInt sp;
    sqInt pointResult;

	/* begin pop: */
	foo->stackPointer -= 1 * BytesPerWord;
	pointWord = ioScreenSize();
	/* begin push: */
	/* begin makePointwithxValue:yValue: */
	pointResult = instantiateSmallClasssizeInBytes(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassPoint << ShiftForWord)), 3 * BytesPerWord);
	longAtput((pointResult + BaseHeaderSize) + (XIndex << ShiftForWord), ((((((usqInt) pointWord) >> 16) & 65535) << 1) | 1));
	longAtput((pointResult + BaseHeaderSize) + (YIndex << ShiftForWord), (((pointWord & 65535) << 1) | 1));
	object = pointResult;
	longAtput(sp = foo->stackPointer + BytesPerWord, object);
	foo->stackPointer = sp;
}


/*	Return the number of seconds since January 1, 1901 as an integer. */

sqInt primitiveSecondsClock(void) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt sp;

	/* begin pop:thenPush: */
	oop = positive32BitIntegerFor(ioSeconds());
	longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), oop);
	foo->stackPointer = sp;
}


/*	Set to OS to the requested display mode.
	See also DisplayScreen setDisplayDepth:extent:fullscreen: */

sqInt primitiveSetDisplayMode(void) {
register struct foo * foo = &fum;
    sqInt h;
    sqInt w;
    sqInt okay;
    sqInt fsFlag;
    sqInt d;
    sqInt integerPointer;
    sqInt integerPointer1;
    sqInt integerPointer2;
    sqInt sp;
    sqInt sp1;

	/* begin booleanValueOf: */
	if ((longAt(foo->stackPointer)) == foo->trueObj) {
		fsFlag = 1;
		goto l1;
	}
	if ((longAt(foo->stackPointer)) == foo->falseObj) {
		fsFlag = 0;
		goto l1;
	}
	foo->successFlag = 0;
	fsFlag = null;
l1:	/* end booleanValueOf: */;
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		h = (integerPointer >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		h = 0;
		goto l2;
	}
l2:	/* end checkedIntegerValueOf: */;
	/* begin stackIntegerValue: */
	integerPointer1 = longAt(foo->stackPointer - (2 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer1 & 1)) {
		w = (integerPointer1 >> 1);
		goto l3;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		w = 0;
		goto l3;
	}
l3:	/* end checkedIntegerValueOf: */;
	/* begin stackIntegerValue: */
	integerPointer2 = longAt(foo->stackPointer - (3 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer2 & 1)) {
		d = (integerPointer2 >> 1);
		goto l4;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		d = 0;
		goto l4;
	}
l4:	/* end checkedIntegerValueOf: */;
	if (foo->successFlag) {
		okay = ioSetDisplayMode(w, h, d, fsFlag);
	}
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 5 * BytesPerWord;
		/* begin pushBool: */
		if (okay) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}


/*	On platforms that support it, set full-screen mode to the value of the boolean argument. */

sqInt primitiveSetFullScreen(void) {
register struct foo * foo = &fum;
    sqInt argOop;

	argOop = longAt(foo->stackPointer);
	if (argOop == foo->trueObj) {
		ioSetFullScreen(1);
	} else {
		if (argOop == foo->falseObj) {
			ioSetFullScreen(0);
		} else {
			/* begin primitiveFail */
			foo->successFlag = 0;
		}
	}
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 1 * BytesPerWord;
	}
}


/*	Primitive. Indicate if the GC logic should have bias to grow */

EXPORT(sqInt) primitiveSetGCBiasToGrow(void) {
register struct foo * foo = &fum;
    sqInt flag;
    sqInt integerPointer;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		flag = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		flag = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	if (foo->successFlag) {
		foo->gcBiasToGrow = flag;
		/* begin pop: */
		foo->stackPointer -= foo->argumentCount * BytesPerWord;
	}
}


/*	Primitive. If the GC logic has  bias to grow, set growth limit */

EXPORT(sqInt) primitiveSetGCBiasToGrowGCLimit(void) {
register struct foo * foo = &fum;
    sqInt value;
    sqInt integerPointer;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		value = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		value = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	if (foo->successFlag) {
		foo->gcBiasToGrowGCLimit = value;
		foo->gcBiasToGrowThreshold = foo->youngStart - (((int) memory));
		/* begin pop: */
		foo->stackPointer -= foo->argumentCount * BytesPerWord;
	}
}


/*	Primitive. Indicate the semaphore to be signalled for upon garbage collection */

EXPORT(sqInt) primitiveSetGCSemaphore(void) {
register struct foo * foo = &fum;
    sqInt index;
    sqInt integerPointer;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		index = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	if (foo->successFlag) {
		foo->gcSemaphoreIndex = index;
		/* begin pop: */
		foo->stackPointer -= foo->argumentCount * BytesPerWord;
	}
}


/*	Set the user interrupt keycode. The keycode is an integer whose encoding is described in the comment for primitiveKbdNext. */

sqInt primitiveSetInterruptKey(void) {
register struct foo * foo = &fum;
    sqInt keycode;
    sqInt integerPointer;
    sqInt top;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer = top;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		keycode = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		keycode = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	if (foo->successFlag) {
		foo->interruptKeycode = keycode;
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
	}
}


/*	Treat the receiver, which can be indexible by either bytes or words, as an array of signed 16-bit values. Return the contents of the given index. Note that the index specifies the i-th 16-bit entry, not the i-th byte or word. */

sqInt primitiveShortAt(void) {
register struct foo * foo = &fum;
    sqInt value;
    sqInt rcvr;
    sqInt addr;
    sqInt sz;
    sqInt index;
    sqInt sp;
    sqInt integerPointer;
    sqInt successValue;
    sqInt successValue1;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		index = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	rcvr = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin success: */
	successValue = (!((rcvr & 1))) && (((rcvr & 1) == 0) && (isWordsOrBytesNonInt(rcvr)));
	foo->successFlag = successValue && foo->successFlag;
	if (!(foo->successFlag)) {
		return null;
	}

	/* number of 16-bit fields */

	sz = ((sqInt) ((sizeBitsOf(rcvr)) - BaseHeaderSize) >> 1);
	/* begin success: */
	successValue1 = (index >= 1) && (index <= sz);
	foo->successFlag = successValue1 && foo->successFlag;
	if (foo->successFlag) {
		addr = (rcvr + BaseHeaderSize) + (2 * (index - 1));
		value = shortAt(addr);
		/* begin pop:thenPushInteger: */
		longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), ((value << 1) | 1));
		foo->stackPointer = sp;
	}
}


/*	Treat the receiver, which can be indexible by either bytes or words, as an array of signed 16-bit values. Set the contents of the given index to the given value. Note that the index specifies the i-th 16-bit entry, not the i-th byte or word. */

sqInt primitiveShortAtPut(void) {
register struct foo * foo = &fum;
    sqInt value;
    sqInt rcvr;
    sqInt addr;
    sqInt sz;
    sqInt index;
    sqInt integerPointer;
    sqInt integerPointer1;
    sqInt successValue;
    sqInt successValue1;
    sqInt successValue2;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		value = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		value = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	/* begin stackIntegerValue: */
	integerPointer1 = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer1 & 1)) {
		index = (integerPointer1 >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l2;
	}
l2:	/* end checkedIntegerValueOf: */;
	rcvr = longAt(foo->stackPointer - (2 * BytesPerWord));
	/* begin success: */
	successValue = (!((rcvr & 1))) && (((rcvr & 1) == 0) && (isWordsOrBytesNonInt(rcvr)));
	foo->successFlag = successValue && foo->successFlag;
	if (!(foo->successFlag)) {
		return null;
	}

	/* number of 16-bit fields */

	sz = ((sqInt) ((sizeBitsOf(rcvr)) - BaseHeaderSize) >> 1);
	/* begin success: */
	successValue1 = (index >= 1) && (index <= sz);
	foo->successFlag = successValue1 && foo->successFlag;
	/* begin success: */
	successValue2 = (value >= -32768) && (value <= 32767);
	foo->successFlag = successValue2 && foo->successFlag;
	if (foo->successFlag) {
		addr = (rcvr + BaseHeaderSize) + (2 * (index - 1));
		shortAtput(addr, value);
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
	}
}


/*	Force the given rectangular section of the Display to be 
	copied to the screen. */

sqInt primitiveShowDisplayRect(void) {
register struct foo * foo = &fum;
    sqInt right;
    sqInt left;
    sqInt bottom;
    sqInt top;
    sqInt integerPointer;
    sqInt integerPointer1;
    sqInt integerPointer2;
    sqInt integerPointer3;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		bottom = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		bottom = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	/* begin stackIntegerValue: */
	integerPointer1 = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer1 & 1)) {
		top = (integerPointer1 >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		top = 0;
		goto l2;
	}
l2:	/* end checkedIntegerValueOf: */;
	/* begin stackIntegerValue: */
	integerPointer2 = longAt(foo->stackPointer - (2 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer2 & 1)) {
		right = (integerPointer2 >> 1);
		goto l3;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		right = 0;
		goto l3;
	}
l3:	/* end checkedIntegerValueOf: */;
	/* begin stackIntegerValue: */
	integerPointer3 = longAt(foo->stackPointer - (3 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer3 & 1)) {
		left = (integerPointer3 >> 1);
		goto l4;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		left = 0;
		goto l4;
	}
l4:	/* end checkedIntegerValueOf: */;
	displayBitsOfLeftTopRightBottom(longAt((foo->specialObjectsOop + BaseHeaderSize) + (TheDisplay << ShiftForWord)), left, top, right, bottom);
	if (foo->successFlag) {
		ioForceDisplayUpdate();
		/* begin pop: */
		foo->stackPointer -= 4 * BytesPerWord;
	}
}


/*	synchromously signal the semaphore. This may change the active process as a result */

sqInt primitiveSignal(void) {
register struct foo * foo = &fum;
    sqInt sema;
    sqInt ccIndex;
    sqInt cl;


	/* rcvr */

	sema = longAt(foo->stackPointer);
	/* begin assertClassOf:is: */
	if ((sema & 1)) {
		foo->successFlag = 0;
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(sema))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(sema - BaseHeaderSize)) & AllButTypeMask;
	} else {
		cl = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassSemaphore << ShiftForWord)))) && foo->successFlag;
l1:	/* end assertClassOf:is: */;
	if (foo->successFlag) {
		synchronousSignal(sema);
	}
}


/*	Set the low-water mark for free space. When the free space 
	falls below this level, the new and new: primitives fail and 
	system attempts to allocate space (e.g., to create a method 
	context) cause the low-space semaphore (if one is 
	registered) to be signalled. */

sqInt primitiveSignalAtBytesLeft(void) {
register struct foo * foo = &fum;
    sqInt bytes;
    sqInt integerPointer;
    sqInt top;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer = top;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		bytes = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		bytes = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	if (foo->successFlag) {
		foo->lowSpaceThreshold = bytes;
	} else {
		foo->lowSpaceThreshold = 0;
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
	}
}


/*	Cause the time semaphore, if one has been registered, to
	be signalled when the millisecond clock is greater than or
	equal to the given tick value. A tick value of zero turns off
	timer interrupts. */

sqInt primitiveSignalAtMilliseconds(void) {
register struct foo * foo = &fum;
    sqInt tick;
    sqInt sema;
    sqInt oop;
    sqInt oop1;
    sqInt valuePointer;
    sqInt integerPointer;
    sqInt top;
    sqInt top1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer = top;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		tick = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		tick = 0;
		goto l1;
	}
	tick = null;
l1:	/* end popInteger */;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	sema = top1;
	if (foo->successFlag) {
		if ((fetchClassOf(sema)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassSemaphore << ShiftForWord)))) {
			/* begin storePointer:ofObject:withValue: */
			oop = foo->specialObjectsOop;
			if ((((usqInt) oop)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(oop, sema);
			}
			longAtput((oop + BaseHeaderSize) + (TheTimerSemaphore << ShiftForWord), sema);
			foo->nextWakeupTick = tick;
		} else {
			/* begin storePointer:ofObject:withValue: */
			oop1 = foo->specialObjectsOop;
			valuePointer = foo->nilObj;
			if ((((usqInt) oop1)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(oop1, valuePointer);
			}
			longAtput((oop1 + BaseHeaderSize) + (TheTimerSemaphore << ShiftForWord), valuePointer);
			foo->nextWakeupTick = 0;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}

sqInt primitiveSine(void) {
register struct foo * foo = &fum;
    double  rcvr;

	rcvr = popFloat();
	if (foo->successFlag) {
		pushFloat(sin(rcvr));
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
	}
}

sqInt primitiveSize(void) {
register struct foo * foo = &fum;
    sqInt rcvr;
    sqInt sz;
    sqInt oop;
    sqInt sp;

	rcvr = longAt(foo->stackPointer);
	if ((rcvr & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (((((usqInt) (longAt(rcvr))) >> 8) & 15) < 2) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	sz = stSizeOf(rcvr);
	if (foo->successFlag) {
		/* begin pop:thenPush: */
		oop = positive32BitIntegerFor(sz);
		longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), oop);
		foo->stackPointer = sp;
	}
}


/*	save a normal snapshot under the same name as it was loaded unless it has been renamed by the last primitiveImageName */

sqInt primitiveSnapshot(void) {
	return snapshot(0);
}


/*	save an embedded snapshot */

sqInt primitiveSnapshotEmbedded(void) {
	return snapshot(1);
}

sqInt primitiveSomeInstance(void) {
register struct foo * foo = &fum;
    sqInt class;
    sqInt instance;
    sqInt sp;
    sqInt thisClass;
    sqInt thisObj;
    sqInt ccIndex;
    sqInt obj;
    sqInt sz;
    sqInt header;

	class = longAt(foo->stackPointer);
	/* begin initialInstanceOf: */
	/* begin firstAccessibleObject */
	obj = memory + (foo->headerTypeBytes[(longAt(memory)) & TypeMask]);
	while ((((usqInt) obj)) < (((usqInt) foo->endOfMemory))) {
		if (!(((longAt(obj)) & TypeMask) == HeaderTypeFree)) {
			thisObj = obj;
			goto l4;
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) obj)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(obj)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(obj)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(obj);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(obj - (BytesPerWord * 2))) & LongSizeMask;
				goto l3;
			} else {
				sz = header & SizeMask;
				goto l3;
			}
		l3:	/* end sizeBitsOf: */;
		}
		obj = (obj + sz) + (foo->headerTypeBytes[(longAt(obj + sz)) & TypeMask]);
	}
	error("heap is empty");
l4:	/* end firstAccessibleObject */;
	while (!(thisObj == null)) {
		/* begin fetchClassOf: */
		if ((thisObj & 1)) {
			thisClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
			goto l2;
		}
		ccIndex = (((usqInt) (longAt(thisObj))) >> 12) & 31;
		if (ccIndex == 0) {
			thisClass = (longAt(thisObj - BaseHeaderSize)) & AllButTypeMask;
			goto l2;
		} else {
			thisClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
			goto l2;
		}
	l2:	/* end fetchClassOf: */;
		if (thisClass == class) {
			instance = thisObj;
			goto l1;
		}
		thisObj = accessibleObjectAfter(thisObj);
	}
	instance = foo->nilObj;
l1:	/* end initialInstanceOf: */;
	if (instance == foo->nilObj) {
		/* begin primitiveFail */
		foo->successFlag = 0;
	} else {
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * BytesPerWord), instance);
		foo->stackPointer = sp;
	}
}


/*	Return the first object in the heap. */

sqInt primitiveSomeObject(void) {
register struct foo * foo = &fum;
    sqInt object;
    sqInt sp;
    sqInt obj;
    sqInt sz;
    sqInt header;

	/* begin pop: */
	foo->stackPointer -= (foo->argumentCount + 1) * BytesPerWord;
	/* begin push: */
	/* begin firstAccessibleObject */
	obj = memory + (foo->headerTypeBytes[(longAt(memory)) & TypeMask]);
	while ((((usqInt) obj)) < (((usqInt) foo->endOfMemory))) {
		if (!(((longAt(obj)) & TypeMask) == HeaderTypeFree)) {
			object = obj;
			goto l2;
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) obj)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(obj)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(obj)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(obj);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(obj - (BytesPerWord * 2))) & LongSizeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		obj = (obj + sz) + (foo->headerTypeBytes[(longAt(obj + sz)) & TypeMask]);
	}
	error("heap is empty");
l2:	/* end firstAccessibleObject */;
	longAtput(sp = foo->stackPointer + BytesPerWord, object);
	foo->stackPointer = sp;
}


/*	Return the oop of the SpecialObjectsArray. */

sqInt primitiveSpecialObjectsOop(void) {
register struct foo * foo = &fum;
    sqInt sp;

	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), foo->specialObjectsOop);
	foo->stackPointer = sp;
}

sqInt primitiveSquareRoot(void) {
register struct foo * foo = &fum;
    double  rcvr;

	rcvr = popFloat();
	/* begin success: */
	foo->successFlag = (rcvr >= 0.0) && foo->successFlag;
	if (foo->successFlag) {
		pushFloat(sqrt(rcvr));
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
	}
}


/*	This primitive is called from Squeak as...
		<imageSegment> storeSegmentFor: arrayOfRoots into: aWordArray outPointers: anArray. */
/*	This primitive will store a binary image segment (in the same format as the Squeak image file) of the receiver and every object in its proper tree of subParts (ie, that is not refered to from anywhere else outside the tree).  All pointers from within the tree to objects outside the tree will be copied into the array of outpointers.  In their place in the image segment will be an oop equal to the offset in the outPointer array (the first would be 4). but with the high bit set. */
/*	The primitive expects the array and wordArray to be more than adequately long.  In this case it returns normally, and truncates the two arrays to exactly the right size.  To simplify truncation, both incoming arrays are required to be 256 bytes or more long (ie with 3-word headers).  If either array is too small, the primitive will fail, but in no other case.

During operation of the primitive, it is necessary to convert from both internal and external oops to their mapped values.  To make this fast, the headers of the original objects in question are replaced by the mapped values (and this is noted by adding the forbidden XX header type).  Tables are kept of both kinds of oops, as well as of the original headers for restoration.

To be specific, there are two similar two-part tables, the outpointer array, and one in the upper fifth of the segmentWordArray.  Each grows oops from the bottom up, and preserved headers from halfway up.

In case of either success or failure, the headers must be restored.  In the event of primitive failure, the table of outpointers must also be nilled out (since the garbage in the high half will not have been discarded. */

sqInt primitiveStoreImageSegment(void) {
register struct foo * foo = &fum;
    usqInt hdrBaseIn;
    usqInt lastIn;
    usqInt firstIn;
    sqInt doingClass;
    sqInt versionOffset;
    usqInt firstOut;
    sqInt extraSize;
    sqInt arrayOfRoots;
    usqInt fieldPtr;
    sqInt fieldOop;
    usqInt lastOut;
    usqInt lastPtr;
    usqInt lastSeg;
    sqInt segmentWordArray;
    sqInt mapOop;
    sqInt hdrTypeBits;
    usqInt segOop;
    usqInt savedYoungStart;
    usqInt hdrBaseOut;
    sqInt outPointerArray;
    usqInt endSeg;
    sqInt header;
    sqInt i;
    sqInt lastAddr;
    sqInt i1;
    sqInt lastAddr1;
    sqInt i2;
    sqInt lastAddr2;
    sqInt i3;
    sqInt lastAddr3;
    sqInt out;
    sqInt lastIn1;
    sqInt in;
    sqInt out1;
    sqInt lastIn2;
    sqInt in1;
    sqInt sz;
    sqInt header1;

	outPointerArray = longAt(foo->stackPointer);
	segmentWordArray = longAt(foo->stackPointer - (1 * BytesPerWord));

	/* Essential type checks */

	arrayOfRoots = longAt(foo->stackPointer - (2 * BytesPerWord));
	if (!((((((usqInt) (longAt(arrayOfRoots))) >> 8) & 15) == 2) && ((((((usqInt) (longAt(outPointerArray))) >> 8) & 15) == 2) && (((((usqInt) (longAt(segmentWordArray))) >> 8) & 15) == 6)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (!((((longAt(outPointerArray)) & TypeMask) == HeaderTypeSizeAndClass) && (((longAt(segmentWordArray)) & TypeMask) == HeaderTypeSizeAndClass))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (DoAssertionChecks) {
		verifyCleanHeaders();
	}
	firstOut = outPointerArray + BaseHeaderSize;
	lastOut = firstOut - BytesPerWord;

	/* top half */

	hdrBaseOut = outPointerArray + (((lastPointerOf(outPointerArray)) / (BytesPerWord * 2)) * BytesPerWord);
	lastSeg = segmentWordArray;

	/* Write a version number for byte order and version check */

	endSeg = (segmentWordArray + (sizeBitsOf(segmentWordArray))) - BytesPerWord;
	versionOffset = BytesPerWord;
	lastSeg += versionOffset;
	if (lastSeg > endSeg) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	longAtput(lastSeg, imageSegmentVersion());

	/* Take 1/8 of seg */

	firstIn = endSeg - (((sizeBitsOf(segmentWordArray)) / (BytesPerWord * 8)) * BytesPerWord);
	lastIn = firstIn - BytesPerWord;

	/* top half of that */
	/* First mark the rootArray and all root objects. */

	hdrBaseIn = firstIn + (((sizeBitsOf(segmentWordArray)) / (BytesPerWord * 16)) * BytesPerWord);
	longAtput(arrayOfRoots, (longAt(arrayOfRoots)) | MarkBit);
	lastPtr = arrayOfRoots + (lastPointerOf(arrayOfRoots));
	fieldPtr = arrayOfRoots + BaseHeaderSize;
	while (fieldPtr <= lastPtr) {
		fieldOop = longAt(fieldPtr);
		if (!((fieldOop & 1))) {
			longAtput(fieldOop, (longAt(fieldOop)) | MarkBit);
		}
		fieldPtr += BytesPerWord;
	}
	savedYoungStart = foo->youngStart;

	/* process all of memory */
	/* clear the recycled context lists */

	foo->youngStart = memory;
	foo->freeContexts = NilContext;
	foo->freeLargeContexts = NilContext;
	markAndTraceInterpreterOops();

	/* Finally unmark the rootArray and all root objects. */

	foo->youngStart = savedYoungStart;
	longAtput(arrayOfRoots, (longAt(arrayOfRoots)) & AllButMarkBit);
	fieldPtr = arrayOfRoots + BaseHeaderSize;
	while (fieldPtr <= lastPtr) {
		fieldOop = longAt(fieldPtr);
		if (!((fieldOop & 1))) {
			longAtput(fieldOop, (longAt(fieldOop)) & AllButMarkBit);
		}
		fieldPtr += BytesPerWord;
	}
	lastIn += BytesPerWord;
	if (lastIn >= hdrBaseIn) {
		foo->successFlag = 0;
	}
	lastSeg = copyObjtoSegmentaddrstopAtsaveOopAtheaderAt(arrayOfRoots, segmentWordArray, lastSeg, firstIn, lastIn, hdrBaseIn + (lastIn - firstIn));
	if (!(foo->successFlag)) {
		lastIn -= BytesPerWord;
		restoreHeadersFromtofromandtofrom(firstIn, lastIn, hdrBaseIn, firstOut, lastOut, hdrBaseOut);
		/* begin primitiveFailAfterCleanup: */
		lastAddr = outPointerArray + (lastPointerOf(outPointerArray));
		i = outPointerArray + BaseHeaderSize;
		while (i <= lastAddr) {
			longAtput(i, foo->nilObj);
			i += BytesPerWord;
		}
		if (DoAssertionChecks) {
			verifyCleanHeaders();
		}
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	segOop = ((segmentWordArray + versionOffset) + BaseHeaderSize) + (foo->headerTypeBytes[(longAt((segmentWordArray + versionOffset) + BaseHeaderSize)) & TypeMask]);
	while (segOop <= lastSeg) {
		if (((longAt(segOop)) & TypeMask) <= 1) {
			fieldPtr = segOop - BytesPerWord;
			doingClass = 1;
		} else {
			fieldPtr = segOop + BaseHeaderSize;
			doingClass = 0;
		}

		/* last field */
		/* Go through all oops, remapping them... */

		lastPtr = segOop + (lastPointerOf(segOop));
		while (!(fieldPtr > lastPtr)) {
			fieldOop = longAt(fieldPtr);
			if (doingClass) {
				hdrTypeBits = fieldOop & TypeMask;
				fieldOop -= hdrTypeBits;
			}
			if ((fieldOop & 1)) {
				fieldPtr += BytesPerWord;
			} else {
				header = longAt(fieldOop);
				if ((header & TypeMask) == HeaderTypeFree) {
					mapOop = header & AllButTypeMask;
				} else {
					if (((longAt(fieldOop)) & MarkBit) == 0) {
						lastIn += BytesPerWord;
						if (lastIn >= hdrBaseIn) {
							foo->successFlag = 0;
						}
						lastSeg = copyObjtoSegmentaddrstopAtsaveOopAtheaderAt(fieldOop, segmentWordArray, lastSeg, firstIn, lastIn, hdrBaseIn + (lastIn - firstIn));
						if (!(foo->successFlag)) {
							lastIn -= BytesPerWord;
							restoreHeadersFromtofromandtofrom(firstIn, lastIn, hdrBaseIn, firstOut, lastOut, hdrBaseOut);
							/* begin primitiveFailAfterCleanup: */
							lastAddr1 = outPointerArray + (lastPointerOf(outPointerArray));
							i1 = outPointerArray + BaseHeaderSize;
							while (i1 <= lastAddr1) {
								longAtput(i1, foo->nilObj);
								i1 += BytesPerWord;
							}
							if (DoAssertionChecks) {
								verifyCleanHeaders();
							}
							/* begin primitiveFail */
							foo->successFlag = 0;
							return null;
						}
						mapOop = (longAt(fieldOop)) & AllButTypeMask;
					} else {
						lastOut += BytesPerWord;
						if (lastOut >= hdrBaseOut) {
							lastOut -= BytesPerWord;
							restoreHeadersFromtofromandtofrom(firstIn, lastIn, hdrBaseIn, firstOut, lastOut, hdrBaseOut);
							/* begin primitiveFailAfterCleanup: */
							lastAddr2 = outPointerArray + (lastPointerOf(outPointerArray));
							i2 = outPointerArray + BaseHeaderSize;
							while (i2 <= lastAddr2) {
								longAtput(i2, foo->nilObj);
								i2 += BytesPerWord;
							}
							if (DoAssertionChecks) {
								verifyCleanHeaders();
							}
							/* begin primitiveFail */
							foo->successFlag = 0;
							return null;
						}
						mapOop = (lastOut - outPointerArray) | 2147483648U;
						/* begin forward:to:savingOopAt:andHeaderAt: */
						longAtput(lastOut, fieldOop);
						longAtput(hdrBaseOut + (lastOut - firstOut), longAt(fieldOop));
						longAtput(fieldOop, mapOop + HeaderTypeFree);
					}
				}
				if (doingClass) {
					longAtput(fieldPtr, mapOop + hdrTypeBits);
					fieldPtr += BytesPerWord * 2;
					doingClass = 0;
				} else {
					longAtput(fieldPtr, mapOop);
					fieldPtr += BytesPerWord;
				}
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) segOop)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(segOop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(segOop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header1 = longAt(segOop);
			if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(segOop - (BytesPerWord * 2))) & LongSizeMask;
				goto l1;
			} else {
				sz = header1 & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		segOop = (segOop + sz) + (foo->headerTypeBytes[(longAt(segOop + sz)) & TypeMask]);
	}
	restoreHeadersFromtofromandtofrom(firstIn, lastIn, hdrBaseIn, firstOut, lastOut, hdrBaseOut);
	if ((((outPointerArray + (lastPointerOf(outPointerArray))) - lastOut) < 12) || ((endSeg - lastSeg) < 12)) {
		/* begin primitiveFailAfterCleanup: */
		lastAddr3 = outPointerArray + (lastPointerOf(outPointerArray));
		i3 = outPointerArray + BaseHeaderSize;
		while (i3 <= lastAddr3) {
			longAtput(i3, foo->nilObj);
			i3 += BytesPerWord;
		}
		if (DoAssertionChecks) {
			verifyCleanHeaders();
		}
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	extraSize = foo->headerTypeBytes[(longAt(segmentWordArray)) & TypeMask];

	/* Copy the 3-word wordArray header to establish a free chunk. */

	hdrTypeBits = (longAt(segmentWordArray)) & TypeMask;
	/* begin transfer:from:to: */
	flag("Dan");
	in = (segmentWordArray - extraSize) - BytesPerWord;
	lastIn1 = in + (3 * BytesPerWord);
	out = (lastOut + BytesPerWord) - BytesPerWord;
	while ((((usqInt) in)) < (((usqInt) lastIn1))) {
		longAtput(out += BytesPerWord, longAt(in += BytesPerWord));
	}
	longAtput(lastOut + BytesPerWord, (((outPointerArray + (lastPointerOf(outPointerArray))) - lastOut) - extraSize) + hdrTypeBits);
	longAtput(outPointerArray - extraSize, ((lastOut - firstOut) + (BytesPerWord * 2)) + hdrTypeBits);
	beRootIfOld(outPointerArray);
	/* begin transfer:from:to: */
	flag("Dan");
	in1 = (segmentWordArray - extraSize) - BytesPerWord;
	lastIn2 = in1 + (3 * BytesPerWord);
	out1 = (lastSeg + BytesPerWord) - BytesPerWord;
	while ((((usqInt) in1)) < (((usqInt) lastIn2))) {
		longAtput(out1 += BytesPerWord, longAt(in1 += BytesPerWord));
	}
	longAtput(segmentWordArray - extraSize, ((lastSeg - segmentWordArray) + BaseHeaderSize) + hdrTypeBits);
	longAtput(lastSeg + BytesPerWord, ((endSeg - lastSeg) - extraSize) + hdrTypeBits);
	if (DoAssertionChecks) {
		verifyCleanHeaders();
	}
	/* begin pop: */
	foo->stackPointer -= 3 * BytesPerWord;
}


/*	Atomic store into context stackPointer. 
	Also ensures that any newly accessible cells are initialized to nil  */

sqInt primitiveStoreStackp(void) {
register struct foo * foo = &fum;
    sqInt stackp;
    sqInt ctxt;
    sqInt newStackp;
    sqInt i;
    sqInt valuePointer;
    sqInt integerPointer;
    sqInt sp;

	ctxt = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		newStackp = (integerPointer >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		newStackp = 0;
		goto l2;
	}
l2:	/* end checkedIntegerValueOf: */;
	/* begin success: */
	foo->successFlag = ((((usqInt) newStackp)) >= (((usqInt) 0))) && foo->successFlag;
	/* begin success: */
	foo->successFlag = ((((usqInt) newStackp)) <= (((usqInt) ((((sqInt) (LargeContextSize - BaseHeaderSize) >> 2)) - CtxtTempFrameStart)))) && foo->successFlag;
	if (!(foo->successFlag)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin fetchStackPointerOf: */
	sp = longAt((ctxt + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
	if (!((sp & 1))) {
		stackp = 0;
		goto l1;
	}
	stackp = (sp >> 1);
l1:	/* end fetchStackPointerOf: */;
	if ((((usqInt) newStackp)) > (((usqInt) stackp))) {
		for (i = (stackp + 1); i <= newStackp; i += 1) {
			/* begin storePointer:ofObject:withValue: */
			valuePointer = foo->nilObj;
			if ((((usqInt) ctxt)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(ctxt, valuePointer);
			}
			longAtput((ctxt + BaseHeaderSize) + (((i + CtxtTempFrameStart) - 1) << ShiftForWord), valuePointer);
		}
	}
	/* begin storeStackPointerValue:inContext: */
	longAtput((ctxt + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), ((newStackp << 1) | 1));
	/* begin pop: */
	foo->stackPointer -= 1 * BytesPerWord;
}

sqInt primitiveStringAt(void) {
	commonAt(1);
}

sqInt primitiveStringAtPut(void) {
	commonAtPut(1);
}


/*	 
	<array> primReplaceFrom: start to: stop with: replacement 
	startingAt: repStart  
	<primitive: 105>
	 */

sqInt primitiveStringReplace(void) {
register struct foo * foo = &fum;
    sqInt stop;
    sqInt replInstSize;
    sqInt srcIndex;
    sqInt array;
    sqInt arrayInstSize;
    sqInt replFmt;
    sqInt repl;
    sqInt totalLength;
    sqInt replStart;
    sqInt start;
    sqInt arrayFmt;
    sqInt hdr;
    sqInt i;
    sqInt valueWord;
    sqInt integerPointer;
    sqInt integerPointer1;
    sqInt integerPointer2;
    sqInt sz;
    sqInt class;
    sqInt classFormat;
    sqInt sz1;
    sqInt class1;
    sqInt classFormat1;
    sqInt ccIndex;
    sqInt ccIndex1;

	array = longAt(foo->stackPointer - (4 * BytesPerWord));
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (3 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		start = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		start = 0;
		goto l1;
	}
	start = null;
l1:	/* end stackIntegerValue: */;
	/* begin stackIntegerValue: */
	integerPointer1 = longAt(foo->stackPointer - (2 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer1 & 1)) {
		stop = (integerPointer1 >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		stop = 0;
		goto l2;
	}
	stop = null;
l2:	/* end stackIntegerValue: */;
	repl = longAt(foo->stackPointer - (1 * BytesPerWord));
	/* begin stackIntegerValue: */
	integerPointer2 = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer2 & 1)) {
		replStart = (integerPointer2 >> 1);
		goto l3;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		replStart = 0;
		goto l3;
	}
	replStart = null;
l3:	/* end stackIntegerValue: */;
	if (!(foo->successFlag)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if ((repl & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	hdr = longAt(array);
	arrayFmt = (((usqInt) hdr) >> 8) & 15;
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(array - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz = hdr & SizeMask;
	}
	sz -= hdr & Size4Bit;
	if (arrayFmt <= 4) {
		totalLength = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
		goto l4;
	}
	if (arrayFmt < 8) {
		totalLength = ((usqInt) (sz - BaseHeaderSize)) >> 2;
		goto l4;
	} else {
		totalLength = (sz - BaseHeaderSize) - (arrayFmt & 3);
		goto l4;
	}
l4:	/* end lengthOf:baseHeader:format: */;
	/* begin fixedFieldsOf:format:length: */
	if ((arrayFmt > 4) || (arrayFmt == 2)) {
		arrayInstSize = 0;
		goto l5;
	}
	if (arrayFmt < 2) {
		arrayInstSize = totalLength;
		goto l5;
	}
	/* begin fetchClassOf: */
	if ((array & 1)) {
		class = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l8;
	}
	ccIndex = (((usqInt) (longAt(array))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(array - BaseHeaderSize)) & AllButTypeMask;
		goto l8;
	} else {
		class = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l8;
	}
l8:	/* end fetchClassOf: */;
	classFormat = (longAt((class + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1;
	arrayInstSize = (((((usqInt) classFormat) >> 11) & 192) + ((((usqInt) classFormat) >> 2) & 63)) - 1;
l5:	/* end fixedFieldsOf:format:length: */;
	if (!((start >= 1) && (((start - 1) <= stop) && ((stop + arrayInstSize) <= totalLength)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	hdr = longAt(repl);
	replFmt = (((usqInt) hdr) >> 8) & 15;
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(repl - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz1 = hdr & SizeMask;
	}
	sz1 -= hdr & Size4Bit;
	if (replFmt <= 4) {
		totalLength = ((usqInt) (sz1 - BaseHeaderSize)) >> ShiftForWord;
		goto l6;
	}
	if (replFmt < 8) {
		totalLength = ((usqInt) (sz1 - BaseHeaderSize)) >> 2;
		goto l6;
	} else {
		totalLength = (sz1 - BaseHeaderSize) - (replFmt & 3);
		goto l6;
	}
l6:	/* end lengthOf:baseHeader:format: */;
	/* begin fixedFieldsOf:format:length: */
	if ((replFmt > 4) || (replFmt == 2)) {
		replInstSize = 0;
		goto l7;
	}
	if (replFmt < 2) {
		replInstSize = totalLength;
		goto l7;
	}
	/* begin fetchClassOf: */
	if ((repl & 1)) {
		class1 = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l9;
	}
	ccIndex1 = (((usqInt) (longAt(repl))) >> 12) & 31;
	if (ccIndex1 == 0) {
		class1 = (longAt(repl - BaseHeaderSize)) & AllButTypeMask;
		goto l9;
	} else {
		class1 = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex1 - 1) << ShiftForWord));
		goto l9;
	}
l9:	/* end fetchClassOf: */;
	classFormat1 = (longAt((class1 + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1;
	replInstSize = (((((usqInt) classFormat1) >> 11) & 192) + ((((usqInt) classFormat1) >> 2) & 63)) - 1;
l7:	/* end fixedFieldsOf:format:length: */;
	if (!((replStart >= 1) && ((((stop - start) + replStart) + replInstSize) <= totalLength))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (arrayFmt < 8) {
		if (!(arrayFmt == replFmt)) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	} else {
		if (!((arrayFmt & 12) == (replFmt & 12))) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}

	/* - 1 for 0-based access */

	srcIndex = (replStart + replInstSize) - 1;
	if (arrayFmt <= 4) {
		for (i = ((start + arrayInstSize) - 1); i <= ((stop + arrayInstSize) - 1); i += 1) {
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) array)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(array, longAt((repl + BaseHeaderSize) + (srcIndex << ShiftForWord)));
			}
			longAtput((array + BaseHeaderSize) + (i << ShiftForWord), longAt((repl + BaseHeaderSize) + (srcIndex << ShiftForWord)));
			srcIndex += 1;
		}
	} else {
		if (arrayFmt < 8) {
			for (i = ((start + arrayInstSize) - 1); i <= ((stop + arrayInstSize) - 1); i += 1) {
				/* begin storeLong32:ofObject:withValue: */
				valueWord = long32At((repl + BaseHeaderSize) + (srcIndex << 2));
				long32Atput((array + BaseHeaderSize) + (i << 2), valueWord);
				srcIndex += 1;
			}
		} else {
			for (i = ((start + arrayInstSize) - 1); i <= ((stop + arrayInstSize) - 1); i += 1) {
				byteAtput((array + BaseHeaderSize) + i, byteAt((repl + BaseHeaderSize) + srcIndex));
				srcIndex += 1;
			}
		}
	}
	/* begin pop: */
	foo->stackPointer -= foo->argumentCount * BytesPerWord;
}

sqInt primitiveSubtract(void) {
register struct foo * foo = &fum;
    sqInt integerResult;
    sqInt sp;

	/* begin pop2AndPushIntegerIfOK: */
	integerResult = (stackIntegerValue(1)) - (stackIntegerValue(0));
	if (foo->successFlag) {
		if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
			(((((int) integerResult)) ^ ((((int) integerResult)) << 1)) >= 0)
# else
			((integerResult >= -1073741824) && (integerResult <= 1073741823))
# endif  // SQ_HOST32
		) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - ((2 - 1) * BytesPerWord), ((integerResult << 1) | 1));
			foo->stackPointer = sp;
		} else {
			foo->successFlag = 0;
		}
	}
}

sqInt primitiveSuspend(void) {
register struct foo * foo = &fum;
    sqInt activeProc;
    sqInt sp;

	activeProc = longAt(((longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord))) + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
	/* begin success: */
	foo->successFlag = ((longAt(foo->stackPointer)) == activeProc) && foo->successFlag;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 1 * BytesPerWord;
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, foo->nilObj);
		foo->stackPointer = sp;
		transferTo(wakeHighestPriority());
	}
}


/*	Primitive. Terminate up the context stack from the receiver up to but not including the argument, if previousContext is on my Context stack. Make previousContext my sender. This prim has to shadow the code in ContextPart>terminateTo: to be correct */

sqInt primitiveTerminateTo(void) {
register struct foo * foo = &fum;
    sqInt nextCntx;
    sqInt aContext;
    sqInt currentCntx;
    sqInt thisCntx;
    sqInt nilOop;
    sqInt top;
    sqInt top1;
    sqInt sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	aContext = top;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	thisCntx = top1;
	if (contexthasSender(thisCntx, aContext)) {
		nilOop = foo->nilObj;
		currentCntx = longAt((thisCntx + BaseHeaderSize) + (SenderIndex << ShiftForWord));
		while (!(currentCntx == aContext)) {
			nextCntx = longAt((currentCntx + BaseHeaderSize) + (SenderIndex << ShiftForWord));
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) currentCntx)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(currentCntx, nilOop);
			}
			longAtput((currentCntx + BaseHeaderSize) + (SenderIndex << ShiftForWord), nilOop);
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) currentCntx)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(currentCntx, nilOop);
			}
			longAtput((currentCntx + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), nilOop);
			currentCntx = nextCntx;
		}
	}
	/* begin storePointer:ofObject:withValue: */
	if ((((usqInt) thisCntx)) < (((usqInt) foo->youngStart))) {
		possibleRootStoreIntovalue(thisCntx, aContext);
	}
	longAtput((thisCntx + BaseHeaderSize) + (SenderIndex << ShiftForWord), aContext);
	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, thisCntx);
	foo->stackPointer = sp;
	return null;
}


/*	Return true if the host OS does support the given display depth. */

sqInt primitiveTestDisplayDepth(void) {
register struct foo * foo = &fum;
    sqInt okay;
    sqInt bitsPerPixel;
    sqInt integerPointer;
    sqInt sp;
    sqInt sp1;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		bitsPerPixel = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		bitsPerPixel = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	if (foo->successFlag) {
		okay = ioHasDisplayDepth(bitsPerPixel);
	}
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * BytesPerWord;
		/* begin pushBool: */
		if (okay) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

sqInt primitiveTimesTwoPower(void) {
register struct foo * foo = &fum;
    double  rcvr;
    sqInt arg;
    sqInt integerPointer;
    sqInt top;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	integerPointer = top;
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		arg = (integerPointer >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		arg = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	rcvr = popFloat();
	if (foo->successFlag) {
		pushFloat(ldexp(rcvr, arg));
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}

sqInt primitiveTruncated(void) {
register struct foo * foo = &fum;
    double  rcvr;
    double  trunc;
    double  frac;
    sqInt successValue;
    sqInt sp;

	rcvr = popFloat();
	if (foo->successFlag) {
		frac = modf(rcvr, &trunc);
		flag("Dan");
		success((-1073741824.0 <= trunc) && (trunc <= 1073741823.0));
	}
	if (foo->successFlag) {
		pushInteger((sqInt) trunc);
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * BytesPerWord;
	}
}


/*	Primitive. Unload the module with the given name. */
/*	Reloading of the module will happen *later* automatically, when a 
	function from it is called. This is ensured by invalidating current sessionID. */

sqInt primitiveUnloadModule(void) {
register struct foo * foo = &fum;
    sqInt moduleName;

	if (!(foo->argumentCount == 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	moduleName = longAt(foo->stackPointer);
	if ((moduleName & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (!(((moduleName & 1) == 0) && (((((usqInt) (longAt(moduleName))) >> 8) & 15) >= 8))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (!(ioUnloadModuleOfLength(oopForPointer(firstIndexableField(moduleName)), byteSizeOf(moduleName)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	flushExternalPrimitives();
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
	foo->nextPollTick = 0;
	/* begin pop: */
	foo->stackPointer -= 1 * BytesPerWord;
}


/*	Answer an array with UTC mocroseconds since the Posix epoch and tthe
	current seconds offset from GMT in the local time zone.
	This is a named (not numbered) primitive in the null module (ie the VM) */

EXPORT(sqInt) primitiveUtcWithOffset(void) {
register struct foo * foo = &fum;
    int offset;
    sqInt resultArray;
    sqLong clock;
    sqInt oop;
    sqInt sp;

	if ((ioUtcWithOffset(&clock, &offset)) == -1) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin pushRemappableOop: */
	oop = positive64BitIntegerFor(clock);
	foo->remapBuffer[foo->remapBufferCount += 1] = oop;
	resultArray = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassArray << ShiftForWord)), 2);
	stObjectatput(resultArray, 1, popRemappableOop());
	stObjectatput(resultArray, 2, ((offset << 1) | 1));
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), resultArray);
	foo->stackPointer = sp;
}


/*	Behaviour depends on argument count:
		0 args:	return an Array of VM parameter values;
		1 arg:	return the indicated VM parameter;
		2 args:	set the VM indicated parameter.
	VM parameters are numbered as follows:
		1	end of old-space (0-based, read-only)
		2	end of young-space (read-only)
		3	end of memory (read-only)
		4	allocationCount (read-only)
		5	allocations between GCs (read-write)
		6	survivor count tenuring threshold (read-write)
		7	full GCs since startup (read-only)
		8	total milliseconds in full GCs since startup (read-only)
		9	incremental GCs since startup (read-only)
		10	total milliseconds in incremental GCs since startup (read-only)
		11	tenures of surving objects since startup (read-only)
		12-20 specific to the translating VM
		21	root table size (read-only)
		22	root table overflows since startup (read-only)
		23	bytes of extra memory to reserve for VM buffers, plugins, etc.
		24	memory threshold above which shrinking object memory (rw)
		25	memory headroom when growing object memory (rw)
		26  interruptChecksEveryNms - force an ioProcessEvents every N milliseconds, in case the image  is not calling getNextEvent often (rw)
		27	number of times mark loop iterated for current IGC/FGC (read-only) includes ALL marking
		28	number of times sweep loop iterated  for current IGC/FGC (read-only)
		29	number of times make forward loop iterated for current IGC/FGC (read-only)
		30	number of times compact move loop iterated for current IGC/FGC (read-only)
		31	number of grow memory requests (read-only)
		32	number of shrink memory requests (read-only)
		33	number of root table entries used for current IGC/FGC (read-only)
		34	number of allocations done before current IGC/FGC (read-only)
		35	number of survivor objects after current IGC/FGC (read-only)
		36  millisecond clock when current IGC/FGC completed (read-only)
		37  number of marked objects for Roots of the world, not including Root Table entries for current IGC/FGC (read-only)
		38  milliseconds taken by current IGC  (read-only)
		39  Number of finalization signals for Weak Objects pending when current IGC/FGC completed (read-only)
		40 BytesPerWord for this image
		
	Note: Thanks to Ian Piumarta for this primitive. */

sqInt primitiveVMParameter(void) {
register struct foo * foo = &fum;
    sqInt statIGCDeltaTimeObj;
    sqInt statIncrGCMSecsObj;
    sqInt mem;
    sqInt statGCTimeObj;
    sqInt arg;
    sqInt result;
    sqInt paramsArraySize;
    sqLong resultLargePositiveInteger;
    sqInt index;
    sqInt i;
    sqInt statFullGCMSecsObj;
    sqInt oop;
    sqInt oop1;
    sqInt oop2;
    sqInt oop3;
    sqInt oop4;
    sqInt oop5;
    sqInt oop6;
    sqInt oop7;
    sqInt oop8;
    sqInt valuePointer;
    sqInt valuePointer1;
    sqInt valuePointer2;
    sqInt valuePointer3;
    sqInt valuePointer4;
    sqInt valuePointer5;
    sqInt valuePointer6;
    sqInt valuePointer7;
    sqInt valuePointer8;
    sqInt valuePointer9;
    sqInt valuePointer10;
    sqInt valuePointer11;
    sqInt valuePointer12;
    sqInt valuePointer13;
    sqInt valuePointer14;
    sqInt valuePointer15;
    sqInt valuePointer16;
    sqInt valuePointer17;
    sqInt valuePointer18;
    sqInt valuePointer19;
    sqInt valuePointer20;
    sqInt valuePointer21;
    sqInt valuePointer22;
    sqInt valuePointer23;
    sqInt valuePointer24;
    sqInt valuePointer25;
    sqInt sp;
    sqInt sp1;
    sqInt oop9;
    sqInt sp2;
    sqInt sp3;

	mem = memory;
	paramsArraySize = 40;
	if (foo->argumentCount == 0) {
		result = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassArray << ShiftForWord)), paramsArraySize);
		/* begin pushRemappableOop: */
		foo->remapBuffer[foo->remapBufferCount += 1] = result;
		/* begin pushRemappableOop: */
		oop = positive64BitIntegerFor(foo->statFullGCMSecs);
		foo->remapBuffer[foo->remapBufferCount += 1] = oop;
		/* begin pushRemappableOop: */
		oop1 = positive64BitIntegerFor(foo->statIncrGCMSecs);
		foo->remapBuffer[foo->remapBufferCount += 1] = oop1;
		/* begin pushRemappableOop: */
		oop2 = positive64BitIntegerFor(foo->statGCTime);
		foo->remapBuffer[foo->remapBufferCount += 1] = oop2;
		/* begin pushRemappableOop: */
		oop3 = positive64BitIntegerFor(foo->statIGCDeltaTime);
		foo->remapBuffer[foo->remapBufferCount += 1] = oop3;
		/* begin popRemappableOop */
		oop4 = foo->remapBuffer[foo->remapBufferCount];
		foo->remapBufferCount -= 1;
		statIGCDeltaTimeObj = oop4;
		/* begin popRemappableOop */
		oop5 = foo->remapBuffer[foo->remapBufferCount];
		foo->remapBufferCount -= 1;
		statGCTimeObj = oop5;
		/* begin popRemappableOop */
		oop6 = foo->remapBuffer[foo->remapBufferCount];
		foo->remapBufferCount -= 1;
		statIncrGCMSecsObj = oop6;
		/* begin popRemappableOop */
		oop7 = foo->remapBuffer[foo->remapBufferCount];
		foo->remapBufferCount -= 1;
		statFullGCMSecsObj = oop7;
		/* begin popRemappableOop */
		oop8 = foo->remapBuffer[foo->remapBufferCount];
		foo->remapBufferCount -= 1;
		result = oop8;
		for (i = 0; i <= (paramsArraySize - 1); i += 1) {
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(result, ConstZero);
			}
			longAtput((result + BaseHeaderSize) + (i << ShiftForWord), ConstZero);
		}
		/* begin storePointer:ofObject:withValue: */
		valuePointer = (((foo->youngStart - mem) << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer);
		}
		longAtput((result + BaseHeaderSize) + (0 << ShiftForWord), valuePointer);
		/* begin storePointer:ofObject:withValue: */
		valuePointer1 = (((foo->freeBlock - mem) << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer1);
		}
		longAtput((result + BaseHeaderSize) + (1 << ShiftForWord), valuePointer1);
		/* begin storePointer:ofObject:withValue: */
		valuePointer2 = (((foo->endOfMemory - mem) << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer2);
		}
		longAtput((result + BaseHeaderSize) + (2 << ShiftForWord), valuePointer2);
		/* begin storePointer:ofObject:withValue: */
		valuePointer3 = ((foo->allocationCount << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer3);
		}
		longAtput((result + BaseHeaderSize) + (3 << ShiftForWord), valuePointer3);
		/* begin storePointer:ofObject:withValue: */
		valuePointer4 = ((foo->allocationsBetweenGCs << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer4);
		}
		longAtput((result + BaseHeaderSize) + (4 << ShiftForWord), valuePointer4);
		/* begin storePointer:ofObject:withValue: */
		valuePointer5 = ((foo->tenuringThreshold << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer5);
		}
		longAtput((result + BaseHeaderSize) + (5 << ShiftForWord), valuePointer5);
		/* begin storePointer:ofObject:withValue: */
		valuePointer6 = ((foo->statFullGCs << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer6);
		}
		longAtput((result + BaseHeaderSize) + (6 << ShiftForWord), valuePointer6);
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, statFullGCMSecsObj);
		}
		longAtput((result + BaseHeaderSize) + (7 << ShiftForWord), statFullGCMSecsObj);
		/* begin storePointer:ofObject:withValue: */
		valuePointer7 = ((foo->statIncrGCs << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer7);
		}
		longAtput((result + BaseHeaderSize) + (8 << ShiftForWord), valuePointer7);
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, statIncrGCMSecsObj);
		}
		longAtput((result + BaseHeaderSize) + (9 << ShiftForWord), statIncrGCMSecsObj);
		/* begin storePointer:ofObject:withValue: */
		valuePointer8 = ((foo->statTenures << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer8);
		}
		longAtput((result + BaseHeaderSize) + (10 << ShiftForWord), valuePointer8);
		/* begin storePointer:ofObject:withValue: */
		valuePointer9 = ((foo->rootTableCount << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer9);
		}
		longAtput((result + BaseHeaderSize) + (20 << ShiftForWord), valuePointer9);
		/* begin storePointer:ofObject:withValue: */
		valuePointer10 = ((foo->statRootTableOverflows << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer10);
		}
		longAtput((result + BaseHeaderSize) + (21 << ShiftForWord), valuePointer10);
		/* begin storePointer:ofObject:withValue: */
		valuePointer11 = ((extraVMMemory << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer11);
		}
		longAtput((result + BaseHeaderSize) + (22 << ShiftForWord), valuePointer11);
		/* begin storePointer:ofObject:withValue: */
		valuePointer12 = ((foo->shrinkThreshold << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer12);
		}
		longAtput((result + BaseHeaderSize) + (23 << ShiftForWord), valuePointer12);
		/* begin storePointer:ofObject:withValue: */
		valuePointer13 = ((foo->growHeadroom << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer13);
		}
		longAtput((result + BaseHeaderSize) + (24 << ShiftForWord), valuePointer13);
		/* begin storePointer:ofObject:withValue: */
		valuePointer14 = ((foo->interruptChecksEveryNms << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer14);
		}
		longAtput((result + BaseHeaderSize) + (25 << ShiftForWord), valuePointer14);
		/* begin storePointer:ofObject:withValue: */
		valuePointer15 = ((foo->statMarkCount << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer15);
		}
		longAtput((result + BaseHeaderSize) + (26 << ShiftForWord), valuePointer15);
		/* begin storePointer:ofObject:withValue: */
		valuePointer16 = ((foo->statSweepCount << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer16);
		}
		longAtput((result + BaseHeaderSize) + (27 << ShiftForWord), valuePointer16);
		/* begin storePointer:ofObject:withValue: */
		valuePointer17 = ((foo->statMkFwdCount << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer17);
		}
		longAtput((result + BaseHeaderSize) + (28 << ShiftForWord), valuePointer17);
		/* begin storePointer:ofObject:withValue: */
		valuePointer18 = ((foo->statCompMoveCount << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer18);
		}
		longAtput((result + BaseHeaderSize) + (29 << ShiftForWord), valuePointer18);
		/* begin storePointer:ofObject:withValue: */
		valuePointer19 = ((foo->statGrowMemory << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer19);
		}
		longAtput((result + BaseHeaderSize) + (30 << ShiftForWord), valuePointer19);
		/* begin storePointer:ofObject:withValue: */
		valuePointer20 = ((foo->statShrinkMemory << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer20);
		}
		longAtput((result + BaseHeaderSize) + (31 << ShiftForWord), valuePointer20);
		/* begin storePointer:ofObject:withValue: */
		valuePointer21 = ((foo->statRootTableCount << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer21);
		}
		longAtput((result + BaseHeaderSize) + (32 << ShiftForWord), valuePointer21);
		/* begin storePointer:ofObject:withValue: */
		valuePointer22 = ((foo->statAllocationCount << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer22);
		}
		longAtput((result + BaseHeaderSize) + (33 << ShiftForWord), valuePointer22);
		/* begin storePointer:ofObject:withValue: */
		valuePointer23 = ((foo->statSurvivorCount << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer23);
		}
		longAtput((result + BaseHeaderSize) + (34 << ShiftForWord), valuePointer23);
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, statGCTimeObj);
		}
		longAtput((result + BaseHeaderSize) + (35 << ShiftForWord), statGCTimeObj);
		/* begin storePointer:ofObject:withValue: */
		valuePointer24 = ((foo->statSpecialMarkCount << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer24);
		}
		longAtput((result + BaseHeaderSize) + (36 << ShiftForWord), valuePointer24);
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, statIGCDeltaTimeObj);
		}
		longAtput((result + BaseHeaderSize) + (37 << ShiftForWord), statIGCDeltaTimeObj);
		/* begin storePointer:ofObject:withValue: */
		valuePointer25 = ((foo->statpendingFinalizationSignals << 1) | 1);
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, valuePointer25);
		}
		longAtput((result + BaseHeaderSize) + (38 << ShiftForWord), valuePointer25);
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) result)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(result, ((BytesPerWord << 1) | 1));
		}
		longAtput((result + BaseHeaderSize) + (39 << ShiftForWord), ((BytesPerWord << 1) | 1));
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), result);
		foo->stackPointer = sp;
		return null;
	}
	arg = longAt(foo->stackPointer);
	if (!((arg & 1))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	arg = (arg >> 1);
	resultLargePositiveInteger = -1;
	if (foo->argumentCount == 1) {
		if ((arg < 1) || (arg > paramsArraySize)) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
		if (arg == 1) {
			result = foo->youngStart - mem;
		}
		if (arg == 2) {
			result = foo->freeBlock - mem;
		}
		if (arg == 3) {
			result = foo->endOfMemory - mem;
		}
		if (arg == 4) {
			result = foo->allocationCount;
		}
		if (arg == 5) {
			result = foo->allocationsBetweenGCs;
		}
		if (arg == 6) {
			result = foo->tenuringThreshold;
		}
		if (arg == 7) {
			result = foo->statFullGCs;
		}
		if (arg == 8) {
			resultLargePositiveInteger = foo->statFullGCMSecs;
		}
		if (arg == 9) {
			result = foo->statIncrGCs;
		}
		if (arg == 10) {
			resultLargePositiveInteger = foo->statIncrGCMSecs;
		}
		if (arg == 11) {
			result = foo->statTenures;
		}
		if ((arg >= 12) && (arg <= 20)) {
			result = 0;
		}
		if (arg == 21) {
			result = foo->rootTableCount;
		}
		if (arg == 22) {
			result = foo->statRootTableOverflows;
		}
		if (arg == 23) {
			result = extraVMMemory;
		}
		if (arg == 24) {
			result = foo->shrinkThreshold;
		}
		if (arg == 25) {
			result = foo->growHeadroom;
		}
		if (arg == 26) {
			result = foo->interruptChecksEveryNms;
		}
		if (arg == 27) {
			result = foo->statMarkCount;
		}
		if (arg == 28) {
			result = foo->statSweepCount;
		}
		if (arg == 29) {
			result = foo->statMkFwdCount;
		}
		if (arg == 30) {
			result = foo->statCompMoveCount;
		}
		if (arg == 31) {
			result = foo->statGrowMemory;
		}
		if (arg == 32) {
			result = foo->statShrinkMemory;
		}
		if (arg == 33) {
			result = foo->statRootTableCount;
		}
		if (arg == 34) {
			result = foo->statAllocationCount;
		}
		if (arg == 35) {
			result = foo->statSurvivorCount;
		}
		if (arg == 36) {
			resultLargePositiveInteger = foo->statGCTime;
		}
		if (arg == 37) {
			result = foo->statSpecialMarkCount;
		}
		if (arg == 38) {
			resultLargePositiveInteger = foo->statIGCDeltaTime;
		}
		if (arg == 39) {
			result = foo->statpendingFinalizationSignals;
		}
		if (arg == 40) {
			result = BytesPerWord;
		}
		if (resultLargePositiveInteger == -1) {
			/* begin pop:thenPush: */
			longAtput(sp1 = foo->stackPointer - ((2 - 1) * BytesPerWord), ((result << 1) | 1));
			foo->stackPointer = sp1;
		} else {
			/* begin pop:thenPush: */
			oop9 = positive64BitIntegerFor(resultLargePositiveInteger);
			longAtput(sp2 = foo->stackPointer - ((2 - 1) * BytesPerWord), oop9);
			foo->stackPointer = sp2;
		}
		return null;
	}
	if (!(foo->argumentCount == 2)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	index = longAt(foo->stackPointer - (1 * BytesPerWord));
	if (!((index & 1))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	index = (index >> 1);
	if (index <= 0) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	foo->successFlag = 0;
	if (index == 5) {
		result = foo->allocationsBetweenGCs;
		foo->allocationsBetweenGCs = arg;
		foo->successFlag = 1;
	}
	if (index == 6) {
		result = foo->tenuringThreshold;
		foo->tenuringThreshold = arg;
		foo->successFlag = 1;
	}
	if (index == 23) {
		result = extraVMMemory;
		extraVMMemory = arg;
		foo->successFlag = 1;
	}
	if (index == 24) {
		result = foo->shrinkThreshold;
		if (arg > 0) {
			foo->shrinkThreshold = arg;
			foo->successFlag = 1;
		}
	}
	if (index == 25) {
		result = foo->growHeadroom;
		if (arg > 0) {
			foo->growHeadroom = arg;
			foo->successFlag = 1;
		}
	}
	if (index == 26) {
		if (arg > 1) {
			result = foo->interruptChecksEveryNms;
			foo->interruptChecksEveryNms = arg;
			foo->successFlag = 1;
		}
	}
	if (foo->successFlag) {
		/* begin pop:thenPush: */
		longAtput(sp3 = foo->stackPointer - ((3 - 1) * BytesPerWord), ((result << 1) | 1));
		foo->stackPointer = sp3;
		return null;
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
}


/*	Return a string containing the path name of VM's directory. */

sqInt primitiveVMPath(void) {
register struct foo * foo = &fum;
    sqInt sz;
    sqInt s;
    sqInt sp;

	sz = vmPathSize();
	s = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassString << ShiftForWord)), sz);
	vmPathGetLength(s + BaseHeaderSize, sz);
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), s);
	foo->stackPointer = sp;
}


/*	Answer a string corresponding to the version of virtual machine. This
	represents the version level of the Smalltalk source code (interpreter and various
	plugins) that is translated to C by a CCodeGenerator,  in addition to the external
	platform source code, typically written in C and managed separately for each platform.
	By convention, this is a string composed of the interpreter source version and the
	platform source version, e.g. '4.0.2-2172'.
	
	This is a named (not numbered) primitive in the null module (ie the VM) */

EXPORT(sqInt) primitiveVMVersion(void) {
register struct foo * foo = &fum;
    void * p;
    sqInt versionString;
    sqInt len;
    sqInt sp;

	
# ifdef VM_VERSION  // version level of interpreter plus platform support code
	len = strlen(VM_VERSION);
	versionString = instantiateClassindexableSize(longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassString << ShiftForWord)), len);
	/* begin arrayValueOf: */
	if ((!((versionString & 1))) && (((versionString & 1) == 0) && (isWordsOrBytesNonInt(versionString)))) {
		p = pointerForOop(versionString + BaseHeaderSize);
		goto l1;
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
l1:	/* end arrayValueOf: */;
	strncpy(p, VM_VERSION, len);
# else
	/* begin primitiveFail */
	foo->successFlag = 0;
	return null;
# endif  // VM_VERSION
	
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((1 - 1) * BytesPerWord), versionString);
	foo->stackPointer = sp;
}

sqInt primitiveValue(void) {
register struct foo * foo = &fum;
    sqInt initialIP;
    sqInt blockContext;
    sqInt blockArgumentCount;
    sqInt count;
    sqInt firstFrom;
    sqInt fromOop;
    sqInt toIndex;
    sqInt fromIndex;
    sqInt lastFrom;
    sqInt localArgCount;
    sqInt successValue;
    sqInt tmp;

	blockContext = longAt(foo->stackPointer - (foo->argumentCount * BytesPerWord));
	/* begin argumentCountOfBlock: */
	localArgCount = longAt((blockContext + BaseHeaderSize) + (BlockArgumentCountIndex << ShiftForWord));
	/* begin checkedIntegerValueOf: */
	if ((localArgCount & 1)) {
		blockArgumentCount = (localArgCount >> 1);
		goto l1;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		blockArgumentCount = 0;
		goto l1;
	}
l1:	/* end checkedIntegerValueOf: */;
	/* begin success: */
	successValue = (foo->argumentCount == blockArgumentCount) && ((longAt((blockContext + BaseHeaderSize) + (CallerIndex << ShiftForWord))) == foo->nilObj);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		/* begin transfer:fromIndex:ofObject:toIndex:ofObject: */
		count = foo->argumentCount;
		firstFrom = ((((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) - foo->argumentCount) + 1;
		fromOop = foo->activeContext;
		flag("Dan");
		fromIndex = fromOop + (firstFrom * BytesPerWord);
		toIndex = blockContext + (TempFrameStart * BytesPerWord);
		lastFrom = fromIndex + (count * BytesPerWord);
		while ((((usqInt) fromIndex)) < (((usqInt) lastFrom))) {
			fromIndex += BytesPerWord;
			toIndex += BytesPerWord;
			longAtput(toIndex, longAt(fromIndex));
		}
		/* begin pop: */
		foo->stackPointer -= (foo->argumentCount + 1) * BytesPerWord;
		initialIP = longAt((blockContext + BaseHeaderSize) + (InitialIPIndex << ShiftForWord));
		longAtput((blockContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), initialIP);
		/* begin storeStackPointerValue:inContext: */
		longAtput((blockContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), ((foo->argumentCount << 1) | 1));
		longAtput((blockContext + BaseHeaderSize) + (CallerIndex << ShiftForWord), foo->activeContext);
		/* begin newActiveContext: */
		/* begin storeContextRegisters: */
		longAtput((foo->activeContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput((foo->activeContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), (((((((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) - TempFrameStart) + 1) << 1) | 1));
		if ((((usqInt) blockContext)) < (((usqInt) foo->youngStart))) {
			beRootIfOld(blockContext);
		}
		foo->activeContext = blockContext;
		/* begin fetchContextRegisters: */
		tmp = longAt((blockContext + BaseHeaderSize) + (MethodIndex << ShiftForWord));
		if ((tmp & 1)) {
			tmp = longAt((blockContext + BaseHeaderSize) + (HomeIndex << ShiftForWord));
			if ((((usqInt) tmp)) < (((usqInt) foo->youngStart))) {
				beRootIfOld(tmp);
			}
		} else {
			tmp = blockContext;
		}
		foo->theHomeContext = tmp;
		foo->receiver = longAt((tmp + BaseHeaderSize) + (ReceiverIndex << ShiftForWord));
		foo->method = longAt((tmp + BaseHeaderSize) + (MethodIndex << ShiftForWord));
		tmp = ((longAt((blockContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord))) >> 1);
		foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
		tmp = ((longAt((blockContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord))) >> 1);
		foo->stackPointer = (blockContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * BytesPerWord);
	}
}


/*	The only purpose of this primitive is to indicate that the new EH mechanisms are supported. */

sqInt primitiveValueUninterruptably(void) {
	return primitiveValue();
}

sqInt primitiveValueWithArgs(void) {
register struct foo * foo = &fum;
    sqInt initialIP;
    sqInt blockContext;
    sqInt arrayArgumentCount;
    sqInt argumentArray;
    sqInt blockArgumentCount;
    sqInt sz;
    sqInt header;
    sqInt successValue;
    sqInt toIndex;
    sqInt fromIndex;
    sqInt lastFrom;
    sqInt tmp;
    sqInt top;
    sqInt top1;
    sqInt localArgCount;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	argumentArray = top;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= BytesPerWord;
	blockContext = top1;
	/* begin argumentCountOfBlock: */
	localArgCount = longAt((blockContext + BaseHeaderSize) + (BlockArgumentCountIndex << ShiftForWord));
	/* begin checkedIntegerValueOf: */
	if ((localArgCount & 1)) {
		blockArgumentCount = (localArgCount >> 1);
		goto l2;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		blockArgumentCount = 0;
		goto l2;
	}
	blockArgumentCount = null;
l2:	/* end argumentCountOfBlock: */;
	if (!(((argumentArray & 1) == 0) && (((((usqInt) (longAt(argumentArray))) >> 8) & 15) == 2))) {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (foo->successFlag) {
		/* begin fetchWordLengthOf: */
		/* begin sizeBitsOf: */
		header = longAt(argumentArray);
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(argumentArray - (BytesPerWord * 2))) & LongSizeMask;
			goto l1;
		} else {
			sz = header & SizeMask;
			goto l1;
		}
	l1:	/* end sizeBitsOf: */;
		arrayArgumentCount = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
		/* begin success: */
		successValue = (arrayArgumentCount == blockArgumentCount) && ((longAt((blockContext + BaseHeaderSize) + (CallerIndex << ShiftForWord))) == foo->nilObj);
		foo->successFlag = successValue && foo->successFlag;
	}
	if (foo->successFlag) {
		/* begin transfer:fromIndex:ofObject:toIndex:ofObject: */
		flag("Dan");
		fromIndex = argumentArray + (0 * BytesPerWord);
		toIndex = blockContext + (TempFrameStart * BytesPerWord);
		lastFrom = fromIndex + (arrayArgumentCount * BytesPerWord);
		while ((((usqInt) fromIndex)) < (((usqInt) lastFrom))) {
			fromIndex += BytesPerWord;
			toIndex += BytesPerWord;
			longAtput(toIndex, longAt(fromIndex));
		}
		initialIP = longAt((blockContext + BaseHeaderSize) + (InitialIPIndex << ShiftForWord));
		longAtput((blockContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), initialIP);
		/* begin storeStackPointerValue:inContext: */
		longAtput((blockContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), ((arrayArgumentCount << 1) | 1));
		longAtput((blockContext + BaseHeaderSize) + (CallerIndex << ShiftForWord), foo->activeContext);
		/* begin newActiveContext: */
		/* begin storeContextRegisters: */
		longAtput((foo->activeContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput((foo->activeContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), (((((((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) - TempFrameStart) + 1) << 1) | 1));
		if ((((usqInt) blockContext)) < (((usqInt) foo->youngStart))) {
			beRootIfOld(blockContext);
		}
		foo->activeContext = blockContext;
		/* begin fetchContextRegisters: */
		tmp = longAt((blockContext + BaseHeaderSize) + (MethodIndex << ShiftForWord));
		if ((tmp & 1)) {
			tmp = longAt((blockContext + BaseHeaderSize) + (HomeIndex << ShiftForWord));
			if ((((usqInt) tmp)) < (((usqInt) foo->youngStart))) {
				beRootIfOld(tmp);
			}
		} else {
			tmp = blockContext;
		}
		foo->theHomeContext = tmp;
		foo->receiver = longAt((tmp + BaseHeaderSize) + (ReceiverIndex << ShiftForWord));
		foo->method = longAt((tmp + BaseHeaderSize) + (MethodIndex << ShiftForWord));
		tmp = ((longAt((blockContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord))) >> 1);
		foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
		tmp = ((longAt((blockContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord))) >> 1);
		foo->stackPointer = (blockContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * BytesPerWord);
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * BytesPerWord;
	}
}

sqInt primitiveWait(void) {
register struct foo * foo = &fum;
    sqInt excessSignals;
    sqInt activeProc;
    sqInt sema;
    sqInt lastLink;
    sqInt ccIndex;
    sqInt cl;


	/* rcvr */

	sema = longAt(foo->stackPointer);
	/* begin assertClassOf:is: */
	if ((sema & 1)) {
		foo->successFlag = 0;
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(sema))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(sema - BaseHeaderSize)) & AllButTypeMask;
	} else {
		cl = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassSemaphore << ShiftForWord)))) && foo->successFlag;
l1:	/* end assertClassOf:is: */;
	if (foo->successFlag) {
		excessSignals = fetchIntegerofObject(ExcessSignalsIndex, sema);
		if (excessSignals > 0) {
			/* begin storeInteger:ofObject:withValue: */
			if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
				(((((int) (excessSignals - 1))) ^ ((((int) (excessSignals - 1))) << 1)) >= 0)
# else
				(((excessSignals - 1) >= -1073741824) && ((excessSignals - 1) <= 1073741823))
# endif  // SQ_HOST32
			) {
				longAtput((sema + BaseHeaderSize) + (ExcessSignalsIndex << ShiftForWord), (((excessSignals - 1) << 1) | 1));
			} else {
				/* begin primitiveFail */
				foo->successFlag = 0;
			}
		} else {
			activeProc = longAt(((longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord))) + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
			/* begin addLastLink:toList: */
			if ((longAt((sema + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord))) == foo->nilObj) {
				/* begin storePointer:ofObject:withValue: */
				if ((((usqInt) sema)) < (((usqInt) foo->youngStart))) {
					possibleRootStoreIntovalue(sema, activeProc);
				}
				longAtput((sema + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord), activeProc);
			} else {
				lastLink = longAt((sema + BaseHeaderSize) + (LastLinkIndex << ShiftForWord));
				/* begin storePointer:ofObject:withValue: */
				if ((((usqInt) lastLink)) < (((usqInt) foo->youngStart))) {
					possibleRootStoreIntovalue(lastLink, activeProc);
				}
				longAtput((lastLink + BaseHeaderSize) + (NextLinkIndex << ShiftForWord), activeProc);
			}
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) sema)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(sema, activeProc);
			}
			longAtput((sema + BaseHeaderSize) + (LastLinkIndex << ShiftForWord), activeProc);
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) activeProc)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(activeProc, sema);
			}
			longAtput((activeProc + BaseHeaderSize) + (MyListIndex << ShiftForWord), sema);
			transferTo(wakeHighestPriority());
		}
	}
}


/*	primitively do the equivalent of Process>yield */

sqInt primitiveYield(void) {
register struct foo * foo = &fum;
    sqInt priority;
    sqInt processList;
    sqInt processLists;
    sqInt activeProc;
    sqInt lastLink;

	activeProc = longAt(((longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord))) + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
	priority = ((longAt((activeProc + BaseHeaderSize) + (PriorityIndex << ShiftForWord))) >> 1);
	processLists = longAt(((longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord))) + BaseHeaderSize) + (ProcessListsIndex << ShiftForWord));
	processList = longAt((processLists + BaseHeaderSize) + ((priority - 1) << ShiftForWord));
	if (!((longAt((processList + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord))) == foo->nilObj)) {
		/* begin addLastLink:toList: */
		if ((longAt((processList + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord))) == foo->nilObj) {
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) processList)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(processList, activeProc);
			}
			longAtput((processList + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord), activeProc);
		} else {
			lastLink = longAt((processList + BaseHeaderSize) + (LastLinkIndex << ShiftForWord));
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) lastLink)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(lastLink, activeProc);
			}
			longAtput((lastLink + BaseHeaderSize) + (NextLinkIndex << ShiftForWord), activeProc);
		}
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) processList)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(processList, activeProc);
		}
		longAtput((processList + BaseHeaderSize) + (LastLinkIndex << ShiftForWord), activeProc);
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) activeProc)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(activeProc, processList);
		}
		longAtput((activeProc + BaseHeaderSize) + (MyListIndex << ShiftForWord), processList);
		transferTo(wakeHighestPriority());
	}
}


/*	For testing in Smalltalk, this method should be overridden in a subclass. */

sqInt print(char * s) {
	printf("%s", s);
}


/*	Print all the stacks of all running processes, including those that are currently suspended. */

sqInt printAllStacks(void) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt ctx;
    sqInt proc;
    sqInt sz;
    sqInt header;

	proc = longAt(((longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord))) + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
	printNameOfClasscount(fetchClassOf(proc), 5);
	/* begin cr */
	printf("\n");
	printCallStackOf(foo->activeContext);
	oop = memory + (foo->headerTypeBytes[(longAt(memory)) & TypeMask]);
	while ((((usqInt) oop)) < (((usqInt) foo->endOfMemory))) {
		if ((fetchClassOf(oop)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassSemaphore << ShiftForWord)))) {
			/* begin cr */
			printf("\n");
			proc = longAt((oop + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord));
			while (!(proc == foo->nilObj)) {
				printNameOfClasscount(fetchClassOf(proc), 5);
				/* begin cr */
				printf("\n");
				ctx = longAt((proc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord));
				if (!(ctx == foo->nilObj)) {
					printCallStackOf(ctx);
				}
				proc = longAt((proc + BaseHeaderSize) + (NextLinkIndex << ShiftForWord));
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) oop)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(oop);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz) + (foo->headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	}
}

sqInt printCallStack(void) {
	return printCallStackOf(foo->activeContext);
}

sqInt printCallStackOf(sqInt aContext) {
register struct foo * foo = &fum;
    sqInt ctxt;
    sqInt message;
    sqInt methodSel;
    sqInt methClass;
    sqInt home;
    sqInt currClass;
    sqInt methodArray;
    sqInt classDictSize;
    sqInt classDict;
    sqInt i;
    sqInt done;
    sqInt sz;
    sqInt header;
    sqInt ccIndex;
    sqInt ccIndex1;
    sqInt currClass1;
    sqInt methodArray1;
    sqInt classDictSize1;
    sqInt classDict1;
    sqInt i1;
    sqInt done1;
    sqInt sz1;
    sqInt header1;
    sqInt ccIndex2;

	ctxt = aContext;
	while (!(ctxt == foo->nilObj)) {
		if ((fetchClassOf(ctxt)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassBlockContext << ShiftForWord)))) {
			home = longAt((ctxt + BaseHeaderSize) + (HomeIndex << ShiftForWord));
		} else {
			home = ctxt;
		}
		/* begin findClassOfMethod:forReceiver: */
		/* begin fetchClassOf: */
		if (((longAt((home + BaseHeaderSize) + (ReceiverIndex << ShiftForWord))) & 1)) {
			currClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
			goto l2;
		}
		ccIndex = (((usqInt) (longAt(longAt((home + BaseHeaderSize) + (ReceiverIndex << ShiftForWord))))) >> 12) & 31;
		if (ccIndex == 0) {
			currClass = (longAt((longAt((home + BaseHeaderSize) + (ReceiverIndex << ShiftForWord))) - BaseHeaderSize)) & AllButTypeMask;
			goto l2;
		} else {
			currClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
			goto l2;
		}
	l2:	/* end fetchClassOf: */;
		done = 0;
		while (!(done)) {
			classDict = longAt((currClass + BaseHeaderSize) + (MessageDictionaryIndex << ShiftForWord));
			/* begin fetchWordLengthOf: */
			/* begin sizeBitsOf: */
			header = longAt(classDict);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(classDict - (BytesPerWord * 2))) & LongSizeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
			classDictSize = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
			methodArray = longAt((classDict + BaseHeaderSize) + (MethodArrayIndex << ShiftForWord));
			i = 0;
			while (i < (classDictSize - SelectorStart)) {
				if ((longAt((home + BaseHeaderSize) + (MethodIndex << ShiftForWord))) == (longAt((methodArray + BaseHeaderSize) + (i << ShiftForWord)))) {
					methClass = currClass;
					goto l3;
				}
				i += 1;
			}
			currClass = longAt((currClass + BaseHeaderSize) + (SuperclassIndex << ShiftForWord));
			done = currClass == foo->nilObj;
		}
		/* begin fetchClassOf: */
		if (((longAt((home + BaseHeaderSize) + (ReceiverIndex << ShiftForWord))) & 1)) {
			methClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
			goto l3;
		}
		ccIndex1 = (((usqInt) (longAt(longAt((home + BaseHeaderSize) + (ReceiverIndex << ShiftForWord))))) >> 12) & 31;
		if (ccIndex1 == 0) {
			methClass = (longAt((longAt((home + BaseHeaderSize) + (ReceiverIndex << ShiftForWord))) - BaseHeaderSize)) & AllButTypeMask;
			goto l3;
		} else {
			methClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex1 - 1) << ShiftForWord));
			goto l3;
		}
		methClass = null;
	l3:	/* end findClassOfMethod:forReceiver: */;
		/* begin findSelectorOfMethod:forReceiver: */
		/* begin fetchClassOf: */
		if (((longAt((home + BaseHeaderSize) + (ReceiverIndex << ShiftForWord))) & 1)) {
			currClass1 = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
			goto l5;
		}
		ccIndex2 = (((usqInt) (longAt(longAt((home + BaseHeaderSize) + (ReceiverIndex << ShiftForWord))))) >> 12) & 31;
		if (ccIndex2 == 0) {
			currClass1 = (longAt((longAt((home + BaseHeaderSize) + (ReceiverIndex << ShiftForWord))) - BaseHeaderSize)) & AllButTypeMask;
			goto l5;
		} else {
			currClass1 = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex2 - 1) << ShiftForWord));
			goto l5;
		}
	l5:	/* end fetchClassOf: */;
		done1 = 0;
		while (!(done1)) {
			classDict1 = longAt((currClass1 + BaseHeaderSize) + (MessageDictionaryIndex << ShiftForWord));
			/* begin fetchWordLengthOf: */
			/* begin sizeBitsOf: */
			header1 = longAt(classDict1);
			if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
				sz1 = (longAt(classDict1 - (BytesPerWord * 2))) & LongSizeMask;
				goto l4;
			} else {
				sz1 = header1 & SizeMask;
				goto l4;
			}
		l4:	/* end sizeBitsOf: */;
			classDictSize1 = ((usqInt) (sz1 - BaseHeaderSize)) >> ShiftForWord;
			methodArray1 = longAt((classDict1 + BaseHeaderSize) + (MethodArrayIndex << ShiftForWord));
			i1 = 0;
			while (i1 <= (classDictSize1 - SelectorStart)) {
				if ((longAt((home + BaseHeaderSize) + (MethodIndex << ShiftForWord))) == (longAt((methodArray1 + BaseHeaderSize) + (i1 << ShiftForWord)))) {
					methodSel = longAt((classDict1 + BaseHeaderSize) + ((i1 + SelectorStart) << ShiftForWord));
					goto l6;
				}
				i1 += 1;
			}
			currClass1 = longAt((currClass1 + BaseHeaderSize) + (SuperclassIndex << ShiftForWord));
			done1 = currClass1 == foo->nilObj;
		}
		methodSel = foo->nilObj;
	l6:	/* end findSelectorOfMethod:forReceiver: */;
		printNum(ctxt);
		print(" ");
		if (!(ctxt == home)) {
			print("[] in ");
		}
		printNameOfClasscount(methClass, 5);
		print(">");
		if (methodSel == foo->nilObj) {
			print("?");
		} else {
			printStringOf(methodSel);
		}
		if (methodSel == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (SelectorDoesNotUnderstand << ShiftForWord)))) {
			message = longAt((home + BaseHeaderSize) + ((0 + TempFrameStart) << ShiftForWord));
			methodSel = longAt((message + BaseHeaderSize) + (MessageSelectorIndex << ShiftForWord));
			print(" ");
			printStringOf(methodSel);
		}
		/* begin cr */
		printf("\n");
		ctxt = longAt((ctxt + BaseHeaderSize) + (SenderIndex << ShiftForWord));
	}
}


/*	Details: The count argument is used to avoid a possible infinite recursion if classOop is a corrupted object. */

sqInt printNameOfClasscount(sqInt classOop, sqInt cnt) {
	if (cnt <= 0) {
		return print("bad class");
	}
	if ((sizeBitsOf(classOop)) == (7 * BytesPerWord)) {
		printNameOfClasscount(longAt((classOop + BaseHeaderSize) + (5 << ShiftForWord)), cnt - 1);
		print(" class");
	} else {
		printStringOf(longAt((classOop + BaseHeaderSize) + (6 << ShiftForWord)));
	}
}


/*	For testing in Smalltalk, this method should be overridden in a subclass. */

sqInt printNum(sqInt n) {
	printf("%ld", (long) n);
}

sqInt printStringOf(sqInt oop) {
    sqInt fmt;
    sqInt cnt;
    sqInt i;

	if ((oop & 1)) {
		return null;
	}
	fmt = (((usqInt) (longAt(oop))) >> 8) & 15;
	if (fmt < 8) {
		return null;
	}
	cnt = ((100 < (lengthOf(oop))) ? 100 : (lengthOf(oop)));
	i = 0;
	while (i < cnt) {
		/* begin printChar: */
		putchar(byteAt((oop + BaseHeaderSize) + i));
		i += 1;
	}
}

sqInt printUnbalancedStack(sqInt primIdx) {
	print("Stack unbalanced after ");
	if (foo->successFlag) {
		print("successful primitive ");
	} else {
		print("failed primitive ");
	}
	printNum(primIdx);
	/* begin cr */
	printf("\n");
}

sqInt push(sqInt object) {
register struct foo * foo = &fum;
    sqInt sp;

	longAtput(sp = foo->stackPointer + BytesPerWord, object);
	foo->stackPointer = sp;
}

sqInt pushBool(sqInt trueOrFalse) {
register struct foo * foo = &fum;
    sqInt sp;
    sqInt sp1;

	if (trueOrFalse) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
		foo->stackPointer = sp;
	} else {
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
		foo->stackPointer = sp1;
	}
}

sqInt pushFloat(double  f) {
register struct foo * foo = &fum;
    sqInt object;
    sqInt sp;

	/* begin push: */
	object = floatObjectOf(f);
	longAtput(sp = foo->stackPointer + BytesPerWord, object);
	foo->stackPointer = sp;
}

sqInt pushInteger(sqInt integerValue) {
register struct foo * foo = &fum;
    sqInt sp;

	/* begin push: */
	longAtput(sp = foo->stackPointer + BytesPerWord, ((integerValue << 1) | 1));
	foo->stackPointer = sp;
}


/*	Record the given object in a the remap buffer. Objects in this buffer are remapped when a compaction occurs. This facility is used by the interpreter to ensure that objects in temporary variables are properly remapped. */

sqInt pushRemappableOop(sqInt oop) {
register struct foo * foo = &fum;
	foo->remapBuffer[foo->remapBufferCount += 1] = oop;
}


/*	Append aWord to aFile in this platforms 'natural' byte order.  (Bytes will be swapped, if
	necessary, when the image is read on a different platform.) Set successFlag to false if
	the write fails. */

sqInt putLongtoFile(sqInt aWord, sqImageFile  aFile) {
register struct foo * foo = &fum;
    sqInt objectsWritten;

	objectsWritten = sqImageFileWrite(&aWord, sizeof(aWord), 1, aFile);
	/* begin success: */
	foo->successFlag = (objectsWritten == 1) && foo->successFlag;
}


/*	Read an image from the given file stream, allocating the given amount of memory to its object heap. Fail if the image has an unknown format or requires more than the given amount of memory. */
/*	Details: This method detects when the image was stored on a machine with the opposite byte ordering from this machine and swaps the bytes automatically. Furthermore, it allows the header information to start 512 bytes into the file, since some file transfer programs for the Macintosh apparently prepend a Mac-specific header of this size. Note that this same 512 bytes of prefix area could also be used to store an exec command on Unix systems, allowing one to launch Smalltalk by invoking the image name as a command. */
/*	This code is based on C code by Ian Piumarta and Smalltalk code by Tim Rowledge. Many thanks to both of you!! */

sqInt readImageFromFileHeapSizeStartingAt(sqImageFile  f, usqInt desiredHeapSize, squeakFileOffsetType  imageOffset) {
register struct foo * foo = &fum;
    sqInt heapSize;
    sqInt bytesToShift;
    sqInt headerSize;
    size_t  dataSize;
    size_t bytesRead;
    sqInt oldBaseAddr;
    sqInt swapBytes;
    squeakFileOffsetType  headerStart;
    sqInt memStart;
    sqInt minimumMemory;
    char * memoryAddress;
    sqInt startAddr;
    sqInt stopAddr;
    sqInt addr;

	swapBytes = checkImageVersionFromstartingAt(f, imageOffset);

	/* record header start position */

	headerStart = (sqImageFilePosition(f)) - BytesPerWord;
	headerSize = getLongFromFileswap(f, swapBytes);
	dataSize = getLongFromFileswap(f, swapBytes);
	oldBaseAddr = getLongFromFileswap(f, swapBytes);
	foo->specialObjectsOop = getLongFromFileswap(f, swapBytes);
	foo->lastHash = getLongFromFileswap(f, swapBytes);
	foo->savedWindowSize = getLongFromFileswap(f, swapBytes);
	foo->fullScreenFlag = getLongFromFileswap(f, swapBytes);
	extraVMMemory = getLongFromFileswap(f, swapBytes);
	if (foo->lastHash == 0) {
		foo->lastHash = 999;
	}
	heapSize = reserveExtraCHeapBytes(desiredHeapSize, extraVMMemory);

	/* need at least 100K of breathing room */

	minimumMemory = dataSize + 100000;
	if (heapSize < minimumMemory) {
		insufficientMemorySpecifiedError();
	}
	memory = allocateMemoryMinimumImageFileHeaderSize(heapSize, minimumMemory, f, headerSize);
	if (memory == null) {
		insufficientMemoryAvailableError();
	}
	memStart = memory;

	/* decrease memoryLimit a tad for safety */

	foo->memoryLimit = (memStart + heapSize) - 24;

	/* position file after the header */

	foo->endOfMemory = memStart + dataSize;
	sqImageFileSeek(f, headerStart + headerSize);
	/* begin sqImage:read:size:length: */
	memoryAddress = pointerForOop(memory);
	bytesRead = sqImageFileReadEntireImage(memoryAddress, sizeof(unsigned char), dataSize, f);
	if (bytesRead != dataSize) {
		unableToReadImageError();
	}
	foo->headerTypeBytes[0] = (BytesPerWord * 2);
	foo->headerTypeBytes[1] = BytesPerWord;
	foo->headerTypeBytes[2] = 0;
	foo->headerTypeBytes[3] = 0;
	if (swapBytes) {
		/* begin reverseBytesInImage */
		/* begin reverseBytesFrom:to: */
		startAddr = memory;
		stopAddr = foo->endOfMemory;
		flag("Dan");
		addr = startAddr;
		while ((((usqInt) addr)) < (((usqInt) stopAddr))) {
			longAtput(addr, byteSwapped(longAt(addr)));
			addr += BytesPerWord;
		}
		/* begin byteSwapByteObjects */
		byteSwapByteObjectsFromto(memory + (foo->headerTypeBytes[(longAt(memory)) & TypeMask]), foo->endOfMemory);
	}
	bytesToShift = memStart - oldBaseAddr;
	initializeInterpreter(bytesToShift);
	isBigEnder();
	return dataSize;
}


/*	Anwer true if images of the given format are readable by this interpreter. Allows a virtual machine to accept selected older image formats.  In our case we can select a newer (closure) image format as well as the existing format. */

sqInt readableFormat(sqInt imageVersion) {
	return (imageVersion == imageFormatVersionNumber) || ((imageVersion == (imageFormatForwardCompatibilityVersion())) || (imageVersion == (imageFormatBackwardCompatibilityVersion())));
}


/*	Map the given oop to its new value during a compaction or 
	become: operation. If it has no forwarding table entry, 
	return the oop itself. */

sqInt remap(sqInt oop) {
register struct foo * foo = &fum;
    sqInt fwdBlock;

	if (((oop & 1) == 0) && (((longAt(oop)) & MarkBit) != 0)) {
		fwdBlock = ((longAt(oop)) & AllButMarkBitAndTypeMask) << 1;
		if (DoAssertionChecks) {
			/* begin fwdBlockValidate: */
			if (!(((((usqInt) fwdBlock)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock & 3) == 0)))) {
				error("invalid fwd table entry");
			}
		}
		return longAt(fwdBlock);
	}
	return oop;
}


/*	Remove the first process from the given linked list. */

sqInt removeFirstLinkOfList(sqInt aList) {
register struct foo * foo = &fum;
    sqInt last;
    sqInt next;
    sqInt first;
    sqInt valuePointer;
    sqInt valuePointer1;
    sqInt valuePointer2;

	first = longAt((aList + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord));
	last = longAt((aList + BaseHeaderSize) + (LastLinkIndex << ShiftForWord));
	if (first == last) {
		/* begin storePointer:ofObject:withValue: */
		valuePointer = foo->nilObj;
		if ((((usqInt) aList)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(aList, valuePointer);
		}
		longAtput((aList + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord), valuePointer);
		/* begin storePointer:ofObject:withValue: */
		valuePointer1 = foo->nilObj;
		if ((((usqInt) aList)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(aList, valuePointer1);
		}
		longAtput((aList + BaseHeaderSize) + (LastLinkIndex << ShiftForWord), valuePointer1);
	} else {
		next = longAt((first + BaseHeaderSize) + (NextLinkIndex << ShiftForWord));
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) aList)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(aList, next);
		}
		longAtput((aList + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord), next);
	}
	/* begin storePointer:ofObject:withValue: */
	valuePointer2 = foo->nilObj;
	if ((((usqInt) first)) < (((usqInt) foo->youngStart))) {
		possibleRootStoreIntovalue(first, valuePointer2);
	}
	longAtput((first + BaseHeaderSize) + (NextLinkIndex << ShiftForWord), valuePointer2);
	return first;
}


/*	Remove the given variable location to the extra roots table */

EXPORT(sqInt) removeGCRoot(sqInt *varLoc) {
register struct foo * foo = &fum;
    sqInt *root;
    sqInt i;

	for (i = 1; i <= foo->extraRootCount; i += 1) {
		root = foo->extraRoots[i];
		if (root == varLoc) {
			foo->extraRoots[i] = (foo->extraRoots[foo->extraRootCount]);
			foo->extraRootCount -= 1;
			return 1;
		}
	}
	return 0;
}


/*	Restore headers smashed by forwarding links */

sqInt restoreHeadersFromtofromandtofrom(sqInt firstIn, sqInt lastIn, sqInt hdrBaseIn, sqInt firstOut, sqInt lastOut, sqInt hdrBaseOut) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt tablePtr;
    sqInt header;
    sqInt sz;
    sqInt header1;

	tablePtr = firstIn;
	while ((((usqInt) tablePtr)) <= (((usqInt) lastIn))) {
		oop = longAt(tablePtr);
		header = longAt(hdrBaseIn + (tablePtr - firstIn));
		longAtput(oop, header);
		tablePtr += BytesPerWord;
	}
	tablePtr = firstOut;
	while ((((usqInt) tablePtr)) <= (((usqInt) lastOut))) {
		oop = longAt(tablePtr);
		header = longAt(hdrBaseOut + (tablePtr - firstOut));
		longAtput(oop, header);
		tablePtr += BytesPerWord;
	}
	oop = memory + (foo->headerTypeBytes[(longAt(memory)) & TypeMask]);
	while ((((usqInt) oop)) < (((usqInt) foo->endOfMemory))) {
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			longAtput(oop, (longAt(oop)) & AllButMarkBit);
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) oop)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header1 = longAt(oop);
			if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
				goto l1;
			} else {
				sz = header1 & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz) + (foo->headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	}
}

sqInt resume(sqInt aProcess) {
register struct foo * foo = &fum;
    sqInt activePriority;
    sqInt newPriority;
    sqInt activeProc;
    sqInt priority;
    sqInt processList;
    sqInt processLists;
    sqInt lastLink;
    sqInt priority1;
    sqInt processList1;
    sqInt processLists1;
    sqInt lastLink1;

	activeProc = longAt(((longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord))) + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
	activePriority = ((longAt((activeProc + BaseHeaderSize) + (PriorityIndex << ShiftForWord))) >> 1);
	newPriority = ((longAt((aProcess + BaseHeaderSize) + (PriorityIndex << ShiftForWord))) >> 1);
	if (newPriority > activePriority) {
		/* begin putToSleep: */
		priority = ((longAt((activeProc + BaseHeaderSize) + (PriorityIndex << ShiftForWord))) >> 1);
		processLists = longAt(((longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord))) + BaseHeaderSize) + (ProcessListsIndex << ShiftForWord));
		processList = longAt((processLists + BaseHeaderSize) + ((priority - 1) << ShiftForWord));
		/* begin addLastLink:toList: */
		if ((longAt((processList + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord))) == foo->nilObj) {
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) processList)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(processList, activeProc);
			}
			longAtput((processList + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord), activeProc);
		} else {
			lastLink = longAt((processList + BaseHeaderSize) + (LastLinkIndex << ShiftForWord));
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) lastLink)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(lastLink, activeProc);
			}
			longAtput((lastLink + BaseHeaderSize) + (NextLinkIndex << ShiftForWord), activeProc);
		}
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) processList)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(processList, activeProc);
		}
		longAtput((processList + BaseHeaderSize) + (LastLinkIndex << ShiftForWord), activeProc);
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) activeProc)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(activeProc, processList);
		}
		longAtput((activeProc + BaseHeaderSize) + (MyListIndex << ShiftForWord), processList);
		transferTo(aProcess);
	} else {
		/* begin putToSleep: */
		priority1 = ((longAt((aProcess + BaseHeaderSize) + (PriorityIndex << ShiftForWord))) >> 1);
		processLists1 = longAt(((longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord))) + BaseHeaderSize) + (ProcessListsIndex << ShiftForWord));
		processList1 = longAt((processLists1 + BaseHeaderSize) + ((priority1 - 1) << ShiftForWord));
		/* begin addLastLink:toList: */
		if ((longAt((processList1 + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord))) == foo->nilObj) {
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) processList1)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(processList1, aProcess);
			}
			longAtput((processList1 + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord), aProcess);
		} else {
			lastLink1 = longAt((processList1 + BaseHeaderSize) + (LastLinkIndex << ShiftForWord));
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) lastLink1)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(lastLink1, aProcess);
			}
			longAtput((lastLink1 + BaseHeaderSize) + (NextLinkIndex << ShiftForWord), aProcess);
		}
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) processList1)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(processList1, aProcess);
		}
		longAtput((processList1 + BaseHeaderSize) + (LastLinkIndex << ShiftForWord), aProcess);
		/* begin storePointer:ofObject:withValue: */
		if ((((usqInt) aProcess)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(aProcess, processList1);
		}
		longAtput((aProcess + BaseHeaderSize) + (MyListIndex << ShiftForWord), processList1);
	}
}


/*	Reverse the given range of Display words (at different bit 
	depths, this will reverse different numbers of pixels). Used to 
	give feedback during VM activities such as garbage 
	collection when debugging. It is assumed that the given 
	word range falls entirely within the first line of the Display. */

sqInt reverseDisplayFromto(sqInt startIndex, sqInt endIndex) {
register struct foo * foo = &fum;
    sqInt dispBitsPtr;
    sqInt w;
    sqInt ptr;
    sqInt displayObj;
    sqInt reversed;

	displayObj = longAt((foo->specialObjectsOop + BaseHeaderSize) + (TheDisplay << ShiftForWord));
	if (!((((displayObj & 1) == 0) && (((((usqInt) (longAt(displayObj))) >> 8) & 15) <= 4)) && ((lengthOf(displayObj)) >= 4))) {
		return null;
	}
	w = fetchIntegerofObject(1, displayObj);
	dispBitsPtr = longAt((displayObj + BaseHeaderSize) + (0 << ShiftForWord));
	if ((dispBitsPtr & 1)) {
		return null;
	}
	dispBitsPtr += BaseHeaderSize;
	for (ptr = (dispBitsPtr + (startIndex * 4)); ptr <= (dispBitsPtr + (endIndex * 4)); ptr += 4) {
		reversed = (long32At(ptr)) ^ 4294967295U;
		longAtput(ptr, reversed);
	}
	foo->successFlag = 1;
	displayBitsOfLeftTopRightBottom(displayObj, 0, 0, w, 1);
	ioForceDisplayUpdate();
}


/*	Rewrite the cache entry with the given primitive index and matching function pointer */

sqInt rewriteMethodCacheSelclassprimIndex(sqInt selector, sqInt class, sqInt localPrimIndex) {
    void * primPtr;

	if (localPrimIndex == 0) {
		primPtr = 0;
	} else {
		primPtr = primitiveTable[localPrimIndex];
	}
	rewriteMethodCacheSelclassprimIndexprimFunction(selector, class, localPrimIndex, primPtr);
}


/*	Rewrite an existing entry in the method cache with a new primitive 
	index & function address. Used by primExternalCall to make direct jumps to found external prims */

sqInt rewriteMethodCacheSelclassprimIndexprimFunction(sqInt selector, sqInt class, sqInt localPrimIndex, void * localPrimAddress) {
register struct foo * foo = &fum;
    sqInt p;
    sqInt probe;
    sqInt hash;

	hash = selector ^ class;
	for (p = 0; p <= (CacheProbeMax - 1); p += 1) {
		probe = (((usqInt) hash) >> p) & MethodCacheMask;
		if (((foo->methodCache[probe + MethodCacheSelector]) == selector) && ((foo->methodCache[probe + MethodCacheClass]) == class)) {
			foo->methodCache[probe + MethodCachePrim] = localPrimIndex;
			foo->methodCache[probe + MethodCachePrimFunction] = (((long) localPrimAddress));
			return null;
		}
	}
}

sqInt setCompilerInitialized(sqInt newFlag) {
register struct foo * foo = &fum;
    sqInt oldFlag;

	oldFlag = foo->compilerInitialized;
	foo->compilerInitialized = newFlag;
	return oldFlag;
}

sqInt setFullScreenFlag(sqInt value) {
	foo->fullScreenFlag = value;
}

sqInt setInterruptCheckCounter(sqInt value) {
	foo->interruptCheckCounter = value;
}

sqInt setInterruptKeycode(sqInt value) {
	foo->interruptKeycode = value;
}

sqInt setInterruptPending(sqInt value) {
	foo->interruptPending = value;
}


/*	A default substitute for unimplemented ioUtcWithOffset external function. */

sqInt setMicroSecondsandOffset(sqLong * microSeconds, int * utcOffset) {
	flag("toRemove");
	return -1;
}

sqInt setNextWakeupTick(sqInt value) {
	foo->nextWakeupTick = value;
}

sqInt setSavedWindowSize(sqInt value) {
	foo->savedWindowSize = value;
}


/*	Repaint the portion of the Smalltalk screen bounded by the affected rectangle. Used to synchronize the screen after a Bitblt to the Smalltalk Display object. */

sqInt showDisplayBitsLeftTopRightBottom(sqInt aForm, sqInt l, sqInt t, sqInt r, sqInt b) {
	if (foo->deferDisplayUpdates) {
		return null;
	}
	displayBitsOfLeftTopRightBottom(aForm, l, t, r, b);
}


/*	Record the given semaphore index in the double buffer semaphores array to be signaled at the next convenient moment. Force a real interrupt check as soon as possible. */

sqInt signalSemaphoreWithIndex(sqInt index) {
register struct foo * foo = &fum;
	if (index <= 0) {
		return null;
	}
	if (foo->semaphoresUseBufferA) {
		if (foo->semaphoresToSignalCountA < SemaphoresToSignalSize) {
			foo->semaphoresToSignalCountA += 1;
			foo->semaphoresToSignalA[foo->semaphoresToSignalCountA] = index;
		}
	} else {
		if (foo->semaphoresToSignalCountB < SemaphoresToSignalSize) {
			foo->semaphoresToSignalCountB += 1;
			foo->semaphoresToSignalB[foo->semaphoresToSignalCountB] = index;
		}
	}
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
	foo->nextPollTick = 0;
}


/*	Return a full 32 bit integer object for the given integer value */

sqInt signed32BitIntegerFor(int integerValue) {
register struct foo * foo = &fum;
    sqInt value;
    sqInt newLargeInteger;
    sqInt largeClass;

	if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
		(((((int) integerValue)) ^ ((((int) integerValue)) << 1)) >= 0)
# else
		((integerValue >= -1073741824) && (integerValue <= 1073741823))
# endif  // SQ_HOST32
	) {
		return ((integerValue << 1) | 1);
	}
	if (integerValue < 0) {
		largeClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargeNegativeInteger << ShiftForWord));
		value = 0 - integerValue;
	} else {
		largeClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargePositiveInteger << ShiftForWord));
		value = integerValue;
	}
	newLargeInteger = instantiateClassindexableSize(largeClass, 4);
	byteAtput((newLargeInteger + BaseHeaderSize) + 3, (((usqInt) value) >> 24) & 255);
	byteAtput((newLargeInteger + BaseHeaderSize) + 2, (((usqInt) value) >> 16) & 255);
	byteAtput((newLargeInteger + BaseHeaderSize) + 1, (((usqInt) value) >> 8) & 255);
	byteAtput((newLargeInteger + BaseHeaderSize) + 0, value & 255);
	return newLargeInteger;
}


/*	Convert the given object into an integer value.
	The object may be either a positive ST integer or a four-byte LargeInteger. */

int signed32BitValueOf(sqInt oop) {
register struct foo * foo = &fum;
    int value;
    sqInt largeClass;
    sqInt sz;
    sqInt negative;
    sqInt ccIndex;
    sqInt header;
    sqInt sz1;

	if ((oop & 1)) {
		return (oop >> 1);
	}
	if ((lengthOf(oop)) > 4) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin fetchClassOf: */
	if ((oop & 1)) {
		largeClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l1;
	}
	ccIndex = (((usqInt) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		largeClass = (longAt(oop - BaseHeaderSize)) & AllButTypeMask;
		goto l1;
	} else {
		largeClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	if (largeClass == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargePositiveInteger << ShiftForWord)))) {
		negative = 0;
	} else {
		if (largeClass == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargeNegativeInteger << ShiftForWord)))) {
			negative = 1;
		} else {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	/* begin lengthOf: */
	header = longAt(oop);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz1 = header & SizeMask;
	}
	sz1 -= header & Size4Bit;
	if (((((usqInt) header) >> 8) & 15) <= 4) {
		sz = ((usqInt) (sz1 - BaseHeaderSize)) >> ShiftForWord;
		goto l2;
	}
	if (((((usqInt) header) >> 8) & 15) < 8) {
		sz = ((usqInt) (sz1 - BaseHeaderSize)) >> 2;
		goto l2;
	} else {
		sz = (sz1 - BaseHeaderSize) - (((((usqInt) header) >> 8) & 15) & 3);
		goto l2;
	}
	sz = null;
l2:	/* end lengthOf: */;
	if (!(sz == 4)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}

	/* Fail if value exceeds range of a 32-bit two's-complement signed integer. */

	value = (((byteAt((oop + BaseHeaderSize) + 0)) + ((byteAt((oop + BaseHeaderSize) + 1)) << 8)) + ((byteAt((oop + BaseHeaderSize) + 2)) << 16)) + ((byteAt((oop + BaseHeaderSize) + 3)) << 24);
	if (negative) {
		value = 0 - value;
		if (value >= 0) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	} else {
		if (value < 0) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	return value;
}


/*	Return a Large Integer object for the given integer value */

sqInt signed64BitIntegerFor(sqLong integerValue) {
register struct foo * foo = &fum;
    unsigned sqLong magnitude;
    sqInt newLargeInteger;
    usqInt highWord;
    sqInt largeClass;
    sqInt sz;
    sqInt intValue;
    sqInt i;

	if (integerValue < 0) {
		largeClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargeNegativeInteger << ShiftForWord));
		magnitude = 0 - integerValue;
	} else {
		largeClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargePositiveInteger << ShiftForWord));
		magnitude = integerValue;
	}
	if (magnitude <= 2147483647U) {
		return signed32BitIntegerFor(integerValue);
	}

	/* shift is coerced to usqInt otherwise */

	highWord = magnitude >> 32;
	if (highWord == 0) {
		sz = 4;
	} else {
		sz = 5;
		if (!((highWord = ((usqInt) highWord) >> 8) == 0)) {
			sz += 1;
		}
		if (!((highWord = ((usqInt) highWord) >> 8) == 0)) {
			sz += 1;
		}
		if (!((highWord = ((usqInt) highWord) >> 8) == 0)) {
			sz += 1;
		}
	}
	newLargeInteger = instantiateClassindexableSize(largeClass, sz);
	for (i = 0; i <= (sz - 1); i += 1) {
		intValue = (magnitude >> (i * 8)) & 255;
		byteAtput((newLargeInteger + BaseHeaderSize) + i, intValue);
	}
	return newLargeInteger;
}


/*	Convert the given object into an integer value.
	The object may be either a positive ST integer or a eight-byte LargeInteger. */

sqLong signed64BitValueOf(sqInt oop) {
register struct foo * foo = &fum;
    sqLong value;
    sqInt szsqLong;
    sqInt largeClass;
    sqInt sz;
    sqInt i;
    sqInt negative;
    sqInt header;
    sqInt sz1;
    sqInt ccIndex;

	if ((oop & 1)) {
		return ((sqLong) ((oop >> 1)));
	}
	/* begin lengthOf: */
	header = longAt(oop);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz1 = header & SizeMask;
	}
	sz1 -= header & Size4Bit;
	if (((((usqInt) header) >> 8) & 15) <= 4) {
		sz = ((usqInt) (sz1 - BaseHeaderSize)) >> ShiftForWord;
		goto l1;
	}
	if (((((usqInt) header) >> 8) & 15) < 8) {
		sz = ((usqInt) (sz1 - BaseHeaderSize)) >> 2;
		goto l1;
	} else {
		sz = (sz1 - BaseHeaderSize) - (((((usqInt) header) >> 8) & 15) & 3);
		goto l1;
	}
	sz = null;
l1:	/* end lengthOf: */;
	if (sz > 8) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin fetchClassOf: */
	if ((oop & 1)) {
		largeClass = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l2;
	}
	ccIndex = (((usqInt) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		largeClass = (longAt(oop - BaseHeaderSize)) & AllButTypeMask;
		goto l2;
	} else {
		largeClass = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l2;
	}
l2:	/* end fetchClassOf: */;
	if (largeClass == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargePositiveInteger << ShiftForWord)))) {
		negative = 0;
	} else {
		if (largeClass == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassLargeNegativeInteger << ShiftForWord)))) {
			negative = 1;
		} else {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	szsqLong = sizeof(sqLong);
	if (sz > szsqLong) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	value = 0;
	for (i = 0; i <= (sz - 1); i += 1) {
		value += (((sqLong) (byteAt((oop + BaseHeaderSize) + i)))) << (i * 8);
	}
	if (negative) {
		value = 0 - value;
		if (value >= 0) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	} else {
		if (value < 0) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	return value;
}


/*	Answer the number of bytes in the given object, including its base header, rounded up to an integral number of words. */
/*	Note: byte indexable objects need to have low bits subtracted from this size. */

sqInt sizeBitsOf(sqInt oop) {
    sqInt header;

	header = longAt(oop);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		return (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		return header & SizeMask;
	}
}


/*	Return the number of indexable fields of the given object. This method is to be called from an automatically generated C primitive. The argument is assumed to be a pointer to the first indexable field of a words or bytes object; the object header starts 4 bytes before that. */
/*	Note: Only called by translated primitive code. */

sqInt sizeOfSTArrayFromCPrimitive(void * cPtr) {
    sqInt oop;
    sqInt header;
    sqInt sz;

	oop = (oopForPointer(((char *) cPtr))) - BaseHeaderSize;
	if (!(((oop & 1) == 0) && (isWordsOrBytesNonInt(oop)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return 0;
	}
	/* begin lengthOf: */
	header = longAt(oop);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz = header & SizeMask;
	}
	sz -= header & Size4Bit;
	if (((((usqInt) header) >> 8) & 15) <= 4) {
		return ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
	}
	if (((((usqInt) header) >> 8) & 15) < 8) {
		return ((usqInt) (sz - BaseHeaderSize)) >> 2;
	} else {
		return (sz - BaseHeaderSize) - (((((usqInt) header) >> 8) & 15) & 3);
	}
	return null;
}


/*	Returns the number of slots in the receiver.
	If the receiver is a byte object, return the number of bytes.
	Otherwise return the number of words. */

sqInt slotSizeOf(sqInt oop) {
    sqInt header;
    sqInt sz;

	if ((oop & 1)) {
		return 0;
	}
	/* begin lengthOf: */
	header = longAt(oop);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz = header & SizeMask;
	}
	sz -= header & Size4Bit;
	if (((((usqInt) header) >> 8) & 15) <= 4) {
		return ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
	}
	if (((((usqInt) header) >> 8) & 15) < 8) {
		return ((usqInt) (sz - BaseHeaderSize)) >> 2;
	} else {
		return (sz - BaseHeaderSize) - (((((usqInt) header) >> 8) & 15) & 3);
	}
	return null;
}


/*	update state of active context */

sqInt snapshot(sqInt embedded) {
register struct foo * foo = &fum;
    sqInt rcvr;
    sqInt dataSize;
    void * setMacType;
    sqInt activeProc;
    sqInt top;
    sqInt sp;
    sqInt sp1;
    sqInt sp2;
    sqInt valuePointer;
    sqInt oop;
    sqInt fmt;
    sqInt sz;
    sqInt i;
    sqInt header;
    sqInt header1;
    sqInt sz1;
    sqInt header2;
    sqInt oop1;
    sqInt i1;

	if (foo->compilerInitialized) {
		compilerPreSnapshot();
	} else {
		/* begin storeContextRegisters: */
		longAtput((foo->activeContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput((foo->activeContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), (((((((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) - TempFrameStart) + 1) << 1) | 1));
	}
	activeProc = longAt(((longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord))) + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
	/* begin storePointer:ofObject:withValue: */
	valuePointer = foo->activeContext;
	if ((((usqInt) activeProc)) < (((usqInt) foo->youngStart))) {
		possibleRootStoreIntovalue(activeProc, valuePointer);
	}
	longAtput((activeProc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord), valuePointer);
	incrementalGC();
	fullGC();
	/* begin snapshotCleanUp */
	oop = memory + (foo->headerTypeBytes[(longAt(memory)) & TypeMask]);
	while ((((usqInt) oop)) < (((usqInt) foo->endOfMemory))) {
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			header = longAt(oop);
			fmt = (((usqInt) header) >> 8) & 15;
			if ((fmt == 3) && ((((((usqInt) header) >> 12) & 31) == 13) || ((((((usqInt) header) >> 12) & 31) == 14) || (((((usqInt) header) >> 12) & 31) == 4)))) {
				/* begin sizeBitsOf: */
				header1 = longAt(oop);
				if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
					sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
					goto l1;
				} else {
					sz = header1 & SizeMask;
					goto l1;
				}
			l1:	/* end sizeBitsOf: */;
				for (i = ((lastPointerOf(oop)) + BytesPerWord); i <= (sz - BaseHeaderSize); i += BytesPerWord) {
					longAtput(oop + i, foo->nilObj);
				}
			}
			if (fmt >= 12) {
				if ((primitiveIndexOf(oop)) == PrimitiveExternalCallIndex) {
					flushExternalPrimitiveOf(oop);
				}
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) oop)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz1 = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header2 = longAt(oop);
			if ((header2 & TypeMask) == HeaderTypeSizeAndClass) {
				sz1 = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
				goto l2;
			} else {
				sz1 = header2 & SizeMask;
				goto l2;
			}
		l2:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz1) + (foo->headerTypeBytes[(longAt(oop + sz1)) & TypeMask]);
	}
	/* begin clearRootsTable */
	for (i1 = 1; i1 <= foo->rootTableCount; i1 += 1) {
		oop1 = foo->rootTable[i1];
		longAtput(oop1, (longAt(oop1)) & AllButRootBit);
		foo->rootTable[i1] = 0;
	}
	foo->rootTableCount = 0;

	/* Assume all objects are below the start of the free block */

	dataSize = foo->freeBlock - memory;
	if (foo->successFlag) {
		/* begin popStack */
		top = longAt(foo->stackPointer);
		foo->stackPointer -= BytesPerWord;
		rcvr = top;
		/* begin push: */
		longAtput(sp = foo->stackPointer + BytesPerWord, foo->trueObj);
		foo->stackPointer = sp;
		writeImageFile(dataSize);
		if (!(embedded)) {
			setMacType = ioLoadFunctionFrom("setMacFileTypeAndCreator", "FilePlugin");
			if (!(setMacType == 0)) {
				((sqInt (*)(char *, char *, char *))setMacType)(imageName, "STim", "FAST");
			}
		}
		/* begin pop: */
		foo->stackPointer -= 1 * BytesPerWord;
	}
	beRootIfOld(foo->activeContext);
	if (foo->successFlag) {
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + BytesPerWord, foo->falseObj);
		foo->stackPointer = sp1;
	} else {
		/* begin push: */
		longAtput(sp2 = foo->stackPointer + BytesPerWord, rcvr);
		foo->stackPointer = sp2;
	}
	if (foo->compilerInitialized) {
		compilerPostSnapshot();
	}
}


/*	Return one of the objects in the SpecialObjectsArray */

sqInt splObj(sqInt index) {
	return longAt((foo->specialObjectsOop + BaseHeaderSize) + (index << ShiftForWord));
}


/*	Return what ST would return for <obj> at: index. */

sqInt stObjectat(sqInt array, sqInt index) {
register struct foo * foo = &fum;
    sqInt fmt;
    sqInt totalLength;
    sqInt stSize;
    sqInt hdr;
    sqInt fixedFields;
    sqInt sp;
    sqInt sz;
    sqInt class;
    sqInt classFormat;
    sqInt ccIndex;

	hdr = longAt(array);
	fmt = (((usqInt) hdr) >> 8) & 15;
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(array - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz = hdr & SizeMask;
	}
	sz -= hdr & Size4Bit;
	if (fmt <= 4) {
		totalLength = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
		goto l2;
	}
	if (fmt < 8) {
		totalLength = ((usqInt) (sz - BaseHeaderSize)) >> 2;
		goto l2;
	} else {
		totalLength = (sz - BaseHeaderSize) - (fmt & 3);
		goto l2;
	}
l2:	/* end lengthOf:baseHeader:format: */;
	/* begin fixedFieldsOf:format:length: */
	if ((fmt > 4) || (fmt == 2)) {
		fixedFields = 0;
		goto l3;
	}
	if (fmt < 2) {
		fixedFields = totalLength;
		goto l3;
	}
	/* begin fetchClassOf: */
	if ((array & 1)) {
		class = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l4;
	}
	ccIndex = (((usqInt) (longAt(array))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(array - BaseHeaderSize)) & AllButTypeMask;
		goto l4;
	} else {
		class = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l4;
	}
l4:	/* end fetchClassOf: */;
	classFormat = (longAt((class + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1;
	fixedFields = (((((usqInt) classFormat) >> 11) & 192) + ((((usqInt) classFormat) >> 2) & 63)) - 1;
l3:	/* end fixedFieldsOf:format:length: */;
	if ((fmt == 3) && ((((((usqInt) hdr) >> 12) & 31) == 13) || ((((((usqInt) hdr) >> 12) & 31) == 14) || (((((usqInt) hdr) >> 12) & 31) == 4)))) {
		/* begin fetchStackPointerOf: */
		sp = longAt((array + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
		if (!((sp & 1))) {
			stSize = 0;
			goto l1;
		}
		stSize = (sp >> 1);
	l1:	/* end fetchStackPointerOf: */;
	} else {
		stSize = totalLength - fixedFields;
	}
	if (((((usqInt) index)) >= (((usqInt) 1))) && ((((usqInt) index)) <= (((usqInt) stSize)))) {
		/* begin subscript:with:format: */
		if (fmt <= 4) {
			return longAt((array + BaseHeaderSize) + (((index + fixedFields) - 1) << ShiftForWord));
		}
		if (fmt < 8) {
			return positive32BitIntegerFor(long32At((array + BaseHeaderSize) + (((index + fixedFields) - 1) << 2)));
		} else {
			return (((byteAt((array + BaseHeaderSize) + ((index + fixedFields) - 1))) << 1) | 1);
		}
		return null;
	} else {
		foo->successFlag = 0;
		return 0;
	}
}


/*	Do what ST would return for <obj> at: index put: value. */

sqInt stObjectatput(sqInt array, sqInt index, sqInt value) {
register struct foo * foo = &fum;
    sqInt fmt;
    sqInt totalLength;
    sqInt stSize;
    sqInt hdr;
    sqInt fixedFields;
    sqInt sp;
    sqInt sz;
    sqInt class;
    sqInt classFormat;
    sqInt valueToStore;
    sqInt ccIndex;

	hdr = longAt(array);
	fmt = (((usqInt) hdr) >> 8) & 15;
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(array - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz = hdr & SizeMask;
	}
	sz -= hdr & Size4Bit;
	if (fmt <= 4) {
		totalLength = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
		goto l2;
	}
	if (fmt < 8) {
		totalLength = ((usqInt) (sz - BaseHeaderSize)) >> 2;
		goto l2;
	} else {
		totalLength = (sz - BaseHeaderSize) - (fmt & 3);
		goto l2;
	}
l2:	/* end lengthOf:baseHeader:format: */;
	/* begin fixedFieldsOf:format:length: */
	if ((fmt > 4) || (fmt == 2)) {
		fixedFields = 0;
		goto l3;
	}
	if (fmt < 2) {
		fixedFields = totalLength;
		goto l3;
	}
	/* begin fetchClassOf: */
	if ((array & 1)) {
		class = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l4;
	}
	ccIndex = (((usqInt) (longAt(array))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(array - BaseHeaderSize)) & AllButTypeMask;
		goto l4;
	} else {
		class = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l4;
	}
l4:	/* end fetchClassOf: */;
	classFormat = (longAt((class + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1;
	fixedFields = (((((usqInt) classFormat) >> 11) & 192) + ((((usqInt) classFormat) >> 2) & 63)) - 1;
l3:	/* end fixedFieldsOf:format:length: */;
	if ((fmt == 3) && ((((((usqInt) hdr) >> 12) & 31) == 13) || ((((((usqInt) hdr) >> 12) & 31) == 14) || (((((usqInt) hdr) >> 12) & 31) == 4)))) {
		/* begin fetchStackPointerOf: */
		sp = longAt((array + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
		if (!((sp & 1))) {
			stSize = 0;
			goto l1;
		}
		stSize = (sp >> 1);
	l1:	/* end fetchStackPointerOf: */;
	} else {
		stSize = totalLength - fixedFields;
	}
	if (((((usqInt) index)) >= (((usqInt) 1))) && ((((usqInt) index)) <= (((usqInt) stSize)))) {
		/* begin subscript:with:storing:format: */
		if (fmt <= 4) {
			/* begin storePointer:ofObject:withValue: */
			if ((((usqInt) array)) < (((usqInt) foo->youngStart))) {
				possibleRootStoreIntovalue(array, value);
			}
			longAtput((array + BaseHeaderSize) + (((index + fixedFields) - 1) << ShiftForWord), value);
		} else {
			if (fmt < 8) {
				valueToStore = positive32BitValueOf(value);
				if (foo->successFlag) {
					long32Atput((array + BaseHeaderSize) + (((index + fixedFields) - 1) << 2), valueToStore);
				}
			} else {
				if (!((value & 1))) {
					foo->successFlag = 0;
				}
				valueToStore = (value >> 1);
				if (!((valueToStore >= 0) && (valueToStore <= 255))) {
					foo->successFlag = 0;
				}
				if (foo->successFlag) {
					byteAtput((array + BaseHeaderSize) + ((index + fixedFields) - 1), valueToStore);
				}
			}
		}
	} else {
		foo->successFlag = 0;
	}
}


/*	Return the number of indexable fields in the given object. (i.e., what Smalltalk would return for <obj> size). */
/*	Note: Assume oop is not a SmallInteger! */

sqInt stSizeOf(sqInt oop) {
register struct foo * foo = &fum;
    sqInt fmt;
    sqInt totalLength;
    sqInt hdr;
    sqInt fixedFields;
    sqInt sp;
    sqInt sz;
    sqInt class;
    sqInt classFormat;
    sqInt ccIndex;

	hdr = longAt(oop);
	fmt = (((usqInt) hdr) >> 8) & 15;
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
	} else {
		sz = hdr & SizeMask;
	}
	sz -= hdr & Size4Bit;
	if (fmt <= 4) {
		totalLength = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;
		goto l1;
	}
	if (fmt < 8) {
		totalLength = ((usqInt) (sz - BaseHeaderSize)) >> 2;
		goto l1;
	} else {
		totalLength = (sz - BaseHeaderSize) - (fmt & 3);
		goto l1;
	}
l1:	/* end lengthOf:baseHeader:format: */;
	/* begin fixedFieldsOf:format:length: */
	if ((fmt > 4) || (fmt == 2)) {
		fixedFields = 0;
		goto l2;
	}
	if (fmt < 2) {
		fixedFields = totalLength;
		goto l2;
	}
	/* begin fetchClassOf: */
	if ((oop & 1)) {
		class = longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassInteger << ShiftForWord));
		goto l3;
	}
	ccIndex = (((usqInt) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(oop - BaseHeaderSize)) & AllButTypeMask;
		goto l3;
	} else {
		class = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (CompactClasses << ShiftForWord))) + BaseHeaderSize) + ((ccIndex - 1) << ShiftForWord));
		goto l3;
	}
l3:	/* end fetchClassOf: */;
	classFormat = (longAt((class + BaseHeaderSize) + (InstanceSpecificationIndex << ShiftForWord))) - 1;
	fixedFields = (((((usqInt) classFormat) >> 11) & 192) + ((((usqInt) classFormat) >> 2) & 63)) - 1;
l2:	/* end fixedFieldsOf:format:length: */;
	if ((fmt == 3) && ((((((usqInt) hdr) >> 12) & 31) == 13) || ((((((usqInt) hdr) >> 12) & 31) == 14) || (((((usqInt) hdr) >> 12) & 31) == 4)))) {
		/* begin fetchStackPointerOf: */
		sp = longAt((oop + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
		if (!((sp & 1))) {
			return 0;
		}
		return (sp >> 1);
	} else {
		return totalLength - fixedFields;
	}
}


/*	Note: May be called by translated primitive code. */

double stackFloatValue(sqInt offset) {
register struct foo * foo = &fum;
    double  result;
    sqInt floatPointer;

	floatPointer = longAt(foo->stackPointer - (offset * BytesPerWord));
	if (!((fetchClassOf(floatPointer)) == (longAt((foo->specialObjectsOop + BaseHeaderSize) + (ClassFloat << ShiftForWord))))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return 0.0;
	}
	;
	fetchFloatAtinto(floatPointer + BaseHeaderSize, result);
	return result;
}

sqInt stackIntegerValue(sqInt offset) {
register struct foo * foo = &fum;
    sqInt integerPointer;

	integerPointer = longAt(foo->stackPointer - (offset * BytesPerWord));
	/* begin checkedIntegerValueOf: */
	if ((integerPointer & 1)) {
		return (integerPointer >> 1);
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return 0;
	}
	return null;
}


/*	Ensures that the given object is a real object, not a SmallInteger. */

sqInt stackObjectValue(sqInt offset) {
register struct foo * foo = &fum;
    sqInt oop;

	oop = longAt(foo->stackPointer - (offset * BytesPerWord));
	if ((oop & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	return oop;
}

sqInt stackValue(sqInt offset) {
	return longAt(foo->stackPointer - (offset * BytesPerWord));
}


/*	Note: May be called by translated primitive code. */

sqInt storeIntegerofObjectwithValue(sqInt fieldIndex, sqInt objectPointer, sqInt integerValue) {
	if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
		(((((int) integerValue)) ^ ((((int) integerValue)) << 1)) >= 0)
# else
		((integerValue >= -1073741824) && (integerValue <= 1073741823))
# endif  // SQ_HOST32
	) {
		longAtput((objectPointer + BaseHeaderSize) + (fieldIndex << ShiftForWord), ((integerValue << 1) | 1));
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
	}
}


/*	Note must check here for stores of young objects into old ones. */

sqInt storePointerofObjectwithValue(sqInt fieldIndex, sqInt oop, sqInt valuePointer) {
	if ((((usqInt) oop)) < (((usqInt) foo->youngStart))) {
		possibleRootStoreIntovalue(oop, valuePointer);
	}
	return longAtput((oop + BaseHeaderSize) + (fieldIndex << ShiftForWord), valuePointer);
}

sqInt success(sqInt successValue) {
register struct foo * foo = &fum;
	foo->successFlag = successValue && foo->successFlag;
}


/*	Return true if there is enough free space after doing a garbage collection. If not, signal that space is low. */

sqInt sufficientSpaceAfterGC(usqInt minFree) {
register struct foo * foo = &fum;
    usqInt minFreePlus;
    usqInt growSize;

	incrementalGC();
	if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) < (((usqInt) minFree))) {
		if (foo->signalLowSpace) {
			return 0;
		}
		fullGC();
		minFreePlus = minFree + 15000;
		if (minFreePlus < minFree) {
			return 0;
		}
		if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((usqInt) minFreePlus))) {
			return 1;
		}
		growSize = (minFree - ((longAt(foo->freeBlock)) & AllButTypeMask)) + foo->growHeadroom;
		growObjectMemory(growSize);
		if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((usqInt) minFreePlus))) {
			return 1;
		}
		return 0;
	}
	return 1;
}


/*	Return true if there is enough space to allocate the given number of bytes,
	perhaps after doing a garbage collection. Sender is responsible for ensuring
	that requested size does result in arithmetic overflow, see note below. */

sqInt sufficientSpaceToAllocate(usqInt bytes) {
register struct foo * foo = &fum;
    usqInt minFree;


	/* check for low-space */

	minFree = (foo->lowSpaceThreshold + bytes) + BaseHeaderSize;
	if ((((usqInt) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((usqInt) minFree))) {
		return 1;
	} else {
		return sufficientSpaceAfterGC(minFree);
	}
}

sqInt superclassOf(sqInt classPointer) {
	return longAt((classPointer + BaseHeaderSize) + (SuperclassIndex << ShiftForWord));
}


/*	Sweep memory from youngStart through the end of memory. Free all 
	inaccessible objects and coalesce adjacent free chunks. Clear the mark 
	bits of accessible objects. Compute the starting point for the first pass of 
	incremental compaction (compStart). Return the number of surviving 
	objects.  */
/*	Details: Each time a non-free object is encountered, decrement the 
	number of available forward table entries. If all entries are spoken for 
	(i.e., entriesAvailable reaches zero), set compStart to the last free 
	chunk before that object or, if there is no free chunk before the given 
	object, the first free chunk after it. Thus, at the end of the sweep 
	phase, compStart through compEnd spans the highest collection of 
	non-free objects that can be accomodated by the forwarding table. This 
	information is used by the first pass of incremental compaction to 
	ensure that space is initially freed at the end of memory. Note that 
	there should always be at least one free chunk--the one at the end of 
	the heap. */

sqInt sweepPhase(void) {
register struct foo * foo = &fum;
    usqInt endOfMemoryLocal;
    sqInt firstFree;
    sqInt oopHeader;
    sqInt freeChunkSize;
    usqInt oop;
    sqInt entriesAvailable;
    sqInt freeChunk;
    sqInt hdrBytes;
    sqInt oopHeaderType;
    sqInt survivors;
    sqInt oopSize;

	entriesAvailable = fwdTableInit(BytesPerWord * 2);
	survivors = 0;
	freeChunk = null;

	/* will be updated later */

	firstFree = null;
	endOfMemoryLocal = foo->endOfMemory;
	oop = foo->youngStart + (foo->headerTypeBytes[(longAt(foo->youngStart)) & TypeMask]);
	while (oop < endOfMemoryLocal) {
		foo->statSweepCount += 1;
		oopHeader = longAt(oop);
		oopHeaderType = oopHeader & TypeMask;
		hdrBytes = foo->headerTypeBytes[oopHeaderType];
		if ((oopHeaderType & 1) == 1) {
			oopSize = oopHeader & SizeMask;
		} else {
			if (oopHeaderType == HeaderTypeSizeAndClass) {
				oopSize = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
			} else {
				oopSize = oopHeader & LongSizeMask;
			}
		}
		if ((oopHeader & MarkBit) == 0) {
			longAtput(oop - hdrBytes, HeaderTypeFree);
			if (freeChunk != null) {
				freeChunkSize = (freeChunkSize + oopSize) + hdrBytes;
			} else {

				/* chunk may start 4 or 8 bytes before oop */

				freeChunk = oop - hdrBytes;

				/* adjust size for possible extra header bytes */

				freeChunkSize = oopSize + (oop - freeChunk);
				if (firstFree == null) {
					firstFree = freeChunk;
				}
			}
		} else {
			longAtput(oop, oopHeader & AllButMarkBit);
			if (((((usqInt) (longAt(oop))) >> 8) & 15) == 4) {
				finalizeReference(oop);
			}
			if (entriesAvailable > 0) {
				entriesAvailable -= 1;
			} else {
				firstFree = freeChunk;
			}
			if (freeChunk != null) {
				longAtput(freeChunk, (freeChunkSize & LongSizeMask) | HeaderTypeFree);
				freeChunk = null;
			}
			survivors += 1;
		}
		oop = (oop + oopSize) + (foo->headerTypeBytes[(longAt(oop + oopSize)) & TypeMask]);
	}
	if (freeChunk != null) {
		longAtput(freeChunk, (freeChunkSize & LongSizeMask) | HeaderTypeFree);
	}
	if (!(oop == foo->endOfMemory)) {
		error("sweep failed to find exact end of memory");
	}
	if (firstFree == null) {
		error("expected to find at least one free object");
	} else {
		foo->compStart = firstFree;
	}
	return survivors;
}


/*	Signal the given semaphore from within the interpreter. */

sqInt synchronousSignal(sqInt aSemaphore) {
register struct foo * foo = &fum;
    sqInt excessSignals;

	if ((longAt((aSemaphore + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord))) == foo->nilObj) {
		excessSignals = fetchIntegerofObject(ExcessSignalsIndex, aSemaphore);
		/* begin storeInteger:ofObject:withValue: */
		if (
# ifdef SQ_HOST32  // cast to int for 64 bit image on 32 bit host
			(((((int) (excessSignals + 1))) ^ ((((int) (excessSignals + 1))) << 1)) >= 0)
# else
			(((excessSignals + 1) >= -1073741824) && ((excessSignals + 1) <= 1073741823))
# endif  // SQ_HOST32
		) {
			longAtput((aSemaphore + BaseHeaderSize) + (ExcessSignalsIndex << ShiftForWord), (((excessSignals + 1) << 1) | 1));
		} else {
			/* begin primitiveFail */
			foo->successFlag = 0;
		}
	} else {
		resume(removeFirstLinkOfList(aSemaphore));
	}
}


/*	Record a process to be awoken on the next interpreter cycle. 
	ikp 11/24/1999 06:07 -- added hook for external runtime 
	compiler  */

sqInt transferTo(sqInt aProc) {
register struct foo * foo = &fum;
    sqInt newProc;
    sqInt sched;
    sqInt oldProc;
    sqInt valuePointer;
    sqInt tmp;
    sqInt valuePointer1;

	newProc = aProc;
	sched = longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord));
	oldProc = longAt((sched + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord));
	/* begin storePointer:ofObject:withValue: */
	if ((((usqInt) sched)) < (((usqInt) foo->youngStart))) {
		possibleRootStoreIntovalue(sched, newProc);
	}
	longAtput((sched + BaseHeaderSize) + (ActiveProcessIndex << ShiftForWord), newProc);
	if (foo->compilerInitialized) {
		compilerProcessChangeto(oldProc, newProc);
	} else {
		/* begin storePointer:ofObject:withValue: */
		valuePointer = foo->activeContext;
		if ((((usqInt) oldProc)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(oldProc, valuePointer);
		}
		longAtput((oldProc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord), valuePointer);
		/* begin newActiveContext: */
		/* begin storeContextRegisters: */
		longAtput((foo->activeContext + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput((foo->activeContext + BaseHeaderSize) + (StackPointerIndex << ShiftForWord), (((((((usqInt) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> ShiftForWord) - TempFrameStart) + 1) << 1) | 1));
		if ((((usqInt) (longAt((newProc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord))))) < (((usqInt) foo->youngStart))) {
			beRootIfOld(longAt((newProc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord)));
		}
		foo->activeContext = longAt((newProc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord));
		/* begin fetchContextRegisters: */
		tmp = longAt(((longAt((newProc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord))) + BaseHeaderSize) + (MethodIndex << ShiftForWord));
		if ((tmp & 1)) {
			tmp = longAt(((longAt((newProc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord))) + BaseHeaderSize) + (HomeIndex << ShiftForWord));
			if ((((usqInt) tmp)) < (((usqInt) foo->youngStart))) {
				beRootIfOld(tmp);
			}
		} else {
			tmp = longAt((newProc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord));
		}
		foo->theHomeContext = tmp;
		foo->receiver = longAt((tmp + BaseHeaderSize) + (ReceiverIndex << ShiftForWord));
		foo->method = longAt((tmp + BaseHeaderSize) + (MethodIndex << ShiftForWord));
		tmp = ((longAt(((longAt((newProc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord))) + BaseHeaderSize) + (InstructionPointerIndex << ShiftForWord))) >> 1);
		foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
		tmp = ((longAt(((longAt((newProc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord))) + BaseHeaderSize) + (StackPointerIndex << ShiftForWord))) >> 1);
		foo->stackPointer = ((longAt((newProc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord))) + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * BytesPerWord);
		/* begin storePointer:ofObject:withValue: */
		valuePointer1 = foo->nilObj;
		if ((((usqInt) newProc)) < (((usqInt) foo->youngStart))) {
			possibleRootStoreIntovalue(newProc, valuePointer1);
		}
		longAtput((newProc + BaseHeaderSize) + (SuspendedContextIndex << ShiftForWord), valuePointer1);
	}
	foo->reclaimableContextCount = 0;
}

sqInt trueObject(void) {
	return foo->trueObj;
}


/*	update pointers in the given memory range */

sqInt updatePointersInRangeFromto(sqInt memStart, sqInt memEnd) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt fwdBlock;
    sqInt newOop;
    sqInt fieldOop;
    sqInt fieldOffset;
    sqInt fwdBlock1;
    sqInt header;
    sqInt header1;
    sqInt header2;
    sqInt fmt;
    sqInt fwdBlock2;
    sqInt methodHeader;
    sqInt size;
    sqInt contextSize;
    sqInt header3;
    sqInt sp;
    sqInt fwdBlock3;
    sqInt newClassHeader;
    sqInt classOop;
    sqInt newClassOop;
    sqInt classHeader;
    sqInt fwdBlock11;
    sqInt header4;
    sqInt header11;
    sqInt header21;
    sqInt sz;
    sqInt fwdBlock4;
    sqInt realHeader;
    sqInt header5;
    sqInt sz1;
    sqInt header12;

	oop = memStart + (foo->headerTypeBytes[(longAt(memStart)) & TypeMask]);
	while ((((usqInt) oop)) < (((usqInt) memEnd))) {
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			/* begin remapFieldsAndClassOf: */
			/* begin lastPointerWhileForwarding: */
			header3 = longAt(oop);
			if ((header3 & MarkBit) != 0) {
				fwdBlock2 = (header3 & AllButMarkBitAndTypeMask) << 1;
				if (DoAssertionChecks) {
					/* begin fwdBlockValidate: */
					if (!(((((usqInt) fwdBlock2)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock2)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock2 & 3) == 0)))) {
						error("invalid fwd table entry");
					}
				}
				header3 = longAt(fwdBlock2 + BytesPerWord);
			}
			fmt = (((usqInt) header3) >> 8) & 15;
			if (fmt <= 4) {
				if ((fmt == 3) && ((((((usqInt) header3) >> 12) & 31) == 13) || ((((((usqInt) header3) >> 12) & 31) == 14) || (((((usqInt) header3) >> 12) & 31) == 4)))) {
					/* begin fetchStackPointerOf: */
					sp = longAt((oop + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
					if (!((sp & 1))) {
						contextSize = 0;
						goto l2;
					}
					contextSize = (sp >> 1);
				l2:	/* end fetchStackPointerOf: */;
					fieldOffset = (CtxtTempFrameStart + contextSize) * BytesPerWord;
					goto l1;
				}
				if ((header3 & TypeMask) == HeaderTypeSizeAndClass) {
					size = (longAt(oop - (BytesPerWord * 2))) & AllButTypeMask;
				} else {
					size = header3 & SizeMask;
				}
				fieldOffset = size - BaseHeaderSize;
				goto l1;
			}
			if (fmt < 12) {
				fieldOffset = 0;
				goto l1;
			}
			methodHeader = longAt(oop + BaseHeaderSize);
			fieldOffset = (((((usqInt) methodHeader) >> 10) & 255) * BytesPerWord) + BaseHeaderSize;
		l1:	/* end lastPointerWhileForwarding: */;
			while (fieldOffset >= BaseHeaderSize) {
				fieldOop = longAt(oop + fieldOffset);
				if (((fieldOop & 1) == 0) && (((longAt(fieldOop)) & MarkBit) != 0)) {
					fwdBlock = ((longAt(fieldOop)) & AllButMarkBitAndTypeMask) << 1;
					if (DoAssertionChecks) {
						/* begin fwdBlockValidate: */
						if (!(((((usqInt) fwdBlock)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock & 3) == 0)))) {
							error("invalid fwd table entry");
						}
					}
					newOop = longAt(fwdBlock);
					longAtput(oop + fieldOffset, newOop);
					if (((((usqInt) oop)) < (((usqInt) foo->youngStart))) && ((((usqInt) newOop)) >= (((usqInt) foo->youngStart)))) {
						/* begin beRootWhileForwarding: */
						header = longAt(oop);
						if ((header & MarkBit) != 0) {
							fwdBlock1 = (header & AllButMarkBitAndTypeMask) << 1;
							if (DoAssertionChecks) {
								/* begin fwdBlockValidate: */
								if (!(((((usqInt) fwdBlock1)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock1)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock1 & 3) == 0)))) {
									error("invalid fwd table entry");
								}
							}
							/* begin noteAsRoot:headerLoc: */
							header1 = longAt(fwdBlock1 + BytesPerWord);
							if ((header1 & RootBit) == 0) {
								if (foo->rootTableCount < RootTableRedZone) {
									foo->rootTableCount += 1;
									foo->rootTable[foo->rootTableCount] = oop;
									longAtput(fwdBlock1 + BytesPerWord, header1 | RootBit);
								} else {
									if (foo->rootTableCount < RootTableSize) {
										foo->rootTableCount += 1;
										foo->rootTable[foo->rootTableCount] = oop;
										longAtput(fwdBlock1 + BytesPerWord, header1 | RootBit);
										foo->allocationCount = foo->allocationsBetweenGCs + 1;
									}
								}
							}
						} else {
							/* begin noteAsRoot:headerLoc: */
							header2 = longAt(oop);
							if ((header2 & RootBit) == 0) {
								if (foo->rootTableCount < RootTableRedZone) {
									foo->rootTableCount += 1;
									foo->rootTable[foo->rootTableCount] = oop;
									longAtput(oop, header2 | RootBit);
								} else {
									if (foo->rootTableCount < RootTableSize) {
										foo->rootTableCount += 1;
										foo->rootTable[foo->rootTableCount] = oop;
										longAtput(oop, header2 | RootBit);
										foo->allocationCount = foo->allocationsBetweenGCs + 1;
									}
								}
							}
						}
					}
				}
				fieldOffset -= BytesPerWord;
			}
			/* begin remapClassOf: */
			if (((longAt(oop)) & TypeMask) == HeaderTypeShort) {
				goto l3;
			}
			classHeader = longAt(oop - BytesPerWord);
			classOop = classHeader & AllButTypeMask;
			if (((classOop & 1) == 0) && (((longAt(classOop)) & MarkBit) != 0)) {
				fwdBlock3 = ((longAt(classOop)) & AllButMarkBitAndTypeMask) << 1;
				if (DoAssertionChecks) {
					/* begin fwdBlockValidate: */
					if (!(((((usqInt) fwdBlock3)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock3)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock3 & 3) == 0)))) {
						error("invalid fwd table entry");
					}
				}
				newClassOop = longAt(fwdBlock3);
				newClassHeader = newClassOop | (classHeader & TypeMask);
				longAtput(oop - BytesPerWord, newClassHeader);
				if (((((usqInt) oop)) < (((usqInt) foo->youngStart))) && ((((usqInt) newClassOop)) >= (((usqInt) foo->youngStart)))) {
					/* begin beRootWhileForwarding: */
					header4 = longAt(oop);
					if ((header4 & MarkBit) != 0) {
						fwdBlock11 = (header4 & AllButMarkBitAndTypeMask) << 1;
						if (DoAssertionChecks) {
							/* begin fwdBlockValidate: */
							if (!(((((usqInt) fwdBlock11)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock11)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock11 & 3) == 0)))) {
								error("invalid fwd table entry");
							}
						}
						/* begin noteAsRoot:headerLoc: */
						header11 = longAt(fwdBlock11 + BytesPerWord);
						if ((header11 & RootBit) == 0) {
							if (foo->rootTableCount < RootTableRedZone) {
								foo->rootTableCount += 1;
								foo->rootTable[foo->rootTableCount] = oop;
								longAtput(fwdBlock11 + BytesPerWord, header11 | RootBit);
							} else {
								if (foo->rootTableCount < RootTableSize) {
									foo->rootTableCount += 1;
									foo->rootTable[foo->rootTableCount] = oop;
									longAtput(fwdBlock11 + BytesPerWord, header11 | RootBit);
									foo->allocationCount = foo->allocationsBetweenGCs + 1;
								}
							}
						}
					} else {
						/* begin noteAsRoot:headerLoc: */
						header21 = longAt(oop);
						if ((header21 & RootBit) == 0) {
							if (foo->rootTableCount < RootTableRedZone) {
								foo->rootTableCount += 1;
								foo->rootTable[foo->rootTableCount] = oop;
								longAtput(oop, header21 | RootBit);
							} else {
								if (foo->rootTableCount < RootTableSize) {
									foo->rootTableCount += 1;
									foo->rootTable[foo->rootTableCount] = oop;
									longAtput(oop, header21 | RootBit);
									foo->allocationCount = foo->allocationsBetweenGCs + 1;
								}
							}
						}
					}
				}
			}
		l3:	/* end remapClassOf: */;
		}
		/* begin objectAfterWhileForwarding: */
		header5 = longAt(oop);
		if ((header5 & MarkBit) == 0) {
			/* begin objectAfter: */
			if (DoAssertionChecks) {
				if ((((usqInt) oop)) >= (((usqInt) foo->endOfMemory))) {
					error("no objects after the end of memory");
				}
			}
			if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
				sz1 = (longAt(oop)) & AllButTypeMask;
			} else {
				/* begin sizeBitsOf: */
				header12 = longAt(oop);
				if ((header12 & TypeMask) == HeaderTypeSizeAndClass) {
					sz1 = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
					goto l4;
				} else {
					sz1 = header12 & SizeMask;
					goto l4;
				}
			l4:	/* end sizeBitsOf: */;
			}
			oop = (oop + sz1) + (foo->headerTypeBytes[(longAt(oop + sz1)) & TypeMask]);
			goto l5;
		}
		fwdBlock4 = (header5 & AllButMarkBitAndTypeMask) << 1;
		if (DoAssertionChecks) {
			/* begin fwdBlockValidate: */
			if (!(((((usqInt) fwdBlock4)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock4)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock4 & 3) == 0)))) {
				error("invalid fwd table entry");
			}
		}
		realHeader = longAt(fwdBlock4 + BytesPerWord);
		if ((realHeader & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
		} else {
			sz = realHeader & SizeMask;
		}
		oop = (oop + sz) + (foo->headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	l5:	/* end objectAfterWhileForwarding: */;
	}
}


/*	update pointers in root objects */

sqInt updatePointersInRootObjectsFromto(sqInt memStart, sqInt memEnd) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt i;
    sqInt fwdBlock;
    sqInt newOop;
    sqInt fieldOop;
    sqInt fieldOffset;
    sqInt fwdBlock1;
    sqInt header;
    sqInt header1;
    sqInt header2;
    sqInt fmt;
    sqInt fwdBlock2;
    sqInt methodHeader;
    sqInt size;
    sqInt contextSize;
    sqInt header3;
    sqInt sp;
    sqInt fwdBlock3;
    sqInt newClassHeader;
    sqInt classOop;
    sqInt newClassOop;
    sqInt classHeader;
    sqInt fwdBlock11;
    sqInt header4;
    sqInt header11;
    sqInt header21;

	for (i = 1; i <= foo->rootTableCount; i += 1) {
		oop = foo->rootTable[i];
		if (((((usqInt) oop)) < (((usqInt) memStart))) || ((((usqInt) oop)) >= (((usqInt) memEnd)))) {
			/* begin remapFieldsAndClassOf: */
			/* begin lastPointerWhileForwarding: */
			header3 = longAt(oop);
			if ((header3 & MarkBit) != 0) {
				fwdBlock2 = (header3 & AllButMarkBitAndTypeMask) << 1;
				if (DoAssertionChecks) {
					/* begin fwdBlockValidate: */
					if (!(((((usqInt) fwdBlock2)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock2)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock2 & 3) == 0)))) {
						error("invalid fwd table entry");
					}
				}
				header3 = longAt(fwdBlock2 + BytesPerWord);
			}
			fmt = (((usqInt) header3) >> 8) & 15;
			if (fmt <= 4) {
				if ((fmt == 3) && ((((((usqInt) header3) >> 12) & 31) == 13) || ((((((usqInt) header3) >> 12) & 31) == 14) || (((((usqInt) header3) >> 12) & 31) == 4)))) {
					/* begin fetchStackPointerOf: */
					sp = longAt((oop + BaseHeaderSize) + (StackPointerIndex << ShiftForWord));
					if (!((sp & 1))) {
						contextSize = 0;
						goto l2;
					}
					contextSize = (sp >> 1);
				l2:	/* end fetchStackPointerOf: */;
					fieldOffset = (CtxtTempFrameStart + contextSize) * BytesPerWord;
					goto l1;
				}
				if ((header3 & TypeMask) == HeaderTypeSizeAndClass) {
					size = (longAt(oop - (BytesPerWord * 2))) & AllButTypeMask;
				} else {
					size = header3 & SizeMask;
				}
				fieldOffset = size - BaseHeaderSize;
				goto l1;
			}
			if (fmt < 12) {
				fieldOffset = 0;
				goto l1;
			}
			methodHeader = longAt(oop + BaseHeaderSize);
			fieldOffset = (((((usqInt) methodHeader) >> 10) & 255) * BytesPerWord) + BaseHeaderSize;
		l1:	/* end lastPointerWhileForwarding: */;
			while (fieldOffset >= BaseHeaderSize) {
				fieldOop = longAt(oop + fieldOffset);
				if (((fieldOop & 1) == 0) && (((longAt(fieldOop)) & MarkBit) != 0)) {
					fwdBlock = ((longAt(fieldOop)) & AllButMarkBitAndTypeMask) << 1;
					if (DoAssertionChecks) {
						/* begin fwdBlockValidate: */
						if (!(((((usqInt) fwdBlock)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock & 3) == 0)))) {
							error("invalid fwd table entry");
						}
					}
					newOop = longAt(fwdBlock);
					longAtput(oop + fieldOffset, newOop);
					if (((((usqInt) oop)) < (((usqInt) foo->youngStart))) && ((((usqInt) newOop)) >= (((usqInt) foo->youngStart)))) {
						/* begin beRootWhileForwarding: */
						header = longAt(oop);
						if ((header & MarkBit) != 0) {
							fwdBlock1 = (header & AllButMarkBitAndTypeMask) << 1;
							if (DoAssertionChecks) {
								/* begin fwdBlockValidate: */
								if (!(((((usqInt) fwdBlock1)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock1)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock1 & 3) == 0)))) {
									error("invalid fwd table entry");
								}
							}
							/* begin noteAsRoot:headerLoc: */
							header1 = longAt(fwdBlock1 + BytesPerWord);
							if ((header1 & RootBit) == 0) {
								if (foo->rootTableCount < RootTableRedZone) {
									foo->rootTableCount += 1;
									foo->rootTable[foo->rootTableCount] = oop;
									longAtput(fwdBlock1 + BytesPerWord, header1 | RootBit);
								} else {
									if (foo->rootTableCount < RootTableSize) {
										foo->rootTableCount += 1;
										foo->rootTable[foo->rootTableCount] = oop;
										longAtput(fwdBlock1 + BytesPerWord, header1 | RootBit);
										foo->allocationCount = foo->allocationsBetweenGCs + 1;
									}
								}
							}
						} else {
							/* begin noteAsRoot:headerLoc: */
							header2 = longAt(oop);
							if ((header2 & RootBit) == 0) {
								if (foo->rootTableCount < RootTableRedZone) {
									foo->rootTableCount += 1;
									foo->rootTable[foo->rootTableCount] = oop;
									longAtput(oop, header2 | RootBit);
								} else {
									if (foo->rootTableCount < RootTableSize) {
										foo->rootTableCount += 1;
										foo->rootTable[foo->rootTableCount] = oop;
										longAtput(oop, header2 | RootBit);
										foo->allocationCount = foo->allocationsBetweenGCs + 1;
									}
								}
							}
						}
					}
				}
				fieldOffset -= BytesPerWord;
			}
			/* begin remapClassOf: */
			if (((longAt(oop)) & TypeMask) == HeaderTypeShort) {
				goto l3;
			}
			classHeader = longAt(oop - BytesPerWord);
			classOop = classHeader & AllButTypeMask;
			if (((classOop & 1) == 0) && (((longAt(classOop)) & MarkBit) != 0)) {
				fwdBlock3 = ((longAt(classOop)) & AllButMarkBitAndTypeMask) << 1;
				if (DoAssertionChecks) {
					/* begin fwdBlockValidate: */
					if (!(((((usqInt) fwdBlock3)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock3)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock3 & 3) == 0)))) {
						error("invalid fwd table entry");
					}
				}
				newClassOop = longAt(fwdBlock3);
				newClassHeader = newClassOop | (classHeader & TypeMask);
				longAtput(oop - BytesPerWord, newClassHeader);
				if (((((usqInt) oop)) < (((usqInt) foo->youngStart))) && ((((usqInt) newClassOop)) >= (((usqInt) foo->youngStart)))) {
					/* begin beRootWhileForwarding: */
					header4 = longAt(oop);
					if ((header4 & MarkBit) != 0) {
						fwdBlock11 = (header4 & AllButMarkBitAndTypeMask) << 1;
						if (DoAssertionChecks) {
							/* begin fwdBlockValidate: */
							if (!(((((usqInt) fwdBlock11)) > (((usqInt) foo->endOfMemory))) && (((((usqInt) fwdBlock11)) <= (((usqInt) foo->fwdTableNext))) && ((fwdBlock11 & 3) == 0)))) {
								error("invalid fwd table entry");
							}
						}
						/* begin noteAsRoot:headerLoc: */
						header11 = longAt(fwdBlock11 + BytesPerWord);
						if ((header11 & RootBit) == 0) {
							if (foo->rootTableCount < RootTableRedZone) {
								foo->rootTableCount += 1;
								foo->rootTable[foo->rootTableCount] = oop;
								longAtput(fwdBlock11 + BytesPerWord, header11 | RootBit);
							} else {
								if (foo->rootTableCount < RootTableSize) {
									foo->rootTableCount += 1;
									foo->rootTable[foo->rootTableCount] = oop;
									longAtput(fwdBlock11 + BytesPerWord, header11 | RootBit);
									foo->allocationCount = foo->allocationsBetweenGCs + 1;
								}
							}
						}
					} else {
						/* begin noteAsRoot:headerLoc: */
						header21 = longAt(oop);
						if ((header21 & RootBit) == 0) {
							if (foo->rootTableCount < RootTableRedZone) {
								foo->rootTableCount += 1;
								foo->rootTable[foo->rootTableCount] = oop;
								longAtput(oop, header21 | RootBit);
							} else {
								if (foo->rootTableCount < RootTableSize) {
									foo->rootTableCount += 1;
									foo->rootTable[foo->rootTableCount] = oop;
									longAtput(oop, header21 | RootBit);
									foo->allocationCount = foo->allocationsBetweenGCs + 1;
								}
							}
						}
					}
				}
			}
		l3:	/* end remapClassOf: */;
		}
	}
}


/*	Verify that every old object that points to a new object 
		has its root bit set, and
		appears in the rootTable.
	This method should not be called if the rootTable is full, because roots
	are no longer recorded, and incremental collections are not attempted.
	If DoAssertionChecks is true, this routine will halt on an unmarked root.
	Otherwise, this routine will merely return true in that case. */

sqInt validateRoots(void) {
register struct foo * foo = &fum;
    sqInt badRoot;
    usqInt oop;
    usqInt fieldOop;
    usqInt fieldAddr;
    sqInt header;
    sqInt sz;
    sqInt header1;

	badRoot = 0;
	oop = memory + (foo->headerTypeBytes[(longAt(memory)) & TypeMask]);
	while (oop < foo->youngStart) {
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			fieldAddr = oop + (lastPointerOf(oop));
			while (fieldAddr > oop) {
				fieldOop = longAt(fieldAddr);
				if ((fieldOop >= foo->youngStart) && (!((fieldOop & 1)))) {
					header = longAt(oop);
					if ((header & RootBit) == 0) {
						if (DoAssertionChecks) {
							error("root bit not set");
						}
						badRoot = 1;
					} else {
						null;
					}
				}
				fieldAddr -= BytesPerWord;
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) oop)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header1 = longAt(oop);
			if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
				goto l1;
			} else {
				sz = header1 & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz) + (foo->headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	}
	return badRoot;
}

sqInt verifyCleanHeaders(void) {
register struct foo * foo = &fum;
    sqInt oop;
    sqInt sz;
    sqInt header;

	oop = memory + (foo->headerTypeBytes[(longAt(memory)) & TypeMask]);
	while ((((usqInt) oop)) < (((usqInt) foo->endOfMemory))) {
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			if (!((objectAfter(oop)) == foo->endOfMemory)) {
				error("Invalid obj with HeaderTypeBits = Free.");
			}
		} else {
			if (!(((longAt(oop)) & MarkBit) == 0)) {
				error("Invalid obj with MarkBit set.");
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if ((((usqInt) oop)) >= (((usqInt) foo->endOfMemory))) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(oop);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - (BytesPerWord * 2))) & LongSizeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz) + (foo->headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	}
}


/*	return 0 for little endian, 1 for big endian */

sqInt vmEndianness(void) {
	if (isBigEnder()) {
		return 1;
	} else {
		return 0;
	}
}


/*	Return the highest priority process that is ready to run. */
/*	Note: It is a fatal VM error if there is no runnable process. */

sqInt wakeHighestPriority(void) {
register struct foo * foo = &fum;
    sqInt p;
    sqInt processList;
    sqInt schedLists;
    sqInt sz;
    sqInt header;

	schedLists = longAt(((longAt(((longAt((foo->specialObjectsOop + BaseHeaderSize) + (SchedulerAssociation << ShiftForWord))) + BaseHeaderSize) + (ValueIndex << ShiftForWord))) + BaseHeaderSize) + (ProcessListsIndex << ShiftForWord));
	/* begin fetchWordLengthOf: */
	/* begin sizeBitsOf: */
	header = longAt(schedLists);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(schedLists - (BytesPerWord * 2))) & LongSizeMask;
		goto l1;
	} else {
		sz = header & SizeMask;
		goto l1;
	}
l1:	/* end sizeBitsOf: */;
	p = ((usqInt) (sz - BaseHeaderSize)) >> ShiftForWord;

	/* index of last indexable field */

	p -= 1;
	processList = longAt((schedLists + BaseHeaderSize) + (p << ShiftForWord));
	while ((longAt((processList + BaseHeaderSize) + (FirstLinkIndex << ShiftForWord))) == foo->nilObj) {
		p -= 1;
		if (p < 0) {
			error("scheduler could not find a runnable process");
		}
		processList = longAt((schedLists + BaseHeaderSize) + (p << ShiftForWord));
	}
	return removeFirstLinkOfList(processList);
}


/*	Return the given 64-bit integer with its halves in the reverse order. */

sqInt wordSwapped(sqInt w) {
	if (!(BytesPerWord == 8)) {
		error("This cannot happen.");
	}
	return ((((usqInt) w << 0)) & Bytes3to0Mask) + ((((usqInt) w << 0)) & Bytes7to4Mask);
}

sqInt writeImageFile(sqInt imageBytes) {
    void * fn;

	writeImageFileIO(imageBytes);
	fn = ioLoadFunctionFrom("setMacFileTypeAndCreator", "FilePlugin");
	if (!(fn == 0)) {
		((sqInt (*)(char*, char*, char*))fn)(imageName, "STim", "FAST");
	}
}

sqInt writeImageFileIO(sqInt imageBytes) {
register struct foo * foo = &fum;
    sqImageFile f;
    sqInt okToWrite;
    sqInt headerSize;
    size_t bytesWritten;
    void * sCWIfn;
    sqInt i;
    squeakFileOffsetType  headerStart;
    char * memoryAddress;

	sCWIfn = ioLoadFunctionFrom("secCanWriteImage", "SecurityPlugin");
	if (sCWIfn != 0) {
		okToWrite = ((sqInt (*)(void))sCWIfn)();
		if (!(okToWrite)) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	headerStart = 0;

	/* header size in bytes; do not change! */

	headerSize = 64;
	f = sqImageFileOpen(imageName, "wb");
	if (f == null) {
		/* begin success: */
		foo->successFlag = 0 && foo->successFlag;
		return null;
	}
	headerStart = sqImageFileStartLocation(f,imageName,headerSize+imageBytes);
	/* Note: on Unix systems one could put an exec command here, padded to 512 bytes */;
	sqImageFileSeek(f, headerStart);
	putLongtoFile(imageFormatVersionNumber, f);
	putLongtoFile(headerSize, f);
	putLongtoFile(imageBytes, f);
	putLongtoFile(memory, f);
	putLongtoFile(foo->specialObjectsOop, f);
	putLongtoFile(foo->lastHash, f);
	putLongtoFile(ioScreenSize(), f);
	putLongtoFile(foo->fullScreenFlag, f);
	putLongtoFile(extraVMMemory, f);
	for (i = 1; i <= 7; i += 1) {
		putLongtoFile(0, f);
	}
	if (!(foo->successFlag)) {
		sqImageFileClose(f);
		return null;
	}
	sqImageFileSeek(f, headerStart + headerSize);
	/* begin sqImage:write:size:length: */
	memoryAddress = pointerForOop(memory);
	bytesWritten = sqImageFileWrite(memoryAddress, sizeof(unsigned char), imageBytes, f);
	/* begin success: */
	foo->successFlag = (bytesWritten == imageBytes) && foo->successFlag;
	sqImageFileClose(f);
}


void* vm_exports[][3] = {
	{"", "primitiveMicrosecondClock", (void*)primitiveMicrosecondClock},
	{"", "dumpImage", (void*)dumpImage},
	{"", "addGCRoot", (void*)addGCRoot},
	{"", "callbackLeave", (void*)callbackLeave},
	{"", "primitiveIsRoot", (void*)primitiveIsRoot},
	{"", "primitiveRootTableAt", (void*)primitiveRootTableAt},
	{"", "callbackEnter", (void*)callbackEnter},
	{"", "primitiveInterpreterSourceVersion", (void*)primitiveInterpreterSourceVersion},
	{"", "primitiveImageFormatVersion", (void*)primitiveImageFormatVersion},
	{"", "primitiveIsYoung", (void*)primitiveIsYoung},
	{"", "callInterpreter", (void*)callInterpreter},
	{"", "primitiveChangeClassWithClass", (void*)primitiveChangeClassWithClass},
	{"", "primitiveUtcWithOffset", (void*)primitiveUtcWithOffset},
	{"", "primitiveForceTenure", (void*)primitiveForceTenure},
	{"", "moduleUnloaded", (void*)moduleUnloaded},
	{"", "primitiveSetGCSemaphore", (void*)primitiveSetGCSemaphore},
	{"", "primitiveScreenDepth", (void*)primitiveScreenDepth},
	{"", "primitiveDisablePowerManager", (void*)primitiveDisablePowerManager},
	{"", "primitivePlatformSourceVersion", (void*)primitivePlatformSourceVersion},
	{"", "removeGCRoot", (void*)removeGCRoot},
	{"", "primitiveRootTable", (void*)primitiveRootTable},
	{"", "primitiveVMVersion", (void*)primitiveVMVersion},
	{"", "primitiveSetGCBiasToGrowGCLimit", (void*)primitiveSetGCBiasToGrowGCLimit},
	{"", "primitiveSetGCBiasToGrow", (void*)primitiveSetGCBiasToGrow},
	{NULL, NULL, NULL}
};
