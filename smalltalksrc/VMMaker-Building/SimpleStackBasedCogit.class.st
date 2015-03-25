"
I am the stage one JIT for Cog that does not attempt to eliminate the stack via deferred code generation.
"
Class {
	#name : #SimpleStackBasedCogit,
	#superclass : #Cogit,
	#instVars : [
		'externalPrimCallOffsets',
		'externalPrimJumpOffsets'
	],
	#pools : [
		'VMMethodCacheConstants',
		'VMObjectIndices'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
SimpleStackBasedCogit class >> ancilliaryClasses: options [
	initializationOptions ifNil:
		[initializationOptions := options].
	^(super ancilliaryClasses: options), (self objectRepresentationClass withAllSuperclasses copyUpThrough: CogObjectRepresentation) reverse
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
	aCCodeGenerator
		var: #externalPrimCallOffsets
			declareC: 'sqInt externalPrimCallOffsets[MaxNumArgs + 1]';
		var: #externalPrimJumpOffsets
			declareC: 'sqInt externalPrimJumpOffsets[MaxNumArgs + 1]'
]

{ #category : #'class initialization' }
SimpleStackBasedCogit class >> initializeBytecodeTableForNewspeakV3PlusClosures [
	"SimpleStackBasedCogit initializeBytecodeTableForNewspeakV3PlusClosures"

	NSSendIsPCAnnotated := true. "IsNSSendCall used by PushImplicitReceiver"
	FirstSpecialSelector := 176.
	self flag:
'Special selector send class must be inlined to agree with the interpreter, which
 inlines class.  If class is sent to e.g. a general instance of ProtoObject then unless
 class is inlined there will be an MNU.  It must be that the Cointerpreter and Cogit
 have identical semantics.  We get away with not hardwiring the other special
 selectors either because in the Cointerpreter they are not inlined or because they
 are inlined only to instances of classes for which there will always be a method.'.
	self generatorTableFrom: #(
		(1    0   15 genPushReceiverVariableBytecode)
		(1  16   31 genPushTemporaryVariableBytecode)
		(1  32   63 genPushLiteralConstantBytecode needsFrameNever: 1)
		(1  64   95 genPushLiteralVariableBytecode needsFrameNever: 1)
		(1  96 103 genStoreAndPopReceiverVariableBytecode needsFrameNever: -1) "N.B. not frameless if immutability"
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

		(3 126 126 genDynamicSuperSendBytecode isMapped)			"Newspeak"
		(2 127 127 genPushImplicitReceiverBytecode isMapped hasIRC)	"Newspeak"

		(2 128 128 extendedPushBytecode needsFrameNever: 1)
		(2 129 129 extendedStoreBytecode)
		(2 130 130 extendedStoreAndPopBytecode)
		(2 131 131 genExtendedSendBytecode isMapped)
		(3 132 132 doubleExtendedDoAnythingBytecode isMapped)
		(2 133 133 genExtendedSuperBytecode isMapped)
		(2 134 134 genSecondExtendedSendBytecode isMapped)
		(1 135 135 genPopStackBytecode needsFrameNever: -1)
		(1 136 136 duplicateTopBytecode needsFrameNever: 1)

		(1 137 137 genPushActiveContextBytecode)
		(2 138 138 genPushNewArrayBytecode)),

		((initializationOptions at: #SpurObjectMemory ifAbsent: [false])
			ifTrue: [#((3 139 139 callPrimitiveBytecode))]									"V3PlusClosures on Spur"
			ifFalse: [#((2 139 139 genPushEnclosingObjectBytecode isMapped))]),	"Newspeak"

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
		(1 200 207 genSpecialSelectorSend isMapped)
		(1 208 223 genSendLiteralSelector0ArgsBytecode isMapped)
		(1 224 239 genSendLiteralSelector1ArgBytecode isMapped)
		(1 240 255 genSendLiteralSelector2ArgsBytecode isMapped))
]

{ #category : #'class initialization' }
SimpleStackBasedCogit class >> initializeBytecodeTableForNewspeakV4 [
	"SimpleStackBasedCogit initializeBytecodeTableForNewspeakV4"

	NSSendIsPCAnnotated := false. "IsNSSendCall used by SendAbsentImplicit"
	FirstSpecialSelector := 80.
	self flag:
'Special selector send class must be inlined to agree with the interpreter, which
 inlines class.  If class is sent to e.g. a general instance of ProtoObject then unless
 class is inlined there will be an MNU.  It must be that the Cointerpreter and Cogit
 have identical semantics.  We get away with not hardwiring the other special
 selectors either because in the Cointerpreter they are not inlined or because they
 are inlined only to instances of classes for which there will always be a method.'.
	self generatorTableFrom: #(
		"1 byte bytecodes"
		(1    0   15 genPushReceiverVariableBytecode)
		(1  16   31 genPushLiteralVariable16CasesBytecode needsFrameNever: 1)
		(1  32   63 genPushLiteralConstantBytecode needsFrameNever: 1)
		(1  64   75 genPushTemporaryVariableBytecode)
		(1  76   76 genPushReceiverBytecode)
		(1  77   77 genExtPushPseudoVariableOrOuterBytecode)
		(1  78   78 genPushConstantZeroBytecode)
		(1  79   79 genPushConstantOneBytecode)

		(1   80 101 genSpecialSelectorSend isMapped) "#+ #- #< #> #<= #>= #= #~= #* #/ #\\ #@ #bitShift: #// #bitAnd: #bitOr: #at: #at:put: #size #next #nextPut: #atEnd"
		(1 102 102 genSpecialSelectorEqualsEquals needsFrameNever: notMapped -1) "not mapped because it is directly inlined (for now)"
		(1 103 103 genSpecialSelectorClass needsFrameNever: notMapped 0) "not mapped because it is directly inlined (for now)"
		(1 104 111 genSpecialSelectorSend isMapped) "#blockCopy: #value #value: #do: #new #new: #x #y"

		(1 112 127 genSendLiteralSelector0ArgsBytecode isMapped)
		(1 128 143 genSendLiteralSelector1ArgBytecode isMapped)
		(1 144 159 genSendLiteralSelector2ArgsBytecode isMapped)
		(1 160 175	genSendAbsentImplicit0ArgsBytecode isMapped hasIRC)

		(1 176 183 genStoreAndPopReceiverVariableBytecode needsFrameNever: -1) "N.B. not frameless if immutability"
		(1 184 191 genStoreAndPopTemporaryVariableBytecode)

		(1 192 199 genShortUnconditionalJump	branch v3:ShortForward:Branch:Distance:)
		(1 200 207 genShortJumpIfTrue			branch isBranchTrue isMapped "because of mustBeBoolean"
													v3:ShortForward:Branch:Distance:)
		(1 208 215 genShortJumpIfFalse			branch isBranchFalse isMapped "because of mustBeBoolean"
													v3:ShortForward:Branch:Distance:)

		(1 216 216 genReturnReceiver				return needsFrameIfInBlock: isMappedInBlock 0)
		(1 217 217 genReturnTopFromMethod		return needsFrameIfInBlock: isMappedInBlock -1)
		(1 218 218 genExtReturnTopFromBlock	return needsFrameNever: -1)

		(1 219 219 duplicateTopBytecode			needsFrameNever: 1)
		(1 220 220 genPopStackBytecode			needsFrameNever: -1)
		(1 221 221 genExtNopBytecode			needsFrameNever: 0)
		(1 222 223	unknownBytecode)

		"2 byte bytecodes"
		(2 224 224 extABytecode extension)
		(2 225 225 extBBytecode extension)
		(2 226 226 genExtPushReceiverVariableBytecode)
		(2 227 227 genExtPushLiteralVariableBytecode		needsFrameNever: 1)
		(2 228 228 genExtPushLiteralBytecode					needsFrameNever: 1)
		(2 229 229 genExtPushIntegerBytecode				needsFrameNever: 1)
		(2 230 230 genLongPushTemporaryVariableBytecode)
		(2 231 231 genPushNewArrayBytecode)
		(2 232 232 genExtStoreReceiverVariableBytecode)
		(2 233 233 genExtStoreLiteralVariableBytecode)
		(2 234 234 genLongStoreTemporaryVariableBytecode)
		(2 235 235 genExtStoreAndPopReceiverVariableBytecode)
		(2 236 236 genExtStoreAndPopLiteralVariableBytecode)
		(2 237 237 genLongStoreAndPopTemporaryVariableBytecode)

		(2 238 238 genExtSendBytecode isMapped)
		(2 239 239 genExtSendSuperBytecode isMapped)
		(2 240 240 genExtSendAbsentImplicitBytecode isMapped hasIRC)
		(2 241 241 genExtSendAbsentDynamicSuperBytecode isMapped)

		(2 242 242 genExtUnconditionalJump	branch isMapped "because of interrupt check" v4:Long:Branch:Distance:)
		(2 243 243 genExtJumpIfTrue			branch isBranchTrue isMapped "because of mustBeBoolean" v4:Long:Branch:Distance:)
		(2 244 244 genExtJumpIfFalse			branch isBranchFalse isMapped "because of mustBeBoolean" v4:Long:Branch:Distance:)

		(2 245 245 genExtSendAbsentSelfBytecode isMapped)

		(2 246 248	unknownBytecode)

		"3 byte bytecodes"
		(3 249 249 callPrimitiveBytecode)
		(3 250 250 genPushRemoteTempLongBytecode)
		(3 251 251 genStoreRemoteTempLongBytecode)
		(3 252 252 genStoreAndPopRemoteTempLongBytecode)
		(3 253 253 genExtPushClosureBytecode block v4:Block:Code:Size:)
		(3 254 254 genExtSendAbsentOuterBytecode isMapped)

		(3 255 255	unknownBytecode))
]

{ #category : #'class initialization' }
SimpleStackBasedCogit class >> initializeBytecodeTableForSistaV1 [
	"SimpleStackBasedCogit initializeBytecodeTableForSistaV1"

	FirstSpecialSelector := 96.
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
		(1    0   15 genPushReceiverVariableBytecode)
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
		(1 120 127 genSpecialSelectorSend isMapped) "#blockCopy: #value #value: #do: #new #new: #x #y"

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
		(1 200 207 genStoreAndPopReceiverVariableBytecode needsFrameNever: -1) "N.B. not frameless if immutability"
		(1 208 215 genStoreAndPopTemporaryVariableBytecode)

		(1 216 216 genPopStackBytecode needsFrameNever: -1)

		(1 217 223 unknownBytecode)

		"2 byte bytecodes"
		(2 224 224 extABytecode extension)
		(2 225 225 extBBytecode extension)

		"pushes"
		(2 226 226 genExtPushReceiverVariableBytecode)
		(2 227 227 genExtPushLiteralVariableBytecode		needsFrameNever: 1)
		(2 228 228 genExtPushLiteralBytecode					needsFrameNever: 1)
		(2 229 229 genLongPushTemporaryVariableBytecode)
		(2 230 230 genPushClosureTempsBytecode)
		(2 231 231 genPushNewArrayBytecode)
		(2 232 232 genExtPushIntegerBytecode				needsFrameNever: 1)
		(2 233 233 genExtPushCharacterBytecode				needsFrameNever: 1)

		"returns"
		"sends"
		(2 234 234 genExtSendBytecode isMapped)
		(2 235 235 genExtSendSuperBytecode isMapped)

		"sista bytecodes"
		(2 236 236 genExtTrapIfNotInstanceOfBehaviorsBytecode isMapped)

		"jumps"
		(2 237 237 genExtUnconditionalJump	branch isMapped "because of interrupt check" v4:Long:Branch:Distance:)
		(2 238 238 genExtJumpIfTrue			branch isBranchTrue isMapped "because of mustBeBoolean" v4:Long:Branch:Distance:)
		(2 239 239 genExtJumpIfFalse			branch isBranchFalse isMapped "because of mustBeBoolean" v4:Long:Branch:Distance:)

		"stores"
		(2 240 240 genExtStoreAndPopReceiverVariableBytecode)
		(2 241 241 genExtStoreAndPopLiteralVariableBytecode)
		(2 242 242 genLongStoreAndPopTemporaryVariableBytecode)
		(2 243 243 genExtStoreReceiverVariableBytecode)
		(2 244 244 genExtStoreLiteralVariableBytecode)
		(2 245 245 genLongStoreTemporaryVariableBytecode)

		(2 246 247	unknownBytecode)

		"3 byte bytecodes"
		(3 248 248 genCallPrimitiveBytecode)
		(3 249 249 unknownBytecode) "reserved for Push Float"
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
	self flag:
'Special selector send class must be inlined to agree with the interpreter, which
 inlines class.  If class is sent to e.g. a general instance of ProtoObject then unless
 class is inlined there will be an MNU.  It must be that the Cointerpreter and Cogit
 have identical semantics.  We get away with not hardwiring the other special
 selectors either because in the Cointerpreter they are not inlined or because they
 are inlined only to instances of classes for which there will always be a method.'.
	self generatorTableFrom: #(
		(1    0   15 genPushReceiverVariableBytecode)
		(1  16   31 genPushTemporaryVariableBytecode)
		(1  32   63 genPushLiteralConstantBytecode needsFrameNever: 1)
		(1  64   95 genPushLiteralVariableBytecode needsFrameNever: 1)
		(1  96 103 genStoreAndPopReceiverVariableBytecode needsFrameNever: -1) "N.B. not frameless if immutability"
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

		(2 128 128 extendedPushBytecode needsFrameNever: 1)
		(2 129 129 extendedStoreBytecode)
		(2 130 130 extendedStoreAndPopBytecode)
		(2 131 131 genExtendedSendBytecode isMapped)
		(3 132 132 doubleExtendedDoAnythingBytecode isMapped)
		(2 133 133 genExtendedSuperBytecode isMapped)
		(2 134 134 genSecondExtendedSendBytecode isMapped)
		(1 135 135 genPopStackBytecode needsFrameNever: -1)
		(1 136 136 duplicateTopBytecode needsFrameNever: 1)

		(1 137 137 genPushActiveContextBytecode)
		(2 138 138 genPushNewArrayBytecode)),

		((initializationOptions at: #SpurObjectMemory ifAbsent: [false])
			ifTrue: [#((3 139 139 callPrimitiveBytecode))]
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
		(1 200 207 genSpecialSelectorSend isMapped)
		(1 208 223 genSendLiteralSelector0ArgsBytecode isMapped)
		(1 224 239 genSendLiteralSelector1ArgBytecode isMapped)
		(1 240 255 genSendLiteralSelector2ArgsBytecode isMapped))
]

{ #category : #'class initialization' }
SimpleStackBasedCogit class >> initializeMiscConstants [
	super initializeMiscConstants.
	MaxLiteralCountForCompile := initializationOptions at: #MaxLiteralCountForCompile ifAbsent: [60].
	NumTrampolines := NewspeakVM
							ifTrue: [50]
							ifFalse: [42]
]

{ #category : #'class initialization' }
SimpleStackBasedCogit class >> initializePrimitiveTableForNewsqueak [
	"Initialize the table of primitive generators.  This does not include normal primitives implemented in the coInterpreter."
	"SimpleStackBasedCogit initializePrimitiveTableForSqueakV3"
	MaxCompiledPrimitiveIndex := 222.
	primitiveTable := CArrayAccessor on: (Array new: MaxCompiledPrimitiveIndex + 1).
	self table: primitiveTable from: 
	#(	"Integer Primitives (0-19)"
		(1 genPrimitiveAdd				1	mclassIsSmallInteger:)
		(2 genPrimitiveSubtract			1	mclassIsSmallInteger:)
		(3 genPrimitiveLessThan		1	mclassIsSmallInteger:)
		(4 genPrimitiveGreaterThan		1	mclassIsSmallInteger:)
		(5 genPrimitiveLessOrEqual		1	mclassIsSmallInteger:)
		(6 genPrimitiveGreaterOrEqual	1	mclassIsSmallInteger:)
		(7 genPrimitiveEqual			1	mclassIsSmallInteger:)
		(8 genPrimitiveNotEqual		1	mclassIsSmallInteger:)
		(9 genPrimitiveMultiply			1	processorHasMultiplyAndMClassIsSmallInteger:)
		(10 genPrimitiveDivide			1	processorHasDivQuoRemAndMClassIsSmallInteger:)
		(11 genPrimitiveMod			1	processorHasDivQuoRemAndMClassIsSmallInteger:)
		(12 genPrimitiveDiv				1	processorHasDivQuoRemAndMClassIsSmallInteger:)
		(13 genPrimitiveQuo			1	processorHasDivQuoRemAndMClassIsSmallInteger:)
		(14 genPrimitiveBitAnd			1	mclassIsSmallInteger:)
		(15 genPrimitiveBitOr			1	mclassIsSmallInteger:)
		(16 genPrimitiveBitXor			1	mclassIsSmallInteger:)
		(17 genPrimitiveBitShift			1	mclassIsSmallInteger:)
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
		"(38 primitiveFloatAt)"
		"(39 primitiveFloatAtPut)"
		(40 genPrimitiveAsFloat					0	processorHasDoublePrecisionFloatingPointSupport:)
		(41 genPrimitiveFloatAdd				1	processorHasDoublePrecisionFloatingPointSupport:)
		(42 genPrimitiveFloatSubtract			1	processorHasDoublePrecisionFloatingPointSupport:)
		(43 genPrimitiveFloatLessThan			1	processorHasDoublePrecisionFloatingPointSupport:)
		(44 genPrimitiveFloatGreaterThan		1	processorHasDoublePrecisionFloatingPointSupport:)
		(45 genPrimitiveFloatLessOrEqual		1	processorHasDoublePrecisionFloatingPointSupport:)
		(46 genPrimitiveFloatGreaterOrEqual	1	processorHasDoublePrecisionFloatingPointSupport:)
		(47 genPrimitiveFloatEqual				1	processorHasDoublePrecisionFloatingPointSupport:)
		(48 genPrimitiveFloatNotEqual			1	processorHasDoublePrecisionFloatingPointSupport:)
		(49 genPrimitiveFloatMultiply			1	processorHasDoublePrecisionFloatingPointSupport:)
		(50 genPrimitiveFloatDivide				1	processorHasDoublePrecisionFloatingPointSupport:)
		"(51 primitiveTruncated)"
		"(52 primitiveFractionalPart)"
		"(53 primitiveExponent)"
		"(54 primitiveTimesTwoPower)"
		(55 genPrimitiveFloatSquareRoot		0	processorHasDoublePrecisionFloatingPointSupport:)
		"(56 primitiveSine)"
		"(57 primitiveArctan)"
		"(58 primitiveLogN)"
		"(59 primitiveExp)"

		"Subscript and Stream Primitives (60-67)"
		(60 genPrimitiveAt				1)
		(61 genPrimitiveAtPut			2)
		(62 genPrimitiveSize			0)
		(63 genPrimitiveStringAt		1)
		(64 genPrimitiveStringAtPut		2)
		"The stream primitives no longer pay their way; normal Smalltalk code is faster."
		"(65 primitiveFail)""was primitiveNext"
		"(66 primitiveFail)" "was primitiveNextPut"
		"(67 primitiveFail)" "was primitiveAtEnd"

		"StorageManagement Primitives (68-79)"
		"(68 primitiveObjectAt)"
		"(69 primitiveObjectAtPut)"
		(70 genPrimitiveNew			-1)			"For VMMirror support 1 argument instantiateFixedClass: as well as baiscNew"
		(71 genPrimitiveNewWithArg	-1)			"For VMMirror support 2 argument instantiateVariableClass:withSize: as well as baiscNew:"
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
		"(83 primitivePerform)"
		"(84 primitivePerformWithArgs)"
		"(85 primitiveSignal)"
		"(86 primitiveWait)"
		"(87 primitiveResume)"
		"(88 primitiveSuspend)"
		"(89 primitiveFlushCache)"

		"Input/Output Primitives (90-109); We won't compile any of these"

		"System Primitives (110-119)"
		(110 genPrimitiveIdentical 1)
		(111 genPrimitiveClass)
		"(112 primitiveBytesLeft)"
		"(113 primitiveQuit)"
		"(114 primitiveExitToDebugger)"
		"(115 primitiveChangeClass)"					"Blue Book: primitiveOopsLeft"
		"(116 primitiveFlushCacheByMethod)"
		"(117 primitiveExternalCall)"
		"(118 primitiveDoPrimitiveWithArgs)"
		"(119 primitiveFlushCacheSelective)"
			"Squeak 2.2 and earlier use 119.  Squeak 2.3 and later use 116.
			Both are supported for backward compatibility."

		"Miscellaneous Primitives (120-127); We won't compile any of these"

		"Squeak Primitives Start Here"

		"Squeak Miscellaneous Primitives (128-149); We won't compile any of these"

		"File Primitives (150-169) - NO LONGER INDEXED; We won't compile any of these"
		(169 genPrimitiveNotIdentical 1)

		(170 genPrimitiveAsCharacter)			"SmallInteger>>asCharacter, Character class>>value:"
		(171 genPrimitiveCharacterValue 0)	"Character>>value"
		"Sound Primitives (170-199) - NO LONGER INDEXED; We won't compile any of these"
		(175 genPrimitiveIdentityHash	0)		"Behavior>>identityHash"
		"Sound Primitives (170-199) - NO LONGER INDEXED; We won't compile any of these"

		"Old closure primitives"
		"(186 primitiveFail)" "was primitiveClosureValue"
		"(187 primitiveFail)" "was primitiveClosureValueWithArgs"

		"Perform method directly"
		"(188 primitiveExecuteMethodArgsArray)"
		"(189 primitiveExecuteMethod)"

		"Sound Primitives (continued) - NO LONGER INDEXED; We won't compile any of these"
		"(190 194 primitiveFail)"

		"Unwind primitives"
		"(195 primitiveFindNextUnwindContext)"
		"(196 primitiveTerminateTo)"
		"(197 primitiveFindHandlerContext)"
		(198 genFastPrimFail "primitiveMarkUnwindMethod")
		(199 genFastPrimFail "primitiveMarkHandlerMethod")

		"new closure primitives (were Networking primitives)"
		"(200 primitiveClosureCopyWithCopiedValues)"
		(201 genPrimitiveClosureValue	0) "value"
		(202 genPrimitiveClosureValue	1) "value:"
		(203 genPrimitiveClosureValue	2) "value:value:"
		(204 genPrimitiveClosureValue	3) "value:value:value:"
		(205 genPrimitiveClosureValue	4) "value:value:value:value:"
		"(206 genPrimitiveClosureValueWithArgs)" "valueWithArguments:"

		"(207 209 primitiveFail)"	"reserved for Cog primitives"

		"(210 primitiveContextAt)"
		"(211 primitiveContextAtPut)"
		"(212 primitiveContextSize)"
		"(213 217 primitiveFail)"	"reserved for Cog primitives"
		"(218 primitiveDoNamedPrimitiveWithArgs)"
		"(219 primitiveFail)"	"reserved for Cog primitives"

		"(220 primitiveFail)"		"reserved for Cog primitives"

		(221 genPrimitiveClosureValue	0) "valueNoContextSwitch"
		(222 genPrimitiveClosureValue	1) "valueNoContextSwitch:"

		"(223 229 primitiveFail)"	"reserved for Cog primitives"
	)
]

{ #category : #'class initialization' }
SimpleStackBasedCogit class >> initializePrimitiveTableForSqueak [
	"Initialize the table of primitive generators.  This does not include normal primitives implemented in the coInterpreter."
	"SimpleStackBasedCogit initializePrimitiveTableForSqueak"
	MaxCompiledPrimitiveIndex := 222.
	primitiveTable := CArrayAccessor on: (Array new: MaxCompiledPrimitiveIndex + 1).
	self table: primitiveTable from: 
	#(	"Integer Primitives (0-19)"
		(1 genPrimitiveAdd				1	mclassIsSmallInteger:)
		(2 genPrimitiveSubtract			1	mclassIsSmallInteger:)
		(3 genPrimitiveLessThan		1	mclassIsSmallInteger:)
		(4 genPrimitiveGreaterThan		1	mclassIsSmallInteger:)
		(5 genPrimitiveLessOrEqual		1	mclassIsSmallInteger:)
		(6 genPrimitiveGreaterOrEqual	1	mclassIsSmallInteger:)
		(7 genPrimitiveEqual			1	mclassIsSmallInteger:)
		(8 genPrimitiveNotEqual		1	mclassIsSmallInteger:)
		(9 genPrimitiveMultiply			1	processorHasMultiplyAndMClassIsSmallInteger:)
		(10 genPrimitiveDivide			1	processorHasDivQuoRemAndMClassIsSmallInteger:)
		(11 genPrimitiveMod			1	processorHasDivQuoRemAndMClassIsSmallInteger:)
		(12 genPrimitiveDiv				1	processorHasDivQuoRemAndMClassIsSmallInteger:)
		(13 genPrimitiveQuo			1	processorHasDivQuoRemAndMClassIsSmallInteger:)
		(14 genPrimitiveBitAnd			1	mclassIsSmallInteger:)
		(15 genPrimitiveBitOr			1	mclassIsSmallInteger:)
		(16 genPrimitiveBitXor			1	mclassIsSmallInteger:)
		(17 genPrimitiveBitShift			1	mclassIsSmallInteger:)
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
		"(38 primitiveFloatAt)"
		"(39 primitiveFloatAtPut)"
		(40 genPrimitiveAsFloat					0	processorHasDoublePrecisionFloatingPointSupport:)
		(41 genPrimitiveFloatAdd				1	processorHasDoublePrecisionFloatingPointSupport:)
		(42 genPrimitiveFloatSubtract			1	processorHasDoublePrecisionFloatingPointSupport:)
		(43 genPrimitiveFloatLessThan			1	processorHasDoublePrecisionFloatingPointSupport:)
		(44 genPrimitiveFloatGreaterThan		1	processorHasDoublePrecisionFloatingPointSupport:)
		(45 genPrimitiveFloatLessOrEqual		1	processorHasDoublePrecisionFloatingPointSupport:)
		(46 genPrimitiveFloatGreaterOrEqual	1	processorHasDoublePrecisionFloatingPointSupport:)
		(47 genPrimitiveFloatEqual				1	processorHasDoublePrecisionFloatingPointSupport:)
		(48 genPrimitiveFloatNotEqual			1	processorHasDoublePrecisionFloatingPointSupport:)
		(49 genPrimitiveFloatMultiply			1	processorHasDoublePrecisionFloatingPointSupport:)
		(50 genPrimitiveFloatDivide				1	processorHasDoublePrecisionFloatingPointSupport:)
		"(51 primitiveTruncated)"
		"(52 primitiveFractionalPart)"
		"(53 primitiveExponent)"
		"(54 primitiveTimesTwoPower)"
		(55 genPrimitiveFloatSquareRoot		0	processorHasDoublePrecisionFloatingPointSupport:)
		"(56 primitiveSine)"
		"(57 primitiveArctan)"
		"(58 primitiveLogN)"
		"(59 primitiveExp)"

		"Subscript and Stream Primitives (60-67)"
		(60 genPrimitiveAt				1)
		(61 genPrimitiveAtPut			2)
		(62 genPrimitiveSize			0)
		(63 genPrimitiveStringAt		1)
		(64 genPrimitiveStringAtPut		2)
		"The stream primitives no longer pay their way; normal Smalltalk code is faster."
		"(65 primitiveFail)""was primitiveNext"
		"(66 primitiveFail)" "was primitiveNextPut"
		"(67 primitiveFail)" "was primitiveAtEnd"

		"StorageManagement Primitives (68-79)"
		"(68 primitiveObjectAt)"
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
		"(83 primitivePerform)"
		"(84 primitivePerformWithArgs)"
		"(85 primitiveSignal)"
		"(86 primitiveWait)"
		"(87 primitiveResume)"
		"(88 primitiveSuspend)"
		"(89 primitiveFlushCache)"

		"Input/Output Primitives (90-109); We won't compile any of these"

		"System Primitives (110-119)"
		(110 genPrimitiveIdentical 1)
		(111 genPrimitiveClass)
		"(112 primitiveBytesLeft)"
		"(113 primitiveQuit)"
		"(114 primitiveExitToDebugger)"
		"(115 primitiveChangeClass)"					"Blue Book: primitiveOopsLeft"
		"(116 primitiveFlushCacheByMethod)"
		"(117 primitiveExternalCall)"
		"(118 primitiveDoPrimitiveWithArgs)"
		"(119 primitiveFlushCacheSelective)"
			"Squeak 2.2 and earlier use 119.  Squeak 2.3 and later use 116.
			Both are supported for backward compatibility."

		"Miscellaneous Primitives (120-127); We won't compile any of these"

		"Squeak Primitives Start Here"

		"Squeak Miscellaneous Primitives (128-149); We won't compile any of these"

		"File Primitives (150-169) - NO LONGER INDEXED; We won't compile any of these"
		(169 genPrimitiveNotIdentical 1)

		(170 genPrimitiveAsCharacter)			"SmallInteger>>asCharacter, Character class>>value:"
		(171 genPrimitiveCharacterValue 0)	"Character>>value"
		"Sound Primitives (170-199) - NO LONGER INDEXED; We won't compile any of these"
		(175 genPrimitiveIdentityHash	0)		"Behavior>>identityHash"
		"Sound Primitives (170-199) - NO LONGER INDEXED; We won't compile any of these"

		"Old closure primitives"
		"(186 primitiveFail)" "was primitiveClosureValue"
		"(187 primitiveFail)" "was primitiveClosureValueWithArgs"

		"Perform method directly"
		"(188 primitiveExecuteMethodArgsArray)"
		"(189 primitiveExecuteMethod)"

		"Sound Primitives (continued) - NO LONGER INDEXED; We won't compile any of these"
		"(190 194 primitiveFail)"

		"Unwind primitives"
		"(195 primitiveFindNextUnwindContext)"
		"(196 primitiveTerminateTo)"
		"(197 primitiveFindHandlerContext)"
		(198 genFastPrimFail "primitiveMarkUnwindMethod")
		(199 genFastPrimFail "primitiveMarkHandlerMethod")

		"new closure primitives (were Networking primitives)"
		"(200 primitiveClosureCopyWithCopiedValues)"
		(201 genPrimitiveClosureValue	0) "value"
		(202 genPrimitiveClosureValue	1) "value:"
		(203 genPrimitiveClosureValue	2) "value:value:"
		(204 genPrimitiveClosureValue	3) "value:value:value:"
		(205 genPrimitiveClosureValue	4) "value:value:value:value:"
		"(206 genPrimitiveClosureValueWithArgs)" "valueWithArguments:"

		"(207 209 primitiveFail)"	"reserved for Cog primitives"

		"(210 primitiveContextAt)"
		"(211 primitiveContextAtPut)"
		"(212 primitiveContextSize)"
		"(213 217 primitiveFail)"	"reserved for Cog primitives"
		"(218 primitiveDoNamedPrimitiveWithArgs)"
		"(219 primitiveFail)"	"reserved for Cog primitives"

		"(220 primitiveFail)"		"reserved for Cog primitives"

		(221 genPrimitiveClosureValue	0) "valueNoContextSwitch"
		(222 genPrimitiveClosureValue	1) "valueNoContextSwitch:"

		"(223 229 primitiveFail)"	"reserved for Cog primitives"
	)
]

{ #category : #'simulation only' }
SimpleStackBasedCogit >> bytecodeFixupClass [
	<doNotGenerate>
	^CogBytecodeFixup
]

{ #category : #trampolines }
SimpleStackBasedCogit >> cPICMissTrampolineFor: numArgs [
	^ceCPICMissTrampoline
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> callPrimitiveBytecode [
	"V3PlusClosures:	139 10001011	iiiiiiii   jjjjjjjj  Call Primitive #iiiiiiii + (jjjjjjjj * 256)
	 NewsqueakV4:		249 11111001	iiiiiiii   jjjjjjjj  Call Primitive #iiiiiiii + (jjjjjjjj * 256)
	 SistaV1:			248 11111000 iiiiiiii mjjjjjjj  Call Primitive #iiiiiiii + ( jjjjjjj * 256)
							m=1 means inlined primitive, no hard return after execution."
	self assert: (primitiveIndex = (byte1 + (byte2 << 8))
				or: [primitiveIndex = 0 "disabled primitives, e.g. stream prims"
					and: [(coInterpreter primitiveIndexOf: methodObj) = (byte1 + (byte2 << 8))]]).
	^0
]

{ #category : #trampolines }
SimpleStackBasedCogit >> ceClosureCopyDescriptor: descriptor [ "<Integer>" 
	^coInterpreter
		createClosureNumArgs: (descriptor bitAnd: 16r3F)
		numCopied: ((descriptor >> 6) bitAnd: 16r3F)
		startpc: descriptor >> 12
]

{ #category : #'simulation only' }
SimpleStackBasedCogit >> ceShortCutTraceBlockActivation: aProcessorSimulationTrap [
	self shortcutTrampoline: aProcessorSimulationTrap
		to: [coInterpreter ceTraceBlockActivation]
]

{ #category : #'simulation only' }
SimpleStackBasedCogit >> ceShortCutTraceLinkedSend: aProcessorSimulationTrap [
	self shortcutTrampoline: aProcessorSimulationTrap
		to: [coInterpreter ceTraceLinkedSend: (processor registerAt: (backEnd concreteRegister: ReceiverResultReg))]
]

{ #category : #'simulation only' }
SimpleStackBasedCogit >> ceShortCutTraceStore: aProcessorSimulationTrap [
	<doNotGenerate>
	self shortcutTrampoline: aProcessorSimulationTrap
		to: [coInterpreter
				ceTraceStoreOf: (processor registerAt: (backEnd concreteRegister: ClassReg))
				into: (processor registerAt: (backEnd concreteRegister: ReceiverResultReg))]
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
	inBlock := true.
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
	"The block method field must have its MFMethodFlagIsBlockFlag bit set.
	 We arrange this using a labelOffset.  A hack, but it works."
	blockStart fakeHeader
		addDependent: (self annotateAbsolutePCRef:
			(self PushCw: blockStart fakeHeader asInteger)); "method"
		setLabelOffset: MFMethodFlagIsBlockFlag.
	self annotate: (self PushCw: objectMemory nilObject) "context"
		objRef: objectMemory nilObject.
	"fetch home receiver from outer context. closure is on stack and initially in ReceiverResultReg"
	objectRepresentation
		genLoadSlot: ClosureOuterContextIndex
			sourceReg: ReceiverResultReg
				destReg: TempReg;
		genLoadSlot: ReceiverIndex
			sourceReg: TempReg
				destReg: ClassReg.
	self PushR: ClassReg. "home receiver"
	"Push copied values; bytecode initializes temporaries"
	0 to: blockStart numCopied - 1 do:
		[:i|
		objectRepresentation
			genLoadSlot: i + ClosureFirstCopiedValueIndex
			sourceReg: ReceiverResultReg
			destReg: TempReg.
		self PushR: TempReg].
	self MoveR: ClassReg R: ReceiverResultReg.
	self MoveAw: coInterpreter stackLimitAddress R: TempReg.
	self CmpR: TempReg R: SPReg. "N.B. FLAGS := SPReg - TempReg"
	self JumpBelow: stackOverflowCall.
	blockStart stackCheckLabel: (self annotateBytecode: self Label)
]

{ #category : #'compile abstract instructions' }
SimpleStackBasedCogit >> compileBlockFramelessEntry: blockStart [
	"Make sure ReceiverResultReg holds the receiver, loaded from the closure,
	 which is what is initially in ReceiverResultReg.  We must annotate the first
	 instruction so that findMethodForStartBcpc:inHomeMethod: can function.
	 We need two annotations because the first is a fiducial."
	<var: #blockStart type: #'BlockStart *'>
	self annotateBytecode: blockStart entryLabel.
	self annotateBytecode: blockStart entryLabel.
	objectRepresentation
		genLoadSlot: ClosureOuterContextIndex
			sourceReg: ReceiverResultReg
				destReg: TempReg;
		genLoadSlot: ReceiverIndex
			sourceReg: TempReg
				destReg: ReceiverResultReg
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> compileFallbackToInterpreterPrimitive [
	<inline: false>
	^self compileInterpreterPrimitive: (coInterpreter
											functionPointerForCompiledMethod: methodObj
											primitiveIndex: primitiveIndex)
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
	| methodHeader jumpSkip |
	<inline: false>
	<var: #jumpSkip type: #'AbstractInstruction *'>
	needsFrame ifFalse: [^0].
	methodHeader := objectMemory methodHeaderOf: methodObj.
	backEnd hasLinkRegister ifTrue: [self PushR: LinkReg].
	self PushR: FPReg.
	self MoveR: SPReg R: FPReg.
	methodLabel addDependent: (self annotateAbsolutePCRef:
		(self PushCw: methodLabel asInteger)). "method"
	self annotate: (self MoveCw: objectMemory nilObject R: SendNumArgsReg)
		objRef: objectMemory nilObject.
	self PushR: SendNumArgsReg. "context"
	self PushR: ReceiverResultReg.
	methodOrBlockNumArgs + 1 to: (coInterpreter temporaryCountOfMethodHeader: methodHeader) do:
		[:i|
		self PushR: SendNumArgsReg].
	(primitiveIndex > 0
	 and: [(coInterpreter longStoreBytecodeForHeader: methodHeader)
			= (objectMemory
				fetchByte: initialPC + (coInterpreter sizeOfCallPrimitiveBytecode: methodHeader)
				ofObject: methodObj)]) ifTrue:
		[self compileGetErrorCode.
		 initialPC := initialPC
				   + (coInterpreter sizeOfCallPrimitiveBytecode: methodHeader)
				   + (coInterpreter sizeOfLongStoreTempBytecode: methodHeader)].
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
	self annotateBytecode: stackCheckLabel.
	self cppIf: #NewspeakVM ifTrue:
		[numIRCs > 0 ifTrue:
		 	[self PrefetchAw: theIRCs]]
]

{ #category : #'compile abstract instructions' }
SimpleStackBasedCogit >> compileGetErrorCode [
	"After pushing the temporaries but before the stack limit check a primitive method
	 needs to fetch the error code, if any, and replace the last temp with it."
	<inline: false>
	| jmpNoError primErrorTable primErrorTableSize jmpIntError jmpGotError |
	<var: #jmpNoError type: #'AbstractInstruction *'>
	<var: #jmpIntError type: #'AbstractInstruction *'>
	<var: #jmpGotError type: #'AbstractInstruction *'>
	self MoveAw: coInterpreter primFailCodeAddress R: TempReg.
	self flag: 'ask concrete code gen if move sets condition codes?'.
	self CmpCq: 0 R: TempReg.
	jmpNoError := self JumpZero: 0.
	primErrorTable := coInterpreter primErrTable.
	primErrorTableSize := objectMemory lengthOf: primErrorTable.
	self flag: 'use CmpCqR if pc mapping means stable contexts never contain native pcs'.
	"Can't use CmpCqR here because table could change its size.
	 Assume generated code is flushed whenever primitive error table is changed."
	self CmpCw: primErrorTableSize R: TempReg.
	jmpIntError := self JumpAboveOrEqual: 0. "Filter out negative values as well"
	objectRepresentation genFetchIndexRegister: TempReg from: primErrorTable into: ClassReg.
	jmpGotError := self Jump: 0.
	jmpIntError jmpTarget: self Label.
	objectRepresentation genConvertIntegerToSmallIntegerInReg: TempReg.
	self MoveR: TempReg R: ClassReg.
	jmpGotError jmpTarget: (self MoveR: ClassReg Mw: 0 r: SPReg).
	"zero the error code to agree with the interpreter's (internal)ActivateNewMethod."
	self MoveCq: 0 R: TempReg.
	self MoveR: TempReg Aw: coInterpreter primFailCodeAddress.
	jmpNoError jmpTarget: self Label
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> compileInterpreterPrimitive: primitiveRoutine [
	"Compile a call to an interpreter primitive.  Call the C routine with the
	 usual stack-switching dance, test the primFailCode and then either
	 return on success or continue to the method body."
	<var: #primitiveRoutine declareC: 'void (*primitiveRoutine)(void)'>
	| flags jmp jmpSamplePrim retry continuePostSamplePrim jmpSampleNonPrim continuePostSampleNonPrim |
	<var: #jmp type: #'AbstractInstruction *'>
	<var: #retry type: #'AbstractInstruction *'>
	<var: #jmpSamplePrim type: #'AbstractInstruction *'>
	<var: #continuePostSamplePrim type: #'AbstractInstruction *'>
	<var: #jmpSampleNonPrim type: #'AbstractInstruction *'>
	<var: #continuePostSampleNonPrim type: #'AbstractInstruction *'>

	"Save processor fp, sp and return pc in the interpreter's frame stack and instruction pointers"
	self genExternalizePointersForPrimitiveCall.
	"Switch to the C stack."
	self genLoadCStackPointersForPrimCall.

	flags := coInterpreter primitivePropertyFlags: primitiveIndex.
	(flags anyMask: PrimCallDoNotJIT) ifTrue:
		[^ShouldNotJIT].

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
	retry := self MoveCq: 0 R: TempReg.
	self MoveR: TempReg Aw: coInterpreter primFailCodeAddress.
	methodOrBlockNumArgs ~= 0 ifTrue:
		[self MoveCq: methodOrBlockNumArgs R: TempReg].
	self MoveR: TempReg Aw: coInterpreter argumentCountAddress.

	"If required, set primitiveFunctionPointer and newMethod"
	(flags anyMask: PrimCallNeedsPrimitiveFunction) ifTrue:
		[self MoveCw: primitiveRoutine asInteger R: TempReg.
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
			 backEnd genSubstituteReturnAddress:
				((flags anyMask: PrimCallCollectsProfileSamples)
					ifTrue: [cePrimReturnEnterCogCodeProfiling]
					ifFalse: [cePrimReturnEnterCogCode]).
			 self JumpRT: primitiveRoutine asInteger.
			 primInvokeLabel := self Label.
			 jmp := jmpSamplePrim := continuePostSamplePrim := nil]
		ifFalse:
			["Call the C primitive routine."
			self CallRT: primitiveRoutine asInteger.
			primInvokeLabel := self Label.
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
			objectRepresentation maybeCompileRetry: retry onPrimitiveFail: primitiveIndex.
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
			self flag: 'currently caller pushes result'.
			self RetN: objectMemory wordSize].	"return to caller, popping receiver"

	(flags anyMask: PrimCallCollectsProfileSamples) ifTrue:
		["The sample is collected by cePrimReturnEnterCogCode for external calls"
		jmpSamplePrim notNil ifTrue:
			["Call ceCheckProfileTick: to record sample and then continue."
			jmpSamplePrim jmpTarget: self Label.
			self assert: (flags anyMask: PrimCallNeedsNewMethod).
			self CallRT: (self cCode: [#ceCheckProfileTick asUnsignedLong]
							   inSmalltalk: [self simulatedTrampolineFor: #ceCheckProfileTick]).
			"reenter the post-primitive call flow"
			self Jump: continuePostSamplePrim].
		"Null newMethod and call ceCheckProfileTick: to record sample and then continue.
		 ceCheckProfileTick will map null/0 to coInterpreter nilObject"
		jmpSampleNonPrim jmpTarget: self Label.
		self MoveCq: 0 R: TempReg.
		self MoveR: TempReg Aw: coInterpreter newMethodAddress.
		self CallRT: (self cCode: [#ceCheckProfileTick asUnsignedLong]
						   inSmalltalk: [self simulatedTrampolineFor: #ceCheckProfileTick]).
		"reenter the post-primitive call flow"
		self Jump: continuePostSampleNonPrim].

	jmp notNil ifTrue:
		["Jump to restore of receiver reg and proceed to frame build for failure."
		 jmp jmpTarget: self Label.
		 "Restore receiver reg from stack.  If on RISCs ret pc is in LinkReg, if on CISCs ret pc is on stack."
		 self MoveMw: objectMemory wordSize * (methodOrBlockNumArgs + (backEnd hasLinkRegister ifTrue: [0] ifFalse: [1]))
			r: SPReg
			R: ReceiverResultReg].
	^0
]

{ #category : #'in-line cacheing' }
SimpleStackBasedCogit >> compileOpenPIC: selector numArgs: numArgs [
	"Compile the code for an open PIC.  Perform a probe of the first-level method
	 lookup cache followed by a call of ceSendFromInLineCacheMiss: if the probe fails."
	| jumpSelectorMiss jumpClassMiss itsAHit jumpBCMethod |
	<var: #jumpSelectorMiss type: #'AbstractInstruction *'>
	<var: #jumpClassMiss type: #'AbstractInstruction *'>
	<var: #itsAHit type: #'AbstractInstruction *'>
	<var: #jumpBCMethod type: #'AbstractInstruction *'>
	self compilePICAbort: numArgs.
	self cppIf: NewspeakVM ifTrue:
		[self Nop. "1st nop differentiates dynSuperEntry from no-check entry if using nextMethod"
		 dynSuperEntry := self Nop].
	entry := objectRepresentation genGetClassTagOf: ReceiverResultReg into: ClassReg scratchReg: TempReg.

	"Do first of three probes.  See CoInterpreter>>lookupInMethodCacheSel:classTag:"
	self flag: #lookupInMethodCacheSel:classTag:. "so this method shows up as a sender of lookupInMethodCacheSel:class:"
	self MoveR: ClassReg R: SendNumArgsReg.
	self annotate: (self XorCw: selector R: ClassReg) objRef: selector.
	self LogicalShiftLeftCq: objectMemory shiftForWord R: ClassReg.
	self AndCq: MethodCacheMask << objectMemory shiftForWord R: ClassReg.
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheSelector << objectMemory shiftForWord)
		r: ClassReg
		R: TempReg.
	self annotate: (self CmpCw: selector R: TempReg) objRef: selector.
	jumpSelectorMiss := self JumpNonZero: 0.
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheClass << objectMemory shiftForWord)
		r: ClassReg
		R: TempReg.
	self CmpR: SendNumArgsReg R: TempReg.
	jumpClassMiss := self JumpNonZero: 0.

	itsAHit := self Label.
	"Fetch the method.  The interpret trampoline requires the bytecoded method in SendNumArgsReg"
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheMethod << objectMemory shiftForWord)
		r: ClassReg
		R: SendNumArgsReg.
	"If the method is compiled jump to its unchecked entry-point, otherwise interpret it."
	objectRepresentation
		genLoadSlot: HeaderIndex sourceReg: SendNumArgsReg destReg: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpBCMethod := objectRepresentation genJumpSmallIntegerInScratchReg: TempReg.
	jumpBCMethod jmpTarget: picInterpretAbort.
	self AddCq: cmNoCheckEntryOffset R: ClassReg.
	self JumpR: ClassReg.

	"First probe missed.  Do second of three probes.  Shift hash right one and retry."
	jumpSelectorMiss jmpTarget: (jumpClassMiss jmpTarget: self Label).
	self MoveR: SendNumArgsReg R: ClassReg.
	self annotate: (self XorCw: selector R: ClassReg) objRef: selector.
	self LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: ClassReg.
	self AndCq: MethodCacheMask << objectMemory shiftForWord R: ClassReg.
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheSelector << objectMemory shiftForWord)
		r: ClassReg
		R: TempReg.
	self annotate: (self CmpCw: selector R: TempReg) objRef: selector.
	jumpSelectorMiss := self JumpNonZero: 0.
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheClass << objectMemory shiftForWord)
		r: ClassReg
		R: TempReg.
	self CmpR: SendNumArgsReg R: TempReg.
	self JumpZero: itsAHit.

	"Second probe missed.  Do last probe.  Shift hash right two and retry."
	jumpSelectorMiss jmpTarget: self Label.
	self MoveR: SendNumArgsReg R: ClassReg.
	self annotate: (self XorCw: selector R: ClassReg) objRef: selector.
	objectMemory shiftForWord > 2 ifTrue:
		[self LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: ClassReg].
	self AndCq: MethodCacheMask << objectMemory shiftForWord R: ClassReg.
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheSelector << objectMemory shiftForWord)
		r: ClassReg
		R: TempReg.
	self annotate: (self CmpCw: selector R: TempReg) objRef: selector.
	jumpSelectorMiss := self JumpNonZero: 0.
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheClass << objectMemory shiftForWord)
		r: ClassReg
		R: TempReg.
	self CmpR: SendNumArgsReg R: TempReg.
	self JumpZero: itsAHit.

	"Last probe missed.  Call ceSendFromInLineCacheMiss: to do the full lookup."
	jumpSelectorMiss jmpTarget: self Label.
	backEnd genSaveStackPointers.
	backEnd genLoadCStackPointers.
	methodLabel addDependent: (self annotateAbsolutePCRef: (self MoveCw: methodLabel asInteger R: SendNumArgsReg)).
	self 
		compileCallFor: #ceSendFromInLineCacheMiss:
		numArgs: 1
		arg: SendNumArgsReg
		arg: nil
		arg: nil
		arg: nil
		resultReg: nil
		saveRegs: false
	"Note that this call does not return."
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
		[^self genSend: (self getLiteral: byte2) numArgs: (byte1 bitAnd: 31)].
	opType = 1 ifTrue:
		[^self genSendSuper: (self getLiteral: byte2) numArgs: (byte1 bitAnd: 31)].
	"We need a map entry for this bytecode for correct parsing.
	 The sends will get an IsSend entry anyway.  The other cases need a
	 fake one.  We could of course special case the scanning but that's silly."
	opType caseOf: {
			[2]	->	[(coInterpreter isReadMediatedContextInstVarIndex: byte2)
						ifTrue: [self genPushMaybeContextReceiverVariable: byte2]
						ifFalse: [self genPushReceiverVariable: byte2]].
			[3]	->	[self genPushLiteralIndex: byte2].
			[4]	->	[self genPushLiteralVariable: byte2].
			[7]	->	[self genStorePop: false LiteralVariable: byte2] }
		otherwise: "5 & 6"
			[(coInterpreter isWriteMediatedContextInstVarIndex: byte2)
				ifTrue: [self genStorePop: opType = 6 MaybeContextReceiverVariable: byte2]
				ifFalse: [self genStorePop: opType = 6 ReceiverVariable: byte2]].
	"We need a map entry for this bytecode for correct parsing (if the method builds a frame).
	 We could of course special case the scanning but that's silly."
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
		[^self genStorePop: true TemporaryVariable: variableIndex].
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
		[^self genStorePop: false TemporaryVariable: variableIndex].
	variableType = 3 ifTrue:
		[^self genStorePop: false LiteralVariable: variableIndex].
	^EncounteredUnknownBytecode
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> firstSpecialSelectorBytecodeOffset [
	<inline: true>
	^self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [bytecodeSetOffset = 256 ifTrue: [AltFirstSpecialSelector + 256] ifFalse: [FirstSpecialSelector]]
		ifFalse: [FirstSpecialSelector]
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> frameOffsetOfTemporary: index [
	^index < methodOrBlockNumArgs
		ifTrue: [FoxCallerSavedIP + ((methodOrBlockNumArgs - index) * objectMemory wordSize)]
		ifFalse: [FoxMFReceiver - objectMemory wordSize + ((methodOrBlockNumArgs - index) * objectMemory wordSize)]
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genBlockReturn [
	"Return from block, assuming result already loaded into ReceiverResultReg."
	needsFrame ifTrue:
		[self MoveR: FPReg R: SPReg.
		 self PopR: FPReg].
	"Tim, I disagree; link reg should only be popped if frameful.
	 Frameless methods should /not/ push the link reg except around trampolines.
	 Eliot"
	backEnd hasLinkRegister ifTrue:
		[self PopR: LinkReg].
	self RetN: methodOrBlockNumArgs + 1 * objectMemory wordSize.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genCallPrimitiveBytecode [
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution."
	"This makes sense only for the optimizing JITs"
	^EncounteredUnknownBytecode
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genDoubleArithmetic: arithmeticOperator preOpCheck: preOpCheckOrNil [
	"Stack looks like
		receiver (also in ResultReceiverReg)
		arg
		return address"
	<var: #preOpCheckOrNil declareC: 'AbstractInstruction *(*preOpCheckOrNil)(int rcvrReg, int argReg)'>
	| jumpFailClass jumpFailAlloc jumpFailCheck jumpImmediate jumpNonInt doOp fail |
	<var: #jumpFailClass type: #'AbstractInstruction *'>
	<var: #jumpFailAlloc type: #'AbstractInstruction *'>
	<var: #jumpNonInt type: #'AbstractInstruction *'>
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	<var: #jumpFailCheck type: #'AbstractInstruction *'>
	<var: #doOp type: #'AbstractInstruction *'>
	<var: #fail type: #'AbstractInstruction *'>
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	objectRepresentation genGetDoubleValueOf: ReceiverResultReg into: DPFPReg0.
	self MoveR: TempReg R: ClassReg.
	jumpImmediate := objectRepresentation genJumpImmediateInScratchReg: TempReg.
	objectRepresentation genGetCompactClassIndexNonImmOf: ClassReg into: SendNumArgsReg.
	objectRepresentation genCmpClassFloatCompactIndexR: SendNumArgsReg.
	jumpFailClass := self JumpNonZero: 0.
	objectRepresentation genGetDoubleValueOf: ClassReg into: DPFPReg1.
	doOp := self Label.
	preOpCheckOrNil ifNotNil:
		[jumpFailCheck := self perform: preOpCheckOrNil with: DPFPReg0 with: DPFPReg1].
	self gen: arithmeticOperator operand: DPFPReg1 operand: DPFPReg0.
	jumpFailAlloc := objectRepresentation
					genAllocFloatValue: DPFPReg0
					into: SendNumArgsReg
					scratchReg: ClassReg
					scratchReg: TempReg.
	self MoveR: SendNumArgsReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpImmediate jmpTarget: self Label.
	objectRepresentation smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg].
	objectRepresentation genConvertSmallIntegerToIntegerInReg: ClassReg.
	self ConvertR: ClassReg Rd: DPFPReg1.
	self Jump: doOp.
	jumpFailAlloc jmpTarget: self Label.
	self compileFallbackToInterpreterPrimitive.
	fail := self Label.
	jumpFailClass jmpTarget: fail.
	preOpCheckOrNil ifNotNil:
		[jumpFailCheck jmpTarget: fail].
	objectRepresentation smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt jmpTarget: fail].
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genDoubleComparison: jumpOpcodeGenerator invert: invertComparison [
	"Stack looks like
		receiver (also in ResultReceiverReg)
		arg
		return address"
	<var: #jumpOpcodeGenerator declareC: 'AbstractInstruction *(*jumpOpcodeGenerator)(void *)'>
	| jumpFail jumpImmediate jumpNonInt jumpCond compare |
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	<var: #jumpNonInt type: #'AbstractInstruction *'>
	<var: #jumpCond type: #'AbstractInstruction *'>
	<var: #compare type: #'AbstractInstruction *'>
	<var: #jumpFail type: #'AbstractInstruction *'>

	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	objectRepresentation genGetDoubleValueOf: ReceiverResultReg into: DPFPReg0.
	self MoveR: TempReg R: ClassReg.
	jumpImmediate := objectRepresentation genJumpImmediateInScratchReg: TempReg.
	objectRepresentation genGetCompactClassIndexNonImmOf: ClassReg into: SendNumArgsReg.
	objectRepresentation genCmpClassFloatCompactIndexR: SendNumArgsReg.
	jumpFail := self JumpNonZero: 0.
	objectRepresentation genGetDoubleValueOf: ClassReg into: DPFPReg1.
	invertComparison "May need to invert for NaNs"
		ifTrue: [compare := self CmpRd: DPFPReg0 Rd: DPFPReg1]
		ifFalse: [compare := self CmpRd: DPFPReg1 Rd: DPFPReg0].
	jumpCond := self perform: jumpOpcodeGenerator with: 0. "FP jumps are a little weird"
	self annotate: (self MoveCw: objectMemory falseObject R: ReceiverResultReg)
		objRef: objectMemory falseObject.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpCond jmpTarget: (self annotate: (self MoveCw: objectMemory trueObject R: ReceiverResultReg)
							objRef: objectMemory trueObject).
	self RetN: objectMemory wordSize * 2.
	jumpImmediate jmpTarget: self Label.
	objectRepresentation smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg].
	objectRepresentation genConvertSmallIntegerToIntegerInReg: ClassReg.
	self ConvertR: ClassReg Rd: DPFPReg1.
	self Jump: compare.
	jumpFail jmpTarget: self Label.
	objectRepresentation smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt jmpTarget: jumpFail getJmpTarget].
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genDoubleFailIfZeroArgRcvr: rcvrReg arg: argReg [
	<returnTypeC: #'AbstractInstruction *'>
	self MoveCq: 0 R: TempReg.
	self ConvertR: TempReg Rd: DPFPReg2.
	self CmpRd: DPFPReg2 Rd: argReg.
	^self JumpFPEqual: 0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genDynamicSuperSendBytecode [
	^self genSendDynamicSuper: (self getLiteral: byte2) numArgs: byte1
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
	target := distance + 2 + bytecodePC.
	^self genJumpIf: objectMemory trueObject to: target
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtNopBytecode [
	"NewspeakV4: 221		11011101		Nop"
	"SistaV1:		 91		01011011'		Nop"
	extA := extB := 0.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtPushCharacterBytecode [
	"SistaV1:		233		11101001	iiiiiiii		Push Character #iiiiiiii (+ Extend B * 256)"
	| value |
	value := byte1 + (extB << 8).
	extB := 0.
	^self genPushLiteral: (objectMemory characterObjectOf: value)
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtPushClosureBytecode [
	"Block compilation.  At this point in the method create the block.  Note its start
	 and defer generating code for it until after the method and any other preceeding
	 blocks.  The block's actual code will be compiled later."
	"253		11111101 eei i i kkk	jjjjjjjj		Push Closure Num Copied iii (+ Ext A // 16 * 8) Num Args kkk (+ Ext A \\ 16 * 8) BlockSize jjjjjjjj (+ Ext B * 256). ee = num extensions"
	| numArgs numCopied |
	self assert: needsFrame.
	self addBlockStartAt: bytecodePC + 3 "0 relative"
		numArgs: (numArgs := (byte1 bitAnd: 16r7) + (extA \\ 16 * 8))
		numCopied: (numCopied := ((byte1 >> 3) bitAnd: 7) + (extA // 16 * 8))
		span: byte2 + (extB << 8).
	extA := extB := 0.
	objectRepresentation
		genCreateClosureAt: bytecodePC + 4 "1 relative"
		numArgs: numArgs
		numCopied: numCopied
		contextNumArgs: methodOrBlockNumArgs
		large: (coInterpreter methodNeedsLargeContext: methodObj)
		inBlock: inBlock.
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
SimpleStackBasedCogit >> genExtSendAbsentDynamicSuperBytecode [
	"241		11110001	i i i i i j j j	Send To Absent Dynamic Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	| litIndex nArgs |
	litIndex := (byte1 >> 3) + (extA << 5).
	extA := 0.
	nArgs := (byte1 bitAnd: 7) + (extB << 3).
	extB := 0.
	^self genSendAbsentDynamicSuper: (self getLiteral: litIndex) numArgs: nArgs
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtSendAbsentImplicitBytecode [
	"240		11110000	i i i i i j j j	Send To Absent Implicit Receiver Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	| litIndex nArgs |
	litIndex := (byte1 >> 3) + (extA << 5).
	extA := 0.
	nArgs := (byte1 bitAnd: 7) + (extB << 3).
	extB := 0.
	^self genSendAbsentImplicit: (self getLiteral: litIndex) numArgs: nArgs
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtSendAbsentOuterBytecode [
	"254		 11111110	i i i i i j j j kkkkkkkk	Send To Absent Outer Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments at Depth kkkkkkkk "
	| litIndex nArgs depth |
	litIndex := (byte1 >> 3) + (extA << 5).
	extA := 0.
	nArgs := (byte1 bitAnd: 7) + (extB << 3).
	extB := 0.
	depth := byte2.
	^self genSendAbsentOuter: (self getLiteral: litIndex) numArgs: nArgs depth: depth

]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtSendAbsentSelfBytecode [
	"245		11110101	i i i i i j j j	Send To Absent Self Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	| litIndex nArgs |
	litIndex := (byte1 >> 3) + (extA << 5).
	extA := 0.
	nArgs := (byte1 bitAnd: 7) + (extB << 3).
	extB := 0.
	^self genSendAbsentSelf: (self getLiteral: litIndex) numArgs: nArgs
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtSendBytecode [
	"238		11101110	i i i i i j j j	Send Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	| litIndex nArgs |
	litIndex := (byte1 >> 3) + (extA << 5).
	extA := 0.
	nArgs := (byte1 bitAnd: 7) + (extB << 3).
	extB := 0.
	^self genSend: (self getLiteral: litIndex) numArgs: nArgs
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtSendSuperBytecode [
	"239		11101111	i i i i i j j j	Send To Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	| litIndex nArgs |
	litIndex := (byte1 >> 3) + (extA << 5).
	extA := 0.
	nArgs := (byte1 bitAnd: 7) + (extB << 3).
	extB := 0.
	^self genSendSuper: (self getLiteral: litIndex) numArgs: nArgs
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
SimpleStackBasedCogit >> genExtStoreLiteralVariableBytecode [
	"233		11101001	i i i i i i i i	Store Literal Variable #iiiiiiii (+ Extend A * 256)"
	| index |
	index := byte1 + (extA << 8).
	extA := 0.
	^self genStorePop: false LiteralVariable: index
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

	^self genSend: (self getLiteral: (byte1 bitAnd: 16r1F)) numArgs: byte1 >> 5
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genExtendedSuperBytecode [
	^self genSendSuper: (self getLiteral: (byte1 bitAnd: 16r1F)) numArgs: byte1 >> 5
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genFastPrimFail [
	primitiveIndex := 0.
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genFastPrimTraceUsing: r1 and: r2 [
	"Suport for compileInterpreterPrimitive.  Generate inline code so as to record the primitive
	 trace as fast as possible."
	self MoveCq: 0 R: TempReg.
	self MoveCq: 0 R: r2. "N.B. MoveMb:r:R: does not zero other bits"
	self MoveMb: coInterpreter primTraceLogIndexAddress r: TempReg R: r2.
	self MoveR: r2 R: r1.
	self AddCq: 1 R: r1.
	self MoveR: r1 Mb: coInterpreter primTraceLogIndexAddress r: TempReg.
	methodLabel addDependent:
		(self annotateAbsolutePCRef:
			(self MoveCw: methodLabel asInteger R: r1)).
	self MoveMw: (self offset: CogMethod of: #selector) r: r1 R: TempReg.
	self MoveCw: coInterpreter primTraceLogAddress asInteger R: r1.
	self MoveR: TempReg Xwr: r2 R: r1
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genGetImplicitReceiverFor: selector forPush: forPushSendBar [
	"Cached implicit receiver implementation.  If objectRepresentation doesn't support
	 pinning then caller looks like
				mov selector, ClassReg
				call ceImplicitReceiverTrampoline
				br continue
		Lclass	.word
		Lmixin:	.word
		continue:
	 If objectRepresentation supports pinning then caller looks like
				mov Lclass, Arg1Reg
				mov selector, SendNumArgsReg
				call ceImplicitReceiver
	 and Lclass: .word; Lmixin: .word is somewhere on the heap.

	 If class matches class of receiver then mixin contains either 0 or the implicit receiver.
	 If 0, answer the actual receiver.  This is done in the trampoline.
	 See generateNewspeakRuntime."

	| skip |
	<var: #skip type: #'AbstractInstruction *'>
	"N.B. For PC mapping either this is used for SendAbsentImplicit or for PushAbsentReceiver
	 but not both.  So any Newspeak instruction set has to choose either SendAbsentImplicit
	 or PushImplicitReceiver.  See isPCMappedAnnotation:alternateInstructionSet:"
	self assert: forPushSendBar = (self isPCMappedAnnotation: IsNSSendCall
										alternateInstructionSet: bytecodeSetOffset > 0).
	self assert: (self noAssertMethodClassAssociationOf: methodObj) ~= objectMemory nilObject.
	self assert: needsFrame.
	(objectMemory isYoung: selector) ifTrue:
		[hasYoungReferent := true].
	objectRepresentation canPinObjects ifTrue:
		[self MoveCw: theIRCs + (2 * objectMemory bytesPerOop * indexOfIRC) R: Arg1Reg.
		 self MoveCw: selector R: SendNumArgsReg.
		 self CallNewspeakSend: ceImplicitReceiverTrampoline.
		 indexOfIRC := indexOfIRC + 1.
		 ^0].
	self MoveCw: selector R: SendNumArgsReg.
	self CallNewspeakSend: ceImplicitReceiverTrampoline.
	skip := self Jump: 0.
	self Fill32: 0.
	self Fill32: 0.
	skip jmpTarget: self Label.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genJumpBackTo: targetBytecodePC [
	self MoveAw: coInterpreter stackLimitAddress R: TempReg.
	self CmpR: TempReg R: SPReg. "N.B. FLAGS := SPReg - TempReg"
	self JumpAboveOrEqual: (self fixupAt: targetBytecodePC - initialPC).
	self annotateBytecode: (self CallRT: ceCheckForInterruptTrampoline).
	self Jump: (self fixupAt: targetBytecodePC - initialPC).
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genJumpIf: boolean to: targetBytecodePC [
	<inline: false>
	"Cunning trick by LPD.  If true and false are contiguous subtract the smaller.
	 Correct result is either 0 or the distance between them.  If result is not 0 or
	 their distance send mustBeBoolean."
	| ok |
	<var: #ok type: #'AbstractInstruction *'>
	self assert: (objectMemory objectAfter: objectMemory falseObject) = objectMemory trueObject.
	self PopR: TempReg.
	self annotate: (self SubCw: boolean R: TempReg) objRef: boolean.
	self JumpZero: (self ensureFixupAt: targetBytecodePC - initialPC).
	self CmpCq: (boolean == objectMemory falseObject
					ifTrue: [objectMemory trueObject - objectMemory falseObject]
					ifFalse: [objectMemory falseObject - objectMemory trueObject])
		R: TempReg.
	ok := self JumpZero: 0.
	self CallRT: (boolean == objectMemory falseObject
					ifTrue: [ceSendMustBeBooleanAddFalseTrampoline]
					ifFalse: [ceSendMustBeBooleanAddTrueTrampoline]).
	ok jmpTarget: (self annotateBytecode: self Label).
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genJumpTo: targetBytecodePC [
	self Jump: (self ensureFixupAt: targetBytecodePC - initialPC).
	^0
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
	| distance targetpc |
	distance := self v3: (self generatorAt: byte0)
					Long: bytecodePC
					Branch: 0
					Distance: methodObj.
	self assert: distance < 0.
	targetpc := distance + 2 + bytecodePC.
	^self genJumpBackTo: targetpc
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

{ #category : #initialization }
SimpleStackBasedCogit >> genMustBeBooleanTrampolineFor: boolean called: trampolineName [
	<var: #trampolineName type: #'char *'>
	<inline: false>
	opcodeIndex := 0.
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
		saveRegs: false
		pushLinkReg: true
		resultReg: nil
		appendOpcodes: true
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPopStackBytecode [
	self AddCq: objectMemory wordSize R: SPReg.
	^0
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
	opcodeIndex := 0.

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
		resultReg: nil
		saveRegs: false.

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
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize.	"return to caller, popping receiver"

	profiling ifTrue:
		["Call ceCheckProfileTick: to record sample and then continue.  newMethod
		 should be up-to-date.  Need to save and restore the link reg around this call."
		 jmpSample jmpTarget: self Label.
		 backEnd hasLinkRegister ifTrue: [self PushR: LinkReg].
		 self CallRT: (self cCode: '(unsigned long)ceCheckProfileTick'
						inSmalltalk: [self simulatedTrampolineFor: #ceCheckProfileTick]).
		 backEnd hasLinkRegister ifTrue: [self PopR: LinkReg].
		 self Jump: continuePostSample]
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveAdd [
	"Stack looks like
		receiver (also in ResultReceiverReg)
		arg
		return address"
	| jumpNotSI jumpOvfl |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpOvfl type: #'AbstractInstruction *'>
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	objectRepresentation genRemoveSmallIntegerTagsInScratchReg: ClassReg.
	self MoveR: ReceiverResultReg R: TempReg.
	self AddR: ClassReg R: TempReg.
	jumpOvfl := self JumpOverflow: 0.
	self MoveR: TempReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpOvfl jmpTarget: (jumpNotSI jmpTarget: self Label).
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveAsCharacter [
	| na r |
	na := coInterpreter argumentCountOf: methodObj.
	na <= 1 ifTrue:
		[na = 1 ifTrue:
			[self MoveMw: objectMemory wordSize r: SPReg R: Arg0Reg].
		 (r := objectRepresentation
				genInnerPrimitiveAsCharacter: 0
				inReg: (na = 0 ifTrue: [ReceiverResultReg] ifFalse: [Arg0Reg])) < 0 ifTrue:
			[^r]].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveAsFloat [
	"Stack looks like
		receiver (also in ResultReceiverReg)
		return address"
	| jumpFailAlloc |
	<var: #jumpFailAlloc type: #'AbstractInstruction *'>
	self MoveR: ReceiverResultReg R: ClassReg.
	objectRepresentation genConvertSmallIntegerToIntegerInReg: ClassReg.
	self ConvertR: ClassReg Rd: DPFPReg0.
	jumpFailAlloc := objectRepresentation
					genAllocFloatValue: DPFPReg0
					into: SendNumArgsReg
					scratchReg: ClassReg
					scratchReg: TempReg.
	self MoveR: SendNumArgsReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize.
	jumpFailAlloc jmpTarget: self Label.
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveAt [
	| r |
	self MoveMw: objectMemory wordSize r: SPReg R: Arg0Reg.
	(r := objectRepresentation genInnerPrimitiveAt: objectMemory wordSize * 2) < 0 ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveAtPut [
	| r |
	self MoveMw: objectMemory wordSize * 2 r: SPReg R: Arg0Reg.
	self MoveMw: objectMemory wordSize r: SPReg R: Arg1Reg.
	((r := objectRepresentation genInnerPrimitiveAtPut: objectMemory wordSize * 3) < 0
	 and: [r ~= UnimplementedPrimitive]) ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveBitAnd [
	| jumpNotSI |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	"Whether the SmallInteger tags are zero or non-zero, anding them together will preserve them."
	self AndR: ClassReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpNotSI jmpTarget: self Label.
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveBitOr [
	| jumpNotSI |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	"Whether the SmallInteger tags are zero or non-zero, oring them together will preserve them."
	self OrR: ClassReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpNotSI jmpTarget: self Label.
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveBitShift [
	"Stack looks like
		receiver (also in ResultReceiverReg)
		arg
		return address

	rTemp := ArgOffset(SP)
	rClass := tTemp
	rTemp := rTemp & 1
	jz nonInt
	rClass >>= 1
	cmp 0,rClass
	jge neg
	cmp 31,rClass // numSmallIntegerBits, jge for sign
	jge tooBig
	rTemp := rReceiver
	rTemp <<= rClass
	rTemp >>= rClass (arithmetic)
	cmp rTemp,rReceiver
	jnz ovfl
	rReceiver := rReceiver - 1
	rReceiver := rReceiver <<= rClass
	rReceiver := rReceiver + 1
	ret
neg:
	rClass := 0 - rClass
	cmp 31,rClass
	jge inRange
	rClass := 31
inRange
	rReceiver := rReceiver >>= rClass.
	rReceiver := rReceiver | 1.
	ret
ovfl
tooBig
nonInt:
	fail"
	| jumpNotSI jumpOvfl jumpNegative jumpTooBig jumpInRange |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpOvfl type: #'AbstractInstruction *'>
	<var: #jumpNegative type: #'AbstractInstruction *'>
	<var: #jumpTooBig type: #'AbstractInstruction *'>
	<var: #jumpInRange type: #'AbstractInstruction *'>
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	objectRepresentation genConvertSmallIntegerToIntegerInReg: ClassReg.
	(self lastOpcode setsConditionCodesFor: JumpNegative) ifFalse:
		[self CmpCq: 0 R: ClassReg]. "N.B. FLAGS := ClassReg - 0"
	jumpNegative := self JumpNegative: 0.
	self CmpCq: objectRepresentation numSmallIntegerBits R: ClassReg. "N.B. FLAGS := ClassReg - 31"
	jumpTooBig := self JumpGreaterOrEqual: 0.
	self MoveR: ReceiverResultReg R: TempReg.
	self LogicalShiftLeftR: ClassReg R: TempReg.
	self ArithmeticShiftRightR: ClassReg R: TempReg.
	self CmpR: TempReg R: ReceiverResultReg. "N.B. FLAGS := RRReg - TempReg"
	jumpOvfl := self JumpNonZero: 0.
	objectRepresentation genRemoveSmallIntegerTagsInScratchReg: ReceiverResultReg.
	self LogicalShiftLeftR: ClassReg R: ReceiverResultReg.
	objectRepresentation genAddSmallIntegerTagsTo: ReceiverResultReg.
	self RetN: objectMemory wordSize * 2.
	jumpNegative jmpTarget: (self NegateR: ClassReg).
	self CmpCq: objectRepresentation numSmallIntegerBits R: ClassReg. "N.B. FLAGS := ClassReg - 31"
	jumpInRange := self JumpLessOrEqual: 0.
	self MoveCq: objectRepresentation numSmallIntegerBits R: ClassReg.
	jumpInRange jmpTarget: (self ArithmeticShiftRightR: ClassReg R: ReceiverResultReg).
	objectRepresentation genSetSmallIntegerTagsIn: ReceiverResultReg.
	self RetN: objectMemory wordSize * 2.
	jumpNotSI jmpTarget: (jumpTooBig jmpTarget: (jumpOvfl jmpTarget: self Label)).
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveBitXor [
	| jumpNotSI |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	"Clear one or the other tag so that xoring will preserve them."
	objectRepresentation genRemoveSmallIntegerTagsInScratchReg: ClassReg.
	self XorR: ClassReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpNotSI jmpTarget: self Label.
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveCharacterValue [
	| r |
	(r := objectRepresentation genInnerPrimitiveCharacterValue: objectMemory wordSize) < 0 ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveClass [
	"Stack looks like
		receiver (also in ReceiverResultReg)
		return address"
	(objectRepresentation
			genGetClassObjectOf: ReceiverResultReg
			into: ReceiverResultReg
			scratchReg: TempReg
			instRegIsReceiver: methodOrBlockNumArgs = 0) = BadRegisterSet ifTrue:
		[objectRepresentation
			genGetClassObjectOf: ReceiverResultReg
			into: ClassReg
			scratchReg: TempReg
			instRegIsReceiver: methodOrBlockNumArgs = 0.
		 self MoveR: ClassReg R: ReceiverResultReg].
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize.
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveClosureValue [
	"Check the argument count.  Fail if wrong.
	 Get the method from the outerContext and see if it is cogged.  If so, jump to the
	 block entry or the no-context-switch entry, as appropriate, and we're done.  If not,
	 invoke the interpreter primitive."
	| jumpFail jumpBCMethod primitiveRoutine result |
	<var: #jumpFail type: #'AbstractInstruction *'>
	<var: #jumpBCMethod type: #'AbstractInstruction *'>
	<var: #primitiveRoutine declareC: 'void (*primitiveRoutine)()'>
	objectRepresentation genLoadSlot: ClosureNumArgsIndex sourceReg: ReceiverResultReg destReg: TempReg.
	self CmpCq: (objectMemory integerObjectOf: methodOrBlockNumArgs) R: TempReg.
	jumpFail := self JumpNonZero: 0.
	objectRepresentation
		genLoadSlot: ClosureOuterContextIndex sourceReg: ReceiverResultReg destReg: ClassReg;
		genLoadSlot: MethodIndex sourceReg: ClassReg destReg: SendNumArgsReg;
		genLoadSlot: HeaderIndex sourceReg: SendNumArgsReg destReg: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpBCMethod := objectRepresentation genJumpSmallIntegerInScratchReg: TempReg.
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
	jumpBCMethod jmpTarget: self Label.
	(result := self compileInterpreterPrimitive: primitiveRoutine) < 0 ifTrue:
		[^result].
	jumpFail jmpTarget: self Label.
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveDiv [
	| jumpNotSI jumpZero jumpExact jumpSameSign convert |
	<var: #convert type: #'AbstractInstruction *'>
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpExact type: #'AbstractInstruction *'>
	<var: #jumpSameSign type: #'AbstractInstruction *'>
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	self MoveR: TempReg R: ClassReg.
	self MoveR: TempReg R: Arg1Reg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	"We must shift away the tags, not just subtract them, so that the
	 overflow case doesn't actually overflow the machine instruction."
	objectRepresentation genShiftAwaySmallIntegerTagsInScratchReg: ClassReg.
	(self lastOpcode setsConditionCodesFor: JumpZero) ifFalse:
		[self CmpCq: 0 R: ClassReg].
	jumpZero := self JumpZero: 0.
	self MoveR: ReceiverResultReg R: TempReg.
	objectRepresentation genShiftAwaySmallIntegerTagsInScratchReg: TempReg.
	self DivR: ClassReg R: TempReg Quo: TempReg Rem: ClassReg.
	"If remainder is zero we must check for overflow."
	self CmpCq: 0 R: ClassReg.
	jumpExact := self JumpZero: 0.
	"If arg and remainder signs are different we must round down."
	self XorR: ClassReg R: Arg1Reg.
	(self lastOpcode setsConditionCodesFor: JumpZero) ifFalse:
		[self CmpCq: 0 R: Arg1Reg].
	jumpSameSign := self JumpGreaterOrEqual: 0.
	self SubCq: 1 R: TempReg.
	jumpSameSign jmpTarget: (convert := self Label).
	objectRepresentation genConvertIntegerToSmallIntegerInReg: TempReg.
	self MoveR: TempReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	"test for overflow; the only case is SmallInteger minVal // -1"
	jumpExact jmpTarget:
		(self CmpCq: (1 << (objectRepresentation numSmallIntegerBits - 1)) R: TempReg).
	self JumpLess: convert.
	jumpZero jmpTarget: (jumpNotSI jmpTarget: self Label).
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveDivide [
	| jumpNotSI jumpZero jumpInexact jumpOverflow |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpInexact type: #'AbstractInstruction *'>
	<var: #jumpOverflow type: #'AbstractInstruction *'>
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	"We must shift away the tags, not just subtract them, so that the
	 overflow case doesn't actually overflow the machine instruction."
	objectRepresentation genShiftAwaySmallIntegerTagsInScratchReg: ClassReg.
	jumpZero := self JumpZero: 0.
	self MoveR: ReceiverResultReg R: TempReg.
	objectRepresentation genShiftAwaySmallIntegerTagsInScratchReg: TempReg.
	self DivR: ClassReg R: TempReg Quo: TempReg Rem: ClassReg.
	"If remainder is non-zero fail."
	self CmpCq: 0 R: ClassReg.
	jumpInexact := self JumpNonZero: 0.
	"test for overflow; the only case is SmallInteger minVal / -1"
	self CmpCq: (1 << (objectRepresentation numSmallIntegerBits - 1)) R: TempReg.
	jumpOverflow := self JumpGreaterOrEqual: 0.
	objectRepresentation genConvertIntegerToSmallIntegerInReg: TempReg.
	self MoveR: TempReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpOverflow jmpTarget: (jumpInexact jmpTarget: (jumpZero jmpTarget: (jumpNotSI jmpTarget: self Label))).
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveEqual [
	^self genSmallIntegerComparison: JumpZero orDoubleComparison: #JumpFPEqual: asSymbol
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveFloatAdd [
	^self genDoubleArithmetic: AddRdRd preOpCheck: nil
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveFloatDivide [
	^self genDoubleArithmetic: DivRdRd preOpCheck: #genDoubleFailIfZeroArgRcvr:arg:
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveFloatEqual [
	^self genDoubleComparison: #JumpFPEqual: invert: false
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveFloatGreaterOrEqual [
	^self genDoubleComparison: #JumpFPGreaterOrEqual: invert: false
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveFloatGreaterThan [
	^self genDoubleComparison: #JumpFPGreater: invert: false
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveFloatLessOrEqual [
	^self genDoubleComparison: #JumpFPGreaterOrEqual: invert: true
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveFloatLessThan [
	^self genDoubleComparison: #JumpFPGreater: invert: true
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveFloatMultiply [
	^self genDoubleArithmetic: MulRdRd preOpCheck: nil
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveFloatNotEqual [
	^self genDoubleComparison: #JumpFPNotEqual: invert: false
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveFloatSquareRoot [
	"Stack looks like
		receiver (also in ResultReceiverReg)
		return address"
	| jumpFailAlloc |
	<var: #jumpFailAlloc type: #'AbstractInstruction *'>
	objectRepresentation genGetDoubleValueOf: ReceiverResultReg into: DPFPReg0.
	self SqrtRd: DPFPReg0.
	jumpFailAlloc := objectRepresentation
					genAllocFloatValue: DPFPReg0
					into: SendNumArgsReg
					scratchReg: ClassReg
					scratchReg: TempReg.
	self MoveR: SendNumArgsReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize.
	jumpFailAlloc jmpTarget: self Label.
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveFloatSubtract [
	^self genDoubleArithmetic: SubRdRd preOpCheck: nil
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveGreaterOrEqual [
	^self genSmallIntegerComparison: JumpGreaterOrEqual orDoubleComparison: #JumpFPGreaterOrEqual: asSymbol
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveGreaterThan [
	^self genSmallIntegerComparison: JumpGreater orDoubleComparison: #JumpFPGreater: asSymbol
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveIdentical [
	"Stack looks like
		receiver (also in ResultReceiverReg)
		arg
		return address"
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	^objectRepresentation
		genInnerPrimitiveIdentical: objectMemory wordSize * 2
		orNotIf: false
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveIdentityHash [
	| r |
	(r := objectRepresentation genInnerPrimitiveIdentityHash: objectMemory wordSize) < 0 ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveLessOrEqual [
	^self genSmallIntegerComparison: JumpLessOrEqual orDoubleComparison: #JumpFPLessOrEqual: asSymbol
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveLessThan [
	^self genSmallIntegerComparison: JumpLess orDoubleComparison: #JumpFPLess: asSymbol
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveMod [
	| jumpNotSI jumpZero jumpExact jumpSameSign |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpExact type: #'AbstractInstruction *'>
	<var: #jumpSameSign type: #'AbstractInstruction *'>
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	objectRepresentation genRemoveSmallIntegerTagsInScratchReg: ClassReg.
	jumpZero := self JumpZero: 0.
	self MoveR: ClassReg R: Arg1Reg.
	self MoveR: ReceiverResultReg R: TempReg.
	objectRepresentation genRemoveSmallIntegerTagsInScratchReg: TempReg.
	self DivR: ClassReg R: TempReg Quo: TempReg Rem: ClassReg.
	"If remainder is zero we're done."
	self CmpCq: 0 R: ClassReg.
	jumpExact := self JumpZero: 0.
	"If arg and remainder signs are different we must reflect around zero."
	self XorR: ClassReg R: Arg1Reg.
	(self lastOpcode setsConditionCodesFor: JumpZero) ifFalse:
		[self CmpCq: 0 R: Arg1Reg].
	jumpSameSign := self JumpGreaterOrEqual: 0.
	self XorR: ClassReg R: Arg1Reg.
	self AddR: Arg1Reg R: ClassReg.
	jumpSameSign jmpTarget: (jumpExact jmpTarget: self Label).
	objectRepresentation genSetSmallIntegerTagsIn: ClassReg.
	self MoveR: ClassReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpZero jmpTarget: (jumpNotSI jmpTarget: self Label).
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveMultiply [
	| jumpNotSI jumpOvfl |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpOvfl type: #'AbstractInstruction *'>
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	objectRepresentation genShiftAwaySmallIntegerTagsInScratchReg: ClassReg.
	self MoveR: ReceiverResultReg R: TempReg.
	objectRepresentation genRemoveSmallIntegerTagsInScratchReg: TempReg.
	self MulR: TempReg R: ClassReg.
	jumpOvfl := self JumpOverflow: 0.
	objectRepresentation genSetSmallIntegerTagsIn: ClassReg.
	self MoveR: ClassReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpOvfl jmpTarget: (jumpNotSI jmpTarget: self Label).
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveNew [
	| r |
	((r := objectRepresentation genInnerPrimitiveNew: objectMemory wordSize) < 0
	 and: [r ~= UnimplementedPrimitive]) ifTrue:
		[^r].
	"Call the interpreter primitive either when the machine-code primitive
	 fails, or if the machine-code primitive is unimplemented."
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveNewMethod [
	| r |
	((r := objectRepresentation genInnerPrimitiveNewMethod: 2 * objectMemory wordSize) < 0
	 and: [r ~= UnimplementedPrimitive]) ifTrue:
		[^r].
	"Call the interpreter primitive either when the machine-code primitive
	 fails, or if the machine-code primitive is unimplemented."
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveNewWithArg [
	| r |
	((r := objectRepresentation genInnerPrimitiveNewWithArg: objectMemory wordSize) < 0
	 and: [r ~= UnimplementedPrimitive]) ifTrue:
		[^r].
	"Call the interpreter primitive either when the machine-code primitive
	 fails, or if the machine-code primitive is unimplemented."
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveNotEqual [
	^self genSmallIntegerComparison: JumpNonZero orDoubleComparison: #JumpFPNotEqual: asSymbol
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveNotIdentical [
	"Stack looks like
		receiver (also in ResultReceiverReg)
		arg
		return address"
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	^objectRepresentation
		genInnerPrimitiveIdentical: objectMemory wordSize * 2
		orNotIf: true
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveQuo [
	| jumpNotSI jumpZero jumpOverflow |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpOverflow type: #'AbstractInstruction *'>
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	"We must shift away the tags, not just subtract them, so that the
	 overflow case doesn't actually overflow the machine instruction."
	objectRepresentation genShiftAwaySmallIntegerTagsInScratchReg: ClassReg.
	(self lastOpcode setsConditionCodesFor: JumpZero) ifFalse:
		[self CmpCq: 0 R: ClassReg].
	jumpZero := self JumpZero: 0.
	self MoveR: ReceiverResultReg R: TempReg.
	objectRepresentation genShiftAwaySmallIntegerTagsInScratchReg: TempReg.
	self DivR: ClassReg R: TempReg Quo: TempReg Rem: ClassReg.
	"test for overflow; the only case is SmallInteger minVal quo: -1"
	self CmpCq: (1 << (objectRepresentation numSmallIntegerBits - 1)) R: TempReg.
	jumpOverflow := self JumpGreaterOrEqual: 0.
	objectRepresentation genConvertIntegerToSmallIntegerInReg: TempReg.
	self MoveR: TempReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpOverflow jmpTarget: (jumpZero jmpTarget: (jumpNotSI jmpTarget: self Label)).
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveSize [
	| r |
	(r := objectRepresentation genInnerPrimitiveSize: objectMemory wordSize) < 0 ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveStringAt [
	| r |
	self MoveMw: objectMemory wordSize r: SPReg R: Arg0Reg.
	(r := objectRepresentation genInnerPrimitiveStringAt: objectMemory wordSize * 2) < 0 ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveStringAtPut [
	| r |
	self MoveMw: objectMemory wordSize * 2 r: SPReg R: Arg0Reg.
	self MoveMw: objectMemory wordSize r: SPReg R: Arg1Reg.
	((r := objectRepresentation genInnerPrimitiveStringAtPut: objectMemory wordSize * 3) < 0
	 and: [r ~= UnimplementedPrimitive]) ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genPrimitiveSubtract [
	"Stack looks like
		receiver (also in ResultReceiverReg)
		arg
		return address"
	| jumpNotSI jumpOvfl |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpOvfl type: #'AbstractInstruction *'>
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	self MoveR: ReceiverResultReg R: TempReg.
	self SubR: ClassReg R: TempReg.
	jumpOvfl := self JumpOverflow: 0.
	objectRepresentation genAddSmallIntegerTagsTo: TempReg.
	self MoveR: TempReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpOvfl jmpTarget: (jumpNotSI jmpTarget: self Label).
	^0
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
	 and defer generating code for it until after the method and any other preceeding
	 blocks.  The block's actual code will be compiled later."
	"143   10001111 llllkkkk jjjjjjjj iiiiiiii	Push Closure Num Copied llll Num Args kkkk BlockSize jjjjjjjjiiiiiiii"
	| numArgs numCopied |
	self assert: needsFrame.
	self addBlockStartAt: bytecodePC + 4 "0 relative"
		numArgs: (numArgs := byte1 bitAnd: 16rF)
		numCopied: (numCopied := byte1 >> 4)
		span: (byte2 << 8) + byte3.
	objectRepresentation
		genCreateClosureAt: bytecodePC + 5 "1 relative"
		numArgs: numArgs
		numCopied: numCopied
		contextNumArgs: methodOrBlockNumArgs
		large: (coInterpreter methodNeedsLargeContext: methodObj)
		inBlock: inBlock.
	self PushR: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushClosureTempsBytecode [
	"SistaV1: 230		11100110	iiiiiiii		PushNClosureTemps iiiiiiii"
	1 to: byte1 do:
		[:i| self genPushLiteral: objectMemory nilObject].
	^0
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

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushEnclosingObjectAt: level [
	"Uncached push enclosing object"
	self MoveCq: level R: SendNumArgsReg.
	self CallRT: ceEnclosingObjectTrampoline.
	self PushR: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushEnclosingObjectBytecode [
	"Uncached push enclosing object"
	| levelOop |
	levelOop := self getLiteral: byte1.
	self assert: (objectMemory isIntegerObject: levelOop).
	^self genPushEnclosingObjectAt: (objectMemory integerValueOf: levelOop)
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushImplicitReceiverBytecode [
	| result |
	result := self genGetImplicitReceiverFor: (self getLiteral: byte1) forPush: true.
	result ~= 0 ifTrue:
		[^result].
	self PushR: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushLiteral: literal [
	self annotate: (self PushCw: literal) objRef: literal.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushLiteralConstantBytecode [
	^self genPushLiteralIndex: (byte0 bitAnd: 31)
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushLiteralIndex: literalIndex [ "<SmallInteger>"
	<inline: false>
	| literal |
	literal := self getLiteral: literalIndex.
	^self genPushLiteral: literal
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushLiteralVariable16CasesBytecode [
	"16-31		0001 i i i i		Push Literal Variable #iiii"
	^self genPushLiteralVariable: (byte0 bitAnd: 15)
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushLiteralVariable: literalIndex [
	<inline: false>
	| association |
	association := self getLiteral: literalIndex.
	"N.B. Do _not_ use ReceiverResultReg to avoid overwriting receiver in assignment in frameless methods."
	self annotate: (self MoveCw: association R: ClassReg) objRef: association.
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

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushMaybeContextReceiverVariable: slotIndex [ 
	<inline: false>
	| jmpSingle jmpDone |
	<var: #jmpSingle type: #'AbstractInstruction *'>
	<var: #jmpDone type: #'AbstractInstruction *'>
	self assert: needsFrame.
	"See CoInterpreter>>contextInstructionPointer:frame: for an explanation
	 of the instruction pointer slot handling."
	slotIndex = InstructionPointerIndex ifTrue:
		[self MoveMw: FoxMFReceiver r: FPReg R: ReceiverResultReg.
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

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushReceiverVariable: index [
	<inline: false>
	| maybeErr |
	needsFrame ifTrue:
		[self MoveMw: FoxMFReceiver r: FPReg R: ReceiverResultReg].
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

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genPushRemoteTempLongBytecode [
	self MoveMw: (self frameOffsetOfTemporary: byte2) r: FPReg R: ClassReg.
	objectRepresentation
		genLoadSlot: byte1
		sourceReg: ClassReg
		destReg: TempReg.
	self PushR: TempReg.
	^0
]

{ #category : #'bytecode generators' }
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
	self annotate:
			(self gen: ((objectRepresentation isImmediate: constant)
						ifTrue: [MoveCqR]
						ifFalse: [MoveCwR])
				operand: constant
				operand: ReceiverResultReg)
		objRef: constant.
	^self genUpArrowReturn
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genQuickReturnInstVar [
	<api> "because selected by CoInterpreter>>quickPrimitiveGeneratorFor:"
	| index |
	index := coInterpreter quickPrimitiveInstVarIndexFor: primitiveIndex.
	objectRepresentation genLoadSlot: index sourceReg: ReceiverResultReg destReg: ReceiverResultReg.
	^self genUpArrowReturn
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genQuickReturnSelf [
	<api> "because selected by CoInterpreter>>quickPrimitiveGeneratorFor:"
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnFalse [
	self annotate: (self MoveCw: objectMemory falseObject R: ReceiverResultReg)
		objRef: objectMemory falseObject.
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnNil [
	self annotate: (self MoveCw: objectMemory nilObject R: ReceiverResultReg)
		objRef: objectMemory nilObject.
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnNilFromBlock [
	self assert: inBlock.
	self flag: 'currently caller pushes result'.
	self annotate: (self MoveCw: objectMemory nilObject R: ReceiverResultReg)
		objRef: objectMemory nilObject.
	^self genBlockReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnReceiver [
	"Frameless method activation looks like
				receiver
				args
		sp->	ret pc.
	 Return pops receiver and arguments off the stack.  Callee pushes the result."
	self flag: 'currently caller pushes result'.
	needsFrame ifTrue:
		[self MoveMw: FoxMFReceiver r: FPReg R: ReceiverResultReg].
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnTopFromBlock [
	self assert: inBlock.
	self flag: 'currently caller pushes result'.
	self PopR: ReceiverResultReg.
	^self genBlockReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnTopFromMethod [
	"Return pops receiver and arguments off the stack.  Callee pushes the result."
	self flag: 'currently caller pushes result'.
	self PopR: ReceiverResultReg.
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genReturnTrue [
	self annotate: (self MoveCw: objectMemory trueObject R: ReceiverResultReg)
		objRef: objectMemory trueObject.
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSecondExtendedSendBytecode [
	"Can use any of the first 64 literals for the selector and pass up to 3 arguments."

	^self genSend: (self getLiteral: (byte1 bitAnd: 16r3F)) numArgs: byte1 >> 6
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSend: selector numArgs: numArgs [
	<inline: false>
	(objectMemory isYoung: selector) ifTrue:
		[hasYoungReferent := true].
	self assert: needsFrame.
	self assert: (numArgs between: 0 and: 256). "say"
	self assert: (objectMemory addressCouldBeOop: selector).
	self MoveMw: numArgs * objectMemory wordSize r: SPReg R: ReceiverResultReg.
	numArgs > 2 ifTrue:
		[self MoveCq: numArgs R: SendNumArgsReg].
	self MoveCw: selector R: ClassReg.
	self CallSend: (sendTrampolines at: (numArgs min: NumSendTrampolines - 1)).
	self flag: 'currently caller pushes result'.
	self PushR: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSendAbsentDynamicSuper: selector numArgs: numArgs [
	"Shuffle arguments if necessary and push receiver.
	 Then send."
	<inline: false>
	self marshallAbsentReceiverSendArguments: numArgs.
	^self genSendDynamicSuper: selector numArgs: numArgs
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSendAbsentImplicit0ArgsBytecode [
	"160-175	1010 i i i i		Send To Absent Implicit Receiver Literal Selector #iiii With 0 Arguments."
	^self genSendAbsentImplicit: (self getLiteral: (byte0 bitAnd: 15)) numArgs: 0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSendAbsentImplicit: selector numArgs: numArgs [
	"Get the implicit receiver and shuffle arguments if necessary.
	 Then send."
	<inline: false>
	| result |
	result := self genGetImplicitReceiverFor: selector forPush: false.
	result ~= 0 ifTrue:
		[^result].
	self marshallAbsentReceiverSendArguments: numArgs.
	^self genSend: selector numArgs: numArgs
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSendAbsentOuter: selector numArgs: numArgs depth: depth [
	"Shuffle arguments if necessary and push receiver.
	 Then send."
	<inline: false>
	self genPushEnclosingObjectAt: depth.
	self PopR: ReceiverResultReg.
	self marshallAbsentReceiverSendArguments: numArgs.
	^self genSend: selector numArgs: numArgs
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSendAbsentSelf: selector numArgs: numArgs [
	"Shuffle arguments if necessary and push receiver.
	 Then send."
	<inline: false>
	self marshallAbsentReceiverSendArguments: numArgs.
	^self genSend: selector numArgs: numArgs
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSendDynamicSuper: selector numArgs: numArgs [
	(objectMemory isYoung: selector) ifTrue:
		[hasYoungReferent := true].
	self assert: needsFrame.
	self MoveMw: numArgs * objectMemory wordSize r: SPReg R: ReceiverResultReg.
	numArgs > 2 ifTrue:
		[self MoveCq: numArgs R: SendNumArgsReg].
	self MoveCw: selector R: ClassReg.
	self CallSend: (dynamicSuperSendTrampolines at: (numArgs min: NumSendTrampolines - 1)).
	self flag: 'currently caller pushes result'.
	self PushR: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSendLiteralSelector0ArgsBytecode [
	^self genSend: (self getLiteral: (byte0 bitAnd: 15)) numArgs: 0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSendLiteralSelector1ArgBytecode [
	^self genSend: (self getLiteral: (byte0 bitAnd: 15)) numArgs: 1
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSendLiteralSelector2ArgsBytecode [
	^self genSend: (self getLiteral: (byte0 bitAnd: 15)) numArgs: 2
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSendSuper: selector numArgs: numArgs [
	<inline: false>
	self assert: needsFrame.
	self assert: (numArgs between: 0 and: 256). "say"
	self assert: (objectMemory addressCouldBeOop: selector).
	(objectMemory isYoung: selector) ifTrue:
		[hasYoungReferent := true].
	self MoveMw: numArgs * objectMemory wordSize r: SPReg R: ReceiverResultReg.
	numArgs > 2 ifTrue:
		[self MoveCq: numArgs R: SendNumArgsReg].
	self MoveCw: selector R: ClassReg.
	self CallSend: (superSendTrampolines at: (numArgs min: NumSendTrampolines - 1)).
	self flag: 'currently caller pushes result'.
	self PushR: ReceiverResultReg.
	^0
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

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genSmallIntegerComparison: jumpOpcode [
	"Stack looks like
		receiver (also in ResultReceiverReg)
		arg
		return address"
	| jumpFail jumpTrue |
	<var: #jumpFail type: #'AbstractInstruction *'>
	<var: #jumpTrue type: #'AbstractInstruction *'>
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpFail := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	self CmpR: ClassReg R: ReceiverResultReg. "N.B. FLAGS := RRReg - ClassReg"
	jumpTrue := self gen: jumpOpcode.
	self annotate: (self MoveCw: objectMemory falseObject R: ReceiverResultReg)
		objRef: objectMemory falseObject.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpTrue jmpTarget: (self annotate: (self MoveCw: objectMemory trueObject R: ReceiverResultReg)
						objRef: objectMemory trueObject).
	self RetN: objectMemory wordSize * 2.
	jumpFail jmpTarget: self Label.
	^0
]

{ #category : #'primitive generators' }
SimpleStackBasedCogit >> genSmallIntegerComparison: jumpOpcode orDoubleComparison: jumpFPOpcodeGenerator [
	"Stack looks like
		receiver (also in ResultReceiverReg)
		arg
		return address"
	| jumpDouble jumpNonInt jumpFail jumpTrue jumpCond |
	<var: #jumpFPOpcodeGenerator declareC: 'AbstractInstruction *(*jumpFPOpcodeGenerator)(void *)'>
	<var: #jumpDouble type: #'AbstractInstruction *'>
	<var: #jumpNonInt type: #'AbstractInstruction *'>
	<var: #jumpCond type: #'AbstractInstruction *'>
	<var: #jumpTrue type: #'AbstractInstruction *'>
	<var: #jumpFail type: #'AbstractInstruction *'>
	backEnd hasDoublePrecisionFloatingPointSupport ifFalse:
		[^self genSmallIntegerComparison: jumpOpcode].
	self MoveMw: objectMemory wordSize r: SPReg R: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpDouble := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	self CmpR: ClassReg R: ReceiverResultReg. "N.B. FLAGS := RRReg - ClassReg"
	jumpTrue := self gen: jumpOpcode.
	self annotate: (self MoveCw: objectMemory falseObject R: ReceiverResultReg)
		objRef: objectMemory falseObject.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpTrue jmpTarget: (self annotate: (self MoveCw: objectMemory trueObject R: ReceiverResultReg)
						objRef: objectMemory trueObject).
	self RetN: objectMemory wordSize * 2.
	
	"Argument may be a Float : let us check or fail"
	jumpDouble jmpTarget: self Label.
	objectRepresentation smallIntegerIsOnlyImmediateType ifFalse:
		[self MoveR: ClassReg R: TempReg.
		 jumpNonInt := objectRepresentation genJumpImmediateInScratchReg: TempReg].
	objectRepresentation genGetCompactClassIndexNonImmOf: ClassReg into: SendNumArgsReg.
	objectRepresentation genCmpClassFloatCompactIndexR: SendNumArgsReg.
	jumpFail := self JumpNonZero: 0.

	"It was a Float, so convert the receiver to double and perform the operation"
	self MoveR: ReceiverResultReg R: TempReg.
	objectRepresentation genConvertSmallIntegerToIntegerInReg: TempReg.
	self ConvertR: TempReg Rd: DPFPReg0.
	objectRepresentation genGetDoubleValueOf: ClassReg into: DPFPReg1.
	self CmpRd: DPFPReg1 Rd: DPFPReg0.
	jumpCond := self perform: jumpFPOpcodeGenerator with: 0. "FP jumps are a little weird"
	self annotate: (self MoveCw: objectMemory falseObject R: ReceiverResultReg)
		objRef: objectMemory falseObject.
	self flag: 'currently caller pushes result'.
	self RetN: objectMemory wordSize * 2.
	jumpCond jmpTarget: (self annotate: (self MoveCw: objectMemory trueObject R: ReceiverResultReg)
							objRef: objectMemory trueObject).
	self RetN: objectMemory wordSize * 2.

	objectRepresentation smallIntegerIsOnlyImmediateType
		ifTrue: [jumpFail jmpTarget: self Label]
		ifFalse: [jumpNonInt jmpTarget: (jumpFail jmpTarget: self Label)].
	^0
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
	| jumpNotEqual jumpPush |
	<var: #jumpNotEqual type: #'AbstractInstruction *'>
	<var: #jumpPush type: #'AbstractInstruction *'>
	self PopR: Arg0Reg.
	objectRepresentation
		genEnsureObjInRegNotForwarded: Arg0Reg
		scratchReg: TempReg.
	self MoveMw: 0 r: SPReg R: ClassReg.
	objectRepresentation
		genEnsureObjInRegNotForwarded: ClassReg
		scratchReg: TempReg.
	self CmpR: Arg0Reg R: ClassReg.
	jumpNotEqual := self JumpNonZero: 0.
	self annotate: (self MoveCw: objectMemory trueObject R: Arg0Reg)
		objRef: objectMemory trueObject.
	jumpPush := self Jump: 0.
	jumpNotEqual jmpTarget: (self annotate: (self MoveCw: objectMemory falseObject R: Arg0Reg)
							objRef: objectMemory falseObject).
	jumpPush jmpTarget: (self MoveR: Arg0Reg Mw: 0 r: SPReg).
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genSpecialSelectorSend [
	| index selector numArgs |
	index := byte0 - self firstSpecialSelectorBytecodeOffset.
	selector := coInterpreter specialSelector: index.
	numArgs := coInterpreter specialSelectorNumArgs: index.
	^self genSend: selector numArgs: numArgs
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

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genStorePop: popBoolean LiteralVariable: litVarIndex [
	<inline: false>
	| association |
	self assert: needsFrame.
	association := self getLiteral: litVarIndex.
	self annotate: (self MoveCw: association R: ReceiverResultReg) objRef: association.
	objectRepresentation
		genEnsureObjInRegNotForwarded: ReceiverResultReg
		scratchReg: TempReg.
	popBoolean
		ifTrue: [self PopR: ClassReg]
		ifFalse: [self MoveMw: 0 r: SPReg R: ClassReg].
	traceStores > 0 ifTrue:
		[self CallRT: ceTraceStoreTrampoline].
	^objectRepresentation
		genStoreSourceReg: ClassReg
		slotIndex: ValueIndex
		destReg: ReceiverResultReg
		scratchReg: TempReg
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genStorePop: popBoolean MaybeContextReceiverVariable: slotIndex [
	<inline: false>
	| jmpSingle jmpDone |
	<var: #jmpSingle type: #'AbstractInstruction *'>
	<var: #jmpDone type: #'AbstractInstruction *'>
	self assert: needsFrame.
	self MoveMw: FoxMFReceiver r: FPReg R: ReceiverResultReg.
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
	traceStores > 0 ifTrue:
		[self CallRT: ceTraceStoreTrampoline].
	objectRepresentation
		genStoreSourceReg: ClassReg
		slotIndex: slotIndex
		destReg: ReceiverResultReg
		scratchReg: TempReg.
	jmpDone jmpTarget: self Label.
	popBoolean ifTrue:
		[self AddCq: objectMemory wordSize R: SPReg].
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genStorePop: popBoolean ReceiverVariable: slotIndex [
	<inline: false>
	needsFrame ifTrue:
		[self MoveMw: FoxMFReceiver r: FPReg R: ReceiverResultReg].
	popBoolean
		ifTrue: [self PopR: ClassReg]
		ifFalse: [self MoveMw: 0 r: SPReg R: ClassReg].
	traceStores > 0 ifTrue:
		[self CallRT: ceTraceStoreTrampoline].
	^objectRepresentation
		genStoreSourceReg: ClassReg
		slotIndex: slotIndex
		destReg: ReceiverResultReg
		scratchReg: TempReg
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genStorePop: popBoolean RemoteTemp: slotIndex At: remoteTempIndex [
	<inline: false>
	self assert: needsFrame.
	popBoolean
		ifTrue: [self PopR: ClassReg]
		ifFalse: [self MoveMw: 0 r: SPReg R: ClassReg].
	self MoveMw: (self frameOffsetOfTemporary: remoteTempIndex) r: FPReg R: ReceiverResultReg.
	traceStores > 0 ifTrue:
		[self CallRT: ceTraceStoreTrampoline].
	^objectRepresentation
		genStoreSourceReg: ClassReg
		slotIndex: slotIndex
		destReg: ReceiverResultReg
		scratchReg: TempReg
]

{ #category : #'bytecode generators' }
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

{ #category : #initialization }
SimpleStackBasedCogit >> genTraceStoreTrampoline [
	ceTraceStoreTrampoline := self genSafeTrampolineFor: #ceTraceStoreOf:into:
										called: 'ceTraceStoreTrampoline'
										arg: ClassReg
										arg: ReceiverResultReg
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genUnconditionnalTrapBytecode [
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
	self flag: 'currently caller pushes result'.
	inBlock ifTrue:
		[self assert: needsFrame.
		 self annotateBytecode: (self CallRT: ceNonLocalReturnTrampoline).
		 ^0].
	needsFrame ifTrue:
		[self MoveR: FPReg R: SPReg.
		 self PopR: FPReg.
		 backEnd hasLinkRegister ifTrue:
			[self PopR: LinkReg]].
	self RetN: methodOrBlockNumArgs + 1 * objectMemory wordSize.
	^0
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> genV4SpecialSelectorSend [
	| index selector numArgs |
	index := byte0 - 80.
	selector := coInterpreter specialSelector: index.
	numArgs := coInterpreter specialSelectorNumArgs: index.
	^self genSend: selector numArgs: numArgs
]

{ #category : #initialization }
SimpleStackBasedCogit >> generateMissAbortTrampolines [
	"Generate the run-time entries for the various method and PIC entry misses and aborts..
	 Read the class-side method trampolines for documentation on the various trampolines"

	ceMethodAbortTrampoline := self genMethodAbortTrampoline.
	cePICAbortTrampoline := self genPICAbortTrampoline.
	ceCPICMissTrampoline := self genTrampolineFor: #ceCPICMiss:receiver:
								called: 'ceCPICMissTrampoline'
								arg: ClassReg
								arg: ReceiverResultReg
]

{ #category : #initialization }
SimpleStackBasedCogit >> generateTracingTrampolines [
	"Generate trampolines for tracing.  In the simulator we can save a lot of time
	 and avoid noise instructions in the lastNInstructions log by short-cutting these
	 trampolines, but we need them in the real vm."
	ceTraceLinkedSendTrampoline :=
		self genSafeTrampolineFor: #ceTraceLinkedSend:
			called: 'ceTraceLinkedSendTrampoline'
			arg: ReceiverResultReg.
	ceTraceBlockActivationTrampoline :=
		self genTrampolineFor: #ceTraceBlockActivation
			called: 'ceTraceBlockActivationTrampoline'.
	ceTraceStoreTrampoline :=
		self genSafeTrampolineFor: #ceTraceStoreOf:into:
			called: 'ceTraceStoreTrampoline'
			arg: ClassReg
			arg: ReceiverResultReg.
	self cCode: [] inSmalltalk:
		[ceTraceLinkedSendTrampoline := self simulatedTrampolineFor: #ceShortCutTraceLinkedSend:.
		 ceTraceBlockActivationTrampoline := self simulatedTrampolineFor: #ceShortCutTraceBlockActivation:.
		 ceTraceStoreTrampoline := self simulatedTrampolineFor: #ceShortCutTraceStore:]
]

{ #category : #'bytecode generators' }
SimpleStackBasedCogit >> marshallAbsentReceiverSendArguments: numArgs [
	"Shuffle arguments if necessary and push receiver."
	numArgs = 0
		ifTrue:
			[self PushR: ReceiverResultReg]
		ifFalse:
			[self MoveMw: 0 r: SPReg R: TempReg.
			self PushR: TempReg.
			2 to: numArgs do:
				[:index|
				self MoveMw: index * BytesPerWord r: SPReg R: TempReg.
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

{ #category : #testing }
SimpleStackBasedCogit >> numRegArgs [
	<api>
	^0
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

{ #category : #trampolines }
SimpleStackBasedCogit >> picAbortTrampolineFor: numArgs [
	^cePICAbortTrampoline
]

{ #category : #'external primitive support' }
SimpleStackBasedCogit >> recordCallOffsetIn: cogMethod of: callLabelArg [
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	<var: #callLabelArg type: #'void *'>
	| callLabel offset offsetTable |
	<var: #callLabel type: #'AbstractInstruction *'>
	<var: #offsetTable type: #'sqInt *'>
	callLabel := callLabelArg. "this function is exported but AbstractInstruction isn't; hence pun through void *"
	offsetTable := (backEnd isCallPreceedingReturnPC: callLabel address asUnsignedInteger)
						ifTrue: [externalPrimCallOffsets]
						ifFalse: [externalPrimJumpOffsets].
	offset := callLabel address - cogMethod asInteger.
	(offsetTable at: cogMethod cmNumArgs) isNil
		ifTrue: [offsetTable at: cogMethod cmNumArgs put: offset]
		ifFalse: [self assert: (offsetTable at: cogMethod cmNumArgs) = offset]
]

{ #category : #trampolines }
SimpleStackBasedCogit >> returnRegForStoreCheck [
	"See the subclass for explanation."
	^backEnd cResultRegister
]

{ #category : #'external primitive support' }
SimpleStackBasedCogit >> rewritePrimInvocationIn: cogMethod to: primFunctionPointer [
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	<var: #primFunctionPointer declareC: #'void (*primFunctionPointer)(void)'>
	| primIndex flags address extent |
	self assert: cogMethod cmType = CMMethod.
	primIndex := coInterpreter
					primitiveIndexOfMethod: cogMethod methodObject
					header: cogMethod methodHeader.
	flags := coInterpreter primitivePropertyFlags: primIndex.
	"See compileInterpreterPrimitive:"
	(flags bitAnd: PrimCallMayCallBack) ~= 0
		ifTrue:
			[address := cogMethod asUnsignedInteger
						+ (externalPrimJumpOffsets at: cogMethod cmNumArgs).
			extent := backEnd
						rewriteJumpLongAt: address
						target: (self cCode: [primFunctionPointer asUnsignedInteger]
									inSmalltalk: [self simulatedTrampolineFor: primFunctionPointer])]
		ifFalse:
			[address := cogMethod asUnsignedInteger
						+ (externalPrimCallOffsets at: cogMethod cmNumArgs).
			extent := backEnd
						rewriteCallAt: address
						target: (self cCode: [primFunctionPointer asUnsignedInteger]
									inSmalltalk: [self simulatedTrampolineFor: primFunctionPointer])].
	processor flushICacheFrom: address to: address + extent
]

{ #category : #initialization }
SimpleStackBasedCogit >> setInterpreter: aCoInterpreter [
	"Initialization of the code generator in the simulator.
	 These objects already exist in the generated C VM
	 or are used only in the simulation."
	<doNotGenerate>
	super setInterpreter: aCoInterpreter.
	externalPrimJumpOffsets := CArrayAccessor on: (Array new: MaxNumArgs + 1).
	externalPrimCallOffsets := CArrayAccessor on: (Array new: MaxNumArgs + 1)
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
		externalPrimCallOffsets at: i put: nil]
]
