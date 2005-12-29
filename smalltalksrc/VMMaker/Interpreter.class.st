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
		'obsoleteIndexedPrimitiveTable',
		'obsoleteNamedPrimitiveTable',
		'interpreterProxy',
		'showSurfaceFn',
		'interruptCheckCounterFeedBackReset',
		'interruptChecksEveryNms',
		'externalPrimitiveTable',
		'primitiveTable',
		'globalSessionID'
	],
	#classVars : [
		'SemaphoresToSignalSize',
		'StackPointerIndex',
		'AtCacheMask',
		'MethodIndex',
		'StreamArrayIndex',
		'MethodArrayIndex',
		'DirEntryFound',
		'LastLinkIndex',
		'MethodCachePrim',
		'CrossedX',
		'ExcessSignalsIndex',
		'MaxPrimitiveIndex',
		'MethodCacheSize',
		'MyListIndex',
		'MillisecondClockMask',
		'BlockMethodIndex',
		'MethodCacheSelector',
		'AtPutBase',
		'InstanceSpecificationIndex',
		'ActiveProcessIndex',
		'MessageSelectorIndex',
		'MethodCachePrimFunction',
		'PrimitiveExternalCallIndex',
		'SenderIndex',
		'MethodCacheEntrySize',
		'MethodCacheMethod',
		'InitialIPIndex',
		'MethodCacheNative',
		'HeaderIndex',
		'InstructionPointerIndex',
		'BytecodeTable',
		'ProcessListsIndex',
		'SuspendedContextIndex',
		'MaxExternalPrimitiveTableSize',
		'MethodCacheMask',
		'BlockArgumentCountIndex',
		'CallerIndex',
		'DirBadPath',
		'CacheProbeMax',
		'StreamWriteLimitIndex',
		'FirstLinkIndex',
		'EndOfRun',
		'JitterTable',
		'AtCacheOop',
		'AtCacheSize',
		'PriorityIndex',
		'ReceiverIndex',
		'MessageDictionaryIndex',
		'AtCacheFmt',
		'DirNoMoreEntries',
		'NextLinkIndex',
		'MethodCacheClass',
		'SelectorStart',
		'MessageLookupClassIndex',
		'TempFrameStart',
		'MethodCacheEntries',
		'ValueIndex',
		'XIndex',
		'YIndex',
		'LiteralStart',
		'AtCacheFixedFields',
		'AtCacheTotalSize',
		'CharacterValueIndex',
		'HomeIndex',
		'StreamReadLimitIndex',
		'PrimitiveTable',
		'SuperclassIndex',
		'MessageArgumentsIndex',
		'StreamIndexIndex',
		'AtCacheEntries',
		'CompilerHooksSize'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #constants }
Interpreter class >> bytecodeTable [

	^ BytecodeTable
]

