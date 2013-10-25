"
This class is a complete implementation of the Smalltalk-80 virtual machine, derived originally from the Blue Book specification but quite different in some areas.

It has been modernized with 32-bit pointers, better management of Contexts, and attention to variable use that allows the CCodeGenerator (qv) to keep, eg, the instruction pointer and stack pointer in registers as well as keeping most simple variables in a global array that seems to improve performance for most platforms.

The latest version has been extend to support 64 bit systems in at least a basic manner - it is possible to create a 64 bit image via a special SystemTracer - and much of the core code has been cleaned up so that it works whether the C compiler thinks integers are 32 or 64 bit in size. There is still some cleanup required.

In addition to SmallInteger arithmetic and Floats, it supports logic on 32-bit PositiveLargeIntegers, thus allowing it to simulate itself much more effectively than would otherwise be the case.

NOTE:  Here follows a list of things to be borne in mind when working on this code, or when making changes for the future.

1.  There are a number of things that should be done the next time we plan to release a copletely incompatible image format.  These include unifying the instanceSize field of the class format word -- see instantiateClass:indexableSize:, and unifying the bits of the method primitive index (if we decide we need more than 512, after all) -- see primitiveIndexOf:.  Also, contexts should be given a special format code (see next item).

2.  There are several fast checks for contexts (see isContextHeader: and isMethodContextHeader:) which will fail if the compact class indices of BlockContext or MethodContext change.  This is necessary because the oops may change during a compaction when the oops are being adjusted.  It's important to be aware of this when writing a new image using the systemTracer.  A better solution would be to reserve one of the format codes for Contexts only.

3.  We have made normal files tolerant to size and positions up to 32 bits.  This has not been done for async files, since they are still experimental.  The code in size, at: and at:put: should work with sizes and indices up to 31 bits, although I have not tested it (di 12/98); it might or might not work with 32-bit sizes.

4.  Note that 0 is used in a couple of places as an impossible oop.  This should be changed to a constant that really is impossible (or perhaps there is code somewhere that guarantees it --if so it should be put in this comment).  The places include the method cache and the at cache. 
"
Class {
	#name : #NewspeakInterpreter,
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
		'primFailCode',
		'primitiveFunctionPointer',
		'inIOProcessEvents',
		'methodCache',
		'atCache',
		'lkupClass',
		'reclaimableContextCount',
		'nextPollTick',
		'nextWakeupTick',
		'lastTick',
		'interruptKeycode',
		'interruptPending',
		'gcSemaphoreIndex',
		'savedWindowSize',
		'fullScreenFlag',
		'deferDisplayUpdates',
		'pendingFinalizationSignals',
		'extraVMMemory',
		'imageFormatVersionNumber',
		'interpreterProxy',
		'showSurfaceFn',
		'interruptCheckCounterFeedBackReset',
		'interruptChecksEveryNms',
		'externalPrimitiveTable',
		'primitiveTable',
		'globalSessionID',
		'metaclassSizeBits',
		'thisClassIndex',
		'classNameIndex',
		'statPendingFinalizationSignals',
		'breakSelector',
		'breakSelectorLength',
		'primTraceLog',
		'primTraceLogIndex',
		'sendTraceLog',
		'sendTraceLogIndex'
	],
	#classVars : [
		'AtCacheEntries',
		'AtCacheFixedFields',
		'AtCacheFmt',
		'AtCacheMask',
		'AtCacheOop',
		'AtCacheSize',
		'AtCacheTotalSize',
		'AtPutBase',
		'BlockArgumentCountIndex',
		'BytecodeTable',
		'CacheProbeMax',
		'CallerIndex',
		'CrossedX',
		'DirBadPath',
		'DirEntryFound',
		'DirNoMoreEntries',
		'EnclosingMixinIndex',
		'EnclosingObjectIndex',
		'EndOfRun',
		'FailImbalancedPrimitives',
		'HomeIndex',
		'InitialIPIndex',
		'MaxExternalPrimitiveTableSize',
		'MaxPrimitiveIndex',
		'MaxQuickPrimitiveIndex',
		'MessageDictionaryIndex',
		'MillisecondClockMask',
		'MixinIndex',
		'MixinNameIndex',
		'PrimitiveExternalCallIndex',
		'PrimitiveTable',
		'RecordPrimTrace',
		'RecordSendTrace',
		'TempFrameStart',
		'TraceLogSize'
	],
	#pools : [
		'VMBasicConstants',
		'VMMethodCacheConstants',
		'VMObjectIndices'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #translation }
NewspeakInterpreter class >> additionalHeadersDo: aBinaryBlock [
	"Evaluate aBinaryBlock with the names and contents of
	 any additional header files that need to be generated."
	aBinaryBlock
		value: 'vmCallback.h'
		value: self vmCallbackHeader
]

{ #category : #translation }
NewspeakInterpreter class >> additionalSelectorTables [
	^{ self primitiveTable }
]

{ #category : #translation }
NewspeakInterpreter class >> ancilliaryClasses: options [
	^{ VMCallbackContext }
]

{ #category : #constants }
NewspeakInterpreter class >> bytecodeTable [

	^ BytecodeTable
]

{ #category : #translation }
NewspeakInterpreter class >> declareCVarsIn: aCCodeGenerator [

	aCCodeGenerator
		addHeaderFile:'<stddef.h> /* for e.g. alloca */';
		addHeaderFile:'<setjmp.h>';
		addHeaderFile:'"vmCallback.h"';
		addHeaderFile:'"dispdbg.h"'.
	aCCodeGenerator 
		var: #interpreterProxy 
		type: #'struct VirtualMachine*'.
	aCCodeGenerator
		declareVar: #sendTrace type: 'volatile int';
		declareVar: #byteCount type: 'unsigned long'.
	aCCodeGenerator
		var: #primitiveTable
		declareC: 'void *primitiveTable[', (MaxPrimitiveIndex +2) printString, '] = ',	self primitiveTableString.
	aCCodeGenerator
		var: #primitiveFunctionPointer
		declareC: 'void (*primitiveFunctionPointer)()'.
	aCCodeGenerator
		var: #methodCache
		declareC: 'long methodCache[', (MethodCacheSize + 1) printString, ']'.
	aCCodeGenerator
		var: #atCache
		declareC: 'sqInt atCache[', (AtCacheTotalSize + 1) printString, ']'.
	aCCodeGenerator var: #localIP type: #'char*'.
	aCCodeGenerator var: #localSP type: #'char*'.
	aCCodeGenerator var: #showSurfaceFn type: #'void*'.
	"Newspeak as of mid 2011 derives SystemScope systemName from the interpreterVersion (via system attribute 1004)
	 by copying up to but not including the last space, provided the string ends with a digit.  So spaces must be eliminated
	 from the Monitcello version string, and we can't surround it with square brackets.."
	(aCCodeGenerator shortMonticelloDescriptionForClass: self) last isDigit ifFalse:
		[self error: 'Newspeak expects interpreterVersion ends with a digit'].
	aCCodeGenerator
		var: #interpreterVersion
		declareC: 'const char *interpreterVersion = "Newspeak Virtual Machine ',
						((aCCodeGenerator shortMonticelloDescriptionForClass: self) copyReplaceAll: ' ' with: '_'),
						'"'.
	aCCodeGenerator
		var: #externalPrimitiveTable
		declareC: 'void *externalPrimitiveTable[', (MaxExternalPrimitiveTableSize + 1) printString, ']'.

	aCCodeGenerator
		var: #imageFormatVersionNumber
		declareC: 'sqInt imageFormatVersionNumber = ',
					(BytesPerWord == 4
						ifTrue: ['6502']
						ifFalse: ['68000']).
	aCCodeGenerator
		var: #breakSelector type: #'char *';
		var: #breakSelectorLength
		declareC: 'sqInt breakSelectorLength = -1';
		var: #primTraceLogIndex type: #'unsigned char';
		var: #primTraceLog declareC: 'sqInt primTraceLog[256]';
		var: #sendTraceLogIndex type: #'unsigned char';
		var: #sendTraceLog declareC: 'sqInt sendTraceLog[256]'

]

{ #category : #translation }
NewspeakInterpreter class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return.
	 Try and use sqInt for the interpreter and whatever ObjectMemory wants
	 (void at time of writing) for ObjectMemory methods."
	^(ObjectMemory canUnderstand: aSelector)
		ifTrue: [ObjectMemory implicitReturnTypeFor: aSelector]
		ifFalse: [#sqInt]
]

{ #category : #initialization }
NewspeakInterpreter class >> initializeAssociationIndex [
	ValueIndex := 1
]

{ #category : #initialization }
NewspeakInterpreter class >> initializeBytecodeTable [
	"NewspeakInterpreter initializeBytecodeTable"
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

		"Newspeak bytecodes"
		(126 dynamicSuperSendBytecode)
		(127 pushImplicitReceiverBytecode)

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

		"Closure & Newspeak bytecodes"
		(138 pushNewArrayBytecode)
		(139 pushExplicitOuterSendReceiverBytecode)
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

		(208 223 sendLiteralSelector0ArgsBytecode)
		(224 239 sendLiteralSelector1ArgBytecode)
		(240 255 sendLiteralSelector2ArgsBytecode)
	).
]

{ #category : #initialization }
NewspeakInterpreter class >> initializeCaches [

	| atCacheEntrySize |
	MethodCacheEntries := 1024. 
	MethodCacheSelector := 1.
	MethodCacheClass := 2.
	MethodCacheMethod := 3.
	MethodCachePrimFunction := 4.
	MethodCacheEntrySize := 4.  "Must be power of two for masking scheme."
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
NewspeakInterpreter class >> initializeCharacterIndex [
	CharacterValueIndex := 0
]

{ #category : #initialization }
NewspeakInterpreter class >> initializeCharacterScannerIndices [
	CrossedX := 258.
	EndOfRun := 257

]

{ #category : #initialization }
NewspeakInterpreter class >> initializeClassIndices [
	"Behavior"
	SuperclassIndex := 0.
	MessageDictionaryIndex := 1.
	InstanceSpecificationIndex := 2.

	"Fields of a Mixin (also defined by Behavior)"
	EnclosingMixinIndex := 3.  "(Class instVarIndexFor: 'mixinSlot') - 1"
	"Fields of a MixinApplication (also defined by Behavior)"
	MixinIndex := 3. "(Class instVarIndexFor: 'mixinSlot') - 1"
	MixinNameIndex := 8.  "(Class instVarIndexFor: 'name') - 1"
	EnclosingObjectIndex := 4. "(Class instVarIndexFor: 'enclosingObjectSlot') - 1"

	"Fields of a message dictionary"
	MethodArrayIndex := 1.
	SelectorStart := 2
]

{ #category : #initialization }
NewspeakInterpreter class >> initializeCompactClassIndices [
	"Initialize indices for compact classes we are going to depend on being compact.
	 The VI allows classes to become compact and become uncompact.  For efficiency
	 the VM assumes certain classes are compact with particular indices."

	"Smalltalk compactClassesArray"
	"{Array. LargePositiveInteger. Float. MethodContext. } collect: [:c| c -> c indexIfCompact]"

	ClassArrayCompactIndex := 3.
	ClassLargeNegativeIntegerCompactIndex := 0. "Currently PseudoContext class"
	ClassLargePositiveIntegerCompactIndex := 5.
	ClassFloatCompactIndex := 6.
	ClassBlockClosureCompactIndex := 0 "12". "Prospective.  May still be TranslatedMethod class"
	ClassByteStringCompactIndex := 11.
	ClassBlockContextCompactIndex := 13.
	ClassMethodContextCompactIndex := 14.

	ClassByteArrayCompactIndex := 0.
	ClassMessageCompactIndex := 0.
	ClassBitmapCompactIndex := 0
]

{ #category : #initialization }
NewspeakInterpreter class >> initializeContextIndices [
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
NewspeakInterpreter class >> initializeDirectoryLookupResultCodes [

	DirEntryFound := 0.
	DirNoMoreEntries := 1.
	DirBadPath := 2.
]

{ #category : #initialization }
NewspeakInterpreter class >> initializeMessageIndices [
	MessageSelectorIndex := 0.
	MessageArgumentsIndex := 1.
	MessageLookupClassIndex := 2.
]

{ #category : #initialization }
NewspeakInterpreter class >> initializeMethodIndices [
	"Class CompiledMethod"
	HeaderIndex := 0.
	LiteralStart := 1
]

{ #category : #initialization }
NewspeakInterpreter class >> initializeMiscConstants [

	super initializeMiscConstants.
	NewspeakVM := true.
	IMMUTABILITY := initializationOptions at: #IMMUTABILITY ifAbsent: [true].

	PrimitiveExternalCallIndex := 117. "Primitive index for #primitiveExternalCall"
	MillisecondClockMask := 16r1FFFFFFF.
	"Note: The external primitive table should actually be dynamically sized but for the sake of inferior platforms (e.g., Mac :-) who cannot allocate memory in any reasonable way, we keep it static (and cross our fingers...)"
	MaxExternalPrimitiveTableSize := 1024. "entries"

	FailImbalancedPrimitives ifNil: [FailImbalancedPrimitives := false].
	RecordPrimTrace := false.
	RecordSendTrace := false.
	TraceLogSize := 256
]

{ #category : #initialization }
NewspeakInterpreter class >> initializePointIndices [
	XIndex := 0.
	YIndex := 1
]

{ #category : #initialization }
NewspeakInterpreter class >> initializePrimitiveTable [ 
	"This table generates a C function address table use in primitiveResponse along with dispatchFunctionPointerOn:in:"

	"NOTE: The real limit here is 2047 because of the method header layout but there is no point in going over the needed size"
	MaxPrimitiveIndex := 575.
	MaxQuickPrimitiveIndex := 519.
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

		"LargeInteger Primitives (20-37)"
		(20 primitiveRemLargeIntegers)
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

		"Float Primitives (38-59)"
		(38 primitiveAt) "for compatibility with Cog's primitiveFloatAt"
		(39 primitiveAtPut) "for compatibility with Cog's primitiveFloatAtPut"
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
		(96 primitiveFail)	"was primitiveObsoleteIndexedPrimitive; was primitiveCopyBits"
		(97 primitiveSnapshot)
		(98 primitiveStoreImageSegment)
		(99 primitiveLoadImageSegment)
		(100 primitivePerformInSuperclass)		"Blue Book: primitiveSignalAtTick"
		(101 primitiveBeCursor)
		(102 primitiveBeDisplay)
		(103 primitiveScanCharacters)
		(104 primitiveFail)	"was primitiveObsoleteIndexedPrimitive; was primitiveDrawLoop"
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
		(119 primitiveFlushCacheBySelector)
			"Squeak 2.2 and earlier use 119.  Squeak 2.3 and later use 116.
			Both are supported for backward compatibility."

		"Miscellaneous Primitives (120-127)"
		(120 primitiveCalloutToFFI)
		(121 primitiveImageName)
		(122 primitiveNoop)					"Blue Book: primitiveImageVolume"
		(123 primitiveFail)	"was primitiveValueUninterruptably"
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
		(161 primitiveArrayBecomeOneWayForceImmutables)
		(162 primitiveArrayBecomeForceImmutables)
		(163 primitiveGetImmutability)
		(164 primitiveSetImmutability)
		(165 primitiveIntegerAt)		"hacked in here for now"
		(166 primitiveIntegerAtPut)
		(167 primitiveYield)
		(168 primitiveCopyObject)
		(169 primitiveNotIdentical)

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

		(223 225 primitiveFail)	"reserved for Cog primitives"

		"Newsqueak debug primitives"
		(226 primitiveHeaderWords)

		"Used to encode protected access"
		(227 primitiveFail)

		"Other Primitives (228-249)"
		(228 primitiveFail)	
		(229 primitiveFail)	
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
		(250 primitiveClearVMProfile)
		(251 primitiveControlVMProfiling "primitiveStartVMProfiling")
		(252 primitiveVMProfileSamplesInto "primitiveStopVMProfiling")
		(253 primitiveFail "N.B. primitiveCollectCogCodeConstituents in CoInterpreter below")
		(254 primitiveVMParameter)
		(255 primitiveFail)

		"Quick Push Const Methods"
		(256 nil) "primitivePushSelf"
		(257 nil) "primitivePushTrue"
		(258 nil) "primitivePushFalse"
		(259 nil) "primitivePushNil"
		(260 nil) "primitivePushMinusOne"
		(261 nil) "primitivePushZero"
		(262 nil) "primitivePushOne"
		(263 nil) "primitivePushTwo"

		"Quick Push Const Methods"
		(264 519 nil) "primitiveLoadInstVar"

		(520 primitiveFail)
		"MIDI Primitives (521-539) - NO LONGER INDEXED"
		(521 529 primitiveFail)
		(530 539 primitiveFail)  "reserved for extended MIDI primitives"

		"Experimental Asynchrous File Primitives - NO LONGER INDEXED"
		(540 545 primitiveFail)

		"Used to encode private access"
		(546 primitiveFail)

		(547 primitiveFail)

		"Pen Tablet Primitives - NO LONGER INDEXED"
		(548 549 primitiveFail)

		"Sound Codec Primitives - NO LONGER INDEXED"
		(550 569 primitiveFail)

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
NewspeakInterpreter class >> initializeSchedulerIndices [
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
NewspeakInterpreter class >> initializeSmallIntegers [
	"SmallIntegers"
	ConstMinusOne := NewspeakInterpreter new integerObjectOf: -1.
	ConstZero := NewspeakInterpreter new integerObjectOf: 0.
	ConstOne := NewspeakInterpreter new integerObjectOf: 1.
	ConstTwo := NewspeakInterpreter new integerObjectOf: 2
]

{ #category : #initialization }
NewspeakInterpreter class >> initializeStreamIndices [
	StreamArrayIndex := 0.
	StreamIndexIndex := 1.
	StreamReadLimitIndex := 2.
	StreamWriteLimitIndex := 3.
]

{ #category : #initialization }
NewspeakInterpreter class >> initializeWithOptions: optionsDictionary [
	"NewspeakInterpreter initializeWithOptions: Dictionary new"

	super initializeWithOptions: optionsDictionary.  "initialize ObjectMemory constants"
	self initializeMiscConstants. "must preceed other initialization."
	self initializeAssociationIndex.
	self initializeBytecodeTable.
	self initializeCaches.
	self initializeCharacterIndex.
	self initializeCharacterScannerIndices.
	self initializeClassIndices.
	self initializeContextIndices.
	self initializeDirectoryLookupResultCodes.
	self initializeMessageIndices.
	self initializeMethodIndices.
	self initializePointIndices.
	self initializePrimitiveTable.
	self initializePrimitiveErrorCodes.
	self initializeSchedulerIndices.
	self initializeSmallIntegers.
	self initializeStreamIndices
]

{ #category : #translation }
NewspeakInterpreter class >> isInterpreterClass [
	^true
]

{ #category : #translation }
NewspeakInterpreter class >> isNonArgumentImplicitReceiverVariableName: aString [
	^'self' = aString
]

{ #category : #translation }
NewspeakInterpreter class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^(ObjectMemory mustBeGlobal: var)
	   or: [#('interpreterProxy' 'interpreterVersion' 'inIOProcessEvents'
			'deferDisplayUpdates' 'extraVMMemory' 'showSurfaceFn'
			'breakSelector' 'breakSelectorLength' 'sendTrace') includes: var]
]

{ #category : #translation }
NewspeakInterpreter class >> namesOfVariablesToLocalize [
	^#(currentBytecode localIP localSP localHomeContext localReturnContext localReturnValue)
]

{ #category : #translation }
NewspeakInterpreter class >> needsCogit [
	^false
]

{ #category : #translation }
NewspeakInterpreter class >> patchInterp: fileName [
	"NewspeakInterpreter patchInterp: 'Squeak VM PPC'"
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
NewspeakInterpreter class >> patchInterpGCCPPC: fileName [
	"NewspeakInterpreter patchInterpGCCPPC: 'Squeak copy 1'"
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

{ #category : #translation }
NewspeakInterpreter class >> preGenerationHook: aCCodeGenerator [
	"Perform any last-minute changes to the code generator immediately
	 before it performs code analysis and generation.  In this case, make
	 all non-exported methods private."
	| publicMethodNames |
	publicMethodNames := (self requiredMethodNames: aCCodeGenerator options)
								copyWithoutAll: (self primitiveTable
														copyWithout: #primitiveFail).
	aCCodeGenerator selectorsAndMethodsDo:
		[:s :m|
		(m export or: [publicMethodNames includes: s]) ifTrue:
			[m static: false]]
]

{ #category : #translation }
NewspeakInterpreter class >> preambleCCode [
	^	
'void printCallStack(void);

/* Disable Intel compiler inlining of warning which is used for breakpoints */
#pragma auto_inline off
void
warning(char *s) { /* Print an error message but don''t exit. */
	printf("\n%s\n", s);
}
#pragma auto_inline on

void
invalidCompactClassError(char *s) { /* Print a compact class index error message and exit. */
	static sqInt printingStack = true; /* not running at this point */

	printf("\nClass %s does not have the required compact class index\n", s);
	exit(-1);
}

/*
 * Define sigsetjmp and siglongjmp to be the most minimal setjmp/longjmp available on the platform.
 */
#if WIN32
# define sigsetjmp(jb,ssmf) setjmp(jb)
# define siglongjmp(jb,v) longjmp(jb,v)
#else
# define sigsetjmp(jb,ssmf) _setjmp(jb)
# define siglongjmp(jb,v) _longjmp(jb,v)
#endif
'
]

{ #category : #translation }
NewspeakInterpreter class >> prepareToBeAddedToCodeGenerator: aCodeGen [
	"Override to avoid repeating ObjectMemory's preparations
	 and to delete ObjectMemory methods we override."
	self selectors do:
		[:sel|
		 (superclass whichClassIncludesSelector: sel) ifNotNil:
			[aCodeGen removeMethodForSelector: sel]]
]

{ #category : #constants }
NewspeakInterpreter class >> primitiveTable [

	^ PrimitiveTable
]

{ #category : #initialization }
NewspeakInterpreter class >> primitiveTableString [
	"NewspeakInterpreter initializePrimitiveTable primitiveTableString"
	^String streamContents:
		[:s | 
		s nextPut: ${.
		self primitiveTable withIndexDo:
			[:primSpec :index |
			s
				crtab;
				nextPutAll: '/* ';
				print: index - 1;
				nextPutAll: ' */ ';
				nextPutAll: (primSpec isString
								ifTrue: [primSpec == #primitiveFail
											ifTrue: ['(void (*)(void))0']
											ifFalse: [primSpec]]
								ifFalse: ['(void (*)(void))', primSpec printString]);
				nextPut: $,].
			s cr; nextPutAll: ' 0 }']
]

{ #category : #translation }
NewspeakInterpreter class >> requiredMethodNames: options [
	"return the list of method names that should be retained for export or other support reasons"
	| requiredList |
	requiredList := self exportAPISelectors: options.
	"A number of methods required by VM support code, jitter, specific platforms etc"
	requiredList addAll: #(fullDisplayUpdate interpret printCallStack printAllStacks printOop: readImageFromFile:HeapSize:StartingAt: success: readableFormat: getCurrentBytecode characterForAscii: findClassOfMethod:forReceiver: findSelectorOfMethod:forReceiver: loadInitialContext primitiveFlushExternalPrimitives getFullScreenFlag getInterruptCheckCounter getInterruptKeycode getInterruptPending getNextWakeupTick getSavedWindowSize setFullScreenFlag: setInterruptCheckCounter: setInterruptKeycode: setInterruptPending: setNextWakeupTick: setSavedWindowSize: forceInterruptCheck getThisSessionID getDeferDisplayUpdates validInstructionPointer:inMethod:).

	"Nice to actually have all the primitives available"
	requiredList addAll: self primitiveTable.

	"InterpreterProxy is the internal analogue of sqVirtualMachine.c, so make sure to keep all those"
	InterpreterProxy organization categories do: [:cat |
		((cat ~= 'initialize') and: [cat ~= 'private']) ifTrue: [
			requiredList addAll: (InterpreterProxy organization listAtCategoryNamed: cat)]].
	
	^requiredList
]

{ #category : #translation }
NewspeakInterpreter class >> sourceFileName [
	^'interp.c'
]

{ #category : #initialization }
NewspeakInterpreter class >> table: anArray from: specArray [ 
	"SpecArray is an array of one of (index selector) or (index1 
	 index2 selector) or (index nil) or (index1 index2 nil).  If selector
	 then the entry is the selector, but if nil the entry is the index."
	| contiguous |
	contiguous := 0.
	specArray do:
		[:spec | 
		(spec at: 1) = contiguous ifFalse:
			[self error: 'Non-contiguous table entry'].
		spec size = 2
			ifTrue:
				[anArray
					at: (spec at: 1) + 1
					put: ((spec at: 2) ifNil: [spec at: 1] ifNotNil: [:sym| sym]).
				 contiguous := contiguous + 1]
			ifFalse:
				[(spec at: 1) to: (spec at: 2) do:
					[:i | anArray at: i + 1 put: ((spec at: 3) ifNil: [i] ifNotNil: [:sym| sym])].
				 contiguous := contiguous + ((spec at: 2) - (spec at: 1)) + 1]]
]

{ #category : #translation }
NewspeakInterpreter class >> vmCallbackHeader [
	^String streamContents:
		[:s|
		s nextPutAll: '#define VM_CALLBACK_INC 1'; cr; cr.
		VMCallbackContext printTypedefOn: s.
		s cr]
]

{ #category : #'api version' }
NewspeakInterpreter class >> vmProxyMajorVersion [
	"Define the  VM_PROXY_MAJOR version for this VM as used to
	 define the api in platforms/Cross/vm/sqVirtualMachine.[ch]"
	^1
]

{ #category : #'api version' }
NewspeakInterpreter class >> vmProxyMinorVersion [
	"Define the  VM_PROXY_MINOR version for this VM as used to
	 define the api in platforms/Cross/vm/sqVirtualMachine.[ch]"
	^12
]

{ #category : #translation }
NewspeakInterpreter class >> wantsLabels [
	"Only label the VM, not plugins (internal or external).  This to cut down the scope
	 of problems with labels being duplicated by C compiler optimizer inlining and
	 loop unrolling.  We use the asmLabel: directive to control labelling in the
	 interpreter proper. But it is too much work doing that for plugins too."
	^true
]

{ #category : #translation }
NewspeakInterpreter class >> writeVMHeaderTo: aStream bytesPerWord: bytesPerWord [
	super writeVMHeaderTo: aStream bytesPerWord: bytesPerWord.
	aStream
		nextPutAll: '#define NewspeakVM 1'; cr;
		nextPutAll: '#define ALIEN_FFI 1'; cr;
		nextPutAll: '#define IMMUTABILITY 1'; cr;
		nextPutAll: '#define BigEndianFloats 1'; cr;
		cr
]

{ #category : #'control primitives' }
NewspeakInterpreter >> activateNewClosureMethod: blockClosure [
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
	where :=  newContext + BaseHeaderSize.
	self longAt: where + (SenderIndex << ShiftForWord)
		put: activeContext.
	self longAt: where + (InstructionPointerIndex << ShiftForWord)
		put: (self fetchPointer: ClosureStartPCIndex ofObject: theBlockClosure).
	self longAt: where + (StackPointerIndex << ShiftForWord)
		put: (self integerObjectOf: argumentCount + numCopied).
	self longAt: where + (MethodIndex << ShiftForWord)
		put: (self fetchPointer: MethodIndex ofObject: outerContext).
	self longAt: where + (ClosureIndex << ShiftForWord)
		put: theBlockClosure.
	self longAt: where + (ReceiverIndex << ShiftForWord)
		put: (self fetchPointer: ReceiverIndex ofObject: outerContext).

	"Copy the arguments..."
	1 to: argumentCount do:
		[:i | self longAt: where + ((ReceiverIndex+i) << ShiftForWord)
				put: (self stackValue: argumentCount-i)].

	"Copy the copied values..."
	where := newContext + BaseHeaderSize + ((ReceiverIndex + 1 + argumentCount) << ShiftForWord).
	0 to: numCopied - 1 do:
		[:i| self longAt: where + (i << ShiftForWord)
				put: (self fetchPointer: i + ClosureFirstCopiedValueIndex
						  ofObject: theBlockClosure)].

	"The initial instructions in the block nil-out remaining temps."

	self pop: argumentCount + 1.
	self newActiveContext: newContext
]

{ #category : #'message sending' }
NewspeakInterpreter >> activateNewMethod [
	| newContext methodHeader initialIP tempCount nilOop where errorCode |

	methodHeader := self headerOf: newMethod.
	newContext := self allocateOrRecycleContext: (methodHeader bitAnd: LargeContextBit).

	initialIP := ((LiteralStart + (self literalCountOfHeader: methodHeader)) * BytesPerWord) + 1.
	tempCount := (methodHeader >> 19) bitAnd: 16r3F.

	"Assume: newContext will be recorded as a root if necessary by the
	 call to newActiveContext: below, so we can use unchecked stores."

	where :=  newContext  + BaseHeaderSize.
	self longAt: where + (SenderIndex << ShiftForWord) put: activeContext.
	self longAt: where + (InstructionPointerIndex << ShiftForWord) put: (self integerObjectOf: initialIP).
	self longAt: where + (StackPointerIndex << ShiftForWord) put: (self integerObjectOf: tempCount).
	self longAt: where + (MethodIndex << ShiftForWord) put: newMethod.
	self longAt: where + (ClosureIndex << ShiftForWord) put: nilObj.

	"Copy the receiver and arguments..."
	0 to: argumentCount do:
		[:i | self longAt: where + ((ReceiverIndex+i) << ShiftForWord) put: (self stackValue: argumentCount-i)].

	"clear remaining temps to nil in case it has been recycled"
	nilOop := nilObj.
	argumentCount+1+ReceiverIndex to: tempCount+ReceiverIndex do:
		[:i | self longAt: where + (i << ShiftForWord) put: nilOop].

	"Pass primitive error code to last temp if method receives it (indicated
	 by an initial long store temp bytecode).  Protect against obsolete values
	 in primFailCode by checking that newMethod actually has a primitive?"
	primFailCode > 0 ifTrue:
		[((self primitiveIndexOfMethodHeader: methodHeader) > 0
		   and: [(self fetchByte: initialIP - 1 ofObject: newMethod) = 129 "long store temp"]) ifTrue:
			[errorCode := self fetchPointer: primFailCode - 1 ofObject: (self splObj: PrimErrTableIndex).
			 self longAt: where + ((tempCount+ReceiverIndex) << ShiftForWord)
				put: errorCode "nil if primFailCode == 1, or primFailCode"].
		primFailCode := 0].

	self pop: argumentCount + 1.
	reclaimableContextCount := reclaimableContextCount + 1.
	self newActiveContext: newContext.
]

{ #category : #'process primitive support' }
NewspeakInterpreter >> activeProcess [
	"Answer the current activeProcess."
	^self fetchPointer: ActiveProcessIndex ofObject: self schedulerPointer
]

{ #category : #'process primitive support' }
NewspeakInterpreter >> addLastLink: proc toList: aList [ 
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
NewspeakInterpreter >> addNewMethodToCache [
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
	| probe hash primitiveIndex |
	<inline: false>
	hash := messageSelector bitXor: lkupClass.  "drop low-order zeros from addresses"

	primitiveIndex := self primitiveIndexOf: newMethod.
	primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: lkupClass.
	
	0 to: CacheProbeMax-1 do:
		[:p | probe := (hash >> p) bitAnd: MethodCacheMask.
		(methodCache at: probe + MethodCacheSelector) = 0 ifTrue:
			["Found an empty entry -- use it"
			methodCache at: probe + MethodCacheSelector put: messageSelector.
			methodCache at: probe + MethodCacheClass put: lkupClass.
			methodCache at: probe + MethodCacheMethod put: newMethod.
			methodCache at: probe + MethodCachePrimFunction put: (self cCoerce: primitiveFunctionPointer to: #long).
			^ nil]].

	"OK, we failed to find an entry -- install at the first slot..."
	probe := hash bitAnd: MethodCacheMask.  "first probe"
	methodCache at: probe + MethodCacheSelector put: messageSelector.
	methodCache at: probe + MethodCacheClass put: lkupClass.
	methodCache at: probe + MethodCacheMethod put: newMethod.
	methodCache at: probe + MethodCachePrimFunction put: (self cCoerce: primitiveFunctionPointer to: #long).

	"...and zap the following entries"
	1 to: CacheProbeMax-1 do:
		[:p | probe := (hash >> p) bitAnd: MethodCacheMask.
		methodCache at: probe + MethodCacheSelector put: 0]
]

{ #category : #'plugin support' }
NewspeakInterpreter >> addToExternalPrimitiveTable: functionAddress [
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

{ #category : #utilities }
NewspeakInterpreter >> addressOf: rcvr startingAt: byteOffset size: byteSize [
"Return the int of the address of the (byteSize) slot at btyeOffset in rcvr. Usde for getting byte/word/int/float/double out of Byte/WordArrays"
	| rcvrSize addr |
	(self isBytes: rcvr) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	(byteOffset > 0) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	rcvrSize := self byteSizeOf: rcvr.
	(byteOffset+byteSize-1 <= rcvrSize) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	addr := self oopForPointer: (self firstIndexableField: rcvr).
	addr := addr + byteOffset - 1.
	^addr
]

{ #category : #'debug support' }
NewspeakInterpreter >> allAccessibleObjectsOkay [
	"Ensure that all accessible objects in the heap are okay."

	| oop ok |
	ok := true.
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[ok := ok & (self okayFields: oop).
		 oop := self accessibleObjectAfter: oop].
	^ok
]

{ #category : #'as yet unclassified' }
NewspeakInterpreter >> allocateMemory: heapSize minimum: minimumMemory imageFile: fileStream headerSize: headerSize [

	"Translate to C function call with (case sensitive) camelCase. The purpose of this
	method is to document the translation.
	The default implementation is sqAllocateMemory(minimumMemory, heapSize). This may
	be redefined to make use of the image file and header size parameters for efficient
	implementation with mmap().
	See CCodeGenerator>>writeDefaultMacrosOn: which specifies a default implementation."

	<inline: true>
	<returnTypeC: #'char *'>
	<var: #fileStream type: #sqImageFile>
	^ self
		allocateMemory: heapSize
		Minimum: minimumMemory
		ImageFile: fileStream
		HeaderSize: headerSize
]

{ #category : #contexts }
NewspeakInterpreter >> allocateOrRecycleContext: needsLarge [
	"Return a recycled context or a newly allocated one if none is available for recycling."
	| cntxt |
	needsLarge = 0
	ifTrue: [freeContexts ~= NilContext ifTrue:
				[cntxt := freeContexts.
				freeContexts := self fetchPointer: 0 ofObject: cntxt.
				^ cntxt]]
	ifFalse: [freeLargeContexts ~= NilContext ifTrue:
				[cntxt := freeLargeContexts.
				freeLargeContexts := self fetchPointer: 0 ofObject: cntxt.
				^ cntxt]].
	
	needsLarge = 0
		ifTrue: [cntxt := self instantiateContext: (self splObj: ClassMethodContext)
				sizeInBytes: SmallContextSize]
		ifFalse: [cntxt := self instantiateContext: (self splObj: ClassMethodContext)
				sizeInBytes: LargeContextSize].
	"Required init -- above does not fill w/nil.  All others get written."
	self storePointerUnchecked: 4 "InitialIPIndex" ofObject: cntxt
					withValue: nilObj.
	^ cntxt
]

{ #category : #utilities }
NewspeakInterpreter >> areIntegers: oop1 and: oop2 [
"Test oop1 and oop2 to make sure both are SmallIntegers."
	^ ((oop1 bitAnd: oop2) bitAnd: 1) ~= 0
]

{ #category : #'compiled methods' }
NewspeakInterpreter >> argumentCountOf: methodPointer [
	^ ((self headerOf: methodPointer) >> 25) bitAnd: 16r0F
]

{ #category : #contexts }
NewspeakInterpreter >> argumentCountOfBlock: blockPointer [

	| localArgCount |
	localArgCount := self fetchPointer: BlockArgumentCountIndex ofObject: blockPointer.
	^self checkedIntegerValueOf: localArgCount
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> argumentCountOfClosure: closurePointer [

	^self quickFetchInteger: ClosureNumArgsIndex ofObject: closurePointer
]

{ #category : #'compiled methods' }
NewspeakInterpreter >> argumentCountOfMethodHeader: header [
	^ (header >> 25) bitAnd: 16r0F
]

{ #category : #utilities }
NewspeakInterpreter >> arrayValueOf: arrayOop [
	"Return the address of first indexable field of resulting array object, or fail if
	 the instance variable does not contain an indexable bytes or words object."
	"Note: May be called by translated primitive code."

	<returnTypeC: #'void *'>
	((self isNonIntegerObject: arrayOop)
	 and: [self isWordsOrBytes: arrayOop]) ifTrue:
		[^self cCoerceSimple: (self pointerForOop: arrayOop + BaseHeaderSize) to: #'void *'].
	self primitiveFail
]

{ #category : #'indexing primitive support' }
NewspeakInterpreter >> asciiOfCharacter: characterObj [  "Returns an integer object"

	<inline: false>
	self assertClassOf: characterObj is: (self splObj: ClassCharacter).
	self successful
		ifTrue: [^ self fetchPointer: CharacterValueIndex ofObject: characterObj]
		ifFalse: [^ ConstZero]  "in case some code needs an int"
]

{ #category : #utilities }
NewspeakInterpreter >> assertClassOf: oop is: classOop [
	"Succeed if the given (non-integer) object is an instance of the given class. Fail if the object is an integer."

	<inline: true>
	<asmLabel: false>
	self success: (self isClassOfNonImm: oop equalTo: classOop)
]

{ #category : #become }
NewspeakInterpreter >> become: array1 with: array2 twoWay: twoWayFlag copyHash: copyHashFlag forceImmutables: immutablesOk [ 
	"All references to each object in array1 are swapped with all references to the corresponding object in array2. That is, all pointers to one object are replaced with with pointers to the other. The arguments must be arrays of the same length. 
	Returns true if the primitive succeeds."
	"Implementation: Uses forwarding blocks to update references as done in compaction."
	| start |
	(self isArray: array1) ifFalse:
		[^PrimErrBadReceiver].
	((self isArray: array2)
	 and: [(self lastPointerOf: array1) = (self lastPointerOf: array2)]) ifFalse:
		[^PrimErrBadArgument].
	(self containOnlyOops: array1 and: array2) ifFalse:
		[PrimErrInappropriate].
	"This code fails the primitive if it should fail for immutables and objects
	 that are being becommed are immutable. This is debateable.  Instead we
	 could have it that we fail only if the referents are immutable."
	immutablesOk ifFalse:
		[(self containOnlyMutableOops: array1 and: array2) ifFalse:
			[^PrimErrNoModification]].

	(self prepareForwardingTableForBecoming: array1 with: array2 twoWay: twoWayFlag) ifFalse:
		[^PrimErrNoMemory]. "fail; not enough space for forwarding table"

	(self allYoung: array1 and: array2)
		ifTrue: [start := youngStart"sweep only the young objects plus the roots"]
		ifFalse: [start := self startOfMemory"sweep all objects"].
	immutablesOk ifFalse:
		["Search for any references to a forwarded object in an immutable.
		 Fail if any exist."
		 (self existImmutableReferencesToForwardedInRangeFrom: start to: endOfMemory) ifTrue:
			[twoWayFlag
				ifTrue: [self restoreHeadersAfterBecoming: array1 with: array2]
				ifFalse: [self restoreHeadersAfterForwardBecome: copyHashFlag].
			 ^PrimErrNoModification]].
	self mapPointersInObjectsFrom: start to: endOfMemory.
	twoWayFlag
		ifTrue: [self restoreHeadersAfterBecoming: array1 with: array2]
		ifFalse: [self restoreHeadersAfterForwardBecome: copyHashFlag].

	self initializeMemoryFirstFree: freeBlock. "re-initialize memory used for forwarding table"
	
	self forceInterruptCheck. "pretty much guaranteed to take a long time, so check for timers etc ASAP"

	^PrimNoErr "success"
]

{ #category : #utilities }
NewspeakInterpreter >> booleanCheat: cond [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<inline: true>

	cond
		ifTrue: [self booleanCheatTrue]
		ifFalse: [self booleanCheatFalse]
]

{ #category : #utilities }
NewspeakInterpreter >> booleanCheatFalse [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<sharedCodeNamed: 'booleanCheatFalse' inCase: #bytecodePrimGreaterThan>
	| bytecode offset |

	bytecode := self fetchByte.  "assume next bytecode is jumpIfFalse (99%)"
	self internalPop: 2.
	(bytecode < 160 and: [bytecode > 151]) ifTrue:  "short jumpIfFalse"
		[^self jump: bytecode - 151].

	bytecode = 172 ifTrue:  "long jumpIfFalse"
		[offset := self fetchByte.
		^self jump: offset].

	"not followed by a jumpIfFalse; (un)do instruction fetch and push boolean result"
	currentBytecode := bytecode.
	self internalPush: falseObj
]

{ #category : #utilities }
NewspeakInterpreter >> booleanCheatTrue [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<sharedCodeNamed: 'booleanCheatTrue' inCase: #bytecodePrimLessThan>
	| bytecode offset |

	bytecode := self fetchByte.  "assume next bytecode is jumpIfFalse (99%)"
	self internalPop: 2.
	(bytecode < 173 and: [bytecode > 151]) ifTrue:
		[bytecode < 160 ifTrue: "short jumpIfFalse 152 - 159"
			[^self fetchNextBytecode].
		bytecode = 172 ifTrue: "long jumpIfFalse"
			[self fetchByte.
			^self fetchNextBytecode].
		bytecode > 167 ifTrue: "long jumpIfTrue 168 - 171"
			[offset := bytecode - 168 << 8 + self fetchByte.
			^self jump: offset]].

	"not followed by a jumpIfFalse; (un)do instruction fetch and push boolean result"
	currentBytecode := bytecode.
	self internalPush: trueObj
]

{ #category : #utilities }
NewspeakInterpreter >> booleanValueOf: obj [
"convert true and false (Smalltalk) to true or false(C)"
	obj = trueObj ifTrue: [ ^ true ].
	obj = falseObj ifTrue: [ ^ false ].
	^self primitiveFail
]

{ #category : #'image save/restore' }
NewspeakInterpreter >> byteSwapByteObjects [
	"Byte-swap the words of all bytes objects in the image. This returns these objects to their original byte ordering after blindly byte-swapping the entire image."

	self byteSwapByteObjectsFrom: self firstObject to: endOfMemory
]

{ #category : #'image save/restore' }
NewspeakInterpreter >> byteSwapByteObjectsFrom: startOop to: stopAddr [ 
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
							wordAddr := oop + BaseHeaderSize.
							fmt >= 12
								ifTrue: ["compiled method; start after methodHeader and literals"
									methodHeader := self longAt: oop + BaseHeaderSize.
									wordAddr := wordAddr + BytesPerWord + ((methodHeader >> 10 bitAnd: 255) * BytesPerWord)].
							self reverseBytesFrom: wordAddr to: oop + (self sizeBitsOf: oop)].
					(fmt = 6 and: [BytesPerWord = 8])
						ifTrue: ["Object contains 32-bit half-words packed into 64-bit machine words."
							wordAddr := oop + BaseHeaderSize.
							self reverseWordsFrom: wordAddr to: oop + (self sizeBitsOf: oop)]].
			oop := self objectAfter: oop]
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimAdd [
	| rcvr arg result |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg)
		ifTrue: [result := (self integerValueOf: rcvr) + (self integerValueOf: arg).
				(self isIntegerValue: result) ifTrue:
					[self internalPop: 2 thenPush: (self integerObjectOf: result).
					^ self fetchNextBytecode "success"]]
		ifFalse: [self initPrimCall.
				self externalizeIPandSP.
				self primitiveFloatAdd: rcvr toArg: arg.
				self internalizeIPandSP.
				self successful ifTrue: [^ self fetchNextBytecode "success"]].

	messageSelector := self specialSelector: 0.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimAt [
	"BytecodePrimAt will only succeed if the receiver is in the atCache.
	Otherwise it will fail so that the more general primitiveAt will put it in the
	cache after validating that message lookup results in a primitive response."
	| index rcvr result atIx |
	index := self internalStackTop.
	rcvr := self internalStackValue: 1.
	self success: ((self isIntegerObject: rcvr) not and: [self isIntegerObject: index]).
	self successful ifTrue:
		[atIx := rcvr bitAnd: AtCacheMask.  "Index into atCache = 4N, for N = 0 ... 7"
		(atCache at: atIx+AtCacheOop) = rcvr
		ifTrue: [result := self commonVariableInternal: rcvr at: (self integerValueOf: index) cacheIndex: atIx.
			self successful ifTrue:
				[self fetchNextBytecode.
				^self internalPop: 2 thenPush: result]]].

	messageSelector := self specialSelector: 16.
	argumentCount := 1.
	self normalSend.

]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimAtEnd [
	messageSelector := self specialSelector: 21.
	argumentCount := 0.
	self normalSend.
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimAtPut [
	"BytecodePrimAtPut will only succeed if the receiver is in the atCache.
	Otherwise it will fail so that the more general primitiveAtPut will put it in the
	cache after validating that message lookup results in a primitive response."
	| index rcvr atIx value |
	value := self internalStackTop.
	index := self internalStackValue: 1.
	rcvr := self internalStackValue: 2.
	self success: ((self isIntegerObject: rcvr) not
					and: [(self isIntegerObject: index)
					and: [self isObjMutable: rcvr]]).
	self successful ifTrue:
		[atIx := (rcvr bitAnd: AtCacheMask) + AtPutBase.  "Index into atPutCache"
		 (atCache at: atIx+AtCacheOop) = rcvr ifTrue:
			[self commonVariable: rcvr
				at: (self integerValueOf: index)
				put: value
				cacheIndex: atIx.
			 self successful ifTrue:
				[self fetchNextBytecode.
				 ^self internalPop: 3 thenPush: value]]].

	messageSelector := self specialSelector: 17.
	argumentCount := 2.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimBitAnd [

	self initPrimCall.
	self externalizeIPandSP.
	self primitiveBitAnd.
	self internalizeIPandSP.
	self successful ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 14.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimBitOr [

	self initPrimCall.
	self externalizeIPandSP.
	self primitiveBitOr.
	self internalizeIPandSP.
	self successful ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 15.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimBitShift [

	self initPrimCall.
	self externalizeIPandSP.
	self primitiveBitShift.
	self internalizeIPandSP.
	self successful ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 12.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimBlockCopy [

	| rcvr hdr |
	rcvr := self internalStackValue: 1.
	self initPrimCall.
	hdr := self baseHeader: rcvr.
	self success: (self isContextHeader: hdr).
	self successful ifTrue: [self externalizeIPandSP.
		self primitiveBlockCopy.
		self internalizeIPandSP].
	self successful ifFalse: [messageSelector := self specialSelector: 24.
		argumentCount := 1.
		^ self normalSend].
	self fetchNextBytecode.

]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimClass [
	| rcvr |
	rcvr := self internalStackTop.
	self internalPop: 1 thenPush: (self fetchClassOf: rcvr).
	self fetchNextBytecode.

]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimDiv [
	| quotient |
	self initPrimCall.
	quotient := self doPrimitiveDiv: (self internalStackValue: 1) by: (self internalStackValue: 0).
	self successful ifTrue: [self internalPop: 2 thenPush: (self integerObjectOf: quotient).
		^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 13.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimDivide [
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
		ifFalse: [self initPrimCall.
			self externalizeIPandSP.
			self primitiveFloatDivide: rcvr byArg: arg.
			self internalizeIPandSP.
			self successful ifTrue: [^ self fetchNextBytecode"success"]].

	messageSelector := self specialSelector: 9.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimDo [

	messageSelector := self specialSelector: 27.
	argumentCount := 1.
	self normalSend.

]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue: [^self booleanCheat: rcvr = arg].

	self initPrimCall.
	aBool := self primitiveFloatEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 6.
	argumentCount := 1.
	self normalSend

]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimEquivalent [

	| rcvr arg |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	self booleanCheat: rcvr = arg.
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimGreaterOrEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheat: rcvr >= arg]
			inSmalltalk: [self booleanCheat: (self integerValueOf: rcvr) >= (self integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatGreaterOrEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 5.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimGreaterThan [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheat: rcvr > arg]
			inSmalltalk: [self booleanCheat: (self integerValueOf: rcvr) > (self integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatGreater: rcvr thanArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 3.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimLessOrEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheat: rcvr <= arg]
			inSmalltalk: [self booleanCheat: (self integerValueOf: rcvr) <= (self integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatLessOrEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 4.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimLessThan [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheat: rcvr < arg]
			inSmalltalk: [self booleanCheat: (self integerValueOf: rcvr) < (self integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatLess: rcvr thanArg: arg.
	self successful ifTrue: [^ self booleanCheat: aBool].

	messageSelector := self specialSelector: 2.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimMakePoint [

	self initPrimCall.
	self externalizeIPandSP.
	self primitiveMakePoint.
	self internalizeIPandSP.
	self successful ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 11.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimMod [
	| mod |
	self initPrimCall.
	mod := self doPrimitiveMod: (self internalStackValue: 1) by: (self internalStackValue: 0).
	self successful ifTrue:
		[self internalPop: 2 thenPush: (self integerObjectOf: mod).
		^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 10.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimMultiply [
	| rcvr arg result |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg)
		ifTrue: [rcvr := self integerValueOf: rcvr.
				arg := self integerValueOf: arg.
				result := rcvr * arg.
				(arg = 0
				 or: [(result // arg) = rcvr and: [self isIntegerValue: result]]) ifTrue:
					[self internalPop: 2 thenPush: (self integerObjectOf: result).
					 ^self fetchNextBytecode "success"]]
		ifFalse: [self initPrimCall.
				self externalizeIPandSP.
				self primitiveFloatMultiply: rcvr byArg: arg.
				self internalizeIPandSP.
				self successful ifTrue: [^ self fetchNextBytecode "success"]].

	messageSelector := self specialSelector: 8.
	argumentCount := 1.
	self normalSend.

]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimNew [

	messageSelector := self specialSelector: 28.
	argumentCount := 0.
	self normalSend.

]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimNewWithArg [

	messageSelector := self specialSelector: 29.
	argumentCount := 1.
	self normalSend.

]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimNext [
	messageSelector := self specialSelector: 19.
	argumentCount := 0.
	self normalSend.
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimNextPut [
	messageSelector := self specialSelector: 20.
	argumentCount := 1.
	self normalSend.
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimNotEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue: [^self booleanCheat: rcvr ~= arg].

	self initPrimCall.
	aBool := self primitiveFloatEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool not].

	messageSelector := self specialSelector: 7.
	argumentCount := 1.
	self normalSend

]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimPointX [

	| rcvr |
	self initPrimCall.
	rcvr := self internalStackTop.
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	self successful
		ifTrue: [self internalPop: 1 thenPush: (self fetchPointer: XIndex ofObject: rcvr).
			^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 30.
	argumentCount := 0.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimPointY [

	| rcvr |
	self initPrimCall.
	rcvr := self internalStackTop.
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	self successful
		ifTrue: [self internalPop: 1 thenPush: (self fetchPointer: YIndex ofObject: rcvr).
			^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 31.
	argumentCount := 0.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimSize [
	messageSelector := self specialSelector: 18.
	argumentCount := 0.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimSubtract [
	| rcvr arg result |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg)
		ifTrue: [result := (self integerValueOf: rcvr) - (self integerValueOf: arg).
				(self isIntegerValue: result) ifTrue:
					[self internalPop: 2 thenPush: (self integerObjectOf: result).
					^self fetchNextBytecode "success"]]
		ifFalse: [self initPrimCall.
				self externalizeIPandSP.
				self primitiveFloatSubtract: rcvr fromArg: arg.
				self internalizeIPandSP.
				self successful ifTrue: [^self fetchNextBytecode "success"]].

	messageSelector := self specialSelector: 1.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimValue [
	"In-line value for BlockClosure and BlockContext"
	| maybeBlock rcvrClass |
	maybeBlock := self internalStackTop.
	self initPrimCall.
	argumentCount := 0.
	(self isNonIntegerObject: maybeBlock) ifTrue:
		[rcvrClass := self fetchClassOfNonImm: maybeBlock.
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
						[self primitiveFail]]].
	self successful ifFalse:
		[messageSelector := self specialSelector: 25.
		 ^self normalSend].
	self fetchNextBytecode
]

{ #category : #'common selector sends' }
NewspeakInterpreter >> bytecodePrimValueWithArg [
	"In-line value: for BlockClosure and BlockContext"
	| maybeBlock rcvrClass |
	maybeBlock := self internalStackValue: 1.
	self initPrimCall.
	argumentCount := 1.
	(self isNonIntegerObject: maybeBlock) ifTrue:
		[rcvrClass := self fetchClassOfNonImm: maybeBlock.
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
						[self primitiveFail]]].
	self successful ifFalse:
		[messageSelector := self specialSelector: 26.
		 ^self normalSend].
	self fetchNextBytecode
]

{ #category : #'primitive support' }
NewspeakInterpreter >> cStringOrNullFor: oop [
	"Answer either a malloced string with the null-terminated contents of oop if oop is a string,
	 or the null pointer if oop is nil, or fail.  It is the client's responsibility to free the string later."
	<api>
	<returnTypeC: #'char *'>
	| isString len cString |
	<var: 'cString' type: #'char *'>
	isString := self isInstanceOfClassByteString: oop.
	isString ifFalse:
		[oop ~= nilObj ifTrue:
			[self primitiveFailFor: PrimErrBadArgument].
		 ^0].
	len := self lengthOf: oop.
	len = 0 ifTrue:
		[^0].
	cString := self malloc: len + 1.
	cString ifNil:
		[self primitiveFailFor: PrimErrNoCMemory.
		 ^0].
	self mem: cString cp: (self firstIndexableField: oop) y: len.
	cString at: len put: 0.
	^cString
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> callExternalPrimitive: functionID [
	"Call the external plugin function identified. In the VM this is an address;
	 see NewspeakInterpreterSimulator for its version."

	<var: #functionID declareC: 'void (*functionID)()'>
	self dispatchFunctionPointer: functionID
]

{ #category : #contexts }
NewspeakInterpreter >> caller [
	^self fetchPointer: CallerIndex ofObject: activeContext
]

{ #category : #'debug support' }
NewspeakInterpreter >> capturePendingFinalizationSignals [
	statPendingFinalizationSignals := pendingFinalizationSignals
]

{ #category : #'indexing primitive support' }
NewspeakInterpreter >> characterForAscii: ascii [  "Arg must lie in range 0-255!"
	<inline: true>
	^ self fetchPointer: ascii ofObject: (self splObj: CharacterTable)
]

{ #category : #initialization }
NewspeakInterpreter >> checkAssumedCompactClasses [
	"Check that the classes the VM assumes are compact have the right indices.
	 As of 5/10/2011 Newspeak images have Squeak V9 compact classes.  If and
	 when we bootstrap to Cog , Squeak V4 and closures we can use the fuller set
	 for faster large integer arithmetic, etc."
	self checkCompactIndex: ClassArrayCompactIndex isClass: ClassArray named: 'Array'.
	self checkCompactIndex: ClassLargePositiveIntegerCompactIndex isClass: ClassLargePositiveInteger named: 'LargePositiveInteger'.
	self checkCompactIndex: ClassFloatCompactIndex isClass: ClassFloat named: 'Float'.
	self checkCompactIndex: ClassBlockContextCompactIndex isClass: ClassBlockContext named: 'BlockContext'.
	self checkCompactIndex: ClassMethodContextCompactIndex isClass: ClassMethodContext named: 'MethodContext'
]

{ #category : #'arithmetic primitive support' }
NewspeakInterpreter >> checkBooleanResult: result [
	self successful
		ifTrue: [self pushBool: result]
		ifFalse: [self unPop: 2]
]

{ #category : #processes }
NewspeakInterpreter >> checkForInterrupts [
	"Check for possible interrupts and handle one if necessary."
	| sema now thisLastTick |
	<inline: false>

	"Mask so same wrapping as primitiveMillisecondClock"
	now := self ioMSecs bitAnd: MillisecondClockMask.
	thisLastTick := lastTick.

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

	"inIOProcessEvents prevents reentrancy into ioProcessEvents and allows disabling
	 ioProcessEvents e.g. for native GUIs.  We would like to manage that here but can't
	 since the platform code may choose to call ioProcessEvents itself in various places."
	false
		ifTrue:
			[(now >= nextPollTick
			  and: [inIOProcessEvents = 0]) ifTrue:
				[inIOProcessEvents := inIOProcessEvents + 1.
				 self ioProcessEvents. "sets interruptPending if interrupt key pressed; may callback"
				 inIOProcessEvents > 0 ifTrue:
					[inIOProcessEvents := inIOProcessEvents - 1].
				nextPollTick := now + 200
				"msecs to wait before next call to ioProcessEvents.  
				Note that strictly speaking we might need to update  
				'now' at this point since ioProcessEvents could take a  
				very long time on some platforms"]]
		ifFalse:
			[now >= nextPollTick ifTrue:
				[self ioProcessEvents.
				 "sets interruptPending if interrupt key pressed"
				 nextPollTick := now + 200
				 "msecs to wait before next call to ioProcessEvents.  
				 Note that strictly speaking we might need to update  
				 'now' at this point since ioProcessEvents could take a  
				 very long time on some platforms"]].
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
	self signalExternalSemaphores.

	"update the tracking value (unless e.g. updated in a callback via ioProcessEvents)."
	lastTick = thisLastTick ifTrue:
		[lastTick := now]
]

{ #category : #'image save/restore' }
NewspeakInterpreter >> checkImageVersionFrom: f startingAt: imageOffset [
	"Read and verify the image file version number and return true if the the given image file needs to be byte-swapped. As a side effect, position the file stream just after the version number of the image header. This code prints a warning and does a hard-exit if it cannot find a valid version number."
	"This code is based on C code by Ian Piumarta."

	| version firstVersion |
	<var: #f type: 'sqImageFile '>
	<var: #imageOffset type: 'squeakFileOffsetType '>

	"check the version number"
	self sqImageFile: f Seek: imageOffset.
	version := firstVersion := self getLongFromFile: f swap: false.
	(self readableFormat: version) ifTrue: [^ false].

	"try with bytes reversed"
	self sqImageFile: f Seek: imageOffset.
	version := self getLongFromFile: f swap: true.
	(self readableFormat: version) ifTrue: [^ true].

	"Note: The following is only meaningful if not reading an embedded image"
	imageOffset = 0 ifTrue:[
		"try skipping the first 512 bytes (prepended by certain Mac file transfer utilities)"
		self sqImageFile: f Seek: 512.
		version := self getLongFromFile: f swap: false.
		(self readableFormat: version) ifTrue: [^ false].

		"try skipping the first 512 bytes with bytes reversed"
		self sqImageFile: f Seek: 512.
		version := self getLongFromFile: f swap: true.
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

{ #category : #utilities }
NewspeakInterpreter >> checkedIntegerValueOf: intOop [
	"Note: May be called by translated primitive code."

	(self isIntegerObject: intOop)
		ifTrue: [ ^ self integerValueOf: intOop ]
		ifFalse: [ self primitiveFail. ^ 0 ]
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> classNameOf: aClass Is: className [ 
	"Check if aClass's name is className"
	| srcName name length |
	<var: #className type: #'char *'>
	<var: #srcName type: #'char *'>
	(self lengthOf: aClass) <= classNameIndex ifTrue:
		[^ false]. "Not a class but might be behavior"
	name := self fetchPointer: classNameIndex ofObject: aClass.
	(self isBytes: name) ifFalse:
		[^false].
	length := self stSizeOf: name.
	srcName := self cCoerce: (self arrayValueOf: name) to: 'char *'.
	0 to: length - 1 do: [:i | (srcName at: i) = (className at: i) ifFalse: [^false]].
	"Check if className really ends at this point"
	^(className at: length) = 0
]

{ #category : #'control primitives' }
NewspeakInterpreter >> closureNumArgs: numArgs instructionPointer: initialIP numCopiedValues: numCopied [
	| newClosure |
	<inline: true>
	newClosure := self
					instantiateSmallClass: (self splObj: ClassBlockClosure)
					sizeInBytes: (BytesPerWord * (ClosureFirstCopiedValueIndex + numCopied)) + BaseHeaderSize.
	"Assume: have just allocated a new closure; it must be young. Thus, can use unchecked stores."
	self storePointerUnchecked: ClosureStartPCIndex ofObject: newClosure withValue: (self integerObjectOf: initialIP).
	self storePointerUnchecked: ClosureNumArgsIndex ofObject: newClosure withValue: (self integerObjectOf: numArgs).
	"It is up to the caller to store the outer context and copiedValues."
	^newClosure
]

{ #category : #'indexing primitive support' }
NewspeakInterpreter >> commonAt: stringy [
	"This code is called if the receiver responds primitively to at:.
	If this is so, it will be installed in the atCache so that subsequent calls of at:
	or next may be handled immediately in bytecode primitive routines."
	| index rcvr atIx result |
	self initPrimCall.
	rcvr := self stackObjectValue: 1.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	index := self positive32BitValueOf: self stackTop.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].

	"NOTE:  The at-cache, since it is specific to the non-super response to #at:.
	Therefore we must determine that the message is #at: (not, eg, #basicAt:),
	and that the send is not a super-send, before using the at-cache."
	(messageSelector = (self specialSelector: 16)
		and: [lkupClass = (self fetchClassOfNonImm: rcvr)])
		ifTrue:
		["OK -- look in the at-cache"
		atIx := rcvr bitAnd: AtCacheMask.  "Index into atCache = 4N, for N = 0 ... 7"
		(atCache at: atIx+AtCacheOop) = rcvr ifFalse:
			["Rcvr not in cache.  Install it..."
			self install: rcvr inAtCache: atCache at: atIx string: stringy].
		self successful ifTrue:
			[result := self commonVariable: rcvr at: index cacheIndex: atIx].
		self successful ifTrue:
			[^ self pop: argumentCount+1 thenPush: result]].

	"The slow but sure way..."
	self initPrimCall.
	result := self stObject: rcvr at: index.
	self successful ifTrue:
		[stringy ifTrue: [result := self characterForAscii: (self integerValueOf: result)].
		^ self pop: argumentCount+1 thenPush: result]
]

{ #category : #'indexing primitive support' }
NewspeakInterpreter >> commonAtPut: stringy [
	"This code is called if the receiver responds primitively to at:Put:.
	If this is so, it will be installed in the atPutCache so that subsequent calls of at:
	or  next may be handled immediately in bytecode primitive routines."
	| value index rcvr atIx |
	self initPrimCall.
	rcvr := self stackObjectValue: 2.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	index := self positive32BitValueOf: (self stackValue: 1).
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	(self isOopImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	value := self stackTop.

	"NOTE:  The atPut-cache, since it is specific to the non-super response to #at:Put:.
	Therefore we must determine that the message is #at:Put: (not, eg, #basicAt:Put:),
	and that the send is not a super-send, before using the at-cache."
	(messageSelector = (self specialSelector: 17)
	  and: [lkupClass = (self fetchClassOfNonImm: rcvr)])
		ifTrue:
		["OK -- look in the at-cache"
		atIx := (rcvr bitAnd: AtCacheMask) + AtPutBase.  "Index into atPutCache"
		(atCache at: atIx+AtCacheOop) = rcvr ifFalse:
			["Rcvr not in cache.  Install it..."
			self install: rcvr inAtCache: atCache at: atIx string: stringy].
		self successful ifTrue:
			[self commonVariable: rcvr at: index put: value cacheIndex: atIx].
		self successful ifTrue:
			[^ self pop: argumentCount+1 thenPush: value]].

	"The slow but sure way..."
	self initPrimCall.
	stringy ifTrue: [self stObject: rcvr at: index put: (self asciiOfCharacter: value)]
			ifFalse: [self stObject: rcvr at: index put: value].
	self successful ifTrue: [^ self pop: argumentCount+1 thenPush: value].

]

{ #category : #'return bytecodes' }
NewspeakInterpreter >> commonReturn [
	"Note: Assumed to be inlined into the dispatch loop."

	<sharedCodeNamed: 'commonReturn' inCase: #returnReceiver>
	| nilOop thisCntx contextOfCaller localCntx localVal unwindMarked |

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
	(thisCntx < youngStart) ifTrue: [ self beRootIfOld: thisCntx ].

	self internalFetchContextRegisters: thisCntx.  "updates local IP and SP"
	self fetchNextBytecode.
	self internalPush: localVal.

]

{ #category : #'message sending' }
NewspeakInterpreter >> commonSend [
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that 
	the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeNamed: 'commonSend' inCase: #singleExtendedSendBytecode>
	self fastLogSend: messageSelector.
	self sendBreakpoint: messageSelector receiver: (self internalStackValue: argumentCount).
	self internalFindNewMethod.
	self internalExecuteNewMethod.
	self fetchNextBytecode
]

{ #category : #'indexing primitive support' }
NewspeakInterpreter >> commonVariable: rcvr at: index cacheIndex: atIx [ 
	"This code assumes the receiver has been identified at location atIx in the atCache."
	| stSize fmt fixedFields result |

	stSize := atCache at: atIx+AtCacheSize.
	((self cCoerce: index to: 'usqInt ') >= 1
		and: [(self cCoerce: index to: 'usqInt ') <= (self cCoerce: stSize to: 'usqInt ')])
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

	self primitiveFailFor: ((self formatOf: rcvr) <= 1
								ifTrue: [PrimErrBadReceiver]
								ifFalse: [PrimErrBadIndex])
]

{ #category : #'indexing primitive support' }
NewspeakInterpreter >> commonVariable: rcvr at: index put: value cacheIndex: atIx [
	"This code assumes the receiver has been identified at location atIx in the atCache."
	"It also assumes that all immutability checking has been done by the caller."
	| stSize fmt fixedFields valToPut |
	<inline: true>

	stSize := atCache at: atIx+AtCacheSize.
	((self cCoerce: index to: 'usqInt ') >= 1
		and: [(self cCoerce: index to: 'usqInt ') <= (self cCoerce: stSize to: 'usqInt ')])
	ifTrue:
		[fmt := atCache at: atIx+AtCacheFmt.
		fmt <= 4 ifTrue:
			[fixedFields := atCache at: atIx+AtCacheFixedFields.
			^ self storePointer: index + fixedFields - 1 ofObject: rcvr withValue: value].
		fmt < 8 ifTrue:  "Bitmap"
			[valToPut := self positive32BitValueOf: value.
			self successful ifTrue:
				[^self storeLong32: index - 1 ofObject: rcvr withValue: valToPut].
			^ self primitiveFailFor: PrimErrBadArgument].
		fmt >= 16  "Note fmt >= 16 is an artificial flag for strings"
			ifTrue: [valToPut := self asciiOfCharacter: value.
					self successful ifFalse: [^ self primitiveFailFor: PrimErrBadArgument]]
			ifFalse: [valToPut := value].
		(self isIntegerObject: valToPut) ifTrue:
			[valToPut := self integerValueOf: valToPut.
			((valToPut >= 0) and: [valToPut <= 255]) ifFalse:
				[^ self primitiveFailFor: PrimErrBadArgument].
			^ self storeByte: index - 1 ofObject: rcvr withValue: valToPut].
		^self primitiveFailFor: PrimErrInappropriate].

	^self primitiveFailFor: ((self formatOf: rcvr) <= 1
								ifTrue: [PrimErrBadReceiver]
								ifFalse: [PrimErrBadIndex])
]

{ #category : #'array and stream primitive support' }
NewspeakInterpreter >> commonVariableInternal: rcvr at: index cacheIndex: atIx [ 
	"This code assumes the receiver has been identified at location atIx in the atCache."
	| stSize fmt fixedFields result |
	<inline: true>

	stSize := atCache at: atIx+AtCacheSize.
	((self cCoerce: index to: 'usqInt ') >= 1
		and: [(self cCoerce: index to: 'usqInt ') <= (self cCoerce: stSize to: 'usqInt ')])
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

	self primitiveFailFor: PrimErrBadIndex
]

{ #category : #'arithmetic primitive support' }
NewspeakInterpreter >> compare31or32Bits: obj1 equal: obj2 [
	"May set success to false"

	"First compare two ST integers..."
	((self isIntegerObject: obj1)
		and: [self isIntegerObject: obj2])
		ifTrue: [^ obj1 = obj2].

	"Now compare, assuming positive integers, but setting fail if not"
	^ (self positive32BitValueOf: obj1) = (self positive32BitValueOf: obj2)
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> context: thisCntx hasSender: aContext [ 
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
NewspeakInterpreter >> copyBits [
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
NewspeakInterpreter >> copyBitsFrom: x0 to: x1 at: y [
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

{ #category : #'debug printing' }
NewspeakInterpreter >> cr [
	"For testing in Smalltalk, this method should be overridden in a subclass."
	<inline: true>
	self printf: '\n'
]

{ #category : #'message sending' }
NewspeakInterpreter >> createActualMessageTo: aClass [ 
	"Bundle up the selector, arguments and lookupClass into a Message object. 
	In the process it pops the arguments off the stack, and pushes the message object. 
	This can then be presented as the argument of e.g. #doesNotUnderstand:."
	"remap lookupClass in case GC happens during allocation"
	| argumentArray message lookupClass |
	<inline: false> "This is a useful break-point"
	self pushRemappableOop: aClass.
	argumentArray := self instantiateClass: (self splObj: ClassArray) indexableSize: argumentCount.
	"remap argumentArray in case GC happens during allocation"
	self pushRemappableOop: argumentArray.
	message := self instantiateClass: (self splObj: ClassMessage) indexableSize: 0.
	argumentArray := self popRemappableOop.
	lookupClass := self popRemappableOop.
	self beRootIfOld: argumentArray.

	self transfer: argumentCount from: stackPointer - (argumentCount - 1 * BytesPerWord) to: argumentArray + BaseHeaderSize.
	self pop: argumentCount thenPush: message.

	argumentCount := 1.
	self storePointerUnchecked: MessageSelectorIndex ofObject: message withValue: messageSelector.
	self storePointerUnchecked: MessageArgumentsIndex ofObject: message withValue: argumentArray.
	self storePointerUnchecked: MessageLookupClassIndex ofObject: message withValue: lookupClass
]

{ #category : #utilities }
NewspeakInterpreter >> dbgFloatValueOf: oop [
	"This version answers the value of a float or nil if not a flat *WITHOUT* setting successFlag or any other such nonsense.  It is hence safe for use in debug printing.  Sheesh."

	| result |
	<returnTypeC: #double>
	<var: #result type: #double>
	self flag: #Dan.  "None of the float stuff has been converted for 64 bits"
	((self isNonIntegerObject: oop)
	and: [(self fetchClassOfNonImm: oop) = (self splObj: ClassFloat)]) ifTrue:
		[self cCode: '' inSmalltalk: [result := Float new: 2].
		 self fetchFloatAt: oop + BaseHeaderSize into: result.
		 ^result].
	^nil
]

{ #category : #'message sending' }
NewspeakInterpreter >> dispatchFunctionPointer: aFunctionPointer [
	"In C aFunctionPointer is void (*aFunctionPointer)()"
	<cmacro: '(aFunctionPointer) (aFunctionPointer)()'>
	(aFunctionPointer isInteger
	 and: [aFunctionPointer >= 1000]) ifTrue:
		[^self callExternalPrimitive: aFunctionPointer].
	"In Smalltalk aFunctionPointer is a message selector symbol"
	^self perform: aFunctionPointer
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> displayBitsOf: aForm Left: l Top: t Right: r Bottom: b [
	"Repaint the portion of the Smalltalk screen bounded by the affected rectangle. Used to synchronize the screen after a Bitblt to the Smalltalk Display object."

	| displayObj dispBits w h dispBitsIndex d left right top bottom surfaceHandle |
	displayObj := self splObj: TheDisplay.
	aForm = displayObj ifFalse: [^ nil].
	self success: ((self isPointers: displayObj) and: [(self lengthOf: displayObj) >= 4]).
	self successful ifTrue: [
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
	self successful ifTrue: [
		(self isIntegerObject: dispBits) ifTrue: [
			surfaceHandle := self integerValueOf: dispBits.
			showSurfaceFn = 0 ifTrue: [
				showSurfaceFn := self ioLoadFunction: 'ioShowSurface' From: 'SurfacePlugin'.
				showSurfaceFn = 0 ifTrue: [^self success: false]].
			self cCode:'((sqInt (*)(sqInt, sqInt, sqInt, sqInt, sqInt))showSurfaceFn)(surfaceHandle, left, top, right-left, bottom-top)'.
		] ifFalse: [
			dispBitsIndex := dispBits + BaseHeaderSize.  "index in memory byte array"
			self cCode: 'ioShowDisplay(dispBitsIndex, w, h, d, left, right, top, bottom)'
				inSmalltalk: [self showDisplayBits: dispBitsIndex 
								w: w h: h d: d
								left: left right: right top: top bottom: bottom]
		].
	].
]

{ #category : #'arithmetic primitive support' }
NewspeakInterpreter >> doPrimitiveDiv: rcvr by: arg [
	"Rounds negative results towards negative infinity, rather than zero."
	| result posArg posRcvr integerRcvr integerArg |
	(self areIntegers: rcvr and: arg)
		ifTrue: [integerRcvr := self integerValueOf: rcvr.
				integerArg := self integerValueOf: arg.
				self success: integerArg ~= 0]
		ifFalse: [self primitiveFail].
	self successful ifFalse: [^ 1 "fail"].

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
NewspeakInterpreter >> doPrimitiveMod: rcvr by: arg [
	| integerResult integerRcvr integerArg |
	(self areIntegers: rcvr and: arg)
		ifTrue: [integerRcvr := self integerValueOf: rcvr.
				integerArg := self integerValueOf: arg.
				self success: integerArg ~= 0]
		ifFalse: [self primitiveFail].
	self successful ifFalse: [^ 1 "fail"].

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

{ #category : #'process primitive support' }
NewspeakInterpreter >> doSignalSemaphoreWithIndex: index [
	"Signal the external semaphore with the given index.  Answer if a context switch
	 occurs as a result.  Do not bounds check.  This has been done in the caller."
	<api>
	| xArray semaphoreClass sema |
	xArray := self splObj: ExternalObjectsArray.
	semaphoreClass := self splObj: ClassSemaphore.
	sema := self fetchPointer: index - 1 ofObject: xArray. "Note: semaphore indices are 1-based"
	^(self isNonIntegerObject: sema)
	   and: [(self fetchClassOfNonImm: sema) = semaphoreClass
	   and: [self synchronousSignal: sema]]
]

{ #category : #'send bytecodes' }
NewspeakInterpreter >> doubleExtendedDoAnythingBytecode [
	"Replaces the Blue Book double-extended send [132], in which the first byte was wasted on 8 bits of argument count. 
	Here we use 3 bits for the operation sub-type (opType),  and the remaining 5 bits for argument count where needed. 
	The last byte give access to 256 instVars or literals. 
	See also secondExtendedSendBytecode"
	| byte2 byte3 opType top |
	byte2 := self fetchByte.
	byte3 := self fetchByte.
	opType := byte2 >> 5.
	opType = 0 ifTrue:
		[messageSelector := self literal: byte3.
		 argumentCount := byte2 bitAnd: 31.
		 ^ self normalSend].
	opType = 1 ifTrue:
		[messageSelector := self literal: byte3.
		 argumentCount := byte2 bitAnd: 31.
		 ^ self superclassSend].
	self fetchNextBytecode.
	opType = 2 ifTrue: [^ self pushReceiverVariable: byte3].
	opType = 3 ifTrue: [^ self pushLiteralConstant: byte3].
	opType = 4 ifTrue: [^ self pushLiteralVariable: byte3].
	opType = 5 ifTrue:
		[top := self internalStackTop.
		(self isObjImmutable: receiver) ifTrue:
			[self undoFetchNextBytecode.
			 ^self internalCannotAssign: top to: receiver withIndex: byte3].
		 ^ self storePointer: byte3 ofObject: receiver withValue: top].
	opType = 6 ifTrue:
		[top := self internalStackTop.
		 self internalPop: 1.
		(self isObjImmutable: receiver) ifTrue:
			[self undoFetchNextBytecode.
			 ^self internalCannotAssign: top to: receiver withIndex: byte3].
		 ^ self storePointer: byte3 ofObject: receiver withValue: top].
	opType = 7 ifTrue:
		[top := self internalStackTop.
		 ^ self storePointer: ValueIndex ofObject: (self literal: byte3) withValue: top]
]

{ #category : #initialization }
NewspeakInterpreter >> dummyReferToProxy [
	<inline: false>
	interpreterProxy := interpreterProxy
]

{ #category : #'debug support' }
NewspeakInterpreter >> dumpPrimTraceLog [
	"The prim trace log is a circular buffer of entries. If there is
	 an entry at primTraceLogIndex \\ PrimTraceLogSize it has entries.
	 If there is something at primTraceLogIndex it has wrapped."

	<api>
	<inline: false>
	(primTraceLog at: (self safe: primTraceLogIndex - 1 mod: TraceLogSize)) = 0 ifTrue: [^nil].
	(primTraceLog at: primTraceLogIndex) ~= 0 ifTrue:
		[primTraceLogIndex to: TraceLogSize - 1 do:
			[:i | self safePrintStringOf: (primTraceLog at: i); cr]].
	0 to: primTraceLogIndex - 1 do:
		[:i | self safePrintStringOf: (primTraceLog at: i); cr]
]

{ #category : #'debug support' }
NewspeakInterpreter >> dumpSendTraceLog [
	"The send trace log is a circular buffer of entries. If there is
	 an entry at sendTraceLogIndex \\ PrimTraceLogSize it has entries.
	 If there is something at sendTraceLogIndex it has wrapped."

	<api>
	<inline: false>
	(sendTraceLog at: (self safe: sendTraceLogIndex - 1 mod: TraceLogSize)) = 0 ifTrue: [^nil].
	(sendTraceLog at: sendTraceLogIndex) ~= 0 ifTrue:
		[sendTraceLogIndex to: TraceLogSize - 1 do:
			[:i | self safePrintStringOf: (sendTraceLog at: i); cr]].
	0 to: sendTraceLogIndex - 1 do:
		[:i | self safePrintStringOf: (sendTraceLog at: i); cr]
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> duplicateTopBytecode [

	self fetchNextBytecode.
	self internalPush: self internalStackTop.

]

{ #category : #'send bytecodes' }
NewspeakInterpreter >> dynamicSuperSendBytecode [
"Send a message to self, starting lookup in the superclass of the method application of the currently executing method's mixin."
"Assume: messageSelector and argumentCount have been set, and that the receiver and arguments have been pushed onto the stack," 
"WE WANT THE RECEIVER PUSHED IMPLICITLY, BUT IT IS NOT - SO FAR"
"Note: This method is inlined into the interpreter dispatch loop."
	| rcvr mClassMixin mixinApplication |
	<inline: true>
	argumentCount := self fetchByte.
	messageSelector := self literal: self fetchByte.
	rcvr := self internalStackValue: argumentCount.
	mClassMixin := self methodClassOf: method.
	mixinApplication := self 
		findApplicationOfTargetMixin: mClassMixin
		startingAtBehavior: (self fetchClassOf: rcvr).
	lkupClass := self superclassOf: mixinApplication.
	self commonSend
]

{ #category : #'debug printing' }
NewspeakInterpreter >> elementsPerPrintOopLine [
	^5
]

{ #category : #'message sending' }
NewspeakInterpreter >> executeNewMethod [
	"Execute newMethod - either primitiveFunctionPointer must be set directly
	 (i.e. from primitiveExecuteMethod et al), or it would have been set probing
	 the method cache (i.e. primitivePerform et al)."
	primitiveFunctionPointer ~= 0 ifTrue:
		[self isPrimitiveFunctionPointerAnIndex ifTrue:
			[self externalQuickPrimitiveResponse.
			 ^nil].
		 self slowPrimitiveResponse ifTrue: [^nil]].
	"if not primitive, or primitive failed, activate the method"
	self activateNewMethod.
	"check for possible interrupts at each real send"
	self quickCheckForInterrupts
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> explicitOuterReceiver: n withObject: anObject withMixin: mixin [ 
	"This is used to implement the innards of the pushExplicitOuterReceiverBytecode,
	 used for explicit outer sends in NS2/NS3.  "
	| explicitReceiver mixinApplication  targetMixin  count |
	
	explicitReceiver := anObject.
	targetMixin := mixin.
	count := 0.
	[count < n] whileTrue:[
		count := count + 1.
		(targetMixin == nilObj or:[explicitReceiver == nilObj]) ifTrue:
		[^nilObj].
		mixinApplication := self
							findApplicationOfTargetMixin: targetMixin
							startingAtNonMetaClass: (self fetchClassOf: explicitReceiver).
		mixinApplication == nilObj ifTrue:[^nilObj]. "should never happen!"
		explicitReceiver := self fetchPointer: EnclosingObjectIndex 
								ofObject: mixinApplication.	
		targetMixin := self fetchPointer: EnclosingMixinIndex ofObject: targetMixin.	
	].
	
	^explicitReceiver
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> extendedPushBytecode [

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
NewspeakInterpreter >> extendedStoreAndPopBytecode [

	self extendedStoreBytecode.
	self internalPop: 1.

]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> extendedStoreBytecode [
	| descriptor variableType value variableIndex association isPop |
	<inline: true>
	isPop := currentBytecode = 130.  "extendedStoreAndPopBytecode"
	descriptor := self fetchByte.
	self fetchNextBytecode.
	variableType := descriptor >> 6 bitAnd: 3.
	variableIndex := descriptor bitAnd: 63.
	variableType = 2 ifTrue:
		[^self error: 'illegal store'].
	value := self internalStackTop.
	variableType = 0 ifTrue:
		[(self isObjImmutable: receiver) ifTrue:
			[isPop ifTrue: [self internalPop: 1].
			 self undoFetchNextBytecode.
			 ^self internalCannotAssign: value to: receiver withIndex: variableIndex].
		^self storePointer: variableIndex ofObject: receiver withValue: value].
	variableType = 1 ifTrue:
		[^self storePointerUnchecked: variableIndex + TempFrameStart ofObject: localHomeContext withValue: value].
	variableType = 3 ifTrue:
		[association := self literal: variableIndex.
		 (self isObjImmutable: association) ifTrue:
			[isPop ifTrue: [self internalPop: 1].
			 self undoFetchNextBytecode.
			 ^self internalCannotAssign: value to: association withIndex: ValueIndex].
		^self storePointer: ValueIndex ofObject: association withValue: value]
]

{ #category : #'primitive support' }
NewspeakInterpreter >> externalQuickPrimitiveResponse [
	"Called under the assumption that primFunctionPtr has been preloaded"
	
	| localPrimIndex |
	self assert: self isPrimitiveFunctionPointerAnIndex.
	localPrimIndex := self cCoerceSimple: primitiveFunctionPointer to: #sqInt.
	self assert: (localPrimIndex > 255 and: [localPrimIndex < 520]).
	"Quick return inst vars"
	localPrimIndex >= 264 ifTrue:
		[self pop: 1 thenPush: (self fetchPointer: localPrimIndex - 264 ofObject: self stackTop).
		 ^true].
	"Quick return constants"
	localPrimIndex = 256 ifTrue: [^true "return self"].
	localPrimIndex = 257 ifTrue: [self pop: 1 thenPush: self trueObject. ^true].
	localPrimIndex = 258 ifTrue: [self pop: 1 thenPush: self falseObject. ^true].
	localPrimIndex = 259 ifTrue: [self pop: 1 thenPush: self nilObject. ^true].
	self pop: 1 thenPush: (self integerObjectOf: localPrimIndex - 261).
	^true
]

{ #category : #utilities }
NewspeakInterpreter >> externalizeIPandSP [
	"Copy the local instruction and stack pointer to global variables for use in primitives and other functions outside the interpret loop."

	instructionPointer := self oopForPointer: localIP.
	stackPointer := self oopForPointer: localSP.
	theHomeContext := localHomeContext.

]

{ #category : #'primitive support' }
NewspeakInterpreter >> failUnbalancedPrimitive [
	"not inlined for breakpoint value..."
	<inline: false>
	self primitiveFailFor: PrimErrBadNumArgs
]

{ #category : #'primitive support' }
NewspeakInterpreter >> failed [
	<api>
	"In C, non-zero is true, so avoid computation by simply answering primFailCode in the C version."
	^self cCode: [primFailCode] inSmalltalk: [primFailCode ~= 0]
]

{ #category : #'debug support' }
NewspeakInterpreter >> fastLogPrim: aSelector [
	"Fast tracing of named primitives.  primTraceLogIndex is a byte variable.
	 primTraceLog has 256 entries.  In C the + 1 below is hence implicitly modulo 256."
	<inline: true>
	RecordPrimTrace ifTrue:
		[primTraceLog at: primTraceLogIndex put: aSelector.
		 self primTraceLogIndex: primTraceLogIndex + 1]
]

{ #category : #'debug support' }
NewspeakInterpreter >> fastLogSend: aSelector [
	"Fast tracing of sends.  sendTraceLogIndex is a byte variable.
	 sendTraceLog has 256 entries.  In C the + 1 below is hence implicitly modulo 256."
	<inline: true>
	RecordSendTrace ifTrue:
		[sendTraceLog at: sendTraceLogIndex put: aSelector.
		 self sendTraceLogIndex: sendTraceLogIndex + 1]
]

{ #category : #utilities }
NewspeakInterpreter >> fetchArray: fieldIndex ofObject: objectPointer [
	"Fetch the instance variable at the given index of the given object. Return the address of first indexable field of resulting array object, or fail if the instance variable does not contain an indexable bytes or words object."
	"Note: May be called by translated primitive code."

	| arrayOop |
	<returnTypeC: 'void *'>
	arrayOop := self fetchPointer: fieldIndex ofObject: objectPointer.
	^ self arrayValueOf: arrayOop

]

{ #category : #'interpreter shell' }
NewspeakInterpreter >> fetchByte [
	"This method uses the preIncrement builtin function which has no Smalltalk equivalent. Thus, it must be overridden in the simulator."

	^ self byteAtPointer: localIP preIncrement
]

{ #category : #contexts }
NewspeakInterpreter >> fetchContextRegisters: activeCntx [ 
	"Note: internalFetchContextRegisters: should track changes  to this method."
	| tmp |
	<inline: true>
	tmp := self fetchPointer: MethodIndex ofObject: activeCntx.
	(self isIntegerObject: tmp)
		ifTrue: ["if the MethodIndex field is an integer, activeCntx is a block context"
			tmp := self fetchPointer: HomeIndex ofObject: activeCntx.
			tmp < youngStart ifTrue: [self beRootIfOld: tmp]]
		ifFalse: ["otherwise, it is a method context and is its own home context "
			tmp := activeCntx].
	theHomeContext := tmp.
	receiver := self fetchPointer: ReceiverIndex ofObject: tmp.
	method := self fetchPointer: MethodIndex ofObject: tmp.

	"the instruction pointer is a pointer variable equal to 
	method oop + ip + BaseHeaderSize 
	-1 for 0-based addressing of fetchByte 
	-1 because it gets incremented BEFORE fetching currentByte "
	tmp := self quickFetchInteger: InstructionPointerIndex ofObject: activeCntx.
	instructionPointer := method + tmp + BaseHeaderSize - 2.

	"the stack pointer is a pointer variable also..."
	tmp := self quickFetchInteger: StackPointerIndex ofObject: activeCntx.
	stackPointer := activeCntx + BaseHeaderSize + (TempFrameStart + tmp - 1 * BytesPerWord)
]

{ #category : #utilities }
NewspeakInterpreter >> fetchFloat: fieldIndex ofObject: objectPointer [
	"Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float."
	"Note: May be called by translated primitive code."

	| floatOop |
	<returnTypeC: 'double'>
	floatOop := self fetchPointer: fieldIndex ofObject: objectPointer.
	^ self floatValueOf: floatOop
]

{ #category : #utilities }
NewspeakInterpreter >> fetchInteger: fieldIndex ofObject: objectPointer [
	"Note: May be called by translated primitive code."

	| intOop |
	<inline: false>
	intOop := self fetchPointer: fieldIndex ofObject: objectPointer.
	^self checkedIntegerValueOf: intOop
]

{ #category : #utilities }
NewspeakInterpreter >> fetchIntegerOrTruncFloat: fieldIndex ofObject: objectPointer [
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
	self successful ifTrue: [
		self cCode: '' inSmalltalk: [floatVal := Float new: 2].
		self fetchFloatAt: intOrFloat + BaseHeaderSize into: floatVal.
		self cCode: 'frac = modf(floatVal, &trunc)'.
		"the following range check is for C ints, with range -2^31..2^31-1"
		self flag: #Dan.		"The ranges are INCORRECT if SmallIntegers are wider than 31 bits."
		self cCode: 'success((-2147483648.0 <= trunc) && (trunc <= 2147483647.0))'.].
	self successful
		ifTrue: [^ self cCode: '((sqInt) trunc)' inSmalltalk: [floatVal truncated]]
		ifFalse: [^ 0].

]

{ #category : #'interpreter shell' }
NewspeakInterpreter >> fetchNextBytecode [
	"This method fetches the next instruction (bytecode). Each bytecode method is responsible for fetching the next bytecode, preferably as early as possible to allow the memory system time to process the request before the next dispatch."

	currentBytecode := self fetchByte.

]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> fetchStackPointerOf: aContext [
	"Return the stackPointer of a Context or BlockContext."
	| sp |
	<inline: true>
	sp := self fetchPointer: StackPointerIndex ofObject: aContext.
	(self isIntegerObject: sp) ifFalse: [^0].
	^self integerValueOf: sp
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> findApplicationOfTargetMixin: targetMixin startingAtBehavior: aBehavior [
	"This is used to implement the innards of the pushImplicitReceiverBytecode,
	 used for outer sends in NS2/NS3.  Find the MixinApplcation of which aBehavior
	is a subclass that is an application of targetMixin.  This is an implementation derived from

	<ContextPart> findApplicationOfTargetMixin: targetMixin startingAtBehavior: aBehavior
	"
	| mixinOrMixinApplication mixin |
	mixinOrMixinApplication := aBehavior.
	[mixinOrMixinApplication == nilObj
	 or: [mixinOrMixinApplication == targetMixin
	 or: [(mixin := self fetchPointer: MixinIndex ofObject: mixinOrMixinApplication) == targetMixin
	 or: [(self fetchClassOf: mixin) == targetMixin]]]] whileFalse:
		[mixinOrMixinApplication := self fetchPointer: SuperclassIndex ofObject: mixinOrMixinApplication].
	^mixinOrMixinApplication
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> findApplicationOfTargetMixin: targetMixin startingAtNonMetaClass: aClass [
	"This is used to implement the innards of the pushImplicitReceiverBytecode,
	 used for outer sends in NS2/NS3.  Find the MixinApplcation of which aClass
	is a subclass that is an application of targetMixin.  This is an implementation derived from

	<ContextPart> findApplicationOfTargetMixin: targetMixin startingAtNonMetaClass: aClass
	"
	| mixinOrMixinApplication |
	mixinOrMixinApplication := aClass.
	[mixinOrMixinApplication == nilObj
	 or: [mixinOrMixinApplication == targetMixin
	 or: [(self fetchPointer: MixinIndex ofObject: mixinOrMixinApplication) == targetMixin]]] whileFalse:
		[mixinOrMixinApplication := self fetchPointer: SuperclassIndex ofObject: mixinOrMixinApplication].
	^mixinOrMixinApplication
]

{ #category : #'debug support' }
NewspeakInterpreter >> findClassOfMethod: meth forReceiver: rcvr [

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

{ #category : #'debug printing' }
NewspeakInterpreter >> findHomeForContext: aContext [
	| closureOrNil |
	<inline: false>
	(self isMethodContext: aContext) ifFalse:
		[^self fetchPointer: HomeIndex ofObject: aContext].
	closureOrNil := self fetchPointer: ClosureIndex ofObject: aContext.
	closureOrNil = self nilObject ifTrue:
		[^aContext].
	^self findHomeForContext: (self fetchPointer: ClosureOuterContextIndex ofObject: closureOrNil)
]

{ #category : #'message sending' }
NewspeakInterpreter >> findNewMethodInClass: class [ 
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
NewspeakInterpreter >> findSelectorOfMethod: meth forReceiver: rcvr [

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

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> floatArg: index [
	"Like #stackFloatValue: but access method arguments left-to-right"
	| oop |
	<returnTypeC: #double>
	oop := self methodArg: index.
	oop = 0 ifTrue:[^0.0]. "methodArg: failed"
	^self floatValueOf: oop
]

{ #category : #'object format' }
NewspeakInterpreter >> floatObjectOf: aFloat [
	| newFloatObj |
	<var: #aFloat type: #double>
	<inline: false> "because storeFloatAt:from: insists that its last arg is a variable"
	self flag: #Dan. "None of the float stuff has been converted for 64 bits"
	newFloatObj := self instantiateSmallClass: (self splObj: ClassFloat) sizeInBytes: 8+BaseHeaderSize.
	self storeFloatAt: newFloatObj + BaseHeaderSize from: aFloat.
	^newFloatObj
]

{ #category : #utilities }
NewspeakInterpreter >> floatValueOf: oop [
	"Answer the C double precision floating point value of the argument,
	 or fail if it is not a Float, and answer 0.
	 Note: May be called by translated primitive code."

	| isFloat result |
	<returnTypeC: #double>
	<var: #result type: #double>
	isFloat := self isInstanceOfClassFloat: oop.
	isFloat ifTrue:
		[self cCode: '' inSmalltalk: [result := Float new: 2].
		 self fetchFloatAt: oop + BaseHeaderSize into: result.
		 ^result].
	self primitiveFail.
	^0.0
]

{ #category : #'debug printing' }
NewspeakInterpreter >> flush [
	<cmacro: '() fflush(stdout)'>
]

{ #category : #'method lookup cache' }
NewspeakInterpreter >> flushAtCache [
	"Flush the at cache. The method cache is flushed on every programming change and garbage collect."

	1 to: AtCacheTotalSize do: [ :i | atCache at: i put: 0 ]
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> flushExternalPrimitiveOf: methodPtr [
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
NewspeakInterpreter >> flushExternalPrimitiveTable [
	"Flush the external primitive table"
	0 to: MaxExternalPrimitiveTableSize-1 do:[:i|
		externalPrimitiveTable at: i put: 0].

]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> flushExternalPrimitives [
	"Flush the references to external functions from plugin 
	primitives. This will force a reload of those primitives when 
	accessed next. 
	Note: We must flush the method cache here so that any 
	failed primitives are looked up again."
	| oop primIdx |
	oop := self firstObject.
	[oop < endOfMemory]
		whileTrue: [(self isFreeObject: oop)
				ifFalse: [(self isCompiledMethod: oop)
						ifTrue: ["This is a compiled method"
							primIdx := self primitiveIndexOf: oop.
							primIdx = PrimitiveExternalCallIndex
								ifTrue: ["It's primitiveExternalCall"
									self flushExternalPrimitiveOf: oop]]].
			oop := self objectAfter: oop].
	self flushMethodCache.
	self flushAtCache.
	self flushExternalPrimitiveTable
]

{ #category : #'method lookup cache' }
NewspeakInterpreter >> flushMethodCache [
	"Flush the method cache. The method cache is flushed on every programming change and garbage collect."

	1 to: MethodCacheSize do: [ :i | methodCache at: i put: 0 ]
]

{ #category : #'method lookup cache' }
NewspeakInterpreter >> flushMethodCacheFrom: memStart to: memEnd [ 
	"Flush entries in the method cache only if the oop address is within the given memory range. 
	This reduces overagressive cache clearing. Note the AtCache is fully flushed, 70% of the time 
	cache entries live in newspace, new objects die young"
	| probe |
	probe := 0.
	1 to: MethodCacheEntries do: [:i | 
			(methodCache at: probe + MethodCacheSelector) = 0
				ifFalse: [((((self oop: (methodCache at: probe + MethodCacheSelector) isGreaterThanOrEqualTo: memStart)
										and: [self oop: (methodCache at: probe + MethodCacheSelector) isLessThan: memEnd])
									or: [(self oop: (methodCache at: probe + MethodCacheClass) isGreaterThanOrEqualTo: memStart)
											and: [self oop: (methodCache at: probe + MethodCacheClass) isLessThan: memEnd]])
								or: [(self oop: (methodCache at: probe + MethodCacheMethod) isGreaterThanOrEqualTo: memStart)
										and: [self oop: (methodCache at: probe + MethodCacheMethod) isLessThan: memEnd]])
						ifTrue: [methodCache at: probe + MethodCacheSelector put: 0]].
			probe := probe + MethodCacheEntrySize].
	1 to: AtCacheTotalSize do: [:i | atCache at: i put: 0]
]

{ #category : #'process primitive support' }
NewspeakInterpreter >> forceInterruptCheck [
	"force an interrupt check ASAP - setting interruptCheckCounter to a large -ve number is used as a flag to skip messing with the feedback mechanism and nextPollTick resetting makes sure that ioProcess gets called as near immediately as we can manage"
	interruptCheckCounter := -1000.
	nextPollTick := 0
]

{ #category : #'I/O primitive support' }
NewspeakInterpreter >> fullDisplayUpdate [
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
NewspeakInterpreter >> functionPointerFor: primIdx inClass: theClass [
	"Find an actual function pointer for this primitiveIndex.  This is an
	opportunity to specialise the prim for the relevant class (format for
	example).  Default for now is simply the entry in the base primitiveTable."

	<returnTypeC: 'void *'>
	^primitiveTable at: primIdx
]

{ #category : #'interpreter shell' }
NewspeakInterpreter >> getCurrentBytecode [
	"currentBytecode will be private to the main dispatch loop in the generated code. This method allows the currentBytecode to be retrieved from global variables."

	^ self byteAt: instructionPointer
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> getDeferDisplayUpdates [
	^deferDisplayUpdates
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> getFullScreenFlag [
	^fullScreenFlag
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> getInterruptCheckCounter [
	^interruptCheckCounter
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> getInterruptKeycode [
	^interruptKeycode
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> getInterruptPending [
	^interruptPending
]

{ #category : #'image save/restore' }
NewspeakInterpreter >> getLongFromFile: aFile swap: swapFlag [
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
NewspeakInterpreter >> getNextWakeupTick [
	^nextWakeupTick
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> getSavedWindowSize [
	^savedWindowSize
]

{ #category : #'primitive support' }
NewspeakInterpreter >> getStackPointer [
	"For Newsqueak FFI"
	<export: true>
	<returnTypeC: #'sqInt *'>
	^self cCoerce: stackPointer to: #'sqInt *'
]

{ #category : #'plugin support' }
NewspeakInterpreter >> getThisSessionID [
	"return the global session ID value"
	<inline: false>
	^globalSessionID
]

{ #category : #'compiled methods' }
NewspeakInterpreter >> headerOf: methodPointer [
	^self fetchPointer: HeaderIndex ofObject: methodPointer
]

{ #category : #'process primitive support' }
NewspeakInterpreter >> highBit: anUnsignedValue [ 
	"This is a C implementation needed by ioSetMaxExtSemTableSize."
	| shifted bitNo |
	<api>
	<var: #anUnsignedValue type: #usqInt>
	<var: #shifted type: #usqInt>
	shifted := anUnsignedValue.
	bitNo := 0.
	self cppIf: BytesPerWord > 4
		ifTrue:
			[shifted < (1 << 32) ifFalse:
				[shifted := shifted >> 32.
				 bitNo := bitNo + 32]].
	shifted < (1 << 16) ifFalse:
		[shifted := shifted >> 16.
		 bitNo := bitNo + 16].
	shifted < (1 << 8) ifFalse:
		[shifted := shifted >> 8.
		 bitNo := bitNo + 8].
	shifted < (1 << 4) ifFalse:
		[shifted := shifted >> 4.
		 bitNo := bitNo + 4].
	shifted < (1 << 2) ifFalse:
		[shifted := shifted >> 2.
		 bitNo := bitNo + 2].
	shifted < (1 << 1) ifFalse:
		[shifted := shifted >> 1.
		 bitNo := bitNo + 1].
	"shifted 0 or 1 now"
	^bitNo + shifted
]

{ #category : #'debug support' }
NewspeakInterpreter >> ifValidWriteBackStack: theCFP Pointers: theCSP Save: savedFPP To: savedSPP [
	"This is for low-level error reporting.  If either of the C stack pointers are
	 pointing into the stack zone then write them back to framePointer and/or
	 stackPointer so that the stack backtrace will be up to date.  Write their
	 original values through savedFPP & savedSPP if non-null.
	 This is a noop in the Interpreter VM since the C stack pointers are always
	 elsewhere (e.g., in some C function running the interpreter)."
	<api>
	<var: #theCFP type: #'void *'>
	<var: #theCSP type: #'void *'>
	<var: #savedFPP type: #'char **'>
	<var: #savedSPP type: #'char **'>
	<returnTypeC: #void>
]

{ #category : #'image save/restore' }
NewspeakInterpreter >> imageFormatCompatibilityVersion [
	"This VM is backward-compatible with the immediately preceeding non-closure version."

	BytesPerWord == 4
		ifTrue: [^6502]
		ifFalse: [^68000]
]

{ #category : #'image save/restore' }
NewspeakInterpreter >> imageFormatForwardCompatibilityVersion [
	"This VM is forwards-compatible with the immediately following closure version, and
	 will write the new version number in snapshots if the closure creation bytecode is used."

	BytesPerWord == 4
		ifTrue: [^6504]
		ifFalse: [^68002]
]

{ #category : #'image save/restore' }
NewspeakInterpreter >> imageFormatVersion [
	"Return a magic constant that changes when the image format changes. Since the image reading code uses
	 this to detect byte ordering, one must avoid version numbers that are invariant under byte reversal."

	"See NewspeakInterpreter class>>declareCVarsIn: and NewspeakInterpreter>>pushClosureCopyCopiedValuesBytecode
	 for the initialization of imageFormatVersionNumber"
	^imageFormatVersionNumber
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> implicitReceiverForMixin: mixin implementing: selector [
	"This is used to implement the innards of the pushImplicitReceiverBytecode,
	 used for implicit receiver sends in NS2/NS3.  Find the nearest lexically-enclosing
	 implementation of selector by searching up the static chain of anObject,
	 starting at mixin's application.  This is an iterative implementation derived from

	<ContextPart> implicitReceiverFor: obj <Object>
					withMixin: mixin <Mixin>
					implementing: selector <Symbol> ^<Object
	 "
	| mixinApplication dictionary found |
	messageSelector := selector. "messageSelector is an implicit parameter of lookupMethodInDictionary:"
	mixinApplication := self
							findApplicationOfTargetMixin: mixin
							startingAtBehavior: (self fetchClassOf: receiver).
	 mixinApplication == nilObj ifTrue:
		[^receiver].
	 dictionary := self fetchPointer: MessageDictionaryIndex ofObject: mixinApplication.
	 found := self lookupMethodInDictionary: dictionary.
	 found ifFalse:
		[| implicitReceiverOrNil theMixin |
		 theMixin := self fetchPointer: MixinIndex ofObject: mixinApplication.
		 implicitReceiverOrNil := self nextImplicitReceiverFor: (self fetchPointer: EnclosingObjectIndex
																ofObject: mixinApplication)
									withMixin: (self fetchPointer: EnclosingMixinIndex ofObject: theMixin).
		 implicitReceiverOrNil ~= nilObj ifTrue:
			[^implicitReceiverOrNil]].
	^receiver
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> includesBehavior: aClass ThatOf: aSuperclass [
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

{ #category : #'primitive support' }
NewspeakInterpreter >> initPrimCall [
	"Selt the failure code/success flag in preparation for calling a primitve.
	 If primfailCode is non-zero a primitive has failed.  If primFailCode is greater
	 than one then its value indicates the reason for failure."
	<inline: true>
	primFailCode := 0
]

{ #category : #initialization }
NewspeakInterpreter >> initialCleanup [
	"Images written by VMs earlier than 3.6/3.7 will wrongly have the root bit set on the active context. Besides clearing the root bit, we treat this as a marker that these images also lack a cleanup of external primitives (which has been introduced at the same time when the root bit problem was fixed). In this case, we merely flush them from here."

	((self longAt: activeContext) bitAnd: RootBit) = 0 ifTrue:[^nil]. "root bit is clean"
	"Clean root bit of activeContext"
	self longAt: activeContext put: ((self longAt: activeContext) bitAnd: AllButRootBit).
	"Clean external primitives"
	self flushExternalPrimitives.
]

{ #category : #initialization }
NewspeakInterpreter >> initialize [
	<doNotGenerate>
	super initialize.
	imageFormatVersionNumber := 6502
]

{ #category : #initialization }
NewspeakInterpreter >> initializeExtraClassInstVarIndices [
	"Initialize metaclassSizeBits and thisClassIndex which are used in debug printing, and
	 classNameIndex which is used not only for debug printing but for is:KindOf: & is:MemberOf:
	 via classNameOf:is: (evil but a reality we have to accept)."
	| classArrayObj classArrayClass |
	classNameIndex := 6. "default"
	thisClassIndex := 5. "default"
	classArrayObj := self splObj: ClassArray.
	classArrayClass := self fetchClassOfNonImm: classArrayObj.
	metaclassSizeBits := self sizeBitsOf: classArrayClass.	"determine actual (Metaclass instSize * 4)"
	InstanceSpecificationIndex + 1 to: (self lengthOf: classArrayClass) do:
		[:i|
		(self fetchPointer: i ofObject: classArrayClass) = classArrayObj ifTrue:
			[thisClassIndex := i]].
	InstanceSpecificationIndex + 1 to: (self lengthOf: classArrayObj) do:
		[:i| | oop |
		oop := self fetchPointer: i ofObject: classArrayObj.
		((self isBytes: oop)
		and: [(self lengthOf: oop) = 5
		and: [(self str: 'Array' n: (self firstFixedField: oop) cmp: 5) = 0]]) ifTrue:
			[classNameIndex := i]]
]

{ #category : #initialization }
NewspeakInterpreter >> initializeInterpreter: bytesToShift [ 
	"Initialize NewspeakInterpreter state before starting execution of a new image."
	interpreterProxy := self sqGetInterpreterProxy.
	self dummyReferToProxy.
	self initializeObjectMemory: bytesToShift.
	self checkAssumedCompactClasses.
	primFailCode := 0.
	self initializeExtraClassInstVarIndices.
	activeContext := nilObj.
	theHomeContext := nilObj.
	method := nilObj.
	receiver := nilObj.
	messageSelector := nilObj.
	newMethod := nilObj.
	lkupClass := nilObj.
	self flushMethodCache.
	self flushAtCache.
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
	deferDisplayUpdates := false.
	pendingFinalizationSignals := 0.
	globalSessionID := 0.
	[globalSessionID = 0]
		whileTrue: [globalSessionID := self
						cCode: 'time(NULL) + ioMSecs()'
						inSmalltalk: [(Random new next * SmallInteger maxVal) asInteger]]
]

{ #category : #'indexing primitive support' }
NewspeakInterpreter >> install: rcvr inAtCache: cache at: atIx string: stringy [
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

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> integerArg: index [
	"Like #stackIntegerValue: but access method arguments left-to-right"
	| oop |
	oop := self methodArg: index.
	oop = 0 ifTrue:[^0.0]. "methodArg: failed"
	^self checkedIntegerValueOf: oop
]

{ #category : #'return bytecodes' }
NewspeakInterpreter >> internalAboutToReturn: resultObj through: aContext [
	<inline: true>
	self internalPush: activeContext.
	self internalPush: resultObj.
	self internalPush: aContext.
	messageSelector := self splObj: SelectorAboutToReturn.
	argumentCount := 2.
	^self normalSend
]

{ #category : #'message sending' }
NewspeakInterpreter >> internalActivateNewMethod [
	| methodHeader initialIP newContext tempCount argCount2 needsLarge where |
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
	initialIP := ((LiteralStart + (self literalCountOfHeader: methodHeader)) * BytesPerWord) + 1.
	tempCount := (methodHeader >> 19) bitAnd: 16r3F.

	"Assume: newContext will be recorded as a root if necessary by the
	 call to newActiveContext: below, so we can use unchecked stores."
	where :=   newContext + BaseHeaderSize.
	self longAt: where + (SenderIndex << ShiftForWord) put: activeContext.
	self longAt: where + (InstructionPointerIndex << ShiftForWord) put: (self integerObjectOf: initialIP).
	self longAt: where + (StackPointerIndex << ShiftForWord) put: (self integerObjectOf: tempCount).
	self longAt: where + (MethodIndex << ShiftForWord) put: newMethod.
	self longAt: where + (ClosureIndex << ShiftForWord) put: nilObj.

	"Copy the receiver and arguments..."
	argCount2 := argumentCount.
	0 to: argCount2 do:
		[:i | self longAt: where + ((ReceiverIndex+i) << ShiftForWord) put: (self internalStackValue: argCount2-i)].

	"clear remaining temps to nil in case it has been recycled"
	needsLarge := nilObj.  "needsLarge here used just as faster (register?) temp"
	argCount2+1+ReceiverIndex to: tempCount+ReceiverIndex do:
		[:i | self longAt: where + (i << ShiftForWord) put: needsLarge].

	"Pass primitive error code to last temp if method receives it (indicated
	 by an initial long store temp bytecode).  Protect against obsolete values
	 in primFailCode by checking that newMethod actually has a primitive?"
	primFailCode > 0 ifTrue:
		[((self primitiveIndexOfMethodHeader: methodHeader) > 0
		  and: [(self fetchByte: initialIP - 1 ofObject: newMethod) = 129 "long store temp"]) ifTrue:
			[needsLarge := self fetchPointer: primFailCode - 1 ofObject: (self splObj: PrimErrTableIndex).
			 self longAt: where + ((tempCount+ReceiverIndex) << ShiftForWord)
				put: needsLarge "nil if primFailCode == 1, or primFailCode"].
		primFailCode := 0].

	self internalPop: argCount2 + 1.
	reclaimableContextCount := reclaimableContextCount + 1.
	self internalNewActiveContext: newContext.
 
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> internalCannotAssign: resultObj to: targetObj withIndex: index [
	<inline: true> "because of use of normalSend..."
	self internalPush: targetObj.
	self internalPush: resultObj.
	self internalPush: (self integerObjectOf: index + 1).
	messageSelector := self splObj: SelectorAttemptToAssign.
	argumentCount := 2.
	^ self normalSend
]

{ #category : #'return bytecodes' }
NewspeakInterpreter >> internalCannotReturn: resultObj [
	<inline: true>
	self internalPush: activeContext.
	self internalPush: resultObj.
	messageSelector := self splObj: SelectorCannotReturn.
	argumentCount := 1.
	^ self normalSend
]

{ #category : #'message sending' }
NewspeakInterpreter >> internalExecuteNewMethod [
	| succeeded |
	<inline: true>
	primitiveFunctionPointer ~~ 0 ifTrue:
		[self isPrimitiveFunctionPointerAnIndex ifTrue:
			[^self internalQuickPrimitiveResponse].
		 self externalizeIPandSP.
		 succeeded := self slowPrimitiveResponse.
		 self internalizeIPandSP.
		 succeeded ifTrue:
			[self browserPluginReturnIfNeeded.
			^nil]].
	"if not primitive, or primitive failed, activate the method"
	self internalActivateNewMethod.
	"check for possible interrupts at each real send"
	self internalQuickCheckForInterrupts
]

{ #category : #contexts }
NewspeakInterpreter >> internalFetchContextRegisters: activeCntx [
	"Inlined into return bytecodes. The only difference between this method and fetchContextRegisters: is that this method sets the local IP and SP."

	| tmp |
	<inline: true>
	tmp := self fetchPointer: MethodIndex ofObject: activeCntx.
	(self isIntegerObject: tmp) ifTrue: [
		"if the MethodIndex field is an integer, activeCntx is a block context"
		tmp := self fetchPointer: HomeIndex ofObject: activeCntx.
		(tmp < youngStart) ifTrue: [ self beRootIfOld: tmp ].
	] ifFalse: [
		"otherwise, it is a method context and is its own home context"
		tmp := activeCntx.
	].
	localHomeContext := tmp.
	receiver := self fetchPointer: ReceiverIndex ofObject: tmp.
	method := self fetchPointer: MethodIndex ofObject: tmp.

	"the instruction pointer is a pointer variable equal to
		method oop + ip + BaseHeaderSize
		  -1 for 0-based addressing of fetchByte
		  -1 because it gets incremented BEFORE fetching currentByte"
	tmp := self quickFetchInteger: InstructionPointerIndex ofObject: activeCntx.
	localIP := self pointerForOop: method + tmp + BaseHeaderSize - 2.

	"the stack pointer is a pointer variable also..."
	tmp := self quickFetchInteger: StackPointerIndex ofObject: activeCntx.
	localSP := self pointerForOop: activeCntx + BaseHeaderSize + ((TempFrameStart + tmp - 1) * BytesPerWord)
]

{ #category : #'message sending' }
NewspeakInterpreter >> internalFindNewMethod [
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

{ #category : #contexts }
NewspeakInterpreter >> internalNewActiveContext: aContext [
	"The only difference between this method and newActiveContext: is that this method uses internal context registers."
	<inline: true>

	self internalStoreContextRegisters: activeContext.
	(aContext < youngStart) ifTrue: [ self beRootIfOld: aContext ].
	activeContext := aContext.
	self internalFetchContextRegisters: aContext.
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> internalPop: nItems [

	localSP := localSP - (nItems * BytesPerWord).
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> internalPop: nItems thenPush: oop [

	self longAtPointer: (localSP := localSP - ((nItems - 1) * BytesPerWord)) put: oop.

]

{ #category : #'control primitives' }
NewspeakInterpreter >> internalPrimitiveValue [
	<sharedCodeNamed: 'commonPrimitiveValue' inCase: #bytecodePrimValue>
	| newContext blockArgumentCount initialIP |
	self initPrimCall.
	newContext := self internalStackValue: argumentCount.
	self assertClassOf: newContext is: (self splObj: ClassBlockContext).
	blockArgumentCount := self argumentCountOfBlock: newContext.

	self success: (argumentCount = blockArgumentCount and: [(self fetchPointer: CallerIndex ofObject: newContext) = nilObj]).

	self successful
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

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> internalPush: object [

	self longAtPointer: (localSP := localSP + BytesPerWord) put: object.
]

{ #category : #processes }
NewspeakInterpreter >> internalQuickCheckForInterrupts [
	"Internal version of quickCheckForInterrupts for use within jumps."

	<inline: true>
	((interruptCheckCounter := interruptCheckCounter - 1) <= 0) ifTrue: [
		self externalizeIPandSP.
		self checkForInterrupts.

		self browserPluginReturnIfNeeded.

		self internalizeIPandSP].

]

{ #category : #'primitive support' }
NewspeakInterpreter >> internalQuickPrimitiveResponse [
	"Called under the assumption that primFunctionPtr has been preloaded"
	
	| localPrimIndex |
	self assert: self isPrimitiveFunctionPointerAnIndex.
	localPrimIndex := self cCoerceSimple: primitiveFunctionPointer to: #sqInt.
	self assert: (localPrimIndex > 255 and: [localPrimIndex < 520]).
	"Quick return inst vars"
	localPrimIndex >= 264 ifTrue:
		[self internalStackTopPut: (self fetchPointer: localPrimIndex - 264 ofObject: self internalStackTop).
		 ^true].
	"Quick return constants"
	localPrimIndex = 256 ifTrue: [^true "return self"].
	localPrimIndex = 257 ifTrue: [self internalStackTopPut: self trueObject. ^true].
	localPrimIndex = 258 ifTrue: [self internalStackTopPut: self falseObject. ^true].
	localPrimIndex = 259 ifTrue: [self internalStackTopPut: self nilObject. ^true].
	self internalStackTopPut: (self integerObjectOf: localPrimIndex - 261).
	^true
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> internalStackTop [

	^ self longAtPointer: localSP
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> internalStackTopPut: aValue [

	^self longAtPointer: localSP put: aValue
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> internalStackValue: offset [

	^ self longAtPointer: localSP - (offset * BytesPerWord)
]

{ #category : #contexts }
NewspeakInterpreter >> internalStoreContextRegisters: activeCntx [
	"The only difference between this method and fetchContextRegisters: is that this method stores from the local IP and SP."

	"InstructionPointer is a pointer variable equal to
	method oop + ip + BaseHeaderSize
		-1 for 0-based addressing of fetchByte
		-1 because it gets incremented BEFORE fetching currentByte"

	<inline: true>
	self storePointerUnchecked: InstructionPointerIndex ofObject: activeCntx
		withValue: (self integerObjectOf: 
			((self oopForPointer: localIP) + 2 - (method + BaseHeaderSize))).
	self storePointerUnchecked: StackPointerIndex		  ofObject: activeCntx
		withValue: (self integerObjectOf:
			((((self oopForPointer: localSP) - (activeCntx + BaseHeaderSize)) >> ShiftForWord) - TempFrameStart + 1)).

]

{ #category : #utilities }
NewspeakInterpreter >> internalizeIPandSP [
	"Copy the local instruction and stack pointer to local variables for rapid access within the interpret loop."

	localIP := self pointerForOop: instructionPointer.
	localSP := self pointerForOop: stackPointer.
	localHomeContext := theHomeContext.

]

{ #category : #'interpreter shell' }
NewspeakInterpreter >> interpret [
	"This is the main interpreter loop. It normally loops forever, fetching and executing
	 bytecodes.  When running in the context of a browser plugin VM, however, it must
	 return control to the browser periodically.  This should done only when the state of
	 the currently running Squeak thread is safely stored in the object heap.  Since this
	 is the case at the moment that a check for interrupts is performed, that is when we
	 return to the browser if it is time to do so.  Interrupt checks happen quite frequently."

	<inline: false> "should *not* be inlined into sendInvokeCallback:Stack:Registers:Jmpbuf:"
	"record entry time when running as a browser plug-in"
	self browserPluginInitialiseIfNeeded.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue: [self dispatchOn: currentBytecode in: BytecodeTable].
	localIP := localIP - 1.  "undo the pre-increment of IP before returning"
	self externalizeIPandSP.

]

{ #category : #processes }
NewspeakInterpreter >> interruptCheckForced [
	"was this interrupt check forced by outside code?"
	^interruptCheckCounter < -100
]

{ #category : #'plugin support' }
NewspeakInterpreter >> ioFilename: aCharBuffer fromString: aFilenameString ofLength: filenameLength resolveAliases: aBoolean [
"the vm has to convert aFilenameString via any canonicalization and char-mapping and put the result in aCharBuffer.
Note the resolveAliases flag - this is an awful artefact of OSX and Apples demented alias handling. When opening a file, the flag must be  true, when closing or renaming it must be false. Sigh."
	<var: #aCharBuffer type: #'char *'>
	<var: #aFilenameString type: #'char *'>
	self cCode:'sqGetFilenameFromString(aCharBuffer, aFilenameString, filenameLength, aBoolean)'
		inSmalltalk:["this doesn't translate well in Smalltalk since we know how long strings are rather than considering them terminated by a 0 char. Do the best we can"
			aCharBuffer replaceFrom:1 to: filenameLength with: aFilenameString]
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> is: oop KindOf: className [
	"Support for external primitives."
	| oopClass |
	<var: #className type:#'char *'>
	oopClass := self fetchClassOf: oop.
	[oopClass == nilObj] whileFalse:[
		(self classNameOf: oopClass Is: className) ifTrue:[^true].
		oopClass := self superclassOf: oopClass].
	^false
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> is: oop KindOfClass: aClass [
	"Support for external primitives."
	<api>
	| oopClass |
	oopClass := self fetchClassOf: oop.
	[oopClass = nilObj] whileFalse:
		[oopClass = aClass ifTrue: [^true].
		 oopClass := self superclassOf: oopClass].
	^false
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> is: oop MemberOf: className [
	"Support for external primitives"
	| oopClass |
	<var: #className type:#'char *'>
	oopClass := self fetchClassOf: oop.
	^(self classNameOf: oopClass Is: className)
]

{ #category : #'process primitive support' }
NewspeakInterpreter >> isEmptyList: aLinkedList [

	^ (self fetchPointer: FirstLinkIndex ofObject: aLinkedList) = nilObj
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> isFloatObject: oop [
	^(self isNonIntegerObject: oop)
	  and: [(self fetchClassOfNonImm: oop) = self classFloat]
]

{ #category : #'compiled methods' }
NewspeakInterpreter >> isHandlerMarked: aContext [
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

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> isMethodContext: oop [
	<inline: true>
	^(self isNonIntegerObject: oop) and: [self isMethodContextHeader: (self baseHeader: oop)]
]

{ #category : #'primitive support' }
NewspeakInterpreter >> isPrimitiveFunctionPointerAnIndex [
	"We save slots in the method cache by using the primitiveFunctionPointer
	 to hold either a function pointer or the index of a quick primitive. Since
	 quick primitive indices are small they can't be confused with function
	 addresses. "
	^(self cCoerce: primitiveFunctionPointer to: 'unsigned long') <= MaxQuickPrimitiveIndex
]

{ #category : #'compiled methods' }
NewspeakInterpreter >> isUnwindMarked: aContext [
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
NewspeakInterpreter >> jump: offset [

	localIP := localIP + offset + 1.
	currentBytecode := self byteAtPointer: localIP.

]

{ #category : #'jump bytecodes' }
NewspeakInterpreter >> jumplfFalseBy: offset [ 
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
NewspeakInterpreter >> jumplfTrueBy: offset [ 
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

{ #category : #'callback support' }
NewspeakInterpreter >> justActivateNewMethod [
	"Activate the new method but *do not* copy receiver or arguments from activeContext."
	| methodHeader initialIP newContext tempCount needsLarge where |
	<inline: true>

	methodHeader := self headerOf: newMethod.
	needsLarge := methodHeader bitAnd: LargeContextBit.
	(needsLarge = 0 and: [freeContexts ~= NilContext])
		ifTrue: [newContext := freeContexts.
				freeContexts := self fetchPointer: 0 ofObject: newContext]
		ifFalse: ["Slower call for large contexts or empty free list"
				newContext := self allocateOrRecycleContext: needsLarge].
	initialIP := ((LiteralStart + (self literalCountOfHeader: methodHeader)) * BytesPerWord) + 1.
	tempCount := (methodHeader >> 19) bitAnd: 16r3F.

	"Assume: newContext will be recorded as a root if necessary by the
	 call to newActiveContext: below, so we can use unchecked stores."
	where := newContext + BaseHeaderSize.
	self longAt: where + (SenderIndex << ShiftForWord) put: activeContext.
	self longAt: where + (InstructionPointerIndex << ShiftForWord) put: (self integerObjectOf: initialIP).
	self longAt: where + (StackPointerIndex << ShiftForWord) put: (self integerObjectOf: tempCount).
	self longAt: where + (MethodIndex << ShiftForWord) put: newMethod.

	"Set the receiver..."
	self longAt: where + (ReceiverIndex << ShiftForWord) put: receiver.

	"clear all args and temps to nil in case it has been recycled"
	needsLarge := nilObj.  "needsLarge here used just as faster (register?) temp"
	ReceiverIndex + 1 to: tempCount + ReceiverIndex do:
		[:i | self longAt: where + (i << ShiftForWord) put: needsLarge].
	reclaimableContextCount := reclaimableContextCount + 1.

	activeContext := newContext.
	(self oop: newContext isLessThan: youngStart) ifTrue:
		[self beRootIfOld: newContext].
	self fetchContextRegisters: activeContext
]

{ #category : #'debug printing' }
NewspeakInterpreter >> lengthOfNameOfClass: classOop [
	<inline: false>
	(self sizeBitsOf: classOop) = metaclassSizeBits ifTrue:
		[^self lengthOfNameOfClass: (self fetchPointer: thisClassIndex ofObject: classOop)].
	^self lengthOf: (self fetchPointer: classNameIndex ofObject: classOop)
]

{ #category : #'compiled methods' }
NewspeakInterpreter >> literal: offset [
	^self literal: offset ofMethod: method
]

{ #category : #'compiled methods' }
NewspeakInterpreter >> literal: offset ofMethod: methodPointer [

	^ self fetchPointer: offset + LiteralStart ofObject: methodPointer

]

{ #category : #'compiled methods' }
NewspeakInterpreter >> literalCountOf: methodPointer [
	^self literalCountOfHeader: (self headerOf: methodPointer)
]

{ #category : #'compiled methods' }
NewspeakInterpreter >> literalCountOfHeader: headerPointer [
	^ (headerPointer >> 10) bitAnd: 16rFF
]

{ #category : #'bitblt support' }
NewspeakInterpreter >> loadBitBltFrom: bb [
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
NewspeakInterpreter >> loadFloatOrIntFrom: floatOrInt [
	"If floatOrInt is an integer, then convert it to a C double float and return it.
	 If it is a Float, then load its value and return it.
	 Otherwise fail -- ie return with primErrorCode non-zero."

	<inline: true>
	<asmLabel: false>
	<returnTypeC: #double>

	(self isIntegerObject: floatOrInt) ifTrue:
		[^(self integerValueOf: floatOrInt) asFloat].
	^self floatValueOf: floatOrInt
]

{ #category : #initialization }
NewspeakInterpreter >> loadInitialContext [
	| sched proc |
	<inline: false>
	sched := self fetchPointer: ValueIndex ofObject: (self splObj: SchedulerAssociation).
	proc := self fetchPointer: ActiveProcessIndex ofObject: sched.
	activeContext := self fetchPointer: SuspendedContextIndex ofObject: proc.
	(activeContext < youngStart) ifTrue: [ self beRootIfOld: activeContext ].
	self fetchContextRegisters: activeContext.
	reclaimableContextCount := 0.
]

{ #category : #'jump bytecodes' }
NewspeakInterpreter >> longJumpIfFalse [

	self jumplfFalseBy: ((currentBytecode bitAnd: 3) * 256) + self fetchByte.
]

{ #category : #'jump bytecodes' }
NewspeakInterpreter >> longJumpIfTrue [

	self jumplfTrueBy: ((currentBytecode bitAnd: 3) * 256) + self fetchByte.
]

{ #category : #'jump bytecodes' }
NewspeakInterpreter >> longUnconditionalJump [

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
NewspeakInterpreter >> lookupInMethodCacheSel: selector class: class [
	"This method implements a simple method lookup cache. If an entry for the given selector and class is found in the cache, set the values of 'newMethod' and 'primitiveFunctionPointer' and return true. Otherwise, return false."
	"About the re-probe scheme: The hash is the low bits of the XOR of two large addresses, minus their useless lowest two bits. If a probe doesn't get a hit, the hash is shifted right one bit to compute the next probe, introducing a new randomish bit. The cache is probed CacheProbeMax times before giving up."
	"WARNING: Since the hash computation is based on the object addresses of the class and selector, we must rehash or flush when compacting storage. We've chosen to flush, since that also saves the trouble of updating the addresses of the objects in the cache."

	| hash probe |
	<inline: true>
	<asmLabel: false>
	hash := selector bitXor: class.  "shift drops two low-order zeros from addresses"

	probe := hash bitAnd: MethodCacheMask.  "first probe"
	(((methodCache at: probe + MethodCacheSelector) = selector) and:
		 [(methodCache at: probe + MethodCacheClass) = class]) ifTrue:
			[newMethod := methodCache at: probe + MethodCacheMethod.
			primitiveFunctionPointer := self cCoerceSimple: (methodCache at: probe + MethodCachePrimFunction)
											to: #'void (*)()'.
			^ true	"found entry in cache; done"].

	probe := (hash >> 1) bitAnd: MethodCacheMask.  "second probe"
	(((methodCache at: probe + MethodCacheSelector) = selector) and:
		 [(methodCache at: probe + MethodCacheClass) = class]) ifTrue:
			[newMethod := methodCache at: probe + MethodCacheMethod.
			primitiveFunctionPointer := self cCoerceSimple: (methodCache at: probe + MethodCachePrimFunction)
											to: #'void (*)()'.
			^ true	"found entry in cache; done"].

	probe := (hash >> 2) bitAnd: MethodCacheMask.
	(((methodCache at: probe + MethodCacheSelector) = selector) and:
		 [(methodCache at: probe + MethodCacheClass) = class]) ifTrue:
			[newMethod := methodCache at: probe + MethodCacheMethod.
			primitiveFunctionPointer := self cCoerceSimple: (methodCache at: probe + MethodCachePrimFunction)
											to: #'void (*)()'.
			^ true	"found entry in cache; done"].

	^ false
]

{ #category : #'message sending' }
NewspeakInterpreter >> lookupMethodInClass: class [
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
			self fastLogSend: messageSelector.
			self sendBreakpoint: messageSelector receiver: nil.
			^ self lookupMethodInClass: (self superclassOf: currentClass)].
		found := self lookupMethodInDictionary: dictionary.
		found ifTrue: [^currentClass].
		currentClass := self superclassOf: currentClass].

	"Could not find #doesNotUnderstand: -- unrecoverable error."
	messageSelector = (self splObj: SelectorDoesNotUnderstand) ifTrue:
		[self error: 'Recursive not understood error encountered'].

	"Cound not find a normal message -- raise exception #doesNotUnderstand:"
	self pushRemappableOop: class.  "may cause GC!"
	self createActualMessageTo: class.
	rclass := self popRemappableOop.
	messageSelector := self splObj: SelectorDoesNotUnderstand.
	RecordSendTrace ifTrue:
		[self fastLogSend: messageSelector].
	self sendBreak: messageSelector + BaseHeaderSize
		point: (self lengthOf: messageSelector)
		receiver: nil.
	^ self lookupMethodInClass: rclass
]

{ #category : #'message sending' }
NewspeakInterpreter >> lookupMethodInDictionary: dictionary [ 
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
	[true] whileTrue:
		[nextSelector := self fetchPointer: index ofObject: dictionary.
		nextSelector = nilObj ifTrue: [^ false].
		nextSelector = messageSelector ifTrue:
			[methodArray := self fetchPointer: MethodArrayIndex ofObject: dictionary.
			newMethod := self fetchPointer: index - SelectorStart ofObject: methodArray.
			^true].
		index := index + 1.
		index = length ifTrue:
			[wrapAround ifTrue: [^false].
			wrapAround := true.
			index := SelectorStart]]
]

{ #category : #'callback support' }
NewspeakInterpreter >> lookupMethodNoMNUEtcInClass: class [
	"Lookup messageSelector in class.  Answer 0 on success. Answer the splObj: index
	 for the error selector to use on failure rather than performing MNU processing etc."
	| currentClass dictionary |
	<inline: true>

	currentClass := class.
	[currentClass ~= nilObj] whileTrue:
		[dictionary := self fetchPointer: MessageDictionaryIndex ofObject: currentClass.
		 dictionary = nilObj ifTrue:
			[lkupClass := self superclassOf: currentClass.
			 ^SelectorCannotInterpret].
		(self lookupMethodInDictionary: dictionary) ifTrue:
			[self addNewMethodToCache.
			 ^0].
		currentClass := self superclassOf: currentClass].

	^SelectorDoesNotUnderstand
]

{ #category : #utilities }
NewspeakInterpreter >> makePointwithxValue: xValue yValue: yValue [
"make a Point xValue@yValue.
We know both will be integers so no value nor root checking is needed"
	| pointResult |
	pointResult := self instantiateSmallClass: (self splObj: ClassPoint) sizeInBytes: 3*BytesPerWord.
	self storePointerUnchecked: XIndex ofObject: pointResult withValue: (self integerObjectOf: xValue).
	self storePointerUnchecked: YIndex ofObject: pointResult withValue: (self integerObjectOf: yValue).
	^ pointResult
]

{ #category : #'object memory support' }
NewspeakInterpreter >> mapInterpreterOops [
	"Map all oops in the interpreter's state to their new values 
	during garbage collection or a become: operation."
	"Assume: All traced variables contain valid oops."
	stackPointer := stackPointer - activeContext. "*rel to active"
	activeContext := self remap: activeContext.
	stackPointer := stackPointer + activeContext. "*rel to active"
	theHomeContext := self remap: theHomeContext.
	instructionPointer := instructionPointer - method. "*rel to method"
	method := self remap: method.
	instructionPointer := instructionPointer + method. "*rel to method"
	receiver := self remap: receiver.
	(self isIntegerObject: messageSelector) ifFalse:
		[messageSelector := self remap: messageSelector].
	(self isIntegerObject: newMethod) ifFalse:
		[newMethod := self remap: newMethod].
	lkupClass := self remap: lkupClass.
	self mapTraceLogs
]

{ #category : #'debug support' }
NewspeakInterpreter >> mapTraceLogs [
	"The prim and send trace logs are circular buffers of selectors. If there is
	 an entry at primTraceLogIndex - 1 \\ PrimTraceBufferSize it has entries.
	 If there is something at primTraceLogIndex it has wrapped."
	<inline: false>
	| limit |
	limit := self safe: primTraceLogIndex - 1 mod: TraceLogSize.
	(primTraceLog at: limit) = 0 ifTrue: [^nil].
	(primTraceLog at: primTraceLogIndex) ~= 0 ifTrue:
		[limit := TraceLogSize - 1].
	0 to: limit do:
		[:i| | selector |
		selector := primTraceLog at: i.
		(self isIntegerObject: selector) ifFalse:
			[primTraceLog at: i put: (self remap: selector)]].
	limit := self safe: sendTraceLogIndex - 1 mod: TraceLogSize.
	(sendTraceLog at: limit) = 0 ifTrue: [^nil].
	(sendTraceLog at: sendTraceLogIndex) ~= 0 ifTrue:
		[limit := TraceLogSize - 1].
	0 to: limit do:
		[:i| | selector |
		selector := sendTraceLog at: i.
		(self isIntegerObject: selector) ifFalse:
			[sendTraceLog at: i put: (self remap: selector)]]
]

{ #category : #'object memory support' }
NewspeakInterpreter >> markAndTraceInterpreterOops [
	"Mark and trace all oops in the interpreter's state."
	"Assume: All traced variables contain valid oops."
	| oop |
	self markAndTrace: specialObjectsOop. "also covers nilObj, trueObj, falseObj, and compact classes"
	self markAndTrace: activeContext.
	self markAndTrace: messageSelector.
	self markAndTrace: newMethod.
	self markAndTrace: lkupClass.
	1 to: remapBufferCount do:
		[:i | 
		oop := remapBuffer at: i.
		(self isIntegerObject: oop) ifFalse: [self markAndTrace: oop]].
	self markAndTraceTraceLogs
]

{ #category : #'debug support' }
NewspeakInterpreter >> markAndTraceTraceLogs [
	"The prim and send trace logs are circular buffers of selectors. If there is
	 an entry at primTraceLogIndex - 1 \\ PrimTraceBufferSize it has entries.
	 If there is something at primTraceLogIndex it has wrapped."
	<inline: false>
	| limit |
	RecordPrimTrace ifTrue:
		[limit := self safe: primTraceLogIndex - 1 mod: TraceLogSize.
		(primTraceLog at: limit) ~= 0 ifTrue:
			[(primTraceLog at: primTraceLogIndex) ~= 0 ifTrue:
				[limit := TraceLogSize - 1].
			0 to: limit do:
				[:i| | selector |
				selector := primTraceLog at: i.
				(self isIntegerObject: selector) ifFalse:
					[self markAndTrace: selector]]]].
	RecordSendTrace ifTrue:
		[limit := self safe: sendTraceLogIndex - 1 mod: TraceLogSize.
		(sendTraceLog at: limit) ~= 0 ifTrue:
			[(sendTraceLog at: sendTraceLogIndex) ~= 0 ifTrue:
				[limit := TraceLogSize - 1].
			0 to: limit do:
				[:i| | selector |
				selector := sendTraceLog at: i.
				(self isIntegerObject: selector) ifFalse:
					[self markAndTrace: selector]]]]
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> methodArg: index [
	"Like #stackValue: but access method arguments left-to-right"
	index > argumentCount + 1 ifTrue:[
		self cCode: 'fprintf(stderr,"[VM]: Attempt to access method args beyond range\n")'.
		self printCallStack.
		self primitiveFail.
		^0].
	^self stackValue: argumentCount - index
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> methodArgumentCount [
	^argumentCount
]

{ #category : #'compiled methods' }
NewspeakInterpreter >> methodClassOf: methodPointer [
	| literal |
	literal := self literal: (self literalCountOf: methodPointer) - 1 ofMethod: methodPointer.
	^literal = nilObj
		ifTrue: [literal]
		ifFalse: [self fetchPointer: ValueIndex ofObject: literal]
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> methodPrimitiveIndex [
	<api>
	((self addressCouldBeObj: newMethod)
	 and: [self isCompiledMethod: newMethod]) ifFalse:
		[^-1].
	^self primitiveIndexOf: newMethod
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> methodReturnValue: oop [
	"Sets the return value for a method.  In the CoInterpreter we replace the cumbersome
	 primResult machinery."
	self pop: argumentCount+1 thenPush: oop.
	^0
]

{ #category : #initialization }
NewspeakInterpreter >> moduleUnloaded: aModuleName [ 
	"The module with the given name was just unloaded. 
	Make sure we have no dangling references."
	<export: true>
	<var: #aModuleName type: #'char *'>
	(aModuleName strcmp: 'SurfacePlugin') = 0
		ifTrue: ["Surface plugin went away. Should never happen. But  then, who knows"
			showSurfaceFn := 0]
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> nacFetchStackPointerOf: aContext [
	"A version of fetchStackPointerOf: for use when objects may be forwarded.
	 Does not do an assert-check of the stack pointer being in bounds."
	| sp |
	<inline: true>
	sp := self fetchPointer: StackPointerIndex ofObject: aContext.
	(self isIntegerObject: sp) ifFalse: [^0].
	^self integerValueOf: sp
]

{ #category : #'debug printing' }
NewspeakInterpreter >> nameOfClass: classOop [
	"Brain-damaged nameOfClass: for C VM.  Does *not* answer Foo class for metaclasses.
	 Use e.g. classIsMeta: to avoid being fooled."
	<inline: false>
	<returnTypeC: 'char *'>
	(self sizeBitsOf: classOop) = metaclassSizeBits ifTrue:
		[^self nameOfClass: (self fetchPointer: thisClassIndex ofObject: classOop)].
	^self firstFixedField: (self fetchPointer: classNameIndex ofObject: classOop)
]

{ #category : #contexts }
NewspeakInterpreter >> newActiveContext: aContext [
	"Note: internalNewActiveContext: should track changes to this method."

	self storeContextRegisters: activeContext.
	(aContext < youngStart) ifTrue: [ self beRootIfOld: aContext ].
	activeContext := aContext.
	self fetchContextRegisters: aContext.
]

{ #category : #'message sending' }
NewspeakInterpreter >> newspeakSuperclassSend [
"Send a message to self, starting lookup in the superclass of the method application of the currently executing method's mixin."
"Assume: messageSelector and argumentCount have been set, and that the receiver and arguments have been pushed onto the stack," 
"WE WANT THE RECEIVER PUSHED IMPLICITLY"
"Note: This method is inlined into the interpreter dispatch loop."
	| rcvr mClassMixin mixinApplication |
	<inline: true>
	rcvr := self internalStackValue: argumentCount.
	mClassMixin := self methodClassOf: method.
	mixinApplication := self 
		findApplicationOfTargetMixin: mClassMixin
		startingAtBehavior: (self fetchClassOf: rcvr).
	lkupClass := self superclassOf: mixinApplication.
	self commonSend
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> nextImplicitReceiverFor: anObject withMixin: mixin [
	"This is used to implement the innards of the pushImplicitReceiverBytecode,
	 used for implicit receiver sends in NS2/NS3.  Find the nearest lexically-enclosing
	 implementation of selector by searching up the static chain of anObject,
	 starting at mixin's application.  This is an iterative implementation derived from

	<ContextPart> nextImplicitReceiverFor: obj <Object>
				withMixin: mixin <Mixin>
				implementing: selector <Symbol> ^<Object>"
	| implicitReceiver mixinApplication theMixin targetMixin dictionary found |
	implicitReceiver := anObject.
	targetMixin := mixin.
	[(targetMixin == nilObj "or: [implicitReceiver == nilObj]") ifTrue:
		[^nilObj].
	mixinApplication := self
							findApplicationOfTargetMixin: targetMixin
							startingAtNonMetaClass: (self fetchClassOf: implicitReceiver).
	 mixinApplication == nilObj ifTrue:
		[^nilObj].
	 dictionary := self fetchPointer: MessageDictionaryIndex ofObject: mixinApplication.
	 found := self lookupMethodInDictionary: dictionary.
	 found]
		whileFalse:
			[implicitReceiver := self fetchPointer: EnclosingObjectIndex ofObject: mixinApplication.
			 theMixin := self fetchPointer: MixinIndex ofObject: mixinApplication.
			 theMixin == nilObj ifTrue:[^nilObj].
			 targetMixin := self fetchPointer: EnclosingMixinIndex ofObject: theMixin].
	^implicitReceiver
]

{ #category : #'message sending' }
NewspeakInterpreter >> normalSend [
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that 
	the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeNamed: 'normalSend' inCase: #singleExtendedSendBytecode>
	| rcvr |
	rcvr := self internalStackValue: argumentCount.
	lkupClass := self fetchClassOf: rcvr.
	self commonSend
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> objectArg: index [
	"Like #stackObjectValue: but access method arguments left-to-right"
	| oop |
	oop := self methodArg: index.
	oop = 0 ifTrue:[^0.0]. "methodArg: failed"
	(self isIntegerObject: oop) ifTrue: [self primitiveFail. ^ nil].
	^oop
]

{ #category : #'debug support' }
NewspeakInterpreter >> okayActiveProcessStack [

	| cntxt |
	cntxt := activeContext.	
	[cntxt = nilObj] whileFalse: [
		self okayFields: cntxt.
		cntxt := (self fetchPointer: SenderIndex ofObject: cntxt).
	].
]

{ #category : #'debug support' }
NewspeakInterpreter >> okayFields: oop [
	"Check if the argument is an ok object.
	 If this is a pointers object, check that its fields are all okay oops."

	| i fieldOop |
	(oop = nil or: [oop = 0]) ifTrue: [ ^true ].
	(self isIntegerObject: oop) ifTrue: [ ^true ].
	(self okayOop: oop) ifFalse: [ ^false ].
	(self oopHasOkayClass: oop) ifFalse: [ ^false ].
	((self isPointers: oop) or: [self isCompiledMethod: oop]) ifFalse: [ ^true ].
	(self isCompiledMethod: oop)
		ifTrue:
			[i := (self literalCountOf: oop) + LiteralStart - 1]
		ifFalse:
			[(self isContext: oop)
				ifTrue: [i := CtxtTempFrameStart + (self fetchStackPointerOf: oop) - 1]
				ifFalse: [i := (self lengthOf: oop) - 1]].
	[i >= 0] whileTrue: [
		fieldOop := self fetchPointer: i ofObject: oop.
		(self isIntegerObject: fieldOop) ifFalse: [
			(self okayOop: fieldOop) ifFalse: [ ^false ].
			(self oopHasOkayClass: fieldOop) ifFalse: [ ^false ].
		].
		i := i - 1.
	].
	^true
]

{ #category : #'debug support' }
NewspeakInterpreter >> okayInterpreterObjects [

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
NewspeakInterpreter >> oopHasOkayClass: signedOop [
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

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> pop2AndPushIntegerIfOK: integerResult [

	self successful ifTrue:
		[(self isIntegerValue: integerResult)
			ifTrue: [self pop: 2 thenPush: (self integerObjectOf: integerResult)]
			ifFalse: [self primitiveFail]]
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> pop: nItems [
	"Note: May be called by translated primitive code."

	stackPointer := stackPointer - (nItems*BytesPerWord).
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> pop: nItems thenPush: oop [

	| sp |
	self longAt: (sp := stackPointer - ((nItems - 1) * BytesPerWord)) put: oop.
	stackPointer := sp.

]

{ #category : #contexts }
NewspeakInterpreter >> pop: nItems thenPushBool: trueOrFalse [
	"A few places pop a few items off the stack and then push a boolean. Make it convenient"
	| sp |
	self longAt: (sp := stackPointer - ((nItems - 1) * BytesPerWord))
		put:(trueOrFalse ifTrue: [trueObj] ifFalse: [falseObj]).
	stackPointer := sp
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> pop: nItems thenPushInteger: integerVal [
"lots of places pop a few items off the stack and then push an integer. MAke it convenient"
	| sp |
	self longAt: (sp := stackPointer - ((nItems - 1) * BytesPerWord)) put:(self integerObjectOf: integerVal).
	stackPointer := sp.

]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> popFloat [
	<returnTypeC: #double>
	^self floatValueOf: self popStack
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> popInteger [
"returns 0 if the stackTop was not an integer value, plus sets successFlag false"
	| integerPointer |
	integerPointer := self popStack.
	^self checkedIntegerValueOf: integerPointer
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> popPos32BitInteger [
	"May set successFlag, and return false if not valid"

	| top |
	top := self popStack.
	^ self positive32BitValueOf: top
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> popStack [

	| top |
	top := self longAt: stackPointer.
	stackPointer := stackPointer - BytesPerWord.
	^ top
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> popStackBytecode [

	self fetchNextBytecode.
	self internalPop: 1.

]

{ #category : #'primitive support' }
NewspeakInterpreter >> positive32BitIntegerFor: integerValue [

	| newLargeInteger |
	"Note - integerValue is interpreted as POSITIVE, eg, as the result of
		Bitmap>at:, or integer>bitAnd:."
	integerValue >= 0
		ifTrue: [(self isIntegerValue: integerValue)
					ifTrue: [^ self integerObjectOf: integerValue]].

	BytesPerWord = 4
	ifTrue: ["Faster instantiateSmallClass: currently only works with integral word size."
			newLargeInteger := self instantiateSmallClass: (self splObj: ClassLargePositiveInteger)
					sizeInBytes: BaseHeaderSize + 4]
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
NewspeakInterpreter >> positive32BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive ST integer or a four-byte LargePositiveInteger."

	| sz value |
	(self isIntegerObject: oop) ifTrue: [
		value := self integerValueOf: oop.
		value < 0 ifTrue: [^ self primitiveFail].
		^ value].

	self assertClassOf: oop is: (self splObj: ClassLargePositiveInteger).
	self successful ifTrue: [
		sz := self lengthOf: oop.
		sz = 4 ifFalse: [^ self primitiveFail]].
	self successful ifTrue: [
		^ (self fetchByte: 0 ofObject: oop) +
		  ((self fetchByte: 1 ofObject: oop) <<  8) +
		  ((self fetchByte: 2 ofObject: oop) << 16) +
		  ((self fetchByte: 3 ofObject: oop) << 24) ].
]

{ #category : #'primitive support' }
NewspeakInterpreter >> positive64BitIntegerFor: integerValue [

	| newLargeInteger value check |
	"Note - integerValue is interpreted as POSITIVE, eg, as the result of
		Bitmap>at:, or integer>bitAnd:."
	<var: 'integerValue' type: 'sqLong'>
 
	(self sizeof: integerValue) = 4 ifTrue: [^self positive32BitIntegerFor: integerValue].

  	self cCode: 'check = integerValue >> 32'.  "Why not run this in sim?"
	check = 0 ifTrue: [^self positive32BitIntegerFor: integerValue].
	
	newLargeInteger :=
		self instantiateSmallClass: (self splObj: ClassLargePositiveInteger) sizeInBytes: BaseHeaderSize + 8.
	0 to: 7 do: [:i |
		self cCode: 'value = ( integerValue >> (i * 8)) & 255'.
		self storeByte: i ofObject: newLargeInteger withValue: value].
	^ newLargeInteger
]

{ #category : #'primitive support' }
NewspeakInterpreter >> positive64BitValueOf: oop [
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
	self successful ifFalse: [^ self primitiveFail].
	szsqLong := self cCode: 'sizeof(sqLong)'.
	sz := self lengthOf: oop.
	sz > szsqLong
		ifTrue: [^ self primitiveFail].
	value := 0.
	0 to: sz - 1 do: [:i |
		value := value + ((self cCoerce: (self fetchByte: i ofObject: oop) to: 'sqLong') <<  (i*8))].
	^value.
]

{ #category : #'primitive support' }
NewspeakInterpreter >> positiveMachineIntegerValueOf: oop [
	"Answer a value of an integer in address range, i.e up to the size of a machine word.
	The object may be either a positive SmallInteger or a LargePositiveInteger of size <= word size."
	<returnTypeC: #'unsigned long'>
	| value bs ok |
	(self isIntegerObject: oop) ifTrue:
		[value := self integerValueOf: oop.
		 value < 0 ifTrue: [^self primitiveFail].
		^value].

	ok := self
			isClassOfNonImm: oop
			equalTo: (self splObj: ClassLargePositiveInteger)
			compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	(ok and: [(bs := self lengthOf: oop) <= (self sizeof: #'unsigned long')]) ifFalse:
		[^self primitiveFail].

	((self sizeof: #'unsigned long') = 8
	and: [bs > 4]) ifTrue:
		[^  (self fetchByte: 0 ofObject: oop)
		 + ((self fetchByte: 1 ofObject: oop) <<  8)
		 + ((self fetchByte: 2 ofObject: oop) << 16)
		 + ((self fetchByte: 3 ofObject: oop) << 24)
		 + ((self fetchByte: 4 ofObject: oop) << 32)
		 + ((self fetchByte: 5 ofObject: oop) << 40)
		 + ((self fetchByte: 6 ofObject: oop) << 48)
		 + ((self fetchByte: 7 ofObject: oop) << 56)].

	^  (self fetchByte: 0 ofObject: oop)
	+ ((self fetchByte: 1 ofObject: oop) <<  8)
	+ ((self fetchByte: 2 ofObject: oop) << 16)
	+ ((self fetchByte: 3 ofObject: oop) << 24)
]

{ #category : #'object memory support' }
NewspeakInterpreter >> postGCAction: gcModeArg [
	"Mark the active and home contexts as roots if old. This 
	allows the interpreter to use storePointerUnchecked to 
	store into them."

	activeContext < youngStart ifTrue:
		[self beRootIfOld: activeContext].
	theHomeContext < youngStart ifTrue:
		[self beRootIfOld: theHomeContext].
	(self sizeOfFree: freeBlock) > shrinkThreshold ifTrue:
		["Attempt to shrink memory after successfully reclaiming lots of memory"
		 self shrinkObjectMemory: (self sizeOfFree: freeBlock) - growHeadroom].
	
	self signalSemaphoreWithIndex: gcSemaphoreIndex
]

{ #category : #'object memory support' }
NewspeakInterpreter >> preGCAction: fullGCFlag [

	self storeContextRegisters: activeContext
]

{ #category : #'debug support' }
NewspeakInterpreter >> primTraceLogIndex: aValue [
	<cmacro: '(aValue) (GIV(primTraceLogIndex) = (aValue))'>
	"N.B. primTraceLogIndex is 8-bits"
	^primTraceLogIndex := aValue bitAnd: 16rFF
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveAdd [

	self pop2AndPushIntegerIfOK: (self stackIntegerValue: 1) + (self stackIntegerValue: 0)
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveAdoptInstance [
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
		ifFalse: [self primitiveFailFor: err].
	^nil
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveArctan [

	| rcvr |
	<var: #rcvr type: 'double '>
	rcvr := self popFloat.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'atan(rcvr)' inSmalltalk: [rcvr arcTan])]
		ifFalse: [self unPop: 1]
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveArrayBecome [
	"We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors.  This version fails for immutables."

	| arg rcvr ec |
	arg := self stackTop.
	rcvr := self stackValue: 1.
	ec := self become: rcvr with: arg twoWay: true copyHash: true forceImmutables: false.
	ec = PrimNoErr
		ifTrue: [self pop: 1]
		ifFalse: [self primitiveFailFor: ec]
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveArrayBecomeForceImmutables [
	"We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors.  This version succeeds for immutables."

	| arg rcvr ec |
	arg := self stackTop.
	rcvr := self stackValue: 1.
	ec := self become: rcvr with: arg twoWay: true copyHash: true forceImmutables: true.
	ec = PrimNoErr
		ifTrue: [self pop: 1]
		ifFalse: [self primitiveFailFor: ec]
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveArrayBecomeOneWay [
	"We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors.  This version fails for immutables."

	| arg rcvr ec |
	arg := self stackTop.
	rcvr := self stackValue: 1.
	ec := self become: rcvr with: arg twoWay: false copyHash: true forceImmutables: false.
	ec = PrimNoErr
		ifTrue: [self pop: 1]
		ifFalse: [self primitiveFailFor: ec]
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveArrayBecomeOneWayCopyHash [
	"Similar to primitiveArrayBecomeOneWay but accepts a third
	 argument whether to copy the receiver's identity hash over
	 the argument's identity hash.  This version fails for immutables."

	| copyHash arg rcvr ec |
	copyHash := self booleanValueOf: (self stackTop).
	arg := self stackValue: 1.
	rcvr := self stackValue: 2.
	ec := self become: rcvr with: arg twoWay: false copyHash: copyHash forceImmutables: false.
	ec = PrimNoErr
		ifTrue: [self pop: 2]
		ifFalse: [self primitiveFailFor: ec]
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveArrayBecomeOneWayForceImmutables [
	"We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors.  This version succeeds for immutables."

	| arg rcvr ec |
	arg := self stackTop.
	rcvr := self stackValue: 1.
	ec := self become: rcvr with: arg twoWay: false copyHash: true forceImmutables: true.
	ec = PrimNoErr
		ifTrue: [self pop: 1]
		ifFalse: [self primitiveFailFor: ec]
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveAsFloat [
	| arg |
	arg := self popInteger.
	self successful
		ifTrue: [ self pushFloat: (self cCode: '((double) arg)' inSmalltalk: [arg asFloat]) ]
		ifFalse: [ self unPop: 1 ].
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveAsOop [
	| thisReceiver |
	thisReceiver := self stackTop.
	self success: (self isIntegerObject: thisReceiver) not.
	self successful
		ifTrue: [self pop:1 thenPushInteger: (self hashBitsOf: thisReceiver)]
]

{ #category : #'array and stream primitives' }
NewspeakInterpreter >> primitiveAt [

	self commonAt: false.
]

{ #category : #'array and stream primitives' }
NewspeakInterpreter >> primitiveAtEnd [
	| stream index limit |
	stream := self popStack.
	self success: ((self isPointers: stream)
					and: [(self lengthOf: stream) >= (StreamReadLimitIndex+1)]).
 	self successful ifTrue: [
		index := self fetchInteger: StreamIndexIndex ofObject: stream.
		limit := self fetchInteger: StreamReadLimitIndex ofObject: stream].
 	self successful
		ifTrue: [self pushBool: (index >= limit)]
		ifFalse: [self unPop: 1].
]

{ #category : #'array and stream primitives' }
NewspeakInterpreter >> primitiveAtPut [

	self commonAtPut: false.
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveBeCursor [
	"Set the cursor to the given shape. The Mac only supports 16x16 pixel cursors. Cursor offsets are handled by Smalltalk."

	| cursorObj maskBitsIndex maskObj bitsObj extentX extentY depth offsetObj offsetX offsetY cursorBitsIndex ourCursor |

	argumentCount = 0 ifTrue: [
		cursorObj := self stackTop.
		maskBitsIndex := nil].
	argumentCount = 1 ifTrue: [
		cursorObj := self stackValue: 1.
		maskObj := self stackTop].
	self success: (argumentCount < 2).

	self success: ((self isPointers: cursorObj) and: [(self lengthOf: cursorObj) >= 5]).
	self successful ifTrue: [
		bitsObj := self fetchPointer: 0 ofObject: cursorObj.
		extentX := self fetchInteger: 1 ofObject: cursorObj.
		extentY := self fetchInteger: 2 ofObject: cursorObj.
		depth := self fetchInteger: 3 ofObject: cursorObj.
		offsetObj := self fetchPointer: 4 ofObject: cursorObj].
		self success: ((self isPointers: offsetObj) and: [(self lengthOf: offsetObj) >= 2]).

	self successful ifTrue: [
		offsetX := self fetchInteger: 0 ofObject: offsetObj.
		offsetY := self fetchInteger: 1 ofObject: offsetObj.
		self success: ((extentX = 16) and: [extentY = 16 and: [depth = 1]]).
		self success: ((offsetX >= -16) and: [offsetX <= 0]).
		self success: ((offsetY >= -16) and: [offsetY <= 0]).
		self success: ((self isWords: bitsObj) and: [(self lengthOf: bitsObj) = 16]).
		cursorBitsIndex := bitsObj + BaseHeaderSize.
		self cCode: '' inSmalltalk:
			[ourCursor := Cursor
				extent: extentX @ extentY
				fromArray: ((1 to: 16) collect: [:i |
					((self fetchLong32: i-1 ofObject: bitsObj) >> (BytesPerWord*8 - 16)) bitAnd: 16rFFFF])
				offset: offsetX  @ offsetY]].

	argumentCount = 1 ifTrue: [
		self success: ((self isPointers: maskObj) and: [(self lengthOf: maskObj) >= 5]).
		self successful ifTrue: [
			bitsObj := self fetchPointer: 0 ofObject: maskObj.
			extentX := self fetchInteger: 1 ofObject: maskObj.
			extentY := self fetchInteger: 2 ofObject: maskObj.
			depth := self fetchInteger: 3 ofObject: maskObj].

		self successful ifTrue: [
			self success: ((extentX = 16) and: [extentY = 16 and: [depth = 1]]).
			self success: ((self isWords: bitsObj) and: [(self lengthOf: bitsObj) = 16]).
			maskBitsIndex := bitsObj + BaseHeaderSize]].

	self successful ifTrue: [
		argumentCount = 0
			ifTrue: [self cCode: 'ioSetCursor(cursorBitsIndex, offsetX, offsetY)'
						inSmalltalk: [ourCursor show]]
			ifFalse: [self cCode: 'ioSetCursorWithMask(cursorBitsIndex, maskBitsIndex, offsetX, offsetY)'
						inSmalltalk: [ourCursor show]].
		self pop: argumentCount].

]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveBeDisplay [
	"Record the system Display object in the specialObjectsTable."
	| rcvr |
	rcvr := self stackTop.
	self success: ((self isPointers: rcvr) and: [(self lengthOf: rcvr) >= 4]).
	self successful ifTrue: [self storePointer: TheDisplay ofObject: specialObjectsOop withValue: rcvr]
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveBeep [
"make the basic beep noise"
	self ioBeep.
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveBitAnd [
	| integerReceiver integerArgument |
	integerArgument := self popPos32BitInteger.
	integerReceiver := self popPos32BitInteger.
	self successful
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitAnd: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveBitOr [
	| integerReceiver integerArgument |
	integerArgument := self popPos32BitInteger.
	integerReceiver := self popPos32BitInteger.
	self successful
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitOr: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveBitShift [ 
	| integerReceiver integerArgument shifted |
	integerArgument := self popInteger.
	integerReceiver := self popPos32BitInteger.
	self successful ifTrue: [
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
	self successful
		ifTrue: [self push: (self positive32BitIntegerFor: shifted)]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveBitXor [
	| integerReceiver integerArgument |
	integerArgument := self popPos32BitInteger.
	integerReceiver := self popPos32BitInteger.
	self successful
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitXor: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'control primitives' }
NewspeakInterpreter >> primitiveBlockCopy [

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

	initialIP := self integerObjectOf: (instructionPointer+1+3) - (method+BaseHeaderSize).
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
NewspeakInterpreter >> primitiveByteArrayDoubleAt [
	"Return a double from the given byte offset in a ByteArray."
	| byteOffset rcvr addr floatValue |
	<export: true>
	<inline: false>
	<var: #floatValue type:'double '>
	byteOffset := self stackIntegerValue: 0.
	self failed ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackObjectValue: 1.
	self failed ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	addr := self addressOf: rcvr startingAt: byteOffset size: 8.
	self failed ifTrue:[^0].
	self cCode:'((int*)(&floatValue))[0] = ((int*)addr)[0]'.
	self cCode:'((int*)(&floatValue))[1] = ((int*)addr)[1]'.
	self pop: 2.
	^self pushFloat: floatValue

]

{ #category : #'array and stream primitive support' }
NewspeakInterpreter >> primitiveByteArrayDoubleAtPut [
	"Store a Double at given byte offset in a ByteArray."
	| byteOffset rcvr addr floatValue floatOop |
	<export: true>
	<inline: false>
	<var: #floatValue type:'double '>
	floatOop := self stackValue: 0.
	(self isIntegerObject: floatOop)
		ifTrue:[floatValue := self cCoerce: (self integerValueOf: floatOop) to:'double']
		ifFalse:[floatValue := self cCoerce: (self floatValueOf: floatOop) to:'double'].
	byteOffset := self stackIntegerValue: 1.
	self failed ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackObjectValue: 2.
	self failed ifTrue:[^self primitiveFailFor: PrimErrInappropriate].
	addr := self addressOf: rcvr startingAt: byteOffset size: 8.
	self failed ifTrue:[^0].
	(self isOopImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	self cCode:'((int*)addr)[0] = ((int*)(&floatValue))[0]'.
	self cCode:'((int*)addr)[1] = ((int*)(&floatValue))[1]'.
	self pop: 3.
	^self push: floatOop
]

{ #category : #'array and stream primitive support' }
NewspeakInterpreter >> primitiveByteArrayFloatAt [
	"Return a Float from the given byte offset in a ByteArray."
	| byteOffset rcvr addr floatValue |
	<export: true>
	<inline: false>
	<var: #floatValue type:'float '>
	byteOffset := self stackIntegerValue: 0.
	self failed ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackObjectValue: 1.
	self failed ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	addr := self addressOf: rcvr startingAt: byteOffset size: 4.
	self failed ifTrue:[^0].
	self cCode:'((int*)(&floatValue))[0] = ((int*)addr)[0]'.
	self pop: 2.
	^self pushFloat: floatValue
]

{ #category : #'array and stream primitive support' }
NewspeakInterpreter >> primitiveByteArrayFloatAtPut [
	"Store a Float at the given byteOffset in a ByteArray"
	| byteOffset rcvr addr floatValue floatOop |
	<export: true>
	<inline: false>
	<var: #floatValue type:'float '>
	floatOop := self stackValue: 0.
	(self isIntegerObject: floatOop)
		ifTrue:[floatValue := self cCoerce: (self integerValueOf: floatOop) to:'float']
		ifFalse:[floatValue := self cCoerce: (self floatValueOf: floatOop) to:'float'].
	byteOffset := self stackIntegerValue: 1.
	self failed ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackObjectValue: 2.
	self failed ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	addr := self addressOf: rcvr startingAt: byteOffset size: 4.
	self failed ifTrue:[^0].
	(self isOopImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	self cCode:'((int*)addr)[0] = ((int*)(&floatValue))[0]'.
	self pop: 3.
	^self push: floatOop
]

{ #category : #'array and stream primitive support' }
NewspeakInterpreter >> primitiveByteArrayNByteIIntegerAtPut [
	"Store a (signed or unsigned) n byte integer at the given byte offset."
	| isSigned byteSize byteOffset rcvr addr value max valueOop |
	<export: true>
	<inline: false>
	isSigned := self booleanValueOf: (self stackValue: 0).
	byteSize := self stackIntegerValue: 1.
	valueOop := self stackValue: 2.
	byteOffset := self stackIntegerValue: 3.
	self failed ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackObjectValue: 4.
	self failed ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	(byteOffset > 0 and:[byteSize = 1 or:[byteSize = 2 or:[byteSize = 4]]])
		ifFalse:[^self primitiveFailFor: PrimErrBadArgument].
	addr := self addressOf: rcvr startingAt: byteOffset size: byteSize.
	self failed ifTrue:[^0].
	isSigned 
		ifTrue:[value := self signed32BitValueOf: valueOop]
		ifFalse:[value := self positive32BitValueOf: valueOop].
	self failed ifTrue:[^0].
	byteSize < 4
		ifTrue:
			[isSigned ifTrue:[
				max := 1 << (8 * byteSize - 1).
				value >= max ifTrue:[^self primitiveFail].
				value < (0 - max) ifTrue:[^self primitiveFail].
			] ifFalse:[
				value >= (1 << (8*byteSize)) ifTrue:[^self primitiveFail].
			].
			(self isOopImmutable: rcvr) ifTrue:
				[^self primitiveFailFor: PrimErrNoModification].
			"short/byte"
			byteSize = 1 
				ifTrue:[self byteAt: addr put: value]
				ifFalse:[	self cCode: '*((short int *) addr) = value' 
							inSmalltalk: [self shortAt: addr put: value]]]
		ifFalse:
			[(self isOopImmutable: rcvr) ifTrue:
				[^self primitiveFailFor: PrimErrNoModification].
			self longAt: addr put: value].
	self pop: 5.
	^self push: valueOop.
]

{ #category : #'array and stream primitive support' }
NewspeakInterpreter >> primitiveByteArrayNByteIntegerAt [
	"Return a (signed or unsigned) n byte integer from the given byte offset."
	| isSigned byteSize byteOffset rcvr addr value mask |
	<export: true>
	<inline: false>
	isSigned := self booleanValueOf: (self stackValue: 0).
	byteSize := self stackIntegerValue: 1.
	byteOffset := self stackIntegerValue: 2.
	self failed ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackObjectValue: 3.
	self failed ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	(byteOffset > 0 and:[byteSize = 1 or:[byteSize = 2 or:[byteSize = 4]]])
		ifFalse:[^self primitiveFailFor: PrimErrBadArgument].
	addr := self addressOf: rcvr startingAt: byteOffset size: byteSize.
	self failed ifTrue:[^0].
	byteSize < 4 ifTrue:[
		"short/byte"
		byteSize = 1 
			ifTrue:[value := self byteAt: addr]
			ifFalse:[value := self cCode: '*((unsigned short int *) addr)' 
								inSmalltalk: [self shortAt: addr]].
		isSigned ifTrue:["sign extend value"
			mask := 1 << (byteSize * 8 - 1).
			value := (value bitAnd: mask-1) - (value bitAnd: mask)].
		"note: byte/short never exceed SmallInteger range"
		value := self integerObjectOf: value.
	] ifFalse:[
		"general 32 bit integer"
		value := self longAt: addr.
		isSigned
			ifTrue:[value := self signed32BitIntegerFor: value]
			ifFalse:[value := self positive32BitIntegerFor: value].
	].
	self pop: 4.
	^self push: value

]

{ #category : #'memory space primitives' }
NewspeakInterpreter >> primitiveBytesLeft [
	"Reports bytes available at this moment. For more meaningful 
	results, calls to this primitive should be preceeded by a full 
	or incremental garbage collection."
	| aBool |
	self methodArgumentCount = 0
		ifTrue: ["old behavior - just return the size of the free block"
			^self pop: 1 thenPushInteger: (self sizeOfFree: freeBlock)].
	self methodArgumentCount = 1
		ifTrue: ["new behaviour -including or excluding swap space depending on aBool"
			aBool := self booleanValueOf: self stackTop.
			self successful ifFalse: [^ nil].
			^self pop: 2 thenPushInteger: (self bytesLeft: aBool)].
	^ self primitiveFail
]

{ #category : #'message sending' }
NewspeakInterpreter >> primitiveCalloutToFFI [
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
NewspeakInterpreter >> primitiveChangeClass [
	"Primitive.  Change the class of the receiver into the class of the argument given that
	 the format of the receiver matches the format of the argument's class.  Fail if the
	 receiver or argument are SmallIntegers, or the receiver is an instance of a compact
	 class and the argument isn't, or when the argument's class is compact and the receiver
	 isn't, or when the format of the receiver is different from the format of the argument's
	 class, or when the arguments class is fixed and the receiver's size differs from the size
	 that an instance of the argument's class should have."
	| arg rcvr argClass err |
	arg := self stackObjectValue: 0.
	rcvr := self stackObjectValue: 1.
	self successful ifFalse:[^nil].
	argClass := self fetchClassOfNonImm: arg.
	err := self changeClassOf: rcvr to: argClass.
	err = 0
		ifTrue: ["Flush at cache because rcvr's class has changed."
				self flushAtCache.
				self pop: self methodArgumentCount]
		ifFalse: [self primitiveFailFor: err].
	^nil
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveClass [
	| instance |
	instance := self stackTop.
	self pop: argumentCount+1 thenPush: (self fetchClassOf: instance)
]

{ #category : #'process primitives' }
NewspeakInterpreter >> primitiveClearVMProfile [
	"Primitive. Void the VM profile histograms."
	self cCode: 'ioClearProfile()'.
	self pop: argumentCount
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveClipboardText [
	"When called with a single string argument, post the string to 
	the clipboard. When called with zero arguments, return a 
	string containing the current clipboard contents."
	| s sz |
	argumentCount = 1
		ifTrue: [s := self stackTop.
			(self isBytes: s) ifFalse: [^ self primitiveFail].
			self successful
				ifTrue: [sz := self stSizeOf: s.
					self clipboardWrite: sz From: s + BaseHeaderSize At: 0.
					self pop: 1]]
		ifFalse: [sz := self clipboardSize.
			(self sufficientSpaceToAllocate: sz) ifFalse:[^self primitiveFail].
			s := self instantiateClass: (self splObj: ClassByteString) indexableSize: sz.
			self clipboardRead: sz Into: s + BaseHeaderSize At: 0.
			self pop: 1 thenPush: s]
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveClone [
	"Return a shallow copy of the receiver."

	| newCopy |
	newCopy := self clone: (self stackTop).
	newCopy = 0
		ifTrue:["not enough memory most likely" ^self primitiveFail].
	self pop: 1 thenPush: newCopy.
]

{ #category : #'control primitives' }
NewspeakInterpreter >> primitiveClosureCopyWithCopiedValues [
	| newClosure copiedValues numCopiedValues numArgs |
	numArgs := self stackIntegerValue: 1.
	copiedValues := self stackTop.
	(self fetchClassOf: copiedValues) = (self splObj: ClassArray) ifFalse:
		[^self primitiveFail].
	numCopiedValues := self fetchWordLengthOf: copiedValues.
	newClosure := self
					closureNumArgs: numArgs
									"greater by 1 due to preIncrement of localIP"
					instructionPointer: instructionPointer + 2 - (method+BaseHeaderSize)
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
NewspeakInterpreter >> primitiveClosureValue [
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
	((self isNonIntegerObject: closureMethod) and: [self isCompiledMethod: closureMethod]) ifFalse:
		[^self primitiveFail].

	self activateNewClosureMethod: blockClosure.
	self quickCheckForInterrupts
]

{ #category : #'control primitives' }
NewspeakInterpreter >> primitiveClosureValueNoContextSwitch [
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
	((self isNonIntegerObject: closureMethod) and: [self isCompiledMethod: closureMethod]) ifFalse:
		[^self primitiveFail].

	self activateNewClosureMethod: blockClosure
]

{ #category : #'control primitives' }
NewspeakInterpreter >> primitiveClosureValueWithArgs [
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
	((self isNonIntegerObject: closureMethod) and: [self isCompiledMethod: closureMethod]) ifFalse:
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

{ #category : #'sound primitives' }
NewspeakInterpreter >> primitiveConstantFill [
	"Fill the receiver, which must be an indexable bytes or words 
	objects, with the given integer value."
	| fillValue rcvr rcvrIsBytes end i |
	fillValue := self positive32BitValueOf: self stackTop.
	rcvr := self stackValue: 1.
	self success: (self isWordsOrBytes: rcvr).
	rcvrIsBytes := self isBytes: rcvr.
	rcvrIsBytes ifTrue: [self success: (fillValue >= 0 and: [fillValue <= 255])].
	self successful
		ifTrue: [end := rcvr + (self sizeBitsOf: rcvr).
			i := rcvr + BaseHeaderSize.
			rcvrIsBytes
				ifTrue: [[i < end]
						whileTrue: [self byteAt: i put: fillValue.
							i := i + 1]]
				ifFalse: [[i < end]
						whileTrue: [self long32At: i put: fillValue.
							i := i + 4]].
			self pop: 1]
]

{ #category : #'process primitives' }
NewspeakInterpreter >> primitiveControlVMProfiling [
	"Primitive. Start or stop the VM profiler.  The first argument is a boolean
	 to switch profiling on or off.  The second argument is an integer or nil.
	 If an integer it determines the maximum number of samples in the VM's
	 sample buffer. Answer the current number of samples in the buffer."
	| onOffBar bufferSize numSamples |
	argumentCount ~= 2 ifTrue:
		[^self primitiveFail].
	(onOffBar := self stackValue: 1) = self trueObject
		ifTrue: [onOffBar := 1]
		ifFalse:
			[onOffBar = self falseObject
				ifTrue: [onOffBar := 0]
				ifFalse: [^self primitiveFail]].
	(bufferSize := self stackTop) = self nilObject
		ifTrue: [bufferSize := 0]
		ifFalse:
			[((self isIntegerObject: bufferSize)
			  and: [(bufferSize := self integerValueOf: bufferSize) > 0]) ifFalse:
				[^self primitiveFail]].
	numSamples := self cCode: 'ioControlNewProfile(onOffBar,bufferSize)'.
	self pop: 3 thenPushInteger: numSamples
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveCopyObject [
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
NewspeakInterpreter >> primitiveDeferDisplayUpdates [
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
	self successful
		ifTrue: [self pop: 1]
]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveDisablePowerManager [
	"Pass in a non-negative value to disable the architectures powermanager if any, zero to enable. This is a named (not numbered) primitive in the null module (ie the VM)"

	| integer |
	<export: true>
	integer := self stackIntegerValue: 0.
	self successful ifTrue: [
		self ioDisablePowerManager: integer.
		self pop: 1].  "integer; leave rcvr on stack"

]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveDiv [
	| quotient |
	quotient := self doPrimitiveDiv: (self stackValue: 1) by: (self stackTop).
	self pop2AndPushIntegerIfOK: quotient
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveDivide [
	| integerReceiver integerArgument |
	integerReceiver := self stackIntegerValue: 1.
	integerArgument := self stackIntegerValue: 0.
	(integerArgument ~= 0 and: [integerReceiver \\ integerArgument = 0])
		ifTrue: [self pop2AndPushIntegerIfOK: integerReceiver // integerArgument]
		ifFalse: [self primitiveFail]
]

{ #category : #'plugin primitives' }
NewspeakInterpreter >> primitiveDoNamedPrimitiveWithArgs [
	"Simulate an primitiveExternalCall invocation (e.g. for the Debugger).  Do not cache anything.
	 e.g. ContextPart>>tryNamedPrimitiveIn: aCompiledMethod for: aReceiver withArgs: arguments"
	| argumentArray arraySize index methodArg methodHeader spec
	  moduleName functionName moduleLength functionLength addr |
	<var: #addr declareC: 'void (*addr)()'>

	argumentArray := self stackTop.
	(self isArray: argumentArray) ifFalse:
		[^self primitiveFail]. "invalid args"
	arraySize := self fetchWordLengthOf: argumentArray.
	self success: (self roomToPushNArgs: arraySize).

	methodArg := self stackObjectValue: 2.
	self successful ifFalse:
		[^self primitiveFail]. "invalid args"

	(self isCompiledMethod: methodArg) ifFalse:
		[^self primitiveFail]. "invalid args"

	methodHeader := self headerOf: methodArg.

	(self literalCountOfHeader: methodHeader) > 2 ifFalse:
		[^self primitiveFail]. "invalid methodArg state"
	self assertClassOf: (spec := self fetchPointer: 1 "first literal" ofObject: methodArg)
		is: (self splObj: ClassArray).
	(self successful
	and: [(self lengthOf: spec) = 4
	and: [(self primitiveIndexOfMethodHeader: methodHeader) = 117]]) ifFalse:
		[^self primitiveFail]. "invalid methodArg state"

	(self argumentCountOfMethodHeader: methodHeader) = arraySize ifFalse:
		[^self primitiveFail]. "invalid args (Array args wrong size)"

	"The function has not been loaded yet. Fetch module and function name."
	moduleName := self fetchPointer: 0 ofObject: spec.
	moduleName = nilObj
		ifTrue: [moduleLength := 0]
		ifFalse: [self success: (self isBytes: moduleName).
				moduleLength := self lengthOf: moduleName.
				self cCode: '' inSmalltalk:
					[ (#('FloatArrayPlugin' 'Matrix2x3Plugin') includes: (self stringOf: moduleName)) "??"
						ifTrue: [moduleLength := 0  "Cause all of these to fail"]]].
	functionName := self fetchPointer: 1 ofObject: spec.
	self success: (self isBytes: functionName).
	functionLength := self lengthOf: functionName.
	self successful ifFalse: [^self primitiveFail]. "invalid methodArg state"

	addr := self ioLoadExternalFunction: functionName + BaseHeaderSize
				OfLength: functionLength
				FromModule: moduleName + BaseHeaderSize
				OfLength: moduleLength.
	addr = 0 ifTrue:
		[^self primitiveFail]. "could not find function"

	"Cannot fail this primitive from now on.  Can only fail the external primitive."
	self pop: 1.
	argumentCount := arraySize.
	index := 1.
	[index <= arraySize] whileTrue:
		[self push: (self fetchPointer: index - 1 ofObject: argumentArray).
		 index := index + 1].

	"Run the primitive (sets primFailCode)"
	self pushRemappableOop: argumentArray. "prim might alloc/gc in callback"
	lkupClass := nilObj.
	self callExternalPrimitive: addr.
	argumentArray := self popRemappableOop.
	self successful ifFalse: "If primitive failed, then restore state for failure code"
		[self pop: arraySize thenPush: argumentArray.
		 argumentCount := 3]
]

{ #category : #'control primitives' }
NewspeakInterpreter >> primitiveDoPrimitiveWithArgs [
	| argumentArray arraySize index cntxSize primIdx |
	argumentArray := self stackTop.
	arraySize := self fetchWordLengthOf: argumentArray.
	cntxSize := self fetchWordLengthOf: activeContext.
	self success: self stackPointerIndex + arraySize < cntxSize.
	(self isArray: argumentArray) ifFalse: [^ self primitiveFail].

	primIdx := self stackIntegerValue: 1.
	self successful ifFalse: [^ self primitiveFail]. "invalid args"

	primitiveFunctionPointer := self functionPointerFor: primIdx inClass: nil.
	primitiveFunctionPointer = 0 ifTrue:
		[^self primitiveFail].

	"Pop primIndex and argArray, then push args in place..."
	self pop: 2.
	argumentCount := arraySize.
	index := 1.
	[index <= argumentCount] whileTrue:
		[self push: (self fetchPointer: index - 1 ofObject: argumentArray).
		 index := index + 1].

	self isPrimitiveFunctionPointerAnIndex ifTrue:
		[self externalQuickPrimitiveResponse.
		^nil].

	"Run the primitive (sets successFlag)"
	self pushRemappableOop: argumentArray. "prim might alloc/gc"
	lkupClass := nilObj.
	"Run the primitive (sets primFailCode)"
	self slowPrimitiveResponse.
	argumentArray := self popRemappableOop.
	self successful ifFalse:
		["If primitive failed, then restore state for failure code"
		self pop: arraySize.
		self pushInteger: primIdx.
		self push: argumentArray.
		argumentCount := 2]
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveEqual [
	| integerReceiver integerArgument result |
	integerArgument := self popStack.
	integerReceiver := self popStack.
	result := self compare31or32Bits: integerReceiver equal: integerArgument.
	self checkBooleanResult: result
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveEquivalent [
"is the receiver the same object as the argument?"
	| thisObject otherObject |
	otherObject := self popStack.
	thisObject := self popStack.
	self pushBool: thisObject = otherObject
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveEventProcessingControl [
	"With 0 args answers whether ioProcessEvents is enabled and being called.
	 With 1 arg expects a boolean which will enable ioProcessEvents if true and
	 disable it if false, answering its previous state."
	<export: true>
	| enabled |
	enabled := inIOProcessEvents >= 0.
	argumentCount = 0 ifTrue:
		[^self pop: 1 thenPushBool: enabled].
	argumentCount = 1 ifTrue:
		[self stackTop = trueObj
			ifTrue: [inIOProcessEvents < 0 ifTrue:
					[inIOProcessEvents := 0]]
			ifFalse:
				[self stackTop = falseObj
					ifTrue: [inIOProcessEvents := -1]
					ifFalse: [^self primitiveFailFor: PrimErrBadArgument]].
		 ^self pop: 2 thenPushBool: enabled].
	self primitiveFailFor: PrimErrBadNumArgs
]

{ #category : #'control primitives' }
NewspeakInterpreter >> primitiveExecuteMethod [
	"receiver, args, then method are on top of stack. Execute method against receiver and args.
	 Set primitiveFunctionPointer because no cache lookup has been done for the method, and
	 hence primitiveFunctionPointer is stale."
	| methodArgument primitiveIndex |
	methodArgument := self stackTop.
	(self isOopCompiledMethod: methodArgument) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	argumentCount - 1 = (self argumentCountOf: methodArgument) ifFalse:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	newMethod := self popStack.
	primitiveIndex := self primitiveIndexOf: newMethod.
	primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: nil.
	argumentCount := argumentCount - 1.
	"We set the messageSelector for executeMethod below since things
	 like the at cache read messageSelector and so it cannot be left stale."
	messageSelector := self nilObject.
	self executeNewMethod.
	"Recursive xeq affects primErrorCode"
	self initPrimCall
]

{ #category : #'control primitives' }
NewspeakInterpreter >> primitiveExecuteMethodArgsArray [
	"receiver, argsArray, then method are on top of stack.  Execute method against
	 receiver and args.  Allow for up to two extra arguments (e.g. for mirror primitives).
	 Set primitiveFunctionPointer because no cache lookup has been done for the
	 method, and hence primitiveFunctionPointer is stale."
	| methodArgument argCnt argumentArray primitiveIndex |
	methodArgument := self stackTop.
	argumentArray := self stackValue: 1.
	((self isOopCompiledMethod: methodArgument)
	 and: [self isArray: argumentArray]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	argCnt := self argumentCountOf: methodArgument.
	argCnt = (self fetchWordLengthOf: argumentArray) ifFalse:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	argumentCount > 2 ifTrue: "CompiledMethod class>>receiver:withArguments:executeMethod:
								SqueakObjectPrimitives class >> receiver:withArguments:apply:
								VMMirror>>ifFail:object:with:executeMethod: et al"
		[argumentCount > 4 ifTrue:
			[^self primitiveFailFor: PrimErrUnsupported].
		self stackValue: argumentCount put: (self stackValue: 2)]. "replace actual receiver with desired receiver"
	"and push the actual arguments"
	self pop: argumentCount.
	0 to: argCnt - 1 do:
		[:i|
		self push: (self fetchPointer: i ofObject: argumentArray)].
	newMethod := methodArgument.
	primitiveIndex := self primitiveIndexOf: newMethod.
	primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: nil.
	argumentCount := argCnt.
	"We set the messageSelector for executeMethod below since things
	 like the at cache read messageSelector and so it cannot be left stale."
	messageSelector := self nilObject.
	self executeNewMethod.
	"Recursive xeq affects primErrorCode"
	self initPrimCall
]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveExitToDebugger [

	self error: 'Exit to debugger at user request'.
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveExp [
	"Computes E raised to the receiver power."

	| rcvr |
	<var: #rcvr type: 'double '>
	rcvr := self popFloat.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'exp(rcvr)' inSmalltalk: [rcvr exp])]
		ifFalse: [self unPop: 1]
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveExponent [
	"Exponent part of this float."

	| rcvr frac pwr |
	<var: #rcvr type: 'double '>
	<var: #frac type: 'double '>
	<var: #pwr type: 'int '>
	rcvr := self popFloat.
	self successful
		ifTrue: [  "rcvr = frac * 2^pwr, where frac is in [0.5..1.0)"
			self cCode: 'frac = frexp(rcvr, &pwr)'
					inSmalltalk: [pwr := rcvr exponent].
			self pushInteger: pwr - 1]
		ifFalse: [self unPop: 1].
]

{ #category : #'plugin primitives' }
NewspeakInterpreter >> primitiveExternalCall [
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
	self successful ifFalse: [^ nil].

	lit := self literal: 0 ofMethod: newMethod. 
	"Check if it's an array of length 4"
	self success: ((self isArray: lit) and: [(self lengthOf: lit) = 4]).
	self successful ifFalse: [^ nil].

	"Look at the function index in case it has been loaded before"
	index := self fetchPointer: 3 ofObject: lit.
	index := self checkedIntegerValueOf: index.
	self successful ifFalse: [^ nil].
	"Check if we have already looked up the function and failed."
	index < 0 ifTrue:
		["Function address was not found in this session, 
		  Rewrite the mcache entry with a zero primitive index."
		 self
			rewriteMethodCacheSel: messageSelector
			class: lkupClass
			primIndex: 0.
		^self success: false].

	"Try to call the function directly"
	(index > 0 and: [index <= MaxExternalPrimitiveTableSize]) ifTrue:
		[addr := externalPrimitiveTable at: index - 1.
		 addr ~= 0 ifTrue:
			[self rewriteMethodCacheSel: messageSelector class: lkupClass primIndex: (1000 + index) primFunction: addr.
			 self callExternalPrimitive: addr.
			 ^nil].
		"if we get here, then an index to the external prim was 
		kept on the ST side although the underlying prim 
		table was already flushed"
		^self primitiveFail].

	"Clean up session id and external primitive index"
	self storePointerUnchecked: 2 ofObject: lit withValue: ConstZero.
	self storePointerUnchecked: 3 ofObject: lit withValue: ConstZero.

	"The function has not been loaded yet. Fetch module and function name."
	moduleName := self fetchPointer: 0 ofObject: lit.
	moduleName = nilObj
		ifTrue: [moduleLength := 0]
		ifFalse: [self success: (self isBytes: moduleName).
				moduleLength := self lengthOf: moduleName].
	functionName := self fetchPointer: 1 ofObject: lit.
	self success: (self isBytes: functionName).
	functionLength := self lengthOf: functionName.
	self successful ifFalse: [^ nil].

	addr := self ioLoadExternalFunction: functionName + BaseHeaderSize
				OfLength: functionLength
				FromModule: moduleName + BaseHeaderSize
				OfLength: moduleLength.
	addr = 0
		ifTrue: [index := -1]
		ifFalse: ["add the function to the external primitive table"
			index := self addToExternalPrimitiveTable: addr].
	self success: index >= 0.
	"Store the index (or -1 if failure) back in the literal"
	self storePointerUnchecked: 3 ofObject: lit withValue: (self integerObjectOf: index).

	"If the function has been successfully loaded process it"
	(self successful and: [addr ~= 0])
		ifTrue:
			[self rewriteMethodCacheSel: messageSelector class: lkupClass primIndex: (1000 + index) primFunction: addr.
			 self callExternalPrimitive: addr]
		ifFalse: "Otherwise rewrite the primitive index"
			[self
				rewriteMethodCacheSel: messageSelector
				class: lkupClass
				primIndex: 0]
]

{ #category : #'primitive support' }
NewspeakInterpreter >> primitiveFail [
	"Set general (unspecified) primitive failure."
	primFailCode := 1
]

{ #category : #'image segment in/out' }
NewspeakInterpreter >> primitiveFailAfterCleanup: outPointerArray [
	"If the storeSegment primitive fails, it must clean up first."

	| i lastAddr |   "Store nils throughout the outPointer array."
	lastAddr := outPointerArray + (self lastPointerOf: outPointerArray).
	i := outPointerArray + BaseHeaderSize.
	[i <= lastAddr] whileTrue:
		[self longAt: i put: nilObj.
		i := i + BytesPerWord].

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	self primitiveFail
]

{ #category : #'primitive support' }
NewspeakInterpreter >> primitiveFailFor: reasonCode [
	"Set specific primitive failure."
	primFailCode := reasonCode
]

{ #category : #'primitive support' }
NewspeakInterpreter >> primitiveFailureCode [
	<api>
	^primFailCode
]

{ #category : #'process primitives' }
NewspeakInterpreter >> primitiveFindHandlerContext [
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
NewspeakInterpreter >> primitiveFindNextUnwindContext [
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

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveFloatAdd [
	^ self primitiveFloatAdd: (self stackValue: 1) toArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
NewspeakInterpreter >> primitiveFloatAdd: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	<var: #arg type: 'double '>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	self successful ifTrue: [
		self pop: 2.
		self pushFloat: rcvr + arg].
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveFloatDivide [
	^ self primitiveFloatDivide: (self stackValue: 1) byArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
NewspeakInterpreter >> primitiveFloatDivide: rcvrOop byArg: argOop [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	<var: #arg type: 'double '>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	self successful ifTrue: [
		self success: arg ~= 0.0.
		self successful ifTrue: [
			self pop: 2.
			self pushFloat: (self cCode: 'rcvr / arg' inSmalltalk: [rcvr / arg])]].
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveFloatEqual [
	| aBool |
	aBool := self primitiveFloatEqual: (self stackValue: 1) toArg: self stackTop.
	self successful ifTrue: [self pop: 2. self pushBool: aBool].

]

{ #category : #'comparison float primitives' }
NewspeakInterpreter >> primitiveFloatEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	^rcvr = arg
]

{ #category : #'comparison float primitives' }
NewspeakInterpreter >> primitiveFloatGreater: rcvrOop thanArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	^rcvr > arg
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveFloatGreaterOrEqual [
	| aBool |
	aBool := self primitiveFloatGreaterOrEqual: (self stackValue: 1) toArg: self stackTop.
	self successful ifTrue: [self pop: 2 thenPushBool: aBool]
]

{ #category : #'comparison float primitives' }
NewspeakInterpreter >> primitiveFloatGreaterOrEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	^rcvr >= arg
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveFloatGreaterThan [
	| aBool |
	aBool := self primitiveFloatGreater: (self stackValue: 1) thanArg: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: aBool]
]

{ #category : #'comparison float primitives' }
NewspeakInterpreter >> primitiveFloatLess: rcvrOop thanArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	^rcvr < arg
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveFloatLessOrEqual [
	| aBool |
	aBool := self primitiveFloatLessOrEqual: (self stackValue: 1) toArg: self stackTop.
	self successful ifTrue: [self pop: 2 thenPushBool: aBool]
]

{ #category : #'comparison float primitives' }
NewspeakInterpreter >> primitiveFloatLessOrEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	^rcvr <= arg
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveFloatLessThan [
	| aBool |
	aBool := self primitiveFloatLess: (self stackValue: 1) thanArg: self stackTop.
	self successful ifTrue: [self pop: 2. self pushBool: aBool].

]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveFloatMultiply [
	^ self primitiveFloatMultiply: (self stackValue: 1) byArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
NewspeakInterpreter >> primitiveFloatMultiply: rcvrOop byArg: argOop [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	<var: #arg type: 'double '>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	self successful ifTrue: [
		self pop: 2.
		self pushFloat: rcvr * arg].
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveFloatNotEqual [
	| aBool |
	aBool := self primitiveFloatEqual: (self stackValue: 1) toArg: self stackTop.
	self successful ifTrue: [self pop: 2. self pushBool: aBool not].

]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveFloatSubtract [
	^ self primitiveFloatSubtract: (self stackValue: 1) fromArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
NewspeakInterpreter >> primitiveFloatSubtract: rcvrOop fromArg: argOop [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	<var: #arg type: 'double '>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	self successful ifTrue: [
		self pop: 2.
		self pushFloat: rcvr - arg].
]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveFlushCache [
	"Clear the method lookup cache. This must be done after every programming change."

	self flushMethodCache.
	self flushAtCache
]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveFlushCacheByMethod [
	"The receiver is a compiledMethod.  Clear all entries in the method lookup cache that refer to this method, presumably because it has been redefined, overridden or removed."
	| probe oldMethod |
	oldMethod := self stackTop.
	probe := 0.
	1 to: MethodCacheEntries do:
		[:i | (methodCache at: probe + MethodCacheMethod) = oldMethod ifTrue:
			[methodCache at: probe + MethodCacheSelector put: 0].
		probe := probe + MethodCacheEntrySize].
	self flushAtCache
]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveFlushCacheBySelector [
	"The receiver is a message selector.  Clear all entries in the method lookup cache
	 with this selector, presumably because an associated method has been redefined."
	| selector probe |
	selector := self stackTop.
	probe := 0.
	1 to: MethodCacheEntries do:
		[:i | (methodCache at: probe + MethodCacheSelector) = selector ifTrue:
			[methodCache at: probe + MethodCacheSelector put: 0].
		probe := probe + MethodCacheEntrySize].
	(selector = (self specialSelector: 16) "at:"
	 or: [selector = (self specialSelector: 17) "at:put:"]) ifTrue:
		[self flushAtCache]
]

{ #category : #'plugin primitives' }
NewspeakInterpreter >> primitiveFlushExternalPrimitives [
	"Primitive. Flush all the existing external primitives in the image thus forcing a reload on next invokation."
	^self flushExternalPrimitives
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveForceDisplayUpdate [
	"On some platforms, this primitive forces enqueued display updates to be processed immediately. On others, it does nothing."

	self ioForceDisplayUpdate.

]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveForceTenure [
	"Set force tenure flag to true, this forces a tenure operation on the next incremental GC"

	<export: true>
	forceTenureFlag := 1
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveFormPrint [
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
	self successful ifTrue: [
		((self  isPointers: rcvr) and: [(self lengthOf: rcvr) >= 4])
			ifFalse: [self success: false]].
	self successful ifTrue: [
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
	self successful ifTrue: [
		BytesPerWord = 8
			ifTrue: [ok := self cCode: 'ioFormPrint(bitsArray + 8, w, h, depth, hScale, vScale, landscapeFlag)']
			ifFalse: [ok := self cCode: 'ioFormPrint(bitsArray + 4, w, h, depth, hScale, vScale, landscapeFlag)'].
		self success: ok].
	self successful ifTrue: [
		self pop: 3].  "pop hScale, vScale, and landscapeFlag; leave rcvr on stack"

]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveFractionalPart [
	| rcvr frac trunc |
	<var: #rcvr type: 'double '>
	<var: #frac type: 'double '>
	<var: #trunc type: 'double '>
	rcvr := self popFloat.
	self successful
		ifTrue: [self cCode: 'frac = modf(rcvr, &trunc)' inSmalltalk: [frac := rcvr fractionPart].
				self pushFloat: frac]
		ifFalse: [self unPop: 1]
]

{ #category : #'memory space primitives' }
NewspeakInterpreter >> primitiveFullGC [
	"Do a full garbage collection and return the number of bytes available (including swap space if dynamic memory management is supported)."

	self pop: 1.
	self incrementalGC.  "maximimize space for forwarding table"
	self fullGC.
	self pushInteger: (self bytesLeft: true).
]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveGetAttribute [
	"Fetch the system attribute with the given integer ID. The 
	result is a string, which will be empty if the attribute is not 
	defined."
	| attr sz s |
	attr := self stackIntegerValue: 0.
	self successful
		ifTrue: [sz := self attributeSize: attr].
	self successful
		ifTrue: [s := self
						instantiateClass: (self splObj: ClassByteString)
						indexableSize: sz.
			self
				getAttribute: attr
				Into: s + BaseHeaderSize
				Length: sz.
			self pop: 2 thenPush: s]
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveGetImmutability [
	| rcvr hdr |
	rcvr := self stackValue: 0.
	(self isIntegerObject: rcvr)
		ifTrue:
			[self pop: argumentCount thenPush: (self splObj: TrueObject)]
		ifFalse:
			[hdr := self baseHeader: rcvr.
			self pop: argumentCount thenPushBool: (hdr bitAnd: ImmutabilityBit) ~= 0]
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveGetNextEvent [
	"Primitive. Return the next input event from the VM event queue."
	| evtBuf arg value |
	<var: #evtBuf declareC:'int evtBuf[8] = { 0, 0, 0, 0, 0, 0, 0, 0 }'>
	self cCode:'' inSmalltalk:[evtBuf := CArrayAccessor on: (IntegerArray new: 8)].
	arg := self stackTop.
	((self isArray: arg) and:[(self slotSizeOf: arg) = 8])  ifFalse:[^self primitiveFail].

	self ioGetNextEvent: (self cCoerce: evtBuf to: 'sqInputEvent*').
	self successful ifFalse:[^nil].

	"Event type"
	self storeInteger: 0 ofObject: arg withValue: (evtBuf at: 0).
	self successful ifFalse:[^nil].

	"Event time stamp"
	self storeInteger: 1 ofObject: arg withValue: ((evtBuf at: 1) bitAnd: MillisecondClockMask).
	self successful ifFalse:[^nil].

	"Event arguments"
	2 to: 7 do:[:i|
		value := evtBuf at: i.
		(self isIntegerValue: value)
			ifTrue:[self storeInteger: i ofObject: arg withValue: value]
			ifFalse:["Need to remap because allocation may cause GC"
				self pushRemappableOop: arg.
				value := self positive32BitIntegerFor: value.
				arg := self popRemappableOop.
				self storePointer: i ofObject: arg withValue: value]].

	self successful ifFalse:[^nil].
	self pop: 1.
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveGreaterOrEqual [
	| integerReceiver integerArgument |
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver >= integerArgument
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveGreaterThan [
	| integerReceiver integerArgument |
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver > integerArgument
]

{ #category : #'other primitives' }
NewspeakInterpreter >> primitiveHeaderWords [
	"Primitive. Answer an Array of the integers representing the header words for the argument."
	| obj hdr1 result size |
	obj := self stackTop.
	(self isIntegerObject: obj) ifTrue:
		[self primitiveFail. ^nil].
	(self headerType: obj) = HeaderTypeShort
		ifTrue: [size := 1]
		ifFalse:
			[(self headerType: obj) = HeaderTypeClass
				ifTrue: [size := 2]
				ifFalse:
					[size := 3]].
	result := self instantiateClass: self classArray indexableSize: size. "can cause GC"
	obj := self stackTop.
	self storePointer: 0 ofObject: result withValue: (self positive32BitIntegerFor: (self baseHeader: obj)).
	size > 1 ifTrue:
		[self storePointer: 1 ofObject: result withValue: (self positive32BitIntegerFor: (self classHeader: obj))].
	size > 2 ifTrue:
		[self storePointer: 2 ofObject: result withValue: (self positive32BitIntegerFor: (self sizeHeader: obj))].
	self pop: self methodArgumentCount + 1 thenPush: result.
]

{ #category : #'other primitives' }
NewspeakInterpreter >> primitiveImageName [
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
		self assertClassOf: s is: (self splObj: ClassByteString).
		self successful ifTrue: [
			sz := self stSizeOf: s.
			self imageNamePut: (s + BaseHeaderSize) Length: sz.
			self pop: 1.  "pop s, leave rcvr on stack"
		].
	] ifFalse: [
		sz := self imageNameSize.
		s := self instantiateClass: (self splObj: ClassByteString) indexableSize: sz.
		self imageNameGet: (s + BaseHeaderSize) Length: sz.
		self pop: 1.  "rcvr"
		self push: s.
	].

]

{ #category : #'memory space primitives' }
NewspeakInterpreter >> primitiveIncrementalGC [
	"Do a quick, incremental garbage collection and return the number of bytes immediately available. (Note: more space may be made available by doing a full garbage collection."

	self pop: 1.
	self incrementalGC.
	self pushInteger: (self bytesLeft: false).
]

{ #category : #'compiled methods' }
NewspeakInterpreter >> primitiveIndexOf: methodPointer [
	"Note: We now have 10 bits of primitive index, but they are in two places
	for temporary backward compatibility.  The time to unpack is negligible,
	since the reconstituted full index is stored in the method cache."
	| primBits |
	primBits := ((self headerOf: methodPointer) >> 1) bitAnd: 16r100001FF.
	
	^ (primBits bitAnd: 16r1FF) + (primBits >> 19)

]

{ #category : #'compiled methods' }
NewspeakInterpreter >> primitiveIndexOfMethodHeader: methodHeader [
	"Note: We now have 10 bits of primitive index, but they are in two places
	for temporary backward compatibility.  The time to unpack is negligible,
	since the reconstituted full index is stored in the method cache."
	| primBits |
	primBits := (methodHeader >> 1) bitAnd: 16r100001FF.
	^ (primBits bitAnd: 16r1FF) + (primBits >> 19)
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveInputSemaphore [
	"Register the input semaphore. The argument is an index into the ExternalObjectsArray part of the specialObjectsArray and must have been allocated via 'Smalltalk registerExternalObject: the Semaphore' "
	| arg |
	arg := self stackTop.
	(self isIntegerObject: arg)
		ifTrue: ["If arg is integer, then condsider it as an index  into the external objects array and install it  as the new event semaphore"
			self ioSetInputSemaphore: (self integerValueOf: arg).
			self successful
				ifTrue: [self pop: 1].
			^ nil]
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveInputWord [
	"Return an integer indicating the reason for the most recent input interrupt."

	self pop: 1 thenPushInteger: 0.	"noop for now"
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveInstVarAt [
	| index rcvr hdr fmt totalLength fixedFields value |
	index := self stackIntegerValue: 0.
	rcvr := self stackValue: 1.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	hdr := self baseHeader: rcvr.
	fmt := hdr >> 8 bitAnd: 15.
	totalLength := self lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: rcvr format: fmt length: totalLength.
	(index >= 1 and: [index <= fixedFields]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	value := self subscript: rcvr with: index format: fmt.
	self pop: argumentCount + 1 thenPush: value
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveInstVarAtPut [
	| newValue index rcvr hdr fmt totalLength fixedFields |
	newValue := self stackTop.
	index := self stackIntegerValue: 1.
	rcvr := self stackValue: 2.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	hdr := self baseHeader: rcvr.
	fmt := hdr >> 8 bitAnd: 15.
	totalLength := self lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: rcvr format: fmt length: totalLength.
	(index >= 1 and: [index <= fixedFields]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	 (hdr bitAnd: ImmutabilityBit) ~= 0 ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	self subscript: rcvr with: index storing: newValue format: fmt.
	self pop: argumentCount + 1 thenPush: newValue
]

{ #category : #'sound primitives' }
NewspeakInterpreter >> primitiveIntegerAt [
	"Return the 32bit signed integer contents of a words receiver"

	| index rcvr sz addr value |
	index := self stackIntegerValue: 0.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 1.
	((self isIntegerObject: rcvr)
	or: [(self isWords: rcvr) not]) ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	sz := self lengthOf: rcvr.  "number of fields"
	((index >= 1) and: [index <= sz]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	addr := rcvr + BaseHeaderSize - 4 "for zero indexing" + (index * 4).
	value := self intAt: addr.
	self pop: 2.  "pop rcvr, index"
	"push element value"
	(self isIntegerValue: value)
		ifTrue: [self pushInteger: value]
		ifFalse: [self push: (self signed32BitIntegerFor: value)]
]

{ #category : #'sound primitives' }
NewspeakInterpreter >> primitiveIntegerAtPut [
	"Return the 32bit signed integer contents of a words receiver"
	| index rcvr sz addr value valueOop |
	valueOop := self stackValue: 0.
	index := self stackIntegerValue: 1.
	(self isIntegerObject: valueOop)
		ifTrue:[value := self integerValueOf: valueOop]
		ifFalse:[value := self signed32BitValueOf: valueOop].
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 2.
	((self isIntegerObject: rcvr)
	or: [(self isWords: rcvr) not]) ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	sz := self lengthOf: rcvr.  "number of fields"
	(index >= 1 and: [index <= sz]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	(self isOopImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	addr := rcvr + BaseHeaderSize - 4 "for zero indexing" + (index * 4).
	value := self intAt: addr put: value.
	self pop: 3 thenPush: valueOop "pop all; return value"

]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveInterruptSemaphore [
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
NewspeakInterpreter >> primitiveInvokeObjectAsMethod [
	"Primitive. 'Invoke' an object like a function, sending the special message 
		run: originalSelector with: arguments in: aReceiver.
	"
	| runSelector runReceiver runArgs newReceiver lookupClass |
	runArgs := self instantiateClass: (self splObj: ClassArray) indexableSize: argumentCount.
	self beRootIfOld: runArgs. "do we really need this?"
	self transfer: argumentCount from: stackPointer - ((argumentCount - 1) * BytesPerWord) to: runArgs + BaseHeaderSize.

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
	self executeNewMethod.  "Recursive xeq affects successFlag"
	self initPrimCall.

]

{ #category : #'memory space primitives' }
NewspeakInterpreter >> primitiveIsRoot [
	"Primitive. Answer whether the argument to the primitive is a root for young space"
	| oop |
	<export: true>
	oop := self stackObjectValue: 0.
	self successful ifTrue:
		[self pop: argumentCount + 1 thenPushBool: (self isYoungRoot: oop)]
]

{ #category : #'memory space primitives' }
NewspeakInterpreter >> primitiveIsYoung [
	"Primitive. Answer whether the argument to the primitive resides in young space."
	| oop |
	<export: true>
	oop := self stackObjectValue: 0.
	self successful ifTrue:[
		self pop: argumentCount + 1.
		self pushBool: oop >= youngStart.
	].
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveKbdNext [
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
NewspeakInterpreter >> primitiveKbdPeek [
	"Obsolete on virtually all platforms; old style input polling code.
	Return the next keycode and without removing it from the input buffer. The low byte is the 8-bit ISO character. The next four bits are the Smalltalk modifier bits <cmd><option><ctrl><shift>."

	| keystrokeWord |
	self pop: 1.
	keystrokeWord := self ioPeekKeystroke.
	keystrokeWord >= 0
		ifTrue: [self pushInteger: keystrokeWord]
		ifFalse: [self push: nilObj].
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveLessOrEqual [
	| integerReceiver integerArgument |
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver <= integerArgument
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveLessThan [
	| integerReceiver integerArgument |
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver < integerArgument
]

{ #category : #'plugin primitives' }
NewspeakInterpreter >> primitiveListBuiltinModule [
	"Primitive. Return the n-th builtin module name."
	| moduleName index length nameOop |
	<var: #moduleName type: #'char *'>
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
NewspeakInterpreter >> primitiveListExternalModule [
	"Primitive. Return the n-th loaded external module name."
	| moduleName index length nameOop |
	<var: #moduleName type: #'char *'>
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
NewspeakInterpreter >> primitiveLoadImageSegment [
	"This primitive is called from Squeak as...
		<imageSegment> loadSegmentFrom: aWordArray outPointers: anArray."

"This primitive will load a binary image segment created by primitiveStoreImageSegment.  It expects the outPointer array to be of the proper size, and the wordArray to be well formed.  It will return as its value the original array of roots, and the erstwhile segmentWordArray will have been truncated to a size of zero.  If this primitive should fail, the segmentWordArray will, sadly, have been reduced to an unrecognizable and unusable jumble.  But what more could you have done with it anyway?"

	| outPointerArray segmentWordArray endSeg segOop fieldPtr fieldOop doingClass lastPtr extraSize mapOop lastOut outPtr hdrTypeBits header data |

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	outPointerArray := self stackTop.
	lastOut := outPointerArray + (self lastPointerOf: outPointerArray).
	segmentWordArray := self stackValue: 1.
	endSeg := segmentWordArray + (self sizeBitsOf: segmentWordArray) - BaseHeaderSize.

	"Essential type checks"
	((self formatOf: outPointerArray) = 2				"Must be indexable pointers"
		and: [(self formatOf: segmentWordArray) = 6])	"Must be indexable words"
		ifFalse: [^ self primitiveFail].

	"Version check.  Byte order of the WordArray now"
	data := self longAt: segmentWordArray + BaseHeaderSize.
	(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse: [
		"Not readable -- try again with reversed bytes..."
		self reverseBytesFrom: segmentWordArray + BaseHeaderSize to: endSeg + BytesPerWord.
		data := self longAt: segmentWordArray + BaseHeaderSize.
		(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse: [
			"Still NG -- put things back and fail"
			self reverseBytesFrom: segmentWordArray + BaseHeaderSize to: endSeg + BytesPerWord.
			DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^ self primitiveFail]].
	"Reverse the Byte type objects if the data from opposite endian machine"
	"Test top byte.  $d on the Mac or $s on the PC.  Rest of word is equal"
	data = self imageSegmentVersion ifFalse: [
		"Reverse the byte-type objects once"
		segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
			 "Oop of first embedded object"
		self byteSwapByteObjectsFrom: segOop to: endSeg + BytesPerWord].

	"Proceed through the segment, remapping pointers..."
	segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
	[segOop <= endSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type = 0 or 1) -- start with that."
					fieldPtr := segOop - BytesPerWord.  doingClass := true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr := segOop + BaseHeaderSize.  doingClass := false].
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
					fieldPtr := fieldPtr + BytesPerWord]
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
								fieldPtr := fieldPtr + BytesPerWord].
					segOop < youngStart
						ifTrue: [self possibleRootStoreInto: segOop value: mapOop].
					]].
		segOop := self objectAfter: segOop].

	"Again, proceed through the segment checking consistency..."
	segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
	[segOop <= endSeg] whileTrue:
		[(self oopHasAcceptableClass: segOop) ifFalse: [^ self primitiveFail "inconsistency"].
		fieldPtr := segOop + BaseHeaderSize.		"first field"
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"
		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop := self longAt: fieldPtr.
			(self oopHasAcceptableClass: fieldOop) ifFalse: [^ self primitiveFail "inconsistency"].
			fieldPtr := fieldPtr + BytesPerWord].
		segOop := self objectAfter: segOop].

	"Truncate the segment word array to size = BytesPerWord (vers stamp only)"
	extraSize := self extraHeaderBytes: segmentWordArray.
	hdrTypeBits := self headerType: segmentWordArray.
	extraSize = 8
		ifTrue: [self longAt: segmentWordArray-extraSize put: BaseHeaderSize + BytesPerWord + hdrTypeBits]
		ifFalse: [header := self longAt: segmentWordArray.
				self longAt: segmentWordArray
					put: header - (header bitAnd: SizeMask) + BaseHeaderSize + BytesPerWord].	
	"and return the roots array which was first in the segment"
	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	self pop: 3 thenPush: (self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord).

]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveLogN [
	"Natural log."

	| rcvr |
	<var: #rcvr type: 'double '>
	rcvr := self popFloat.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'log(rcvr)' inSmalltalk: [rcvr ln])]
		ifFalse: [self unPop: 1]
]

{ #category : #'memory space primitives' }
NewspeakInterpreter >> primitiveLowSpaceSemaphore [
	"Register the low-space semaphore. If the argument is not a 
	Semaphore, unregister the current low-space Semaphore."
	| arg |
	arg := self popStack.
	(self fetchClassOf: arg) = (self splObj: ClassSemaphore)
		ifTrue: [self storePointer: TheLowSpaceSemaphore ofObject: specialObjectsOop withValue: arg]
		ifFalse: [self storePointer: TheLowSpaceSemaphore ofObject: specialObjectsOop withValue: nilObj]
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveMakePoint [
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
NewspeakInterpreter >> primitiveMarkHandlerMethod [
	"Primitive. Mark the method for exception handling. The primitive must fail after marking the context so that the regular code is run."
	<inline: false>
	^self primitiveFail
]

{ #category : #'process primitives' }
NewspeakInterpreter >> primitiveMarkUnwindMethod [
	"Primitive. Mark the method for exception unwinding. The primitive must fail after marking the context so that the regular code is run."
	<inline: false>
	^self primitiveFail
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> primitiveMethod [
	"Return the method an external primitive was defined in"
	^newMethod
]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveMillisecondClock [
	"Return the value of the millisecond clock as an integer. Note that the millisecond clock wraps around periodically. On some platforms it can wrap daily. The range is limited to SmallInteger maxVal / 2 to allow delays of up to that length without overflowing a SmallInteger."

	self pop: 1 thenPush: (self integerObjectOf: (self ioMSecs bitAnd: MillisecondClockMask)).

]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveMod [
	| mod |
	mod := self doPrimitiveMod: (self stackValue: 1) by: (self stackTop).
	self pop2AndPushIntegerIfOK: mod
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveMouseButtons [
	"Obsolete on virtually all platforms; old style input polling code.
	Return the mouse button state. The low three bits encode the state of the <red><yellow><blue> mouse buttons. The next four bits encode the Smalltalk modifier bits <cmd><option><ctrl><shift>."

	| buttonWord |
	self pop: 1.
	buttonWord := self ioGetButtonState.
	self pushInteger: buttonWord.
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveMousePoint [
	"Obsolete on virtually all platforms; old style input polling code.
	Return a Point indicating current position of the mouse. Note that mouse coordinates may be negative if the mouse moves above or to the left of the top-left corner of the Smalltalk window."

	| pointWord x y |
	self pop: 1.
	pointWord := self ioMousePoint.
	x := self signExtend16: ((pointWord >> 16) bitAnd: 16rFFFF).
	y := self signExtend16: (pointWord bitAnd: 16rFFFF).
	self push: (self makePointwithxValue: x  yValue: y).
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveMultiply [
	| integerRcvr integerArg integerResult |
	integerRcvr := self stackIntegerValue: 1.
	integerArg := self stackIntegerValue: 0.
	self successful ifTrue:
		[integerResult := integerRcvr * integerArg.
		"check for C overflow by seeing if computation is reversible"
		((integerArg = 0) or: [(integerResult // integerArg) = integerRcvr])
			ifTrue: [self pop2AndPushIntegerIfOK: integerResult]
			ifFalse: [self primitiveFail]]
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveNew [
	"Allocate a new fixed-size instance. Fail if the allocation would leave less than lowSpaceThreshold bytes free. May cause a GC"

	| class spaceOkay |
	class := self stackTop.
	"The following may cause GC!"
	spaceOkay := self sufficientSpaceToInstantiate: class indexableSize: 0.
	self success: spaceOkay.
	self successful ifTrue: [ self push: (self instantiateClass: self popStack indexableSize: 0) ]
]

{ #category : #'compiled methods' }
NewspeakInterpreter >> primitiveNewMethod [
	| header bytecodeCount class size theMethod literalCount |
	header := self popStack.
	bytecodeCount := self popInteger.
	self success: (self isIntegerObject: header).
	self successful ifFalse:
		[self unPop: 2. ^nil].
	class := self popStack.
	size := (self literalCountOfHeader: header) + 1 * BytesPerWord + bytecodeCount.
	theMethod := self instantiateClass: class indexableSize: size.
	self storePointerUnchecked: HeaderIndex ofObject: theMethod withValue: header.
	literalCount := self literalCountOfHeader: header.
	1 to: literalCount do:
		[:i | self storePointerUnchecked: i ofObject: theMethod withValue: nilObj].
	self push: theMethod
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveNewWithArg [
	"Allocate a new indexable instance. Fail if the allocation would leave less than lowSpaceThreshold bytes free."
	| size class spaceOkay |
	size := self positive32BitValueOf: self stackTop.
	class := self stackValue: 1.
	self success: size >= 0.
	self successful
		ifTrue: ["The following may cause GC!"
			spaceOkay := self sufficientSpaceToInstantiate: class indexableSize: size.
			self success: spaceOkay.
			class := self stackValue: 1].
	self successful ifTrue: [self pop: 2 thenPush: (self instantiateClass: class indexableSize: size)]
]

{ #category : #'array and stream primitives' }
NewspeakInterpreter >> primitiveNext [
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
	self successful ifTrue:
		[stream := self stackTop.
		self storeInteger: StreamIndexIndex ofObject: stream withValue: index.
		^ self pop: 1 thenPush: result].

]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveNextInstance [
	| object instance |
	object := self stackTop.
	instance := self instanceAfter: object.
	instance = nilObj
		ifTrue: [self primitiveFail]
		ifFalse: [self pop: argumentCount+1 thenPush: instance]
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveNextObject [
	"Return the object following the receiver in the heap. Return the SmallInteger zero when there are no more objects."

	| object instance |
	object := self stackTop.
	instance := self accessibleObjectAfter: object.
	instance = nil
		ifTrue: [ self pop: argumentCount+1 thenPushInteger: 0 ]
		ifFalse: [ self pop: argumentCount+1 thenPush: instance ].
]

{ #category : #'array and stream primitives' }
NewspeakInterpreter >> primitiveNextPut [
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
	limit := self fetchInteger: StreamReadLimitIndex ofObject: stream.
	atIx := (array bitAnd: AtCacheMask) + AtPutBase.
	(index < limit
	 and: [(atCache at: atIx+AtCacheOop) = array]) ifFalse:
		[^self primitiveFail].
	((self isOopImmutable: stream)
	 or: [self isOopImmutable: array]) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].

	"OK -- its not at end, and the array is in the cache"
	index := index + 1.
	self commonVariable: array at: index put: value cacheIndex: atIx.
	self successful ifTrue:
		[self storeInteger: StreamIndexIndex ofObject: stream withValue: index.
		^ self pop: 2 thenPush: value].

]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveNoop [
	"A placeholder for primitives that haven't been implemented or are being withdrawn gradually. Just absorbs any arguments and returns the receiver."

	self pop: argumentCount.  "pop args, leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveNotEqual [
	| integerReceiver integerArgument result |
	integerArgument := self popStack.
	integerReceiver := self popStack.
	result := (self compare31or32Bits: integerReceiver equal: integerArgument) not.
	self checkBooleanResult: result
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveNotIdentical [
	"is the receiver/first argument not the same object as the (last) argument?.
	 pop argumentCount because this can be used as a mirror primitive."
	| thisObject otherObject |
	otherObject := self stackValue: 1.
	thisObject := self stackTop.
	self pop: argumentCount + 1 thenPushBool: thisObject ~= otherObject
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveObjectAt [
"Defined for CompiledMethods only"
	| thisReceiver index |
	index  := self stackIntegerValue: 0.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	thisReceiver := self stackValue: 1.
	(index > 0 and: [index <= ((self literalCountOf: thisReceiver) + LiteralStart)]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	self pop: 2 thenPush: (self fetchPointer: index - 1 ofObject: thisReceiver)
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveObjectAtPut [
"Defined for CompiledMethods only"
	| rcvr index newValue |
	newValue := self stackValue: 0.
	index := self stackIntegerValue: 1.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 2.
	(index > 0 and: [index <= ((self literalCountOf: rcvr) + LiteralStart)]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	(self isOopImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	self storePointer: index - 1 ofObject: rcvr withValue: newValue.
	self pop: 3 thenPush: newValue
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveObjectPointsTo [
	| rcvr thang lastField |
	thang := self popStack.
	rcvr := self popStack.
	(self isIntegerObject: rcvr) ifTrue: [^self pushBool: false].

	lastField := self lastPointerOf: rcvr.
	BaseHeaderSize to: lastField by: BytesPerWord do:
		[:i | (self longAt: rcvr + i) = thang
			ifTrue: [^ self pushBool: true]].
	self pushBool: false.
]

{ #category : #'control primitives' }
NewspeakInterpreter >> primitivePerform [
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
	self sendBreakpoint: messageSelector receiver: newReceiver.
	self findNewMethodInClass: lookupClass.

	"Only test CompiledMethods for argument count - other objects will have to take their chances"
	(self isCompiledMethod: newMethod)
		ifTrue: [self success: (self argumentCountOf: newMethod) = argumentCount].

	self successful
		ifTrue: [self executeNewMethod.
			"Recursive xeq affects successFlag"
			self initPrimCall]
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
NewspeakInterpreter >> primitivePerformAt: lookupClass [
	"Common routine used by perform:withArgs: and perform:withArgs:inSuperclass:"

	"NOTE:  The case of doesNotUnderstand: is not a failure to perform.
	The only failures are arg types and consistency of argumentCount."

	| performSelector argumentArray arraySize index cntxSize performMethod performArgCount |
	argumentArray := self stackTop.
	(self isArray: argumentArray) ifFalse:[^self primitiveFail].

	self successful ifTrue:
		["Check for enough space in thisContext to push all args"
		arraySize := self fetchWordLengthOf: argumentArray.
		cntxSize := self fetchWordLengthOf: activeContext.
		self success: (self stackPointerIndex + arraySize) < cntxSize].
	self successful ifFalse: [^nil].

	performSelector := messageSelector.
	performMethod := newMethod.
	performArgCount := argumentCount.
	"pop the arg array and the selector, then push the args out of the array, as if they were on the stack"
	self popStack.
	messageSelector := self popStack.

	"Copy the arguments to the stack, and execute"
	index := 1.
	[index <= arraySize] whileTrue:
		[self push: (self fetchPointer: index - 1 ofObject: argumentArray).
		index := index + 1].
	argumentCount := arraySize.

	self fastLogSend: messageSelector.
	self sendBreakpoint: messageSelector receiver: receiver.
	self findNewMethodInClass: lookupClass.

	"Only test CompiledMethods for argument count - any other objects playacting as CMs will have to take their chances"
	(self isCompiledMethod: newMethod)
		ifTrue: [self success: (self argumentCountOf: newMethod) = argumentCount].

	self successful
		ifTrue: [self executeNewMethod.  "Recursive xeq affects successFlag"
				self initPrimCall]
		ifFalse: ["Restore the state by popping all those array entries and pushing back the selector and array, and fail"
				self pop: argumentCount.
				self push: messageSelector.
				self push: argumentArray.
				messageSelector := performSelector.
				newMethod := performMethod.
				argumentCount := performArgCount]

]

{ #category : #'control primitives' }
NewspeakInterpreter >> primitivePerformInSuperclass [
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
	self successful ifFalse:
		[self push: lookupClass]
]

{ #category : #'control primitives' }
NewspeakInterpreter >> primitivePerformWithArgs [

	| lookupClass rcvr |
	rcvr := self stackValue: argumentCount.
	lookupClass := self fetchClassOf: rcvr.
	self primitivePerformAt: lookupClass.

]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitivePointX [
	| rcvr | 
	<inline: false>
	rcvr := self popStack.
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	self successful
		ifTrue: [self push: (self fetchPointer: XIndex ofObject: rcvr)]
		ifFalse: [self unPop: 1]
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitivePointY [
	| rcvr | 
	<inline: false>
	rcvr := self popStack.
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	self successful
		ifTrue: [self push: (self fetchPointer: YIndex ofObject: rcvr)]
		ifFalse: [self unPop: 1]
]

{ #category : #'quick primitives' }
NewspeakInterpreter >> primitivePushFalse [
	self popStack.
	self push: falseObj
]

{ #category : #'quick primitives' }
NewspeakInterpreter >> primitivePushMinusOne [
	self popStack.
	self push: ConstMinusOne
]

{ #category : #'quick primitives' }
NewspeakInterpreter >> primitivePushNil [
	self popStack.
	self push: nilObj
]

{ #category : #'quick primitives' }
NewspeakInterpreter >> primitivePushOne [
	self popStack.
	self push: ConstOne
]

{ #category : #'quick primitives' }
NewspeakInterpreter >> primitivePushSelf [
"	no-op, really...
	thisReceiver := self popStack.
	self push: thisReceiver
"
]

{ #category : #'quick primitives' }
NewspeakInterpreter >> primitivePushTrue [
	self popStack.
	self push: trueObj
]

{ #category : #'quick primitives' }
NewspeakInterpreter >> primitivePushTwo [
	self popStack.
	self push: ConstTwo
]

{ #category : #'quick primitives' }
NewspeakInterpreter >> primitivePushZero [
	self popStack.
	self push: ConstZero
]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveQuit [

	self ioExit.

]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveQuo [
	"Rounds negative results towards zero."
	| integerRcvr integerArg integerResult |
	integerRcvr := self stackIntegerValue: 1.
	integerArg := self stackIntegerValue: 0.
	self success: integerArg ~= 0.
	self successful ifTrue: [
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

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveRelinquishProcessor [
	"Relinquish the processor for up to the given number of microseconds. The exact behavior of this primitive is platform dependent."

	| microSecs |
	microSecs := self stackIntegerValue: 0.
	self successful ifTrue: [
		self ioRelinquishProcessorForMicroseconds: microSecs.
		self pop: 1]  "microSecs; leave rcvr on stack"

]

{ #category : #'process primitives' }
NewspeakInterpreter >> primitiveResume [
"put this process on the scheduler's lists thus allowing it to proceed next time there is a chance for processes of it's priority level"
	| proc |
	proc := self stackTop.  "rcvr"
	"self success: ((self fetchClassOf: proc) = (self splObj: ClassProcess))."
	self successful ifTrue: [ self resume: proc ].
]

{ #category : #'memory space primitives' }
NewspeakInterpreter >> primitiveRootTable [
	"Primitive. Answer a copy (snapshot) element of the root table.
	The primitive can cause GC itself and if so the return value may
	be inaccurate - in this case one should guard the read operation
	by looking at the gc counter statistics."
	self pop: argumentCount + 1 thenPush: self rootTableObject
]

{ #category : #'memory space primitives' }
NewspeakInterpreter >> primitiveRootTableAt [
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
	self successful ifTrue:[
		self pop: argumentCount + 1.
		self push: (rootTable at: index).
	].
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveScanCharacters [
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
	self successful ifFalse: [^ nil].
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
NewspeakInterpreter >> primitiveScreenDepth [
	"Return a SmallInteger indicating the current depth of the OS screen. Negative values are used to imply LSB type pixel format an there is some support in the VM for handling either MSB or LSB"
	| depth |
	<export: true>
	depth := self ioScreenDepth.
	self failed ifTrue:[^self primitiveFail].
	self pop: 1 thenPushInteger: depth.
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveScreenSize [
	"Return a point indicating the current size of the Smalltalk window. Currently there is a limit of 65535 in each direction because the point is encoded into a single 32bit value in the image header. This might well become a problem one day"
	| pointWord |
	self pop: 1.
	pointWord := self ioScreenSize.
	self push: (self makePointwithxValue: (pointWord >> 16 bitAnd: 65535) yValue: (pointWord bitAnd: 65535))
]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveSecondsClock [
	"Return the number of seconds since January 1, 1901 as an integer."

	self pop: 1 thenPush: (self positive32BitIntegerFor: self ioSeconds).
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveSetDisplayMode [
	"Set to OS to the requested display mode.
	See also DisplayScreen setDisplayDepth:extent:fullscreen:"
	| fsFlag h w d okay |
	fsFlag := self booleanValueOf: (self stackTop).
	h := self stackIntegerValue: 1.
	w := self stackIntegerValue: 2.
	d := self stackIntegerValue: 3.
	self successful ifTrue: [okay := self cCode:'ioSetDisplayMode(w, h, d, fsFlag)'].
	self successful ifTrue: [
		self pop: 5. "Pop args+rcvr"
		self pushBool: okay].
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveSetFullScreen [
	"On platforms that support it, set full-screen mode to the value of the boolean argument."

	| argOop |
	argOop := self stackTop.
	argOop = trueObj
		ifTrue: [self ioSetFullScreen: true]
		ifFalse: [ argOop = falseObj
				ifTrue: [self ioSetFullScreen: false]
				ifFalse: [self primitiveFail]].
	self successful ifTrue: [self pop: 1].

]

{ #category : #'memory space primitives' }
NewspeakInterpreter >> primitiveSetGCBiasToGrow [
	"Primitive. Indicate if the GC logic should have bias to grow"
	| flag |
	<export: true>
	flag := self stackIntegerValue: 0.
	self successful ifTrue:[
		gcBiasToGrow := flag.
		self pop: argumentCount.
	].
]

{ #category : #'memory space primitives' }
NewspeakInterpreter >> primitiveSetGCBiasToGrowGCLimit [
	"Primitive. If the GC logic has  bias to grow, set growth limit"
	| value |
	<export: true>
	value := self stackIntegerValue: 0.
	self successful ifTrue:[
		gcBiasToGrowGCLimit := value.
		gcBiasToGrowThreshold := youngStart - (self cCoerce: memory to: 'int').
		self pop: argumentCount.
	].
]

{ #category : #'memory space primitives' }
NewspeakInterpreter >> primitiveSetGCSemaphore [
	"Primitive. Indicate the semaphore to be signalled for upon garbage collection"
	| index |
	<export: true>
	index := self stackIntegerValue: 0.
	self successful ifTrue:[
		gcSemaphoreIndex := index.
		self pop: argumentCount.
	].
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveSetImmutability [
	| boolean rcvr hdr wasImmutable |
	rcvr := self stackValue: 1.
	(self isIntegerObject: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	boolean := self booleanValueOf: self stackTop.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	hdr := self baseHeader: rcvr.
	wasImmutable := hdr bitAnd: ImmutabilityBit.
	boolean
		ifTrue: [hdr := hdr bitOr: ImmutabilityBit]
		ifFalse: [hdr := hdr bitAnd: AllButImmutabilityBit].
	self baseHeader: rcvr put: hdr.
	self pop: argumentCount thenPushBool: wasImmutable ~= 0
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveSetInterruptKey [
	"Set the user interrupt keycode. The keycode is an integer whose encoding is described in the comment for primitiveKbdNext."

	| keycode |
	keycode := self popInteger.
	self successful
		ifTrue: [ interruptKeycode := keycode ]
		ifFalse: [ self unPop: 1 ].
]

{ #category : #'sound primitives' }
NewspeakInterpreter >> primitiveShortAt [
	"Treat the receiver, which can be indexible by either bytes or words, as an array of signed 16-bit values. Return the contents of the given index. Note that the index specifies the i-th 16-bit entry, not the i-th byte or word."

	| index rcvr sz addr value |
	index := self stackIntegerValue: 0.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 1.
	((self isIntegerObject: rcvr)
	or: [(self isWordsOrBytes: rcvr) not]) ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	sz := ((self sizeBitsOf: rcvr) - BaseHeaderSize) // 2.  "number of 16-bit fields"
	((index >= 1) and: [index <= sz]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	addr := rcvr + BaseHeaderSize + (2 * (index - 1)).
	value := self shortAt: addr.
	self pop: 2 thenPushInteger: value
]

{ #category : #'sound primitives' }
NewspeakInterpreter >> primitiveShortAtPut [
	"Treat the receiver, which can be indexible by either bytes or words, as an array of signed 16-bit values. Set the contents of the given index to the given value. Note that the index specifies the i-th 16-bit entry, not the i-th byte or word."

	| index rcvr sz addr value |
	value := self stackIntegerValue: 0.
	index := self stackIntegerValue: 1.
	(self successful and: [(value >= -32768) and: [value <= 32767]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 2.
	((self isIntegerObject: rcvr) not and: [self isWordsOrBytes: rcvr]) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	sz := ((self sizeBitsOf: rcvr) - BaseHeaderSize) // 2.  "number of 16-bit fields"
	(index >= 1 and: [index <= sz]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	(self isOopImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	addr := rcvr + BaseHeaderSize + (2 * (index - 1)).
	self shortAt: addr put: value.
	self pop: 3 thenPush: (self integerObjectOf: value) "pop all; return value"
]

{ #category : #'I/O primitives' }
NewspeakInterpreter >> primitiveShowDisplayRect [
	"Force the given rectangular section of the Display to be 
	copied to the screen."
	| bottom top right left |
	bottom := self stackIntegerValue: 0.
	top := self stackIntegerValue: 1.
	right := self stackIntegerValue: 2.
	left := self stackIntegerValue: 3.
	self displayBitsOf: (self splObj: TheDisplay) Left: left Top: top Right: right Bottom: bottom.
	self successful
		ifTrue: [self ioForceDisplayUpdate.
			self pop: 4]
]

{ #category : #'process primitives' }
NewspeakInterpreter >> primitiveSignal [
"synchromously signal the semaphore. This may change the active process as a result"
	| sema |
	sema := self stackTop.  "rcvr"
	self assertClassOf: sema is: (self splObj: ClassSemaphore).
	self successful ifTrue: [ self synchronousSignal: sema ].
]

{ #category : #'memory space primitives' }
NewspeakInterpreter >> primitiveSignalAtBytesLeft [
	"Set the low-water mark for free space. When the free space 
	falls below this level, the new and new: primitives fail and 
	system attempts to allocate space (e.g., to create a method 
	context) cause the low-space semaphore (if one is 
	registered) to be signalled."
	| bytes |
	bytes := self popInteger.
	self successful
		ifTrue: [lowSpaceThreshold := bytes]
		ifFalse: [lowSpaceThreshold := 0.
			self unPop: 1]
]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveSignalAtMilliseconds [
	"Cause the time semaphore, if one has been registered, to
	be signalled when the millisecond clock is greater than or
	equal to the given tick value. A tick value of zero turns off
	timer interrupts."
	| tick sema |
	tick := self popInteger.
	sema := self popStack.
	self successful
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
NewspeakInterpreter >> primitiveSine [

	| rcvr |
	<var: #rcvr type: 'double '>
	rcvr := self popFloat.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'sin(rcvr)' inSmalltalk: [rcvr sin])]
		ifFalse: [self unPop: 1]
]

{ #category : #'array and stream primitives' }
NewspeakInterpreter >> primitiveSize [
	| rcvr sz |
	rcvr := self stackTop.
	(self isIntegerObject: rcvr) ifTrue: [^ self primitiveFail].  "Integers are not indexable"
	(self formatOf: rcvr) < 2 ifTrue: [^ self primitiveFail].  "This is not an indexable object"
	sz := self stSizeOf: rcvr.
	self successful ifTrue:
		[self pop: argumentCount + 1 thenPush: (self positive32BitIntegerFor: sz)]

]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveSnapshot [
"save a normal snapshot under the same name as it was loaded unless it has been renamed by the last primitiveImageName"
	<inline: false>
	^self snapshot: false

]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveSnapshotEmbedded [
"save an embedded snapshot"
	<inline: false>
	^self snapshot: true
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveSomeInstance [
	| class instance |
	class := self stackTop.
	instance := self initialInstanceOf: class.
	instance
		ifNil: [self primitiveFail]
		ifNotNil: [self pop: argumentCount+1 thenPush: instance]
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveSomeObject [
	"Return the first object in the heap."

	self pop: argumentCount+1.
	self push: self firstAccessibleObject.
]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveSpecialObjectsOop [
	"Return the oop of the SpecialObjectsArray."

	self pop: 1 thenPush: specialObjectsOop.
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveSquareRoot [
	| rcvr |
	<var: #rcvr type: 'double '>
	rcvr := self popFloat.
	self success: rcvr >= 0.0.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'sqrt(rcvr)' inSmalltalk: [rcvr sqrt])]
		ifFalse: [self unPop: 1]
]

{ #category : #'image segment in/out' }
NewspeakInterpreter >> primitiveStoreImageSegment [
	"This primitive is called from Squeak as...
		<imageSegment> storeSegmentFor: arrayOfRoots into: aWordArray outPointers: anArray."

"This primitive will store a binary image segment (in the same format as the Squeak image file) of the receiver and every object in its proper tree of subParts (ie, that is not refered to from anywhere else outside the tree).  All pointers from within the tree to objects outside the tree will be copied into the array of outpointers.  In their place in the image segment will be an oop equal to the offset in the outPointer array (the first would be 4). but with the high bit set."

"The primitive expects the array and wordArray to be more than adequately long.  In this case it returns normally, and truncates the two arrays to exactly the right size.  To simplify truncation, both incoming arrays are required to be 256 bytes or more long (ie with 3-word headers).  If either array is too small, the primitive will fail, but in no other case.

During operation of the primitive, it is necessary to convert from both internal and external oops to their mapped values.  To make this fast, the headers of the original objects in question are replaced by the mapped values (and this is noted by adding the forbidden XX header type).  Tables are kept of both kinds of oops, as well as of the original headers for restoration.

To be specific, there are two similar two-part tables, the outpointer array, and one in the upper fifth of the segmentWordArray.  Each grows oops from the bottom up, and preserved headers from halfway up.

In case of either success or failure, the headers must be restored.  In the event of primitive failure, the table of outpointers must also be nilled out (since the garbage in the high half will not have been discarded."

	| outPointerArray segmentWordArray arrayOfRoots ecode |

	outPointerArray := self stackTop.
	segmentWordArray := self stackValue: 1.
	arrayOfRoots := self stackValue: 2.

	"Essential type checks"
	((self isArray: arrayOfRoots)				"Must be indexable pointers"
	and: [(self isArray: outPointerArray)		"Must be indexable pointers"
	and: [self isWords: segmentWordArray]])	"Must be indexable words"
		ifFalse: [^self primitiveFail].

	ecode := self storeImageSegmentInto: segmentWordArray outPointers: outPointerArray roots: arrayOfRoots.
	ecode = PrimNoErr
		ifTrue: [self pop: 3]  "...leaving the receiver on the stack as return value"
		ifFalse: [self primitiveFailFor: ecode]
]

{ #category : #'object access primitives' }
NewspeakInterpreter >> primitiveStoreStackp [
	"Atomic store into context stackPointer. 
	Also ensures that any newly accessible cells are initialized to nil "
	| ctxt newStackp stackp |
	ctxt := self stackValue: 1.
	newStackp := self stackIntegerValue: 0.
	self success: newStackp >= 0.
	self success: newStackp <= (LargeContextSize - BaseHeaderSize // BytesPerWord - CtxtTempFrameStart).
	self successful ifFalse: [^ self primitiveFail].
	stackp := self fetchStackPointerOf: ctxt.
	newStackp > stackp ifTrue: ["Nil any newly accessible cells"
			stackp + 1 to: newStackp do: [:i | self storePointer: i + CtxtTempFrameStart - 1 ofObject: ctxt withValue: nilObj]].
	self storeStackPointerValue: newStackp inContext: ctxt.
	self pop: 1
]

{ #category : #'array and stream primitives' }
NewspeakInterpreter >> primitiveStringAt [

	self commonAt: true.
]

{ #category : #'array and stream primitives' }
NewspeakInterpreter >> primitiveStringAtPut [

	self commonAtPut: true.
]

{ #category : #'array and stream primitives' }
NewspeakInterpreter >> primitiveStringReplace [
	" 
	<array> primReplaceFrom: start to: stop with: replacement startingAt: repStart  
	<primitive: 105>
	"
	| array start stop repl replStart hdr1 hdr2 arrayFmt totalLength arrayInstSize replFmt replInstSize srcIndex |
	array := self stackValue: 4.
	start := self stackIntegerValue: 3.
	stop := self stackIntegerValue: 2.
	repl := self stackValue: 1.
	replStart := self stackIntegerValue: 0.

	self successful ifFalse: [^ self primitiveFail].
	(self isIntegerObject: repl) ifTrue: ["can happen in LgInt copy"
			^ self primitiveFail].

	hdr1 := self baseHeader: array.
	arrayFmt := hdr1 >> 8 bitAnd: 15.
	totalLength := self lengthOf: array baseHeader: hdr1 format: arrayFmt.
	arrayInstSize := self fixedFieldsOf: array format: arrayFmt length: totalLength.
	(start >= 1 and: [start - 1 <= stop and: [stop + arrayInstSize <= totalLength]])
		ifFalse: [^ self primitiveFail].

	hdr2 := self baseHeader: repl.
	replFmt := hdr2 >> 8 bitAnd: 15.
	totalLength := self lengthOf: repl baseHeader: hdr2 format: replFmt.
	replInstSize := self fixedFieldsOf: repl format: replFmt length: totalLength.
	(replStart >= 1 and: [stop - start + replStart + replInstSize <= totalLength])
		ifFalse: [^ self primitiveFail].

	"Array formats (without byteSize bits, if bytes array) must be same "
	arrayFmt < 8
		ifTrue: [arrayFmt = replFmt
				ifFalse: [^ self primitiveFail]]
		ifFalse: [(arrayFmt bitAnd: 12) = (replFmt bitAnd: 12)
				ifFalse: [^ self primitiveFail]].

	(hdr1  bitAnd: ImmutabilityBit) ~= 0 ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].

	"choose direction to copy in to prevent destroying contents if copying from self to self"
	replStart >= start
		ifTrue:
			[srcIndex := replStart + replInstSize - 1.
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
									srcIndex := srcIndex + 1]]]]
		ifFalse:
			[srcIndex := replStart + replInstSize - 1 + stop - start.
			"- 1 for 0-based access"

			arrayFmt <= 4
				ifTrue: ["pointer type objects"
					stop + arrayInstSize - 1 to: start + arrayInstSize - 1 by: -1 do:
						[:i |
						self storePointer: i ofObject: array withValue: (self fetchPointer: srcIndex ofObject: repl).
						srcIndex := srcIndex - 1]]
				ifFalse: [arrayFmt < 8
						ifTrue: ["32-bit-word type objects"
							stop + arrayInstSize - 1 to: start + arrayInstSize - 1 by: -1 do:
								[:i |
								self storeLong32: i ofObject: array withValue: (self fetchLong32: srcIndex ofObject: repl).
								srcIndex := srcIndex - 1]]
						ifFalse: ["byte-type objects"
							stop + arrayInstSize - 1 to: start + arrayInstSize - 1 by: -1 do:
								[:i |
								self storeByte: i ofObject: array withValue: (self fetchByte: srcIndex ofObject: repl).
								srcIndex := srcIndex - 1]]]].
	"We might consider  comparing stop - start to some value here and using forceInterruptCheck"

	self pop: argumentCount "leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
NewspeakInterpreter >> primitiveSubtract [

	self pop2AndPushIntegerIfOK: (self stackIntegerValue: 1) - (self stackIntegerValue: 0)
]

{ #category : #'process primitives' }
NewspeakInterpreter >> primitiveSuspend [

	| activeProc |
	activeProc := self activeProcess.
	self success: self stackTop = activeProc.
	self successful ifTrue:
		[self pop: 1 thenPush: nilObj.
		self transferTo: self wakeHighestPriority]
]

{ #category : #'process primitives' }
NewspeakInterpreter >> primitiveTerminateTo [
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
NewspeakInterpreter >> primitiveTestDisplayDepth [
	"Return true if the host OS does support the given display depth."
	| bitsPerPixel okay|
	bitsPerPixel := self stackIntegerValue: 0.
	self successful ifTrue: [okay := self ioHasDisplayDepth: bitsPerPixel].
	self successful ifTrue: [
		self pop: 2. "Pop arg+rcvr"
		self pushBool: okay].
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveTimesTwoPower [
	| rcvr arg |
	<var: #rcvr type: 'double '>
	arg := self popInteger.
	rcvr := self popFloat.
	self successful
		ifTrue: [ self pushFloat: (self cCode: 'ldexp(rcvr, arg)' inSmalltalk: [rcvr timesTwoPower: arg]) ]
		ifFalse: [ self unPop: 2 ].
]

{ #category : #'float primitives' }
NewspeakInterpreter >> primitiveTruncated [ 
	| rcvr frac trunc |
	<var: #rcvr type: 'double '>
	<var: #frac type: 'double '>
	<var: #trunc type: 'double '>
	rcvr := self popFloat.
	self successful ifTrue:
		[self cCode: 'frac = modf(rcvr, &trunc)'
			inSmalltalk: [trunc := rcvr truncated].
		self flag: #Dan.		"The ranges are INCORRECT if SmallIntegers are wider than 31 bits."
		self cCode: 'success((-1073741824.0 <= trunc) && (trunc <= 1073741823.0))'
			inSmalltalk: [self success: (trunc between: SmallInteger minVal and: SmallInteger maxVal)]].
	self successful
		ifTrue: [self cCode: 'pushInteger((sqInt) trunc)' inSmalltalk: [self pushInteger: trunc]]
		ifFalse: [self unPop: 1]
]

{ #category : #'plugin primitives' }
NewspeakInterpreter >> primitiveUnloadModule [
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
NewspeakInterpreter >> primitiveVMParameter [
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
		41 1 if the VM supports immutability, 0 otherwise
		
	Note: Thanks to Ian Piumarta for this primitive."

	| mem paramsArraySize result arg index ok |
	mem := self startOfMemory.
	paramsArraySize := 41.
	argumentCount = 0 ifTrue: [
		result := self instantiateClass: (self splObj: ClassArray) indexableSize: paramsArraySize.
		0 to: paramsArraySize - 1 do:
			[:i | self storePointerUnchecked: i ofObject: result withValue: ConstZero].
		self storePointerUnchecked: 0	ofObject: result withValue:
			(self integerObjectOf: youngStart - mem).
		self storePointerUnchecked: 1	ofObject: result withValue:
			(self integerObjectOf: freeBlock - mem).
		self storePointerUnchecked: 2	ofObject: result withValue:
			(self integerObjectOf: endOfMemory - mem).
		self storePointerUnchecked: 3	ofObject: result withValue:
			(self integerObjectOf: allocationCount).
		self storePointerUnchecked: 4	ofObject: result withValue:
			(self integerObjectOf: allocationsBetweenGCs).
		self storePointerUnchecked: 5	ofObject: result withValue:
			(self integerObjectOf: tenuringThreshold).
		self storePointerUnchecked: 6	ofObject: result withValue:
			(self integerObjectOf: statFullGCs).
		self storePointerUnchecked: 7	ofObject: result withValue:
			(self integerObjectOf: statFullGCUsecs + 500 // 1000).
		self storePointerUnchecked: 8	ofObject: result withValue:
			(self integerObjectOf: statIncrGCs).
		self storePointerUnchecked: 9	ofObject: result withValue:
			(self integerObjectOf: statIncrGCUsecs + 500 // 1000).
		self storePointerUnchecked: 10 ofObject: result withValue:
			(self integerObjectOf: statTenures).
		self storePointerUnchecked: 20 ofObject: result withValue:
			(self integerObjectOf: rootTableCount).
		self storePointerUnchecked: 21 ofObject: result withValue:
			(self integerObjectOf: statRootTableOverflows).
		self storePointerUnchecked: 22 ofObject: result withValue:
			(self integerObjectOf: extraVMMemory).
		self storePointerUnchecked: 23 ofObject: result withValue:
			(self integerObjectOf: shrinkThreshold).
		self storePointerUnchecked: 24 ofObject: result withValue:
			(self integerObjectOf: growHeadroom).
		self storePointerUnchecked: 25 ofObject: result withValue:
			(self integerObjectOf: interruptChecksEveryNms).
		self storePointerUnchecked: 26 ofObject: result withValue:
			(self integerObjectOf: statMarkCount).
		self storePointerUnchecked: 27 ofObject: result withValue:
			(self integerObjectOf: statSweepCount).
		self storePointerUnchecked: 28 ofObject: result withValue:
			(self integerObjectOf: statMkFwdCount).
		self storePointerUnchecked: 29 ofObject: result withValue:
			(self integerObjectOf: statCompMoveCount).
		self storePointerUnchecked: 30 ofObject: result withValue:
			(self integerObjectOf: statGrowMemory).
		self storePointerUnchecked: 31 ofObject: result withValue:
			(self integerObjectOf: statShrinkMemory).
		self storePointerUnchecked: 32 ofObject: result withValue:
			(self integerObjectOf: statRootTableCount).
		self storePointerUnchecked: 33 ofObject: result withValue:
			(self integerObjectOf: statAllocationCount).
		self storePointerUnchecked: 34 ofObject: result withValue:
			(self integerObjectOf: statSurvivorCount).
		self storePointerUnchecked: 35 ofObject: result withValue:
			(self integerObjectOf: statGCEndTime).
		self storePointerUnchecked: 36 ofObject: result withValue:
			(self integerObjectOf: statSpecialMarkCount).
		self storePointerUnchecked: 37 ofObject: result withValue:
			(self integerObjectOf: statIGCDeltaUsecs + 500 // 1000).
		self storePointerUnchecked: 38 ofObject: result withValue:
			(self integerObjectOf: statPendingFinalizationSignals).
		self storePointerUnchecked: 39 ofObject: result withValue:
			(self integerObjectOf: BytesPerWord).
		self storePointerUnchecked: 40 ofObject: result withValue:
			(self integerObjectOf: ImmutabilityBit ~= 0).
		self pop: 1 thenPush: result.
		^nil].

	argumentCount = 1
		ifTrue: [index := self stackTop]
		ifFalse: [argumentCount = 2
					ifTrue: [index := self stackValue: 1]
					ifFalse: [^self primitiveFail]].
	(self isIntegerObject: index) ifFalse: [^self primitiveFail].
	index := self integerValueOf: index.
	(index < 1 or: [index > paramsArraySize]) ifTrue: [^self primitiveFail].
	
	"read VM parameter"
	index = 1	ifTrue: [result := youngStart - mem].
	index = 2	ifTrue: [result := freeBlock - mem].
	index = 3	ifTrue: [result := endOfMemory - mem].
	index = 4	ifTrue: [result := allocationCount].
	index = 5	ifTrue: [result := allocationsBetweenGCs].
	index = 6	ifTrue: [result := tenuringThreshold].
	index = 7	ifTrue: [result := statFullGCs].
	index = 8	ifTrue: [result := statFullGCUsecs + 500 // 1000].
	index = 9	ifTrue: [result := statIncrGCs].
	index = 10	ifTrue: [result := statIncrGCUsecs + 500 // 1000].
	index = 11	ifTrue: [result := statTenures].
	((index >= 12) and: [index <= 20]) ifTrue: [result := 0].
	index = 21	ifTrue: [result := rootTableCount].
	index = 22	ifTrue: [result := statRootTableOverflows].
	index = 23	ifTrue: [result := extraVMMemory].
	index = 24	ifTrue: [result := shrinkThreshold].
	index = 25	ifTrue: [result := growHeadroom].
	index = 26	ifTrue: [result := interruptChecksEveryNms]. 
	index = 27	ifTrue: [result := statMarkCount]. 
	index = 28	ifTrue: [result := statSweepCount]. 
	index = 29	ifTrue: [result := statMkFwdCount]. 
	index = 30	ifTrue: [result := statCompMoveCount]. 
	index = 31	ifTrue: [result := statGrowMemory]. 
	index = 32	ifTrue: [result := statShrinkMemory]. 
	index = 33	ifTrue: [result := statRootTableCount]. 
	index = 34	ifTrue: [result := statAllocationCount]. 
	index = 35	ifTrue: [result := statSurvivorCount]. 
	index = 36  	ifTrue: [result := statGCEndTime]. 
	index = 37  	ifTrue: [result := statSpecialMarkCount]. 
	index = 38  	ifTrue: [result := statIGCDeltaUsecs + 500 // 1000]. 
	index = 39  	ifTrue: [result := statPendingFinalizationSignals]. 
	index = 40  	ifTrue: [result := BytesPerWord].
	index = 41  	ifTrue: [result := ImmutabilityBit ~= 0].
	argumentCount = 1 ifTrue:
		[self pop: 2 thenPush: (self integerObjectOf: result).
		^nil].

	"write a VM parameter"
	arg := self stackTop.
	(self isIntegerObject: arg) ifFalse: [^self primitiveFail].
	arg := self integerValueOf: arg.

	ok := false.
	index = 5 ifTrue: [
		allocationsBetweenGCs := arg.
		ok := true].
	index = 6 ifTrue: [
		tenuringThreshold := arg.
		ok := true].
	index = 23 ifTrue: [
		extraVMMemory := arg.
		ok := true].
	(index = 24 and: [arg > 0]) ifTrue:[
			shrinkThreshold := arg.
			ok := true].
	(index = 25 and: [arg > 0]) ifTrue:[
			growHeadroom := arg.
			ok := true].
	(index = 26 and: [arg > 1]) ifTrue:[
			interruptChecksEveryNms := arg.
			ok := true]. 

	ok ifTrue: [
		self pop: 3 thenPush: (self integerObjectOf: result).  "return old value"
		^ nil].

	self primitiveFail.  "attempting to write a read-only parameter"




]

{ #category : #'system control primitives' }
NewspeakInterpreter >> primitiveVMPath [
	"Return a string containing the path name of VM's directory."

	| s sz |
	sz := self vmPathSize.
	s := self instantiateClass: (self splObj: ClassByteString) indexableSize: sz.
	self vmPathGet: (s + BaseHeaderSize) Length: sz.
	self pop: 1 thenPush: s.

]

{ #category : #'process primitives' }
NewspeakInterpreter >> primitiveVMProfileSamplesInto [
	"Primitive.
	 0 args: Answer whether the VM Profiler is running or not.
	 1 arg:	Copy the sample data into the supplied argument, which must be a Bitmap
			of suitable size. Answer the number of samples copied into the buffer."
	| sampleBuffer sampleBufferAddress running bufferSize numSamples |
	<var: #bufferSize type: #long>
	<var: #sampleBufferAddress type: #'unsigned long *'>
	self cCode: 'ioNewProfileStatus(&running,&bufferSize)'
		inSmalltalk: [running := false. bufferSize := 0].
	argumentCount = 0 ifTrue:
		[^self pop: 1 thenPushBool: running].
	self success: argumentCount = 1.
	self successful ifTrue:
		[sampleBuffer := self stackObjectValue: 0.
		 self assertClassOf: sampleBuffer is: (self splObj: ClassBitmap).
		 self success: (self fetchWordLengthOf: sampleBuffer) >= bufferSize].
	self successful ifFalse:
		[^nil].
	sampleBufferAddress := self firstFixedField: sampleBuffer.
	numSamples := self cCode: 'ioNewProfileSamplesInto(sampleBufferAddress)'
						inSmalltalk: [sampleBufferAddress := sampleBufferAddress].
	self pop: argumentCount + 1 thenPushInteger: numSamples
]

{ #category : #'control primitives' }
NewspeakInterpreter >> primitiveValue [
	| blockContext blockArgumentCount initialIP |
	blockContext := self stackValue: argumentCount.
	blockArgumentCount := self argumentCountOfBlock: blockContext.
	self success: (argumentCount = blockArgumentCount
			and: [(self fetchPointer: CallerIndex ofObject: blockContext) = nilObj]).
	self successful
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
NewspeakInterpreter >> primitiveValueWithArgs [
	| argumentArray blockContext blockArgumentCount arrayArgumentCount initialIP |
	argumentArray := self popStack.
	blockContext := self popStack.
	blockArgumentCount := self argumentCountOfBlock: blockContext.
	"If the argArray isnt actually an Array we ahve to unpop the above two"
	(self isArray: argumentArray) ifFalse: [self unPop:2. ^self primitiveFail].

	self successful ifTrue: [arrayArgumentCount := self fetchWordLengthOf: argumentArray.
			self success: (arrayArgumentCount = blockArgumentCount
						and: [(self fetchPointer: CallerIndex ofObject: blockContext) = nilObj])].
	self successful
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
NewspeakInterpreter >> primitiveWait [

	| sema excessSignals activeProc |
	sema := self stackTop.  "rcvr"
	self assertClassOf: sema is: (self splObj: ClassSemaphore).
	self successful ifTrue: [
		excessSignals :=
			self fetchInteger: ExcessSignalsIndex ofObject: sema.
		excessSignals > 0 ifTrue: [
			self storeInteger: ExcessSignalsIndex
				ofObject: sema withValue: excessSignals - 1.
		] ifFalse: [
			activeProc := self activeProcess.
			self addLastLink: activeProc toList: sema.
			self transferTo: self wakeHighestPriority.
		].
	].
]

{ #category : #'process primitives' }
NewspeakInterpreter >> primitiveYield [
"primitively do the equivalent of Process>yield"
	| activeProc priority processLists processList |
	activeProc := self activeProcess.
	priority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	processLists := self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	processList := self fetchPointer: priority - 1 ofObject: processLists.

	(self isEmptyList: processList) ifFalse:[
		self addLastLink: activeProc toList: processList.
		self transferTo: self wakeHighestPriority]
]

{ #category : #'debug printing' }
NewspeakInterpreter >> print: s [
	"For testing in Smalltalk, this method should be overridden in a subclass."
	<api>
	<var: #s type: #'char *'>
	self cCode: 'printf("%s", s)'.
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printActivationNameFor: aMethod receiver: anObject isBlock: isBlock firstTemporary: maybeMessage [
	| methClass methodSel |
	<inline: false>
	isBlock ifTrue:
		[self print: '[] in '].
	methClass := self findClassOfMethod: aMethod forReceiver: anObject.
	methodSel := self findSelectorOfMethod: aMethod forReceiver: anObject.
	(self addressCouldBeOop: anObject)
		ifTrue:
			[(self fetchClassOf: anObject) = methClass
				ifTrue: [self printNameOfClass: methClass count: 5]
				ifFalse:
					[self printNameOfClass: (self fetchClassOf: anObject) count: 5.
					 self print: '('.
					 self printNameOfClass: methClass count: 5.
					 self print: ')']]
		ifFalse: [self print: 'INVALID RECEIVER'].
	self print: '>'.
	(self addressCouldBeOop: methodSel)
		ifTrue:
			[methodSel = self nilObject
				ifTrue: [self print: '?']
				ifFalse: [self printStringOf: methodSel]]
		ifFalse: [self print: 'INVALID SELECTOR'].
	(methodSel = (self splObj: SelectorDoesNotUnderstand)
	and: [(self addressCouldBeObj: maybeMessage)
	and: [(self fetchClassOf: maybeMessage) = (self splObj: ClassMessage)]]) ifTrue:
		["print arg message selector"
		methodSel := self fetchPointer: MessageSelectorIndex ofObject: maybeMessage.
		self print: ' '.
		self printStringOf: methodSel]
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printAllStacks [
	"Print all the stacks of all running processes, including those that are currently suspended."
	<api>
	| oop classObj proc semaphoreClass schedLists processList |
	<inline: false>
	proc := self activeProcess.
	self printNameOfClass: (self fetchClassOf: proc) count: 5; space; printHex: proc.
	self print: ' priority '; printNum: (self quickFetchInteger: PriorityIndex ofObject: proc); cr.
	self printContextCallStackOf: activeContext.
	semaphoreClass := self classSemaphore.
	oop := self firstObject.
	[self oop: oop isLessThan: freeBlock] whileTrue:
		[classObj := self fetchClassOfNonImm: oop.
		 (classObj = semaphoreClass) ifTrue:
			[self printProcsOnList: oop].
		 oop := self objectAfter: oop].
	schedLists := self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	(self fetchWordLengthOf: schedLists) - 1 to: 0 by: -1 do:
		[:pri|
		processList := self fetchPointer: pri ofObject: schedLists.
		(self isEmptyList: processList) ifFalse:
			[self cr; print: 'processes at priority '; printNum: pri + 1.
			 self printProcsOnList: processList]]
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printCallStack [
	<inline: false>
	<returnTypeC: #void>
	self printCallStackOf: activeContext
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printCallStackOf: aContextOrProcess [

	| ctxt home message methodSel |
	<inline: false>
	((self isContext: aContextOrProcess) not
	and: [(self lengthOf: aContextOrProcess) > MyListIndex
	and: [self isContext: (self fetchPointer: SuspendedContextIndex
									ofObject: aContextOrProcess)]]) ifTrue:
		[^self printCallStackOf: (self fetchPointer: SuspendedContextIndex
									ofObject: aContextOrProcess)].
	ctxt := aContextOrProcess.
	[ctxt = nilObj] whileFalse:
		[home := self findHomeForContext: ctxt.
		self printNum: ctxt.
		self space.
		self printActivationNameFor: (self fetchPointer: MethodIndex ofObject: home)
			receiver: (self fetchPointer: ReceiverIndex ofObject: home)
			isBlock: home ~= ctxt
			firstTemporary: (self fetchPointer: 0 + CtxtTempFrameStart ofObject: home).
		methodSel := self findSelectorOfMethod: (self fetchPointer: MethodIndex ofObject: home)
							forReceiver: (self fetchPointer: ReceiverIndex ofObject: home).
		methodSel = (self splObj: SelectorDoesNotUnderstand) ifTrue:
			"print arg message selector"
			[message := self fetchPointer: 0 + TempFrameStart ofObject: home.
			methodSel := self fetchPointer: MessageSelectorIndex ofObject: message.
			self print: ' '.
			self printStringOf: methodSel].
		 self cr.
		 ctxt := (self fetchPointer: SenderIndex ofObject: ctxt)]
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printChar: aByte [
	<api>
	"For testing in Smalltalk, this method should be overridden in a subclass."
	self putchar: aByte.
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printContext: aContext [
	| sender ip sp na spc |
	<api>
	<inline: false>
	self shortPrintContext: aContext.
	sender := self fetchPointer: SenderIndex ofObject: aContext.
	ip := self fetchPointer: InstructionPointerIndex ofObject: aContext.
	self print: 'sender   '; shortPrintOop: sender.
	self print: 'ip       '; printNum: ip; print: ' ('; printNum: (self integerValueOf: ip); space; printHex: (self integerValueOf: ip); printChar: $); cr.
	sp := self fetchPointer: StackPointerIndex ofObject: aContext.
	self print: 'sp       '; printNum: sp; print: ' ('; printNum: (self integerValueOf: sp); printChar: $); cr.
	(self isMethodContext: aContext)
		ifTrue:
			[self print: 'method   '; shortPrintOop: (self fetchPointer: MethodIndex ofObject: aContext).
			self print: 'closure  '; shortPrintOop: (self fetchPointer: ClosureIndex ofObject: aContext).
			self print: 'receiver '; shortPrintOop: (self fetchPointer: ReceiverIndex ofObject: aContext)]
		ifFalse:
			[na := self fetchPointer: BlockArgumentCountIndex ofObject: aContext.
			self print: 'numargs  '; printNum: na; print: ' ('; printNum: (self integerValueOf: na); printChar: $); cr.
			spc := self fetchPointer: InitialIPIndex ofObject: aContext.
			self print: 'startpc  '; printNum: spc; print: ' ('; printNum: (self integerValueOf: spc); printChar: $); cr.
			self print: 'home     '; shortPrintOop: (self fetchPointer: HomeIndex ofObject: aContext)].
	sp := self integerValueOf: sp.
	sp := sp min: (self lengthOf: aContext) - ReceiverIndex.
	1 to: sp do:
		[:i|
		self print: '       '; printNum: i; space; shortPrintOop: (self fetchPointer: ReceiverIndex + i ofObject: aContext)]
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printContext: aContext WithSP: theSP [
	| sender ip na spc sp |
	<api>
	<inline: false>
	self shortPrintContext: aContext.
	sender := self fetchPointer: SenderIndex ofObject: aContext.
	ip := self fetchPointer: InstructionPointerIndex ofObject: aContext.
	sp := self integerObjectOf: (self stackPointerIndexFor: theSP context: aContext) - ReceiverIndex.
	self print: 'sender   '; shortPrintOop: sender.
	self print: 'ip       '; printNum: ip; print: ' ('; printNum: (self integerValueOf: ip); space; printHex: (self integerValueOf: ip); printChar: $); cr.
	self print: 'sp       '; printNum: sp; print: ' ('; printNum: (self integerValueOf: sp); printChar: $); cr.
	(self isMethodContext: aContext)
		ifTrue:
			[self print: 'method   '; shortPrintOop: (self fetchPointer: MethodIndex ofObject: aContext).
			self print: 'closure  '; shortPrintOop: (self fetchPointer: ClosureIndex ofObject: aContext).
			self print: 'receiver '; shortPrintOop: (self fetchPointer: ReceiverIndex ofObject: aContext)]
		ifFalse:
			[na := self fetchPointer: BlockArgumentCountIndex ofObject: aContext.
			self print: 'numargs  '; printNum: na; print: ' ('; printNum: (self integerValueOf: na); printChar: $); cr.
			spc := self fetchPointer: InitialIPIndex ofObject: aContext.
			self print: 'startpc  '; printNum: spc; print: ' ('; printNum: (self integerValueOf: spc); printChar: $); cr.
			self print: 'home     '; shortPrintOop: (self fetchPointer: HomeIndex ofObject: aContext)].
	sp := self integerValueOf: sp.
	sp := sp min: (self lengthOf: aContext) - ReceiverIndex.
	1 to: sp do:
		[:i|
		self print: '       '; printNum: i; space; shortPrintOop: (self fetchPointer: ReceiverIndex + i ofObject: aContext)]
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printContextCallStackOf: aContext [
	"Print the call stack of aContext until it links to a frame."
	| ctxt |
	<inline: false>
	ctxt := aContext.
	[ctxt = nilObj] whileFalse:
		[self shortPrintContext: ctxt.
		 ctxt := self fetchPointer: SenderIndex ofObject: ctxt].
	^ctxt
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printFloat: f [
	"For testing in Smalltalk, this method should be overridden in a subclass."
	<cmacro: '(f) printf("%g", f)'>
	self print: f
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printHex: n [
	"Print n in hex,  in the form '    0x1234', padded to a width of 10 characters
	 in 32-bits ('0x' + 8 nibbles) or 18 characters in 64-bits ('0x' + 16 nibbles)"
	<api>
	| len buf |
	<var: #buf declareC: 'char buf[35]'> "large enough for a 64-bit value in hex plus the null plus 16 spaces"
	self cCode: 'memset(buf,'' '',34)' inSmalltalk: [buf := 'doh!'].
	len := self cCode: 'sprintf(buf + 2 + 2 * BytesPerWord, "0x%lx", (unsigned long)(n))'.
	self cCode: 'printf("%s", buf + len)'.
	len touch: buf
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printHexPtr: p [
	"Print n in hex, passed to 10 characters in the form '    0x1234'"
	<inline: true>
	<var: #p type: #'void *'>
	self printHex: (self oopForPointer: p)
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printNameOfClass: classOop count: cnt [
	"Details: The count argument is used to avoid a possible infinite recursion if classOop is a corrupted object."
	<inline: false>
	(classOop = 0 or: [cnt <= 0]) ifTrue: [^self print: 'bad class'].
	((self sizeBitsOf: classOop) = metaclassSizeBits
	  and: [metaclassSizeBits > (thisClassIndex * BytesPerWord)])	"(Metaclass instSize * 4)"
		ifTrue: [self printNameOfClass: (self fetchPointer: thisClassIndex ofObject: classOop) count: cnt - 1.
				self print: ' class']
		ifFalse: [self printStringOf: (self fetchPointer: classNameIndex ofObject: classOop)]
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printNum: n [
	"For testing in Smalltalk, this method should be overridden in a subclass."

	self cCode: 'printf("%ld", (long) n)'.
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printOop: oop [
	| cls fmt lastIndex startIP bytecodesPerLine |
	<inline: false>
	self printHex: oop.
	(self isIntegerObject: oop) ifTrue:
		[^self
			cCode: 'printf("=%ld\n", (long)integerValueOf(oop))'
			inSmalltalk: [self print: (self shortPrint: oop); cr]].
	(oop between: self startOfMemory and: freeBlock) ifFalse:
		[self printHex: oop; print: ' is not on the heap'; cr.
		 ^nil].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[self printHex: oop; print: ' is misaligned'; cr.
		 ^nil].
	(self isFreeObject: oop) ifTrue:
		[self print: ' free chunk of size '; printNum: (self sizeOfFree: oop); cr.
		 ^nil].
	self print: ': a(n) '.
	self printNameOfClass: (cls := self fetchClassOfNonImm: oop) count: 5.
	cls = (self splObj: ClassFloat) ifTrue:
		[self cr; printFloat: (self dbgFloatValueOf: oop); cr.
		 ^nil].
	fmt := self formatOf: oop.
	fmt > 4 ifTrue:
		[self print: ' nbytes '; printNum: (self byteSizeOf: oop)].
	self cr.
	(fmt > 4 and: [fmt < 12]) ifTrue:
		[(self isWords: oop) ifTrue:
			[lastIndex := 64 min: ((self byteSizeOf: oop) / BytesPerWord).
			 lastIndex > 0 ifTrue:
				[1 to: lastIndex do:
					[:index|
					self space; printHex: (self fetchLong32: index - 1 ofObject: oop).
					(index \\ self elementsPerPrintOopLine) = 0 ifTrue:
						[self cr]].
				(lastIndex \\ self elementsPerPrintOopLine) = 0 ifFalse:
					[self cr]].
			^nil].
		^self printStringOf: oop; cr].
	lastIndex := 64 min: (startIP := (self lastPointerOf: oop) / BytesPerWord).
	lastIndex > 0 ifTrue:
		[1 to: lastIndex do:
			[:index|
			self cCode: 'printHex(fetchPointerofObject(index - 1, oop)); putchar('' '')'
				inSmalltalk: [self space; printHex: (self fetchPointer: index - 1 ofObject: oop); space.
							 self print: (self shortPrint: (self fetchPointer: index - 1 ofObject: oop))].
			(index \\ self elementsPerPrintOopLine) = 0 ifTrue:
				[self cr]].
		(lastIndex \\ self elementsPerPrintOopLine) = 0 ifFalse:
			[self cr]].
	(self isCompiledMethod: oop)
		ifFalse:
			[startIP > 64 ifTrue: [self print: '...'; cr]]
		ifTrue:
			[startIP := startIP * BytesPerWord + 1.
			 lastIndex := self lengthOf: oop.
			 lastIndex - startIP > 100 ifTrue:
				[lastIndex := startIP + 100].
			 bytecodesPerLine := 10.
			 startIP to: lastIndex do:
				[:index| | byte |
				byte := self fetchByte: index - 1 ofObject: oop.
				self cCode: 'printf(" %02x/%-3d", byte,byte)'
					inSmalltalk: [self space; print: (byte radix: 16); printChar: $/; printNum: byte].
				((index - startIP + 1) \\ bytecodesPerLine) = 0 ifTrue:
					[self cr]].
			((lastIndex - startIP + 1) \\ bytecodesPerLine) = 0 ifFalse:
				[self cr]]
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printOopShort: oop [
	<inline: false>
	self printOopShortInner: oop.
	self flush
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printOopShortInner: oop [
	| classOop name nameLen |
	<var: #name type: #'char *'>
	<inline: true>
	self printChar: $=.
	(self isIntegerObject: oop) ifTrue:
		[self printNum: (self integerValueOf: oop);
			printChar: $(;
			printHex: (self integerValueOf: oop);
			printChar: $).
		 ^nil].
	(oop between: self startOfMemory and: freeBlock) ifFalse:
		[self printHex: oop; print: ' is not on the heap'.
		 ^nil].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[self printHex: oop; print: ' is misaligned'.
		 ^nil].
	(self isFloatObject: oop) ifTrue:
		[self printFloat: (self dbgFloatValueOf: oop).
		 ^nil].
	classOop := self fetchClassOf: oop.
	(self sizeBitsOf: classOop) = metaclassSizeBits ifTrue:
		[self printNameOfClass: oop count: 5.
		 ^nil].
	oop = self nilObject ifTrue: [self print: 'nil'. ^nil].
	oop = self trueObject ifTrue: [self print: 'true'. ^nil].
	oop = self falseObject ifTrue: [self print: 'false'. ^nil].
	nameLen := self lengthOfNameOfClass: classOop.
	nameLen = 0 ifTrue: [self print: 'a ??'. ^nil].
	name := self nameOfClass: classOop.
	nameLen = 10 ifTrue:
		[(self str: name n: 'ByteString' cmp: 10) not "strncmp is weird" ifTrue:
			[self printChar: $"; printStringOf: oop; printChar: $".
			 ^nil].
		 (self str: name n: 'ByteSymbol' cmp: 10) not "strncmp is weird" ifTrue:
			[self printChar: $#; printStringOf: oop.
			 ^nil]].
	(nameLen = 9 and: [(self str: name n: 'Character' cmp: 9) not]) ifTrue:
		[self printChar: $$; printChar: (self integerValueOf: (self fetchPointer: 0 ofObject: oop)).
		 ^nil].
	self cCode: [self prin: 'a(n) %.*s' t: nameLen f: name]
		inSmalltalk: [self print: 'a(n) '; print: name]
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printProcessStack: aProcess [
	<api>
	<inline: false>
	| ctx |
	self cr; printNameOfClass: (self fetchClassOf: aProcess) count: 5; space; printHex: aProcess.
	self print: ' priority '; printNum: (self quickFetchInteger: PriorityIndex ofObject: aProcess); cr.
	ctx := self fetchPointer: SuspendedContextIndex ofObject: aProcess.
	ctx = nilObj ifFalse:
		[self printContextCallStackOf: ctx]
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printProcsOnList: procList [
	<api>
	<inline: false>
	| proc firstProc |
	proc := firstProc := self fetchPointer: FirstLinkIndex ofObject: procList.
	[proc = self nilObject] whileFalse:
		[self printProcessStack: proc.
		 proc := self fetchPointer: NextLinkIndex ofObject: proc.
		 proc = firstProc ifTrue:
			[self warning: 'circular process list!!'.
			 ^nil]]
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printStringOf: oop [
	| fmt cnt i |
	<inline: false>
	(self isIntegerObject: oop) ifTrue:
		[^nil].
	(oop between: self startOfMemory and: freeBlock) ifFalse:
		[^nil].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[^nil].
	fmt := self formatOf: oop.
	fmt < 8 ifTrue: [ ^nil ].

	cnt := 100 min: (self lengthOf: oop).
	i := 0.

	((self is: oop
		  instanceOf: (self splObj: ClassByteArray)
		  compactClassIndex: 0)
	or: [(self is: oop
			instanceOf: (self splObj: ClassLargePositiveInteger)
			compactClassIndex: ClassLargePositiveIntegerCompactIndex)
	or: [(self is: oop
			instanceOf: (self splObj: ClassLargeNegativeInteger)
			compactClassIndex: ClassLargeNegativeIntegerCompactIndex)]])
		ifTrue:
			[[i < cnt] whileTrue: [
				self printHex: (self fetchByte: i ofObject: oop).
				i := i + 1]]
		ifFalse:
			[[i < cnt] whileTrue: [
				self printChar: (self fetchByte: i ofObject: oop).
				i := i + 1]].
	self flush
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printUnbalancedStack: primIdx [
	<inline: false>
	self print: 'Stack unbalanced after '.
	self successful 
		ifTrue:[self print:'successful primitive '] 
		ifFalse:[self print: 'failed primitive '].
	self printNum: primIdx.
	self cr.
		
]

{ #category : #'debug printing' }
NewspeakInterpreter >> printUnbalancedStackFromNamedPrimitive [
	| lit |
	<inline: false>
	self print: 'Stack unbalanced after '.
	self successful 
		ifTrue:[self print:'successful '] 
		ifFalse:[self print: 'failed '].
	lit := self literal: 0 ofMethod: newMethod.
	self printStringOf: (self fetchPointer: 1 ofObject: lit).
	self print:' in '.
	self printStringOf: (self fetchPointer: 0 ofObject: lit).
	self cr.
		
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> push: object [

	| sp |
	self longAt: (sp := stackPointer + BytesPerWord) put: object.
	stackPointer := sp.
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushActiveContextBytecode [
	"Puts reclaimability of this context in question."

	self fetchNextBytecode.
	reclaimableContextCount := 0.
	self internalPush: activeContext.

]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> pushBool: trueOrFalse [

	trueOrFalse
		ifTrue: [ self push: trueObj ]
		ifFalse: [ self push: falseObj ].
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushClosureCopyCopiedValuesBytecode [
	"The compiler has pushed the values to be copied, if any.  Find numArgs and numCopied in the byte following.
	 Create a Closure with space for the copiedValues and pop numCopied values off the stack into the closure.
	 Set numArgs as specified, and set startpc to the pc following the block size and jump over that code."
	| newClosure numArgsNumCopied numArgs numCopied blockSize |
	BytesPerWord == 4
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
					instructionPointer: ((self oopForPointer: localIP) + 2 - (method+BaseHeaderSize))
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
NewspeakInterpreter >> pushConstantFalseBytecode [

	self fetchNextBytecode.
	self internalPush: falseObj.

]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushConstantMinusOneBytecode [

	self fetchNextBytecode.
	self internalPush: ConstMinusOne.

]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushConstantNilBytecode [

	self fetchNextBytecode.
	self internalPush: nilObj.

]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushConstantOneBytecode [

	self fetchNextBytecode.
	self internalPush: ConstOne.

]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushConstantTrueBytecode [

	self fetchNextBytecode.
	self internalPush: trueObj.

]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushConstantTwoBytecode [

	self fetchNextBytecode.
	self internalPush: ConstTwo.

]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushConstantZeroBytecode [

	self fetchNextBytecode.
	self internalPush: ConstZero.

]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushExplicitOuterSendReceiverBytecode [
"Find the appropriate implicit receiver for outer N"
	|  mClassMixin  litIndex  n anInt |
	<inline: true>
	litIndex := self fetchByte.
	anInt := self literal: litIndex.
	n := self checkedIntegerValueOf: anInt.
	self fetchNextBytecode.
	mClassMixin := self methodClassOf: method.
	self internalPush:(self 
		explicitOuterReceiver: n 
		withObject: receiver 
		withMixin: mClassMixin
		)

]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushFloat: f [

	<var: #f type: 'double '>
	self push: (self floatObjectOf: f).
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushImplicitReceiverBytecode [
	"This bytecode is used to implement outer sends in NS2/NS3. The
	 bytecode takes as an argument the literal offset of a selector. It
	 effectively finds the nearest lexically-enclosing implementation of
	 that selector by searching up the static chain of the receiver,
	 starting at the current method."
	| litIndex |
	litIndex := self fetchByte.
	self fetchNextBytecode.
	self internalPush: (self
							implicitReceiverForMixin: (self methodClassOf: method)
							implementing: (self literal: litIndex))
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> pushInteger: integerValue [
	self push: (self integerObjectOf: integerValue).
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushLiteralConstant: literalIndex [

	self internalPush: (self literal: literalIndex).
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushLiteralConstantBytecode [
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self pushLiteralConstant: (currentBytecode bitAnd: 16r1F)]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self pushLiteralConstant: (currentBytecode bitAnd: 16r1F).
			 self fetchNextBytecode]
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushLiteralVariable: literalIndex [

	self internalPush:
		(self fetchPointer: ValueIndex ofObject: (self literal: literalIndex)).
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushLiteralVariableBytecode [
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self pushLiteralVariable: (currentBytecode bitAnd: 16r1F)]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self pushLiteralVariable: (currentBytecode bitAnd: 16r1F).
			 self fetchNextBytecode]
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushNewArrayBytecode [
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
NewspeakInterpreter >> pushReceiverBytecode [

	self fetchNextBytecode.
	self internalPush: receiver.

]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushReceiverVariable: fieldIndex [

	self internalPush:
		(self fetchPointer: fieldIndex ofObject: receiver).
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushReceiverVariableBytecode [
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self pushReceiverVariable: (currentBytecode bitAnd: 16rF)]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self pushReceiverVariable: (currentBytecode bitAnd: 16rF).
			 self fetchNextBytecode]
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushRemoteTemp: index inVectorAt: tempVectorIndex [
	| tempVector |
	tempVector := self temporary: tempVectorIndex.
	self internalPush: (self fetchPointer: index ofObject: tempVector)
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushRemoteTempLongBytecode [
	| remoteTempIndex tempVectorIndex |
	remoteTempIndex := self fetchByte.
	tempVectorIndex := self fetchByte.
	self fetchNextBytecode.
	self pushRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushTemporaryVariable: temporaryIndex [

	self internalPush: (self temporary: temporaryIndex).
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> pushTemporaryVariableBytecode [
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self pushTemporaryVariable: (currentBytecode bitAnd: 16rF)]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self pushTemporaryVariable: (currentBytecode bitAnd: 16rF).
			 self fetchNextBytecode]
]

{ #category : #'image save/restore' }
NewspeakInterpreter >> putLong: aWord toFile: aFile [
	"Append aWord to aFile in this platforms 'natural' byte order.  (Bytes will be swapped, if
	necessary, when the image is read on a different platform.) Set successFlag to false if
	the write fails."

	| objectsWritten |
	<var: #aFile type: 'sqImageFile '>

	objectsWritten := self cCode: 'sqImageFileWrite(&aWord, sizeof(aWord), 1, aFile)'.
	self success: objectsWritten = 1.

]

{ #category : #processes }
NewspeakInterpreter >> putToSleep: aProcess [
	"Save the given process on the scheduler process list for its priority."

	| priority processLists processList |
	priority := self quickFetchInteger: PriorityIndex ofObject: aProcess.
	processLists := self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	processList := self fetchPointer: priority - 1 ofObject: processLists.
	self addLastLink: aProcess toList: processList.
]

{ #category : #processes }
NewspeakInterpreter >> quickCheckForInterrupts [
	"Quick check for possible user or timer interrupts. Decrement a counter and only do a real check when counter reaches zero or when a low space or user interrupt is pending."
	"Note: Clients that trigger interrupts should set use forceInterruptCheck to set interruptCheckCounter to zero and get immediate results."
	"Note: Requires that instructionPointer and stackPointer be external."

	((interruptCheckCounter := interruptCheckCounter - 1) <= 0)
		ifTrue: [self checkForInterrupts].

]

{ #category : #utilities }
NewspeakInterpreter >> quickFetchInteger: fieldIndex ofObject: objectPointer [
	"Return the integer value of the field without verifying that it is an integer value! For use in time-critical places where the integer-ness of the field can be guaranteed."

	^ self integerValueOf: (self fetchPointer: fieldIndex ofObject: objectPointer).
]

{ #category : #'image save/restore' }
NewspeakInterpreter >> readImageFromFile: f HeapSize: desiredHeapSize StartingAt: imageOffset [
	"Read an image from the given file stream, allocating the given amount of memory to its object heap. Fail if the image has an unknown format or requires more than the given amount of memory."
	"Details: This method detects when the image was stored on a machine with the opposite byte ordering from this machine and swaps the bytes automatically. Furthermore, it allows the header information to start 512 bytes into the file, since some file transfer programs for the Macintosh apparently prepend a Mac-specific header of this size. Note that this same 512 bytes of prefix area could also be used to store an exec command on Unix systems, allowing one to launch Smalltalk by invoking the image name as a command."
	"This code is based on C code by Ian Piumarta and Smalltalk code by Tim Rowledge. Many thanks to both of you!!"

	| swapBytes headerStart headerSize dataSize oldBaseAddr minimumMemory memStart bytesRead bytesToShift heapSize |
	<var: #f type: 'sqImageFile '>
	<var: #memStart type: 'usqInt'>
	<var: #desiredHeapSize type: 'usqInt'>
	<var: #headerStart type: 'squeakFileOffsetType '>
	<var: #dataSize type: 'size_t '>
	<var: #imageOffset type: 'squeakFileOffsetType '>

	metaclassSizeBits := 7 * BytesPerWord.	"guess (Metaclass instSize+1 * 4)"
	swapBytes := self checkImageVersionFrom: f startingAt: imageOffset.
	headerStart := (self sqImageFilePosition: f) - BytesPerWord.  "record header start position"

	headerSize			:= self getLongFromFile: f swap: swapBytes.
	dataSize			:= self getLongFromFile: f swap: swapBytes.
	oldBaseAddr		:= self getLongFromFile: f swap: swapBytes.
	specialObjectsOop	:= self getLongFromFile: f swap: swapBytes.
	lastHash			:= self getLongFromFile: f swap: swapBytes.
	savedWindowSize	:= self getLongFromFile: f swap: swapBytes.
	fullScreenFlag		:= self getLongFromFile: f swap: swapBytes.
	extraVMMemory	:= self getLongFromFile: f swap: swapBytes.

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
	bytesRead := self cCode: 'sqImageFileRead(pointerForOop(memory), sizeof(unsigned char), dataSize, f)'.
	bytesRead ~= dataSize ifTrue: [self unableToReadImageError].

	swapBytes ifTrue: [self reverseBytesInImage].

	"compute difference between old and new memory base addresses"
	bytesToShift := memStart - oldBaseAddr.
	self initializeInterpreter: bytesToShift.  "adjusts all oops to new location"
	^dataSize
]

{ #category : #'image save/restore' }
NewspeakInterpreter >> readableFormat: imageVersion [
	"Anwer true if images of the given format are readable by this interpreter. Allows a virtual machine to accept selected older image formats.  In our case we can select a newer (closure) image format as well as the existing format."

	^ imageVersion = self imageFormatVersion
	or: [imageVersion = self imageFormatForwardCompatibilityVersion]
"
	Example of multiple formats:
	^ (imageVersion = self imageFormatVersion) or: [imageVersion = 6504]
"
]

{ #category : #contexts }
NewspeakInterpreter >> recycleContextIfPossible: cntxOop [ 
	"If possible, save the given context on a list of free contexts to 
	be recycled."
	"Note: The context is not marked free, so it can be reused 
	with minimal fuss. The recycled context lists are cleared at 
	every garbage collect."
	| header |
	<inline: true>
	"only recycle young contexts (which should be most of them)"
	(self oop: cntxOop isGreaterThanOrEqualTo: youngStart)
		ifTrue: [header := self baseHeader: cntxOop.
			(self isMethodContextHeader: header)
				ifTrue: ["It's a young context, alright."
					(header bitAnd: SizeMask) = SmallContextSize
						ifTrue: ["Recycle small contexts"
							self storePointerUnchecked: 0 ofObject: cntxOop withValue: freeContexts.
							freeContexts := cntxOop].
					(header bitAnd: SizeMask) = LargeContextSize
						ifTrue: ["Recycle large contexts"
							self storePointerUnchecked: 0 ofObject: cntxOop withValue: freeLargeContexts.
							freeLargeContexts := cntxOop]]]
]

{ #category : #'callback support' }
NewspeakInterpreter >> reestablishContextPriorToCallback: callbackContext [
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
NewspeakInterpreter >> removeFirstLinkOfList: aList [ 
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

{ #category : #processes }
NewspeakInterpreter >> resume: aProcess [ 
	| activeProc activePriority newPriority |
	<inline: false>
	activeProc := self activeProcess.
	activePriority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	newPriority := self quickFetchInteger: PriorityIndex ofObject: aProcess.
	newPriority <= activePriority ifTrue:
		[self putToSleep: aProcess.
		 ^false].
	self putToSleep: activeProc.
	self transferTo: aProcess.
	^true
]

{ #category : #'callback support' }
NewspeakInterpreter >> returnAs: returnTypeOop ThroughCallback: vmCallbackContext Context: callbackMethodContext [
	"callbackMethodContext is an activation of invokeCallback:[stack:registers:jmpbuf:].
	 Its sender is the VM's state prior to the callback.  Reestablish that state (via longjmp),
	 and mark callbackMethodContext as dead."
	<export: true>
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
	| calloutMethodContext |
	((self isIntegerObject: returnTypeOop)
	 and: [self isContext: callbackMethodContext]) ifFalse:
		[^false].
	calloutMethodContext := self fetchPointer: SenderIndex ofObject: callbackMethodContext.
	(self isContext: calloutMethodContext) ifFalse:
		[^false].
	self newActiveContext: calloutMethodContext.
	 "N.B. siglongjmp is defines as _longjmp on non-win32 platforms.
	  This matches the use of _setjmp in ia32abicc.c."
	self siglong: vmCallbackContext trampoline jmp: (self integerValueOf: returnTypeOop).
	"NOTREACHED"
	^true
]

{ #category : #'return bytecodes' }
NewspeakInterpreter >> returnFalse [
	localReturnContext := self sender.
	localReturnValue := falseObj.
	self commonReturn.

]

{ #category : #'return bytecodes' }
NewspeakInterpreter >> returnNil [
	localReturnContext := self sender.
	localReturnValue := nilObj.
	self commonReturn.
]

{ #category : #'return bytecodes' }
NewspeakInterpreter >> returnReceiver [
	localReturnContext := self sender.
	localReturnValue := receiver.
	self commonReturn.
]

{ #category : #'return bytecodes' }
NewspeakInterpreter >> returnTopFromBlock [
	"Return to the caller of the method containing the block."
	localReturnContext := self caller.  "Note: caller, not sender!"
	localReturnValue := self internalStackTop.
	self commonReturn.
]

{ #category : #'return bytecodes' }
NewspeakInterpreter >> returnTopFromMethod [
	localReturnContext := self sender.
	localReturnValue := self internalStackTop.
	self commonReturn.
]

{ #category : #'return bytecodes' }
NewspeakInterpreter >> returnTrue [
	localReturnContext := self sender.
	localReturnValue := trueObj.
	self commonReturn.
]

{ #category : #'image save/restore' }
NewspeakInterpreter >> reverseBytesInImage [
	"Byte-swap all words in memory after reading in the entire image file with bulk read. Contributed by Tim Rowledge."

	"First, byte-swap every word in the image. This fixes objects headers."
	self reverseBytesFrom: self startOfMemory to: endOfMemory.

	"Second, return the bytes of bytes-type objects to their orginal order."
	self byteSwapByteObjects.
]

{ #category : #'I/O primitive support' }
NewspeakInterpreter >> reverseDisplayFrom: startIndex to: endIndex [ 
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
	dispBitsPtr := dispBitsPtr + BaseHeaderSize.
	dispBitsPtr + (startIndex * 4) to: dispBitsPtr + (endIndex * 4) by: 4
		do: [:ptr | 
			reversed := (self long32At: ptr) bitXor: 4294967295.
			self longAt: ptr put: reversed].
	self initPrimCall.
	self displayBitsOf: displayObj Left: 0 Top: 0 Right: w Bottom: 1.
	self ioForceDisplayUpdate
]

{ #category : #'method lookup cache' }
NewspeakInterpreter >> rewriteMethodCacheSel: selector class: class primIndex: localPrimIndex [

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
NewspeakInterpreter >> rewriteMethodCacheSel: selector class: class primIndex: localPrimIndex primFunction: localPrimAddress [
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
NewspeakInterpreter >> roomToPushNArgs: n [
	"Answer if there is room to push n arguments onto the current stack.
	 There may be room in this stackPage but there may not be room if
	 the frame were converted into a context."
	| cntxSize |
	((self headerOf: method) bitAnd: LargeContextBit) ~= 0
		ifTrue: [cntxSize := LargeContextSize / BytesPerWord - ReceiverIndex]
		ifFalse: [cntxSize := SmallContextSize / BytesPerWord - ReceiverIndex].
	^self stackPointerIndex + n <= cntxSize
]

{ #category : #processes }
NewspeakInterpreter >> saveProcessSignalingLowSpace [
	"The low space semaphore is about to be signaled. Save the currently active
	process in the special objects array so that the low space handler will be able
	to determine the process that first triggered a low space condition. The low
	space handler (in the image) is expected to nil out the special objects array
	slot when it handles the low space condition."

	| lastSavedProcess currentProc |
	lastSavedProcess := self splObj: ProcessSignalingLowSpace.
	(lastSavedProcess == self nilObject) ifTrue:
		[currentProc := self activeProcess.
		self storePointer: ProcessSignalingLowSpace ofObject: specialObjectsOop withValue: currentProc]
]

{ #category : #'process primitive support' }
NewspeakInterpreter >> schedulerPointer [

	^ self fetchPointer: ValueIndex ofObject: (self splObj: SchedulerAssociation)
]

{ #category : #'send bytecodes' }
NewspeakInterpreter >> secondExtendedSendBytecode [
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

{ #category : #'debug printing' }
NewspeakInterpreter >> selectorOfContext: aContext [
	(self isContext: aContext) ifFalse:
		[^nil].
	^self
		findSelectorOfMethod: (self fetchPointer: MethodIndex ofObject: aContext)
		forReceiver:  (self fetchPointer: ReceiverIndex ofObject: aContext)
]

{ #category : #'callback support' }
NewspeakInterpreter >> sendInvokeCallback: thunkPtr Stack: stackPtr Registers: regsPtr Jmpbuf: jmpBufPtr [
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
	lkupClass := self fetchClassOfNonImm: receiver.
	messageSelector := self splObj: SelectorInvokeCallback.
	(self lookupInMethodCacheSel: messageSelector class: lkupClass) ifFalse:
	 	[(self lookupMethodNoMNUEtcInClass: lkupClass) ifFalse:
			[^false]].
	((self argumentCountOf: newMethod) = 4
	and: [primitiveFunctionPointer = 0]) ifFalse:
		[^false].
	self storeContextRegisters: activeContext.
	self justActivateNewMethod.
	where := activeContext + BaseHeaderSize + (ReceiverIndex << ShiftForWord).
	self longAt: where + (1 << ShiftForWord) put: self popRemappableOop.
	self longAt: where + (2 << ShiftForWord) put: self popRemappableOop.
	self longAt: where + (3 << ShiftForWord) put: self popRemappableOop.
	self longAt: where + (4 << ShiftForWord) put: self popRemappableOop.
	self interpret.
	"not reached"
	^true
]

{ #category : #'callback support' }
NewspeakInterpreter >> sendInvokeCallbackContext: vmCallbackContext [
	"Send the calllback message to Alien class with the supplied arg(s).  Use either the
	 1 arg invokeCallbackContext: or the 4 arg invokeCallback:stack:registers:jmpbuf:
	 message, depending on what selector is installed in the specialObjectsArray.
	 Note that if invoking the legacy invokeCallback:stack:registers:jmpbuf: we pass the
	 vmCallbackContext as the jmpbuf argument (see reestablishContextPriorToCallback:).
	 The arguments are raw C addresses and are converted to integer objects on the way."
	<export: true>
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
	| relativeSP |
	receiver := self splObj: ClassAlien.
	lkupClass := self fetchClassOfNonImm: receiver.
	messageSelector := self splObj: SelectorInvokeCallback.
	(self lookupInMethodCacheSel: messageSelector class: lkupClass) ifFalse:
	 	[(self lookupMethodNoMNUEtcInClass: lkupClass) ~= 0 ifTrue:
			[^false]].
	primitiveFunctionPointer ~= 0 ifTrue:
		[^false].
	self storeContextRegisters: activeContext.
	self justActivateNewMethod.
	relativeSP := stackPointer - activeContext.
	stackPointer := activeContext + BaseHeaderSize + (ReceiverIndex * BytesPerWord).
	self cppIf: BytesPerWord = 8
		ifTrue:
			[(self argumentCountOf: newMethod) = 4 ifTrue:
				[self push: (self positive64BitIntegerFor: vmCallbackContext thunkp asUnsignedInteger).
				 self push: (self positive64BitIntegerFor: vmCallbackContext stackp asUnsignedInteger).
				 self push: (self positive64BitIntegerFor: vmCallbackContext intregargsp asUnsignedInteger)].
			 self push: (self positive64BitIntegerFor: vmCallbackContext asUnsignedInteger)]
		ifFalse:
			[(self argumentCountOf: newMethod) = 4 ifTrue:
				[self push: (self positive32BitIntegerFor: vmCallbackContext thunkp asUnsignedInteger).
				 self push: (self positive32BitIntegerFor: vmCallbackContext stackp asUnsignedInteger).
				 self push: (self positive32BitIntegerFor: vmCallbackContext intregargsp asUnsignedInteger)].
			 self push: (self positive32BitIntegerFor: vmCallbackContext asUnsignedInteger)].
	stackPointer := activeContext + relativeSP.
	self assert: (self validInstructionPointer: instructionPointer inMethod: method).
	self interpret.
	"not reached"
	^true
]

{ #category : #'send bytecodes' }
NewspeakInterpreter >> sendLiteralSelector0ArgsBytecode [
	"Can use any of the first 16 literals for the selector."
	| rcvr |
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := 0.
	rcvr := self internalStackValue: 0.
	lkupClass := self fetchClassOf: rcvr.
	self commonSend
]

{ #category : #'send bytecodes' }
NewspeakInterpreter >> sendLiteralSelector1ArgBytecode [
	"Can use any of the first 16 literals for the selector."
	| rcvr |
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := 1.
	rcvr := self internalStackValue: 1.
	lkupClass := self fetchClassOf: rcvr.
	self commonSend
]

{ #category : #'send bytecodes' }
NewspeakInterpreter >> sendLiteralSelector2ArgsBytecode [
	"Can use any of the first 16 literals for the selector."
	| rcvr |
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := 2.
	rcvr := self internalStackValue: 2.
	lkupClass := self fetchClassOf: rcvr.
	self commonSend
]

{ #category : #'send bytecodes' }
NewspeakInterpreter >> sendLiteralSelectorBytecode [
	"Can use any of the first 16 literals for the selector and pass up to 2 arguments."
	<expandCases>
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := ((currentBytecode >> 4) bitAnd: 3) - 1.
	self normalSend
]

{ #category : #'debug support' }
NewspeakInterpreter >> sendTraceLogIndex: aValue [
	<cmacro: '(aValue) (GIV(sendTraceLogIndex) = (aValue))'>
	"N.B. sendTraceLogIndex is 8-bits"
	^sendTraceLogIndex := aValue bitAnd: 16rFF
]

{ #category : #contexts }
NewspeakInterpreter >> sender [

	| context closureOrNil |
	context := localHomeContext.
	[(closureOrNil := self fetchPointer: ClosureIndex ofObject: context) ~~ nilObj] whileTrue:
		[context := self fetchPointer: ClosureOuterContextIndex ofObject: closureOrNil].
	^self fetchPointer: SenderIndex ofObject: context
]

{ #category : #'debug support' }
NewspeakInterpreter >> setBreakSelector: aString [
	<api>
	<var: #aString type: #'char *'>
	aString isNil
		ifTrue: [breakSelectorLength := -1. "nil's effective length is zero" breakSelector := nil]
		ifFalse: [breakSelectorLength := self strlen: aString. breakSelector := aString]
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> setFullScreenFlag: value [
	fullScreenFlag := value
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> setInterruptCheckCounter: value [
	interruptCheckCounter := value
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> setInterruptKeycode: value [
	interruptKeycode := value
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> setInterruptPending: value [
	interruptPending := value
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> setNextWakeupTick: value [
	nextWakeupTick := value
]

{ #category : #'plugin primitive support' }
NewspeakInterpreter >> setSavedWindowSize: value [
	savedWindowSize := value
]

{ #category : #'jump bytecodes' }
NewspeakInterpreter >> shortConditionalJump [

	self jumplfFalseBy: (currentBytecode bitAnd: 7) + 1.
]

{ #category : #'debug printing' }
NewspeakInterpreter >> shortPrintContext: aContext [
	| home |
	<api>
	<inline: false>
	(self isContext: aContext) ifFalse:
		[self printHex: aContext; print: ' is not a context'; cr.
		^nil].
	home := self findHomeForContext: aContext.
	self printNum: aContext.
	self space.
	self printActivationNameFor: (self fetchPointer: MethodIndex ofObject: home)
		receiver: (self fetchPointer: ReceiverIndex ofObject: home)
		isBlock: home ~= aContext
		firstTemporary: (self fetchPointer: 0 + CtxtTempFrameStart ofObject: home).
	self cr
]

{ #category : #'debug printing' }
NewspeakInterpreter >> shortPrintOop: oop [
	<inline: false>
	self printHex: oop.
	(self isIntegerObject: oop) ifTrue:
		[^self cCode: 'printf("=%ld\n", (long)integerValueOf(oop))' inSmalltalk: [self print: (self shortPrint: oop); cr]].
	(oop between: self startOfMemory and: freeBlock) ifFalse:
		[self printHex: oop; print: ' is not on the heap'; cr.
		 ^nil].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[self printHex: oop; print: ' is misaligned'; cr.
		 ^nil].
	self print: ': a(n) '.
	self printNameOfClass: (self fetchClassOf: oop) count: 5.
	self cr
]

{ #category : #'jump bytecodes' }
NewspeakInterpreter >> shortUnconditionalJump [
	<expandCases>
	self jump: (currentBytecode bitAnd: 7) + 1.
]

{ #category : #'I/O primitive support' }
NewspeakInterpreter >> showDisplayBits: aForm Left: l Top: t Right: r Bottom: b [
	"Repaint the portion of the Smalltalk screen bounded by the affected rectangle. Used to synchronize the screen after a Bitblt to the Smalltalk Display object."
	deferDisplayUpdates ifTrue: [^ nil].
	self displayBitsOf: aForm Left: l Top: t Right: r Bottom: b
]

{ #category : #utilities }
NewspeakInterpreter >> signExtend16: int16 [
	"Convert a signed 16-bit integer into a signed 32-bit integer value. The integer bit is not added here."

	(int16 bitAnd: 16r8000) = 0
		ifTrue: [ ^ int16 ]
		ifFalse: [ ^ int16 - 16r10000 ].
]

{ #category : #'process primitive support' }
NewspeakInterpreter >> signalExternalSemaphores [
	"Signal all requested semaphores.  Answer if a context switch has occurred."
	| xArray |
	xArray := self splObj: ExternalObjectsArray.
	^self doSignalExternalSemaphores: (self stSizeOf: xArray)
]

{ #category : #'process primitive support' }
NewspeakInterpreter >> signalFinalization: weakReferenceOop [
	"If it is not there already, record the given semaphore index in the list of semaphores to be signaled at the next convenient moment. Force a real interrupt check as soon as possible."

	self forceInterruptCheck.
	pendingFinalizationSignals := pendingFinalizationSignals + 1.
]

{ #category : #processes }
NewspeakInterpreter >> signalNoResume: aSemaphore [
	"Signal the given semaphore from within the interpreter.  Used to serialize callbacks."
	| empty |
	<api>
	<inline: false>
	empty := self isEmptyList: aSemaphore. 
	empty ifFalse:
		[self putToSleep: (self removeFirstLinkOfList: aSemaphore)].
	^empty
]

{ #category : #'primitive support' }
NewspeakInterpreter >> signed32BitIntegerFor: integerValue [
	"Return a full 32 bit integer object for the given integer value"
	| newLargeInteger value largeClass |
	<inline: false>
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
NewspeakInterpreter >> signed32BitValueOf: oop [
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
	value < 0 ifTrue:
		[self assert: (self sizeof: value) == 4.
		 "Don't fail for -16r80000000/-2147483648
		  Alas the simple (negative and: [value - 1 > 0]) isn't adequate since in C the result of signed integer
		  overflow is undefined and hence under optimization this may fail.  The shift, however, is well-defined."
		 (negative and: [0 = (self cCode: [value << 1]
									inSmalltalk: [value << 1 bitAnd: (1 << 32) - 1])]) ifTrue: 
			[^value].
		 ^self primitiveFail].
	^negative
		ifTrue: [0 - value]
		ifFalse: [value]
]

{ #category : #'primitive support' }
NewspeakInterpreter >> signed64BitIntegerFor: integerValue [
	"Return a Large Integer object for the given integer value"
	| newLargeInteger magnitude largeClass intValue highWord sz |
	<inline: false>
	<var: 'integerValue' type: #sqLong>
	<var: 'magnitude' type: #sqLong>
	<var: 'highWord' type: #usqInt>

	integerValue < 0
		ifTrue: [largeClass := self classLargeNegativeInteger.
				magnitude := 0 - integerValue]
		ifFalse: [largeClass := self classLargePositiveInteger.
				magnitude := integerValue].

	"Make sure to handle the most -ve value correctly.
	 0 - most -ve = most -ve and most -ve - 1 is +ve"
	(magnitude <= 16r7FFFFFFF
	 and: [integerValue >= 0 or: [integerValue - 1 < 0]]) ifTrue:
		[^self signed32BitIntegerFor: integerValue].

	highWord := magnitude >> 32.
	highWord = 0 
		ifTrue:[sz := 4] 
		ifFalse:
			[sz := 5.
			(highWord := highWord >> 8) = 0 ifFalse:[sz := sz + 1].
			(highWord := highWord >> 8) = 0 ifFalse:[sz := sz + 1].
			(highWord := highWord >> 8) = 0 ifFalse:[sz := sz + 1]].
	newLargeInteger := self instantiateClass: largeClass indexableSize:  sz.
	0 to: sz-1 do: [:i |
		intValue := (magnitude >> (i * 8)) bitAnd: 255.
		self storeByte: i ofObject: newLargeInteger withValue: intValue].
	^newLargeInteger
]

{ #category : #'primitive support' }
NewspeakInterpreter >> signed64BitValueOf: oop [
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
	value < 0 ifTrue:
		[self cCode:
			[self assert: (self sizeof: value) == 8.
			 self assert: (self sizeof: value << 1) == 8].
		"Don't fail for -9223372036854775808/-16r8000000000000000.
		 Alas the simple (negative and: [value - 1 > 0]) isn't adequate since in C the result of signed integer
		  overflow is undefined and hence under optimization this may fail.  The shift, however, is well-defined."
		 (negative and: [0 = (self cCode: [value << 1]
									inSmalltalk: [value << 1 bitAnd: (1 << 64) - 1])]) ifTrue: 
			[^value].
		 ^self primitiveFail].
	^negative
		ifTrue:[0 - value]
		ifFalse:[value]
]

{ #category : #'primitive support' }
NewspeakInterpreter >> signedMachineIntegerValueOf: oop [
	"Answer a signed value of an integer up to the size of a machine word.
	The object may be either a positive SmallInteger or a LargeInteger of size <= word size."
	<returnTypeC: #'long'>
	| negative ok bs value bits |
	<var: #value type: #long>
	(self isIntegerObject: oop) ifTrue:
		[^self integerValueOf: oop].

	ok := self isClassOfNonImm: oop
					equalTo: (self splObj: ClassLargePositiveInteger)
					compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	ok
		ifTrue: [negative := false]
		ifFalse:
			[negative := true.
			 ok := self isClassOfNonImm: oop
							equalTo: (self splObj: ClassLargeNegativeInteger)
							compactClassIndex: ClassLargeNegativeIntegerCompactIndex.
			ok ifFalse: [^self primitiveFail]].
	(bs := self lengthOf: oop) > (self sizeof: #'unsigned long') ifTrue:
		[^self primitiveFail].

	((self sizeof: #'unsigned long') = 8
	 and: [bs > 4])
		ifTrue:
			[value :=   (self fetchByte: 0 ofObject: oop)
					+ ((self fetchByte: 1 ofObject: oop) <<  8)
					+ ((self fetchByte: 2 ofObject: oop) << 16)
					+ ((self fetchByte: 3 ofObject: oop) << 24)
					+ ((self fetchByte: 4 ofObject: oop) << 32)
					+ ((self fetchByte: 5 ofObject: oop) << 40)
					+ ((self fetchByte: 6 ofObject: oop) << 48)
					+ ((self fetchByte: 7 ofObject: oop) << 56)]
		ifFalse:
			[value :=   (self fetchByte: 0 ofObject: oop)
					+ ((self fetchByte: 1 ofObject: oop) <<  8)
					+ ((self fetchByte: 2 ofObject: oop) << 16)
					+ ((self fetchByte: 3 ofObject: oop) << 24)].

	
	self cCode: []
		inSmalltalk:
			[bits := (self sizeof: #long) * 8.
			 (value bitShift: 1 - bits) > 0 ifTrue:
				[value := value - (1 bitShift: bits)]].
	value < 0 ifTrue:
		["Don't fail for -16r80000000[00000000].
		  Alas the simple (negative and: [value - 1 > 0]) isn't adequate since in C the result of signed integer
		  overflow is undefined and hence under optimization this may fail.  The shift, however, is well-defined."
		 (negative and: [0 = (self cCode: [value << 1]
									inSmalltalk: [value << 1 bitAnd: (1 << bits) - 1])]) ifTrue: 
			[^value].
		 ^self primitiveFail].
	^negative
		ifTrue: [0 - value]
		ifFalse: [value]
]

{ #category : #'send bytecodes' }
NewspeakInterpreter >> singleExtendedSendBytecode [
	"Can use any of the first 32 literals for the selector and pass up to 7 arguments."

	| descriptor |
	descriptor := self fetchByte.
	messageSelector := self literal: (descriptor bitAnd: 16r1F).
	argumentCount := descriptor >> 5.
	self normalSend.
]

{ #category : #'send bytecodes' }
NewspeakInterpreter >> singleExtendedSuperBytecode [
	"Can use any of the first 32 literals for the selector and pass up to 7 arguments."

	| descriptor |
	descriptor := self fetchByte.
	messageSelector := self literal: (descriptor bitAnd: 16r1F).
	argumentCount := descriptor >> 5.
	self superclassSend.

]

{ #category : #'primitive support' }
NewspeakInterpreter >> sizeFieldOfAlien: alienObj [
	"Answer the first field of alienObj which is assumed to be an Alien of at least 8 bytes"
	<inline: true>
	^self longAt: alienObj + BaseHeaderSize
]

{ #category : #'primitive support' }
NewspeakInterpreter >> sizeOfAlienData: oop [
	"Answer the start of the Alien's data or fail if oop is not an Alien."
	<api>
	<returnTypeC: #usqInt>
	| size |
	(self is: oop KindOfClass: (self splObj: ClassAlien)) ifFalse:
		[self primitiveFailFor: PrimErrBadArgument.
		 ^0].
	size := self sizeFieldOfAlien: oop.
	^size abs
]

{ #category : #utilities }
NewspeakInterpreter >> sizeOfSTArrayFromCPrimitive: cPtr [
	"Return the number of indexable fields of the given object. This method is to be called from an automatically generated C primitive. The argument is assumed to be a pointer to the first indexable field of a words or bytes object; the object header starts 4 bytes before that."
	"Note: Only called by translated primitive code."

	| oop |
	<var: #cPtr type: 'void *'>
	oop := (self oopForPointer: cPtr) - BaseHeaderSize.
	(self isWordsOrBytes: oop) ifFalse: [
		self primitiveFail.
		^0].
	^self lengthOf: oop

]

{ #category : #'primitive support' }
NewspeakInterpreter >> slowPrimitiveResponse [
	"NB: tpr removed the timer checks here and moved them to the primitiveExternalCall method.
	We make the possibly unwarranted assumption that numbered prims are quick and external prims are slow."

	| nArgs deltaIfSuccess savedContext |
	<inline: true>
	FailImbalancedPrimitives ifTrue:
		[savedContext := activeContext.
		 nArgs := argumentCount.
		 deltaIfSuccess := stackPointer - (argumentCount * BytesPerOop) - activeContext].
	self fastLogPrim: messageSelector.
	self initPrimCall.
	self dispatchFunctionPointer: primitiveFunctionPointer.
	(FailImbalancedPrimitives
	and: [self successful
	and: [savedContext = activeContext]]) ifTrue:"Don't fail if primitive has done something radical, e.g. perform:"
		[stackPointer - activeContext ~= deltaIfSuccess ifTrue:
			[self flag: 'Would be nice to make this a message send of e.g. unbalancedPrimitive to the current process or context'.
			 self warning: 'failing primitive due to unbalanced stack'.
			 "This is necessary but insufficient; the result may still have been written to the stack.
			   At least we'll know something is wrong."
			 stackPointer := activeContext + deltaIfSuccess + (nArgs * BytesPerOop).
			 self failUnbalancedPrimitive]].
	^ self successful
]

{ #category : #'image save/restore' }
NewspeakInterpreter >> snapshot: embedded [ 
	"update state of active context"
	| activeProc dataSize rcvr setMacType |
	<var: #setMacType type: 'void *'>
	self storeContextRegisters: activeContext.

	"update state of active process"
	activeProc := self activeProcess.
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
	self successful ifTrue:
		[rcvr := self popStack.
		"pop rcvr"
		self push: trueObj.
		self writeImageFile: dataSize.
		embedded ifFalse:
			["set Mac file type and creator; this is a noop on other platforms"
			setMacType := self ioLoadFunction: 'setMacFileTypeAndCreator' From: 'FilePlugin'.
			setMacType = 0 ifFalse:
				[self cCode: '((sqInt (*)(char *, char *, char *))setMacType)(imageName, "STim", "FAST")']].
		self pop: 1].

	"activeContext was unmarked in #snapshotCleanUp, mark it old "
	self beRootIfOld: activeContext.
	self successful
		ifTrue: [self push: falseObj]
		ifFalse: [self push: rcvr]
]

{ #category : #'image save/restore' }
NewspeakInterpreter >> snapshotCleanUp [
	"Clean up right before saving an image, sweeping memory and:
	* nilling out all fields of contexts above the stack pointer. 
	* flushing external primitives 
	* clearing the root bit of any object in the root table "
	| oop header fmt sz |
	oop := self firstObject.
	[oop < endOfMemory]
		whileTrue: [(self isFreeObject: oop)
				ifFalse: [header := self longAt: oop.
					fmt := header >> 8 bitAnd: 15.
					"Clean out context"
					(fmt = 3 and: [self isContextHeader: header])
						ifTrue: [sz := self sizeBitsOf: oop.
							(self lastPointerOf: oop) + BytesPerWord
								to: sz - BaseHeaderSize by: BytesPerWord
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

{ #category : #'debug printing' }
NewspeakInterpreter >> space [
	<inline: true>
	self printChar: $ 
]

{ #category : #'message sending' }
NewspeakInterpreter >> specialSelector: index [

	^ self fetchPointer: (index * 2) ofObject: (self splObj: SpecialSelectors)
]

{ #category : #'indexing primitive support' }
NewspeakInterpreter >> stObject: array at: index [
	"Return what ST would return for <obj> at: index."

	| hdr fmt totalLength fixedFields stSize |
	<inline: false>
	hdr := self baseHeader: array.
	fmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: array baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: array format: fmt length: totalLength.
	(fmt = 3 and: [self isContextHeader: hdr])
		ifTrue: [stSize := self fetchStackPointerOf: array]
		ifFalse: [stSize := totalLength - fixedFields].
	((self oop: index isGreaterThanOrEqualTo: 1)
	 and: [self oop: index isLessThanOrEqualTo: stSize]) ifTrue:
		[^self subscript: array with: (index + fixedFields) format: fmt].
	self primitiveFailFor: (fmt <= 1 ifTrue: [PrimErrBadReceiver] ifFalse: [PrimErrBadIndex]).
	^0
]

{ #category : #'indexing primitive support' }
NewspeakInterpreter >> stObject: array at: index put: value [
	"Do what ST would return for <obj> at: index put: value."
	| hdr fmt totalLength fixedFields stSize |
	<inline: false>
	hdr := self baseHeader: array.
	fmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: array baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: array format: fmt length: totalLength.
	(fmt = 3 and: [self isContextHeader: hdr])
		ifTrue: [stSize := self fetchStackPointerOf: array]
		ifFalse: [stSize := totalLength - fixedFields].
	((self oop: index isGreaterThanOrEqualTo: 1)
	 and: [self oop: index isLessThanOrEqualTo: stSize])
		ifTrue: [self subscript: array with: (index + fixedFields) storing: value format: fmt]
		ifFalse: [self primitiveFailFor: (fmt <= 1 ifTrue: [PrimErrBadReceiver] ifFalse: [PrimErrBadIndex])].
	^value
]

{ #category : #'indexing primitive support' }
NewspeakInterpreter >> stSizeOf: oop [
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

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> stackFloatValue: offset [
	<returnTypeC: #double>
	^self floatValueOf: (self longAt: stackPointer - (offset*BytesPerWord))
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> stackIntegerValue: offset [
	| integerPointer |
	integerPointer := self longAt: stackPointer - (offset*BytesPerWord).
	^self checkedIntegerValueOf: integerPointer
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> stackObjectValue: offset [
	"Ensures that the given object is a real object, not a SmallInteger."

	| oop |
	oop := self longAt: stackPointer - (offset * BytesPerWord).
	(self isIntegerObject: oop) ifTrue: [self primitiveFail. ^ nil].
	^ oop

]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> stackPointerIndex [
	"Return the 0-based index rel to the current context.
	(This is what stackPointer used to be before conversion to pointer"
	<inline: true>
	^self stackPointerIndexFor: stackPointer context: activeContext
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> stackPointerIndexFor: sp context: ctxt [
	"Return the 0-based index rel to the current context.
	(This is what stackPointer used to be before conversion to pointer"
	<api>
	<inline: true>
	^ (sp - ctxt - BaseHeaderSize) >> ShiftForWord
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> stackPositiveMachineIntegerValue: offset [
	<api>
	| integerPointer |
	integerPointer := self longAt: stackPointer - (offset*BytesPerWord).
	^self positiveMachineIntegerValueOf: integerPointer
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> stackSignedMachineIntegerValue: offset [
	<api>
	| integerPointer |
	integerPointer := self longAt: stackPointer - (offset*BytesPerWord).
	^self signedMachineIntegerValueOf: integerPointer
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> stackTop [
	^self longAt: stackPointer
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> stackValue: offset [
	^ self longAt: stackPointer - (offset*BytesPerWord)
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> stackValue: offset put: oop [
	^self longAt: stackPointer - (offset*BytesPerWord)
		put: oop
]

{ #category : #'primitive support' }
NewspeakInterpreter >> startOfAlienData: oop [
	"Answer the start of the Alien's data or fail if oop is not an Alien."
	<api>
	<returnTypeC: #'void *'>
	(self is: oop KindOfClass: (self splObj: ClassAlien)) ifFalse:
		[self primitiveFailFor: PrimErrBadArgument.
		 ^0].
	^self cCoerceSimple: ((self sizeFieldOfAlien: oop) > 0
						 	ifTrue: [oop + BaseHeaderSize + BytesPerOop]
							ifFalse: [self longAt: oop + BaseHeaderSize + BytesPerOop])
			to: #'void *'
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> storeAndPopReceiverVariableBytecode [
	"Note: This code uses storePointerUnchecked:ofObject:withValue: and does the 
	 store check explicitly in order to help the translator produce better code."
	| rcvr top |
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[rcvr := receiver.
			 top := self internalStackTop.
			 (self isObjImmutable: rcvr) ifTrue:
				[self internalPop: 1.
				 self internalCannotAssign: top to: receiver withIndex: (currentBytecode bitAnd: 7)].
			 "cannot fetch next bytecode until after immutability check so pc is correct (set to
			  following bytecode, not the bytecode after that) after attemptToAssign:withIndex:"
			 self fetchNextBytecode.
			 rcvr < youngStart ifTrue:
				[self possibleRootStoreInto: rcvr value: top].
			 self storePointerUnchecked: (currentBytecode bitAnd: 7) ofObject: rcvr withValue: top.
			 self internalPop: 1]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[rcvr := receiver.
			 top := self internalStackTop.
			 (self isObjImmutable: rcvr) ifTrue:
				[self internalPop: 1.
				 self internalCannotAssign: top to: receiver withIndex: (currentBytecode bitAnd: 7)].
			 rcvr < youngStart ifTrue:
				[self possibleRootStoreInto: rcvr value: top].
			 self storePointerUnchecked: (currentBytecode bitAnd: 7) ofObject: rcvr withValue: top.
			 self internalPop: 1.
			 self fetchNextBytecode]
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> storeAndPopRemoteTempLongBytecode [
	self storeRemoteTempLongBytecode.
	self internalPop: 1
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> storeAndPopTemporaryVariableBytecode [
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self storePointerUnchecked: (currentBytecode bitAnd: 7) + TempFrameStart
				ofObject: localHomeContext
				withValue: self internalStackTop.
			self internalPop: 1]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self storePointerUnchecked: (currentBytecode bitAnd: 7) + TempFrameStart
				ofObject: localHomeContext
				withValue: self internalStackTop.
			self internalPop: 1.
			self fetchNextBytecode]
]

{ #category : #contexts }
NewspeakInterpreter >> storeContextRegisters: activeCntx [
	"Note: internalStoreContextRegisters: should track changes to this method."

	"InstructionPointer is a pointer variable equal to
	method oop + ip + BaseHeaderSize
		-1 for 0-based addressing of fetchByte
		-1 because it gets incremented BEFORE fetching currentByte"

	<inline: true>
	self storePointerUnchecked: InstructionPointerIndex ofObject: activeCntx
		withValue: (self integerObjectOf: (instructionPointer - method - (BaseHeaderSize - 2))).
	self storePointerUnchecked: StackPointerIndex ofObject: activeCntx
		withValue: (self integerObjectOf: (self stackPointerIndex - TempFrameStart + 1)).

]

{ #category : #contexts }
NewspeakInterpreter >> storeInstructionPointerValue: value inContext: contextPointer [
	"Assume: value is an integerValue"

	self storePointerUnchecked: InstructionPointerIndex ofObject: contextPointer withValue: (self integerObjectOf: value).
]

{ #category : #utilities }
NewspeakInterpreter >> storeInteger: fieldIndex ofObject: objectPointer withValue: integerValue [ 
	"Note: May be called by translated primitive code."
	(self isIntegerValue: integerValue)
		ifTrue: [self storePointerUnchecked: fieldIndex ofObject: objectPointer
					withValue: (self integerObjectOf: integerValue)]
		ifFalse: [self primitiveFail]
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> storeRemoteTemp: index inVectorAt: tempVectorIndex [
	| tempVector |
	tempVector := self temporary: tempVectorIndex.
	self storePointer: index ofObject: tempVector withValue: self internalStackTop.
]

{ #category : #'stack bytecodes' }
NewspeakInterpreter >> storeRemoteTempLongBytecode [
	| remoteTempIndex tempVectorIndex |
	remoteTempIndex := self fetchByte.
	tempVectorIndex := self fetchByte.
	self fetchNextBytecode.
	self storeRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> storeStackPointerValue: value inContext: contextPointer [
	"Assume: value is an integerValue"

	self storePointerUnchecked: StackPointerIndex ofObject: contextPointer
		withValue: (self integerObjectOf: value).
]

{ #category : #'indexing primitive support' }
NewspeakInterpreter >> subscript: array with: index format: fmt [
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

{ #category : #'indexing primitive support' }
NewspeakInterpreter >> subscript: array with: index storing: oopToStore format: fmt [ 
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
					self successful
						ifTrue: [self storeLong32: index - 1 ofObject: array
									withValue: valueToStore]]
				ifFalse: ["byte-type objects"
					(self isIntegerObject: oopToStore)
						ifFalse: [self primitiveFail].
					valueToStore := self integerValueOf: oopToStore.
					(valueToStore >= 0
							and: [valueToStore <= 255])
						ifFalse: [self primitiveFail].
					self successful
						ifTrue: [self
								storeByte: index - 1
								ofObject: array
								withValue: valueToStore]]]
]

{ #category : #'primitive support' }
NewspeakInterpreter >> success: successBoolean [
	"Set the state of the primitive failure code/success flag, iff successBoolean
	 is false. If primFailCode is non-zero a primitive has failed.  If primFailCode
	 is greater than one then its value indicates the reason for failure."

	"Use returnTypeC: #sqInt because that's the way it is defined in sq.h.
	 Use no explicit return so that Slang doesn't fail an inlining type-check when
	 a primitive with return type void uses ^self success: false to exit."
	<returnTypeC: #sqInt>
	<inline: true>
	successBoolean ifFalse:
		["Don't overwrite an error code that has already been set."
		 self successful ifTrue:
			[primFailCode := 1]]
]

{ #category : #'primitive support' }
NewspeakInterpreter >> successful [
	"Answer the state of the primitive failure code/success flag.  If
	 primFailCode is non-zero a primitive has failed.  If primFailCode
	 is greater than one then its value indicates the reason for failure."
	<inline: true>
	
	"In C, non-zero is true, so avoid computation by using not the C version."
	^self cCode: [primFailCode not] inSmalltalk: [primFailCode = 0]
]

{ #category : #'message sending' }
NewspeakInterpreter >> superclassOf: classPointer [

	^ self fetchPointer: SuperclassIndex ofObject: classPointer
]

{ #category : #'message sending' }
NewspeakInterpreter >> superclassSend [
	"Send a message to self, starting lookup with the superclass of the class containing the currently executing method."
	"Assume: messageSelector and argumentCount have been set, and that the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeNamed: 'commonSupersend' inCase: #singleExtendedSuperBytecode>
	lkupClass := self superclassOf: (self methodClassOf: method).
	self commonSend
]

{ #category : #'debug support' }
NewspeakInterpreter >> symbolicMethod: aMethod [
	<doNotGenerate>
	| ts prim |
	(ts := self transcript) ensureCr.
	(prim := self primitiveIndexOf: aMethod) > 0 ifTrue:
		[ts nextPutAll: '<primitive: '; print: prim; nextPut: $>.
		(self isQuickPrimitiveIndex: prim) ifTrue:
			[ts nextPutAll: ' quick method'; cr; flush.
			 ^self].
		ts cr].
	(InstructionPrinter
			on: (VMCompiledMethodProxy new
					for: method
					coInterpreter: self
					objectMemory: self))
		indent: 0;
		printInstructionsOn: ts.
	ts flush
]

{ #category : #'process primitive support' }
NewspeakInterpreter >> synchronousSignal: aSemaphore [ 
	"Signal the given semaphore from within the interpreter.
	 Answer if the current process was preempted."
	| excessSignals |
	<inline: false>
	(self isEmptyList: aSemaphore) ifTrue:
		["no process is waiting on this semaphore"
		 excessSignals := self fetchInteger: ExcessSignalsIndex ofObject: aSemaphore.
		 self storeInteger: ExcessSignalsIndex
			ofObject: aSemaphore
			withValue: excessSignals + 1.
		 ^false].
	^self resume: (self removeFirstLinkOfList: aSemaphore)
]

{ #category : #'debug printing' }
NewspeakInterpreter >> tab [
	<inline: true>
	self printChar: $	"<-Character tab"
]

{ #category : #'compiled methods' }
NewspeakInterpreter >> tempCountOf: methodPointer [
	^ ((self headerOf: methodPointer) >> 19) bitAnd: 16r3F
]

{ #category : #contexts }
NewspeakInterpreter >> temporary: offset [

	^ self fetchPointer: offset + TempFrameStart ofObject: localHomeContext
]

{ #category : #utilities }
NewspeakInterpreter >> transfer: count fromIndex: firstFrom ofObject: fromOop toIndex: firstTo ofObject: toOop [
	"Transfer the specified fullword fields, as from calling context to called context"
	
	"Assume: beRootIfOld: will be called on toOop."
	| fromIndex toIndex lastFrom |
	<inline: true>
	self flag: #Dan.  "Need to check all senders before converting this for 64 bits"
	fromIndex := fromOop + (firstFrom * BytesPerWord).
	toIndex := toOop + (firstTo * BytesPerWord).
	lastFrom := fromIndex + (count * BytesPerWord).
	[self oop: fromIndex isLessThan: lastFrom]
		whileTrue: [fromIndex := fromIndex + BytesPerWord.
			toIndex := toIndex + BytesPerWord.
			self
				longAt: toIndex
				put: (self longAt: fromIndex)]
]

{ #category : #'process primitive support' }
NewspeakInterpreter >> transferTo: aProc [ 
	"Record a process to be awoken on the next interpreter cycle."
	| sched oldProc newProc |
	newProc := aProc.
	sched := self schedulerPointer.
	oldProc := self fetchPointer: ActiveProcessIndex ofObject: sched.
	self storePointer: ActiveProcessIndex ofObject: sched withValue: newProc.
	self storePointer: SuspendedContextIndex ofObject: oldProc withValue: activeContext.
	self newActiveContext: (self fetchPointer: SuspendedContextIndex ofObject: newProc).
	self storePointer: SuspendedContextIndex ofObject: newProc withValue: nilObj.
	reclaimableContextCount := 0
]

{ #category : #'internal interpreter access' }
NewspeakInterpreter >> unPop: nItems [
	stackPointer := stackPointer + (nItems*BytesPerWord)
]

{ #category : #'interpreter shell' }
NewspeakInterpreter >> undoFetchNextBytecode [
	"Backup the ip when it has been incremented to fetch the next bytecode."

	localIP := localIP - 1
]

{ #category : #'interpreter shell' }
NewspeakInterpreter >> unknownBytecode [
	"This should never get called; it means that an unimplemented bytecode appears in a CompiledMethod."

	self error: 'Unknown bytecode'.
]

{ #category : #'debug support' }
NewspeakInterpreter >> validInstructionPointer: anInstrPointer inMethod: aMethod [
	^anInstrPointer >= (aMethod + (self lastPointerOf: aMethod) + 1)
	  and: [anInstrPointer < (aMethod + (self byteLengthOf: aMethod))]
]

{ #category : #'process primitive support' }
NewspeakInterpreter >> wakeHighestPriority [
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
NewspeakInterpreter >> wordSwapped: w [
	"Return the given 64-bit integer with its halves in the reverse order."

	BytesPerWord = 8 ifFalse: [self error: 'This cannot happen.'].
	^   ((w bitShift: Byte4ShiftNegated) bitAnd: Bytes3to0Mask)
	  + ((w bitShift: Byte4Shift         ) bitAnd: Bytes7to4Mask)

]

{ #category : #'image save/restore' }
NewspeakInterpreter >> writeImageFile: imageBytes [

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
NewspeakInterpreter >> writeImageFileIO: imageBytes [

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
	headerSize := 64.  "header size in bytes; do not change!"

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
	self successful ifFalse: [
		"file write or seek failure"
		self cCode: 'sqImageFileClose(f)'.
		^ nil].

	"position file after the header"
	self sqImageFile: f Seek: headerStart + headerSize.

	"write the image data"
	bytesWritten := self cCode: 'sqImageFileWrite(pointerForOop(memory), sizeof(unsigned char), imageBytes, f)'.
	self success: bytesWritten = imageBytes.
	self cCode: 'sqImageFileClose(f)'.


]
