/* Automatically generated from Squeak on #(18 March 2005 7:42:18 pm) */

#define SQ_USE_GLOBAL_STRUCT 1

#include "sq.h"

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)

int printCallStack(void);
void error(char *s);
void error(char *s) {
	/* Print an error message and exit. */
	static int printingStack = false;

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
#define BlockMethodIndex 0
#define CacheProbeMax 3
#define CallerIndex 0
#define CharacterTable 24
#define CharacterValueIndex 0
#define ClassArray 7
#define ClassBitmap 4
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
#define CompactClassMask 126976
#define CompactClasses 28
#define ConstMinusOne 4294967295U
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
#define LargeContextBit 262144
#define LargeContextSize 252
#define LastLinkIndex 1
#define LiteralStart 1
#define MarkBit 2147483648U
#define MaxExternalPrimitiveTableSize 4096
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
#define SizeMask 252
#define SmallContextSize 92
#define SpecialSelectors 23
#define StackPointerIndex 2
#define StartField 1
#define StartObj 2
#define StreamArrayIndex 0
#define StreamIndexIndex 1
#define StreamReadLimitIndex 2
#define SuperclassIndex 0
#define SuspendedContextIndex 1
#define TempFrameStart 6
#define TheDisplay 14
#define TheFinalizationSemaphore 41
#define TheInputSemaphore 22
#define TheInterruptSemaphore 30
#define TheLowSpaceSemaphore 17
#define TheTimerSemaphore 29
#define TrueObject 2
#define TypeMask 3
#define Upward 3
#define ValueIndex 1
#define XIndex 0
#define YIndex 1

/*** Function Prototypes ***/
int accessibleObjectAfter(int oop);
int addNewMethodToCache(void);
int adjustAllOopsBy(int bytesToShift);
int allYoungand(int array1, int array2);
int allocateheaderSizeh1h2h3doFillwith(int byteSize, int hdrSize, int baseHeader, int classOop, int extendedSize, int doFill, int fillWord);
int allocateChunk(int byteSize);
int allocateOrRecycleContext(int needsLarge);
int argumentCountOf(int methodPointer);
void * arrayValueOf(int arrayOop);
int asciiOfCharacter(int characterObj);
int balancedStackafterPrimitivewithArgs(int delta, int primIdx, int nArgs);
int beRootIfOld(int oop);
int becomewith(int array1, int array2);
int becomewithtwoWaycopyHash(int array1, int array2, int twoWayFlag, int copyHashFlag);
int booleanValueOf(int obj);
int byteSizeOf(int oop);
int byteSwapByteObjectsFromto(int startOop, int stopAddr);
int byteSwapped(int w);
int characterForAscii(int ascii);
int characterTable(void);
int checkForInterrupts(void);
int checkImageVersionFromstartingAt(sqImageFile f, squeakFileOffsetType imageOffset);
int checkedIntegerValueOf(int intOop);
int checkedLongAt(int byteAddress);
int classArray(void);
int classBitmap(void);
int classByteArray(void);
int classCharacter(void);
int classExternalAddress(void);
int classExternalData(void);
int classExternalFunction(void);
int classExternalLibrary(void);
int classExternalStructure(void);
int classFloat(void);
int classLargeNegativeInteger(void);
int classLargePositiveInteger(void);
int classNameOfIs(int aClass, char *className);
int classPoint(void);
int classSemaphore(void);
int classSmallInteger(void);
int classString(void);
int clone(int oop);
int commonAt(int stringy);
int commonAtPut(int stringy);
int commonVariableatcacheIndex(int rcvr, int index, int atIx);
int compare31or32Bitsequal(int obj1, int obj2);
int compilerCreateActualMessagestoringArgs(int aMessage, int argArray);
int compilerFlushCache(int aCompiledMethod);
int compilerMapFromto(int memStart, int memEnd);
int compilerMark(void);
int compilerPostGC(void);
int compilerPostSnapshot(void);
int compilerPreGC(int fullGCFlag);
int compilerPreSnapshot(void);
int compilerProcessChange(void);
int compilerProcessChangeto(int oldProc, int newProc);
int compilerTranslateMethod(void);
int containOnlyOopsand(int array1, int array2);
int contexthasSender(int thisCntx, int aContext);
int copyBits(void);
int copyBitsFromtoat(int x0, int x1, int y);
int copyObjtoSegmentaddrstopAtsaveOopAtheaderAt(int oop, int segmentWordArray, int lastSeg, int stopAddr, int oopPtr, int hdrPtr);
int createActualMessageTo(int aClass);
int displayBitsOfLeftTopRightBottom(int aForm, int l, int t, int r, int b);
int displayObject(void);
int doPrimitiveDivby(int rcvr, int arg);
int doPrimitiveModby(int rcvr, int arg);
int dummyReferToProxy(void);
int failed(void);
int falseObject(void);
void * fetchArrayofObject(int fieldIndex, int objectPointer);
int fetchClassOf(int oop);
int fetchClassOfNonInt(int oop);
double fetchFloatofObject(int fieldIndex, int objectPointer);
int fetchIntegerofObject(int fieldIndex, int objectPointer);
int fetchPointerofObject(int fieldIndex, int oop);
int fetchStackPointerOf(int aContext);
int fetchWordofObject(int fieldIndex, int oop);
int fetchWordLengthOf(int objectPointer);
int finalizeReference(int oop);
int findClassOfMethodforReceiver(int meth, int rcvr);
int findNewMethodInClass(int class);
int findObsoleteNamedPrimitivelength(char * functionName, int functionLength);
int findSelectorOfMethodforReceiver(int meth, int rcvr);
int firstAccessibleObject(void);
void * firstFixedField(int oop);
void * firstIndexableField(int oop);
int floatObjectOf(double aFloat);
double floatValueOf(int oop);
int flushExternalPrimitiveOf(int methodPtr);
int flushExternalPrimitives(void);
int forceInterruptCheck(void);
int fullDisplayUpdate(void);
int fullGC(void);
int fwdTableInit(int blkSize);
int fwdTableSize(int blkSize);
int getCurrentBytecode(void);
int getFullScreenFlag(void);
int getInterruptCheckCounter(void);
int getInterruptKeycode(void);
int getInterruptPending(void);
int getLongFromFileswap(sqImageFile f, int swapFlag);
int getNextWakeupTick(void);
int getSavedWindowSize(void);
int imageSegmentVersion(void);
int incCompBody(void);
int incCompMakeFwd(void);
int incCompMove(int bytesFreed);
int includesBehaviorThatOf(int aClass, int aSuperclass);
int incrementalGC(void);
int initCompilerHooks(void);
int initializeMemoryFirstFree(int firstFree);
int initializeObjectMemory(int bytesToShift);
int installinAtCacheatstring(int rcvr, int *cache, int atIx, int stringy);
int instantiateClassindexableSize(int classPointer, int size);
int instantiateContextsizeInBytes(int classPointer, int sizeInBytes);
int instantiateSmallClasssizeInBytesfill(int classPointer, int sizeInBytes, int fillValue);
int integerObjectOf(int value);
int integerValueOf(int objectPointer);
int interpret(void);
int isKindOf(int oop, char *className);
int isMemberOf(int oop, char *className);
int isArray(int oop);
int isBytes(int oop);
int isFloatObject(int oop);
int isHandlerMarked(int aContext);
int isInMemory(int address);
int isIndexable(int oop);
int isIntegerObject(int objectPointer);
int isIntegerValue(int intValue);
int isPointers(int oop);
int isWeak(int oop);
int isWords(int oop);
int isWordsOrBytes(int oop);
int isWordsOrBytesNonInt(int oop);
int lastPointerOf(int oop);
int lengthOf(int oop);
int literalofMethod(int offset, int methodPointer);
int literalCountOf(int methodPointer);
int loadBitBltFrom(int bb);
double loadFloatOrIntFrom(int floatOrInt);
int loadInitialContext(void);
int lookupMethodInClass(int class);
int lowestFreeAfter(int chunk);
int makePointwithxValueyValue(int xValue, int yValue);
int mapPointersInObjectsFromto(int memStart, int memEnd);
int markAndTrace(int oop);
int markAndTraceInterpreterOops(void);
int markPhase(void);
int methodArgumentCount(void);
int methodPrimitiveIndex(void);
#pragma export on
EXPORT(int) moduleUnloaded(char * aModuleName);
#pragma export off
int nilObject(void);
int nonWeakFieldsOf(int oop);
int noteAsRootheaderLoc(int oop, int headerLoc);
int nullCompilerHook(void);
int objectAfter(int oop);
int okayFields(int oop);
int okayOop(int signedOop);
int oopFromChunk(int chunk);
int oopHasAcceptableClass(int signedOop);
int oopHasOkayClass(int signedOop);
int pop(int nItems);
int popthenPush(int nItems, int oop);
double popFloat(void);
int popRemappableOop(void);
int popStack(void);
int positive32BitIntegerFor(int integerValue);
int positive32BitValueOf(int oop);
int positive64BitIntegerFor(squeakInt64 integerValue);
squeakInt64 positive64BitValueOf(int oop);
int possibleRootStoreIntovalue(int oop, int valueObj);
int prepareForwardingTableForBecomingwithtwoWay(int array1, int array2, int twoWayFlag);
int primitiveAdd(void);
int primitiveArctan(void);
int primitiveArrayBecome(void);
int primitiveArrayBecomeOneWay(void);
int primitiveArrayBecomeOneWayCopyHash(void);
int primitiveAsFloat(void);
int primitiveAsOop(void);
int primitiveAt(void);
int primitiveAtEnd(void);
int primitiveAtPut(void);
int primitiveBeCursor(void);
int primitiveBeDisplay(void);
int primitiveBeep(void);
int primitiveBitAnd(void);
int primitiveBitOr(void);
int primitiveBitShift(void);
int primitiveBitXor(void);
int primitiveBlockCopy(void);
int primitiveBytesLeft(void);
int primitiveCalloutToFFI(void);
int primitiveChangeClass(void);
int primitiveClass(void);
int primitiveClipboardText(void);
int primitiveClone(void);
int primitiveClosureValue(void);
int primitiveClosureValueWithArgs(void);
int primitiveConstantFill(void);
int primitiveCopyObject(void);
int primitiveDeferDisplayUpdates(void);
#pragma export on
EXPORT(int) primitiveDisablePowerManager(void);
#pragma export off
int primitiveDiv(void);
int primitiveDivide(void);
int primitiveDoPrimitiveWithArgs(void);
int primitiveEqual(void);
int primitiveEquivalent(void);
int primitiveExecuteMethod(void);
int primitiveExitToDebugger(void);
int primitiveExp(void);
int primitiveExponent(void);
int primitiveExternalCall(void);
int primitiveFail(void);
int primitiveFindHandlerContext(void);
int primitiveFindNextUnwindContext(void);
int primitiveFloatAdd(void);
int primitiveFloatAddtoArg(int rcvrOop, int argOop);
int primitiveFloatDivide(void);
int primitiveFloatDividebyArg(int rcvrOop, int argOop);
int primitiveFloatEqual(void);
int primitiveFloatEqualtoArg(int rcvrOop, int argOop);
int primitiveFloatGreaterthanArg(int rcvrOop, int argOop);
int primitiveFloatGreaterOrEqual(void);
int primitiveFloatGreaterThan(void);
int primitiveFloatLessthanArg(int rcvrOop, int argOop);
int primitiveFloatLessOrEqual(void);
int primitiveFloatLessThan(void);
int primitiveFloatMultiply(void);
int primitiveFloatMultiplybyArg(int rcvrOop, int argOop);
int primitiveFloatNotEqual(void);
int primitiveFloatSubtract(void);
int primitiveFloatSubtractfromArg(int rcvrOop, int argOop);
int primitiveFlushCache(void);
int primitiveFlushCacheByMethod(void);
int primitiveFlushCacheSelective(void);
int primitiveFlushExternalPrimitives(void);
int primitiveForceDisplayUpdate(void);
int primitiveFormPrint(void);
int primitiveFractionalPart(void);
int primitiveFullGC(void);
int primitiveGetAttribute(void);
int primitiveGetNextEvent(void);
int primitiveGreaterOrEqual(void);
int primitiveGreaterThan(void);
int primitiveImageName(void);
int primitiveIncrementalGC(void);
int primitiveIndexOf(int methodPointer);
int primitiveInputSemaphore(void);
int primitiveInputWord(void);
int primitiveInstVarAt(void);
int primitiveInstVarAtPut(void);
int primitiveInstVarsPutFromStack(void);
int primitiveIntegerAt(void);
int primitiveIntegerAtPut(void);
int primitiveInterruptSemaphore(void);
int primitiveInvokeObjectAsMethod(void);
int primitiveKbdNext(void);
int primitiveKbdPeek(void);
int primitiveLessOrEqual(void);
int primitiveLessThan(void);
int primitiveListBuiltinModule(void);
int primitiveListExternalModule(void);
int primitiveLoadImageSegment(void);
int primitiveLoadInstVar(void);
int primitiveLogN(void);
int primitiveLowSpaceSemaphore(void);
int primitiveMakePoint(void);
int primitiveMarkHandlerMethod(void);
int primitiveMarkUnwindMethod(void);
int primitiveMethod(void);
int primitiveMillisecondClock(void);
int primitiveMod(void);
int primitiveMouseButtons(void);
int primitiveMousePoint(void);
int primitiveMultiply(void);
int primitiveNew(void);
int primitiveNewMethod(void);
int primitiveNewWithArg(void);
int primitiveNext(void);
int primitiveNextInstance(void);
int primitiveNextObject(void);
int primitiveNextPut(void);
int primitiveNoop(void);
int primitiveNotEqual(void);
int primitiveObjectAt(void);
int primitiveObjectAtPut(void);
int primitiveObjectPointsTo(void);
int primitiveObsoleteIndexedPrimitive(void);
int primitivePerform(void);
int primitivePerformAt(int lookupClass);
int primitivePerformInSuperclass(void);
int primitivePerformWithArgs(void);
int primitivePushFalse(void);
int primitivePushMinusOne(void);
int primitivePushNil(void);
int primitivePushOne(void);
int primitivePushSelf(void);
int primitivePushTrue(void);
int primitivePushTwo(void);
int primitivePushZero(void);
int primitiveQuit(void);
int primitiveQuo(void);
int primitiveRelinquishProcessor(void);
int primitiveResume(void);
int primitiveScanCharacters(void);
#pragma export on
EXPORT(int) primitiveScreenDepth(void);
#pragma export off
int primitiveScreenSize(void);
int primitiveSecondsClock(void);
int primitiveSetDisplayMode(void);
int primitiveSetFullScreen(void);
int primitiveSetInterruptKey(void);
int primitiveShortAt(void);
int primitiveShortAtPut(void);
int primitiveShowDisplayRect(void);
int primitiveSignal(void);
int primitiveSignalAtBytesLeft(void);
int primitiveSignalAtMilliseconds(void);
int primitiveSine(void);
int primitiveSize(void);
int primitiveSnapshot(void);
int primitiveSnapshotEmbedded(void);
int primitiveSomeInstance(void);
int primitiveSomeObject(void);
int primitiveSpecialObjectsOop(void);
int primitiveSquareRoot(void);
int primitiveStoreImageSegment(void);
int primitiveStoreStackp(void);
int primitiveStringAt(void);
int primitiveStringAtPut(void);
int primitiveStringReplace(void);
int primitiveSubtract(void);
int primitiveSuspend(void);
int primitiveTerminateTo(void);
int primitiveTestDisplayDepth(void);
int primitiveTimesTwoPower(void);
int primitiveTruncated(void);
int primitiveUnloadModule(void);
int primitiveVMParameter(void);
int primitiveVMPath(void);
int primitiveValue(void);
int primitiveValueUninterruptably(void);
int primitiveValueWithArgs(void);
int primitiveWait(void);
int primitiveYield(void);
int print(char *s);
int printAllStacks(void);
int printCallStack(void);
int printCallStackOf(int aContext);
int printNameOfClasscount(int classOop, int cnt);
int printNum(int n);
int printStringOf(int oop);
int printUnbalancedStack(int primIdx);
int printUnbalancedStackFromNamedPrimitive(void);
int push(int object);
int pushBool(int trueOrFalse);
int pushFloat(double f);
int pushInteger(int integerValue);
int pushRemappableOop(int oop);
int putLongtoFile(int n, sqImageFile f);
int readImageFromFileHeapSizeStartingAt(sqImageFile f, int desiredHeapSize, squeakFileOffsetType imageOffset);
int readableFormat(int imageVersion);
int remap(int oop);
int removeFirstLinkOfList(int aList);
int restoreHeadersFromtofromandtofrom(int firstIn, int lastIn, int hdrBaseIn, int firstOut, int lastOut, int hdrBaseOut);
int resume(int aProcess);
int reverseDisplayFromto(int startIndex, int endIndex);
int rewriteMethodCacheSelclassprimIndex(int selector, int class, int localPrimIndex);
int rewriteMethodCacheSelclassprimIndexprimFunction(int selector, int class, int localPrimIndex, int localPrimAddress);
int setCompilerInitialized(int newFlag);
int setFullScreenFlag(int value);
int setInterruptCheckCounter(int value);
int setInterruptKeycode(int value);
int setInterruptPending(int value);
int setNextWakeupTick(int value);
int setSavedWindowSize(int value);
int showDisplayBitsLeftTopRightBottom(int aForm, int l, int t, int r, int b);
int signalSemaphoreWithIndex(int index);
int signed32BitIntegerFor(int integerValue);
int signed32BitValueOf(int oop);
int signed64BitIntegerFor(squeakInt64 integerValue);
squeakInt64 signed64BitValueOf(int oop);
int sizeBitsOf(int oop);
int sizeOfSTArrayFromCPrimitive(void *cPtr);
int slotSizeOf(int oop);
int snapshot(int embedded);
int splObj(int index);
int stObjectat(int array, int index);
int stObjectatput(int array, int index, int value);
int stSizeOf(int oop);
double stackFloatValue(int offset);
int stackIntegerValue(int offset);
int stackObjectValue(int offset);
int stackValue(int offset);
int startOfMemory(void);
int storeIntegerofObjectwithValue(int fieldIndex, int objectPointer, int integerValue);
int storePointerofObjectwithValue(int fieldIndex, int oop, int valuePointer);
int success(int successValue);
int sufficientSpaceAfterGC(int minFree);
int superclassOf(int classPointer);
int sweepPhase(void);
int synchronousSignal(int aSemaphore);
int transferTo(int aProc);
int trueObject(void);
int updatePointersInRangeFromto(int memStart, int memEnd);
int updatePointersInRootObjectsFromto(int memStart, int memEnd);
int verifyCleanHeaders(void);
int wakeHighestPriority(void);
int writeImageFile(int imageBytes);
/*** Variables ***/
struct foo {
int stackPointer;
int successFlag;
int specialObjectsOop;
int nilObj;
int argumentCount;
int falseObj;
int trueObj;
int interruptCheckCounter;
int activeContext;
int freeBlock;
int instructionPointer;
int method;
int newMethod;
int theHomeContext;
int primitiveIndex;
int messageSelector;
int receiver;
int remapBufferCount;
int compilerInitialized;
int allocationCount;
int rootTableCount;
int allocationsBetweenGCs;
int lkupClass;
int reclaimableContextCount;
int fwdTableNext;
int lowSpaceThreshold;
int signalLowSpace;
int nextWakeupTick;
int lastHash;
int compStart;
int freeLargeContexts;
int growHeadroom;
int freeContexts;
int receiverClass;
int fwdTableLast;
int fullScreenFlag;
int methodClass;
int shrinkThreshold;
int interruptKeycode;
int newNativeMethod;
int interruptPending;
int totalObjectCount;
int primitiveFunctionPointer;
int compEnd;
int deferDisplayUpdates;
int savedWindowSize;
int semaphoresToSignalCountB;
int statRootTableOverflows;
int semaphoresUseBufferA;
int semaphoresToSignalCountA;
int statFullGCMSecs;
int tenuringThreshold;
int statFullGCs;
int pendingFinalizationSignals;
int interruptChecksEveryNms;
int statIncrGCMSecs;
int statTenures;
int statIncrGCs;
int lastTick;
int interruptCheckCounterFeedBackReset;
int nextPollTick;
unsigned youngStart;
unsigned endOfMemory;
int pollChecksEveryNms;
unsigned memoryLimit;
 } fum;
struct foo * foo = &fum;

int extraVMMemory;
int showSurfaceFn;
const char *interpreterVersion = "Squeak3.7 of '4 September 2004' [latest update: #5989]";
int semaphoresToSignalA[501];
int (*compilerHooks[16])();
int methodCache[4097];
int atCache[65];
struct VirtualMachine* interpreterProxy;
int semaphoresToSignalB[501];
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
unsigned char* memory;
int externalPrimitiveTable[4097];
fptr const primitiveTable[] = {
primitiveFail,
primitiveAdd,
primitiveSubtract,
primitiveLessThan,
primitiveGreaterThan,
primitiveLessOrEqual,
primitiveGreaterOrEqual,
primitiveEqual,
primitiveNotEqual,
primitiveMultiply,
primitiveDivide,
primitiveMod,
primitiveDiv,
primitiveQuo,
primitiveBitAnd,
primitiveBitOr,
primitiveBitXor,
primitiveBitShift,
primitiveMakePoint,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveAsFloat,
primitiveFloatAdd,
primitiveFloatSubtract,
primitiveFloatLessThan,
primitiveFloatGreaterThan,
primitiveFloatLessOrEqual,
primitiveFloatGreaterOrEqual,
primitiveFloatEqual,
primitiveFloatNotEqual,
primitiveFloatMultiply,
primitiveFloatDivide,
primitiveTruncated,
primitiveFractionalPart,
primitiveExponent,
primitiveTimesTwoPower,
primitiveSquareRoot,
primitiveSine,
primitiveArctan,
primitiveLogN,
primitiveExp,
primitiveAt,
primitiveAtPut,
primitiveSize,
primitiveStringAt,
primitiveStringAtPut,
primitiveNext,
primitiveNextPut,
primitiveAtEnd,
primitiveObjectAt,
primitiveObjectAtPut,
primitiveNew,
primitiveNewWithArg,
primitiveArrayBecomeOneWay,
primitiveInstVarAt,
primitiveInstVarAtPut,
primitiveAsOop,
primitiveStoreStackp,
primitiveSomeInstance,
primitiveNextInstance,
primitiveNewMethod,
primitiveBlockCopy,
primitiveValue,
primitiveValueWithArgs,
primitivePerform,
primitivePerformWithArgs,
primitiveSignal,
primitiveWait,
primitiveResume,
primitiveSuspend,
primitiveFlushCache,
primitiveMousePoint,
primitiveTestDisplayDepth,
primitiveSetDisplayMode,
primitiveInputSemaphore,
primitiveGetNextEvent,
primitiveInputWord,
primitiveObsoleteIndexedPrimitive,
primitiveSnapshot,
primitiveStoreImageSegment,
primitiveLoadImageSegment,
primitivePerformInSuperclass,
primitiveBeCursor,
primitiveBeDisplay,
primitiveScanCharacters,
primitiveObsoleteIndexedPrimitive,
primitiveStringReplace,
primitiveScreenSize,
primitiveMouseButtons,
primitiveKbdNext,
primitiveKbdPeek,
primitiveEquivalent,
primitiveClass,
primitiveBytesLeft,
primitiveQuit,
primitiveExitToDebugger,
primitiveChangeClass,
primitiveFlushCacheByMethod,
primitiveExternalCall,
primitiveDoPrimitiveWithArgs,
primitiveFlushCacheSelective,
primitiveCalloutToFFI,
primitiveImageName,
primitiveNoop,
primitiveValueUninterruptably,
primitiveLowSpaceSemaphore,
primitiveSignalAtBytesLeft,
primitiveDeferDisplayUpdates,
primitiveShowDisplayRect,
primitiveArrayBecome,
primitiveSpecialObjectsOop,
primitiveFullGC,
primitiveIncrementalGC,
primitiveObjectPointsTo,
primitiveSetInterruptKey,
primitiveInterruptSemaphore,
primitiveMillisecondClock,
primitiveSignalAtMilliseconds,
primitiveSecondsClock,
primitiveSomeObject,
primitiveNextObject,
primitiveBeep,
primitiveClipboardText,
primitiveVMPath,
primitiveShortAt,
primitiveShortAtPut,
primitiveConstantFill,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveClone,
primitiveGetAttribute,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveIntegerAt,
primitiveIntegerAtPut,
primitiveYield,
primitiveCopyObject,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveClosureValue,
primitiveClosureValueWithArgs,
primitiveExecuteMethod,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveFindNextUnwindContext,
primitiveTerminateTo,
primitiveFindHandlerContext,
primitiveMarkUnwindMethod,
primitiveMarkHandlerMethod,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveRelinquishProcessor,
primitiveForceDisplayUpdate,
primitiveFormPrint,
primitiveSetFullScreen,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveFail,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveSnapshotEmbedded,
primitiveInvokeObjectAsMethod,
primitiveArrayBecomeOneWayCopyHash,
clearProfile,
dumpProfile,
startProfiling,
stopProfiling,
primitiveVMParameter,
primitiveInstVarsPutFromStack,
primitivePushSelf,
primitivePushTrue,
primitivePushFalse,
primitivePushNil,
primitivePushMinusOne,
primitivePushZero,
primitivePushOne,
primitivePushTwo,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveLoadInstVar,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveFail,
primitiveFail,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveObsoleteIndexedPrimitive,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFail,
primitiveFlushExternalPrimitives,
primitiveUnloadModule,
primitiveListBuiltinModule,
primitiveListExternalModule,
primitiveFail,
primitiveFail,

};
int headerTypeBytes[4];
int rootTable[2501];
int remapBuffer[26];



/*	Return the accessible object following the given object or 
	free chunk in the heap. Return nil when heap is exhausted. */

int accessibleObjectAfter(int oop) {
register struct foo * foo = &fum;
    int obj;
    int sz;
    int header;
    int sz1;
    int header1;

	/* begin objectAfter: */
	if (DoAssertionChecks) {
		if (oop >= foo->endOfMemory) {
			error("no objects after the end of memory");
		}
	}
	if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
		sz1 = (longAt(oop)) & AllButTypeMask;
	} else {
		/* begin sizeBitsOf: */
		header1 = longAt(oop);
		if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
			sz1 = (longAt(oop - 8)) & AllButTypeMask;
			goto l2;
		} else {
			sz1 = header1 & SizeMask;
			goto l2;
		}
	l2:	/* end sizeBitsOf: */;
	}
	obj = (oop + sz1) + (headerTypeBytes[(longAt(oop + sz1)) & TypeMask]);
	while (obj < foo->endOfMemory) {
		if (!(((longAt(obj)) & TypeMask) == HeaderTypeFree)) {
			return obj;
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if (obj >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(obj)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(obj)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(obj);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(obj - 8)) & AllButTypeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		obj = (obj + sz) + (headerTypeBytes[(longAt(obj + sz)) & TypeMask]);
	}
	return null;
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

int addNewMethodToCache(void) {
register struct foo * foo = &fum;
    int probe;
    int p;
    int hash;

	foo->compilerInitialized && (compilerTranslateMethod());

	/* drop low-order zeros from addresses */

	hash = foo->messageSelector ^ foo->lkupClass;
	foo->primitiveFunctionPointer = ((int) (primitiveTable[foo->primitiveIndex]));
	for (p = 0; p <= (CacheProbeMax - 1); p += 1) {
		probe = (((unsigned) hash) >> p) & MethodCacheMask;
		if ((methodCache[probe + MethodCacheSelector]) == 0) {
			methodCache[probe + MethodCacheSelector] = foo->messageSelector;
			methodCache[probe + MethodCacheClass] = foo->lkupClass;
			methodCache[probe + MethodCacheMethod] = foo->newMethod;
			methodCache[probe + MethodCachePrim] = foo->primitiveIndex;
			methodCache[probe + MethodCacheNative] = foo->newNativeMethod;
			methodCache[probe + MethodCachePrimFunction] = foo->primitiveFunctionPointer;
			return null;
		}
	}

	/* first probe */

	probe = hash & MethodCacheMask;
	methodCache[probe + MethodCacheSelector] = foo->messageSelector;
	methodCache[probe + MethodCacheClass] = foo->lkupClass;
	methodCache[probe + MethodCacheMethod] = foo->newMethod;
	methodCache[probe + MethodCachePrim] = foo->primitiveIndex;
	methodCache[probe + MethodCacheNative] = foo->newNativeMethod;
	methodCache[probe + MethodCachePrimFunction] = foo->primitiveFunctionPointer;
	for (p = 1; p <= (CacheProbeMax - 1); p += 1) {
		probe = (((unsigned) hash) >> p) & MethodCacheMask;
		methodCache[probe + MethodCacheSelector] = 0;
	}
}


/*	Adjust all oop references by the given number of bytes. This 
	is done just after reading in an image when the new base 
	address of the object heap is different from the base address 
	in the image. */
/*	di 11/18/2000 - return number of objects found */

int adjustAllOopsBy(int bytesToShift) {
register struct foo * foo = &fum;
    int oop;
    int totalObjects;
    int newClassOop;
    int fieldOop;
    int classHeader;
    int fieldAddr;
    int sz;
    int header;
    int chunk;

	if (bytesToShift == 0) {
		return 300000;
	}
	totalObjects = 0;
	/* begin oopFromChunk: */
	chunk = startOfMemory();
	oop = chunk + (headerTypeBytes[(longAt(chunk)) & TypeMask]);
	while (oop < foo->endOfMemory) {
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			totalObjects += 1;
			/* begin adjustFieldsAndClassOf:by: */
			fieldAddr = oop + (lastPointerOf(oop));
			while (fieldAddr > oop) {
				fieldOop = longAt(fieldAddr);
				if (!((fieldOop & 1))) {
					longAtput(fieldAddr, fieldOop + bytesToShift);
				}
				fieldAddr -= 4;
			}
			if (((longAt(oop)) & TypeMask) != HeaderTypeShort) {
				classHeader = longAt(oop - 4);
				newClassOop = (classHeader & AllButTypeMask) + bytesToShift;
				longAtput(oop - 4, newClassOop | (classHeader & TypeMask));
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if (oop >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(oop);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - 8)) & AllButTypeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz) + (headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	}
	return totalObjects;
}


/*	Return true if all the oops in both arrays, and the arrays 
	themselves, are in the young object space. */

int allYoungand(int array1, int array2) {
register struct foo * foo = &fum;
    int fieldOffset;
    int fmt;
    int sz;
    int methodHeader;
    int contextSize;
    int header;
    int sp;
    int header1;
    int type;

	if (array1 < foo->youngStart) {
		return 0;
	}
	if (array2 < foo->youngStart) {
		return 0;
	}
	/* begin lastPointerOf: */
	header = longAt(array1);
	fmt = (((unsigned) header) >> 8) & 15;
	if (fmt <= 4) {
		if ((fmt == 3) && ((((((unsigned) header) >> 12) & 31) == 13) || ((((((unsigned) header) >> 12) & 31) == 14) || (((((unsigned) header) >> 12) & 31) == 4)))) {
			/* begin fetchStackPointerOf: */
			sp = longAt(((((char *) array1)) + BaseHeaderSize) + (StackPointerIndex << 2));
			if (!((sp & 1))) {
				contextSize = 0;
				goto l1;
			}
			contextSize = (sp >> 1);
		l1:	/* end fetchStackPointerOf: */;
			fieldOffset = (CtxtTempFrameStart + contextSize) * 4;
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
			sz = (longAt(array1 - 8)) & AllButTypeMask;
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
	fieldOffset = (((((unsigned) methodHeader) >> 10) & 255) * 4) + BaseHeaderSize;
l4:	/* end lastPointerOf: */;
	while (fieldOffset >= BaseHeaderSize) {
		if ((longAt(array1 + fieldOffset)) < foo->youngStart) {
			return 0;
		}
		if ((longAt(array2 + fieldOffset)) < foo->youngStart) {
			return 0;
		}
		fieldOffset -= 4;
	}
	return 1;
}


/*	Allocate a new object of the given size and number of header words. (Note: byteSize already includes space for the base header word.) Initialize the header fields of the new object and fill the remainder of the object with the given value.
	May cause a GC */

int allocateheaderSizeh1h2h3doFillwith(int byteSize, int hdrSize, int baseHeader, int classOop, int extendedSize, int doFill, int fillWord) {
register struct foo * foo = &fum;
    int newObj;
    unsigned end;
    int remappedClassOop;
    unsigned i;
    int oop;
    int newFreeSize;
    int newChunk;
    int enoughSpace;
    int minFree;

	if (hdrSize > 1) {
		/* begin pushRemappableOop: */
		remapBuffer[foo->remapBufferCount += 1] = classOop;
	}
	/* begin allocateChunk: */
	if (foo->allocationCount >= foo->allocationsBetweenGCs) {
		incrementalGC();
	}
	/* begin sufficientSpaceToAllocate: */
	minFree = (foo->lowSpaceThreshold + (byteSize + ((hdrSize - 1) * 4))) + BaseHeaderSize;
	if ((((unsigned ) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((unsigned ) minFree))) {
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
		/* begin forceInterruptCheck */
		foo->interruptCheckCounter = -1000;
	}
	if ((((unsigned ) ((longAt(foo->freeBlock)) & AllButTypeMask))) < (((unsigned ) ((byteSize + ((hdrSize - 1) * 4)) + BaseHeaderSize)))) {
		error("out of memory");
	}
	newFreeSize = ((longAt(foo->freeBlock)) & AllButTypeMask) - (byteSize + ((hdrSize - 1) * 4));
	newChunk = foo->freeBlock;
	foo->freeBlock += byteSize + ((hdrSize - 1) * 4);
	/* begin setSizeOfFree:to: */
	longAtput(foo->freeBlock, (newFreeSize & AllButTypeMask) | HeaderTypeFree);
	foo->allocationCount += 1;
	newObj = newChunk;
	if (hdrSize > 1) {
		/* begin popRemappableOop */
		oop = remapBuffer[foo->remapBufferCount];
		foo->remapBufferCount -= 1;
		remappedClassOop = oop;
	}
	if (hdrSize == 3) {
		longAtput(newObj, extendedSize | HeaderTypeSizeAndClass);
		longAtput(newObj + 4, remappedClassOop | HeaderTypeSizeAndClass);
		longAtput(newObj + 8, baseHeader | HeaderTypeSizeAndClass);
		newObj += 8;
	}
	if (hdrSize == 2) {
		longAtput(newObj, remappedClassOop | HeaderTypeClass);
		longAtput(newObj + 4, baseHeader | HeaderTypeClass);
		newObj += 4;
	}
	if (hdrSize == 1) {
		longAtput(newObj, baseHeader | HeaderTypeShort);
	}
	if (doFill) {
		end = newObj + byteSize;
		i = newObj + 4;
		while (i < end) {
			longAtput(i, fillWord);
			i += 4;
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


/*	Allocate a chunk of the given size. Sender must be sure that  the requested size includes enough space for the header  word(s).  */
/*	Details: To limit the time per incremental GC, do one every so many allocations. The number is settable via primitiveVMParameter to tune your memory system */

int allocateChunk(int byteSize) {
register struct foo * foo = &fum;
    int newFreeSize;
    int newChunk;
    int enoughSpace;
    int minFree;

	if (foo->allocationCount >= foo->allocationsBetweenGCs) {
		incrementalGC();
	}
	/* begin sufficientSpaceToAllocate: */
	minFree = (foo->lowSpaceThreshold + byteSize) + BaseHeaderSize;
	if ((((unsigned ) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((unsigned ) minFree))) {
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
		/* begin forceInterruptCheck */
		foo->interruptCheckCounter = -1000;
	}
	if ((((unsigned ) ((longAt(foo->freeBlock)) & AllButTypeMask))) < (((unsigned ) (byteSize + BaseHeaderSize)))) {
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

int allocateOrRecycleContext(int needsLarge) {
register struct foo * foo = &fum;
    int cntxt;

	if (needsLarge == 0) {
		if (foo->freeContexts != NilContext) {
			cntxt = foo->freeContexts;
			foo->freeContexts = longAt(((((char *) cntxt)) + BaseHeaderSize) + (0 << 2));
			return cntxt;
		}
	} else {
		if (foo->freeLargeContexts != NilContext) {
			cntxt = foo->freeLargeContexts;
			foo->freeLargeContexts = longAt(((((char *) cntxt)) + BaseHeaderSize) + (0 << 2));
			return cntxt;
		}
	}
	if (needsLarge == 0) {
		cntxt = instantiateContextsizeInBytes(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassMethodContext << 2)), SmallContextSize);
	} else {
		cntxt = instantiateContextsizeInBytes(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassMethodContext << 2)), LargeContextSize);
	}
	longAtput(((((char *) cntxt)) + BaseHeaderSize) + (4 << 2), foo->nilObj);
	return cntxt;
}

int argumentCountOf(int methodPointer) {
	return (((unsigned) (longAt(((((char *) methodPointer)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 25) & 15;
}


/*	Return the address of first indexable field of the word or byte arry-like object arrayOop. Fail if arrayOop is not an indexable bytes or words object. */
/*	Note: May be called by translated primitive code. */

void * arrayValueOf(int arrayOop) {
	if (((arrayOop & 1) == 0) && (isWordsOrBytesNonInt(arrayOop))) {
		return (void *) (arrayOop + 4);
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
}


/*	Returns an integer object */

int asciiOfCharacter(int characterObj) {
register struct foo * foo = &fum;
    int cl;
    int ccIndex;

	/* begin assertClassOf:is: */
	if ((characterObj & 1)) {
		foo->successFlag = 0;
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(characterObj))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(characterObj - 4)) & AllButTypeMask;
	} else {
		cl = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassCharacter << 2)))) && foo->successFlag;
l1:	/* end assertClassOf:is: */;
	if (foo->successFlag) {
		return longAt(((((char *) characterObj)) + BaseHeaderSize) + (CharacterValueIndex << 2));
	} else {
		return ConstZero;
	}
}


/*	Return true if the stack is still balanced after executing primitive primIndex with nArgs args. Delta is 'stackPointer - activeContext' which is a relative measure for the stack pointer (so we don't have to relocate it during the primitive) */

int balancedStackafterPrimitivewithArgs(int delta, int primIdx, int nArgs) {
register struct foo * foo = &fum;
	if ((primIdx >= 81) && (primIdx <= 88)) {
		return 1;
	}
	if (foo->successFlag) {
		return ((foo->stackPointer - foo->activeContext) + (nArgs * 4)) == delta;
	}
	return (foo->stackPointer - foo->activeContext) == delta;
}


/*	If this object is old, mark it as a root (because a new object 
	may be stored into it) */

int beRootIfOld(int oop) {
register struct foo * foo = &fum;
    int header;

	if ((oop < foo->youngStart) && (!((oop & 1)))) {
		/* begin noteAsRoot:headerLoc: */
		header = longAt(oop);
		if ((header & RootBit) == 0) {
			if (foo->rootTableCount < RootTableRedZone) {
				foo->rootTableCount += 1;
				rootTable[foo->rootTableCount] = oop;
				longAtput(oop, header | RootBit);
			} else {
				if (foo->rootTableCount < RootTableSize) {
					foo->rootTableCount += 1;
					rootTable[foo->rootTableCount] = oop;
					longAtput(oop, header | RootBit);
					foo->allocationCount = foo->allocationsBetweenGCs + 1;
				}
			}
		}
	}
}

int becomewith(int array1, int array2) {
	return becomewithtwoWaycopyHash(array1, array2, 1, 1);
}


/*	All references to each object in array1 are swapped with all references to the corresponding object in array2. That is, all pointers to one object are replaced with with pointers to the other. The arguments must be arrays of the same length. 
	Returns true if the primitive succeeds. */
/*	Implementation: Uses forwarding blocks to update references as done in compaction. */

int becomewithtwoWaycopyHash(int array1, int array2, int twoWayFlag, int copyHashFlag) {
register struct foo * foo = &fum;
    int oop2;
    int hdr1;
    int fieldOffset;
    int oop1;
    int hdr2;
    int fwdHeader;
    int fwdBlock;
    int fwdHeader1;
    int fwdBlock1;
    int oop21;
    int hdr11;
    int fwdBlock2;
    int oop11;
    int hdr21;
    int fwdHeader2;
    int fwdBlock11;
    int fmt;
    int sz;
    int methodHeader;
    int contextSize;
    int header;
    int sp;
    int header1;
    int type;

	if (!(((array1 & 1) == 0) && (((((unsigned) (longAt(array1))) >> 8) & 15) == 2))) {
		return 0;
	}
	if (!(((array2 & 1) == 0) && (((((unsigned) (longAt(array2))) >> 8) & 15) == 2))) {
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
		mapPointersInObjectsFromto(startOfMemory(), foo->endOfMemory);
	}
	if (twoWayFlag) {
		/* begin restoreHeadersAfterBecoming:with: */
		/* begin lastPointerOf: */
		header = longAt(array1);
		fmt = (((unsigned) header) >> 8) & 15;
		if (fmt <= 4) {
			if ((fmt == 3) && ((((((unsigned) header) >> 12) & 31) == 13) || ((((((unsigned) header) >> 12) & 31) == 14) || (((((unsigned) header) >> 12) & 31) == 4)))) {
				/* begin fetchStackPointerOf: */
				sp = longAt(((((char *) array1)) + BaseHeaderSize) + (StackPointerIndex << 2));
				if (!((sp & 1))) {
					contextSize = 0;
					goto l1;
				}
				contextSize = (sp >> 1);
			l1:	/* end fetchStackPointerOf: */;
				fieldOffset = (CtxtTempFrameStart + contextSize) * 4;
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
				sz = (longAt(array1 - 8)) & AllButTypeMask;
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
		fieldOffset = (((((unsigned) methodHeader) >> 10) & 255) * 4) + BaseHeaderSize;
	l4:	/* end lastPointerOf: */;
		while (fieldOffset >= BaseHeaderSize) {
			oop1 = longAt(array1 + fieldOffset);
			oop2 = longAt(array2 + fieldOffset);
			/* begin restoreHeaderOf: */
			fwdHeader = longAt(oop1);
			fwdBlock = (fwdHeader & AllButMarkBitAndTypeMask) << 1;
			if (DoAssertionChecks) {
				if ((fwdHeader & MarkBit) == 0) {
					error("attempting to restore the header of an object that has no forwarding block");
				}
				/* begin fwdBlockValidate: */
				if (!((fwdBlock > foo->endOfMemory) && ((fwdBlock <= foo->fwdTableNext) && ((fwdBlock & 3) == 0)))) {
					error("invalid fwd table entry");
				}
			}
			longAtput(oop1, longAt(fwdBlock + 4));
			/* begin restoreHeaderOf: */
			fwdHeader1 = longAt(oop2);
			fwdBlock1 = (fwdHeader1 & AllButMarkBitAndTypeMask) << 1;
			if (DoAssertionChecks) {
				if ((fwdHeader1 & MarkBit) == 0) {
					error("attempting to restore the header of an object that has no forwarding block");
				}
				/* begin fwdBlockValidate: */
				if (!((fwdBlock1 > foo->endOfMemory) && ((fwdBlock1 <= foo->fwdTableNext) && ((fwdBlock1 & 3) == 0)))) {
					error("invalid fwd table entry");
				}
			}
			longAtput(oop2, longAt(fwdBlock1 + 4));
			hdr1 = longAt(oop1);
			hdr2 = longAt(oop2);
			longAtput(oop1, (hdr1 & AllButHashBits) | (hdr2 & HashBits));
			longAtput(oop2, (hdr2 & AllButHashBits) | (hdr1 & HashBits));
			fieldOffset -= 4;
		}
	} else {
		/* begin restoreHeadersAfterForwardBecome: */
		fwdBlock2 = ((foo->endOfMemory + BaseHeaderSize) + 7) & 4294967288U;
		fwdBlock2 += 16;
		while (fwdBlock2 <= foo->fwdTableNext) {
			oop11 = longAt(fwdBlock2 + 8);
			oop21 = longAt(fwdBlock2);
			/* begin restoreHeaderOf: */
			fwdHeader2 = longAt(oop11);
			fwdBlock11 = (fwdHeader2 & AllButMarkBitAndTypeMask) << 1;
			if (DoAssertionChecks) {
				if ((fwdHeader2 & MarkBit) == 0) {
					error("attempting to restore the header of an object that has no forwarding block");
				}
				/* begin fwdBlockValidate: */
				if (!((fwdBlock11 > foo->endOfMemory) && ((fwdBlock11 <= foo->fwdTableNext) && ((fwdBlock11 & 3) == 0)))) {
					error("invalid fwd table entry");
				}
			}
			longAtput(oop11, longAt(fwdBlock11 + 4));
			if (copyHashFlag) {
				hdr11 = longAt(oop11);
				hdr21 = longAt(oop21);
				longAtput(oop21, (hdr21 & AllButHashBits) | (hdr11 & HashBits));
			}
			fwdBlock2 += 16;
		}
	}
	initializeMemoryFirstFree(foo->freeBlock);
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
	return 1;
}


/*	convert true and false (Smalltalk) to true or false(C) */

int booleanValueOf(int obj) {
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

int byteSizeOf(int oop) {
    int slots;
    int header;
    int sz;

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
		sz = (longAt(oop - 8)) & AllButTypeMask;
	} else {
		sz = header & SizeMask;
	}
	if (((((unsigned) header) >> 8) & 15) < 8) {
		slots = ((unsigned) (sz - BaseHeaderSize)) >> 2;
		goto l2;
	} else {
		slots = (sz - BaseHeaderSize) - (((((unsigned) header) >> 8) & 15) & 3);
		goto l2;
	}
	slots = null;
l2:	/* end lengthOf: */;
l1:	/* end slotSizeOf: */;
	if (((((unsigned) (longAt(oop))) >> 8) & 15) >= 8) {
		return slots;
	} else {
		return slots * 4;
	}
}


/*	Byte-swap the words of all bytes objects in a range of the 
	image, including Strings, ByteArrays, and CompiledMethods. 
	This returns these objects to their original byte ordering 
	after blindly byte-swapping the entire image. For compiled 
	methods, byte-swap only their bytecodes part. */

int byteSwapByteObjectsFromto(int startOop, int stopAddr) {
    int fmt;
    int oop;
    int methodHeader;
    int wordAddr;
    int stopAddr1;
    int addr;
    int sz;
    int header;

	oop = startOop;
	while (oop < stopAddr) {
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			fmt = (((unsigned) (longAt(oop))) >> 8) & 15;
			if (fmt >= 8) {
				wordAddr = oop + BaseHeaderSize;
				if (fmt >= 12) {
					methodHeader = longAt(oop + BaseHeaderSize);
					wordAddr = (wordAddr + 4) + (((((unsigned) methodHeader) >> 10) & 255) * 4);
				}
				/* begin reverseBytesFrom:to: */
				stopAddr1 = oop + (sizeBitsOf(oop));
				addr = wordAddr;
				while (addr < stopAddr1) {
					longAtput(addr, ((((((unsigned) (longAt(addr)) >> 24)) & 255) + ((((unsigned) (longAt(addr)) >> 8)) & 65280)) + ((((unsigned) (longAt(addr)) << 8)) & 16711680)) + ((((unsigned) (longAt(addr)) << 24)) & 4278190080U));
					addr += 4;
				}
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if (oop >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(oop);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - 8)) & AllButTypeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz) + (headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	}
}


/*	Return the given integer with its bytes in the reverse order. */

int byteSwapped(int w) {
	return ((((((unsigned) w >> 24)) & 255) + ((((unsigned) w >> 8)) & 65280)) + ((((unsigned) w << 8)) & 16711680)) + ((((unsigned) w << 24)) & 4278190080U);
}


/*	Arg must lie in range 0-255! */

int characterForAscii(int ascii) {
	return longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CharacterTable << 2))))) + BaseHeaderSize) + (ascii << 2));
}

int characterTable(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CharacterTable << 2));
}


/*	Check for possible interrupts and handle one if necessary. */

int checkForInterrupts(void) {
register struct foo * foo = &fum;
    int now;
    int sema;
    int i;
    int xArray;
    int xSize;
    int index;
    int sema1;

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
		sema = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (TheLowSpaceSemaphore << 2));
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
		sema = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (TheInterruptSemaphore << 2));
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
			sema = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (TheTimerSemaphore << 2));
			if (!(sema == foo->nilObj)) {
				synchronousSignal(sema);
			}
		}
	}
	if (foo->pendingFinalizationSignals > 0) {
		sema = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (TheFinalizationSemaphore << 2));
		if ((fetchClassOf(sema)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassSemaphore << 2)))) {
			synchronousSignal(sema);
		}
		foo->pendingFinalizationSignals = 0;
	}
	if ((foo->semaphoresToSignalCountA > 0) || (foo->semaphoresToSignalCountB > 0)) {
		/* begin signalExternalSemaphores */
		foo->semaphoresUseBufferA = !foo->semaphoresUseBufferA;
		xArray = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ExternalObjectsArray << 2));
		xSize = stSizeOf(xArray);
		if (foo->semaphoresUseBufferA) {
			for (i = 1; i <= foo->semaphoresToSignalCountB; i += 1) {
				index = semaphoresToSignalB[i];
				if (index <= xSize) {
					sema1 = longAt(((((char *) xArray)) + BaseHeaderSize) + ((index - 1) << 2));
					if ((fetchClassOf(sema1)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassSemaphore << 2)))) {
						synchronousSignal(sema1);
					}
				}
			}
			foo->semaphoresToSignalCountB = 0;
		} else {
			for (i = 1; i <= foo->semaphoresToSignalCountA; i += 1) {
				index = semaphoresToSignalA[i];
				if (index <= xSize) {
					sema1 = longAt(((((char *) xArray)) + BaseHeaderSize) + ((index - 1) << 2));
					if ((fetchClassOf(sema1)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassSemaphore << 2)))) {
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

int checkImageVersionFromstartingAt(sqImageFile f, squeakFileOffsetType imageOffset) {
    int version;
    int firstVersion;

	sqImageFileSeek(f, imageOffset);
	version = firstVersion = getLongFromFileswap(f, 0);
	if (version == 6502) {
		return 0;
	}
	sqImageFileSeek(f, imageOffset);
	version = getLongFromFileswap(f, 1);
	if (version == 6502) {
		return 1;
	}
	if (imageOffset == 0) {
		sqImageFileSeek(f, 512);
		version = getLongFromFileswap(f, 0);
		if (version == 6502) {
			return 0;
		}
		sqImageFileSeek(f, 512);
		version = getLongFromFileswap(f, 1);
		if (version == 6502) {
			return 1;
		}
	}
	print("This interpreter (vers. ");
	printNum(6502);
	print(" cannot read image file (vers. ");
	printNum(firstVersion);
	/* begin cr */
	printf("\n");
	print("Hit CR to quit");
	getchar();
	ioExit();
}


/*	Note: May be called by translated primitive code. */

int checkedIntegerValueOf(int intOop) {
	if ((intOop & 1)) {
		return (intOop >> 1);
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return 0;
	}
}


/*	Assumes zero-based array indexing. For testing in Smalltalk, this method should be overridden in a subclass. */

int checkedLongAt(int byteAddress) {
register struct foo * foo = &fum;
	/* begin checkAddress: */
	if (byteAddress < (startOfMemory())) {
		error("bad address: negative");
	}
	if (byteAddress >= foo->memoryLimit) {
		error("bad address: past end of heap");
	}
	/* begin checkAddress: */
	if ((byteAddress + 3) < (startOfMemory())) {
		error("bad address: negative");
	}
	if ((byteAddress + 3) >= foo->memoryLimit) {
		error("bad address: past end of heap");
	}
	return longAt(byteAddress);
}

int classArray(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassArray << 2));
}

int classBitmap(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassBitmap << 2));
}

int classByteArray(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassByteArray << 2));
}

int classCharacter(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassCharacter << 2));
}

int classExternalAddress(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassExternalAddress << 2));
}

int classExternalData(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassExternalData << 2));
}

int classExternalFunction(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassExternalFunction << 2));
}

int classExternalLibrary(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassExternalLibrary << 2));
}

int classExternalStructure(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassExternalStructure << 2));
}

int classFloat(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassFloat << 2));
}

int classLargeNegativeInteger(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargeNegativeInteger << 2));
}

int classLargePositiveInteger(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargePositiveInteger << 2));
}


/*	Check if aClass' name is className */

int classNameOfIs(int aClass, char *className) {
    int length;
    char *srcName;
    int name;
    int i;

	if ((lengthOf(aClass)) <= 6) {
		return 0;
	}
	name = longAt(((((char *) aClass)) + BaseHeaderSize) + (6 << 2));
	if (!(((name & 1) == 0) && (((((unsigned) (longAt(name))) >> 8) & 15) >= 8))) {
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

int classPoint(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassPoint << 2));
}

int classSemaphore(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassSemaphore << 2));
}

int classSmallInteger(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
}

int classString(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassString << 2));
}


/*	Return a shallow copy of the given object. May cause GC */
/*	Assume: Oop is a real object, not a small integer. */

int clone(int oop) {
register struct foo * foo = &fum;
    int remappedOop;
    int fromIndex;
    int bytes;
    int newChunk;
    int newOop;
    int extraHdrBytes;
    int toIndex;
    int lastFrom;
    int hash;
    int header;
    int oop1;
    int header1;
    int newFreeSize;
    int newChunk1;
    int enoughSpace;
    int minFree;

	extraHdrBytes = headerTypeBytes[(longAt(oop)) & TypeMask];
	/* begin sizeBitsOf: */
	header1 = longAt(oop);
	if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
		bytes = (longAt(oop - 8)) & AllButTypeMask;
		goto l1;
	} else {
		bytes = header1 & SizeMask;
		goto l1;
	}
l1:	/* end sizeBitsOf: */;

	/* allocate space for the copy, remapping oop in case of a GC */

	bytes += extraHdrBytes;
	/* begin pushRemappableOop: */
	remapBuffer[foo->remapBufferCount += 1] = oop;
	/* begin allocateChunk: */
	if (foo->allocationCount >= foo->allocationsBetweenGCs) {
		incrementalGC();
	}
	/* begin sufficientSpaceToAllocate: */
	minFree = (foo->lowSpaceThreshold + bytes) + BaseHeaderSize;
	if ((((unsigned ) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((unsigned ) minFree))) {
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
		/* begin forceInterruptCheck */
		foo->interruptCheckCounter = -1000;
	}
	if ((((unsigned ) ((longAt(foo->freeBlock)) & AllButTypeMask))) < (((unsigned ) (bytes + BaseHeaderSize)))) {
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
	oop1 = remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	remappedOop = oop1;

	/* loop below uses pre-increment */

	toIndex = newChunk - 4;
	fromIndex = (remappedOop - extraHdrBytes) - 4;
	lastFrom = fromIndex + bytes;
	while (fromIndex < lastFrom) {
		longAtput(toIndex += 4, longAt(fromIndex += 4));
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

int commonAt(int stringy) {
register struct foo * foo = &fum;
    int result;
    int atIx;
    int rcvr;
    int index;
    int sp;
    int sp1;


	/* Sets successFlag */

	index = positive32BitValueOf(longAt(foo->stackPointer));
	rcvr = longAt(foo->stackPointer - (1 * 4));
	if (!(foo->successFlag && (!((rcvr & 1))))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if ((foo->messageSelector == (longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((16 * 2) << 2)))) && (foo->lkupClass == (fetchClassOfNonInt(rcvr)))) {

		/* Index into atCache = 4N, for N = 0 ... 7 */

		atIx = rcvr & AtCacheMask;
		if (!((atCache[atIx + AtCacheOop]) == rcvr)) {
			installinAtCacheatstring(rcvr, atCache, atIx, stringy);
		}
		if (foo->successFlag) {
			result = commonVariableatcacheIndex(rcvr, index, atIx);
		}
		if (foo->successFlag) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * 4), result);
			foo->stackPointer = sp;
			return null;
		}
	}
	foo->successFlag = 1;
	result = stObjectat(rcvr, index);
	if (foo->successFlag) {
		if (stringy) {
			result = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CharacterTable << 2))))) + BaseHeaderSize) + (((result >> 1)) << 2));
		}
		/* begin pop:thenPush: */
		longAtput(sp1 = foo->stackPointer - (((foo->argumentCount + 1) - 1) * 4), result);
		foo->stackPointer = sp1;
		return null;
	}
}


/*	This code is called if the receiver responds primitively to at:Put:.
	If this is so, it will be installed in the atPutCache so that subsequent calls of at:
	or  next may be handled immediately in bytecode primitive routines. */

int commonAtPut(int stringy) {
register struct foo * foo = &fum;
    int value;
    int atIx;
    int rcvr;
    int index;
    int fmt;
    int stSize;
    int fixedFields;
    int valToPut;
    int sp;
    int sp1;

	value = longAt(foo->stackPointer);

	/* Sets successFlag */

	index = positive32BitValueOf(longAt(foo->stackPointer - (1 * 4)));
	rcvr = longAt(foo->stackPointer - (2 * 4));
	if (!(foo->successFlag && (!((rcvr & 1))))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if ((foo->messageSelector == (longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((17 * 2) << 2)))) && (foo->lkupClass == (fetchClassOfNonInt(rcvr)))) {

		/* Index into atPutCache */

		atIx = (rcvr & AtCacheMask) + AtPutBase;
		if (!((atCache[atIx + AtCacheOop]) == rcvr)) {
			installinAtCacheatstring(rcvr, atCache, atIx, stringy);
		}
		if (foo->successFlag) {
			/* begin commonVariable:at:put:cacheIndex: */
			stSize = atCache[atIx + AtCacheSize];
			if (((((unsigned ) index)) >= 1) && ((((unsigned ) index)) <= (((unsigned ) stSize)))) {
				fmt = atCache[atIx + AtCacheFmt];
				if (fmt <= 4) {
					fixedFields = atCache[atIx + AtCacheFixedFields];
					/* begin storePointer:ofObject:withValue: */
					if (rcvr < foo->youngStart) {
						possibleRootStoreIntovalue(rcvr, value);
					}
					longAtput(((((char *) rcvr)) + BaseHeaderSize) + (((index + fixedFields) - 1) << 2), value);
					goto l1;
				}
				if (fmt < 8) {
					valToPut = positive32BitValueOf(value);
					if (foo->successFlag) {
						longAtput(((((char *) rcvr)) + BaseHeaderSize) + ((index - 1) << 2), valToPut);
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
					byteAtput(((((char *) rcvr)) + BaseHeaderSize) + (index - 1), valToPut);
					goto l1;
				}
			}
			/* begin primitiveFail */
			foo->successFlag = 0;
		l1:	/* end commonVariable:at:put:cacheIndex: */;
		}
		if (foo->successFlag) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * 4), value);
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
		longAtput(sp1 = foo->stackPointer - (((foo->argumentCount + 1) - 1) * 4), value);
		foo->stackPointer = sp1;
		return null;
	}
}


/*	This code assumes the reciever has been identified at location atIx in the atCache. */

int commonVariableatcacheIndex(int rcvr, int index, int atIx) {
register struct foo * foo = &fum;
    int fmt;
    int result;
    int stSize;
    int fixedFields;

	stSize = atCache[atIx + AtCacheSize];
	if (((((unsigned ) index)) >= 1) && ((((unsigned ) index)) <= (((unsigned ) stSize)))) {
		fmt = atCache[atIx + AtCacheFmt];
		if (fmt <= 4) {
			fixedFields = atCache[atIx + AtCacheFixedFields];
			return longAt(((((char *) rcvr)) + BaseHeaderSize) + (((index + fixedFields) - 1) << 2));
		}
		if (fmt < 8) {
			result = longAt(((((char *) rcvr)) + BaseHeaderSize) + ((index - 1) << 2));
			result = positive32BitIntegerFor(result);
			return result;
		}
		if (fmt >= 16) {
			return longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CharacterTable << 2))))) + BaseHeaderSize) + ((byteAt(((((char *) rcvr)) + BaseHeaderSize) + (index - 1))) << 2));
		} else {
			return (((byteAt(((((char *) rcvr)) + BaseHeaderSize) + (index - 1))) << 1) | 1);
		}
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
}


/*	May set success to false */
/*	First compare two ST integers... */

int compare31or32Bitsequal(int obj1, int obj2) {
	if (((obj1 & 1)) && ((obj2 & 1))) {
		return obj1 == obj2;
	}
	return (positive32BitValueOf(obj1)) == (positive32BitValueOf(obj2));
}

int compilerCreateActualMessagestoringArgs(int aMessage, int argArray) {
	return compilerHooks[14](aMessage, argArray);
}

int compilerFlushCache(int aCompiledMethod) {
	return compilerHooks[2](aCompiledMethod);
}

int compilerMapFromto(int memStart, int memEnd) {
	return compilerHooks[4](memStart, memEnd);
}

int compilerMark(void) {
	return compilerHooks[9]();
}

int compilerPostGC(void) {
	return compilerHooks[5]();
}

int compilerPostSnapshot(void) {
	return compilerHooks[8]();
}

int compilerPreGC(int fullGCFlag) {
	return compilerHooks[3](fullGCFlag);
}

int compilerPreSnapshot(void) {
	return compilerHooks[7]();
}

int compilerProcessChange(void) {
	return compilerHooks[6]();
}

int compilerProcessChangeto(int oldProc, int newProc) {
	return compilerHooks[6](oldProc, newProc);
}

int compilerTranslateMethod(void) {
	return compilerHooks[1]();
}


/*	Return true if neither array contains a small integer. You 
	can't become: integers! */

int containOnlyOopsand(int array1, int array2) {
    int fieldOffset;
    int fmt;
    int sz;
    int methodHeader;
    int contextSize;
    int header;
    int sp;
    int header1;
    int type;

	/* begin lastPointerOf: */
	header = longAt(array1);
	fmt = (((unsigned) header) >> 8) & 15;
	if (fmt <= 4) {
		if ((fmt == 3) && ((((((unsigned) header) >> 12) & 31) == 13) || ((((((unsigned) header) >> 12) & 31) == 14) || (((((unsigned) header) >> 12) & 31) == 4)))) {
			/* begin fetchStackPointerOf: */
			sp = longAt(((((char *) array1)) + BaseHeaderSize) + (StackPointerIndex << 2));
			if (!((sp & 1))) {
				contextSize = 0;
				goto l1;
			}
			contextSize = (sp >> 1);
		l1:	/* end fetchStackPointerOf: */;
			fieldOffset = (CtxtTempFrameStart + contextSize) * 4;
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
			sz = (longAt(array1 - 8)) & AllButTypeMask;
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
	fieldOffset = (((((unsigned) methodHeader) >> 10) & 255) * 4) + BaseHeaderSize;
l4:	/* end lastPointerOf: */;
	while (fieldOffset >= BaseHeaderSize) {
		if (((longAt(array1 + fieldOffset)) & 1)) {
			return 0;
		}
		if (((longAt(array2 + fieldOffset)) & 1)) {
			return 0;
		}
		fieldOffset -= 4;
	}
	return 1;
}


/*	Does thisCntx have aContext in its sender chain? */

int contexthasSender(int thisCntx, int aContext) {
    int s;
    int nilOop;

	if (thisCntx == aContext) {
		return 0;
	}
	nilOop = foo->nilObj;
	s = longAt(((((char *) thisCntx)) + BaseHeaderSize) + (SenderIndex << 2));
	while (!(s == nilOop)) {
		if (s == aContext) {
			return 1;
		}
		s = longAt(((((char *) s)) + BaseHeaderSize) + (SenderIndex << 2));
	}
	return 0;
}


/*	This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin_copyBits
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided */

int copyBits(void) {
    int fn;

	fn = ioLoadFunctionFrom("copyBits", "BitBltPlugin");
	if (fn == 0) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	return  ((int (*) (void)) fn)();
}


/*	This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin_copyBitsFrom:to:at:
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided */

int copyBitsFromtoat(int x0, int x1, int y) {
    int fn;

	fn = ioLoadFunctionFrom("copyBitsFromtoat", "BitBltPlugin");
	if (fn == 0) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	return  ((int (*) (int, int, int)) fn)(x0, x1, y);
}


/*	Copy this object into the segment beginning at lastSeg.
	Install a forwarding pointer, and save oop and header.
	Fail if out of space.  Return the next segmentAddr if successful. */
/*	Copy the object... */

int copyObjtoSegmentaddrstopAtsaveOopAtheaderAt(int oop, int segmentWordArray, int lastSeg, int stopAddr, int oopPtr, int hdrPtr) {
register struct foo * foo = &fum;
    int bodySize;
    int hdrAddr;
    int extraSize;
    int out;
    int lastIn;
    int in;
    int header;

	if (!(foo->successFlag)) {
		return lastSeg;
	}
	extraSize = headerTypeBytes[(longAt(oop)) & TypeMask];
	/* begin sizeBitsOf: */
	header = longAt(oop);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		bodySize = (longAt(oop - 8)) & AllButTypeMask;
		goto l1;
	} else {
		bodySize = header & SizeMask;
		goto l1;
	}
l1:	/* end sizeBitsOf: */;
	if (((lastSeg + extraSize) + bodySize) >= stopAddr) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin transfer:from:to: */
	in = (oop - extraSize) - 4;
	lastIn = in + ((((int) (extraSize + bodySize) >> 2)) * 4);
	out = (lastSeg + 4) - 4;
	while (in < lastIn) {
		longAtput(out += 4, longAt(in += 4));
	}
	hdrAddr = (lastSeg + 4) + extraSize;
	longAtput(hdrAddr, (longAt(hdrAddr)) & (AllButRootBit - MarkBit));
	/* begin forward:to:savingOopAt:andHeaderAt: */
	longAtput(oopPtr, oop);
	longAtput(hdrPtr, longAt(oop));
	longAtput(oop, (((lastSeg + 4) + extraSize) - segmentWordArray) + HeaderTypeFree);
	return (lastSeg + extraSize) + bodySize;
}


/*	Bundle up the selector, arguments and lookupClass into a Message object. 
	In the process it pops the arguments off the stack, and pushes the message object. 
	This can then be presented as the argument of e.g. #doesNotUnderstand:. 
	ikp 11/20/1999 03:59 -- added hook for external runtime compilers. */
/*	remap lookupClass in case GC happens during allocation */

int createActualMessageTo(int aClass) {
register struct foo * foo = &fum;
    int lookupClass;
    int argumentArray;
    int message;
    int out;
    int lastIn;
    int in;
    int sp;
    int oop;
    int oop1;
    int valuePointer;

	/* begin pushRemappableOop: */
	remapBuffer[foo->remapBufferCount += 1] = aClass;

	/* remap argumentArray in case GC happens during allocation */

	argumentArray = instantiateClassindexableSize(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassArray << 2)), foo->argumentCount);
	/* begin pushRemappableOop: */
	remapBuffer[foo->remapBufferCount += 1] = argumentArray;
	message = instantiateClassindexableSize(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassMessage << 2)), 0);
	/* begin popRemappableOop */
	oop = remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	argumentArray = oop;
	/* begin popRemappableOop */
	oop1 = remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	lookupClass = oop1;
	beRootIfOld(argumentArray);
	if (foo->compilerInitialized) {
		compilerCreateActualMessagestoringArgs(message, argumentArray);
	} else {
		/* begin transfer:from:to: */
		in = (foo->stackPointer - ((foo->argumentCount - 1) * 4)) - 4;
		lastIn = in + (foo->argumentCount * 4);
		out = (argumentArray + BaseHeaderSize) - 4;
		while (in < lastIn) {
			longAtput(out += 4, longAt(in += 4));
		}
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((foo->argumentCount - 1) * 4), message);
		foo->stackPointer = sp;
	}
	foo->argumentCount = 1;
	/* begin storePointer:ofObject:withValue: */
	valuePointer = foo->messageSelector;
	if (message < foo->youngStart) {
		possibleRootStoreIntovalue(message, valuePointer);
	}
	longAtput(((((char *) message)) + BaseHeaderSize) + (MessageSelectorIndex << 2), valuePointer);
	/* begin storePointer:ofObject:withValue: */
	if (message < foo->youngStart) {
		possibleRootStoreIntovalue(message, argumentArray);
	}
	longAtput(((((char *) message)) + BaseHeaderSize) + (MessageArgumentsIndex << 2), argumentArray);
	if ((lastPointerOf(message)) >= ((MessageLookupClassIndex * 4) + BaseHeaderSize)) {
		/* begin storePointer:ofObject:withValue: */
		if (message < foo->youngStart) {
			possibleRootStoreIntovalue(message, lookupClass);
		}
		longAtput(((((char *) message)) + BaseHeaderSize) + (MessageLookupClassIndex << 2), lookupClass);
	}
}


/*	Repaint the portion of the Smalltalk screen bounded by the 
	affected rectangle. Used to synchronize the screen after a 
	Bitblt to the Smalltalk Display object. */

int displayBitsOfLeftTopRightBottom(int aForm, int l, int t, int r, int b) {
register struct foo * foo = &fum;
    int surfaceHandle;
    int right;
    int left;
    int h;
    int w;
    int dispBitsIndex;
    int bottom;
    int d;
    int displayObj;
    int dispBits;
    int top;
    int successValue;

	displayObj = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (TheDisplay << 2));
	if (!(aForm == displayObj)) {
		return null;
	}
	/* begin success: */
	successValue = (((displayObj & 1) == 0) && (((((unsigned) (longAt(displayObj))) >> 8) & 15) <= 4)) && ((lengthOf(displayObj)) >= 4);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		dispBits = longAt(((((char *) displayObj)) + BaseHeaderSize) + (0 << 2));
		w = fetchIntegerofObject(1, displayObj);
		h = fetchIntegerofObject(2, displayObj);
		d = fetchIntegerofObject(3, displayObj);
	}
	if (!(foo->successFlag)) {
		return null;
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
		((int (*) (int, int, int, int, int))showSurfaceFn)(surfaceHandle, left, top, right-left, bottom-top);
	} else {
		dispBitsIndex = dispBits + BaseHeaderSize;
		ioShowDisplay(dispBitsIndex, w, h, d, left, right, top, bottom);
	}
}

int displayObject(void) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (TheDisplay << 2));
}


/*	Rounds negative results towards negative infinity, rather than zero. */

int doPrimitiveDivby(int rcvr, int arg) {
register struct foo * foo = &fum;
    int integerRcvr;
    int result;
    int integerArg;
    int posRcvr;
    int posArg;

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
	foo->successFlag = ((result ^ (result << 1)) >= 0) && foo->successFlag;
	return result;
}

int doPrimitiveModby(int rcvr, int arg) {
register struct foo * foo = &fum;
    int integerRcvr;
    int integerResult;
    int integerArg;

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
	foo->successFlag = ((integerResult ^ (integerResult << 1)) >= 0) && foo->successFlag;
	return integerResult;
}

int dummyReferToProxy(void) {
	interpreterProxy = interpreterProxy;
}

int failed(void) {
	return !foo->successFlag;
}

int falseObject(void) {
	return foo->falseObj;
}


/*	Fetch the instance variable at the given index of the given object. Return the address of first indexable field of resulting array object, or fail if the instance variable does not contain an indexable bytes or words object. */
/*	Note: May be called by translated primitive code. */

void * fetchArrayofObject(int fieldIndex, int objectPointer) {
    int arrayOop;

	arrayOop = longAt(((((char *) objectPointer)) + BaseHeaderSize) + (fieldIndex << 2));
	return arrayValueOf(arrayOop);
}

int fetchClassOf(int oop) {
register struct foo * foo = &fum;
    int ccIndex;

	if ((oop & 1)) {
		return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
	}
	ccIndex = (((unsigned) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		return (longAt(oop - 4)) & AllButTypeMask;
	} else {
		return longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
	}
}

int fetchClassOfNonInt(int oop) {
    int ccIndex;

	ccIndex = (((unsigned) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		return (longAt(oop - 4)) & AllButTypeMask;
	} else {
		return longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
	}
}


/*	Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float. */
/*	Note: May be called by translated primitive code. */

double fetchFloatofObject(int fieldIndex, int objectPointer) {
    int floatOop;

	floatOop = longAt(((((char *) objectPointer)) + BaseHeaderSize) + (fieldIndex << 2));
	return floatValueOf(floatOop);
}


/*	Note: May be called by translated primitive code. */

int fetchIntegerofObject(int fieldIndex, int objectPointer) {
    int intOop;

	intOop = longAt(((((char *) objectPointer)) + BaseHeaderSize) + (fieldIndex << 2));
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

int fetchPointerofObject(int fieldIndex, int oop) {
	return longAt(((((char *) oop)) + BaseHeaderSize) + (fieldIndex << 2));
}


/*	Return the stackPointer of a Context or BlockContext. */

int fetchStackPointerOf(int aContext) {
    int sp;

	sp = longAt(((((char *) aContext)) + BaseHeaderSize) + (StackPointerIndex << 2));
	if (!((sp & 1))) {
		return 0;
	}
	return (sp >> 1);
}

int fetchWordofObject(int fieldIndex, int oop) {
	return longAt(((((char *) oop)) + BaseHeaderSize) + (fieldIndex << 2));
}

int fetchWordLengthOf(int objectPointer) {
    int sz;
    int header;

	/* begin sizeBitsOf: */
	header = longAt(objectPointer);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(objectPointer - 8)) & AllButTypeMask;
		goto l1;
	} else {
		sz = header & SizeMask;
		goto l1;
	}
l1:	/* end sizeBitsOf: */;
	return ((unsigned) (sz - BaseHeaderSize)) >> 2;
}


/*	During sweep phase we have encountered a weak reference. 
	Check if  its object has gone away (or is about to) and if so, signal a 
	semaphore.  */
/*	Do *not* inline this in sweepPhase - it is quite an unlikely 
	case to run into a weak reference */

int finalizeReference(int oop) {
register struct foo * foo = &fum;
    int oopGone;
    int chunk;
    int i;
    int lastField;
    int firstField;
    int weakOop;
    int fmt;
    int sz;
    int methodHeader;
    int contextSize;
    int header;
    int sp;
    int header1;
    int type;

	firstField = BaseHeaderSize + ((nonWeakFieldsOf(oop)) << 2);
	/* begin lastPointerOf: */
	header = longAt(oop);
	fmt = (((unsigned) header) >> 8) & 15;
	if (fmt <= 4) {
		if ((fmt == 3) && ((((((unsigned) header) >> 12) & 31) == 13) || ((((((unsigned) header) >> 12) & 31) == 14) || (((((unsigned) header) >> 12) & 31) == 4)))) {
			/* begin fetchStackPointerOf: */
			sp = longAt(((((char *) oop)) + BaseHeaderSize) + (StackPointerIndex << 2));
			if (!((sp & 1))) {
				contextSize = 0;
				goto l1;
			}
			contextSize = (sp >> 1);
		l1:	/* end fetchStackPointerOf: */;
			lastField = (CtxtTempFrameStart + contextSize) * 4;
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
			sz = (longAt(oop - 8)) & AllButTypeMask;
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
	lastField = (((((unsigned) methodHeader) >> 10) & 255) * 4) + BaseHeaderSize;
l4:	/* end lastPointerOf: */;
	for (i = firstField; i <= lastField; i += 4) {
		weakOop = longAt(oop + i);
		if (!((weakOop == foo->nilObj) || ((weakOop & 1)))) {
			if (weakOop < oop) {
				chunk = weakOop - (headerTypeBytes[(longAt(weakOop)) & TypeMask]);
				oopGone = ((longAt(chunk)) & TypeMask) == HeaderTypeFree;
			} else {
				oopGone = ((longAt(weakOop)) & MarkBit) == 0;
			}
			if (oopGone) {
				longAtput(oop + i, foo->nilObj);
				/* begin signalFinalization: */
				/* begin forceInterruptCheck */
				foo->interruptCheckCounter = -1000;
				foo->pendingFinalizationSignals += 1;
			}
		}
	}
}

int findClassOfMethodforReceiver(int meth, int rcvr) {
register struct foo * foo = &fum;
    int currClass;
    int methodArray;
    int classDictSize;
    int i;
    int classDict;
    int done;
    int sz;
    int header;
    int ccIndex;
    int ccIndex1;

	/* begin fetchClassOf: */
	if ((rcvr & 1)) {
		currClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l2;
	}
	ccIndex = (((unsigned) (longAt(rcvr))) >> 12) & 31;
	if (ccIndex == 0) {
		currClass = (longAt(rcvr - 4)) & AllButTypeMask;
		goto l2;
	} else {
		currClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l2;
	}
l2:	/* end fetchClassOf: */;
	done = 0;
	while (!(done)) {
		classDict = longAt(((((char *) currClass)) + BaseHeaderSize) + (MessageDictionaryIndex << 2));
		/* begin fetchWordLengthOf: */
		/* begin sizeBitsOf: */
		header = longAt(classDict);
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(classDict - 8)) & AllButTypeMask;
			goto l1;
		} else {
			sz = header & SizeMask;
			goto l1;
		}
	l1:	/* end sizeBitsOf: */;
		classDictSize = ((unsigned) (sz - BaseHeaderSize)) >> 2;
		methodArray = longAt(((((char *) classDict)) + BaseHeaderSize) + (MethodArrayIndex << 2));
		i = 0;
		while (i < (classDictSize - SelectorStart)) {
			if (meth == (longAt(((((char *) methodArray)) + BaseHeaderSize) + (i << 2)))) {
				return currClass;
			}
			i += 1;
		}
		currClass = longAt(((((char *) currClass)) + BaseHeaderSize) + (SuperclassIndex << 2));
		done = currClass == foo->nilObj;
	}
	/* begin fetchClassOf: */
	if ((rcvr & 1)) {
		return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
	}
	ccIndex1 = (((unsigned) (longAt(rcvr))) >> 12) & 31;
	if (ccIndex1 == 0) {
		return (longAt(rcvr - 4)) & AllButTypeMask;
	} else {
		return longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex1 - 1) << 2));
	}
	return null;
}


/*	Find the compiled method to be run when the current 
	messageSelector is sent to the given class, setting the values 
	of 'newMethod' and 'primitiveIndex'. */

int findNewMethodInClass(int class) {
register struct foo * foo = &fum;
    int ok;
    int probe;
    int hash;

	/* begin lookupInMethodCacheSel:class: */
	hash = foo->messageSelector ^ class;
	probe = hash & MethodCacheMask;
	if (((methodCache[probe + MethodCacheSelector]) == foo->messageSelector) && ((methodCache[probe + MethodCacheClass]) == class)) {
		foo->newMethod = methodCache[probe + MethodCacheMethod];
		foo->primitiveIndex = methodCache[probe + MethodCachePrim];
		foo->newNativeMethod = methodCache[probe + MethodCacheNative];
		foo->primitiveFunctionPointer = methodCache[probe + MethodCachePrimFunction];
		ok = 1;
		goto l1;
	}
	probe = (((unsigned) hash) >> 1) & MethodCacheMask;
	if (((methodCache[probe + MethodCacheSelector]) == foo->messageSelector) && ((methodCache[probe + MethodCacheClass]) == class)) {
		foo->newMethod = methodCache[probe + MethodCacheMethod];
		foo->primitiveIndex = methodCache[probe + MethodCachePrim];
		foo->newNativeMethod = methodCache[probe + MethodCacheNative];
		foo->primitiveFunctionPointer = methodCache[probe + MethodCachePrimFunction];
		ok = 1;
		goto l1;
	}
	probe = (((unsigned) hash) >> 2) & MethodCacheMask;
	if (((methodCache[probe + MethodCacheSelector]) == foo->messageSelector) && ((methodCache[probe + MethodCacheClass]) == class)) {
		foo->newMethod = methodCache[probe + MethodCacheMethod];
		foo->primitiveIndex = methodCache[probe + MethodCachePrim];
		foo->newNativeMethod = methodCache[probe + MethodCacheNative];
		foo->primitiveFunctionPointer = methodCache[probe + MethodCachePrimFunction];
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

int findObsoleteNamedPrimitivelength(char * functionName, int functionLength) {
    int chIndex;
    const char * entry;
    int index;

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

int findSelectorOfMethodforReceiver(int meth, int rcvr) {
register struct foo * foo = &fum;
    int currClass;
    int methodArray;
    int classDictSize;
    int i;
    int done;
    int classDict;
    int sz;
    int header;
    int ccIndex;

	/* begin fetchClassOf: */
	if ((rcvr & 1)) {
		currClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l2;
	}
	ccIndex = (((unsigned) (longAt(rcvr))) >> 12) & 31;
	if (ccIndex == 0) {
		currClass = (longAt(rcvr - 4)) & AllButTypeMask;
		goto l2;
	} else {
		currClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l2;
	}
l2:	/* end fetchClassOf: */;
	done = 0;
	while (!(done)) {
		classDict = longAt(((((char *) currClass)) + BaseHeaderSize) + (MessageDictionaryIndex << 2));
		/* begin fetchWordLengthOf: */
		/* begin sizeBitsOf: */
		header = longAt(classDict);
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(classDict - 8)) & AllButTypeMask;
			goto l1;
		} else {
			sz = header & SizeMask;
			goto l1;
		}
	l1:	/* end sizeBitsOf: */;
		classDictSize = ((unsigned) (sz - BaseHeaderSize)) >> 2;
		methodArray = longAt(((((char *) classDict)) + BaseHeaderSize) + (MethodArrayIndex << 2));
		i = 0;
		while (i <= (classDictSize - SelectorStart)) {
			if (meth == (longAt(((((char *) methodArray)) + BaseHeaderSize) + (i << 2)))) {
				return longAt(((((char *) classDict)) + BaseHeaderSize) + ((i + SelectorStart) << 2));
			}
			i += 1;
		}
		currClass = longAt(((((char *) currClass)) + BaseHeaderSize) + (SuperclassIndex << 2));
		done = currClass == foo->nilObj;
	}
	return foo->nilObj;
}


/*	Return the first accessible object in the heap. */

int firstAccessibleObject(void) {
register struct foo * foo = &fum;
    int obj;
    int chunk;
    int sz;
    int header;

	/* begin oopFromChunk: */
	chunk = startOfMemory();
	obj = chunk + (headerTypeBytes[(longAt(chunk)) & TypeMask]);
	while (obj < foo->endOfMemory) {
		if (!(((longAt(obj)) & TypeMask) == HeaderTypeFree)) {
			return obj;
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if (obj >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(obj)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(obj)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(obj);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(obj - 8)) & AllButTypeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		obj = (obj + sz) + (headerTypeBytes[(longAt(obj + sz)) & TypeMask]);
	}
	error("heap is empty");
}

void * firstFixedField(int oop) {
	return ((void *) (oop + 4));
}

void * firstIndexableField(int oop) {
register struct foo * foo = &fum;
    int fmt;
    int totalLength;
    int hdr;
    int fixedFields;
    int sz;
    int classFormat;
    int class;
    int ccIndex;

	hdr = longAt(oop);
	fmt = (((unsigned) hdr) >> 8) & 15;
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(oop - 8)) & AllButTypeMask;
	} else {
		sz = hdr & SizeMask;
	}
	if (fmt < 8) {
		totalLength = ((unsigned) (sz - BaseHeaderSize)) >> 2;
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
		class = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l3;
	}
	ccIndex = (((unsigned) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(oop - 4)) & AllButTypeMask;
		goto l3;
	} else {
		class = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l3;
	}
l3:	/* end fetchClassOf: */;
	classFormat = (longAt(((((char *) class)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1;
	fixedFields = (((((unsigned) classFormat) >> 11) & 192) + ((((unsigned) classFormat) >> 2) & 63)) - 1;
l2:	/* end fixedFieldsOf:format:length: */;
	if (fmt < 8) {
		return ((void *) ((oop + 4) + (fixedFields << 2)));
	} else {
		return ((void *) ((oop + 4) + fixedFields));
	}
}

int floatObjectOf(double aFloat) {
    int newFloatObj;

	newFloatObj = instantiateSmallClasssizeInBytesfill(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassFloat << 2)), 12, 0);
	storeFloatAtfrom(newFloatObj + BaseHeaderSize, aFloat);
	return newFloatObj;
}


/*	Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float. */
/*	Note: May be called by translated primitive code. */

double floatValueOf(int oop) {
register struct foo * foo = &fum;
    double result;
    int cl;
    int ccIndex;

	/* begin assertClassOf:is: */
	if ((oop & 1)) {
		foo->successFlag = 0;
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(oop - 4)) & AllButTypeMask;
	} else {
		cl = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassFloat << 2)))) && foo->successFlag;
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

int flushExternalPrimitiveOf(int methodPtr) {
    int lit;

	if (!(((((unsigned) (longAt(((((char *) methodPtr)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 10) & 255) > 0)) {
		return null;
	}
	lit = longAt(((((char *) methodPtr)) + BaseHeaderSize) + ((0 + LiteralStart) << 2));
	if (!((((lit & 1) == 0) && (((((unsigned) (longAt(lit))) >> 8) & 15) == 2)) && ((lengthOf(lit)) == 4))) {
		return null;
	}
	longAtput(((((char *) lit)) + BaseHeaderSize) + (2 << 2), ConstZero);
	longAtput(((((char *) lit)) + BaseHeaderSize) + (3 << 2), ConstZero);
}


/*	Flush the references to external functions from plugin 
	primitives. This will force a reload of those primitives when 
	accessed next. 
	Note: We must flush the method cache here so that any 
	failed primitives are looked up again. */

int flushExternalPrimitives(void) {
register struct foo * foo = &fum;
    int primIdx;
    int oop;
    int primBits;
    int chunk;
    int i;
    int i1;
    int i2;
    int sz;
    int header;

	/* begin oopFromChunk: */
	chunk = startOfMemory();
	oop = chunk + (headerTypeBytes[(longAt(chunk)) & TypeMask]);
	while (oop < foo->endOfMemory) {
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			if (((((unsigned) (longAt(oop))) >> 8) & 15) >= 12) {
				/* begin primitiveIndexOf: */
				primBits = (((unsigned) (longAt(((((char *) oop)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 1) & 268435967;
				primIdx = (primBits & 511) + (((unsigned) primBits) >> 19);
				if (primIdx == PrimitiveExternalCallIndex) {
					flushExternalPrimitiveOf(oop);
				}
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if (oop >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(oop);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - 8)) & AllButTypeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz) + (headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	}
	/* begin flushMethodCache */
	for (i = 1; i <= MethodCacheSize; i += 1) {
		methodCache[i] = 0;
	}
	for (i = 1; i <= AtCacheTotalSize; i += 1) {
		atCache[i] = 0;
	}
	/* begin flushObsoleteIndexedPrimitives */
	for (i1 = 1; i1 <= MaxPrimitiveIndex; i1 += 1) {
		(obsoleteIndexedPrimitiveTable[i1])[2] = null;
	}
	/* begin flushExternalPrimitiveTable */
	for (i2 = 0; i2 <= (MaxExternalPrimitiveTableSize - 1); i2 += 1) {
		externalPrimitiveTable[i2] = 0;
	}
}


/*	force an interrupt check ASAP */

int forceInterruptCheck(void) {
	foo->interruptCheckCounter = -1000;
}


/*	Repaint the entire smalltalk screen, ignoring the affected rectangle. Used in some platform's code when the Smalltalk window is brought to the front or uncovered. */

int fullDisplayUpdate(void) {
    int w;
    int h;
    int displayObj;

	displayObj = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (TheDisplay << 2));
	if ((((displayObj & 1) == 0) && (((((unsigned) (longAt(displayObj))) >> 8) & 15) <= 4)) && ((lengthOf(displayObj)) >= 4)) {
		w = fetchIntegerofObject(1, displayObj);
		h = fetchIntegerofObject(2, displayObj);
		displayBitsOfLeftTopRightBottom(displayObj, 0, 0, w, h);
		ioForceDisplayUpdate();
	}
}


/*	Do a mark/sweep garbage collection of the entire object memory. Free inaccessible objects but do not move them. */

int fullGC(void) {
register struct foo * foo = &fum;
    int startTime;
    int oop;
    int i;
    int sz;
    int delta;
    int limit;
    int delta1;
    int limit1;

	if (DoAssertionChecks) {
		reverseDisplayFromto(0, 7);
	}
	/* begin preGCAction: */
	if (foo->compilerInitialized) {
		compilerPreGC(1);
	} else {
		/* begin storeContextRegisters: */
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (StackPointerIndex << 2), (((((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - TempFrameStart) + 1) << 1) | 1));
	}
	startTime = ioMicroMSecs();
	/* begin clearRootsTable */
	for (i = 1; i <= foo->rootTableCount; i += 1) {
		oop = rootTable[i];
		longAtput(oop, (longAt(oop)) & AllButRootBit);
		rootTable[i] = 0;
	}
	foo->rootTableCount = 0;

	/* process all of memory */

	foo->youngStart = startOfMemory();
	markPhase();
	foo->totalObjectCount = sweepPhase();
	/* begin fullCompaction */
	foo->compStart = lowestFreeAfter(startOfMemory());
	if (foo->compStart == foo->freeBlock) {
		initializeMemoryFirstFree(foo->freeBlock);
		goto l1;
	}
	if ((sz = fwdTableSize(8)) < foo->totalObjectCount) {
		/* begin growObjectMemory: */
		delta = ((foo->totalObjectCount - sz) + 10000) * 8;
		limit = sqGrowMemoryBy(foo->memoryLimit, delta);
		if (!(limit == foo->memoryLimit)) {
			foo->memoryLimit = limit - 24;
			initializeMemoryFirstFree(foo->freeBlock);
		}
	}
	while (foo->compStart < foo->freeBlock) {
		foo->compStart = incCompBody();
	}
l1:	/* end fullCompaction */;
	foo->allocationCount = 0;
	foo->statFullGCs += 1;
	foo->statFullGCMSecs += (ioMicroMSecs()) - startTime;

	/* reset the young object boundary */

	foo->youngStart = foo->freeBlock;
	/* begin postGCAction */
	if (foo->compilerInitialized) {
		compilerPostGC();
	} else {
		if (foo->activeContext < foo->youngStart) {
			beRootIfOld(foo->activeContext);
		}
		if (foo->theHomeContext < foo->youngStart) {
			beRootIfOld(foo->theHomeContext);
		}
	}
	if (((longAt(foo->freeBlock)) & AllButTypeMask) > foo->shrinkThreshold) {
		/* begin shrinkObjectMemory: */
		delta1 = ((longAt(foo->freeBlock)) & AllButTypeMask) - foo->growHeadroom;
		limit1 = sqShrinkMemoryBy(foo->memoryLimit, delta1);
		if (!(limit1 == foo->memoryLimit)) {
			foo->memoryLimit = limit1 - 24;
			initializeMemoryFirstFree(foo->freeBlock);
		}
	}
	if (DoAssertionChecks) {
		reverseDisplayFromto(0, 7);
	}
}


/*	Set the limits for a table of two- or three-word forwarding blocks above the last used oop. The pointer fwdTableNext moves up to fwdTableLast. Used for compaction of memory and become-ing objects. Returns the number of forwarding blocks available. */

int fwdTableInit(int blkSize) {
register struct foo * foo = &fum;
	/* begin setSizeOfFree:to: */
	longAtput(foo->freeBlock, (BaseHeaderSize & AllButTypeMask) | HeaderTypeFree);

	/* make a fake free chunk at endOfMemory for use as a sentinal in memory scans */

	foo->endOfMemory = foo->freeBlock + BaseHeaderSize;
	/* begin setSizeOfFree:to: */
	longAtput(foo->endOfMemory, (BaseHeaderSize & AllButTypeMask) | HeaderTypeFree);
	foo->fwdTableNext = ((foo->endOfMemory + BaseHeaderSize) + 7) & 4294967288U;

	/* last forwarding table entry */
	/* return the number of forwarding blocks available */

	foo->fwdTableLast = foo->memoryLimit - blkSize;
	return (foo->fwdTableLast - foo->fwdTableNext) / blkSize;
}


/*	Estimate the number of forwarding blocks available for compaction */

int fwdTableSize(int blkSize) {
register struct foo * foo = &fum;
    int fwdFirst;
    int eom;
    int fwdLast;


	/* use all memory free between freeBlock and memoryLimit for forwarding table */
	/* Note: Forward blocks must be quadword aligned. */

	eom = foo->freeBlock + BaseHeaderSize;
	fwdFirst = ((eom + BaseHeaderSize) + 7) & 4294967288U;

	/* last forwarding table entry */
	/* return the number of forwarding blocks available */

	fwdLast = foo->memoryLimit - blkSize;
	return (fwdLast - fwdFirst) / blkSize;
}


/*	currentBytecode will be private to the main dispatch loop in the generated code. This method allows the currentBytecode to be retrieved from global variables. */

int getCurrentBytecode(void) {
	return byteAt(foo->instructionPointer);
}

int getFullScreenFlag(void) {
	return foo->fullScreenFlag;
}

int getInterruptCheckCounter(void) {
	return foo->interruptCheckCounter;
}

int getInterruptKeycode(void) {
	return foo->interruptKeycode;
}

int getInterruptPending(void) {
	return foo->interruptPending;
}


/*	Return the next 4-byte word of the given file, byte-swapped according to the given flag. */

int getLongFromFileswap(sqImageFile f, int swapFlag) {
    int w;

	sqImageFileRead(&w, sizeof(char), 4, f);
	if (swapFlag) {
		return ((((((unsigned) w >> 24)) & 255) + ((((unsigned) w >> 8)) & 65280)) + ((((unsigned) w << 8)) & 16711680)) + ((((unsigned) w << 24)) & 4278190080U);
	} else {
		return w;
	}
}

int getNextWakeupTick(void) {
	return foo->nextWakeupTick;
}

int getSavedWindowSize(void) {
	return foo->savedWindowSize;
}


/*	a more complex version that tells both the word reversal and the endianness of the machine it came from.  Low half of word is 6502.  Top byte is top byte of #doesNotUnderstand: on this machine. ($d on the Mac or $s on the PC) */

int imageSegmentVersion(void) {
    int wholeWord;


	/* first data word, 'does'  */

	wholeWord = longAt((longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SelectorDoesNotUnderstand << 2))) + BaseHeaderSize);
	return 6502 | (wholeWord & 4278190080U);
}


/*	Move objects to consolidate free space into one big chunk. Return the newly created free chunk. */

int incCompBody(void) {
register struct foo * foo = &fum;
    int bytesFreed;

	fwdTableInit(8);

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

int incCompMakeFwd(void) {
register struct foo * foo = &fum;
    int oop;
    int bytesFreed;
    int fwdBlock;
    int newOop;
    int originalHeaderType;
    int originalHeader;
    int sz;
    int realHeader;
    int fwdBlock1;
    int header;
    int sz1;
    int header1;

	bytesFreed = 0;
	oop = foo->compStart + (headerTypeBytes[(longAt(foo->compStart)) & TypeMask]);
	while (oop < foo->endOfMemory) {
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			bytesFreed += (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin fwdBlockGet: */
			foo->fwdTableNext += 8;
			if (foo->fwdTableNext <= foo->fwdTableLast) {
				fwdBlock = foo->fwdTableNext;
				goto l1;
			} else {
				fwdBlock = null;
				goto l1;
			}
		l1:	/* end fwdBlockGet: */;
			if (fwdBlock == null) {
				foo->compEnd = oop - (headerTypeBytes[(longAt(oop)) & TypeMask]);
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
			longAtput(fwdBlock + 4, originalHeader);
			if (0) {
				longAtput(fwdBlock + 8, oop);
			}
			longAtput(oop, (((unsigned) fwdBlock) >> 1) | (MarkBit | originalHeaderType));
		}
		/* begin objectAfterWhileForwarding: */
		header = longAt(oop);
		if ((header & MarkBit) == 0) {
			/* begin objectAfter: */
			if (DoAssertionChecks) {
				if (oop >= foo->endOfMemory) {
					error("no objects after the end of memory");
				}
			}
			if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
				sz1 = (longAt(oop)) & AllButTypeMask;
			} else {
				/* begin sizeBitsOf: */
				header1 = longAt(oop);
				if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
					sz1 = (longAt(oop - 8)) & AllButTypeMask;
					goto l2;
				} else {
					sz1 = header1 & SizeMask;
					goto l2;
				}
			l2:	/* end sizeBitsOf: */;
			}
			oop = (oop + sz1) + (headerTypeBytes[(longAt(oop + sz1)) & TypeMask]);
			goto l3;
		}
		fwdBlock1 = (header & AllButMarkBitAndTypeMask) << 1;
		if (DoAssertionChecks) {
			/* begin fwdBlockValidate: */
			if (!((fwdBlock1 > foo->endOfMemory) && ((fwdBlock1 <= foo->fwdTableNext) && ((fwdBlock1 & 3) == 0)))) {
				error("invalid fwd table entry");
			}
		}
		realHeader = longAt(fwdBlock1 + 4);
		if ((realHeader & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(oop - 8)) & AllButTypeMask;
		} else {
			sz = realHeader & SizeMask;
		}
		oop = (oop + sz) + (headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
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

int incCompMove(int bytesFreed) {
register struct foo * foo = &fum;
    int newFreeChunk;
    int target;
    int sz;
    int fwdBlock;
    int newOop;
    int w;
    int lastWord;
    int next;
    int oop;
    int firstWord;
    int header;
    int bytesToMove;
    int header1;
    int sz2;
    int realHeader;
    int fwdBlock1;
    int header2;
    int sz1;
    int header11;

	newOop = null;
	oop = foo->compStart + (headerTypeBytes[(longAt(foo->compStart)) & TypeMask]);
	while (oop < foo->compEnd) {
		/* begin objectAfterWhileForwarding: */
		header2 = longAt(oop);
		if ((header2 & MarkBit) == 0) {
			/* begin objectAfter: */
			if (DoAssertionChecks) {
				if (oop >= foo->endOfMemory) {
					error("no objects after the end of memory");
				}
			}
			if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
				sz1 = (longAt(oop)) & AllButTypeMask;
			} else {
				/* begin sizeBitsOf: */
				header11 = longAt(oop);
				if ((header11 & TypeMask) == HeaderTypeSizeAndClass) {
					sz1 = (longAt(oop - 8)) & AllButTypeMask;
					goto l2;
				} else {
					sz1 = header11 & SizeMask;
					goto l2;
				}
			l2:	/* end sizeBitsOf: */;
			}
			next = (oop + sz1) + (headerTypeBytes[(longAt(oop + sz1)) & TypeMask]);
			goto l3;
		}
		fwdBlock1 = (header2 & AllButMarkBitAndTypeMask) << 1;
		if (DoAssertionChecks) {
			/* begin fwdBlockValidate: */
			if (!((fwdBlock1 > foo->endOfMemory) && ((fwdBlock1 <= foo->fwdTableNext) && ((fwdBlock1 & 3) == 0)))) {
				error("invalid fwd table entry");
			}
		}
		realHeader = longAt(fwdBlock1 + 4);
		if ((realHeader & TypeMask) == HeaderTypeSizeAndClass) {
			sz2 = (longAt(oop - 8)) & AllButTypeMask;
		} else {
			sz2 = realHeader & SizeMask;
		}
		next = (oop + sz2) + (headerTypeBytes[(longAt(oop + sz2)) & TypeMask]);
	l3:	/* end objectAfterWhileForwarding: */;
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			fwdBlock = ((longAt(oop)) & AllButMarkBitAndTypeMask) << 1;
			if (DoAssertionChecks) {
				/* begin fwdBlockValidate: */
				if (!((fwdBlock > foo->endOfMemory) && ((fwdBlock <= foo->fwdTableNext) && ((fwdBlock & 3) == 0)))) {
					error("invalid fwd table entry");
				}
			}
			newOop = longAt(fwdBlock);
			header = longAt(fwdBlock + 4);
			longAtput(oop, header);

			/* move the oop (including any extra header words)  */

			bytesToMove = oop - newOop;
			/* begin sizeBitsOf: */
			header1 = longAt(oop);
			if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - 8)) & AllButTypeMask;
				goto l1;
			} else {
				sz = header1 & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
			firstWord = oop - (headerTypeBytes[(longAt(oop)) & TypeMask]);
			lastWord = (oop + sz) - BaseHeaderSize;
			target = firstWord - bytesToMove;
			for (w = firstWord; w <= lastWord; w += 4) {
				longAtput(target, longAt(w));
				target += 4;
			}
		}
		oop = next;
	}
	if (newOop == null) {
		oop = foo->compStart + (headerTypeBytes[(longAt(foo->compStart)) & TypeMask]);
		if ((((longAt(oop)) & TypeMask) == HeaderTypeFree) && ((objectAfter(oop)) == (foo->compEnd + (headerTypeBytes[(longAt(foo->compEnd)) & TypeMask])))) {
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
		if (!((objectAfter(newFreeChunk)) == (foo->compEnd + (headerTypeBytes[(longAt(foo->compEnd)) & TypeMask])))) {
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

int includesBehaviorThatOf(int aClass, int aSuperclass) {
register struct foo * foo = &fum;
    int theClass;

	if (((theClass = aClass) == aSuperclass) || (aSuperclass == foo->nilObj)) {
		return 1;
	}
	do {
		if ((theClass = longAt(((((char *) theClass)) + BaseHeaderSize) + (SuperclassIndex << 2))) == aSuperclass) {
			return 1;
		}
	} while(theClass != foo->nilObj);
	return 0;
}


/*	Do a mark/sweep garbage collection of just the young object 
	area of object memory (i.e., objects above youngStart), using 
	the root table to identify objects containing pointers to 
	young objects from the old object area. */

int incrementalGC(void) {
register struct foo * foo = &fum;
    int survivorCount;
    int startTime;
    int oop;
    int i;
    int oop1;
    int badRoot;
    int fieldOop;
    int fieldAddr;
    int header;
    int delta;
    int limit;
    int sz;
    int header1;
    int chunk;

	if (foo->rootTableCount >= RootTableSize) {
		foo->statRootTableOverflows += 1;
		return fullGC();
	}
	if (DoAssertionChecks) {
		reverseDisplayFromto(8, 15);
		/* begin validateRoots */
		badRoot = 0;
		/* begin oopFromChunk: */
		chunk = startOfMemory();
		oop1 = chunk + (headerTypeBytes[(longAt(chunk)) & TypeMask]);
		while (oop1 < foo->youngStart) {
			if (!(((longAt(oop1)) & TypeMask) == HeaderTypeFree)) {
				fieldAddr = oop1 + (lastPointerOf(oop1));
				while (fieldAddr > oop1) {
					fieldOop = longAt(fieldAddr);
					if ((fieldOop >= foo->youngStart) && (!((fieldOop & 1)))) {
						header = longAt(oop1);
						if ((header & RootBit) == 0) {
							if (DoAssertionChecks) {
								error("root bit not set");
							}
							badRoot = 1;
						} else {
							null;
						}
					}
					fieldAddr -= 4;
				}
			}
			/* begin objectAfter: */
			if (DoAssertionChecks) {
				if (oop1 >= foo->endOfMemory) {
					error("no objects after the end of memory");
				}
			}
			if (((longAt(oop1)) & TypeMask) == HeaderTypeFree) {
				sz = (longAt(oop1)) & AllButTypeMask;
			} else {
				/* begin sizeBitsOf: */
				header1 = longAt(oop1);
				if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
					sz = (longAt(oop1 - 8)) & AllButTypeMask;
					goto l1;
				} else {
					sz = header1 & SizeMask;
					goto l1;
				}
			l1:	/* end sizeBitsOf: */;
			}
			oop1 = (oop1 + sz) + (headerTypeBytes[(longAt(oop1 + sz)) & TypeMask]);
		}
	}
	/* begin preGCAction: */
	if (foo->compilerInitialized) {
		compilerPreGC(0);
	} else {
		/* begin storeContextRegisters: */
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (StackPointerIndex << 2), (((((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - TempFrameStart) + 1) << 1) | 1));
	}
	startTime = ioMicroMSecs();
	markPhase();
	survivorCount = sweepPhase();
	/* begin incrementalCompaction */
	if (foo->compStart == foo->freeBlock) {
		initializeMemoryFirstFree(foo->freeBlock);
	} else {
		incCompBody();
	}
	foo->allocationCount = 0;
	foo->statIncrGCs += 1;
	foo->statIncrGCMSecs += (ioMicroMSecs()) - startTime;
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
	if ((survivorCount > foo->tenuringThreshold) || (foo->rootTableCount >= RootTableRedZone)) {
		foo->statTenures += 1;
		/* begin clearRootsTable */
		for (i = 1; i <= foo->rootTableCount; i += 1) {
			oop = rootTable[i];
			longAtput(oop, (longAt(oop)) & AllButRootBit);
			rootTable[i] = 0;
		}
		foo->rootTableCount = 0;
		foo->youngStart = foo->freeBlock;
	}
	/* begin postGCAction */
	if (foo->compilerInitialized) {
		compilerPostGC();
	} else {
		if (foo->activeContext < foo->youngStart) {
			beRootIfOld(foo->activeContext);
		}
		if (foo->theHomeContext < foo->youngStart) {
			beRootIfOld(foo->theHomeContext);
		}
	}
	if (((longAt(foo->freeBlock)) & AllButTypeMask) > foo->shrinkThreshold) {
		/* begin shrinkObjectMemory: */
		delta = ((longAt(foo->freeBlock)) & AllButTypeMask) - foo->growHeadroom;
		limit = sqShrinkMemoryBy(foo->memoryLimit, delta);
		if (!(limit == foo->memoryLimit)) {
			foo->memoryLimit = limit - 24;
			initializeMemoryFirstFree(foo->freeBlock);
		}
	}
	if (DoAssertionChecks) {
		reverseDisplayFromto(8, 15);
	}
}


/*	Initialize hooks for the 'null compiler' */

int initCompilerHooks(void) {
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


/*	Initialize endOfMemory to the top of oop storage space, reserving some space for forwarding blocks, and create the freeBlock from which space is allocated. Also create a fake free chunk at endOfMemory to act as a sentinal for memory scans.  */
/*	Note: The amount of space reserved for forwarding blocks should be chosen to ensure that incremental compactions can usually be done in a single pass. However, there should be enough forwarding blocks so a full compaction can be done in a reasonable number of passes, say ten. (A full compaction requires N object-moving passes, where N = number of non-garbage objects / number of forwarding blocks). 
	di 11/18/2000 Re totalObjectCount: Provide a margin of one byte per object to be used for forwarding pointers at GC time. Since fwd blocks are 8 bytes, this means an absolute worst case of 8 passes to compact memory. In most cases it will be adequate to do compaction in a single pass.  */
/*	reserve space for forwarding blocks */

int initializeMemoryFirstFree(int firstFree) {
register struct foo * foo = &fum;
    int fwdBlockBytes;

	fwdBlockBytes = foo->totalObjectCount & 4294967292U;
	if (!((foo->memoryLimit - fwdBlockBytes) >= (firstFree + BaseHeaderSize))) {
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
		if (!((foo->endOfMemory + (headerTypeBytes[(longAt(foo->endOfMemory)) & TypeMask])) == foo->endOfMemory)) {
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

int initializeObjectMemory(int bytesToShift) {
register struct foo * foo = &fum;

	/* image may be at a different address; adjust oops for new location */

	foo->youngStart = foo->endOfMemory;
	foo->totalObjectCount = adjustAllOopsBy(bytesToShift);
	initializeMemoryFirstFree(foo->endOfMemory);

	/* heavily used special objects */

	foo->specialObjectsOop += bytesToShift;
	foo->nilObj = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (NilObject << 2));
	foo->falseObj = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (FalseObject << 2));
	foo->trueObj = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (TrueObject << 2));
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
}


/*	Install the oop of this object in the given cache (at or atPut), along with
	its size, format and fixedSize */

int installinAtCacheatstring(int rcvr, int *cache, int atIx, int stringy) {
register struct foo * foo = &fum;
    int fmt;
    int totalLength;
    int hdr;
    int fixedFields;
    int sz;
    int classFormat;
    int class;
    int ccIndex;

	hdr = longAt(rcvr);
	fmt = (((unsigned) hdr) >> 8) & 15;
	if ((fmt == 3) && ((((((unsigned) hdr) >> 12) & 31) == 13) || ((((((unsigned) hdr) >> 12) & 31) == 14) || (((((unsigned) hdr) >> 12) & 31) == 4)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(rcvr - 8)) & AllButTypeMask;
	} else {
		sz = hdr & SizeMask;
	}
	if (fmt < 8) {
		totalLength = ((unsigned) (sz - BaseHeaderSize)) >> 2;
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
		class = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l3;
	}
	ccIndex = (((unsigned) (longAt(rcvr))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(rcvr - 4)) & AllButTypeMask;
		goto l3;
	} else {
		class = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l3;
	}
l3:	/* end fetchClassOf: */;
	classFormat = (longAt(((((char *) class)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1;
	fixedFields = (((((unsigned) classFormat) >> 11) & 192) + ((((unsigned) classFormat) >> 2) & 63)) - 1;
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


/*	 
	NOTE: This method supports the backward-compatible split instSize field of the 
	class format word. The sizeHiBits will go away and other shifts change by 2 
	when the split fields get merged in an (incompatible) image change.  */

int instantiateClassindexableSize(int classPointer, int size) {
register struct foo * foo = &fum;
    int newObj;
    int header3;
    int binc;
    int hdrSize;
    int cClass;
    int byteSize;
    int header1;
    int hash;
    int fillWord;
    int sizeHiBits;
    int header2;
    int format;
    int inc;

	if (DoAssertionChecks) {
		if (size < 0) {
			error("cannot have a negative indexable field count");
		}
	}
	/* begin newObjectHash */
	foo->lastHash = (13849 + (27181 * foo->lastHash)) & 65535;
	hash = foo->lastHash;

	/* Low 2 bits are 0 */

	header1 = (longAt(((((char *) classPointer)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1;
	sizeHiBits = ((unsigned) (header1 & 393216)) >> 9;
	header1 = (header1 & 131071) | ((hash << HashBitsOffset) & HashBits);
	header2 = classPointer;
	header3 = 0;

	/* compact class field from format word */

	cClass = header1 & CompactClassMask;

	/* size in bytes -- low 2 bits are 0 */

	byteSize = (header1 & SizeMask) + sizeHiBits;
	format = (((unsigned) header1) >> 8) & 15;
	if (format < 8) {
		inc = size * 4;
	} else {

		/* round up */

		inc = (size + 3) & AllButTypeMask;

		/* odd bytes */
		/* low bits of byte size go in format field */

		binc = 3 - ((size + 3) & 3);
		header1 = header1 | (binc << 8);
	}
	if ((byteSize + inc) > 255) {
		header3 = byteSize + inc;
		header1 -= byteSize & 255;
	} else {
		header1 += inc;
	}
	byteSize += inc;
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
	newObj = allocateheaderSizeh1h2h3doFillwith(byteSize, hdrSize, header1, header2, header3, 1, fillWord);
	return newObj;
}


/*	This version of instantiateClass assumes that the total object 
	size is under 256 bytes, the limit for objects with only one or 
	two header words. Note that the size is specified in bytes 
	and should include four bytes for the base header word. */

int instantiateContextsizeInBytes(int classPointer, int sizeInBytes) {
register struct foo * foo = &fum;
    int header1;
    int hash;
    int header2;
    int hdrSize;

	/* begin newObjectHash */
	foo->lastHash = (13849 + (27181 * foo->lastHash)) & 65535;
	hash = foo->lastHash;
	header1 = ((hash << HashBitsOffset) & HashBits) | ((longAt(((((char *) classPointer)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1);
	header1 += sizeInBytes - (header1 & SizeMask);
	header2 = classPointer;
	if ((header1 & CompactClassMask) == 0) {
		hdrSize = 2;
	} else {
		hdrSize = 1;
	}
	return allocateheaderSizeh1h2h3doFillwith(sizeInBytes, hdrSize, header1, header2, 0, 0, 0);
}


/*	This version of instantiateClass assumes that the total object 
	size is under 256 bytes, the limit for objects with only one or 
	two header words. Note that the size is specified in bytes 
	and should include four bytes for the base header word. 
	May cause a GC */

int instantiateSmallClasssizeInBytesfill(int classPointer, int sizeInBytes, int fillValue) {
register struct foo * foo = &fum;
    int header1;
    int hash;
    int header2;
    int hdrSize;

	/* begin newObjectHash */
	foo->lastHash = (13849 + (27181 * foo->lastHash)) & 65535;
	hash = foo->lastHash;
	header1 = ((hash << HashBitsOffset) & HashBits) | ((longAt(((((char *) classPointer)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1);
	header1 += sizeInBytes - (header1 & SizeMask);
	header2 = classPointer;
	if ((header1 & CompactClassMask) == 0) {
		hdrSize = 2;
	} else {
		hdrSize = 1;
	}
	return allocateheaderSizeh1h2h3doFillwith(sizeInBytes, hdrSize, header1, header2, 0, 1, fillValue);
}

int integerObjectOf(int value) {
	if (value < 0) {
		return ((2147483648U + value) << 1) + 1;
	} else {
		return (value << 1) + 1;
	}
}


/*	Translator produces 'objectPointer >> 1' */

int integerValueOf(int objectPointer) {
	if ((objectPointer & 2147483648U) != 0) {
		return ((((unsigned) (objectPointer & 2147483647U)) >> 1) - 1073741823) - 1;
	} else {
		return ((unsigned) objectPointer) >> 1;
	}
}


/*	This is the main interpreter loop. It normally loops forever, fetching and executing bytecodes. When running in the context of a browser plugin VM, however, it must return control to the browser periodically. This should done only when the state of the currently running Squeak thread is safely stored in the object heap. Since this is the case at the moment that a check for interrupts is performed, that is when we return to the browser if it is time to do so. Interrupt checks happen quite frequently. */
/*	record entry time when running as a browser plug-in */

int interpret(void) {
register struct foo * foo = &fum;
    int localReturnValue;
    int localReturnContext;
    int localHomeContext;
    char* localSP;
    char* localIP;
    int currentBytecode;

	browserPluginInitialiseIfNeeded();
	/* begin internalizeIPandSP */
	localIP = ((char *) foo->instructionPointer);
	localSP = ((char *) foo->stackPointer);
	localHomeContext = foo->theHomeContext;
	/* begin fetchNextBytecode */
	currentBytecode = byteAt(++localIP);
	while (1) {
		switch (currentBytecode) {
		case 0:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((0 & 15) << 2)));
			}
;
			break;
		case 1:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((1 & 15) << 2)));
			}
;
			break;
		case 2:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((2 & 15) << 2)));
			}
;
			break;
		case 3:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((3 & 15) << 2)));
			}
;
			break;
		case 4:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((4 & 15) << 2)));
			}
;
			break;
		case 5:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((5 & 15) << 2)));
			}
;
			break;
		case 6:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((6 & 15) << 2)));
			}
;
			break;
		case 7:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((7 & 15) << 2)));
			}
;
			break;
		case 8:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((8 & 15) << 2)));
			}
;
			break;
		case 9:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((9 & 15) << 2)));
			}
;
			break;
		case 10:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((10 & 15) << 2)));
			}
;
			break;
		case 11:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((11 & 15) << 2)));
			}
;
			break;
		case 12:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((12 & 15) << 2)));
			}
;
			break;
		case 13:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((13 & 15) << 2)));
			}
;
			break;
		case 14:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((14 & 15) << 2)));
			}
;
			break;
		case 15:
			/* pushReceiverVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushReceiverVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + ((15 & 15) << 2)));
			}
;
			break;
		case 16:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((16 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 17:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((17 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 18:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((18 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 19:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((19 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 20:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((20 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 21:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((21 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 22:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((22 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 23:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((23 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 24:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((24 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 25:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((25 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 26:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((26 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 27:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((27 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 28:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((28 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 29:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((29 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 30:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((30 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 31:
			/* pushTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushTemporaryVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((31 & 15) + TempFrameStart) << 2)));
			}
;
			break;
		case 32:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((32 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 33:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((33 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 34:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((34 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 35:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((35 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 36:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((36 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 37:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((37 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 38:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((38 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 39:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((39 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 40:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((40 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 41:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((41 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 42:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((42 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 43:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((43 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 44:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((44 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 45:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((45 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 46:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((46 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 47:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((47 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 48:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((48 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 49:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((49 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 50:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((50 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 51:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((51 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 52:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((52 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 53:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((53 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 54:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((54 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 55:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((55 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 56:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((56 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 57:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((57 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 58:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((58 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 59:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((59 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 60:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((60 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 61:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((61 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 62:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((62 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 63:
			/* pushLiteralConstantBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralConstant: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + (((63 & 31) + LiteralStart) << 2)));
			}
;
			break;
		case 64:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((64 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 65:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((65 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 66:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((66 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 67:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((67 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 68:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((68 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 69:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((69 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 70:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((70 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 71:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((71 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 72:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((72 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 73:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((73 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 74:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((74 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 75:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((75 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 76:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((76 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 77:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((77 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 78:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((78 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 79:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((79 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 80:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((80 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 81:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((81 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 82:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((82 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 83:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((83 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 84:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((84 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 85:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((85 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 86:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((86 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 87:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((87 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 88:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((88 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 89:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((89 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 90:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((90 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 91:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((91 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 92:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((92 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 93:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((93 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 94:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((94 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 95:
			/* pushLiteralVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin pushLiteralVariable: */
				/* begin internalPush: */
				longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((95 & 31) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
			}
;
			break;
		case 96:
			/* storeAndPopReceiverVariableBytecode */
			{
				int rcvr;
				int top;
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				rcvr = foo->receiver;
				top = longAt(localSP);
				if (rcvr < foo->youngStart) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput(((((char *) rcvr)) + BaseHeaderSize) + ((96 & 7) << 2), top);
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 97:
			/* storeAndPopReceiverVariableBytecode */
			{
				int rcvr;
				int top;
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				rcvr = foo->receiver;
				top = longAt(localSP);
				if (rcvr < foo->youngStart) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput(((((char *) rcvr)) + BaseHeaderSize) + ((97 & 7) << 2), top);
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 98:
			/* storeAndPopReceiverVariableBytecode */
			{
				int rcvr;
				int top;
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				rcvr = foo->receiver;
				top = longAt(localSP);
				if (rcvr < foo->youngStart) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput(((((char *) rcvr)) + BaseHeaderSize) + ((98 & 7) << 2), top);
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 99:
			/* storeAndPopReceiverVariableBytecode */
			{
				int rcvr;
				int top;
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				rcvr = foo->receiver;
				top = longAt(localSP);
				if (rcvr < foo->youngStart) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput(((((char *) rcvr)) + BaseHeaderSize) + ((99 & 7) << 2), top);
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 100:
			/* storeAndPopReceiverVariableBytecode */
			{
				int rcvr;
				int top;
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				rcvr = foo->receiver;
				top = longAt(localSP);
				if (rcvr < foo->youngStart) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput(((((char *) rcvr)) + BaseHeaderSize) + ((100 & 7) << 2), top);
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 101:
			/* storeAndPopReceiverVariableBytecode */
			{
				int rcvr;
				int top;
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				rcvr = foo->receiver;
				top = longAt(localSP);
				if (rcvr < foo->youngStart) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput(((((char *) rcvr)) + BaseHeaderSize) + ((101 & 7) << 2), top);
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 102:
			/* storeAndPopReceiverVariableBytecode */
			{
				int rcvr;
				int top;
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				rcvr = foo->receiver;
				top = longAt(localSP);
				if (rcvr < foo->youngStart) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput(((((char *) rcvr)) + BaseHeaderSize) + ((102 & 7) << 2), top);
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 103:
			/* storeAndPopReceiverVariableBytecode */
			{
				int rcvr;
				int top;
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				rcvr = foo->receiver;
				top = longAt(localSP);
				if (rcvr < foo->youngStart) {
					possibleRootStoreIntovalue(rcvr, top);
				}
				longAtput(((((char *) rcvr)) + BaseHeaderSize) + ((103 & 7) << 2), top);
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 104:
			/* storeAndPopTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				longAtput(((((char *) localHomeContext)) + BaseHeaderSize) + (((104 & 7) + TempFrameStart) << 2), longAt(localSP));
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 105:
			/* storeAndPopTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				longAtput(((((char *) localHomeContext)) + BaseHeaderSize) + (((105 & 7) + TempFrameStart) << 2), longAt(localSP));
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 106:
			/* storeAndPopTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				longAtput(((((char *) localHomeContext)) + BaseHeaderSize) + (((106 & 7) + TempFrameStart) << 2), longAt(localSP));
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 107:
			/* storeAndPopTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				longAtput(((((char *) localHomeContext)) + BaseHeaderSize) + (((107 & 7) + TempFrameStart) << 2), longAt(localSP));
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 108:
			/* storeAndPopTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				longAtput(((((char *) localHomeContext)) + BaseHeaderSize) + (((108 & 7) + TempFrameStart) << 2), longAt(localSP));
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 109:
			/* storeAndPopTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				longAtput(((((char *) localHomeContext)) + BaseHeaderSize) + (((109 & 7) + TempFrameStart) << 2), longAt(localSP));
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 110:
			/* storeAndPopTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				longAtput(((((char *) localHomeContext)) + BaseHeaderSize) + (((110 & 7) + TempFrameStart) << 2), longAt(localSP));
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 111:
			/* storeAndPopTemporaryVariableBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				longAtput(((((char *) localHomeContext)) + BaseHeaderSize) + (((111 & 7) + TempFrameStart) << 2), longAt(localSP));
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 112:
			/* pushReceiverBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin internalPush: */
				longAtput(localSP += 4, foo->receiver);
			}
;
			break;
		case 113:
			/* pushConstantTrueBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin internalPush: */
				longAtput(localSP += 4, foo->trueObj);
			}
;
			break;
		case 114:
			/* pushConstantFalseBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin internalPush: */
				longAtput(localSP += 4, foo->falseObj);
			}
;
			break;
		case 115:
			/* pushConstantNilBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin internalPush: */
				longAtput(localSP += 4, foo->nilObj);
			}
;
			break;
		case 116:
			/* pushConstantMinusOneBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin internalPush: */
				longAtput(localSP += 4, ConstMinusOne);
			}
;
			break;
		case 117:
			/* pushConstantZeroBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin internalPush: */
				longAtput(localSP += 4, ConstZero);
			}
;
			break;
		case 118:
			/* pushConstantOneBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin internalPush: */
				longAtput(localSP += 4, ConstOne);
			}
;
			break;
		case 119:
			/* pushConstantTwoBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin internalPush: */
				longAtput(localSP += 4, ConstTwo);
			}
;
			break;
		case 120:
			/* returnReceiver */
			{
				localReturnContext = longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (SenderIndex << 2));
				localReturnValue = foo->receiver;
				/* goto commonReturn */
			}
;
			
		commonReturn:
			/* commonReturn */
			{
				int contextOfCaller;
				int thisCntx;
				int localCntx;
				int nilOop;
				int localVal;
				int unwindMarked;
				int meth;
				int pIndex;
				int header;
				int header1;
				int primBits;
				int tmp;
				/* inline:  */;
				nilOop = foo->nilObj;
				thisCntx = foo->activeContext;
				localCntx = localReturnContext;
				localVal = localReturnValue;
				if ((localCntx == nilOop) || ((longAt(((((char *) localCntx)) + BaseHeaderSize) + (InstructionPointerIndex << 2))) == nilOop)) {
					/* begin internalCannotReturn: */
					/* begin internalPush: */
					longAtput(localSP += 4, foo->activeContext);
					/* begin internalPush: */
					longAtput(localSP += 4, localVal);
					foo->messageSelector = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SelectorCannotReturn << 2));
					foo->argumentCount = 1;
					goto normalSend;
					goto l43;
				}
				thisCntx = longAt(((((char *) foo->activeContext)) + BaseHeaderSize) + (SenderIndex << 2));
				while (!(thisCntx == localCntx)) {
					if (thisCntx == nilOop) {
						/* begin internalCannotReturn: */
						/* begin internalPush: */
						longAtput(localSP += 4, foo->activeContext);
						/* begin internalPush: */
						longAtput(localSP += 4, localVal);
						foo->messageSelector = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SelectorCannotReturn << 2));
						foo->argumentCount = 1;
						goto normalSend;
						goto l43;
					}
					/* begin isUnwindMarked: */
					header = longAt(thisCntx);
					if (!(((((unsigned) header) >> 12) & 31) == 14)) {
						unwindMarked = 0;
						goto l44;
					}
					meth = longAt(((((char *) thisCntx)) + BaseHeaderSize) + (MethodIndex << 2));
					/* begin primitiveIndexOf: */
					primBits = (((unsigned) (longAt(((((char *) meth)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 1) & 268435967;
					pIndex = (primBits & 511) + (((unsigned) primBits) >> 19);
					unwindMarked = pIndex == 198;
				l44:	/* end isUnwindMarked: */;
					if (unwindMarked) {
						/* begin internalAboutToReturn:through: */
						/* begin internalPush: */
						longAtput(localSP += 4, foo->activeContext);
						/* begin internalPush: */
						longAtput(localSP += 4, localVal);
						/* begin internalPush: */
						longAtput(localSP += 4, thisCntx);
						foo->messageSelector = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SelectorAboutToReturn << 2));
						foo->argumentCount = 2;
						goto normalSend;
						goto l43;
					}
					thisCntx = longAt(((((char *) thisCntx)) + BaseHeaderSize) + (SenderIndex << 2));
				}
				thisCntx = foo->activeContext;
				while (!(thisCntx == localCntx)) {
					contextOfCaller = longAt(((((char *) thisCntx)) + BaseHeaderSize) + (SenderIndex << 2));
					longAtput(((((char *) thisCntx)) + BaseHeaderSize) + (SenderIndex << 2), nilOop);
					longAtput(((((char *) thisCntx)) + BaseHeaderSize) + (InstructionPointerIndex << 2), nilOop);
					if (foo->reclaimableContextCount > 0) {
						foo->reclaimableContextCount -= 1;
						/* begin recycleContextIfPossible: */
						if (thisCntx >= foo->youngStart) {
							header1 = longAt(thisCntx);
							if (((((unsigned) header1) >> 12) & 31) == 14) {
								if ((header1 & SizeMask) == SmallContextSize) {
									longAtput(((((char *) thisCntx)) + BaseHeaderSize) + (0 << 2), foo->freeContexts);
									foo->freeContexts = thisCntx;
								}
								if ((header1 & SizeMask) == LargeContextSize) {
									longAtput(((((char *) thisCntx)) + BaseHeaderSize) + (0 << 2), foo->freeLargeContexts);
									foo->freeLargeContexts = thisCntx;
								}
							}
						}
					}
					thisCntx = contextOfCaller;
				}
				foo->activeContext = thisCntx;
				if (thisCntx < foo->youngStart) {
					beRootIfOld(thisCntx);
				}
				/* begin internalFetchContextRegisters: */
				tmp = longAt(((((char *) thisCntx)) + BaseHeaderSize) + (MethodIndex << 2));
				if ((tmp & 1)) {
					tmp = longAt(((((char *) thisCntx)) + BaseHeaderSize) + (HomeIndex << 2));
					if (tmp < foo->youngStart) {
						beRootIfOld(tmp);
					}
				} else {
					tmp = thisCntx;
				}
				localHomeContext = tmp;
				foo->receiver = longAt(((((char *) tmp)) + BaseHeaderSize) + (ReceiverIndex << 2));
				foo->method = longAt(((((char *) tmp)) + BaseHeaderSize) + (MethodIndex << 2));
				tmp = ((longAt(((((char *) thisCntx)) + BaseHeaderSize) + (InstructionPointerIndex << 2))) >> 1);
				localIP = ((char *) (((foo->method + tmp) + BaseHeaderSize) - 2));
				tmp = ((longAt(((((char *) thisCntx)) + BaseHeaderSize) + (StackPointerIndex << 2))) >> 1);
				localSP = ((char *) ((thisCntx + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * 4)));
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin internalPush: */
				longAtput(localSP += 4, localVal);
			}
;
		l43:	/* end case */;
			break;
		case 121:
			/* returnTrue */
			{
				localReturnContext = longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (SenderIndex << 2));
				localReturnValue = foo->trueObj;
				goto commonReturn;
			}
;
			break;
		case 122:
			/* returnFalse */
			{
				localReturnContext = longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (SenderIndex << 2));
				localReturnValue = foo->falseObj;
				goto commonReturn;
			}
;
			break;
		case 123:
			/* returnNil */
			{
				localReturnContext = longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (SenderIndex << 2));
				localReturnValue = foo->nilObj;
				goto commonReturn;
			}
;
			break;
		case 124:
			/* returnTopFromMethod */
			{
				localReturnContext = longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (SenderIndex << 2));
				localReturnValue = longAt(localSP);
				goto commonReturn;
			}
;
			break;
		case 125:
			/* returnTopFromBlock */
			{
				localReturnContext = longAt(((((char *) foo->activeContext)) + BaseHeaderSize) + (CallerIndex << 2));
				localReturnValue = longAt(localSP);
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
				int variableIndex;
				int descriptor;
				int variableType;
				descriptor = byteAt(++localIP);
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				variableType = (((unsigned) descriptor) >> 6) & 3;
				variableIndex = descriptor & 63;
				if (variableType == 0) {
					/* begin pushReceiverVariable: */
					/* begin internalPush: */
					longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + (variableIndex << 2)));
					goto l1;
				}
				if (variableType == 1) {
					/* begin pushTemporaryVariable: */
					/* begin internalPush: */
					longAtput(localSP += 4, longAt(((((char *) localHomeContext)) + BaseHeaderSize) + ((variableIndex + TempFrameStart) << 2)));
					goto l1;
				}
				if (variableType == 2) {
					/* begin pushLiteralConstant: */
					/* begin internalPush: */
					longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + ((variableIndex + LiteralStart) << 2)));
					goto l1;
				}
				if (variableType == 3) {
					/* begin pushLiteralVariable: */
					/* begin internalPush: */
					longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + ((variableIndex + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
					goto l1;
				}
			}
;
		l1:	/* end case */;
			break;
		case 129:
			/* extendedStoreBytecode */
			{
				int variableIndex;
				int descriptor;
				int association;
				int variableType;
				int oop;
				int valuePointer;
				int valuePointer1;
				descriptor = byteAt(++localIP);
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				variableType = (((unsigned) descriptor) >> 6) & 3;
				variableIndex = descriptor & 63;
				if (variableType == 0) {
					/* begin storePointer:ofObject:withValue: */
					oop = foo->receiver;
					valuePointer = longAt(localSP);
					if (oop < foo->youngStart) {
						possibleRootStoreIntovalue(oop, valuePointer);
					}
					longAtput(((((char *) oop)) + BaseHeaderSize) + (variableIndex << 2), valuePointer);
					goto l2;
				}
				if (variableType == 1) {
					longAtput(((((char *) localHomeContext)) + BaseHeaderSize) + ((variableIndex + TempFrameStart) << 2), longAt(localSP));
					goto l2;
				}
				if (variableType == 2) {
					error("illegal store");
				}
				if (variableType == 3) {
					association = longAt(((((char *) foo->method)) + BaseHeaderSize) + ((variableIndex + LiteralStart) << 2));
					/* begin storePointer:ofObject:withValue: */
					valuePointer1 = longAt(localSP);
					if (association < foo->youngStart) {
						possibleRootStoreIntovalue(association, valuePointer1);
					}
					longAtput(((((char *) association)) + BaseHeaderSize) + (ValueIndex << 2), valuePointer1);
					goto l2;
				}
			}
;
		l2:	/* end case */;
			break;
		case 130:
			/* extendedStoreAndPopBytecode */
			{
				int variableIndex;
				int descriptor;
				int association;
				int variableType;
				int oop;
				int valuePointer;
				int valuePointer1;
				/* begin extendedStoreBytecode */
				descriptor = byteAt(++localIP);
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				variableType = (((unsigned) descriptor) >> 6) & 3;
				variableIndex = descriptor & 63;
				if (variableType == 0) {
					/* begin storePointer:ofObject:withValue: */
					oop = foo->receiver;
					valuePointer = longAt(localSP);
					if (oop < foo->youngStart) {
						possibleRootStoreIntovalue(oop, valuePointer);
					}
					longAtput(((((char *) oop)) + BaseHeaderSize) + (variableIndex << 2), valuePointer);
					goto l3;
				}
				if (variableType == 1) {
					longAtput(((((char *) localHomeContext)) + BaseHeaderSize) + ((variableIndex + TempFrameStart) << 2), longAt(localSP));
					goto l3;
				}
				if (variableType == 2) {
					error("illegal store");
				}
				if (variableType == 3) {
					association = longAt(((((char *) foo->method)) + BaseHeaderSize) + ((variableIndex + LiteralStart) << 2));
					/* begin storePointer:ofObject:withValue: */
					valuePointer1 = longAt(localSP);
					if (association < foo->youngStart) {
						possibleRootStoreIntovalue(association, valuePointer1);
					}
					longAtput(((((char *) association)) + BaseHeaderSize) + (ValueIndex << 2), valuePointer1);
					goto l3;
				}
			l3:	/* end extendedStoreBytecode */;
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 131:
			/* singleExtendedSendBytecode */
			{
				int descriptor;
				descriptor = byteAt(++localIP);
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((descriptor & 31) + LiteralStart) << 2));
				foo->argumentCount = ((unsigned) descriptor) >> 5;
				/* goto normalSend */
			}
;
			
		normalSend:
			/* normalSend */
			{
				int rcvr;
				int ccIndex;
				/* inline:  */;
				rcvr = longAt(localSP - (foo->argumentCount * 4));
				/* begin fetchClassOf: */
				if ((rcvr & 1)) {
					foo->lkupClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
					goto l45;
				}
				ccIndex = (((unsigned) (longAt(rcvr))) >> 12) & 31;
				if (ccIndex == 0) {
					foo->lkupClass = (longAt(rcvr - 4)) & AllButTypeMask;
					goto l45;
				} else {
					foo->lkupClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
					goto l45;
				}
			l45:	/* end fetchClassOf: */;
				foo->receiverClass = foo->lkupClass;
				/* goto commonSend */
			}
;
			
		commonSend:
			/* commonSend */
			{
				int ok;
				int probe;
				int hash;
				int nArgs;
				int delta;
				int localPrimIndex;
				int oop;
				int tempCount;
				int newContext;
				int where;
				int needsLarge;
				int argCount2;
				int methodHeader;
				int i;
				int tmp;
				/* begin internalFindNewMethod */
				/* begin lookupInMethodCacheSel:class: */
				hash = foo->messageSelector ^ foo->lkupClass;
				probe = hash & MethodCacheMask;
				if (((methodCache[probe + MethodCacheSelector]) == foo->messageSelector) && ((methodCache[probe + MethodCacheClass]) == foo->lkupClass)) {
					foo->newMethod = methodCache[probe + MethodCacheMethod];
					foo->primitiveIndex = methodCache[probe + MethodCachePrim];
					foo->newNativeMethod = methodCache[probe + MethodCacheNative];
					foo->primitiveFunctionPointer = methodCache[probe + MethodCachePrimFunction];
					ok = 1;
					goto l46;
				}
				probe = (((unsigned) hash) >> 1) & MethodCacheMask;
				if (((methodCache[probe + MethodCacheSelector]) == foo->messageSelector) && ((methodCache[probe + MethodCacheClass]) == foo->lkupClass)) {
					foo->newMethod = methodCache[probe + MethodCacheMethod];
					foo->primitiveIndex = methodCache[probe + MethodCachePrim];
					foo->newNativeMethod = methodCache[probe + MethodCacheNative];
					foo->primitiveFunctionPointer = methodCache[probe + MethodCachePrimFunction];
					ok = 1;
					goto l46;
				}
				probe = (((unsigned) hash) >> 2) & MethodCacheMask;
				if (((methodCache[probe + MethodCacheSelector]) == foo->messageSelector) && ((methodCache[probe + MethodCacheClass]) == foo->lkupClass)) {
					foo->newMethod = methodCache[probe + MethodCacheMethod];
					foo->primitiveIndex = methodCache[probe + MethodCachePrim];
					foo->newNativeMethod = methodCache[probe + MethodCacheNative];
					foo->primitiveFunctionPointer = methodCache[probe + MethodCachePrimFunction];
					ok = 1;
					goto l46;
				}
				ok = 0;
			l46:	/* end lookupInMethodCacheSel:class: */;
				if (!(ok)) {
					/* begin externalizeIPandSP */
					foo->instructionPointer = ((unsigned) localIP);
					foo->stackPointer = ((unsigned) localSP);
					foo->theHomeContext = localHomeContext;
					lookupMethodInClass(foo->lkupClass);
					/* begin internalizeIPandSP */
					localIP = ((char *) foo->instructionPointer);
					localSP = ((char *) foo->stackPointer);
					localHomeContext = foo->theHomeContext;
					addNewMethodToCache();
				}
				/* begin internalExecuteNewMethod */
				localPrimIndex = foo->primitiveIndex;
				if (localPrimIndex > 0) {
					if ((localPrimIndex > 255) && (localPrimIndex < 520)) {
						if (localPrimIndex >= 264) {
							/* begin internalPop:thenPush: */
							oop = longAt(((((char *) (longAt(localSP)))) + BaseHeaderSize) + ((localPrimIndex - 264) << 2));
							longAtput(localSP -= (1 - 1) * 4, oop);
							goto l47;
						} else {
							if (localPrimIndex == 256) {
								goto l47;
							}
							if (localPrimIndex == 257) {
								/* begin internalPop:thenPush: */
								longAtput(localSP -= (1 - 1) * 4, foo->trueObj);
								goto l47;
							}
							if (localPrimIndex == 258) {
								/* begin internalPop:thenPush: */
								longAtput(localSP -= (1 - 1) * 4, foo->falseObj);
								goto l47;
							}
							if (localPrimIndex == 259) {
								/* begin internalPop:thenPush: */
								longAtput(localSP -= (1 - 1) * 4, foo->nilObj);
								goto l47;
							}
							/* begin internalPop:thenPush: */
							longAtput(localSP -= (1 - 1) * 4, (((localPrimIndex - 261) << 1) | 1));
							goto l47;
						}
					} else {
						/* begin externalizeIPandSP */
						foo->instructionPointer = ((unsigned) localIP);
						foo->stackPointer = ((unsigned) localSP);
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
						localIP = ((char *) foo->instructionPointer);
						localSP = ((char *) foo->stackPointer);
						localHomeContext = foo->theHomeContext;
						if (foo->successFlag) {
							browserPluginReturnIfNeeded();
							goto l47;
						}
					}
				}
				/* begin internalActivateNewMethod */
				methodHeader = longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2));
				needsLarge = methodHeader & LargeContextBit;
				if ((needsLarge == 0) && (foo->freeContexts != NilContext)) {
					newContext = foo->freeContexts;
					foo->freeContexts = longAt(((((char *) newContext)) + BaseHeaderSize) + (0 << 2));
				} else {
					/* begin externalizeIPandSP */
					foo->instructionPointer = ((unsigned) localIP);
					foo->stackPointer = ((unsigned) localSP);
					foo->theHomeContext = localHomeContext;
					newContext = allocateOrRecycleContext(needsLarge);
					/* begin internalizeIPandSP */
					localIP = ((char *) foo->instructionPointer);
					localSP = ((char *) foo->stackPointer);
					localHomeContext = foo->theHomeContext;
				}
				tempCount = (((unsigned) methodHeader) >> 19) & 63;
				where = newContext + BaseHeaderSize;
				longAtput(where + (SenderIndex << 2), foo->activeContext);
				longAtput(where + (InstructionPointerIndex << 2), (((((LiteralStart + ((((unsigned) methodHeader) >> 10) & 255)) * 4) + 1) << 1) | 1));
				longAtput(where + (StackPointerIndex << 2), ((tempCount << 1) | 1));
				longAtput(where + (MethodIndex << 2), foo->newMethod);
				argCount2 = foo->argumentCount;
				for (i = 0; i <= argCount2; i += 1) {
					longAtput(where + ((ReceiverIndex + i) << 2), longAt(localSP - ((argCount2 - i) * 4)));
				}
				methodHeader = foo->nilObj;
				for (i = ((argCount2 + 1) + ReceiverIndex); i <= (tempCount + ReceiverIndex); i += 1) {
					longAtput(where + (i << 2), methodHeader);
				}
				/* begin internalPop: */
				localSP -= (argCount2 + 1) * 4;
				foo->reclaimableContextCount += 1;
				/* begin internalNewActiveContext: */
				/* begin internalStoreContextRegisters: */
				longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), (((((((int) localIP )) + 2) - (foo->method + BaseHeaderSize)) << 1) | 1));
				longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (StackPointerIndex << 2), (((((((unsigned) ((((int) localSP )) - (foo->activeContext + BaseHeaderSize))) >> 2) - TempFrameStart) + 1) << 1) | 1));
				if (newContext < foo->youngStart) {
					beRootIfOld(newContext);
				}
				foo->activeContext = newContext;
				/* begin internalFetchContextRegisters: */
				tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (MethodIndex << 2));
				if ((tmp & 1)) {
					tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (HomeIndex << 2));
					if (tmp < foo->youngStart) {
						beRootIfOld(tmp);
					}
				} else {
					tmp = newContext;
				}
				localHomeContext = tmp;
				foo->receiver = longAt(((((char *) tmp)) + BaseHeaderSize) + (ReceiverIndex << 2));
				foo->method = longAt(((((char *) tmp)) + BaseHeaderSize) + (MethodIndex << 2));
				tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2))) >> 1);
				localIP = ((char *) (((foo->method + tmp) + BaseHeaderSize) - 2));
				tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (StackPointerIndex << 2))) >> 1);
				localSP = ((char *) ((newContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * 4)));
				/* begin internalQuickCheckForInterrupts */
				if ((foo->interruptCheckCounter -= 1) <= 0) {
					/* begin externalizeIPandSP */
					foo->instructionPointer = ((unsigned) localIP);
					foo->stackPointer = ((unsigned) localSP);
					foo->theHomeContext = localHomeContext;
					checkForInterrupts();
					browserPluginReturnIfNeeded();
					/* begin internalizeIPandSP */
					localIP = ((char *) foo->instructionPointer);
					localSP = ((char *) foo->stackPointer);
					localHomeContext = foo->theHomeContext;
				}
			l47:	/* end internalExecuteNewMethod */;
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
			}
;
			break;
		case 132:
			/* doubleExtendedDoAnythingBytecode */
			{
				int byte2;
				int opType;
				int byte3;
				int top;
				int oop;
				int oop1;
				int oop2;
				byte2 = byteAt(++localIP);
				byte3 = byteAt(++localIP);
				opType = ((unsigned) byte2) >> 5;
				if (opType == 0) {
					foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + ((byte3 + LiteralStart) << 2));
					foo->argumentCount = byte2 & 31;
					goto normalSend;
					goto l4;
				}
				if (opType == 1) {
					foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + ((byte3 + LiteralStart) << 2));
					foo->argumentCount = byte2 & 31;
					goto commonSupersend;
					goto l4;
				}
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				if (opType == 2) {
					/* begin pushReceiverVariable: */
					/* begin internalPush: */
					longAtput(localSP += 4, longAt(((((char *) foo->receiver)) + BaseHeaderSize) + (byte3 << 2)));
					goto l4;
				}
				if (opType == 3) {
					/* begin pushLiteralConstant: */
					/* begin internalPush: */
					longAtput(localSP += 4, longAt(((((char *) foo->method)) + BaseHeaderSize) + ((byte3 + LiteralStart) << 2)));
					goto l4;
				}
				if (opType == 4) {
					/* begin pushLiteralVariable: */
					/* begin internalPush: */
					longAtput(localSP += 4, longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + ((byte3 + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2)));
					goto l4;
				}
				if (opType == 5) {
					top = longAt(localSP);
					/* begin storePointer:ofObject:withValue: */
					oop = foo->receiver;
					if (oop < foo->youngStart) {
						possibleRootStoreIntovalue(oop, top);
					}
					longAtput(((((char *) oop)) + BaseHeaderSize) + (byte3 << 2), top);
					goto l4;
				}
				if (opType == 6) {
					top = longAt(localSP);
					/* begin internalPop: */
					localSP -= 1 * 4;
					/* begin storePointer:ofObject:withValue: */
					oop1 = foo->receiver;
					if (oop1 < foo->youngStart) {
						possibleRootStoreIntovalue(oop1, top);
					}
					longAtput(((((char *) oop1)) + BaseHeaderSize) + (byte3 << 2), top);
					goto l4;
				}
				if (opType == 7) {
					top = longAt(localSP);
					/* begin storePointer:ofObject:withValue: */
					oop2 = longAt(((((char *) foo->method)) + BaseHeaderSize) + ((byte3 + LiteralStart) << 2));
					if (oop2 < foo->youngStart) {
						possibleRootStoreIntovalue(oop2, top);
					}
					longAtput(((((char *) oop2)) + BaseHeaderSize) + (ValueIndex << 2), top);
					goto l4;
				}
			}
;
		l4:	/* end case */;
			break;
		case 133:
			/* singleExtendedSuperBytecode */
			{
				int descriptor;
				descriptor = byteAt(++localIP);
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((descriptor & 31) + LiteralStart) << 2));
				foo->argumentCount = ((unsigned) descriptor) >> 5;
				/* goto commonSupersend */
			}
;
			
		commonSupersend:
			/* superclassSend */
			{
				int rcvr;
				int classPointer;
				int ccIndex;
				/* inline:  */;
				/* begin superclassOf: */
				classPointer = longAt(((((char *) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (((((((unsigned) (longAt(((((char *) foo->method)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 10) & 255) - 1) + LiteralStart) << 2))))) + BaseHeaderSize) + (ValueIndex << 2));
				foo->lkupClass = longAt(((((char *) classPointer)) + BaseHeaderSize) + (SuperclassIndex << 2));
				rcvr = longAt(localSP - (foo->argumentCount * 4));
				/* begin fetchClassOf: */
				if ((rcvr & 1)) {
					foo->receiverClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
					goto l48;
				}
				ccIndex = (((unsigned) (longAt(rcvr))) >> 12) & 31;
				if (ccIndex == 0) {
					foo->receiverClass = (longAt(rcvr - 4)) & AllButTypeMask;
					goto l48;
				} else {
					foo->receiverClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
					goto l48;
				}
			l48:	/* end fetchClassOf: */;
				goto commonSend;
			}
;
			break;
		case 134:
			/* secondExtendedSendBytecode */
			{
				int descriptor;
				descriptor = byteAt(++localIP);
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((descriptor & 63) + LiteralStart) << 2));
				foo->argumentCount = ((unsigned) descriptor) >> 6;
				goto normalSend;
			}
;
			break;
		case 135:
			/* popStackBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin internalPop: */
				localSP -= 1 * 4;
			}
;
			break;
		case 136:
			/* duplicateTopBytecode */
			{
				int object;
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				/* begin internalPush: */
				object = longAt(localSP);
				longAtput(localSP += 4, object);
			}
;
			break;
		case 137:
			/* pushActiveContextBytecode */
			{
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				foo->reclaimableContextCount = 0;
				/* begin internalPush: */
				longAtput(localSP += 4, foo->activeContext);
			}
;
			break;
		case 138:
		case 139:
		case 140:
		case 141:
		case 142:
		case 143:
			/* experimentalBytecode */
			{
				int result;
				int byte2;
				int byte3;
				int arg1;
				int byte4;
				int offset;
				int arg1Val;
				int arg2Val;
				arg1 = longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((currentBytecode - 138) + TempFrameStart) << 2));
				byte2 = byteAt(localIP + 1);
				byte3 = byteAt(localIP + 2);
				byte4 = byteAt(localIP + 3);
				if ((arg1 & 1)) {
					arg1Val = (arg1 >> 1);
				} else {
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					/* begin internalPush: */
					longAtput(localSP += 4, arg1);
					goto l5;
				}
				if (byte2 < 32) {
					arg2Val = longAt(((((char *) localHomeContext)) + BaseHeaderSize) + (((byte2 & 15) + TempFrameStart) << 2));
					if ((arg2Val & 1)) {
						arg2Val = (arg2Val >> 1);
					} else {
						/* begin fetchNextBytecode */
						currentBytecode = byteAt(++localIP);
						/* begin internalPush: */
						longAtput(localSP += 4, arg1);
						goto l5;
					}
				} else {
					if (byte2 > 64) {
						arg2Val = 1;
					} else {
						arg2Val = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((byte2 & 31) + LiteralStart) << 2));
						if ((arg2Val & 1)) {
							arg2Val = (arg2Val >> 1);
						} else {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							/* begin internalPush: */
							longAtput(localSP += 4, arg1);
							goto l5;
						}
					}
				}
				if (byte3 < 178) {
					result = arg1Val + arg2Val;
					if ((result ^ (result << 1)) >= 0) {
						if ((byte4 > 103) && (byte4 < 112)) {
							localIP += 3;
							longAtput(((((char *) localHomeContext)) + BaseHeaderSize) + (((byte4 & 7) + TempFrameStart) << 2), ((result << 1) | 1));
						} else {
							localIP += 2;
							/* begin internalPush: */
							longAtput(localSP += 4, ((result << 1) | 1));
						}
					} else {
						/* begin fetchNextBytecode */
						currentBytecode = byteAt(++localIP);
						/* begin internalPush: */
						longAtput(localSP += 4, arg1);
						goto l5;
					}
				} else {
					offset = byteAt(localIP + 4);
					if (arg1Val <= arg2Val) {
						localIP = (localIP + 3) + 1;
					} else {
						localIP = ((localIP + 3) + 1) + offset;
					}
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
				}
			}
;
		l5:	/* end case */;
			break;
		case 144:
			/* shortUnconditionalJump */
			{
				int offset;
				/* begin jump: */
				offset = (144 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAt(localIP);
			}
;
			break;
		case 145:
			/* shortUnconditionalJump */
			{
				int offset;
				/* begin jump: */
				offset = (145 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAt(localIP);
			}
;
			break;
		case 146:
			/* shortUnconditionalJump */
			{
				int offset;
				/* begin jump: */
				offset = (146 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAt(localIP);
			}
;
			break;
		case 147:
			/* shortUnconditionalJump */
			{
				int offset;
				/* begin jump: */
				offset = (147 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAt(localIP);
			}
;
			break;
		case 148:
			/* shortUnconditionalJump */
			{
				int offset;
				/* begin jump: */
				offset = (148 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAt(localIP);
			}
;
			break;
		case 149:
			/* shortUnconditionalJump */
			{
				int offset;
				/* begin jump: */
				offset = (149 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAt(localIP);
			}
;
			break;
		case 150:
			/* shortUnconditionalJump */
			{
				int offset;
				/* begin jump: */
				offset = (150 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAt(localIP);
			}
;
			break;
		case 151:
			/* shortUnconditionalJump */
			{
				int offset;
				/* begin jump: */
				offset = (151 & 7) + 1;
				localIP = (localIP + offset) + 1;
				currentBytecode = byteAt(localIP);
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
				int offset;
				int boolean;
				/* begin jumplfFalseBy: */
				offset = (currentBytecode & 7) + 1;
				boolean = longAt(localSP);
				if (boolean == foo->falseObj) {
					/* begin jump: */
					localIP = (localIP + offset) + 1;
					currentBytecode = byteAt(localIP);
				} else {
					if (!(boolean == foo->trueObj)) {
						foo->messageSelector = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SelectorMustBeBoolean << 2));
						foo->argumentCount = 0;
						goto normalSend;
						goto l6;
					}
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
				}
				/* begin internalPop: */
				localSP -= 1 * 4;
			l6:	/* end jumplfFalseBy: */;
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
				int offset;
				offset = (((currentBytecode & 7) - 4) * 256) + (byteAt(++localIP));
				localIP += offset;
				if (offset < 0) {
					/* begin internalQuickCheckForInterrupts */
					if ((foo->interruptCheckCounter -= 1) <= 0) {
						/* begin externalizeIPandSP */
						foo->instructionPointer = ((unsigned) localIP);
						foo->stackPointer = ((unsigned) localSP);
						foo->theHomeContext = localHomeContext;
						checkForInterrupts();
						browserPluginReturnIfNeeded();
						/* begin internalizeIPandSP */
						localIP = ((char *) foo->instructionPointer);
						localSP = ((char *) foo->stackPointer);
						localHomeContext = foo->theHomeContext;
					}
				}
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
			}
;
			break;
		case 168:
		case 169:
		case 170:
		case 171:
			/* longJumpIfTrue */
			{
				int offset;
				int boolean;
				/* begin jumplfTrueBy: */
				offset = ((currentBytecode & 3) * 256) + (byteAt(++localIP));
				boolean = longAt(localSP);
				if (boolean == foo->trueObj) {
					/* begin jump: */
					localIP = (localIP + offset) + 1;
					currentBytecode = byteAt(localIP);
				} else {
					if (!(boolean == foo->falseObj)) {
						foo->messageSelector = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SelectorMustBeBoolean << 2));
						foo->argumentCount = 0;
						goto normalSend;
						goto l7;
					}
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
				}
				/* begin internalPop: */
				localSP -= 1 * 4;
			l7:	/* end jumplfTrueBy: */;
			}
;
			break;
		case 172:
		case 173:
		case 174:
		case 175:
			/* longJumpIfFalse */
			{
				int offset;
				int boolean;
				/* begin jumplfFalseBy: */
				offset = ((currentBytecode & 3) * 256) + (byteAt(++localIP));
				boolean = longAt(localSP);
				if (boolean == foo->falseObj) {
					/* begin jump: */
					localIP = (localIP + offset) + 1;
					currentBytecode = byteAt(localIP);
				} else {
					if (!(boolean == foo->trueObj)) {
						foo->messageSelector = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SelectorMustBeBoolean << 2));
						foo->argumentCount = 0;
						goto normalSend;
						goto l8;
					}
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
				}
				/* begin internalPop: */
				localSP -= 1 * 4;
			l8:	/* end jumplfFalseBy: */;
			}
;
			break;
		case 176:
			/* bytecodePrimAdd */
			{
				int result;
				int rcvr;
				int arg;
				rcvr = longAt(localSP - (1 * 4));
				arg = longAt(localSP - (0 * 4));
				if (((rcvr & arg) & 1) != 0) {
					result = ((rcvr >> 1)) + ((arg >> 1));
					if ((result ^ (result << 1)) >= 0) {
						/* begin internalPop:thenPush: */
						longAtput(localSP -= (2 - 1) * 4, ((result << 1) | 1));
						/* begin fetchNextBytecode */
						currentBytecode = byteAt(++localIP);
						goto l9;
					}
				} else {
					foo->successFlag = 1;
					/* begin externalizeIPandSP */
					foo->instructionPointer = ((unsigned) localIP);
					foo->stackPointer = ((unsigned) localSP);
					foo->theHomeContext = localHomeContext;
					primitiveFloatAddtoArg(rcvr, arg);
					/* begin internalizeIPandSP */
					localIP = ((char *) foo->instructionPointer);
					localSP = ((char *) foo->stackPointer);
					localHomeContext = foo->theHomeContext;
					if (foo->successFlag) {
						/* begin fetchNextBytecode */
						currentBytecode = byteAt(++localIP);
						goto l9;
					}
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((0 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l9:	/* end case */;
			break;
		case 177:
			/* bytecodePrimSubtract */
			{
				int result;
				int rcvr;
				int arg;
				rcvr = longAt(localSP - (1 * 4));
				arg = longAt(localSP - (0 * 4));
				if (((rcvr & arg) & 1) != 0) {
					result = ((rcvr >> 1)) - ((arg >> 1));
					if ((result ^ (result << 1)) >= 0) {
						/* begin internalPop:thenPush: */
						longAtput(localSP -= (2 - 1) * 4, ((result << 1) | 1));
						/* begin fetchNextBytecode */
						currentBytecode = byteAt(++localIP);
						goto l10;
					}
				} else {
					foo->successFlag = 1;
					/* begin externalizeIPandSP */
					foo->instructionPointer = ((unsigned) localIP);
					foo->stackPointer = ((unsigned) localSP);
					foo->theHomeContext = localHomeContext;
					primitiveFloatSubtractfromArg(rcvr, arg);
					/* begin internalizeIPandSP */
					localIP = ((char *) foo->instructionPointer);
					localSP = ((char *) foo->stackPointer);
					localHomeContext = foo->theHomeContext;
					if (foo->successFlag) {
						/* begin fetchNextBytecode */
						currentBytecode = byteAt(++localIP);
						goto l10;
					}
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((1 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l10:	/* end case */;
			break;
		case 178:
			/* bytecodePrimLessThan */
			{
				int rcvr;
				int aBool;
				int arg;
				int bytecode;
				int offset;
				int bytecode1;
				int offset1;
				int bytecode2;
				int offset2;
				rcvr = longAt(localSP - (1 * 4));
				arg = longAt(localSP - (0 * 4));
				if (((rcvr & arg) & 1) != 0) {
					;
					/* begin booleanCheat: */
					bytecode1 = byteAt(++localIP);
					/* begin internalPop: */
					localSP -= 2 * 4;
					if ((bytecode1 < 160) && (bytecode1 > 151)) {
						if (rcvr < arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l11;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode1 - 151)) + 1;
							currentBytecode = byteAt(localIP);
							goto l11;
						}
					}
					if (bytecode1 == 172) {
						offset1 = byteAt(++localIP);
						if (rcvr < arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l11;
						} else {
							/* begin jump: */
							localIP = (localIP + offset1) + 1;
							currentBytecode = byteAt(localIP);
							goto l11;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					if (rcvr < arg) {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->falseObj);
					}
					goto l11;
				}
				foo->successFlag = 1;
				aBool = primitiveFloatLessthanArg(rcvr, arg);
				if (foo->successFlag) {
					/* begin booleanCheat: */
					bytecode2 = byteAt(++localIP);
					/* begin internalPop: */
					localSP -= 2 * 4;
					if ((bytecode2 < 160) && (bytecode2 > 151)) {
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l11;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode2 - 151)) + 1;
							currentBytecode = byteAt(localIP);
							goto l11;
						}
					}
					if (bytecode2 == 172) {
						offset2 = byteAt(++localIP);
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l11;
						} else {
							/* begin jump: */
							localIP = (localIP + offset2) + 1;
							currentBytecode = byteAt(localIP);
							goto l11;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					if (aBool) {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->falseObj);
					}
					goto l11;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((2 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l11:	/* end case */;
			break;
		case 179:
			/* bytecodePrimGreaterThan */
			{
				int rcvr;
				int aBool;
				int arg;
				int bytecode;
				int offset;
				int bytecode1;
				int offset1;
				int bytecode2;
				int offset2;
				rcvr = longAt(localSP - (1 * 4));
				arg = longAt(localSP - (0 * 4));
				if (((rcvr & arg) & 1) != 0) {
					;
					/* begin booleanCheat: */
					bytecode1 = byteAt(++localIP);
					/* begin internalPop: */
					localSP -= 2 * 4;
					if ((bytecode1 < 160) && (bytecode1 > 151)) {
						if (rcvr > arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l12;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode1 - 151)) + 1;
							currentBytecode = byteAt(localIP);
							goto l12;
						}
					}
					if (bytecode1 == 172) {
						offset1 = byteAt(++localIP);
						if (rcvr > arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l12;
						} else {
							/* begin jump: */
							localIP = (localIP + offset1) + 1;
							currentBytecode = byteAt(localIP);
							goto l12;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					if (rcvr > arg) {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->falseObj);
					}
					goto l12;
				}
				foo->successFlag = 1;
				aBool = primitiveFloatGreaterthanArg(rcvr, arg);
				if (foo->successFlag) {
					/* begin booleanCheat: */
					bytecode2 = byteAt(++localIP);
					/* begin internalPop: */
					localSP -= 2 * 4;
					if ((bytecode2 < 160) && (bytecode2 > 151)) {
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l12;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode2 - 151)) + 1;
							currentBytecode = byteAt(localIP);
							goto l12;
						}
					}
					if (bytecode2 == 172) {
						offset2 = byteAt(++localIP);
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l12;
						} else {
							/* begin jump: */
							localIP = (localIP + offset2) + 1;
							currentBytecode = byteAt(localIP);
							goto l12;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					if (aBool) {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->falseObj);
					}
					goto l12;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((3 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l12:	/* end case */;
			break;
		case 180:
			/* bytecodePrimLessOrEqual */
			{
				int rcvr;
				int aBool;
				int arg;
				int bytecode;
				int offset;
				int bytecode1;
				int offset1;
				int bytecode2;
				int offset2;
				rcvr = longAt(localSP - (1 * 4));
				arg = longAt(localSP - (0 * 4));
				if (((rcvr & arg) & 1) != 0) {
					;
					/* begin booleanCheat: */
					bytecode1 = byteAt(++localIP);
					/* begin internalPop: */
					localSP -= 2 * 4;
					if ((bytecode1 < 160) && (bytecode1 > 151)) {
						if (rcvr <= arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l13;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode1 - 151)) + 1;
							currentBytecode = byteAt(localIP);
							goto l13;
						}
					}
					if (bytecode1 == 172) {
						offset1 = byteAt(++localIP);
						if (rcvr <= arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l13;
						} else {
							/* begin jump: */
							localIP = (localIP + offset1) + 1;
							currentBytecode = byteAt(localIP);
							goto l13;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					if (rcvr <= arg) {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->falseObj);
					}
					goto l13;
				}
				foo->successFlag = 1;
				aBool = primitiveFloatGreaterthanArg(rcvr, arg);
				if (foo->successFlag) {
					/* begin booleanCheat: */
					bytecode2 = byteAt(++localIP);
					/* begin internalPop: */
					localSP -= 2 * 4;
					if ((bytecode2 < 160) && (bytecode2 > 151)) {
						if (!aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l13;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode2 - 151)) + 1;
							currentBytecode = byteAt(localIP);
							goto l13;
						}
					}
					if (bytecode2 == 172) {
						offset2 = byteAt(++localIP);
						if (!aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l13;
						} else {
							/* begin jump: */
							localIP = (localIP + offset2) + 1;
							currentBytecode = byteAt(localIP);
							goto l13;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					if (!aBool) {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->falseObj);
					}
					goto l13;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((4 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l13:	/* end case */;
			break;
		case 181:
			/* bytecodePrimGreaterOrEqual */
			{
				int rcvr;
				int aBool;
				int arg;
				int bytecode;
				int offset;
				int bytecode1;
				int offset1;
				int bytecode2;
				int offset2;
				rcvr = longAt(localSP - (1 * 4));
				arg = longAt(localSP - (0 * 4));
				if (((rcvr & arg) & 1) != 0) {
					;
					/* begin booleanCheat: */
					bytecode1 = byteAt(++localIP);
					/* begin internalPop: */
					localSP -= 2 * 4;
					if ((bytecode1 < 160) && (bytecode1 > 151)) {
						if (rcvr >= arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l14;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode1 - 151)) + 1;
							currentBytecode = byteAt(localIP);
							goto l14;
						}
					}
					if (bytecode1 == 172) {
						offset1 = byteAt(++localIP);
						if (rcvr >= arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l14;
						} else {
							/* begin jump: */
							localIP = (localIP + offset1) + 1;
							currentBytecode = byteAt(localIP);
							goto l14;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					if (rcvr >= arg) {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->falseObj);
					}
					goto l14;
				}
				foo->successFlag = 1;
				aBool = primitiveFloatLessthanArg(rcvr, arg);
				if (foo->successFlag) {
					/* begin booleanCheat: */
					bytecode2 = byteAt(++localIP);
					/* begin internalPop: */
					localSP -= 2 * 4;
					if ((bytecode2 < 160) && (bytecode2 > 151)) {
						if (!aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l14;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode2 - 151)) + 1;
							currentBytecode = byteAt(localIP);
							goto l14;
						}
					}
					if (bytecode2 == 172) {
						offset2 = byteAt(++localIP);
						if (!aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l14;
						} else {
							/* begin jump: */
							localIP = (localIP + offset2) + 1;
							currentBytecode = byteAt(localIP);
							goto l14;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					if (!aBool) {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->falseObj);
					}
					goto l14;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((5 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l14:	/* end case */;
			break;
		case 182:
			/* bytecodePrimEqual */
			{
				int rcvr;
				int aBool;
				int arg;
				int bytecode;
				int offset;
				int bytecode1;
				int offset1;
				rcvr = longAt(localSP - (1 * 4));
				arg = longAt(localSP - (0 * 4));
				if (((rcvr & arg) & 1) != 0) {
					/* begin booleanCheat: */
					bytecode = byteAt(++localIP);
					/* begin internalPop: */
					localSP -= 2 * 4;
					if ((bytecode < 160) && (bytecode > 151)) {
						if (rcvr == arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l15;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode - 151)) + 1;
							currentBytecode = byteAt(localIP);
							goto l15;
						}
					}
					if (bytecode == 172) {
						offset = byteAt(++localIP);
						if (rcvr == arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l15;
						} else {
							/* begin jump: */
							localIP = (localIP + offset) + 1;
							currentBytecode = byteAt(localIP);
							goto l15;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					if (rcvr == arg) {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->falseObj);
					}
					goto l15;
				}
				foo->successFlag = 1;
				aBool = primitiveFloatEqualtoArg(rcvr, arg);
				if (foo->successFlag) {
					/* begin booleanCheat: */
					bytecode1 = byteAt(++localIP);
					/* begin internalPop: */
					localSP -= 2 * 4;
					if ((bytecode1 < 160) && (bytecode1 > 151)) {
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l15;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode1 - 151)) + 1;
							currentBytecode = byteAt(localIP);
							goto l15;
						}
					}
					if (bytecode1 == 172) {
						offset1 = byteAt(++localIP);
						if (aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l15;
						} else {
							/* begin jump: */
							localIP = (localIP + offset1) + 1;
							currentBytecode = byteAt(localIP);
							goto l15;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					if (aBool) {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->falseObj);
					}
					goto l15;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((6 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l15:	/* end case */;
			break;
		case 183:
			/* bytecodePrimNotEqual */
			{
				int rcvr;
				int aBool;
				int arg;
				int bytecode;
				int offset;
				int bytecode1;
				int offset1;
				rcvr = longAt(localSP - (1 * 4));
				arg = longAt(localSP - (0 * 4));
				if (((rcvr & arg) & 1) != 0) {
					/* begin booleanCheat: */
					bytecode = byteAt(++localIP);
					/* begin internalPop: */
					localSP -= 2 * 4;
					if ((bytecode < 160) && (bytecode > 151)) {
						if (rcvr != arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l16;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode - 151)) + 1;
							currentBytecode = byteAt(localIP);
							goto l16;
						}
					}
					if (bytecode == 172) {
						offset = byteAt(++localIP);
						if (rcvr != arg) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l16;
						} else {
							/* begin jump: */
							localIP = (localIP + offset) + 1;
							currentBytecode = byteAt(localIP);
							goto l16;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					if (rcvr != arg) {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->falseObj);
					}
					goto l16;
				}
				foo->successFlag = 1;
				aBool = primitiveFloatEqualtoArg(rcvr, arg);
				if (foo->successFlag) {
					/* begin booleanCheat: */
					bytecode1 = byteAt(++localIP);
					/* begin internalPop: */
					localSP -= 2 * 4;
					if ((bytecode1 < 160) && (bytecode1 > 151)) {
						if (!aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l16;
						} else {
							/* begin jump: */
							localIP = (localIP + (bytecode1 - 151)) + 1;
							currentBytecode = byteAt(localIP);
							goto l16;
						}
					}
					if (bytecode1 == 172) {
						offset1 = byteAt(++localIP);
						if (!aBool) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l16;
						} else {
							/* begin jump: */
							localIP = (localIP + offset1) + 1;
							currentBytecode = byteAt(localIP);
							goto l16;
						}
					}
					localIP -= 1;
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					if (!aBool) {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->trueObj);
					} else {
						/* begin internalPush: */
						longAtput(localSP += 4, foo->falseObj);
					}
					goto l16;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((7 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l16:	/* end case */;
			break;
		case 184:
			/* bytecodePrimMultiply */
			{
				int result;
				int rcvr;
				int arg;
				rcvr = longAt(localSP - (1 * 4));
				arg = longAt(localSP - (0 * 4));
				if (((rcvr & arg) & 1) != 0) {
					rcvr = (rcvr >> 1);
					arg = (arg >> 1);
					result = rcvr * arg;
					if (((arg == 0) || ((result / arg) == rcvr)) && ((result ^ (result << 1)) >= 0)) {
						/* begin internalPop:thenPush: */
						longAtput(localSP -= (2 - 1) * 4, ((result << 1) | 1));
						/* begin fetchNextBytecode */
						currentBytecode = byteAt(++localIP);
						goto l17;
					}
				} else {
					foo->successFlag = 1;
					/* begin externalizeIPandSP */
					foo->instructionPointer = ((unsigned) localIP);
					foo->stackPointer = ((unsigned) localSP);
					foo->theHomeContext = localHomeContext;
					primitiveFloatMultiplybyArg(rcvr, arg);
					/* begin internalizeIPandSP */
					localIP = ((char *) foo->instructionPointer);
					localSP = ((char *) foo->stackPointer);
					localHomeContext = foo->theHomeContext;
					if (foo->successFlag) {
						/* begin fetchNextBytecode */
						currentBytecode = byteAt(++localIP);
						goto l17;
					}
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((8 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l17:	/* end case */;
			break;
		case 185:
			/* bytecodePrimDivide */
			{
				int result;
				int rcvr;
				int arg;
				rcvr = longAt(localSP - (1 * 4));
				arg = longAt(localSP - (0 * 4));
				if (((rcvr & arg) & 1) != 0) {
					rcvr = (rcvr >> 1);
					arg = (arg >> 1);
					if ((arg != 0) && ((rcvr % arg) == 0)) {
						result = rcvr / arg;
						if ((result ^ (result << 1)) >= 0) {
							/* begin internalPop:thenPush: */
							longAtput(localSP -= (2 - 1) * 4, ((result << 1) | 1));
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							goto l18;
						}
					}
				} else {
					foo->successFlag = 1;
					/* begin externalizeIPandSP */
					foo->instructionPointer = ((unsigned) localIP);
					foo->stackPointer = ((unsigned) localSP);
					foo->theHomeContext = localHomeContext;
					primitiveFloatDividebyArg(rcvr, arg);
					/* begin internalizeIPandSP */
					localIP = ((char *) foo->instructionPointer);
					localSP = ((char *) foo->stackPointer);
					localHomeContext = foo->theHomeContext;
					if (foo->successFlag) {
						/* begin fetchNextBytecode */
						currentBytecode = byteAt(++localIP);
						goto l18;
					}
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((9 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l18:	/* end case */;
			break;
		case 186:
			/* bytecodePrimMod */
			{
				int mod;
				foo->successFlag = 1;
				mod = doPrimitiveModby(longAt(localSP - (1 * 4)), longAt(localSP - (0 * 4)));
				if (foo->successFlag) {
					/* begin internalPop:thenPush: */
					longAtput(localSP -= (2 - 1) * 4, ((mod << 1) | 1));
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					goto l19;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((10 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l19:	/* end case */;
			break;
		case 187:
			/* bytecodePrimMakePoint */
			{
				int pt;
				int rcvr;
				int argument;
				int valuePointer;
				int valuePointer1;
				int valuePointer2;
				int sp;
				int pointResult;
				int pointResult1;
				int pointResult2;
				foo->successFlag = 1;
				/* begin externalizeIPandSP */
				foo->instructionPointer = ((unsigned) localIP);
				foo->stackPointer = ((unsigned) localSP);
				foo->theHomeContext = localHomeContext;
				/* begin primitiveMakePoint */
				argument = longAt(foo->stackPointer);
				rcvr = longAt(foo->stackPointer - (1 * 4));
				if ((rcvr & 1)) {
					if ((argument & 1)) {
						/* begin makePointwithxValue:yValue: */
						pointResult = instantiateSmallClasssizeInBytesfill(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassPoint << 2)), 12, foo->nilObj);
						/* begin storePointer:ofObject:withValue: */
						if (pointResult < foo->youngStart) {
							possibleRootStoreIntovalue(pointResult, ((((rcvr >> 1)) << 1) | 1));
						}
						longAtput(((((char *) pointResult)) + BaseHeaderSize) + (XIndex << 2), ((((rcvr >> 1)) << 1) | 1));
						/* begin storePointer:ofObject:withValue: */
						if (pointResult < foo->youngStart) {
							possibleRootStoreIntovalue(pointResult, ((((argument >> 1)) << 1) | 1));
						}
						longAtput(((((char *) pointResult)) + BaseHeaderSize) + (YIndex << 2), ((((argument >> 1)) << 1) | 1));
						pt = pointResult;
					} else {
						/* begin makePointwithxValue:yValue: */
						pointResult1 = instantiateSmallClasssizeInBytesfill(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassPoint << 2)), 12, foo->nilObj);
						/* begin storePointer:ofObject:withValue: */
						if (pointResult1 < foo->youngStart) {
							possibleRootStoreIntovalue(pointResult1, ((((rcvr >> 1)) << 1) | 1));
						}
						longAtput(((((char *) pointResult1)) + BaseHeaderSize) + (XIndex << 2), ((((rcvr >> 1)) << 1) | 1));
						/* begin storePointer:ofObject:withValue: */
						if (pointResult1 < foo->youngStart) {
							possibleRootStoreIntovalue(pointResult1, ((0 << 1) | 1));
						}
						longAtput(((((char *) pointResult1)) + BaseHeaderSize) + (YIndex << 2), ((0 << 1) | 1));
						pt = pointResult1;
						/* begin storePointer:ofObject:withValue: */
						valuePointer = longAt(foo->stackPointer - (0 * 4));
						if (pt < foo->youngStart) {
							possibleRootStoreIntovalue(pt, valuePointer);
						}
						longAtput(((((char *) pt)) + BaseHeaderSize) + (1 << 2), valuePointer);
					}
				} else {
					if (!((fetchClassOf(rcvr)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassFloat << 2))))) {
						/* begin success: */
						foo->successFlag = 0 && foo->successFlag;
						goto l21;
					}
					/* begin makePointwithxValue:yValue: */
					pointResult2 = instantiateSmallClasssizeInBytesfill(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassPoint << 2)), 12, foo->nilObj);
					/* begin storePointer:ofObject:withValue: */
					if (pointResult2 < foo->youngStart) {
						possibleRootStoreIntovalue(pointResult2, ((0 << 1) | 1));
					}
					longAtput(((((char *) pointResult2)) + BaseHeaderSize) + (XIndex << 2), ((0 << 1) | 1));
					/* begin storePointer:ofObject:withValue: */
					if (pointResult2 < foo->youngStart) {
						possibleRootStoreIntovalue(pointResult2, ((0 << 1) | 1));
					}
					longAtput(((((char *) pointResult2)) + BaseHeaderSize) + (YIndex << 2), ((0 << 1) | 1));
					pt = pointResult2;
					/* begin storePointer:ofObject:withValue: */
					valuePointer1 = longAt(foo->stackPointer - (1 * 4));
					if (pt < foo->youngStart) {
						possibleRootStoreIntovalue(pt, valuePointer1);
					}
					longAtput(((((char *) pt)) + BaseHeaderSize) + (0 << 2), valuePointer1);
					/* begin storePointer:ofObject:withValue: */
					valuePointer2 = longAt(foo->stackPointer - (0 * 4));
					if (pt < foo->youngStart) {
						possibleRootStoreIntovalue(pt, valuePointer2);
					}
					longAtput(((((char *) pt)) + BaseHeaderSize) + (1 << 2), valuePointer2);
				}
				/* begin pop:thenPush: */
				longAtput(sp = foo->stackPointer - ((2 - 1) * 4), pt);
				foo->stackPointer = sp;
			l21:	/* end primitiveMakePoint */;
				/* begin internalizeIPandSP */
				localIP = ((char *) foo->instructionPointer);
				localSP = ((char *) foo->stackPointer);
				localHomeContext = foo->theHomeContext;
				if (foo->successFlag) {
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					goto l20;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((11 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l20:	/* end case */;
			break;
		case 188:
			/* bytecodePrimBitShift */
			{
				int integerArgument;
				int shifted;
				int integerReceiver;
				int integerPointer;
				int object;
				int sp;
				int top;
				int top2;
				int top1;
				foo->successFlag = 1;
				/* begin externalizeIPandSP */
				foo->instructionPointer = ((unsigned) localIP);
				foo->stackPointer = ((unsigned) localSP);
				foo->theHomeContext = localHomeContext;
				/* begin primitiveBitShift */
				/* begin popInteger */
				/* begin popStack */
				top = longAt(foo->stackPointer);
				foo->stackPointer -= 4;
				integerPointer = top;
				/* begin checkedIntegerValueOf: */
				if ((integerPointer & 1)) {
					integerArgument = (integerPointer >> 1);
					goto l23;
				} else {
					/* begin primitiveFail */
					foo->successFlag = 0;
					integerArgument = 0;
					goto l23;
				}
			l23:	/* end checkedIntegerValueOf: */;
				/* begin popPos32BitInteger */
				/* begin popStack */
				top1 = longAt(foo->stackPointer);
				foo->stackPointer -= 4;
				top2 = top1;
				integerReceiver = positive32BitValueOf(top2);
				if (foo->successFlag) {
					if (integerArgument >= 0) {
						/* begin success: */
						foo->successFlag = (integerArgument <= 31) && foo->successFlag;
						shifted = integerReceiver << integerArgument;
						/* begin success: */
						foo->successFlag = ((((unsigned) shifted) >> integerArgument) == integerReceiver) && foo->successFlag;
					} else {
						/* begin success: */
						foo->successFlag = (integerArgument >= -31) && foo->successFlag;
						shifted = ((integerArgument < 0) ? ((unsigned) integerReceiver >> -integerArgument) : ((unsigned) integerReceiver << integerArgument));
					}
				}
				if (foo->successFlag) {
					/* begin push: */
					object = positive32BitIntegerFor(shifted);
					longAtput(sp = foo->stackPointer + 4, object);
					foo->stackPointer = sp;
				} else {
					/* begin unPop: */
					foo->stackPointer += 2 * 4;
				}
				/* begin internalizeIPandSP */
				localIP = ((char *) foo->instructionPointer);
				localSP = ((char *) foo->stackPointer);
				localHomeContext = foo->theHomeContext;
				if (foo->successFlag) {
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					goto l22;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((12 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l22:	/* end case */;
			break;
		case 189:
			/* bytecodePrimDiv */
			{
				int quotient;
				foo->successFlag = 1;
				quotient = doPrimitiveDivby(longAt(localSP - (1 * 4)), longAt(localSP - (0 * 4)));
				if (foo->successFlag) {
					/* begin internalPop:thenPush: */
					longAtput(localSP -= (2 - 1) * 4, ((quotient << 1) | 1));
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					goto l24;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((13 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l24:	/* end case */;
			break;
		case 190:
			/* bytecodePrimBitAnd */
			{
				int integerArgument;
				int integerReceiver;
				int object;
				int sp;
				int top;
				int top1;
				int top2;
				int top11;
				foo->successFlag = 1;
				/* begin externalizeIPandSP */
				foo->instructionPointer = ((unsigned) localIP);
				foo->stackPointer = ((unsigned) localSP);
				foo->theHomeContext = localHomeContext;
				/* begin primitiveBitAnd */
				/* begin popPos32BitInteger */
				/* begin popStack */
				top1 = longAt(foo->stackPointer);
				foo->stackPointer -= 4;
				top = top1;
				integerArgument = positive32BitValueOf(top);
				/* begin popPos32BitInteger */
				/* begin popStack */
				top11 = longAt(foo->stackPointer);
				foo->stackPointer -= 4;
				top2 = top11;
				integerReceiver = positive32BitValueOf(top2);
				if (foo->successFlag) {
					/* begin push: */
					object = positive32BitIntegerFor(integerReceiver & integerArgument);
					longAtput(sp = foo->stackPointer + 4, object);
					foo->stackPointer = sp;
				} else {
					/* begin unPop: */
					foo->stackPointer += 2 * 4;
				}
				/* begin internalizeIPandSP */
				localIP = ((char *) foo->instructionPointer);
				localSP = ((char *) foo->stackPointer);
				localHomeContext = foo->theHomeContext;
				if (foo->successFlag) {
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					goto l25;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((14 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l25:	/* end case */;
			break;
		case 191:
			/* bytecodePrimBitOr */
			{
				int integerArgument;
				int integerReceiver;
				int object;
				int sp;
				int top;
				int top1;
				int top2;
				int top11;
				foo->successFlag = 1;
				/* begin externalizeIPandSP */
				foo->instructionPointer = ((unsigned) localIP);
				foo->stackPointer = ((unsigned) localSP);
				foo->theHomeContext = localHomeContext;
				/* begin primitiveBitOr */
				/* begin popPos32BitInteger */
				/* begin popStack */
				top1 = longAt(foo->stackPointer);
				foo->stackPointer -= 4;
				top = top1;
				integerArgument = positive32BitValueOf(top);
				/* begin popPos32BitInteger */
				/* begin popStack */
				top11 = longAt(foo->stackPointer);
				foo->stackPointer -= 4;
				top2 = top11;
				integerReceiver = positive32BitValueOf(top2);
				if (foo->successFlag) {
					/* begin push: */
					object = positive32BitIntegerFor(integerReceiver | integerArgument);
					longAtput(sp = foo->stackPointer + 4, object);
					foo->stackPointer = sp;
				} else {
					/* begin unPop: */
					foo->stackPointer += 2 * 4;
				}
				/* begin internalizeIPandSP */
				localIP = ((char *) foo->instructionPointer);
				localSP = ((char *) foo->stackPointer);
				localHomeContext = foo->theHomeContext;
				if (foo->successFlag) {
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					goto l26;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((15 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l26:	/* end case */;
			break;
		case 192:
			/* bytecodePrimAt */
			{
				int result;
				int atIx;
				int rcvr;
				int index;
				int fmt;
				int result1;
				int stSize;
				int fixedFields;
				index = longAt(localSP);
				rcvr = longAt(localSP - (1 * 4));
				foo->successFlag = (!((rcvr & 1))) && ((index & 1));
				if (foo->successFlag) {
					atIx = rcvr & AtCacheMask;
					if ((atCache[atIx + AtCacheOop]) == rcvr) {
						/* begin commonVariableInternal:at:cacheIndex: */
						stSize = atCache[atIx + AtCacheSize];
						if (((((unsigned ) ((index >> 1)))) >= 1) && ((((unsigned ) ((index >> 1)))) <= (((unsigned ) stSize)))) {
							fmt = atCache[atIx + AtCacheFmt];
							if (fmt <= 4) {
								fixedFields = atCache[atIx + AtCacheFixedFields];
								result = longAt(((((char *) rcvr)) + BaseHeaderSize) + (((((index >> 1)) + fixedFields) - 1) << 2));
								goto l28;
							}
							if (fmt < 8) {
								result1 = longAt(((((char *) rcvr)) + BaseHeaderSize) + ((((index >> 1)) - 1) << 2));
								/* begin externalizeIPandSP */
								foo->instructionPointer = ((unsigned) localIP);
								foo->stackPointer = ((unsigned) localSP);
								foo->theHomeContext = localHomeContext;
								result1 = positive32BitIntegerFor(result1);
								/* begin internalizeIPandSP */
								localIP = ((char *) foo->instructionPointer);
								localSP = ((char *) foo->stackPointer);
								localHomeContext = foo->theHomeContext;
								result = result1;
								goto l28;
							}
							if (fmt >= 16) {
								result = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CharacterTable << 2))))) + BaseHeaderSize) + ((byteAt(((((char *) rcvr)) + BaseHeaderSize) + (((index >> 1)) - 1))) << 2));
								goto l28;
							} else {
								result = (((byteAt(((((char *) rcvr)) + BaseHeaderSize) + (((index >> 1)) - 1))) << 1) | 1);
								goto l28;
							}
						}
						/* begin primitiveFail */
						foo->successFlag = 0;
					l28:	/* end commonVariableInternal:at:cacheIndex: */;
						if (foo->successFlag) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							/* begin internalPop:thenPush: */
							longAtput(localSP -= (2 - 1) * 4, result);
							goto l27;
						}
					}
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((16 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
		l27:	/* end case */;
			break;
		case 193:
			/* bytecodePrimAtPut */
			{
				int value;
				int atIx;
				int rcvr;
				int index;
				int fmt;
				int stSize;
				int fixedFields;
				int valToPut;
				value = longAt(localSP);
				index = longAt(localSP - (1 * 4));
				rcvr = longAt(localSP - (2 * 4));
				foo->successFlag = (!((rcvr & 1))) && ((index & 1));
				if (foo->successFlag) {
					atIx = (rcvr & AtCacheMask) + AtPutBase;
					if ((atCache[atIx + AtCacheOop]) == rcvr) {
						/* begin commonVariable:at:put:cacheIndex: */
						stSize = atCache[atIx + AtCacheSize];
						if (((((unsigned ) ((index >> 1)))) >= 1) && ((((unsigned ) ((index >> 1)))) <= (((unsigned ) stSize)))) {
							fmt = atCache[atIx + AtCacheFmt];
							if (fmt <= 4) {
								fixedFields = atCache[atIx + AtCacheFixedFields];
								/* begin storePointer:ofObject:withValue: */
								if (rcvr < foo->youngStart) {
									possibleRootStoreIntovalue(rcvr, value);
								}
								longAtput(((((char *) rcvr)) + BaseHeaderSize) + (((((index >> 1)) + fixedFields) - 1) << 2), value);
								goto l30;
							}
							if (fmt < 8) {
								valToPut = positive32BitValueOf(value);
								if (foo->successFlag) {
									longAtput(((((char *) rcvr)) + BaseHeaderSize) + ((((index >> 1)) - 1) << 2), valToPut);
								}
								goto l30;
							}
							if (fmt >= 16) {
								valToPut = asciiOfCharacter(value);
								if (!(foo->successFlag)) {
									goto l30;
								}
							} else {
								valToPut = value;
							}
							if ((valToPut & 1)) {
								valToPut = (valToPut >> 1);
								if (!((valToPut >= 0) && (valToPut <= 255))) {
									/* begin primitiveFail */
									foo->successFlag = 0;
									goto l30;
								}
								byteAtput(((((char *) rcvr)) + BaseHeaderSize) + (((index >> 1)) - 1), valToPut);
								goto l30;
							}
						}
						/* begin primitiveFail */
						foo->successFlag = 0;
					l30:	/* end commonVariable:at:put:cacheIndex: */;
						if (foo->successFlag) {
							/* begin fetchNextBytecode */
							currentBytecode = byteAt(++localIP);
							/* begin internalPop:thenPush: */
							longAtput(localSP -= (3 - 1) * 4, value);
							goto l29;
						}
					}
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((17 * 2) << 2));
				foo->argumentCount = 2;
				goto normalSend;
			}
;
		l29:	/* end case */;
			break;
		case 194:
			/* bytecodePrimSize */
			{
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((18 * 2) << 2));
				foo->argumentCount = 0;
				goto normalSend;
			}
;
			break;
		case 195:
			/* bytecodePrimNext */
			{
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((19 * 2) << 2));
				foo->argumentCount = 0;
				goto normalSend;
			}
;
			break;
		case 196:
			/* bytecodePrimNextPut */
			{
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((20 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
			break;
		case 197:
			/* bytecodePrimAtEnd */
			{
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((21 * 2) << 2));
				foo->argumentCount = 0;
				goto normalSend;
			}
;
			break;
		case 198:
			/* bytecodePrimEquivalent */
			{
				int rcvr;
				int arg;
				int bytecode;
				int offset;
				rcvr = longAt(localSP - (1 * 4));
				arg = longAt(localSP - (0 * 4));
				/* begin booleanCheat: */
				bytecode = byteAt(++localIP);
				/* begin internalPop: */
				localSP -= 2 * 4;
				if ((bytecode < 160) && (bytecode > 151)) {
					if (rcvr == arg) {
						/* begin fetchNextBytecode */
						currentBytecode = byteAt(++localIP);
						goto l31;
					} else {
						/* begin jump: */
						localIP = (localIP + (bytecode - 151)) + 1;
						currentBytecode = byteAt(localIP);
						goto l31;
					}
				}
				if (bytecode == 172) {
					offset = byteAt(++localIP);
					if (rcvr == arg) {
						/* begin fetchNextBytecode */
						currentBytecode = byteAt(++localIP);
						goto l31;
					} else {
						/* begin jump: */
						localIP = (localIP + offset) + 1;
						currentBytecode = byteAt(localIP);
						goto l31;
					}
				}
				localIP -= 1;
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
				if (rcvr == arg) {
					/* begin internalPush: */
					longAtput(localSP += 4, foo->trueObj);
				} else {
					/* begin internalPush: */
					longAtput(localSP += 4, foo->falseObj);
				}
			l31:	/* end booleanCheat: */;
			}
;
			break;
		case 199:
			/* bytecodePrimClass */
			{
				int rcvr;
				int oop;
				int ccIndex;
				rcvr = longAt(localSP);
				/* begin internalPop:thenPush: */
				/* begin fetchClassOf: */
				if ((rcvr & 1)) {
					oop = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
					goto l32;
				}
				ccIndex = (((unsigned) (longAt(rcvr))) >> 12) & 31;
				if (ccIndex == 0) {
					oop = (longAt(rcvr - 4)) & AllButTypeMask;
					goto l32;
				} else {
					oop = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
					goto l32;
				}
			l32:	/* end fetchClassOf: */;
				longAtput(localSP -= (1 - 1) * 4, oop);
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
			}
;
			break;
		case 200:
			/* bytecodePrimBlockCopy */
			{
				int rcvr;
				int hdr;
				int successValue;
				int initialIP;
				int context;
				int newContext;
				int methodContext;
				int contextSize;
				int header;
				int oop;
				int sp;
				rcvr = longAt(localSP - (1 * 4));
				foo->successFlag = 1;
				hdr = longAt(rcvr);
				/* begin success: */
				successValue = (((((unsigned) hdr) >> 12) & 31) == 13) || ((((((unsigned) hdr) >> 12) & 31) == 14) || (((((unsigned) hdr) >> 12) & 31) == 4));
				foo->successFlag = successValue && foo->successFlag;
				if (foo->successFlag) {
					/* begin externalizeIPandSP */
					foo->instructionPointer = ((unsigned) localIP);
					foo->stackPointer = ((unsigned) localSP);
					foo->theHomeContext = localHomeContext;
					/* begin primitiveBlockCopy */
					context = longAt(foo->stackPointer - (1 * 4));
					if (((longAt(((((char *) context)) + BaseHeaderSize) + (MethodIndex << 2))) & 1)) {
						methodContext = longAt(((((char *) context)) + BaseHeaderSize) + (HomeIndex << 2));
					} else {
						methodContext = context;
					}
					/* begin sizeBitsOf: */
					header = longAt(methodContext);
					if ((header & TypeMask) == HeaderTypeSizeAndClass) {
						contextSize = (longAt(methodContext - 8)) & AllButTypeMask;
						goto l34;
					} else {
						contextSize = header & SizeMask;
						goto l34;
					}
				l34:	/* end sizeBitsOf: */;
					context = null;
					/* begin pushRemappableOop: */
					remapBuffer[foo->remapBufferCount += 1] = methodContext;
					newContext = instantiateContextsizeInBytes(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassBlockContext << 2)), contextSize);
					/* begin popRemappableOop */
					oop = remapBuffer[foo->remapBufferCount];
					foo->remapBufferCount -= 1;
					methodContext = oop;
					initialIP = (((foo->instructionPointer - foo->method) << 1) | 1);
					longAtput(((((char *) newContext)) + BaseHeaderSize) + (InitialIPIndex << 2), initialIP);
					longAtput(((((char *) newContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), initialIP);
					/* begin storeStackPointerValue:inContext: */
					longAtput(((((char *) newContext)) + BaseHeaderSize) + (StackPointerIndex << 2), ((0 << 1) | 1));
					longAtput(((((char *) newContext)) + BaseHeaderSize) + (BlockArgumentCountIndex << 2), longAt(foo->stackPointer - (0 * 4)));
					longAtput(((((char *) newContext)) + BaseHeaderSize) + (HomeIndex << 2), methodContext);
					longAtput(((((char *) newContext)) + BaseHeaderSize) + (SenderIndex << 2), foo->nilObj);
					/* begin pop:thenPush: */
					longAtput(sp = foo->stackPointer - ((2 - 1) * 4), newContext);
					foo->stackPointer = sp;
					/* begin internalizeIPandSP */
					localIP = ((char *) foo->instructionPointer);
					localSP = ((char *) foo->stackPointer);
					localHomeContext = foo->theHomeContext;
				}
				if (!(foo->successFlag)) {
					foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((24 * 2) << 2));
					foo->argumentCount = 1;
					goto normalSend;
					goto l33;
				}
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
			}
;
		l33:	/* end case */;
			break;
		case 201:
			/* bytecodePrimValue */
			{
				int block;
				int cl;
				int ccIndex;
				block = longAt(localSP);
				foo->successFlag = 1;
				foo->argumentCount = 0;
				/* begin assertClassOf:is: */
				if ((block & 1)) {
					foo->successFlag = 0;
					goto l36;
				}
				ccIndex = (((unsigned) (longAt(block))) >> 12) & 31;
				if (ccIndex == 0) {
					cl = (longAt(block - 4)) & AllButTypeMask;
				} else {
					cl = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
				}
				/* begin success: */
				foo->successFlag = (cl == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassBlockContext << 2)))) && foo->successFlag;
			l36:	/* end assertClassOf:is: */;
				if (foo->successFlag) {
					/* begin externalizeIPandSP */
					foo->instructionPointer = ((unsigned) localIP);
					foo->stackPointer = ((unsigned) localSP);
					foo->theHomeContext = localHomeContext;
					primitiveValue();
					/* begin internalizeIPandSP */
					localIP = ((char *) foo->instructionPointer);
					localSP = ((char *) foo->stackPointer);
					localHomeContext = foo->theHomeContext;
				}
				if (!(foo->successFlag)) {
					foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((25 * 2) << 2));
					foo->argumentCount = 0;
					goto normalSend;
					goto l35;
				}
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
			}
;
		l35:	/* end case */;
			break;
		case 202:
			/* bytecodePrimValueWithArg */
			{
				int block;
				int cl;
				int ccIndex;
				block = longAt(localSP - (1 * 4));
				foo->successFlag = 1;
				foo->argumentCount = 1;
				/* begin assertClassOf:is: */
				if ((block & 1)) {
					foo->successFlag = 0;
					goto l38;
				}
				ccIndex = (((unsigned) (longAt(block))) >> 12) & 31;
				if (ccIndex == 0) {
					cl = (longAt(block - 4)) & AllButTypeMask;
				} else {
					cl = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
				}
				/* begin success: */
				foo->successFlag = (cl == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassBlockContext << 2)))) && foo->successFlag;
			l38:	/* end assertClassOf:is: */;
				if (foo->successFlag) {
					/* begin externalizeIPandSP */
					foo->instructionPointer = ((unsigned) localIP);
					foo->stackPointer = ((unsigned) localSP);
					foo->theHomeContext = localHomeContext;
					primitiveValue();
					/* begin internalizeIPandSP */
					localIP = ((char *) foo->instructionPointer);
					localSP = ((char *) foo->stackPointer);
					localHomeContext = foo->theHomeContext;
				}
				if (!(foo->successFlag)) {
					foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((26 * 2) << 2));
					foo->argumentCount = 1;
					goto normalSend;
					goto l37;
				}
				/* begin fetchNextBytecode */
				currentBytecode = byteAt(++localIP);
			}
;
		l37:	/* end case */;
			break;
		case 203:
			/* bytecodePrimDo */
			{
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((27 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
			break;
		case 204:
			/* bytecodePrimNew */
			{
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((28 * 2) << 2));
				foo->argumentCount = 0;
				goto normalSend;
			}
;
			break;
		case 205:
			/* bytecodePrimNewWithArg */
			{
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((29 * 2) << 2));
				foo->argumentCount = 1;
				goto normalSend;
			}
;
			break;
		case 206:
			/* bytecodePrimPointX */
			{
				int rcvr;
				int cl;
				int ccIndex;
				foo->successFlag = 1;
				rcvr = longAt(localSP);
				/* begin assertClassOf:is: */
				if ((rcvr & 1)) {
					foo->successFlag = 0;
					goto l40;
				}
				ccIndex = (((unsigned) (longAt(rcvr))) >> 12) & 31;
				if (ccIndex == 0) {
					cl = (longAt(rcvr - 4)) & AllButTypeMask;
				} else {
					cl = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
				}
				/* begin success: */
				foo->successFlag = (cl == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassPoint << 2)))) && foo->successFlag;
			l40:	/* end assertClassOf:is: */;
				if (foo->successFlag) {
					/* begin internalPop:thenPush: */
					longAtput(localSP -= (1 - 1) * 4, longAt(((((char *) rcvr)) + BaseHeaderSize) + (XIndex << 2)));
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					goto l39;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((30 * 2) << 2));
				foo->argumentCount = 0;
				goto normalSend;
			}
;
		l39:	/* end case */;
			break;
		case 207:
			/* bytecodePrimPointY */
			{
				int rcvr;
				int cl;
				int ccIndex;
				foo->successFlag = 1;
				rcvr = longAt(localSP);
				/* begin assertClassOf:is: */
				if ((rcvr & 1)) {
					foo->successFlag = 0;
					goto l42;
				}
				ccIndex = (((unsigned) (longAt(rcvr))) >> 12) & 31;
				if (ccIndex == 0) {
					cl = (longAt(rcvr - 4)) & AllButTypeMask;
				} else {
					cl = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
				}
				/* begin success: */
				foo->successFlag = (cl == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassPoint << 2)))) && foo->successFlag;
			l42:	/* end assertClassOf:is: */;
				if (foo->successFlag) {
					/* begin internalPop:thenPush: */
					longAtput(localSP -= (1 - 1) * 4, longAt(((((char *) rcvr)) + BaseHeaderSize) + (YIndex << 2)));
					/* begin fetchNextBytecode */
					currentBytecode = byteAt(++localIP);
					goto l41;
				}
				foo->messageSelector = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SpecialSelectors << 2))))) + BaseHeaderSize) + ((31 * 2) << 2));
				foo->argumentCount = 0;
				goto normalSend;
			}
;
		l41:	/* end case */;
			break;
		case 208:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((208 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 208) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 209:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((209 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 209) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 210:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((210 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 210) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 211:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((211 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 211) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 212:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((212 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 212) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 213:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((213 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 213) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 214:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((214 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 214) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 215:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((215 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 215) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 216:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((216 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 216) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 217:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((217 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 217) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 218:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((218 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 218) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 219:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((219 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 219) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 220:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((220 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 220) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 221:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((221 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 221) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 222:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((222 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 222) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 223:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((223 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 223) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 224:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((224 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 224) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 225:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((225 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 225) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 226:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((226 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 226) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 227:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((227 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 227) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 228:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((228 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 228) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 229:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((229 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 229) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 230:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((230 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 230) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 231:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((231 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 231) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 232:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((232 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 232) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 233:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((233 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 233) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 234:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((234 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 234) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 235:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((235 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 235) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 236:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((236 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 236) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 237:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((237 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 237) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 238:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((238 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 238) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 239:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((239 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 239) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 240:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((240 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 240) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 241:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((241 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 241) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 242:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((242 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 242) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 243:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((243 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 243) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 244:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((244 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 244) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 245:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((245 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 245) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 246:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((246 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 246) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 247:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((247 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 247) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 248:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((248 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 248) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 249:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((249 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 249) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 250:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((250 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 250) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 251:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((251 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 251) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 252:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((252 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 252) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 253:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((253 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 253) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 254:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((254 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 254) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		case 255:
			/* sendLiteralSelectorBytecode */
			{
				foo->messageSelector = longAt(((((char *) foo->method)) + BaseHeaderSize) + (((255 & 15) + LiteralStart) << 2));
				foo->argumentCount = ((((unsigned) 255) >> 4) & 3) - 1;
				goto normalSend;
			}
;
			break;
		}
	}

	/* undo the pre-increment of IP before returning */

	localIP -= 1;
	/* begin externalizeIPandSP */
	foo->instructionPointer = ((unsigned) localIP);
	foo->stackPointer = ((unsigned) localSP);
	foo->theHomeContext = localHomeContext;
}


/*	Support for external primitives. */

int isKindOf(int oop, char *className) {
register struct foo * foo = &fum;
    int oopClass;
    int ccIndex;

	/* begin fetchClassOf: */
	if ((oop & 1)) {
		oopClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		oopClass = (longAt(oop - 4)) & AllButTypeMask;
		goto l1;
	} else {
		oopClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	while (!(oopClass == foo->nilObj)) {
		if (classNameOfIs(oopClass, className)) {
			return 1;
		}
		oopClass = longAt(((((char *) oopClass)) + BaseHeaderSize) + (SuperclassIndex << 2));
	}
	return 0;
}


/*	Support for external primitives */

int isMemberOf(int oop, char *className) {
register struct foo * foo = &fum;
    int oopClass;
    int ccIndex;

	/* begin fetchClassOf: */
	if ((oop & 1)) {
		oopClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		oopClass = (longAt(oop - 4)) & AllButTypeMask;
		goto l1;
	} else {
		oopClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	return classNameOfIs(oopClass, className);
}


/*	Answer true if this is an indexable object with pointer elements, e.g., an array */

int isArray(int oop) {
	return ((oop & 1) == 0) && (((((unsigned) (longAt(oop))) >> 8) & 15) == 2);
}


/*	Answer true if the argument contains indexable bytes. See comment in formatOf: */
/*	Note: Includes CompiledMethods. */

int isBytes(int oop) {
	return ((oop & 1) == 0) && (((((unsigned) (longAt(oop))) >> 8) & 15) >= 8);
}

int isFloatObject(int oop) {
	return (fetchClassOf(oop)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassFloat << 2)));
}


/*	Is this a MethodContext whose meth has a primitive number of 199? */
/*	NB: the use of a primitive number for marking the method is pretty grungy, but it is simple to use for a test sytem, not too expensive and we don't actually have the two spare method header bits we need. We can probably obtain them when the method format is changed.
	NB 2: actually, the jitter will probably implement the prim to actually mark the volatile frame by changing the return function pointer. */

int isHandlerMarked(int aContext) {
    int meth;
    int pIndex;
    int header;
    int primBits;

	header = longAt(aContext);
	if (!(((((unsigned) header) >> 12) & 31) == 14)) {
		return 0;
	}
	meth = longAt(((((char *) aContext)) + BaseHeaderSize) + (MethodIndex << 2));
	/* begin primitiveIndexOf: */
	primBits = (((unsigned) (longAt(((((char *) meth)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 1) & 268435967;
	pIndex = (primBits & 511) + (((unsigned) primBits) >> 19);
	return pIndex == 199;
}


/*	Return true if the given address is in ST object memory */

int isInMemory(int address) {
	return (address >= (startOfMemory())) && (address < foo->endOfMemory);
}

int isIndexable(int oop) {
	return ((((unsigned) (longAt(oop))) >> 8) & 15) >= 2;
}

int isIntegerObject(int objectPointer) {
	return (objectPointer & 1) > 0;
}


/*	Return true if the given value can be represented as a Smalltalk integer value. */
/*	Details: This trick is from Tim Rowledge. Use a shift and XOR to set the sign bit if and only if the top two bits of the given value are the same, then test the sign bit. Note that the top two bits are equal for exactly those integers in the range that can be represented in 31-bits. */

int isIntegerValue(int intValue) {
	return (intValue ^ (intValue << 1)) >= 0;
}


/*	Answer true if the argument has only fields that can hold oops. See comment in formatOf: */

int isPointers(int oop) {
	return ((oop & 1) == 0) && (((((unsigned) (longAt(oop))) >> 8) & 15) <= 4);
}


/*	Answer true if the argument has only weak fields that can hold oops. See comment in formatOf: */

int isWeak(int oop) {
	return ((oop & 1) == 0) && (((((unsigned) (longAt(oop))) >> 8) & 15) == 4);
}


/*	Answer true if the argument contains only indexable words (no oops). See comment in formatOf: */

int isWords(int oop) {
	return ((oop & 1) == 0) && (((((unsigned) (longAt(oop))) >> 8) & 15) == 6);
}


/*	Answer true if the contains only indexable words or bytes (no oops). See comment in formatOf: */
/*	Note: Excludes CompiledMethods. */

int isWordsOrBytes(int oop) {
	return ((oop & 1) == 0) && (isWordsOrBytesNonInt(oop));
}


/*	Answer true if the contains only indexable words or bytes (no oops). See comment in formatOf: */
/*	Note: Excludes CompiledMethods. */

int isWordsOrBytesNonInt(int oop) {
    int fmt;

	fmt = (((unsigned) (longAt(oop))) >> 8) & 15;
	return (fmt == 6) || ((fmt >= 8) && (fmt <= 11));
}


/*	Return the byte offset of the last pointer field of the given object.  
	Works with CompiledMethods, as well as ordinary objects. 
	Can be used even when the type bits are not correct. */

int lastPointerOf(int oop) {
    int fmt;
    int sz;
    int methodHeader;
    int contextSize;
    int header;
    int sp;
    int header1;
    int type;

	header = longAt(oop);
	fmt = (((unsigned) header) >> 8) & 15;
	if (fmt <= 4) {
		if ((fmt == 3) && ((((((unsigned) header) >> 12) & 31) == 13) || ((((((unsigned) header) >> 12) & 31) == 14) || (((((unsigned) header) >> 12) & 31) == 4)))) {
			/* begin fetchStackPointerOf: */
			sp = longAt(((((char *) oop)) + BaseHeaderSize) + (StackPointerIndex << 2));
			if (!((sp & 1))) {
				contextSize = 0;
				goto l1;
			}
			contextSize = (sp >> 1);
		l1:	/* end fetchStackPointerOf: */;
			return (CtxtTempFrameStart + contextSize) * 4;
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
			sz = (longAt(oop - 8)) & AllButTypeMask;
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
	return (((((unsigned) methodHeader) >> 10) & 255) * 4) + BaseHeaderSize;
}


/*	Return the number of indexable bytes or words in the given object. Assume the argument is not an integer. For a CompiledMethod, the size of the method header (in bytes) should be subtracted from the result. */

int lengthOf(int oop) {
    int header;
    int sz;

	header = longAt(oop);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(oop - 8)) & AllButTypeMask;
	} else {
		sz = header & SizeMask;
	}
	if (((((unsigned) header) >> 8) & 15) < 8) {
		return ((unsigned) (sz - BaseHeaderSize)) >> 2;
	} else {
		return (sz - BaseHeaderSize) - (((((unsigned) header) >> 8) & 15) & 3);
	}
	return null;
}

int literalofMethod(int offset, int methodPointer) {
	return longAt(((((char *) methodPointer)) + BaseHeaderSize) + ((offset + LiteralStart) << 2));
}

int literalCountOf(int methodPointer) {
	return (((unsigned) (longAt(((((char *) methodPointer)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 10) & 255;
}


/*	This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin_loadBitBltFrom
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided */

int loadBitBltFrom(int bb) {
    int fn;

	fn = ioLoadFunctionFrom("loadBitBltFrom", "BitBltPlugin");
	if (fn == 0) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	return  ((int (*) (int)) fn)(bb);
}


/*	If floatOrInt is an integer, then convert it to a C double float and return it.
	If it is a Float, then load its value and return it.
	Otherwise fail -- ie return with successFlag set to false. */

double loadFloatOrIntFrom(int floatOrInt) {
register struct foo * foo = &fum;
	if ((floatOrInt & 1)) {
		return ((double) (floatOrInt >> 1));
	}
	if ((fetchClassOfNonInt(floatOrInt)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassFloat << 2)))) {
		return floatValueOf(floatOrInt);
	}
	foo->successFlag = 0;
}

int loadInitialContext(void) {
register struct foo * foo = &fum;
    int sched;
    int proc;
    int activeCntx;
    int tmp;

	sched = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SchedulerAssociation << 2))))) + BaseHeaderSize) + (ValueIndex << 2));
	proc = longAt(((((char *) sched)) + BaseHeaderSize) + (ActiveProcessIndex << 2));
	foo->activeContext = longAt(((((char *) proc)) + BaseHeaderSize) + (SuspendedContextIndex << 2));
	if (foo->activeContext < foo->youngStart) {
		beRootIfOld(foo->activeContext);
	}
	/* begin fetchContextRegisters: */
	activeCntx = foo->activeContext;
	tmp = longAt(((((char *) activeCntx)) + BaseHeaderSize) + (MethodIndex << 2));
	if ((tmp & 1)) {
		tmp = longAt(((((char *) activeCntx)) + BaseHeaderSize) + (HomeIndex << 2));
		if (tmp < foo->youngStart) {
			beRootIfOld(tmp);
		}
	} else {
		tmp = activeCntx;
	}
	foo->theHomeContext = tmp;
	foo->receiver = longAt(((((char *) tmp)) + BaseHeaderSize) + (ReceiverIndex << 2));
	foo->method = longAt(((((char *) tmp)) + BaseHeaderSize) + (MethodIndex << 2));
	tmp = ((longAt(((((char *) activeCntx)) + BaseHeaderSize) + (InstructionPointerIndex << 2))) >> 1);
	foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
	tmp = ((longAt(((((char *) activeCntx)) + BaseHeaderSize) + (StackPointerIndex << 2))) >> 1);
	foo->stackPointer = (activeCntx + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * 4);
	foo->reclaimableContextCount = 0;
}

int lookupMethodInClass(int class) {
register struct foo * foo = &fum;
    int found;
    int rclass;
    int dictionary;
    int currentClass;
    int oop;
    int oop1;
    int length;
    int nextSelector;
    int methodArray;
    int index;
    int mask;
    int wrapAround;
    int sz;
    int primBits;
    int header;

	currentClass = class;
	while (currentClass != foo->nilObj) {
		dictionary = longAt(((((char *) currentClass)) + BaseHeaderSize) + (MessageDictionaryIndex << 2));
		if (dictionary == foo->nilObj) {
			/* begin pushRemappableOop: */
			remapBuffer[foo->remapBufferCount += 1] = currentClass;
			createActualMessageTo(class);
			/* begin popRemappableOop */
			oop = remapBuffer[foo->remapBufferCount];
			foo->remapBufferCount -= 1;
			currentClass = oop;
			foo->messageSelector = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SelectorCannotInterpret << 2));
			return lookupMethodInClass(longAt(((((char *) currentClass)) + BaseHeaderSize) + (SuperclassIndex << 2)));
		}
		/* begin lookupMethodInDictionary: */
		/* begin fetchWordLengthOf: */
		/* begin sizeBitsOf: */
		header = longAt(dictionary);
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(dictionary - 8)) & AllButTypeMask;
			goto l1;
		} else {
			sz = header & SizeMask;
			goto l1;
		}
	l1:	/* end sizeBitsOf: */;
		length = ((unsigned) (sz - BaseHeaderSize)) >> 2;
		mask = (length - SelectorStart) - 1;
		if ((foo->messageSelector & 1)) {
			index = (mask & ((foo->messageSelector >> 1))) + SelectorStart;
		} else {
			index = (mask & ((((unsigned) (longAt(foo->messageSelector))) >> 17) & 4095)) + SelectorStart;
		}
		wrapAround = 0;
		while (1) {
			nextSelector = longAt(((((char *) dictionary)) + BaseHeaderSize) + (index << 2));
			if (nextSelector == foo->nilObj) {
				found = 0;
				goto l2;
			}
			if (nextSelector == foo->messageSelector) {
				methodArray = longAt(((((char *) dictionary)) + BaseHeaderSize) + (MethodArrayIndex << 2));
				foo->newMethod = longAt(((((char *) methodArray)) + BaseHeaderSize) + ((index - SelectorStart) << 2));
				if (((((unsigned) (longAt(foo->newMethod))) >> 8) & 15) >= 12) {
					/* begin primitiveIndexOf: */
					primBits = (((unsigned) (longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 1) & 268435967;
					foo->primitiveIndex = (primBits & 511) + (((unsigned) primBits) >> 19);
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
		currentClass = longAt(((((char *) currentClass)) + BaseHeaderSize) + (SuperclassIndex << 2));
	}
	if (foo->messageSelector == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SelectorDoesNotUnderstand << 2)))) {
		error("Recursive not understood error encountered");
	}
	/* begin pushRemappableOop: */
	remapBuffer[foo->remapBufferCount += 1] = class;
	createActualMessageTo(class);
	/* begin popRemappableOop */
	oop1 = remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	rclass = oop1;
	foo->messageSelector = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SelectorDoesNotUnderstand << 2));
	return lookupMethodInClass(rclass);
}


/*	Return the first free block after the given chunk in memory. */

int lowestFreeAfter(int chunk) {
    int oop;
    int oopHeaderType;
    int oopHeader;
    int oopSize;

	oop = chunk + (headerTypeBytes[(longAt(chunk)) & TypeMask]);
	while (oop < foo->endOfMemory) {
		oopHeader = longAt(oop);
		oopHeaderType = oopHeader & TypeMask;
		if (oopHeaderType == HeaderTypeFree) {
			return oop;
		} else {
			if (oopHeaderType == HeaderTypeSizeAndClass) {
				oopSize = (longAt(oop - 8)) & AllButTypeMask;
			} else {
				oopSize = oopHeader & SizeMask;
			}
		}
		oop = (oop + oopSize) + (headerTypeBytes[(longAt(oop + oopSize)) & TypeMask]);
	}
	error("expected to find at least one free object");
}

int makePointwithxValueyValue(int xValue, int yValue) {
register struct foo * foo = &fum;
    int pointResult;

	pointResult = instantiateSmallClasssizeInBytesfill(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassPoint << 2)), 12, foo->nilObj);
	/* begin storePointer:ofObject:withValue: */
	if (pointResult < foo->youngStart) {
		possibleRootStoreIntovalue(pointResult, ((xValue << 1) | 1));
	}
	longAtput(((((char *) pointResult)) + BaseHeaderSize) + (XIndex << 2), ((xValue << 1) | 1));
	/* begin storePointer:ofObject:withValue: */
	if (pointResult < foo->youngStart) {
		possibleRootStoreIntovalue(pointResult, ((yValue << 1) | 1));
	}
	longAtput(((((char *) pointResult)) + BaseHeaderSize) + (YIndex << 2), ((yValue << 1) | 1));
	return pointResult;
}


/*	Use the forwarding table to update the pointers of all non-free objects in the given range of memory. Also remap pointers in root objects which may contains pointers into the given memory range, and don't forget to flush the method cache based on the range */

int mapPointersInObjectsFromto(int memStart, int memEnd) {
register struct foo * foo = &fum;
    int oop;
    int i;
    int probe;
    int i1;

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
	for (i = 1; i <= foo->remapBufferCount; i += 1) {
		oop = remapBuffer[i];
		if (!((oop & 1))) {
			remapBuffer[i] = (remap(oop));
		}
	}
	/* begin flushMethodCacheFrom:to: */
	probe = 0;
	for (i1 = 1; i1 <= MethodCacheEntries; i1 += 1) {
		if (!((methodCache[probe + MethodCacheSelector]) == 0)) {
			if ((((((methodCache[probe + MethodCacheSelector]) >= memStart) && ((methodCache[probe + MethodCacheSelector]) < memEnd)) || (((methodCache[probe + MethodCacheClass]) >= memStart) && ((methodCache[probe + MethodCacheClass]) < memEnd))) || (((methodCache[probe + MethodCacheMethod]) >= memStart) && ((methodCache[probe + MethodCacheMethod]) < memEnd))) || (((methodCache[probe + MethodCacheNative]) >= memStart) && ((methodCache[probe + MethodCacheNative]) < memEnd))) {
				methodCache[probe + MethodCacheSelector] = 0;
			}
		}
		probe += MethodCacheEntrySize;
	}
	for (i1 = 1; i1 <= AtCacheTotalSize; i1 += 1) {
		atCache[i1] = 0;
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

int markAndTrace(int oop) {
register struct foo * foo = &fum;
    int action;
    int lastFieldOffset;
    int header;
    int childType;
    int typeBits;
    int type;
    int header1;
    int oop1;
    int lastFieldOffset1;
    int header2;
    int fmt;
    int sz;
    int methodHeader;
    int contextSize;
    int header3;
    int sp;
    int header11;
    int type1;
    int fmt1;
    int sz1;
    int methodHeader1;
    int contextSize1;
    int header4;
    int sp1;
    int header12;
    int type2;
    int parentField;
    int field;
    unsigned youngStartLocal;
    int child;

	header = longAt(oop);
	if (!((header & MarkBit) == 0)) {
		return 0;
	}
	header = (header & AllButTypeMask) | HeaderTypeGC;
	if (oop >= foo->youngStart) {
		header = header | MarkBit;
	}
	longAtput(oop, header);
	parentField = GCTopMarker;
	child = oop;
	/* begin lastPointerOf: */
	header4 = longAt(oop);
	fmt1 = (((unsigned) header4) >> 8) & 15;
	if (fmt1 <= 4) {
		if ((fmt1 == 3) && ((((((unsigned) header4) >> 12) & 31) == 13) || ((((((unsigned) header4) >> 12) & 31) == 14) || (((((unsigned) header4) >> 12) & 31) == 4)))) {
			/* begin fetchStackPointerOf: */
			sp1 = longAt(((((char *) oop)) + BaseHeaderSize) + (StackPointerIndex << 2));
			if (!((sp1 & 1))) {
				contextSize1 = 0;
				goto l11;
			}
			contextSize1 = (sp1 >> 1);
		l11:	/* end fetchStackPointerOf: */;
			lastFieldOffset = (CtxtTempFrameStart + contextSize1) * 4;
			goto l14;
		}
		/* begin sizeBitsOfSafe: */
		header12 = longAt(oop);
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
			sz1 = (longAt(oop - 8)) & AllButTypeMask;
			goto l13;
		} else {
			sz1 = header12 & SizeMask;
			goto l13;
		}
	l13:	/* end sizeBitsOfSafe: */;
		lastFieldOffset = sz1 - BaseHeaderSize;
		goto l14;
	}
	if (fmt1 < 12) {
		lastFieldOffset = 0;
		goto l14;
	}
	methodHeader1 = longAt(oop + BaseHeaderSize);
	lastFieldOffset = (((((unsigned) methodHeader1) >> 10) & 255) * 4) + BaseHeaderSize;
l14:	/* end lastPointerOf: */;
	field = oop + lastFieldOffset;
	action = StartField;

	/* run the tracer state machine until all objects reachable from oop are marked */

	youngStartLocal = foo->youngStart;
	while (!(action == Done)) {
		if (action == StartField) {
			/* begin startField */
			child = longAt(field);
			typeBits = child & TypeMask;
			if ((typeBits & 1) == 1) {
				field -= 4;
				action = StartField;
				goto l1;
			}
			if (typeBits == 0) {
				longAtput(field, parentField);
				parentField = field;
				action = StartObj;
				goto l1;
			}
			if (typeBits == 2) {
				if ((child & CompactClassMask) != 0) {
					child = child & AllButTypeMask;
					/* begin rightType: */
					if ((child & SizeMask) == 0) {
						childType = HeaderTypeSizeAndClass;
						goto l2;
					} else {
						if ((child & CompactClassMask) == 0) {
							childType = HeaderTypeClass;
							goto l2;
						} else {
							childType = HeaderTypeShort;
							goto l2;
						}
					}
				l2:	/* end rightType: */;
					longAtput(field, child | childType);
					action = Upward;
					goto l1;
				} else {
					child = longAt(field - 4);
					child = child & AllButTypeMask;
					longAtput(field - 4, parentField);
					parentField = (field - 4) | 1;
					action = StartObj;
					goto l1;
				}
			}
		l1:	/* end startField */;
		}
		if (action == StartObj) {
			/* begin startObj */
			oop1 = child;
			if (oop1 < youngStartLocal) {
				field = oop1;
				action = Upward;
				goto l6;
			}
			header2 = longAt(oop1);
			if ((header2 & MarkBit) == 0) {
				if (((((unsigned) (longAt(oop1))) >> 8) & 15) == 4) {
					lastFieldOffset1 = (nonWeakFieldsOf(oop1)) << 2;
				} else {
					/* begin lastPointerOf: */
					header3 = longAt(oop1);
					fmt = (((unsigned) header3) >> 8) & 15;
					if (fmt <= 4) {
						if ((fmt == 3) && ((((((unsigned) header3) >> 12) & 31) == 13) || ((((((unsigned) header3) >> 12) & 31) == 14) || (((((unsigned) header3) >> 12) & 31) == 4)))) {
							/* begin fetchStackPointerOf: */
							sp = longAt(((((char *) oop1)) + BaseHeaderSize) + (StackPointerIndex << 2));
							if (!((sp & 1))) {
								contextSize = 0;
								goto l7;
							}
							contextSize = (sp >> 1);
						l7:	/* end fetchStackPointerOf: */;
							lastFieldOffset1 = (CtxtTempFrameStart + contextSize) * 4;
							goto l10;
						}
						/* begin sizeBitsOfSafe: */
						header11 = longAt(oop1);
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
							sz = (longAt(oop1 - 8)) & AllButTypeMask;
							goto l9;
						} else {
							sz = header11 & SizeMask;
							goto l9;
						}
					l9:	/* end sizeBitsOfSafe: */;
						lastFieldOffset1 = sz - BaseHeaderSize;
						goto l10;
					}
					if (fmt < 12) {
						lastFieldOffset1 = 0;
						goto l10;
					}
					methodHeader = longAt(oop1 + BaseHeaderSize);
					lastFieldOffset1 = (((((unsigned) methodHeader) >> 10) & 255) * 4) + BaseHeaderSize;
				l10:	/* end lastPointerOf: */;
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
					header1 = longAt(field + 4);
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
					field += 4;
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
				field -= 4;
				action = StartField;
				goto l5;
			}
		l5:	/* end upward */;
		}
	}
}


/*	Mark and trace all oops in the interpreter's state. */
/*	Assume: All traced variables contain valid oops. */

int markAndTraceInterpreterOops(void) {
register struct foo * foo = &fum;
    int oop;
    int i;

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
		oop = remapBuffer[i];
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

int markPhase(void) {
register struct foo * foo = &fum;
    int oop;
    int i;

	foo->freeContexts = NilContext;

	/* trace the interpreter's objects, including the active stack 
	and special objects array */

	foo->freeLargeContexts = NilContext;
	markAndTraceInterpreterOops();
	for (i = 1; i <= foo->rootTableCount; i += 1) {
		oop = rootTable[i];
		markAndTrace(oop);
	}
}

int methodArgumentCount(void) {
	return foo->argumentCount;
}

int methodPrimitiveIndex(void) {
	return foo->primitiveIndex;
}


/*	The module with the given name was just unloaded. 
	Make sure we have no dangling references. */

EXPORT(int) moduleUnloaded(char * aModuleName) {
	if ((strcmp(aModuleName, "SurfacePlugin")) == 0) {
		showSurfaceFn = 0;
	}
}


/*	For access from BitBlt module */

int nilObject(void) {
	return foo->nilObj;
}


/*	Return the number of non-weak fields in oop (i.e. the number of fixed fields).
	Note: The following is copied from fixedFieldsOf:format:length: since we do know
	the format of the oop (e.g. format = 4) and thus don't need the length. */

int nonWeakFieldsOf(int oop) {
register struct foo * foo = &fum;
    int classFormat;
    int class;
    int ccIndex;

	if (!(((((unsigned) (longAt(oop))) >> 8) & 15) == 4)) {
		error("Called fixedFieldsOfWeak: with a non-weak oop");
	}
	/* begin fetchClassOf: */
	if ((oop & 1)) {
		class = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(oop - 4)) & AllButTypeMask;
		goto l1;
	} else {
		class = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	classFormat = (longAt(((((char *) class)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1;
	return (((((unsigned) classFormat) >> 11) & 192) + ((((unsigned) classFormat) >> 2) & 63)) - 1;
}


/*	Record that the given oop in the old object area points to an 
	object in the young area. 
	HeaderLoc is usually = oop, but may be an addr in a 
	forwarding block. */

int noteAsRootheaderLoc(int oop, int headerLoc) {
register struct foo * foo = &fum;
    int header;

	header = longAt(headerLoc);
	if ((header & RootBit) == 0) {
		if (foo->rootTableCount < RootTableRedZone) {
			foo->rootTableCount += 1;
			rootTable[foo->rootTableCount] = oop;
			longAtput(headerLoc, header | RootBit);
		} else {
			if (foo->rootTableCount < RootTableSize) {
				foo->rootTableCount += 1;
				rootTable[foo->rootTableCount] = oop;
				longAtput(headerLoc, header | RootBit);
				foo->allocationCount = foo->allocationsBetweenGCs + 1;
			}
		}
	}
}


/*	This should never be called: either the compiler is uninitialised (in which case the hooks should never be reached) or the compiler initialisation should have replaced all the hook with their external implementations. */

int nullCompilerHook(void) {
	error("uninitialised compiler hook called");
	return 0;
}


/*	Return the object or free chunk immediately following the 
	given object or free chunk in memory. Return endOfMemory 
	when enumeration is complete. */

int objectAfter(int oop) {
    int sz;
    int header;

	if (DoAssertionChecks) {
		if (oop >= foo->endOfMemory) {
			error("no objects after the end of memory");
		}
	}
	if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
		sz = (longAt(oop)) & AllButTypeMask;
	} else {
		/* begin sizeBitsOf: */
		header = longAt(oop);
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(oop - 8)) & AllButTypeMask;
			goto l1;
		} else {
			sz = header & SizeMask;
			goto l1;
		}
	l1:	/* end sizeBitsOf: */;
	}
	return (oop + sz) + (headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
}


/*	If this is a pointers object, check that its fields are all okay oops. */

int okayFields(int oop) {
register struct foo * foo = &fum;
    int c;
    int i;
    int fieldOop;
    int ccIndex;

	if ((oop == null) || (oop == 0)) {
		return 1;
	}
	if ((oop & 1)) {
		return 1;
	}
	okayOop(oop);
	oopHasOkayClass(oop);
	if (!(((oop & 1) == 0) && (((((unsigned) (longAt(oop))) >> 8) & 15) <= 4))) {
		return 1;
	}
	/* begin fetchClassOf: */
	if ((oop & 1)) {
		c = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		c = (longAt(oop - 4)) & AllButTypeMask;
		goto l1;
	} else {
		c = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	if ((c == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassMethodContext << 2)))) || (c == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassBlockContext << 2))))) {
		i = (CtxtTempFrameStart + (fetchStackPointerOf(oop))) - 1;
	} else {
		i = (lengthOf(oop)) - 1;
	}
	while (i >= 0) {
		fieldOop = longAt(((((char *) oop)) + BaseHeaderSize) + (i << 2));
		if (!((fieldOop & 1))) {
			okayOop(fieldOop);
			oopHasOkayClass(fieldOop);
		}
		i -= 1;
	}
}


/*	Verify that the given oop is legitimate. Check address, header, and size but not class. */

int okayOop(int signedOop) {
register struct foo * foo = &fum;
    int fmt;
    int sz;
    int type;
    unsigned oop;
    int header;


	/* address and size checks */

	oop = ((unsigned) signedOop);
	if ((oop & 1)) {
		return 1;
	}
	if (!(oop < foo->endOfMemory)) {
		error("oop is not a valid address");
	}
	if (!((oop % 4) == 0)) {
		error("oop is not a word-aligned address");
	}
	/* begin sizeBitsOf: */
	header = longAt(oop);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(oop - 8)) & AllButTypeMask;
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
		if (((((unsigned) (longAt(oop))) >> 12) & 31) == 0) {
			error("cannot have zero compact class field in a short header");
		}
	}
	if (type == HeaderTypeClass) {
		if (!((oop >= 4) && (((longAt(oop - 4)) & TypeMask) == type))) {
			error("class header word has wrong type");
		}
	}
	if (type == HeaderTypeSizeAndClass) {
		if (!((oop >= 8) && ((((longAt(oop - 8)) & TypeMask) == type) && (((longAt(oop - 4)) & TypeMask) == type)))) {
			error("class header word has wrong type");
		}
	}
	fmt = (((unsigned) (longAt(oop))) >> 8) & 15;
	if ((fmt == 5) || (fmt == 7)) {
		error("oop has an unknown format type");
	}
	if (!(((longAt(oop)) & 536870912) == 0)) {
		error("unused header bit 30 is set; should be zero");
	}
	if ((((longAt(oop)) & RootBit) == 1) && (oop >= foo->youngStart)) {
		error("root bit is set in a young object");
	}
	return 1;
}


/*	Compute the oop of this chunk by adding its extra header bytes. */

int oopFromChunk(int chunk) {
	return chunk + (headerTypeBytes[(longAt(chunk)) & TypeMask]);
}


/*	Similar to oopHasOkayClass:, except that it only returns true or false. */

int oopHasAcceptableClass(int signedOop) {
register struct foo * foo = &fum;
    int formatMask;
    unsigned oopClass;
    unsigned oop;
    int behaviorFormatBits;
    int oopFormatBits;

	if ((signedOop & 1)) {
		return 1;
	}
	oop = ((unsigned) signedOop);
	if (!(oop < foo->endOfMemory)) {
		return 0;
	}
	if (!((oop % 4) == 0)) {
		return 0;
	}
	if (!((oop + (sizeBitsOf(oop))) < foo->endOfMemory)) {
		return 0;
	}
	oopClass = ((unsigned) (fetchClassOf(oop)));
	if ((oopClass & 1)) {
		return 0;
	}
	if (!(oopClass < foo->endOfMemory)) {
		return 0;
	}
	if (!((oopClass % 4) == 0)) {
		return 0;
	}
	if (!((oopClass + (sizeBitsOf(oopClass))) < foo->endOfMemory)) {
		return 0;
	}
	if (!((((oopClass & 1) == 0) && (((((unsigned) (longAt(oopClass))) >> 8) & 15) <= 4)) && ((lengthOf(oopClass)) >= 3))) {
		return 0;
	}
	if (((oop & 1) == 0) && (((((unsigned) (longAt(oop))) >> 8) & 15) >= 8)) {

		/* ignore extra bytes size bits */

		formatMask = 3072;
	} else {
		formatMask = 3840;
	}
	behaviorFormatBits = ((longAt(((((char *) oopClass)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1) & formatMask;
	oopFormatBits = (longAt(oop)) & formatMask;
	if (!(behaviorFormatBits == oopFormatBits)) {
		return 0;
	}
	return 1;
}


/*	Attempt to verify that the given oop has a reasonable behavior. The class must be a valid, non-integer oop and must not be nilObj. It must be a pointers object with three or more fields. Finally, the instance specification field of the behavior must match that of the instance. */

int oopHasOkayClass(int signedOop) {
    int formatMask;
    unsigned oopClass;
    unsigned oop;
    int behaviorFormatBits;
    int oopFormatBits;

	oop = ((unsigned) signedOop);
	okayOop(oop);
	oopClass = ((unsigned) (fetchClassOf(oop)));
	if ((oopClass & 1)) {
		error("a SmallInteger is not a valid class or behavior");
	}
	okayOop(oopClass);
	if (!((((oopClass & 1) == 0) && (((((unsigned) (longAt(oopClass))) >> 8) & 15) <= 4)) && ((lengthOf(oopClass)) >= 3))) {
		error("a class (behavior) must be a pointers object of size >= 3");
	}
	if (((oop & 1) == 0) && (((((unsigned) (longAt(oop))) >> 8) & 15) >= 8)) {

		/* ignore extra bytes size bits */

		formatMask = 3072;
	} else {
		formatMask = 3840;
	}
	behaviorFormatBits = ((longAt(((((char *) oopClass)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1) & formatMask;
	oopFormatBits = (longAt(oop)) & formatMask;
	if (!(behaviorFormatBits == oopFormatBits)) {
		error("object and its class (behavior) formats differ");
	}
	return 1;
}


/*	Note: May be called by translated primitive code. */

int pop(int nItems) {
register struct foo * foo = &fum;
	foo->stackPointer -= nItems * 4;
}

int popthenPush(int nItems, int oop) {
register struct foo * foo = &fum;
    int sp;

	longAtput(sp = foo->stackPointer - ((nItems - 1) * 4), oop);
	foo->stackPointer = sp;
}


/*	Note: May be called by translated primitive code. */

double popFloat(void) {
register struct foo * foo = &fum;
    double result;
    int top;
    int top1;
    int cl;
    int ccIndex;

	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	top = top1;
	/* begin assertClassOf:is: */
	if ((top & 1)) {
		foo->successFlag = 0;
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(top))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(top - 4)) & AllButTypeMask;
	} else {
		cl = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassFloat << 2)))) && foo->successFlag;
l1:	/* end assertClassOf:is: */;
	if (foo->successFlag) {
		;
		fetchFloatAtinto(top + BaseHeaderSize, result);
	}
	return result;
}


/*	Pop and return the possibly remapped object from the remap buffer. */

int popRemappableOop(void) {
register struct foo * foo = &fum;
    int oop;

	oop = remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	return oop;
}

int popStack(void) {
register struct foo * foo = &fum;
    int top;

	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	return top;
}


/*	Note - integerValue is interpreted as POSITIVE, eg, as the result of
		Bitmap>at:, or integer>bitAnd:. */

int positive32BitIntegerFor(int integerValue) {
    int newLargeInteger;

	if ((integerValue >= 0) && ((integerValue ^ (integerValue << 1)) >= 0)) {
		return ((integerValue << 1) | 1);
	}
	newLargeInteger = instantiateSmallClasssizeInBytesfill(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargePositiveInteger << 2)), 8, 0);
	byteAtput(((((char *) newLargeInteger)) + BaseHeaderSize) + 3, (((unsigned) integerValue) >> 24) & 255);
	byteAtput(((((char *) newLargeInteger)) + BaseHeaderSize) + 2, (((unsigned) integerValue) >> 16) & 255);
	byteAtput(((((char *) newLargeInteger)) + BaseHeaderSize) + 1, (((unsigned) integerValue) >> 8) & 255);
	byteAtput(((((char *) newLargeInteger)) + BaseHeaderSize) + 0, integerValue & 255);
	return newLargeInteger;
}


/*	Convert the given object into an integer value.
	The object may be either a positive ST integer or a four-byte LargePositiveInteger. */

int positive32BitValueOf(int oop) {
register struct foo * foo = &fum;
    int sz;
    int value;
    int header;
    int sz1;
    int cl;
    int ccIndex;

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
	ccIndex = (((unsigned) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(oop - 4)) & AllButTypeMask;
	} else {
		cl = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargePositiveInteger << 2)))) && foo->successFlag;
l2:	/* end assertClassOf:is: */;
	if (foo->successFlag) {
		/* begin lengthOf: */
		header = longAt(oop);
		/* begin lengthOf:baseHeader:format: */
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz1 = (longAt(oop - 8)) & AllButTypeMask;
		} else {
			sz1 = header & SizeMask;
		}
		if (((((unsigned) header) >> 8) & 15) < 8) {
			sz = ((unsigned) (sz1 - BaseHeaderSize)) >> 2;
			goto l1;
		} else {
			sz = (sz1 - BaseHeaderSize) - (((((unsigned) header) >> 8) & 15) & 3);
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
		return (((byteAt(((((char *) oop)) + BaseHeaderSize) + 0)) + ((byteAt(((((char *) oop)) + BaseHeaderSize) + 1)) << 8)) + ((byteAt(((((char *) oop)) + BaseHeaderSize) + 2)) << 16)) + ((byteAt(((((char *) oop)) + BaseHeaderSize) + 3)) << 24);
	}
}


/*	Note - integerValue is interpreted as POSITIVE, eg, as the result of
		Bitmap>at:, or integer>bitAnd:. */

int positive64BitIntegerFor(squeakInt64 integerValue) {
    int value;
    int i;
    int newLargeInteger;
    int check;

	if ((sizeof(integerValue)) == 4) {
		return positive32BitIntegerFor(integerValue);
	}
	check = integerValue >> 32;
	if (check == 0) {
		return positive32BitIntegerFor(integerValue);
	}
	newLargeInteger = instantiateSmallClasssizeInBytesfill(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargePositiveInteger << 2)), 12, 0);
	for (i = 0; i <= 7; i += 1) {
		value = ( integerValue >> (i * 8)) & 255;
		byteAtput(((((char *) newLargeInteger)) + BaseHeaderSize) + i, value);
	}
	return newLargeInteger;
}


/*	Convert the given object into an integer value.
	The object may be either a positive ST integer or a eight-byte LargePositiveInteger. */

squeakInt64 positive64BitValueOf(int oop) {
register struct foo * foo = &fum;
    int szsqueakInt64;
    int sz;
    squeakInt64 value;
    int i;
    int cl;
    int ccIndex;
    int header;
    int sz1;

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
	ccIndex = (((unsigned) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(oop - 4)) & AllButTypeMask;
	} else {
		cl = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargePositiveInteger << 2)))) && foo->successFlag;
l1:	/* end assertClassOf:is: */;
	if (!(foo->successFlag)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	szsqueakInt64 = sizeof(squeakInt64);
	/* begin lengthOf: */
	header = longAt(oop);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(oop - 8)) & AllButTypeMask;
	} else {
		sz1 = header & SizeMask;
	}
	if (((((unsigned) header) >> 8) & 15) < 8) {
		sz = ((unsigned) (sz1 - BaseHeaderSize)) >> 2;
		goto l2;
	} else {
		sz = (sz1 - BaseHeaderSize) - (((((unsigned) header) >> 8) & 15) & 3);
		goto l2;
	}
	sz = null;
l2:	/* end lengthOf: */;
	if (sz > szsqueakInt64) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	value = 0;
	for (i = 0; i <= (sz - 1); i += 1) {
		value += (((squeakInt64) (byteAt(((((char *) oop)) + BaseHeaderSize) + i)))) << (i * 8);
	}
	return value;
}


/*	oop is an old object.  If valueObj is young, mark the object as a root. */

int possibleRootStoreIntovalue(int oop, int valueObj) {
register struct foo * foo = &fum;
    int header;

	if ((valueObj >= foo->youngStart) && (!((valueObj & 1)))) {
		/* begin noteAsRoot:headerLoc: */
		header = longAt(oop);
		if ((header & RootBit) == 0) {
			if (foo->rootTableCount < RootTableRedZone) {
				foo->rootTableCount += 1;
				rootTable[foo->rootTableCount] = oop;
				longAtput(oop, header | RootBit);
			} else {
				if (foo->rootTableCount < RootTableSize) {
					foo->rootTableCount += 1;
					rootTable[foo->rootTableCount] = oop;
					longAtput(oop, header | RootBit);
					foo->allocationCount = foo->allocationsBetweenGCs + 1;
				}
			}
		}
	}
}


/*	Ensure that there are enough forwarding blocks to 
	accomodate this become, then prepare forwarding blocks for 
	the pointer swap. Return true if successful. */
/*	Details: Doing a GC might generate enough space for 
	forwarding blocks if we're short. However, this is an 
	uncommon enough case that it is better handled by primitive 
	fail code at the Smalltalk level. */

int prepareForwardingTableForBecomingwithtwoWay(int array1, int array2, int twoWayFlag) {
register struct foo * foo = &fum;
    int entriesNeeded;
    int oop2;
    int fwdBlock;
    int entriesAvailable;
    int fwdBlkSize;
    int fieldOffset;
    int oop1;
    int originalHeaderType;
    int originalHeader;
    int originalHeaderType1;
    int originalHeader1;
    int fmt;
    int sz;
    int methodHeader;
    int contextSize;
    int header;
    int sp;
    int header1;
    int type;


	/* need enough entries for all oops */

	entriesNeeded = ((int) (lastPointerOf(array1)) >> 2);
	if (twoWayFlag) {
		entriesNeeded = entriesNeeded * 2;

		/* Note: Forward blocks must be quadword aligned. */

		fwdBlkSize = 8;
	} else {

		/* Note: Forward blocks must be quadword aligned. */

		fwdBlkSize = 16;
	}
	entriesAvailable = fwdTableInit(fwdBlkSize);
	if (entriesAvailable < entriesNeeded) {
		initializeMemoryFirstFree(foo->freeBlock);
		return 0;
	}
	/* begin lastPointerOf: */
	header = longAt(array1);
	fmt = (((unsigned) header) >> 8) & 15;
	if (fmt <= 4) {
		if ((fmt == 3) && ((((((unsigned) header) >> 12) & 31) == 13) || ((((((unsigned) header) >> 12) & 31) == 14) || (((((unsigned) header) >> 12) & 31) == 4)))) {
			/* begin fetchStackPointerOf: */
			sp = longAt(((((char *) array1)) + BaseHeaderSize) + (StackPointerIndex << 2));
			if (!((sp & 1))) {
				contextSize = 0;
				goto l4;
			}
			contextSize = (sp >> 1);
		l4:	/* end fetchStackPointerOf: */;
			fieldOffset = (CtxtTempFrameStart + contextSize) * 4;
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
			sz = (longAt(array1 - 8)) & AllButTypeMask;
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
	fieldOffset = (((((unsigned) methodHeader) >> 10) & 255) * 4) + BaseHeaderSize;
l6:	/* end lastPointerOf: */;
	while (fieldOffset >= BaseHeaderSize) {
		oop1 = longAt(array1 + fieldOffset);
		oop2 = longAt(array2 + fieldOffset);
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
		longAtput(fwdBlock + 4, originalHeader1);
		if (!twoWayFlag) {
			longAtput(fwdBlock + 8, oop1);
		}
		longAtput(oop1, (((unsigned) fwdBlock) >> 1) | (MarkBit | originalHeaderType1));
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
			longAtput(fwdBlock + 4, originalHeader);
			if (!twoWayFlag) {
				longAtput(fwdBlock + 8, oop2);
			}
			longAtput(oop2, (((unsigned) fwdBlock) >> 1) | (MarkBit | originalHeaderType));
		}
		fieldOffset -= 4;
	}
	return 1;
}

int primitiveAdd(void) {
register struct foo * foo = &fum;
    int integerResult;
    int sp;

	/* begin pop2AndPushIntegerIfOK: */
	integerResult = (stackIntegerValue(1)) + (stackIntegerValue(0));
	if (foo->successFlag) {
		if ((integerResult ^ (integerResult << 1)) >= 0) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - ((2 - 1) * 4), ((integerResult << 1) | 1));
			foo->stackPointer = sp;
		} else {
			foo->successFlag = 0;
		}
	}
}

int primitiveArctan(void) {
register struct foo * foo = &fum;
    double rcvr;

	rcvr = popFloat();
	if (foo->successFlag) {
		pushFloat(atan(rcvr));
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * 4;
	}
}


/*	We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors. */

int primitiveArrayBecome(void) {
register struct foo * foo = &fum;
    int rcvr;
    int arg;
    int successValue;

	arg = longAt(foo->stackPointer);
	rcvr = longAt(foo->stackPointer - (1 * 4));
	/* begin success: */
	successValue = becomewithtwoWaycopyHash(rcvr, arg, 1, 1);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 1 * 4;
	}
}


/*	We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors. */

int primitiveArrayBecomeOneWay(void) {
register struct foo * foo = &fum;
    int rcvr;
    int arg;
    int successValue;

	arg = longAt(foo->stackPointer);
	rcvr = longAt(foo->stackPointer - (1 * 4));
	/* begin success: */
	successValue = becomewithtwoWaycopyHash(rcvr, arg, 0, 1);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 1 * 4;
	}
}


/*	Similar to primitiveArrayBecomeOneWay but accepts a third argument whether to copy
	the receiver's identity hash over the argument's identity hash. */

int primitiveArrayBecomeOneWayCopyHash(void) {
register struct foo * foo = &fum;
    int copyHashFlag;
    int rcvr;
    int arg;
    int successValue;

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
	arg = longAt(foo->stackPointer - (1 * 4));
	rcvr = longAt(foo->stackPointer - (2 * 4));
	/* begin success: */
	successValue = becomewithtwoWaycopyHash(rcvr, arg, 0, copyHashFlag);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
	}
}

int primitiveAsFloat(void) {
register struct foo * foo = &fum;
    int arg;
    int integerPointer;
    int top;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
		foo->stackPointer += 1 * 4;
	}
}

int primitiveAsOop(void) {
register struct foo * foo = &fum;
    int thisReceiver;
    int sp;
    int top;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	thisReceiver = top;
	/* begin success: */
	foo->successFlag = (!((thisReceiver & 1))) && foo->successFlag;
	if (foo->successFlag) {
		/* begin pushInteger: */
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, ((((((unsigned) (longAt(thisReceiver))) >> 17) & 4095) << 1) | 1));
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * 4;
	}
}

int primitiveAt(void) {
	commonAt(0);
}

int primitiveAtEnd(void) {
register struct foo * foo = &fum;
    int stream;
    int index;
    int limit;
    int sp;
    int sp1;
    int top;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	stream = top;
	foo->successFlag = (((stream & 1) == 0) && (((((unsigned) (longAt(stream))) >> 8) & 15) <= 4)) && ((lengthOf(stream)) >= (StreamReadLimitIndex + 1));
	if (foo->successFlag) {
		index = fetchIntegerofObject(StreamIndexIndex, stream);
		limit = fetchIntegerofObject(StreamReadLimitIndex, stream);
	}
	if (foo->successFlag) {
		/* begin pushBool: */
		if (index >= limit) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * 4;
	}
}

int primitiveAtPut(void) {
	commonAtPut(0);
}


/*	Set the cursor to the given shape. The Mac only supports 16x16 pixel cursors. Cursor offsets are handled by Smalltalk. */

int primitiveBeCursor(void) {
register struct foo * foo = &fum;
    int offsetY;
    int extentX;
    int offsetObj;
    int bitsObj;
    int maskBitsIndex;
    int offsetX;
    int cursorBitsIndex;
    int cursorObj;
    int extentY;
    int ourCursor;
    int i;
    int maskObj;
    int depth;
    int successValue;
    int successValue1;
    int successValue2;
    int successValue3;
    int successValue4;
    int successValue5;
    int successValue6;
    int successValue7;
    int successValue8;

	if (foo->argumentCount == 0) {
		cursorObj = longAt(foo->stackPointer);
		maskBitsIndex = null;
	}
	if (foo->argumentCount == 1) {
		cursorObj = longAt(foo->stackPointer - (1 * 4));
		maskObj = longAt(foo->stackPointer);
	}
	/* begin success: */
	foo->successFlag = (foo->argumentCount < 2) && foo->successFlag;
	/* begin success: */
	successValue7 = (((cursorObj & 1) == 0) && (((((unsigned) (longAt(cursorObj))) >> 8) & 15) <= 4)) && ((lengthOf(cursorObj)) >= 5);
	foo->successFlag = successValue7 && foo->successFlag;
	if (foo->successFlag) {
		bitsObj = longAt(((((char *) cursorObj)) + BaseHeaderSize) + (0 << 2));
		extentX = fetchIntegerofObject(1, cursorObj);
		extentY = fetchIntegerofObject(2, cursorObj);
		depth = fetchIntegerofObject(3, cursorObj);
		offsetObj = longAt(((((char *) cursorObj)) + BaseHeaderSize) + (4 << 2));
	}
	/* begin success: */
	successValue8 = (((offsetObj & 1) == 0) && (((((unsigned) (longAt(offsetObj))) >> 8) & 15) <= 4)) && ((lengthOf(offsetObj)) >= 2);
	foo->successFlag = successValue8 && foo->successFlag;
	if (foo->successFlag) {
		offsetX = fetchIntegerofObject(0, offsetObj);
		offsetY = fetchIntegerofObject(1, offsetObj);
		/* begin success: */
		successValue = (extentX == 16) && ((extentY == 16) && (depth == 1));
		foo->successFlag = successValue && foo->successFlag;
		/* begin success: */
		successValue1 = (offsetX >= -16) && (offsetX <= 0);
		foo->successFlag = successValue1 && foo->successFlag;
		/* begin success: */
		successValue2 = (offsetY >= -16) && (offsetY <= 0);
		foo->successFlag = successValue2 && foo->successFlag;
		/* begin success: */
		successValue3 = (((bitsObj & 1) == 0) && (((((unsigned) (longAt(bitsObj))) >> 8) & 15) == 6)) && ((lengthOf(bitsObj)) == 16);
		foo->successFlag = successValue3 && foo->successFlag;
		cursorBitsIndex = bitsObj + BaseHeaderSize;
		;
	}
	if (foo->argumentCount == 1) {
		/* begin success: */
		successValue6 = (((maskObj & 1) == 0) && (((((unsigned) (longAt(maskObj))) >> 8) & 15) <= 4)) && ((lengthOf(maskObj)) >= 5);
		foo->successFlag = successValue6 && foo->successFlag;
		if (foo->successFlag) {
			bitsObj = longAt(((((char *) maskObj)) + BaseHeaderSize) + (0 << 2));
			extentX = fetchIntegerofObject(1, maskObj);
			extentY = fetchIntegerofObject(2, maskObj);
			depth = fetchIntegerofObject(3, maskObj);
		}
		if (foo->successFlag) {
			/* begin success: */
			successValue4 = (extentX == 16) && ((extentY == 16) && (depth == 1));
			foo->successFlag = successValue4 && foo->successFlag;
			/* begin success: */
			successValue5 = (((bitsObj & 1) == 0) && (((((unsigned) (longAt(bitsObj))) >> 8) & 15) == 6)) && ((lengthOf(bitsObj)) == 16);
			foo->successFlag = successValue5 && foo->successFlag;
			maskBitsIndex = bitsObj + BaseHeaderSize;
		}
	}
	if (foo->successFlag) {
		if (foo->argumentCount == 0) {
			ioSetCursor(cursorBitsIndex, offsetX, offsetY);
		} else {
			ioSetCursorWithMask(cursorBitsIndex, maskBitsIndex, offsetX, offsetY);
		}
		/* begin pop: */
		foo->stackPointer -= foo->argumentCount * 4;
	}
}


/*	Record the system Display object in the specialObjectsTable. */

int primitiveBeDisplay(void) {
register struct foo * foo = &fum;
    int rcvr;
    int oop;
    int successValue;

	rcvr = longAt(foo->stackPointer);
	/* begin success: */
	successValue = (((rcvr & 1) == 0) && (((((unsigned) (longAt(rcvr))) >> 8) & 15) <= 4)) && ((lengthOf(rcvr)) >= 4);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		/* begin storePointer:ofObject:withValue: */
		oop = foo->specialObjectsOop;
		if (oop < foo->youngStart) {
			possibleRootStoreIntovalue(oop, rcvr);
		}
		longAtput(((((char *) oop)) + BaseHeaderSize) + (TheDisplay << 2), rcvr);
	}
}


/*	make the basic beep noise */

int primitiveBeep(void) {
	ioBeep();
}

int primitiveBitAnd(void) {
register struct foo * foo = &fum;
    int integerArgument;
    int integerReceiver;
    int object;
    int sp;
    int top;
    int top1;
    int top2;
    int top11;

	/* begin popPos32BitInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	top = top1;
	integerArgument = positive32BitValueOf(top);
	/* begin popPos32BitInteger */
	/* begin popStack */
	top11 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	top2 = top11;
	integerReceiver = positive32BitValueOf(top2);
	if (foo->successFlag) {
		/* begin push: */
		object = positive32BitIntegerFor(integerReceiver & integerArgument);
		longAtput(sp = foo->stackPointer + 4, object);
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}

int primitiveBitOr(void) {
register struct foo * foo = &fum;
    int integerArgument;
    int integerReceiver;
    int object;
    int sp;
    int top;
    int top1;
    int top2;
    int top11;

	/* begin popPos32BitInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	top = top1;
	integerArgument = positive32BitValueOf(top);
	/* begin popPos32BitInteger */
	/* begin popStack */
	top11 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	top2 = top11;
	integerReceiver = positive32BitValueOf(top2);
	if (foo->successFlag) {
		/* begin push: */
		object = positive32BitIntegerFor(integerReceiver | integerArgument);
		longAtput(sp = foo->stackPointer + 4, object);
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}

int primitiveBitShift(void) {
register struct foo * foo = &fum;
    int integerArgument;
    int shifted;
    int integerReceiver;
    int integerPointer;
    int object;
    int sp;
    int top;
    int top2;
    int top1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
	foo->stackPointer -= 4;
	top2 = top1;
	integerReceiver = positive32BitValueOf(top2);
	if (foo->successFlag) {
		if (integerArgument >= 0) {
			/* begin success: */
			foo->successFlag = (integerArgument <= 31) && foo->successFlag;
			shifted = integerReceiver << integerArgument;
			/* begin success: */
			foo->successFlag = ((((unsigned) shifted) >> integerArgument) == integerReceiver) && foo->successFlag;
		} else {
			/* begin success: */
			foo->successFlag = (integerArgument >= -31) && foo->successFlag;
			shifted = ((integerArgument < 0) ? ((unsigned) integerReceiver >> -integerArgument) : ((unsigned) integerReceiver << integerArgument));
		}
	}
	if (foo->successFlag) {
		/* begin push: */
		object = positive32BitIntegerFor(shifted);
		longAtput(sp = foo->stackPointer + 4, object);
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}

int primitiveBitXor(void) {
register struct foo * foo = &fum;
    int integerArgument;
    int integerReceiver;
    int object;
    int sp;
    int top;
    int top1;
    int top2;
    int top11;

	/* begin popPos32BitInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	top = top1;
	integerArgument = positive32BitValueOf(top);
	/* begin popPos32BitInteger */
	/* begin popStack */
	top11 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	top2 = top11;
	integerReceiver = positive32BitValueOf(top2);
	if (foo->successFlag) {
		/* begin push: */
		object = positive32BitIntegerFor(integerReceiver ^ integerArgument);
		longAtput(sp = foo->stackPointer + 4, object);
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}

int primitiveBlockCopy(void) {
register struct foo * foo = &fum;
    int initialIP;
    int context;
    int newContext;
    int methodContext;
    int contextSize;
    int header;
    int oop;
    int sp;

	context = longAt(foo->stackPointer - (1 * 4));
	if (((longAt(((((char *) context)) + BaseHeaderSize) + (MethodIndex << 2))) & 1)) {
		methodContext = longAt(((((char *) context)) + BaseHeaderSize) + (HomeIndex << 2));
	} else {
		methodContext = context;
	}
	/* begin sizeBitsOf: */
	header = longAt(methodContext);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		contextSize = (longAt(methodContext - 8)) & AllButTypeMask;
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
	remapBuffer[foo->remapBufferCount += 1] = methodContext;
	newContext = instantiateContextsizeInBytes(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassBlockContext << 2)), contextSize);
	/* begin popRemappableOop */
	oop = remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	methodContext = oop;

	/* Was instructionPointer + 3, but now it's greater by 
		methodOop + 4 (headerSize) and less by 1 due to preIncrement */
	/* Assume: have just allocated a new context; it must be young.
	 Thus, can use uncheck stores. See the comment in fetchContextRegisters. */

	initialIP = (((foo->instructionPointer - foo->method) << 1) | 1);
	longAtput(((((char *) newContext)) + BaseHeaderSize) + (InitialIPIndex << 2), initialIP);
	longAtput(((((char *) newContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), initialIP);
	/* begin storeStackPointerValue:inContext: */
	longAtput(((((char *) newContext)) + BaseHeaderSize) + (StackPointerIndex << 2), ((0 << 1) | 1));
	longAtput(((((char *) newContext)) + BaseHeaderSize) + (BlockArgumentCountIndex << 2), longAt(foo->stackPointer - (0 * 4)));
	longAtput(((((char *) newContext)) + BaseHeaderSize) + (HomeIndex << 2), methodContext);
	longAtput(((((char *) newContext)) + BaseHeaderSize) + (SenderIndex << 2), foo->nilObj);
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((2 - 1) * 4), newContext);
	foo->stackPointer = sp;
}


/*	Reports bytes available at this moment. For more meaningful 
	results, calls to this primitive should be preceeded by a full 
	or incremental garbage collection. */

int primitiveBytesLeft(void) {
register struct foo * foo = &fum;
    int aBool;
    int sp;
    int integerValue;
    int sp1;

	if (foo->argumentCount == 0) {
		/* begin pop: */
		foo->stackPointer -= 1 * 4;
		/* begin pushInteger: */
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, ((((longAt(foo->freeBlock)) & AllButTypeMask) << 1) | 1));
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
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
		/* begin pushInteger: */
		integerValue = ((longAt(foo->freeBlock)) & AllButTypeMask) + (sqMemoryExtraBytesLeft(aBool));
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + 4, ((integerValue << 1) | 1));
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

int primitiveCalloutToFFI(void) {
register struct foo * foo = &fum;
    static int function = 0;
    static char *functionName = "primitiveCallout";
    static char *moduleName = "SqueakFFIPrims";

	if (function == 0) {
		function = ioLoadExternalFunctionOfLengthFromModuleOfLength(((int) functionName), 16, ((int) moduleName), 14);
		if (function == 0) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	((int (*) (void)) function) ();
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
}


/*	Primitive. Change the class of the receiver into the class of the argument given that the format of the receiver matches the format of the argument's class. Fail if receiver or argument are SmallIntegers, or the receiver is an instance of a compact class and the argument isn't, or when the argument's class is compact and the receiver isn't, or when the format of the receiver is different from the format of the argument's class, or when the arguments class is fixed and the receiver's size differs from the size that an instance of the argument's class should have. */

int primitiveChangeClass(void) {
register struct foo * foo = &fum;
    int argClass;
    int argFormat;
    int rcvrFormat;
    int classHdr;
    int rcvr;
    int byteSize;
    int ccIndex;
    int sizeHiBits;
    int arg;
    int oop;
    int oop1;
    int i;
    int ccIndex1;

	/* begin stackObjectValue: */
	oop = longAt(foo->stackPointer - (0 * 4));
	if ((oop & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		arg = null;
		goto l1;
	}
	arg = oop;
l1:	/* end stackObjectValue: */;
	/* begin stackObjectValue: */
	oop1 = longAt(foo->stackPointer - (1 * 4));
	if ((oop1 & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		rcvr = null;
		goto l2;
	}
	rcvr = oop1;
l2:	/* end stackObjectValue: */;
	if (!(foo->successFlag)) {
		return null;
	}
	/* begin fetchClassOf: */
	if ((arg & 1)) {
		argClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l3;
	}
	ccIndex1 = (((unsigned) (longAt(arg))) >> 12) & 31;
	if (ccIndex1 == 0) {
		argClass = (longAt(arg - 4)) & AllButTypeMask;
		goto l3;
	} else {
		argClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex1 - 1) << 2));
		goto l3;
	}
l3:	/* end fetchClassOf: */;

	/* Low 2 bits are 0 */
	/* Compute the size of instances of the class (used for fixed field classes only) */

	classHdr = (longAt(((((char *) argClass)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1;
	sizeHiBits = ((unsigned) (classHdr & 393216)) >> 9;
	classHdr = classHdr & 131071;

	/* size in bytes -- low 2 bits are 0 */
	/* Check the receiver's format against that of the class */

	byteSize = (classHdr & SizeMask) + sizeHiBits;
	argFormat = (((unsigned) classHdr) >> 8) & 15;
	rcvrFormat = (((unsigned) (longAt(rcvr))) >> 8) & 15;
	if (!(argFormat == rcvrFormat)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (argFormat < 2) {
		if (!((byteSize - 4) == (byteSizeOf(rcvr)))) {
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
		longAtput(rcvr - 4, argClass | ((longAt(rcvr)) & TypeMask));
		if (rcvr < foo->youngStart) {
			possibleRootStoreIntovalue(rcvr, argClass);
		}
	}
	/* begin flushMethodCache */
	for (i = 1; i <= MethodCacheSize; i += 1) {
		methodCache[i] = 0;
	}
	for (i = 1; i <= AtCacheTotalSize; i += 1) {
		atCache[i] = 0;
	}
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 1 * 4;
	}
}

int primitiveClass(void) {
register struct foo * foo = &fum;
    int instance;
    int oop;
    int sp;
    int ccIndex;

	instance = longAt(foo->stackPointer);
	/* begin pop:thenPush: */
	/* begin fetchClassOf: */
	if ((instance & 1)) {
		oop = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(instance))) >> 12) & 31;
	if (ccIndex == 0) {
		oop = (longAt(instance - 4)) & AllButTypeMask;
		goto l1;
	} else {
		oop = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * 4), oop);
	foo->stackPointer = sp;
}


/*	When called with a single string argument, post the string to 
	the clipboard. When called with zero arguments, return a 
	string containing the current clipboard contents. */

int primitiveClipboardText(void) {
register struct foo * foo = &fum;
    int sz;
    int s;
    int sp;

	if (foo->argumentCount == 1) {
		s = longAt(foo->stackPointer);
		if (!(((s & 1) == 0) && (((((unsigned) (longAt(s))) >> 8) & 15) >= 8))) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
		if (foo->successFlag) {
			sz = stSizeOf(s);
			clipboardWriteFromAt(sz, s + BaseHeaderSize, 0);
			/* begin pop: */
			foo->stackPointer -= 1 * 4;
		}
	} else {
		sz = clipboardSize();
		s = instantiateClassindexableSize(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassString << 2)), sz);
		clipboardReadIntoAt(sz, s + BaseHeaderSize, 0);
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((1 - 1) * 4), s);
		foo->stackPointer = sp;
	}
}


/*	Return a shallow copy of the receiver. */

int primitiveClone(void) {
register struct foo * foo = &fum;
    int newCopy;
    int sp;

	newCopy = clone(longAt(foo->stackPointer));
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((1 - 1) * 4), newCopy);
	foo->stackPointer = sp;
}

int primitiveClosureValue(void) {
register struct foo * foo = &fum;
    int blockClosure;
    int primIdx;
    int nArgs;
    int delta;
    int primBits;
    int initialIP;
    int tempCount;
    int newContext;
    int where;
    int i;
    int methodHeader;
    int nilOop;
    int tmp;

	blockClosure = longAt(foo->stackPointer - (foo->argumentCount * 4));
	foo->newMethod = longAt(((((char *) blockClosure)) + BaseHeaderSize) + (BlockMethodIndex << 2));
	/* begin primitiveIndexOf: */
	primBits = (((unsigned) (longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 1) & 268435967;
	foo->primitiveIndex = (primBits & 511) + (((unsigned) primBits) >> 19);
	/* begin success: */
	foo->successFlag = (foo->argumentCount == ((((unsigned) (longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 25) & 15)) && foo->successFlag;
	if (foo->successFlag) {
		/* begin executeNewMethod */
		if (foo->primitiveIndex > 0) {
			/* begin primitiveResponse */
			if (DoBalanceChecks) {
				nArgs = foo->argumentCount;
				delta = foo->stackPointer - foo->activeContext;
			}
			primIdx = foo->primitiveIndex;
			foo->successFlag = 1;
			dispatchFunctionPointerOnin(primIdx, primitiveTable);
			if (DoBalanceChecks) {
				if (!(balancedStackafterPrimitivewithArgs(delta, primIdx, nArgs))) {
					printUnbalancedStack(primIdx);
				}
			}
			if (foo->successFlag) {
				goto l1;
			}
		}
		/* begin activateNewMethod */
		methodHeader = longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2));
		newContext = allocateOrRecycleContext(methodHeader & LargeContextBit);
		initialIP = ((LiteralStart + ((((unsigned) methodHeader) >> 10) & 255)) * 4) + 1;
		tempCount = (((unsigned) methodHeader) >> 19) & 63;
		where = newContext + BaseHeaderSize;
		longAtput(where + (SenderIndex << 2), foo->activeContext);
		longAtput(where + (InstructionPointerIndex << 2), ((initialIP << 1) | 1));
		longAtput(where + (StackPointerIndex << 2), ((tempCount << 1) | 1));
		longAtput(where + (MethodIndex << 2), foo->newMethod);
		for (i = 0; i <= foo->argumentCount; i += 1) {
			longAtput(where + ((ReceiverIndex + i) << 2), longAt(foo->stackPointer - ((foo->argumentCount - i) * 4)));
		}
		nilOop = foo->nilObj;
		for (i = ((foo->argumentCount + 1) + ReceiverIndex); i <= (tempCount + ReceiverIndex); i += 1) {
			longAtput(where + (i << 2), nilOop);
		}
		/* begin pop: */
		foo->stackPointer -= (foo->argumentCount + 1) * 4;
		foo->reclaimableContextCount += 1;
		/* begin newActiveContext: */
		/* begin storeContextRegisters: */
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (StackPointerIndex << 2), (((((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - TempFrameStart) + 1) << 1) | 1));
		if (newContext < foo->youngStart) {
			beRootIfOld(newContext);
		}
		foo->activeContext = newContext;
		/* begin fetchContextRegisters: */
		tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (MethodIndex << 2));
		if ((tmp & 1)) {
			tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (HomeIndex << 2));
			if (tmp < foo->youngStart) {
				beRootIfOld(tmp);
			}
		} else {
			tmp = newContext;
		}
		foo->theHomeContext = tmp;
		foo->receiver = longAt(((((char *) tmp)) + BaseHeaderSize) + (ReceiverIndex << 2));
		foo->method = longAt(((((char *) tmp)) + BaseHeaderSize) + (MethodIndex << 2));
		tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2))) >> 1);
		foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
		tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (StackPointerIndex << 2))) >> 1);
		foo->stackPointer = (newContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * 4);
		/* begin quickCheckForInterrupts */
		if ((foo->interruptCheckCounter -= 1) <= 0) {
			checkForInterrupts();
		}
	l1:	/* end executeNewMethod */;
	}
}

int primitiveClosureValueWithArgs(void) {
register struct foo * foo = &fum;
    int blockClosure;
    int sp;
    int argCnt;
    int argumentArray;
    int successValue;
    int out;
    int lastIn;
    int in;
    int primIdx;
    int nArgs;
    int delta;
    int top;
    int primBits;
    int top1;
    int initialIP;
    int tempCount;
    int newContext;
    int where;
    int i;
    int methodHeader;
    int nilOop;
    int tmp;

	blockClosure = longAt(foo->stackPointer - (1 * 4));
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, longAt(((((char *) blockClosure)) + BaseHeaderSize) + (BlockMethodIndex << 2)));
	foo->stackPointer = sp;
	/* begin primitiveExecuteMethod */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	foo->newMethod = top;
	/* begin primitiveIndexOf: */
	primBits = (((unsigned) (longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 1) & 268435967;
	foo->primitiveIndex = (primBits & 511) + (((unsigned) primBits) >> 19);
	argCnt = (((unsigned) (longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 25) & 15;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	argumentArray = top1;
	if (!(((argumentArray & 1) == 0) && (((((unsigned) (longAt(argumentArray))) >> 8) & 15) == 2))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		goto l2;
	}
	if (foo->successFlag) {
		/* begin success: */
		successValue = argCnt == (fetchWordLengthOf(argumentArray));
		foo->successFlag = successValue && foo->successFlag;
	}
	if (foo->successFlag) {
		/* begin transfer:from:to: */
		in = (argumentArray + BaseHeaderSize) - 4;
		lastIn = in + (argCnt * 4);
		out = (foo->stackPointer + 4) - 4;
		while (in < lastIn) {
			longAtput(out += 4, longAt(in += 4));
		}
		/* begin unPop: */
		foo->stackPointer += argCnt * 4;
		foo->argumentCount = argCnt;
		/* begin executeNewMethod */
		if (foo->primitiveIndex > 0) {
			/* begin primitiveResponse */
			if (DoBalanceChecks) {
				nArgs = foo->argumentCount;
				delta = foo->stackPointer - foo->activeContext;
			}
			primIdx = foo->primitiveIndex;
			foo->successFlag = 1;
			dispatchFunctionPointerOnin(primIdx, primitiveTable);
			if (DoBalanceChecks) {
				if (!(balancedStackafterPrimitivewithArgs(delta, primIdx, nArgs))) {
					printUnbalancedStack(primIdx);
				}
			}
			if (foo->successFlag) {
				goto l1;
			}
		}
		/* begin activateNewMethod */
		methodHeader = longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2));
		newContext = allocateOrRecycleContext(methodHeader & LargeContextBit);
		initialIP = ((LiteralStart + ((((unsigned) methodHeader) >> 10) & 255)) * 4) + 1;
		tempCount = (((unsigned) methodHeader) >> 19) & 63;
		where = newContext + BaseHeaderSize;
		longAtput(where + (SenderIndex << 2), foo->activeContext);
		longAtput(where + (InstructionPointerIndex << 2), ((initialIP << 1) | 1));
		longAtput(where + (StackPointerIndex << 2), ((tempCount << 1) | 1));
		longAtput(where + (MethodIndex << 2), foo->newMethod);
		for (i = 0; i <= foo->argumentCount; i += 1) {
			longAtput(where + ((ReceiverIndex + i) << 2), longAt(foo->stackPointer - ((foo->argumentCount - i) * 4)));
		}
		nilOop = foo->nilObj;
		for (i = ((foo->argumentCount + 1) + ReceiverIndex); i <= (tempCount + ReceiverIndex); i += 1) {
			longAtput(where + (i << 2), nilOop);
		}
		/* begin pop: */
		foo->stackPointer -= (foo->argumentCount + 1) * 4;
		foo->reclaimableContextCount += 1;
		/* begin newActiveContext: */
		/* begin storeContextRegisters: */
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (StackPointerIndex << 2), (((((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - TempFrameStart) + 1) << 1) | 1));
		if (newContext < foo->youngStart) {
			beRootIfOld(newContext);
		}
		foo->activeContext = newContext;
		/* begin fetchContextRegisters: */
		tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (MethodIndex << 2));
		if ((tmp & 1)) {
			tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (HomeIndex << 2));
			if (tmp < foo->youngStart) {
				beRootIfOld(tmp);
			}
		} else {
			tmp = newContext;
		}
		foo->theHomeContext = tmp;
		foo->receiver = longAt(((((char *) tmp)) + BaseHeaderSize) + (ReceiverIndex << 2));
		foo->method = longAt(((((char *) tmp)) + BaseHeaderSize) + (MethodIndex << 2));
		tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2))) >> 1);
		foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
		tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (StackPointerIndex << 2))) >> 1);
		foo->stackPointer = (newContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * 4);
		/* begin quickCheckForInterrupts */
		if ((foo->interruptCheckCounter -= 1) <= 0) {
			checkForInterrupts();
		}
	l1:	/* end executeNewMethod */;
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
l2:	/* end primitiveExecuteMethod */;
	if (!(foo->successFlag)) {
		/* begin pop: */
		foo->stackPointer -= 1 * 4;
	}
}


/*	Fill the receiver, which must be an indexable bytes or words 
	objects, with the given integer value. */

int primitiveConstantFill(void) {
register struct foo * foo = &fum;
    int fillValue;
    int end;
    int rcvr;
    int rcvrIsBytes;
    int i;
    int successValue;
    int successValue1;

	fillValue = positive32BitValueOf(longAt(foo->stackPointer));
	rcvr = longAt(foo->stackPointer - (1 * 4));
	/* begin success: */
	successValue1 = ((rcvr & 1) == 0) && (isWordsOrBytesNonInt(rcvr));
	foo->successFlag = successValue1 && foo->successFlag;
	rcvrIsBytes = ((rcvr & 1) == 0) && (((((unsigned) (longAt(rcvr))) >> 8) & 15) >= 8);
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
				longAtput(i, fillValue);
				i += 4;
			}
		}
		/* begin pop: */
		foo->stackPointer -= 1 * 4;
	}
}


/*	Primitive. Copy the state of the receiver from the argument. 
		Fail if receiver and argument are of a different class. 
		Fail if the receiver or argument are non-pointer objects.
		Fail if receiver and argument have different lengths (for indexable objects).
	 */

int primitiveCopyObject(void) {
register struct foo * foo = &fum;
    int length;
    int rcvr;
    int i;
    int arg;
    int oop;
    int oop1;
    int header;
    int sz;

	if (!(foo->argumentCount == 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackObjectValue: */
	oop = longAt(foo->stackPointer - (0 * 4));
	if ((oop & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		arg = null;
		goto l1;
	}
	arg = oop;
l1:	/* end stackObjectValue: */;
	/* begin stackObjectValue: */
	oop1 = longAt(foo->stackPointer - (1 * 4));
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
	if (!(((rcvr & 1) == 0) && (((((unsigned) (longAt(rcvr))) >> 8) & 15) <= 4))) {
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
		sz = (longAt(rcvr - 8)) & AllButTypeMask;
	} else {
		sz = header & SizeMask;
	}
	if (((((unsigned) header) >> 8) & 15) < 8) {
		length = ((unsigned) (sz - BaseHeaderSize)) >> 2;
		goto l3;
	} else {
		length = (sz - BaseHeaderSize) - (((((unsigned) header) >> 8) & 15) & 3);
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
		if (rcvr < foo->youngStart) {
			possibleRootStoreIntovalue(rcvr, longAt(((((char *) arg)) + BaseHeaderSize) + (i << 2)));
		}
		longAtput(((((char *) rcvr)) + BaseHeaderSize) + (i << 2), longAt(((((char *) arg)) + BaseHeaderSize) + (i << 2)));
	}
	/* begin pop: */
	foo->stackPointer -= 1 * 4;
}


/*	Set or clear the flag that controls whether modifications of 
	the Display object are propagated to the underlying 
	platform's screen. */

int primitiveDeferDisplayUpdates(void) {
register struct foo * foo = &fum;
    int flag;

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
		foo->stackPointer -= 1 * 4;
	}
}


/*	Pass in a non-negative value to disable the architectures powermanager if any, zero to enable */

EXPORT(int) primitiveDisablePowerManager(void) {
register struct foo * foo = &fum;
    int integer;
    int integerPointer;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * 4));
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
		foo->stackPointer -= 1 * 4;
	}
}

int primitiveDiv(void) {
register struct foo * foo = &fum;
    int quotient;
    int sp;

	quotient = doPrimitiveDivby(longAt(foo->stackPointer - (1 * 4)), longAt(foo->stackPointer));
	/* begin pop2AndPushIntegerIfOK: */
	if (foo->successFlag) {
		if ((quotient ^ (quotient << 1)) >= 0) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - ((2 - 1) * 4), ((quotient << 1) | 1));
			foo->stackPointer = sp;
		} else {
			foo->successFlag = 0;
		}
	}
}

int primitiveDivide(void) {
register struct foo * foo = &fum;
    int integerArgument;
    int integerReceiver;
    int integerPointer;
    int integerPointer1;
    int sp;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * 4));
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
	integerPointer1 = longAt(foo->stackPointer - (0 * 4));
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
			if (((integerReceiver / integerArgument) ^ ((integerReceiver / integerArgument) << 1)) >= 0) {
				/* begin pop:thenPush: */
				longAtput(sp = foo->stackPointer - ((2 - 1) * 4), (((integerReceiver / integerArgument) << 1) | 1));
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

int primitiveDoPrimitiveWithArgs(void) {
register struct foo * foo = &fum;
    int primIdx;
    int arraySize;
    int cntxSize;
    int argumentArray;
    int index;
    int sp;
    int sp1;
    int sp2;
    int sz;
    int objectPointer;
    int sz1;
    int integerPointer;
    int primIdx1;
    int nArgs;
    int delta;
    int oop;
    int header;
    int header1;

	argumentArray = longAt(foo->stackPointer);
	/* begin fetchWordLengthOf: */
	/* begin sizeBitsOf: */
	header = longAt(argumentArray);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(argumentArray - 8)) & AllButTypeMask;
		goto l2;
	} else {
		sz = header & SizeMask;
		goto l2;
	}
l2:	/* end sizeBitsOf: */;
	arraySize = ((unsigned) (sz - BaseHeaderSize)) >> 2;
	/* begin fetchWordLengthOf: */
	objectPointer = foo->activeContext;
	/* begin sizeBitsOf: */
	header1 = longAt(objectPointer);
	if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(objectPointer - 8)) & AllButTypeMask;
		goto l3;
	} else {
		sz1 = header1 & SizeMask;
		goto l3;
	}
l3:	/* end sizeBitsOf: */;
	cntxSize = ((unsigned) (sz1 - BaseHeaderSize)) >> 2;
	/* begin success: */
	foo->successFlag = (((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) + arraySize) < cntxSize) && foo->successFlag;
	if (!(((argumentArray & 1) == 0) && (((((unsigned) (longAt(argumentArray))) >> 8) & 15) == 2))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * 4));
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
	foo->stackPointer -= 2 * 4;
	foo->primitiveIndex = primIdx;
	foo->argumentCount = arraySize;
	index = 1;
	while (index <= foo->argumentCount) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, longAt(((((char *) argumentArray)) + BaseHeaderSize) + ((index - 1) << 2)));
		foo->stackPointer = sp;
		index += 1;
	}
	/* begin pushRemappableOop: */
	remapBuffer[foo->remapBufferCount += 1] = argumentArray;
	foo->lkupClass = foo->nilObj;
	/* begin primitiveResponse */
	if (DoBalanceChecks) {
		nArgs = foo->argumentCount;
		delta = foo->stackPointer - foo->activeContext;
	}
	primIdx1 = foo->primitiveIndex;
	foo->successFlag = 1;
	dispatchFunctionPointerOnin(primIdx1, primitiveTable);
	if (DoBalanceChecks) {
		if (!(balancedStackafterPrimitivewithArgs(delta, primIdx1, nArgs))) {
			printUnbalancedStack(primIdx1);
		}
	}
	/* begin popRemappableOop */
	oop = remapBuffer[foo->remapBufferCount];
	foo->remapBufferCount -= 1;
	argumentArray = oop;
	if (!(foo->successFlag)) {
		/* begin pop: */
		foo->stackPointer -= arraySize * 4;
		/* begin pushInteger: */
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + 4, ((primIdx << 1) | 1));
		foo->stackPointer = sp1;
		/* begin push: */
		longAtput(sp2 = foo->stackPointer + 4, argumentArray);
		foo->stackPointer = sp2;
		foo->argumentCount = 2;
	}
}

int primitiveEqual(void) {
register struct foo * foo = &fum;
    int result;
    int integerArgument;
    int integerReceiver;
    int top;
    int top1;
    int sp;
    int sp1;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	integerArgument = top;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}


/*	is the receiver the same object as the argument? */

int primitiveEquivalent(void) {
register struct foo * foo = &fum;
    int otherObject;
    int thisObject;
    int top;
    int top1;
    int sp;
    int sp1;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	otherObject = top;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	thisObject = top1;
	/* begin pushBool: */
	if (thisObject == otherObject) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, foo->trueObj);
		foo->stackPointer = sp;
	} else {
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
		foo->stackPointer = sp1;
	}
}


/*	receiver, argsArray, then method are on top of stack.  Execute method against receiver and args */

int primitiveExecuteMethod(void) {
register struct foo * foo = &fum;
    int argCnt;
    int argumentArray;
    int successValue;
    int out;
    int lastIn;
    int in;
    int primIdx;
    int nArgs;
    int delta;
    int top;
    int primBits;
    int top1;
    int initialIP;
    int tempCount;
    int newContext;
    int where;
    int i;
    int methodHeader;
    int nilOop;
    int tmp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	foo->newMethod = top;
	/* begin primitiveIndexOf: */
	primBits = (((unsigned) (longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 1) & 268435967;
	foo->primitiveIndex = (primBits & 511) + (((unsigned) primBits) >> 19);
	argCnt = (((unsigned) (longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 25) & 15;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	argumentArray = top1;
	if (!(((argumentArray & 1) == 0) && (((((unsigned) (longAt(argumentArray))) >> 8) & 15) == 2))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (foo->successFlag) {
		/* begin success: */
		successValue = argCnt == (fetchWordLengthOf(argumentArray));
		foo->successFlag = successValue && foo->successFlag;
	}
	if (foo->successFlag) {
		/* begin transfer:from:to: */
		in = (argumentArray + BaseHeaderSize) - 4;
		lastIn = in + (argCnt * 4);
		out = (foo->stackPointer + 4) - 4;
		while (in < lastIn) {
			longAtput(out += 4, longAt(in += 4));
		}
		/* begin unPop: */
		foo->stackPointer += argCnt * 4;
		foo->argumentCount = argCnt;
		/* begin executeNewMethod */
		if (foo->primitiveIndex > 0) {
			/* begin primitiveResponse */
			if (DoBalanceChecks) {
				nArgs = foo->argumentCount;
				delta = foo->stackPointer - foo->activeContext;
			}
			primIdx = foo->primitiveIndex;
			foo->successFlag = 1;
			dispatchFunctionPointerOnin(primIdx, primitiveTable);
			if (DoBalanceChecks) {
				if (!(balancedStackafterPrimitivewithArgs(delta, primIdx, nArgs))) {
					printUnbalancedStack(primIdx);
				}
			}
			if (foo->successFlag) {
				goto l1;
			}
		}
		/* begin activateNewMethod */
		methodHeader = longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2));
		newContext = allocateOrRecycleContext(methodHeader & LargeContextBit);
		initialIP = ((LiteralStart + ((((unsigned) methodHeader) >> 10) & 255)) * 4) + 1;
		tempCount = (((unsigned) methodHeader) >> 19) & 63;
		where = newContext + BaseHeaderSize;
		longAtput(where + (SenderIndex << 2), foo->activeContext);
		longAtput(where + (InstructionPointerIndex << 2), ((initialIP << 1) | 1));
		longAtput(where + (StackPointerIndex << 2), ((tempCount << 1) | 1));
		longAtput(where + (MethodIndex << 2), foo->newMethod);
		for (i = 0; i <= foo->argumentCount; i += 1) {
			longAtput(where + ((ReceiverIndex + i) << 2), longAt(foo->stackPointer - ((foo->argumentCount - i) * 4)));
		}
		nilOop = foo->nilObj;
		for (i = ((foo->argumentCount + 1) + ReceiverIndex); i <= (tempCount + ReceiverIndex); i += 1) {
			longAtput(where + (i << 2), nilOop);
		}
		/* begin pop: */
		foo->stackPointer -= (foo->argumentCount + 1) * 4;
		foo->reclaimableContextCount += 1;
		/* begin newActiveContext: */
		/* begin storeContextRegisters: */
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (StackPointerIndex << 2), (((((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - TempFrameStart) + 1) << 1) | 1));
		if (newContext < foo->youngStart) {
			beRootIfOld(newContext);
		}
		foo->activeContext = newContext;
		/* begin fetchContextRegisters: */
		tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (MethodIndex << 2));
		if ((tmp & 1)) {
			tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (HomeIndex << 2));
			if (tmp < foo->youngStart) {
				beRootIfOld(tmp);
			}
		} else {
			tmp = newContext;
		}
		foo->theHomeContext = tmp;
		foo->receiver = longAt(((((char *) tmp)) + BaseHeaderSize) + (ReceiverIndex << 2));
		foo->method = longAt(((((char *) tmp)) + BaseHeaderSize) + (MethodIndex << 2));
		tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2))) >> 1);
		foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
		tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (StackPointerIndex << 2))) >> 1);
		foo->stackPointer = (newContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * 4);
		/* begin quickCheckForInterrupts */
		if ((foo->interruptCheckCounter -= 1) <= 0) {
			checkForInterrupts();
		}
	l1:	/* end executeNewMethod */;
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}

int primitiveExitToDebugger(void) {
	error("Exit to debugger at user request");
}


/*	Computes E raised to the receiver power. */

int primitiveExp(void) {
register struct foo * foo = &fum;
    double rcvr;

	rcvr = popFloat();
	if (foo->successFlag) {
		pushFloat(exp(rcvr));
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * 4;
	}
}


/*	Exponent part of this float. */

int primitiveExponent(void) {
register struct foo * foo = &fum;
    double rcvr;
    int pwr;
    double frac;
    int sp;

	rcvr = popFloat();
	if (foo->successFlag) {
		frac = frexp(rcvr, &pwr);
		/* begin pushInteger: */
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, (((pwr - 1) << 1) | 1));
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * 4;
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
	Timer code details: Since primitives can run for a long time, 
	we must check to see if it is time to process a timer 
	interrupt. However, on the Mac, the high-resolution 
	millisecond clock is expensive to poll. Thus, we use a fast, 
	low-resolution (1/60th second) clock to determine if the 
	primitive took enough time to justify polling the 
	high-resolution clock. Seems Byzantine, but Bob Arning 
	showed that the performance of primitive-intensive code 
	decreased substantially if there was another process waiting 
	on a Delay. 
	One other timer detail: If the primitive fails, we want to 
	postpone the timer interrupt until just after the primitive 
	failure code has been entered. This is accomplished by 
	setting the interrupt check counter to zero, thus triggering 
	a check for interrupts when activating the method 
	containing the primitive. 
	 */
/*	start the prim timing initialise */

int primitiveExternalCall(void) {
register struct foo * foo = &fum;
    int functionLength;
    int addr;
    int timerPending;
    int moduleLength;
    int moduleName;
    int nArgs;
    int functionName;
    int delta;
    int index;
    int lit;
    int startTime;
    int successValue;
    int header;
    int sz;
    int i;
    int successValue1;
    int successValue2;
    int header1;
    int sz1;

	timerPending = foo->nextWakeupTick != 0;
	if (timerPending) {
		startTime = ioLowResMSecs();
	}
	if (DoBalanceChecks) {
		nArgs = foo->argumentCount;
		delta = foo->stackPointer - foo->activeContext;
	}
	/* begin success: */
	foo->successFlag = (((((unsigned) (longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 10) & 255) > 0) && foo->successFlag;
	if (!(foo->successFlag)) {
		return null;
	}

	/* Check if it's an array of length 4 */

	lit = longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + ((0 + LiteralStart) << 2));
	/* begin success: */
	successValue1 = (((lit & 1) == 0) && (((((unsigned) (longAt(lit))) >> 8) & 15) == 2)) && ((lengthOf(lit)) == 4);
	foo->successFlag = successValue1 && foo->successFlag;
	if (!(foo->successFlag)) {
		return null;
	}
	index = longAt(((((char *) lit)) + BaseHeaderSize) + (3 << 2));
	/* begin checkedIntegerValueOf: */
	if ((index & 1)) {
		index = (index >> 1);
		goto l3;
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
		index = 0;
		goto l3;
	}
l3:	/* end checkedIntegerValueOf: */;
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
		addr = externalPrimitiveTable[index - 1];
		if (addr != 0) {
			/* begin callExternalPrimitive: */
			dispatchFunctionPointer(addr);
			if (DoBalanceChecks) {
				if (!(balancedStackafterPrimitivewithArgs(delta, foo->primitiveIndex, nArgs))) {
					printUnbalancedStackFromNamedPrimitive();
				}
			}
			if (timerPending) {
				if ((ioLowResMSecs()) != startTime) {
					if (((ioMSecs()) & MillisecondClockMask) >= foo->nextWakeupTick) {
						if (foo->successFlag) {
							checkForInterrupts();
						} else {
							/* begin forceInterruptCheck */
							foo->interruptCheckCounter = -1000;
						}
					}
				}
			}
			return null;
		}
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	longAtput(((((char *) lit)) + BaseHeaderSize) + (2 << 2), ConstZero);
	longAtput(((((char *) lit)) + BaseHeaderSize) + (3 << 2), ConstZero);
	moduleName = longAt(((((char *) lit)) + BaseHeaderSize) + (0 << 2));
	if (moduleName == foo->nilObj) {
		moduleLength = 0;
	} else {
		/* begin success: */
		successValue = ((moduleName & 1) == 0) && (((((unsigned) (longAt(moduleName))) >> 8) & 15) >= 8);
		foo->successFlag = successValue && foo->successFlag;
		/* begin lengthOf: */
		header = longAt(moduleName);
		/* begin lengthOf:baseHeader:format: */
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(moduleName - 8)) & AllButTypeMask;
		} else {
			sz = header & SizeMask;
		}
		if (((((unsigned) header) >> 8) & 15) < 8) {
			moduleLength = ((unsigned) (sz - BaseHeaderSize)) >> 2;
			goto l1;
		} else {
			moduleLength = (sz - BaseHeaderSize) - (((((unsigned) header) >> 8) & 15) & 3);
			goto l1;
		}
		moduleLength = null;
	l1:	/* end lengthOf: */;
	}
	functionName = longAt(((((char *) lit)) + BaseHeaderSize) + (1 << 2));
	/* begin success: */
	successValue2 = ((functionName & 1) == 0) && (((((unsigned) (longAt(functionName))) >> 8) & 15) >= 8);
	foo->successFlag = successValue2 && foo->successFlag;
	/* begin lengthOf: */
	header1 = longAt(functionName);
	/* begin lengthOf:baseHeader:format: */
	if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(functionName - 8)) & AllButTypeMask;
	} else {
		sz1 = header1 & SizeMask;
	}
	if (((((unsigned) header1) >> 8) & 15) < 8) {
		functionLength = ((unsigned) (sz1 - BaseHeaderSize)) >> 2;
		goto l4;
	} else {
		functionLength = (sz1 - BaseHeaderSize) - (((((unsigned) header1) >> 8) & 15) & 3);
		goto l4;
	}
	functionLength = null;
l4:	/* end lengthOf: */;
	if (!(foo->successFlag)) {
		return null;
	}

	/* Addr ~= 0 indicates we have a compat match later */

	addr = 0;
	if (moduleLength == 0) {

		/* The returned value is the index into the obsolete primitive table. 
			If the index is found, use the 'C-style' version of the lookup.  */

		index = findObsoleteNamedPrimitivelength(((char *) (functionName + 4)), functionLength);
		if (!(index < 0)) {
			addr = ioLoadFunctionFrom(((char*) ((obsoleteNamedPrimitiveTable[index])[2])), ((char*) ((obsoleteNamedPrimitiveTable[index])[1])));
		}
	}
	if (addr == 0) {
		addr = ioLoadExternalFunctionOfLengthFromModuleOfLength(functionName + 4, functionLength, moduleName + 4, moduleLength);
	}
	if (addr == 0) {
		index = -1;
	} else {
		/* begin addToExternalPrimitiveTable: */
		for (i = 0; i <= (MaxExternalPrimitiveTableSize - 1); i += 1) {
			if ((externalPrimitiveTable[i]) == 0) {
				externalPrimitiveTable[i] = addr;
				index = i + 1;
				goto l2;
			}
		}
		index = 0;
	l2:	/* end addToExternalPrimitiveTable: */;
	}
	/* begin success: */
	foo->successFlag = (index >= 0) && foo->successFlag;
	/* begin storePointer:ofObject:withValue: */
	if (lit < foo->youngStart) {
		possibleRootStoreIntovalue(lit, ((index << 1) | 1));
	}
	longAtput(((((char *) lit)) + BaseHeaderSize) + (3 << 2), ((index << 1) | 1));
	if (foo->successFlag && (addr != 0)) {
		/* begin callExternalPrimitive: */
		dispatchFunctionPointer(addr);
		if (DoBalanceChecks) {
			if (!(balancedStackafterPrimitivewithArgs(delta, foo->primitiveIndex, nArgs))) {
				printUnbalancedStackFromNamedPrimitive();
			}
		}
		if (timerPending) {
			if ((ioLowResMSecs()) != startTime) {
				if (((ioMSecs()) & MillisecondClockMask) >= foo->nextWakeupTick) {
					if (foo->successFlag) {
						checkForInterrupts();
					} else {
						/* begin forceInterruptCheck */
						foo->interruptCheckCounter = -1000;
					}
				}
			}
		}
	} else {
		rewriteMethodCacheSelclassprimIndex(foo->messageSelector, foo->lkupClass, 0);
	}
}

int primitiveFail(void) {
	foo->successFlag = 0;
}


/*	Primitive. Search up the context stack for the next method context marked for exception handling starting at the receiver. Return nil if none found */

int primitiveFindHandlerContext(void) {
register struct foo * foo = &fum;
    int thisCntx;
    int nilOop;
    int sp;
    int top;
    int sp1;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	thisCntx = top;
	nilOop = foo->nilObj;
	do {
		if (isHandlerMarked(thisCntx)) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, thisCntx);
			foo->stackPointer = sp;
			return null;
		}
		thisCntx = longAt(((((char *) thisCntx)) + BaseHeaderSize) + (SenderIndex << 2));
	} while(!(thisCntx == nilOop));
	/* begin push: */
	longAtput(sp1 = foo->stackPointer + 4, foo->nilObj);
	foo->stackPointer = sp1;
	return null;
}


/*	Primitive. Search up the context stack for the next method context marked for unwind handling from the receiver up to but not including the argument. Return nil if none found. */

int primitiveFindNextUnwindContext(void) {
register struct foo * foo = &fum;
    int thisCntx;
    int aContext;
    int nilOop;
    int unwindMarked;
    int sp;
    int top;
    int oop;
    int sp1;
    int meth;
    int pIndex;
    int header;
    int top1;
    int primBits;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	aContext = top;
	/* begin fetchPointer:ofObject: */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	oop = top1;
	thisCntx = longAt(((((char *) oop)) + BaseHeaderSize) + (SenderIndex << 2));
	nilOop = foo->nilObj;
	while (!((thisCntx == aContext) || (thisCntx == nilOop))) {
		/* begin isUnwindMarked: */
		header = longAt(thisCntx);
		if (!(((((unsigned) header) >> 12) & 31) == 14)) {
			unwindMarked = 0;
			goto l1;
		}
		meth = longAt(((((char *) thisCntx)) + BaseHeaderSize) + (MethodIndex << 2));
		/* begin primitiveIndexOf: */
		primBits = (((unsigned) (longAt(((((char *) meth)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 1) & 268435967;
		pIndex = (primBits & 511) + (((unsigned) primBits) >> 19);
		unwindMarked = pIndex == 198;
	l1:	/* end isUnwindMarked: */;
		if (unwindMarked) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, thisCntx);
			foo->stackPointer = sp;
			return null;
		}
		thisCntx = longAt(((((char *) thisCntx)) + BaseHeaderSize) + (SenderIndex << 2));
	}
	/* begin push: */
	longAtput(sp1 = foo->stackPointer + 4, nilOop);
	foo->stackPointer = sp1;
	return null;
}

int primitiveFloatAdd(void) {
register struct foo * foo = &fum;
	return primitiveFloatAddtoArg(longAt(foo->stackPointer - (1 * 4)), longAt(foo->stackPointer));
}

int primitiveFloatAddtoArg(int rcvrOop, int argOop) {
register struct foo * foo = &fum;
    double rcvr;
    double arg;

	rcvr = loadFloatOrIntFrom(rcvrOop);
	arg = loadFloatOrIntFrom(argOop);
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
		pushFloat(rcvr + arg);
	}
}

int primitiveFloatDivide(void) {
register struct foo * foo = &fum;
	return primitiveFloatDividebyArg(longAt(foo->stackPointer - (1 * 4)), longAt(foo->stackPointer));
}

int primitiveFloatDividebyArg(int rcvrOop, int argOop) {
register struct foo * foo = &fum;
    double rcvr;
    double arg;

	rcvr = loadFloatOrIntFrom(rcvrOop);
	arg = loadFloatOrIntFrom(argOop);
	if (foo->successFlag) {
		/* begin success: */
		foo->successFlag = (arg != 0.0) && foo->successFlag;
		if (foo->successFlag) {
			/* begin pop: */
			foo->stackPointer -= 2 * 4;
			pushFloat(rcvr / arg);
		}
	}
}

int primitiveFloatEqual(void) {
register struct foo * foo = &fum;
    int aBool;
    int sp;
    int sp1;

	aBool = primitiveFloatEqualtoArg(longAt(foo->stackPointer - (1 * 4)), longAt(foo->stackPointer));
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
		/* begin pushBool: */
		if (aBool) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

int primitiveFloatEqualtoArg(int rcvrOop, int argOop) {
    double rcvr;
    double arg;

	rcvr = loadFloatOrIntFrom(rcvrOop);
	arg = loadFloatOrIntFrom(argOop);
	if (foo->successFlag) {
		return rcvr == arg;
	}
}

int primitiveFloatGreaterthanArg(int rcvrOop, int argOop) {
    double rcvr;
    double arg;

	rcvr = loadFloatOrIntFrom(rcvrOop);
	arg = loadFloatOrIntFrom(argOop);
	if (foo->successFlag) {
		return rcvr > arg;
	}
}

int primitiveFloatGreaterOrEqual(void) {
register struct foo * foo = &fum;
    int aBool;
    int sp;
    int sp1;

	aBool = primitiveFloatLessthanArg(longAt(foo->stackPointer - (1 * 4)), longAt(foo->stackPointer));
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
		/* begin pushBool: */
		if (!aBool) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

int primitiveFloatGreaterThan(void) {
register struct foo * foo = &fum;
    int aBool;
    int sp;
    int sp1;

	aBool = primitiveFloatGreaterthanArg(longAt(foo->stackPointer - (1 * 4)), longAt(foo->stackPointer));
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
		/* begin pushBool: */
		if (aBool) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

int primitiveFloatLessthanArg(int rcvrOop, int argOop) {
    double rcvr;
    double arg;

	rcvr = loadFloatOrIntFrom(rcvrOop);
	arg = loadFloatOrIntFrom(argOop);
	if (foo->successFlag) {
		return rcvr < arg;
	}
}

int primitiveFloatLessOrEqual(void) {
register struct foo * foo = &fum;
    int aBool;
    int sp;
    int sp1;

	aBool = primitiveFloatGreaterthanArg(longAt(foo->stackPointer - (1 * 4)), longAt(foo->stackPointer));
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
		/* begin pushBool: */
		if (!aBool) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

int primitiveFloatLessThan(void) {
register struct foo * foo = &fum;
    int aBool;
    int sp;
    int sp1;

	aBool = primitiveFloatLessthanArg(longAt(foo->stackPointer - (1 * 4)), longAt(foo->stackPointer));
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
		/* begin pushBool: */
		if (aBool) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

int primitiveFloatMultiply(void) {
register struct foo * foo = &fum;
	return primitiveFloatMultiplybyArg(longAt(foo->stackPointer - (1 * 4)), longAt(foo->stackPointer));
}

int primitiveFloatMultiplybyArg(int rcvrOop, int argOop) {
register struct foo * foo = &fum;
    double rcvr;
    double arg;

	rcvr = loadFloatOrIntFrom(rcvrOop);
	arg = loadFloatOrIntFrom(argOop);
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
		pushFloat(rcvr * arg);
	}
}

int primitiveFloatNotEqual(void) {
register struct foo * foo = &fum;
    int aBool;
    int sp;
    int sp1;

	aBool = primitiveFloatEqualtoArg(longAt(foo->stackPointer - (1 * 4)), longAt(foo->stackPointer));
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
		/* begin pushBool: */
		if (!aBool) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

int primitiveFloatSubtract(void) {
register struct foo * foo = &fum;
	return primitiveFloatSubtractfromArg(longAt(foo->stackPointer - (1 * 4)), longAt(foo->stackPointer));
}

int primitiveFloatSubtractfromArg(int rcvrOop, int argOop) {
register struct foo * foo = &fum;
    double rcvr;
    double arg;

	rcvr = loadFloatOrIntFrom(rcvrOop);
	arg = loadFloatOrIntFrom(argOop);
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
		pushFloat(rcvr - arg);
	}
}


/*	Clear the method lookup cache. This must be done after every programming change. */

int primitiveFlushCache(void) {
    int i;
    int aCompiledMethod;

	/* begin flushMethodCache */
	for (i = 1; i <= MethodCacheSize; i += 1) {
		methodCache[i] = 0;
	}
	for (i = 1; i <= AtCacheTotalSize; i += 1) {
		atCache[i] = 0;
	}
	/* begin compilerFlushCacheHook: */
	aCompiledMethod = null;
	if (foo->compilerInitialized) {
		compilerFlushCache(aCompiledMethod);
	}
}


/*	The receiver is a compiledMethod.  Clear all entries in the method lookup cache that refer to this method, presumably because it has been redefined, overridden or removed. */

int primitiveFlushCacheByMethod(void) {
register struct foo * foo = &fum;
    int probe;
    int oldMethod;
    int i;

	oldMethod = longAt(foo->stackPointer);
	probe = 0;
	for (i = 1; i <= MethodCacheEntries; i += 1) {
		if ((methodCache[probe + MethodCacheMethod]) == oldMethod) {
			methodCache[probe + MethodCacheSelector] = 0;
		}
		probe += MethodCacheEntrySize;
	}
	/* begin compilerFlushCacheHook: */
	if (foo->compilerInitialized) {
		compilerFlushCache(oldMethod);
	}
}


/*	The receiver is a message selector.  Clear all entries in the method lookup cache with this selector, presumably because an associated method has been redefined. */

int primitiveFlushCacheSelective(void) {
    int probe;
    int i;
    int selector;

	selector = longAt(foo->stackPointer);
	probe = 0;
	for (i = 1; i <= MethodCacheEntries; i += 1) {
		if ((methodCache[probe + MethodCacheSelector]) == selector) {
			methodCache[probe + MethodCacheSelector] = 0;
		}
		probe += MethodCacheEntrySize;
	}
}


/*	Primitive. Flush all the existing external primitives in the image thus forcing a reload on next invokation. */

int primitiveFlushExternalPrimitives(void) {
	return flushExternalPrimitives();
}


/*	On some platforms, this primitive forces enqueued display updates to be processed immediately. On others, it does nothing. */

int primitiveForceDisplayUpdate(void) {
	ioForceDisplayUpdate();
}


/*	On platforms that support it, this primitive prints the receiver, assumed to be a Form, to the default printer. */

int primitiveFormPrint(void) {
register struct foo * foo = &fum;
    int pixelsPerWord;
    int rcvr;
    int w;
    int h;
    int wordsPerLine;
    int landscapeFlag;
    int bitsArraySize;
    double vScale;
    int ok;
    int bitsArray;
    int depth;
    double hScale;
    int fmt;
    int sz;
    int header;

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
	vScale = floatValueOf(longAt(foo->stackPointer - (1 * 4)));
	hScale = floatValueOf(longAt(foo->stackPointer - (2 * 4)));
	rcvr = longAt(foo->stackPointer - (3 * 4));
	if ((rcvr & 1)) {
		/* begin success: */
		foo->successFlag = 0 && foo->successFlag;
	}
	if (foo->successFlag) {
		if (!((((rcvr & 1) == 0) && (((((unsigned) (longAt(rcvr))) >> 8) & 15) <= 4)) && ((lengthOf(rcvr)) >= 4))) {
			/* begin success: */
			foo->successFlag = 0 && foo->successFlag;
		}
	}
	if (foo->successFlag) {
		bitsArray = longAt(((((char *) rcvr)) + BaseHeaderSize) + (0 << 2));
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
				sz = (longAt(bitsArray - 8)) & AllButTypeMask;
			} else {
				sz = header & SizeMask;
			}
			fmt = (((unsigned) header) >> 8) & 15;
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
		ok = ioFormPrint(bitsArray + 4, w, h, depth, hScale, vScale, landscapeFlag);
		/* begin success: */
		foo->successFlag = ok && foo->successFlag;
	}
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 3 * 4;
	}
}

int primitiveFractionalPart(void) {
register struct foo * foo = &fum;
    double rcvr;
    double trunc;
    double frac;

	rcvr = popFloat();
	if (foo->successFlag) {
		frac = modf(rcvr, &trunc);
		pushFloat(frac);
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * 4;
	}
}


/*	Do a full garbage collection and return the number of bytes available (including swap space if dynamic memory management is supported). */

int primitiveFullGC(void) {
register struct foo * foo = &fum;
    int integerValue;
    int sp;

	/* begin pop: */
	foo->stackPointer -= 1 * 4;
	incrementalGC();
	fullGC();
	/* begin pushInteger: */
	integerValue = ((longAt(foo->freeBlock)) & AllButTypeMask) + (sqMemoryExtraBytesLeft(1));
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, ((integerValue << 1) | 1));
	foo->stackPointer = sp;
}


/*	Fetch the system attribute with the given integer ID. The 
	result is a string, which will be empty if the attribute is not 
	defined.  */

int primitiveGetAttribute(void) {
register struct foo * foo = &fum;
    int sz;
    int attr;
    int s;
    int sp;
    int integerPointer;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * 4));
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
		s = instantiateClassindexableSize(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassString << 2)), sz);
		getAttributeIntoLength(attr, s + BaseHeaderSize, sz);
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((2 - 1) * 4), s);
		foo->stackPointer = sp;
	}
}


/*	Primitive. Return the next input event from the VM event queue. */

int primitiveGetNextEvent(void) {
register struct foo * foo = &fum;
    int value;
    int evtBuf[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };
    int i;
    int arg;
    int oop;

	;
	arg = longAt(foo->stackPointer);
	if (!((((arg & 1) == 0) && (((((unsigned) (longAt(arg))) >> 8) & 15) == 2)) && ((slotSizeOf(arg)) == 8))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	ioGetNextEvent(((sqInputEvent*) evtBuf));
	if (!(foo->successFlag)) {
		return null;
	}
	/* begin storeInteger:ofObject:withValue: */
	if (((evtBuf[0]) ^ ((evtBuf[0]) << 1)) >= 0) {
		longAtput(((((char *) arg)) + BaseHeaderSize) + (0 << 2), (((evtBuf[0]) << 1) | 1));
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
	}
	if (!(foo->successFlag)) {
		return null;
	}
	/* begin storeInteger:ofObject:withValue: */
	if ((((evtBuf[1]) & MillisecondClockMask) ^ (((evtBuf[1]) & MillisecondClockMask) << 1)) >= 0) {
		longAtput(((((char *) arg)) + BaseHeaderSize) + (1 << 2), ((((evtBuf[1]) & MillisecondClockMask) << 1) | 1));
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
	}
	if (!(foo->successFlag)) {
		return null;
	}
	for (i = 2; i <= 7; i += 1) {
		value = evtBuf[i];
		if ((value ^ (value << 1)) >= 0) {
			/* begin storeInteger:ofObject:withValue: */
			if ((value ^ (value << 1)) >= 0) {
				longAtput(((((char *) arg)) + BaseHeaderSize) + (i << 2), ((value << 1) | 1));
			} else {
				/* begin primitiveFail */
				foo->successFlag = 0;
			}
		} else {
			/* begin pushRemappableOop: */
			remapBuffer[foo->remapBufferCount += 1] = arg;
			value = positive32BitIntegerFor(value);
			/* begin popRemappableOop */
			oop = remapBuffer[foo->remapBufferCount];
			foo->remapBufferCount -= 1;
			arg = oop;
			/* begin storePointer:ofObject:withValue: */
			if (arg < foo->youngStart) {
				possibleRootStoreIntovalue(arg, value);
			}
			longAtput(((((char *) arg)) + BaseHeaderSize) + (i << 2), value);
		}
	}
	if (!(foo->successFlag)) {
		return null;
	}
	/* begin pop: */
	foo->stackPointer -= 1 * 4;
}

int primitiveGreaterOrEqual(void) {
register struct foo * foo = &fum;
    int integerArgument;
    int integerReceiver;
    int integerPointer;
    int integerPointer1;
    int top;
    int top1;
    int sp;
    int sp1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
	foo->stackPointer -= 4;
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
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}

int primitiveGreaterThan(void) {
register struct foo * foo = &fum;
    int integerArgument;
    int integerReceiver;
    int integerPointer;
    int integerPointer1;
    int top;
    int top1;
    int sp;
    int sp1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
	foo->stackPointer -= 4;
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
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}


/*	When called with a single string argument, record the string 
	as the current image file name. When called with zero 
	arguments, return a string containing the current image file 
	name.  */

int primitiveImageName(void) {
register struct foo * foo = &fum;
    int sz;
    int s;
    int sCRIfn;
    int okToRename;
    int sp;

	if (foo->argumentCount == 1) {
		sCRIfn = ioLoadFunctionFrom("secCanRenameImage", "SecurityPlugin");
		if (sCRIfn != 0) {
			okToRename =  ((int (*) (void)) sCRIfn)();
			if (!(okToRename)) {
				/* begin primitiveFail */
				foo->successFlag = 0;
				return null;
			}
		}
		s = longAt(foo->stackPointer);
		if (!(((s & 1) == 0) && (((((unsigned) (longAt(s))) >> 8) & 15) >= 8))) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
		if (foo->successFlag) {
			sz = stSizeOf(s);
			imageNamePutLength(s + BaseHeaderSize, sz);
			/* begin pop: */
			foo->stackPointer -= 1 * 4;
		}
	} else {
		sz = imageNameSize();
		s = instantiateClassindexableSize(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassString << 2)), sz);
		imageNameGetLength(s + BaseHeaderSize, sz);
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((1 - 1) * 4), s);
		foo->stackPointer = sp;
	}
}


/*	Do a quick, incremental garbage collection and return the number of bytes immediately available. (Note: more space may be made available by doing a full garbage collection. */

int primitiveIncrementalGC(void) {
register struct foo * foo = &fum;
    int integerValue;
    int sp;

	/* begin pop: */
	foo->stackPointer -= 1 * 4;
	incrementalGC();
	/* begin pushInteger: */
	integerValue = ((longAt(foo->freeBlock)) & AllButTypeMask) + (sqMemoryExtraBytesLeft(0));
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, ((integerValue << 1) | 1));
	foo->stackPointer = sp;
}


/*	Note: We now have 10 bits of primitive index, but they are in two places
	for temporary backward compatibility.  The time to unpack is negligible,
	since the reconstituted full index is stored in the method cache. */

int primitiveIndexOf(int methodPointer) {
    int primBits;

	primBits = (((unsigned) (longAt(((((char *) methodPointer)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 1) & 268435967;
	return (primBits & 511) + (((unsigned) primBits) >> 19);
}


/*	Register the input semaphore. If the argument is not a 
	Semaphore, unregister the current input semaphore. */

int primitiveInputSemaphore(void) {
register struct foo * foo = &fum;
    int arg;
    int oop;
    int oop1;
    int valuePointer;
    int top;

	arg = longAt(foo->stackPointer);
	if ((arg & 1)) {
		ioSetInputSemaphore((arg >> 1));
		if (foo->successFlag) {
			/* begin pop: */
			foo->stackPointer -= 1 * 4;
		}
		return null;
	}
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	arg = top;
	if ((fetchClassOf(arg)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassSemaphore << 2)))) {
		/* begin storePointer:ofObject:withValue: */
		oop = foo->specialObjectsOop;
		if (oop < foo->youngStart) {
			possibleRootStoreIntovalue(oop, arg);
		}
		longAtput(((((char *) oop)) + BaseHeaderSize) + (TheInputSemaphore << 2), arg);
	} else {
		/* begin storePointer:ofObject:withValue: */
		oop1 = foo->specialObjectsOop;
		valuePointer = foo->nilObj;
		if (oop1 < foo->youngStart) {
			possibleRootStoreIntovalue(oop1, valuePointer);
		}
		longAtput(((((char *) oop1)) + BaseHeaderSize) + (TheInputSemaphore << 2), valuePointer);
	}
}


/*	Return an integer indicating the reason for the most recent input interrupt. */

int primitiveInputWord(void) {
register struct foo * foo = &fum;
    int sp;

	/* begin pop: */
	foo->stackPointer -= 1 * 4;
	/* begin pushInteger: */
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, ((0 << 1) | 1));
	foo->stackPointer = sp;
}

int primitiveInstVarAt(void) {
register struct foo * foo = &fum;
    int fmt;
    int totalLength;
    int value;
    int rcvr;
    int hdr;
    int index;
    int fixedFields;
    int sp;
    int integerPointer;
    int sz;
    int classFormat;
    int class;
    int ccIndex;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * 4));
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
	rcvr = longAt(foo->stackPointer - (1 * 4));
	if (foo->successFlag) {
		hdr = longAt(rcvr);
		fmt = (((unsigned) hdr) >> 8) & 15;
		/* begin lengthOf:baseHeader:format: */
		if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(rcvr - 8)) & AllButTypeMask;
		} else {
			sz = hdr & SizeMask;
		}
		if (fmt < 8) {
			totalLength = ((unsigned) (sz - BaseHeaderSize)) >> 2;
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
			class = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
			goto l5;
		}
		ccIndex = (((unsigned) (longAt(rcvr))) >> 12) & 31;
		if (ccIndex == 0) {
			class = (longAt(rcvr - 4)) & AllButTypeMask;
			goto l5;
		} else {
			class = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
			goto l5;
		}
	l5:	/* end fetchClassOf: */;
		classFormat = (longAt(((((char *) class)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1;
		fixedFields = (((((unsigned) classFormat) >> 11) & 192) + ((((unsigned) classFormat) >> 2) & 63)) - 1;
	l3:	/* end fixedFieldsOf:format:length: */;
		if (!((index >= 1) && (index <= fixedFields))) {
			foo->successFlag = 0;
		}
	}
	if (foo->successFlag) {
		/* begin subscript:with:format: */
		if (fmt <= 4) {
			value = longAt(((((char *) rcvr)) + BaseHeaderSize) + ((index - 1) << 2));
			goto l1;
		}
		if (fmt < 8) {
			value = positive32BitIntegerFor(longAt(((((char *) rcvr)) + BaseHeaderSize) + ((index - 1) << 2)));
			goto l1;
		} else {
			value = (((byteAt(((((char *) rcvr)) + BaseHeaderSize) + (index - 1))) << 1) | 1);
			goto l1;
		}
	l1:	/* end subscript:with:format: */;
	}
	if (foo->successFlag) {
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * 4), value);
		foo->stackPointer = sp;
	}
}

int primitiveInstVarAtPut(void) {
register struct foo * foo = &fum;
    int fmt;
    int newValue;
    int totalLength;
    int rcvr;
    int hdr;
    int index;
    int fixedFields;
    int sp;
    int integerPointer;
    int sz;
    int classFormat;
    int class;
    int valueToStore;
    int ccIndex;

	newValue = longAt(foo->stackPointer);
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * 4));
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
	rcvr = longAt(foo->stackPointer - (2 * 4));
	if (foo->successFlag) {
		hdr = longAt(rcvr);
		fmt = (((unsigned) hdr) >> 8) & 15;
		/* begin lengthOf:baseHeader:format: */
		if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(rcvr - 8)) & AllButTypeMask;
		} else {
			sz = hdr & SizeMask;
		}
		if (fmt < 8) {
			totalLength = ((unsigned) (sz - BaseHeaderSize)) >> 2;
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
			class = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
			goto l4;
		}
		ccIndex = (((unsigned) (longAt(rcvr))) >> 12) & 31;
		if (ccIndex == 0) {
			class = (longAt(rcvr - 4)) & AllButTypeMask;
			goto l4;
		} else {
			class = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
			goto l4;
		}
	l4:	/* end fetchClassOf: */;
		classFormat = (longAt(((((char *) class)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1;
		fixedFields = (((((unsigned) classFormat) >> 11) & 192) + ((((unsigned) classFormat) >> 2) & 63)) - 1;
	l3:	/* end fixedFieldsOf:format:length: */;
		if (!((index >= 1) && (index <= fixedFields))) {
			foo->successFlag = 0;
		}
	}
	if (foo->successFlag) {
		/* begin subscript:with:storing:format: */
		if (fmt <= 4) {
			/* begin storePointer:ofObject:withValue: */
			if (rcvr < foo->youngStart) {
				possibleRootStoreIntovalue(rcvr, newValue);
			}
			longAtput(((((char *) rcvr)) + BaseHeaderSize) + ((index - 1) << 2), newValue);
		} else {
			if (fmt < 8) {
				valueToStore = positive32BitValueOf(newValue);
				if (foo->successFlag) {
					longAtput(((((char *) rcvr)) + BaseHeaderSize) + ((index - 1) << 2), valueToStore);
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
					byteAtput(((((char *) rcvr)) + BaseHeaderSize) + (index - 1), valueToStore);
				}
			}
		}
	}
	if (foo->successFlag) {
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * 4), newValue);
		foo->stackPointer = sp;
	}
}


/*	Note:  this primitive has been decommissioned.  It is only here for short-term compatibility with an internal 2.3beta-d image that used this.  It did not save much time and it complicated several things.  Plus Jitter will do it right anyway. */

int primitiveInstVarsPutFromStack(void) {
register struct foo * foo = &fum;
    int rcvr;
    int i;
    int offsetBits;


	/* Mark dirty so stores below can be unchecked */

	rcvr = longAt(foo->stackPointer - (foo->argumentCount * 4));
	if (rcvr < foo->youngStart) {
		beRootIfOld(rcvr);
	}
	for (i = 0; i <= (foo->argumentCount - 1); i += 1) {
		if ((i & 3) == 0) {
			offsetBits = positive32BitValueOf(longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (((((int) i >> 2)) + LiteralStart) << 2)));
		}
		longAtput(((((char *) rcvr)) + BaseHeaderSize) + ((offsetBits & 255) << 2), longAt(foo->stackPointer - (i * 4)));
		offsetBits = ((unsigned) offsetBits) >> 8;
	}
	/* begin pop: */
	foo->stackPointer -= foo->argumentCount * 4;
}


/*	Return the 32bit signed integer contents of a words receiver */

int primitiveIntegerAt(void) {
register struct foo * foo = &fum;
    int sz;
    int value;
    int rcvr;
    int index;
    int addr;
    int sp;
    int object;
    int sp1;
    int integerPointer;
    int header;
    int sz1;
    int successValue;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * 4));
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
	rcvr = longAt(foo->stackPointer - (1 * 4));
	if (!(((rcvr & 1) == 0) && (((((unsigned) (longAt(rcvr))) >> 8) & 15) == 6))) {
		/* begin success: */
		foo->successFlag = 0 && foo->successFlag;
		return null;
	}
	/* begin lengthOf: */
	header = longAt(rcvr);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(rcvr - 8)) & AllButTypeMask;
	} else {
		sz1 = header & SizeMask;
	}
	if (((((unsigned) header) >> 8) & 15) < 8) {
		sz = ((unsigned) (sz1 - BaseHeaderSize)) >> 2;
		goto l2;
	} else {
		sz = (sz1 - BaseHeaderSize) - (((((unsigned) header) >> 8) & 15) & 3);
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
		value = *((int *) addr);
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
		if ((value ^ (value << 1)) >= 0) {
			/* begin pushInteger: */
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, ((value << 1) | 1));
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			object = signed32BitIntegerFor(value);
			longAtput(sp1 = foo->stackPointer + 4, object);
			foo->stackPointer = sp1;
		}
	}
}


/*	Return the 32bit signed integer contents of a words receiver */

int primitiveIntegerAtPut(void) {
register struct foo * foo = &fum;
    int sz;
    int value;
    int rcvr;
    int index;
    int addr;
    int valueOop;
    int sp;
    int integerPointer;
    int header;
    int sz1;

	valueOop = longAt(foo->stackPointer);
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * 4));
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
	rcvr = longAt(foo->stackPointer - (2 * 4));
	if (!(((rcvr & 1) == 0) && (((((unsigned) (longAt(rcvr))) >> 8) & 15) == 6))) {
		/* begin success: */
		foo->successFlag = 0 && foo->successFlag;
		return null;
	}
	/* begin lengthOf: */
	header = longAt(rcvr);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(rcvr - 8)) & AllButTypeMask;
	} else {
		sz1 = header & SizeMask;
	}
	if (((((unsigned) header) >> 8) & 15) < 8) {
		sz = ((unsigned) (sz1 - BaseHeaderSize)) >> 2;
		goto l2;
	} else {
		sz = (sz1 - BaseHeaderSize) - (((((unsigned) header) >> 8) & 15) & 3);
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
		value = *((int *) addr) = value;
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((3 - 1) * 4), valueOop);
		foo->stackPointer = sp;
	}
}


/*	Register the user interrupt semaphore. If the argument is 
	not a Semaphore, unregister the current interrupt 
	semaphore.  */

int primitiveInterruptSemaphore(void) {
register struct foo * foo = &fum;
    int arg;
    int oop;
    int oop1;
    int valuePointer;
    int top;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	arg = top;
	if ((fetchClassOf(arg)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassSemaphore << 2)))) {
		/* begin storePointer:ofObject:withValue: */
		oop = foo->specialObjectsOop;
		if (oop < foo->youngStart) {
			possibleRootStoreIntovalue(oop, arg);
		}
		longAtput(((((char *) oop)) + BaseHeaderSize) + (TheInterruptSemaphore << 2), arg);
	} else {
		/* begin storePointer:ofObject:withValue: */
		oop1 = foo->specialObjectsOop;
		valuePointer = foo->nilObj;
		if (oop1 < foo->youngStart) {
			possibleRootStoreIntovalue(oop1, valuePointer);
		}
		longAtput(((((char *) oop1)) + BaseHeaderSize) + (TheInterruptSemaphore << 2), valuePointer);
	}
}


/*	Primitive. 'Invoke' an object like a function, sending the special message 
		run: originalSelector with: arguments in: aReceiver.
	 */

int primitiveInvokeObjectAsMethod(void) {
register struct foo * foo = &fum;
    int lookupClass;
    int runReceiver;
    int runArgs;
    int newReceiver;
    int runSelector;
    int out;
    int lastIn;
    int in;
    int sp;
    int sp1;
    int sp2;
    int sp3;
    int primIdx;
    int nArgs;
    int delta;
    int ccIndex;
    int initialIP;
    int tempCount;
    int newContext;
    int where;
    int i;
    int methodHeader;
    int nilOop;
    int tmp;

	runArgs = instantiateClassindexableSize(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassArray << 2)), foo->argumentCount);
	beRootIfOld(runArgs);
	/* begin transfer:from:to: */
	in = (foo->stackPointer - ((foo->argumentCount - 1) * 4)) - 4;
	lastIn = in + (foo->argumentCount * 4);
	out = (runArgs + BaseHeaderSize) - 4;
	while (in < lastIn) {
		longAtput(out += 4, longAt(in += 4));
	}
	runSelector = foo->messageSelector;
	runReceiver = longAt(foo->stackPointer - (foo->argumentCount * 4));
	/* begin pop: */
	foo->stackPointer -= (foo->argumentCount + 1) * 4;
	newReceiver = foo->newMethod;
	foo->messageSelector = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SelectorRunWithIn << 2));
	foo->argumentCount = 3;
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, newReceiver);
	foo->stackPointer = sp;
	/* begin push: */
	longAtput(sp1 = foo->stackPointer + 4, runSelector);
	foo->stackPointer = sp1;
	/* begin push: */
	longAtput(sp2 = foo->stackPointer + 4, runArgs);
	foo->stackPointer = sp2;
	/* begin push: */
	longAtput(sp3 = foo->stackPointer + 4, runReceiver);
	foo->stackPointer = sp3;
	/* begin fetchClassOf: */
	if ((newReceiver & 1)) {
		lookupClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l2;
	}
	ccIndex = (((unsigned) (longAt(newReceiver))) >> 12) & 31;
	if (ccIndex == 0) {
		lookupClass = (longAt(newReceiver - 4)) & AllButTypeMask;
		goto l2;
	} else {
		lookupClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l2;
	}
l2:	/* end fetchClassOf: */;
	findNewMethodInClass(lookupClass);
	/* begin executeNewMethod */
	if (foo->primitiveIndex > 0) {
		/* begin primitiveResponse */
		if (DoBalanceChecks) {
			nArgs = foo->argumentCount;
			delta = foo->stackPointer - foo->activeContext;
		}
		primIdx = foo->primitiveIndex;
		foo->successFlag = 1;
		dispatchFunctionPointerOnin(primIdx, primitiveTable);
		if (DoBalanceChecks) {
			if (!(balancedStackafterPrimitivewithArgs(delta, primIdx, nArgs))) {
				printUnbalancedStack(primIdx);
			}
		}
		if (foo->successFlag) {
			goto l1;
		}
	}
	/* begin activateNewMethod */
	methodHeader = longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2));
	newContext = allocateOrRecycleContext(methodHeader & LargeContextBit);
	initialIP = ((LiteralStart + ((((unsigned) methodHeader) >> 10) & 255)) * 4) + 1;
	tempCount = (((unsigned) methodHeader) >> 19) & 63;
	where = newContext + BaseHeaderSize;
	longAtput(where + (SenderIndex << 2), foo->activeContext);
	longAtput(where + (InstructionPointerIndex << 2), ((initialIP << 1) | 1));
	longAtput(where + (StackPointerIndex << 2), ((tempCount << 1) | 1));
	longAtput(where + (MethodIndex << 2), foo->newMethod);
	for (i = 0; i <= foo->argumentCount; i += 1) {
		longAtput(where + ((ReceiverIndex + i) << 2), longAt(foo->stackPointer - ((foo->argumentCount - i) * 4)));
	}
	nilOop = foo->nilObj;
	for (i = ((foo->argumentCount + 1) + ReceiverIndex); i <= (tempCount + ReceiverIndex); i += 1) {
		longAtput(where + (i << 2), nilOop);
	}
	/* begin pop: */
	foo->stackPointer -= (foo->argumentCount + 1) * 4;
	foo->reclaimableContextCount += 1;
	/* begin newActiveContext: */
	/* begin storeContextRegisters: */
	longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
	longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (StackPointerIndex << 2), (((((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - TempFrameStart) + 1) << 1) | 1));
	if (newContext < foo->youngStart) {
		beRootIfOld(newContext);
	}
	foo->activeContext = newContext;
	/* begin fetchContextRegisters: */
	tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (MethodIndex << 2));
	if ((tmp & 1)) {
		tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (HomeIndex << 2));
		if (tmp < foo->youngStart) {
			beRootIfOld(tmp);
		}
	} else {
		tmp = newContext;
	}
	foo->theHomeContext = tmp;
	foo->receiver = longAt(((((char *) tmp)) + BaseHeaderSize) + (ReceiverIndex << 2));
	foo->method = longAt(((((char *) tmp)) + BaseHeaderSize) + (MethodIndex << 2));
	tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2))) >> 1);
	foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
	tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (StackPointerIndex << 2))) >> 1);
	foo->stackPointer = (newContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * 4);
	/* begin quickCheckForInterrupts */
	if ((foo->interruptCheckCounter -= 1) <= 0) {
		checkForInterrupts();
	}
l1:	/* end executeNewMethod */;
	foo->successFlag = 1;
}


/*	Obsolete on virtually all platforms; old style input polling code.
	Return the next keycode and remove it from the input buffer. The low byte is the 8-bit ISO character. The next four bits are the Smalltalk modifier bits <cmd><option><ctrl><shift>. */

int primitiveKbdNext(void) {
register struct foo * foo = &fum;
    int keystrokeWord;
    int sp;
    int sp1;

	/* begin pop: */
	foo->stackPointer -= 1 * 4;
	keystrokeWord = ioGetKeystroke();
	if (keystrokeWord >= 0) {
		/* begin pushInteger: */
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, ((keystrokeWord << 1) | 1));
		foo->stackPointer = sp;
	} else {
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + 4, foo->nilObj);
		foo->stackPointer = sp1;
	}
}


/*	Obsolete on virtually all platforms; old style input polling code.
	Return the next keycode and without removing it from the input buffer. The low byte is the 8-bit ISO character. The next four bits are the Smalltalk modifier bits <cmd><option><ctrl><shift>. */

int primitiveKbdPeek(void) {
register struct foo * foo = &fum;
    int keystrokeWord;
    int sp;
    int sp1;

	/* begin pop: */
	foo->stackPointer -= 1 * 4;
	keystrokeWord = ioPeekKeystroke();
	if (keystrokeWord >= 0) {
		/* begin pushInteger: */
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, ((keystrokeWord << 1) | 1));
		foo->stackPointer = sp;
	} else {
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + 4, foo->nilObj);
		foo->stackPointer = sp1;
	}
}

int primitiveLessOrEqual(void) {
register struct foo * foo = &fum;
    int integerArgument;
    int integerReceiver;
    int integerPointer;
    int integerPointer1;
    int top;
    int top1;
    int sp;
    int sp1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
	foo->stackPointer -= 4;
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
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}

int primitiveLessThan(void) {
register struct foo * foo = &fum;
    int integerArgument;
    int integerReceiver;
    int integerPointer;
    int integerPointer1;
    int top;
    int top1;
    int sp;
    int sp1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
	foo->stackPointer -= 4;
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
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}


/*	Primitive. Return the n-th builtin module name. */

int primitiveListBuiltinModule(void) {
register struct foo * foo = &fum;
    int length;
    int i;
    int index;
    int nameOop;
    char * moduleName;
    int sp;
    int integerPointer;
    int sp1;

	if (!(foo->argumentCount == 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * 4));
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
		foo->stackPointer -= 2 * 4;
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, foo->nilObj);
		foo->stackPointer = sp;
		return null;
	}
	length = strlen(moduleName);
	nameOop = instantiateClassindexableSize(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassString << 2)), length);
	for (i = 0; i <= (length - 1); i += 1) {
		byteAtput(((((char *) nameOop)) + BaseHeaderSize) + i, moduleName[i]);
	}
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
	/* begin pop:thenPush: */
	longAtput(sp1 = foo->stackPointer - ((2 - 1) * 4), nameOop);
	foo->stackPointer = sp1;
}


/*	Primitive. Return the n-th loaded external module name. */

int primitiveListExternalModule(void) {
register struct foo * foo = &fum;
    int length;
    int i;
    int index;
    int nameOop;
    char * moduleName;
    int sp;
    int integerPointer;
    int sp1;

	if (!(foo->argumentCount == 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * 4));
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
		foo->stackPointer -= 2 * 4;
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, foo->nilObj);
		foo->stackPointer = sp;
		return null;
	}
	length = strlen(moduleName);
	nameOop = instantiateClassindexableSize(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassString << 2)), length);
	for (i = 0; i <= (length - 1); i += 1) {
		byteAtput(((((char *) nameOop)) + BaseHeaderSize) + i, moduleName[i]);
	}
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
	/* begin pop:thenPush: */
	longAtput(sp1 = foo->stackPointer - ((2 - 1) * 4), nameOop);
	foo->stackPointer = sp1;
}


/*	This primitive is called from Squeak as...
		<imageSegment> loadSegmentFrom: aWordArray outPointers: anArray. */
/*	This primitive will load a binary image segment created by primitiveStoreImageSegment.  It expects the outPointer array to be of the proper size, and the wordArray to be well formed.  It will return as its value the original array of roots, and the erstwhile segmentWordArray will have been truncated to a size of zero.  If this primitive should fail, the segmentWordArray will, sadly, have been reduced to an unrecognizable and unusable jumble.  But what more could you have done with it anyway? */

int primitiveLoadImageSegment(void) {
register struct foo * foo = &fum;
    int doingClass;
    int extraSize;
    int fieldPtr;
    int fieldOop;
    int lastOut;
    int lastPtr;
    int segmentWordArray;
    int mapOop;
    int hdrTypeBits;
    int segOop;
    int data;
    int outPointerArray;
    int endSeg;
    int header;
    int outPtr;
    int addr;
    int addr1;
    int sp;
    int sz;
    int header1;
    int sz1;
    int header2;

	if (DoAssertionChecks) {
		verifyCleanHeaders();
	}
	outPointerArray = longAt(foo->stackPointer);
	lastOut = outPointerArray + (lastPointerOf(outPointerArray));
	segmentWordArray = longAt(foo->stackPointer - (1 * 4));

	/* Essential type checks */

	endSeg = (segmentWordArray + (sizeBitsOf(segmentWordArray))) - BaseHeaderSize;
	if (!((((((unsigned) (longAt(outPointerArray))) >> 8) & 15) == 2) && (((((unsigned) (longAt(segmentWordArray))) >> 8) & 15) == 6))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	data = longAt(segmentWordArray + BaseHeaderSize);
	if (!((data & 65535) == 6502)) {
		/* begin reverseBytesFrom:to: */
		addr1 = segmentWordArray + BaseHeaderSize;
		while (addr1 < (endSeg + 4)) {
			longAtput(addr1, ((((((unsigned) (longAt(addr1)) >> 24)) & 255) + ((((unsigned) (longAt(addr1)) >> 8)) & 65280)) + ((((unsigned) (longAt(addr1)) << 8)) & 16711680)) + ((((unsigned) (longAt(addr1)) << 24)) & 4278190080U));
			addr1 += 4;
		}
		data = longAt(segmentWordArray + BaseHeaderSize);
		if (!((data & 65535) == 6502)) {
			/* begin reverseBytesFrom:to: */
			addr = segmentWordArray + BaseHeaderSize;
			while (addr < (endSeg + 4)) {
				longAtput(addr, ((((((unsigned) (longAt(addr)) >> 24)) & 255) + ((((unsigned) (longAt(addr)) >> 8)) & 65280)) + ((((unsigned) (longAt(addr)) << 8)) & 16711680)) + ((((unsigned) (longAt(addr)) << 24)) & 4278190080U));
				addr += 4;
			}
			if (DoAssertionChecks) {
				verifyCleanHeaders();
			}
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	if (!(data == (imageSegmentVersion()))) {

		/* Oop of first embedded object */

		segOop = ((segmentWordArray + BaseHeaderSize) + 4) + (headerTypeBytes[(longAt((segmentWordArray + BaseHeaderSize) + 4)) & TypeMask]);
		byteSwapByteObjectsFromto(segOop, endSeg + 4);
	}
	segOop = ((segmentWordArray + BaseHeaderSize) + 4) + (headerTypeBytes[(longAt((segmentWordArray + BaseHeaderSize) + 4)) & TypeMask]);
	while (segOop <= endSeg) {
		if (((longAt(segOop)) & TypeMask) <= 1) {
			fieldPtr = segOop - 4;
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
				fieldPtr += 4;
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
					fieldPtr += 4;
				}
				if (segOop < foo->youngStart) {
					possibleRootStoreIntovalue(segOop, mapOop);
				}
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if (segOop >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(segOop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(segOop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header1 = longAt(segOop);
			if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(segOop - 8)) & AllButTypeMask;
				goto l1;
			} else {
				sz = header1 & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		segOop = (segOop + sz) + (headerTypeBytes[(longAt(segOop + sz)) & TypeMask]);
	}
	segOop = ((segmentWordArray + BaseHeaderSize) + 4) + (headerTypeBytes[(longAt((segmentWordArray + BaseHeaderSize) + 4)) & TypeMask]);
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
			fieldPtr += 4;
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if (segOop >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(segOop)) & TypeMask) == HeaderTypeFree) {
			sz1 = (longAt(segOop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header2 = longAt(segOop);
			if ((header2 & TypeMask) == HeaderTypeSizeAndClass) {
				sz1 = (longAt(segOop - 8)) & AllButTypeMask;
				goto l2;
			} else {
				sz1 = header2 & SizeMask;
				goto l2;
			}
		l2:	/* end sizeBitsOf: */;
		}
		segOop = (segOop + sz1) + (headerTypeBytes[(longAt(segOop + sz1)) & TypeMask]);
	}
	extraSize = headerTypeBytes[(longAt(segmentWordArray)) & TypeMask];
	hdrTypeBits = (longAt(segmentWordArray)) & TypeMask;
	if (extraSize == 8) {
		longAtput(segmentWordArray - extraSize, (BaseHeaderSize + 4) + hdrTypeBits);
	} else {
		header = longAt(segmentWordArray);
		longAtput(segmentWordArray, ((header - (header & SizeMask)) + BaseHeaderSize) + 4);
	}
	if (DoAssertionChecks) {
		verifyCleanHeaders();
	}
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((3 - 1) * 4), ((segmentWordArray + BaseHeaderSize) + 4) + (headerTypeBytes[(longAt((segmentWordArray + BaseHeaderSize) + 4)) & TypeMask]));
	foo->stackPointer = sp;
}

int primitiveLoadInstVar(void) {
register struct foo * foo = &fum;
    int thisReceiver;
    int top;
    int sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	thisReceiver = top;
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, longAt(((((char *) thisReceiver)) + BaseHeaderSize) + ((foo->primitiveIndex - 264) << 2)));
	foo->stackPointer = sp;
}


/*	Natural log. */

int primitiveLogN(void) {
register struct foo * foo = &fum;
    double rcvr;

	rcvr = popFloat();
	if (foo->successFlag) {
		pushFloat(log(rcvr));
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * 4;
	}
}


/*	Register the low-space semaphore. If the argument is not a 
	Semaphore, unregister the current low-space Semaphore. */

int primitiveLowSpaceSemaphore(void) {
register struct foo * foo = &fum;
    int arg;
    int oop;
    int oop1;
    int valuePointer;
    int top;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	arg = top;
	if ((fetchClassOf(arg)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassSemaphore << 2)))) {
		/* begin storePointer:ofObject:withValue: */
		oop = foo->specialObjectsOop;
		if (oop < foo->youngStart) {
			possibleRootStoreIntovalue(oop, arg);
		}
		longAtput(((((char *) oop)) + BaseHeaderSize) + (TheLowSpaceSemaphore << 2), arg);
	} else {
		/* begin storePointer:ofObject:withValue: */
		oop1 = foo->specialObjectsOop;
		valuePointer = foo->nilObj;
		if (oop1 < foo->youngStart) {
			possibleRootStoreIntovalue(oop1, valuePointer);
		}
		longAtput(((((char *) oop1)) + BaseHeaderSize) + (TheLowSpaceSemaphore << 2), valuePointer);
	}
}

int primitiveMakePoint(void) {
register struct foo * foo = &fum;
    int pt;
    int rcvr;
    int argument;
    int valuePointer;
    int valuePointer1;
    int valuePointer2;
    int sp;
    int pointResult;
    int pointResult1;
    int pointResult2;

	argument = longAt(foo->stackPointer);
	rcvr = longAt(foo->stackPointer - (1 * 4));
	if ((rcvr & 1)) {
		if ((argument & 1)) {
			/* begin makePointwithxValue:yValue: */
			pointResult = instantiateSmallClasssizeInBytesfill(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassPoint << 2)), 12, foo->nilObj);
			/* begin storePointer:ofObject:withValue: */
			if (pointResult < foo->youngStart) {
				possibleRootStoreIntovalue(pointResult, ((((rcvr >> 1)) << 1) | 1));
			}
			longAtput(((((char *) pointResult)) + BaseHeaderSize) + (XIndex << 2), ((((rcvr >> 1)) << 1) | 1));
			/* begin storePointer:ofObject:withValue: */
			if (pointResult < foo->youngStart) {
				possibleRootStoreIntovalue(pointResult, ((((argument >> 1)) << 1) | 1));
			}
			longAtput(((((char *) pointResult)) + BaseHeaderSize) + (YIndex << 2), ((((argument >> 1)) << 1) | 1));
			pt = pointResult;
		} else {
			/* begin makePointwithxValue:yValue: */
			pointResult1 = instantiateSmallClasssizeInBytesfill(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassPoint << 2)), 12, foo->nilObj);
			/* begin storePointer:ofObject:withValue: */
			if (pointResult1 < foo->youngStart) {
				possibleRootStoreIntovalue(pointResult1, ((((rcvr >> 1)) << 1) | 1));
			}
			longAtput(((((char *) pointResult1)) + BaseHeaderSize) + (XIndex << 2), ((((rcvr >> 1)) << 1) | 1));
			/* begin storePointer:ofObject:withValue: */
			if (pointResult1 < foo->youngStart) {
				possibleRootStoreIntovalue(pointResult1, ((0 << 1) | 1));
			}
			longAtput(((((char *) pointResult1)) + BaseHeaderSize) + (YIndex << 2), ((0 << 1) | 1));
			pt = pointResult1;
			/* begin storePointer:ofObject:withValue: */
			valuePointer = longAt(foo->stackPointer - (0 * 4));
			if (pt < foo->youngStart) {
				possibleRootStoreIntovalue(pt, valuePointer);
			}
			longAtput(((((char *) pt)) + BaseHeaderSize) + (1 << 2), valuePointer);
		}
	} else {
		if (!((fetchClassOf(rcvr)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassFloat << 2))))) {
			/* begin success: */
			foo->successFlag = 0 && foo->successFlag;
			return null;
		}
		/* begin makePointwithxValue:yValue: */
		pointResult2 = instantiateSmallClasssizeInBytesfill(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassPoint << 2)), 12, foo->nilObj);
		/* begin storePointer:ofObject:withValue: */
		if (pointResult2 < foo->youngStart) {
			possibleRootStoreIntovalue(pointResult2, ((0 << 1) | 1));
		}
		longAtput(((((char *) pointResult2)) + BaseHeaderSize) + (XIndex << 2), ((0 << 1) | 1));
		/* begin storePointer:ofObject:withValue: */
		if (pointResult2 < foo->youngStart) {
			possibleRootStoreIntovalue(pointResult2, ((0 << 1) | 1));
		}
		longAtput(((((char *) pointResult2)) + BaseHeaderSize) + (YIndex << 2), ((0 << 1) | 1));
		pt = pointResult2;
		/* begin storePointer:ofObject:withValue: */
		valuePointer1 = longAt(foo->stackPointer - (1 * 4));
		if (pt < foo->youngStart) {
			possibleRootStoreIntovalue(pt, valuePointer1);
		}
		longAtput(((((char *) pt)) + BaseHeaderSize) + (0 << 2), valuePointer1);
		/* begin storePointer:ofObject:withValue: */
		valuePointer2 = longAt(foo->stackPointer - (0 * 4));
		if (pt < foo->youngStart) {
			possibleRootStoreIntovalue(pt, valuePointer2);
		}
		longAtput(((((char *) pt)) + BaseHeaderSize) + (1 << 2), valuePointer2);
	}
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((2 - 1) * 4), pt);
	foo->stackPointer = sp;
}


/*	Primitive. Mark the method for exception handling. The primitive must fail after marking the context so that the regular code is run. */

int primitiveMarkHandlerMethod(void) {
	/* begin primitiveFail */
	foo->successFlag = 0;
	return null;
}


/*	Primitive. Mark the method for exception unwinding. The primitive must fail after marking the context so that the regular code is run. */

int primitiveMarkUnwindMethod(void) {
	/* begin primitiveFail */
	foo->successFlag = 0;
	return null;
}


/*	Return the method an external primitive was defined in */

int primitiveMethod(void) {
	return foo->newMethod;
}


/*	Return the value of the millisecond clock as an integer. Note that the millisecond clock wraps around periodically. On some platforms it can wrap daily. The range is limited to SmallInteger maxVal / 2 to allow delays of up to that length without overflowing a SmallInteger. */

int primitiveMillisecondClock(void) {
register struct foo * foo = &fum;
    int oop;
    int sp;

	/* begin pop:thenPush: */
	oop = ((((ioMSecs()) & MillisecondClockMask) << 1) | 1);
	longAtput(sp = foo->stackPointer - ((1 - 1) * 4), oop);
	foo->stackPointer = sp;
}

int primitiveMod(void) {
register struct foo * foo = &fum;
    int mod;
    int sp;

	mod = doPrimitiveModby(longAt(foo->stackPointer - (1 * 4)), longAt(foo->stackPointer));
	/* begin pop2AndPushIntegerIfOK: */
	if (foo->successFlag) {
		if ((mod ^ (mod << 1)) >= 0) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - ((2 - 1) * 4), ((mod << 1) | 1));
			foo->stackPointer = sp;
		} else {
			foo->successFlag = 0;
		}
	}
}


/*	Obsolete on virtually all platforms; old style input polling code.
	Return the mouse button state. The low three bits encode the state of the <red><yellow><blue> mouse buttons. The next four bits encode the Smalltalk modifier bits <cmd><option><ctrl><shift>. */

int primitiveMouseButtons(void) {
register struct foo * foo = &fum;
    int buttonWord;
    int sp;

	/* begin pop: */
	foo->stackPointer -= 1 * 4;
	buttonWord = ioGetButtonState();
	/* begin pushInteger: */
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, ((buttonWord << 1) | 1));
	foo->stackPointer = sp;
}


/*	Obsolete on virtually all platforms; old style input polling code.
	Return a Point indicating current position of the mouse. Note that mouse coordinates may be negative if the mouse moves above or to the left of the top-left corner of the Smalltalk window. */

int primitiveMousePoint(void) {
register struct foo * foo = &fum;
    int x;
    int y;
    int pointWord;
    int object;
    int sp;
    int pointResult;

	/* begin pop: */
	foo->stackPointer -= 1 * 4;
	pointWord = ioMousePoint();
	/* begin signExtend16: */
	if ((((((unsigned) pointWord) >> 16) & 65535) & 32768) == 0) {
		x = (((unsigned) pointWord) >> 16) & 65535;
		goto l1;
	} else {
		x = ((((unsigned) pointWord) >> 16) & 65535) - 65536;
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
	pointResult = instantiateSmallClasssizeInBytesfill(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassPoint << 2)), 12, foo->nilObj);
	/* begin storePointer:ofObject:withValue: */
	if (pointResult < foo->youngStart) {
		possibleRootStoreIntovalue(pointResult, ((x << 1) | 1));
	}
	longAtput(((((char *) pointResult)) + BaseHeaderSize) + (XIndex << 2), ((x << 1) | 1));
	/* begin storePointer:ofObject:withValue: */
	if (pointResult < foo->youngStart) {
		possibleRootStoreIntovalue(pointResult, ((y << 1) | 1));
	}
	longAtput(((((char *) pointResult)) + BaseHeaderSize) + (YIndex << 2), ((y << 1) | 1));
	object = pointResult;
	longAtput(sp = foo->stackPointer + 4, object);
	foo->stackPointer = sp;
}

int primitiveMultiply(void) {
register struct foo * foo = &fum;
    int integerRcvr;
    int integerResult;
    int integerArg;
    int integerPointer;
    int integerPointer1;
    int sp;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * 4));
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
	integerPointer1 = longAt(foo->stackPointer - (0 * 4));
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
				if ((integerResult ^ (integerResult << 1)) >= 0) {
					/* begin pop:thenPush: */
					longAtput(sp = foo->stackPointer - ((2 - 1) * 4), ((integerResult << 1) | 1));
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

int primitiveNew(void) {
register struct foo * foo = &fum;
    int spaceOkay;
    int class;
    int object;
    int sp;
    int okay;
    int format;
    int minFree;
    int minFree1;


	/* The following may cause GC! */

	class = longAt(foo->stackPointer);
	/* begin sufficientSpaceToInstantiate:indexableSize: */
	format = (((unsigned) ((longAt(((((char *) class)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1)) >> 8) & 15;
	if (((((unsigned ) 0)) > 0) && (format < 2)) {
		spaceOkay = 0;
		goto l3;
	}
	if (format < 8) {
		/* begin sufficientSpaceToAllocate: */
		minFree = (foo->lowSpaceThreshold + (2500 + (0 * 4))) + BaseHeaderSize;
		if ((((unsigned ) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((unsigned ) minFree))) {
			okay = 1;
			goto l1;
		} else {
			okay = sufficientSpaceAfterGC(minFree);
			goto l1;
		}
	l1:	/* end sufficientSpaceToAllocate: */;
	} else {
		/* begin sufficientSpaceToAllocate: */
		minFree1 = (foo->lowSpaceThreshold + (2500 + 0)) + BaseHeaderSize;
		if ((((unsigned ) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((unsigned ) minFree1))) {
			okay = 1;
			goto l2;
		} else {
			okay = sufficientSpaceAfterGC(minFree1);
			goto l2;
		}
	l2:	/* end sufficientSpaceToAllocate: */;
	}
	spaceOkay = okay;
l3:	/* end sufficientSpaceToInstantiate:indexableSize: */;
	/* begin success: */
	foo->successFlag = spaceOkay && foo->successFlag;
	if (foo->successFlag) {
		/* begin push: */
		object = instantiateClassindexableSize(popStack(), 0);
		longAtput(sp = foo->stackPointer + 4, object);
		foo->stackPointer = sp;
	}
}

int primitiveNewMethod(void) {
register struct foo * foo = &fum;
    int theMethod;
    int literalCount;
    int i;
    int bytecodeCount;
    int size;
    int class;
    int header;
    int valuePointer;
    int top;
    int integerPointer;
    int top1;
    int top2;
    int sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	header = top;
	/* begin popInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
		foo->stackPointer += 2 * 4;
	}
	/* begin popStack */
	top2 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	class = top2;
	size = ((((((unsigned) header) >> 10) & 255) + 1) * 4) + bytecodeCount;
	theMethod = instantiateClassindexableSize(class, size);
	/* begin storePointer:ofObject:withValue: */
	if (theMethod < foo->youngStart) {
		possibleRootStoreIntovalue(theMethod, header);
	}
	longAtput(((((char *) theMethod)) + BaseHeaderSize) + (HeaderIndex << 2), header);
	literalCount = (((unsigned) header) >> 10) & 255;
	for (i = 1; i <= literalCount; i += 1) {
		/* begin storePointer:ofObject:withValue: */
		valuePointer = foo->nilObj;
		if (theMethod < foo->youngStart) {
			possibleRootStoreIntovalue(theMethod, valuePointer);
		}
		longAtput(((((char *) theMethod)) + BaseHeaderSize) + (i << 2), valuePointer);
	}
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, theMethod);
	foo->stackPointer = sp;
}


/*	Allocate a new indexable instance. Fail if the allocation would leave less than lowSpaceThreshold bytes free. */

int primitiveNewWithArg(void) {
register struct foo * foo = &fum;
    int spaceOkay;
    int size;
    int class;
    int oop;
    int sp;
    int okay;
    int format;
    int minFree;
    int minFree1;

	size = positive32BitValueOf(longAt(foo->stackPointer));
	class = longAt(foo->stackPointer - (1 * 4));
	/* begin success: */
	foo->successFlag = (size >= 0) && foo->successFlag;
	if (foo->successFlag) {
		/* begin sufficientSpaceToInstantiate:indexableSize: */
		format = (((unsigned) ((longAt(((((char *) class)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1)) >> 8) & 15;
		if (((((unsigned ) size)) > 0) && (format < 2)) {
			spaceOkay = 0;
			goto l3;
		}
		if (format < 8) {
			/* begin sufficientSpaceToAllocate: */
			minFree = (foo->lowSpaceThreshold + (2500 + (size * 4))) + BaseHeaderSize;
			if ((((unsigned ) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((unsigned ) minFree))) {
				okay = 1;
				goto l1;
			} else {
				okay = sufficientSpaceAfterGC(minFree);
				goto l1;
			}
		l1:	/* end sufficientSpaceToAllocate: */;
		} else {
			/* begin sufficientSpaceToAllocate: */
			minFree1 = (foo->lowSpaceThreshold + (2500 + size)) + BaseHeaderSize;
			if ((((unsigned ) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= (((unsigned ) minFree1))) {
				okay = 1;
				goto l2;
			} else {
				okay = sufficientSpaceAfterGC(minFree1);
				goto l2;
			}
		l2:	/* end sufficientSpaceToAllocate: */;
		}
		spaceOkay = okay;
	l3:	/* end sufficientSpaceToInstantiate:indexableSize: */;
		/* begin success: */
		foo->successFlag = spaceOkay && foo->successFlag;
		class = longAt(foo->stackPointer - (1 * 4));
	}
	if (foo->successFlag) {
		/* begin pop:thenPush: */
		oop = instantiateClassindexableSize(class, size);
		longAtput(sp = foo->stackPointer - ((2 - 1) * 4), oop);
		foo->stackPointer = sp;
	}
}


/*	PrimitiveNext will succeed only if the stream's array is in the atCache.
	Otherwise failure will lead to proper message lookup of at: and
	subsequent installation in the cache if appropriate. */

int primitiveNext(void) {
register struct foo * foo = &fum;
    int result;
    int stream;
    int atIx;
    int index;
    int limit;
    int array;
    int sp;

	stream = longAt(foo->stackPointer);
	if (!((((stream & 1) == 0) && (((((unsigned) (longAt(stream))) >> 8) & 15) <= 4)) && ((lengthOf(stream)) >= (StreamReadLimitIndex + 1)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	array = longAt(((((char *) stream)) + BaseHeaderSize) + (StreamArrayIndex << 2));
	index = fetchIntegerofObject(StreamIndexIndex, stream);
	limit = fetchIntegerofObject(StreamReadLimitIndex, stream);
	atIx = array & AtCacheMask;
	if (!((index < limit) && ((atCache[atIx + AtCacheOop]) == array))) {
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
		if ((index ^ (index << 1)) >= 0) {
			longAtput(((((char *) stream)) + BaseHeaderSize) + (StreamIndexIndex << 2), ((index << 1) | 1));
		} else {
			/* begin primitiveFail */
			foo->successFlag = 0;
		}
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((1 - 1) * 4), result);
		foo->stackPointer = sp;
		return null;
	}
}

int primitiveNextInstance(void) {
register struct foo * foo = &fum;
    int object;
    int instance;
    int sp;
    int thisObj;
    int classPointer;
    int thisClass;
    int ccIndex;
    int ccIndex1;

	object = longAt(foo->stackPointer);
	/* begin instanceAfter: */
	/* begin fetchClassOf: */
	if ((object & 1)) {
		classPointer = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l3;
	}
	ccIndex1 = (((unsigned) (longAt(object))) >> 12) & 31;
	if (ccIndex1 == 0) {
		classPointer = (longAt(object - 4)) & AllButTypeMask;
		goto l3;
	} else {
		classPointer = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex1 - 1) << 2));
		goto l3;
	}
l3:	/* end fetchClassOf: */;
	thisObj = accessibleObjectAfter(object);
	while (!(thisObj == null)) {
		/* begin fetchClassOf: */
		if ((thisObj & 1)) {
			thisClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
			goto l2;
		}
		ccIndex = (((unsigned) (longAt(thisObj))) >> 12) & 31;
		if (ccIndex == 0) {
			thisClass = (longAt(thisObj - 4)) & AllButTypeMask;
			goto l2;
		} else {
			thisClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
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
		longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * 4), instance);
		foo->stackPointer = sp;
	}
}


/*	Return the object following the receiver in the heap. Return the SmallInteger zero when there are no more objects. */

int primitiveNextObject(void) {
register struct foo * foo = &fum;
    int object;
    int instance;
    int sp;
    int sp1;

	object = longAt(foo->stackPointer);
	instance = accessibleObjectAfter(object);
	if (instance == null) {
		/* begin pop: */
		foo->stackPointer -= (foo->argumentCount + 1) * 4;
		/* begin pushInteger: */
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, ((0 << 1) | 1));
		foo->stackPointer = sp;
	} else {
		/* begin pop:thenPush: */
		longAtput(sp1 = foo->stackPointer - (((foo->argumentCount + 1) - 1) * 4), instance);
		foo->stackPointer = sp1;
	}
}


/*	PrimitiveNextPut will succeed only if the stream's array is in the atPutCache.
	Otherwise failure will lead to proper message lookup of at:put: and
	subsequent installation in the cache if appropriate. */

int primitiveNextPut(void) {
register struct foo * foo = &fum;
    int stream;
    int value;
    int atIx;
    int index;
    int limit;
    int array;
    int sp;
    int fmt;
    int stSize;
    int fixedFields;
    int valToPut;

	value = longAt(foo->stackPointer);
	stream = longAt(foo->stackPointer - (1 * 4));
	if (!((((stream & 1) == 0) && (((((unsigned) (longAt(stream))) >> 8) & 15) <= 4)) && ((lengthOf(stream)) >= (StreamReadLimitIndex + 1)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	array = longAt(((((char *) stream)) + BaseHeaderSize) + (StreamArrayIndex << 2));
	index = fetchIntegerofObject(StreamIndexIndex, stream);
	limit = fetchIntegerofObject(StreamReadLimitIndex, stream);
	atIx = (array & AtCacheMask) + AtPutBase;
	if (!((index < limit) && ((atCache[atIx + AtCacheOop]) == array))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	index += 1;
	/* begin commonVariable:at:put:cacheIndex: */
	stSize = atCache[atIx + AtCacheSize];
	if (((((unsigned ) index)) >= 1) && ((((unsigned ) index)) <= (((unsigned ) stSize)))) {
		fmt = atCache[atIx + AtCacheFmt];
		if (fmt <= 4) {
			fixedFields = atCache[atIx + AtCacheFixedFields];
			/* begin storePointer:ofObject:withValue: */
			if (array < foo->youngStart) {
				possibleRootStoreIntovalue(array, value);
			}
			longAtput(((((char *) array)) + BaseHeaderSize) + (((index + fixedFields) - 1) << 2), value);
			goto l1;
		}
		if (fmt < 8) {
			valToPut = positive32BitValueOf(value);
			if (foo->successFlag) {
				longAtput(((((char *) array)) + BaseHeaderSize) + ((index - 1) << 2), valToPut);
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
			byteAtput(((((char *) array)) + BaseHeaderSize) + (index - 1), valToPut);
			goto l1;
		}
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
l1:	/* end commonVariable:at:put:cacheIndex: */;
	if (foo->successFlag) {
		/* begin storeInteger:ofObject:withValue: */
		if ((index ^ (index << 1)) >= 0) {
			longAtput(((((char *) stream)) + BaseHeaderSize) + (StreamIndexIndex << 2), ((index << 1) | 1));
		} else {
			/* begin primitiveFail */
			foo->successFlag = 0;
		}
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((2 - 1) * 4), value);
		foo->stackPointer = sp;
		return null;
	}
}


/*	A placeholder for primitives that haven't been implemented or are being withdrawn gradually. Just absorbs any arguments and returns the receiver. */

int primitiveNoop(void) {
register struct foo * foo = &fum;
	/* begin pop: */
	foo->stackPointer -= foo->argumentCount * 4;
}

int primitiveNotEqual(void) {
register struct foo * foo = &fum;
    int result;
    int integerArgument;
    int integerReceiver;
    int top;
    int top1;
    int sp;
    int sp1;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	integerArgument = top;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	integerReceiver = top1;
	result = !(compare31or32Bitsequal(integerReceiver, integerArgument));
	/* begin checkBooleanResult: */
	if (foo->successFlag) {
		/* begin pushBool: */
		if (result) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}


/*	Defined for CompiledMethods only */

int primitiveObjectAt(void) {
register struct foo * foo = &fum;
    int thisReceiver;
    int index;
    int sp;
    int integerPointer;
    int top;
    int top1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
	foo->stackPointer -= 4;
	thisReceiver = top1;
	/* begin success: */
	foo->successFlag = (index > 0) && foo->successFlag;
	/* begin success: */
	foo->successFlag = (index <= (((((unsigned) (longAt(((((char *) thisReceiver)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 10) & 255) + LiteralStart)) && foo->successFlag;
	if (foo->successFlag) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, longAt(((((char *) thisReceiver)) + BaseHeaderSize) + ((index - 1) << 2)));
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}


/*	Defined for CompiledMethods only */

int primitiveObjectAtPut(void) {
register struct foo * foo = &fum;
    int newValue;
    int thisReceiver;
    int index;
    int sp;
    int top;
    int integerPointer;
    int top1;
    int top2;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	newValue = top;
	/* begin popInteger */
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
	foo->stackPointer -= 4;
	thisReceiver = top2;
	/* begin success: */
	foo->successFlag = (index > 0) && foo->successFlag;
	/* begin success: */
	foo->successFlag = (index <= (((((unsigned) (longAt(((((char *) thisReceiver)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 10) & 255) + LiteralStart)) && foo->successFlag;
	if (foo->successFlag) {
		/* begin storePointer:ofObject:withValue: */
		if (thisReceiver < foo->youngStart) {
			possibleRootStoreIntovalue(thisReceiver, newValue);
		}
		longAtput(((((char *) thisReceiver)) + BaseHeaderSize) + ((index - 1) << 2), newValue);
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, newValue);
		foo->stackPointer = sp;
	} else {
		/* begin unPop: */
		foo->stackPointer += 3 * 4;
	}
}

int primitiveObjectPointsTo(void) {
register struct foo * foo = &fum;
    int thang;
    int lastField;
    int rcvr;
    int i;
    int top;
    int top1;
    int sp;
    int sp1;
    int sp2;
    int sp3;
    int sp4;
    int sp5;
    int fmt;
    int sz;
    int methodHeader;
    int contextSize;
    int header;
    int sp6;
    int header1;
    int type;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	thang = top;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	rcvr = top1;
	if ((rcvr & 1)) {
		/* begin pushBool: */
		if (0) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
		return null;
	}
	/* begin lastPointerOf: */
	header = longAt(rcvr);
	fmt = (((unsigned) header) >> 8) & 15;
	if (fmt <= 4) {
		if ((fmt == 3) && ((((((unsigned) header) >> 12) & 31) == 13) || ((((((unsigned) header) >> 12) & 31) == 14) || (((((unsigned) header) >> 12) & 31) == 4)))) {
			/* begin fetchStackPointerOf: */
			sp6 = longAt(((((char *) rcvr)) + BaseHeaderSize) + (StackPointerIndex << 2));
			if (!((sp6 & 1))) {
				contextSize = 0;
				goto l1;
			}
			contextSize = (sp6 >> 1);
		l1:	/* end fetchStackPointerOf: */;
			lastField = (CtxtTempFrameStart + contextSize) * 4;
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
			sz = (longAt(rcvr - 8)) & AllButTypeMask;
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
	lastField = (((((unsigned) methodHeader) >> 10) & 255) * 4) + BaseHeaderSize;
l4:	/* end lastPointerOf: */;
	for (i = BaseHeaderSize; i <= lastField; i += 4) {
		if ((longAt(rcvr + i)) == thang) {
			/* begin pushBool: */
			if (1) {
				/* begin push: */
				longAtput(sp2 = foo->stackPointer + 4, foo->trueObj);
				foo->stackPointer = sp2;
			} else {
				/* begin push: */
				longAtput(sp3 = foo->stackPointer + 4, foo->falseObj);
				foo->stackPointer = sp3;
			}
			return null;
		}
	}
	/* begin pushBool: */
	if (0) {
		/* begin push: */
		longAtput(sp4 = foo->stackPointer + 4, foo->trueObj);
		foo->stackPointer = sp4;
	} else {
		/* begin push: */
		longAtput(sp5 = foo->stackPointer + 4, foo->falseObj);
		foo->stackPointer = sp5;
	}
}


/*	Primitive. Invoke an obsolete indexed primitive. */

int primitiveObsoleteIndexedPrimitive(void) {
register struct foo * foo = &fum;
    int functionAddress;
    char *pluginName;
    char *functionName;

	functionAddress = ((int) ((obsoleteIndexedPrimitiveTable[foo->primitiveIndex])[2]));
	if (!(functionAddress == null)) {
		return ((int (*) (void))functionAddress)();
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
		return ((int (*) (void))functionAddress)();
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
	return null;
}

int primitivePerform(void) {
register struct foo * foo = &fum;
    int lookupClass;
    int performSelector;
    int performMethod;
    int i;
    int newReceiver;
    int selectorIndex;
    int successValue;
    int fieldIndex;
    int oop;
    int valuePointer;
    int oop1;
    int valuePointer1;
    int fromIndex;
    int toIndex;
    int lastFrom;
    int primIdx;
    int nArgs;
    int delta;
    int ccIndex;
    int initialIP;
    int tempCount;
    int newContext;
    int where;
    int i1;
    int methodHeader;
    int nilOop;
    int tmp;

	performSelector = foo->messageSelector;
	performMethod = foo->newMethod;
	foo->messageSelector = longAt(foo->stackPointer - ((foo->argumentCount - 1) * 4));

	/* NOTE: the following lookup may fail and be converted to #doesNotUnderstand:, so we must adjust argumentCount and slide args now, so that would work. */
	/* Slide arguments down over selector */

	newReceiver = longAt(foo->stackPointer - (foo->argumentCount * 4));
	foo->argumentCount -= 1;
	selectorIndex = (((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - foo->argumentCount;
	/* begin transfer:fromIndex:ofObject:toIndex:ofObject: */
	fromIndex = foo->activeContext + ((selectorIndex + 1) * 4);
	toIndex = foo->activeContext + (selectorIndex * 4);
	lastFrom = fromIndex + (foo->argumentCount * 4);
	while (fromIndex < lastFrom) {
		fromIndex += 4;
		toIndex += 4;
		longAtput(toIndex, longAt(fromIndex));
	}
	/* begin pop: */
	foo->stackPointer -= 1 * 4;
	/* begin fetchClassOf: */
	if ((newReceiver & 1)) {
		lookupClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l2;
	}
	ccIndex = (((unsigned) (longAt(newReceiver))) >> 12) & 31;
	if (ccIndex == 0) {
		lookupClass = (longAt(newReceiver - 4)) & AllButTypeMask;
		goto l2;
	} else {
		lookupClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l2;
	}
l2:	/* end fetchClassOf: */;
	findNewMethodInClass(lookupClass);
	if (((((unsigned) (longAt(foo->newMethod))) >> 8) & 15) >= 12) {
		/* begin success: */
		successValue = ((((unsigned) (longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 25) & 15) == foo->argumentCount;
		foo->successFlag = successValue && foo->successFlag;
	}
	if (foo->successFlag) {
		/* begin executeNewMethod */
		if (foo->primitiveIndex > 0) {
			/* begin primitiveResponse */
			if (DoBalanceChecks) {
				nArgs = foo->argumentCount;
				delta = foo->stackPointer - foo->activeContext;
			}
			primIdx = foo->primitiveIndex;
			foo->successFlag = 1;
			dispatchFunctionPointerOnin(primIdx, primitiveTable);
			if (DoBalanceChecks) {
				if (!(balancedStackafterPrimitivewithArgs(delta, primIdx, nArgs))) {
					printUnbalancedStack(primIdx);
				}
			}
			if (foo->successFlag) {
				goto l1;
			}
		}
		/* begin activateNewMethod */
		methodHeader = longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2));
		newContext = allocateOrRecycleContext(methodHeader & LargeContextBit);
		initialIP = ((LiteralStart + ((((unsigned) methodHeader) >> 10) & 255)) * 4) + 1;
		tempCount = (((unsigned) methodHeader) >> 19) & 63;
		where = newContext + BaseHeaderSize;
		longAtput(where + (SenderIndex << 2), foo->activeContext);
		longAtput(where + (InstructionPointerIndex << 2), ((initialIP << 1) | 1));
		longAtput(where + (StackPointerIndex << 2), ((tempCount << 1) | 1));
		longAtput(where + (MethodIndex << 2), foo->newMethod);
		for (i1 = 0; i1 <= foo->argumentCount; i1 += 1) {
			longAtput(where + ((ReceiverIndex + i1) << 2), longAt(foo->stackPointer - ((foo->argumentCount - i1) * 4)));
		}
		nilOop = foo->nilObj;
		for (i1 = ((foo->argumentCount + 1) + ReceiverIndex); i1 <= (tempCount + ReceiverIndex); i1 += 1) {
			longAtput(where + (i1 << 2), nilOop);
		}
		/* begin pop: */
		foo->stackPointer -= (foo->argumentCount + 1) * 4;
		foo->reclaimableContextCount += 1;
		/* begin newActiveContext: */
		/* begin storeContextRegisters: */
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (StackPointerIndex << 2), (((((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - TempFrameStart) + 1) << 1) | 1));
		if (newContext < foo->youngStart) {
			beRootIfOld(newContext);
		}
		foo->activeContext = newContext;
		/* begin fetchContextRegisters: */
		tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (MethodIndex << 2));
		if ((tmp & 1)) {
			tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (HomeIndex << 2));
			if (tmp < foo->youngStart) {
				beRootIfOld(tmp);
			}
		} else {
			tmp = newContext;
		}
		foo->theHomeContext = tmp;
		foo->receiver = longAt(((((char *) tmp)) + BaseHeaderSize) + (ReceiverIndex << 2));
		foo->method = longAt(((((char *) tmp)) + BaseHeaderSize) + (MethodIndex << 2));
		tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2))) >> 1);
		foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
		tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (StackPointerIndex << 2))) >> 1);
		foo->stackPointer = (newContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * 4);
		/* begin quickCheckForInterrupts */
		if ((foo->interruptCheckCounter -= 1) <= 0) {
			checkForInterrupts();
		}
	l1:	/* end executeNewMethod */;
		foo->successFlag = 1;
	} else {
		for (i = 1; i <= foo->argumentCount; i += 1) {
			/* begin storePointer:ofObject:withValue: */
			fieldIndex = ((foo->argumentCount - i) + 1) + selectorIndex;
			oop = foo->activeContext;
			valuePointer = longAt(((((char *) foo->activeContext)) + BaseHeaderSize) + (((foo->argumentCount - i) + selectorIndex) << 2));
			if (oop < foo->youngStart) {
				possibleRootStoreIntovalue(oop, valuePointer);
			}
			longAtput(((((char *) oop)) + BaseHeaderSize) + (fieldIndex << 2), valuePointer);
		}
		/* begin unPop: */
		foo->stackPointer += 1 * 4;
		/* begin storePointer:ofObject:withValue: */
		oop1 = foo->activeContext;
		valuePointer1 = foo->messageSelector;
		if (oop1 < foo->youngStart) {
			possibleRootStoreIntovalue(oop1, valuePointer1);
		}
		longAtput(((((char *) oop1)) + BaseHeaderSize) + (selectorIndex << 2), valuePointer1);
		foo->argumentCount += 1;
		foo->newMethod = performMethod;
		foo->messageSelector = performSelector;
	}
}


/*	Common routine used by perform:withArgs: and perform:withArgs:inSuperclass: */
/*	NOTE:  The case of doesNotUnderstand: is not a failure to perform.
	The only failures are arg types and consistency of argumentCount. */

int primitivePerformAt(int lookupClass) {
register struct foo * foo = &fum;
    int performSelector;
    int arraySize;
    int cntxSize;
    int performArgCount;
    int performMethod;
    int argumentArray;
    int index;
    int sz;
    int header;
    int sz1;
    int header1;
    int sp;
    int primIdx;
    int nArgs;
    int delta;
    int sp1;
    int sp2;
    int top;
    int top1;
    int initialIP;
    int tempCount;
    int newContext;
    int where;
    int i;
    int methodHeader;
    int nilOop;
    int tmp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	argumentArray = top;
	if (!(((argumentArray & 1) == 0) && (((((unsigned) (longAt(argumentArray))) >> 8) & 15) == 2))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (foo->successFlag) {
		/* begin fetchWordLengthOf: */
		/* begin sizeBitsOf: */
		header = longAt(argumentArray);
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(argumentArray - 8)) & AllButTypeMask;
			goto l1;
		} else {
			sz = header & SizeMask;
			goto l1;
		}
	l1:	/* end sizeBitsOf: */;
		arraySize = ((unsigned) (sz - BaseHeaderSize)) >> 2;
		/* begin fetchWordLengthOf: */
		/* begin sizeBitsOf: */
		header1 = longAt(foo->activeContext);
		if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
			sz1 = (longAt(foo->activeContext - 8)) & AllButTypeMask;
			goto l2;
		} else {
			sz1 = header1 & SizeMask;
			goto l2;
		}
	l2:	/* end sizeBitsOf: */;
		cntxSize = ((unsigned) (sz1 - BaseHeaderSize)) >> 2;
		/* begin success: */
		foo->successFlag = (((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) + arraySize) < cntxSize) && foo->successFlag;
	}
	if (!(foo->successFlag)) {
		/* begin unPop: */
		foo->stackPointer += 1 * 4;
		return null;
	}
	performSelector = foo->messageSelector;
	performMethod = foo->newMethod;
	performArgCount = foo->argumentCount;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	foo->messageSelector = top1;
	index = 1;
	while (index <= arraySize) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, longAt(((((char *) argumentArray)) + BaseHeaderSize) + ((index - 1) << 2)));
		foo->stackPointer = sp;
		index += 1;
	}
	foo->argumentCount = arraySize;
	findNewMethodInClass(lookupClass);
	if (((((unsigned) (longAt(foo->newMethod))) >> 8) & 15) >= 12) {
		/* begin success: */
		foo->successFlag = (((((unsigned) (longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2)))) >> 25) & 15) == foo->argumentCount) && foo->successFlag;
	}
	if (foo->successFlag) {
		/* begin executeNewMethod */
		if (foo->primitiveIndex > 0) {
			/* begin primitiveResponse */
			if (DoBalanceChecks) {
				nArgs = foo->argumentCount;
				delta = foo->stackPointer - foo->activeContext;
			}
			primIdx = foo->primitiveIndex;
			foo->successFlag = 1;
			dispatchFunctionPointerOnin(primIdx, primitiveTable);
			if (DoBalanceChecks) {
				if (!(balancedStackafterPrimitivewithArgs(delta, primIdx, nArgs))) {
					printUnbalancedStack(primIdx);
				}
			}
			if (foo->successFlag) {
				goto l3;
			}
		}
		/* begin activateNewMethod */
		methodHeader = longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + (HeaderIndex << 2));
		newContext = allocateOrRecycleContext(methodHeader & LargeContextBit);
		initialIP = ((LiteralStart + ((((unsigned) methodHeader) >> 10) & 255)) * 4) + 1;
		tempCount = (((unsigned) methodHeader) >> 19) & 63;
		where = newContext + BaseHeaderSize;
		longAtput(where + (SenderIndex << 2), foo->activeContext);
		longAtput(where + (InstructionPointerIndex << 2), ((initialIP << 1) | 1));
		longAtput(where + (StackPointerIndex << 2), ((tempCount << 1) | 1));
		longAtput(where + (MethodIndex << 2), foo->newMethod);
		for (i = 0; i <= foo->argumentCount; i += 1) {
			longAtput(where + ((ReceiverIndex + i) << 2), longAt(foo->stackPointer - ((foo->argumentCount - i) * 4)));
		}
		nilOop = foo->nilObj;
		for (i = ((foo->argumentCount + 1) + ReceiverIndex); i <= (tempCount + ReceiverIndex); i += 1) {
			longAtput(where + (i << 2), nilOop);
		}
		/* begin pop: */
		foo->stackPointer -= (foo->argumentCount + 1) * 4;
		foo->reclaimableContextCount += 1;
		/* begin newActiveContext: */
		/* begin storeContextRegisters: */
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (StackPointerIndex << 2), (((((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - TempFrameStart) + 1) << 1) | 1));
		if (newContext < foo->youngStart) {
			beRootIfOld(newContext);
		}
		foo->activeContext = newContext;
		/* begin fetchContextRegisters: */
		tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (MethodIndex << 2));
		if ((tmp & 1)) {
			tmp = longAt(((((char *) newContext)) + BaseHeaderSize) + (HomeIndex << 2));
			if (tmp < foo->youngStart) {
				beRootIfOld(tmp);
			}
		} else {
			tmp = newContext;
		}
		foo->theHomeContext = tmp;
		foo->receiver = longAt(((((char *) tmp)) + BaseHeaderSize) + (ReceiverIndex << 2));
		foo->method = longAt(((((char *) tmp)) + BaseHeaderSize) + (MethodIndex << 2));
		tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2))) >> 1);
		foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
		tmp = ((longAt(((((char *) newContext)) + BaseHeaderSize) + (StackPointerIndex << 2))) >> 1);
		foo->stackPointer = (newContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * 4);
		/* begin quickCheckForInterrupts */
		if ((foo->interruptCheckCounter -= 1) <= 0) {
			checkForInterrupts();
		}
	l3:	/* end executeNewMethod */;
		foo->successFlag = 1;
	} else {
		/* begin pop: */
		foo->stackPointer -= foo->argumentCount * 4;
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + 4, foo->messageSelector);
		foo->stackPointer = sp1;
		/* begin push: */
		longAtput(sp2 = foo->stackPointer + 4, argumentArray);
		foo->stackPointer = sp2;
		foo->messageSelector = performSelector;
		foo->newMethod = performMethod;
		foo->argumentCount = performArgCount;
	}
}

int primitivePerformInSuperclass(void) {
register struct foo * foo = &fum;
    int lookupClass;
    int rcvr;
    int currentClass;
    int sp;
    int top;
    int ccIndex;

	lookupClass = longAt(foo->stackPointer);
	rcvr = longAt(foo->stackPointer - (foo->argumentCount * 4));
	/* begin fetchClassOf: */
	if ((rcvr & 1)) {
		currentClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(rcvr))) >> 12) & 31;
	if (ccIndex == 0) {
		currentClass = (longAt(rcvr - 4)) & AllButTypeMask;
		goto l1;
	} else {
		currentClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	while (currentClass != lookupClass) {
		currentClass = longAt(((((char *) currentClass)) + BaseHeaderSize) + (SuperclassIndex << 2));
		if (currentClass == foo->nilObj) {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	primitivePerformAt(lookupClass);
	if (!(foo->successFlag)) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, lookupClass);
		foo->stackPointer = sp;
	}
}

int primitivePerformWithArgs(void) {
register struct foo * foo = &fum;
    int lookupClass;
    int rcvr;
    int ccIndex;

	rcvr = longAt(foo->stackPointer - (foo->argumentCount * 4));
	/* begin fetchClassOf: */
	if ((rcvr & 1)) {
		lookupClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(rcvr))) >> 12) & 31;
	if (ccIndex == 0) {
		lookupClass = (longAt(rcvr - 4)) & AllButTypeMask;
		goto l1;
	} else {
		lookupClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	primitivePerformAt(lookupClass);
}

int primitivePushFalse(void) {
register struct foo * foo = &fum;
    int top;
    int sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, foo->falseObj);
	foo->stackPointer = sp;
}

int primitivePushMinusOne(void) {
register struct foo * foo = &fum;
    int top;
    int sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, ConstMinusOne);
	foo->stackPointer = sp;
}

int primitivePushNil(void) {
register struct foo * foo = &fum;
    int top;
    int sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, foo->nilObj);
	foo->stackPointer = sp;
}

int primitivePushOne(void) {
register struct foo * foo = &fum;
    int top;
    int sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, ConstOne);
	foo->stackPointer = sp;
}


/*		no-op, really...
	thisReceiver _ self popStack.
	self push: thisReceiver
 */

int primitivePushSelf(void) {
}

int primitivePushTrue(void) {
register struct foo * foo = &fum;
    int top;
    int sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, foo->trueObj);
	foo->stackPointer = sp;
}

int primitivePushTwo(void) {
register struct foo * foo = &fum;
    int top;
    int sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, ConstTwo);
	foo->stackPointer = sp;
}

int primitivePushZero(void) {
register struct foo * foo = &fum;
    int top;
    int sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, ConstZero);
	foo->stackPointer = sp;
}

int primitiveQuit(void) {
	ioExit();
}


/*	Rounds negative results towards zero. */

int primitiveQuo(void) {
register struct foo * foo = &fum;
    int integerRcvr;
    int integerResult;
    int integerArg;
    int integerPointer;
    int integerPointer1;
    int sp;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (1 * 4));
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
	integerPointer1 = longAt(foo->stackPointer - (0 * 4));
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
		if ((integerResult ^ (integerResult << 1)) >= 0) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - ((2 - 1) * 4), ((integerResult << 1) | 1));
			foo->stackPointer = sp;
		} else {
			foo->successFlag = 0;
		}
	}
}


/*	Relinquish the processor for up to the given number of microseconds. The exact behavior of this primitive is platform dependent. */

int primitiveRelinquishProcessor(void) {
register struct foo * foo = &fum;
    int microSecs;
    int integerPointer;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * 4));
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
		foo->stackPointer -= 1 * 4;
	}
}


/*	put this process on the scheduler's lists thus allowing it to proceed next time there is a chance for processes of it's priority level */

int primitiveResume(void) {
register struct foo * foo = &fum;
    int proc;


	/* rcvr */
	/* self success: ((self fetchClassOf: proc) = (self splObj: ClassProcess)). */

	proc = longAt(foo->stackPointer);
	if (foo->successFlag) {
		resume(proc);
	}
}


/*	The character scanner primitive. */

int primitiveScanCharacters(void) {
register struct foo * foo = &fum;
    int scanStopIndex;
    int sourceString;
    int rcvr;
    int glyphIndex;
    int scanXTable;
    int nextDestX;
    int maxGlyph;
    int scanStartIndex;
    int scanLastIndex;
    int scanRightX;
    int kernDelta;
    int ascii;
    int scanMap;
    int stops;
    int nilOop;
    int stopReason;
    int scanDestX;
    int sourceX;
    int sourceX2;
    int sp;
    int sp1;
    int integerPointer;
    int oop;
    int integerPointer1;
    int oop1;
    int integerPointer2;
    int integerPointer3;
    int oop2;
    int sp2;

	if (!(foo->argumentCount == 6)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * 4));
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
	oop = longAt(foo->stackPointer - (1 * 4));
	if ((oop & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		stops = null;
		goto l2;
	}
	stops = oop;
l2:	/* end stackObjectValue: */;
	if (!(((stops & 1) == 0) && (((((unsigned) (longAt(stops))) >> 8) & 15) == 2))) {
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
	integerPointer1 = longAt(foo->stackPointer - (2 * 4));
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
	oop1 = longAt(foo->stackPointer - (3 * 4));
	if ((oop1 & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		sourceString = null;
		goto l4;
	}
	sourceString = oop1;
l4:	/* end stackObjectValue: */;
	if (!(((sourceString & 1) == 0) && (((((unsigned) (longAt(sourceString))) >> 8) & 15) >= 8))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin stackIntegerValue: */
	integerPointer2 = longAt(foo->stackPointer - (4 * 4));
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
	integerPointer3 = longAt(foo->stackPointer - (5 * 4));
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
	oop2 = longAt(foo->stackPointer - (6 * 4));
	if ((oop2 & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		rcvr = null;
		goto l7;
	}
	rcvr = oop2;
l7:	/* end stackObjectValue: */;
	if (!((((rcvr & 1) == 0) && (((((unsigned) (longAt(rcvr))) >> 8) & 15) <= 4)) && ((slotSizeOf(rcvr)) >= 4))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	scanDestX = fetchIntegerofObject(0, rcvr);
	scanLastIndex = fetchIntegerofObject(1, rcvr);
	scanXTable = longAt(((((char *) rcvr)) + BaseHeaderSize) + (2 << 2));
	scanMap = longAt(((((char *) rcvr)) + BaseHeaderSize) + (3 << 2));
	if (!((((scanXTable & 1) == 0) && (((((unsigned) (longAt(scanXTable))) >> 8) & 15) == 2)) && (((scanMap & 1) == 0) && (((((unsigned) (longAt(scanMap))) >> 8) & 15) == 2)))) {
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

		ascii = byteAt(((((char *) sourceString)) + BaseHeaderSize) + (scanLastIndex - 1));
		if (!((stopReason = longAt(((((char *) stops)) + BaseHeaderSize) + (ascii << 2))) == nilOop)) {
			if (!((scanDestX ^ (scanDestX << 1)) >= 0)) {
				/* begin primitiveFail */
				foo->successFlag = 0;
				return null;
			}
			/* begin storeInteger:ofObject:withValue: */
			if ((scanDestX ^ (scanDestX << 1)) >= 0) {
				longAtput(((((char *) rcvr)) + BaseHeaderSize) + (0 << 2), ((scanDestX << 1) | 1));
			} else {
				/* begin primitiveFail */
				foo->successFlag = 0;
			}
			/* begin storeInteger:ofObject:withValue: */
			if ((scanLastIndex ^ (scanLastIndex << 1)) >= 0) {
				longAtput(((((char *) rcvr)) + BaseHeaderSize) + (1 << 2), ((scanLastIndex << 1) | 1));
			} else {
				/* begin primitiveFail */
				foo->successFlag = 0;
			}
			/* begin pop: */
			foo->stackPointer -= 7 * 4;
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, stopReason);
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
			if (!((scanDestX ^ (scanDestX << 1)) >= 0)) {
				/* begin primitiveFail */
				foo->successFlag = 0;
				return null;
			}
			/* begin storeInteger:ofObject:withValue: */
			if ((scanDestX ^ (scanDestX << 1)) >= 0) {
				longAtput(((((char *) rcvr)) + BaseHeaderSize) + (0 << 2), ((scanDestX << 1) | 1));
			} else {
				/* begin primitiveFail */
				foo->successFlag = 0;
			}
			/* begin storeInteger:ofObject:withValue: */
			if ((scanLastIndex ^ (scanLastIndex << 1)) >= 0) {
				longAtput(((((char *) rcvr)) + BaseHeaderSize) + (1 << 2), ((scanLastIndex << 1) | 1));
			} else {
				/* begin primitiveFail */
				foo->successFlag = 0;
			}
			/* begin pop: */
			foo->stackPointer -= 7 * 4;
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, longAt(((((char *) stops)) + BaseHeaderSize) + ((CrossedX - 1) << 2)));
			foo->stackPointer = sp1;
			return null;
		}
		scanDestX = nextDestX + kernDelta;
		scanLastIndex += 1;
	}
	if (!((scanDestX ^ (scanDestX << 1)) >= 0)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin storeInteger:ofObject:withValue: */
	if ((scanDestX ^ (scanDestX << 1)) >= 0) {
		longAtput(((((char *) rcvr)) + BaseHeaderSize) + (0 << 2), ((scanDestX << 1) | 1));
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
	}
	/* begin storeInteger:ofObject:withValue: */
	if ((scanStopIndex ^ (scanStopIndex << 1)) >= 0) {
		longAtput(((((char *) rcvr)) + BaseHeaderSize) + (1 << 2), ((scanStopIndex << 1) | 1));
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
	}
	/* begin pop: */
	foo->stackPointer -= 7 * 4;
	/* begin push: */
	longAtput(sp2 = foo->stackPointer + 4, longAt(((((char *) stops)) + BaseHeaderSize) + ((EndOfRun - 1) << 2)));
	foo->stackPointer = sp2;
	return null;
}


/*	Return a SmallInteger indicating the current depth of the OS screen. Negative values are used to imply LSB type pixel format an there is some support in the VM for handling either MSB or LSB */

EXPORT(int) primitiveScreenDepth(void) {
register struct foo * foo = &fum;
    int depth;
    int sp;

	depth = ioScreenDepth();
	if (!foo->successFlag) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin pop: */
	foo->stackPointer -= 1 * 4;
	/* begin pushInteger: */
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, ((depth << 1) | 1));
	foo->stackPointer = sp;
}


/*	Return a point indicating the current size of the Smalltalk window. Currently there is a limit of 65535 in each direction because the point is encoded into a single 32bit value in the image header. This might well become a problem one day */

int primitiveScreenSize(void) {
register struct foo * foo = &fum;
    int pointWord;
    int object;
    int sp;
    int pointResult;

	/* begin pop: */
	foo->stackPointer -= 1 * 4;
	pointWord = ioScreenSize();
	/* begin push: */
	/* begin makePointwithxValue:yValue: */
	pointResult = instantiateSmallClasssizeInBytesfill(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassPoint << 2)), 12, foo->nilObj);
	/* begin storePointer:ofObject:withValue: */
	if (pointResult < foo->youngStart) {
		possibleRootStoreIntovalue(pointResult, ((((((unsigned) pointWord) >> 16) & 65535) << 1) | 1));
	}
	longAtput(((((char *) pointResult)) + BaseHeaderSize) + (XIndex << 2), ((((((unsigned) pointWord) >> 16) & 65535) << 1) | 1));
	/* begin storePointer:ofObject:withValue: */
	if (pointResult < foo->youngStart) {
		possibleRootStoreIntovalue(pointResult, (((pointWord & 65535) << 1) | 1));
	}
	longAtput(((((char *) pointResult)) + BaseHeaderSize) + (YIndex << 2), (((pointWord & 65535) << 1) | 1));
	object = pointResult;
	longAtput(sp = foo->stackPointer + 4, object);
	foo->stackPointer = sp;
}


/*	Return the number of seconds since January 1, 1901 as an integer. */

int primitiveSecondsClock(void) {
register struct foo * foo = &fum;
    int oop;
    int sp;

	/* begin pop:thenPush: */
	oop = positive32BitIntegerFor(ioSeconds());
	longAtput(sp = foo->stackPointer - ((1 - 1) * 4), oop);
	foo->stackPointer = sp;
}


/*	Set to OS to the requested display mode.
	See also DisplayScreen setDisplayDepth:extent:fullscreen: */

int primitiveSetDisplayMode(void) {
register struct foo * foo = &fum;
    int okay;
    int h;
    int w;
    int fsFlag;
    int d;
    int integerPointer;
    int integerPointer1;
    int integerPointer2;
    int sp;
    int sp1;

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
	integerPointer = longAt(foo->stackPointer - (1 * 4));
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
	integerPointer1 = longAt(foo->stackPointer - (2 * 4));
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
	integerPointer2 = longAt(foo->stackPointer - (3 * 4));
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
		foo->stackPointer -= 5 * 4;
		/* begin pushBool: */
		if (okay) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}


/*	On platforms that support it, set full-screen mode to the value of the boolean argument. */

int primitiveSetFullScreen(void) {
register struct foo * foo = &fum;
    int argOop;

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
		foo->stackPointer -= 1 * 4;
	}
}


/*	Set the user interrupt keycode. The keycode is an integer whose encoding is described in the comment for primitiveKbdNext. */

int primitiveSetInterruptKey(void) {
register struct foo * foo = &fum;
    int keycode;
    int integerPointer;
    int top;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
		foo->stackPointer += 1 * 4;
	}
}


/*	Treat the receiver, which can be indexible by either bytes or 
	words, as an array of signed 16-bit values. Return the 
	contents of the given index. Note that the index specifies the 
	i-th 16-bit entry, not the i-th byte or word. */

int primitiveShortAt(void) {
register struct foo * foo = &fum;
    int sz;
    int value;
    int rcvr;
    int index;
    int addr;
    int sp;
    int integerPointer;
    int successValue;
    int successValue1;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * 4));
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
	rcvr = longAt(foo->stackPointer - (1 * 4));
	/* begin success: */
	successValue = ((rcvr & 1) == 0) && (isWordsOrBytesNonInt(rcvr));
	foo->successFlag = successValue && foo->successFlag;
	if (!(foo->successFlag)) {
		return null;
	}

	/* number of 16-bit fields */

	sz = ((int) ((sizeBitsOf(rcvr)) - BaseHeaderSize) >> 1);
	/* begin success: */
	successValue1 = (index >= 1) && (index <= sz);
	foo->successFlag = successValue1 && foo->successFlag;
	if (foo->successFlag) {
		addr = (rcvr + BaseHeaderSize) + (2 * (index - 1));
		value = *((short int *) addr);
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
		/* begin pushInteger: */
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, ((value << 1) | 1));
		foo->stackPointer = sp;
	}
}


/*	Treat the receiver, which can be indexible by either bytes or 
	words, as an array of signed 16-bit values. Set the contents 
	of the given index to the given value. Note that the index 
	specifies the i-th 16-bit entry, not the i-th byte or word. */

int primitiveShortAtPut(void) {
register struct foo * foo = &fum;
    int sz;
    int value;
    int rcvr;
    int index;
    int addr;
    int integerPointer;
    int integerPointer1;
    int successValue;
    int successValue1;
    int successValue2;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * 4));
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
	integerPointer1 = longAt(foo->stackPointer - (1 * 4));
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
	rcvr = longAt(foo->stackPointer - (2 * 4));
	/* begin success: */
	successValue = ((rcvr & 1) == 0) && (isWordsOrBytesNonInt(rcvr));
	foo->successFlag = successValue && foo->successFlag;
	if (!(foo->successFlag)) {
		return null;
	}

	/* number of 16-bit fields */

	sz = ((int) ((sizeBitsOf(rcvr)) - BaseHeaderSize) >> 1);
	/* begin success: */
	successValue1 = (index >= 1) && (index <= sz);
	foo->successFlag = successValue1 && foo->successFlag;
	/* begin success: */
	successValue2 = (value >= -32768) && (value <= 32767);
	foo->successFlag = successValue2 && foo->successFlag;
	if (foo->successFlag) {
		addr = (rcvr + BaseHeaderSize) + (2 * (index - 1));
		*((short int *) addr) = value;
		/* begin pop: */
		foo->stackPointer -= 2 * 4;
	}
}


/*	Force the given rectangular section of the Display to be 
	copied to the screen. */

int primitiveShowDisplayRect(void) {
register struct foo * foo = &fum;
    int right;
    int left;
    int bottom;
    int top;
    int integerPointer;
    int integerPointer1;
    int integerPointer2;
    int integerPointer3;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * 4));
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
	integerPointer1 = longAt(foo->stackPointer - (1 * 4));
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
	integerPointer2 = longAt(foo->stackPointer - (2 * 4));
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
	integerPointer3 = longAt(foo->stackPointer - (3 * 4));
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
	displayBitsOfLeftTopRightBottom(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (TheDisplay << 2)), left, top, right, bottom);
	if (foo->successFlag) {
		ioForceDisplayUpdate();
		/* begin pop: */
		foo->stackPointer -= 4 * 4;
	}
}


/*	synchromously signal the semaphore. This may change the active process as a result */

int primitiveSignal(void) {
register struct foo * foo = &fum;
    int sema;
    int cl;
    int ccIndex;


	/* rcvr */

	sema = longAt(foo->stackPointer);
	/* begin assertClassOf:is: */
	if ((sema & 1)) {
		foo->successFlag = 0;
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(sema))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(sema - 4)) & AllButTypeMask;
	} else {
		cl = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassSemaphore << 2)))) && foo->successFlag;
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

int primitiveSignalAtBytesLeft(void) {
register struct foo * foo = &fum;
    int bytes;
    int integerPointer;
    int top;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
		foo->stackPointer += 1 * 4;
	}
}


/*	Cause the time semaphore, if one has been registered, to be signalled when the millisecond clock is greater than or equal to the given tick value. A tick value of zero turns off timer interrupts. */

int primitiveSignalAtMilliseconds(void) {
register struct foo * foo = &fum;
    int tick;
    int sema;
    int oop;
    int oop1;
    int valuePointer;
    int integerPointer;
    int top;
    int top1;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
	foo->stackPointer -= 4;
	sema = top1;
	if (foo->successFlag) {
		if ((fetchClassOf(sema)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassSemaphore << 2)))) {
			/* begin storePointer:ofObject:withValue: */
			oop = foo->specialObjectsOop;
			if (oop < foo->youngStart) {
				possibleRootStoreIntovalue(oop, sema);
			}
			longAtput(((((char *) oop)) + BaseHeaderSize) + (TheTimerSemaphore << 2), sema);
			foo->nextWakeupTick = tick;
		} else {
			/* begin storePointer:ofObject:withValue: */
			oop1 = foo->specialObjectsOop;
			valuePointer = foo->nilObj;
			if (oop1 < foo->youngStart) {
				possibleRootStoreIntovalue(oop1, valuePointer);
			}
			longAtput(((((char *) oop1)) + BaseHeaderSize) + (TheTimerSemaphore << 2), valuePointer);
			foo->nextWakeupTick = 0;
		}
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}

int primitiveSine(void) {
register struct foo * foo = &fum;
    double rcvr;

	rcvr = popFloat();
	if (foo->successFlag) {
		pushFloat(sin(rcvr));
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * 4;
	}
}

int primitiveSize(void) {
register struct foo * foo = &fum;
    int sz;
    int rcvr;
    int oop;
    int sp;

	rcvr = longAt(foo->stackPointer);
	if ((rcvr & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (((((unsigned) (longAt(rcvr))) >> 8) & 15) < 2) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	sz = stSizeOf(rcvr);
	if (foo->successFlag) {
		/* begin pop:thenPush: */
		oop = positive32BitIntegerFor(sz);
		longAtput(sp = foo->stackPointer - ((1 - 1) * 4), oop);
		foo->stackPointer = sp;
	}
}


/*	save a normal snapshot under the same name as it was loaded or rename it as per the last primitiveImageName */

int primitiveSnapshot(void) {
	return snapshot(0);
}


/*	save an embedded snapshot */

int primitiveSnapshotEmbedded(void) {
	return snapshot(1);
}

int primitiveSomeInstance(void) {
register struct foo * foo = &fum;
    int instance;
    int class;
    int sp;
    int thisObj;
    int thisClass;
    int ccIndex;
    int obj;
    int chunk;
    int sz;
    int header;

	class = longAt(foo->stackPointer);
	/* begin initialInstanceOf: */
	/* begin firstAccessibleObject */
	/* begin oopFromChunk: */
	chunk = startOfMemory();
	obj = chunk + (headerTypeBytes[(longAt(chunk)) & TypeMask]);
	while (obj < foo->endOfMemory) {
		if (!(((longAt(obj)) & TypeMask) == HeaderTypeFree)) {
			thisObj = obj;
			goto l3;
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if (obj >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(obj)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(obj)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(obj);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(obj - 8)) & AllButTypeMask;
				goto l4;
			} else {
				sz = header & SizeMask;
				goto l4;
			}
		l4:	/* end sizeBitsOf: */;
		}
		obj = (obj + sz) + (headerTypeBytes[(longAt(obj + sz)) & TypeMask]);
	}
	error("heap is empty");
l3:	/* end firstAccessibleObject */;
	while (!(thisObj == null)) {
		/* begin fetchClassOf: */
		if ((thisObj & 1)) {
			thisClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
			goto l2;
		}
		ccIndex = (((unsigned) (longAt(thisObj))) >> 12) & 31;
		if (ccIndex == 0) {
			thisClass = (longAt(thisObj - 4)) & AllButTypeMask;
			goto l2;
		} else {
			thisClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
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
		longAtput(sp = foo->stackPointer - (((foo->argumentCount + 1) - 1) * 4), instance);
		foo->stackPointer = sp;
	}
}


/*	Return the first object in the heap. */

int primitiveSomeObject(void) {
register struct foo * foo = &fum;
    int object;
    int sp;
    int obj;
    int sz;
    int header;
    int chunk;

	/* begin pop: */
	foo->stackPointer -= (foo->argumentCount + 1) * 4;
	/* begin push: */
	/* begin firstAccessibleObject */
	/* begin oopFromChunk: */
	chunk = startOfMemory();
	obj = chunk + (headerTypeBytes[(longAt(chunk)) & TypeMask]);
	while (obj < foo->endOfMemory) {
		if (!(((longAt(obj)) & TypeMask) == HeaderTypeFree)) {
			object = obj;
			goto l1;
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if (obj >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(obj)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(obj)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(obj);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(obj - 8)) & AllButTypeMask;
				goto l2;
			} else {
				sz = header & SizeMask;
				goto l2;
			}
		l2:	/* end sizeBitsOf: */;
		}
		obj = (obj + sz) + (headerTypeBytes[(longAt(obj + sz)) & TypeMask]);
	}
	error("heap is empty");
l1:	/* end firstAccessibleObject */;
	longAtput(sp = foo->stackPointer + 4, object);
	foo->stackPointer = sp;
}


/*	Return the oop of the SpecialObjectsArray. */

int primitiveSpecialObjectsOop(void) {
register struct foo * foo = &fum;
    int sp;

	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((1 - 1) * 4), foo->specialObjectsOop);
	foo->stackPointer = sp;
}

int primitiveSquareRoot(void) {
register struct foo * foo = &fum;
    double rcvr;

	rcvr = popFloat();
	/* begin success: */
	foo->successFlag = (rcvr >= 0.0) && foo->successFlag;
	if (foo->successFlag) {
		pushFloat(sqrt(rcvr));
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * 4;
	}
}


/*	This primitive is called from Squeak as...
		<imageSegment> storeSegmentFor: arrayOfRoots into: aWordArray outPointers: anArray. */
/*	This primitive will store a binary image segment (in the same format as the Squeak image file) of the receiver and every object in its proper tree of subParts (ie, that is not refered to from anywhere else outside the tree).  All pointers from within the tree to objects outside the tree will be copied into the array of outpointers.  In their place in the image segment will be an oop equal to the offset in the outPointer array (the first would be 4). but with the high bit set. */
/*	The primitive expects the array and wordArray to be more than adequately long.  In this case it returns normally, and truncates the two arrays to exactly the right size.  To simplify truncation, both incoming arrays are required to be 256 bytes or more long (ie with 3-word headers).  If either array is too small, the primitive will fail, but in no other case.

During operation of the primitive, it is necessary to convert from both internal and external oops to their mapped values.  To make this fast, the headers of the original objects in question are replaced by the mapped values (and this is noted by adding the forbidden XX header type).  Tables are kept of both kinds of oops, as well as of the original headers for restoration.

To be specific, there are two similar two-part tables, the outpointer array, and one in the upper fifth of the segmentWordArray.  Each grows oops from the bottom up, and preserved headers from halfway up.

In case of either success or failure, the headers must be restored.  In the event of primitive failure, the table of outpointers must also be nilled out (since the garbage in the high half will not have been discarded. */

int primitiveStoreImageSegment(void) {
register struct foo * foo = &fum;
    int hdrBaseIn;
    int lastIn;
    int firstIn;
    int doingClass;
    int versionOffset;
    int firstOut;
    int extraSize;
    int arrayOfRoots;
    int fieldPtr;
    int fieldOop;
    int lastOut;
    int lastPtr;
    int lastSeg;
    int segmentWordArray;
    int mapOop;
    int hdrTypeBits;
    int segOop;
    int savedYoungStart;
    int hdrBaseOut;
    int outPointerArray;
    int endSeg;
    int header;
    int i;
    int lastAddr;
    int i1;
    int lastAddr1;
    int i2;
    int lastAddr2;
    int i3;
    int lastAddr3;
    int out;
    int lastIn1;
    int in;
    int out1;
    int lastIn2;
    int in1;
    int sz;
    int header1;

	outPointerArray = longAt(foo->stackPointer);
	segmentWordArray = longAt(foo->stackPointer - (1 * 4));

	/* Essential type checks */

	arrayOfRoots = longAt(foo->stackPointer - (2 * 4));
	if (!((((((unsigned) (longAt(arrayOfRoots))) >> 8) & 15) == 2) && ((((((unsigned) (longAt(outPointerArray))) >> 8) & 15) == 2) && (((((unsigned) (longAt(segmentWordArray))) >> 8) & 15) == 6)))) {
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
	lastOut = firstOut - 4;

	/* top half */

	hdrBaseOut = outPointerArray + ((((int) (lastPointerOf(outPointerArray)) >> 3)) * 4);
	lastSeg = segmentWordArray;

	/* Write a version number for byte order and version check */

	endSeg = (segmentWordArray + (sizeBitsOf(segmentWordArray))) - 4;
	versionOffset = 4;
	lastSeg += versionOffset;
	if (lastSeg > endSeg) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	longAtput(lastSeg, imageSegmentVersion());

	/* Take 1/8 of seg */

	firstIn = endSeg - ((((int) (sizeBitsOf(segmentWordArray)) >> 5)) * 4);
	lastIn = firstIn - 4;

	/* top half */
	/* First mark the rootArray and all root objects. */

	hdrBaseIn = firstIn + ((((int) (sizeBitsOf(segmentWordArray)) >> 6)) * 4);
	longAtput(arrayOfRoots, (longAt(arrayOfRoots)) | MarkBit);
	lastPtr = arrayOfRoots + (lastPointerOf(arrayOfRoots));
	fieldPtr = arrayOfRoots + BaseHeaderSize;
	while (fieldPtr <= lastPtr) {
		fieldOop = longAt(fieldPtr);
		if (!((fieldOop & 1))) {
			longAtput(fieldOop, (longAt(fieldOop)) | MarkBit);
		}
		fieldPtr += 4;
	}
	savedYoungStart = foo->youngStart;

	/* process all of memory */
	/* clear the recycled context lists */

	foo->youngStart = startOfMemory();
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
		fieldPtr += 4;
	}
	lastIn += 4;
	if (lastIn >= hdrBaseIn) {
		foo->successFlag = 0;
	}
	lastSeg = copyObjtoSegmentaddrstopAtsaveOopAtheaderAt(arrayOfRoots, segmentWordArray, lastSeg, firstIn, lastIn, hdrBaseIn + (lastIn - firstIn));
	if (!(foo->successFlag)) {
		lastIn -= 4;
		restoreHeadersFromtofromandtofrom(firstIn, lastIn, hdrBaseIn, firstOut, lastOut, hdrBaseOut);
		/* begin primitiveFailAfterCleanup: */
		lastAddr = outPointerArray + (lastPointerOf(outPointerArray));
		i = outPointerArray + BaseHeaderSize;
		while (i <= lastAddr) {
			longAtput(i, foo->nilObj);
			i += 4;
		}
		if (DoAssertionChecks) {
			verifyCleanHeaders();
		}
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	segOop = ((segmentWordArray + versionOffset) + BaseHeaderSize) + (headerTypeBytes[(longAt((segmentWordArray + versionOffset) + BaseHeaderSize)) & TypeMask]);
	while (segOop <= lastSeg) {
		if (((longAt(segOop)) & TypeMask) <= 1) {
			fieldPtr = segOop - 4;
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
				fieldPtr += 4;
			} else {
				header = longAt(fieldOop);
				if ((header & TypeMask) == HeaderTypeFree) {
					mapOop = header & AllButTypeMask;
				} else {
					if (((longAt(fieldOop)) & MarkBit) == 0) {
						lastIn += 4;
						if (lastIn >= hdrBaseIn) {
							foo->successFlag = 0;
						}
						lastSeg = copyObjtoSegmentaddrstopAtsaveOopAtheaderAt(fieldOop, segmentWordArray, lastSeg, firstIn, lastIn, hdrBaseIn + (lastIn - firstIn));
						if (!(foo->successFlag)) {
							lastIn -= 4;
							restoreHeadersFromtofromandtofrom(firstIn, lastIn, hdrBaseIn, firstOut, lastOut, hdrBaseOut);
							/* begin primitiveFailAfterCleanup: */
							lastAddr1 = outPointerArray + (lastPointerOf(outPointerArray));
							i1 = outPointerArray + BaseHeaderSize;
							while (i1 <= lastAddr1) {
								longAtput(i1, foo->nilObj);
								i1 += 4;
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
						lastOut += 4;
						if (lastOut >= hdrBaseOut) {
							lastOut -= 4;
							restoreHeadersFromtofromandtofrom(firstIn, lastIn, hdrBaseIn, firstOut, lastOut, hdrBaseOut);
							/* begin primitiveFailAfterCleanup: */
							lastAddr2 = outPointerArray + (lastPointerOf(outPointerArray));
							i2 = outPointerArray + BaseHeaderSize;
							while (i2 <= lastAddr2) {
								longAtput(i2, foo->nilObj);
								i2 += 4;
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
					fieldPtr += 8;
					doingClass = 0;
				} else {
					longAtput(fieldPtr, mapOop);
					fieldPtr += 4;
				}
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if (segOop >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(segOop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(segOop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header1 = longAt(segOop);
			if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(segOop - 8)) & AllButTypeMask;
				goto l1;
			} else {
				sz = header1 & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		segOop = (segOop + sz) + (headerTypeBytes[(longAt(segOop + sz)) & TypeMask]);
	}
	restoreHeadersFromtofromandtofrom(firstIn, lastIn, hdrBaseIn, firstOut, lastOut, hdrBaseOut);
	if ((((outPointerArray + (lastPointerOf(outPointerArray))) - lastOut) < 12) || ((endSeg - lastSeg) < 12)) {
		/* begin primitiveFailAfterCleanup: */
		lastAddr3 = outPointerArray + (lastPointerOf(outPointerArray));
		i3 = outPointerArray + BaseHeaderSize;
		while (i3 <= lastAddr3) {
			longAtput(i3, foo->nilObj);
			i3 += 4;
		}
		if (DoAssertionChecks) {
			verifyCleanHeaders();
		}
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	extraSize = headerTypeBytes[(longAt(segmentWordArray)) & TypeMask];

	/* Copy the 3-word wordArray header to establish a free chunk. */

	hdrTypeBits = (longAt(segmentWordArray)) & TypeMask;
	/* begin transfer:from:to: */
	in = (segmentWordArray - extraSize) - 4;
	lastIn1 = in + (3 * 4);
	out = (lastOut + 4) - 4;
	while (in < lastIn1) {
		longAtput(out += 4, longAt(in += 4));
	}
	longAtput(lastOut + 4, (((outPointerArray + (lastPointerOf(outPointerArray))) - lastOut) - extraSize) + hdrTypeBits);
	longAtput(outPointerArray - extraSize, ((lastOut - firstOut) + 8) + hdrTypeBits);
	beRootIfOld(outPointerArray);
	/* begin transfer:from:to: */
	in1 = (segmentWordArray - extraSize) - 4;
	lastIn2 = in1 + (3 * 4);
	out1 = (lastSeg + 4) - 4;
	while (in1 < lastIn2) {
		longAtput(out1 += 4, longAt(in1 += 4));
	}
	longAtput(segmentWordArray - extraSize, ((lastSeg - segmentWordArray) + BaseHeaderSize) + hdrTypeBits);
	longAtput(lastSeg + 4, ((endSeg - lastSeg) - extraSize) + hdrTypeBits);
	if (DoAssertionChecks) {
		verifyCleanHeaders();
	}
	/* begin pop: */
	foo->stackPointer -= 3 * 4;
}


/*	Atomic store into context stackPointer. 
	Also ensures that any newly accessible cells are initialized to nil  */

int primitiveStoreStackp(void) {
register struct foo * foo = &fum;
    int stackp;
    int ctxt;
    int i;
    int newStackp;
    int valuePointer;
    int integerPointer;
    int sp;

	ctxt = longAt(foo->stackPointer - (1 * 4));
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * 4));
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
	foo->successFlag = (newStackp >= 0) && foo->successFlag;
	/* begin success: */
	foo->successFlag = (newStackp <= ((((int) (LargeContextSize - BaseHeaderSize) >> 2)) - CtxtTempFrameStart)) && foo->successFlag;
	if (!(foo->successFlag)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	/* begin fetchStackPointerOf: */
	sp = longAt(((((char *) ctxt)) + BaseHeaderSize) + (StackPointerIndex << 2));
	if (!((sp & 1))) {
		stackp = 0;
		goto l1;
	}
	stackp = (sp >> 1);
l1:	/* end fetchStackPointerOf: */;
	if (newStackp > stackp) {
		for (i = (stackp + 1); i <= newStackp; i += 1) {
			/* begin storePointer:ofObject:withValue: */
			valuePointer = foo->nilObj;
			if (ctxt < foo->youngStart) {
				possibleRootStoreIntovalue(ctxt, valuePointer);
			}
			longAtput(((((char *) ctxt)) + BaseHeaderSize) + (((i + CtxtTempFrameStart) - 1) << 2), valuePointer);
		}
	}
	/* begin storeStackPointerValue:inContext: */
	longAtput(((((char *) ctxt)) + BaseHeaderSize) + (StackPointerIndex << 2), ((newStackp << 1) | 1));
	/* begin pop: */
	foo->stackPointer -= 1 * 4;
}

int primitiveStringAt(void) {
	commonAt(1);
}

int primitiveStringAtPut(void) {
	commonAtPut(1);
}


/*	 
	<array> primReplaceFrom: start to: stop with: replacement 
	startingAt: repStart  
	<primitive: 105>
	 */

int primitiveStringReplace(void) {
register struct foo * foo = &fum;
    int stop;
    int replInstSize;
    int srcIndex;
    int array;
    int arrayInstSize;
    int replFmt;
    int repl;
    int totalLength;
    int replStart;
    int start;
    int arrayFmt;
    int hdr;
    int i;
    int integerPointer;
    int integerPointer1;
    int integerPointer2;
    int sz;
    int classFormat;
    int class;
    int sz1;
    int classFormat1;
    int class1;
    int ccIndex;
    int ccIndex1;

	array = longAt(foo->stackPointer - (4 * 4));
	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (3 * 4));
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
	integerPointer1 = longAt(foo->stackPointer - (2 * 4));
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
	repl = longAt(foo->stackPointer - (1 * 4));
	/* begin stackIntegerValue: */
	integerPointer2 = longAt(foo->stackPointer - (0 * 4));
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
	arrayFmt = (((unsigned) hdr) >> 8) & 15;
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(array - 8)) & AllButTypeMask;
	} else {
		sz = hdr & SizeMask;
	}
	if (arrayFmt < 8) {
		totalLength = ((unsigned) (sz - BaseHeaderSize)) >> 2;
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
		class = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l8;
	}
	ccIndex = (((unsigned) (longAt(array))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(array - 4)) & AllButTypeMask;
		goto l8;
	} else {
		class = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l8;
	}
l8:	/* end fetchClassOf: */;
	classFormat = (longAt(((((char *) class)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1;
	arrayInstSize = (((((unsigned) classFormat) >> 11) & 192) + ((((unsigned) classFormat) >> 2) & 63)) - 1;
l5:	/* end fixedFieldsOf:format:length: */;
	if (!((start >= 1) && (((start - 1) <= stop) && ((stop + arrayInstSize) <= totalLength)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	hdr = longAt(repl);
	replFmt = (((unsigned) hdr) >> 8) & 15;
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(repl - 8)) & AllButTypeMask;
	} else {
		sz1 = hdr & SizeMask;
	}
	if (replFmt < 8) {
		totalLength = ((unsigned) (sz1 - BaseHeaderSize)) >> 2;
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
		class1 = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l9;
	}
	ccIndex1 = (((unsigned) (longAt(repl))) >> 12) & 31;
	if (ccIndex1 == 0) {
		class1 = (longAt(repl - 4)) & AllButTypeMask;
		goto l9;
	} else {
		class1 = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex1 - 1) << 2));
		goto l9;
	}
l9:	/* end fetchClassOf: */;
	classFormat1 = (longAt(((((char *) class1)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1;
	replInstSize = (((((unsigned) classFormat1) >> 11) & 192) + ((((unsigned) classFormat1) >> 2) & 63)) - 1;
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
	if (arrayFmt < 4) {
		for (i = ((start + arrayInstSize) - 1); i <= ((stop + arrayInstSize) - 1); i += 1) {
			/* begin storePointer:ofObject:withValue: */
			if (array < foo->youngStart) {
				possibleRootStoreIntovalue(array, longAt(((((char *) repl)) + BaseHeaderSize) + (srcIndex << 2)));
			}
			longAtput(((((char *) array)) + BaseHeaderSize) + (i << 2), longAt(((((char *) repl)) + BaseHeaderSize) + (srcIndex << 2)));
			srcIndex += 1;
		}
	} else {
		if (arrayFmt < 8) {
			for (i = ((start + arrayInstSize) - 1); i <= ((stop + arrayInstSize) - 1); i += 1) {
				longAtput(((((char *) array)) + BaseHeaderSize) + (i << 2), longAt(((((char *) repl)) + BaseHeaderSize) + (srcIndex << 2)));
				srcIndex += 1;
			}
		} else {
			for (i = ((start + arrayInstSize) - 1); i <= ((stop + arrayInstSize) - 1); i += 1) {
				byteAtput(((((char *) array)) + BaseHeaderSize) + i, byteAt(((((char *) repl)) + BaseHeaderSize) + srcIndex));
				srcIndex += 1;
			}
		}
	}
	/* begin pop: */
	foo->stackPointer -= foo->argumentCount * 4;
}

int primitiveSubtract(void) {
register struct foo * foo = &fum;
    int integerResult;
    int sp;

	/* begin pop2AndPushIntegerIfOK: */
	integerResult = (stackIntegerValue(1)) - (stackIntegerValue(0));
	if (foo->successFlag) {
		if ((integerResult ^ (integerResult << 1)) >= 0) {
			/* begin pop:thenPush: */
			longAtput(sp = foo->stackPointer - ((2 - 1) * 4), ((integerResult << 1) | 1));
			foo->stackPointer = sp;
		} else {
			foo->successFlag = 0;
		}
	}
}

int primitiveSuspend(void) {
register struct foo * foo = &fum;
    int activeProc;
    int sp;

	activeProc = longAt(((((char *) (longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SchedulerAssociation << 2))))) + BaseHeaderSize) + (ValueIndex << 2))))) + BaseHeaderSize) + (ActiveProcessIndex << 2));
	/* begin success: */
	foo->successFlag = ((longAt(foo->stackPointer)) == activeProc) && foo->successFlag;
	if (foo->successFlag) {
		/* begin pop: */
		foo->stackPointer -= 1 * 4;
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, foo->nilObj);
		foo->stackPointer = sp;
		transferTo(wakeHighestPriority());
	}
}


/*	Primitive. Terminate up the context stack from the receiver up to but not including the argument, if previousContext is on my Context stack. Make previousContext my sender. This prim has to shadow the code in ContextPart>terminateTo: to be correct */

int primitiveTerminateTo(void) {
register struct foo * foo = &fum;
    int thisCntx;
    int nextCntx;
    int aContext;
    int currentCntx;
    int nilOop;
    int top;
    int top1;
    int sp;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	aContext = top;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	thisCntx = top1;
	if (contexthasSender(thisCntx, aContext)) {
		nilOop = foo->nilObj;
		currentCntx = longAt(((((char *) thisCntx)) + BaseHeaderSize) + (SenderIndex << 2));
		while (!(currentCntx == aContext)) {
			nextCntx = longAt(((((char *) currentCntx)) + BaseHeaderSize) + (SenderIndex << 2));
			/* begin storePointer:ofObject:withValue: */
			if (currentCntx < foo->youngStart) {
				possibleRootStoreIntovalue(currentCntx, nilOop);
			}
			longAtput(((((char *) currentCntx)) + BaseHeaderSize) + (SenderIndex << 2), nilOop);
			/* begin storePointer:ofObject:withValue: */
			if (currentCntx < foo->youngStart) {
				possibleRootStoreIntovalue(currentCntx, nilOop);
			}
			longAtput(((((char *) currentCntx)) + BaseHeaderSize) + (InstructionPointerIndex << 2), nilOop);
			currentCntx = nextCntx;
		}
	}
	/* begin storePointer:ofObject:withValue: */
	if (thisCntx < foo->youngStart) {
		possibleRootStoreIntovalue(thisCntx, aContext);
	}
	longAtput(((((char *) thisCntx)) + BaseHeaderSize) + (SenderIndex << 2), aContext);
	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, thisCntx);
	foo->stackPointer = sp;
	return null;
}


/*	Return true if the host OS does support the given display depth. */

int primitiveTestDisplayDepth(void) {
register struct foo * foo = &fum;
    int okay;
    int bitsPerPixel;
    int integerPointer;
    int sp;
    int sp1;

	/* begin stackIntegerValue: */
	integerPointer = longAt(foo->stackPointer - (0 * 4));
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
		foo->stackPointer -= 2 * 4;
		/* begin pushBool: */
		if (okay) {
			/* begin push: */
			longAtput(sp = foo->stackPointer + 4, foo->trueObj);
			foo->stackPointer = sp;
		} else {
			/* begin push: */
			longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
			foo->stackPointer = sp1;
		}
	}
}

int primitiveTimesTwoPower(void) {
register struct foo * foo = &fum;
    double rcvr;
    int arg;
    int integerPointer;
    int top;

	/* begin popInteger */
	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
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
		foo->stackPointer += 2 * 4;
	}
}

int primitiveTruncated(void) {
register struct foo * foo = &fum;
    double rcvr;
    double trunc;
    double frac;
    int integerValue;
    int sp;

	rcvr = popFloat();
	if (foo->successFlag) {
		frac = modf(rcvr, &trunc);
		success((-1073741824.0 <= trunc) && (trunc <= 1073741823.0));
	}
	if (foo->successFlag) {
		pushInteger((int) trunc);
	} else {
		/* begin unPop: */
		foo->stackPointer += 1 * 4;
	}
}


/*	Primitive. Unload the module with the given name. */
/*	Reloading of the module will happen *later* automatically, when a 
	function from it is called. This is ensured by invalidating current sessionID. */

int primitiveUnloadModule(void) {
register struct foo * foo = &fum;
    int moduleName;

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
	if (!(((moduleName & 1) == 0) && (((((unsigned) (longAt(moduleName))) >> 8) & 15) >= 8))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (!(ioUnloadModuleOfLength(((int) (firstIndexableField(moduleName))), byteSizeOf(moduleName)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	flushExternalPrimitives();
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
	/* begin pop: */
	foo->stackPointer -= 1 * 4;
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
		24	memory headroom when growing object memory (rw)
		25	memory threshold above which shrinking object memory (rw)
		26 interruptChecksEveryNms - force an ioProcessEvents every N milliseconds, in case the image is not calling getNextEvent often (rw)

	Note: Thanks to Ian Piumarta for this primitive. */

int primitiveVMParameter(void) {
register struct foo * foo = &fum;
    int result;
    int paramsArraySize;
    int i;
    int index;
    int mem;
    int arg;
    int sp;
    int sp1;
    int sp2;

	mem = ((int) memory);
	;
	if (foo->argumentCount == 0) {
		paramsArraySize = 25;
		result = instantiateClassindexableSize(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassArray << 2)), paramsArraySize);
		for (i = 0; i <= (paramsArraySize - 1); i += 1) {
			longAtput(((((char *) result)) + BaseHeaderSize) + (i << 2), ConstZero);
		}
		longAtput(((((char *) result)) + BaseHeaderSize) + (0 << 2), (((foo->youngStart - mem) << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (1 << 2), (((foo->freeBlock - mem) << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (2 << 2), (((foo->endOfMemory - mem) << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (3 << 2), ((foo->allocationCount << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (4 << 2), ((foo->allocationsBetweenGCs << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (5 << 2), ((foo->tenuringThreshold << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (6 << 2), ((foo->statFullGCs << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (7 << 2), ((foo->statFullGCMSecs << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (8 << 2), ((foo->statIncrGCs << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (9 << 2), ((foo->statIncrGCMSecs << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (10 << 2), ((foo->statTenures << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (20 << 2), ((foo->rootTableCount << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (21 << 2), ((foo->statRootTableOverflows << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (22 << 2), ((extraVMMemory << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (23 << 2), ((foo->shrinkThreshold << 1) | 1));
		longAtput(((((char *) result)) + BaseHeaderSize) + (24 << 2), ((foo->growHeadroom << 1) | 1));
		/* begin pop:thenPush: */
		longAtput(sp = foo->stackPointer - ((1 - 1) * 4), result);
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
	if (foo->argumentCount == 1) {
		if ((arg < 1) || (arg > 25)) {
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
			result = foo->statFullGCMSecs;
		}
		if (arg == 9) {
			result = foo->statIncrGCs;
		}
		if (arg == 10) {
			result = foo->statIncrGCMSecs;
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
		/* begin pop:thenPush: */
		longAtput(sp1 = foo->stackPointer - ((2 - 1) * 4), ((result << 1) | 1));
		foo->stackPointer = sp1;
		return null;
	}
	if (!(foo->argumentCount == 2)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	index = longAt(foo->stackPointer - (1 * 4));
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
			foo->successFlag = 1;
		}
	}
	if (foo->successFlag) {
		/* begin pop:thenPush: */
		longAtput(sp2 = foo->stackPointer - ((3 - 1) * 4), ((result << 1) | 1));
		foo->stackPointer = sp2;
		return null;
	}
	/* begin primitiveFail */
	foo->successFlag = 0;
}


/*	Return a string containing the path name of VM's directory. */

int primitiveVMPath(void) {
register struct foo * foo = &fum;
    int sz;
    int s;
    int sp;

	sz = vmPathSize();
	s = instantiateClassindexableSize(longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassString << 2)), sz);
	vmPathGetLength(s + BaseHeaderSize, sz);
	/* begin pop:thenPush: */
	longAtput(sp = foo->stackPointer - ((1 - 1) * 4), s);
	foo->stackPointer = sp;
}

int primitiveValue(void) {
register struct foo * foo = &fum;
    int initialIP;
    int blockArgumentCount;
    int blockContext;
    int fromIndex;
    int toIndex;
    int lastFrom;
    int localArgCount;
    int successValue;
    int tmp;

	blockContext = longAt(foo->stackPointer - (foo->argumentCount * 4));
	/* begin argumentCountOfBlock: */
	localArgCount = longAt(((((char *) blockContext)) + BaseHeaderSize) + (BlockArgumentCountIndex << 2));
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
	successValue = (foo->argumentCount == blockArgumentCount) && ((longAt(((((char *) blockContext)) + BaseHeaderSize) + (CallerIndex << 2))) == foo->nilObj);
	foo->successFlag = successValue && foo->successFlag;
	if (foo->successFlag) {
		/* begin transfer:fromIndex:ofObject:toIndex:ofObject: */
		fromIndex = foo->activeContext + ((((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - foo->argumentCount) + 1) * 4);
		toIndex = blockContext + (TempFrameStart * 4);
		lastFrom = fromIndex + (foo->argumentCount * 4);
		while (fromIndex < lastFrom) {
			fromIndex += 4;
			toIndex += 4;
			longAtput(toIndex, longAt(fromIndex));
		}
		/* begin pop: */
		foo->stackPointer -= (foo->argumentCount + 1) * 4;
		initialIP = longAt(((((char *) blockContext)) + BaseHeaderSize) + (InitialIPIndex << 2));
		longAtput(((((char *) blockContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), initialIP);
		/* begin storeStackPointerValue:inContext: */
		longAtput(((((char *) blockContext)) + BaseHeaderSize) + (StackPointerIndex << 2), ((foo->argumentCount << 1) | 1));
		longAtput(((((char *) blockContext)) + BaseHeaderSize) + (CallerIndex << 2), foo->activeContext);
		/* begin newActiveContext: */
		/* begin storeContextRegisters: */
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (StackPointerIndex << 2), (((((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - TempFrameStart) + 1) << 1) | 1));
		if (blockContext < foo->youngStart) {
			beRootIfOld(blockContext);
		}
		foo->activeContext = blockContext;
		/* begin fetchContextRegisters: */
		tmp = longAt(((((char *) blockContext)) + BaseHeaderSize) + (MethodIndex << 2));
		if ((tmp & 1)) {
			tmp = longAt(((((char *) blockContext)) + BaseHeaderSize) + (HomeIndex << 2));
			if (tmp < foo->youngStart) {
				beRootIfOld(tmp);
			}
		} else {
			tmp = blockContext;
		}
		foo->theHomeContext = tmp;
		foo->receiver = longAt(((((char *) tmp)) + BaseHeaderSize) + (ReceiverIndex << 2));
		foo->method = longAt(((((char *) tmp)) + BaseHeaderSize) + (MethodIndex << 2));
		tmp = ((longAt(((((char *) blockContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2))) >> 1);
		foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
		tmp = ((longAt(((((char *) blockContext)) + BaseHeaderSize) + (StackPointerIndex << 2))) >> 1);
		foo->stackPointer = (blockContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * 4);
	}
}


/*	The only purpose of this primitive is to indicate that the new EH mechanisms are supported. */

int primitiveValueUninterruptably(void) {
	return primitiveValue();
}

int primitiveValueWithArgs(void) {
register struct foo * foo = &fum;
    int initialIP;
    int argumentArray;
    int blockArgumentCount;
    int blockContext;
    int arrayArgumentCount;
    int sz;
    int header;
    int successValue;
    int fromIndex;
    int toIndex;
    int lastFrom;
    int tmp;
    int top;
    int top1;
    int localArgCount;

	/* begin popStack */
	top = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	argumentArray = top;
	/* begin popStack */
	top1 = longAt(foo->stackPointer);
	foo->stackPointer -= 4;
	blockContext = top1;
	/* begin argumentCountOfBlock: */
	localArgCount = longAt(((((char *) blockContext)) + BaseHeaderSize) + (BlockArgumentCountIndex << 2));
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
	if (!(((argumentArray & 1) == 0) && (((((unsigned) (longAt(argumentArray))) >> 8) & 15) == 2))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	if (foo->successFlag) {
		/* begin fetchWordLengthOf: */
		/* begin sizeBitsOf: */
		header = longAt(argumentArray);
		if ((header & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(argumentArray - 8)) & AllButTypeMask;
			goto l1;
		} else {
			sz = header & SizeMask;
			goto l1;
		}
	l1:	/* end sizeBitsOf: */;
		arrayArgumentCount = ((unsigned) (sz - BaseHeaderSize)) >> 2;
		/* begin success: */
		successValue = (arrayArgumentCount == blockArgumentCount) && ((longAt(((((char *) blockContext)) + BaseHeaderSize) + (CallerIndex << 2))) == foo->nilObj);
		foo->successFlag = successValue && foo->successFlag;
	}
	if (foo->successFlag) {
		/* begin transfer:fromIndex:ofObject:toIndex:ofObject: */
		fromIndex = argumentArray + (0 * 4);
		toIndex = blockContext + (TempFrameStart * 4);
		lastFrom = fromIndex + (arrayArgumentCount * 4);
		while (fromIndex < lastFrom) {
			fromIndex += 4;
			toIndex += 4;
			longAtput(toIndex, longAt(fromIndex));
		}
		initialIP = longAt(((((char *) blockContext)) + BaseHeaderSize) + (InitialIPIndex << 2));
		longAtput(((((char *) blockContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), initialIP);
		/* begin storeStackPointerValue:inContext: */
		longAtput(((((char *) blockContext)) + BaseHeaderSize) + (StackPointerIndex << 2), ((arrayArgumentCount << 1) | 1));
		longAtput(((((char *) blockContext)) + BaseHeaderSize) + (CallerIndex << 2), foo->activeContext);
		/* begin newActiveContext: */
		/* begin storeContextRegisters: */
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (StackPointerIndex << 2), (((((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - TempFrameStart) + 1) << 1) | 1));
		if (blockContext < foo->youngStart) {
			beRootIfOld(blockContext);
		}
		foo->activeContext = blockContext;
		/* begin fetchContextRegisters: */
		tmp = longAt(((((char *) blockContext)) + BaseHeaderSize) + (MethodIndex << 2));
		if ((tmp & 1)) {
			tmp = longAt(((((char *) blockContext)) + BaseHeaderSize) + (HomeIndex << 2));
			if (tmp < foo->youngStart) {
				beRootIfOld(tmp);
			}
		} else {
			tmp = blockContext;
		}
		foo->theHomeContext = tmp;
		foo->receiver = longAt(((((char *) tmp)) + BaseHeaderSize) + (ReceiverIndex << 2));
		foo->method = longAt(((((char *) tmp)) + BaseHeaderSize) + (MethodIndex << 2));
		tmp = ((longAt(((((char *) blockContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2))) >> 1);
		foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
		tmp = ((longAt(((((char *) blockContext)) + BaseHeaderSize) + (StackPointerIndex << 2))) >> 1);
		foo->stackPointer = (blockContext + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * 4);
	} else {
		/* begin unPop: */
		foo->stackPointer += 2 * 4;
	}
}

int primitiveWait(void) {
register struct foo * foo = &fum;
    int excessSignals;
    int activeProc;
    int sema;
    int lastLink;
    int cl;
    int ccIndex;


	/* rcvr */

	sema = longAt(foo->stackPointer);
	/* begin assertClassOf:is: */
	if ((sema & 1)) {
		foo->successFlag = 0;
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(sema))) >> 12) & 31;
	if (ccIndex == 0) {
		cl = (longAt(sema - 4)) & AllButTypeMask;
	} else {
		cl = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
	}
	/* begin success: */
	foo->successFlag = (cl == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassSemaphore << 2)))) && foo->successFlag;
l1:	/* end assertClassOf:is: */;
	if (foo->successFlag) {
		excessSignals = fetchIntegerofObject(ExcessSignalsIndex, sema);
		if (excessSignals > 0) {
			/* begin storeInteger:ofObject:withValue: */
			if (((excessSignals - 1) ^ ((excessSignals - 1) << 1)) >= 0) {
				longAtput(((((char *) sema)) + BaseHeaderSize) + (ExcessSignalsIndex << 2), (((excessSignals - 1) << 1) | 1));
			} else {
				/* begin primitiveFail */
				foo->successFlag = 0;
			}
		} else {
			activeProc = longAt(((((char *) (longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SchedulerAssociation << 2))))) + BaseHeaderSize) + (ValueIndex << 2))))) + BaseHeaderSize) + (ActiveProcessIndex << 2));
			/* begin addLastLink:toList: */
			if ((longAt(((((char *) sema)) + BaseHeaderSize) + (FirstLinkIndex << 2))) == foo->nilObj) {
				/* begin storePointer:ofObject:withValue: */
				if (sema < foo->youngStart) {
					possibleRootStoreIntovalue(sema, activeProc);
				}
				longAtput(((((char *) sema)) + BaseHeaderSize) + (FirstLinkIndex << 2), activeProc);
			} else {
				lastLink = longAt(((((char *) sema)) + BaseHeaderSize) + (LastLinkIndex << 2));
				/* begin storePointer:ofObject:withValue: */
				if (lastLink < foo->youngStart) {
					possibleRootStoreIntovalue(lastLink, activeProc);
				}
				longAtput(((((char *) lastLink)) + BaseHeaderSize) + (NextLinkIndex << 2), activeProc);
			}
			/* begin storePointer:ofObject:withValue: */
			if (sema < foo->youngStart) {
				possibleRootStoreIntovalue(sema, activeProc);
			}
			longAtput(((((char *) sema)) + BaseHeaderSize) + (LastLinkIndex << 2), activeProc);
			/* begin storePointer:ofObject:withValue: */
			if (activeProc < foo->youngStart) {
				possibleRootStoreIntovalue(activeProc, sema);
			}
			longAtput(((((char *) activeProc)) + BaseHeaderSize) + (MyListIndex << 2), sema);
			transferTo(wakeHighestPriority());
		}
	}
}


/*	primitively do the equivalent of Process>yield */

int primitiveYield(void) {
register struct foo * foo = &fum;
    int priority;
    int processList;
    int activeProc;
    int processLists;
    int lastLink;

	activeProc = longAt(((((char *) (longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SchedulerAssociation << 2))))) + BaseHeaderSize) + (ValueIndex << 2))))) + BaseHeaderSize) + (ActiveProcessIndex << 2));
	priority = ((longAt(((((char *) activeProc)) + BaseHeaderSize) + (PriorityIndex << 2))) >> 1);
	processLists = longAt(((((char *) (longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SchedulerAssociation << 2))))) + BaseHeaderSize) + (ValueIndex << 2))))) + BaseHeaderSize) + (ProcessListsIndex << 2));
	processList = longAt(((((char *) processLists)) + BaseHeaderSize) + ((priority - 1) << 2));
	if (!((longAt(((((char *) processList)) + BaseHeaderSize) + (FirstLinkIndex << 2))) == foo->nilObj)) {
		/* begin addLastLink:toList: */
		if ((longAt(((((char *) processList)) + BaseHeaderSize) + (FirstLinkIndex << 2))) == foo->nilObj) {
			/* begin storePointer:ofObject:withValue: */
			if (processList < foo->youngStart) {
				possibleRootStoreIntovalue(processList, activeProc);
			}
			longAtput(((((char *) processList)) + BaseHeaderSize) + (FirstLinkIndex << 2), activeProc);
		} else {
			lastLink = longAt(((((char *) processList)) + BaseHeaderSize) + (LastLinkIndex << 2));
			/* begin storePointer:ofObject:withValue: */
			if (lastLink < foo->youngStart) {
				possibleRootStoreIntovalue(lastLink, activeProc);
			}
			longAtput(((((char *) lastLink)) + BaseHeaderSize) + (NextLinkIndex << 2), activeProc);
		}
		/* begin storePointer:ofObject:withValue: */
		if (processList < foo->youngStart) {
			possibleRootStoreIntovalue(processList, activeProc);
		}
		longAtput(((((char *) processList)) + BaseHeaderSize) + (LastLinkIndex << 2), activeProc);
		/* begin storePointer:ofObject:withValue: */
		if (activeProc < foo->youngStart) {
			possibleRootStoreIntovalue(activeProc, processList);
		}
		longAtput(((((char *) activeProc)) + BaseHeaderSize) + (MyListIndex << 2), processList);
		transferTo(wakeHighestPriority());
	}
}


/*	For testing in Smalltalk, this method should be overridden in a subclass. */

int print(char *s) {
	printf("%s", s);
}


/*	Print all the stacks of all running processes, including those that are currently suspended. */

int printAllStacks(void) {
register struct foo * foo = &fum;
    int ctx;
    int proc;
    int oop;
    int sz;
    int header;
    int chunk;

	proc = longAt(((((char *) (longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SchedulerAssociation << 2))))) + BaseHeaderSize) + (ValueIndex << 2))))) + BaseHeaderSize) + (ActiveProcessIndex << 2));
	printNameOfClasscount(fetchClassOf(proc), 5);
	/* begin cr */
	printf("\n");
	printCallStackOf(foo->activeContext);
	/* begin oopFromChunk: */
	chunk = startOfMemory();
	oop = chunk + (headerTypeBytes[(longAt(chunk)) & TypeMask]);
	while (oop < foo->endOfMemory) {
		if ((fetchClassOf(oop)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassSemaphore << 2)))) {
			/* begin cr */
			printf("\n");
			proc = longAt(((((char *) oop)) + BaseHeaderSize) + (FirstLinkIndex << 2));
			while (!(proc == foo->nilObj)) {
				printNameOfClasscount(fetchClassOf(proc), 5);
				/* begin cr */
				printf("\n");
				ctx = longAt(((((char *) proc)) + BaseHeaderSize) + (SuspendedContextIndex << 2));
				if (!(ctx == foo->nilObj)) {
					printCallStackOf(ctx);
				}
				proc = longAt(((((char *) proc)) + BaseHeaderSize) + (NextLinkIndex << 2));
			}
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if (oop >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(oop);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - 8)) & AllButTypeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz) + (headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	}
}

int printCallStack(void) {
	return printCallStackOf(foo->activeContext);
}

int printCallStackOf(int aContext) {
register struct foo * foo = &fum;
    int methClass;
    int ctxt;
    int message;
    int home;
    int methodSel;
    int currClass;
    int methodArray;
    int classDictSize;
    int i;
    int classDict;
    int done;
    int sz;
    int header;
    int ccIndex;
    int ccIndex1;
    int currClass1;
    int methodArray1;
    int classDictSize1;
    int i1;
    int done1;
    int classDict1;
    int sz1;
    int header1;
    int ccIndex2;

	ctxt = aContext;
	while (!(ctxt == foo->nilObj)) {
		if ((fetchClassOf(ctxt)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassBlockContext << 2)))) {
			home = longAt(((((char *) ctxt)) + BaseHeaderSize) + (HomeIndex << 2));
		} else {
			home = ctxt;
		}
		/* begin findClassOfMethod:forReceiver: */
		/* begin fetchClassOf: */
		if (((longAt(((((char *) home)) + BaseHeaderSize) + (ReceiverIndex << 2))) & 1)) {
			currClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
			goto l2;
		}
		ccIndex = (((unsigned) (longAt(longAt(((((char *) home)) + BaseHeaderSize) + (ReceiverIndex << 2))))) >> 12) & 31;
		if (ccIndex == 0) {
			currClass = (longAt((longAt(((((char *) home)) + BaseHeaderSize) + (ReceiverIndex << 2))) - 4)) & AllButTypeMask;
			goto l2;
		} else {
			currClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
			goto l2;
		}
	l2:	/* end fetchClassOf: */;
		done = 0;
		while (!(done)) {
			classDict = longAt(((((char *) currClass)) + BaseHeaderSize) + (MessageDictionaryIndex << 2));
			/* begin fetchWordLengthOf: */
			/* begin sizeBitsOf: */
			header = longAt(classDict);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(classDict - 8)) & AllButTypeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
			classDictSize = ((unsigned) (sz - BaseHeaderSize)) >> 2;
			methodArray = longAt(((((char *) classDict)) + BaseHeaderSize) + (MethodArrayIndex << 2));
			i = 0;
			while (i < (classDictSize - SelectorStart)) {
				if ((longAt(((((char *) home)) + BaseHeaderSize) + (MethodIndex << 2))) == (longAt(((((char *) methodArray)) + BaseHeaderSize) + (i << 2)))) {
					methClass = currClass;
					goto l3;
				}
				i += 1;
			}
			currClass = longAt(((((char *) currClass)) + BaseHeaderSize) + (SuperclassIndex << 2));
			done = currClass == foo->nilObj;
		}
		/* begin fetchClassOf: */
		if (((longAt(((((char *) home)) + BaseHeaderSize) + (ReceiverIndex << 2))) & 1)) {
			methClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
			goto l3;
		}
		ccIndex1 = (((unsigned) (longAt(longAt(((((char *) home)) + BaseHeaderSize) + (ReceiverIndex << 2))))) >> 12) & 31;
		if (ccIndex1 == 0) {
			methClass = (longAt((longAt(((((char *) home)) + BaseHeaderSize) + (ReceiverIndex << 2))) - 4)) & AllButTypeMask;
			goto l3;
		} else {
			methClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex1 - 1) << 2));
			goto l3;
		}
		methClass = null;
	l3:	/* end findClassOfMethod:forReceiver: */;
		/* begin findSelectorOfMethod:forReceiver: */
		/* begin fetchClassOf: */
		if (((longAt(((((char *) home)) + BaseHeaderSize) + (ReceiverIndex << 2))) & 1)) {
			currClass1 = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
			goto l5;
		}
		ccIndex2 = (((unsigned) (longAt(longAt(((((char *) home)) + BaseHeaderSize) + (ReceiverIndex << 2))))) >> 12) & 31;
		if (ccIndex2 == 0) {
			currClass1 = (longAt((longAt(((((char *) home)) + BaseHeaderSize) + (ReceiverIndex << 2))) - 4)) & AllButTypeMask;
			goto l5;
		} else {
			currClass1 = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex2 - 1) << 2));
			goto l5;
		}
	l5:	/* end fetchClassOf: */;
		done1 = 0;
		while (!(done1)) {
			classDict1 = longAt(((((char *) currClass1)) + BaseHeaderSize) + (MessageDictionaryIndex << 2));
			/* begin fetchWordLengthOf: */
			/* begin sizeBitsOf: */
			header1 = longAt(classDict1);
			if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
				sz1 = (longAt(classDict1 - 8)) & AllButTypeMask;
				goto l4;
			} else {
				sz1 = header1 & SizeMask;
				goto l4;
			}
		l4:	/* end sizeBitsOf: */;
			classDictSize1 = ((unsigned) (sz1 - BaseHeaderSize)) >> 2;
			methodArray1 = longAt(((((char *) classDict1)) + BaseHeaderSize) + (MethodArrayIndex << 2));
			i1 = 0;
			while (i1 <= (classDictSize1 - SelectorStart)) {
				if ((longAt(((((char *) home)) + BaseHeaderSize) + (MethodIndex << 2))) == (longAt(((((char *) methodArray1)) + BaseHeaderSize) + (i1 << 2)))) {
					methodSel = longAt(((((char *) classDict1)) + BaseHeaderSize) + ((i1 + SelectorStart) << 2));
					goto l6;
				}
				i1 += 1;
			}
			currClass1 = longAt(((((char *) currClass1)) + BaseHeaderSize) + (SuperclassIndex << 2));
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
		if (methodSel == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SelectorDoesNotUnderstand << 2)))) {
			message = longAt(((((char *) home)) + BaseHeaderSize) + ((0 + TempFrameStart) << 2));
			methodSel = longAt(((((char *) message)) + BaseHeaderSize) + (MessageSelectorIndex << 2));
			print(" ");
			printStringOf(methodSel);
		}
		/* begin cr */
		printf("\n");
		ctxt = longAt(((((char *) ctxt)) + BaseHeaderSize) + (SenderIndex << 2));
	}
}


/*	Details: The count argument is used to avoid a possible infinite recursion if classOop is a corrupted object. */

int printNameOfClasscount(int classOop, int cnt) {
	if (cnt <= 0) {
		return print("bad class");
	}
	if ((sizeBitsOf(classOop)) == 28) {
		printNameOfClasscount(longAt(((((char *) classOop)) + BaseHeaderSize) + (5 << 2)), cnt - 1);
		print(" class");
	} else {
		printStringOf(longAt(((((char *) classOop)) + BaseHeaderSize) + (6 << 2)));
	}
}


/*	For testing in Smalltalk, this method should be overridden in a subclass. */

int printNum(int n) {
	printf("%ld", (long) n);
}

int printStringOf(int oop) {
    int fmt;
    int cnt;
    int i;

	if ((oop & 1)) {
		return null;
	}
	fmt = (((unsigned) (longAt(oop))) >> 8) & 15;
	if (fmt < 8) {
		return null;
	}
	cnt = ((100 < (lengthOf(oop))) ? 100 : (lengthOf(oop)));
	i = 0;
	while (i < cnt) {
		/* begin printChar: */
		putchar(byteAt(((((char *) oop)) + BaseHeaderSize) + i));
		i += 1;
	}
}

int printUnbalancedStack(int primIdx) {
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

int printUnbalancedStackFromNamedPrimitive(void) {
register struct foo * foo = &fum;
    int lit;

	print("Stack unbalanced after ");
	if (foo->successFlag) {
		print("successful ");
	} else {
		print("failed ");
	}
	lit = longAt(((((char *) foo->newMethod)) + BaseHeaderSize) + ((0 + LiteralStart) << 2));
	printStringOf(longAt(((((char *) lit)) + BaseHeaderSize) + (1 << 2)));
	print(" in ");
	printStringOf(longAt(((((char *) lit)) + BaseHeaderSize) + (0 << 2)));
	/* begin cr */
	printf("\n");
}

int push(int object) {
register struct foo * foo = &fum;
    int sp;

	longAtput(sp = foo->stackPointer + 4, object);
	foo->stackPointer = sp;
}

int pushBool(int trueOrFalse) {
register struct foo * foo = &fum;
    int sp;
    int sp1;

	if (trueOrFalse) {
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, foo->trueObj);
		foo->stackPointer = sp;
	} else {
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
		foo->stackPointer = sp1;
	}
}

int pushFloat(double f) {
register struct foo * foo = &fum;
    int object;
    int sp;

	/* begin push: */
	object = floatObjectOf(f);
	longAtput(sp = foo->stackPointer + 4, object);
	foo->stackPointer = sp;
}

int pushInteger(int integerValue) {
register struct foo * foo = &fum;
    int sp;

	/* begin push: */
	longAtput(sp = foo->stackPointer + 4, ((integerValue << 1) | 1));
	foo->stackPointer = sp;
}


/*	Record the given object in a the remap buffer. Objects in this buffer are remapped when a compaction occurs. This facility is used by the interpreter to ensure that objects in temporary variables are properly remapped. */

int pushRemappableOop(int oop) {
register struct foo * foo = &fum;
	remapBuffer[foo->remapBufferCount += 1] = oop;
}


/*	Append the given 4-byte long word to the given file in this platforms 'natural' byte order. (Bytes will be swapped, if necessary, when the image is read on a different platform.) Set successFlag to false if the write fails. */

int putLongtoFile(int n, sqImageFile f) {
register struct foo * foo = &fum;
    int wordsWritten;

	wordsWritten = sqImageFileWrite(&n, sizeof(int), 1, f);
	/* begin success: */
	foo->successFlag = (wordsWritten == 1) && foo->successFlag;
}


/*	Read an image from the given file stream, allocating the given amount of memory to its object heap. Fail if the image has an unknown format or requires more than the given amount of memory. */
/*	Details: This method detects when the image was stored on a machine with the opposite byte ordering from this machine and swaps the bytes automatically. Furthermore, it allows the header information to start 512 bytes into the file, since some file transfer programs for the Macintosh apparently prepend a Mac-specific header of this size. Note that this same 512 bytes of prefix area could also be used to store an exec command on Unix systems, allowing one to launch Smalltalk by invoking the image name as a command. */
/*	This code is based on C code by Ian Piumarta and Smalltalk code by Tim Rowledge. Many thanks to both of you!! */

int readImageFromFileHeapSizeStartingAt(sqImageFile f, int desiredHeapSize, squeakFileOffsetType imageOffset) {
register struct foo * foo = &fum;
    int heapSize;
    int bytesToShift;
    int headerSize;
    size_t dataSize;
    int bytesRead;
    int oldBaseAddr;
    int swapBytes;
    unsigned memStart;
    squeakFileOffsetType headerStart;
    int minimumMemory;
    int startAddr;
    int addr;
    int i;
    int sched;
    int proc;
    int activeCntx;
    int tmp;

	swapBytes = checkImageVersionFromstartingAt(f, imageOffset);

	/* record header start position */

	headerStart = (sqImageFilePosition(f)) - 4;
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
	memory = (unsigned char *) sqAllocateMemory(minimumMemory, heapSize);
	if (memory == null) {
		insufficientMemoryAvailableError();
	}
	memStart = startOfMemory();

	/* decrease memoryLimit a tad for safety */

	foo->memoryLimit = (memStart + heapSize) - 24;

	/* position file after the header */

	foo->endOfMemory = memStart + dataSize;
	sqImageFileSeek(f, headerStart + headerSize);
	bytesRead = sqImageFileRead(memory, sizeof(unsigned char), dataSize, f);
	if (bytesRead != dataSize) {
		unableToReadImageError();
	}
	headerTypeBytes[0] = 8;
	headerTypeBytes[1] = 4;
	headerTypeBytes[2] = 0;
	headerTypeBytes[3] = 0;
	if (swapBytes) {
		/* begin reverseBytesInImage */
		/* begin reverseBytesFrom:to: */
		startAddr = startOfMemory();
		addr = startAddr;
		while (addr < foo->endOfMemory) {
			longAtput(addr, ((((((unsigned) (longAt(addr)) >> 24)) & 255) + ((((unsigned) (longAt(addr)) >> 8)) & 65280)) + ((((unsigned) (longAt(addr)) << 8)) & 16711680)) + ((((unsigned) (longAt(addr)) << 24)) & 4278190080U));
			addr += 4;
		}
		/* begin byteSwapByteObjects */
		byteSwapByteObjectsFromto(oopFromChunk(startOfMemory()), foo->endOfMemory);
	}
	bytesToShift = memStart - oldBaseAddr;
	/* begin initializeInterpreter: */
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
		methodCache[i] = 0;
	}
	for (i = 1; i <= AtCacheTotalSize; i += 1) {
		atCache[i] = 0;
	}
	/* begin loadInitialContext */
	sched = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SchedulerAssociation << 2))))) + BaseHeaderSize) + (ValueIndex << 2));
	proc = longAt(((((char *) sched)) + BaseHeaderSize) + (ActiveProcessIndex << 2));
	foo->activeContext = longAt(((((char *) proc)) + BaseHeaderSize) + (SuspendedContextIndex << 2));
	if (foo->activeContext < foo->youngStart) {
		beRootIfOld(foo->activeContext);
	}
	/* begin fetchContextRegisters: */
	activeCntx = foo->activeContext;
	tmp = longAt(((((char *) activeCntx)) + BaseHeaderSize) + (MethodIndex << 2));
	if ((tmp & 1)) {
		tmp = longAt(((((char *) activeCntx)) + BaseHeaderSize) + (HomeIndex << 2));
		if (tmp < foo->youngStart) {
			beRootIfOld(tmp);
		}
	} else {
		tmp = activeCntx;
	}
	foo->theHomeContext = tmp;
	foo->receiver = longAt(((((char *) tmp)) + BaseHeaderSize) + (ReceiverIndex << 2));
	foo->method = longAt(((((char *) tmp)) + BaseHeaderSize) + (MethodIndex << 2));
	tmp = ((longAt(((((char *) activeCntx)) + BaseHeaderSize) + (InstructionPointerIndex << 2))) >> 1);
	foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
	tmp = ((longAt(((((char *) activeCntx)) + BaseHeaderSize) + (StackPointerIndex << 2))) >> 1);
	foo->stackPointer = (activeCntx + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * 4);
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
	foo->interruptKeycode = 2094;
	foo->interruptPending = 0;
	foo->semaphoresUseBufferA = 1;
	foo->semaphoresToSignalCountA = 0;
	foo->semaphoresToSignalCountB = 0;
	foo->deferDisplayUpdates = 0;
	foo->pendingFinalizationSignals = 0;
	return dataSize;
}


/*	Anwer true if images of the given format are readable by this interpreter. Allows a virtual machine to accept selected older image formats. */

int readableFormat(int imageVersion) {
	return imageVersion == 6502;
}


/*	Map the given oop to its new value during a compaction or 
	become: operation. If it has no forwarding table entry, 
	return the oop itself. */

int remap(int oop) {
register struct foo * foo = &fum;
    int fwdBlock;

	if (((oop & 1) == 0) && (((longAt(oop)) & MarkBit) != 0)) {
		fwdBlock = ((longAt(oop)) & AllButMarkBitAndTypeMask) << 1;
		if (DoAssertionChecks) {
			/* begin fwdBlockValidate: */
			if (!((fwdBlock > foo->endOfMemory) && ((fwdBlock <= foo->fwdTableNext) && ((fwdBlock & 3) == 0)))) {
				error("invalid fwd table entry");
			}
		}
		return longAt(fwdBlock);
	}
	return oop;
}


/*	Remove the first process from the given linked list. */

int removeFirstLinkOfList(int aList) {
register struct foo * foo = &fum;
    int last;
    int next;
    int first;
    int valuePointer;
    int valuePointer1;
    int valuePointer2;

	first = longAt(((((char *) aList)) + BaseHeaderSize) + (FirstLinkIndex << 2));
	last = longAt(((((char *) aList)) + BaseHeaderSize) + (LastLinkIndex << 2));
	if (first == last) {
		/* begin storePointer:ofObject:withValue: */
		valuePointer = foo->nilObj;
		if (aList < foo->youngStart) {
			possibleRootStoreIntovalue(aList, valuePointer);
		}
		longAtput(((((char *) aList)) + BaseHeaderSize) + (FirstLinkIndex << 2), valuePointer);
		/* begin storePointer:ofObject:withValue: */
		valuePointer1 = foo->nilObj;
		if (aList < foo->youngStart) {
			possibleRootStoreIntovalue(aList, valuePointer1);
		}
		longAtput(((((char *) aList)) + BaseHeaderSize) + (LastLinkIndex << 2), valuePointer1);
	} else {
		next = longAt(((((char *) first)) + BaseHeaderSize) + (NextLinkIndex << 2));
		/* begin storePointer:ofObject:withValue: */
		if (aList < foo->youngStart) {
			possibleRootStoreIntovalue(aList, next);
		}
		longAtput(((((char *) aList)) + BaseHeaderSize) + (FirstLinkIndex << 2), next);
	}
	/* begin storePointer:ofObject:withValue: */
	valuePointer2 = foo->nilObj;
	if (first < foo->youngStart) {
		possibleRootStoreIntovalue(first, valuePointer2);
	}
	longAtput(((((char *) first)) + BaseHeaderSize) + (NextLinkIndex << 2), valuePointer2);
	return first;
}


/*	Restore headers smashed by forwarding links */

int restoreHeadersFromtofromandtofrom(int firstIn, int lastIn, int hdrBaseIn, int firstOut, int lastOut, int hdrBaseOut) {
register struct foo * foo = &fum;
    int tablePtr;
    int oop;
    int header;
    int chunk;
    int sz;
    int header1;

	tablePtr = firstIn;
	while (tablePtr <= lastIn) {
		oop = longAt(tablePtr);
		header = longAt(hdrBaseIn + (tablePtr - firstIn));
		longAtput(oop, header);
		tablePtr += 4;
	}
	tablePtr = firstOut;
	while (tablePtr <= lastOut) {
		oop = longAt(tablePtr);
		header = longAt(hdrBaseOut + (tablePtr - firstOut));
		longAtput(oop, header);
		tablePtr += 4;
	}
	/* begin oopFromChunk: */
	chunk = startOfMemory();
	oop = chunk + (headerTypeBytes[(longAt(chunk)) & TypeMask]);
	while (oop < foo->endOfMemory) {
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			longAtput(oop, (longAt(oop)) & AllButMarkBit);
		}
		/* begin objectAfter: */
		if (DoAssertionChecks) {
			if (oop >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header1 = longAt(oop);
			if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - 8)) & AllButTypeMask;
				goto l1;
			} else {
				sz = header1 & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz) + (headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	}
}

int resume(int aProcess) {
register struct foo * foo = &fum;
    int newPriority;
    int activeProc;
    int activePriority;
    int priority;
    int processList;
    int processLists;
    int lastLink;
    int priority1;
    int processList1;
    int processLists1;
    int lastLink1;

	activeProc = longAt(((((char *) (longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SchedulerAssociation << 2))))) + BaseHeaderSize) + (ValueIndex << 2))))) + BaseHeaderSize) + (ActiveProcessIndex << 2));
	activePriority = ((longAt(((((char *) activeProc)) + BaseHeaderSize) + (PriorityIndex << 2))) >> 1);
	newPriority = ((longAt(((((char *) aProcess)) + BaseHeaderSize) + (PriorityIndex << 2))) >> 1);
	if (newPriority > activePriority) {
		/* begin putToSleep: */
		priority = ((longAt(((((char *) activeProc)) + BaseHeaderSize) + (PriorityIndex << 2))) >> 1);
		processLists = longAt(((((char *) (longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SchedulerAssociation << 2))))) + BaseHeaderSize) + (ValueIndex << 2))))) + BaseHeaderSize) + (ProcessListsIndex << 2));
		processList = longAt(((((char *) processLists)) + BaseHeaderSize) + ((priority - 1) << 2));
		/* begin addLastLink:toList: */
		if ((longAt(((((char *) processList)) + BaseHeaderSize) + (FirstLinkIndex << 2))) == foo->nilObj) {
			/* begin storePointer:ofObject:withValue: */
			if (processList < foo->youngStart) {
				possibleRootStoreIntovalue(processList, activeProc);
			}
			longAtput(((((char *) processList)) + BaseHeaderSize) + (FirstLinkIndex << 2), activeProc);
		} else {
			lastLink = longAt(((((char *) processList)) + BaseHeaderSize) + (LastLinkIndex << 2));
			/* begin storePointer:ofObject:withValue: */
			if (lastLink < foo->youngStart) {
				possibleRootStoreIntovalue(lastLink, activeProc);
			}
			longAtput(((((char *) lastLink)) + BaseHeaderSize) + (NextLinkIndex << 2), activeProc);
		}
		/* begin storePointer:ofObject:withValue: */
		if (processList < foo->youngStart) {
			possibleRootStoreIntovalue(processList, activeProc);
		}
		longAtput(((((char *) processList)) + BaseHeaderSize) + (LastLinkIndex << 2), activeProc);
		/* begin storePointer:ofObject:withValue: */
		if (activeProc < foo->youngStart) {
			possibleRootStoreIntovalue(activeProc, processList);
		}
		longAtput(((((char *) activeProc)) + BaseHeaderSize) + (MyListIndex << 2), processList);
		transferTo(aProcess);
	} else {
		/* begin putToSleep: */
		priority1 = ((longAt(((((char *) aProcess)) + BaseHeaderSize) + (PriorityIndex << 2))) >> 1);
		processLists1 = longAt(((((char *) (longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SchedulerAssociation << 2))))) + BaseHeaderSize) + (ValueIndex << 2))))) + BaseHeaderSize) + (ProcessListsIndex << 2));
		processList1 = longAt(((((char *) processLists1)) + BaseHeaderSize) + ((priority1 - 1) << 2));
		/* begin addLastLink:toList: */
		if ((longAt(((((char *) processList1)) + BaseHeaderSize) + (FirstLinkIndex << 2))) == foo->nilObj) {
			/* begin storePointer:ofObject:withValue: */
			if (processList1 < foo->youngStart) {
				possibleRootStoreIntovalue(processList1, aProcess);
			}
			longAtput(((((char *) processList1)) + BaseHeaderSize) + (FirstLinkIndex << 2), aProcess);
		} else {
			lastLink1 = longAt(((((char *) processList1)) + BaseHeaderSize) + (LastLinkIndex << 2));
			/* begin storePointer:ofObject:withValue: */
			if (lastLink1 < foo->youngStart) {
				possibleRootStoreIntovalue(lastLink1, aProcess);
			}
			longAtput(((((char *) lastLink1)) + BaseHeaderSize) + (NextLinkIndex << 2), aProcess);
		}
		/* begin storePointer:ofObject:withValue: */
		if (processList1 < foo->youngStart) {
			possibleRootStoreIntovalue(processList1, aProcess);
		}
		longAtput(((((char *) processList1)) + BaseHeaderSize) + (LastLinkIndex << 2), aProcess);
		/* begin storePointer:ofObject:withValue: */
		if (aProcess < foo->youngStart) {
			possibleRootStoreIntovalue(aProcess, processList1);
		}
		longAtput(((((char *) aProcess)) + BaseHeaderSize) + (MyListIndex << 2), processList1);
	}
}


/*	Reverse the given range of Display words (at different bit 
	depths, this will reverse different numbers of pixels). Used to 
	give feedback during VM activities such as garbage 
	collection when debugging. It is assumed that the given 
	word range falls entirely within the first line of the Display. */

int reverseDisplayFromto(int startIndex, int endIndex) {
    int dispBitsPtr;
    int w;
    int ptr;
    int displayObj;
    int reversed;

	displayObj = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (TheDisplay << 2));
	if (!((((displayObj & 1) == 0) && (((((unsigned) (longAt(displayObj))) >> 8) & 15) <= 4)) && ((lengthOf(displayObj)) >= 4))) {
		return null;
	}
	w = fetchIntegerofObject(1, displayObj);
	dispBitsPtr = longAt(((((char *) displayObj)) + BaseHeaderSize) + (0 << 2));
	if ((dispBitsPtr & 1)) {
		return null;
	}
	dispBitsPtr += BaseHeaderSize;
	for (ptr = (dispBitsPtr + (startIndex * 4)); ptr <= (dispBitsPtr + (endIndex * 4)); ptr += 4) {
		reversed = (longAt(ptr)) ^ 4294967295U;
		longAtput(ptr, reversed);
	}
	displayBitsOfLeftTopRightBottom(displayObj, 0, 0, w, 1);
	ioForceDisplayUpdate();
}


/*	rewrite the cache entry with the provided prim index and matching function pointer */

int rewriteMethodCacheSelclassprimIndex(int selector, int class, int localPrimIndex) {
    int primPtr;

	if (localPrimIndex == 0) {
		primPtr = 0;
	} else {
		primPtr = ((int) (primitiveTable[localPrimIndex]));
	}
	rewriteMethodCacheSelclassprimIndexprimFunction(selector, class, localPrimIndex, primPtr);
}


/*	Rewrite an existing entry in the method cache with a new primitive 
	index & function address. Used by primExternalCall to make direct jumps to found external prims */

int rewriteMethodCacheSelclassprimIndexprimFunction(int selector, int class, int localPrimIndex, int localPrimAddress) {
    int probe;
    int p;
    int hash;

	hash = selector ^ class;
	for (p = 0; p <= (CacheProbeMax - 1); p += 1) {
		probe = (((unsigned) hash) >> p) & MethodCacheMask;
		if (((methodCache[probe + MethodCacheSelector]) == selector) && ((methodCache[probe + MethodCacheClass]) == class)) {
			methodCache[probe + MethodCachePrim] = localPrimIndex;
			methodCache[probe + MethodCachePrimFunction] = localPrimAddress;
			return null;
		}
	}
}

int setCompilerInitialized(int newFlag) {
register struct foo * foo = &fum;
    int oldFlag;

	oldFlag = foo->compilerInitialized;
	foo->compilerInitialized = newFlag;
	return oldFlag;
}

int setFullScreenFlag(int value) {
	foo->fullScreenFlag = value;
}

int setInterruptCheckCounter(int value) {
	foo->interruptCheckCounter = value;
}

int setInterruptKeycode(int value) {
	foo->interruptKeycode = value;
}

int setInterruptPending(int value) {
	foo->interruptPending = value;
}

int setNextWakeupTick(int value) {
	foo->nextWakeupTick = value;
}

int setSavedWindowSize(int value) {
	foo->savedWindowSize = value;
}


/*	Repaint the portion of the Smalltalk screen bounded by the affected rectangle. Used to synchronize the screen after a Bitblt to the Smalltalk Display object. */

int showDisplayBitsLeftTopRightBottom(int aForm, int l, int t, int r, int b) {
	if (foo->deferDisplayUpdates) {
		return null;
	}
	displayBitsOfLeftTopRightBottom(aForm, l, t, r, b);
}


/*	Record the given semaphore index in the double buffer semaphores array to be signaled at the next convenient moment. Force a real interrupt check as soon as possible. */

int signalSemaphoreWithIndex(int index) {
register struct foo * foo = &fum;
	if (index <= 0) {
		return null;
	}
	if (foo->semaphoresUseBufferA) {
		if (foo->semaphoresToSignalCountA < SemaphoresToSignalSize) {
			foo->semaphoresToSignalCountA += 1;
			semaphoresToSignalA[foo->semaphoresToSignalCountA] = index;
		}
	} else {
		if (foo->semaphoresToSignalCountB < SemaphoresToSignalSize) {
			foo->semaphoresToSignalCountB += 1;
			semaphoresToSignalB[foo->semaphoresToSignalCountB] = index;
		}
	}
	/* begin forceInterruptCheck */
	foo->interruptCheckCounter = -1000;
}


/*	Return a full 32 bit integer object for the given integer value */

int signed32BitIntegerFor(int integerValue) {
register struct foo * foo = &fum;
    int value;
    int newLargeInteger;
    int largeClass;

	if ((integerValue ^ (integerValue << 1)) >= 0) {
		return ((integerValue << 1) | 1);
	}
	if (integerValue < 0) {
		largeClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargeNegativeInteger << 2));
		value = 0 - integerValue;
	} else {
		largeClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargePositiveInteger << 2));
		value = integerValue;
	}
	newLargeInteger = instantiateClassindexableSize(largeClass, 4);
	byteAtput(((((char *) newLargeInteger)) + BaseHeaderSize) + 3, (((unsigned) value) >> 24) & 255);
	byteAtput(((((char *) newLargeInteger)) + BaseHeaderSize) + 2, (((unsigned) value) >> 16) & 255);
	byteAtput(((((char *) newLargeInteger)) + BaseHeaderSize) + 1, (((unsigned) value) >> 8) & 255);
	byteAtput(((((char *) newLargeInteger)) + BaseHeaderSize) + 0, value & 255);
	return newLargeInteger;
}


/*	Convert the given object into an integer value.
	The object may be either a positive ST integer or a four-byte LargeInteger. */

int signed32BitValueOf(int oop) {
register struct foo * foo = &fum;
    int sz;
    int value;
    int largeClass;
    int negative;
    int ccIndex;
    int header;
    int sz1;

	if ((oop & 1)) {
		return (oop >> 1);
	}
	/* begin fetchClassOf: */
	if ((oop & 1)) {
		largeClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		largeClass = (longAt(oop - 4)) & AllButTypeMask;
		goto l1;
	} else {
		largeClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	if (largeClass == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargePositiveInteger << 2)))) {
		negative = 0;
	} else {
		if (largeClass == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargeNegativeInteger << 2)))) {
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
		sz1 = (longAt(oop - 8)) & AllButTypeMask;
	} else {
		sz1 = header & SizeMask;
	}
	if (((((unsigned) header) >> 8) & 15) < 8) {
		sz = ((unsigned) (sz1 - BaseHeaderSize)) >> 2;
		goto l2;
	} else {
		sz = (sz1 - BaseHeaderSize) - (((((unsigned) header) >> 8) & 15) & 3);
		goto l2;
	}
	sz = null;
l2:	/* end lengthOf: */;
	if (!(sz == 4)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	value = (((byteAt(((((char *) oop)) + BaseHeaderSize) + 0)) + ((byteAt(((((char *) oop)) + BaseHeaderSize) + 1)) << 8)) + ((byteAt(((((char *) oop)) + BaseHeaderSize) + 2)) << 16)) + ((byteAt(((((char *) oop)) + BaseHeaderSize) + 3)) << 24);
	if (negative) {
		return 0 - value;
	} else {
		return value;
	}
}


/*	Return a Large Integer object for the given integer value */

int signed64BitIntegerFor(squeakInt64 integerValue) {
register struct foo * foo = &fum;
    squeakInt64 value;
    int intValue;
    int i;
    int newLargeInteger;
    int largeClass;
    int check;

	if (integerValue < 0) {
		largeClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargeNegativeInteger << 2));
		value = 0 - integerValue;
	} else {
		largeClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargePositiveInteger << 2));
		value = integerValue;
	}
	if ((sizeof(value)) == 4) {
		return signed32BitIntegerFor(integerValue);
	}
	check = value >> 32;
	if (check == 0) {
		return signed32BitIntegerFor(integerValue);
	}
	newLargeInteger = instantiateSmallClasssizeInBytesfill(largeClass, 12, 0);
	for (i = 0; i <= 7; i += 1) {
		intValue = ( value >> (i * 8)) & 255;
		byteAtput(((((char *) newLargeInteger)) + BaseHeaderSize) + i, intValue);
	}
	return newLargeInteger;
}


/*	Convert the given object into an integer value.
	The object may be either a positive ST integer or a eight-byte LargeInteger. */

squeakInt64 signed64BitValueOf(int oop) {
register struct foo * foo = &fum;
    int szsqueakInt64;
    int sz;
    squeakInt64 value;
    int i;
    int largeClass;
    int negative;
    int ccIndex;
    int header;
    int sz1;

	if ((oop & 1)) {
		return ((squeakInt64) ((oop >> 1)));
	}
	/* begin fetchClassOf: */
	if ((oop & 1)) {
		largeClass = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l1;
	}
	ccIndex = (((unsigned) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		largeClass = (longAt(oop - 4)) & AllButTypeMask;
		goto l1;
	} else {
		largeClass = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l1;
	}
l1:	/* end fetchClassOf: */;
	if (largeClass == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargePositiveInteger << 2)))) {
		negative = 0;
	} else {
		if (largeClass == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassLargeNegativeInteger << 2)))) {
			negative = 1;
		} else {
			/* begin primitiveFail */
			foo->successFlag = 0;
			return null;
		}
	}
	szsqueakInt64 = sizeof(squeakInt64);
	/* begin lengthOf: */
	header = longAt(oop);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz1 = (longAt(oop - 8)) & AllButTypeMask;
	} else {
		sz1 = header & SizeMask;
	}
	if (((((unsigned) header) >> 8) & 15) < 8) {
		sz = ((unsigned) (sz1 - BaseHeaderSize)) >> 2;
		goto l2;
	} else {
		sz = (sz1 - BaseHeaderSize) - (((((unsigned) header) >> 8) & 15) & 3);
		goto l2;
	}
	sz = null;
l2:	/* end lengthOf: */;
	if (sz > szsqueakInt64) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	value = 0;
	for (i = 0; i <= (sz - 1); i += 1) {
		value += (((squeakInt64) (byteAt(((((char *) oop)) + BaseHeaderSize) + i)))) << (i * 8);
	}
	if (negative) {
		return 0 - value;
	} else {
		return value;
	}
}


/*	Answer the number of bytes in the given object, including its base header, rounded up to an integral number of words. */
/*	Note: byte indexable objects need to have low bits subtracted from this size. */

int sizeBitsOf(int oop) {
    int header;

	header = longAt(oop);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		return (longAt(oop - 8)) & AllButTypeMask;
	} else {
		return header & SizeMask;
	}
}


/*	Return the number of indexable fields of the given object. This method is to be called from an automatically generated C primitive. The argument is assumed to be a pointer to the first indexable field of a words or bytes object; the object header start 4 bytes before that. */
/*	Note: Only called by translated primitive code. */

int sizeOfSTArrayFromCPrimitive(void *cPtr) {
    int oop;
    int header;
    int sz;

	oop = ((int) cPtr) - 4;
	if (!(((oop & 1) == 0) && (isWordsOrBytesNonInt(oop)))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return 0;
	}
	/* begin lengthOf: */
	header = longAt(oop);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(oop - 8)) & AllButTypeMask;
	} else {
		sz = header & SizeMask;
	}
	if (((((unsigned) header) >> 8) & 15) < 8) {
		return ((unsigned) (sz - BaseHeaderSize)) >> 2;
	} else {
		return (sz - BaseHeaderSize) - (((((unsigned) header) >> 8) & 15) & 3);
	}
	return null;
}


/*	Returns the number of slots in the receiver.
	If the receiver is a byte object, return the number of bytes.
	Otherwise return the number of words. */

int slotSizeOf(int oop) {
    int header;
    int sz;

	if ((oop & 1)) {
		return 0;
	}
	/* begin lengthOf: */
	header = longAt(oop);
	/* begin lengthOf:baseHeader:format: */
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(oop - 8)) & AllButTypeMask;
	} else {
		sz = header & SizeMask;
	}
	if (((((unsigned) header) >> 8) & 15) < 8) {
		return ((unsigned) (sz - BaseHeaderSize)) >> 2;
	} else {
		return (sz - BaseHeaderSize) - (((((unsigned) header) >> 8) & 15) & 3);
	}
	return null;
}


/*	update state of active context */

int snapshot(int embedded) {
register struct foo * foo = &fum;
    int rcvr;
    int dataSize;
    int setMacType;
    int activeProc;
    int top;
    int sp;
    int sp1;
    int sp2;
    int valuePointer;
    int fmt;
    int sz;
    int oop;
    int i;
    int header;
    int oop1;
    int i1;
    int header1;
    int chunk;
    int sz1;
    int header2;

	if (foo->compilerInitialized) {
		compilerPreSnapshot();
	} else {
		/* begin storeContextRegisters: */
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (StackPointerIndex << 2), (((((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - TempFrameStart) + 1) << 1) | 1));
	}
	activeProc = longAt(((((char *) (longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SchedulerAssociation << 2))))) + BaseHeaderSize) + (ValueIndex << 2))))) + BaseHeaderSize) + (ActiveProcessIndex << 2));
	/* begin storePointer:ofObject:withValue: */
	valuePointer = foo->activeContext;
	if (activeProc < foo->youngStart) {
		possibleRootStoreIntovalue(activeProc, valuePointer);
	}
	longAtput(((((char *) activeProc)) + BaseHeaderSize) + (SuspendedContextIndex << 2), valuePointer);
	incrementalGC();
	fullGC();
	/* begin snapshotCleanUp */
	/* begin oopFromChunk: */
	chunk = startOfMemory();
	oop = chunk + (headerTypeBytes[(longAt(chunk)) & TypeMask]);
	while (oop < foo->endOfMemory) {
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			header = longAt(oop);
			fmt = (((unsigned) header) >> 8) & 15;
			if ((fmt == 3) && ((((((unsigned) header) >> 12) & 31) == 13) || ((((((unsigned) header) >> 12) & 31) == 14) || (((((unsigned) header) >> 12) & 31) == 4)))) {
				/* begin sizeBitsOf: */
				header1 = longAt(oop);
				if ((header1 & TypeMask) == HeaderTypeSizeAndClass) {
					sz = (longAt(oop - 8)) & AllButTypeMask;
					goto l1;
				} else {
					sz = header1 & SizeMask;
					goto l1;
				}
			l1:	/* end sizeBitsOf: */;
				for (i = ((lastPointerOf(oop)) + 4); i <= (sz - BaseHeaderSize); i += 4) {
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
			if (oop >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz1 = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header2 = longAt(oop);
			if ((header2 & TypeMask) == HeaderTypeSizeAndClass) {
				sz1 = (longAt(oop - 8)) & AllButTypeMask;
				goto l2;
			} else {
				sz1 = header2 & SizeMask;
				goto l2;
			}
		l2:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz1) + (headerTypeBytes[(longAt(oop + sz1)) & TypeMask]);
	}
	/* begin clearRootsTable */
	for (i1 = 1; i1 <= foo->rootTableCount; i1 += 1) {
		oop1 = rootTable[i1];
		longAtput(oop1, (longAt(oop1)) & AllButRootBit);
		rootTable[i1] = 0;
	}
	foo->rootTableCount = 0;

	/* Assume all objects are below the start of the free block */

	dataSize = foo->freeBlock - (startOfMemory());
	if (foo->successFlag) {
		/* begin popStack */
		top = longAt(foo->stackPointer);
		foo->stackPointer -= 4;
		rcvr = top;
		/* begin push: */
		longAtput(sp = foo->stackPointer + 4, foo->trueObj);
		foo->stackPointer = sp;
		writeImageFile(dataSize);
		if (!(embedded)) {
			setMacType = ioLoadFunctionFrom("setMacFileTypeAndCreator", "FilePlugin");
			if (!(setMacType == 0)) {
				((int (*) (char*, char*, char*)) setMacType) (imageName, "STim", "FAST");
			}
		}
		/* begin pop: */
		foo->stackPointer -= 1 * 4;
	}
	beRootIfOld(foo->activeContext);
	if (foo->successFlag) {
		/* begin push: */
		longAtput(sp1 = foo->stackPointer + 4, foo->falseObj);
		foo->stackPointer = sp1;
	} else {
		/* begin push: */
		longAtput(sp2 = foo->stackPointer + 4, rcvr);
		foo->stackPointer = sp2;
	}
	if (foo->compilerInitialized) {
		compilerPostSnapshot();
	}
}


/*	Return one of the objects in the SpecialObjectsArray */

int splObj(int index) {
	return longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (index << 2));
}


/*	Return what ST would return for <obj> at: index. */

int stObjectat(int array, int index) {
register struct foo * foo = &fum;
    int fmt;
    int totalLength;
    int hdr;
    int stSize;
    int fixedFields;
    int sp;
    int sz;
    int classFormat;
    int class;
    int ccIndex;

	hdr = longAt(array);
	fmt = (((unsigned) hdr) >> 8) & 15;
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(array - 8)) & AllButTypeMask;
	} else {
		sz = hdr & SizeMask;
	}
	if (fmt < 8) {
		totalLength = ((unsigned) (sz - BaseHeaderSize)) >> 2;
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
		class = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l4;
	}
	ccIndex = (((unsigned) (longAt(array))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(array - 4)) & AllButTypeMask;
		goto l4;
	} else {
		class = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l4;
	}
l4:	/* end fetchClassOf: */;
	classFormat = (longAt(((((char *) class)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1;
	fixedFields = (((((unsigned) classFormat) >> 11) & 192) + ((((unsigned) classFormat) >> 2) & 63)) - 1;
l3:	/* end fixedFieldsOf:format:length: */;
	if ((fmt == 3) && ((((((unsigned) hdr) >> 12) & 31) == 13) || ((((((unsigned) hdr) >> 12) & 31) == 14) || (((((unsigned) hdr) >> 12) & 31) == 4)))) {
		/* begin fetchStackPointerOf: */
		sp = longAt(((((char *) array)) + BaseHeaderSize) + (StackPointerIndex << 2));
		if (!((sp & 1))) {
			stSize = 0;
			goto l1;
		}
		stSize = (sp >> 1);
	l1:	/* end fetchStackPointerOf: */;
	} else {
		stSize = totalLength - fixedFields;
	}
	if (((((unsigned ) index)) >= 1) && ((((unsigned ) index)) <= (((unsigned ) stSize)))) {
		/* begin subscript:with:format: */
		if (fmt <= 4) {
			return longAt(((((char *) array)) + BaseHeaderSize) + (((index + fixedFields) - 1) << 2));
		}
		if (fmt < 8) {
			return positive32BitIntegerFor(longAt(((((char *) array)) + BaseHeaderSize) + (((index + fixedFields) - 1) << 2)));
		} else {
			return (((byteAt(((((char *) array)) + BaseHeaderSize) + ((index + fixedFields) - 1))) << 1) | 1);
		}
		return null;
	} else {
		foo->successFlag = 0;
		return 0;
	}
}


/*	Do what ST would return for <obj> at: index put: value. */

int stObjectatput(int array, int index, int value) {
register struct foo * foo = &fum;
    int fmt;
    int totalLength;
    int hdr;
    int stSize;
    int fixedFields;
    int sp;
    int sz;
    int classFormat;
    int class;
    int valueToStore;
    int ccIndex;

	hdr = longAt(array);
	fmt = (((unsigned) hdr) >> 8) & 15;
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(array - 8)) & AllButTypeMask;
	} else {
		sz = hdr & SizeMask;
	}
	if (fmt < 8) {
		totalLength = ((unsigned) (sz - BaseHeaderSize)) >> 2;
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
		class = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l4;
	}
	ccIndex = (((unsigned) (longAt(array))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(array - 4)) & AllButTypeMask;
		goto l4;
	} else {
		class = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l4;
	}
l4:	/* end fetchClassOf: */;
	classFormat = (longAt(((((char *) class)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1;
	fixedFields = (((((unsigned) classFormat) >> 11) & 192) + ((((unsigned) classFormat) >> 2) & 63)) - 1;
l3:	/* end fixedFieldsOf:format:length: */;
	if ((fmt == 3) && ((((((unsigned) hdr) >> 12) & 31) == 13) || ((((((unsigned) hdr) >> 12) & 31) == 14) || (((((unsigned) hdr) >> 12) & 31) == 4)))) {
		/* begin fetchStackPointerOf: */
		sp = longAt(((((char *) array)) + BaseHeaderSize) + (StackPointerIndex << 2));
		if (!((sp & 1))) {
			stSize = 0;
			goto l1;
		}
		stSize = (sp >> 1);
	l1:	/* end fetchStackPointerOf: */;
	} else {
		stSize = totalLength - fixedFields;
	}
	if (((((unsigned ) index)) >= 1) && ((((unsigned ) index)) <= (((unsigned ) stSize)))) {
		/* begin subscript:with:storing:format: */
		if (fmt <= 4) {
			/* begin storePointer:ofObject:withValue: */
			if (array < foo->youngStart) {
				possibleRootStoreIntovalue(array, value);
			}
			longAtput(((((char *) array)) + BaseHeaderSize) + (((index + fixedFields) - 1) << 2), value);
		} else {
			if (fmt < 8) {
				valueToStore = positive32BitValueOf(value);
				if (foo->successFlag) {
					longAtput(((((char *) array)) + BaseHeaderSize) + (((index + fixedFields) - 1) << 2), valueToStore);
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
					byteAtput(((((char *) array)) + BaseHeaderSize) + ((index + fixedFields) - 1), valueToStore);
				}
			}
		}
	} else {
		foo->successFlag = 0;
	}
}


/*	Return the number of indexable fields in the given object. (i.e., what Smalltalk would return for <obj> size). */
/*	Note: Assume oop is not a SmallInteger! */

int stSizeOf(int oop) {
register struct foo * foo = &fum;
    int fmt;
    int totalLength;
    int hdr;
    int fixedFields;
    int sp;
    int sz;
    int classFormat;
    int class;
    int ccIndex;

	hdr = longAt(oop);
	fmt = (((unsigned) hdr) >> 8) & 15;
	/* begin lengthOf:baseHeader:format: */
	if ((hdr & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(oop - 8)) & AllButTypeMask;
	} else {
		sz = hdr & SizeMask;
	}
	if (fmt < 8) {
		totalLength = ((unsigned) (sz - BaseHeaderSize)) >> 2;
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
		class = longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassInteger << 2));
		goto l3;
	}
	ccIndex = (((unsigned) (longAt(oop))) >> 12) & 31;
	if (ccIndex == 0) {
		class = (longAt(oop - 4)) & AllButTypeMask;
		goto l3;
	} else {
		class = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (CompactClasses << 2))))) + BaseHeaderSize) + ((ccIndex - 1) << 2));
		goto l3;
	}
l3:	/* end fetchClassOf: */;
	classFormat = (longAt(((((char *) class)) + BaseHeaderSize) + (InstanceSpecificationIndex << 2))) - 1;
	fixedFields = (((((unsigned) classFormat) >> 11) & 192) + ((((unsigned) classFormat) >> 2) & 63)) - 1;
l2:	/* end fixedFieldsOf:format:length: */;
	if ((fmt == 3) && ((((((unsigned) hdr) >> 12) & 31) == 13) || ((((((unsigned) hdr) >> 12) & 31) == 14) || (((((unsigned) hdr) >> 12) & 31) == 4)))) {
		/* begin fetchStackPointerOf: */
		sp = longAt(((((char *) oop)) + BaseHeaderSize) + (StackPointerIndex << 2));
		if (!((sp & 1))) {
			return 0;
		}
		return (sp >> 1);
	} else {
		return totalLength - fixedFields;
	}
}


/*	Note: May be called by translated primitive code. */

double stackFloatValue(int offset) {
register struct foo * foo = &fum;
    double result;
    int floatPointer;

	floatPointer = longAt(foo->stackPointer - (offset * 4));
	if (!((fetchClassOf(floatPointer)) == (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (ClassFloat << 2))))) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return 0.0;
	}
	;
	fetchFloatAtinto(floatPointer + BaseHeaderSize, result);
	return result;
}

int stackIntegerValue(int offset) {
register struct foo * foo = &fum;
    int integerPointer;

	integerPointer = longAt(foo->stackPointer - (offset * 4));
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

int stackObjectValue(int offset) {
register struct foo * foo = &fum;
    int oop;

	oop = longAt(foo->stackPointer - (offset * 4));
	if ((oop & 1)) {
		/* begin primitiveFail */
		foo->successFlag = 0;
		return null;
	}
	return oop;
}

int stackValue(int offset) {
	return longAt(foo->stackPointer - (offset * 4));
}


/*	Return the start of object memory. */

int startOfMemory(void) {
	return (unsigned) memory;
}


/*	Note: May be called by translated primitive code. */

int storeIntegerofObjectwithValue(int fieldIndex, int objectPointer, int integerValue) {
	if ((integerValue ^ (integerValue << 1)) >= 0) {
		longAtput(((((char *) objectPointer)) + BaseHeaderSize) + (fieldIndex << 2), ((integerValue << 1) | 1));
	} else {
		/* begin primitiveFail */
		foo->successFlag = 0;
	}
}


/*	Note must check here for stores of young objects into old ones.  */

int storePointerofObjectwithValue(int fieldIndex, int oop, int valuePointer) {
	if (oop < foo->youngStart) {
		possibleRootStoreIntovalue(oop, valuePointer);
	}
	return longAtput(((((char *) oop)) + BaseHeaderSize) + (fieldIndex << 2), valuePointer);
}

int success(int successValue) {
register struct foo * foo = &fum;
	foo->successFlag = successValue && foo->successFlag;
}


/*	Return true if there is enough free space after doing a garbage collection. If not, signal that space is low. */

int sufficientSpaceAfterGC(int minFree) {
register struct foo * foo = &fum;
    int growSize;
    int limit;

	incrementalGC();
	if ((((unsigned ) ((longAt(foo->freeBlock)) & AllButTypeMask))) < (((unsigned ) minFree))) {
		if (foo->signalLowSpace) {
			return 0;
		}
		fullGC();
		if ((((unsigned ) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= ((((unsigned ) minFree)) + 15000)) {
			return 1;
		}
		growSize = (minFree - ((longAt(foo->freeBlock)) & AllButTypeMask)) + foo->growHeadroom;
		/* begin growObjectMemory: */
		limit = sqGrowMemoryBy(foo->memoryLimit, growSize);
		if (!(limit == foo->memoryLimit)) {
			foo->memoryLimit = limit - 24;
			initializeMemoryFirstFree(foo->freeBlock);
		}
		if ((((unsigned ) ((longAt(foo->freeBlock)) & AllButTypeMask))) >= ((((unsigned ) minFree)) + 15000)) {
			return 1;
		}
		return 0;
	}
	return 1;
}

int superclassOf(int classPointer) {
	return longAt(((((char *) classPointer)) + BaseHeaderSize) + (SuperclassIndex << 2));
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

int sweepPhase(void) {
register struct foo * foo = &fum;
    int endOfMemoryLocal;
    int firstFree;
    int oopHeader;
    int freeChunkSize;
    int oop;
    int entriesAvailable;
    int freeChunk;
    int hdrBytes;
    int oopHeaderType;
    int survivors;
    int oopSize;

	entriesAvailable = fwdTableInit(8);
	survivors = 0;
	freeChunk = null;

	/* will be updated later */

	firstFree = null;
	endOfMemoryLocal = foo->endOfMemory;
	oop = foo->youngStart + (headerTypeBytes[(longAt(foo->youngStart)) & TypeMask]);
	while (oop < endOfMemoryLocal) {
		oopHeader = longAt(oop);
		oopHeaderType = oopHeader & TypeMask;
		hdrBytes = headerTypeBytes[oopHeaderType];
		if ((oopHeaderType & 1) == 1) {
			oopSize = oopHeader & SizeMask;
		} else {
			if (oopHeaderType == HeaderTypeSizeAndClass) {
				oopSize = (longAt(oop - 8)) & AllButTypeMask;
			} else {
				oopSize = oopHeader & AllButTypeMask;
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
			if (((((unsigned) (longAt(oop))) >> 8) & 15) == 4) {
				finalizeReference(oop);
			}
			if (entriesAvailable > 0) {
				entriesAvailable -= 1;
			} else {
				firstFree = freeChunk;
			}
			if (freeChunk != null) {
				longAtput(freeChunk, (freeChunkSize & AllButTypeMask) | HeaderTypeFree);
				freeChunk = null;
			}
			survivors += 1;
		}
		oop = (oop + oopSize) + (headerTypeBytes[(longAt(oop + oopSize)) & TypeMask]);
	}
	if (freeChunk != null) {
		longAtput(freeChunk, (freeChunkSize & AllButTypeMask) | HeaderTypeFree);
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

int synchronousSignal(int aSemaphore) {
register struct foo * foo = &fum;
    int excessSignals;

	if ((longAt(((((char *) aSemaphore)) + BaseHeaderSize) + (FirstLinkIndex << 2))) == foo->nilObj) {
		excessSignals = fetchIntegerofObject(ExcessSignalsIndex, aSemaphore);
		/* begin storeInteger:ofObject:withValue: */
		if (((excessSignals + 1) ^ ((excessSignals + 1) << 1)) >= 0) {
			longAtput(((((char *) aSemaphore)) + BaseHeaderSize) + (ExcessSignalsIndex << 2), (((excessSignals + 1) << 1) | 1));
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

int transferTo(int aProc) {
register struct foo * foo = &fum;
    int newProc;
    int sched;
    int oldProc;
    int valuePointer;
    int tmp;
    int valuePointer1;

	newProc = aProc;
	sched = longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SchedulerAssociation << 2))))) + BaseHeaderSize) + (ValueIndex << 2));
	oldProc = longAt(((((char *) sched)) + BaseHeaderSize) + (ActiveProcessIndex << 2));
	/* begin storePointer:ofObject:withValue: */
	if (sched < foo->youngStart) {
		possibleRootStoreIntovalue(sched, newProc);
	}
	longAtput(((((char *) sched)) + BaseHeaderSize) + (ActiveProcessIndex << 2), newProc);
	if (foo->compilerInitialized) {
		compilerProcessChangeto(oldProc, newProc);
	} else {
		/* begin storePointer:ofObject:withValue: */
		valuePointer = foo->activeContext;
		if (oldProc < foo->youngStart) {
			possibleRootStoreIntovalue(oldProc, valuePointer);
		}
		longAtput(((((char *) oldProc)) + BaseHeaderSize) + (SuspendedContextIndex << 2), valuePointer);
		/* begin newActiveContext: */
		/* begin storeContextRegisters: */
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (InstructionPointerIndex << 2), ((((foo->instructionPointer - foo->method) - (BaseHeaderSize - 2)) << 1) | 1));
		longAtput(((((char *) foo->activeContext)) + BaseHeaderSize) + (StackPointerIndex << 2), (((((((unsigned) ((foo->stackPointer - foo->activeContext) - BaseHeaderSize)) >> 2) - TempFrameStart) + 1) << 1) | 1));
		if ((longAt(((((char *) newProc)) + BaseHeaderSize) + (SuspendedContextIndex << 2))) < foo->youngStart) {
			beRootIfOld(longAt(((((char *) newProc)) + BaseHeaderSize) + (SuspendedContextIndex << 2)));
		}
		foo->activeContext = longAt(((((char *) newProc)) + BaseHeaderSize) + (SuspendedContextIndex << 2));
		/* begin fetchContextRegisters: */
		tmp = longAt(((((char *) (longAt(((((char *) newProc)) + BaseHeaderSize) + (SuspendedContextIndex << 2))))) + BaseHeaderSize) + (MethodIndex << 2));
		if ((tmp & 1)) {
			tmp = longAt(((((char *) (longAt(((((char *) newProc)) + BaseHeaderSize) + (SuspendedContextIndex << 2))))) + BaseHeaderSize) + (HomeIndex << 2));
			if (tmp < foo->youngStart) {
				beRootIfOld(tmp);
			}
		} else {
			tmp = longAt(((((char *) newProc)) + BaseHeaderSize) + (SuspendedContextIndex << 2));
		}
		foo->theHomeContext = tmp;
		foo->receiver = longAt(((((char *) tmp)) + BaseHeaderSize) + (ReceiverIndex << 2));
		foo->method = longAt(((((char *) tmp)) + BaseHeaderSize) + (MethodIndex << 2));
		tmp = ((longAt(((((char *) (longAt(((((char *) newProc)) + BaseHeaderSize) + (SuspendedContextIndex << 2))))) + BaseHeaderSize) + (InstructionPointerIndex << 2))) >> 1);
		foo->instructionPointer = ((foo->method + tmp) + BaseHeaderSize) - 2;
		tmp = ((longAt(((((char *) (longAt(((((char *) newProc)) + BaseHeaderSize) + (SuspendedContextIndex << 2))))) + BaseHeaderSize) + (StackPointerIndex << 2))) >> 1);
		foo->stackPointer = ((longAt(((((char *) newProc)) + BaseHeaderSize) + (SuspendedContextIndex << 2))) + BaseHeaderSize) + (((TempFrameStart + tmp) - 1) * 4);
		/* begin storePointer:ofObject:withValue: */
		valuePointer1 = foo->nilObj;
		if (newProc < foo->youngStart) {
			possibleRootStoreIntovalue(newProc, valuePointer1);
		}
		longAtput(((((char *) newProc)) + BaseHeaderSize) + (SuspendedContextIndex << 2), valuePointer1);
	}
	foo->reclaimableContextCount = 0;
}

int trueObject(void) {
	return foo->trueObj;
}


/*	update pointers in the given memory range */

int updatePointersInRangeFromto(int memStart, int memEnd) {
register struct foo * foo = &fum;
    int oop;
    int fieldOop;
    int fieldOffset;
    int fwdBlock;
    int newOop;
    int fwdBlock1;
    int header;
    int header1;
    int header2;
    int fmt;
    int methodHeader;
    int size;
    int fwdBlock2;
    int contextSize;
    int header3;
    int sp;
    int newClassOop;
    int classHeader;
    int fwdBlock3;
    int newClassHeader;
    int classOop;
    int fwdBlock11;
    int header4;
    int header11;
    int header21;
    int sz;
    int realHeader;
    int fwdBlock4;
    int header5;
    int sz1;
    int header12;

	oop = memStart + (headerTypeBytes[(longAt(memStart)) & TypeMask]);
	while (oop < memEnd) {
		if (!(((longAt(oop)) & TypeMask) == HeaderTypeFree)) {
			/* begin remapFieldsAndClassOf: */
			/* begin lastPointerWhileForwarding: */
			header3 = longAt(oop);
			if ((header3 & MarkBit) != 0) {
				fwdBlock2 = (header3 & AllButMarkBitAndTypeMask) << 1;
				if (DoAssertionChecks) {
					/* begin fwdBlockValidate: */
					if (!((fwdBlock2 > foo->endOfMemory) && ((fwdBlock2 <= foo->fwdTableNext) && ((fwdBlock2 & 3) == 0)))) {
						error("invalid fwd table entry");
					}
				}
				header3 = longAt(fwdBlock2 + 4);
			}
			fmt = (((unsigned) header3) >> 8) & 15;
			if (fmt <= 4) {
				if ((fmt == 3) && ((((((unsigned) header3) >> 12) & 31) == 13) || ((((((unsigned) header3) >> 12) & 31) == 14) || (((((unsigned) header3) >> 12) & 31) == 4)))) {
					/* begin fetchStackPointerOf: */
					sp = longAt(((((char *) oop)) + BaseHeaderSize) + (StackPointerIndex << 2));
					if (!((sp & 1))) {
						contextSize = 0;
						goto l1;
					}
					contextSize = (sp >> 1);
				l1:	/* end fetchStackPointerOf: */;
					fieldOffset = (CtxtTempFrameStart + contextSize) * 4;
					goto l2;
				}
				if ((header3 & TypeMask) == HeaderTypeSizeAndClass) {
					size = (longAt(oop - 8)) & AllButTypeMask;
				} else {
					size = header3 & SizeMask;
				}
				fieldOffset = size - BaseHeaderSize;
				goto l2;
			}
			if (fmt < 12) {
				fieldOffset = 0;
				goto l2;
			}
			methodHeader = longAt(oop + BaseHeaderSize);
			fieldOffset = (((((unsigned) methodHeader) >> 10) & 255) * 4) + BaseHeaderSize;
		l2:	/* end lastPointerWhileForwarding: */;
			while (fieldOffset >= BaseHeaderSize) {
				fieldOop = longAt(oop + fieldOffset);
				if (((fieldOop & 1) == 0) && (((longAt(fieldOop)) & MarkBit) != 0)) {
					fwdBlock = ((longAt(fieldOop)) & AllButMarkBitAndTypeMask) << 1;
					if (DoAssertionChecks) {
						/* begin fwdBlockValidate: */
						if (!((fwdBlock > foo->endOfMemory) && ((fwdBlock <= foo->fwdTableNext) && ((fwdBlock & 3) == 0)))) {
							error("invalid fwd table entry");
						}
					}
					newOop = longAt(fwdBlock);
					longAtput(oop + fieldOffset, newOop);
					if ((oop < foo->youngStart) && (newOop >= foo->youngStart)) {
						/* begin beRootWhileForwarding: */
						header = longAt(oop);
						if ((header & MarkBit) != 0) {
							fwdBlock1 = (header & AllButMarkBitAndTypeMask) << 1;
							if (DoAssertionChecks) {
								/* begin fwdBlockValidate: */
								if (!((fwdBlock1 > foo->endOfMemory) && ((fwdBlock1 <= foo->fwdTableNext) && ((fwdBlock1 & 3) == 0)))) {
									error("invalid fwd table entry");
								}
							}
							/* begin noteAsRoot:headerLoc: */
							header1 = longAt(fwdBlock1 + 4);
							if ((header1 & RootBit) == 0) {
								if (foo->rootTableCount < RootTableRedZone) {
									foo->rootTableCount += 1;
									rootTable[foo->rootTableCount] = oop;
									longAtput(fwdBlock1 + 4, header1 | RootBit);
								} else {
									if (foo->rootTableCount < RootTableSize) {
										foo->rootTableCount += 1;
										rootTable[foo->rootTableCount] = oop;
										longAtput(fwdBlock1 + 4, header1 | RootBit);
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
									rootTable[foo->rootTableCount] = oop;
									longAtput(oop, header2 | RootBit);
								} else {
									if (foo->rootTableCount < RootTableSize) {
										foo->rootTableCount += 1;
										rootTable[foo->rootTableCount] = oop;
										longAtput(oop, header2 | RootBit);
										foo->allocationCount = foo->allocationsBetweenGCs + 1;
									}
								}
							}
						}
					}
				}
				fieldOffset -= 4;
			}
			/* begin remapClassOf: */
			if (((longAt(oop)) & TypeMask) == HeaderTypeShort) {
				goto l3;
			}
			classHeader = longAt(oop - 4);
			classOop = classHeader & AllButTypeMask;
			if (((classOop & 1) == 0) && (((longAt(classOop)) & MarkBit) != 0)) {
				fwdBlock3 = ((longAt(classOop)) & AllButMarkBitAndTypeMask) << 1;
				if (DoAssertionChecks) {
					/* begin fwdBlockValidate: */
					if (!((fwdBlock3 > foo->endOfMemory) && ((fwdBlock3 <= foo->fwdTableNext) && ((fwdBlock3 & 3) == 0)))) {
						error("invalid fwd table entry");
					}
				}
				newClassOop = longAt(fwdBlock3);
				newClassHeader = newClassOop | (classHeader & TypeMask);
				longAtput(oop - 4, newClassHeader);
				if ((oop < foo->youngStart) && (newClassOop >= foo->youngStart)) {
					/* begin beRootWhileForwarding: */
					header4 = longAt(oop);
					if ((header4 & MarkBit) != 0) {
						fwdBlock11 = (header4 & AllButMarkBitAndTypeMask) << 1;
						if (DoAssertionChecks) {
							/* begin fwdBlockValidate: */
							if (!((fwdBlock11 > foo->endOfMemory) && ((fwdBlock11 <= foo->fwdTableNext) && ((fwdBlock11 & 3) == 0)))) {
								error("invalid fwd table entry");
							}
						}
						/* begin noteAsRoot:headerLoc: */
						header11 = longAt(fwdBlock11 + 4);
						if ((header11 & RootBit) == 0) {
							if (foo->rootTableCount < RootTableRedZone) {
								foo->rootTableCount += 1;
								rootTable[foo->rootTableCount] = oop;
								longAtput(fwdBlock11 + 4, header11 | RootBit);
							} else {
								if (foo->rootTableCount < RootTableSize) {
									foo->rootTableCount += 1;
									rootTable[foo->rootTableCount] = oop;
									longAtput(fwdBlock11 + 4, header11 | RootBit);
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
								rootTable[foo->rootTableCount] = oop;
								longAtput(oop, header21 | RootBit);
							} else {
								if (foo->rootTableCount < RootTableSize) {
									foo->rootTableCount += 1;
									rootTable[foo->rootTableCount] = oop;
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
				if (oop >= foo->endOfMemory) {
					error("no objects after the end of memory");
				}
			}
			if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
				sz1 = (longAt(oop)) & AllButTypeMask;
			} else {
				/* begin sizeBitsOf: */
				header12 = longAt(oop);
				if ((header12 & TypeMask) == HeaderTypeSizeAndClass) {
					sz1 = (longAt(oop - 8)) & AllButTypeMask;
					goto l4;
				} else {
					sz1 = header12 & SizeMask;
					goto l4;
				}
			l4:	/* end sizeBitsOf: */;
			}
			oop = (oop + sz1) + (headerTypeBytes[(longAt(oop + sz1)) & TypeMask]);
			goto l5;
		}
		fwdBlock4 = (header5 & AllButMarkBitAndTypeMask) << 1;
		if (DoAssertionChecks) {
			/* begin fwdBlockValidate: */
			if (!((fwdBlock4 > foo->endOfMemory) && ((fwdBlock4 <= foo->fwdTableNext) && ((fwdBlock4 & 3) == 0)))) {
				error("invalid fwd table entry");
			}
		}
		realHeader = longAt(fwdBlock4 + 4);
		if ((realHeader & TypeMask) == HeaderTypeSizeAndClass) {
			sz = (longAt(oop - 8)) & AllButTypeMask;
		} else {
			sz = realHeader & SizeMask;
		}
		oop = (oop + sz) + (headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	l5:	/* end objectAfterWhileForwarding: */;
	}
}


/*	update pointers in root objects */

int updatePointersInRootObjectsFromto(int memStart, int memEnd) {
register struct foo * foo = &fum;
    int oop;
    int i;
    int fieldOop;
    int fieldOffset;
    int fwdBlock;
    int newOop;
    int fwdBlock1;
    int header;
    int header1;
    int header2;
    int fmt;
    int methodHeader;
    int size;
    int fwdBlock2;
    int contextSize;
    int header3;
    int sp;
    int newClassOop;
    int classHeader;
    int fwdBlock3;
    int newClassHeader;
    int classOop;
    int fwdBlock11;
    int header4;
    int header11;
    int header21;

	for (i = 1; i <= foo->rootTableCount; i += 1) {
		oop = rootTable[i];
		if ((oop < memStart) || (oop >= memEnd)) {
			/* begin remapFieldsAndClassOf: */
			/* begin lastPointerWhileForwarding: */
			header3 = longAt(oop);
			if ((header3 & MarkBit) != 0) {
				fwdBlock2 = (header3 & AllButMarkBitAndTypeMask) << 1;
				if (DoAssertionChecks) {
					/* begin fwdBlockValidate: */
					if (!((fwdBlock2 > foo->endOfMemory) && ((fwdBlock2 <= foo->fwdTableNext) && ((fwdBlock2 & 3) == 0)))) {
						error("invalid fwd table entry");
					}
				}
				header3 = longAt(fwdBlock2 + 4);
			}
			fmt = (((unsigned) header3) >> 8) & 15;
			if (fmt <= 4) {
				if ((fmt == 3) && ((((((unsigned) header3) >> 12) & 31) == 13) || ((((((unsigned) header3) >> 12) & 31) == 14) || (((((unsigned) header3) >> 12) & 31) == 4)))) {
					/* begin fetchStackPointerOf: */
					sp = longAt(((((char *) oop)) + BaseHeaderSize) + (StackPointerIndex << 2));
					if (!((sp & 1))) {
						contextSize = 0;
						goto l1;
					}
					contextSize = (sp >> 1);
				l1:	/* end fetchStackPointerOf: */;
					fieldOffset = (CtxtTempFrameStart + contextSize) * 4;
					goto l2;
				}
				if ((header3 & TypeMask) == HeaderTypeSizeAndClass) {
					size = (longAt(oop - 8)) & AllButTypeMask;
				} else {
					size = header3 & SizeMask;
				}
				fieldOffset = size - BaseHeaderSize;
				goto l2;
			}
			if (fmt < 12) {
				fieldOffset = 0;
				goto l2;
			}
			methodHeader = longAt(oop + BaseHeaderSize);
			fieldOffset = (((((unsigned) methodHeader) >> 10) & 255) * 4) + BaseHeaderSize;
		l2:	/* end lastPointerWhileForwarding: */;
			while (fieldOffset >= BaseHeaderSize) {
				fieldOop = longAt(oop + fieldOffset);
				if (((fieldOop & 1) == 0) && (((longAt(fieldOop)) & MarkBit) != 0)) {
					fwdBlock = ((longAt(fieldOop)) & AllButMarkBitAndTypeMask) << 1;
					if (DoAssertionChecks) {
						/* begin fwdBlockValidate: */
						if (!((fwdBlock > foo->endOfMemory) && ((fwdBlock <= foo->fwdTableNext) && ((fwdBlock & 3) == 0)))) {
							error("invalid fwd table entry");
						}
					}
					newOop = longAt(fwdBlock);
					longAtput(oop + fieldOffset, newOop);
					if ((oop < foo->youngStart) && (newOop >= foo->youngStart)) {
						/* begin beRootWhileForwarding: */
						header = longAt(oop);
						if ((header & MarkBit) != 0) {
							fwdBlock1 = (header & AllButMarkBitAndTypeMask) << 1;
							if (DoAssertionChecks) {
								/* begin fwdBlockValidate: */
								if (!((fwdBlock1 > foo->endOfMemory) && ((fwdBlock1 <= foo->fwdTableNext) && ((fwdBlock1 & 3) == 0)))) {
									error("invalid fwd table entry");
								}
							}
							/* begin noteAsRoot:headerLoc: */
							header1 = longAt(fwdBlock1 + 4);
							if ((header1 & RootBit) == 0) {
								if (foo->rootTableCount < RootTableRedZone) {
									foo->rootTableCount += 1;
									rootTable[foo->rootTableCount] = oop;
									longAtput(fwdBlock1 + 4, header1 | RootBit);
								} else {
									if (foo->rootTableCount < RootTableSize) {
										foo->rootTableCount += 1;
										rootTable[foo->rootTableCount] = oop;
										longAtput(fwdBlock1 + 4, header1 | RootBit);
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
									rootTable[foo->rootTableCount] = oop;
									longAtput(oop, header2 | RootBit);
								} else {
									if (foo->rootTableCount < RootTableSize) {
										foo->rootTableCount += 1;
										rootTable[foo->rootTableCount] = oop;
										longAtput(oop, header2 | RootBit);
										foo->allocationCount = foo->allocationsBetweenGCs + 1;
									}
								}
							}
						}
					}
				}
				fieldOffset -= 4;
			}
			/* begin remapClassOf: */
			if (((longAt(oop)) & TypeMask) == HeaderTypeShort) {
				goto l3;
			}
			classHeader = longAt(oop - 4);
			classOop = classHeader & AllButTypeMask;
			if (((classOop & 1) == 0) && (((longAt(classOop)) & MarkBit) != 0)) {
				fwdBlock3 = ((longAt(classOop)) & AllButMarkBitAndTypeMask) << 1;
				if (DoAssertionChecks) {
					/* begin fwdBlockValidate: */
					if (!((fwdBlock3 > foo->endOfMemory) && ((fwdBlock3 <= foo->fwdTableNext) && ((fwdBlock3 & 3) == 0)))) {
						error("invalid fwd table entry");
					}
				}
				newClassOop = longAt(fwdBlock3);
				newClassHeader = newClassOop | (classHeader & TypeMask);
				longAtput(oop - 4, newClassHeader);
				if ((oop < foo->youngStart) && (newClassOop >= foo->youngStart)) {
					/* begin beRootWhileForwarding: */
					header4 = longAt(oop);
					if ((header4 & MarkBit) != 0) {
						fwdBlock11 = (header4 & AllButMarkBitAndTypeMask) << 1;
						if (DoAssertionChecks) {
							/* begin fwdBlockValidate: */
							if (!((fwdBlock11 > foo->endOfMemory) && ((fwdBlock11 <= foo->fwdTableNext) && ((fwdBlock11 & 3) == 0)))) {
								error("invalid fwd table entry");
							}
						}
						/* begin noteAsRoot:headerLoc: */
						header11 = longAt(fwdBlock11 + 4);
						if ((header11 & RootBit) == 0) {
							if (foo->rootTableCount < RootTableRedZone) {
								foo->rootTableCount += 1;
								rootTable[foo->rootTableCount] = oop;
								longAtput(fwdBlock11 + 4, header11 | RootBit);
							} else {
								if (foo->rootTableCount < RootTableSize) {
									foo->rootTableCount += 1;
									rootTable[foo->rootTableCount] = oop;
									longAtput(fwdBlock11 + 4, header11 | RootBit);
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
								rootTable[foo->rootTableCount] = oop;
								longAtput(oop, header21 | RootBit);
							} else {
								if (foo->rootTableCount < RootTableSize) {
									foo->rootTableCount += 1;
									rootTable[foo->rootTableCount] = oop;
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

int verifyCleanHeaders(void) {
register struct foo * foo = &fum;
    int oop;
    int chunk;
    int sz;
    int header;

	/* begin oopFromChunk: */
	chunk = startOfMemory();
	oop = chunk + (headerTypeBytes[(longAt(chunk)) & TypeMask]);
	while (oop < foo->endOfMemory) {
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
			if (oop >= foo->endOfMemory) {
				error("no objects after the end of memory");
			}
		}
		if (((longAt(oop)) & TypeMask) == HeaderTypeFree) {
			sz = (longAt(oop)) & AllButTypeMask;
		} else {
			/* begin sizeBitsOf: */
			header = longAt(oop);
			if ((header & TypeMask) == HeaderTypeSizeAndClass) {
				sz = (longAt(oop - 8)) & AllButTypeMask;
				goto l1;
			} else {
				sz = header & SizeMask;
				goto l1;
			}
		l1:	/* end sizeBitsOf: */;
		}
		oop = (oop + sz) + (headerTypeBytes[(longAt(oop + sz)) & TypeMask]);
	}
}


/*	Return the highest priority process that is ready to run. */
/*	Note: It is a fatal VM error if there is no runnable process. */

int wakeHighestPriority(void) {
register struct foo * foo = &fum;
    int schedLists;
    int p;
    int processList;
    int sz;
    int header;

	schedLists = longAt(((((char *) (longAt(((((char *) (longAt(((((char *) foo->specialObjectsOop)) + BaseHeaderSize) + (SchedulerAssociation << 2))))) + BaseHeaderSize) + (ValueIndex << 2))))) + BaseHeaderSize) + (ProcessListsIndex << 2));
	/* begin fetchWordLengthOf: */
	/* begin sizeBitsOf: */
	header = longAt(schedLists);
	if ((header & TypeMask) == HeaderTypeSizeAndClass) {
		sz = (longAt(schedLists - 8)) & AllButTypeMask;
		goto l1;
	} else {
		sz = header & SizeMask;
		goto l1;
	}
l1:	/* end sizeBitsOf: */;
	p = ((unsigned) (sz - BaseHeaderSize)) >> 2;

	/* index of last indexable field */

	p -= 1;
	processList = longAt(((((char *) schedLists)) + BaseHeaderSize) + (p << 2));
	while ((longAt(((((char *) processList)) + BaseHeaderSize) + (FirstLinkIndex << 2))) == foo->nilObj) {
		p -= 1;
		if (p < 0) {
			error("scheduler could not find a runnable process");
		}
		processList = longAt(((((char *) schedLists)) + BaseHeaderSize) + (p << 2));
	}
	return removeFirstLinkOfList(processList);
}

int writeImageFile(int imageBytes) {
register struct foo * foo = &fum;
    sqImageFile f;
    int okToWrite;
    int headerSize;
    int i;
    squeakFileOffsetType headerStart;
    int bytesWritten;
    int sCWIfn;

	sCWIfn = ioLoadFunctionFrom("secCanWriteImage", "SecurityPlugin");
	if (sCWIfn != 0) {
		okToWrite =  ((int (*) (void)) sCWIfn)();
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
	putLongtoFile(6502, f);
	putLongtoFile(headerSize, f);
	putLongtoFile(imageBytes, f);
	putLongtoFile(startOfMemory(), f);
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
	bytesWritten = sqImageFileWrite(memory, sizeof(unsigned char), imageBytes, f);
	/* begin success: */
	foo->successFlag = (bytesWritten == imageBytes) && foo->successFlag;
	sqImageFileClose(f);
}


void* vm_exports[][3] = {
	{"", "primitiveDisablePowerManager", (void*)primitiveDisablePowerManager},
	{"", "moduleUnloaded", (void*)moduleUnloaded},
	{"", "primitiveScreenDepth", (void*)primitiveScreenDepth},
	{NULL, NULL, NULL}
};