{ #category : #translation }
Interpreter class >> declareCVarsIn: aCCodeGenerator [

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

	SemaphoresToSignalSize _ 500.
	PrimitiveExternalCallIndex _ 117. "Primitive index for #primitiveExternalCall"
	MillisecondClockMask _ 16r1FFFFFFF.
	"Note: The external primitive table should actually be dynamically sized but for the sake of inferior platforms (e.g., Mac :-) who cannot allocate memory in any reasonable way, we keep it static (and cross our fingers...)"
	MaxExternalPrimitiveTableSize _ 4096. "entries"

]

{ #category : #initialization }
Interpreter class >> initializeAssociationIndex [
	ValueIndex _ 1
]

{ #category : #initialization }
Interpreter class >> initializeBytecodeTable [
	"Interpreter initializeBytecodeTable"
	"Note: This table will be used to generate a C switch statement."

	BytecodeTable _ Array new: 256.
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
		(126 unknownBytecode)
		(127 unknownBytecode)
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
		(138 143 experimentalBytecode)
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
	MethodCacheEntries _ 512. 
	MethodCacheSelector _ 1.
	MethodCacheClass _ 2.
	MethodCacheMethod _ 3.
	MethodCachePrim _ 4.
	MethodCacheNative _ 5.
	MethodCachePrimFunction _ 6.
	MethodCacheEntrySize _ 8.  "Must be power of two for masking scheme."
	MethodCacheMask _ (MethodCacheEntries - 1) * MethodCacheEntrySize.
	MethodCacheSize _ MethodCacheEntries * MethodCacheEntrySize.
	CacheProbeMax _ 3.

	AtCacheEntries _ 8.  "Must be a power of two"
	AtCacheOop _ 1.
	AtCacheSize _ 2.
	AtCacheFmt _ 3.
	AtCacheFixedFields _ 4.
	atCacheEntrySize _ 4.  "Must be power of two for masking scheme."
	AtCacheMask _ (AtCacheEntries-1) * atCacheEntrySize.
	AtPutBase _ AtCacheEntries * atCacheEntrySize.
	AtCacheTotalSize _ AtCacheEntries * atCacheEntrySize * 2.

]

{ #category : #initialization }
Interpreter class >> initializeCharacterIndex [
	CharacterValueIndex _ 0
]

{ #category : #initialization }
Interpreter class >> initializeCharacterScannerIndices [
	CrossedX _ 258.
	EndOfRun _ 257

]

{ #category : #initialization }
Interpreter class >> initializeClassIndices [
	"Class Class"
	SuperclassIndex _ 0.
	MessageDictionaryIndex _ 1.
	InstanceSpecificationIndex _ 2.
	"Fields of a message dictionary"
	MethodArrayIndex _ 1.
	SelectorStart _ 2
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

	CompilerHooksSize _ 15.
]

{ #category : #initialization }
Interpreter class >> initializeContextIndices [
	"Class MethodContext"
	SenderIndex _ 0.
	InstructionPointerIndex _ 1.
	StackPointerIndex _ 2.
	MethodIndex _ 3.
	ReceiverIndex _ 5.
	TempFrameStart _ 6.  "Note this is in two places!"

	"Class BlockContext"
	CallerIndex _ 0.
	BlockArgumentCountIndex _ 3.
	InitialIPIndex _ 4.
	HomeIndex _ 5.

	"Class BlockClosure"
	BlockMethodIndex _ 0.

]

{ #category : #initialization }
Interpreter class >> initializeDirectoryLookupResultCodes [

	DirEntryFound _ 0.
	DirNoMoreEntries _ 1.
	DirBadPath _ 2.
]

{ #category : #initialization }
Interpreter class >> initializeMessageIndices [
	MessageSelectorIndex _ 0.
	MessageArgumentsIndex _ 1.
	MessageLookupClassIndex _ 2.
]

{ #category : #initialization }
Interpreter class >> initializeMethodIndices [
	"Class CompiledMethod"
	HeaderIndex _ 0.
	LiteralStart _ 1
]

{ #category : #initialization }
Interpreter class >> initializePointIndices [
	XIndex _ 0.
	YIndex _ 1
]

{ #category : #initialization }
Interpreter class >> initializePrimitiveTable [ 
	"This table generates a C function address table use in primitiveResponse along with dispatchFunctionPointerOn:in:"

	"NOTE: The real limit here is 2047 because of the method header layout but there is no point in going over the needed size"
	MaxPrimitiveIndex _ 575.
	PrimitiveTable _ Array new: MaxPrimitiveIndex + 1.
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
		"32-bit logic is aliased to Integer prims above"
		(20 39 primitiveFail)

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
		(65 primitiveNext)
		(66 primitiveNextPut)
		(67 primitiveAtEnd)

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
		(96 primitiveObsoleteIndexedPrimitive)	"primitiveCopyBits"
		(97 primitiveSnapshot)
		(98 primitiveStoreImageSegment)
		(99 primitiveLoadImageSegment)
		(100 primitivePerformInSuperclass)		"Blue Book: primitiveSignalAtTick"
		(101 primitiveBeCursor)
		(102 primitiveBeDisplay)
		(103 primitiveScanCharacters)
		(104 primitiveObsoleteIndexedPrimitive)	"primitiveDrawLoop"
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
		(146 primitiveObsoleteIndexedPrimitive)	"primitiveReadJoystick"
		(147 primitiveObsoleteIndexedPrimitive)	"primitiveWarpBits"
		(148 primitiveClone)
		(149 primitiveGetAttribute)

		"File Primitives (150-169) - NO LONGER INDEXED"
		(150 164 primitiveObsoleteIndexedPrimitive)
		(165 primitiveIntegerAt)		"hacked in here for now"
		(166 primitiveIntegerAtPut)
		(167 primitiveYield)
		(168 primitiveCopyObject)
		(169 primitiveObsoleteIndexedPrimitive)

		"Sound Primitives (170-199) - NO LONGER INDEXED"
		(170 185 primitiveObsoleteIndexedPrimitive)

		"Old closure primitives"
		(186 primitiveFail) "was primitiveClosureValue"
		(187 primitiveFail) "was primitiveClosureValueWithArgs"

		"Perform method directly"
		(188 primitiveExecuteMethodArgsArray)
		(189 primitiveExecuteMethod)

		"Sound Primitives (continued) - NO LONGER INDEXED"
		(190 194 primitiveObsoleteIndexedPrimitive)

		"Unwind primitives"
		(195 primitiveFindNextUnwindContext)
		(196 primitiveTerminateTo)
		(197 primitiveFindHandlerContext)
		(198 primitiveMarkUnwindMethod)
		(199 primitiveMarkHandlerMethod)

		"Networking Primitives (200-225) - NO LONGER INDEXED"
		(200 225 primitiveObsoleteIndexedPrimitive)

		"Other Primitives (226-249)"
		(226 primitiveFail)
		(227 primitiveFail)
		(228 primitiveFail)	
		(229 primitiveFail)	
		(230 primitiveRelinquishProcessor)
		(231 primitiveForceDisplayUpdate)
		(232 primitiveFormPrint)
		(233 primitiveSetFullScreen)
		(234 primitiveObsoleteIndexedPrimitive) "primBitmapdecompressfromByteArrayat"
		(235 primitiveObsoleteIndexedPrimitive) "primStringcomparewithcollated"
		(236 primitiveObsoleteIndexedPrimitive) "primSampledSoundconvert8bitSignedFromto16Bit"
		(237 primitiveObsoleteIndexedPrimitive) "primBitmapcompresstoByteArray"
		(238 241 primitiveObsoleteIndexedPrimitive) "serial port primitives"
		(242 primitiveFail)
		(243 primitiveObsoleteIndexedPrimitive) "primStringtranslatefromtotable"
		(244 primitiveObsoleteIndexedPrimitive) "primStringfindFirstInStringinSetstartingAt"
		(245 primitiveObsoleteIndexedPrimitive) "primStringindexOfAsciiinStringstartingAt"
		(246 primitiveObsoleteIndexedPrimitive) "primStringfindSubstringinstartingAtmatchTable"
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

		(520 primitiveFail)
		"MIDI Primitives (521-539) - NO LONGER INDEXED"
		(521 529 primitiveObsoleteIndexedPrimitive)
		(530 539 primitiveFail)  "reserved for extended MIDI primitives"

		"Experimental Asynchrous File Primitives - NO LONGER INDEXED"
		(540 545 primitiveObsoleteIndexedPrimitive)
		(546 547 primitiveFail)

		"Pen Tablet Primitives - NO LONGER INDEXED"
		(548 primitiveObsoleteIndexedPrimitive)
		(549 primitiveObsoleteIndexedPrimitive)

		"Sound Codec Primitives - NO LONGER INDEXED"
		(550 553 primitiveObsoleteIndexedPrimitive)
		(554 569 primitiveFail)

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
	ProcessListsIndex _ 0.
	ActiveProcessIndex _ 1.
	"Class LinkedList"
	FirstLinkIndex _ 0.
	LastLinkIndex _ 1.
	"Class Semaphore"
	ExcessSignalsIndex _ 2.
	"Class Link"
	NextLinkIndex _ 0.
	"Class Process"
	SuspendedContextIndex _ 1.
	PriorityIndex _ 2.
	MyListIndex _ 3
]

{ #category : #initialization }
Interpreter class >> initializeSmallIntegers [
	"SmallIntegers"
	ConstMinusOne _ Interpreter new integerObjectOf: -1.
	ConstZero _ Interpreter new integerObjectOf: 0.
	ConstOne _ Interpreter new integerObjectOf: 1.
	ConstTwo _ Interpreter new integerObjectOf: 2
]

{ #category : #initialization }
Interpreter class >> initializeStreamIndices [
	StreamArrayIndex _ 0.
	StreamIndexIndex _ 1.
	StreamReadLimitIndex _ 2.
	StreamWriteLimitIndex _ 3.
]

{ #category : #initialization }
Interpreter class >> obsoleteIndexedPrimitiveTable [
	"Interpreter obsoleteIndexedPrimitiveTableString"
	"Initialize the links from the (now obsolete) indexed primitives to
	the new named primitives."
	| table |
	table _ Array new: MaxPrimitiveIndex+1.
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
	table _ self obsoleteIndexedPrimitiveTable.
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
	table _ self obsoleteNamedPrimitiveTable.
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
	delta _ 6.
	f _ FileStream fileNamed: fileName.
	f binary.
	code _ Bitmap new: (len _ f size) // 4.
	f nextInto: code.
	remnant _ f next: len - (code size * 4).
	i _ 0.
	["Look for a BCTR instruction"
	(i _ code indexOf: 16r4E800420 startingAt: i + 1 ifAbsent: [0]) > 0] whileTrue:
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
	delta _ 7.
	f _ FileStream fileNamed: fileName.
	f binary.
	code _ Bitmap new: (len _ f size) // 4.
	f nextInto: code.
	remnant _ f next: len - (code size * 4).
	i _ 0.
	["Look for a BCTR instruction"
	(i _ code indexOf: 16r4E800420 startingAt: i + 1 ifAbsent: [0]) > 0] whileTrue:
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
	requiredList _ Set new:400.
	"A number of methods required by VM support code, jitter, specific platforms etc"
	requiredList addAll: #(fullDisplayUpdate interpret printCallStack printAllStacks readImageFromFile:HeapSize:StartingAt: success: readableFormat: getCurrentBytecode characterForAscii: findClassOfMethod:forReceiver: findSelectorOfMethod:forReceiver: loadInitialContext nullCompilerHook primitiveFlushExternalPrimitives setCompilerInitialized: getFullScreenFlag getInterruptCheckCounter getInterruptKeycode getInterruptPending getNextWakeupTick getSavedWindowSize setFullScreenFlag: setInterruptCheckCounter: setInterruptKeycode: setInterruptPending: setNextWakeupTick: setSavedWindowSize: forceInterruptCheck getThisSessionID).

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
	contiguous _ 0.
	specArray do: [:spec | 
			(spec at: 1) = contiguous
				ifFalse: [self error: 'Non-contiguous table entry'].
			spec size = 2
				ifTrue: [anArray at: (spec at: 1) + 1
						put: (spec at: 2).
					contiguous _ contiguous + 1]
				ifFalse: [(spec at: 1) to: (spec at: 2) do: [:i | anArray at: i + 1 put: (spec at: 3)].
					contiguous _ contiguous + ((spec at: 2) - (spec at: 1)) + 1]]
]

{ #category : #'message sending' }
Interpreter >> activateNewMethod [
	| newContext methodHeader initialIP tempCount nilOop where |

	methodHeader _ self headerOf: newMethod.
	newContext _ self allocateOrRecycleContext: (methodHeader bitAnd: LargeContextBit).

	initialIP _ ((LiteralStart + (self literalCountOfHeader: methodHeader)) * BytesPerWord) + 1.
	tempCount _ (methodHeader >> 19) bitAnd: 16r3F.

	"Assume: newContext will be recorded as a root if necessary by the
	 call to newActiveContext: below, so we can use unchecked stores."

	where _  newContext  + BaseHeaderSize.
	self longAt: where + (SenderIndex << ShiftForWord) put: activeContext.
	self longAt: where + (InstructionPointerIndex << ShiftForWord) put: (self integerObjectOf: initialIP).
	self longAt: where + (StackPointerIndex << ShiftForWord) put: (self integerObjectOf: tempCount).
	self longAt: where + (MethodIndex << ShiftForWord) put: newMethod.

	"Copy the reciever and arguments..."
	0 to: argumentCount do:
		[:i | self longAt: where + ((ReceiverIndex+i) << ShiftForWord) put: (self stackValue: argumentCount-i)].

	"clear remaining temps to nil in case it has been recycled"
	nilOop _ nilObj.
	argumentCount+1+ReceiverIndex to: tempCount+ReceiverIndex do:
		[:i | self longAt: where + (i << ShiftForWord) put: nilOop].

	self pop: argumentCount + 1.
	reclaimableContextCount _ reclaimableContextCount + 1.
	self newActiveContext: newContext.
]

{ #category : #processes }
Interpreter >> addLastLink: proc toList: aList [ 
	"Add the given process to the given linked list and set the 
	backpointer of process to its new list."
	| lastLink |
	(self isEmptyList: aList)
		ifTrue: [self storePointer: FirstLinkIndex ofObject: aList withValue: proc]
		ifFalse: [lastLink _ self fetchPointer: LastLinkIndex ofObject: aList.
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
	self inline: false.
	self compilerTranslateMethodHook.	"newMethod x lkupClass -> newNativeMethod (may cause GC !)"
	hash _ messageSelector bitXor: lkupClass.  "drop low-order zeros from addresses"

	primitiveFunctionPointer _ self functionPointerFor: primitiveIndex inClass: lkupClass.
	
	0 to: CacheProbeMax-1 do:
		[:p | probe _ (hash >> p) bitAnd: MethodCacheMask.
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
	probe _ hash bitAnd: MethodCacheMask.  "first probe"
	methodCache at: probe + MethodCacheSelector put: messageSelector.
	methodCache at: probe + MethodCacheClass put: lkupClass.
	methodCache at: probe + MethodCacheMethod put: newMethod.
	methodCache at: probe + MethodCachePrim put: primitiveIndex.
	methodCache at: probe + MethodCacheNative put: newNativeMethod.
	methodCache at: probe + MethodCachePrimFunction put: (self cCoerce: primitiveFunctionPointer to: 'long').

	"...and zap the following entries"
	1 to: CacheProbeMax-1 do:
		[:p | probe _ (hash >> p) bitAnd: MethodCacheMask.
		methodCache at: probe + MethodCacheSelector put: 0].

]

{ #category : #'plugin support' }
Interpreter >> addToExternalPrimitiveTable: functionAddress [
	"Add the given function address to the external primitive table and return the index where it's stored. This function doesn't need to be fast since it is only called when an external primitive has been looked up (which takes quite a bit of time itself). So there's nothing specifically complicated here.
	Note: Return index will be one-based (ST convention)"

	self var: #functionAddress declareC: 'void *functionAddress'.

	0 to: MaxExternalPrimitiveTableSize-1 do: [ :i |
		(externalPrimitiveTable at: i) = 0 ifTrue: [
			externalPrimitiveTable at: i put: functionAddress.
			^i+1]].
	"if no space left, return zero so it'll looked up again"
	^0
]

{ #category : #utilities }
Interpreter >> addressOf: rcvr startingAt: byteOffset size: byteSize [
"Return the int of the address of the (byteSize) slot at btyeOffset in rcvr. Usde for getting byte/word/int/float/double out of Byte/WordArrays"
	| rcvrSize addr |
	(self isBytes: rcvr) ifFalse:[^self primitiveFail].
	(byteOffset > 0) ifFalse:[^self primitiveFail].
	rcvrSize _ self byteSizeOf: rcvr.
	(byteOffset+byteSize-1 <= rcvrSize)
			ifFalse:[^self primitiveFail].
	addr _ self cCoerce: (self firstIndexableField: rcvr) to: 'int'.
	addr _ addr + byteOffset - 1.
	^addr
]

{ #category : #'debug support' }
Interpreter >> allAccessibleObjectsOkay [
	"Ensure that all accessible objects in the heap are okay."

	| oop |
	oop _ self firstAccessibleObject.
	[oop = nil] whileFalse: [
		self okayFields: oop.
		oop _ self accessibleObjectAfter: oop.
	].
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
	localArgCount _ self fetchPointer: BlockArgumentCountIndex ofObject: blockPointer.
	^self checkedIntegerValueOf: localArgCount
]

{ #category : #utilities }
Interpreter >> arrayValueOf: arrayOop [
	"Return the address of first indexable field of resulting array object, or fail if the instance variable does not contain an indexable bytes or words object."
	"Note: May be called by translated primitive code."

	self returnTypeC: 'void *'.
	((self isIntegerObject: arrayOop) not and:
	 [self isWordsOrBytes: arrayOop])
		ifTrue: [^ self cCode: '(void *)pointerForOop(arrayOop + BaseHeaderSize)'].
	self primitiveFail.

]

{ #category : #'array and stream primitive support' }
Interpreter >> asciiOfCharacter: characterObj [  "Returns an integer object"

	self inline: false.
	self assertClassOf: characterObj is: (self splObj: ClassCharacter).
	successFlag
		ifTrue: [^ self fetchPointer: CharacterValueIndex ofObject: characterObj]
		ifFalse: [^ ConstZero]  "in case some code needs an int"
]

{ #category : #utilities }
Interpreter >> assertClassOf: oop is: classOop [
	"Succeed if the given (non-integer) object is an instance of the given class. Fail if the object is an integer."

	| ccIndex cl |
	self inline: true.
	(self isIntegerObject: oop)
		ifTrue: [ successFlag _ false. ^ nil ].

	ccIndex _ ((self baseHeader: oop) >> 12) bitAnd: 16r1F.
	ccIndex = 0
		ifTrue: [ cl _ ((self classHeader: oop) bitAnd: AllButTypeMask) ]
		ifFalse: [
			"look up compact class"
			cl _ (self fetchPointer: (ccIndex - 1)
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
		^(stackPointer - activeContext + (nArgs * BytesPerWord)) = delta
	].
	"Failed prim must leave stack intact"
	^(stackPointer - activeContext) = delta

]

{ #category : #utilities }
Interpreter >> booleanCheat: cond [
"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	| bytecode offset |
	self inline: true.

	bytecode _ self fetchByte.  "assume next bytecode is jumpIfFalse (99%)"
	self internalPop: 2.
	(bytecode < 160 and: [bytecode > 151]) ifTrue: [  "short jumpIfFalse"
		cond
			ifTrue: [^ self fetchNextBytecode]
			ifFalse: [^ self jump: bytecode - 151]].

	bytecode = 172 ifTrue: [  "long jumpIfFalse"
		offset _ self fetchByte.
		cond
			ifTrue: [^ self fetchNextBytecode]
			ifFalse: [^ self jump: offset]].

	"not followed by a jumpIfFalse; undo instruction fetch and push boolean result"
	localIP _ localIP - 1.
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
	successFlag _ false.
	^ nil
]

{ #category : #'array and stream primitive support' }
Interpreter >> byteLengthOf: oop [
	"Return the number of indexable bytes in the given object. This is basically a special copy of lengthOf: for BitBlt."
	| header sz fmt |
	header _ self baseHeader: oop.
	(header bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ sz _ (self sizeHeader: oop) bitAnd: AllButTypeMask ]
		ifFalse: [ sz _ header bitAnd: SizeMask ].
	fmt _ (header >> 8) bitAnd: 16rF.
	fmt < 8
		ifTrue: [ ^ (sz - BaseHeaderSize)]  "words"
		ifFalse: [ ^ (sz - BaseHeaderSize) - (fmt bitAnd: 3)]  "bytes"
]

{ #category : #'object format' }
Interpreter >> byteSizeOf: oop [
	| slots |
self flag: #Dan.
	(self isIntegerObject: oop) ifTrue:[^0].
	slots _ self slotSizeOf: oop.
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
	oop _ startOop.
	[oop < stopAddr]
		whileTrue: [(self isFreeObject: oop)
				ifFalse: [fmt _ self formatOf: oop.
					fmt >= 8
						ifTrue: ["oop contains bytes"
							wordAddr _ oop + BaseHeaderSize.
							fmt >= 12
								ifTrue: ["compiled method; start after methodHeader and literals"
									methodHeader _ self longAt: oop + BaseHeaderSize.
									wordAddr _ wordAddr + BytesPerWord + ((methodHeader >> 10 bitAnd: 255) * BytesPerWord)].
							self reverseBytesFrom: wordAddr to: oop + (self sizeBitsOf: oop)].
					(fmt = 6 and: [BytesPerWord = 8])
						ifTrue: ["Object contains 32-bit half-words packed into 64-bit machine words."
							wordAddr _ oop + BaseHeaderSize.
							self reverseWordsFrom: wordAddr to: oop + (self sizeBitsOf: oop)]].
			oop _ self objectAfter: oop]
]

{ #category : #'image save/restore' }
Interpreter >> byteSwapped: w [
	"Answer the given integer with its bytes in the reverse order."

	BytesPerWord = 4
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
	rcvr _ self internalStackValue: 1.
	arg _ self internalStackValue: 0.
	(self areIntegers: rcvr and: arg)
		ifTrue: [result _ (self integerValueOf: rcvr) + (self integerValueOf: arg).
				(self isIntegerValue: result) ifTrue:
					[self internalPop: 2 thenPush: (self integerObjectOf: result).
					^ self fetchNextBytecode "success"]]
		ifFalse: [successFlag _ true.
				self externalizeIPandSP.
				self primitiveFloatAdd: rcvr toArg: arg.
				self internalizeIPandSP.
				successFlag ifTrue: [^ self fetchNextBytecode "success"]].

	messageSelector _ self specialSelector: 0.
	argumentCount _ 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimAt [
	"BytecodePrimAt will only succeed if the receiver is in the atCache.
	Otherwise it will fail so that the more general primitiveAt will put it in the
	cache after validating that message lookup results in a primitive response."
	| index rcvr result atIx |
	index _ self internalStackTop.
	rcvr _ self internalStackValue: 1.
	successFlag _ (self isIntegerObject: rcvr) not and: [self isIntegerObject: index].
	successFlag ifTrue:
		[atIx _ rcvr bitAnd: AtCacheMask.  "Index into atCache = 4N, for N = 0 ... 7"
		(atCache at: atIx+AtCacheOop) = rcvr
		ifTrue: [result _ self commonVariableInternal: rcvr at: (self integerValueOf: index) cacheIndex: atIx.
			successFlag ifTrue:
				[self fetchNextBytecode.
				^self internalPop: 2 thenPush: result]]].

	messageSelector _ self specialSelector: 16.
	argumentCount _ 1.
	self normalSend.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimAtEnd [
	messageSelector _ self specialSelector: 21.
	argumentCount _ 0.
	self normalSend.
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimAtPut [
	"BytecodePrimAtPut will only succeed if the receiver is in the atCache.
	Otherwise it will fail so that the more general primitiveAtPut will put it in the
	cache after validating that message lookup results in a primitive response."
	| index rcvr atIx value |
	value _ self internalStackTop.
	index _ self internalStackValue: 1.
	rcvr _ self internalStackValue: 2.
	successFlag _ (self isIntegerObject: rcvr) not and: [self isIntegerObject: index].
	successFlag
		ifTrue: [atIx _ (rcvr bitAnd: AtCacheMask) + AtPutBase.  "Index into atPutCache"
			(atCache at: atIx+AtCacheOop) = rcvr
				ifTrue: [self commonVariable: rcvr at: (self integerValueOf: index) put: value cacheIndex: atIx.
					successFlag ifTrue: [self fetchNextBytecode.
						^self internalPop: 3 thenPush: value]]].

	messageSelector _ self specialSelector: 17.
	argumentCount _ 2.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimBitAnd [

	successFlag _ true.
	self externalizeIPandSP.
	self primitiveBitAnd.
	self internalizeIPandSP.
	successFlag ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector _ self specialSelector: 14.
	argumentCount _ 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimBitOr [

	successFlag _ true.
	self externalizeIPandSP.
	self primitiveBitOr.
	self internalizeIPandSP.
	successFlag ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector _ self specialSelector: 15.
	argumentCount _ 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimBitShift [

	successFlag _ true.
	self externalizeIPandSP.
	self primitiveBitShift.
	self internalizeIPandSP.
	successFlag ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector _ self specialSelector: 12.
	argumentCount _ 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimBlockCopy [

	| rcvr hdr |
	rcvr _ self internalStackValue: 1.
	successFlag _ true.
	hdr _ self baseHeader: rcvr.
	self success: (self isContextHeader: hdr).
	successFlag ifTrue: [self externalizeIPandSP.
		self primitiveBlockCopy.
		self internalizeIPandSP].
	successFlag ifFalse: [messageSelector _ self specialSelector: 24.
		argumentCount _ 1.
		^ self normalSend].
	self fetchNextBytecode.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimClass [
	| rcvr |
	rcvr _ self internalStackTop.
	self internalPop: 1 thenPush: (self fetchClassOf: rcvr).
	self fetchNextBytecode.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimDiv [
	| quotient |
	successFlag _ true.
	quotient _ self doPrimitiveDiv: (self internalStackValue: 1) by: (self internalStackValue: 0).
	successFlag ifTrue: [self internalPop: 2 thenPush: (self integerObjectOf: quotient).
		^ self fetchNextBytecode "success"].

	messageSelector _ self specialSelector: 13.
	argumentCount _ 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimDivide [
	| rcvr arg result |
	rcvr _ self internalStackValue: 1.
	arg _ self internalStackValue: 0.
	(self areIntegers: rcvr and: arg)
		ifTrue: [rcvr _ self integerValueOf: rcvr.
			arg _ self integerValueOf: arg.
			(arg ~= 0 and: [rcvr \\ arg = 0])
				ifTrue: [result _ rcvr // arg.
					"generates C / operation"
					(self isIntegerValue: result)
						ifTrue: [self internalPop: 2 thenPush: (self integerObjectOf: result).
							^ self fetchNextBytecode"success"]]]
		ifFalse: [successFlag _ true.
			self externalizeIPandSP.
			self primitiveFloatDivide: rcvr byArg: arg.
			self internalizeIPandSP.
			successFlag ifTrue: [^ self fetchNextBytecode"success"]].

	messageSelector _ self specialSelector: 9.
	argumentCount _ 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimDo [

	messageSelector _ self specialSelector: 27.
	argumentCount _ 1.
	self normalSend.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimEqual [
	| rcvr arg aBool |
	rcvr _ self internalStackValue: 1.
	arg _ self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue: [^self booleanCheat: rcvr = arg].

	successFlag _ true.
	aBool _ self primitiveFloatEqual: rcvr toArg: arg.
	successFlag ifTrue: [^self booleanCheat: aBool].

	messageSelector _ self specialSelector: 6.
	argumentCount _ 1.
	self normalSend

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimEquivalent [

	| rcvr arg |
	rcvr _ self internalStackValue: 1.
	arg _ self internalStackValue: 0.
	self booleanCheat: rcvr = arg.
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimGreaterOrEqual [
	| rcvr arg aBool |
	rcvr _ self internalStackValue: 1.
	arg _ self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		[self cCode: '' inSmalltalk: [^self booleanCheat: (self integerValueOf: rcvr) >= (self integerValueOf: arg)].
		^self booleanCheat: rcvr >= arg].

	successFlag _ true.
	aBool _ self primitiveFloatLess: rcvr thanArg: arg.
	successFlag ifTrue: [^self booleanCheat: aBool not].

	messageSelector _ self specialSelector: 5.
	argumentCount _ 1.
	self normalSend

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimGreaterThan [
	| rcvr arg aBool |
	rcvr _ self internalStackValue: 1.
	arg _ self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		[self cCode: '' inSmalltalk: [^self booleanCheat: (self integerValueOf: rcvr) > (self integerValueOf: arg)].
		^self booleanCheat: rcvr > arg].

	successFlag _ true.
	aBool _ self primitiveFloatGreater: rcvr thanArg: arg.
	successFlag ifTrue: [^self booleanCheat: aBool].

	messageSelector _ self specialSelector: 3.
	argumentCount _ 1.
	self normalSend

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimLessOrEqual [
	| rcvr arg aBool |
	rcvr _ self internalStackValue: 1.
	arg _ self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		[self cCode: '' inSmalltalk: [^self booleanCheat: (self integerValueOf: rcvr) <= (self integerValueOf: arg)].
		^ self booleanCheat: rcvr <= arg].

	successFlag _ true.
	aBool _ self primitiveFloatGreater: rcvr thanArg: arg.
	successFlag ifTrue: [^self booleanCheat: aBool not].

	messageSelector _ self specialSelector: 4.
	argumentCount _ 1.
	self normalSend

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimLessThan [
	| rcvr arg aBool |
	rcvr _ self internalStackValue: 1.
	arg _ self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		[self cCode: '' inSmalltalk: [^self booleanCheat: (self integerValueOf: rcvr) < (self integerValueOf: arg)].
		^ self booleanCheat: rcvr < arg].

	successFlag _ true.
	aBool _ self primitiveFloatLess: rcvr thanArg: arg.
	successFlag ifTrue: [^ self booleanCheat: aBool].

	messageSelector _ self specialSelector: 2.
	argumentCount _ 1.
	self normalSend

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimMakePoint [

	successFlag _ true.
	self externalizeIPandSP.
	self primitiveMakePoint.
	self internalizeIPandSP.
	successFlag ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector _ self specialSelector: 11.
	argumentCount _ 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimMod [
	| mod |
	successFlag _ true.
	mod _ self doPrimitiveMod: (self internalStackValue: 1) by: (self internalStackValue: 0).
	successFlag ifTrue:
		[self internalPop: 2 thenPush: (self integerObjectOf: mod).
		^ self fetchNextBytecode "success"].

	messageSelector _ self specialSelector: 10.
	argumentCount _ 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimMultiply [
	| rcvr arg result |
	rcvr _ self internalStackValue: 1.
	arg _ self internalStackValue: 0.
	(self areIntegers: rcvr and: arg)
		ifTrue: [rcvr _ self integerValueOf: rcvr.
				arg _ self integerValueOf: arg.
				result _ rcvr * arg.
				((arg = 0 or: [(result // arg) = rcvr]) and: [self isIntegerValue: result])
					ifTrue: [self internalPop: 2 thenPush: (self integerObjectOf: result).
							^ self fetchNextBytecode "success"]]
		ifFalse: [successFlag _ true.
				self externalizeIPandSP.
				self primitiveFloatMultiply: rcvr byArg: arg.
				self internalizeIPandSP.
				successFlag ifTrue: [^ self fetchNextBytecode "success"]].

	messageSelector _ self specialSelector: 8.
	argumentCount _ 1.
	self normalSend.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimNew [

	messageSelector _ self specialSelector: 28.
	argumentCount _ 0.
	self normalSend.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimNewWithArg [

	messageSelector _ self specialSelector: 29.
	argumentCount _ 1.
	self normalSend.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimNext [
	messageSelector _ self specialSelector: 19.
	argumentCount _ 0.
	self normalSend.
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimNextPut [
	messageSelector _ self specialSelector: 20.
	argumentCount _ 1.
	self normalSend.
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimNotEqual [
	| rcvr arg aBool |
	rcvr _ self internalStackValue: 1.
	arg _ self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue: [^self booleanCheat: rcvr ~= arg].

	successFlag _ true.
	aBool _ self primitiveFloatEqual: rcvr toArg: arg.
	successFlag ifTrue: [^self booleanCheat: aBool not].

	messageSelector _ self specialSelector: 7.
	argumentCount _ 1.
	self normalSend

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimPointX [

	| rcvr |
	successFlag _ true.
	rcvr _ self internalStackTop.
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	successFlag
		ifTrue: [self internalPop: 1 thenPush: (self fetchPointer: XIndex ofObject: rcvr).
			^ self fetchNextBytecode "success"].

	messageSelector _ self specialSelector: 30.
	argumentCount _ 0.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimPointY [

	| rcvr |
	successFlag _ true.
	rcvr _ self internalStackTop.
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	successFlag
		ifTrue: [self internalPop: 1 thenPush: (self fetchPointer: YIndex ofObject: rcvr).
			^ self fetchNextBytecode "success"].

	messageSelector _ self specialSelector: 31.
	argumentCount _ 0.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimSize [
	messageSelector _ self specialSelector: 18.
	argumentCount _ 0.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimSubtract [
	| rcvr arg result |
	rcvr _ self internalStackValue: 1.
	arg _ self internalStackValue: 0.
	(self areIntegers: rcvr and: arg)
		ifTrue: [result _ (self integerValueOf: rcvr) - (self integerValueOf: arg).
				(self isIntegerValue: result) ifTrue:
					[self internalPop: 2 thenPush: (self integerObjectOf: result).
					^self fetchNextBytecode "success"]]
		ifFalse: [successFlag _ true.
				self externalizeIPandSP.
				self primitiveFloatSubtract: rcvr fromArg: arg.
				self internalizeIPandSP.
				successFlag ifTrue: [^self fetchNextBytecode "success"]].

	messageSelector _ self specialSelector: 1.
	argumentCount _ 1.
	self normalSend
]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimValue [

	| block |
	block _ self internalStackTop.
	successFlag _ true.
	argumentCount _ 0.
	self assertClassOf: block is: (self splObj: ClassBlockContext).
	successFlag ifTrue: [
		self externalizeIPandSP.
		self primitiveValue.
		self internalizeIPandSP.
	].
	successFlag ifFalse: [
		messageSelector _ self specialSelector: 25.
		argumentCount _ 0.
		^ self normalSend
	].
	self fetchNextBytecode.

]

{ #category : #'common selector sends' }
Interpreter >> bytecodePrimValueWithArg [

	| block |
	block _ self internalStackValue: 1.
	successFlag _ true.
	argumentCount _ 1.
	self assertClassOf: block is: (self splObj: ClassBlockContext).
	successFlag ifTrue: [
		self externalizeIPandSP.
		self primitiveValue.
		self internalizeIPandSP.
	].
	successFlag ifFalse: [
		messageSelector _ self specialSelector: 26.
		argumentCount _ 1.
		^ self normalSend
	].
	self fetchNextBytecode.

]

{ #category : #'plugin primitive support' }
Interpreter >> callExternalPrimitive: functionID [
	"Call the external plugin function identified. In the VM this is an address, see 	InterpreterSimulator for it's version. "

	self var: #functionID type: 'void *'.
	self dispatchFunctionPointer: functionID
]

{ #category : #contexts }
Interpreter >> caller [
	^self fetchPointer: CallerIndex ofObject: activeContext
]

{ #category : #'debug support' }
Interpreter >> capturePendingFinalizationSignals [
	statpendingFinalizationSignals _ pendingFinalizationSignals.

]

{ #category : #'array and stream primitive support' }
Interpreter >> characterForAscii: ascii [  "Arg must lie in range 0-255!"
	self inline: true.
	^ self fetchPointer: ascii ofObject: (self splObj: CharacterTable)
]

{ #category : #'arithmetic primitive support' }
Interpreter >> checkBooleanResult: result [
	successFlag
		ifTrue: [self pushBool: result]
		ifFalse: [self unPop: 2]
]

{ #category : #processes }
Interpreter >> checkForInterrupts [
	"Check for possible interrupts and handle one if necessary."
	| sema now |
	self inline: false.

	"Mask so same wrapping as primitiveMillisecondClock"
	now _ self ioMSecs bitAnd: MillisecondClockMask.

	self interruptCheckForced ifFalse: [
		"don't play with the feedback if we forced a check. It only makes life difficult"
		now - lastTick < interruptChecksEveryNms
			ifTrue: ["wrapping is not a concern, it'll get caught quickly  
				enough. This clause is trying to keep a reasonable  
				guess of how many times per 	interruptChecksEveryNms we are calling  
				quickCheckForInterrupts. Not sure how effective it really is."
				interruptCheckCounterFeedBackReset _ interruptCheckCounterFeedBackReset + 10]
			ifFalse: [interruptCheckCounterFeedBackReset <= 1000
					ifTrue: [interruptCheckCounterFeedBackReset _ 1000]
					ifFalse: [interruptCheckCounterFeedBackReset _ interruptCheckCounterFeedBackReset - 12]]].

	"reset the interrupt check counter"
	interruptCheckCounter _ interruptCheckCounterFeedBackReset.

	signalLowSpace
		ifTrue: [signalLowSpace _ false. "reset flag"
			sema _ self splObj: TheLowSpaceSemaphore.
			sema = nilObj ifFalse: [self synchronousSignal: sema]].

	now < lastTick
		ifTrue: ["millisecond clock wrapped so correct the nextPollTick"
			nextPollTick _ nextPollTick - MillisecondClockMask - 1].
	now >= nextPollTick
		ifTrue: [self ioProcessEvents.
			"sets interruptPending if interrupt key pressed"
			nextPollTick _ now + 200
			"msecs to wait before next call to ioProcessEvents.  
			Note that strictly speaking we might need to update  
			'now' at this point since ioProcessEvents could take a  
			very long time on some platforms"].
	interruptPending
		ifTrue: [interruptPending _ false.
			"reset interrupt flag"
			sema _ self splObj: TheInterruptSemaphore.
			sema = nilObj
				ifFalse: [self synchronousSignal: sema]].

	nextWakeupTick ~= 0
		ifTrue: [now < lastTick
				ifTrue: ["the clock has wrapped. Subtract the wrap  
					interval from nextWakeupTick - this might just  
					possibly result in 0. Since this is used as a flag  
					value for 'no timer' we do the 0 check above"
					nextWakeupTick _ nextWakeupTick - MillisecondClockMask - 1].
			now >= nextWakeupTick
				ifTrue: [nextWakeupTick _ 0.
					"set timer interrupt to 0 for 'no timer'"
					sema _ self splObj: TheTimerSemaphore.
					sema = nilObj ifFalse: [self synchronousSignal: sema]]].

	"signal any pending finalizations"
	pendingFinalizationSignals > 0
		ifTrue: [sema _ self splObj: TheFinalizationSemaphore.
			(self fetchClassOf: sema) = (self splObj: ClassSemaphore)
				ifTrue: [self synchronousSignal: sema].
			pendingFinalizationSignals _ 0].

	"signal all semaphores in semaphoresToSignal"
	(semaphoresToSignalCountA > 0 or: [semaphoresToSignalCountB > 0])
		ifTrue: [self signalExternalSemaphores].

	"update the tracking value"
	lastTick _ now
]

{ #category : #'image save/restore' }
Interpreter >> checkImageVersionFrom: f startingAt: imageOffset [
	"Read and verify the image file version number and return true if the the given image file needs to be byte-swapped. As a side effect, position the file stream just after the version number of the image header. This code prints a warning and does a hard-exit if it cannot find a valid version number."
	"This code is based on C code by Ian Piumarta."

	| version firstVersion |
	self var: #f type: 'sqImageFile '.
	self var: #imageOffset type: 'squeakFileOffsetType '.

	"check the version number"
	self sqImageFile: f Seek: imageOffset.
	version _ firstVersion _ self getLongFromFile: f swap: false.
	(self readableFormat: version) ifTrue: [^ false].

	"try with bytes reversed"
	self sqImageFile: f Seek: imageOffset.
	version _ self getLongFromFile: f swap: true.
	(self readableFormat: version) ifTrue: [^ true].

	"Note: The following is only meaningful if not reading an embedded image"
	imageOffset = 0 ifTrue:[
		"try skipping the first 512 bytes (prepended by certain Mac file transfer utilities)"
		self sqImageFile: f Seek: 512.
		version _ self getLongFromFile: f swap: false.
		(self readableFormat: version) ifTrue: [^ false].

		"try skipping the first 512 bytes with bytes reversed"
		self sqImageFile: f Seek: 512.
		version _ self getLongFromFile: f swap: true.
		(self readableFormat: version) ifTrue: [^ true]].

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
	self var: #className type: 'char *'.
	self var: #srcName type: 'char *'.
	(self lengthOf: aClass) <= 6 ifTrue: [^ false].

	"Not a class but might be behavior"
	name _ self fetchPointer: 6 ofObject: aClass.
	(self isBytes: name) ifFalse: [^ false].
	length _ self stSizeOf: name.
	srcName _ self cCoerce: (self arrayValueOf: name) to: 'char *'.
	0 to: length - 1 do: [:i | (srcName at: i) = (className at: i) ifFalse: [^ false]].
	"Check if className really ends at this point"
	^ (className at: length) = 0
]

{ #category : #'array and stream primitive support' }
Interpreter >> commonAt: stringy [
	"This code is called if the receiver responds primitively to at:.
	If this is so, it will be installed in the atCache so that subsequent calls of at:
	or next may be handled immediately in bytecode primitive routines."
	| index rcvr atIx result |
	index _ self positive32BitValueOf: (self stackTop).  "Sets successFlag"
	rcvr _ self stackValue: 1.
	successFlag & (self isIntegerObject: rcvr) not
		ifFalse: [^ self primitiveFail].

	"NOTE:  The at-cache, since it is specific to the non-super response to #at:.
	Therefore we must determine that the message is #at: (not, eg, #basicAt:),
	and that the send is not a super-send, before using the at-cache."
	(messageSelector = (self specialSelector: 16)
		and: [lkupClass = (self fetchClassOfNonInt: rcvr)])
		ifTrue:
		["OK -- look in the at-cache"
		atIx _ rcvr bitAnd: AtCacheMask.  "Index into atCache = 4N, for N = 0 ... 7"
		(atCache at: atIx+AtCacheOop) = rcvr ifFalse:
			["Rcvr not in cache.  Install it..."
			self install: rcvr inAtCache: atCache at: atIx string: stringy].
		successFlag ifTrue:
			[result _ self commonVariable: rcvr at: index cacheIndex: atIx].
		successFlag ifTrue:
			[^ self pop: argumentCount+1 thenPush: result]].

	"The slow but sure way..."
	successFlag _ true.
	result _ self stObject: rcvr at: index.
	successFlag ifTrue:
		[stringy ifTrue: [result _ self characterForAscii: (self integerValueOf: result)].
		^ self pop: argumentCount+1 thenPush: result]
]

{ #category : #'array and stream primitive support' }
Interpreter >> commonAtPut: stringy [
	"This code is called if the receiver responds primitively to at:Put:.
	If this is so, it will be installed in the atPutCache so that subsequent calls of at:
	or  next may be handled immediately in bytecode primitive routines."
	| value index rcvr atIx |
	value _ self stackTop.
	index _ self positive32BitValueOf: (self stackValue: 1).  "Sets successFlag"
	rcvr _ self stackValue: 2.
	successFlag & (self isIntegerObject: rcvr) not
		ifFalse: [^ self primitiveFail].

	"NOTE:  The atPut-cache, since it is specific to the non-super response to #at:Put:.
	Therefore we must determine that the message is #at:Put: (not, eg, #basicAt:Put:),
	and that the send is not a super-send, before using the at-cache."
	(messageSelector = (self specialSelector: 17)
		and: [lkupClass = (self fetchClassOfNonInt: rcvr)])
		ifTrue:
		["OK -- look in the at-cache"
		atIx _ (rcvr bitAnd: AtCacheMask) + AtPutBase.  "Index into atPutCache"
		(atCache at: atIx+AtCacheOop) = rcvr ifFalse:
			["Rcvr not in cache.  Install it..."
			self install: rcvr inAtCache: atCache at: atIx string: stringy].
		successFlag ifTrue:
			[self commonVariable: rcvr at: index put: value cacheIndex: atIx].
		successFlag ifTrue:
			[^ self pop: argumentCount+1 thenPush: value]].

	"The slow but sure way..."
	successFlag _ true.
	stringy ifTrue: [self stObject: rcvr at: index put: (self asciiOfCharacter: value)]
			ifFalse: [self stObject: rcvr at: index put: value].
	successFlag ifTrue: [^ self pop: argumentCount+1 thenPush: value].

]

{ #category : #'return bytecodes' }
Interpreter >> commonReturn [
	"Note: Assumed to be inlined into the dispatch loop."

	| nilOop thisCntx contextOfCaller localCntx localVal unwindMarked |
	self inline: true.
	self sharedCodeNamed: 'commonReturn' inCase: 120.

	nilOop _ nilObj. "keep in a register"
	thisCntx _ activeContext.
	localCntx _ localReturnContext.
	localVal _ localReturnValue.

	"make sure we can return to the given context"
	((localCntx = nilOop) or:
	 [(self fetchPointer: InstructionPointerIndex ofObject: localCntx) = nilOop]) ifTrue: [
		"error: sender's instruction pointer or context is nil; cannot return"
		^self internalCannotReturn: localVal].

	"If this return is not to our immediate predecessor (i.e. from a method to its sender, or from a block to its caller), scan the stack for the first unwind marked context and inform this context and let it deal with it. This provides a chance for ensure unwinding to occur."
	thisCntx _ self fetchPointer: SenderIndex ofObject: activeContext.

	"Just possibly a faster test would be to compare the homeContext and activeContext - they are of course different for blocks. Thus we might be able to optimise a touch by having a different returnTo for the blockreteurn (since we know that must return to caller) and then if active ~= home we must be doing a non-local return. I think. Maybe."
	[thisCntx = localCntx] whileFalse: [
		thisCntx = nilOop ifTrue:[
			"error: sender's instruction pointer or context is nil; cannot return"
			^self internalCannotReturn: localVal].
		"Climb up stack towards localCntx. Break out to a send of #aboutToReturn:through: if an unwind marked context is found"
		unwindMarked _ self isUnwindMarked: thisCntx.
		unwindMarked ifTrue:[
			"context is marked; break out"
			^self internalAboutToReturn: localVal through: thisCntx].
		thisCntx _ self fetchPointer: SenderIndex ofObject: thisCntx.
 ].

	"If we get here there is no unwind to worry about. Simply terminate the stack up to the localCntx - often just the sender of the method"
	thisCntx _ activeContext.
	[thisCntx = localCntx]
		whileFalse:
		["climb up stack to localCntx"
		contextOfCaller _ self fetchPointer: SenderIndex ofObject: thisCntx.

		"zap exited contexts so any future attempted use will be caught"
		self storePointerUnchecked: SenderIndex ofObject: thisCntx withValue: nilOop.
		self storePointerUnchecked: InstructionPointerIndex ofObject: thisCntx withValue: nilOop.
		reclaimableContextCount > 0 ifTrue:
			["try to recycle this context"
			reclaimableContextCount _ reclaimableContextCount - 1.
			self recycleContextIfPossible: thisCntx].
		thisCntx _ contextOfCaller].

	activeContext _ thisCntx.
	(thisCntx < youngStart) ifTrue: [ self beRootIfOld: thisCntx ].

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

{ #category : #'array and stream primitive support' }
Interpreter >> commonVariable: rcvr at: index cacheIndex: atIx [ 
	"This code assumes the reciever has been identified at location atIx in the atCache."
	| stSize fmt fixedFields result |

	stSize _ atCache at: atIx+AtCacheSize.
	((self cCoerce: index to: 'usqInt ') >= 1
		and: [(self cCoerce: index to: 'usqInt ') <= (self cCoerce: stSize to: 'usqInt ')])
	ifTrue:
		[fmt _ atCache at: atIx+AtCacheFmt.
		fmt <= 4 ifTrue:
			[fixedFields _ atCache at: atIx+AtCacheFixedFields.
			^ self fetchPointer: index + fixedFields - 1 ofObject: rcvr].
		fmt < 8 ifTrue:  "Bitmap"
			[result _ self fetchLong32: index - 1 ofObject: rcvr.
			result _ self positive32BitIntegerFor: result.
			^ result].
		fmt >= 16  "Note fmt >= 16 is an artificial flag for strings"
			ifTrue: "String"
			[^ self characterForAscii: (self fetchByte: index - 1 ofObject: rcvr)]
			ifFalse: "ByteArray"
			[^ self integerObjectOf: (self fetchByte: index - 1 ofObject: rcvr)]].

	self primitiveFail
]

{ #category : #'array and stream primitive support' }
Interpreter >> commonVariable: rcvr at: index put: value cacheIndex: atIx [
	"This code assumes the reciever has been identified at location atIx in the atCache."
	| stSize fmt fixedFields valToPut |
	self inline: true.

	stSize _ atCache at: atIx+AtCacheSize.
	((self cCoerce: index to: 'usqInt ') >= 1
		and: [(self cCoerce: index to: 'usqInt ') <= (self cCoerce: stSize to: 'usqInt ')])
	ifTrue:
		[fmt _ atCache at: atIx+AtCacheFmt.
		fmt <= 4 ifTrue:
			[fixedFields _ atCache at: atIx+AtCacheFixedFields.
			^ self storePointer: index + fixedFields - 1 ofObject: rcvr withValue: value].
		fmt < 8 ifTrue:  "Bitmap"
			[valToPut _ self positive32BitValueOf: value.
			successFlag ifTrue: [self storeLong32: index - 1 ofObject: rcvr withValue: valToPut].
			^ nil].
		fmt >= 16  "Note fmt >= 16 is an artificial flag for strings"
			ifTrue: [valToPut _ self asciiOfCharacter: value.
					successFlag ifFalse: [^ nil]]
			ifFalse: [valToPut _ value].
		(self isIntegerObject: valToPut) ifTrue:
			[valToPut _ self integerValueOf: valToPut.
			((valToPut >= 0) and: [valToPut <= 255]) ifFalse: [^ self primitiveFail].
			^ self storeByte: index - 1 ofObject: rcvr withValue: valToPut]].

	self primitiveFail
]

{ #category : #'array and stream primitive support' }
Interpreter >> commonVariableInternal: rcvr at: index cacheIndex: atIx [ 
	"This code assumes the reciever has been identified at location atIx in the atCache."
	| stSize fmt fixedFields result |
	self inline: true.

	stSize _ atCache at: atIx+AtCacheSize.
	((self cCoerce: index to: 'usqInt ') >= 1
		and: [(self cCoerce: index to: 'usqInt ') <= (self cCoerce: stSize to: 'usqInt ')])
	ifTrue:
		[fmt _ atCache at: atIx+AtCacheFmt.
		fmt <= 4 ifTrue:
			[fixedFields _ atCache at: atIx+AtCacheFixedFields.
			^ self fetchPointer: index + fixedFields - 1 ofObject: rcvr].
		fmt < 8 ifTrue:  "Bitmap"
			[result _ self fetchLong32: index - 1 ofObject: rcvr.
			self externalizeIPandSP.
			result _ self positive32BitIntegerFor: result.
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
	self inline: true.
	compilerInitialized ifTrue: [self compilerFlushCache: aCompiledMethod]
]

{ #category : #'compiler support' }
Interpreter >> compilerMapFrom: memStart to: memEnd [
	^self cCode: 'compilerHooks[4](memStart, memEnd)'
]

{ #category : #'compiler support' }
Interpreter >> compilerMapHookFrom: memStart to: memEnd [
	self inline: true.
	compilerInitialized ifTrue: [self compilerMapFrom: memStart to: memEnd]
]

{ #category : #'compiler support' }
Interpreter >> compilerMark [
	^self cCode: 'compilerHooks[9]()'
]

{ #category : #'compiler support' }
Interpreter >> compilerMarkHook [
	self inline: true.
	compilerInitialized ifTrue: [self compilerMark]
]

{ #category : #'compiler support' }
Interpreter >> compilerPostGC [
	^self cCode: 'compilerHooks[5]()'
]

{ #category : #'compiler support' }
Interpreter >> compilerPostGCHook [
	self inline: true.
	compilerInitialized ifTrue: [self compilerPostGC]
]

{ #category : #'compiler support' }
Interpreter >> compilerPostSnapshot [
	^self cCode: 'compilerHooks[8]()'
]

{ #category : #'compiler support' }
Interpreter >> compilerPostSnapshotHook [
	self inline: true.
	compilerInitialized ifTrue: [self compilerPostSnapshot]
]

{ #category : #'compiler support' }
Interpreter >> compilerPreGC: fullGCFlag [
	^self cCode: 'compilerHooks[3](fullGCFlag)'
]

{ #category : #'compiler support' }
Interpreter >> compilerPreGCHook: fullGCFlag [
	self inline: true.
	compilerInitialized ifTrue: [self compilerPreGC: fullGCFlag]
]

{ #category : #'compiler support' }
Interpreter >> compilerPreSnapshot [
	^self cCode: 'compilerHooks[7]()'
]

{ #category : #'compiler support' }
Interpreter >> compilerPreSnapshotHook [
	self inline: true.
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
	self inline: true.
	compilerInitialized ifTrue: [self compilerProcessChange]
]

{ #category : #'compiler support' }
Interpreter >> compilerTranslateMethod [
	^self cCode: 'compilerHooks[1]()'
]

{ #category : #'compiler support' }
Interpreter >> compilerTranslateMethodHook [
	self inline: true.
	^compilerInitialized and: [self compilerTranslateMethod]
]

{ #category : #contexts }
Interpreter >> context: thisCntx hasSender: aContext [ 
	"Does thisCntx have aContext in its sender chain?"
	| s nilOop |
	self inline: true.
	thisCntx == aContext ifTrue: [^false].
	nilOop _ nilObj.
	s _ self fetchPointer: SenderIndex ofObject: thisCntx.
	[s == nilOop]
		whileFalse: [s == aContext ifTrue: [^true].
			s _ self fetchPointer: SenderIndex ofObject: s].
	^false
]

{ #category : #'bitblt support' }
Interpreter >> copyBits [
	"This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin_copyBits
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided"

	| fn |
	self var: #fn type: 'void *'.
	fn _ self ioLoadFunction: 'copyBits' From: 'BitBltPlugin'.
	fn = 0 ifTrue: [^self primitiveFail].
	^self cCode: '((sqInt (*)(void))fn)()'
]

{ #category : #'bitblt support' }
Interpreter >> copyBitsFrom: x0 to: x1 at: y [
	"This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin_copyBitsFrom:to:at:
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided"

	| fn |
	self var: #fn type: 'void *'.
	fn _ self ioLoadFunction: 'copyBitsFromtoat' From: 'BitBltPlugin'.
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
	extraSize _ self extraHeaderBytes: oop.
	bodySize _ self sizeBitsOf: oop.
	(lastSeg + extraSize + bodySize) >= stopAddr
		ifTrue: [^ self primitiveFail].
	self transfer: extraSize + bodySize // BytesPerWord  "wordCount"
		from: oop - extraSize
		to: lastSeg+BytesPerWord.

	"Clear root and mark bits of all headers copied into the segment"
	hdrAddr _ lastSeg+BytesPerWord + extraSize.
	self longAt: hdrAddr put: ((self longAt: hdrAddr) bitAnd: AllButRootBit - MarkBit).

	self forward: oop to: (lastSeg+BytesPerWord + extraSize - segmentWordArray)
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
	argumentArray _ self instantiateClass: (self splObj: ClassArray) indexableSize: argumentCount.
	"remap argumentArray in case GC happens during allocation"
	self pushRemappableOop: argumentArray.
	message _ self instantiateClass: (self splObj: ClassMessage) indexableSize: 0.
	argumentArray _ self popRemappableOop.
	lookupClass _ self popRemappableOop.
	self beRootIfOld: argumentArray.

	compilerInitialized
		ifTrue: [self compilerCreateActualMessage: message storingArgs: argumentArray]
		ifFalse: [self transfer: argumentCount from: stackPointer - (argumentCount - 1 * BytesPerWord) to: argumentArray + BaseHeaderSize.
			self pop: argumentCount thenPush: message].

	argumentCount _ 1.
	self storePointer: MessageSelectorIndex ofObject: message withValue: messageSelector.
	self storePointer: MessageArgumentsIndex ofObject: message withValue: argumentArray.
	(self lastPointerOf: message) >= (MessageLookupClassIndex * BytesPerWord + BaseHeaderSize)
		ifTrue: ["Only store lookupClass if message has 3 fields (old images don't)"
			self storePointer: MessageLookupClassIndex ofObject: message withValue: lookupClass]
]

{ #category : #'compiler support' }
Interpreter >> disableCompiler [
	compilerInitialized _ false
]

{ #category : #'message sending' }
Interpreter >> dispatchFunctionPointer: aFunctionPointer [

	self var: #aFunctionPointer type: 'void *'.
	self cCode: '((void (*)(void))aFunctionPointer)()'
			inSmalltalk: [self error: 'my simulator should simulate me']
]

{ #category : #'message sending' }
Interpreter >> dispatchFunctionPointerOn: primIdx in: primTable [
	"Call the primitive at index primIdx in the primitiveTable."

	self var: #primTable declareC: 'void *primTable[]'.
	^self dispatchFunctionPointer: (primTable at: primIdx)
]

{ #category : #'I/O primitives' }
Interpreter >> displayBitsOf: aForm Left: l Top: t Right: r Bottom: b [
	"Repaint the portion of the Smalltalk screen bounded by the affected rectangle. Used to synchronize the screen after a Bitblt to the Smalltalk Display object."

	| displayObj dispBits w h dispBitsIndex d left right top bottom surfaceHandle |
	displayObj _ self splObj: TheDisplay.
	aForm = displayObj ifFalse: [^ nil].
	self success: ((self isPointers: displayObj) and: [(self lengthOf: displayObj) >= 4]).
	successFlag ifTrue: [
		dispBits _ self fetchPointer: 0 ofObject: displayObj.
		w _ self fetchInteger: 1 ofObject: displayObj.
		h _ self fetchInteger: 2 ofObject: displayObj.
		d _ self fetchInteger: 3 ofObject: displayObj.
	].
	l < 0 ifTrue:[left _ 0] ifFalse: [left _ l].
	r > w ifTrue: [right _ w] ifFalse: [right _ r].
	t < 0 ifTrue: [top _ 0] ifFalse: [top _ t].
	b > h ifTrue: [bottom _ h] ifFalse: [bottom _ b].
	((left <= right) and: [top <= bottom]) ifFalse: [^nil].
	successFlag ifTrue: [
		(self isIntegerObject: dispBits) ifTrue: [
			surfaceHandle _ self integerValueOf: dispBits.
			showSurfaceFn = 0 ifTrue: [
				showSurfaceFn _ self ioLoadFunction: 'ioShowSurface' From: 'SurfacePlugin'.
				showSurfaceFn = 0 ifTrue: [^self success: false]].
			self cCode:'((sqInt (*)(sqInt, sqInt, sqInt, sqInt, sqInt))showSurfaceFn)(surfaceHandle, left, top, right-left, bottom-top)'.
		] ifFalse: [
			dispBitsIndex _ dispBits + BaseHeaderSize.  "index in memory byte array"
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
		ifTrue: [integerRcvr _ self integerValueOf: rcvr.
				integerArg _ self integerValueOf: arg.
				self success: integerArg ~= 0]
		ifFalse: [self primitiveFail].
	successFlag ifFalse: [^ 1 "fail"].

	integerRcvr > 0
		ifTrue: [integerArg > 0
					ifTrue: [result _ integerRcvr // integerArg]
					ifFalse: ["round negative result toward negative infinity"
							posArg _ 0 - integerArg.
							result _ 0 - ((integerRcvr + (posArg - 1)) // posArg)]]
		ifFalse: [posRcvr _ 0 - integerRcvr.
				integerArg > 0
					ifTrue: ["round negative result toward negative infinity"
							result _ 0 - ((posRcvr + (integerArg - 1)) // integerArg)]
					ifFalse: [posArg _ 0 - integerArg.
							result _ posRcvr // posArg]].
	self success: (self isIntegerValue: result).
	^ result
]

{ #category : #'arithmetic primitive support' }
Interpreter >> doPrimitiveMod: rcvr by: arg [
	| integerResult integerRcvr integerArg |
	(self areIntegers: rcvr and: arg)
		ifTrue: [integerRcvr _ self integerValueOf: rcvr.
				integerArg _ self integerValueOf: arg.
				self success: integerArg ~= 0]
		ifFalse: [self primitiveFail].
	successFlag ifFalse: [^ 1 "fail"].

	integerResult _ integerRcvr \\ integerArg.

	"ensure that the result has the same sign as the integerArg"
	integerArg < 0
		ifTrue: [integerResult > 0
			ifTrue: [integerResult _ integerResult + integerArg]]
		ifFalse: [integerResult < 0
			ifTrue: [integerResult _ integerResult + integerArg]].
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
	byte2 _ self fetchByte.
	byte3 _ self fetchByte.
	opType _ byte2 >> 5.
	opType = 0 ifTrue: [messageSelector _ self literal: byte3.
			argumentCount _ byte2 bitAnd: 31.
			^ self normalSend].
	opType = 1 ifTrue: [messageSelector _ self literal: byte3.
			argumentCount _ byte2 bitAnd: 31.
			^ self superclassSend].
	self fetchNextBytecode.
	opType = 2 ifTrue: [^ self pushReceiverVariable: byte3].
	opType = 3 ifTrue: [^ self pushLiteralConstant: byte3].
	opType = 4 ifTrue: [^ self pushLiteralVariable: byte3].
	opType = 5 ifTrue: [top _ self internalStackTop.
			^ self storePointer: byte3 ofObject: receiver withValue: top].
	opType = 6
		ifTrue: [top _ self internalStackTop.
			self internalPop: 1.
			^ self storePointer: byte3 ofObject: receiver withValue: top].
	opType = 7
		ifTrue: [top _ self internalStackTop.
			^ self storePointer: ValueIndex ofObject: (self literal: byte3) withValue: top]
]

{ #category : #initialization }
Interpreter >> dummyReferToProxy [
	self inline: false.
	interpreterProxy _ interpreterProxy
]

{ #category : #'stack bytecodes' }
Interpreter >> duplicateTopBytecode [

	self fetchNextBytecode.
	self internalPush: self internalStackTop.

]

{ #category : #'compiler support' }
Interpreter >> enableCompiler [
	"Calling this before loading the compiler will provoke a nullCompilerHook error"

	compilerInitialized _ true
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
Interpreter >> experimentalBytecode [
	"Note: This bytecode is not currently generated by the compiler."
	"This range of six bytecodes can replace the pushTemporaryVariable[0..5] bytecode at the beginning of a sequence of either the form:
		pushTemp
		pushTemp | pushConstantOne | pushLiteralConstant
		<=
		longJumpIfFalse
or the form:
		pushTemp
		pushTemp | pushConstantOne | pushLiteralConstant
		+
		popIntoTemp (optional)

If two values pushed are not small integers, this bytecode acts like the pushTemp bytecode it replaces. However, if they are small integers, then the given arithmetic or comparison operation is performed. The result of that operation is either pushed onto the stack or, if one of the expected bytecodes follows it, then that bytecode is performed immediately. In such cases, the entire four instruction sequence is performed without doing any stack operations."

	| arg1 byte2 byte3 byte4 arg1Val arg2Val result offset |
	arg1 _ self temporary: currentBytecode - 138.
	byte2 _ self byteAtPointer: localIP + 1.  "fetch ahead"
	byte3 _ self byteAtPointer: localIP + 2.  "fetch ahead"
	byte4 _ self byteAtPointer: localIP + 3.  "fetch ahead"

	"check first arg"
	(self isIntegerObject: arg1) ifTrue: [
		arg1Val _ self integerValueOf: arg1.
	] ifFalse: [
		self fetchNextBytecode.
		^ self internalPush: arg1.  "abort; first arg is not an integer"
	].

	"get and check second arg"
	byte2 < 32 ifTrue: [
		arg2Val _ self temporary: (byte2 bitAnd: 16rF).
		(self isIntegerObject: arg2Val) ifTrue: [
			arg2Val _ self integerValueOf: arg2Val.
		] ifFalse: [
			self fetchNextBytecode.
			^ self internalPush: arg1.  "abort; second arg is not an integer"
		].
	] ifFalse: [
		byte2 > 64 ifTrue: [
			arg2Val _ 1.
		] ifFalse: [
			arg2Val _ self literal: (byte2 bitAnd: 16r1F).
			(self isIntegerObject: arg2Val) ifTrue: [
				arg2Val _ self integerValueOf: arg2Val.
			] ifFalse: [
				self fetchNextBytecode.
				^ self internalPush: arg1.  "abort; second arg is not an integer"
			].
		].
	].

	byte3 < 178 ifTrue: [
		"do addition, possibly followed by a storeAndPopTemp"
		result _ arg1Val + arg2Val.
		(self isIntegerValue: result) ifTrue: [
			((byte4 > 103) and: [byte4 < 112]) ifTrue: [
				"next instruction is a storeAndPopTemp"
				localIP _ localIP + 3.
				self storePointerUnchecked: (byte4 bitAnd: 7) + TempFrameStart
					ofObject: localHomeContext
					withValue: (self integerObjectOf: result).
			] ifFalse: [
				localIP _ localIP + 2.
				self internalPush: (self integerObjectOf: result).
			].
		] ifFalse: [
			self fetchNextBytecode.
			^ self internalPush: arg1.  "abort; result is not an integer"
		].
	] ifFalse: [
		"do comparison operation, followed by a longJumpIfFalse"
		offset _ self byteAtPointer: localIP + 4.
		arg1Val <= arg2Val
			ifTrue: [localIP _ localIP + 3 + 1]  "jump not taken; skip extra instruction byte"
			ifFalse: [localIP _ localIP + 3 + 1 + offset].
			self fetchNextBytecode.
	].

]

{ #category : #'stack bytecodes' }
Interpreter >> extendedPushBytecode [

	| descriptor variableType variableIndex |
	descriptor _ self fetchByte.
	self fetchNextBytecode.
	variableType _ (descriptor >> 6) bitAnd: 16r3.
	variableIndex _ descriptor bitAnd: 16r3F.
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
	self inline: true.
	descriptor _ self fetchByte.
	self fetchNextBytecode.
	variableType _ descriptor >> 6 bitAnd: 3.
	variableIndex _ descriptor bitAnd: 63.
	variableType = 0
		ifTrue: [^ self storePointer: variableIndex ofObject: receiver withValue: self internalStackTop].
	variableType = 1
		ifTrue: [^ self storePointerUnchecked: variableIndex + TempFrameStart ofObject: localHomeContext withValue: self internalStackTop].
	variableType = 2
		ifTrue: [self error: 'illegal store'].
	variableType = 3
		ifTrue: [association _ self literal: variableIndex.
			^ self storePointer: ValueIndex ofObject: association withValue: self internalStackTop]
]

{ #category : #utilities }
Interpreter >> externalizeIPandSP [
	"Copy the local instruction and stack pointer to global variables for use in primitives and other functions outside the interpret loop."

	instructionPointer _ self oopForPointer: localIP.
	stackPointer _ self oopForPointer: localSP.
	theHomeContext _ localHomeContext.

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
	self returnTypeC: 'void *'.
	arrayOop _ self fetchPointer: fieldIndex ofObject: objectPointer.
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
	self inline: true.
	tmp _ self fetchPointer: MethodIndex ofObject: activeCntx.
	(self isIntegerObject: tmp)
		ifTrue: ["if the MethodIndex field is an integer, activeCntx is a block context"
			tmp _ self fetchPointer: HomeIndex ofObject: activeCntx.
			tmp < youngStart ifTrue: [self beRootIfOld: tmp]]
		ifFalse: ["otherwise, it is a method context and is its own home context "
			tmp _ activeCntx].
	theHomeContext _ tmp.
	receiver _ self fetchPointer: ReceiverIndex ofObject: tmp.
	method _ self fetchPointer: MethodIndex ofObject: tmp.

	"the instruction pointer is a pointer variable equal to 
	method oop + ip + BaseHeaderSize 
	-1 for 0-based addressing of fetchByte 
	-1 because it gets incremented BEFORE fetching currentByte "
	tmp _ self quickFetchInteger: InstructionPointerIndex ofObject: activeCntx.
	instructionPointer _ method + tmp + BaseHeaderSize - 2.

	"the stack pointer is a pointer variable also..."
	tmp _ self quickFetchInteger: StackPointerIndex ofObject: activeCntx.
	stackPointer _ activeCntx + BaseHeaderSize + (TempFrameStart + tmp - 1 * BytesPerWord)
]

{ #category : #utilities }
Interpreter >> fetchFloat: fieldIndex ofObject: objectPointer [
	"Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float."
	"Note: May be called by translated primitive code."

	| floatOop |
	self returnTypeC: 'double'.
	floatOop _ self fetchPointer: fieldIndex ofObject: objectPointer.
	^ self floatValueOf: floatOop
]

{ #category : #utilities }
Interpreter >> fetchInteger: fieldIndex ofObject: objectPointer [
	"Note: May be called by translated primitive code."

	| intOop |
	self inline: false.
	intOop _ self fetchPointer: fieldIndex ofObject: objectPointer.
	^self checkedIntegerValueOf: intOop
]

{ #category : #utilities }
Interpreter >> fetchIntegerOrTruncFloat: fieldIndex ofObject: objectPointer [
	"Return the integer value of the given field of the given object. If the field contains a Float, truncate it and return its integral part. Fail if the given field does not contain a small integer or Float, or if the truncated Float is out of the range of small integers."
	"Note: May be called by translated primitive code."

	| intOrFloat floatVal frac trunc |
	self inline: false.
	self var: #floatVal type: 'double '.
	self var: #frac type: 'double '.
	self var: #trunc type: 'double '.

	intOrFloat _ self fetchPointer: fieldIndex ofObject: objectPointer.
	(self isIntegerObject: intOrFloat) ifTrue: [^ self integerValueOf: intOrFloat].
	self assertClassOf: intOrFloat is: (self splObj: ClassFloat).
	successFlag ifTrue: [
		self cCode: '' inSmalltalk: [floatVal _ Float new: 2].
		self fetchFloatAt: intOrFloat + BaseHeaderSize into: floatVal.
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

	currentBytecode _ self fetchByte.

]

{ #category : #contexts }
Interpreter >> fetchStackPointerOf: aContext [
	"Return the stackPointer of a Context or BlockContext."
	| sp |
	self inline: true.
	sp _ self fetchPointer: StackPointerIndex ofObject: aContext.
	(self isIntegerObject: sp) ifFalse: [^0].
	^self integerValueOf: sp
]

{ #category : #'debug support' }
Interpreter >> findClassOfMethod: meth forReceiver: rcvr [

	| currClass classDict classDictSize methodArray i done |
	currClass _ self fetchClassOf: rcvr.
	done _ false.
	[done] whileFalse: [
		classDict _ self fetchPointer: MessageDictionaryIndex ofObject: currClass.
		classDictSize _ self fetchWordLengthOf: classDict.
		methodArray _ self fetchPointer: MethodArrayIndex ofObject: classDict.
		i _ 0.
		[i < (classDictSize - SelectorStart)] whileTrue: [
			meth = (self fetchPointer: i ofObject: methodArray) ifTrue: [ ^currClass ].
			i _ i + 1.
		].
		currClass _ self fetchPointer: SuperclassIndex ofObject: currClass.
		done _ currClass = nilObj.
	].
	^self fetchClassOf: rcvr    "method not found in superclass chain"
]

{ #category : #'message sending' }
Interpreter >> findNewMethodInClass: class [ 
	"Find the compiled method to be run when the current 
	messageSelector is sent to the given class, setting the values 
	of 'newMethod' and 'primitiveIndex'."
	| ok |
	self inline: false.
	ok _ self lookupInMethodCacheSel: messageSelector class: class.
	ok
		ifFalse: ["entry was not found in the cache; look it up the hard way "
			self lookupMethodInClass: class.
			lkupClass _ class.
			self addNewMethodToCache]
]

{ #category : #'plugin support' }
Interpreter >> findObsoleteNamedPrimitive: functionName length: functionLength [
	"Search the obsolete named primitive table for the given function.
	Return the index if it's found, -1 otherwise."
	| entry index chIndex |
	self var: #functionName type:'char *'.
	self var: #entry type:'const char *'.
	index _ 0.
	[true] whileTrue:[
		entry _ self
			cCode: 'obsoleteNamedPrimitiveTable[index][0]'
			inSmalltalk: [ (CArrayAccessor on: (obsoleteNamedPrimitiveTable at: index)) at: 0 ].
		entry == nil ifTrue:[^-1]. "at end of table"
		self cCode: '' inSmalltalk: [ entry _ CArrayAccessor on: entry ].
		"Compare entry with functionName"
		chIndex _ 0.
		[(entry at: chIndex) = (self cCode: 'functionName[chIndex]'
								inSmalltalk: [self byteAtPointer: functionName + chIndex]) 
			and:[chIndex < functionLength]] whileTrue:[chIndex _ chIndex + 1].
		(chIndex = functionLength and:[(entry at: chIndex) = 0]) 
			ifTrue:[^index]. "match"
		index _ index + 1.
	].
]

{ #category : #'debug support' }
Interpreter >> findSelectorOfMethod: meth forReceiver: rcvr [

	| currClass done classDict classDictSize methodArray i |
	currClass _ self fetchClassOf: rcvr.
	done _ false.
	[done] whileFalse: [
		classDict _ self fetchPointer: MessageDictionaryIndex ofObject: currClass.
		classDictSize _ self fetchWordLengthOf: classDict.
		methodArray _ self fetchPointer: MethodArrayIndex ofObject: classDict.
		i _ 0.
		[i <= (classDictSize - SelectorStart)] whileTrue: [
			meth = (self fetchPointer: i ofObject: methodArray) ifTrue: [
				^(self fetchPointer: i + SelectorStart ofObject: classDict)
			].
			i _ i + 1.
		].
		currClass _ self fetchPointer: SuperclassIndex ofObject: currClass.
		done _ currClass = nilObj.
	].
	^ nilObj    "method not found in superclass chain"
]

{ #category : #'plugin support' }
Interpreter >> firstFixedField: oop [

	self returnTypeC: 'void *'.
	^ self pointerForOop: oop + BaseHeaderSize
]

{ #category : #'plugin support' }
Interpreter >> firstIndexableField: oop [
	"NOTE: copied in InterpreterSimulator, so please duplicate any changes"

	| hdr fmt totalLength fixedFields |
	self returnTypeC: 'void *'.
	hdr _ self baseHeader: oop.
	fmt _ (hdr >> 8) bitAnd: 16rF.
	totalLength _ self lengthOf: oop baseHeader: hdr format: fmt.
	fixedFields _ self fixedFieldsOf: oop format: fmt length: totalLength.
	fmt < 8 ifTrue:
		[fmt = 6 ifTrue:
			["32 bit field objects"
			^ self pointerForOop: oop + BaseHeaderSize + (fixedFields << 2)].
		"full word objects (pointer or bits)"
		^ self pointerForOop: oop + BaseHeaderSize + (fixedFields << ShiftForWord)]
	ifFalse:
		["Byte objects"
		^ self pointerForOop: oop + BaseHeaderSize + fixedFields]
]

{ #category : #'object format' }
Interpreter >> fixedFieldsOf: oop format: fmt length: wordLength [
"
	NOTE: This code supports the backward-compatible extension to 8 bits of instSize.
	When we revise the image format, it should become...
	^ (classFormat >> 2 bitAnd: 16rFF) - 1
"
	| class classFormat |
	self inline: true.
	((fmt > 4) or: [fmt = 2]) ifTrue: [^ 0].  "indexable fields only"
	fmt < 2 ifTrue: [^ wordLength].  "fixed fields only (zero or more)"
	
	"fmt = 3 or 4: mixture of fixed and indexable fields, so must look at class format word"
	class _ self fetchClassOf: oop.
	classFormat _ self formatOfClass: class.
	^ (classFormat >> 11 bitAnd: 16rC0) + (classFormat >> 2 bitAnd: 16r3F) - 1

]

{ #category : #'object format' }
Interpreter >> floatObjectOf: aFloat [
	| newFloatObj |
self flag: #Dan.
	self var: #aFloat type: 'double '.
	newFloatObj _ self instantiateSmallClass: (self splObj: ClassFloat) sizeInBytes: 8+BaseHeaderSize.
	self storeFloatAt: newFloatObj + BaseHeaderSize from: aFloat.
	^ newFloatObj.

]

{ #category : #utilities }
Interpreter >> floatValueOf: oop [
	"Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float."
	"Note: May be called by translated primitive code."

	| result |
	self flag: #Dan.  "None of the float stuff has been converted for 64 bits"
	self returnTypeC: 'double'.
	self var: #result type: 'double '.
	self assertClassOf: oop is: (self splObj: ClassFloat).
	successFlag
		ifTrue: [self cCode: '' inSmalltalk: [result _ Float new: 2].
				self fetchFloatAt: oop + BaseHeaderSize into: result]
		ifFalse: [result _ 0.0].
	^ result
]

{ #category : #'plugin primitive support' }
Interpreter >> flushExternalPrimitiveOf: methodPtr [
	"methodPtr is a CompiledMethod containing an external primitive. Flush the function address and session ID of the CM"
	| lit |
	(self literalCountOf: methodPtr) > 0 ifFalse:[^nil]. "Something's broken"
	lit _ self literal: 0 ofMethod: methodPtr.
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
	oop _ self firstObject.
	[oop < endOfMemory]
		whileTrue: [(self isFreeObject: oop)
				ifFalse: [(self isCompiledMethod: oop)
						ifTrue: ["This is a compiled method"
							primIdx _ self primitiveIndexOf: oop.
							primIdx = PrimitiveExternalCallIndex
								ifTrue: ["It's primitiveExternalCall"
									self flushExternalPrimitiveOf: oop]]].
			oop _ self objectAfter: oop].
	self flushMethodCache.
	self flushObsoleteIndexedPrimitives.
	self flushExternalPrimitiveTable
]

{ #category : #'method lookup cache' }
Interpreter >> flushMethodCache [
	"Flush the method cache. The method cache is flushed on every programming change and garbage collect."

	1 to: MethodCacheSize do: [ :i | methodCache at: i put: 0 ].
	1 to: AtCacheTotalSize do: [ :i | atCache at: i put: 0 ].

]

{ #category : #'method lookup cache' }
Interpreter >> flushMethodCacheFrom: memStart to: memEnd [ 
	"Flush entries in the method cache only if the oop address is within the given memory range. 
	This reduces overagressive cache clearing. Note the AtCache is fully flushed, 70% of the time 
	cache entries live in newspace, new objects die young"
	| probe |
	probe _ 0.
	1 to: MethodCacheEntries do: [:i | 
			(methodCache at: probe + MethodCacheSelector) = 0
				ifFalse: [(((((methodCache at: probe + MethodCacheSelector) >= memStart
										and: [(methodCache at: probe + MethodCacheSelector) < memEnd])
									or: [(methodCache at: probe + MethodCacheClass) >= memStart
											and: [(methodCache at: probe + MethodCacheClass) < memEnd]])
								or: [(methodCache at: probe + MethodCacheMethod) >= memStart
										and: [(methodCache at: probe + MethodCacheMethod) < memEnd]])
							or: [(methodCache at: probe + MethodCacheNative) >= memStart
									and: [(methodCache at: probe + MethodCacheNative) < memEnd]])
						ifTrue: [methodCache at: probe + MethodCacheSelector put: 0]].
			probe _ probe + MethodCacheEntrySize].
	1 to: AtCacheTotalSize do: [:i | atCache at: i put: 0]
]

{ #category : #'plugin primitive support' }
Interpreter >> flushObsoleteIndexedPrimitives [
	"Flush the pointers in the obsolete indexed primitive table"
	1 to: MaxPrimitiveIndex
		do: [:i | (obsoleteIndexedPrimitiveTable at: i) at: 2 put: nil]
]

{ #category : #processes }
Interpreter >> forceInterruptCheck [
	"force an interrupt check ASAP"
	interruptCheckCounter _ -1000
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
	displayObj _ self splObj: TheDisplay.
	((self isPointers: displayObj) and: [(self lengthOf: displayObj) >= 4]) ifTrue: [
		w _ self fetchInteger: 1 ofObject: displayObj.
		h _ self fetchInteger: 2 ofObject: displayObj.
		self displayBitsOf: displayObj Left: 0 Top: 0 Right: w Bottom: h.
		self ioForceDisplayUpdate].

]

{ #category : #'method lookup cache' }
Interpreter >> functionPointerFor: primIdx inClass: theClass [
	"Find an actual function pointer for this primitiveIndex.  This is an
	opportunity to specialise the prim for the relevant class (format for
	example).  Default for now is simply the entry in the base primitiveTable."

	self returnTypeC: 'void *'.
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
	self var: #aFile type: 'sqImageFile '.
	w _ 0.
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

{ #category : #'plugin support' }
Interpreter >> getThisSessionID [
	"return the global session ID value"
	self inline: false.
	^globalSessionID
]

{ #category : #'compiled methods' }
Interpreter >> headerOf: methodPointer [
	^self fetchPointer: HeaderIndex ofObject: methodPointer
]

{ #category : #'image save/restore' }
Interpreter >> imageFormatVersion [
	"Return a magic constant that changes when the image format changes. Since the image reading code uses this to detect byte ordering, one must avoid version numbers that are invariant under byte reversal."

	BytesPerWord == 4
		ifTrue: [^6502]
		ifFalse: [^68000]
]

{ #category : #'image segment in/out' }
Interpreter >> imageSegmentVersion [
	| wholeWord |
	"a more complex version that tells both the word reversal and the endianness of the machine it came from.  Low half of word is 6502.  Top byte is top byte of #doesNotUnderstand: on this machine. ($d on the Mac or $s on the PC)"

	wholeWord _ self longAt: (self splObj: SelectorDoesNotUnderstand) + BaseHeaderSize.
		"first data word, 'does' "
	^ self imageFormatVersion bitOr: (wholeWord bitAnd: 16rFF000000)
]

{ #category : #'plugin primitive support' }
Interpreter >> includesBehavior: aClass ThatOf: aSuperclass [
	"Return the equivalent of 
		aClass includesBehavior: aSuperclass.
	Note: written for efficiency and better inlining (only 1 temp)"
	| theClass |
	self inline: true.
	(((theClass _ aClass) = aSuperclass) "aClass == aSuperclass"
		or:[aSuperclass = nilObj]) "every class inherits from nil"
			ifTrue:[^true].
	[(theClass _ self superclassOf: theClass) = aSuperclass ifTrue:[^true].
	theClass ~= nilObj] whileTrue.
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

	compilerInitialized _ false
]

{ #category : #initialization }
Interpreter >> initialCleanup [
	"Images written by VMs earlier than 3.6/3.7 will wrongly have the root bit set on the active context. Besides clearing the root bit, we treat this as a marker that these images also lack a cleanup of external primitives (which has been introduced at the same time when the root bit problem was fixed). In this case, we merely flush them from here."

	((self longAt: activeContext) bitAnd: RootBit) = 0 ifTrue:[^nil]. "root bit is clean"
	"Clean root bit of activeContext"
	self longAt: activeContext put: ((self longAt: activeContext) bitAnd: AllButRootBit).
	"Clean external primitives"
	self flushExternalPrimitives.
]

{ #category : #initialization }
Interpreter >> initializeInterpreter: bytesToShift [ 
	"Initialize Interpreter state before starting execution of a new image."
	interpreterProxy _ self sqGetInterpreterProxy.
	self dummyReferToProxy.
	self initializeObjectMemory: bytesToShift.
	self initCompilerHooks.
	activeContext _ nilObj.
	theHomeContext _ nilObj.
	method _ nilObj.
	receiver _ nilObj.
	messageSelector _ nilObj.
	newMethod _ nilObj.
	methodClass _ nilObj.
	lkupClass _ nilObj.
	receiverClass _ nilObj.
	newNativeMethod _ nilObj.
	self flushMethodCache.
	self loadInitialContext.
	self initialCleanup.
	interruptCheckCounter _ 0.
	interruptCheckCounterFeedBackReset _ 1000.
	interruptChecksEveryNms _ 1.
	nextPollTick _ 0.
	nextWakeupTick _ 0.
	lastTick _ 0.
	interruptKeycode _ 2094. "cmd-. as used for Mac but no other OS"
	interruptPending _ false.
	semaphoresUseBufferA _ true.
	semaphoresToSignalCountA _ 0.
	semaphoresToSignalCountB _ 0.
	deferDisplayUpdates _ false.
	pendingFinalizationSignals _ 0.
	globalSessionID _ 0.
	[globalSessionID = 0]
		whileTrue: [globalSessionID _ self
						cCode: 'time(NULL) + ioMSecs()'
						inSmalltalk: [(Random new next * SmallInteger maxVal) asInteger]]
]

{ #category : #'array and stream primitives' }
Interpreter >> install: rcvr inAtCache: cache at: atIx string: stringy [
	"Install the oop of this object in the given cache (at or atPut), along with
	its size, format and fixedSize"
	| hdr fmt totalLength fixedFields |
	self var: #cache type: 'sqInt *'.

	hdr _ self baseHeader: rcvr.
	fmt _ (hdr >> 8) bitAnd: 16rF.
	(fmt = 3 and: [self isContextHeader: hdr]) ifTrue:
		["Contexts must not be put in the atCache, since their size is not constant"
		^ self primitiveFail].
	totalLength _ self lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields _ self fixedFieldsOf: rcvr format: fmt length: totalLength.

	cache at: atIx+AtCacheOop put: rcvr.
	stringy ifTrue: [cache at: atIx+AtCacheFmt put: fmt + 16]  "special flag for strings"
			ifFalse: [cache at: atIx+AtCacheFmt put: fmt].
	cache at: atIx+AtCacheFixedFields put: fixedFields.
	cache at: atIx+AtCacheSize put: totalLength - fixedFields.

]

{ #category : #'return bytecodes' }
Interpreter >> internalAboutToReturn: resultObj through: aContext [
	self inline: true.
	self internalPush: activeContext.
	self internalPush: resultObj.
	self internalPush: aContext.
	messageSelector _ self splObj: SelectorAboutToReturn.
	argumentCount _ 2.
	^self normalSend
]

{ #category : #'message sending' }
Interpreter >> internalActivateNewMethod [
	| methodHeader newContext tempCount argCount2 needsLarge where |
	self inline: true.

	methodHeader _ self headerOf: newMethod.
	needsLarge _ methodHeader bitAnd: LargeContextBit.
	(needsLarge = 0 and: [freeContexts ~= NilContext])
		ifTrue: [newContext _ freeContexts.
				freeContexts _ self fetchPointer: 0 ofObject: newContext]
		ifFalse: ["Slower call for large contexts or empty free list"
				self externalizeIPandSP.
				newContext _ self allocateOrRecycleContext: needsLarge.
				self internalizeIPandSP].
	tempCount _ (methodHeader >> 19) bitAnd: 16r3F.

	"Assume: newContext will be recorded as a root if necessary by the
	 call to newActiveContext: below, so we can use unchecked stores."
	where _   newContext + BaseHeaderSize.
	self longAt: where + (SenderIndex << ShiftForWord) put: activeContext.
	self longAt: where + (InstructionPointerIndex << ShiftForWord) put: (self integerObjectOf:
			(((LiteralStart + (self literalCountOfHeader: methodHeader)) * BytesPerWord) + 1)).
	self longAt: where + (StackPointerIndex << ShiftForWord) put: (self integerObjectOf: tempCount).
	self longAt: where + (MethodIndex << ShiftForWord) put: newMethod.

	"Copy the reciever and arguments..."
	argCount2 _ argumentCount.
	0 to: argCount2 do:
		[:i | self longAt: where + ((ReceiverIndex+i) << ShiftForWord) put: (self internalStackValue: argCount2-i)].

	"clear remaining temps to nil in case it has been recycled"
	methodHeader _ nilObj.  "methodHeader here used just as faster (register?) temp"
	argCount2+1+ReceiverIndex to: tempCount+ReceiverIndex do:
		[:i | self longAt: where + (i << ShiftForWord) put: methodHeader].

	self internalPop: argCount2 + 1.
	reclaimableContextCount _ reclaimableContextCount + 1.
	self internalNewActiveContext: newContext.
 
]

{ #category : #'return bytecodes' }
Interpreter >> internalCannotReturn: resultObj [
	self inline: true.
	self internalPush: activeContext.
	self internalPush: resultObj.
	messageSelector _ self splObj: SelectorCannotReturn.
	argumentCount _ 1.
	^ self normalSend
]

{ #category : #'message sending' }
Interpreter >> internalExecuteNewMethod [
	| localPrimIndex delta nArgs |
	self inline: true.
	localPrimIndex _ primitiveIndex.
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
							nArgs _ argumentCount.
							delta _ stackPointer - activeContext].
					successFlag _ true.
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
	self inline: true.
	tmp _ self fetchPointer: MethodIndex ofObject: activeCntx.
	(self isIntegerObject: tmp) ifTrue: [
		"if the MethodIndex field is an integer, activeCntx is a block context"
		tmp _ self fetchPointer: HomeIndex ofObject: activeCntx.
		(tmp < youngStart) ifTrue: [ self beRootIfOld: tmp ].
	] ifFalse: [
		"otherwise, it is a method context and is its own home context"
		tmp _ activeCntx.
	].
	localHomeContext _ tmp.
	receiver _ self fetchPointer: ReceiverIndex ofObject: tmp.
	method _ self fetchPointer: MethodIndex ofObject: tmp.

	"the instruction pointer is a pointer variable equal to
		method oop + ip + BaseHeaderSize
		  -1 for 0-based addressing of fetchByte
		  -1 because it gets incremented BEFORE fetching currentByte"
	tmp _ self quickFetchInteger: InstructionPointerIndex ofObject: activeCntx.
	localIP _ self pointerForOop: method + tmp + BaseHeaderSize - 2.

	"the stack pointer is a pointer variable also..."
	tmp _ self quickFetchInteger: StackPointerIndex ofObject: activeCntx.
	localSP _ self pointerForOop: activeCntx + BaseHeaderSize + ((TempFrameStart + tmp - 1) * BytesPerWord)
]

{ #category : #'message sending' }
Interpreter >> internalFindNewMethod [
	"Find the compiled method to be run when the current messageSelector is sent to the class 'lkupClass', setting the values of 'newMethod' and 'primitiveIndex'."
	| ok | 
	self inline: true.
	ok _ self lookupInMethodCacheSel: messageSelector class: lkupClass.
	ok ifFalse: [
		"entry was not found in the cache; look it up the hard way"
		self externalizeIPandSP.
		self lookupMethodInClass: lkupClass.
		self internalizeIPandSP.
		self addNewMethodToCache].

]

{ #category : #contexts }
Interpreter >> internalNewActiveContext: aContext [
	"The only difference between this method and newActiveContext: is that this method uses internal context registers."
	self inline: true.

	self internalStoreContextRegisters: activeContext.
	(aContext < youngStart) ifTrue: [ self beRootIfOld: aContext ].
	activeContext _ aContext.
	self internalFetchContextRegisters: aContext.
]

{ #category : #contexts }
Interpreter >> internalPop: nItems [

	localSP _ localSP - (nItems * BytesPerWord).
]

{ #category : #contexts }
Interpreter >> internalPop: nItems thenPush: oop [

	self longAtPointer: (localSP _ localSP - ((nItems - 1) * BytesPerWord)) put: oop.

]

{ #category : #'control primitives' }
Interpreter >> internalPrimitiveValue [
	| newContext blockArgumentCount initialIP |
	self inline: true.
	self sharedCodeNamed: 'commonPrimitiveValue' inCase: 201.
	successFlag _ true.
	newContext _ self internalStackValue: argumentCount.
	self assertClassOf: newContext is: (self splObj: ClassBlockContext).
	blockArgumentCount _ self argumentCountOfBlock: newContext.

	self success: (argumentCount = blockArgumentCount and: [(self fetchPointer: CallerIndex ofObject: newContext) = nilObj]).

	successFlag
		ifTrue: ["This code assumes argCount can only = 0 or 1"
			argumentCount = 1
				ifTrue: [self storePointer: TempFrameStart ofObject: newContext withValue: self internalStackTop].
			self internalPop: argumentCount + 1.
			"copy the initialIP value to the ip slot"
			initialIP _ self fetchPointer: InitialIPIndex ofObject: newContext.
			self storePointerUnchecked: InstructionPointerIndex ofObject: newContext withValue: initialIP.
			self storeStackPointerValue: argumentCount inContext: newContext.
			self storePointerUnchecked: CallerIndex ofObject: newContext withValue: activeContext.
			self internalNewActiveContext: newContext]
		ifFalse: [messageSelector _ self specialSelector: 25 + argumentCount.
			self normalSend]
]

{ #category : #contexts }
Interpreter >> internalPush: object [

	self longAtPointer: (localSP _ localSP + BytesPerWord) put: object.
]

{ #category : #processes }
Interpreter >> internalQuickCheckForInterrupts [
	"Internal version of quickCheckForInterrupts for use within jumps."

	self inline: true.
	((interruptCheckCounter _ interruptCheckCounter - 1) <= 0) ifTrue: [
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

	^ self longAtPointer: localSP - (offset * BytesPerWord)
]

{ #category : #contexts }
Interpreter >> internalStoreContextRegisters: activeCntx [
	"The only difference between this method and fetchContextRegisters: is that this method stores from the local IP and SP."

	"InstructionPointer is a pointer variable equal to
	method oop + ip + BaseHeaderSize
		-1 for 0-based addressing of fetchByte
		-1 because it gets incremented BEFORE fetching currentByte"

	self inline: true.
	self storePointerUnchecked: InstructionPointerIndex ofObject: activeCntx
		withValue: (self integerObjectOf: 
			((self oopForPointer: localIP) + 2 - (method + BaseHeaderSize))).
	self storePointerUnchecked: StackPointerIndex		  ofObject: activeCntx
		withValue: (self integerObjectOf:
			((((self oopForPointer: localSP) - (activeCntx + BaseHeaderSize)) >> ShiftForWord) - TempFrameStart + 1)).

]

{ #category : #utilities }
Interpreter >> internalizeIPandSP [
	"Copy the local instruction and stack pointer to local variables for rapid access within the interpret loop."

	localIP _ self pointerForOop: instructionPointer.
	localSP _ self pointerForOop: stackPointer.
	localHomeContext _ theHomeContext.

]

{ #category : #'interpreter shell' }
Interpreter >> interpret [
	"This is the main interpreter loop. It normally loops forever, fetching and executing bytecodes. When running in the context of a browser plugin VM, however, it must return control to the browser periodically. This should done only when the state of the currently running Squeak thread is safely stored in the object heap. Since this is the case at the moment that a check for interrupts is performed, that is when we return to the browser if it is time to do so. Interrupt checks happen quite frequently."

	"record entry time when running as a browser plug-in"
	self browserPluginInitialiseIfNeeded.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue: [self dispatchOn: currentBytecode in: BytecodeTable].
	localIP _ localIP - 1.  "undo the pre-increment of IP before returning"
	self externalizeIPandSP.

]

{ #category : #processes }
Interpreter >> interruptCheckForced [
	"was this interrupt check forced by outside code?"
	^interruptCheckCounter < -100
]

{ #category : #'plugin support' }
Interpreter >> ioFilename: aCharBuffer fromString: aFilenameString ofLength: filenameLength resolveAliases: aBoolean [
"the vm has to convert aFilenameString via any canonicalization and char-mapping and put the result in aCharBuffer.
Note the resolveAliases flag - this is an awful artefact of OSX and Apples demented alias handling. When opening a file, the flag must be  true, when closing or renaming it must be false. Sigh."
	self var: #aCharBuffer type: 'char *'.
	self var: #aFilenameString type: 'char *'.
	self cCode:'sqGetFilenameFromString(aCharBuffer, aFilenameString, filenameLength, aBoolean)'
		inSmalltalk:["this doesn't translate well in Smalltalk since we know how long strings are rather than considering them terminated by a 0 char. Do the best we can"
			aCharBuffer replaceFrom:1 to: filenameLength with: aFilenameString]
]

{ #category : #'plugin primitive support' }
Interpreter >> is: oop KindOf: className [
	"Support for external primitives."
	| oopClass |
	self var: #className type:'char *'.
	oopClass _ self fetchClassOf: oop.
	[oopClass == nilObj] whileFalse:[
		(self classNameOf: oopClass Is: className) ifTrue:[^true].
		oopClass _ self superclassOf: oopClass].
	^false
]

{ #category : #'plugin primitive support' }
Interpreter >> is: oop MemberOf: className [
	"Support for external primitives"
	| oopClass |
	self var: #className type:'char *'.
	oopClass _ self fetchClassOf: oop.
	^(self classNameOf: oopClass Is: className)
]

{ #category : #'plugin support' }
Interpreter >> isBigEnder [
	"Answer true (non-zero) if running on a big endian machine."
	| endianness anInt cString len i |
	self var: 'cString' type: 'char *'.
	self var: 'endianness' declareC: 'static sqInt endianness = -1'.
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
Interpreter >> isContext: oop header: hdr [
	"NOTE: anOop is assumed not to be an integer"
	| ccIndex theClass |
	self inline: true.
	ccIndex _ (hdr >> 12) bitAnd: 16r1F.
	ccIndex = 0
		ifTrue: [theClass _ (self classHeader: oop) bitAnd: AllButTypeMask]
		ifFalse: ["look up compact class"
				theClass _ self fetchPointer: ccIndex - 1 ofObject: (self splObj: CompactClasses)].
	^ theClass = (self splObj: ClassMethodContext) or: [theClass = (self splObj: ClassBlockContext)]

]

{ #category : #contexts }
Interpreter >> isContextHeader: aHeader [
	self inline: true.
	^ ((aHeader >> 12) bitAnd: 16r1F) = 13			"MethodContext"
		or: [((aHeader >> 12) bitAnd: 16r1F) = 14		"BlockContext"
		or: [((aHeader >> 12) bitAnd: 16r1F) = 4]]	"PseudoContext"
]

{ #category : #processes }
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
	self inline: true.
	header _ self baseHeader: aContext.
	(self isMethodContextHeader: header) ifFalse: [^false].
	meth _ self fetchPointer: MethodIndex ofObject: aContext.
	pIndex _ self primitiveIndexOf: meth.
	^pIndex == 199

]

{ #category : #'object format' }
Interpreter >> isIndexable: oop [
	^(self formatOf: oop) >= 2
]

{ #category : #contexts }
Interpreter >> isMethodContextHeader: aHeader [
	self inline: true.
	^ ((aHeader >> 12) bitAnd: 16r1F) = 14
]

{ #category : #'compiled methods' }
Interpreter >> isUnwindMarked: aContext [
	"Is this a MethodContext whose meth has a primitive number of 198?"
	| header meth pIndex |
	"NB: the use of a primitive number for marking the method is pretty grungy, but it is simple to use for a test sytem, not too expensive and we don't actually have the two spare method header bits we need. We can probably obtain them when the method format is changed
	NB 2: actually, the jitter will probably implement the prim to actually mark the volatile frame by changing the return function pointer."
	self inline: true.
	header _ self baseHeader: aContext.
	(self isMethodContextHeader: header) ifFalse: [^false].
	meth _ self fetchPointer: MethodIndex ofObject: aContext.
	pIndex _ self primitiveIndexOf: meth.
	^pIndex == 198

]

{ #category : #'jump bytecodes' }
Interpreter >> jump: offset [

	localIP _ localIP + offset + 1.
	currentBytecode _ self byteAtPointer: localIP.

]

{ #category : #'jump bytecodes' }
Interpreter >> jumplfFalseBy: offset [ 
	| boolean |
	boolean _ self internalStackTop.
	boolean = falseObj
		ifTrue: [self jump: offset]
		ifFalse: [boolean = trueObj
				ifFalse: [messageSelector _ self splObj: SelectorMustBeBoolean.
					argumentCount _ 0.
					^ self normalSend].
			self fetchNextBytecode].
	self internalPop: 1
]

{ #category : #'jump bytecodes' }
Interpreter >> jumplfTrueBy: offset [ 
	| boolean |
	boolean _ self internalStackTop.
	boolean = trueObj
		ifTrue: [self jump: offset]
		ifFalse: [boolean = falseObj
				ifFalse: [messageSelector _ self splObj: SelectorMustBeBoolean.
					argumentCount _ 0.
					^ self normalSend].
			self fetchNextBytecode].
	self internalPop: 1
]

{ #category : #'array and stream primitive support' }
Interpreter >> lengthOf: oop [
	"Return the number of indexable bytes or words in the given object. Assume the argument is not an integer. For a CompiledMethod, the size of the method header (in bytes) should be subtracted from the result."

	| header |
	self inline: true.
	header _ self baseHeader: oop.
	^ self lengthOf: oop baseHeader: header format: ((header >> 8) bitAnd: 16rF)
]

{ #category : #'array and stream primitive support' }
Interpreter >> lengthOf: oop baseHeader: hdr format: fmt [
	"Return the number of indexable bytes or words in the given object. Assume the given oop is not an integer. For a CompiledMethod, the size of the method header (in bytes) should be subtracted from the result of this method."

	| sz |
	self inline: true.
	(hdr bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ sz _ (self sizeHeader: oop) bitAnd: LongSizeMask ]
		ifFalse: [ sz _ (hdr bitAnd: SizeMask)].
	sz _ sz - (hdr bitAnd: Size4Bit).
	fmt <= 4
		ifTrue: [ ^ (sz - BaseHeaderSize) >> ShiftForWord "words"].
	fmt < 8
		ifTrue: [ ^ (sz - BaseHeaderSize) >> 2 "32-bit longs"]
		ifFalse: [ ^ (sz - BaseHeaderSize) - (fmt bitAnd: 3) "bytes"]
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
	Since BitBlt is now a plugin we need to look up BitBltPlugin_loadBitBltFrom
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided"
	| fn |
	self var: #fn type: 'void *'.
	fn _ self ioLoadFunction: 'loadBitBltFrom' From: 'BitBltPlugin'.
	fn = 0 ifTrue: [^self primitiveFail].
	^self cCode: '((sqInt (*)(sqInt))fn)(bb)'
]

{ #category : #utilities }
Interpreter >> loadFloatOrIntFrom: floatOrInt [
	"If floatOrInt is an integer, then convert it to a C double float and return it.
	If it is a Float, then load its value and return it.
	Otherwise fail -- ie return with successFlag set to false."

	self inline: true.
	self returnTypeC: 'double'.

	(self isIntegerObject: floatOrInt) ifTrue:
		[^ self cCode: '((double) (floatOrInt >> 1))'
				inSmalltalk: [(self integerValueOf: floatOrInt) asFloat]].
	(self fetchClassOfNonInt: floatOrInt) = (self splObj: ClassFloat)
		ifTrue: [^ self floatValueOf: floatOrInt].
	successFlag _ false
]

{ #category : #initialization }
Interpreter >> loadInitialContext [

	| sched proc |
	sched _ self fetchPointer: ValueIndex ofObject: (self splObj: SchedulerAssociation).
	proc _ self fetchPointer: ActiveProcessIndex ofObject: sched.
	activeContext _ self fetchPointer: SuspendedContextIndex ofObject: proc.
	(activeContext < youngStart) ifTrue: [ self beRootIfOld: activeContext ].
	self fetchContextRegisters: activeContext.
	reclaimableContextCount _ 0.
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
	offset _ (((currentBytecode bitAnd: 7) - 4) * 256) + self fetchByte.
	localIP _ localIP + offset.
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
	self inline: true.
	hash _ selector bitXor: class.  "shift drops two low-order zeros from addresses"

	probe _ hash bitAnd: MethodCacheMask.  "first probe"
	(((methodCache at: probe + MethodCacheSelector) = selector) and:
		 [(methodCache at: probe + MethodCacheClass) = class]) ifTrue:
			[newMethod _ methodCache at: probe + MethodCacheMethod.
			primitiveIndex _ methodCache at: probe + MethodCachePrim.
			newNativeMethod _ methodCache at: probe + MethodCacheNative.
			primitiveFunctionPointer _ self cCoerce: (methodCache at: probe + MethodCachePrimFunction) to: 'void *'.
			^ true	"found entry in cache; done"].

	probe _ (hash >> 1) bitAnd: MethodCacheMask.  "second probe"
	(((methodCache at: probe + MethodCacheSelector) = selector) and:
		 [(methodCache at: probe + MethodCacheClass) = class]) ifTrue:
			[newMethod _ methodCache at: probe + MethodCacheMethod.
			primitiveIndex _ methodCache at: probe + MethodCachePrim.
			newNativeMethod _ methodCache at: probe + MethodCacheNative.
			primitiveFunctionPointer _ self cCoerce: (methodCache at: probe + MethodCachePrimFunction) to: 'void *'.
			^ true	"found entry in cache; done"].

	probe _ (hash >> 2) bitAnd: MethodCacheMask.
	(((methodCache at: probe + MethodCacheSelector) = selector) and:
		 [(methodCache at: probe + MethodCacheClass) = class]) ifTrue:
			[newMethod _ methodCache at: probe + MethodCacheMethod.
			primitiveIndex _ methodCache at: probe + MethodCachePrim.
			newNativeMethod _ methodCache at: probe + MethodCacheNative.
			primitiveFunctionPointer _ self cCoerce: (methodCache at: probe + MethodCachePrimFunction) to: 'void *'.
			^ true	"found entry in cache; done"].

	^ false

]

{ #category : #'message sending' }
Interpreter >> lookupMethodInClass: class [
	| currentClass dictionary found rclass |
	self inline: false.

	currentClass _ class.
	[currentClass ~= nilObj]
		whileTrue:
		[dictionary _ self fetchPointer: MessageDictionaryIndex ofObject: currentClass.
		dictionary = nilObj ifTrue:
			["MethodDict pointer is nil (hopefully due a swapped out stub)
				-- raise exception #cannotInterpret:."
			self pushRemappableOop: currentClass.  "may cause GC!"
			self createActualMessageTo: class.
			currentClass _ self popRemappableOop.
			messageSelector _ self splObj: SelectorCannotInterpret.
			^ self lookupMethodInClass: (self superclassOf: currentClass)].
		found _ self lookupMethodInDictionary: dictionary.
		found ifTrue: [^ methodClass _ currentClass].
		currentClass _ self superclassOf: currentClass].

	"Could not find #doesNotUnderstand: -- unrecoverable error."
	messageSelector = (self splObj: SelectorDoesNotUnderstand) ifTrue:
		[self error: 'Recursive not understood error encountered'].

	"Cound not find a normal message -- raise exception #doesNotUnderstand:"
	self pushRemappableOop: class.  "may cause GC!"
	self createActualMessageTo: class.
	rclass _ self popRemappableOop.
	messageSelector _ self splObj: SelectorDoesNotUnderstand.
	^ self lookupMethodInClass: rclass
]

{ #category : #'message sending' }
Interpreter >> lookupMethodInDictionary: dictionary [ 
	"This method lookup tolerates integers as Dictionary keys to 
	support execution of images in which Symbols have been 
	compacted out"
	| length index mask wrapAround nextSelector methodArray |
	self inline: true.
	length _ self fetchWordLengthOf: dictionary.
	mask _ length - SelectorStart - 1.
	(self isIntegerObject: messageSelector)
		ifTrue: [index _ (mask bitAnd: (self integerValueOf: messageSelector)) + SelectorStart]
		ifFalse: [index _ (mask bitAnd: (self hashBitsOf: messageSelector)) + SelectorStart].

	"It is assumed that there are some nils in this dictionary, and search will 
	stop when one is encountered. However, if there are no nils, then wrapAround 
	will be detected the second time the loop gets to the end of the table."
	wrapAround _ false.
	[true]
		whileTrue: [nextSelector _ self fetchPointer: index ofObject: dictionary.
			nextSelector = nilObj ifTrue: [^ false].
			nextSelector = messageSelector
				ifTrue: [methodArray _ self fetchPointer: MethodArrayIndex ofObject: dictionary.
					newMethod _ self fetchPointer: index - SelectorStart ofObject: methodArray.
					"Check if newMethod is a CompiledMethod."
					(self isCompiledMethod: newMethod)
						ifTrue: [primitiveIndex _ self primitiveIndexOf: newMethod.
							primitiveIndex > MaxPrimitiveIndex
								ifTrue: ["If primitiveIndex is out of range, set to zero before putting in 
									cache. This is equiv to primFail, and avoids the need to check on 
									every send."
									primitiveIndex _ 0]]
						ifFalse: ["indicate that this is no compiled method - use primitiveInvokeObjectAsMethod"
							primitiveIndex _ 248].
					^ true].
			index _ index + 1.
			index = length
				ifTrue: [wrapAround
						ifTrue: [^ false].
					wrapAround _ true.
					index _ SelectorStart]]
]

{ #category : #utilities }
Interpreter >> makePointwithxValue: xValue yValue: yValue [
"make a Point xValue@yValue.
We know both will be integers so no value nor root checking is needed"
	| pointResult |
	pointResult _ self instantiateSmallClass: (self splObj: ClassPoint) sizeInBytes: 3*BytesPerWord.
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
	nilObj _ self remap: nilObj.
	falseObj _ self remap: falseObj.
	trueObj _ self remap: trueObj.
	specialObjectsOop _ self remap: specialObjectsOop.
	compilerInitialized
		ifFalse: [stackPointer _ stackPointer - activeContext. "*rel to active"
			activeContext _ self remap: activeContext.
			stackPointer _ stackPointer + activeContext. "*rel to active"
			theHomeContext _ self remap: theHomeContext].
	instructionPointer _ instructionPointer - method. "*rel to method"
	method _ self remap: method.
	instructionPointer _ instructionPointer + method. "*rel to method"
	receiver _ self remap: receiver.
	messageSelector _ self remap: messageSelector.
	newMethod _ self remap: newMethod.
	methodClass _ self remap: methodClass.
	lkupClass _ self remap: lkupClass.
	receiverClass _ self remap: receiverClass.
	1 to: remapBufferCount do: [:i | 
			oop _ remapBuffer at: i.
			(self isIntegerObject: oop)
				ifFalse: [remapBuffer at: i put: (self remap: oop)]]
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
			oop _ remapBuffer at: i.
			(self isIntegerObject: oop) ifFalse: [self markAndTrace: oop]]
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
	self export: true.
	self var: #aModuleName type: 'char *'.
	(aModuleName strcmp: 'SurfacePlugin') = 0
		ifTrue: ["Surface plugin went away. Should never happen. But  then, who knows"
			showSurfaceFn _ 0]
]

{ #category : #contexts }
Interpreter >> newActiveContext: aContext [
	"Note: internalNewActiveContext: should track changes to this method."

	self storeContextRegisters: activeContext.
	(aContext < youngStart) ifTrue: [ self beRootIfOld: aContext ].
	activeContext _ aContext.
	self fetchContextRegisters: aContext.
]

{ #category : #'object format' }
Interpreter >> nonWeakFieldsOf: oop [
	"Return the number of non-weak fields in oop (i.e. the number of fixed fields).
	Note: The following is copied from fixedFieldsOf:format:length: since we do know
	the format of the oop (e.g. format = 4) and thus don't need the length."
	| class classFormat |
	self inline: false. "No need to inline - we won't call this often"

	(self isWeakNonInt: oop) ifFalse:[self error:'Called fixedFieldsOfWeak: with a non-weak oop'].

	"fmt = 3 or 4: mixture of fixed and indexable fields, so must look at class format word"
	class _ self fetchClassOf: oop.
	classFormat _ self formatOfClass: class.
	^ (classFormat >> 11 bitAnd: 16rC0) + (classFormat >> 2 bitAnd: 16r3F) - 1

]

{ #category : #'message sending' }
Interpreter >> normalSend [
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that 
	the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	| rcvr |
	self inline: true.
	self sharedCodeNamed: 'normalSend' inCase: 131.
	rcvr _ self internalStackValue: argumentCount.
	lkupClass _ self fetchClassOf: rcvr.
	receiverClass _ lkupClass.
	self commonSend.
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
	cntxt _ activeContext.	
	[cntxt = nilObj] whileFalse: [
		self okayFields: cntxt.
		cntxt _ (self fetchPointer: SenderIndex ofObject: cntxt).
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
	c _ self fetchClassOf: oop.
	(c = (self splObj: ClassMethodContext)
		or: [c = (self splObj: ClassBlockContext)])
		ifTrue: [i _ CtxtTempFrameStart + (self fetchStackPointerOf: oop) - 1]
		ifFalse: [i _ (self lengthOf: oop) - 1].
	[i >= 0] whileTrue: [
		fieldOop _ self fetchPointer: i ofObject: oop.
		(self isIntegerObject: fieldOop) ifFalse: [
			self okayOop: fieldOop.
			self oopHasOkayClass: fieldOop.
		].
		i _ i - 1.
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
		oopOrZero _ methodCache at: i + MethodCacheSelector.
		oopOrZero = 0 ifFalse: [
			self okayFields: (methodCache at: i + MethodCacheSelector).
			self okayFields: (methodCache at: i + MethodCacheClass).
			self okayFields: (methodCache at: i + MethodCacheMethod).
		].
	].
	1 to: remapBufferCount do: [ :i |
		oop _ remapBuffer at: i.
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
	self var: #oop type: 'usqInt'.
	oop := self cCoerce: signedOop to: 'usqInt'.

	"address and size checks"
	(self isIntegerObject: oop) ifTrue: [ ^true ].
	(oop < endOfMemory)
		ifFalse: [ self error: 'oop is not a valid address' ].
	((oop \\ BytesPerWord) = 0)
		ifFalse: [ self error: 'oop is not a word-aligned address' ].
	sz _ self sizeBitsOf: oop.
	(oop + sz) < endOfMemory
		ifFalse: [ self error: 'oop size would make it extend beyond the end of memory' ].

	"header type checks"
	type _ self headerType: oop.
	type = HeaderTypeFree
		ifTrue:  [ self error: 'oop is a free chunk, not an object' ].
	type = HeaderTypeShort ifTrue: [
		(((self baseHeader: oop) >> 12) bitAnd: 16r1F) = 0
			ifTrue:  [ self error: 'cannot have zero compact class field in a short header' ].
	].
	type = HeaderTypeClass ifTrue: [
		((oop >= BytesPerWord) and: [(self headerType: oop - BytesPerWord) = type])
			ifFalse: [ self error: 'class header word has wrong type' ].
	].
	type = HeaderTypeSizeAndClass ifTrue: [
		((oop >= (BytesPerWord*2)) and:
		 [(self headerType: oop - (BytesPerWord*2)) = type and:
		 [(self headerType: oop - BytesPerWord) = type]])
			ifFalse: [ self error: 'class header word has wrong type' ].
	].

	"format check"
	fmt _ self formatOf: oop.
	((fmt = 5) | (fmt = 7))
		ifTrue:  [ self error: 'oop has an unknown format type' ].

	"mark and root bit checks"
	unusedBit _ 16r20000000.
	BytesPerWord = 8
		ifTrue:
			[unusedBit _ unusedBit << 16.
			 unusedBit _ unusedBit << 16].
	((self longAt: oop) bitAnd: unusedBit) = 0
		ifFalse: [ self error: 'unused header bit 30 is set; should be zero' ].
"xxx
	((self longAt: oop) bitAnd: MarkBit) = 0
		ifFalse: [ self error: 'mark bit should not be set except during GC' ].
xxx"
	(((self longAt: oop) bitAnd: RootBit) = 1 and:
	 [oop >= youngStart])
		ifTrue: [ self error: 'root bit is set in a young object' ].
	^true

]

{ #category : #'image segment in/out' }
Interpreter >> oopHasAcceptableClass: signedOop [
	"Similar to oopHasOkayClass:, except that it only returns true or false."

	| oopClass formatMask behaviorFormatBits oopFormatBits oop |
	(self isIntegerObject: signedOop) ifTrue: [^ true].

	self var: #oop type: 'usqInt'.
	self var: #oopClass type: 'usqInt'.

	oop := self cCoerce: signedOop to: 'usqInt'.

	oop < endOfMemory ifFalse: [^ false].
	((oop \\ BytesPerWord) = 0) ifFalse: [^ false].
	(oop + (self sizeBitsOf: oop)) < endOfMemory ifFalse: [^ false].
	oopClass := self cCoerce: (self fetchClassOf: oop) to: 'usqInt'.

	(self isIntegerObject: oopClass) ifTrue: [^ false].
	(oopClass < endOfMemory) ifFalse: [^ false].
	((oopClass \\ BytesPerWord) = 0) ifFalse: [^ false].
	(oopClass + (self sizeBitsOf: oopClass)) < endOfMemory ifFalse: [^ false].
	((self isPointers: oopClass) and: [(self lengthOf: oopClass) >= 3]) ifFalse: [^ false].
	(self isBytes: oop)
		ifTrue: [ formatMask _ 16rC00 ]  "ignore extra bytes size bits"
		ifFalse: [ formatMask _ 16rF00 ].

	behaviorFormatBits _ (self formatOfClass: oopClass) bitAnd: formatMask.
	oopFormatBits _ (self baseHeader: oop) bitAnd: formatMask.
	behaviorFormatBits = oopFormatBits ifFalse: [^ false].
	^ true
]

{ #category : #'debug support' }
Interpreter >> oopHasOkayClass: signedOop [
	"Attempt to verify that the given oop has a reasonable behavior. The class must be a valid, non-integer oop and must not be nilObj. It must be a pointers object with three or more fields. Finally, the instance specification field of the behavior must match that of the instance."

	| oop oopClass formatMask behaviorFormatBits oopFormatBits |
	self var: #oop type: 'usqInt'.
	self var: #oopClass type: 'usqInt'.

	oop := self cCoerce: signedOop to: 'usqInt'.
	self okayOop: oop.
	oopClass := self cCoerce: (self fetchClassOf: oop) to: 'usqInt'.

	(self isIntegerObject: oopClass)
		ifTrue: [ self error: 'a SmallInteger is not a valid class or behavior' ].
	self okayOop: oopClass.
	((self isPointers: oopClass) and: [(self lengthOf: oopClass) >= 3])
		ifFalse: [ self error: 'a class (behavior) must be a pointers object of size >= 3' ].
	(self isBytes: oop)
		ifTrue: [ formatMask _ 16rC00 ]  "ignore extra bytes size bits"
		ifFalse: [ formatMask _ 16rF00 ].

	behaviorFormatBits _ (self formatOfClass: oopClass) bitAnd: formatMask.
	oopFormatBits _ (self baseHeader: oop) bitAnd: formatMask.
	behaviorFormatBits = oopFormatBits
		ifFalse: [ self error: 'object and its class (behavior) formats differ' ].
	^true
]

{ #category : #contexts }
Interpreter >> pop2AndPushIntegerIfOK: integerResult [

	successFlag ifTrue:
		[(self isIntegerValue: integerResult)
			ifTrue: [self pop: 2 thenPush: (self integerObjectOf: integerResult)]
			ifFalse: [successFlag _ false]]
]

{ #category : #contexts }
Interpreter >> pop: nItems [
	"Note: May be called by translated primitive code."

	stackPointer _ stackPointer - (nItems*BytesPerWord).
]

{ #category : #contexts }
Interpreter >> pop: nItems thenPush: oop [

	| sp |
	self longAt: (sp _ stackPointer - ((nItems - 1) * BytesPerWord)) put: oop.
	stackPointer _ sp.

]

{ #category : #contexts }
Interpreter >> pop: nItems thenPushInteger: integerVal [
"lots of places pop a few items off the stack and then push an integer. MAke it convenient"
	| sp |
	self longAt: (sp _ stackPointer - ((nItems - 1) * BytesPerWord)) put:(self integerObjectOf: integerVal).
	stackPointer _ sp.

]

{ #category : #'stack bytecodes' }
Interpreter >> popFloat [
	"Note: May be called by translated primitive code."

	| top result |
	self returnTypeC: 'double'.
	self var: #result type: 'double '.
	top _ self popStack.
	self assertClassOf: top is: (self splObj: ClassFloat).
	successFlag ifTrue:
		[self cCode: '' inSmalltalk: [result _ Float new: 2].
		self fetchFloatAt: top + BaseHeaderSize into: result].
	^ result
]

{ #category : #contexts }
Interpreter >> popInteger [
"returns 0 if the stackTop was not an integer value, plus sets successFlag false"
	| integerPointer |
	integerPointer _ self popStack.
	^self checkedIntegerValueOf: integerPointer
]

{ #category : #contexts }
Interpreter >> popPos32BitInteger [
	"May set successFlag, and return false if not valid"

	| top |
	top _ self popStack.
	^ self positive32BitValueOf: top
]

{ #category : #contexts }
Interpreter >> popStack [

	| top |
	top _ self longAt: stackPointer.
	stackPointer _ stackPointer - BytesPerWord.
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

	BytesPerWord = 4
	ifTrue: ["Faster instantiateSmallClass: currently only works with integral word size."
			newLargeInteger _ self instantiateSmallClass: (self splObj: ClassLargePositiveInteger)
					sizeInBytes: BaseHeaderSize + 4]
	ifFalse: ["Cant use instantiateSmallClass: due to integral word requirement."
			newLargeInteger _ self instantiateClass: (self splObj: ClassLargePositiveInteger)
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
		value _ self integerValueOf: oop.
		value < 0 ifTrue: [^ self primitiveFail].
		^ value].

	self assertClassOf: oop is: (self splObj: ClassLargePositiveInteger).
	successFlag ifTrue: [
		sz _ self lengthOf: oop.
		sz = 4 ifFalse: [^ self primitiveFail]].
	successFlag ifTrue: [
		^ (self fetchByte: 0 ofObject: oop) +
		  ((self fetchByte: 1 ofObject: oop) <<  8) +
		  ((self fetchByte: 2 ofObject: oop) << 16) +
		  ((self fetchByte: 3 ofObject: oop) << 24) ].
]

{ #category : #'primitive support' }
Interpreter >> positive64BitIntegerFor: integerValue [

	| newLargeInteger value check |
	"Note - integerValue is interpreted as POSITIVE, eg, as the result of
		Bitmap>at:, or integer>bitAnd:."
	self var: 'integerValue' type: 'sqLong'.
 
	(self sizeof: integerValue) = 4 ifTrue: [^self positive32BitIntegerFor: integerValue].

  	self cCode: 'check = integerValue >> 32'.  "Why not run this in sim?"
	check = 0 ifTrue: [^self positive32BitIntegerFor: integerValue].
	
	newLargeInteger _
		self instantiateSmallClass: (self splObj: ClassLargePositiveInteger) sizeInBytes: BaseHeaderSize + 8.
	0 to: 7 do: [:i |
		self cCode: 'value = ( integerValue >> (i * 8)) & 255'.
		self storeByte: i ofObject: newLargeInteger withValue: value].
	^ newLargeInteger
]

{ #category : #'primitive support' }
Interpreter >> positive64BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive ST integer or a eight-byte LargePositiveInteger."

	| sz szsqLong value  |
	self returnTypeC: 'sqLong'.
	self var: 'value' type: 'sqLong'.
	(self isIntegerObject: oop) ifTrue: [
		value _ self integerValueOf: oop.
		value < 0 ifTrue: [^ self primitiveFail].
		^ value].

	self assertClassOf: oop is: (self splObj: ClassLargePositiveInteger).
	successFlag ifFalse: [^ self primitiveFail].
	szsqLong _ self cCode: 'sizeof(sqLong)'.
	sz _ self lengthOf: oop.
	sz > szsqLong
		ifTrue: [^ self primitiveFail].
	value _ 0.
	0 to: sz - 1 do: [:i |
		value _ value + ((self cCoerce: (self fetchByte: i ofObject: oop) to: 'sqLong') <<  (i*8))].
	^value.
]

{ #category : #'object memory support' }
Interpreter >> postGCAction [
	"Mark the active and home contexts as roots if old. This 
	allows the interpreter to use storePointerUnchecked to 
	store into them."

	compilerInitialized
		ifTrue: [self compilerPostGC]
		ifFalse: [activeContext < youngStart
				ifTrue: [self beRootIfOld: activeContext].
			theHomeContext < youngStart
				ifTrue: [self beRootIfOld: theHomeContext]].
	(self sizeOfFree: freeBlock) > shrinkThreshold
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

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveAdd [

	self pop2AndPushIntegerIfOK: (self stackIntegerValue: 1) + (self stackIntegerValue: 0)
]

{ #category : #'float primitives' }
Interpreter >> primitiveArctan [

	| rcvr |
	self var: #rcvr type: 'double '.
	rcvr _ self popFloat.
	successFlag
		ifTrue: [self pushFloat: (self cCode: 'atan(rcvr)' inSmalltalk: [rcvr arcTan])]
		ifFalse: [self unPop: 1]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveArrayBecome [
	"We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors."

	| arg rcvr |
	arg _ self stackTop.
	rcvr _ self stackValue: 1.
	self success: (self become: rcvr with: arg twoWay: true copyHash: true).
	successFlag ifTrue: [ self pop: 1 ].
]

{ #category : #'object access primitives' }
Interpreter >> primitiveArrayBecomeOneWay [
	"We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors."

	| arg rcvr |
	arg _ self stackTop.
	rcvr _ self stackValue: 1.
	self success: (self become: rcvr with: arg twoWay: false copyHash: true).
	successFlag ifTrue: [ self pop: 1 ].
]

{ #category : #'object access primitives' }
Interpreter >> primitiveArrayBecomeOneWayCopyHash [
	"Similar to primitiveArrayBecomeOneWay but accepts a third argument whether to copy
	the receiver's identity hash over the argument's identity hash."

	| copyHashFlag arg rcvr |
	copyHashFlag _ self booleanValueOf: (self stackTop).
	arg _ self stackValue: 1.
	rcvr _ self stackValue: 2.
	self success: (self become: rcvr with: arg twoWay: false copyHash: copyHashFlag).
	successFlag ifTrue: [ self pop: 2 ].
]

{ #category : #'float primitives' }
Interpreter >> primitiveAsFloat [
	| arg |
	arg _ self popInteger.
	successFlag
		ifTrue: [ self pushFloat: (self cCode: '((double) arg)' inSmalltalk: [arg asFloat]) ]
		ifFalse: [ self unPop: 1 ].
]

{ #category : #'object access primitives' }
Interpreter >> primitiveAsOop [
	| thisReceiver |
	thisReceiver _ self stackTop.
	self success: (self isIntegerObject: thisReceiver) not.
	successFlag
		ifTrue: [self pop:1 thenPushInteger: (self hashBitsOf: thisReceiver)]
]

{ #category : #'array and stream primitives' }
Interpreter >> primitiveAt [

	self commonAt: false.
]

{ #category : #'array and stream primitives' }
Interpreter >> primitiveAtEnd [
	| stream index limit |
	stream _ self popStack.
	successFlag _ ((self isPointers: stream)
			and: [(self lengthOf: stream) >= (StreamReadLimitIndex+1)]).
 	successFlag ifTrue: [
		index _ self fetchInteger: StreamIndexIndex ofObject: stream.
		limit _ self fetchInteger: StreamReadLimitIndex ofObject: stream].
 	successFlag
		ifTrue: [self pushBool: (index >= limit)]
		ifFalse: [self unPop: 1].
]

{ #category : #'array and stream primitives' }
Interpreter >> primitiveAtPut [

	self commonAtPut: false.
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveBeCursor [
	"Set the cursor to the given shape. The Mac only supports 16x16 pixel cursors. Cursor offsets are handled by Smalltalk."

	| cursorObj maskBitsIndex maskObj bitsObj extentX extentY depth offsetObj offsetX offsetY cursorBitsIndex ourCursor |

self flag: #Dan.  "This is disabled until we convert bitmaps appropriately"
BytesPerWord = 8 ifTrue: [^ self pop: argumentCount].

	argumentCount = 0 ifTrue: [
		cursorObj _ self stackTop.
		maskBitsIndex _ nil].
	argumentCount = 1 ifTrue: [
		cursorObj _ self stackValue: 1.
		maskObj _ self stackTop].
	self success: (argumentCount < 2).

	self success: ((self isPointers: cursorObj) and: [(self lengthOf: cursorObj) >= 5]).
	successFlag ifTrue: [
		bitsObj _ self fetchPointer: 0 ofObject: cursorObj.
		extentX _ self fetchInteger: 1 ofObject: cursorObj.
		extentY _ self fetchInteger: 2 ofObject: cursorObj.
		depth _ self fetchInteger: 3 ofObject: cursorObj.
		offsetObj _ self fetchPointer: 4 ofObject: cursorObj].
		self success: ((self isPointers: offsetObj) and: [(self lengthOf: offsetObj) >= 2]).

	successFlag ifTrue: [
		offsetX _ self fetchInteger: 0 ofObject: offsetObj.
		offsetY _ self fetchInteger: 1 ofObject: offsetObj.
		self success: ((extentX = 16) and: [extentY = 16 and: [depth = 1]]).
		self success: ((offsetX >= -16) and: [offsetX <= 0]).
		self success: ((offsetY >= -16) and: [offsetY <= 0]).
		self success: ((self isWords: bitsObj) and: [(self lengthOf: bitsObj) = 16]).
		cursorBitsIndex _ bitsObj + BaseHeaderSize.
		self cCode: '' inSmalltalk:
			[ourCursor _ Cursor
				extent: extentX @ extentY
				fromArray: ((1 to: 16) collect: [:i |
					((self fetchLong32: i-1 ofObject: bitsObj) >> (BytesPerWord*8 - 16)) bitAnd: 16rFFFF])
				offset: offsetX  @ offsetY]].

	argumentCount = 1 ifTrue: [
		self success: ((self isPointers: maskObj) and: [(self lengthOf: maskObj) >= 5]).
		successFlag ifTrue: [
			bitsObj _ self fetchPointer: 0 ofObject: maskObj.
			extentX _ self fetchInteger: 1 ofObject: maskObj.
			extentY _ self fetchInteger: 2 ofObject: maskObj.
			depth _ self fetchInteger: 3 ofObject: maskObj].

		successFlag ifTrue: [
			self success: ((extentX = 16) and: [extentY = 16 and: [depth = 1]]).
			self success: ((self isWords: bitsObj) and: [(self lengthOf: bitsObj) = 16]).
			maskBitsIndex _ bitsObj + BaseHeaderSize]].

	successFlag ifTrue: [
		argumentCount = 0
			ifTrue: [self cCode: 'ioSetCursor(cursorBitsIndex, offsetX, offsetY)'
						inSmalltalk: [ourCursor show]]
			ifFalse: [self cCode: 'ioSetCursorWithMask(cursorBitsIndex, maskBitsIndex, offsetX, offsetY)'
						inSmalltalk: [ourCursor show]].
		self pop: argumentCount].

]

{ #category : #'I/O primitives' }
Interpreter >> primitiveBeDisplay [
	"Record the system Display object in the specialObjectsTable."
	| rcvr |
	rcvr _ self stackTop.
	self success: ((self isPointers: rcvr) and: [(self lengthOf: rcvr) >= 4]).
	successFlag ifTrue: [self storePointer: TheDisplay ofObject: specialObjectsOop withValue: rcvr]
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveBeep [
"make the basic beep noise"
	self ioBeep.
]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveBitAnd [
	| integerReceiver integerArgument |
	integerArgument _ self popPos32BitInteger.
	integerReceiver _ self popPos32BitInteger.
	successFlag
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitAnd: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveBitOr [
	| integerReceiver integerArgument |
	integerArgument _ self popPos32BitInteger.
	integerReceiver _ self popPos32BitInteger.
	successFlag
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitOr: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveBitShift [ 
	| integerReceiver integerArgument shifted |
	integerArgument _ self popInteger.
	integerReceiver _ self popPos32BitInteger.
	successFlag ifTrue: [
		integerArgument >= 0 ifTrue: [
			"Left shift -- must fail if we lose bits beyond 32"
			self success: integerArgument <= 31.
			shifted _ integerReceiver << integerArgument.
			self success: (shifted >> integerArgument) = integerReceiver.
		] ifFalse: [
			"Right shift -- OK to lose bits"
			self success: integerArgument >= -31.
			shifted _ integerReceiver bitShift: integerArgument.
		].
	].
	successFlag
		ifTrue: [self push: (self positive32BitIntegerFor: shifted)]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveBitXor [
	| integerReceiver integerArgument |
	integerArgument _ self popPos32BitInteger.
	integerReceiver _ self popPos32BitInteger.
	successFlag
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitXor: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'control primitives' }
Interpreter >> primitiveBlockCopy [

	| context methodContext contextSize newContext initialIP |
	context _ self stackValue: 1.
	(self isIntegerObject: (self fetchPointer: MethodIndex ofObject: context))
		ifTrue: ["context is a block; get the context of its enclosing method"
				methodContext _ self fetchPointer: HomeIndex ofObject: context]
		ifFalse: [methodContext _ context].
	contextSize _ self sizeBitsOf: methodContext.  "in bytes, including header"
	context _ nil.  "context is no longer needed and is not preserved across allocation"

	"remap methodContext in case GC happens during allocation"
	self pushRemappableOop: methodContext.
	newContext _ self instantiateContext: (self splObj: ClassBlockContext) sizeInBytes: contextSize.
	methodContext _ self popRemappableOop.

	initialIP _ self integerObjectOf: (instructionPointer+1+3) - (method+BaseHeaderSize).
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

{ #category : #'array and stream primitive support' }
Interpreter >> primitiveByteArrayDoubleAt [
	"Return a double from the given byte offset in a ByteArray."
	| byteOffset rcvr addr floatValue |
	self export: true.
	self inline: false.
	self var: #floatValue type:'double '.
	byteOffset _ self stackIntegerValue: 0.
	rcvr _ self stackObjectValue: 1.
	self failed ifTrue:[^0].
	addr _ self addressOf: rcvr startingAt: byteOffset size: 8.
	self failed ifTrue:[^0].
	self cCode:'((int*)(&floatValue))[0] = ((int*)addr)[0]'.
	self cCode:'((int*)(&floatValue))[1] = ((int*)addr)[1]'.
	self pop: 2.
	^self pushFloat: floatValue

]

{ #category : #'array and stream primitive support' }
Interpreter >> primitiveByteArrayDoubleAtPut [
	"Store a Double at given byte offset in a ByteArray."
	| byteOffset rcvr addr floatValue floatOop |
	self export: true.
	self inline: false.
	self var: #floatValue type:'double '.
	floatOop _ self stackValue: 0.
	(self isIntegerObject: floatOop)
		ifTrue:[floatValue _ self cCoerce: (self integerValueOf: floatOop) to:'double']
		ifFalse:[floatValue _ self cCoerce: (self floatValueOf: floatOop) to:'double'].
	byteOffset _ self stackIntegerValue: 1.
	rcvr _ self stackObjectValue: 2.
	self failed ifTrue:[^0].
	addr _ self addressOf: rcvr startingAt: byteOffset size: 8.
	self failed ifTrue:[^0].
	self cCode:'((int*)addr)[0] = ((int*)(&floatValue))[0]'.
	self cCode:'((int*)addr)[1] = ((int*)(&floatValue))[1]'.
	self pop: 3.
	^self push: floatOop
]

{ #category : #'array and stream primitive support' }
Interpreter >> primitiveByteArrayFloatAt [
	"Return a Float from the given byte offset in a ByteArray."
	| byteOffset rcvr addr floatValue |
	self export: true.
	self inline: false.
	self var: #floatValue type:'float '.
	byteOffset _ self stackIntegerValue: 0.
	rcvr _ self stackObjectValue: 1.
	self failed ifTrue:[^0].
	addr _ self addressOf: rcvr startingAt: byteOffset size: 4.
	self failed ifTrue:[^0].
	self cCode:'((int*)(&floatValue))[0] = ((int*)addr)[0]'.
	self pop: 2.
	^self pushFloat: floatValue
]

{ #category : #'array and stream primitive support' }
Interpreter >> primitiveByteArrayFloatAtPut [
	"Store a Float at the given byteOffset in a ByteArray"
	| byteOffset rcvr addr floatValue floatOop |
	self export: true.
	self inline: false.
	self var: #floatValue type:'float '.
	floatOop _ self stackValue: 0.
	(self isIntegerObject: floatOop)
		ifTrue:[floatValue _ self cCoerce: (self integerValueOf: floatOop) to:'float']
		ifFalse:[floatValue _ self cCoerce: (self floatValueOf: floatOop) to:'float'].
	byteOffset _ self stackIntegerValue: 1.
	rcvr _ self stackObjectValue: 2.
	self failed ifTrue:[^0].
	addr _ self addressOf: rcvr startingAt: byteOffset size: 4.
	self failed ifTrue:[^0].
	self cCode:'((int*)addr)[0] = ((int*)(&floatValue))[0]'.
	self pop: 3.
	^self push: floatOop
]

{ #category : #'array and stream primitive support' }
Interpreter >> primitiveByteArrayNByteIIntegerAtPut [
	"Store a (signed or unsigned) n byte integer at the given byte offset."
	| isSigned byteSize byteOffset rcvr addr value max valueOop |
	self export: true.
	self inline: false.
	isSigned _ self booleanValueOf: (self stackValue: 0).
	byteSize _ self stackIntegerValue: 1.
	valueOop _ self stackValue: 2.
	byteOffset _ self stackIntegerValue: 3.
	rcvr _ self stackObjectValue: 4.
	self failed ifTrue:[^0].
	(byteOffset > 0 and:[byteSize = 1 or:[byteSize = 2 or:[byteSize = 4]]])
		ifFalse:[^self primitiveFail].
	addr _ self addressOf: rcvr startingAt: byteOffset size: byteSize.
	self failed ifTrue:[^0].
	isSigned 
		ifTrue:[value _ self signed32BitValueOf: valueOop]
		ifFalse:[value _ self positive32BitValueOf: valueOop].
	self failed ifTrue:[^0].
	byteSize < 4 ifTrue:[
		isSigned ifTrue:[
			max _ 1 << (8 * byteSize - 1).
			value >= max ifTrue:[^self primitiveFail].
			value < (0 - max) ifTrue:[^self primitiveFail].
		] ifFalse:[
			value >= (1 << (8*byteSize)) ifTrue:[^self primitiveFail].
		].
		"short/byte"
		byteSize = 1 
			ifTrue:[self byteAt: addr put: value]
			ifFalse:[	self cCode: '*((short int *) addr) = value' 
						inSmalltalk: [self shortAt: addr put: value]].
	] ifFalse:[self longAt: addr put: value].
	self pop: 5.
	^self push: valueOop.
]

{ #category : #'array and stream primitive support' }
Interpreter >> primitiveByteArrayNByteIntegerAt [
	"Return a (signed or unsigned) n byte integer from the given byte offset."
	| isSigned byteSize byteOffset rcvr addr value mask |
	self export: true.
	self inline: false.
	isSigned _ self booleanValueOf: (self stackValue: 0).
	byteSize _ self stackIntegerValue: 1.
	byteOffset _ self stackIntegerValue: 2.
	rcvr _ self stackObjectValue: 3.
	self failed ifTrue:[^0].
	(byteOffset > 0 and:[byteSize = 1 or:[byteSize = 2 or:[byteSize = 4]]])
		ifFalse:[^self primitiveFail].
	addr _ self addressOf: rcvr startingAt: byteOffset size: byteSize.
	self failed ifTrue:[^0].
	byteSize < 4 ifTrue:[
		"short/byte"
		byteSize = 1 
			ifTrue:[value _ self byteAt: addr]
			ifFalse:[	value _ self cCode: '*((short int *) addr)' 
								inSmalltalk: [self shortAt: addr]].
		isSigned ifTrue:["sign extend value"
			mask _ 1 << (byteSize * 8 - 1).
			value _ (value bitAnd: mask-1) - (value bitAnd: mask)].
		"note: byte/short never exceed SmallInteger range"
		value _ self integerObjectOf: value.
	] ifFalse:[
		"general 32 bit integer"
		value _ self longAt: addr.
		isSigned
			ifTrue:[value _ self signed32BitIntegerFor: value]
			ifFalse:[value _ self positive32BitIntegerFor: value].
	].
	self pop: 4.
	^self push: value

]

{ #category : #'memory space primitives' }
Interpreter >> primitiveBytesLeft [
	"Reports bytes available at this moment. For more meaningful 
	results, calls to this primitive should be preceeded by a full 
	or incremental garbage collection."
	| aBool |
	self methodArgumentCount = 0
		ifTrue: ["old behavior - just return the size of the free block"
			^self pop: 1 thenPushInteger: (self sizeOfFree: freeBlock)].
	self methodArgumentCount = 1
		ifTrue: ["new behaviour -including or excluding swap space depending on aBool"
			aBool _ self booleanValueOf: self stackTop.
			successFlag ifFalse: [^ nil].
			^self pop: 2 thenPushInteger: (self bytesLeft: aBool)].
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
	self var: #function declareC: 'static void *function = 0'.
	self var: #moduleName declareC: 'static char *moduleName = "SqueakFFIPrims"'.
	self var: #functionName declareC: 'static char *functionName = "primitiveCallout"'.
	function = 0 ifTrue: [
		function _ self
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
	| arg rcvr argClass classHdr sizeHiBits byteSize argFormat rcvrFormat ccIndex |
	arg _ self stackObjectValue: 0.
	rcvr _ self stackObjectValue: 1.
	successFlag ifFalse:[^nil].

	"Get the class we want to convert the receiver into"
	argClass _ self fetchClassOf: arg.

	"Check what the format of the class says"
	classHdr _ self formatOfClass: argClass. "Low 2 bits are 0"

	"Compute the size of instances of the class (used for fixed field classes only)"
	sizeHiBits _ (classHdr bitAnd: 16r60000) >> 9.
	classHdr _ classHdr bitAnd: 16r1FFFF.
	byteSize _ (classHdr bitAnd: SizeMask) + sizeHiBits. "size in bytes -- low 2 bits are 0"

	"Check the receiver's format against that of the class"
	argFormat _ (classHdr >> 8) bitAnd: 16rF.
	rcvrFormat _ self formatOf: rcvr.
	argFormat = rcvrFormat ifFalse:[^self primitiveFail]. "no way"

	"For fixed field classes, the sizes must match.
	Note: base header size is included in class size."
	argFormat < 2 ifTrue:[(byteSize - BaseHeaderSize) = (self byteSizeOf: rcvr) ifFalse:[^self primitiveFail]].

	(self headerType: rcvr) = HeaderTypeShort
		ifTrue:[ "Compact classes. Check if the arg's class is compact and exchange ccIndex"
			ccIndex _ classHdr bitAnd: CompactClassMask.
			ccIndex = 0 ifTrue:[^self primitiveFail]. "class is not compact"
			self longAt: rcvr put:
				(((self longAt: rcvr) bitAnd: CompactClassMask bitInvert32)
					bitOr: ccIndex)]
		ifFalse:["Exchange the class pointer, which could make rcvr a root for argClass"
			self longAt: rcvr-BaseHeaderSize put: (argClass bitOr: (self headerType: rcvr)).
			(rcvr < youngStart) ifTrue: [self possibleRootStoreInto: rcvr value: argClass]].

	"Flush cache because rcvr's class has changed"
	self flushMethodCache.

	successFlag ifTrue: [ self pop: 1 ]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveClass [
	| instance |
	instance _ self stackTop.
	self pop: argumentCount+1 thenPush: (self fetchClassOf: instance)
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveClipboardText [
	"When called with a single string argument, post the string to 
	the clipboard. When called with zero arguments, return a 
	string containing the current clipboard contents."
	| s sz |
	argumentCount = 1
		ifTrue: [s _ self stackTop.
			(self isBytes: s) ifFalse: [^ self primitiveFail].
			successFlag
				ifTrue: [sz _ self stSizeOf: s.
					self clipboardWrite: sz From: s + BaseHeaderSize At: 0.
					self pop: 1]]
		ifFalse: [sz _ self clipboardSize.
			(self sufficientSpaceToAllocate: sz) ifFalse:[^self primitiveFail].
			s _ self instantiateClass: (self splObj: ClassString) indexableSize: sz.
			self clipboardRead: sz Into: s + BaseHeaderSize At: 0.
			self pop: 1 thenPush: s]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveClone [
	"Return a shallow copy of the receiver."

	| newCopy |
	newCopy _ self clone: (self stackTop).
	newCopy = 0
		ifTrue:["not enough memory most likely" ^self primitiveFail].
	self pop: 1 thenPush: newCopy.
]

{ #category : #'sound primitives' }
Interpreter >> primitiveConstantFill [
	"Fill the receiver, which must be an indexable bytes or words 
	objects, with the given integer value."
	| fillValue rcvr rcvrIsBytes end i |
	fillValue _ self positive32BitValueOf: self stackTop.
	rcvr _ self stackValue: 1.
	self success: (self isWordsOrBytes: rcvr).
	rcvrIsBytes _ self isBytes: rcvr.
	rcvrIsBytes ifTrue: [self success: (fillValue >= 0 and: [fillValue <= 255])].
	successFlag
		ifTrue: [end _ rcvr + (self sizeBitsOf: rcvr).
			i _ rcvr + BaseHeaderSize.
			rcvrIsBytes
				ifTrue: [[i < end]
						whileTrue: [self byteAt: i put: fillValue.
							i _ i + 1]]
				ifFalse: [[i < end]
						whileTrue: [self long32At: i put: fillValue.
							i _ i + 4]].
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
	arg _ self stackObjectValue: 0.
	rcvr _ self stackObjectValue: 1.

	self failed ifTrue:[^nil].
	(self isPointers: rcvr) ifFalse:[^self primitiveFail].
	(self fetchClassOf: rcvr) = (self fetchClassOf: arg) ifFalse:[^self primitiveFail].
	length _ self lengthOf: rcvr.
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
	flag _ self stackTop.
	flag = trueObj
		ifTrue: [deferDisplayUpdates _ true]
		ifFalse: [flag = falseObj
				ifTrue: [deferDisplayUpdates _ false]
				ifFalse: [self primitiveFail]].
	successFlag
		ifTrue: [self pop: 1]
]

{ #category : #'system control primitives' }
Interpreter >> primitiveDisablePowerManager [
	"Pass in a non-negative value to disable the architectures powermanager if any, zero to enable. This is a named (not numbered) primitive in the null module (ie the VM)"

	| integer |
	self export: true.
	integer _ self stackIntegerValue: 0.
	successFlag ifTrue: [
		self ioDisablePowerManager: integer.
		self pop: 1].  "integer; leave rcvr on stack"

]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveDiv [
	| quotient |
	quotient _ self doPrimitiveDiv: (self stackValue: 1) by: (self stackTop).
	self pop2AndPushIntegerIfOK: quotient
]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveDivide [
	| integerReceiver integerArgument |
	integerReceiver _ self stackIntegerValue: 1.
	integerArgument _ self stackIntegerValue: 0.
	(integerArgument ~= 0 and: [integerReceiver \\ integerArgument = 0])
		ifTrue: [self pop2AndPushIntegerIfOK: integerReceiver // integerArgument]
		ifFalse: [self primitiveFail]
]

{ #category : #'control primitives' }
Interpreter >> primitiveDoPrimitiveWithArgs [
	| argumentArray arraySize index cntxSize primIdx |
	argumentArray _ self stackTop.
	arraySize _ self fetchWordLengthOf: argumentArray.
	cntxSize _ self fetchWordLengthOf: activeContext.
	self success: self stackPointerIndex + arraySize < cntxSize.
	(self isArray: argumentArray) ifFalse: [^ self primitiveFail].

	primIdx _ self stackIntegerValue: 1.
	successFlag ifFalse: [^ self primitiveFail]. "invalid args"

	"Pop primIndex and argArray, then push args in place..."
	self pop: 2.
	primitiveIndex _ primIdx.
	argumentCount _ arraySize.
	index _ 1.
	[index <= argumentCount]
		whileTrue: [self push: (self fetchPointer: index - 1 ofObject: argumentArray).
			index _ index + 1].

	"Run the primitive (sets successFlag)"
	self pushRemappableOop: argumentArray. "prim might alloc/gc"
	lkupClass _ nilObj.
	self primitiveResponse.
	argumentArray _ self popRemappableOop.
	successFlag
		ifFalse: ["If primitive failed, then restore state for failure code"
			self pop: arraySize.
			self pushInteger: primIdx.
			self push: argumentArray.
			argumentCount _ 2]
]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveEqual [
	| integerReceiver integerArgument result |
	integerArgument _ self popStack.
	integerReceiver _ self popStack.
	result _ self compare31or32Bits: integerReceiver equal: integerArgument.
	self checkBooleanResult: result
]

{ #category : #'object access primitives' }
Interpreter >> primitiveEquivalent [
"is the receiver the same object as the argument?"
	| thisObject otherObject |
	otherObject _ self popStack.
	thisObject _ self popStack.
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

	| argCnt argumentArray |
	newMethod _ self popStack.
	primitiveIndex _ self primitiveIndexOf: newMethod.
	argCnt _ self argumentCountOf: newMethod.
	argumentArray _ self popStack.
	"If the argArray isnt actually an Array we have to unPop both the above"
	(self isArray: argumentArray) ifFalse:[self unPop: 2. ^self primitiveFail].
	successFlag ifTrue: [self success: (argCnt = (self fetchWordLengthOf: argumentArray))].
	successFlag
		ifTrue: [self transfer: argCnt from: argumentArray + BaseHeaderSize to: stackPointer + BytesPerWord.
			self unPop: argCnt.
			argumentCount _ argCnt.
			self executeNewMethod]
		ifFalse: [self unPop: 2].

]

{ #category : #'system control primitives' }
Interpreter >> primitiveExitToDebugger [

	self error: 'Exit to debugger at user request'.
]

{ #category : #'float primitives' }
Interpreter >> primitiveExp [
	"Computes E raised to the receiver power."

	| rcvr |
	self var: #rcvr type: 'double '.
	rcvr _ self popFloat.
	successFlag
		ifTrue: [self pushFloat: (self cCode: 'exp(rcvr)' inSmalltalk: [rcvr exp])]
		ifFalse: [self unPop: 1]
]

{ #category : #'float primitives' }
Interpreter >> primitiveExponent [
	"Exponent part of this float."

	| rcvr frac pwr |
	self var: #rcvr type: 'double '.
	self var: #frac type: 'double '.
	self var: #pwr type: 'int '.
	rcvr _ self popFloat.
	successFlag
		ifTrue: [  "rcvr = frac * 2^pwr, where frac is in [0.5..1.0)"
			self cCode: 'frac = frexp(rcvr, &pwr)'
					inSmalltalk: [pwr _ rcvr exponent].
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
	self var: #addr type: 'void *'.
	
	"Fetch the first literal of the method"
	self success: (self literalCountOf: newMethod) > 0. "@@: Could this be omitted for speed?!"
	successFlag ifFalse: [^ nil].

	lit _ self literal: 0 ofMethod: newMethod. 
	"Check if it's an array of length 4"
	self success: ((self isArray: lit) and: [(self lengthOf: lit) = 4]).
	successFlag ifFalse: [^ nil].

	"Look at the function index in case it has been loaded before"
	index _ self fetchPointer: 3 ofObject: lit.
	index _ self checkedIntegerValueOf: index.
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
		ifTrue: [addr _ externalPrimitiveTable at: index - 1.
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
	moduleName _ self fetchPointer: 0 ofObject: lit.
	moduleName = nilObj
		ifTrue: [moduleLength _ 0]
		ifFalse: [self success: (self isBytes: moduleName).
				moduleLength _ self lengthOf: moduleName.
				self cCode: '' inSmalltalk:
					[ (#('FloatArrayPlugin' 'Matrix2x3Plugin') includes: (self stringOf: moduleName))
						ifTrue: [moduleLength _ 0  "Cause all of these to fail"]]].
	functionName _ self fetchPointer: 1 ofObject: lit.
	self success: (self isBytes: functionName).
	functionLength _ self lengthOf: functionName.
	successFlag ifFalse: [^ nil].

	"Backward compatibility: 
	Attempt to map any old-style named primitives into the new 
	ones. The old ones are exclusively bound into the VM so we 
	don't need to check if a module is given."
	addr _ 0. "Addr ~= 0 indicates we have a compat match later"
	moduleLength = 0
		ifTrue: ["Search the obsolete named primitive table for a match "
		index _ self findObsoleteNamedPrimitive: ((self pointerForOop: functionName) + BaseHeaderSize) length: functionLength.
			"The returned value is the index into the obsolete primitive table. 
			If the index is found, use the 'C-style' version of the lookup. "
			index < 0 ifFalse: [addr _ self ioLoadFunction: (self cCoerce: ((obsoleteNamedPrimitiveTable at: index) at: 2) to: 'char*')
								From: (self cCoerce: ((obsoleteNamedPrimitiveTable at: index) at: 1) to: 'char*')]].
	addr = 0 ifTrue: ["Only if no compat version was found"
			addr _ self ioLoadExternalFunction: functionName + BaseHeaderSize
						OfLength: functionLength
						FromModule: moduleName + BaseHeaderSize
						OfLength: moduleLength].
	addr = 0
		ifTrue: [index _ -1]
		ifFalse: ["add the function to the external primitive table"
			index _ self addToExternalPrimitiveTable: addr].
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

	successFlag _ false.
]

{ #category : #'image segment in/out' }
Interpreter >> primitiveFailAfterCleanup: outPointerArray [
	"If the storeSegment primitive fails, it must clean up first."

	| i lastAddr |   "Store nils throughout the outPointer array."
	lastAddr _ outPointerArray + (self lastPointerOf: outPointerArray).
	i _ outPointerArray + BaseHeaderSize.
	[i <= lastAddr] whileTrue:
		[self longAt: i put: nilObj.
		i _ i + BytesPerWord].

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	self primitiveFail
]

{ #category : #'process primitives' }
Interpreter >> primitiveFindHandlerContext [
	"Primitive. Search up the context stack for the next method context marked for exception handling starting at the receiver. Return nil if none found"
	| thisCntx nilOop |
	thisCntx _ self popStack.
	nilOop _ nilObj.

	[(self isHandlerMarked: thisCntx) ifTrue:[
			self push: thisCntx.
			^nil].
		thisCntx _ self fetchPointer: SenderIndex ofObject: thisCntx.
		thisCntx = nilOop] whileFalse.

	^self push: nilObj
]

{ #category : #'process primitives' }
Interpreter >> primitiveFindNextUnwindContext [
	"Primitive. Search up the context stack for the next method context marked for unwind handling from the receiver up to but not including the argument. Return nil if none found."
	| thisCntx nilOop aContext unwindMarked |
	aContext _ self popStack.
	thisCntx _ self fetchPointer: SenderIndex ofObject: self popStack.
	nilOop _ nilObj.

	[(thisCntx = aContext) or: [thisCntx = nilOop]] whileFalse: [
		unwindMarked _ self isUnwindMarked: thisCntx.
		unwindMarked ifTrue:[
			self push: thisCntx.
			^nil].
		thisCntx _ self fetchPointer: SenderIndex ofObject: thisCntx].

	^self push: nilOop
]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatAdd [
	^ self primitiveFloatAdd: (self stackValue: 1) toArg: self stackTop
]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatAdd: rcvrOop toArg: argOop [
	| rcvr arg |
	self var: #rcvr type: 'double '.
	self var: #arg type: 'double '.

	rcvr _ self loadFloatOrIntFrom: rcvrOop.
	arg _ self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [
		self pop: 2.
		self pushFloat: rcvr + arg].
]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatDivide [
	^ self primitiveFloatDivide: (self stackValue: 1) byArg: self stackTop
]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatDivide: rcvrOop byArg: argOop [
	| rcvr arg |
	self var: #rcvr type: 'double '.
	self var: #arg type: 'double '.

	rcvr _ self loadFloatOrIntFrom: rcvrOop.
	arg _ self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [
		self success: arg ~= 0.0.
		successFlag ifTrue: [
			self pop: 2.
			self pushFloat: (self cCode: 'rcvr / arg' inSmalltalk: [rcvr / arg])]].
]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatEqual [
	| aBool |
	aBool _ self primitiveFloatEqual: (self stackValue: 1) toArg: self stackTop.
	successFlag ifTrue: [self pop: 2. self pushBool: aBool].

]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	self var: #rcvr type: 'double '.
	self var: #arg type: 'double '.

	rcvr _ self loadFloatOrIntFrom: rcvrOop.
	arg _ self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [^ rcvr = arg]
]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatGreater: rcvrOop thanArg: argOop [
	| rcvr arg |
	self var: #rcvr type: 'double '.
	self var: #arg type: 'double '.

	rcvr _ self loadFloatOrIntFrom: rcvrOop.
	arg _ self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [^ rcvr > arg].

]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatGreaterOrEqual [
	| aBool |
	aBool _ self primitiveFloatLess: (self stackValue: 1) thanArg: self stackTop.
	successFlag ifTrue: [self pop: 2. self pushBool: aBool not].

]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatGreaterThan [
	| aBool |
	aBool _ self primitiveFloatGreater: (self stackValue: 1) thanArg: self stackTop.
	successFlag ifTrue: [self pop: 2. self pushBool: aBool].

]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatLess: rcvrOop thanArg: argOop [
	| rcvr arg |
	self var: #rcvr type: 'double '.
	self var: #arg type: 'double '.

	rcvr _ self loadFloatOrIntFrom: rcvrOop.
	arg _ self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [^ rcvr < arg].

]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatLessOrEqual [
	| aBool |
	aBool _ self primitiveFloatGreater: (self stackValue: 1) thanArg: self stackTop.
	successFlag ifTrue: [self pop: 2. self pushBool: aBool not].

]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatLessThan [
	| aBool |
	aBool _ self primitiveFloatLess: (self stackValue: 1) thanArg: self stackTop.
	successFlag ifTrue: [self pop: 2. self pushBool: aBool].

]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatMultiply [
	^ self primitiveFloatMultiply: (self stackValue: 1) byArg: self stackTop
]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatMultiply: rcvrOop byArg: argOop [
	| rcvr arg |
	self var: #rcvr type: 'double '.
	self var: #arg type: 'double '.

	rcvr _ self loadFloatOrIntFrom: rcvrOop.
	arg _ self loadFloatOrIntFrom: argOop.
	successFlag ifTrue: [
		self pop: 2.
		self pushFloat: rcvr * arg].
]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatNotEqual [
	| aBool |
	aBool _ self primitiveFloatEqual: (self stackValue: 1) toArg: self stackTop.
	successFlag ifTrue: [self pop: 2. self pushBool: aBool not].

]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatSubtract [
	^ self primitiveFloatSubtract: (self stackValue: 1) fromArg: self stackTop
]

{ #category : #'float primitives' }
Interpreter >> primitiveFloatSubtract: rcvrOop fromArg: argOop [
	| rcvr arg |
	self var: #rcvr type: 'double '.
	self var: #arg type: 'double '.

	rcvr _ self loadFloatOrIntFrom: rcvrOop.
	arg _ self loadFloatOrIntFrom: argOop.
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
	oldMethod _ self stackTop.
	probe _ 0.
	1 to: MethodCacheEntries do:
		[:i | (methodCache at: probe + MethodCacheMethod) = oldMethod ifTrue:
			[methodCache at: probe + MethodCacheSelector put: 0].
		probe _ probe + MethodCacheEntrySize].
	self compilerFlushCacheHook: oldMethod.		"Flush the dynamic compiler's inline caches."
]

{ #category : #'system control primitives' }
Interpreter >> primitiveFlushCacheSelective [
	"The receiver is a message selector.  Clear all entries in the method lookup cache with this selector, presumably because an associated method has been redefined."
	| selector probe |
	selector _ self stackTop.
	probe _ 0.
	1 to: MethodCacheEntries do:
		[:i | (methodCache at: probe + MethodCacheSelector) = selector ifTrue:
			[methodCache at: probe + MethodCacheSelector put: 0].
		probe _ probe + MethodCacheEntrySize]
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

	self export: true.
	forceTenureFlag _ 1
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveFormPrint [
	"On platforms that support it, this primitive prints the receiver, assumed to be a Form, to the default printer."

	| landscapeFlag vScale hScale rcvr bitsArray w h
	 depth pixelsPerWord wordsPerLine bitsArraySize ok |

	self var: #vScale type: 'double '.
	self var: #hScale type: 'double '.
	landscapeFlag _ self booleanValueOf: self stackTop.
	vScale _ self floatValueOf: (self stackValue: 1).
	hScale _ self floatValueOf: (self stackValue: 2).
	rcvr _ self stackValue: 3.
	(rcvr isIntegerObject: rcvr) ifTrue: [self success: false].
	successFlag ifTrue: [
		((self  isPointers: rcvr) and: [(self lengthOf: rcvr) >= 4])
			ifFalse: [self success: false]].
	successFlag ifTrue: [
		bitsArray _ self fetchPointer: 0 ofObject: rcvr.
		w _ self fetchInteger: 1 ofObject: rcvr.
		h _ self fetchInteger: 2 ofObject: rcvr.
		depth _ self fetchInteger: 3 ofObject: rcvr.
		(w > 0 and: [h > 0]) ifFalse: [self success: false].
		pixelsPerWord _ 32 // depth.
		wordsPerLine _ (w + (pixelsPerWord - 1)) // pixelsPerWord.
		((rcvr isIntegerObject: rcvr) not and: [self isWordsOrBytes: bitsArray])
			ifTrue: [
				bitsArraySize _ self byteLengthOf: bitsArray.
				self success: (bitsArraySize = (wordsPerLine * h * 4))]
			ifFalse: [self success: false]].	
	successFlag ifTrue: [
		BytesPerWord = 8
			ifTrue: [ok _ self cCode: 'ioFormPrint(bitsArray + 8, w, h, depth, hScale, vScale, landscapeFlag)']
			ifFalse: [ok _ self cCode: 'ioFormPrint(bitsArray + 4, w, h, depth, hScale, vScale, landscapeFlag)'].
		self success: ok].
	successFlag ifTrue: [
		self pop: 3].  "pop hScale, vScale, and landscapeFlag; leave rcvr on stack"

]

{ #category : #'float primitives' }
Interpreter >> primitiveFractionalPart [
	| rcvr frac trunc |
	self var: #rcvr type: 'double '.
	self var: #frac type: 'double '.
	self var: #trunc type: 'double '.
	rcvr _ self popFloat.
	successFlag
		ifTrue: [self cCode: 'frac = modf(rcvr, &trunc)' inSmalltalk: [frac _ rcvr fractionPart].
				self pushFloat: frac]
		ifFalse: [self unPop: 1]
]

{ #category : #'memory space primitives' }
Interpreter >> primitiveFullGC [
	"Do a full garbage collection and return the number of bytes available (including swap space if dynamic memory management is supported)."

	self pop: 1.
	self incrementalGC.  "maximimize space for forwarding table"
	self fullGC.
	self pushInteger: (self bytesLeft: true).
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
				Into: s + BaseHeaderSize
				Length: sz.
			self pop: 2 thenPush: s]
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveGetNextEvent [
	"Primitive. Return the next input event from the VM event queue."
	| evtBuf arg value |
	self var: #evtBuf declareC:'int evtBuf[8] = { 0, 0, 0, 0, 0, 0, 0, 0 }'.
	self cCode:'' inSmalltalk:[evtBuf _ CArrayAccessor on: (IntegerArray new: 8)].
	arg _ self stackTop.
	((self isArray: arg) and:[(self slotSizeOf: arg) = 8])  ifFalse:[^self primitiveFail].

	self ioGetNextEvent: (self cCoerce: evtBuf to: 'sqInputEvent*').
	successFlag ifFalse:[^nil].

	"Event type"
	self storeInteger: 0 ofObject: arg withValue: (evtBuf at: 0).
	successFlag ifFalse:[^nil].

	"Event time stamp"
	self storeInteger: 1 ofObject: arg withValue: ((evtBuf at: 1) bitAnd: MillisecondClockMask).
	successFlag ifFalse:[^nil].

	"Event arguments"
	2 to: 7 do:[:i|
		value _ evtBuf at: i.
		(self isIntegerValue: value)
			ifTrue:[self storeInteger: i ofObject: arg withValue: value]
			ifFalse:["Need to remap because allocation may cause GC"
				self pushRemappableOop: arg.
				value _ self positive32BitIntegerFor: value.
				arg _ self popRemappableOop.
				self storePointer: i ofObject: arg withValue: value]].

	successFlag ifFalse:[^nil].
	self pop: 1.
]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveGreaterOrEqual [
	| integerReceiver integerArgument |
	integerArgument _ self popInteger.
	integerReceiver _ self popInteger.
	self checkBooleanResult: integerReceiver >= integerArgument
]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveGreaterThan [
	| integerReceiver integerArgument |
	integerArgument _ self popInteger.
	integerReceiver _ self popInteger.
	self checkBooleanResult: integerReceiver > integerArgument
]

{ #category : #'other primitives' }
Interpreter >> primitiveImageName [
	"When called with a single string argument, record the string as the current image file name. When called with zero arguments, return a string containing the current image file name."

	| s sz sCRIfn okToRename |
	self var: #sCRIfn type: 'void *'.
	argumentCount = 1 ifTrue: [
		"If the security plugin can be loaded, use it to check for rename permission.
		If not, assume it's ok"
		sCRIfn _ self ioLoadFunction: 'secCanRenameImage' From: 'SecurityPlugin'.
		sCRIfn ~= 0 ifTrue:[okToRename _ self cCode:' ((sqInt (*)(void))sCRIfn)()'.
			okToRename ifFalse:[^self primitiveFail]].
		s _ self stackTop.
		self assertClassOf: s is: (self splObj: ClassString).
		successFlag ifTrue: [
			sz _ self stSizeOf: s.
			self imageNamePut: (s + BaseHeaderSize) Length: sz.
			self pop: 1.  "pop s, leave rcvr on stack"
		].
	] ifFalse: [
		sz _ self imageNameSize.
		s _ self instantiateClass: (self splObj: ClassString) indexableSize: sz.
		self imageNameGet: (s + BaseHeaderSize) Length: sz.
		self pop: 1.  "rcvr"
		self push: s.
	].

]

{ #category : #'memory space primitives' }
Interpreter >> primitiveIncrementalGC [
	"Do a quick, incremental garbage collection and return the number of bytes immediately available. (Note: more space may be made available by doing a full garbage collection."

	self pop: 1.
	self incrementalGC.
	self pushInteger: (self bytesLeft: false).
]

{ #category : #'compiled methods' }
Interpreter >> primitiveIndexOf: methodPointer [
	"Note: We now have 10 bits of primitive index, but they are in two places
	for temporary backward compatibility.  The time to unpack is negligible,
	since the reconstituted full index is stored in the method cache."
	| primBits |
	primBits _ ((self headerOf: methodPointer) >> 1) bitAnd: 16r100001FF.
	
	^ (primBits bitAnd: 16r1FF) + (primBits >> 19)

]

{ #category : #'I/O primitives' }
Interpreter >> primitiveInputSemaphore [
	"Register the input semaphore. If the argument is not a 
	Semaphore, unregister the current input semaphore."
	| arg |
	arg _ self stackTop.
	(self isIntegerObject: arg)
		ifTrue: ["If arg is integer, then use it as an index 
			into the external objects array and install it 
			as the new event semaphore"
			self ioSetInputSemaphore: (self integerValueOf: arg).
			successFlag
				ifTrue: [self pop: 1].
			^ nil].

	"old code for compatibility"
	arg _ self popStack.
	(self fetchClassOf: arg) = (self splObj: ClassSemaphore)
		ifTrue: [self
				storePointer: TheInputSemaphore
				ofObject: specialObjectsOop
				withValue: arg]
		ifFalse: [self
				storePointer: TheInputSemaphore
				ofObject: specialObjectsOop
				withValue: nilObj]
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveInputWord [
	"Return an integer indicating the reason for the most recent input interrupt."

	self pop: 1 thenPushInteger: 0.	"noop for now"
]

{ #category : #'object access primitives' }
Interpreter >> primitiveInstVarAt [
	| index rcvr hdr fmt totalLength fixedFields value |
	index _ self stackIntegerValue: 0.
	rcvr _ self stackValue: 1.
	successFlag
		ifTrue: [hdr _ self baseHeader: rcvr.
			fmt _ hdr >> 8 bitAnd: 15.
			totalLength _ self lengthOf: rcvr baseHeader: hdr format: fmt.
			fixedFields _ self fixedFieldsOf: rcvr format: fmt length: totalLength.
			(index >= 1 and: [index <= fixedFields])
				ifFalse: [successFlag _ false]].
	successFlag ifTrue: [value _ self subscript: rcvr with: index format: fmt].
	successFlag ifTrue: [self pop: argumentCount + 1 thenPush: value]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveInstVarAtPut [
	| newValue index rcvr hdr fmt totalLength fixedFields |
	newValue _ self stackTop.
	index _ self stackIntegerValue: 1.
	rcvr _ self stackValue: 2.
	successFlag
		ifTrue: [hdr _ self baseHeader: rcvr.
			fmt _ hdr >> 8 bitAnd: 15.
			totalLength _ self lengthOf: rcvr baseHeader: hdr format: fmt.
			fixedFields _ self fixedFieldsOf: rcvr format: fmt length: totalLength.
			(index >= 1 and: [index <= fixedFields]) ifFalse: [successFlag _ false]].
	successFlag ifTrue: [self subscript: rcvr with: index storing: newValue format: fmt].
	successFlag ifTrue: [self pop: argumentCount + 1 thenPush: newValue]
]

{ #category : #'quick primitives' }
Interpreter >> primitiveInstVarsPutFromStack [
	"Note:  this primitive has been decommissioned.  It is only here for short-term compatibility with an internal 2.3beta-d image that used this.  It did not save much time and it complicated several things.  Plus Jitter will do it right anyway."
	| rcvr offsetBits |
	rcvr _ self stackValue: argumentCount.
	"Mark dirty so stores below can be unchecked"
	(rcvr < youngStart) ifTrue: [ self beRootIfOld: rcvr ].
	0 to: argumentCount-1 do:
		[:i | (i bitAnd: 3) = 0 ifTrue:
			[offsetBits _ self positive32BitValueOf: (self literal: i//4 ofMethod: newMethod)].
		self storePointerUnchecked: (offsetBits bitAnd: 16rFF) ofObject: rcvr
						withValue: (self stackValue: i).
		offsetBits _ offsetBits >> 8].
	self pop: argumentCount
]

{ #category : #'sound primitives' }
Interpreter >> primitiveIntegerAt [
	"Return the 32bit signed integer contents of a words receiver"

	| index rcvr sz addr value |
	index _ self stackIntegerValue: 0.
	rcvr _ self stackValue: 1.
	(self isIntegerObject: rcvr) ifTrue: [^self success: false].
	(self isWords: rcvr) ifFalse: [^self success: false].
	sz _ self lengthOf: rcvr.  "number of fields"
	self success: ((index >= 1) and: [index <= sz]).
	successFlag ifTrue: [
		addr _ rcvr + BaseHeaderSize - 4 "for zero indexing" + (index * 4).
		value _ self intAt: addr.
		self pop: 2.  "pop rcvr, index"
		"push element value"
		(self isIntegerValue: value)
			ifTrue: [self pushInteger: value]
			ifFalse: [self push: (self signed32BitIntegerFor: value)].
	].
]

{ #category : #'sound primitives' }
Interpreter >> primitiveIntegerAtPut [
	"Return the 32bit signed integer contents of a words receiver"
	| index rcvr sz addr value valueOop |
	valueOop _ self stackValue: 0.
	index _ self stackIntegerValue: 1.
	rcvr _ self stackValue: 2.
	(self isIntegerObject: rcvr) ifTrue:[^self success: false].
	(self isWords: rcvr) ifFalse:[^self success: false].
	sz _ self lengthOf: rcvr.  "number of fields"
	((index >= 1) and: [index <= sz]) ifFalse:[^self success: false].
	(self isIntegerObject: valueOop)
		ifTrue:[value _ self integerValueOf: valueOop]
		ifFalse:[value _ self signed32BitValueOf: valueOop].
	successFlag ifTrue:[
		addr _ rcvr + BaseHeaderSize - 4 "for zero indexing" + (index * 4).
		value _ self intAt: addr put: value.
		self pop: 3 thenPush: valueOop. "pop all; return value"
	].

]

{ #category : #'I/O primitives' }
Interpreter >> primitiveInterruptSemaphore [
	"Register the user interrupt semaphore. If the argument is 
	not a Semaphore, unregister the current interrupt 
	semaphore. "
	| arg |
	arg _ self popStack.
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
	runArgs _ self instantiateClass: (self splObj: ClassArray) indexableSize: argumentCount.
	self beRootIfOld: runArgs. "do we really need this?"
	self transfer: argumentCount from: stackPointer - ((argumentCount - 1) * BytesPerWord) to: runArgs + BaseHeaderSize.

	runSelector _ messageSelector.
	runReceiver _ self stackValue: argumentCount.
	self pop: argumentCount+1.

	"stack is clean here"

	newReceiver _ newMethod.
	messageSelector _ self splObj: SelectorRunWithIn.
	argumentCount _ 3.

	self push: newReceiver.
	self push: runSelector.
	self push: runArgs.
	self push: runReceiver.

	lookupClass _ self fetchClassOf: newReceiver.
	self findNewMethodInClass: lookupClass.
	self executeNewMethodFromCache.  "Recursive xeq affects successFlag"
	successFlag _ true.

]

{ #category : #'memory space primitives' }
Interpreter >> primitiveIsRoot [
	"Primitive. Answer whether the argument to the primitive is a root for young space"
	| oop |
	self export: true.
	oop := self stackObjectValue: 0.
	successFlag ifTrue:[
		self pop: argumentCount + 1.
		self pushBool: ((self baseHeader: oop) bitAnd: RootBit).
	].
]

{ #category : #'memory space primitives' }
Interpreter >> primitiveIsYoung [
	"Primitive. Answer whether the argument to the primitive resides in young space."
	| oop |
	self export: true.
	oop := self stackObjectValue: 0.
	successFlag ifTrue:[
		self pop: argumentCount + 1.
		self pushBool: oop >= youngStart.
	].
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveKbdNext [
	"Obsolete on virtually all platforms; old style input polling code.
	Return the next keycode and remove it from the input buffer. The low byte is the 8-bit ISO character. The next four bits are the Smalltalk modifier bits <cmd><option><ctrl><shift>."

	| keystrokeWord |
	self pop: 1.
	keystrokeWord _ self ioGetKeystroke.
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
	keystrokeWord _ self ioPeekKeystroke.
	keystrokeWord >= 0
		ifTrue: [self pushInteger: keystrokeWord]
		ifFalse: [self push: nilObj].
]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveLessOrEqual [
	| integerReceiver integerArgument |
	integerArgument _ self popInteger.
	integerReceiver _ self popInteger.
	self checkBooleanResult: integerReceiver <= integerArgument
]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveLessThan [
	| integerReceiver integerArgument |
	integerArgument _ self popInteger.
	integerReceiver _ self popInteger.
	self checkBooleanResult: integerReceiver < integerArgument
]

{ #category : #'plugin primitives' }
Interpreter >> primitiveListBuiltinModule [
	"Primitive. Return the n-th builtin module name."
	| moduleName index length nameOop |
	self var: #moduleName type: 'char *'.
	self methodArgumentCount = 1 ifFalse:[^self primitiveFail].
	index _ self stackIntegerValue: 0.
	index <= 0 ifTrue:[^self primitiveFail].
	moduleName _ self ioListBuiltinModule: index.
	moduleName == nil ifTrue:[
		self pop: 2. "arg+rcvr"
		^self push: self nilObject].
	length _ self strlen: moduleName.
	nameOop _ self instantiateClass: self classString indexableSize: length.
	0 to: length-1 do:[:i|
		self storeByte: i ofObject: nameOop withValue: (moduleName at: i)].
	self forceInterruptCheck.
	self pop: 2 thenPush: nameOop
]

{ #category : #'plugin primitives' }
Interpreter >> primitiveListExternalModule [
	"Primitive. Return the n-th loaded external module name."
	| moduleName index length nameOop |
	self var: #moduleName type: 'char *'.
	self methodArgumentCount = 1 ifFalse:[^self primitiveFail].
	index _ self stackIntegerValue: 0.
	index <= 0 ifTrue:[^self primitiveFail].
	moduleName _ self ioListLoadedModule: index.
	moduleName == nil ifTrue:[
		self pop: 2. "arg+rcvr"
		^self push: self nilObject].
	length _ self strlen: moduleName.
	nameOop _ self instantiateClass: self classString indexableSize: length.
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

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	outPointerArray _ self stackTop.
	lastOut _ outPointerArray + (self lastPointerOf: outPointerArray).
	segmentWordArray _ self stackValue: 1.
	endSeg _ segmentWordArray + (self sizeBitsOf: segmentWordArray) - BaseHeaderSize.

	"Essential type checks"
	((self formatOf: outPointerArray) = 2				"Must be indexable pointers"
		and: [(self formatOf: segmentWordArray) = 6])	"Must be indexable words"
		ifFalse: [^ self primitiveFail].

	"Version check.  Byte order of the WordArray now"
	data _ self longAt: segmentWordArray + BaseHeaderSize.
	(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse: [
		"Not readable -- try again with reversed bytes..."
		self reverseBytesFrom: segmentWordArray + BaseHeaderSize to: endSeg + BytesPerWord.
		data _ self longAt: segmentWordArray + BaseHeaderSize.
		(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse: [
			"Still NG -- put things back and fail"
			self reverseBytesFrom: segmentWordArray + BaseHeaderSize to: endSeg + BytesPerWord.
			DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^ self primitiveFail]].
	"Reverse the Byte type objects if the data from opposite endian machine"
	"Test top byte.  $d on the Mac or $s on the PC.  Rest of word is equal"
	data = self imageSegmentVersion ifFalse: [
		"Reverse the byte-type objects once"
		segOop _ self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
			 "Oop of first embedded object"
		self byteSwapByteObjectsFrom: segOop to: endSeg + BytesPerWord].

	"Proceed through the segment, remapping pointers..."
	segOop _ self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
	[segOop <= endSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type = 0 or 1) -- start with that."
					fieldPtr _ segOop - BytesPerWord.  doingClass _ true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr _ segOop + BaseHeaderSize.  doingClass _ false].
		lastPtr _ segOop + (self lastPointerOf: segOop).	"last field"
		lastPtr > endSeg ifTrue: [
			DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^ self primitiveFail "out of bounds"].

		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop _ self longAt: fieldPtr.
			doingClass ifTrue:
				[hdrTypeBits _ self headerType: fieldPtr.
				fieldOop _ fieldOop - hdrTypeBits].
			(self isIntegerObject: fieldOop)
				ifTrue:
					["Integer -- nothing to do"
					fieldPtr _ fieldPtr + BytesPerWord]
				ifFalse:
					[(fieldOop bitAnd: 3) = 0 ifFalse: [^ self primitiveFail "bad oop"].
					(fieldOop bitAnd: 16r80000000) = 0
						ifTrue: ["Internal pointer -- add segment offset"
								mapOop _ fieldOop + segmentWordArray]
						ifFalse: ["External pointer -- look it up in outPointers"
								outPtr _ outPointerArray + (fieldOop bitAnd: 16r7FFFFFFF).
								outPtr > lastOut ifTrue: [^ self primitiveFail "out of bounds"].
								mapOop _ self longAt: outPtr].
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr _ fieldPtr + 8.
								doingClass _ false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr _ fieldPtr + BytesPerWord].
					segOop < youngStart
						ifTrue: [self possibleRootStoreInto: segOop value: mapOop].
					]].
		segOop _ self objectAfter: segOop].

	"Again, proceed through the segment checking consistency..."
	segOop _ self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
	[segOop <= endSeg] whileTrue:
		[(self oopHasAcceptableClass: segOop) ifFalse: [^ self primitiveFail "inconsistency"].
		fieldPtr _ segOop + BaseHeaderSize.		"first field"
		lastPtr _ segOop + (self lastPointerOf: segOop).	"last field"
		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop _ self longAt: fieldPtr.
			(self oopHasAcceptableClass: fieldOop) ifFalse: [^ self primitiveFail "inconsistency"].
			fieldPtr _ fieldPtr + BytesPerWord].
		segOop _ self objectAfter: segOop].

	"Truncate the segment word array to size = BytesPerWord (vers stamp only)"
	extraSize _ self extraHeaderBytes: segmentWordArray.
	hdrTypeBits _ self headerType: segmentWordArray.
	extraSize = 8
		ifTrue: [self longAt: segmentWordArray-extraSize put: BaseHeaderSize + BytesPerWord + hdrTypeBits]
		ifFalse: [header _ self longAt: segmentWordArray.
				self longAt: segmentWordArray
					put: header - (header bitAnd: SizeMask) + BaseHeaderSize + BytesPerWord].	
	"and return the roots array which was first in the segment"
	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	self pop: 3 thenPush: (self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord).

]

{ #category : #'quick primitives' }
Interpreter >> primitiveLoadInstVar [
	| thisReceiver |
	thisReceiver _ self popStack.
	self push: (self fetchPointer: primitiveIndex-264 ofObject: thisReceiver)
]

{ #category : #'float primitives' }
Interpreter >> primitiveLogN [
	"Natural log."

	| rcvr |
	self var: #rcvr type: 'double '.
	rcvr _ self popFloat.
	successFlag
		ifTrue: [self pushFloat: (self cCode: 'log(rcvr)' inSmalltalk: [rcvr ln])]
		ifFalse: [self unPop: 1]
]

{ #category : #'memory space primitives' }
Interpreter >> primitiveLowSpaceSemaphore [
	"Register the low-space semaphore. If the argument is not a 
	Semaphore, unregister the current low-space Semaphore."
	| arg |
	arg _ self popStack.
	(self fetchClassOf: arg) = (self splObj: ClassSemaphore)
		ifTrue: [self storePointer: TheLowSpaceSemaphore ofObject: specialObjectsOop withValue: arg]
		ifFalse: [self storePointer: TheLowSpaceSemaphore ofObject: specialObjectsOop withValue: nilObj]
]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveMakePoint [
	| rcvr argument pt |
	argument _ self stackTop.
	rcvr _ self stackValue: 1.
	(self isIntegerObject: rcvr)
		ifTrue: [(self isIntegerObject: argument)
				ifTrue: [pt _ self makePointwithxValue: (self integerValueOf: rcvr) yValue: (self integerValueOf: argument)]
				ifFalse: [pt _ self makePointwithxValue: (self integerValueOf: rcvr) yValue: 0.
					"Above may cause GC!"
					self storePointer: 1 ofObject: pt withValue: (self stackValue: 0)]]
		ifFalse: [(self isFloatObject: rcvr)
				ifFalse: [^ self success: false].
			pt _ self makePointwithxValue: 0 yValue: 0.
			"Above may cause GC!"
			self storePointer: 0 ofObject: pt withValue: (self stackValue: 1).
			self storePointer: 1 ofObject: pt withValue: (self stackValue: 0)].

	self pop: 2 thenPush: pt
]

{ #category : #'process primitives' }
Interpreter >> primitiveMarkHandlerMethod [
	"Primitive. Mark the method for exception handling. The primitive must fail after marking the context so that the regular code is run."
	self inline: false.
	^self primitiveFail
]

{ #category : #'process primitives' }
Interpreter >> primitiveMarkUnwindMethod [
	"Primitive. Mark the method for exception unwinding. The primitive must fail after marking the context so that the regular code is run."
	self inline: false.
	^self primitiveFail
]

{ #category : #'plugin primitive support' }
Interpreter >> primitiveMethod [
	"Return the method an external primitive was defined in"
	^newMethod
]

{ #category : #'system control primitives' }
Interpreter >> primitiveMillisecondClock [
	"Return the value of the millisecond clock as an integer. Note that the millisecond clock wraps around periodically. On some platforms it can wrap daily. The range is limited to SmallInteger maxVal / 2 to allow delays of up to that length without overflowing a SmallInteger."

	self pop: 1 thenPush: (self integerObjectOf: (self ioMSecs bitAnd: MillisecondClockMask)).

]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveMod [
	| mod |
	mod _ self doPrimitiveMod: (self stackValue: 1) by: (self stackTop).
	self pop2AndPushIntegerIfOK: mod
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveMouseButtons [
	"Obsolete on virtually all platforms; old style input polling code.
	Return the mouse button state. The low three bits encode the state of the <red><yellow><blue> mouse buttons. The next four bits encode the Smalltalk modifier bits <cmd><option><ctrl><shift>."

	| buttonWord |
	self pop: 1.
	buttonWord _ self ioGetButtonState.
	self pushInteger: buttonWord.
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveMousePoint [
	"Obsolete on virtually all platforms; old style input polling code.
	Return a Point indicating current position of the mouse. Note that mouse coordinates may be negative if the mouse moves above or to the left of the top-left corner of the Smalltalk window."

	| pointWord x y |
	self pop: 1.
	pointWord _ self ioMousePoint.
	x _ self signExtend16: ((pointWord >> 16) bitAnd: 16rFFFF).
	y _ self signExtend16: (pointWord bitAnd: 16rFFFF).
	self push: (self makePointwithxValue: x  yValue: y).
]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveMultiply [
	| integerRcvr integerArg integerResult |
	integerRcvr _ self stackIntegerValue: 1.
	integerArg _ self stackIntegerValue: 0.
	successFlag ifTrue:
		[integerResult _ integerRcvr * integerArg.
		"check for C overflow by seeing if computation is reversible"
		((integerArg = 0) or: [(integerResult // integerArg) = integerRcvr])
			ifTrue: [self pop2AndPushIntegerIfOK: integerResult]
			ifFalse: [self primitiveFail]]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveNew [
	"Allocate a new fixed-size instance. Fail if the allocation would leave less than lowSpaceThreshold bytes free. May cause a GC"

	| class spaceOkay |
	class _ self stackTop.
	"The following may cause GC!"
	spaceOkay _ self sufficientSpaceToInstantiate: class indexableSize: 0.
	self success: spaceOkay.
	successFlag ifTrue: [ self push: (self instantiateClass: self popStack indexableSize: 0) ]
]

{ #category : #'compiled methods' }
Interpreter >> primitiveNewMethod [
	| header bytecodeCount class size theMethod literalCount |
	header _ self popStack.
	bytecodeCount _ self popInteger.
	self success: (self isIntegerObject: header).
	successFlag ifFalse: [self unPop: 2].
	class _ self popStack.
	size _ (self literalCountOfHeader: header) + 1 * BytesPerWord + bytecodeCount.
	theMethod _ self instantiateClass: class indexableSize: size.
	self storePointer: HeaderIndex ofObject: theMethod withValue: header.
	literalCount _ self literalCountOfHeader: header.
	1 to: literalCount do:
		[:i | self storePointer: i ofObject: theMethod withValue: nilObj].
	self push: theMethod
]

{ #category : #'object access primitives' }
Interpreter >> primitiveNewWithArg [
	"Allocate a new indexable instance. Fail if the allocation would leave less than lowSpaceThreshold bytes free."
	| size class spaceOkay |
	size _ self positive32BitValueOf: self stackTop.
	class _ self stackValue: 1.
	self success: size >= 0.
	successFlag
		ifTrue: ["The following may cause GC!"
			spaceOkay _ self sufficientSpaceToInstantiate: class indexableSize: size.
			self success: spaceOkay.
			class _ self stackValue: 1].
	successFlag ifTrue: [self pop: 2 thenPush: (self instantiateClass: class indexableSize: size)]
]

{ #category : #'array and stream primitives' }
Interpreter >> primitiveNext [
	"PrimitiveNext will succeed only if the stream's array is in the atCache.
	Otherwise failure will lead to proper message lookup of at: and
	subsequent installation in the cache if appropriate."
	| stream array index limit result atIx |
	stream _ self stackTop.
	((self isPointers: stream)
		and: [(self lengthOf: stream) >= (StreamReadLimitIndex + 1)])
		ifFalse: [^ self primitiveFail].

	array _ self fetchPointer: StreamArrayIndex ofObject: stream.
	index _ self fetchInteger: StreamIndexIndex ofObject: stream.
	limit _ self fetchInteger: StreamReadLimitIndex ofObject: stream.
	atIx _ array bitAnd: AtCacheMask.
	(index < limit and: [(atCache at: atIx+AtCacheOop) = array])
		ifFalse: [^ self primitiveFail].

	"OK -- its not at end, and the array is in the cache"
	index _ index + 1.
	result _ self commonVariable: array at: index cacheIndex: atIx.
	"Above may cause GC, so can't use stream, array etc. below it"
	successFlag ifTrue:
		[stream _ self stackTop.
		self storeInteger: StreamIndexIndex ofObject: stream withValue: index.
		^ self pop: 1 thenPush: result].

]

{ #category : #'object access primitives' }
Interpreter >> primitiveNextInstance [
	| object instance |
	object _ self stackTop.
	instance _ self instanceAfter: object.
	instance = nilObj
		ifTrue: [self primitiveFail]
		ifFalse: [self pop: argumentCount+1 thenPush: instance]
]

{ #category : #'object access primitives' }
Interpreter >> primitiveNextObject [
	"Return the object following the receiver in the heap. Return the SmallInteger zero when there are no more objects."

	| object instance |
	object _ self stackTop.
	instance _ self accessibleObjectAfter: object.
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
	value _ self stackTop.
	stream _ self stackValue: 1.
	((self isPointers: stream)
		and: [(self lengthOf: stream) >= (StreamReadLimitIndex + 1)])
		ifFalse: [^ self primitiveFail].

	array _ self fetchPointer: StreamArrayIndex ofObject: stream.
	index _ self fetchInteger: StreamIndexIndex ofObject: stream.
	limit _ self fetchInteger: StreamReadLimitIndex ofObject: stream.
	atIx _ (array bitAnd: AtCacheMask) + AtPutBase.
	(index < limit and: [(atCache at: atIx+AtCacheOop) = array])
		ifFalse: [^ self primitiveFail].

	"OK -- its not at end, and the array is in the cache"
	index _ index + 1.
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

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveNotEqual [
	| integerReceiver integerArgument result |
	integerArgument _ self popStack.
	integerReceiver _ self popStack.
	result _ (self compare31or32Bits: integerReceiver equal: integerArgument) not.
	self checkBooleanResult: result
]

{ #category : #'object access primitives' }
Interpreter >> primitiveObjectAt [
"Defined for CompiledMethods only"
	| thisReceiver index |
	index  _ self popInteger.
	thisReceiver _ self popStack.
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
	newValue _ self popStack.
	index _ self popInteger.
	thisReceiver _ self popStack.
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
	thang _ self popStack.
	rcvr _ self popStack.
	(self isIntegerObject: rcvr) ifTrue: [^self pushBool: false].

	lastField _ self lastPointerOf: rcvr.
	BaseHeaderSize to: lastField by: BytesPerWord do:
		[:i | (self longAt: rcvr + i) = thang
			ifTrue: [^ self pushBool: true]].
	self pushBool: false.
]

{ #category : #'other primitives' }
Interpreter >> primitiveObsoleteIndexedPrimitive [
	"Primitive. Invoke an obsolete indexed primitive."

	| pluginName functionName functionAddress |
	self var: #pluginName type: 'char *'.
	self var: #functionName type: 'char *'.
	self var: #functionAddress type: 'void *'.
	functionAddress _ self cCoerce: ((obsoleteIndexedPrimitiveTable at: primitiveIndex) at: 2) to: 'void *'.
	functionAddress = nil 
		ifFalse: [^self cCode: '((sqInt (*)(void))functionAddress)()'
					inSmalltalk: [self callExternalPrimitive: functionAddress]].
	pluginName _ (obsoleteIndexedPrimitiveTable at: primitiveIndex) at: 0.
	functionName _ (obsoleteIndexedPrimitiveTable at: primitiveIndex) at: 1.
	(pluginName = nil and: [functionName = nil]) 
		ifTrue: [^self primitiveFail].
	functionAddress _ self ioLoadFunction: functionName From: pluginName.
	functionAddress = 0 ifFalse: ["Cache for future use"
		(obsoleteIndexedPrimitiveTable at: primitiveIndex) at: 2 put: 
			(self cCoerce: functionAddress to: 'char*').
		^self cCode: '((sqInt (*)(void))functionAddress)()'
				inSmalltalk: [self callExternalPrimitive: functionAddress]].
	^self primitiveFail
]

{ #category : #'control primitives' }
Interpreter >> primitivePerform [
	| performSelector newReceiver selectorIndex lookupClass performMethod |
	performSelector _ messageSelector.
	performMethod _ newMethod.
	messageSelector _ self stackValue: argumentCount - 1.
	newReceiver _ self stackValue: argumentCount.

	"NOTE: the following lookup may fail and be converted to #doesNotUnderstand:, so we must adjust argumentCount and slide args now, so that would work."

	"Slide arguments down over selector"
	argumentCount _ argumentCount - 1.
	selectorIndex _ self stackPointerIndex - argumentCount.
	self
		transfer: argumentCount
		fromIndex: selectorIndex + 1
		ofObject: activeContext
		toIndex: selectorIndex
		ofObject: activeContext.
	self pop: 1.
	lookupClass _ self fetchClassOf: newReceiver.
	self findNewMethodInClass: lookupClass.

	"Only test CompiledMethods for argument count - other objects will have to take their chances"
	(self isCompiledMethod: newMethod)
		ifTrue: [self success: (self argumentCountOf: newMethod) = argumentCount].

	successFlag
		ifTrue: [self executeNewMethodFromCache.
			"Recursive xeq affects successFlag"
			successFlag _ true]
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
			argumentCount _ argumentCount + 1.
			newMethod _ performMethod.
			messageSelector _ performSelector]
]

{ #category : #'control primitives' }
Interpreter >> primitivePerformAt: lookupClass [
	"Common routine used by perform:withArgs: and perform:withArgs:inSuperclass:"

	"NOTE:  The case of doesNotUnderstand: is not a failure to perform.
	The only failures are arg types and consistency of argumentCount."

	| performSelector argumentArray arraySize index cntxSize performMethod performArgCount |
	argumentArray _ self stackTop.
	(self isArray: argumentArray) ifFalse:[^self primitiveFail].

	successFlag ifTrue:
		["Check for enough space in thisContext to push all args"
		arraySize _ self fetchWordLengthOf: argumentArray.
		cntxSize _ self fetchWordLengthOf: activeContext.
		self success: (self stackPointerIndex + arraySize) < cntxSize].
	successFlag ifFalse: [^nil].

	performSelector _ messageSelector.
	performMethod _ newMethod.
	performArgCount _ argumentCount.
	"pop the arg array and the selector, then push the args out of the array, as if they were on the stack"
	self popStack.
	messageSelector _ self popStack.

	"Copy the arguments to the stack, and execute"
	index _ 1.
	[index <= arraySize]
		whileTrue:
		[self push: (self fetchPointer: index - 1 ofObject: argumentArray).
		index _ index + 1].
	argumentCount _ arraySize.

	self findNewMethodInClass: lookupClass.

	"Only test CompiledMethods for argument count - any other objects playacting as CMs will have to take their chances"
	(self isCompiledMethod: newMethod)
		ifTrue: [self success: (self argumentCountOf: newMethod) = argumentCount].

	successFlag
		ifTrue: [self executeNewMethodFromCache.  "Recursive xeq affects successFlag"
				successFlag _ true]
		ifFalse: ["Restore the state by popping all those array entries and pushing back the selector and array, and fail"
				self pop: argumentCount.
				self push: messageSelector.
				self push: argumentArray.
				messageSelector _ performSelector.
				newMethod _ performMethod.
				argumentCount _ performArgCount]

]

{ #category : #'control primitives' }
Interpreter >> primitivePerformInSuperclass [
	| lookupClass rcvr currentClass |
	lookupClass _ self stackTop.
	rcvr _ self stackValue: argumentCount.
	currentClass _ self fetchClassOf: rcvr.
	[currentClass ~= lookupClass]
		whileTrue:
		[currentClass _ self superclassOf: currentClass.
		currentClass = nilObj ifTrue: [^ self primitiveFail]].

	self popStack.
	self primitivePerformAt: lookupClass.
	successFlag ifFalse:
		[self push: lookupClass]
]

{ #category : #'control primitives' }
Interpreter >> primitivePerformWithArgs [

	| lookupClass rcvr |
	rcvr _ self stackValue: argumentCount.
	lookupClass _ self fetchClassOf: rcvr.
	self primitivePerformAt: lookupClass.

]

{ #category : #'object access primitives' }
Interpreter >> primitivePointX [
	| rcvr | 
	self inline: false.
	rcvr _ self popStack.
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	successFlag
		ifTrue: [self push: (self fetchPointer: XIndex ofObject: rcvr)]
		ifFalse: [self unPop: 1]
]

{ #category : #'object access primitives' }
Interpreter >> primitivePointY [
	| rcvr | 
	self inline: false.
	rcvr _ self popStack.
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
	thisReceiver _ self popStack.
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

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveQuo [
	"Rounds negative results towards zero."
	| integerRcvr integerArg integerResult |
	integerRcvr _ self stackIntegerValue: 1.
	integerArg _ self stackIntegerValue: 0.
	self success: integerArg ~= 0.
	successFlag ifTrue: [
		integerRcvr > 0 ifTrue: [
			integerArg > 0 ifTrue: [
				integerResult _ integerRcvr // integerArg.
			] ifFalse: [
				integerResult _ 0 - (integerRcvr // (0 - integerArg)).
			].
		] ifFalse: [
			integerArg > 0 ifTrue: [
				integerResult _ 0 - ((0 - integerRcvr) // integerArg).
			] ifFalse: [
				integerResult _ (0 - integerRcvr) // (0 - integerArg).
			].
		]].
	self pop2AndPushIntegerIfOK: integerResult
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveRelinquishProcessor [
	"Relinquish the processor for up to the given number of microseconds. The exact behavior of this primitive is platform dependent."

	| microSecs |
	microSecs _ self stackIntegerValue: 0.
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
		nArgs _ argumentCount.
		delta _ stackPointer - activeContext.
	].
	primIdx _ primitiveIndex.
	successFlag _ true.
	"self dispatchOn: primitiveIndex in: primitiveTable."
	self dispatchFunctionPointerOn: primIdx in: primitiveTable.
	"replace with fetch entry primitiveIndex from table and branch there"
	DoBalanceChecks ifTrue:[
		(self balancedStack: delta afterPrimitive: primIdx withArgs: nArgs) 
			ifFalse:[self printUnbalancedStack: primIdx].
	].
	^ successFlag

]

{ #category : #'process primitives' }
Interpreter >> primitiveResume [
"put this process on the scheduler's lists thus allowing it to proceed next time there is a chance for processes of it's priority level"
	| proc |
	proc _ self stackTop.  "rcvr"
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
	self export: true.
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
	self export: true.
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
	kernDelta _ self stackIntegerValue: 0.
	stops _ self stackObjectValue: 1.
	(self isArray: stops) ifFalse: [^ self primitiveFail].
	(self slotSizeOf: stops) >= 258 ifFalse: [^ self primitiveFail].
	scanRightX _ self stackIntegerValue: 2.
	sourceString _ self stackObjectValue: 3.
	(self isBytes: sourceString) ifFalse: [^ self primitiveFail].
	scanStopIndex _ self stackIntegerValue: 4.
	scanStartIndex _ self stackIntegerValue: 5.
	(scanStartIndex > 0 and: [scanStopIndex > 0 and: [scanStopIndex <= (self byteSizeOf: sourceString)]])
		ifFalse: [^ self primitiveFail].

	"Load receiver and required instVars"
	rcvr _ self stackObjectValue: 6.
	((self isPointers: rcvr) and: [(self slotSizeOf: rcvr) >= 4]) ifFalse: [^ self primitiveFail].
	scanDestX _ self fetchInteger: 0 ofObject: rcvr.
	scanLastIndex _ self fetchInteger: 1 ofObject: rcvr.
	scanXTable _ self fetchPointer: 2 ofObject: rcvr.
	scanMap _ self fetchPointer: 3 ofObject: rcvr.
	((self isArray: scanXTable) and: [self isArray: scanMap]) ifFalse: [^ self primitiveFail].
	(self slotSizeOf: scanMap) = 256 ifFalse: [^ self primitiveFail].
	successFlag ifFalse: [^ nil].
	maxGlyph _ (self slotSizeOf: scanXTable) - 2.

	"Okay, here we go. We have eliminated nearly all failure 
	conditions, to optimize the inner fetches."
	scanLastIndex _ scanStartIndex.
	nilOop _ self nilObject.
	[scanLastIndex <= scanStopIndex]
		whileTrue: [
			"Known to be okay since scanStartIndex > 0 and scanStopIndex <= sourceString size"
			ascii _ self fetchByte: scanLastIndex - 1 ofObject: sourceString.
			"Known to be okay since stops size >= 258"
			(stopReason _ self fetchPointer: ascii ofObject: stops) = nilOop
				ifFalse: ["Store everything back and get out of here since some stop conditionn needs to be checked"
					(self isIntegerValue: scanDestX) ifFalse: [^ self primitiveFail].
					self storeInteger: 0 ofObject: rcvr withValue: scanDestX.
					self storeInteger: 1 ofObject: rcvr withValue: scanLastIndex.
					self pop: 7. "args+rcvr"
					^ self push: stopReason].
			"Known to be okay since scanMap size = 256"
			glyphIndex _ self fetchInteger: ascii ofObject: scanMap.
			"fail if the glyphIndex is out of range"
			(self failed or: [glyphIndex < 0 	or: [glyphIndex > maxGlyph]]) ifTrue: [^ self primitiveFail].
			sourceX _ self fetchInteger: glyphIndex ofObject: scanXTable.
			sourceX2 _ self fetchInteger: glyphIndex + 1 ofObject: scanXTable.
			"Above may fail if non-integer entries in scanXTable"
			self failed ifTrue: [^ nil].
			nextDestX _ scanDestX + sourceX2 - sourceX.
			nextDestX > scanRightX
				ifTrue: ["Store everything back and get out of here since we got to the right edge"
					(self isIntegerValue: scanDestX) ifFalse: [^ self primitiveFail].
					self storeInteger: 0 ofObject: rcvr withValue: scanDestX.
					self storeInteger: 1 ofObject: rcvr withValue: scanLastIndex.
					self pop: 7. "args+rcvr"
					^ self push: (self fetchPointer: CrossedX - 1 ofObject: stops)].
			scanDestX _ nextDestX + kernDelta.
			scanLastIndex _ scanLastIndex + 1].
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
	self export: true.
	depth _ self ioScreenDepth.
	self failed ifTrue:[^self primitiveFail].
	self pop: 1 thenPushInteger: depth.
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveScreenSize [
	"Return a point indicating the current size of the Smalltalk window. Currently there is a limit of 65535 in each direction because the point is encoded into a single 32bit value in the image header. This might well become a problem one day"
	| pointWord |
	self pop: 1.
	pointWord _ self ioScreenSize.
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
	fsFlag _ self booleanValueOf: (self stackTop).
	h _ self stackIntegerValue: 1.
	w _ self stackIntegerValue: 2.
	d _ self stackIntegerValue: 3.
	successFlag ifTrue: [okay _ self cCode:'ioSetDisplayMode(w, h, d, fsFlag)'].
	successFlag ifTrue: [
		self pop: 5. "Pop args+rcvr"
		self pushBool: okay].
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveSetFullScreen [
	"On platforms that support it, set full-screen mode to the value of the boolean argument."

	| argOop |
	argOop _ self stackTop.
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
	self export: true.
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
	self export: true.
	value := self stackIntegerValue: 0.
	successFlag ifTrue:[
		gcBiasToGrowGCLimit := value.
		gcBiasToGrowThreshold _ youngStart - (self cCoerce: memory to: 'int').
		self pop: argumentCount.
	].
]

{ #category : #'memory space primitives' }
Interpreter >> primitiveSetGCSemaphore [
	"Primitive. Indicate the semaphore to be signalled for upon garbage collection"
	| index |
	self export: true.
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
	keycode _ self popInteger.
	successFlag
		ifTrue: [ interruptKeycode _ keycode ]
		ifFalse: [ self unPop: 1 ].
]

{ #category : #'sound primitives' }
Interpreter >> primitiveShortAt [
	"Treat the receiver, which can be indexible by either bytes or words, as an array of signed 16-bit values. Return the contents of the given index. Note that the index specifies the i-th 16-bit entry, not the i-th byte or word."

	| index rcvr sz addr value |
	index _ self stackIntegerValue: 0.
	rcvr _ self stackValue: 1.
	self success: ((self isIntegerObject: rcvr) not and: [self isWordsOrBytes: rcvr]).
	successFlag ifFalse: [ ^ nil ].
	sz _ ((self sizeBitsOf: rcvr) - BaseHeaderSize) // 2.  "number of 16-bit fields"
	self success: ((index >= 1) and: [index <= sz]).
	successFlag ifTrue: [
		addr _ rcvr + BaseHeaderSize + (2 * (index - 1)).
		value _ self shortAt: addr.
		self pop: 2 thenPushInteger: value. 
	]
]

{ #category : #'sound primitives' }
Interpreter >> primitiveShortAtPut [
	"Treat the receiver, which can be indexible by either bytes or words, as an array of signed 16-bit values. Set the contents of the given index to the given value. Note that the index specifies the i-th 16-bit entry, not the i-th byte or word."

	| index rcvr sz addr value |
	value _ self stackIntegerValue: 0.
	index _ self stackIntegerValue: 1.
	rcvr _ self stackValue: 2.
	self success: ((self isIntegerObject: rcvr) not and: [self isWordsOrBytes: rcvr]).
	successFlag ifFalse: [ ^ nil ].
	sz _ ((self sizeBitsOf: rcvr) - BaseHeaderSize) // 2.  "number of 16-bit fields"
	self success: ((index >= 1) and: [index <= sz]).
	self success: ((value >= -32768) and: [value <= 32767]).
	successFlag ifTrue: [
		addr _ rcvr + BaseHeaderSize + (2 * (index - 1)).
		self shortAt: addr put: value.
		self pop: 2.  "pop index and value; leave rcvr on stack"
	]
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveShowDisplayRect [
	"Force the given rectangular section of the Display to be 
	copied to the screen."
	| bottom top right left |
	bottom _ self stackIntegerValue: 0.
	top _ self stackIntegerValue: 1.
	right _ self stackIntegerValue: 2.
	left _ self stackIntegerValue: 3.
	self displayBitsOf: (self splObj: TheDisplay) Left: left Top: top Right: right Bottom: bottom.
	successFlag
		ifTrue: [self ioForceDisplayUpdate.
			self pop: 4]
]

{ #category : #'process primitives' }
Interpreter >> primitiveSignal [
"synchromously signal the semaphore. This may change the active process as a result"
	| sema |
	sema _ self stackTop.  "rcvr"
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
	bytes _ self popInteger.
	successFlag
		ifTrue: [lowSpaceThreshold _ bytes]
		ifFalse: [lowSpaceThreshold _ 0.
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

{ #category : #'float primitives' }
Interpreter >> primitiveSine [

	| rcvr |
	self var: #rcvr type: 'double '.
	rcvr _ self popFloat.
	successFlag
		ifTrue: [self pushFloat: (self cCode: 'sin(rcvr)' inSmalltalk: [rcvr sin])]
		ifFalse: [self unPop: 1]
]

{ #category : #'array and stream primitives' }
Interpreter >> primitiveSize [
	| rcvr sz |
	rcvr _ self stackTop.
	(self isIntegerObject: rcvr) ifTrue: [^ self primitiveFail].  "Integers are not indexable"
	(self formatOf: rcvr) < 2 ifTrue: [^ self primitiveFail].  "This is not an indexable object"
	sz _ self stSizeOf: rcvr.
	successFlag ifTrue:
		[self pop: 1 thenPush: (self positive32BitIntegerFor: sz)]

]

{ #category : #'system control primitives' }
Interpreter >> primitiveSnapshot [
"save a normal snapshot under the same name as it was loaded unless it has been renamed by the last primitiveImageName"
	self inline: false.
	^self snapshot: false

]

{ #category : #'system control primitives' }
Interpreter >> primitiveSnapshotEmbedded [
"save an embedded snapshot"
	self inline: false.
	^self snapshot: true
]

{ #category : #'object access primitives' }
Interpreter >> primitiveSomeInstance [
	| class instance |
	class _ self stackTop.
	instance _ self initialInstanceOf: class.
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

{ #category : #'float primitives' }
Interpreter >> primitiveSquareRoot [
	| rcvr |
	self var: #rcvr type: 'double '.
	rcvr _ self popFloat.
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

	outPointerArray _ self stackTop.
	segmentWordArray _ self stackValue: 1.
	arrayOfRoots _ self stackValue: 2.

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
	firstOut _ outPointerArray + BaseHeaderSize.
	lastOut _ firstOut - BytesPerWord.
	hdrBaseOut _ outPointerArray + ((self lastPointerOf: outPointerArray) // (BytesPerWord*2) * BytesPerWord). "top half"

	lastSeg _ segmentWordArray.
	endSeg _ segmentWordArray + (self sizeBitsOf: segmentWordArray) - BytesPerWord.

	"Write a version number for byte order and version check"
	versionOffset _ BytesPerWord.
	lastSeg _ lastSeg + versionOffset.
	lastSeg > endSeg ifTrue: [^ self primitiveFail].
	self longAt: lastSeg put: self imageSegmentVersion.

	"Allocate top 1/8 of segment for table of internal oops and saved headers"
	firstIn _ endSeg - ((self sizeBitsOf: segmentWordArray) // (BytesPerWord*8) * BytesPerWord).  "Take 1/8 of seg"
	lastIn _ firstIn - BytesPerWord.
	hdrBaseIn _ firstIn + ((self sizeBitsOf: segmentWordArray) // (BytesPerWord*16) * BytesPerWord). "top half of that"

	"First mark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitOr: MarkBit).
	lastPtr _ arrayOfRoots + (self lastPointerOf: arrayOfRoots).
	fieldPtr _ arrayOfRoots + BaseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop _ self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitOr: MarkBit)].
		fieldPtr _ fieldPtr + BytesPerWord].

	"Then do a mark pass over all objects.  This will stop at our marked roots,
	thus leaving our segment unmarked in their shadow."
	savedYoungStart _ youngStart.
	youngStart _ self startOfMemory.  "process all of memory"
		"clear the recycled context lists"
		freeContexts _ NilContext.
		freeLargeContexts _ NilContext.
	self markAndTraceInterpreterOops.	"and special objects array"
	youngStart _ savedYoungStart.
	
	"Finally unmark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitAnd: AllButMarkBit).
	fieldPtr _ arrayOfRoots + BaseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop _ self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitAnd: AllButMarkBit)].
		fieldPtr _ fieldPtr + BytesPerWord].

	"All external objects, and only they, are now marked.
	Copy the array of roots into the segment, and forward its oop."
	lastIn _ lastIn + BytesPerWord.
	lastIn >= hdrBaseIn ifTrue: [successFlag _ false].
	lastSeg _ self copyObj: arrayOfRoots toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn).
	successFlag ifFalse:
		[lastIn _ lastIn - BytesPerWord.
		self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
		^ self primitiveFailAfterCleanup: outPointerArray].

	"Now run through the segment fixing up all the pointers.
	Note that more objects will be added to the segment as we make our way along."
	segOop _ self oopFromChunk: segmentWordArray + versionOffset + BaseHeaderSize.
	[segOop <= lastSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type=0 or 1) -- start with that."
					fieldPtr _ segOop - BytesPerWord.  doingClass _ true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr _ segOop + BaseHeaderSize.  doingClass _ false].
		lastPtr _ segOop + (self lastPointerOf: segOop).	"last field"

		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop _ self longAt: fieldPtr.
			doingClass ifTrue:
				[hdrTypeBits _ fieldOop bitAnd: TypeMask.
				fieldOop _ fieldOop - hdrTypeBits].
			(self isIntegerObject: fieldOop)
				ifTrue: ["Just an integer -- nothing to do"
						fieldPtr _ fieldPtr + BytesPerWord]
				ifFalse:
				[header _ self longAt: fieldOop.
				(header bitAnd: TypeMask) = HeaderTypeFree
					ifTrue: ["Has already been forwarded -- this is the link"
							mapOop _ header bitAnd: AllButTypeMask]
					ifFalse:
					[((self longAt: fieldOop) bitAnd: MarkBit) = 0
						ifTrue:
							["Points to an unmarked obj -- an internal pointer.
							Copy the object into the segment, and forward its oop."
							lastIn _ lastIn + BytesPerWord.
							lastIn >= hdrBaseIn ifTrue: [successFlag _ false].
							lastSeg _ self copyObj: fieldOop toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn).
							successFlag ifFalse:
								["Out of space in segment"
								lastIn _ lastIn - BytesPerWord.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^ self primitiveFailAfterCleanup: outPointerArray].
							mapOop _ (self longAt: fieldOop) bitAnd: AllButTypeMask]
						ifFalse:
							["Points to a marked obj -- an external pointer.
							Map it as a tagged index in outPointers, and forward its oop."
							lastOut _ lastOut + BytesPerWord.
							lastOut >= hdrBaseOut ifTrue:
								["Out of space in outPointerArray"
								lastOut _ lastOut - BytesPerWord.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^ self primitiveFailAfterCleanup: outPointerArray].
.							mapOop _ lastOut - outPointerArray bitOr: 16r80000000.
							self forward: fieldOop to: mapOop
								savingOopAt: lastOut andHeaderAt: hdrBaseOut + (lastOut - firstOut)]].
					"Replace the oop by its mapped value"
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr _ fieldPtr + (BytesPerWord*2).
								doingClass _ false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr _ fieldPtr + BytesPerWord].
]].
		segOop _ self objectAfter: segOop].

	self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.

	"Truncate the outPointerArray..."
	((outPointerArray + (self lastPointerOf: outPointerArray) - lastOut) < 12
		or: [(endSeg - lastSeg) < 12]) ifTrue:
			["Not enough room to insert simple 3-word headers"
			^ self primitiveFailAfterCleanup: outPointerArray].
	extraSize _ self extraHeaderBytes: segmentWordArray.
	hdrTypeBits _ self headerType: segmentWordArray.
	"Copy the 3-word wordArray header to establish a free chunk."
	self transfer: 3
		from: segmentWordArray - extraSize
		to: lastOut+BytesPerWord.
	"Adjust the size of the original as well as the free chunk."
	self longAt: lastOut+BytesPerWord
		put: outPointerArray + (self lastPointerOf: outPointerArray) - lastOut - extraSize + hdrTypeBits.
	self longAt: outPointerArray-extraSize
		put: lastOut - firstOut + (BytesPerWord*2) + hdrTypeBits.
	"Note that pointers have been stored into roots table"
	self beRootIfOld: outPointerArray.

	"Truncate the image segment..."
	"Copy the 3-word wordArray header to establish a free chunk."
	self transfer: 3
		from: segmentWordArray - extraSize
		to: lastSeg+BytesPerWord.
	"Adjust the size of the original as well as the free chunk."
	self longAt: segmentWordArray-extraSize
		put: lastSeg - segmentWordArray + BaseHeaderSize + hdrTypeBits.
	self longAt: lastSeg+BytesPerWord
		put: endSeg - lastSeg - extraSize + hdrTypeBits.

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	self pop: 3.  "...leaving the reciever on the stack as return value"

]

{ #category : #'object access primitives' }
Interpreter >> primitiveStoreStackp [
	"Atomic store into context stackPointer. 
	Also ensures that any newly accessible cells are initialized to nil "
	| ctxt newStackp stackp |
	ctxt _ self stackValue: 1.
	newStackp _ self stackIntegerValue: 0.
	self success: newStackp >= 0.
	self success: newStackp <= (LargeContextSize - BaseHeaderSize // BytesPerWord - CtxtTempFrameStart).
	successFlag ifFalse: [^ self primitiveFail].
	stackp _ self fetchStackPointerOf: ctxt.
	newStackp > stackp ifTrue: ["Nil any newly accessible cells"
			stackp + 1 to: newStackp do: [:i | self storePointer: i + CtxtTempFrameStart - 1 ofObject: ctxt withValue: nilObj]].
	self storeStackPointerValue: newStackp inContext: ctxt.
	self pop: 1
]

{ #category : #'array and stream primitives' }
Interpreter >> primitiveStringAt [

	self commonAt: true.
]

{ #category : #'array and stream primitives' }
Interpreter >> primitiveStringAtPut [

	self commonAtPut: true.
]

{ #category : #'array and stream primitives' }
Interpreter >> primitiveStringReplace [
	" 
	<array> primReplaceFrom: start to: stop with: replacement 
	startingAt: repStart  
	<primitive: 105>
	"
	| array start stop repl replStart hdr arrayFmt totalLength arrayInstSize replFmt replInstSize srcIndex |
	array _ self stackValue: 4.
	start _ self stackIntegerValue: 3.
	stop _ self stackIntegerValue: 2.
	repl _ self stackValue: 1.
	replStart _ self stackIntegerValue: 0.

	successFlag ifFalse: [^ self primitiveFail].
	(self isIntegerObject: repl) ifTrue: ["can happen in LgInt copy"
			^ self primitiveFail].

	hdr _ self baseHeader: array.
	arrayFmt _ hdr >> 8 bitAnd: 15.
	totalLength _ self lengthOf: array baseHeader: hdr format: arrayFmt.
	arrayInstSize _ self fixedFieldsOf: array format: arrayFmt length: totalLength.
	(start >= 1 and: [start - 1 <= stop and: [stop + arrayInstSize <= totalLength]])
		ifFalse: [^ self primitiveFail].

	hdr _ self baseHeader: repl.
	replFmt _ hdr >> 8 bitAnd: 15.
	totalLength _ self lengthOf: repl baseHeader: hdr format: replFmt.
	replInstSize _ self fixedFieldsOf: repl format: replFmt length: totalLength.
	(replStart >= 1 and: [stop - start + replStart + replInstSize <= totalLength])
		ifFalse: [^ self primitiveFail].

	"Array formats (without byteSize bits, if bytes array) must be same "
	arrayFmt < 8
		ifTrue: [arrayFmt = replFmt
				ifFalse: [^ self primitiveFail]]
		ifFalse: [(arrayFmt bitAnd: 12) = (replFmt bitAnd: 12)
				ifFalse: [^ self primitiveFail]].

	srcIndex _ replStart + replInstSize - 1.
	"- 1 for 0-based access"

	arrayFmt <= 4
		ifTrue: ["pointer type objects"
			start + arrayInstSize - 1 to: stop + arrayInstSize - 1 do: [:i |
				self storePointer: i ofObject: array withValue: (self fetchPointer: srcIndex ofObject: repl).
					srcIndex _ srcIndex + 1]]
		ifFalse: [arrayFmt < 8
				ifTrue: ["32-bit-word type objects"
					start + arrayInstSize - 1 to: stop + arrayInstSize - 1
						do: [:i | self storeLong32: i ofObject: array withValue: (self fetchLong32: srcIndex ofObject: repl).
							srcIndex _ srcIndex + 1]]
				ifFalse: ["byte-type objects"
					start + arrayInstSize - 1 to: stop + arrayInstSize - 1
						do: [:i |  self storeByte: i ofObject: array withValue: (self fetchByte: srcIndex ofObject: repl).
							srcIndex _ srcIndex + 1]]].
	"We might consider  comparing stop - start to some value here and using forceInterruptCheck"

	self pop: argumentCount "leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
Interpreter >> primitiveSubtract [

	self pop2AndPushIntegerIfOK: (self stackIntegerValue: 1) - (self stackIntegerValue: 0)
]

{ #category : #'process primitives' }
Interpreter >> primitiveSuspend [

	| activeProc |
	activeProc _ self fetchPointer: ActiveProcessIndex
						 ofObject: self schedulerPointer.
	self success: self stackTop = activeProc.
	successFlag ifTrue: [
		self pop: 1.
		self push: nilObj.
		self transferTo: self wakeHighestPriority.
	].
]

{ #category : #'process primitives' }
Interpreter >> primitiveTerminateTo [
	"Primitive. Terminate up the context stack from the receiver up to but not including the argument, if previousContext is on my Context stack. Make previousContext my sender. This prim has to shadow the code in ContextPart>terminateTo: to be correct"
	| thisCntx currentCntx aContext nextCntx nilOop |
	aContext _ self popStack.
	thisCntx _ self popStack.

	"make sure that aContext is in my chain"
	(self context: thisCntx hasSender: aContext) ifTrue:[
		nilOop _ nilObj.
		currentCntx _ self fetchPointer: SenderIndex ofObject: thisCntx.
		[currentCntx = aContext] whileFalse: [
			nextCntx _ self fetchPointer: SenderIndex ofObject: currentCntx.
			self storePointer: SenderIndex ofObject: currentCntx withValue: nilOop.
			self storePointer: InstructionPointerIndex ofObject: currentCntx withValue: nilOop.
			currentCntx _ nextCntx]].

	self storePointer: SenderIndex ofObject: thisCntx withValue: aContext.
	^self push: thisCntx
]

{ #category : #'I/O primitives' }
Interpreter >> primitiveTestDisplayDepth [
	"Return true if the host OS does support the given display depth."
	| bitsPerPixel okay|
	bitsPerPixel _ self stackIntegerValue: 0.
	successFlag ifTrue: [okay _ self ioHasDisplayDepth: bitsPerPixel].
	successFlag ifTrue: [
		self pop: 2. "Pop arg+rcvr"
		self pushBool: okay].
]

{ #category : #'float primitives' }
Interpreter >> primitiveTimesTwoPower [
	| rcvr arg |
	self var: #rcvr type: 'double '.
	arg _ self popInteger.
	rcvr _ self popFloat.
	successFlag
		ifTrue: [ self pushFloat: (self cCode: 'ldexp(rcvr, arg)' inSmalltalk: [rcvr timesTwoPower: arg]) ]
		ifFalse: [ self unPop: 2 ].
]

{ #category : #'float primitives' }
Interpreter >> primitiveTruncated [ 
	| rcvr frac trunc |
	self var: #rcvr type: 'double '.
	self var: #frac type: 'double '.
	self var: #trunc type: 'double '.
	rcvr _ self popFloat.
	successFlag ifTrue:
		[self cCode: 'frac = modf(rcvr, &trunc)'
			inSmalltalk: [trunc _ rcvr truncated].
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
	moduleName _ self stackTop.
	(self isIntegerObject: moduleName) ifTrue:[^self primitiveFail].
	(self isBytes: moduleName) ifFalse:[^self primitiveFail].
	(self ioUnloadModule: (self oopForPointer: (self firstIndexableField: moduleName))
		OfLength: (self byteSizeOf: moduleName)) ifFalse:[^self primitiveFail].
	self flushExternalPrimitives.
	self forceInterruptCheck.
	self pop: 1 "pop moduleName; return receiver"
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

	| mem paramsArraySize result arg index |
	mem _ self startOfMemory.
	paramsArraySize _ 40.
	argumentCount = 0 ifTrue: [
		result _ self instantiateClass: (self splObj: ClassArray) indexableSize: paramsArraySize.
		0 to: paramsArraySize - 1 do:
			[:i | self storePointer: i ofObject: result withValue: ConstZero].
		self storePointer: 0	ofObject: result withValue: (self integerObjectOf: youngStart - mem).
		self storePointer: 1		ofObject: result withValue: (self integerObjectOf: freeBlock - mem).
		self storePointer: 2	ofObject: result withValue: (self integerObjectOf: endOfMemory - mem).
		self storePointer: 3	ofObject: result withValue: (self integerObjectOf: allocationCount).
		self storePointer: 4	ofObject: result withValue: (self integerObjectOf: allocationsBetweenGCs).
		self storePointer: 5	ofObject: result withValue: (self integerObjectOf: tenuringThreshold).
		self storePointer: 6	ofObject: result withValue: (self integerObjectOf: statFullGCs).
		self storePointer: 7	ofObject: result withValue: (self integerObjectOf: statFullGCMSecs).
		self storePointer: 8	ofObject: result withValue: (self integerObjectOf: statIncrGCs).
		self storePointer: 9	ofObject: result withValue: (self integerObjectOf: statIncrGCMSecs).
		self storePointer: 10	ofObject: result withValue: (self integerObjectOf: statTenures).
		self storePointer: 20	ofObject: result withValue: (self integerObjectOf: rootTableCount).
		self storePointer: 21	ofObject: result withValue: (self integerObjectOf: statRootTableOverflows).
		self storePointer: 22	ofObject: result withValue: (self integerObjectOf: extraVMMemory).
		self storePointer: 23	ofObject: result withValue: (self integerObjectOf: shrinkThreshold).
		self storePointer: 24	ofObject: result withValue: (self integerObjectOf: growHeadroom).
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
		self storePointer: 35	ofObject: result withValue: (self integerObjectOf: statGCTime).
		self storePointer: 36	ofObject: result withValue: (self integerObjectOf: statSpecialMarkCount).
		self storePointer: 37	ofObject: result withValue: (self integerObjectOf: statIGCDeltaTime).
		self storePointer: 38	ofObject: result withValue: (self integerObjectOf: statpendingFinalizationSignals).
		self storePointer: 39	ofObject: result withValue: (self integerObjectOf: BytesPerWord).
		self pop: 1 thenPush: result.
		^nil].

	arg _ self stackTop.
	(self isIntegerObject: arg) ifFalse: [^self primitiveFail].
	arg _ self integerValueOf: arg.
	argumentCount = 1 ifTrue: [	 "read VM parameter"
		(arg < 1 or: [arg > paramsArraySize]) ifTrue: [^self primitiveFail].
		arg = 1		ifTrue: [result _ youngStart - mem].
		arg = 2		ifTrue: [result _ freeBlock - mem].
		arg = 3		ifTrue: [result _ endOfMemory - mem].
		arg = 4		ifTrue: [result _ allocationCount].
		arg = 5		ifTrue: [result _ allocationsBetweenGCs].
		arg = 6		ifTrue: [result _ tenuringThreshold].
		arg = 7		ifTrue: [result _ statFullGCs].
		arg = 8		ifTrue: [result _ statFullGCMSecs].
		arg = 9		ifTrue: [result _ statIncrGCs].
		arg = 10		ifTrue: [result _ statIncrGCMSecs].
		arg = 11		ifTrue: [result _ statTenures].
		((arg >= 12) and: [arg <= 20]) ifTrue: [result _ 0].
		arg = 21		ifTrue: [result _ rootTableCount].
		arg = 22		ifTrue: [result _ statRootTableOverflows].
		arg = 23		ifTrue: [result _ extraVMMemory].
		arg = 24		ifTrue: [result _ shrinkThreshold].
		arg = 25		ifTrue: [result _ growHeadroom].
		arg = 26		ifTrue: [result _ interruptChecksEveryNms]. 
		arg = 27		ifTrue: [result _ statMarkCount]. 
		arg = 28		ifTrue: [result _ statSweepCount]. 
		arg = 29		ifTrue: [result _ statMkFwdCount]. 
		arg = 30		ifTrue: [result _ statCompMoveCount]. 
		arg = 31		ifTrue: [result _ statGrowMemory]. 
		arg = 32		ifTrue: [result _ statShrinkMemory]. 
		arg = 33		ifTrue: [result _ statRootTableCount]. 
		arg = 34		ifTrue: [result _ statAllocationCount]. 
		arg = 35		ifTrue: [result _ statSurvivorCount]. 
		arg = 36  	ifTrue: [result _ statGCTime]. 
		arg = 37  	ifTrue: [result _ statSpecialMarkCount]. 
		arg = 38  	ifTrue: [result _ statIGCDeltaTime]. 
		arg = 39  	ifTrue: [result _ statpendingFinalizationSignals]. 
		arg = 40  	ifTrue: [result _ BytesPerWord]. 
		self pop: 2 thenPush: (self integerObjectOf: result).
		^nil].

	"write a VM parameter"
	argumentCount = 2 ifFalse: [^self primitiveFail].
	index _ self stackValue: 1.
	(self isIntegerObject: index) ifFalse: [^self primitiveFail].
	index _ self integerValueOf: index.
	index <= 0 ifTrue: [^self primitiveFail].
	successFlag _ false.
	index = 5 ifTrue: [
		result _ allocationsBetweenGCs.
		allocationsBetweenGCs _ arg.
		successFlag _ true].
	index = 6 ifTrue: [
		result _ tenuringThreshold.
		tenuringThreshold _ arg.
		successFlag _ true].
	index = 23 ifTrue: [
		result _ extraVMMemory.
		extraVMMemory _ arg.
		successFlag _ true].
	index = 24 ifTrue: [
		result _ shrinkThreshold.
		arg > 0 ifTrue:[
			shrinkThreshold _ arg.
			successFlag _ true]].
	index = 25 ifTrue: [
		result _ growHeadroom.
		arg > 0 ifTrue:[
			growHeadroom _ arg.
			successFlag _ true]].
	index = 26 ifTrue: [
		arg > 1 ifTrue:[
			result _ interruptChecksEveryNms.
			interruptChecksEveryNms _ arg.
			successFlag _ true]]. 

	successFlag ifTrue: [
		self pop: 3 thenPush: (self integerObjectOf: result).  "return old value"
		^ nil].

	self primitiveFail.  "attempting to write a read-only parameter"




]

{ #category : #'system control primitives' }
Interpreter >> primitiveVMPath [
	"Return a string containing the path name of VM's directory."

	| s sz |
	sz _ self vmPathSize.
	s _ self instantiateClass: (self splObj: ClassString) indexableSize: sz.
	self vmPathGet: (s + BaseHeaderSize) Length: sz.
	self pop: 1 thenPush: s.

]

{ #category : #'control primitives' }
Interpreter >> primitiveValue [
	| blockContext blockArgumentCount initialIP |
	blockContext _ self stackValue: argumentCount.
	blockArgumentCount _ self argumentCountOfBlock: blockContext.
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
			initialIP _ self fetchPointer: InitialIPIndex	ofObject: blockContext.
			self storePointerUnchecked: InstructionPointerIndex ofObject: blockContext withValue: initialIP.
			self storeStackPointerValue: argumentCount inContext: blockContext.
			self storePointerUnchecked: CallerIndex ofObject: blockContext withValue: activeContext.
			self newActiveContext: blockContext]
]

{ #category : #'control primitives' }
Interpreter >> primitiveValueUninterruptably [
	"The only purpose of this primitive is to indicate that the new EH mechanisms are supported."
	self inline: false.
	^self primitiveValue
]

{ #category : #'control primitives' }
Interpreter >> primitiveValueWithArgs [
	| argumentArray blockContext blockArgumentCount arrayArgumentCount initialIP |
	argumentArray _ self popStack.
	blockContext _ self popStack.
	blockArgumentCount _ self argumentCountOfBlock: blockContext.
	"If the argArray isnt actually an Array we ahve to unpop the above two"
	(self isArray: argumentArray) ifFalse: [self unPop:2. ^self primitiveFail].

	successFlag ifTrue: [arrayArgumentCount _ self fetchWordLengthOf: argumentArray.
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
			initialIP _ self fetchPointer: InitialIPIndex ofObject: blockContext.
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
	sema _ self stackTop.  "rcvr"
	self assertClassOf: sema is: (self splObj: ClassSemaphore).
	successFlag ifTrue: [
		excessSignals _
			self fetchInteger: ExcessSignalsIndex ofObject: sema.
		excessSignals > 0 ifTrue: [
			self storeInteger: ExcessSignalsIndex
				ofObject: sema withValue: excessSignals - 1.
		] ifFalse: [
			activeProc _ self fetchPointer: ActiveProcessIndex
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
	activeProc _ self fetchPointer: ActiveProcessIndex
						 ofObject: self schedulerPointer.
	priority _ self quickFetchInteger: PriorityIndex ofObject: activeProc.
	processLists _ self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	processList _ self fetchPointer: priority - 1 ofObject: processLists.

	(self isEmptyList: processList) ifFalse:[
		self addLastLink: activeProc toList: processList.
		self transferTo: self wakeHighestPriority]
]

{ #category : #'debug printing' }
Interpreter >> print: s [
	"For testing in Smalltalk, this method should be overridden in a subclass."

	self var: #s type: 'char *'.
	self cCode: 'printf("%s", s)'.
]

{ #category : #'debug printing' }
Interpreter >> printAllStacks [
	"Print all the stacks of all running processes, including those that are currently suspended."
	| oop proc ctx |
	proc _ self fetchPointer: ActiveProcessIndex ofObject: self schedulerPointer.
	self printNameOfClass: (self fetchClassOf: proc) count: 5.
	self cr.
	self printCallStackOf: activeContext. "first the active context"
	oop _ self firstObject.
	[oop < endOfMemory] whileTrue:[
		(self fetchClassOf: oop) == self classSemaphore ifTrue:[
			self cr.
			proc _ self fetchPointer: FirstLinkIndex ofObject: oop.
			[proc == self nilObject] whileFalse:[
				self printNameOfClass: (self fetchClassOf: proc) count: 5.
				self cr.
				ctx _ self fetchPointer: SuspendedContextIndex ofObject: proc.
				ctx == self nilObject ifFalse:[self printCallStackOf: ctx].
				proc _ self fetchPointer: NextLinkIndex ofObject: proc].
		].
		oop _ self objectAfter: oop.
	].
]

{ #category : #'debug printing' }
Interpreter >> printCallStack [
	^self printCallStackOf: activeContext
]

{ #category : #'debug printing' }
Interpreter >> printCallStackOf: aContext [

	| ctxt home methClass methodSel message |
	self inline: false.
	ctxt _ aContext.
	[ctxt = nilObj] whileFalse: [
		(self fetchClassOf: ctxt) = (self splObj: ClassBlockContext)
			ifTrue: [ home _ self fetchPointer: HomeIndex ofObject: ctxt ]
			ifFalse: [ home _ ctxt ].
		methClass _
			self findClassOfMethod: (self fetchPointer: MethodIndex ofObject: home)
					   forReceiver: (self fetchPointer: ReceiverIndex ofObject: home).
		methodSel _
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
			message _ self fetchPointer: 0 + TempFrameStart ofObject: home.
			methodSel _ self fetchPointer: MessageSelectorIndex ofObject: message.
			self print: ' '.
			self printStringOf: methodSel.
		].
		self cr.

		ctxt _ (self fetchPointer: SenderIndex ofObject: ctxt).
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
	(self sizeBitsOf: classOop) = (7 * BytesPerWord)	"(Metaclass instSize+1 * 4)"
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
	fmt _ self formatOf: oop.
	fmt < 8 ifTrue: [ ^nil ].

	cnt _ 100 min: (self lengthOf: oop).
	i _ 0.
	[i < cnt] whileTrue: [
		self printChar: (self fetchByte: i ofObject: oop).
		i _ i + 1.
	].
]

{ #category : #'debug printing' }
Interpreter >> printUnbalancedStack: primIdx [
	self inline: false.
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
	self inline: false.
	self print: 'Stack unbalanced after '.
	successFlag 
		ifTrue:[self print:'successful '] 
		ifFalse:[self print: 'failed '].
	lit _ self literal: 0 ofMethod: newMethod.
	self printStringOf: (self fetchPointer: 1 ofObject: lit).
	self print:' in '.
	self printStringOf: (self fetchPointer: 0 ofObject: lit).
	self cr.
		
]

{ #category : #contexts }
Interpreter >> push: object [

	| sp |
	self longAt: (sp _ stackPointer + BytesPerWord) put: object.
	stackPointer _ sp.
]

{ #category : #'stack bytecodes' }
Interpreter >> pushActiveContextBytecode [
	"Puts reclaimability of this context in question."

	self fetchNextBytecode.
	reclaimableContextCount _ 0.
	self internalPush: activeContext.

]

{ #category : #contexts }
Interpreter >> pushBool: trueOrFalse [

	trueOrFalse
		ifTrue: [ self push: trueObj ]
		ifFalse: [ self push: falseObj ].
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

	self var: #f type: 'double '.
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

	self fetchNextBytecode.
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	self pushLiteralVariable: (currentBytecode bitAnd: 16r1F).

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

	self fetchNextBytecode.
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	self pushReceiverVariable: (currentBytecode bitAnd: 16rF).

]

{ #category : #'stack bytecodes' }
Interpreter >> pushTemporaryVariable: temporaryIndex [

	self internalPush: (self temporary: temporaryIndex).
]

{ #category : #'stack bytecodes' }
Interpreter >> pushTemporaryVariableBytecode [

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
	self var: #aFile type: 'sqImageFile '.

	objectsWritten _ self cCode: 'sqImageFileWrite(&aWord, sizeof(aWord), 1, aFile)'.
	self success: objectsWritten = 1.

]

{ #category : #processes }
Interpreter >> putToSleep: aProcess [
	"Save the given process on the scheduler process list for its priority."

	| priority processLists processList |
	priority _ self quickFetchInteger: PriorityIndex ofObject: aProcess.
	processLists _ self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	processList _ self fetchPointer: priority - 1 ofObject: processLists.
	self addLastLink: aProcess toList: processList.
]

{ #category : #processes }
Interpreter >> quickCheckForInterrupts [
	"Quick check for possible user or timer interrupts. Decrement a counter and only do a real check when counter reaches zero or when a low space or user interrupt is pending."
	"Note: Clients that trigger interrupts should set use forceInterruptCheck to set interruptCheckCounter to zero and get immediate results."
	"Note: Requires that instructionPointer and stackPointer be external."

	((interruptCheckCounter _ interruptCheckCounter - 1) <= 0)
		ifTrue: [self checkForInterrupts].

]

{ #category : #utilities }
Interpreter >> quickFetchInteger: fieldIndex ofObject: objectPointer [
	"Return the integer value of the field without verifying that it is an integer value! For use in time-critical places where the integer-ness of the field can be guaranteed."

	^ self integerValueOf: (self fetchPointer: fieldIndex ofObject: objectPointer).
]

{ #category : #'image save/restore' }
Interpreter >> readImageFromFile: f HeapSize: desiredHeapSize StartingAt: imageOffset [
	"Read an image from the given file stream, allocating the given amount of memory to its object heap. Fail if the image has an unknown format or requires more than the given amount of memory."
	"Details: This method detects when the image was stored on a machine with the opposite byte ordering from this machine and swaps the bytes automatically. Furthermore, it allows the header information to start 512 bytes into the file, since some file transfer programs for the Macintosh apparently prepend a Mac-specific header of this size. Note that this same 512 bytes of prefix area could also be used to store an exec command on Unix systems, allowing one to launch Smalltalk by invoking the image name as a command."
	"This code is based on C code by Ian Piumarta and Smalltalk code by Tim Rowledge. Many thanks to both of you!!"

	| swapBytes headerStart headerSize dataSize oldBaseAddr minimumMemory memStart bytesRead bytesToShift heapSize |
	self var: #f type: 'sqImageFile '.
	self var: #headerStart type: 'squeakFileOffsetType '.
	self var: #dataSize type: 'size_t '.
	self var: #imageOffset type: 'squeakFileOffsetType '.

	swapBytes _ self checkImageVersionFrom: f startingAt: imageOffset.
	headerStart _ (self sqImageFilePosition: f) - BytesPerWord.  "record header start position"

	headerSize			_ self getLongFromFile: f swap: swapBytes.
	dataSize				_ self getLongFromFile: f swap: swapBytes.
	oldBaseAddr			_ self getLongFromFile: f swap: swapBytes.
	specialObjectsOop	_ self getLongFromFile: f swap: swapBytes.
	lastHash			_ self getLongFromFile: f swap: swapBytes.
	savedWindowSize	_ self getLongFromFile: f swap: swapBytes.
	fullScreenFlag		_ self getLongFromFile: f swap: swapBytes.
	extraVMMemory		_ self getLongFromFile: f swap: swapBytes.

	lastHash = 0 ifTrue: [
		"lastHash wasn't stored (e.g. by the cloner); use 999 as the seed"
		lastHash _ 999].

	"decrease Squeak object heap to leave extra memory for the VM"
	heapSize _ self cCode: 'reserveExtraCHeapBytes(desiredHeapSize, extraVMMemory)'.

	"compare memory requirements with availability".
	minimumMemory _ dataSize + 100000.  "need at least 100K of breathing room"
	heapSize < minimumMemory ifTrue: [
		self insufficientMemorySpecifiedError].

	"allocate a contiguous block of memory for the Squeak heap"
	memory _ self cCode: 'sqAllocateMemory(minimumMemory, heapSize)'.
	memory = nil ifTrue: [self insufficientMemoryAvailableError].

	memStart _ self startOfMemory.
	memoryLimit _ (memStart + heapSize) - 24.  "decrease memoryLimit a tad for safety"
	endOfMemory _ memStart + dataSize.

	"position file after the header"
	self sqImageFile: f Seek: headerStart + headerSize.

	"read in the image in bulk, then swap the bytes if necessary"
	bytesRead _ self cCode: 'sqImageFileRead(pointerForOop(memory), sizeof(unsigned char), dataSize, f)'.
	bytesRead ~= dataSize ifTrue: [self unableToReadImageError].

	headerTypeBytes at: 0 put: BytesPerWord * 2.		"3-word header (type 0)"	
	headerTypeBytes at: 1 put: BytesPerWord.		"2-word header (type 1)"
	headerTypeBytes at: 2 put: 0.					"free chunk (type 2)"	
	headerTypeBytes at: 3 put: 0.					"1-word header (type 3)"

	swapBytes ifTrue: [self reverseBytesInImage].

	"compute difference between old and new memory base addresses"
	bytesToShift _ memStart - oldBaseAddr.
	self initializeInterpreter: bytesToShift.  "adjusts all oops to new location"
	^ dataSize

]

{ #category : #'image save/restore' }
Interpreter >> readableFormat: imageVersion [
	"Anwer true if images of the given format are readable by this interpreter. Allows a virtual machine to accept selected older image formats."

	^ imageVersion = self imageFormatVersion
"
	Example of multiple formats:
	^ (imageVersion = self imageFormatVersion) or: [imageVersion = 6504]
"
]

{ #category : #processes }
Interpreter >> removeFirstLinkOfList: aList [ 
	"Remove the first process from the given linked list."
	| first last next |
	first _ self fetchPointer: FirstLinkIndex ofObject: aList.
	last _ self fetchPointer: LastLinkIndex ofObject: aList.
	first = last
		ifTrue: [self storePointer: FirstLinkIndex ofObject: aList withValue: nilObj.
			self storePointer: LastLinkIndex ofObject: aList withValue: nilObj]
		ifFalse: [next _ self fetchPointer: NextLinkIndex ofObject: first.
			self storePointer: FirstLinkIndex ofObject: aList withValue: next].
	self storePointer: NextLinkIndex ofObject: first withValue: nilObj.
	^ first
]

{ #category : #'image segment in/out' }
Interpreter >> restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut [

	"Restore headers smashed by forwarding links"
	| tablePtr oop header |
	tablePtr _ firstIn.
	[tablePtr <= lastIn] whileTrue:
		[oop _ self longAt: tablePtr.
		header _ self longAt: hdrBaseIn + (tablePtr-firstIn).
		self longAt: oop put: header.
		tablePtr _ tablePtr + BytesPerWord].
	tablePtr _ firstOut.
	[tablePtr <= lastOut] whileTrue:
		[oop _ self longAt: tablePtr.
		header _ self longAt: hdrBaseOut + (tablePtr-firstOut).
		self longAt: oop put: header.
		tablePtr _ tablePtr + BytesPerWord].
	
	"Clear all mark bits"
	oop _ self firstObject.
	[oop < endOfMemory] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[self longAt: oop put: ((self longAt: oop) bitAnd: AllButMarkBit)].
		oop _ self objectAfter: oop].

]

{ #category : #processes }
Interpreter >> resume: aProcess [ 
	| activeProc activePriority newPriority |
	self inline: false.
	activeProc _ self fetchPointer: ActiveProcessIndex ofObject: self schedulerPointer.
	activePriority _ self quickFetchInteger: PriorityIndex ofObject: activeProc.
	newPriority _ self quickFetchInteger: PriorityIndex ofObject: aProcess.
	newPriority > activePriority
		ifTrue: [self putToSleep: activeProc.
			self transferTo: aProcess]
		ifFalse: [self putToSleep: aProcess]
]

{ #category : #'return bytecodes' }
Interpreter >> returnFalse [
	localReturnContext _ self sender.
	localReturnValue _ falseObj.
	self commonReturn.

]

{ #category : #'return bytecodes' }
Interpreter >> returnNil [
	localReturnContext _ self sender.
	localReturnValue _ nilObj.
	self commonReturn.
]

{ #category : #'return bytecodes' }
Interpreter >> returnReceiver [
	localReturnContext _ self sender.
	localReturnValue _ receiver.
	self commonReturn.
]

{ #category : #'return bytecodes' }
Interpreter >> returnTopFromBlock [
	"Return to the caller of the method containing the block."
	localReturnContext _ self caller.  "Note: caller, not sender!"
	localReturnValue _ self internalStackTop.
	self commonReturn.
]

{ #category : #'return bytecodes' }
Interpreter >> returnTopFromMethod [
	localReturnContext _ self sender.
	localReturnValue _ self internalStackTop.
	self commonReturn.
]

{ #category : #'return bytecodes' }
Interpreter >> returnTrue [
	localReturnContext _ self sender.
	localReturnValue _ trueObj.
	self commonReturn.
]

{ #category : #'image save/restore' }
Interpreter >> reverseBytesFrom: startAddr to: stopAddr [
	"Byte-swap the given range of memory (not inclusive of stopAddr!)."
	| addr |
	self flag: #Dan.
	addr _ startAddr.
	[addr < stopAddr] whileTrue:
		[self longAt: addr put: (self byteSwapped: (self longAt: addr)).
		addr _ addr + BytesPerWord].
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
	displayObj _ self splObj: TheDisplay.
	((self isPointers: displayObj) and: [(self lengthOf: displayObj) >= 4]) ifFalse: [^ nil].
	w _ self fetchInteger: 1 ofObject: displayObj.
	dispBitsPtr _ self fetchPointer: 0 ofObject: displayObj.
	(self isIntegerObject: dispBitsPtr) ifTrue: [^ nil].
	dispBitsPtr _ dispBitsPtr + BaseHeaderSize.
	dispBitsPtr + (startIndex * 4) to: dispBitsPtr + (endIndex * 4) by: 4
		do: [:ptr | 
			reversed _ (self long32At: ptr) bitXor: 4294967295.
			self longAt: ptr put: reversed].
	successFlag _ true.
	self displayBitsOf: displayObj Left: 0 Top: 0 Right: w Bottom: 1.
	self ioForceDisplayUpdate
]

{ #category : #'image save/restore' }
Interpreter >> reverseWordsFrom: startAddr to: stopAddr [
	"Word-swap the given range of memory, excluding stopAddr."

	| addr |
	addr _ startAddr.
	[addr < stopAddr] whileTrue:
		[self longAt: addr put: (self wordSwapped: (self longAt: addr)).
		addr _ addr + BytesPerWord].
]

{ #category : #'method lookup cache' }
Interpreter >> rewriteMethodCacheSel: selector class: class primIndex: localPrimIndex [

	"Rewrite the cache entry with the given primitive index and matching function pointer"
	| primPtr |
	self var: #primPtr type: 'void *'.
	self inline: false.
	localPrimIndex = 0
		ifTrue: [primPtr _ 0]
		ifFalse: [primPtr _ primitiveTable at: localPrimIndex].
	self
		rewriteMethodCacheSel: selector class: class
		primIndex: localPrimIndex primFunction: primPtr
]

{ #category : #'method lookup cache' }
Interpreter >> rewriteMethodCacheSel: selector class: class primIndex: localPrimIndex primFunction: localPrimAddress [
	"Rewrite an existing entry in the method cache with a new primitive 
	index & function address. Used by primExternalCall to make direct jumps to found external prims"
	| probe hash |
	self inline: false.
	self var: #localPrimAddress type: 'void *'.
	hash := selector bitXor: class.
	0 to: CacheProbeMax - 1 do: [:p | 
			probe := hash >> p bitAnd: MethodCacheMask.
			((methodCache at: probe + MethodCacheSelector) = selector
					and: [(methodCache at: probe + MethodCacheClass) = class])
				ifTrue: [methodCache at: probe + MethodCachePrim put: localPrimIndex.
					methodCache at: probe + MethodCachePrimFunction put: (self cCoerce: localPrimAddress to: 'long').
					^ nil]]
]

{ #category : #processes }
Interpreter >> saveProcessSignalingLowSpace [
	"The low space semaphore is about to be signaled. Save the currently active
	process in the special objects array so that the low space handler will be able
	to determine the process that first triggered a low space condition. The low
	space handler (in the image) is expected to nil out the special objects array
	slot when it handles the low space condition."

	| lastSavedProcess sched currentProc |
	lastSavedProcess _ self splObj: ProcessSignalingLowSpace.
	(lastSavedProcess == self nilObject) ifTrue:
		[sched _ self schedulerPointer.
		currentProc _ self fetchPointer: ActiveProcessIndex ofObject: sched.
		self storePointer: ProcessSignalingLowSpace ofObject: specialObjectsOop withValue: currentProc]
]

{ #category : #processes }
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
	descriptor _ self fetchByte.
	messageSelector _ self literal: (descriptor bitAnd: 16r3F).
	argumentCount _ descriptor >> 6.
	self normalSend.

]

{ #category : #'send bytecodes' }
Interpreter >> sendLiteralSelectorBytecode [
	"Can use any of the first 16 literals for the selector and pass up to 2 arguments."

	messageSelector _ self literal: (currentBytecode bitAnd: 16rF).
	argumentCount _ ((currentBytecode >> 4) bitAnd: 3) - 1.
	self normalSend
]

{ #category : #contexts }
Interpreter >> sender [

	^ self fetchPointer: SenderIndex ofObject: localHomeContext
]

{ #category : #'compiler support' }
Interpreter >> setCompilerInitialized: newFlag [
	| oldFlag |
	oldFlag _ compilerInitialized.
	compilerInitialized _ newFlag.
	^oldFlag
]

{ #category : #'plugin primitive support' }
Interpreter >> setFullScreenFlag: value [
	fullScreenFlag _ value
]

{ #category : #'plugin primitive support' }
Interpreter >> setInterruptCheckCounter: value [
	interruptCheckCounter _ value
]

{ #category : #'plugin primitive support' }
Interpreter >> setInterruptKeycode: value [
	interruptKeycode _ value
]

{ #category : #'plugin primitive support' }
Interpreter >> setInterruptPending: value [
	interruptPending _ value
]

{ #category : #'plugin primitive support' }
Interpreter >> setNextWakeupTick: value [
	nextWakeupTick _ value
]

{ #category : #'plugin primitive support' }
Interpreter >> setSavedWindowSize: value [
	savedWindowSize _ value
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

{ #category : #processes }
Interpreter >> signalExternalSemaphores [
	"Signal all requested semaphores"
	| xArray xSize index sema |
	semaphoresUseBufferA _ semaphoresUseBufferA not.
	xArray _ self splObj: ExternalObjectsArray.
	xSize _ self stSizeOf: xArray.
	semaphoresUseBufferA
		ifTrue: ["use opposite buffer during read"
			1 to: semaphoresToSignalCountB do: [:i | 
					index _ semaphoresToSignalB at: i.
					index <= xSize
						ifTrue: [sema _ self fetchPointer: index - 1 ofObject: xArray.
							"Note: semaphore indices are 1-based"
							(self fetchClassOf: sema) = (self splObj: ClassSemaphore)
								ifTrue: [self synchronousSignal: sema]]].
			semaphoresToSignalCountB _ 0]
		ifFalse: [1 to: semaphoresToSignalCountA do: [:i | 
					index _ semaphoresToSignalA at: i.
					index <= xSize
						ifTrue: [sema _ self fetchPointer: index - 1 ofObject: xArray.
							"Note: semaphore indices are 1-based"
							(self fetchClassOf: sema) = (self splObj: ClassSemaphore)
								ifTrue: [self synchronousSignal: sema]]].
			semaphoresToSignalCountA _ 0]
]

{ #category : #processes }
Interpreter >> signalFinalization: weakReferenceOop [
	"If it is not there already, record the given semaphore index in the list of semaphores to be signaled at the next convenient moment. Force a real interrupt check as soon as possible."

	self forceInterruptCheck.
	pendingFinalizationSignals _ pendingFinalizationSignals + 1.
]

{ #category : #processes }
Interpreter >> signalSemaphoreWithIndex: index [
	"Record the given semaphore index in the double buffer semaphores array to be signaled at the next convenient moment. Force a real interrupt check as soon as possible."

	index <= 0 ifTrue: [^ nil].  "bad index; ignore it"

	semaphoresUseBufferA
		ifTrue: [semaphoresToSignalCountA < SemaphoresToSignalSize
			ifTrue: [ semaphoresToSignalCountA _ semaphoresToSignalCountA + 1.
				semaphoresToSignalA at: semaphoresToSignalCountA put: index]]
		ifFalse: [semaphoresToSignalCountB < SemaphoresToSignalSize
			ifTrue: [ semaphoresToSignalCountB _ semaphoresToSignalCountB + 1.
				semaphoresToSignalB at: semaphoresToSignalCountB put: index]].
	self forceInterruptCheck

]

{ #category : #'primitive support' }
Interpreter >> signed32BitIntegerFor: integerValue [
	"Return a full 32 bit integer object for the given integer value"
	| newLargeInteger value largeClass |
	self inline: false.
	(self isIntegerValue: integerValue)
		ifTrue: [^ self integerObjectOf: integerValue].
	integerValue < 0
		ifTrue:[	largeClass _ self classLargeNegativeInteger.
				value _ 0 - integerValue]
		ifFalse:[	largeClass _ self classLargePositiveInteger.
				value _ integerValue].
	newLargeInteger _ self instantiateClass: largeClass indexableSize: 4.
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
	self inline: false.
	(self isIntegerObject: oop) ifTrue: [^self integerValueOf: oop].
	largeClass _ self fetchClassOf: oop.
	largeClass = self classLargePositiveInteger
		ifTrue:[negative _ false]
		ifFalse:[largeClass = self classLargeNegativeInteger
					ifTrue:[negative _ true]
					ifFalse:[^self primitiveFail]].
	sz _ self lengthOf: oop.
	sz = 4 ifFalse: [^ self primitiveFail].
	value _ (self fetchByte: 0 ofObject: oop) +
		  ((self fetchByte: 1 ofObject: oop) <<  8) +
		  ((self fetchByte: 2 ofObject: oop) << 16) +
		  ((self fetchByte: 3 ofObject: oop) << 24).
	negative
		ifTrue:[^0 - value]
		ifFalse:[^value]
]

{ #category : #'primitive support' }
Interpreter >> signed64BitIntegerFor: integerValue [
	"Return a Large Integer object for the given integer value"
	| newLargeInteger value largeClass intValue check |
	self inline: false.
	self var: 'integerValue' type: 'sqLong'.
	self var: 'value' type: 'sqLong'.
	integerValue < 0
		ifTrue:[	largeClass _ self classLargeNegativeInteger.
				value _ 0 - integerValue]
		ifFalse:[	largeClass _ self classLargePositiveInteger.
				value _ integerValue].

	(self sizeof: value) = 4 ifTrue: [^self signed32BitIntegerFor: integerValue].

	self cCode: 'check = value >> 32'.
	check = 0 ifTrue: [^self signed32BitIntegerFor: integerValue].

	newLargeInteger _ self instantiateSmallClass: largeClass sizeInBytes:  BaseHeaderSize + 8.
	0 to: 7 do: [:i |
		self cCode: 'intValue = ( value >> (i * 8)) & 255'.
		self storeByte: i ofObject: newLargeInteger withValue: intValue].
	^ newLargeInteger
]

{ #category : #'primitive support' }
Interpreter >> signed64BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive ST integer or a eight-byte LargeInteger."
	| sz value largeClass negative szsqLong |
	self inline: false.
	self returnTypeC: 'sqLong'.
	self var: 'value' type: 'sqLong'.
	(self isIntegerObject: oop) ifTrue: [^self cCoerce: (self integerValueOf: oop) to: 'sqLong'].
	largeClass _ self fetchClassOf: oop.
	largeClass = self classLargePositiveInteger
		ifTrue:[negative _ false]
		ifFalse:[largeClass = self classLargeNegativeInteger
					ifTrue:[negative _ true]
					ifFalse:[^self primitiveFail]].
	szsqLong _ self cCode: 'sizeof(sqLong)'.
	sz _ self lengthOf: oop.
	sz > szsqLong 
		ifTrue: [^ self primitiveFail].
	value _ 0.
	0 to: sz - 1 do: [:i |
		value _ value + ((self cCoerce: (self fetchByte: i ofObject: oop) to: 'sqLong') <<  (i*8))].
	negative
		ifTrue:[^0 - value]
		ifFalse:[^value]
]

{ #category : #'send bytecodes' }
Interpreter >> singleExtendedSendBytecode [
	"Can use any of the first 32 literals for the selector and pass up to 7 arguments."

	| descriptor |
	descriptor _ self fetchByte.
	messageSelector _ self literal: (descriptor bitAnd: 16r1F).
	argumentCount _ descriptor >> 5.
	self normalSend.
]

{ #category : #'send bytecodes' }
Interpreter >> singleExtendedSuperBytecode [
	"Can use any of the first 32 literals for the selector and pass up to 7 arguments."

	| descriptor |
	descriptor _ self fetchByte.
	messageSelector _ self literal: (descriptor bitAnd: 16r1F).
	argumentCount _ descriptor >> 5.
	self superclassSend.

]

{ #category : #utilities }
Interpreter >> sizeOfSTArrayFromCPrimitive: cPtr [
	"Return the number of indexable fields of the given object. This method is to be called from an automatically generated C primitive. The argument is assumed to be a pointer to the first indexable field of a words or bytes object; the object header starts 4 bytes before that."
	"Note: Only called by translated primitive code."

	| oop |
	self var: #cPtr type: 'void *'.
	oop _ (self oopForPointer: cPtr) - BaseHeaderSize.
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
	self var: #setMacType type: 'void *'.
	compilerInitialized
		ifTrue: [self compilerPreSnapshot]
		ifFalse: [self storeContextRegisters: activeContext].

	"update state of active process"
	activeProc _ self fetchPointer: ActiveProcessIndex ofObject: self schedulerPointer.
	self
		storePointer: SuspendedContextIndex
		ofObject: activeProc
		withValue: activeContext.

	"compact memory and compute the size of the memory actually in use"
	self incrementalGC.

	"maximimize space for forwarding table"
	self fullGC.
	self snapshotCleanUp.

	dataSize _ freeBlock - self startOfMemory. "Assume all objects are below the start of the free block"
	successFlag
		ifTrue: [rcvr _ self popStack.
			"pop rcvr"
			self push: trueObj.
			self writeImageFile: dataSize.
			embedded
				ifFalse: ["set Mac file type and creator; this is a noop on other platforms"
					setMacType _ self ioLoadFunction: 'setMacFileTypeAndCreator' From: 'FilePlugin'.
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
	oop _ self firstObject.
	[oop < endOfMemory]
		whileTrue: [(self isFreeObject: oop)
				ifFalse: [header _ self longAt: oop.
					fmt _ header >> 8 bitAnd: 15.
					"Clean out context"
					(fmt = 3 and: [self isContextHeader: header])
						ifTrue: [sz _ self sizeBitsOf: oop.
							(self lastPointerOf: oop) + BytesPerWord
								to: sz - BaseHeaderSize by: BytesPerWord
								do: [:i | self longAt: oop + i put: nilObj]].
					"Clean out external functions"
					fmt >= 12
						ifTrue: ["This is a compiled method"
							(self primitiveIndexOf: oop) = PrimitiveExternalCallIndex
								ifTrue: ["It's primitiveExternalCall"
									self flushExternalPrimitiveOf: oop]]].
			oop _ self objectAfter: oop].
	self clearRootsTable
]

{ #category : #'message sending' }
Interpreter >> specialSelector: index [

	^ self fetchPointer: (index * 2) ofObject: (self splObj: SpecialSelectors)
]

{ #category : #'array and stream primitive support' }
Interpreter >> stObject: array at: index [
	"Return what ST would return for <obj> at: index."

	| hdr fmt totalLength fixedFields stSize |
	self inline: false.
	hdr _ self baseHeader: array.
	fmt _ (hdr >> 8) bitAnd: 16rF.
	totalLength _ self lengthOf: array baseHeader: hdr format: fmt.
	fixedFields _ self fixedFieldsOf: array format: fmt length: totalLength.
	(fmt = 3 and: [self isContextHeader: hdr])
		ifTrue: [stSize _ self fetchStackPointerOf: array]
		ifFalse: [stSize _ totalLength - fixedFields].
	((self cCoerce: index to: 'usqInt ') >= 1
		and: [(self cCoerce: index to: 'usqInt ') <= (self cCoerce: stSize to: 'usqInt ')])
		ifTrue: [^ self subscript: array with: (index + fixedFields) format: fmt]
		ifFalse: [successFlag _ false.  ^ 0].
]

{ #category : #'array and stream primitive support' }
Interpreter >> stObject: array at: index put: value [
	"Do what ST would return for <obj> at: index put: value."
	| hdr fmt totalLength fixedFields stSize |
	self inline: false.
	hdr _ self baseHeader: array.
	fmt _ (hdr >> 8) bitAnd: 16rF.
	totalLength _ self lengthOf: array baseHeader: hdr format: fmt.
	fixedFields _ self fixedFieldsOf: array format: fmt length: totalLength.
	(fmt = 3 and: [self isContextHeader: hdr])
		ifTrue: [stSize _ self fetchStackPointerOf: array]
		ifFalse: [stSize _ totalLength - fixedFields].
	((self cCoerce: index to: 'usqInt ') >= 1
		and: [(self cCoerce: index to: 'usqInt ') <= (self cCoerce: stSize to: 'usqInt ')])
		ifTrue: [self subscript: array with: (index + fixedFields) storing: value format: fmt]
		ifFalse: [successFlag _ false]
]

{ #category : #'array and stream primitive support' }
Interpreter >> stSizeOf: oop [
	"Return the number of indexable fields in the given object. (i.e., what Smalltalk would return for <obj> size)."
	"Note: Assume oop is not a SmallInteger!"

	| hdr fmt totalLength fixedFields |
	self inline: false.
	hdr _ self baseHeader: oop.
	fmt _ (hdr >> 8) bitAnd: 16rF.
	totalLength _ self lengthOf: oop baseHeader: hdr format: fmt.
	fixedFields _ self fixedFieldsOf: oop format: fmt length: totalLength.
	(fmt = 3 and: [self isContextHeader: hdr])
		ifTrue: [^ self fetchStackPointerOf: oop]
		ifFalse: [^ totalLength - fixedFields]
]

{ #category : #contexts }
Interpreter >> stackFloatValue: offset [
	"Note: May be called by translated primitive code."
	| result floatPointer |
	self returnTypeC: 'double'.
	self var: #result type: 'double '.
	floatPointer _ self longAt: stackPointer - (offset*BytesPerWord).
	(self fetchClassOf: floatPointer) = (self splObj: ClassFloat) 
		ifFalse:[self primitiveFail. ^0.0].
	self cCode: '' inSmalltalk: [result _ Float new: 2].
	self fetchFloatAt: floatPointer + BaseHeaderSize into: result.
	^ result
]

{ #category : #contexts }
Interpreter >> stackIntegerValue: offset [
	| integerPointer |
	integerPointer _ self longAt: stackPointer - (offset*BytesPerWord).
	^self checkedIntegerValueOf: integerPointer
]

{ #category : #contexts }
Interpreter >> stackObjectValue: offset [
	"Ensures that the given object is a real object, not a SmallInteger."

	| oop |
	oop _ self longAt: stackPointer - (offset * BytesPerWord).
	(self isIntegerObject: oop) ifTrue: [self primitiveFail. ^ nil].
	^ oop

]

{ #category : #contexts }
Interpreter >> stackPointerIndex [
	"Return the 0-based index rel to the current context.
	(This is what stackPointer used to be before conversion to pointer"
	^ (stackPointer - activeContext - BaseHeaderSize) >> ShiftForWord
]

{ #category : #contexts }
Interpreter >> stackTop [
	^self longAt: stackPointer
]

{ #category : #contexts }
Interpreter >> stackValue: offset [
	^ self longAt: stackPointer - (offset*BytesPerWord)
]

{ #category : #'stack bytecodes' }
Interpreter >> storeAndPopReceiverVariableBytecode [
	"Note: This code uses 
	storePointerUnchecked:ofObject:withValue: and does the 
	store check explicitely in order to help the translator 
	produce better code."
	| rcvr top |
	self fetchNextBytecode.
	"this bytecode will be expanded so that refs to 
	currentBytecode below will be constant"
	rcvr _ receiver.
	top _ self internalStackTop.
	rcvr < youngStart
		ifTrue: [self possibleRootStoreInto: rcvr value: top].
	self storePointerUnchecked: (currentBytecode bitAnd: 7) ofObject: rcvr withValue: top.
	self internalPop: 1
]

{ #category : #'stack bytecodes' }
Interpreter >> storeAndPopTemporaryVariableBytecode [

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
	method oop + ip + BaseHeaderSize
		-1 for 0-based addressing of fetchByte
		-1 because it gets incremented BEFORE fetching currentByte"

	self inline: true.
	self storePointerUnchecked: InstructionPointerIndex ofObject: activeCntx
		withValue: (self integerObjectOf: (instructionPointer - method - (BaseHeaderSize - 2))).
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

{ #category : #contexts }
Interpreter >> storeStackPointerValue: value inContext: contextPointer [
	"Assume: value is an integerValue"

	self storePointerUnchecked: StackPointerIndex ofObject: contextPointer
		withValue: (self integerObjectOf: value).
]

{ #category : #'array and stream primitive support' }
Interpreter >> subscript: array with: index format: fmt [
	"Note: This method assumes that the index is within bounds!"

	self inline: true.
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

{ #category : #'array and stream primitive support' }
Interpreter >> subscript: array with: index storing: oopToStore format: fmt [ 
	"Note: This method assumes that the index is within bounds!"
	| valueToStore |
	self inline: true.
	fmt <= 4
		ifTrue: ["pointer type objects"
			self storePointer: index - 1 ofObject: array
				withValue: oopToStore]
		ifFalse: [fmt < 8
				ifTrue: ["long-word type objects"
					valueToStore _ self positive32BitValueOf: oopToStore.
					successFlag
						ifTrue: [self storeLong32: index - 1 ofObject: array
									withValue: valueToStore]]
				ifFalse: ["byte-type objects"
					(self isIntegerObject: oopToStore)
						ifFalse: [successFlag _ false].
					valueToStore _ self integerValueOf: oopToStore.
					(valueToStore >= 0
							and: [valueToStore <= 255])
						ifFalse: [successFlag _ false].
					successFlag
						ifTrue: [self
								storeByte: index - 1
								ofObject: array
								withValue: valueToStore]]]
]

{ #category : #'primitive support' }
Interpreter >> success: successValue [

	successFlag _ successValue & successFlag.
]

{ #category : #'object access primitives' }
Interpreter >> sufficientSpaceToInstantiate: classOop indexableSize: size [ 
	"Return the number of bytes required to allocate an instance of the given class with the given number of indexable fields."
	"Details: For speed, over-estimate space needed for fixed fields or literals; the low space threshold is a blurry line."
	| format atomSize|
	self inline: true.
	format _ (self formatOfClass: classOop) >> 8 bitAnd: 15.

	"fail if attempting to call new: on non-indexable class"
	((self cCoerce: size to: 'usqInt ') > 0 and: [format < 2])
		ifTrue: [^ false].

	format < 8
		ifTrue: ["indexable fields are words or pointers" atomSize _ BytesPerWord]
		ifFalse: ["indexable fields are bytes" atomSize _ 1].
	^self sufficientSpaceToAllocate: 2500 + (size * atomSize)
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
	self inline: true.
	self sharedCodeNamed: 'commonSupersend' inCase: 133.
	lkupClass _ self superclassOf: (self methodClassOf: method).
	rcvr _ self internalStackValue: argumentCount.
	receiverClass _ self fetchClassOf: rcvr.
	self commonSend.
]

{ #category : #processes }
Interpreter >> synchronousSignal: aSemaphore [ 
	"Signal the given semaphore from within the interpreter."
	| excessSignals |
	self inline: false.
	(self isEmptyList: aSemaphore)
		ifTrue: ["no process is waiting on this semaphore"
			excessSignals _ self fetchInteger: ExcessSignalsIndex ofObject: aSemaphore.
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
	self flag: #Dan.  "Need to check all senders before converting this for 64 bits"
	self inline: true.
	in _ src - BytesPerWord.
	lastIn _ in + (count * BytesPerWord).
	out _ dst - BytesPerWord.
	[in < lastIn]
		whileTrue: [self
				longAt: (out _ out + BytesPerWord)
				put: (self longAt: (in _ in + BytesPerWord))]
]

{ #category : #utilities }
Interpreter >> transfer: count fromIndex: firstFrom ofObject: fromOop toIndex: firstTo ofObject: toOop [
	"Transfer the specified fullword fields, as from calling context to called context"
	
	"Assume: beRootIfOld: will be called on toOop."
	| fromIndex toIndex lastFrom |
	self flag: #Dan.  "Need to check all senders before converting this for 64 bits"
	self inline: true.
	fromIndex _ fromOop + (firstFrom * BytesPerWord).
	toIndex _ toOop + (firstTo * BytesPerWord).
	lastFrom _ fromIndex + (count * BytesPerWord).
	[fromIndex < lastFrom]
		whileTrue: [fromIndex _ fromIndex + BytesPerWord.
			toIndex _ toIndex + BytesPerWord.
			self
				longAt: toIndex
				put: (self longAt: fromIndex)]
]

{ #category : #processes }
Interpreter >> transferTo: aProc [ 
	"Record a process to be awoken on the next interpreter cycle. 
	ikp 11/24/1999 06:07 -- added hook for external runtime 
	compiler "
	| sched oldProc newProc |
	newProc _ aProc.
	sched _ self schedulerPointer.
	oldProc _ self fetchPointer: ActiveProcessIndex ofObject: sched.
	self storePointer: ActiveProcessIndex ofObject: sched withValue: newProc.
	compilerInitialized
		ifTrue: [self compilerProcessChange: oldProc to: newProc]
		ifFalse: [self storePointer: SuspendedContextIndex ofObject: oldProc withValue: activeContext.
			self newActiveContext: (self fetchPointer: SuspendedContextIndex ofObject: newProc).
			self storePointer: SuspendedContextIndex ofObject: newProc withValue: nilObj].
	reclaimableContextCount _ 0
]

{ #category : #contexts }
Interpreter >> unPop: nItems [
	stackPointer _ stackPointer + (nItems*BytesPerWord)
]

{ #category : #'interpreter shell' }
Interpreter >> unknownBytecode [
	"This should never get called; it means that an unimplemented bytecode appears in a CompiledMethod."

	self error: 'Unknown bytecode'.
]

{ #category : #'debug support' }
Interpreter >> verifyCleanHeaders [
	| oop |
	oop _ self firstObject.
	[oop < endOfMemory] whileTrue:
		[(self isFreeObject: oop)
			ifTrue: ["There should only be one free block at end of memory."
					(self objectAfter: oop) = endOfMemory
						ifFalse: [self error: 'Invalid obj with HeaderTypeBits = Free.']]
			ifFalse: [((self longAt: oop) bitAnd: MarkBit) = 0
						ifFalse: [self error: 'Invalid obj with MarkBit set.']].
		oop _ self objectAfter: oop]
]

{ #category : #'plugin support' }
Interpreter >> vmEndianness [
	"return 0 for little endian, 1 for big endian"

	self isBigEnder ifTrue: [^ 1] ifFalse: [^ 0]

]

{ #category : #processes }
Interpreter >> wakeHighestPriority [
	"Return the highest priority process that is ready to run."
	"Note: It is a fatal VM error if there is no runnable process."
	| schedLists p processList |
	schedLists _ self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	p _ self fetchWordLengthOf: schedLists.
	p _ p - 1.
	"index of last indexable field"
	processList _ self fetchPointer: p ofObject: schedLists.
	[self isEmptyList: processList]
		whileTrue: [p _ p - 1.
			p < 0 ifTrue: [self error: 'scheduler could not find a runnable process'].
			processList _ self fetchPointer: p ofObject: schedLists].
	^ self removeFirstLinkOfList: processList
]

{ #category : #'image save/restore' }
Interpreter >> wordSwapped: w [
	"Return the given 64-bit integer with its halves in the reverse order."

	BytesPerWord = 8 ifFalse: [self error: 'This cannot happen.'].
	^   ((w bitShift: Byte4ShiftNegated) bitAnd: Bytes3to0Mask)
	  + ((w bitShift: Byte4Shift         ) bitAnd: Bytes7to4Mask)

]

{ #category : #'image save/restore' }
Interpreter >> writeImageFile: imageBytes [

	| fn |
	self var: #fn type: 'void *'.
	self writeImageFileIO: imageBytes.
	"set Mac file type and creator; this is a noop on other platforms"
	fn _ self ioLoadFunction: 'setMacFileTypeAndCreator' From: 'FilePlugin'.
	fn = 0 ifFalse:[
		self cCode:'((sqInt (*)(char*, char*, char*))fn)(imageName, "STim", "FAST")'.
	].

]

{ #category : #'image save/restore' }
Interpreter >> writeImageFileIO: imageBytes [

	| headerStart headerSize f bytesWritten sCWIfn okToWrite |
	self var: #f type: 'sqImageFile'.
	self var: #headerStart type: 'squeakFileOffsetType '.
	self var: #sCWIfn type: 'void *'.

	"If the security plugin can be loaded, use it to check for write permission.
	If not, assume it's ok"
	sCWIfn _ self ioLoadFunction: 'secCanWriteImage' From: 'SecurityPlugin'.
	sCWIfn ~= 0 ifTrue:[okToWrite _ self cCode: '((sqInt (*)(void))sCWIfn)()'.
		okToWrite ifFalse:[^self primitiveFail]].
	
	"local constants"
	headerStart _ 0.  
	headerSize _ 64.  "header size in bytes; do not change!"

	f _ self cCode: 'sqImageFileOpen(imageName, "wb")'.
	f = nil ifTrue: [
		"could not open the image file for writing"
		self success: false.
		^ nil].

	headerStart _ self cCode: 'sqImageFileStartLocation(f,imageName,headerSize+imageBytes)'.
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
	bytesWritten _ self cCode: 'sqImageFileWrite(pointerForOop(memory), sizeof(unsigned char), imageBytes, f)'.
	self success: bytesWritten = imageBytes.
	self cCode: 'sqImageFileClose(f)'.


]
