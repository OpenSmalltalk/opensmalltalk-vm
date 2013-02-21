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
	#superclass : #InterpreterPrimitives,
	#instVars : [
		'currentBytecode',
		'bytecodeSetSelector',
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
		'extA',
		'extB',
		'primitiveFunctionPointer',
		'methodCache',
		'atCache',
		'lkupClass',
		'highestRunnableProcessPriority',
		'nextWakeupUsecs',
		'nextPollUsecs',
		'inIOProcessEvents',
		'interruptKeycode',
		'interruptPending',
		'savedWindowSize',
		'imageHeaderFlags',
		'fullScreenFlag',
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
		'suspendedCallbacks',
		'suspendedMethods',
		'numStackPages',
		'desiredNumStackPages',
		'desiredEdenBytes',
		'classNameIndex',
		'thisClassIndex',
		'metaclassSizeBits',
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
		'tempOop',
		'statForceInterruptCheck',
		'statStackOverflow',
		'statStackPageDivorce',
		'statCheckForEvents',
		'statProcessSwitch',
		'statIOProcessEvents',
		'theUnknownShort',
		'imageFloatsBigEndian',
		'maxExtSemTabSizeSet',
		'lastMethodCacheProbeWrite',
		'statPendingFinalizationSignals',
		'gcSemaphoreIndex',
		'classByteArrayCompactIndex'
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
		'BytecodeTable',
		'CacheProbeMax',
		'DirBadPath',
		'DirEntryFound',
		'DirNoMoreEntries',
		'DumpStackOnLowSpace',
		'EnclosingMixinIndex',
		'EnclosingObjectIndex',
		'FailImbalancedPrimitives',
		'HeaderFlagBitPosition',
		'MaxExternalPrimitiveTableSize',
		'MaxJumpBuf',
		'MaxPrimitiveIndex',
		'MaxQuickPrimitiveIndex',
		'MixinIndex',
		'PrimitiveExternalCallIndex',
		'PrimitiveTable'
	],
	#pools : [
		'VMBasicConstants',
		'VMMethodCacheConstants',
		'VMObjectIndices',
		'VMSqueakV3BytecodeConstants',
		'VMSqueakV3ObjectRepresentationConstants',
		'VMStackFrameOffsets'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #translation }
StackInterpreter class >> additionalHeadersDo: aBinaryBlock [
	"Evaluate aBinaryBlock with the names and contents of
	 any additional header files that need to be generated."
	self objectMemoryClass additionalHeadersDo: aBinaryBlock.
	aBinaryBlock
		value: 'vmCallback.h'
		value: self vmCallbackHeader
]

