"
This class is a complete implementation of the Smalltalk-80 virtual machine, derived originally from the Blue Book specification but quite different in some areas.  This VM supports Closures but *not* old-style BlockContexts.

It has been modernized with 32-bit pointers, better management of Contexts (see next item), and attention to variable use that allows the CCodeGenerator (qv) to keep, eg, the instruction pointer and stack pointer in registers as well as keeping most simple variables in a global array that seems to improve performance for most platforms.

The VM does not use Contexts directly.  Instead Contexts serve as proxies for a more conventional stack format that is invisible to the image.  There is considerable explanation at http://www.mirandabanda.org/cogblog/2009/01/14/under-cover-contexts-and-the-big-frame-up.  The VM maintains a fixed-size stack zone divided into pages, each page being capable of holding several method/block activations.  A send establishes a new frame in the current stack page, a return returns to the previous frame.  This eliminates allocation/deallocation of contexts and the moving of receiver and arguments from caller to callee on each send/return.  Contexts are created lazily when an activation needs a context (creating a block, explicit use of thisContext, access to sender when sender is a frame, or linking of stack pages together).  Contexts are either conventional and heap-resident (""single"") or ""married"" and serve as proxies for their corresponding frame or ""widowed"", meaning that their spouse frame has been returned from (died).  A married context is specially marked (more details in the code) and refers to its frame.  Likewise a married frame is specially marked and refers to its context.

In addition to SmallInteger arithmetic and Floats, the VM supports logic on 32-bit PositiveLargeIntegers, thus allowing it to simulate itself much more effectively than would otherwise be the case.

NOTE:  Here follows a list of things to be borne in mind when working on this code, or when making changes for the future.

1.  There are a number of things that should be done the next time we plan to release a completely incompatible image format.  These include unifying the instanceSize field of the class format word -- see instantiateClass:indexableSize:, and unifying the bits of the method primitive index (if we decide we need more than 512, after all) -- see primitiveIndexOf:.  Also, contexts should be given a special format code (see next item).

2.  There are several fast checks for contexts (see isContextHeader: and isMethodContextHeader:) which will fail if the compact class indices of BlockContext or MethodContext change.  This is necessary because the oops may change during a compaction when the oops are being adjusted.  It's important to be aware of this when writing a new image using the SystemTracer.  A better solution would be to reserve one of the format codes for Contexts only.

3.  We have made normal files tolerant to size and positions up to 32 bits.  This has not been done for async files, since they are still experimental.  The code in size, at: and at:put: should work with sizes and indices up to 31 bits, although I have not tested it (di 12/98); it might or might not work with 32-bit sizes.

4.  Note that 0 is used in a couple of places as an impossible oop.  This should be changed to a constant that really is impossible (or perhaps there is code somewhere that guarantees it --if so it should be put in this comment).  The places include the method cache and the at cache.

5. Moving to a 2 bit immediate tag and having immediate Characters is a good choice for Unicode and the JIT

6.  If Eliot Miranda's 2 word header scheme is acceptable in terms of footprint (we estimate about a 10% increase in image size with about 35 reclaimed by better representation of CompiledMethod - loss of MethodProperties) then the in-line cache for the JIT is simplified, class access is faster and header access is the same in 32-bit and full 64-bit images.
"
Class {
	#name : #StackInterpreter,
	#superclass : #NewObjectMemory,
	#instVars : [
		'currentBytecode',
		'localFP',
		'localIP',
		'localSP',
		'stackLimit',
		'stackPage',
		'stackPages',
		'method',
		'instructionPointer',
		'stackPointer',
		'framePointer',
		'localReturnValue',
		'messageSelector',
		'argumentCount',
		'newMethod',
		'primFailCode',
		'primPops',
		'primResult',
		'shouldPopArgs',
		'primitiveFunctionPointer',
		'methodCache',
		'atCache',
		'lkupClass',
		'highestRunnableProcessPriority',
		'nextPollUsecs',
		'nextWakeupUsecs',
		'interruptKeycode',
		'interruptPending',
		'savedWindowSize',
		'imageHeaderFlags',
		'fullScreenFlag',
		'preemptionYields',
		'deferDisplayUpdates',
		'pendingFinalizationSignals',
		'extraVMMemory',
		'interpreterProxy',
		'showSurfaceFn',
		'primitiveTable',
		'externalPrimitiveTable',
		'externalPrimitiveTableFirstFreeIndex',
		'overflowedPage',
		'extraFramesToMoveOnOverflow',
		'globalSessionID',
		'jmpBuf',
		'jmpDepth',
		'jmpMax',
		'suspendedCallbacks',
		'suspendedMethods',
		'profileProcess',
		'profileMethod',
		'profileSemaphore',
		'nextProfileTick',
		'numStackPages',
		'desiredNumStackPages',
		'desiredEdenBytes',
		'metaclassSizeBytes',
		'interruptCheckChain',
		'suppressHeartbeatFlag',
		'breakSelector',
		'breakSelectorLength',
		'longRunningPrimitiveCheckMethod',
		'longRunningPrimitiveCheckSemaphore',
		'longRunningPrimitiveStartUsecs',
		'longRunningPrimitiveStopUsecs',
		'longRunningPrimitiveGCUsecs',
		'longRunningPrimitiveCheckSequenceNumber',
		'longRunningPrimitiveSignalUndelivered',
		'statForceInterruptCheck',
		'statStackOverflow',
		'statStackPageDivorce',
		'statCheckForEvents',
		'statProcessSwitch',
		'statIOProcessEvents',
		'theUnknownShort',
		'imageFloatsBigEndian',
		'maxExtSemTabSizeSet',
		'lastMethodCacheProbeWrite'
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
		'BytecodeTable',
		'CacheProbeMax',
		'CharacterValueIndex',
		'ClosureCopiedValuesIndex',
		'ClosureIndex',
		'CrossedX',
		'DirBadPath',
		'DirEntryFound',
		'DirNoMoreEntries',
		'DumpStackOnLowSpace',
		'EndOfRun',
		'ExcessSignalsIndex',
		'FailImbalancedPrimitives',
		'FirstLinkIndex',
		'HeaderFlagBitPosition',
		'LastLinkIndex',
		'LiteralStart',
		'MaxExternalPrimitiveTableSize',
		'MaxJumpBuf',
		'MaxPrimitiveIndex',
		'MaxQuickPrimitiveIndex',
		'MessageArgumentsIndex',
		'MessageDictionaryIndex',
		'MessageLookupClassIndex',
		'MessageSelectorIndex',
		'MethodArrayIndex',
		'MillisecondClockMask',
		'MyListIndex',
		'NextLinkIndex',
		'PrimitiveExternalCallIndex',
		'PrimitiveTable',
		'PriorityIndex',
		'ProcessListsIndex',
		'SelectorStart',
		'StreamArrayIndex',
		'StreamIndexIndex',
		'StreamReadLimitIndex',
		'StreamWriteLimitIndex',
		'SuperclassIndex',
		'SuspendedContextIndex',
		'TempFrameStart',
		'XIndex',
		'YIndex'
	],
	#pools : [
		'VMMethodCacheConstants',
		'VMStackFrameOffsets'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #translation }
StackInterpreter class >> additionalSelectorTables [
	^{ self primitiveTable }
]

{ #category : #translation }
StackInterpreter class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^super ancilliaryClasses,
	  { InterpreterStackPages }
]

{ #category : #translation }
StackInterpreter class >> ancilliaryStructClasses [
	^{ InterpreterStackPage }
]

{ #category : #constants }
StackInterpreter class >> bytecodeTable [

	^ BytecodeTable
]

{ #category : #translation }
StackInterpreter class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator
		addHeaderFile:'<malloc.h> /* for alloca under MSVC */';
		addHeaderFile:'<setjmp.h>';
		addHeaderFile:'"dispdbg.h"'.
	aCCodeGenerator
		var: #interpreterVersion
		declareC: 'const char *interpreterVersion = "Croquet Closure Stack VM [',
					(aCCodeGenerator shortMonticelloDescriptionForClass: self),']"'.
	aCCodeGenerator
		var: #interpreterProxy  type: #'struct VirtualMachine*'.
	aCCodeGenerator
		declareVar: #sendTrace type: 'volatile int';
		declareVar: #byteCount type: 'unsigned long'.
	"These need to be pointers or unsigned."
	self declareC: #(instructionPointer method newMethod)
		as: #usqInt
		in: aCCodeGenerator.
	"These are all pointers; char * because Slang has no support for C pointer arithmetic."
	self declareC: #(localIP localSP localFP stackPointer framePointer stackLimit stackMemory)
		as: #'char *'
		in: aCCodeGenerator.
	self declareC: #(stackPage overflowedPage)
		as: #'StackPage *'
		in: aCCodeGenerator.
	aCCodeGenerator removeVariable: 'stackPages'.  "this is an implicit receiver in the translated code."
	aCCodeGenerator
		var: #methodCache
		declareC: 'long methodCache[MethodCacheSize + 1 /* ', (MethodCacheSize + 1) printString, ' */]'.
	aCCodeGenerator
		var: #atCache
		declareC: 'sqInt atCache[AtCacheTotalSize + 1 /* ', (AtCacheTotalSize + 1) printString, ' */]'.
	aCCodeGenerator
		var: #primitiveTable
		declareC: 'void (*primitiveTable[MaxPrimitiveIndex + 2 /* ', (MaxPrimitiveIndex +2) printString, ' */])(void) = ', self primitiveTableString.
	self primitiveTable do:
		[:symbolOrNot|
		(symbolOrNot isSymbol
		 and: [symbolOrNot ~~ #primitiveFail]) ifTrue:
			[(aCCodeGenerator methodNamed: symbolOrNot) ifNotNil:
				[:tMethod| tMethod returnType: #void]]].
	aCCodeGenerator
		var: #primitiveFunctionPointer
		declareC: 'void (*primitiveFunctionPointer)()'.
	aCCodeGenerator
		var: #externalPrimitiveTable
		declareC: 'void (*externalPrimitiveTable[MaxExternalPrimitiveTableSize + 1 /* ', (MaxExternalPrimitiveTableSize + 1) printString, ' */])(void)'.
	aCCodeGenerator var: #showSurfaceFn type: #'void *'.
	aCCodeGenerator
		var: #jmpBuf
		declareC: 'jmp_buf jmpBuf[MaxJumpBuf + 1 /* ', (MaxJumpBuf + 1) printString, ' */]'.
	aCCodeGenerator
		var: #suspendedCallbacks
		declareC: 'usqInt suspendedCallbacks[MaxJumpBuf + 1 /* ', (MaxJumpBuf + 1) printString, ' */]'.
	aCCodeGenerator
		var: #suspendedMethods
		declareC: 'usqInt suspendedMethods[MaxJumpBuf + 1 /* ', (MaxJumpBuf + 1) printString, ' */]'.
	aCCodeGenerator
		var: #interruptCheckChain
		declareC: 'void (*interruptCheckChain)(void) = 0'.
	aCCodeGenerator
		var: #breakSelector type: #'char *';
		var: #breakSelectorLength
		declareC: 'sqInt breakSelectorLength = -1'.

	self declareC: #(nextPollUsecs nextWakeupUsecs longRunningPrimitiveGCUsecs
					longRunningPrimitiveStartUsecs longRunningPrimitiveStopUsecs)
		as: #usqLong
		in: aCCodeGenerator.
	aCCodeGenerator var: #nextProfileTick type: #sqLong
]

{ #category : #initialization }
StackInterpreter class >> initialize [
	"StackInterpreter initialize"

	self initializeWithBytesToWord: 4.  "initialize ObjectMemory constants"
	self initializeAssociationIndex.
	self initializeBytecodeTable.
	self initializeCaches.
	self initializeCharacterIndex.
	self initializeCharacterScannerIndices.
	self initializeClassIndices.
	self initializeContextIndices.
	self initializeFrameIndices.
	self initializeDirectoryLookupResultCodes.
	self initializeMessageIndices.
	self initializeMethodIndices.
	self initializePointIndices.
	self initializePrimitiveTable.
	self initializeSchedulerIndices.
	self initializeSmallIntegers.
	self initializeStreamIndices.
	self initializeMiscConstants
]

{ #category : #initialization }
StackInterpreter class >> initializeAssociationIndex [
	ValueIndex := 1
]

{ #category : #initialization }
StackInterpreter class >> initializeBytecodeTable [
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

		(208 223 sendLiteralSelector0ArgsBytecode)
		(224 239 sendLiteralSelector1ArgBytecode)
		(240 255 sendLiteralSelector2ArgsBytecode)
	).
]

{ #category : #initialization }
StackInterpreter class >> initializeCaches [

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
StackInterpreter class >> initializeCharacterIndex [
	CharacterValueIndex := 0
]

{ #category : #initialization }
StackInterpreter class >> initializeCharacterScannerIndices [
	CrossedX := 258.
	EndOfRun := 257

]

{ #category : #initialization }
StackInterpreter class >> initializeClassIndices [
	"Class Class"
	SuperclassIndex := 0.
	MessageDictionaryIndex := 1.
	InstanceSpecificationIndex := 2.
	"Fields of a message dictionary"
	MethodArrayIndex := 1.
	SelectorStart := 2
]

{ #category : #initialization }
StackInterpreter class >> initializeContextIndices [
	"Class MethodContext"
	SenderIndex := 0.
	InstructionPointerIndex := 1.
	StackPointerIndex := 2.
	MethodIndex := 3.
	ClosureIndex := 4. "N.B. Called receiverMap in the image."
	ReceiverIndex := 5.
	TempFrameStart := 6.  "Note this is in two places!"

	"Class BlockClosure"
	ClosureOuterContextIndex := 0.
	ClosureStartPCIndex := 1.
	ClosureNumArgsIndex := 2.
	ClosureFirstCopiedValueIndex := 3.
	ClosureCopiedValuesIndex := 3
]

{ #category : #initialization }
StackInterpreter class >> initializeDirectoryLookupResultCodes [

	DirEntryFound := 0.
	DirNoMoreEntries := 1.
	DirBadPath := 2.
]

{ #category : #initialization }
StackInterpreter class >> initializeFrameIndices [
	"Format of a stack frame.  Word-sized indices relative to the frame pointer.
	 Terminology
		Frames are either single (have no context) or married (have a context).
		Contexts are either single (exist on the heap), married (have a context) or widowed (had a frame that has exited).
	 Stacks grow down:

			receiver for method activations/closure for block activations
			arg0
			...
			argN
			caller's method ip/base frame's sender context
	fp->	saved fp
			method
			frame flags
			context (uninitialized)
			receiver
			first temp
			...
	sp->	Nth temp

	frame flags holds the number of arguments (since argument temporaries are above the frame)
	the flag for a block activation
	and the flag indicating if the context field is valid (whether the frame is married).

	The first frame in a stack page is the baseFrame and is marked as such by a null saved fp,
	in which case the saved method ip is actually the context (possibly hybrid) beneath the base frame"

	| fxCallerSavedIP fxSavedFP fxMethod fxFrameFlags fxThisContext fxReceiver |
	fxCallerSavedIP := 1.
	fxSavedFP := 0.
	fxMethod := -1.
	fxFrameFlags := -2.	"Can find numArgs, needed for fast temp access. args are above fxCallerSavedIP.
							 Can find ``is block'' bit
							 Can find ``has context'' bit"
	fxThisContext := -3.
	fxReceiver := -4.

	FrameSlots := fxCallerSavedIP - fxReceiver + 1.

	FoxCallerSavedIP := fxCallerSavedIP * BytesPerWord.
	"In base frames the caller saved ip field holds the caller context."
	FoxCallerContext := FoxCallerSavedIP.
	FoxSavedFP := fxSavedFP * BytesPerWord.
	FoxMethod := fxMethod * BytesPerWord.
	FoxFrameFlags := fxFrameFlags * BytesPerWord.
	FoxThisContext := fxThisContext * BytesPerWord.
	FoxReceiver := fxReceiver * BytesPerWord
]

{ #category : #initialization }
StackInterpreter class >> initializeMessageIndices [
	MessageSelectorIndex := 0.
	MessageArgumentsIndex := 1.
	MessageLookupClassIndex := 2.
]

{ #category : #initialization }
StackInterpreter class >> initializeMethodIndices [
	"Class CompiledMethod"
	HeaderIndex := 0.
	LiteralStart := 1.

	"The position of the unused flag bit in the method header, not including tag bit(s)"
	HeaderFlagBitPosition := 29
]

{ #category : #initialization }
StackInterpreter class >> initializeMiscConstants [

	DumpStackOnLowSpace := 0.
	PrimitiveExternalCallIndex := 117. "Primitive index for #primitiveExternalCall"
	MillisecondClockMask := 16r1FFFFFFF.
	"Note: The external primitive table should actually be dynamically sized but for the sake of inferior platforms (e.g., Mac :-) who cannot allocate memory in any reasonable way, we keep it static (and cross our fingers...)"
	MaxExternalPrimitiveTableSize := 4096. "entries"

	MaxJumpBuf := 32. "max. callback depth"
	FailImbalancedPrimitives := true
]

{ #category : #initialization }
StackInterpreter class >> initializePointIndices [
	XIndex := 0.
	YIndex := 1
]

{ #category : #initialization }
StackInterpreter class >> initializePrimitiveTable [ 
	"This table generates a C function address table use in primitiveResponse along with dispatchFunctionPointerOn:in:"

	"NOTE: The real limit here is 2047 because of the method header layout but there is no point in going over the needed size"
	MaxPrimitiveIndex := 575.	
	MaxQuickPrimitiveIndex := 519.
	PrimitiveTable := Array new: MaxPrimitiveIndex + 1.
	self table: PrimitiveTable from: 
	#(	"Integer Primitives (0-19)"
		(0 0 "a.k.a. primitiveFail but faster because primitiveFail won't even be called")
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

		"Float Primitives (38-59)"
		(38 primitiveFloatAt)
		(39 primitiveFloatAtPut)
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
		"The stream primitives no longer pay their way; normal Smalltalk code is faster."
		(65 0 "a.k.a. primitiveFail but faster because primitiveFail won't even be called")"was primitiveNext"
		(66 0 "a.k.a. primitiveFail but faster because primitiveFail won't even be called") "was primitiveNextPut"
		(67 0 "a.k.a. primitiveFail but faster because primitiveFail won't even be called") "was primitiveAtEnd"

		"StorageManagement Primitives (68-79)"
		(68 primitiveObjectAt)
		(69 primitiveObjectAtPut)
		(70 primitiveNew)
		(71 primitiveNewWithArg)
		(72 primitiveArrayBecomeOneWay)	"Blue Book: primitiveBecome"
		(73 primitiveInstVarAt)
		(74 primitiveInstVarAtPut)
		(75 primitiveIdentityHash)
		(76 primitiveStoreStackp)			"Blue Book: primitiveAsObject"
		(77 primitiveSomeInstance)
		(78 primitiveNextInstance)
		(79 primitiveNewMethod)

		"Control Primitives (80-89)"
		(80 primitiveFail)					"Blue Book: primitiveBlockCopy"
		(81 primitiveFail)					"Blue Book: primitiveValue"
		(82 primitiveFail)					"Blue Book: primitiveValueWithArgs"
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
		(110 primitiveIdentical)
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
		(161 164 primitiveFail)
		(165 primitiveIntegerAt)		"hacked in here for now"
		(166 primitiveIntegerAtPut)
		(167 primitiveYield)
		(168 primitiveCopyObject)
		(169 primitiveFail)

		"Sound Primitives (170-199) - NO LONGER INDEXED"
		(170 184 primitiveFail)

		"CriticalSection primitives"
		(185 primitiveExitCriticalSection) "similar to signal hence index = signal + 100"
		(186 primitiveEnterCriticalSection) "similar to wait hence index = wait + 100. was primitiveClosureValue"
		(187 primitiveTestAndSetOwnershipOfCriticalSection) "was primitiveClosureValueWithArgs"

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

		(207 209 primitiveFail)	"reserved for Cog primitives"

		(210 primitiveContextAt)
		(211 primitiveContextAtPut)
		(212 primitiveContextSize)
		(213 primitiveContextXray)
		(214 primitiveVoidVMState)
		(215 217 primitiveFail)	"reserved for Cog primitives"
		(218 primitiveDoNamedPrimitiveWithArgs)
		(219 primitiveFail)	"reserved for Cog primitives"

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
		(238 239 primitiveFail) "serial port primitives"
		(240 primitiveUTCMicrosecondClock)		"was serial port primitive"
		(241 primitiveLocalMicrosecondClock)		"was serial port primitive"
		(242 primitiveSignalAtUTCMicroseconds)
		(243 primitiveUpdateTimezone) "primStringtranslatefromtotable"
		(244 primitiveFail) "primStringfindFirstInStringinSetstartingAt"
		(245 primitiveFail) "primStringindexOfAsciiinStringstartingAt"
		(246 primitiveFail) "primStringfindSubstringinstartingAtmatchTable"
		(247 primitiveSnapshotEmbedded)
		(248 primitiveFail) "primitiveInvokeObjectAsMethod"
		(249 primitiveArrayBecomeOneWayCopyHash)

		"VM Implementor Primitives (250-255)"
		(250 primitiveClearVMProfile)
		(251 primitiveControlVMProfiling "primitiveStartVMProfiling")
		(252 primitiveVMProfileSamplesInto "primitiveStopVMProfiling")
		(253 primitiveFail "N.B. primitiveCollectCogCodeConstituents in CoInterpreter below")
		(254 primitiveVMParameter)
		(255 primitiveFail) "primitiveInstVarsPutFromStack. Never used except in Disney tests."

		"Quick Push Const Methods"
		(256 nil) "primitivePushSelf"
		(257 nil) "primitivePushTrue"
		(258 nil) "primitivePushFalse"
		(259 nil) "primitivePushNil"
		(260 nil) "primitivePushMinusOne"
		(261 nil) "primitivePushZero"
		(262 nil) "primitivePushOne"
		(263 nil) "primitivePushTwo"

		"Quick Push Inst Var Methods"
		(264 519 nil) "primitiveLoadInstVar"

		(520 primitiveFail)
		"MIDI Primitives (521-539) - NO LONGER INDEXED"
		(521 529 primitiveFail)
		(530 539 primitiveFail)  "reserved for extended MIDI primitives"

		"Experimental Asynchrous File Primitives - NO LONGER INDEXED"
		"Pen Tablet Primitives - NO LONGER INDEXED"
		(540 549 primitiveFail)

		"Sound Codec Primitives - NO LONGER INDEXED"
		(550 569 primitiveFail)

		"External primitive support primitives"
		(570 primitiveFlushExternalPrimitives)
		(571 primitiveUnloadModule)
		(572 primitiveListBuiltinModule)
		(573 primitiveListExternalModule)
		(574 primitiveFail) "reserved for addl. external support prims"

		"Unassigned Primitives"
		(575 primitiveFail))
]

{ #category : #initialization }
StackInterpreter class >> initializeSchedulerIndices [
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
StackInterpreter class >> initializeSmallIntegers [
	"SmallIntegers"
	ConstMinusOne := self basicNew integerObjectOf: -1.
	ConstZero := self basicNew integerObjectOf: 0.
	ConstOne := self basicNew integerObjectOf: 1.
	ConstTwo := self basicNew integerObjectOf: 2
]

{ #category : #initialization }
StackInterpreter class >> initializeStreamIndices [
	StreamArrayIndex := 0.
	StreamIndexIndex := 1.
	StreamReadLimitIndex := 2.
	StreamWriteLimitIndex := 3.
]

{ #category : #translation }
StackInterpreter class >> isInterpreterClass [
	^true
]

{ #category : #translation }
StackInterpreter class >> isNonArgumentImplicitReceiverVariableName: aString [
	^#('self' 'stackPages' 'interpreter') includes: aString
]

{ #category : #translation }
StackInterpreter class >> isTypePointerToStruct: type [ "<String>"
	^type notNil
	  and: [(type beginsWith: 'StackPage')
	  and: [type includes: $*]]
]

{ #category : #benchmarks }
StackInterpreter class >> macroBenchmark [  "Interpreter macroBenchmark"
	"Copied from Interpreter class>>translate:doInlining:forBrowserPlugin:"
	| cg fileName |
	fileName := 'benchmark2.out'.
	StackInterpreter initialize.
	ObjectMemory initialize.
	cg := CCodeGenerator new initialize.
	StackInterpreter initialize.
	ObjectMemory initializeWithBytesToWord: 4.
	cg addClass: StackInterpreter.
	cg addClass: ObjectMemory.
	StackInterpreter declareCVarsIn: cg.
	ObjectMemory declareCVarsIn: cg.
	FileDirectory default deleteFileNamed: fileName.
	cg storeCodeOnFile: fileName doInlining: true.
	FileDirectory default deleteFileNamed: fileName.
]

{ #category : #translation }
StackInterpreter class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^(super mustBeGlobal: var)
	   or: [#('interpreterProxy' 'interpreterVersion'
			'deferDisplayUpdates' 'extraVMMemory' 'showSurfaceFn'
			'desiredNumStackPages' 'desiredEdenBytes'
			'breakSelector' 'breakSelectorLength' 'suppressHeartbeatFlag') includes: var]
]

{ #category : #translation }
StackInterpreter class >> namesOfVariablesToLocalize [
	^#(currentBytecode localFP localIP localSP localReturnValue)
]

{ #category : #translation }
StackInterpreter class >> needsCogit [
	^false
]

{ #category : #translation }
StackInterpreter class >> patchInterp: fileName [
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
StackInterpreter class >> patchInterpGCCPPC: fileName [
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

{ #category : #translation }
StackInterpreter class >> preGenerationHook: aCCodeGenerator [
	"Perform any last-minute changes to the code generator immediately
	 before it performs code analysis and generation.  In this case, make
	 all non-exported methods private."
	| publicMethodNames |
	publicMethodNames := self requiredMethodNames
								copyWithoutAll: (self primitiveTable
														copyWithout: #primitiveFail).
	aCCodeGenerator selectorsAndMethodsDo:
		[:s :m|
		(m export or: [publicMethodNames includes: s]) ifTrue:
			[m static: false]]
]

{ #category : #translation }
StackInterpreter class >> preambleCCode [
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
'
]

{ #category : #translation }
StackInterpreter class >> prepareToBeAddedToCodeGenerator: aCodeGen [
	"This class uses a thread to cause regular polling for I/O"
	aCodeGen removeVariable: 'interruptCheckCounter'
]

{ #category : #constants }
StackInterpreter class >> primitiveTable [

	^ PrimitiveTable
]

{ #category : #initialization }
StackInterpreter class >> primitiveTableString [
	"StackInterpreter initializePrimitiveTable primitiveTableString"
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
StackInterpreter class >> requiredMethodNames [
	"return the list of method names that should be retained for export or other support reasons"
	| requiredList |
	requiredList := self exportAPISelectors.
	requiredList addAll: NewObjectMemory requiredMethodNames.
	"A number of methods required by VM support code, jitter, specific platforms etc"
	requiredList addAll: #(
		assertValidExecutionPointe:r:s:
		characterForAscii: checkedLongAt:
		delayExpired
		findClassOfMethod:forReceiver: findSelectorOfMethod:forReceiver:
			forceInterruptCheck forceInterruptCheckFromHeartbeat fullDisplayUpdate
		getCurrentBytecode getFullScreenFlag getInterruptKeycode getInterruptPending
			getSavedWindowSize getThisSessionID
		highBit:
		interpret
		loadInitialContext
		objectBefore: objectExactlyBefore: oopFromChunk:
		primitiveFail primitiveFailFor: primitiveFlushExternalPrimitives printAllStacks printCallStack printContext:
			printExternalHeadFrame printFramesInPage: printFrame: printHeadFrame printMemory printOop:
				printStackPages printStackPageList printStackPagesInUse printStackPageListInUse
		readableFormat: readImageFromFile:HeapSize:StartingAt:
		setFullScreenFlag: setInterruptKeycode: setInterruptPending: setInterruptCheckChain:
			setSavedWindowSize: success:
		validInstructionPointer:inMethod:framePointer:).

	"Nice to actually have all the primitives available"
	requiredList addAll: (self primitiveTable select: [:each| each isSymbol]).

	"Compatibility push/pop"
	requiredList addAll:#(pluginPop: pluginPop:thenPush: pluginPushFloat: pluginPushBool: pluginPushInteger: pluginPush: pluginStackValue: pluginStackObjectValue: pluginStackFloatValue: pluginStackIntegerValue:).

	"InterpreterProxy is the internal analogue of sqVirtualMachine.c, so make sure to keep all those"
	InterpreterProxy organization categories do:
		[:cat |
		((cat ~= 'initialize') and: [cat ~= 'private']) ifTrue:
			[requiredList addAll: (InterpreterProxy organization listAtCategoryNamed: cat)]].

	^requiredList
]

{ #category : #translation }
StackInterpreter class >> sourceFileName [
	^'interp.c'
]

{ #category : #initialization }
StackInterpreter class >> table: anArray from: specArray [ 
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
StackInterpreter class >> wantsLabels [
	"Only label the VM, not plugins (internal or external).  This to cut down the scope
	 of problems with labels being duplicated by C compiler optimizer inlining and
	 loop unrolling.  We use the asmLabel: directive to control labelling in the
	 interpreter proper. But it is too much work doing that for plugins too."
	^true
]

{ #category : #translation }
StackInterpreter class >> writeVMHeaderTo: aStream bytesPerWord: bytesPerWord [
	aStream
		nextPutAll: '#define STACKVM 1'; cr;
		nextPutAll: '#define SQ_VI_BYTES_PER_WORD '; print: bytesPerWord; cr;
		cr.
	((VMBasicConstants classPool associations select: [:a| a key beginsWith: 'PrimErr'])
		asSortedCollection: [:a1 :a2| a1 value <= a2 value])
		do: [:a|
			aStream nextPutAll: '#define '; nextPutAll: a key; space; print: a value; cr].
	aStream cr
]

{ #category : #'control primitives' }
StackInterpreter >> activateNewClosureMethod: blockClosure numArgs: numArgs mayContextSwitch: mayContextSwitch [
	"Similar to activateNewMethod but for Closure and newMethod."
	| numCopied outerContext theMethod closureIP |
	<inline: true>
	outerContext := self fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	numCopied := self copiedValueCountOfClosure: blockClosure.

	theMethod := self fetchPointer: MethodIndex ofObject: outerContext.
	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: theMethod.
	self push: (self encodeFrameFieldHasContext: false isBlock: true numArgs: numArgs).
	self push: nilObj. "FxThisContext field"
	self push: (self fetchPointer: ReceiverIndex ofObject: outerContext).

	"Copy the copied values..."
	0 to: numCopied - 1 do:
		[:i|
		self push: (self
					fetchPointer: i + ClosureFirstCopiedValueIndex
					ofObject: blockClosure)].

	self assert: (self frameIsBlockActivation: framePointer).
	self assert: (self frameHasContext: framePointer) not.

	"The initial instructions in the block nil-out remaining temps."

	"the instruction pointer is a pointer variable equal to 
	method oop + ip + BaseHeaderSize 
	-1 for 0-based addressing of fetchByte 
	-1 because it gets incremented BEFORE fetching currentByte"
	closureIP := self quickFetchInteger: ClosureStartPCIndex ofObject: blockClosure.
	instructionPointer := theMethod + closureIP + BaseHeaderSize - 2.
	self setMethod: theMethod.

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)"
	stackPointer < stackLimit ifTrue:
		[self handleStackOverflowOrEventAllowContextSwitch: mayContextSwitch]
]

{ #category : #'message sending' }
StackInterpreter >> activateNewMethod [
	| methodHeader numArgs numTemps rcvr errorCode |

	methodHeader := self headerOf: newMethod.
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	numArgs := self argumentCountOfMethodHeader: methodHeader.

	rcvr := self stackValue: numArgs. "could new rcvr be set at point of send?"

	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: newMethod.
	self setMethod: newMethod.
	self push: (self encodeFrameFieldHasContext: false isBlock: false numArgs: numArgs).
	self push: nilObj. "FxThisContext field"
	self push: rcvr.

	"clear remaining temps to nil"
	numArgs+1 to: numTemps do:
		[:i | self push: nilObj].

	instructionPointer := (self initialPCForHeader: methodHeader method: newMethod) - 1.

	"Pass primitive error code to last temp if method receives it (indicated
	 by an initial long store temp bytecode).  Protect against obsolete values
	 in primFailCode by checking that newMethod actually has a primitive?"
	primFailCode ~= 0 ifTrue:
		[((self methodHeaderHasPrimitive: methodHeader)
		   and: [(self byteAtPointer: instructionPointer + 1) = 129 "long store temp"]) ifTrue:
			[errorCode := self getErrorObjectFromPrimFailCode.
			 self stackTopPut: errorCode "nil if primFailCode == 1, or primFailCode"].
		primFailCode := 0].

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	stackPointer < stackLimit ifTrue:
		[self handleStackOverflowOrEventAllowContextSwitch: (self canContextSwitchIfActivating: methodHeader)]
]

{ #category : #'process primitive support' }
StackInterpreter >> activeProcess [
	"Answer the current activeProcess."
	^self fetchPointer: ActiveProcessIndex ofObject: self schedulerPointer
]

{ #category : #'process primitive support' }
StackInterpreter >> addFirstLink: proc toList: aList [ 
	"Add the given process to the front of the given linked list
	 and set the backpointer of process to its new list."
	| firstLink |
	self assert: (self fetchPointer: NextLinkIndex ofObject: proc) = nilObj.
	firstLink := self fetchPointer: FirstLinkIndex ofObject: aList.
	self storePointer: FirstLinkIndex ofObject: aList withValue: proc.
	firstLink = nilObj "a.k.a. (self isEmptyList: aList)"
		ifTrue: [self storePointer: LastLinkIndex ofObject: aList withValue: proc]
		ifFalse: [self storePointer: NextLinkIndex ofObject: proc withValue: firstLink].
	self storePointer: MyListIndex ofObject: proc withValue: aList
]

{ #category : #'process primitive support' }
StackInterpreter >> addLastLink: proc toList: aList [ 
	"Add the given process to the end of the given linked list
	 and set the backpointer of process to its new list."
	| lastLink |
	self assert: (self fetchPointer: NextLinkIndex ofObject: proc) = nilObj.
	(self isEmptyList: aList)
		ifTrue: [self storePointer: FirstLinkIndex ofObject: aList withValue: proc]
		ifFalse: [lastLink := self fetchPointer: LastLinkIndex ofObject: aList.
			self storePointer: NextLinkIndex ofObject: lastLink withValue: proc].
	self storePointer: LastLinkIndex ofObject: aList withValue: proc.
	self storePointer: MyListIndex ofObject: proc withValue: aList
]

{ #category : #'method lookup cache' }
StackInterpreter >> addNewMethodToCache: class [
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
	hash := messageSelector bitXor: class.  "drop low-order zeros from addresses"
	primitiveIndex := self primitiveIndexOf: newMethod.
	primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: class.

	0 to: CacheProbeMax-1 do:
		[:p | probe := (hash >> p) bitAnd: MethodCacheMask.
		(methodCache at: probe + MethodCacheSelector) = 0 ifTrue:
			["Found an empty entry -- use it"
			methodCache at: probe + MethodCacheSelector put: messageSelector.
			methodCache at: probe + MethodCacheClass put: class.
			methodCache at: probe + MethodCacheMethod put: newMethod.
			methodCache at: probe + MethodCachePrimFunction put: (self cCoerce: primitiveFunctionPointer to: #long).
			lastMethodCacheProbeWrite := probe. "this for primitiveExternalMethod"
			^ nil]].

	"OK, we failed to find an entry -- install at the first slot..."
	probe := hash bitAnd: MethodCacheMask.  "first probe"
	methodCache at: probe + MethodCacheSelector put: messageSelector.
	methodCache at: probe + MethodCacheClass put: class.
	methodCache at: probe + MethodCacheMethod put: newMethod.
	methodCache at: probe + MethodCachePrimFunction put: (self cCoerce: primitiveFunctionPointer to: #long).
	lastMethodCacheProbeWrite := probe. "this for primitiveExternalMethod"

	"...and zap the following entries"
	1 to: CacheProbeMax-1 do:
		[:p | probe := (hash >> p) bitAnd: MethodCacheMask.
		methodCache at: probe + MethodCacheSelector put: 0]
]

{ #category : #'plugin support' }
StackInterpreter >> addToExternalPrimitiveTable: functionAddress [
	"Add the given function address to the external primitive table and return the index where it's stored. This function doesn't need to be fast since it is only called when an external primitive has been looked up (which takes quite a bit of time itself). So there's nothing specifically complicated here.
	Note: Return index will be one-based (ST convention)"

	<var: #functionAddress declareC: 'void *functionAddress'>

	externalPrimitiveTableFirstFreeIndex to: MaxExternalPrimitiveTableSize-1 do:
		[ :i |
		(externalPrimitiveTable at: i) = 0 ifTrue:
			[externalPrimitiveTable at: i put: functionAddress.
			^externalPrimitiveTableFirstFreeIndex := i+1]].
	"if no space left, return zero so it'll looked up again"
	^0
]

{ #category : #'debug support' }
StackInterpreter >> allAccessibleObjectsOkay [
	"Ensure that all accessible objects in the heap are okay."

	| oop |
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse: [
		self okayFields: oop.
		oop := self accessibleObjectAfter: oop.
	].
]

{ #category : #utilities }
StackInterpreter >> areIntegers: oop1 and: oop2 [
"Test oop1 and oop2 to make sure both are SmallIntegers."
	^ ((oop1 bitAnd: oop2) bitAnd: 1) ~= 0
]

{ #category : #'compiled methods' }
StackInterpreter >> argumentCountOf: methodPointer [
	<api>
	^self argumentCountOfMethodHeader: (self headerOf: methodPointer)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> argumentCountOfClosure: closurePointer [

	^self quickFetchInteger: ClosureNumArgsIndex ofObject: closurePointer
]

{ #category : #'compiled methods' }
StackInterpreter >> argumentCountOfMethodHeader: header [
	^ (header >> 25) bitAnd: 16r0F
]

{ #category : #utilities }
StackInterpreter >> arrayValueOf: arrayOop [
	"Return the address of first indexable field of resulting array object, or fail if the instance variable does not contain an indexable bytes or words object."
	"Note: May be called by translated primitive code."

	<returnTypeC: 'void *'>
	((self isIntegerObject: arrayOop) not and:
	 [self isWordsOrBytes: arrayOop])
		ifTrue: [^ self cCode: '(void *)pointerForOop(arrayOop + BaseHeaderSize)'].
	self primitiveFail.

]

{ #category : #'indexing primitive support' }
StackInterpreter >> asciiOfCharacter: characterObj [  "Returns an integer object"

	<inline: false>
	self assertClassOf: characterObj is: (self splObj: ClassCharacter).
	self successful
		ifTrue: [^ self fetchPointer: CharacterValueIndex ofObject: characterObj]
		ifFalse: [^ ConstZero]  "in case some code needs an int"
]

{ #category : #'debug support' }
StackInterpreter >> assertCStackCorrectlyAligned [
	"This is a no-op in the Stack VM"
]

{ #category : #utilities }
StackInterpreter >> assertClassOf: oop is: classOop [
	"Succeed if oop is an instance of the given class. Fail if the object is an integer."

	| ccIndex cl |
	<inline: true>
	<asmLabel: false>
	(self isIntegerObject: oop) ifTrue:
		[self success: false.
		 ^nil].

	(ccIndex := self compactClassIndexOf: oop) = 0
		ifTrue: [ cl := ((self classHeader: oop) bitAnd: AllButTypeMask) ]
		ifFalse: [
			"look up compact class"
			cl := (self fetchPointer: (ccIndex - 1)
					ofObject: (self fetchPointer: CompactClasses ofObject: specialObjectsOop))].

	self success: cl = classOop
]

{ #category : #utilities }
StackInterpreter >> assertClassOf: oop is: classOop compactClassIndex: compactClassIndex [
	"Succeed if the oop is an instance of the given class. Fail if the object is an integer.
	 If the class has a (non-zero) compactClassIndex use that to speed up the check.
	 N.B. Inlining should result in classOop not being accessed if compactClassIndex
	 is non-zero."

	| ccIndex |
	<inline: true>
	(self isIntegerObject: oop) ifTrue:
		[self success: false. ^nil].

	ccIndex := self compactClassIndexOf: oop.
	compactClassIndex = 0
		ifTrue:
			[ccIndex = 0
				ifTrue: [self success: ((self classHeader: oop) bitAnd: AllButTypeMask) = classOop]
				ifFalse: [self success: false]]
		ifFalse:
			[self success: compactClassIndex == ccIndex]
]

{ #category : #utilities }
StackInterpreter >> assertClassOfNonInt: oop is: classOop compactClassIndex: compactClassIndex [
	"Succeed if the given (non-integer) object is an instance of the given class. Fail if the object is an integer.
	 If the class has a (non-zero) compactClassIndex use that to speed up the check."

	| ccIndex |
	<inline: true>
	<asmLabel: false>
	ccIndex := self compactClassIndexOf: oop.
	compactClassIndex = 0
		ifTrue:
			[ccIndex = 0
				ifTrue: [self success: ((self classHeader: oop) bitAnd: AllButTypeMask) = classOop]
				ifFalse: [self success: false]]
		ifFalse:
			[self success: compactClassIndex == ccIndex]
]

{ #category : #'debug support' }
StackInterpreter >> assertValidExecutionPointe: lip r: lifp s: lisp [
	<var: #lip type: #'usqInt'>
	<var: #lifp type: #'char *'>
	<var: #lisp type: #'char *'>
	self assertValidExecutionPointe: lip r: lifp s: lisp imbar: (self isMachineCodeFrame: lifp) not
]

{ #category : #'debug support' }
StackInterpreter >> assertValidExecutionPointe: lip r: lfp s: lsp imbar: inInterpreter [
	<var: #lip type: #'char *'>
	<var: #lfp type: #'char *'>
	<var: #lsp type: #'char *'>
	self assert: inInterpreter.
	self assert: stackPage = (stackPages stackPageFor: lfp).
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	self assertValidStackLimits.
	self assert: lfp < stackPage baseAddress.
	self assert: lsp < lfp.
	self assert: lfp > lsp.
	self assert: lsp >= (stackPage realStackLimit - self stackLimitOffset).
	self assert:  (lfp - lsp) < LargeContextSize.
	self assert: (self validInstructionPointer: lip inFrame: lfp).
	self assert: ((self frameIsBlockActivation: lfp)
				or: [(self pushedReceiverOrClosureOfFrame: lfp) = (self frameReceiver: lfp)])
]

{ #category : #'process primitive support' }
StackInterpreter >> assertValidStackLimits [
	<returnTypeC: #void>
	"Order in the stackLimit checks is important because stackLimit is smashed by
	 interrupts. So always check for unsmashed value first to avoid race condition."
	self assert: (stackLimit = stackPage realStackLimit
				or: [stackLimit = (self cCoerceSimple: -1 signedIntToLong to: 'char *')]).
	self assert: (stackPage stackLimit = stackPage realStackLimit
				or: [stackPage stackLimit = (self cCoerceSimple: -1 signedIntToLong to: 'char *')])
]

{ #category : #'debug support' }
StackInterpreter >> balancedStack: delta withArgs: nArgs [
	"Return true if the stack is still balanced after executingsome primitive with
	 nArgs args.  Delta is 'stackPointer - activeContext' which is a relative measure
	 for the stack pointer (so we don't have to relocate it during the primitive)"
	^self successful
		ifTrue:"Successful prim, stack must have exactly nArgs arguments popped off"
			[(framePointer - stackPointer) = (delta - (nArgs * BytesPerWord))]
		ifFalse:"Failed prim must leave stack intact"
			[(framePointer - stackPointer) = delta]
]

{ #category : #'return bytecodes' }
StackInterpreter >> baseFrameReturn [
	| contextToReturnTo isAContext theFP theSP thePage frameAbove |
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #frameAbove type: #'char *'>
	contextToReturnTo := self frameCallerContext: localFP.
	isAContext := self isContext: contextToReturnTo.
	(isAContext
	 and: [self isStillMarriedContext: contextToReturnTo])
		ifTrue:
			[theFP := self frameOfMarriedContext: contextToReturnTo.
			 thePage := stackPages stackPageFor: theFP.
			 theFP = thePage headFP
				ifTrue:
					[theSP := thePage headSP.
					 stackPages freeStackPageNoAssert: stackPage "for a short time invariant is violated; assert follows"]
				ifFalse:
					["Returning to some interior frame, presumably because of a sender assignment.
					  Move the frames above to another page (they may be in use, e.g. via coroutining).
					  Make the interior frame the top frame."
					 frameAbove := self findFrameAbove: theFP inPage: thePage.
					 "Reuse the page we're exiting, which avoids allocating a new page and
					  manipulating the page list to mark the page we're entering as least recently
					  used (to avoid it being deallocated when allocating a new page)."
					 self moveFramesIn: thePage through: frameAbove toPage: stackPage.
					 theFP := thePage headFP.
					 theSP := thePage headSP]]
		ifFalse:
			[(isAContext
			  and: [self isIntegerObject: (self fetchPointer: InstructionPointerIndex ofObject: contextToReturnTo)]) ifFalse:
				[^self internalCannotReturn: localReturnValue].
			 thePage := self makeBaseFrameFor: contextToReturnTo.
			 theFP := thePage headFP.
			 theSP := thePage headSP.
			 stackPages freeStackPageNoAssert: stackPage "for a short time invariant is violated; assert follows"].
	self setStackPageAndLimit: thePage.
	self assert: (stackPages stackPageFor: theFP) = stackPage.
	localSP := theSP.
	localFP := theFP.
	self setMethod: (self frameMethod: localFP).
	localIP := self pointerForOop: self internalStackTop.
	self internalStackTopPut: localReturnValue.
	self assert: (self checkIsStillMarriedContext: contextToReturnTo currentFP: localFP).
	^self fetchNextBytecode
]

{ #category : #'frame access' }
StackInterpreter >> bereaveAllMarriedContexts [
	"Enumerate all contexts and convert married contexts to widowed contexts so
	 that the snapshot contains only single contexts.  This allows the test for being
	 married to avoid checking for a context's frame pointer being in bounds.
	 Thanks to Greg Nuyens for this idea."
	| oop |
	oop := self firstObject.
	[oop < freeStart] whileTrue:
		[((self isFreeObject: oop) not
		   and: [(self isContextNonInt: oop)
		   and: [self isMarriedOrWidowedContext: oop]]) ifTrue:
			[self storePointerUnchecked: SenderIndex ofObject: oop withValue: nilObj.
			 self storePointerUnchecked: InstructionPointerIndex ofObject: oop withValue: nilObj].
		 oop := self objectAfter: oop]
]

{ #category : #utilities }
StackInterpreter >> booleanCheat: cond [
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
StackInterpreter >> booleanValueOf: obj [
"convert true and false (Smalltalk) to true or false(C)"
	obj = trueObj ifTrue: [ ^ true ].
	obj = falseObj ifTrue: [ ^ false ].
	self success: false.
	^ nil
]

{ #category : #'indexing primitive support' }
StackInterpreter >> byteLengthOf: oop [
	"Return the number of indexable bytes in the given object. This is basically a special copy of lengthOf: for BitBlt."
	| header sz fmt |
	header := self baseHeader: oop.
	sz := (header bitAnd: TypeMask) = HeaderTypeSizeAndClass
			ifTrue: [(self sizeHeader: oop) bitAnd: AllButTypeMask]
			ifFalse: [header bitAnd: SizeMask].
	fmt := self formatOfHeader: header.
	^fmt < 8
		ifTrue: [(sz - BaseHeaderSize)]  "words"
		ifFalse: [(sz - BaseHeaderSize) - (fmt bitAnd: 3)]  "bytes"
]

{ #category : #'object format' }
StackInterpreter >> byteSizeOf: oop [
	| slots |
self flag: #Dan.
	(self isIntegerObject: oop) ifTrue:[^0].
	slots := self slotSizeOf: oop.
	(self isBytesNonInt: oop)
		ifTrue:[^slots]
		ifFalse:[^slots * 4]
]

{ #category : #'image segment in/out' }
StackInterpreter >> byteSwapByteObjectsFrom: startOop to: stopAddr flipFloatsIf: flipFloatWords [
	"Byte-swap the words of all bytes objects in a range of the 
	image, including Strings, ByteArrays, and CompiledMethods. 
	This returns these objects to their original byte ordering 
	after blindly byte-swapping the entire image. For compiled 
	methods, byte-swap only their bytecodes part.  For Floats
	swap their most and least significant words if required."
	| oop fmt temp wordAddr |
	oop := startOop.
	[self oop: oop isLessThan: stopAddr] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[fmt := self formatOf: oop.
			fmt >= 8 ifTrue:
				["oop contains bytes; unswap"
				wordAddr := oop + BaseHeaderSize.
				fmt >= 12 ifTrue: "compiled method; start after methodHeader and literals"
					[wordAddr := wordAddr + BytesPerWord + ((self literalCountOf: oop) * BytesPerWord)].
				self reverseBytesFrom: wordAddr to: oop + (self sizeBitsOf: oop)].
			fmt = 6  ifTrue: "Bitmap, Float etc"
				[(self compactClassIndexOf: oop) = ClassFloatCompactIndex
					ifTrue:
						[flipFloatWords ifTrue:
							[temp := self longAt: oop + BaseHeaderSize.
							 self longAt: oop + BaseHeaderSize put: (self longAt: oop + BaseHeaderSize + 4).
							 self longAt: oop + BaseHeaderSize + 4 put: temp]]
					ifFalse:
						[BytesPerWord = 8 ifTrue:
							["Object contains 32-bit half-words packed into 64-bit machine words."
							wordAddr := oop + BaseHeaderSize.
							self reverseWordsFrom: wordAddr to: oop + (self sizeBitsOf: oop)]]]].
			oop := self objectAfter: oop]
]

{ #category : #'image save/restore' }
StackInterpreter >> byteSwapped: w [
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
StackInterpreter >> bytecodePrimAdd [
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
StackInterpreter >> bytecodePrimAt [
	"BytecodePrimAt will only succeed if the receiver is in the atCache.
	Otherwise it will fail so that the more general primitiveAt will put it in the
	cache after validating that message lookup results in a primitive response."
	| index rcvr result atIx |
	index := self internalStackTop.
	rcvr := self internalStackValue: 1.
	((self isIntegerObject: rcvr) not
	 and: [self isIntegerObject: index]) ifTrue:
		[atIx := rcvr bitAnd: AtCacheMask.  "Index into atCache = 4N, for N = 0 ... 7"
		(atCache at: atIx+AtCacheOop) = rcvr ifTrue:
			[result := self commonVariable: rcvr at: (self integerValueOf: index) cacheIndex: atIx.
			 self successful ifTrue:
				[self fetchNextBytecode.
				^self internalPop: 2 thenPush: result]]].

	messageSelector := self specialSelector: 16.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimAtEnd [
	messageSelector := self specialSelector: 21.
	argumentCount := 0.
	self normalSend.
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimAtPut [
	"BytecodePrimAtPut will only succeed if the receiver is in the atCache.
	Otherwise it will fail so that the more general primitiveAtPut will put it in the
	cache after validating that message lookup results in a primitive response."
	| index rcvr atIx value |
	value := self internalStackTop.
	index := self internalStackValue: 1.
	rcvr := self internalStackValue: 2.
	((self isIntegerObject: rcvr) not
	 and: [self isIntegerObject: index]) ifTrue:
		[atIx := (rcvr bitAnd: AtCacheMask) + AtPutBase.  "Index into atPutCache"
		 (atCache at: atIx+AtCacheOop) = rcvr ifTrue:
			[self commonVariable: rcvr at: (self integerValueOf: index) put: value cacheIndex: atIx.
			 self successful ifTrue:
				[self fetchNextBytecode.
				 ^self internalPop: 3 thenPush: value]]].

	messageSelector := self specialSelector: 17.
	argumentCount := 2.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimBitAnd [

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
StackInterpreter >> bytecodePrimBitOr [

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
StackInterpreter >> bytecodePrimBitShift [

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
StackInterpreter >> bytecodePrimBlockCopy [

	messageSelector := self specialSelector: 24.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimClass [
	| rcvr |
	rcvr := self internalStackTop.
	self internalPop: 1 thenPush: (self fetchClassOf: rcvr).
	self fetchNextBytecode.

]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimDiv [
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
StackInterpreter >> bytecodePrimDivide [
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
StackInterpreter >> bytecodePrimDo [

	messageSelector := self specialSelector: 27.
	argumentCount := 1.
	self normalSend.

]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimEqual [
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
StackInterpreter >> bytecodePrimEquivalent [

	| rcvr arg |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	self booleanCheat: rcvr = arg.
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimGreaterOrEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		self cCode: '' inSmalltalk: [^self booleanCheat: (self integerValueOf: rcvr) >= (self integerValueOf: arg)].
		^self booleanCheat: rcvr >= arg].

	self initPrimCall.
	"Invert test so that NaN comparisons work correctly."
	aBool := self primitiveFloatLess: rcvr thanArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool not].

	messageSelector := self specialSelector: 5.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimGreaterThan [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		self cCode: '' inSmalltalk: [^self booleanCheat: (self integerValueOf: rcvr) > (self integerValueOf: arg)].
		^self booleanCheat: rcvr > arg].

	self initPrimCall.
	aBool := self primitiveFloatGreater: rcvr thanArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 3.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimLessOrEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		self cCode: '' inSmalltalk: [^self booleanCheat: (self integerValueOf: rcvr) <= (self integerValueOf: arg)].
		^ self booleanCheat: rcvr <= arg].

	self initPrimCall.
	"Invert test so that NaN comparisons work correctly."
	aBool := self primitiveFloatGreater: rcvr thanArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool not].

	messageSelector := self specialSelector: 4.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimLessThan [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		self cCode: '' inSmalltalk: [^self booleanCheat: (self integerValueOf: rcvr) < (self integerValueOf: arg)].
		^ self booleanCheat: rcvr < arg].

	self initPrimCall.
	aBool := self primitiveFloatLess: rcvr thanArg: arg.
	self successful ifTrue: [^ self booleanCheat: aBool].

	messageSelector := self specialSelector: 2.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimMakePoint [

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
StackInterpreter >> bytecodePrimMod [
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
StackInterpreter >> bytecodePrimMultiply [
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
		ifFalse: [self initPrimCall.
				self externalizeIPandSP.
				self primitiveFloatMultiply: rcvr byArg: arg.
				self internalizeIPandSP.
				self successful ifTrue: [^ self fetchNextBytecode "success"]].

	messageSelector := self specialSelector: 8.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNew [

	messageSelector := self specialSelector: 28.
	argumentCount := 0.
	self normalSend.

]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNewWithArg [

	messageSelector := self specialSelector: 29.
	argumentCount := 1.
	self normalSend.

]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNext [
	messageSelector := self specialSelector: 19.
	argumentCount := 0.
	self normalSend.
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNextPut [
	messageSelector := self specialSelector: 20.
	argumentCount := 1.
	self normalSend.
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNotEqual [
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
StackInterpreter >> bytecodePrimPointX [

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
StackInterpreter >> bytecodePrimPointY [

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
StackInterpreter >> bytecodePrimSize [
	| rcvr sz isString isArray |
	self initPrimCall.
	rcvr := self internalStackTop.

	"Shortcut the mega-lookup for ByteString and Array, the two big consumers of cycles
	 here. Both of these have compact class indices and neither has any added fields."
      isString := self is: rcvr instanceOf: ClassString compactClassIndex: ClassByteStringCompactIndex.
	isString ifTrue:
		[sz := self lengthOf: rcvr.
		 self internalPop: 1 thenPush: (self integerObjectOf: sz).
		^self fetchNextBytecode].

      isArray := self is: rcvr instanceOf: ClassArray compactClassIndex: ClassArrayCompactIndex.
	isArray ifTrue:
		[sz := self lengthOf: rcvr.
		 self internalPop: 1 thenPush: (self integerObjectOf: sz).
		^self fetchNextBytecode].

	messageSelector := self specialSelector: 18.
	argumentCount := 0.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimSubtract [
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
StackInterpreter >> bytecodePrimValue [
	| block |
	block := self internalStackTop.
	self initPrimCall.
	argumentCount := 0.
	self assertClassOf: block is: (self splObj: ClassBlockClosure).
	self successful ifTrue: [
		self externalizeIPandSP.
		self primitiveClosureValue.
		self internalizeIPandSP.
	].
	self successful ifFalse: [
		messageSelector := self specialSelector: 25.
		^ self normalSend
	].
	self fetchNextBytecode
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimValueWithArg [
	| block |
	block := self internalStackValue: 1.
	self initPrimCall.
	argumentCount := 1.
	self assertClassOf: block is: (self splObj: ClassBlockClosure).
	self successful ifTrue: [
		self externalizeIPandSP.
		self primitiveClosureValue.
		self internalizeIPandSP.
	].
	self successful ifFalse: [
		messageSelector := self specialSelector: 26.
		^self normalSend
	].
	self fetchNextBytecode
]

{ #category : #'plugin primitive support' }
StackInterpreter >> callExternalPrimitive: functionID [
	"Call the external plugin function identified. In the VM this is an address;
	 see StackInterpreterSimulator for its version."

	<var: #functionID declareC: 'void (*functionID)()'>
	self dispatchFunctionPointer: functionID
]

{ #category : #'callback support' }
StackInterpreter >> callbackEnter: callbackID [
	"Re-enter the interpreter for executing a callback"
	<export: true>
	<var: #callbackID type: #'sqInt *'>

	"For now, do not allow a callback unless we're in a primitiveResponse"
	(self asserta: primitiveFunctionPointer ~= 0) ifFalse:
		[^false].

	"Check if we've exceeded the callback depth"
	(self asserta: jmpDepth < jmpMax) ifFalse:
		[^false].
	jmpDepth := jmpDepth + 1.

	"Suspend the currently active process"
	suspendedCallbacks at: jmpDepth put: self activeProcess.
	"We need to preserve newMethod explicitly since it is not activated yet
	and therefore no context has been created for it. If the caller primitive
	for any reason decides to fail we need to make sure we execute the correct
	method and not the one 'last used' in the call back"
	suspendedMethods at: jmpDepth put: newMethod.
	self transferTo: self wakeHighestPriority.

	"Typically, invoking the callback means that some semaphore has been 
	signaled to indicate the callback. Force an interrupt check as soon as possible."
	self forceInterruptCheck.

	(self setjmp: (jmpBuf at: jmpDepth)) == 0 ifTrue: "Fill in callbackID"
		[callbackID at: 0 put: jmpDepth.
		self interpret].

	"Transfer back to the previous process so that caller can push result"
	self putToSleep: self activeProcess yieldingIf: preemptionYields.
	newMethod := suspendedMethods at: jmpDepth.	"see comment above"
	argumentCount := self argumentCountOf: newMethod.
	self transferTo: (suspendedCallbacks at: jmpDepth).
	jmpDepth := jmpDepth-1.
	"clean out the primPops etc since we'll be returning via primitive"
	self initPrimCall.
	^true
]

{ #category : #'callback support' }
StackInterpreter >> callbackLeave: cbID [
	"Leave from a previous callback"
	<export: true>

	"For now, do not allow a callback return unless we're in a primitiveResponse"
	(self asserta: primitiveFunctionPointer ~= 0) ifFalse:
		[^false].

	"Check if this is the top-level callback"
	cbID = jmpDepth ifFalse:[^false].
	cbID < 1 ifTrue:[^false].
	"This is ugly but necessary, or otherwise the Mac will not build"
	self long: (jmpBuf at: jmpDepth) jmp: 1.
	"NOTREACHED"
	^nil
]

{ #category : #'message sending' }
StackInterpreter >> canContextSwitchIfActivating: methodHeader [
	"Context switch should not be allowed on every method activation.  In particular
	 the implementation of ensure: and ifCurtailed: depends on there being no
	 suspension point on failing primitive 198 (primitiveMarkUnwindMethod).
	 slowPrimitiveResponse states
		``N.B.  This means there is no suspension point on primitive failure
		    which methods such as ensure: and ifCurtailed: rely on.''
	 Rather than prevent context switch on all primitives but the ones we really need
	 to be suspension points (primitiveSignal et al) we choose to allow context switch
	 for all but primitiveMarkUnwindMethod."
	| primitiveIndex |
	<inline: true>
	primitiveIndex := self primitiveIndexOfMethodHeader: methodHeader.
	true ifTrue:
		[^primitiveIndex ~= 198]."primitiveMarkUnwindMethod"
	^primitiveIndex = 0
	  or: [(primitiveIndex between: 85 and: 88) "primitiveSignal primitiveWait primitiveResume primitiveSuspend"
	  or: [primitiveIndex = 167]] "primitiveYield"
]

{ #category : #'debug support' }
StackInterpreter >> capturePendingFinalizationSignals [
	statPendingFinalizationSignals := pendingFinalizationSignals.

]

{ #category : #'object access primitives' }
StackInterpreter >> changeClassOf: rcvr to: argClass [
	"Change the class of the receiver into the class specified by the argument given that the format of the receiver matches the format of the argument. Fail if receiver or argument are SmallIntegers, or the receiver is an instance of a compact class and the argument isn't, or when the argument's class is compact and the receiver isn't, or when the format of the receiver is different from the format of the argument's class, or when the arguments class is fixed and the receiver's size differs from the size that an instance of the argument's class should have."
	| classHdr sizeHiBits byteSize argFormat rcvrFormat ccIndex |
	"Check what the format of the class says"
	classHdr := self formatOfClass: argClass. "Low 2 bits are 0"

	"Compute the size of instances of the class (used for fixed field classes only)"
	sizeHiBits := (classHdr bitAnd: 16r60000) >> 9.
	classHdr := classHdr bitAnd: 16r1FFFF.
	byteSize := (classHdr bitAnd: SizeMask) + sizeHiBits. "size in bytes -- low 2 bits are 0"

	"Check the receiver's format against that of the class"
	argFormat := self formatOfHeader: classHdr.
	rcvrFormat := self formatOf: rcvr.
	"If the receiver is a byte object we need to clear the number of odd bytes from the format."
	rcvrFormat > 8 ifTrue:
		[rcvrFormat := rcvrFormat bitAnd: 16rC].
	argFormat = rcvrFormat ifFalse:[^self primitiveFailFor: PrimErrInappropriate]. "no way"

	"For fixed field classes, the sizes must match.
	Note: byteSize-4 because base header is included in class size."
	argFormat < 2
		ifTrue:
			[(byteSize - BaseHeaderSize) ~= (self byteSizeOf: rcvr) ifTrue:
				[^self primitiveFailFor: PrimErrBadReceiver]]
		ifFalse:
			[argFormat = 3 ifTrue: "For indexable plus fixed fields the receiver must be at least big enough."
				[(byteSize - BaseHeaderSize) > (self byteSizeOf: rcvr) ifTrue:
					[^self primitiveFailFor: PrimErrBadReceiver]]].

	(self headerType: rcvr) = HeaderTypeShort
		ifTrue:[ "Compact classes. Check if the arg's class is compact and exchange ccIndex"
			ccIndex := classHdr bitAnd: CompactClassMask.
			ccIndex = 0 ifTrue:[^self primitiveFailFor: PrimErrInappropriate]. "class is not compact"
			self longAt: rcvr put:
				(((self longAt: rcvr) bitAnd: CompactClassMask bitInvert32)
					bitOr: ccIndex)]
		ifFalse:["Exchange the class pointer, which could make rcvr a root for argClass"
			self longAt: rcvr-BaseHeaderSize put: (argClass bitOr: (self headerType: rcvr)).
			(self oop: rcvr isLessThan: youngStart)
				ifTrue: [self possibleRootStoreInto: rcvr value: argClass]].

	"Flush at cache because rcvr's class has changed."
	self flushAtCache
]

{ #category : #'indexing primitive support' }
StackInterpreter >> characterForAscii: ascii [  "Arg must lie in range 0-255!"
	<inline: true>
	^ self fetchPointer: ascii ofObject: (self splObj: CharacterTable)
]

{ #category : #initialization }
StackInterpreter >> checkAssumedCompactClasses [
	"Check that the classes the VM assumes are compact have the right indices."

	self checkCompactIndex: ClassArrayCompactIndex isClass: ClassArray named: 'Array'.
	self checkCompactIndex: ClassLargeNegativeIntegerCompactIndex isClass: ClassLargeNegativeInteger named: 'LargeNegativeInteger'.
	self checkCompactIndex: ClassLargePositiveIntegerCompactIndex isClass: ClassLargePositiveInteger named: 'LargePositiveInteger'.
	self checkCompactIndex: ClassFloatCompactIndex isClass: ClassFloat named: 'Float'.
	self checkCompactIndex: ClassBlockClosureCompactIndex isClass: ClassBlockClosure named: 'BlockClosure'.
	self checkCompactIndex: ClassMethodContextCompactIndex isClass: ClassMethodContext named: 'MethodContext'
]

{ #category : #'arithmetic primitive support' }
StackInterpreter >> checkBooleanResult: result [
	self successful
		ifTrue: [self pushBool: result]
		ifFalse: [self unPop: 2]
]

{ #category : #'object memory support' }
StackInterpreter >> checkCodeIntegrity: fullGCFlag [
	"This is a no-op in the StackVM"
	^true
]

{ #category : #'process primitive support' }
StackInterpreter >> checkCogCompiledCodeCompactionCalledFor [
	"This is a no-op in the StackVM"
]

{ #category : #'primitive support' }
StackInterpreter >> checkDeliveryOfLongRunningPrimitiveSignal [
	"Check for a hit of the longRunningPrimitive probe and if so attempt to signal the
	 longRunningPrimitiveCheckSemaphore.  Answer if a process switch occurred as a result."
	<inline: true>
	(longRunningPrimitiveStopUsecs > longRunningPrimitiveStartUsecs "a hit"
	 and: [longRunningPrimitiveCheckSemaphore notNil "deliverable"
	 and: [longRunningPrimitiveSignalUndelivered]]) ifTrue: "but not yet delivered"
		[longRunningPrimitiveSignalUndelivered := false.
		 longRunningPrimitiveGCUsecs := (gcStartUsecs < longRunningPrimitiveStopUsecs
										   and: [statGCEndUsecs > longRunningPrimitiveStartUsecs])
											ifTrue: [statGCEndUsecs - gcStartUsecs]
											ifFalse: [0].
		"Signal the LRP check semaphore if it is present"
		^self synchronousSignal: longRunningPrimitiveCheckSemaphore].
	^false
]

{ #category : #'process primitive support' }
StackInterpreter >> checkForEventsMayContextSwitch: mayContextSwitch [
	"Check for possible interrupts and handle one if necessary.
	 Answer if a context switch has occurred."
	| switched sema now |
	<inline: false>
	<var: #now type: #usqLong>
	self assertCStackCorrectlyAligned.
	statCheckForEvents := statCheckForEvents + 1.

	"restore the stackLimit if it has been smashed."
	self restoreStackLimit.
	self externalWriteBackHeadFramePointers.
	self assert: stackPage = stackPages mostRecentlyUsedPage.

	"Allow the platform to do anything it needs to do synchronously."
	self ioSynchronousCheckForEvents.

	self checkCogCompiledCodeCompactionCalledFor.

	needGCFlag ifTrue:
		[needGCFlag := false.
		"sufficientSpaceAfterGC: runs the incremental GC and
		 then, if not enough space is available, the fullGC."
		 (self sufficientSpaceAfterGC: 0) ifFalse:
			[self setSignalLowSpaceFlagAndSaveProcess]].

	mayContextSwitch ifFalse: [^false].

	switched := false.

	(profileProcess ~= nilObj
	 or: [nextProfileTick > 0 and:[self ioHighResClock >= nextProfileTick]]) ifTrue:
		["Take a sample (if not already done so) for the profiler if it is active.  This
		  must be done before any of the synchronousSignals below or else we will
		  attribute a pause in ioRelinquishProcessor to the newly activated process."
		profileProcess = nilObj ifTrue:
			[profileProcess := self activeProcess.
			 profileMethod := nilObj].
		"and signal the profiler semaphore if it is present"
		(profileSemaphore ~= nilObj 
		 and: [self synchronousSignal: profileSemaphore]) ifTrue:
			[switched := true].
		nextProfileTick := 0].

	self checkDeliveryOfLongRunningPrimitiveSignal ifTrue:
		[switched := true].

	signalLowSpace ifTrue:
		[signalLowSpace := false. "reset flag"
		 sema := self splObj: TheLowSpaceSemaphore.
		 (sema ~= nilObj 
		  and: [self synchronousSignal: sema]) ifTrue:
			[switched := true]].

	(now := self ioUTCMicroseconds) >= nextPollUsecs ifTrue:
		[statIOProcessEvents := statIOProcessEvents + 1.
		 self ioProcessEvents.
		 "sets interruptPending if interrupt key pressed"
		 nextPollUsecs := now + 20000
		 "msecs to wait before next call to ioProcessEvents.  Note that strictly
		  speaking we might need to update 'now' at this point since
		  ioProcessEvents could take a very long time on some platforms"].
	interruptPending ifTrue:
		[interruptPending := false.
		 "reset interrupt flag"
		 sema := self splObj: TheInterruptSemaphore.
		 (sema ~= nilObj 
		  and: [self synchronousSignal: sema]) ifTrue:
			[switched := true]].

	nextWakeupUsecs ~= 0 ifTrue:
		[now >= nextWakeupUsecs ifTrue:
			[nextWakeupUsecs := 0.
			 "set timer interrupt to 0 for 'no timer'"
			 sema := self splObj: TheTimerSemaphore.
			 (sema ~= nilObj 
			  and: [self synchronousSignal: sema]) ifTrue:
				[switched := true]]].

	"signal any pending finalizations"
	pendingFinalizationSignals > 0 ifTrue:
		[sema := self splObj: TheFinalizationSemaphore.
		 ((self isNonIntegerObject: sema)
		  and: [(self fetchClassOfNonInt: sema) = (self splObj: ClassSemaphore)
		  and: [self synchronousSignal: sema]]) ifTrue:
			[switched := true].
		pendingFinalizationSignals := 0].

	"signal all semaphores in semaphoresToSignal"
	self signalExternalSemaphores ifTrue:
		[switched := true].

	^switched
]

{ #category : #'primitive support' }
StackInterpreter >> checkForLongRunningPrimitive [
	"Called from forceInterruptCheckFromHeartbeat.  If the system has been running
	 the same primitive on two successive heartbeats then signal profileMethod."
	<inline: true>
	longRunningPrimitiveCheckSemaphore isNil ifTrue:
		[^nil].
	(longRunningPrimitiveStartUsecs > 0
	 and: [longRunningPrimitiveCheckMethod = newMethod
	 and: [longRunningPrimitiveCheckSequenceNumber = statCheckForEvents]]) ifTrue:
		[longRunningPrimitiveStopUsecs := self ioUTCMicroseconds.
		self assert: longRunningPrimitiveStopUsecs > longRunningPrimitiveStartUsecs.
		^nil].
	longRunningPrimitiveStopUsecs = 0 ifTrue:
		[longRunningPrimitiveCheckMethod := newMethod.
		 longRunningPrimitiveStartUsecs := self ioUTCMicroseconds.
		 longRunningPrimitiveCheckSequenceNumber := statCheckForEvents]
]

{ #category : #'image save/restore' }
StackInterpreter >> checkImageVersionFrom: f startingAt: imageOffset [
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
	^false
]

{ #category : #'arithmetic primitive support' }
StackInterpreter >> checkIntegerResult: integerResult [
	(self successful and: [self isIntegerValue: integerResult])
		ifTrue: [self pushInteger: integerResult]
		ifFalse: [self unPop: 2]
]

{ #category : #'object memory support' }
StackInterpreter >> checkInterpreterIntegrity [
	"Perform an integrity/leak check using the heapMap.  Assume
	 clearLeakMapAndMapAccessibleObjects has set a bit at each
	 object's header.  Check that all oops in the interpreter's state
	 points to a header.  Answer if all checks pass."
	| ok |
	ok := true.
	(self checkOopIntegrity: specialObjectsOop named: 'specialObjectsOop')ifFalse:
		[ok := false].
	(self isIntegerObject: messageSelector) ifFalse:
		[(self checkOopIntegrity: messageSelector named: 'messageSelector')ifFalse:
			[ok := false]].
	(self checkOopIntegrity: newMethod named: 'newMethod')ifFalse:
		[ok := false].
	(self checkOopIntegrity: lkupClass named: 'lkupClass')ifFalse:
		[ok := false].
	(self checkOopIntegrity: profileProcess named: 'profileProcess')ifFalse:
		[ok := false].
	(self checkOopIntegrity: profileMethod named: 'profileMethod')ifFalse:
		[ok := false].
	(self checkOopIntegrity: profileSemaphore named: 'profileSemaphore')ifFalse:
		[ok := false].
	primResult = 0 ifFalse:
		[(self checkOopIntegrity: primResult named: 'primResult')ifFalse:
			[ok := false]].

	"Callback support - check suspended callback list"
	1 to: jmpDepth do:
		[:i|
		(self checkOopIntegrity: (suspendedCallbacks at: i) named: 'suspendedCallbacks' index: i) ifFalse:
			[ok := false].
		(self checkOopIntegrity: (suspendedMethods at: i) named: 'suspendedMethods' index: i) ifFalse:
			[ok := false]].

	self checkLogIntegrity ifFalse:
		[ok := false].

	^ok
]

{ #category : #'frame access' }
StackInterpreter >> checkIsStillMarriedContext: aContext currentFP: currentFP [
	"Another version of isWidowedContext:currentFP: for debugging.
	 This will not bereave a widowed context."
	| thePage theFP limitFP |
	<inline: false>
	<var: #currentFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<var: #limitFP type: #'char *'>
	(self isIntegerObject: (self fetchPointer: SenderIndex ofObject: aContext)) ifFalse:
		[^false].
	theFP := self frameOfMarriedContext: aContext.
	thePage := stackPages stackPageFor: theFP.
	limitFP := (thePage = stackPage and: [currentFP notNil])
				ifTrue: [currentFP]
				ifFalse: [thePage headFP].
	^theFP >= limitFP
	   and: [(self isNonIntegerObject: (self frameCallerFP: theFP) asInteger)
	   and: [(self withSmallIntegerTags: (self frameCallerFP: theFP))
			= (self fetchPointer: InstructionPointerIndex ofObject: aContext)
	   and: [(self frameMethodObject: theFP)
			= (self fetchPointer: MethodIndex ofObject: aContext)
	   and: [(self frameHasContext: theFP)
	   and: [(self frameContext: theFP) = aContext
	   and: [self isContext: aContext]]]]]]
]

{ #category : #'object memory support' }
StackInterpreter >> checkLogIntegrity [
	"This is a no-op in the StackInterpreter"
	^true
]

{ #category : #'process primitive support' }
StackInterpreter >> checkProfileTick: aPrimitiveMethod [
	"Check if the profile timer has expired and if so take a sample.
	 If the primitive has failed sample the profileMethod as nil."
	<inline: true>
	<asmLabel: false>
	self assert: nextProfileTick ~= 0.
	self ioHighResClock >= nextProfileTick ifTrue:
		[profileProcess :=  self activeProcess.
		 profileMethod := self successful ifTrue: [aPrimitiveMethod] ifFalse: [nilObj].
		 self forceInterruptCheck.
		 nextProfileTick := 0]
]

{ #category : #'object memory support' }
StackInterpreter >> checkStackIntegrity [
	"Perform an integrity/leak check using the heapMap.  Assume
	 clearLeakMapAndMapAccesibleObjects has set a bit at each
	 object's header.  Scan all objects accessible from the stack
	 checking that every pointer points to a header.  Answer if no
	 dangling pointers were detected."
	| ok |
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	ok := true.
	0 to: numStackPages - 1 do:
		[:i| | thePage theSP theFP callerFP oop |
		thePage := stackPages stackPageAt: i.
		(stackPages isFree: thePage) ifFalse:
			[thePage = stackPage
				ifTrue:
					[theSP := stackPointer.
					 theFP := framePointer]
				ifFalse:
					[theSP := thePage headSP.
					 theFP := thePage  headFP].
			 "Skip the instruction pointer on top of stack of inactive pages."
			 thePage = stackPage ifFalse:
				[theSP := theSP + BytesPerWord].
			 [[theSP <= (theFP + FoxReceiver)] whileTrue:
				[oop := stackPages longAt: theSP.
				 ((self isNonIntegerObject: oop) 
				   and: [(self heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
					[self printFrameThing: 'object leak in frame temp' at: theSP; cr.
					 ok := false].
				 theSP := theSP + BytesPerWord].
			 (self frameHasContext: theFP) ifTrue:
				[oop := self frameContext: theFP.
				 ((self isIntegerObject: oop) 
				   or: [(self heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
					[self printFrameThing: 'object leak in frame ctxt' at: theFP + FoxThisContext; cr.
					 ok := false].
				 (self isContext: oop) ifFalse:
					[self printFrameThing: 'frame ctxt should be context' at: theFP + FoxThisContext; cr.
					 ok := false]].
			 oop := self frameMethod: theFP.
			 ((self isIntegerObject: oop) 
			   or: [(self heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
				[self printFrameThing: 'object leak in frame mthd' at: theFP + FoxMethod; cr.
				 ok := false].
			 (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
				[theSP := theFP + FoxCallerSavedIP + BytesPerWord.
				 theFP := callerFP].
			 theSP := theFP + FoxCallerContext "a.k.a. FoxCallerSavedIP".
			 [theSP <= thePage baseAddress] whileTrue:
				[oop := stackPages longAt: theSP.
				 ((self isNonIntegerObject: oop) 
				   and: [(self heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
					[self printFrameThing: 'object leak in frame arg' at: theSP; cr.
					 ok := false].
				 theSP := theSP + BytesPerWord]]].
	^ok
]

{ #category : #utilities }
StackInterpreter >> checkedIntegerValueOf: intOop [
	"Note: May be called by translated primitive code."

	(self isIntegerObject: intOop)
		ifTrue: [ ^ self integerValueOf: intOop ]
		ifFalse: [ self primitiveFail. ^ 0 ]
]

{ #category : #'plugin primitive support' }
StackInterpreter >> classNameOf: aClass Is: className [ 
	"Check if aClass's name is className"
	| srcName name length |
	<var: #className type: #'char *'>
	<var: #srcName type: #'char *'>
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
StackInterpreter >> closureIn: context numArgs: numArgs instructionPointer: initialIP copiedValues: copiedValues [
	| newClosure numCopied |
	<inline: true>
	"numCopied should be zero for nil"
	numCopied := self fetchWordLengthOf: copiedValues.
	newClosure := self
					eeInstantiateSmallClass: (self splObj: ClassBlockClosure)
					sizeInBytes: (BytesPerWord * (ClosureFirstCopiedValueIndex + numCopied)) + BaseHeaderSize.
	"Assume: have just allocated a new closure; it must be young. Thus, can use unchecked stores."
	self storePointerUnchecked: ClosureOuterContextIndex ofObject: newClosure withValue: context.
	self storePointerUnchecked: ClosureStartPCIndex ofObject: newClosure withValue: (self integerObjectOf: initialIP).
	self storePointerUnchecked: ClosureNumArgsIndex ofObject: newClosure withValue: (self integerObjectOf: numArgs).
	0 to: numCopied - 1 do:
		[:i|
		self storePointerUnchecked: i + ClosureFirstCopiedValueIndex
			ofObject: newClosure
			withValue: (self fetchPointer: i ofObject: copiedValues)].
	^newClosure
]

{ #category : #'control primitives' }
StackInterpreter >> closureIn: context numArgs: numArgs instructionPointer: initialIP numCopiedValues: numCopied [
	| newClosure |
	<inline: true>
	self assert: (BytesPerWord * (ClosureFirstCopiedValueIndex + numCopied)) + BaseHeaderSize <= 252.
	newClosure := self
					eeInstantiateSmallClass: (self splObj: ClassBlockClosure)
					sizeInBytes: (BytesPerWord * (ClosureFirstCopiedValueIndex + numCopied)) + BaseHeaderSize.
	"Assume: have just allocated a new closure; it must be young. Thus, can use unchecked stores."
	self storePointerUnchecked: ClosureOuterContextIndex ofObject: newClosure withValue: context.
	self storePointerUnchecked: ClosureStartPCIndex ofObject: newClosure withValue: (self integerObjectOf: initialIP).
	self storePointerUnchecked: ClosureNumArgsIndex ofObject: newClosure withValue: (self integerObjectOf: numArgs).
	^newClosure
]

{ #category : #'indexing primitive support' }
StackInterpreter >> commonAt: stringy [
	"This code is called if the receiver responds primitively to at:.
	 If this is so, it will be installed in the atCache so that subsequent calls of at:
	 or next may be handled immediately in bytecode primitive routines."
	| index rcvr atIx result |
	self initPrimCall.
	rcvr := self stackValue: 1.
	(self isNonIntegerObject: rcvr) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	index := self stackTop.
	"No need to test for large positive integers here.  No object has 1g elements"
	(self isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := self integerValueOf: index.

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
StackInterpreter >> commonAtPut: stringy [
	"This code is called if the receiver responds primitively to at:Put:.
	If this is so, it will be installed in the atPutCache so that subsequent calls of at:
	or  next may be handled immediately in bytecode primitive routines."
	| value index rcvr atIx |
	value := self stackTop.
	self initPrimCall.
	rcvr := self stackValue: 2.
	(self isNonIntegerObject: rcvr) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	index := self stackValue: 1.
	"No need to test for large positive integers here.  No object has 1g elements"
	(self isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := self integerValueOf: index.

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
		self successful ifTrue:
			[self commonVariable: rcvr at: index put: value cacheIndex: atIx].
		self successful ifTrue:
			[^ self pop: argumentCount+1 thenPush: value]].

	"The slow but sure way..."
	self initPrimCall.
	stringy
		ifTrue: [self stObject: rcvr at: index put: (self asciiOfCharacter: value)]
		ifFalse: [self stObject: rcvr at: index put: value].
	self successful ifTrue:
		[^ self pop: argumentCount+1 thenPush: value]
]

{ #category : #'return bytecodes' }
StackInterpreter >> commonCallerReturn [
	"Return to the previous context/frame (sender for method activations, caller for block activations)."
	| callersFPOrNull |
	<var: #callersFPOrNull type: #'char *'>
	<sharedCodeNamed: 'commonCallerReturn' inCase: 125> "returnTopFromBlock"

	callersFPOrNull := self frameCallerFP: localFP.
	callersFPOrNull == 0 "baseFrame" ifTrue:
		[self assert: localFP = stackPage baseFP.
		 ^self baseFrameReturn].

	localIP := self frameCallerSavedIP: localFP.
	localSP := localFP + (self frameStackedReceiverOffset: localFP).
	localFP := callersFPOrNull.
	self internalStackTopPut: localReturnValue.
	self fetchNextBytecode.
	^self setMethod: (self frameMethod: localFP)
]

{ #category : #'return bytecodes' }
StackInterpreter >> commonReturn [
	"Note: Assumed to be inlined into the dispatch loop."

	| closure home unwindContextOrNilOrZero frameToReturnTo contextToReturnTo theFP callerFP newPage |
	<var: #frameToReturnTo type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #newPage type: #'StackPage *'>
	<var: #thePage type: #'StackPage *'>
	<sharedCodeNamed: 'commonReturn' inCase: 120>

	"If this is a method simply return to the  sender/caller."
	(self frameIsBlockActivation: localFP) ifFalse:
		[^self commonCallerReturn].

	"Since this is a block activation the closure is on the stack above any args and the frame."
	closure := self pushedReceiverOrClosureOfFrame: localFP.

	home := nil.
	"Walk the closure's lexical chain to find the context or frame to return from (home)."
	[closure ~~ nilObj] whileTrue:
		[home := self fetchPointer: ClosureOuterContextIndex ofObject: closure.
		 closure := self fetchPointer: ClosureIndex ofObject: home].
	"home is to be returned from provided there is no unwind-protect activation between
	 this frame and home's sender.  Search for an unwind.  findUnwindThroughContext:
	 will answer either the context for an unwind-protect activation or nilObj if the sender
	 cannot be found or 0 if no unwind is found but the sender is.  We must update the
	 current page's headFrame pointers to enable the search to identify widowed contexts
	 correctly."
	self writeBackHeadFramePointers.
	unwindContextOrNilOrZero := self internalFindUnwindThroughContext: home.
	unwindContextOrNilOrZero = nilObj ifTrue:
		["error: can't find home on chain; cannot return"
		 ^self internalCannotReturn: localReturnValue].
	unwindContextOrNilOrZero ~~ 0 ifTrue:
		[^self internalAboutToReturn: localReturnValue through: unwindContextOrNilOrZero].

	"Now we know home is on the sender chain.
	 We could be returning to either a context or a frame.  Find out which."
	contextToReturnTo := nil.
	(self isMarriedOrWidowedContext: home)
		ifTrue:
			[self assert: (self checkIsStillMarriedContext: home currentFP: localFP).
			 theFP := self frameOfMarriedContext: home.
			 (self isBaseFrame: theFP)
				ifTrue:
					[contextToReturnTo := self frameCallerContext: theFP]
				ifFalse:
					[frameToReturnTo := self frameCallerFP: theFP]]
		ifFalse:
			[contextToReturnTo := self fetchPointer: SenderIndex ofObject: home.
			 ((self isContext: contextToReturnTo)
			  and: [self isMarriedOrWidowedContext: contextToReturnTo]) ifTrue:
				[self assert: (self checkIsStillMarriedContext: contextToReturnTo currentFP: localFP).
			 	 frameToReturnTo := self frameOfMarriedContext: contextToReturnTo.
				 contextToReturnTo := nil]].

	"If returning to a context we must make a frame for it unless it is dead."
	contextToReturnTo ~= nil ifTrue:
		[frameToReturnTo := self establishFrameForContextToReturnTo: contextToReturnTo.
		 frameToReturnTo == 0 ifTrue:
			["error: home's sender is dead; cannot return"
			 ^self internalCannotReturn: localReturnValue]].

	"Now we have a frame to return to.  If it is on a different page we must
	 free intervening pages and nil out intervening contexts.  We must free
	 intervening stack pages because if we leave the pages to be divorced
	 then their contexts will be divorced with intact senders and instruction
	 pointers.  This code is similar to primitiveTerminateTo."
	self assert: stackPages pageListIsWellFormed.
	newPage := stackPages stackPageFor: frameToReturnTo.
	newPage ~~ stackPage ifTrue:
		[| currentCtx thePage nextCntx |
		 currentCtx := self frameCallerContext: stackPage baseFP.
		 self assert: (self isContext: currentCtx).
		 stackPages freeStackPage: stackPage.
		 [(self isMarriedOrWidowedContext: currentCtx)
		   and: [(stackPages stackPageFor: (theFP := self frameOfMarriedContext: currentCtx)) = newPage]] whileFalse:
			[(self isMarriedOrWidowedContext: currentCtx)
				ifTrue:
					[thePage := stackPages stackPageFor: theFP.
					 currentCtx := self frameCallerContext: thePage baseFP.
					 self freeStackPage: thePage]
				ifFalse:
					[self assert: (self isContext: currentCtx).
					 nextCntx := self fetchPointer: SenderIndex ofObject: currentCtx.
					 self storePointerUnchecked: SenderIndex ofObject: currentCtx withValue: nilObj.
					 self storePointerUnchecked: InstructionPointerIndex ofObject: currentCtx withValue: nilObj.
					 currentCtx := nextCntx]].
		 self setStackPageAndLimit: newPage.
		 localSP := stackPage headSP.
		 localFP := stackPage headFP].

	"Two cases.  Returning to the top frame or an interior frame.
	 The top frame has its instruction pointer on top of stack.
	 An interior frame has its instruction pointer in the caller frame.
	 We need to peel back any frames on the page until we get to the correct frame."

	localFP = frameToReturnTo
		ifTrue: "pop the saved IP, push the return value and continue."
			[localIP := self pointerForOop: self internalStackTop]
		ifFalse:
			[[callerFP := localFP.
			  localFP := self frameCallerFP: localFP.
			  localFP ~~ frameToReturnTo] whileTrue.
			localIP := self frameCallerSavedIP: callerFP.
			localSP := (self frameCallerSP: callerFP) - BytesPerWord].
	self internalStackTopPut: localReturnValue.
	self setMethod: (self frameMethod: localFP).
	^self fetchNextBytecode
]

{ #category : #'message sending' }
StackInterpreter >> commonSend [
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that 
	the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeNamed: 'commonSend' inCase: 131>
	self sendBreak: messageSelector + BaseHeaderSize
		point: (self lengthOf: messageSelector)
		receiver: (self internalStackValue: argumentCount).
	self internalFindNewMethod.
	self internalExecuteNewMethod.
	self fetchNextBytecode
]

{ #category : #'indexing primitive support' }
StackInterpreter >> commonVariable: rcvr at: index cacheIndex: atIx [ 
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
			 ^self positive32BitIntegerFor: result].
		fmt >= 16  "Note fmt >= 16 is an artificial flag for strings"
			ifTrue: "String"
			[^ self characterForAscii: (self fetchByte: index - 1 ofObject: rcvr)]
			ifFalse: "ByteArray"
			[^ self integerObjectOf: (self fetchByte: index - 1 ofObject: rcvr)]].

	^self primitiveFailFor: PrimErrBadIndex
]

{ #category : #'indexing primitive support' }
StackInterpreter >> commonVariable: rcvr at: index put: value cacheIndex: atIx [
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
			self successful ifTrue: [self storeLong32: index - 1 ofObject: rcvr withValue: valToPut].
			^ nil].
		fmt >= 16  "Note fmt >= 16 is an artificial flag for strings"
			ifTrue: [valToPut := self asciiOfCharacter: value.
					self successful ifFalse: [^ nil]]
			ifFalse: [valToPut := value].
		(self isIntegerObject: valToPut) ifTrue:
			[valToPut := self integerValueOf: valToPut.
			((valToPut >= 0) and: [valToPut <= 255]) ifFalse: [^ self primitiveFail].
			^ self storeByte: index - 1 ofObject: rcvr withValue: valToPut]].

	^self primitiveFailFor: PrimErrBadIndex
]

{ #category : #'arithmetic primitive support' }
StackInterpreter >> compare31or32Bits: obj1 equal: obj2 [
	"May set success to false"

	"First compare two ST integers..."
	((self isIntegerObject: obj1)
		and: [self isIntegerObject: obj2])
		ifTrue: [^ obj1 = obj2].

	"Now compare, assuming positive integers, but setting fail if not"
	^ (self positive32BitValueOf: obj1) = (self positive32BitValueOf: obj2)
]

{ #category : #initialization }
StackInterpreter >> computeStackZoneSize [
	"In C the StackPage structs live next to the actual stack pages in the alloca'ed stack
	 zone.  In simulation these live in some dictionary and don't exist in the memory."
	^numStackPages * ((self cCode: 'sizeof(StackPage)' inSmalltalk: [0])
						+ self stackPageByteSize)
	 + stackPages extraStackBytes
]

{ #category : #'internal interpreter access' }
StackInterpreter >> context: thisCntx hasSender: aContext [ 
	"Does thisCntx have aContext in its sender chain?
	 Cheapo implementation above extant machinery."
	| handlerOrNilOrZero |
	<inline: true>
	handlerOrNilOrZero := self
							findMethodWithPrimitive: -1
							FromContext: thisCntx
							UpToContext: aContext.
	^handlerOrNilOrZero == 0
]

{ #category : #'frame access' }
StackInterpreter >> contextInstructionPointer: theIP frame: theFP [
	<var: #theFP type: #'char *'>
	self assert: (self validInstructionPointer: theIP inFrame: theFP).
	^self integerObjectOf: theIP - (self iframeMethod: theFP) - BaseHeaderSize + 2
]

{ #category : #'image save/restore' }
StackInterpreter >> convertFloatsToPlatformOrderFrom: startOop to: stopAddr [ 
	"Byte-swap the words of all bytes objects in a range of the 
	 image, including Strings, ByteArrays, and CompiledMethods.
	 This returns these objects to their original byte ordering 
	 after blindly byte-swapping the entire image. For compiled 
	 methods, byte-swap only their bytecodes part.
	 Ensure floats are in platform-order."
	| oop temp |
	self vmEndianness = imageFloatsBigEndian ifTrue:
		[^self].
	self assert: ClassFloatCompactIndex ~= 0.
	oop := startOop.
	[self oop: oop isLessThan: stopAddr] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[(self compactClassIndexOf: oop) = ClassFloatCompactIndex ifTrue:
				[temp := self longAt: oop + BaseHeaderSize.
				 self longAt: oop + BaseHeaderSize put: (self longAt: oop + BaseHeaderSize + 4).
				 self longAt: oop + BaseHeaderSize + 4 put: temp]].
		 oop := self objectAfter: oop]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> copiedValueCountOfClosure: closurePointer [

	^(self fetchWordLengthOf: closurePointer) - ClosureFirstCopiedValueIndex
]

{ #category : #'bitblt support' }
StackInterpreter >> copyBits [
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
StackInterpreter >> copyBitsFrom: x0 to: x1 at: y [
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
StackInterpreter >> copyObj: oop toSegment: segmentWordArray addr: lastSeg stopAt: stopAddr saveOopAt: oopPtr headerAt: hdrPtr [
	"Copy this object into the segment beginning at lastSeg.
	Install a forwarding pointer, and save oop and header.
	Fail if out of space.  Return the next segmentAddr if successful."

	"Copy the object..."
	| extraSize bodySize hdrAddr |
	self flag: #Dan.  "None of the imageSegment stuff has been updated for 64 bits"
	self successful ifFalse: [^ lastSeg].
	extraSize := self extraHeaderBytes: oop.
	bodySize := self sizeBitsOf: oop.
	(self oop: (lastSeg + extraSize + bodySize) isGreaterThanOrEqualTo: stopAddr)
		ifTrue: [^ self primitiveFail].
	self transfer: extraSize + bodySize // BytesPerWord  "wordCount"
		from: oop - extraSize
		to: lastSeg+BytesPerWord.

	"Clear root and mark bits of all headers copied into the segment"
	hdrAddr := lastSeg+BytesPerWord + extraSize.
	self longAt: hdrAddr put: ((self longAt: hdrAddr) bitAnd: AllButRootBit - MarkBit).

	self forward: oop to: (lastSeg+BytesPerWord + extraSize - segmentWordArray)
		savingOopAt: oopPtr andHeaderAt: hdrPtr.

	"Return new end of segment"
	^ lastSeg + extraSize + bodySize
]

{ #category : #'debug printing' }
StackInterpreter >> cr [
	"For testing in Smalltalk, this method should be overridden in a subclass."
	<inline: true>
	self printf: '\n'
]

{ #category : #'message sending' }
StackInterpreter >> createActualMessageTo: lookupClass [ 
	"Bundle up the selector, arguments and lookupClass into a Message object. 
	 In the process it pops the arguments off the stack, and pushes the message object. 
	 This can then be presented as the argument of e.g. #doesNotUnderstand:"
	| argumentArray message |
	<inline: false> "This is a useful break-point"
	self assert: ((self isIntegerObject: messageSelector) or: [self addressCouldBeObj: messageSelector]).
	argumentArray := self eeInstantiateClass: (self splObj: ClassArray) indexableSize: argumentCount.
	message := self eeInstantiateClass: (self splObj: ClassMessage) indexableSize: 0.

	"Since the array is new can use unchecked stores."
	(argumentCount - 1) * BytesPerWord to: 0 by: BytesPerWord negated do:
		[:i|
		self longAt:  argumentArray + BaseHeaderSize + i put: self popStack].
	"Since message is new can use unchecked stores."
	self storePointerUnchecked: MessageSelectorIndex ofObject: message withValue: messageSelector.
	self storePointerUnchecked: MessageArgumentsIndex ofObject: message withValue: argumentArray.
	self storePointerUnchecked: MessageLookupClassIndex ofObject: message withValue: lookupClass.

	self push: message.

	argumentCount := 1.
]

{ #category : #utilities }
StackInterpreter >> dbgFloatValueOf: oop [
	"This version answers the value of a float or nil if not a flat *WITHOUT* setting successFlag or any other such nonsense.  It is hence safe for use in debug printing.  Sheesh."

	| result |
	<returnTypeC: #double>
	<var: #result type: #double>
	self flag: #Dan.  "None of the float stuff has been converted for 64 bits"
	((self isNonIntegerObject: oop)
	and: [(self fetchClassOfNonInt: oop) = (self splObj: ClassFloat)]) ifTrue:
		[self cCode: '' inSmalltalk: [result := Float new: 2].
		 self fetchFloatAt: oop + BaseHeaderSize into: result.
		 ^result].
	^nil
]

{ #category : #initialization }
StackInterpreter >> defaultNumStackPages [
	"Return the default number of stack pages allocate at startup.
	 This default suits Qwaq Forums (specifically general rendering).
	 It is probably a bit high for normal use but QF is profligate with processes.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file."
	<inline: false>
	^160
]

{ #category : #'message sending' }
StackInterpreter >> dispatchFunctionPointer: aFunctionPointer [
	"In C aFunctionPointer is void (*aFunctionPointer)()"
	<cmacro: '(aFunctionPointer) (aFunctionPointer)()'>
	(aFunctionPointer isInteger
	 and: [aFunctionPointer >= 1000]) ifTrue:
		[^self callExternalPrimitive: aFunctionPointer].
	"In Smalltalk aFunctionPointer is a message selector symbol"
	^self perform: aFunctionPointer
]

{ #category : #'I/O primitives' }
StackInterpreter >> displayBitsOf: aForm Left: l Top: t Right: r Bottom: b [
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
	]
]

{ #category : #'frame access' }
StackInterpreter >> divorceAllFrames [
	| activeContext |
	<inline: false>
	<var: #aPage type: #'StackPage *'>
	self externalWriteBackHeadFramePointers.
	activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
	0 to: numStackPages - 1 do:
		[:i| | aPage |
		aPage := stackPages stackPageAt: i.
		(stackPages isFree: aPage) ifFalse:
			[self divorceFramesIn: aPage]].
	stackPage := 0.
	^activeContext
]

{ #category : #'frame access' }
StackInterpreter >> divorceFramesIn: aStackPage [
	| theFP calleeFP theSP theIP calleeContext theContext |
	<inline: false>
	<var: #aStackPage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<var: #calleeFP type: #'char *'>
	<var: #theSP type: #'char *'>

	statStackPageDivorce := statStackPageDivorce + 1.

	theFP := aStackPage headFP.
	theSP := aStackPage headSP.
	theIP := stackPages longAt: theSP.
	theSP := theSP + BytesPerWord. "theSP points at hottest item on frame's stack"
	calleeContext := nil.

	[theContext := self ensureFrameIsMarried: theFP SP: theSP.
	 self updateStateOfSpouseContextForFrame: theFP WithSP: theSP.
	 self storePointerUnchecked: InstructionPointerIndex
		ofObject: theContext
		withValue: (self contextInstructionPointer: theIP frame: theFP).
	 self assert: (self frameReceiver: theFP)
				= (self fetchPointer: ReceiverIndex ofObject: theContext).
	 calleeContext ~~ nil ifTrue:
		[self storePointer: SenderIndex
			ofObject: calleeContext
			withValue: theContext].
	 calleeContext := theContext.
	 calleeFP := theFP.
	 theIP := (self frameCallerSavedIP: theFP) asInteger.
	 theFP := self frameCallerFP: theFP.
	 theFP ~= 0] whileTrue:
		["theSP points at stacked hottest item on frame's stack"
		 theSP := self frameCallerSP: calleeFP].

	self storePointer: SenderIndex
		ofObject: theContext
		withValue: (self frameCallerContext: calleeFP).

	"The page is now free; mark it so."
	aStackPage baseFP: 0
]

{ #category : #'arithmetic primitive support' }
StackInterpreter >> doPrimitiveDiv: rcvr by: arg [
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
StackInterpreter >> doPrimitiveMod: rcvr by: arg [
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
StackInterpreter >> doSignalSemaphoreWithIndex: index [
	"Signal the external semaphore with the given index.  Answer if a context switch
	 occurs as a result.  Do not bounds check.  This has been done in the caller."
	<api>
	| xArray semaphoreClass sema |
	xArray := self splObj: ExternalObjectsArray.
	semaphoreClass := self splObj: ClassSemaphore.
	sema := self fetchPointer: index - 1 ofObject: xArray. "Note: semaphore indices are 1-based"
	^(self isNonIntegerObject: sema)
	   and: [(self fetchClassOfNonInt: sema) = semaphoreClass
	   and: [self synchronousSignal: sema]]
]

{ #category : #'send bytecodes' }
StackInterpreter >> doubleExtendedDoAnythingBytecode [
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
		 ^self normalSend].
	opType = 1 ifTrue:
		[messageSelector := self literal: byte3.
		 argumentCount := byte2 bitAnd: 31.
		 ^self superclassSend].
	self fetchNextBytecode.
	opType = 2 ifTrue: [^self pushMaybeContextReceiverVariable: byte3].
	opType = 3 ifTrue: [^self pushLiteralConstant: byte3].
	opType = 4 ifTrue: [^self pushLiteralVariable: byte3].
	top := self internalStackTop.
	opType = 7 ifTrue:
		[^self storePointer: ValueIndex ofObject: (self literal: byte3) withValue: top].
	"opType = 5 is store; opType = 6 = storePop"
	opType = 6 ifTrue:
		[self internalPop: 1].
	^self storeMaybeContextReceiverVariable: byte3 withValue: top
]

{ #category : #initialization }
StackInterpreter >> dummyReferToProxy [
	<inline: false>
	interpreterProxy := interpreterProxy
]

{ #category : #'image save/restore' }
StackInterpreter >> dumpImage: fileName [
	"Dump the entire image out to the given file. Intended for debugging only."
	| f dataSize result |
	<export: true>
	<var: #f type: 'sqImageFile'>

	f := self cCode: 'sqImageFileOpen(pointerForOop(fileName), "wb")'.
	f = nil ifTrue: [^-1].
	dataSize := endOfMemory - self startOfMemory.
	result := self cCode: 'sqImageFileWrite(pointerForOop(memory), sizeof(unsigned char), dataSize, f)'.
	self cCode: 'sqImageFileClose(f)'.
	^result

]

{ #category : #'stack bytecodes' }
StackInterpreter >> duplicateTopBytecode [

	self fetchNextBytecode.
	self internalPush: self internalStackTop.

]

{ #category : #'debug printing' }
StackInterpreter >> elementsPerPrintOopLine [
	^5
]

{ #category : #'frame access' }
StackInterpreter >> encodeFrameFieldHasContext: hasContext "<Boolean>" isBlock: isBlock "<Boolean>" numArgs: numArgs [
	"For ``fast'' temporary access (ok, to mitigate slower temp access) we need
	 fast access to a method's numArgs.  Could have a variable set on save and return.
	 We'll investigate this.  For the moment we just use a byte in the frameFlags
	 field.  This is endian dependent.  Store numArgs in byte at FoxFrameFields + 1.
	 Store hasContext flag in top bit (allows for 64-bit tags) of byte at FoxFrameFields.
	 Make frameFields look like a SmallInteger for the benefit of gc (dubious)."
	"bitsPerWord := BytesPerWord * 8"
	<inline: true>
	^VMBIGENDIAN
		ifTrue: [1
				+ (numArgs << ((BytesPerWord * 8) - 8))
				+ (hasContext ifTrue: [1 << ((BytesPerWord * 8) - 16)] ifFalse: [0])
				+  (isBlock ifTrue: [1 << ((BytesPerWord * 8) - 24)] ifFalse: [0])]
		ifFalse: [1
				+ (numArgs << 8)
				+  (hasContext ifTrue: [1 << 16] ifFalse: [0])
				+  (isBlock ifTrue: [1 << 24] ifFalse: [0])]
]

{ #category : #'frame access' }
StackInterpreter >> ensureCallerContext: theFP [
	"Answerr the caller context for a frame.  If the frame has a caller
	 frame that doesn't have a context, then marry the caller frame."
	| callerFP |
	<inline: true>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<asmLabel: false>
	callerFP := self frameCallerFP: theFP.
	callerFP = 0 ifTrue: "base frame, context in saved ip slot (or base of stack in Cog)"
		[^self frameCallerContext: theFP].
	^self ensureFrameIsMarried: callerFP SP: (self frameCallerStackPointer: theFP)
]

{ #category : #'frame access' }
StackInterpreter >> ensureFrameIsMarried: theFP SP: theSP [
	<inline: true>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	(self frameHasContext: theFP) ifTrue:
		[self assert: (self isContext: (self frameContext: theFP)).
		^self frameContext: theFP].

	^self marryFrame: theFP SP: theSP
]

{ #category : #'image save/restore' }
StackInterpreter >> ensureImageFormatIsUpToDate: swapBytes [
	"Ensure the image data has been updayed to suit the current VM."
	<inline: false>
	swapBytes
		ifTrue: [self reverseBytesInImage]
		ifFalse: [self convertFloatsToPlatformOrderFrom: self firstObject to: endOfMemory]
]

{ #category : #'frame access' }
StackInterpreter >> establishFrameForContextToReturnTo: contextToReturnTo [
	| thePage |
	<var: #thePage type: #'StackPage *'>
	<returnTypeC: 'char *'>
	(self isContext: contextToReturnTo) ifFalse:
		[^0].
	(self isMarriedOrWidowedContext: contextToReturnTo) ifTrue:
		[(self isWidowedContext: contextToReturnTo) ifTrue:
			["error: home's sender is dead; cannot return"
			 ^0].
		 ^self frameOfMarriedContext: contextToReturnTo].
	(self isIntegerObject: (self fetchPointer: InstructionPointerIndex ofObject: contextToReturnTo)) ifFalse:
		[^0].
	thePage := self makeBaseFrameFor: contextToReturnTo.
	stackPages markStackPageMostRecentlyUsed: thePage.
	^thePage baseFP
]

{ #category : #'message sending' }
StackInterpreter >> executeNewMethod [
	"Execute newMethod - either primitiveFunctionPointer must be set directly
	 (i.e. from primitiveExecuteMethod et al), or it would have been set probing
	 the method cache (i.e. primitivePerform et al)."
	primitiveFunctionPointer ~= 0 ifTrue:
		[self isPrimitiveFunctionPointerAnIndex ifTrue:
			[self externalQuickPrimitiveResponse.
			 ^nil].
		 self slowPrimitiveResponse.
		 self successful ifTrue: [^nil]].
	"if not primitive, or primitive failed, activate the method"
	self activateNewMethod
]

{ #category : #'translation support' }
StackInterpreter >> expandCases [
	"For translation only; noop when running in Smalltalk.
	 Must not be inlined otherwise the directive will disappear!"
	<inline: false>
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extendedPushBytecode [

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
StackInterpreter >> extendedStoreAndPopBytecode [

	self extendedStoreBytecode.
	self internalPop: 1.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> extendedStoreBytecode [
	| descriptor variableType variableIndex association |
	<inline: true>
	descriptor := self fetchByte.
	self fetchNextBytecode.
	variableType := descriptor >> 6 bitAnd: 3.
	variableIndex := descriptor bitAnd: 63.
	variableType = 0 ifTrue:
		[^self storePointer: variableIndex ofObject: self receiver withValue: self internalStackTop].
	variableType = 1 ifTrue:
		[^self temporary: variableIndex in: localFP put: self internalStackTop].
	variableType = 3 ifTrue:
		[association := self literal: variableIndex.
		 ^self storePointer: ValueIndex ofObject: association withValue: self internalStackTop].
	self error: 'illegal store'.
	^nil
]

{ #category : #'frame access' }
StackInterpreter >> externalDivorceFrame: theFP andContext: ctxt [
	"Divorce a single frame and its context.  If it is not the top frame of a stack this means splitting its stack."
	| thePage onCurrent theSP callerCtx newPage frameAbove callerFP callerSP callerIP theIP |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #newPage type: #'StackPage *'>
	<var: #frameAbove type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #callerSP type: #'char *'>
	"stackPage needs to have current head pointers to avoid confusion."
	self assert: theFP ~= framePointer.
	self assert: (stackPage = 0 or: [stackPage = stackPages mostRecentlyUsedPage]).
	thePage := stackPages stackPageFor: theFP.
	(onCurrent := thePage = stackPage) ifFalse:
		[stackPages markStackPageNextMostRecentlyUsed: thePage].
	theSP := self findSPOf: theFP on: thePage.
	self updateStateOfSpouseContextForFrame: theFP WithSP: theSP.
	callerCtx := self ensureCallerContext: theFP.
	(frameAbove := self findFrameAbove: theFP inPage: thePage) == 0
		ifTrue: "If we're divorcing the top frame we can simply peel it off."
			[theIP := stackPages longAt: thePage headSP]
		ifFalse: "othewise move all frames above to a new stack and then peel the frame off."
			[newPage := self newStackPage.
			 theIP := self oopForPointer: (self frameCallerSavedIP: frameAbove).
			 frameAbove := self moveFramesIn: thePage through: frameAbove toPage: newPage.
			 onCurrent
				ifTrue:
					[self setStackPageAndLimit: newPage.
					 framePointer := stackPage headFP.
					 stackPointer := stackPage headSP]
				ifFalse:
					[stackPages markStackPageMostRecentlyUsed: newPage].
			 self assert: (self frameCallerContext: frameAbove) = ctxt].
	self storePointerUnchecked: InstructionPointerIndex
		ofObject: ctxt
		withValue: (self contextInstructionPointer: theIP frame: theFP).
	self storePointer: SenderIndex
		ofObject: ctxt
		withValue: callerCtx.
	callerFP := self frameCallerFP: theFP.
	callerFP == 0 "theFP is a base frame; it is now alone; free the entire page"
		ifTrue: [stackPages freeStackPage: thePage]
		ifFalse:
			[callerIP := self oopForPointer: (self frameCallerSavedIP: theFP).
			 callerSP := (self frameCallerSP: theFP) - BytesPerWord.
			 stackPages longAt: callerSP put: callerIP.
			 self setHeadFP: callerFP andSP: callerSP inPage: thePage]
	
]

{ #category : #'frame access' }
StackInterpreter >> externalEnsureIsBaseFrame: aFramePtr [
	"Ensure aFramePtr is a base frame.  Then we can assign its sender.
	 Answer the possibly moved location of the frame."
	| theFP thePage onCurrent |
	<var: #aFramePtr type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<returnTypeC: 'char *'>
	(self isBaseFrame: aFramePtr) ifTrue:
		[^aFramePtr].
	theFP := aFramePtr.
	thePage := stackPages stackPageFor: theFP.
	onCurrent := thePage = stackPage.
	"Storing the frame's sender with its caller's context
	 has the side effect of making theFP a base frame."
	theFP := self
				storeSenderOfFrame: theFP
				withValue: (self ensureCallerContext: theFP).
	onCurrent
		ifTrue:
			[self assert: stackPage ~~ thePage. "stackPage has moved to a new page"
			 framePointer := stackPage headFP.
			 stackPointer := stackPage headSP]
		ifFalse:
			[stackPages markStackPageMostRecentlyUsed: stackPage].
	self assert: stackPages pageListIsWellFormed.
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	^theFP
]

{ #category : #'frame access' }
StackInterpreter >> externalInstVar: offset ofContext: aContext [
	"Fetch an instance variable from a maybe married context.
	 If the context is still married compute the value of the
	 relevant inst var from the spouse frame's state."
	| spouseFP |
	<var: #spouseFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theFPAbove type: #'char *'>

	self assert: offset < MethodIndex.
	self assert: (self isContext: aContext).
	(self isMarriedOrWidowedContext: aContext) ifFalse:
		[^self fetchPointer: offset ofObject: aContext].

	self externalWriteBackHeadFramePointers.
	(self isWidowedContext: aContext) ifTrue:
		[^self fetchPointer: offset ofObject: aContext].

	spouseFP := self frameOfMarriedContext: aContext.
	offset = SenderIndex ifTrue:
		[^self ensureCallerContext: spouseFP].
	offset = StackPointerIndex ifTrue:
		[self assert: ReceiverIndex + (self stackPointerIndexForFrame: spouseFP) < (self lengthOf: aContext).
		^self integerObjectOf: (self stackPointerIndexForFrame: spouseFP)].
	offset = InstructionPointerIndex ifTrue:
		[| theIP thePage theFPAbove |
		 spouseFP = framePointer
			ifTrue: [theIP := self oopForPointer: instructionPointer]
			ifFalse:
				[thePage := stackPages stackPageFor: spouseFP.
				 theFPAbove := self findFrameAbove: spouseFP inPage: thePage.
				 theIP := theFPAbove == 0
							ifTrue: [stackPages longAt: thePage headSP]
							ifFalse:[self oopForPointer: (self frameCallerSavedIP: theFPAbove)]].
		 ^self contextInstructionPointer: theIP frame: spouseFP].
	self error: 'bad index'.
	^0
]

{ #category : #'frame access' }
StackInterpreter >> externalInstVar: index ofContext: maybeMarriedContext put: anOop [
	| theFP thePage onCurrentPage |
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	self externalWriteBackHeadFramePointers.
	"Assign the field of a married context."
	(self isStillMarriedContext: maybeMarriedContext) ifFalse:
		[self storePointer: index ofObject: maybeMarriedContext withValue: anOop.
		 ^nil].
	theFP := self frameOfMarriedContext: maybeMarriedContext.
	thePage := stackPages stackPageFor: theFP.
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	onCurrentPage := thePage = stackPage.
	index == SenderIndex
		ifTrue:
			[self storeSenderOfFrame: theFP withValue: anOop]
		ifFalse:
			[self externalDivorceFrame: theFP andContext: maybeMarriedContext.
			 self storePointer: index ofObject: maybeMarriedContext withValue: anOop].
	onCurrentPage
		ifTrue:
			[framePointer := stackPage headFP.
			 stackPointer := stackPage headSP]
		ifFalse:
			[stackPages markStackPageMostRecentlyUsed: stackPage].
	stackPages assert: stackPage = stackPages mostRecentlyUsedPage.
	stackPages assert: stackPages pageListIsWellFormed.
	stackPages assert: self validStackPageBaseFrames
]

{ #category : #'primitive support' }
StackInterpreter >> externalQuickPrimitiveResponse [
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
	localPrimIndex = 257 ifTrue: [self pop: 1 thenPush: trueObj. ^true].
	localPrimIndex = 258 ifTrue: [self pop: 1 thenPush: falseObj. ^true].
	localPrimIndex = 259 ifTrue: [self pop: 1 thenPush: nilObj. ^true].
	self pop: 1 thenPush: (self integerObjectOf: localPrimIndex - 261).
	^true
]

{ #category : #'frame access' }
StackInterpreter >> externalSetStackPageAndPointersForSuspendedContextOfProcess: aProcess [
	"Set stackPage, framePointer and stackPointer for the suspendedContext of aProcess,
	 marrying the context if necessary, and niling the suspendedContext slot.  This is used
	 on process switch to ensure a context has a stack frame and so can continue execution."
	| newContext theFrame thePage |
	<var: #theFrame type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	
	newContext := self fetchPointer: SuspendedContextIndex ofObject: aProcess.
	self assert: (self isContext: newContext).
	(self isMarriedOrWidowedContext: newContext) ifTrue:
		[self assert: (self checkIsStillMarriedContext: newContext currentFP: framePointer)].
	self storePointerUnchecked: SuspendedContextIndex ofObject: aProcess withValue: nilObj.
	(self isStillMarriedContext: newContext)
		ifTrue:
			[theFrame := self frameOfMarriedContext: newContext.
			 thePage := stackPages stackPageFor: theFrame]
		ifFalse:
			[thePage := self makeBaseFrameFor: newContext.
			 theFrame := thePage baseFP].
	self assert: thePage headFP = theFrame.
	self setStackPageAndLimit: thePage.
	stackPointer := thePage headSP.
	framePointer := thePage headFP.
	(self isMachineCodeFrame: framePointer) ifFalse:
		[self setMethod: (self iframeMethod: framePointer)]
]

{ #category : #'stack pages' }
StackInterpreter >> externalWriteBackHeadFramePointers [
	<asmLabel: false>
	self assert:  (framePointer - stackPointer) < LargeContextSize.
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	self setHeadFP: framePointer andSP: stackPointer inPage: stackPage.
	self assert: stackPages pageListIsWellFormed
]

{ #category : #utilities }
StackInterpreter >> externalizeFPandSP [
	"Copy the frame and stack pointers to global variables for use in primitives and other functions outside the interpret loop."
	self assert: (localSP < stackPage baseAddress
				and: [localSP > (stackPage realStackLimit - LargeContextSize)]).
	stackPointer := localSP.
	framePointer := localFP
]

{ #category : #utilities }
StackInterpreter >> externalizeIPandSP [
	"Copy the local instruction, stack and frame pointers to global variables for use in primitives and other functions outside the interpret loop."

	instructionPointer := self oopForPointer: localIP.
	stackPointer := localSP.
	framePointer := localFP
]

{ #category : #'primitive support' }
StackInterpreter >> failUnbalancedPrimitive [
	"not inlined for breakpoint value..."
	<inline: false>
	self primitiveFailFor: PrimErrBadNumArgs
]

{ #category : #'primitive support' }
StackInterpreter >> failed [
	<api>
	^primFailCode ~= 0
]

{ #category : #utilities }
StackInterpreter >> fetchArray: fieldIndex ofObject: objectPointer [
	"Fetch the instance variable at the given index of the given object. Return the address of first indexable field of resulting array object, or fail if the instance variable does not contain an indexable bytes or words object."
	"Note: May be called by translated primitive code."

	| arrayOop |
	<returnTypeC: 'void *'>
	arrayOop := self fetchPointer: fieldIndex ofObject: objectPointer.
	^ self arrayValueOf: arrayOop

]

{ #category : #'interpreter shell' }
StackInterpreter >> fetchByte [
	"This method uses the preIncrement builtin function which has no Smalltalk equivalent. Thus, it must be overridden in the simulator."

	^ self byteAtPointer: localIP preIncrement
]

{ #category : #utilities }
StackInterpreter >> fetchFloat: fieldIndex ofObject: objectPointer [
	"Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float."
	"Note: May be called by translated primitive code."

	| floatOop |
	<returnTypeC: 'double'>
	floatOop := self fetchPointer: fieldIndex ofObject: objectPointer.
	^ self floatValueOf: floatOop
]

{ #category : #utilities }
StackInterpreter >> fetchInteger: fieldIndex ofObject: objectPointer [
	"Note: May be called by translated primitive code."

	| intOop |
	<inline: false>
	intOop := self fetchPointer: fieldIndex ofObject: objectPointer.
	^self checkedIntegerValueOf: intOop
]

{ #category : #utilities }
StackInterpreter >> fetchIntegerOrTruncFloat: fieldIndex ofObject: objectPointer [
	"Return the integer value of the given field of the given object. If the field contains a Float, truncate it and return its integral part. Fail if the given field does not contain a small integer or Float, or if the truncated Float is out of the range of small integers."
	"Note: May be called by translated primitive code."

	| intOrFloat floatVal frac trunc |
	<inline: false>
	<var: #floatVal type: #double>
	<var: #frac type: #double>
	<var: #trunc type: #double>

	intOrFloat := self fetchPointer: fieldIndex ofObject: objectPointer.
	(self isIntegerObject: intOrFloat) ifTrue: [^ self integerValueOf: intOrFloat].
	self assertClassOfNonInt: intOrFloat is: (self splObj: ClassFloat) compactClassIndex: ClassFloatCompactIndex.
	self successful ifTrue: [
		self cCode: '' inSmalltalk: [floatVal := Float new: 2].
		self fetchFloatAt: intOrFloat + BaseHeaderSize into: floatVal.
		self cCode: 'frac = modf(floatVal, &trunc)'.
		"the following range check is for C ints, with range -2^31..2^31-1"
		self flag: #Dan.		"The ranges are INCORRECT if SmallIntegers are wider than 31 bits."
		self cCode: 'success((-2147483648.0 <= trunc) && (trunc <= 2147483647.0))'.].
	self successful
		ifTrue: [^ self cCode: '((sqInt) trunc)' inSmalltalk: [floatVal truncated]]
		ifFalse: [^ 0]
]

{ #category : #'interpreter shell' }
StackInterpreter >> fetchNextBytecode [
	"This method fetches the next instruction (bytecode). Each bytecode method is responsible for fetching the next bytecode, preferably as early as possible to allow the memory system time to process the request before the next dispatch."

	currentBytecode := self fetchByte.

]

{ #category : #'internal interpreter access' }
StackInterpreter >> fetchStackPointerOf: aContext [
	"Return the stackPointer of a Context or BlockContext.
	 Does not deal with married contexts.  Use only for debug
	 printing or object tracing functions.  To obtain an accurate
	 stack pointer use stackPointerForMaybeMarriedContext:"
	| sp |
	<inline: true>
	sp := self fetchPointer: StackPointerIndex ofObject: aContext.
	(self isIntegerObject: sp) ifFalse: [^0].
	self assert: ReceiverIndex + (self integerValueOf: sp) < (self lengthOf: aContext).
	^self integerValueOf: sp
]

{ #category : #'debug support' }
StackInterpreter >> findClassOfMethod: meth forReceiver: rcvr [

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

{ #category : #'frame access' }
StackInterpreter >> findFrameAbove: theFP inPage: thePage [
	"Answer the frame above theFP (adjacent frame nearest head end).
	 If theFP is the head frame answer 0."
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	| fp callerFP |
	<var: #fp type: #'char *'>
	<var: #callerFP type: #'char *'>
	<returnTypeC: #'char *'>
	fp := thePage headFP.
	fp = theFP ifTrue:
		[^0].
	[(callerFP := self frameCallerFP: fp) ~= 0] whileTrue:
		[callerFP = theFP ifTrue:
			[^fp].
		 fp := callerFP].
	self error: 'did not find theFP in stack page'.
	^0
]

{ #category : #'debug printing' }
StackInterpreter >> findHomeForContext: aContext [
	| closureOrNil |
	<inline: false>
	closureOrNil := self fetchPointer: ClosureIndex ofObject: aContext.
	closureOrNil = nilObj ifTrue:
		[^aContext].
	^self findHomeForContext: (self fetchPointer: ClosureOuterContextIndex ofObject: closureOrNil)
]

{ #category : #'handler search' }
StackInterpreter >> findMethodWithPrimitive: primitive FromContext: senderContext UpToContext: homeContext [
	"See findUnwindThroughContext:.  Alas this is mutually recursive with
	 findMethodWithPrimitive:FromFP:SP:ThroughContext: instead of iterative.
	 We're doing the simplest thing that could possibly work.  Niceties can wait."
	| theContext theMethod |
	self assert: (senderContext = nilObj or: [self isContext: senderContext]).
	self assert: (homeContext = nilObj or: [self isContext: homeContext]).
	theContext := senderContext.
	[theContext = nilObj ifTrue:
		[^theContext].
	 self isMarriedOrWidowedContext: theContext] whileFalse:
		[theContext = homeContext ifTrue: [^0].
		 (self fetchPointer: ClosureIndex ofObject: theContext) = nilObj ifTrue:
		 	[theMethod := self fetchPointer: MethodIndex ofObject: theContext.
			 (self primitiveIndexOf: theMethod) == primitive ifTrue:
				[^theContext]].
		 theContext := self fetchPointer: SenderIndex ofObject: theContext].
	(self isWidowedContext: theContext) ifTrue:
		[^nilObj].
	^self
		findMethodWithPrimitive: primitive
		FromFP: (self frameOfMarriedContext: theContext)
		UpToContext: homeContext
]

{ #category : #'handler search' }
StackInterpreter >> findMethodWithPrimitive: primitive FromFP: startFP UpToContext: homeContext [
	"See findUnwindThroughContext:.  Alas this is mutually recursive with
	 findMethodWithPrimitive:FromContext:ThroughContext: instead of iterative.
	 We're doing the simplest thing that could possibly work.  Niceties can wait."
	| theFP theFPAbove theSP theMethod senderContext |
	<var: #startFP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #theFPAbove type: #'char *'>
	<var: #theSP type: #'char *'>
	theFP := startFP.
	theFPAbove := startFP.
	[((self frameHasContext: theFP)
	  and: [homeContext = (self frameContext: theFP)]) ifTrue:
		[^0].
	 (self frameIsBlockActivation: theFP) ifFalse:
	 	[theMethod := self frameMethodObject: theFP.
		 (self primitiveIndexOf: theMethod) == primitive ifTrue:
			[theFP = theFPAbove
						ifTrue: [theSP := self findSPOf: theFP on: (stackPages stackPageFor: theFP)]
						ifFalse: [theSP := self frameCallerStackPointer: theFPAbove].
			 ^self ensureFrameIsMarried: theFP SP: theSP]].
	 theFPAbove := theFP.
	 theFP := self frameCallerFP: theFP.
	 theFP ~= 0] whileTrue.
	senderContext := self frameCallerContext: theFPAbove.
	(self isContext: senderContext) ifFalse:
		[^nilObj].
	^self
		findMethodWithPrimitive: primitive
		FromContext: senderContext
		UpToContext: homeContext
]

{ #category : #'message sending' }
StackInterpreter >> findNewMethodInClass: class [ 
	"Find the compiled method to be run when the current 
	messageSelector is sent to the given class, setting the values 
	of 'newMethod' and 'primitiveIndex'."
	| ok |
	<inline: false>
	ok := self lookupInMethodCacheSel: messageSelector class: class.
	ok ifFalse: "entry was not found in the cache; look it up the hard way "
		[self lookupMethodInClass: class.
		 self addNewMethodToCache: class]
]

{ #category : #'frame access' }
StackInterpreter >> findSPOf: theFP on: thePage [
	"Search for the stack pointer for theFP.  This points to the hottest item on the frame's stack.
	 DO NOT CALL THIS WITH theFP == localFP OR theFP == framePointer!"
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<returnTypeC: #'char *'>
	| theSP |
	<inline: false>
	<var: #theSP type: #'char *'>
	theSP := self findSPOrNilOf: theFP on: thePage startingFrom: thePage headFP.
	theSP notNil ifTrue:
		[^theSP].
	self error: 'did not find theFP in stack page'.
	^0
]

{ #category : #'frame access' }
StackInterpreter >> findSPOrNilOf: theFP on: thePage startingFrom: startFrame [
	"Search for the stack pointer for theFP.  This points to the hottest item on the frame's stack.
	 DO NOT CALL THIS WITH theFP == localFP OR theFP == framePointer!"
	<var: #aFrame type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<returnTypeC: #'char *'>
	| aFrame theSP |
	<inline: true>
	<asmLabel: false>
	<var: #startFrame type: #'char *'>
	<var: #theSP type: #'char *'>
	self assert: (stackPages isFree: thePage) not.
	aFrame := startFrame.
	theSP := thePage headSP.
	aFrame = theFP ifTrue:
		[theSP >= aFrame ifTrue:
			["If the SP is invalid return the pointer to the receiver field."
			 ^self frameReceiverOffset: aFrame].
		 "Skip the instruction pointer on top of stack of inactive pages."
		^thePage = stackPage
			ifTrue: [theSP]
			ifFalse: [theSP + BytesPerWord]].
	[theSP := self frameCallerSP: aFrame.
	 aFrame := self frameCallerFP: aFrame.
	 aFrame ~= 0] whileTrue:
		[theFP = aFrame ifTrue:
			[^theSP]].
	^nil
]

{ #category : #'debug support' }
StackInterpreter >> findSelectorOfMethod: meth forReceiver: rcvr [

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

{ #category : #'return bytecodes' }
StackInterpreter >> findUnwindThroughContext: homeContext [
	"Search for either an unwind-protect (activation of method with primitive 198)
	 or homeContext along the sender chain, which ever is found first.  If homeContext
	 is not found answer nilObj, indicating cannotReturn:.  If homeContext is found
	 answer 0.  If homeContext is itself an unwind-protect answer the context, not 0."
	| ctxtOrNilOrZero theMethod |
	"Since nothing changes we don't need to internalize."
	ctxtOrNilOrZero := self findMethodWithPrimitive: 198 FromFP: framePointer UpToContext: homeContext.
	ctxtOrNilOrZero = 0 ifTrue:
		[theMethod := self fetchPointer: MethodIndex ofObject: homeContext.
		 (self primitiveIndexOf: theMethod) == 198 ifTrue:
			[^homeContext]].
	^ctxtOrNilOrZero
]

{ #category : #'plugin support' }
StackInterpreter >> firstFixedField: oop [

	<returnTypeC: 'void *'>
	^ self pointerForOop: oop + BaseHeaderSize
]

{ #category : #'plugin support' }
StackInterpreter >> firstIndexableField: oop [
	"NOTE: copied in InterpreterSimulator, so please duplicate any changes"

	| hdr fmt totalLength fixedFields |
	<returnTypeC: 'void *'>
	hdr := self baseHeader: oop.
	fmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: oop baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: oop format: fmt length: totalLength.
	fmt < 8 ifTrue:
		[fmt = 6 ifTrue: "32 bit field objects"
			[^self pointerForOop: oop + BaseHeaderSize + (fixedFields << 2)].
		"full word objects (pointer or bits)"
		^self pointerForOop: oop + BaseHeaderSize + (fixedFields << ShiftForWord)].
	"Byte objects"
	^self pointerForOop: oop + BaseHeaderSize + fixedFields
]

{ #category : #'object format' }
StackInterpreter >> fixedFieldsOf: oop format: fmt length: wordLength [
"
	NOTE: This code supports the backward-compatible extension to 8 bits of instSize.
	When we revise the image format, it should become...
	^ (classFormat >> 2 bitAnd: 16rFF) - 1
"
	| class classFormat |
	<inline: true>
	<asmLabel: false>
	((fmt > 4) or: [fmt = 2]) ifTrue: [^ 0].  "indexable fields only"
	fmt < 2 ifTrue: [^ wordLength].  "fixed fields only (zero or more)"
	
	"fmt = 3 or 4: mixture of fixed and indexable fields, so must look at class format word"
	class := self fetchClassOfNonInt: oop.
	classFormat := self formatOfClass: class.
	^ (classFormat >> 11 bitAnd: 16rC0) + (classFormat >> 2 bitAnd: 16r3F) - 1

]

{ #category : #'plugin primitive support' }
StackInterpreter >> floatArg: index [
	"Like #stackFloatValue: but access method arguments left-to-right"
	| result oop |
	<returnTypeC: #double>
	<var: #result type: #double>
	oop := self methodArg: index.
	oop = 0 ifTrue:[^0.0]. "methodArg: failed"
	"N.B.  Because Slang always inlines assertClassOf:is:compactClassIndex:
	 (because assertClassOf:is:compactClassIndex: has an inline: pragma) the
	 phrase (self splObj: ClassArray) is expanded in-place and is _not_
	 evaluated if ClassArrayCompactIndex is non-zero."
	self assertClassOf: oop is: (self splObj: ClassFloat)
		compactClassIndex: ClassFloatCompactIndex.
	self successful ifTrue:[
		self cCode: '' inSmalltalk: [result := Float new: 2].
		self fetchFloatAt: oop + BaseHeaderSize into: result.
		^result
	] ifFalse:[^0.0]

]

{ #category : #'object format' }
StackInterpreter >> floatObjectOf: aFloat [
	| newFloatObj |
	<inline: false>
	<var: #aFloat type: #double>
	self flag: #Dan.
	newFloatObj := self eeInstantiateSmallClass: (self splObj: ClassFloat) sizeInBytes: 8+BaseHeaderSize.
	self storeFloatAt: newFloatObj + BaseHeaderSize from: aFloat.
	^ newFloatObj.

]

{ #category : #utilities }
StackInterpreter >> floatValueOf: oop [
	"Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float."
	"Note: May be called by translated primitive code."

	| result |
	<returnTypeC: #double>
	<var: #result type: #double>
	self flag: #Dan.  "None of the float stuff has been converted for 64 bits"
	"N.B.  Because Slang always inlines assertClassOf:is:compactClassIndex:
	 (because assertClassOf:is:compactClassIndex: has an inline: pragma) the
	 phrase (self splObj: ClassArray) is expanded in-place and is _not_
	 evaluated if ClassArrayCompactIndex is non-zero."
	self assertClassOf: oop
		is: (self splObj: ClassFloat)
		compactClassIndex: ClassFloatCompactIndex.
	self successful
		ifTrue: [self cCode: '' inSmalltalk: [result := Float new: 2].
				self fetchFloatAt: oop + BaseHeaderSize into: result.
				^result]
		ifFalse: [^0.0]
]

{ #category : #'debug printing' }
StackInterpreter >> flush [
	<cmacro: '() fflush(stdout)'>
]

{ #category : #'method lookup cache' }
StackInterpreter >> flushAtCache [
	"Flush the at cache. The method cache is flushed on every programming change and garbage collect."

	1 to: AtCacheTotalSize do: [ :i | atCache at: i put: 0 ]
]

{ #category : #'plugin primitive support' }
StackInterpreter >> flushExternalPrimitiveOf: methodPtr [
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
StackInterpreter >> flushExternalPrimitiveTable [
	"Flush the external primitive table"
	0 to: MaxExternalPrimitiveTableSize-1 do:[:i|
		externalPrimitiveTable at: i put: 0].
	externalPrimitiveTableFirstFreeIndex := 0
]

{ #category : #'plugin primitive support' }
StackInterpreter >> flushExternalPrimitives [
	"Flush the references to external functions from plugin 
	primitives. This will force a reload of those primitives when 
	accessed next. 
	Note: We must flush the method cache here so that any 
	failed primitives are looked up again."
	| oop primIdx |
	oop := self firstObject.
	[self oop: oop isLessThan: freeStart]
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
StackInterpreter >> flushMethodCache [
	"Flush the method cache. The method cache is flushed on every programming change and garbage collect."

	1 to: MethodCacheSize do: [ :i | methodCache at: i put: 0 ].
	lastMethodCacheProbeWrite := 0 "this for primitiveExternalMethod"
]

{ #category : #'method lookup cache' }
StackInterpreter >> flushMethodCacheFrom: memStart to: memEnd [ 
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
StackInterpreter >> forceInterruptCheck [
	"Force an interrupt check ASAP.
	 Must set the stack page's limit before stackLimit to avoid
	 a race condition if this is called from an interrupt handler."
	| thePage iccFunc |
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	<var: #iccFunc declareC: 'void (*iccFunc)()'>
	"Do _not_ set stackLimit until the stack system has been initialized.
	 stackLimit is the initialization flag for the stack system."
	stackLimit = 0 ifTrue:
		[^nil].
	thePage := stackPage.
	thePage notNil ifTrue:
		[thePage stackLimit: (self cCoerceSimple: -1 signedIntToLong to: #'char *')].
	stackLimit := self cCoerceSimple: -1 signedIntToLong to: #'char *'.
	"There is a race condition if we test the function and then dereference
	 it a second time to call it.  This is called from interrupt code but at the
	 same time other code could be clearing the interruptCheckChain via
	 setInterruptCheckChain:."
	(iccFunc := interruptCheckChain) notNil ifTrue:
		[self perform: iccFunc].
	statForceInterruptCheck := statForceInterruptCheck + 1
]

{ #category : #'process primitive support' }
StackInterpreter >> forceInterruptCheckFromHeartbeat [
	"Force an interrupt check ASAP. This version is the
	 entry-point to forceInterruptCheck for the heartbeat
	 timer to allow for repeatable debugging."
	self cPreprocessorDirective: '#if !DEBUG_DISABLE_HEARTBEAT'.
	suppressHeartbeatFlag ifFalse:
		[self checkForLongRunningPrimitive.
		 self forceInterruptCheck].
	self cPreprocessorDirective: '#endif'
]

{ #category : #'object format' }
StackInterpreter >> formatOfClass: classPointer [
	"**should be in-lined**"
	"Note that, in Smalltalk, the instSpec will be equal to the inst spec
	part of the base header of an instance (without hdr type) shifted left 1.
	In this way, apart from the smallInt bit, the bits
	are just where you want them for the first header word."
	"Callers (must) expect low 2 bits (header type) to be zero!"
	<api>
	<inline: true>
	^ (self fetchPointer: InstanceSpecificationIndex ofObject: classPointer) - 1
]

{ #category : #'frame access' }
StackInterpreter >> formatOfMethodContext [
	"Answer the class format word for MethodContext which is used to instantiate
	 contexts without needing to fetch it from the class MethodContext itself."
	^(ClassMethodContextCompactIndex << 12)
	+ (3 << 8) "Pointers+Variable"
	+ (TempFrameStart + (BaseHeaderSize / BytesPerWord) << 2)
]

{ #category : #'image segment in/out' }
StackInterpreter >> forward: oop to: newOop savingOopAt: oopPtr andHeaderAt: hdrPtr [

	"Make a new entry in the table of saved oops."
	self longAt: oopPtr put: oop.					"Save the oop"
	self longAt: hdrPtr put: (self longAt: oop).	"Save the old header word"

	"Put a forwarding pointer in the old object, flagged with forbidden header type"
	self longAt: oop put: newOop + HeaderTypeFree.

]

{ #category : #'frame access' }
StackInterpreter >> frameCallerContext: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxCallerContext "a.k.a. FoxCallerSavedIP"
]

{ #category : #'frame access' }
StackInterpreter >> frameCallerContext: theFP put: aValue [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages
		longAt: theFP + FoxCallerContext "a.k.a. FoxCallerSavedIP"
		put: aValue
]

{ #category : #'frame access' }
StackInterpreter >> frameCallerFP: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	<returnTypeC: 'char *'>
	^self pointerForOop: (stackPages longAt: theFP + FoxSavedFP)
]

{ #category : #'frame access' }
StackInterpreter >> frameCallerSP: theFP [
	"Answer the SP of the caller provided theFP is not a base frame.
	 This points to the hottest item on the caller frame's stack."
	<var: #theFP type: #'char *'>
	<returnTypeC: 'char *'>
	<asmLabel: false>
	self assert: (self isBaseFrame: theFP) not.
	^theFP + (self frameStackedReceiverOffset: theFP) + BytesPerWord
]

{ #category : #'frame access' }
StackInterpreter >> frameCallerSavedIP: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	<returnTypeC: 'char *'>
	^self pointerForOop: (stackPages longAt: theFP + FoxCallerSavedIP) "a.k.a. FoxCallerSavedIP"
]

{ #category : #'frame access' }
StackInterpreter >> frameCallerStackPointer: theFP [
	"Answer the stack pointer of the caller frame."
	<var: #theFP type: #'char *'>
	<returnTypeC: #'char *'>
	<inline: true>
	<asmLabel: false>
	self assert: (self isBaseFrame: theFP) not.
	^theFP + (self frameStackedReceiverOffset: theFP) + BytesPerWord
]

{ #category : #'frame access' }
StackInterpreter >> frameContext: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxThisContext
]

{ #category : #'frame access' }
StackInterpreter >> frameHasContext: theFP [
	"See encodeFrameFieldHasContext:numArgs:"
	<inline: true>
	<var: #theFP type: #'char *'>
	^(stackPages byteAt: theFP + FoxFrameFlags + 2) ~= 0
]

{ #category : #'frame access' }
StackInterpreter >> frameInstructionPointerForContext: aContext method: aMethod [
	"Answer the instruction pointer for usage in a frame (a pointer to a bytecode)
	 from the index instructionPointer in the given context."
	^aMethod
	+ (self quickFetchInteger: InstructionPointerIndex ofObject: aContext)
	+ BaseHeaderSize
	- 2
]

{ #category : #'frame access' }
StackInterpreter >> frameIsBlockActivation: theFP [ "<Integer>"
	<inline: true>
	<var: #theFP type: #'char *'>
	^(stackPages byteAt: theFP + FoxFrameFlags + 3) ~= 0
]

{ #category : #'frame access' }
StackInterpreter >> frameMethod: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxMethod
]

{ #category : #'frame access' }
StackInterpreter >> frameMethodObject: theFP [
	"Homonym of frameMethod: for compatibility with CoInterpreter"
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxMethod
]

{ #category : #'frame access' }
StackInterpreter >> frameNumArgs: theFP [
	"See encodeFrameFieldHasContext:numArgs:"
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages byteAt: theFP + FoxFrameFlags + 1
]

{ #category : #'frame access' }
StackInterpreter >> frameOfMarriedContext: aContext [ 
	| value |
	<inline: true>
	<returnTypeC: 'char *'>
	value := self fetchPointer: SenderIndex ofObject: aContext.
	^self withoutSmallIntegerTags: value
]

{ #category : #'frame access' }
StackInterpreter >> frameReceiver: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxReceiver
]

{ #category : #'frame access' }
StackInterpreter >> frameReceiverOffset: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^theFP + FoxReceiver
]

{ #category : #'frame access' }
StackInterpreter >> frameStackedReceiver: theFP numArgs: numArgs [
	"Answer the stacked receiver given the frame's argument count.
	 The receiver of a message send or the closure of a block activation is
	 always on the stack above any arguments and the frame itself.  See the
	 diagram in StackInterpreter class>>initializeFrameIndices."
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxCallerSavedIP + BytesPerWord + (numArgs << ShiftForWord)
]

{ #category : #'frame access' }
StackInterpreter >> frameStackedReceiverOffset: theFP [
	"Answer the offset in bytes from the a frame pointer to its stacked receiver.
	 The receiver of a message send or the closure of a block activation is
	 always on the stack above any arguments and the frame itself.  See the
	 diagram in StackInterpreter class>>initializeFrameIndices."
	<inline: true>
	<var: #theFP type: #'char *'>
	^FoxCallerSavedIP + BytesPerWord + ((self frameNumArgs: theFP) << ShiftForWord)
]

{ #category : #'frame access' }
StackInterpreter >> frameStackedReceiverOffset: theFP numArgs: numArgs [
	"Answer the offset in bytes from the a frame pointer to its stacked receiver.
	 The receiver of a message send or the closure of a block activation is
	 always on the stack above any arguments and the frame itself.  See the
	 diagram in StackInterpreter class>>initializeFrameIndices."
	<inline: true>
	<var: #theFP type: #'char *'>
	^FoxCallerSavedIP + BytesPerWord + (numArgs << ShiftForWord)
]

{ #category : #'I/O primitive support' }
StackInterpreter >> fullDisplayUpdate [
	"Repaint the entire smalltalk screen, ignoring the affected rectangle. Used in some platform's code when the Smalltalk window is brought to the front or uncovered."

	| displayObj w h |
	displayObj := self splObj: TheDisplay.
	((self isPointers: displayObj) and: [(self lengthOf: displayObj) >= 4]) ifTrue: [
		w := self fetchInteger: 1 ofObject: displayObj.
		h := self fetchInteger: 2 ofObject: displayObj.
		self displayBitsOf: displayObj Left: 0 Top: 0 Right: w Bottom: h.
		self ioForceDisplayUpdate].
	^nil
]

{ #category : #'plugin primitive support' }
StackInterpreter >> functionForPrimitiveCallout [
	"Answer the function primitiveCallout from the FFI plugin or nil if it can't
	 be found.  Cache it for performance.  We use this circumlocution so that
	 Squeak can be deployed without the FFI plugin for security reasons."

	<returnTypeC: 'void (*functionForPrimitiveCallout())(void)'>
	| function |
	<var: #function declareC: 'static void *function = (void *)-1'>
	function asInteger = -1 ifTrue:
		[function := self ioLoadFunction: 'primitiveCallout' From: 'SqueakFFIPrims'].
	^self cCoerceSimple: function to: #'void (*)(void)'
]

{ #category : #'method lookup cache' }
StackInterpreter >> functionPointerFor: primIdx inClass: theClass [
	"Find an actual function pointer for this primitiveIndex.  This is an
	opportunity to specialise the prim for the relevant class (format for
	example).  Default for now is simply the entry in the base primitiveTable."

	<returnTypeC: 'void (*functionPointerForinClass(sqInt primIdx,sqInt theClass))(void)'>
	^primIdx > MaxPrimitiveIndex ifTrue: [0] ifFalse: [primitiveTable at: primIdx]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCodeCompactionCount [
	"This is nil in the StackVM"
	^nilObj
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCodeCompactionMSecs [
	"This is nil in the StackVM"
	^nilObj
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCogCodeSize [
	"This is nil in the StackVM"
	^nilObj
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCogVMFlags [
	"Answer an array of flags indicating various properties of the Cog VM.
	 Bit 2: if set, implies preempting a process does not put it to the back of its run queue"
	^self integerObjectOf: (preemptionYields ifTrue: [0] ifFalse: [4])
]

{ #category : #'interpreter shell' }
StackInterpreter >> getCurrentBytecode [
	"currentBytecode will be private to the main dispatch loop in the generated code. This method allows the currentBytecode to be retrieved from global variables."

	^ self byteAt: instructionPointer
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getDesiredCogCodeSize [
	"This is nil in the StackVM"
	^nilObj
]

{ #category : #'message sending' }
StackInterpreter >> getErrorObjectFromPrimFailCode [
	"Answer the errorCode object to supply to a failing primitive method that accepts one.
	 If there is a primitive error table and the primFailCode is a valid index there-in answer
	 the coprresponding entry in the table, otherwise simply answer the code as an integer."
	| table |
	primFailCode > 0 ifTrue:
		[table := self splObj: PrimErrTableIndex.
		 primFailCode <= ((self lastPointerOf: table) // BytesPerWord) ifTrue:
			[^self fetchPointer: primFailCode - 1 ofObject: table]].
	^self integerObjectOf: primFailCode
]

{ #category : #'plugin primitive support' }
StackInterpreter >> getFullScreenFlag [
	^fullScreenFlag
]

{ #category : #'image save/restore' }
StackInterpreter >> getImageHeaderFlags [
	"Answer the flags that are contained in the 7th long of the image header."
	^fullScreenFlag "0 or 1"
	+ (VMBIGENDIAN ifTrue: [0] ifFalse: [2]) "this is the imageFloatsLittleEndian flag"
	+ (preemptionYields ifTrue: [0] ifFalse: [16])
	+ (imageHeaderFlags bitAnd: 19 bitInvert32) "these are any flags we do not recognize"
]

{ #category : #'plugin primitive support' }
StackInterpreter >> getInterruptKeycode [
	^interruptKeycode
]

{ #category : #'plugin primitive support' }
StackInterpreter >> getInterruptPending [
	^interruptPending
]

{ #category : #'image save/restore' }
StackInterpreter >> getLongFromFile: aFile swap: swapFlag [
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
StackInterpreter >> getNextWakeupUsecs [
	<api>
	<returnTypeC: #usqLong>
	^nextWakeupUsecs
]

{ #category : #'plugin primitive support' }
StackInterpreter >> getSavedWindowSize [
	^savedWindowSize
]

{ #category : #'image save/restore' }
StackInterpreter >> getShortFromFile: aFile swap: swapFlag [
	"Answer the next half-word read from aFile, byte-swapped according to the swapFlag."

	| w |
	<var: #aFile type: 'sqImageFile '>
	w := 0.
	self cCode: 'sqImageFileRead(&w, sizeof(unsigned short), 1, aFile)'.
	^swapFlag
		ifTrue: [(w bitShift: -8) + ((w bitAnd: 16rFF) bitShift: 8)]
		ifFalse: [w]
]

{ #category : #'plugin support' }
StackInterpreter >> getThisSessionID [
	"return the global session ID value"
	<inline: false>
	^globalSessionID
]

{ #category : #'message sending' }
StackInterpreter >> handleStackOverflowOrEventAllowContextSwitch: mayContextSwitch [
	"The stackPointer is below the stackLimit.  This is either because of a
	 stack overflow or the setting of stackLimit to indicate a possible interrupt.
	 Check for interrupts and stackOverflow and deal with each appropriately.
	 Answer if a context switch occurred."
	| switched newPage theFP callerFP overflowLimitAddress overflowCount |
	<var: #newPage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #overflowLimitAddress type: #'char *'>

	"If the stackLimit differs from the realStackLimit then the stackLimit
	 has been set to indicate an event or interrupt that needs servicing."
	stackLimit = stackPage realStackLimit
		ifTrue:
			[self externalWriteBackHeadFramePointers.
			 switched := false]
		ifFalse: [switched := self checkForEventsMayContextSwitch: mayContextSwitch].

	"After checkForInterrupts another event check may have been forced, setting both
	 stackLimit and stackPage stackLimit to all ones.  So here we must check against
	 the real stackLimit, not the effective stackLimit."
	stackPointer < stackPage realStackLimit ifFalse:
		[^switched].

	statStackOverflow := statStackOverflow + 1.

	"The stack has overflowed this page.  If the system is executing some recursive algorithm,
	 e.g. fibonacci, then the system could thrash overflowing the stack if the call soon returns
	 back to the current page.  To avoid thrashing, since overflow is quite slow, we can move
	 more than one frame.  The idea is to record which page has overflowed, and the first
	 time it overflows move one frame, the second time two frames, and so on.  We move no
	 more frames than would leave the page half occupied."
	theFP := framePointer.
	stackPage = overflowedPage
		ifTrue:
			[overflowLimitAddress := stackPage baseAddress - stackPages overflowLimit.
			 overflowCount := extraFramesToMoveOnOverflow := extraFramesToMoveOnOverflow + 1.
			 [(overflowCount := overflowCount - 1) >= 0
			   and: [(callerFP := self frameCallerFP: theFP) < overflowLimitAddress
			   and: [(self isBaseFrame: callerFP) not]]] whileTrue:
				[theFP := callerFP]]
		ifFalse:
			[overflowedPage := stackPage.
			 extraFramesToMoveOnOverflow := 0].

	self ensureCallerContext: theFP.
	newPage := self newStackPage.
	self moveFramesIn: stackPage through: theFP toPage: newPage.
	self setStackPageAndLimit: newPage.
	framePointer := stackPage headFP.
	stackPointer := stackPage headSP.
	self isCog
		ifFalse: "To overflow the stack this must be a new frame, but in Cog base frames are married."
			[self assert: (self frameHasContext: framePointer) not.
			 self assert: (self validInstructionPointer: instructionPointer
							inMethod: method
							framePointer: framePointer)]
		ifTrue:
			[self assert: (self validInstructionPointer: instructionPointer
							inFrame: framePointer).
			 self assert: ((self frameHasContext: framePointer) not
						or: [self isContext: (self frameContext: framePointer)])].
	^switched
]

{ #category : #'compiled methods' }
StackInterpreter >> headerOf: methodPointer [
	^self fetchPointer: HeaderIndex ofObject: methodPointer
]

{ #category : #'stack pages' }
StackInterpreter >> highBit: anUnsignedValue [ 
	"This is a C implementation needed by stackPageByteSize when translated."
	| shifted bitNo |
	<var: #anUnsignedValue type: #usqInt>
	<var: #shifted type: #usqInt>
	shifted := anUnsignedValue.
	bitNo := 0.
	BytesPerWord > 4 ifTrue:
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

{ #category : #'process primitive support' }
StackInterpreter >> highestPriorityProcess [
	"Answer the highest priority process that is ready to run, but
	 unlike wakeHighestPriority do not remove it from the list.
	 To save time looking at many empty lists before finding a
	 runnable process the VM maintains a variable holding the
	 highest priority runnable process.  If this variable is 0 then the
	 VM does not know the highest priority and must search all lists.
	 Note: It is a fatal VM error if there is no runnable process."
	| schedLists p processList processOrNil |
	<inline: false>
	schedLists := self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	p := highestRunnableProcessPriority = 0
			ifTrue: [self fetchWordLengthOf: schedLists]
			ifFalse: [highestRunnableProcessPriority].
	p := p - 1.
	"index of last indexable field"
	[processList := self fetchPointer: p ofObject: schedLists.
	 processOrNil := self fetchPointer: FirstLinkIndex ofObject: processList.
	 processOrNil = nilObj] whileTrue:
		[(p := p - 1) < 0 ifTrue:
			[^nil]].
	highestRunnableProcessPriority := p + 1.
	^processOrNil
]

{ #category : #'debug support' }
StackInterpreter >> ifValidWriteBackStack: theCFP Pointers: theCSP [
	"This is for low-level error reporting.  If either of the C stack pointers are
	 pointing into the stack zone then write them back to framePointer and/or
	 stackPointer so that the stack backtrace will be up to date.
	 This is a noop in the stack VM since the C stack pointers are always elsewhere
	 (e.g., in some C function running the interpreter)"
	<api>
	<var: #theCFP type: #'void *'>
	<var: #theCSP type: #'void *'>
	<returnTypeC: #void>
]

{ #category : #'frame access' }
StackInterpreter >> iframeMethod: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxMethod
]

{ #category : #'image save/restore' }
StackInterpreter >> imageFormatCompatibilityVersion [
	"This VM is backward-compatible with the immediately preceeding version."

	^BytesPerWord == 4 ifTrue: [6504] ifFalse: [68002]
]

{ #category : #'image save/restore' }
StackInterpreter >> imageFormatVersion [
	"Return a magic constant that changes when the image format changes. Since the image reading code uses this to detect byte ordering, one must avoid version numbers that are invariant under byte reversal."

	^BytesPerWord == 4 ifTrue: [6505] ifFalse: [68003]
]

{ #category : #'image segment in/out' }
StackInterpreter >> imageSegmentVersion [
	| wholeWord |
	"a more complex version that tells both the word reversal and the endianness of the machine it came from.  Low half of word is 6502.  Top byte is top byte of #doesNotUnderstand: on this machine. ($d on the Mac or $s on the PC)"

	wholeWord := self longAt: (self splObj: SelectorDoesNotUnderstand) + BaseHeaderSize.
		"first data word, 'does' "
	^ self imageFormatVersion bitOr: (wholeWord bitAnd: 16rFF000000)
]

{ #category : #'plugin primitive support' }
StackInterpreter >> includesBehavior: aClass ThatOf: aSuperclass [
	"Return the equivalent of 
		aClass includesBehavior: aSuperclass.
	Note: written for efficiency and better inlining (only 1 temp)"
	| theClass |
	<inline: true>
	(((theClass := aClass) = aSuperclass) "aClass == aSuperclass"
		or:[aSuperclass = nilObj]) "every class inherits from nil"
			ifTrue:[^true].
	[(theClass := self superclassOf: theClass) = aSuperclass ifTrue:[^true].
	theClass ~= nilObj] whileTrue.
	^false
]

{ #category : #'primitive support' }
StackInterpreter >> initPrimCall [
	"Set the failure code/success flag in preparation for calling a primitve.
	 If primFailCode is non-zero a primitive has failed.  If primFailCode is
	 greater than one then its value indicates the reason for failure."
	<inline: true>
	primFailCode := 0.
	primPops := 0.
	primResult := 0. "mark as unused return value"
	shouldPopArgs := false.

]

{ #category : #initialization }
StackInterpreter >> initStackPages [
	"Initialize the stackPages.  This version is only for simulation
	 because Slang refuses to inline it, which makes the alloca invalid."
	| stackPageBytes stackPagesBytes theStackMemory |
	stackPageBytes := self stackPageByteSize.
	stackPagesBytes := self computeStackZoneSize.
	theStackMemory := self
						cCode: 'alloca(stackPagesBytes)'
						inSmalltalk:
							[stackPages := self stackPagesClass new.
							 stackPages initializeWithByteSize: stackPagesBytes for: self].
	stackPages
		initializeStack: theStackMemory
		numSlots: stackPagesBytes / BytesPerWord
		pageSize: stackPageBytes / BytesPerWord
		stackLimitOffset: self stackLimitOffset
		stackPageHeadroom: self stackPageHeadroom
]

{ #category : #initialization }
StackInterpreter >> initStackPagesAndInterpret [
	"Initialize the stack pages and enter interpret. Use alloca'ed memory so that when
	 we have a JIT its stack pointer will be on the native stack since alloca allocates
	 memory on the stack. Certain thread systems use the native stack pointer as the
	 frame ID so putting the stack anywhere else can confuse the thread system."

	"This should be in its own initStackPages method but Slang can't inline
	 C code strings."
	| stackPageBytes stackPagesBytes theStackMemory |
	<var: #theStackMemory type: #'void *'>
	stackPageBytes := self stackPageByteSize.
	stackPagesBytes := self computeStackZoneSize.
	theStackMemory := self
						cCode: 'alloca(stackPagesBytes)'
						inSmalltalk:
							[stackPages := self stackPagesClass new.
							 stackPages initializeWithByteSize: stackPagesBytes for: self].
	stackPages
		initializeStack: theStackMemory
		numSlots: stackPagesBytes / BytesPerWord
		pageSize: stackPageBytes / BytesPerWord
		stackLimitOffset: self stackLimitOffset
		stackPageHeadroom: self stackPageHeadroom.

	"Once the stack pages are initialized we can continue to bootstrap the system."
	self loadInitialContext.
	"We're ready for the heartbeat (poll interrupt)"
	self ioInitHeartbeat.
	self interpret.
	^nil
]

{ #category : #initialization }
StackInterpreter >> initialCleanup [
	"This used to cope with issues with images written by VMs earlier than 3.6/3.7.
	 Since we won't be loading such images (being a closure only VM) we only have to
	 deal with external primitives.  Since references to external plugins in methods are
	 cleaned up in snapshotCleanUp only initialize the tables, not visit each method."
	self flushMethodCache.
	self flushAtCache.
	self flushExternalPrimitiveTable
]

{ #category : #'compiled methods' }
StackInterpreter >> initialPCForHeader: methodHeader method: theMethod [
	^theMethod + ((LiteralStart + (self literalCountOfHeader: methodHeader)) * BytesPerWord) + BaseHeaderSize
]

{ #category : #initialization }
StackInterpreter >> initializeInterpreter: bytesToShift [ 
	"Initialize Interpreter state before starting execution of a new image."
	interpreterProxy := self sqGetInterpreterProxy.
	self dummyReferToProxy.
	self initializeObjectMemory: bytesToShift.
	self checkAssumedCompactClasses.
	primFailCode := 0.
	metaclassSizeBytes := self sizeBitsOf: (self fetchClassOfNonInt: (self splObj: ClassArray)).	"determine actual (Metaclass instSize * 4)"
	stackLimit := 0. "This is also the initialization flag for the stack system."
	stackPage := overflowedPage := 0.
	extraFramesToMoveOnOverflow := 0.
	self setMethod: nilObj.
	messageSelector := nilObj.
	newMethod := nilObj.
	lkupClass := nilObj.
	self flushMethodCache.
	self flushAtCache.
	self initialCleanup.
	highestRunnableProcessPriority := 0.
	nextProfileTick := 0.
	profileSemaphore := nilObj.
	profileProcess := nilObj.
	profileMethod := nilObj.
	nextPollUsecs := 0.
	nextWakeupUsecs := 0.
	primPops := 0.
	primResult := 0.
	shouldPopArgs := false.
	interruptKeycode := 2094. "cmd-. as used for Mac but no other OS"
	interruptPending := false.
	deferDisplayUpdates := false.
	pendingFinalizationSignals := statPendingFinalizationSignals := 0.
	globalSessionID := 0.
	[globalSessionID = 0]
		whileTrue: [globalSessionID := self
						cCode: 'time(NULL) + ioMSecs()'
						inSmalltalk: [(Random new next * SmallInteger maxVal) asInteger]].
	jmpDepth := 0.
	jmpMax := MaxJumpBuf. "xxxx: Must match the definition of jmpBuf and suspendedCallbacks"
	longRunningPrimitiveStartUsecs :=
	longRunningPrimitiveStopUsecs := 0.
	maxExtSemTabSizeSet := false.
	statForceInterruptCheck := 0.
	statStackOverflow := 0.
	statCheckForEvents := 0.
	statProcessSwitch := 0.
	statIOProcessEvents := 0.
	statStackPageDivorce := 0
]

{ #category : #'object format' }
StackInterpreter >> instSpecOfClass: classPointer [
	"This is the same as the field stored in every object header"

	^(self formatOfClass: classPointer) >> 8 bitAnd: 16rF
]

{ #category : #'frame access' }
StackInterpreter >> instVar: offset ofContext: aContext [
	"Fetch an instance avriable from a maybe married context.
	 If the context is still married compute the value of the
	 relevant inst var from the spouse frame's state."
	| spouseFP |
	<var: #spouseFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theFPAbove type: #'char *'>
	<inline: true>
	self assert: offset < MethodIndex.
	self assert: (self isContext: aContext).
	(self isMarriedOrWidowedContext: aContext) ifFalse:
		[^self fetchPointer: offset ofObject: aContext].

	self writeBackHeadFramePointers.
	(self isWidowedContext: aContext) ifTrue:
		[^self fetchPointer: offset ofObject: aContext].

	spouseFP := self frameOfMarriedContext: aContext.
	offset = SenderIndex ifTrue:
		[^self ensureCallerContext: spouseFP].
	offset = StackPointerIndex ifTrue:
		[self assert: ReceiverIndex + (self stackPointerIndexForFrame: spouseFP) < (self lengthOf: aContext).
		^self integerObjectOf: (self stackPointerIndexForFrame: spouseFP)].
	offset = InstructionPointerIndex ifTrue:
		[| theIP thePage theFPAbove |
		 spouseFP = localFP
			ifTrue: [theIP := self oopForPointer: localIP]
			ifFalse:
				[thePage := stackPages stackPageFor: spouseFP.
				 theFPAbove := self findFrameAbove: spouseFP inPage: thePage.
				 theIP := theFPAbove == 0
							ifTrue: [stackPages longAt: thePage headSP]
							ifFalse:[self oopForPointer: (self frameCallerSavedIP: theFPAbove)]].
		 ^self contextInstructionPointer: theIP frame: spouseFP].
	self error: 'bad index'.
	^0
]

{ #category : #'frame access' }
StackInterpreter >> instVar: index ofContext: aMarriedContext put: anOop [
	| theFP |
	"Assign the field of a married context.  The important case to optimize is
	 assigning the sender.  We could also consider optimizing assiging the IP but
	 typically that is followed by an assignment to the stack pointer and we can't
	 efficiently assign the stack pointer because it involves moving frames around."
	<inline: true>
	self assert: (self isMarriedOrWidowedContext: aMarriedContext).
	self writeBackHeadFramePointers.
	(self isStillMarriedContext: aMarriedContext) ifFalse:
		[self storePointer: index ofObject: aMarriedContext withValue: anOop.
		 ^nil].
	theFP := self frameOfMarriedContext: aMarriedContext.
	index == SenderIndex ifTrue:
		[| thePage onCurrentPage |
		 thePage := stackPages stackPageFor: theFP.
		 self assert: stackPage = stackPages mostRecentlyUsedPage.
		 onCurrentPage := thePage = stackPage.
		 self storeSenderOfFrame: theFP withValue: anOop.
		 onCurrentPage
			ifTrue:
				[localFP := stackPage headFP.
				 localSP := stackPage headSP]
			ifFalse:
				[stackPages markStackPageMostRecentlyUsed: stackPage].
		 ^nil].
	self externalizeIPandSP.
	self externalDivorceFrame: theFP andContext: aMarriedContext.
	self storePointer: index ofObject: aMarriedContext withValue: anOop.
	self internalizeIPandSP
]

{ #category : #'indexing primitive support' }
StackInterpreter >> install: rcvr inAtCache: cache at: atIx string: stringy [
	"Install the oop of this object in the given cache (at or atPut), along with
	its size, format and fixedSize"
	| hdr fmt totalLength fixedFields |
	<var: #cache type: 'sqInt *'>

	hdr := self baseHeader: rcvr.
	fmt := self formatOfHeader: hdr.
	(fmt = 3 and: [self isContextHeader: hdr]) ifTrue:
		["Contexts must not be put in the atCache, since their size is not constant"
		^ self primitiveFail].
	totalLength := self lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: rcvr format: fmt length: totalLength.

	cache at: atIx+AtCacheOop put: rcvr.
	cache at: atIx+AtCacheFmt put: (stringy
										ifTrue: [fmt + 16]  "special flag for strings"
										ifFalse: [fmt]).
	cache at: atIx+AtCacheFixedFields put: fixedFields.
	cache at: atIx+AtCacheSize put: totalLength - fixedFields
]

{ #category : #'plugin primitive support' }
StackInterpreter >> integerArg: index [
	"Like #stackIntegerValue: but access method arguments left-to-right"
	| oop |
	oop := self methodArg: index.
	oop = 0 ifTrue:[^0.0]. "methodArg: failed"
	^self checkedIntegerValueOf: oop
]

{ #category : #'return bytecodes' }
StackInterpreter >> internalAboutToReturn: resultOop through: aContext [
	| ourContext |
	<inline: true>
	ourContext := self ensureFrameIsMarried: localFP SP: localSP.
	self internalPush: ourContext.
	self internalPush: resultOop.
	self internalPush: aContext.
	messageSelector := self splObj: SelectorAboutToReturn.
	argumentCount := 2.
	^self normalSend
]

{ #category : #'message sending' }
StackInterpreter >> internalActivateNewMethod [
	| methodHeader numTemps rcvr errorCode |
	<inline: true>

	methodHeader := self headerOf: newMethod.
	numTemps := self tempCountOfMethodHeader: methodHeader.

	rcvr := self internalStackValue: argumentCount. "could new rcvr be set at point of send?"

	self internalPush: localIP.
	self internalPush: localFP.
	localFP := localSP.
	self internalPush: newMethod.
	self setMethod: newMethod.
	self internalPush: (self
						encodeFrameFieldHasContext: false
						isBlock: false
						numArgs: (self argumentCountOfMethodHeader: methodHeader)).
	self internalPush: nilObj. "FxThisContext field"
	self internalPush: rcvr.

	"Initialize temps..."
	argumentCount + 1 to: numTemps do:
		[:i | self internalPush: nilObj].

	"-1 to account for pre-increment in fetchNextBytecode"
	localIP := self pointerForOop: (self initialPCForHeader: methodHeader method: newMethod) - 1.

	"Pass primitive error code to last temp if method receives it (indicated
	 by an initial long store temp bytecode).  Protect against obsolete values
	 in primFailCode by checking that newMethod actually has a primitive?"
	primFailCode ~= 0 ifTrue:
		[((self methodHeaderHasPrimitive: methodHeader)
		   and: [(self byteAtPointer: localIP + 1) = 129 "long store temp"]) ifTrue:
			[errorCode := self getErrorObjectFromPrimFailCode.
			 self internalStackTopPut: errorCode "nil if primFailCode == 1, or primFailCode"].
		primFailCode := 0].

	self assert: (self frameNumArgs: localFP) == argumentCount.
	self assert: (self frameIsBlockActivation: localFP) not.
	self assert: (self frameHasContext: localFP) not.

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	localSP < stackLimit ifTrue:
		[self externalizeIPandSP.
		 self handleStackOverflowOrEventAllowContextSwitch: (self canContextSwitchIfActivating: methodHeader).
		 self internalizeIPandSP]
]

{ #category : #'return bytecodes' }
StackInterpreter >> internalCannotReturn: resultOop [
	| ourContext |
	<inline: true>
	ourContext := self ensureFrameIsMarried: localFP SP: localSP.
	self internalPush: ourContext.
	self internalPush: resultOop.
	messageSelector := self splObj: SelectorCannotReturn.
	argumentCount := 1.
	^self normalSend
]

{ #category : #'message sending' }
StackInterpreter >> internalExecuteNewMethod [
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
	^self internalActivateNewMethod
]

{ #category : #'message sending' }
StackInterpreter >> internalFindNewMethod [
	"Find the compiled method to be run when the current messageSelector is sent to the class 'lkupClass', setting the values of 'newMethod' and 'primitiveIndex'."
	| ok | 
	<inline: true>
	ok := self lookupInMethodCacheSel: messageSelector class: lkupClass.
	ok ifFalse: "entry was not found in the cache; look it up the hard way"
		[self externalizeIPandSP.
		self lookupMethodInClass: lkupClass.
		self internalizeIPandSP.
		self addNewMethodToCache: lkupClass]
]

{ #category : #'return bytecodes' }
StackInterpreter >> internalFindUnwindThroughContext: homeContext [
	"Search for either an unwind-protect (activation of method with primitive 198)
	 or homeContext along the sender chain, which ever is found first.  If homeContext
	 is not found answer nilObj, indicating cannotReturn:.  If homeContext is found
	 answer 0.  If homeContext is itself an unwind-protect answer the context, not 0."
	self externalizeIPandSP.
	^self findUnwindThroughContext: homeContext
]

{ #category : #'return bytecodes' }
StackInterpreter >> internalMustBeBoolean [
	<inline: true>
	messageSelector := self splObj: SelectorMustBeBoolean.
	argumentCount := 0.
	self normalSend
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPop: nItems [
	"In the StackInterpreter stacks grow down."
	localSP := localSP + (nItems * BytesPerWord)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPop: nItems thenPush: oop [
	"In the StackInterpreter stacks grow down."
	stackPages longAtPointer: (localSP := localSP + ((nItems - 1) * BytesPerWord)) put: oop
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPopStack [
	"In the StackInterpreter stacks grow down."
	| top |
	top := stackPages longAt: localSP.
	localSP := localSP + BytesPerWord.
	^top
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPush: object [
	"In the StackInterpreter stacks grow down."
	stackPages longAtPointer: (localSP := localSP - BytesPerWord) put: object
]

{ #category : #'primitive support' }
StackInterpreter >> internalQuickPrimitiveResponse [
	"Called under the assumption that primFunctionPtr has been preloaded"
	
	| localPrimIndex |
	self assert: self isPrimitiveFunctionPointerAnIndex.
	localPrimIndex := self cCoerceSimple: primitiveFunctionPointer to: #sqInt.
	self assert: (localPrimIndex > 255 and: [localPrimIndex < 520]).
	"Quick return inst vars"
	localPrimIndex >= 264 ifTrue:
		[self internalPop: 1 thenPush: (self fetchPointer: localPrimIndex - 264 ofObject: self internalStackTop).
		 ^true].
	"Quick return constants"
	localPrimIndex = 256 ifTrue: [^true "return self"].
	localPrimIndex = 257 ifTrue: [self internalPop: 1 thenPush: trueObj. ^true].
	localPrimIndex = 258 ifTrue: [self internalPop: 1 thenPush: falseObj. ^true].
	localPrimIndex = 259 ifTrue: [self internalPop: 1 thenPush: nilObj. ^true].
	self internalPop: 1 thenPush: (self integerObjectOf: localPrimIndex - 261).
	^true
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalStackTop [

	^stackPages longAtPointer: localSP
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalStackTopPut: aValue [

	^stackPages longAtPointer: localSP put: aValue
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalStackValue: offset [
	"In the StackInterpreter stacks grow down."
	^stackPages longAtPointer: localSP + (offset * BytesPerWord)
]

{ #category : #utilities }
StackInterpreter >> internalizeIPandSP [
	"Copy the instruction, stack and frame pointers to local variables for rapid access within the interpret loop."

	localIP := self pointerForOop: instructionPointer.
	localSP := self pointerForOop: stackPointer.
	localFP := self pointerForOop: framePointer
]

{ #category : #'interpreter shell' }
StackInterpreter >> interpret [
	"This is the main interpreter loop. It normally loops forever, fetching and executing bytecodes. When running in the context of a browser plugin VM, however, it must return control to the browser periodically. This should done only when the state of the currently running Squeak thread is safely stored in the object heap. Since this is the case at the moment that a check for interrupts is performed, that is when we return to the browser if it is time to do so. Interrupt checks happen quite frequently."

	<inline: false>
	"If stacklimit is zero then the stack pages have not been initialized."
	stackLimit = 0 ifTrue:
		[^self initStackPagesAndInterpret].
	"record entry time when running as a browser plug-in"
	self browserPluginInitialiseIfNeeded.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue: [self dispatchOn: currentBytecode in: BytecodeTable].
	localIP := localIP - 1.  "undo the pre-increment of IP before returning"
	self externalizeIPandSP.
	^nil

]

{ #category : #'stack pages' }
StackInterpreter >> interpreterAllocationReserveBytes [
	"At a rough approximation we may need to allocate up to a couple
	 of page's worth of contexts when switching stack pages, assigning
	 to senders, etc.  But the snapshot primitive voids all stack pages.
	 So a safe margin is the size of a large context times the maximum
	 number of frames per page times the number of pages."
	| availableBytesPerPage maxFramesPerPage |
	availableBytesPerPage := self stackPageByteSize - self stackLimitOffset - self stackPageHeadroom.
	maxFramesPerPage := availableBytesPerPage / BytesPerWord // FrameSlots.
	^2 raisedTo: (maxFramesPerPage * LargeContextSize * numStackPages) highBit
]

{ #category : #'plugin support' }
StackInterpreter >> ioFilename: aCharBuffer fromString: aFilenameString ofLength: filenameLength resolveAliases: aBoolean [
"the vm has to convert aFilenameString via any canonicalization and char-mapping and put the result in aCharBuffer.
Note the resolveAliases flag - this is an awful artefact of OSX and Apples demented alias handling. When opening a file, the flag must be  true, when closing or renaming it must be false. Sigh."
	<var: #aCharBuffer type: #'char *'>
	<var: #aFilenameString type: #'char *'>
	self cCode:'sqGetFilenameFromString(aCharBuffer, aFilenameString, filenameLength, aBoolean)'
		inSmalltalk:["this doesn't translate well in Smalltalk since we know how long strings are rather than considering them terminated by a 0 char. Do the best we can"
			aCharBuffer replaceFrom:1 to: filenameLength with: aFilenameString]
]

{ #category : #'system control primitives' }
StackInterpreter >> ioUpdateVMTimezone [
	"A noop in the simulator"
	<doNotGenerate>
]

{ #category : #'plugin primitive support' }
StackInterpreter >> is: oop KindOf: className [
	"Support for external primitives."
	| oopClass |
	<var: #className type:#'char *'>
	oopClass := self fetchClassOf: oop.
	[oopClass = nilObj] whileFalse:[
		(self classNameOf: oopClass Is: className) ifTrue:[^true].
		oopClass := self superclassOf: oopClass].
	^false
]

{ #category : #'plugin primitive support' }
StackInterpreter >> is: oop MemberOf: className [
	"Support for external primitives"
	| oopClass |
	<var: #className type:#'char *'>
	oopClass := self fetchClassOf: oop.
	^(self classNameOf: oopClass Is: className)
]

{ #category : #utilities }
StackInterpreter >> is: oop instanceOf: classOop compactClassIndex: compactClassIndex [
	"Answer if oop is an instance of the given class. If the class has a (non-zero)
	 compactClassIndex use that to speed up the check.  N.B. Inlining should
	 result in classOop not being accessed if compactClassIndex is non-zero."

	| ccIndex |
	<inline: true>
	(self isIntegerObject: oop) ifTrue:
		[^false].

	ccIndex := self compactClassIndexOf: oop.
	compactClassIndex ~= 0 ifTrue:
		[^compactClassIndex == ccIndex].

	^ccIndex ~= 0
	  and: [((self classHeader: oop) bitAnd: AllButTypeMask) = classOop]
]

{ #category : #'frame access' }
StackInterpreter >> isBaseFrame: theFP [
	"A base frame (first frame in a stack page) is so marked by having a null saved fp."
	<inline: true>
	<var: #theFP type: #'char *'>
	^(stackPages longAt: theFP + FoxSavedFP) == 0
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isCog [
	^false
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isContext: oop [
	<inline: true>
	^(self isNonIntegerObject: oop) and: [self isContextHeader: (self baseHeader: oop)]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isContextHeader: aHeader [
	<inline: true>
	"c.f. {BlockContext. MethodContext. PseudoContext} collect: [:class| class -> class indexIfCompact]"
	^(self compactClassIndexOfHeader: aHeader) == ClassMethodContextCompactIndex
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isContextNonInt: oop [
	<inline: true>
	^self isContextHeader: (self baseHeader: oop)
]

{ #category : #'process primitive support' }
StackInterpreter >> isEmptyList: aLinkedList [

	^ (self fetchPointer: FirstLinkIndex ofObject: aLinkedList) = nilObj
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isFloatObject: oop [
	^(self isNonIntegerObject: oop)
	   and: [ClassFloatCompactIndex ~= 0
			ifTrue: [(self compactClassIndexOf: oop) = ClassFloatCompactIndex]
			ifFalse: [(self fetchClassOfNonInt: oop) = self classFloat]]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isFloatObjectNonInt: oop floatClass: floatClass [
	^ClassFloatCompactIndex ~= 0
		ifTrue: [(self compactClassIndexOf: oop) = ClassFloatCompactIndex]
		ifFalse: [(self fetchClassOfNonInt: oop) = floatClass]
]

{ #category : #'object format' }
StackInterpreter >> isIndexable: oop [
	^(self formatOf: oop) >= 2
]

{ #category : #'frame access' }
StackInterpreter >> isMachineCodeFrame: theFP [
	"For compatibility with CoInterpreter.  Needed to avoid slowPrimitiveResponse
	 failing within ceSend:to:numArgs: et al with an unbalanced stack."
	<var: #theFP type: #'char *'>
	<inline: true>
	^false
]

{ #category : #'frame access' }
StackInterpreter >> isMarriedOrWidowedContext: aContext [
	^self isIntegerObject: (self fetchPointer: SenderIndex ofObject: aContext)
]

{ #category : #utilities }
StackInterpreter >> isNonIntObject: object instanceOf: classOop compactClassIndex: compactClassIndex [
	"Answer if the non-integer object is an instance of the given class. If the class
	 has a (non-zero) compactClassIndex use that to speed up the check.  N.B. inlining
	 should result in classOop not being accessed if compactClassIndex is non-zero."

	| ccIndex |
	<inline: true>

	ccIndex := self compactClassIndexOf: object.
	compactClassIndex ~= 0 ifTrue:
		[^compactClassIndex == ccIndex].

	^ccIndex ~= 0
	  and: [((self classHeader: object) bitAnd: AllButTypeMask) = classOop]
]

{ #category : #'image segment in/out' }
StackInterpreter >> isPlatformFloatOrderVersion: imageVersion [
	"Answer if floats are stored in the platform's float order for the given imageVersion.
	 Prior to this version they were always in big-endian (e.g. PowerPC) format."
	^imageVersion >= 6505
]

{ #category : #'primitive support' }
StackInterpreter >> isPrimitiveFunctionPointerAnIndex [
	"We save slots in the method cache by using the primitiveFunctionPointer
	 to hold either a function pointer or the index of a quick primitive. Since
	 quick primitive indices are small they can't be confused with function
	 addresses. "
	^(self cCoerce: primitiveFunctionPointer to: 'unsigned long') <= MaxQuickPrimitiveIndex
]

{ #category : #'frame access' }
StackInterpreter >> isSingleContext: aContext [
	^self isNonIntegerObject: (self fetchPointer: SenderIndex ofObject: aContext)
]

{ #category : #'frame access' }
StackInterpreter >> isStillMarriedContext: aContext [
	"Answer if aContext is married or widowed and still married.
	 If a context is widowed then turn it into a single dead context."
	^(self isMarriedOrWidowedContext: aContext)
	    and: [(self isWidowedContext: aContext) not]
]

{ #category : #'frame access' }
StackInterpreter >> isWidowedContext: aOnceMarriedContext [
	"See if the argument is connected with a live frame or not.
	 If it is not, turn it into a bereaved single context."
	| theFrame thePage shouldBeFrameCallerField |
	<var: #theFrame type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #shouldBeFrameCallerField type: #'char *'>
	self assert: (self isContext: aOnceMarriedContext).
	theFrame := self frameOfMarriedContext: aOnceMarriedContext.
	thePage := stackPages stackPageFor: theFrame.
	((stackPages isFree: thePage)
	 or: [theFrame < thePage headFP]) ifFalse:
		["The frame pointer is within the bounds of a live page.
		   Now check if it matches a frame."
		 shouldBeFrameCallerField := self withoutSmallIntegerTags:
										(self fetchPointer: InstructionPointerIndex
											ofObject: aOnceMarriedContext).
		 ((self frameCallerFP: theFrame) = shouldBeFrameCallerField
		  and: [(self frameMethodObject: theFrame) = (self fetchPointer: MethodIndex
													ofObject: aOnceMarriedContext)
		  and: [(self frameHasContext: theFrame)
		  and: [(self frameContext: theFrame) = aOnceMarriedContext]]]) ifTrue:
			["It is still married!"
			^false]].
	"It is out of range or doesn't match the frame's context.  It is widowed.  Time to wear black."
	self storePointerUnchecked: SenderIndex ofObject: aOnceMarriedContext withValue: nilObj.
	self storePointerUnchecked: InstructionPointerIndex ofObject: aOnceMarriedContext withValue: nilObj.
	^true
]

{ #category : #'jump bytecodes' }
StackInterpreter >> jump: offset [

	localIP := localIP + offset + 1.
	currentBytecode := self byteAtPointer: localIP.

]

{ #category : #'jump bytecodes' }
StackInterpreter >> jumplfFalseBy: offset [ 
	| boolean |
	boolean := self internalStackTop.
	boolean = falseObj
		ifTrue: [self jump: offset]
		ifFalse:
			[boolean = trueObj ifFalse:
				[^self internalMustBeBoolean].
			self fetchNextBytecode].
	self internalPop: 1
]

{ #category : #'jump bytecodes' }
StackInterpreter >> jumplfTrueBy: offset [ 
	| boolean |
	boolean := self internalStackTop.
	boolean = trueObj
		ifTrue: [self jump: offset]
		ifFalse:
			[boolean = falseObj ifFalse:
				[^self internalMustBeBoolean].
			self fetchNextBytecode].
	self internalPop: 1
]

{ #category : #'indexing primitive support' }
StackInterpreter >> lengthOf: oop [
	"Return the number of indexable bytes or words in the given object. Assume the argument is not an integer. For a CompiledMethod, the size of the method header (in bytes) should be subtracted from the result."

	<api>
	| header |
	<inline: true>
	<asmLabel: false> 
	header := self baseHeader: oop.
	^self lengthOf: oop baseHeader: header format: (self formatOfHeader: header)
]

{ #category : #'indexing primitive support' }
StackInterpreter >> lengthOf: oop baseHeader: hdr format: fmt [
	"Return the number of indexable bytes or words in the given object. Assume the given oop is not an integer. For a CompiledMethod, the size of the method header (in bytes) should be subtracted from the result of this method."

	| sz |
	<inline: true>
	<asmLabel: false> 
	(hdr bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [ sz := (self sizeHeader: oop) bitAnd: LongSizeMask ]
		ifFalse: [ sz := (hdr bitAnd: SizeMask)].
	sz := sz - (hdr bitAnd: Size4Bit).
	fmt <= 4
		ifTrue: [ ^ (sz - BaseHeaderSize) >> ShiftForWord "words"].
	fmt < 8
		ifTrue: [ ^ (sz - BaseHeaderSize) >> 2 "32-bit longs"]
		ifFalse: [ ^ (sz - BaseHeaderSize) - (fmt bitAnd: 3) "bytes"]
]

{ #category : #'debug printing' }
StackInterpreter >> lengthOfNameOfClass: classOop [
	<inline: false>
	(self sizeBitsOf: classOop) = metaclassSizeBytes ifTrue:
		[^self lengthOfNameOfClass: (self fetchPointer: 5 "thisClass" ofObject: classOop)].
	^self lengthOf: (self fetchPointer: 6 "name" ofObject: classOop)
]

{ #category : #'compiled methods' }
StackInterpreter >> literal: offset [
	self assert: method = (self iframeMethod: localFP).
	^self literal: offset ofMethod: method
]

{ #category : #'compiled methods' }
StackInterpreter >> literal: offset ofMethod: methodPointer [

	^ self fetchPointer: offset + LiteralStart ofObject: methodPointer

]

{ #category : #'compiled methods' }
StackInterpreter >> literalCountOf: methodPointer [
	^self literalCountOfHeader: (self headerOf: methodPointer)
]

{ #category : #'compiled methods' }
StackInterpreter >> literalCountOfHeader: headerPointer [
	<api>
	^(headerPointer >> 10) bitAnd: 16rFF
]

{ #category : #'bitblt support' }
StackInterpreter >> loadBitBltFrom: bb [
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
StackInterpreter >> loadFloatOrIntFrom: floatOrInt [
	"If floatOrInt is an integer, then convert it to a C double float and return it.
	If it is a Float, then load its value and return it.
	Otherwise fail -- ie return with primErrorCode non-zero."

	| result |
	<inline: true>
	<asmLabel: false>
	<returnTypeC: #double>
	<var: #result type: #double>

	(self isIntegerObject: floatOrInt) ifTrue:
		[^(self integerValueOf: floatOrInt) asFloat].
	self assertClassOf: floatOrInt
		is: (self splObj: ClassFloat)
		compactClassIndex: ClassFloatCompactIndex.
	self cCode: '' inSmalltalk: [result := Float new: 2].
	self successful ifTrue:
		[self fetchFloatAt: floatOrInt + BaseHeaderSize into: result].
	^result
]

{ #category : #initialization }
StackInterpreter >> loadInitialContext [
	| sched proc activeContext |
	self leakCheckFullGC ifTrue:
		[self clearLeakMapAndMapAccessibleObjects.
		 self assert: self checkHeapIntegrity].
	sched := self fetchPointer: ValueIndex ofObject: (self splObj: SchedulerAssociation).
	proc := self fetchPointer: ActiveProcessIndex ofObject: sched.
	activeContext := self fetchPointer: SuspendedContextIndex ofObject: proc.
	self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext
]

{ #category : #'debug printing' }
StackInterpreter >> log10: n [
	"compat with C library."
	<doNotGenerate>
	^n log: 10
]

{ #category : #'jump bytecodes' }
StackInterpreter >> longJumpIfFalse [

	self jumplfFalseBy: ((currentBytecode bitAnd: 3) * 256) + self fetchByte.
]

{ #category : #'jump bytecodes' }
StackInterpreter >> longJumpIfTrue [

	self jumplfTrueBy: ((currentBytecode bitAnd: 3) * 256) + self fetchByte.
]

{ #category : #'jump bytecodes' }
StackInterpreter >> longUnconditionalJump [
	| offset |
	offset := (((currentBytecode bitAnd: 7) - 4) * 256) + self fetchByte.
	localIP := localIP + offset.
	(offset < 0 "backward jump means we're in a loop; check for possible interrupts"
	 and: [localSP < stackLimit]) ifTrue:
		[self externalizeIPandSP.
		 self checkForEventsMayContextSwitch: true.
		 self browserPluginReturnIfNeeded.
		 self internalizeIPandSP].
	self fetchNextBytecode
]

{ #category : #'method lookup cache' }
StackInterpreter >> lookupInMethodCacheSel: selector class: class [
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
StackInterpreter >> lookupMethodInClass: class [
	| currentClass dictionary found |
	<inline: false>
	self assert: class ~~ nilObj.
	currentClass := class.
	[currentClass ~= nilObj]
		whileTrue:
		[dictionary := self fetchPointer: MessageDictionaryIndex ofObject: currentClass.
		dictionary = nilObj ifTrue:
			["MethodDict pointer is nil (hopefully due a swapped out stub)
				-- raise exception #cannotInterpret:."
			self createActualMessageTo: class.
			messageSelector := self splObj: SelectorCannotInterpret.
			self sendBreak: messageSelector + BaseHeaderSize
				point: (self lengthOf: messageSelector)
				receiver: nil.
			^self lookupMethodInClass: (self superclassOf: currentClass)].
		found := self lookupMethodInDictionary: dictionary.
		found ifTrue: [^currentClass].
		currentClass := self superclassOf: currentClass].

	"Could not find #doesNotUnderstand: -- unrecoverable error."
	messageSelector = (self splObj: SelectorDoesNotUnderstand) ifTrue:
		[self error: 'Recursive not understood error encountered'].

	"Cound not find a normal message -- raise exception #doesNotUnderstand:"
	self createActualMessageTo: class.
	messageSelector := self splObj: SelectorDoesNotUnderstand.
	self sendBreak: messageSelector + BaseHeaderSize
		point: (self lengthOf: messageSelector)
		receiver: nil.
	^self lookupMethodInClass: class
]

{ #category : #'message sending' }
StackInterpreter >> lookupMethodInDictionary: dictionary [ 
	"This method lookup tolerates integers as Dictionary keys to suoport
	 execution of images in which Symbols have been compacted out."
	| length index mask wrapAround nextSelector methodArray |
	<inline: true>
	<asmLabel: false>
	length := self fetchWordLengthOf: dictionary.
	mask := length - SelectorStart - 1.
	index := SelectorStart + (mask bitAnd: ((self isIntegerObject: messageSelector)
												ifTrue: [self integerValueOf: messageSelector]
												ifFalse: [self hashBitsOf: messageSelector])).

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
			 index := SelectorStart]].
	^false "for Slang"
]

{ #category : #'callback support' }
StackInterpreter >> lookupMethodNoMNUEtcInClass: class [
	"Lookup.  Answer false on failure father than performing MNU processing etc."
	| currentClass dictionary |
	<inline: true>

	currentClass := class.
	[currentClass ~= nilObj] whileTrue:
		[dictionary := self fetchPointer: MessageDictionaryIndex ofObject: currentClass.
		(dictionary ~= nilObj
		 and: [self lookupMethodInDictionary: dictionary]) ifTrue:
			[^true].
		currentClass := self superclassOf: currentClass].

	^false
]

{ #category : #'frame access' }
StackInterpreter >> makeBaseFrameFor: aContext [ "<Integer>"
	"Marry aContext with the base frame of a new stack page.  Build
	 the base frame to reflect the context's state.  Answer the new page."
	| page pointer theMethod numArgs stackPtrIndex maybeClosure |
	<inline: false>
	<var: #page type: #'StackPage *'>
	<var: #pointer type: #'char *'>
	<returnTypeC: 'StackPage *'>
	self assert: (self isSingleContext: aContext).
	page := self newStackPage.
	pointer := page baseAddress.
	theMethod := self fetchPointer: MethodIndex ofObject: aContext.
	"If the frame is a closure activation then the closure should be on the stack in
	 the pushed receiver position (closures receiver the value[:value:] messages).
	 Otherwise it should be the receiver proper."
	maybeClosure := (self fetchPointer: ClosureIndex ofObject: aContext).
	maybeClosure ~= nilObj
		ifTrue: [numArgs := self argumentCountOfClosure: maybeClosure.
			 stackPages longAt: pointer put: maybeClosure]
		ifFalse:
			[numArgs := self argumentCountOf: theMethod.
			 stackPages longAt: pointer put: (self fetchPointer: ReceiverIndex ofObject: aContext)].
	"Put the arguments on the stack"
	1 to: numArgs do:
		[:i|
		stackPages
			longAt: (pointer := pointer - BytesPerWord)
			put: (self fetchPointer: ReceiverIndex + i ofObject: aContext)].
	"saved caller ip is sender context in base frame"
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: (self fetchPointer: SenderIndex ofObject: aContext).
	"base frame's saved fp is null"
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: 0.
	page baseFP: pointer; headFP: pointer.
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: theMethod.
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: (self encodeFrameFieldHasContext: true isBlock: maybeClosure ~= nilObj numArgs: numArgs).
	self assert: (self frameHasContext: page baseFP).
	self assert: (self frameNumArgs: page baseFP) == numArgs.
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: aContext.
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: (self fetchPointer: ReceiverIndex ofObject: aContext).
	stackPtrIndex := self quickFetchInteger: StackPointerIndex ofObject: aContext.
	self assert: ReceiverIndex + stackPtrIndex < (self lengthOf: aContext).
	numArgs + 1 to: stackPtrIndex do:
		[:i|
		stackPages
			longAt: (pointer := pointer - BytesPerWord)
			put: (self fetchPointer: ReceiverIndex + i ofObject: aContext)].
	"last thing on stack is the instruction pointer"
	(self isIntegerObject: (self fetchPointer: InstructionPointerIndex ofObject: aContext)) ifFalse:
		[self error: 'context is not resumable'].
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: (self frameInstructionPointerForContext: aContext method: theMethod).
	self assert: (self fetchPointer: InstructionPointerIndex ofObject: aContext)
			= (self contextInstructionPointer: (stackPages longAt: pointer) frame: page baseFP).
	page headSP: pointer.

	"Mark context as married by setting its sender to the frame pointer plus SmallInteger
	 tags and the InstructionPointer to the saved fp (which ensures correct alignment
	 w.r.t. the frame when we check for validity)"
	self storePointerUnchecked: SenderIndex
		ofObject: aContext
		withValue: (self withSmallIntegerTags: page baseFP).
	self storePointerUnchecked: InstructionPointerIndex
		ofObject: aContext
		withValue: (self withSmallIntegerTags: 0).
	self assert: (self isIntegerObject: (self fetchPointer: SenderIndex ofObject: aContext)).
	self assert: (self frameOfMarriedContext: aContext) = page baseFP.

	^page
]

{ #category : #utilities }
StackInterpreter >> makePointwithxValue: xValue yValue: yValue [
"make a Point xValue@yValue.
We know both will be integers so no value nor root checking is needed"
	| pointResult |
	pointResult := self eeInstantiateSmallClass: (self splObj: ClassPoint) sizeInBytes: 3*BytesPerWord.
	self storePointerUnchecked: XIndex ofObject: pointResult withValue: (self integerObjectOf: xValue).
	self storePointerUnchecked: YIndex ofObject: pointResult withValue: (self integerObjectOf: yValue).
	^ pointResult
]

{ #category : #'object memory support' }
StackInterpreter >> mapInterpreterOops [
	"Map all oops in the interpreter's state to their new values 
	during garbage collection or a become: operation."
	"Assume: All traced variables contain valid oops."
	| oop |
	nilObj := self remap: nilObj.
	falseObj := self remap: falseObj.
	trueObj := self remap: trueObj.
	specialObjectsOop := self remap: specialObjectsOop.
	self mapStackPages.
	self mapMachineCode.
	self mapTraceLogs.
	self mapVMRegisters.
	self mapProfileState.
	primResult = 0 ifFalse:[primResult := self remap: primResult].
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
StackInterpreter >> mapMachineCode [
	"This is a no-op in the StackVM"
]

{ #category : #'object memory support' }
StackInterpreter >> mapProfileState [
	| fwdBlock targetObj |
	profileProcess := self remap: profileProcess.
	profileMethod := self remap: profileMethod.
	profileSemaphore := self remap: profileSemaphore.
	"Since the longRunningPrimitiveCheckMethod is sampled at interrupt time it may be invalid.
	 Be very careful with it."
	(longRunningPrimitiveCheckMethod ~= nil
	 and: [self isObjectForwarded: longRunningPrimitiveCheckMethod]) ifTrue:
		["If it is invalid at this point we'd better nil it."
		 fwdBlock := self forwardingPointerOf: longRunningPrimitiveCheckMethod.
		 (self fwdBlockValid: fwdBlock)
			ifTrue:
				[targetObj := self longAt: fwdBlock.
				 (self addressCouldBeObjWhileForwarding: targetObj)
					ifTrue: [longRunningPrimitiveCheckMethod := targetObj]
					ifFalse: [self voidLongRunningPrimitive: 'bad *fwd']]
			ifFalse: [self voidLongRunningPrimitive: 'bad fwd->']].
	longRunningPrimitiveCheckSemaphore ~= nil ifTrue:
		[longRunningPrimitiveCheckSemaphore := self remap: longRunningPrimitiveCheckSemaphore]
]

{ #category : #'object memory support' }
StackInterpreter >> mapStackPages [
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #theIPPtr type: #'char *'>
	"Need to write back the frame pointers unless all pages are free (as in snapshot)"
	stackPage ~= 0 ifTrue:
		[self externalWriteBackHeadFramePointers].
	0 to: numStackPages - 1 do:
		[:i| | thePage theSP theFP callerFP theIPPtr theIP oop |
		thePage := stackPages stackPageAt: i.
		thePage isFree ifFalse:
			[theSP := thePage headSP.
			 theFP := thePage  headFP.
			 "Skip the instruction pointer on top of stack of inactive pages."
			 thePage = stackPage
				ifTrue: [theIPPtr := 0]
				ifFalse:
					[theIPPtr := theSP.
					 theSP := theSP + BytesPerWord].
			[self assert: (thePage addressIsInPage: theFP).
			 self assert: (thePage addressIsInPage: theSP).
			 self assert: (theIPPtr = 0 or: [thePage addressIsInPage: theFP]).
			 [theSP <= (theFP + FoxReceiver)] whileTrue:
				[oop := stackPages longAt: theSP.
				 (self isIntegerObject: oop) ifFalse:
					[stackPages longAt: theSP put: (self remap: oop)].
				 theSP := theSP + BytesPerWord].
			 (self frameHasContext: theFP) ifTrue:
				[stackPages
					longAt: theFP + FoxThisContext
					put: (self remap: (self frameContext: theFP))].
			 theIPPtr ~= 0 ifTrue:
				[self assert: (stackPages longAt: theIPPtr) > (self frameMethod: theFP).
				 theIP := (stackPages longAt: theIPPtr) - (self frameMethod: theFP)].
			 stackPages
				longAt: theFP + FoxMethod
				put: (self remap: (self frameMethod: theFP)).
			 theIPPtr ~= 0 ifTrue:
				[stackPages longAt: theIPPtr put: theIP + (self frameMethod: theFP)].
			 (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
				[theSP := (theIPPtr := theFP + FoxCallerSavedIP) + BytesPerWord.
				 theFP := callerFP].
			 theSP := theFP + FoxCallerContext. "a.k.a. FoxCallerSavedIP"
			 [theSP <= thePage baseAddress] whileTrue:
				[oop := stackPages longAt: theSP.
				 (self isIntegerObject: oop) ifFalse:
					[stackPages longAt: theSP put: (self remap: oop)].
				 theSP := theSP + BytesPerWord]]]
]

{ #category : #'object memory support' }
StackInterpreter >> mapTraceLogs [
	"This is a no-op in the StackVM"
]

{ #category : #'object memory support' }
StackInterpreter >> mapVMRegisters [
	"Map the oops in the interpreter's vm ``registers'' to their new values 
	during garbage collection or a become: operation."
	"Assume: All traced variables contain valid oops."
	instructionPointer := instructionPointer - method. "*rel to method"
	self setMethod: (self remap: method).
	instructionPointer := instructionPointer + method. "*rel to method"
	messageSelector := self remap: messageSelector.
	newMethod := self remap: newMethod.
	lkupClass := self remap: lkupClass
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceAndMaybeFreeStackPages: fullGCFlag [
	"Read markAndTraceStackPages:'s comment.  Finish tracing to-be-traced pages.
	 Then free any untraced pages."
	| thePage foundToBeTracedPage |
	<var: #thePage type: #'StackPage *'>
	<inline: false>
	fullGCFlag ifFalse:
		[0 to: numStackPages - 1 do:
			[:i|
			thePage := stackPages stackPageAt: i.
			self assert: (thePage trace: -1) ~= 0]. "Invalidate the trace state for assertion checks"
		^nil].
	[foundToBeTracedPage := false.
	0 to: numStackPages - 1 do:
		[:i|
		thePage := stackPages stackPageAt: i.
		((stackPages isFree: thePage) not
		 and: [thePage trace = 1]) ifTrue:
			[foundToBeTracedPage := true.
			 thePage trace: 2.
			 self markAndTraceStackPage: thePage]].
	foundToBeTracedPage] whileTrue.

	0 to: numStackPages - 1 do:
		[:i|
		thePage := stackPages stackPageAt: i.
		((stackPages isFree: thePage) not
		 and: [thePage trace = 0]) ifTrue:
			[self assert: (self noMarkedContextsOnPage: thePage).
			 stackPages freeStackPage: thePage].
		self assert: (thePage trace: -1) ~= 0] "Invalidate the trace state for assertion checks"
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceInterpreterOops: fullGCFlag [
	"Mark and trace all oops in the interpreter's state."
	"Assume: All traced variables contain valid oops."
	| oop |
	"Must mark stack pages first to initialize the per-page trace
	 flags for full garbage collect before any subsequent tracing."
	self markAndTraceStackPages: fullGCFlag.
	self markAndTrace: specialObjectsOop. "also covers nilObj, trueObj, falseObj, and compact classes"
	(self isIntegerObject: messageSelector) ifFalse:
		[self markAndTrace: messageSelector].
	self markAndTrace: newMethod.
	self markAndTrace: lkupClass.
	self traceProfileState.
	primResult = 0 ifFalse:[self markAndTrace: primResult].

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
	self markAndTraceTraceLog
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceOrFreeMachineCode: fullGCFlag [
	"This is a no-op in the StackVM"
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceStackPage: thePage [
	| theSP theFP frameRcvrOffset callerFP oop |
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #frameRcvrOffset type: #'char *'>
	<var: #callerFP type: #'char *'>
	<inline: false>
	self assert: (stackPages isFree: thePage) not.
	theSP := thePage headSP.
	theFP := thePage  headFP.
	"Skip the instruction pointer on top of stack of inactive pages."
	thePage = stackPage ifFalse:
		[theSP := theSP + BytesPerWord].
	[frameRcvrOffset := self frameReceiverOffset: theFP.
	 [theSP <= frameRcvrOffset] whileTrue:
		[oop := stackPages longAt: theSP.
		 (self isIntegerObject: oop) ifFalse:
			[self markAndTrace: oop].
		 theSP := theSP + BytesPerWord].
	(self frameHasContext: theFP) ifTrue:
		[self assert: (self isContext: (self frameContext: theFP)).
		 self markAndTrace: (self frameContext: theFP)].
	self markAndTrace: (self iframeMethod: theFP).
	(callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
		[theSP := theFP + FoxCallerSavedIP + BytesPerWord.
		 theFP := callerFP].
	theSP := self isCog
				ifTrue: [theFP + FoxCallerSavedIP + BytesPerWord] "caller ip is ceBaseReturnPC"
				ifFalse: [theFP + FoxCallerSavedIP]. "caller ip is frameCallerContext in a base frame"
	[theSP <= thePage baseAddress] whileTrue:
		[oop := stackPages longAt: theSP.
		 (self isIntegerObject: oop) ifFalse:
			[self markAndTrace: oop].
		 theSP := theSP + BytesPerWord]
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceStackPages: fullGCFlag [
	"GC of pages.  Throwing away all stack pages on full GC is simple but dangerous
	 because it causes us to allocate lots of contexts immediately before a GC.
	 Reclaiming pages whose top context is not referenced is poor because it would
	 take N incrementalGCs to reclaim N unused pages.  Only the page whose top
	 context is not referred to by the bottom context of any other page would be
	 reclaimed.  Not until the next GC would the page whose top contect is the
	 previously reclaimed page's base frame's bottom context be reclaimed.

	 Better is to not mark stack pages until their contexts are encountered.  We can
	 eagerly trace the active page and the page reachable from its bottom context
	 if any, and so on.  Other pages can be marked when we encounter a married
	 context."
	| thePage context |
	<var: #thePage type: #'StackPage *'>
	<inline: false>
	"Need to write back the frame pointers unless all pages are free (as in snapshot)"
	stackPage ~= 0 ifTrue:
		[self externalWriteBackHeadFramePointers].

	0 to: numStackPages - 1 do:
		[:i|
		thePage := stackPages stackPageAt: i.
		thePage trace: 0].

	"On an incremental GC simply consider all non-free stack pages to be roots."
	fullGCFlag ifFalse:
		[0 to: numStackPages - 1 do:
			[:i|
			thePage := stackPages stackPageAt: i.
			(stackPages isFree: thePage) ifFalse:
				[thePage trace: 2.
				 self markAndTraceStackPage: thePage]].
		^nil].

	"On a full GC only eagerly trace pages referenced from the active page."
	stackPage = 0 ifTrue: [^nil].
	thePage := stackPage.
	[thePage trace: 2.
	 self markAndTraceStackPage: thePage.
	 context := self frameCallerContext: thePage baseFP.
	 ((self isContext: context)
	  and: [(self isMarriedOrWidowedContext: context)
	  and: [self isStillMarriedContext: context]]) ifTrue:
		[thePage := stackPages stackPageFor:  (self frameOfMarriedContext: context).
		 self assert: (stackPages isFree: thePage) not].
	 thePage trace = 0] whileTrue
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceTraceLog [
	"This is a no-op in the StackVM"
]

{ #category : #'frame access' }
StackInterpreter >> marriedContext: spouseContext pointsTo: anOop stackDeltaForCurrentFrame: stackDeltaForCurrentFrame [
	"This is a helper for primitiveObjectPointsTo so it *does not* check the frameContext field because that is an implicit self-reference not present in the stale ."
	| theFP thePage theSP rcvrOffset |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #rcvrOffset type: #'char *'>
	theFP := self frameOfMarriedContext: spouseContext.
	theFP = framePointer
		ifTrue: [theSP := stackPointer + (stackDeltaForCurrentFrame * BytesPerWord)]
		ifFalse:
			[thePage := stackPages stackPageFor: theFP.
			theSP := self findSPOf: theFP on: thePage].
	(self isIntegerObject: anOop)
		ifTrue: "Check stack and instruction pointer fields."
			[(anOop = (self integerObjectOf: (self stackPointerIndexForFrame: theFP WithSP: theSP))
			or: [anOop = (self externalInstVar: InstructionPointerIndex ofContext: spouseContext)]) ifTrue:
				[^true]]
		ifFalse: "Check method and sender fields, avoiding unnecessarily reifying sender context."
			[anOop = (self frameMethodObject: theFP) ifTrue:
				[^true].
			 (self isBaseFrame: theFP)
				ifTrue: [anOop = (self frameCallerContext: theFP) ifTrue:
							[^true]]
				ifFalse: [((self frameHasContext: (self frameCallerFP: theFP))
						and: [anOop = (self frameContext: (self frameCallerFP: theFP))]) ifTrue:
							[^true]]].
	"Now check receiver, temps and stack contents"
	rcvrOffset := self frameReceiverOffset: theFP.
	 [theSP <= rcvrOffset] whileTrue:
		[anOop = (stackPages longAt: theSP) ifTrue:
			[^true].
		 theSP := theSP + BytesPerWord].
	"Finally check stacked receiver (closure field or duplicate of receiver) and arguments"
	theSP := theFP + FoxCallerSavedIP + BytesPerWord.
	rcvrOffset := theFP + (self frameStackedReceiverOffset: theFP).
	 [theSP <= rcvrOffset] whileTrue:
		[anOop = (stackPages longAt: theSP) ifTrue:
			[^true].
		 theSP := theSP + BytesPerWord].
	^false
]

{ #category : #'frame access' }
StackInterpreter >> marryContextInNewStackPageAndInitializeInterpreterRegisters: aContext [
	"Establish aContext at the base of a new stackPage, make the stackPage the
	 active one and set-up the interreter registers.  This is used to boot the system
	 and bring it back after a snapshot."
	| newPage |
	<var: #newPage type: #'StackPage *'>
	self assert: stackPage = 0.
	newPage := self makeBaseFrameFor: aContext.
	self setStackPageAndLimit: newPage.
	framePointer := stackPage headFP.
	stackPointer := stackPage headSP.
	self setMethod: (self iframeMethod: stackPage headFP).
	instructionPointer := self popStack
]

{ #category : #'frame access' }
StackInterpreter >> marryFrame: theFP SP: theSP [
	"Marry an unmarried frame.  This means creating a spouse context
	 initialized with a subset of the frame's state (state through the last argument)
	 that references the frame."
	| theContext methodHeader byteSize numArgs numStack closureOrNil |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	self assert: (self frameHasContext: theFP) not.

	methodHeader := self headerOf: (self frameMethod: theFP).
	"Decide how much of the stack to preserve in widowed contexts.  Preserving too much
	 state will potentially hold onto garbage.  Holding onto too little may mean that a dead
	 context isn't informative enough in a debugging situation.  We compromise, retaining
	 only the arguments with no temporaries.  Note that we still set the stack pointer to its
	 current value, but stack contents other than the arguments are nil."
	numArgs := self frameNumArgs: theFP.
	numStack := self stackPointerIndexForFrame: theFP WithSP: theSP.

	closureOrNil := (self frameIsBlockActivation: theFP)
						ifTrue: [self pushedReceiverOrClosureOfFrame: theFP]
						ifFalse: [nilObj].

	byteSize := (methodHeader bitAnd: LargeContextBit) ~= 0
					ifTrue: [LargeContextSize]
					ifFalse: [SmallContextSize].
	theContext := self eeInstantiateMethodContextByteSize: byteSize.
	self assert: numStack + ReceiverIndex << ShiftForWord + BaseHeaderSize <= byteSize. 
	"Mark context as married by setting its sender to the frame pointer plus SmallInteger
	 tags and the InstructionPointer to the saved fp (which ensures correct alignment
	 w.r.t. the frame when we check for validity)"
	self storePointerUnchecked: SenderIndex
		ofObject: theContext
		withValue: (self withSmallIntegerTags: theFP).
	self storePointerUnchecked: InstructionPointerIndex
		ofObject: theContext
		withValue: (self withSmallIntegerTags: (self frameCallerFP: theFP)).
	self storePointerUnchecked: StackPointerIndex
		ofObject: theContext
		withValue: (self integerObjectOf: numStack).
	self storePointerUnchecked: MethodIndex
		ofObject: theContext
		withValue: (self frameMethod: theFP).
	self storePointerUnchecked: ClosureIndex ofObject: theContext withValue: closureOrNil.
	self storePointerUnchecked: ReceiverIndex
		ofObject: theContext
		withValue: (self frameReceiver: theFP).
	"Store just the arguments.  If the frame is divorced the context
	 will have valid arguments but all temporaries will be nil."
	1 to: numArgs do:
		[:i|
		self storePointerUnchecked: ReceiverIndex + i
			ofObject: theContext "inline self temporary: i - 1 in:theFP" 
			withValue: (stackPages longAt: theFP
										+ FoxCallerSavedIP
										+ ((numArgs - i + 1) * BytesPerWord))].
	numArgs + 1 to: numStack do:
		[:i|
		self storePointerUnchecked: ReceiverIndex + i
			ofObject: theContext
			withValue: nilObj].

	stackPages longAt: theFP + FoxThisContext put: theContext.
	stackPages byteAt: theFP + FoxFrameFlags + 2 put: 1.

	self assert: (self frameHasContext: theFP).
	self assert: (self frameOfMarriedContext: theContext) = theFP.
	self assert: numStack + ReceiverIndex < (self lengthOf: theContext).

	^theContext

]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodArg: index [
	"Like #stackValue: but access method arguments left-to-right"
	shouldPopArgs := true.
	index > argumentCount + 1 ifTrue:[
		self cCode: 'fprintf(stderr,"[VM]: Attempt to access method args beyond range\n")'.
		self printCallStack.
		self primitiveFail.
		^0].
	^self stackValue: argumentCount - index
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodArgumentCount [
	^argumentCount
]

{ #category : #'compiled methods' }
StackInterpreter >> methodClassOf: methodPointer [

	^ self fetchPointer: ValueIndex ofObject: (self literal: (self literalCountOf: methodPointer) - 1 ofMethod: methodPointer)
]

{ #category : #'compiled methods' }
StackInterpreter >> methodHeaderHasPrimitive: methodHeader [
	"Note: We now have 10 bits of primitive index, but they are in two places
	 for temporary backward compatibility.  The time to unpack is negligible,
	 since the derived primitive function pointer is stored in the method cache."
	^(methodHeader bitAnd: 16r200003FE) ~= 0
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodPrimitiveIndex [
	<api>
	((self addressCouldBeObj: newMethod)
	 and: [self isCompiledMethod: newMethod]) ifFalse:
		[^-1].
	^self primitiveIndexOf: newMethod
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodReturnValue: oop [
	"Stores the return value from a primitive"
	primResult = 0 ifFalse:[
		"TODO: Report attempt to set return value multiple times."
		self cCode: 'fprintf(stderr, "[VM]: Attempt to set method return type multiple times\n")'.
		self printCallStack.
	].
	shouldPopArgs := true.
	primResult := oop.
	^0
]

{ #category : #'frame access' }
StackInterpreter >> mframeCogMethod: theFP [
	self shouldNotImplement
]

{ #category : #'primitive support' }
StackInterpreter >> microsecondsToMilliseconds: microseconds [
	<var: #microseconds type: #usqLong>
	^microseconds // 1000 bitAnd: MillisecondClockMask
]

{ #category : #initialization }
StackInterpreter >> moduleUnloaded: aModuleName [ 
	"The module with the given name was just unloaded. 
	Make sure we have no dangling references."
	<export: true>
	<var: #aModuleName type: 'char *'>
	(aModuleName strcmp: 'SurfacePlugin') = 0
		ifTrue: ["Surface plugin went away. Should never happen. But  then, who knows"
			showSurfaceFn := 0]
]

{ #category : #'frame access' }
StackInterpreter >> moveFramesIn: oldPage through: theFP toPage: newPage [
	"Move frames from the hot end of oldPage through to theFP to newPage.
	 This has the effect of making theFP a base frame which can be stored into.
	 Answer theFP's new location."
	| newSP newFP stackedReceiverOffset delta callerFP callerIP fpInNewPage offsetCallerFP theContext |
	<inline: false>
	<var: #oldPage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<var: #newPage type: #'StackPage *'>
	<var: #newSP type: #'char *'>
	<var: #newFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #fpInNewPage type: #'char *'>
	<var: #offsetCallerFP type: #'char *'>
	<var: #source type: #'char *'>
	<returnTypeC: 'char *'>
	newSP := newPage baseAddress + BytesPerWord.
	stackedReceiverOffset := self frameStackedReceiverOffset: theFP.
	"First move the data.  We will fix up frame pointers later."
	theFP + stackedReceiverOffset
		to: oldPage headSP
		by: BytesPerWord negated
		do: [:source|
			newSP := newSP - BytesPerWord.
			stackPages longAt: newSP put: (stackPages longAt: source)].
	"newSP = oldSP + delta => delta = newSP - oldSP"
	delta := newSP - oldPage headSP.
	newFP := newPage baseAddress - stackedReceiverOffset.
	self setHeadFP: oldPage headFP + delta andSP: newSP inPage: newPage.
	newPage baseFP: newFP.
	callerFP := self frameCallerFP: theFP.
	self assert: (self isBaseFrame: theFP) not.
	self assert: (self frameHasContext: callerFP).
	callerIP := self oopForPointer: (self frameCallerSavedIP: theFP).
	stackPages longAt: theFP + stackedReceiverOffset put: callerIP.
	oldPage
		headFP: callerFP;
		headSP: theFP + stackedReceiverOffset.
	"Mark the new base frame in the new page (FoxCallerContext a.k.a. FoxCallerSavedIP)"
	stackPages longAt: newFP + FoxCallerContext put:  (self frameContext: callerFP).
	stackPages longAt: newFP + FoxSavedFP put: 0.
	"Now relocate frame pointers, updating married contexts to refer to their moved spouse frames."
	fpInNewPage := newPage headFP.
	[offsetCallerFP := self frameCallerFP: fpInNewPage.
	 offsetCallerFP ~= 0 ifTrue:
		[offsetCallerFP := offsetCallerFP + delta].
	 stackPages longAt: fpInNewPage + FoxSavedFP put: (self oopForPointer: offsetCallerFP).
	 (self frameHasContext: fpInNewPage) ifTrue:
		[theContext := self frameContext: fpInNewPage.
		 self storePointerUnchecked: SenderIndex
			ofObject: theContext
			withValue: (self withSmallIntegerTags: fpInNewPage).
		 self storePointerUnchecked: InstructionPointerIndex
			ofObject: theContext
			withValue: (self withSmallIntegerTags: offsetCallerFP)].
	 fpInNewPage := offsetCallerFP.
	 fpInNewPage ~= 0] whileTrue.
	^newFP
]

{ #category : #'internal interpreter access' }
StackInterpreter >> nacFetchStackPointerOf: aContext [
	"A version of fetchStackPointerOf: for use when objects may be forwarded.
	 Does not do an assert-check of the stack pointer being in bounds."
	| sp |
	<inline: true>
	sp := self fetchPointer: StackPointerIndex ofObject: aContext.
	(self isIntegerObject: sp) ifFalse: [^0].
	^self integerValueOf: sp
]

{ #category : #'debug printing' }
StackInterpreter >> nameOfClass: classOop [
	"Brain-damaged nameOfClass: for C VM.  Does *not* answer Foo class for metaclasses.
	 Use e.g. classIsMeta: to avoid being fooled."
	<inline: false>
	<returnTypeC: 'char *'>
	(self sizeBitsOf: classOop) = metaclassSizeBytes ifTrue:
		[^self nameOfClass: (self fetchPointer: 5 "thisClass" ofObject: classOop)].
	^self pointerForOop: (self fetchPointer: 6 "name" ofObject: classOop) + BaseHeaderSize
]

{ #category : #'stack pages' }
StackInterpreter >> newStackPage [
	"MRUP-->used page<->used page<->used page<->used page<--LRUP
	               ^                        <-next-prev->                         ^
	                |                                                                       |
	                v                        <-prev-next->                         v
	                free page<->free page<->free page<->free page"
	| lruOrFree |
	<var: #lruOrFree type: #'StackPage *'>
	<returnTypeC: #'StackPage *'>
	lruOrFree := stackPages mostRecentlyUsedPage nextPage.
	(stackPages isFree: lruOrFree) ifTrue:
		[^lruOrFree].
	self divorceFramesIn: lruOrFree.
	^lruOrFree
]

{ #category : #'object memory support' }
StackInterpreter >> noMarkedContextsOnPage: thePage [
	"Answer true if there are no marked contexts on thePage."
	| theFP |
	<var: #thePage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<inline: false>
	self assert: (stackPages isFree: thePage) not.
	theFP := thePage  headFP.
	[(self frameHasContext: theFP) ifTrue:
		[self assert: (self isContext: (self frameContext: theFP)).
		 (self isMarked: (self frameContext:  theFP)) ifTrue:
			[^false]].
	(theFP := self frameCallerFP: theFP) ~= 0] whileTrue.
	^true
]

{ #category : #'object format' }
StackInterpreter >> nonWeakFieldsOf: oop [
	"Return the number of non-weak fields in oop (i.e. the number of fixed fields).
	Note: The following is copied from fixedFieldsOf:format:length: since we do know
	the format of the oop (e.g. format = 4) and thus don't need the length."
	| class classFormat |
	<inline: false> "No need to inline - we won't call this often"

	self assert: (self isWeakNonInt: oop).

	"fmt = 3 or 4: mixture of fixed and indexable fields, so must look at class format word"
	class := self fetchClassOfNonInt: oop.
	classFormat := self formatOfClass: class.
	^ (classFormat >> 11 bitAnd: 16rC0) + (classFormat >> 2 bitAnd: 16r3F) - 1

]

{ #category : #'message sending' }
StackInterpreter >> normalSend [
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that 
	the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	| rcvr |
	<sharedCodeNamed: 'normalSend' inCase: 131>
	rcvr := self internalStackValue: argumentCount.
	lkupClass := self fetchClassOf: rcvr.
	self assert: lkupClass ~~ nilObj.
	self commonSend
]

{ #category : #'stack pages' }
StackInterpreter >> numStkPages [
	^numStackPages
]

{ #category : #'plugin primitive support' }
StackInterpreter >> objectArg: index [
	"Like #stackObjectValue: but access method arguments left-to-right"
	| oop |
	oop := self methodArg: index.
	oop = 0 ifTrue:[^0.0]. "methodArg: failed"
	(self isIntegerObject: oop) ifTrue: [self primitiveFail. ^ nil].
	^oop
]

{ #category : #'debug support' }
StackInterpreter >> okayFields: oop [
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
			[i := (self literalCountOf: oop) - 1]
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
StackInterpreter >> okayInterpreterObjects [

	| oopOrZero oop |
	self okayFields: nilObj.
	self okayFields: falseObj.
	self okayFields: trueObj.
	self okayFields: specialObjectsOop.
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
	self okayStackZone.
]

{ #category : #'debug support' }
StackInterpreter >> okayOop: signedOop [
	"Verify that the given oop is legitimate. Check address, header, and size but not class."

	| sz type fmt unusedBit oop |
	<var: #oop type: 'usqInt'>
	oop := self cCoerce: signedOop to: 'usqInt'.

	"address and size checks"
	(self isIntegerObject: oop) ifTrue: [ ^true ].
	(oop < freeStart)
		ifFalse: [ self error: 'oop is not a valid address'. ^false ].
	((oop \\ BytesPerWord) = 0)
		ifFalse: [ self error: 'oop is not a word-aligned address'. ^false ].
	sz := self sizeBitsOf: oop.
	(oop + sz) < endOfMemory
		ifFalse: [ self error: 'oop size would make it extend beyond the end of memory'. ^false ].

	"header type checks"
	type := self headerType: oop.
	type = HeaderTypeFree
		ifTrue:  [ self error: 'oop is a free chunk, not an object'. ^false ].
	type = HeaderTypeShort ifTrue: [
		(self compactClassIndexOf: oop) = 0
			ifTrue:  [ self error: 'cannot have zero compact class field in a short header'. ^false ].
	].
	type = HeaderTypeClass ifTrue: [
		((oop >= BytesPerWord) and: [(self headerType: oop - BytesPerWord) = type])
			ifFalse: [ self error: 'class header word has wrong type'. ^false ].
	].
	type = HeaderTypeSizeAndClass ifTrue: [
		((oop >= (BytesPerWord*2)) and:
		 [(self headerType: oop - (BytesPerWord*2)) = type and:
		 [(self headerType: oop - BytesPerWord) = type]])
			ifFalse: [ self error: 'class header word has wrong type'. ^false ].
	].

	"format check"
	fmt := self formatOf: oop.
	((fmt = 5) | (fmt = 7))
		ifTrue:  [ self error: 'oop has an unknown format type'. ^false ].

	"mark and root bit checks"
	unusedBit := 16r20000000.
	BytesPerWord = 8
		ifTrue:
			[unusedBit := unusedBit << 16.
			 unusedBit := unusedBit << 16].
	((self longAt: oop) bitAnd: unusedBit) = 0
		ifFalse: [ self error: 'unused header bit 30 is set; should be zero'. ^false ].
"xxx
	((self longAt: oop) bitAnd: MarkBit) = 0
		ifFalse: [ self error: 'mark bit should not be set except during GC' ].
xxx"
	(((self longAt: oop) bitAnd: RootBit) = 1 and:
	 [oop >= youngStart])
		ifTrue: [ self error: 'root bit is set in a young object'. ^false ].
	^true

]

{ #category : #'image segment in/out' }
StackInterpreter >> oopHasAcceptableClass: signedOop [
	"Similar to oopHasOkayClass:, except that it only returns true or false."

	| oopClass formatMask behaviorFormatBits oopFormatBits oop |
	<var: #oop type: #usqInt>
	<var: #oopClass type: #usqInt>

	(self isIntegerObject: signedOop) ifTrue: [^ true].

	oop := self cCoerce: signedOop to: #usqInt.

	oop < freeStart ifFalse: [^ false].
	((oop \\ BytesPerWord) = 0) ifFalse: [^ false].
	(oop + (self sizeBitsOf: oop)) < endOfMemory ifFalse: [^ false].
	oopClass := self cCoerce: (self fetchClassOfNonInt: oop) to: #usqInt.

	(self isIntegerObject: oopClass) ifTrue: [^ false].
	(oopClass < freeStart) ifFalse: [^ false].
	((oopClass \\ BytesPerWord) = 0) ifFalse: [^ false].
	(oopClass + (self sizeBitsOf: oopClass)) < freeStart ifFalse: [^ false].
	((self isPointersNonInt: oopClass) and: [(self lengthOf: oopClass) >= 3]) ifFalse: [^ false].
	(self isBytesNonInt: oop)
		ifTrue: [ formatMask := 16rC00 ]  "ignore extra bytes size bits"
		ifFalse: [ formatMask := 16rF00 ].

	behaviorFormatBits := (self formatOfClass: oopClass) bitAnd: formatMask.
	oopFormatBits := (self baseHeader: oop) bitAnd: formatMask.
	behaviorFormatBits = oopFormatBits ifFalse: [^ false].
	^ true
]

{ #category : #'debug support' }
StackInterpreter >> oopHasOkayClass: signedOop [
	"Attempt to verify that the given oop has a reasonable behavior. The class must be a valid, non-integer oop and must not be nilObj. It must be a pointers object with three or more fields. Finally, the instance specification field of the behavior must match that of the instance."

	| oop oopClass formatMask behaviorFormatBits oopFormatBits |
	<var: #oop type: #usqInt>
	<var: #oopClass type: #usqInt>

	oop := self cCoerce: signedOop to: #usqInt.
	self okayOop: oop.
	oopClass := self cCoerce: (self fetchClassOf: oop) to: #usqInt.

	(self isIntegerObject: oopClass)
		ifTrue: [ self error: 'a SmallInteger is not a valid class or behavior'. ^false ].
	(self okayOop: oopClass)
		ifFalse: [ self error: 'class oop is not ok'. ^false ].
	((self isPointers: oopClass) and: [(self lengthOf: oopClass) >= 3])
		ifFalse: [ self error: 'a class (behavior) must be a pointers object of size >= 3'. ^false ].
	(self isBytes: oop)
		ifTrue: [ formatMask := 16rC00 ]  "ignore extra bytes size bits"
		ifFalse: [ formatMask := 16rF00 ].

	behaviorFormatBits := (self formatOfClass: oopClass) bitAnd: formatMask.
	oopFormatBits := (self baseHeader: oop) bitAnd: formatMask.
	behaviorFormatBits = oopFormatBits
		ifFalse: [ self error: 'object and its class (behavior) formats differ'. ^false ].
	^true
]

{ #category : #'plugin primitive support' }
StackInterpreter >> pluginPop: nItems [
	"The (obsolete) interface used by primitives that doesn't actually do anything besides noting the fact someone tried to pop the given number of elements"
	shouldPopArgs := true.
	primPops := primPops + nItems.
]

{ #category : #'plugin primitive support' }
StackInterpreter >> pluginPop: nItems thenPush: oop [
	"A variant of pop:thenPush: used by primitives that doesn't actually do anything besides noting the fact someone tried to pop the given number of elements"
	self pluginPop: nItems.
	self pluginPush: oop.

]

{ #category : #'plugin primitive support' }
StackInterpreter >> pluginPush: oop [
	"A variant of push: used by primitives to communicate the return value"
	primPops := primPops - 1. "a push counts as a negative pop"
	self methodReturnValue: oop.
]

{ #category : #'plugin primitive support' }
StackInterpreter >> pluginPushBool: trueOrFalse [
	"For plugin use only"
	trueOrFalse
		ifTrue: [ self pluginPush: trueObj ]
		ifFalse: [ self pluginPush: falseObj ].
]

{ #category : #'plugin primitive support' }
StackInterpreter >> pluginPushFloat: f [
	"For plugin use only"
	<var: #f type: 'double '>
	self pluginPush: (self floatObjectOf: f).
]

{ #category : #'plugin primitive support' }
StackInterpreter >> pluginPushInteger: integerValue [
	"For plugin use only"
	self pluginPush: (self integerObjectOf: integerValue).
]

{ #category : #'plugin primitive support' }
StackInterpreter >> pluginStackFloatValue: index [
	"For plugin use only."
	<returnTypeC: #double>
	shouldPopArgs := true.
	index > (argumentCount + 1) ifTrue:[
		self cCode: 'fprintf(stderr,"[VM]: Attempt to access method args beyond range\n")'.
		self printCallStack.
		self primitiveFail.
		^0].
	^self stackFloatValue: index

]

{ #category : #'plugin primitive support' }
StackInterpreter >> pluginStackIntegerValue: index [
	"For plugin use only."
	shouldPopArgs := true.
	index > (argumentCount + 1) ifTrue:[
		self cCode: 'fprintf(stderr,"[VM]: Attempt to access method args beyond range\n")'.
		self printCallStack.
		self primitiveFail.
		^0].
	^self stackIntegerValue: index

]

{ #category : #'plugin primitive support' }
StackInterpreter >> pluginStackObjectValue: index [
	"For plugin use only."
	shouldPopArgs := true.
	index > (argumentCount + 1) ifTrue:[
		self cCode: 'fprintf(stderr,"[VM]: Attempt to access method args beyond range\n")'.
		self printCallStack.
		self primitiveFail.
		^0].
	^self stackObjectValue: index

]

{ #category : #'plugin primitive support' }
StackInterpreter >> pluginStackValue: index [
	"For plugin use only."
	shouldPopArgs := true.
	index > (argumentCount + 1) ifTrue:[
		self cCode: 'fprintf(stderr,"[VM]: Attempt to access method args beyond range\n")'.
		self printCallStack.
		self primitiveFail.
		^0].
	^self stackValue: index

]

{ #category : #'internal interpreter access' }
StackInterpreter >> pop2AndPushIntegerIfOK: integerResult [

	self successful ifTrue:
		[(self isIntegerValue: integerResult)
			ifTrue: [self pop: 2 thenPush: (self integerObjectOf: integerResult)]
			ifFalse: [self success: false]]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pop: nItems [
	<inline: true>
	"In the StackInterpreter stacks grow down."
	stackPointer := stackPointer + (nItems*BytesPerWord).
	^nil
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pop: nItems thenPush: oop [
	"In the StackInterpreter stacks grow down."
	| sp |
	<inline: true>
	<var: #sp type: #'char *'>
	stackPages longAt: (sp := stackPointer + ((nItems - 1) * BytesPerWord)) put: oop.
	stackPointer := sp
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pop: nItems thenPushBool: trueOrFalse [
	"In the StackInterpreter stacks grow down."
	| sp |
	<inline: true>
	<var: #sp type: #'char *'>
	stackPages
		longAt: (sp := stackPointer + ((nItems - 1) * BytesPerWord))
		put: (trueOrFalse ifTrue: [trueObj] ifFalse: [falseObj]).
	stackPointer := sp
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pop: nItems thenPushFloat: f [
	"In the StackInterpreter stacks grow down."
	| sp |
	<inline: true>
	<var: #f type: #double>
	<var: #sp type: #'char *'>
	stackPages
		longAt: (sp := stackPointer + ((nItems - 1) * BytesPerWord))
		put: (self floatObjectOf: f).
	stackPointer := sp
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pop: nItems thenPushInteger: integerVal [
	"lots of places pop a few items off the stack and then push an integer. Make it convenient.
	 In the StackInterpreter stacks grow down."
	| sp |
	<var: #sp type: #'char *'>
	stackPages
		longAt: (sp := stackPointer + ((nItems - 1) * BytesPerWord))
		put: (self integerObjectOf: integerVal).
	stackPointer := sp
]

{ #category : #'stack bytecodes' }
StackInterpreter >> popFloat [
	"Note: May be called by translated primitive code."

	| top result |
	<returnTypeC: #double>
	<var: #result type: #double>
	top := self popStack.
	"N.B.  Because Slang always inlines assertClassOf:is:compactClassIndex:
	 (because assertClassOf:is:compactClassIndex: has an inline: pragma) the
	 phrase (self splObj: ClassArray) is expanded in-place and is _not_
	 evaluated if ClassArrayCompactIndex is non-zero."
	self assertClassOf: top
		is: (self splObj: ClassFloat)
		compactClassIndex: ClassFloatCompactIndex.
	self successful ifTrue:
		[self cCode: '' inSmalltalk: [result := Float new: 2].
		self fetchFloatAt: top + BaseHeaderSize into: result].
	^ result
]

{ #category : #'internal interpreter access' }
StackInterpreter >> popInteger [
"returns 0 if the stackTop was not an integer value, plus sets successFlag false"
	| integerPointer |
	integerPointer := self popStack.
	^self checkedIntegerValueOf: integerPointer
]

{ #category : #'internal interpreter access' }
StackInterpreter >> popPos32BitInteger [
	"May set successFlag, and return false if not valid"

	| top |
	top := self popStack.
	^ self positive32BitValueOf: top
]

{ #category : #'internal interpreter access' }
StackInterpreter >> popStack [
	"In the StackInterpreter stacks grow down."
	| top |
	<inline: true>
	top := stackPages longAt: stackPointer.
	stackPointer := stackPointer + BytesPerWord.
	^top
]

{ #category : #'stack bytecodes' }
StackInterpreter >> popStackBytecode [

	self fetchNextBytecode.
	self internalPop: 1.

]

{ #category : #'primitive support' }
StackInterpreter >> positive32BitIntegerFor: integerValue [

	| newLargeInteger |
	"Note - integerValue is interpreted as POSITIVE, eg, as the result of
		Bitmap>at:, or integer>bitAnd:."
	integerValue >= 0
		ifTrue: [(self isIntegerValue: integerValue)
					ifTrue: [^ self integerObjectOf: integerValue]].

	BytesPerWord = 4
	ifTrue: ["Faster instantiateSmallClass: currently only works with integral word size."
			newLargeInteger := self eeInstantiateSmallClass: (self splObj: ClassLargePositiveInteger)
					sizeInBytes: BaseHeaderSize + 4]
	ifFalse: ["Cant use instantiateSmallClass: due to integral word requirement."
			newLargeInteger := self eeInstantiateClass: (self splObj: ClassLargePositiveInteger)
					indexableSize: 4].
	self storeByte: 3 ofObject: newLargeInteger withValue: ((integerValue >> 24) bitAnd: 16rFF).
	self storeByte: 2 ofObject: newLargeInteger withValue: ((integerValue >> 16) bitAnd: 16rFF).
	self storeByte: 1 ofObject: newLargeInteger withValue: ((integerValue >> 8) bitAnd: 16rFF).
	self storeByte: 0 ofObject: newLargeInteger withValue: (integerValue bitAnd: 16rFF).
	^newLargeInteger
]

{ #category : #'primitive support' }
StackInterpreter >> positive32BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive ST integer or a four-byte LargePositiveInteger."

	| value |
	(self isIntegerObject: oop) ifTrue:
		[value := self integerValueOf: oop.
		value < 0 ifTrue: [self primitiveFail. value := 0].
		^value].

	self assertClassOf: oop
		is: (self splObj: ClassLargePositiveInteger)
		compactClassIndex: ClassLargePositiveIntegerCompactIndex.
	self successful ifFalse:
		[^0].
	(self lengthOf: oop) = 4 ifFalse:
		[^self primitiveFail].
	^(self fetchByte: 0 ofObject: oop)
	+ ((self fetchByte: 1 ofObject: oop) <<  8)
	+ ((self fetchByte: 2 ofObject: oop) << 16)
	+ ((self fetchByte: 3 ofObject: oop) << 24)
]

{ #category : #'primitive support' }
StackInterpreter >> positive64BitIntegerFor: integerValue [

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
StackInterpreter >> positive64BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive ST integer or a eight-byte LargePositiveInteger."

	| sz szsqLong value  |
	<returnTypeC: #sqLong>
	<var: 'value' type: #sqLong>
	(self isIntegerObject: oop) ifTrue: [
		value := self integerValueOf: oop.
		value < 0 ifTrue: [^ self primitiveFail].
		^ value].

	self assertClassOf: oop is: (self splObj: ClassLargePositiveInteger).
	self successful ifFalse: [^ self primitiveFail].
	szsqLong := self sizeof: #sqLong asSymbol.
	sz := self lengthOf: oop.
	sz > szsqLong
		ifTrue: [^ self primitiveFail].
	value := 0.
	0 to: sz - 1 do: [:i |
		value := value + ((self cCoerce: (self fetchByte: i ofObject: oop) to: #sqLong) <<  (i*8))].
	^value
]

{ #category : #'object memory support' }
StackInterpreter >> postGCAction: fullGCFlag [
	"Shrink free memory and signal the gc semaphore"
	| freeSizeNow |

	freeSizeNow := self freeSize.
	(freeSizeNow > shrinkThreshold
	 and: [freeSizeNow > growHeadroom]) ifTrue:
		["Attempt to shrink memory after successfully reclaiming lots of memory"
		 self shrinkObjectMemory: freeSizeNow - growHeadroom].

	self signalSemaphoreWithIndex: gcSemaphoreIndex
]

{ #category : #'object memory support' }
StackInterpreter >> preGCAction: fullGCFlag [
	"Need to write back the frame pointers unless all pages are free (as in snapshot)"
	stackPage ~= 0 ifTrue:
		[self externalWriteBackHeadFramePointers]
]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveAdd [

	self pop2AndPushIntegerIfOK: (self stackIntegerValue: 1) + (self stackIntegerValue: 0)
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveAddLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| integerRcvr integerArg result oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'result' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).
	self successful ifFalse:[^nil].

	"Compute the preliminary result (which may overflow)"
	result := integerRcvr + integerArg.

	"Now check overflow conditions. First is whether rcvr and arg are of the same sign.
	If they are we need to check for overflow more carefully."
	(integerRcvr bitXor: integerArg) < 0 ifFalse:[
		"Second is whether rcvr and result are of the same sign. If not, we have an overflow."
		(integerRcvr bitXor: result) < 0 ifTrue:[self primitiveFail]].
			
	self successful ifFalse:[^nil].

	oopResult := self signed64BitIntegerFor: result.
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveAdoptInstance [
	"Primitive. Change the class of the argument to make it an instance of the receiver
	 given that the format of the receiver matches the format of the argument's class.
	 Fail if receiver or argument are SmallIntegers, or the receiver is an instance of a
	 compact class and the argument isn't, or when the argument's class is compact and
	 the receiver isn't, or when the format of the receiver is different from the format of
	 the argument's class, or when the arguments class is fixed and the receiver's size
	 differs from the size that an instance of the argument's class should have."
	| rcvr arg |

	arg := self stackObjectValue: 0.
	rcvr := self stackObjectValue: 1.

	self changeClassOf: arg to: rcvr.
	self successful ifTrue:
		[self pop: self methodArgumentCount].
	^nil
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveArctan [

	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self popFloat.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'atan(rcvr)' inSmalltalk: [rcvr arcTan])]
		ifFalse: [self unPop: 1]
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveArrayBecome [
	"We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors."

	| arg rcvr ec |
	arg := self stackTop.
	rcvr := self stackValue: 1.
	ec := self become: rcvr with: arg twoWay: true copyHash: true.
	ec = PrimNoErr
		ifTrue: [self pop: 1]
		ifFalse: [self primitiveFailFor: ec]
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveArrayBecomeOneWay [
	"We must flush the method cache here, to eliminate stale references
	to mutated classes and/or selectors."

	| arg rcvr ec |
	arg := self stackTop.
	rcvr := self stackValue: 1.
	ec := self become: rcvr with: arg twoWay: false copyHash: true.
	ec = PrimNoErr
		ifTrue: [self pop: 1]
		ifFalse: [self primitiveFailFor: ec]
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveArrayBecomeOneWayCopyHash [
	"Similar to primitiveArrayBecomeOneWay but accepts a third argument whether to copy
	the receiver's identity hash over the argument's identity hash."

	| copyHashFlag arg rcvr ec |
	copyHashFlag := self booleanValueOf: (self stackTop).
	arg := self stackValue: 1.
	rcvr := self stackValue: 2.
	ec := self become: rcvr with: arg twoWay: false copyHash: copyHashFlag.
	ec = PrimNoErr
		ifTrue: [self pop: 2]
		ifFalse: [self primitiveFailFor: ec]
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveAsFloat [
	| arg |
	arg := self popInteger.
	self successful
		ifTrue: [ self pushFloat: (self cCode: '((double) arg)' inSmalltalk: [arg asFloat]) ]
		ifFalse: [ self unPop: 1 ]
]

{ #category : #'indexing primitives' }
StackInterpreter >> primitiveAt [

	self commonAt: false.
]

{ #category : #'indexing primitives' }
StackInterpreter >> primitiveAtPut [

	self commonAtPut: false.
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveBeCursor [
	"Set the cursor to the given shape. The Mac only supports 16x16 pixel cursors. Cursor offsets are handled by Smalltalk."

	| cursorObj maskBitsIndex maskObj bitsObj extentX extentY depth offsetObj offsetX offsetY cursorBitsIndex ourCursor |

self flag: #Dan.  "This is disabled until we convert bitmaps appropriately"
BytesPerWord = 8 ifTrue: [self pop: argumentCount. ^nil].

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
		(argumentCount = 0 and: [depth = 32])
			ifTrue: [
				"Support arbitrary-sized 32 bit ARGB forms --bf 3/1/2007 23:51"
				self success: ((extentX > 0) and: [extentY > 0]).
				self success: ((offsetX >= (extentX * -1)) and: [offsetX <= 0]).
				self success: ((offsetY >= (extentY * -1)) and: [offsetY <= 0]).
				self success: ((self isWords: bitsObj) and: [(self lengthOf: bitsObj) = (extentX * extentY)]).
				cursorBitsIndex := bitsObj + BaseHeaderSize.
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
				cursorBitsIndex := bitsObj + BaseHeaderSize.
				self cCode: '' inSmalltalk:
					[ourCursor := Cursor
						extent: extentX @ extentY
						fromArray: ((1 to: 16) collect: [:i |
							((self fetchLong32: i-1 ofObject: bitsObj) >> (BytesPerWord*8 - 16)) bitAnd: 16rFFFF])
						offset: offsetX  @ offsetY]]].

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
StackInterpreter >> primitiveBeDisplay [
	"Record the system Display object in the specialObjectsTable."
	| rcvr |
	rcvr := self stackTop.
	self success: ((self isPointers: rcvr) and: [(self lengthOf: rcvr) >= 4]).
	self successful ifTrue: [self storePointer: TheDisplay ofObject: specialObjectsOop withValue: rcvr]
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveBeep [
"make the basic beep noise"
	self ioBeep.
]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveBitAnd [
	| integerReceiver integerArgument |
	integerArgument := self popPos32BitInteger.
	integerReceiver := self popPos32BitInteger.
	self successful
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitAnd: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveBitAndLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| integerRcvr integerArg oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self positive64BitValueOf: (self stackValue: 0).
	integerRcvr := self positive64BitValueOf: (self stackValue: 1).
	self successful ifFalse:[^nil].

	oopResult := self positive64BitIntegerFor: (integerRcvr bitAnd: integerArg).
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveBitOr [
	| integerReceiver integerArgument |
	integerArgument := self popPos32BitInteger.
	integerReceiver := self popPos32BitInteger.
	self successful
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitOr: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveBitOrLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| integerRcvr integerArg oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self positive64BitValueOf: (self stackValue: 0).
	integerRcvr := self positive64BitValueOf: (self stackValue: 1).
	self successful ifFalse:[^nil].

	oopResult := self positive64BitIntegerFor: (integerRcvr bitOr: integerArg).
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveBitShift [ 
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

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveBitShiftLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| shifted integerArg integerRcvr oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'shifted' type: 'sqLong'>

	integerArg := self stackIntegerValue: 0.
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	self successful ifTrue: [
		integerArg >= 0 ifTrue: [
			"Left shift -- must fail if we lose bits beyond 64"
			self success: integerArg < 64.
			shifted := integerRcvr << integerArg.
			self success: integerRcvr = (self cCode: 'shifted >> integerArg'
											inSmalltalk: [shifted >> integerArg]).
		] ifFalse: [
			"Right shift -- OK to lose bits"
			self success: integerArg > -64.
			shifted := self cCode: 'integerRcvr >> (0 - integerArg)' "right shift coerces to usqInt"
						inSmalltalk: [integerRcvr >> (0 - integerArg)]
		].
	].
	self successful ifFalse:[^nil].
	oopResult := self signed64BitIntegerFor: shifted.
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveBitXor [
	| integerReceiver integerArgument |
	integerArgument := self popPos32BitInteger.
	integerReceiver := self popPos32BitInteger.
	self successful
		ifTrue: [self push: (self positive32BitIntegerFor:
					(integerReceiver bitXor: integerArgument))]
		ifFalse: [self unPop: 2]
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveBitXorLargeIntegers [
	"Primitive logical operations for large integers in 64 bit range"
	| integerRcvr integerArg oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self positive64BitValueOf: (self stackValue: 0).
	integerRcvr := self positive64BitValueOf: (self stackValue: 1).
	self successful ifFalse:[^nil].

	oopResult := self positive64BitIntegerFor: (integerRcvr bitXor: integerArg).
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'memory space primitives' }
StackInterpreter >> primitiveBytesLeft [
	"Reports bytes available at this moment. For more meaningful 
	results, calls to this primitive should be preceeded by a full 
	or incremental garbage collection."
	| aBool |
	self methodArgumentCount = 0
		ifTrue: ["old behavior - just return the size of free memory"
			^self pop: 1 thenPushInteger: self freeSize].
	self methodArgumentCount = 1
		ifTrue: ["new behaviour -including or excluding swap space depending on aBool"
			aBool := self booleanValueOf: self stackTop.
			self successful ifTrue:
				[^self pop: 2 thenPushInteger: (self bytesLeft: aBool)]].
	^ self primitiveFail
]

{ #category : #'plugin primitives' }
StackInterpreter >> primitiveCalloutToFFI [
	"Perform a function call to a foreign function.
	Only invoked from method containing explicit external call spec.
	Due to this we use the pluggable prim mechanism explicitly here
	(the first literal of any FFI spec'ed method is an ExternalFunction
	and not an array as used in the pluggable primitive mechanism)."

	| primitiveCallout |
	<var: #primitiveCallout declareC: 'void (*primitiveCallout)(void)'>
	primitiveCallout := self functionForPrimitiveCallout.
	primitiveCallout isNil
		ifTrue: [self primitiveFail]
		ifFalse: [self perform: primitiveCallout]
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveChangeClass [
	"Primitive. Change the class of the receiver into the class of the argument given that the format of the receiver matches the format of the argument's class. Fail if receiver or argument are SmallIntegers, or the receiver is an instance of a compact class and the argument isn't, or when the argument's class is compact and the receiver isn't, or when the format of the receiver is different from the format of the argument's class, or when the arguments class is fixed and the receiver's size differs from the size that an instance of the argument's class should have."
	| arg rcvr argClass classHdr sizeHiBits byteSize argFormat rcvrFormat ccIndex |
	arg := self stackObjectValue: 0.
	rcvr := self stackObjectValue: 1.
	self successful ifFalse:[^nil].

	"Get the class we want to convert the receiver into"
	argClass := self fetchClassOf: arg.

	"Check what the format of the class says"
	classHdr := self formatOfClass: argClass. "Low 2 bits are 0"

	"Compute the size of instances of the class (used for fixed field classes only)"
	sizeHiBits := (classHdr bitAnd: 16r60000) >> 9.
	classHdr := classHdr bitAnd: 16r1FFFF.
	byteSize := (classHdr bitAnd: SizeMask) + sizeHiBits. "size in bytes -- low 2 bits are 0"

	"Check the receiver's format against that of the class"
	argFormat := self formatOfHeader: classHdr.
	rcvrFormat := self formatOf: rcvr.
	argFormat = rcvrFormat ifFalse:[^self primitiveFail]. "no way"

	"For fixed field classes, the sizes must match.
	Note: byteSize-4 because base header is included in class size."
	argFormat < 2
		ifTrue:
			[(byteSize - BaseHeaderSize) ~= (self byteSizeOf: rcvr) ifTrue:
				[^self primitiveFailFor: PrimErrBadReceiver]]
		ifFalse:
			[argFormat = 3 ifTrue: "For indexable plus fixed fields the receiver must be at least big enough."
				[(byteSize - BaseHeaderSize) > (self byteSizeOf: rcvr) ifTrue:
					[^self primitiveFailFor: PrimErrBadReceiver]]].

	(self headerType: rcvr) = HeaderTypeShort
		ifTrue:[ "Compact classes. Check if the arg's class is compact and exchange ccIndex"
			ccIndex := classHdr bitAnd: CompactClassMask.
			ccIndex = 0 ifTrue:[^self primitiveFail]. "class is not compact"
			self longAt: rcvr put:
				(((self longAt: rcvr) bitAnd: CompactClassMask bitInvert32)
					bitOr: ccIndex)]
		ifFalse:["Exchange the class pointer, which could make rcvr a root for argClass"
			self longAt: rcvr-BaseHeaderSize put: (argClass bitOr: (self headerType: rcvr)).
			(rcvr < youngStart) ifTrue: [self possibleRootStoreInto: rcvr value: argClass]].

	"Flush at cache because rcvr's class has changed"
	self flushAtCache.

	self successful ifTrue: [ self pop: 1 ]
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveClass [
	| instance |
	instance := self stackTop.
	self pop: argumentCount+1 thenPush: (self fetchClassOf: instance)
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveClearVMProfile [
	"Primitive. Void the VM profile histograms."
	self cCode: 'ioClearProfile()'.
	self pop: argumentCount
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveClipboardText [
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
			s := self instantiateClass: (self splObj: ClassString) indexableSize: sz.
			self clipboardRead: sz Into: s + BaseHeaderSize At: 0.
			self pop: 1 thenPush: s]
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveClockLogAddresses [
	"Take a boolean which if true turns or keeps clock logging on.  Answer an array supplying
	 the size of the clock logs, the address of the usecs log, the index in it, the address of the
	 msecs log, and the index into it."
	<export: true>
	| result runInNOut usecs uidx msecs midx v1 v2 |
	<var: #usecs type: #'void *'>
	<var: #msecs type: #'void *'>
	argumentCount ~= 1 ifTrue:
		[^self primitiveFail].
	runInNOut := (self stackValue: 0) == trueObj.
	self ioGetClockLogSize: (self addressOf: runInNOut)
		Usecs: (self addressOf: usecs) Idx: (self addressOf: uidx)
		Msecs: (self addressOf: msecs) Idx: (self addressOf: midx).
	result := self instantiateClass: (self splObj: ClassArray) indexableSize: 5.
	result = 0 ifTrue:
		[^self primitiveFail].
	self pushRemappableOop: result.
	self storePointerUnchecked: 0 ofObject: self topRemappableOop withValue: (self integerObjectOf: runInNOut).
	v1 := self positive32BitIntegerFor: usecs.
	v2 := self positive32BitIntegerFor: msecs.
	self successful ifFalse:
		[self popRemappableOop.
		 ^self primitiveFail].
	self storePointer: 1 ofObject: self topRemappableOop withValue: v1.
	self storePointerUnchecked: 2 ofObject: self topRemappableOop withValue: (self integerObjectOf: uidx).
	self storePointer: 3 ofObject: self topRemappableOop withValue: v2.
	self storePointerUnchecked: 4 ofObject: self topRemappableOop withValue: (self integerObjectOf: midx).
	self pop: 2 thenPush: self popRemappableOop

]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveClone [
	"Return a shallow copy of the receiver."

	| newCopy |
	newCopy := self clone: (self stackTop).
	newCopy = 0
		ifTrue:["not enough memory most likely" ^self primitiveFail].
	self pop: 1 thenPush: newCopy.
]

{ #category : #'control primitives' }
StackInterpreter >> primitiveClosureCopyWithCopiedValues [
	| newClosure numArgs |
	numArgs := self stackIntegerValue: 1.
	self successful ifFalse:
		[^self primitiveFail].

	newClosure := self
					closureIn: (self stackValue: 2)
					numArgs: numArgs
							"greater by 1 due to preIncrement of localIP"
					instructionPointer: instructionPointer + 2 - (method+BaseHeaderSize)
					copiedValues: self stackTop.
	self pop: 3 thenPush: newClosure
]

{ #category : #'control primitives' }
StackInterpreter >> primitiveClosureValue [
	| blockClosure numArgs closureMethod outerContext |
	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	argumentCount = numArgs ifFalse:
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

	"Note we use activateNewMethod, not executeNewMethodFromCache, to
	 avoid quickCheckForInterrupts.  Don't check until we have a full activation."
	self activateNewClosureMethod: blockClosure numArgs: numArgs mayContextSwitch: true
]

{ #category : #'control primitives' }
StackInterpreter >> primitiveClosureValueNoContextSwitch [
	"An exact clone of primitiveClosureValue except that this version will not
	 check for interrupts on stack overflow.  It may invoke the garbage collector
	 but will not switch processes.  See checkForInterruptsMayContextSwitch:"
	| blockClosure numArgs closureMethod outerContext |
	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	argumentCount = numArgs ifFalse:
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

	"Note we use activateNewMethod, not executeNewMethodFromCache, to
	 avoid quickCheckForInterrupts.  Don't check until we have a full activation."
	self activateNewClosureMethod: blockClosure numArgs: numArgs mayContextSwitch: false
]

{ #category : #'control primitives' }
StackInterpreter >> primitiveClosureValueWithArgs [
	| argumentArray arraySize blockClosure numArgs closureMethod index outerContext |
	argumentArray := self stackTop.
	(self isArray: argumentArray) ifFalse:
		[^self primitiveFail].

	"Check for enough space in thisContext to push all args"
	arraySize := self fetchWordLengthOf: argumentArray.
	(self roomToPushNArgs: arraySize) ifFalse:
		[^self primitiveFail].

	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	arraySize = numArgs ifFalse:
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
	[index <= numArgs]
		whileTrue:
		[self push: (self fetchPointer: index - 1 ofObject: argumentArray).
		index := index + 1].

	"Note we use activateNewMethod, not executeNewMethodFromCache, to
	 avoid quickCheckForInterrupts.  Don't check until we have a full activation."
	self activateNewClosureMethod: blockClosure numArgs: numArgs mayContextSwitch: true
]

{ #category : #'indexing primitives' }
StackInterpreter >> primitiveCompareBytes [
	"Primitive. Compare two byte-indexed objects for equality"
	| arg1 arg2 len1 len2 |
	<export: true>
	argumentCount = 1 ifFalse:[^self primitiveFail].
	arg1 := self stackValue: 1.
	arg2 := self stackValue: 0.
	((self isBytes: arg1) and:[self isBytes: arg2]) 
		ifFalse:[^self primitiveFail].
	"Quick identity test"
	(arg1 = arg2) ifTrue:[^self pop: 2 thenPush: trueObj].
	len1 := self byteSizeOf: arg1.
	len2 := self byteSizeOf: arg2.
	len1 = len2 ifFalse:[^self pop: 2 thenPush: falseObj].
	0 to: len1-1 do:[:i|
		(self fetchByte: i ofObject: arg1) = (self fetchByte: i ofObject: arg2) 
			ifFalse:[^self pop: 2 thenPush: falseObj]].
	self pop: 2 thenPush: trueObj.

]

{ #category : #'sound primitives' }
StackInterpreter >> primitiveConstantFill [
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

{ #category : #'indexing primitives' }
StackInterpreter >> primitiveContextAt [
	| index value aContext spouseFP hdr fmt totalLength fixedFields stSize |
	<var: #spouseFP type: #'char *'>
	index := self stackTop.
	(self isIntegerObject: index) ifFalse:
		[^self primitiveFail].
	index := self integerValueOf: index.
	aContext := self stackValue: 1.
	"Duplicating much of stObject:at:put: here allows stObject:at:put: to omit tests for contexts."
	hdr := self baseHeader: aContext.
	(self isContextHeader: hdr) ifFalse: "might be an instance of a subclass"
		[value := self stObject: aContext at: index.
		 ^self pop: 2 thenPush: value].
	self externalWriteBackHeadFramePointers.
	(self isStillMarriedContext: aContext) ifFalse:
		[fmt := self formatOfHeader: hdr.
		 totalLength := self lengthOf: aContext baseHeader: hdr format: fmt.
		 fixedFields := self fixedFieldsOf: aContext format: fmt length: totalLength.
		 stSize := self stackPointerForMaybeMarriedContext: aContext.
		 (index between: 1 and: stSize) ifFalse:
			[^self primitiveFail].			
		value := self subscript: aContext with: (index + fixedFields) format: fmt.
		^self pop: 2 thenPush: value].
	spouseFP := self frameOfMarriedContext: aContext.
	(index between: 1 and: (self stackPointerIndexForFrame: spouseFP)) ifFalse:
		[^self primitiveFail].
	value := self temporary: index - 1 in: spouseFP.
	self pop: 2 thenPush: value
]

{ #category : #'indexing primitives' }
StackInterpreter >> primitiveContextAtPut [
	| index value aContext spouseFP hdr fmt totalLength fixedFields stSize |
	<var: #spouseFP type: #'char *'>
	value := self stackTop.
	index := self stackValue: 1.
	aContext := self stackValue: 2.
	(self isIntegerObject: index) ifFalse:
		[^self primitiveFail].
	"Duplicating much of stObject:at:put: here allows stObject:at:put: to omit tests for contexts."
	hdr := self baseHeader: aContext.
	index := self integerValueOf: index.
	(self isContextHeader: hdr) ifFalse: "might be an instance of a subclass"
		[self stObject: aContext at: index put: value.
		 ^self pop: 3 thenPush: value].
	self externalWriteBackHeadFramePointers.
	(self isStillMarriedContext: aContext) ifFalse:
		[fmt := self formatOfHeader: hdr.
		 totalLength := self lengthOf: aContext baseHeader: hdr format: fmt.
		 fixedFields := self fixedFieldsOf: aContext format: fmt length: totalLength.
		 stSize := self stackPointerForMaybeMarriedContext: aContext.
		 (index between: 1 and: stSize) ifFalse:
			[^self primitiveFail].			
		self subscript: aContext with: (index + fixedFields) storing: value format: fmt.
		^self pop: 3 thenPush: value].
	spouseFP := self frameOfMarriedContext: aContext.
	(index between: 1 and: (self stackPointerIndexForFrame: spouseFP)) ifFalse:
		[^self primitiveFail].
	self temporary: index - 1 in: spouseFP put: value.
	^self pop: 3 thenPush: value
]

{ #category : #'indexing primitives' }
StackInterpreter >> primitiveContextSize [
	| rcvr sz hdr fmt totalLength fixedFields |
	rcvr := self stackTop.
	hdr := self baseHeader: rcvr.
	fmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: rcvr format: fmt length: totalLength.
	(self isContextHeader: hdr)
		ifTrue:
			[self externalWriteBackHeadFramePointers.
			sz := self stackPointerForMaybeMarriedContext: rcvr]
		ifFalse: [sz := totalLength - fixedFields].
	self successful ifTrue:
		[self pop: 1 thenPush: (self integerObjectOf: sz)]
]

{ #category : #'indexing primitives' }
StackInterpreter >> primitiveContextXray [
	"Lift the veil from a context and answer an integer describing its interior state.
	 Used for e.g. VM tests so they can verify they're testing what they think they're testing.
	 0 implies a vanilla heap context.
	 Bit 0 = is or was married to a frame
	 Bit 1 = is still married to a frame
	 Bit 2 = frame is executing machine code
	 Bit 3 = has machine code pc (as opposed to nil or a bytecode pc)
	 Bit 4 = method is currently compiled to machine code"
	| context flags |
	context := self stackTop.
	(self isMarriedOrWidowedContext: context)
		ifTrue:
			[(self checkIsStillMarriedContext: context currentFP: framePointer)
				ifTrue: [flags := 3]
				ifFalse: [flags := 1]]
		ifFalse:
			[flags := 0].
	self pop: 1 thenPush: (self integerObjectOf: flags)
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveControlVMProfiling [
	"Primitive. Start or stop the VM profiler.  The first argument is a boolean
	 to switch profiling on or off.  The second argument is an integer or nil.
	 If an integer it determines the maximum number of samples in the VM's
	 sample buffer. Answer the current number of samples in the buffer."
	| onOffBar bufferSize numSamples |
	argumentCount ~= 2 ifTrue:
		[^self primitiveFail].
	(onOffBar := self stackValue: 1) = trueObj
		ifTrue: [onOffBar := 1]
		ifFalse:
			[onOffBar = falseObj
				ifTrue: [onOffBar := 0]
				ifFalse: [^self primitiveFail]].
	(bufferSize := self stackTop) = nilObj
		ifTrue: [bufferSize := 0]
		ifFalse:
			[((self isIntegerObject: bufferSize)
			  and: [(bufferSize := self integerValueOf: bufferSize) > 0]) ifFalse:
				[^self primitiveFail]].
	numSamples := self cCode: 'ioControlNewProfile(onOffBar,bufferSize)'.
	self pop: 3 thenPushInteger: numSamples
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveCopyObject [
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

{ #category : #'system control primitives' }
StackInterpreter >> primitiveCrashVM [
	"Crash the VM by indirecting through a null pointer.  If the sole argument
	 is true crash in this thread, and if it is false crash in a new thread."
	| crashInThisThread |
	<export: true>
	crashInThisThread := self booleanValueOf: self stackTop.
	(self failed
	 or: [argumentCount ~= 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	self crashInThisOrAnotherThread: crashInThisThread.
	self pop: 1
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveDeferDisplayUpdates [
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
StackInterpreter >> primitiveDisablePowerManager [
	"Pass in a non-negative value to disable the architectures powermanager if any, zero to enable. This is a named (not numbered) primitive in the null module (ie the VM)"

	| integer |
	<export: true>
	integer := self stackIntegerValue: 0.
	self successful ifTrue: [
		self ioDisablePowerManager: integer.
		self pop: 1].  "integer; leave rcvr on stack"
]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveDiv [
	| quotient |
	quotient := self doPrimitiveDiv: (self stackValue: 1) by: (self stackTop).
	self pop2AndPushIntegerIfOK: quotient
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveDivLargeIntegers [
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
	self successful ifFalse:[^nil].

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
	self successful ifTrue:[oopResult := self signed64BitIntegerFor: result].
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveDivide [
	| integerReceiver integerArgument |
	integerReceiver := self stackIntegerValue: 1.
	integerArgument := self stackIntegerValue: 0.
	(integerArgument ~= 0 and: [integerReceiver \\ integerArgument = 0])
		ifTrue: [self pop2AndPushIntegerIfOK: integerReceiver // integerArgument]
		ifFalse: [self primitiveFail]
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveDivideLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| integerRcvr integerArg result oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'result' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).
	(integerArg ~= 0 and:[integerRcvr \\ integerArg = 0]) ifFalse:[self primitiveFail].
	self successful ifFalse:[^nil].
	result := integerRcvr // integerArg.
	oopResult := self signed64BitIntegerFor: result.
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'plugin primitives' }
StackInterpreter >> primitiveDoNamedPrimitiveWithArgs [
	"Simulate an primitiveExternalCall invocation (e.g. for the Debugger).  Do not cache anything.
	 e.g. ContextPart>>tryNamedPrimitiveIn: aCompiledMethod for: aReceiver withArgs: arguments"
	| argumentArray arraySize methodArg methodHeader
	  moduleName functionName moduleLength functionLength
	  spec addr primRcvr ctxtRcvr |
	<var: #addr declareC: 'void (*addr)()'>
	argumentArray := self stackTop.
	(self isArray: argumentArray) ifFalse:
		[^self primitiveFailFor: -2]. "invalid args"
	arraySize := self fetchWordLengthOf: argumentArray.
	self success: (self roomToPushNArgs: arraySize).

	methodArg := self stackObjectValue: 2.
	self successful ifFalse:
		[^self primitiveFailFor: -2]. "invalid args"

	(self isCompiledMethod: methodArg) ifFalse:
		[^self primitiveFailFor: -2]. "invalid args"

	methodHeader := self headerOf: methodArg.

	(self literalCountOfHeader: methodHeader) > 2 ifFalse:
		[^self primitiveFailFor: -3]. "invalid methodArg state"
	(self assertClassOf: (spec := self fetchPointer: 1 "first literal" ofObject: methodArg)
		is: (self splObj: ClassArray) 
		compactClassIndex: ClassArrayCompactIndex).
	(self successful
	and: [(self lengthOf: spec) = 4
	and: [(self primitiveIndexOfMethodHeader: methodHeader) = 117]]) ifFalse:
		[^self primitiveFailFor: -3]. "invalid methodArg state"

	(self argumentCountOfMethodHeader: methodHeader) = arraySize ifFalse:
		[^self primitiveFailFor: -2]. "invalid args (Array args wrong size)"

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
	self successful ifFalse: [^self primitiveFailFor: -3]. "invalid methodArg state"

	addr := self ioLoadExternalFunction: functionName + BaseHeaderSize
				OfLength: functionLength
				FromModule: moduleName + BaseHeaderSize
				OfLength: moduleLength.
	addr = 0 ifTrue:
		[^self primitiveFailFor: -4]. "could not find function"

	"Cannot fail this primitive from now on.  Can only fail the external primitive."
	self pushRemappableOop: (argumentArray := self popStack).
	self pushRemappableOop: (primRcvr := self popStack).
	self pushRemappableOop: self popStack. "the method"
	self pushRemappableOop: self popStack. "the context receiver"
	self push: primRcvr. "replace context receiver with actual receiver"
	argumentCount := arraySize.
	1 to: arraySize do:
		[:index| self push: (self fetchPointer: index - 1 ofObject: argumentArray)].
	"Run the primitive (sets primFailCode)"
	lkupClass := nilObj.
	self callExternalPrimitive: addr.
	ctxtRcvr  := self popRemappableOop.
	methodArg := self popRemappableOop.
	primRcvr := self popRemappableOop.
	argumentArray := self popRemappableOop.
	self successful ifFalse: "If primitive failed, then restore state for failure code"
		[self pop: arraySize + 1.
		 self push: ctxtRcvr.
		 self push: methodArg.
		 self push: primRcvr.
		 self push: argumentArray.
		 argumentCount := 3.
		 "Hack.  A nil prim error code (primErrorCode = 1) is interpreted by the image
		  as meaning this primitive is not implemented.  So to pass back nil as an error
		  code we use -1 to indicate generic failure."
		 primFailCode = 1 ifTrue:
			[primFailCode := -1]]
]

{ #category : #'control primitives' }
StackInterpreter >> primitiveDoPrimitiveWithArgs [
	| argumentArray arraySize index primIdx |
	argumentArray := self stackTop.
	(self isArray: argumentArray) ifFalse: [^self primitiveFail].
	arraySize := self fetchWordLengthOf: argumentArray.
	self success: (self roomToPushNArgs: arraySize).

	primIdx := self stackIntegerValue: 1.
	self successful ifFalse: [^self primitiveFail]. "invalid args"

	"Pop primIndex and argArray, then push args in place..."
	self pop: 2.
	primitiveFunctionPointer := self functionPointerFor: primIdx inClass: nil.
	argumentCount := arraySize.
	index := 1.
	[index <= argumentCount] whileTrue:
		[self push: (self fetchPointer: index - 1 ofObject: argumentArray).
		 index := index + 1].

	self isPrimitiveFunctionPointerAnIndex ifTrue:
		[self externalQuickPrimitiveResponse.
		^nil].
	"Run the primitive (sets primFailCode)"
	self pushRemappableOop: argumentArray. "prim might alloc/gc"
	lkupClass := nilObj.
	self slowPrimitiveResponse.
	argumentArray := self popRemappableOop.
	self successful ifFalse: "If primitive failed, then restore state for failure code"
		[self pop: arraySize.
		 self pushInteger: primIdx.
		 self push: argumentArray.
		 argumentCount := 2]
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveEnterCriticalSection [
	"Attempt to enter a CriticalSection/Mutex.  If not owned, set the owner to the current
	 process and answer false. If owned by the current process  answer true.   Otherwise
	 suspend the process.  Answer if the receiver is owned by the current process."
	| criticalSection owningProcessIndex owningProcess activeProc |
	criticalSection := self stackTop.  "rcvr"
	owningProcessIndex := ExcessSignalsIndex. "CriticalSections are laid out like Semaphores"
	owningProcess := self fetchPointer: owningProcessIndex ofObject: criticalSection.
	activeProc := self activeProcess.
	owningProcess = nilObj ifTrue:
		[self storePointer: owningProcessIndex
			ofObject: criticalSection
			withValue: activeProc.
		 ^self pop: 1 thenPush: falseObj].
	owningProcess = activeProc ifTrue:
		[^self pop: 1 thenPush: trueObj].
	"Arrange to answer false (unowned) when the process is resumed."
	self pop: 1 thenPush: falseObj.
	self addLastLink: activeProc toList: criticalSection.
	self transferTo: self wakeHighestPriority
]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveEqual [
	| integerReceiver integerArgument result |
	integerArgument := self popStack.
	integerReceiver := self popStack.
	result := self compare31or32Bits: integerReceiver equal: integerArgument.
	self checkBooleanResult: result
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveEqualLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	self successful ifTrue:
		[self pop: 2 thenPushBool: integerRcvr = integerArg]
]

{ #category : #'control primitives' }
StackInterpreter >> primitiveExecuteMethod [
	"receiver, args, then method are on top of stack. Execute method against receiver and args.
	 Set primitiveFunctionPointer because no cache lookup has been done for the method, and
	 hence primitiveFunctionPointer is stale."
	| methodArgument primitiveIndex |
	methodArgument := self stackTop.
	((self isNonIntegerObject: methodArgument)
	 and: [self isCompiledMethod: methodArgument]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	argumentCount - 1 = (self argumentCountOf: methodArgument) ifFalse:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	newMethod := self popStack.
	primitiveIndex := self primitiveIndexOf: newMethod.
	primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: nil.
	argumentCount := argumentCount - 1.
	self executeNewMethod.
	"Recursive xeq affects primErrorCode"
	self initPrimCall
]

{ #category : #'control primitives' }
StackInterpreter >> primitiveExecuteMethodArgsArray [
	"receiver, argsArray, then method are on top of stack.  Execute method against receiver and args.
	 Set primitiveFunctionPointer because no cache lookup has been done for the method, and
	 hence primitiveFunctionPointer is stale."
	| methodArgument argCnt argumentArray primitiveIndex |
	methodArgument := self stackTop.
	argumentArray := self stackValue: 1.
	((self isNonIntegerObject: methodArgument)
	 and: [(self isCompiledMethod: methodArgument)
	 and: [self isArray: argumentArray]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	argCnt := self argumentCountOf: methodArgument.
	argCnt = (self fetchWordLengthOf: argumentArray) ifFalse:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	self pop: 2.
	0 to: argCnt - 1 do:
		[:i|
		self push: (self fetchPointer: i ofObject: argumentArray)].
	newMethod := methodArgument.
	primitiveIndex := self primitiveIndexOf: newMethod.
	primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: nil.
	argumentCount := argCnt.
	self executeNewMethod.
	"Recursive xeq affects primErrorCode"
	self initPrimCall
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveExitCriticalSection [
	"Exit the critical section.
	 This may change the active process as a result."
	| criticalSection owningProcessIndex owningProcess |
	criticalSection := self stackTop.  "rcvr"
	owningProcessIndex := ExcessSignalsIndex. "CriticalSections are laid out like Semaphores"
	(self isEmptyList: criticalSection)
		ifTrue:
			[self storePointerUnchecked: owningProcessIndex
				ofObject: criticalSection
				withValue: nilObj]
		ifFalse:
			[owningProcess := self removeFirstLinkOfList: criticalSection.
			 "store check unnecessary because aSemaphore referred to owningProcess
			  via its FirstLinkIndex slot before owningProcess was removed."
			 self storePointerUnchecked: owningProcessIndex
				ofObject: criticalSection
				withValue: owningProcess.
			 "Note that resume: isn't fair; it won't suspend the active process.
			  For fairness we must do the equivalent of a primitiveYield, but that
			  may break old code, so we stick with unfair resume:."
			self resume: owningProcess preemptedYieldingIf: preemptionYields]
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveExitToDebugger [

	self error: 'Exit to debugger at user request'.
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveExp [
	"Computes E raised to the receiver power."

	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self popFloat.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'exp(rcvr)' inSmalltalk: [rcvr exp])]
		ifFalse: [self unPop: 1]
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveExponent [
	"Exponent part of this float."

	| rcvr frac pwr |
	<var: #rcvr type: #double>
	<var: #frac type: #double>
	<var: #pwr type: #int>
	rcvr := self popFloat.
	self successful
		ifTrue: [  "rcvr = frac * 2^pwr, where frac is in [0.5..1.0)"
			self cCode: 'frac = frexp(rcvr, &pwr)'
					inSmalltalk: [pwr := rcvr exponent].
			self pushInteger: pwr - 1]
		ifFalse: [self unPop: 1]
]

{ #category : #'plugin primitives' }
StackInterpreter >> primitiveExternalCall [
	"Call an external primitive. External primitive methods first literals are an array of
		* The module name (String | Symbol) 
		* The function name (String | Symbol) 
		* The session ID (SmallInteger) [OBSOLETE] 
		* The function index (Integer) in the externalPrimitiveTable
	For fast interpreter dispatch in subsequent invocations the primitiveFunctionPointer
	in the method cache is rewritten, either to the function itself, or to zero if the external
	function is not found.   This allows for fast responses as long as the method stays in
	the cache. The cache rewrite relies on lastMethodCacheProbeWrite which is set in
	addNewMethodToCache:. 
	Now that the VM flushes function addresses from its tables, the session ID is obsolete,
	but it is kept for backward compatibility. Also, a failed lookup is reported specially. If a
	method has been  looked up and not been found, the function address is stored as -1
	(i.e., the SmallInteger -1 to distinguish from 16rFFFFFFFF which may be returned from
	lookup), and the primitive fails with PrimErrNotFound."
	| lit addr moduleName functionName moduleLength functionLength index |
	<var: #addr declareC: 'void (*addr)()'>
	
	"Fetch the first literal of the method"
	(self literalCountOf: newMethod) > 0 ifFalse:
		[^self primitiveFailFor: PrimErrBadMethod].

	lit := self literal: 0 ofMethod: newMethod. 
	"Check if it's an array of length 4"
	((self isArray: lit) and: [(self lengthOf: lit) = 4]) ifFalse:
		[^self primitiveFailFor: PrimErrBadMethod].

	"Look at the function index in case it has been loaded before"
	index := self fetchPointer: 3 ofObject: lit.
	(self isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadMethod].
	index := self integerValueOf: index.
	"Check if we have already looked up the function and failed."
	index < 0 ifTrue:
		["Function address was not found in this session, 
		  Void the primitive function."
		 self rewriteMethodCacheEntryForExternalPrimitiveToFunction: 0.
		 ^self primitiveFailFor: PrimErrNotFound].

	"Try to call the function directly"
	(index > 0 and: [index <= MaxExternalPrimitiveTableSize]) ifTrue:
		[addr := externalPrimitiveTable at: index - 1.
		 addr ~= 0 ifTrue:
			[self rewriteMethodCacheEntryForExternalPrimitiveToFunction: (self cCode: 'addr' inSmalltalk: [1000 + index]).
			 self callExternalPrimitive: addr.
			 ^nil].
		"if we get here, then an index to the external prim was 
		kept on the ST side although the underlying prim 
		table was already flushed"
		^self primitiveFailFor: PrimErrNamedInternal].

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
	(self isBytes: functionName) ifFalse:
		[self primitiveFailFor: PrimErrBadMethod].
	functionLength := self lengthOf: functionName.

	addr := self ioLoadExternalFunction: functionName + BaseHeaderSize
				OfLength: functionLength
				FromModule: moduleName + BaseHeaderSize
				OfLength: moduleLength.
	addr = 0
		ifTrue: [index := -1]
		ifFalse: ["add the function to the external primitive table"
			index := self addToExternalPrimitiveTable: addr].

	"Store the index (or -1 if failure) back in the literal"
	self storePointerUnchecked: 3 ofObject: lit withValue: (self integerObjectOf: index).

	"If the function has been successfully loaded cache and call it"
	index >= 0
		ifTrue:
			[self rewriteMethodCacheEntryForExternalPrimitiveToFunction: (self cCode: 'addr' inSmalltalk: [1000 + index]).
			self callExternalPrimitive: addr]
		ifFalse: ["Otherwise void the primitive function and fail"
			self rewriteMethodCacheEntryForExternalPrimitiveToFunction: 0.
			^self primitiveFailFor: PrimErrNotFound]
]

{ #category : #'primitive support' }
StackInterpreter >> primitiveFail [
	"Set general (unspecified) primitive failure.  Don't overwrite an error code that has already been set."

	"Use returnTypeC: #sqInt because that's the way it is defined in sq.h.
	 Use no explicit return so that Slang doesn't fail an inlin ingtype-check when
	 a primitive with return type void uses ^self primitiveFail to exit."
	<returnTypeC: #sqInt>
	primFailCode == 0 ifTrue:
		[primFailCode := 1]
]

{ #category : #'image segment in/out' }
StackInterpreter >> primitiveFailAfterCleanup: outPointerArray [
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
StackInterpreter >> primitiveFailFor: reasonCode [
	"Set specific primitive failure.
	 N.B. primitiveFailFor: PrimNoErr is expected to clear the primFailCode."
	<api>
	^primFailCode := reasonCode
]

{ #category : #'control primitives' }
StackInterpreter >> primitiveFindHandlerContext [
	"Primitive. Search up the context stack for the next method context marked
	 for exception handling starting at the receiver. Return nil if none found"
	| handlerOrNilOrZero |
	self externalWriteBackHeadFramePointers.
	handlerOrNilOrZero := self
							findMethodWithPrimitive: 199
							FromContext: self stackTop
							UpToContext: nilObj.
	handlerOrNilOrZero = 0 ifTrue:
		[handlerOrNilOrZero := nilObj].
	self pop: 1 thenPush: handlerOrNilOrZero
]

{ #category : #'control primitives' }
StackInterpreter >> primitiveFindNextUnwindContext [
	"Primitive. Search up the context stack for the next method context marked for unwind
	 handling from the receiver up to but not including the argument. Return nil if none found."
	| stopContext calleeContext handlerOrNilOrZero |
	<var: #theFP type: #'char *'>
	stopContext := self stackTop.
	calleeContext := self stackValue: 1.
	(stopContext = nilObj or: [self isContext: stopContext]) ifFalse:
		[^self primitiveFail].
	self externalWriteBackHeadFramePointers.
	(self isStillMarriedContext: calleeContext)
		ifTrue:
			[| theFP |
			 theFP := self frameOfMarriedContext: calleeContext.
			 (self isBaseFrame: theFP)
				ifTrue:
					[handlerOrNilOrZero := self findMethodWithPrimitive: 198
												FromContext: (self frameCallerContext: theFP)
												UpToContext: stopContext]
				ifFalse:
					[handlerOrNilOrZero :=  self findMethodWithPrimitive: 198
												FromFP: (self frameCallerFP: theFP)
												UpToContext: stopContext]]
		ifFalse:
			[| startContext |
			 startContext := self fetchPointer: SenderIndex ofObject: calleeContext.
			 (self isContext: startContext)
				ifTrue:
					[handlerOrNilOrZero := self findMethodWithPrimitive: 198
												FromContext: startContext
												UpToContext: stopContext]
				ifFalse:
					[handlerOrNilOrZero := 0]].
	handlerOrNilOrZero = 0 ifTrue:
		[handlerOrNilOrZero := nilObj].
	self pop: 2 thenPush: handlerOrNilOrZero
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatAdd [
	^ self primitiveFloatAdd: (self stackValue: 1) toArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatAdd: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	self successful ifTrue:
		[self pop: 2 thenPushFloat: rcvr + arg]
]

{ #category : #'indexing primitives' }
StackInterpreter >> primitiveFloatAt [
	"Provide platform-independent access to 32-bit words comprising
	 a Float.  Map index 1 onto the most significant word and index 2
	 onto the least significant word."
	| rcvr index result |
	<var: #result type: #usqInt>
	self initPrimCall.
	rcvr := self stackValue: 1.
	index := self stackTop.
	index = ConstOne ifTrue:
		[result := self positive32BitIntegerFor:
					(self fetchLong32: (VMBIGENDIAN ifTrue: [0] ifFalse: [1])
						ofObject: rcvr).
		^self pop: 2 thenPush: result].
	index = ConstTwo ifTrue:
		[result := self positive32BitIntegerFor:
					(self fetchLong32: (VMBIGENDIAN ifTrue: [1] ifFalse: [0])
						ofObject: rcvr).
		^self pop: 2 thenPush: result].
	self primitiveFailFor: ((self isIntegerObject: index)
							ifTrue: [PrimErrBadIndex]
							ifFalse: [PrimErrBadArgument])
]

{ #category : #'indexing primitives' }
StackInterpreter >> primitiveFloatAtPut [
	"Provide platform-independent access to 32-bit words comprising
	 a Float.  Map index 1 onto the most significant word and index 2
	 onto the least significant word."
	| rcvr index oopToStore valueToStore |
	<var: #result type: #usqInt>
	self initPrimCall.
	oopToStore := self stackTop.
	valueToStore := self positive32BitValueOf: oopToStore.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 2.
	index := self stackValue: 1.
	index = ConstOne ifTrue:
		[self storeLong32: (VMBIGENDIAN ifTrue: [0] ifFalse: [1])
			ofObject: rcvr
			withValue: valueToStore.
		^self pop: 3 thenPush: oopToStore].
	index = ConstTwo ifTrue:
		[self storeLong32: (VMBIGENDIAN ifTrue: [1] ifFalse: [0])
			ofObject: rcvr
			withValue: valueToStore.
		^self pop: 3 thenPush: oopToStore].
	self primitiveFailFor: ((self isIntegerObject: index)
							ifTrue: [PrimErrBadIndex]
							ifFalse: [PrimErrBadArgument])
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatDivide [
	self primitiveFloatDivide: (self stackValue: 1) byArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatDivide: rcvrOop byArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	self success: arg ~= 0.0.
	self successful ifTrue:
		[self pop: 2 thenPushFloat: rcvr / arg]
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatEqual [
	| aBool |
	aBool := self primitiveFloatEqual: (self stackValue: 1) toArg: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: aBool]
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	^rcvr = arg
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatGreater: rcvrOop thanArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	^rcvr > arg
]

{ #category : #'comparison float primitives' }
StackInterpreter >> primitiveFloatGreaterOrEqual [
	| aBool |
	aBool := self primitiveFloatGreaterOrEqual: (self stackValue: 1) toArg: self stackTop.
	self successful ifTrue: [self pop: 2 thenPushBool: aBool]
]

{ #category : #'comparison float primitives' }
StackInterpreter >> primitiveFloatGreaterOrEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	^rcvr >= arg
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatGreaterThan [
	| aBool |
	aBool := self primitiveFloatGreater: (self stackValue: 1) thanArg: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: aBool]
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatLess: rcvrOop thanArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	^rcvr < arg
]

{ #category : #'comparison float primitives' }
StackInterpreter >> primitiveFloatLessOrEqual [
	| aBool |
	aBool := self primitiveFloatLessOrEqual: (self stackValue: 1) toArg: self stackTop.
	self successful ifTrue: [self pop: 2 thenPushBool: aBool]
]

{ #category : #'comparison float primitives' }
StackInterpreter >> primitiveFloatLessOrEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	^rcvr <= arg
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatLessThan [
	| aBool |
	aBool := self primitiveFloatLess: (self stackValue: 1) thanArg: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: aBool]
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatMultiply [
	^ self primitiveFloatMultiply: (self stackValue: 1) byArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatMultiply: rcvrOop byArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	self successful ifTrue:
		[self pop: 2 thenPushFloat: rcvr * arg]
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatNotEqual [
	| aBool |
	aBool := self primitiveFloatEqual: (self stackValue: 1) toArg: self stackTop.
	self successful ifTrue:
		[self pop: 2 thenPushBool: aBool not]
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatSubtract [
	^ self primitiveFloatSubtract: (self stackValue: 1) fromArg: self stackTop
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatSubtract: rcvrOop fromArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	self successful ifTrue:
		[self pop: 2 thenPushFloat: rcvr - arg]
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveFlushCache [
	"Clear the method lookup cache. This must be done after every programming change."

	self flushMethodCache.
	self flushAtCache
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveFlushCacheByMethod [
	"The receiver is a compiledMethod.  Clear all entries in the method lookup cache that refer to this method, presumably because it has been redefined, overridden or removed."
	| probe oldMethod |
	oldMethod := self stackTop.
	probe := 0.
	1 to: MethodCacheEntries do:
		[:i |
		(methodCache at: probe + MethodCacheMethod) = oldMethod ifTrue:
			[methodCache at: probe + MethodCacheSelector put: 0].
		probe := probe + MethodCacheEntrySize]
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveFlushCacheBySelector [
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
StackInterpreter >> primitiveFlushExternalPrimitives [
	"Primitive. Flush all the existing external primitives in the image thus forcing a reload on next invokation."
	self flushExternalPrimitives
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveForceDisplayUpdate [
	"On some platforms, this primitive forces enqueued display updates to be processed immediately. On others, it does nothing."

	self ioForceDisplayUpdate.

]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveForceTenure [
	"Set force tenure flag to true, this forces a tenure operation on the next incremental GC"

	<export: true>
	forceTenureFlag := 1
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveFormPrint [
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

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFractionalPart [
	| rcvr frac trunc |
	<var: #rcvr type: #double>
	<var: #frac type: #double>
	<var: #trunc type: #double>
	rcvr := self popFloat.
	self successful
		ifTrue: [self cCode: 'frac = modf(rcvr, &trunc)' inSmalltalk: [frac := rcvr fractionPart].
				self pushFloat: frac]
		ifFalse: [self unPop: 1]
]

{ #category : #'memory space primitives' }
StackInterpreter >> primitiveFullGC [
	"Do a full garbage collection and return the number of bytes available (including swap space if dynamic memory management is supported)."

	fullGCLock > 0 ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	self externalWriteBackHeadFramePointers.
	self incrementalGC.  "maximimize space for forwarding table"
	self fullGC.
	self pop: 1 thenPushInteger: (self bytesLeft: true).
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveGetAttribute [
	"Fetch the system attribute with the given integer ID. The 
	result is a string, which will be empty if the attribute is not 
	defined."
	| attr sz s |
	attr := self stackIntegerValue: 0.
	self successful
		ifTrue: [sz := self attributeSize: attr].
	self successful
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
StackInterpreter >> primitiveGetLogDirectory [
	"Primitive. Answer the VM's current log directory"
	| ptr sz stringOop |
	<var: 'ptr' type: 'char*'>
	<export: true>
	ptr := self ioGetLogDirectory.
	ptr == nil ifTrue:[^self success: false].
	sz := self strlen: ptr.
	stringOop := self instantiateClass: self classString indexableSize: sz.
	0 to: sz-1 do:[:i| self storeByte: i ofObject: stringOop withValue: (ptr at: i)].
	self pop: self methodArgumentCount+1.
	self push: stringOop.
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveGetNextEvent [
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
			ifFalse:[value := self positive32BitIntegerFor: value.
				self storePointer: i ofObject: arg withValue: value]].

	self successful ifFalse:[^nil].
	self pop: 1
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveGetWindowLabel [
	"Primitive. Answer the OS window's label"
	| ptr sz labelOop |
	<var: 'ptr' type: 'char*'>
	<export: true>
	ptr := self ioGetWindowLabel.
	ptr == nil ifTrue:[^self success: false].
	sz := self strlen: ptr.
	labelOop := self instantiateClass: self classString indexableSize: sz.
	0 to: sz-1 do:[:i| self storeByte: i ofObject: labelOop withValue: (ptr at: i)].
	self pop: self methodArgumentCount+1.
	self push: labelOop.
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveGetWindowSize [
	"Primitive. Answer the OS window's size (extent)"
	| w h |
	<export: true>
	w := self ioGetWindowWidth.
	h := self ioGetWindowHeight.
	self pop: self methodArgumentCount+1.
	self push: (self makePointwithxValue: w yValue: h).
]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveGreaterOrEqual [
	| integerReceiver integerArgument |
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver >= integerArgument
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveGreaterOrEqualLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	self successful ifTrue:
		[self pop: 2 thenPushBool: integerRcvr >= integerArg]
]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveGreaterThan [
	| integerReceiver integerArgument |
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver > integerArgument
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveGreaterThanLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	self successful ifTrue:
		[self pop: 2 thenPushBool: integerRcvr > integerArg]
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveHeartbeatFrequency [
	"Answer the heartbeat frequency in beats per second.  If the argument is true, reset the frequency measure."
	<export: true>
	| reset |
	reset := argumentCount = 1 and: [self stackTop = trueObj].
	self pop: argumentCount + 1
		thenPush: (self positive32BitIntegerFor: (self ioHeartbeatFrequency: reset))
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveHighResClock [
	"Return the value of the high resolution clock if this system has any. The exact frequency of the high res clock is undefined specifically so that we can use processor dependent instructions (like RDTSC). The only use for the high res clock is for profiling where we can allocate time based on sub-msec resolution of the high res clock. If no high-resolution counter is available, the platform should return zero."
	<export: true>
	self pop: 1.
	self push: (self positive64BitIntegerFor: self ioHighResClock).
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveIdentical [
	"is the receiver/first argument the same object as the (last) argument?.
	 pop argumentCount because this can be used as a mirror primitive."
	| thisObject otherObject |
	otherObject := self stackValue: 1.
	thisObject := self stackTop.
	self pop: argumentCount + 1 thenPushBool: thisObject = otherObject
]

{ #category : #'other primitives' }
StackInterpreter >> primitiveIdentityDictionaryLookup [
	"Primitive. Speed up IdentityDictionary>>scanFor:.
	XXXX: DO NOT USE THIS YET. I have a suspicion that the code below might be flawed since the speedup is much less than what I would have expected to see. Perhaps my expectations are wrong but perhaps that code is just completely broken... YMMV."
	| obj dict array finish hash start assoc key |
	<export: true>
	obj := self stackValue: 0.
	dict := self stackValue: 1.
	((self isIntegerObject: dict) or:[(self slotSizeOf: dict) < 2]) 
		ifTrue:[^self primitiveFail].

	array := self fetchPointer: 1 ofObject: dict.
	(self fetchClassOf: array) = (self splObj: ClassArray) 
		ifFalse:[^self primitiveFail].

	finish := self lengthOf: array.
	(self isIntegerObject: obj)
		ifTrue: [hash := self integerValueOf: obj]
		ifFalse: [hash := self hashBitsOf: obj].
	"Scale hash if the receiver is a large dictionary"
	finish > 4096 ifTrue: [hash := hash * (finish // 4096)].

	"First pass is from start to finish.
     Dodge undefined remainder in C for negative arguments."
	hash < 0 ifTrue: [
		start := (((0 - hash) \\ finish) + 1)
	] ifFalse: [
		start := (hash \\ finish) + 1.
	].

	1 to: 2 do:[:pass|
		start to: finish do:[:index|
			assoc := self fetchPointer: index-1 ofObject: array.
			assoc = nilObj ifTrue:[
				^self pop: 2 thenPush: (self integerObjectOf: index).
			].
			((self isPointers: assoc) and:[(self lengthOf: assoc) > 1])
				ifFalse:[^self primitiveFail].
			key := self fetchPointer: 0 ofObject: assoc.
			key == obj ifTrue:[
				^self pop: 2 thenPush: (self integerObjectOf: index).
			].
		].
		"Second pass is from 1 to start-1"
		finish := start-1.
		start := 1.
	].
	"No match and no empty slot"
	self pop: 2 thenPush: (self integerObjectOf: 0).

]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveIdentityHash [
	| thisReceiver |
	thisReceiver := self stackTop.
	self success: (self isIntegerObject: thisReceiver) not.
	self successful
		ifTrue: [self pop:1 thenPushInteger: (self hashBitsOf: thisReceiver)]
]

{ #category : #'other primitives' }
StackInterpreter >> primitiveImageName [
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
		self successful ifTrue: [
			sz := self stSizeOf: s.
			self imageNamePut: (s + BaseHeaderSize) Length: sz.
			self pop: 1.  "pop s, leave rcvr on stack"
		].
	] ifFalse: [
		sz := self imageNameSize.
		s := self instantiateClass: (self splObj: ClassString) indexableSize: sz.
		self imageNameGet: (s + BaseHeaderSize) Length: sz.
		self pop: 1.  "rcvr"
		self push: s.
	]
]

{ #category : #'memory space primitives' }
StackInterpreter >> primitiveIncrementalGC [
	"Do a quick, incremental garbage collection and return the number of bytes immediately available.
	 (Note: more space may be made available by doing a full garbage collection."

	self externalWriteBackHeadFramePointers.
	self incrementalGC.
	self pop: 1 thenPushInteger: (self bytesLeft: false)
]

{ #category : #'compiled methods' }
StackInterpreter >> primitiveIndexOf: methodPointer [
	"Note: We now have 10 bits of primitive index, but they are in two places
	for temporary backward compatibility.  The time to unpack is negligible,
	 since the derived primitive function pointer is stored in the method cache."
	<api>
	| primBits |
	primBits := ((self headerOf: methodPointer) >> 1) bitAnd: 16r100001FF.
	^(primBits bitAnd: 16r1FF) + (primBits >> 19)

]

{ #category : #'compiled methods' }
StackInterpreter >> primitiveIndexOfMethodHeader: methodHeader [
	"Note: We now have 10 bits of primitive index, but they are in two places
	 for temporary backward compatibility.  The time to unpack is negligible,
	 since the derived primitive function pointer is stored in the method cache."
	<api>
	| primBits |
	primBits := (methodHeader >> 1).
	^(primBits bitAnd: 16r1FF) + ((primBits >> 19) bitAnd: 16r200)
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveInputSemaphore [
	"Register the input semaphore. If the argument is not a 
	Semaphore, unregister the current input semaphore."
	| arg |
	arg := self stackTop.
	(self isIntegerObject: arg) ifTrue:
		["If arg is integer, then use it as an index 
		  into the external objects array and install it 
		  as the new event semaphore"
		 self ioSetInputSemaphore: (self integerValueOf: arg).
		 self successful ifTrue:
			[self pop: 1].
		 ^nil].

	"old code for compatibility"
	TheInputSemaphore = nil ifTrue:
		[^self primitiveFail].
	arg := self popStack.
	(self fetchClassOf: arg) = (self splObj: ClassSemaphore) ifFalse:
		[arg := nilObj].
	self
		storePointer: TheInputSemaphore
		ofObject: specialObjectsOop
		withValue: arg
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveInputWord [
	"Return an integer indicating the reason for the most recent input interrupt."

	self pop: 1 thenPushInteger: 0.	"noop for now"
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveInstVarAt [
	| index rcvr hdr fmt totalLength fixedFields value |
	index := self stackIntegerValue: 0.
	rcvr := self stackValue: 1.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	hdr := self baseHeader: rcvr.
	fmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: rcvr format: fmt length: totalLength.
	(index >= 1 and: [index <= fixedFields]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	(fmt = 3
	 and: [(self isContextHeader: hdr)
	 and: [index - 1 <= StackPointerIndex]])
		ifTrue: [value := self externalInstVar: index - 1 ofContext: rcvr]
		ifFalse: [value := self subscript: rcvr with: index format: fmt].
	self pop: argumentCount + 1 thenPush: value
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveInstVarAtPut [
	| newValue index rcvr hdr fmt totalLength fixedFields |
	newValue := self stackTop.
	index := self stackIntegerValue: 1.
	rcvr := self stackValue: 2.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	hdr := self baseHeader: rcvr.
	fmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: rcvr format: fmt length: totalLength.
	(index >= 1 and: [index <= fixedFields]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	(fmt = 3
	 and: [(self isContextHeader: hdr)
	 and: [self isMarriedOrWidowedContext: rcvr]])
		ifTrue: [self externalInstVar: index ofContext: rcvr put: newValue]
		ifFalse: [self subscript: rcvr with: index storing: newValue format: fmt].
	self pop: argumentCount + 1 thenPush: newValue
]

{ #category : #'sound primitives' }
StackInterpreter >> primitiveIntegerAt [
	"Return the 32bit signed integer contents of a words receiver"

	| index rcvr sz addr value intValue |
	<var: #intValue type: 'int'>
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
	addr := rcvr + BaseHeaderSize + (index - 1 * BytesPerWord). "for zero indexing"
	value := self intAt: addr.
	self pop: 2.  "pop rcvr, index"
	"push element value"
	(self isIntegerValue: value)
		ifTrue: [self pushInteger: value]
		ifFalse: [intValue := value. "32 bit int may have been stored in 32 or 64 bit sqInt"
				self push: (self signed32BitIntegerFor: intValue)] "intValue may be sign extended to 64 bit sqInt"
]

{ #category : #'sound primitives' }
StackInterpreter >> primitiveIntegerAtPut [
	"Return the 32bit signed integer contents of a words receiver"
	| index rcvr sz addr value valueOop |
	<var: 'value' type: 'int'>
	valueOop := self stackValue: 0.
	index := self stackIntegerValue: 1.
	value := self signed32BitValueOf: valueOop.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	rcvr := self stackValue: 2.
	((self isIntegerObject: rcvr)
	or: [(self isWords: rcvr) not]) ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	sz := self lengthOf: rcvr.  "number of fields"
	(index >= 1 and: [index <= sz]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	addr := rcvr + BaseHeaderSize + (index - 1 * BytesPerWord). "for zero indexing"
	value := self intAt: addr put: value.
	self pop: 3 thenPush: valueOop "pop all; return value"

]

{ #category : #'process primitives' }
StackInterpreter >> primitiveInterruptChecksPerMSec [
	"Primitive. Answer the number of interrupt checks per milliseconds that we execute
	on this machine. This can be used to adjust the sub-msecs profiler to check (roughly) 
	n times per millisecond."
	<export: true>
	self methodArgumentCount = 0 ifFalse:[^self success: false].
	self pop: 1 thenPush: (self integerObjectOf: self ioHeartbeatMilliseconds).
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveInterruptSemaphore [
	"Register the user interrupt semaphore. If the argument is 
	not a Semaphore, unregister the current interrupt 
	semaphore. "
	| arg |
	arg := self popStack.
	(self fetchClassOf: arg) = (self splObj: ClassSemaphore)
		ifTrue: [self storePointer: TheInterruptSemaphore ofObject: specialObjectsOop withValue: arg]
		ifFalse: [self storePointer: TheInterruptSemaphore ofObject: specialObjectsOop withValue: nilObj]
]

{ #category : #'memory space primitives' }
StackInterpreter >> primitiveIsRoot [
	"Primitive. Answer whether the argument to the primitive is a root for young space"
	| oop |
	<export: true>
	oop := self stackObjectValue: 0.
	self successful ifTrue:
		[self pop: argumentCount + 1 thenPushBool: ((self baseHeader: oop) bitAnd: RootBit)]
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveIsWindowObscured [
	"Primitive. Answer whether the OS window is currently partially or fully obscured."
	<export: true>
	self pop: self methodArgumentCount+1.
	self pushBool: self ioIsWindowObscured.

]

{ #category : #'memory space primitives' }
StackInterpreter >> primitiveIsYoung [
	"Primitive. Answer whether the argument to the primitive resides in young space."
	| oop |
	<export: true>
	oop := self stackObjectValue: 0.
	self successful ifTrue:
		[self pop: argumentCount + 1 thenPushBool: (self oop: oop isGreaterThanOrEqualTo: youngStart)]
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveKbdNext [
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
StackInterpreter >> primitiveKbdPeek [
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
StackInterpreter >> primitiveLessOrEqual [
	| integerReceiver integerArgument |
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver <= integerArgument
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveLessOrEqualLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	self successful ifTrue:
		[self pop: 2 thenPushBool: integerRcvr <= integerArg]
]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveLessThan [
	| integerReceiver integerArgument |
	integerArgument := self popInteger.
	integerReceiver := self popInteger.
	self checkBooleanResult: integerReceiver < integerArgument
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveLessThanLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	self successful ifTrue:
		[self pop: 2 thenPushBool: integerRcvr < integerArg]
]

{ #category : #'plugin primitives' }
StackInterpreter >> primitiveListBuiltinModule [
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
StackInterpreter >> primitiveListExternalModule [
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
StackInterpreter >> primitiveLoadImageSegment [
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
	endSeg := segmentWordArray + (self sizeBitsOf: segmentWordArray) - BaseHeaderSize.

	"Essential type checks"
	((self formatOf: outPointerArray) = 2				"Must be indexable pointers"
	 and: [(self formatOf: segmentWordArray) = 6])	"Must be indexable words"
		ifFalse: [^ self primitiveFail].

	"Version check.  Byte order of the WordArray now"
	data := self longAt: segmentWordArray + BaseHeaderSize.
	(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse:
		"Not readable -- try again with reversed bytes..."
		[self reverseBytesFrom: segmentWordArray + BaseHeaderSize to: endSeg + BytesPerWord.
		data := self longAt: segmentWordArray + BaseHeaderSize.
		(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse:
			"Still NG -- put things back and fail"
			[self reverseBytesFrom: segmentWordArray + BaseHeaderSize to: endSeg + BytesPerWord.
			DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^ self primitiveFail]].
	"Reverse the Byte type objects if the data is from opposite endian machine.
	 Revese the words in Floats if from an earlier version wit different Float order.
	 Test top byte.  $d on the Mac or $s on the PC.  Rest of word is equal."
	(data >> 16) = (self imageSegmentVersion >> 16)
		ifTrue:
			"Need to swap floats if the segment is being loaded into a little-endian VM from a version
			 that keeps Floats in big-endian word order as was the case prior to the 6505 image format."
			[(self isPlatformFloatOrderVersion: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse:
				[self vmEndianness ~= 1 "~= 1 => little-endian" ifTrue:
					[segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
					 self wordSwapFloatsFrom: segOop to: endSeg + BytesPerWord]]]
		ifFalse: "Reverse the byte-type objects once"
			[segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
				 "Oop of first embedded object"
			self byteSwapByteObjectsFrom: segOop
				to: endSeg + BytesPerWord
				flipFloatsIf: (self isPlatformFloatOrderVersion: (data bitAnd: 16rFFFF "low 2 bytes"))].

	"Proceed through the segment, remapping pointers..."
	segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
	[segOop <= endSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type = 0 or 1) -- start with that."
					fieldPtr := segOop - BytesPerWord.  doingClass := true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr := segOop + BaseHeaderSize.  doingClass := false].
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"
		lastPtr > endSeg ifTrue:
			[DoAssertionChecks ifTrue: [self verifyCleanHeaders].
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
					[(fieldOop bitAnd: 3) = 0 ifFalse:
						[^ self primitiveFail "bad oop"].
					(fieldOop bitAnd: 16r80000000) = 0
						ifTrue: ["Internal pointer -- add segment offset"
								mapOop := fieldOop + segmentWordArray]
						ifFalse: ["External pointer -- look it up in outPointers"
								outPtr := outPointerArray + (fieldOop bitAnd: 16r7FFFFFFF).
								outPtr > lastOut ifTrue:
									[^ self primitiveFail "out of bounds"].
								mapOop := self longAt: outPtr].
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr := fieldPtr + 8.
								doingClass := false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr := fieldPtr + BytesPerWord].
					segOop < youngStart ifTrue:
						[self possibleRootStoreInto: segOop value: mapOop]]].
		segOop := self objectAfter: segOop].

	"Again, proceed through the segment checking consistency..."
	segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
	[segOop <= endSeg] whileTrue:
		[(self oopHasAcceptableClass: segOop) ifFalse:
			[^ self primitiveFail "inconsistency"].
		fieldPtr := segOop + BaseHeaderSize.		"first field"
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"
		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop := self longAt: fieldPtr.
			(self oopHasAcceptableClass: fieldOop) ifFalse:
				[^ self primitiveFail "inconsistency"].
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

{ #category : #'system control primitives' }
StackInterpreter >> primitiveLocalMicrosecondClock [
	"Return the value of the microsecond clock as an integer.  The microsecond clock is at
	 least 60 bits wide which means it'll get to around August 38435 before it wraps around."

	self pop: 1 thenPush: (self positive64BitIntegerFor: self ioLocalMicroseconds)
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveLogN [
	"Natural log."

	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self popFloat.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'log(rcvr)' inSmalltalk: [rcvr ln])]
		ifFalse: [self unPop: 1]
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveLongRunningPrimitive [
	"Primitive. Answer an Array with the current long-running primitive method identified by
	 the heartbeat, the minimum number of milliseconds it was active for, and the milliseconds
	 of GC activity there-in, or nil if none.  Since the longRunningPrimitiveCheckMethod is
	 sampled at interrupt time be careful to validate it before returning it."
	<export: true>
	| result primms gcms |
	self methodArgumentCount = 0 ifFalse:
		[^self primitiveFail].
	(longRunningPrimitiveStopUsecs > longRunningPrimitiveStartUsecs "a hit"
	 and: [longRunningPrimitiveCheckMethod ~= nil					"method looks valid"
	 and: [(self addressCouldBeObj: longRunningPrimitiveCheckMethod)
	 and: [(self isFreeObject: longRunningPrimitiveCheckMethod) not
	 and: [(self isCompiledMethod: longRunningPrimitiveCheckMethod)]]]])
		ifTrue: [result := self instantiateClass: (self splObj: ClassArray) indexableSize: 3.
				primms := (longRunningPrimitiveStopUsecs - longRunningPrimitiveStartUsecs) + 500 // 1000.
				
				gcms := longRunningPrimitiveGCUsecs + 500 // 1000.
				self storePointer: 0 ofObject: result withValue: longRunningPrimitiveCheckMethod.
				self storePointerUnchecked: 1 ofObject: result withValue: (self integerObjectOf: primms).
				self storePointerUnchecked: 2 ofObject: result withValue: (self integerObjectOf: gcms)]
		ifFalse: [result := nilObj].
	self pop: 1 thenPush: result.
	self voidLongRunningPrimitive: 'get'
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveLongRunningPrimitiveSemaphore [
	"Primitive. Install the semaphore to be used for collecting long-running primitives, 
	 or nil if no semaphore should be used."
	| sema |
	<export: true>
	sema := self stackValue: 0.
	((self isIntegerObject: sema)
	or: [self methodArgumentCount ~= 1]) ifTrue:
		[^self primitiveFail].
	sema = nilObj
		ifTrue:
			[longRunningPrimitiveCheckSemaphore := nil]
		ifFalse:
			[(self fetchClassOfNonInt: sema) = (self splObj: ClassSemaphore) ifFalse:
				[^self primitiveFail].
			 longRunningPrimitiveCheckSemaphore := sema].
	self voidLongRunningPrimitive: 'install'.
	self pop: 1
]

{ #category : #'memory space primitives' }
StackInterpreter >> primitiveLowSpaceSemaphore [
	"Register the low-space semaphore. If the argument is not a 
	Semaphore, unregister the current low-space Semaphore."
	| arg |
	arg := self popStack.
	(self fetchClassOf: arg) = (self splObj: ClassSemaphore)
		ifTrue: [self storePointer: TheLowSpaceSemaphore ofObject: specialObjectsOop withValue: arg]
		ifFalse: [self storePointer: TheLowSpaceSemaphore ofObject: specialObjectsOop withValue: nilObj]
]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveMakePoint [
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

{ #category : #'control primitives' }
StackInterpreter >> primitiveMarkHandlerMethod [
	"Primitive. Mark the method for exception handling. The primitive must fail after marking the context so that the regular code is run."
	<inline: false>
	^self primitiveFail
]

{ #category : #'control primitives' }
StackInterpreter >> primitiveMarkUnwindMethod [
	"Primitive. Mark the method for exception unwinding. The primitive must fail after marking the context so that the regular code is run.  It must also *not* allow a context switch."
	<inline: false>
	^self primitiveFail
]

{ #category : #'plugin primitive support' }
StackInterpreter >> primitiveMethod [
	"Return the method an external primitive was defined in"
	^newMethod
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveMillisecondClock [
	"Return the value of the millisecond clock as an integer. Note that the millisecond clock wraps around periodically. On some platforms it can wrap daily. The range is limited to SmallInteger maxVal / 2 to allow delays of up to that length without overflowing a SmallInteger."

	self pop: 1 thenPush: (self integerObjectOf: (self ioMSecs bitAnd: MillisecondClockMask)).

]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveMod [
	| mod |
	mod := self doPrimitiveMod: (self stackValue: 1) by: (self stackTop).
	self pop2AndPushIntegerIfOK: mod
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveModLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| integerRcvr integerArg result oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'result' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).
	integerArg = 0 ifTrue:[self primitiveFail].
	self successful ifFalse:[^nil].

	result := integerRcvr \\ integerArg.

	"ensure that the result has the same sign as the integerArg"
	integerArg < 0
		ifTrue: [result > 0
			ifTrue: [result := result + integerArg]]
		ifFalse: [result < 0
			ifTrue: [result := result + integerArg]].

	oopResult := self signed64BitIntegerFor: result.
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveMouseButtons [
	"Obsolete on virtually all platforms; old style input polling code.
	Return the mouse button state. The low three bits encode the state of the <red><yellow><blue> mouse buttons. The next four bits encode the Smalltalk modifier bits <cmd><option><ctrl><shift>."

	| buttonWord |
	self pop: 1.
	buttonWord := self ioGetButtonState.
	self pushInteger: buttonWord.
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveMousePoint [
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
StackInterpreter >> primitiveMultiply [
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

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveMultiplyLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| integerRcvr integerArg result oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'result' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).
	self successful ifFalse:[^nil].

	result := integerRcvr * integerArg.
	"check for C overflow by seeing if computation is reversible"
	((integerArg = 0) or: [(result // integerArg) = integerRcvr])
		ifTrue:[oopResult := self signed64BitIntegerFor: result]
		ifFalse: [self primitiveFail].

	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveNew [
	"Allocate a new fixed-size instance. Fail if the allocation would leave less than lowSpaceThreshold bytes free. May cause a GC"

	| class spaceOkay |
	class := self stackTop.
	"The following may cause GC!"
	spaceOkay := self sufficientSpaceToInstantiate: class indexableSize: 0.
	self success: spaceOkay.
	self successful ifTrue: [ self push: (self instantiateClass: self popStack indexableSize: 0) ]
]

{ #category : #'compiled methods' }
StackInterpreter >> primitiveNewMethod [
	| header bytecodeCount class size theMethod literalCount |
	header := self stackTop.
	bytecodeCount := self stackIntegerValue: 1.
	self success: (self isIntegerObject: header).
	self successful ifFalse: [^nil].
	class := self stackValue: 2.
	size := (self literalCountOfHeader: header) + 1 * BytesPerWord + bytecodeCount.
	theMethod := self instantiateClass: class indexableSize: size.
	self storePointerUnchecked: HeaderIndex ofObject: theMethod withValue: header.
	literalCount := self literalCountOfHeader: header.
	1 to: literalCount do:
		[:i | self storePointer: i ofObject: theMethod withValue: nilObj].
	self pop: 3 thenPush: theMethod
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveNewWithArg [
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

{ #category : #'object access primitives' }
StackInterpreter >> primitiveNextInstance [
	| object classPointer subsequentObject |
	object := self stackTop.
	(self isIntegerObject: object) ifFalse:
		[classPointer := self fetchClassOfNonInt: object.
		subsequentObject := self objectAfter: object.
		[self oop: subsequentObject isLessThan: freeStart] whileTrue:
			[((self isFreeObject: subsequentObject) not
			  and: [(self fetchClassOfNonInt: subsequentObject) = classPointer]) ifTrue:
				[^self pop: argumentCount+1 thenPush: subsequentObject].
			 subsequentObject := self objectAfter: subsequentObject]].
	self primitiveFail
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveNextObject [
	"Return the object following the receiver in the heap. Return the SmallInteger zero when there are no more objects."

	| object instance |
	object := self stackTop.
	instance := self accessibleObjectAfter: object.
	instance = nil
		ifTrue: [ self pop: argumentCount+1 thenPushInteger: 0 ]
		ifFalse: [ self pop: argumentCount+1 thenPush: instance ].
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveNoop [
	"A placeholder for primitives that haven't been implemented or are being withdrawn gradually. Just absorbs any arguments and returns the receiver."

	self pop: argumentCount.  "pop args, leave rcvr on stack"
]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveNotEqual [
	| integerReceiver integerArgument result |
	integerArgument := self popStack.
	integerReceiver := self popStack.
	result := (self compare31or32Bits: integerReceiver equal: integerArgument) not.
	self checkBooleanResult: result
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveNotEqualLargeIntegers [
	"Primitive comparison operations for large integers in 64 bit range"
	| integerRcvr integerArg |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).

	self successful ifTrue:
		[self pop: 2 thenPushBool: integerRcvr ~= integerArg]
]

{ #category : #'control primitives' }
StackInterpreter >> primitiveObject: actualReceiver perform: selector withArguments: argumentArray lookedUpIn: lookupClass [
	"Common routine used by perform:withArgs:, perform:withArgs:inSuperclass:,
	 object:perform:withArgs:inClass: et al.  Answer nil on success.

	 NOTE:  The case of doesNotUnderstand: is not a failure to perform.
	 The only failures are arg types and consistency of argumentCount.

	 Since we're in the stack VM we can assume there is space to push the arguments
	 provided they are within limits (max argument count is 15).  We can therefore deal
	 with the arbitrary amount of state to remove from the stack (lookup class, selector,
	 mirror receiver) and arbitrary argument orders by deferring popping anything until
	 we know whether the send has succeeded.  So on failure we merely have to remove
	 the actual receiver and arguments pushed, and on success we have to slide the actual
	 receiver and arguments down to replace the original ones."

	| arraySize performArgCount delta |
	(self isArray: argumentArray) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].

	"Check if number of arguments is reasonable; MaxNumArgs isn't available
	 so just use LargeContextSize"
	arraySize := self fetchWordLengthOf: argumentArray.
	arraySize > (LargeContextSize / BytesPerWord) ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].

	performArgCount := argumentCount.
	"Push newMethod to save it in case of failure,
	 then push the actual receiver and args out of the array."
	self push: newMethod.
	self push: actualReceiver.
	"Copy the arguments to the stack, and execute"
	1 to: arraySize do:
		[:index| self push: (self fetchPointer: index - 1 ofObject: argumentArray)].
	argumentCount := arraySize.
	messageSelector := selector.

	self findNewMethodInClass: lookupClass.

	"Only test CompiledMethods for argument count - any other objects playacting as CMs will have to take their chances"
	(self isCompiledMethod: newMethod) ifTrue:
		[(self argumentCountOf: newMethod) ~= argumentCount ifTrue:
			["Restore the state by popping all those array entries and pushing back the selector and array, and fail"
			 self pop: arraySize + 1.
			 newMethod := self popStack.
			 ^self primitiveFailFor: PrimErrBadNumArgs]].

	"Cannot fail this primitive from here-on.  Slide the actual receiver and arguments down
	 to replace the perform arguments and saved newMethod and then execute the new
	 method. Use argumentCount not arraySize because an MNU may have changed it."
	delta := BytesPerWord * (performArgCount + 2). "+2 = receiver + saved newMethod"
	argumentCount * BytesPerWord to: 0 by: BytesPerWord negated do:
		[:offset|
		stackPages
			longAt: stackPointer + offset + delta
			put: (stackPages longAt: stackPointer + offset)].
	self pop: performArgCount + 2.
	self executeNewMethod.
	self initPrimCall.  "Recursive xeq affects primErrorCode"
	^nil
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveObjectAt [
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
StackInterpreter >> primitiveObjectAtPut [
"Defined for CompiledMethods only"
	| thisReceiver index newValue |
	newValue := self stackValue: 0.
	index := self stackIntegerValue: 1.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	thisReceiver := self stackValue: 2.
	(index > 0 and: [index <= ((self literalCountOf: thisReceiver) + LiteralStart)]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	self storePointer: index - 1 ofObject: thisReceiver withValue: newValue.
	self pop: 3 thenPush: newValue
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveObjectPointsTo [
	"This primitive is assumed to be fast (see e.g. MethodDictionary>>includesKey:) so make it so"
	| rcvr thang header fmt lastField methodHeader |
	thang := self stackTop.
	rcvr := self stackValue: 1.
	(self isIntegerObject: rcvr) ifTrue:
		[^self pop: 2 thenPushBool: false].

	"Inlined version of lastPointerOf: for speed in determining if rcvr is a context."
	header := self baseHeader: rcvr.
	fmt := self formatOfHeader: header.
	fmt <= 4
		ifTrue:
			[(fmt = 3
			  and: [self isContextHeader: header]) 
				ifTrue:
	 				[(self isMarriedOrWidowedContext: rcvr) ifTrue:
						[self externalWriteBackHeadFramePointers.
						 (self isStillMarriedContext: rcvr) ifTrue:
							[^self pop: 2
									thenPushBool: (self marriedContext: rcvr
														pointsTo: thang
														stackDeltaForCurrentFrame: 2)]].
					"contexts end at the stack pointer"
					lastField := CtxtTempFrameStart + (self fetchStackPointerOf: rcvr) * BytesPerWord]
				ifFalse:
					[lastField := (self sizeBitsOfSafe: rcvr) - BaseHeaderSize]]
		ifFalse:
			[fmt <= 12 "no pointers" ifTrue:
				[^self pop: 2 thenPushBool: false].
			"CompiledMethod: contains both pointers and bytes:"
			methodHeader := self longAt: rcvr + BaseHeaderSize.
			lastField := (self literalCountOfHeader: methodHeader) * BytesPerWord + BaseHeaderSize].

	BaseHeaderSize to: lastField by: BytesPerWord do:
		[:i |
		(self longAt: rcvr + i) = thang ifTrue:
			[^self pop: 2 thenPushBool: true]].
	self pop: 2 thenPushBool: false
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveOriginalMillisecondClock [
	"Return the value of the millisecond clock as an integer, using the old method prior to the 64-bit microsecond clock."
	<export: true>
	self pop: 1 thenPush: (self integerObjectOf: (self ioOldMSecs bitAnd: MillisecondClockMask))
]

{ #category : #'control primitives' }
StackInterpreter >> primitivePerform [
	| performSelector newReceiver lookupClass performMethod |
	performSelector := messageSelector.
	performMethod := newMethod.
	messageSelector := self stackValue: argumentCount - 1.
	newReceiver := self stackValue: argumentCount.

	"NOTE: the following lookup may fail and be converted to #doesNotUnderstand:,
	 so we must adjust argumentCount and slide args now, so that will work."

	"Slide arguments down over selector"
	argumentCount := argumentCount - 1.
	argumentCount to: 1 by: -1 do:
		[:i|
		stackPages
			longAt: stackPointer + (i * BytesPerWord)
			put: (stackPages longAt: stackPointer + ((i - 1) * BytesPerWord))].
	self pop: 1.
	lookupClass := self fetchClassOf: newReceiver.
	self findNewMethodInClass: lookupClass.

	"Only test CompiledMethods for argument count - other objects will have to take their chances"
	(self isCompiledMethod: newMethod)
		ifTrue: [self success: (self argumentCountOf: newMethod) = argumentCount].

	self successful
		ifTrue: [self executeNewMethod.
			"Recursive xeq affects primErrorCode"
			self initPrimCall]
		ifFalse: ["Slide the args back up (sigh) and re-insert the selector."
			self unPop: 1.
			1 to: argumentCount by: 1 do:
				[:i |
				stackPages longAt: stackPointer + ((i - 1) * BytesPerWord)
					put: (stackPages longAt: stackPointer + (i * BytesPerWord))].
			stackPages longAt: stackPointer + (argumentCount * BytesPerWord) put: messageSelector.
			argumentCount := argumentCount + 1.
			newMethod := performMethod.
			messageSelector := performSelector]
]

{ #category : #'control primitives' }
StackInterpreter >> primitivePerformInSuperclass [
	| lookupClass rcvr currentClass |
	lookupClass := self stackTop.
	rcvr := self stackValue: 3.
	currentClass := self fetchClassOf: rcvr.
	[currentClass ~= lookupClass] whileTrue:
		[currentClass := self superclassOf: currentClass.
		 currentClass = nilObj ifTrue: [^self primitiveFailFor: PrimErrBadArgument]].

	self primitiveObject: rcvr "a.k.a. self stackValue: 3"
		perform: (self stackValue: 2)
		withArguments: (self stackValue: 1)
		lookedUpIn: lookupClass "a.k.a. self stackTop"
]

{ #category : #'control primitives' }
StackInterpreter >> primitivePerformWithArgs [

	| lookupClass rcvr |
	rcvr := self stackValue: 2.
	lookupClass := self fetchClassOf: rcvr.

	self primitiveObject: rcvr "a.k.a. self stackValue: 2"
		perform: (self stackValue: 1)
		withArguments: self stackTop
		lookedUpIn: lookupClass
]

{ #category : #'object access primitives' }
StackInterpreter >> primitivePointX [
	| rcvr | 
	<inline: false>
	rcvr := self popStack.
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	self successful
		ifTrue: [self push: (self fetchPointer: XIndex ofObject: rcvr)]
		ifFalse: [self unPop: 1]
]

{ #category : #'object access primitives' }
StackInterpreter >> primitivePointY [
	| rcvr | 
	<inline: false>
	rcvr := self popStack.
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	self successful
		ifTrue: [self push: (self fetchPointer: YIndex ofObject: rcvr)]
		ifFalse: [self unPop: 1]
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveProfilePrimitive [
	"Primitive. Answer the last primitive method sampled by the profiler."
	<export: true>
	self methodArgumentCount = 0 ifFalse:
		[^self primitiveFail].
	self pop: 1 thenPush: profileMethod.
	profileMethod := nilObj
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveProfileSample [
	"Primitive. Answer the last sample taken by the profiler, or nil if the profiler isn't active.
	See also primitiveProfileStart."
	<export: true>
	self methodArgumentCount = 0 ifFalse:
		[^self primitiveFail].
	self pop: 1 thenPush: profileProcess.
	profileProcess := nilObj
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveProfileSemaphore [
	"Primitive. Install the semaphore to be used for profiling, 
	or nil if no semaphore should be used.
	See also primitiveProfileStart."
	| sema |
	<export: true>
	self methodArgumentCount = 1 ifFalse:[^self success: false].
	sema := self stackValue: 0.
	sema = nilObj ifFalse:[
		(self fetchClassOf: sema) = (self splObj: ClassSemaphore) 
			ifFalse:[^self success: false]].
	profileSemaphore := sema.
	profileProcess := profileMethod := nilObj.
	self pop: 1.
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveProfileStart [
	"Primitive. Begin profiling execution every by using the interrupt check-counter instead of a time-based process (which is limited to timing resolution and triggers off the same signal that many of the processes being profiled trigger off leading to consistently wrong results).
	The argument is the number of interrupt checks (method activations) to let go by before taking a sample. The sample is being stored in the profileSample iVar which can be retrieved by executing primitiveProfileSample. When a sample is taken, it signals the semaphore specified in primitiveProfileSemaphore.
	If the argument is less or equal to zero, it disables profiling."
	| deltaTicks |
	<export: true>
	self methodArgumentCount = 1 ifFalse:[^self success: false].
	deltaTicks := self stackIntegerValue: 0.
	self successful ifTrue:[
		nextProfileTick := self ioHighResClock + deltaTicks.
		self pop: 1.
	]
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveQuit [

	self ioExit.

]

{ #category : #'arithmetic integer primitives' }
StackInterpreter >> primitiveQuo [
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

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveQuoLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| integerRcvr integerArg result oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'result' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).
	integerArg = 0 ifTrue:[self primitiveFail].
	self successful ifFalse:[^nil].

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
	self successful ifTrue:[self pop: 2 thenPush: oopResult]
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveRelinquishProcessor [
	"Relinquish the processor for up to the given number of microseconds. The exact behavior of this primitive is platform dependent."

	| microSecs |
	microSecs := self stackIntegerValue: 0.
	self successful ifTrue: [
		"DO NOT allow relinquishing the processor while we are profiling since this
		may skew the time base for our measures (it may reduce processor speed etc).
		Instead we go full speed, therefore measuring the precise time we spend in the
		inner idle loop as a busy loop."
		nextProfileTick = 0 ifTrue:[self ioRelinquishProcessorForMicroseconds: microSecs].
		self pop: 1.  "microSecs; leave rcvr on stack"
	]
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveResume [
	"Put this process on the scheduler's lists thus allowing it to proceed next time there is
	 a chance for processes of it's priority level.  It must go to the back of its run queue so
	 as not to preempt any already running processes at this level.  If the process's priority
	 is higher than the current process, preempt the current process."
	| proc |
	proc := self stackTop.  "rcvr"
	self success: (self isContext: (self fetchPointer: SuspendedContextIndex ofObject: proc)).
	self successful ifTrue: [self resume: proc preemptedYieldingIf: preemptionYields]
]

{ #category : #'memory space primitives' }
StackInterpreter >> primitiveRootTable [
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
StackInterpreter >> primitiveRootTableAt [
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
	]
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveScanCharacters [
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
StackInterpreter >> primitiveScreenDepth [
	"Return a SmallInteger indicating the current depth of the OS screen. Negative values are used to imply LSB type pixel format an there is some support in the VM for handling either MSB or LSB"
	| depth |
	<export: true>
	depth := self ioScreenDepth.
	self failed ifTrue:[^self primitiveFail].
	self pop: 1 thenPushInteger: depth.
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveScreenSize [
	"Return a point indicating the current size of the Smalltalk window. Currently there is a limit of 65535 in each direction because the point is encoded into a single 32bit value in the image header. This might well become a problem one day"
	| pointWord |
	self pop: 1.
	pointWord := self ioScreenSize.
	self push: (self makePointwithxValue: (pointWord >> 16 bitAnd: 65535) yValue: (pointWord bitAnd: 65535))
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveSecondsClock [
	"Return the number of seconds since January 1, 1901 as an integer."

	self pop: 1 thenPush: (self positive32BitIntegerFor: self ioSeconds).
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveSetDisplayMode [
	"Set to OS to the requested display mode.
	See also DisplayScreen setDisplayDepth:extent:fullscreen:"
	| fsFlag h w d okay |
	fsFlag := self booleanValueOf: (self stackTop).
	h := self stackIntegerValue: 1.
	w := self stackIntegerValue: 2.
	d := self stackIntegerValue: 3.
	self successful ifTrue: [okay := self cCode:'ioSetDisplayMode(w, h, d, fsFlag)'].
	self successful ifTrue: [self pop: 5 thenPushBool: okay "Pop args+rcvr"]
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveSetFullScreen [
	"On platforms that support it, set full-screen mode to the value of the boolean argument."

	| argOop |
	argOop := self stackTop.
	argOop = trueObj
		ifTrue: [self ioSetFullScreen: true]
		ifFalse: [ argOop = falseObj
				ifTrue: [self ioSetFullScreen: false]
				ifFalse: [self primitiveFail]].
	self successful ifTrue: [self pop: 1]
]

{ #category : #'memory space primitives' }
StackInterpreter >> primitiveSetGCBiasToGrow [
	"Primitive. Indicate if the GC logic should have bias to grow"
	| flag |
	<export: true>
	flag := self stackIntegerValue: 0.
	self successful ifTrue:[
		gcBiasToGrow := flag.
		self pop: argumentCount.
	]
]

{ #category : #'memory space primitives' }
StackInterpreter >> primitiveSetGCBiasToGrowGCLimit [
	"Primitive. If the GC logic has  bias to grow, set growth limit"
	| value |
	<export: true>
	value := self stackIntegerValue: 0.
	self successful ifTrue:
		[gcBiasToGrowGCLimit := value.
		 gcBiasToGrowThreshold := youngStart - self startOfMemory asInteger.
		 self pop: argumentCount]
]

{ #category : #'memory space primitives' }
StackInterpreter >> primitiveSetGCSemaphore [
	"Primitive. Indicate the semaphore to be signalled for upon garbage collection"
	| index |
	<export: true>
	index := self stackIntegerValue: 0.
	self successful ifTrue:[
		gcSemaphoreIndex := index.
		self pop: argumentCount.
	]
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveSetInterruptKey [
	"Set the user interrupt keycode. The keycode is an integer whose encoding is described in the comment for primitiveKbdNext."

	| keycode |
	keycode := self popInteger.
	self successful
		ifTrue: [ interruptKeycode := keycode ]
		ifFalse: [ self unPop: 1 ]
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveSetLogDirectory [
	"Primitive. Set the VM's log directory"
	| stringOop sz |
	<export: true>
	stringOop := self stackTop.
	(self isBytes: stringOop) ifFalse:[^self success: false].
	sz := self byteSizeOf: stringOop.
	self ioSetLogDirectory: (self firstIndexableField: stringOop) OfSize: sz.
	self successful ifTrue:[self pop: self methodArgumentCount]
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveSetWindowLabel [
	"Primitive. Set the OS window's label"
	| labelOop sz |
	<export: true>
	labelOop := self stackTop.
	(self isBytes: labelOop) ifFalse:[^self success: false].
	sz := self byteSizeOf: labelOop.
	self ioSetWindowLabel: (self firstIndexableField: labelOop) OfSize: sz.
	self successful ifTrue:[self pop: self methodArgumentCount]
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveSetWindowSize [
	"Primitive. Answer the OS window's size (extent)"
	| w h |
	<export: true>
	h := self stackIntegerValue: 0.
	w := self stackIntegerValue: 1.
	self successful ifTrue:[
		self ioSetWindowWidth: w Height: h.
		self pop: self methodArgumentCount.
	]
]

{ #category : #'sound primitives' }
StackInterpreter >> primitiveShortAt [
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
StackInterpreter >> primitiveShortAtPut [
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
	addr := rcvr + BaseHeaderSize + (2 * (index - 1)).
	self shortAt: addr put: value.
	self pop: 3 thenPush: (self integerObjectOf: value) "pop all; return value"
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveShowDisplayRect [
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
StackInterpreter >> primitiveSignal [
	"Synchronously signal the semaphore.
	 This may change the active process as a result."
	self synchronousSignal: self stackTop
]

{ #category : #'memory space primitives' }
StackInterpreter >> primitiveSignalAtBytesLeft [
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
StackInterpreter >> primitiveSignalAtMilliseconds [
	"Cause the time semaphore, if one has been registered, to be
	 signalled when the microsecond clock is greater than or equal to
	 the given tick value. A tick value of zero turns off timer interrupts."
	| msecsObj msecs deltaMsecs sema |
	<var: #msecs type: #usqInt>
	msecsObj := self stackTop.
	sema := self stackValue: 1.
	msecs := self positive32BitValueOf: msecsObj.
	(self failed
	 or: [self isIntegerObject: sema]) ifTrue:
		[self primitiveFail.
		 ^nil].
	(self fetchClassOfNonInt: sema) = (self splObj: ClassSemaphore)
		ifTrue:
			[self
				storePointer: TheTimerSemaphore
				ofObject: specialObjectsOop
				withValue: sema.
			deltaMsecs := msecs - (self ioMSecs bitAnd: MillisecondClockMask).
			deltaMsecs < 0 ifTrue:
				[deltaMsecs := deltaMsecs + MillisecondClockMask + 1].
			nextWakeupUsecs := self ioUTCMicroseconds + (deltaMsecs * 1000)]
		ifFalse:
			[self
				storePointer: TheTimerSemaphore
				ofObject: specialObjectsOop
				withValue: nilObj.
			nextWakeupUsecs := 0].
	self pop: 2
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveSignalAtUTCMicroseconds [
	"Cause the time semaphore, if one has been registered, to be
	 signalled when the microsecond clock is greater than or equal to
	 the given tick value. A tick value of zero turns off timer interrupts."
	| usecsObj sema usecs |
	<var: #usecs type: #usqLong>
	usecsObj := self stackTop.
	sema := self stackValue: 1.
	usecs := self positive64BitValueOf: usecsObj.
	(self failed
	 or: [self isIntegerObject: sema]) ifTrue:
		[self primitiveFail.
		 ^nil].
	(self fetchClassOfNonInt: sema) = (self splObj: ClassSemaphore)
		ifTrue:
			[self
				storePointer: TheTimerSemaphore
				ofObject: specialObjectsOop
				withValue: sema.
			nextWakeupUsecs := usecs]
		ifFalse:
			[self
				storePointer: TheTimerSemaphore
				ofObject: specialObjectsOop
				withValue: nilObj.
			nextWakeupUsecs := 0].
	self pop: 2
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveSine [

	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self popFloat.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'sin(rcvr)' inSmalltalk: [rcvr sin])]
		ifFalse: [self unPop: 1]
]

{ #category : #'indexing primitives' }
StackInterpreter >> primitiveSize [
	| rcvr sz |
	rcvr := self stackTop.
	(self isIntegerObject: rcvr) ifTrue: [^ self primitiveFail].  "Integers are not indexable"
	(self formatOf: rcvr) < 2 ifTrue: [^ self primitiveFail].  "This is not an indexable object"
	sz := self stSizeOf: rcvr.
	self successful ifTrue:
		[self pop: argumentCount + 1 thenPush: (self integerObjectOf: sz)]
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveSnapshot [
	"save a normal snapshot under the same name as it was loaded unless it has been renamed by the last primitiveImageName"
	<inline: false>
	self snapshot: false

]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveSnapshotEmbedded [
	"save an embedded snapshot"
	<inline: false>
	self snapshot: true
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveSomeInstance [
	| class instance |
	class := self stackTop.
	instance := self initialInstanceOf: class.
	instance = nilObj
		ifTrue: [self primitiveFail]
		ifFalse: [self pop: argumentCount+1 thenPush: instance]
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveSomeObject [
	"Return the first object in the heap."

	self pop: argumentCount+1.
	self push: self firstAccessibleObject.
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveSpecialObjectsOop [
	"Return the oop of the SpecialObjectsArray."

	self pop: 1 thenPush: specialObjectsOop.
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveSquareRoot [
	| rcvr |
	<var: #rcvr type: #double>
	rcvr := self popFloat.
	self success: rcvr >= 0.0.
	self successful
		ifTrue: [self pushFloat: (self cCode: 'sqrt(rcvr)' inSmalltalk: [rcvr sqrt])]
		ifFalse: [self unPop: 1]
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveStartVMProfiling [
	"Primitive. Start the VM profiler."
	self cCode: 'ioControlProfile(1,0,0,0,0)'.
	self pop: argumentCount
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveStopVMProfiling [
	"Primitive. Stop the VM profiler and either copy the histogram data into the
	 supplied arguments, if they're non-nil.  Fail if the arguments are not of the right type or size."
	| vmHistArrayOrNil vmHist vmBins easHistArrayOrNil easHist easBins |
	<var: #vmHist type: #'long *'>
	<var: #vmBins type: #long>
	<var: #easHist type: #'long *'>
	<var: #easBins type: #long>
	self success: argumentCount = 2.
	vmHistArrayOrNil := self stackObjectValue: 1.
	easHistArrayOrNil := self stackObjectValue: 0.
	self successful ifFalse:
		[^nil].
	"Both args must be either nil or arrays.  If they're arrays and the wrong size we incorrectly stop profiling."
	((vmHistArrayOrNil = nilObj or: [(self fetchClassOfNonInt: vmHistArrayOrNil) = (self splObj: ClassArray)])
	 and: [(self fetchClassOfNonInt: vmHistArrayOrNil) = (self fetchClassOfNonInt: easHistArrayOrNil)]) ifFalse:
		[^self primitiveFail].
	self cCode: 'ioControlProfile(0,&vmHist,&vmBins,&easHist,&easBins)'
		inSmalltalk: [vmHist := vmBins := easHist := easBins := 0].
	vmHistArrayOrNil ~= nilObj ifTrue:
		[((self fetchWordLengthOf: vmHistArrayOrNil) = vmBins
		  and: [(self fetchWordLengthOf: easHistArrayOrNil) = easBins]) ifFalse:
			[^self primitiveFail].
		0 to: vmBins - 1 do:
			[:i|
			self storePointerUnchecked: i
				ofObject: vmHistArrayOrNil
				withValue: (self integerObjectOf: (vmHist at: i))].
		0 to: easBins - 1 do:
			[:i|
			self storePointerUnchecked: i
				ofObject: easHistArrayOrNil
				withValue: (self integerObjectOf: (easHist at: i))]].
	self pop: argumentCount
]

{ #category : #'image segment in/out' }
StackInterpreter >> primitiveStoreImageSegment [
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
	firstOut := outPointerArray + BaseHeaderSize.
	lastOut := firstOut - BytesPerWord.
	hdrBaseOut := outPointerArray + ((self lastPointerOf: outPointerArray) // (BytesPerWord*2) * BytesPerWord). "top half"

	lastSeg := segmentWordArray.
	endSeg := segmentWordArray + (self sizeBitsOf: segmentWordArray) - BytesPerWord.

	"Write a version number for byte order and version check"
	versionOffset := BytesPerWord.
	lastSeg := lastSeg + versionOffset.
	lastSeg > endSeg ifTrue: [^ self primitiveFail].
	self longAt: lastSeg put: self imageSegmentVersion.

	"Allocate top 1/8 of segment for table of internal oops and saved headers"
	firstIn := endSeg - ((self sizeBitsOf: segmentWordArray) // (BytesPerWord*8) * BytesPerWord).  "Take 1/8 of seg"
	lastIn := firstIn - BytesPerWord.
	hdrBaseIn := firstIn + ((self sizeBitsOf: segmentWordArray) // (BytesPerWord*16) * BytesPerWord). "top half of that"

	"First mark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitOr: MarkBit).
	lastPtr := arrayOfRoots + (self lastPointerOf: arrayOfRoots).
	fieldPtr := arrayOfRoots + BaseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop := self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitOr: MarkBit)].
		fieldPtr := fieldPtr + BytesPerWord].

	"Then do a mark pass over all objects.  This will stop at our marked roots,
	thus leaving our segment unmarked in their shadow."
	savedYoungStart := youngStart.
	youngStart := self startOfMemory.  "process all of memory"
	self markAndTraceInterpreterOops: false.	"and special objects array"
	youngStart := savedYoungStart.
	
	"Finally unmark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitAnd: AllButMarkBit).
	fieldPtr := arrayOfRoots + BaseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop := self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitAnd: AllButMarkBit)].
		fieldPtr := fieldPtr + BytesPerWord].

	"All external objects, and only they, are now marked.
	Copy the array of roots into the segment, and forward its oop."
	lastIn := lastIn + BytesPerWord.
	lastIn >= hdrBaseIn ifTrue: [self success: false].
	lastSeg := self copyObj: arrayOfRoots toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn).
	self successful ifFalse:
		[lastIn := lastIn - BytesPerWord.
		self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
		^ self primitiveFailAfterCleanup: outPointerArray].

	"Now run through the segment fixing up all the pointers.
	Note that more objects will be added to the segment as we make our way along."
	segOop := self oopFromChunk: segmentWordArray + versionOffset + BaseHeaderSize.
	[segOop <= lastSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type=0 or 1) -- start with that."
					fieldPtr := segOop - BytesPerWord.  doingClass := true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr := segOop + BaseHeaderSize.  doingClass := false].
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
						fieldPtr := fieldPtr + BytesPerWord]
				ifFalse:
				[header := self longAt: fieldOop.
				(header bitAnd: TypeMask) = HeaderTypeFree
					ifTrue: ["Has already been forwarded -- this is the link"
							mapOop := header bitAnd: AllButTypeMask]
					ifFalse:
					[((self longAt: fieldOop) bitAnd: MarkBit) = 0
						ifTrue:
							["Points to an unmarked obj -- an internal pointer.
							Copy the object into the segment, and forward its oop."
							lastIn := lastIn + BytesPerWord.
							lastIn >= hdrBaseIn ifTrue: [self success: false].
							lastSeg := self copyObj: fieldOop toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn).
							self successful ifFalse:
								["Out of space in segment"
								lastIn := lastIn - BytesPerWord.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^ self primitiveFailAfterCleanup: outPointerArray].
							mapOop := (self longAt: fieldOop) bitAnd: AllButTypeMask]
						ifFalse:
							["Points to a marked obj -- an external pointer.
							Map it as a tagged index in outPointers, and forward its oop."
							lastOut := lastOut + BytesPerWord.
							lastOut >= hdrBaseOut ifTrue:
								["Out of space in outPointerArray"
								lastOut := lastOut - BytesPerWord.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^ self primitiveFailAfterCleanup: outPointerArray].
.							mapOop := lastOut - outPointerArray bitOr: 16r80000000.
							self forward: fieldOop to: mapOop
								savingOopAt: lastOut andHeaderAt: hdrBaseOut + (lastOut - firstOut)]].
					"Replace the oop by its mapped value"
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr := fieldPtr + (BytesPerWord*2).
								doingClass := false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr := fieldPtr + BytesPerWord]]].
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
	self pop: 3.  "...leaving the receiver on the stack as return value"
]

{ #category : #'object access primitives' }
StackInterpreter >> primitiveStoreStackp [
	"Atomic store into context stackPointer. 
	Also ensures that any newly accessible cells are initialized to nil "
	| ctxt newStackp theFP thePage onCurrentPage stackp |
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	ctxt := self stackValue: 1.
	newStackp := self stackIntegerValue: 0.
	(self successful
	 and: [newStackp between: 0 and: (self lengthOf: ctxt)]) ifFalse:
		[^self primitiveFail].
	self externalWriteBackHeadFramePointers.
	(self isStillMarriedContext: ctxt) ifTrue:
		[theFP := self frameOfMarriedContext: ctxt.
		 thePage := stackPages stackPageFor: theFP.
		 ((onCurrentPage := thePage = stackPage)
		 and: [theFP = framePointer]) ifTrue:
			[^self primitiveFail]. "Probably easy to do this right here right now (just move stackPointer).  But fail for now."
		 self externalDivorceFrame: theFP andContext: ctxt.
		 onCurrentPage
			ifTrue:
				[framePointer := stackPage headFP.
				 stackPointer := stackPage headSP]
			ifFalse:
				[self assert: stackPage = (stackPages stackPageFor: framePointer).
				 stackPages markStackPageMostRecentlyUsed: stackPage]].
	stackp := self fetchStackPointerOf: ctxt.
	"Nil any newly accessible cells"
	stackp + 1 to: newStackp do:
		[:i | self storePointerUnchecked: i + CtxtTempFrameStart - 1 ofObject: ctxt withValue: nilObj].
	self storeStackPointerValue: newStackp inContext: ctxt.
	self pop: 1
]

{ #category : #'indexing primitives' }
StackInterpreter >> primitiveStringAt [

	self commonAt: true.
]

{ #category : #'indexing primitives' }
StackInterpreter >> primitiveStringAtPut [

	self commonAtPut: true.
]

{ #category : #'indexing primitives' }
StackInterpreter >> primitiveStringReplace [
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

	self successful ifFalse: [^ self primitiveFail].
	(self isIntegerObject: repl) ifTrue: ["can happen in LgInt copy"
			^ self primitiveFail].

	hdr := self baseHeader: array.
	arrayFmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: array baseHeader: hdr format: arrayFmt.
	arrayInstSize := self fixedFieldsOf: array format: arrayFmt length: totalLength.
	(start >= 1 and: [start - 1 <= stop and: [stop + arrayInstSize <= totalLength]])
		ifFalse: [^ self primitiveFailFor: PrimErrBadIndex].

	hdr := self baseHeader: repl.
	replFmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: repl baseHeader: hdr format: replFmt.
	replInstSize := self fixedFieldsOf: repl format: replFmt length: totalLength.
	(replStart >= 1 and: [stop - start + replStart + replInstSize <= totalLength])
		ifFalse: [^ self primitiveFailFor: PrimErrBadIndex].

	"Array formats (without byteSize bits, if bytes array) must be same "
	arrayFmt < 8
		ifTrue: [arrayFmt = replFmt
				ifFalse: [^ self primitiveFailFor: PrimErrInappropriate]]
		ifFalse: [(arrayFmt bitAnd: 12) = (replFmt bitAnd: 12)
				ifFalse: [^ self primitiveFailFor: PrimErrInappropriate]].

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
StackInterpreter >> primitiveSubtract [

	self pop2AndPushIntegerIfOK: (self stackIntegerValue: 1) - (self stackIntegerValue: 0)
]

{ #category : #'arithmetic largeint primitives' }
StackInterpreter >> primitiveSubtractLargeIntegers [
	"Primitive arithmetic operations for large integers in 64 bit range"
	| integerRcvr integerArg integerArgNegated result oopResult |
	<export: true>
	<var: 'integerRcvr' type: 'sqLong'>
	<var: 'integerArg' type: 'sqLong'>
	<var: 'integerArgNegated' type: 'sqLong'>
	<var: 'result' type: 'sqLong'>

	integerArg := self signed64BitValueOf: (self stackValue: 0).
	integerRcvr := self signed64BitValueOf: (self stackValue: 1).
	self successful ifFalse:
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
	self successful ifTrue:
		[self pop: 2 thenPush: oopResult]
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveSuspend [
	"Primitive. Suspend the receiver, aProcess such that it can be executed again
	by sending #resume. If the given process is not currently running, take it off
	its corresponding list. The primitive returns the list the receiver was previously on."
	| process myList |
	process := self stackTop.
	process = self activeProcess ifTrue:[
		self pop: 1 thenPush: nilObj.
		self transferTo: self wakeHighestPriority.
	] ifFalse:[
		myList := self fetchPointer: MyListIndex ofObject: process.
		"XXXX Fixme. We should really check whether myList is a kind of LinkedList or not
		but we can't easily so just do a quick check for nil which is the most common case."
		myList = nilObj ifTrue:[^self primitiveFail].
		self removeProcess: process fromList: myList.
		self successful ifTrue:[
			self storePointer: MyListIndex ofObject: process withValue: nilObj.
			self pop: 1 thenPush: myList.
		].
	]
]

{ #category : #'control primitives' }
StackInterpreter >> primitiveTerminateTo [
	"Primitive. Terminate up the context stack from the receiver up to but not including
	 the argument, if previousContext is on my Context stack. Make previousContext my
	 sender. This prim has to shadow the code in ContextPart>terminateTo: to be correct."
	| thisCtx currentCtx aContextOrNil contextsFP contextsSP contextsIP nextCntx stackedReceiverOffset 
	  theFP newFP newSP pageToStopOn thePage frameAbove |
	<var: #contextsFP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #newFP type: #'char *'>
	<var: #newSP type: #'char *'>
	<var: #contextsIP type: #usqInt>
	<var: #frameAbove type: #'char *'>
	<var: #contextsSP type: #'char *'>
	<var: #source type: #'char *'>
	<var: #pageToStopOn type: #'StackPage *'>
	<var: #thePage type: #'StackPage *'>

	aContextOrNil := self stackTop.
	(aContextOrNil = nilObj or: [self isContext: aContextOrNil]) ifFalse:
		[^self primitiveFail].
	thisCtx := self stackValue: 1.
	thisCtx = aContextOrNil ifTrue:
		[^self primitiveFail].		

	"All stackPages need to have current head pointers to avoid confusion."
	self externalWriteBackHeadFramePointers.

	"If we're searching for aContextOrNil it might be on a stack page.  Helps to know
	 if we can free a whole page or not, or if we can short-cut the termination."
	(aContextOrNil ~= nilObj and: [self isStillMarriedContext: aContextOrNil])
		ifTrue: [contextsFP := self frameOfMarriedContext: aContextOrNil.
				pageToStopOn := stackPages stackPageFor: contextsFP]
		ifFalse: [pageToStopOn := 0].

	"if thisCtx is married ensure it is a base frame.  Then we can assign its sender."
	(self isStillMarriedContext: thisCtx)
		ifTrue:
			[theFP := self frameOfMarriedContext: thisCtx.
			 "Optimize terminating thisContext.  Move its frame down to be next to
			  aContextOrNil's frame. Common in the exception system and so helps to be fast."
			 (theFP = framePointer
			  and: [pageToStopOn = stackPage]) ifTrue:
				[(self frameCallerFP: theFP) ~= contextsFP ifTrue:
					[stackedReceiverOffset := self frameStackedReceiverOffset: theFP.
					 frameAbove := self findFrameAbove: contextsFP inPage: pageToStopOn.
					 contextsIP := self frameCallerSavedIP: frameAbove.
					 newSP := self frameCallerSP: frameAbove.
					 newFP := newSP - stackedReceiverOffset - BytesPerWord.
					 theFP + stackedReceiverOffset
						to: stackPointer
						by: BytesPerWord negated
						do: [:source|
							newSP := newSP - BytesPerWord.
							stackPages longAt: newSP put: (stackPages longAt: source)].
					 stackPages longAt: newFP + FoxSavedFP put: contextsFP.
					 stackPages longAt: newFP + FoxCallerSavedIP put: contextsIP.
					 self assert: (self isContext: thisCtx).
					 self storePointerUnchecked: SenderIndex
						ofObject: thisCtx
						withValue: (self withSmallIntegerTags: newFP).
					 self storePointerUnchecked: InstructionPointerIndex
						ofObject: thisCtx
						withValue: (self withSmallIntegerTags: contextsFP).
					 framePointer := newFP.
					 stackPointer := newSP].
				self pop: 1.
				self assert: stackPage = stackPages mostRecentlyUsedPage.
				^nil].
			 theFP := self externalEnsureIsBaseFrame: theFP. "May cause a GC!!"
			 currentCtx := self frameCallerContext: theFP.
			 "May also reclaim aContextOrNil's page, hence..."
			 (aContextOrNil ~= nilObj and: [self isStillMarriedContext: aContextOrNil])
				ifTrue: [contextsFP := self frameOfMarriedContext: aContextOrNil.
						pageToStopOn := stackPages stackPageFor: contextsFP]
				ifFalse: [pageToStopOn := 0]]
		ifFalse:
			[currentCtx := self fetchPointer: SenderIndex ofObject: thisCtx].

	(self context: thisCtx hasSender: aContextOrNil) ifTrue:
		["Need to walk the stack freeing stack pages and nilling contexts."
		[currentCtx = aContextOrNil
		 or: [currentCtx = nilObj]] whileFalse:
			[(self isMarriedOrWidowedContext: currentCtx)
				ifTrue:
					[theFP := self frameOfMarriedContext: currentCtx.
					thePage := stackPages stackPageFor: theFP.
					"If externalEnsureIsBaseFrame: above has moved thisContext to its own stack
					 then we will always terminate to a frame on a different page.  But if we are
					 terminating some other context to a context somewhere on the current page
					 we must save the active frames above that context.  Things will look e.g. like this:
		thisCtx			499383332 s MethodContext(ContextPart)>resume:
						499380484 s BlockClosure>ensure:
						499377320 s MethodContext(ContextPart)>handleSignal:
						499373760 s MethodContext(ContextPart)>handleSignal:
						499372772 s MessageNotUnderstood(Exception)>signal
						499369068 s CodeSimulationTests(Object)>doesNotUnderstand: absentMethod
						499368708 s [] in CodeSimulationTests>testDNU
							(sender is 0xbffc2480 I CodeSimulationTests>runSimulated:)
						------------
		framePointer	0xbffc234c M MethodContext(ContextPart)>doPrimitive:method:receiver:args:
						0xbffc2378 M MethodContext(ContextPart)>tryPrimitiveFor:receiver:args:
						0xbffc23ac M MethodContext(ContextPart)>send:to:with:super:
						0xbffc23e4 M MethodContext(ContextPart)>send:super:numArgs:
						0xbffc2418 M MethodContext(InstructionStream)>interpretNextInstructionFor:
						0xbffc2434 M MethodContext(ContextPart)>step
						0xbffc2458 I MethodContext(ContextPart)>runSimulated:contextAtEachStep:
						------------
(499368708's sender)	0xbffc2480 I CodeSimulationTests>runSimulated:
						0xbffc249c M CodeSimulationTests>testDNU
						0xbffc24bc I CodeSimulationTests(TestCase)>performTest
						0xbffc24dc I [] in CodeSimulationTests(TestCase)>runCase
		aContextOrNil	0xbffc24fc M BlockClosure>ensure:
						0xbffc2520 I CodeSimulationTests(TestCase)>runCase
						0xbffc253c M [] in TestResult>runCase:
					When we find this case we move the frames above to a new page by making the
					frame above currentCtx a base frame, i.e. making 0xbffc2458 in the above example
					a base frame.  But in this iteration of the loop we don't move down a frame i.e. currentCtx
					doesn't change on this iteration."
					thePage = stackPage
						ifTrue:
							[frameAbove := self findFrameAbove: theFP inPage: thePage.
							self assert: frameAbove ~= 0.
							frameAbove := self externalEnsureIsBaseFrame: frameAbove. "May cause a GC!! May also reclaim aContextOrNil's page, hence..."
							(aContextOrNil ~= nilObj and: [self isStillMarriedContext: aContextOrNil])
								ifTrue: [contextsFP := self frameOfMarriedContext: aContextOrNil.
										pageToStopOn := stackPages stackPageFor: contextsFP]
								ifFalse: [pageToStopOn := 0]]
						ifFalse:
							[thePage = pageToStopOn
								ifTrue:
									["We're here.  Cut back the stack to aContextOrNil's frame,
									  push its instructionPointer if it's not already a head frame,
									  and we're done."
									 frameAbove := self findFrameAbove: contextsFP inPage: thePage.
									 frameAbove ~= 0 ifTrue:
										[contextsSP := (self frameCallerSP: frameAbove) - BytesPerWord.
										 stackPages longAt: contextsSP put: (self frameCallerSavedIP: frameAbove).
										 self setHeadFP: contextsFP andSP: contextsSP inPage: thePage].
									 currentCtx := aContextOrNil]
								ifFalse:
									["We can free the entire page without further ado."
									 currentCtx := self frameCallerContext: thePage baseFP.
									 "for a short time invariant is violated; assert follows"
									 stackPages freeStackPageNoAssert: thePage]]]
				ifFalse:
					[self assert: (self isContext: currentCtx).
					 nextCntx := self fetchPointer: SenderIndex ofObject: currentCtx.
					 self storePointerUnchecked: SenderIndex ofObject: currentCtx withValue: nilObj.
					 self storePointerUnchecked: InstructionPointerIndex ofObject: currentCtx withValue: nilObj.
					 currentCtx := nextCntx]]].
	self assert: stackPages pageListIsWellFormed.
	(self isMarriedOrWidowedContext: thisCtx)
		ifTrue:
			[self assert: (self checkIsStillMarriedContext: thisCtx currentFP: framePointer).
			 self assert: (self isBaseFrame: (self frameOfMarriedContext: thisCtx)).
			 theFP := self frameOfMarriedContext: thisCtx.
			 self frameCallerContext: theFP put: aContextOrNil]
		ifFalse: [self storePointer: SenderIndex ofObject: thisCtx withValue: aContextOrNil].
	self pop: 1.
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	^nil
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveTestAndSetOwnershipOfCriticalSection [
	"Attempt to test-and-set the ownership of the critical section.  If not owned,
	 set the owner to the current process and answer false. If owned by the
	 current process answer true.  If owned by some other process answer nil."
	| criticalSection owningProcessIndex owningProcess activeProc |
	criticalSection := self stackTop.  "rcvr"
	owningProcessIndex := ExcessSignalsIndex. "CriticalSections are laid out like Semaphores"
	owningProcess := self fetchPointer: owningProcessIndex ofObject: criticalSection.
	activeProc := self activeProcess.
	owningProcess = nilObj ifTrue:
		[self storePointer: owningProcessIndex
			ofObject: criticalSection
			withValue: activeProc.
		 ^self pop: 1 thenPush: falseObj].
	owningProcess = activeProc ifTrue:
		[^self pop: 1 thenPush: trueObj].
	^self pop: 1 thenPush: nilObj
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveTestDisplayDepth [
	"Return true if the host OS does support the given display depth."
	| bitsPerPixel okay|
	bitsPerPixel := self stackIntegerValue: 0.
	self successful ifTrue: [okay := self ioHasDisplayDepth: bitsPerPixel].
	self successful ifTrue: [self pop: 2 thenPushBool: okay"Pop arg+rcvr"]
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveTimesTwoPower [
	| rcvr arg |
	<var: #rcvr type: #double>
	arg := self popInteger.
	rcvr := self popFloat.
	self successful
		ifTrue: [ self pushFloat: (self cCode: 'ldexp(rcvr, arg)' inSmalltalk: [rcvr timesTwoPower: arg]) ]
		ifFalse: [ self unPop: 2 ]
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveTruncated [ 
	| rcvr frac trunc |
	<var: #rcvr type: #double>
	<var: #frac type: #double>
	<var: #trunc type: #double>
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

{ #category : #'system control primitives' }
StackInterpreter >> primitiveUTCMicrosecondClock [
	"Return the value of the microsecond clock as an integer.  The microsecond clock is at
	 least 60 bits wide which means it'll get to around August 38435 before it wraps around."

	self pop: 1 thenPush: (self positive64BitIntegerFor: self ioUTCMicroseconds)
]

{ #category : #'plugin primitives' }
StackInterpreter >> primitiveUnloadModule [
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
StackInterpreter >> primitiveUpdateTimezone [
	"Update the VMs notion of the current timezone.  The VM sets its notion
	 of the timezone once at start-up.  If one wants the Vm to keep its notion
	 up-to-date arrange to invoke tis primitive periodically."
	self ioUpdateVMTimezone
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveVMParameter [
	"Behaviour depends on argument count:
		0 args:	return an Array of VM parameter values;
		1 arg:	return the indicated VM parameter;
		2 args:	set the VM indicated parameter.
	VM parameters are numbered as follows:
		1	end of old-space (0-based, read-only)
		2	end of young-space (read-only)
		3	end of memory (read-only)
		4	nil (was allocationCount (read-only))
		5	nil (was allocations between GCs (read-write)
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
		26  interruptChecksEveryNms - force an ioProcessEvents every N milliseconds (rw)
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
		40  BytesPerWord for this image
		41  imageFormatVersion for the VM
		42	number of stack pages in use
		43	desired number of stack pages (stored in image file header, max 65535)
		44	size of eden, in bytes
		45	desired size of eden, in bytes (stored in image file header)
		46	machine code zone size, in bytes (Cog only; otherwise nil)
		47	desired machine code zone size (Cog only; otherwise nil)
		48	various header flags.  See getCogVMFlags.
		49	max size the image promises to grow the external semaphore table to (0 sets to default, which is 256 as of writing)
		50-55 nil; reserved for VM parameters that persist in the image (such as eden above)
		56	number of process switches since startup (read-only)
		57	number of ioProcessEvents calls since startup (read-only)
		58	number of ForceInterruptCheck calls since startup (read-only)
		59	number of check event calls since startup (read-only)
		60	number of stack page overflows since startup (read-only)
		61	number of stack page divorces since startup (read-only)
		62	compiled code compactions since startup (read-only; Cog only; otherwise nil)
		63	total milliseconds in compiled code compactions since startup (read-only; Cog only; otherwise nil)
		
	Note: Thanks to Ian Piumarta for this primitive."

	| mem paramsArraySize result arg index |
	mem := self startOfMemory.
	paramsArraySize := 63.
	argumentCount = 0 ifTrue:
		[result := self instantiateClass: (self splObj: ClassArray) indexableSize: paramsArraySize.
		self storePointerUnchecked: 0	ofObject: result withValue: (self integerObjectOf: youngStart - mem).
		self storePointerUnchecked: 1	ofObject: result withValue: (self integerObjectOf: freeStart - mem).
		self storePointerUnchecked: 2	ofObject: result withValue: (self integerObjectOf: endOfMemory - mem).
		self storePointerUnchecked: 3	ofObject: result withValue: nilObj "was allocationCount".
		self storePointerUnchecked: 4	ofObject: result withValue: nilObj "allocationsBetweenGCs".
		self storePointerUnchecked: 5	ofObject: result withValue: (self integerObjectOf: tenuringThreshold).
		self storePointerUnchecked: 6	ofObject: result withValue: (self integerObjectOf: statFullGCs).
		self storePointerUnchecked: 7	ofObject: result withValue: (self integerObjectOf: statFullGCUsecs + 500 // 1000).
		self storePointerUnchecked: 8	ofObject: result withValue: (self integerObjectOf: statIncrGCs).
		self storePointerUnchecked: 9	ofObject: result withValue: (self integerObjectOf: statIncrGCUsecs + 500 // 1000).
		self storePointerUnchecked: 10	ofObject: result withValue: (self integerObjectOf: statTenures).
		11 to: 19 do:
			[:i | self storePointerUnchecked: i ofObject: result withValue: ConstZero].
		self storePointerUnchecked: 20	ofObject: result withValue: (self integerObjectOf: rootTableCount).
		self storePointerUnchecked: 21	ofObject: result withValue: (self integerObjectOf: statRootTableOverflows).
		self storePointerUnchecked: 22	ofObject: result withValue: (self integerObjectOf: extraVMMemory).
		self storePointerUnchecked: 23	ofObject: result withValue: (self integerObjectOf: shrinkThreshold).
		self storePointerUnchecked: 24	ofObject: result withValue: (self integerObjectOf: growHeadroom).
		self storePointerUnchecked: 25	ofObject: result withValue: (self integerObjectOf: self ioHeartbeatMilliseconds).
		self storePointerUnchecked: 26	ofObject: result withValue: (self integerObjectOf: statMarkCount).
		self storePointerUnchecked: 27	ofObject: result withValue: (self integerObjectOf: statSweepCount).
		self storePointerUnchecked: 28	ofObject: result withValue: (self integerObjectOf: statMkFwdCount).
		self storePointerUnchecked: 29	ofObject: result withValue: (self integerObjectOf: statCompMoveCount).
		self storePointerUnchecked: 30	ofObject: result withValue: (self integerObjectOf: statGrowMemory).
		self storePointerUnchecked: 31	ofObject: result withValue: (self integerObjectOf: statShrinkMemory).
		self storePointerUnchecked: 32	ofObject: result withValue: (self integerObjectOf: statRootTableCount).
		self storePointerUnchecked: 33	ofObject: result withValue: nilObj "was statAllocationCount".
		self storePointerUnchecked: 34	ofObject: result withValue: (self integerObjectOf: statSurvivorCount).
		self storePointerUnchecked: 35	ofObject: result withValue: (self integerObjectOf: (self microsecondsToMilliseconds: statGCEndUsecs)).
		self storePointerUnchecked: 36	ofObject: result withValue: (self integerObjectOf: statSpecialMarkCount).
		self storePointerUnchecked: 37	ofObject: result withValue: (self integerObjectOf: statIGCDeltaUsecs + 500 // 1000).
		self storePointerUnchecked: 38	ofObject: result withValue: (self integerObjectOf: statPendingFinalizationSignals).
		self storePointerUnchecked: 39	ofObject: result withValue: (self integerObjectOf: BytesPerWord).
		self storePointerUnchecked: 40	ofObject: result withValue: (self integerObjectOf: self imageFormatVersion).
		self storePointerUnchecked: 41	ofObject: result withValue: (self integerObjectOf: numStackPages).
		self storePointerUnchecked: 42	ofObject: result withValue: (self integerObjectOf: desiredNumStackPages).
		self storePointerUnchecked: 43	ofObject: result withValue: (self integerObjectOf: edenBytes).
		self storePointerUnchecked: 44	ofObject: result withValue: (self integerObjectOf: desiredEdenBytes).
		self storePointerUnchecked: 45	ofObject: result withValue: self getCogCodeSize.
		self storePointerUnchecked: 46	ofObject: result withValue: self getDesiredCogCodeSize.
		self storePointerUnchecked: 47	ofObject: result withValue: self getCogVMFlags.
		self storePointerUnchecked: 48	ofObject: result withValue: (self integerObjectOf: self ioGetMaxExtSemTableSize).
		49 to: 54 do:
			[:i | self storePointerUnchecked: i ofObject: result withValue: nilObj].
		self storePointerUnchecked: 55	ofObject: result withValue: (self integerObjectOf: statProcessSwitch).
		self storePointerUnchecked: 56	ofObject: result withValue: (self integerObjectOf: statIOProcessEvents).
		self storePointerUnchecked: 57	ofObject: result withValue: (self integerObjectOf: statForceInterruptCheck).
		self storePointerUnchecked: 58	ofObject: result withValue: (self integerObjectOf: statCheckForEvents).
		self storePointerUnchecked: 59	ofObject: result withValue: (self integerObjectOf: statStackOverflow).
		self storePointerUnchecked: 60	ofObject: result withValue: (self integerObjectOf: statStackPageDivorce).
		self storePointerUnchecked: 61	ofObject: result withValue: self getCodeCompactionCount.
		self storePointerUnchecked: 62	ofObject: result withValue: self getCodeCompactionMSecs.
    
		self pop: 1 thenPush: result.
		^nil].

	arg := self stackTop.
	(self isIntegerObject: arg) ifFalse: [^self primitiveFailFor: PrimErrBadArgument].
	arg := self integerValueOf: arg.
	argumentCount = 1 ifTrue:	 "read VM parameter"
		[(arg < 1 or: [arg > paramsArraySize]) ifTrue: [^self primitiveFailFor: PrimErrBadIndex].
		result := nilObj.
		arg = 1		ifTrue: [result := self integerObjectOf: youngStart - mem].
		arg = 2		ifTrue: [result := self integerObjectOf: freeStart - mem].
		arg = 3		ifTrue: [result := self integerObjectOf: endOfMemory - mem].
		arg = 4		ifTrue: [result := nilObj "was allocationCount"].
		arg = 5		ifTrue: [result := nilObj "was allocationsBetweenGCs"].
		arg = 6		ifTrue: [result := self integerObjectOf: tenuringThreshold].
		arg = 7		ifTrue: [result := self integerObjectOf: statFullGCs].
		arg = 8		ifTrue: [result := self integerObjectOf: statFullGCUsecs + 500 // 1000].
		arg = 9		ifTrue: [result := self integerObjectOf: statIncrGCs].
		arg = 10	ifTrue: [result := self integerObjectOf: statIncrGCUsecs + 500 // 1000].
		arg = 11	ifTrue: [result := self integerObjectOf: statTenures].
		(arg between: 12 and: 20) ifTrue: [result := ConstZero].
		arg = 21	ifTrue: [result := self integerObjectOf: rootTableCount].
		arg = 22	ifTrue: [result := self integerObjectOf: statRootTableOverflows].
		arg = 23	ifTrue: [result := self integerObjectOf: extraVMMemory].
		arg = 24	ifTrue: [result := self integerObjectOf: shrinkThreshold].
		arg = 25	ifTrue: [result := self integerObjectOf: growHeadroom].
		arg = 26	ifTrue: [result := self integerObjectOf: self ioHeartbeatMilliseconds].
		arg = 27	ifTrue: [result := self integerObjectOf: statMarkCount].
		arg = 28	ifTrue: [result := self integerObjectOf: statSweepCount].
		arg = 29	ifTrue: [result := self integerObjectOf: statMkFwdCount].
		arg = 30	ifTrue: [result := self integerObjectOf: statCompMoveCount].
		arg = 31	ifTrue: [result := self integerObjectOf: statGrowMemory].
		arg = 32	ifTrue: [result := self integerObjectOf: statShrinkMemory].
		arg = 33	ifTrue: [result := self integerObjectOf: statRootTableCount].
		arg = 34	ifTrue: [result := nilObj "was statAllocationCount"].
		arg = 35	ifTrue: [result := self integerObjectOf: statSurvivorCount].
		arg = 36  	ifTrue: [result := self integerObjectOf: (self microsecondsToMilliseconds: statGCEndUsecs)].
		arg = 37  	ifTrue: [result := self integerObjectOf: statSpecialMarkCount].
		arg = 38  	ifTrue: [result := self integerObjectOf: statIGCDeltaUsecs + 500 // 1000].
		arg = 39  	ifTrue: [result := self integerObjectOf: statPendingFinalizationSignals].
		arg = 40  	ifTrue: [result := self integerObjectOf: BytesPerWord].
		arg = 41  	ifTrue: [result := self integerObjectOf: self imageFormatVersion].
		arg = 42  	ifTrue: [result := self integerObjectOf: numStackPages].
		arg = 43  	ifTrue: [result := self integerObjectOf: desiredNumStackPages].
		arg = 44  	ifTrue: [result := self integerObjectOf: edenBytes].
		arg = 45  	ifTrue: [result := self integerObjectOf: desiredEdenBytes].
		arg = 46	ifTrue: [result := self getCogCodeSize].
		arg = 47	ifTrue: [result := self getDesiredCogCodeSize].
		arg = 48	ifTrue: [result := self getCogVMFlags].
		arg = 49	ifTrue: [result := self integerObjectOf: self ioGetMaxExtSemTableSize].
		(arg between: 50 and: 55) ifTrue: [result := nilObj].
		arg = 56  	ifTrue: [result := self integerObjectOf: statProcessSwitch].
		arg = 57  	ifTrue: [result := self integerObjectOf: statIOProcessEvents].
		arg = 58  	ifTrue: [result := self integerObjectOf: statForceInterruptCheck].
		arg = 59  	ifTrue: [result := self integerObjectOf: statCheckForEvents].
		arg = 60  	ifTrue: [result := self integerObjectOf: statStackOverflow].
		arg = 61  	ifTrue: [result := self integerObjectOf: statStackPageDivorce].
		arg = 62	ifTrue: [result := self getCodeCompactionCount].
		arg = 63	ifTrue: [result := self getCodeCompactionMSecs].
		
		self pop: 2 thenPush: result.
		^nil].

	"write a VM parameter"
	argumentCount = 2 ifFalse: [^self primitiveFailFor: PrimErrBadNumArgs].
	index := self stackValue: 1.
	(self isIntegerObject: index) ifFalse: [^self primitiveFailFor: PrimErrBadArgument].
	index := self integerValueOf: index.
	(index <= 0 or: [index > 63]) ifTrue: [^self primitiveFailFor: PrimErrBadIndex].
	self success: false.
	index = 5 ifTrue: [
		"Was:
		result := allocationsBetweenGCs.
		allocationsBetweenGCs := arg."
		"Ignore for now, because old images won't start up otherwise.
		 See 44 & 45 for eden size setting."
		result := nilObj.
		self initPrimCall].
	index = 6 ifTrue: [
		result := tenuringThreshold.
		tenuringThreshold := arg.
		self initPrimCall].
	index = 23 ifTrue: [
		result := extraVMMemory.
		extraVMMemory := arg.
		self initPrimCall].
	index = 24 ifTrue: [
		result := shrinkThreshold.
		arg > 0 ifTrue:[
			shrinkThreshold := arg.
			self initPrimCall]].
	index = 25 ifTrue: [
		result := growHeadroom.
		arg > 0 ifTrue:[
			growHeadroom := arg.
			self initPrimCall]].
	index = 26 ifTrue: [
		arg > 1 ifTrue:[
			result := self ioHeartbeatMilliseconds.
			self ioSetHeartbeatMilliseconds: arg.
			self initPrimCall]].
	index = 43 ifTrue: [
		(arg >= 0 and: [arg <= 65535]) ifTrue:[
			result := desiredNumStackPages.
			desiredNumStackPages := arg.
			self initPrimCall]].
	index = 45 ifTrue: [
		(arg >= 0) ifTrue:[
			result := desiredEdenBytes.
			desiredEdenBytes := arg.
			self initPrimCall]].
	(index = 47 and: [self isCog]) ifTrue: [
		(arg >= 0) ifTrue:[
			result := self getDesiredCogCodeSize.
			self setDesiredCogCodeSize: arg.
			self initPrimCall]].
	(index = 48 and: [self isCog]) ifTrue: [
		(arg >= 0) ifTrue:[
			result := self getCogVMFlags.
			self initPrimCall. "i.e. setCogVMFlags: can fail"
			self setCogVMFlags: arg]].
	index = 49 ifTrue:
		[(arg >= 0 and: [arg <= 65535]) ifTrue:
			[result := self ioGetMaxExtSemTableSize.
			self initPrimCall. "i.e. ioSetMaxExtSemTableSize: is allowed to fail"
			self setMaxExtSemSizeTo: arg]].

	self successful ifTrue:
		[self pop: 3 thenPush: (self integerObjectOf: result).  "return old value"
		^ nil].

	self primitiveFailFor: PrimErrInappropriate  "attempting to write a read-only or non-existent parameter"
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveVMPath [
	"Return a string containing the path name of VM's directory."

	| s sz |
	sz := self vmPathSize.
	s := self instantiateClass: (self splObj: ClassString) indexableSize: sz.
	self vmPathGet: (s + BaseHeaderSize) Length: sz.
	self pop: 1 thenPush: s.

]

{ #category : #'process primitives' }
StackInterpreter >> primitiveVMProfileInfoInto [
	"Primitive. Answer whether the profiler is running or not.
	 If the argument is an Array of suitable size fill it with the following information:
		1. the addresses of the first element of the VM histogram (the first address in the executable)
		2. the address following the last element (the last address in the executable, excluding dynamically linked libraries)
		3. the size of the VM histogram in bins (each bin is a 4 byte unsigned long)
		4. the size of the VM histogram in bins (each bin is a 4 byte unsigned long)"
	| info running exeStart exeLimit vmBins easBins |
	<var: #exeStart type: #'char *'>
	<var: #exeLimit type: #'char *'>
	<var: #vmBins type: #long>
	<var: #easBins type: #long>
	self success: argumentCount = 1.
	self successful ifTrue:
		[info := self stackObjectValue: 0.
		 info ~= nilObj ifTrue:
			[self assertClassOf: info is: (self splObj: ClassArray).
			 self success: (self fetchWordLengthOf: info) >= 4]].
	self successful ifFalse:
		[^nil].
	
	self cCode: 'ioProfileStatus(&running,&exeStart,&exeLimit,0,&vmBins,0,&easBins)'
		inSmalltalk: [running := exeStart := exeLimit := vmBins := easBins := 0].
	info ~= nilObj ifTrue:
		[self storePointerUnchecked: 0
			ofObject: info
			withValue: (self integerObjectOf: (self oopForPointer: exeStart)).
		self storePointerUnchecked: 1
			ofObject: info
			withValue: (self integerObjectOf: (self oopForPointer: exeLimit)).
		self storePointerUnchecked: 2
			ofObject: info
			withValue: (self integerObjectOf: vmBins).
		self storePointerUnchecked: 3
			ofObject: info
			withValue: (self integerObjectOf: easBins)].
	self pop: 2 thenPushBool: running
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveVMProfileSamplesInto [
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

{ #category : #'system control primitives' }
StackInterpreter >> primitiveVoidReceiver [
	"Potentially crash the VM by voiding the receiver.  A subsequent inst var
	 access in the caller's frame should indirect through a null pointer."
	<export: true>
	stackPages longAt: (self frameReceiverOffset: framePointer) put: 0
]

{ #category : #'system control primitives' }
StackInterpreter >> primitiveVoidVMState [
	"Void all internal VM state in the stack and machine code zones"
	| activeContext |

	self push: instructionPointer.
	activeContext := self voidVMStateForSnapshot.
	self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
	^0
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveWait [
	| sema excessSignals activeProc |
	sema := self stackTop.  "rcvr"
	excessSignals := self fetchInteger: ExcessSignalsIndex ofObject: sema.
	excessSignals > 0
		ifTrue:
			[self storeInteger: ExcessSignalsIndex ofObject: sema withValue: excessSignals - 1]
		ifFalse:
			[activeProc := self activeProcess.
			 self addLastLink: activeProc toList: sema.
			 self transferTo: self wakeHighestPriority]
]

{ #category : #'process primitives' }
StackInterpreter >> primitiveYield [
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
StackInterpreter >> print: s [
	"For testing in Smalltalk, this method should be overridden in a subclass."
	<api>
	<var: #s type: #'char *'>
	self cCode: 'printf("%s", s)'.
]

{ #category : #'debug printing' }
StackInterpreter >> printActivationNameFor: aMethod receiver: anObject isBlock: isBlock firstTemporary: maybeMessage [
	| methClass methodSel |
	<inline: false>
	isBlock ifTrue:
		[self print: '[] in '].
	methClass := self findClassOfMethod: aMethod forReceiver: anObject.
	methodSel := self findSelectorOfMethod: aMethod forReceiver: anObject.
	(self fetchClassOf: anObject) = methClass
		ifTrue: [self printNameOfClass: methClass count: 5]
		ifFalse:
			[self printNameOfClass: (self fetchClassOf: anObject) count: 5.
			 self print: '('.
			 self printNameOfClass: methClass count: 5.
			 self print: ')'].
	self print: '>'.
	methodSel = nilObj
		ifTrue: [self print: '?']
		ifFalse: [self printStringOf: methodSel].
	(methodSel = (self splObj: SelectorDoesNotUnderstand)
	and: [(self addressCouldBeObj: maybeMessage)
	and: [(self fetchClassOf: maybeMessage) = (self splObj: ClassMessage)]]) ifTrue:
		["print arg message selector"
		methodSel := self fetchPointer: MessageSelectorIndex ofObject: maybeMessage.
		self print: ' '.
		self printStringOf: methodSel]
]

{ #category : #'debug printing' }
StackInterpreter >> printAllStacks [
	"Print all the stacks of all running processes, including those that are currently suspended."
	<api>
	| oop classObj proc semaphoreClass mutexClass schedLists p processList |
	<inline: false>
	proc := self activeProcess.
	self printNameOfClass: (self fetchClassOf: proc) count: 5; space; printHex: proc.
	self print: ' priority '; printNum: (self quickFetchInteger: PriorityIndex ofObject: proc); cr.
	self printCallStackFP: framePointer. "first the current activation"
	semaphoreClass := self classSemaphore.
	mutexClass := self classMutex.
	oop := self firstObject.
	[self oop: oop isLessThan: freeStart] whileTrue:
		[classObj := self fetchClassOfNonInt: oop.
		 (classObj = semaphoreClass
		  or: [classObj = mutexClass]) ifTrue:
			[self printProcsOnList: oop].
		 oop := self objectAfter: oop].
	schedLists := self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	p := highestRunnableProcessPriority = 0
			ifTrue: [self fetchWordLengthOf: schedLists]
			ifFalse: [highestRunnableProcessPriority].
	p - 1 to: 0 by: -1 do:
		[:pri|
		processList := self fetchPointer: pri ofObject: schedLists.
		(self isEmptyList: processList) ifFalse:
			[self cr; print: 'processes at priority '; printNum: pri + 1.
			 self printProcsOnList: processList]]
]

{ #category : #'debug printing' }
StackInterpreter >> printCallStack [
	<inline: false>
	self printCallStackFP: framePointer
]

{ #category : #'debug printing' }
StackInterpreter >> printCallStackFP: theFP [
	| context |
	<inline: false>
	<var: #theFP type: #'char *'>
	context := self shortReversePrintFrameAndCallers: theFP.
	[context = nilObj] whileFalse:
		[(self isMarriedOrWidowedContext: context)
			ifTrue:
				[(self checkIsStillMarriedContext: context currentFP: framePointer) ifFalse:
					[self shortPrintContext: context.
					 ^nil].
				 context := self shortReversePrintFrameAndCallers: (self frameOfMarriedContext: context)]
			ifFalse:
				[context := self printContextCallStackOf: context]]
]

{ #category : #'debug printing' }
StackInterpreter >> printCallStackOf: aContext currentFP: currFP [
	| ctxt theFP thePage |
	<inline: false>
	<var: #currFP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	ctxt := aContext.
	[ctxt = nilObj] whileFalse:
		[(self isMarriedOrWidowedContext: ctxt)
			ifFalse:
				[self shortPrintContext: ctxt.
				 ctxt := self fetchPointer: SenderIndex ofObject: ctxt]
			ifTrue:
				[theFP := self frameOfMarriedContext: ctxt.
				 (self checkIsStillMarriedContext: ctxt currentFP: currFP)
					ifTrue:
						[thePage := stackPages stackPageFor: theFP.
						 (stackPages isFree: thePage) ifTrue:
							[self printHexPtr: theFP; print: ' is on a free page?!'; cr.
							 ^nil].
						 self shortPrintFrameAndCallers: theFP.
						 theFP := thePage baseFP.
						 ctxt := self frameCallerContext: theFP]
					ifFalse: [self print: 'widowed caller frame '; print: theFP; cr.
							^nil]]]
]

{ #category : #'debug printing' }
StackInterpreter >> printChar: aByte [
	<api>
	"For testing in Smalltalk, this method should be overridden in a subclass."
	self putchar: aByte.
]

{ #category : #'debug printing' }
StackInterpreter >> printContext: aContext [
	| sender ip sp |
	<inline: false>
	self shortPrintContext: aContext.
	sender := self fetchPointer: SenderIndex ofObject: aContext.
	ip := self fetchPointer: InstructionPointerIndex ofObject: aContext.
	(self isIntegerObject: sender)
		ifTrue:
			[(self checkIsStillMarriedContext: aContext currentFP: framePointer)
				ifTrue: [self print: 'married (assuming framePointer valid)'; cr]
				ifFalse: [self print: 'widdowed (assuming framePointer valid)'; cr].
			self print: 'sender   '; printNum: sender; print: ' (';
				printHexPtr: (self withoutSmallIntegerTags: sender); printChar: $); cr.
			 self print: 'ip       '; printNum: ip; print: ' (';
				printHexPtr: (self withoutSmallIntegerTags: ip); printChar: $); cr]
		ifFalse:
			[self print: 'sender   '; shortPrintOop: sender.
			 self print: 'ip       '; printNum: ip; print: ' ('; printNum: (self integerValueOf: ip); printHex: (self integerValueOf: ip); printChar: $); cr].
	sp := self fetchPointer: StackPointerIndex ofObject: aContext.
	self print: 'sp       '; printNum: sp; print: ' ('; printNum: (self integerValueOf: sp); printChar: $); cr.
	self print: 'method   '; shortPrintOop: (self fetchPointer: MethodIndex ofObject: aContext).
	self print: 'closure  '; shortPrintOop: (self fetchPointer: ClosureIndex ofObject: aContext).
	self print: 'receiver '; shortPrintOop: (self fetchPointer: ReceiverIndex ofObject: aContext).
	sp := self integerValueOf: sp.
	1 to: sp do:
		[:i|
		self print: '       '; printNum: i; space; shortPrintOop: (self fetchPointer: ReceiverIndex + i ofObject: aContext)]
]

{ #category : #'debug printing' }
StackInterpreter >> printContextCallStackOf: aContext [
	"Print the call stack of aContext until it links to a frame."
	| ctxt |
	<inline: false>
	ctxt := aContext.
	[ctxt = nilObj or: [self isMarriedOrWidowedContext: ctxt]] whileFalse:
		[self shortPrintContext: ctxt.
		 ctxt := self fetchPointer: SenderIndex ofObject: ctxt].
	^ctxt
]

{ #category : #'debug printing' }
StackInterpreter >> printExternalHeadFrame [
	<inline: false>
	self printFrame: framePointer WithSP: stackPointer
]

{ #category : #'debug printing' }
StackInterpreter >> printFloat: f [
	"For testing in Smalltalk, this method should be overridden in a subclass."
	<cmacro: '(f) printf("%g", f)'>
	self print: f
]

{ #category : #'debug printing' }
StackInterpreter >> printFrame: theFP [
	| thePage theSP |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	theFP = framePointer
		ifTrue: [theSP := stackPointer]
		ifFalse:
			[thePage := stackPages stackPageFor: theFP.
			 (stackPages isFree: thePage) ifTrue:
				[self printHexPtr: theFP; print: ' is on a free page?!'; cr.
				 ^nil].
			 theSP := self findSPOrNilOf: theFP
						on: thePage
						startingFrom: ((thePage = stackPage
									and: [framePointer < thePage headFP])
										ifTrue: [framePointer]
										ifFalse: [thePage headFP])].
	theSP isNil ifTrue:
		[self print: 'could not find sp; using bogus value'; cr.
		 theSP := theFP + FoxReceiver].
	self printFrame: theFP WithSP: theSP
]

{ #category : #'debug printing' }
StackInterpreter >> printFrame: theFP WithSP: theSP [
	| theMethod numArgs topThing |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #addr type: #'char *'>
	theMethod := self frameMethod: theFP.
	numArgs := self frameNumArgs: theFP.
	self shortPrintFrame: theFP.
	self printFrameOop: 'rcvr/clsr'
		at: theFP + FoxCallerSavedIP + ((numArgs + 1) * BytesPerWord).
	numArgs to: 1 by: -1 do:
		[:i| self printFrameOop: 'arg' at: theFP + FoxCallerSavedIP + (i * BytesPerWord)].
	self printFrameThing: 'cllr ip/ctxt' at: theFP + FoxCallerSavedIP.
	self printFrameThing: 'saved fp' at: theFP + FoxSavedFP.
	self printFrameOop: 'method' at: theFP + FoxMethod.
	self printFrameFlagsForFP: theFP.
	self printFrameThing: 'context' at: theFP + FoxThisContext.
	self printFrameOop: 'receiver' at: theFP + FoxReceiver.
	topThing := stackPages longAt: theSP.
	(topThing >= theMethod
	 and: [topThing <= (theMethod + (self sizeBitsOfSafe: theMethod))])
		ifTrue:
			[theFP + FoxReceiver - BytesPerWord to: theSP + BytesPerWord by: BytesPerWord negated do:
				[:addr|
				self printFrameOop: 'temp/stck' at: addr].
			self printFrameThing: 'frame ip' at: theSP]
		ifFalse:
			[theFP + FoxReceiver - BytesPerWord to: theSP by: BytesPerWord negated do:
				[:addr|
				self printFrameOop: 'temp/stck' at: addr]]
]

{ #category : #'debug printing' }
StackInterpreter >> printFrameAndCallers: theFP SP: theSP [
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	theFP == 0 ifTrue: [^nil].
	(self isBaseFrame: theFP) ifFalse:
		[self printFrameAndCallers: (self frameCallerFP: theFP)
			SP: (self frameCallerSP: theFP)].
	self cr.
	self printFrame: theFP WithSP: theSP
]

{ #category : #'debug printing' }
StackInterpreter >> printFrameFlagsForFP: theFP [
	| address it |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #address type: #'char *'>
	address := theFP + FoxFrameFlags.
	it := stackPages longAt: address.
	self printHexPtr: address;
		print: ':       flags: ';
		printHex: it.
	it ~= 0 ifTrue:
		[self printChar: $=; printNum: it].
	self print: '  numArgs: '; printNum: (self frameNumArgs: theFP);
		print: '  hasContext: '; printNum: (self frameHasContext: theFP);
		print: '  isBlock: '; printNum: (self frameIsBlockActivation: theFP);
		cr
]

{ #category : #'debug printing' }
StackInterpreter >> printFrameOop: name at: address [
	| it |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	it := stackPages longAt: address.
	self printHexPtr: address;
		printChar: $:.
	1 to: 12 - (self strlen: name) do: [:i| self printChar: $ ].
	self print: name;
		print: ': ';
		printHex: it.
	self tab;
		printOopShort: it;
		cr
]

{ #category : #'debug printing' }
StackInterpreter >> printFrameOop: name index: idx at: address [
	| it |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	it := stackPages longAt: address.
	self printHexPtr: address;
		printChar: $:.
	1	to: 11 - (self strlen: name) - (self log10: idx) floor
		do: [:i| self printChar: $ ].
	self print: name;
		printNum: idx;
		print: ': ';
		printHex: it.
	self tab;
		printOopShort: it;
		cr
]

{ #category : #'debug printing' }
StackInterpreter >> printFrameThing: name at: address [
	| it len |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	it := stackPages longAt: address.
	self printHexPtr: address;
		printChar: $:.
	len := self strlen: name.
	1 to: 12 - len do: [:i| self space].
	self print: name;
		print: ': ';
		printHex: it.
	it ~= 0 ifTrue:
		[self printChar: $=.
		 it = nilObj
			ifTrue: [self print: 'nil']
			ifFalse:
				[self printNum: it]].
	self cr
]

{ #category : #'debug printing' }
StackInterpreter >> printFramesInPage: thePage [
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	self printFrameAndCallers: thePage headFP SP: thePage headSP
]

{ #category : #'debug printing' }
StackInterpreter >> printHeadFrame [
	<inline: false>
	self printFrame: localFP WithSP: localSP
]

{ #category : #'debug printing' }
StackInterpreter >> printHex: n [
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
StackInterpreter >> printHexPtr: p [
	"Print n in hex, passed to 10 characters in the form '    0x1234'"
	<inline: true>
	<var: #p type: #'void *'>
	self printHex: (self oopForPointer: p)
]

{ #category : #'debug printing' }
StackInterpreter >> printMemField: memField name: name size: length [
	<var: #memField type: #usqInt>
	<var: #name type: #'char *'>
	self print: name; tab; printHexPtr: memField;
		printChar: $/; printNum: (self oopForPointer: memField);
		print: ' ='; printHex: length.
	length ~= 0 ifTrue:
		[self printChar: $/; printNum: length].
	self cr
]

{ #category : #'debug printing' }
StackInterpreter >> printMemory [
	self printMemField: self startOfMemory name: 'memory      ' size: youngStart - self startOfMemory.
	self printMemField: youngStart name: 'youngStart  ' size: freeStart - youngStart.
	freeStart <= scavengeThreshold
		ifTrue:
			[self printMemField: freeStart name: 'freeStart   ' size: reserveStart - freeStart.
			 self printMemField: scavengeThreshold name: 'scavenge@   ' size: scavengeThreshold-freeStart]
		ifFalse:
			[self printMemField: scavengeThreshold name: 'scavenge@   ' size: scavengeThreshold-freeStart.
			 self printMemField: freeStart name: 'freeStart   ' size: reserveStart - freeStart].
	self printMemField: reserveStart name: 'reserveStart' size: endOfMemory - reserveStart.
	self printMemField: endOfMemory name: 'endOfMemory ' size: memoryLimit - endOfMemory.
	self printMemField: memoryLimit name: 'memoryLimit ' size: 0
]

{ #category : #'debug printing' }
StackInterpreter >> printNameOfClass: classOop count: cnt [
	"Details: The count argument is used to avoid a possible infinite recursion if classOop is a corrupted object."
	<inline: false>
	(classOop = 0 or: [cnt <= 0]) ifTrue: [^self print: 'bad class'].
	((self sizeBitsOf: classOop) = metaclassSizeBytes
	  and: [metaclassSizeBytes >= (6 * BytesPerWord)])	"(Metaclass instSize * 4)"
		ifTrue: [self printNameOfClass: (self fetchPointer: 5 "thisClass" ofObject: classOop) count: cnt - 1.
				self print: ' class']
		ifFalse: [self printStringOf: (self fetchPointer: 6 "name" ofObject: classOop)]
]

{ #category : #'debug printing' }
StackInterpreter >> printNum: n [
	"For testing in Smalltalk, this method should be overridden in a subclass."

	self cCode: 'printf("%ld", (long) n)'.
]

{ #category : #'debug printing' }
StackInterpreter >> printOop: oop [
	| cls fmt lastIndex startIP bytecodesPerLine |
	<inline: false>
	self printHex: oop.
	(self isIntegerObject: oop) ifTrue:
		[^self
			cCode: 'printf("=%ld\n", integerValueOf(oop))'
			inSmalltalk: [self print: (self shortPrint: oop); cr]].
	(oop between: self startOfMemory and: freeStart) ifFalse:
		[self printHex: oop; print: ' is not on the heap'; cr.
		 ^nil].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[self printHex: oop; print: ' is misaligned'; cr.
		 ^nil].
	self print: ': a(n) '.
	self printNameOfClass: (cls := self fetchClassOfNonInt: oop) count: 5.
	self cr.
	cls = (self splObj: ClassFloat) ifTrue:
		[self printFloat: (self dbgFloatValueOf: oop); cr.
		 ^nil].
	fmt := self formatOf: oop.
	(fmt > 4 and: [fmt < 12]) ifTrue:
		[^self printStringOf: oop].
	lastIndex := 64 min: (startIP := (self lastPointerOf: oop) / BytesPerWord).
	lastIndex > 0 ifTrue:
		[1 to: lastIndex do:
			[:index|
			self cCode: 'printHex(fetchPointerofObject(index - 1, oop)); putchar('' '')'
				inSmalltalk: [self space; print: (self fetchPointer: index - 1 ofObject: oop) printString; space.
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
StackInterpreter >> printOopShort: oop [
	<var: #name type: #'char *'>
	self printOopShortInner: oop.
	self flush
]

{ #category : #'debug printing' }
StackInterpreter >> printOopShortInner: oop [
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
	(oop between: self startOfMemory and: freeStart) ifFalse:
		[self printHex: oop; print: ' is not on the heap'.
		 ^nil].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[self printHex: oop; print: ' is misaligned'.
		 ^nil].
	(self isFloatObject: oop) ifTrue:
		[self printFloat: (self dbgFloatValueOf: oop).
		 ^nil].
	classOop := self fetchClassOf: oop.
	(self sizeBitsOf: classOop) = metaclassSizeBytes ifTrue:
		[self printNameOfClass: oop count: 5.
		 ^nil].
	oop = nilObj ifTrue: [self print: 'nil'. ^nil].
	oop = trueObj ifTrue: [self print: 'true'. ^nil].
	oop = falseObj ifTrue: [self print: 'false'. ^nil].
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
	self cCode: 'printf("a(n) %.*s", nameLen, name)'
		inSmalltalk: [self print: 'a(n) '; print: name]
]

{ #category : #'debug printing' }
StackInterpreter >> printPageHeadFrame [
	<inline: false>
	self printFrame: stackPage headFP WithSP: stackPage headSP
]

{ #category : #'debug printing' }
StackInterpreter >> printProcessStack: aProcess [
	<inline: false>
	| ctx |
	self cr; printNameOfClass: (self fetchClassOf: aProcess) count: 5; space; printHex: aProcess.
	self print: ' priority '; printNum: (self quickFetchInteger: PriorityIndex ofObject: aProcess); cr.
	ctx := self fetchPointer: SuspendedContextIndex ofObject: aProcess.
	ctx = nilObj ifFalse:
		[self printCallStackOf: ctx currentFP: framePointer]
]

{ #category : #'debug printing' }
StackInterpreter >> printProcsOnList: procList [
	<inline: false>
	| proc |
	proc := self fetchPointer: FirstLinkIndex ofObject: procList.
	[proc = nilObj] whileFalse:
		[self printProcessStack: proc.
		 proc := self fetchPointer: NextLinkIndex ofObject: proc]
]

{ #category : #'debug printing' }
StackInterpreter >> printStackPage: page [
	<inline: false>
	<var: #page type: #'StackPage *'>
	self print: 'page '; printHexPtr: (self cCode: [page] inSmalltalk: [page baseAddress]);
		print: ' ('; printNum: (stackPages pageIndexFor: page realStackLimit);
		print: ')  (trace: '; printNum: page trace; printChar: $).
	(stackPages isFree: page) ifTrue:
		[self print: ' (free)'].
	page = stackPages mostRecentlyUsedPage ifTrue:
		[self print: ' (MRU)'].
	self cr; tab;
		printHexPtr: page baseAddress; print: ' - ';
		printHexPtr: page realStackLimit; print: ' - ';
		printHexPtr: page lastAddress.
	(stackPages isFree: page) ifFalse:
		[self cr; tab; print: 'baseFP '; printHexPtr: page baseFP.
		 self "cr;" tab; print: 'headFP '; printHexPtr: page headFP.
		 self "cr;" tab; print: 'headSP '; printHexPtr: page headSP].
	self cr; tab; print: 'prev '; printHexPtr: (self cCode: 'page->prevPage' inSmalltalk: [page prevPage baseAddress]);
		print: ' ('; printNum: (stackPages pageIndexFor: page prevPage realStackLimit); printChar: $).
	self tab; print: 'next '; printHexPtr: (self cCode: 'page->nextPage' inSmalltalk: [page nextPage baseAddress]);
		print: ' ('; printNum: (stackPages pageIndexFor: page nextPage realStackLimit); printChar: $).
	self cr
]

{ #category : #'debug printing' }
StackInterpreter >> printStackPageList [
	| page |
	<inline: false>
	<var: #page type: #'StackPage *'>
	page := stackPages mostRecentlyUsedPage.
	[self printStackPage: page.
	 self cr.
	 (page := page prevPage) ~= stackPages mostRecentlyUsedPage] whileTrue
]

{ #category : #'debug printing' }
StackInterpreter >> printStackPageListInUse [
	| page |
	<inline: false>
	<var: #page type: #'StackPage *'>
	page := stackPages mostRecentlyUsedPage.
	[(stackPages isFree: page) ifFalse:
		[self printStackPage: page.
		 self cr].
	 (page := page prevPage) ~= stackPages mostRecentlyUsedPage] whileTrue
]

{ #category : #'debug printing' }
StackInterpreter >> printStackPages [
	0 to: numStackPages - 1 do:
		[:i|
		self printStackPage: (stackPages stackPageAt: i).
		self cr]
]

{ #category : #'debug printing' }
StackInterpreter >> printStackPagesInUse [
	0 to: numStackPages - 1 do:
		[:i|
		(stackPages isFree: (stackPages stackPageAt: i)) ifFalse:
			[self printStackPage: (stackPages stackPageAt: i).
			 self cr]]
]

{ #category : #'debug printing' }
StackInterpreter >> printStringOf: oop [
	| fmt cnt i |
	<inline: false>
	(self isIntegerObject: oop) ifTrue:
		[^nil].
	(oop between: self startOfMemory and: freeStart) ifFalse:
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
StackInterpreter >> printUnbalancedStack: primIdx [
	<inline: false>
	self print: 'Stack unbalanced after '.
	self successful 
		ifTrue:[self print:'successful primitive '] 
		ifFalse:[self print: 'failed primitive '].
	self printNum: primIdx.
	self cr.
		
]

{ #category : #'internal interpreter access' }
StackInterpreter >> push: object [
	"In the StackInterpreter stacks grow down."
	| sp |
	<inline: true>
	<var: #sp type: #'char *'>
	stackPages longAt: (sp := stackPointer - BytesPerWord) put: object.
	stackPointer := sp
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushActiveContextBytecode [
	| ourContext |
	ourContext := self ensureFrameIsMarried: localFP SP: localSP.
	self fetchNextBytecode.
	self internalPush: ourContext
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pushBool: trueOrFalse [

	trueOrFalse
		ifTrue: [ self push: trueObj ]
		ifFalse: [ self push: falseObj ].
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushClosureCopyCopiedValuesBytecode [
	"The compiler has pushed the values to be copied, if any.  Find numArgs and numCopied in the byte following.
	 Create a Closure with space for the copiedValues and pop numCopied values off the stack into the closure.
	 Set numArgs as specified, and set startpc to the pc following the block size and jump over that code."
	| newClosure numArgsNumCopied numArgs numCopied blockSize context |
	numArgsNumCopied := self fetchByte.
	numArgs := numArgsNumCopied bitAnd: 16rF.
	numCopied := numArgsNumCopied bitShift: -4.
	"Split blockSize := (self fetchByte * 256) + self fetchByte. into two because evaluation order in C is undefined."
	blockSize := self fetchByte << 8.
	blockSize := blockSize + self fetchByte.
	"No need to record the pushed copied values in the outerContext."
	context := self ensureFrameIsMarried: localFP SP: localSP + (numCopied * BytesPerWord).
	newClosure := self
					closureIn: context
					numArgs: numArgs
					instructionPointer: (self oopForPointer: localIP) + 2 - (method+BaseHeaderSize)
					numCopiedValues: numCopied.
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
StackInterpreter >> pushConstantFalseBytecode [

	self fetchNextBytecode.
	self internalPush: falseObj.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantMinusOneBytecode [

	self fetchNextBytecode.
	self internalPush: ConstMinusOne.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantNilBytecode [

	self fetchNextBytecode.
	self internalPush: nilObj.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantOneBytecode [

	self fetchNextBytecode.
	self internalPush: ConstOne.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantTrueBytecode [

	self fetchNextBytecode.
	self internalPush: trueObj.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantTwoBytecode [

	self fetchNextBytecode.
	self internalPush: ConstTwo.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantZeroBytecode [

	self fetchNextBytecode.
	self internalPush: ConstZero.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushFloat: f [

	<var: #f type: #double>
	self push: (self floatObjectOf: f).
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pushInteger: integerValue [
	self push: (self integerObjectOf: integerValue).
	^nil
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushLiteralConstant: literalIndex [

	self internalPush: (self literal: literalIndex).
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushLiteralConstantBytecode [
	<expandCases>
	self fetchNextBytecode.
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	self pushLiteralConstant: (currentBytecode bitAnd: 16r1F)
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushLiteralVariable: literalIndex [

	self internalPush:
		(self fetchPointer: ValueIndex ofObject: (self literal: literalIndex)).
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushLiteralVariableBytecode [
	<expandCases>
	self fetchNextBytecode.
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	self pushLiteralVariable: (currentBytecode bitAnd: 16r1F)
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushMaybeContextReceiverVariable: fieldIndex [
	"Must trap accesses to married and widowed contexts.
	 But don't want to check on all inst var accesses.  This
	 method is only used by the long-form bytecodes, evading
	 the cost. Note that the method, closure and receiver fields
	 of married contexts are correctly initialized so they don't
	 need special treatment on read.  Only sender, instruction
	 pointer and stack pointer need to be intercepted on reads."
	| rcvr |
	<inline: true>
	rcvr := self receiver.
	(fieldIndex < MethodIndex
	and: [self isContextNonInt: rcvr])
		ifTrue:
			[self internalPush: (self instVar: fieldIndex ofContext: rcvr)]
		ifFalse:
			[self internalPush: (self fetchPointer: fieldIndex ofObject: rcvr)]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushNewArrayBytecode [
	| size popValues array |
	size := self fetchByte.
	popValues := size > 127.
	size := size bitAnd: 127.
	self fetchNextBytecode.
	self externalizeIPandSP.
	array := self eeInstantiateClass: (self splObj: ClassArray) indexableSize: size.
	self internalizeIPandSP.
	popValues
		ifTrue:
			[0 to: size - 1 do:
				[:i|
				"Assume: have just allocated a new Array; it must be young. Thus, can use unchecked stores."
				self storePointerUnchecked: i ofObject: array withValue: (self internalStackValue: size - i - 1)].
			 self internalPop: size]
		ifFalse:
			[0 to: size - 1 do:
				[:i|
				self storePointerUnchecked: i ofObject: array withValue: nilObj]].
	self internalPush: array
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushReceiverBytecode [

	self fetchNextBytecode.
	self internalPush: self receiver.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushReceiverVariable: fieldIndex [

	self internalPush: (self fetchPointer: fieldIndex ofObject: self receiver).
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushReceiverVariableBytecode [
	<expandCases>
	self fetchNextBytecode.
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	self pushReceiverVariable: (currentBytecode bitAnd: 16rF)
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushRemoteTemp: index inVectorAt: tempVectorIndex [
	| tempVector |
	tempVector := self temporary: tempVectorIndex in: localFP.
	self internalPush: (self fetchPointer: index ofObject: tempVector)
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushRemoteTempLongBytecode [
	| remoteTempIndex tempVectorIndex |
	remoteTempIndex := self fetchByte.
	tempVectorIndex := self fetchByte.
	self fetchNextBytecode.
	self pushRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushTemporaryVariable: temporaryIndex [

	self internalPush: (self temporary: temporaryIndex in: localFP).
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushTemporaryVariableBytecode [
	<expandCases>
	self fetchNextBytecode.
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	self pushTemporaryVariable: (currentBytecode bitAnd: 16rF)
]

{ #category : #'frame access' }
StackInterpreter >> pushedReceiverOrClosureOfFrame: theFP [
	"The receiver of a message send or the closure of a block activation is
	 always on the stack above any arguments and the frame itself.  See the
	 diagram in StackInterpreter class>>initializeFrameIndices."
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + (self frameStackedReceiverOffset: theFP)
]

{ #category : #'image save/restore' }
StackInterpreter >> putLong: aWord toFile: aFile [
	"Append aWord to aFile in this platforms 'natural' byte order.  (Bytes will be swapped, if
	necessary, when the image is read on a different platform.) Set successFlag to false if
	the write fails."

	| objectsWritten |
	<var: #aFile type: 'sqImageFile '>

	objectsWritten := self cCode: 'sqImageFileWrite(&aWord, sizeof(aWord), 1, aFile)'.
	self success: objectsWritten = 1.

]

{ #category : #'image save/restore' }
StackInterpreter >> putShort: aShort toFile: aFile [
	"Append the 16-bit aShort to aFile in this platforms 'natural' byte order.
	 (Bytes will be swapped, if necessary, when the image is read on a
	 different platform.) Set successFlag to false if the write fails."

	| objectsWritten |
	<var: #aFile type: 'sqImageFile '>

	objectsWritten := self cCode: 'sqImageFileWrite(&aShort, sizeof(short), 1, aFile)'.
	self success: objectsWritten = 1.

]

{ #category : #'process primitive support' }
StackInterpreter >> putToSleep: aProcess yieldingIf: yieldImplicitly [
	"Save the given process on the scheduler process list for its priority,
	 adding to the back if yieldImplicitly or to the front if not yieldImplicitly."

	| priority processLists processList |
	self assert:  (framePointer - stackPointer) < LargeContextSize.
	priority := self quickFetchInteger: PriorityIndex ofObject: aProcess.
	(highestRunnableProcessPriority ~= 0
	 and: [priority > highestRunnableProcessPriority]) ifTrue:
		[highestRunnableProcessPriority := priority].
	processLists := self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	processList := self fetchPointer: priority - 1 ofObject: processLists.
	yieldImplicitly
		ifTrue: [self addLastLink: aProcess toList: processList]
		ifFalse: [self addFirstLink: aProcess toList: processList]
]

{ #category : #utilities }
StackInterpreter >> quickFetchInteger: fieldIndex ofObject: objectPointer [
	"Return the integer value of the field without verifying that it is an integer value! For use in time-critical places where the integer-ness of the field can be guaranteed."

	| oop |
	oop := self fetchPointer: fieldIndex ofObject: objectPointer.
	self assert: (self isIntegerObject: oop).
	^self integerValueOf: oop
]

{ #category : #'image save/restore' }
StackInterpreter >> readImageFromFile: f HeapSize: desiredHeapSize StartingAt: imageOffset [
	"Read an image from the given file stream, allocating the given amount of memory to its object heap. Fail if the image has an unknown format or requires more than the given amount of memory."
	"Details: This method detects when the image was stored on a machine with the opposite byte ordering from this machine and swaps the bytes automatically. Furthermore, it allows the header information to start 512 bytes into the file, since some file transfer programs for the Macintosh apparently prepend a Mac-specific header of this size. Note that this same 512 bytes of prefix area could also be used to store an exec command on Unix systems, allowing one to launch Smalltalk by invoking the image name as a command."
	"This code is based on C code by Ian Piumarta and Smalltalk code by Tim Rowledge. Many thanks to both of you!!"

	| swapBytes headerStart headerSize dataSize oldBaseAddr hdrNumStackPages
	  minimumMemory memStart bytesRead bytesToShift heapSize hdrEdenBytes
	  headerFlags hdrMaxExtSemTabSize |
	<var: #f type: 'sqImageFile '>
	<var: #memStart type: 'usqInt'>
	<var: #headerStart type: 'squeakFileOffsetType '>
	<var: #dataSize type: 'size_t '>
	<var: #imageOffset type: 'squeakFileOffsetType '>

	metaclassSizeBytes := 6 * BytesPerWord.	"guess (Metaclass instSize * BPW)"
	swapBytes := self checkImageVersionFrom: f startingAt: imageOffset.
	headerStart := (self sqImageFilePosition: f) - BytesPerWord.  "record header start position"

	headerSize			:= self getLongFromFile: f swap: swapBytes.
	dataSize			:= self getLongFromFile: f swap: swapBytes.
	oldBaseAddr		:= self getLongFromFile: f swap: swapBytes.
	specialObjectsOop	:= self getLongFromFile: f swap: swapBytes.
	lastHash			:= self getLongFromFile: f swap: swapBytes. "N.B.  not used."
	savedWindowSize	:= self getLongFromFile: f swap: swapBytes.
	headerFlags			:= self getLongFromFile: f swap: swapBytes.
	self setImageHeaderFlagsFrom: headerFlags.
	extraVMMemory		:= self getLongFromFile: f swap: swapBytes.
	hdrNumStackPages	:= self getShortFromFile: f swap: swapBytes.
	"4 stack pages is small.  Should be able to run with as few as
	 three. 4 should be comfortable but slow.  8 is a reasonable
	 default.  Can be changed via vmParameterAt: 43 put: n.
	 Can be set as a preference (Info.plist, VM.ini, command line etc).
	 If desiredNumStackPages is already non-zero then it has been
	 set as a preference.  Ignore (but preserve) the header's default."
	numStackPages := desiredNumStackPages ~= 0
						ifTrue: [desiredNumStackPages]
						ifFalse: [hdrNumStackPages = 0
									ifTrue: [self defaultNumStackPages]
									ifFalse: [hdrNumStackPages]].
	desiredNumStackPages := hdrNumStackPages.
	"pad to word boundary.  This slot can be used for anything else that will fit in 16 bits.
	 Preserve it to be polite to images run on Cog."
	theUnknownShort	:= self getShortFromFile: f swap: swapBytes.
	hdrEdenBytes		:= self getLongFromFile: f swap: swapBytes.
	edenBytes := desiredEdenBytes ~= 0
						ifTrue: [desiredEdenBytes]
						ifFalse:
							[hdrEdenBytes = 0
									ifTrue: [self defaultEdenBytes]
									ifFalse: [hdrEdenBytes]].
	desiredEdenBytes := hdrEdenBytes.
	hdrMaxExtSemTabSize := self getShortFromFile: f swap: swapBytes.
	hdrMaxExtSemTabSize ~= 0 ifTrue:
		[self setMaxExtSemSizeTo: hdrMaxExtSemTabSize].
	"decrease Squeak object heap to leave extra memory for the VM"
	heapSize := self cCode: 'reserveExtraCHeapBytes(desiredHeapSize, extraVMMemory)'.

	"compare memory requirements with availability".
	minimumMemory := dataSize + edenBytes + self interpreterAllocationReserveBytes.
	heapSize < minimumMemory ifTrue:
		[self insufficientMemorySpecifiedError].

	"allocate a contiguous block of memory for the Squeak heap"
	memory := self cCode: 'sqAllocateMemory(minimumMemory, heapSize)'.
	memory = nil ifTrue: [self insufficientMemoryAvailableError].

	memStart := self startOfMemory.
	self setMemoryLimit: (memStart + heapSize) - 24.  "decrease memoryLimit a tad for safety"
	self setEndOfMemory: memStart + dataSize.

	"position file after the header"
	self sqImageFile: f Seek: headerStart + headerSize.

	"read in the image in bulk, then swap the bytes if necessary"
	bytesRead := self cCode: 'sqImageFileRead(pointerForOop(memory), sizeof(unsigned char), dataSize, f)'.
	bytesRead ~= dataSize ifTrue: [self unableToReadImageError].

	self ensureImageFormatIsUpToDate: swapBytes.

	"compute difference between old and new memory base addresses"
	bytesToShift := memStart - oldBaseAddr.
	self initializeInterpreter: bytesToShift.  "adjusts all oops to new location"
	^dataSize

]

{ #category : #'image save/restore' }
StackInterpreter >> readableFormat: imageVersion [
	"Anwer true if images of the given format are readable by this interpreter.
	 Allows a virtual machine to accept selected older image formats."

	^imageVersion = self imageFormatVersion "Float words in platform-order"
	   or: [imageVersion = self imageFormatCompatibilityVersion] "Float words in BigEndian order"
]

{ #category : #'internal interpreter access' }
StackInterpreter >> receiver [
	<inline: true>
	^stackPages longAt: localFP + FoxReceiver
]

{ #category : #'process primitive support' }
StackInterpreter >> removeFirstLinkOfList: aList [ 
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
StackInterpreter >> removeProcess: aProcess fromList: aList [ 
	"Remove a given process from a linked list. May fail if aProcess is not on the list."
	| firstLink lastLink nextLink tempLink |
	firstLink := self fetchPointer: FirstLinkIndex ofObject: aList.
	lastLink := self fetchPointer: LastLinkIndex ofObject: aList.
	aProcess  = firstLink ifTrue:[
		nextLink := self fetchPointer: NextLinkIndex ofObject: aProcess .
		self storePointer: FirstLinkIndex ofObject: aList withValue: nextLink.
		aProcess  = lastLink ifTrue:[
			self storePointer: LastLinkIndex ofObject: aList withValue: nilObj.
		].
	] ifFalse:[
		tempLink := firstLink.
		[tempLink = nilObj ifTrue:[^self success: false]. "fail"
		nextLink := self fetchPointer: NextLinkIndex ofObject: tempLink.
		nextLink = aProcess] whileFalse:[
			tempLink := self fetchPointer: NextLinkIndex ofObject: tempLink.
		].
		nextLink := self fetchPointer: NextLinkIndex ofObject: aProcess.
		self storePointer: NextLinkIndex ofObject: tempLink withValue: nextLink.
		aProcess  = lastLink ifTrue:[
			self storePointer: LastLinkIndex ofObject: aList withValue: tempLink.
		].
	].
	self storePointer: NextLinkIndex ofObject: aProcess withValue: nilObj
]

{ #category : #'image segment in/out' }
StackInterpreter >> restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut [

	"Restore headers smashed by forwarding links"
	| tablePtr oop header |
	tablePtr := firstIn.
	[self oop: tablePtr isLessThanOrEqualTo: lastIn] whileTrue:
		[oop := self longAt: tablePtr.
		header := self longAt: hdrBaseIn + (tablePtr-firstIn).
		self longAt: oop put: header.
		tablePtr := tablePtr + BytesPerWord].
	tablePtr := firstOut.
	[self oop: tablePtr isLessThanOrEqualTo: lastOut] whileTrue:
		[oop := self longAt: tablePtr.
		header := self longAt: hdrBaseOut + (tablePtr-firstOut).
		self longAt: oop put: header.
		tablePtr := tablePtr + BytesPerWord].
	
	"Clear all mark bits"
	oop := self firstObject.
	[self oop: oop isLessThan: freeStart] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[self longAt: oop put: ((self longAt: oop) bitAnd: AllButMarkBit)].
		oop := self objectAfter: oop].

]

{ #category : #'stack pages' }
StackInterpreter >> restoreStackLimit [
	"restore the stackLimit if it has been smashed."
	<inline: true>
	stackPage stackLimit: stackPage realStackLimit.
	stackLimit := stackPage stackLimit
]

{ #category : #'process primitive support' }
StackInterpreter >> resume: aProcess preemptedYieldingIf: yieldImplicitly [
	"Make aProcess runnable and if its priority is higher than  that of the
	 current process, preempt the current process.   Answer if the current
	 process was preempted.  If the current process was preempted then if
	 yieldImplicitly add the current process to the back of its run queue,
	 causing an implicit yiled to other processes on the run queue,  otherwise
	 add the current process to the front of its run queue, hence not yielding.
	 Blue book behaviour is to yield implicitly but is arguably incorrect."
	| activeProc activePriority newPriority |
	<inline: false>
	activeProc := self activeProcess.
	activePriority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	newPriority := self quickFetchInteger: PriorityIndex ofObject: aProcess.
	newPriority <= activePriority ifTrue:
		[self putToSleep: aProcess yieldingIf: true.
		 ^false].
	self putToSleep: activeProc yieldingIf: yieldImplicitly.
	self transferTo: aProcess.
	^true
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnFalse [
	localReturnValue := falseObj.
	self commonReturn
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnNil [
	localReturnValue := nilObj.
	self commonReturn
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnReceiver [
	localReturnValue := self receiver.
	self commonReturn
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnTopFromBlock [
	"Return to the caller of the current block activation."
	localReturnValue := self internalStackTop.
	self commonCallerReturn
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnTopFromMethod [
	localReturnValue := self internalStackTop.
	self commonReturn
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnTrue [
	localReturnValue := trueObj.
	self commonReturn
]

{ #category : #'image save/restore' }
StackInterpreter >> reverseBytesFrom: startAddr to: stopAddr [
	"Byte-swap the given range of memory (not inclusive of stopAddr!)."
	| addr |
	self flag: #Dan.
	addr := startAddr.
	[self oop: addr isLessThan: stopAddr] whileTrue:
		[self longAt: addr put: (self byteSwapped: (self longAt: addr)).
		addr := addr + BytesPerWord].
]

{ #category : #'image save/restore' }
StackInterpreter >> reverseBytesInImage [
	"Byte-swap all words in memory after reading in the entire image file with bulk read. Contributed by Tim Rowledge."

	"First, byte-swap every word in the image. This fixes objects headers."
	self reverseBytesFrom: self startOfMemory to: endOfMemory.

	"Second, return the bytes of bytes-type objects to their orginal order, and perform any
	 other format conversions."
	self updateObjectsPostByteSwapFrom: self firstObject to: endOfMemory
]

{ #category : #'I/O primitive support' }
StackInterpreter >> reverseDisplayFrom: startIndex to: endIndex [ 
	"Reverse the given range of Display words (at different bit 
	depths, this will reverse different numbers of pixels). Used to 
	give feedback during VM activities such as garbage 
	collection when debugging. It is assumed that the given 
	word range falls entirely within the first line of the Display."
	| displayObj displayBits w wordStartIndex wordEndIndex primFailCodeValue |
	displayObj := self splObj: TheDisplay.
	((self isPointers: displayObj) and: [(self lengthOf: displayObj) >= 4]) ifFalse: [^ nil].
	w := self fetchPointer: 1 ofObject: displayObj.
	displayBits := self fetchPointer: 0 ofObject: displayObj.
	((self isIntegerObject: displayBits)
	or: [(self isNonIntegerObject: w)
	or: [self isPointersNonInt: displayBits]]) ifTrue: [^ nil].
	wordStartIndex := startIndex * 4.
	wordEndIndex := endIndex * 4 min: (self sizeBitsOf: displayBits).
	displayBits := displayBits + BaseHeaderSize.
	displayBits + wordStartIndex to: displayBits + wordEndIndex by: 4 do:
		[:ptr | | reversed  |
		reversed := (self long32At: ptr) bitXor: 4294967295.
		self longAt: ptr put: reversed].
	primFailCodeValue := primFailCode.
	self initPrimCall.
	self displayBitsOf: displayObj Left: 0 Top: 0 Right: (self integerValueOf: w) Bottom: 1.
	self ioForceDisplayUpdate.
	primFailCode := primFailCodeValue
]

{ #category : #'image save/restore' }
StackInterpreter >> reverseWordsFrom: startAddr to: stopAddr [
	"Word-swap the given range of memory, excluding stopAddr."

	| addr |
	addr := startAddr.
	[self oop: addr isLessThan: stopAddr] whileTrue:
		[self longAt: addr put: (self wordSwapped: (self longAt: addr)).
		addr := addr + BytesPerWord].
]

{ #category : #'method lookup cache' }
StackInterpreter >> rewriteMethodCacheEntryForExternalPrimitiveToFunction: localPrimAddress [
	"Rewrite an existing entry in the method cache with a new primitive function address.
	 Used by primitiveExternalCall to make direct calls to found external prims, or quickly
	 fail not found external prims."
	<inline: false>
	<var: #localPrimAddress declareC: 'void (*localPrimAddress)(void)'>
	(methodCache at: lastMethodCacheProbeWrite + MethodCacheMethod) = newMethod ifTrue:
		[methodCache
			at: lastMethodCacheProbeWrite + MethodCachePrimFunction
			put: (self cCoerce: localPrimAddress to: #long)]
]

{ #category : #'primitive support' }
StackInterpreter >> roomToPushNArgs: n [
	"Answer if there is room to push n arguments onto the current stack.
	 There may be room in this stackPage but there may not be room if
	 the frame were converted into a context."
	| cntxSize |
	self assert: method = (stackPages longAt: framePointer + FoxMethod).
	cntxSize := ((self headerOf: method) bitAnd: LargeContextBit) ~= 0
					ifTrue: [LargeContextSize / BytesPerWord - ReceiverIndex]
					ifFalse: [SmallContextSize / BytesPerWord - ReceiverIndex].
	^self stackPointerIndex + n <= cntxSize
]

{ #category : #'process primitive support' }
StackInterpreter >> schedulerPointer [

	^ self fetchPointer: ValueIndex ofObject: (self splObj: SchedulerAssociation)
]

{ #category : #'send bytecodes' }
StackInterpreter >> secondExtendedSendBytecode [
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

{ #category : #'send bytecodes' }
StackInterpreter >> sendLiteralSelector0ArgsBytecode [
	"Can use any of the first 16 literals for the selector."
	| rcvr |
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := 0.
	rcvr := self internalStackValue: 0.
	lkupClass := self fetchClassOf: rcvr.
	self assert: lkupClass ~~ nilObj.
	self commonSend
]

{ #category : #'send bytecodes' }
StackInterpreter >> sendLiteralSelector1ArgBytecode [
	"Can use any of the first 16 literals for the selector."
	| rcvr |
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := 1.
	rcvr := self internalStackValue: 1.
	lkupClass := self fetchClassOf: rcvr.
	self assert: lkupClass ~~ nilObj.
	self commonSend
]

{ #category : #'send bytecodes' }
StackInterpreter >> sendLiteralSelector2ArgsBytecode [
	"Can use any of the first 16 literals for the selector."
	| rcvr |
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := 2.
	rcvr := self internalStackValue: 2.
	lkupClass := self fetchClassOf: rcvr.
	self assert: lkupClass ~~ nilObj.
	self commonSend
]

{ #category : #'debug support' }
StackInterpreter >> setBreakSelector: aString [
	<api>
	<var: #aString type: #'char *'>
	aString isNil
		ifTrue: [breakSelectorLength := -1. "nil's effective length is zero" breakSelector := nil]
		ifFalse: [breakSelectorLength := self strlen: aString. breakSelector := aString]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> setCogVMFlags: flags [
	"Set an array of flags indicating various properties of the Cog VM.
	 Bit 2: if set, implies preempting a process does not put it to the back of its run queue"
	flags asUnsignedInteger > 7 ifTrue:
		[^self primitiveFailFor: PrimErrUnsupported].
	preemptionYields := (flags bitAnd: 4) = 0
]

{ #category : #'internal interpreter access' }
StackInterpreter >> setDesiredCogCodeSize: iCouldCareLess [
	"This is a no-op in the StackVM"
]

{ #category : #'plugin primitive support' }
StackInterpreter >> setFullScreenFlag: value [
	fullScreenFlag := value
]

{ #category : #'stack pages' }
StackInterpreter >> setHeadFP: theFP andSP: theSP inPage: thePage [
	<inline: true>
	<asmLabel: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	self assert: theSP < theFP.
	self assert: (theSP < thePage baseAddress
				and: [theSP > (thePage realStackLimit - LargeContextSize)]).
	self assert: (theFP < thePage baseAddress
				and: [theFP > (thePage realStackLimit - (LargeContextSize / 2))]).
	thePage headFP: theFP; headSP: theSP
]

{ #category : #'image save/restore' }
StackInterpreter >> setImageHeaderFlagsFrom: headerFlags [
	"Set the flags that are contained in the 7th long of the image header."
	imageHeaderFlags := headerFlags. "so as to preserve unrecognised flags."
	fullScreenFlag := headerFlags bitAnd: 1.
	imageFloatsBigEndian := (headerFlags bitAnd: 2) = 0 ifTrue: [1] ifFalse: [0].
	preemptionYields := (headerFlags bitAnd: 16) = 0
]

{ #category : #'primitive support' }
StackInterpreter >> setInterruptCheckChain: aFunction [
	<var: #aFunction declareC: 'void (*aFunction)()'>
	<var: #prevFunction declareC: 'void (*prevFunction)()'>
	<returnTypeC: 'void (*setInterruptCheckChain(void (*aFunction)(void)))()'>
	<export: true>
	| prevFunction |
	prevFunction := interruptCheckChain.
	interruptCheckChain := aFunction.
	^prevFunction
]

{ #category : #'plugin primitive support' }
StackInterpreter >> setInterruptKeycode: value [
	interruptKeycode := value
]

{ #category : #'plugin primitive support' }
StackInterpreter >> setInterruptPending: value [
	self forceInterruptCheck.
	interruptPending := value
]

{ #category : #'process primitive support' }
StackInterpreter >> setMaxExtSemSizeTo: maxExtSemTabSize [
	maxExtSemTabSizeSet := true.
	self ioSetMaxExtSemTableSize: maxExtSemTabSize
]

{ #category : #'internal interpreter access' }
StackInterpreter >> setMethod: aMethodObj [
	method := aMethodObj
]

{ #category : #'plugin primitive support' }
StackInterpreter >> setNextWakeupUsecs: value [
	<api>
	<var: #value type: #usqLong>
	nextWakeupUsecs := value
]

{ #category : #'plugin primitive support' }
StackInterpreter >> setSavedWindowSize: value [
	savedWindowSize := value
]

{ #category : #'process primitive support' }
StackInterpreter >> setSignalLowSpaceFlagAndSaveProcess [
	"The low space semaphore is about to be signaled. Set the signalLowSpace flag,
	 and force an interrupt check.  Save the currently active process in the special
	 objects array so that the low space handler will be able to determine the process
	 that first triggered a low space condition. The image's low space handler is expected
	 to nil out the special objects array slot when it handles the low space condition."

	| lastSavedProcess activeProc |
	<inline: false>
	DumpStackOnLowSpace ~= 0 ifTrue:
		[self printCallStack.
		 self printAllStacks].
	signalLowSpace := true.
	lowSpaceThreshold := 0. "disable additional interrupts until lowSpaceThreshold is reset by image"
	lastSavedProcess := self splObj: ProcessSignalingLowSpace.
	lastSavedProcess = nilObj ifTrue:
		[activeProc := self activeProcess.
		self storePointer: ProcessSignalingLowSpace ofObject: specialObjectsOop withValue: activeProc].
	self forceInterruptCheck
]

{ #category : #'stack pages' }
StackInterpreter >> setStackPageAndLimit: thePage [
	"Set stackPage to a different page.  Set stackLimit unless it has
	 been smashed.  Make the stackPage the most recently used"
	<inline: true>
	<asmLabel: false>
	<var: #thePage type: #'StackPage *'>
	stackPage := thePage.
	stackLimit ~= (self cCoerceSimple: -1 signedIntToLong to: #'char *') ifTrue:
		[stackLimit := stackPage stackLimit].
	stackPages markStackPageMostRecentlyUsed: thePage
]

{ #category : #'object memory support' }
StackInterpreter >> setTraceFlagOnContextsFramesPageIfNeeded: aContext [
	| thePage |
	<var: #thePage type: #'StackPage *'>
	(self isStillMarriedContext: aContext) ifTrue:
		[thePage := stackPages stackPageFor: (self frameOfMarriedContext: aContext).
		 self assert: (thePage trace between: 0 and: 2).
		 thePage trace = 0 ifTrue:
			[thePage trace: 1]]
]

{ #category : #'jump bytecodes' }
StackInterpreter >> shortConditionalJump [

	self jumplfFalseBy: (currentBytecode bitAnd: 7) + 1.
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintContext: aContext [
	| home |
	<inline: false>
	home := self findHomeForContext: aContext.
	self printNum: aContext.
	(self isMarriedOrWidowedContext: aContext)
		ifTrue: [((self checkIsStillMarriedContext: aContext currentFP: framePointer)
				and: [self isMachineCodeFrame: (self frameOfMarriedContext: aContext)])
					ifTrue: [self print: ' m ']
					ifFalse: [self print: ' i ']]
		ifFalse: [self print: ' s '].
	self printActivationNameFor: (self fetchPointer: MethodIndex ofObject: home)
		receiver: (self fetchPointer: ReceiverIndex ofObject: home)
		isBlock: home ~= aContext
		firstTemporary: (self fetchPointer: 0 + TempFrameStart ofObject: home).
	self cr
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintFrame: theFP [
	<inline: false>
	<var: #theFP type: #'char *'>
	| rcvr |
	theFP = 0 ifTrue:
		[self print: 'null fp'; cr.
		 ^nil].
	rcvr := self frameReceiver: theFP.
	self printHexPtr: theFP.
	self space.
	self printActivationNameFor: (self frameMethod: theFP)
		receiver: rcvr
		isBlock: (self frameIsBlockActivation: theFP)
		firstTemporary: (self temporary: 0 in: theFP).
	self space.
	self shortPrintOop: rcvr "shortPrintOop: adds a cr"
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintFrameAndCallers: theFP [
	<inline: false>
	<var: #theFP type: #'char *'>
	theFP == 0 ifTrue: [^nil].
	self shortPrintFrame: theFP.
	self shortPrintFrameAndCallers: (self frameCallerFP: theFP)
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintFramesInCurrentPage [
	<inline: false>
	self shortPrintFrameAndCallers: localFP
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintFramesInPage: thePage [
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	self shortPrintFrameAndCallers: thePage headFP
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintOop: oop [
	<inline: false>
	self printNum: oop.
	(self isIntegerObject: oop) ifTrue:
		[^self cCode: 'printf("=%ld\n", integerValueOf(oop))' inSmalltalk: [self print: (self shortPrint: oop); cr]].
	(oop between: self startOfMemory and: freeStart) ifFalse:
		[self printHex: oop; print: ' is not on the heap'; cr.
		 ^nil].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[self printHex: oop; print: ' is misaligned'; cr.
		 ^nil].
	self print: ': a(n) '.
	self printNameOfClass: (self fetchClassOf: oop) count: 5.
	self cr
]

{ #category : #'debug printing' }
StackInterpreter >> shortReversePrintFrameAndCallers: aFramePointer [
	| theFP callerFP |
	<inline: false>
	<var: #aFramePointer type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	theFP := aFramePointer.
	[self shortPrintFrame: theFP.
	 callerFP := self frameCallerFP: theFP.
	 callerFP ~= 0] whileTrue:
		[theFP := callerFP].
	^self frameCallerContext: theFP
]

{ #category : #'jump bytecodes' }
StackInterpreter >> shortUnconditionalJump [
	<expandCases>
	self jump: (currentBytecode bitAnd: 7) + 1.
]

{ #category : #'I/O primitive support' }
StackInterpreter >> showDisplayBits: aForm Left: l Top: t Right: r Bottom: b [
	"Repaint the portion of the Smalltalk screen bounded by the affected rectangle. Used to synchronize the screen after a Bitblt to the Smalltalk Display object."
	deferDisplayUpdates ifTrue: [^ nil].
	self displayBitsOf: aForm Left: l Top: t Right: r Bottom: b
]

{ #category : #utilities }
StackInterpreter >> signExtend16: int16 [
	"Convert a signed 16-bit integer into a signed 32-bit integer value. The integer bit is not added here."

	(int16 bitAnd: 16r8000) = 0
		ifTrue: [ ^ int16 ]
		ifFalse: [ ^ int16 - 16r10000 ].
]

{ #category : #'process primitive support' }
StackInterpreter >> signalExternalSemaphores [
	"Signal all requested semaphores.  Answer if a context switch has occurred."
	| xArray |
	xArray := self splObj: ExternalObjectsArray.
	^self doSignalExternalSemaphores: (self stSizeOf: xArray)
]

{ #category : #'process primitive support' }
StackInterpreter >> signalFinalization: weakReferenceOop [
	"If it is not there already, record the given semaphore index in the list of semaphores to be signaled at the next convenient moment. Force a real interrupt check as soon as possible."

	self forceInterruptCheck.
	pendingFinalizationSignals := pendingFinalizationSignals + 1.
]

{ #category : #'primitive support' }
StackInterpreter >> signed32BitIntegerFor: integerValue [
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
	newLargeInteger := self eeInstantiateClass: largeClass indexableSize: 4.
	self storeByte: 3 ofObject: newLargeInteger withValue: ((value >> 24) bitAnd: 16rFF).
	self storeByte: 2 ofObject: newLargeInteger withValue: ((value >> 16) bitAnd: 16rFF).
	self storeByte: 1 ofObject: newLargeInteger withValue: ((value >> 8) bitAnd: 16rFF).
	self storeByte: 0 ofObject: newLargeInteger withValue: (value bitAnd: 16rFF).
	^newLargeInteger
]

{ #category : #'primitive support' }
StackInterpreter >> signed32BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive ST integer or a four-byte LargeInteger."
	| sz value largeClass negative |
	<inline: false>
	(self isIntegerObject: oop) ifTrue: [^self integerValueOf: oop].
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
	"Filter out values out of range for the signed interpretation such as
	 16rFFFFFFFF (positive w/ bit 32 set) and -16rFFFFFFFF (negative w/ bit
	 32 set). Since the sign is implicit in the class we require that the high
	 bit of the magnitude is not set which is a simple test here.  Note that
	 we have to handle the most negative 32-bit value -2147483648 specially."
	value < 0 ifTrue:
		[self assert: (self cCode: 'sizeof(value) == 4').
		(negative and: [value - 1 > 0]) ifTrue: "Don't fail for -2147483648 /-16r80000000"
			[^value].
		 ^self primitiveFail].
	^negative
		ifTrue: [0 - value]
		ifFalse: [value]
]

{ #category : #'primitive support' }
StackInterpreter >> signed64BitIntegerFor: integerValue [
	"Return a Large Integer object for the given integer value"
	| newLargeInteger magnitude largeClass intValue highWord sz |
	<inline: false>
	<var: 'integerValue' type: 'sqLong'>
	<var: 'magnitude' type: 'sqLong'>
	<var: 'highWord' type: 'usqInt'>

	integerValue < 0
		ifTrue:[	largeClass := self classLargeNegativeInteger.
				magnitude := 0 - integerValue]
		ifFalse:[	largeClass := self classLargePositiveInteger.
				magnitude := integerValue].

	"Make sure to handle the most -ve value correctly.
	 0 - most -ve = most -ve and most -ve - 1 is +ve"
	(magnitude <= 16r7FFFFFFF
	 and: [integerValue >= 0 or: [integerValue - 1 < 0]]) ifTrue:
			[^self signed32BitIntegerFor: integerValue].

	highWord := self cCode: 'magnitude >> 32' inSmalltalk: [magnitude >> 32]. "shift is coerced to usqInt otherwise"
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
		intValue := self cCode: '(magnitude >> (i * 8)) & 255' inSmalltalk: [(magnitude >> (i * 8)) bitAnd: 255].
		self storeByte: i ofObject: newLargeInteger withValue: intValue].
	^ newLargeInteger
]

{ #category : #'primitive support' }
StackInterpreter >> signed64BitValueOf: oop [
	"Convert the given object into an integer value.
	The object may be either a positive ST integer or a eight-byte LargeInteger."
	| sz value largeClass negative szsqLong |
	<inline: false>
	<returnTypeC: #sqLong>
	<var: #value type: #sqLong>
	(self isIntegerObject: oop) ifTrue: [^self cCoerce: (self integerValueOf: oop) to: #sqLong].
	largeClass := self fetchClassOfNonInt: oop.
	largeClass = self classLargePositiveInteger
		ifTrue:[negative := false]
		ifFalse:[largeClass = self classLargeNegativeInteger
					ifTrue:[negative := true]
					ifFalse:[^self primitiveFail]].
	szsqLong := self sizeof: #sqLong asSymbol.
	sz := self lengthOf: oop.
	sz > szsqLong 
		ifTrue: [^ self primitiveFail].
	value := 0.
	0 to: sz - 1 do: [:i |
		value := value + ((self cCoerce: (self fetchByte: i ofObject: oop) to: #sqLong) <<  (i*8))].
	"Filter out values out of range for the signed interpretation such as
	16rFFFFFFFF... (positive w/ bit 64 set) and -16rFFFFFFFF... (negative w/ bit
	64 set). Since the sign is implicit in the class we require that the high bit of
	the magnitude is not set which is a simple test here.  Note that we have to
	handle the most negative 64-bit value -9223372036854775808 specially."
	value < 0 ifTrue:
		[self assert: (self cCode: 'sizeof(value) == 8').
		(negative and: [value - 1 > 0]) ifTrue: "Don't fail for -9223372036854775808/-16r8000000000000000"
			[^value].
		 ^self primitiveFail].
	^negative
		ifTrue:[0 - value]
		ifFalse:[value]
]

{ #category : #'send bytecodes' }
StackInterpreter >> singleExtendedSendBytecode [
	"Can use any of the first 32 literals for the selector and pass up to 7 arguments."

	| descriptor |
	descriptor := self fetchByte.
	messageSelector := self literal: (descriptor bitAnd: 16r1F).
	argumentCount := descriptor >> 5.
	self normalSend.
]

{ #category : #'send bytecodes' }
StackInterpreter >> singleExtendedSuperBytecode [
	"Can use any of the first 32 literals for the selector and pass up to 7 arguments."

	| descriptor |
	descriptor := self fetchByte.
	messageSelector := self literal: (descriptor bitAnd: 16r1F).
	argumentCount := descriptor >> 5.
	self superclassSend.

]

{ #category : #utilities }
StackInterpreter >> sizeOfSTArrayFromCPrimitive: cPtr [
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

{ #category : #'translation support' }
StackInterpreter >> sizeof: objectSymbolOrClass [
	<doNotGenerate>
	objectSymbolOrClass isInteger ifTrue:
		[self flag: #Dan.
		 ^BytesPerWord].
	objectSymbolOrClass isSymbol ifTrue:
		[(objectSymbolOrClass == #sqLong
		 or: [objectSymbolOrClass == #double]) ifTrue:
			[^8].
		 self error: 'unrecognized C type name'].
	^(objectSymbolOrClass isBehavior
			ifTrue: [objectSymbolOrClass]
			ifFalse: [objectSymbolOrClass class]) alignedByteSize
]

{ #category : #'object format' }
StackInterpreter >> slotSizeOf: oop [
	"Returns the number of slots in the receiver.
	If the receiver is a byte object, return the number of bytes.
	Otherwise return the number of words."
	(self isIntegerObject: oop) ifTrue:[^0].
	^self lengthOf: oop
]

{ #category : #'primitive support' }
StackInterpreter >> slowPrimitiveResponse [
	"Called under the assumption that primFunctionPtr has been preloaded"
	| delta nArgs savedFramePointer savedNewMethod savedStackPointer expectedPops |
	<inline: true>
	<asmLabel: false>
	<var: #savedFramePointer type: #'char *'>
	<var: #savedStackPointer type: #'char *'>
	FailImbalancedPrimitives
		ifTrue:
			[nArgs := argumentCount.
			 savedStackPointer := stackPointer.
			 savedFramePointer := framePointer]
		ifFalse:
			[DoBalanceChecks ifTrue:"check stack balance"
				[nArgs := argumentCount.
				 delta := framePointer - stackPointer.
				 "If frame pointer changes then primitive has sent or unwound.
				  Stack will appear unbalanced in this case."
				 savedFramePointer := framePointer.
				 savedNewMethod := newMethod]].
	self initPrimCall.
	self dispatchFunctionPointer: primitiveFunctionPointer.
	shouldPopArgs ifTrue:[
		"This was a plugin primitive. If the primitive was successful, pop the args,
		push the return value. Otherwise leave things alone."
		self successful ifTrue:[
			expectedPops := argumentCount.
			self pop: expectedPops.
			primResult = 0 ifFalse:[self pop: 1 thenPush: primResult].
		] ifFalse:[expectedPops := 0].
		primResult := 0. "clear result"
		"Verify that the primitive popped the expected number of args.
		If we have zero primPops assume access via methodArg: etc. 
		and don't complain."
		(primPops = 0 or:[expectedPops = primPops]) ifFalse:[
			self cCode: 'fprintf(stderr,"[VM]: Warning: Primitive popped wrong number of args\n")'.
			self printCallStack.
		].
	].
	FailImbalancedPrimitives
		ifTrue:
			[(self successful
			  and: [framePointer = savedFramePointer
			  and: [(self isMachineCodeFrame: framePointer) not]]) ifTrue:"Don't fail if primitive has done something radical, e.g. perform:"
				[stackPointer ~= (savedStackPointer + (nArgs * BytesPerWord)) ifTrue:
					"Soon make this a message send of e.g. unbalancedPrimitive to the current process or context"
					[stackPointer := savedStackPointer. "This is necessary but insufficient; the result may still have been written to the stack."
					 self failUnbalancedPrimitive]]]
		ifFalse:
			[(DoBalanceChecks
			 and: [framePointer = savedFramePointer]) ifTrue:
				[(self balancedStack: delta withArgs: nArgs) ifFalse:
					[self printUnbalancedStack: (self primitiveIndexOf: savedNewMethod)]]].
	"If we are profiling, take accurate primitive measures"
	nextProfileTick > 0 ifTrue:
		[self checkProfileTick: newMethod].
	^self successful
]

{ #category : #'image save/restore' }
StackInterpreter >> snapshot: embedded [ 
	"update state of active context"
	| activeContext activeProc dataSize rcvr setMacType stackIndex |
	<var: #setMacType type: 'void *'>

	"Need to convert all frames into contexts since the snapshot file only holds objects."
	self push: instructionPointer.
	activeContext := self voidVMStateForSnapshot.
	self pushRemappableOop: activeContext.

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

	"Nothing moves from here on so it is safe to grab the activeContext again."
	activeContext := self popRemappableOop.

	dataSize := freeStart - self startOfMemory. "Assume all objects are below the start of the free block"
	self successful ifTrue:
		["Without contexts or stacks simulate
			rcvr := self popStack.
			''pop rcvr''
			self push: trueObj.
		  to arrange that the snapshot resumes with true.  N.B. stackIndex is one-relative."
		stackIndex := self quickFetchInteger: StackPointerIndex ofObject: activeContext.
		rcvr := self fetchPointer: stackIndex + TempFrameStart - 1 ofObject: activeContext.
		self storePointerUnchecked: stackIndex + TempFrameStart - 1
			ofObject: activeContext
			withValue: trueObj.
		"now attempt to write the snapshot file"
		self writeImageFile: dataSize.
		embedded ifFalse:
			["set Mac file type and creator; this is a noop on other platforms"
			setMacType := self ioLoadFunction: 'setMacFileTypeAndCreator' From: 'FilePlugin'.
			setMacType = 0 ifFalse:
				[self cCode: '((sqInt (*)(char *, char *, char *))setMacType)(imageName, "STim", "FAST")']].
		"Without contexts or stacks simulate
			self pop: 1"
		self storePointerUnchecked: StackPointerIndex
			ofObject: activeContext
			withValue: (self integerObjectOf: stackIndex - 1)].

	self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
	self successful
		ifTrue: [self push: falseObj]
		ifFalse: [self push: rcvr]
]

{ #category : #'image save/restore' }
StackInterpreter >> snapshotCleanUp [
	"Clean up right before saving an image, sweeping memory and:
	* nilling out all fields of contexts above the stack pointer. 
	* flushing external primitives 
	* clearing the root bit of any object in the root table
	* bereaving widowed contexts.
	 By ensuring that all contexts are single in a snapshot (i.e. that no married contexts
	 exist) we can maintain the invariant that a married or widowed context's frame
	 reference (in its sender field) must point into the stack pages since no married or
	 widowed contexts are present from older runs of the system."
	| oop header fmt sz |
	oop := self firstObject.
	[self oop: oop isLessThan: freeStart] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[header := self longAt: oop.
			 fmt := self formatOfHeader: header.
			 "Clean out context"
			 (fmt = 3 and: [self isContextHeader: header]) ifTrue:
				["All contexts have been divorced. Bereave remaining widows."
				 (self isMarriedOrWidowedContext: oop) ifTrue:
					[self storePointerUnchecked: SenderIndex ofObject: oop withValue: nilObj.
					 self storePointerUnchecked: InstructionPointerIndex ofObject: oop withValue: nilObj].
				 sz := self sizeBitsOf: oop.
				 (self lastPointerOf: oop) + BytesPerWord
				 to: sz - BaseHeaderSize by: BytesPerWord
				 do: [:i | self longAt: oop + i put: nilObj]].
			 "Clean out external functions"
			 fmt >= 12 ifTrue:
				["This is a compiled method"
				 (self primitiveIndexOf: oop) = PrimitiveExternalCallIndex ifTrue:
					["Its primitiveExternalCall"
					 self flushExternalPrimitiveOf: oop]]].
			oop := self objectAfter: oop].
	self clearRootsTable
]

{ #category : #'debug printing' }
StackInterpreter >> space [
	<inline: true>
	self printChar: $ 
]

{ #category : #'message sending' }
StackInterpreter >> specialSelector: index [

	^ self fetchPointer: (index * 2) ofObject: (self splObj: SpecialSelectors)
]

{ #category : #'indexing primitive support' }
StackInterpreter >> stObject: array at: index [
	"Return what ST would return for <obj> at: index."

	| hdr fmt totalLength fixedFields stSize |
	<inline: false>
	hdr := self baseHeader: array.
	fmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: array baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: array format: fmt length: totalLength.
	fmt = 3 ifTrue: [self assert: (self isContextHeader: hdr) not].
	stSize := totalLength - fixedFields.
	((self oop: index isGreaterThanOrEqualTo: 1)
	 and: [self oop: index isLessThanOrEqualTo: stSize])
		ifTrue: [^self subscript: array with: (index + fixedFields) format: fmt]
		ifFalse: [self primitiveFailFor: PrimErrBadIndex.  ^ 0]
]

{ #category : #'indexing primitive support' }
StackInterpreter >> stObject: array at: index put: value [
	"Do what ST would return for <obj> at: index put: value."
	| hdr fmt totalLength fixedFields stSize |
	<inline: false>
	hdr := self baseHeader: array.
	fmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: array baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: array format: fmt length: totalLength.
	fmt = 3 ifTrue: [self assert: (self isContextHeader: hdr) not].
	stSize := totalLength - fixedFields.
	((self oop: index isGreaterThanOrEqualTo: 1)
	 and: [self oop: index isLessThanOrEqualTo: stSize])
		ifTrue: [self subscript: array with: (index + fixedFields) storing: value format: fmt]
		ifFalse: [self primitiveFailFor: PrimErrBadIndex]
]

{ #category : #'indexing primitive support' }
StackInterpreter >> stSizeOf: oop [
	"Return the number of indexable fields in the given object. (i.e., what Smalltalk would return for <obj> size)."
	"Note: Assume oop is not a SmallInteger!"

	| hdr fmt totalLength fixedFields |
	<inline: false>
	hdr := self baseHeader: oop.
	fmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: oop baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: oop format: fmt length: totalLength.
	fmt = 3 ifTrue: [self assert: (self isContextHeader: hdr) not].
	^totalLength - fixedFields
]

{ #category : #'internal interpreter access' }
StackInterpreter >> stackFloatValue: offset [
	"In the StackInterpreter stacks grow down."
	| result floatPointer |
	<returnTypeC: #double>
	<var: #result type: #double>
	floatPointer := stackPages longAt: stackPointer + (offset*BytesPerWord).

	"N.B.  Because Slang always inlines assertClassOf:is:compactClassIndex:
	 (because assertClassOf:is:compactClassIndex: has an inline: pragma) the
	 phrase (self splObj: ClassArray) is expanded in-place and is _not_
	 evaluated if ClassArrayCompactIndex is non-zero."
	self assertClassOf: floatPointer
		is: (self splObj: ClassFloat)
		compactClassIndex: ClassFloatCompactIndex.
	self successful
		ifTrue:
			[self cCode: '' inSmalltalk: [result := Float new: 2].
			self fetchFloatAt: floatPointer + BaseHeaderSize into: result.
			^result]
		ifFalse:
			[^0.0]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> stackIntegerValue: offset [
	"In the StackInterpreter stacks grow down."
	| integerPointer |
	integerPointer := stackPages longAt: stackPointer + (offset*BytesPerWord).
	^self checkedIntegerValueOf: integerPointer
]

{ #category : #'stack pages' }
StackInterpreter >> stackLimitOffset [
	"Answer the amount of slots needed to fit a new frame at the point the stack
	 limit is checked.  A frame looks like this at the point the stack limit is checked:
			stacked receiver/closure
			arg0
			...
			argN
			caller's method ip/base frame's sender context
	fp->	saved fp
			method
			method header fields
			context (uninitialized)
			receiver
			first temp
			...
	sp->	Nth temp
	So the amount of headroom is
		the maximum number of arguments + 1 (for stacked receiver and arguments)
		+ the frame size
		+ the max number of temps.
	 Since a method's number of temps includes its arguments the actual offset is:"
	^(FrameSlots + 64) * BytesPerWord
]

{ #category : #'internal interpreter access' }
StackInterpreter >> stackObjectValue: offset [
	"Ensures that the given object is a real object, not a SmallInteger."
	"In the StackInterpreter stacks grow down."
	| oop |
	oop := stackPages longAt: stackPointer + (offset * BytesPerWord).
	(self isIntegerObject: oop) ifTrue: [self primitiveFail. ^ nil].
	^ oop

]

{ #category : #'stack pages' }
StackInterpreter >> stackPageByteSize [
	"Room for 512 bytes of frames gives around 40 frames a page which is a
	 good compromise between overflow rate and latency in divorcing a page."
	<inline: false>
	^1 bitShift: (512 + self stackLimitOffset + self stackPageHeadroom - 1) highBit
]

{ #category : #'stack pages' }
StackInterpreter >> stackPageHeadroom [
	"Return a minimum amount of headroom for each stack page (in bytes).
	 In a JIT the stack has to have room for interrupt handlers which will run on the
	 stack.  In the interpreter we don't actually need any headroom."
	^0
]

{ #category : #initialization }
StackInterpreter >> stackPagesClass [
	<doNotGenerate>
	^VMBIGENDIAN
		ifTrue: [InterpreterStackPagesMSB]
		ifFalse: [InterpreterStackPagesLSB]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> stackPointerForMaybeMarriedContext: aContext [
	"Return the stackPointer of a Context or BlockContext."
	| sp |
	<inline: true>
	(self isStillMarriedContext: aContext) ifTrue:
		[sp := self stackPointerIndexForFrame: (self frameOfMarriedContext: aContext).
		 self assert: ReceiverIndex + (self integerValueOf: sp) < (self lengthOf: aContext).
		 ^sp].
	^self fetchStackPointerOf: aContext
]

{ #category : #'internal interpreter access' }
StackInterpreter >> stackPointerIndex [
	"Return the 1-based value of the stack pointer for the current frame.
	 This is what the value of the stackp slot would be in a context object."
	^self stackPointerIndexForFrame: framePointer WithSP: stackPointer
]

{ #category : #'frame access' }
StackInterpreter >> stackPointerIndexForFrame: theFP [
	"Return the 0-based index rel to the given frame.
	 (This is what stackPointer used to be before conversion to pointer)"
	"In the StackInterpreter stacks grow down."
	| thePage theSP |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	thePage := stackPages stackPageFor: theFP.
	theSP := self findSPOf: theFP on: thePage.
	^self stackPointerIndexForFrame: theFP WithSP: theSP
]

{ #category : #'frame access' }
StackInterpreter >> stackPointerIndexForFrame: theFP WithSP: theSP [
	"Return the 1-based index rel to the given frame"
	"In the StackInterpreter stacks grow down."
	^(((theFP + FoxReceiver) - theSP) >> ShiftForWord) + (self frameNumArgs: theFP)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> stackTop [
	^stackPages longAt: stackPointer
]

{ #category : #'internal interpreter access' }
StackInterpreter >> stackTopPut: aValue [

	^stackPages longAtPointer: stackPointer put: aValue
]

{ #category : #'internal interpreter access' }
StackInterpreter >> stackValue: offset [
	<api>
	"In the StackInterpreter stacks grow down."
	^stackPages longAt: stackPointer + (offset*BytesPerWord)
]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeAndPopReceiverVariableBytecode [
	"Note: This code uses 
	storePointerUnchecked:ofObject:withValue: and does the 
	store check explicitely in order to help the translator 
	produce better code."
	| rcvr top |
	rcvr := self receiver.
	top := self internalStackTop.
	(self oop: rcvr isLessThan: youngStart) ifTrue:
		[self possibleRootStoreInto: rcvr value: top].
	self storePointerUnchecked: (currentBytecode bitAnd: 7) ofObject: rcvr withValue: top.
	self fetchNextBytecode.
	self internalPop: 1
]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeAndPopRemoteTempLongBytecode [
	self storeRemoteTempLongBytecode.
	self internalPop: 1
]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeAndPopTemporaryVariableBytecode [
	<expandCases>
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	self fetchNextBytecode.
	self temporary: (currentBytecode bitAnd: 7) in: localFP put: self internalStackTop.
	self internalPop: 1
]

{ #category : #utilities }
StackInterpreter >> storeInteger: fieldIndex ofObject: objectPointer withValue: integerValue [ 
	"Note: May be called by translated primitive code."
	(self isIntegerValue: integerValue)
		ifTrue: [self storePointerUnchecked: fieldIndex ofObject: objectPointer
					withValue: (self integerObjectOf: integerValue)]
		ifFalse: [self primitiveFail].
	^nil
]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeMaybeContextReceiverVariable: fieldIndex withValue: anObject [
	"Must trap accesses to married and widowed contexts.
	 But don't want to check on all inst var accesses.  This
	 method is only used by the long-form bytecodes, evading the cost."
	| rcvr |
	rcvr := self receiver.
	(fieldIndex <= ReceiverIndex
	and: [(self isContextNonInt: rcvr)
	and: [self isMarriedOrWidowedContext: rcvr]])
		ifTrue:
			[self instVar: fieldIndex ofContext: rcvr put: anObject]
		ifFalse:
			[self storePointer: fieldIndex ofObject: rcvr withValue: anObject]

]

{ #category : #'object memory support' }
StackInterpreter >> storePointerUnchecked: fieldIndex ofObject: oop withValue: valuePointer [
	"Like storePointer:ofObject:withValue:, but the caller guarantees that the
	 object being stored into is a young object or is already marked as a root."
	<api>
	^self
		longAt: oop + BaseHeaderSize + (fieldIndex << ShiftForWord)
		put: valuePointer
]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeRemoteTemp: index inVectorAt: tempVectorIndex [
	| tempVector |
	tempVector := self temporary: tempVectorIndex in: localFP.
	self storePointer: index ofObject: tempVector withValue: self internalStackTop.
]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeRemoteTempLongBytecode [
	| remoteTempIndex tempVectorIndex |
	remoteTempIndex := self fetchByte.
	tempVectorIndex := self fetchByte.
	self fetchNextBytecode.
	self storeRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex
]

{ #category : #'frame access' }
StackInterpreter >> storeSenderOfFrame: theFP withValue: anOop [
	"Set the sender of a frame.  If the frame is a base frame then this is trivial;
	 merely store into the FoxCallerSavedIP/FoxCallerContext field.  If not, then
	 split the stack at the frame, moving the frame and those hotter than it to a
	 new stack page.  In the new stack page the frame will be the base frame
	 and storing trivial.  Answer the possibly changed location of theFP."
	| thePage onCurrentPage newPage theMovedFP |
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #newPage type: #'StackPage *'>
	<var: #theMovedFP type: #'char *'>
	<returnTypeC: #'char *'>
	(self isBaseFrame: theFP) ifTrue:
		[self frameCallerContext: theFP put: anOop.
		 ^theFP].
	self ensureCallerContext: theFP.
	thePage := stackPages stackPageFor: theFP.
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	onCurrentPage := thePage = stackPage.
	onCurrentPage ifFalse:
		["Make sure the frame's page isn't divorced when a new page is allocated."
		 stackPages markStackPageNextMostRecentlyUsed: thePage].
	newPage := self newStackPage.
	theMovedFP := self moveFramesIn: thePage through: theFP toPage: newPage.
	onCurrentPage
		ifTrue: [self setStackPageAndLimit: newPage]
		ifFalse: [stackPages markStackPageMostRecentlyUsed: newPage].
	self assert: (self isBaseFrame: theMovedFP).
	self frameCallerContext: theMovedFP put: anOop.
	^theMovedFP
]

{ #category : #'internal interpreter access' }
StackInterpreter >> storeStackPointerValue: value inContext: aContext [
	"Assume: value is an integerValue"
	self assert: ReceiverIndex + value < (self lengthOf: aContext).
	self storePointerUnchecked: StackPointerIndex
		ofObject: aContext
		withValue: (self integerObjectOf: value)
]

{ #category : #'indexing primitive support' }
StackInterpreter >> subscript: array with: index format: fmt [
	"Note: This method assumes that the index is within bounds!"

	<inline: true>
	<asmLabel: false> "If labelled icc duplicates when inlining stObject:at:"
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
StackInterpreter >> subscript: array with: index storing: oopToStore format: fmt [ 
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
						ifFalse: [self success: false].
					valueToStore := self integerValueOf: oopToStore.
					(valueToStore >= 0
							and: [valueToStore <= 255])
						ifFalse: [self success: false].
					self successful
						ifTrue: [self
								storeByte: index - 1
								ofObject: array
								withValue: valueToStore]]]
]

{ #category : #'primitive support' }
StackInterpreter >> success: successBoolean [
	"Set the state of the primitive failure code/success flag, iff successBoolean
	 is false. If primFailCode is non-zero a primitive has failed.  If primFailCode
	 is greater than one then its value indicates the reason for failure."

	"Use returnTypeC: #sqInt because that's the way it is defined in sq.h.
	 Use no explicit return so that Slang doesn't fail an inlin ingtype-check when
	 a primitive with return type void uses ^self success: false to exit."
	<returnTypeC: #sqInt>
	<inline: true>
	successBoolean ifFalse:
		["Don't overwrite an error code that has already been set."
		 primFailCode == 0 ifTrue:
			[primFailCode := 1]]
]

{ #category : #'primitive support' }
StackInterpreter >> successful [
	"Answer the state of the primitive failure code/success flag.  If
	 primFailCode is non-zero a primitive has failed.  If primFailCode
	 is greater than one then its value indicates the reason for failure."
	<inline: true>
	^primFailCode == 0
]

{ #category : #'object access primitives' }
StackInterpreter >> sufficientSpaceToInstantiate: classOop indexableSize: size [ 
	"Return the number of bytes required to allocate an instance of the given class with the given number of indexable fields."
	"Details: For speed, over-estimate space needed for fixed fields or literals; the low space threshold is a blurry line."
	| format atomSize|
	<inline: true>
	format := self instSpecOfClass: classOop.

	"fail if attempting to call new: on non-indexable class"
	((self cCoerce: size to: 'usqInt ') > 0 and: [format < 2])
		ifTrue: [^ false].

	format < 8
		ifTrue: ["indexable fields are words or pointers" atomSize := BytesPerWord]
		ifFalse: ["indexable fields are bytes" atomSize := 1].
	^self sufficientSpaceToAllocate: 2500 + (size * atomSize)
]

{ #category : #'message sending' }
StackInterpreter >> superclassOf: classPointer [

	^ self fetchPointer: SuperclassIndex ofObject: classPointer
]

{ #category : #'message sending' }
StackInterpreter >> superclassSend [
	"Send a message to self, starting lookup with the superclass of the class
	 containing the currently executing method."
	"Assume: messageSelector and argumentCount have been set, and that
	 the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeNamed: 'commonSupersend' inCase: 133>
	lkupClass := self superclassOf: (self methodClassOf: method).
	self assert: lkupClass ~~ nilObj.
	self commonSend
]

{ #category : #'process primitive support' }
StackInterpreter >> synchronousSignal: aSemaphore [ 
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
		preemptedYieldingIf: preemptionYields
]

{ #category : #'debug printing' }
StackInterpreter >> tab [
	<inline: true>
	self printChar: $	"<-Character tab"
]

{ #category : #'compiled methods' }
StackInterpreter >> tempCountOf: methodPointer [
	^self tempCountOfMethodHeader: (self headerOf: methodPointer)
]

{ #category : #'compiled methods' }
StackInterpreter >> tempCountOfMethodHeader: header [
	<inline: true>
	^ (header >> 19) bitAnd: 16r3F
]

{ #category : #'internal interpreter access' }
StackInterpreter >> temporary: offset in: theFP [
	"See StackInterpreter class>>initializeFrameIndices"
	| frameNumArgs |
	<inline: true>
	<var: #theFP type: #'char *'>
	^offset < (frameNumArgs := self frameNumArgs: theFP)
		ifTrue: [stackPages longAt: theFP + FoxCallerSavedIP + ((frameNumArgs - offset) * BytesPerWord)]
		ifFalse: [stackPages longAt: theFP + FoxReceiver - BytesPerWord + ((frameNumArgs - offset) * BytesPerWord)]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> temporary: offset in: theFP put: valueOop [
	"See StackInterpreter class>>initializeFrameIndices"
	| frameNumArgs |
	<inline: true>
	<var: #theFP type: #'char *'>
	offset < (frameNumArgs := self frameNumArgs: theFP)
		ifTrue: [stackPages longAt: theFP + FoxCallerSavedIP + ((frameNumArgs - offset) * BytesPerWord) put: valueOop]
		ifFalse: [stackPages longAt: theFP + FoxReceiver - BytesPerWord + ((frameNumArgs - offset) * BytesPerWord) put: valueOop]
]

{ #category : #'compiled methods' }
StackInterpreter >> temporaryCountOfMethodHeader: header [
	^(header >> 19) bitAnd: 16r3F
]

{ #category : #'internal interpreter access' }
StackInterpreter >> temporaryLocation: offset in: theFP numArgs: numArgs [
	"Answer the pointer to a given temporary (for debug frame printing in odd circumstances)"
	<var: #theFP type: #'char *'>
	<returnTypeC: #'char *'>
	<asmLabel: false>
	^offset < numArgs
		ifTrue: [theFP + FoxCallerSavedIP + ((numArgs - offset) * BytesPerWord)]
		ifFalse: [theFP + FoxReceiver - BytesPerWord + ((numArgs - offset) * BytesPerWord)]
]

{ #category : #'object memory support' }
StackInterpreter >> traceProfileState [
	self markAndTrace: profileProcess.
	self markAndTrace: profileMethod.
	self markAndTrace: profileSemaphore.

	"Since the longRunningPrimitiveCheckMethod is sampled at interrupt time it may be invalid.
	 Be very careful with it."
	(longRunningPrimitiveCheckMethod ~= nil
	 and: [(self isFreeObject: longRunningPrimitiveCheckMethod) not
	 and: [self isCompiledMethod: longRunningPrimitiveCheckMethod]]) ifTrue:
		[self markAndTrace: longRunningPrimitiveCheckMethod].
	longRunningPrimitiveCheckSemaphore ~= nil ifTrue:
		[self markAndTrace: longRunningPrimitiveCheckSemaphore]
]

{ #category : #utilities }
StackInterpreter >> transfer: count from: src to: dst [ 
	| in out lastIn |
	self flag: #Dan.  "Need to check all senders before converting this for 64 bits"
	self inline: true.
	in := src - BytesPerWord.
	lastIn := in + (count * BytesPerWord).
	out := dst - BytesPerWord.
	[self oop: in isLessThan: lastIn]
		whileTrue: [self
				longAt: (out := out + BytesPerWord)
				put: (self longAt: (in := in + BytesPerWord))]
]

{ #category : #'process primitive support' }
StackInterpreter >> transferTo: newProc [ 
	"Record a process to be awoken on the next interpreter cycle."
	| activeContext sched oldProc |
	<inline: false>
	statProcessSwitch := statProcessSwitch + 1.
	self push: instructionPointer.
	self externalWriteBackHeadFramePointers.
	sched := self schedulerPointer.
	oldProc := self fetchPointer: ActiveProcessIndex ofObject: sched.
	activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
	self storePointer: SuspendedContextIndex ofObject: oldProc withValue: activeContext.
	self storePointer: ActiveProcessIndex ofObject: sched withValue: newProc.
	self storePointerUnchecked: MyListIndex ofObject: newProc withValue: nilObj.
	self externalSetStackPageAndPointersForSuspendedContextOfProcess: newProc.
	instructionPointer := self popStack.
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer
]

{ #category : #'internal interpreter access' }
StackInterpreter >> unPop: nItems [
	"In the StackInterpreter stacks grow down."
	stackPointer := stackPointer - (nItems*BytesPerWord)
]

{ #category : #'interpreter shell' }
StackInterpreter >> unknownBytecode [
	"This should never get called; it means that an unimplemented bytecode appears in a CompiledMethod."

	self error: 'Unknown bytecode'.
]

{ #category : #'image save/restore' }
StackInterpreter >> unknownShortOrCodeSizeInKs [
	"preserve whatever this value was (for images run on Cog)"
	^theUnknownShort
]

{ #category : #'image save/restore' }
StackInterpreter >> updateObjectsPostByteSwapFrom: startOop to: stopAddr [ 
	"Byte-swap the words of all bytes objects in a range of the 
	 image, including Strings, ByteArrays, and CompiledMethods.
	 This returns these objects to their original byte ordering 
	 after blindly byte-swapping the entire image. For compiled 
	 methods, byte-swap only their bytecodes part.
	 Ensure floats are in platform-order."
	| oop fmt wordAddr methodHeader swapFloatWords temp |
	swapFloatWords := self vmEndianness ~= imageFloatsBigEndian.
	self assert: ClassFloatCompactIndex ~= 0.
	oop := startOop.
	[self oop: oop isLessThan: stopAddr] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[fmt := self formatOf: oop.
			 fmt >= 8 ifTrue: "oop contains bytes"
				[wordAddr := oop + BaseHeaderSize.
				fmt >= 12 ifTrue: "compiled method; start after methodHeader and literals"
					[methodHeader := self longAt: oop + BaseHeaderSize.
					 wordAddr := wordAddr + BytesPerWord + ((methodHeader >> 10 bitAnd: 255) * BytesPerWord)].
				self reverseBytesFrom: wordAddr to: oop + (self sizeBitsOf: oop)].
			 fmt = 6 ifTrue: "Bitmap, Float etc"
				[(swapFloatWords
				  and: [(self compactClassIndexOf: oop) = ClassFloatCompactIndex])
					ifTrue:
						[temp := self longAt: oop + BaseHeaderSize.
						 self longAt: oop + BaseHeaderSize put: (self longAt: oop + BaseHeaderSize + 4).
						 self longAt: oop + BaseHeaderSize + 4 put: temp]
					ifFalse:
						[BytesPerWord = 8 ifTrue: "Object contains 32-bit half-words packed into 64-bit machine words."
							[wordAddr := oop + BaseHeaderSize.
							 self reverseWordsFrom: wordAddr to: oop + (self sizeBitsOf: oop)]]]].
			oop := self objectAfter: oop]
]

{ #category : #'frame access' }
StackInterpreter >> updateStateOfSpouseContextForFrame: theFP WithSP: theSP [
	"Update the frame's spouse context with the frame's current state except for the
	 sender and instruction pointer, which are used to mark the context as married."
	| theContext tempIndex pointer |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #pointer type: #'char *'>
	self assert: (self frameHasContext: theFP).
	theContext := self frameContext: theFP.
	self assert: (self frameReceiver: theFP)
				= (self fetchPointer: ReceiverIndex ofObject: theContext).
	tempIndex := self frameNumArgs: theFP.
	pointer := theFP + FoxReceiver - BytesPerWord.
	[pointer >= theSP] whileTrue:
		[self assert: (self addressCouldBeOop: (stackPages longAt: pointer)).
		 tempIndex := tempIndex + 1.
		 self storePointer: ReceiverIndex + tempIndex
			ofObject: theContext
			withValue: (stackPages longAt: pointer).
		 pointer := pointer - BytesPerWord].
	self assert: ReceiverIndex + tempIndex < (self lengthOf: theContext).
	self storePointerUnchecked: StackPointerIndex
		ofObject: theContext
		withValue: (self integerObjectOf: tempIndex)
]

{ #category : #'debug support' }
StackInterpreter >> validInstructionPointer: anInstrPointer inFrame: fp [
	<var: #anInstrPointer type: #usqInt>
	<var: #fp type: #'char *'>
	<inline: false>
	^self validInstructionPointer: anInstrPointer inMethod: (self frameMethodObject: fp) framePointer: fp
]

{ #category : #'debug support' }
StackInterpreter >> validInstructionPointer: instrPointer inMethod: aMethod framePointer: fp [
	<var: #instrPointer type: #usqInt>
	<var: #aMethod type: #usqInt>
	^instrPointer >= (aMethod + (self lastPointerOf: aMethod) + BytesPerWord - 1)
	  and: [instrPointer < (aMethod + (self byteLengthOf: aMethod) + BaseHeaderSize)]
]

{ #category : #'stack pages' }
StackInterpreter >> validStackPageBaseFrames [
	"Check that the base frames in all in-use stack pages have a valid sender context."
	<var: #aPage type: #'StackPage *'>
	0 to: numStackPages - 1 do:
		[:i| | aPage senderContextOrNil |
		aPage := stackPages stackPageAt: i.
		(stackPages isFree: aPage) ifFalse:
			[(self asserta: (self isBaseFrame: aPage baseFP)) ifFalse:
				[^false].
			 senderContextOrNil := self frameCallerContext: aPage baseFP.
			 (self asserta: (self addressCouldBeObj: senderContextOrNil)) ifFalse:
				[^false].
			 (self asserta: (senderContextOrNil = nilObj or: [self isContext: senderContextOrNil])) ifFalse:
				[^false]]].
	^true
]

{ #category : #'debug support' }
StackInterpreter >> verifyCleanHeaders [
	| oop |
	oop := self firstObject.
	[self oop: oop isLessThan: freeStart] whileTrue:
		[(self isFreeObject: oop)
			ifTrue: ["There should only be one free block at end of memory."
					(self objectAfter: oop) = endOfMemory
						ifFalse: [self error: 'Invalid obj with HeaderTypeBits = Free.']]
			ifFalse: [(self isMarked: oop) ifTrue:
						[self error: 'Invalid obj with MarkBit set.']].
		oop := self objectAfter: oop]
]

{ #category : #'plugin support' }
StackInterpreter >> vmEndianness [
	"return 0 for little endian, 1 for big endian"
	"?!*#$%! _Terrible_ name. Call it what it is.
	 VMBIGENDIAN or VMLITTLEENDIAN.  Dont leave us guessing!!!!
	 Alas this has to remain for backward compatibility."

	^VMBIGENDIAN ifTrue: [1] ifFalse: [0]

]

{ #category : #'primitive support' }
StackInterpreter >> voidLongRunningPrimitive: reason [
	"Void the state associated with the long-running primitive check.
	 This is done when a new semaphore is installed or when it appears
	 that is longRunningPrimitiveCheckMethod is invalid, e.g. because it
	 has eben sampled in the middle of a GC."
	<var: #reason type: #'char *'>
	<inline: false>
	longRunningPrimitiveCheckMethod := nil.
	longRunningPrimitiveCheckSequenceNumber = 0. "not strictly necessary but prevents this being inlined into checkForLongRunningPrimitive"
	longRunningPrimitiveStartUsecs :=
	longRunningPrimitiveStopUsecs := 0.
	longRunningPrimitiveSignalUndelivered := true
]

{ #category : #'frame access' }
StackInterpreter >> voidVMStateForSnapshot [
	"Make sure that all VM state that affects the heap contents is voided so that the heap is ready
	 to be snapshotted. Answer the activeContext object that should be stored in the snapshot."
	| activeContext |
	<inline: false>
	activeContext := self divorceAllFrames.
	self bereaveAllMarriedContexts.
	^activeContext
]

{ #category : #'process primitive support' }
StackInterpreter >> wakeHighestPriority [
	"Return the highest priority process that is ready to run.
	 To save time looking at many empty lists before finding a
	 runnable process the VM maintains a variable holding the
	 highest priority runnable process.  If this variable is 0 then the
	 VM does not know the highest priority and must search all lists.
	 Note: It is a fatal VM error if there is no runnable process."
	| schedLists p processList |
	schedLists := self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	p := highestRunnableProcessPriority = 0
			ifTrue: [self fetchWordLengthOf: schedLists]
			ifFalse: [highestRunnableProcessPriority].
	p := p - 1.
	"index of last indexable field"
	[processList := self fetchPointer: p ofObject: schedLists.
	 self isEmptyList: processList] whileTrue:
		[(p := p - 1) < 0 ifTrue:
			[self error: 'scheduler could not find a runnable process']].
	highestRunnableProcessPriority := p + 1.
	^self removeFirstLinkOfList: processList
]

{ #category : #'frame access' }
StackInterpreter >> withSmallIntegerTags: value [
	<inline: true>
	<var: #value type: #'char *'>
	self assert: ((self oopForPointer: value) bitAnd: BytesPerWord - 1) = 0.
	^(self oopForPointer: value) + 1
]

{ #category : #'frame access' }
StackInterpreter >> withoutSmallIntegerTags: anInteger [
	<inline: true>
	<returnTypeC: #'char *'>
	self assert: (self isIntegerObject: anInteger).
	^self pointerForOop: (anInteger - 1)
]

{ #category : #'image segment in/out' }
StackInterpreter >> wordSwapFloatsFrom: startOop to: stopAddr [
	"Swap the most and least significant words of Floats in a range of the image."
	| oop temp |
	oop := startOop.
	[self oop: oop isLessThan: stopAddr] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[((self formatOf: oop) = 6
			 and: [(self compactClassIndexOf: oop) = ClassFloatCompactIndex]) ifTrue:
				[temp := self longAt: oop + BaseHeaderSize.
				 self longAt: oop + BaseHeaderSize put: (self longAt: oop + BaseHeaderSize + 4).
				 self longAt: oop + BaseHeaderSize + 4 put: temp]].
		oop := self objectAfter: oop]
]

{ #category : #'image save/restore' }
StackInterpreter >> wordSwapped: w [
	"Return the given 64-bit integer with its halves in the reverse order."

	BytesPerWord = 8 ifFalse: [self error: 'This cannot happen.'].
	^   ((w bitShift: Byte4ShiftNegated) bitAnd: Bytes3to0Mask)
	  + ((w bitShift: Byte4Shift         ) bitAnd: Bytes7to4Mask)

]

{ #category : #'stack pages' }
StackInterpreter >> writeBackHeadFramePointers [
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	self setHeadFP: localFP andSP: localSP inPage: stackPage.
	self assert: stackPages pageListIsWellFormed
]

{ #category : #'image save/restore' }
StackInterpreter >> writeImageFile: imageBytes [

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
StackInterpreter >> writeImageFileIO: imageBytes [

	| headerStart headerSize f bytesWritten sCWIfn okToWrite memStart |
	<var: #f type: 'sqImageFile'>
	<var: #headerStart type: 'squeakFileOffsetType '>
	<var: #sCWIfn type: 'void *'>

	"If the security plugin can be loaded, use it to check for write permission.
	If not, assume it's ok"
	sCWIfn := self ioLoadFunction: 'secCanWriteImage' From: 'SecurityPlugin'.
	sCWIfn ~= 0 ifTrue:
		[okToWrite := self cCode: '((sqInt (*)(void))sCWIfn)()'.
		 okToWrite ifFalse:[^self primitiveFail]].
	
	"local constants"
	headerStart := 0.  
	headerSize := 64.  "header size in bytes; do not change!"

	f := self cCode: 'sqImageFileOpen(imageName, "wb")'.
	f = nil ifTrue: "could not open the image file for writing"
		[^self primitiveFail].

	headerStart := self cCode: 'sqImageFileStartLocation(f,imageName,headerSize+imageBytes)'.
	self cCode: '/* Note: on Unix systems one could put an exec command here, padded to 512 bytes */'.
	"position file to start of header"
	self sqImageFile: f Seek: headerStart.

	self putLong: self imageFormatVersion toFile: f.
	self putLong: headerSize toFile: f.
	self putLong: imageBytes toFile: f.
	self putLong: self startOfMemory toFile: f.
	self putLong: specialObjectsOop toFile: f.
	self putLong: self newObjectHash toFile: f.
	self putLong: self ioScreenSize toFile: f.
	self putLong: self getImageHeaderFlags toFile: f.
	self putLong: extraVMMemory toFile: f.
	self putShort: desiredNumStackPages toFile: f.
	self putShort: self unknownShortOrCodeSizeInKs toFile: f.
	self putLong: desiredEdenBytes toFile: f.
	self putShort: (maxExtSemTabSizeSet ifTrue: [self ioGetMaxExtSemTableSize] ifFalse: [0]) toFile: f.
	self putShort: 0 toFile: f.
	1 to: 4 do: [:i | self putLong: 0 toFile: f].  "fill remaining header words with zeros"
	self successful ifFalse: [
		"file write or seek failure"
		self cCode: 'sqImageFileClose(f)'.
		^ nil].

	"position file after the header"
	self sqImageFile: f Seek: headerStart + headerSize.

	"write the image data"
	memStart := self startOfMemory.
	bytesWritten := self cCode: 'sqImageFileWrite(pointerForOop(memStart), sizeof(unsigned char), imageBytes, f)'.
	self success: bytesWritten = imageBytes.
	self touch: memStart.
	self cCode: 'sqImageFileClose(f)'

]
