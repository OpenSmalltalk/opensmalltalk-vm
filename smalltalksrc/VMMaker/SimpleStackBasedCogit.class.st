"
I am the stage one JIT for Cog that does not attempt to eliminate the stack via deferred code generation.
"
Class {
	#name : #SimpleStackBasedCogit,
	#superclass : #Cogit,
	#instVars : [
		'primitiveGeneratorTable',
		'primSetFunctionLabel',
		'primInvokeInstruction',
		'externalPrimCallOffsets',
		'externalPrimJumpOffsets',
		'externalSetPrimOffsets',
		'introspectionDataIndex',
		'introspectionData'
	],
	#pools : [
		'VMMethodCacheConstants',
		'VMObjectIndices',
		'VMSqueakClassIndices'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
SimpleStackBasedCogit class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^super ancilliaryClasses, (self objectRepresentationClass withAllSuperclasses copyUpThrough: CogObjectRepresentation) reverse
]

{ #category : #documentation }
SimpleStackBasedCogit class >> callingConvention [
	"The Smalltalk-to-Smalltalk calling convention for SimpleStackBasedCogit is
	 designed to be congruent with the interpreter and convenient for inline cacheing.
	 For inline cacheing it is convenient if the receiver is in a register.

	 Hence the calling convention is:
	
		On call ReceiverResultReg (edx on x86) contains the receiver, and the receiver
		and arguments are all on the stack, receiver furthest from top-of-stack.
	
		If the number of arguments is 3 or greater then the argument count is passed in
		SendNumArgsReg (this is for the linking run-time routine; it is ignored in linked sends).

		On return result is in ReceiverResultReg.  The callee removes arguments from the stack.
		The caller pushes the result if the result is used."
]

{ #category : #translation }
SimpleStackBasedCogit class >> declareCVarsIn: aCCodeGenerator [

	aCCodeGenerator vmClass primitiveTable ifNotNil:
		[:bytecodeGenTable|
		aCCodeGenerator
			var: #primitiveGeneratorTable
				declareC: 'static PrimitiveDescriptor primitiveGeneratorTable[MaxCompiledPrimitiveIndex+1]',
							(self tableInitializerFor: aCCodeGenerator vmClass primitiveTable
								in: aCCodeGenerator)].
	aCCodeGenerator
		var: #externalPrimCallOffsets
			declareC: 'sqInt externalPrimCallOffsets[MaxNumArgs + 1]';
		var: #externalPrimJumpOffsets
			declareC: 'sqInt externalPrimJumpOffsets[MaxNumArgs + 1]';
		var: #externalSetPrimOffsets
			declareC: 'sqInt externalSetPrimOffsets[MaxNumArgs + 1]';
		var: #primSetFunctionLabel type: #'AbstractInstruction *';
		var: #primInvokeInstruction type: #'AbstractInstruction *'
]

{ #category : #'class initialization' }
SimpleStackBasedCogit class >> initializeBytecodeTableForSistaV1 [
	"SimpleStackBasedCogit initializeBytecodeTableForSistaV1"

	BytecodeSetHasDirectedSuperSend := true.
	FirstSpecialSelector := 96.
	NumSpecialSelectors := 32.
	self flag:
'Special selector send class must be inlined to agree with the interpreter, which
 inlines class.  If class is sent to e.g. a general instance of ProtoObject then unless
 class is inlined there will be an MNU.  It must be that the Cointerpreter and Cogit
 have identical semantics.  We get away with not hardwiring the other special
 selectors either because in the Cointerpreter they are not inlined or because they
 are inlined only to instances of classes for which there will always be a method.'.
	self generatorTableFrom: #(
		"1 byte bytecodes"
		"pushes"
		(1    0   15 genPushReceiverVariableBytecode isInstVarRef)
		(1  16   31 genPushLiteralVariable16CasesBytecode	needsFrameNever: 1)
		(1  32   63 genPushLiteralConstantBytecode			needsFrameNever: 1)
		(1  64   75 genPushTemporaryVariableBytecode)
		(1  76   76 genPushReceiverBytecode)
		(1  77   77 genPushConstantTrueBytecode				needsFrameNever: 1)
		(1  78   78 genPushConstantFalseBytecode			needsFrameNever: 1)
		(1  79   79 genPushConstantNilBytecode				needsFrameNever: 1)
		(1  80   80 genPushConstantZeroBytecode				needsFrameNever: 1)
		(1  81   81 genPushConstantOneBytecode				needsFrameNever: 1)
		(1  82   82 genExtPushPseudoVariable)
		(1  83   83 duplicateTopBytecode						needsFrameNever: 1)

		(1  84   87 unknownBytecode)

		"returns"
		(1  88   88 genReturnReceiver				return needsFrameIfInBlock: isMappedInBlock 0)
		(1  89   89 genReturnTrue					return needsFrameIfInBlock: isMappedInBlock 0)
		(1  90   90 genReturnFalse					return needsFrameIfInBlock: isMappedInBlock 0)
		(1  91   91 genReturnNil					return needsFrameIfInBlock: isMappedInBlock 0)
		(1  92   92 genReturnTopFromMethod		return needsFrameIfInBlock: isMappedInBlock -1)
		(1  93   93 genReturnNilFromBlock			return needsFrameNever: -1)
		(1  94   94 genReturnTopFromBlock		return needsFrameNever: -1)
		(1  95   95 genExtNopBytecode			needsFrameNever: 0)

		"sends"
		(1   96 117 genSpecialSelectorSend isMapped) "#+ #- #< #> #<= #>= #= #~= #* #/ #\\ #@ #bitShift: #// #bitAnd: #bitOr: #at: #at:put: #size #next #nextPut: #atEnd"
		(1 118 118 genSpecialSelectorEqualsEquals needsFrameNever: notMapped -1) "not mapped because it is directly inlined (for now)"
		(1 119 119 genSpecialSelectorClass needsFrameNever: notMapped 0) "not mapped because it is directly inlined (for now)"
		(1 120 120 genSpecialSelectorNotEqualsEquals needsFrameNever: notMapped -1) "not mapped because it is directly inlined (for now)"
		(1 121 127 genSpecialSelectorSend isMapped) "#value #value: #do: #new #new: #x #y"

		(1 128 143 genSendLiteralSelector0ArgsBytecode isMapped)
		(1 144 159 genSendLiteralSelector1ArgBytecode isMapped)
		(1 160 175 genSendLiteralSelector2ArgsBytecode isMapped)

		"jumps"
		(1 176 183 genShortUnconditionalJump	branch v3:ShortForward:Branch:Distance:)
		(1 184 191 genShortJumpIfTrue			branch isBranchTrue isMapped "because of mustBeBoolean"
													v3:ShortForward:Branch:Distance:)
		(1 192 199 genShortJumpIfFalse			branch isBranchFalse isMapped "because of mustBeBoolean"
													v3:ShortForward:Branch:Distance:)

		"stores"
		(1 200 207 genStoreAndPopReceiverVariableBytecode isInstVarRef isMappedIfImmutability needsFrameIfImmutability: -1)
		(1 208 215 genStoreAndPopTemporaryVariableBytecode)

		(1 216 216 genPopStackBytecode needsFrameNever: -1)

		(1 217 217 genUnconditionalTrapBytecode isMapped)

		(1 218 223 unknownBytecode)

		"2 byte bytecodes"
		(2 224 224 extABytecode extension)
		(2 225 225 extBBytecode extension)

		"pushes"
		(2 226 226 genExtPushReceiverVariableBytecode isInstVarRef)		"Needs a frame for context inst var access"
		(2 227 227 genExtPushLiteralVariableBytecode		needsFrameNever: 1)
		(2 228 228 genExtPushLiteralBytecode					needsFrameNever: 1)
		(2 229 229 genLongPushTemporaryVariableBytecode)
		(2 230 230 unknownBytecode)
		(2 231 231 genPushNewArrayBytecode)
		(2 232 232 genExtPushIntegerBytecode				needsFrameNever: 1)
		(2 233 233 genExtPushCharacterBytecode				needsFrameNever: 1)

		"returns"
		"sends"
		(2 234 234 genExtSendBytecode isMapped)
		(2 235 235 genExtSendSuperBytecode isMapped)

		"sista bytecodes"
		(2 236 236 unknownBytecode)

		"jumps"
		(2 237 237 genExtUnconditionalJump	branch isMapped "because of interrupt check" v4:Long:Branch:Distance:)
		(2 238 238 genExtJumpIfTrue			branch isBranchTrue isMapped "because of mustBeBoolean" v4:Long:Branch:Distance:)
		(2 239 239 genExtJumpIfFalse			branch isBranchFalse isMapped "because of mustBeBoolean" v4:Long:Branch:Distance:)

		"stores"
		(2 240 240 genExtStoreAndPopReceiverVariableBytecode isInstVarRef isMappedIfImmutability)
		(2 241 241 genExtStoreAndPopLiteralVariableBytecode isMappedIfImmutability)
		(2 242 242 genLongStoreAndPopTemporaryVariableBytecode)
		(2 243 243 genExtStoreReceiverVariableBytecode isInstVarRef isMappedIfImmutability)
		(2 244 244 genExtStoreLiteralVariableBytecode isMappedIfImmutability)
		(2 245 245 genLongStoreTemporaryVariableBytecode)

		(2 246 247	unknownBytecode)

		"3 byte bytecodes"
		(3 248 248 genCallPrimitiveBytecode)
		(3 249 249 genExtPushFullClosureBytecode) 
		(3 250 250 genExtPushClosureBytecode block v4:Block:Code:Size:)
		(3 251 251 genPushRemoteTempLongBytecode)
		(3 252 252 genStoreRemoteTempLongBytecode)
		(3 253 253 genStoreAndPopRemoteTempLongBytecode)

		(3 254 255	unknownBytecode))
]

{ #category : #'class initialization' }
SimpleStackBasedCogit class >> initializeBytecodeTableForSqueakV3PlusClosures [
	"SimpleStackBasedCogit initializeBytecodeTableForSqueakV3PlusClosures"

	FirstSpecialSelector := 176.
	NumSpecialSelectors := 32.
	self flag:
'Special selector send class must be inlined to agree with the interpreter, which
 inlines class.  If class is sent to e.g. a general instance of ProtoObject then unless
 class is inlined there will be an MNU.  It must be that the Cointerpreter and Cogit
 have identical semantics.  We get away with not hardwiring the other special
 selectors either because in the Cointerpreter they are not inlined or because they
 are inlined only to instances of classes for which there will always be a method.'.
	self generatorTableFrom: #(
		(1    0   15 genPushReceiverVariableBytecode isInstVarRef)
		(1  16   31 genPushTemporaryVariableBytecode)
		(1  32   63 genPushLiteralConstantBytecode needsFrameNever: 1)
		(1  64   95 genPushLiteralVariableBytecode needsFrameNever: 1)
		(1  96 103 genStoreAndPopReceiverVariableBytecode isInstVarRef isMappedIfImmutability needsFrameIfImmutability: -1)
		(1 104 111 genStoreAndPopTemporaryVariableBytecode)
		(1 112 112 genPushReceiverBytecode)
		(1 113 113 genPushConstantTrueBytecode needsFrameNever: 1)
		(1 114 114 genPushConstantFalseBytecode needsFrameNever: 1)
		(1 115 115 genPushConstantNilBytecode needsFrameNever: 1)
		(1 116 119 genPushQuickIntegerConstantBytecode needsFrameNever: 1)
		"method returns in blocks need a frame because of nonlocalReturn:through:"
		(1 120 120 genReturnReceiver				return needsFrameIfInBlock: isMappedInBlock 0)
		(1 121 121 genReturnTrue					return needsFrameIfInBlock: isMappedInBlock 0)
		(1 122 122 genReturnFalse					return needsFrameIfInBlock: isMappedInBlock 0)
		(1 123 123 genReturnNil					return needsFrameIfInBlock: isMappedInBlock 0)
		(1 124 124 genReturnTopFromMethod		return needsFrameIfInBlock: isMappedInBlock -1)
		(1 125 125 genReturnTopFromBlock		return needsFrameNever: -1)

		(1 126 127 unknownBytecode)

		(2 128 128 extendedPushBytecode isInstVarRef) "well, maybe inst var ref"
		(2 129 129 extendedStoreBytecode isInstVarRef isMappedIfImmutability) "well, maybe inst var ref"
		(2 130 130 extendedStoreAndPopBytecode isInstVarRef isMappedIfImmutability) "well, maybe inst var ref"
		(2 131 131 genExtendedSendBytecode isMapped)
		(3 132 132 doubleExtendedDoAnythingBytecode isInstVarRef isMapped) "well, maybe inst var ref"
		(2 133 133 genExtendedSuperBytecode isMapped)
		(2 134 134 genSecondExtendedSendBytecode isMapped)
		(1 135 135 genPopStackBytecode needsFrameNever: -1)
		(1 136 136 duplicateTopBytecode needsFrameNever: 1)

		(1 137 137 genPushActiveContextBytecode)
		(2 138 138 genPushNewArrayBytecode)),

		((InitializationOptions at: #SpurObjectMemory ifAbsent: [false])
			ifTrue: [#((3 139 139 genCallPrimitiveBytecode))]
			ifFalse: [#((1 139 139 unknownBytecode))]),

	  #(
		(3 140 140 genPushRemoteTempLongBytecode)
		(3 141 141 genStoreRemoteTempLongBytecode)
		(3 142 142 genStoreAndPopRemoteTempLongBytecode)
		(4 143 143 genPushClosureCopyCopiedValuesBytecode block v3:Block:Code:Size:)

		(1 144 151 genShortUnconditionalJump			branch v3:ShortForward:Branch:Distance:)
		(1 152 159 genShortJumpIfFalse					branch isBranchFalse isMapped "because of mustBeBoolean"
															v3:ShortForward:Branch:Distance:)
		(2 160 163 genLongUnconditionalBackwardJump	branch isMapped "because of interrupt check"
															v3:Long:Branch:Distance:)
		(2 164 167 genLongUnconditionalForwardJump		branch v3:Long:Branch:Distance:)
		(2 168 171 genLongJumpIfTrue					branch isBranchTrue isMapped "because of mustBeBoolean"
															v3:LongForward:Branch:Distance:)
		(2 172 175 genLongJumpIfFalse					branch isBranchFalse isMapped "because of mustBeBoolean"
															v3:LongForward:Branch:Distance:)

		(1 176 197 genSpecialSelectorSend isMapped)
		(1 198 198 genSpecialSelectorEqualsEquals needsFrameNever: notMapped -1) "not mapped because it is directly inlined (for now)"
		(1 199 199 genSpecialSelectorClass needsFrameNever: notMapped 0) "not mapped because it is directly inlined (for now)"
		(1 200 200 genSpecialSelectorNotEqualsEquals needsFrameNever: notMapped -1) "not mapped because it is directly inlined (for now)"
		(1 201 207 genSpecialSelectorSend isMapped)
		(1 208 223 genSendLiteralSelector0ArgsBytecode isMapped)
		(1 224 239 genSendLiteralSelector1ArgBytecode isMapped)
		(1 240 255 genSendLiteralSelector2ArgsBytecode isMapped))
]

{ #category : #'class initialization' }
SimpleStackBasedCogit class >> initializePrimitiveTableForSqueak [
	"Initialize the table of primitive generators.  This does not include normal primitives implemented in the coInterpreter.
	 N.B. primitives that don't have an explicit arg count (the integer following the generator) may be variadic."
	"SimpleStackBasedCogit initializePrimitiveTableForSqueak"
	MaxCompiledPrimitiveIndex := self objectRepresentationClass wordSize = 8
										ifTrue: [659]
										ifFalse: [222].
	primitiveTable := CArrayAccessor on: (Array new: MaxCompiledPrimitiveIndex + 1).
	self table: primitiveTable from: 
	#(	"Integer Primitives (0-19)"
		(1 genPrimitiveAdd				1)
		(2 genPrimitiveSubtract			1)
		(3 genPrimitiveLessThan		1)
		(4 genPrimitiveGreaterThan		1)
		(5 genPrimitiveLessOrEqual		1)
		(6 genPrimitiveGreaterOrEqual	1)
		(7 genPrimitiveEqual			1)
		(8 genPrimitiveNotEqual		1)
		(9 genPrimitiveMultiply			1)
		(10 genPrimitiveDivide			1)
		(11 genPrimitiveMod			1)
		(12 genPrimitiveDiv				1)
		(13 genPrimitiveQuo			1)
		(14 genPrimitiveBitAnd			1)
		(15 genPrimitiveBitOr			1)
		(16 genPrimitiveBitXor			1)
		(17 genPrimitiveBitShift			1)
		"(18 primitiveMakePoint)"
		"(19 primitiveFail)"					"Guard primitive for simulation -- *must* fail"

		"LargeInteger Primitives (20-39)"
		"(20 primitiveFail)"
		"(21 primitiveAddLargeIntegers)"
		"(22 primitiveSubtractLargeIntegers)"
		"(23 primitiveLessThanLargeIntegers)"
		"(24 primitiveGreaterThanLargeIntegers)"
		"(25 primitiveLessOrEqualLargeIntegers)"
		"(26 primitiveGreaterOrEqualLargeIntegers)"
		"(27 primitiveEqualLargeIntegers)"
		"(28 primitiveNotEqualLargeIntegers)"
		"(29 primitiveMultiplyLargeIntegers)"
		"(30 primitiveDivideLargeIntegers)"
		"(31 primitiveModLargeIntegers)"
		"(32 primitiveDivLargeIntegers)"
		"(33 primitiveQuoLargeIntegers)"
		"(34 primitiveBitAndLargeIntegers)"
		"(35 primitiveBitOrLargeIntegers)"
		"(36 primitiveBitXorLargeIntegers)"
		"(37 primitiveBitShiftLargeIntegers)"

		"Float Primitives (38-59)"
		"(38 genPrimitiveFloatAt)"
		"(39 genPrimitiveFloatAtPut)"
		(40 genPrimitiveAsFloat					0)
		(41 genPrimitiveFloatAdd				1)
		(42 genPrimitiveFloatSubtract			1)
		(43 genPrimitiveFloatLessThan			1)
		(44 genPrimitiveFloatGreaterThan		1)
		(45 genPrimitiveFloatLessOrEqual		1)
		(46 genPrimitiveFloatGreaterOrEqual	1)
		(47 genPrimitiveFloatEqual				1)
		(48 genPrimitiveFloatNotEqual			1)
		(49 genPrimitiveFloatMultiply			1)
		(50 genPrimitiveFloatDivide				1)
		"(51 genPrimitiveTruncated)"
		"(52 genPrimitiveFractionalPart)"
		"(53 genPrimitiveExponent)"
		"(54 genPrimitiveTimesTwoPower)"
		(55 genPrimitiveFloatSquareRoot		0)
		"(56 genPrimitiveSine)"
		"(57 genPrimitiveArctan)"
		"(58 genPrimitiveLogN)"
		"(59 genPrimitiveExp)"

		"Subscript and Stream Primitives (60-67)"
		(60 genPrimitiveAt				1)
		(61 genPrimitiveAtPut			2)
		(62 genPrimitiveSize			0)
		(63 genPrimitiveStringAt		1)
		(64 genPrimitiveStringAtPut		2)
		"The stream primitives no longer pay their way; normal Smalltalk code is faster."
		(65 genFastPrimFail)"was primitiveNext"
		(66 genFastPrimFail) "was primitiveNextPut"
		(67 genFastPrimFail) "was primitiveAtEnd"

		"StorageManagement Primitives (68-79)"
		(68 genPrimitiveObjectAt			1)	"Good for debugger/InstructionStream performance"
		"(69 primitiveObjectAtPut)"
		(70 genPrimitiveNew			0)
		(71 genPrimitiveNewWithArg	1)
		"(72 primitiveArrayBecomeOneWay)"		"Blue Book: primitiveBecome"
		"(73 primitiveInstVarAt)"
		"(74 primitiveInstVarAtPut)"
		(75 genPrimitiveIdentityHash	0)
		"(76 primitiveStoreStackp)"					"Blue Book: primitiveAsObject"
		"(77 primitiveSomeInstance)"
		"(78 primitiveNextInstance)"
		(79 genPrimitiveNewMethod	2)

		"Control Primitives (80-89)"
		"(80 primitiveFail)"							"Blue Book: primitiveBlockCopy"
		"(81 primitiveFail)"							"Blue Book: primitiveValue"
		"(82 primitiveFail)"							"Blue Book: primitiveValueWithArgs"
		(83 genPrimitivePerform)
		"(84 primitivePerformWithArgs)"
		"(85 primitiveSignal)"
		"(86 primitiveWait)"
		"(87 primitiveResume)"
		"(88 primitiveSuspend)"
		"(89 primitiveFlushCache)"

		"(90 primitiveMousePoint)"
		"(91 primitiveTestDisplayDepth)"			"Blue Book: primitiveCursorLocPut"
		"(92 primitiveSetDisplayMode)"				"Blue Book: primitiveCursorLink"
		"(93 primitiveInputSemaphore)"
		"(94 primitiveGetNextEvent)"				"Blue Book: primitiveSampleInterval"
		"(95 primitiveInputWord)"
		"(96 primitiveFail)"	"primitiveCopyBits"
		"(97 primitiveSnapshot)"
		"(98 primitiveStoreImageSegment)"
		"(99 primitiveLoadImageSegment)"
		"(100 primitivePerformInSuperclass)"		"Blue Book: primitiveSignalAtTick"
		"(101 primitiveBeCursor)"
		"(102 primitiveBeDisplay)"
		"(103 primitiveScanCharacters)"
		"(104 primitiveFail)"	"primitiveDrawLoop"
		(105 genPrimitiveStringReplace)
		"(106 primitiveScreenSize)"
		"(107 primitiveMouseButtons)"
		"(108 primitiveKbdNext)"
		"(109 primitiveKbdPeek)"


		"System Primitives (110-119)"
		(110 genPrimitiveIdentical 1)
		(111 genPrimitiveClass)				"Support both class and Context>>objectClass:"
		"(112 primitiveBytesLeft)"
		"(113 primitiveQuit)"
		"(114 primitiveExitToDebugger)"
		"(115 primitiveChangeClass)"					"Blue Book: primitiveOopsLeft"
		"(116 primitiveFlushCacheByMethod)"
		"(117 primitiveExternalCall)"
		"(118 primitiveDoPrimitiveWithArgs)"
		"(119 primitiveFlushCacheSelective)"

		(148 genPrimitiveShallowCopy 0)			"a.k.a. clone"

		(158 genPrimitiveStringCompareWith 1)
		(159 genPrimitiveHashMultiply 0)

		(165 genPrimitiveIntegerAt			1)	"Signed version of genPrimitiveAt"
		(166 genPrimitiveIntegerAtPut		2)	"Signed version of genPrimitiveAtPut"

		(169 genPrimitiveNotIdentical 1)

		(170 genPrimitiveAsCharacter)				"SmallInteger>>asCharacter, Character class>>value:"
		(171 genPrimitiveImmediateAsInteger 0)	"Character>>value SmallFloat64>>asInteger"
			
		"(173 primitiveSlotAt 1)"
		"(174 primitiveSlotAtPut 2)"
		(175 genPrimitiveIdentityHash	0)		"Behavior>>identityHash"

		"Old closure primitives"
		"(186 primitiveFail)" "was primitiveClosureValue"
		"(187 primitiveFail)" "was primitiveClosureValueWithArgs"

		"Perform method directly"
		"(188 primitiveExecuteMethodArgsArray)"
		"(189 primitiveExecuteMethod)"

		"Unwind primitives"
		"(195 primitiveFindNextUnwindContext)"
		"(196 primitiveTerminateTo)"
		"(197 primitiveFindHandlerContext)"
		(198 genFastPrimFail "primitiveMarkUnwindMethod")
		(199 genFastPrimFail "primitiveMarkHandlerMethod")

		"new closure primitives"
		"(200 primitiveClosureCopyWithCopiedValues)"
		(201 genPrimitiveClosureValue	0) "value"
		(202 genPrimitiveClosureValue	1) "value:"
		(203 genPrimitiveClosureValue	2) "value:value:"
		(204 genPrimitiveClosureValue	3) "value:value:value:"
		(205 genPrimitiveClosureValue	4) "value:value:value:value:"
		"(206 genPrimitiveClosureValueWithArgs)" "valueWithArguments:"

		(207 genPrimitiveFullClosureValue) "value[:value:value:value:] et al"
		"(208 genPrimitiveFullClosureValueWithArgs)" "valueWithArguments:"
		(209 genPrimitiveFullClosureValue) "valueNoContextSwitch[:value:] et al"

		"(210 primitiveContextAt)"
		"(211 primitiveContextAtPut)"
		"(212 primitiveContextSize)"

		"(218 primitiveDoNamedPrimitiveWithArgs)"
		"(219 primitiveFail)"	"reserved for Cog primitives"

		"(220 primitiveFail)"		"reserved for Cog primitives"

		(221 genPrimitiveClosureValue	0) "valueNoContextSwitch"
		(222 genPrimitiveClosureValue	1) "valueNoContextSwitch:"

		"SmallFloat primitives (540-559)"
		(541 genPrimitiveSmallFloatAdd				1)
		(542 genPrimitiveSmallFloatSubtract			1)
		(543 genPrimitiveSmallFloatLessThan			1)
		(544 genPrimitiveSmallFloatGreaterThan		1)
		(545 genPrimitiveSmallFloatLessOrEqual		1)
		(546 genPrimitiveSmallFloatGreaterOrEqual		1)
		(547 genPrimitiveSmallFloatEqual				1)
		(548 genPrimitiveSmallFloatNotEqual			1)
		(549 genPrimitiveSmallFloatMultiply				1)
		(550 genPrimitiveSmallFloatDivide				1)
		"(551 genPrimitiveSmallFloatTruncated			0)"
		"(552 genPrimitiveSmallFloatFractionalPart		0)"
		"(553 genPrimitiveSmallFloatExponent			0)"
		"(554 genPrimitiveSmallFloatTimesTwoPower	1)"
		(555 genPrimitiveSmallFloatSquareRoot			0)
		"(556 genPrimitiveSmallFloatSine				0)"
		"(557 genPrimitiveSmallFloatArctan				0)"
		"(558 genPrimitiveSmallFloatLogN				0)"
		"(559 genPrimitiveSmallFloatExp				0)"

		"Pinned object creation primitives"
		"(598 primitiveNewPinned)"
		"(599 primitiveNewWithArgPinned)"
						
		(600 genPrimitiveLoadBoolean8FromBytes)
		(601 genPrimitiveLoadUInt8FromBytes)
		(602 genPrimitiveLoadInt8FromBytes)
		(603 genPrimitiveLoadUInt16FromBytes)
		(604 genPrimitiveLoadInt16FromBytes)
		(605 genPrimitiveLoadUInt32FromBytes)
		(606 genPrimitiveLoadInt32FromBytes)
		(607 genPrimitiveLoadUInt64FromBytes)
		(608 genPrimitiveLoadInt64FromBytes)
		(609 genPrimitiveLoadPointerFromBytes)
		(610 genPrimitiveLoadChar8FromBytes)
		(611 genPrimitiveLoadChar16FromBytes)
		(612 genPrimitiveLoadChar32FromBytes)
		(613 genPrimitiveLoadFloat32FromBytes)
		(614 genPrimitiveLoadFloat64FromBytes)
		(615 genPrimitiveStoreBoolean8IntoBytes)
		(616 genPrimitiveStoreUInt8IntoBytes)
		(617 genPrimitiveStoreInt8IntoBytes)
		(618 genPrimitiveStoreUInt16IntoBytes)
		(619 genPrimitiveStoreInt16IntoBytes)
		(620 genPrimitiveStoreUInt32IntoBytes)
		(621 genPrimitiveStoreInt32IntoBytes)
		(622 genPrimitiveStoreUInt64IntoBytes)
		(623 genPrimitiveStoreInt64IntoBytes)
		(624 genPrimitiveStorePointerIntoBytes)
		(625 genPrimitiveStoreChar8IntoBytes)
		(626 genPrimitiveStoreChar16IntoBytes)
		(627 genPrimitiveStoreChar32IntoBytes)
		(628 genPrimitiveStoreFloat32IntoBytes)
		(629 genPrimitiveStoreFloat64IntoBytes)
		(630 genPrimitiveLoadBoolean8FromExternalAddress)
		(631 genPrimitiveLoadUInt8FromExternalAddress)
		(632 genPrimitiveLoadInt8FromExternalAddress)
		(633 genPrimitiveLoadUInt16FromExternalAddress)
		(634 genPrimitiveLoadInt16FromExternalAddress)
		(635 genPrimitiveLoadUInt32FromExternalAddress)
		(636 genPrimitiveLoadInt32FromExternalAddress)
		(637 genPrimitiveLoadUInt64FromExternalAddress)
		(638 genPrimitiveLoadInt64FromExternalAddress)
		(639 genPrimitiveLoadPointerFromExternalAddress)
		(640 genPrimitiveLoadChar8FromExternalAddress)
		(641 genPrimitiveLoadChar16FromExternalAddress)
		(642 genPrimitiveLoadChar32FromExternalAddress)
		(643 genPrimitiveLoadFloat32FromExternalAddress)
		(644 genPrimitiveLoadFloat64FromExternalAddress)
		(645 genPrimitiveStoreBoolean8IntoExternalAddress)
		(646 genPrimitiveStoreUInt8IntoExternalAddress)
		(647 genPrimitiveStoreInt8IntoExternalAddress)
		(648 genPrimitiveStoreUInt16IntoExternalAddress)
		(649 genPrimitiveStoreInt16IntoExternalAddress)
		(650 genPrimitiveStoreUInt32IntoExternalAddress)
		(651 genPrimitiveStoreInt32IntoExternalAddress)
		(652 genPrimitiveStoreUInt64IntoExternalAddress)
		(653 genPrimitiveStoreInt64IntoExternalAddress)
		(654 genPrimitiveStorePointerIntoExternalAddress)
		(655 genPrimitiveStoreChar8IntoExternalAddress)
		(656 genPrimitiveStoreChar16IntoExternalAddress)
		(657 genPrimitiveStoreChar32IntoExternalAddress)
		(658 genPrimitiveStoreFloat32IntoExternalAddress)
		(659 genPrimitiveStoreFloat64IntoExternalAddress)
	)
]

{ #category : #'class initialization' }
SimpleStackBasedCogit class >> table: primArray from: specArray [ 
	"Fill in the specified entries in the primitive table."
	specArray do:
		[:spec | 
		 (spec first <= primArray size
		  and: [spec second == #genFastPrimFail
			  or: [self objectRepresentationClass shouldIncludeMethodForSelector: spec second]]) ifTrue:
			[(primArray at: spec first put: CogPrimitiveDescriptor new)
				primitiveGenerator: spec second;
				primNumArgs: (spec at: 3 ifAbsent: -1)]].
	primArray object withIndexDo:
		[:generator :i|
		generator ifNil:
			[(primArray object at: i put: CogPrimitiveDescriptor new)
				primNumArgs: -1]]
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> adjustArgumentsForPerform: numArgs [
	"e.g.	Receiver				Receiver	or	Receiver				Receiver	(RISC)
			Selector/Arg0	=>		Arg1			Selector/Arg0	=>		Arg1
			Arg1					Arg2			Arg1					Arg2
			Arg2					Arg3			Arg2			sp->	Arg3
	 		Arg3			sp->	retpc	sp->	Arg3
	 sp->	retpc"

	backEnd hasLinkRegister
		ifTrue:
			[numArgs - 2 to: 0 by: -1 do:
				[:index|
				self MoveMw: index * objectMemory wordSize r: SPReg R: TempReg.
				self MoveR: TempReg Mw: index + 1 * objectMemory wordSize r: SPReg].
			self AddCq: objectMemory wordSize R: SPReg]
		ifFalse:
			[numArgs - 1 to: 1 by: -1 do:
				[:index|
				self MoveMw: index * objectMemory wordSize r: SPReg R: TempReg.
				self MoveR: TempReg Mw: index + 1 * objectMemory wordSize r: SPReg].
			self PopR: TempReg.
			self MoveR: TempReg Mw: 0 r: SPReg]
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> annotationForSendTable: sendTable [
	"c.f. offsetAndSendTableFor:annotation:into:"
	<inline: true>
	<var: #sendTable type: #'sqInt *'>
	sendTable == ordinarySendTrampolines ifTrue:
		[^IsSendCall].
	BytecodeSetHasDirectedSuperSend ifTrue:
		[sendTable == directedSuperSendTrampolines ifTrue:
			[^IsDirectedSuperSend].
		 sendTable == directedSuperBindingSendTrampolines ifTrue:
			[^IsDirectedSuperBindingSend]].
	self assert: sendTable == superSendTrampolines.
	^IsSuperSend
]

{ #category : #'simulation only' }
SimpleStackBasedCogit >> bytecodeFixupClass [
	<doNotGenerate>
	^CogBytecodeFixup
]

{ #category : #accessing }
SimpleStackBasedCogit >> bytecodePC: anInteger [ 
	<doNotGenerate>
	bytecodePC := anInteger 
]

{ #category : #trampolines }
SimpleStackBasedCogit >> cPICMissTrampolineFor: numArgs [
	^ceCPICMissTrampoline
]

{ #category : #accessing }
SimpleStackBasedCogit >> ceCPICMissTrampoline: anAddress [ 
	
	ceCPICMissTrampoline := anAddress
]

{ #category : #'simulation only' }
SimpleStackBasedCogit >> ceShortCutTraceBlockActivation: aProcessorSimulationTrap [
	self shortcutTrampoline: aProcessorSimulationTrap
		to: [coInterpreter ceTraceBlockActivation]
]

{ #category : #'simulation only' }
SimpleStackBasedCogit >> ceShortCutTraceLinkedSend: aProcessorSimulationTrap [
	self shortcutTrampoline: aProcessorSimulationTrap
		to: [coInterpreter ceTraceLinkedSend: (processor registerAt: ReceiverResultReg)]
]

{ #category : #'simulation only' }
SimpleStackBasedCogit >> ceShortCutTraceStore: aProcessorSimulationTrap [
	<doNotGenerate>
	self shortcutTrampoline: aProcessorSimulationTrap
		to: [coInterpreter
				ceTraceStoreOf: (processor registerAt: ClassReg)
				into: (processor registerAt: ReceiverResultReg)]
]

{ #category : #'compile abstract instructions' }
SimpleStackBasedCogit >> compileBlockBodies [
	<inline: false>
	| result compiledBlocksCount blockStart savedNeedsFrame savedNumArgs |
	<var: #blockStart type: #'BlockStart *'>
	self assert: blockCount > 0.
	"scanBlock: in compileBlockEntry: sets both of these appropriately for each block."
	savedNeedsFrame := needsFrame.
	savedNumArgs := methodOrBlockNumArgs.
	inBlock := InVanillaBlock.
	compiledBlocksCount := 0.
	[compiledBlocksCount < blockCount] whileTrue:
		[blockStart := self blockStartAt: compiledBlocksCount.
		 self scanBlock: blockStart.
		 self compileBlockEntry: blockStart.
		 (result := self compileAbstractInstructionsFrom: blockStart startpc
						through: blockStart startpc + blockStart span - 1) < 0 ifTrue:
			[^result].
		 compiledBlocksCount := compiledBlocksCount + 1].
	needsFrame := savedNeedsFrame.
	methodOrBlockNumArgs := savedNumArgs.
	^0
]

{ #category : #'compile abstract instructions' }
SimpleStackBasedCogit >> compileBlockDispatch [
	"Compile the jump instruction(s) at the end of the method that dispatch to each block body."
	<inline: false>
	| jumpSkip |
	<var: #jumpSkip type: #'AbstractInstruction *'>
	self assert: blockCount > 0.
	"Generate the special block entry for primitiveClosureValueNoContextSwitch
	 that signals a context-switch is not possible by zeroing SendNumArgsReg.
	 Even though conceptually this isn't needed if no blocks build a frame it has
	 to be present so that primitiveClosureValueNoContextSwitch can call it."
	blockEntryNoContextSwitch := self MoveCq: 0 R: SendNumArgsReg.
	"Now generate a binary search through start pcs to jump to blocks. 1 block is a special case."
	jumpSkip := self Jump: 0.
	"Set OK to context switch flag to non-zero."
	blockEntryLabel := self MoveR: ReceiverResultReg R: SendNumArgsReg.
	jumpSkip jmpTarget: self Label.
	blockCount > 1 ifTrue:
		[objectRepresentation
			genLoadSlot: ClosureStartPCIndex
			sourceReg: ReceiverResultReg
			destReg: TempReg].
	self compileBlockDispatchFrom: 0 to: blockCount - 1.
	^0
]

{ #category : #'compile abstract instructions' }
SimpleStackBasedCogit >> compileBlockFrameBuild: blockStart [
	"Build a frame for a block activation.  See CoInterpreter class>>initializeFrameIndices.
	 		closure (in ReceiverResultReg)
			arg0
			...
			argN
			caller's saved ip/this stackPage (for a base frame)
	fp->	saved fp
			method
			context (uninitialized?)
			receiver
			first temp
			...
	sp->	Nth temp
	Avoid use of SendNumArgsReg which is the flag determining whether
	context switch is allowed on stack-overflow."
	<var: #blockStart type: #'BlockStart *'>
	<inline: false>
	self annotateBytecode: self Label.
	backEnd hasLinkRegister ifTrue:
		[self PushR: LinkReg].
	self PushR: FPReg.
	self MoveR: SPReg R: FPReg.
	"Think of ClassReg as ClosureReg"
	self MoveR: ReceiverResultReg R: ClassReg.
	"The block method field must have its MFMethodFlagIsBlockFlag bit set.
	 We arrange this using a labelOffset.  A hack, but it works."
	blockStart fakeHeader
		addDependent: (self annotateAbsolutePCRef:
			(self PushCw: blockStart fakeHeader asInteger)); "method"
		setLabelOffset: MFMethodFlagIsBlockFlag.
	self annotate: (self PushCw: objectMemory nilObject) "context"
		objRef: objectMemory nilObject.
	"Fetch home receiver from outer context. closure is on stack and initially in ReceiverResultReg.
	 It is safe to use Arg0Reg because reg args are pushed by the value primitives if there are any.".
	blockStart hasInstVarRef
		ifTrue: "Use ReceiverResultReg for Context to agree with store check trampoline"
			[objectRepresentation
				genLoadSlot: ClosureOuterContextIndex
					sourceReg: ClassReg
						destReg: ReceiverResultReg;
				genLoadSlot: ReceiverIndex
					sourceReg: ReceiverResultReg
						destReg: Arg0Reg.
			objectRepresentation
				genEnsureOopInRegNotForwarded: Arg0Reg scratchReg: TempReg updatingSlot: ReceiverIndex in: ReceiverResultReg.
			self MoveR: Arg0Reg R: ReceiverResultReg]
		ifFalse:
			[objectRepresentation
				genLoadSlot: ClosureOuterContextIndex
					sourceReg: ClassReg
						destReg: Arg0Reg;
				genLoadSlot: ReceiverIndex
					sourceReg: Arg0Reg
						destReg: ReceiverResultReg].
	self PushR: ReceiverResultReg. "home receiver"
	"Push copied values; bytecode initializes temporaries"
	0 to: blockStart numCopied - 1 do:
		[:i|
		objectRepresentation
			genLoadSlot: i + ClosureFirstCopiedValueIndex
			sourceReg: ClassReg
			destReg: TempReg.
		self PushR: TempReg].
	self MoveAw: coInterpreter stackLimitAddress R: TempReg.
	self CmpR: TempReg R: SPReg. "N.B. FLAGS := SPReg - TempReg"
	self JumpBelow: stackOverflowCall.
	blockStart stackCheckLabel: (self annotateBytecode: self Label)
]

{ #category : #'compile abstract instructions' }
SimpleStackBasedCogit >> compileBlockFramelessEntry: blockStart [
	"Make sure ReceiverResultReg holds the receiver, loaded from the closure,
	 which is what is initially in ReceiverResultReg.  We must annotate the first
	 instruction in vanilla blocks so that findMethodForStartBcpc:inHomeMethod:
	 can function. We need two annotations because the first is a fiducial."
	<var: #blockStart type: #'BlockStart *'>
	blockStart entryLabel ifNotNil:
		[self annotateBytecode: blockStart entryLabel.
		 self annotateBytecode: blockStart entryLabel].
	blockStart hasInstVarRef
		ifTrue: "Use ReceiverResultReg for Context to agree with store check trampoline"
			[objectRepresentation
				genLoadSlot: ClosureOuterContextIndex
					sourceReg: ReceiverResultReg
						destReg: ReceiverResultReg;
				genLoadSlot: ReceiverIndex
					sourceReg: ReceiverResultReg
						destReg: Arg0Reg.
			objectRepresentation
				genEnsureOopInRegNotForwarded: Arg0Reg scratchReg: TempReg updatingSlot: ReceiverIndex in: ReceiverResultReg.
			self MoveR: Arg0Reg R: ReceiverResultReg]
		ifFalse:
			[objectRepresentation
				genLoadSlot: ClosureOuterContextIndex
					sourceReg: ReceiverResultReg
						destReg: TempReg;
				genLoadSlot: ReceiverIndex
					sourceReg: TempReg
						destReg: ReceiverResultReg].
]

{ #category : #'compile abstract instructions' }
SimpleStackBasedCogit >> compileFrameBuild [
	"Build a frame for a CogMethod activation.  See CoInterpreter class>>initializeFrameIndices.
	 		receiver (in ReceiverResultReg)
			arg0
			...
			argN
			caller's saved ip/this stackPage (for a base frame)
	fp->	saved fp
			method
			context (uninitialized?)
			receiver
			first temp
			...
	sp->	Nth temp
	If there is a primitive and an error code the Nth temp is the error code.
	Ensure SendNumArgsReg is set early on (incidentally to nilObj) because
	it is the flag determining whether context switch is allowed on stack-overflow."
	| jumpSkip |
	<inline: false>
	<var: #jumpSkip type: #'AbstractInstruction *'>
	needsFrame ifFalse: [^self].
	backEnd hasLinkRegister ifTrue: [self PushR: LinkReg].
	self PushR: FPReg.
	self MoveR: SPReg R: FPReg.
	methodLabel addDependent: (self annotateAbsolutePCRef:
		(self PushCw: methodLabel asInteger)). "method"
	self genMoveNilR: SendNumArgsReg.
	self PushR: SendNumArgsReg. "context"
	self PushR: ReceiverResultReg.
	methodOrBlockNumArgs + 1 to: (coInterpreter temporaryCountOfMethodHeader: methodHeader) do:
		[:i|
		self PushR: SendNumArgsReg].
	(self methodUsesPrimitiveErrorCode: methodObj header: methodHeader) ifTrue:
		[self compileGetErrorCode].
	self MoveAw: coInterpreter stackLimitAddress R: TempReg.
	self CmpR: TempReg R: SPReg. "N.B. FLAGS := SPReg - TempReg"
	"If we can't context switch for this method, use a slightly
	 slower overflow check that clears SendNumArgsReg."
	(coInterpreter canContextSwitchIfActivating: methodObj header: methodHeader)
		ifTrue:
			[self JumpBelow: stackOverflowCall.
			 stackCheckLabel := self Label]
		ifFalse:
			[jumpSkip := self JumpAboveOrEqual: 0.
			 self MoveCq: 0 R: SendNumArgsReg.
			 self Jump: stackOverflowCall.
			 jumpSkip jmpTarget: (stackCheckLabel := self Label)].
	self annotateBytecode: stackCheckLabel
]

{ #category : #'compile abstract instructions' }
SimpleStackBasedCogit >> compileFullBlockFramelessEntry: numCopied [ 
	"Make sure ReceiverResultReg holds the receiver, loaded from the closure,
	 which is what is initially in ReceiverResultReg.  "
	self flag: #TODO. "we could follow the receiver only if the block has inst var ref. Currently we use scanMethod for fullBlock 
	and that scanner does not provide this information. We could extend it based on the scanBlock: method"
	"Use ReceiverResultReg for the closure to agree with store check trampoline"
	objectRepresentation
		genLoadSlot: FullClosureReceiverIndex
			sourceReg: ReceiverResultReg
				destReg: Arg0Reg.
	objectRepresentation
		genEnsureOopInRegNotForwarded: Arg0Reg scratchReg: TempReg updatingSlot: FullClosureReceiverIndex in: ReceiverResultReg.
	self MoveR: Arg0Reg R: ReceiverResultReg.
]

{ #category : #'compile abstract instructions' }
SimpleStackBasedCogit >> compileFullBlockMethodFrameBuild: numCopied [
	"Build a frame for a block activation.  See CoInterpreter class>>initializeFrameIndices.
	 		closure (in ReceiverResultReg)
			arg0
			...
			argN
			caller's saved ip/this stackPage (for a base frame)
	fp->	saved fp
			method
			context (uninitialized?)
			receiver
			first temp
			...
	sp->	Nth temp
	Avoid use of SendNumArgsReg which is the flag determining whether
	context switch is allowed on stack-overflow."
	<inline: false>
	needsFrame ifFalse: [^self].
	backEnd hasLinkRegister ifTrue: [self PushR: LinkReg].
	self PushR: FPReg.
	self MoveR: SPReg R: FPReg.
	"Think of ClassReg as ClosureReg"
	self MoveR: ReceiverResultReg R: ClassReg.
	"The block method field must have its MFMethodFlagIsBlockFlag bit set.
	 We arrange this using a labelOffset.  A hack, but it works."
	methodLabel addDependent: (self annotateAbsolutePCRef:
			(self PushCw: methodLabel asInteger));
			setLabelOffset: MFMethodFlagIsBlockFlag.. "method"
	self genMoveNilR: SendNumArgsReg.
	self PushR: SendNumArgsReg. "context"
	"Closure is on stack and initially in ReceiverResultReg.
	 It is safe to use Arg0Reg because reg args are pushed by the value primitives if there are any.".

	self flag: #TODO. "we could follow the receiver only if the block has inst var ref. Currently we use scanMethod for fullBlock 
	and that scanner does not provide this information. We could extend it based on the scanBlock: method"
	"Use ReceiverResultReg for the closure to agree with store check trampoline"
	objectRepresentation
		genLoadSlot: FullClosureReceiverIndex
			sourceReg: ClassReg
				destReg: Arg0Reg.
	objectRepresentation
		genEnsureOopInRegNotForwarded: Arg0Reg scratchReg: TempReg updatingSlot: FullClosureReceiverIndex in: ReceiverResultReg.
	self MoveR: Arg0Reg R: ReceiverResultReg.

	self PushR: ReceiverResultReg. "closure receiver"
	"Push copied values"
	0 to: numCopied - 1 do:
		[:i|
		objectRepresentation
			genLoadSlot: i + FullClosureFirstCopiedValueIndex
			sourceReg: ClassReg
			destReg: TempReg.
		self PushR: TempReg].
	"Push slots for temps"
	methodOrBlockNumArgs + numCopied + 1 to: (coInterpreter temporaryCountOfMethodHeader: methodHeader) do:
		[:i|
		self PushR: SendNumArgsReg].
	
	self MoveAw: coInterpreter stackLimitAddress R: TempReg.
	self CmpR: TempReg R: SPReg. "N.B. FLAGS := SPReg - TempReg"
	self JumpBelow: stackOverflowCall.
	stackCheckLabel := (self annotateBytecode: self Label)
]

{ #category : #'compile abstract instructions' }
SimpleStackBasedCogit >> compileGetErrorCode [
	"After pushing the temporaries but before the stack limit check a primitive method
	 needs to fetch the error code, if any.  If the primitive has failed, call the trampoline
	 that will assign it to the last temp."
	<inline: false>
	| jmpNoError |
	<var: #jmpNoError type: #'AbstractInstruction *'>
	self MoveAw: coInterpreter primFailCodeAddress R: TempReg.
	self flag: 'ask concrete code gen if move sets condition codes?'.
	self CmpCq: 0 R: TempReg.
	jmpNoError := self JumpZero: 0.
	methodLabel addDependent:
		(self annotateAbsolutePCRef:
			(self MoveCw: methodLabel asInteger R: ClassReg)).
	self CallRT: ceReapAndResetErrorCodeTrampoline.
	jmpNoError jmpTarget: self Label
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> compileInterpreterPrimitive [
	<inline: true>
	| primitiveRoutine |
	<var: #primitiveRoutine declareC: 'void (*primitiveRoutine)(void)'>
	primitiveRoutine := coInterpreter
							functionPointerForCompiledMethod: methodObj
							primitiveIndex: primitiveIndex.
	^ self
		compileInterpreterPrimitive: primitiveRoutine
		flags: (coInterpreter primitivePropertyFlags: primitiveIndex)
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> compileInterpreterPrimitive: primitiveRoutine flags: flags [
	"Compile a call to an interpreter primitive.  Call the C routine with the
	 usual stack-switching dance, test the primFailCode and then either
	 return on success or continue to the method body."
	<var: #primitiveRoutine declareC: 'void (*primitiveRoutine)(void)'>
	| jmp jmpSamplePrim continuePostSamplePrim jmpSampleNonPrim continuePostSampleNonPrim |
	<var: #jmp type: #'AbstractInstruction *'>
	<var: #jmpSamplePrim type: #'AbstractInstruction *'>
	<var: #jmpSampleNonPrim type: #'AbstractInstruction *'>
	<var: #continuePostSamplePrim type: #'AbstractInstruction *'>
	<var: #continuePostSampleNonPrim type: #'AbstractInstruction *'>

	"Save processor fp, sp and return pc in the interpreter's frame stack and instruction pointers"
	self genExternalizePointersForPrimitiveCall.
	"Switch to the C stack."
	self genLoadCStackPointersForPrimCall.

	(flags anyMask: PrimCallCollectsProfileSamples) ifTrue:
		["Test nextProfileTick for being non-zero and call checkProfileTick if so"
		objectMemory wordSize = 4
			ifTrue:
				[self MoveAw: coInterpreter nextProfileTickAddress R: TempReg.
				 self MoveAw: coInterpreter nextProfileTickAddress + objectMemory wordSize R: ClassReg.
				 self OrR: TempReg R: ClassReg]
			ifFalse:
				[self MoveAw: coInterpreter nextProfileTickAddress R: TempReg.
				 self CmpCq: 0 R: TempReg].
		"If set, jump to record sample call."
		jmpSampleNonPrim := self JumpNonZero: 0.
		continuePostSampleNonPrim := self Label].

	"Old full prim trace is in VMMaker-eem.550 and prior"
	self recordPrimTrace ifTrue:
		[self genFastPrimTraceUsing: ClassReg and: SendNumArgsReg].

	"Clear the primFailCode and set argumentCount"
	self MoveCq: 0 R: TempReg.
	self MoveR: TempReg Aw: coInterpreter primFailCodeAddress.
	methodOrBlockNumArgs ~= 0 ifTrue:
		[self MoveCq: methodOrBlockNumArgs R: TempReg].
	self MoveR: TempReg Aw: coInterpreter argumentCountAddress.

	"If required, set primitiveFunctionPointer and newMethod"
	(flags anyMask: PrimCallNeedsPrimitiveFunction) ifTrue:
		[self MoveCw: primitiveRoutine asInteger R: TempReg.
		 primSetFunctionLabel :=
		 self MoveR: TempReg Aw: coInterpreter primitiveFunctionPointerAddress].
	(flags anyMask: PrimCallNeedsNewMethod+PrimCallMayCallBack) ifTrue:
		["The ceActivateFailingPrimitiveMethod: machinery can't handle framelessness."
		 (flags anyMask: PrimCallMayCallBack) ifTrue:
			[needsFrame := true].
		 methodLabel addDependent:
			(self annotateAbsolutePCRef:
				(self MoveCw: methodLabel asInteger R: ClassReg)).
		 self MoveMw: (self offset: CogMethod of: #methodObject) r: ClassReg R: TempReg.
		 self MoveR: TempReg Aw: coInterpreter newMethodAddress].

	"Invoke the primitive"
	self PrefetchAw: coInterpreter primFailCodeAddress.
	(flags anyMask: PrimCallMayCallBack)
		ifTrue: "Sideways call the C primitive routine so that we return through cePrimReturnEnterCogCode."
			["On Spur ceActivateFailingPrimitiveMethod: would like to retry if forwarders
			  are found. So insist on PrimCallNeedsPrimitiveFunction being set too."
			 self assert: (flags anyMask: PrimCallNeedsPrimitiveFunction).
			 backEnd
				genMarshallNArgs: 0 arg: 0 arg: 0 arg: 0 arg: 0;
				genSubstituteReturnAddress:
					((flags anyMask: PrimCallCollectsProfileSamples)
						ifTrue: [cePrimReturnEnterCogCodeProfiling]
						ifFalse: [cePrimReturnEnterCogCode]).
			 primInvokeInstruction := self JumpFullRT: primitiveRoutine asInteger.
			 jmp := jmpSamplePrim := continuePostSamplePrim := nil]
		ifFalse:
			["Call the C primitive routine."
			backEnd genMarshallNArgs: 0 arg: 0 arg: 0 arg: 0 arg: 0.
			primInvokeInstruction := self CallFullRT: primitiveRoutine asInteger.
			backEnd genRemoveNArgsFromStack: 0.
			(flags anyMask: PrimCallCollectsProfileSamples) ifTrue:
				[self assert: (flags anyMask: PrimCallNeedsNewMethod).
				"Test nextProfileTick for being non-zero and call checkProfileTick if so"
				objectMemory wordSize = 4
					ifTrue:
						[self MoveAw: coInterpreter nextProfileTickAddress R: TempReg.
						 self MoveAw: coInterpreter nextProfileTickAddress + objectMemory wordSize R: ClassReg.
						 self OrR: TempReg R: ClassReg]
					ifFalse:
						[self MoveAw: coInterpreter nextProfileTickAddress R: TempReg.
						 self CmpCq: 0 R: TempReg].
				"If set, jump to record sample call."
				jmpSamplePrim := self JumpNonZero: 0.
				continuePostSamplePrim := self Label].
			objectRepresentation maybeCompileRetryOnPrimitiveFail: primitiveIndex.
			self maybeCompileAllocFillerCheck.
			"Switch back to the Smalltalk stack.  Stack better be in either of these two states:
				success:	stackPointer ->	result (was receiver)
											arg1
											...
											argN
											return pc
				failure:						receiver
											arg1
											...
							stackPointer ->	argN
											return pc
			In either case we can push the instructionPointer or load it into the LinkRegister to reestablish the return pc"
			self MoveAw: coInterpreter instructionPointerAddress
				R: (backEnd hasLinkRegister ifTrue: [LinkReg] ifFalse: [ClassReg]).
			backEnd genLoadStackPointers.
			"Test primitive failure"
			self MoveAw: coInterpreter primFailCodeAddress R: TempReg.
			backEnd hasLinkRegister ifFalse: [self PushR: ClassReg]. "Restore return pc on CISCs"
			self flag: 'ask concrete code gen if move sets condition codes?'.
			self CmpCq: 0 R: TempReg.
			jmp := self JumpNonZero: 0.
			"Fetch result from stack"
			self MoveMw: (backEnd hasLinkRegister ifTrue: [0] ifFalse: [objectMemory wordSize])
				r: SPReg
				R: ReceiverResultReg.
			self RetN: objectMemory wordSize].	"return to caller, popping receiver"

	(flags anyMask: PrimCallCollectsProfileSamples) ifTrue:
		["The sample is collected by cePrimReturnEnterCogCode for external calls"
		jmpSamplePrim ifNotNil:
			["Call ceCheckProfileTick: to record sample and then continue."
			jmpSamplePrim jmpTarget: self Label.
			self assert: (flags anyMask: PrimCallNeedsNewMethod).
			self CallFullRT: (self cCode: [#ceCheckProfileTick asUnsignedIntegerPtr]
							   inSmalltalk: [self simulatedTrampolineFor: #ceCheckProfileTick]).
			"reenter the post-primitive call flow"
			self Jump: continuePostSamplePrim].
		"Null newMethod and call ceCheckProfileTick: to record sample and then continue.
		 ceCheckProfileTick will map null/0 to coInterpreter nilObject"
		jmpSampleNonPrim jmpTarget: self Label.
		self MoveCq: 0 R: TempReg.
		self MoveR: TempReg Aw: coInterpreter newMethodAddress.
		self CallFullRT: (self cCode: [#ceCheckProfileTick asUnsignedIntegerPtr]
						   inSmalltalk: [self simulatedTrampolineFor: #ceCheckProfileTick]).
		"reenter the post-primitive call flow"
		self Jump: continuePostSampleNonPrim].

	jmp ifNotNil:
		["Jump to restore of receiver reg and proceed to frame build for failure."
		 jmp jmpTarget: self Label.
		 "Restore receiver reg from stack.  If on RISCs ret pc is in LinkReg, if on CISCs ret pc is on stack."
		 self MoveMw: objectMemory wordSize * (methodOrBlockNumArgs + (backEnd hasLinkRegister ifTrue: [0] ifFalse: [1]))
			r: SPReg
			R: ReceiverResultReg].
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> compileMachineCodeInterpreterPrimitive: primitiveRoutine [
	"Compile a call to a machine-code convention interpreter primitive.  Call the C routine
	 on the Smalltalk stack, assuming it consumes little or no stack space."
	<var: #primitiveRoutine declareC: 'void (*primitiveRoutine)(void)'>
	| jmpFail liveRegsMask |
	

	"for now handle functions with less than 4 arguments; our C call marshalling machinery
	 extends up to 4 arguments only, and the first argument of an mcprim is the receiver."
	self assert: methodOrBlockNumArgs <= 3.
	liveRegsMask := (methodOrBlockNumArgs > self numRegArgs
					   or: [methodOrBlockNumArgs = 0])
						ifTrue:
							[self registerMaskFor: ReceiverResultReg]
						ifFalse:
							[(self numRegArgs > 1 and: [methodOrBlockNumArgs > 1])
								ifFalse: [self registerMaskFor: ReceiverResultReg and: Arg0Reg]
								ifTrue: [self registerMaskFor: ReceiverResultReg and: Arg0Reg and: Arg1Reg]].

	"As this is using a call, I need to store the Link register."
	backEnd hasLinkRegister 
		ifTrue: [ self MoveR: LinkReg R: Extra0Reg ].
	
	backEnd genSaveRegs: (liveRegsMask bitAnd: CallerSavedRegisterMask).
	methodOrBlockNumArgs > self numRegArgs ifTrue:
		["Wrangle args into Arg0Reg, Arg1Reg, SendNumArgsReg & ClassReg"
		 "offset := self bitCountOf: (liveRegsMask bitAnd: CallerSavedRegisterMask)."
		 self shouldBeImplemented].

	backEnd prepareStackToCallCFunctionInSmalltalkStack: methodOrBlockNumArgs + 1.
	
	backEnd
		genMarshallNArgs: methodOrBlockNumArgs + 1
		arg: ReceiverResultReg
		arg: Arg0Reg
		arg: Arg1Reg
		arg: SendNumArgsReg
		"arg: ClassReg (when we extend C call marchalling to support 5 args for replaceFrom:to:with:startingAt:".

	self CallFullRT: primitiveRoutine asInteger.

	backEnd
		genRemoveNArgsFromStack: methodOrBlockNumArgs + 1;
		returnFromCallCFunctionInSmalltalkStack: methodOrBlockNumArgs + 1;
		genRestoreRegs: (liveRegsMask bitAnd: CallerSavedRegisterMask).

	backEnd hasLinkRegister 
		ifTrue: [ self MoveR: Extra0Reg R: LinkReg ].

	self CmpCq: 0 R: backEnd cResultRegister.
	jmpFail := self JumpZero: 0.
	backEnd cResultRegister ~= ReceiverResultReg ifTrue:
		[self MoveR: backEnd cResultRegister R: ReceiverResultReg].
	self RetN: (methodOrBlockNumArgs > self numRegArgs
				ifTrue: [methodOrBlockNumArgs + 1 * objectMemory wordSize]
				ifFalse: [0]).
	jmpFail jmpTarget: self Label.
	^0
]

{ #category : #'in-line cacheing' }
SimpleStackBasedCogit >> compileOpenPIC: selector numArgs: numArgs [
	"Compile the code for an open PIC.  Perform a probe of the first-level method
	 lookup cache followed by a call of ceSendFromInLineCacheMiss: if the probe fails."
	| cacheBaseReg jumpSelectorMiss jumpClassMiss itsAHit jumpBCMethod |
	<var: #jumpSelectorMiss type: #'AbstractInstruction *'>
	<var: #jumpClassMiss type: #'AbstractInstruction *'>
	<var: #itsAHit type: #'AbstractInstruction *'>
	<var: #jumpBCMethod type: #'AbstractInstruction *'>
	self preenMethodLabel.
	self compilePICAbort: numArgs.
	entry := objectRepresentation genGetClassTagOf: ReceiverResultReg into: SendNumArgsReg scratchReg: TempReg.

	self flag: #lookupInMethodCacheSel:classTag:. "so this method shows up as a sender of lookupInMethodCacheSel:class:"

	cacheBaseReg := NoReg.
	(backEnd isWithinMwOffsetRange: coInterpreter methodCacheAddress) ifFalse:
		[self MoveCq: coInterpreter methodCacheAddress R: (cacheBaseReg := Extra0Reg)].

	"Do first of three probes.  See CoInterpreter>>lookupInMethodCacheSel:classTag:"
	jumpSelectorMiss := self compileOpenPICMethodCacheProbeFor: selector withShift: 0 baseRegOrNone: cacheBaseReg.
	jumpClassMiss := self JumpNonZero: 0.

	"Fetch the method.  The interpret trampoline requires the bytecoded method in SendNumArgsReg"
	itsAHit := self MoveMw: (cacheBaseReg = NoReg
								ifTrue: [coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheMethod << objectMemory shiftForWord)]
								ifFalse: [MethodCacheMethod << objectMemory shiftForWord])
					r: ClassReg
					R: SendNumArgsReg.
			.
	"If the method is compiled jump to its unchecked entry-point, otherwise interpret it."
	objectRepresentation genLoadSlot: HeaderIndex sourceReg: SendNumArgsReg destReg: ClassReg.
	jumpBCMethod := objectRepresentation genJumpImmediate: ClassReg.
	jumpBCMethod jmpTarget: picInterpretAbort.
	self AddCq: cmNoCheckEntryOffset R: ClassReg.
	self JumpR: ClassReg.

	"First probe missed.  Do second of three probes.  Shift hash right one and retry."
	jumpSelectorMiss jmpTarget: (jumpClassMiss jmpTarget: self Label).
	jumpSelectorMiss := self compileOpenPICMethodCacheProbeFor: selector withShift: 1 baseRegOrNone: cacheBaseReg.
	self JumpZero: itsAHit.

	"Second probe missed.  Do last probe.  Shift hash right two and retry."
	jumpSelectorMiss jmpTarget: self Label.
	jumpSelectorMiss := self compileOpenPICMethodCacheProbeFor: selector withShift: 2 baseRegOrNone: cacheBaseReg.
	self JumpZero: itsAHit.

	"Last probe missed.  Call ceSendFromInLineCacheMiss: to do the full lookup."
	jumpSelectorMiss jmpTarget: self Label.
	self numRegArgs > 0 ifTrue:
		[backEnd genPushRegisterArgsForNumArgs: numArgs scratchReg: SendNumArgsReg].
	self genSmalltalkToCStackSwitch: true.
	methodLabel addDependent: (self annotateAbsolutePCRef: (self MoveCw: methodLabel asInteger R: SendNumArgsReg)).
	self 
		compileCallFor: #ceSendFromInLineCacheMiss:
		numArgs: 1
		arg: SendNumArgsReg
		arg: nil
		arg: nil
		arg: nil
		resultReg: NoReg
		regsToSave: self emptyRegisterMask
	"Note that this call does not return."
]

{ #category : #'in-line cacheing' }
SimpleStackBasedCogit >> compileOpenPICMethodCacheProbeFor: selector withShift: shift baseRegOrNone: baseRegOrNone [
	"Compile one method cache probe in an OpenPIC's lookup of selector.
	 Answer the jump taken if the selector probe fails.
	 The class tag of the receiver must be in SendNumArgsReg.  ClassReg and TempReg are used as scratch registers.
	 On a hit, the offset of the entry is in ClassReg."
	<returnTypeC: #'AbstractInstruction *'>
	<inline: false>
	| jumpSelectorMiss |
	<var: 'jumpSelectorMiss' type: #'AbstractInstruction *'>
	self MoveR: SendNumArgsReg R: ClassReg.
	objectRepresentation maybeShiftClassTagRegisterForMethodCacheProbe: ClassReg.
	self annotate: (self XorCw: selector R: ClassReg) objRef: selector.
	self assert: shift <= objectMemory shiftForWord.
	"Need to shift the hash right by shift to form the probe, and then shift the probe left by shiftForWord to form the index.
	 So shift left by shiftForWord - shift and and with the shifted mask."
	shift < objectMemory shiftForWord ifTrue:
		[self LogicalShiftLeftCq: objectMemory shiftForWord - shift R: ClassReg].
	self AndCq: MethodCacheMask << objectMemory shiftForWord R: ClassReg.
	baseRegOrNone = NoReg
		ifTrue:
			[self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheSelector << objectMemory shiftForWord)
				r: ClassReg
				R: TempReg]
		ifFalse:
			[self AddR: baseRegOrNone R: ClassReg;
				MoveMw: MethodCacheSelector << objectMemory shiftForWord r: ClassReg R: TempReg].
	self annotate: (self CmpCw: selector R: TempReg) objRef: selector.
	jumpSelectorMiss := self JumpNonZero: 0.
	baseRegOrNone = NoReg
		ifTrue:
			[self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheClass << objectMemory shiftForWord)
				r: ClassReg
				R: TempReg]
		ifFalse:
			[self MoveMw: MethodCacheClass << objectMemory shiftForWord r: ClassReg R: TempReg].
	self CmpR: SendNumArgsReg R: TempReg.
	^jumpSelectorMiss
]

{ #category : #'in-line cacheing' }
SimpleStackBasedCogit >> compilePerformMethodCacheProbeFor: selectorReg withShift: shift baseRegOrNone: baseRegOrNone [
	"Compile one method cache probe in a perform: primitive's lookup of selector.
	 Answer the jump taken if the selector probe fails."
	<returnTypeC: #'AbstractInstruction *'>
	<inline: false>
	| jumpSelectorMiss |
	<var: 'jumpSelectorMiss' type: #'AbstractInstruction *'>
	self MoveR: SendNumArgsReg R: ClassReg.
	objectRepresentation maybeShiftClassTagRegisterForMethodCacheProbe: ClassReg.
	self XorR: selectorReg R: ClassReg.
	self assert: shift <= objectMemory shiftForWord.
	"Need to shift the hash right by shift to form the probe, and then shift the probe left by shiftForWord to form the index.
	 So shift left by shiftForWord - shift and and with the shifted mask."
	shift < objectMemory shiftForWord ifTrue:
		[self LogicalShiftLeftCq: objectMemory shiftForWord - shift R: ClassReg].
	self AndCq: MethodCacheMask << objectMemory shiftForWord R: ClassReg.
	baseRegOrNone = NoReg
		ifTrue:
			[self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheSelector << objectMemory shiftForWord)
				r: ClassReg
				R: TempReg]
		ifFalse:
			[self AddR: baseRegOrNone R: ClassReg;
				MoveMw: MethodCacheSelector << objectMemory shiftForWord r: ClassReg R: TempReg].
	self CmpR: selectorReg R: TempReg.
	jumpSelectorMiss := self JumpNonZero: 0.
	baseRegOrNone = NoReg
		ifTrue:
			[self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheClass << objectMemory shiftForWord)
				r: ClassReg
				R: TempReg]
		ifFalse:
			[self MoveMw: MethodCacheClass << objectMemory shiftForWord r: ClassReg R: TempReg].
	self CmpR: SendNumArgsReg R: TempReg.
	^jumpSelectorMiss
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> compilePrimitive [
	"Compile a primitive.  If possible, performance-critical primtiives will
	 be generated by their own routines (primitiveGenerator).  Otherwise,
	 if there is a primitive at all, we call the C routine with the usual
	 stack-switching dance, test the primFailCode and then either return
	 on success or continue to the method body."
	<inline: false>
	| code opcodeIndexAtPrimitive primitiveDescriptor primitiveRoutine flags |
	<var: #primitiveDescriptor type: #'PrimitiveDescriptor *'>
	<var: #primitiveRoutine declareC: 'void (*primitiveRoutine)(void)'>

	primitiveIndex = 0 ifTrue: [^0].
	code := 0.
	"Note opcodeIndex so that compileFallbackToInterpreterPrimitive:
	 can discard arg load instructions for unimplemented primitives."
	opcodeIndexAtPrimitive := opcodeIndex.
	"If a descriptor specifies an argument count (by numArgs >= 0) then it must match
	 for the generated code to be correct.  For example for speed many primitives use
	 ResultReceiverReg instead of accessing the stack, so the receiver better be at
	 numArgs down the stack.  Use the interpreter version if not."
	((primitiveDescriptor := self primitiveGeneratorOrNil) notNil
	 and: [primitiveDescriptor primitiveGenerator notNil
	 and: [(primitiveDescriptor primNumArgs < 0 "means don't care"
		   or: [primitiveDescriptor primNumArgs = (coInterpreter argumentCountOf: methodObj)])]]) ifTrue:
		[code := objectRepresentation perform: primitiveDescriptor primitiveGenerator].
	(code < 0 and: [code ~= UnimplementedPrimitive]) ifTrue: "Generator failed, so no point continuing..."
		[^code].
	code = UnfailingPrimitive ifTrue:
		[^0].
	"If the machine code verison handles all cases the only reason to call the interpreter
	 primitive is to reap the primitive error code.  Don't bother if it isn't used."
	(code = CompletePrimitive
	 and: [(self methodUsesPrimitiveErrorCode: methodObj header: methodHeader) not]) ifTrue:
		[^0].
	"Discard any arg load code generated by the primitive generator."
	code = UnimplementedPrimitive ifTrue:
		[opcodeIndex := opcodeIndexAtPrimitive].

	flags := coInterpreter primitivePropertyFlags: primitiveIndex.
	(flags anyMask: PrimCallDoNotJIT) ifTrue:
		[^ShouldNotJIT].

	(flags anyMask: PrimCallOnSmalltalkStack) ifTrue:
		[self assert: flags = PrimCallOnSmalltalkStack.
		 ^self compileMachineCodeInterpreterPrimitive: (coInterpreter mcprimFunctionForPrimitiveIndex: primitiveIndex)].

	((primitiveRoutine := coInterpreter
							functionPointerForCompiledMethod: methodObj
							primitiveIndex: primitiveIndex) = 0 "no primitive"
	or: [primitiveRoutine = #primitiveFail]) ifTrue:
		[^self genFastPrimFail].
	minValidCallAddress := minValidCallAddress min: primitiveRoutine asUnsignedInteger.
	^self compileInterpreterPrimitive: primitiveRoutine flags: flags
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> doubleExtendedDoAnythingBytecode [
	"Replaces the Blue Book double-extended send [132], in which the first byte was wasted on 8 bits of argument count. 
	Here we use 3 bits for the operation sub-type (opType),  and the remaining 5 bits for argument count where needed. 
	The last byte give access to 256 instVars or literals. 
	See also secondExtendedSendBytecode"
	| opType |
	opType := byte1 >> 5.
	opType = 0 ifTrue:
		[^self genSend: byte2 numArgs: (byte1 bitAnd: 31)].
	opType = 1 ifTrue:
		[^self genSendSuper: byte2 numArgs: (byte1 bitAnd: 31)].
	"We need a map entry for this bytecode for correct parsing.
	 The sends will get an IsSend entry anyway.  The other cases need a fake one."
	opType caseOf: {
			[2]	->	[(coInterpreter isReadMediatedContextInstVarIndex: byte2)
						ifTrue: [self genPushMaybeContextReceiverVariable: byte2]
						ifFalse: [self genPushReceiverVariable: byte2]].
			[3]	->	[self genPushLiteralIndex: byte2].
			[4]	->	[self genPushLiteralVariable: byte2].
			[7]	->	[self genStorePop: false LiteralVariable: byte2.
					 self cppIf: IMMUTABILITY ifTrue: ["genStorePop:LiteralVariable: annotates; don't annotate twice" ^0]] }
		otherwise: "5 & 6"
			[(coInterpreter isWriteMediatedContextInstVarIndex: byte2)
				ifTrue: [self genStorePop: opType = 6 MaybeContextReceiverVariable: byte2]
				ifFalse: [self genStorePop: opType = 6 ReceiverVariable: byte2].
			 self cppIf: IMMUTABILITY ifTrue: ["genStorePop:...ReceiverVariable: annotate; don't annotate twice" ^0]].
	"We need a map entry for this bytecode for correct parsing (if the method builds a frame)."
	needsFrame ifTrue:
		[self annotateBytecode: self Label].
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> duplicateTopBytecode [
	self MoveMw: 0 r: SPReg R: TempReg.
	self PushR: TempReg.
	^0
]

{ #category : #'*VMMaker-Tests' }
SimpleStackBasedCogit >> entryOffset: anInteger [ 
	<doNotGenerate>
	cmEntryOffset := anInteger
]

{ #category : #'trampoline support' }
SimpleStackBasedCogit >> evaluateTrampolineCallBlock: block protectLinkRegIfNot: inFrame [
	<inline: true>
	inFrame 
		ifFalse: 
			[ backEnd saveAndRestoreLinkRegAround: [ block value ] ]
		ifTrue:
			[ block value ].
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> extendedPushBytecode [
	| variableType variableIndex |
	variableType := (byte1 >> 6) bitAnd: 16r3.
	variableIndex := byte1 bitAnd: 16r3F.
	variableType = 0 ifTrue:
		[^self genPushReceiverVariable: variableIndex].
	variableType = 1 ifTrue:
		[^self genPushTemporaryVariable: variableIndex].
	variableType = 2 ifTrue:
		[^self genPushLiteralIndex: variableIndex].
	^self genPushLiteralVariable: variableIndex
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> extendedStoreAndPopBytecode [
	| variableType variableIndex |
	variableType := byte1 >> 6 bitAnd: 3.
	variableIndex := byte1 bitAnd: 63.
	variableType = 0 ifTrue:
		[^self genStorePop: true ReceiverVariable: variableIndex].
	variableType = 1 ifTrue:
		[self genStorePop: true TemporaryVariable: variableIndex.
		"needs a fake map entry if Immutability is ON..."
		self cppIf: IMMUTABILITY ifTrue: [ self annotateBytecode: self Label. ].
		^ 0].
	variableType = 3 ifTrue:
		[^self genStorePop: true LiteralVariable: variableIndex].
	^EncounteredUnknownBytecode
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> extendedStoreBytecode [
	| variableType variableIndex |
	variableType := byte1 >> 6 bitAnd: 3.
	variableIndex := byte1 bitAnd: 63.
	variableType = 0 ifTrue:
		[^self genStorePop: false ReceiverVariable: variableIndex].
	variableType = 1 ifTrue:
		[self genStorePop: false TemporaryVariable: variableIndex.
		"needs a fake map entry if Immutability is ON..."
		self cppIf: IMMUTABILITY ifTrue: [ self annotateBytecode: self Label. ].
		^ 0].
	variableType = 3 ifTrue:
		[^self genStorePop: false LiteralVariable: variableIndex].
	^EncounteredUnknownBytecode
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> firstSpecialSelectorBytecodeOffset [
	<inline: true>
	^self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [bytecodeSetOffset = 256 ifTrue: [AltFirstSpecialSelector + 256] ifFalse: [FirstSpecialSelector]]
		ifFalse: [FirstSpecialSelector]
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> frameOffsetOfTemporary: index [
	^self frameOffsetOfTemporary: index numArgs: methodOrBlockNumArgs
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> frameOffsetOfTemporary: index numArgs: numArgs [
	<inline: true>
	^index < numArgs
		ifTrue: [FoxCallerSavedIP + ((numArgs - index) * objectMemory wordSize)]
		ifFalse: [FoxMFReceiver - objectMemory wordSize + ((numArgs - index) * objectMemory wordSize)]
]

{ #category : #accessing }
SimpleStackBasedCogit >> fullBlockEntryOffset [
	<api>
	<cmacro>
	^cbEntryOffset
]

{ #category : #accessing }
SimpleStackBasedCogit >> fullBlockNoContextSwitchEntryOffset [
	<api>
	<cmacro>
	^cbNoSwitchEntryOffset
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genBlockReturn [
	"Return from block, assuming result already loaded into ReceiverResultReg."
	needsFrame ifTrue:
		[self MoveR: FPReg R: SPReg.
		 self PopR: FPReg.
		 backEnd hasLinkRegister ifTrue:
			[self PopR: LinkReg]].
	self RetN: methodOrBlockNumArgs + 1 * objectMemory wordSize.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genCallMappedInlinedPrimitive [
	"Implemented with SistaCogit only"
	^EncounteredUnknownBytecode
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genCallPrimitiveBytecode [
	"V3PlusClosures:	139 10001011	iiiiiiii   jjjjjjjj  Call Primitive #iiiiiiii + (jjjjjjjj * 256)
	 NewsqueakV4:		249 11111001	iiiiiiii   jjjjjjjj  Call Primitive #iiiiiiii + (jjjjjjjj * 256)
	 SistaV1:			248 11111000 iiiiiiii mjjjjjjj  Call Primitive #iiiiiiii + ( jjjjjjj * 256)
							m=1 means inlined primitive, no hard return after execution."
	(bytecodePC = initialPC and: [byte2 < 128]) ifFalse: [^EncounteredUnknownBytecode].
	^0
]

{ #category : #'constant support' }
SimpleStackBasedCogit >> genCmpConstant: constant R: register [
	"If the objectMemory allows it, generates a quick constant cmp, else generates a word constant cmp"
	<inline: true>
	^ (objectRepresentation shouldAnnotateObjectReference: constant)
		ifTrue: [ self annotate: (self CmpCw: constant R: register) objRef: constant ]
		ifFalse: [ self CmpCq: constant R: register ]
	
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genDoubleFailIfZeroArgRcvr: rcvrReg arg: argReg [
	<option: #DPFPReg0>
	<var: 'rcvrReg' type: #int>
	<var: 'argReg' type: #int>
	<returnTypeC: #'AbstractInstruction *'>
	self MoveCq: 0 R: TempReg.
	self ConvertR: TempReg Rd: DPFPReg2.
	self CmpRd: DPFPReg2 Rd: argReg.
	^self JumpFPEqual: 0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtJumpIfFalse [
	"244		11110100	i i i i i i i i	Pop and Jump 0n False i i i i i i i i (+ Extend B * 256, where Extend B >= 0)"
	| distance target |
	distance := byte1 + (extB << 8).
	self assert: distance = (self v4: (self generatorAt: byte0)
								LongForward: bytecodePC
								Branch: (extA ~= 0 ifTrue: [1] ifFalse: [0]) + (extB ~= 0 ifTrue: [1] ifFalse: [0])
								Distance: methodObj).
	extB := 0.
	numExtB := 0.
	target := distance + 2 + bytecodePC.
	^self genJumpIf: objectMemory falseObject to: target
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtJumpIfTrue [
	"243		11110011	i i i i i i i i	Pop and Jump 0n True i i i i i i i i (+ Extend B * 256, where Extend B >= 0)"
	| distance target |
	distance := byte1 + (extB << 8).
	self assert: distance = (self v4: (self generatorAt: byte0)
								LongForward: bytecodePC
								Branch: (extA ~= 0 ifTrue: [1] ifFalse: [0]) + (extB ~= 0 ifTrue: [1] ifFalse: [0])
								Distance: methodObj).
	extB := 0.
	numExtB := 0.
	target := distance + 2 + bytecodePC.
	^self genJumpIf: objectMemory trueObject to: target
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtNopBytecode [
	"SistaV1:		 91		01011011'		Nop"
	extA := numExtB := extB := 0.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtPushCharacterBytecode [
	"SistaV1:		233		11101001	iiiiiiii		Push Character #iiiiiiii (+ Extend B * 256)"
	| value |
	value := byte1 + (extB << 8).
	extB := 0.
	numExtB := 0.
	^self genPushLiteral: (objectMemory characterObjectOf: value)
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtPushClosureBytecode [
	"Block compilation.  At this point in the method create the block.  Note its start
	 and defer generating code for it until after the method and any other preceding
	 blocks.  The block's actual code will be compiled later."
	"253		11111101 eei i i kkk	jjjjjjjj		Push Closure Num Copied iii (+ Ext A // 16 * 8) Num Args kkk (+ Ext A \\ 16 * 8) BlockSize jjjjjjjj (+ Ext B * 256). ee = num extensions"
	| startpc numArgs numCopied |
	self assert: needsFrame.
	startpc := bytecodePC + (self generatorAt: byte0) numBytes.
	self addBlockStartAt: startpc "0 relative"
		numArgs: (numArgs := (byte1 bitAnd: 16r7) + (extA \\ 16 * 8))
		numCopied: (numCopied := ((byte1 >> 3) bitAnd: 7) + (extA // 16 * 8))
		span: byte2 + (extB << 8).
	extA := numExtB := extB := 0.
	objectRepresentation
		genCreateClosureAt: startpc + 1 "1 relative"
		numArgs: numArgs
		numCopied: numCopied
		contextNumArgs: methodOrBlockNumArgs
		large: (coInterpreter methodNeedsLargeContext: methodObj)
		inBlock: inBlock.
	self PushR: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtPushFullClosureBytecode [
	"Full Block creation compilation. The block's actual code will be compiled separatedly."
	"*	255		11111111	xxxxxxxx	siyyyyyy	push Closure Compiled block literal index xxxxxxxx (+ Extend A * 256) numCopied yyyyyy receiverOnStack: s = 1 ignoreOuterContext: i = 1"
	| numCopied ignoreContext receiverIsOnStack compiledBlock |
	self assert: needsFrame.
	compiledBlock := self getLiteral: byte1 + (extA << 8).
	extA := 0.
	numCopied := byte2 bitAnd: 1<< 6 - 1.
	receiverIsOnStack := byte2 anyMask: 1 << 7.
	ignoreContext := byte2 anyMask: 1 << 6.
	objectRepresentation
		genCreateFullClosure: compiledBlock
		numArgs: (coInterpreter argumentCountOf: compiledBlock)
		numCopied: numCopied
		ignoreContext: ignoreContext
		contextNumArgs: methodOrBlockNumArgs
		large: (coInterpreter methodNeedsLargeContext: methodObj)
		inBlock: inBlock.
	"Closure in ReceiverResultReg"
	1 to: numCopied do:
		[:i|
		self
			PopR: TempReg;
			MoveR: TempReg
				Mw: numCopied - i + FullClosureFirstCopiedValueIndex * objectMemory bytesPerOop + objectMemory baseHeaderSize
					r: ReceiverResultReg].
	receiverIsOnStack
		ifTrue: [self PopR: TempReg]
		ifFalse: [ self MoveMw: FoxMFReceiver r: FPReg R: TempReg].
	self
		MoveR: TempReg
		Mw: FullClosureReceiverIndex * objectMemory bytesPerOop + objectMemory baseHeaderSize
		r: ReceiverResultReg.
	self PushR: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtPushIntegerBytecode [
	"NewsqueakV4:	229		11100101	iiiiiiii	Push Integer #iiiiiiii (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)
	SistaV1:		232		11101000	iiiiiiii	Push Integer #iiiiiiii (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	| value |
	value := byte1 + (extB << 8).
	extB := 0.
	numExtB := 0.
	^self genPushLiteral: (objectMemory integerObjectOf: value)
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtPushLiteralBytecode [
	"228		11100100	i i i i i i i i	Push Literal #iiiiiiii (+ Extend A * 256)"
	| index |
	index := byte1 + (extA << 8).
	extA := 0.
	^self genPushLiteralIndex: index
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtPushLiteralVariableBytecode [
	"227		11100011	i i i i i i i i	Push Literal Variable #iiiiiiii (+ Extend A * 256)"
	| index |
	index := byte1 + (extA << 8).
	extA := 0.
	^self genPushLiteralVariable: index
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtPushPseudoVariable [
	"SistaV1: *	82			01010010			Push thisContext, (then Extend B = 1 => push thisProcess)"
	| ext |
	ext := extB.
	extB := 0.
	numExtB := 0.
	ext caseOf: {
		[0]	->	[^self genPushActiveContextBytecode].
		}
		otherwise:
			[^self unknownBytecode].
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtPushPseudoVariableOrOuterBytecode [
	"77			01001101		Push false [* 1:true, 2:nil, 3:thisContext, ..., -N: pushEnclosingObjectAt: N, N = Extend B]"
	| ext |
	ext := extB.
	extB := 0.
	numExtB := 0.
	ext caseOf: {
		[0]	->	[^self genPushLiteral: objectMemory falseObject].
		[1]	->	[^self genPushLiteral: objectMemory trueObject].
		[2]	->	[^self genPushLiteral: objectMemory nilObject].
		[3]	->	[^self genPushActiveContextBytecode]
		}
		otherwise:
			[ext < 0 ifTrue:
				[^self genPushEnclosingObjectAt: 0 - ext].
			 self warning: 'undefined extension for extPushPseudoVariableOrOuter'.
			 ^self unknownBytecode].
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtPushReceiverVariableBytecode [
	"226		11100010	i i i i i i i i	Push Receiver Variable #iiiiiiii (+ Extend A * 256)"
	| index |
	index := byte1 + (extA << 8).
	extA := 0.
	^(coInterpreter isReadMediatedContextInstVarIndex: index)
		ifTrue: [self genPushMaybeContextReceiverVariable: index]
		ifFalse: [self genPushReceiverVariable: index]
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtPushRemoteTempOrInstVarLongBytecode [
	| index |
	^ (byte2 noMask: coInterpreter remoteIsInstVarAccess)
		ifTrue: [ self genPushRemoteTempLongBytecode ]
		ifFalse: 
			[ index := byte1 + (extA << 8).
			extA := 0.
			extB := 0. "don't use flags in the simple cogit"
			numExtB := 0.
			(coInterpreter isReadMediatedContextInstVarIndex: index)
				ifTrue: [self 
							genPushMaybeContextRemoteInstVar: index 
							inObjectAt: byte2 - coInterpreter remoteIsInstVarAccess]
				ifFalse: [self 
							genPushRemoteInstVar: index 
							inObjectAt: byte2 - coInterpreter remoteIsInstVarAccess]]
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtReturnTopFromBlock [
	"218		11011010		Return Stack Top From Block [* return from enclosing block N, N = Extend A]
	 If extA is zero, return to the caller of the current block activation.
	 If extA is non-zero return to the caller of the Nth enclosing block activation."
	extA = 0 ifTrue:
		[^self genReturnTopFromBlock].
	self shouldBeImplemented.
	extA := 0.
	^EncounteredUnknownBytecode
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtSendBytecode [
	"238		11101110	i i i i i j j j	Send Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	| litIndex nArgs |
	litIndex := (byte1 >> 3) + (extA << 5).
	extA := 0.
	nArgs := (byte1 bitAnd: 7) + (extB << 3).
	extB := 0.
	numExtB := 0.
	^self genSend: litIndex numArgs: nArgs
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtSendSuperBytecode [
	"239		11101111	i i i i i j j j	Send To Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	| isDirected litIndex nArgs |
	(isDirected := extB >= 64) ifTrue:
		[extB := extB bitAnd: 63].
	litIndex := (byte1 >> 3) + (extA << 5).
	extA := 0.
	nArgs := (byte1 bitAnd: 7) + (extB << 3).
	extB := 0.
	numExtB := 0.
	^isDirected
		ifTrue: [self genSendDirectedSuper: litIndex numArgs: nArgs]
		ifFalse: [self genSendSuper: litIndex numArgs: nArgs]
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtStoreAndPopLiteralVariableBytecode [
	"236		11101100	i i i i i i i i	Pop and Store Literal Variable #iiiiiiii (+ Extend A * 256)"
	| index |
	index := byte1 + (extA << 8).
	extA := 0.
	^self genStorePop: true LiteralVariable: index
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtStoreAndPopReceiverVariableBytecode [
	"235		11101011	i i i i i i i i	Pop and Store Receiver Variable #iiiiiii (+ Extend A * 256)"
	| index |
	index := byte1 + (extA << 8).
	extA := 0.
	^(coInterpreter isWriteMediatedContextInstVarIndex: index)
		ifTrue: [self genStorePop: true MaybeContextReceiverVariable: index]
		ifFalse: [self genStorePop: true ReceiverVariable: index]
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtStoreAndPopRemoteTempOrInstVarLongBytecode [
	^ self genExtStorePopRemoteTempOrInstVarLongBytecodePopBoolean: true
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtStoreLiteralVariableBytecode [
	"233		11101001	i i i i i i i i	Store Literal Variable #iiiiiiii (+ Extend A * 256)"
	| index |
	index := byte1 + (extA << 8).
	extA := 0.
	^self genStorePop: false LiteralVariable: index
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtStorePopRemoteTempOrInstVarLongBytecodePopBoolean: popBoolean [
	| index |
	extB := 0. "simple cogit don't use the extra flag"
	numExtB := 0.
	(byte2 noMask: coInterpreter remoteIsInstVarAccess)
		ifTrue: 
			[ self genStorePop: popBoolean RemoteTemp: byte1 At: byte2.
			self cppIf: IMMUTABILITY ifTrue: [ self annotateBytecode: self Label ] ]
		ifFalse: 
			[ index := byte1 + (extA << 8).
			extA := 0.
			(coInterpreter isWriteMediatedContextInstVarIndex: index)
				ifTrue: [ self 
						genStorePop: popBoolean 
						MaybeContextRemoteInstVar: index 
						ofObjectAt: byte2 - coInterpreter remoteIsInstVarAccess ]
				ifFalse: [ self 
						genStorePop: popBoolean 
						RemoteInstVar: index 
						ofObjectAt: byte2 - coInterpreter remoteIsInstVarAccess  ] ].
	^ 0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtStoreReceiverVariableBytecode [
	"232		11101000	i i i i i i i i	Store Receiver Variable #iiiiiii (+ Extend A * 256)"
	| index |
	index := byte1 + (extA << 8).
	extA := 0.
	^(coInterpreter isWriteMediatedContextInstVarIndex: index)
		ifTrue: [self genStorePop: false MaybeContextReceiverVariable: index]
		ifFalse: [self genStorePop: false ReceiverVariable: index]
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtStoreRemoteTempOrInstVarLongBytecode [
	^ self genExtStorePopRemoteTempOrInstVarLongBytecodePopBoolean: false
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtTrapIfNotInstanceOfBehaviorsBytecode [
	"SistaV1: *	236		11101100	iiiiiiii		Trap If Not Instance Of Behavior/Array Of Behavior #iiiiiiii (+ Extend A * 256, where Extend A >= 0)"
	"This really only makes sense for the optimizing JITs"
	^EncounteredUnknownBytecode
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtUnconditionalJump [
	"242		11110010	i i i i i i i i	Jump i i i i i i i i (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	| distance target |
	distance := byte1 + (extB << 8).
	self assert: distance = (self v4: (self generatorAt: byte0)
								Long: bytecodePC
								Branch: (extA ~= 0 ifTrue: [1] ifFalse: [0]) + (extB ~= 0 ifTrue: [1] ifFalse: [0])
								Distance: methodObj).
	extB := 0.
	numExtB := 0.
	target := distance + 2 + bytecodePC.
	distance < 0 ifTrue:
		[^self genJumpBackTo: target].
	self genJumpTo: target.
	"The bytecode must be mapped since it can be either forward or backward, and
	  backwards branches must be mapped. So if forward, we need to map."
	self annotateBytecode: self lastOpcode.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtendedSendBytecode [
	"Can use any of the first 32 literals for the selector and pass up to 7 arguments."

	^self genSend: (byte1 bitAnd: 16r1F) numArgs: byte1 >> 5
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtendedSuperBytecode [
	^self genSendSuper: (byte1 bitAnd: 16r1F) numArgs: byte1 >> 5
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genFastPrimFail [
	primitiveIndex := 0.
	^UnfailingPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genFastPrimTraceUsing: r1 and: r2 [
	"Suport for compileInterpreterPrimitive.  Generate inline code so as to record the primitive
	 trace as fast as possible."
	backEnd byteReadsZeroExtend ifFalse:
		[self MoveCq: 0 R: r2].
	self MoveAb: coInterpreter primTraceLogIndexAddress R: r2.
	self MoveR: r2 R: r1.
	self AddCq: 1 R: r1.
	self MoveR: r1 Ab: coInterpreter primTraceLogIndexAddress.
	methodLabel addDependent:
		(self annotateAbsolutePCRef:
			(self MoveCw: methodLabel asInteger R: r1)).
	self MoveMw: (self offset: CogMethod of: #selector) r: r1 R: TempReg.
	self MoveCw: coInterpreter primTraceLogAddress asInteger R: r1.
	self MoveR: TempReg Xwr: r2 R: r1
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genInlinedIdenticalOrNotIf: orNot [
	| jumpNotEqual jumpPush |
	<var: #jumpNotEqual type: #'AbstractInstruction *'>
	<var: #jumpPush type: #'AbstractInstruction *'>
	self PopR: Arg0Reg.
	objectRepresentation
		genEnsureOopInRegNotForwarded: Arg0Reg
		scratchReg: TempReg.
	self MoveMw: 0 r: SPReg R: ClassReg.
	objectRepresentation
		genEnsureOopInRegNotForwarded: ClassReg
		scratchReg: TempReg.
	self CmpR: Arg0Reg R: ClassReg.
	jumpNotEqual := self genConditionalBranch: (orNot ifTrue: [JumpZero] ifFalse: [JumpNonZero]) operand: 0.
	self annotate: (self genMoveTrueR: Arg0Reg)
		objRef: objectMemory trueObject.
	jumpPush := self Jump: 0.
	jumpNotEqual jmpTarget: (self genMoveFalseR: Arg0Reg).
	jumpPush jmpTarget: (self MoveR: Arg0Reg Mw: 0 r: SPReg).
	^0
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genJumpBackTo: targetBytecodePC [
	self MoveAw: coInterpreter stackLimitAddress R: TempReg.
	self CmpR: TempReg R: SPReg. "N.B. FLAGS := SPReg - TempReg"
	self JumpAboveOrEqual: (self fixupAt: targetBytecodePC).
	self CallRT: ceCheckForInterruptTrampoline.
	self annotateBytecode: self Label.
	self Jump: (self fixupAt: targetBytecodePC).
	^0
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genJumpIf: boolean to: targetBytecodePC [
	<inline: false>
	"Cunning trick by LPD.  If true and false are contiguous subtract the smaller.
	 Correct result is either 0 or the distance between them.  If result is not 0 or
	 their distance send mustBeBoolean."
	| ok |
	<var: #ok type: #'AbstractInstruction *'>
	extA := 0.
	self assert: (objectMemory objectAfter: objectMemory falseObject) = objectMemory trueObject.
	self PopR: TempReg.
	self genSubConstant: boolean R: TempReg.
	self JumpZero: (self ensureFixupAt: targetBytecodePC).
	self CmpCq: (boolean = objectMemory falseObject
					ifTrue: [objectMemory trueObject - objectMemory falseObject]
					ifFalse: [objectMemory falseObject - objectMemory trueObject])
		R: TempReg.
	ok := self JumpZero: 0.
	self genCallMustBeBooleanFor: boolean.
	ok jmpTarget: (self annotateBytecode: self Label).
	^0
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genJumpTo: targetBytecodePC [
	self Jump: (self ensureFixupAt: targetBytecodePC).
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genLoadArgAtDepth: n into: reg [
	"Load an argument at depth from top-of-stack (0 relative) into a register.
	 The actual offset depends on whether there's a link register or not."
	self MoveMw: (backEnd hasLinkRegister ifTrue: [n] ifFalse: [n + 1]) * objectMemory wordSize
		r: SPReg
		R: reg
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genLongJumpIfFalse [
	| distance target |
	distance := self v3: (self generatorAt: byte0) LongForward: bytecodePC Branch: 0 Distance: methodObj.
	target := distance + 2 + bytecodePC.
	^self genJumpIf: objectMemory falseObject to: target
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genLongJumpIfTrue [
	| distance target |
	distance := self v3: (self generatorAt: byte0) LongForward: bytecodePC Branch: 0 Distance: methodObj.
	target := distance + 2 + bytecodePC.
	^self genJumpIf: objectMemory trueObject to: target
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genLongPushTemporaryVariableBytecode [
	"230		11100110	i i i i i i i i	Push Temporary Variable #iiiiiiii"
	^self genPushTemporaryVariable: byte1
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genLongStoreAndPopTemporaryVariableBytecode [
	"237		11101101	i i i i i i i i	Pop and Store Temporary Variable #iiiiiiii"
	^self genStorePop: true TemporaryVariable: byte1
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genLongStoreTemporaryVariableBytecode [
	"234		11101010	i i i i i i i i	Store Temporary Variable #iiiiiiii"
	^self genStorePop: false TemporaryVariable: byte1
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genLongUnconditionalBackwardJump [
	| distance |
	distance := self v3: (self generatorAt: byte0)
					Long: bytecodePC
					Branch: 0
					Distance: methodObj.
	self assert: distance < 0.
	^self genJumpBackTo: distance + 2 + bytecodePC
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genLongUnconditionalForwardJump [
	| distance targetpc |
	distance := self v3: (self generatorAt: byte0)
					Long: bytecodePC
					Branch: 0
					Distance: methodObj.
	self assert: distance >= 0.
	targetpc := distance + 2 + bytecodePC.
	^self genJumpTo: targetpc
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genLookupForPerformNumArgs: numArgs [
	"Compile the code for a probe of the first-level method cache for a perform primtiive.
	 The selector is assumed to be in Arg0Reg.  Defer to adjustArgumentsForPerform: to
	 adjust the arguments before the jump to the method."
	| jumpSelectorMiss jumpClassMiss jumpInterpret itsAHit cacheBaseReg |
	<var: #jumpSelectorMiss type: #'AbstractInstruction *'>
	<var: #jumpClassMiss type: #'AbstractInstruction *'>
	<var: #jumpInterpret type: #'AbstractInstruction *'>
	<var: #itsAHit type: #'AbstractInstruction *'>

	"N.B.  Can't assume TempReg already contains the tag because a method can
	 of course be invoked via the unchecked entry-point, e.g. as does perform:."
	objectRepresentation genGetInlineCacheClassTagFrom: ReceiverResultReg into: SendNumArgsReg forEntry: false.

	self flag: #lookupInMethodCacheSel:classTag:. "so this method shows up as a sender of lookupInMethodCacheSel:class:"

	cacheBaseReg := NoReg.
	(backEnd isWithinMwOffsetRange: coInterpreter methodCacheAddress) ifFalse:
		[self MoveCq: coInterpreter methodCacheAddress R: (cacheBaseReg := Extra0Reg)].

	"Do first of three probes.  See CoInterpreter>>lookupInMethodCacheSel:classTag:"
	jumpSelectorMiss := self compilePerformMethodCacheProbeFor: Arg0Reg withShift: 0 baseRegOrNone: cacheBaseReg.
	jumpClassMiss := self JumpNonZero: 0.

	"Fetch the method, and check if it is cogged."
	itsAHit := self MoveMw: (cacheBaseReg = NoReg
								ifTrue: [coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheMethod << objectMemory shiftForWord)]
								ifFalse: [MethodCacheMethod << objectMemory shiftForWord])
					r: ClassReg
					R: SendNumArgsReg.
	"If the method is not compiled fall back on the interpreter primitive."
	objectRepresentation genLoadSlot: HeaderIndex sourceReg: SendNumArgsReg destReg: ClassReg.
	jumpInterpret := objectRepresentation genJumpImmediate: ClassReg.
	"Adjust arguments and jump to the method's unchecked entry-point."
	self AddCq: cmNoCheckEntryOffset R: ClassReg.
	self adjustArgumentsForPerform: numArgs.
	self JumpR: ClassReg.

	"First probe missed.  Do second of three probes.  Shift hash right one and retry."
	jumpSelectorMiss jmpTarget: (jumpClassMiss jmpTarget: self Label).
	jumpSelectorMiss := self compilePerformMethodCacheProbeFor: Arg0Reg withShift: 1 baseRegOrNone: cacheBaseReg.
	self JumpZero: itsAHit.

	"Second probe missed.  Do last probe.  Shift hash right two and retry."
	jumpSelectorMiss jmpTarget: self Label.
	jumpSelectorMiss := self compilePerformMethodCacheProbeFor: Arg0Reg withShift: 2 baseRegOrNone: cacheBaseReg.
	self JumpZero: itsAHit.

	"Last probe missed.  Caller will generate the call to fall back on the interpreter primitive."
	jumpSelectorMiss jmpTarget:
	(jumpInterpret jmpTarget: self Label).
	^0
]

{ #category : #'constant support' }
SimpleStackBasedCogit >> genMoveConstant: constant R: reg [
	"If the objectMemory allows it, generates a quick constant move, else generates a word constant move"
	<inline: true>
	^ (objectRepresentation shouldAnnotateObjectReference: constant)
		ifTrue: [ self annotate: (self MoveCw: constant R: reg) objRef: constant ]
		ifFalse: [ self MoveCq: constant R: reg ]
	
	
]

{ #category : #'constant support' }
SimpleStackBasedCogit >> genMoveFalseR: reg [
	<inline: true>
	^ self genMoveConstant: objectMemory falseObject R: reg
	
]

{ #category : #'constant support' }
SimpleStackBasedCogit >> genMoveNilR: reg [
	<inline: true>
	^ self genMoveConstant: objectMemory nilObject R: reg
	
]

{ #category : #'constant support' }
SimpleStackBasedCogit >> genMoveTrueR: reg [
	<inline: true>
	^ self genMoveConstant: objectMemory trueObject R: reg
	
]

{ #category : #initialization }
SimpleStackBasedCogit >> genMustBeBooleanTrampolineFor: boolean called: trampolineName [
	<var: #trampolineName type: #'char *'>
	<inline: false>
	self zeroOpcodeIndex.
	"If the objectRepresentation does want true & false to be mobile then we need to record these addresses."
	self assert: (objectRepresentation shouldAnnotateObjectReference: boolean) not.
	self AddCq: boolean R: TempReg.
	^self genTrampolineFor: #ceSendMustBeBoolean:
		called: trampolineName
		numArgs: 1
		arg: TempReg
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: true
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPopStackBytecode [
	self AddCq: objectMemory wordSize R: SPReg.
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimReturn [
	"Generate a return that cuts back the stack to remove the receiver
	 and arguments after an invocation of a primitive with nargs arguments.
	 This is similar to a Pascal calling convention."
	<inline: true>
	^self RetN: methodOrBlockNumArgs + 1 * objectMemory wordSize
]

{ #category : #initialization }
SimpleStackBasedCogit >> genPrimReturnEnterCogCodeEnilopmart: profiling [
	"Generate the substitute return code for an external or FFI primitive call.
	 On success simply return, extracting numArgs from newMethod.
	 On primitive failure call ceActivateFailingPrimitiveMethod: newMethod."
	| jmpSample continuePostSample jmpFail |
	<var: #jmpSample type: #'AbstractInstruction *'>
	<var: #continuePostSample type: #'AbstractInstruction *'>
	<var: #jmpFail type: #'AbstractInstruction *'>
	self zeroOpcodeIndex.
	backEnd hasVarBaseRegister ifTrue:
		[self MoveCq: self varBaseAddress R: VarBaseReg]. "Must happen sometime"

	profiling ifTrue:
		["Test nextProfileTick for being non-zero and call checkProfileTick: if so.
		  N.B. nextProfileTick is 64-bits so 32-bit systems need to test both halves."
		objectMemory wordSize = 4
			ifTrue:
				[self MoveAw: coInterpreter nextProfileTickAddress R: TempReg.
				 self MoveAw: coInterpreter nextProfileTickAddress + objectMemory wordSize R: ClassReg.
				 self OrR: TempReg R: ClassReg]
			ifFalse:
				[self MoveAw: coInterpreter nextProfileTickAddress R: TempReg.
				 self CmpCq: 0 R: TempReg].
		"If set, jump to record sample call."
		jmpSample := self JumpNonZero: 0.
		continuePostSample := self Label].

	self maybeCompileAllocFillerCheck.

	"Test primitive failure"
	self MoveAw: coInterpreter primFailCodeAddress R: TempReg.
	self flag: 'ask concrete code gen if move sets condition codes?'.
	self CmpCq: 0 R: TempReg.
	jmpFail := self JumpNonZero: 0.

	"Switch back to the Smalltalk stack.  Stack better be in either of these two states:
		success:	stackPointer	->	result (was receiver)
										arg1
										...
										argN
										return pc
		failure:							receiver
										arg1
										...
					stackPointer	->	argN
										return pc
	We push the instructionPointer to reestablish the return pc in the success case,
	but leave it to ceActivateFailingPrimitiveMethod: to do so in the failure case."

	backEnd hasLinkRegister
		ifTrue:
			[backEnd genLoadStackPointers.											"Switch back to Smalltalk stack."
			 backEnd hasPCRegister
				ifTrue:
					[self PopR: ReceiverResultReg.										"Pop result from stack"
					 self MoveAw: coInterpreter instructionPointerAddress R: PCReg]	"Return"
				ifFalse:
					[self MoveMw: 0 r: SPReg R: ReceiverResultReg.						"Fetch result from stack"
					 self MoveAw: coInterpreter instructionPointerAddress R: LinkReg.	"Get ret pc"
					 self RetN: objectMemory wordSize]]								"Return, popping result from stack"
		ifFalse:
			[self MoveAw: coInterpreter instructionPointerAddress R: ClassReg.	"Get return pc"
			 backEnd genLoadStackPointers.									"Switch back to Smalltalk stack."
			 self MoveMw: 0 r: SPReg R: ReceiverResultReg.						"Fetch result from stack"
			 self MoveR: ClassReg Mw: 0 r: SPReg.								"Restore return pc"
			 self RetN: 0].														"Return, popping result from stack"

	"Primitive failed.  Invoke C code to build the frame and continue."
	jmpFail jmpTarget: (self MoveAw: coInterpreter newMethodAddress R: SendNumArgsReg).
	"Reload sp with CStackPointer; easier than popping args of checkProfileTick."
	self MoveAw: self cStackPointerAddress R: SPReg.
	self 
		compileCallFor: #ceActivateFailingPrimitiveMethod:
		numArgs: 1
		arg: SendNumArgsReg
		arg: nil
		arg: nil
		arg: nil
		resultReg: NoReg
		regsToSave: self emptyRegisterMask.

	"On Spur ceActivateFailingPrimitiveMethod: may retry the primitive and return if successful.
	 So continue by returning to the caller.
	 Switch back to the Smalltalk stack.  Stack should be in this state:
				success:	stackPointer ->	result (was receiver)
											arg1
											...
											argN
											return pc
	 We can push the instructionPointer or load it into the LinkRegister to reestablish the return pc"
	self MoveAw: coInterpreter instructionPointerAddress
		R: (backEnd hasLinkRegister ifTrue: [LinkReg] ifFalse: [ClassReg]).
	backEnd genLoadStackPointers.
	backEnd hasLinkRegister
		ifTrue:
			[self MoveMw: 0 r: SPReg R: ReceiverResultReg]	"Fetch result from stack"
		ifFalse:
			[self MoveMw: objectMemory wordSize r: SPReg R: ReceiverResultReg.	"Fetch result from stack"
			 self PushR: ClassReg].											"Restore return pc on CISCs"
	self RetN: objectMemory wordSize.	"return to caller, popping receiver"

	profiling ifTrue:
		["Call ceCheckProfileTick: to record sample and then continue.  newMethod
		 should be up-to-date.  Need to save and restore the link reg around this call."
		 jmpSample jmpTarget: self Label.
		 backEnd saveAndRestoreLinkRegAround:
			[self CallFullRT: (self cCode: '(usqIntptr_t)ceCheckProfileTick'
						inSmalltalk: [self simulatedTrampolineFor: #ceCheckProfileTick])].
		 self Jump: continuePostSample]
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveClosureValue [
	"Check the argument count.  Fail if wrong.
	 Get the method from the outerContext and see if it is cogged.  If so, jump to the
	 block entry or the no-context-switch entry, as appropriate, and we're done.  If not,
	 invoke the interpreter primitive."
	| jumpFailNArgs jumpFail1 jumpFail2 jumpFail3 jumpFail4 jumpBCMethod primitiveRoutine result |
	<var: #jumpFail1 type: #'AbstractInstruction *'>
	<var: #jumpFail2 type: #'AbstractInstruction *'>
	<var: #jumpFail3 type: #'AbstractInstruction *'>
	<var: #jumpFail4 type: #'AbstractInstruction *'>
	<var: #jumpFailNArgs type: #'AbstractInstruction *'>
	<var: #jumpBCMethod type: #'AbstractInstruction *'>
	<var: #primitiveRoutine declareC: 'void (*primitiveRoutine)(void)'>
	objectRepresentation genLoadSlot: ClosureNumArgsIndex sourceReg: ReceiverResultReg destReg: TempReg.
	self CmpCq: (objectMemory integerObjectOf: methodOrBlockNumArgs) R: TempReg.
	jumpFailNArgs := self JumpNonZero: 0.
	objectRepresentation genLoadSlot: ClosureOuterContextIndex sourceReg: ReceiverResultReg destReg: ClassReg.
	jumpFail1 := objectRepresentation genJumpImmediate: ClassReg.
	objectRepresentation genGetCompactClassIndexNonImmOf: ClassReg into: TempReg.
	objectRepresentation genCmpClassMethodContextCompactIndexR: TempReg.
	jumpFail2 := self JumpNonZero: 0.
	"We defer unforwarding the receiver to the prologue; scanning blocks
	 for inst var refs and only unforwarding if the block refers to inst vars."
	(false
	 and: [objectRepresentation hasSpurMemoryManagerAPI]) ifTrue:
		[objectRepresentation
			genLoadSlot: ReceiverIndex sourceReg: ClassReg destReg: SendNumArgsReg;
			genEnsureOopInRegNotForwarded: SendNumArgsReg
			scratchReg: TempReg
			updatingSlot: ReceiverIndex
			in: ClassReg].
	objectRepresentation genLoadSlot: MethodIndex sourceReg: ClassReg destReg: SendNumArgsReg.
	jumpFail3 := objectRepresentation genJumpImmediate: SendNumArgsReg.
	objectRepresentation genGetFormatOf: SendNumArgsReg into: TempReg.
	self CmpCq: objectMemory firstCompiledMethodFormat R: TempReg.
	jumpFail4 := self JumpLess: 0.
	objectRepresentation genLoadSlot: HeaderIndex sourceReg: SendNumArgsReg destReg: ClassReg.
	jumpBCMethod := objectRepresentation genJumpImmediate: ClassReg.
	self MoveM16: (self offset: CogMethod of: #blockEntryOffset) r: ClassReg R: TempReg.
	self AddR: ClassReg R: TempReg.
	primitiveRoutine := coInterpreter
							functionPointerForCompiledMethod: methodObj
							primitiveIndex: primitiveIndex.
	primitiveRoutine = #primitiveClosureValueNoContextSwitch ifTrue:
		[blockNoContextSwitchOffset = nil ifTrue:
			[^NotFullyInitialized].
		 self SubCq: blockNoContextSwitchOffset R: TempReg].
	self JumpR: TempReg.
	jumpBCMethod jmpTarget: (jumpFail1 jmpTarget: (jumpFail2 jmpTarget: (jumpFail3 jmpTarget: (jumpFail4 jmpTarget: self Label)))).
	(result := self
				compileInterpreterPrimitive: primitiveRoutine
				flags: (coInterpreter primitivePropertyFlags: primitiveIndex)) < 0 ifTrue:
		[^result].
	jumpFailNArgs jmpTarget: self Label.
	^CompletePrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveFullClosureValue [
	"Check the argument count.  Fail if wrong.
	 Get the method from the outerContext and see if it is cogged.  If so, jump to the
	 block entry or the no-context-switch entry, as appropriate, and we're done.  If not,
	 invoke the interpreter primitive."
	| jumpFailNArgs jumpFailImmediateMethod jumpFail4 jumpBCMethod primitiveRoutine result |
	<option: #SistaV1BytecodeSet>
	<var: #jumpFailImmediateMethod type: #'AbstractInstruction *'>
	<var: #jumpFail4 type: #'AbstractInstruction *'>
	<var: #jumpFailNArgs type: #'AbstractInstruction *'>
	<var: #jumpBCMethod type: #'AbstractInstruction *'>
	<var: #primitiveRoutine declareC: 'void (*primitiveRoutine)(void)'>
	objectRepresentation genLoadSlot: ClosureNumArgsIndex sourceReg: ReceiverResultReg destReg: TempReg.
	self CmpCq: (objectMemory integerObjectOf: methodOrBlockNumArgs) R: TempReg.
	jumpFailNArgs := self JumpNonZero: 0.

	"We defer unforwarding the receiver to the prologue; scanning blocks
	 for inst var refs and only unforwarding if the block refers to inst vars."
	(false
	 and: [objectRepresentation hasSpurMemoryManagerAPI]) ifTrue:
		[objectRepresentation
			genLoadSlot: FullClosureReceiverIndex sourceReg: ReceiverResultReg destReg: SendNumArgsReg;
			genEnsureOopInRegNotForwarded: SendNumArgsReg
			scratchReg: TempReg
			updatingSlot: FullClosureReceiverIndex
			in: ReceiverResultReg].
	objectRepresentation genLoadSlot: FullClosureCompiledBlockIndex sourceReg: ReceiverResultReg destReg: SendNumArgsReg.
	jumpFailImmediateMethod := objectRepresentation genJumpImmediate: SendNumArgsReg.
	objectRepresentation genGetFormatOf: SendNumArgsReg into: TempReg.
	self CmpCq: objectMemory firstCompiledMethodFormat R: TempReg.
	jumpFail4 := self JumpLess: 0.
	objectRepresentation genLoadSlot: HeaderIndex sourceReg: SendNumArgsReg destReg: ClassReg.
	jumpBCMethod := objectRepresentation genJumpImmediate: ClassReg.

	primitiveRoutine := coInterpreter
							functionPointerForCompiledMethod: methodObj
							primitiveIndex: primitiveIndex.
	self AddCq: (primitiveRoutine = #primitiveFullClosureValueNoContextSwitch
					ifTrue: [self fullBlockNoContextSwitchEntryOffset]
					ifFalse: [self fullBlockEntryOffset])
		 R: ClassReg.
	self JumpR: ClassReg.
	jumpBCMethod jmpTarget: (jumpFailImmediateMethod jmpTarget: (jumpFail4 jmpTarget: self Label)).
	(result := self
				compileInterpreterPrimitive: primitiveRoutine
				 flags: (coInterpreter primitivePropertyFlags: primitiveIndex)) < 0 ifTrue:
		[^result].
	jumpFailNArgs jmpTarget: self Label.
	^CompletePrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveHashMultiply [
	"Implement 28-bit hashMultiply for SmallInteger and LargePositiveInteger receivers."
	| jmpFailImm jmpFailNonImm jmpNotSmallInt reenter |
	jmpNotSmallInt := objectRepresentation genJumpNotSmallInteger: ReceiverResultReg.

	objectRepresentation genConvertSmallIntegerToIntegerInReg: ReceiverResultReg.
	reenter :=
	self MoveCq: HashMultiplyConstant R: TempReg.
	self MulR: TempReg R: ReceiverResultReg.
	self AndCq: HashMultiplyMask R: ReceiverResultReg.
	objectRepresentation genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
	self RetN: 0.

	jmpNotSmallInt jmpTarget: self Label.
	jmpFailImm := objectRepresentation genJumpImmediate: ReceiverResultReg.
	objectRepresentation genGetCompactClassIndexNonImmOf: ReceiverResultReg into: ClassReg.
	self CmpCq: ClassLargePositiveIntegerCompactIndex R: ClassReg.
	jmpFailNonImm := self JumpNonZero: 0.
	objectRepresentation genLoadSlot: 0 sourceReg: ReceiverResultReg destReg: ReceiverResultReg.
	self Jump: reenter.

	jmpFailImm jmpTarget: (jmpFailNonImm jmpTarget: self Label).
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitivePerform [
	"Generate an in-line perform primitive.  The lookup code requires the selector to be in Arg0Reg.
	 adjustArgumentsForPerform: adjusts the arguments once genLookupForPerformNumArgs:
	 has generated the code for the lookup."
	self MoveMw: (backEnd hasLinkRegister
					ifTrue: [methodOrBlockNumArgs - 1]
					ifFalse: [methodOrBlockNumArgs]) * objectMemory wordSize
		r: SPReg
		R: Arg0Reg.
	^self genLookupForPerformNumArgs: methodOrBlockNumArgs
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushActiveContextBytecode [
	self assert: needsFrame.
	objectRepresentation
		genGetActiveContextNumArgs: methodOrBlockNumArgs
		large: (coInterpreter methodNeedsLargeContext: methodObj)
		inBlock: inBlock.
	self PushR: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushClosureCopyCopiedValuesBytecode [
	"Block compilation.  At this point in the method create the block.  Note its start
	 and defer generating code for it until after the method and any other preceding
	 blocks.  The block's actual code will be compiled later."
	"143   10001111 llllkkkk jjjjjjjj iiiiiiii	Push Closure Num Copied llll Num Args kkkk BlockSize jjjjjjjjiiiiiiii"
	| startpc numArgs numCopied |
	self assert: needsFrame.
	startpc := bytecodePC + (self generatorAt: byte0) numBytes.
	self addBlockStartAt: startpc "0 relative"
		numArgs: (numArgs := byte1 bitAnd: 16rF)
		numCopied: (numCopied := byte1 >> 4)
		span: (byte2 << 8) + byte3.
	objectRepresentation
		genCreateClosureAt: startpc + 1 "1 relative"
		numArgs: numArgs
		numCopied: numCopied
		contextNumArgs: methodOrBlockNumArgs
		large: (coInterpreter methodNeedsLargeContext: methodObj)
		inBlock: inBlock.
	self PushR: ReceiverResultReg.
	^0
]

{ #category : #'constant support' }
SimpleStackBasedCogit >> genPushConstant: constant [
	"If the objectMemory allows it, generates a quick constant push, else generates a word constant push"
	<inline: true>
	^ (objectRepresentation shouldAnnotateObjectReference: constant)
		ifTrue: [ self annotate: (self PushCw: constant) objRef: constant ]
		ifFalse: [ self PushCq: constant ]
	
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushConstantFalseBytecode [
	^self genPushLiteral: objectMemory falseObject
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushConstantNilBytecode [
	^self genPushLiteral: objectMemory nilObject
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushConstantOneBytecode [
	"79			01001111		Push 1"
	^self genPushLiteral: (objectMemory integerObjectOf: 1)
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushConstantTrueBytecode [
	^self genPushLiteral: objectMemory trueObject
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushConstantZeroBytecode [
	"78			01001110		Push 0"
	^self genPushLiteral: (objectMemory integerObjectOf: 0)
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genPushEnclosingObjectAt: level [
	"Uncached push enclosing object"
	self MoveCq: level R: SendNumArgsReg.
	self CallRT: ceEnclosingObjectTrampoline.
	self PushR: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genPushLiteral: literal [
	self genPushConstant: literal.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushLiteralConstantBytecode [
	^self genPushLiteralIndex: (byte0 bitAnd: 31)
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genPushLiteralIndex: literalIndex [ "<SmallInteger>"
	<inline: false>
	| literal |
	literal := self getLiteral: literalIndex.
	BytecodeSetHasDirectedSuperSend ifTrue:
		[self nextDescriptorExtensionsAndNextPCInto:
			[:descriptor :exta :extb :followingPC|
			(self isDirectedSuper: descriptor extA: exta extB: extb) ifTrue:
				[tempOop := literal.
				 ^0]]].
	^self genPushLiteral: literal
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushLiteralVariable16CasesBytecode [
	"16-31		0001 i i i i		Push Literal Variable #iiii"
	^self genPushLiteralVariable: (byte0 bitAnd: 15)
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genPushLiteralVariable: literalIndex [
	<inline: false>
	| association |
	association := self getLiteral: literalIndex.
	"If followed by a directed super send bytecode, avoid generating any code yet.
	 The association will be passed to the directed send trampoline in a register
	 and fully dereferenced only when first linked.  It will be ignored in later sends."
	BytecodeSetHasDirectedSuperSend ifTrue:
		[self deny: directedSendUsesBinding.
		 self nextDescriptorExtensionsAndNextPCInto:
			[:descriptor :exta :extb :followingPC|
			(self isDirectedSuper: descriptor extA: exta extB: extb) ifTrue:
				[tempOop := association.
				 directedSendUsesBinding := true.
				 ^0]]].
	"N.B. Do _not_ use ReceiverResultReg to avoid overwriting receiver in assignment in frameless methods."
	self genMoveConstant: association R: ClassReg.
	objectRepresentation
		genEnsureObjInRegNotForwarded: ClassReg
		scratchReg: TempReg.
	objectRepresentation
		genLoadSlot: ValueIndex
		sourceReg: ClassReg
		destReg: TempReg.
	self PushR: TempReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushLiteralVariableBytecode [
	^self genPushLiteralVariable: (byte0 bitAnd: 31)
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genPushMaybeContextReceiverVariable: slotIndex [ 
	<inline: false>
	| jmpSingle jmpDone |
	<var: #jmpSingle type: #'AbstractInstruction *'>
	<var: #jmpDone type: #'AbstractInstruction *'>
	self assert: needsFrame.
	"See CoInterpreter>>contextInstructionPointer:frame: for an explanation
	 of the instruction pointer slot handling."
	slotIndex = InstructionPointerIndex ifTrue:
		[self putSelfInReceiverResultReg.
		 self MoveCq: slotIndex R: SendNumArgsReg.
		 self CallRT: ceFetchContextInstVarTrampoline.
		 self PushR: SendNumArgsReg.
		 ^0].
	self MoveMw: FoxMFReceiver r: FPReg R: ReceiverResultReg.
	objectRepresentation
		genLoadSlot: SenderIndex
		sourceReg: ReceiverResultReg
		destReg: TempReg.
	jmpSingle := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	self MoveCq: slotIndex R: SendNumArgsReg.
	self CallRT: ceFetchContextInstVarTrampoline.
	jmpDone := self Jump: 0.
	jmpSingle jmpTarget: self Label.
	objectRepresentation
		genLoadSlot: slotIndex
		sourceReg: ReceiverResultReg
		destReg: SendNumArgsReg.
	jmpDone jmpTarget: (self PushR: SendNumArgsReg).
	^0
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genPushMaybeContextRemoteInstVar: slotIndex inObjectAt: objectIndex [
	| jmpSingle jmpDone |
	<var: #jmpSingle type: #'AbstractInstruction *'>
	<var: #jmpDone type: #'AbstractInstruction *'>
	self assert: needsFrame.
	"See CoInterpreter>>contextInstructionPointer:frame: for an explanation
	 of the instruction pointer slot handling."
	self MoveMw: (self frameOffsetOfTemporary: objectIndex) r: FPReg R: ReceiverResultReg.
	objectRepresentation 
		genEnsureOopInRegNotForwarded: ReceiverResultReg 
		scratchReg: TempReg.
	slotIndex = InstructionPointerIndex ifTrue:
		[self MoveCq: slotIndex R: SendNumArgsReg.
		 self CallRT: ceFetchContextInstVarTrampoline.
		 self PushR: SendNumArgsReg.
		 ^0].
	objectRepresentation
		genLoadSlot: SenderIndex
		sourceReg: ReceiverResultReg
		destReg: TempReg.
	jmpSingle := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	self MoveCq: slotIndex R: SendNumArgsReg.
	self CallRT: ceFetchContextInstVarTrampoline.
	jmpDone := self Jump: 0.
	jmpSingle jmpTarget: self Label.
	objectRepresentation
		genLoadSlot: slotIndex
		sourceReg: ReceiverResultReg
		destReg: SendNumArgsReg.
	jmpDone jmpTarget: (self PushR: SendNumArgsReg).
	^0

]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushNewArrayBytecode [
	| size popValues |
	self assert: needsFrame.
	popValues := byte1 > 127.
	size := byte1 bitAnd: 127.
	objectRepresentation genNewArrayOfSize: size initialized: popValues not.
	popValues ifTrue:
		[size - 1 to: 0 by: -1 do:
			[:i|
			self PopR: TempReg.
			objectRepresentation
				genStoreSourceReg: TempReg
				slotIndex: i
				intoNewObjectInDestReg: ReceiverResultReg]].
	self PushR: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushQuickIntegerConstantBytecode [
	^self genPushLiteral: (objectMemory integerObjectOf: byte0 - 117)
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushReceiverBytecode [
	needsFrame
		ifTrue:
			[self MoveMw: FoxMFReceiver r: FPReg R: TempReg.
			 self PushR: TempReg]
		ifFalse:
			[self PushR: ReceiverResultReg].
	^0
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genPushReceiverVariable: index [
	<inline: false>
	| maybeErr |
	needsFrame ifTrue:
		[self putSelfInReceiverResultReg].
	maybeErr := objectRepresentation genLoadSlot: index sourceReg: ReceiverResultReg destReg: TempReg.
	maybeErr < 0 ifTrue:
		[^maybeErr].
	self PushR: TempReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushReceiverVariableBytecode [
	^self genPushReceiverVariable: (byte0 bitAnd: 15)
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genPushRemoteInstVar: index inObjectAt: objectIndex [
	self MoveMw: (self frameOffsetOfTemporary: objectIndex) r: FPReg R: ClassReg.
	objectRepresentation 
		genEnsureOopInRegNotForwarded: ClassReg 
		scratchReg: TempReg.
	objectRepresentation
		genLoadSlot: index
		sourceReg: ClassReg
		destReg: TempReg.
	self PushR: TempReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushRemoteTempLongBytecode [
	self MoveMw: (self frameOffsetOfTemporary: byte2) r: FPReg R: ClassReg.
	TempVectReadBarrier
		ifTrue: [objectRepresentation
				genEnsureObjInRegNotForwarded: ClassReg
				scratchReg: TempReg].
	objectRepresentation
		genLoadSlot: byte1
		sourceReg: ClassReg
		destReg: TempReg.
	self PushR: TempReg.
	^0
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genPushTemporaryVariable: index [
	self MoveMw: (self frameOffsetOfTemporary: index) r: FPReg R: TempReg.
	self PushR: TempReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushTemporaryVariableBytecode [
	^self genPushTemporaryVariable: (byte0 bitAnd: 15)
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genQuickReturnConst [
	<api> "because selected by CoInterpreter>>quickPrimitiveGeneratorFor:"
	| constant |
	constant := coInterpreter quickPrimitiveConstantFor: primitiveIndex.
	self genMoveConstant: constant R: ReceiverResultReg.
	self genUpArrowReturn.
	^UnfailingPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genQuickReturnInstVar [
	<api> "because selected by CoInterpreter>>quickPrimitiveGeneratorFor:"
	| index |
	index := coInterpreter quickPrimitiveInstVarIndexFor: primitiveIndex.
	objectRepresentation genLoadSlot: index sourceReg: ReceiverResultReg destReg: ReceiverResultReg.
	self genUpArrowReturn.
	^UnfailingPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genQuickReturnSelf [
	<api> "because selected by CoInterpreter>>quickPrimitiveGeneratorFor:"
	self genUpArrowReturn.
	^UnfailingPrimitive
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnFalse [
	self genMoveFalseR: ReceiverResultReg.
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnNil [
	self genMoveNilR: ReceiverResultReg.
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnNilFromBlock [
	self assert: inBlock > 0.
	self genMoveNilR: ReceiverResultReg.
	^self genBlockReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnReceiver [
	"Frameless method activation looks like
				receiver
				args
		sp->	ret pc.
	 Return pops receiver and arguments off the stack.  Callee pushes the result."
	needsFrame ifTrue:
		[self putSelfInReceiverResultReg].
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnTopFromBlock [
	self assert: inBlock > 0.
	self PopR: ReceiverResultReg.
	^self genBlockReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnTopFromMethod [
	"Return pops receiver and arguments off the stack.  Callee pushes the result."
	self PopR: ReceiverResultReg.
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnTrue [
	self genMoveTrueR: ReceiverResultReg.
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSecondExtendedSendBytecode [
	"Can use any of the first 64 literals for the selector and pass up to 3 arguments."

	^self genSend: (byte1 bitAnd: 16r3F) numArgs: byte1 >> 6
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genSend: selectorIndex numArgs: numArgs [
	<inline: true>
	^self genSend: selectorIndex numArgs: numArgs sendTable: ordinarySendTrampolines
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genSend: selectorIndex numArgs: numArgs sendTable: sendTable [
	<inline: false>
	<var: #sendTable type: #'sqInt *'>
	| annotation |
	self assert: needsFrame.
	annotation := self annotationForSendTable: sendTable.
	self assert: (numArgs between: 0 and: 255). "say"
	self MoveMw: numArgs * objectMemory wordSize r: SPReg R: ReceiverResultReg.
	"Deal with stale super sends; see SpurMemoryManager's class comment."
	(self annotationIsForUncheckedEntryPoint: annotation) ifTrue:
		[objectRepresentation genEnsureOopInRegNotForwarded: ReceiverResultReg scratchReg: TempReg].
	"0 through (NumSendTrampolines - 2) numArgs sends have the arg count implciti in the trampoline.
	 The last send trampoline (NumSendTrampolines - 1) passes numArgs in SendNumArgsReg."
	numArgs >= (NumSendTrampolines - 1) ifTrue:
		[self MoveCq: numArgs R: SendNumArgsReg].
	(BytecodeSetHasDirectedSuperSend
	 and: [annotation
			between: IsDirectedSuperSend
			and: IsDirectedSuperBindingSend]) ifTrue:
		[self genMoveConstant: tempOop R: TempReg].
	self genLoadInlineCacheWithSelector: selectorIndex.

	(self Call: (sendTable at: (numArgs min: NumSendTrampolines - 1))) annotation: annotation.
	self PushR: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genSendDirectedSuper: selectorIndex numArgs: numArgs [
	<inline: false>
	"N.B. genPushLiteralVariableGivenDirectedSuper: has already loaded tempOop with the association."
	| result |
	result := self
				genSend: selectorIndex
				numArgs: numArgs
				sendTable: (directedSendUsesBinding
								ifTrue: [directedSuperBindingSendTrampolines]
								ifFalse: [directedSuperSendTrampolines]).
	directedSendUsesBinding := false.
	^result
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSendLiteralSelector0ArgsBytecode [
	^self genSend: (byte0 bitAnd: 15) numArgs: 0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSendLiteralSelector1ArgBytecode [
	^self genSend: (byte0 bitAnd: 15) numArgs: 1
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSendLiteralSelector2ArgsBytecode [

	^self genSend: (byte0 bitAnd: 15) numArgs: 2
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genSendSuper: selectorIndex numArgs: numArgs [
	<inline: false>
	^self genSend: selectorIndex numArgs: numArgs sendTable: superSendTrampolines
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genShortJumpIfFalse [
	| distance target |
	distance := self v3: (self generatorAt: byte0)
					ShortForward: bytecodePC
					Branch: 0
					Distance: methodObj.
	target := distance + 1 + bytecodePC.
	^self genJumpIf: objectMemory falseObject to: target
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genShortJumpIfTrue [
	| distance target |
	distance := self v3: (self generatorAt: byte0)
					ShortForward: bytecodePC
					Branch: 0
					Distance: methodObj.
	target := distance + 1 + bytecodePC.
	^self genJumpIf: objectMemory trueObject to: target
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genShortUnconditionalJump [
	| distance target |
	distance := self v3: (self generatorAt: byte0)
					ShortForward: bytecodePC
					Branch: 0
					Distance: methodObj.
	target := distance + 1 + bytecodePC.
	^self genJumpTo: target
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSistaExtStoreAndPopLiteralVariableBytecode [
	^ self genSistaExtStoreLiteralVariableBytecodePopBoolean: true
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSistaExtStoreAndPopReceiverVariableBytecode [
	^ self genSistaExtStoreAndPopReceiverVariableBytecodePopBoolean: true
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSistaExtStoreAndPopReceiverVariableBytecodePopBoolean: boolean [
	| index |
	extB := 0. "Simple cogit don't use the extra flags"
	numExtB := 0.
	index := byte1 + (extA << 8).
	extA := 0.
	^(coInterpreter isWriteMediatedContextInstVarIndex: index)
		ifTrue: [self genStorePop: boolean MaybeContextReceiverVariable: index ]
		ifFalse: [self genStorePop: boolean ReceiverVariable: index ]
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSistaExtStoreLiteralVariableBytecode [
	^ self genSistaExtStoreLiteralVariableBytecodePopBoolean: false
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSistaExtStoreLiteralVariableBytecodePopBoolean: boolean [
	| index |
	extB := 0. "SimpleCogit don't use the extra flags"
	numExtB := 0.
	index := byte1 + (extA << 8).
	extA := 0.
	^ self genStorePop: boolean LiteralVariable: index
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSistaExtStoreReceiverVariableBytecode [
	^ self genSistaExtStoreAndPopReceiverVariableBytecodePopBoolean: false
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSpecialSelectorClass [
	self MoveMw: 0 r: SPReg R: SendNumArgsReg.
	objectRepresentation
		genGetClassObjectOf: SendNumArgsReg
		into: ClassReg
		scratchReg: TempReg
		instRegIsReceiver: false.
	self MoveR: ClassReg Mw: 0 r: SPReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSpecialSelectorEqualsEquals [
	^ self genInlinedIdenticalOrNotIf: false
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSpecialSelectorNotEqualsEquals [
	^ self genInlinedIdenticalOrNotIf: true
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSpecialSelectorSend [
	| index numArgs |
	index := byte0 - self firstSpecialSelectorBytecodeOffset.
	numArgs := coInterpreter specialSelectorNumArgs: index.
	^self genSend: index negated - 1 numArgs: numArgs
]

{ #category : #'simulation stack' }
SimpleStackBasedCogit >> genStackArgAt: n into: reg [ 
	<inline: true>
	self
		MoveMw: (self backEnd hasLinkRegister
				ifTrue: [n]
				ifFalse: [n + 1])
				* objectMemory wordSize
		r: SPReg
		R: reg.
	^ 0

]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genStoreAndPopReceiverVariableBytecode [
	^self genStorePop: true ReceiverVariable: (byte0 bitAnd: 7)
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genStoreAndPopRemoteTempLongBytecode [
	^self genStorePop: true RemoteTemp: byte1 At: byte2
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genStoreAndPopTemporaryVariableBytecode [
	^self genStorePop: true TemporaryVariable: (byte0 bitAnd: 7)
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genStorePop: popBoolean LiteralVariable: litVarIndex [
	<inline: false>
	| association |
	"The only reason we assert needsFrame here is that in a frameless method
	 ReceiverResultReg must and does contain only self, but the ceStoreCheck
	 trampoline expects the target of the store to be in ReceiverResultReg.  So
	 in a frameless method we would have a conflict between the receiver and
	 the literal store, unless we we smart enough to realise that ReceiverResultReg
	 was unused after the literal variable store, unlikely given that methods
	 return self by default."
	self assert: needsFrame.
	association := self getLiteral: litVarIndex.
	self genMoveConstant: association R: ReceiverResultReg.
	objectRepresentation
		genEnsureObjInRegNotForwarded: ReceiverResultReg
		scratchReg: TempReg.
	popBoolean
		ifTrue: [self PopR: ClassReg]
		ifFalse: [self MoveMw: 0 r: SPReg R: ClassReg].
	self
		genStoreSourceReg: ClassReg 
		slotIndex: ValueIndex 
		destReg: ReceiverResultReg 
		scratchReg: TempReg 
		inFrame: needsFrame.
	^0
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genStorePop: popBoolean MaybeContextReceiverVariable: slotIndex [
	<inline: false>
	| jmpSingle jmpDone |
	<var: #jmpSingle type: #'AbstractInstruction *'>
	<var: #jmpDone type: #'AbstractInstruction *'>
	"The reason we need a frame here is that assigning to an inst var of a context may
	 involve wholesale reorganization of stack pages, and the only way to preserve the
	 execution state of an activation in that case is if it has a frame."
	self assert: needsFrame.
	self putSelfInReceiverResultReg.
	objectRepresentation
		genLoadSlot: SenderIndex
		sourceReg: ReceiverResultReg
		destReg: TempReg.
	self MoveMw: 0 r: SPReg R: ClassReg.
	jmpSingle := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	self MoveCq: slotIndex R: SendNumArgsReg.
	self CallRT: ceStoreContextInstVarTrampoline.
	jmpDone := self Jump: 0.
	jmpSingle jmpTarget: self Label.
	popBoolean ifTrue:
		[self AddCq: objectMemory wordSize R: SPReg].
	self
		genStoreSourceReg: ClassReg 
		slotIndex: slotIndex 
		destReg: ReceiverResultReg 
		scratchReg: TempReg 
		inFrame: needsFrame.
	jmpDone jmpTarget: self Label.
	^0
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genStorePop: popBoolean MaybeContextRemoteInstVar: slotIndex ofObjectAt: objectIndex [
	<inline: false>
	| jmpSingle jmpDone |
	<var: #jmpSingle type: #'AbstractInstruction *'>
	<var: #jmpDone type: #'AbstractInstruction *'>
	"The reason we need a frame here is that assigning to an inst var of a context may
	 involve wholesale reorganization of stack pages, and the only way to preserve the
	 execution state of an activation in that case is if it has a frame."
	self assert: needsFrame.
	self MoveMw: (self frameOffsetOfTemporary: objectIndex) r: FPReg R: ReceiverResultReg.
	objectRepresentation 
		genEnsureOopInRegNotForwarded: ReceiverResultReg 
		scratchReg: TempReg.
	objectRepresentation
		genLoadSlot: SenderIndex
		sourceReg: ReceiverResultReg
		destReg: TempReg.
	self MoveMw: 0 r: SPReg R: ClassReg.
	jmpSingle := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	self MoveCq: slotIndex R: SendNumArgsReg.
	self CallRT: ceStoreContextInstVarTrampoline.
	jmpDone := self Jump: 0.
	jmpSingle jmpTarget: self Label.
	popBoolean ifTrue:
		[self AddCq: objectMemory wordSize R: SPReg].
	self
		genStoreSourceReg: ClassReg 
		slotIndex: slotIndex 
		destReg: ReceiverResultReg 
		scratchReg: TempReg 
		inFrame: needsFrame.
	jmpDone jmpTarget: self Label.
	^0
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genStorePop: popBoolean ReceiverVariable: slotIndex [
	<inline: false>
	needsFrame ifTrue:
		[self putSelfInReceiverResultReg].
	popBoolean
		ifTrue: [self PopR: ClassReg]
		ifFalse: [self MoveMw: 0 r: SPReg R: ClassReg].
	objectRepresentation
		genStoreSourceReg: ClassReg 
		slotIndex: slotIndex 
		destReg: ReceiverResultReg 
		scratchReg: TempReg 
		inFrame: needsFrame.
	^0
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genStorePop: popBoolean RemoteInstVar: slotIndex ofObjectAt: objectIndex [
	<inline: false>
	"The only reason we assert needsFrame here is that in a frameless method
	 ReceiverResultReg must and does contain only self, but the ceStoreCheck
	 trampoline expects the target of the store to be in ReceiverResultReg.  So
	 in a frameless method we would have a conflict between the receiver and
	 the temote temp store, unless we we smart enough to realise that
	 ReceiverResultReg was unused after the literal variable store, unlikely given
	 that methods return self by default."
	self assert: needsFrame.
	popBoolean
		ifTrue: [self PopR: ClassReg]
		ifFalse: [self MoveMw: 0 r: SPReg R: ClassReg].
	self MoveMw: (self frameOffsetOfTemporary: objectIndex) r: FPReg R: ReceiverResultReg.
	objectRepresentation 
		genEnsureOopInRegNotForwarded: ReceiverResultReg 
		scratchReg: TempReg.
	^objectRepresentation
		genStoreSourceReg: ClassReg
		slotIndex: slotIndex
		destReg: ReceiverResultReg
		scratchReg: TempReg
		inFrame: needsFrame
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genStorePop: popBoolean RemoteTemp: slotIndex At: remoteTempIndex [
	<inline: false>
	"The only reason we assert needsFrame here is that in a frameless method
	 ReceiverResultReg must and does contain only self, but the ceStoreCheck
	 trampoline expects the target of the store to be in ReceiverResultReg.  So
	 in a frameless method we would have a conflict between the receiver and
	 the temote temp store, unless we we smart enough to realise that
	 ReceiverResultReg was unused after the literal variable store, unlikely given
	 that methods return self by default."
	self assert: needsFrame.
	popBoolean
		ifTrue: [self PopR: ClassReg]
		ifFalse: [self MoveMw: 0 r: SPReg R: ClassReg].
	self MoveMw: (self frameOffsetOfTemporary: remoteTempIndex) r: FPReg R: ReceiverResultReg.
	TempVectReadBarrier
		ifTrue: [objectRepresentation
				genEnsureObjInRegNotForwarded: ReceiverResultReg
				scratchReg: TempReg].
	^objectRepresentation
		genStoreSourceReg: ClassReg
		slotIndex: slotIndex
		destReg: ReceiverResultReg
		scratchReg: TempReg
		inFrame: needsFrame
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genStorePop: popBoolean TemporaryVariable: tempIndex [
	<inline: false>
	popBoolean
		ifTrue: [self PopR: TempReg]
		ifFalse: [self MoveMw: 0 r: SPReg R: TempReg].
	self MoveR: TempReg
		Mw: (self frameOffsetOfTemporary: tempIndex)
		r: FPReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genStoreRemoteTempLongBytecode [
	^self genStorePop: false RemoteTemp: byte1 At: byte2
]

{ #category : #'constant support' }
SimpleStackBasedCogit >> genSubConstant: constant R: reg [
	"If the objectMemory allows it, generates a quick constant sub, else generates a word constant sub"
	<inline: true>
	^ (objectRepresentation shouldAnnotateObjectReference: constant)
		ifTrue: [ self annotate: (self SubCw: constant R: reg) objRef: reg. ]
		ifFalse: [ self SubCq: constant R: reg ]
]

{ #category : #initialization }
SimpleStackBasedCogit >> genTraceStoreTrampoline [
	ceTraceStoreTrampoline := self genTrampolineFor: #ceTraceStoreOf:into:
										called: 'ceTraceStoreTrampoline'
										arg: ClassReg
										arg: ReceiverResultReg
										regsToSave: CallerSavedRegisterMask
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> genTraceStores [
	<inline: true>
	traceStores > 0 ifTrue: [ self CallRT: ceTraceStoreTrampoline ].
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genUnconditionalTrapBytecode [
	"SistaV1: *	217		Trap"
	^EncounteredUnknownBytecode
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genUpArrowReturn [
	"Generate a method return from within a method or a block.
	 Frameless method activation looks like
				receiver
				args
		sp->	ret pc.
	 Return pops receiver and arguments off the stack.  Callee pushes the result."
	inBlock > 0 ifTrue:
		[self assert: needsFrame.
		 self CallRT: ceNonLocalReturnTrampoline.
		 self annotateBytecode: self Label.
		 ^0].
	needsFrame ifTrue:
		[self MoveR: FPReg R: SPReg.
		 self PopR: FPReg.
		 backEnd hasLinkRegister ifTrue:
			[self PopR: LinkReg]].
	self RetN: methodOrBlockNumArgs + 1 * objectMemory wordSize.
	^0
]

{ #category : #initialization }
SimpleStackBasedCogit >> generateMissAbortTrampolines [
	"Generate the run-time entries for the various method and PIC entry misses and aborts.
	 Read the class-side method trampolines for documentation on the various trampolines"

	ceMethodAbortTrampoline := self genMethodAbortTrampoline.
	cePICAbortTrampoline := self genPICAbortTrampoline.
	ceCPICMissTrampoline := self genTrampolineFor: #ceCPICMiss:receiver:
								called: 'ceCPICMissTrampoline'
								arg: ClassReg
								arg: ReceiverResultReg.
	ceReapAndResetErrorCodeTrampoline := self genTrampolineFor: #ceReapAndResetErrorCodeFor:
												called: 'ceReapAndResetErrorCodeTrampoline'
												arg: ClassReg
]

{ #category : #initialization }
SimpleStackBasedCogit >> generateTracingTrampolines [
	"Generate trampolines for tracing.  In the simulator we can save a lot of time
	 and avoid noise instructions in the lastNInstructions log by short-cutting these
	 trampolines, but we need them in the real vm."
	ceTraceLinkedSendTrampoline :=
		self genTrampolineFor: #ceTraceLinkedSend:
			called: 'ceTraceLinkedSendTrampoline'
			arg: ReceiverResultReg
			regsToSave: CallerSavedRegisterMask.
	ceTraceBlockActivationTrampoline :=
		self genTrampolineFor: #ceTraceBlockActivation
			called: 'ceTraceBlockActivationTrampoline'
			regsToSave: CallerSavedRegisterMask..
	ceTraceStoreTrampoline :=
		self genTrampolineFor: #ceTraceStoreOf:into:
			called: 'ceTraceStoreTrampoline'
			arg: ClassReg
			arg: ReceiverResultReg
			regsToSave: CallerSavedRegisterMask..
	self cCode: [] inSmalltalk:
		[ceTraceLinkedSendTrampoline := self simulatedTrampolineFor: #ceShortCutTraceLinkedSend:.
		 ceTraceBlockActivationTrampoline := self simulatedTrampolineFor: #ceShortCutTraceBlockActivation:.
		 ceTraceStoreTrampoline := self simulatedTrampolineFor: #ceShortCutTraceStore:]
]

{ #category : #'register management' }
SimpleStackBasedCogit >> isCallerSavedReg: reg [
	<inline: true>
	^self register: reg isInMask: CallerSavedRegisterMask
]

{ #category : #'method introspection' }
SimpleStackBasedCogit >> mapPCDataFor: cogMethod into: arrayObj [
	"Collect the branch and send data for cogMethod, storing it into arrayObj."
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	| errCode |
	introspectionDataIndex := 0.
	introspectionData := arrayObj.
	cogMethod stackCheckOffset = 0 ifTrue:
		[self assert: introspectionDataIndex = 0.
		 cogMethod cmIsFullBlock
			ifTrue:
				[objectMemory
					storePointerUnchecked: 0 ofObject: introspectionData withValue: objectMemory nilObject;
					storePointerUnchecked: 1 ofObject: introspectionData withValue: (objectMemory integerObjectOf: cbNoSwitchEntryOffset);
					storePointerUnchecked: 2 ofObject: introspectionData withValue: objectMemory nilObject;
					storePointerUnchecked: 3 ofObject: introspectionData withValue: (objectMemory integerObjectOf: cbEntryOffset)]
			ifFalse:
				[objectMemory
					storePointerUnchecked: 0 ofObject: introspectionData withValue: objectMemory nilObject;
					storePointerUnchecked: 1 ofObject: introspectionData withValue: (objectMemory integerObjectOf: cmEntryOffset);
					storePointerUnchecked: 2 ofObject: introspectionData withValue: objectMemory nilObject;
					storePointerUnchecked: 3 ofObject: introspectionData withValue: (objectMemory integerObjectOf: cmNoCheckEntryOffset)].
		 ^4].
	errCode := self
					mapFor: (self cCoerceSimple: cogMethod to: #'CogBlockMethod *')
					bcpc: (coInterpreter startPCOfMethod: cogMethod methodObject)
					performUntil: #pcDataFor:Annotation:Mcpc:Bcpc:Method:
					arg: cogMethod asVoidPointer.
	errCode ~= 0 ifTrue:
		[self assert: errCode = PrimErrNoMemory.
		 ^-1].
	cogMethod blockEntryOffset ~= 0 ifTrue:
		[errCode := self blockDispatchTargetsFor: cogMethod
						perform: #pcDataForBlockEntry:Method:
						arg: cogMethod asInteger.
		 errCode ~= 0 ifTrue:
			[self assert: errCode = PrimErrNoMemory.
			 ^-1]].
	^introspectionDataIndex
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> marshallAbsentReceiverSendArguments: numArgs [
	self assert: needsFrame.
	self putSelfInReceiverResultReg.

	"Shuffle arguments if necessary and push receiver."
	numArgs = 0
		ifTrue:
			[self PushR: ReceiverResultReg]
		ifFalse:
			[self MoveMw: 0 r: SPReg R: TempReg.
			self PushR: TempReg.
			2 to: numArgs do:
				[:index|
				self MoveMw: index * objectMemory wordSize r: SPReg R: TempReg.
				self MoveR: TempReg Mw: index - 1 * BytesPerWord r: SPReg].
			self MoveR: ReceiverResultReg Mw: numArgs * BytesPerWord r: SPReg].
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> maybeCompileAllocFillerCheck [
	"If allocCheckFiller is true, words in newSpace from freeStart to scavengeThreshold
	 are filled with their address, and after each call of a plugin primitive, the VM checks
	 that freeStart points to a word containing the value of freeStart.  This is a simple
	 check for primitives overwriting the ends of an object."
	| jmpOk |
	<var: #jmpOk type: #'AbstractInstruction *'>
	coInterpreter getCheckAllocFiller ifTrue:
		[self MoveAw: objectMemory freeStartAddress R: ClassReg.
		 self MoveMw: 0 r: ClassReg R: TempReg.
		 self CmpR: ClassReg R: TempReg.
		 jmpOk := self JumpZero: 0.
		 self MoveCq: PrimErrWritePastObject R: TempReg.
		 self MoveR: TempReg Aw: coInterpreter primFailCodeAddress.
		 jmpOk jmpTarget: self Label]
]

{ #category : #trampolines }
SimpleStackBasedCogit >> methodAbortTrampolineFor: numArgs [
	^ceMethodAbortTrampoline
]

{ #category : #'compile abstract instructions' }
SimpleStackBasedCogit >> methodUsesPrimitiveErrorCode: aMethodObj header: aMethodHeader [
	"Answer if aMethodObj contains a primitive and uses the primitive error code."
	<inline: true>
	^(coInterpreter primitiveIndexOfMethod: aMethodObj header: aMethodHeader) > 0
	  and: [(coInterpreter longStoreBytecodeForHeader: aMethodHeader)
			= (objectMemory
				fetchByte: (coInterpreter startPCOfMethod: aMethodObj) + (coInterpreter sizeOfCallPrimitiveBytecode: aMethodHeader)
				ofObject: aMethodObj)]
]

{ #category : #accessing }
SimpleStackBasedCogit >> minCallAddress: anInteger [ 
	<doNotGenerate>

	minValidCallAddress:=anInteger
]

{ #category : #testing }
SimpleStackBasedCogit >> numRegArgs [
	<api>
	^0
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> numSpecialSelectors [
	<inline: true>
	^self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [bytecodeSetOffset = 256 ifTrue: [AltNumSpecialSelectors] ifFalse: [NumSpecialSelectors]]
		ifFalse: [NumSpecialSelectors]
]

{ #category : #'span functions' }
SimpleStackBasedCogit >> parseV4Exts: nExts priorTo: bcpc in: aMethodObj into: aBinaryBlock [
	"224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)
	 225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)"
	| extAValue extBValue pc byte extByte |
	<inline: true>
	extAValue := extBValue := 0.
	pc := bcpc - nExts - nExts.
	[pc < bcpc] whileTrue:
		[byte := objectMemory fetchByte: pc ofObject: aMethodObj.
		 pc := pc + 1.
		 extByte := objectMemory fetchByte: pc ofObject: aMethodObj.
		 pc := pc + 1.
		 self assert: (byte = 224 or: [byte = 225]).
		 byte = 224
			ifTrue:
				[extAValue := (extAValue bitShift: 8) + extByte]
			ifFalse:
				[extBValue := (extBValue = 0 and: [extByte > 127])
							ifTrue: [extByte - 256]
							ifFalse: [(extBValue bitShift: 8) + extByte]]].
	aBinaryBlock value: extAValue value: extBValue
]

{ #category : #'method introspection' }
SimpleStackBasedCogit >> pcDataFor: descriptor Annotation: isBackwardBranchAndAnnotation Mcpc: mcpc Bcpc: bcpc Method: cogMethodArg [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #mcpc type: #'char *'>
	<var: #cogMethodArg type: #'void *'>

	descriptor ifNil: "this is the stackCheck offset"
		[self assert: introspectionDataIndex = 0.
		 (self cCoerceSimple: cogMethodArg to: #'CogMethod *') cmIsFullBlock
			ifTrue:
				[objectMemory
					storePointerUnchecked: introspectionDataIndex + 0 ofObject: introspectionData withValue: objectMemory nilObject;
					storePointerUnchecked: introspectionDataIndex + 1 ofObject: introspectionData withValue: (objectMemory integerObjectOf: cbNoSwitchEntryOffset);
					storePointerUnchecked: introspectionDataIndex + 2 ofObject: introspectionData withValue: objectMemory nilObject;
					storePointerUnchecked: introspectionDataIndex + 3 ofObject: introspectionData withValue: (objectMemory integerObjectOf: cbEntryOffset)]
			ifFalse:
				[objectMemory
					storePointerUnchecked: introspectionDataIndex + 0 ofObject: introspectionData withValue: objectMemory nilObject;
					storePointerUnchecked: introspectionDataIndex + 1 ofObject: introspectionData withValue: (objectMemory integerObjectOf: cmEntryOffset);
					storePointerUnchecked: introspectionDataIndex + 2 ofObject: introspectionData withValue: objectMemory nilObject;
					storePointerUnchecked: introspectionDataIndex + 3 ofObject: introspectionData withValue: (objectMemory integerObjectOf: cmNoCheckEntryOffset)].
		 objectMemory
			storePointerUnchecked: introspectionDataIndex + 4 ofObject: introspectionData withValue: (objectMemory integerObjectOf: bcpc + 1);
			storePointerUnchecked: introspectionDataIndex + 5 ofObject: introspectionData withValue: (objectMemory integerObjectOf: (self cCoerceSimple: cogMethodArg to: #'CogMethod *') stackCheckOffset).
		 introspectionDataIndex := introspectionDataIndex + 6.
		 ^0].

	(self isPCMappedAnnotation: isBackwardBranchAndAnnotation >> 1) ifTrue:
		[| actualBcpc actualMcpc |
		 actualBcpc := (isBackwardBranchAndAnnotation anyMask: 1)
							ifTrue: [bcpc + 1]
							ifFalse: [bcpc + descriptor numBytes + 1].
		 actualMcpc := mcpc asUnsignedInteger - cogMethodArg asUnsignedInteger.
		 objectMemory
			storePointerUnchecked: introspectionDataIndex + 0 ofObject: introspectionData withValue: (objectMemory integerObjectOf: actualBcpc);
			storePointerUnchecked: introspectionDataIndex + 1 ofObject: introspectionData withValue: (objectMemory integerObjectOf: actualMcpc).
		 introspectionDataIndex := introspectionDataIndex + 2].

	^0
]

{ #category : #'method introspection' }
SimpleStackBasedCogit >> pcDataForBlockEntry: blockEntryMcpc Method: cogMethod [
	"Collect the branch and send data for the block method starting at blockEntryMcpc, storing it into picData."
	<returnTypeC: #usqInt>
	objectMemory
		storePointerUnchecked: introspectionDataIndex + 0 ofObject: introspectionData withValue: objectMemory nilObject;
		storePointerUnchecked: introspectionDataIndex + 1 ofObject: introspectionData withValue: (objectMemory integerObjectOf: blockEntryMcpc - blockNoContextSwitchOffset);
		storePointerUnchecked: introspectionDataIndex + 2 ofObject: introspectionData withValue: objectMemory nilObject;
		storePointerUnchecked: introspectionDataIndex + 3 ofObject: introspectionData withValue: (objectMemory integerObjectOf: blockEntryMcpc).
	introspectionDataIndex := introspectionDataIndex + 4.
	^0
]

{ #category : #trampolines }
SimpleStackBasedCogit >> picAbortTrampolineFor: numArgs [
	^cePICAbortTrampoline
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> primitiveGeneratorOrNil [
	"If there is a generator for the current primitive then answer it;
	 otherwise answer nil."
	<returnTypeC: #'PrimitiveDescriptor *'>
	| primitiveDescriptor |
	<var: #primitiveDescriptor type: #'PrimitiveDescriptor *'>
	(coInterpreter isQuickPrimitiveIndex: primitiveIndex) ifTrue:
		[primitiveDescriptor := self addressOf: (primitiveGeneratorTable at: 0). "an unused one"
		 primitiveDescriptor primitiveGenerator: (coInterpreter quickPrimitiveGeneratorFor: primitiveIndex).
		 ^primitiveDescriptor].
	(primitiveIndex between: 1 and: MaxCompiledPrimitiveIndex) ifTrue:
		[self cCode: [] inSmalltalk: "for debugging, allow excluding specific primitives"
			[self class initializationOptions at: #DoNotJIT ifPresent:
				[:excluded|
				((excluded includes: primitiveIndex)
				 and: [(primitiveGeneratorTable at: primitiveIndex) primitiveGenerator notNil]) ifTrue:
					[coInterpreter transcript nextPutAll: 'EXCLUDING primitive #'; print: primitiveIndex; space; nextPutAll: (primitiveGeneratorTable at: primitiveIndex) primitiveGenerator; cr; flush.
				 ^nil]]].
		 ^self addressOf: (primitiveGeneratorTable at: primitiveIndex)].
	^nil
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> putSelfInReceiverResultReg [
	<inline: true>
	self MoveMw: FoxMFReceiver r: FPReg R: ReceiverResultReg
]

{ #category : #'external primitive support' }
SimpleStackBasedCogit >> recordCallOffsetIn: cogMethod [
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	| offset offsetTable |
	<var: #offsetTable type: #'sqInt *'>
	offset := primSetFunctionLabel address - cogMethod asInteger.
	(externalSetPrimOffsets at: cogMethod cmNumArgs) isNil
		ifTrue: [externalSetPrimOffsets at: cogMethod cmNumArgs put: offset]
		ifFalse: [self assert: (externalSetPrimOffsets at: cogMethod cmNumArgs) = offset].
	offsetTable := primInvokeInstruction isJump
						ifTrue: [externalPrimJumpOffsets]
						ifFalse: [externalPrimCallOffsets].
	offset := primInvokeInstruction address + primInvokeInstruction machineCodeSize - cogMethod asInteger.
	(offsetTable at: cogMethod cmNumArgs) isNil
		ifTrue: [offsetTable at: cogMethod cmNumArgs put: offset]
		ifFalse: [self assert: (offsetTable at: cogMethod cmNumArgs) = offset]
]

{ #category : #testing }
SimpleStackBasedCogit >> register: reg1 and: reg2 isNotInMask: mask [
	<inline: true>
	^mask noMask: (self registerMaskFor: reg1 and: reg2)
]

{ #category : #testing }
SimpleStackBasedCogit >> register: reg isInMask: mask [
	<inline: true>
	^ mask anyMask: (self registerMaskFor: reg)
]

{ #category : #testing }
SimpleStackBasedCogit >> register: reg isNotInMask: mask [
	<inline: true>
	^ mask noMask: (self registerMaskFor: reg)
]

{ #category : #trampolines }
SimpleStackBasedCogit >> returnRegForStoreCheck [
	"We must ensure the ReceiverResultReg is live across the store check so that
	 we can store into receiver inst vars in a frameless method since self exists
	 only in ReceiverResultReg in a frameless method.  So if ReceiverResultReg is
	 caller-saved we use the fact that ceStoreCheck: answers its argument to
	 reload ReceiverResultReg cheaply.  Otherwise we don't care about the result
	 and use the cResultRegister, effectively a no-op (see compileTrampoline...)"
	<inline: true>
	^(self isCallerSavedReg: ReceiverResultReg)
		ifTrue: [ReceiverResultReg]
		ifFalse: [backEnd cResultRegister]
]

{ #category : #'external primitive support' }
SimpleStackBasedCogit >> rewritePrimInvocationIn: cogMethod to: primFunctionPointer [
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	<var: #primFunctionPointer declareC: #'void (*primFunctionPointer)(void)'>
	| primIndex flags address extent |
	self cCode: [] inSmalltalk:
		[primFunctionPointer isInteger ifFalse:
			[^self rewritePrimInvocationIn: cogMethod to: (self simulatedTrampolineFor: primFunctionPointer)]].
	self assert: cogMethod cmType = CMMethod.
	primIndex := coInterpreter
					primitiveIndexOfMethod: cogMethod methodObject
					header: cogMethod methodHeader.
	flags := coInterpreter primitivePropertyFlags: primIndex.
	(flags anyMask: PrimCallNeedsPrimitiveFunction) ifTrue:
		[backEnd
			storeLiteral: primFunctionPointer asUnsignedInteger
			beforeFollowingAddress: cogMethod asUnsignedInteger
									+ (externalSetPrimOffsets at: cogMethod cmNumArgs)].
	"See compileInterpreterPrimitive:"
	(flags anyMask: PrimCallMayCallBack)
		ifTrue:
			[address := cogMethod asUnsignedInteger
						+ (externalPrimJumpOffsets at: cogMethod cmNumArgs).
			extent := backEnd
						rewriteJumpFullAt: address
						target: primFunctionPointer asUnsignedInteger]
		ifFalse:
			[address := cogMethod asUnsignedInteger
						+ (externalPrimCallOffsets at: cogMethod cmNumArgs).
			extent := backEnd
						rewriteCallFullAt: address
						target: primFunctionPointer asUnsignedInteger].
	processor
		flushICacheFrom: cogMethod asUnsignedInteger + cmNoCheckEntryOffset
		to: address asUnsignedInteger + extent
]

{ #category : #testing }
SimpleStackBasedCogit >> seemsToBeInstantiating: format [
	"Answers if the code is installed in a class instantiating objects with the format. Used in primitive 
	 generation to make a quick path based on where the method is installed. This method cannot
	 be used as a guarantee as there can be false positive, it's just a heuristic.
	 Tries to interpret the last literal of the method as a behavior (more than 3 fields, 3rd field a Smi).
	 If it can be interpreted as a behavior, answers if instSpec matches the format, else answers false."
	<inline: true>
	^ objectMemory maybeMethodClassOf: methodObj seemsToBeInstantiating: format
]

{ #category : #initialization }
SimpleStackBasedCogit >> setInterpreter: aCoInterpreter [
	"Initialization of the code generator in the simulator.
	 These objects already exist in the generated C VM
	 or are used only in the simulation."
	<doNotGenerate>
	super setInterpreter: aCoInterpreter.
	primitiveGeneratorTable := self class primitiveTable.
	externalPrimJumpOffsets := CArrayAccessor on: (Array new: MaxNumArgs + 1).
	externalPrimCallOffsets := CArrayAccessor on: (Array new: MaxNumArgs + 1).
	externalSetPrimOffsets := CArrayAccessor on: (Array new: MaxNumArgs + 1)
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> temporaryIndexOfFrameOffset: offset [
	^self temporaryIndexOfFrameOffset: offset numArgs: methodOrBlockNumArgs
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> temporaryIndexOfFrameOffset: offset numArgs: numArgs [
	"For assert checking..."
	^numArgs - ((offset < 0 "args are > 0"
					ifTrue: [offset - FoxMFReceiver + objectMemory wordSize]
					ifFalse: [offset - FoxCallerSavedIP]) / objectMemory wordSize)
]

{ #category : #'span functions' }
SimpleStackBasedCogit >> v3: descriptor Block: pc Code: nExts Size: aMethodObj [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	self assert: nExts <= 0.
	^((objectMemory fetchByte: pc + 2 ofObject: aMethodObj) << 8)
	+ (objectMemory fetchByte: pc + 3 ofObject: aMethodObj)
]

{ #category : #'span functions' }
SimpleStackBasedCogit >> v3: descriptor Long: pc Branch: nExts Distance: aMethodObj [
	"Answer the distance of a two byte forward long jump."
	<var: #descriptor type: #'BytecodeDescriptor *'>
	self assert: nExts = 0.
	^(((objectMemory fetchByte: pc ofObject: aMethodObj) bitAnd: 7) - 4 << 8)
	 + (objectMemory fetchByte: pc + 1 ofObject: aMethodObj)
]

{ #category : #'span functions' }
SimpleStackBasedCogit >> v3: descriptor LongForward: pc Branch: nExts Distance: aMethodObj [
	"Answer the distance of a two byte forward long jump."
	<var: #descriptor type: #'BytecodeDescriptor *'>
	self assert: nExts = 0.
	^(((objectMemory fetchByte: pc ofObject: aMethodObj) bitAnd: 3) << 8)
	 + (objectMemory fetchByte: pc + 1 ofObject: aMethodObj)
]

{ #category : #'span functions' }
SimpleStackBasedCogit >> v3: descriptor ShortForward: pc Branch: nExts Distance: aMethodObj [
	"N.B.  This serves for both BlueBook/V3 and V4 short jumps."
	<var: #descriptor type: #'BytecodeDescriptor *'>
	self assert: nExts = 0.
	^((objectMemory fetchByte: pc ofObject: aMethodObj) bitAnd: 7) + 1
]

{ #category : #'span functions' }
SimpleStackBasedCogit >> v4: descriptor Block: pc Code: nExts Size: aMethodObj [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	"253		11111101 eei i i kkk	jjjjjjjj		Push Closure Num Copied iii (+ Ext A // 16 * 8) Num Args kkk (+ Ext A \\ 16 * 8) BlockSize jjjjjjjj (+ Ext B * 256). ee = num extensions"
	| byteOne extBValue |
	byteOne := objectMemory fetchByte: pc + 1 ofObject: aMethodObj.
	"If nExts < 0 it isn't known and we rely on the number of extensions encoded in the eeiiikkk byte."
	self assert: (nExts < 0 or: [nExts = (byteOne >> 6)]).
	self parseV4Exts: byteOne >> 6 priorTo: pc in: aMethodObj into: [:ea :eb| extBValue := eb].
	^(objectMemory fetchByte: pc + 2 ofObject: aMethodObj)
	+ (extBValue << 8)
]

{ #category : #'span functions' }
SimpleStackBasedCogit >> v4: descriptor Long: pc Branch: nExts Distance: aMethodObj [
	"242		11110010	i i i i i i i i	Jump i i i i i i i i (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	<var: #descriptor type: #'BytecodeDescriptor *'>
	| extBValue |
	self assert: nExts >= 0.
	self parseV4Exts: nExts priorTo: pc in: aMethodObj into: [:ea :eb| extBValue := eb].
	^(objectMemory fetchByte: pc + 1 ofObject: aMethodObj)
	+ (extBValue << 8)
]

{ #category : #'span functions' }
SimpleStackBasedCogit >> v4: descriptor Long: pc BranchIfNotInstanceOf: nExts Distance: aMethodObj [
	"**	254		11111110	kkkkkkkk	jjjjjjjj		branch If Not Instance Of Behavior/Array Of Behavior kkkkkkkk (+ Extend A * 256, where Extend A >= 0) distance jjjjjjjj (+ Extend B * 256, where Extend B >= 0)"
	<var: #descriptor type: #'BytecodeDescriptor *'>
	| extBValue |
	self assert: nExts >= 0.
	self parseV4Exts: nExts priorTo: pc in: aMethodObj into: [:ea :eb| extBValue := eb].
	extBValue < 0 ifTrue: [extBValue := extBValue + 128].
	^(objectMemory fetchByte: pc + 2 ofObject: aMethodObj) + (extBValue << 8)
]

{ #category : #'span functions' }
SimpleStackBasedCogit >> v4: descriptor LongForward: pc Branch: nExts Distance: aMethodObj [
	"242		11110010	i i i i i i i i	Jump i i i i i i i i (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	"243		11110011	i i i i i i i i	Pop and Jump 0n True i i i i i i i i (+ Extend A * 256)"
	"244		11110100	i i i i i i i i	Pop and Jump 0n False i i i i i i i i (+ Extend A * 256)"
	<var: #descriptor type: #'BytecodeDescriptor *'>
	| extBValue |
	self assert: nExts >= 0.
	self parseV4Exts: nExts priorTo: pc in: aMethodObj into: [:ea :eb| extBValue := eb].
	^(objectMemory fetchByte: pc + 1 ofObject: aMethodObj)
	+ (extBValue << 8)
]

{ #category : #'jit - api' }
SimpleStackBasedCogit >> voidCogCompiledCode [
	<api>
	methodZone clearCogCompiledCode.
	0 to: MaxNumArgs do:
		[:i|
		externalPrimJumpOffsets at: i put: nil.
		externalPrimCallOffsets at: i put: nil.
		externalSetPrimOffsets at: i put: nil]
]

{ #category : #'bytecode generator support' }
SimpleStackBasedCogit >> voidReceiverOptStatus [
	"No op in this cogit. Provided for compatibility with the cleverer subclasses."
	<inline: true>
]