{ #category : #translation }
StackInterpreter class >> additionalSelectorTables [
	^{ self primitiveTable }
]

{ #category : #translation }
StackInterpreter class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^{ self objectMemoryClass. InterpreterStackPages }
]

{ #category : #translation }
StackInterpreter class >> ancilliaryStructClasses [
	^{ InterpreterStackPage. VMCallbackContext }
]

{ #category : #constants }
StackInterpreter class >> bytecodeTable [

	^ BytecodeTable
]

{ #category : #translation }
StackInterpreter class >> declareCVarsIn: aCCodeGenerator [
	self class == thisContext methodClass ifFalse: [^self]. "Don't duplicate decls in subclasses"
	aCCodeGenerator
		addHeaderFile:'<stddef.h> /* for e.g. alloca */';
		addHeaderFile:'<setjmp.h>';
		addHeaderFile:'"vmCallback.h"';
		addHeaderFile:'"sqMemoryFence.h"';
		addHeaderFile:'"dispdbg.h"'.
	self declareInterpreterVersionIn: aCCodeGenerator
		defaultName: 'Stack'.
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
	"This defines bytecodeSetSelector as 0 if MULTIPLEBYTECODESETS
	 is not defined, for the benefit of the interpreter on slow machines."
	aCCodeGenerator addConstantForBinding: (self bindingOf: #MULTIPLEBYTECODESETS).
	MULTIPLEBYTECODESETS == false ifTrue:
		[aCCodeGenerator
			removeVariable: 'extA';
			removeVariable: 'extB';
			removeVariable: 'bytecodeSetSelector'].
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

{ #category : #translation }
StackInterpreter class >> exportAPISelectors [
	| omExports |
	omExports := (self objectMemoryClass withAllSuperclasses copyUpTo: VMClass)
					inject: Set new
					into: [:api :c| api addAll: c exportAPISelectors; yourself].
	^(self withAllSuperclasses copyUpTo: VMClass), self ancilliaryClasses
		inject: omExports
		into: [:set :class| set addAll: (self exportAPISelectorsFor: class); yourself]
]

{ #category : #translation }
StackInterpreter class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #initialization }
StackInterpreter class >> initializeAssociationIndex [
	KeyIndex := 0.
	ValueIndex := 1
]

{ #category : #initialization }
StackInterpreter class >> initializeBytecodeTable [
	"StackInterpreter initializeBytecodeTable"

	NewspeakVM ifTrue:
		[^MULTIPLEBYTECODESETS
			ifTrue: [self initializeBytecodeTableForNewspeakV3PlusClosuresNewspeakV4Hybrid]
			ifFalse: [self initializeBytecodeTableForNewspeakV3PlusClosures]].

	^self initializeBytecodeTableForSqueakV3PlusClosures
]

{ #category : #initialization }
StackInterpreter class >> initializeBytecodeTableForNewspeakV3PlusClosures [
	"StackInterpreter initializeBytecodeTableForNewspeakV3PlusClosures"
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

		"2 of the 3 Newspeak bytecodes"
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
		(138 pushNewArrayBytecode)

		"The last of 3 Newspeak bytecodes"
		(139 pushExplicitOuterSendReceiverBytecode)

		(140 pushRemoteTempLongBytecode)
		(141 storeRemoteTempLongBytecode)
		(142 storeAndPopRemoteTempLongBytecode)
		(143 pushClosureCopyCopiedValuesBytecode)

		(144 151 shortUnconditionalJump)
		(152 159 shortConditionalJumpFalse)
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
		(200 bytecodePrimSpecialSelector24)
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
	)
]

{ #category : #initialization }
StackInterpreter class >> initializeBytecodeTableForNewspeakV3PlusClosuresNewspeakV4Hybrid [
	"StackInterpreter initializeBytecodeTableForNewspeakV3PlusClosuresNewspeakV4Hybrid"

	| v3Table v4Table |
	self initializeBytecodeTableForNewspeakV3PlusClosures.
	v3Table := BytecodeTable.
	self initializeBytecodeTableForNewspeakV4.
	v4Table := BytecodeTable.
	BytecodeTable := v3Table, v4Table
]

{ #category : #initialization }
StackInterpreter class >> initializeBytecodeTableForNewspeakV4 [
	"StackInterpreter initializeBytecodeTableForNewspeakV4"
	"Note: This table will be used to generate a C switch statement."

	BytecodeTable := Array new: 256.
	self table: BytecodeTable from:
	#(	"1 byte bytecodes"
		(   0  15 pushReceiverVariableBytecode)
		( 16  31 pushLiteralVariable16CasesBytecode)
		( 32  63 pushLiteralConstantBytecode)
		( 64  75 pushTemporaryVariableBytecode)
		( 76	 pushReceiverBytecode)
		( 77	 extPushPseudoVariableOrOuterBytecode)
		( 78	 pushConstantZeroBytecode)
		( 79	 pushConstantOneBytecode)

		( 80	 bytecodePrimAdd)
		( 81	 bytecodePrimSubtract)
		( 82	 bytecodePrimLessThanV4) "for booleanCheatV4:"
		( 83	 bytecodePrimGreaterThanV4) "for booleanCheatV4:"
		( 84	 bytecodePrimLessOrEqualV4) "for booleanCheatV4:"
		( 85	 bytecodePrimGreaterOrEqualV4) "for booleanCheatV4:"
		( 86	 bytecodePrimEqualV4) "for booleanCheatV4:"
		( 87	 bytecodePrimNotEqualV4) "for booleanCheatV4:"
		( 88	 bytecodePrimMultiply)
		( 89	 bytecodePrimDivide)
		( 90	 bytecodePrimMod)
		( 91	 bytecodePrimMakePoint)
		( 92	 bytecodePrimBitShift)
		( 93	 bytecodePrimDiv)
		( 94	 bytecodePrimBitAnd)
		( 95	 bytecodePrimBitOr)

		( 96	 bytecodePrimAt)
		( 97	 bytecodePrimAtPut)
		( 98	 bytecodePrimSize)
		( 99	 bytecodePrimNext)
		(100	 bytecodePrimNextPut)
		(101	 bytecodePrimAtEnd)
		(102	 bytecodePrimEquivalentV4) "for booleanCheatV4:"
		(103	 bytecodePrimClass)
		(104	 bytecodePrimSpecialSelector24) "was blockCopy:"
		(105	 bytecodePrimValue)
		(106	 bytecodePrimValueWithArg)
		(107	 bytecodePrimDo)
		(108	 bytecodePrimNew)
		(109	 bytecodePrimNewWithArg)
		(110	 bytecodePrimPointX)
		(111	 bytecodePrimPointY)

		(112 127	sendLiteralSelector0ArgsBytecode)
		(128 143	sendLiteralSelector1ArgBytecode)
		(144 159	sendLiteralSelector2ArgsBytecode)
		(160 175	sendAbsentImplicit0ArgsBytecode)

		(176 183	storeAndPopReceiverVariableBytecode)
		(184 191	storeAndPopTemporaryVariableBytecode)

		(192 199	shortUnconditionalJump)
		(200 207	shortConditionalJumpTrue)
		(208 215	shortConditionalJumpFalse)

		(216		returnReceiver)
		(217		returnTopFromMethod)
		(218		extReturnTopFromBlock)

		(219		duplicateTopBytecode)
		(220		popStackBytecode)
		(221		extNopBytecode)
		(222 223	unknownBytecode)

		"2 byte bytecodes"
		(224		extABytecode)
		(225		extBBytecode)

		(226		extPushReceiverVariableBytecode)
		(227		extPushLiteralVariableBytecode)
		(228		extPushLiteralBytecode)
		(229		extPushIntegerBytecode)
		(230		longPushTemporaryVariableBytecode)
		(231		pushNewArrayBytecode)
		(232		extStoreReceiverVariableBytecode)
		(233		extStoreLiteralVariableBytecode)
		(234		longStoreTemporaryVariableBytecode)
		(235		extStoreAndPopReceiverVariableBytecode)
		(236		extStoreAndPopLiteralVariableBytecode)
		(237		longStoreAndPopTemporaryVariableBytecode)

		(238		extSendBytecode)
		(239		extSendSuperBytecode)
		(240		extSendAbsentImplicitBytecode)
		(241		extSendAbsentDynamicSuperBytecode)

		(242		extUnconditionalJump)
		(243		extJumpIfTrue)
		(244		extJumpIfFalse)

		(245 248	unknownBytecode)

		"3 byte bytecodes"
		(249		callPrimitiveBytecode)

		(250		pushRemoteTempLongBytecode)
		(251		storeRemoteTempLongBytecode)
		(252		storeAndPopRemoteTempLongBytecode)
		(253		extPushClosureBytecode)

		(254 255	unknownBytecode)
	)
]

{ #category : #initialization }
StackInterpreter class >> initializeBytecodeTableForSqueakV3PlusClosures [
	"StackInterpreter initializeBytecodeTableForSqueakV3PlusClosures"
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
		(152 159 shortConditionalJumpFalse)
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
		(200 bytecodePrimSpecialSelector24)
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
	)
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
	MethodDictionaryIndex := 1.
	InstanceSpecificationIndex := 2.
	"Fields of a message dictionary"
	MethodArrayIndex := 1.
	SelectorStart := 2.

	"Newspeak extensions"
	"Fields of a Mixin (also defined by Behavior)"
	EnclosingMixinIndex := NewspeakVM ifTrue: [3].  "(Class instVarIndexFor: 'mixinSlot') - 1"
	"Fields of a MixinApplication (also defined by Behavior)"
	MixinIndex := NewspeakVM ifTrue: [3]. "(Class instVarIndexFor: 'mixinSlot') - 1"
	EnclosingObjectIndex := NewspeakVM ifTrue: [4]. "(Class instVarIndexFor: 'enclosingObjectSlot') - 1"


]

{ #category : #initialization }
StackInterpreter class >> initializeContextIndices [
	"Class MethodContext"
	| contextFixedSizePlusHeader |
	SenderIndex := 0.
	InstructionPointerIndex := 1.
	StackPointerIndex := 2.
	MethodIndex := 3.
	ClosureIndex := 4. "N.B. Called receiverMap in the image."
	ReceiverIndex := 5.
	CtxtTempFrameStart := 6.

	"Class BlockClosure"
	ClosureOuterContextIndex := 0.
	ClosureStartPCIndex := 1.
	ClosureNumArgsIndex := 2.
	ClosureFirstCopiedValueIndex := 3.
	ClosureCopiedValuesIndex := 3.

	contextFixedSizePlusHeader := CtxtTempFrameStart + 1.
	SmallContextSize := contextFixedSizePlusHeader + 16 * BytesPerWord.  "16 indexable fields"
	"Large contexts have 56 indexable fileds.  Max with single header word."
	"However note that in 64 bits, for now, large contexts have 3-word headers"
	LargeContextSize := contextFixedSizePlusHeader + 56 * BytesPerWord
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

	LargeContextBit := 16r40000.  "This bit set in method headers if large context is needed."
	"The position of the unused flag bit in the method header, not including tag bit(s)"
	HeaderFlagBitPosition := 29
]

{ #category : #initialization }
StackInterpreter class >> initializeMiscConstantsWith: optionsDictionary [

	super initializeMiscConstantsWith: optionsDictionary.
	STACKVM := true.

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
		(161 primitiveSetIdentityHash)
		(162 164 primitiveFail)			"reserved for immutablity primitives"
		(165 primitiveIntegerAt)		"hacked in here for now"
		(166 primitiveIntegerAtPut)
		(167 primitiveYield)
		(168 primitiveCopyObject)
		(169 primitiveNotIdentical)

		"Sound Primitives (170-199) - NO LONGER INDEXED"
		(170 174 primitiveFail)

		"CogMemoryManager primitives"
		(175 primitiveBehaviorHash)
		(176 primitiveMaxIdentityHash)
		(177 184 primitiveFail)

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
		(215 primitiveFlushCacheByMethod) "primitiveVoidVMStateForMethod in the CoInterpreter"
		(216 217 primitiveFail)	"reserved for Cog primitives"
		(218 primitiveDoNamedPrimitiveWithArgs)
		(219 primitiveFail)		"reserved for Cog primitives"

		(220 primitiveFail)		"reserved for Cog primitives"

		(221 primitiveClosureValueNoContextSwitch) "valueNoContextSwitch"
		(222 primitiveClosureValueNoContextSwitch) "valueNoContextSwitch:"

		(223 229 primitiveFail)	"reserved for Cog primitives (see 228 & 229 in CoInterpreterMTS"

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
	ConstMinusOne := self objectMemoryClass basicNew integerObjectOf: -1.
	ConstZero := self objectMemoryClass basicNew integerObjectOf: 0.
	ConstOne := self objectMemoryClass basicNew integerObjectOf: 1.
	ConstTwo := self objectMemoryClass basicNew integerObjectOf: 2
]

{ #category : #initialization }
StackInterpreter class >> initializeStreamIndices [
	StreamArrayIndex := 0.
	StreamIndexIndex := 1.
	StreamReadLimitIndex := 2.
	StreamWriteLimitIndex := 3.
]

{ #category : #initialization }
StackInterpreter class >> initializeWithOptions: optionsDictionary [
	"StackInterpreter initializeWithOptions: Dictionary new"

	NewObjectMemory initializeWithOptions: optionsDictionary.  "initialize ObjectMemory constants"
	self initializeMiscConstantsWith: optionsDictionary. "must preceed other initialization."
	self initializeAssociationIndex.
	self initializeBytecodeTable.
	self initializeCaches.
	self initializeCharacterIndex.
	self initializeCharacterScannerIndices.
	self initializeClassIndices.
	self initializeContextIndices.
	self initializeDirectoryLookupResultCodes.
	self initializeFrameIndices.
	self initializeMessageIndices.
	self initializeMethodIndices.
	self initializePointIndices.
	self initializePrimitiveTable.
	self initializeSchedulerIndices.
	self initializeSmallIntegers.
	self initializeStreamIndices
]

{ #category : #translation }
StackInterpreter class >> isInterpreterClass [
	^true
]

{ #category : #translation }
StackInterpreter class >> isNonArgumentImplicitReceiverVariableName: aString [
	^#('self' 'stackPages' 'interpreter' 'objectMemory' 'coInterpreter') includes: aString
]

{ #category : #benchmarks }
StackInterpreter class >> macroBenchmark [  "StackInterpreter macroBenchmark"
	| dir |
	dir := 'benchmark2.dir'.
	(FileDirectory default directoryExists: dir)
		ifTrue: [(FileDirectory default directoryNamed: dir) recursiveDeleteContents]
		ifFalse: [(FileDirectory default directoryNamed: dir) assureExistence].
	([VMMaker
			makerFor: StackInterpreter
			and: nil
			with: #()
			to: (FileDirectory default pathFromURI: dir)
			platformDir: 'none'
			excluding:  (InterpreterPlugin withAllSubclasses collect: [:ea| ea name])]
		on: VMMakerException "suppress bleats about non-existent platforms dir"
		do: [:ex| ex resume: nil])
			generateInterpreterFile.
	(FileDirectory default directoryNamed: dir) recursiveDeleteContents; recursiveDelete
]

{ #category : #translation }
StackInterpreter class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^(self objectMemoryClass mustBeGlobal: var)
	   or: [(#('interpreterProxy' 'interpreterVersion' 'inIOProcessEvents'
			'deferDisplayUpdates' 'extraVMMemory' 'showSurfaceFn'
			'desiredNumStackPages' 'desiredEdenBytes'
			'breakSelector' 'breakSelectorLength' 'sendTrace'
			'suppressHeartbeatFlag') includes: var)
	   or: [ "This allows slow machines to define bytecodeSetSelector as 0
			to avoid the interpretation overhead."
			MULTIPLEBYTECODESETS not and: [var = 'bytecodeSetSelector']]]
]

{ #category : #translation }
StackInterpreter class >> namesOfVariablesToLocalize [
	^#(currentBytecode localFP localIP localSP localReturnValue)
]

{ #category : #translation }
StackInterpreter class >> needsCogit [
	^false
]

{ #category : #'accessing class hierarchy' }
StackInterpreter class >> objectMemoryClass [
	^NewObjectMemory
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
StackInterpreter class >> prepareToBeAddedToCodeGenerator: aCodeGen [
	"Override to delete InterpreterPrimitives methods we override."
	aCodeGen removeVariable: 'cogit'.
	self selectors do:
		[:sel|
		 (superclass whichClassIncludesSelector: sel) ifNotNil:
			[aCodeGen removeMethodForSelector: sel]]
]

{ #category : #constants }
StackInterpreter class >> primitiveTable [

	^ PrimitiveTable
]

{ #category : #initialization }
StackInterpreter class >> primitiveTableString [
	"StackInterpreter initializePrimitiveTable primitiveTableString"
	^self primitiveTableStringFor: self primitiveTable
]

{ #category : #initialization }
StackInterpreter class >> primitiveTableStringFor: table [
	"StackInterpreter initializePrimitiveTable primitiveTableString"
	^String streamContents:
		[:s | 
		s nextPut: ${.
		table withIndexDo:
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

{ #category : #miscellaneous }
StackInterpreter class >> reorganizeAsISeeFit [
	"StackInterpreter reorganizeAsISeeFit"
	"CoInterpreter reorganizeAsISeeFit"
	| initializations bytecodes privates remainder |
	initializations := OrderedCollection new.
	bytecodes := OrderedCollection new.
	privates := OrderedCollection new.
	remainder := OrderedCollection new.
	self organization categories do:
		[:cat|
		((cat includesSubString: 'initializ')
			ifTrue: [initializations]
			ifFalse:
				[((cat endsWith: 'bytecodes') or: [cat includesSubString: 'selector sends'])
					ifTrue: [bytecodes]
					ifFalse:
						[(cat includesSubString: 'private')
							ifTrue: [privates]
							ifFalse: [remainder]]])
			add: cat].
	self organization categories: initializations sort, bytecodes sort, remainder sort, privates sort
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
		oopFromChunk:
		primitiveFail primitiveFailFor: primitiveFlushExternalPrimitives printAllStacks printCallStack printContext:
			printExternalHeadFrame printFramesInPage: printFrame: printHeadFrame printMemory printOop:
				printStackPages printStackPageList printStackPagesInUse printStackPageListInUse
		readableFormat: readImageFromFile:HeapSize:StartingAt:
		setFullScreenFlag: setInterruptKeycode: setInterruptPending: setInterruptCheckChain:
			setSavedWindowSize: success:
		validInstructionPointer:inMethod:framePointer:).

	"Nice to actually have all the primitives available"
	requiredList addAll: (self primitiveTable select: [:each| each isSymbol]).

	"InterpreterProxy is the internal analogue of sqVirtualMachine.c, so make sure to keep all those"
	InterpreterProxy organization categories do:
		[:cat |
		((cat ~= 'initialize') and: [cat ~= 'private']) ifTrue:
			[requiredList addAll: (InterpreterProxy organization listAtCategoryNamed: cat)]].

	^requiredList
]

{ #category : #translation }
StackInterpreter class >> shouldGenerateTypedefFor: aStructClass [
	"Hack to work-around mutliple definitions.  Sometimes a type has been defined in an include."
	^aStructClass ~~ VMCallbackContext
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
StackInterpreter class >> translationClass [
	"Return te class to use as the interpreterCLass when translating.  For the all-in-one
	 VMs that inherit from ObjectMemory this is the receiver.  But for the separate VMs
	 where most primitives are in a subclass it will be the subclass with the primitives."
	^self subclasses detect: [:s| s name = (self name, 'Primitives')] ifNone: [self]
]

{ #category : #translation }
StackInterpreter class >> vmCallbackHeader [
	^String streamContents:
		[:s|
		s nextPutAll: '#define VM_CALLBACK_INC 1'; cr; cr.
		VMCallbackContext printTypedefOn: s.
		s cr]
]

{ #category : #'api version' }
StackInterpreter class >> vmProxyMajorVersion [
	"Define the  VM_PROXY_MAJOR version for this VM as used to
	 define the api in platforms/Cross/vm/sqVirtualMachine.[ch]"
	^1
]

{ #category : #'api version' }
StackInterpreter class >> vmProxyMinorVersion [
	"Define the  VM_PROXY_MINOR version for this VM as used to
	 define the api in platforms/Cross/vm/sqVirtualMachine.[ch]"
	^12
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
	super writeVMHeaderTo: aStream bytesPerWord: bytesPerWord.
	NewspeakVM ifTrue:
		[aStream nextPutAll: '#define NewspeakVM 1'; cr].
	IMMUTABILITY ifTrue:
		[aStream nextPutAll: '#define IMMUTABILITY 1'; cr].
	NewspeakVM | IMMUTABILITY ifTrue:
		[aStream cr].
	aStream nextPutAll: '#define STACKVM 1'; cr; cr
]

{ #category : #'debug support' }
StackInterpreter >> abstractDetailedSymbolicMethod: aMethod [
	<doNotGenerate>
	| ts prim |
	(ts := self transcript) ensureCr.
	(prim := self primitiveIndexOf: aMethod) > 0 ifTrue:
		[ts nextPutAll: '<primitive: '; print: prim; nextPut: $>.
		(self isQuickPrimitiveIndex: prim) ifTrue:
			[ts nextPutAll: ' quick method'; cr; flush.
			 ^self].
		ts cr].
	(RelativeDetailedInstructionPrinter
			on: (VMCompiledMethodProxy new
					for: aMethod
					coInterpreter: self
					objectMemory: objectMemory))
		indent: 0;
		printInstructionsOn: ts.
	ts flush
]

{ #category : #'control primitives' }
StackInterpreter >> activateNewClosureMethod: blockClosure numArgs: numArgs mayContextSwitch: mayContextSwitch [
	"Similar to activateNewMethod but for Closure and newMethod."
	| numCopied outerContext theMethod closureIP |
	<inline: true>
	outerContext := objectMemory fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	numCopied := self copiedValueCountOfClosure: blockClosure.

	theMethod := objectMemory fetchPointer: MethodIndex ofObject: outerContext.
	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: theMethod.
	self push: (self encodeFrameFieldHasContext: false isBlock: true numArgs: numArgs).
	self push: objectMemory nilObject. "FxThisContext field"
	self push: (objectMemory fetchPointer: ReceiverIndex ofObject: outerContext).

	"Copy the copied values..."
	0 to: numCopied - 1 do:
		[:i|
		self push: (objectMemory
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
	| methodHeader |
	methodHeader := self justActivateNewMethod.

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	stackPointer < stackLimit ifTrue:
		[self handleStackOverflowOrEventAllowContextSwitch: (self canContextSwitchIfActivating: newMethod header: methodHeader)]
]

{ #category : #'process primitive support' }
StackInterpreter >> activeProcess [
	"Answer the current activeProcess."
	<api> "useful for VM debugging"
	^objectMemory fetchPointer: ActiveProcessIndex ofObject: self schedulerPointer
]

{ #category : #'process primitive support' }
StackInterpreter >> addFirstLink: proc toList: aList [ 
	"Add the given process to the front of the given linked list
	 and set the backpointer of process to its new list."
	| firstLink |
	self assert: (objectMemory fetchPointer: NextLinkIndex ofObject: proc) = objectMemory nilObject.
	firstLink := objectMemory fetchPointer: FirstLinkIndex ofObject: aList.
	self assert: firstLink ~= proc.
	objectMemory storePointer: FirstLinkIndex ofObject: aList withValue: proc.
	firstLink = objectMemory nilObject "a.k.a. (self isEmptyList: aList)"
		ifTrue: [objectMemory storePointer: LastLinkIndex ofObject: aList withValue: proc]
		ifFalse: [objectMemory storePointer: NextLinkIndex ofObject: proc withValue: firstLink].
	objectMemory storePointer: MyListIndex ofObject: proc withValue: aList
]

{ #category : #'process primitive support' }
StackInterpreter >> addLastLink: proc toList: aList [ 
	"Add the given process to the end of the given linked list
	 and set the backpointer of process to its new list."
	| lastLink |
	self assert: (objectMemory fetchPointer: NextLinkIndex ofObject: proc) = objectMemory nilObject.
	(self isEmptyList: aList)
		ifTrue: [objectMemory storePointer: FirstLinkIndex ofObject: aList withValue: proc]
		ifFalse:
			[lastLink := objectMemory fetchPointer: LastLinkIndex ofObject: aList.
			 self assert: lastLink ~= proc.
			 objectMemory storePointer: NextLinkIndex ofObject: lastLink withValue: proc].
	objectMemory storePointer: LastLinkIndex ofObject: aList withValue: proc.
	objectMemory storePointer: MyListIndex ofObject: proc withValue: aList
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
	(objectMemory isOopCompiledMethod: newMethod)
		ifTrue:
			[primitiveIndex := self primitiveIndexOf: newMethod.
			 primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: class]
		ifFalse:
			[primitiveFunctionPointer := #primitiveInvokeObjectAsMethod].

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
	| ok oop |
	ok := true.
	oop := objectMemory firstAccessibleObject.
	[oop = nil] whileFalse:
		[ok := ok & (self okayFields: oop).
		oop := objectMemory accessibleObjectAfter: oop].
	^ok
]

{ #category : #'image save/restore' }
StackInterpreter >> allocateMemory: heapSize minimum: minimumMemory imageFile: fileStream headerSize: headerSize [
	"Translate to C function call with (case sensitive) camelCase. The purpose of this
	 method is to document the translation.
	 The default implementation is sqAllocateMemory(minimumMemory, heapSize). This may
	 be redefined to make use of the image file and header size parameters for efficient
	 implementation with mmap().
	 See CCodeGenerator>>writeDefaultMacrosOn: which specifies a default implementation."

	<inline: true>
	<returnTypeC: #'char *'>
	<var: #fileStream type: #sqImageFile>
	^self pointerForOop: (self
							allocateMemory: heapSize
							Minimum: minimumMemory
							ImageFile: fileStream
							HeaderSize: headerSize)
]

{ #category : #'compiled methods' }
StackInterpreter >> alternateHeaderHasPrimitiveFlag: methodHeader [
	<inline: true>
	^methodHeader anyMask: 16r10000 << SmallIntegerShift
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
	<api>
	^header >> 25 bitAnd: 16r0F
]

{ #category : #utilities }
StackInterpreter >> arrayValueOf: arrayOop [
	"Return the address of first indexable field of resulting array object, or fail if
	 the instance variable does not contain an indexable bytes or words object."
	"Note: May be called by translated primitive code."

	<returnTypeC: #'void *'>
	((objectMemory isNonIntegerObject: arrayOop)
	 and: [objectMemory isWordsOrBytes: arrayOop]) ifTrue:
		[^self cCoerceSimple: (self pointerForOop: arrayOop + BaseHeaderSize) to: #'void *'].
	self primitiveFail
]

{ #category : #'indexing primitive support' }
StackInterpreter >> asciiOfCharacter: characterObj [  "Returns an integer object"

	<inline: false>
	self assertClassOf: characterObj is: (objectMemory splObj: ClassCharacter).
	self successful
		ifTrue: [^ objectMemory fetchPointer: CharacterValueIndex ofObject: characterObj]
		ifFalse: [^ ConstZero]  "in case some code needs an int"
]

{ #category : #utilities }
StackInterpreter >> assertClassOf: oop is: classOop [
	"Succeed if oop is an instance of the given class. Fail if the object is an integer."

	<inline: true>
	<asmLabel: false>
	self success: (objectMemory isClassOfNonImm: oop equalTo: classOop)
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
				or: [(self pushedReceiverOrClosureOfFrame: lfp) = (self frameReceiver: lfp)]).
	self assert: method = (self frameMethod: lfp).
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [self assert: (self methodUsesAlternateBytecodeSet: method) = (bytecodeSetSelector = 256)].
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

{ #category : #'return bytecodes' }
StackInterpreter >> baseFrameReturn [
	"Return from a baseFrame (the bottom frame in a stackPage).  The context to
	 return to (which may be married) is stored in the saved instruction pointer slot."
	<inline: true>
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
			  and: [objectMemory isIntegerObject: (objectMemory fetchPointer: InstructionPointerIndex ofObject: contextToReturnTo)]) ifFalse:
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
	<asmLabel: false>
	oop := objectMemory firstObject.
	[oop < objectMemory freeStart] whileTrue:
		[((objectMemory isFreeObject: oop) not
		   and: [(objectMemory isContextNonInt: oop)
		   and: [self isMarriedOrWidowedContext: oop]]) ifTrue:
			[self markContextAsDead: oop].
		 oop := objectMemory objectAfter: oop]
]

{ #category : #utilities }
StackInterpreter >> booleanCheat: cond [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<inline: true>

	cond
		ifTrue: [self booleanCheatTrue]
		ifFalse: [self booleanCheatFalse]
]

{ #category : #utilities }
StackInterpreter >> booleanCheatFalse [
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
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := bytecode + bytecodeSetSelector]
		ifFalse: [currentBytecode := bytecode].
	self internalPush: objectMemory falseObject
]

{ #category : #utilities }
StackInterpreter >> booleanCheatFalseV4 [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<sharedCodeNamed: 'booleanCheatFalseV4' inCase: #bytecodePrimGreaterThanV4>
	| bytecode offset |

	bytecode := self fetchByte.  "assume next bytecode is jumpIfFalse (99%)"
	self internalPop: 2.
	(bytecode < 216 and: [bytecode > 207]) ifTrue:  "short jumpIfFalse"
		[^self jump: bytecode - 207].

	bytecode = 244 ifTrue:  "long jumpIfFalse"
		[offset := self fetchByte.
		^self jump: offset].

	"not followed by a jumpIfFalse; (un)do instruction fetch and push boolean result"
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := bytecode + bytecodeSetSelector]
		ifFalse: [currentBytecode := bytecode].
	self internalPush: objectMemory falseObject
]

{ #category : #utilities }
StackInterpreter >> booleanCheatTrue [
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
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := bytecode + bytecodeSetSelector]
		ifFalse: [currentBytecode := bytecode].
	self internalPush: objectMemory trueObject
]

{ #category : #utilities }
StackInterpreter >> booleanCheatTrueV4 [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<sharedCodeNamed: 'booleanCheatTrueV4' inCase: #bytecodePrimLessThanV4>
	| bytecode offset |

	bytecode := self fetchByte.  "assume next bytecode is jumpIfFalse (99%)"
	self internalPop: 2.
	bytecode >= 208 ifTrue:
		[bytecode <= 215 ifTrue: "short jumpIfFalse 208 - 215"
			[^self fetchNextBytecode].
		bytecode = 244 ifTrue: "long jumpIfFalse"
			[self fetchByte.
			^self fetchNextBytecode].
		bytecode = 243 ifTrue: "long jumpIfTrue 243"
			[offset := self fetchByte.
			^self jump: offset]].

	"not followed by a jumpIfFalse; (un)do instruction fetch and push boolean result"
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := bytecode + bytecodeSetSelector]
		ifFalse: [currentBytecode := bytecode].
	self internalPush: objectMemory trueObject
]

{ #category : #utilities }
StackInterpreter >> booleanCheatV4: cond [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<inline: true>

	cond
		ifTrue: [self booleanCheatTrueV4]
		ifFalse: [self booleanCheatFalseV4]
]

{ #category : #utilities }
StackInterpreter >> booleanValueOf: obj [
"convert true and false (Smalltalk) to true or false(C)"
	obj = objectMemory trueObject ifTrue: [ ^ true ].
	obj = objectMemory falseObject ifTrue: [ ^ false ].
	self success: false.
	^ nil
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimAdd [
	| rcvr arg result |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg)
		ifTrue: [result := (objectMemory integerValueOf: rcvr) + (objectMemory integerValueOf: arg).
				(objectMemory isIntegerValue: result) ifTrue:
					[self internalPop: 2 thenPush: (objectMemory integerObjectOf: result).
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
	((objectMemory isIntegerObject: rcvr) not
	 and: [objectMemory isIntegerObject: index]) ifTrue:
		[atIx := rcvr bitAnd: AtCacheMask.  "Index into atCache = 4N, for N = 0 ... 7"
		(atCache at: atIx+AtCacheOop) = rcvr ifTrue:
			[result := self commonVariable: rcvr at: (objectMemory integerValueOf: index) cacheIndex: atIx.
			 self successful ifTrue:
				[self fetchNextBytecode.
				^self internalPop: 2 thenPush: result].
			 self initPrimCall]].

	messageSelector := self specialSelector: 16.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimAtEnd [
	messageSelector := self specialSelector: 21.
	argumentCount := self specialSelectorNumArgs: 21.
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
	((objectMemory isIntegerObject: rcvr) not
	 and: [objectMemory isIntegerObject: index]) ifTrue:
		[atIx := (rcvr bitAnd: AtCacheMask) + AtPutBase.  "Index into atPutCache"
		 (atCache at: atIx+AtCacheOop) = rcvr ifTrue:
			[self commonVariable: rcvr at: (objectMemory integerValueOf: index) put: value cacheIndex: atIx.
			 self successful ifTrue:
				[self fetchNextBytecode.
				 ^self internalPop: 3 thenPush: value].
			 self initPrimCall]].

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
StackInterpreter >> bytecodePrimClass [
	| rcvr |
	rcvr := self internalStackTop.
	self internalStackTopPut: (objectMemory fetchClassOf: rcvr).
	self fetchNextBytecode
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimDiv [
	| quotient |
	self initPrimCall.
	quotient := self doPrimitiveDiv: (self internalStackValue: 1) by: (self internalStackValue: 0).
	self successful ifTrue: [self internalPop: 2 thenPush: (objectMemory integerObjectOf: quotient).
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
		ifTrue: [rcvr := objectMemory integerValueOf: rcvr.
			arg := objectMemory integerValueOf: arg.
			(arg ~= 0 and: [rcvr \\ arg = 0])
				ifTrue: [result := rcvr // arg.
					"generates C / operation"
					(objectMemory isIntegerValue: result)
						ifTrue: [self internalPop: 2 thenPush: (objectMemory integerObjectOf: result).
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
	argumentCount := self specialSelectorNumArgs: 27.
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
StackInterpreter >> bytecodePrimEqualV4 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue: [^self booleanCheatV4: rcvr = arg].

	self initPrimCall.
	aBool := self primitiveFloatEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheatV4: aBool].

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
StackInterpreter >> bytecodePrimEquivalentV4 [

	| rcvr arg |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	self booleanCheatV4: rcvr = arg.
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimGreaterOrEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheat: rcvr >= arg]
			inSmalltalk: [self booleanCheat: (objectMemory integerValueOf: rcvr) >= (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatGreaterOrEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 5.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimGreaterOrEqualV4 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheatV4: rcvr >= arg]
			inSmalltalk: [self booleanCheatV4: (objectMemory integerValueOf: rcvr) >= (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatGreaterOrEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheatV4: aBool].

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
		^self cCode: [self booleanCheat: rcvr > arg]
			inSmalltalk: [self booleanCheat: (objectMemory integerValueOf: rcvr) > (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatGreater: rcvr thanArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 3.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimGreaterThanV4 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheatV4: rcvr > arg]
			inSmalltalk: [self booleanCheatV4: (objectMemory integerValueOf: rcvr) > (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatGreater: rcvr thanArg: arg.
	self successful ifTrue: [^self booleanCheatV4: aBool].

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
		^self cCode: [self booleanCheat: rcvr <= arg]
			inSmalltalk: [self booleanCheat: (objectMemory integerValueOf: rcvr) <= (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatLessOrEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 4.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimLessOrEqualV4 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheatV4: rcvr <= arg]
			inSmalltalk: [self booleanCheatV4: (objectMemory integerValueOf: rcvr) <= (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatLessOrEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheatV4: aBool].

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
		^self cCode: [self booleanCheat: rcvr < arg]
			inSmalltalk: [self booleanCheat: (objectMemory integerValueOf: rcvr) < (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatLess: rcvr thanArg: arg.
	self successful ifTrue: [^ self booleanCheat: aBool].

	messageSelector := self specialSelector: 2.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimLessThanV4 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheatV4: rcvr < arg]
			inSmalltalk: [self booleanCheatV4: (objectMemory integerValueOf: rcvr) < (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatLess: rcvr thanArg: arg.
	self successful ifTrue: [^ self booleanCheatV4: aBool].

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
		[self internalPop: 2 thenPush: (objectMemory integerObjectOf: mod).
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
		ifTrue: [rcvr := objectMemory integerValueOf: rcvr.
				arg := objectMemory integerValueOf: arg.
				result := rcvr * arg.
				(arg = 0
				 or: [(result // arg) = rcvr and: [objectMemory isIntegerValue: result]]) ifTrue:
					[self internalPop: 2 thenPush: (objectMemory integerObjectOf: result).
					 ^self fetchNextBytecode "success"]]
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
	argumentCount := self specialSelectorNumArgs: 19.
	self normalSend.
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNextPut [
	messageSelector := self specialSelector: 20.
	argumentCount := self specialSelectorNumArgs: 20.
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
StackInterpreter >> bytecodePrimNotEqualV4 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg) ifTrue: [^self booleanCheatV4: rcvr ~= arg].

	self initPrimCall.
	aBool := self primitiveFloatEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheatV4: aBool not].

	messageSelector := self specialSelector: 7.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimPointX [

	| rcvr |
	self initPrimCall.
	rcvr := self internalStackTop.
	self assertClassOf: rcvr is: (objectMemory splObj: ClassPoint).
	self successful ifTrue:
		[self internalStackTopPut: (objectMemory fetchPointer: XIndex ofObject: rcvr).
		^self fetchNextBytecode "success"].
	primFailCode := 0.

	messageSelector := self specialSelector: 30.
	argumentCount := 0.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimPointY [

	| rcvr |
	self initPrimCall.
	rcvr := self internalStackTop.
	self assertClassOf: rcvr is: (objectMemory splObj: ClassPoint).
	self successful ifTrue:
		[self internalStackTopPut: (objectMemory fetchPointer: YIndex ofObject: rcvr).
		^self fetchNextBytecode "success"].
	primFailCode := 0.

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
      isString := self isInstanceOfClassByteString: rcvr.
	isString ifTrue:
		[sz := objectMemory lengthOf: rcvr.
		 self internalStackTopPut: (objectMemory integerObjectOf: sz).
		^self fetchNextBytecode].

      isArray := self isInstanceOfClassArray: rcvr.
	isArray ifTrue:
		[sz := objectMemory lengthOf: rcvr.
		 self internalStackTopPut: (objectMemory integerObjectOf: sz).
		^self fetchNextBytecode].

	messageSelector := self specialSelector: 18.
	argumentCount := 0.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimSpecialSelector24 [

	messageSelector := self specialSelector: 24.
	argumentCount := self specialSelectorNumArgs: 24.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimSubtract [
	| rcvr arg result |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(self areIntegers: rcvr and: arg)
		ifTrue: [result := (objectMemory integerValueOf: rcvr) - (objectMemory integerValueOf: arg).
				(objectMemory isIntegerValue: result) ifTrue:
					[self internalPop: 2 thenPush: (objectMemory integerObjectOf: result).
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
	| rcvr isBlock |
	rcvr := self internalStackTop.
	argumentCount := 0.
	isBlock := self isInstanceOfClassBlockClosure: rcvr.
	isBlock ifTrue:
		[self externalizeIPandSP.
		self initPrimCall.
		self primitiveClosureValue.
		self internalizeIPandSP.
		self successful ifTrue:
			[^self fetchNextBytecode].
		primFailCode := 0].
	messageSelector := self specialSelector: 25.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimValueWithArg [
	| rcvr isBlock |
	rcvr := self internalStackValue: 1.
	argumentCount := 1.
	isBlock := self isInstanceOfClassBlockClosure: rcvr.
	isBlock ifTrue:
		[self externalizeIPandSP.
		self initPrimCall.
		self primitiveClosureValue.
		self internalizeIPandSP.
		self successful ifTrue:
			[^self fetchNextBytecode].
		primFailCode := 0].
	messageSelector := self specialSelector: 26.
	self normalSend
]

{ #category : #'plugin primitive support' }
StackInterpreter >> callExternalPrimitive: functionID [
	"Call the external plugin function identified. In the VM this is an address;
	 see StackInterpreterSimulator for its version."

	<var: #functionID declareC: 'void (*functionID)()'>
	self dispatchFunctionPointer: functionID
]

{ #category : #'miscellaneous bytecodes' }
StackInterpreter >> callPrimitiveBytecode [
	"249		11111001	i i i i i i i i	jjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjjj * 256)"
	self error: 'should not be evaluated. method activation should step beyond this bytecode.'
	"We could make it a noop and not skip it in {foo}ActivateMethod, as in:

	localIP := localIP + 3.
	self fetchNextBytecode

	 But for now, having {foo}ActivateMethod skip it makes it available for invoking embedded primitives."
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
	(self asserta: jmpDepth < MaxJumpBuf) ifFalse:
		[^false].
	jmpDepth := jmpDepth + 1.

	"Suspend the currently active process"
	suspendedCallbacks at: jmpDepth put: self activeProcess.
	"We need to preserve newMethod explicitly since it is not activated yet
	and therefore no context has been created for it. If the caller primitive
	for any reason decides to fail we need to make sure we execute the correct
	method and not the one 'last used' in the call back"
	suspendedMethods at: jmpDepth put: newMethod.
	"Signal external semaphores since a signalSemaphoreWithIndex: request may
	 have been issued immediately prior to this callback before the VM has any
	 chance to do a signalExternalSemaphores in checkForEventsMayContextSwitch:"
	self signalExternalSemaphores.
	"If no process is awakened by signalExternalSemaphores then transfer
	 to the highest priority runnable one."
	(suspendedCallbacks at: jmpDepth) == self activeProcess ifTrue:
		[self transferTo: self wakeHighestPriority].

	"Typically, invoking the callback means that some semaphore has been 
	signaled to indicate the callback. Force an interrupt check as soon as possible."
	self forceInterruptCheck.

	(self setjmp: (jmpBuf at: jmpDepth)) == 0 ifTrue: "Fill in callbackID"
		[callbackID at: 0 put: jmpDepth.
		self interpret].

	"Transfer back to the previous process so that caller can push result"
	self putToSleep: self activeProcess yieldingIf: preemptionYields.
	self transferTo: (suspendedCallbacks at: jmpDepth).
	newMethod := suspendedMethods at: jmpDepth.	"see comment above"
	argumentCount := self argumentCountOf: newMethod.
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
StackInterpreter >> canContextSwitchIfActivating: theMethod header: methodHeader [
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
	<api>
	<inline: true>
	primitiveIndex := self primitiveIndexOfMethod: theMethod header: methodHeader.
	^self cppIf: true
		ifTrue:
			[primitiveIndex ~= 198] "primitiveMarkUnwindMethod"
		ifFalse:
			[primitiveIndex = 0
			  or: [(primitiveIndex between: 85 and: 88) "primitiveSignal primitiveWait primitiveResume primitiveSuspend"
			  or: [primitiveIndex = 167]]] "primitiveYield"
]

{ #category : #'debug support' }
StackInterpreter >> capturePendingFinalizationSignals [
	statPendingFinalizationSignals := pendingFinalizationSignals.

]

{ #category : #'indexing primitive support' }
StackInterpreter >> characterForAscii: ascii [  "Arg must lie in range 0-255!"
	<inline: true>
	^ objectMemory fetchPointer: ascii ofObject: (objectMemory splObj: CharacterTable)
]

{ #category : #'debug support' }
StackInterpreter >> checkAllAccessibleObjectsOkay [
	"Ensure that all accessible objects in the heap are okay."
	<api>
	| ok oop |
	ok := true.
	oop := objectMemory firstAccessibleObject.
	[oop = nil] whileFalse:
		[ok := ok & (self checkOkayFields: oop).
		oop := objectMemory accessibleObjectAfter: oop].
	^ok
]

{ #category : #initialization }
StackInterpreter >> checkAssumedCompactClasses [
	"Check that the classes the VM assumes are compact have the right indices."
	objectMemory checkCompactIndex: ClassArrayCompactIndex isClass: ClassArray named: 'Array'.
	objectMemory checkCompactIndex: ClassLargeNegativeIntegerCompactIndex isClass: ClassLargeNegativeInteger named: 'LargeNegativeInteger'.
	objectMemory checkCompactIndex: ClassLargePositiveIntegerCompactIndex isClass: ClassLargePositiveInteger named: 'LargePositiveInteger'.
	objectMemory checkCompactIndex: ClassFloatCompactIndex isClass: ClassFloat named: 'Float'.
	objectMemory checkCompactIndex: ClassBlockClosureCompactIndex isClass: ClassBlockClosure named: 'BlockClosure'.
	objectMemory checkCompactIndex: ClassMethodContextCompactIndex isClass: ClassMethodContext named: 'MethodContext'.
	classByteArrayCompactIndex := objectMemory compactIndexOfClass: (objectMemory splObj: ClassByteArray)
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
		 longRunningPrimitiveGCUsecs := (objectMemory gcStartUsecs < longRunningPrimitiveStopUsecs
										   and: [objectMemory statGCEndUsecs > longRunningPrimitiveStartUsecs])
											ifTrue: [objectMemory statGCEndUsecs - objectMemory gcStartUsecs]
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
	statCheckForEvents := statCheckForEvents + 1.

	"restore the stackLimit if it has been smashed."
	self restoreStackLimit.
	self externalWriteBackHeadFramePointers.
	self assert: stackPage = stackPages mostRecentlyUsedPage.

	"Allow the platform to do anything it needs to do synchronously."
	self ioSynchronousCheckForEvents.

	self checkCogCompiledCodeCompactionCalledFor.

	objectMemory needGCFlag ifTrue:
		["sufficientSpaceAfterGC: runs the incremental GC and
		 then, if not enough space is available, the fullGC."
		 (objectMemory sufficientSpaceAfterGC: 0) ifFalse:
			[self setSignalLowSpaceFlagAndSaveProcess]].

	mayContextSwitch ifFalse: [^false].

	switched := false.

	(profileProcess ~= objectMemory nilObject
	 or: [nextProfileTick > 0 and:[self ioHighResClock >= nextProfileTick]]) ifTrue:
		["Take a sample (if not already done so) for the profiler if it is active.  This
		  must be done before any of the synchronousSignals below or else we will
		  attribute a pause in ioRelinquishProcessor to the newly activated process."
		profileProcess = objectMemory nilObject ifTrue:
			[profileProcess := self activeProcess.
			 profileMethod := objectMemory nilObject].
		"and signal the profiler semaphore if it is present"
		(profileSemaphore ~= objectMemory nilObject 
		 and: [self synchronousSignal: profileSemaphore]) ifTrue:
			[switched := true].
		nextProfileTick := 0].

	self checkDeliveryOfLongRunningPrimitiveSignal ifTrue:
		[switched := true].

	objectMemory signalLowSpace ifTrue:
		[objectMemory signalLowSpace: false. "reset flag"
		 sema := objectMemory splObj: TheLowSpaceSemaphore.
		 (sema ~= objectMemory nilObject 
		  and: [self synchronousSignal: sema]) ifTrue:
			[switched := true]].

	"inIOProcessEvents prevents reentrancy into ioProcessEvents and allows disabling
	 ioProcessEvents e.g. for native GUIs.  We would like to manage that here but can't
	 since the platform code may choose to call ioProcessEvents itself in various places."
	false
		ifTrue:
			[((now := self ioUTCMicroseconds) >= nextPollUsecs
			 and: [inIOProcessEvents = 0]) ifTrue:
				[statIOProcessEvents := statIOProcessEvents + 1.
				 inIOProcessEvents := inIOProcessEvents + 1.
				 self ioProcessEvents. "sets interruptPending if interrupt key pressed; may callback"
				 inIOProcessEvents > 0 ifTrue:
					[inIOProcessEvents := inIOProcessEvents - 1].
				 nextPollUsecs := now + 20000
				 "msecs to wait before next call to ioProcessEvents.  Note that strictly
				  speaking we might need to update 'now' at this point since
				  ioProcessEvents could take a very long time on some platforms"]]
		ifFalse:
			[(now := self ioUTCMicroseconds) >= nextPollUsecs ifTrue:
				[statIOProcessEvents := statIOProcessEvents + 1.
				 self ioProcessEvents. "sets interruptPending if interrupt key pressed; may callback"
				 nextPollUsecs := now + 20000
				 "msecs to wait before next call to ioProcessEvents.  Note that strictly
				  speaking we might need to update 'now' at this point since
				  ioProcessEvents could take a very long time on some platforms"]].

	interruptPending ifTrue:
		[interruptPending := false.
		 "reset interrupt flag"
		 sema := objectMemory splObj: TheInterruptSemaphore.
		 (sema ~= objectMemory nilObject 
		  and: [self synchronousSignal: sema]) ifTrue:
			[switched := true]].

	nextWakeupUsecs ~= 0 ifTrue:
		[now >= nextWakeupUsecs ifTrue:
			[nextWakeupUsecs := 0.
			 "set timer interrupt to 0 for 'no timer'"
			 sema := objectMemory splObj: TheTimerSemaphore.
			 (sema ~= objectMemory nilObject 
			  and: [self synchronousSignal: sema]) ifTrue:
				[switched := true]]].

	"signal any pending finalizations"
	pendingFinalizationSignals > 0 ifTrue:
		[sema := objectMemory splObj: TheFinalizationSemaphore.
		 ((objectMemory isClassOfNonImm: sema equalTo: (objectMemory splObj: ClassSemaphore))
		  and: [self synchronousSignal: sema]) ifTrue:
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
	"See traceProfileState & mapProfileState."
	longRunningPrimitiveStopUsecs = 0 ifTrue:
		[longRunningPrimitiveCheckSequenceNumber := statCheckForEvents.
		 longRunningPrimitiveCheckMethod := newMethod.
		 longRunningPrimitiveStartUsecs := self ioUTCMicroseconds.
		 self sqLowLevelMFence]
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
	self ioExitWithErrorCode: 1.
	^false
]

{ #category : #'object memory support' }
StackInterpreter >> checkInterpreterIntegrity [
	"Perform an integrity/leak check using the heapMap.  Assume
	 clearLeakMapAndMapAccessibleObjects has set a bit at each
	 object's header.  Check that all oops in the interpreter's state
	 points to a header.  Answer if all checks pass."
	| ok |
	ok := true.
	(objectMemory checkOopIntegrity: objectMemory specialObjectsOop named: 'specialObjectsOop')ifFalse:
		[ok := false].
	(objectMemory isIntegerObject: messageSelector) ifFalse:
		[(objectMemory checkOopIntegrity: messageSelector named: 'messageSelector')ifFalse:
			[ok := false]].
	(objectMemory checkOopIntegrity: newMethod named: 'newMethod')ifFalse:
		[ok := false].
	(objectMemory checkOopIntegrity: lkupClass named: 'lkupClass')ifFalse:
		[ok := false].
	(objectMemory checkOopIntegrity: profileProcess named: 'profileProcess')ifFalse:
		[ok := false].
	(objectMemory checkOopIntegrity: profileMethod named: 'profileMethod')ifFalse:
		[ok := false].
	(objectMemory checkOopIntegrity: profileSemaphore named: 'profileSemaphore')ifFalse:
		[ok := false].
	tempOop = 0 ifFalse:
		[(objectMemory checkOopIntegrity: tempOop named: 'tempOop')ifFalse:
			[ok := false]].

	"Callback support - check suspended callback list"
	1 to: jmpDepth do:
		[:i|
		(objectMemory checkOopIntegrity: (suspendedCallbacks at: i) named: 'suspendedCallbacks' index: i) ifFalse:
			[ok := false].
		(objectMemory checkOopIntegrity: (suspendedMethods at: i) named: 'suspendedMethods' index: i) ifFalse:
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
	(objectMemory isIntegerObject: (objectMemory fetchPointer: SenderIndex ofObject: aContext)) ifFalse:
		[^false].
	theFP := self frameOfMarriedContext: aContext.
	thePage := stackPages stackPageFor: theFP.
	limitFP := (thePage = stackPage and: [currentFP notNil])
				ifTrue: [currentFP]
				ifFalse: [thePage headFP].
	^theFP >= limitFP
	   and: [(objectMemory isNonIntegerObject: (self frameCallerFP: theFP) asInteger)
	   and: [(self withSmallIntegerTags: (self frameCallerFP: theFP))
			= (objectMemory fetchPointer: InstructionPointerIndex ofObject: aContext)
	   and: [(self frameMethodObject: theFP)
			= (objectMemory fetchPointer: MethodIndex ofObject: aContext)
	   and: [(self frameHasContext: theFP)
	   and: [(self frameContext: theFP) = aContext
	   and: [self isContext: aContext]]]]]]
]

{ #category : #'object memory support' }
StackInterpreter >> checkLogIntegrity [
	"This is a no-op in the StackInterpreter"
	^true
]

{ #category : #'debug support' }
StackInterpreter >> checkOkayFields: oop [
	"Check if the argument is an ok object.
	 If this is a pointers object, check that its fields are all okay oops."

	| hasYoung i fieldOop |
	(oop = nil or: [oop = 0]) ifTrue: [ ^true ]. "?? eem 1/16/2013"
	(objectMemory isIntegerObject: oop) ifTrue: [ ^true ].
	(objectMemory checkOkayOop: oop) ifFalse: [ ^false ].
	(self checkOopHasOkayClass: oop) ifFalse: [ ^false ].
	hasYoung := objectMemory isYoung: (objectMemory fetchClassOfNonInt: oop).
	((objectMemory isPointers: oop) or: [objectMemory isCompiledMethod: oop]) ifTrue:
		[(objectMemory isCompiledMethod: oop)
			ifTrue:
				[i := (self literalCountOf: oop) - 1]
			ifFalse:
				[(self isContext: oop)
					ifTrue: [i := CtxtTempFrameStart + (self fetchStackPointerOf: oop) - 1]
					ifFalse: [i := (objectMemory lengthOf: oop) - 1]].
		[i >= 0] whileTrue:
			[fieldOop := objectMemory fetchPointer: i ofObject: oop.
			(objectMemory isIntegerObject: fieldOop) ifFalse:
				[hasYoung := hasYoung or: [objectMemory isYoung: fieldOop].
				(objectMemory checkOkayOop: fieldOop) ifFalse: [ ^false ].
				(self checkOopHasOkayClass: fieldOop) ifFalse: [ ^false ]].
			i := i - 1]].
	hasYoung ifTrue:
		[^objectMemory checkOkayYoungReferrer: oop].
	^true
]

{ #category : #'debug support' }
StackInterpreter >> checkOkayInterpreterObjects: writeBack [
	<api>
	| ok oopOrZero oop |
	ok := true.
	ok := ok & (self checkOkayFields: objectMemory nilObject).
	ok := ok & (self checkOkayFields: objectMemory falseObject).
	ok := ok & (self checkOkayFields: objectMemory trueObject).
	ok := ok & (self checkOkayFields: objectMemory specialObjectsOop).
	ok := ok & (self checkOkayFields: messageSelector).
	ok := ok & (self checkOkayFields: newMethod).
	ok := ok & (self checkOkayFields: lkupClass).
	0 to: MethodCacheEntries - 1 by: MethodCacheEntrySize do:
		[ :i |
		oopOrZero := methodCache at: i + MethodCacheSelector.
		oopOrZero = 0 ifFalse:
			[ok := ok & (self checkOkayFields: (methodCache at: i + MethodCacheSelector)).
			ok := ok & (self checkOkayFields: (methodCache at: i + MethodCacheClass)).
			ok := ok & (self checkOkayFields: (methodCache at: i + MethodCacheMethod))]].
	1 to: objectMemory remapBufferCount do:
		[ :i |
		oop := objectMemory remapBuffer at: i.
		(objectMemory isIntegerObject: oop) ifFalse:
			[ok := ok & (self checkOkayFields: oop)]].
	ok := ok & (self checkOkayStackZone: writeBack).
	^ok
]

{ #category : #'debug support' }
StackInterpreter >> checkOkayStackPage: thePage [
	| theSP theFP ok frameRcvrOffset callerFP oop |
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #frameRcvrOffset type: #'char *'>
	<var: #callerFP type: #'char *'>
	<inline: false>
	theSP := thePage headSP.
	theFP := thePage  headFP.
	ok := true.
	"Skip the instruction pointer on top of stack of inactive pages."
	thePage = stackPage ifFalse:
		[theSP := theSP + BytesPerWord].
	[frameRcvrOffset := self frameReceiverOffset: theFP.
	 [theSP <= frameRcvrOffset] whileTrue:
		[oop := stackPages longAt: theSP.
		 (objectMemory isIntegerObject: oop) ifFalse:
			[ok := ok & (self checkOkayFields: oop)].
		 theSP := theSP + BytesPerWord].
	(self frameHasContext: theFP) ifTrue:
		[self assert: (self isContext: (self frameContext: theFP)).
		 ok := ok & (self checkOkayFields: (self frameContext: theFP))].
	ok := ok & (self checkOkayFields: (self frameMethodObject: theFP)).
	(callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
		[theSP := theFP + FoxCallerSavedIP + BytesPerWord.
		 theFP := callerFP].
	theSP := self isCog
				ifTrue: [theFP + FoxCallerSavedIP + BytesPerWord] "caller ip is ceBaseReturnPC"
				ifFalse: [theFP + FoxCallerSavedIP]. "caller ip is frameCallerContext in a base frame"
	[theSP <= thePage baseAddress] whileTrue:
		[oop := stackPages longAt: theSP.
		 (objectMemory isIntegerObject: oop) ifFalse:
			[ok := ok & (self checkOkayFields: oop)].
		 theSP := theSP + BytesPerWord].
	^ok
]

{ #category : #'debug support' }
StackInterpreter >> checkOkayStackZone: writeBack [
	"Check that all objects in the stack zone are okay"
	| ok thePage |
	<var: #thePage type: #'StackPage *'>
	<inline: false>
	writeBack ifTrue:
		[self externalWriteBackHeadFramePointers].
	ok := true.

	0 to: numStackPages - 1 do:
		[:i|
		thePage := stackPages stackPageAt: i.
		(stackPages isFree: thePage) ifFalse:
			[ok := ok & (self checkOkayStackPage: thePage)]].

	^ok
]

{ #category : #'debug support' }
StackInterpreter >> checkOopHasOkayClass: obj [
	"Attempt to verify that the given obj has a reasonable behavior. The class must be a
	 valid, non-integer oop and must not be nilObj. It must be a pointers object with three
	 or more fields. Finally, the instance specification field of the behavior must match that
	 of the instance. If OK answer true.  If  not, print reason and answer false."

	<api>
	<var: #oop type: #usqInt>
	| objClass formatMask behaviorFormatBits objFormatBits |
	<var: #oopClass type: #usqInt>

	(objectMemory checkOkayOop: obj) ifFalse:
		[^false].
	objClass := self cCoerce: (objectMemory fetchClassOfNonInt: obj) to: #usqInt.

	(objectMemory isIntegerObject: objClass) ifTrue:
		[self print: 'obj '; printHex: obj; print: ' a SmallInteger is not a valid class or behavior'; cr. ^false].
	(objectMemory okayOop: objClass) ifFalse:
		[self print: 'obj '; printHex: obj; print: ' class obj is not ok'; cr. ^false].
	((objectMemory isPointers: objClass) and: [(objectMemory lengthOf: objClass) >= 3]) ifFalse:
		[self print: 'obj '; printHex: obj; print: ' a class (behavior) must be a pointers object of size >= 3'; cr. ^false].
	formatMask := (objectMemory isBytes: obj)
						ifTrue: [16rC00]  "ignore extra bytes size bits"
						ifFalse: [16rF00].

	behaviorFormatBits := (objectMemory formatOfClass: objClass) bitAnd: formatMask.
	objFormatBits := (objectMemory baseHeader: obj) bitAnd: formatMask.
	behaviorFormatBits = objFormatBits ifFalse:
		[self print: 'obj '; printHex: obj; print: ' and its class (behavior) formats differ'; cr. ^false].
	^true
]

{ #category : #'process primitive support' }
StackInterpreter >> checkProfileTick: aPrimitiveMethod [
	"Check if the profile timer has expired and if so take a sample.
	 If the primitive has failed sample the profileMethod as nil."
	<inline: false>
	self assert: nextProfileTick ~= 0.
	self ioHighResClock >= nextProfileTick ifTrue:
		[profileProcess := self activeProcess.
		 profileMethod := self successful ifTrue: [aPrimitiveMethod] ifFalse: [objectMemory nilObject].
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
				 ((objectMemory isNonIntegerObject: oop) 
				   and: [(self heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
					[self printFrameThing: 'object leak in frame temp' at: theSP; cr.
					 ok := false].
				 theSP := theSP + BytesPerWord].
			 (self frameHasContext: theFP) ifTrue:
				[oop := self frameContext: theFP.
				 ((objectMemory isIntegerObject: oop) 
				   or: [(self heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
					[self printFrameThing: 'object leak in frame ctxt' at: theFP + FoxThisContext; cr.
					 ok := false].
				 (self isContext: oop) ifFalse:
					[self printFrameThing: 'frame ctxt should be context' at: theFP + FoxThisContext; cr.
					 ok := false]].
			 oop := self frameMethod: theFP.
			 ((objectMemory isIntegerObject: oop) 
			   or: [(self heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
				[self printFrameThing: 'object leak in frame mthd' at: theFP + FoxMethod; cr.
				 ok := false].
			 (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
				[theSP := theFP + FoxCallerSavedIP + BytesPerWord.
				 theFP := callerFP].
			 theSP := theFP + FoxCallerContext "a.k.a. FoxCallerSavedIP".
			 [theSP <= thePage baseAddress] whileTrue:
				[oop := stackPages longAt: theSP.
				 ((objectMemory isNonIntegerObject: oop) 
				   and: [(self heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
					[self printFrameThing: 'object leak in frame arg' at: theSP; cr.
					 ok := false].
				 theSP := theSP + BytesPerWord]]].
	^ok
]

{ #category : #utilities }
StackInterpreter >> checkedIntegerValueOf: intOop [
	"Note: May be called by translated primitive code."

	(objectMemory isIntegerObject: intOop)
		ifTrue: [ ^ objectMemory integerValueOf: intOop ]
		ifFalse: [ self primitiveFail. ^ 0 ]
]

{ #category : #'plugin primitive support' }
StackInterpreter >> classNameOf: aClass Is: className [ 
	"Check if aClass's name is className"
	| srcName name length |
	<var: #className type: #'char *'>
	<var: #srcName type: #'char *'>
	(objectMemory lengthOf: aClass) <= classNameIndex ifTrue:
		[^ false]. "Not a class but might be behavior"
	name := objectMemory fetchPointer: classNameIndex ofObject: aClass.
	(objectMemory isBytes: name) ifFalse:
		[^false].
	length := self stSizeOf: name.
	srcName := self cCoerce: (self arrayValueOf: name) to: 'char *'.
	0 to: length - 1 do: [:i | (srcName at: i) = (className at: i) ifFalse: [^false]].
	"Check if className really ends at this point"
	^(className at: length) = 0
]

{ #category : #'control primitives' }
StackInterpreter >> closureIn: context numArgs: numArgs instructionPointer: initialIP copiedValues: copiedValues [
	| newClosure numCopied |
	<inline: true>
	"numCopied should be zero for nil"
	numCopied := objectMemory fetchWordLengthOf: copiedValues.
	newClosure := objectMemory
					eeInstantiateSmallClass: (objectMemory splObj: ClassBlockClosure)
					sizeInBytes: (BytesPerWord * (ClosureFirstCopiedValueIndex + numCopied)) + BaseHeaderSize.
	"Assume: have just allocated a new closure; it must be young. Thus, can use unchecked stores."
	objectMemory storePointerUnchecked: ClosureOuterContextIndex ofObject: newClosure withValue: context.
	objectMemory storePointerUnchecked: ClosureStartPCIndex ofObject: newClosure withValue: (objectMemory integerObjectOf: initialIP).
	objectMemory storePointerUnchecked: ClosureNumArgsIndex ofObject: newClosure withValue: (objectMemory integerObjectOf: numArgs).
	0 to: numCopied - 1 do:
		[:i|
		objectMemory storePointerUnchecked: i + ClosureFirstCopiedValueIndex
			ofObject: newClosure
			withValue: (objectMemory fetchPointer: i ofObject: copiedValues)].
	^newClosure
]

{ #category : #'control primitives' }
StackInterpreter >> closureIn: context numArgs: numArgs instructionPointer: initialIP numCopiedValues: numCopied [
	| newClosure |
	<inline: true>
	self assert: (BytesPerWord * (ClosureFirstCopiedValueIndex + numCopied)) + BaseHeaderSize <= 252.
	newClosure := objectMemory
					eeInstantiateSmallClass: (objectMemory splObj: ClassBlockClosure)
					sizeInBytes: (BytesPerWord * (ClosureFirstCopiedValueIndex + numCopied)) + BaseHeaderSize.
	"Assume: have just allocated a new closure; it must be young. Thus, can use unchecked stores."
	objectMemory storePointerUnchecked: ClosureOuterContextIndex ofObject: newClosure withValue: context.
	objectMemory storePointerUnchecked: ClosureStartPCIndex ofObject: newClosure withValue: (objectMemory integerObjectOf: initialIP).
	objectMemory storePointerUnchecked: ClosureNumArgsIndex ofObject: newClosure withValue: (objectMemory integerObjectOf: numArgs).
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
	(objectMemory isNonIntegerObject: rcvr) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	index := self stackTop.
	"No need to test for large positive integers here.  No object has 1g elements"
	(objectMemory isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.

	"NOTE:  The at-cache, since it is specific to the non-super response to #at:.
	Therefore we must determine that the message is #at: (not, eg, #basicAt:),
	and that the send is not a super-send, before using the at-cache."
	(messageSelector = (self specialSelector: 16)
	 and: [lkupClass = (objectMemory fetchClassOfNonInt: rcvr)])
		ifTrue:
		["OK -- look in the at-cache"
		atIx := rcvr bitAnd: AtCacheMask.  "Index into atCache = 4N, for N = 0 ... 7"
		(atCache at: atIx+AtCacheOop) = rcvr ifFalse:
			["Rcvr not in cache.  Attempt to install it..."
			(self install: rcvr inAtCache: atCache at: atIx string: stringy) ifFalse:
				[self assert: (objectMemory isContextNonInt: rcvr).
				self initPrimCall.
				^self primitiveContextAt]].
		self successful ifTrue:
			[result := self commonVariable: rcvr at: index cacheIndex: atIx].
		self successful ifTrue:
			[^ self pop: argumentCount+1 thenPush: result]].

	"The slow but sure way..."
	self initPrimCall.
	result := self stObject: rcvr at: index.
	self successful ifTrue:
		[stringy ifTrue: [result := self characterForAscii: (objectMemory integerValueOf: result)].
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
	(objectMemory isNonIntegerObject: rcvr) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	index := self stackValue: 1.
	"No need to test for large positive integers here.  No object has 1g elements"
	(objectMemory isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.

	"NOTE:  The atPut-cache, since it is specific to the non-super response to #at:Put:.
	Therefore we must determine that the message is #at:Put: (not, eg, #basicAt:Put:),
	and that the send is not a super-send, before using the at-cache."
	(messageSelector = (self specialSelector: 17)
		and: [lkupClass = (objectMemory fetchClassOfNonInt: rcvr)])
		ifTrue:
		["OK -- look in the at-cache"
		atIx := (rcvr bitAnd: AtCacheMask) + AtPutBase.  "Index into atPutCache"
		(atCache at: atIx+AtCacheOop) = rcvr ifFalse:
			["Rcvr not in cache.  Attempt to install it..."
			(self install: rcvr inAtCache: atCache at: atIx string: stringy) ifFalse:
				[self assert: (objectMemory isContextNonInt: rcvr).
				self initPrimCall.
				^self primitiveContextAtPut]].
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
	<sharedCodeNamed: 'commonCallerReturn' inCase: #returnTopFromBlock>
	| callersFPOrNull |
	<var: #callersFPOrNull type: #'char *'>

	callersFPOrNull := self frameCallerFP: localFP.
	callersFPOrNull == 0 "baseFrame" ifTrue:
		[self assert: localFP = stackPage baseFP.
		 ^self baseFrameReturn].

	localIP := self frameCallerSavedIP: localFP.
	localSP := localFP + (self frameStackedReceiverOffset: localFP).
	localFP := callersFPOrNull.
	self setMethod: (self frameMethod: localFP).
	self fetchNextBytecode.
	^self internalStackTopPut: localReturnValue
]

{ #category : #'return bytecodes' }
StackInterpreter >> commonReturn [
	"Do an ^-return (return form method), perhaps checking for unwinds if this is a block activation.
	 Note: Assumed to be inlined into the dispatch loop."

	<sharedCodeNamed: 'commonReturn' inCase: #returnReceiver>
	| closure home unwindContextOrNilOrZero frameToReturnTo contextToReturnTo theFP callerFP newPage |
	<var: #frameToReturnTo type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #newPage type: #'StackPage *'>
	<var: #thePage type: #'StackPage *'>

	"If this is a method simply return to the  sender/caller."
	(self frameIsBlockActivation: localFP) ifFalse:
		[^self commonCallerReturn].

	"Since this is a block activation the closure is on the stack above any args and the frame."
	closure := self pushedReceiverOrClosureOfFrame: localFP.

	home := nil.
	"Walk the closure's lexical chain to find the context or frame to return from (home)."
	[closure ~= objectMemory nilObject] whileTrue:
		[home := objectMemory fetchPointer: ClosureOuterContextIndex ofObject: closure.
		 closure := objectMemory fetchPointer: ClosureIndex ofObject: home].
	"home is to be returned from provided there is no unwind-protect activation between
	 this frame and home's sender.  Search for an unwind.  findUnwindThroughContext:
	 will answer either the context for an unwind-protect activation or nilObj if the sender
	 cannot be found or 0 if no unwind is found but the sender is.  We must update the
	 current page's headFrame pointers to enable the search to identify widowed contexts
	 correctly."
	self writeBackHeadFramePointers.
	unwindContextOrNilOrZero := self internalFindUnwindThroughContext: home.
	unwindContextOrNilOrZero = objectMemory nilObject ifTrue:
		["error: can't find home on chain; cannot return"
		 ^self internalCannotReturn: localReturnValue].
	unwindContextOrNilOrZero ~= 0 ifTrue:
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
			[contextToReturnTo := objectMemory fetchPointer: SenderIndex ofObject: home.
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

	"Now we have a frame to return to.  If it is on a different page we must free intervening pages and
	 nil out intervening contexts.  We must free intervening stack pages because if we leave the pages
	 to be divorced then their contexts will be divorced with intact senders and instruction pointers.  This
	 code is similar to primitiveTerminateTo.  We must move any frames on itervening pages above the
	 frame linked to because these may be in use, e.g. via co-routining (see baseFrameReturn)."
	self assert: stackPages pageListIsWellFormed.
	newPage := stackPages stackPageFor: frameToReturnTo.
	newPage ~~ stackPage ifTrue:
		[| currentCtx thePage nextCntx |
		 currentCtx := self frameCallerContext: stackPage baseFP.
		 self assert: (self isContext: currentCtx).
		 stackPages freeStackPage: stackPage.
		 [self assert: (self isContext: currentCtx).
		  (self isMarriedOrWidowedContext: currentCtx)
		   and: [(stackPages stackPageFor: (theFP := self frameOfMarriedContext: currentCtx)) = newPage]] whileFalse:
			[(self isMarriedOrWidowedContext: currentCtx)
				ifTrue:
					[thePage := stackPages stackPageFor: theFP.
					 theFP ~= thePage headFP ifTrue:
						["Since we've just deallocated a page we know that newStackPage won't deallocate an existing one."
						 self moveFramesIn: thePage through: (self findFrameAbove: theFP inPage: thePage) toPage: self newStackPage].
					 currentCtx := self frameCallerContext: thePage baseFP.
					 stackPages freeStackPage: thePage]
				ifFalse:
					[nextCntx := objectMemory fetchPointer: SenderIndex ofObject: currentCtx.
					 self markContextAsDead: currentCtx.
					 currentCtx := nextCntx]].
		 self setStackPageAndLimit: newPage.
		 localSP := stackPage headSP.
		 localFP := stackPage headFP].

	"Two cases.  Returning to the top frame on a new page or an interior frame on the current page.
	 The top frame has its instruction pointer on top of stack. An interior frame has its instruction pointer
	 in the caller frame. We need to peel back any frames on the page until we get to the correct frame."

	localFP = frameToReturnTo
		ifTrue: "pop the saved IP, push the return value and continue."
			[localIP := self pointerForOop: self internalStackTop]
		ifFalse:
			[[callerFP := localFP.
			  localFP := self frameCallerFP: localFP.
			  localFP ~~ frameToReturnTo] whileTrue.
			localIP := self frameCallerSavedIP: callerFP.
			localSP := (self frameCallerSP: callerFP) - BytesPerWord].
	self setMethod: (self frameMethod: localFP).
	self fetchNextBytecode.
	^self internalStackTopPut: localReturnValue
]

{ #category : #'send bytecodes' }
StackInterpreter >> commonSend [
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that 
	the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeNamed: 'commonSend' inCase: #singleExtendedSendBytecode>
	self sendBreak: messageSelector + BaseHeaderSize
		point: (objectMemory lengthOf: messageSelector)
		receiver: (self internalStackValue: argumentCount).
	self printSends ifTrue:
		[self printActivationNameForSelector: messageSelector startClass: lkupClass; cr].
	self internalFindNewMethod.
	self internalExecuteNewMethod.
	self fetchNextBytecode
]

{ #category : #'send bytecodes' }
StackInterpreter >> commonSendAbsentImplicit [
	"Send a message to the implicit receiver for that message."
	"Assume: messageSelector and argumentCount have been set, and that 
	the arguments but not the receiver have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	"160-175	1010 i i i i		Send To Absent Implicit Receiver Literal Selector #iiii With 0 Arguments"
	"240		11110000	i i i i i j j j	Send To Absent Implicit Receiver Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	<sharedCodeNamed: 'commonSendAbsentImplicit' inCase: #extSendAbsentImplicitBytecode>
	| implicitReceiver |
	implicitReceiver := self
							implicitReceiverFor: self receiver
							mixin: (self methodClassOf: method)
							implementing: messageSelector.
	self shuffleArgumentsAndStoreAbsentReceiver: implicitReceiver.
	lkupClass := objectMemory fetchClassOf: implicitReceiver.
	self assert: lkupClass ~= objectMemory nilObject.
	self commonSend
]

{ #category : #'indexing primitive support' }
StackInterpreter >> commonVariable: rcvr at: index cacheIndex: atIx [ 
	"This code assumes the receiver has been identified at location atIx in the atCache."
	| stSize fmt fixedFields result |
	<inline: true>
	stSize := atCache at: atIx+AtCacheSize.
	((self oop: index isGreaterThanOrEqualTo: 1)
	 and: [self oop: index isLessThanOrEqualTo: stSize]) ifTrue:
		[fmt := atCache at: atIx+AtCacheFmt.
		 fmt <= 4 ifTrue:
			[self assert: (objectMemory isContextNonInt: rcvr) not.
			 fixedFields := atCache at: atIx+AtCacheFixedFields.
			 ^objectMemory fetchPointer: index + fixedFields - 1 ofObject: rcvr].
		 fmt < 8 ifTrue:  "Bitmap"
			[result := objectMemory fetchLong32: index - 1 ofObject: rcvr.
			 ^self positive32BitIntegerFor: result].
		 fmt >= 16  "Note fmt >= 16 is an artificial flag for strings"
			ifTrue: "String"
				[^self characterForAscii: (objectMemory fetchByte: index - 1 ofObject: rcvr)]
			ifFalse:
				[(fmt < 12 "ByteArray"
				  or: [index >= (self firstByteIndexOfMethod: rcvr) "CompiledMethod"]) ifTrue:
					[^objectMemory integerObjectOf: (objectMemory fetchByte: index - 1 ofObject: rcvr)]]].

	^self primitiveFailFor: ((objectMemory formatOf: rcvr) <= 1
								ifTrue: [PrimErrBadReceiver]
								ifFalse: [PrimErrBadIndex])
]

{ #category : #'indexing primitive support' }
StackInterpreter >> commonVariable: rcvr at: index put: value cacheIndex: atIx [
	"This code assumes the receiver has been identified at location atIx in the atCache."
	| stSize fmt fixedFields valToPut isCharacter |
	<inline: true>
	stSize := atCache at: atIx+AtCacheSize.
	((self oop: index isGreaterThanOrEqualTo: 1)
	  and: [self oop: index isLessThanOrEqualTo: stSize]) ifTrue:
		[fmt := atCache at: atIx+AtCacheFmt.
		fmt <= 4 ifTrue:
			[self assert: (objectMemory isContextNonInt: rcvr) not.
			 fixedFields := atCache at: atIx+AtCacheFixedFields.
			 ^objectMemory storePointer: index + fixedFields - 1 ofObject: rcvr withValue: value].
		fmt < 8 ifTrue:  "Bitmap"
			[valToPut := self positive32BitValueOf: value.
			self successful ifTrue: [objectMemory storeLong32: index - 1 ofObject: rcvr withValue: valToPut].
			^nil].
		fmt >= 16  "Note fmt >= 16 is an artificial flag for strings"
			ifTrue: [isCharacter := self isInstanceOfClassCharacter: value.
					isCharacter ifFalse:
						[^self primitiveFailFor: PrimErrBadArgument].
					valToPut := objectMemory fetchPointer: CharacterValueIndex ofObject: value]
			ifFalse:
				[(fmt >= 12 and: [index < (self firstByteIndexOfMethod: rcvr)]) ifTrue: "CompiledMethod"
					[^self primitiveFailFor: PrimErrBadIndex].
				valToPut := value].
		(objectMemory isIntegerObject: valToPut) ifTrue:
			[valToPut := objectMemory integerValueOf: valToPut.
			((valToPut >= 0) and: [valToPut <= 255]) ifFalse: [^self primitiveFailFor: PrimErrBadArgument].
			^objectMemory storeByte: index - 1 ofObject: rcvr withValue: valToPut]].

	^self primitiveFailFor: ((objectMemory formatOf: rcvr) <= 1
								ifTrue: [PrimErrBadReceiver]
								ifFalse: [PrimErrBadIndex])
]

{ #category : #'arithmetic primitive support' }
StackInterpreter >> compare31or32Bits: obj1 equal: obj2 [
	"May set success to false"

	"First compare two ST integers..."
	((objectMemory isIntegerObject: obj1)
		and: [objectMemory isIntegerObject: obj2])
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

{ #category : #'debug support' }
StackInterpreter >> context: aContext hasValidInversePCMappingOf: theIP in: theFP [
	"For asserts.  Check that theIP maps back correctly to the context's pc.
	 The CallPrimitive bytecode presents a complication."
	| pc encodedip |
	<var: #theFP type: #'char *'>
	pc := objectMemory fetchPointer: InstructionPointerIndex ofObject: aContext.
	encodedip := self contextInstructionPointer: theIP frame: theFP.
	^self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [pc = encodedip
				or: [| methodHeader |
					methodHeader := self headerOf: (objectMemory fetchPointer: MethodIndex ofObject: aContext).
					(self methodHeaderHasPrimitive: methodHeader)
					and: [(objectMemory integerValueOf: encodedip) - (objectMemory integerValueOf: pc)
						= (self sizeOfCallPrimitiveBytecode: methodHeader)]]]
		ifFalse: [pc = encodedip]
]

{ #category : #'frame access' }
StackInterpreter >> contextInstructionPointer: theIP frame: theFP [
	<var: #theFP type: #'char *'>
	self assert: (self validInstructionPointer: theIP inFrame: theFP).
	^objectMemory integerObjectOf: theIP - (self iframeMethod: theFP) - BaseHeaderSize + 2
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
	objectMemory vmEndianness = imageFloatsBigEndian ifTrue:
		[^nil].
	self assert: ClassFloatCompactIndex ~= 0.
	oop := startOop.
	[self oop: oop isLessThan: stopAddr] whileTrue:
		[(objectMemory isFreeObject: oop) ifFalse:
			[(objectMemory compactClassIndexOf: oop) = ClassFloatCompactIndex ifTrue:
				[temp := self longAt: oop + BaseHeaderSize.
				 self longAt: oop + BaseHeaderSize put: (self longAt: oop + BaseHeaderSize + 4).
				 self longAt: oop + BaseHeaderSize + 4 put: temp]].
		 oop := objectMemory objectAfter: oop]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> copiedValueCountOfClosure: closurePointer [

	^(objectMemory fetchWordLengthOf: closurePointer) - ClosureFirstCopiedValueIndex
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
	self assert: ((objectMemory isIntegerObject: messageSelector) or: [objectMemory addressCouldBeObj: messageSelector]).
	argumentArray := objectMemory eeInstantiateClass: (objectMemory splObj: ClassArray) indexableSize: argumentCount.
	message := objectMemory eeInstantiateClass: (objectMemory splObj: ClassMessage) indexableSize: 0.

	"Since the array is new can use unchecked stores."
	(argumentCount - 1) * BytesPerWord to: 0 by: BytesPerWord negated do:
		[:i|
		self longAt:  argumentArray + BaseHeaderSize + i put: self popStack].
	"Since message is new can use unchecked stores."
	objectMemory storePointerUnchecked: MessageSelectorIndex ofObject: message withValue: messageSelector.
	objectMemory storePointerUnchecked: MessageArgumentsIndex ofObject: message withValue: argumentArray.
	objectMemory storePointerUnchecked: MessageLookupClassIndex ofObject: message withValue: lookupClass.

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
	((objectMemory isNonIntegerObject: oop)
	and: [(objectMemory fetchClassOfNonInt: oop) = (objectMemory splObj: ClassFloat)]) ifTrue:
		[self cCode: '' inSmalltalk: [result := Float new: 2].
		 objectMemory fetchFloatAt: oop + BaseHeaderSize into: result.
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

{ #category : #'debug support' }
StackInterpreter >> detailedSymbolicMethod: aMethod [
	<doNotGenerate>
	| ts prim proxy |
	(ts := self transcript) ensureCr.
	(prim := self primitiveIndexOf: aMethod) > 0 ifTrue:
		[ts nextPutAll: '<primitive: '; print: prim; nextPut: $>.
		(self isQuickPrimitiveIndex: prim) ifTrue:
			[ts nextPutAll: ' quick method'; cr; flush.
			 ^self].
		ts cr].
	proxy := VMCompiledMethodProxy new
					for: aMethod
					coInterpreter: self
					objectMemory: objectMemory.
	(DetailedInstructionPrinter on: proxy)
		stackHeightComputer: ((NewspeakVM
										ifTrue: [NewspeakStackDepthFinder]
										ifFalse: [StackDepthFinder])
									on: proxy);
		indent: 0;
		printInstructionsOn: ts.
	ts flush
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
	displayObj := objectMemory splObj: TheDisplay.
	aForm = displayObj ifFalse: [^ nil].
	self success: ((objectMemory isPointers: displayObj) and: [(objectMemory lengthOf: displayObj) >= 4]).
	self successful ifTrue: [
		dispBits := objectMemory fetchPointer: 0 ofObject: displayObj.
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
		(objectMemory isIntegerObject: dispBits) ifTrue: [
			surfaceHandle := objectMemory integerValueOf: dispBits.
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
	 objectMemory storePointerUnchecked: InstructionPointerIndex
		ofObject: theContext
		withValue: (self contextInstructionPointer: theIP frame: theFP).
	 self assert: (self frameReceiver: theFP)
				= (objectMemory fetchPointer: ReceiverIndex ofObject: theContext).
	 calleeContext ~~ nil ifTrue:
		[objectMemory storePointer: SenderIndex
			ofObject: calleeContext
			withValue: theContext].
	 calleeContext := theContext.
	 calleeFP := theFP.
	 theIP := (self frameCallerSavedIP: theFP) asInteger.
	 theFP := self frameCallerFP: theFP.
	 theFP ~= 0] whileTrue:
		["theSP points at stacked hottest item on frame's stack"
		 theSP := self frameCallerSP: calleeFP].

	objectMemory storePointer: SenderIndex
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
		ifTrue: [integerRcvr := objectMemory integerValueOf: rcvr.
				integerArg := objectMemory integerValueOf: arg.
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
	self success: (objectMemory isIntegerValue: result).
	^ result
]

{ #category : #'arithmetic primitive support' }
StackInterpreter >> doPrimitiveMod: rcvr by: arg [
	| integerResult integerRcvr integerArg |
	(self areIntegers: rcvr and: arg)
		ifTrue: [integerRcvr := objectMemory integerValueOf: rcvr.
				integerArg := objectMemory integerValueOf: arg.
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
	self success: (objectMemory isIntegerValue: integerResult).
	^ integerResult
]

{ #category : #'process primitive support' }
StackInterpreter >> doSignalSemaphoreWithIndex: index [
	"Signal the external semaphore with the given index.  Answer if a context switch
	 occurs as a result.  Do not bounds check.  This has been done in the caller."
	<api>
	| xArray semaphoreClass sema |
	xArray := objectMemory splObj: ExternalObjectsArray.
	semaphoreClass := objectMemory splObj: ClassSemaphore.
	sema := objectMemory fetchPointer: index - 1 ofObject: xArray. "Note: semaphore indices are 1-based"
	^(objectMemory isNonIntegerObject: sema)
	   and: [(objectMemory fetchClassOfNonInt: sema) = semaphoreClass
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
		[^objectMemory storePointer: ValueIndex ofObject: (self literal: byte3) withValue: top].
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
	dataSize := objectMemory endOfMemory - objectMemory startOfMemory.
	result := self cCode: 'sqImageFileWrite(pointerForOop(memory), sizeof(unsigned char), dataSize, f)'.
	self cCode: 'sqImageFileClose(f)'.
	^result

]

{ #category : #'debug support' }
StackInterpreter >> dumpPrimTraceLog [
	"Dummy definition to allow the StackInterpreter to link against the Cog run-time."

	<api>
]

{ #category : #'stack bytecodes' }
StackInterpreter >> duplicateTopBytecode [

	self fetchNextBytecode.
	self internalPush: self internalStackTop.

]

{ #category : #'send bytecodes' }
StackInterpreter >> dynamicSuperSendBytecode [
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
		startingAtBehavior: (objectMemory fetchClassOf: rcvr).
	lkupClass := self superclassOf: mixinApplication.
	self commonSend
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
StackInterpreter >> ensureContextIsExecutionSafeAfterAssignToStackPointer: aContext [
	"Safety to give the JIT lattitude in calling convention.  A noop in the interpreter.
	 See subclass implementation(s) for explanation."
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
		ifFalse: [self convertFloatsToPlatformOrderFrom: objectMemory firstObject to: objectMemory freeStart]
]

{ #category : #'callback support' }
StackInterpreter >> enterSmalltalkExecutiveFromCallback [
	<inline: true>
	self interpret
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
	(objectMemory isIntegerObject: (objectMemory fetchPointer: InstructionPointerIndex ofObject: contextToReturnTo)) ifFalse:
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

{ #category : #'newspeak bytecode support' }
StackInterpreter >> explicitOuterReceiver: n withObject: anObject withMixin: mixin [ 
	"This is used to implement the innards of the pushExplicitOuterReceiverBytecode,
	 used for explicit outer sends in NS2/NS3.  "
	| explicitReceiver mixinApplication  targetMixin  count |
	
	explicitReceiver := anObject.
	targetMixin := mixin.
	count := 0.
	[count < n] whileTrue:
		[count := count + 1.
		(targetMixin = objectMemory nilObject or:[explicitReceiver = objectMemory nilObject]) ifTrue:
			[^objectMemory nilObject].
		mixinApplication := self
								findApplicationOfTargetMixin: targetMixin
								startingAtNonMetaClass: (self fetchClassOf: explicitReceiver).
		mixinApplication = objectMemory nilObject ifTrue:
			[^objectMemory nilObject]. "should never happen!"
		explicitReceiver := objectMemory fetchPointer: EnclosingObjectIndex ofObject: mixinApplication.	
		targetMixin := objectMemory fetchPointer: EnclosingMixinIndex ofObject: targetMixin].
	
	^explicitReceiver
]

{ #category : #'miscellaneous bytecodes' }
StackInterpreter >> extABytecode [
	"224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)"
	extA := (extA bitShift: 8) + self fetchByte.
	self fetchNextBytecode
]

{ #category : #'miscellaneous bytecodes' }
StackInterpreter >> extBBytecode [
	"225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)"
	| byte |
	byte := self fetchByte.
	self fetchNextBytecode.
	extB := (extB = 0 and: [byte > 127])
				ifTrue: [byte - 256]
				ifFalse: [(extB bitShift: 8) + byte]
]

{ #category : #'jump bytecodes' }
StackInterpreter >> extJumpIfFalse [
	"244		11110100	i i i i i i i i	Pop and Jump 0n False i i i i i i i i (+ Extend B * 256, where Extend B >= 0)"
	| byte offset |
	byte := self fetchByte.
	offset := byte + (extB << 8).
	extB := 0.
	self jumplfFalseBy: offset
]

{ #category : #'jump bytecodes' }
StackInterpreter >> extJumpIfTrue [
	"243		11110011	i i i i i i i i	Pop and Jump 0n True i i i i i i i i (+ Extend B * 256, where Extend B >= 0)"
	| byte offset |
	byte := self fetchByte.
	offset := byte + (extB << 8).
	extB := 0.
	self jumplfTrueBy: offset
]

{ #category : #'miscellaneous bytecodes' }
StackInterpreter >> extNopBytecode [
	"221		11011101		Nop"
	extA := extB := 0
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushClosureBytecode [
	"253		11111101 eei i i kkk	jjjjjjjj		Push Closure Num Copied iii (+ Ext A // 16 * 8) Num Args kkk (+ Ext A \\ 16 * 8) BlockSize jjjjjjjj (+ Ext B * 256). ee = num extensions.
	 The compiler has pushed the values to be copied, if any.  Find numArgs and numCopied in the byte following.
	 Create a Closure with space for the copiedValues and pop numCopied values off the stack into the closure.
	 Set numArgs as specified, and set startpc to the pc following the block size and jump over that code."
	| byte numArgs numCopied blockSize |
	byte := self fetchByte.
	numArgs := (byte bitAnd: 7) + (extA \\ 16 * 8).
	numCopied := ((byte >> 3) bitAnd: 7) + (extA // 16 * 8).
	extA := 0.
	blockSize := self fetchByte + (extB << 8).
	extB := 0.
	self pushClosureNumArgs: numArgs copiedValues: numCopied blockSize: blockSize
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushIntegerBytecode [
	"229		11100101	i i i i i i i i	Push Integer #iiiiiiii (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	| value |
	value := self fetchByte + (extB << 8).
	self fetchNextBytecode.
	extB := 0.
	self internalPush: (objectMemory integerObjectOf: value)
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushLiteralBytecode [
	"228		11100100	i i i i i i i i	Push Literal #iiiiiiii (+ Extend A * 256)"
	| index |
	index := self fetchByte + (extA << 8).
	self fetchNextBytecode.
	extA := 0.
	self pushLiteralConstant: index
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushLiteralVariableBytecode [
	"227		11100011	i i i i i i i i	Push Literal Variable #iiiiiiii (+ Extend A * 256)"
	| index |
	index := self fetchByte + (extA << 8).
	self fetchNextBytecode.
	extA := 0.
	self pushLiteralVariable: index
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushPseudoVariableOrOuterBytecode [
	"77			01001101		Push false [* 1:true, 2:nil, 3:thisContext, ..., -N: pushExplicitOuter: N, N = Extend B]"
	| thing |
	self fetchNextBytecode.
	thing := extB
				caseOf: {
					[0]	->	[^self internalPush: objectMemory falseObject].
					[1]	->	[objectMemory trueObject].
					[2]	->	[objectMemory nilObject].
					[3]	->	[| context |
							 context := self ensureFrameIsMarried: localFP SP: localSP.
							 context]
				}
				otherwise:
					[extB < 0
						ifTrue:
							[self 
								explicitOuterReceiver: 0 - extB 
								withObject: self receiver 
								withMixin: (self methodClassOf: method)]
						ifFalse:
							[self error: 'undefined extension for extPushPseudoVariableOrOuter'.
							 objectMemory nilObject]].
	extB := 0.
	self internalPush: thing
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushReceiverVariableBytecode [
	"226		11100010	i i i i i i i i	Push Receiver Variable #iiiiiiii (+ Extend A * 256)"
	| index |
	index := self fetchByte + (extA << 8).
	self fetchNextBytecode.
	extA := 0.
	self pushMaybeContextReceiverVariable: index
]

{ #category : #'return bytecodes' }
StackInterpreter >> extReturnTopFromBlock [
	"218		11011010		Return Stack Top From Block [* return from enclosing block N, N = Extend A]
	 If extA is zero, return to the caller of the current block activation.
	 If extA is non-zero return to the caller of the Nth enclosing block activation."
	extA = 0 ifTrue:
		[localReturnValue := self internalStackTop.
		 ^self commonCallerReturn].
	self shouldBeImplemented.
	extA := 0
]

{ #category : #'send bytecodes' }
StackInterpreter >> extSendAbsentDynamicSuperBytecode [
	"241		11110001	i i i i i j j j	Send To Dynamic Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	| byte mClassMixin mixinApplication |
	byte := self fetchByte.
	messageSelector := self literal: (byte >> 3) + (extA << 5).
	extA := 0.
	argumentCount := (byte bitAnd: 7) + (extB << 3).
	extB := 0.
	self shuffleArgumentsAndStoreAbsentReceiver: self receiver.
	mClassMixin := self methodClassOf: method.
	mixinApplication := self 
							findApplicationOfTargetMixin: mClassMixin
							startingAtBehavior: (objectMemory fetchClassOf: self receiver).
	lkupClass := self superclassOf: mixinApplication.
	self commonSend
]

{ #category : #'send bytecodes' }
StackInterpreter >> extSendAbsentImplicitBytecode [
	"240		11110000	i i i i i j j j	Send To Absent Implicit Receiver Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	| byte |
	byte := self fetchByte.
	messageSelector := self literal: (byte >> 3) + (extA << 5).
	extA := 0.
	argumentCount := (byte bitAnd: 7) + (extB << 3).
	extB := 0.
	self commonSendAbsentImplicit
]

{ #category : #'send bytecodes' }
StackInterpreter >> extSendBytecode [
	"238		11101110	i i i i i j j j	Send Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	| byte rcvr |
	byte := self fetchByte.
	messageSelector := self literal: (byte >> 3) + (extA << 5).
	extA := 0.
	argumentCount := (byte bitAnd: 7) + (extB << 3).
	extB := 0.
	rcvr := self internalStackValue: argumentCount.
	lkupClass := objectMemory fetchClassOf: rcvr.
	self assert: lkupClass ~= objectMemory nilObject.
	self commonSend
]

{ #category : #'send bytecodes' }
StackInterpreter >> extSendSuperBytecode [
	"239		11101111	i i i i i j j j	Send To Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	| byte |
	byte := self fetchByte.
	messageSelector := self literal: (byte >> 3) + (extA << 5).
	extA := 0.
	argumentCount := (byte bitAnd: 7) + (extB << 3).
	extB := 0.
	self superclassSend.
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extStoreAndPopLiteralVariableBytecode [
	"236		11101100	i i i i i i i i	Pop and Store Literal Variable #iiiiiiii (+ Extend A * 256)"
	self extStoreLiteralVariableBytecode.
	self internalPop: 1
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extStoreAndPopReceiverVariableBytecode [
	"235		11101011	i i i i i i i i	Pop and Store Receiver Variable #iiiiiii (+ Extend A * 256)"
	self extStoreReceiverVariableBytecode.
	self internalPop: 1
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extStoreLiteralVariableBytecode [
	"233		11101001	i i i i i i i i	Store Literal Variable #iiiiiiii (+ Extend A * 256)"
	| association variableIndex |
	variableIndex := self fetchByte + (extA << 8).
	self fetchNextBytecode.
	extA := 0.
	association := self literal: variableIndex.
	objectMemory storePointer: ValueIndex ofObject: association withValue: self internalStackTop
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extStoreReceiverVariableBytecode [
	"232		11101000	i i i i i i i i	Store Receiver Variable #iiiiiii (+ Extend A * 256)"
	| variableIndex |
	variableIndex := self fetchByte + (extA << 8).
	self fetchNextBytecode.
	extA := 0.
	self storeMaybeContextReceiverVariable: variableIndex withValue: self internalStackTop
]

{ #category : #'jump bytecodes' }
StackInterpreter >> extUnconditionalJump [
	"242		11110010	i i i i i i i i	Jump i i i i i i i i (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	| byte offset |
	byte := self fetchByte.
	offset := byte + (extB << 8).
	extB := 0.
	localIP := localIP + offset.
	self ifBackwardsCheckForEvents: offset.
	self fetchNextBytecode
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
		[^objectMemory storePointer: variableIndex ofObject: self receiver withValue: self internalStackTop].
	variableType = 1 ifTrue:
		[^self temporary: variableIndex in: localFP put: self internalStackTop].
	variableType = 3 ifTrue:
		[association := self literal: variableIndex.
		 ^objectMemory storePointer: ValueIndex ofObject: association withValue: self internalStackTop].
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
	objectMemory storePointerUnchecked: InstructionPointerIndex
		ofObject: ctxt
		withValue: (self contextInstructionPointer: theIP frame: theFP).
	objectMemory storePointer: SenderIndex
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

	self assert: (self isContext: aContext).
	"method, closureOrNil & receiver need no special handling; only
	 sender, pc & stackp have to be computed for married contexts."
	(offset < MethodIndex 
	 and: [self isMarriedOrWidowedContext: aContext]) ifFalse:
		[^objectMemory fetchPointer: offset ofObject: aContext].

	self externalWriteBackHeadFramePointers.
	(self isWidowedContext: aContext) ifTrue:
		[^objectMemory fetchPointer: offset ofObject: aContext].

	spouseFP := self frameOfMarriedContext: aContext.
	offset = SenderIndex ifTrue:
		[^self ensureCallerContext: spouseFP].
	offset = StackPointerIndex ifTrue:
		[self assert: ReceiverIndex + (self stackPointerIndexForFrame: spouseFP) < (objectMemory lengthOf: aContext).
		^objectMemory integerObjectOf: (self stackPointerIndexForFrame: spouseFP)].
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
	self assert: (self isContext: maybeMarriedContext).
	self externalWriteBackHeadFramePointers.
	"Assign the field of a married context."
	(self isStillMarriedContext: maybeMarriedContext) ifFalse:
		[objectMemory storePointer: index ofObject: maybeMarriedContext withValue: anOop.
		 index = StackPointerIndex ifTrue:
			[self ensureContextIsExecutionSafeAfterAssignToStackPointer: maybeMarriedContext].
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
			 objectMemory storePointer: index ofObject: maybeMarriedContext withValue: anOop.
			 index = StackPointerIndex ifTrue:
				[self ensureContextIsExecutionSafeAfterAssignToStackPointer: maybeMarriedContext]].
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
	"Invoke a quick primitive.
	 Called under the assumption that primFunctionPtr has been preloaded"
	
	| localPrimIndex |
	self assert: self isPrimitiveFunctionPointerAnIndex.
	localPrimIndex := self cCoerceSimple: primitiveFunctionPointer to: #sqInt.
	self assert: (localPrimIndex > 255 and: [localPrimIndex < 520]).
	"Quick return inst vars"
	localPrimIndex >= 264 ifTrue:
		[self pop: 1 thenPush: (objectMemory fetchPointer: localPrimIndex - 264 ofObject: self stackTop).
		 ^true].
	"Quick return constants"
	localPrimIndex = 256 ifTrue: [^true "return self"].
	localPrimIndex = 257 ifTrue: [self pop: 1 thenPush: objectMemory trueObject. ^true].
	localPrimIndex = 258 ifTrue: [self pop: 1 thenPush: objectMemory falseObject. ^true].
	localPrimIndex = 259 ifTrue: [self pop: 1 thenPush: objectMemory nilObject. ^true].
	self pop: 1 thenPush: (objectMemory integerObjectOf: localPrimIndex - 261).
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
	
	newContext := objectMemory fetchPointer: SuspendedContextIndex ofObject: aProcess.
	self assert: (self isContext: newContext).
	(self isMarriedOrWidowedContext: newContext) ifTrue:
		[self assert: (self checkIsStillMarriedContext: newContext currentFP: framePointer)].
	objectMemory storePointerUnchecked: SuspendedContextIndex ofObject: aProcess withValue: objectMemory nilObject.
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
		[self setMethod: (self iframeMethod: framePointer)].
	self assertValidExecutionPointe: self stackTop asUnsignedInteger r: framePointer s: stackPointer
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

{ #category : #utilities }
StackInterpreter >> fetchArray: fieldIndex ofObject: objectPointer [
	"Fetch the instance variable at the given index of the given object. Return the address of first indexable field of resulting array object, or fail if the instance variable does not contain an indexable bytes or words object."
	"Note: May be called by translated primitive code."

	| arrayOop |
	<returnTypeC: 'void *'>
	arrayOop := objectMemory fetchPointer: fieldIndex ofObject: objectPointer.
	^ self arrayValueOf: arrayOop

]

{ #category : #'interpreter shell' }
StackInterpreter >> fetchByte [
	"This method uses the preIncrement builtin function which has no Smalltalk equivalent. Thus, it must be overridden in the simulator."

	^objectMemory byteAtPointer: localIP preIncrement
]

{ #category : #utilities }
StackInterpreter >> fetchFloat: fieldIndex ofObject: objectPointer [
	"Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float."
	"Note: May be called by translated primitive code."

	| floatOop |
	<returnTypeC: 'double'>
	floatOop := objectMemory fetchPointer: fieldIndex ofObject: objectPointer.
	^ self floatValueOf: floatOop
]

{ #category : #utilities }
StackInterpreter >> fetchInteger: fieldIndex ofObject: objectPointer [
	"Note: May be called by translated primitive code."

	| intOop |
	<inline: false>
	intOop := objectMemory fetchPointer: fieldIndex ofObject: objectPointer.
	^self checkedIntegerValueOf: intOop
]

{ #category : #'interpreter shell' }
StackInterpreter >> fetchNextBytecode [
	"This method fetches the next instruction (bytecode). Each bytecode method is responsible for fetching the next bytecode, preferably as early as possible to allow the memory system time to process the request before the next dispatch."

	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := self fetchByte + bytecodeSetSelector]
		ifFalse: [currentBytecode := self fetchByte]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> fetchStackPointerOf: aContext [
	"Return the stackPointer of a Context or BlockContext.
	 Does not deal with married contexts.  Use only for debug
	 printing or object tracing functions.  To obtain an accurate
	 stack pointer use stackPointerForMaybeMarriedContext:"
	| sp |
	<inline: true>
	sp := objectMemory fetchPointer: StackPointerIndex ofObject: aContext.
	(objectMemory isIntegerObject: sp) ifFalse: [^0].
	self assert: ReceiverIndex + (objectMemory integerValueOf: sp) < (objectMemory lengthOf: aContext).
	^objectMemory integerValueOf: sp
]

{ #category : #'newspeak bytecode support' }
StackInterpreter >> findApplicationOfTargetMixin: targetMixin startingAtBehavior: aBehavior [
	"This is used to implement the innards of the pushImplicitReceiverBytecode,
	 used for outer sends in NS2/NS3.  Find the MixinApplcation of which aBehavior
	 is a subclass that is an application of targetMixin.  This is an implementation derived from

	<ContextPart> findApplicationOfTargetMixin: targetMixin startingAtBehavior: aBehavior
	"
	| mixinOrMixinApplication mixin |
	mixinOrMixinApplication := aBehavior.
	[mixinOrMixinApplication = objectMemory nilObject
	 or: [mixinOrMixinApplication = targetMixin
	 or: [(mixin := objectMemory fetchPointer: MixinIndex ofObject: mixinOrMixinApplication) = targetMixin
	 or: [(objectMemory fetchClassOfNonInt: mixin) = targetMixin]]]] whileFalse:
		[mixinOrMixinApplication := objectMemory fetchPointer: SuperclassIndex ofObject: mixinOrMixinApplication].
	^mixinOrMixinApplication
]

{ #category : #'newspeak bytecode support' }
StackInterpreter >> findApplicationOfTargetMixin: targetMixin startingAtNonMetaClass: aClass [
	"This is used to implement the innards of the pushImplicitReceiverBytecode,
	 used for outer sends in NS2/NS3.  Find the MixinApplcation of which aClass
	 is a subclass that is an application of targetMixin.  This is an implementation derived from

	<ContextPart> findApplicationOfTargetMixin: targetMixin startingAtNonMetaClass: aClass
	"
	| mixinOrMixinApplication |
	mixinOrMixinApplication := aClass.
	[mixinOrMixinApplication = objectMemory nilObject
	 or: [mixinOrMixinApplication = targetMixin
	 or: [(objectMemory fetchPointer: MixinIndex ofObject: mixinOrMixinApplication) = targetMixin]]] whileFalse:
		[mixinOrMixinApplication := objectMemory fetchPointer: SuperclassIndex ofObject: mixinOrMixinApplication].
	^mixinOrMixinApplication
]

{ #category : #'debug support' }
StackInterpreter >> findClassForSelector: aSelector lookupClass: startClass do: unaryBlock [
	"Search startClass' class hierarchy looking for aSelector and if found, evaluate unaryBlock
	 with the class where the selector is found.  Otherwise evaluate unaryBlock with nil."
	| currClass classDict classDictSize i |
	currClass := startClass.
	[classDict := objectMemory fetchPointer: MethodDictionaryIndex ofObject: currClass.
	 classDictSize := objectMemory fetchWordLengthOf: classDict.
	 i := SelectorStart.
	 [i < classDictSize] whileTrue:
		[aSelector = (objectMemory fetchPointer: i ofObject: classDict) ifTrue:
			[^unaryBlock value: currClass].
			i := i + 1].
	 currClass := self superclassOf: currClass.
	 currClass = objectMemory nilObject] whileFalse.
	^unaryBlock value: nil    "selector not found in superclass chain"
		
]

{ #category : #'debug support' }
StackInterpreter >> findClassOfMethod: meth forReceiver: rcvr [

	| rclass currClass classDict classDictSize methodArray i |
	(objectMemory addressCouldBeObj: meth) ifFalse:
		[^objectMemory nilObject].
	(objectMemory addressCouldBeOop: rcvr)
		ifTrue: [rclass := objectMemory fetchClassOf: rcvr]
		ifFalse: [rclass := self methodClassOf: meth].
	currClass := rclass.
	[classDict := objectMemory fetchPointer: MethodDictionaryIndex ofObject: currClass.
	 classDictSize := objectMemory fetchWordLengthOf: classDict.
	 methodArray := objectMemory fetchPointer: MethodArrayIndex ofObject: classDict.
	 i := 0.
	 [i < (classDictSize - SelectorStart)] whileTrue:
		[meth = (objectMemory fetchPointer: i ofObject: methodArray) ifTrue:
			[^currClass].
		 i := i + 1].
	 currClass := self superclassOf: currClass.
	 currClass = objectMemory nilObject] whileFalse.
	^rclass		"method not found in superclass chain"
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
	(self isContext: aContext) ifFalse:
		[^nil].
	closureOrNil := objectMemory fetchPointer: ClosureIndex ofObject: aContext.
	closureOrNil = objectMemory nilObject ifTrue:
		[^aContext].
	(objectMemory fetchClassOf: closureOrNil) ~= (objectMemory splObj: ClassBlockClosure) ifTrue:
		[^nil].
	^self findHomeForContext: (objectMemory fetchPointer: ClosureOuterContextIndex ofObject: closureOrNil)
]

{ #category : #'handler search' }
StackInterpreter >> findMethodWithPrimitive: primitive FromContext: senderContext UpToContext: homeContext [
	"See findUnwindThroughContext:.  Alas this is mutually recursive with
	 findMethodWithPrimitive:FromFP:SP:ThroughContext: instead of iterative.
	 We're doing the simplest thing that could possibly work.  Niceties can wait."
	| theContext theMethod |
	self assert: (senderContext = objectMemory nilObject or: [self isContext: senderContext]).
	self assert: (homeContext = objectMemory nilObject or: [self isContext: homeContext]).
	theContext := senderContext.
	[theContext = objectMemory nilObject ifTrue:
		[^theContext].
	 self isMarriedOrWidowedContext: theContext] whileFalse:
		[theContext = homeContext ifTrue: [^0].
		 (objectMemory fetchPointer: ClosureIndex ofObject: theContext) = objectMemory nilObject ifTrue:
		 	[theMethod := objectMemory fetchPointer: MethodIndex ofObject: theContext.
			 (self primitiveIndexOf: theMethod) == primitive ifTrue:
				[^theContext]].
		 theContext := objectMemory fetchPointer: SenderIndex ofObject: theContext].
	(self isWidowedContext: theContext) ifTrue:
		[^objectMemory nilObject].
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
		[^objectMemory nilObject].
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
StackInterpreter >> findSelectorAndClassForMethod: meth lookupClass: startClass do: binaryBlock [
	"Search startClass' class hierarchy searching for method and if found, evaluate aBinaryBlock
	 with the selector and class where the method is found.  Otherwise evaluate aBinaryBlock
	 with doesNotUnderstand: and nil."
	| currClass classDict classDictSize methodArray i |
	currClass := startClass.
	[classDict := objectMemory fetchPointer: MethodDictionaryIndex ofObject: currClass.
	 classDictSize := objectMemory fetchWordLengthOf: classDict.
	 methodArray := objectMemory fetchPointer: MethodArrayIndex ofObject: classDict.
	 i := 0.
	 [i <= (classDictSize - SelectorStart)] whileTrue:
		[meth = (objectMemory fetchPointer: i ofObject: methodArray) ifTrue:
			[^binaryBlock
				value: (objectMemory fetchPointer: i + SelectorStart ofObject: classDict)
				value: currClass].
			i := i + 1].
	 currClass := self superclassOf: currClass.
	 currClass = objectMemory nilObject] whileFalse.
	^binaryBlock    "method not found in superclass chain"
		value: (objectMemory splObj: SelectorDoesNotUnderstand)
		value: nil
]

{ #category : #'debug support' }
StackInterpreter >> findSelectorOfMethod: meth forReceiver: rcvr [

	| currClass classDict classDictSize methodArray i |
	(objectMemory addressCouldBeObj: meth) ifFalse:
		[^objectMemory nilObject].
	(objectMemory addressCouldBeOop: rcvr)
		ifTrue: [currClass := objectMemory fetchClassOf: rcvr]
		ifFalse: [currClass := self methodClassOf: meth].
	[classDict := objectMemory fetchPointer: MethodDictionaryIndex ofObject: currClass.
	 classDictSize := objectMemory fetchWordLengthOf: classDict.
	 methodArray := objectMemory fetchPointer: MethodArrayIndex ofObject: classDict.
	 i := 0.
	 [i <= (classDictSize - SelectorStart)] whileTrue:
		[meth = (objectMemory fetchPointer: i ofObject: methodArray) ifTrue:
			[^(objectMemory fetchPointer: i + SelectorStart ofObject: classDict)].
			i := i + 1].
	 currClass := self superclassOf: currClass.
	 currClass = objectMemory nilObject] whileFalse.
	^currClass    "method not found in superclass chain"
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
		[theMethod := objectMemory fetchPointer: MethodIndex ofObject: homeContext.
		 (self primitiveIndexOf: theMethod) == 198 ifTrue:
			[^homeContext]].
	^ctxtOrNilOrZero
]

{ #category : #'compiled methods' }
StackInterpreter >> firstByteIndexOfMethod: methodObj [
	"Answer the one-relative index of the first bytecode in methodObj.
	 Used for safer bounds-checking on methods."
	^(self literalCountOf: methodObj) + LiteralStart * BytesPerWord + 1
]

{ #category : #'compiled methods' }
StackInterpreter >> firstBytecodeOfAlternateHeader: methodHeader method: theMethod [
	^theMethod + ((LiteralStart + (self literalCountOfAlternateHeader: methodHeader)) * BytesPerWord) + BaseHeaderSize
]

{ #category : #'plugin primitive support' }
StackInterpreter >> floatArg: index [
	"Like #stackFloatValue: but access method arguments left-to-right"
	| oop |
	<returnTypeC: #double>
	oop := self methodArg: index.
	oop = 0 ifTrue:[^0.0]. "methodArg: failed"
	^self floatValueOf: oop
]

{ #category : #'object format' }
StackInterpreter >> floatObjectOf: aFloat [
	| newFloatObj |
	<inline: false>
	<var: #aFloat type: #double>
	self flag: #Dan.
	newFloatObj := objectMemory eeInstantiateSmallClass: (objectMemory splObj: ClassFloat) sizeInBytes: 8+BaseHeaderSize.
	objectMemory storeFloatAt: newFloatObj + BaseHeaderSize from: aFloat.
	^ newFloatObj.

]

{ #category : #utilities }
StackInterpreter >> floatValueOf: oop [
	"Answer the C double precision floating point value of the argument,
	 or fail if it is not a Float, and answer 0.
	 Note: May be called by translated primitive code."

	| isFloat result |
	<returnTypeC: #double>
	<var: #result type: #double>
	isFloat := self isInstanceOfClassFloat: oop.
	isFloat ifTrue:
		[self cCode: '' inSmalltalk: [result := Float new: 2].
		 objectMemory fetchFloatAt: oop + BaseHeaderSize into: result.
		 ^result].
	self primitiveFail.
	^0.0
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
StackInterpreter >> flushExternalPrimitiveOf: methodObj [
	"methodObj is a CompiledMethod containing an external primitive. Flush the function address and session ID of the CM"
	| lit |
	(self literalCountOf: methodObj) > 0 ifFalse:
		[^nil]. "Something's broken"
	lit := self literal: 0 ofMethod: methodObj.
	((objectMemory isArray: lit) and:[(objectMemory lengthOf: lit) = 4]) ifFalse:
		[^nil]. "Something's broken"
	"ConstZero is a known SmallInt so no root check needed"
	objectMemory storePointerUnchecked: 2 ofObject: lit withValue: ConstZero.
	objectMemory storePointerUnchecked: 3 ofObject: lit withValue: ConstZero
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
	oop := objectMemory firstObject.
	[self oop: oop isLessThan: objectMemory freeStart]
		whileTrue: [(objectMemory isFreeObject: oop)
				ifFalse: [(objectMemory isCompiledMethod: oop)
						ifTrue: ["This is a compiled method"
							primIdx := self primitiveIndexOf: oop.
							primIdx = PrimitiveExternalCallIndex
								ifTrue: ["It's primitiveExternalCall"
									self flushExternalPrimitiveOf: oop]]].
			oop := objectMemory objectAfter: oop].
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
	(thePage notNil and: [thePage ~= 0]) ifTrue:
		[thePage stackLimit: (self cCoerceSimple: -1 signedIntToLong to: #'char *')].
	stackLimit := self cCoerceSimple: -1 signedIntToLong to: #'char *'.
	self sqLowLevelMFence.
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
	suppressHeartbeatFlag ifFalse:
		[self checkForLongRunningPrimitive.
		 self forceInterruptCheck]
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
	<returnTypeC: #'char *'>
	<var: #theFP type: #'char *'>
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
	value := objectMemory fetchPointer: SenderIndex ofObject: aContext.
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
	^stackPages longAt: theFP + (self frameStackedReceiverOffsetNumArgs: numArgs)
]

{ #category : #'frame access' }
StackInterpreter >> frameStackedReceiverOffset: theFP [
	"Answer the offset in bytes from the the frame pointer to its stacked receiver.
	 The receiver of a message send or the closure of a block activation is
	 always on the stack above any arguments and the frame itself.  See the
	 diagram in StackInterpreter class>>initializeFrameIndices."
	<inline: true>
	<var: #theFP type: #'char *'>
	^self frameStackedReceiverOffsetNumArgs: (self frameNumArgs: theFP)
]

{ #category : #'frame access' }
StackInterpreter >> frameStackedReceiverOffsetNumArgs: numArgs [
	"Answer the offset in bytes from the a frame pointer to its stacked receiver,
	 given the argument count.  The receiver of a message send or the closure of
	 a block activation is always on the stack above any arguments and the frame
	 itself.  See the diagram in StackInterpreter class>>initializeFrameIndices."
	<inline: true>
	^FoxCallerSavedIP + BytesPerWord + (numArgs << ShiftForWord)
]

{ #category : #'I/O primitive support' }
StackInterpreter >> fullDisplayUpdate [
	"Repaint the entire smalltalk screen, ignoring the affected rectangle. Used in some platform's code when the Smalltalk window is brought to the front or uncovered."

	| displayObj w h |
	displayObj := objectMemory splObj: TheDisplay.
	((objectMemory isPointers: displayObj) and: [(objectMemory lengthOf: displayObj) >= 4]) ifTrue: [
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
	self cCode: '' inSmalltalk: [function := -1].
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
	^objectMemory nilObject
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCodeCompactionMSecs [
	"This is nil in the StackVM"
	^objectMemory nilObject
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCogCodeSize [
	"This is nil in the StackVM"
	^objectMemory nilObject
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCogMethodCount [
	"This is 0 in the StackVM"
	^ConstZero
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCogVMFlags [
	"Answer an array of flags indicating various properties of the Cog VM.
	 Bit 2: if set, implies preempting a process does not put it to the back of its run queue"
	^objectMemory integerObjectOf: (preemptionYields ifTrue: [0] ifFalse: [4])
]

{ #category : #'interpreter shell' }
StackInterpreter >> getCurrentBytecode [
	"currentBytecode will be private to the main dispatch loop in the generated code. This method allows the currentBytecode to be retrieved from global variables."

	^objectMemory byteAt: instructionPointer
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getDesiredCogCodeSize [
	"This is nil in the StackVM"
	^objectMemory nilObject
]

{ #category : #'message sending' }
StackInterpreter >> getErrorObjectFromPrimFailCode [
	"Answer the errorCode object to supply to a failing primitive method that accepts one.
	 If there is a primitive error table and the primFailCode is a valid index there-in answer
	 the coprresponding entry in the table, otherwise simply answer the code as an integer."
	| table |
	primFailCode > 0 ifTrue:
		[table := objectMemory splObj: PrimErrTableIndex.
		 primFailCode <= ((objectMemory lastPointerOf: table) // BytesPerWord) ifTrue:
			[^objectMemory fetchPointer: primFailCode - 1 ofObject: table]].
	^objectMemory integerObjectOf: primFailCode
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
	+ (preemptionYields ifTrue: [0] ifFalse: [16r10])
	+ (imageHeaderFlags bitClear: 16r13) "these are any flags we do not recognize"
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
		ifTrue: [^ objectMemory byteSwapped: w]
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
	<var: #aFile type: #'sqImageFile'>
	w := 0.
	self cCode: 'sqImageFileRead(&w, sizeof(unsigned short), 1, aFile)'.
	^swapFlag
		ifTrue: [(w bitShift: -8) + ((w bitAnd: 16rFF) bitShift: 8)]
		ifFalse: [w]
]

{ #category : #'primitive support' }
StackInterpreter >> getStackPointer [
	"For Alien FFI"
	<api>
	<returnTypeC: #'sqInt *'>
	^self cCoerce: stackPointer to: #'sqInt *'
]

{ #category : #'plugin support' }
StackInterpreter >> getThisSessionID [
	"return the global session ID value"
	<inline: false>
	^globalSessionID
]

{ #category : #'message sending' }
StackInterpreter >> handleStackOverflow [
	"Check for stack overflow, moving frames to another stack if so."
	| newPage theFP callerFP overflowLimitAddress overflowCount |
	<var: #newPage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #overflowLimitAddress type: #'char *'>

	"After checkForInterrupts another event check may have been forced, setting both
	 stackLimit and stackPage stackLimit to all ones.  So here we must check against
	 the real stackLimit, not the effective stackLimit."
	stackPointer < stackPage realStackLimit ifFalse:
		[^self].

	self maybeTraceStackOverflow.
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
						or: [self isContext: (self frameContext: framePointer)])]
]

{ #category : #'message sending' }
StackInterpreter >> handleStackOverflowOrEventAllowContextSwitch: mayContextSwitch [
	"The stackPointer is below the stackLimit.  This is either because of a
	 stack overflow or the setting of stackLimit to indicate a possible interrupt.
	 Check for interrupts and stackOverflow and deal with each appropriately.
	 Answer if a context switch occurred."
	| switched |
	<inline: false>
	"If the stackLimit differs from the realStackLimit then the stackLimit
	 has been set to indicate an event or interrupt that needs servicing."
	stackLimit = stackPage realStackLimit
		ifTrue:
			[self externalWriteBackHeadFramePointers.
			 switched := false]
		ifFalse: [switched := self checkForEventsMayContextSwitch: mayContextSwitch].

	self handleStackOverflow.
	^switched
]

{ #category : #'internal interpreter access' }
StackInterpreter >> headerIndicatesAlternateBytecodeSet: methodHeader [
	<api>
	<inline: true>
	"A negative header selects the alternate bytecode set."
	^methodHeader signedIntFromLong < 0
]

{ #category : #'compiled methods' }
StackInterpreter >> headerOf: methodPointer [
	^objectMemory fetchPointer: HeaderIndex ofObject: methodPointer
]

{ #category : #'stack pages' }
StackInterpreter >> highBit: anUnsignedValue [ 
	"This is a C implementation needed by ioSetMaxExtSemTableSize
	 and e.g. stackPageByteSize."
	| shifted bitNo |
	<api>
	<highBit> "so it shows up in senders..."
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
	schedLists := objectMemory fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	p := highestRunnableProcessPriority = 0
			ifTrue: [objectMemory fetchWordLengthOf: schedLists]
			ifFalse: [highestRunnableProcessPriority].
	p := p - 1.
	"index of last indexable field"
	[processList := objectMemory fetchPointer: p ofObject: schedLists.
	 processOrNil := objectMemory fetchPointer: FirstLinkIndex ofObject: processList.
	 processOrNil = objectMemory nilObject] whileTrue:
		[(p := p - 1) < 0 ifTrue:
			[^nil]].
	highestRunnableProcessPriority := p + 1.
	^processOrNil
]

{ #category : #'message sending' }
StackInterpreter >> ifAppropriateCompileToNativeCode: aMethodObj selector: selector [
	"Convenient  noop in the StackInterpreter e.g. for sendInvokeCallbackContext:"
]

{ #category : #'jump bytecodes' }
StackInterpreter >> ifBackwardsCheckForEvents: offset [
	"Backward jump means we're in a loop; check for possible interrupts."
	<inline: true>
	(offset < 0
	 and: [localSP < stackLimit]) ifTrue:
		[self externalizeIPandSP.
		 self checkForEventsMayContextSwitch: true.
		 self browserPluginReturnIfNeeded.
		 self internalizeIPandSP]
]

{ #category : #'debug support' }
StackInterpreter >> ifValidWriteBackStack: theCFP Pointers: theCSP Save: savedFPP To: savedSPP [
	"This is for low-level error reporting.  If either of the C stack pointers are
	 pointing into the stack zone then write them back to framePointer and/or
	 stackPointer so that the stack backtrace will be up to date.  Write their
	 original values through savedFPP & savedSPP if non-null.
	 This is a noop in the stack VM since the C stack pointers are always
	 elsewhere (e.g., in some C function running the interpreter)."
	<api>
	<var: #theCFP type: #'void *'>
	<var: #theCSP type: #'void *'>
	<var: #savedFPP type: #'char **'>
	<var: #savedSPP type: #'char **'>
	<returnTypeC: #void>
]

{ #category : #'frame access' }
StackInterpreter >> iframeInstructionPointerForIndex: ip method: aMethod [
	"Answer the instruction pointer for use in an interpreter frame (a pointer to a bytecode)."
	self assert: (ip between: (objectMemory lastPointerOf: aMethod) and: (objectMemory lengthOf: aMethod)).
	^aMethod + ip + BaseHeaderSize - 2
]

{ #category : #'frame access' }
StackInterpreter >> iframeMethod: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	<returnTypeC: #usqInt>
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

{ #category : #'newspeak bytecode support' }
StackInterpreter >> implicitReceiverFor: rcvr mixin: mixin implementing: selector [
	"This is used to implement the innards of the pushImplicitReceiverBytecode,
	 used for implicit receiver sends in NS2/NS3.  Find the nearest lexically-enclosing
	 implementation of selector by searching up the static chain of anObject,
	 starting at mixin's application.  This is an iterative implementation derived from

	<ContextPart> implicitReceiverFor: obj <Object>
					withMixin: mixin <Mixin>
					implementing: selector <Symbol> ^<Object>"
	<api>
	<option: #NewspeakVM>
	| mixinApplication dictionary found |
	messageSelector := selector. "messageSelector is an implicit parameter of lookupMethodInDictionary:"
	mixinApplication := self
							findApplicationOfTargetMixin: mixin
							startingAtBehavior: (objectMemory fetchClassOf: rcvr).
	 mixinApplication = objectMemory nilObject ifTrue:
		[^rcvr].
	 dictionary := objectMemory fetchPointer: MethodDictionaryIndex ofObject: mixinApplication.
	 found := self lookupMethodInDictionary: dictionary.
	 found ifFalse:
		[| implicitReceiverOrNil theMixin |
		 theMixin := objectMemory fetchPointer: MixinIndex ofObject: mixinApplication.
		 implicitReceiverOrNil := self nextImplicitReceiverFor: (objectMemory
																fetchPointer: EnclosingObjectIndex
																ofObject: mixinApplication)
									withMixin: (objectMemory
													fetchPointer: EnclosingMixinIndex
													ofObject: theMixin).
		 implicitReceiverOrNil ~= objectMemory nilObject ifTrue:
			[^implicitReceiverOrNil]].
	^rcvr
]

{ #category : #'plugin primitive support' }
StackInterpreter >> includesBehavior: aClass ThatOf: aSuperclass [
	"Return the equivalent of 
		aClass includesBehavior: aSuperclass.
	Note: written for efficiency and better inlining (only 1 temp)"
	| theClass |
	<inline: true>
	aSuperclass = objectMemory nilObject ifTrue:
		[^false].
	theClass := aClass.
	[theClass = aSuperclass ifTrue:
		[^true].
	 theClass ~= objectMemory nilObject] whileTrue:
		[theClass := self superclassOf: theClass].
	^false
]

{ #category : #'simulation support' }
StackInterpreter >> initExtensions [
	<inline: true>
	self cppIf: MULTIPLEBYTECODESETS ifTrue: [extA := extB := 0]
]

{ #category : #initialization }
StackInterpreter >> initStackPages [
	"Initialize the stackPages.  This version is only for simulation
	 because Slang refuses to inline it, which makes the alloca invalid."
	| stackPageBytes stackPagesBytes theStackMemory |
	stackPageBytes := self stackPageByteSize.
	stackPagesBytes := self computeStackZoneSize.
	theStackMemory := self
						cCode: [self alloca: stackPagesBytes]
						inSmalltalk:
							[stackPages := self stackPagesClass new.
							 stackPages initializeWithByteSize: stackPagesBytes for: self].
	self cCode: [self me: theStackMemory ms: 0 et: stackPagesBytes].
	stackPages
		initializeStack: theStackMemory
		numSlots: stackPagesBytes / BytesPerWord
		pageSize: stackPageBytes / BytesPerWord
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
						cCode: [self alloca: stackPagesBytes]
						inSmalltalk:
							[stackPages := self stackPagesClass new.
							 stackPages initializeWithByteSize: stackPagesBytes for: self].
	self cCode: [self me: theStackMemory ms: 0 et: stackPagesBytes].
	stackPages
		initializeStack: theStackMemory
		numSlots: stackPagesBytes / BytesPerWord
		pageSize: stackPageBytes / BytesPerWord.

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
	<api>
	^theMethod + ((LiteralStart + (self literalCountOfHeader: methodHeader)) * BytesPerWord) + BaseHeaderSize
]

{ #category : #initialization }
StackInterpreter >> initializeExtraClassInstVarIndices [
	"Initialize metaclassSizeBits and thisClassIndex which are used in debug printing, and
	 classNameIndex which is used not only for debug printing but for is:KindOf: & is:MemberOf:
	 via classNameOf:is: (evil but a reality we have to accept)."
	| classArrayObj classArrayClass |
	classArrayObj := objectMemory splObj: ClassArray.
	classArrayClass := objectMemory fetchClassOfNonInt: classArrayObj.
	metaclassSizeBits := objectMemory sizeBitsOf: classArrayClass.	"determine actual (Metaclass instSize * 4)"
	thisClassIndex := 5. "default"
	InstanceSpecificationIndex + 1 to: (objectMemory lengthOf: classArrayClass) do:
		[:i|
		(objectMemory fetchPointer: i - 1 ofObject: classArrayClass) = classArrayObj ifTrue:
			[thisClassIndex := i - 1]].
	classNameIndex := 6. "default"
	InstanceSpecificationIndex + 1 to: (objectMemory lengthOf: classArrayObj) do:
		[:i| | oop |
		oop := objectMemory fetchPointer: i - 1 ofObject: classArrayObj.
		((objectMemory isBytes: oop)
		and: [(objectMemory lengthOf: oop) = 5
		and: [(self str: 'Array' n: (objectMemory firstFixedField: oop) cmp: 5) = 0]]) ifTrue:
			[classNameIndex := i - 1]]
]

{ #category : #initialization }
StackInterpreter >> initializeInterpreter: bytesToShift [ 
	"Initialize Interpreter state before starting execution of a new image."
	interpreterProxy := self sqGetInterpreterProxy.
	self dummyReferToProxy.
	objectMemory initializeObjectMemory: bytesToShift.
	self checkAssumedCompactClasses.
	primFailCode := 0.
	self initializeExtraClassInstVarIndices.
	stackLimit := 0. "This is also the initialization flag for the stack system."
	stackPage := overflowedPage := 0.
	extraFramesToMoveOnOverflow := 0.
	method := objectMemory nilObject.
	self cCode: [self cppIf: MULTIPLEBYTECODESETS ifTrue: [bytecodeSetSelector := 0]]
		inSmalltalk: [bytecodeSetSelector := 0].
	messageSelector := objectMemory nilObject.
	newMethod := objectMemory nilObject.
	lkupClass := objectMemory nilObject.
	self flushMethodCache.
	self flushAtCache.
	self initialCleanup.
	highestRunnableProcessPriority := 0.
	nextProfileTick := 0.
	profileSemaphore := objectMemory nilObject.
	profileProcess := objectMemory nilObject.
	profileMethod := objectMemory nilObject.
	nextPollUsecs := 0.
	nextWakeupUsecs := 0.
	tempOop := 0.
	interruptKeycode := 2094. "cmd-. as used for Mac but no other OS"
	interruptPending := false.
	inIOProcessEvents := 0.
	deferDisplayUpdates := false.
	pendingFinalizationSignals := statPendingFinalizationSignals := 0.
	globalSessionID := 0.
	[globalSessionID = 0]
		whileTrue: [globalSessionID := self
						cCode: 'time(NULL) + ioMSecs()'
						inSmalltalk: [(Random new next * SmallInteger maxVal) asInteger]].
	jmpDepth := 0.
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
		[^objectMemory fetchPointer: offset ofObject: aContext].

	self writeBackHeadFramePointers.
	(self isWidowedContext: aContext) ifTrue:
		[^objectMemory fetchPointer: offset ofObject: aContext].

	spouseFP := self frameOfMarriedContext: aContext.
	offset = SenderIndex ifTrue:
		[^self ensureCallerContext: spouseFP].
	offset = StackPointerIndex ifTrue:
		[self assert: ReceiverIndex + (self stackPointerIndexForFrame: spouseFP) < (objectMemory lengthOf: aContext).
		^objectMemory integerObjectOf: (self stackPointerIndexForFrame: spouseFP)].
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
		[objectMemory storePointer: index ofObject: aMarriedContext withValue: anOop.
		 index = StackPointerIndex ifTrue:
			[self ensureContextIsExecutionSafeAfterAssignToStackPointer: aMarriedContext].
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
	objectMemory storePointer: index ofObject: aMarriedContext withValue: anOop.
	index = StackPointerIndex ifTrue:
		[self ensureContextIsExecutionSafeAfterAssignToStackPointer: aMarriedContext].
	self internalizeIPandSP.
	"Assigning various fields can force a divorce which can change the stackPage."
	stackPages markStackPageMostRecentlyUsed: stackPage.
	self assertValidExecutionPointe: localIP asUnsignedInteger r: localFP s: localSP imbar: true
]

{ #category : #'indexing primitive support' }
StackInterpreter >> install: rcvr inAtCache: cache at: atIx string: stringy [
	"Attempt to install the oop of this object in the given cache (at or atPut),
	 along with its size, format and fixedSize. Answer if this was successful."
	| hdr fmt totalLength fixedFields |
	<var: #cache type: 'sqInt *'>

	hdr := objectMemory baseHeader: rcvr.
	fmt := objectMemory formatOfHeader: hdr.
	(fmt = 3 and: [objectMemory isContextHeader: hdr]) ifTrue:
		["Contexts must not be put in the atCache, since their size is not constant"
		self primitiveFailFor: PrimErrBadReceiver.
		^false].
	totalLength := objectMemory lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: rcvr format: fmt length: totalLength.

	cache at: atIx+AtCacheOop put: rcvr.
	cache at: atIx+AtCacheFmt put: (stringy
										ifTrue: [fmt + 16]  "special flag for strings"
										ifFalse: [fmt]).
	cache at: atIx+AtCacheFixedFields put: fixedFields.
	cache at: atIx+AtCacheSize put: totalLength - fixedFields.
	^true
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
	messageSelector := objectMemory splObj: SelectorAboutToReturn.
	argumentCount := 2.
	^self normalSend
]

{ #category : #'message sending' }
StackInterpreter >> internalActivateNewMethod [
	| methodHeader numTemps rcvr errorCode |
	<inline: true>

	methodHeader := self headerOf: newMethod.
	numTemps := self temporaryCountOfMethodHeader: methodHeader.

	rcvr := self internalStackValue: argumentCount. "could new rcvr be set at point of send?"

	self internalPush: localIP.
	self internalPush: localFP.
	localFP := localSP.
	self internalPush: newMethod.
	self setMethod: newMethod methodHeader: methodHeader.
	self internalPush: (self
						encodeFrameFieldHasContext: false
						isBlock: false
						numArgs: (self argumentCountOfMethodHeader: methodHeader)).
	self internalPush: objectMemory nilObject. "FxThisContext field"
	self internalPush: rcvr.

	"Initialize temps..."
	argumentCount + 1 to: numTemps do:
		[:i | self internalPush: objectMemory nilObject].

	"-1 to account for pre-increment in fetchNextBytecode"
	localIP := self pointerForOop: (self initialPCForHeader: methodHeader method: newMethod) - 1.

	(self methodHeaderHasPrimitive: methodHeader) ifTrue:
		["Skip the CallPrimitive bytecode, if it's there, and store the error code if the method starts
		  with a long store temp.  Strictly no need to skip the store because it's effectively a noop."
		 localIP := localIP + (self sizeOfCallPrimitiveBytecode: methodHeader).
		 primFailCode ~= 0 ifTrue:
			[(objectMemory byteAt: localIP + 1)
			  = (self longStoreBytecodeForHeader: methodHeader) ifTrue:
				[errorCode := self getErrorObjectFromPrimFailCode.
				 self internalStackTopPut: errorCode "nil if primFailCode == 1, or primFailCode"].
			 primFailCode := 0]].

	self assert: (self frameNumArgs: localFP) == argumentCount.
	self assert: (self frameIsBlockActivation: localFP) not.
	self assert: (self frameHasContext: localFP) not.

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	localSP < stackLimit ifTrue:
		[self externalizeIPandSP.
		 self handleStackOverflowOrEventAllowContextSwitch: (self canContextSwitchIfActivating: newMethod header: methodHeader).
		 self internalizeIPandSP]
]

{ #category : #'return bytecodes' }
StackInterpreter >> internalCannotReturn: resultOop [
	| ourContext |
	<inline: true>
	ourContext := self ensureFrameIsMarried: localFP SP: localSP.
	self internalPush: ourContext.
	self internalPush: resultOop.
	messageSelector := objectMemory splObj: SelectorCannotReturn.
	argumentCount := 1.
	^self normalSend
]

{ #category : #'message sending' }
StackInterpreter >> internalExecuteNewMethod [
	| succeeded |
	<inline: true>
	primitiveFunctionPointer ~= 0 ifTrue:
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
	messageSelector := objectMemory splObj: SelectorMustBeBoolean.
	argumentCount := 0.
	self normalSend
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPop: nItems [
	"In the StackInterpreter stacks grow down."
	localSP := localSP + (nItems * BytesPerOop)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPop: nItems thenPush: oop [
	"In the StackInterpreter stacks grow down."
	stackPages longAtPointer: (localSP := localSP + ((nItems - 1) * BytesPerOop)) put: oop
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPopStack [
	"In the StackInterpreter stacks grow down."
	| top |
	top := stackPages longAt: localSP.
	localSP := localSP + BytesPerOop.
	^top
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPush: object [
	"In the StackInterpreter stacks grow down."
	stackPages longAtPointer: (localSP := localSP - BytesPerOop) put: object
]

{ #category : #'primitive support' }
StackInterpreter >> internalQuickPrimitiveResponse [
	"Invoke a quick primitive.
	 Called under the assumption that primFunctionPtr has been preloaded"
	
	| localPrimIndex |
	self assert: self isPrimitiveFunctionPointerAnIndex.
	localPrimIndex := self cCoerceSimple: primitiveFunctionPointer to: #sqInt.
	self assert: (localPrimIndex > 255 and: [localPrimIndex < 520]).
	"Quick return inst vars"
	localPrimIndex >= 264 ifTrue:
		[self internalStackTopPut: (objectMemory fetchPointer: localPrimIndex - 264 ofObject: self internalStackTop).
		 ^true].
	"Quick return constants"
	localPrimIndex = 256 ifTrue: [^true "return self"].
	localPrimIndex = 257 ifTrue: [self internalStackTopPut: objectMemory trueObject. ^true].
	localPrimIndex = 258 ifTrue: [self internalStackTopPut: objectMemory falseObject. ^true].
	localPrimIndex = 259 ifTrue: [self internalStackTopPut: objectMemory nilObject. ^true].
	self internalStackTopPut: (objectMemory integerObjectOf: localPrimIndex - 261).
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
	^stackPages longAtPointer: localSP + (offset * BytesPerOop)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalStackValue: offset put: aValue [
	"In the StackInterpreter stacks grow down."
	^stackPages longAtPointer: localSP + (offset * BytesPerOop) put: aValue
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
	self initExtensions.
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
	| maxUsedBytesPerPage maxFramesPerPage |
	maxUsedBytesPerPage := self stackPageFrameBytes + self stackLimitOffset.
	maxFramesPerPage := maxUsedBytesPerPage / BytesPerWord // MFrameSlots.
	^maxFramesPerPage * LargeContextSize * numStackPages
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

{ #category : #'primitive support' }
StackInterpreter >> ioLocalMicroseconds [
	<doNotGenerate>
	^Time localMicrosecondClock
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
	oopClass := objectMemory fetchClassOf: oop.
	[oopClass = objectMemory nilObject] whileFalse:[
		(self classNameOf: oopClass Is: className) ifTrue:[^true].
		oopClass := self superclassOf: oopClass].
	^false
]

{ #category : #'plugin primitive support' }
StackInterpreter >> is: oop KindOfClass: aClass [
	"Support for external primitives."
	<api>
	| oopClass |
	oopClass := objectMemory fetchClassOf: oop.
	[oopClass = objectMemory nilObject] whileFalse:
		[oopClass = aClass ifTrue: [^true].
		 oopClass := self superclassOf: oopClass].
	^false
]

{ #category : #'plugin primitive support' }
StackInterpreter >> is: oop MemberOf: className [
	"Support for external primitives"
	| oopClass |
	<var: #className type:#'char *'>
	oopClass := objectMemory fetchClassOf: oop.
	^(self classNameOf: oopClass Is: className)
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
	^(objectMemory isNonIntegerObject: oop) and: [objectMemory isContextHeader: (objectMemory baseHeader: oop)]
]

{ #category : #'process primitive support' }
StackInterpreter >> isEmptyList: aLinkedList [

	^ (objectMemory fetchPointer: FirstLinkIndex ofObject: aLinkedList) = objectMemory nilObject
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isFloatObject: oop [
	^(objectMemory isNonIntegerObject: oop)
	   and: [ClassFloatCompactIndex ~= 0
			ifTrue: [(objectMemory compactClassIndexOf: oop) = ClassFloatCompactIndex]
			ifFalse: [(objectMemory fetchClassOfNonInt: oop) = objectMemory classFloat]]
]

{ #category : #'object format' }
StackInterpreter >> isIndexable: oop [
	^(objectMemory formatOf: oop) >= 2
]

{ #category : #'frame access' }
StackInterpreter >> isLiveContext: oop [
	"Answer if the argument, which can be any object, is a live context."
	(self isContext: oop) ifFalse:
		[^false].
	(self isSingleContext: oop) ifTrue:
		[^objectMemory isIntegerObject: (objectMemory fetchPointer: InstructionPointerIndex ofObject: oop)].
	^(self isWidowedContext: oop) not
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
	^objectMemory isIntegerObject: (objectMemory fetchPointer: SenderIndex ofObject: aContext)
]

{ #category : #'compiled methods' }
StackInterpreter >> isNullExternalPrimitiveCall: aMethodObj [
	"Answer if the method is an external primtiive call (prim 117) with a null external primtiive.
	 This is just for an assert in the CoInterpreter."
	| lit |
	((self primitiveIndexOf: aMethodObj) = 117
	and: [(self literalCountOf: aMethodObj) > 0]) ifFalse:
		[^false].

	lit := self literal: 0 ofMethod: aMethodObj.
	^(objectMemory isArray: lit)
	  and: [(objectMemory lengthOf: lit) = 4
	  and: [(objectMemory fetchPointer: 3 ofObject: lit) = ConstZero
			or: [(objectMemory fetchPointer: 3 ofObject: lit) = ConstMinusOne]]]
]

{ #category : #'primitive support' }
StackInterpreter >> isPrimitiveFunctionPointerAnIndex [
	"We save slots in the method cache by using the primitiveFunctionPointer
	 to hold either a function pointer or the index of a quick primitive. Since
	 quick primitive indices are small they can't be confused with function
	 addresses. "
	^(self cCoerce: primitiveFunctionPointer to: 'unsigned long') <= MaxQuickPrimitiveIndex
]

{ #category : #'compiled methods' }
StackInterpreter >> isQuickPrimitiveIndex: anInteger [
	<api>
	^anInteger between: 256 and: 519
]

{ #category : #'frame access' }
StackInterpreter >> isSingleContext: aContext [
	^objectMemory isNonIntegerObject: (objectMemory fetchPointer: SenderIndex ofObject: aContext)
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
	self assert: ((self isContext: aOnceMarriedContext)
				  and: [self isMarriedOrWidowedContext: aOnceMarriedContext]).
	theFrame := self frameOfMarriedContext: aOnceMarriedContext.
	thePage := stackPages stackPageFor: theFrame.
	((stackPages isFree: thePage)
	 or: [theFrame < thePage headFP]) ifFalse:
		["The frame pointer is within the bounds of a live page.
		   Now check if it matches a frame."
		 shouldBeFrameCallerField := self withoutSmallIntegerTags:
										(objectMemory fetchPointer: InstructionPointerIndex
											ofObject: aOnceMarriedContext).
		 ((self frameCallerFP: theFrame) = shouldBeFrameCallerField
		  and: [(self frameMethodObject: theFrame) = (objectMemory fetchPointer: MethodIndex
													ofObject: aOnceMarriedContext)
		  and: [(self frameHasContext: theFrame)
		  and: [(self frameContext: theFrame) = aOnceMarriedContext]]]) ifTrue:
			["It is still married!"
			^false]].
	"It is out of range or doesn't match the frame's context.
	 It is widowed. Time to wear black."
	self markContextAsDead: aOnceMarriedContext.
	^true
]

{ #category : #'jump bytecodes' }
StackInterpreter >> jump: offset [
	localIP := localIP + offset + 1.
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := (objectMemory byteAtPointer: localIP) + bytecodeSetSelector]
		ifFalse: [currentBytecode := objectMemory byteAtPointer: localIP]
]

{ #category : #'jump bytecodes' }
StackInterpreter >> jumplfFalseBy: offset [ 
	| boolean |
	boolean := self internalStackTop.
	boolean = objectMemory falseObject
		ifTrue: [self jump: offset]
		ifFalse:
			[boolean = objectMemory trueObject ifFalse:
				[^self internalMustBeBoolean].
			self fetchNextBytecode].
	self internalPop: 1
]

{ #category : #'jump bytecodes' }
StackInterpreter >> jumplfTrueBy: offset [ 
	| boolean |
	boolean := self internalStackTop.
	boolean = objectMemory trueObject
		ifTrue: [self jump: offset]
		ifFalse:
			[boolean = objectMemory falseObject ifFalse:
				[^self internalMustBeBoolean].
			self fetchNextBytecode].
	self internalPop: 1
]

{ #category : #'message sending' }
StackInterpreter >> justActivateNewMethod [
	| methodHeader numArgs numTemps rcvr errorCode |
	<inline: true>
	methodHeader := self headerOf: newMethod.
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	numArgs := self argumentCountOfMethodHeader: methodHeader.

	rcvr := self stackValue: numArgs. "could new rcvr be set at point of send?"

	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: newMethod.
	self setMethod: newMethod methodHeader: methodHeader.
	self push: (self encodeFrameFieldHasContext: false isBlock: false numArgs: numArgs).
	self push: objectMemory nilObject. "FxThisContext field"
	self push: rcvr.

	"clear remaining temps to nil"
	numArgs+1 to: numTemps do:
		[:i | self push: objectMemory nilObject].

	instructionPointer := (self initialPCForHeader: methodHeader method: newMethod) - 1.

	(self methodHeaderHasPrimitive: methodHeader) ifTrue:
		["Skip the CallPrimitive bytecode, if it's there, and store the error code if the method starts
		  with a long store temp.  Strictly no need to skip the store because it's effectively a noop."
		 instructionPointer := instructionPointer + (self sizeOfCallPrimitiveBytecode: methodHeader).
		 primFailCode ~= 0 ifTrue:
			[(objectMemory byteAt: instructionPointer + 1)
			  = (self longStoreBytecodeForHeader: methodHeader) ifTrue:
				[errorCode := self getErrorObjectFromPrimFailCode.
				 self stackTopPut: errorCode "nil if primFailCode == 1, or primFailCode"].
			 primFailCode := 0]].

	^methodHeader
]

{ #category : #'debug printing' }
StackInterpreter >> lengthOfNameOfClass: classOop [
	<inline: false>
	(objectMemory sizeBitsOf: classOop) = metaclassSizeBits ifTrue:
		[^self lengthOfNameOfClass: (objectMemory fetchPointer: thisClassIndex ofObject: classOop)].
	^objectMemory lengthOf: (objectMemory fetchPointer: classNameIndex ofObject: classOop)
]

{ #category : #'compiled methods' }
StackInterpreter >> literal: offset [
	self assert: method = (self iframeMethod: localFP).
	^self literal: offset ofMethod: method
]

{ #category : #'compiled methods' }
StackInterpreter >> literal: offset ofMethod: methodPointer [

	^ objectMemory fetchPointer: offset + LiteralStart ofObject: methodPointer

]

{ #category : #'compiled methods' }
StackInterpreter >> literalCountOf: methodPointer [
	^self literalCountOfHeader: (self headerOf: methodPointer)
]

{ #category : #'compiled methods' }
StackInterpreter >> literalCountOfAlternateHeader: headerPointer [
	<inline: true>
	^(headerPointer >> 1) bitAnd: 16rFFFF
]

{ #category : #'compiled methods' }
StackInterpreter >> literalCountOfHeader: headerPointer [
	<api>
	^self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [(self headerIndicatesAlternateBytecodeSet: headerPointer)
					ifTrue: [self literalCountOfAlternateHeader: headerPointer]
					ifFalse: [self literalCountOfOriginalHeader: headerPointer]]
		ifFalse: [self literalCountOfOriginalHeader: headerPointer]
]

{ #category : #'compiled methods' }
StackInterpreter >> literalCountOfOriginalHeader: headerPointer [
	<inline: true>
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

	<inline: true>
	<asmLabel: false>
	<returnTypeC: #double>

	(objectMemory isIntegerObject: floatOrInt) ifTrue:
		[^(objectMemory integerValueOf: floatOrInt) asFloat].
	^self floatValueOf: floatOrInt
]

{ #category : #initialization }
StackInterpreter >> loadInitialContext [
	<inline: false>
	| activeProc activeContext |
	self cCode: [] inSmalltalk: [self initExtensions].
	objectMemory leakCheckFullGC ifTrue:
		[objectMemory clearLeakMapAndMapAccessibleObjects.
		 self assert: objectMemory checkHeapIntegrity].
	activeProc := self activeProcess.
	activeContext := objectMemory fetchPointer: SuspendedContextIndex ofObject: activeProc.
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

{ #category : #'debug printing' }
StackInterpreter >> longPrintOop: oop [
	<api>
	| class fmt lastIndex startIP bytecodesPerLine column |
	((objectMemory isIntegerObject: oop)
	 or: [(oop between: objectMemory startOfMemory and: objectMemory freeStart) not
	 or: [(oop bitAnd: (BytesPerWord - 1)) ~= 0
	 or: [(objectMemory isFreeObject: oop)]]]) ifTrue:
		[^self printOop: oop].
	class := objectMemory fetchClassOfNonInt: oop.
	self printHex: oop;
		print: ': a(n) '; printNameOfClass: class count: 5;
		print: ' ('; printHex: class; print: ')'.
	fmt := objectMemory formatOf: oop.
	fmt > 4 ifTrue:
		[self print: ' nbytes '; printNum: (objectMemory byteSizeOf: oop)].
	objectMemory printHeaderTypeOf: oop.
	self cr.
	(fmt between: 5 and: 11) ifTrue:
		[^self].
	lastIndex := 256 min: (startIP := (objectMemory lastPointerOf: oop) / BytesPerWord).
	lastIndex > 0 ifTrue:
		[1 to: lastIndex do:
			[:i| | fieldOop |
			fieldOop := objectMemory fetchPointer: i - 1 ofObject: oop.
			self space; printNum: i - 1; space; printHex: fieldOop; space.
			(i = 1 and: [objectMemory isCompiledMethod: oop])
				ifTrue: [self printMethodHeaderOop: fieldOop]
				ifFalse: [self printOopShort: fieldOop].
			self cr]].
	(objectMemory isCompiledMethod: oop)
		ifFalse:
			[startIP > 64 ifTrue: [self print: '...'; cr]]
		ifTrue:
			[startIP := startIP * BytesPerWord + 1.
			 lastIndex := objectMemory lengthOf: oop.
			 lastIndex - startIP > 100 ifTrue:
				[lastIndex := startIP + 100].
			 bytecodesPerLine := 8.
			 column := 1.
			 startIP to: lastIndex do:
				[:index| | byte |
				column = 1 ifTrue:
					[self cCode: 'printf("0x%08x: ", oop+BaseHeaderSize+index-1)'
						inSmalltalk: [self print: (oop+BaseHeaderSize+index-1) hex; print: ': ']].
				byte := objectMemory fetchByte: index - 1 ofObject: oop.
				self cCode: 'printf(" %02x/%-3d", byte,byte)'
					inSmalltalk: [self space; print: (byte radix: 16); printChar: $/; printNum: byte].
				column := column + 1.
				column > bytecodesPerLine ifTrue:
					[column := 1. self cr]].
			column = 1 ifFalse:
				[self cr]]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> longPushTemporaryVariableBytecode [
	"230		11100110	i i i i i i i i	Push Temporary Variable #iiiiiiii"
	| index |
	index := self fetchByte.
	self fetchNextBytecode.
	self internalPush: (self temporary: index in: localFP)
]

{ #category : #'stack bytecodes' }
StackInterpreter >> longStoreAndPopTemporaryVariableBytecode [
	"237		11101101	i i i i i i i i	Pop and Store Temporary Variable #iiiiiiii"
	self longStoreTemporaryVariableBytecode.
	self internalPop: 1
]

{ #category : #'compiled methods' }
StackInterpreter >> longStoreBytecodeForHeader: methodHeader [
	"Answer the relevant long store temp bytecode, which indicates it has a primitive error code."
	"234		11101010	i i i i i i i i	Store Temporary Variable #iiiiiiii"
	"129 		10000001 jjkkkkkk 	Store (Receiver Variable, Temporary Location, Illegal, Literal Variable) [jj] #kkkkkk"
	<api>
	<inline: true>
	^self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [(self headerIndicatesAlternateBytecodeSet: methodHeader) ifTrue: [234] ifFalse: [129]]
		ifFalse: [129]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> longStoreTemporaryVariableBytecode [
	"234		11101010	i i i i i i i i	Store Temporary Variable #iiiiiiii"
	| index |
	index := self fetchByte.
	self fetchNextBytecode.
	self temporary: index in: localFP put: self internalStackTop
]

{ #category : #'jump bytecodes' }
StackInterpreter >> longUnconditionalJump [
	| offset |
	offset := (((currentBytecode bitAnd: 7) - 4) * 256) + self fetchByte.
	localIP := localIP + offset.
	self ifBackwardsCheckForEvents: offset.
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
StackInterpreter >> lookupMethodFor: selector InDictionary: dictionary [
	"Lookup the argument selector in aDictionary and answer either the
	 method or nil, if not found.
	This method lookup tolerates integers as Dictionary keys to support
	 execution of images in which Symbols have been compacted out."
	| length index mask wrapAround nextSelector methodArray |
	<inline: true>
	<asmLabel: false>
	length := objectMemory fetchWordLengthOf: dictionary.
	mask := length - SelectorStart - 1.
	index := SelectorStart + (mask bitAnd: ((objectMemory isIntegerObject: selector)
												ifTrue: [objectMemory integerValueOf: selector]
												ifFalse: [objectMemory hashBitsOf: selector])).

	"It is assumed that there are some nils in this dictionary, and search will 
	 stop when one is encountered. However, if there are no nils, then wrapAround 
	 will be detected the second time the loop gets to the end of the table."
	wrapAround := false.
	[true] whileTrue:
		[nextSelector := objectMemory fetchPointer: index ofObject: dictionary.
		 nextSelector = objectMemory nilObject ifTrue:
			[^nil].
		 nextSelector = selector ifTrue:
			[methodArray := objectMemory fetchPointer: MethodArrayIndex ofObject: dictionary.
			 ^objectMemory fetchPointer: index - SelectorStart ofObject: methodArray].
		 index := index + 1.
		 index = length ifTrue:
			[wrapAround ifTrue: [^nil].
			 wrapAround := true.
			 index := SelectorStart]].
	^nil "for Slang"
]

{ #category : #'message sending' }
StackInterpreter >> lookupMethodInClass: class [
	| currentClass dictionary found |
	<inline: false>
	self assert: class ~= objectMemory nilObject.
	currentClass := class.
	[currentClass ~= objectMemory nilObject]
		whileTrue:
		[dictionary := objectMemory fetchPointer: MethodDictionaryIndex ofObject: currentClass.
		dictionary = objectMemory nilObject ifTrue:
			["MethodDict pointer is nil (hopefully due a swapped out stub)
				-- raise exception #cannotInterpret:."
			self createActualMessageTo: class.
			messageSelector := objectMemory splObj: SelectorCannotInterpret.
			self sendBreak: messageSelector + BaseHeaderSize
				point: (objectMemory lengthOf: messageSelector)
				receiver: nil.
			^self lookupMethodInClass: (self superclassOf: currentClass)].
		found := self lookupMethodInDictionary: dictionary.
		found ifTrue: [^currentClass].
		currentClass := self superclassOf: currentClass].

	"Could not find #doesNotUnderstand: -- unrecoverable error."
	messageSelector = (objectMemory splObj: SelectorDoesNotUnderstand) ifTrue:
		[self error: 'Recursive not understood error encountered'].

	"Cound not find a normal message -- raise exception #doesNotUnderstand:"
	self createActualMessageTo: class.
	messageSelector := objectMemory splObj: SelectorDoesNotUnderstand.
	self sendBreak: messageSelector + BaseHeaderSize
		point: (objectMemory lengthOf: messageSelector)
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
	length := objectMemory fetchWordLengthOf: dictionary.
	mask := length - SelectorStart - 1.
	index := SelectorStart + (mask bitAnd: ((objectMemory isIntegerObject: messageSelector)
												ifTrue: [objectMemory integerValueOf: messageSelector]
												ifFalse: [objectMemory hashBitsOf: messageSelector])).

	"It is assumed that there are some nils in this dictionary, and search will 
	 stop when one is encountered. However, if there are no nils, then wrapAround 
	 will be detected the second time the loop gets to the end of the table."
	wrapAround := false.
	[true] whileTrue:
		[nextSelector := objectMemory fetchPointer: index ofObject: dictionary.
		 nextSelector = objectMemory nilObject ifTrue: [^ false].
		 nextSelector = messageSelector ifTrue:
			[methodArray := objectMemory fetchPointer: MethodArrayIndex ofObject: dictionary.
			 newMethod := objectMemory fetchPointer: index - SelectorStart ofObject: methodArray.
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
	"Lookup messageSelector in class.  Answer 0 on success. Answer the splObj: index
	 for the error selector to use on failure rather than performing MNU processing etc."
	| currentClass dictionary |
	<inline: true>

	currentClass := class.
	[currentClass ~= objectMemory nilObject] whileTrue:
		[dictionary := objectMemory fetchPointer: MethodDictionaryIndex ofObject: currentClass.
		 dictionary = objectMemory nilObject ifTrue:
			[lkupClass := self superclassOf: currentClass.
			 ^SelectorCannotInterpret].
		 (self lookupMethodInDictionary: dictionary) ifTrue:
			[self addNewMethodToCache: class.
			 ^0].
		currentClass := self superclassOf: currentClass].
	lkupClass := class.
	^SelectorDoesNotUnderstand
]

{ #category : #'frame access' }
StackInterpreter >> makeBaseFrameFor: aContext [ "<Integer>"
	"Marry aContext with the base frame of a new stack page.  Build the base
	 frame to reflect the context's state.  Answer the new page."
	<returnTypeC: #'StackPage *'>
	| page pointer theMethod theIP numArgs stackPtrIndex maybeClosure |
	<inline: false>
	<var: #page type: #'StackPage *'>
	<var: #pointer type: #'char *'>
	self assert: (self isSingleContext: aContext).
	page := self newStackPage.
	pointer := page baseAddress.
	theIP := objectMemory fetchPointer: InstructionPointerIndex ofObject: aContext.
	theMethod := objectMemory fetchPointer: MethodIndex ofObject: aContext.
	(objectMemory isIntegerObject: theIP) ifFalse:
		[self error: 'context is not resumable'].
	theIP := objectMemory integerValueOf: theIP.
	"If the frame is a closure activation then the closure should be on the stack in
	 the pushed receiver position (closures receiver the value[:value:] messages).
	 Otherwise it should be the receiver proper."
	maybeClosure := objectMemory fetchPointer: ClosureIndex ofObject: aContext.
	maybeClosure ~= objectMemory nilObject
		ifTrue:
			[numArgs := self argumentCountOfClosure: maybeClosure.
			 stackPages longAt: pointer put: maybeClosure]
		ifFalse:
			[| header |
			 header := self headerOf: theMethod.
			 numArgs := self argumentCountOfMethodHeader: header.
			 self cppIf: MULTIPLEBYTECODESETS
				ifTrue: "If this is a synthetic context its IP could be pointing at the CallPrimitive opcode.  If so, skip it."
					[(theIP signedIntFromLong > 0
					  and: [(self methodHeaderHasPrimitive: header)
					  and: [theIP = (1 + (objectMemory lastPointerOf: theMethod))]]) ifTrue:
						[theIP := theIP + (self sizeOfCallPrimitiveBytecode: header)]].
			 stackPages longAt: pointer put: (objectMemory fetchPointer: ReceiverIndex ofObject: aContext)].
	"Put the arguments on the stack"
	1 to: numArgs do:
		[:i|
		stackPages
			longAt: (pointer := pointer - BytesPerWord)
			put: (objectMemory fetchPointer: ReceiverIndex + i ofObject: aContext)].
	"saved caller ip is sender context in base frame"
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: (objectMemory fetchPointer: SenderIndex ofObject: aContext).
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
		put: (self encodeFrameFieldHasContext: true isBlock: maybeClosure ~= objectMemory nilObject numArgs: numArgs).
	self assert: (self frameHasContext: page baseFP).
	self assert: (self frameNumArgs: page baseFP) == numArgs.
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: aContext.
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: (objectMemory fetchPointer: ReceiverIndex ofObject: aContext).
	stackPtrIndex := self quickFetchInteger: StackPointerIndex ofObject: aContext.
	self assert: ReceiverIndex + stackPtrIndex < (objectMemory lengthOf: aContext).
	numArgs + 1 to: stackPtrIndex do:
		[:i|
		stackPages
			longAt: (pointer := pointer - BytesPerWord)
			put: (objectMemory fetchPointer: ReceiverIndex + i ofObject: aContext)].
	"top of stack is the instruction pointer"
	theIP := self iframeInstructionPointerForIndex: theIP method: theMethod.
	stackPages longAt: (pointer := pointer - BytesPerWord) put: theIP.
	page headSP: pointer.
	self assert: (self context: aContext hasValidInversePCMappingOf: theIP in: page baseFP).

	"Mark context as married by setting its sender to the frame pointer plus SmallInteger
	 tags and the InstructionPointer to the saved fp (which ensures correct alignment
	 w.r.t. the frame when we check for validity) plus SmallInteger tags."
	objectMemory storePointerUnchecked: SenderIndex
		ofObject: aContext
		withValue: (self withSmallIntegerTags: page baseFP).
	objectMemory storePointerUnchecked: InstructionPointerIndex
		ofObject: aContext
		withValue: (self withSmallIntegerTags: 0).
	self assert: (objectMemory isIntegerObject: (objectMemory fetchPointer: SenderIndex ofObject: aContext)).
	self assert: (self frameOfMarriedContext: aContext) = page baseFP.
	self assert: self validStackPageBaseFrames.
	^page
]

{ #category : #utilities }
StackInterpreter >> makePointwithxValue: xValue yValue: yValue [
"make a Point xValue@yValue.
We know both will be integers so no value nor root checking is needed"
	| pointResult |
	pointResult := objectMemory eeInstantiateSmallClass: (objectMemory splObj: ClassPoint) sizeInBytes: 3*BytesPerWord.
	objectMemory storePointerUnchecked: XIndex ofObject: pointResult withValue: (objectMemory integerObjectOf: xValue).
	objectMemory storePointerUnchecked: YIndex ofObject: pointResult withValue: (objectMemory integerObjectOf: yValue).
	^ pointResult
]

{ #category : #'object memory support' }
StackInterpreter >> mapInterpreterOops [
	"Map all oops in the interpreter's state to their new values 
	during garbage collection or a become: operation."
	"Assume: All traced variables contain valid oops."
	| oop |
	objectMemory nilObject: (objectMemory remap: objectMemory nilObject).
	objectMemory falseObject: (objectMemory remap: objectMemory falseObject).
	objectMemory trueObject: (objectMemory remap: objectMemory trueObject).
	objectMemory specialObjectsOop: (objectMemory remap: objectMemory specialObjectsOop).
	self mapStackPages.
	self mapMachineCode.
	self mapTraceLogs.
	self mapVMRegisters.
	self mapProfileState.
	tempOop = 0 ifFalse: [tempOop := objectMemory remap: tempOop].
	1 to: objectMemory remapBufferCount do: [:i | 
			oop := objectMemory remapBuffer at: i.
			(objectMemory isIntegerObject: oop)
				ifFalse: [objectMemory remapBuffer at: i put: (objectMemory remap: oop)]].

	"Callback support - trace suspended callback list"
	1 to: jmpDepth do:[:i|
		oop := suspendedCallbacks at: i.
		(objectMemory isIntegerObject: oop) 
			ifFalse:[suspendedCallbacks at: i put: (objectMemory remap: oop)].
		oop := suspendedMethods at: i.
		(objectMemory isIntegerObject: oop) 
			ifFalse:[suspendedMethods at: i put: (objectMemory remap: oop)].
	].

]

{ #category : #'object memory support' }
StackInterpreter >> mapMachineCode [
	"This is a no-op in the StackVM"
]

{ #category : #'object memory support' }
StackInterpreter >> mapProfileState [
	profileProcess := objectMemory remap: profileProcess.
	profileMethod := objectMemory remap: profileMethod.
	profileSemaphore := objectMemory remap: profileSemaphore.
	"The longRunningPrimitiveCheckMethod (LRPCM) is sampled in an interrupt.  Be very careful with it.
	  If longRunningPrimitiveCheckSequenceNumber (LRPCSN) = statCheckForEvents then LRPCM has
	  been recenty sampled and could be mapped or not, but it must be newMethod and we can simply
	  copy newMethod.  If LRPCSN ~= statCheckForEvents then LRPCM must be some extant object and
	  needs to be remapped."
	self sqLowLevelMFence.
	longRunningPrimitiveCheckMethod ~= nil ifTrue:
		[longRunningPrimitiveCheckMethod :=
			longRunningPrimitiveCheckSequenceNumber = statCheckForEvents
				ifTrue: [newMethod]
				ifFalse: [self remap: longRunningPrimitiveCheckMethod].
		 self sqLowLevelMFence].
	longRunningPrimitiveCheckSemaphore ~= nil ifTrue:
		[longRunningPrimitiveCheckSemaphore := objectMemory remap: longRunningPrimitiveCheckSemaphore]
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
				 (objectMemory isIntegerObject: oop) ifFalse:
					[stackPages longAt: theSP put: (objectMemory remap: oop)].
				 theSP := theSP + BytesPerWord].
			 (self frameHasContext: theFP) ifTrue:
				[stackPages
					longAt: theFP + FoxThisContext
					put: (objectMemory remap: (self frameContext: theFP))].
			 theIPPtr ~= 0 ifTrue:
				[self assert: (stackPages longAt: theIPPtr) > (self frameMethod: theFP).
				 theIP := (stackPages longAt: theIPPtr) - (self frameMethod: theFP)].
			 stackPages
				longAt: theFP + FoxMethod
				put: (objectMemory remap: (self frameMethod: theFP)).
			 theIPPtr ~= 0 ifTrue:
				[stackPages longAt: theIPPtr put: theIP + (self frameMethod: theFP)].
			 (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
				[theSP := (theIPPtr := theFP + FoxCallerSavedIP) + BytesPerWord.
				 theFP := callerFP].
			 theSP := theFP + FoxCallerContext. "a.k.a. FoxCallerSavedIP"
			 [theSP <= thePage baseAddress] whileTrue:
				[oop := stackPages longAt: theSP.
				 (objectMemory isIntegerObject: oop) ifFalse:
					[stackPages longAt: theSP put: (objectMemory remap: oop)].
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
	method := (objectMemory remap: method).
	instructionPointer := instructionPointer + method. "*rel to method"
	(objectMemory isIntegerObject: messageSelector) ifFalse:
		[messageSelector := objectMemory remap: messageSelector].
	(objectMemory isIntegerObject: newMethod) ifFalse:
		[newMethod := objectMemory remap: newMethod].
	lkupClass := objectMemory remap: lkupClass
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
	self markAndTraceTraceLog.
	self markAndTracePrimTraceLog.
	objectMemory markAndTrace: objectMemory specialObjectsOop. "also covers nilObj, trueObj, falseObj, and compact classes"
	(objectMemory isIntegerObject: messageSelector) ifFalse:
		[objectMemory markAndTrace: messageSelector].
	(objectMemory isIntegerObject: newMethod) ifFalse:
		[objectMemory markAndTrace: newMethod.
	objectMemory markAndTrace: lkupClass].
	self traceProfileState.
	tempOop = 0 ifFalse: [objectMemory markAndTrace: tempOop].

	1 to: objectMemory remapBufferCount do: [:i | 
			oop := objectMemory remapBuffer at: i.
			(objectMemory isIntegerObject: oop) ifFalse: [objectMemory markAndTrace: oop]].

	"Callback support - trace suspended callback list"
	1 to: jmpDepth do:[:i|
		oop := suspendedCallbacks at: i.
		(objectMemory isIntegerObject: oop) ifFalse:[objectMemory markAndTrace: oop].
		oop := suspendedMethods at: i.
		(objectMemory isIntegerObject: oop) ifFalse:[objectMemory markAndTrace: oop].
	]
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceOrFreeMachineCode: fullGCFlag [
	"This is a no-op in the StackVM"
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTracePrimTraceLog [
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
		 (objectMemory isIntegerObject: oop) ifFalse:
			[objectMemory markAndTrace: oop].
		 theSP := theSP + BytesPerWord].
	(self frameHasContext: theFP) ifTrue:
		[self assert: (self isContext: (self frameContext: theFP)).
		 objectMemory markAndTrace: (self frameContext: theFP)].
	objectMemory markAndTrace: (self iframeMethod: theFP).
	(callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
		[theSP := theFP + FoxCallerSavedIP + BytesPerWord.
		 theFP := callerFP].
	theSP := theFP + FoxCallerSavedIP. "caller ip is frameCallerContext in a base frame"
	[theSP <= thePage baseAddress] whileTrue:
		[oop := stackPages longAt: theSP.
		 (objectMemory isIntegerObject: oop) ifFalse:
			[objectMemory markAndTrace: oop].
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
StackInterpreter >> markContextAsDead: oop [
	"Mark the argument, which must be a context, married, widowed or single, as dead.
	 For married or widowed contexts this breaks any link to the spouse and makes the context single.
	 For all contexts, marks the context as inactive/having been returned from."
	<inline: true>
	self assert: (self isContext: oop).
	objectMemory
		storePointerUnchecked: SenderIndex ofObject: oop withValue: objectMemory nilObject;
		storePointerUnchecked: InstructionPointerIndex ofObject: oop withValue: objectMemory nilObject
]

{ #category : #'frame access' }
StackInterpreter >> marriedContext: spouseContext pointsTo: anOop stackDeltaForCurrentFrame: stackDeltaForCurrentFrame [
	"This is a helper for primitiveObjectPointsTo so it *does not* check the frameContext field because that is an implicit self-reference not present in the state ."
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
	(objectMemory isIntegerObject: anOop)
		ifTrue: "Check stack and instruction pointer fields."
			[(anOop = (objectMemory integerObjectOf: (self stackPointerIndexForFrame: theFP WithSP: theSP))
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
	<inline: false>
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
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<inline: false>
	^self marryFrame: theFP SP: theSP copyTemps: false
]

{ #category : #'frame access' }
StackInterpreter >> marryFrame: theFP SP: theSP copyTemps: copyTemps [
	"Marry an unmarried frame.  This means creating a spouse context
	 initialized with a subset of the frame's state that references the frame.
	 For the default closure implementation we do not need to copy temps.
	 Different closure implementations may require temps to be copied."
	| theContext methodHeader byteSize numArgs numStack closureOrNil numTemps |
	<inline: true>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	self assert: (self frameHasContext: theFP) not.

	methodHeader := self headerOf: (self frameMethod: theFP).
	"Decide how much of the stack to preserve in widowed contexts.  Preserving too much
	 state will potentially hold onto garbage.  Holding onto too little may mean that a dead
	 context isn't informative enough in a debugging situation.  If copyTemps is false (as it
	 is in the default closure implementation) compromise, retaining only the arguments with
	 no temporaries.  Note that we still set the stack pointer to its current value, but stack
	 contents other than the arguments are nil."
	numArgs := self frameNumArgs: theFP.
	numStack := self stackPointerIndexForFrame: theFP WithSP: theSP.

	closureOrNil := (self frameIsBlockActivation: theFP)
						ifTrue: [self pushedReceiverOrClosureOfFrame: theFP]
						ifFalse: [objectMemory nilObject].

	byteSize := (methodHeader bitAnd: LargeContextBit) ~= 0
					ifTrue: [LargeContextSize]
					ifFalse: [SmallContextSize].
	theContext := objectMemory eeInstantiateMethodContextByteSize: byteSize.
	self assert: numStack + ReceiverIndex << ShiftForWord + BaseHeaderSize <= byteSize. 
	"Mark context as married by setting its sender to the frame pointer plus SmallInteger
	 tags and the InstructionPointer to the saved fp (which ensures correct alignment
	 w.r.t. the frame when we check for validity)"
	objectMemory storePointerUnchecked: SenderIndex
		ofObject: theContext
		withValue: (self withSmallIntegerTags: theFP).
	objectMemory storePointerUnchecked: InstructionPointerIndex
		ofObject: theContext
		withValue: (self withSmallIntegerTags: (self frameCallerFP: theFP)).
	objectMemory storePointerUnchecked: StackPointerIndex
		ofObject: theContext
		withValue: (objectMemory integerObjectOf: numStack).
	objectMemory storePointerUnchecked: MethodIndex
		ofObject: theContext
		withValue: (self frameMethod: theFP).
	objectMemory storePointerUnchecked: ClosureIndex ofObject: theContext withValue: closureOrNil.
	objectMemory storePointerUnchecked: ReceiverIndex
		ofObject: theContext
		withValue: (self frameReceiver: theFP).
	"If copyTemps is false, store just the arguments.  If the frame is divorced the context
	 will have valid arguments but all temporaries will be nil."
	1 to: numArgs do:
		[:i|
		objectMemory storePointerUnchecked: ReceiverIndex + i
			ofObject: theContext "inline self temporary: i - 1 in:theFP" 
			withValue: (stackPages longAt: theFP
										+ FoxCallerSavedIP
										+ ((numArgs - i + 1) * BytesPerWord))].
	copyTemps ifTrue:
		[numTemps := self frameNumTemps: theFP.
		 1 to: numTemps do:
			[:i|
			objectMemory storePointerUnchecked: ReceiverIndex + i + numArgs
				ofObject: theContext
				withValue: (self temporary: i - 1 in: theFP)].
		 numArgs := numArgs + numTemps].

	numArgs + 1 to: numStack do:
		[:i|
		objectMemory storePointerUnchecked: ReceiverIndex + i
			ofObject: theContext
			withValue: objectMemory nilObject].

	self setFrameContext: theFP to: theContext.
	self setFrameHasContext: theFP.

	self assert: (self frameHasContext: theFP).
	self assert: (self frameOfMarriedContext: theContext) = theFP.
	self assert: numStack + ReceiverIndex < (objectMemory lengthOf: theContext).

	^theContext

]

{ #category : #'compiled methods' }
StackInterpreter >> maybeFlagMethodAsInterpreted: aMethod [
	"Convenient  noop in the StackInterpreter e.g. for sendInvokeCallbackContext:"
]

{ #category : #'debug support' }
StackInterpreter >> maybeTraceStackOverflow [
	"nop in the stack interpreter"
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodArg: index [
	"Like #stackValue: but access method arguments left-to-right"
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
StackInterpreter >> methodClassAssociationOf: methodPointer [
	<api>
	^self literal: (self literalCountOf: methodPointer) - 1 ofMethod: methodPointer
]

{ #category : #'compiled methods' }
StackInterpreter >> methodClassOf: methodPointer [

	^self cppIf: NewspeakVM
		ifTrue:
			[ | literal |
			literal := self literal: (self literalCountOf: methodPointer) - 1 ofMethod: methodPointer.
			literal = objectMemory nilObject
				ifTrue: [literal]
				ifFalse: [objectMemory fetchPointer: ValueIndex ofObject: literal]]
		ifFalse:
			[objectMemory fetchPointer: ValueIndex ofObject: (self literal: (self literalCountOf: methodPointer) - 1 ofMethod: methodPointer)]
]

{ #category : #'compiled methods' }
StackInterpreter >> methodHeaderHasPrimitive: methodHeader [
	"Note: We now have 10 bits of primitive index, but they are in two places
	 for temporary backward compatibility.  The time to unpack is negligible,
	 since the derived primitive function pointer is stored in the method cache."
	^self
		cppIf: MULTIPLEBYTECODESETS
		ifTrue: [(self headerIndicatesAlternateBytecodeSet: methodHeader)
				ifTrue: [self alternateHeaderHasPrimitiveFlag: methodHeader]
				ifFalse: [(methodHeader bitAnd: 16r200003FE) ~= 0]]
		ifFalse: [(methodHeader bitAnd: 16r200003FE) ~= 0]
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodPrimitiveIndex [
	<api>
	((objectMemory addressCouldBeObj: newMethod)
	 and: [objectMemory isCompiledMethod: newMethod]) ifFalse:
		[^-1].
	^self primitiveIndexOf: newMethod
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodReturnValue: oop [
	"Sets the return value for a method.  In the CoInterpreter we replace the cumbersome
	 primResult machinery."
	self pop: argumentCount+1 thenPush: oop.
	^0
]

{ #category : #'internal interpreter access' }
StackInterpreter >> methodUsesAlternateBytecodeSet: aMethodObj [
	<api>
	<inline: true>
	"A negative header selects the alternate bytecode set."
	^self headerIndicatesAlternateBytecodeSet: (self headerOf: aMethodObj)
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
	self assert: (callerFP < oldPage baseAddress
				and: [callerFP > (oldPage realStackLimit - (LargeContextSize / 2))]).
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
		 objectMemory storePointerUnchecked: SenderIndex
			ofObject: theContext
			withValue: (self withSmallIntegerTags: fpInNewPage).
		 objectMemory storePointerUnchecked: InstructionPointerIndex
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
	sp := objectMemory fetchPointer: StackPointerIndex ofObject: aContext.
	(objectMemory isIntegerObject: sp) ifFalse: [^0].
	^objectMemory integerValueOf: sp
]

{ #category : #'debug printing' }
StackInterpreter >> nameOfClass: classOop [
	"Brain-damaged nameOfClass: for C VM.  Does *not* answer Foo class for metaclasses.
	 Use e.g. classIsMeta: to avoid being fooled."
	<inline: false>
	<returnTypeC: 'char *'>
	(objectMemory sizeBitsOf: classOop) = metaclassSizeBits ifTrue:
		[^self nameOfClass: (objectMemory fetchPointer: thisClassIndex ofObject: classOop)].
	^objectMemory firstFixedField: (objectMemory fetchPointer: classNameIndex ofObject: classOop)
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

{ #category : #'newspeak bytecode support' }
StackInterpreter >> nextImplicitReceiverFor: anObject withMixin: mixin [
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
	[(targetMixin = objectMemory nilObject "or: [implicitReceiver = objectMemory nilObject]") ifTrue:
		[^objectMemory nilObject].
	mixinApplication := self findApplicationOfTargetMixin: targetMixin
							startingAtNonMetaClass: (objectMemory fetchClassOf: implicitReceiver).
	 mixinApplication = objectMemory nilObject ifTrue:
		[^objectMemory nilObject].
	 dictionary := objectMemory fetchPointer: MethodDictionaryIndex ofObject: mixinApplication.
	 found := self lookupMethodInDictionary: dictionary.
	 found]
		whileFalse:
			[implicitReceiver := objectMemory fetchPointer: EnclosingObjectIndex ofObject: mixinApplication.
			 theMixin := objectMemory fetchPointer: MixinIndex ofObject: mixinApplication.
			 theMixin = objectMemory nilObject ifTrue:
				[^objectMemory nilObject].
			 targetMixin := objectMemory fetchPointer: EnclosingMixinIndex ofObject: theMixin].
	^implicitReceiver
]

{ #category : #'compiled methods' }
StackInterpreter >> noAssertHeaderOf: methodPointer [
	^objectMemory fetchPointer: HeaderIndex ofObject: methodPointer
]

{ #category : #'internal interpreter access' }
StackInterpreter >> noInlineTemporary: offset in: theFP [
	<var: #theFP type: #'char *'>
	<inline: false>
	^self temporary: offset in: theFP
]

{ #category : #'internal interpreter access' }
StackInterpreter >> noInlineTemporary: offset in: theFP put: valueOop [
	<var: #theFP type: #'char *'>
	<inline: false>
	^self temporary: offset in: theFP put: valueOop
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
		 (objectMemory isMarked: (self frameContext:  theFP)) ifTrue:
			[^false]].
	(theFP := self frameCallerFP: theFP) ~= 0] whileTrue.
	^true
]

{ #category : #'send bytecodes' }
StackInterpreter >> normalSend [
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that 
	the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeNamed: 'normalSend' inCase: #singleExtendedSendBytecode>
	| rcvr |
	rcvr := self internalStackValue: argumentCount.
	lkupClass := objectMemory fetchClassOf: rcvr.
	self assert: lkupClass ~= objectMemory nilObject.
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
	(objectMemory isIntegerObject: oop) ifTrue: [self primitiveFail. ^ nil].
	^oop
]

{ #category : #'cog jit support' }
StackInterpreter >> objectMemory [
	<doNotGenerate>
	^objectMemory
]

{ #category : #'debug support' }
StackInterpreter >> okayFields: oop [
	"Check if the argument is an ok object.
	 If this is a pointers object, check that its fields are all okay oops."

	| i fieldOop |
	(oop = nil or: [oop = 0]) ifTrue: [ ^true ].
	(objectMemory isIntegerObject: oop) ifTrue: [ ^true ].
	(objectMemory okayOop: oop) ifFalse: [ ^false ].
	(self oopHasOkayClass: oop) ifFalse: [ ^false ].
	((objectMemory isPointers: oop) or: [objectMemory isCompiledMethod: oop]) ifFalse: [ ^true ].
	(objectMemory isCompiledMethod: oop)
		ifTrue:
			[i := (self literalCountOf: oop) - 1]
		ifFalse:
			[(self isContext: oop)
				ifTrue: [i := CtxtTempFrameStart + (self fetchStackPointerOf: oop) - 1]
				ifFalse: [i := (objectMemory lengthOf: oop) - 1]].
	[i >= 0] whileTrue: [
		fieldOop := objectMemory fetchPointer: i ofObject: oop.
		(objectMemory isIntegerObject: fieldOop) ifFalse: [
			(objectMemory okayOop: fieldOop) ifFalse: [ ^false ].
			(self oopHasOkayClass: fieldOop) ifFalse: [ ^false ].
		].
		i := i - 1.
	].
	^true
]

{ #category : #'debug support' }
StackInterpreter >> okayInterpreterObjects [

	| oopOrZero oop |
	self okayFields: objectMemory nilObject.
	self okayFields: objectMemory falseObject.
	self okayFields: objectMemory trueObject.
	self okayFields: objectMemory specialObjectsOop.
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
	1 to: objectMemory remapBufferCount do: [ :i |
		oop := objectMemory remapBuffer at: i.
		(objectMemory isIntegerObject: oop) ifFalse: [
			self okayFields: oop.
		].
	].
	self okayStackZone.
]

{ #category : #'debug support' }
StackInterpreter >> oopHasOkayClass: signedOop [
	"Attempt to verify that the given oop has a reasonable behavior. The class must be a valid, non-integer oop and must not be nilObj. It must be a pointers object with three or more fields. Finally, the instance specification field of the behavior must match that of the instance."

	| oop oopClass formatMask behaviorFormatBits oopFormatBits |
	<var: #oop type: #usqInt>
	<var: #oopClass type: #usqInt>

	oop := self cCoerce: signedOop to: #usqInt.
	objectMemory okayOop: oop.
	oopClass := self cCoerce: (objectMemory fetchClassOf: oop) to: #usqInt.

	(objectMemory isIntegerObject: oopClass)
		ifTrue: [ self error: 'a SmallInteger is not a valid class or behavior'. ^false ].
	(objectMemory okayOop: oopClass)
		ifFalse: [ self error: 'class oop is not ok'. ^false ].
	((objectMemory isPointers: oopClass) and: [(objectMemory lengthOf: oopClass) >= 3])
		ifFalse: [ self error: 'a class (behavior) must be a pointers object of size >= 3'. ^false ].
	(objectMemory isBytes: oop)
		ifTrue: [ formatMask := 16rC00 ]  "ignore extra bytes size bits"
		ifFalse: [ formatMask := 16rF00 ].

	behaviorFormatBits := (objectMemory formatOfClass: oopClass) bitAnd: formatMask.
	oopFormatBits := (objectMemory baseHeader: oop) bitAnd: formatMask.
	behaviorFormatBits = oopFormatBits
		ifFalse: [ self error: 'object and its class (behavior) formats differ'. ^false ].
	^true
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pop2AndPushIntegerIfOK: integerResult [

	self successful ifTrue:
		[(objectMemory isIntegerValue: integerResult)
			ifTrue: [self pop: 2 thenPush: (objectMemory integerObjectOf: integerResult)]
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
		put: (objectMemory booleanObjectOf: trueOrFalse).
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
		put: (objectMemory integerObjectOf: integerVal).
	stackPointer := sp
]

{ #category : #'primitive support' }
StackInterpreter >> popFloat [
	<returnTypeC: #double>
	^self floatValueOf: self popStack
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
		ifTrue: [(objectMemory isIntegerValue: integerValue)
					ifTrue: [^ objectMemory integerObjectOf: integerValue]].

	self cppIf: BytesPerWord = 4
		ifTrue: "Faster instantiateSmallClass: currently only works with integral word size."
			[newLargeInteger := objectMemory
									eeInstantiateSmallClass: (objectMemory splObj: ClassLargePositiveInteger)
									sizeInBytes: BaseHeaderSize + 4]
		ifFalse: "Cant use instantiateSmallClass: due to integral word requirement."
			[newLargeInteger := objectMemory
									eeInstantiateClass: (objectMemory splObj: ClassLargePositiveInteger)
									indexableSize: 4].
	objectMemory storeByte: 3 ofObject: newLargeInteger withValue: ((integerValue >> 24) bitAnd: 16rFF).
	objectMemory storeByte: 2 ofObject: newLargeInteger withValue: ((integerValue >> 16) bitAnd: 16rFF).
	objectMemory storeByte: 1 ofObject: newLargeInteger withValue: ((integerValue >> 8) bitAnd: 16rFF).
	objectMemory storeByte: 0 ofObject: newLargeInteger withValue: (integerValue bitAnd: 16rFF).
	^newLargeInteger
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
	newLargeInteger := objectMemory instantiateClass: (objectMemory splObj: ClassLargePositiveInteger) indexableSize:  sz.
	0 to: sz-1 do: [:i |
		value := self cCode: '(integerValue >> (i * 8)) & 255'.
		objectMemory storeByte: i ofObject: newLargeInteger withValue: value].
	^ newLargeInteger

]

{ #category : #'object memory support' }
StackInterpreter >> postBecomeAction [
	"This is a noop in the StackInterpreter"
]

{ #category : #'object memory support' }
StackInterpreter >> postGCAction [
	"Shrink free memory and signal the gc semaphore"
	| freeSizeNow |

	freeSizeNow := objectMemory freeSize.
	(freeSizeNow > objectMemory shrinkThreshold
	 and: [freeSizeNow > objectMemory growHeadroom]) ifTrue:
		["Attempt to shrink memory after successfully reclaiming lots of memory"
		 objectMemory shrinkObjectMemory: freeSizeNow - objectMemory growHeadroom].

	self signalSemaphoreWithIndex: gcSemaphoreIndex
]

{ #category : #'object memory support' }
StackInterpreter >> preBecomeAction [
	"Need to write back the frame pointers unless all pages are free (as in snapshot)"
	stackPage ~= 0 ifTrue:
		[self externalWriteBackHeadFramePointers]
]

{ #category : #'object memory support' }
StackInterpreter >> preGCAction: gcModeArg [
	<asmLabel: false>
	"Need to write back the frame pointers unless all pages are free (as in snapshot)"
	stackPage ~= 0 ifTrue:
		[self externalWriteBackHeadFramePointers]
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveEventProcessingControl [
	"With 0 args answers whether ioProcessEvents is enabled and being called.
	 With 1 arg expects a boolean which will enable ioProcessEvents if true and
	 disable it if false, answering its previous state."
	<export: true>
	| enabled |
	enabled := inIOProcessEvents >= 0.
	argumentCount = 0 ifTrue:
		[^self pop: 1 thenPushBool: enabled].
	argumentCount = 1 ifTrue:
		[self stackTop = objectMemory trueObject
			ifTrue: [inIOProcessEvents < 0 ifTrue:
					[inIOProcessEvents := 0]]
			ifFalse:
				[self stackTop = objectMemory falseObject
					ifTrue: [inIOProcessEvents := -1]
					ifFalse: [^self primitiveFailFor: PrimErrBadArgument]].
		 ^self pop: 2 thenPushBool: enabled].
	self primitiveFailFor: PrimErrBadNumArgs
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

{ #category : #'comparison float primitives' }
StackInterpreter >> primitiveFloatEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	^rcvr = arg
]

{ #category : #'comparison float primitives' }
StackInterpreter >> primitiveFloatGreater: rcvrOop thanArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	^rcvr > arg
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

{ #category : #'comparison float primitives' }
StackInterpreter >> primitiveFloatLess: rcvrOop thanArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	^rcvr < arg
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
StackInterpreter >> primitiveFloatSubtract: rcvrOop fromArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := self loadFloatOrIntFrom: rcvrOop.
	arg := self loadFloatOrIntFrom: argOop.
	self successful ifTrue:
		[self pop: 2 thenPushFloat: rcvr - arg]
]

{ #category : #'compiled methods' }
StackInterpreter >> primitiveIndexOf: methodPointer [
	<api>
	^self primitiveIndexOfMethod: methodPointer header: (self headerOf: methodPointer)
]

{ #category : #'compiled methods' }
StackInterpreter >> primitiveIndexOfMethod: theMethod header: methodHeader [
	"Note: With the Squeak V0 format we now have 10 bits of primitive index, but they are in
	 two places for temporary backward compatibility.  The time to unpack is negligible,
	 since the derived primitive function pointer is stored in the method cache.  With the new
	 format we assume a 3-byte CallPrimitive with a little-endian 16-bit primitive index."
	<api>
	<inline: true>
	^self cppIf: MULTIPLEBYTECODESETS
		ifTrue:
			[(self headerIndicatesAlternateBytecodeSet: methodHeader)
				ifTrue:
					[(self alternateHeaderHasPrimitiveFlag: methodHeader)
						ifTrue:
							[| firstBytecode |
							 firstBytecode := self firstBytecodeOfAlternateHeader: methodHeader method: theMethod.
							 (objectMemory byteAt: firstBytecode + 1) + ((objectMemory byteAt: firstBytecode + 2) << 8)]
						ifFalse:
							[0]]
				ifFalse:
					[| primBits |
					 primBits := methodHeader >> 1.
					 (primBits bitAnd: 16r1FF) + (primBits >> 19 bitAnd: 16r200)]]
		ifFalse:
			[| primBits |
			primBits := methodHeader >> 1.
			(primBits bitAnd: 16r1FF) + (primBits >> 19 bitAnd: 16r200)]
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
	(objectMemory isArray: argumentArray) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].

	"Check if number of arguments is reasonable; MaxNumArgs isn't available
	 so just use LargeContextSize"
	arraySize := objectMemory fetchWordLengthOf: argumentArray.
	arraySize > (LargeContextSize / BytesPerWord) ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].

	performArgCount := argumentCount.
	"Push newMethod to save it in case of failure,
	 then push the actual receiver and args out of the array."
	self push: newMethod.
	self push: actualReceiver.
	"Copy the arguments to the stack, and execute"
	1 to: arraySize do:
		[:index| self push: (objectMemory fetchPointer: index - 1 ofObject: argumentArray)].
	argumentCount := arraySize.
	messageSelector := selector.
	self sendBreak: messageSelector + BaseHeaderSize
		point: (objectMemory lengthOf: messageSelector)
		receiver: actualReceiver.
	self printSends ifTrue:
		[self printActivationNameForSelector: messageSelector startClass: lookupClass; cr].
	self findNewMethodInClass: lookupClass.

	"Only test CompiledMethods for argument count - any other objects playacting as CMs will have to take their chances"
	((objectMemory isOopCompiledMethod: newMethod)
	  and: [(self argumentCountOf: newMethod) ~= argumentCount]) ifTrue:
		["Restore the state by popping all those array entries and pushing back the selector and array, and fail"
		 self pop: arraySize + 1.
		 newMethod := self popStack.
		 ^self primitiveFailFor: PrimErrBadNumArgs].

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

{ #category : #'debug printing' }
StackInterpreter >> print: s [
	"For testing in Smalltalk, this method should be overridden in a subclass."
	<api>
	<var: #s type: #'char *'>
	self cCode: 'fputs(s, stdout)'
]

{ #category : #'debug printing' }
StackInterpreter >> printActivationNameFor: aMethod receiver: anObject isBlock: isBlock firstTemporary: maybeMessage [
	| methClass methodSel |
	<inline: false>
	isBlock ifTrue:
		[self print: '[] in '].
	methClass := self findClassOfMethod: aMethod forReceiver: anObject.
	methodSel := self findSelectorOfMethod: aMethod forReceiver: anObject.
	(objectMemory addressCouldBeOop: anObject)
		ifTrue:
			[(objectMemory fetchClassOf: anObject) = methClass
				ifTrue: [self printNameOfClass: methClass count: 5]
				ifFalse:
					[self printNameOfClass: (objectMemory fetchClassOf: anObject) count: 5.
					 self print: '('.
					 self printNameOfClass: methClass count: 5.
					 self print: ')']]
		ifFalse: [self print: 'INVALID RECEIVER'].
	self print: '>'.
	(objectMemory addressCouldBeOop: methodSel)
		ifTrue:
			[methodSel = objectMemory nilObject
				ifTrue: [self print: '?']
				ifFalse: [self printStringOf: methodSel]]
		ifFalse: [self print: 'INVALID SELECTOR'].
	(methodSel = (objectMemory splObj: SelectorDoesNotUnderstand)
	and: [(objectMemory addressCouldBeObj: maybeMessage)
	and: [(objectMemory fetchClassOf: maybeMessage) = (objectMemory splObj: ClassMessage)]]) ifTrue:
		["print arg message selector"
		methodSel := objectMemory fetchPointer: MessageSelectorIndex ofObject: maybeMessage.
		self print: ' '.
		self printStringOf: methodSel]
]

{ #category : #'debug printing' }
StackInterpreter >> printActivationNameForMethod: aMethod startClass: startClass isBlock: isBlock firstTemporary: maybeMessage [
	| methClass methodSel |
	<inline: false>
	isBlock ifTrue:
		[self print: '[] in '].
	self findSelectorAndClassForMethod: aMethod
		lookupClass: startClass
		do: [:sel :class|
			methodSel := sel.
			methClass := class].
	((self addressCouldBeOop: startClass) and: [methClass notNil])
		ifTrue:
			[startClass = methClass
				ifTrue: [self printNameOfClass: methClass count: 5]
				ifFalse:
					[self printNameOfClass: startClass count: 5.
					 self printChar: $(.
					 self printNameOfClass: methClass count: 5.
					 self printChar: $)]]
		ifFalse: [self print: 'INVALID CLASS'].
	self printChar: $>.
	(objectMemory addressCouldBeOop: methodSel)
		ifTrue:
			[(objectMemory isBytes: methodSel)
				ifTrue: [self printStringOf: methodSel]
				ifFalse: [self printOopShort: methodSel]]
		ifFalse: [self print: 'INVALID SELECTOR'].
	(methodSel = (objectMemory splObj: SelectorDoesNotUnderstand)
	and: [(objectMemory addressCouldBeObj: maybeMessage)
	and: [(objectMemory fetchClassOfNonInt: maybeMessage) = (objectMemory splObj: ClassMessage)]]) ifTrue:
		["print arg message selector"
		methodSel := objectMemory fetchPointer: MessageSelectorIndex ofObject: maybeMessage.
		self print: ' '.
		self printStringOf: methodSel]
]

{ #category : #'debug printing' }
StackInterpreter >> printActivationNameForSelector: aSelector startClass: startClass [
	| methClass |
	<inline: false>
	(objectMemory addressCouldBeObj: startClass)
		ifTrue:
			[self findClassForSelector: aSelector
				lookupClass: startClass
				do: [:class| methClass := class].
			(methClass isNil or: [startClass = methClass])
				ifTrue:
					[self printNameOfClass: methClass count: 5..
					 self printChar: $>.
					 methClass ifNil:
						[self printStringOf: (objectMemory splObj: SelectorDoesNotUnderstand).
						 self print: ' ']]
				ifFalse:
					[self printNameOfClass: startClass count: 5.
					 self printChar: $(.
					 self printNameOfClass: methClass count: 5.
					 self printChar: $).
					 self printChar: $>]]
		ifFalse: [self print: 'INVALID CLASS'].
	(objectMemory addressCouldBeOop: aSelector)
		ifTrue:
			[(objectMemory isBytes: aSelector)
				ifTrue: [self printStringOf: aSelector]
				ifFalse: [self printOopShort: aSelector]]
		ifFalse: [self print: 'INVALID SELECTOR']
]

{ #category : #'debug printing' }
StackInterpreter >> printAllStacks [
	"Print all the stacks of all running processes, including those that are currently suspended."
	<api>
	| oop classObj proc semaphoreClass mutexClass schedLists p processList |
	<inline: false>
	proc := self activeProcess.
	self printNameOfClass: (objectMemory fetchClassOf: proc) count: 5; space; printHex: proc.
	self print: ' priority '; printNum: (self quickFetchInteger: PriorityIndex ofObject: proc); cr.
	self printCallStackFP: framePointer. "first the current activation"
	semaphoreClass := objectMemory classSemaphore.
	mutexClass := objectMemory classMutex.
	oop := objectMemory firstObject.
	[self oop: oop isLessThan: objectMemory freeStart] whileTrue:
		[classObj := objectMemory fetchClassOfNonInt: oop.
		 (classObj = semaphoreClass
		  or: [classObj = mutexClass]) ifTrue:
			[self printProcsOnList: oop].
		 oop := objectMemory objectAfter: oop].
	schedLists := objectMemory fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	p := highestRunnableProcessPriority = 0
			ifTrue: [objectMemory fetchWordLengthOf: schedLists]
			ifFalse: [highestRunnableProcessPriority].
	p - 1 to: 0 by: -1 do:
		[:pri|
		processList := objectMemory fetchPointer: pri ofObject: schedLists.
		(self isEmptyList: processList) ifFalse:
			[self cr; print: 'processes at priority '; printNum: pri + 1.
			 self printProcsOnList: processList]]
]

{ #category : #'debug printing' }
StackInterpreter >> printCallStack [
	<inline: false>
	framePointer = nil
		ifTrue: [self printCallStackOf: (objectMemory fetchPointer: SuspendedContextIndex ofObject: self activeProcess)]
		ifFalse: [self printCallStackFP: framePointer]
]

{ #category : #'debug printing' }
StackInterpreter >> printCallStackFP: theFP [
	| context |
	<inline: false>
	<var: #theFP type: #'char *'>
	context := self shortReversePrintFrameAndCallers: theFP.
	[context = objectMemory nilObject] whileFalse:
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
StackInterpreter >> printCallStackOf: aContextOrProcess [
	<api>
	| context |
	<inline: false>
	<var: #theFP type: #'char *'>
	((self isContext: aContextOrProcess) not
	and: [(objectMemory lengthOf: aContextOrProcess) > MyListIndex
	and: [self isContext: (objectMemory
									fetchPointer: SuspendedContextIndex
									ofObject: aContextOrProcess)]]) ifTrue:
		[^self printCallStackOf: (objectMemory
									fetchPointer: SuspendedContextIndex
									ofObject: aContextOrProcess)].
	context := aContextOrProcess.
	[context = objectMemory nilObject] whileFalse:
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
	[ctxt = objectMemory nilObject] whileFalse:
		[(self isMarriedOrWidowedContext: ctxt)
			ifFalse:
				[self shortPrintContext: ctxt.
				 ctxt := objectMemory fetchPointer: SenderIndex ofObject: ctxt]
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
					ifFalse: [self print: 'widowed caller frame '; printHexPtr: theFP; cr.
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
	sender := objectMemory fetchPointer: SenderIndex ofObject: aContext.
	ip := objectMemory fetchPointer: InstructionPointerIndex ofObject: aContext.
	(objectMemory isIntegerObject: sender)
		ifTrue:
			[(self checkIsStillMarriedContext: aContext currentFP: framePointer)
				ifTrue: [self print: 'married (assuming framePointer valid)'; cr]
				ifFalse: [self print: 'widowed (assuming framePointer valid)'; cr].
			self print: 'sender   '; printNum: sender; print: ' (';
				printHexPtr: (self withoutSmallIntegerTags: sender); printChar: $); cr.
			 self print: 'ip       '; printNum: ip; print: ' (';
				printHexPtr: (self withoutSmallIntegerTags: ip); printChar: $); cr]
		ifFalse:
			[self print: 'sender   '; shortPrintOop: sender.
			 self print: 'ip       '.
			 ip = objectMemory nilObject
				ifTrue: [self shortPrintOop: ip]
				ifFalse: [self printNum: ip; print: ' ('; printNum: (objectMemory integerValueOf: ip); space; printHex: (objectMemory integerValueOf: ip); printChar: $); cr]].
	sp := objectMemory fetchPointer: StackPointerIndex ofObject: aContext.
	sp := sp min: (objectMemory lengthOf: aContext) - ReceiverIndex.
	self print: 'sp       '; printNum: sp; print: ' ('; printNum: (objectMemory integerValueOf: sp); printChar: $); cr.
	self print: 'method   '; shortPrintOop: (objectMemory fetchPointer: MethodIndex ofObject: aContext).
	self print: 'closure  '; shortPrintOop: (objectMemory fetchPointer: ClosureIndex ofObject: aContext).
	self print: 'receiver '; shortPrintOop: (objectMemory fetchPointer: ReceiverIndex ofObject: aContext).
	sp := objectMemory integerValueOf: sp.
	1 to: sp do:
		[:i|
		self print: '       '; printNum: i; space; shortPrintOop: (objectMemory fetchPointer: ReceiverIndex + i ofObject: aContext)]
]

{ #category : #'debug printing' }
StackInterpreter >> printContextCallStackOf: aContext [
	"Print the call stack of aContext until it links to a frame."
	| ctxt |
	<inline: false>
	ctxt := aContext.
	[ctxt = objectMemory nilObject or: [self isMarriedOrWidowedContext: ctxt]] whileFalse:
		[self shortPrintContext: ctxt.
		 ctxt := objectMemory fetchPointer: SenderIndex ofObject: ctxt].
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
	self cCode: '' inSmalltalk: [self transcript ensureCr].
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
	 and: [topThing <= (theMethod + (objectMemory sizeBitsOfSafe: theMethod))])
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
	self printFrameAndCallers: theFP SP: theSP short: false
]

{ #category : #'debug printing' }
StackInterpreter >> printFrameAndCallers: theFP SP: theSP short: printShort [
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	(stackPages couldBeFramePointer: theFP) ifFalse: [^nil].
	(self isBaseFrame: theFP) ifFalse:
		[self printFrameAndCallers: (self frameCallerFP: theFP)
			SP: (self frameCallerSP: theFP)
			short: printShort].
	printShort ifTrue:
		[self shortPrintFrame: theFP.
		 ^nil].
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
		print: ((self frameHasContext: theFP) ifTrue: [' hasContext'] ifFalse: [' noContext']);
		print: ((self frameIsBlockActivation: theFP) ifTrue: [' isBlock'] ifFalse: [' notBlock']);
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
		printHex: it;
		tab;
		printChar: $=;
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
	1	to: 11 - (self strlen: name) - (self log10: (idx max: 1)) floor
		do: [:i| self printChar: $ ].
	self print: name;
		printNum: idx;
		print: ': ';
		printHex: it;
		tab;
		printChar: $=;
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
		 it = objectMemory nilObject
			ifTrue: [self print: 'nil']
			ifFalse:
				[self printNum: it]].
	self cr
]

{ #category : #'debug printing' }
StackInterpreter >> printFramesInPage: thePage [
	<export: true> "use export: not api, so it won't be written to cointerp.h. cogit.c is unaware of StackPage"
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	self printFrameAndCallers: thePage headFP SP: thePage headSP short: false
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
	"Print p in hex, passed to 10 characters in the form '    0x1234'"
	<inline: true>
	<var: #p type: #'void *'>
	self printHex: (self oopForPointer: p)
]

{ #category : #'debug printing' }
StackInterpreter >> printMethodDictionary: dictionary [
	<api>
	| methodArray |
	methodArray := objectMemory fetchPointer: MethodArrayIndex ofObject: dictionary.
	SelectorStart to: (objectMemory fetchWordLengthOf: dictionary) - 1 do:
		[:index | | selector meth |
		 selector := objectMemory fetchPointer: index ofObject: dictionary.
		 selector ~= objectMemory nilObject ifTrue:
			[meth := objectMemory fetchPointer: index - SelectorStart ofObject: methodArray.
			 self
				printOopShort: selector;
				print: ' => ';
				printOopShort: meth;
				print: ' (';
				printHex: selector;
				print: ' => ';
				printHex: meth;
				putchar: $);
				cr]]
]

{ #category : #'debug printing' }
StackInterpreter >> printMethodDictionaryOf: behavior [
	<api>
	self printMethodDictionary: (objectMemory fetchPointer: MethodDictionaryIndex ofObject: behavior)
]

{ #category : #'debug printing' }
StackInterpreter >> printMethodHeaderOop: anOop [
	"Override hook for CoInterpreter"
	<inline: true>
	^self printOopShort: anOop
]

{ #category : #'debug printing' }
StackInterpreter >> printNameOfClass: classOop count: cnt [
	"Details: The count argument is used to avoid a possible infinite recursion if classOop is a corrupted object."
	<inline: false>
	(classOop = 0 or: [cnt <= 0]) ifTrue: [^self print: 'bad class'].
	((objectMemory sizeBitsOf: classOop) = metaclassSizeBits
	  and: [metaclassSizeBits > (thisClassIndex * BytesPerWord)])	"(Metaclass instSize * 4)"
		ifTrue: [self printNameOfClass: (objectMemory fetchPointer: thisClassIndex ofObject: classOop) count: cnt - 1.
				self print: ' class']
		ifFalse: [self printStringOf: (objectMemory fetchPointer: classNameIndex ofObject: classOop)]
]

{ #category : #'debug printing' }
StackInterpreter >> printNum: n [
	"For testing in Smalltalk, this method should be overridden in a subclass."

	self cCode: 'printf("%ld", (long) n)'.
]

{ #category : #'debug printing' }
StackInterpreter >> printOop: oop [
	| cls fmt lastIndex startIP bytecodesPerLine column |
	<inline: false>
	self printHex: oop.
	(objectMemory isIntegerObject: oop) ifTrue:
		[^self
			cCode: 'printf("=%ld\n", (long)integerValueOf(oop))'
			inSmalltalk: [self print: (self shortPrint: oop); cr]].
	(oop between: objectMemory startOfMemory and: objectMemory freeStart) ifFalse:
		[self print: ' is not on the heap'; cr.
		 ^nil].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[self print: ' is misaligned'; cr.
		 ^nil].
	(objectMemory isFreeObject: oop) ifTrue:
		[self print: ' is a free chunk of size '; printNum: (objectMemory sizeOfFree: oop); cr.
		 ^nil].
	self print: ': a(n) '.
	self printNameOfClass: (cls := objectMemory fetchClassOfNonInt: oop) count: 5.
	cls = (objectMemory splObj: ClassFloat) ifTrue:
		[self cr; printFloat: (self dbgFloatValueOf: oop); cr.
		 ^nil].
	fmt := objectMemory formatOf: oop.
	fmt > 4 ifTrue:
		[self print: ' nbytes '; printNum: (objectMemory byteSizeOf: oop)].
	self cr.
	(fmt > 4 and: [fmt < 12]) ifTrue:
		["This will answer false if splObj: ClassAlien is nilObject"
		 (self is: oop KindOfClass: (objectMemory splObj: ClassAlien)) ifTrue:
			[self print: ' datasize '; printNum: (self sizeOfAlienData: oop).
			self print: ((self isIndirectAlien: oop)
							ifTrue: [' indirect @ ']
							ifFalse:
								[(self isPointerAlien: oop)
									ifTrue: [' pointer @ ']
									ifFalse: [' direct @ ']]).
			 self printHex: (self startOfAlienData: oop) asUnsignedInteger; cr.
			 ^nil].
		 (objectMemory isWords: oop) ifTrue:
			[lastIndex := 64 min: ((objectMemory byteSizeOf: oop) / BytesPerWord).
			 lastIndex > 0 ifTrue:
				[1 to: lastIndex do:
					[:index|
					self space; printHex: (objectMemory fetchLong32: index - 1 ofObject: oop).
					(index \\ self elementsPerPrintOopLine) = 0 ifTrue:
						[self cr]].
				(lastIndex \\ self elementsPerPrintOopLine) = 0 ifFalse:
					[self cr]].
			^nil].
		^self printStringOf: oop; cr].
	lastIndex := 64 min: (startIP := (objectMemory lastPointerOf: oop) / BytesPerWord).
	lastIndex > 0 ifTrue:
		[1 to: lastIndex do:
			[:index|
			self cCode: [self printHex: (objectMemory fetchPointer: index - 1 ofObject: oop); space]
				inSmalltalk: [self space; printHex: (objectMemory fetchPointer: index - 1 ofObject: oop); space.
							 self print: (self shortPrint: (objectMemory fetchPointer: index - 1 ofObject: oop))].
			(index \\ self elementsPerPrintOopLine) = 0 ifTrue:
				[self cr]].
		(lastIndex \\ self elementsPerPrintOopLine) = 0 ifFalse:
			[self cr]].
	(objectMemory isCompiledMethod: oop)
		ifFalse:
			[startIP > 64 ifTrue: [self print: '...'; cr]]
		ifTrue:
			[startIP := startIP * BytesPerWord + 1.
			 lastIndex := objectMemory lengthOf: oop.
			 lastIndex - startIP > 100 ifTrue:
				[lastIndex := startIP + 100].
			 bytecodesPerLine := 8.
			 column := 1.
			 startIP to: lastIndex do:
				[:index| | byte |
				column = 1 ifTrue:
					[self cCode: 'printf("0x%08x: ", oop+BaseHeaderSize+index-1)'
						inSmalltalk: [self print: (oop+BaseHeaderSize+index-1) hex; print: ': ']].
				byte := objectMemory fetchByte: index - 1 ofObject: oop.
				self cCode: 'printf(" %02x/%-3d", byte,byte)'
					inSmalltalk: [self space; print: (byte radix: 16); printChar: $/; printNum: byte].
				column := column + 1.
				column > bytecodesPerLine ifTrue:
					[column := 1. self cr]].
			column = 1 ifFalse:
				[self cr]]
]

{ #category : #'debug printing' }
StackInterpreter >> printOopShort: oop [
	<inline: false>
	self printOopShortInner: oop.
	self flush
]

{ #category : #'debug printing' }
StackInterpreter >> printOopShortInner: oop [
	| classOop name nameLen |
	<var: #name type: #'char *'>
	<inline: true>
	(objectMemory isIntegerObject: oop) ifTrue:
		[self printNum: (objectMemory integerValueOf: oop);
			printChar: $(;
			printHex: (objectMemory integerValueOf: oop);
			printChar: $).
		 ^nil].
	(oop between: objectMemory startOfMemory and: objectMemory freeStart) ifFalse:
		[self printHex: oop; print: ' is not on the heap'.
		 ^nil].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[self printHex: oop; print: ' is misaligned'.
		 ^nil].
	(self isFloatObject: oop) ifTrue:
		[self printFloat: (self dbgFloatValueOf: oop).
		 ^nil].
	classOop := objectMemory fetchClassOfNonInt: oop.
	(objectMemory addressCouldBeObj: classOop) ifFalse:
		[self print: 'a ??'. ^nil].
	(objectMemory sizeBitsOf: classOop) = metaclassSizeBits ifTrue:
		[self printNameOfClass: oop count: 5.
		 ^nil].
	oop = objectMemory nilObject ifTrue: [self print: 'nil'. ^nil].
	oop = objectMemory trueObject ifTrue: [self print: 'true'. ^nil].
	oop = objectMemory falseObject ifTrue: [self print: 'false'. ^nil].
	nameLen := self lengthOfNameOfClass: classOop.
	nameLen = 0 ifTrue: [self print: 'a ??'. ^nil].
	name := self nameOfClass: classOop.
	nameLen = 10 ifTrue:
		[(self str: name n: 'ByteString' cmp: 10) not "strncmp is weird" ifTrue:
			[self printChar: $'; printStringOf: oop; printChar: $'.
			 ^nil].
		 (self str: name n: 'ByteSymbol' cmp: 10) not "strncmp is weird" ifTrue:
			[self printChar: $#; printStringOf: oop.
			 ^nil]].
	(nameLen = 9 and: [(self str: name n: 'Character' cmp: 9) not]) ifTrue:
		[self printChar: $$; printChar: (objectMemory integerValueOf: (objectMemory fetchPointer: 0 ofObject: oop)).
		 ^nil].
	self cCode: [self prin: 'a(n) %.*s' t: nameLen f: name]
		inSmalltalk: [self print: 'a(n) '; print: name].
	"Try to spot association-like things; they're all subclasses of LookupKey"
	((objectMemory instanceSizeOf: classOop) = (ValueIndex + 1)
	 and: [(self superclassOf: classOop) = (self superclassOf: (objectMemory fetchClassOfNonInt: (objectMemory splObj: SchedulerAssociation)))
	 and: [objectMemory isBytes: (objectMemory fetchPointer: KeyIndex ofObject: oop)]]) ifTrue:
		[self space;
			printOopShort: (objectMemory fetchPointer: KeyIndex ofObject: oop);
			print: ' -> ';
			printHex: (objectMemory fetchPointer: ValueIndex ofObject: oop)]
]

{ #category : #'debug printing' }
StackInterpreter >> printPageHeadFrame [
	<inline: false>
	self printFrame: stackPage headFP WithSP: stackPage headSP
]

{ #category : #'debug printing' }
StackInterpreter >> printProcessStack: aProcess [
	<api>
	<inline: false>
	| ctx |
	self cr; printNameOfClass: (objectMemory fetchClassOf: aProcess) count: 5; space; printHex: aProcess.
	self print: ' priority '; printNum: (self quickFetchInteger: PriorityIndex ofObject: aProcess); cr.
	ctx := objectMemory fetchPointer: SuspendedContextIndex ofObject: aProcess.
	ctx = objectMemory nilObject ifFalse:
		[self printCallStackOf: ctx currentFP: framePointer]
]

{ #category : #'debug printing' }
StackInterpreter >> printProcsOnList: procList [
	<api>
	<inline: false>
	| proc firstProc |
	proc := firstProc := objectMemory fetchPointer: FirstLinkIndex ofObject: procList.
	[proc = objectMemory nilObject] whileFalse:
		[self printProcessStack: proc.
		 proc := objectMemory fetchPointer: NextLinkIndex ofObject: proc.
		 proc = firstProc ifTrue:
			[self warning: 'circular process list!!'.
			 ^nil]]
]

{ #category : #'debug printing' }
StackInterpreter >> printSends [
	^false
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
	self cr; tab; print: 'ba: ';
		printHexPtr: page baseAddress; print: ' - sl: ';
		printHexPtr: page realStackLimit; print: ' - sl-so: ';
		printHexPtr: page realStackLimit - self stackLimitOffset; print: ' - la:';
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
	| fmt len cnt max i |
	<inline: false>
	(objectMemory isIntegerObject: oop) ifTrue:
		[^nil].
	(oop between: objectMemory startOfMemory and: objectMemory freeStart) ifFalse:
		[^nil].
	(oop bitAnd: (BytesPerOop - 1)) ~= 0 ifTrue:
		[^nil].
	fmt := objectMemory formatOf: oop.
	fmt < 8 ifTrue: [^nil].

	cnt := (max := 128) min: (len := objectMemory lengthOf: oop).
	i := 0.

	((objectMemory is: oop
		  instanceOf: (objectMemory splObj: ClassByteArray)
		  compactClassIndex: classByteArrayCompactIndex)
	or: [(self isInstanceOfClassLargePositiveInteger: oop)
	or: [(self isInstanceOfClassLargeNegativeInteger: oop)]])
		ifTrue:
			[[i < cnt] whileTrue:
				[self printHex: (objectMemory fetchByte: i ofObject: oop).
				 i := i + 1]]
		ifFalse:
			[[i < cnt] whileTrue:
				[self printChar: (objectMemory fetchByte: i ofObject: oop).
				 i := i + 1]].
	len > max ifTrue:
		[self print: '...'].
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
	<inline: true>
	self push: (objectMemory booleanObjectOf: trueOrFalse)
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushClosureCopyCopiedValuesBytecode [
	"The compiler has pushed the values to be copied, if any.  Find numArgs and numCopied in the byte following.
	 Create a Closure with space for the copiedValues and pop numCopied values off the stack into the closure.
	 Set numArgs as specified, and set startpc to the pc following the block size and jump over that code."
	| numArgsNumCopied numArgs numCopied blockSize |
	numArgsNumCopied := self fetchByte.
	numArgs := numArgsNumCopied bitAnd: 16rF.
	numCopied := numArgsNumCopied bitShift: -4.
	"Split blockSize := (self fetchByte * 256) + self fetchByte. into two because evaluation order in C is undefined."
	blockSize := self fetchByte << 8.
	blockSize := blockSize + self fetchByte.
	self pushClosureNumArgs: numArgs copiedValues: numCopied blockSize: blockSize
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushClosureNumArgs: numArgs copiedValues: numCopied blockSize: blockSize [
	"The compiler has pushed the values to be copied, if any.
	 Create a Closure with space for the copiedValues and pop numCopied values off the stack into the closure.
	 Set numArgs as specified, and set startpc to the pc following the block size and jump over that code."
	<inline: true>
	| newClosure context |
	"No need to record the pushed copied values in the outerContext."
	context := self ensureFrameIsMarried: localFP SP: localSP + (numCopied * BytesPerOop).
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
			 objectMemory storePointerUnchecked: i + ClosureFirstCopiedValueIndex
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
	self internalPush: objectMemory falseObject.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantMinusOneBytecode [

	self fetchNextBytecode.
	self internalPush: ConstMinusOne.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantNilBytecode [

	self fetchNextBytecode.
	self internalPush: objectMemory nilObject.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantOneBytecode [

	self fetchNextBytecode.
	self internalPush: ConstOne.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantTrueBytecode [

	self fetchNextBytecode.
	self internalPush: objectMemory trueObject.

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
StackInterpreter >> pushExplicitOuterSendReceiverBytecode [
	"Find the appropriate implicit receiver for outer N"
	| litIndex  n anIntOop |
	<inline: true>
	litIndex := self fetchByte.
	anIntOop := self literal: litIndex.
	n := (objectMemory isIntegerObject: anIntOop)
			ifTrue: [objectMemory integerValueOf: anIntOop]
			ifFalse: [0].
	self fetchNextBytecode.
	self internalPush:(self 
						explicitOuterReceiver: n 
						withObject: self receiver 
						withMixin: (self methodClassOf: method))
]

{ #category : #'primitive support' }
StackInterpreter >> pushFloat: f [

	<var: #f type: #double>
	self push: (self floatObjectOf: f).
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushImplicitReceiverBytecode [
	"This bytecode is used to implement outer sends in NS2/NS3. The
	 bytecode takes as an argument the literal offset of a selector. It
	 effectively finds the nearest lexically-enclosing implementation of
	 that selector by searching up the static chain of the receiver,
	 starting at the current method."
	| selector |
	selector := self literal: self fetchByte.
	self fetchNextBytecode.
	self internalPush: (self
						implicitReceiverFor: self receiver
						mixin: (self methodClassOf: method)
						implementing: selector)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pushInteger: integerValue [
	self push: (objectMemory integerObjectOf: integerValue).
	^nil
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushLiteralConstant: literalIndex [

	self internalPush: (self literal: literalIndex).
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushLiteralConstantBytecode [
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
StackInterpreter >> pushLiteralVariable16CasesBytecode [
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self pushLiteralVariable: (currentBytecode bitAnd: 16rF)]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self pushLiteralVariable: (currentBytecode bitAnd: 16rF).
			 self fetchNextBytecode]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushLiteralVariable: literalIndex [

	self internalPush:
		(objectMemory fetchPointer: ValueIndex ofObject: (self literal: literalIndex)).
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushLiteralVariableBytecode [
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
	and: [objectMemory isContextNonInt: rcvr])
		ifTrue:
			[self internalPush: (self instVar: fieldIndex ofContext: rcvr)]
		ifFalse:
			[self internalPush: (objectMemory fetchPointer: fieldIndex ofObject: rcvr)]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushNewArrayBytecode [
	| size popValues array |
	size := self fetchByte.
	popValues := size > 127.
	size := size bitAnd: 127.
	self fetchNextBytecode.
	self externalizeIPandSP.
	array := objectMemory eeInstantiateClass: (objectMemory splObj: ClassArray) indexableSize: size.
	self internalizeIPandSP.
	popValues
		ifTrue:
			[0 to: size - 1 do:
				[:i|
				"Assume: have just allocated a new Array; it must be young. Thus, can use unchecked stores."
				objectMemory storePointerUnchecked: i ofObject: array withValue: (self internalStackValue: size - i - 1)].
			 self internalPop: size]
		ifFalse:
			[0 to: size - 1 do:
				[:i|
				objectMemory storePointerUnchecked: i ofObject: array withValue: objectMemory nilObject]].
	self internalPush: array
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushReceiverBytecode [

	self fetchNextBytecode.
	self internalPush: self receiver.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushReceiverVariable: fieldIndex [

	self internalPush: (objectMemory fetchPointer: fieldIndex ofObject: self receiver).
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushReceiverVariableBytecode [
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
StackInterpreter >> pushRemoteTemp: index inVectorAt: tempVectorIndex [
	| tempVector |
	tempVector := self temporary: tempVectorIndex in: localFP.
	self internalPush: (objectMemory fetchPointer: index ofObject: tempVector)
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
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self pushTemporaryVariable: (currentBytecode bitAnd: 16rF)]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self pushTemporaryVariable: (currentBytecode bitAnd: 16rF).
			 self fetchNextBytecode]
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
	self assert: (framePointer - stackPointer) < LargeContextSize.
	priority := self quickFetchInteger: PriorityIndex ofObject: aProcess.
	(highestRunnableProcessPriority ~= 0
	 and: [priority > highestRunnableProcessPriority]) ifTrue:
		[highestRunnableProcessPriority := priority].
	processLists := objectMemory fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	processList := objectMemory fetchPointer: priority - 1 ofObject: processLists.
	yieldImplicitly
		ifTrue: [self addLastLink: aProcess toList: processList]
		ifFalse: [self addFirstLink: aProcess toList: processList]
]

{ #category : #utilities }
StackInterpreter >> quickFetchInteger: fieldIndex ofObject: objectPointer [
	"Return the integer value of the field without verifying that it is an integer value! For use in time-critical places where the integer-ness of the field can be guaranteed."

	| oop |
	oop := objectMemory fetchPointer: fieldIndex ofObject: objectPointer.
	self assert: (objectMemory isIntegerObject: oop).
	^objectMemory integerValueOf: oop
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
	<var: #desiredHeapSize type: 'usqInt'>
	<var: #headerStart type: 'squeakFileOffsetType '>
	<var: #dataSize type: 'size_t '>
	<var: #imageOffset type: 'squeakFileOffsetType '>

	metaclassSizeBits := 6 * BytesPerWord.	"guess (Metaclass instSize * BPW)"
	swapBytes := self checkImageVersionFrom: f startingAt: imageOffset.
	headerStart := (self sqImageFilePosition: f) - BytesPerWord.  "record header start position"

	headerSize			:= self getLongFromFile: f swap: swapBytes.
	dataSize			:= self getLongFromFile: f swap: swapBytes.
	oldBaseAddr		:= self getLongFromFile: f swap: swapBytes.
	objectMemory specialObjectsOop: (self getLongFromFile: f swap: swapBytes).
	objectMemory lastHash: (self getLongFromFile: f swap: swapBytes). "N.B.  not used."
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
	objectMemory edenBytes: (desiredEdenBytes ~= 0
						ifTrue: [desiredEdenBytes]
						ifFalse:
							[hdrEdenBytes = 0
									ifTrue: [objectMemory defaultEdenBytes]
									ifFalse: [hdrEdenBytes]]).
	desiredEdenBytes := hdrEdenBytes.
	hdrMaxExtSemTabSize := self getShortFromFile: f swap: swapBytes.
	hdrMaxExtSemTabSize ~= 0 ifTrue:
		[self setMaxExtSemSizeTo: hdrMaxExtSemTabSize].
	"decrease Squeak object heap to leave extra memory for the VM"
	heapSize := self cCode: 'reserveExtraCHeapBytes(desiredHeapSize, extraVMMemory)'.

	"compare memory requirements with availability".
	minimumMemory := dataSize + objectMemory edenBytes + self interpreterAllocationReserveBytes.
	heapSize < minimumMemory ifTrue:
		[self insufficientMemorySpecifiedError].

	"allocate a contiguous block of memory for the Squeak heap"
	objectMemory memory: (self
								allocateMemory: heapSize
								minimum: minimumMemory
								imageFile: f
								headerSize: headerSize) asUnsignedInteger.
	objectMemory memory = nil ifTrue: [self insufficientMemoryAvailableError].

	memStart := objectMemory startOfMemory.
	objectMemory setMemoryLimit: (memStart + heapSize) - 24.  "decrease memoryLimit a tad for safety"
	objectMemory setEndOfMemory: memStart + dataSize.

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

{ #category : #'callback support' }
StackInterpreter >> reestablishContextPriorToCallback: callbackContext [
	"callbackContext is an activation of invokeCallback:[stack:registers:jmpbuf:].
	 Its sender is the VM's state prior to the callback.  Reestablish that state,
	 and mark calloutContext as dead."
	| calloutContext theFP thePage |
	<export: true>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	self flag: #obsolete.
	(self isLiveContext: callbackContext) ifFalse:
		[^false].
	calloutContext := self externalInstVar: SenderIndex ofContext: callbackContext.
	(self isLiveContext: calloutContext) ifFalse:
		[^false].
	"We're about to leave this stack page; must save the current frame's instructionPointer."
	self push: instructionPointer.
	self externalWriteBackHeadFramePointers.
	"Mark callbackContext as dead; the common case is that it is the current frame.
	 We go the extra mile for the debugger."
	(self isSingleContext: callbackContext)
		ifTrue: [self markContextAsDead: callbackContext]
		ifFalse:
			[theFP := self frameOfMarriedContext: callbackContext.
			 framePointer = theFP "common case"
				ifTrue:
					[(self isBaseFrame: theFP)
						ifTrue: [stackPages freeStackPage: stackPage]
						ifFalse: "calloutContext is immediately below on the same page.  Make it current."
							[instructionPointer := (self frameCallerSavedIP: framePointer) asUnsignedInteger.
							 stackPointer := framePointer + (self frameStackedReceiverOffset: framePointer) + BytesPerWord.
							 framePointer := self frameCallerFP: framePointer.
							 ^true]]
				ifFalse:
					[self externalDivorceFrame: theFP andContext: callbackContext.
					 self markContextAsDead: callbackContext]].
	"Make the calloutContext the active frame.  The case where calloutContext
	 is immediately below callbackContext on the same page is handled above."
	(self isStillMarriedContext: calloutContext)
		ifTrue:
			[theFP := self frameOfMarriedContext: calloutContext.
			 thePage := stackPages stackPageFor: theFP.
			 "findSPOf:on: points to the word beneath the instructionPointer, but
			  there is no instructionPointer on the top frame of the current page."
			 self assert: thePage ~= stackPage.
			 stackPointer := (self findSPOf: theFP on: thePage) - BytesPerWord.
			 framePointer := theFP]
		ifFalse:
			[thePage := self makeBaseFrameFor: calloutContext.
			 framePointer := thePage headFP.
			 stackPointer := thePage headSP].
	instructionPointer := self popStack.
	self setStackPageAndLimit: thePage.
	^true
]

{ #category : #'process primitive support' }
StackInterpreter >> removeFirstLinkOfList: aList [ 
	"Remove the first process from the given linked list."
	| first last next |
	first := objectMemory fetchPointer: FirstLinkIndex ofObject: aList.
	last := objectMemory fetchPointer: LastLinkIndex ofObject: aList.
	first = last
		ifTrue: [objectMemory storePointer: FirstLinkIndex ofObject: aList withValue: objectMemory nilObject.
			objectMemory storePointer: LastLinkIndex ofObject: aList withValue: objectMemory nilObject]
		ifFalse: [next := objectMemory fetchPointer: NextLinkIndex ofObject: first.
			objectMemory storePointer: FirstLinkIndex ofObject: aList withValue: next].
	objectMemory storePointer: NextLinkIndex ofObject: first withValue: objectMemory nilObject.
	^ first
]

{ #category : #'process primitive support' }
StackInterpreter >> removeProcess: aProcess fromList: aList [ 
	"Remove a given process from a linked list. May fail if aProcess is not on the list."
	| firstLink lastLink nextLink tempLink |
	firstLink := objectMemory fetchPointer: FirstLinkIndex ofObject: aList.
	lastLink := objectMemory fetchPointer: LastLinkIndex ofObject: aList.
	aProcess  = firstLink ifTrue:[
		nextLink := objectMemory fetchPointer: NextLinkIndex ofObject: aProcess .
		objectMemory storePointer: FirstLinkIndex ofObject: aList withValue: nextLink.
		aProcess  = lastLink ifTrue:[
			objectMemory storePointer: LastLinkIndex ofObject: aList withValue: objectMemory nilObject.
		].
	] ifFalse:[
		tempLink := firstLink.
		[tempLink = objectMemory nilObject ifTrue:[^self success: false]. "fail"
		nextLink := objectMemory fetchPointer: NextLinkIndex ofObject: tempLink.
		nextLink = aProcess] whileFalse:[
			tempLink := objectMemory fetchPointer: NextLinkIndex ofObject: tempLink.
		].
		nextLink := objectMemory fetchPointer: NextLinkIndex ofObject: aProcess.
		objectMemory storePointer: NextLinkIndex ofObject: tempLink withValue: nextLink.
		aProcess  = lastLink ifTrue:[
			objectMemory storePointer: LastLinkIndex ofObject: aList withValue: tempLink.
		].
	].
	objectMemory storePointer: NextLinkIndex ofObject: aProcess withValue: objectMemory nilObject
]

{ #category : #'miscellaneous bytecodes' }
StackInterpreter >> respondToUnknownBytecode [
	"If an error selector is available then send it to the activeContext, otherwise abort."
	<sharedCodeNamed: #respondToUnknownBytecode inCase: #unknownBytecode>
	| unknownBytecodeSelector ourContext |
	unknownBytecodeSelector := objectMemory maybeSplObj: SelectorUnknownBytecode.
	unknownBytecodeSelector isNil ifTrue:
		[self error: 'Unknown bytecode'].
	ourContext := self ensureFrameIsMarried: localFP SP: localSP.
	"N.B. Do Not:
	self fetchNextBytecode."
	self internalPush: ourContext.
	messageSelector := unknownBytecodeSelector.
	argumentCount := 0.
	self commonSend
]

{ #category : #'callback support' }
StackInterpreter >> restoreCStackStateForCallbackContext: vmCallbackContext [
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
	"this is a no-op for the Stack VM"
]

{ #category : #'stack pages' }
StackInterpreter >> restoreStackLimit [
	"restore the stackLimit if it has been smashed."
	<inline: true>
	stackPage stackLimit: stackPage realStackLimit.
	stackLimit := stackPage stackLimit
]

{ #category : #'process primitive support' }
StackInterpreter >> resume: aProcess [
	"Replaced by resume:preemptedYieldingIf:"
	"Make aProcess runnable and if its priority is higher than
	 that of the current process, preempt the current process.
	 Answer if the current process was preempted.  Override
	 to add tracing info (see resume:from:)."
	<doNotGenerate>
	self shouldNotImplement
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

{ #category : #'callback support' }
StackInterpreter >> returnAs: returnTypeOop ThroughCallback: vmCallbackContext Context: callbackMethodContext [
	"callbackMethodContext is an activation of invokeCallback:[stack:registers:jmpbuf:].
	 Its sender is the VM's state prior to the callback.  Reestablish that state (via longjmp),
	 and mark callbackMethodContext as dead."
	<export: true>
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
	| calloutMethodContext theFP thePage |
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	((self isIntegerObject: returnTypeOop)
	 and: [self isLiveContext: callbackMethodContext]) ifFalse:
		[^false].
	calloutMethodContext := self externalInstVar: SenderIndex ofContext: callbackMethodContext.
	(self isLiveContext: calloutMethodContext) ifFalse:
		[^false].
	"We're about to leave this stack page; must save the current frame's instructionPointer."
	self push: instructionPointer.
	self externalWriteBackHeadFramePointers.
	"Mark callbackMethodContext as dead; the common case is that it is the current frame.
	 We go the extra mile for the debugger."
	(self isSingleContext: callbackMethodContext)
		ifTrue: [self markContextAsDead: callbackMethodContext]
		ifFalse:
			[theFP := self frameOfMarriedContext: callbackMethodContext.
			 framePointer = theFP "common case"
				ifTrue:
					[(self isBaseFrame: theFP)
						ifTrue: [stackPages freeStackPage: stackPage]
						ifFalse: "calloutMethodContext is immediately below on the same page.  Make it current."
							[instructionPointer := (self frameCallerSavedIP: framePointer) asUnsignedInteger.
							 stackPointer := framePointer + (self frameStackedReceiverOffset: framePointer) + BytesPerWord.
							 framePointer := self frameCallerFP: framePointer.
							 self restoreCStackStateForCallbackContext: vmCallbackContext.
							 "N.B. siglongjmp is defines as _longjmp on non-win32 platforms.
							  This matches the use of _setjmp in ia32abicc.c."
							 self siglong: vmCallbackContext trampoline jmp: (self integerValueOf: returnTypeOop).
							 ^true]]
				ifFalse:
					[self externalDivorceFrame: theFP andContext: callbackMethodContext.
					 self markContextAsDead: callbackMethodContext]].
	"Make the calloutMethodContext the active frame.  The case where calloutMethodContext
	 is immediately below callbackMethodContext on the same page is handled above."
	(self isStillMarriedContext: calloutMethodContext)
		ifTrue:
			[theFP := self frameOfMarriedContext: calloutMethodContext.
			 thePage := stackPages stackPageFor: theFP.
			 "findSPOf:on: points to the word beneath the instructionPointer, but
			  there is no instructionPointer on the top frame of the current page."
			 self assert: thePage ~= stackPage.
			 stackPointer := (self findSPOf: theFP on: thePage) - BytesPerWord.
			 framePointer := theFP]
		ifFalse:
			[thePage := self makeBaseFrameFor: calloutMethodContext.
			 framePointer := thePage headFP.
			 stackPointer := thePage headSP].
	instructionPointer := self popStack.
	self setStackPageAndLimit: thePage.
	self restoreCStackStateForCallbackContext: vmCallbackContext.
	 "N.B. siglongjmp is defines as _longjmp on non-win32 platforms.
	  This matches the use of _setjmp in ia32abicc.c."
	self siglong: vmCallbackContext trampoline jmp: (self integerValueOf: returnTypeOop).
	"NOTREACHED"
	^true
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnFalse [
	localReturnValue := objectMemory falseObject.
	self commonReturn
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnNil [
	localReturnValue := objectMemory nilObject.
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
	localReturnValue := objectMemory trueObject.
	self commonReturn
]

{ #category : #'image save/restore' }
StackInterpreter >> reverseBytesInImage [
	"Byte-swap all words in memory after reading in the entire image file with bulk read. Contributed by Tim Rowledge."

	"First, byte-swap every word in the image. This fixes objects headers."
	objectMemory reverseBytesFrom: objectMemory startOfMemory to: objectMemory freeStart.

	"Second, return the bytes of bytes-type objects to their orginal order, and perform any
	 other format conversions."
	self updateObjectsPostByteSwapFrom: objectMemory firstObject to: objectMemory freeStart
]

{ #category : #'I/O primitive support' }
StackInterpreter >> reverseDisplayFrom: startIndex to: endIndex [ 
	"Reverse the given range of Display words (at different bit 
	depths, this will reverse different numbers of pixels). Used to 
	give feedback during VM activities such as garbage 
	collection when debugging. It is assumed that the given 
	word range falls entirely within the first line of the Display."
	| displayObj displayBits w wordStartIndex wordEndIndex primFailCodeValue |
	displayObj := objectMemory splObj: TheDisplay.
	((objectMemory isPointers: displayObj) and: [(objectMemory lengthOf: displayObj) >= 4]) ifFalse: [^ nil].
	w := objectMemory fetchPointer: 1 ofObject: displayObj.
	displayBits := objectMemory fetchPointer: 0 ofObject: displayObj.
	((objectMemory isIntegerObject: displayBits)
	or: [(objectMemory isNonIntegerObject: w)
	or: [objectMemory isPointersNonInt: displayBits]]) ifTrue: [^ nil].
	wordStartIndex := startIndex * 4.
	wordEndIndex := endIndex * 4 min: (objectMemory sizeBitsOf: displayBits).
	displayBits := displayBits + BaseHeaderSize.
	displayBits + wordStartIndex to: displayBits + wordEndIndex by: 4 do:
		[:ptr | | reversed  |
		reversed := (objectMemory long32At: ptr) bitXor: 4294967295.
		objectMemory longAt: ptr put: reversed].
	primFailCodeValue := primFailCode.
	self initPrimCall.
	self displayBitsOf: displayObj Left: 0 Top: 0 Right: (objectMemory integerValueOf: w) Bottom: 1.
	self ioForceDisplayUpdate.
	primFailCode := primFailCodeValue
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

{ #category : #'callback support' }
StackInterpreter >> saveCStackStateForCallbackContext: vmCallbackContext [
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
	"this is a no-op for the Stack VM"
]

{ #category : #'process primitive support' }
StackInterpreter >> schedulerPointer [

	^ objectMemory fetchPointer: ValueIndex ofObject: (objectMemory splObj: SchedulerAssociation)
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

{ #category : #'debug printing' }
StackInterpreter >> selectorOfContext: aContext [
	(self isContext: aContext) ifFalse:
		[^nil].
	^self
		findSelectorOfMethod: (objectMemory fetchPointer: MethodIndex ofObject: aContext)
		forReceiver:  (objectMemory fetchPointer: ReceiverIndex ofObject: aContext)
]

{ #category : #'send bytecodes' }
StackInterpreter >> sendAbsentImplicit0ArgsBytecode [
	"160-175	1010 i i i i		Send To Absent Implicit Receiver Literal Selector #iiii With 0 Arguments"
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := 0.
	self commonSendAbsentImplicit
]

{ #category : #'callback support' }
StackInterpreter >> sendInvokeCallback: thunkPtr Stack: stackPtr Registers: regsPtr Jmpbuf: jmpBufPtr [
	"Send the 4 argument callback message invokeCallback:stack:registers:jmpbuf:
	 to Alien class with the supplied args.  The arguments are raw C addresses
	 and are converted to integer objects on the way."
	<export: true>
	self flag: #obsolete.
	lkupClass := self fetchClassOfNonInt: (self splObj: ClassAlien).
	messageSelector := self splObj: SelectorInvokeCallback.
	argumentCount := 4.
	(self lookupInMethodCacheSel: messageSelector class: lkupClass) ifFalse:
	 	[(self lookupMethodNoMNUEtcInClass: lkupClass) ~= 0 ifTrue:
			[^false]].
	((self argumentCountOf: newMethod) = 4
	and: [primitiveFunctionPointer = 0]) ifFalse:
		[^false].
	self push: (self splObj: ClassAlien). "receiver"
	self push: (self positive32BitIntegerFor: thunkPtr).
	self push: (self positive32BitIntegerFor: stackPtr).
	self push: (self positive32BitIntegerFor: regsPtr).
	self push: (self positive32BitIntegerFor: jmpBufPtr).
	self ifAppropriateCompileToNativeCode: newMethod selector: messageSelector.
	self justActivateNewMethod.
	(self isMachineCodeFrame: framePointer) ifFalse:
		[self maybeFlagMethodAsInterpreted: newMethod].
	self externalWriteBackHeadFramePointers.
	self handleStackOverflow.
	self enterSmalltalkExecutiveFromCallback.
	"not reached"
	^true
]

{ #category : #'callback support' }
StackInterpreter >> sendInvokeCallbackContext: vmCallbackContext [
	"Send the calllback message to Alien class with the supplied arg(s).  Use either the
	 1 arg invokeCallbackContext: or the 4 arg invokeCallback:stack:registers:jmpbuf:
	 message, depending on what selector is installed in the specialObjectsArray.
	 Note that if invoking the legacy invokeCallback:stack:registers:jmpbuf: we pass the
	 vmCallbackContext as the jmpbuf argument (see reestablishContextPriorToCallback:).
	 The arguments are raw C addresses and are converted to integer objects on the way."
	<export: true>
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
	lkupClass := self fetchClassOfNonInt: (self splObj: ClassAlien).
	messageSelector := self splObj: SelectorInvokeCallback.
	(self lookupInMethodCacheSel: messageSelector class: lkupClass) ifFalse:
	 	[(self lookupMethodNoMNUEtcInClass: lkupClass) ~= 0 ifTrue:
			[^false]].
	primitiveFunctionPointer ~= 0 ifTrue:
		[^false].
	self saveCStackStateForCallbackContext: vmCallbackContext.
	self push: (self splObj: ClassAlien). "receiver"
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
	self ifAppropriateCompileToNativeCode: newMethod selector: messageSelector.
	self justActivateNewMethod.
	(self isMachineCodeFrame: framePointer) ifFalse:
		[self maybeFlagMethodAsInterpreted: newMethod].
	self externalWriteBackHeadFramePointers.
	self handleStackOverflow.
	self enterSmalltalkExecutiveFromCallback.
	"not reached"
	^true
]

{ #category : #'send bytecodes' }
StackInterpreter >> sendLiteralSelector0ArgsBytecode [
	"Can use any of the first 16 literals for the selector."
	| rcvr |
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := 0.
	rcvr := self internalStackValue: 0.
	lkupClass := objectMemory fetchClassOf: rcvr.
	self assert: lkupClass ~= objectMemory nilObject.
	self commonSend
]

{ #category : #'send bytecodes' }
StackInterpreter >> sendLiteralSelector1ArgBytecode [
	"Can use any of the first 16 literals for the selector."
	| rcvr |
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := 1.
	rcvr := self internalStackValue: 1.
	lkupClass := objectMemory fetchClassOf: rcvr.
	self assert: lkupClass ~= objectMemory nilObject.
	self commonSend
]

{ #category : #'send bytecodes' }
StackInterpreter >> sendLiteralSelector2ArgsBytecode [
	"Can use any of the first 16 literals for the selector."
	| rcvr |
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := 2.
	rcvr := self internalStackValue: 2.
	lkupClass := objectMemory fetchClassOf: rcvr.
	self assert: lkupClass ~= objectMemory nilObject.
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

{ #category : #'frame access' }
StackInterpreter >> setFrameContext: theFP to: aContext [
	<inline: true>
	<var: #theFP type: #'char *'>
	stackPages longAt: theFP + FoxThisContext put: aContext
]

{ #category : #'frame access' }
StackInterpreter >> setFrameHasContext: theFP [
	"See encodeFrameFieldHasContext:numArgs:"
	<inline: true>
	<var: #theFP type: #'char *'>
	stackPages byteAt: theFP + FoxFrameFlags + 2 put: 1
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
	"Set the method and determine the bytecode set based on the method header's sign.
	 If MULTIPLEBYTECODESETS then a negative header selects the alternate bytecode set.
	 Conditionalizing the code on MULTIPLEBYTECODESETS allows the header sign bit to be
	 used for other experiments."
	<inline: true>
	method := aMethodObj.
	self assert: (objectMemory isOopCompiledMethod: method).
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [bytecodeSetSelector := (self methodUsesAlternateBytecodeSet: method)
											ifTrue: [256]
											ifFalse: [0]]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> setMethod: aMethodObj methodHeader: methodHeader [
	"Set the method and determine the bytecode set based on the method header's sign.
	 If MULTIPLEBYTECODESETS then a negative header selects the alternate bytecode set.
	 Conditionalizing the code on MULTIPLEBYTECODESETS allows the header sign bit to be
	 used for other experiments."
	<inline: true>
	method := aMethodObj.
	self assert: (objectMemory isOopCompiledMethod: method).
	self assert: (self headerOf: method) = methodHeader.
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [bytecodeSetSelector := (self headerIndicatesAlternateBytecodeSet: methodHeader)
											ifTrue: [256]
											ifFalse: [0]]
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
	objectMemory signalLowSpace: true.
	objectMemory lowSpaceThreshold: 0. "disable additional interrupts until lowSpaceThreshold is reset by image"
	lastSavedProcess := objectMemory splObj: ProcessSignalingLowSpace.
	lastSavedProcess = objectMemory nilObject ifTrue:
		[activeProc := self activeProcess.
		objectMemory splObj: ProcessSignalingLowSpace put: activeProc].
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
StackInterpreter >> shortConditionalJumpFalse [

	self jumplfFalseBy: (currentBytecode bitAnd: 7) + 1
]

{ #category : #'jump bytecodes' }
StackInterpreter >> shortConditionalJumpTrue [

	self jumplfTrueBy: (currentBytecode bitAnd: 7) + 1
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintContext: aContext [
	| theFP |
	<inline: false>
	<var: #theFP type: #'char *'>
	(self isContext: aContext) ifFalse:
		[self printHex: aContext; print: ' is not a context'; cr.
		^nil].
	self printHex: aContext.
	(self isMarriedOrWidowedContext: aContext)
		ifTrue: [(self checkIsStillMarriedContext: aContext currentFP: framePointer)
					ifTrue:
						[(self isMachineCodeFrame: (theFP := self frameOfMarriedContext: aContext))
							ifTrue: [self print: ' M (']
							ifFalse: [self print: ' I ('].
						 self printHex: theFP asUnsignedInteger; print: ') ']
					ifFalse:
						[self print: ' w ']]
		ifFalse: [self print: ' s '].
	(self findHomeForContext: aContext)
		ifNil: [self print: ' BOGUS CONTEXT (can''t determine home)']
		ifNotNil:
			[:home|
			self printActivationNameFor: (objectMemory fetchPointer: MethodIndex ofObject: aContext)
		receiver: (home isNil
					ifTrue: [objectMemory nilObject]
					ifFalse: [objectMemory fetchPointer: ReceiverIndex ofObject: home])
		isBlock: home ~= aContext
		firstTemporary: (objectMemory fetchPointer: 0 + CtxtTempFrameStart ofObject: home)].
	self cr
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintFrame: theFP [
	<inline: false>
	<var: #theFP type: #'char *'>
	| rcvr |
	(stackPages couldBeFramePointer: theFP) ifFalse:
		[self print: 'invalid frame pointer'; cr.
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
StackInterpreter >> shortPrintFrame: theFP AndNCallers: n [
	<api>
	<inline: false>
	<var: #theFP type: #'char *'>
	(n ~= 0 and: [stackPages couldBeFramePointer: theFP]) ifTrue:
		[self shortPrintFrame: theFP.
		 self shortPrintFrame: (self frameCallerFP: theFP) AndNCallers: n - 1]
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintFrameAndCallers: theFP [
	<inline: false>
	<var: #theFP type: #'char *'>
	(stackPages couldBeFramePointer: theFP) ifFalse: [^nil].
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
	<export: true> "use export: not api, so it won't be written to cointerp.h. cogit.c is unaware of StackPage"
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	self printFrameAndCallers: thePage headFP SP: thePage headSP short: true
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintOop: oop [
	<inline: false>
	self printHex: oop.
	(objectMemory isIntegerObject: oop) ifTrue:
		[^self cCode: 'printf("=%ld\n", (long)integerValueOf(oop))' inSmalltalk: [self print: (self shortPrint: oop); cr]].
	(oop between: objectMemory startOfMemory and: objectMemory freeStart) ifFalse:
		[self printHex: oop; print: ' is not on the heap'; cr.
		 ^nil].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[self printHex: oop; print: ' is misaligned'; cr.
		 ^nil].
	self print: ': a(n) '.
	self printNameOfClass: (objectMemory fetchClassOf: oop) count: 5.
	self cr
]

{ #category : #'debug printing' }
StackInterpreter >> shortReversePrintFrameAndCallers: aFramePointer [
	| theFP callerFP |
	<inline: false>
	<var: #aFramePointer type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	aFramePointer = 0 ifTrue:
		[^objectMemory nilObject].
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

{ #category : #'send bytecodes' }
StackInterpreter >> shuffleArgumentsAndStoreAbsentReceiver: theReceiver [
	"For the absent receiver sends move the arguments up the stack and store the supplied receiver."
	<inline: true>
	localSP := localSP - BytesPerOop. "a.k.a. self internalPush: anything"
	1 to: argumentCount do:
		[:i| | oop |
		oop := self internalStackValue: i.
		self internalStackValue: i - 1 put: oop].
	self internalStackValue: argumentCount put: theReceiver
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
	xArray := objectMemory splObj: ExternalObjectsArray.
	^self doSignalExternalSemaphores: (self stSizeOf: xArray)
]

{ #category : #'process primitive support' }
StackInterpreter >> signalFinalization: weakReferenceOop [
	"Record the fact that there is at least one object to finalize
	 and cause the VM to check for interrupts at the earliest
	 opportunity. The finalization semaphore will actually be
	 signalled once in checkForEventsMayContextSwitch:"

	self forceInterruptCheck.
	pendingFinalizationSignals := pendingFinalizationSignals + 1
]

{ #category : #'primitive support' }
StackInterpreter >> signed32BitIntegerFor: integerValue [
	"Return a full 32 bit integer object for the given integer value"
	| newLargeInteger value largeClass |
	<inline: false>
	(objectMemory isIntegerValue: integerValue)
		ifTrue: [^ objectMemory integerObjectOf: integerValue].
	integerValue < 0
		ifTrue:[	largeClass := objectMemory classLargeNegativeInteger.
				value := 0 - integerValue]
		ifFalse:[	largeClass := objectMemory classLargePositiveInteger.
				value := integerValue].
	newLargeInteger := objectMemory eeInstantiateClass: largeClass indexableSize: 4.
	objectMemory storeByte: 3 ofObject: newLargeInteger withValue: ((value >> 24) bitAnd: 16rFF).
	objectMemory storeByte: 2 ofObject: newLargeInteger withValue: ((value >> 16) bitAnd: 16rFF).
	objectMemory storeByte: 1 ofObject: newLargeInteger withValue: ((value >> 8) bitAnd: 16rFF).
	objectMemory storeByte: 0 ofObject: newLargeInteger withValue: (value bitAnd: 16rFF).
	^newLargeInteger
]

{ #category : #'primitive support' }
StackInterpreter >> signed64BitIntegerFor: integerValue [
	"Return a Large Integer object for the given integer value"
	| newLargeInteger magnitude largeClass intValue highWord sz |
	<inline: false>
	<var: 'integerValue' type: #sqLong>
	<var: 'magnitude' type: #sqLong>
	<var: 'highWord' type: #usqInt>

	integerValue < 0
		ifTrue:[	largeClass := objectMemory classLargeNegativeInteger.
				magnitude := 0 - integerValue]
		ifFalse:[	largeClass := objectMemory classLargePositiveInteger.
				magnitude := integerValue].

	"Make sure to handle the most -ve value correctly. 0 - most -ve = most -ve and most -ve - 1
	 is +ve.  Alas the simple (negative or: [integerValue - 1 < 0]) fails with contemporary gcc and icc
	 versions with optimization and sometimes without.  The shift works on all, touch wood."
	(magnitude <= 16r7FFFFFFF
	 and: [integerValue >= 0
		  or: [0 ~= (self cCode: [integerValue << 1]
						inSmalltalk: [integerValue << 1 bitAnd: (1 << 64) - 1])]]) ifTrue:
			[^self signed32BitIntegerFor: integerValue].

	highWord := magnitude >> 32.
	highWord = 0 
		ifTrue:[sz := 4] 
		ifFalse:
			[sz := 5.
			(highWord := highWord >> 8) = 0 ifFalse:[sz := sz + 1].
			(highWord := highWord >> 8) = 0 ifFalse:[sz := sz + 1].
			(highWord := highWord >> 8) = 0 ifFalse:[sz := sz + 1]].
	newLargeInteger := objectMemory instantiateClass: largeClass indexableSize:  sz.
	0 to: sz-1 do: [:i |
		intValue := (magnitude >> (i * 8)) bitAnd: 255.
		objectMemory storeByte: i ofObject: newLargeInteger withValue: intValue].
	^newLargeInteger
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

{ #category : #'compiled methods' }
StackInterpreter >> sizeOfCallPrimitiveBytecode: methodHeader [
	"Answer if the method starts with a long store temp bytecode, which indicates it has a primitive error code."
	"249		11111001	i i i i i i i i	jjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjjj * 256)"
	<api>
	<inline: true>
	^self
		cppIf: MULTIPLEBYTECODESETS
		ifTrue: [(self headerIndicatesAlternateBytecodeSet: methodHeader)
					ifTrue: [3]
					ifFalse: [0]]
		ifFalse: [0]
]

{ #category : #'compiled methods' }
StackInterpreter >> sizeOfLongStoreTempBytecode: methodHeader [
	"234		11101010	i i i i i i i i	Store Temporary Variable #iiiiiiii"
	"129 		10000001 jjkkkkkk 	Store (Receiver Variable, Temporary Location, Illegal, Literal Variable) [jj] #kkkkkk"
	<api>
	^2
]

{ #category : #utilities }
StackInterpreter >> sizeOfSTArrayFromCPrimitive: cPtr [
	"Return the number of indexable fields of the given object. This method is to be called from an automatically generated C primitive. The argument is assumed to be a pointer to the first indexable field of a words or bytes object; the object header starts 4 bytes before that."
	"Note: Only called by translated primitive code."

	| oop |
	<var: #cPtr type: 'void *'>
	oop := (self oopForPointer: cPtr) - BaseHeaderSize.
	(objectMemory isWordsOrBytes: oop) ifFalse: [
		self primitiveFail.
		^0].
	^objectMemory lengthOf: oop

]

{ #category : #'primitive support' }
StackInterpreter >> slowPrimitiveResponse [
	"Invoke a normal (non-quick) primitive.
	 Called under the assumption that primFunctionPtr has been preloaded"
	| nArgs savedFramePointer savedStackPointer |
	<inline: true>
	<asmLabel: false>
	<var: #savedFramePointer type: #'char *'>
	<var: #savedStackPointer type: #'char *'>
	FailImbalancedPrimitives ifTrue:
		[nArgs := argumentCount.
		 savedStackPointer := stackPointer.
		 savedFramePointer := framePointer].
	self initPrimCall.
	self dispatchFunctionPointer: primitiveFunctionPointer.
	(FailImbalancedPrimitives
	and: [self successful
	and: [framePointer = savedFramePointer]]) ifTrue:"Don't fail if primitive has done something radical, e.g. perform:"
		[stackPointer ~= (savedStackPointer + (nArgs * BytesPerWord)) ifTrue:
			[self flag: 'Would be nice to make this a message send of e.g. unbalancedPrimitive to the current process or context'.
			 "This is necessary but insufficient; the result may still have been written to the stack.
			   At least we'll know something is wrong."
			 stackPointer := savedStackPointer.
			 self failUnbalancedPrimitive]].
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

	"For nowe the stack munging below doesn't deal with more than omne argument.
	 It can, and should."
	argumentCount ~= 0 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].

	"Need to convert all frames into contexts since the snapshot file only holds objects."
	self push: instructionPointer.
	activeContext := self voidVMStateForSnapshot.

	"update state of active process"
	activeProc := self activeProcess.
	objectMemory
		storePointer: SuspendedContextIndex
		ofObject: activeProc
		withValue: activeContext.

	objectMemory pushRemappableOop: activeContext.

	"compact memory and compute the size of the memory actually in use"
	objectMemory incrementalGC.

	"maximimize space for forwarding table"
	objectMemory fullGC.
	self snapshotCleanUp.

	"Nothing moves from here on so it is safe to grab the activeContext again."
	activeContext := objectMemory popRemappableOop.

	dataSize := objectMemory freeStart - objectMemory startOfMemory. "Assume all objects are below the start of the free block"
	self successful ifTrue:
		["Without contexts or stacks simulate
			rcvr := self popStack.
			''pop rcvr''
			self push: trueObj.
		  to arrange that the snapshot resumes with true.  N.B. stackIndex is one-relative."
		stackIndex := self quickFetchInteger: StackPointerIndex ofObject: activeContext.
		rcvr := objectMemory fetchPointer: stackIndex + CtxtTempFrameStart - 1 ofObject: activeContext.
		objectMemory
			storePointerUnchecked: stackIndex + CtxtTempFrameStart - 1
			ofObject: activeContext
			withValue: objectMemory trueObject.
		"now attempt to write the snapshot file"
		self writeImageFileIO: dataSize.
		(self successful and: [embedded not]) ifTrue:
			["set Mac file type and creator; this is a noop on other platforms"
			setMacType := self ioLoadFunction: 'setMacFileTypeAndCreator' From: 'FilePlugin'.
			setMacType = 0 ifFalse:
				[self cCode: '((sqInt (*)(char *, char *, char *))setMacType)(imageName, "STim", "FAST")']].
		"Without contexts or stacks simulate
			self pop: 1"
		objectMemory
			storePointerUnchecked: StackPointerIndex
			ofObject: activeContext
			withValue: (objectMemory integerObjectOf: stackIndex - 1)].

	self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
	self successful
		ifTrue: [self push: objectMemory falseObject]
		ifFalse:
			[self push: rcvr.
			 self justActivateNewMethod]
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
	oop := objectMemory firstObject.
	[self oop: oop isLessThan: objectMemory freeStart] whileTrue:
		[(objectMemory isFreeObject: oop) ifFalse:
			[header := self longAt: oop.
			 fmt := objectMemory formatOfHeader: header.
			 "Clean out context"
			 (fmt = 3 and: [objectMemory isContextHeader: header]) ifTrue:
				["All contexts have been divorced. Bereave remaining widows."
				 (self isMarriedOrWidowedContext: oop) ifTrue:
					[self markContextAsDead: oop].
				 sz := objectMemory sizeBitsOf: oop.
				 (objectMemory lastPointerOf: oop) + BytesPerWord
				 to: sz - BaseHeaderSize by: BytesPerWord
				 do: [:i | self longAt: oop + i put: objectMemory nilObject]].
			 "Clean out external functions"
			 fmt >= 12 ifTrue:
				["This is a compiled method"
				 (self primitiveIndexOf: oop) = PrimitiveExternalCallIndex ifTrue:
					["Its primitiveExternalCall"
					 self flushExternalPrimitiveOf: oop]]].
			oop := objectMemory objectAfter: oop].
	objectMemory clearRootsTable
]

{ #category : #'debug printing' }
StackInterpreter >> space [
	<inline: true>
	self printChar: $ 
]

{ #category : #'message sending' }
StackInterpreter >> specialSelector: index [

	^ objectMemory fetchPointer: (index * 2) ofObject: (objectMemory splObj: SpecialSelectors)
]

{ #category : #'message sending' }
StackInterpreter >> specialSelectorNumArgs: index [
	^objectMemory integerValueOf: (objectMemory fetchPointer: (index * 2) + 1 ofObject: (objectMemory splObj: SpecialSelectors))
]

{ #category : #'indexing primitive support' }
StackInterpreter >> stObject: array at: index [
	"Return what ST would return for <obj> at: index."

	| hdr fmt totalLength fixedFields stSize |
	<inline: false>
	hdr := objectMemory baseHeader: array.
	fmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: array baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: array format: fmt length: totalLength.
	(fmt = 3 and: [objectMemory isContextHeader: hdr])
		ifTrue:
			[stSize := self stackPointerForMaybeMarriedContext: array.
			((self oop: index isGreaterThanOrEqualTo: 1)
			 and: [(self oop: index isLessThanOrEqualTo: stSize)
			 and: [self isStillMarriedContext: array]]) ifTrue:
				[^self noInlineTemporary: index - 1 in: (self frameOfMarriedContext: array)]]
		ifFalse: [stSize := totalLength - fixedFields].
	((self oop: index isGreaterThanOrEqualTo: (objectMemory firstValidIndexOfIndexableObject: array withFormat: fmt))
	 and: [self oop: index isLessThanOrEqualTo: stSize]) ifTrue:
		[^self subscript: array with: (index + fixedFields) format: fmt].
	self primitiveFailFor: (fmt <= 1 ifTrue: [PrimErrBadReceiver] ifFalse: [PrimErrBadIndex]).
	^0
]

{ #category : #'indexing primitive support' }
StackInterpreter >> stObject: array at: index put: value [
	"Do what ST would return for <obj> at: index put: value."
	| hdr fmt totalLength fixedFields stSize |
	<inline: false>
	hdr := objectMemory baseHeader: array.
	fmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: array baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: array format: fmt length: totalLength.
	(fmt = 3
	 and: [objectMemory isContextHeader: hdr])
		ifTrue:
			[stSize := self stackPointerForMaybeMarriedContext: array.
			((self oop: index isGreaterThanOrEqualTo: 1)
			 and: [(self oop: index isLessThanOrEqualTo: stSize)
			 and: [self isStillMarriedContext: array]]) ifTrue:
				[^self noInlineTemporary: index - 1 in: (self frameOfMarriedContext: array) put: value]]
		ifFalse: [stSize := totalLength - fixedFields].
	((self oop: index isGreaterThanOrEqualTo: (objectMemory firstValidIndexOfIndexableObject: array withFormat: fmt))
	 and: [self oop: index isLessThanOrEqualTo: stSize])
		ifTrue: [self subscript: array with: (index + fixedFields) storing: value format: fmt]
		ifFalse: [self primitiveFailFor: (fmt <= 1 ifTrue: [PrimErrBadReceiver] ifFalse: [PrimErrBadIndex])].
	^value
]

{ #category : #'indexing primitive support' }
StackInterpreter >> stSizeOf: oop [
	"Return the number of indexable fields in the given object. (i.e., what Smalltalk would return for <obj> size)."
	"Note: Assume oop is not a SmallInteger!"

	| hdr fmt totalLength fixedFields |
	<inline: false>
	hdr := objectMemory baseHeader: oop.
	fmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: oop baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: oop format: fmt length: totalLength.
	fmt = 3 ifTrue: [self assert: (objectMemory isContextHeader: hdr) not].
	^totalLength - fixedFields
]

{ #category : #'internal interpreter access' }
StackInterpreter >> stackFloatValue: offset [
	"In the StackInterpreter stacks grow down."
	<returnTypeC: #double>
	^self floatValueOf: (stackPages longAt: stackPointer + (offset*BytesPerWord))
]

{ #category : #'internal interpreter access' }
StackInterpreter >> stackIntegerValue: offset [
	"In the StackInterpreter stacks grow down."
	| integerPointer |
	integerPointer := stackPages longAt: stackPointer + (offset*BytesPerWord).
	^self checkedIntegerValueOf: integerPointer
]

{ #category : #'stack pages' }
StackInterpreter >> stackLimitBytes [
	"Answer the actual stackLimit offset in a page.  Since stackPageByteSize may have chosen to shrink a page
	 this may be less than stackPageFrameBytes, but it should be no more than stackPageFrameBytes."
	^self stackPageFrameBytes min: self stackPageByteSize - self stackLimitOffset - self stackPageHeadroom.
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
	(objectMemory isIntegerObject: oop) ifTrue: [self primitiveFail. ^ nil].
	^ oop

]

{ #category : #'stack pages' }
StackInterpreter >> stackPageByteSize [
	"Answer a page size that is a power-of-two and contains a useful number of frames.
	 Room for 512 bytes of frames gives around 40 frames a page which is a
	 good compromise between overflow rate and latency in divorcing a page."
	<inline: false>
	| pageBytes largeSize smallSize |
	pageBytes := self stackPageFrameBytes + self stackLimitOffset + self stackPageHeadroom.
	(pageBytes bitAnd: pageBytes - 1) = 0 ifTrue: "= 0 => a power of two"
		[^pageBytes].
	"round up or round down; that is the question.  If rounding down reduces
	 the size by no more than 1/8th round down, otherwise roundup."
	largeSize := 1 << pageBytes highBit.
	smallSize := 1 << (pageBytes highBit - 1).
	self assert: (largeSize > pageBytes and: [pageBytes > smallSize]).
	^(pageBytes - smallSize) <= (smallSize / 8)
		ifTrue: [smallSize]
		ifFalse: [largeSize]
]

{ #category : #'stack pages' }
StackInterpreter >> stackPageFrameBytes [
	"Answer a byte size that accomodates a useful number of frames.
	 512 bytes is room for around 40 frames a page which is a good
	 compromise between overflow rate and latency in divorcing a page."
	^512
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
		 self assert: ReceiverIndex + (objectMemory integerValueOf: sp) < (objectMemory lengthOf: aContext).
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
StackInterpreter >> stackPositiveMachineIntegerValue: offset [
	<api>
	"In the StackInterpreter stacks grow down."
	| integerPointer |
	integerPointer := stackPages longAt: stackPointer + (offset*BytesPerWord).
	^self positiveMachineIntegerValueOf: integerPointer
]

{ #category : #'internal interpreter access' }
StackInterpreter >> stackSignedMachineIntegerValue: offset [
	<api>
	"In the StackInterpreter stacks grow down."
	| integerPointer |
	integerPointer := stackPages longAt: stackPointer + (offset*BytesPerWord).
	^self signedMachineIntegerValueOf: integerPointer
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

{ #category : #'internal interpreter access' }
StackInterpreter >> stackValue: offset put: oop [
	"In the StackInterpreter stacks grow down."
	^stackPages
		longAt: stackPointer + (offset*BytesPerWord)
		put: oop
]

{ #category : #'compiled methods' }
StackInterpreter >> startPCOfMethod: aCompiledMethod [
	<api>
	"Zero-relative version of CompiledMethod>>startpc."
	^objectMemory lastPointerOf: aCompiledMethod
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
	(self oop: rcvr isLessThan: objectMemory youngStart) ifTrue:
		[objectMemory possibleRootStoreInto: rcvr value: top].
	objectMemory storePointerUnchecked: (currentBytecode bitAnd: 7) ofObject: rcvr withValue: top.
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
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self temporary: (currentBytecode bitAnd: 7) in: localFP put: self internalStackTop.
			 self internalPop: 1]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self temporary: (currentBytecode bitAnd: 7) in: localFP put: self internalStackTop.
			 self fetchNextBytecode.
			 self internalPop: 1]
]

{ #category : #utilities }
StackInterpreter >> storeInteger: fieldIndex ofObject: objectPointer withValue: integerValue [ 
	"Note: May be called by translated primitive code."
	(objectMemory isIntegerValue: integerValue)
		ifTrue: [objectMemory storePointerUnchecked: fieldIndex ofObject: objectPointer
					withValue: (objectMemory integerObjectOf: integerValue)]
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
	and: [(objectMemory isContextNonInt: rcvr)
	and: [self isMarriedOrWidowedContext: rcvr]])
		ifTrue:
			[self instVar: fieldIndex ofContext: rcvr put: anObject]
		ifFalse:
			[objectMemory storePointer: fieldIndex ofObject: rcvr withValue: anObject]

]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeRemoteTemp: index inVectorAt: tempVectorIndex [
	| tempVector |
	tempVector := self temporary: tempVectorIndex in: localFP.
	objectMemory storePointer: index ofObject: tempVector withValue: self internalStackTop.
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
	self assert: ReceiverIndex + value < (objectMemory lengthOf: aContext).
	objectMemory storePointerUnchecked: StackPointerIndex
		ofObject: aContext
		withValue: (objectMemory integerObjectOf: value)
]

{ #category : #'primitive support' }
StackInterpreter >> stringForCString: aCString [
	"Answer a new String copied from a null-terminated C string,
	 or nil if out of memory.
	 Caution: This may invoke the garbage collector."
	<api>
	<var: 'aCString' type: 'const char *'>
	| len newString |
	len := self strlen: aCString.
	newString := objectMemory instantiateClass: objectMemory classString indexableSize: len.
	newString isNil ifFalse:
		[self st: (self arrayValueOf: newString)
			rn: aCString
			cpy: len]. "(char *)strncpy()"
	^newString
]

{ #category : #'indexing primitive support' }
StackInterpreter >> subscript: array with: index format: fmt [
	"Note: This method assumes that the index is within bounds!"

	<inline: true>
	<asmLabel: false> "If labelled icc duplicates when inlining stObject:at:"
	fmt <= 4 ifTrue: [  "pointer type objects"
		^ objectMemory fetchPointer: index - 1 ofObject: array].
	fmt < 8 ifTrue: [  "long-word type objects"
		^ self positive32BitIntegerFor:
			(objectMemory fetchLong32: index - 1 ofObject: array)
	] ifFalse: [  "byte-type objects"
		^ objectMemory integerObjectOf:
			(objectMemory fetchByte: index - 1 ofObject: array)
	].
]

{ #category : #'indexing primitive support' }
StackInterpreter >> subscript: array with: index storing: oopToStore format: fmt [ 
	"Note: This method assumes that the index is within bounds!"
	| valueToStore |
	<inline: true>
	fmt <= 4
		ifTrue: ["pointer type objects"
			objectMemory storePointer: index - 1 ofObject: array
				withValue: oopToStore]
		ifFalse: [fmt < 8
				ifTrue: ["long-word type objects"
					valueToStore := self positive32BitValueOf: oopToStore.
					self successful
						ifTrue: [objectMemory storeLong32: index - 1 ofObject: array
									withValue: valueToStore]]
				ifFalse: ["byte-type objects"
					(objectMemory isIntegerObject: oopToStore)
						ifFalse: [self success: false].
					valueToStore := objectMemory integerValueOf: oopToStore.
					(valueToStore >= 0
							and: [valueToStore <= 255])
						ifFalse: [self success: false].
					self successful
						ifTrue: [objectMemory
								storeByte: index - 1
								ofObject: array
								withValue: valueToStore]]]
]

{ #category : #'message sending' }
StackInterpreter >> superclassOf: classPointer [
	<inline: true>
	^objectMemory fetchPointer: SuperclassIndex ofObject: classPointer
]

{ #category : #'send bytecodes' }
StackInterpreter >> superclassSend [
	"Send a message to self, starting lookup with the superclass of the class
	 containing the currently executing method."
	"Assume: messageSelector and argumentCount have been set, and that
	 the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeNamed: 'commonSupersend' inCase: #singleExtendedSuperBytecode>
	lkupClass := self superclassOf: (self methodClassOf: method).
	self assert: lkupClass ~= objectMemory nilObject.
	self commonSend
]

{ #category : #'debug support' }
StackInterpreter >> symbolicMethod: aMethod [
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
					for: aMethod
					coInterpreter: self
					objectMemory: objectMemory))
		indent: 0;
		printInstructionsOn: ts.
	ts flush
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
	^self temporaryCountOfMethodHeader: (self headerOf: methodPointer)
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
	^offset < (frameNumArgs := self frameNumArgs: theFP)
		ifTrue: [stackPages longAt: theFP + FoxCallerSavedIP + ((frameNumArgs - offset) * BytesPerWord) put: valueOop]
		ifFalse: [stackPages longAt: theFP + FoxReceiver - BytesPerWord + ((frameNumArgs - offset) * BytesPerWord) put: valueOop]
]

{ #category : #'compiled methods' }
StackInterpreter >> temporaryCountOfMethodHeader: header [
	<api>
	<inline: true>
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
	objectMemory markAndTrace: profileProcess.
	objectMemory markAndTrace: profileMethod.
	objectMemory markAndTrace: profileSemaphore.

	"The longRunningPrimitiveCheckMethod (LRPCM) is sampled in an interrupt.  Be very careful with it.
	  If longRunningPrimitiveCheckSequenceNumber (LRPCSN) = statCheckForEvents then LRPCM has
	  been recenty sampled, but it must be newMethod and we don't need to trace it twice.  If LRPCSN
	  ~= statCheckForEvents then LRPCM must be some extant object and needs to be traced."
	self sqLowLevelMFence.
	(longRunningPrimitiveCheckMethod ~= nil
	 and: [longRunningPrimitiveCheckSequenceNumber ~= statCheckForEvents]) ifTrue:
		[objectMemory markAndTrace: longRunningPrimitiveCheckMethod].
	longRunningPrimitiveCheckSemaphore ~= nil ifTrue:
		[objectMemory markAndTrace: longRunningPrimitiveCheckSemaphore]
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
	oldProc := objectMemory fetchPointer: ActiveProcessIndex ofObject: sched.
	activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
	objectMemory storePointer: SuspendedContextIndex ofObject: oldProc withValue: activeContext.
	objectMemory storePointer: ActiveProcessIndex ofObject: sched withValue: newProc.
	objectMemory storePointerUnchecked: MyListIndex ofObject: newProc withValue: objectMemory nilObject.
	self externalSetStackPageAndPointersForSuspendedContextOfProcess: newProc.
	instructionPointer := self popStack
]

{ #category : #'internal interpreter access' }
StackInterpreter >> unPop: nItems [
	"In the StackInterpreter stacks grow down."
	stackPointer := stackPointer - (nItems*BytesPerWord)
]

{ #category : #'interpreter shell' }
StackInterpreter >> undoFetchNextBytecode [
	"Backup the ip when it has been incremented to fetch the next bytecode."

	localIP := localIP - 1
]

{ #category : #'miscellaneous bytecodes' }
StackInterpreter >> unknownBytecode [
	"If an error selector is available then send it to the activeContext, otherwise abort."
	self respondToUnknownBytecode
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
	swapFloatWords := objectMemory vmEndianness ~= imageFloatsBigEndian.
	self assert: ClassFloatCompactIndex ~= 0.
	oop := startOop.
	[self oop: oop isLessThan: stopAddr] whileTrue:
		[(objectMemory isFreeObject: oop) ifFalse:
			[fmt := objectMemory formatOf: oop.
			 fmt >= 8 ifTrue: "oop contains bytes"
				[wordAddr := oop + BaseHeaderSize.
				fmt >= 12 ifTrue: "compiled method; start after methodHeader and literals"
					[methodHeader := self longAt: oop + BaseHeaderSize.
					 wordAddr := wordAddr + BytesPerWord + ((methodHeader >> 10 bitAnd: 255) * BytesPerWord)].
				objectMemory reverseBytesFrom: wordAddr to: oop + (objectMemory sizeBitsOf: oop)].
			 fmt = 6 ifTrue: "Bitmap, Float etc"
				[(swapFloatWords
				  and: [(objectMemory compactClassIndexOf: oop) = ClassFloatCompactIndex])
					ifTrue:
						[temp := self longAt: oop + BaseHeaderSize.
						 self longAt: oop + BaseHeaderSize put: (self longAt: oop + BaseHeaderSize + 4).
						 self longAt: oop + BaseHeaderSize + 4 put: temp]
					ifFalse:
						[BytesPerWord = 8 ifTrue: "Object contains 32-bit half-words packed into 64-bit machine words."
							[wordAddr := oop + BaseHeaderSize.
							 objectMemory reverseWordsFrom: wordAddr to: oop + (objectMemory sizeBitsOf: oop)]]]].
			oop := objectMemory objectAfter: oop]
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
	<var: #argsPointer type: #'char *'>
	self assert: (self frameHasContext: theFP).
	theContext := self frameContext: theFP.
	self assert: (self frameReceiver: theFP)
				= (objectMemory fetchPointer: ReceiverIndex ofObject: theContext).
	tempIndex := self frameNumArgs: theFP.
	"update the arguments. this would appear not to be strictly necessary, but is for two reasons.
	 First, the fact that arguments are read-only is only as convention in the Smalltalk compiler;
	 other languages may choose to modify arguments.
	 Second, the Squeak runUntilErrorOrReturnFrom: nightmare pops the stack top, which may, in
	 certain circumstances, be the last argument, and hence the last argument may not have been
	 stored into the context."
	pointer := theFP + (self frameStackedReceiverOffsetNumArgs: tempIndex).
	1 to: tempIndex do:
		[:i|
		pointer := pointer - BytesPerWord.
		self assert: (objectMemory addressCouldBeOop: (stackPages longAt: pointer)).
		 objectMemory storePointer: ReceiverIndex + i
			ofObject: theContext
			withValue: (stackPages longAt: pointer)].
	"now update the non-argument stack contents."
	pointer := theFP + FoxReceiver - BytesPerWord.
	[pointer >= theSP] whileTrue:
		[self assert: (objectMemory addressCouldBeOop: (stackPages longAt: pointer)).
		 tempIndex := tempIndex + 1.
		 objectMemory storePointer: ReceiverIndex + tempIndex
			ofObject: theContext
			withValue: (stackPages longAt: pointer).
		 pointer := pointer - BytesPerWord].
	self assert: ReceiverIndex + tempIndex < (objectMemory lengthOf: theContext).
	objectMemory storePointerUnchecked: StackPointerIndex
		ofObject: theContext
		withValue: (objectMemory integerObjectOf: tempIndex)
]

{ #category : #'debug support' }
StackInterpreter >> validInstructionPointer: anInstrPointer inFrame: fp [
	<var: #anInstrPointer type: #usqInt>
	<var: #fp type: #'char *'>
	<inline: false>
	^self validInstructionPointer: anInstrPointer inMethod: (self frameMethodObject: fp) framePointer: fp
]

{ #category : #'debug support' }
StackInterpreter >> validInstructionPointer: theInstrPointer inMethod: aMethod framePointer: fp [
	<var: #theInstrPointer type: #usqInt>
	<var: #aMethod type: #usqInt>
	^self
		cppIf: MULTIPLEBYTECODESETS
		ifTrue:
			[| methodHeader |
			 methodHeader := self noAssertHeaderOf: aMethod. "-1 for pre-increment in fetchNextBytecode"
			 theInstrPointer >= (aMethod + (objectMemory lastPointerOf: aMethod) + BaseHeaderSize - 1)
			 and: [theInstrPointer < (aMethod + (objectMemory byteLengthOf: aMethod) + BaseHeaderSize - 1)
			 and: ["If the method starts with a CallPrimitive opcode the instruction pointer should be past it."
				((self headerIndicatesAlternateBytecodeSet: methodHeader)
				and: [(self alternateHeaderHasPrimitiveFlag: methodHeader)
				and: [theInstrPointer < (aMethod
										+ BaseHeaderSize - 1
										+ (objectMemory lastPointerOf: aMethod)
										+ (self sizeOfCallPrimitiveBytecode: methodHeader) - 1)]])
					not]]]
		ifFalse: "-1 for pre-increment in fetchNextBytecode"
			[theInstrPointer >= (aMethod + (objectMemory lastPointerOf: aMethod) + BaseHeaderSize - 1)
			 and: [theInstrPointer < (aMethod + (objectMemory byteLengthOf: aMethod) + BaseHeaderSize - 1)]]
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
			 (self asserta: (objectMemory addressCouldBeObj: senderContextOrNil)) ifFalse:
				[^false].
			 (self asserta: (senderContextOrNil = objectMemory nilObject or: [self isContext: senderContextOrNil])) ifFalse:
				[^false]]].
	^true
]

{ #category : #'simulation support' }
StackInterpreter >> validate [
	<doNotGenerate>
	objectMemory validate
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
	longRunningPrimitiveSignalUndelivered := true.
	self sqLowLevelMFence
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
	| schedLists p processList proc ctxt |
	self externalWriteBackHeadFramePointers.
	schedLists := objectMemory fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	p := highestRunnableProcessPriority = 0
			ifTrue: [objectMemory fetchWordLengthOf: schedLists]
			ifFalse: [highestRunnableProcessPriority].
	[(p := p - 1) >= 0] whileTrue:
		[processList := objectMemory fetchPointer: p ofObject: schedLists.
	 	 [self isEmptyList: processList] whileFalse:
			["Only answer processes with a runnable suspendedContext.
			  Discard those that aren't; the VM would crash otherwise."
			 proc := self removeFirstLinkOfList: processList.
			 ctxt := objectMemory fetchPointer: SuspendedContextIndex ofObject: proc.
			 (self isLiveContext: ctxt) ifTrue:
				[highestRunnableProcessPriority := p + 1.
				^proc].
			 self warning: 'evicted zombie process from run queue']].
	self error: 'scheduler could not find a runnable process'.
	^nil
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
	self assert: (objectMemory isIntegerObject: anInteger).
	^self pointerForOop: (anInteger - 1)
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
	self successful ifTrue:
		["set Mac file type and creator; this is a noop on other platforms"
		fn := self ioLoadFunction: 'setMacFileTypeAndCreator' From: 'FilePlugin'.
		fn = 0 ifFalse:
			[self cCode:'((sqInt (*)(char*, char*, char*))fn)(imageName, "STim", "FAST")']]

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
	self putLong: objectMemory startOfMemory toFile: f.
	self putLong: objectMemory specialObjectsOop toFile: f.
	self putLong: objectMemory newObjectHash toFile: f.
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
	memStart := objectMemory startOfMemory.
	bytesWritten := self cCode: 'sqImageFileWrite(pointerForOop(memStart), sizeof(unsigned char), imageBytes, f)'.
	self success: bytesWritten = imageBytes.
	self touch: memStart.
	self cCode: 'sqImageFileClose(f)'

]
