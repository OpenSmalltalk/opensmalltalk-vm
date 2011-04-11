"
This class is a complete implementation of the Smalltalk-80 virtual machine, derived originally from the Blue Book specification but quite different in some areas.

It has been modernized with 32-bit pointers, better management of Contexts, and attention to variable use that allows the CCodeGenerator (qv) to keep, eg, the instruction pointer and stack pointer in registers as well as keeping most simple variables in a global array that seems to improve performance for most platforms.

In addition to SmallInteger arithmetic and Floats, it supports logic on 32-bit PositiveLargeIntegers, thus allowing it to simulate itself much more effectively than would otherwise be the case.

NOTE:  Here follows a list of things to be borne in mind when working on this code, or when making changes for the future.

1.  There are a number of things that should be done the next time we plan to release a copletely incompatible image format.  These include unifying the instanceSize field of the class format word -- see instantiateClass:indexableSize:, and unifying the bits of the method primitive index (if we decide we need more than 512, after all) -- see primitiveIndexOf:.  Also, contexts should be given a special format code (see next item).

2.  There are several fast checks for contexts (see isContextHeader: and isMethodContextHeader:) which will fail if the compact class indices of BlockContext or MethodContext change.  This is necessary because the oops may change during a compaction when the oops are being adjusted.  It's important to be aware of this when writing a new image using the systemTracer.  A better solution would be to reserve one of the format codes for Contexts only.

3.  We have made normal files tolerant to size and positions up to 32 bits.  This has not been done for async files, since they are still experimental.  The code in size, at: and at:put: should work with sizes and indices up to 31 bits, although I have not tested it (di 12/98); it might or might not work with 32-bit sizes.

4.  Note that 0 is used in a couple of places as an impossible oop.  This should be changed to a constant that really is impossible (or perhaps there is code somewhere that guarantees it --if so it should be put in this comment).  The places include the method cache and the at cache. 
"
Class {
	#name : #Interpreter,
	#superclass : #ObjectMemory,
	#instVars : [
		'activeContext',
		'theHomeContext',
		'method',
		'receiver',
		'instructionPointer',
		'stackPointer',
		'localIP',
		'localSP',
		'localHomeContext',
		'localReturnContext',
		'localReturnValue',
		'messageSelector',
		'argumentCount',
		'newMethod',
		'currentBytecode',
		'successFlag',
		'primitiveIndex',
		'primitiveFunctionPointer',
		'methodCache',
		'atCache',
		'lkupClass',
		'reclaimableContextCount',
		'nextPollTick',
		'nextWakeupTick',
		'lastTick',
		'interruptKeycode',
		'interruptPending',
		'semaphoresToSignalA',
		'semaphoresUseBufferA',
		'semaphoresToSignalCountA',
		'semaphoresToSignalB',
		'semaphoresToSignalCountB',
		'processSignalingLowSpace',
		'savedWindowSize',
		'fullScreenFlag',
		'deferDisplayUpdates',
		'pendingFinalizationSignals',
		'compilerInitialized',
		'compilerHooks',
		'extraVMMemory',
		'newNativeMethod',
		'methodClass',
		'receiverClass',
		'interpreterVersion',
		'imageFormatVersionNumber',
		'interpreterProxy',
		'showSurfaceFn',
		'interruptCheckCounterFeedBackReset',
		'interruptChecksEveryNms',
		'externalPrimitiveTable',
		'primitiveTable',
		'globalSessionID',
		'jmpBuf',
		'jmpDepth',
		'jmpMax',
		'suspendedCallbacks',
		'suspendedMethods',
		'primFailCode',
		'imageFormatInitialVersion'
	],
	#classVars : [
		'ActiveProcessIndex',
		'AtCacheEntries',
		'AtCacheFixedFields',
		'AtCacheFmt',
		'AtCacheMask',
		'AtCacheOop',
		'AtCacheSize',
		'AtCacheTotalSize',
		'AtPutBase',
		'BlockArgumentCountIndex',
		'BlockMethodIndex',
		'BytecodeTable',
		'CacheProbeMax',
		'CallerIndex',
		'CharacterValueIndex',
		'ClosureCopiedValuesIndex',
		'ClosureFirstCopiedValueIndex',
		'ClosureIndex',
		'ClosureMethodIndex',
		'ClosureNumArgsIndex',
		'ClosureOuterContextIndex',
		'ClosureStartPCIndex',
		'CompilerHooksSize',
		'CrossedX',
		'DirBadPath',
		'DirEntryFound',
		'DirNoMoreEntries',
		'EndOfRun',
		'ExcessSignalsIndex',
		'FirstLinkIndex',
		'HeaderIndex',
		'HomeIndex',
		'InitialIPIndex',
		'InstanceSpecificationIndex',
		'InstructionPointerIndex',
		'InterpreterSourceVersion',
		'JitterTable',
		'LastLinkIndex',
		'LiteralStart',
		'MaxExternalPrimitiveTableSize',
		'MaxJumpBuf',
		'MaxPrimitiveIndex',
		'MessageArgumentsIndex',
		'MessageDictionaryIndex',
		'MessageLookupClassIndex',
		'MessageSelectorIndex',
		'MethodArrayIndex',
		'MethodCacheClass',
		'MethodCacheEntries',
		'MethodCacheEntrySize',
		'MethodCacheMask',
		'MethodCacheMethod',
		'MethodCacheNative',
		'MethodCachePrim',
		'MethodCachePrimFunction',
		'MethodCacheSelector',
		'MethodCacheSize',
		'MethodIndex',
		'MillisecondClockMask',
		'MyListIndex',
		'NextLinkIndex',
		'PrimErrBadArgument',
		'PrimErrBadIndex',
		'PrimErrBadNumArgs',
		'PrimErrBadReceiver',
		'PrimErrGenericFailure',
		'PrimErrInappropriate',
		'PrimErrNoCMemory',
		'PrimErrNoMemory',
		'PrimErrNoModification',
		'PrimErrNotFound',
		'PrimErrTableIndex',
		'PrimErrUnsupported',
		'PrimNoErr',
		'PrimitiveExternalCallIndex',
		'PrimitiveTable',
		'PriorityIndex',
		'ProcessListsIndex',
		'ReceiverIndex',
		'SelectorStart',
		'SemaphoresToSignalSize',
		'SenderIndex',
		'StackPointerIndex',
		'StreamArrayIndex',
		'StreamIndexIndex',
		'StreamReadLimitIndex',
		'StreamWriteLimitIndex',
		'SuperclassIndex',
		'SuspendedContextIndex',
		'TempFrameStart',
		'ValueIndex',
		'XIndex',
		'YIndex'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #constants }
Interpreter class >> bytecodeTable [

	^ BytecodeTable
]

{ #category : #translation }
Interpreter class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator addHeaderFile:'<setjmp.h>'.
	aCCodeGenerator 
		var: #interpreterProxy 
		type: #'struct VirtualMachine*'.
	aCCodeGenerator
		var: #primitiveTable
		declareC: 'void *primitiveTable[', (MaxPrimitiveIndex +2) printString, '] = ',	self primitiveTableString.
	aCCodeGenerator
		var: #primitiveFunctionPointer
		declareC: 'void *primitiveFunctionPointer'				.		"xxxx FIX THIS STUPIDITY xxxx - ikp. What he means is use a better type than void *, apparently - tpr"
	aCCodeGenerator
		var: #methodCache
		declareC: 'long methodCache[', (MethodCacheSize + 1) printString, ']'.
	aCCodeGenerator
		var: #atCache
		declareC: 'sqInt atCache[', (AtCacheTotalSize + 1) printString, ']'.
	aCCodeGenerator var: #statGCTime type: #'sqLong'.
	aCCodeGenerator var: #statFullGCMSecs type: #'sqLong'.
	aCCodeGenerator var: #statIGCDeltaTime type: #'sqLong'.
	aCCodeGenerator var: #statIncrGCMSecs type: #'sqLong'.
	aCCodeGenerator var: #localIP type: #'char*'.
	aCCodeGenerator var: #localSP type: #'char*'.
	aCCodeGenerator var: #showSurfaceFn type: #'void*'.
	aCCodeGenerator var: 'semaphoresToSignalA'
		declareC: 'sqInt semaphoresToSignalA[', (SemaphoresToSignalSize + 1) printString, ']'.
	aCCodeGenerator var: 'semaphoresToSignalB'
		declareC: 'sqInt semaphoresToSignalB[', (SemaphoresToSignalSize + 1) printString, ']'.
	aCCodeGenerator
		var: #compilerHooks
		declareC: 'sqInt (*compilerHooks[', (CompilerHooksSize + 1) printString, '])()'.
	aCCodeGenerator
		var: #interpreterVersion
		declareC: 'const char *interpreterVersion = "', SmalltalkImage current datedVersion, ' [', SmalltalkImage current lastUpdateString,']"'.
	aCCodeGenerator
		var: #obsoleteIndexedPrimitiveTable
		declareC: 'char* obsoleteIndexedPrimitiveTable[][3] = ', self obsoleteIndexedPrimitiveTableString.
	aCCodeGenerator
		var: #obsoleteNamedPrimitiveTable
		declareC: 'const char* obsoleteNamedPrimitiveTable[][3] = ', self obsoleteNamedPrimitiveTableString.
	aCCodeGenerator
		var: #externalPrimitiveTable
		declareC: 'void *externalPrimitiveTable[', (MaxExternalPrimitiveTableSize + 1) printString, ']'.

	self declareCAsOop: {
			#instructionPointer .
			#method .
			#newMethod .
			#activeContext .
			#theHomeContext .
			#stackPointer }
		in: aCCodeGenerator.
		
	aCCodeGenerator
		var: #jmpBuf
		declareC: 'jmp_buf jmpBuf[', (MaxJumpBuf + 1) printString, ']'.
	aCCodeGenerator
		var: #suspendedCallbacks
		declareC: 'sqInt suspendedCallbacks[', (MaxJumpBuf + 1) printString, ']'.
	aCCodeGenerator
		var: #suspendedMethods
		declareC: 'sqInt suspendedMethods[', (MaxJumpBuf + 1) printString, ']'.

	"Reinitialized at interpreter entry by #initializeImageFormatVersion"
	aCCodeGenerator
		var: #imageFormatVersionNumber
		declareC: 'sqInt imageFormatVersionNumber = 0'.
	"Declared here to prevent inclusion in foo struct by CCodeGeneratorGlobalStructure"
	aCCodeGenerator
		var: #imageFormatInitialVersion
		declareC: 'sqInt imageFormatInitialVersion = 0'

]

{ #category : #initialization }
Interpreter class >> initialize [
	"Interpreter initialize"

	super initialize.  "initialize ObjectMemory constants"
	self initializeAssociationIndex.
	self initializeBytecodeTable.
	self initializeCaches.
	self initializeCharacterIndex.
	self initializeCharacterScannerIndices.
	self initializeClassIndices.
	self initializeCompilerHooks.
	self initializeContextIndices.
	self initializeDirectoryLookupResultCodes.
	self initializeMessageIndices.
	self initializeMethodIndices.
	self initializePointIndices.
	self initializePrimitiveTable.
	self initializeSchedulerIndices.
	self initializeSmallIntegers.
	self initializeStreamIndices.
	self initializeInterpreterSourceVersion.

	SemaphoresToSignalSize := 500.
	PrimitiveExternalCallIndex := 117. "Primitive index for #primitiveExternalCall"
	MillisecondClockMask := 16r1FFFFFFF.
	"Note: The external primitive table should actually be dynamically sized but for the sake of inferior platforms (e.g., Mac :-) who cannot allocate memory in any reasonable way, we keep it static (and cross our fingers...)"
	MaxExternalPrimitiveTableSize := 4096. "entries"

	MaxJumpBuf := 32. "max. callback depth"
]

{ #category : #initialization }
Interpreter class >> initializeAssociationIndex [
	ValueIndex := 1
]

{ #category : #initialization }
Interpreter class >> initializeBytecodeTable [
	"Interpreter initializeBytecodeTable"
	"Note: This table will be used to generate a C switch statement."

	BytecodeTable := Array new: 256.
	self table: BytecodeTable from:
	#(
		(  0  15 pushReceiverVariableBytecode)
		( 16  31 pushTemporaryVariableBytecode)
		( 32  63 pushLiteralConstantBytecode)
		( 64  95 pushLiteralVariableBytecode)
		( 96 103 storeAndPopReceiverVariableBytecode)
		(104 111 storeAndPopTemporaryVariableBytecode)
		(112 pushReceiverBytecode)
		(113 pushConstantTrueBytecode)
		(114 pushConstantFalseBytecode)
		(115 pushConstantNilBytecode)
		(116 pushConstantMinusOneBytecode)
		(117 pushConstantZeroBytecode)
		(118 pushConstantOneBytecode)
		(119 pushConstantTwoBytecode)
		(120 returnReceiver)
		(121 returnTrue)
		(122 returnFalse)
		(123 returnNil)
		(124 returnTopFromMethod)
		(125 returnTopFromBlock)

		(126 127 unknownBytecode)

		(128 extendedPushBytecode)
		(129 extendedStoreBytecode)
		(130 extendedStoreAndPopBytecode)
		(131 singleExtendedSendBytecode)
		(132 doubleExtendedDoAnythingBytecode)
		(133 singleExtendedSuperBytecode)
		(134 secondExtendedSendBytecode)
		(135 popStackBytecode)
		(136 duplicateTopBytecode)

		(137 pushActiveContextBytecode)
		(138 pushNewArrayBytecode)
		(139 unknownBytecode)
		(140 pushRemoteTempLongBytecode)
		(141 storeRemoteTempLongBytecode)
		(142 storeAndPopRemoteTempLongBytecode)
		(143 pushClosureCopyCopiedValuesBytecode)

		(144 151 shortUnconditionalJump)
		(152 159 shortConditionalJump)
		(160 167 longUnconditionalJump)
		(168 171 longJumpIfTrue)
		(172 175 longJumpIfFalse)

		"176-191 were sendArithmeticSelectorBytecode"
		(176 bytecodePrimAdd)
		(177 bytecodePrimSubtract)
		(178 bytecodePrimLessThan)
		(179 bytecodePrimGreaterThan)
		(180 bytecodePrimLessOrEqual)
		(181 bytecodePrimGreaterOrEqual)
		(182 bytecodePrimEqual)
		(183 bytecodePrimNotEqual)
		(184 bytecodePrimMultiply)
		(185 bytecodePrimDivide)
		(186 bytecodePrimMod)
		(187 bytecodePrimMakePoint)
		(188 bytecodePrimBitShift)
		(189 bytecodePrimDiv)
		(190 bytecodePrimBitAnd)
		(191 bytecodePrimBitOr)	

		"192-207 were sendCommonSelectorBytecode"
		(192 bytecodePrimAt)
		(193 bytecodePrimAtPut)
		(194 bytecodePrimSize)
		(195 bytecodePrimNext)
		(196 bytecodePrimNextPut)
		(197 bytecodePrimAtEnd)
		(198 bytecodePrimEquivalent)
		(199 bytecodePrimClass)
		(200 bytecodePrimBlockCopy)
		(201 bytecodePrimValue)
		(202 bytecodePrimValueWithArg)
		(203 bytecodePrimDo)
		(204 bytecodePrimNew)
		(205 bytecodePrimNewWithArg)
		(206 bytecodePrimPointX)
		(207 bytecodePrimPointY)

		(208 255 sendLiteralSelectorBytecode)
	).
]

{ #category : #initialization }
Interpreter class >> initializeCaches [

	| atCacheEntrySize |
	MethodCacheEntries := 512. 
	MethodCacheSelector := 1.
	MethodCacheClass := 2.
	MethodCacheMethod := 3.
	MethodCachePrim := 4.
	MethodCacheNative := 5.
	MethodCachePrimFunction := 6.
	MethodCacheEntrySize := 8.  "Must be power of two for masking scheme."
	MethodCacheMask := (MethodCacheEntries - 1) * MethodCacheEntrySize.
	MethodCacheSize := MethodCacheEntries * MethodCacheEntrySize.
	CacheProbeMax := 3.

	AtCacheEntries := 8.  "Must be a power of two"
	AtCacheOop := 1.
	AtCacheSize := 2.
	AtCacheFmt := 3.
	AtCacheFixedFields := 4.
	atCacheEntrySize := 4.  "Must be power of two for masking scheme."
	AtCacheMask := (AtCacheEntries-1) * atCacheEntrySize.
	AtPutBase := AtCacheEntries * atCacheEntrySize.
	AtCacheTotalSize := AtCacheEntries * atCacheEntrySize * 2.

]

{ #category : #initialization }
Interpreter class >> initializeCharacterIndex [
	CharacterValueIndex := 0
]

{ #category : #initialization }
Interpreter class >> initializeCharacterScannerIndices [
	CrossedX := 258.
	EndOfRun := 257

]

{ #category : #initialization }
Interpreter class >> initializeClassIndices [
	"Class Class"
	SuperclassIndex := 0.
	MessageDictionaryIndex := 1.
	InstanceSpecificationIndex := 2.
	"Fields of a message dictionary"
	MethodArrayIndex := 1.
	SelectorStart := 2
]

{ #category : #initialization }
Interpreter class >> initializeCompilerHooks [
	"Interpreter initializeCompilerHooks"

	"compilerHooks[] indices:
	1	void compilerTranslateMethodHook(void)
	2	void compilerFlushCacheHook(CompiledMethod *oldMethod)
	3	void compilerPreGCHook(int fullGCFlag)
	4	void compilerMapHook(int memStart, int memEnd)
	5	void compilerPostGCHook(void)
	6	void compilerProcessChangeHook(void)
	7	void compilerPreSnapshotHook(void)
	8	void compilerPostSnapshotHook(void)
	9	void compilerMarkHook(void)
	10	void compilerActivateMethodHook(void)
	11	void compilerNewActiveContextHook(int sendFlag)
	12	void compilerGetInstructionPointerHook(void)
	13	void compilerSetInstructionPointerHook(void)
	14	void compilerCreateActualMessageHook(void)"

	CompilerHooksSize := 15.
]

{ #category : #initialization }
Interpreter class >> initializeContextIndices [
	"Class MethodContext"
	SenderIndex := 0.
	InstructionPointerIndex := 1.
	StackPointerIndex := 2.
	MethodIndex := 3.
	ClosureIndex := 4. "N.B. Called receiverMap in the image."
	ReceiverIndex := 5.
	TempFrameStart := 6.  "Note this is in two places!"

	"Class BlockContext"
	CallerIndex := 0.
	BlockArgumentCountIndex := 3.
	InitialIPIndex := 4.
	HomeIndex := 5.

	"Class BlockClosure"
	ClosureOuterContextIndex := 0.
	ClosureStartPCIndex := 1.
	ClosureNumArgsIndex := 2.
	ClosureFirstCopiedValueIndex := 3
]

{ #category : #initialization }
Interpreter class >> initializeDirectoryLookupResultCodes [

	DirEntryFound := 0.
	DirNoMoreEntries := 1.
	DirBadPath := 2.
]

{ #category : #initialization }
Interpreter class >> initializeInterpreterSourceVersion [
	"Identify the VMMaker source version that generated the C code for an
	interpreter. Provides a runtime version identification test."

	Smalltalk at: #VMMaker
		ifPresent: [:vmm | ^ InterpreterSourceVersion := vmm versionString].
	^ InterpreterSourceVersion := ''
]

{ #category : #initialization }
Interpreter class >> initializeMessageIndices [
	MessageSelectorIndex := 0.
	MessageArgumentsIndex := 1.
	MessageLookupClassIndex := 2.
]

{ #category : #initialization }
Interpreter class >> initializeMethodIndices [
	"Class CompiledMethod"
	HeaderIndex := 0.
	LiteralStart := 1
]

{ #category : #initialization }
Interpreter class >> initializePointIndices [
	XIndex := 0.
	YIndex := 1
]

{ #category : #initialization }
Interpreter class >> initializePrimitiveTable [ 
	"This table generates a C function address table use in primitiveResponse along with dispatchFunctionPointerOn:in:"

	"NOTE: The real limit here is 2047 because of the method header layout but there is no point in going over the needed size"
	MaxPrimitiveIndex := 575.
	PrimitiveTable := Array new: MaxPrimitiveIndex + 1.
	self table: PrimitiveTable from: 
	#(	"Integer Primitives (0-19)"
		(0 primitiveFail)
		(1 primitiveAdd)
		(2 primitiveSubtract)
		(3 primitiveLessThan)
		(4 primitiveGreaterThan)
		(5 primitiveLessOrEqual)
		(6 primitiveGreaterOrEqual)
		(7 primitiveEqual)
		(8 primitiveNotEqual)
		(9 primitiveMultiply)
		(10 primitiveDivide)
		(11 primitiveMod)
		(12 primitiveDiv)
		(13 primitiveQuo)
		(14 primitiveBitAnd)
		(15 primitiveBitOr)
		(16 primitiveBitXor)
		(17 primitiveBitShift)
		(18 primitiveMakePoint)
		(19 primitiveFail)					"Guard primitive for simulation -- *must* fail"

		"LargeInteger Primitives (20-39)"
		(20 primitiveFail)
		(21 primitiveAddLargeIntegers)
		(22 primitiveSubtractLargeIntegers)
		(23 primitiveLessThanLargeIntegers)
		(24 primitiveGreaterThanLargeIntegers)
		(25 primitiveLessOrEqualLargeIntegers)
		(26 primitiveGreaterOrEqualLargeIntegers)
		(27 primitiveEqualLargeIntegers)
		(28 primitiveNotEqualLargeIntegers)
		(29 primitiveMultiplyLargeIntegers)
		(30 primitiveDivideLargeIntegers)
		(31 primitiveModLargeIntegers)
		(32 primitiveDivLargeIntegers)
		(33 primitiveQuoLargeIntegers)
		(34 primitiveBitAndLargeIntegers)
		(35 primitiveBitOrLargeIntegers)
		(36 primitiveBitXorLargeIntegers)
		(37 primitiveBitShiftLargeIntegers)
		(38 primitiveFail)
		(39 primitiveFail)

		"Float Primitives (40-59)"
		(40 primitiveAsFloat)
		(41 primitiveFloatAdd)
		(42 primitiveFloatSubtract)
		(43 primitiveFloatLessThan)
		(44 primitiveFloatGreaterThan)
		(45 primitiveFloatLessOrEqual)
		(46 primitiveFloatGreaterOrEqual)
		(47 primitiveFloatEqual)
		(48 primitiveFloatNotEqual)
		(49 primitiveFloatMultiply)
		(50 primitiveFloatDivide)
		(51 primitiveTruncated)
		(52 primitiveFractionalPart)
		(53 primitiveExponent)
		(54 primitiveTimesTwoPower)
		(55 primitiveSquareRoot)
		(56 primitiveSine)
		(57 primitiveArctan)
		(58 primitiveLogN)
		(59 primitiveExp)

		"Subscript and Stream Primitives (60-67)"
		(60 primitiveAt)
		(61 primitiveAtPut)
		(62 primitiveSize)
		(63 primitiveStringAt)
		(64 primitiveStringAtPut)
		(65 primitiveFail) "was primitiveNext which no longer pays its way (normal Smalltalk code is faster)"
		(66 primitiveFail) "was primitiveNextPut which no longer pays its way (normal Smalltalk code is faster)"
		(67 primitiveFail) "was primitiveAtEnd which no longer pays its way (normal Smalltalk code is faster)"

		"StorageManagement Primitives (68-79)"
		(68 primitiveObjectAt)
		(69 primitiveObjectAtPut)
		(70 primitiveNew)
		(71 primitiveNewWithArg)
		(72 primitiveArrayBecomeOneWay)	"Blue Book: primitiveBecome"
		(73 primitiveInstVarAt)
		(74 primitiveInstVarAtPut)
		(75 primitiveAsOop)
		(76 primitiveStoreStackp)					"Blue Book: primitiveAsObject"
		(77 primitiveSomeInstance)
		(78 primitiveNextInstance)
		(79 primitiveNewMethod)

		"Control Primitives (80-89)"
		(80 primitiveBlockCopy)
		(81 primitiveValue)
		(82 primitiveValueWithArgs)
		(83 primitivePerform)
		(84 primitivePerformWithArgs)
		(85 primitiveSignal)
		(86 primitiveWait)
		(87 primitiveResume)
		(88 primitiveSuspend)
		(89 primitiveFlushCache)

		"Input/Output Primitives (90-109)"
		(90 primitiveMousePoint)
		(91 primitiveTestDisplayDepth)			"Blue Book: primitiveCursorLocPut"
		(92 primitiveSetDisplayMode)				"Blue Book: primitiveCursorLink"
		(93 primitiveInputSemaphore)
		(94 primitiveGetNextEvent)				"Blue Book: primitiveSampleInterval"
		(95 primitiveInputWord)
		(96 primitiveFail)	"primitiveCopyBits"
		(97 primitiveSnapshot)
		(98 primitiveStoreImageSegment)
		(99 primitiveLoadImageSegment)
		(100 primitivePerformInSuperclass)		"Blue Book: primitiveSignalAtTick"
		(101 primitiveBeCursor)
		(102 primitiveBeDisplay)
		(103 primitiveScanCharacters)
		(104 primitiveFail)	"primitiveDrawLoop"
		(105 primitiveStringReplace)
		(106 primitiveScreenSize)
		(107 primitiveMouseButtons)
		(108 primitiveKbdNext)
		(109 primitiveKbdPeek)

		"System Primitives (110-119)"
		(110 primitiveEquivalent)
		(111 primitiveClass)
		(112 primitiveBytesLeft)
		(113 primitiveQuit)
		(114 primitiveExitToDebugger)
		(115 primitiveChangeClass)					"Blue Book: primitiveOopsLeft"
		(116 primitiveFlushCacheByMethod)
		(117 primitiveExternalCall)
		(118 primitiveDoPrimitiveWithArgs)
		(119 primitiveFlushCacheSelective)
			"Squeak 2.2 and earlier use 119.  Squeak 2.3 and later use 116.
			Both are supported for backward compatibility."

		"Miscellaneous Primitives (120-127)"
		(120 primitiveCalloutToFFI)
		(121 primitiveImageName)
		(122 primitiveNoop)					"Blue Book: primitiveImageVolume"
		(123 primitiveValueUninterruptably)	"@@@: Remove this when all VMs have support"
		(124 primitiveLowSpaceSemaphore)
		(125 primitiveSignalAtBytesLeft)

		"Squeak Primitives Start Here"

		"Squeak Miscellaneous Primitives (128-149)"
		(126 primitiveDeferDisplayUpdates)
		(127 primitiveShowDisplayRect)
		(128 primitiveArrayBecome)
		(129 primitiveSpecialObjectsOop)
		(130 primitiveFullGC)
		(131 primitiveIncrementalGC)
		(132 primitiveObjectPointsTo)
		(133 primitiveSetInterruptKey)
		(134 primitiveInterruptSemaphore)
		(135 primitiveMillisecondClock)
		(136 primitiveSignalAtMilliseconds)
		(137 primitiveSecondsClock)
		(138 primitiveSomeObject)
		(139 primitiveNextObject)
		(140 primitiveBeep)
		(141 primitiveClipboardText)
		(142 primitiveVMPath)
		(143 primitiveShortAt)
		(144 primitiveShortAtPut)
		(145 primitiveConstantFill)
		"NOTE: When removing the obsolete indexed primitives,
		the following two should go become #primitiveIntegerAt / atPut"
		(146 primitiveFail)	"primitiveReadJoystick"
		(147 primitiveFail)	"primitiveWarpBits"
		(148 primitiveClone)
		(149 primitiveGetAttribute)

		"File Primitives (150-169) - NO LONGER INDEXED"
		(150 159 primitiveFail)
		(160 primitiveAdoptInstance)
		(161 164 primitiveFail)
		(165 primitiveIntegerAt)		"hacked in here for now"
		(166 primitiveIntegerAtPut)
		(167 primitiveYield)
		(168 primitiveCopyObject)
		(169 primitiveFail)

		"Sound Primitives (170-199) - NO LONGER INDEXED"
		(170 185 primitiveFail)

		"Old closure primitives"
		(186 primitiveFail) "was primitiveClosureValue"
		(187 primitiveFail) "was primitiveClosureValueWithArgs"

		"Perform method directly"
		(188 primitiveExecuteMethodArgsArray)
		(189 primitiveExecuteMethod)

		"Sound Primitives (continued) - NO LONGER INDEXED"
		(190 194 primitiveFail)

		"Unwind primitives"
		(195 primitiveFindNextUnwindContext)
		(196 primitiveTerminateTo)
		(197 primitiveFindHandlerContext)
		(198 primitiveMarkUnwindMethod)
		(199 primitiveMarkHandlerMethod)

		"new closure primitives (were Networking primitives)"
		(200 primitiveClosureCopyWithCopiedValues)
		(201 primitiveClosureValue) "value"
		(202 primitiveClosureValue) "value:"
		(203 primitiveClosureValue) "value:value:"
		(204 primitiveClosureValue) "value:value:value:"
		(205 primitiveClosureValue) "value:value:value:value:"
		(206 primitiveClosureValueWithArgs) "valueWithArguments:"

		(207 209 primitiveFail) "reserved for Cog primitives"

		(210 primitiveAt)		"Compatibility with Cog StackInterpreter Context primitives"
		(211 primitiveAtPut)	"Compatibility with Cog StackInterpreter Context primitives"
		(212 primitiveSize)	"Compatibility with Cog StackInterpreter Context primitives"
		(213 219 primitiveFail) "reserved for Cog primitives"

		(220 primitiveFail)		"reserved for Cog primitives"

		(221 primitiveClosureValueNoContextSwitch) "valueNoContextSwitch"
		(222 primitiveClosureValueNoContextSwitch) "valueNoContextSwitch:"

		(223 229 primitiveFail)	"reserved for Cog primitives"

		(230 primitiveRelinquishProcessor)
		(231 primitiveForceDisplayUpdate)
		(232 primitiveFormPrint)
		(233 primitiveSetFullScreen)
		(234 primitiveFail) "primBitmapdecompressfromByteArrayat"
		(235 primitiveFail) "primStringcomparewithcollated"
		(236 primitiveFail) "primSampledSoundconvert8bitSignedFromto16Bit"
		(237 primitiveFail) "primBitmapcompresstoByteArray"
		(238 241 primitiveFail) "serial port primitives"
		(242 primitiveFail)
		(243 primitiveFail) "primStringtranslatefromtotable"
		(244 primitiveFail) "primStringfindFirstInStringinSetstartingAt"
		(245 primitiveFail) "primStringindexOfAsciiinStringstartingAt"
		(246 primitiveFail) "primStringfindSubstringinstartingAtmatchTable"
		(247 primitiveSnapshotEmbedded)
		(248 primitiveInvokeObjectAsMethod)
		(249 primitiveArrayBecomeOneWayCopyHash)

		"VM Implementor Primitives (250-255)"
		(250 clearProfile)
		(251 dumpProfile)
		(252 startProfiling)
		(253 stopProfiling)
		(254 primitiveVMParameter)
		(255 primitiveInstVarsPutFromStack) "Never used except in Disney tests.  Remove after 2.3 release."

		"Quick Push Const Methods"
		(256 primitivePushSelf)
		(257 primitivePushTrue)
		(258 primitivePushFalse)
		(259 primitivePushNil)
		(260 primitivePushMinusOne)
		(261 primitivePushZero)
		(262 primitivePushOne)
		(263 primitivePushTwo)

		"Quick Push Const Methods"
		(264 519 primitiveLoadInstVar)

		"These ranges used to be used by obsiolete indexed primitives."
		(520 529 primitiveFail)
		(530 539 primitiveFail)
		(540 549 primitiveFail)
		(550 559 primitiveFail)
		(560 569 primitiveFail)

		"External primitive support primitives"
		(570 primitiveFlushExternalPrimitives)
		(571 primitiveUnloadModule)
		(572 primitiveListBuiltinModule)
		(573 primitiveListExternalModule)
		(574 primitiveFail) "reserved for addl. external support prims"

		"Unassigned Primitives"
		(575 primitiveFail)).

]

{ #category : #initialization }
Interpreter class >> initializeSchedulerIndices [
	"Class ProcessorScheduler"
	ProcessListsIndex := 0.
	ActiveProcessIndex := 1.
	"Class LinkedList"
	FirstLinkIndex := 0.
	LastLinkIndex := 1.
	"Class Semaphore"
	ExcessSignalsIndex := 2.
	"Class Link"
	NextLinkIndex := 0.
	"Class Process"
	SuspendedContextIndex := 1.
	PriorityIndex := 2.
	MyListIndex := 3
]

{ #category : #initialization }
Interpreter class >> initializeSmallIntegers [
	"SmallIntegers"
	ConstMinusOne := Interpreter new integerObjectOf: -1.
	ConstZero := Interpreter new integerObjectOf: 0.
	ConstOne := Interpreter new integerObjectOf: 1.
	ConstTwo := Interpreter new integerObjectOf: 2
]

{ #category : #initialization }
Interpreter class >> initializeStreamIndices [
	StreamArrayIndex := 0.
	StreamIndexIndex := 1.
	StreamReadLimitIndex := 2.
	StreamWriteLimitIndex := 3.
]

{ #category : #translation }
Interpreter class >> isNonArgumentImplicitReceiverVariableName: aString [
	aString = 'interpreterProxy' ifTrue: [self halt].
	^'self' = aString
]

{ #category : #translation }
Interpreter class >> isTypePointerToStruct: type [ "<String>"
	^false
]

{ #category : #initialization }
Interpreter class >> obsoleteIndexedPrimitiveTable [
	"Interpreter obsoleteIndexedPrimitiveTableString"
	"Initialize the links from the (now obsolete) indexed primitives to
	the new named primitives."
	| table |
	table := Array new: MaxPrimitiveIndex+1.
	#(
		(96	(BitBltPlugin primitiveCopyBits))
		(104 (BitBltPlugin primitiveDrawLoop))
		(147 (BitBltPlugin primitiveWarpBits))

		(146 (JoystickTabletPlugin primitiveReadJoystick))

		"File Primitives (150-169)"
		(150 (FilePlugin primitiveFileAtEnd))
		(151 (FilePlugin primitiveFileClose))
		(152 (FilePlugin primitiveFileGetPosition))
		(153 (FilePlugin primitiveFileOpen))
		(154 (FilePlugin primitiveFileRead))
		(155 (FilePlugin primitiveFileSetPosition))
		(156 (FilePlugin primitiveFileDelete))
		(157 (FilePlugin primitiveFileSize))
		(158 (FilePlugin primitiveFileWrite))
		(159 (FilePlugin primitiveFileRename))
		(160 (FilePlugin primitiveDirectoryCreate))
		(161 (FilePlugin primitiveDirectoryDelimitor))
		(162 (FilePlugin primitiveDirectoryLookup))
		(163 (FilePlugin primitiveDirectoryDelete))
		(164 (FilePlugin primitiveDirectoryGetMacTypeAndCreator))
		(169 (FilePlugin primitiveDirectorySetMacTypeAndCreator))

		"Sound Primitives (170-199)"
		(170 (SoundPlugin primitiveSoundStart))
		(171 (SoundPlugin primitiveSoundStartWithSemaphore))
		(172 (SoundPlugin primitiveSoundStop))
		(173 (SoundPlugin primitiveSoundAvailableSpace))
		(174 (SoundPlugin primitiveSoundPlaySamples))
		(175 (SoundPlugin primitiveSoundPlaySilence))

		(176 (SoundGenerationPlugin primitiveWaveTableSoundMix))
		(177 (SoundGenerationPlugin primitiveFMSoundMix))
		(178 (SoundGenerationPlugin primitivePluckedSoundMix))
		(179 (SoundGenerationPlugin primitiveSampledSoundMix))
		(180 (SoundGenerationPlugin primitiveMixFMSound))
		(181 (SoundGenerationPlugin primitiveMixPluckedSound))
		(182 (SoundGenerationPlugin primitiveOldSampledSoundMix))
		(183 (SoundGenerationPlugin primitiveApplyReverb))
		(184 (SoundGenerationPlugin primitiveMixLoopedSampledSound))
		(185 (SoundGenerationPlugin primitiveMixSampledSound))

		(189 (SoundPlugin primitiveSoundInsertSamples))
		(190 (SoundPlugin primitiveSoundStartRecording))
		(191 (SoundPlugin primitiveSoundStopRecording))
		(192 (SoundPlugin primitiveSoundGetRecordingSampleRate))
		(193 (SoundPlugin primitiveSoundRecordSamples))
		(194 (SoundPlugin primitiveSoundSetRecordLevel))

		"Networking Primitives (200-229)"
		(200 (SocketPlugin primitiveInitializeNetwork))
		(201 (SocketPlugin primitiveResolverStartNameLookup))
		(202 (SocketPlugin primitiveResolverNameLookupResult))
		(203 (SocketPlugin primitiveResolverStartAddressLookup))
		(204 (SocketPlugin primitiveResolverAddressLookupResult))
		(205 (SocketPlugin primitiveResolverAbortLookup))
		(206 (SocketPlugin primitiveResolverLocalAddress))
		(207 (SocketPlugin primitiveResolverStatus))
		(208 (SocketPlugin primitiveResolverError))
		(209 (SocketPlugin primitiveSocketCreate))
		(210 (SocketPlugin primitiveSocketDestroy))
		(211 (SocketPlugin primitiveSocketConnectionStatus))
		(212 (SocketPlugin primitiveSocketError))
		(213 (SocketPlugin primitiveSocketLocalAddress))
		(214 (SocketPlugin primitiveSocketLocalPort))
		(215 (SocketPlugin primitiveSocketRemoteAddress))
		(216 (SocketPlugin primitiveSocketRemotePort))
		(217 (SocketPlugin primitiveSocketConnectToPort))
		(218 (SocketPlugin primitiveSocketListenWithOrWithoutBacklog))
		(219 (SocketPlugin primitiveSocketCloseConnection))
		(220 (SocketPlugin primitiveSocketAbortConnection))
		(221 (SocketPlugin primitiveSocketReceiveDataBufCount))
		(222 (SocketPlugin primitiveSocketReceiveDataAvailable))
		(223 (SocketPlugin primitiveSocketSendDataBufCount))
		(224 (SocketPlugin primitiveSocketSendDone))
		(225 (SocketPlugin primitiveSocketAccept))

		"Other Primitives (230-249)"
		(234 (MiscPrimitivePlugin primitiveDecompressFromByteArray))
		(235 (MiscPrimitivePlugin primitiveCompareString))
		(236 (MiscPrimitivePlugin primitiveConvert8BitSigned))
		(237 (MiscPrimitivePlugin primitiveCompressToByteArray))
		(238 (SerialPlugin primitiveSerialPortOpen))
		(239 (SerialPlugin primitiveSerialPortClose))
		(240 (SerialPlugin primitiveSerialPortWrite))
		(241 (SerialPlugin primitiveSerialPortRead))

		(243 (MiscPrimitivePlugin primitiveTranslateStringWithTable))
		(244 (MiscPrimitivePlugin primitiveFindFirstInString))
		(245 (MiscPrimitivePlugin primitiveIndexOfAsciiInString))
		(246 (MiscPrimitivePlugin primitiveFindSubstring))

		"MIDI Primitives (521-539)"
		(521 (MIDIPlugin primitiveMIDIClosePort))
		(522 (MIDIPlugin primitiveMIDIGetClock))
		(523 (MIDIPlugin primitiveMIDIGetPortCount))
		(524 (MIDIPlugin primitiveMIDIGetPortDirectionality))
		(525 (MIDIPlugin primitiveMIDIGetPortName))
		(526 (MIDIPlugin primitiveMIDIOpenPort))
		(527 (MIDIPlugin primitiveMIDIParameterGetOrSet))
		(528 (MIDIPlugin primitiveMIDIRead))
		(529 (MIDIPlugin primitiveMIDIWrite))

		"Experimental Asynchrous File Primitives"
		(540 (AsynchFilePlugin primitiveAsyncFileClose))
		(541 (AsynchFilePlugin primitiveAsyncFileOpen))
		(542 (AsynchFilePlugin primitiveAsyncFileReadResult))
		(543 (AsynchFilePlugin primitiveAsyncFileReadStart))
		(544 (AsynchFilePlugin primitiveAsyncFileWriteResult))
		(545 (AsynchFilePlugin primitiveAsyncFileWriteStart))

		"Pen Tablet Primitives"
		(548 (JoystickTabletPlugin primitiveGetTabletParameters))
		(549 (JoystickTabletPlugin primitiveReadTablet))

		"Sound Codec Primitives"

		(550 (ADPCMCodecPlugin primitiveDecodeMono))
		(551 (ADPCMCodecPlugin primitiveDecodeStereo))	
		(552 (ADPCMCodecPlugin primitiveEncodeMono))	
		(553 (ADPCMCodecPlugin primitiveEncodeStereo))

	) do:[:spec| table at: spec first+1 put: spec second].
	^table
]

{ #category : #initialization }
Interpreter class >> obsoleteIndexedPrimitiveTableString [
	"Interpreter obsoleteIndexedPrimitiveTableString"
	"Initialize the links from the (now obsolete) indexed primitives 
	to the new named primitives."
	| table |
	table := self obsoleteIndexedPrimitiveTable.
	^ String streamContents: [:s | 
			s nextPutAll: '{';
				 cr.
			table doWithIndex: [:primSpec :idx | 
					primSpec
						ifNil: [s nextPutAll: '{ NULL, NULL, NULL }']
						ifNotNil: [s nextPutAll: '{ "';
								 nextPutAll: primSpec first;
								 nextPutAll: '", "';
								 nextPutAll: primSpec last;
								 nextPutAll: '", NULL }'].
					idx < table size
						ifTrue: [s nextPut: $,;
								 cr]].
			s cr; nextPutAll: '}']
]

{ #category : #initialization }
Interpreter class >> obsoleteNamedPrimitiveTable [
	"Interpreter obsoleteNamedPrimitiveTableString"
	"Initialize the links from the (now obsolete) named primitives to
	the new named primitives."
	^#(
		(gePrimitiveMergeFillFrom B2DPlugin primitiveMergeFillFrom)
		(gePrimitiveSetClipRect B2DPlugin primitiveSetClipRect)
		(gePrimitiveDoProfileStats B2DPlugin primitiveDoProfileStats)
		(gePrimitiveAddCompressedShape B2DPlugin primitiveAddCompressedShape)
		(gePrimitiveFinishedProcessing B2DPlugin primitiveFinishedProcessing)
		(gePrimitiveGetBezierStats B2DPlugin primitiveGetBezierStats)
		(gePrimitiveSetDepth B2DPlugin primitiveSetDepth)
		(gePrimitiveAbortProcessing B2DPlugin primitiveAbortProcessing)
		(gePrimitiveGetTimes B2DPlugin primitiveGetTimes)
		(gePrimitiveNextActiveEdgeEntry B2DPlugin primitiveNextActiveEdgeEntry)
		(gePrimitiveAddBezier B2DPlugin primitiveAddBezier)
		(gePrimitiveRenderScanline B2DPlugin primitiveRenderScanline)
		(gePrimitiveAddBezierShape B2DPlugin primitiveAddBezierShape)
		(gePrimitiveAddLine B2DPlugin primitiveAddLine)
		(gePrimitiveRenderImage B2DPlugin primitiveRenderImage)
		(gePrimitiveGetAALevel B2DPlugin primitiveGetAALevel)
		(gePrimitiveRegisterExternalEdge B2DPlugin primitiveRegisterExternalEdge)
		(gePrimitiveInitializeBuffer B2DPlugin primitiveInitializeBuffer)
		(gePrimitiveAddRect B2DPlugin primitiveAddRect)
		(gePrimitiveInitializeProcessing B2DPlugin primitiveInitializeProcessing)
		(gePrimitiveAddBitmapFill B2DPlugin primitiveAddBitmapFill)
		(gePrimitiveGetClipRect B2DPlugin primitiveGetClipRect)
		(gePrimitiveGetFailureReason B2DPlugin primitiveGetFailureReason)
		(gePrimitiveNextGlobalEdgeEntry B2DPlugin primitiveNextGlobalEdgeEntry)
		(gePrimitiveNextFillEntry B2DPlugin primitiveNextFillEntry)
		(gePrimitiveSetColorTransform B2DPlugin primitiveSetColorTransform)
		(gePrimitiveDisplaySpanBuffer B2DPlugin primitiveDisplaySpanBuffer)
		(gePrimitiveGetOffset B2DPlugin primitiveGetOffset)
		(gePrimitiveAddPolygon B2DPlugin primitiveAddPolygon)
		(gePrimitiveNeedsFlush B2DPlugin primitiveNeedsFlush)
		(gePrimitiveAddOval B2DPlugin primitiveAddOval)
		(gePrimitiveSetAALevel B2DPlugin primitiveSetAALevel)
		(gePrimitiveCopyBuffer B2DPlugin primitiveCopyBuffer)
		(gePrimitiveAddActiveEdgeEntry B2DPlugin primitiveAddActiveEdgeEntry)
		(gePrimitiveGetCounts B2DPlugin primitiveGetCounts)
		(gePrimitiveSetOffset B2DPlugin primitiveSetOffset)
		(gePrimitiveAddGradientFill B2DPlugin primitiveAddGradientFill)
		(gePrimitiveChangedActiveEdgeEntry B2DPlugin primitiveChangedActiveEdgeEntry)
		(gePrimitiveRegisterExternalFill B2DPlugin primitiveRegisterExternalFill)
		(gePrimitiveGetDepth B2DPlugin primitiveGetDepth)
		(gePrimitiveSetEdgeTransform B2DPlugin primitiveSetEdgeTransform)
		(gePrimitiveNeedsFlushPut B2DPlugin primitiveNeedsFlushPut)

		(primitiveFloatArrayAt FloatArrayPlugin primitiveAt)
		(primitiveFloatArrayMulFloatArray FloatArrayPlugin primitiveMulFloatArray)
		(primitiveFloatArrayAddScalar FloatArrayPlugin primitiveAddScalar)
		(primitiveFloatArrayDivFloatArray FloatArrayPlugin primitiveDivFloatArray)
		(primitiveFloatArrayDivScalar FloatArrayPlugin primitiveDivScalar)
		(primitiveFloatArrayHash FloatArrayPlugin primitiveHashArray)
		(primitiveFloatArrayAtPut FloatArrayPlugin primitiveAtPut)
		(primitiveFloatArrayMulScalar FloatArrayPlugin primitiveMulScalar)
		(primitiveFloatArrayAddFloatArray FloatArrayPlugin primitiveAddFloatArray)
		(primitiveFloatArraySubScalar FloatArrayPlugin primitiveSubScalar)
		(primitiveFloatArraySubFloatArray FloatArrayPlugin primitiveSubFloatArray)
		(primitiveFloatArrayEqual FloatArrayPlugin primitiveEqual)
		(primitiveFloatArrayDotProduct FloatArrayPlugin primitiveDotProduct)

		(m23PrimitiveInvertRectInto Matrix2x3Plugin primitiveInvertRectInto)
		(m23PrimitiveTransformPoint Matrix2x3Plugin primitiveTransformPoint)
		(m23PrimitiveIsPureTranslation Matrix2x3Plugin primitiveIsPureTranslation)
		(m23PrimitiveComposeMatrix Matrix2x3Plugin primitiveComposeMatrix)
		(m23PrimitiveTransformRectInto Matrix2x3Plugin primitiveTransformRectInto)
		(m23PrimitiveIsIdentity Matrix2x3Plugin primitiveIsIdentity)
		(m23PrimitiveInvertPoint Matrix2x3Plugin primitiveInvertPoint)

		(primitiveDeflateBlock ZipPlugin primitiveDeflateBlock)
		(primitiveDeflateUpdateHashTable ZipPlugin primitiveDeflateUpdateHashTable)
		(primitiveUpdateGZipCrc32 ZipPlugin primitiveUpdateGZipCrc32)
		(primitiveInflateDecompressBlock ZipPlugin primitiveInflateDecompressBlock)
		(primitiveZipSendBlock ZipPlugin primitiveZipSendBlock)

		(primitiveFFTTransformData FFTPlugin primitiveFFTTransformData)
		(primitiveFFTScaleData FFTPlugin primitiveFFTScaleData)
		(primitiveFFTPermuteData FFTPlugin primitiveFFTPermuteData)
	)
]

{ #category : #initialization }
Interpreter class >> obsoleteNamedPrimitiveTableString [
	"Interpreter obsoleteNamedPrimitiveTableString"
	"Initialize the links from the (now obsolete) indexed primitives 
	to the new named primitives."
	| table |
	table := self obsoleteNamedPrimitiveTable.
	^ String streamContents: [:s | 
			s nextPutAll: '{';
				 cr.
			table do: [:primSpec | s nextPutAll: '{ "';
						 nextPutAll: primSpec first;
						 nextPutAll: '", "';
						 nextPutAll: primSpec second;
						 nextPutAll: '", "';
						 nextPutAll: primSpec third;
						 nextPutAll: '" },';
						 cr].
			s nextPutAll: '{ NULL, NULL, NULL }'.
			s cr; nextPutAll: '}']
]

{ #category : #translation }
Interpreter class >> patchInterp: fileName [
	"Interpreter patchInterp: 'Squeak VM PPC'"
	"This will patch out the unneccesary range check (a compare
	 and branch) in the inner interpreter dispatch loop."
	"NOTE: You must edit in the Interpeter file name, and the
	 number of instructions (delta) to count back to find the compare
	 and branch that we want to get rid of."

	| delta f code len remnant i |
	delta := 6.
	f := FileStream fileNamed: fileName.
	f binary.
	code := Bitmap new: (len := f size) // 4.
	f nextInto: code.
	remnant := f next: len - (code size * 4).
	i := 0.
	["Look for a BCTR instruction"
	(i := code indexOf: 16r4E800420 startingAt: i + 1 ifAbsent: [0]) > 0] whileTrue:
		["Look for a CMPLWI FF, 6 instrs back"
	       ((code at: i - delta) bitAnd: 16rFFE0FFFF) = 16r280000FF ifTrue:
			["Copy dispatch instrs back over the compare"
			self inform: 'Patching at ', i hex.
			0 to: delta - 2 do: [ :j |
				code at: (i - delta) + j put: (code at: (i - delta) + j + 2)]]].
	f position: 0; nextPutAll: code; nextPutAll: remnant.
	f close.

]

{ #category : #translation }
Interpreter class >> patchInterpGCCPPC: fileName [
	"Interpreter patchInterpGCCPPC: 'Squeak copy 1'"
	"This will patch out the unneccesary range check (a compare
	 and branch) in the inner interpreter dispatch loop. for the PPC version of the GCC compiled
	version of Squeak under MPW"
	"NOTE: You must edit in the Interpeter file name"

	| delta f code len remnant i |
	delta := 7.
	f := FileStream fileNamed: fileName.
	f binary.
	code := Bitmap new: (len := f size) // 4.
	f nextInto: code.
	remnant := f next: len - (code size * 4).
	i := 0.
	["Look for a BCTR instruction"
	(i := code indexOf: 16r4E800420 startingAt: i + 1 ifAbsent: [0]) > 0] whileTrue:
		["Look for a CMPLWI cr1,rxx,FF, 7 instrs back"
	       ((code at: i - delta) bitAnd: 16rFFE0FFFF) = 16r288000FF ifTrue:
	       	["Copy dispatch instrs back over the compare"
			self inform: 'Patching at ', i hex.
			0 to: delta - 2 do: [ :j |
				code at: (i - delta) + j put: (code at: (i - delta) + j + 2)]]].
	f position: 0; nextPutAll: code; nextPutAll: remnant.
	f close
]

{ #category : #constants }
Interpreter class >> primitiveTable [

	^ PrimitiveTable
]

{ #category : #initialization }
Interpreter class >> primitiveTableString [
	"Interpreter initializePrimitiveTable primitiveTableString"
	| table |
	table := self primitiveTable.
	^ String
		streamContents: [:s | 
			s nextPut: ${.
			table
				withIndexDo: [:primSpec :index | s cr; tab;
					nextPutAll: '/* ';
					nextPutAll: (index - 1) printString;
					nextPutAll: '*/ ';
					nextPutAll: '(void *)';
					nextPutAll: primSpec;
					nextPut: $,].
			s cr; nextPutAll: ' 0 }']
]

{ #category : #translation }
Interpreter class >> requiredMethodNames [
	"return the list of method names that should be retained for export or other support reasons"
	| requiredList |
	requiredList := Set new:400.
	"A number of methods required by VM support code, jitter, specific platforms etc"
	requiredList addAll: #(fullDisplayUpdate interpret printCallStack printAllStacks readImageFromFile:HeapSize:StartingAt: success: readableFormat: getCurrentBytecode characterForAscii: findClassOfMethod:forReceiver: findSelectorOfMethod:forReceiver: loadInitialContext nullCompilerHook primitiveFlushExternalPrimitives setCompilerInitialized: getFullScreenFlag getInterruptCheckCounter getInterruptKeycode getInterruptPending getNextWakeupTick getSavedWindowSize setFullScreenFlag: setInterruptCheckCounter: setInterruptKeycode: setInterruptPending: setNextWakeupTick: setSavedWindowSize: forceInterruptCheck getThisSessionID setMicroSeconds:andOffset:).

	"Nice to actually have all the primitives available"
	requiredList addAll: self primitiveTable.

	"InterpreterProxy is the internal analogue of sqVirtualMachine.c, so make sure to keep all those"
	InterpreterProxy organization categories do: [:cat |
		((cat ~= 'initialize') and: [cat ~= 'private']) ifTrue: [
			requiredList addAll: (InterpreterProxy organization listAtCategoryNamed: cat)]].
	
	^requiredList
]

{ #category : #initialization }
Interpreter class >> table: anArray from: specArray [ 
	"SpecArray is an array of either (index selector) or (index1 
	index2 selector)."
	| contiguous |
	contiguous := 0.
	specArray do: [:spec | 
			(spec at: 1) = contiguous
				ifFalse: [self error: 'Non-contiguous table entry'].
			spec size = 2
				ifTrue: [anArray at: (spec at: 1) + 1
						put: (spec at: 2).
					contiguous := contiguous + 1]
				ifFalse: [(spec at: 1) to: (spec at: 2) do: [:i | anArray at: i + 1 put: (spec at: 3)].
					contiguous := contiguous + ((spec at: 2) - (spec at: 1)) + 1]]
]

{ #category : #'control primitives' }
Interpreter >> activateNewClosureMethod: blockClosure [
	"Similar to activateNewMethod but for Closure and newMethod."
	| theBlockClosure closureMethod newContext methodHeader numCopied where outerContext |

	DoAssertionChecks ifTrue:
		[self okayOop: blockClosure].
	outerContext := self fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	DoAssertionChecks ifTrue:
		[self okayOop: outerContext].
	closureMethod := self fetchPointer: MethodIndex ofObject: outerContext.
	methodHeader := self headerOf: closureMethod.
	self pushRemappableOop: blockClosure.
	newContext := self allocateOrRecycleContext: (methodHeader bitAnd: LargeContextBit). "All for one, and one for all!"

	"allocateOrRecycleContext: may cause a GC; restore blockClosure and refetch outerContext et al"
	theBlockClosure := self popRemappableOop.
	outerContext := self fetchPointer: ClosureOuterContextIndex ofObject: theBlockClosure.
	numCopied := (self fetchWordLengthOf: theBlockClosure) - ClosureFirstCopiedValueIndex.

	"Assume: newContext will be recorded as a root if necessary by the
	 call to newActiveContext: below, so we can use unchecked stores."
	where :=  newContext + self baseHeaderSize.
	self longAt: where + (SenderIndex << self shiftForWord)
		put: activeContext.
	self longAt: where + (InstructionPointerIndex << self shiftForWord)
		put: (self fetchPointer: ClosureStartPCIndex ofObject: theBlockClosure).
	self longAt: where + (StackPointerIndex << self shiftForWord)
		put: (self integerObjectOf: argumentCount + numCopied).
	self longAt: where + (MethodIndex << self shiftForWord)
		put: (self fetchPointer: MethodIndex ofObject: outerContext).
	self longAt: where + (ClosureIndex << self shiftForWord)
		put: theBlockClosure.
	self longAt: where + (ReceiverIndex << self shiftForWord)
		put: (self fetchPointer: ReceiverIndex ofObject: outerContext).

	"Copy the arguments..."
	1 to: argumentCount do:
		[:i | self longAt: where + ((ReceiverIndex+i) << self shiftForWord)
				put: (self stackValue: argumentCount-i)].

	"Copy the copied values..."
	where := newContext + self baseHeaderSize + ((ReceiverIndex + 1 + argumentCount) << self shiftForWord).
	0 to: numCopied - 1 do:
		[:i| self longAt: where + (i << self shiftForWord)
				put: (self fetchPointer: i + ClosureFirstCopiedValueIndex
						  ofObject: theBlockClosure)].

	"The initial instructions in the block nil-out remaining temps."

	self pop: argumentCount + 1.
	self newActiveContext: newContext
]

{ #category : #'message sending' }
Interpreter >> activateNewMethod [
	| newContext methodHeader initialIP tempCount nilOop where |

	methodHeader := self headerOf: newMethod.
	newContext := self allocateOrRecycleContext: (methodHeader bitAnd: LargeContextBit).

	initialIP := ((LiteralStart + (self literalCountOfHeader: methodHeader)) * self bytesPerWord) + 1.
	tempCount := (methodHeader >> 19) bitAnd: 16r3F.

	"Assume: newContext will be recorded as a root if necessary by the
	 call to newActiveContext: below, so we can use unchecked stores."

	where :=  newContext  + self baseHeaderSize.
	self longAt: where + (SenderIndex << self shiftForWord) put: activeContext.
	self longAt: where + (InstructionPointerIndex << self shiftForWord) put: (self integerObjectOf: initialIP).
	self longAt: where + (StackPointerIndex << self shiftForWord) put: (self integerObjectOf: tempCount).
	self longAt: where + (MethodIndex << self shiftForWord) put: newMethod.
	self longAt: where + (ClosureIndex << self shiftForWord) put: nilObj.

	"Copy the receiver and arguments..."
	0 to: argumentCount do:
		[:i | self longAt: where + ((ReceiverIndex+i) << self shiftForWord) put: (self stackValue: argumentCount-i)].

	"clear remaining temps to nil in case it has been recycled"
	nilOop := nilObj.
	argumentCount+1+ReceiverIndex to: tempCount+ReceiverIndex do:
		[:i | self longAt: where + (i << self shiftForWord) put: nilOop].

	self pop: argumentCount + 1.
	reclaimableContextCount := reclaimableContextCount + 1.
	self newActiveContext: newContext.
]

{ #category : #'process primitive support' }
Interpreter >> addLastLink: proc toList: aList [ 
	"Add the given process to the given linked list and set the 
	backpointer of process to its new list."
	| lastLink |
	(self isEmptyList: aList)
		ifTrue: [self storePointer: FirstLinkIndex ofObject: aList withValue: proc]
		ifFalse: [lastLink := self fetchPointer: LastLinkIndex ofObject: aList.
			self storePointer: NextLinkIndex ofObject: lastLink withValue: proc].
	self storePointer: LastLinkIndex ofObject: aList withValue: proc.
	self storePointer: MyListIndex ofObject: proc withValue: aList
]

{ #category : #'method lookup cache' }
Interpreter >> addNewMethodToCache [
	"Add the given entry to the method cache.
	The policy is as follows:
		Look for an empty entry anywhere in the reprobe chain.
		If found, install the new entry there.
		If not found, then install the new entry at the first probe position
			and delete the entries in the rest of the reprobe chain.
		This has two useful purposes:
			If there is active contention over the first slot, the second
				or third will likely be free for reentry after ejection.
			Also, flushing is good when reprobe chains are getting full."
	| probe hash |
	<inline: false>
	self compilerTranslateMethodHook.	"newMethod x lkupClass -> newNativeMethod (may cause GC !)"
	hash := messageSelector bitXor: lkupClass.  "drop low-order zeros from addresses"

	primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: lkupClass.
	
	0 to: CacheProbeMax-1 do:
		[:p | probe := (hash >> p) bitAnd: MethodCacheMask.
		(methodCache at: probe + MethodCacheSelector) = 0 ifTrue:
			["Found an empty entry -- use it"
			methodCache at: probe + MethodCacheSelector put: messageSelector.
			methodCache at: probe + MethodCacheClass put: lkupClass.
			methodCache at: probe + MethodCacheMethod put: newMethod.
			methodCache at: probe + MethodCachePrim put: primitiveIndex.
			methodCache at: probe + MethodCacheNative put: newNativeMethod.
			methodCache at: probe + MethodCachePrimFunction put: (self cCoerce: primitiveFunctionPointer to: 'long').
			^ nil]].

	"OK, we failed to find an entry -- install at the first slot..."
	probe := hash bitAnd: MethodCacheMask.  "first probe"
	methodCache at: probe + MethodCacheSelector put: messageSelector.
	methodCache at: probe + MethodCacheClass put: lkupClass.
	methodCache at: probe + MethodCacheMethod put: newMethod.
	methodCache at: probe + MethodCachePrim put: primitiveIndex.
	methodCache at: probe + MethodCacheNative put: newNativeMethod.
	methodCache at: probe + MethodCachePrimFunction put: (self cCoerce: primitiveFunctionPointer to: 'long').

	"...and zap the following entries"
	1 to: CacheProbeMax-1 do:
		[:p | probe := (hash >> p) bitAnd: MethodCacheMask.
		methodCache at: probe + MethodCacheSelector put: 0].

]

{ #category : #'plugin support' }
Interpreter >> addToExternalPrimitiveTable: functionAddress [
	"Add the given function address to the external primitive table and return the index where it's stored. This function doesn't need to be fast since it is only called when an external primitive has been looked up (which takes quite a bit of time itself). So there's nothing specifically complicated here.
	Note: Return index will be one-based (ST convention)"

	<var: #functionAddress declareC: 'void *functionAddress'>

	0 to: MaxExternalPrimitiveTableSize-1 do: [ :i |
		(externalPrimitiveTable at: i) = 0 ifTrue: [
			externalPrimitiveTable at: i put: functionAddress.
			^i+1]].
	"if no space left, return zero so it'll looked up again"
	^0
]

{ #category : #'debug support' }
Interpreter >> allAccessibleObjectsOkay [
	"Ensure that all accessible objects in the heap are okay."

	| oop |
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse: [
		self okayFields: oop.
		oop := self accessibleObjectAfter: oop.
	].
]

{ #category : #'image save/restore' }
Interpreter >> allocateMemory: heapSize minimum: minimumMemory imageFile: fileStream headerSize: headerSize [

	"Translate to C function call with (case sensitive) camelCase. The purpose of this
	method is to document the translation.
	The default implementation is sqAllocateMemory(minimumMemory, heapSize). This may
	be redefined to make use of the image file and header size parameters for efficient
	implementation with mmap().
	See CCodeGenerator>>writeDefaultMacrosOn: which specifies a default implementation."

	<inline: true>
	<returnTypeC: 'char *'>
	<var: #fileStream type: 'sqImageFile'>
	^ self
		allocateMemory: heapSize
		Minimum: minimumMemory
		ImageFile: fileStream
		HeaderSize: headerSize
]

{ #category : #utilities }
Interpreter >> areIntegers: oop1 and: oop2 [
"Test oop1 and oop2 to make sure both are SmallIntegers."
	^ ((oop1 bitAnd: oop2) bitAnd: 1) ~= 0
]

{ #category : #'message sending' }
Interpreter >> argCount [
	^ argumentCount
]

{ #category : #'compiled methods' }
Interpreter >> argumentCountOf: methodPointer [
	^ ((self headerOf: methodPointer) >> 25) bitAnd: 16r0F
]

{ #category : #contexts }
Interpreter >> argumentCountOfBlock: blockPointer [

	| localArgCount |
	localArgCount := self fetchPointer: BlockArgumentCountIndex ofObject: blockPointer.
	^self checkedIntegerValueOf: localArgCount
]

{ #category : #contexts }
Interpreter >> argumentCountOfClosure: closurePointer [

	^self quickFetchInteger: ClosureNumArgsIndex ofObject: closurePointer
]

{ #category : #'compiled methods' }
Interpreter >> argumentCountOfMethodHeader: header [
	^ (header >> 25) bitAnd: 16r0F
]

{ #category : #utilities }
Interpreter >> arrayValueOf: arrayOop [
	"Return the address of first indexable field of resulting array object, or fail if the instance variable does not contain an indexable bytes or words object."
	"Note: May be called by translated primitive code."

	<returnTypeC: 'void *'>
	((self isIntegerObject: arrayOop) not and:
	 [self isWordsOrBytes: arrayOop])
		ifTrue: [^ self pointerForOop: (arrayOop + self baseHeaderSize)].
	self primitiveFail.

]

{ #category : #'array primitive support' }
Interpreter >> asciiOfCharacter: characterObj [  "Returns an integer object"

	<inline: false>
	self assertClassOf: characterObj is: (self splObj: ClassCharacter).
	successFlag
		ifTrue: [^ self fetchPointer: CharacterValueIndex ofObject: characterObj]
		ifFalse: [^ ConstZero]  "in case some code needs an int"
]

{ #category : #utilities }
Interpreter >> assertClassOf: oop is: classOop [
	"Succeed if the given (non-integer) object is an instance of the given class. Fail if the object is an integer."

	| ccIndex cl |
	<inline: true>
	(self isIntegerObject: oop)
		ifTrue: [ successFlag := false. ^ nil ].

	ccIndex := ((self baseHeader: oop) >> 12) bitAnd: 16r1F.
	ccIndex = 0
		ifTrue: [ cl := ((self classHeader: oop) bitAnd: self allButTypeMask) ]
		ifFalse: [
			"look up compact class"
			cl := (self fetchPointer: (ccIndex - 1)
					ofObject: (self fetchPointer: CompactClasses ofObject: specialObjectsOop))].

	self success: cl = classOop.

]

{ #category : #'debug support' }
Interpreter >> balancedStack: delta afterPrimitive: primIdx withArgs: nArgs [
	"Return true if the stack is still balanced after executing primitive primIndex with nArgs args. Delta is 'stackPointer - activeContext' which is a relative measure for the stack pointer (so we don't have to relocate it during the primitive)"
	(primIdx >= 81 and:[primIdx <= 88]) ifTrue:[^true].
	"81-88 are control primitives after which the stack may look unbalanced"
	successFlag ifTrue:[
		"Successful prim, stack must have exactly nArgs arguments popped off"
		^(stackPointer - activeContext + (nArgs * self bytesPerWord)) = delta
	].
	"Failed prim must leave stack intact"
	^(stackPointer - activeContext) = delta

]

{ #category : #utilities }
Interpreter >> booleanCheat: cond [
"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	| bytecode offset |
	<inline: true>

	bytecode := self fetchByte.  "assume next bytecode is jumpIfFalse (99%)"
	self internalPop: 2.
	(bytecode < 160 and: [bytecode > 151]) ifTrue: [  "short jumpIfFalse"
		cond
			ifTrue: [^ self fetchNextBytecode]
			ifFalse: [^ self jump: bytecode - 151]].

	bytecode = 172 ifTrue: [  "long jumpIfFalse"
		offset := self fetchByte.
		cond
			ifTrue: [^ self fetchNextBytecode]
			ifFalse: [^ self jump: offset]].

	"not followed by a jumpIfFalse; undo instruction fetch and push boolean result"
	localIP := localIP - 1.
	self fetchNextBytecode.
	cond
		ifTrue: [self internalPush: trueObj]
		ifFalse: [self internalPush: falseObj].

]

{ #category : #utilities }
Interpreter >> booleanValueOf: obj [
"convert true and false (Smalltalk) to true or false(C)"
	obj = trueObj ifTrue: [ ^ true ].
	obj = falseObj ifTrue: [ ^ false ].
	successFlag := false.
	^ nil
]

{ #category : #'array primitive support' }
Interpreter >> byteLengthOf: oop [
	"Return the number of indexable bytes in the given object. This is basically a special copy of lengthOf: for BitBlt."
	| header sz fmt |
	header := self baseHeader: oop.
	(header bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ sz := (self sizeHeader: oop) bitAnd: self allButTypeMask ]
		ifFalse: [ sz := header bitAnd: self sizeMask ].
	fmt := (header >> 8) bitAnd: 16rF.
	fmt < 8
		ifTrue: [ ^ (sz - self baseHeaderSize)]  "words"
		ifFalse: [ ^ (sz - self baseHeaderSize) - (fmt bitAnd: 3)]  "bytes"
]

{ #category : #'object format' }
Interpreter >> byteSizeOf: oop [
	| slots |
self flag: #Dan.
	(self isIntegerObject: oop) ifTrue:[^0].
	slots := self slotSizeOf: oop.
	(self isBytesNonInt: oop)
		ifTrue:[^slots]
		ifFalse:[^slots * 4]
]

{ #category : #'image save/restore' }
Interpreter >> byteSwapByteObjects [
	"Byte-swap the words of all bytes objects in the image. This returns these objects to their original byte ordering after blindly byte-swapping the entire image."

	self byteSwapByteObjectsFrom: self firstObject to: endOfMemory
]

{ #category : #'image save/restore' }
Interpreter >> byteSwapByteObjectsFrom: startOop to: stopAddr [ 
	"Byte-swap the words of all bytes objects in a range of the 
	image, including Strings, ByteArrays, and CompiledMethods. 
	This returns these objects to their original byte ordering 
	after blindly byte-swapping the entire image. For compiled 
	methods, byte-swap only their bytecodes part."
	| oop fmt wordAddr methodHeader |
	oop := startOop.
	[self oop: oop isLessThan: stopAddr]
		whileTrue: [(self isFreeObject: oop)
				ifFalse: [fmt := self formatOf: oop.
					fmt >= 8
						ifTrue: ["oop contains bytes"
							wordAddr := oop + self baseHeaderSize.
							fmt >= 12
								ifTrue: ["compiled method; start after methodHeader and literals"
									methodHeader := self longAt: oop + self baseHeaderSize.
									wordAddr := wordAddr + self bytesPerWord + ((methodHeader >> 10 bitAnd: 255) * self bytesPerWord)].
							self reverseBytesFrom: wordAddr to: oop + (self sizeBitsOf: oop)].
					(fmt = 6 and: [self bytesPerWord = 8])
						ifTrue: ["Object contains 32-bit half-words packed into 64-bit machine words."
							wordAddr := oop + self baseHeaderSize.
							self reverseWordsFrom: wordAddr to: oop + (self sizeBitsOf: oop)]].
			oop := self objectAfter: oop]
]

{ #category : #'image save/restore' }
Interpreter >> byteSwapped: w [
	"Answer the given integer with its bytes in the reverse order."

	<inline: true>
	self isDefinedTrueExpression: 'BYTES_PER_WORD == 4'
		inSmalltalk: [self bytesPerWord = 4]
		comment: 'swap bytes in an object word'
		ifTrue:
			[^ ((w bitShift: Byte3ShiftNegated) bitAnd: Byte0Mask)
			 + ((w bitShift: Byte1ShiftNegated) bitAnd: Byte1Mask)
			 + ((w bitShift: Byte1Shift         ) bitAnd: Byte2Mask)
			 + ((w bitShift: Byte3Shift         ) bitAnd: Byte3Mask)]
		ifFalse:
			[^ ((w bitShift: Byte7ShiftNegated) bitAnd: Byte0Mask)
			 + ((w bitShift: Byte5ShiftNegated) bitAnd: Byte1Mask)
			 + ((w bitShift: Byte3ShiftNegated) bitAnd: Byte2Mask)
			 + ((w bitShift: Byte1ShiftNegated) bitAnd: Byte3Mask)
			 + ((w bitShift: Byte1Shift         ) bitAnd: Byte4Mask)
			 + ((w bitShift: Byte3Shift         ) bitAnd: Byte5Mask)
			 + ((w bitShift: Byte5Shift         ) bitAnd: Byte6Mask)
			 + ((w bitShift: Byte7Shift         ) bitAnd: Byte7Mask)]
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimAdd [
	| rcvr arg result |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg)
		ifTrue: [result := (self integerValueOf: rcvr) + (self integerValueOf: arg).
				(self isIntegerValue: result) ifTrue:
					[self internalPop: 2 thenPush: (self integerObjectOf: result).
					^ self fetchNextBytecode "success"]]
		ifFalse: [successFlag := true.
				self externalizeIPandSP.
				self primitiveFloatAdd: rcvr toArg: arg.
				self internalizeIPandSP.
				successFlag ifTrue: [^ self fetchNextBytecode "success"]].

	messageSelector := self specialSelector: 0.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimAt [
	"BytecodePrimAt will only succeed if the receiver is in the atCache.
	Otherwise it will fail so that the more general primitiveAt will put it in the
	cache after validating that message lookup results in a primitive response."
	| index rcvr result atIx |
	index := self internalStackTop.
	rcvr := self internalStackValue: 1.
	successFlag := (self isIntegerObject: rcvr) not and: [self isIntegerObject: index].
	successFlag ifTrue:
		[atIx := rcvr bitAnd: AtCacheMask.  "Index into atCache = 4N, for N = 0 ... 7"
		(atCache at: atIx+AtCacheOop) = rcvr
		ifTrue: [result := self commonVariableInternal: rcvr at: (self integerValueOf: index) cacheIndex: atIx.
			successFlag ifTrue:
				[self fetchNextBytecode.
				^self internalPop: 2 thenPush: result]]].

	messageSelector := self specialSelector: 16.
	argumentCount := 1.
	self normalSend.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimAtEnd [
	messageSelector := self specialSelector: 21.
	argumentCount := 0.
	self normalSend.
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimAtPut [
	"BytecodePrimAtPut will only succeed if the receiver is in the atCache.
	Otherwise it will fail so that the more general primitiveAtPut will put it in the
	cache after validating that message lookup results in a primitive response."
	| index rcvr atIx value |
	value := self internalStackTop.
	index := self internalStackValue: 1.
	rcvr := self internalStackValue: 2.
	successFlag := (self isIntegerObject: rcvr) not and: [self isIntegerObject: index].
	successFlag
		ifTrue: [atIx := (rcvr bitAnd: AtCacheMask) + AtPutBase.  "Index into atPutCache"
			(atCache at: atIx+AtCacheOop) = rcvr
				ifTrue: [self commonVariable: rcvr at: (self integerValueOf: index) put: value cacheIndex: atIx.
					successFlag ifTrue: [self fetchNextBytecode.
						^self internalPop: 3 thenPush: value]]].

	messageSelector := self specialSelector: 17.
	argumentCount := 2.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimBitAnd [

	successFlag := true.
	self externalizeIPandSP.
	self primitiveBitAnd.
	self internalizeIPandSP.
	successFlag ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 14.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimBitOr [

	successFlag := true.
	self externalizeIPandSP.
	self primitiveBitOr.
	self internalizeIPandSP.
	successFlag ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 15.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimBitShift [

	successFlag := true.
	self externalizeIPandSP.
	self primitiveBitShift.
	self internalizeIPandSP.
	successFlag ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 12.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimBlockCopy [

	| rcvr hdr |
	rcvr := self internalStackValue: 1.
	successFlag := true.
	hdr := self baseHeader: rcvr.
	self success: (self isContextHeader: hdr).
	successFlag ifTrue: [self externalizeIPandSP.
		self primitiveBlockCopy.
		self internalizeIPandSP].
	successFlag ifFalse: [messageSelector := self specialSelector: 24.
		argumentCount := 1.
		^ self normalSend].
	self fetchNextBytecode.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimClass [
	| rcvr |
	rcvr := self internalStackTop.
	self internalPop: 1 thenPush: (self fetchClassOf: rcvr).
	self fetchNextBytecode.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimDiv [
	| quotient |
	successFlag := true.
	quotient := self doPrimitiveDiv: (self internalStackValue: 1) by: (self internalStackValue: 0).
	successFlag ifTrue: [self internalPop: 2 thenPush: (self integerObjectOf: quotient).
		^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 13.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimDivide [
	| rcvr arg result |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg)
		ifTrue: [rcvr := self integerValueOf: rcvr.
			arg := self integerValueOf: arg.
			(arg ~= 0 and: [rcvr \\ arg = 0])
				ifTrue: [result := rcvr // arg.
					"generates C / operation"
					(self isIntegerValue: result)
						ifTrue: [self internalPop: 2 thenPush: (self integerObjectOf: result).
							^ self fetchNextBytecode"success"]]]
		ifFalse: [successFlag := true.
			self externalizeIPandSP.
			self primitiveFloatDivide: rcvr byArg: arg.
			self internalizeIPandSP.
			successFlag ifTrue: [^ self fetchNextBytecode"success"]].

	messageSelector := self specialSelector: 9.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimDo [

	messageSelector := self specialSelector: 27.
	argumentCount := 1.
	self normalSend.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue: [^self booleanCheat: rcvr = arg].

	successFlag := true.
	aBool := self primitiveFloatEqual: rcvr toArg: arg.
	successFlag ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 6.
	argumentCount := 1.
	self normalSend

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimEquivalent [

	| rcvr arg |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	self booleanCheat: rcvr = arg.
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimGreaterOrEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		[self cCode: '' inSmalltalk: [^self booleanCheat: (self integerValueOf: rcvr) >= (self integerValueOf: arg)].
		^self booleanCheat: rcvr >= arg].

	successFlag := true.
	aBool := self primitiveFloatGreaterOrEqual: rcvr toArg: arg.
	successFlag ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 5.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimGreaterThan [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		[self cCode: '' inSmalltalk: [^self booleanCheat: (self integerValueOf: rcvr) > (self integerValueOf: arg)].
		^self booleanCheat: rcvr > arg].

	successFlag := true.
	aBool := self primitiveFloatGreater: rcvr thanArg: arg.
	successFlag ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 3.
	argumentCount := 1.
	self normalSend

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimLessOrEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		[self cCode: '' inSmalltalk: [^self booleanCheat: (self integerValueOf: rcvr) <= (self integerValueOf: arg)].
		^ self booleanCheat: rcvr <= arg].

	successFlag := true.
	aBool := self primitiveFloatLessOrEqual: rcvr toArg: arg.
	successFlag ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 4.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimLessThan [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		[self cCode: '' inSmalltalk: [^self booleanCheat: (self integerValueOf: rcvr) < (self integerValueOf: arg)].
		^ self booleanCheat: rcvr < arg].

	successFlag := true.
	aBool := self primitiveFloatLess: rcvr thanArg: arg.
	successFlag ifTrue: [^ self booleanCheat: aBool].

	messageSelector := self specialSelector: 2.
	argumentCount := 1.
	self normalSend

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimMakePoint [

	successFlag := true.
	self externalizeIPandSP.
	self primitiveMakePoint.
	self internalizeIPandSP.
	successFlag ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 11.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimMod [
	| mod |
	successFlag := true.
	mod := self doPrimitiveMod: (self internalStackValue: 1) by: (self internalStackValue: 0).
	successFlag ifTrue:
		[self internalPop: 2 thenPush: (self integerObjectOf: mod).
		^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 10.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimMultiply [
	| rcvr arg result |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg)
		ifTrue: [rcvr := self integerValueOf: rcvr.
				arg := self integerValueOf: arg.
				result := rcvr * arg.
				((arg = 0 or: [(result // arg) = rcvr]) and: [self isIntegerValue: result])
					ifTrue: [self internalPop: 2 thenPush: (self integerObjectOf: result).
							^ self fetchNextBytecode "success"]]
		ifFalse: [successFlag := true.
				self externalizeIPandSP.
				self primitiveFloatMultiply: rcvr byArg: arg.
				self internalizeIPandSP.
				successFlag ifTrue: [^ self fetchNextBytecode "success"]].

	messageSelector := self specialSelector: 8.
	argumentCount := 1.
	self normalSend.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimNew [

	messageSelector := self specialSelector: 28.
	argumentCount := 0.
	self normalSend.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimNewWithArg [

	messageSelector := self specialSelector: 29.
	argumentCount := 1.
	self normalSend.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimNext [
	messageSelector := self specialSelector: 19.
	argumentCount := 0.
	self normalSend.
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimNextPut [
	messageSelector := self specialSelector: 20.
	argumentCount := 1.
	self normalSend.
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimNotEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue: [^self booleanCheat: rcvr ~= arg].

	successFlag := true.
	aBool := self primitiveFloatEqual: rcvr toArg: arg.
	successFlag ifTrue: [^self booleanCheat: aBool not].

	messageSelector := self specialSelector: 7.
	argumentCount := 1.
	self normalSend

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimPointX [

	| rcvr |
	successFlag := true.
	rcvr := self internalStackTop.
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	successFlag
		ifTrue: [self internalPop: 1 thenPush: (self fetchPointer: XIndex ofObject: rcvr).
			^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 30.
	argumentCount := 0.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimPointY [

	| rcvr |
	successFlag := true.
	rcvr := self internalStackTop.
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	successFlag
		ifTrue: [self internalPop: 1 thenPush: (self fetchPointer: YIndex ofObject: rcvr).
			^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 31.
	argumentCount := 0.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimSize [
	messageSelector := self specialSelector: 18.
	argumentCount := 0.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimSubtract [
	| rcvr arg result |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg)
		ifTrue: [result := (self integerValueOf: rcvr) - (self integerValueOf: arg).
				(self isIntegerValue: result) ifTrue:
					[self internalPop: 2 thenPush: (self integerObjectOf: result).
					^self fetchNextBytecode "success"]]
		ifFalse: [successFlag := true.
				self externalizeIPandSP.
				self primitiveFloatSubtract: rcvr fromArg: arg.
				self internalizeIPandSP.
				successFlag ifTrue: [^self fetchNextBytecode "success"]].

	messageSelector := self specialSelector: 1.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimValue [
	"In-line value for BlockClosure and BlockContext"
	| maybeBlock rcvrClass |
	maybeBlock := self internalStackTop.
	argumentCount := 0.
	successFlag := true.
	(self isNonIntegerObject: maybeBlock) ifTrue:
		[rcvrClass := self fetchClassOfNonInt: maybeBlock.
		 rcvrClass = (self splObj: ClassBlockClosure)
			ifTrue:
				[self externalizeIPandSP.
				 self primitiveClosureValue.
				 self internalizeIPandSP]
			ifFalse:
				[rcvrClass = (self splObj: ClassBlockContext)
					ifTrue:
						[self externalizeIPandSP.
						 self primitiveValue.
						 self internalizeIPandSP]
					ifFalse:
						[successFlag := false]]].
	successFlag ifFalse:
		[messageSelector := self specialSelector: 25.
		 ^self normalSend].
	self fetchNextBytecode
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimValueWithArg [
	"In-line value: for BlockClosure and BlockContext"
	| maybeBlock rcvrClass |
	maybeBlock := self internalStackValue: 1.
	argumentCount := 1.
	successFlag := true.
	(self isNonIntegerObject: maybeBlock) ifTrue:
		[rcvrClass := self fetchClassOfNonInt: maybeBlock.
		 rcvrClass = (self splObj: ClassBlockClosure)
			ifTrue:
				[self externalizeIPandSP.
				 self primitiveClosureValue.
				 self internalizeIPandSP]
			ifFalse:
				[rcvrClass = (self splObj: ClassBlockContext)
					ifTrue:
						[self externalizeIPandSP.
						 self primitiveValue.
						 self internalizeIPandSP]
					ifFalse:
						[successFlag := false]]].
	successFlag ifFalse:
		[messageSelector := self specialSelector: 26.
		 ^self normalSend].
	self fetchNextBytecode
]

{ #category : #'plugin primitive support' }
Interpreter >> callExternalPrimitive: functionID [
	"Call the external plugin function identified. In the VM this is an address, see 	InterpreterSimulator for it's version. "

	<var: #functionID type: 'void *'>
	self dispatchFunctionPointer: functionID
]

{ #category : #'interpreter shell' }
Interpreter >> callInterpreter [
	"External call into the interpreter"

	<inline: false>
	<export: true>
	self interpret.
]

{ #category : #'callback support' }
Interpreter >> callbackEnter: callbackID [
	"Re-enter the interpreter for executing a callback"
	| result activeProc |
	<export: true>
	<var: #callbackID declareC: 'sqInt *callbackID'>

	"For now, do not allow a callback unless we're in a primitiveResponse"
	primitiveIndex = 0 ifTrue:[^false].

	"Check if we've exceeded the callback depth"
	jmpDepth >= jmpMax ifTrue:[^false].
	jmpDepth := jmpDepth + 1.

	"Suspend the currently active process"
	activeProc := self fetchPointer: ActiveProcessIndex
						 ofObject: self schedulerPointer.
	suspendedCallbacks at: jmpDepth put: activeProc.
	"We need to preserve newMethod explicitly since it is not activated yet
	and therefore no context has been created for it. If the caller primitive
	for any reason decides to fail we need to make sure we execute the correct
	method and not the one 'last used' in the call back"
	suspendedMethods at: jmpDepth put: newMethod.
	self transferTo: self wakeHighestPriority.

	"Typically, invoking the callback means that some semaphore has been 
	signaled to indicate the callback. Force an interrupt check right away."
	self forceInterruptCheck.

	result := self setjmp: (jmpBuf at: jmpDepth).
	result == 0 ifTrue:["Fill in callbackID"
		callbackID at: 0 put: jmpDepth.
		"This is ugly but the inliner treats interpret() in very special and strange ways and calling any kind of 'self interpret' either directly or even via cCode:inSmalltalk: will cause this entire method to vanish."
		self cCode: 'interpret()'.
	].

	"Transfer back to the previous process so that caller can push result"
	activeProc := self fetchPointer: ActiveProcessIndex
						 ofObject: self schedulerPointer.
	self putToSleep: activeProc.
	activeProc := suspendedCallbacks at: jmpDepth.
	newMethod := suspendedMethods at: jmpDepth.	"see comment above"
	self transferTo: activeProc.
	jmpDepth := jmpDepth-1.
	^true
]

{ #category : #'callback support' }
Interpreter >> callbackLeave: cbID [
	"Leave from a previous callback"
	<export: true>

	"For now, do not allow a callback unless we're in a primitiveResponse"
	primitiveIndex = 0 ifTrue:[^false].

	"Check if this is the top-level callback"
	cbID = jmpDepth ifFalse:[^false].
	cbID < 1 ifTrue:[^false].
	"This is ugly but necessary, or otherwise the Mac will not build"
	self long: (jmpBuf at: jmpDepth) jmp: 1.

]

{ #category : #contexts }
Interpreter >> caller [
	^self fetchPointer: CallerIndex ofObject: activeContext
]

{ #category : #'debug support' }
Interpreter >> capturePendingFinalizationSignals [
	statpendingFinalizationSignals := pendingFinalizationSignals.

]

{ #category : #'object access primitives' }
Interpreter >> changeClassOf: rcvr to: argClass [
	"Change the class of the receiver into the class specified by the argument given that the format of the receiver matches the format of the argument. Fail if receiver or argument are SmallIntegers, or the receiver is an instance of a compact class and the argument isn't, or when the argument's class is compact and the receiver isn't, or when the format of the receiver is different from the format of the argument's class, or when the arguments class is fixed and the receiver's size differs from the size that an instance of the argument's class should have."
	| classHdr sizeHiBits byteSize argFormat rcvrFormat ccIndex |
	"Check what the format of the class says"
	classHdr := self formatOfClass: argClass. "Low 2 bits are 0"

	"Compute the size of instances of the class (used for fixed field classes only)"
	sizeHiBits := (classHdr bitAnd: 16r60000) >> 9.
	classHdr := classHdr bitAnd: 16r1FFFF.
	byteSize := (classHdr bitAnd: self sizeMask) + sizeHiBits. "size in bytes -- low 2 bits are 0"

	"Check the receiver's format against that of the class"
	argFormat := (classHdr >> 8) bitAnd: 16rF.
	rcvrFormat := self formatOf: rcvr.
	argFormat = rcvrFormat ifFalse:[^self primitiveFail]. "no way"

	"For fixed field classes, the sizes must match.
	Note: byteSize-4 because base header is included in class size."
	argFormat < 2 ifTrue:[(byteSize - self baseHeaderSize) = (self byteSizeOf: rcvr) ifFalse:[^self primitiveFail]].

	(self headerType: rcvr) = HeaderTypeShort
		ifTrue:[ "Compact classes. Check if the arg's class is compact and exchange ccIndex"
			ccIndex := classHdr bitAnd: CompactClassMask.
			ccIndex = 0 ifTrue:[^self primitiveFail]. "class is not compact"
			self longAt: rcvr put:
				(((self longAt: rcvr) bitAnd: CompactClassMask bitInvert32)
					bitOr: ccIndex)]
		ifFalse:["Exchange the class pointer, which could make rcvr a root for argClass"
			self longAt: rcvr - self baseHeaderSize put: (argClass bitOr: (self headerType: rcvr)).
			(self oop: rcvr isLessThan: youngStart)
				ifTrue: [self possibleRootStoreInto: rcvr value: argClass]].

	"Flush cache because rcvr's class has changed"
	self flushMethodCache.

]

{ #category : #'array primitive support' }
Interpreter >> characterForAscii: ascii [  "Arg must lie in range 0-255!"
	<inline: true>
	^ self fetchPointer: ascii ofObject: (self splObj: CharacterTable)
]

{ #category : #'arithmetic primitive support' }
Interpreter >> checkBooleanResult: result [
	successFlag
		ifTrue: [self pushBool: result]
		ifFalse: [self unPop: 2]
]

{ #category : #'process primitive support' }
Interpreter >> checkForInterrupts [
	"Check for possible interrupts and handle one if necessary."
	| sema now |
	<inline: false>

	"Mask so same wrapping as primitiveMillisecondClock"
	now := self ioMSecs bitAnd: MillisecondClockMask.

	self interruptCheckForced ifFalse: [
		"don't play with the feedback if we forced a check. It only makes life difficult"
		now - lastTick < interruptChecksEveryNms
			ifTrue: ["wrapping is not a concern, it'll get caught quickly  
				enough. This clause is trying to keep a reasonable  
				guess of how many times per 	interruptChecksEveryNms we are calling  
				quickCheckForInterrupts. Not sure how effective it really is."
				interruptCheckCounterFeedBackReset := interruptCheckCounterFeedBackReset + 10]
			ifFalse: [interruptCheckCounterFeedBackReset <= 1000
					ifTrue: [interruptCheckCounterFeedBackReset := 1000]
					ifFalse: [interruptCheckCounterFeedBackReset := interruptCheckCounterFeedBackReset - 12]]].

	"reset the interrupt check counter"
	interruptCheckCounter := interruptCheckCounterFeedBackReset.

	signalLowSpace
		ifTrue: [signalLowSpace := false. "reset flag"
			sema := self splObj: TheLowSpaceSemaphore.
			sema = nilObj ifFalse: [self synchronousSignal: sema]].

	now < lastTick
		ifTrue: ["millisecond clock wrapped so correct the nextPollTick"
			nextPollTick := nextPollTick - MillisecondClockMask - 1].
	now >= nextPollTick
		ifTrue: [self ioProcessEvents.
			"sets interruptPending if interrupt key pressed"
			nextPollTick := now + 200
			"msecs to wait before next call to ioProcessEvents.  
			Note that strictly speaking we might need to update  
			'now' at this point since ioProcessEvents could take a  
			very long time on some platforms"].
	interruptPending
		ifTrue: [interruptPending := false.
			"reset interrupt flag"
			sema := self splObj: TheInterruptSemaphore.
			sema = nilObj
				ifFalse: [self synchronousSignal: sema]].

	nextWakeupTick ~= 0
		ifTrue: [now < lastTick
				ifTrue: ["the clock has wrapped. Subtract the wrap  
					interval from nextWakeupTick - this might just  
					possibly result in 0. Since this is used as a flag  
					value for 'no timer' we do the 0 check above"
					nextWakeupTick := nextWakeupTick - MillisecondClockMask - 1].
			now >= nextWakeupTick
				ifTrue: [nextWakeupTick := 0.
					"set timer interrupt to 0 for 'no timer'"
					sema := self splObj: TheTimerSemaphore.
					sema = nilObj ifFalse: [self synchronousSignal: sema]]].

	"signal any pending finalizations"
	pendingFinalizationSignals > 0
		ifTrue: [sema := self splObj: TheFinalizationSemaphore.
			(self fetchClassOf: sema) = (self splObj: ClassSemaphore)
				ifTrue: [self synchronousSignal: sema].
			pendingFinalizationSignals := 0].

	"signal all semaphores in semaphoresToSignal"
	(semaphoresToSignalCountA > 0 or: [semaphoresToSignalCountB > 0])
		ifTrue: [self signalExternalSemaphores].

	"update the tracking value"
	lastTick := now
]

{ #category : #'image save/restore' }
Interpreter >> checkImageVersionFrom: f startingAt: imageOffset [
	"Read and verify the image file version number and return true if the the given image file needs to be byte-swapped. As a side effect, position the file stream just after the version number of the image header. This code prints a warning and does a hard-exit if it cannot find a valid version number."
	"This code is based on C code by Ian Piumarta."

	| firstVersion |
	<var: #f type: 'sqImageFile '>
	<var: #imageOffset type: 'squeakFileOffsetType '>

	"check the version number"
	self sqImageFile: f Seek: imageOffset.
	imageFormatInitialVersion := firstVersion := self getLongFromFile: f swap: false.
	(self readableFormat: imageFormatInitialVersion) ifTrue: [^ false].

	"try with bytes reversed"
	self sqImageFile: f Seek: imageOffset.
	imageFormatInitialVersion := self getLongFromFile: f swap: true.
	(self readableFormat: imageFormatInitialVersion) ifTrue: [^ true].

	"Note: The following is only meaningful if not reading an embedded image"
	imageOffset = 0 ifTrue:[
		"try skipping the first 512 bytes (prepended by certain Mac file transfer utilities)"
		self sqImageFile: f Seek: 512.
		imageFormatInitialVersion := self getLongFromFile: f swap: false.
		(self readableFormat: imageFormatInitialVersion) ifTrue: [^ false].

		"try skipping the first 512 bytes with bytes reversed"
		self sqImageFile: f Seek: 512.
		imageFormatInitialVersion := self getLongFromFile: f swap: true.
		(self readableFormat: imageFormatInitialVersion) ifTrue: [^ true]].

	"hard failure; abort"
	self print: 'This interpreter (vers. '.
	self printNum: self imageFormatVersion.
	self print: ') cannot read image file (vers. '.
	self printNum: firstVersion.
	self print: ').'.
	self cr.
	self print: 'Press CR to quit...'.
	self getchar.
	self ioExit.

]

{ #category : #'arithmetic primitive support' }
Interpreter >> checkIntegerResult: integerResult [
	(successFlag and: [self isIntegerValue: integerResult])
		ifTrue: [self pushInteger: integerResult]
		ifFalse: [self unPop: 2]
]

{ #category : #utilities }
Interpreter >> checkedIntegerValueOf: intOop [
	"Note: May be called by translated primitive code."

	(self isIntegerObject: intOop)
		ifTrue: [ ^ self integerValueOf: intOop ]
		ifFalse: [ self primitiveFail. ^ 0 ]
]

{ #category : #'plugin primitive support' }
Interpreter >> classNameOf: aClass Is: className [ 
	"Check if aClass's name is className"
	| srcName name length |
	<var: #className type: 'char *'>
	<var: #srcName type: 'char *'>
	(self lengthOf: aClass) <= 6 ifTrue: [^ false].

	"Not a class but might be behavior"
	name := self fetchPointer: 6 ofObject: aClass.
	(self isBytes: name) ifFalse: [^ false].
	length := self stSizeOf: name.
	srcName := self cCoerce: (self arrayValueOf: name) to: 'char *'.
	0 to: length - 1 do: [:i | (srcName at: i) = (className at: i) ifFalse: [^ false]].
	"Check if className really ends at this point"
	^ (className at: length) = 0
]

{ #category : #'control primitives' }
Interpreter >> closureNumArgs: numArgs instructionPointer: initialIP numCopiedValues: numCopied [
	| newClosure |
	<inline: true>
	newClosure := self
					instantiateSmallClass: (self splObj: ClassBlockClosure)
					sizeInBytes: (self bytesPerWord * (ClosureFirstCopiedValueIndex + numCopied)) + self baseHeaderSize.
	"Assume: have just allocated a new closure; it must be young. Thus, can use unchecked stores."
	self storePointerUnchecked: ClosureStartPCIndex ofObject: newClosure withValue: (self integerObjectOf: initialIP).
	self storePointerUnchecked: ClosureNumArgsIndex ofObject: newClosure withValue: (self integerObjectOf: numArgs).
	"It is up to the caller to store the outer context and copiedValues."
	^newClosure
]

{ #category : #'array primitive support' }
Interpreter >> commonAt: stringy [
	"This code is called if the receiver responds primitively to at:.
	If this is so, it will be installed in the atCache so that subsequent calls of at:
	or next may be handled immediately in bytecode primitive routines."
	| index rcvr atIx result |
	index := self positive32BitValueOf: (self stackTop).  "Sets successFlag"
	rcvr := self stackValue: 1.
	successFlag & (self isIntegerObject: rcvr) not
		ifFalse: [^ self primitiveFail].

	"NOTE:  The at-cache, since it is specific to the non-super response to #at:.
	Therefore we must determine that the message is #at: (not, eg, #basicAt:),
	and that the send is not a super-send, before using the at-cache."
	(messageSelector = (self specialSelector: 16)
		and: [lkupClass = (self fetchClassOfNonInt: rcvr)])
		ifTrue:
		["OK -- look in the at-cache"
		atIx := rcvr bitAnd: AtCacheMask.  "Index into atCache = 4N, for N = 0 ... 7"
		(atCache at: atIx+AtCacheOop) = rcvr ifFalse:
			["Rcvr not in cache.  Install it..."
			self install: rcvr inAtCache: atCache at: atIx string: stringy].
		successFlag ifTrue:
			[result := self commonVariable: rcvr at: index cacheIndex: atIx].
		successFlag ifTrue:
			[^ self pop: argumentCount+1 thenPush: result]].

	"The slow but sure way..."
	successFlag := true.
	result := self stObject: rcvr at: index.
	successFlag ifTrue:
		[stringy ifTrue: [result := self characterForAscii: (self integerValueOf: result)].
		^ self pop: argumentCount+1 thenPush: result]
]

{ #category : #'array primitive support' }
Interpreter >> commonAtPut: stringy [
	"This code is called if the receiver responds primitively to at:Put:.
	If this is so, it will be installed in the atPutCache so that subsequent calls of at:
	or  next may be handled immediately in bytecode primitive routines."
	| value index rcvr atIx |
	value := self stackTop.
	index := self positive32BitValueOf: (self stackValue: 1).  "Sets successFlag"
	rcvr := self stackValue: 2.
	successFlag & (self isIntegerObject: rcvr) not
		ifFalse: [^ self primitiveFail].

	"NOTE:  The atPut-cache, since it is specific to the non-super response to #at:Put:.
	Therefore we must determine that the message is #at:Put: (not, eg, #basicAt:Put:),
	and that the send is not a super-send, before using the at-cache."
	(messageSelector = (self specialSelector: 17)
		and: [lkupClass = (self fetchClassOfNonInt: rcvr)])
		ifTrue:
		["OK -- look in the at-cache"
		atIx := (rcvr bitAnd: AtCacheMask) + AtPutBase.  "Index into atPutCache"
		(atCache at: atIx+AtCacheOop) = rcvr ifFalse:
			["Rcvr not in cache.  Install it..."
			self install: rcvr inAtCache: atCache at: atIx string: stringy].
		successFlag ifTrue:
			[self commonVariable: rcvr at: index put: value cacheIndex: atIx].
		successFlag ifTrue:
			[^ self pop: argumentCount+1 thenPush: value]].

	"The slow but sure way..."
	successFlag := true.
	stringy ifTrue: [self stObject: rcvr at: index put: (self asciiOfCharacter: value)]
			ifFalse: [self stObject: rcvr at: index put: value].
	successFlag ifTrue: [^ self pop: argumentCount+1 thenPush: value].

]

{ #category : #'return bytecodes' }
Interpreter >> commonReturn [
	"Note: Assumed to be inlined into the dispatch loop."

	| nilOop thisCntx contextOfCaller localCntx localVal unwindMarked |
	<inline: true>
	self sharedCodeNamed: 'commonReturn' inCase: 120.

	nilOop := nilObj. "keep in a register"
	thisCntx := activeContext.
	localCntx := localReturnContext.
	localVal := localReturnValue.

	"make sure we can return to the given context"
	((localCntx = nilOop) or:
	 [(self fetchPointer: InstructionPointerIndex ofObject: localCntx) = nilOop]) ifTrue: [
		"error: sender's instruction pointer or context is nil; cannot return"
		^self internalCannotReturn: localVal].

	"If this return is not to our immediate predecessor (i.e. from a method to its sender, or from a block to its caller), scan the stack for the first unwind marked context and inform this context and let it deal with it. This provides a chance for ensure unwinding to occur."
	thisCntx := self fetchPointer: SenderIndex ofObject: activeContext.

	"Just possibly a faster test would be to compare the homeContext and activeContext - they are of course different for blocks. Thus we might be able to optimise a touch by having a different returnTo for the blockreteurn (since we know that must return to caller) and then if active ~= home we must be doing a non-local return. I think. Maybe."
	[thisCntx = localCntx] whileFalse: [
		thisCntx = nilOop ifTrue:[
			"error: sender's instruction pointer or context is nil; cannot return"
			^self internalCannotReturn: localVal].
		"Climb up stack towards localCntx. Break out to a send of #aboutToReturn:through: if an unwind marked context is found"
		unwindMarked := self isUnwindMarked: thisCntx.
		unwindMarked ifTrue:[
			"context is marked; break out"
			^self internalAboutToReturn: localVal through: thisCntx].
		thisCntx := self fetchPointer: SenderIndex ofObject: thisCntx.
 ].

	"If we get here there is no unwind to worry about. Simply terminate the stack up to the localCntx - often just the sender of the method"
	thisCntx := activeContext.
	[thisCntx = localCntx]
		whileFalse:
		["climb up stack to localCntx"
		contextOfCaller := self fetchPointer: SenderIndex ofObject: thisCntx.

		"zap exited contexts so any future attempted use will be caught"
		self storePointerUnchecked: SenderIndex ofObject: thisCntx withValue: nilOop.
		self storePointerUnchecked: InstructionPointerIndex ofObject: thisCntx withValue: nilOop.
		reclaimableContextCount > 0 ifTrue:
			["try to recycle this context"
			reclaimableContextCount := reclaimableContextCount - 1.
			self recycleContextIfPossible: thisCntx].
		thisCntx := contextOfCaller].

	activeContext := thisCntx.
	(self oop: thisCntx isLessThan: youngStart) ifTrue: [ self beRootIfOld: thisCntx ].

	self internalFetchContextRegisters: thisCntx.  "updates local IP and SP"
	self fetchNextBytecode.
	self internalPush: localVal.

]

{ #category : #'message sending' }
Interpreter >> commonSend [
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that 
	the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	self sharedCodeNamed: 'commonSend' inCase: 131.
	self internalFindNewMethod.
	self internalExecuteNewMethod.
	self fetchNextBytecode
]

{ #category : #'array primitive support' }
Interpreter >> commonVariable: rcvr at: index cacheIndex: atIx [ 
	"This code assumes the receiver has been identified at location atIx in the atCache."
	| stSize fmt fixedFields result |

	stSize := atCache at: atIx+AtCacheSize.
	((self oop: index isGreaterThanOrEqualTo: 1)
		and: [self oop: index isLessThanOrEqualTo: stSize])
	ifTrue:
		[fmt := atCache at: atIx+AtCacheFmt.
		fmt <= 4 ifTrue:
			[fixedFields := atCache at: atIx+AtCacheFixedFields.
			^ self fetchPointer: index + fixedFields - 1 ofObject: rcvr].
		fmt < 8 ifTrue:  "Bitmap"
			[result := self fetchLong32: index - 1 ofObject: rcvr.
			result := self positive32BitIntegerFor: result.
			^ result].
		fmt >= 16  "Note fmt >= 16 is an artificial flag for strings"
			ifTrue: "String"
			[^ self characterForAscii: (self fetchByte: index - 1 ofObject: rcvr)]
			ifFalse: "ByteArray"
			[^ self integerObjectOf: (self fetchByte: index - 1 ofObject: rcvr)]].

	self primitiveFail
]

{ #category : #'array primitive support' }
Interpreter >> commonVariable: rcvr at: index put: value cacheIndex: atIx [
	"This code assumes the receiver has been identified at location atIx in the atCache."
	| stSize fmt fixedFields valToPut |
	<inline: true>

	stSize := atCache at: atIx+AtCacheSize.
	((self oop: index isGreaterThanOrEqualTo: 1)
		and: [self oop: index isLessThanOrEqualTo: stSize])
	ifTrue:
		[fmt := atCache at: atIx+AtCacheFmt.
		fmt <= 4 ifTrue:
			[fixedFields := atCache at: atIx+AtCacheFixedFields.
			^ self storePointer: index + fixedFields - 1 ofObject: rcvr withValue: value].
		fmt < 8 ifTrue:  "Bitmap"
			[valToPut := self positive32BitValueOf: value.
			successFlag ifTrue: [self storeLong32: index - 1 ofObject: rcvr withValue: valToPut].
			^ nil].
		fmt >= 16  "Note fmt >= 16 is an artificial flag for strings"
			ifTrue: [valToPut := self asciiOfCharacter: value.
					successFlag ifFalse: [^ nil]]
			ifFalse: [valToPut := value].
		(self isIntegerObject: valToPut) ifTrue:
			[valToPut := self integerValueOf: valToPut.
			((valToPut >= 0) and: [valToPut <= 255]) ifFalse: [^ self primitiveFail].
			^ self storeByte: index - 1 ofObject: rcvr withValue: valToPut]].

	self primitiveFail
]

{ #category : #'array primitive support' }
Interpreter >> commonVariableInternal: rcvr at: index cacheIndex: atIx [ 
	"This code assumes the receiver has been identified at location atIx in the atCache."
	| stSize fmt fixedFields result |
	<inline: true>

	stSize := atCache at: atIx+AtCacheSize.
	((self oop: index isGreaterThanOrEqualTo: 1)
		and: [self oop: index isLessThanOrEqualTo: stSize])
	ifTrue:
		[fmt := atCache at: atIx+AtCacheFmt.
		fmt <= 4 ifTrue:
			[fixedFields := atCache at: atIx+AtCacheFixedFields.
			^ self fetchPointer: index + fixedFields - 1 ofObject: rcvr].
		fmt < 8 ifTrue:  "Bitmap"
			[result := self fetchLong32: index - 1 ofObject: rcvr.
			self externalizeIPandSP.
			result := self positive32BitIntegerFor: result.
			self internalizeIPandSP.
			^ result].
		fmt >= 16  "Note fmt >= 16 is an artificial flag for strings"
			ifTrue: "String"
			[^ self characterForAscii: (self fetchByte: index - 1 ofObject: rcvr)]
			ifFalse: "ByteArray"
			[^ self integerObjectOf: (self fetchByte: index - 1 ofObject: rcvr)]].

	self primitiveFail
]

{ #category : #'arithmetic primitive support' }
Interpreter >> compare31or32Bits: obj1 equal: obj2 [
	"May set success to false"

	"First compare two ST integers..."
	((self isIntegerObject: obj1)
		and: [self isIntegerObject: obj2])
		ifTrue: [^ obj1 = obj2].

	"Now compare, assuming positive integers, but setting fail if not"
	^ (self positive32BitValueOf: obj1) = (self positive32BitValueOf: obj2)
]

{ #category : #'compiler support' }
Interpreter >> compilerCreateActualMessage: aMessage storingArgs: argArray [
	^self cCode: 'compilerHooks[14](aMessage, argArray)'
]

{ #category : #'compiler support' }
Interpreter >> compilerFlushCache: aCompiledMethod [
	^self cCode: 'compilerHooks[2](aCompiledMethod)'
]

{ #category : #'compiler support' }
Interpreter >> compilerFlushCacheHook: aCompiledMethod [
	<inline: true>
	compilerInitialized ifTrue: [self compilerFlushCache: aCompiledMethod]
]

{ #category : #'compiler support' }
Interpreter >> compilerMapFrom: memStart to: memEnd [
	^self cCode: 'compilerHooks[4](memStart, memEnd)'
]

{ #category : #'compiler support' }
Interpreter >> compilerMapHookFrom: memStart to: memEnd [
	<inline: true>
	compilerInitialized ifTrue: [self compilerMapFrom: memStart to: memEnd]
]

{ #category : #'compiler support' }
Interpreter >> compilerMark [
	^self cCode: 'compilerHooks[9]()'
]

{ #category : #'compiler support' }
Interpreter >> compilerMarkHook [
	<inline: true>
	compilerInitialized ifTrue: [self compilerMark]
]

{ #category : #'compiler support' }
Interpreter >> compilerPostGC [
	^self cCode: 'compilerHooks[5]()'
]

{ #category : #'compiler support' }
Interpreter >> compilerPostGCHook [
	<inline: true>
	compilerInitialized ifTrue: [self compilerPostGC]
]

{ #category : #'compiler support' }
Interpreter >> compilerPostSnapshot [
	^self cCode: 'compilerHooks[8]()'
]

{ #category : #'compiler support' }
Interpreter >> compilerPostSnapshotHook [
	<inline: true>
	compilerInitialized ifTrue: [self compilerPostSnapshot]
]

{ #category : #'compiler support' }
Interpreter >> compilerPreGC: fullGCFlag [
	^self cCode: 'compilerHooks[3](fullGCFlag)'
]

{ #category : #'compiler support' }
Interpreter >> compilerPreGCHook: fullGCFlag [
	<inline: true>
	compilerInitialized ifTrue: [self compilerPreGC: fullGCFlag]
]

{ #category : #'compiler support' }
Interpreter >> compilerPreSnapshot [
	^self cCode: 'compilerHooks[7]()'
]

{ #category : #'compiler support' }
Interpreter >> compilerPreSnapshotHook [
	<inline: true>
	compilerInitialized ifTrue: [self compilerPreSnapshot]
]

{ #category : #'compiler support' }
Interpreter >> compilerProcessChange [
	^self cCode: 'compilerHooks[6]()'
]

{ #category : #'compiler support' }
Interpreter >> compilerProcessChange: oldProc to: newProc [
	^self cCode: 'compilerHooks[6](oldProc, newProc)'
]

{ #category : #'compiler support' }
Interpreter >> compilerProcessChangeHook [
	<inline: true>
	compilerInitialized ifTrue: [self compilerProcessChange]
]

{ #category : #'compiler support' }
Interpreter >> compilerTranslateMethod [
	^self cCode: 'compilerHooks[1]()'
]

{ #category : #'compiler support' }
Interpreter >> compilerTranslateMethodHook [
	<inline: true>
	^compilerInitialized and: [self compilerTranslateMethod]
]

{ #category : #contexts }
Interpreter >> context: thisCntx hasSender: aContext [ 
	"Does thisCntx have aContext in its sender chain?"
	| s nilOop |
	<inline: true>
	thisCntx == aContext ifTrue: [^false].
	nilOop := nilObj.
	s := self fetchPointer: SenderIndex ofObject: thisCntx.
	[s == nilOop]
		whileFalse: [s == aContext ifTrue: [^true].
			s := self fetchPointer: SenderIndex ofObject: s].
	^false
]

{ #category : #'bitblt support' }
Interpreter >> copyBits [
	"This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin:=copyBits
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided"

	| fn |
	<var: #fn type: 'void *'>
	fn := self ioLoadFunction: 'copyBits' From: 'BitBltPlugin'.
	fn = 0 ifTrue: [^self primitiveFail].
	^self cCode: '((sqInt (*)(void))fn)()'
]

{ #category : #'bitblt support' }
Interpreter >> copyBitsFrom: x0 to: x1 at: y [
	"This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin:=copyBitsFrom:to:at:
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided"

	| fn |
	<var: #fn type: 'void *'>
	fn := self ioLoadFunction: 'copyBitsFromtoat' From: 'BitBltPlugin'.
	fn = 0 ifTrue: [^self primitiveFail].
	^self cCode: '((sqInt (*)(sqInt, sqInt, sqInt))fn)(x0, x1, y)'
]

{ #category : #'image segment in/out' }
Interpreter >> copyObj: oop toSegment: segmentWordArray addr: lastSeg stopAt: stopAddr saveOopAt: oopPtr headerAt: hdrPtr [
	"Copy this object into the segment beginning at lastSeg.
	Install a forwarding pointer, and save oop and header.
	Fail if out of space.  Return the next segmentAddr if successful."

	"Copy the object..."
	| extraSize bodySize hdrAddr |
	self flag: #Dan.  "None of the imageSegment stuff has been updated for 64 bits"
	successFlag ifFalse: [^ lastSeg].
	extraSize := self extraHeaderBytes: oop.
	bodySize := self sizeBitsOf: oop.
	(self oop: (lastSeg + extraSize + bodySize) isGreaterThanOrEqualTo: stopAddr)
		ifTrue: [^ self primitiveFail].
	self transfer: extraSize + bodySize // self bytesPerWord  "wordCount"
		from: oop - extraSize
		to: lastSeg + self bytesPerWord.

	"Clear root and mark bits of all headers copied into the segment"
	hdrAddr := lastSeg + self bytesPerWord + extraSize.
	self longAt: hdrAddr put: ((self longAt: hdrAddr) bitAnd: self allButRootBit - self markBit).

	self forward: oop to: (lastSeg + self bytesPerWord + extraSize - segmentWordArray)
		savingOopAt: oopPtr andHeaderAt: hdrPtr.

	"Return new end of segment"
	^ lastSeg + extraSize + bodySize
]

{ #category : #'debug printing' }
Interpreter >> cr [
	"For testing in Smalltalk, this method should be overridden in a subclass."

	self printf: '\n'.
]

{ #category : #'message sending' }
Interpreter >> createActualMessageTo: aClass [ 
	"Bundle up the selector, arguments and lookupClass into a Message object. 
	In the process it pops the arguments off the stack, and pushes the message object. 
	This can then be presented as the argument of e.g. #doesNotUnderstand:. 
	ikp 11/20/1999 03:59 -- added hook for external runtime compilers."
	"remap lookupClass in case GC happens during allocation"
	| argumentArray message lookupClass |
	self pushRemappableOop: aClass.
	argumentArray := self instantiateClass: (self splObj: ClassArray) indexableSize: argumentCount.
	"remap argumentArray in case GC happens during allocation"
	self pushRemappableOop: argumentArray.
	message := self instantiateClass: (self splObj: ClassMessage) indexableSize: 0.
	argumentArray := self popRemappableOop.
	lookupClass := self popRemappableOop.
	self beRootIfOld: argumentArray.

	compilerInitialized
		ifTrue: [self compilerCreateActualMessage: message storingArgs: argumentArray]
		ifFalse: [self transfer: argumentCount from: stackPointer - (argumentCount - 1 * self bytesPerWord) to: argumentArray + self baseHeaderSize.
			self pop: argumentCount thenPush: message].

	argumentCount := 1.
	self storePointer: MessageSelectorIndex ofObject: message withValue: messageSelector.
	self storePointer: MessageArgumentsIndex ofObject: message withValue: argumentArray.
	(self lastPointerOf: message) >= (MessageLookupClassIndex * self bytesPerWord + self baseHeaderSize)
		ifTrue: ["Only store lookupClass if message has 3 fields (old images don't)"
			self storePointer: MessageLookupClassIndex ofObject: message withValue: lookupClass]
]

{ #category : #'compiler support' }
Interpreter >> disableCompiler [
	compilerInitialized := false
]

{ #category : #'message sending' }
Interpreter >> dispatchFunctionPointer: aFunctionPointer [

	<var: #aFunctionPointer type: 'void *'>
	self cCode: '((void (*)(void))aFunctionPointer)()'
			inSmalltalk: [self error: 'my simulator should simulate me']
]

{ #category : #'message sending' }
Interpreter >> dispatchFunctionPointerOn: primIdx in: primTable [
	"Call the primitive at index primIdx in the primitiveTable."

	<var: #primTable declareC: 'void *primTable[]'>
	^self dispatchFunctionPointer: (primTable at: primIdx)
]

{ #category : #'I/O primitives' }
Interpreter >> displayBitsOf: aForm Left: l Top: t Right: r Bottom: b [
	"Repaint the portion of the Smalltalk screen bounded by the affected rectangle. Used to synchronize the screen after a Bitblt to the Smalltalk Display object."

	| displayObj dispBits w h dispBitsIndex d left right top bottom surfaceHandle |
	displayObj := self splObj: TheDisplay.
	aForm = displayObj ifFalse: [^ nil].
	self success: ((self isPointers: displayObj) and: [(self lengthOf: displayObj) >= 4]).
	successFlag ifTrue: [
		dispBits := self fetchPointer: 0 ofObject: displayObj.
		w := self fetchInteger: 1 ofObject: displayObj.
		h := self fetchInteger: 2 ofObject: displayObj.
		d := self fetchInteger: 3 ofObject: displayObj.
	].
	l < 0 ifTrue:[left := 0] ifFalse: [left := l].
	r > w ifTrue: [right := w] ifFalse: [right := r].
	t < 0 ifTrue: [top := 0] ifFalse: [top := t].
	b > h ifTrue: [bottom := h] ifFalse: [bottom := b].
	((left <= right) and: [top <= bottom]) ifFalse: [^nil].
	successFlag ifTrue: [
		(self isIntegerObject: dispBits) ifTrue: [
			surfaceHandle := self integerValueOf: dispBits.
			showSurfaceFn = 0 ifTrue: [
				showSurfaceFn := self ioLoadFunction: 'ioShowSurface' From: 'SurfacePlugin'.
				showSurfaceFn = 0 ifTrue: [^self success: false]].
			self cCode:'((sqInt (*)(sqInt, sqInt, sqInt, sqInt, sqInt))showSurfaceFn)(surfaceHandle, left, top, right-left, bottom-top)'.
		] ifFalse: [
			dispBitsIndex := dispBits + self baseHeaderSize.  "index in memory byte array"
			self cCode: 'ioShowDisplay(dispBitsIndex, w, h, d, left, right, top, bottom)'
				inSmalltalk: [self showDisplayBits: dispBitsIndex 
								w: w h: h d: d
								left: left right: right top: top bottom: bottom]
		].
	].
]

{ #category : #'arithmetic primitive support' }
Interpreter >> doPrimitiveDiv: rcvr by: arg [
	"Rounds negative results towards negative infinity, rather than zero."
	| result posArg posRcvr integerRcvr integerArg |
	(self areIntegers: rcvr and: arg)
		ifTrue: [integerRcvr := self integerValueOf: rcvr.
				integerArg := self integerValueOf: arg.
				self success: integerArg ~= 0]
		ifFalse: [self primitiveFail].
	successFlag ifFalse: [^ 1 "fail"].

	integerRcvr > 0
		ifTrue: [integerArg > 0
					ifTrue: [result := integerRcvr // integerArg]
					ifFalse: ["round negative result toward negative infinity"
							posArg := 0 - integerArg.
							result := 0 - ((integerRcvr + (posArg - 1)) // posArg)]]
		ifFalse: [posRcvr := 0 - integerRcvr.
				integerArg > 0
					ifTrue: ["round negative result toward negative infinity"
							result := 0 - ((posRcvr + (integerArg - 1)) // integerArg)]
					ifFalse: [posArg := 0 - integerArg.
							result := posRcvr // posArg]].
	self success: (self isIntegerValue: result).
	^ result
]

{ #category : #'arithmetic primitive support' }
Interpreter >> doPrimitiveMod: rcvr by: arg [
	| integerResult integerRcvr integerArg |
	(self areIntegers: rcvr and: arg)
		ifTrue: [integerRcvr := self integerValueOf: rcvr.
				integerArg := self integerValueOf: arg.
				self success: integerArg ~= 0]
		ifFalse: [self primitiveFail].
	successFlag ifFalse: [^ 1 "fail"].

	integerResult := integerRcvr \\ integerArg.

	"ensure that the result has the same sign as the integerArg"
	integerArg < 0
		ifTrue: [integerResult > 0
			ifTrue: [integerResult := integerResult + integerArg]]
		ifFalse: [integerResult < 0
			ifTrue: [integerResult := integerResult + integerArg]].
	self success: (self isIntegerValue: integerResult).
	^ integerResult

]

{ #category : #'send bytecodes' }
Interpreter >> doubleExtendedDoAnythingBytecode [
	"Replaces the Blue Book double-extended send [132], in which the first byte was wasted on 8 bits of argument count. 
	Here we use 3 bits for the operation sub-type (opType),  and the remaining 5 bits for argument count where needed. 
	The last byte give access to 256 instVars or literals. 
	See also secondExtendedSendBytecode"
	| byte2 byte3 opType top |
	byte2 := self fetchByte.
	byte3 := self fetchByte.
	opType := byte2 >> 5.
	opType = 0 ifTrue: [messageSelector := self literal: byte3.
			argumentCount := byte2 bitAnd: 31.
			^ self normalSend].
	opType = 1 ifTrue: [messageSelector := self literal: byte3.
			argumentCount := byte2 bitAnd: 31.
			^ self superclassSend].
	self fetchNextBytecode.
	opType = 2 ifTrue: [^ self pushReceiverVariable: byte3].
	opType = 3 ifTrue: [^ self pushLiteralConstant: byte3].
	opType = 4 ifTrue: [^ self pushLiteralVariable: byte3].
	opType = 5 ifTrue: [top := self internalStackTop.
			^ self storePointer: byte3 ofObject: receiver withValue: top].
	opType = 6
		ifTrue: [top := self internalStackTop.
			self internalPop: 1.
			^ self storePointer: byte3 ofObject: receiver withValue: top].
	opType = 7
		ifTrue: [top := self internalStackTop.
			^ self storePointer: ValueIndex ofObject: (self literal: byte3) withValue: top]
]

{ #category : #initialization }
Interpreter >> dummyReferToProxy [
	<inline: false>
	interpreterProxy := interpreterProxy
]

{ #category : #'image save/restore' }
Interpreter >> dumpImage: fileName [
	"Dump the entire image out to the given file. Intended for debugging only."
	| f dataSize result |
	<export: true>
	<var: #fileName type: 'char *'>
	<var: #f type: 'sqImageFile'>

	f := self cCode: 'sqImageFileOpen(fileName, "wb")'.
	f = nil ifTrue: [^-1].
	dataSize := endOfMemory - self startOfMemory.
	result := self cCode: 'sqImageFileWrite(pointerForOop(memory), sizeof(unsigned char), dataSize, f)'.
	self cCode: 'sqImageFileClose(f)'.
	^result

]

{ #category : #'stack bytecodes' }
Interpreter >> duplicateTopBytecode [

	self fetchNextBytecode.
	self internalPush: self internalStackTop.

]

{ #category : #'compiler support' }
Interpreter >> enableCompiler [
	"Calling this before loading the compiler will provoke a nullCompilerHook error"

	compilerInitialized := true
]

{ #category : #'message sending' }
Interpreter >> executeNewMethod [
	"execute a method not found in the mCache - which means that 
	primitiveIndex must be manually set. Used by primitiveClosureValue & primitiveExecuteMethod, where no lookup is previously done"
	primitiveIndex > 0
		ifTrue: [self primitiveResponse.
			successFlag ifTrue: [^ nil]].
	"if not primitive, or primitive failed, activate the method"
	self activateNewMethod.
	"check for possible interrupts at each real send"
	self quickCheckForInterrupts
]

{ #category : #'message sending' }
Interpreter >> executeNewMethodFromCache [
	"execute a method found in the mCache - which means that 
	primitiveIndex & primitiveFunctionPointer are already set. Any sender 
	needs to have previously sent findMethodInClass: or equivalent"
	| nArgs delta |
	primitiveIndex > 0
		ifTrue: [DoBalanceChecks ifTrue: ["check stack balance"
					nArgs := argumentCount.
					delta := stackPointer - activeContext].
			successFlag := true.
			self dispatchFunctionPointer: primitiveFunctionPointer.
			"branch direct to prim function from address stored in mcache"
			DoBalanceChecks
				ifTrue: [(self balancedStack: delta afterPrimitive: primitiveIndex withArgs: nArgs)
						ifFalse: [self printUnbalancedStack: primitiveIndex]].
			successFlag ifTrue: [^ nil]].
	"if not primitive, or primitive failed, activate the method"
	self activateNewMethod.
	"check for possible interrupts at each real send"
	self quickCheckForInterrupts
]

{ #category : #'stack bytecodes' }
Interpreter >> extendedPushBytecode [

	| descriptor variableType variableIndex |
	descriptor := self fetchByte.
	self fetchNextBytecode.
	variableType := (descriptor >> 6) bitAnd: 16r3.
	variableIndex := descriptor bitAnd: 16r3F.
	variableType=0 ifTrue: [^self pushReceiverVariable: variableIndex].
	variableType=1 ifTrue: [^self pushTemporaryVariable: variableIndex].
	variableType=2 ifTrue: [^self pushLiteralConstant: variableIndex].
	variableType=3 ifTrue: [^self pushLiteralVariable: variableIndex].

]

{ #category : #'stack bytecodes' }
Interpreter >> extendedStoreAndPopBytecode [

	self extendedStoreBytecode.
	self internalPop: 1.

]

{ #category : #'stack bytecodes' }
Interpreter >> extendedStoreBytecode [
	| descriptor variableType variableIndex association |
	<inline: true>
	descriptor := self fetchByte.
	self fetchNextBytecode.
	variableType := descriptor >> 6 bitAnd: 3.
	variableIndex := descriptor bitAnd: 63.
	variableType = 0
		ifTrue: [^ self storePointer: variableIndex ofObject: receiver withValue: self internalStackTop].
	variableType = 1
		ifTrue: [^ self storePointerUnchecked: variableIndex + TempFrameStart ofObject: localHomeContext withValue: self internalStackTop].
	variableType = 2
		ifTrue: [self error: 'illegal store'].
	variableType = 3
		ifTrue: [association := self literal: variableIndex.
			^ self storePointer: ValueIndex ofObject: association withValue: self internalStackTop]
]

{ #category : #utilities }
Interpreter >> externalizeIPandSP [
	"Copy the local instruction and stack pointer to global variables for use in primitives and other functions outside the interpret loop."

	instructionPointer := self oopForPointer: localIP.
	stackPointer := self oopForPointer: localSP.
	theHomeContext := localHomeContext.

]

{ #category : #'primitive support' }
Interpreter >> failed [

	^successFlag not
]

{ #category : #utilities }
Interpreter >> fetchArray: fieldIndex ofObject: objectPointer [
	"Fetch the instance variable at the given index of the given object. Return the address of first indexable field of resulting array object, or fail if the instance variable does not contain an indexable bytes or words object."
	"Note: May be called by translated primitive code."

	| arrayOop |
	<returnTypeC: 'void *'>
	arrayOop := self fetchPointer: fieldIndex ofObject: objectPointer.
	^ self arrayValueOf: arrayOop

]

{ #category : #'interpreter shell' }
Interpreter >> fetchByte [
	"This method uses the preIncrement builtin function which has no Smalltalk equivalent. Thus, it must be overridden in the simulator."

	^ self byteAtPointer: localIP preIncrement
]

{ #category : #contexts }
Interpreter >> fetchContextRegisters: activeCntx [ 
	"Note: internalFetchContextRegisters: should track changes  to this method."
	| tmp |
	<inline: true>
	tmp := self fetchPointer: MethodIndex ofObject: activeCntx.
	(self isIntegerObject: tmp)
		ifTrue: ["if the MethodIndex field is an integer, activeCntx is a block context"
			tmp := self fetchPointer: HomeIndex ofObject: activeCntx.
			(self oop: tmp isLessThan: youngStart) ifTrue: [self beRootIfOld: tmp]]
		ifFalse: ["otherwise, it is a method context and is its own home context "
			tmp := activeCntx].
	theHomeContext := tmp.
	receiver := self fetchPointer: ReceiverIndex ofObject: tmp.
	method := self fetchPointer: MethodIndex ofObject: tmp.

	"the instruction pointer is a pointer variable equal to 
	method oop + ip + self baseHeaderSize 
	-1 for 0-based addressing of fetchByte 
	-1 because it gets incremented BEFORE fetching currentByte "
	tmp := self quickFetchInteger: InstructionPointerIndex ofObject: activeCntx.
	instructionPointer := method + tmp + self baseHeaderSize - 2.

	"the stack pointer is a pointer variable also..."
	tmp := self quickFetchInteger: StackPointerIndex ofObject: activeCntx.
	stackPointer := activeCntx + self baseHeaderSize + (TempFrameStart + tmp - 1 * self bytesPerWord)
]

{ #category : #utilities }
Interpreter >> fetchFloat: fieldIndex ofObject: objectPointer [
	"Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float."
	"Note: May be called by translated primitive code."

	| floatOop |
	<returnTypeC: 'double'>
	floatOop := self fetchPointer: fieldIndex ofObject: objectPointer.
	^ self floatValueOf: floatOop
]

{ #category : #utilities }
Interpreter >> fetchInteger: fieldIndex ofObject: objectPointer [
	"Note: May be called by translated primitive code."

	| intOop |
	<inline: false>
	intOop := self fetchPointer: fieldIndex ofObject: objectPointer.
	^self checkedIntegerValueOf: intOop
]

{ #category : #utilities }
Interpreter >> fetchIntegerOrTruncFloat: fieldIndex ofObject: objectPointer [
	"Return the integer value of the given field of the given object. If the field contains a Float, truncate it and return its integral part. Fail if the given field does not contain a small integer or Float, or if the truncated Float is out of the range of small integers."
	"Note: May be called by translated primitive code."

	| intOrFloat floatVal frac trunc |
	<inline: false>
	<var: #floatVal type: 'double '>
	<var: #frac type: 'double '>
	<var: #trunc type: 'double '>

	intOrFloat := self fetchPointer: fieldIndex ofObject: objectPointer.
	(self isIntegerObject: intOrFloat) ifTrue: [^ self integerValueOf: intOrFloat].
	self assertClassOf: intOrFloat is: (self splObj: ClassFloat).
	successFlag ifTrue: [
		self cCode: '' inSmalltalk: [floatVal := Float new: 2].
		self fetchFloatAt: intOrFloat + self baseHeaderSize into: floatVal.
		self cCode: 'frac = modf(floatVal, &trunc)'.
		"the following range check is for C ints, with range -2^31..2^31-1"
		self flag: #Dan.		"The ranges are INCORRECT if SmallIntegers are wider than 31 bits."
		self cCode: 'success((-2147483648.0 <= trunc) && (trunc <= 2147483647.0))'.].
	successFlag
		ifTrue: [^ self cCode: '((sqInt) trunc)' inSmalltalk: [floatVal truncated]]
		ifFalse: [^ 0].

]

{ #category : #'interpreter shell' }
Interpreter >> fetchNextBytecode [
	"This method fetches the next instruction (bytecode). Each bytecode method is responsible for fetching the next bytecode, preferably as early as possible to allow the memory system time to process the request before the next dispatch."

	currentBytecode := self fetchByte.

]

{ #category : #contexts }
Interpreter >> fetchStackPointerOf: aContext [
	"Return the stackPointer of a Context or BlockContext."
	| sp |
	<inline: true>
	sp := self fetchPointer: StackPointerIndex ofObject: aContext.
	(self isIntegerObject: sp) ifFalse: [^0].
	^self integerValueOf: sp
]

{ #category : #'debug support' }
Interpreter >> findClassOfMethod: meth forReceiver: rcvr [

	| currClass classDict classDictSize methodArray i done |
	currClass := self fetchClassOf: rcvr.
	done := false.
	[done] whileFalse: [
		classDict := self fetchPointer: MessageDictionaryIndex ofObject: currClass.
		classDictSize := self fetchWordLengthOf: classDict.
		methodArray := self fetchPointer: MethodArrayIndex ofObject: classDict.
		i := 0.
		[i < (classDictSize - SelectorStart)] whileTrue: [
			meth = (self fetchPointer: i ofObject: methodArray) ifTrue: [ ^currClass ].
			i := i + 1.
		].
		currClass := self fetchPointer: SuperclassIndex ofObject: currClass.
		done := currClass = nilObj.
	].
	^self fetchClassOf: rcvr    "method not found in superclass chain"
]

{ #category : #'message sending' }
Interpreter >> findNewMethodInClass: class [ 
	"Find the compiled method to be run when the current 
	messageSelector is sent to the given class, setting the values 
	of 'newMethod' and 'primitiveIndex'."
	| ok |
	<inline: false>
	ok := self lookupInMethodCacheSel: messageSelector class: class.
	ok
		ifFalse: ["entry was not found in the cache; look it up the hard way "
			self lookupMethodInClass: class.
			lkupClass := class.
			self addNewMethodToCache]
]

{ #category : #'debug support' }
Interpreter >> findSelectorOfMethod: meth forReceiver: rcvr [

	| currClass done classDict classDictSize methodArray i |
	currClass := self fetchClassOf: rcvr.
	done := false.
	[done] whileFalse: [
		classDict := self fetchPointer: MessageDictionaryIndex ofObject: currClass.
		classDictSize := self fetchWordLengthOf: classDict.
		methodArray := self fetchPointer: MethodArrayIndex ofObject: classDict.
		i := 0.
		[i <= (classDictSize - SelectorStart)] whileTrue: [
			meth = (self fetchPointer: i ofObject: methodArray) ifTrue: [
				^(self fetchPointer: i + SelectorStart ofObject: classDict)
			].
			i := i + 1.
		].
		currClass := self fetchPointer: SuperclassIndex ofObject: currClass.
		done := currClass = nilObj.
	].
	^ nilObj    "method not found in superclass chain"
]

{ #category : #'plugin support' }
Interpreter >> firstFixedField: oop [

	<returnTypeC: 'char *'>
	^ self pointerForOop: oop + self baseHeaderSize
]

{ #category : #'plugin support' }
Interpreter >> firstIndexableField: oop [
	"NOTE: copied in InterpreterSimulator, so please duplicate any changes"

	| hdr fmt totalLength fixedFields |
	<returnTypeC: 'char *'>
	hdr := self baseHeader: oop.
	fmt := (hdr >> 8) bitAnd: 16rF.
	totalLength := self lengthOf: oop baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: oop format: fmt length: totalLength.
	fmt < 8 ifTrue:
		[fmt = 6 ifTrue:
			["32 bit field objects"
			^ self pointerForOop: oop + self baseHeaderSize + (fixedFields << 2)].
		"full word objects (pointer or bits)"
		^ self pointerForOop: oop + self baseHeaderSize + (fixedFields << self shiftForWord)]
	ifFalse:
		["Byte objects"
		^ self pointerForOop: oop + self baseHeaderSize + fixedFields]
]

{ #category : #'object format' }
Interpreter >> fixedFieldsOf: oop format: fmt length: wordLength [
"
	NOTE: This code supports the backward-compatible extension to 8 bits of instSize.
	When we revise the image format, it should become...
	^ (classFormat >> 2 bitAnd: 16rFF) - 1
"
	| class classFormat |
	<inline: true>
	((fmt > 4) or: [fmt = 2]) ifTrue: [^ 0].  "indexable fields only"
	fmt < 2 ifTrue: [^ wordLength].  "fixed fields only (zero or more)"
	
	"fmt = 3 or 4: mixture of fixed and indexable fields, so must look at class format word"
	class := self fetchClassOf: oop.
	classFormat := self formatOfClass: class.
	^ (classFormat >> 11 bitAnd: 16rC0) + (classFormat >> 2 bitAnd: 16r3F) - 1

]

{ #category : #'object format' }
Interpreter >> floatObjectOf: aFloat [
	| newFloatObj |
	<var: #aFloat type: 'double '>
self flag: #Dan.
	newFloatObj := self instantiateSmallClass: (self splObj: ClassFloat) sizeInBytes: 8 + self baseHeaderSize.
	self storeFloatAt: newFloatObj + self baseHeaderSize from: aFloat.
	^ newFloatObj.

]

{ #category : #utilities }
Interpreter >> floatValueOf: oop [
	"Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float."
	"Note: May be called by translated primitive code."

	| result |
	<returnTypeC: 'double'>
	<var: #result type: 'double '>
	self flag: #Dan.  "None of the float stuff has been converted for 64 bits"
	self assertClassOf: oop is: (self splObj: ClassFloat).
	successFlag
		ifTrue: [self cCode: '' inSmalltalk: [result := Float new: 2].
				self fetchFloatAt: oop + self baseHeaderSize into: result]
		ifFalse: [result := 0.0].
	^ result
]

{ #category : #'method lookup cache' }
Interpreter >> flushAtCache [
	"Flush the at cache. The method cache is flushed on every programming change and garbage collect."

	1 to: AtCacheTotalSize do: [ :i | atCache at: i put: 0 ]

]

{ #category : #'plugin primitive support' }
Interpreter >> flushExternalPrimitiveOf: methodPtr [
	"methodPtr is a CompiledMethod containing an external primitive. Flush the function address and session ID of the CM"
	| lit |
	(self literalCountOf: methodPtr) > 0 ifFalse:[^nil]. "Something's broken"
	lit := self literal: 0 ofMethod: methodPtr.
	((self isArray: lit) and:[(self lengthOf: lit) = 4])
		ifFalse:[^nil]. "Something's broken"
	"ConstZero is a known SmallInt so no root check needed"
	self storePointerUnchecked: 2 ofObject: lit withValue: ConstZero.
	self storePointerUnchecked: 3 ofObject: lit withValue: ConstZero.

]

{ #category : #'plugin primitive support' }
Interpreter >> flushExternalPrimitiveTable [
	"Flush the external primitive table"
	0 to: MaxExternalPrimitiveTableSize-1 do:[:i|
		externalPrimitiveTable at: i put: 0].

]

{ #category : #'plugin primitive support' }
Interpreter >> flushExternalPrimitives [
	"Flush the references to external functions from plugin 
	primitives. This will force a reload of those primitives when 
	accessed next. 
	Note: We must flush the method cache here so that any 
	failed primitives are looked up again."
	| oop primIdx |
	oop := self firstObject.
	[self oop: oop isLessThan: endOfMemory]
		whileTrue: [(self isFreeObject: oop)
				ifFalse: [(self isCompiledMethod: oop)
						ifTrue: ["This is a compiled method"
							primIdx := self primitiveIndexOf: oop.
							primIdx = PrimitiveExternalCallIndex
								ifTrue: ["It's primitiveExternalCall"
									self flushExternalPrimitiveOf: oop]]].
			oop := self objectAfter: oop].
	self flushMethodCache.
	self flushExternalPrimitiveTable
]

{ #category : #'method lookup cache' }
Interpreter >> flushMethodCache [
	"Flush the method cache. The method cache is flushed on every programming change and garbage collect."

	1 to: MethodCacheSize do: [ :i | methodCache at: i put: 0 ].
	self flushAtCache
]

{ #category : #'method lookup cache' }
Interpreter >> flushMethodCacheFrom: memStart to: memEnd [ 
	"Flush entries in the method cache only if the oop address is within the given memory range. 
	This reduces overagressive cache clearing. Note the AtCache is fully flushed, 70% of the time 
	cache entries live in newspace, new objects die young"
	| probe |
	probe := 0.
	1 to: MethodCacheEntries do: [:i | 
			(methodCache at: probe + MethodCacheSelector) = 0
				ifFalse: [(((((self oop: (methodCache at: probe + MethodCacheSelector) isGreaterThanOrEqualTo: memStart)
										and: [self oop: (methodCache at: probe + MethodCacheSelector) isLessThan: memEnd])
									or: [(self oop: (methodCache at: probe + MethodCacheClass) isGreaterThanOrEqualTo: memStart)
											and: [self oop: (methodCache at: probe + MethodCacheClass) isLessThan: memEnd]])
								or: [(self oop: (methodCache at: probe + MethodCacheMethod) isGreaterThanOrEqualTo: memStart)
										and: [self oop: (methodCache at: probe + MethodCacheMethod) isLessThan: memEnd]])
							or: [(self oop: (methodCache at: probe + MethodCacheNative) isGreaterThanOrEqualTo: memStart)
									and: [self oop: (methodCache at: probe + MethodCacheNative) isLessThan: memEnd]])
						ifTrue: [methodCache at: probe + MethodCacheSelector put: 0]].
			probe := probe + MethodCacheEntrySize].
	1 to: AtCacheTotalSize do: [:i | atCache at: i put: 0]
]

{ #category : #'process primitive support' }
Interpreter >> forceInterruptCheck [
	"force an interrupt check ASAP - setting interruptCheckCounter to a large -ve number is used as a flag to skip messing with the feedback mechanism and nextPollTick resetting makes sure that ioProcess gets called as near immediately as we can manage"
	interruptCheckCounter := -1000.
	nextPollTick := 0
]

{ #category : #'object format' }
Interpreter >> formatOfClass: classPointer [
	"**should be in-lined**"
	"Note that, in Smalltalk, the instSpec will be equal to the inst spec
	part of the base header of an instance (without hdr type) shifted left 1.
	In this way, apart from the smallInt bit, the bits
	are just where you want them for the first header word."
	"Callers expect low 2 bits (header type) to be zero!"

	^ (self fetchPointer: InstanceSpecificationIndex ofObject: classPointer) - 1
]

{ #category : #'image segment in/out' }
Interpreter >> forward: oop to: newOop savingOopAt: oopPtr andHeaderAt: hdrPtr [

	"Make a new entry in the table of saved oops."
	self longAt: oopPtr put: oop.					"Save the oop"
	self longAt: hdrPtr put: (self longAt: oop).	"Save the old header word"

	"Put a forwarding pointer in the old object, flagged with forbidden header type"
	self longAt: oop put: newOop + HeaderTypeFree.

]

{ #category : #'I/O primitive support' }
Interpreter >> fullDisplayUpdate [
	"Repaint the entire smalltalk screen, ignoring the affected rectangle. Used in some platform's code when the Smalltalk window is brought to the front or uncovered."

	| displayObj w h |
	displayObj := self splObj: TheDisplay.
	((self isPointers: displayObj) and: [(self lengthOf: displayObj) >= 4]) ifTrue: [
		w := self fetchInteger: 1 ofObject: displayObj.
		h := self fetchInteger: 2 ofObject: displayObj.
		self displayBitsOf: displayObj Left: 0 Top: 0 Right: w Bottom: h.
		self ioForceDisplayUpdate].

]

{ #category : #'method lookup cache' }
Interpreter >> functionPointerFor: primIdx inClass: theClass [
	"Find an actual function pointer for this primitiveIndex.  This is an
	opportunity to specialise the prim for the relevant class (format for
	example).  Default for now is simply the entry in the base primitiveTable."

	<returnTypeC: 'void *'>
	^primitiveTable at: primIdx
]

{ #category : #'interpreter shell' }
Interpreter >> getCurrentBytecode [
	"currentBytecode will be private to the main dispatch loop in the generated code. This method allows the currentBytecode to be retrieved from global variables."

	^ self byteAt: instructionPointer
]

{ #category : #'plugin primitive support' }
Interpreter >> getFullScreenFlag [
	^fullScreenFlag
]

{ #category : #'plugin primitive support' }
Interpreter >> getInterruptCheckCounter [
	^interruptCheckCounter
]

{ #category : #'plugin primitive support' }
Interpreter >> getInterruptKeycode [
	^interruptKeycode
]

{ #category : #'plugin primitive support' }
Interpreter >> getInterruptPending [
	^interruptPending
]

{ #category : #'image save/restore' }
Interpreter >> getLongFromFile: aFile swap: swapFlag [
	"Answer the next word read from aFile, byte-swapped according to the swapFlag."

	| w |
	<var: #aFile type: 'sqImageFile '>
	w := 0.
	self cCode: 'sqImageFileRead(&w, sizeof(w), 1, aFile)'.
	swapFlag
		ifTrue: [^ self byteSwapped: w]
		ifFalse: [^ w].

]

{ #category : #'plugin primitive support' }
Interpreter >> getNextWakeupTick [
	^nextWakeupTick
]

{ #category : #'plugin primitive support' }
Interpreter >> getSavedWindowSize [
	^savedWindowSize
]

{ #category : #contexts }
Interpreter >> getStackPointer [
	"For Newsqueak FFI"
	<export: true>
	^stackPointer
]

{ #category : #'plugin support' }
Interpreter >> getThisSessionID [
	"return the global session ID value"
	<inline: false>
	^globalSessionID
]

{ #category : #'compiled methods' }
Interpreter >> headerOf: methodPointer [
	^self fetchPointer: HeaderIndex ofObject: methodPointer
]

{ #category : #'image save/restore' }
Interpreter >> imageFormatBackwardCompatibilityVersion [
	"This VM is backwards-compatible with the immediately preceeding pre-closure version, and will allow loading images (or image segments) of that version."

	self bytesPerWord == 4
		ifTrue: [^6502]
		ifFalse: [^68000]
]

{ #category : #'image save/restore' }
Interpreter >> imageFormatInitialVersion [
	"This is the image format version that was saved to in the previous image snapshot.
	The interpreter checks this value at image load time to determine if it is able to load
	and run the image file. When the image is next saved, it will be saved using the current
	imageFormatVersion, which may be different from imageFormatInitialVersion. "
	^imageFormatInitialVersion
]

{ #category : #'image save/restore' }
Interpreter >> imageFormatVersion [
	"Return a magic constant that changes when the image format changes. Since the image reading code uses
	 this to detect byte ordering, one must avoid version numbers that are invariant under byte reversal."

	"See Interpreter class>>declareCVarsIn: and Interpreter>>pushClosureCopyCopiedValuesBytecode
	 for the initialization of imageFormatVersionNumber"
	^imageFormatVersionNumber
]

{ #category : #'image segment in/out' }
Interpreter >> imageSegmentVersion [
	| wholeWord |
	"a more complex version that tells both the word reversal and the endianness of the machine it came from.  Low half of word is 6502.  Top byte is top byte of #doesNotUnderstand: on this machine. ($d on the Mac or $s on the PC)"

	wholeWord := self longAt: (self splObj: SelectorDoesNotUnderstand) + self baseHeaderSize.
		"first data word, 'does' "
	^ self imageFormatVersion bitOr: (wholeWord bitAnd: 16rFF000000)
]

{ #category : #'plugin primitive support' }
Interpreter >> includesBehavior: aClass ThatOf: aSuperclass [
	"Return the equivalent of 
		aClass includesBehavior: aSuperclass.
	Note: written for efficiency and better inlining (only 1 temp)"
	| theClass |
	<inline: true>
	aSuperclass = nilObj ifTrue:
		[^false].
	theClass := aClass.
	[theClass = aSuperclass ifTrue:
		[^true].
	 theClass ~= nilObj] whileTrue:
		[theClass := self superclassOf: theClass].
	^false
]

{ #category : #'compiler support' }
Interpreter >> initCompilerHooks [
	"Initialize hooks for the 'null compiler'"

	self cCode: 'compilerHooks[1]= nullCompilerHook'.
	self cCode: 'compilerHooks[2]= nullCompilerHook'.
	self cCode: 'compilerHooks[3]= nullCompilerHook'.
	self cCode: 'compilerHooks[4]= nullCompilerHook'.
	self cCode: 'compilerHooks[5]= nullCompilerHook'.
	self cCode: 'compilerHooks[6]= nullCompilerHook'.
	self cCode: 'compilerHooks[7]= nullCompilerHook'.
	self cCode: 'compilerHooks[8]= nullCompilerHook'.
	self cCode: 'compilerHooks[9]= nullCompilerHook'.
	self cCode: 'compilerHooks[10]= nullCompilerHook'.
	self cCode: 'compilerHooks[11]= nullCompilerHook'.
	self cCode: 'compilerHooks[12]= nullCompilerHook'.
	self cCode: 'compilerHooks[13]= nullCompilerHook'.
	self cCode: 'compilerHooks[14]= nullCompilerHook'.

	compilerInitialized := false
]

{ #category : #initialization }
Interpreter >> initialCleanup [
	"Images written by VMs earlier than 3.6/3.7 will wrongly have the root bit set on the active context. Besides clearing the root bit, we treat this as a marker that these images also lack a cleanup of external primitives (which has been introduced at the same time when the root bit problem was fixed). In this case, we merely flush them from here."

	((self longAt: activeContext) bitAnd: self rootBit) = 0 ifTrue:[^nil]. "root bit is clean"
	"Clean root bit of activeContext"
	self longAt: activeContext put: ((self longAt: activeContext) bitAnd: self allButRootBit).
	"Clean external primitives"
	self flushExternalPrimitives.
]

{ #category : #'image save/restore' }
Interpreter >> initializeImageFormatVersionIfNeeded [
	"Set the imageFormatVersionNumber to a default value for this word
	size. Normally this will have been set at image load time, but set it to
	a reasonable default if this has not been done."

	<inline: false>
	imageFormatVersionNumber = 0
		ifTrue: [self bytesPerWord == 8
				ifFalse: [imageFormatVersionNumber := 6502]
				ifTrue: [imageFormatVersionNumber := 68000]]

]

{ #category : #initialization }
Interpreter >> initializeInterpreter: bytesToShift [ 
	"Initialize Interpreter state before starting execution of a new image."
	interpreterProxy := self sqGetInterpreterProxy.
	self dummyReferToProxy.
	self initializeObjectMemory: bytesToShift.
	self initCompilerHooks.
	activeContext := nilObj.
	theHomeContext := nilObj.
	method := nilObj.
	receiver := nilObj.
	messageSelector := nilObj.
	newMethod := nilObj.
	methodClass := nilObj.
	lkupClass := nilObj.
	receiverClass := nilObj.
	newNativeMethod := nilObj.
	self flushMethodCache.
	self loadInitialContext.
	self initialCleanup.
	interruptCheckCounter := 0.
	interruptCheckCounterFeedBackReset := 1000.
	interruptChecksEveryNms := 1.
	nextPollTick := 0.
	nextWakeupTick := 0.
	lastTick := 0.
	interruptKeycode := 2094. "cmd-. as used for Mac but no other OS"
	interruptPending := false.
	semaphoresUseBufferA := true.
	semaphoresToSignalCountA := 0.
	semaphoresToSignalCountB := 0.
	deferDisplayUpdates := false.
	pendingFinalizationSignals := 0.
	globalSessionID := 0.
	[globalSessionID = 0]
		whileTrue: [globalSessionID := self
						cCode: 'time(NULL) + ioMSecs()'
						inSmalltalk: [(Random new next * SmallInteger maxVal) asInteger]].
	jmpDepth := 0.
	jmpMax := MaxJumpBuf. "xxxx: Must match the definition of jmpBuf and suspendedCallbacks"

]

{ #category : #'array primitives' }
Interpreter >> install: rcvr inAtCache: cache at: atIx string: stringy [
	"Install the oop of this object in the given cache (at or atPut), along with
	its size, format and fixedSize"
	| hdr fmt totalLength fixedFields |
	<var: #cache type: 'sqInt *'>

	hdr := self baseHeader: rcvr.
	fmt := (hdr >> 8) bitAnd: 16rF.
	(fmt = 3 and: [self isContextHeader: hdr]) ifTrue:
		["Contexts must not be put in the atCache, since their size is not constant"
		^ self primitiveFail].
	totalLength := self lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: rcvr format: fmt length: totalLength.

	cache at: atIx+AtCacheOop put: rcvr.
	stringy ifTrue: [cache at: atIx+AtCacheFmt put: fmt + 16]  "special flag for strings"
			ifFalse: [cache at: atIx+AtCacheFmt put: fmt].
	cache at: atIx+AtCacheFixedFields put: fixedFields.
	cache at: atIx+AtCacheSize put: totalLength - fixedFields.

]

{ #category : #'return bytecodes' }
Interpreter >> internalAboutToReturn: resultObj through: aContext [
	<inline: true>
	self internalPush: activeContext.
	self internalPush: resultObj.
	self internalPush: aContext.
	messageSelector := self splObj: SelectorAboutToReturn.
	argumentCount := 2.
	^self normalSend
]

{ #category : #'message sending' }
Interpreter >> internalActivateNewMethod [
	| methodHeader newContext tempCount argCount2 needsLarge where |
	<inline: true>

	methodHeader := self headerOf: newMethod.
	needsLarge := methodHeader bitAnd: LargeContextBit.
	(needsLarge = 0 and: [freeContexts ~= NilContext])
		ifTrue: [newContext := freeContexts.
				freeContexts := self fetchPointer: 0 ofObject: newContext]
		ifFalse: ["Slower call for large contexts or empty free list"
				self externalizeIPandSP.
				newContext := self allocateOrRecycleContext: needsLarge.
				self internalizeIPandSP].
	tempCount := (methodHeader >> 19) bitAnd: 16r3F.

	"Assume: newContext will be recorded as a root if necessary by the
	 call to newActiveContext: below, so we can use unchecked stores."
	where :=   newContext + self baseHeaderSize.
	self longAt: where + (SenderIndex << self shiftForWord) put: activeContext.
	self longAt: where + (InstructionPointerIndex << self shiftForWord)
		put: (self integerObjectOf: (((LiteralStart + (self literalCountOfHeader: methodHeader)) * self bytesPerWord) + 1)).
	self longAt: where + (StackPointerIndex << self shiftForWord) put: (self integerObjectOf: tempCount).
	self longAt: where + (MethodIndex << self shiftForWord) put: newMethod.
	self longAt: where + (ClosureIndex << self shiftForWord) put: nilObj.

	"Copy the receiver and arguments..."
	argCount2 := argumentCount.
	0 to: argCount2 do:
		[:i | self longAt: where + ((ReceiverIndex+i) << self shiftForWord) put: (self internalStackValue: argCount2-i)].

	"clear remaining temps to nil in case it has been recycled"
	methodHeader := nilObj.  "methodHeader here used just as faster (register?) temp"
	argCount2+1+ReceiverIndex to: tempCount+ReceiverIndex do:
		[:i | self longAt: where + (i << self shiftForWord) put: methodHeader].

	self internalPop: argCount2 + 1.
	reclaimableContextCount := reclaimableContextCount + 1.
	self internalNewActiveContext: newContext.
 
]

{ #category : #'return bytecodes' }
Interpreter >> internalCannotReturn: resultObj [
	<inline: true>
	self internalPush: activeContext.
	self internalPush: resultObj.
	messageSelector := self splObj: SelectorCannotReturn.
	argumentCount := 1.
	^ self normalSend
]

{ #category : #'message sending' }
Interpreter >> internalExecuteNewMethod [
	| localPrimIndex delta nArgs |
	<inline: true>
	localPrimIndex := primitiveIndex.
	localPrimIndex > 0
		ifTrue: [(localPrimIndex > 255
					and: [localPrimIndex < 520])
				ifTrue: ["Internal return instvars"
					localPrimIndex >= 264
						ifTrue: [^ self internalPop: 1 thenPush: (self fetchPointer: localPrimIndex - 264 ofObject: self internalStackTop)]
						ifFalse: ["Internal return constants"
							localPrimIndex = 256 ifTrue: [^ nil].
							localPrimIndex = 257 ifTrue: [^ self internalPop: 1 thenPush: trueObj].
							localPrimIndex = 258 ifTrue: [^ self internalPop: 1 thenPush: falseObj].
							localPrimIndex = 259 ifTrue: [^ self internalPop: 1 thenPush: nilObj].
							^ self internalPop: 1 thenPush: (self integerObjectOf: localPrimIndex - 261)]]
				ifFalse: [self externalizeIPandSP.
					"self primitiveResponse. <-replaced with  manually inlined code"
					DoBalanceChecks
						ifTrue: ["check stack balance"
							nArgs := argumentCount.
							delta := stackPointer - activeContext].
					successFlag := true.
					self dispatchFunctionPointer: primitiveFunctionPointer. "branch direct to prim function from address stored in mcache"
					DoBalanceChecks
						ifTrue: [(self balancedStack: delta afterPrimitive: localPrimIndex withArgs: nArgs)
								ifFalse: [self printUnbalancedStack: localPrimIndex]].
					self internalizeIPandSP.
					successFlag
						ifTrue: [self browserPluginReturnIfNeeded.
							^ nil]]].
	"if not primitive, or primitive failed, activate the method"
	self internalActivateNewMethod.
	"check for possible interrupts at each real send"
	self internalQuickCheckForInterrupts
]

{ #category : #contexts }
Interpreter >> internalFetchContextRegisters: activeCntx [
	"Inlined into return bytecodes. The only difference between this method and fetchContextRegisters: is that this method sets the local IP and SP."

	| tmp |
	<inline: true>
	tmp := self fetchPointer: MethodIndex ofObject: activeCntx.
	(self isIntegerObject: tmp) ifTrue: [
		"if the MethodIndex field is an integer, activeCntx is a block context"
		tmp := self fetchPointer: HomeIndex ofObject: activeCntx.
		(self oop: tmp isLessThan: youngStart) ifTrue: [ self beRootIfOld: tmp ].
	] ifFalse: [
		"otherwise, it is a method context and is its own home context"
		tmp := activeCntx.
	].
	localHomeContext := tmp.
	receiver := self fetchPointer: ReceiverIndex ofObject: tmp.
	method := self fetchPointer: MethodIndex ofObject: tmp.

	"the instruction pointer is a pointer variable equal to
		method oop + ip + self baseHeaderSize
		  -1 for 0-based addressing of fetchByte
		  -1 because it gets incremented BEFORE fetching currentByte"
	tmp := self quickFetchInteger: InstructionPointerIndex ofObject: activeCntx.
	localIP := self pointerForOop: method + tmp + self baseHeaderSize - 2.

	"the stack pointer is a pointer variable also..."
	tmp := self quickFetchInteger: StackPointerIndex ofObject: activeCntx.
	localSP := self pointerForOop: activeCntx + self baseHeaderSize + ((TempFrameStart + tmp - 1) * self bytesPerWord)
]

{ #category : #'message sending' }
Interpreter >> internalFindNewMethod [
	"Find the compiled method to be run when the current messageSelector is sent to the class 'lkupClass', setting the values of 'newMethod' and 'primitiveIndex'."
	| ok | 
	<inline: true>
	ok := self lookupInMethodCacheSel: messageSelector class: lkupClass.
	ok ifFalse: [
		"entry was not found in the cache; look it up the hard way"
		self externalizeIPandSP.
		self lookupMethodInClass: lkupClass.
		self internalizeIPandSP.
		self addNewMethodToCache].

]

{ #category : #'object format' }
Interpreter >> internalIsImmutable: oop [
	<inline: true>
	<export: true>
	^false.
	"^((self baseHeader: oop) bitAnd: ImmutabilityBit) ~= 0"
]

{ #category : #'object format' }
Interpreter >> internalIsMutable: oop [
	<inline: true>
	<export: true>
	^true
	"^((self baseHeader: oop) bitAnd: ImmutabilityBit) = 0"
]

{ #category : #'message sending' }
Interpreter >> internalJustActivateNewMethod [
	"Activate the new method but *do not* copy receiver or argumernts from activeContext."
	| methodHeader initialIP newContext tempCount needsLarge where |
	<inline: true>

	methodHeader := self headerOf: newMethod.
	needsLarge := methodHeader bitAnd: LargeContextBit.
	(needsLarge = 0 and: [freeContexts ~= NilContext])
		ifTrue: [newContext := freeContexts.
				freeContexts := self fetchPointer: 0 ofObject: newContext]
		ifFalse: ["Slower call for large contexts or empty free list"
				newContext := self allocateOrRecycleContext: needsLarge].
	initialIP := ((LiteralStart + (self literalCountOfHeader: methodHeader)) * self bytesPerWord) + 1.
	tempCount := (methodHeader >> 19) bitAnd: 16r3F.

	"Assume: newContext will be recorded as a root if necessary by the
	 call to newActiveContext: below, so we can use unchecked stores."
	where := newContext + self baseHeaderSize.
	self longAt: where + (SenderIndex << self shiftForWord) put: activeContext.
	self longAt: where + (InstructionPointerIndex << self shiftForWord) put: (self integerObjectOf: initialIP).
	self longAt: where + (StackPointerIndex << self shiftForWord) put: (self integerObjectOf: tempCount).
	self longAt: where + (MethodIndex << self shiftForWord) put: newMethod.

	"Set the receiver..."
	self longAt: where + (ReceiverIndex << self shiftForWord) put: receiver.

	"clear all args and temps to nil in case it has been recycled"
	needsLarge := nilObj.  "needsLarge here used just as faster (register?) temp"
	ReceiverIndex + 1 to: tempCount + ReceiverIndex do:
		[:i | self longAt: where + (i << self shiftForWord) put: needsLarge].
	reclaimableContextCount := reclaimableContextCount + 1.

	activeContext := newContext.
]

{ #category : #contexts }
Interpreter >> internalNewActiveContext: aContext [
	"The only difference between this method and newActiveContext: is that this method uses internal context registers."
	<inline: true>

	self internalStoreContextRegisters: activeContext.
	(self oop: aContext isLessThan: youngStart) ifTrue: [ self beRootIfOld: aContext ].
	activeContext := aContext.
	self internalFetchContextRegisters: aContext.
]

{ #category : #contexts }
Interpreter >> internalPop: nItems [

	localSP := localSP - (nItems * self bytesPerWord).
]

{ #category : #contexts }
Interpreter >> internalPop: nItems thenPush: oop [

	self longAtPointer: (localSP := localSP - ((nItems - 1) * self bytesPerWord)) put: oop.

]

{ #category : #'control primitives' }
Interpreter >> internalPrimitiveValue [
	| newContext blockArgumentCount initialIP |
	<inline: true>
	self sharedCodeNamed: 'commonPrimitiveValue' inCase: 201.
	successFlag := true.
	newContext := self internalStackValue: argumentCount.
	self assertClassOf: newContext is: (self splObj: ClassBlockContext).
	blockArgumentCount := self argumentCountOfBlock: newContext.

	self success: (argumentCount = blockArgumentCount and: [(self fetchPointer: CallerIndex ofObject: newContext) = nilObj]).

	successFlag
		ifTrue: ["This code assumes argCount can only = 0 or 1"
			argumentCount = 1
				ifTrue: [self storePointer: TempFrameStart ofObject: newContext withValue: self internalStackTop].
			self internalPop: argumentCount + 1.
			"copy the initialIP value to the ip slot"
			initialIP := self fetchPointer: InitialIPIndex ofObject: newContext.
			self storePointerUnchecked: InstructionPointerIndex ofObject: newContext withValue: initialIP.
			self storeStackPointerValue: argumentCount inContext: newContext.
			self storePointerUnchecked: CallerIndex ofObject: newContext withValue: activeContext.
			self internalNewActiveContext: newContext]
		ifFalse: [messageSelector := self specialSelector: 25 + argumentCount.
			self normalSend]
]

{ #category : #contexts }
Interpreter >> internalPush: object [

	self longAtPointer: (localSP := localSP + self bytesPerWord) put: object.
]

{ #category : #'process primitive support' }
Interpreter >> internalQuickCheckForInterrupts [
	"Internal version of quickCheckForInterrupts for use within jumps."

	<inline: true>
	((interruptCheckCounter := interruptCheckCounter - 1) <= 0) ifTrue: [
		self externalizeIPandSP.
		self checkForInterrupts.

		self browserPluginReturnIfNeeded.

		self internalizeIPandSP].

]

{ #category : #contexts }
Interpreter >> internalStackTop [

	^ self longAtPointer: localSP
]

{ #category : #contexts }
Interpreter >> internalStackValue: offset [

	^ self longAtPointer: localSP - (offset * self bytesPerWord)
]

{ #category : #contexts }
Interpreter >> internalStoreContextRegisters: activeCntx [
	"The only difference between this method and fetchContextRegisters: is that this method stores from the local IP and SP."

	"InstructionPointer is a pointer variable equal to
	method oop + ip + self baseHeaderSize
		-1 for 0-based addressing of fetchByte
		-1 because it gets incremented BEFORE fetching currentByte"

	<inline: true>
	self storePointerUnchecked: InstructionPointerIndex ofObject: activeCntx
		withValue: (self integerObjectOf: 
			((self oopForPointer: localIP) + 2 - (method + self baseHeaderSize))).
	self storePointerUnchecked: StackPointerIndex		  ofObject: activeCntx
		withValue: (self integerObjectOf:
			((((self oopForPointer: localSP) - (activeCntx + self baseHeaderSize)) >> self shiftForWord) - TempFrameStart + 1)).

]

{ #category : #utilities }
Interpreter >> internalizeIPandSP [
	"Copy the local instruction and stack pointer to local variables for rapid access within the interpret loop."

	localIP := self pointerForOop: instructionPointer.
	localSP := self pointerForOop: stackPointer.
	localHomeContext := theHomeContext.

]

{ #category : #'interpreter shell' }
Interpreter >> interpret [
	"This is the main interpreter loop. It normally loops forever, fetching and executing bytecodes. When running in the context of a browser plugin VM, however, it must return control to the browser periodically. This should done only when the state of the currently running Squeak thread is safely stored in the object heap. Since this is the case at the moment that a check for interrupts is performed, that is when we return to the browser if it is time to do so. Interrupt checks happen quite frequently."

	<inline: false> "should not be inlined into any senders"
	"record entry time when running as a browser plug-in"
	self browserPluginInitialiseIfNeeded.
	self initializeImageFormatVersionIfNeeded.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue: [self dispatchOn: currentBytecode in: BytecodeTable].
	localIP := localIP - 1.  "undo the pre-increment of IP before returning"
	self externalizeIPandSP.

]

{ #category : #'process primitive support' }
Interpreter >> interruptCheckForced [
	"was this interrupt check forced by outside code?"
	^interruptCheckCounter < -100
]

{ #category : #'plugin support' }
Interpreter >> ioFilename: aCharBuffer fromString: aFilenameString ofLength: filenameLength resolveAliases: aBoolean [
"the vm has to convert aFilenameString via any canonicalization and char-mapping and put the result in aCharBuffer.
Note the resolveAliases flag - this is an awful artefact of OSX and Apples demented alias handling. When opening a file, the flag must be  true, when closing or renaming it must be false. Sigh."
	<var: #aCharBuffer type: 'char *'>
	<var: #aFilenameString type: 'char *'>
	self cCode:'sqGetFilenameFromString(aCharBuffer, aFilenameString, filenameLength, aBoolean)'
		inSmalltalk:["this doesn't translate well in Smalltalk since we know how long strings are rather than considering them terminated by a 0 char. Do the best we can"
			aCharBuffer replaceFrom:1 to: filenameLength with: aFilenameString]
]

{ #category : #'plugin primitive support' }
Interpreter >> is: oop KindOf: className [
	"Support for external primitives."
	| oopClass |
	<var: #className type: 'char *'>
	oopClass := self fetchClassOf: oop.
	[oopClass == nilObj] whileFalse:[
		(self classNameOf: oopClass Is: className) ifTrue:[^true].
		oopClass := self superclassOf: oopClass].
	^false
]

{ #category : #'plugin primitive support' }
Interpreter >> is: oop MemberOf: className [
	"Support for external primitives"
	| oopClass |
	<var: #className type: 'char *'>
	oopClass := self fetchClassOf: oop.
	^(self classNameOf: oopClass Is: className)
]

{ #category : #'plugin support' }
Interpreter >> isBigEnder [
	"Answer true (non-zero) if running on a big endian machine."
	| endianness anInt cString len i |
	<var: 'cString' type: 'char *'>
	<var: 'endianness' declareC: 'static sqInt endianness = -1'>
	(endianness == -1) ifFalse: [^ endianness]. "answer cached value"
	len := self cCode: 'sizeof(anInt)'
			inSmalltalk: [^ (Smalltalk endianness == #little) not].
	cString := self cCode: '(char *) &anInt' inSmalltalk: [].
	i := 0.
	[i < len] whileTrue:
		[cString at: i put: i.
		i := i + 1].
	endianness :=  anInt bitAnd: 255.
	^ endianness

]

{ #category : #contexts }
Interpreter >> isContext: oop [
	<inline: true>
	^(self isNonIntegerObject: oop) and: [self isContextHeader: (self baseHeader: oop)]
]

{ #category : #contexts }
Interpreter >> isContextHeader: aHeader [
	<inline: true>
	^ ((aHeader >> 12) bitAnd: 16r1F) = 13			"MethodContext"
		or: [((aHeader >> 12) bitAnd: 16r1F) = 14		"BlockContext"
		or: [((aHeader >> 12) bitAnd: 16r1F) = 4]]	"PseudoContext"
]

{ #category : #'process primitive support' }
Interpreter >> isEmptyList: aLinkedList [

	^ (self fetchPointer: FirstLinkIndex ofObject: aLinkedList) = nilObj
]

{ #category : #'plugin primitive support' }
Interpreter >> isFloatObject: oop [
	^(self fetchClassOf: oop) == self classFloat
]

{ #category : #'compiled methods' }
Interpreter >> isHandlerMarked: aContext [
	"Is this a MethodContext whose meth has a primitive number of 199?"
	| header meth pIndex |
	"NB: the use of a primitive number for marking the method is pretty grungy, but it is simple to use for a test sytem, not too expensive and we don't actually have the two spare method header bits we need. We can probably obtain them when the method format is changed.
	NB 2: actually, the jitter will probably implement the prim to actually mark the volatile frame by changing the return function pointer."
	<inline: true>
	header := self baseHeader: aContext.
	(self isMethodContextHeader: header) ifFalse: [^false].
	meth := self fetchPointer: MethodIndex ofObject: aContext.
	pIndex := self primitiveIndexOf: meth.
	^pIndex == 199

]

{ #category : #'object format' }
Interpreter >> isIndexable: oop [
	^(self formatOf: oop) >= 2
]

{ #category : #contexts }
Interpreter >> isMethodContextHeader: aHeader [
	<inline: true>
	^ ((aHeader >> 12) bitAnd: 16r1F) = 14
]

{ #category : #'compiled methods' }
Interpreter >> isUnwindMarked: aContext [
	"Is this a MethodContext whose meth has a primitive number of 198?"
	| header meth pIndex |
	"NB: the use of a primitive number for marking the method is pretty grungy, but it is simple to use for a test sytem, not too expensive and we don't actually have the two spare method header bits we need. We can probably obtain them when the method format is changed
	NB 2: actually, the jitter will probably implement the prim to actually mark the volatile frame by changing the return function pointer."
	<inline: true>
	header := self baseHeader: aContext.
	(self isMethodContextHeader: header) ifFalse: [^false].
	meth := self fetchPointer: MethodIndex ofObject: aContext.
	pIndex := self primitiveIndexOf: meth.
	^pIndex == 198

]

{ #category : #'jump bytecodes' }
Interpreter >> jump: offset [

	localIP := localIP + offset + 1.
	currentBytecode := self byteAtPointer: localIP.

]

{ #category : #'jump bytecodes' }
Interpreter >> jumplfFalseBy: offset [ 
	| boolean |
	boolean := self internalStackTop.
	boolean = falseObj
		ifTrue: [self jump: offset]
		ifFalse: [boolean = trueObj
				ifFalse: [messageSelector := self splObj: SelectorMustBeBoolean.
					argumentCount := 0.
					^ self normalSend].
			self fetchNextBytecode].
	self internalPop: 1
]

{ #category : #'jump bytecodes' }
Interpreter >> jumplfTrueBy: offset [ 
	| boolean |
	boolean := self internalStackTop.
	boolean = trueObj
		ifTrue: [self jump: offset]
		ifFalse: [boolean = falseObj
				ifFalse: [messageSelector := self splObj: SelectorMustBeBoolean.
					argumentCount := 0.
					^ self normalSend].
			self fetchNextBytecode].
	self internalPop: 1
]

{ #category : #'array primitive support' }
Interpreter >> lengthOf: oop [
	"Return the number of indexable bytes or words in the given object. Assume the argument is not an integer. For a CompiledMethod, the size of the method header (in bytes) should be subtracted from the result."

	| header |
	<inline: true>
	header := self baseHeader: oop.
	^ self lengthOf: oop baseHeader: header format: ((header >> 8) bitAnd: 16rF)
]

{ #category : #'array primitive support' }
Interpreter >> lengthOf: oop baseHeader: hdr format: fmt [
	"Return the number of indexable bytes or words in the given object. Assume the given oop is not an integer. For a CompiledMethod, the size of the method header (in bytes) should be subtracted from the result of this method."

	| sz |
	<inline: true>
	(hdr bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ sz := (self sizeHeader: oop) bitAnd: self longSizeMask ]
		ifFalse: [ sz := (hdr bitAnd: self sizeMask)].
	sz := sz - (hdr bitAnd: self size4Bit).
	fmt <= 4
		ifTrue: [ ^ (sz - self baseHeaderSize) >> self shiftForWord "words"].
	fmt < 8
		ifTrue: [ ^ (sz - self baseHeaderSize) >> 2 "32-bit longs"]
		ifFalse: [ ^ (sz - self baseHeaderSize) - (fmt bitAnd: 3) "bytes"]
]

{ #category : #'compiled methods' }
Interpreter >> literal: offset [
	^self literal: offset ofMethod: method
]

{ #category : #'compiled methods' }
Interpreter >> literal: offset ofMethod: methodPointer [

	^ self fetchPointer: offset + LiteralStart ofObject: methodPointer

]

{ #category : #'compiled methods' }
Interpreter >> literalCountOf: methodPointer [
	^self literalCountOfHeader: (self headerOf: methodPointer)
]

{ #category : #'compiled methods' }
Interpreter >> literalCountOfHeader: headerPointer [
	^ (headerPointer >> 10) bitAnd: 16rFF
]

{ #category : #'bitblt support' }
Interpreter >> loadBitBltFrom: bb [
	"This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin:=loadBitBltFrom
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided"
	| fn |
	<var: #fn type: 'void *'>
	fn := self ioLoadFunction: 'loadBitBltFrom' From: 'BitBltPlugin'.
	fn = 0 ifTrue: [^self primitiveFail].
	^self cCode: '((sqInt (*)(sqInt))fn)(bb)'
]

{ #category : #utilities }
Interpreter >> loadFloatOrIntFrom: floatOrInt [
	"If floatOrInt is an integer, then convert it to a C double float and return it.
	If it is a Float, then load its value and return it.
	Otherwise fail -- ie return with successFlag set to false."

	<inline: true>
	<returnTypeC: 'double'>

	(self isIntegerObject: floatOrInt) ifTrue:
		[^ (self integerValueOf: floatOrInt) asFloat].
	(self fetchClassOfNonInt: floatOrInt) = (self splObj: ClassFloat)
		ifTrue: [^ self floatValueOf: floatOrInt].
	successFlag := false
]

{ #category : #initialization }
Interpreter >> loadInitialContext [

	| sched proc |
	sched := self fetchPointer: ValueIndex ofObject: (self splObj: SchedulerAssociation).
	proc := self fetchPointer: ActiveProcessIndex ofObject: sched.
	activeContext := self fetchPointer: SuspendedContextIndex ofObject: proc.
	(self oop: activeContext isLessThan: youngStart) ifTrue: [ self beRootIfOld: activeContext ].
	self fetchContextRegisters: activeContext.
	reclaimableContextCount := 0.
]

{ #category : #'jump bytecodes' }
Interpreter >> longJumpIfFalse [

	self jumplfFalseBy: ((currentBytecode bitAnd: 3) * 256) + self fetchByte.
]

{ #category : #'jump bytecodes' }
Interpreter >> longJumpIfTrue [

	self jumplfTrueBy: ((currentBytecode bitAnd: 3) * 256) + self fetchByte.
]

{ #category : #'jump bytecodes' }
Interpreter >> longUnconditionalJump [

	| offset |
	offset := (((currentBytecode bitAnd: 7) - 4) * 256) + self fetchByte.
	localIP := localIP + offset.
	offset < 0 ifTrue: [
		"backward jump means we're in a loop; check for possible interrupts"
		self internalQuickCheckForInterrupts.
	].
	self fetchNextBytecode

]

{ #category : #'method lookup cache' }
Interpreter >> lookupInMethodCacheSel: selector class: class [
	"This method implements a simple method lookup cache. If an entry for the given selector and class is found in the cache, set the values of 'newMethod' and 'primitiveIndex' and return true. Otherwise, return false."
	"About the re-probe scheme: The hash is the low bits of the XOR of two large addresses, minus their useless lowest two bits. If a probe doesn't get a hit, the hash is shifted right one bit to compute the next probe, introducing a new randomish bit. The cache is probed CacheProbeMax times before giving up."
	"WARNING: Since the hash computation is based on the object addresses of the class and selector, we must rehash or flush when compacting storage. We've chosen to flush, since that also saves the trouble of updating the addresses of the objects in the cache."

	| hash probe |
	<inline: true>
	hash := selector bitXor: class.  "shift drops two low-order zeros from addresses"

	probe := hash bitAnd: MethodCacheMask.  "first probe"
	(((methodCache at: probe + MethodCacheSelector) = selector) and:
		 [(methodCache at: probe + MethodCacheClass) = class]) ifTrue:
			[newMethod := methodCache at: probe + MethodCacheMethod.
			primitiveIndex := methodCache at: probe + MethodCachePrim.
			newNativeMethod := methodCache at: probe + MethodCacheNative.
			primitiveFunctionPointer := self cCoerce: (methodCache at: probe + MethodCachePrimFunction) to: 'void *'.
			^ true	"found entry in cache; done"].

	probe := (hash >> 1) bitAnd: MethodCacheMask.  "second probe"
	(((methodCache at: probe + MethodCacheSelector) = selector) and:
		 [(methodCache at: probe + MethodCacheClass) = class]) ifTrue:
			[newMethod := methodCache at: probe + MethodCacheMethod.
			primitiveIndex := methodCache at: probe + MethodCachePrim.
			newNativeMethod := methodCache at: probe + MethodCacheNative.
			primitiveFunctionPointer := self cCoerce: (methodCache at: probe + MethodCachePrimFunction) to: 'void *'.
			^ true	"found entry in cache; done"].

	probe := (hash >> 2) bitAnd: MethodCacheMask.
	(((methodCache at: probe + MethodCacheSelector) = selector) and:
		 [(methodCache at: probe + MethodCacheClass) = class]) ifTrue:
			[newMethod := methodCache at: probe + MethodCacheMethod.
			primitiveIndex := methodCache at: probe + MethodCachePrim.
			newNativeMethod := methodCache at: probe + MethodCacheNative.
			primitiveFunctionPointer := self cCoerce: (methodCache at: probe + MethodCachePrimFunction) to: 'void *'.
			^ true	"found entry in cache; done"].

	^ false

]

{ #category : #'message sending' }
Interpreter >> lookupMethodInClass: class [
	| currentClass dictionary found rclass |
	<inline: false>

	currentClass := class.
	[currentClass ~= nilObj]
		whileTrue:
		[dictionary := self fetchPointer: MessageDictionaryIndex ofObject: currentClass.
		dictionary = nilObj ifTrue:
			["MethodDict pointer is nil (hopefully due a swapped out stub)
				-- raise exception #cannotInterpret:."
			self pushRemappableOop: currentClass.  "may cause GC!"
			self createActualMessageTo: class.
			currentClass := self popRemappableOop.
			messageSelector := self splObj: SelectorCannotInterpret.
			^ self lookupMethodInClass: (self superclassOf: currentClass)].
		found := self lookupMethodInDictionary: dictionary.
		found ifTrue: [^ methodClass := currentClass].
		currentClass := self superclassOf: currentClass].

	"Could not find #doesNotUnderstand: -- unrecoverable error."
	messageSelector = (self splObj: SelectorDoesNotUnderstand) ifTrue:
		[self error: 'Recursive not understood error encountered'].

	"Cound not find a normal message -- raise exception #doesNotUnderstand:"
	self pushRemappableOop: class.  "may cause GC!"
	self createActualMessageTo: class.
	rclass := self popRemappableOop.
	messageSelector := self splObj: SelectorDoesNotUnderstand.
	^ self lookupMethodInClass: rclass
]

{ #category : #'message sending' }
Interpreter >> lookupMethodInDictionary: dictionary [ 
	"This method lookup tolerates integers as Dictionary keys to 
	support execution of images in which Symbols have been 
	compacted out"
	| length index mask wrapAround nextSelector methodArray |
	<inline: true>
	length := self fetchWordLengthOf: dictionary.
	mask := length - SelectorStart - 1.
	(self isIntegerObject: messageSelector)
		ifTrue: [index := (mask bitAnd: (self integerValueOf: messageSelector)) + SelectorStart]
		ifFalse: [index := (mask bitAnd: (self hashBitsOf: messageSelector)) + SelectorStart].

	"It is assumed that there are some nils in this dictionary, and search will 
	stop when one is encountered. However, if there are no nils, then wrapAround 
	will be detected the second time the loop gets to the end of the table."
	wrapAround := false.
	[true]
		whileTrue: [nextSelector := self fetchPointer: index ofObject: dictionary.
			nextSelector = nilObj ifTrue: [^ false].
			nextSelector = messageSelector
				ifTrue: [methodArray := self fetchPointer: MethodArrayIndex ofObject: dictionary.
					newMethod := self fetchPointer: index - SelectorStart ofObject: methodArray.
					"Check if newMethod is a CompiledMethod."
					(self isCompiledMethod: newMethod)
						ifTrue: [primitiveIndex := self primitiveIndexOf: newMethod.
							primitiveIndex > MaxPrimitiveIndex
								ifTrue: ["If primitiveIndex is out of range, set to zero before putting in 
									cache. This is equiv to primFail, and avoids the need to check on 
									every send."
									primitiveIndex := 0]]
						ifFalse: ["indicate that this is no compiled method - use primitiveInvokeObjectAsMethod"
							primitiveIndex := 248].
					^ true].
			index := index + 1.
			index = length
				ifTrue: [wrapAround
						ifTrue: [^ false].
					wrapAround := true.
					index := SelectorStart]]
]

{ #category : #'alien support' }
Interpreter >> lookupMethodNoMNUEtcInClass: class [
	"Lookup.  Answer false on failure father than performing MNU processing etc."
	| currentClass dictionary |
	<inline: true>

	currentClass := class.
	[currentClass ~= nilObj] whileTrue:
		[dictionary := self fetchPointer: MessageDictionaryIndex ofObject: currentClass.
		(dictionary ~= nilObj
		 and: [self lookupMethodInDictionary: dictionary]) ifTrue:
			[methodClass := currentClass.
			 ^true].
		currentClass := self superclassOf: currentClass].

	^false
]

{ #category : #utilities }
Interpreter >> makePointwithxValue: xValue yValue: yValue [
"make a Point xValue@yValue.
We know both will be integers so no value nor root checking is needed"
	| pointResult |
	pointResult := self instantiateSmallClass: (self splObj: ClassPoint) sizeInBytes: 3 * self bytesPerWord.
	self storePointerUnchecked: XIndex ofObject: pointResult withValue: (self integerObjectOf: xValue).
	self storePointerUnchecked: YIndex ofObject: pointResult withValue: (self integerObjectOf: yValue).
	^ pointResult
]

{ #category : #'object memory support' }
Interpreter >> mapInterpreterOops [
	"Map all oops in the interpreter's state to their new values 
	during garbage collection or a become: operation."
	"Assume: All traced variables contain valid oops."
	| oop |
	nilObj := self remap: nilObj.
	falseObj := self remap: falseObj.
	trueObj := self remap: trueObj.
	specialObjectsOop := self remap: specialObjectsOop.
	compilerInitialized
		ifFalse: [stackPointer := stackPointer - activeContext. "*rel to active"
			activeContext := self remap: activeContext.
			stackPointer := stackPointer + activeContext. "*rel to active"
			theHomeContext := self remap: theHomeContext].
	instructionPointer := instructionPointer - method. "*rel to method"
	method := self remap: method.
	instructionPointer := instructionPointer + method. "*rel to method"
	receiver := self remap: receiver.
	messageSelector := self remap: messageSelector.
	newMethod := self remap: newMethod.
	methodClass := self remap: methodClass.
	lkupClass := self remap: lkupClass.
	receiverClass := self remap: receiverClass.
	1 to: remapBufferCount do: [:i | 
			oop := remapBuffer at: i.
			(self isIntegerObject: oop)
				ifFalse: [remapBuffer at: i put: (self remap: oop)]].

	"Callback support - trace suspended callback list"
	1 to: jmpDepth do:[:i|
		oop := suspendedCallbacks at: i.
		(self isIntegerObject: oop) 
			ifFalse:[suspendedCallbacks at: i put: (self remap: oop)].
		oop := suspendedMethods at: i.
		(self isIntegerObject: oop) 
			ifFalse:[suspendedMethods at: i put: (self remap: oop)].
	].

]

{ #category : #'object memory support' }
Interpreter >> markAndTraceInterpreterOops [
	"Mark and trace all oops in the interpreter's state."
	"Assume: All traced variables contain valid oops."
	| oop |
	self compilerMarkHook.
	self markAndTrace: specialObjectsOop. "also covers nilObj, trueObj, falseObj, and compact classes"
	compilerInitialized
		ifTrue: [self markAndTrace: receiver.
			self markAndTrace: method]
		ifFalse: [self markAndTrace: activeContext].
	self markAndTrace: messageSelector.
	self markAndTrace: newMethod.
	self markAndTrace: methodClass.
	self markAndTrace: lkupClass.
	self markAndTrace: receiverClass.
	1 to: remapBufferCount do: [:i | 
			oop := remapBuffer at: i.
			(self isIntegerObject: oop) ifFalse: [self markAndTrace: oop]].

	"Callback support - trace suspended callback list"
	1 to: jmpDepth do:[:i|
		oop := suspendedCallbacks at: i.
		(self isIntegerObject: oop) ifFalse:[self markAndTrace: oop].
		oop := suspendedMethods at: i.
		(self isIntegerObject: oop) ifFalse:[self markAndTrace: oop].
	].

]

{ #category : #'plugin primitive support' }
Interpreter >> methodArgumentCount [
	^argumentCount
]

{ #category : #'compiled methods' }
Interpreter >> methodClassOf: methodPointer [

	^ self fetchPointer: ValueIndex ofObject: (self literal: (self literalCountOf: methodPointer) - 1 ofMethod: methodPointer)
]

{ #category : #'plugin primitive support' }
Interpreter >> methodPrimitiveIndex [
	^primitiveIndex
]

{ #category : #initialization }
Interpreter >> moduleUnloaded: aModuleName [ 
	"The module with the given name was just unloaded. 
	Make sure we have no dangling references."
	<export: true>
	<var: #aModuleName type: 'char *'>
	(aModuleName strcmp: 'SurfacePlugin') = 0
		ifTrue: ["Surface plugin went away. Should never happen. But  then, who knows"
			showSurfaceFn := 0]
]

{ #category : #contexts }
Interpreter >> newActiveContext: aContext [
	"Note: internalNewActiveContext: should track changes to this method."

	self storeContextRegisters: activeContext.
	(self oop: aContext isLessThan: youngStart) ifTrue: [ self beRootIfOld: aContext ].
	activeContext := aContext.
	self fetchContextRegisters: aContext.
]

{ #category : #'object format' }
Interpreter >> nonWeakFieldsOf: oop [
	"Return the number of non-weak fields in oop (i.e. the number of fixed fields).
	Note: The following is copied from fixedFieldsOf:format:length: since we do know
	the format of the oop (e.g. format = 4) and thus don't need the length."
	| class classFormat |
	<inline: false> "No need to inline - we won't call this often"

	(self isWeakNonInt: oop) ifFalse:[self error:'Called fixedFieldsOfWeak: with a non-weak oop'].

	"fmt = 3 or 4: mixture of fixed and indexable fields, so must look at class format word"
	class := self fetchClassOf: oop.
	classFormat := self formatOfClass: class.
	^ (classFormat >> 11 bitAnd: 16rC0) + (classFormat >> 2 bitAnd: 16r3F) - 1

]

{ #category : #'message sending' }
Interpreter >> normalSend [
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that 
	the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	| rcvr |
	<inline: true>
	self sharedCodeNamed: 'normalSend' inCase: 131.
	rcvr := self internalStackValue: argumentCount.
	lkupClass := self fetchClassOf: rcvr.
	receiverClass := lkupClass.
	self commonSend.
]

{ #category : #'image save/restore' }
Interpreter >> normalizeFloatOrderingInImage [
	"Float objects were saved in platform word ordering. Reorder them into the
	traditional object format."

	<inline: false>
	<var: #floatData type: 'unsigned int *'>
	<var: #val type: 'unsigned int'>
	self isBigEnder
		ifFalse: [ | oop | "Swap words within Float objects, taking them out of native platform ordering"
				oop := self firstAccessibleObject.
				[oop = nil] whileFalse: [ | val |
					(self isFreeObject: oop) ifFalse: [
						(self fetchClassOf: oop) = self classFloat
							ifTrue: [ | floatData |
								floatData := self cCoerce: (self firstIndexableField: oop) to: 'unsigned int *'.
								val := floatData at: 0.
								floatData at: 0 put: (floatData at: 1).
								floatData at: 1 put: val].
						oop := self accessibleObjectAfter: oop]]]

]

{ #category : #'compiler support' }
Interpreter >> nullCompilerHook [
	"This should never be called: either the compiler is uninitialised (in which case the hooks should never be reached) or the compiler initialisation should have replaced all the hook with their external implementations."

	self error: 'uninitialised compiler hook called'.
	^false
]

{ #category : #'debug support' }
Interpreter >> okayActiveProcessStack [

	| cntxt |
	cntxt := activeContext.	
	[cntxt = nilObj] whileFalse: [
		self okayFields: cntxt.
		cntxt := (self fetchPointer: SenderIndex ofObject: cntxt).
	].
]

{ #category : #'debug support' }
Interpreter >> okayFields: oop [
	"If this is a pointers object, check that its fields are all okay oops."

	| i fieldOop c |
	(oop = nil or: [oop = 0]) ifTrue: [ ^true ].
	(self isIntegerObject: oop) ifTrue: [ ^true ].
	self okayOop: oop.
	self oopHasOkayClass: oop.
	(self isPointers: oop) ifFalse: [ ^true ].
	c := self fetchClassOf: oop.
	(c = (self splObj: ClassMethodContext)
		or: [c = (self splObj: ClassBlockContext)])
		ifTrue: [i := CtxtTempFrameStart + (self fetchStackPointerOf: oop) - 1]
		ifFalse: [i := (self lengthOf: oop) - 1].
	[i >= 0] whileTrue: [
		fieldOop := self fetchPointer: i ofObject: oop.
		(self isIntegerObject: fieldOop) ifFalse: [
			self okayOop: fieldOop.
			self oopHasOkayClass: fieldOop.
		].
		i := i - 1.
	].
]

{ #category : #'debug support' }
Interpreter >> okayInterpreterObjects [

	| oopOrZero oop |
	self okayFields: nilObj.
	self okayFields: falseObj.
	self okayFields: trueObj.
	self okayFields: specialObjectsOop.
	self okayFields: activeContext.
	self okayFields: method.
	self okayFields: receiver.
	self okayFields: theHomeContext.
	self okayFields: messageSelector.
	self okayFields: newMethod.
	self okayFields: lkupClass.
	0 to: MethodCacheEntries - 1 by: MethodCacheEntrySize do: [ :i |
		oopOrZero := methodCache at: i + MethodCacheSelector.
		oopOrZero = 0 ifFalse: [
			self okayFields: (methodCache at: i + MethodCacheSelector).
			self okayFields: (methodCache at: i + MethodCacheClass).
			self okayFields: (methodCache at: i + MethodCacheMethod).
		].
	].
	1 to: remapBufferCount do: [ :i |
		oop := remapBuffer at: i.
		(self isIntegerObject: oop) ifFalse: [
			self okayFields: oop.
		].
	].
	self okayActiveProcessStack.
]

{ #category : #'debug support' }
Interpreter >> okayOop: signedOop [
	"Verify that the given oop is legitimate. Check address, header, and size but not class."

	| sz type fmt unusedBit oop |
	<var: #oop type: 'usqInt'>
	oop := self cCoerce: signedOop to: 'usqInt'.

	"address and size checks"
	(self isIntegerObject: oop) ifTrue: [ ^true ].
	(oop < endOfMemory)
		ifFalse: [ self error: 'oop is not a valid address' ].
	((oop \\ self bytesPerWord) = 0)
		ifFalse: [ self error: 'oop is not a word-aligned address' ].
	sz := self sizeBitsOf: oop.
	(oop + sz) < endOfMemory
		ifFalse: [ self error: 'oop size would make it extend beyond the end of memory' ].

	"header type checks"
	type := self headerType: oop.
	type = HeaderTypeFree
		ifTrue:  [ self error: 'oop is a free chunk, not an object' ].
	type = HeaderTypeShort ifTrue: [
		(((self baseHeader: oop) >> 12) bitAnd: 16r1F) = 0
			ifTrue:  [ self error: 'cannot have zero compact class field in a short header' ].
	].
	type = HeaderTypeClass ifTrue: [
		((oop >= self bytesPerWord) and: [(self headerType: oop - self bytesPerWord) = type])
			ifFalse: [ self error: 'class header word has wrong type' ].
	].
	type = HeaderTypeSizeAndClass ifTrue: [
		((oop >= (self bytesPerWord * 2)) and:
		 [(self headerType: oop - (self bytesPerWord * 2)) = type and:
		 [(self headerType: oop - self bytesPerWord) = type]])
			ifFalse: [ self error: 'class header word has wrong type' ].
	].

	"format check"
	fmt := self formatOf: oop.
	((fmt = 5) | (fmt = 7))
		ifTrue:  [ self error: 'oop has an unknown format type' ].

	"mark and root bit checks"
	unusedBit := 16r20000000.
	self bytesPerWord = 8
		ifTrue:
			[unusedBit := unusedBit << 16.
			 unusedBit := unusedBit << 16].
	((self longAt: oop) bitAnd: unusedBit) = 0
		ifFalse: [ self error: 'unused header bit 30 is set; should be zero' ].
"xxx
	((self longAt: oop) bitAnd: MarkBit) = 0
		ifFalse: [ self error: 'mark bit should not be set except during GC' ].
xxx"
	(((self longAt: oop) bitAnd: self rootBit) = 1 and:
	 [oop >= youngStart])
		ifTrue: [ self error: 'root bit is set in a young object' ].
	^true

]

{ #category : #'image save/restore' }
Interpreter >> oldFormatFullScreenFlag: flagsWord [
	"The full screen flags word in the image header file was originally defined as
	a boolean (low order bit of the word set for true). In more recent usage with
	StackInterpreter, the remaining bits are allocated for other purposes. This
	interpreter does not use the new bit definitions, and should clear the bits
	before saving the image."

	^ flagsWord bitAnd: 1
]

{ #category : #'image segment in/out' }
Interpreter >> oopHasAcceptableClass: signedOop [
	"Similar to oopHasOkayClass:, except that it only returns true or false."

	| oopClass formatMask behaviorFormatBits oopFormatBits oop |
	<var: #oop type: 'usqInt'>
	<var: #oopClass type: 'usqInt'>

	(self isIntegerObject: signedOop) ifTrue: [^ true].

	oop := self cCoerce: signedOop to: 'usqInt'.

	oop < endOfMemory ifFalse: [^ false].
	((oop \\ self bytesPerWord) = 0) ifFalse: [^ false].
	(oop + (self sizeBitsOf: oop)) < endOfMemory ifFalse: [^ false].
	oopClass := self cCoerce: (self fetchClassOf: oop) to: 'usqInt'.

	(self isIntegerObject: oopClass) ifTrue: [^ false].
	(oopClass < endOfMemory) ifFalse: [^ false].
	((oopClass \\ self bytesPerWord) = 0) ifFalse: [^ false].
	(oopClass + (self sizeBitsOf: oopClass)) < endOfMemory ifFalse: [^ false].
	((self isPointers: oopClass) and: [(self lengthOf: oopClass) >= 3]) ifFalse: [^ false].
	(self isBytes: oop)
		ifTrue: [ formatMask := 16rC00 ]  "ignore extra bytes size bits"
		ifFalse: [ formatMask := 16rF00 ].

	behaviorFormatBits := (self formatOfClass: oopClass) bitAnd: formatMask.
	oopFormatBits := (self baseHeader: oop) bitAnd: formatMask.
	behaviorFormatBits = oopFormatBits ifFalse: [^ false].
	^ true
]

{ #category : #'debug support' }
Interpreter >> oopHasOkayClass: signedOop [
	"Attempt to verify that the given oop has a reasonable behavior. The class must be a valid, non-integer oop and must not be nilObj. It must be a pointers object with three or more fields. Finally, the instance specification field of the behavior must match that of the instance."

	| oop oopClass formatMask behaviorFormatBits oopFormatBits |
	<var: #oop type: 'usqInt'>
	<var: #oopClass type: 'usqInt'>

	oop := self cCoerce: signedOop to: 'usqInt'.
	self okayOop: oop.
	oopClass := self cCoerce: (self fetchClassOf: oop) to: 'usqInt'.

	(self isIntegerObject: oopClass)
		ifTrue: [ self error: 'a SmallInteger is not a valid class or behavior' ].
	self okayOop: oopClass.
	((self isPointers: oopClass) and: [(self lengthOf: oopClass) >= 3])
		ifFalse: [ self error: 'a class (behavior) must be a pointers object of size >= 3' ].
	(self isBytes: oop)
		ifTrue: [ formatMask := 16rC00 ]  "ignore extra bytes size bits"
		ifFalse: [ formatMask := 16rF00 ].

	behaviorFormatBits := (self formatOfClass: oopClass) bitAnd: formatMask.
	oopFormatBits := (self baseHeader: oop) bitAnd: formatMask.
	behaviorFormatBits = oopFormatBits
		ifFalse: [ self error: 'object and its class (behavior) formats differ' ].
	^true
]

{ #category : #contexts }
Interpreter >> pop2AndPushIntegerIfOK: integerResult [

	successFlag ifTrue:
		[(self isIntegerValue: integerResult)
			ifTrue: [self pop: 2 thenPush: (self integerObjectOf: integerResult)]
			ifFalse: [successFlag := false]]
]

{ #category : #contexts }
Interpreter >> pop: nItems [
	"Note: May be called by translated primitive code."

	stackPointer := stackPointer - (nItems * self bytesPerWord).
]

{ #category : #contexts }
Interpreter >> pop: nItems thenPush: oop [

	| sp |
	self longAt: (sp := stackPointer - ((nItems - 1) * self bytesPerWord)) put: oop.
	stackPointer := sp.

]

{ #category : #contexts }
Interpreter >> pop: nItems thenPushInteger: integerVal [
"lots of places pop a few items off the stack and then push an integer. MAke it convenient"
	| sp |
	self longAt: (sp := stackPointer - ((nItems - 1) * self bytesPerWord)) put:(self integerObjectOf: integerVal).
	stackPointer := sp.

]

{ #category : #'stack bytecodes' }
Interpreter >> popFloat [
	"Note: May be called by translated primitive code."

	| top result |
	<returnTypeC: 'double'>
	<var: #result type: 'double '>
	top := self popStack.
	self assertClassOf: top is: (self splObj: ClassFloat).
	successFlag ifTrue:
		[self cCode: '' inSmalltalk: [result := Float new: 2].
		self fetchFloatAt: top + self baseHeaderSize into: result].
	^ result
]

{ #category : #contexts }
Interpreter >> popInteger [
"returns 0 if the stackTop was not an integer value, plus sets successFlag false"
	| integerPointer |
	integerPointer := self popStack.
	^self checkedIntegerValueOf: integerPointer
]

{ #category : #contexts }
Interpreter >> popPos32BitInteger [
	"May set successFlag, and return false if not valid"

	| top |
	top := self popStack.
	^ self positive32BitValueOf: top
]

{ #category : #contexts }
Interpreter >> popStack [

	| top |
	top := self longAt: stackPointer.
	stackPointer := stackPointer - self bytesPerWord.
	^ top
]

{ #category : #'stack bytecodes' }
Interpreter >> popStackBytecode [

	self fetchNextBytecode.
	self internalPop: 1.

]

{ #category : #'primitive support' }
Interpreter >> positive32BitIntegerFor: integerValue [

	| newLargeInteger |
	"Note - integerValue is interpreted as POSITIVE, eg, as the result of
		Bitmap>at:, or integer>bitAnd:."
	integerValue >= 0
		ifTrue: [(self isIntegerValue: integerValue)
					ifTrue: [^ self integerObjectOf: integerValue]].

	self bytesPerWord = 4
	ifTrue: ["Faster instantiateSmallClass: currently only works with integral word size."
			newLargeInteger := self instantiateSmallClass: (self splObj: ClassLargePositiveInteger)
					sizeInBytes: self baseHeaderSize + 4]
	ifFalse: ["Cant use instantiateSmallClass: due to integral word requirement."
			newLargeInteger := self instantiateClass: (self splObj: ClassLargePositiveInteger)
					indexableSize: 4].
	self storeByte: 3 ofObject: newLargeInteger withValue: ((integerValue >> 24) bitAnd: 16rFF).
	self storeByte: 2 ofObject: newLargeInteger withValue: ((integerValue >> 16) bitAnd: 16rFF).
	self storeByte: 1 ofObject: newLargeInteger withValue: ((integerValue >> 8) bitAnd: 16rFF).
	self storeByte: 0 ofObject: newLargeInteger withValue: (integerValue bitAnd: 16rFF).
	^ newLargeInteger
]

{ #category : #'primitive support' }
Interpreter >> positive32BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive ST integer or a four-byte LargePositiveInteger."

	| sz value |
	(self isIntegerObject: oop) ifTrue: [
		value := self integerValueOf: oop.
		value < 0 ifTrue: [^ self primitiveFail].
		^ value].

	self assertClassOf: oop is: (self splObj: ClassLargePositiveInteger).
	successFlag ifTrue: [
		sz := self lengthOf: oop.
		sz = 4 ifFalse: [^ self primitiveFail]].
	successFlag ifTrue: [
		^ (self fetchByte: 0 ofObject: oop) +
		  ((self fetchByte: 1 ofObject: oop) <<  8) +
		  ((self fetchByte: 2 ofObject: oop) << 16) +
		  ((self fetchByte: 3 ofObject: oop) << 24) ].
]

{ #category : #'primitive support' }
Interpreter >> positive64BitIntegerFor: integerValue [

	| newLargeInteger value highWord sz |
	"Note - integerValue is interpreted as POSITIVE, eg, as the result of
		Bitmap>at:, or integer>bitAnd:."
	<var: 'integerValue' type: 'sqLong'>
 
	(self sizeof: integerValue) = 4 ifTrue: [^self positive32BitIntegerFor: integerValue].


	highWord := self cCode: 'integerValue >> 32'. "shift is coerced to usqInt otherwise"
	highWord = 0 ifTrue:[^self positive32BitIntegerFor: integerValue].
	sz := 5.
	(highWord := highWord >> 8) = 0 ifFalse:[sz := sz + 1].
	(highWord := highWord >> 8) = 0 ifFalse:[sz := sz + 1].
	(highWord := highWord >> 8) = 0 ifFalse:[sz := sz + 1].
	newLargeInteger := self instantiateClass: (self splObj: ClassLargePositiveInteger) indexableSize:  sz.
	0 to: sz-1 do: [:i |
		value := self cCode: '(integerValue >> (i * 8)) & 255'.
		self storeByte: i ofObject: newLargeInteger withValue: value].
	^ newLargeInteger

]

{ #category : #'primitive support' }
Interpreter >> positive64BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive ST integer or a eight-byte LargePositiveInteger."

	| sz szsqLong value  |
	<returnTypeC: 'sqLong'>
	<var: 'value' type: 'sqLong'>
	(self isIntegerObject: oop) ifTrue: [
		value := self integerValueOf: oop.
		value < 0 ifTrue: [^ self primitiveFail].
		^ value].

	self assertClassOf: oop is: (self splObj: ClassLargePositiveInteger).
	successFlag ifFalse: [^ self primitiveFail].
	szsqLong := self cCode: 'sizeof(sqLong)'.
	sz := self lengthOf: oop.
	sz > szsqLong
		ifTrue: [^ self primitiveFail].
	value := 0.
	0 to: sz - 1 do: [:i |
		value := value + ((self cCoerce: (self fetchByte: i ofObject: oop) to: 'sqLong') <<  (i*8))].
	^value.
]

{ #category : #'object memory support' }
Interpreter >> postGCAction [
	"Mark the active and home contexts as roots if old. This 
	allows the interpreter to use storePointerUnchecked to 
	store into them."

	compilerInitialized
		ifTrue: [self compilerPostGC]
		ifFalse: [(self oop: activeContext isLessThan: youngStart)
				ifTrue: [self beRootIfOld: activeContext].
			(self oop: theHomeContext isLessThan: youngStart)
				ifTrue: [self beRootIfOld: theHomeContext]].
	(self oop: (self sizeOfFree: freeBlock) isGreaterThan:  shrinkThreshold)
		ifTrue: ["Attempt to shrink memory after successfully 
			reclaiming lots of memory"
			self shrinkObjectMemory: (self sizeOfFree: freeBlock) - growHeadroom].
	
	self signalSemaphoreWithIndex: gcSemaphoreIndex.

]

{ #category : #'object memory support' }
Interpreter >> preGCAction: fullGCFlag [

	compilerInitialized
		ifTrue: [self compilerPreGC: fullGCFlag]
		ifFalse: [self storeContextRegisters: activeContext].
]

{ #category : #'primitive support' }
Interpreter >> primIndex [
	^ primitiveIndex
]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveAdd [

	self pop2AndPushIntegerIfOK: (self stackIntegerValue: 1) + (self stackIntegerValue: 0)
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveAddLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| integerRcvr integerArg result oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'result' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).
	successFlag ifFalse:[^nil].

	"Compute the preliminary result (which may overflow)"
	result := integerRcvr + integerArg.

	"Now check overflow conditions. First is whether rcvr and arg are of the same sign.
	If they are we need to check for overflow more carefully."
	(integerRcvr bitXor: integerArg) < 0 ifFalse:[
		"Second is whether rcvr and result are of the same sign. If not, we have an overflow."
		(integerRcvr bitXor: result) < 0 ifTrue:[self primitiveFail]].
			
	successFlag ifFalse:[^nil].

	oopResult := self signed64BitIntegerFor: result.
	successFlag ifTrue:[self pop: 2 thenPush: oopResult].

]

{ #category : #'object access primitives' }
Interpreter >> primitiveAdoptInstance [
	"Primitive. Change the class of the argument to make it an instance of the receiver
	 given that the format of the receiver matches the format of the argument's class.
	 Fail if receiver or argument are SmallIntegers, or the receiver is an instance of a
	 compact class and the argument isn't, or when the argument's class is compact and
	 the receiver isn't, or when the format of the receiver is different from the format of
	 the argument's class, or when the arguments class is fixed and the receiver's size
	 differs from the size that an instance of the argument's class should have."
	| rcvr arg err |

	arg := self stackObjectValue: 0.
	rcvr := self stackObjectValue: 1.

	err := self changeClassOf: arg to: rcvr.
	err = 0
		ifTrue: ["Flush at cache because rcvr's class has changed."
				self flushAtCache.
				self pop: self methodArgumentCount]
		ifFalse: [self primitiveFail].
	^nil
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveArctan [

	| rcvr |
	<var: #rcvr type: 'double '>
	rcvr := self popFloat.
	successFlag
		ifTrue: [self pushFloat: (self cCode: 'atan(rcvr)' inSmalltalk: [rcvr arcTan])]
		ifFalse: [self unPop: 1]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveArrayBecome [
	"We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors."

	| arg rcvr |
	arg := self stackTop.
	rcvr := self stackValue: 1.
	self success: (self become: rcvr with: arg twoWay: true copyHash: true).
	successFlag ifTrue: [ self pop: 1 ].
]

{ #category : #'object access primitives' }
Interpreter >> primitiveArrayBecomeOneWay [
	"We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors."

	| arg rcvr |
	arg := self stackTop.
	rcvr := self stackValue: 1.
	self success: (self become: rcvr with: arg twoWay: false copyHash: true).
	successFlag ifTrue: [ self pop: 1 ].
]

{ #category : #'object access primitives' }
Interpreter >> primitiveArrayBecomeOneWayCopyHash [
	"Similar to primitiveArrayBecomeOneWay but accepts a third argument whether to copy
	the receiver's identity hash over the argument's identity hash."

	| copyHashFlag arg rcvr |
	copyHashFlag := self booleanValueOf: (self stackTop).
	arg := self stackValue: 1.
	rcvr := self stackValue: 2.
	self success: (self become: rcvr with: arg twoWay: false copyHash: copyHashFlag).
	successFlag ifTrue: [ self pop: 2 ].
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveAsFloat [
	| arg |
	arg := self popInteger.
	successFlag
		ifTrue: [ self pushFloat: (self cCode: '((double) arg)' inSmalltalk: [arg asFloat]) ]
		ifFalse: [ self unPop: 1 ].
]

{ #category : #'object access primitives' }
Interpreter >> primitiveAsOop [
	| thisReceiver |
	thisReceiver := self stackTop.
	self success: (self isIntegerObject: thisReceiver) not.
	successFlag
		ifTrue: [self pop:1 thenPushInteger: (self hashBitsOf: thisReceiver)]
]

{ #category : #'array primitives' }
Interpreter >> primitiveAt [

	self commonAt: false.
]

{ #category : #'array and stream primitives' }
Interpreter >> primitiveAtEnd [
	| stream index limit |
	stream := self popStack.
	successFlag := ((self isPointers: stream)
			and: [(self lengthOf: stream) >= (StreamReadLimitIndex+1)]).
 	successFlag ifTrue: [
		index := self fetchInteger: StreamIndexIndex ofObject: stream.
		limit := self fetchInteger: StreamReadLimitIndex ofObject: stream].
 	successFlag
		ifTrue: [self pushBool: (index >= limit)]
		ifFalse: [self unPop: 1].
]

{ #category : #'array primitives' }
Interpreter >> primitiveAtPut [

	self commonAtPut: false.
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveBeCursor [
	"Set the cursor to the given shape. The Mac only supports 16x16 pixel cursors. Cursor offsets are handled by Smalltalk."

	| cursorObj maskBitsIndex maskObj bitsObj extentX extentY depth offsetObj offsetX offsetY cursorBitsIndex ourCursor |

self flag: #Dan.  "This is disabled until we convert bitmaps appropriately"
self bytesPerWord = 8 ifTrue: [^ self pop: argumentCount].

	argumentCount = 0 ifTrue: [
		cursorObj := self stackTop.
		maskBitsIndex := nil].
	argumentCount = 1 ifTrue: [
		cursorObj := self stackValue: 1.
		maskObj := self stackTop].
	self success: (argumentCount < 2).

	self success: ((self isPointers: cursorObj) and: [(self lengthOf: cursorObj) >= 5]).
	successFlag ifTrue: [
		bitsObj := self fetchPointer: 0 ofObject: cursorObj.
		extentX := self fetchInteger: 1 ofObject: cursorObj.
		extentY := self fetchInteger: 2 ofObject: cursorObj.
		depth := self fetchInteger: 3 ofObject: cursorObj.
		offsetObj := self fetchPointer: 4 ofObject: cursorObj].
		self success: ((self isPointers: offsetObj) and: [(self lengthOf: offsetObj) >= 2]).

	successFlag ifTrue: [
		offsetX := self fetchInteger: 0 ofObject: offsetObj.
		offsetY := self fetchInteger: 1 ofObject: offsetObj.

		(argumentCount = 0 and: [depth = 32])
			ifTrue: [
				"Support arbitrary-sized 32 bit ARGB forms --bf 3/1/2007 23:51"
				self success: ((extentX > 0) and: [extentY > 0]).
				self success: ((offsetX >= (extentX * -1)) and: [offsetX <= 0]).
				self success: ((offsetY >= (extentY * -1)) and: [offsetY <= 0]).
				cursorBitsIndex := bitsObj + self baseHeaderSize.
				self success: ((self isWords: bitsObj) and: [(self lengthOf: bitsObj) = (extentX * extentY)]).
				self cCode: '' inSmalltalk:
					[ourCursor := Cursor
						extent: extentX @ extentY
						depth: 32
						fromArray: ((1 to: extentX * extentY) collect: [:i |
							self fetchLong32: i-1 ofObject: bitsObj])
						offset: offsetX  @ offsetY]]
			ifFalse: [
				self success: ((extentX = 16) and: [extentY = 16 and: [depth = 1]]).
				self success: ((offsetX >= -16) and: [offsetX <= 0]).
				self success: ((offsetY >= -16) and: [offsetY <= 0]).
				self success: ((self isWords: bitsObj) and: [(self lengthOf: bitsObj) = 16]).
				cursorBitsIndex := bitsObj + self baseHeaderSize.
				self cCode: '' inSmalltalk:
					[ourCursor := Cursor
						extent: extentX @ extentY
						fromArray: ((1 to: 16) collect: [:i |
							((self fetchLong32: i-1 ofObject: bitsObj) >> 16) bitAnd: 16rFFFF])
						offset: offsetX  @ offsetY]]].

	argumentCount = 1 ifTrue: [
		self success: ((self isPointers: maskObj) and: [(self lengthOf: maskObj) >= 5]).
		successFlag ifTrue: [
			bitsObj := self fetchPointer: 0 ofObject: maskObj.
			extentX := self fetchInteger: 1 ofObject: maskObj.
			extentY := self fetchInteger: 2 ofObject: maskObj.
			depth := self fetchInteger: 3 ofObject: maskObj].

		successFlag ifTrue: [
			self success: ((extentX = 16) and: [extentY = 16 and: [depth = 1]]).
			self success: ((self isWords: bitsObj) and: [(self lengthOf: bitsObj) = 16]).
			maskBitsIndex := bitsObj + self baseHeaderSize]].


	successFlag ifTrue: [
		argumentCount = 0
			ifTrue: [
				depth = 32
					ifTrue: [(self cCode: 'ioSetCursorARGB(cursorBitsIndex, extentX, extentY, offsetX, offsetY)'
						inSmalltalk: [ourCursor show. Cursor currentCursor == ourCursor])	
							ifFalse: [^self success: false]]
					ifFalse: [self cCode: 'ioSetCursor(cursorBitsIndex, offsetX, offsetY)'
						inSmalltalk: [ourCursor show]]]
			ifFalse: [self cCode: 'ioSetCursorWithMask(cursorBitsIndex, maskBitsIndex, offsetX, offsetY)'
						inSmalltalk: [cursorBitsIndex == maskBitsIndex. "placate compiler"
									ourCursor show]].
		self pop: argumentCount]
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveBeDisplay [
	"Record the system Display object in the specialObjectsTable."
	| rcvr |
	rcvr := self stackTop.
	self success: ((self isPointers: rcvr) and: [(self lengthOf: rcvr) >= 4]).
	successFlag ifTrue: [self storePointer: TheDisplay ofObject: specialObjectsOop withValue: rcvr]
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveBeep [
"make the basic beep noise"
	self ioBeep.
]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveBitAnd [
	| integerReceiver integerArgument |
	integerArgument := self popPos32BitInteger.
	integerReceiver := self popPos32BitInteger.
	successFlag
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitAnd: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveBitAndLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| integerRcvr integerArg oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self positive64BitValueOf: (self stackValue: 0).
	integerRcvr := self positive64BitValueOf: (self stackValue: 1).
	successFlag ifFalse:[^nil].

	oopResult := self positive64BitIntegerFor: (integerRcvr bitAnd: integerArg).
	successFlag ifTrue:[self pop: 2 thenPush: oopResult].

]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveBitOr [
	| integerReceiver integerArgument |
	integerArgument := self popPos32BitInteger.
	integerReceiver := self popPos32BitInteger.
	successFlag
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitOr: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveBitOrLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| integerRcvr integerArg oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self positive64BitValueOf: (self stackValue: 0).
	integerRcvr := self positive64BitValueOf: (self stackValue: 1).
	successFlag ifFalse:[^nil].

	oopResult := self positive64BitIntegerFor: (integerRcvr bitOr: integerArg).
	successFlag ifTrue:[self pop: 2 thenPush: oopResult].

]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveBitShift [ 
	| integerReceiver integerArgument shifted |
	integerArgument := self popInteger.
	integerReceiver := self popPos32BitInteger.
	successFlag ifTrue: [
		integerArgument >= 0 ifTrue: [
			"Left shift -- must fail if we lose bits beyond 32"
			self success: integerArgument <= 31.
			shifted := integerReceiver << integerArgument.
			self success: (shifted >> integerArgument) = integerReceiver.
		] ifFalse: [
			"Right shift -- OK to lose bits"
			self success: integerArgument >= -31.
			shifted := integerReceiver bitShift: integerArgument.
		].
	].
	successFlag
		ifTrue: [self push: (self positive32BitIntegerFor: shifted)]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveBitShiftLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| shifted integerArg integerRcvr oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'shifted' type: 'sqLong'>

	integerArg := self stackIntegerValue: 0.
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	successFlag ifTrue: [
		integerArg >= 0 ifTrue: [
			"Left shift -- must fail if we lose bits beyond 64"
			self success: integerArg < 64.
			shifted := integerRcvr << integerArg.
			self success: (self cCode: 'shifted >> integerArg') = integerRcvr.
		] ifFalse: [
			"Right shift -- OK to lose bits"
			self success: integerArg > -64.
			shifted := self cCode: 'integerRcvr >> (0 - integerArg)'. "right shift coerces to usqInt"
		].
	].
	successFlag ifFalse:[^nil].
	oopResult := self signed64BitIntegerFor: shifted.
	successFlag ifTrue:[self pop: 2 thenPush: oopResult].

]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveBitXor [
	| integerReceiver integerArgument |
	integerArgument := self popPos32BitInteger.
	integerReceiver := self popPos32BitInteger.
	successFlag
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitXor: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveBitXorLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| integerRcvr integerArg oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self positive64BitValueOf: (self stackValue: 0).
	integerRcvr := self positive64BitValueOf: (self stackValue: 1).
	successFlag ifFalse:[^nil].

	oopResult := self positive64BitIntegerFor: (integerRcvr bitXor: integerArg).
	successFlag ifTrue:[self pop: 2 thenPush: oopResult].

]

{ #category : #'control primitives' }
Interpreter >> primitiveBlockCopy [

	| context methodContext contextSize newContext initialIP |
	context := self stackValue: 1.
	(self isIntegerObject: (self fetchPointer: MethodIndex ofObject: context))
		ifTrue: ["context is a block; get the context of its enclosing method"
				methodContext := self fetchPointer: HomeIndex ofObject: context]
		ifFalse: [methodContext := context].
	contextSize := self sizeBitsOf: methodContext.  "in bytes, including header"
	context := nil.  "context is no longer needed and is not preserved across allocation"

	"remap methodContext in case GC happens during allocation"
	self pushRemappableOop: methodContext.
	newContext := self instantiateContext: (self splObj: ClassBlockContext) sizeInBytes: contextSize.
	methodContext := self popRemappableOop.

	initialIP := self integerObjectOf: (instructionPointer+1+3) - (method + self baseHeaderSize).
	"Was instructionPointer + 3, but now it's greater by 1 due to preIncrement"

	"Assume: have just allocated a new context; it must be young.
	 Thus, can use uncheck stores. See the comment in fetchContextRegisters."

	self storePointerUnchecked: InitialIPIndex ofObject: newContext withValue: initialIP.
	self storePointerUnchecked: InstructionPointerIndex ofObject: newContext withValue: initialIP.
	self storeStackPointerValue: 0 inContext: newContext.
	self storePointerUnchecked: BlockArgumentCountIndex ofObject: newContext withValue: (self stackValue: 0).
	self storePointerUnchecked: HomeIndex ofObject: newContext withValue: methodContext.
	self storePointerUnchecked: SenderIndex ofObject: newContext withValue: nilObj.

	self pop: 2 thenPush: newContext.
]

{ #category : #'memory space primitives' }
Interpreter >> primitiveBytesLeft [
	"Reports bytes available at this moment. For more meaningful 
	results, calls to this primitive should be preceeded by a full 
	or incremental garbage collection."
	| aBool |
	self methodArgumentCount = 0
		ifTrue: ["old behavior - just return the size of the free block"
			^self pop: 1 thenPush: (self positive64BitIntegerFor: (self sizeOfFree: freeBlock))].
	self methodArgumentCount = 1
		ifTrue: ["new behaviour -including or excluding swap space depending on aBool"
			aBool := self booleanValueOf: self stackTop.
			successFlag ifFalse: [^ nil].
			^self pop: 2 thenPush: (self positive64BitIntegerFor: (self bytesLeft: aBool))].
	^ self primitiveFail
]

{ #category : #'message sending' }
Interpreter >> primitiveCalloutToFFI [
	"Perform a function call to a foreign function.
	Only invoked from method containing explicit external call spec.
	Due to this we use the pluggable prim mechanism explicitly here
	(the first literal of any FFI spec'ed method is an ExternalFunction
	and not an array as used in the pluggable primitive mechanism)."

	| function moduleName functionName |
	<var: #function declareC: 'static void *function = 0'>
	<var: #moduleName declareC: 'static char *moduleName = "SqueakFFIPrims"'>
	<var: #functionName declareC: 'static char *functionName = "primitiveCallout"'>
	function = 0 ifTrue: [
		function := self
			ioLoadExternalFunction: (self oopForPointer: functionName)
			OfLength: 16
			FromModule: (self oopForPointer: moduleName)
			OfLength: 14.
		function == 0 ifTrue: [^self primitiveFail]].
	^self cCode: '((sqInt (*)(void))function)()'.

]

{ #category : #'object access primitives' }
Interpreter >> primitiveChangeClass [
	"Primitive. Change the class of the receiver into the class of the argument given that the format of the receiver matches the format of the argument's class. Fail if receiver or argument are SmallIntegers, or the receiver is an instance of a compact class and the argument isn't, or when the argument's class is compact and the receiver isn't, or when the format of the receiver is different from the format of the argument's class, or when the arguments class is fixed and the receiver's size differs from the size that an instance of the argument's class should have."
	| arg rcvr argClass |

	self methodArgumentCount = 1 ifFalse: [self primitiveFail. ^ nil].

	arg := self stackObjectValue: 0.
	rcvr := self stackObjectValue: 1.
	argClass := self fetchClassOf: arg.
	self changeClassOf: rcvr to: argClass.
	successFlag ifTrue: [ self pop: 1 ].
	^ nil.

]

{ #category : #'object access primitives' }
Interpreter >> primitiveChangeClassWithClass [
	"Primitive. Change the class of the receiver into the class of the argument given that the format of the receiver matches the format of the argument's class. Fail if receiver or argument are SmallIntegers, or the receiver is an instance of a compact class and the argument isn't, or when the argument's class is compact and the receiver isn't, or when the format of the receiver is different from the format of the argument's class, or when the arguments class is fixed and the receiver's size differs from the size that an instance of the argument's class should have."
	| rcvr argClass |
	<export: true>
	self methodArgumentCount = 1 ifFalse: [self primitiveFail. ^ nil].

	argClass := self stackObjectValue: 0.
	rcvr := self stackObjectValue: 1.

	self changeClassOf: rcvr to: argClass.
	successFlag ifTrue: [ self pop: 1 ].
	^ nil.

]

{ #category : #'object access primitives' }
Interpreter >> primitiveClass [
	| instance |
	instance := self stackTop.
	self pop: argumentCount+1 thenPush: (self fetchClassOf: instance)
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveClipboardText [
	"When called with a single string argument, post the string to 
	the clipboard. When called with zero arguments, return a 
	string containing the current clipboard contents."
	| s sz |
	argumentCount = 1
		ifTrue: [s := self stackTop.
			(self isBytes: s) ifFalse: [^ self primitiveFail].
			successFlag
				ifTrue: [sz := self stSizeOf: s.
					self clipboardWrite: sz From: s + self baseHeaderSize At: 0.
					self pop: 1]]
		ifFalse: [sz := self clipboardSize.
			(self sufficientSpaceToAllocate: sz) ifFalse:[^self primitiveFail].
			s := self instantiateClass: (self splObj: ClassString) indexableSize: sz.
			self clipboardRead: sz Into: s + self baseHeaderSize At: 0.
			self pop: 1 thenPush: s]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveClone [
	"Return a shallow copy of the receiver."

	| newCopy |
	newCopy := self clone: (self stackTop).
	newCopy = 0
		ifTrue:["not enough memory most likely" ^self primitiveFail].
	self pop: 1 thenPush: newCopy.
]

{ #category : #'control primitives' }
Interpreter >> primitiveClosureCopyWithCopiedValues [
	| newClosure copiedValues numCopiedValues numArgs |
	numArgs := self stackIntegerValue: 1.
	copiedValues := self stackTop.
	self success: (self fetchClassOf: copiedValues) = (self splObj: ClassArray).
	successFlag ifFalse:
		[^self primitiveFail].
	numCopiedValues := self fetchWordLengthOf: copiedValues.
	newClosure := self
					closureNumArgs: numArgs
									"greater by 1 due to preIncrement of localIP"
					instructionPointer: instructionPointer + 2 - (method + self baseHeaderSize)
					numCopiedValues: numCopiedValues.
	"Assume: have just allocated a new closure; it must be young. Thus, can use unchecked stores."
	self storePointerUnchecked: ClosureOuterContextIndex ofObject: newClosure withValue: (self stackValue: 2).
	numCopiedValues > 0 ifTrue:
		["Allocation may have done a GC and copiedValues may have moved."
		 copiedValues := self stackTop.
		 0 to: numCopiedValues - 1 do:
			[:i|
			"Assume: have just allocated a new BlockClosure; it must be young.
			 Thus, can use unchecked stores."
			 self storePointerUnchecked: i + ClosureFirstCopiedValueIndex
				ofObject: newClosure
				withValue: (self fetchPointer: i ofObject: copiedValues)]].
	self pop: 3 thenPush: newClosure
]

{ #category : #'control primitives' }
Interpreter >> primitiveClosureValue [
	| blockClosure blockArgumentCount closureMethod outerContext |
	blockClosure := self stackValue: argumentCount.
	blockArgumentCount := self argumentCountOfClosure: blockClosure.
	argumentCount = blockArgumentCount ifFalse:
		[^self primitiveFail].

	"Somewhat paranoiac checks we need while debugging that we may be able to discard
	 in a robust system."
	outerContext := self fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	(self isContext: outerContext) ifFalse:
		[^self primitiveFail].
	closureMethod := self fetchPointer: MethodIndex ofObject: outerContext.
	"Check if the closure's method is actually a CompiledMethod."
	(self isOopCompiledMethod: closureMethod) ifFalse:
		[^self primitiveFail].

	self activateNewClosureMethod: blockClosure.
	self quickCheckForInterrupts
]

{ #category : #'control primitives' }
Interpreter >> primitiveClosureValueNoContextSwitch [
	"An exact clone of primitiveClosureValue except that this version will not
	 check for interrupts on stack overflow."
	| blockClosure blockArgumentCount closureMethod outerContext |
	blockClosure := self stackValue: argumentCount.
	blockArgumentCount := self argumentCountOfClosure: blockClosure.
	argumentCount = blockArgumentCount ifFalse:
		[^self primitiveFail].

	"Somewhat paranoiac checks we need while debugging that we may be able to discard
	 in a robust system."
	outerContext := self fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	(self isContext: outerContext) ifFalse:
		[^self primitiveFail].
	closureMethod := self fetchPointer: MethodIndex ofObject: outerContext.
	"Check if the closure's method is actually a CompiledMethod."
	(self isOopCompiledMethod: closureMethod) ifFalse:
		[^self primitiveFail].

	self activateNewClosureMethod: blockClosure
]

{ #category : #'control primitives' }
Interpreter >> primitiveClosureValueWithArgs [
	| argumentArray arraySize cntxSize blockClosure blockArgumentCount closureMethod index outerContext |
	argumentArray := self stackTop.
	(self isArray: argumentArray) ifFalse:
		[^self primitiveFail].

	"Check for enough space in thisContext to push all args"
	arraySize := self fetchWordLengthOf: argumentArray.
	cntxSize := self fetchWordLengthOf: activeContext.
	(self stackPointerIndex + arraySize) < cntxSize ifFalse:
		[^self primitiveFail].

	blockClosure := self stackValue: argumentCount.
	blockArgumentCount := self argumentCountOfClosure: blockClosure.
	arraySize = blockArgumentCount ifFalse:
		[^self primitiveFail].

	"Somewhat paranoiac checks we need while debugging that we may be able to discard
	 in a robust system."
	outerContext := self fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	(self isContext: outerContext) ifFalse:
		[^self primitiveFail].
	closureMethod := self fetchPointer: MethodIndex ofObject: outerContext.
	"Check if the closure's method is actually a CompiledMethod."
	(self isOopCompiledMethod: closureMethod) ifFalse:
		[^self primitiveFail].

	self popStack.

	"Copy the arguments to the stack, and activate"
	index := 1.
	[index <= arraySize]
		whileTrue:
		[self push: (self fetchPointer: index - 1 ofObject: argumentArray).
		index := index + 1].

	argumentCount := arraySize.
	self activateNewClosureMethod: blockClosure.
	self quickCheckForInterrupts
]

{ #category : #'array primitives' }
Interpreter >> primitiveConstantFill [
	"Fill the receiver, which must be an indexable bytes or words 
	objects, with the given integer value."
	| fillValue rcvr rcvrIsBytes end i |
	<var: #end type: 'usqInt'>
	<var: #i type: 'usqInt'>
	fillValue := self positive32BitValueOf: self stackTop.
	rcvr := self stackValue: 1.
	self success: (self isWordsOrBytes: rcvr).
	rcvrIsBytes := self isBytes: rcvr.
	rcvrIsBytes ifTrue: [self success: (fillValue >= 0 and: [fillValue <= 255])].
	successFlag
		ifTrue: [end := rcvr + (self sizeBitsOf: rcvr).
			i := rcvr + self baseHeaderSize.
			rcvrIsBytes
				ifTrue: [[i < end]
						whileTrue: [self byteAt: i put: fillValue.
							i := i + 1]]
				ifFalse: [[i < end]
						whileTrue: [self long32At: i put: fillValue.
							i := i + 4]].
			self pop: 1]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveCopyObject [
	"Primitive. Copy the state of the receiver from the argument. 
		Fail if receiver and argument are of a different class. 
		Fail if the receiver or argument are non-pointer objects.
		Fail if receiver and argument have different lengths (for indexable objects).
	"
	| rcvr arg length |
	self methodArgumentCount = 1 ifFalse:[^self primitiveFail].
	arg := self stackObjectValue: 0.
	rcvr := self stackObjectValue: 1.

	self failed ifTrue:[^nil].
	(self isPointers: rcvr) ifFalse:[^self primitiveFail].
	(self fetchClassOf: rcvr) = (self fetchClassOf: arg) ifFalse:[^self primitiveFail].
	length := self lengthOf: rcvr.
	length = (self lengthOf: arg) ifFalse:[^self primitiveFail].
	
	"Now copy the elements"
	0 to: length-1 do:[:i|
		self storePointer: i ofObject: rcvr withValue: (self fetchPointer: i ofObject: arg)].

	"Note: The above could be faster for young receivers but I don't think it'll matter"
	self pop: 1. "pop arg; answer receiver"

]

{ #category : #'I/O primitives' }
Interpreter >> primitiveDeferDisplayUpdates [
	"Set or clear the flag that controls whether modifications of 
	the Display object are propagated to the underlying 
	platform's screen."
	| flag |
	flag := self stackTop.
	flag = trueObj
		ifTrue: [deferDisplayUpdates := true]
		ifFalse: [flag = falseObj
				ifTrue: [deferDisplayUpdates := false]
				ifFalse: [self primitiveFail]].
	successFlag
		ifTrue: [self pop: 1]
]

{ #category : #'system control primitives' }
Interpreter >> primitiveDisablePowerManager [
	"Pass in a non-negative value to disable the architectures powermanager if any, zero to enable. This is a named (not numbered) primitive in the null module (ie the VM)"

	| integer |
	<export: true>
	integer := self stackIntegerValue: 0.
	successFlag ifTrue: [
		self ioDisablePowerManager: integer.
		self pop: 1].  "integer; leave rcvr on stack"

]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveDiv [
	| quotient |
	quotient := self doPrimitiveDiv: (self stackValue: 1) by: (self stackTop).
	self pop2AndPushIntegerIfOK: quotient
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveDivLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| integerRcvr integerArg result posArg posRcvr oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'posRcvr' type: 'sqLong'>
	<var: 'posArg' type: 'sqLong'>
	<var: 'result' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).
	integerArg = 0 ifTrue:[self primitiveFail].
	successFlag ifFalse:[^nil].

	integerRcvr > 0
		ifTrue: [integerArg > 0
					ifTrue: [result := integerRcvr // integerArg]
					ifFalse: ["round negative result toward negative infinity"
							posArg := 0 - integerArg.
							posRcvr := integerRcvr + (posArg - 1). "can overflow!"
							posRcvr < 0 ifTrue:[self primitiveFail].
							result := 0 - (posRcvr // posArg)]]
		ifFalse: [posRcvr := 0 - integerRcvr.
				integerArg > 0
					ifTrue: ["round negative result toward negative infinity"
							posRcvr := posRcvr + (integerArg - 1). "can overflow!"
							posRcvr < 0 ifTrue:[self primitiveFail].
							result := 0 - (posRcvr // integerArg)]
					ifFalse: [posArg := 0 - integerArg.
							result := posRcvr // posArg]].
	successFlag ifTrue:[oopResult := self signed64BitIntegerFor: result].
	successFlag ifTrue:[self pop: 2 thenPush: oopResult].

]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveDivide [
	| integerReceiver integerArgument |
	integerReceiver := self stackIntegerValue: 1.
	integerArgument := self stackIntegerValue: 0.
	(integerArgument ~= 0 and: [integerReceiver \\ integerArgument = 0])
		ifTrue: [self pop2AndPushIntegerIfOK: integerReceiver // integerArgument]
		ifFalse: [self primitiveFail]
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveDivideLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| integerRcvr integerArg result oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'result' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).
	(integerArg ~= 0 and:[integerRcvr \\ integerArg = 0]) ifFalse:[self primitiveFail].
	successFlag ifFalse:[^nil].
	result := integerRcvr // integerArg.
	oopResult := self signed64BitIntegerFor: result.
	successFlag ifTrue:[self pop: 2 thenPush: oopResult].

]

{ #category : #'control primitives' }
Interpreter >> primitiveDoPrimitiveWithArgs [
	| argumentArray arraySize index cntxSize primIdx |
	argumentArray := self stackTop.
	arraySize := self fetchWordLengthOf: argumentArray.
	cntxSize := self fetchWordLengthOf: activeContext.
	self success: self stackPointerIndex + arraySize < cntxSize.
	(self isArray: argumentArray) ifFalse: [^ self primitiveFail].

	primIdx := self stackIntegerValue: 1.
	successFlag ifFalse: [^ self primitiveFail]. "invalid args"

	"Pop primIndex and argArray, then push args in place..."
	self pop: 2.
	primitiveIndex := primIdx.
	argumentCount := arraySize.
	index := 1.
	[index <= argumentCount]
		whileTrue: [self push: (self fetchPointer: index - 1 ofObject: argumentArray).
			index := index + 1].

	"Run the primitive (sets successFlag)"
	self pushRemappableOop: argumentArray. "prim might alloc/gc"
	lkupClass := nilObj.
	self primitiveResponse.
	argumentArray := self popRemappableOop.
	successFlag
		ifFalse: ["If primitive failed, then restore state for failure code"
			self pop: arraySize.
			self pushInteger: primIdx.
			self push: argumentArray.
			argumentCount := 2]
]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveEqual [
	| integerReceiver integerArgument result |
	integerArgument := self popStack.
	integerReceiver := self popStack.
	result := self compare31or32Bits: integerReceiver equal: integerArgument.
	self checkBooleanResult: result
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveEqualLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	successFlag ifTrue:[
		self pop: 2.
		self pushBool: integerRcvr = integerArg
	].

]

{ #category : #'object access primitives' }
Interpreter >> primitiveEquivalent [
"is the receiver the same object as the argument?"
	| thisObject otherObject |
	otherObject := self popStack.
	thisObject := self popStack.
	self pushBool: thisObject = otherObject
]

{ #category : #'control primitives' }
Interpreter >> primitiveExecuteMethod [
	"receiver, args, then method are on top of stack. Execute method against receiver and args"
	newMethod := self popStack.
	primitiveIndex := self primitiveIndexOf: newMethod.
	self success: argumentCount - 1 = (self argumentCountOf: newMethod).
	successFlag
		ifTrue: [argumentCount := argumentCount - 1.
			self executeNewMethod]
		ifFalse: [self unPop: 1]
]

{ #category : #'control primitives' }
Interpreter >> primitiveExecuteMethodArgsArray [
	"receiver, argsArray, then method are on top of stack.  Execute method against receiver and args"

	| methodArgument argCnt argumentArray |
	methodArgument := self popStack.
	argumentArray := self popStack.
	((self isOopCompiledMethod: methodArgument)
	 and: [self isArray: argumentArray]) ifFalse:
		[self unPop: 2. ^self primitiveFail].
	argCnt := self argumentCountOf: methodArgument.
	argCnt = (self fetchWordLengthOf: argumentArray) ifFalse:
		[self unPop: 2. ^self primitiveFail].
	self transfer: argCnt from: argumentArray + self baseHeaderSize to: stackPointer + self bytesPerWord.
	self unPop: argCnt.
	newMethod := methodArgument.
	primitiveIndex := self primitiveIndexOf: newMethod.
	argumentCount := argCnt.
	self executeNewMethod.
	"Recursive xeq affects successFlag"
	successFlag := true
]

{ #category : #'system control primitives' }
Interpreter >> primitiveExitToDebugger [

	self error: 'Exit to debugger at user request'.
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveExp [
	"Computes E raised to the receiver power."

	| rcvr |
	<var: #rcvr type: 'double '>
	rcvr := self popFloat.
	successFlag
		ifTrue: [self pushFloat: (self cCode: 'exp(rcvr)' inSmalltalk: [rcvr exp])]
		ifFalse: [self unPop: 1]
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveExponent [
	"Exponent part of this float."

	| rcvr frac pwr |
	<var: #rcvr type: 'double '>
	<var: #frac type: 'double '>
	<var: #pwr type: 'int '>
	rcvr := self popFloat.
	successFlag
		ifTrue: [  "rcvr = frac * 2^pwr, where frac is in [0.5..1.0)"
			self cCode: 'frac = frexp(rcvr, &pwr)'
					inSmalltalk: [pwr := rcvr exponent].
			self pushInteger: pwr - 1]
		ifFalse: [self unPop: 1].
]

{ #category : #'plugin primitives' }
Interpreter >> primitiveExternalCall [
	"Call an external primitive. The external primitive methods 
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
	"
	| lit addr moduleName functionName moduleLength functionLength index |
	<var: #addr type: 'void *'>
	
	"Fetch the first literal of the method"
	self success: (self literalCountOf: newMethod) > 0. "@@: Could this be omitted for speed?!"
	successFlag ifFalse: [^ nil].

	lit := self literal: 0 ofMethod: newMethod. 
	"Check if it's an array of length 4"
	self success: ((self isArray: lit) and: [(self lengthOf: lit) = 4]).
	successFlag ifFalse: [^ nil].

	"Look at the function index in case it has been loaded before"
	index := self fetchPointer: 3 ofObject: lit.
	index := self checkedIntegerValueOf: index.
	successFlag ifFalse: [^ nil].
	"Check if we have already looked up the function and failed."
	index < 0
		ifTrue: ["Function address was not found in this session, 
			Rewrite the mcache entry with a zero primitive index."
			self
				rewriteMethodCacheSel: messageSelector
				class: lkupClass
				primIndex: 0.
			^ self success: false].

	"Try to call the function directly"
	(index > 0 and: [index <= MaxExternalPrimitiveTableSize])
		ifTrue: [addr := externalPrimitiveTable at: index - 1.
			addr ~= 0
				ifTrue: [self rewriteMethodCacheSel: messageSelector class: lkupClass primIndex: (1000 + index) primFunction: addr.
					self callExternalPrimitive: addr.
					^ nil].
			"if we get here, then an index to the external prim was 
			kept on the ST side although the underlying prim 
			table was already flushed"
			^ self primitiveFail].

	"Clean up session id and external primitive index"
	self storePointerUnchecked: 2 ofObject: lit withValue: ConstZero.
	self storePointerUnchecked: 3 ofObject: lit withValue: ConstZero.

	"The function has not been loaded yet. Fetch module and function name."
	moduleName := self fetchPointer: 0 ofObject: lit.
	moduleName = nilObj
		ifTrue: [moduleLength := 0]
		ifFalse: [self success: (self isBytes: moduleName).
				moduleLength := self lengthOf: moduleName.
				self cCode: '' inSmalltalk:
					[ (#('FloatArrayPlugin' 'Matrix2x3Plugin') includes: (self stringOf: moduleName))
						ifTrue: [moduleLength := 0  "Cause all of these to fail"]]].
	functionName := self fetchPointer: 1 ofObject: lit.
	self success: (self isBytes: functionName).
	functionLength := self lengthOf: functionName.
	successFlag ifFalse: [^ nil].

	addr := self ioLoadExternalFunction: functionName + self baseHeaderSize
				OfLength: functionLength
				FromModule: moduleName + self baseHeaderSize
				OfLength: moduleLength.
	addr = 0
		ifTrue: [index := -1]
		ifFalse: ["add the function to the external primitive table"
			index := self addToExternalPrimitiveTable: addr].
	self success: index >= 0.
	"Store the index (or -1 if failure) back in the literal"
	self storePointerUnchecked: 3 ofObject: lit withValue: (self integerObjectOf: index).

	"If the function has been successfully loaded process it"
	(successFlag and: [addr ~= 0])
		ifTrue: [self rewriteMethodCacheSel: messageSelector class: lkupClass primIndex: (1000 + index) primFunction: addr.
				self callExternalPrimitive: addr]
		ifFalse: ["Otherwise rewrite the primitive index"
			self
				rewriteMethodCacheSel: messageSelector
				class: lkupClass
				primIndex: 0]
]

{ #category : #'primitive support' }
Interpreter >> primitiveFail [

	successFlag := false.
]

{ #category : #'image segment in/out' }
Interpreter >> primitiveFailAfterCleanup: outPointerArray [
	"If the storeSegment primitive fails, it must clean up first."

	| i lastAddr |   "Store nils throughout the outPointer array."
	lastAddr := outPointerArray + (self lastPointerOf: outPointerArray).
	i := outPointerArray + self baseHeaderSize.
	[i <= lastAddr] whileTrue:
		[self longAt: i put: nilObj.
		i := i + self bytesPerWord].

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	self primitiveFail
]

{ #category : #'primitive support' }
Interpreter >> primitiveFailFor: reasonCode [
	"Set specific primitive failure."
	primFailCode := reasonCode.
	self primitiveFail.
]

{ #category : #'process primitives' }
Interpreter >> primitiveFindHandlerContext [
	"Primitive. Search up the context stack for the next method context marked for exception handling starting at the receiver. Return nil if none found"
	| thisCntx nilOop |
	thisCntx := self popStack.
	nilOop := nilObj.

	[(self isHandlerMarked: thisCntx) ifTrue:[
			self push: thisCntx.
			^nil].
		thisCntx := self fetchPointer: SenderIndex ofObject: thisCntx.
		thisCntx = nilOop] whileFalse.

	^self push: nilObj
]

{ #category : #'process primitives' }
Interpreter >> primitiveFindNextUnwindContext [
	"Primitive. Search up the context stack for the next method context marked for unwind handling from the receiver up to but not including the argument. Return nil if none found."
	| thisCntx nilOop aContext unwindMarked |
	aContext := self popStack.
	thisCntx := self fetchPointer: SenderIndex ofObject: self popStack.
	nilOop := nilObj.

	[(thisCntx = aContext) or: [thisCntx = nilOop]] whileFalse: [
		unwindMarked := self isUnwindMarked: thisCntx.
		unwindMarked ifTrue:[
			self push: thisCntx.
			^nil].
		thisCntx := self fetchPointer: SenderIndex ofObject: thisCntx].

	^self push: nilOop
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatAdd [
	^ self primitiveFloatAdd: (self stackValue: 1) toArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatAdd: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	<var: #arg type: 'double '>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [
		self pop: 2.
		self pushFloat: rcvr + arg].
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatDivide [
	^ self primitiveFloatDivide: (self stackValue: 1) byArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatDivide: rcvrOop byArg: argOop [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	<var: #arg type: 'double '>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [
		self success: arg ~= 0.0.
		successFlag ifTrue: [
			self pop: 2.
			self pushFloat: (self cCode: 'rcvr / arg' inSmalltalk: [rcvr / arg])]].
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatEqual [
	| aBool |
	aBool := self primitiveFloatEqual: (self stackValue: 1) toArg: self stackTop.
	successFlag ifTrue: [self pop: 2. self pushBool: aBool].

]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	<var: #arg type: 'double '>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [^ rcvr = arg]
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatGreater: rcvrOop thanArg: argOop [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	<var: #arg type: 'double '>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [^ rcvr > arg].

]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatGreaterOrEqual [
	| aBool |
	aBool := self primitiveFloatGreaterOrEqual: (self stackValue: 1) toArg: self stackTop.
	successFlag ifTrue: [self pop: 2. self pushBool: aBool].
]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatGreaterOrEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	<var: #arg type: 'double '>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [^ rcvr >= arg].

]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatGreaterThan [
	| aBool |
	aBool := self primitiveFloatGreater: (self stackValue: 1) thanArg: self stackTop.
	successFlag ifTrue: [self pop: 2. self pushBool: aBool].

]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatLess: rcvrOop thanArg: argOop [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	<var: #arg type: 'double '>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [^ rcvr < arg].

]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatLessOrEqual [
	| aBool |
	aBool := self primitiveFloatLessOrEqual: (self stackValue: 1) toArg: self stackTop.
	successFlag ifTrue: [self pop: 2. self pushBool: aBool].
]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatLessOrEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	<var: #arg type: 'double '>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [^ rcvr <= arg].

]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatLessThan [
	| aBool |
	aBool := self primitiveFloatLess: (self stackValue: 1) thanArg: self stackTop.
	successFlag ifTrue: [self pop: 2. self pushBool: aBool].

]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatMultiply [
	^ self primitiveFloatMultiply: (self stackValue: 1) byArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatMultiply: rcvrOop byArg: argOop [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	<var: #arg type: 'double '>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [
		self pop: 2.
		self pushFloat: rcvr * arg].
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatNotEqual [
	| aBool |
	aBool := self primitiveFloatEqual: (self stackValue: 1) toArg: self stackTop.
	successFlag ifTrue: [self pop: 2. self pushBool: aBool not].

]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatSubtract [
	^ self primitiveFloatSubtract: (self stackValue: 1) fromArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFloatSubtract: rcvrOop fromArg: argOop [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	<var: #arg type: 'double '>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [
		self pop: 2.
		self pushFloat: rcvr - arg].
]

{ #category : #'system control primitives' }
Interpreter >> primitiveFlushCache [
	"Clear the method lookup cache. This must be done after every programming change."

	self flushMethodCache.
	self compilerFlushCacheHook: nil.		"Flush the dynamic compiler's inline caches."

]

{ #category : #'system control primitives' }
Interpreter >> primitiveFlushCacheByMethod [
	"The receiver is a compiledMethod.  Clear all entries in the method lookup cache that refer to this method, presumably because it has been redefined, overridden or removed."
	| probe oldMethod |
	oldMethod := self stackTop.
	probe := 0.
	1 to: MethodCacheEntries do:
		[:i | (methodCache at: probe + MethodCacheMethod) = oldMethod ifTrue:
			[methodCache at: probe + MethodCacheSelector put: 0].
		probe := probe + MethodCacheEntrySize].
	self compilerFlushCacheHook: oldMethod.		"Flush the dynamic compiler's inline caches."
]

{ #category : #'system control primitives' }
Interpreter >> primitiveFlushCacheSelective [
	"The receiver is a message selector.  Clear all entries in the method lookup cache with this selector, presumably because an associated method has been redefined."
	| selector probe |
	selector := self stackTop.
	probe := 0.
	1 to: MethodCacheEntries do:
		[:i | (methodCache at: probe + MethodCacheSelector) = selector ifTrue:
			[methodCache at: probe + MethodCacheSelector put: 0].
		probe := probe + MethodCacheEntrySize]
]

{ #category : #'plugin primitives' }
Interpreter >> primitiveFlushExternalPrimitives [
	"Primitive. Flush all the existing external primitives in the image thus forcing a reload on next invokation."
	^self flushExternalPrimitives
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveForceDisplayUpdate [
	"On some platforms, this primitive forces enqueued display updates to be processed immediately. On others, it does nothing."

	self ioForceDisplayUpdate.

]

{ #category : #'I/O primitives' }
Interpreter >> primitiveForceTenure [
	"Set force tenure flag to true, this forces a tenure operation on the next incremental GC"

	<export: true>
	forceTenureFlag := 1
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveFormPrint [
	"On platforms that support it, this primitive prints the receiver, assumed to be a Form, to the default printer."

	| landscapeFlag vScale hScale rcvr bitsArray w h
	 depth pixelsPerWord wordsPerLine bitsArraySize ok |

	<var: #vScale type: 'double '>
	<var: #hScale type: 'double '>
	landscapeFlag := self booleanValueOf: self stackTop.
	vScale := self floatValueOf: (self stackValue: 1).
	hScale := self floatValueOf: (self stackValue: 2).
	rcvr := self stackValue: 3.
	(rcvr isIntegerObject: rcvr) ifTrue: [self success: false].
	successFlag ifTrue: [
		((self  isPointers: rcvr) and: [(self lengthOf: rcvr) >= 4])
			ifFalse: [self success: false]].
	successFlag ifTrue: [
		bitsArray := self fetchPointer: 0 ofObject: rcvr.
		w := self fetchInteger: 1 ofObject: rcvr.
		h := self fetchInteger: 2 ofObject: rcvr.
		depth := self fetchInteger: 3 ofObject: rcvr.
		(w > 0 and: [h > 0]) ifFalse: [self success: false].
		pixelsPerWord := 32 // depth.
		wordsPerLine := (w + (pixelsPerWord - 1)) // pixelsPerWord.
		((rcvr isIntegerObject: rcvr) not and: [self isWordsOrBytes: bitsArray])
			ifTrue: [
				bitsArraySize := self byteLengthOf: bitsArray.
				self success: (bitsArraySize = (wordsPerLine * h * 4))]
			ifFalse: [self success: false]].	
	successFlag ifTrue: [
		self bytesPerWord = 8
			ifTrue: [ok := self cCode: 'ioFormPrint(bitsArray + 8, w, h, depth, hScale, vScale, landscapeFlag)']
			ifFalse: [ok := self cCode: 'ioFormPrint(bitsArray + 4, w, h, depth, hScale, vScale, landscapeFlag)'].
		self success: ok].
	successFlag ifTrue: [
		self pop: 3].  "pop hScale, vScale, and landscapeFlag; leave rcvr on stack"

]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveFractionalPart [
	| rcvr frac trunc |
	<var: #rcvr type: 'double '>
	<var: #frac type: 'double '>
	<var: #trunc type: 'double '>
	rcvr := self popFloat.
	successFlag
		ifTrue: [self cCode: 'frac = modf(rcvr, &trunc)' inSmalltalk: [frac := rcvr fractionPart].
				self pushFloat: frac]
		ifFalse: [self unPop: 1]
]

{ #category : #'memory space primitives' }
Interpreter >> primitiveFullGC [
	"Do a full garbage collection and return the number of bytes available (including swap space if dynamic memory management is supported)."

	self pop: 1.
	self incrementalGC.  "maximimize space for forwarding table"
	self fullGC.
	self push: (self positive64BitIntegerFor: (self bytesLeft: true))

]

{ #category : #'system control primitives' }
Interpreter >> primitiveGetAttribute [
	"Fetch the system attribute with the given integer ID. The 
	result is a string, which will be empty if the attribute is not 
	defined."
	| attr sz s |
	attr := self stackIntegerValue: 0.
	successFlag
		ifTrue: [sz := self attributeSize: attr].
	successFlag
		ifTrue: [s := self
						instantiateClass: (self splObj: ClassString)
						indexableSize: sz.
			self
				getAttribute: attr
				Into: s + self baseHeaderSize
				Length: sz.
			self pop: 2 thenPush: s]
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveGetNextEvent [
	"Primitive. Return the next input event from the VM event queue."
	| evtBuf arg value eventTypeIs |
	<var: #evtBuf declareC: 'int evtBuf[8] = { 0, 0, 0, 0, 0, 0, 0, 0 }'>
	self cCode:'' inSmalltalk:[evtBuf := CArrayAccessor on: (IntegerArray new: 8)].
	arg := self stackTop.
	((self isArray: arg) and:[(self slotSizeOf: arg) = 8])  ifFalse:[^self primitiveFail].

	self ioGetNextEvent: (self cCoerce: evtBuf to: 'sqInputEvent*').
	successFlag ifFalse:[^nil].

	"Event type"
	eventTypeIs := evtBuf at: 0.
	self storeInteger: 0 ofObject: arg withValue: (evtBuf at: 0).
	successFlag ifFalse:[^nil].

	"Event is Complex, assume evtBuf is populated correctly and return"
	eventTypeIs = 6 ifTrue: 
		[1 to: 7 do: [:i |
			value := evtBuf at: i.
			self storePointer: i ofObject: arg withValue: value]]
	ifFalse: [
		"Event time stamp"
		self storeInteger: 1 ofObject: arg withValue: ((evtBuf at: 1) bitAnd: MillisecondClockMask).
		successFlag ifFalse:[^nil].

		"Event arguments"
		2 to: 7 do:[:i|
			value := evtBuf at: i.
			(self isIntegerValue: value)
				ifTrue:[self storeInteger: i ofObject: arg withValue: value]
				ifFalse:["Need to remap because allocation may cause GC"
					self pushRemappableOop: arg.
					value := self positive32BitIntegerFor: value.
					arg := self popRemappableOop.
					self storePointer: i ofObject: arg withValue: value]]].
	successFlag ifFalse:[^nil].
	self pop: 1.
]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveGreaterOrEqual [
	| integerReceiver integerArgument |
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver >= integerArgument
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveGreaterOrEqualLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	successFlag ifTrue:[
		self pop: 2.
		self pushBool: integerRcvr >= integerArg
	].

]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveGreaterThan [
	| integerReceiver integerArgument |
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver > integerArgument
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveGreaterThanLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	successFlag ifTrue:[
		self pop: 2.
		self pushBool: integerRcvr > integerArg
	].

]

{ #category : #'other primitives' }
Interpreter >> primitiveImageFormatVersion [
	"Answer an integer identifying the type of image. The image version number may
	identify the format of the image (e.g. 32 or 64-bit word size) or specific requirements
	of the image (e.g. block closure support required).
	
	This is a named (not numbered) primitive in the null module (ie the VM)"

	<export: true>
	self pop: 1 thenPush: (self positive32BitIntegerFor: self imageFormatVersion)

]

{ #category : #'other primitives' }
Interpreter >> primitiveImageName [
	"When called with a single string argument, record the string as the current image file name. When called with zero arguments, return a string containing the current image file name."

	| s sz sCRIfn okToRename |
	<var: #sCRIfn type: 'void *'>
	argumentCount = 1 ifTrue: [
		"If the security plugin can be loaded, use it to check for rename permission.
		If not, assume it's ok"
		sCRIfn := self ioLoadFunction: 'secCanRenameImage' From: 'SecurityPlugin'.
		sCRIfn ~= 0 ifTrue:[okToRename := self cCode:' ((sqInt (*)(void))sCRIfn)()'.
			okToRename ifFalse:[^self primitiveFail]].
		s := self stackTop.
		self assertClassOf: s is: (self splObj: ClassString).
		successFlag ifTrue: [
			sz := self stSizeOf: s.
			self imageNamePut: (s + self baseHeaderSize) Length: sz.
			self pop: 1.  "pop s, leave rcvr on stack"
		].
	] ifFalse: [
		sz := self imageNameSize.
		s := self instantiateClass: (self splObj: ClassString) indexableSize: sz.
		self imageNameGet: (s + self baseHeaderSize) Length: sz.
		self pop: 1.  "rcvr"
		self push: s.
	].

]

{ #category : #'memory space primitives' }
Interpreter >> primitiveIncrementalGC [
	"Do a quick, incremental garbage collection and return the number of bytes immediately available. (Note: more space may be made available by doing a full garbage collection."

	self pop: 1.
	self incrementalGC.
	self push: (self positive64BitIntegerFor: (self bytesLeft: false))

]

{ #category : #'compiled methods' }
Interpreter >> primitiveIndexOf: methodPointer [
	"Note: We now have 10 bits of primitive index, but they are in two places
	for temporary backward compatibility.  The time to unpack is negligible,
	since the reconstituted full index is stored in the method cache."
	| primBits |
	primBits := ((self headerOf: methodPointer) >> 1) bitAnd: 16r100001FF.
	
	^ (primBits bitAnd: 16r1FF) + (primBits >> 19)

]

{ #category : #'compiled methods' }
Interpreter >> primitiveIndexOfMethodHeader: methodHeader [
	"Note: We now have 10 bits of primitive index, but they are in two places
	for temporary backward compatibility.  The time to unpack is negligible,
	 since the derived primitive function pointer is stored in the method cache."
	| primBits |
	primBits := (methodHeader >> 1).
	^(primBits bitAnd: 16r1FF) + ((primBits >> 19) bitAnd: 16r200)
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveInputSemaphore [
	"Register the input semaphore. The argument is an index into the ExternalObjectsArray part of the specialObjectsArray and must have been allocated via 'Smalltalk registerExternalObject: the Semaphore' "
	| arg |
	arg := self stackTop.
	(self isIntegerObject: arg)
		ifTrue: ["If arg is integer, then condsider it as an index  into the external objects array and install it  as the new event semaphore"
			self ioSetInputSemaphore: (self integerValueOf: arg).
			successFlag
				ifTrue: [self pop: 1].
			^ nil]
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveInputWord [
	"Return an integer indicating the reason for the most recent input interrupt."

	self pop: 1 thenPushInteger: 0.	"noop for now"
]

{ #category : #'object access primitives' }
Interpreter >> primitiveInstVarAt [
	| index rcvr hdr fmt totalLength fixedFields value |
	index := self stackIntegerValue: 0.
	rcvr := self stackValue: 1.
	successFlag
		ifTrue: [hdr := self baseHeader: rcvr.
			fmt := hdr >> 8 bitAnd: 15.
			totalLength := self lengthOf: rcvr baseHeader: hdr format: fmt.
			fixedFields := self fixedFieldsOf: rcvr format: fmt length: totalLength.
			(index >= 1 and: [index <= fixedFields])
				ifFalse: [successFlag := false]].
	successFlag ifTrue: [value := self subscript: rcvr with: index format: fmt].
	successFlag ifTrue: [self pop: argumentCount + 1 thenPush: value]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveInstVarAtPut [
	| newValue index rcvr hdr fmt totalLength fixedFields |
	newValue := self stackTop.
	index := self stackIntegerValue: 1.
	rcvr := self stackValue: 2.
	successFlag
		ifTrue: [hdr := self baseHeader: rcvr.
			fmt := hdr >> 8 bitAnd: 15.
			totalLength := self lengthOf: rcvr baseHeader: hdr format: fmt.
			fixedFields := self fixedFieldsOf: rcvr format: fmt length: totalLength.
			(index >= 1 and: [index <= fixedFields]) ifFalse: [successFlag := false]].
	successFlag ifTrue: [self subscript: rcvr with: index storing: newValue format: fmt].
	successFlag ifTrue: [self pop: argumentCount + 1 thenPush: newValue]
]

{ #category : #'quick primitives' }
Interpreter >> primitiveInstVarsPutFromStack [
	"Note:  this primitive has been decommissioned.  It is only here for short-term compatibility with an internal 2.3beta-d image that used this.  It did not save much time and it complicated several things.  Plus Jitter will do it right anyway."
	| rcvr offsetBits |
	rcvr := self stackValue: argumentCount.
	"Mark dirty so stores below can be unchecked"
	(self oop: rcvr isLessThan: youngStart) ifTrue: [ self beRootIfOld: rcvr ].
	0 to: argumentCount-1 do:
		[:i | (i bitAnd: 3) = 0 ifTrue:
			[offsetBits := self positive32BitValueOf: (self literal: i//4 ofMethod: newMethod)].
		self storePointerUnchecked: (offsetBits bitAnd: 16rFF) ofObject: rcvr
						withValue: (self stackValue: i).
		offsetBits := offsetBits >> 8].
	self pop: argumentCount
]

{ #category : #'array primitives' }
Interpreter >> primitiveIntegerAt [
	"Return the 32bit signed integer contents of a words receiver"

	| index rcvr sz addr value intValue |
	<var: #intValue type: 'int'>
	index := self stackIntegerValue: 0.
	rcvr := self stackValue: 1.
	(self isIntegerObject: rcvr) ifTrue: [^self success: false].
	(self isWords: rcvr) ifFalse: [^self success: false].
	sz := self lengthOf: rcvr.  "number of fields"
	self success: ((index >= 1) and: [index <= sz]).
	successFlag ifTrue: [
		addr := rcvr + self baseHeaderSize - 4 "for zero indexing" + (index * 4).
		value := self intAt: addr.
		self pop: 2.  "pop rcvr, index"
		"push element value"
		(self isIntegerValue: value)
			ifTrue: [self pushInteger: value]
			ifFalse: [
				intValue := value. "32 bit int may have been stored in 32 or 64 bit sqInt"
				self push: (self signed32BitIntegerFor: intValue)]. "intValue may be sign extended to 64 bit sqInt"
	].
]

{ #category : #'array primitives' }
Interpreter >> primitiveIntegerAtPut [
	"Return the 32bit signed integer contents of a words receiver"
	| index rcvr sz addr value valueOop |
	valueOop := self stackValue: 0.
	index := self stackIntegerValue: 1.
	rcvr := self stackValue: 2.
	(self isIntegerObject: rcvr) ifTrue:[^self success: false].
	(self isWords: rcvr) ifFalse:[^self success: false].
	sz := self lengthOf: rcvr.  "number of fields"
	((index >= 1) and: [index <= sz]) ifFalse:[^self success: false].
	(self isIntegerObject: valueOop)
		ifTrue:[value := self integerValueOf: valueOop]
		ifFalse:[value := self signed32BitValueOf: valueOop].
	successFlag ifTrue:[
		addr := rcvr + self baseHeaderSize - 4 "for zero indexing" + (index * 4).
		value := self intAt: addr put: value.
		self pop: 3 thenPush: valueOop. "pop all; return value"
	].

]

{ #category : #'other primitives' }
Interpreter >> primitiveInterpreterSourceVersion [
	"Answer a string corresponding to the version of the interpreter source. This
	represents the version level of the Smalltalk source code (interpreter and various
	plugins) that is translated to C by a CCodeGenerator, as distinct from the external
	platform source code, typically written in C and managed separately for each platform.
	This is a named (not numbered) primitive in the null module (ie the VM)"
	
	| len versionString p cString |
	<export: true>
	<var: #p type: 'char *'>
	<var: #cString type: 'char *'>
	cString := InterpreterSourceVersion.
	len := self cCode: 'strlen(cString)' inSmalltalk: [0].
	versionString := interpreterProxy
		instantiateClass: interpreterProxy classString
		indexableSize: len.
	p := interpreterProxy arrayValueOf: versionString.
	self cCode: 'strncpy(p, cString, len)'.
	self pop: 1 thenPush: versionString

]

{ #category : #'I/O primitives' }
Interpreter >> primitiveInterruptSemaphore [
	"Register the user interrupt semaphore. If the argument is 
	not a Semaphore, unregister the current interrupt 
	semaphore. "
	| arg |
	arg := self popStack.
	(self fetchClassOf: arg) = (self splObj: ClassSemaphore)
		ifTrue: [self storePointer: TheInterruptSemaphore ofObject: specialObjectsOop withValue: arg]
		ifFalse: [self storePointer: TheInterruptSemaphore ofObject: specialObjectsOop withValue: nilObj]
]

{ #category : #'control primitives' }
Interpreter >> primitiveInvokeObjectAsMethod [
	"Primitive. 'Invoke' an object like a function, sending the special message 
		run: originalSelector with: arguments in: aReceiver.
	"
	| runSelector runReceiver runArgs newReceiver lookupClass |
	runArgs := self instantiateClass: (self splObj: ClassArray) indexableSize: argumentCount.
	self beRootIfOld: runArgs. "do we really need this?"
	self transfer: argumentCount from: stackPointer - ((argumentCount - 1) * self bytesPerWord) to: runArgs + self baseHeaderSize.

	runSelector := messageSelector.
	runReceiver := self stackValue: argumentCount.
	self pop: argumentCount+1.

	"stack is clean here"

	newReceiver := newMethod.
	messageSelector := self splObj: SelectorRunWithIn.
	argumentCount := 3.

	self push: newReceiver.
	self push: runSelector.
	self push: runArgs.
	self push: runReceiver.

	lookupClass := self fetchClassOf: newReceiver.
	self findNewMethodInClass: lookupClass.
	self executeNewMethodFromCache.  "Recursive xeq affects successFlag"
	successFlag := true.

]

{ #category : #'memory space primitives' }
Interpreter >> primitiveIsRoot [
	"Primitive. Answer whether the argument to the primitive is a root for young space"
	| oop |
	<export: true>
	oop := self stackObjectValue: 0.
	successFlag ifTrue:[
		self pop: argumentCount + 1.
		self pushBool: ((self baseHeader: oop) bitAnd: self rootBit).
	].
]

{ #category : #'memory space primitives' }
Interpreter >> primitiveIsYoung [
	"Primitive. Answer whether the argument to the primitive resides in young space."
	| oop |
	<export: true>
	oop := self stackObjectValue: 0.
	successFlag ifTrue:[
		self pop: argumentCount + 1.
		self pushBool: (self oop: oop isGreaterThanOrEqualTo: youngStart).
	].
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveKbdNext [
	"Obsolete on virtually all platforms; old style input polling code.
	Return the next keycode and remove it from the input buffer. The low byte is the 8-bit ISO character. The next four bits are the Smalltalk modifier bits <cmd><option><ctrl><shift>."

	| keystrokeWord |
	self pop: 1.
	keystrokeWord := self ioGetKeystroke.
	keystrokeWord >= 0
		ifTrue: [self pushInteger: keystrokeWord]
		ifFalse: [self push: nilObj].
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveKbdPeek [
	"Obsolete on virtually all platforms; old style input polling code.
	Return the next keycode and without removing it from the input buffer. The low byte is the 8-bit ISO character. The next four bits are the Smalltalk modifier bits <cmd><option><ctrl><shift>."

	| keystrokeWord |
	self pop: 1.
	keystrokeWord := self ioPeekKeystroke.
	keystrokeWord >= 0
		ifTrue: [self pushInteger: keystrokeWord]
		ifFalse: [self push: nilObj].
]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveLessOrEqual [
	| integerReceiver integerArgument |
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver <= integerArgument
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveLessOrEqualLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	successFlag ifTrue:[
		self pop: 2.
		self pushBool: integerRcvr <= integerArg
	].

]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveLessThan [
	| integerReceiver integerArgument |
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver < integerArgument
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveLessThanLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	successFlag ifTrue:[
		self pop: 2.
		self pushBool: integerRcvr < integerArg
	].

]

{ #category : #'plugin primitives' }
Interpreter >> primitiveListBuiltinModule [
	"Primitive. Return the n-th builtin module name."
	| moduleName index length nameOop |
	<var: #moduleName type: 'char *'>
	self methodArgumentCount = 1 ifFalse:[^self primitiveFail].
	index := self stackIntegerValue: 0.
	index <= 0 ifTrue:[^self primitiveFail].
	moduleName := self ioListBuiltinModule: index.
	moduleName == nil ifTrue:[
		self pop: 2. "arg+rcvr"
		^self push: self nilObject].
	length := self strlen: moduleName.
	nameOop := self instantiateClass: self classString indexableSize: length.
	0 to: length-1 do:[:i|
		self storeByte: i ofObject: nameOop withValue: (moduleName at: i)].
	self forceInterruptCheck.
	self pop: 2 thenPush: nameOop
]

{ #category : #'plugin primitives' }
Interpreter >> primitiveListExternalModule [
	"Primitive. Return the n-th loaded external module name."
	| moduleName index length nameOop |
	<var: #moduleName type: 'char *'>
	self methodArgumentCount = 1 ifFalse:[^self primitiveFail].
	index := self stackIntegerValue: 0.
	index <= 0 ifTrue:[^self primitiveFail].
	moduleName := self ioListLoadedModule: index.
	moduleName == nil ifTrue:[
		self pop: 2. "arg+rcvr"
		^self push: self nilObject].
	length := self strlen: moduleName.
	nameOop := self instantiateClass: self classString indexableSize: length.
	0 to: length-1 do:[:i|
		self storeByte: i ofObject: nameOop withValue: (moduleName at: i)].
	self forceInterruptCheck.
	self pop: 2 thenPush: nameOop
]

{ #category : #'image segment in/out' }
Interpreter >> primitiveLoadImageSegment [
	"This primitive is called from Squeak as...
		<imageSegment> loadSegmentFrom: aWordArray outPointers: anArray."

"This primitive will load a binary image segment created by primitiveStoreImageSegment.  It expects the outPointer array to be of the proper size, and the wordArray to be well formed.  It will return as its value the original array of roots, and the erstwhile segmentWordArray will have been truncated to a size of zero.  If this primitive should fail, the segmentWordArray will, sadly, have been reduced to an unrecognizable and unusable jumble.  But what more could you have done with it anyway?"

	| outPointerArray segmentWordArray endSeg segOop fieldPtr fieldOop doingClass lastPtr extraSize mapOop lastOut outPtr hdrTypeBits header data |

	<var: #endSeg type: 'usqInt'>
	<var: #segOop type: 'usqInt'>
	<var: #fieldPtr type: 'usqInt'>
	<var: #lastOut type: 'usqInt'>
	<var: #outPtr type: 'usqInt'>
	<var: #lastPtr type: 'usqInt'>

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	outPointerArray := self stackTop.
	lastOut := outPointerArray + (self lastPointerOf: outPointerArray).
	segmentWordArray := self stackValue: 1.
	endSeg := segmentWordArray + (self sizeBitsOf: segmentWordArray) - self baseHeaderSize.

	"Essential type checks"
	((self formatOf: outPointerArray) = 2				"Must be indexable pointers"
		and: [(self formatOf: segmentWordArray) = 6])	"Must be indexable words"
		ifFalse: [^ self primitiveFail].

	"Version check.  Byte order of the WordArray now"
	data := self longAt: segmentWordArray + self baseHeaderSize.
	(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse: [
		"Not readable -- try again with reversed bytes..."
		self reverseBytesFrom: segmentWordArray + self baseHeaderSize to: endSeg + self bytesPerWord.
		data := self longAt: segmentWordArray + self baseHeaderSize.
		(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse: [
			"Still NG -- put things back and fail"
			self reverseBytesFrom: segmentWordArray + self baseHeaderSize to: endSeg + self bytesPerWord.
			DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^ self primitiveFail]].
	"Reverse the Byte type objects if the is data from opposite endian machine."
	"Test top byte.  $d on the Mac or $s on the PC.  Rest of word is equal."
	(data >> 16) = (self imageSegmentVersion >> 16) ifFalse: [
		"Reverse the byte-type objects once"
		segOop := self oopFromChunk: segmentWordArray + self baseHeaderSize + self bytesPerWord.
			 "Oop of first embedded object"
		self byteSwapByteObjectsFrom: segOop to: endSeg + self bytesPerWord].

	"Proceed through the segment, remapping pointers..."
	segOop := self oopFromChunk: segmentWordArray + self baseHeaderSize + self bytesPerWord.
	[segOop <= endSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type = 0 or 1) -- start with that."
					fieldPtr := segOop - self bytesPerWord.  doingClass := true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr := segOop + self baseHeaderSize.  doingClass := false].
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"
		lastPtr > endSeg ifTrue: [
			DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^ self primitiveFail "out of bounds"].

		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop := self longAt: fieldPtr.
			doingClass ifTrue:
				[hdrTypeBits := self headerType: fieldPtr.
				fieldOop := fieldOop - hdrTypeBits].
			(self isIntegerObject: fieldOop)
				ifTrue:
					["Integer -- nothing to do"
					fieldPtr := fieldPtr + self bytesPerWord]
				ifFalse:
					[(fieldOop bitAnd: 3) = 0 ifFalse: [^ self primitiveFail "bad oop"].
					(fieldOop bitAnd: 16r80000000) = 0
						ifTrue: ["Internal pointer -- add segment offset"
								mapOop := fieldOop + segmentWordArray]
						ifFalse: ["External pointer -- look it up in outPointers"
								outPtr := outPointerArray + (fieldOop bitAnd: 16r7FFFFFFF).
								outPtr > lastOut ifTrue: [^ self primitiveFail "out of bounds"].
								mapOop := self longAt: outPtr].
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr := fieldPtr + 8.
								doingClass := false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr := fieldPtr + self bytesPerWord].
					segOop < youngStart
						ifTrue: [self possibleRootStoreInto: segOop value: mapOop].
					]].
		segOop := self objectAfter: segOop].

	"Again, proceed through the segment checking consistency..."
	segOop := self oopFromChunk: segmentWordArray + self baseHeaderSize + self bytesPerWord.
	[segOop <= endSeg] whileTrue:
		[(self oopHasAcceptableClass: segOop) ifFalse: [^ self primitiveFail "inconsistency"].
		fieldPtr := segOop + self baseHeaderSize.		"first field"
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"
		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop := self longAt: fieldPtr.
			(self oopHasAcceptableClass: fieldOop) ifFalse: [^ self primitiveFail "inconsistency"].
			fieldPtr := fieldPtr + self bytesPerWord].
		segOop := self objectAfter: segOop].

	"Truncate the segment word array to size = self bytesPerWord (vers stamp only)"
	extraSize := self extraHeaderBytes: segmentWordArray.
	hdrTypeBits := self headerType: segmentWordArray.
	extraSize = 8
		ifTrue: [self longAt: segmentWordArray-extraSize put: self baseHeaderSize + self bytesPerWord + hdrTypeBits]
		ifFalse: [header := self longAt: segmentWordArray.
				self longAt: segmentWordArray
					put: header - (header bitAnd: self sizeMask) + self baseHeaderSize + self bytesPerWord].	
	"and return the roots array which was first in the segment"
	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	self pop: 3 thenPush: (self oopFromChunk: segmentWordArray + self baseHeaderSize + self bytesPerWord).

]

{ #category : #'quick primitives' }
Interpreter >> primitiveLoadInstVar [
	| thisReceiver |
	thisReceiver := self popStack.
	self push: (self fetchPointer: primitiveIndex-264 ofObject: thisReceiver)
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveLogN [
	"Natural log."

	| rcvr |
	<var: #rcvr type: 'double '>
	rcvr := self popFloat.
	successFlag
		ifTrue: [self pushFloat: (self cCode: 'log(rcvr)' inSmalltalk: [rcvr ln])]
		ifFalse: [self unPop: 1]
]

{ #category : #'memory space primitives' }
Interpreter >> primitiveLowSpaceSemaphore [
	"Register the low-space semaphore. If the argument is not a 
	Semaphore, unregister the current low-space Semaphore."
	| arg |
	arg := self popStack.
	(self fetchClassOf: arg) = (self splObj: ClassSemaphore)
		ifTrue: [self storePointer: TheLowSpaceSemaphore ofObject: specialObjectsOop withValue: arg]
		ifFalse: [self storePointer: TheLowSpaceSemaphore ofObject: specialObjectsOop withValue: nilObj]
]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveMakePoint [
	| rcvr argument pt |
	argument := self stackTop.
	rcvr := self stackValue: 1.
	(self isIntegerObject: rcvr)
		ifTrue: [(self isIntegerObject: argument)
				ifTrue: [pt := self makePointwithxValue: (self integerValueOf: rcvr) yValue: (self integerValueOf: argument)]
				ifFalse: [pt := self makePointwithxValue: (self integerValueOf: rcvr) yValue: 0.
					"Above may cause GC!"
					self storePointer: 1 ofObject: pt withValue: (self stackValue: 0)]]
		ifFalse: [(self isFloatObject: rcvr)
				ifFalse: [^ self success: false].
			pt := self makePointwithxValue: 0 yValue: 0.
			"Above may cause GC!"
			self storePointer: 0 ofObject: pt withValue: (self stackValue: 1).
			self storePointer: 1 ofObject: pt withValue: (self stackValue: 0)].

	self pop: 2 thenPush: pt
]

{ #category : #'process primitives' }
Interpreter >> primitiveMarkHandlerMethod [
	"Primitive. Mark the method for exception handling. The primitive must fail after marking the context so that the regular code is run."
	<inline: false>
	^self primitiveFail
]

{ #category : #'process primitives' }
Interpreter >> primitiveMarkUnwindMethod [
	"Primitive. Mark the method for exception unwinding. The primitive must fail after marking the context so that the regular code is run."
	<inline: false>
	^self primitiveFail
]

{ #category : #'plugin primitive support' }
Interpreter >> primitiveMethod [
	"Return the method an external primitive was defined in"
	^newMethod
]

{ #category : #'system control primitives' }
Interpreter >> primitiveMicrosecondClock [
	"This is a named (not numbered) primitive in the null module (ie the VM)"
	<export: true>
	self pop: 1 thenPush: (self positive64BitIntegerFor: (self ioMicroSecondClock)).

]

{ #category : #'system control primitives' }
Interpreter >> primitiveMillisecondClock [
	"Return the value of the millisecond clock as an integer. Note that the millisecond clock wraps around periodically. On some platforms it can wrap daily. The range is limited to SmallInteger maxVal / 2 to allow delays of up to that length without overflowing a SmallInteger."

	self pop: 1 thenPush: (self integerObjectOf: (self ioMSecs bitAnd: MillisecondClockMask)).

]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveMod [
	| mod |
	mod := self doPrimitiveMod: (self stackValue: 1) by: (self stackTop).
	self pop2AndPushIntegerIfOK: mod
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveModLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| integerRcvr integerArg result oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'result' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).
	integerArg = 0 ifTrue:[self primitiveFail].
	successFlag ifFalse:[^nil].

	result := integerRcvr \\ integerArg.

	"ensure that the result has the same sign as the integerArg"
	integerArg < 0
		ifTrue: [result > 0
			ifTrue: [result := result + integerArg]]
		ifFalse: [result < 0
			ifTrue: [result := result + integerArg]].

	oopResult := self signed64BitIntegerFor: result.
	successFlag ifTrue:[self pop: 2 thenPush: oopResult].

]

{ #category : #'I/O primitives' }
Interpreter >> primitiveMouseButtons [
	"Obsolete on virtually all platforms; old style input polling code.
	Return the mouse button state. The low three bits encode the state of the <red><yellow><blue> mouse buttons. The next four bits encode the Smalltalk modifier bits <cmd><option><ctrl><shift>."

	| buttonWord |
	self pop: 1.
	buttonWord := self ioGetButtonState.
	self pushInteger: buttonWord.
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveMousePoint [
	"Obsolete on virtually all platforms; old style input polling code.
	Return a Point indicating current position of the mouse. Note that mouse coordinates may be negative if the mouse moves above or to the left of the top-left corner of the Smalltalk window."

	| pointWord x y |
	self pop: 1.
	pointWord := self ioMousePoint.
	x := self signExtend16: ((pointWord >> 16) bitAnd: 16rFFFF).
	y := self signExtend16: (pointWord bitAnd: 16rFFFF).
	self push: (self makePointwithxValue: x  yValue: y).
]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveMultiply [
	| integerRcvr integerArg integerResult |
	integerRcvr := self stackIntegerValue: 1.
	integerArg := self stackIntegerValue: 0.
	successFlag ifTrue:
		[integerResult := integerRcvr * integerArg.
		"check for C overflow by seeing if computation is reversible"
		((integerArg = 0) or: [(integerResult // integerArg) = integerRcvr])
			ifTrue: [self pop2AndPushIntegerIfOK: integerResult]
			ifFalse: [self primitiveFail]]
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveMultiplyLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| integerRcvr integerArg result oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'result' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).
	successFlag ifFalse:[^nil].

	result := integerRcvr * integerArg.
	"check for C overflow by seeing if computation is reversible"
	((integerArg = 0) or: [(result // integerArg) = integerRcvr])
		ifTrue:[oopResult := self signed64BitIntegerFor: result]
		ifFalse: [self primitiveFail].

	successFlag ifTrue:[self pop: 2 thenPush: oopResult].

]

{ #category : #'object access primitives' }
Interpreter >> primitiveNew [
	"Allocate a new fixed-size instance. Fail if the allocation would leave less than lowSpaceThreshold bytes free. May cause a GC"

	| class spaceOkay |
	class := self stackTop.
	"The following may cause GC!"
	spaceOkay := self sufficientSpaceToInstantiate: class indexableSize: 0.
	self success: spaceOkay.
	successFlag ifTrue: [ self push: (self instantiateClass: self popStack indexableSize: 0) ]
]

{ #category : #'compiled methods' }
Interpreter >> primitiveNewMethod [
	| header bytecodeCount class size theMethod literalCount |
	header := self popStack.
	bytecodeCount := self popInteger.
	self success: (self isIntegerObject: header).
	successFlag ifFalse:
		[self unPop: 2. ^nil].
	class := self popStack.
	size := (self literalCountOfHeader: header) + 1 * self bytesPerWord + bytecodeCount.
	theMethod := self instantiateClass: class indexableSize: size.
	self storePointerUnchecked: HeaderIndex ofObject: theMethod withValue: header.
	literalCount := self literalCountOfHeader: header.
	1 to: literalCount do:
		[:i | self storePointer: i ofObject: theMethod withValue: nilObj].
	self push: theMethod
]

{ #category : #'object access primitives' }
Interpreter >> primitiveNewWithArg [
	"Allocate a new indexable instance. Fail if the allocation would leave less than lowSpaceThreshold bytes free."
	| size class spaceOkay |
	<var: #size type: 'usqInt'>

	self isDefinedTrueExpression: 'SQ_IMAGE64 && SQ_HOST64'
		inSmalltalk: [size := self positive32BitValueOf: self stackTop]
		comment: 'permit large object allocation on 64 bit image and host'
		ifTrue: [size := self positive64BitValueOf: self stackTop]
		ifFalse: [size := self positive32BitValueOf: self stackTop].
	class := self stackValue: 1.
	self success: size >= 0.
	successFlag
		ifTrue: ["The following may cause GC!"
			spaceOkay := self sufficientSpaceToInstantiate: class indexableSize: size.
			self success: spaceOkay.
			class := self stackValue: 1].
	successFlag ifTrue: [self pop: 2 thenPush: (self instantiateClass: class indexableSize: size)]
]

{ #category : #'array and stream primitives' }
Interpreter >> primitiveNext [
	"PrimitiveNext will succeed only if the stream's array is in the atCache.
	Otherwise failure will lead to proper message lookup of at: and
	subsequent installation in the cache if appropriate."
	| stream array index limit result atIx |
	stream := self stackTop.
	((self isPointers: stream)
		and: [(self lengthOf: stream) >= (StreamReadLimitIndex + 1)])
		ifFalse: [^ self primitiveFail].

	array := self fetchPointer: StreamArrayIndex ofObject: stream.
	index := self fetchInteger: StreamIndexIndex ofObject: stream.
	limit := self fetchInteger: StreamReadLimitIndex ofObject: stream.
	atIx := array bitAnd: AtCacheMask.
	(index < limit and: [(atCache at: atIx+AtCacheOop) = array])
		ifFalse: [^ self primitiveFail].

	"OK -- its not at end, and the array is in the cache"
	index := index + 1.
	result := self commonVariable: array at: index cacheIndex: atIx.
	"Above may cause GC, so can't use stream, array etc. below it"
	successFlag ifTrue:
		[stream := self stackTop.
		self storeInteger: StreamIndexIndex ofObject: stream withValue: index.
		^ self pop: 1 thenPush: result].

]

{ #category : #'object access primitives' }
Interpreter >> primitiveNextInstance [
	| object instance |
	object := self stackTop.
	instance := self instanceAfter: object.
	instance = nilObj
		ifTrue: [self primitiveFail]
		ifFalse: [self pop: argumentCount+1 thenPush: instance]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveNextObject [
	"Return the object following the receiver in the heap. Return the SmallInteger zero when there are no more objects."

	| object instance |
	object := self stackTop.
	instance := self accessibleObjectAfter: object.
	instance = nil
		ifTrue: [ self pop: argumentCount+1 thenPushInteger: 0 ]
		ifFalse: [ self pop: argumentCount+1 thenPush: instance ].
]

{ #category : #'array and stream primitives' }
Interpreter >> primitiveNextPut [
	"PrimitiveNextPut will succeed only if the stream's array is in the atPutCache.
	Otherwise failure will lead to proper message lookup of at:put: and
	subsequent installation in the cache if appropriate."
	| value stream index limit array atIx |
	value := self stackTop.
	stream := self stackValue: 1.
	((self isPointers: stream)
		and: [(self lengthOf: stream) >= (StreamReadLimitIndex + 1)])
		ifFalse: [^ self primitiveFail].

	array := self fetchPointer: StreamArrayIndex ofObject: stream.
	index := self fetchInteger: StreamIndexIndex ofObject: stream.
	limit := self fetchInteger: StreamWriteLimitIndex ofObject: stream.
	atIx := (array bitAnd: AtCacheMask) + AtPutBase.
	(index < limit and: [(atCache at: atIx+AtCacheOop) = array])
		ifFalse: [^ self primitiveFail].

	"OK -- its not at end, and the array is in the cache"
	index := index + 1.
	self commonVariable: array at: index put: value cacheIndex: atIx.
	successFlag ifTrue:
		[self storeInteger: StreamIndexIndex ofObject: stream withValue: index.
		^ self pop: 2 thenPush: value].

]

{ #category : #'system control primitives' }
Interpreter >> primitiveNoop [
	"A placeholder for primitives that haven't been implemented or are being withdrawn gradually. Just absorbs any arguments and returns the receiver."

	self pop: argumentCount.  "pop args, leave rcvr on stack"
]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveNotEqual [
	| integerReceiver integerArgument result |
	integerArgument := self popStack.
	integerReceiver := self popStack.
	result := (self compare31or32Bits: integerReceiver equal: integerArgument) not.
	self checkBooleanResult: result
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveNotEqualLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	successFlag ifTrue:[
		self pop: 2.
		self pushBool: integerRcvr ~= integerArg
	].

]

{ #category : #'object access primitives' }
Interpreter >> primitiveObjectAt [
"Defined for CompiledMethods only"
	| thisReceiver index |
	index  := self popInteger.
	thisReceiver := self popStack.
	self success: index > 0.
	self success: index <= ((self literalCountOf: thisReceiver) + LiteralStart).
	successFlag
		ifTrue: [self push: (self fetchPointer: index - 1 ofObject: thisReceiver)]
		ifFalse: [self unPop: 2]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveObjectAtPut [
"Defined for CompiledMethods only"
	| thisReceiver index newValue |
	newValue := self popStack.
	index := self popInteger.
	thisReceiver := self popStack.
	self success: index > 0.
	self success: index <= ((self literalCountOf: thisReceiver) + LiteralStart).
	successFlag
		ifTrue: [self storePointer: index - 1 ofObject: thisReceiver withValue: newValue.
			self push: newValue]
		ifFalse: [self unPop: 3]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveObjectPointsTo [
	| rcvr thang lastField |
	thang := self popStack.
	rcvr := self popStack.
	(self isIntegerObject: rcvr) ifTrue: [^self pushBool: false].

	lastField := self lastPointerOf: rcvr.
	self baseHeaderSize to: lastField by: self bytesPerWord do:
		[:i | (self longAt: rcvr + i) = thang
			ifTrue: [^ self pushBool: true]].
	self pushBool: false.
]

{ #category : #'control primitives' }
Interpreter >> primitivePerform [
	| performSelector newReceiver selectorIndex lookupClass performMethod |
	performSelector := messageSelector.
	performMethod := newMethod.
	messageSelector := self stackValue: argumentCount - 1.
	newReceiver := self stackValue: argumentCount.

	"NOTE: the following lookup may fail and be converted to #doesNotUnderstand:, so we must adjust argumentCount and slide args now, so that would work."

	"Slide arguments down over selector"
	argumentCount := argumentCount - 1.
	selectorIndex := self stackPointerIndex - argumentCount.
	self
		transfer: argumentCount
		fromIndex: selectorIndex + 1
		ofObject: activeContext
		toIndex: selectorIndex
		ofObject: activeContext.
	self pop: 1.
	lookupClass := self fetchClassOf: newReceiver.
	self findNewMethodInClass: lookupClass.

	"Only test CompiledMethods for argument count - other objects will have to take their chances"
	(self isOopCompiledMethod: newMethod)
		ifTrue: [self success: (self argumentCountOf: newMethod) = argumentCount].

	successFlag
		ifTrue: [self executeNewMethodFromCache.
			"Recursive xeq affects successFlag"
			successFlag := true]
		ifFalse: ["Slide the args back up (sigh) and re-insert the 
			selector. "
			1 to: argumentCount do: [:i | self
						storePointer: argumentCount - i + 1 + selectorIndex
						ofObject: activeContext
						withValue: (self fetchPointer: argumentCount - i + selectorIndex ofObject: activeContext)].
			self unPop: 1.
			self storePointer: selectorIndex
				ofObject: activeContext
				withValue: messageSelector.
			argumentCount := argumentCount + 1.
			newMethod := performMethod.
			messageSelector := performSelector]
]

{ #category : #'control primitives' }
Interpreter >> primitivePerformAt: lookupClass [
	"Common routine used by perform:withArgs: and perform:withArgs:inSuperclass:"

	"NOTE:  The case of doesNotUnderstand: is not a failure to perform.
	The only failures are arg types and consistency of argumentCount."

	| performSelector argumentArray arraySize index cntxSize performMethod performArgCount |
	argumentArray := self stackTop.
	(self isArray: argumentArray) ifFalse:[^self primitiveFail].

	successFlag ifTrue:
		["Check for enough space in thisContext to push all args"
		arraySize := self fetchWordLengthOf: argumentArray.
		cntxSize := self fetchWordLengthOf: activeContext.
		self success: (self stackPointerIndex + arraySize) < cntxSize].
	successFlag ifFalse: [^nil].

	performSelector := messageSelector.
	performMethod := newMethod.
	performArgCount := argumentCount.
	"pop the arg array and the selector, then push the args out of the array, as if they were on the stack"
	self popStack.
	messageSelector := self popStack.

	"Copy the arguments to the stack, and execute"
	index := 1.
	[index <= arraySize]
		whileTrue:
		[self push: (self fetchPointer: index - 1 ofObject: argumentArray).
		index := index + 1].
	argumentCount := arraySize.

	self findNewMethodInClass: lookupClass.

	"Only test CompiledMethods for argument count - any other objects playacting as CMs will have to take their chances"
	(self isOopCompiledMethod: newMethod)
		ifTrue: [self success: (self argumentCountOf: newMethod) = argumentCount].

	successFlag
		ifTrue: [self executeNewMethodFromCache.  "Recursive xeq affects successFlag"
				successFlag := true]
		ifFalse: ["Restore the state by popping all those array entries and pushing back the selector and array, and fail"
				self pop: argumentCount.
				self push: messageSelector.
				self push: argumentArray.
				messageSelector := performSelector.
				newMethod := performMethod.
				argumentCount := performArgCount]

]

{ #category : #'control primitives' }
Interpreter >> primitivePerformInSuperclass [
	| lookupClass rcvr currentClass |
	lookupClass := self stackTop.
	rcvr := self stackValue: argumentCount.
	currentClass := self fetchClassOf: rcvr.
	[currentClass ~= lookupClass]
		whileTrue:
		[currentClass := self superclassOf: currentClass.
		currentClass = nilObj ifTrue: [^ self primitiveFail]].

	self popStack.
	self primitivePerformAt: lookupClass.
	successFlag ifFalse:
		[self push: lookupClass]
]

{ #category : #'control primitives' }
Interpreter >> primitivePerformWithArgs [

	| lookupClass rcvr |
	rcvr := self stackValue: argumentCount.
	lookupClass := self fetchClassOf: rcvr.
	self primitivePerformAt: lookupClass.

]

{ #category : #'other primitives' }
Interpreter >> primitivePlatformSourceVersion [
	"Answer a string corresponding to the version of the external platform source
	code, typically written in C and managed separately for each platform.
	This is a named (not numbered) primitive in the null module (ie the VM)"
	| len versionString p |
	<export: true>
	<var: #p type: 'char *'>
	self isDefined: 'PLATFORM_SOURCE_VERSION'
		inSmalltalk: [versionString := '']
		comment: 'version level of platform support code'
		ifTrue: [len := self cCode: 'strlen(PLATFORM_SOURCE_VERSION)' inSmalltalk: [0].
			versionString := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: len.
			p := interpreterProxy arrayValueOf: versionString.
			self cCode: 'strncpy(p, PLATFORM_SOURCE_VERSION, len)']
		ifFalse: [^interpreterProxy primitiveFail].
	self pop: 1 thenPush: versionString
]

{ #category : #'object access primitives' }
Interpreter >> primitivePointX [
	| rcvr | 
	<inline: false>
	rcvr := self popStack.
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	successFlag
		ifTrue: [self push: (self fetchPointer: XIndex ofObject: rcvr)]
		ifFalse: [self unPop: 1]
]

{ #category : #'object access primitives' }
Interpreter >> primitivePointY [
	| rcvr | 
	<inline: false>
	rcvr := self popStack.
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	successFlag
		ifTrue: [self push: (self fetchPointer: YIndex ofObject: rcvr)]
		ifFalse: [self unPop: 1]
]

{ #category : #'quick primitives' }
Interpreter >> primitivePushFalse [
	self popStack.
	self push: falseObj
]

{ #category : #'quick primitives' }
Interpreter >> primitivePushMinusOne [
	self popStack.
	self push: ConstMinusOne
]

{ #category : #'quick primitives' }
Interpreter >> primitivePushNil [
	self popStack.
	self push: nilObj
]

{ #category : #'quick primitives' }
Interpreter >> primitivePushOne [
	self popStack.
	self push: ConstOne
]

{ #category : #'quick primitives' }
Interpreter >> primitivePushSelf [
"	no-op, really...
	thisReceiver := self popStack.
	self push: thisReceiver
"
]

{ #category : #'quick primitives' }
Interpreter >> primitivePushTrue [
	self popStack.
	self push: trueObj
]

{ #category : #'quick primitives' }
Interpreter >> primitivePushTwo [
	self popStack.
	self push: ConstTwo
]

{ #category : #'quick primitives' }
Interpreter >> primitivePushZero [
	self popStack.
	self push: ConstZero
]

{ #category : #'system control primitives' }
Interpreter >> primitiveQuit [

	self ioExit.

]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveQuo [
	"Rounds negative results towards zero."
	| integerRcvr integerArg integerResult |
	integerRcvr := self stackIntegerValue: 1.
	integerArg := self stackIntegerValue: 0.
	self success: integerArg ~= 0.
	successFlag ifTrue: [
		integerRcvr > 0 ifTrue: [
			integerArg > 0 ifTrue: [
				integerResult := integerRcvr // integerArg.
			] ifFalse: [
				integerResult := 0 - (integerRcvr // (0 - integerArg)).
			].
		] ifFalse: [
			integerArg > 0 ifTrue: [
				integerResult := 0 - ((0 - integerRcvr) // integerArg).
			] ifFalse: [
				integerResult := (0 - integerRcvr) // (0 - integerArg).
			].
		]].
	self pop2AndPushIntegerIfOK: integerResult
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveQuoLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| integerRcvr integerArg result oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'result' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).
	integerArg = 0 ifTrue:[self primitiveFail].
	successFlag ifFalse:[^nil].

	integerRcvr > 0 ifTrue: [
		integerArg > 0 
			ifTrue: [result := integerRcvr // integerArg]
			ifFalse: [result := 0 - (integerRcvr // (0 - integerArg))].
	] ifFalse: [
		integerArg > 0 
			ifTrue: [result := 0 - ((0 - integerRcvr) // integerArg)]
			ifFalse: [result := (0 - integerRcvr) // (0 - integerArg)].
	].

	oopResult := self signed64BitIntegerFor: result.
	successFlag ifTrue:[self pop: 2 thenPush: oopResult].

]

{ #category : #'I/O primitives' }
Interpreter >> primitiveRelinquishProcessor [
	"Relinquish the processor for up to the given number of microseconds. The exact behavior of this primitive is platform dependent."

	| microSecs |
	microSecs := self stackIntegerValue: 0.
	successFlag ifTrue: [
		self ioRelinquishProcessorForMicroseconds: microSecs.
		self pop: 1]  "microSecs; leave rcvr on stack"

]

{ #category : #'primitive support' }
Interpreter >> primitiveResponse [
	"NB: tpr removed the timer checks here and moved them to the primitiveExternalCall method.
	We make the possibly unwarranted assumption that numbered prims are quick and external prims are slow."

	| delta primIdx nArgs |
	DoBalanceChecks ifTrue:["check stack balance"
		nArgs := argumentCount.
		delta := stackPointer - activeContext.
	].
	primIdx := primitiveIndex.
	successFlag := true.
	"self dispatchOn: primitiveIndex in: primitiveTable."
	self dispatchFunctionPointerOn: primIdx in: primitiveTable.
	"replace with fetch entry primitiveIndex from table and branch there"
	DoBalanceChecks ifTrue:[
		(self balancedStack: delta afterPrimitive: primIdx withArgs: nArgs) 
			ifFalse:[self printUnbalancedStack: primIdx].
	].
	primitiveIndex := 0. "clear out primIndex so VM knows we're no longer in primitive"
	^ successFlag

]

{ #category : #'process primitives' }
Interpreter >> primitiveResume [
"put this process on the scheduler's lists thus allowing it to proceed next time there is a chance for processes of it's priority level"
	| proc |
	proc := self stackTop.  "rcvr"
	"self success: ((self fetchClassOf: proc) = (self splObj: ClassProcess))."
	successFlag ifTrue: [ self resume: proc ].
]

{ #category : #'memory space primitives' }
Interpreter >> primitiveRootTable [
	"Primitive. Answer a copy (snapshot) element of the root table.
	The primitive can cause GC itself and if so the return value may
	be inaccurate - in this case one should guard the read operation
	by looking at the gc counter statistics."
	| oop sz |
	<export: true>
	sz := rootTableCount.
	oop := self instantiateClass: self classArray indexableSize: sz. "can cause GC"
	sz > rootTableCount ifTrue:[sz := rootTableCount].
	1 to: sz do:[:i| 
		self storePointer: i-1 ofObject: oop withValue: (rootTable at: i).
	].
	self pop: argumentCount + 1.
	self push: oop.
]

{ #category : #'memory space primitives' }
Interpreter >> primitiveRootTableAt [
	"Primitive. Answer the nth element of the root table.
	This primitive avoids the creation of an extra array;
	it is intended for enumerations of the form:
		index := 1.
		[root := Smalltalk rootTableAt: index.
		root == nil] whileFalse:[index := index + 1].
	"
	| index |
	<export: true>
	index := self stackIntegerValue: 0.
	self success: (index > 0 and:[index <= rootTableCount]).
	successFlag ifTrue:[
		self pop: argumentCount + 1.
		self push: (rootTable at: index).
	].
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveScanCharacters [
	"The character scanner primitive."
	| kernDelta stops sourceString scanStopIndex scanStartIndex rcvr scanDestX scanLastIndex scanXTable scanMap maxGlyph ascii stopReason glyphIndex sourceX sourceX2 nextDestX scanRightX nilOop |

	self methodArgumentCount = 6
		ifFalse: [^ self primitiveFail].

	"Load the arguments"
	kernDelta := self stackIntegerValue: 0.
	stops := self stackObjectValue: 1.
	(self isArray: stops) ifFalse: [^ self primitiveFail].
	(self slotSizeOf: stops) >= 258 ifFalse: [^ self primitiveFail].
	scanRightX := self stackIntegerValue: 2.
	sourceString := self stackObjectValue: 3.
	(self isBytes: sourceString) ifFalse: [^ self primitiveFail].
	scanStopIndex := self stackIntegerValue: 4.
	scanStartIndex := self stackIntegerValue: 5.
	(scanStartIndex > 0 and: [scanStopIndex > 0 and: [scanStopIndex <= (self byteSizeOf: sourceString)]])
		ifFalse: [^ self primitiveFail].

	"Load receiver and required instVars"
	rcvr := self stackObjectValue: 6.
	((self isPointers: rcvr) and: [(self slotSizeOf: rcvr) >= 4]) ifFalse: [^ self primitiveFail].
	scanDestX := self fetchInteger: 0 ofObject: rcvr.
	scanLastIndex := self fetchInteger: 1 ofObject: rcvr.
	scanXTable := self fetchPointer: 2 ofObject: rcvr.
	scanMap := self fetchPointer: 3 ofObject: rcvr.
	((self isArray: scanXTable) and: [self isArray: scanMap]) ifFalse: [^ self primitiveFail].
	(self slotSizeOf: scanMap) = 256 ifFalse: [^ self primitiveFail].
	successFlag ifFalse: [^ nil].
	maxGlyph := (self slotSizeOf: scanXTable) - 2.

	"Okay, here we go. We have eliminated nearly all failure 
	conditions, to optimize the inner fetches."
	scanLastIndex := scanStartIndex.
	nilOop := self nilObject.
	[scanLastIndex <= scanStopIndex]
		whileTrue: [
			"Known to be okay since scanStartIndex > 0 and scanStopIndex <= sourceString size"
			ascii := self fetchByte: scanLastIndex - 1 ofObject: sourceString.
			"Known to be okay since stops size >= 258"
			(stopReason := self fetchPointer: ascii ofObject: stops) = nilOop
				ifFalse: ["Store everything back and get out of here since some stop conditionn needs to be checked"
					(self isIntegerValue: scanDestX) ifFalse: [^ self primitiveFail].
					self storeInteger: 0 ofObject: rcvr withValue: scanDestX.
					self storeInteger: 1 ofObject: rcvr withValue: scanLastIndex.
					self pop: 7. "args+rcvr"
					^ self push: stopReason].
			"Known to be okay since scanMap size = 256"
			glyphIndex := self fetchInteger: ascii ofObject: scanMap.
			"fail if the glyphIndex is out of range"
			(self failed or: [glyphIndex < 0 	or: [glyphIndex > maxGlyph]]) ifTrue: [^ self primitiveFail].
			sourceX := self fetchInteger: glyphIndex ofObject: scanXTable.
			sourceX2 := self fetchInteger: glyphIndex + 1 ofObject: scanXTable.
			"Above may fail if non-integer entries in scanXTable"
			self failed ifTrue: [^ nil].
			nextDestX := scanDestX + sourceX2 - sourceX.
			nextDestX > scanRightX
				ifTrue: ["Store everything back and get out of here since we got to the right edge"
					(self isIntegerValue: scanDestX) ifFalse: [^ self primitiveFail].
					self storeInteger: 0 ofObject: rcvr withValue: scanDestX.
					self storeInteger: 1 ofObject: rcvr withValue: scanLastIndex.
					self pop: 7. "args+rcvr"
					^ self push: (self fetchPointer: CrossedX - 1 ofObject: stops)].
			scanDestX := nextDestX + kernDelta.
			scanLastIndex := scanLastIndex + 1].
	(self isIntegerValue: scanDestX) ifFalse: [^ self primitiveFail].
	self storeInteger: 0 ofObject: rcvr withValue: scanDestX.
	self storeInteger: 1 ofObject: rcvr withValue: scanStopIndex.
	self pop: 7. "args+rcvr"
	^ self push: (self fetchPointer: EndOfRun - 1 ofObject: stops)
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveScreenDepth [
	"Return a SmallInteger indicating the current depth of the OS screen. Negative values are used to imply LSB type pixel format an there is some support in the VM for handling either MSB or LSB"
	| depth |
	<export: true>
	depth := self ioScreenDepth.
	self failed ifTrue:[^self primitiveFail].
	self pop: 1 thenPushInteger: depth.
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveScreenSize [
	"Return a point indicating the current size of the Smalltalk window. Currently there is a limit of 65535 in each direction because the point is encoded into a single 32bit value in the image header. This might well become a problem one day"
	| pointWord |
	self pop: 1.
	pointWord := self ioScreenSize.
	self push: (self makePointwithxValue: (pointWord >> 16 bitAnd: 65535) yValue: (pointWord bitAnd: 65535))
]

{ #category : #'system control primitives' }
Interpreter >> primitiveSecondsClock [
	"Return the number of seconds since January 1, 1901 as an integer."

	self pop: 1 thenPush: (self positive32BitIntegerFor: self ioSeconds).
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveSetDisplayMode [
	"Set to OS to the requested display mode.
	See also DisplayScreen setDisplayDepth:extent:fullscreen:"
	| fsFlag h w d okay |
	fsFlag := self booleanValueOf: (self stackTop).
	h := self stackIntegerValue: 1.
	w := self stackIntegerValue: 2.
	d := self stackIntegerValue: 3.
	successFlag ifTrue: [okay := self cCode:'ioSetDisplayMode(w, h, d, fsFlag)'].
	successFlag ifTrue: [
		self pop: 5. "Pop args+rcvr"
		self pushBool: okay].
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveSetFullScreen [
	"On platforms that support it, set full-screen mode to the value of the boolean argument."

	| argOop |
	argOop := self stackTop.
	argOop = trueObj
		ifTrue: [self ioSetFullScreen: true]
		ifFalse: [ argOop = falseObj
				ifTrue: [self ioSetFullScreen: false]
				ifFalse: [self primitiveFail]].
	successFlag ifTrue: [self pop: 1].

]

{ #category : #'memory space primitives' }
Interpreter >> primitiveSetGCBiasToGrow [
	"Primitive. Indicate if the GC logic should have bias to grow"
	| flag |
	<export: true>
	flag := self stackIntegerValue: 0.
	successFlag ifTrue:[
		gcBiasToGrow := flag.
		self pop: argumentCount.
	].
]

{ #category : #'memory space primitives' }
Interpreter >> primitiveSetGCBiasToGrowGCLimit [
	"Primitive. If the GC logic has  bias to grow, set growth limit"
	| value |
	<export: true>
	value := self stackIntegerValue: 0.
	successFlag ifTrue:[
		gcBiasToGrowGCLimit := value.
		gcBiasToGrowThreshold := youngStart - (self cCoerce: memory to: 'int').
		self pop: argumentCount.
	].
]

{ #category : #'memory space primitives' }
Interpreter >> primitiveSetGCSemaphore [
	"Primitive. Indicate the semaphore to be signalled for upon garbage collection"
	| index |
	<export: true>
	index := self stackIntegerValue: 0.
	successFlag ifTrue:[
		gcSemaphoreIndex := index.
		self pop: argumentCount.
	].
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveSetInterruptKey [
	"Set the user interrupt keycode. The keycode is an integer whose encoding is described in the comment for primitiveKbdNext."

	| keycode |
	keycode := self popInteger.
	successFlag
		ifTrue: [ interruptKeycode := keycode ]
		ifFalse: [ self unPop: 1 ].
]

{ #category : #'array primitives' }
Interpreter >> primitiveShortAt [
	"Treat the receiver, which can be indexible by either bytes or words, as an array of signed 16-bit values. Return the contents of the given index. Note that the index specifies the i-th 16-bit entry, not the i-th byte or word."

	| index rcvr sz addr value |
	index := self stackIntegerValue: 0.
	rcvr := self stackValue: 1.
	self success: ((self isIntegerObject: rcvr) not and: [self isWordsOrBytes: rcvr]).
	successFlag ifFalse: [ ^ nil ].
	sz := ((self sizeBitsOf: rcvr) - self baseHeaderSize) // 2.  "number of 16-bit fields"
	self success: ((index >= 1) and: [index <= sz]).
	successFlag ifTrue: [
		addr := rcvr + self baseHeaderSize + (2 * (index - 1)).
		value := self shortAt: addr.
		self pop: 2 thenPushInteger: value. 
	]
]

{ #category : #'array primitives' }
Interpreter >> primitiveShortAtPut [
	"Treat the receiver, which can be indexible by either bytes or words, as an array of signed 16-bit values. Set the contents of the given index to the given value. Note that the index specifies the i-th 16-bit entry, not the i-th byte or word."

	| index rcvr sz addr value |
	value := self stackIntegerValue: 0.
	index := self stackIntegerValue: 1.
	rcvr := self stackValue: 2.
	self success: ((self isIntegerObject: rcvr) not and: [self isWordsOrBytes: rcvr]).
	successFlag ifFalse: [ ^ nil ].
	sz := ((self sizeBitsOf: rcvr) - self baseHeaderSize) // 2.  "number of 16-bit fields"
	self success: ((index >= 1) and: [index <= sz]).
	self success: ((value >= -32768) and: [value <= 32767]).
	successFlag ifTrue: [
		addr := rcvr + self baseHeaderSize + (2 * (index - 1)).
		self shortAt: addr put: value.
		self pop: 2.  "pop index and value; leave rcvr on stack"
	]
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveShowDisplayRect [
	"Force the given rectangular section of the Display to be 
	copied to the screen."
	| bottom top right left |
	bottom := self stackIntegerValue: 0.
	top := self stackIntegerValue: 1.
	right := self stackIntegerValue: 2.
	left := self stackIntegerValue: 3.
	self displayBitsOf: (self splObj: TheDisplay) Left: left Top: top Right: right Bottom: bottom.
	successFlag
		ifTrue: [self ioForceDisplayUpdate.
			self pop: 4]
]

{ #category : #'process primitives' }
Interpreter >> primitiveSignal [
"synchromously signal the semaphore. This may change the active process as a result"
	| sema |
	sema := self stackTop.  "rcvr"
	self assertClassOf: sema is: (self splObj: ClassSemaphore).
	successFlag ifTrue: [ self synchronousSignal: sema ].
]

{ #category : #'memory space primitives' }
Interpreter >> primitiveSignalAtBytesLeft [
	"Set the low-water mark for free space. When the free space 
	falls below this level, the new and new: primitives fail and 
	system attempts to allocate space (e.g., to create a method 
	context) cause the low-space semaphore (if one is 
	registered) to be signalled."
	| bytes |
	bytes := self popInteger.
	successFlag
		ifTrue: [lowSpaceThreshold := bytes]
		ifFalse: [lowSpaceThreshold := 0.
			self unPop: 1]
]

{ #category : #'system control primitives' }
Interpreter >> primitiveSignalAtMilliseconds [
	"Cause the time semaphore, if one has been registered, to
	be signalled when the millisecond clock is greater than or
	equal to the given tick value. A tick value of zero turns off
	timer interrupts."
	| tick sema |
	tick := self popInteger.
	sema := self popStack.
	successFlag
		ifTrue: [(self fetchClassOf: sema) = (self splObj: ClassSemaphore)
				ifTrue: [self
						storePointer: TheTimerSemaphore
						ofObject: specialObjectsOop
						withValue: sema.
					nextWakeupTick := tick]
				ifFalse: [self
						storePointer: TheTimerSemaphore
						ofObject: specialObjectsOop
						withValue: nilObj.
					nextWakeupTick := 0]]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveSine [

	| rcvr |
	<var: #rcvr type: 'double '>
	rcvr := self popFloat.
	successFlag
		ifTrue: [self pushFloat: (self cCode: 'sin(rcvr)' inSmalltalk: [rcvr sin])]
		ifFalse: [self unPop: 1]
]

{ #category : #'array primitives' }
Interpreter >> primitiveSize [
	| rcvr sz |
	rcvr := self stackTop.
	(self isIntegerObject: rcvr) ifTrue: [^ self primitiveFail].  "Integers are not indexable"
	(self formatOf: rcvr) < 2 ifTrue: [^ self primitiveFail].  "This is not an indexable object"
	sz := self stSizeOf: rcvr.
	successFlag ifTrue:
		[self pop: 1 thenPush: (self positive32BitIntegerFor: sz)]

]

{ #category : #'system control primitives' }
Interpreter >> primitiveSnapshot [
"save a normal snapshot under the same name as it was loaded unless it has been renamed by the last primitiveImageName"
	<inline: false>
	^self snapshot: false

]

{ #category : #'system control primitives' }
Interpreter >> primitiveSnapshotEmbedded [
"save an embedded snapshot"
	<inline: false>
	^self snapshot: true
]

{ #category : #'object access primitives' }
Interpreter >> primitiveSomeInstance [
	| class instance |
	class := self stackTop.
	instance := self initialInstanceOf: class.
	instance = nilObj
		ifTrue: [self primitiveFail]
		ifFalse: [self pop: argumentCount+1 thenPush: instance]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveSomeObject [
	"Return the first object in the heap."

	self pop: argumentCount+1.
	self push: self firstAccessibleObject.
]

{ #category : #'system control primitives' }
Interpreter >> primitiveSpecialObjectsOop [
	"Return the oop of the SpecialObjectsArray."

	self pop: 1 thenPush: specialObjectsOop.
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveSquareRoot [
	| rcvr |
	<var: #rcvr type: 'double '>
	rcvr := self popFloat.
	self success: rcvr >= 0.0.
	successFlag
		ifTrue: [self pushFloat: (self cCode: 'sqrt(rcvr)' inSmalltalk: [rcvr sqrt])]
		ifFalse: [self unPop: 1]
]

{ #category : #'image segment in/out' }
Interpreter >> primitiveStoreImageSegment [
	"This primitive is called from Squeak as...
		<imageSegment> storeSegmentFor: arrayOfRoots into: aWordArray outPointers: anArray."

"This primitive will store a binary image segment (in the same format as the Squeak image file) of the receiver and every object in its proper tree of subParts (ie, that is not refered to from anywhere else outside the tree).  All pointers from within the tree to objects outside the tree will be copied into the array of outpointers.  In their place in the image segment will be an oop equal to the offset in the outPointer array (the first would be 4). but with the high bit set."

"The primitive expects the array and wordArray to be more than adequately long.  In this case it returns normally, and truncates the two arrays to exactly the right size.  To simplify truncation, both incoming arrays are required to be 256 bytes or more long (ie with 3-word headers).  If either array is too small, the primitive will fail, but in no other case.

During operation of the primitive, it is necessary to convert from both internal and external oops to their mapped values.  To make this fast, the headers of the original objects in question are replaced by the mapped values (and this is noted by adding the forbidden XX header type).  Tables are kept of both kinds of oops, as well as of the original headers for restoration.

To be specific, there are two similar two-part tables, the outpointer array, and one in the upper fifth of the segmentWordArray.  Each grows oops from the bottom up, and preserved headers from halfway up.

In case of either success or failure, the headers must be restored.  In the event of primitive failure, the table of outpointers must also be nilled out (since the garbage in the high half will not have been discarded."

	| outPointerArray segmentWordArray savedYoungStart lastOut lastIn firstIn lastSeg endSeg segOop fieldPtr fieldOop mapOop doingClass lastPtr extraSize hdrTypeBits arrayOfRoots hdrBaseIn hdrBaseOut header firstOut versionOffset |

	<var: #firstIn type: 'usqInt'>
	<var: #lastIn type: 'usqInt'>
	<var: #firstOut type: 'usqInt'>
	<var: #lastOut type: 'usqInt'>
	<var: #hdrBaseIn type: 'usqInt'>
	<var: #hdrBaseOut type: 'usqInt'>
	<var: #lastSeg type: 'usqInt'>
	<var: #endSeg type: 'usqInt'>
	<var: #fieldPtr type: 'usqInt'>
	<var: #lastPtr type: 'usqInt'>
	<var: #segOop type: 'usqInt'>
	<var: #savedYoungStart type: 'usqInt'>

	outPointerArray := self stackTop.
	segmentWordArray := self stackValue: 1.
	arrayOfRoots := self stackValue: 2.

	"Essential type checks"
	((self formatOf: arrayOfRoots) = 2				"Must be indexable pointers"
		and: [(self formatOf: outPointerArray) = 2				"Must be indexable pointers"
		and: [(self formatOf: segmentWordArray) = 6]])	"Must be indexable words"
		ifFalse: [^ self primitiveFail].
	((self headerType: outPointerArray) = HeaderTypeSizeAndClass	"Must be 3-word header"
		and: [(self headerType: segmentWordArray) = HeaderTypeSizeAndClass])	"Must be 3-word header"
		ifFalse: [^ self primitiveFail].

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	"Use the top half of outPointers for saved headers."
	firstOut := outPointerArray + self baseHeaderSize.
	lastOut := firstOut - self bytesPerWord.
	hdrBaseOut := outPointerArray + ((self lastPointerOf: outPointerArray) // (self bytesPerWord * 2) * self bytesPerWord). "top half"

	lastSeg := segmentWordArray.
	endSeg := segmentWordArray + (self sizeBitsOf: segmentWordArray) - self bytesPerWord.

	"Write a version number for byte order and version check"
	versionOffset := self bytesPerWord.
	lastSeg := lastSeg + versionOffset.
	lastSeg > endSeg ifTrue: [^ self primitiveFail].
	self longAt: lastSeg put: self imageSegmentVersion.

	"Allocate top 1/8 of segment for table of internal oops and saved headers"
	firstIn := endSeg - ((self sizeBitsOf: segmentWordArray) // (self bytesPerWord * 8) * self bytesPerWord).  "Take 1/8 of seg"
	lastIn := firstIn - self bytesPerWord.
	hdrBaseIn := firstIn + ((self sizeBitsOf: segmentWordArray) // (self bytesPerWord * 16) * self bytesPerWord). "top half of that"

	"First mark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitOr: self markBit).
	lastPtr := arrayOfRoots + (self lastPointerOf: arrayOfRoots).
	fieldPtr := arrayOfRoots + self baseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop := self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitOr: self markBit)].
		fieldPtr := fieldPtr + self bytesPerWord].

	"Then do a mark pass over all objects.  This will stop at our marked roots,
	thus leaving our segment unmarked in their shadow."
	savedYoungStart := youngStart.
	youngStart := self startOfMemory.  "process all of memory"
		"clear the recycled context lists"
		freeContexts := NilContext.
		freeLargeContexts := NilContext.
	self markAndTraceInterpreterOops.	"and special objects array"
	youngStart := savedYoungStart.
	
	"Finally unmark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitAnd: self allButMarkBit).
	fieldPtr := arrayOfRoots + self baseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop := self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitAnd: self allButMarkBit)].
		fieldPtr := fieldPtr + self bytesPerWord].

	"All external objects, and only they, are now marked.
	Copy the array of roots into the segment, and forward its oop."
	lastIn := lastIn + self bytesPerWord.
	lastIn >= hdrBaseIn ifTrue: [successFlag := false].
	lastSeg := self copyObj: arrayOfRoots toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn).
	successFlag ifFalse:
		[lastIn := lastIn - self bytesPerWord.
		self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
		^ self primitiveFailAfterCleanup: outPointerArray].

	"Now run through the segment fixing up all the pointers.
	Note that more objects will be added to the segment as we make our way along."
	segOop := self oopFromChunk: segmentWordArray + versionOffset + self baseHeaderSize.
	[segOop <= lastSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type=0 or 1) -- start with that."
					fieldPtr := segOop - self bytesPerWord.  doingClass := true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr := segOop + self baseHeaderSize.  doingClass := false].
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"

		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop := self longAt: fieldPtr.
			doingClass ifTrue:
				[hdrTypeBits := fieldOop bitAnd: TypeMask.
				fieldOop := fieldOop - hdrTypeBits].
			(self isIntegerObject: fieldOop)
				ifTrue: ["Just an integer -- nothing to do"
						fieldPtr := fieldPtr + self bytesPerWord]
				ifFalse:
				[header := self longAt: fieldOop.
				(header bitAnd: TypeMask) = HeaderTypeFree
					ifTrue: ["Has already been forwarded -- this is the link"
							mapOop := header bitAnd: self allButTypeMask]
					ifFalse:
					[((self longAt: fieldOop) bitAnd: self markBit) = 0
						ifTrue:
							["Points to an unmarked obj -- an internal pointer.
							Copy the object into the segment, and forward its oop."
							lastIn := lastIn + self bytesPerWord.
							lastIn >= hdrBaseIn ifTrue: [successFlag := false].
							lastSeg := self copyObj: fieldOop toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn).
							successFlag ifFalse:
								["Out of space in segment"
								lastIn := lastIn - self bytesPerWord.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^ self primitiveFailAfterCleanup: outPointerArray].
							mapOop := (self longAt: fieldOop) bitAnd: self allButTypeMask]
						ifFalse:
							["Points to a marked obj -- an external pointer.
							Map it as a tagged index in outPointers, and forward its oop."
							lastOut := lastOut + self bytesPerWord.
							lastOut >= hdrBaseOut ifTrue:
								["Out of space in outPointerArray"
								lastOut := lastOut - self bytesPerWord.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^ self primitiveFailAfterCleanup: outPointerArray].
.							mapOop := lastOut - outPointerArray bitOr: 16r80000000.
							self forward: fieldOop to: mapOop
								savingOopAt: lastOut andHeaderAt: hdrBaseOut + (lastOut - firstOut)]].
					"Replace the oop by its mapped value"
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr := fieldPtr + (self bytesPerWord*2).
								doingClass := false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr := fieldPtr + self bytesPerWord].
]].
		segOop := self objectAfter: segOop].

	self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.

	"Truncate the outPointerArray..."
	((outPointerArray + (self lastPointerOf: outPointerArray) - lastOut) < 12
		or: [(endSeg - lastSeg) < 12]) ifTrue:
			["Not enough room to insert simple 3-word headers"
			^ self primitiveFailAfterCleanup: outPointerArray].
	extraSize := self extraHeaderBytes: segmentWordArray.
	hdrTypeBits := self headerType: segmentWordArray.
	"Copy the 3-word wordArray header to establish a free chunk."
	self transfer: 3
		from: segmentWordArray - extraSize
		to: lastOut+self bytesPerWord.
	"Adjust the size of the original as well as the free chunk."
	self longAt: lastOut+self bytesPerWord
		put: outPointerArray + (self lastPointerOf: outPointerArray) - lastOut - extraSize + hdrTypeBits.
	self longAt: outPointerArray-extraSize
		put: lastOut - firstOut + (self bytesPerWord*2) + hdrTypeBits.
	"Note that pointers have been stored into roots table"
	self beRootIfOld: outPointerArray.

	"Truncate the image segment..."
	"Copy the 3-word wordArray header to establish a free chunk."
	self transfer: 3
		from: segmentWordArray - extraSize
		to: lastSeg+self bytesPerWord.
	"Adjust the size of the original as well as the free chunk."
	self longAt: segmentWordArray-extraSize
		put: lastSeg - segmentWordArray + self baseHeaderSize + hdrTypeBits.
	self longAt: lastSeg+self bytesPerWord
		put: endSeg - lastSeg - extraSize + hdrTypeBits.

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	self pop: 3.  "...leaving the receiver on the stack as return value"

]

{ #category : #'object access primitives' }
Interpreter >> primitiveStoreStackp [
	"Atomic store into context stackPointer. 
	Also ensures that any newly accessible cells are initialized to nil "
	| ctxt newStackp stackp |
	ctxt := self stackValue: 1.
	newStackp := self stackIntegerValue: 0.
	self success: (self oop: newStackp isGreaterThanOrEqualTo: 0).
	self success: (self oop: newStackp isLessThanOrEqualTo: (self largeContextSize - self baseHeaderSize // self bytesPerWord - CtxtTempFrameStart)).
	successFlag ifFalse: [^ self primitiveFail].
	stackp := self fetchStackPointerOf: ctxt.
	(self oop: newStackp isGreaterThan: stackp) ifTrue: ["Nil any newly accessible cells"
			stackp + 1 to: newStackp do: [:i | self storePointer: i + CtxtTempFrameStart - 1 ofObject: ctxt withValue: nilObj]].
	self storeStackPointerValue: newStackp inContext: ctxt.
	self pop: 1
]

{ #category : #'array primitives' }
Interpreter >> primitiveStringAt [

	self commonAt: true.
]

{ #category : #'array primitives' }
Interpreter >> primitiveStringAtPut [

	self commonAtPut: true.
]

{ #category : #'array primitives' }
Interpreter >> primitiveStringReplace [
	" 
	<array> primReplaceFrom: start to: stop with: replacement 
	startingAt: repStart  
	<primitive: 105>
	"
	| array start stop repl replStart hdr arrayFmt totalLength arrayInstSize replFmt replInstSize srcIndex |
	array := self stackValue: 4.
	start := self stackIntegerValue: 3.
	stop := self stackIntegerValue: 2.
	repl := self stackValue: 1.
	replStart := self stackIntegerValue: 0.

	successFlag ifFalse: [^ self primitiveFail].
	(self isIntegerObject: repl) ifTrue: ["can happen in LgInt copy"
			^ self primitiveFail].

	hdr := self baseHeader: array.
	arrayFmt := hdr >> 8 bitAnd: 15.
	totalLength := self lengthOf: array baseHeader: hdr format: arrayFmt.
	arrayInstSize := self fixedFieldsOf: array format: arrayFmt length: totalLength.
	(start >= 1 and: [start - 1 <= stop and: [stop + arrayInstSize <= totalLength]])
		ifFalse: [^ self primitiveFail].

	hdr := self baseHeader: repl.
	replFmt := hdr >> 8 bitAnd: 15.
	totalLength := self lengthOf: repl baseHeader: hdr format: replFmt.
	replInstSize := self fixedFieldsOf: repl format: replFmt length: totalLength.
	(replStart >= 1 and: [stop - start + replStart + replInstSize <= totalLength])
		ifFalse: [^ self primitiveFail].

	"Array formats (without byteSize bits, if bytes array) must be same "
	arrayFmt < 8
		ifTrue: [arrayFmt = replFmt
				ifFalse: [^ self primitiveFail]]
		ifFalse: [(arrayFmt bitAnd: 12) = (replFmt bitAnd: 12)
				ifFalse: [^ self primitiveFail]].

	srcIndex := replStart + replInstSize - 1.
	"- 1 for 0-based access"

	arrayFmt <= 4
		ifTrue: ["pointer type objects"
			start + arrayInstSize - 1 to: stop + arrayInstSize - 1 do: [:i |
				self storePointer: i ofObject: array withValue: (self fetchPointer: srcIndex ofObject: repl).
					srcIndex := srcIndex + 1]]
		ifFalse: [arrayFmt < 8
				ifTrue: ["32-bit-word type objects"
					start + arrayInstSize - 1 to: stop + arrayInstSize - 1
						do: [:i | self storeLong32: i ofObject: array withValue: (self fetchLong32: srcIndex ofObject: repl).
							srcIndex := srcIndex + 1]]
				ifFalse: ["byte-type objects"
					start + arrayInstSize - 1 to: stop + arrayInstSize - 1
						do: [:i |  self storeByte: i ofObject: array withValue: (self fetchByte: srcIndex ofObject: repl).
							srcIndex := srcIndex + 1]]].
	"We might consider  comparing stop - start to some value here and using forceInterruptCheck"

	self pop: argumentCount "leave rcvr on stack"
]

{ #category : #'arithmetic integer primitives' }
Interpreter >> primitiveSubtract [

	self pop2AndPushIntegerIfOK: (self stackIntegerValue: 1) - (self stackIntegerValue: 0)
]

{ #category : #'arithmetic largeint primitives' }
Interpreter >> primitiveSubtractLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| integerRcvr integerArg integerArgNegated result oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'integerArgNegated' type: 'sqLong'>
	<var: 'result' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).
	successFlag ifFalse:
		[^nil].

	"In the test for the argument being most -ve we would
	 have to check for zero if we don't do so here.
	 So do so here and short-circuit the whole subtraction."
	integerArg = 0
		ifTrue: [result := integerRcvr]
		ifFalse:
			["Reverse the argument so that we can recycle the overflow code from addition.
			 But the most -ve 64-bit value can overflow, so check; 0 - most -ve = most -ve"
			integerArgNegated := 0 - integerArg.
			integerArgNegated = integerArg ifTrue:
				[^self primitiveFail].

			"Compute the preliminary result (which may overflow)"
			result := integerRcvr + integerArgNegated.

			"Now check overflow conditions. First is whether rcvr and arg are of the same sign.
			 If they are we need to check for overflow more carefully."
			(integerRcvr bitXor: integerArgNegated) < 0 ifFalse:
				"Second is whether rcvr and result are of the same sign. If not, we have an overflow."
				[(integerRcvr bitXor: result) < 0 ifTrue:
					[^self primitiveFail]]].

	oopResult := self signed64BitIntegerFor: result.
	successFlag ifTrue:
		[self pop: 2 thenPush: oopResult]
]

{ #category : #'process primitives' }
Interpreter >> primitiveSuspend [
	"Primitive. Suspend the receiver, aProcess such that it can be executed again
	by sending #resume. If the given process is not currently running, take it off
	its corresponding list. The primitive returns the list the receiver was previously on."

	| process activeProc myList |
	process := self stackTop.
	activeProc := self fetchPointer: ActiveProcessIndex
						 ofObject: self schedulerPointer.
	process == activeProc ifTrue:[
		self pop: 1.
		self push: nilObj.
		self transferTo: self wakeHighestPriority.
	] ifFalse:[
		myList := self fetchPointer: MyListIndex ofObject: process.
		"XXXX Fixme. We should really check whether myList is a kind of LinkedList or not
		but we can't easily so just do a quick check for nil which is the most common case."
		myList == self nilObject ifTrue:[^self primitiveFail].
		self removeProcess: process fromList: myList.
		successFlag ifTrue:[
			self storePointer: MyListIndex ofObject: process withValue: self nilObject.
			self pop: 1.
			self push: myList.
		].
	].

]

{ #category : #'process primitives' }
Interpreter >> primitiveTerminateTo [
	"Primitive. Terminate up the context stack from the receiver up to but not including the argument, if previousContext is on my Context stack. Make previousContext my sender. This prim has to shadow the code in ContextPart>terminateTo: to be correct"
	| thisCntx currentCntx aContext nextCntx nilOop |
	aContext := self popStack.
	thisCntx := self popStack.

	"make sure that aContext is in my chain"
	(self context: thisCntx hasSender: aContext) ifTrue:[
		nilOop := nilObj.
		currentCntx := self fetchPointer: SenderIndex ofObject: thisCntx.
		[currentCntx = aContext] whileFalse: [
			nextCntx := self fetchPointer: SenderIndex ofObject: currentCntx.
			self storePointer: SenderIndex ofObject: currentCntx withValue: nilOop.
			self storePointer: InstructionPointerIndex ofObject: currentCntx withValue: nilOop.
			currentCntx := nextCntx]].

	self storePointer: SenderIndex ofObject: thisCntx withValue: aContext.
	^self push: thisCntx
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveTestDisplayDepth [
	"Return true if the host OS does support the given display depth."
	| bitsPerPixel okay|
	bitsPerPixel := self stackIntegerValue: 0.
	successFlag ifTrue: [okay := self ioHasDisplayDepth: bitsPerPixel].
	successFlag ifTrue: [
		self pop: 2. "Pop arg+rcvr"
		self pushBool: okay].
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveTimesTwoPower [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	arg := self popInteger.
	rcvr := self popFloat.
	successFlag
		ifTrue: [ self pushFloat: (self cCode: 'ldexp(rcvr, arg)' inSmalltalk: [rcvr timesTwoPower: arg]) ]
		ifFalse: [ self unPop: 2 ].
]

{ #category : #'arithmetic float primitives' }
Interpreter >> primitiveTruncated [ 
	| rcvr frac trunc |
	<var: #rcvr type: 'double '>
	<var: #frac type: 'double '>
	<var: #trunc type: 'double '>
	rcvr := self popFloat.
	successFlag ifTrue:
		[self cCode: 'frac = modf(rcvr, &trunc)'
			inSmalltalk: [trunc := rcvr truncated].
		self flag: #Dan.		"The ranges are INCORRECT if SmallIntegers are wider than 31 bits."
		self cCode: 'success((-1073741824.0 <= trunc) && (trunc <= 1073741823.0))'
			inSmalltalk: [self success: (trunc between: SmallInteger minVal and: SmallInteger maxVal)]].
	successFlag
		ifTrue: [self cCode: 'pushInteger((sqInt) trunc)' inSmalltalk: [self pushInteger: trunc]]
		ifFalse: [self unPop: 1]
]

{ #category : #'plugin primitives' }
Interpreter >> primitiveUnloadModule [
	"Primitive. Unload the module with the given name."
	"Reloading of the module will happen *later* automatically, when a 
	function from it is called. This is ensured by invalidating current sessionID."
	| moduleName |
	self methodArgumentCount = 1 ifFalse:[^self primitiveFail].
	moduleName := self stackTop.
	(self isIntegerObject: moduleName) ifTrue:[^self primitiveFail].
	(self isBytes: moduleName) ifFalse:[^self primitiveFail].
	(self ioUnloadModule: (self oopForPointer: (self firstIndexableField: moduleName))
		OfLength: (self byteSizeOf: moduleName)) ifFalse:[^self primitiveFail].
	self flushExternalPrimitives.
	self forceInterruptCheck.
	self pop: 1 "pop moduleName; return receiver"
]

{ #category : #'system control primitives' }
Interpreter >> primitiveUtcWithOffset [
	"Answer an array with UTC microseconds since the Posix epoch and
	the current seconds offset from GMT in the local time zone.
	This is a named (not numbered) primitive in the null module (ie the VM)"
	| clock offset resultArray |

	<export: true>
	<var: #clock type: 'sqLong'>
	<var: #offset type: 'int'>
	(self cCode: 'ioUtcWithOffset(&clock, &offset)' inSmalltalk: [-1]) = -1
		ifTrue: [^ self primitiveFail].
	self pushRemappableOop: (self positive64BitIntegerFor: clock).
	resultArray := self instantiateClass: self classArray indexableSize: 2.
	self stObject: resultArray at: 1 put: self popRemappableOop.
	self stObject: resultArray at: 2 put: (self integerObjectOf: offset).
	self pop: 1 thenPush: resultArray

]

{ #category : #'system control primitives' }
Interpreter >> primitiveVMParameter [
	"Behaviour depends on argument count:
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
		
	Note: Thanks to Ian Piumarta for this primitive."

	| mem paramsArraySize result arg index statIGCDeltaTimeObj statGCTimeObj statIncrGCMSecsObj statFullGCMSecsObj resultLargePositiveInteger |
	<var: #resultLargePositiveInteger type: 'sqLong'>
	mem := self startOfMemory.
	paramsArraySize := 40.
	argumentCount = 0 ifTrue: [
		result := self instantiateClass: (self splObj: ClassArray) indexableSize: paramsArraySize.
		self pushRemappableOop:  result.
		self pushRemappableOop:  (self positive64BitIntegerFor: statFullGCMSecs).
		self pushRemappableOop:  (self positive64BitIntegerFor: statIncrGCMSecs).
		self pushRemappableOop:  (self positive64BitIntegerFor: statGCTime).
		self pushRemappableOop:  (self positive64BitIntegerFor: statIGCDeltaTime).
		statIGCDeltaTimeObj := self popRemappableOop.
		statGCTimeObj := self popRemappableOop.
		statIncrGCMSecsObj := self popRemappableOop.
		statFullGCMSecsObj := self popRemappableOop.
		result := self popRemappableOop.
		0 to: paramsArraySize - 1 do:
			[:i | self storePointer: i ofObject: result withValue: ConstZero].
	
		self storePointer: 0	ofObject: result withValue: (self positive64BitIntegerFor: youngStart - mem).
		self storePointer: 1	ofObject: result withValue: (self positive64BitIntegerFor: freeBlock - mem).
		self storePointer: 2	ofObject: result withValue: (self positive64BitIntegerFor: endOfMemory - mem).
		self storePointer: 3	ofObject: result withValue: (self integerObjectOf: allocationCount).
		self storePointer: 4	ofObject: result withValue: (self integerObjectOf: allocationsBetweenGCs).
		self storePointer: 5	ofObject: result withValue: (self integerObjectOf: tenuringThreshold).
		self storePointer: 6	ofObject: result withValue: (self integerObjectOf: statFullGCs).
		self storePointer: 7	ofObject: result withValue: statFullGCMSecsObj.
		self storePointer: 8	ofObject: result withValue: (self integerObjectOf: statIncrGCs).
		self storePointer: 9	ofObject: result withValue: statIncrGCMSecsObj.
		self storePointer: 10	ofObject: result withValue: (self integerObjectOf: statTenures).
		self storePointer: 20	ofObject: result withValue: (self integerObjectOf: rootTableCount).
		self storePointer: 21	ofObject: result withValue: (self integerObjectOf: statRootTableOverflows).
		self storePointer: 22	ofObject: result withValue: (self positive64BitIntegerFor: extraVMMemory).
		self storePointer: 23	ofObject: result withValue: (self positive64BitIntegerFor: shrinkThreshold).
		self storePointer: 24	ofObject: result withValue: (self positive64BitIntegerFor: growHeadroom).
		self storePointer: 25	ofObject: result withValue: (self integerObjectOf: interruptChecksEveryNms).
		self storePointer: 26	ofObject: result withValue: (self integerObjectOf: statMarkCount).
		self storePointer: 27	ofObject: result withValue: (self integerObjectOf: statSweepCount).
		self storePointer: 28	ofObject: result withValue: (self integerObjectOf: statMkFwdCount).
		self storePointer: 29	ofObject: result withValue: (self integerObjectOf: statCompMoveCount).
		self storePointer: 30	ofObject: result withValue: (self integerObjectOf: statGrowMemory).
		self storePointer: 31	ofObject: result withValue: (self integerObjectOf: statShrinkMemory).
		self storePointer: 32	ofObject: result withValue: (self integerObjectOf: statRootTableCount).
		self storePointer: 33	ofObject: result withValue: (self integerObjectOf: statAllocationCount).
		self storePointer: 34	ofObject: result withValue: (self integerObjectOf: statSurvivorCount).
		self storePointer: 35	ofObject: result withValue: statGCTimeObj.
		self storePointer: 36	ofObject: result withValue: (self integerObjectOf: statSpecialMarkCount).
		self storePointer: 37	ofObject: result withValue: statIGCDeltaTimeObj.
		self storePointer: 38	ofObject: result withValue: (self integerObjectOf: statpendingFinalizationSignals).
		self storePointer: 39	ofObject: result withValue: (self integerObjectOf: self bytesPerWord).
		self pop: 1 thenPush: result.
		^nil].

	arg := self stackTop.
	(self isIntegerObject: arg) ifFalse: [^self primitiveFail].
	arg := self integerValueOf: arg.
	resultLargePositiveInteger := -1.
	argumentCount = 1 ifTrue: [	 "read VM parameter"
		(arg < 1 or: [arg > paramsArraySize]) ifTrue: [^self primitiveFail].
		arg = 1		ifTrue: [resultLargePositiveInteger := youngStart - mem].
		arg = 2		ifTrue: [resultLargePositiveInteger := freeBlock - mem].
		arg = 3		ifTrue: [resultLargePositiveInteger := endOfMemory - mem].
		arg = 4		ifTrue: [result := allocationCount].
		arg = 5		ifTrue: [result := allocationsBetweenGCs].
		arg = 6		ifTrue: [result := tenuringThreshold].
		arg = 7		ifTrue: [result := statFullGCs].
		arg = 8		ifTrue: [resultLargePositiveInteger := statFullGCMSecs].
		arg = 9		ifTrue: [result := statIncrGCs].
		arg = 10		ifTrue: [resultLargePositiveInteger := statIncrGCMSecs].
		arg = 11		ifTrue: [result := statTenures].
		((arg >= 12) and: [arg <= 20]) ifTrue: [result := 0].
		arg = 21		ifTrue: [result := rootTableCount].
		arg = 22		ifTrue: [result := statRootTableOverflows].
		arg = 23		ifTrue: [resultLargePositiveInteger := extraVMMemory].
		arg = 24		ifTrue: [resultLargePositiveInteger := shrinkThreshold].
		arg = 25		ifTrue: [resultLargePositiveInteger := growHeadroom].
		arg = 26		ifTrue: [result := interruptChecksEveryNms]. 
		arg = 27		ifTrue: [result := statMarkCount]. 
		arg = 28		ifTrue: [result := statSweepCount]. 
		arg = 29		ifTrue: [result := statMkFwdCount]. 
		arg = 30		ifTrue: [result := statCompMoveCount]. 
		arg = 31		ifTrue: [result := statGrowMemory]. 
		arg = 32		ifTrue: [result := statShrinkMemory]. 
		arg = 33		ifTrue: [result := statRootTableCount]. 
		arg = 34		ifTrue: [result := statAllocationCount]. 
		arg = 35		ifTrue: [result := statSurvivorCount]. 
		arg = 36  	ifTrue: [resultLargePositiveInteger := statGCTime]. 
		arg = 37  	ifTrue: [result := statSpecialMarkCount]. 
		arg = 38  	ifTrue: [resultLargePositiveInteger := statIGCDeltaTime]. 
		arg = 39  	ifTrue: [result := statpendingFinalizationSignals]. 
		arg = 40  	ifTrue: [result := self bytesPerWord]. 
		resultLargePositiveInteger = -1 
			ifTrue: [self pop: 2 thenPush: (self integerObjectOf: result)]
			ifFalse: [self pop: 2 thenPush: (self positive64BitIntegerFor: resultLargePositiveInteger)].
		^nil].

	"write a VM parameter"
	argumentCount = 2 ifFalse: [^self primitiveFail].
	index := self stackValue: 1.
	(self isIntegerObject: index) ifFalse: [^self primitiveFail].
	index := self integerValueOf: index.
	index <= 0 ifTrue: [^self primitiveFail].
	successFlag := false.
	index = 5 ifTrue: [
		result := allocationsBetweenGCs.
		allocationsBetweenGCs := arg.
		successFlag := true].
	index = 6 ifTrue: [
		result := tenuringThreshold.
		tenuringThreshold := arg.
		successFlag := true].
	index = 23 ifTrue: [
		result := extraVMMemory.
		extraVMMemory := arg.
		successFlag := true].
	index = 24 ifTrue: [
		result := shrinkThreshold.
		arg > 0 ifTrue:[
			shrinkThreshold := arg.
			successFlag := true]].
	index = 25 ifTrue: [
		result := growHeadroom.
		arg > 0 ifTrue:[
			growHeadroom := arg.
			successFlag := true]].
	index = 26 ifTrue: [
		arg > 1 ifTrue:[
			result := interruptChecksEveryNms.
			interruptChecksEveryNms := arg.
			successFlag := true]]. 

	successFlag ifTrue: [
		self pop: 3 thenPush: (self integerObjectOf: result).  "return old value"
		^ nil].

	self primitiveFail.  "attempting to write a read-only parameter"




]

{ #category : #'system control primitives' }
Interpreter >> primitiveVMPath [
	"Return a string containing the path name of VM's directory."

	| s sz |
	sz := self vmPathSize.
	s := self instantiateClass: (self splObj: ClassString) indexableSize: sz.
	self vmPathGet: (s + self baseHeaderSize) Length: sz.
	self pop: 1 thenPush: s.

]

{ #category : #'other primitives' }
Interpreter >> primitiveVMVersion [
	"Answer a string corresponding to the version of virtual machine. This
	represents the version level of the Smalltalk source code (interpreter and various
	plugins) that is translated to C by a CCodeGenerator,  in addition to the external
	platform source code, typically written in C and managed separately for each platform.
	By convention, this is a string composed of the interpreter source version and the
	platform source version, e.g. '4.0.2-2172'.
	
	This is a named (not numbered) primitive in the null module (ie the VM)"
	
	| len versionString p |
	<export: true>
	<var: #p type: 'char *'>
	self isDefined: 'VM_VERSION'
		inSmalltalk: [versionString := '']
		comment: 'version level of interpreter plus platform support code'
		ifTrue: [len := self cCode: 'strlen(VM_VERSION)' inSmalltalk: [0].
			versionString := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: len.
			p := interpreterProxy arrayValueOf: versionString.
			self cCode: 'strncpy(p, VM_VERSION, len)']
		ifFalse: [^interpreterProxy primitiveFail].
	self pop: 1 thenPush: versionString

]

{ #category : #'control primitives' }
Interpreter >> primitiveValue [
	| blockContext blockArgumentCount initialIP |
	blockContext := self stackValue: argumentCount.
	blockArgumentCount := self argumentCountOfBlock: blockContext.
	self success: (argumentCount = blockArgumentCount
			and: [(self fetchPointer: CallerIndex ofObject: blockContext) = nilObj]).
	successFlag
		ifTrue: [self transfer: argumentCount
				fromIndex: self stackPointerIndex - argumentCount + 1
				ofObject: activeContext
				toIndex: TempFrameStart
				ofObject: blockContext.

			"Assume: The call to transfer:... makes blockContext a root if necessary,
			 allowing use to use unchecked stored in the following code."
			self pop: argumentCount + 1.
			initialIP := self fetchPointer: InitialIPIndex	ofObject: blockContext.
			self storePointerUnchecked: InstructionPointerIndex ofObject: blockContext withValue: initialIP.
			self storeStackPointerValue: argumentCount inContext: blockContext.
			self storePointerUnchecked: CallerIndex ofObject: blockContext withValue: activeContext.
			self newActiveContext: blockContext]
]

{ #category : #'control primitives' }
Interpreter >> primitiveValueUninterruptably [
	"The only purpose of this primitive is to indicate that the new EH mechanisms are supported."
	<inline: false>
	^self primitiveValue
]

{ #category : #'control primitives' }
Interpreter >> primitiveValueWithArgs [
	| argumentArray blockContext blockArgumentCount arrayArgumentCount initialIP |
	argumentArray := self popStack.
	blockContext := self popStack.
	blockArgumentCount := self argumentCountOfBlock: blockContext.
	"If the argArray isnt actually an Array we ahve to unpop the above two"
	(self isArray: argumentArray) ifFalse: [self unPop:2. ^self primitiveFail].

	successFlag ifTrue: [arrayArgumentCount := self fetchWordLengthOf: argumentArray.
			self success: (arrayArgumentCount = blockArgumentCount
						and: [(self fetchPointer: CallerIndex ofObject: blockContext) = nilObj])].
	successFlag
		ifTrue: [self
				transfer: arrayArgumentCount
				fromIndex: 0
				ofObject: argumentArray
				toIndex: TempFrameStart
				ofObject: blockContext.
			"Assume: The call to transfer:... makes blockContext a root if necessary, 
			allowing use to use unchecked stored in the following code. "
			initialIP := self fetchPointer: InitialIPIndex ofObject: blockContext.
			self
				storePointerUnchecked: InstructionPointerIndex
				ofObject: blockContext
				withValue: initialIP.
			self storeStackPointerValue: arrayArgumentCount inContext: blockContext.
			self
				storePointerUnchecked: CallerIndex
				ofObject: blockContext
				withValue: activeContext.
			self newActiveContext: blockContext]
		ifFalse: [self unPop: 2]
]

{ #category : #'process primitives' }
Interpreter >> primitiveWait [

	| sema excessSignals activeProc |
	sema := self stackTop.  "rcvr"
	self assertClassOf: sema is: (self splObj: ClassSemaphore).
	successFlag ifTrue: [
		excessSignals :=
			self fetchInteger: ExcessSignalsIndex ofObject: sema.
		excessSignals > 0 ifTrue: [
			self storeInteger: ExcessSignalsIndex
				ofObject: sema withValue: excessSignals - 1.
		] ifFalse: [
			activeProc := self fetchPointer: ActiveProcessIndex
								 ofObject: self schedulerPointer.
			self addLastLink: activeProc toList: sema.
			self transferTo: self wakeHighestPriority.
		].
	].
]

{ #category : #'process primitives' }
Interpreter >> primitiveYield [
"primitively do the equivalent of Process>yield"
	| activeProc priority processLists processList |
	activeProc := self fetchPointer: ActiveProcessIndex
						 ofObject: self schedulerPointer.
	priority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	processLists := self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	processList := self fetchPointer: priority - 1 ofObject: processLists.

	(self isEmptyList: processList) ifFalse:[
		self addLastLink: activeProc toList: processList.
		self transferTo: self wakeHighestPriority]
]

{ #category : #'debug printing' }
Interpreter >> print: s [
	"For testing in Smalltalk, this method should be overridden in a subclass."

	<var: #s type: 'char *'>
	self cCode: 'printf("%s", s)'.
]

{ #category : #'debug printing' }
Interpreter >> printAllStacks [
	"Print all the stacks of all running processes, including those that are currently suspended."
	| oop proc ctx |
	<export: true> "exported to permit access from plugins"
	proc := self fetchPointer: ActiveProcessIndex ofObject: self schedulerPointer.
	self printNameOfClass: (self fetchClassOf: proc) count: 5.
	self cr.
	self printCallStackOf: activeContext. "first the active context"
	oop := self firstObject.
	[self oop: oop isLessThan: endOfMemory] whileTrue:[
		(self fetchClassOf: oop) == self classSemaphore ifTrue:[
			self cr.
			proc := self fetchPointer: FirstLinkIndex ofObject: oop.
			[proc == self nilObject] whileFalse:[
				self printNameOfClass: (self fetchClassOf: proc) count: 5.
				self cr.
				ctx := self fetchPointer: SuspendedContextIndex ofObject: proc.
				ctx == self nilObject ifFalse:[self printCallStackOf: ctx].
				proc := self fetchPointer: NextLinkIndex ofObject: proc].
		].
		oop := self objectAfter: oop.
	].
]

{ #category : #'debug printing' }
Interpreter >> printCallStack [
	^self printCallStackOf: activeContext
]

{ #category : #'debug printing' }
Interpreter >> printCallStackOf: aContext [

	| ctxt home methClass methodSel message |
	<inline: false>
	ctxt := aContext.
	[ctxt = nilObj] whileFalse: [
		(self fetchClassOf: ctxt) = (self splObj: ClassBlockContext)
			ifTrue: [ home := self fetchPointer: HomeIndex ofObject: ctxt ]
			ifFalse: [ home := ctxt ].
		methClass :=
			self findClassOfMethod: (self fetchPointer: MethodIndex ofObject: home)
					   forReceiver: (self fetchPointer: ReceiverIndex ofObject: home).
		methodSel :=
			self findSelectorOfMethod: (self fetchPointer: MethodIndex ofObject: home)
						 forReceiver: (self fetchPointer: ReceiverIndex ofObject: home).
		self printNum: ctxt.
		self print: ' '.
		ctxt = home ifFalse: [ self print: '[] in ' ].
		self printNameOfClass: methClass count: 5.
		self print: '>'.
		methodSel = nilObj
			ifTrue: [self print: '?']
			ifFalse: [self printStringOf: methodSel].
		methodSel = (self splObj: SelectorDoesNotUnderstand) ifTrue: [
			"print arg message selector"
			message := self fetchPointer: 0 + TempFrameStart ofObject: home.
			methodSel := self fetchPointer: MessageSelectorIndex ofObject: message.
			self print: ' '.
			self printStringOf: methodSel.
		].
		self cr.

		ctxt := (self fetchPointer: SenderIndex ofObject: ctxt).
	].
]

{ #category : #'debug printing' }
Interpreter >> printChar: aByte [
	"For testing in Smalltalk, this method should be overridden in a subclass."

	self putchar: aByte.
]

{ #category : #'debug printing' }
Interpreter >> printNameOfClass: classOop count: cnt [
	"Details: The count argument is used to avoid a possible infinite recursion if classOop is a corrupted object."

	cnt <= 0 ifTrue: [ ^ self print: 'bad class' ].
	(self sizeBitsOf: classOop) = (7 * self bytesPerWord)	"(Metaclass instSize+1 * 4)"
		ifTrue: [self printNameOfClass: (self fetchPointer: 5 "thisClass" ofObject: classOop) 
					count: cnt - 1.
				self print: ' class']
	ifFalse: [self printStringOf: (self fetchPointer: 6 "name" ofObject: classOop)]
]

{ #category : #'debug printing' }
Interpreter >> printNum: n [
	"For testing in Smalltalk, this method should be overridden in a subclass."

	self cCode: 'printf("%ld", (long) n)'.
]

{ #category : #'debug printing' }
Interpreter >> printStringOf: oop [

	| fmt cnt i |
	(self isIntegerObject: oop) ifTrue:[^nil].
	fmt := self formatOf: oop.
	fmt < 8 ifTrue: [ ^nil ].

	cnt := 100 min: (self lengthOf: oop).
	i := 0.
	[i < cnt] whileTrue: [
		self printChar: (self fetchByte: i ofObject: oop).
		i := i + 1.
	].
]

{ #category : #'debug printing' }
Interpreter >> printUnbalancedStack: primIdx [
	<inline: false>
	self print: 'Stack unbalanced after '.
	successFlag 
		ifTrue:[self print:'successful primitive '] 
		ifFalse:[self print: 'failed primitive '].
	self printNum: primIdx.
	self cr.
		
]

{ #category : #'debug printing' }
Interpreter >> printUnbalancedStackFromNamedPrimitive [
	| lit |
	<inline: false>
	self print: 'Stack unbalanced after '.
	successFlag 
		ifTrue:[self print:'successful '] 
		ifFalse:[self print: 'failed '].
	lit := self literal: 0 ofMethod: newMethod.
	self printStringOf: (self fetchPointer: 1 ofObject: lit).
	self print:' in '.
	self printStringOf: (self fetchPointer: 0 ofObject: lit).
	self cr.
		
]

{ #category : #contexts }
Interpreter >> push: object [

	| sp |
	self longAt: (sp := stackPointer + self bytesPerWord) put: object.
	stackPointer := sp.
]

{ #category : #'stack bytecodes' }
Interpreter >> pushActiveContextBytecode [
	"Puts reclaimability of this context in question."

	self fetchNextBytecode.
	reclaimableContextCount := 0.
	self internalPush: activeContext.

]

{ #category : #contexts }
Interpreter >> pushBool: trueOrFalse [

	trueOrFalse
		ifTrue: [ self push: trueObj ]
		ifFalse: [ self push: falseObj ].
]

{ #category : #'stack bytecodes' }
Interpreter >> pushClosureCopyCopiedValuesBytecode [
	"The compiler has pushed the values to be copied, if any.  Find numArgs and numCopied in the byte following.
	 Create a Closure with space for the copiedValues and pop numCopied values off the stack into the closure.
	 Set numArgs as specified, and set startpc to the pc following the block size and jump over that code."
	| newClosure numArgsNumCopied numArgs numCopied blockSize |
	self bytesPerWord == 4
		ifTrue: [imageFormatVersionNumber := 6504]
		ifFalse: [imageFormatVersionNumber := 68002].
	numArgsNumCopied := self fetchByte.
	numArgs := numArgsNumCopied bitAnd: 16rF.
	numCopied := numArgsNumCopied bitShift: -4.
	"Split blockSize := (self fetchByte * 256) + self fetchByte. into two because evaluation order in C is undefined."
	blockSize := self fetchByte << 8.
	blockSize := blockSize + self fetchByte.
	self externalizeIPandSP. "This is a pain."
	newClosure := self
					closureNumArgs: numArgs
					instructionPointer: ((self oopForPointer: localIP) + 2 - (method + self baseHeaderSize))
					numCopiedValues: numCopied.
	self internalizeIPandSP.
	"Assume: have just allocated a new closure; it must be young. Thus, can use unchecked stores."
	self storePointerUnchecked: ClosureOuterContextIndex ofObject: newClosure withValue: activeContext.
	reclaimableContextCount := 0. "The closure refers to thisContext so it can't be reclaimed."
	numCopied > 0 ifTrue:
		[0 to: numCopied - 1 do:
			[:i|
			"Assume: have just allocated a new BlockClosure; it must be young.
			 Thus, can use unchecked stores."
			 self storePointerUnchecked: i + ClosureFirstCopiedValueIndex
				ofObject: newClosure
				withValue: (self internalStackValue: numCopied - i - 1)].
		 self internalPop: numCopied].
	localIP := localIP + blockSize.
	self fetchNextBytecode.
	self internalPush: newClosure
]

{ #category : #'stack bytecodes' }
Interpreter >> pushConstantFalseBytecode [

	self fetchNextBytecode.
	self internalPush: falseObj.

]

{ #category : #'stack bytecodes' }
Interpreter >> pushConstantMinusOneBytecode [

	self fetchNextBytecode.
	self internalPush: ConstMinusOne.

]

{ #category : #'stack bytecodes' }
Interpreter >> pushConstantNilBytecode [

	self fetchNextBytecode.
	self internalPush: nilObj.

]

{ #category : #'stack bytecodes' }
Interpreter >> pushConstantOneBytecode [

	self fetchNextBytecode.
	self internalPush: ConstOne.

]

{ #category : #'stack bytecodes' }
Interpreter >> pushConstantTrueBytecode [

	self fetchNextBytecode.
	self internalPush: trueObj.

]

{ #category : #'stack bytecodes' }
Interpreter >> pushConstantTwoBytecode [

	self fetchNextBytecode.
	self internalPush: ConstTwo.

]

{ #category : #'stack bytecodes' }
Interpreter >> pushConstantZeroBytecode [

	self fetchNextBytecode.
	self internalPush: ConstZero.

]

{ #category : #'stack bytecodes' }
Interpreter >> pushFloat: f [

	<var: #f type: 'double '>
	self push: (self floatObjectOf: f).
]

{ #category : #contexts }
Interpreter >> pushInteger: integerValue [
	self push: (self integerObjectOf: integerValue).
]

{ #category : #'stack bytecodes' }
Interpreter >> pushLiteralConstant: literalIndex [

	self internalPush: (self literal: literalIndex).
]

{ #category : #'stack bytecodes' }
Interpreter >> pushLiteralConstantBytecode [

	self flag: #'requires currentBytecode to be expanded to a constant'.
	self fetchNextBytecode.
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	self pushLiteralConstant: (currentBytecode bitAnd: 16r1F).

]

{ #category : #'stack bytecodes' }
Interpreter >> pushLiteralVariable: literalIndex [

	self internalPush:
		(self fetchPointer: ValueIndex ofObject: (self literal: literalIndex)).
]

{ #category : #'stack bytecodes' }
Interpreter >> pushLiteralVariableBytecode [

	self flag: #'requires currentBytecode to be expanded to a constant'.
	self fetchNextBytecode.
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	self pushLiteralVariable: (currentBytecode bitAnd: 16r1F).

]

{ #category : #'stack bytecodes' }
Interpreter >> pushNewArrayBytecode [
	| size popValues array |
	size := self fetchByte.
	popValues := size > 127.
	size := size bitAnd: 127.
	self fetchNextBytecode.
	self externalizeIPandSP.
	array := self instantiateClass: (self splObj: ClassArray) indexableSize: size.
	self internalizeIPandSP.
	popValues ifTrue:
		[0 to: size - 1 do:
			[:i|
			"Assume: have just allocated a new Array; it must be young. Thus, can use unchecked stores."
			self storePointerUnchecked: i ofObject: array withValue: (self internalStackValue: size - i - 1)].
		 self internalPop: size].
	self internalPush: array
]

{ #category : #'stack bytecodes' }
Interpreter >> pushReceiverBytecode [

	self fetchNextBytecode.
	self internalPush: receiver.

]

{ #category : #'stack bytecodes' }
Interpreter >> pushReceiverVariable: fieldIndex [

	self internalPush:
		(self fetchPointer: fieldIndex ofObject: receiver).
]

{ #category : #'stack bytecodes' }
Interpreter >> pushReceiverVariableBytecode [

	self flag: #'requires currentBytecode to be expanded to a constant'.
	self fetchNextBytecode.
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	self pushReceiverVariable: (currentBytecode bitAnd: 16rF).

]

{ #category : #'stack bytecodes' }
Interpreter >> pushRemoteTemp: index inVectorAt: tempVectorIndex [
	| tempVector |
	tempVector := self temporary: tempVectorIndex.
	self internalPush: (self fetchPointer: index ofObject: tempVector)
]

{ #category : #'stack bytecodes' }
Interpreter >> pushRemoteTempLongBytecode [
	| remoteTempIndex tempVectorIndex |
	remoteTempIndex := self fetchByte.
	tempVectorIndex := self fetchByte.
	self fetchNextBytecode.
	self pushRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex
]

{ #category : #'stack bytecodes' }
Interpreter >> pushTemporaryVariable: temporaryIndex [

	self internalPush: (self temporary: temporaryIndex).
]

{ #category : #'stack bytecodes' }
Interpreter >> pushTemporaryVariableBytecode [

	self flag: #'requires currentBytecode to be expanded to a constant'.
	self fetchNextBytecode.
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	self pushTemporaryVariable: (currentBytecode bitAnd: 16rF).

]

{ #category : #'image save/restore' }
Interpreter >> putLong: aWord toFile: aFile [
	"Append aWord to aFile in this platforms 'natural' byte order.  (Bytes will be swapped, if
	necessary, when the image is read on a different platform.) Set successFlag to false if
	the write fails."

	| objectsWritten |
	<var: #aFile type: 'sqImageFile '>

	objectsWritten := self cCode: 'sqImageFileWrite(&aWord, sizeof(aWord), 1, aFile)'.
	self success: objectsWritten = 1.

]

{ #category : #'process primitive support' }
Interpreter >> putToSleep: aProcess [
	"Save the given process on the scheduler process list for its priority."

	| priority processLists processList |
	priority := self quickFetchInteger: PriorityIndex ofObject: aProcess.
	processLists := self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	processList := self fetchPointer: priority - 1 ofObject: processLists.
	self addLastLink: aProcess toList: processList.
]

{ #category : #'process primitive support' }
Interpreter >> quickCheckForInterrupts [
	"Quick check for possible user or timer interrupts. Decrement a counter and only do a real check when counter reaches zero or when a low space or user interrupt is pending."
	"Note: Clients that trigger interrupts should set use forceInterruptCheck to set interruptCheckCounter to zero and get immediate results."
	"Note: Requires that instructionPointer and stackPointer be external."

	((interruptCheckCounter := interruptCheckCounter - 1) <= 0)
		ifTrue: [self checkForInterrupts].

]

{ #category : #utilities }
Interpreter >> quickFetchInteger: fieldIndex ofObject: objectPointer [
	"Return the integer value of the field without verifying that it is an integer value! For use in time-critical places where the integer-ness of the field can be guaranteed."

	^ self integerValueOf: (self fetchPointer: fieldIndex ofObject: objectPointer).
]

{ #category : #'image save/restore' }
Interpreter >> readImageFormatFromFile: f StartingAt: imageOffset [
	"Read an image header from the given file stream, and answer the image format
	version number for the saved image. Exported to allow platform support code to
	query image files for image format number."

	<export: true>
	<var: #f type: 'sqImageFile '>
	<var: #imageOffset type: 'squeakFileOffsetType '>

	self checkImageVersionFrom: f startingAt: imageOffset.
	^ imageFormatInitialVersion

]

{ #category : #'image save/restore' }
Interpreter >> readImageFromFile: f HeapSize: desiredHeapSize StartingAt: imageOffset [
	"Read an image from the given file stream, allocating the given amount of memory to its object heap. Fail if the image has an unknown format or requires more than the given amount of memory."
	"Details: This method detects when the image was stored on a machine with the opposite byte ordering from this machine and swaps the bytes automatically. Furthermore, it allows the header information to start 512 bytes into the file, since some file transfer programs for the Macintosh apparently prepend a Mac-specific header of this size. Note that this same 512 bytes of prefix area could also be used to store an exec command on Unix systems, allowing one to launch Smalltalk by invoking the image name as a command."
	"This code is based on C code by Ian Piumarta and Smalltalk code by Tim Rowledge. Many thanks to both of you!!"

	| swapBytes headerStart headerSize dataSize oldBaseAddr minimumMemory memStart bytesRead bytesToShift heapSize |
	<var: #f type: 'sqImageFile '>
	<var: #desiredHeapSize type: 'usqInt'>
	<var: #headerStart type: 'squeakFileOffsetType '>
	<var: #dataSize type: 'size_t '>
	<var: #imageOffset type: 'squeakFileOffsetType '>

	swapBytes := self checkImageVersionFrom: f startingAt: imageOffset.
	headerStart := (self sqImageFilePosition: f) - self bytesPerWord.  "record header start position"

	headerSize			:= self getLongFromFile: f swap: swapBytes.
	dataSize				:= self getLongFromFile: f swap: swapBytes.
	oldBaseAddr			:= self getLongFromFile: f swap: swapBytes.
	specialObjectsOop	:= self getLongFromFile: f swap: swapBytes.
	lastHash			:= self getLongFromFile: f swap: swapBytes.
	savedWindowSize	:= self getLongFromFile: f swap: swapBytes.
	fullScreenFlag		:= self oldFormatFullScreenFlag: (self getLongFromFile: f swap: swapBytes).
	extraVMMemory		:= self getLongFromFile: f swap: swapBytes.

	lastHash = 0 ifTrue: [
		"lastHash wasn't stored (e.g. by the cloner); use 999 as the seed"
		lastHash := 999].

	"decrease Squeak object heap to leave extra memory for the VM"
	heapSize := self cCode: 'reserveExtraCHeapBytes(desiredHeapSize, extraVMMemory)'.

	"compare memory requirements with availability".
	minimumMemory := dataSize + 100000.  "need at least 100K of breathing room"
	heapSize < minimumMemory ifTrue: [
		self insufficientMemorySpecifiedError].

	"allocate a contiguous block of memory for the Squeak heap"
	memory := self
		allocateMemory: heapSize
		minimum: minimumMemory
		imageFile: f
		headerSize: headerSize.
	memory = nil ifTrue: [self insufficientMemoryAvailableError].

	memStart := self startOfMemory.
	memoryLimit := (memStart + heapSize) - 24.  "decrease memoryLimit a tad for safety"
	endOfMemory := memStart + dataSize.

	"position file after the header"
	self sqImageFile: f Seek: headerStart + headerSize.

	"read in the image in bulk, then swap the bytes if necessary"
	bytesRead := self
		sqImage: (self pointerForOop: memory)
		read: f
		size: (self cCode: 'sizeof(unsigned char)')
		length: dataSize.
	bytesRead ~= dataSize ifTrue: [self unableToReadImageError].

	headerTypeBytes at: 0 put: self bytesPerWord * 2.		"3-word header (type 0)"	
	headerTypeBytes at: 1 put: self bytesPerWord.		"2-word header (type 1)"
	headerTypeBytes at: 2 put: 0.					"free chunk (type 2)"	
	headerTypeBytes at: 3 put: 0.					"1-word header (type 3)"

	swapBytes ifTrue: [self reverseBytesInImage].

	"compute difference between old and new memory base addresses"
	bytesToShift := memStart - oldBaseAddr.
	self initializeInterpreter: bytesToShift.  "adjusts all oops to new location"
	self isBigEnder. "work out the machine endianness and cache the answer"
	
	(self imageFormatInitialVersion bitAnd: 1) = 1
		ifTrue: ["Low order bit set, indicating that the image was saved from
			a StackInterpreter (Cog) VM. Storage of all Float objects must be
			returned to older object memory format."
			self normalizeFloatOrderingInImage].
 
	^ dataSize

]

{ #category : #'image save/restore' }
Interpreter >> readableFormat: imageVersion [
	"Anwer true if images of the given format are readable by this interpreter. Allows
	a virtual machine to accept selected older image formats.  In our case we can
	select a newer (closure) image format as well as the existing format. Images with
	platform-ordered floats (StackInterpreter and Cog format) are readable but will be
	converted to traditional word ordering."

	self bytesPerWord = 4
		ifTrue: [^ (imageVersion = 6502	"Original 32-bit Squeak image format"
			or: [imageVersion = 6504])		"32-bit with closures"
			or: [imageVersion = 6505]]		"32-bit with closures and platform-ordered floats"
		ifFalse: [^ (imageVersion = 68000	"Original 64-bit Squeak image format"
			or: [imageVersion = 68002])	"64-bit with closures"
			or: [imageVersion = 68003]]	"64-bit with closures and platform-ordered floats"

]

{ #category : #contexts }
Interpreter >> reestablishContextPriorToCallback: callbackContext [
	"callbackContext is an activation of invokeCallback:stack:registers:jmpbuf:.  Its sender
	 is the interpreter's state prior to the callback.  Reestablish that state."
	| calloutContext |
	<export: true>
	(self fetchClassOf: callbackContext) ~~ (self splObj: ClassMethodContext) ifTrue:
		[^false].
	calloutContext := self fetchPointer: SenderIndex ofObject: callbackContext.
	self newActiveContext: calloutContext.
	^true
]

{ #category : #'process primitive support' }
Interpreter >> removeFirstLinkOfList: aList [ 
	"Remove the first process from the given linked list."
	| first last next |
	first := self fetchPointer: FirstLinkIndex ofObject: aList.
	last := self fetchPointer: LastLinkIndex ofObject: aList.
	first = last
		ifTrue: [self storePointer: FirstLinkIndex ofObject: aList withValue: nilObj.
			self storePointer: LastLinkIndex ofObject: aList withValue: nilObj]
		ifFalse: [next := self fetchPointer: NextLinkIndex ofObject: first.
			self storePointer: FirstLinkIndex ofObject: aList withValue: next].
	self storePointer: NextLinkIndex ofObject: first withValue: nilObj.
	^ first
]

{ #category : #'process primitive support' }
Interpreter >> removeProcess: aProcess fromList: aList [ 
	"Remove a given process from a linked list. May fail if aProcess is not on the list."
	| firstLink lastLink nextLink tempLink |
	firstLink := self fetchPointer: FirstLinkIndex ofObject: aList.
	lastLink := self fetchPointer: LastLinkIndex ofObject: aList.
	aProcess  == firstLink ifTrue:[
		nextLink := self fetchPointer: NextLinkIndex ofObject: aProcess .
		self storePointer: FirstLinkIndex ofObject: aList withValue: nextLink.
		aProcess  == lastLink ifTrue:[
			self storePointer: LastLinkIndex ofObject: aList withValue: self nilObject.
		].
	] ifFalse:[
		tempLink := firstLink.
		[tempLink == self nilObject ifTrue:[^self success: false]. "fail"
		nextLink := self fetchPointer: NextLinkIndex ofObject: tempLink.
		nextLink == aProcess] whileFalse:[
			tempLink := self fetchPointer: NextLinkIndex ofObject: tempLink.
		].
		nextLink := self fetchPointer: NextLinkIndex ofObject: aProcess.
		self storePointer: NextLinkIndex ofObject: tempLink withValue: nextLink.
		aProcess  == lastLink ifTrue:[
			self storePointer: LastLinkIndex ofObject: aList withValue: tempLink.
		].
	].
	self storePointer: NextLinkIndex ofObject: aProcess withValue: self nilObject.

]

{ #category : #'image segment in/out' }
Interpreter >> restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut [

	"Restore headers smashed by forwarding links"
	| tablePtr oop header |
	tablePtr := firstIn.
	[self oop: tablePtr isLessThanOrEqualTo: lastIn] whileTrue:
		[oop := self longAt: tablePtr.
		header := self longAt: hdrBaseIn + (tablePtr-firstIn).
		self longAt: oop put: header.
		tablePtr := tablePtr + self bytesPerWord].
	tablePtr := firstOut.
	[self oop: tablePtr isLessThanOrEqualTo: lastOut] whileTrue:
		[oop := self longAt: tablePtr.
		header := self longAt: hdrBaseOut + (tablePtr-firstOut).
		self longAt: oop put: header.
		tablePtr := tablePtr + self bytesPerWord].
	
	"Clear all mark bits"
	oop := self firstObject.
	[self oop: oop isLessThan: endOfMemory] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[self longAt: oop put: ((self longAt: oop) bitAnd: self allButMarkBit)].
		oop := self objectAfter: oop].

]

{ #category : #'process primitive support' }
Interpreter >> resume: aProcess [ 
	| activeProc activePriority newPriority |
	<inline: false>
	activeProc := self fetchPointer: ActiveProcessIndex ofObject: self schedulerPointer.
	activePriority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	newPriority := self quickFetchInteger: PriorityIndex ofObject: aProcess.
	newPriority > activePriority
		ifTrue: [self putToSleep: activeProc.
			self transferTo: aProcess]
		ifFalse: [self putToSleep: aProcess]
]

{ #category : #'return bytecodes' }
Interpreter >> returnFalse [
	localReturnContext := self sender.
	localReturnValue := falseObj.
	self commonReturn.

]

{ #category : #'return bytecodes' }
Interpreter >> returnNil [
	localReturnContext := self sender.
	localReturnValue := nilObj.
	self commonReturn.
]

{ #category : #'return bytecodes' }
Interpreter >> returnReceiver [
	localReturnContext := self sender.
	localReturnValue := receiver.
	self commonReturn.
]

{ #category : #'return bytecodes' }
Interpreter >> returnTopFromBlock [
	"Return to the caller of the method containing the block."
	localReturnContext := self caller.  "Note: caller, not sender!"
	localReturnValue := self internalStackTop.
	self commonReturn.
]

{ #category : #'return bytecodes' }
Interpreter >> returnTopFromMethod [
	localReturnContext := self sender.
	localReturnValue := self internalStackTop.
	self commonReturn.
]

{ #category : #'return bytecodes' }
Interpreter >> returnTrue [
	localReturnContext := self sender.
	localReturnValue := trueObj.
	self commonReturn.
]

{ #category : #'image save/restore' }
Interpreter >> reverseBytesFrom: startAddr to: stopAddr [
	"Byte-swap the given range of memory (not inclusive of stopAddr!)."
	| addr |
	self flag: #Dan.
	addr := startAddr.
	[self oop: addr isLessThan: stopAddr] whileTrue:
		[self longAt: addr put: (self byteSwapped: (self longAt: addr)).
		addr := addr + self bytesPerWord].
]

{ #category : #'image save/restore' }
Interpreter >> reverseBytesInImage [
	"Byte-swap all words in memory after reading in the entire image file with bulk read. Contributed by Tim Rowledge."

	"First, byte-swap every word in the image. This fixes objects headers."
	self reverseBytesFrom: self startOfMemory to: endOfMemory.

	"Second, return the bytes of bytes-type objects to their orginal order."
	self byteSwapByteObjects.
]

{ #category : #'I/O primitive support' }
Interpreter >> reverseDisplayFrom: startIndex to: endIndex [ 
	"Reverse the given range of Display words (at different bit 
	depths, this will reverse different numbers of pixels). Used to 
	give feedback during VM activities such as garbage 
	collection when debugging. It is assumed that the given 
	word range falls entirely within the first line of the Display."
	| displayObj dispBitsPtr w reversed |
	displayObj := self splObj: TheDisplay.
	((self isPointers: displayObj) and: [(self lengthOf: displayObj) >= 4]) ifFalse: [^ nil].
	w := self fetchInteger: 1 ofObject: displayObj.
	dispBitsPtr := self fetchPointer: 0 ofObject: displayObj.
	(self isIntegerObject: dispBitsPtr) ifTrue: [^ nil].
	dispBitsPtr := dispBitsPtr + self baseHeaderSize.
	dispBitsPtr + (startIndex * 4) to: dispBitsPtr + (endIndex * 4) by: 4
		do: [:ptr | 
			reversed := (self long32At: ptr) bitXor: 4294967295.
			self longAt: ptr put: reversed].
	successFlag := true.
	self displayBitsOf: displayObj Left: 0 Top: 0 Right: w Bottom: 1.
	self ioForceDisplayUpdate
]

{ #category : #'image save/restore' }
Interpreter >> reverseWordsFrom: startAddr to: stopAddr [
	"Word-swap the given range of memory, excluding stopAddr."

	| addr |
	addr := startAddr.
	[self oop: addr isLessThan: stopAddr] whileTrue:
		[self longAt: addr put: (self wordSwapped: (self longAt: addr)).
		addr := addr + self bytesPerWord].
]

{ #category : #'method lookup cache' }
Interpreter >> rewriteMethodCacheSel: selector class: class primIndex: localPrimIndex [

	"Rewrite the cache entry with the given primitive index and matching function pointer"
	| primPtr |
	<var: #primPtr type: 'void *'>
	<inline: false>
	localPrimIndex = 0
		ifTrue: [primPtr := 0]
		ifFalse: [primPtr := primitiveTable at: localPrimIndex].
	self
		rewriteMethodCacheSel: selector class: class
		primIndex: localPrimIndex primFunction: primPtr
]

{ #category : #'method lookup cache' }
Interpreter >> rewriteMethodCacheSel: selector class: class primIndex: localPrimIndex primFunction: localPrimAddress [
	"Rewrite an existing entry in the method cache with a new primitive 
	index & function address. Used by primExternalCall to make direct jumps to found external prims"
	| probe hash |
	<inline: false>
	<var: #localPrimAddress type: 'void *'>
	hash := selector bitXor: class.
	0 to: CacheProbeMax - 1 do: [:p | 
			probe := hash >> p bitAnd: MethodCacheMask.
			((methodCache at: probe + MethodCacheSelector) = selector
					and: [(methodCache at: probe + MethodCacheClass) = class])
				ifTrue: [methodCache at: probe + MethodCachePrim put: localPrimIndex.
					methodCache at: probe + MethodCachePrimFunction put: (self cCoerce: localPrimAddress to: 'long').
					^ nil]]
]

{ #category : #'primitive support' }
Interpreter >> roomToPushNArgs: n [
	"Answer if there is room to push n arguments onto the current stack.
	 There may be room in this stackPage but there may not be room if
	 the frame were converted into a context."
	| cntxSize |
	((self headerOf: method) bitAnd: LargeContextBit) ~= 0
		ifTrue: [cntxSize := self largeContextSize / self bytesPerWord - ReceiverIndex]
		ifFalse: [cntxSize := self smallContextSize / self bytesPerWord - ReceiverIndex].
	^self stackPointerIndex + n <= cntxSize
]

{ #category : #'process primitive support' }
Interpreter >> saveProcessSignalingLowSpace [
	"The low space semaphore is about to be signaled. Save the currently active
	process in the special objects array so that the low space handler will be able
	to determine the process that first triggered a low space condition. The low
	space handler (in the image) is expected to nil out the special objects array
	slot when it handles the low space condition."

	| lastSavedProcess sched currentProc |
	lastSavedProcess := self splObj: ProcessSignalingLowSpace.
	(lastSavedProcess == self nilObject) ifTrue:
		[sched := self schedulerPointer.
		currentProc := self fetchPointer: ActiveProcessIndex ofObject: sched.
		self storePointer: ProcessSignalingLowSpace ofObject: specialObjectsOop withValue: currentProc]
]

{ #category : #'process primitive support' }
Interpreter >> schedulerPointer [

	^ self fetchPointer: ValueIndex ofObject: (self splObj: SchedulerAssociation)
]

{ #category : #'send bytecodes' }
Interpreter >> secondExtendedSendBytecode [
	"This replaces the Blue Book double-extended super-send [134],
	which is subsumed by the new double-extended do-anything [132].
	It offers a 2-byte send of 0-3 args for up to 63 literals, for which 
	the Blue Book opcode set requires a 3-byte instruction."

	| descriptor |
	descriptor := self fetchByte.
	messageSelector := self literal: (descriptor bitAnd: 16r3F).
	argumentCount := descriptor >> 6.
	self normalSend.

]

{ #category : #'alien support' }
Interpreter >> sendInvokeCallback: thunkPtr Stack: stackPtr Registers: regsPtr Jmpbuf: jmpBufPtr [
	"Send the 4 argument callback message invokeCallback:stack:registers:jmpbuf:
	 to Alien class with the supplied args.  The arguments are raw C addresses
	 and are converted to integer objects on the way."
	| where |
	<export: true>
	self pushRemappableOop: (self positive32BitIntegerFor: jmpBufPtr).
	self pushRemappableOop: (self positive32BitIntegerFor: regsPtr).
	self pushRemappableOop: (self positive32BitIntegerFor: stackPtr).
	self pushRemappableOop: (self positive32BitIntegerFor: thunkPtr).
	receiver := self splObj: ClassAlien.
	lkupClass := self fetchClassOfNonInt: receiver.
	messageSelector := self splObj: InvokeCallbackSelector.
	(self lookupInMethodCacheSel: messageSelector class: lkupClass) ifFalse:
	 	[(self lookupMethodNoMNUEtcInClass: lkupClass) ifFalse:
			[^false]].
	primitiveIndex ~= 0 ifTrue:
		[^false].
	self storeContextRegisters: activeContext.
	self internalJustActivateNewMethod.
	where := activeContext + self baseHeaderSize + (ReceiverIndex << self shiftForWord).
	self longAt: where + (1 << self shiftForWord) put: self popRemappableOop.
	self longAt: where + (2 << self shiftForWord) put: self popRemappableOop.
	self longAt: where + (3 << self shiftForWord) put: self popRemappableOop.
	self longAt: where + (4 << self shiftForWord) put: self popRemappableOop.
	self fetchContextRegisters: activeContext.
	self callInterpreter.
	"not reached"
	^true
]

{ #category : #'send bytecodes' }
Interpreter >> sendLiteralSelectorBytecode [
	"Can use any of the first 16 literals for the selector and pass up to 2 arguments."

	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := ((currentBytecode >> 4) bitAnd: 3) - 1.
	self normalSend
]

{ #category : #contexts }
Interpreter >> sender [

	| context closureOrNil |
	context := localHomeContext.
	[(closureOrNil := self fetchPointer: ClosureIndex ofObject: context) ~~ nilObj] whileTrue:
		[context := self fetchPointer: ClosureOuterContextIndex ofObject: closureOrNil].
	^self fetchPointer: SenderIndex ofObject: context
]

{ #category : #'compiler support' }
Interpreter >> setCompilerInitialized: newFlag [
	| oldFlag |
	oldFlag := compilerInitialized.
	compilerInitialized := newFlag.
	^oldFlag
]

{ #category : #'plugin primitive support' }
Interpreter >> setFullScreenFlag: value [
	fullScreenFlag := value
]

{ #category : #'plugin primitive support' }
Interpreter >> setInterruptCheckCounter: value [
	interruptCheckCounter := value
]

{ #category : #'plugin primitive support' }
Interpreter >> setInterruptKeycode: value [
	interruptKeycode := value
]

{ #category : #'plugin primitive support' }
Interpreter >> setInterruptPending: value [
	interruptPending := value
]

{ #category : #utilities }
Interpreter >> setMicroSeconds: microSeconds andOffset: utcOffset [
	"A default substitute for unimplemented ioUtcWithOffset external function."
	<var: #microSeconds type: 'sqLong *'>
	<var: #utcOffset type: 'int *'>

	self flag: #toRemove. "after implementing ioUtcWithOffset in support code for all platforms"

	^ -1

	"The corresponding platform support function for a GNU unix system is:
	sqInt ioUtcWithOffset(sqLong *microSeconds, int *offset)
	{
		struct timeval timeval;
		if (gettimeofday(&timeval, NULL) == -1) return -1;
	 	long long seconds = timeval.tv_sec;
		suseconds_t usec = timeval.tv_usec;
		*microSeconds = seconds * 1000000 + usec;
		*offset = localtime(&seconds)->tm_gmtoff;
		return 0;
	}"

]

{ #category : #'plugin primitive support' }
Interpreter >> setNextWakeupTick: value [
	nextWakeupTick := value
]

{ #category : #'plugin primitive support' }
Interpreter >> setSavedWindowSize: value [
	savedWindowSize := value
]

{ #category : #'jump bytecodes' }
Interpreter >> shortConditionalJump [

	self jumplfFalseBy: (currentBytecode bitAnd: 7) + 1.
]

{ #category : #'jump bytecodes' }
Interpreter >> shortUnconditionalJump [

	self jump: (currentBytecode bitAnd: 7) + 1.
]

{ #category : #'I/O primitive support' }
Interpreter >> showDisplayBits: aForm Left: l Top: t Right: r Bottom: b [
	"Repaint the portion of the Smalltalk screen bounded by the affected rectangle. Used to synchronize the screen after a Bitblt to the Smalltalk Display object."
	deferDisplayUpdates ifTrue: [^ nil].
	self displayBitsOf: aForm Left: l Top: t Right: r Bottom: b
]

{ #category : #utilities }
Interpreter >> signExtend16: int16 [
	"Convert a signed 16-bit integer into a signed 32-bit integer value. The integer bit is not added here."

	(int16 bitAnd: 16r8000) = 0
		ifTrue: [ ^ int16 ]
		ifFalse: [ ^ int16 - 16r10000 ].
]

{ #category : #'process primitive support' }
Interpreter >> signalExternalSemaphores [
	"Signal all requested semaphores"
	| xArray xSize index sema |
	semaphoresUseBufferA := semaphoresUseBufferA not.
	xArray := self splObj: ExternalObjectsArray.
	xSize := self stSizeOf: xArray.
	semaphoresUseBufferA
		ifTrue: ["use opposite buffer during read"
			1 to: semaphoresToSignalCountB do: [:i | 
					index := semaphoresToSignalB at: i.
					index <= xSize
						ifTrue: [sema := self fetchPointer: index - 1 ofObject: xArray.
							"Note: semaphore indices are 1-based"
							(self fetchClassOf: sema) = (self splObj: ClassSemaphore)
								ifTrue: [self synchronousSignal: sema]]].
			semaphoresToSignalCountB := 0]
		ifFalse: [1 to: semaphoresToSignalCountA do: [:i | 
					index := semaphoresToSignalA at: i.
					index <= xSize
						ifTrue: [sema := self fetchPointer: index - 1 ofObject: xArray.
							"Note: semaphore indices are 1-based"
							(self fetchClassOf: sema) = (self splObj: ClassSemaphore)
								ifTrue: [self synchronousSignal: sema]]].
			semaphoresToSignalCountA := 0]
]

{ #category : #'process primitive support' }
Interpreter >> signalFinalization: weakReferenceOop [
	"If it is not there already, record the given semaphore index in the list of semaphores to be signaled at the next convenient moment. Force a real interrupt check as soon as possible."

	self forceInterruptCheck.
	pendingFinalizationSignals := pendingFinalizationSignals + 1.
]

{ #category : #'process primitive support' }
Interpreter >> signalSemaphoreWithIndex: index [
	"Record the given semaphore index in the double buffer semaphores array to be signaled at the next convenient moment. Force a real interrupt check as soon as possible."

	index <= 0 ifTrue: [^ nil].  "bad index; ignore it"

	semaphoresUseBufferA
		ifTrue: [semaphoresToSignalCountA < SemaphoresToSignalSize
			ifTrue: [ semaphoresToSignalCountA := semaphoresToSignalCountA + 1.
				semaphoresToSignalA at: semaphoresToSignalCountA put: index]]
		ifFalse: [semaphoresToSignalCountB < SemaphoresToSignalSize
			ifTrue: [ semaphoresToSignalCountB := semaphoresToSignalCountB + 1.
				semaphoresToSignalB at: semaphoresToSignalCountB put: index]].
	self forceInterruptCheck

]

{ #category : #'primitive support' }
Interpreter >> signed32BitIntegerFor: integerValue [
	"Return a full 32 bit integer object for the given integer value"
	| newLargeInteger value largeClass |
	<inline: false>
	<var: #integerValue type: 'int'>
	(self isIntegerValue: integerValue)
		ifTrue: [^ self integerObjectOf: integerValue].
	integerValue < 0
		ifTrue:[	largeClass := self classLargeNegativeInteger.
				value := 0 - integerValue]
		ifFalse:[	largeClass := self classLargePositiveInteger.
				value := integerValue].
	newLargeInteger := self instantiateClass: largeClass indexableSize: 4.
	self storeByte: 3 ofObject: newLargeInteger withValue: ((value >> 24) bitAnd: 16rFF).
	self storeByte: 2 ofObject: newLargeInteger withValue: ((value >> 16) bitAnd: 16rFF).
	self storeByte: 1 ofObject: newLargeInteger withValue: ((value >> 8) bitAnd: 16rFF).
	self storeByte: 0 ofObject: newLargeInteger withValue: (value bitAnd: 16rFF).
	^ newLargeInteger
]

{ #category : #'primitive support' }
Interpreter >> signed32BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive ST integer or a four-byte LargeInteger."
	| sz value largeClass negative |
	<inline: false>
	<returnTypeC: 'int'>
	<var: 'value' type: 'int'>
	(self isIntegerObject: oop) ifTrue: [^self integerValueOf: oop].
	(self lengthOf: oop) > 4 ifTrue: [^ self primitiveFail].
	largeClass := self fetchClassOf: oop.
	largeClass = self classLargePositiveInteger
		ifTrue:[negative := false]
		ifFalse:[largeClass = self classLargeNegativeInteger
					ifTrue:[negative := true]
					ifFalse:[^self primitiveFail]].
	sz := self lengthOf: oop.
	sz = 4 ifFalse: [^ self primitiveFail].
	value := (self fetchByte: 0 ofObject: oop) +
		  ((self fetchByte: 1 ofObject: oop) <<  8) +
		  ((self fetchByte: 2 ofObject: oop) << 16) +
		  ((self fetchByte: 3 ofObject: oop) << 24).
	"Fail if value exceeds range of a 32-bit two's-complement signed integer."
	negative
		ifTrue:[value := 0 - value.
				value >= 0 ifTrue: [^ self primitiveFail]]
		ifFalse:[value < 0 ifTrue:[^ self primitiveFail]].
	^ value
]

{ #category : #'primitive support' }
Interpreter >> signed64BitIntegerFor: integerValue [
	"Return a Large Integer object for the given integer value"
	| newLargeInteger magnitude largeClass intValue highWord sz |
	<inline: false>
	<var: 'integerValue' type: 'sqLong'>
	<var: 'magnitude' type: 'unsigned sqLong'>
	<var: 'highWord' type: 'usqInt'>

	integerValue < 0
		ifTrue:[	largeClass := self classLargeNegativeInteger.
				magnitude := 0 - integerValue]
		ifFalse:[	largeClass := self classLargePositiveInteger.
				magnitude := integerValue].

	magnitude <= 16r7FFFFFFF ifTrue:[^self signed32BitIntegerFor: integerValue].

	highWord := self cCode: 'magnitude >> 32'. "shift is coerced to usqInt otherwise"
	highWord = 0 
		ifTrue:[sz := 4] 
		ifFalse:[
			sz := 5.
			(highWord := highWord >> 8) = 0 ifFalse:[sz := sz + 1].
			(highWord := highWord >> 8) = 0 ifFalse:[sz := sz + 1].
			(highWord := highWord >> 8) = 0 ifFalse:[sz := sz + 1].
		].
	newLargeInteger := self instantiateClass: largeClass indexableSize:  sz.
	0 to: sz-1 do: [:i |
		intValue := self cCode: '(magnitude >> (i * 8)) & 255'.
		self storeByte: i ofObject: newLargeInteger withValue: intValue].
	^ newLargeInteger
]

{ #category : #'primitive support' }
Interpreter >> signed64BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive ST integer or a eight-byte LargeInteger."
	| sz value largeClass negative szsqLong |
	<inline: false>
	<returnTypeC: 'sqLong'>
	<var: 'value' type: 'sqLong'>
	(self isIntegerObject: oop) ifTrue: [^self cCoerce: (self integerValueOf: oop) to: 'sqLong'].
	sz := self lengthOf: oop.
	sz > 8 ifTrue: [^ self primitiveFail].
	largeClass := self fetchClassOf: oop.
	largeClass = self classLargePositiveInteger
		ifTrue:[negative := false]
		ifFalse:[largeClass = self classLargeNegativeInteger
					ifTrue:[negative := true]
					ifFalse:[^self primitiveFail]].
	szsqLong := self cCode: 'sizeof(sqLong)'.
	sz > szsqLong 
		ifTrue: [^ self primitiveFail].
	value := 0.
	0 to: sz - 1 do: [:i |
		value := value + ((self cCoerce: (self fetchByte: i ofObject: oop) to: 'sqLong') <<  (i*8))].
	"Fail if value exceeds range of a 64-bit two's-complement signed integer."
	negative
		ifTrue:[value := 0 - value.
				value >= 0 ifTrue: [^ self primitiveFail]]
		ifFalse:[value < 0 ifTrue:[^ self primitiveFail]].
	^ value
]

{ #category : #'send bytecodes' }
Interpreter >> singleExtendedSendBytecode [
	"Can use any of the first 32 literals for the selector and pass up to 7 arguments."

	| descriptor |
	descriptor := self fetchByte.
	messageSelector := self literal: (descriptor bitAnd: 16r1F).
	argumentCount := descriptor >> 5.
	self normalSend.
]

{ #category : #'send bytecodes' }
Interpreter >> singleExtendedSuperBytecode [
	"Can use any of the first 32 literals for the selector and pass up to 7 arguments."

	| descriptor |
	descriptor := self fetchByte.
	messageSelector := self literal: (descriptor bitAnd: 16r1F).
	argumentCount := descriptor >> 5.
	self superclassSend.

]

{ #category : #utilities }
Interpreter >> sizeOfSTArrayFromCPrimitive: cPtr [
	"Return the number of indexable fields of the given object. This method is to be called from an automatically generated C primitive. The argument is assumed to be a pointer to the first indexable field of a words or bytes object; the object header starts 4 bytes before that."
	"Note: Only called by translated primitive code."

	| oop |
	<var: #cPtr type: 'void *'>
	oop := (self oopForPointer: (self cCoerce: cPtr to: 'char *')) - self baseHeaderSize.
	(self isWordsOrBytes: oop) ifFalse: [
		self primitiveFail.
		^0].
	^self lengthOf: oop

]

{ #category : #'object format' }
Interpreter >> slotSizeOf: oop [
	"Returns the number of slots in the receiver.
	If the receiver is a byte object, return the number of bytes.
	Otherwise return the number of words."
	(self isIntegerObject: oop) ifTrue:[^0].
	^self lengthOf: oop
]

{ #category : #'image save/restore' }
Interpreter >> snapshot: embedded [ 
	"update state of active context"
	| activeProc dataSize rcvr setMacType |
	<var: #setMacType type: 'void *'>
	compilerInitialized
		ifTrue: [self compilerPreSnapshot]
		ifFalse: [self storeContextRegisters: activeContext].

	"update state of active process"
	activeProc := self fetchPointer: ActiveProcessIndex ofObject: self schedulerPointer.
	self
		storePointer: SuspendedContextIndex
		ofObject: activeProc
		withValue: activeContext.

	"compact memory and compute the size of the memory actually in use"
	self incrementalGC.

	"maximimize space for forwarding table"
	self fullGC.
	self snapshotCleanUp.

	dataSize := freeBlock - self startOfMemory. "Assume all objects are below the start of the free block"
	successFlag
		ifTrue: [rcvr := self popStack.
			"pop rcvr"
			self push: trueObj.
			self writeImageFile: dataSize.
			embedded
				ifFalse: ["set Mac file type and creator; this is a noop on other platforms"
					setMacType := self ioLoadFunction: 'setMacFileTypeAndCreator' From: 'FilePlugin'.
					setMacType = 0
						ifFalse: [self cCode: '((sqInt (*)(char *, char *, char *))setMacType)(imageName, "STim", "FAST")']].
			self pop: 1].

	"activeContext was unmarked in #snapshotCleanUp, mark it old "
	self beRootIfOld: activeContext.
	successFlag
		ifTrue: [self push: falseObj]
		ifFalse: [self push: rcvr].
	compilerInitialized
		ifTrue: [self compilerPostSnapshot]
]

{ #category : #'image save/restore' }
Interpreter >> snapshotCleanUp [
	"Clean up right before saving an image, sweeping memory and:
	* nilling out all fields of contexts above the stack pointer. 
	* flushing external primitives 
	* clearing the root bit of any object in the root table "
	| oop header fmt sz |
	oop := self firstObject.
	[self oop: oop isLessThan: endOfMemory]
		whileTrue: [(self isFreeObject: oop)
				ifFalse: [header := self longAt: oop.
					fmt := header >> 8 bitAnd: 15.
					"Clean out context"
					(fmt = 3 and: [self isContextHeader: header])
						ifTrue: [sz := self sizeBitsOf: oop.
							(self lastPointerOf: oop) + self bytesPerWord
								to: sz - self baseHeaderSize by: self bytesPerWord
								do: [:i | self longAt: oop + i put: nilObj]].
					"Clean out external functions"
					fmt >= 12
						ifTrue: ["This is a compiled method"
							(self primitiveIndexOf: oop) = PrimitiveExternalCallIndex
								ifTrue: ["It's primitiveExternalCall"
									self flushExternalPrimitiveOf: oop]]].
			oop := self objectAfter: oop].
	self clearRootsTable
]

{ #category : #'message sending' }
Interpreter >> specialSelector: index [

	^ self fetchPointer: (index * 2) ofObject: (self splObj: SpecialSelectors)
]

{ #category : #'image save/restore' }
Interpreter >> sqImage: memoryAddress read: fileStream size: elementSize length: length [
	"Normally implemented in support code as fread().
	See CCodeGenerator>>writeDefaultMacrosOn: which specifies a default implementation."
 
	<inline: true>
	<returnTypeC: 'size_t'>
	<var: #memoryAddress type: 'char *'>
	<var: #elementSize type: 'size_t'>
	<var: #length type: 'size_t'>
	<var: #fileStream type: 'sqImageFile'>
	^ self sqImage: memoryAddress File: elementSize  ReadEntire: length Image: fileStream 


]

{ #category : #'image save/restore' }
Interpreter >> sqImage: memoryAddress write: fileStream size: elementSize length: length [
	"Normally implemented in support code as fwrite()"

	<inline: true>
	<returnTypeC: 'size_t'>
	<var: #memoryAddress type: 'char *'>
	<var: #elementSize type: 'size_t'>
	<var: #length type: 'size_t'>
	<var: #fileStream type: 'sqImageFile'>
	^ self sq: memoryAddress Image: elementSize File: length Write: fileStream "sqImageFileWrite()"

]

{ #category : #'array primitive support' }
Interpreter >> stObject: array at: index [
	"Return what ST would return for <obj> at: index."

	| hdr fmt totalLength fixedFields stSize |
	<inline: false>
	hdr := self baseHeader: array.
	fmt := (hdr >> 8) bitAnd: 16rF.
	totalLength := self lengthOf: array baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: array format: fmt length: totalLength.
	(fmt = 3 and: [self isContextHeader: hdr])
		ifTrue: [stSize := self fetchStackPointerOf: array]
		ifFalse: [stSize := totalLength - fixedFields].
	((self oop: index isGreaterThanOrEqualTo: 1)
			and: [self oop: index isLessThanOrEqualTo: stSize])
		ifTrue: [^ self subscript: array with: (index + fixedFields) format: fmt]
		ifFalse: [successFlag := false.  ^ 0].
]

{ #category : #'array primitive support' }
Interpreter >> stObject: array at: index put: value [
	"Do what ST would return for <obj> at: index put: value."
	| hdr fmt totalLength fixedFields stSize |
	<inline: false>
	hdr := self baseHeader: array.
	fmt := (hdr >> 8) bitAnd: 16rF.
	totalLength := self lengthOf: array baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: array format: fmt length: totalLength.
	(fmt = 3 and: [self isContextHeader: hdr])
		ifTrue: [stSize := self fetchStackPointerOf: array]
		ifFalse: [stSize := totalLength - fixedFields].
	((self oop: index isGreaterThanOrEqualTo: 1)
			and: [self oop: index isLessThanOrEqualTo: stSize])
		ifTrue: [self subscript: array with: (index + fixedFields) storing: value format: fmt]
		ifFalse: [successFlag := false]
]

{ #category : #'array primitive support' }
Interpreter >> stSizeOf: oop [
	"Return the number of indexable fields in the given object. (i.e., what Smalltalk would return for <obj> size)."
	"Note: Assume oop is not a SmallInteger!"

	| hdr fmt totalLength fixedFields |
	<inline: false>
	hdr := self baseHeader: oop.
	fmt := (hdr >> 8) bitAnd: 16rF.
	totalLength := self lengthOf: oop baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: oop format: fmt length: totalLength.
	(fmt = 3 and: [self isContextHeader: hdr])
		ifTrue: [^ self fetchStackPointerOf: oop]
		ifFalse: [^ totalLength - fixedFields]
]

{ #category : #contexts }
Interpreter >> stackFloatValue: offset [
	"Note: May be called by translated primitive code."
	| result floatPointer |
	<returnTypeC: 'double'>
	<var: #result type: 'double '>
	floatPointer := self longAt: stackPointer - (offset * self bytesPerWord).
	(self fetchClassOf: floatPointer) = (self splObj: ClassFloat) 
		ifFalse:[self primitiveFail. ^0.0].
	self cCode: '' inSmalltalk: [result := Float new: 2].
	self fetchFloatAt: floatPointer + self baseHeaderSize into: result.
	^ result
]

{ #category : #contexts }
Interpreter >> stackIntegerValue: offset [
	| integerPointer |
	integerPointer := self longAt: stackPointer - (offset * self bytesPerWord).
	^self checkedIntegerValueOf: integerPointer
]

{ #category : #contexts }
Interpreter >> stackObjectValue: offset [
	"Ensures that the given object is a real object, not a SmallInteger."

	| oop |
	oop := self longAt: stackPointer - (offset * self bytesPerWord).
	(self isIntegerObject: oop) ifTrue: [self primitiveFail. ^ nil].
	^ oop

]

{ #category : #contexts }
Interpreter >> stackPointerIndex [
	"Return the 0-based index rel to the current context.
	(This is what stackPointer used to be before conversion to pointer"
	^ (stackPointer - activeContext - self baseHeaderSize) >> self shiftForWord
]

{ #category : #contexts }
Interpreter >> stackTop [
	^self longAt: stackPointer
]

{ #category : #contexts }
Interpreter >> stackValue: offset [
	^ self longAt: stackPointer - (offset * self bytesPerWord)
]

{ #category : #'stack bytecodes' }
Interpreter >> storeAndPopReceiverVariableBytecode [
	"Note: This code uses 
	storePointerUnchecked:ofObject:withValue: and does the 
	store check explicitely in order to help the translator 
	produce better code."
	| rcvr top |
	self flag: #'requires currentBytecode to be expanded to a constant'.
	self fetchNextBytecode.
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	rcvr := receiver.
	top := self internalStackTop.
	(self oop: rcvr isLessThan: youngStart)
		ifTrue: [self possibleRootStoreInto: rcvr value: top].
	self storePointerUnchecked: (currentBytecode bitAnd: 7) ofObject: rcvr withValue: top.
	self internalPop: 1
]

{ #category : #'stack bytecodes' }
Interpreter >> storeAndPopRemoteTempLongBytecode [
	self storeRemoteTempLongBytecode.
	self internalPop: 1
]

{ #category : #'stack bytecodes' }
Interpreter >> storeAndPopTemporaryVariableBytecode [

	self flag: #'requires currentBytecode to be expanded to a constant'.
	self fetchNextBytecode.
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	self storePointerUnchecked: (currentBytecode bitAnd: 7) + TempFrameStart
		ofObject: localHomeContext
		withValue: self internalStackTop.
	self internalPop: 1.

]

{ #category : #contexts }
Interpreter >> storeContextRegisters: activeCntx [
	"Note: internalStoreContextRegisters: should track changes to this method."

	"InstructionPointer is a pointer variable equal to
	method oop + ip + self baseHeaderSize
		-1 for 0-based addressing of fetchByte
		-1 because it gets incremented BEFORE fetching currentByte"

	<inline: true>
	self storePointerUnchecked: InstructionPointerIndex ofObject: activeCntx
		withValue: (self integerObjectOf: (instructionPointer - method - (self baseHeaderSize - 2))).
	self storePointerUnchecked: StackPointerIndex ofObject: activeCntx
		withValue: (self integerObjectOf: (self stackPointerIndex - TempFrameStart + 1)).

]

{ #category : #contexts }
Interpreter >> storeInstructionPointerValue: value inContext: contextPointer [
	"Assume: value is an integerValue"

	self storePointerUnchecked: InstructionPointerIndex ofObject: contextPointer withValue: (self integerObjectOf: value).
]

{ #category : #utilities }
Interpreter >> storeInteger: fieldIndex ofObject: objectPointer withValue: integerValue [ 
	"Note: May be called by translated primitive code."
	(self isIntegerValue: integerValue)
		ifTrue: [self storePointerUnchecked: fieldIndex ofObject: objectPointer
					withValue: (self integerObjectOf: integerValue)]
		ifFalse: [self primitiveFail]
]

{ #category : #'stack bytecodes' }
Interpreter >> storeRemoteTemp: index inVectorAt: tempVectorIndex [
	| tempVector |
	tempVector := self temporary: tempVectorIndex.
	self storePointer: index ofObject: tempVector withValue: self internalStackTop.
]

{ #category : #'stack bytecodes' }
Interpreter >> storeRemoteTempLongBytecode [
	| remoteTempIndex tempVectorIndex |
	remoteTempIndex := self fetchByte.
	tempVectorIndex := self fetchByte.
	self fetchNextBytecode.
	self storeRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex
]

{ #category : #contexts }
Interpreter >> storeStackPointerValue: value inContext: contextPointer [
	"Assume: value is an integerValue"

	self storePointerUnchecked: StackPointerIndex ofObject: contextPointer
		withValue: (self integerObjectOf: value).
]

{ #category : #'array primitive support' }
Interpreter >> subscript: array with: index format: fmt [
	"Note: This method assumes that the index is within bounds!"

	<inline: true>
	fmt <= 4 ifTrue: [  "pointer type objects"
		^ self fetchPointer: index - 1 ofObject: array].
	fmt < 8 ifTrue: [  "long-word type objects"
		^ self positive32BitIntegerFor:
			(self fetchLong32: index - 1 ofObject: array)
	] ifFalse: [  "byte-type objects"
		^ self integerObjectOf:
			(self fetchByte: index - 1 ofObject: array)
	].
]

{ #category : #'array primitive support' }
Interpreter >> subscript: array with: index storing: oopToStore format: fmt [ 
	"Note: This method assumes that the index is within bounds!"
	| valueToStore |
	<inline: true>
	fmt <= 4
		ifTrue: ["pointer type objects"
			self storePointer: index - 1 ofObject: array
				withValue: oopToStore]
		ifFalse: [fmt < 8
				ifTrue: ["long-word type objects"
					valueToStore := self positive32BitValueOf: oopToStore.
					successFlag
						ifTrue: [self storeLong32: index - 1 ofObject: array
									withValue: valueToStore]]
				ifFalse: ["byte-type objects"
					(self isIntegerObject: oopToStore)
						ifFalse: [successFlag := false].
					valueToStore := self integerValueOf: oopToStore.
					(valueToStore >= 0
							and: [valueToStore <= 255])
						ifFalse: [successFlag := false].
					successFlag
						ifTrue: [self
								storeByte: index - 1
								ofObject: array
								withValue: valueToStore]]]
]

{ #category : #'primitive support' }
Interpreter >> success: successValue [

	successFlag := successValue & successFlag.
]

{ #category : #'object access primitives' }
Interpreter >> sufficientSpaceToInstantiate: classOop indexableSize: size [ 
	"Return true if there is enough space to allocate an instance of the given class with the given number of indexable fields."
	"Details: For speed, over-estimate space needed for fixed fields or literals; the low space threshold is a blurry line."
	| format |
	<inline: true>
	<var: #size type: 'usqInt'>
	<var: #bytesNeeded type: 'usqInt'>
	format := (self formatOfClass: classOop) >> 8 bitAnd: 16rF.

	"Fail if attempting to call new: on non-indexable class"
	(size > 0 and: [format < 2])
		ifTrue: [^ false].

	format < 8
		ifTrue: ["indexable fields are words or pointers"
				(self isExcessiveAllocationRequest: size shift: self shiftForWord) ifTrue: [^ false].
				^ self sufficientSpaceToAllocate: 2500 + (size * self bytesPerWord)]
		ifFalse: ["indexable fields are bytes"
				(self isExcessiveAllocationRequest: size shift: 0) ifTrue: [^ false].
				^ self sufficientSpaceToAllocate: 2500 + size]

]

{ #category : #'message sending' }
Interpreter >> superclassOf: classPointer [

	^ self fetchPointer: SuperclassIndex ofObject: classPointer
]

{ #category : #'message sending' }
Interpreter >> superclassSend [
	"Send a message to self, starting lookup with the superclass of the class containing the currently executing method."
	"Assume: messageSelector and argumentCount have been set, and that the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	| rcvr |
	<inline: true>
	self sharedCodeNamed: 'commonSupersend' inCase: 133.
	lkupClass := self superclassOf: (self methodClassOf: method).
	rcvr := self internalStackValue: argumentCount.
	receiverClass := self fetchClassOf: rcvr.
	self commonSend.
]

{ #category : #'process primitive support' }
Interpreter >> synchronousSignal: aSemaphore [ 
	"Signal the given semaphore from within the interpreter."
	| excessSignals |
	<inline: false>
	(self isEmptyList: aSemaphore)
		ifTrue: ["no process is waiting on this semaphore"
			excessSignals := self fetchInteger: ExcessSignalsIndex ofObject: aSemaphore.
			self storeInteger: ExcessSignalsIndex ofObject: aSemaphore withValue: excessSignals + 1]
		ifFalse: [self resume: (self removeFirstLinkOfList: aSemaphore)]
]

{ #category : #'compiled methods' }
Interpreter >> tempCountOf: methodPointer [
	^ ((self headerOf: methodPointer) >> 19) bitAnd: 16r3F
]

{ #category : #contexts }
Interpreter >> temporary: offset [

	^ self fetchPointer: offset + TempFrameStart ofObject: localHomeContext
]

{ #category : #utilities }
Interpreter >> transfer: count from: src to: dst [ 
	| in out lastIn |
	<inline: true>
	self flag: #Dan.  "Need to check all senders before converting this for 64 bits"
	in := src - self bytesPerWord.
	lastIn := in + (count * self bytesPerWord).
	out := dst - self bytesPerWord.
	[self oop: in isLessThan: lastIn]
		whileTrue: [self
				longAt: (out := out + self bytesPerWord)
				put: (self longAt: (in := in + self bytesPerWord))]
]

{ #category : #utilities }
Interpreter >> transfer: count fromIndex: firstFrom ofObject: fromOop toIndex: firstTo ofObject: toOop [
	"Transfer the specified fullword fields, as from calling context to called context"
	
	"Assume: beRootIfOld: will be called on toOop."
	| fromIndex toIndex lastFrom |
	<inline: true>
	self flag: #Dan.  "Need to check all senders before converting this for 64 bits"
	fromIndex := fromOop + (firstFrom * self bytesPerWord).
	toIndex := toOop + (firstTo * self bytesPerWord).
	lastFrom := fromIndex + (count * self bytesPerWord).
	[self oop: fromIndex isLessThan: lastFrom]
		whileTrue: [fromIndex := fromIndex + self bytesPerWord.
			toIndex := toIndex + self bytesPerWord.
			self
				longAt: toIndex
				put: (self longAt: fromIndex)]
]

{ #category : #'process primitive support' }
Interpreter >> transferTo: aProc [ 
	"Record a process to be awoken on the next interpreter cycle. 
	ikp 11/24/1999 06:07 -- added hook for external runtime 
	compiler "
	| sched oldProc newProc |
	newProc := aProc.
	sched := self schedulerPointer.
	oldProc := self fetchPointer: ActiveProcessIndex ofObject: sched.
	self storePointer: ActiveProcessIndex ofObject: sched withValue: newProc.
	compilerInitialized
		ifTrue: [self compilerProcessChange: oldProc to: newProc]
		ifFalse: [self storePointer: SuspendedContextIndex ofObject: oldProc withValue: activeContext.
			self newActiveContext: (self fetchPointer: SuspendedContextIndex ofObject: newProc).
			self storePointer: SuspendedContextIndex ofObject: newProc withValue: nilObj].
	reclaimableContextCount := 0
]

{ #category : #contexts }
Interpreter >> unPop: nItems [
	stackPointer := stackPointer + (nItems * self bytesPerWord)
]

{ #category : #'interpreter shell' }
Interpreter >> unknownBytecode [
	"This should never get called; it means that an unimplemented bytecode appears in a CompiledMethod."

	self error: 'Unknown bytecode'.
]

{ #category : #'debug support' }
Interpreter >> verifyCleanHeaders [
	| oop |
	oop := self firstObject.
	[self oop: oop isLessThan: endOfMemory] whileTrue:
		[(self isFreeObject: oop)
			ifTrue: ["There should only be one free block at end of memory."
					(self objectAfter: oop) = endOfMemory
						ifFalse: [self error: 'Invalid obj with HeaderTypeBits = Free.']]
			ifFalse: [((self longAt: oop) bitAnd: self markBit) = 0
						ifFalse: [self error: 'Invalid obj with MarkBit set.']].
		oop := self objectAfter: oop]
]

{ #category : #'plugin support' }
Interpreter >> vmEndianness [
	"return 0 for little endian, 1 for big endian"

	self isBigEnder ifTrue: [^ 1] ifFalse: [^ 0]

]

{ #category : #'process primitive support' }
Interpreter >> wakeHighestPriority [
	"Return the highest priority process that is ready to run."
	"Note: It is a fatal VM error if there is no runnable process."
	| schedLists p processList |
	schedLists := self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	p := self fetchWordLengthOf: schedLists.
	p := p - 1.
	"index of last indexable field"
	processList := self fetchPointer: p ofObject: schedLists.
	[self isEmptyList: processList]
		whileTrue: [p := p - 1.
			p < 0 ifTrue: [self error: 'scheduler could not find a runnable process'].
			processList := self fetchPointer: p ofObject: schedLists].
	^ self removeFirstLinkOfList: processList
]

{ #category : #'image save/restore' }
Interpreter >> wordSwapped: w [
	"Return the given 64-bit integer with its halves in the reverse order."

	<inline: true>
	self isDefinedTrueExpression: 'BYTES_PER_WORD == 8'
		inSmalltalk: [self bytesPerWord = 8]
		comment: 'swap 32-bit ends of a 64-bit object word'
		ifTrue: [^ ((w bitShift: Byte4ShiftNegated) bitAnd: Bytes3to0Mask)
	  					+ ((w bitShift: Byte4Shift) bitAnd: Bytes7to4Mask)]
		ifFalse: [self error: 'This cannot happen.']

]

{ #category : #'image save/restore' }
Interpreter >> writeImageFile: imageBytes [

	| fn |
	<var: #fn type: 'void *'>
	self writeImageFileIO: imageBytes.
	"set Mac file type and creator; this is a noop on other platforms"
	fn := self ioLoadFunction: 'setMacFileTypeAndCreator' From: 'FilePlugin'.
	fn = 0 ifFalse:[
		self cCode:'((sqInt (*)(char*, char*, char*))fn)(imageName, "STim", "FAST")'.
	].

]

{ #category : #'image save/restore' }
Interpreter >> writeImageFileIO: imageBytes [

	| headerStart headerSize f bytesWritten sCWIfn okToWrite |
	<var: #f type: 'sqImageFile'>
	<var: #headerStart type: 'squeakFileOffsetType '>
	<var: #sCWIfn type: 'void *'>

	"If the security plugin can be loaded, use it to check for write permission.
	If not, assume it's ok"
	sCWIfn := self ioLoadFunction: 'secCanWriteImage' From: 'SecurityPlugin'.
	sCWIfn ~= 0 ifTrue:[okToWrite := self cCode: '((sqInt (*)(void))sCWIfn)()'.
		okToWrite ifFalse:[^self primitiveFail]].
	
	"local constants"
	headerStart := 0.  
	headerSize := 16 * self bytesPerWord.  "header size in bytes; do not change!"

	f := self cCode: 'sqImageFileOpen(imageName, "wb")'.
	f = nil ifTrue: [
		"could not open the image file for writing"
		self success: false.
		^ nil].

	headerStart := self cCode: 'sqImageFileStartLocation(f,imageName,headerSize+imageBytes)'.
	self cCode: '/* Note: on Unix systems one could put an exec command here, padded to 512 bytes */'.
	"position file to start of header"
	self sqImageFile: f Seek: headerStart.

	self putLong: (self imageFormatVersion) toFile: f.
	self putLong: headerSize toFile: f.
	self putLong: imageBytes toFile: f.
	self putLong: (self startOfMemory) toFile: f.
	self putLong: specialObjectsOop toFile: f.
	self putLong: lastHash toFile: f.
	self putLong: (self ioScreenSize) toFile: f.
	self putLong: fullScreenFlag toFile: f.
	self putLong: extraVMMemory toFile: f.
	1 to: 7 do: [:i | self putLong: 0 toFile: f].  "fill remaining header words with zeros"
	successFlag ifFalse: [
		"file write or seek failure"
		self cCode: 'sqImageFileClose(f)'.
		^ nil].

	"position file after the header"
	self sqImageFile: f Seek: headerStart + headerSize.

	"write the image data"
	bytesWritten := self
		sqImage: (self pointerForOop: memory)
		write: f
		size: (self cCode: 'sizeof(unsigned char)')
		length: imageBytes.
	self success: bytesWritten = imageBytes.
	self cCode: 'sqImageFileClose(f)'.


]
