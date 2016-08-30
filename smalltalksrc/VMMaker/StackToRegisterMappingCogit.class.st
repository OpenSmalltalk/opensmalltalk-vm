"
StackToRegisterMappingCogit is an optimizing code generator that eliminates a lot of stack operations and inlines some special selector arithmetic.  It does so by a simple stack-to-register mapping scheme based on deferring the generation of code to produce operands until operand-consuming operations.  The operations that consume operands are sends, stores and returns.

See methods in the class-side documentation protocol for more detail.

Instance Variables
	callerSavedRegMask:							<Integer>
	ceEnter0ArgsPIC:								<Integer>
	ceEnter1ArgsPIC:								<Integer>
	ceEnter2ArgsPIC:								<Integer>
	ceEnterCogCodePopReceiverArg0Regs:		<Integer>
	ceEnterCogCodePopReceiverArg1Arg0Regs:	<Integer>
	debugBytecodePointers:						<Set of Integer>
	debugFixupBreaks:								<Set of Integer>
	debugStackPointers:							<CArrayAccessor of (Integer|nil)>
	methodAbortTrampolines:						<CArrayAccessor of Integer>
	methodOrBlockNumTemps:						<Integer>
	optStatus:										<Integer>
	picAbortTrampolines:							<CArrayAccessor of Integer>
	picMissTrampolines:							<CArrayAccessor of Integer>
	realCEEnterCogCodePopReceiverArg0Regs:		<Integer>
	realCEEnterCogCodePopReceiverArg1Arg0Regs:	<Integer>
	regArgsHaveBeenPushed:						<Boolean>
	simSelf:											<CogSimStackEntry>
	simSpillBase:									<Integer>
	simStack:										<CArrayAccessor of CogSimStackEntry>
	simStackPtr:									<Integer>
	traceSimStack:									<Integer>
	useTwoPaths									<Boolean>

callerSavedRegMask
	- the bitmask of the ABI's caller-saved registers

ceEnter0ArgsPIC ceEnter1ArgsPIC ceEnter2ArgsPIC
	- the trampoline for entering an N-arg PIC

ceEnterCogCodePopReceiverArg0Regs ceEnterCogCodePopReceiverArg1Arg0Regs
	- teh trampoline for entering a method with N register args
	
debugBytecodePointers
	- a Set of bytecode pcs for setting breakpoints (simulation only)

debugFixupBreaks
	- a Set of fixup indices for setting breakpoints (simulation only)

debugStackPointers
	- an Array of stack depths for each bytecode for code verification

methodAbortTrampolines
	- a CArrayAccessor of abort trampolines for 0, 1, 2 and N args

methodOrBlockNumTemps
	- the number of method or block temps (including args) in the current compilation unit (method or block)

optStatus
	- the variable used to track the status of ReceiverResultReg for avoiding reloading that register with self between adjacent inst var accesses

picAbortTrampolines
	- a CArrayAccessor of abort trampolines for 0, 1, 2 and N args

picMissTrampolines
	- a CArrayAccessor of abort trampolines for 0, 1, 2 and N args

realCEEnterCogCodePopReceiverArg0Regs realCEEnterCogCodePopReceiverArg1Arg0Regs
	- the real trampolines for ebtering machine code with N reg args when in the Debug regime

regArgsHaveBeenPushed
	- whether the register args have been pushed before frame build (e.g. when an interpreter primitive is called)

simSelf
	- the simulation stack entry representing self in the current compilation unit

simSpillBase
	- the variable tracking how much of the simulation stack has been spilled to the real stack

simStack
	- the simulation stack itself

simStackPtr
	- the pointer to the top of the simulation stack

useTwoPaths
	- a variable controlling whether to create two paths through a method based on the existence of inst var stores.  With immutability this causes a frameless path to be generated if an otherwise frameless method is frameful simply because of inst var stores.  In this case the test to take the first frameless path is if the receiver is not immutable.  Without immutability, if a frameless method contains two or more inst var stores, the first path will be code with no store check, chosen by a single check for the receiver being in new space.

"
Class {
	#name : #StackToRegisterMappingCogit,
	#superclass : #SimpleStackBasedCogit,
	#instVars : [
		'prevBCDescriptor',
		'numPushNilsFunction',
		'pushNilSizeFunction',
		'methodOrBlockNumTemps',
		'regArgsHaveBeenPushed',
		'simSelf',
		'simStack',
		'simStackPtr',
		'simSpillBase',
		'optStatus',
		'ceCallCogCodePopReceiverArg0Regs',
		'ceCallCogCodePopReceiverArg1Arg0Regs',
		'methodAbortTrampolines',
		'picAbortTrampolines',
		'picMissTrampolines',
		'ceCall0ArgsPIC',
		'ceCall1ArgsPIC',
		'ceCall2ArgsPIC',
		'debugStackPointers',
		'debugFixupBreaks',
		'realCECallCogCodePopReceiverArg0Regs',
		'realCECallCogCodePopReceiverArg1Arg0Regs',
		'deadCode',
		'useTwoPaths'
	],
	#classVars : [
		'NeedsMergeFixupFlag',
		'NeedsNonMergeFixupFlag'
	],
	#pools : [
		'CogCompilationConstants',
		'VMMethodCacheConstants',
		'VMObjectIndices',
		'VMStackFrameOffsets'
	],
	#classInstVars : [
		'numPushNilsFunction',
		'pushNilSizeFunction'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
StackToRegisterMappingCogit class >> ancilliaryClasses: options [
	^(super ancilliaryClasses: options),
	  { self basicNew simStackEntryClass. self basicNew bytecodeFixupClass. CogSSOptStatus }
]

{ #category : #documentation }
StackToRegisterMappingCogit class >> callingConvention [
	"The Smalltalk-to-Smalltalk calling convention aims to trade simplicity of compilation against
	 effectiveness of optimization.  Most Smalltalk methods, and certainly most performance-
	 critical primitives have two or less arguments.  So arranging that the receiver and up to two
	 args are in registers means that performance-critical primitives can access their arguments
	 in registers.  So if the argument count is <= numRegArgs nothing is passed on the stack and
	 everything is passed in ReceiverResultReg, Arg0Reg et al.  Above numRegArgs everything is
	 passed on the stack.

	 To save the CoInterpreter from change we shuffle the retpc and push the register args in
	 the prolog so that the frame format is unchanged by register args.  Also, the trampolines for
	 unlinked sends do the same, as does the code preceding an interpreter primitive.  It turns
	 out that this protocol is faster than always pushing arguments.  Comparing benchFib with the
	 shuffling protocol against an always-push protocol on a 2.66 GHz Core i7 (MacBook Pro) , the
	 shuffling protocol is 6.3% faster than the always push protocol.

	 Not shuffling the stack and pushing register arguments after frame build is faster yet again,
	 5.8% faster that the stack shuffle.  So it might be worth-while to change the CoInterpreter's
	 frame management to allow numArgs <= numRegArgs frames to push receiver and arguments
	 after saving the return pc.  This implies changes in stack-to-context mapping, GC,
	 interpreter-to-machine code frame conversion and no doubt else where.

	 Hence the calling convention is

		- if the number of arguments is less than or equal to numRegArgs then the receiver and
		  arguments are passed in registers.  numRegArgs is 1 for V3, and 2 for Spur.  The receiver
		  is passed in ReceiverResultReg, the first argument in Arg0Reg (esi on x86) and the second
		  argument (if numRegArgs = 2) in Arg1Reg (edi on x86).

		- if the number of arguments is greater than numRegArgs then the calling convention is as
		  for SimpleStackBasedCogIt; ReceiverResultReg contains the receiver, and the receiver and
		  arguments are all on the stack, receiver furthest from top-of-stack.  If the argument count
		  is > 2 then argument count is passed in SendNumArgsReg (for the benefit of the run-time
		  linking routines; it is ignored in linked sends).

		On return the result is in ReceiverResultReg.  The callee removes arguments from the stack
		(Pascal convention).

		Note that if a machine code method contains a call to an interpreter primitive it will push any
		register arguments (and if on a RISC, the return pc from the LinReg) on the stack before calling
		the primitive so that to the primitive the stack looks the same as it does in the interpreter.

		Within all machine code primitives except genPrimitiveClosureValue and genPrimitivePerform all
		arguments are taken from registers since no machine code primitive has more than numRegArgs
		arguments.  genPrimitiveClosureValue pushes its register arguments immedately only for laziness
		to be able to reuse SimpleStackBasedCogit's code.  genPrimitivePerform adjusts its arguments
		as required by special-purpose code.

		Within machine code methods with interpreter primitives the register arguments are pushed
		before calling the interpreter primitive.  In normal methods and if not already done so in primitive
		code, the register arguments are pushed during frame build.  If a method is compiled frameless
		it will access its arguments in registers."
]

{ #category : #translation }
StackToRegisterMappingCogit class >> declareCVarsIn: aCodeGen [
	aCodeGen
		var: #methodAbortTrampolines
			declareC: 'sqInt methodAbortTrampolines[4]';
		var: #picAbortTrampolines
			declareC: 'sqInt picAbortTrampolines[4]';
		var: #picMissTrampolines
			declareC: 'sqInt picMissTrampolines[4]';
		var: 'ceCall0ArgsPIC'
			declareC: 'void (*ceCall0ArgsPIC)(void)';
		var: 'ceCall1ArgsPIC'
			declareC: 'void (*ceCall1ArgsPIC)(void)';
		var: 'ceCall2ArgsPIC'
			declareC: 'void (*ceCall2ArgsPIC)(void)';
		var: #ceCallCogCodePopReceiverArg0Regs
			declareC: 'void (*ceCallCogCodePopReceiverArg0Regs)(void)';
		var: #realCECallCogCodePopReceiverArg0Regs
			declareC: 'void (*realCECallCogCodePopReceiverArg0Regs)(void)';
		var: #ceCallCogCodePopReceiverArg1Arg0Regs
			declareC: 'void (*ceCallCogCodePopReceiverArg1Arg0Regs)(void)';
		var: #realCECallCogCodePopReceiverArg1Arg0Regs
			declareC: 'void (*realCECallCogCodePopReceiverArg1Arg0Regs)(void)';
		var: 'simStack'
			declareC: 'SimStackEntry simStack[', self simStackSlots asString, ']';
		var: 'simSelf'
			type: #CogSimStackEntry;
		var: #optStatus
			type: #CogSSOptStatus;
		var: 'prevBCDescriptor'
			type: #'BytecodeDescriptor *'.

	self numPushNilsFunction ifNotNil:
		[aCodeGen
			var: 'numPushNilsFunction'
				declareC: 'sqInt (* const numPushNilsFunction)(struct _BytecodeDescriptor *,sqInt,sqInt,sqInt) = ', (aCodeGen cFunctionNameFor: self numPushNilsFunction);
			var: 'pushNilSizeFunction'
				declareC: 'sqInt (* const pushNilSizeFunction)(sqInt,sqInt) = ', (aCodeGen cFunctionNameFor: self pushNilSizeFunction)].

	aCodeGen
		addSelectorTranslation: #register to: (aCodeGen cFunctionNameFor: 'registerr');
		addSelectorTranslation: #register: to: (aCodeGen cFunctionNameFor: 'registerr:')
]

{ #category : #'class initialization' }
StackToRegisterMappingCogit class >> initializeBytecodeTableForNewspeakV4 [
	"StackToRegisterMappingCogit initializeBytecodeTableForNewspeakV4"

	numPushNilsFunction := #v4:Num:Push:Nils:.
	pushNilSizeFunction := #v4PushNilSize:numInitialNils:.
	NSSendIsPCAnnotated := true. "IsNSSendCall used by SendAbsentImplicit"
	FirstSpecialSelector := 80.
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
		(1    0   15 genPushReceiverVariableBytecode isInstVarRef needsFrameNever: 1)
		(1  16   31 genPushLiteralVariable16CasesBytecode needsFrameNever: 1)
		(1  32   63 genPushLiteralConstantBytecode needsFrameNever: 1)
		(1  64   75 genPushTemporaryVariableBytecode needsFrameIfMod16GENumArgs: 1)
		(1  76   76 genPushReceiverBytecode needsFrameNever: 1)
		(1  77   77 genExtPushPseudoVariableOrOuterBytecode needsFrameIfExtBGT2: 1)
		(1  78   78 genPushConstantZeroBytecode needsFrameNever: 1)
		(1  79   79 genPushConstantOneBytecode needsFrameNever: 1)

		(1   80   80 genSpecialSelectorArithmetic isMapped AddRR)
		(1   81   81 genSpecialSelectorArithmetic isMapped SubRR)
		(1   82   82 genSpecialSelectorComparison isMapped JumpLess)
		(1   83   83 genSpecialSelectorComparison isMapped JumpGreater)
		(1   84   84 genSpecialSelectorComparison isMapped JumpLessOrEqual)
		(1   85   85 genSpecialSelectorComparison isMapped JumpGreaterOrEqual)
		(1   86   86 genSpecialSelectorComparison isMapped JumpZero)
		(1   87   87 genSpecialSelectorComparison isMapped JumpNonZero)
		(1   88   93 genSpecialSelectorSend isMapped)	 " #* #/ #\\ #@ #bitShift: //"
		(1   94   94 genSpecialSelectorArithmetic isMapped AndRR)
		(1   95   95 genSpecialSelectorArithmetic isMapped OrRR)
		(1   96 101 genSpecialSelectorSend isMapped) "#at: #at:put: #size #next #nextPut: #atEnd"
		(1 102 102 genSpecialSelectorEqualsEquals needsFrameNever: notMapped -1) "not mapped because it is directly inlined (for now)"
		(1 103 103 genSpecialSelectorClass needsFrameIfStackGreaterThanOne: notMapped 0) "not mapped because it is directly inlined (for now)"
		(1 104 111 genSpecialSelectorSend isMapped) "#blockCopy: #value #value: #do: #new #new: #x #y"

		(1 112 127 genSendLiteralSelector0ArgsBytecode isMapped)
		(1 128 143 genSendLiteralSelector1ArgBytecode isMapped)
		(1 144 159 genSendLiteralSelector2ArgsBytecode isMapped)
		(1 160 175	genSendAbsentImplicit0ArgsBytecode isMapped hasIRC)
			
		(1 176 183 genStoreAndPopReceiverVariableBytecode isInstVarRef is1ByteInstVarStore isMappedIfImmutability needsFrameIfImmutability: -1)
			
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
		(2 224 224 extABytecode extension					needsFrameNever: 0)
		(2 225 225 extBBytecode extension					needsFrameNever: 0)
		(2 226 226 genExtPushReceiverVariableBytecode isInstVarRef)
		(2 227 227 genExtPushLiteralVariableBytecode		needsFrameNever: 1)
		(2 228 228 genExtPushLiteralBytecode					needsFrameNever: 1)
		(2 229 229 genExtPushIntegerBytecode				needsFrameNever: 1)
		(2 230 230 genLongPushTemporaryVariableBytecode)
		(2 231 231 genPushNewArrayBytecode)
		(2 232 232 genExtStoreReceiverVariableBytecode isInstVarRef isMappedIfImmutability)
		(2 233 233 genExtStoreLiteralVariableBytecode isMappedIfImmutability)
		(2 234 234 genLongStoreTemporaryVariableBytecode)
		(2 235 235 genExtStoreAndPopReceiverVariableBytecode isInstVarRef isMappedIfImmutability)
		(2 236 236 genExtStoreAndPopLiteralVariableBytecode isMappedIfImmutability)
		(2 237 237 genLongStoreAndPopTemporaryVariableBytecode)

		(2 238 238 genExtSendBytecode isMapped)
		(2 239 239 genExtSendSuperBytecode isMapped)
		(2 240 240 genExtSendAbsentImplicitBytecode isMapped hasIRC)
		(2 241 241 genExtSendAbsentDynamicSuperBytecode isMapped hasIRC)

		(2 242 242 genExtUnconditionalJump	branch isMapped "because of interrupt check" v4:Long:Branch:Distance:)
		(2 243 243 genExtJumpIfTrue			branch isBranchTrue isMapped "because of mustBeBoolean" v4:Long:Branch:Distance:)
		(2 244 244 genExtJumpIfFalse			branch isBranchFalse isMapped "because of mustBeBoolean" v4:Long:Branch:Distance:)

		(2 245 245	genExtSendAbsentSelfBytecode isMapped hasIRC)

		(2 246 248	unknownBytecode)

		"3 byte bytecodes"
		(3 249 249 genCallPrimitiveBytecode)
		(3 250 250 genPushRemoteTempLongBytecode)
		(3 251 251 genStoreRemoteTempLongBytecode)
		(3 252 252 genStoreAndPopRemoteTempLongBytecode)
		(3 253 253 genExtPushClosureBytecode block v4:Block:Code:Size:)
		(3 254 254	genExtSendAbsentOuterBytecode isMapped hasIRC)

		(3 255 255	unknownBytecode))
]

{ #category : #'class initialization' }
StackToRegisterMappingCogit class >> initializeBytecodeTableForSistaV1 [
	"StackToRegisterMappingCogit initializeBytecodeTableForSistaV1"

	numPushNilsFunction := #sistaV1:Num:Push:Nils:.
	pushNilSizeFunction := #sistaV1PushNilSize:numInitialNils:.
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
		(1    0   15 genPushReceiverVariableBytecode isInstVarRef		needsFrameNever: 1)
		(1  16   31 genPushLitVarDirSup16CasesBytecode				needsFrameNever: 1)
		(1  32   63 genPushLiteralConstantBytecode					needsFrameNever: 1)
		(1  64   75 genPushTemporaryVariableBytecode				needsFrameIfMod16GENumArgs: 1)
		(1  76   76 genPushReceiverBytecode							needsFrameNever: 1)
		(1  77   77 genPushConstantTrueBytecode						needsFrameNever: 1)
		(1  78   78 genPushConstantFalseBytecode					needsFrameNever: 1)
		(1  79   79 genPushConstantNilBytecode						needsFrameNever: 1)
		(1  80   80 genPushConstantZeroBytecode						needsFrameNever: 1)
		(1  81   81 genPushConstantOneBytecode						needsFrameNever: 1)
		(1  82   82 genExtPushPseudoVariable)
		(1  83   83 duplicateTopBytecode								needsFrameNever: 1)

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
		(1  96   96 genSpecialSelectorArithmetic isMapped AddRR)
		(1  97   97 genSpecialSelectorArithmetic isMapped SubRR)
		(1  98   98 genSpecialSelectorComparison isMapped JumpLess)
		(1  99   99 genSpecialSelectorComparison isMapped JumpGreater)
		(1 100 100 genSpecialSelectorComparison isMapped JumpLessOrEqual)
		(1 101 101 genSpecialSelectorComparison isMapped JumpGreaterOrEqual)
		(1 102 102 genSpecialSelectorComparison isMapped JumpZero)
		(1 103 103 genSpecialSelectorComparison isMapped JumpNonZero)
		(1 104 109 genSpecialSelectorSend isMapped)	 " #* #/ #\\ #@ #bitShift: //"
		(1 110 110 genSpecialSelectorArithmetic isMapped AndRR)
		(1 111 111 genSpecialSelectorArithmetic isMapped OrRR)
		(1 112 117 genSpecialSelectorSend isMapped) "#at: #at:put: #size #next #nextPut: #atEnd"
		(1 118 118 genSpecialSelectorEqualsEquals needsFrameNever: notMapped -1) "not mapped because it is directly inlined (for now)"
		(1 119 119 genSpecialSelectorClass needsFrameIfStackGreaterThanOne: notMapped 0) "not mapped because it is directly inlined (for now)"
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
		(1 200 207 genStoreAndPopReceiverVariableBytecode isInstVarRef is1ByteInstVarStore isMappedIfImmutability needsFrameIfImmutability: -1)
		
		(1 208 215 genStoreAndPopTemporaryVariableBytecode)

		(1 216 216 genPopStackBytecode needsFrameNever: -1)

		(1 217 217 genUnconditionalTrapBytecode isMapped)

		(1 218 223 unknownBytecode)

		"2 byte bytecodes"
		(2 224 224 extABytecode extension)
		(2 225 225 extBBytecode extension)

		"pushes"
		(2 226 226 genExtPushReceiverVariableBytecode isInstVarRef)		"Needs a frame for context inst var access"
		(2 227 227 genExtPushLitVarDirSupBytecode			needsFrameNever: 1)
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
		(2 240 240 genSistaExtStoreAndPopReceiverVariableBytecode isInstVarRef isMappedIfImmutability)
		(2 241 241 genSistaExtStoreAndPopLiteralVariableBytecode isMappedIfImmutability)
		(2 242 242 genLongStoreAndPopTemporaryVariableBytecode)
		(2 243 243 genSistaExtStoreReceiverVariableBytecode isInstVarRef isMappedIfImmutability)
		(2 244 244 genSistaExtStoreLiteralVariableBytecode isMappedIfImmutability)
		(2 245 245 genLongStoreTemporaryVariableBytecode)

		(2 246 247	unknownBytecode)

		"3 byte bytecodes"
		(3 248 248 genCallPrimitiveBytecode)
		(3 249 249 genExtPushFullClosureBytecode)
		(3 250 250 genExtPushClosureBytecode block v4:Block:Code:Size:)
		(3 251 251 genExtPushRemoteTempOrInstVarLongBytecode)
		(3 252 252 genExtStoreRemoteTempOrInstVarLongBytecode isMappedIfImmutability)
		(3 253 253 genExtStoreAndPopRemoteTempOrInstVarLongBytecode isMappedIfImmutability)

		(3 254 254	genExtJumpIfNotInstanceOfBehaviorsOrPopBytecode branch v4:Long:BranchIfNotInstanceOf:Distance:)
		
		(3 255 255	unknownBytecode))
]

{ #category : #'class initialization' }
StackToRegisterMappingCogit class >> initializeBytecodeTableForSqueakV3PlusClosures [
	"StackToRegisterMappingCogit initializeBytecodeTableForSqueakV3PlusClosures"

	numPushNilsFunction := #v3:Num:Push:Nils:.
	pushNilSizeFunction := #v3PushNilSize:numInitialNils:.
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
		(1    0   15 genPushReceiverVariableBytecode isInstVarRef needsFrameNever: 1)
		(1  16   31 genPushTemporaryVariableBytecode needsFrameIfMod16GENumArgs: 1)
		(1  32   63 genPushLiteralConstantBytecode needsFrameNever: 1)
		(1  64   95 genPushLiteralVariableBytecode needsFrameNever: 1)
		(1  96 103 genStoreAndPopReceiverVariableBytecode isInstVarRef is1ByteInstVarStore isMappedIfImmutability needsFrameIfImmutability: -1)
		(1 104 111 genStoreAndPopTemporaryVariableBytecode)
		(1 112 112 genPushReceiverBytecode needsFrameNever: 1)
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
		(3 132 132 doubleExtendedDoAnythingBytecode isMapped) "well, maybe inst var ref"
		(2 133 133 genExtendedSuperBytecode isInstVarRef isMapped)
		(2 134 134 genSecondExtendedSendBytecode isMapped)
		(1 135 135 genPopStackBytecode needsFrameNever: -1)
		(1 136 136 duplicateTopBytecode needsFrameNever: 1)

		(1 137 137 genPushActiveContextBytecode)
		(2 138 138 genPushNewArrayBytecode)),

		((initializationOptions at: #SpurObjectMemory ifAbsent: [false])
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

		(1 176 176 genSpecialSelectorArithmetic isMapped AddRR)
		(1 177 177 genSpecialSelectorArithmetic isMapped SubRR)
		(1 178 178 genSpecialSelectorComparison isMapped JumpLess)
		(1 179 179 genSpecialSelectorComparison isMapped JumpGreater)
		(1 180 180 genSpecialSelectorComparison isMapped JumpLessOrEqual)
		(1 181 181 genSpecialSelectorComparison isMapped JumpGreaterOrEqual)
		(1 182 182 genSpecialSelectorComparison isMapped JumpZero)
		(1 183 183 genSpecialSelectorComparison isMapped JumpNonZero)
		(1 184 189 genSpecialSelectorSend isMapped)	 " #* #/ #\\ #@ #bitShift: //"
		(1 190 190 genSpecialSelectorArithmetic isMapped AndRR)
		(1 191 191 genSpecialSelectorArithmetic isMapped OrRR)
		(1 192 197 genSpecialSelectorSend isMapped) "#at: #at:put: #size #next #nextPut: #atEnd"
		(1 198 198 genSpecialSelectorEqualsEquals needsFrameNever: notMapped -1) "not mapped because it is directly inlined (for now)"
		(1 199 199 genSpecialSelectorClass needsFrameIfStackGreaterThanOne: notMapped 0) "not mapped because it is directly inlined (for now)"
		(1 200 207 genSpecialSelectorSend isMapped) "#blockCopy: #value #value: #do: #new #new: #x #y"
		(1 208 223 genSendLiteralSelector0ArgsBytecode isMapped)
		(1 224 239 genSendLiteralSelector1ArgBytecode isMapped)
		(1 240 255 genSendLiteralSelector2ArgsBytecode isMapped))
]

{ #category : #'class initialization' }
StackToRegisterMappingCogit class >> initializeBytecodeTableForSqueakV3PlusClosuresNewspeakV4Hybrid [
	"SimpleStackBasedCogit initializeBytecodeTableForSqueakV3PlusClosuresNewspeakV4Hybrid"
	"StackToRegisterMappingCogit initializeBytecodeTableForSqueakV3PlusClosuresNewspeakV4Hybrid"

	super initializeBytecodeTableForSqueakV3PlusClosuresNewspeakV4Hybrid.
	numPushNilsFunction := #v3or4:Num:Push:Nils:.
	pushNilSizeFunction := #v3or4PushNilSize:numInitialNils:
]

{ #category : #'class initialization' }
StackToRegisterMappingCogit class >> initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid [
	"StackToRegisterMappingCogit initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid"

	super initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid.
	numPushNilsFunction := #squeakV3orSistaV1:Num:Push:Nils:.
	pushNilSizeFunction := #squeakV3orSistaV1PushNilSize:numInitialNils:
]

{ #category : #'class initialization' }
StackToRegisterMappingCogit class >> initializeSimStackConstants [
	"The simulation stack is used to delay code generation until operands are consumed by
	 some operation, thereby avoiding pushing operands to the real stack and enabling
	 mapping stack contents to registers, and cheaply apply various peephole optimizations.
	 The simulation stack is an array of CogSimStackEntry structs.  Each entry defines the
	 object on the virtual stack (Smalltalk context stack) as compilation proceeds.  See
	 stackToRegisterMapping in this class for documentation."

	SSIllegal := 0.
	SSBaseOffset := 1.
	SSConstant := 2.
	SSRegister := 3.
	SSSpill := 4
]

{ #category : #'class initialization' }
StackToRegisterMappingCogit class >> initializeWithOptions: optionsDictionary [

	super initializeWithOptions: optionsDictionary.
	self initializeSimStackConstants
]

{ #category : #translation }
StackToRegisterMappingCogit class >> isAcceptableAncilliaryClass: aClass [
	^(aClass includesBehavior: CogBytecodeFixup)
		ifTrue: [aClass == self basicNew bytecodeFixupClass]
		ifFalse:
			[(aClass includesBehavior: CogSimStackEntry)
				ifTrue: [aClass == self basicNew simStackEntryClass]
				ifFalse: [true]]
]

{ #category : #translation }
StackToRegisterMappingCogit class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^(super mustBeGlobal: var)
	   or: [#('ceCallCogCodePopReceiverArg0Regs' 'ceCallCogCodePopReceiverArg1Arg0Regs'
			'realCECallCogCodePopReceiverArg0Regs' 'realCECallCogCodePopReceiverArg1Arg0Regs'
			'ceCall0ArgsPIC' 'ceCall1ArgsPIC' 'ceCall2ArgsPIC') includes: var]
]

{ #category : #accessing }
StackToRegisterMappingCogit class >> numPushNilsFunction [
	"Answer the value of numPushNilsFunction"

	^numPushNilsFunction
]

{ #category : #accessing }
StackToRegisterMappingCogit class >> numTrampolines [
	^super numTrampolines + 12 "includes register args aborts"

	"Cogit withAllSubclasses collect: [:c| {c. (c instVarNames select: [:ea| ea beginsWith: 'ce']) size}]"
	"self instVarNames select: [:ea| ea beginsWith: 'ce']"
]

{ #category : #accessing }
StackToRegisterMappingCogit class >> pushNilSizeFunction [
	"Answer the value of pushNilSizeFunction"

	^ pushNilSizeFunction
]

{ #category : #translation }
StackToRegisterMappingCogit class >> requiredMethodNames: options [
	^(super requiredMethodNames: options)
		add: self numPushNilsFunction;
		add: self pushNilSizeFunction;
		yourself
]

{ #category : #translation }
StackToRegisterMappingCogit class >> shouldGenerateTypedefFor: aStructClass [
	"Hack to work-around mutliple definitions.  Sometimes a type has been defined in an include."
	^aStructClass ~~ CogBytecodeFixup "overridden by CogSSBytecodeFixup"
	  and: [super shouldGenerateTypedefFor: aStructClass]
]

{ #category : #translation }
StackToRegisterMappingCogit class >> simStackSlots [
	^ self basicNew simStackSlots
]

{ #category : #documentation }
StackToRegisterMappingCogit class >> stackToRegisterMapping [
	"Stack to register mapping is enabled via a simulation stack { simStack. simStackPtr, simSpillBase } of
	 operand descriptors (CogSimStackEntry) which serve
		- to avoid pushing operands to the actual stack by deferring operand manipulation until an
		  operand-consuming operation (send, store, run-time call)
		- to record operand type information for constants to avoid unnecessary type checks (e.g. tag checks)
		- as a simple register allocator since any live registers are recorded in descriptors on the stack.

	The operand types are
		SSBaseOffset - a value in memory at an offset relative to some register.  For method receiver args
						 and temps the base register is  FPReg (in a frameful method).  For indirect temps
						 the register could be any unassigned register.
		SSConstant - a method literal, hence a Smalltalk object
		SSRegister - the result of an expression assigned to a register
		SSSpill - a value spilled to the actual stack
	The special descriptor simSelf defines self in the current method, relative to FPReg in frameful
	 methods and  in a register in frameless methods.

	The register allocator aspect allocates registers by searching for SSBaseOffset and SSRegister
	 descriptors, computing the set of live registers, and then enumerating to find unused ones.
	 Simulation stack contents must be spilled to the actual stack
		- at a send (since at a suspension point the actual stack must be valid),
		- to make a register available if the code generator needs it
		- at a control flow join (since the two control flows could compute different stack contents and
		  we choose to avoid the complexity of saving stack contents to allow merging at join points).

	At a control-flow join we must discard type information for values pushed to the stack in either
	arm of the control-flow, but need /not/ for items pushed before the control flow diverged.  e.g. in
		self at: 1 put: (expr ifTrue: [v1] ifFalse: [v2]).
	the 1 is still valid after the control flow join for (expr ifTrue: [v1] ifFalse: [v2]).  So at a conditional
	branch we record simStackPtr in the target fixup and only void types between it and the
	simStackPtr at the join point.  This type voiding operation is called merge:.  For now we simply throw
	away all type info but would like to implement the baove scheme soon.

	 We can determine the stack depth at a conditional branch (if), but how do we determine the stack
	 depth following an unconditional jump (else)?  There are essentially three cases
		e ifTrue: [u] ifFalse: [v],
		e ifTrue: [^u] ifFalse: [v],
		e ifTrue: [u] ifFalse: [^v]

		1		expr
		2		jumpCond L1
		3		push
		4		jump L2
		5	L1:
		6		push
		7	L2:

		1		expr
		2		jumpCond L1
		3		ret
		4	L1:
		5		push

		1		expr
		2		jumpCond L1
		3		push
		4		jump L2
		5	L1:
		6		ret
		7	L2:

	In the first case we can know the merge base at L2 by propagating the merge base from 4 jump L2, which
	precedes the target of 2 jumpCond L1.  i.e. the merge base at 7 L2 is the stack pointer at 4 jump L2, which
	precedes the target of 2 jumpCond L1.  So at 2 jumpCond L1 we copy the stack pointer to the merge base
	at 5 L1, /and/ to the preceding 4 jump L2, and when we reach 4 jump L2, propagate the merge base to 7 L2.

	 Since we're conscious of JIT performance we restrict the live register search range by maintaining
	 simSpillBase, which is the index of the unspilled entry furthest from the end of simulation stack.
	 Only entries from simSpillBase to simStackPtr can contain unspilled, and hence live and volatile
	 registers (the FPReg is not volatile).

	 We further optimize by maintaining a simple optimization status for register contents.
	 We record whether ReceiverResultReg contains the receiver or an indirect temp vector
	 and merge this status at control-flow joins."
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> addBlockStartAt: bytecodepc numArgs: numArgs numCopied: numCopied span: span [
	"Add a blockStart for an embedded block.  For a binary tree walk block dispatch
	 blocks must be compiled in pc/depth-first order but are scanned in breadth-first
	 order, so do an insertion sort (which of course is really a bubble sort because we
	 have to move everything higher to make room)."
	<returnTypeC: #'BlockStart *'>
	| i blockStart |
	<var: #blockStart type: #'BlockStart *'>
	"Transcript ensureCr; nextPutAll: 'addBlockStartAt: '; print: bytecodepc; cr; flush."
	blockCount > 0
		ifTrue:
			[i := blockCount - 1.
			 [blockStart := self addressOf: (blockStarts at: i).
			  "check for repeat addition during recompilation due to initialNil miscount."
			  blockStart startpc = bytecodepc ifTrue:
				[^blockStart].
			  blockStart startpc > bytecodepc
			  and: [i > 0]] whileTrue:
				[i := i - 1].
			 blockCount to: i + 1 by: -1 do:
				[:j|
				blockStarts at: j put: (blockStarts at: j - 1)].
			blockStart := self cCode: [self addressOf: (blockStarts at: i + 1)]
								inSmalltalk: [blockStarts at: i + 1 put: CogBlockStart new]]
		ifFalse:
			[blockStart := self cCode: [self addressOf: (blockStarts at: blockCount)]
								inSmalltalk: [blockStarts at: blockCount put: CogBlockStart new]].
	
	blockCount := blockCount + 1.
	blockStart
		startpc: bytecodepc;
		numArgs: numArgs;
		numCopied: numCopied;
		numInitialNils: 0;
		stackCheckLabel: nil;
		hasInstVarRef: false;
		span: span.
	^blockStart
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> adjustArgumentsForPerform: numArgs [
	"Generate code to adjust the possibly stacked arguments immediately
	 before jumping to a method looked up by a perform primitive."
	self assert: self numRegArgs <= 2.
	self assert: numArgs >= 1.
	numArgs <= self numRegArgs ifTrue:
		[numArgs = 2 ifTrue:
			[self MoveR: Arg1Reg R: Arg0Reg].
		 ^self].

	"If the arity is one more than the max numRegArgs, the receiver and all arguments have to be removed from the stack."
	self numRegArgs + 1 = numArgs ifTrue:
		[backEnd hasLinkRegister
			ifTrue:
				[self numRegArgs = 2
					ifTrue:
						[self MoveMw: 0 r: SPReg R: Arg1Reg.
						 self MoveMw: objectMemory wordSize r: SPReg R: Arg0Reg]
					ifFalse:
						[self MoveMw: 0 r: SPReg R: Arg0Reg].
				 self AddCq: numArgs + 1 * objectMemory wordSize R: SPReg]
			ifFalse:
				[self MoveMw: 0 r: SPReg R: TempReg. "save retpc"
				 self numRegArgs = 2
					ifTrue:
						[self MoveMw: objectMemory wordSize r: SPReg R: Arg1Reg.
						 self MoveMw: objectMemory wordSize * 2 r: SPReg R: Arg0Reg]
					ifFalse:
						[self MoveMw: objectMemory wordSize r: SPReg R: Arg0Reg].
				 self AddCq: numArgs + 1 * objectMemory wordSize R: SPReg.
				 self MoveR: TempReg Mw: 0 r: SPReg "Overwrite pushed receiver; ReceiverResultReg already contains receiver."].
		 ^self].

	"e.g.	Receiver				Receiver
			Selector/Arg0	=>		Arg1
			Arg1					Arg2
	 		Arg2			sp->	Arg3
	 sp->	Arg3"
	super adjustArgumentsForPerform: numArgs
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> allocateEqualsEqualsRegistersArgNeedsReg: argNeedsReg rcvrNeedsReg: rcvrNeedsReg into: binaryBlock [
	<inline: true>
	| argReg rcvrReg |
	self assert: (argNeedsReg or: [rcvrNeedsReg]).
	argReg := rcvrReg := NoReg.
	argNeedsReg
		ifTrue: 
			[rcvrNeedsReg
				ifTrue:
					[self allocateRegForStackTopTwoEntriesInto: [:rTop :rNext| argReg := rTop. rcvrReg := rNext].
					 self ssTop popToReg: argReg.
					 (self ssValue: 1) popToReg: rcvrReg]
				ifFalse:
					[argReg := self allocateRegForStackEntryAt: 0.
					 self ssTop popToReg: argReg.
					 "If the receiver is a spilled constant we need to pop it from the stack."
					 (self ssValue: 1) spilled ifTrue:
						[self AddCq: objectMemory wordSize R: SPReg]]]
		ifFalse:
			[self assert: rcvrNeedsReg.
			 self deny: self ssTop spilled.
			 rcvrReg := self allocateRegForStackEntryAt: 1.
			 (self ssValue: 1) popToReg: rcvrReg].
		
	self deny: (argNeedsReg and: [argReg = NoReg]).
	self deny: (rcvrNeedsReg and: [rcvrReg = NoReg]).

	binaryBlock value: rcvrReg value: argReg
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> allocateRegForStackEntryAt: index [
	"If the stack entry is already in a register, answers it,
	else allocate a new register for it"
	<inline: true>
	^ self allocateRegForStackEntryAt: index notConflictingWith: 0
	
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> allocateRegForStackEntryAt: index notConflictingWith: regMask [
	"If the stack entry is already in a register not conflicting with regMask, answers it,
	else allocate a new register not conflicting with reg mask"
	<var: #stackEntry type: #'CogSimStackEntry *'>
	| stackEntry |
	stackEntry := self ssValue: index.
	(stackEntry type = SSRegister and: [ (self register: stackEntry register isInMask: regMask) not ]) ifTrue: 
		[ ^ stackEntry register].
	^ self allocateRegNotConflictingWith: regMask
	
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> allocateRegForStackTopThreeEntriesInto: trinaryBlock thirdIsReceiver: thirdIsReceiver [
	"Answers registers for the 3 top values on stack. If the values are already in registers, answers
	these registers, else allocate registers not conflicting with each others.
	If thirdIsReceiver is true, allocate ReceiverResultReg for stackTop - 2 (for ceStoreCheck)."
	<inline: true>
	| topRegistersMask rTop rNext rThird |
	
	topRegistersMask := 0.
	rTop := rNext := rThird := NoReg.
	
	(self ssTop type = SSRegister and: [ thirdIsReceiver not or: [ self ssTop register ~= ReceiverResultReg ] ]) ifTrue: 
		[ topRegistersMask := self registerMaskFor: (rTop := self ssTop register)].
	((self ssValue: 1) type = SSRegister and: [ thirdIsReceiver not or: [ (self ssValue: 1) register ~= ReceiverResultReg ] ]) ifTrue: 
		[ topRegistersMask := topRegistersMask bitOr: (self registerMaskFor: (rNext := (self ssValue: 1) register))].
	((self ssValue: 2) type = SSRegister and: [thirdIsReceiver not or: [ (self ssValue: 2) register = ReceiverResultReg ] ]) ifTrue: 
		[ topRegistersMask := topRegistersMask bitOr: (self registerMaskFor: (rThird := (self ssValue: 2) register))].
	
	rThird = NoReg ifTrue:
		[ thirdIsReceiver 
			ifTrue:
				[ rThird := ReceiverResultReg.  "Free ReceiverResultReg if it was not free"
				self ssAllocateRequiredReg: ReceiverResultReg.
				optStatus isReceiverResultRegLive: false ]
			ifFalse: [ rThird := self allocateRegNotConflictingWith: topRegistersMask ].
		topRegistersMask := topRegistersMask bitOr: (self registerMaskFor: rThird) ].
	
	rTop = NoReg ifTrue:
		[ rTop := self allocateRegNotConflictingWith: topRegistersMask.
		  topRegistersMask := topRegistersMask bitOr: (self registerMaskFor: rTop) ].
	
	rNext = NoReg ifTrue:
		[ rNext := self allocateRegNotConflictingWith: topRegistersMask ].

	self deny: (rTop = NoReg or: [rNext = NoReg or: [rThird = NoReg]]).

	^ trinaryBlock value: rTop value: rNext value: rThird
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> allocateRegForStackTopTwoEntriesInto: binaryBlock [
	"Answers registers for the 2 top values on stack. If the values are already in registers, answers
	these registers, else allocate registers not conflicting with each others."
	<inline: true>
	| topRegistersMask rTop rNext |
	
	topRegistersMask := 0.
	rTop := rNext := NoReg.
	
	self ssTop type = SSRegister ifTrue: 
		[ rTop := self ssTop register].
	(self ssValue: 1) type = SSRegister ifTrue: 
		[ topRegistersMask := self registerMaskFor: (rNext := (self ssValue: 1) register)].
	
	rTop = NoReg ifTrue:
		[ rTop := self allocateRegNotConflictingWith: topRegistersMask ].
	
	rNext = NoReg ifTrue:
		[ rNext := self allocateRegNotConflictingWith: (self registerMaskFor: rTop) ].

	self deny: (rTop = NoReg or: [rNext = NoReg]).

	^ binaryBlock value: rTop value: rNext
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> allocateRegNotConflictingWith: regMask [
	| reg |
	"if there's a free register, use it"
	reg := backEnd availableRegisterOrNoneFor: (self liveRegisters bitOr: regMask).
	reg = NoReg ifTrue: "No free register, choose one that does not conflict with regMask"
		[reg := self freeAnyRegNotConflictingWith: regMask].
	reg = ReceiverResultReg ifTrue: "If we've allocated RcvrResultReg, it's not live anymore"
		[optStatus isReceiverResultRegLive: false].
	^ reg
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> annotateInstructionForBytecode [
	"Annotate the current instruction as having a bytecode pc.  If the current instruction
	 is already annotated, insert a nop and annotate that.  We cannot have the same instruction
	 address carry multiple annotations."
	<inline: true>
	self annotateBytecode: (self prevInstIsPCAnnotated
								ifTrue: [self Nop]
								ifFalse: [self Label]).
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> anyReferencesToRegister: reg inTopNItems: n [
	| regMask |
	regMask := self registerMaskFor: reg.
	simStackPtr to: simStackPtr - n + 1 by: -1 do:
		[:i|
		((self simStackAt: i) registerMask anyMask: regMask) ifTrue:
			[^true]].
	^false
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> assertCorrectSimStackPtr [
	<inline: true> "generates nothing anyway"
	 self cCode: '' inSmalltalk:
		[deadCode ifFalse:
			[self assert: simStackPtr + (needsFrame ifTrue: [0] ifFalse: [1])
						= (self debugStackPointerFor: bytecodePC)]].
	
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> availableRegOrNoneNotConflictingWith: regMask [
	<inline: true>
	"If there's a free register, answer it, otherwise answer NoReg."
	^backEnd availableRegisterOrNoneFor: (self liveRegisters bitOr: regMask)
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> bytecodeFixupClass [
	<doNotGenerate>
	^CogSSBytecodeFixup
]

{ #category : #trampolines }
StackToRegisterMappingCogit >> cPICMissTrampolineFor: numArgs [
	^picMissTrampolines at: (numArgs min: self numRegArgs + 1)
]

{ #category : #debugging }
StackToRegisterMappingCogit >> callCogCodePopReceiverArg0Regs [
	"This is a static version of ceCallCogCodePopReceiverArg0Regs
	 for break-pointing when debugging in C."
	<api>
	<inline: false>
	"This exists only for break-pointing."
	self cCode: [self realCECallCogCodePopReceiverArg0Regs]
		inSmalltalk: [self ceCallCogCodePopReceiverArg0Regs]
]

{ #category : #debugging }
StackToRegisterMappingCogit >> callCogCodePopReceiverArg1Arg0Regs [
	"This is a static version of ceCallCogCodePopReceiverArg1Arg0Regs
	 for break-pointing when debugging in C."
	<api>
	<inline: false>
	"This exists only for break-pointing."
	self cCode: [self realCECallCogCodePopReceiverArg1Arg0Regs]
		inSmalltalk: [self ceCallCogCodePopReceiverArg1Arg0Regs]
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> ceCall0ArgsPIC [
	<api: 'extern void (*ceCall0ArgsPIC)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceCall0ArgsPIC numArgs: 1
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> ceCall1ArgsPIC [
	<api: 'extern void (*ceCall1ArgsPIC)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceCall1ArgsPIC numArgs: 1
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> ceCall2ArgsPIC [
	<api: 'extern void (*ceCall2ArgsPIC)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceCall2ArgsPIC numArgs: 1
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> ceCallCogCodePopReceiverArg0Regs [
	<api: 'extern void (*ceCallCogCodePopReceiverArg0Regs)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceCallCogCodePopReceiverArg0Regs numArgs: 2
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> ceCallCogCodePopReceiverArg1Arg0Regs [
	<api: 'extern void (*ceCallCogCodePopReceiverArg1Arg0Regs)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceCallCogCodePopReceiverArg1Arg0Regs numArgs: 3
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> ceShortCutTraceStore: aProcessorSimulationTrap [
	<doNotGenerate>
	self shortcutTrampoline: aProcessorSimulationTrap
		to: [coInterpreter
				ceTraceStoreOf: (processor registerAt: TempReg)
				into: (processor registerAt: ReceiverResultReg)]
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileAbstractInstructionsFrom: start through: end [
	"Loop over bytecodes, dispatching to the generator for each bytecode, handling fixups in due course."
	| nextOpcodeIndex descriptor nExts fixup result |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #fixup type: #'BytecodeFixup *'>
	self traceSimStack.
	bytecodePC := start.
	nExts := result := 0.
	descriptor := nil.
	deadCode := false.
	[self cCode: '' inSmalltalk: [self isDebugPC ifTrue: [self halt]].
	 fixup := self fixupAt: bytecodePC - initialPC.
	 self mergeWithFixupIfRequired: fixup.
	 self assertCorrectSimStackPtr.
	 descriptor := self loadBytesAndGetDescriptor.
	 nextOpcodeIndex := opcodeIndex.
	 result := deadCode
				ifTrue: [self mapDeadDescriptorIfNeeded: descriptor]
				ifFalse: [self perform: descriptor generator].
	 self assertExtsAreConsumed: descriptor.
	 self traceDescriptor: descriptor; traceSimStack.
	 self patchFixupTargetIfNeeded: fixup nextOpcodeIndex: nextOpcodeIndex.
	 self maybeDumpLiterals: descriptor.
	 bytecodePC := self nextBytecodePCFor: descriptor exts: nExts.
	 result = 0 and: [bytecodePC <= end]] whileTrue:
		[nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0]].
	self checkEnoughOpcodes.
	^result
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileBlockBodies [
	<inline: false>
	| result compiledBlocksCount blockStart savedNeedsFrame savedNumArgs savedNumTemps
	  initialStackPtr initialOpcodeIndex initialIndexOfIRC |
	<var: #blockStart type: #'BlockStart *'>
	self assert: blockCount > 0.
	"scanBlock: in compileBlockEntry: sets both of these appropriately for each block."
	savedNeedsFrame := needsFrame.
	savedNumArgs := methodOrBlockNumArgs.
	savedNumTemps := methodOrBlockNumTemps.
	inBlock := true.
	compiledBlocksCount := 0.
	[compiledBlocksCount < blockCount] whileTrue:
		[blockStart := self blockStartAt: compiledBlocksCount.
		  (result := self scanBlock: blockStart) < 0 ifTrue: [^result].
		 initialOpcodeIndex := opcodeIndex.
		 literalsManager saveForBlockCompile.
		 NewspeakVM ifTrue:
			[initialIndexOfIRC := indexOfIRC].
		 [self compileBlockEntry: blockStart.
		  initialStackPtr := simStackPtr.
		  (result := self compileAbstractInstructionsFrom: blockStart startpc + (self pushNilSize: methodObj numInitialNils: blockStart numInitialNils)
						through: blockStart startpc + blockStart span - 1) < 0 ifTrue:
			[^result].
		  "If the final simStackPtr is less than the initial simStackPtr then scanBlock: over-
		   estimated the number of initial nils (because it assumed one or more pushNils to
		   produce an operand were pushNils to initialize temps.  This is very rare, so
		   compensate by checking, adjusting numInitialNils and recompiling the block body.
		   N.B.  No need to reinitialize the literalsManager because it answers existing literals."
		  initialStackPtr = simStackPtr]
			whileFalse:
				[self assert: initialStackPtr > simStackPtr.
				 blockStart numInitialNils: blockStart numInitialNils + simStackPtr - initialStackPtr.
				 blockStart fakeHeader dependent: nil.
				 self reinitializeFixupsFrom: blockStart startpc + blockStart numInitialNils
					through: blockStart startpc + blockStart span - 1.
				 self cCode: 'bzero(abstractOpcodes + initialOpcodeIndex,
									(opcodeIndex - initialOpcodeIndex) * sizeof(AbstractInstruction))'
					inSmalltalk: [initialOpcodeIndex to: opcodeIndex - 1 do:
									[:i| abstractOpcodes at: i put: (CogCompilerClass for: self)]].
				 opcodeIndex := initialOpcodeIndex.
				 literalsManager resetForBlockCompile.
				 NewspeakVM ifTrue:
					[indexOfIRC := initialIndexOfIRC]].
		compiledBlocksCount := compiledBlocksCount + 1].
	needsFrame := savedNeedsFrame.
	methodOrBlockNumArgs := savedNumArgs.
	methodOrBlockNumTemps := savedNumTemps.
	^0
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileBlockFrameBuild: blockStart [
	"Build a frame for a block activation.  See CoInterpreter class>>initializeFrameIndices.
	 Override to push the register receiver and register arguments, if any, and to correctly
	 initialize the explicitly nilled/pushed temp entries (they are /not/ of type constant nil)."
	super compileBlockFrameBuild: blockStart.
	methodOrBlockNumTemps := blockStart numArgs + blockStart numCopied + blockStart numInitialNils.
	self initSimStackForFramefulMethod: blockStart startpc.
	blockStart numInitialNils > 0 ifTrue:
		[blockStart numInitialNils > 1
			ifTrue:
				[self genMoveNilR: TempReg.
				 1 to: blockStart numInitialNils do:
					[:ign| self PushR: TempReg]]
			ifFalse:
				[self genPushConstant: objectMemory nilObject].
		 methodOrBlockNumTemps := blockStart numArgs + blockStart numCopied]
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileBlockFramelessEntry: blockStart [
	"Make sure ReceiverResultReg holds the receiver, loaded from
	 the closure, which is what is initially in ReceiverResultReg"
	<var: #blockStart type: #'BlockStart *'>
	methodOrBlockNumTemps := blockStart numArgs + blockStart numCopied + blockStart numInitialNils.
	self initSimStackForFramelessBlock: blockStart startpc.
	super compileBlockFramelessEntry: blockStart
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileCogFullBlockMethod: numCopied [
	<option: #SistaV1BytecodeSet>
	methodOrBlockNumTemps := coInterpreter tempCountOf: methodObj.
	self cCode: '' inSmalltalk:
		[debugStackPointers := coInterpreter debugStackPointersFor: methodObj].
	^super compileCogFullBlockMethod: numCopied
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileCogMethod: selector [
	methodOrBlockNumTemps := coInterpreter tempCountOf: methodObj.
	self cCode: '' inSmalltalk:
		[debugStackPointers := coInterpreter debugStackPointersFor: methodObj].
	^super compileCogMethod: selector
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileEntireMethod [
	"Compile the abstract instructions for the entire method, including blocks."
	regArgsHaveBeenPushed := false.
	^super compileEntireMethod
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileFrameBuild [
	"Build a frame for a CogMethod activation.  See CoInterpreter class>>initializeFrameIndices.
	 Override to push the register receiver and register arguments, if any."
	self cppIf: IMMUTABILITY ifTrue: 
		[useTwoPaths ifTrue: 
			[self compileTwoPathFrameBuild.
		 	^self]].
	needsFrame ifFalse:
		[useTwoPaths ifTrue: 
			[self compileTwoPathFramelessInit].
		 self initSimStackForFramelessMethod: initialPC.
		 ^self].
	self deny: useTwoPaths.
	self genPushRegisterArgs.
	super compileFrameBuild.
	self initSimStackForFramefulMethod: initialPC
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileFullBlockMethodFrameBuild: numCopied [
	<option: #SistaV1BytecodeSet>
	needsFrame ifFalse:
		[self initSimStackForFramelessMethod: initialPC.
		 ^self].
	super compileFullBlockMethodFrameBuild: numCopied.
	self initSimStackForFramefulMethod: initialPC
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileTwoPathFrameBuild [
	"We are in a method where the frame is needed *only* for instance variable store, typically a setter method.
	This case has 20% overhead with Immutability compared to setter without immutability because of the stack
	frame creation. We compile two path, one where the object is immutable, one where it isn't. At the beginning 
	of the frame build, we take one path or the other depending on the receiver mutability.
	
	Note: this specific case happens only where there are only instance variabel stores. We could do something
	similar for literal variable stores, but we don't as it's too uncommon."
	<option: #IMMUTABILITY>
	| jumpImmutable jumpOld |
	self assert: useTwoPaths.
	self assert: blockCount = 0.
	jumpImmutable := objectRepresentation genJumpImmutable: ReceiverResultReg scratchReg: TempReg.
	jumpOld := objectRepresentation genJumpInOldSpace: ReceiverResultReg.
	"first path. The receiver is mutable"
	self assert: needsFrame not.
	self initSimStackForFramelessMethod: initialPC.
	self compileMethodBody.
	"second path. The receiver is mutable"
	useTwoPaths := false. "reset because it impacts inst var store compilation"
	needsFrame := true.
	jumpOld jmpTarget: (jumpImmutable jmpTarget: self Label).
	self genPushRegisterArgs.
	super compileFrameBuild.
	self initSimStackForFramefulMethod: initialPC
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileTwoPathFramelessInit [
	"We are in a frameless method with at least two inst var stores. We compile two paths,
	 one where the object is in new space, and one where it isn't. At the beginning 
	 of the method, we take one path or the other depending on the receiver being in newSpace."
	| jumpOld |
	self deny: IMMUTABILITY.
	self deny: needsFrame.
	self assert: useTwoPaths.
	jumpOld := objectRepresentation genJumpInOldSpace: ReceiverResultReg.
	"first path. The receiver is young"
	self initSimStackForFramelessMethod: initialPC.
	self compileMethodBody.
	"second path. The receiver is old"
	useTwoPaths := false. "reset because it impacts inst var store compilation"
	jumpOld jmpTarget: self Label
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> debugStackPointerFor: bcpc [
	<doNotGenerate>
	^(debugStackPointers at: bcpc) - (needsFrame ifTrue: [1] ifFalse: [0])
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> doubleExtendedDoAnythingBytecode [
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
						ifFalse: [self genPushReceiverVariable: byte2.
								self annotateInstructionForBytecode.
								^0]].
			[3]	->	[self genPushLiteralIndex: byte2.
					 self annotateInstructionForBytecode.
					 ^0].
			[4]	->	[self genPushLiteralVariable: byte2.].
			[7]	->	[self genStorePop: false LiteralVariable: byte2.
					self cppIf: IMMUTABILITY ifTrue: [ "genStorePop:LiteralVariable: annotates; don't annotate twice" ^0 ] ] }
		otherwise: "5 & 6"
			[(coInterpreter isWriteMediatedContextInstVarIndex: byte2)
				ifTrue: [self genStorePop: opType = 6 MaybeContextReceiverVariable: byte2]
				ifFalse: [self genStorePop: opType = 6 ReceiverVariable: byte2].
			self cppIf: IMMUTABILITY ifTrue: [ "genStorePop:LiteralVariable: annotates; don't annotate twice" ^0 ]].
	"We need a map entry for this bytecode for correct parsing (if the method builds a frame)."
	self assert: needsFrame.
	"genPushMaybeContextInstVar, pushListVar, store & storePop all generate code"
	self assert: self prevInstIsPCAnnotated not.
	self annotateBytecode: self Label.
	^0
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> duplicateTopBytecode [
	| desc |
	<var: #desc type: #SimStackEntry>
	desc := self ssTopDescriptor.
	^self ssPushDesc: desc
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> ensureFixupAt: targetIndex [
	"Make sure there's a flagged fixup at the targetIndex (pc relative to first pc) in fixups.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction."
	<returnTypeC: #'BytecodeFixup *'>
	| fixup |
	<var: #fixup type: #'BytecodeFixup *'>
	fixup := self fixupAt: targetIndex.
	self traceFixup: fixup.
	self cCode: '' inSmalltalk:
		[self assert: simStackPtr = (self debugStackPointerFor: targetIndex + initialPC).
		 (fixup isMergeFixupOrIsFixedUp
		  and: [fixup isBackwardBranchFixup not]) ifTrue: "ignore backward branch targets"
			[self assert: fixup simStackPtr = simStackPtr]].
	fixup isNonMergeFixupOrNotAFixup
		ifTrue: "convert a non-merge into a merge"
			[fixup becomeMergeFixup.
			 fixup simStackPtr: simStackPtr]
		ifFalse:
			[fixup isBackwardBranchFixup
				ifTrue: ["this is the target of a backward branch and
						 so doesn't have a simStackPtr assigned yet."
						fixup simStackPtr: simStackPtr]
				ifFalse: [self assert: fixup simStackPtr = simStackPtr]].
	^fixup
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> ensureNonMergeFixupAt: targetIndex [
	"Make sure there's a flagged fixup at the targetIndex (pc relative to first pc) in fixups.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction."
	<returnTypeC: #'BytecodeFixup *'>
	| fixup |
	<var: #fixup type: #'BytecodeFixup *'>
	fixup := self fixupAt: targetIndex.
	fixup notAFixup ifTrue:
		[fixup becomeNonMergeFixup].
	self cCode: '' inSmalltalk:
		[fixup isMergeFixupOrIsFixedUp ifTrue:
			[self assert:
					(fixup isBackwardBranchFixup
					 or: [fixup simStackPtr = (self debugStackPointerFor: targetIndex + initialPC)])]].
	^fixup
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> ensureReceiverResultRegContainsSelf [
	needsFrame
		ifTrue:
			[optStatus isReceiverResultRegLive ifFalse:
				[self ssAllocateRequiredReg: ReceiverResultReg.
				self putSelfInReceiverResultReg ].
			optStatus isReceiverResultRegLive: true]
		ifFalse:
			[self assert: (simSelf type = SSRegister
						  and: [simSelf register = ReceiverResultReg]).
			self assert: (optStatus isReceiverResultRegLive
						  and: [optStatus ssEntry = (self addressOf: simSelf)])]
]

{ #category : #'peephole optimizations' }
StackToRegisterMappingCogit >> evaluate: descriptor at: pc [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	byte0 := objectMemory fetchByte: pc ofObject: methodObj.
	self assert: descriptor = (self generatorAt: bytecodeSetOffset + byte0).
	self loadSubsequentBytesForDescriptor: descriptor at: pc.
	self perform: descriptor generator
]

{ #category : #testing }
StackToRegisterMappingCogit >> extASpecifiesNoMustBeBoolean [
	<inline: true>
	^ extA anyMask: 1
]

{ #category : #testing }
StackToRegisterMappingCogit >> extBSpecifiesImmCheck [ 
	"This is a negative check"
	<inline: true>
	^ extB noMask: 4
]

{ #category : #testing }
StackToRegisterMappingCogit >> extBSpecifiesInitializeInstance [
	"This is a negative; do not intialize if 1 is present in extB.  This is also the no-store-check bit."
	<inline: true>
	^ extB noMask: 1
]

{ #category : #testing }
StackToRegisterMappingCogit >> extBSpecifiesMaybeContext [
	<inline: true>
	^ extB anyMask: 2
]

{ #category : #testing }
StackToRegisterMappingCogit >> extBSpecifiesStoreCheck [ 
	"This is a negative check"
	<inline: true>
	^ extB noMask: 1
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> extractMaybeBranchDescriptorInto: fourArgBlock [
	"Looks one instruction ahead of the current bytecodePC and answers its bytecode descriptor and its pc.
	If the instruction found is a branch, also answers the pc after the branch and the pc targetted by the branch"
	| primDescriptor nextPC nExts branchDescriptor targetBytecodePC postBranchPC |
	<inline: true>
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	
	primDescriptor := self generatorAt: byte0.

	nextPC := bytecodePC + primDescriptor numBytes.
	nExts := 0.
	[branchDescriptor := self generatorAt: (objectMemory fetchByte: nextPC ofObject: methodObj) + bytecodeSetOffset.
	 branchDescriptor isExtension] whileTrue:
		[nExts := nExts + 1.
		 nextPC := nextPC + branchDescriptor numBytes].

	targetBytecodePC := postBranchPC := 0.

	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse]) ifTrue: 
		[ targetBytecodePC := nextPC
							+ branchDescriptor numBytes
							+ (self spanFor: branchDescriptor at: nextPC exts: nExts in: methodObj).
		postBranchPC := nextPC + branchDescriptor numBytes ].
	
	fourArgBlock value: branchDescriptor value: nextPC value: postBranchPC value: targetBytecodePC
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> fixupAt: index [
	<cmacro: '(index) (&fixups[index])'>
	<returnTypeC: #'BytecodeFixup *'>
	(debugFixupBreaks includes: index) ifTrue:
		[self halt].
	^self addressOf: (fixups at: index)
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> freeAnyRegNotConflictingWith: regMask [
	"Spill the closest register on stack not conflicting with regMask. 
	Assertion Failure if regMask has already all the registers"
	<var: #desc type: #'CogSimStackEntry *'>
	| reg index |
	self assert: needsFrame.
	reg := NoReg.
	index := simSpillBase max: 0.
	[reg = NoReg and: [index < simStackPtr]] whileTrue: 
		[ | desc |
		 desc := self simStackAt: index.
		 desc type = SSRegister ifTrue:
			[(regMask anyMask: (self registerMaskFor: desc register)) ifFalse: 
				[reg := desc register]].
		 index := index + 1].
	self deny: reg = NoReg.
	self ssAllocateRequiredReg: reg.
	^reg
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genBlockReturn [
	"Return from block, assuming result already loaded into ReceiverResultReg."
	super genBlockReturn.
	deadCode := true. "can't fall through"
	^0
]

{ #category : #initialization }
StackToRegisterMappingCogit >> genCallPICEnilopmartNumArgs: numArgs [
	"Generate special versions of the ceCallCogCodePopReceiverAndClassRegs
	 enilopmart that also pop register args from the stack to undo the pushing of
	 register args in the abort/miss trampolines."
	<returnTypeC: 'void (*genCallPICEnilopmartNumArgs(sqInt numArgs))(void)'>
	| size endAddress enilopmart |
	self zeroOpcodeIndex.
	backEnd hasVarBaseRegister ifTrue:
		[self MoveCq: self varBaseAddress R: VarBaseReg]. "Must happen first; value may be used in genLoadStackPointers"
	backEnd genLoadStackPointers.
	self PopR: ClassReg. "cacheTag"
	self PopR: TempReg. "entry-point"
	self PopR: (backEnd hasLinkRegister ifTrue: [LinkReg] ifFalse: [SendNumArgsReg]). "retpc"
	numArgs > 0 ifTrue:
		[numArgs > 1 ifTrue:
			[self PopR: Arg1Reg.
			 self assert: self numRegArgs = 2].
		 self PopR: Arg0Reg].
	self PopR: ReceiverResultReg.
	backEnd hasLinkRegister ifFalse: [self PushR: SendNumArgsReg]. "retpc"
	self JumpR: TempReg.
	self computeMaximumSizes.
	size := self generateInstructionsAt: methodZoneBase.
	endAddress := self outputInstructionsAt: methodZoneBase.
	self assert: methodZoneBase + size = endAddress.
	enilopmart := methodZoneBase.
	methodZoneBase := self alignUptoRoutineBoundary: endAddress.
	backEnd stopsFrom: endAddress to: methodZoneBase - 1.
	self recordGeneratedRunTime: (self trampolineName: 'ceCallPIC' numRegArgs: numArgs) address: enilopmart.
	^self cCoerceSimple: enilopmart to: #'void (*)(void)'
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genEqualsEqualsComparisonArgIsConstant: argIsConstant rcvrIsConstant: rcvrIsConstant argReg: argReg rcvrReg: rcvrReg [
	"Generates the Cmp instruction for #==. The instruction is different if one of the operands is a constant.
	In the case of the v3 memory manager, the constant could be annotable." 
	<inline: true>
	argIsConstant 
		ifTrue: [ self genCmpConstant: self ssTop constant R: rcvrReg ]
		ifFalse: [ rcvrIsConstant
			ifTrue: [ self genCmpConstant: (self ssValue: 1) constant R: argReg ]
			ifFalse: [ self CmpR: argReg R: rcvrReg ] ].
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genEqualsEqualsNoBranchArgIsConstant: argIsConstant rcvrIsConstant: rcvrIsConstant argReg: argReg rcvrReg: rcvrRegOrNone [
	"Generates the machine code for #== in the case where the instruction is not followed by a branch"
	| label jumpEqual jumpNotEqual resultReg |
	<var: #label type: #'AbstractInstruction *'>
	<var: #jumpEqual type: #'AbstractInstruction *'>
	<var: #jumpNotEqual type: #'AbstractInstruction *'>
	label := self Label.
	self genEqualsEqualsComparisonArgIsConstant: argIsConstant rcvrIsConstant: rcvrIsConstant argReg: argReg rcvrReg: rcvrRegOrNone.
	self ssPop: 2.
	resultReg := rcvrRegOrNone = NoReg ifTrue: [argReg] ifFalse: [rcvrRegOrNone].
	jumpEqual := self JumpZero: 0.
	 argIsConstant ifFalse:
		[objectRepresentation genEnsureOopInRegNotForwarded: argReg scratchReg: TempReg jumpBackTo: label].
	 rcvrIsConstant ifFalse:
		[objectRepresentation genEnsureOopInRegNotForwarded: rcvrRegOrNone scratchReg: TempReg jumpBackTo: label].
	 self genMoveFalseR: resultReg.
	 jumpNotEqual := self Jump: 0.
	 jumpEqual jmpTarget: (self genMoveTrueR: resultReg).
	 jumpNotEqual jmpTarget: self Label.
	 self ssPushRegister: resultReg.
	 ^0
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genExtPushClosureBytecode [
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
	extA := extB := 0.

	objectRepresentation createsClosuresInline
		ifTrue: [ self genInlineClosure: startpc numArgs: numArgs numCopied: numCopied ]
		ifFalse: [ self genOutlineClosure: startpc numArgs: numArgs numCopied: numCopied ].
		
	^ 0
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genExtPushFullClosureBytecode [
	"Full Block creation compilation. The block's actual code will be compiled separatedly."
	"*	255		11111111	xxxxxxxx	siyyyyyy	push Closure Compiled block literal index xxxxxxxx (+ Extend A * 256) numCopied yyyyyy receiverOnStack: s = 1 ignoreOuterContext: i = 1"
	| numCopied ignoreContext receiverIsOnStack compiledBlock reg |
	self assert: needsFrame.
	compiledBlock := self getLiteral: byte1 + (extA << 8).
	extA := 0.
	numCopied := byte2 bitAnd: 1<< 6 - 1.
	receiverIsOnStack := byte2 anyMask: 1 << 7.
	ignoreContext := byte2 anyMask: 1 << 6.
	optStatus isReceiverResultRegLive: false.
	self ssAllocateCallReg: ReceiverResultReg
		and: SendNumArgsReg
		and: ClassReg.
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
		reg := self ssStorePop: true toPreferredReg: TempReg.
		 objectRepresentation
			genStoreSourceReg: reg
			slotIndex: FullClosureFirstCopiedValueIndex + numCopied - i
			intoNewObjectInDestReg: ReceiverResultReg].
	receiverIsOnStack
		ifTrue: [reg := self ssStorePop: true toPreferredReg: TempReg]
		ifFalse: [(self addressOf: simSelf) storeToReg: (reg := TempReg)].
	objectRepresentation
			genStoreSourceReg: reg
			slotIndex: FullClosureReceiverIndex
			intoNewObjectInDestReg: ReceiverResultReg.
	self ssPushRegister: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genExtPushRemoteTempOrInstVarLongBytecode [
	| index maybeContext |
	^ (byte2 noMask: coInterpreter remoteIsInstVarAccess)
		ifTrue: [ self genPushRemoteTempLongBytecode ]
		ifFalse: 
			[ maybeContext := self extBSpecifiesMaybeContext.
			index := byte1 + (extA << 8).
			extA := 0.
			extB := 0.
			((coInterpreter isReadMediatedContextInstVarIndex: index) and: [ maybeContext ])
				ifTrue: [ self genPushMaybeContextRemoteInstVar: index inObjectAt: byte2 - coInterpreter remoteIsInstVarAccess ]
				ifFalse: [ self genPushRemoteInstVar: index inObjectAt: byte2 - coInterpreter remoteIsInstVarAccess ] ]
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genExtStorePopRemoteTempOrInstVarLongBytecodePopBoolean: boolean [
	| index maybeContext needsStoreCheck needsImmCheck |
	needsStoreCheck := self sistaNeedsStoreCheck.
	maybeContext := self extBSpecifiesMaybeContext.
	needsImmCheck := self extBSpecifiesImmCheck.
	extB := 0.
	(byte2 noMask: coInterpreter remoteIsInstVarAccess)
		ifTrue: 
			[ self 
				genStorePop: boolean 
				RemoteTemp: byte1 
				At: byte2 
				needsStoreCheck: needsStoreCheck.
			self cppIf: IMMUTABILITY ifTrue: [ self annotateBytecode: self Label ] ]
		ifFalse: 
			[index := byte1 + (extA << 8).
			 extA := 0.
			 ((coInterpreter isWriteMediatedContextInstVarIndex: index) and: [ maybeContext ])
				ifTrue: [self 
						genStorePop: boolean 
						MaybeContextRemoteInstVar: index 
						ofObjectAt: byte2 - coInterpreter remoteIsInstVarAccess 
						needsStoreCheck: needsStoreCheck
						needsImmutabilityCheck: needsImmCheck ]
				ifFalse: [self 
						genStorePop: boolean 
						RemoteInstVar: index 
						ofObjectAt: byte2 - coInterpreter remoteIsInstVarAccess 
						needsStoreCheck: needsStoreCheck
						needsImmutabilityCheck: needsImmCheck ] ].
	^ 0
]

{ #category : #'trampoline support' }
StackToRegisterMappingCogit >> genExternalizePointersForPrimitiveCall [
	" Override to push the register receiver and register arguments, if any."
	self genPushRegisterArgs.
	^super genExternalizePointersForPrimitiveCall
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genGenericStorePop: popBoolean MaybeContextSlotIndex: slotIndex needsStoreCheck: needsStoreCheck needsRestoreRcvr: needsRestoreReceiver needsImmutabilityCheck: needsImmCheck [
	"Generates a store into an object that *may* be a context.
	Multiple settings:
	- needsStoreCheck (young into old object check)
	- needRestoreRcvr (ensures the recevier is live across the store)
	- needsImmCheck (do the call-back if the receiver is immutable)"
	<inline: true>
	| jmpSingle jmpDone |
	<var: #jmpSingle type: #'AbstractInstruction *'>
	<var: #jmpDone type: #'AbstractInstruction *'>
	"The reason we need a frame here is that assigning to an inst var of a context may
	 involve wholesale reorganization of stack pages, and the only way to preserve the
	 execution state of an activation in that case is if it has a frame."
	"Context stores do not require Imm checks as contexts can't be immutable"
	self assert: needsFrame.
	self ssPop: 1.
	self ssAllocateCallReg: ClassReg and: SendNumArgsReg. "for ceStoreContextInstVarTrampoline"
	self ssPush: 1.
	objectRepresentation
		genLoadSlot: SenderIndex
		sourceReg: ReceiverResultReg
		destReg: TempReg.
	self ssStoreAndReplacePop: popBoolean toReg: ClassReg.
	jmpSingle := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	self MoveCq: slotIndex R: SendNumArgsReg.
	self CallRT: ceStoreContextInstVarTrampoline.
	jmpDone := self Jump: 0.
	jmpSingle jmpTarget: self Label.
	self 
		cppIf: IMMUTABILITY
		ifTrue:
			[needsImmCheck
				ifTrue: 
					[objectRepresentation 
						genStoreWithImmutabilityCheckSourceReg: ClassReg 
						slotIndex: slotIndex 
						destReg: ReceiverResultReg 
						scratchReg: TempReg 
						needsStoreCheck: needsStoreCheck 
						needRestoreRcvr: needsRestoreReceiver.
					jmpDone jmpTarget: self Label.
					^0]].
	objectRepresentation
			genStoreSourceReg: ClassReg
			slotIndex: slotIndex
			destReg: ReceiverResultReg
			scratchReg: TempReg
			inFrame: true
			needsStoreCheck: needsStoreCheck.
	jmpDone jmpTarget: self Label.
	^0
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genGenericStorePop: popBoolean slotIndex: slotIndex destReg: destReg needsStoreCheck: needsStoreCheck needsRestoreRcvr: needsRestoreReceiver needsImmutabilityCheck: needsImmCheck [
	"Generates a store into an object that *cannot* be a context.
	 This code is common between multiple stores (litVar, instVar, remoteInstVar, RemoteTemp)
	 Multiple settings:
	- needsStoreCheck (young into old object check)
	- needRestoreRcvr (ensures the receiver is live across the store)
	- needsImmCheck (do the call-back if the receiver is immutable)"
	<inline: true>
	"We have two very different paths as only the immutability path requires a specific register 
	for the value on top of stack as well as the stack flush"
	| topReg |
	self 
		cppIf: IMMUTABILITY
		ifTrue:
			[needsImmCheck
				ifTrue: 
					[self ssAllocateRequiredReg: ClassReg.
					 "we replace the top value for the flush"
					 self ssStoreAndReplacePop: popBoolean toReg: ClassReg.
					 self ssFlushTo: simStackPtr.
					 ^objectRepresentation 
						genStoreWithImmutabilityCheckSourceReg: ClassReg 
						slotIndex: slotIndex 
						destReg: destReg 
						scratchReg: TempReg 
						needsStoreCheck: needsStoreCheck 
						needRestoreRcvr: needsRestoreReceiver]].
		 topReg := self 
					allocateRegForStackEntryAt: 0 
					notConflictingWith: (self registerMaskFor: destReg). 
		 self ssStorePop: popBoolean toReg: topReg.
		 ^objectRepresentation
			genStoreSourceReg: topReg
			slotIndex: slotIndex
			destReg: destReg
			scratchReg: TempReg
			inFrame: needsFrame
			needsStoreCheck: needsStoreCheck
	
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genInlineClosure: startpc numArgs: numArgs numCopied: numCopied [
	<inline: true>
	self assert: objectRepresentation getActiveContextAllocatesInMachineCode.
	 optStatus isReceiverResultRegLive: false.
	 self ssAllocateCallReg: ReceiverResultReg
		and: SendNumArgsReg
		and: ClassReg.
	 objectRepresentation
		genNoPopCreateClosureAt: startpc + 1 "1 relative"
		numArgs: numArgs
		numCopied: numCopied
		contextNumArgs: methodOrBlockNumArgs
		large: (coInterpreter methodNeedsLargeContext: methodObj)
		inBlock: inBlock.
	 1 to: numCopied do:
		[:i| | reg |
		 reg := self ssStorePop: true toPreferredReg: TempReg.
		 objectRepresentation
			genStoreSourceReg: reg
			slotIndex: ClosureFirstCopiedValueIndex + numCopied - i
			intoNewObjectInDestReg: ReceiverResultReg].
	 self ssPushRegister: ReceiverResultReg

]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genJumpBackTo: targetBytecodePC [
	self ssFlushTo: simStackPtr.
	deadCode := true. "can't fall through"
	^super genJumpBackTo: targetBytecodePC
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genJumpIf: boolean to: targetBytecodePC [
	<inline: false>
	| desc fixup ok |
	<var: #desc type: #'CogSimStackEntry *'>
	<var: #fixup type: #'BytecodeFixup *'>
	<var: #ok type: #'AbstractInstruction *'>
	self ssFlushTo: simStackPtr - 1.
	desc := self ssTop.
	self ssPop: 1.
	(desc type == SSConstant
	 and: [desc constant = objectMemory trueObject or: [desc constant = objectMemory falseObject]]) ifTrue:
		["Must arrange there's a fixup at the target whether it is jumped to or
		  not so that the simStackPtr can be kept correct."
		 fixup := self ensureFixupAt: targetBytecodePC - initialPC.
		 "Must annotate the bytecode for correct pc mapping."
		 self annotateBytecode: (desc constant = boolean
									ifTrue: [self Jump: fixup]
									ifFalse: [self prevInstIsPCAnnotated
												ifTrue: [self Nop]
												ifFalse: [self Label]]).
		 extA := 0.
		 ^0].
	desc popToReg: TempReg.
	"Cunning trick by LPD.  If true and false are contiguous subtract the smaller.
	 Correct result is either 0 or the distance between them.  If result is not 0 or
	 their distance send mustBeBoolean."
	self assert: (objectMemory objectAfter: objectMemory falseObject) = objectMemory trueObject.
	self genSubConstant: boolean R: TempReg.
	self JumpZero: (self ensureFixupAt: targetBytecodePC - initialPC).
	
	self extASpecifiesNoMustBeBoolean ifTrue: 
		[ extA := 0. 
		self annotateBytecode: self lastOpcode.
		^ 0].
	extA := 0.
	
.	self CmpCq: (boolean == objectMemory falseObject
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

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genJumpTo: targetBytecodePC [
	self ssFlushTo: simStackPtr.
	deadCode := true. "can't fall through"
	^super genJumpTo: targetBytecodePC
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genLoadArgAtDepth: n into: reg [
	"All machine code primitives apart from perform: have only
	 register arguments, hence no arg load code is necessary."
	<inline: true>
	self assert: n < objectRepresentation numRegArgs
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genLoadLiteralVariable: litVarIndex in: destReg [
	<inline: true>
	| association |
	association := self getLiteral: litVarIndex.
	destReg = ReceiverResultReg ifTrue: [ optStatus isReceiverResultRegLive: false ].
	self ssAllocateRequiredReg: destReg.
	self genMoveConstant: association R: destReg.
	objectRepresentation genEnsureObjInRegNotForwarded: destReg scratchReg: TempReg.
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genLoadTemp: objectIndex in: destReg [
	destReg = ReceiverResultReg ifTrue: [ optStatus isReceiverResultRegLive: false ].
	self ssAllocateRequiredReg: destReg. 
	self MoveMw: (self frameOffsetOfTemporary: objectIndex) r: FPReg R: destReg.
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genMarshalledSend: selectorIndex numArgs: numArgs sendTable: sendTable [
	<inline: false>
	<var: #sendTable type: #'sqInt *'>
	| annotation |
	self assert: needsFrame.
	annotation := self annotationForSendTable: sendTable.
	"Deal with stale super sends; see SpurMemoryManager's class comment."
	(self annotationIsForUncheckedEntryPoint: annotation) ifTrue:
		[objectRepresentation genEnsureOopInRegNotForwarded: ReceiverResultReg scratchReg: TempReg].
	"0 through (NumSendTrampolines - 2) numArgs sends have the arg count implciti in the trampoline.
	 The last send trampoline (NumSendTrampolines - 1) passes numArgs in SendNumArgsReg."
	numArgs >= (NumSendTrampolines - 1) ifTrue:
		[self MoveCq: numArgs R: SendNumArgsReg].
	(BytecodeSetHasDirectedSuperSend
	 and: [annotation = IsDirectedSuperSend]) ifTrue:
		[self genMoveConstant: tempOop R: TempReg].
	self genLoadInlineCacheWithSelector: selectorIndex.
	(self Call: (sendTable at: (numArgs min: NumSendTrampolines - 1))) annotation: annotation.
	optStatus isReceiverResultRegLive: false.
	^self ssPushRegister: ReceiverResultReg
]

{ #category : #initialization }
StackToRegisterMappingCogit >> genMethodAbortTrampolineFor: numArgs [
	"Generate the abort for a method.  This abort performs either a call of ceSICMiss:
	 to handle a single-in-line cache miss or a call of ceStackOverflow: to handle a
	 stack overflow.  It distinguishes the two by testing ResultReceiverReg.  If the
	 register is zero then this is a stack-overflow because a) the receiver has already
	 been pushed and so can be set to zero before calling the abort, and b) the
	 receiver must always contain an object (and hence be non-zero) on SIC miss."
	| jumpSICMiss |
	<var: #jumpSICMiss type: #'AbstractInstruction *'>
	self zeroOpcodeIndex.
	self CmpCq: 0 R: ReceiverResultReg.
	jumpSICMiss := self JumpNonZero: 0.

	"The abort sequence has pushed the LinkReg a second time - because a stack
	 overflow can only happen after building a frame, which pushes LinkReg anyway, and
	 we still need to push LinkReg in case we get to this routine from a sendMissAbort.
	 (On ARM there is a simpler way; use two separate abort calls since all instructions are 32-bits
	  but on x86 the zero receiver reg, call methodAbort sequence is smaller; we may fix this one day).
	 Overwrite that duplicate with the right one - the return address for the call to the abort trampoline.
	 The only reason it matters is an assert in ceStackOverflow: uses it"
	backEnd hasLinkRegister ifTrue:
		[self MoveR: LinkReg Mw: 0 r: SPReg].
	self compileTrampolineFor: #ceStackOverflow:
		numArgs: 1
		arg: SendNumArgsReg
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: false "The LinkReg has already been set above."
		resultReg: NoReg.
	jumpSICMiss jmpTarget: self Label.
	backEnd genPushRegisterArgsForAbortMissNumArgs: numArgs.
	^self genTrampolineFor: #ceSICMiss:
		called: (self trampolineName: 'ceMethodAbort' numRegArgs: numArgs)
		numArgs: 1
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: false "The LinkReg will have been pushed in genPushRegisterArgsForAbortMissNumArgs: above."
		resultReg: NoReg
		appendOpcodes: true
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genNSSend: selectorIndex numArgs: numArgs depth: depth sendTable: sendTable [
	<var: #sendTable type: #'sqInt *'>
	| selector nsSendCache |
	self assert: (selectorIndex between: 0 and: (objectMemory literalCountOf: methodObj) - 1).
	selector := self getLiteral: selectorIndex.
	self assert: (objectMemory addressCouldBeOop: selector).	
	(objectMemory isYoung: selector) ifTrue:
		[hasYoungReferent := true].

	nsSendCache := theIRCs + (NumOopsPerNSC * objectMemory bytesPerOop * indexOfIRC).
	indexOfIRC := indexOfIRC + 1.
	self assert: (objectMemory isInOldSpace: nsSendCache).
	self initializeNSSendCache: nsSendCache selector: selector numArgs: numArgs depth: depth.

	self ssAllocateCallReg: SendNumArgsReg.

	"This may leave the method receiver on the stack, which might not be the implicit receiver.
	 But the lookup trampoline will establish an on-stack receiver once it locates it."
	self marshallAbsentReceiverSendArguments: numArgs.

	"Load the cache last so it is a fixed distance from the call."
	self MoveUniqueCw: nsSendCache R: SendNumArgsReg.
	self CallNewspeakSend: (sendTable at: (numArgs min: NumSendTrampolines - 1)).

	optStatus isReceiverResultRegLive: false.
	self ssPushRegister: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genOutlineClosure: startpc numArgs: numArgs numCopied: numCopied [
	<inline: true>
	numCopied > 0 ifTrue:
		[self ssFlushTo: simStackPtr].
	optStatus isReceiverResultRegLive: false.
	objectRepresentation getActiveContextAllocatesInMachineCode
		ifTrue: [self ssAllocateCallReg: ReceiverResultReg
					and: SendNumArgsReg
					and: ClassReg]
		ifFalse: [self ssAllocateCallReg: SendNumArgsReg
					and: ReceiverResultReg].
	objectRepresentation
		genCreateClosureAt: startpc + 1 "1 relative"
		numArgs: numArgs
		numCopied: numCopied
		contextNumArgs: methodOrBlockNumArgs
		large: (coInterpreter methodNeedsLargeContext: methodObj)
		inBlock: inBlock.
	numCopied > 0 ifTrue:
		[self ssPop: numCopied].
	self ssPushRegister: ReceiverResultReg

]

{ #category : #initialization }
StackToRegisterMappingCogit >> genPICAbortTrampolineFor: numArgs [
	"Generate the abort for a PIC.  This abort performs either a call of
	 ceInterpretMethodFromPIC:receiver: to handle invoking an uncogged
	 target or a call of ceMNUFromPICMNUMethod:receiver: to handle an
	 MNU dispatch in a closed PIC.  It distinguishes the two by testing
	 ClassReg.  If the register is zero then this is an MNU."
	self zeroOpcodeIndex. 
	backEnd genPushRegisterArgsForAbortMissNumArgs: numArgs.
	^self genInnerPICAbortTrampoline: (self trampolineName: 'cePICAbort' numRegArgs: numArgs)
]

{ #category : #initialization }
StackToRegisterMappingCogit >> genPICMissTrampolineFor: numArgs [
	<inline: false>
	| startAddress |
	startAddress := methodZoneBase.
	self zeroOpcodeIndex.
	"N.B. a closed PIC jumps to the miss routine, not calls it, so there is only one retpc on the stack."
	backEnd genPushRegisterArgsForNumArgs: numArgs scratchReg: SendNumArgsReg.
	self genTrampolineFor: #ceCPICMiss:receiver:
		called: (self trampolineName: 'cePICMiss' numRegArgs: numArgs)
		numArgs: 2
		arg: ClassReg
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: true.
	^startAddress
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPopStackBytecode [
	self ssTop spilled ifTrue:
		[self AddCq: objectMemory wordSize R: SPReg].
	self ssPop: 1.
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimReturn [
	"Generate a return that cuts back the stack to remove the receiver
	 and arguments after an invocation of a primitive with nargs arguments.
	 Since all primitives that succeed in the normal way (i.e. don't execute a
	 method as do genPrimitiveClosureValue and genPrimitivePerform) take only
	 register arguments, there is nothing to do."
	<inline: true>
	self assert: methodOrBlockNumArgs <= self numRegArgs.
	^self RetN: 0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveClosureValue [
	"Check the argument count.  Fail if wrong.
	 Get the method from the outerContext and see if it is cogged.  If so, jump to the
	 block entry or the no-context-switch entry, as appropriate, and we're done.  If not,
	 invoke the interpreter primitive.
	 Override to push the register args first."
	self genPushRegisterArgs.
	^super genPrimitiveClosureValue
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveFullClosureValue [
	"Override to push the register args first."
	<option: #SistaV1BytecodeSet>
	self genPushRegisterArgs.
	^super genPrimitiveFullClosureValue
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitivePerform [
	"Generate an in-line perform primitive.  The lookup code requires the selector to be in Arg0Reg.
	 adjustArgumentsForPerform: adjusts the arguments once genLookupForPerformNumArgs:
	 has generated the code for the lookup."
	methodOrBlockNumArgs > self numRegArgs ifTrue:
		[self MoveMw: (backEnd hasLinkRegister
					ifTrue: [methodOrBlockNumArgs - 1]
					ifFalse: [methodOrBlockNumArgs]) * objectMemory wordSize
			r: SPReg
			R: Arg0Reg].
	^self genLookupForPerformNumArgs: methodOrBlockNumArgs
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPushActiveContextBytecode [
	self assert: needsFrame.
	optStatus isReceiverResultRegLive: false.
	objectRepresentation getActiveContextAllocatesInMachineCode
		ifTrue: [self ssAllocateCallReg: ReceiverResultReg
					and: SendNumArgsReg
					and: ClassReg]
		ifFalse: [self ssAllocateCallReg: ReceiverResultReg].
	objectRepresentation
		genGetActiveContextNumArgs: methodOrBlockNumArgs
		large: (coInterpreter methodNeedsLargeContext: methodObj)
		inBlock: inBlock.
	^self ssPushRegister: ReceiverResultReg
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPushClosureCopyCopiedValuesBytecode [
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

	objectRepresentation createsClosuresInline 
		ifTrue: [ self genInlineClosure: startpc numArgs: numArgs numCopied: numCopied ]
		ifFalse: [ self genOutlineClosure: startpc numArgs: numArgs numCopied: numCopied ].
		
	^ 0

	
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genPushEnclosingObjectAt: level [
	"Uncached push enclosing object"
	optStatus isReceiverResultRegLive: false.
	self ssAllocateCallReg: SendNumArgsReg and: ReceiverResultReg.
	self MoveCq: level R: SendNumArgsReg.
	self CallRT: ceEnclosingObjectTrampoline.
	^self ssPushRegister: ReceiverResultReg
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genPushLiteral: literal [
	^self ssPushConstant: literal
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genPushLiteralVariable: literalIndex [
	<inline: false>
	| association freeReg |
	freeReg := self allocateRegNotConflictingWith: 0.
	association := self getLiteral: literalIndex.
	"N.B. Do _not_ use ReceiverResultReg to avoid overwriting receiver in assignment in frameless methods."
	"So far descriptors are not rich enough to describe the entire dereference so generate the register
	 load but don't push the result.  There is an order-of-evaluation issue if we defer the dereference."
	self genMoveConstant: association R: TempReg.
	objectRepresentation
		genEnsureObjInRegNotForwarded: TempReg
		scratchReg: freeReg.
	objectRepresentation
		genLoadSlot: ValueIndex
		sourceReg: TempReg
		destReg: freeReg.
	self ssPushRegister: freeReg.
	^0
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genPushLiteralVariableGivenDirectedSuper: literalIndex [
	"This is a version of genPushLiteralVariable: that looks ahead for a directed super send bytecode
	 and does not generate any code for the dereference yet if followed by a directed super send."
	<inline: false>
	self nextDescriptorAndExtensionsInto:
		[:descriptor :exta :extb|
		(self isDirectedSuper: descriptor extA: exta extB: extb) ifTrue:
			[self ssPushConstant: (self getLiteral: literalIndex).
			 ^0]].
	^self genPushLiteralVariable: literalIndex
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genPushMaybeContextReceiverVariable: slotIndex [ 
	<inline: false>
	self ssAllocateCallReg: ReceiverResultReg and: SendNumArgsReg.
	self ensureReceiverResultRegContainsSelf.
	^ self genPushMaybeContextSlotIndex: slotIndex
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genPushMaybeContextRemoteInstVar: slotIndex inObjectAt: index [
	<inline: false>
	self ssAllocateCallReg: ReceiverResultReg and: SendNumArgsReg.
	self genLoadTemp: index in: ReceiverResultReg.
	^ self genPushMaybeContextSlotIndex: slotIndex
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genPushMaybeContextSlotIndex: slotIndex [
	<inline: true>
	"This method expects ReceiverResultReg to hold the object read"
	| jmpSingle jmpDone |
	<var: #jmpSingle type: #'AbstractInstruction *'>
	<var: #jmpDone type: #'AbstractInstruction *'>
	self assert: needsFrame.
	(self isCallerSavedReg: ReceiverResultReg) ifTrue:
		["We have no way of reloading ReceiverResultReg since we need the inst var value as the result."
		optStatus isReceiverResultRegLive: false].
	"See CoInterpreter>>contextInstructionPointer:frame: for an explanation
	 of the instruction pointer slot handling."
	slotIndex = InstructionPointerIndex ifTrue:
		[self MoveCq: slotIndex R: SendNumArgsReg.
		 self CallRT: ceFetchContextInstVarTrampoline.
		 ^self ssPushRegister: SendNumArgsReg].
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
	jmpDone jmpTarget: self Label.
	^self ssPushRegister: SendNumArgsReg
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPushNewArrayBytecode [
	| size popValues |
	self assert: needsFrame.
	optStatus isReceiverResultRegLive: false.
	(popValues := byte1 > 127)
		ifTrue: [self ssFlushTo: simStackPtr]
		ifFalse: [self ssAllocateCallReg: SendNumArgsReg and: ReceiverResultReg].
	size := byte1 bitAnd: 127.
	popValues ifFalse:
		[(self tryCollapseTempVectorInitializationOfSize: size) ifTrue:
			[^0]].
	objectRepresentation genNewArrayOfSize: size initialized: popValues not.
	popValues ifTrue:
		[size - 1 to: 0 by: -1 do:
			[:i|
			self PopR: TempReg.
			objectRepresentation
				genStoreSourceReg: TempReg
				slotIndex: i
				intoNewObjectInDestReg: ReceiverResultReg].
		 self ssPop: size].
	^self ssPushRegister: ReceiverResultReg
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPushReceiverBytecode [
	optStatus isReceiverResultRegLive ifTrue:
		[^self ssPushRegister: ReceiverResultReg].
	^self ssPushDesc: simSelf
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genPushReceiverVariable: index [
	<inline: false>
	self ensureReceiverResultRegContainsSelf.
	^self ssPushBase: ReceiverResultReg
			offset: (objectRepresentation slotOffsetOfInstVarIndex: index)
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> genPushRegisterArgs [
	"Ensure that the register args are pushed before the retpc for methods with arity <= self numRegArgs."
	"This won't be as clumsy on a RISC.  But putting the receiver and
	 args above the return address means the CoInterpreter has a
	 single machine-code frame format which saves us a lot of work."
	(regArgsHaveBeenPushed
	 or: [methodOrBlockNumArgs > self numRegArgs]) ifFalse:
		[backEnd genPushRegisterArgsForNumArgs: methodOrBlockNumArgs scratchReg: SendNumArgsReg.
		regArgsHaveBeenPushed := true]
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genPushRemoteInstVar: index inObjectAt: objectIndex [
	<inline: false>
	| objectReg resultReg |
	self assert: needsFrame.
	objectReg := self allocateRegNotConflictingWith: 0.
	self genLoadTemp: objectIndex in: objectReg.
	resultReg := self availableRegOrNoneNotConflictingWith: (self registerMaskFor: objectReg). 
	resultReg = NoReg ifTrue: [resultReg := objectReg].
	objectRepresentation
		genLoadSlot: byte1
		sourceReg: objectReg
		destReg: resultReg.
	^self ssPushRegister: resultReg
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPushRemoteTempLongBytecode [
	| tempVectReg remoteTempReg |
	tempVectReg := self allocateRegNotConflictingWith: 0.
	self MoveMw: (self frameOffsetOfTemporary: byte2) r: FPReg R: tempVectReg.
	remoteTempReg := self availableRegOrNoneNotConflictingWith: (self registerMaskFor: tempVectReg). 
	remoteTempReg = NoReg ifTrue: [remoteTempReg := tempVectReg].
	objectRepresentation
		genLoadSlot: byte1
		sourceReg: tempVectReg
		destReg: remoteTempReg.
	^self ssPushRegister: remoteTempReg
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genPushTemporaryVariable: index [
	"If a frameless method (not a block), only argument temps can be accessed.
	 This is assured by the use of needsFrameIfMod16GENumArgs: in pushTemp."
	self assert: (inBlock or: [needsFrame or: [index < methodOrBlockNumArgs]]).
	^self ssPushDesc: (simStack at: index)
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genReturnReceiver [
	"In a frameless method ReceiverResultReg already contains self.
	 In a frameful method, ReceiverResultReg /may/ contain self."
	needsFrame ifTrue:
		[ optStatus isReceiverResultRegLive ifFalse:
			[self putSelfInReceiverResultReg]].
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genReturnTopFromBlock [
	self assert: inBlock.
	self ssTop popToReg: ReceiverResultReg.
	self ssPop: 1.
	^self genBlockReturn
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genReturnTopFromMethod [
	self ssTop popToReg: ReceiverResultReg.
	self ssPop: 1.
	^self genUpArrowReturn
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genSend: selectorIndex numArgs: numArgs [
	self marshallSendArguments: numArgs.
	^self genMarshalledSend: selectorIndex numArgs: numArgs sendTable: ordinarySendTrampolines
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genSendDirectedSuper: selectorIndex numArgs: numArgs [
	self assert: self ssTop type = SSConstant.
	tempOop := self ssTop constant.
	self ssPop: 1.
	self marshallSendArguments: numArgs.
	^self genMarshalledSend: selectorIndex numArgs: numArgs sendTable: directedSuperSendTrampolines
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genSendDynamicSuper: selectorIndex numArgs: numArgs [
	self marshallSendArguments: numArgs.
	^self genMarshalledSend: selectorIndex numArgs: numArgs sendTable: dynamicSuperSendTrampolines
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genSendSuper: selectorIndex numArgs: numArgs [
	self marshallSendArguments: numArgs.
	^self genMarshalledSend: selectorIndex numArgs: numArgs sendTable: superSendTrampolines
]

{ #category : #initialization }
StackToRegisterMappingCogit >> genSendTrampolineFor: aRoutine numArgs: numArgs called: aString arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 [
	"Generate a trampoline with four arguments.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	| startAddress |
	<inline: false>
	startAddress := methodZoneBase.
	self zeroOpcodeIndex.
	backEnd genPushRegisterArgsForNumArgs: numArgs scratchReg: SendNumArgsReg.
	objectRepresentation selectorIndexDereferenceRoutine ifNotNil:
		[:routine| self Call: routine].
	self genTrampolineFor: aRoutine
		called: aString
		numArgs: 4
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: regOrConst3
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: true.
	^startAddress
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSistaExtStoreAndPopReceiverVariableBytecodePopBoolean: boolean [
	<inline: true>
	| index needsStoreCheck needsImmCheck |
	needsStoreCheck := self sistaNeedsStoreCheck.
	needsImmCheck := self extBSpecifiesImmCheck.
	extB := 0.
	index := byte1 + (extA << 8).
	extA := 0.
	^(coInterpreter isWriteMediatedContextInstVarIndex: index)
		ifTrue: [self 
				genStorePop: boolean 
				MaybeContextReceiverVariable: index 
				needsStoreCheck: needsStoreCheck 
				needsImmutabilityCheck: needsImmCheck]
		ifFalse: [self 
				 genStorePop: boolean 
				 ReceiverVariable: index 
				 needsStoreCheck: needsStoreCheck 
				 needsImmutabilityCheck: needsImmCheck]
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSistaExtStoreLiteralVariableBytecodePopBoolean: boolean [
	<inline: true>
	| index needsStoreCheck needsImmCheck |
	needsStoreCheck := self sistaNeedsStoreCheck.
	needsImmCheck := self extBSpecifiesImmCheck.
	index := byte1 + (extA << 8).
	extA := extB := 0.
	^self 
		genStorePop: boolean 
		LiteralVariable: index 
		needsStoreCheck: needsStoreCheck 
		needsImmutabilityCheck: needsImmCheck
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSpecialSelectorArithmetic [
	| primDescriptor rcvrIsConst argIsConst rcvrIsInt argIsInt rcvrInt argInt result
	 jumpNotSmallInts jumpContinue index |
	<var: #jumpContinue type: #'AbstractInstruction *'>
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpNotSmallInts type: #'AbstractInstruction *'>
	primDescriptor := self generatorAt: byte0.
	argIsInt := (argIsConst := self ssTop type = SSConstant)
				 and: [objectMemory isIntegerObject: (argInt := self ssTop constant)].
	rcvrIsInt := (rcvrIsConst := (self ssValue: 1) type = SSConstant)
				 and: [objectMemory isIntegerObject: (rcvrInt := (self ssValue: 1) constant)].

	(argIsInt and: [rcvrIsInt]) ifTrue:
		[rcvrInt := objectMemory integerValueOf: rcvrInt.
		 argInt := objectMemory integerValueOf: argInt.
		 primDescriptor opcode caseOf: {
			[AddRR]	-> [result := rcvrInt + argInt].
			[SubRR]	-> [result := rcvrInt - argInt].
			[AndRR]	-> [result := rcvrInt bitAnd: argInt].
			[OrRR]	-> [result := rcvrInt bitOr: argInt] }.
		(objectMemory isIntegerValue: result) ifTrue:
			["Must annotate the bytecode for correct pc mapping."
			^self ssPop: 2; ssPushAnnotatedConstant: (objectMemory integerObjectOf: result)].
		^self genSpecialSelectorSend].

	"If there's any constant involved other than a SmallInteger don't attempt to inline."
	((rcvrIsConst and: [rcvrIsInt not])
	 or: [argIsConst and: [argIsInt not]]) ifTrue:
		[^self genSpecialSelectorSend].

	"If we know nothing about the types then better not to inline as the inline cache and
	 primitive code is not terribly slow so wasting time on duplicating tag tests is pointless."
	(argIsInt or: [rcvrIsInt]) ifFalse:
		[^self genSpecialSelectorSend].

	argIsInt
		ifTrue:
			[self ssFlushTo: simStackPtr - 2.
			 (self ssValue: 1) popToReg: ReceiverResultReg.
			 self ssPop: 2.
			 self MoveR: ReceiverResultReg R: TempReg]
		ifFalse:
			[self marshallSendArguments: 1.
			 self MoveR: Arg0Reg R: TempReg].
	jumpNotSmallInts := (argIsInt or: [rcvrIsInt])
							ifTrue: [objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg]
							ifFalse: [objectRepresentation genJumpNotSmallIntegersIn: ReceiverResultReg andScratch: TempReg scratch: ClassReg].
	primDescriptor opcode caseOf: {
		[AddRR] -> [argIsInt
						ifTrue:
							[self AddCq: argInt - ConstZero R: ReceiverResultReg.
							 jumpContinue := self JumpNoOverflow: 0.
							 "overflow; must undo the damage before continuing"
							 self SubCq: argInt - ConstZero R: ReceiverResultReg]
						ifFalse:
							[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: ReceiverResultReg.
							 self AddR: Arg0Reg R: ReceiverResultReg.
							jumpContinue := self JumpNoOverflow: 0.
							"overflow; must undo the damage before continuing"
							 rcvrIsInt
								ifTrue: [self MoveCq: rcvrInt R: ReceiverResultReg]
								ifFalse:
									[self SubR: Arg0Reg R: ReceiverResultReg.
									 objectRepresentation genSetSmallIntegerTagsIn: ReceiverResultReg]]].
		[SubRR] -> [argIsInt
						ifTrue:
							[self SubCq: argInt - ConstZero R: ReceiverResultReg.
							 jumpContinue := self JumpNoOverflow: 0.
							 "overflow; must undo the damage before continuing"
							 self AddCq: argInt - ConstZero R: ReceiverResultReg]
						ifFalse:
							[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: Arg0Reg.
							 self SubR: Arg0Reg R: ReceiverResultReg.
							 jumpContinue := self JumpNoOverflow: 0.
							 "overflow; must undo the damage before continuing"
							 self AddR: Arg0Reg R: ReceiverResultReg.
							 objectRepresentation genSetSmallIntegerTagsIn: Arg0Reg]].
		[AndRR] -> [argIsInt
						ifTrue: [self AndCq: argInt R: ReceiverResultReg]
						ifFalse: [self AndR: Arg0Reg R: ReceiverResultReg].
					jumpContinue := self Jump: 0].
		[OrRR]	-> [argIsInt
						ifTrue: [self OrCq: argInt R: ReceiverResultReg]
						ifFalse: [self OrR: Arg0Reg R: ReceiverResultReg].
					jumpContinue := self Jump: 0] }.
	jumpNotSmallInts jmpTarget: self Label.
	argIsInt ifTrue:
		[self MoveCq: argInt R: Arg0Reg].
	index := byte0 - self firstSpecialSelectorBytecodeOffset.
	self genMarshalledSend: index negated - 1 numArgs: 1 sendTable: ordinarySendTrampolines.
	jumpContinue jmpTarget: self Label.
	^0
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSpecialSelectorClass [
	| topReg |
	topReg := self ssTop registerOrNone.
	self ssPop: 1.
	(topReg = NoReg or: [topReg = ClassReg])
		ifTrue: [self ssAllocateRequiredReg: (topReg := SendNumArgsReg) and: ClassReg]
		ifFalse: [self ssAllocateRequiredReg: ClassReg].
	self ssPush: 1.
	self ssTop popToReg: topReg.
	objectRepresentation
		genGetClassObjectOf: topReg
		into: ClassReg
		scratchReg: TempReg
		instRegIsReceiver: false.
	^self ssPop: 1; ssPushRegister: ClassReg
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSpecialSelectorComparison [
	| nextPC postBranchPC targetBytecodePC primDescriptor branchDescriptor
	  rcvrIsInt argIsInt argInt jumpNotSmallInts inlineCAB index |
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpNotSmallInts type: #'AbstractInstruction *'>
	self ssFlushTo: simStackPtr - 2.
	primDescriptor := self generatorAt: byte0.
	argIsInt := self ssTop type = SSConstant
				 and: [objectMemory isIntegerObject: (argInt := self ssTop constant)].
	rcvrIsInt := (self ssValue: 1) type = SSConstant
				 and: [objectMemory isIntegerObject: (self ssValue: 1) constant].

	(argIsInt and: [rcvrIsInt]) ifTrue:
		[^ self genStaticallyResolvedSpecialSelectorComparison].

	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetBytecodePC := target ].

	"Only interested in inlining if followed by a conditional branch."
	inlineCAB := branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse].
	"Further, only interested in inlining = and ~= if there's a SmallInteger constant involved.
	 The relational operators successfully statically predict SmallIntegers; the equality operators do not."
	(inlineCAB and: [primDescriptor opcode = JumpZero or: [primDescriptor opcode = JumpNonZero]]) ifTrue:
		[inlineCAB := argIsInt or: [rcvrIsInt]].
	inlineCAB ifFalse:
		[^self genSpecialSelectorSend].

	argIsInt
		ifTrue:
			[(self ssValue: 1) popToReg: ReceiverResultReg.
			 self ssPop: 2.
			 self MoveR: ReceiverResultReg R: TempReg]
		ifFalse:
			[self marshallSendArguments: 1.
			 self MoveR: Arg0Reg R: TempReg].
	jumpNotSmallInts := (argIsInt or: [rcvrIsInt])
							ifTrue: [objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg]
							ifFalse: [objectRepresentation genJumpNotSmallIntegersIn: ReceiverResultReg andScratch: TempReg scratch: ClassReg].
	argIsInt
		ifTrue: [self CmpCq: argInt R: ReceiverResultReg]
		ifFalse: [self CmpR: Arg0Reg R: ReceiverResultReg].
	"Cmp is weird/backwards so invert the comparison.  Further since there is a following conditional
	 jump bytecode define non-merge fixups and leave the cond bytecode to set the mergeness."
	self genConditionalBranch: (branchDescriptor isBranchTrue
				ifTrue: [primDescriptor opcode]
				ifFalse: [self inverseBranchFor: primDescriptor opcode])
		operand: (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.
	self Jump: (self ensureNonMergeFixupAt: postBranchPC - initialPC).
	jumpNotSmallInts jmpTarget: self Label.
	argIsInt ifTrue:
		[self MoveCq: argInt R: Arg0Reg].
	index := byte0 - self firstSpecialSelectorBytecodeOffset.
	^self genMarshalledSend: index negated - 1 numArgs: 1 sendTable: ordinarySendTrampolines
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSpecialSelectorEqualsEquals [
	"Decompose code generation for #== into a common constant-folding version,
	 followed by a double dispatch throguh the objectRepresentation to a version
	 that doesn't deal with forwarders and a version that does."
	| primDescriptor result |
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	primDescriptor := self generatorAt: byte0.
	
	((objectRepresentation isUnannotatableConstant: self ssTop)
	 and: [ objectRepresentation isUnannotatableConstant: (self ssValue: 1) ]) ifTrue:
		[self assert: primDescriptor isMapped not.
		 result := self ssTop constant = (self ssValue: 1) constant
									ifTrue: [objectMemory trueObject]
									ifFalse: [objectMemory falseObject].
		 self ssPop: 2.
		 ^self ssPushConstant: result].

	^objectRepresentation genSpecialSelectorEqualsEqualsGuts
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSpecialSelectorEqualsEqualsWithForwarders [
	| nextPC branchDescriptor unforwardRcvr argReg targetBytecodePC
	unforwardArg  rcvrReg postBranchPC label fixup |
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	<var: #label type: #'AbstractInstruction *'>
	
	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetBytecodePC := target ].

	"If an operand is an annotable constant, it may be forwarded, so we need to store it into a 
	register so the forwarder check can jump back to the comparison after unforwarding the constant.
	However, if one of the operand is an unnanotable constant, does not allocate a register for it 
	(machine code will use operations on constants) and does not generate forwarder checks."
	unforwardRcvr := (objectRepresentation isUnannotatableConstant: (self ssValue: 1)) not.
	unforwardArg := (objectRepresentation isUnannotatableConstant: self ssTop) not.

	self 
		allocateEqualsEqualsRegistersArgNeedsReg: unforwardArg 
		rcvrNeedsReg: unforwardRcvr 
		into: [ :rcvr :arg | rcvrReg:= rcvr. argReg := arg ].

	"If not followed by a branch, resolve to true or false."
	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse]) ifFalse:
		[^ self genEqualsEqualsNoBranchArgIsConstant: unforwardArg not rcvrIsConstant: unforwardRcvr not argReg: argReg rcvrReg: rcvrReg].
	
	"If branching the stack must be flushed for the merge"
	self ssFlushTo: simStackPtr - 2.
	
	label := self Label.
	self genEqualsEqualsComparisonArgIsConstant: unforwardArg not rcvrIsConstant: unforwardRcvr not argReg: argReg rcvrReg: rcvrReg.
	self ssPop: 2.

	"Further since there is a following conditional jump bytecode, define
	 non-merge fixups and leave the cond bytecode to set the mergeness."
	(self fixupAt: nextPC - initialPC) notAFixup
		ifTrue: "The next instruction is dead.  we can skip it."
			[deadCode := true.
		 	 self ensureFixupAt: targetBytecodePC - initialPC.
			 self ensureFixupAt: postBranchPC - initialPC]
		ifFalse:
			[self ssPushConstant: objectMemory trueObject]. "dummy value"

	self assert: (unforwardArg or: [ unforwardRcvr ]).
	branchDescriptor isBranchTrue 
		ifTrue: 
			[ fixup := (self ensureNonMergeFixupAt: postBranchPC - initialPC) asUnsignedInteger.
			self JumpZero:  (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger ]
		ifFalse: "branchDescriptor is branchFalse"
			[ fixup := (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.
			self JumpZero: (self ensureNonMergeFixupAt: postBranchPC - initialPC) asUnsignedInteger ].
		
	"The forwarders checks need to jump back to the comparison (label) if a forwarder is found, else 
	jump forward either to the next forwarder check or to the postBranch or branch target (fixup)."
	unforwardArg ifTrue: 
		[ unforwardRcvr
			ifTrue: [ objectRepresentation genEnsureOopInRegNotForwarded: argReg scratchReg: TempReg jumpBackTo: label ]
			ifFalse: [ objectRepresentation 
				genEnsureOopInRegNotForwarded: argReg 
				scratchReg: TempReg 
				ifForwarder: label
				ifNotForwarder: fixup ] ].
	unforwardRcvr ifTrue: 
		[ objectRepresentation 
			genEnsureOopInRegNotForwarded: rcvrReg 
			scratchReg: TempReg 
			ifForwarder: label
			ifNotForwarder: fixup ].
		
	"Not reached, execution flow have jumped to fixup"
	
	^0
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genStaticallyResolvedSpecialSelectorComparison [
	"Assumes both operands are ints"
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	| rcvrInt argInt primDescriptor result |
	primDescriptor := self generatorAt: byte0.
	argInt := self ssTop constant.
	rcvrInt := (self ssValue: 1) constant.
	self cCode: '' inSmalltalk: "In Simulator ints are unsigned..."
		[rcvrInt := objectMemory integerValueOf: rcvrInt.
		argInt := objectMemory integerValueOf: argInt].
	 primDescriptor opcode caseOf: {
		[JumpLess]				-> [result := rcvrInt < argInt].
		[JumpLessOrEqual]		-> [result := rcvrInt <= argInt].
		[JumpGreater]			-> [result := rcvrInt > argInt].
		[JumpGreaterOrEqual]	-> [result := rcvrInt >= argInt].
		[JumpZero]				-> [result := rcvrInt = argInt].
		[JumpNonZero]			-> [result := rcvrInt ~= argInt] }.
	 "Must annotate the bytecode for correct pc mapping."
	 self ssPop: 2.
	 ^self ssPushAnnotatedConstant: (result
			ifTrue: [objectMemory trueObject]
			ifFalse: [objectMemory falseObject])
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genStorePop: popBoolean LiteralVariable: litVarIndex [
	<inline: true>
	^self 
		genStorePop: popBoolean 
		LiteralVariable: litVarIndex 
		needsStoreCheck: self ssTopNeedsStoreCheck
		needsImmutabilityCheck: true "The generic store checks for IMMUTABILITY flag"
		
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genStorePop: popBoolean LiteralVariable: litVarIndex needsStoreCheck: needsStoreCheck needsImmutabilityCheck: needsImmCheck [
	<inline: false>
	"We need a frame because the association has to be in ReceiverResultReg for the various trampolines
	and ReceiverResultReg holds only the receiver in frameless methods."
	self assert: needsFrame.
	self genLoadLiteralVariable: litVarIndex in: ReceiverResultReg.
	^self 
		genGenericStorePop: popBoolean 
		slotIndex: ValueIndex 
		destReg: ReceiverResultReg
		needsStoreCheck: needsStoreCheck
		needsRestoreRcvr: false
		needsImmutabilityCheck: needsImmCheck
		
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genStorePop: popBoolean MaybeContextReceiverVariable: slotIndex [ 
	<inline: true>
	^self 
		genStorePop: popBoolean 
		MaybeContextReceiverVariable: slotIndex 
		needsStoreCheck: self ssTopNeedsStoreCheck
		needsImmutabilityCheck: true "The generic store checks for IMMUTABILITY flag"
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genStorePop: popBoolean MaybeContextReceiverVariable: slotIndex needsStoreCheck: needsStoreCheck needsImmutabilityCheck: needsImmCheck [
	<inline: false>
	"The reason we need a frame here is that assigning to an inst var of a context may
	 involve wholesale reorganization of stack pages, and the only way to preserve the
	 execution state of an activation in that case is if it has a frame."
	self assert: needsFrame.
	self ssFlushUpThroughReceiverVariable: slotIndex.
	self ensureReceiverResultRegContainsSelf.
	^self 
		genGenericStorePop: popBoolean 
		MaybeContextSlotIndex: slotIndex 
		needsStoreCheck: needsStoreCheck
		needsRestoreRcvr: true
		needsImmutabilityCheck: needsImmCheck
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genStorePop: popBoolean MaybeContextRemoteInstVar: slotIndex ofObjectAt: objectIndex needsStoreCheck: needsStoreCheck needsImmutabilityCheck: needsImmCheck [
	<inline: false>
	"The reason we need a frame here is that assigning to an inst var of a context may
	 involve wholesale reorganization of stack pages, and the only way to preserve the
	 execution state of an activation in that case is if it has a frame."
	self assert: needsFrame.
	self genLoadTemp: objectIndex in: ReceiverResultReg.
	^self 
		genGenericStorePop: popBoolean 
		MaybeContextSlotIndex: slotIndex 
		needsStoreCheck: needsStoreCheck
		needsRestoreRcvr: false
		needsImmutabilityCheck: needsImmCheck
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genStorePop: popBoolean ReceiverVariable: slotIndex [
	<inline: true>
	^self 
		genStorePop: popBoolean 
		ReceiverVariable: slotIndex 
		needsStoreCheck: self ssTopNeedsStoreCheck
		needsImmutabilityCheck: true "The generic store checks for IMMUTABILITY flag"
		
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genStorePop: popBoolean ReceiverVariable: slotIndex needsStoreCheck: needsStoreCheck needsImmutabilityCheck: needsImmCheck [
	<inline: false>
	self ssFlushUpThroughReceiverVariable: slotIndex.
	self ensureReceiverResultRegContainsSelf.
	"In two path compilation the receiver is young AND mutable, hence no store check nor immutability check is needed"
	^self 
		genGenericStorePop: popBoolean 
		slotIndex: slotIndex 
		destReg: ReceiverResultReg 
		needsStoreCheck: (useTwoPaths not and: [needsStoreCheck])
		needsRestoreRcvr: true "ReceiverResultReg is kept live with the receiver across the operation"
		needsImmutabilityCheck: (needsImmCheck and: [useTwoPaths not])
		
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genStorePop: popBoolean RemoteInstVar: slotIndex ofObjectAt: objectIndex needsStoreCheck: needsStoreCheck needsImmutabilityCheck: needsImmCheck [
	<inline: false>
	self assert: needsFrame.
	self genLoadTemp: objectIndex in: ReceiverResultReg.
	^self 
		genGenericStorePop: popBoolean 
		slotIndex: slotIndex 
		destReg: ReceiverResultReg 
		needsStoreCheck: needsStoreCheck
		needsRestoreRcvr: false
		needsImmutabilityCheck: needsImmCheck
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genStorePop: popBoolean RemoteTemp: slotIndex At: remoteTempIndex [
	<inline: true>
	^ self genStorePop: popBoolean RemoteTemp: slotIndex At: remoteTempIndex needsStoreCheck: self ssTopNeedsStoreCheck
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genStorePop: popBoolean RemoteTemp: slotIndex At: remoteTempIndex needsStoreCheck: needsStoreCheck [
	<inline: false>
	"The only reason we assert needsFrame here is that in a frameless method
	 ReceiverResultReg must and does contain only self, but the ceStoreCheck
	 trampoline expects the target of the store to be in ReceiverResultReg.  So
	 in a frameless method we would have a conflict between the receiver and
	 the temote temp store, unless we we smart enough to realise that
	 ReceiverResultReg was unused after the literal variable store, unlikely given
	 that methods return self by default."
	self assert: needsFrame.
	"N.B.  No need to check the stack for references because we generate code for
	 remote temp loads that stores the result in a register, deferring only the register push."
	self ssAllocateRequiredReg: ReceiverResultReg. 
	optStatus isReceiverResultRegLive: false.
	self MoveMw: (self frameOffsetOfTemporary: remoteTempIndex) r: FPReg R: ReceiverResultReg.
	^self 
		genGenericStorePop: popBoolean 
		slotIndex: slotIndex 
		destReg: ReceiverResultReg 
		needsStoreCheck: needsStoreCheck
		needsRestoreRcvr: false "We don't keep ReceiverResultReg live with the receiver across this operation"
		needsImmutabilityCheck: false "never do immutability check on temp vectors"
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genStorePop: popBoolean TemporaryVariable: tempIndex [
	<inline: false>
	| reg |
	self ssFlushUpThroughTemporaryVariable: tempIndex.
	reg := self ssStorePop: popBoolean toPreferredReg: TempReg.
	self MoveR: reg
		Mw: (self frameOffsetOfTemporary: tempIndex)
		r: FPReg.
	^0
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genTraceStores [
	<inline: true>
	traceStores > 0 ifTrue: 
		[ self MoveR: ClassReg R: TempReg.
		self CallRT: ceTraceStoreTrampoline ].
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genUpArrowReturn [
	"Generate a method return from within a method or a block.
	 Frameless method activation looks like
	 CISCs (x86):
				receiver
				args
		sp->	ret pc.
	 RISCs (ARM):
				receiver
				args
				ret pc in LR.
	 A fully framed activation is described in CoInterpreter class>initializeFrameIndices.
	 Return pops receiver and arguments off the stack.  Callee pushes the result."
	| framelessReturn |
	deadCode := true. "can't fall through"
	inBlock ifTrue:
		[self assert: needsFrame. 
		 self CallRT: ceNonLocalReturnTrampoline.
		 self annotateBytecode: self Label.
		 ^0].
	self 
		cppIf: IMMUTABILITY
		ifTrue: [framelessReturn := needsFrame and: [useTwoPaths not]]
		ifFalse: [framelessReturn := needsFrame].
	framelessReturn
		ifTrue:
			[self MoveR: FPReg R: SPReg.
			 self PopR: FPReg.
			 backEnd hasLinkRegister ifTrue:
				[self PopR: LinkReg].
			 self RetN: methodOrBlockNumArgs + 1 * objectMemory wordSize]
		ifFalse:
			[self RetN: ((methodOrBlockNumArgs > self numRegArgs
						"A method with an interpreter prim will push its register args for the prim.  If the failure
						 body is frameless the args must still be popped, see e.g. Behavior>>nextInstance."
						or: [regArgsHaveBeenPushed])
							ifTrue: [methodOrBlockNumArgs + 1 * objectMemory wordSize]
							ifFalse: [0])].
	^0
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genVanillaSpecialSelectorEqualsEquals [
	| nextPC postBranchPC targetBytecodePC branchDescriptor
	  rcvrReg argReg argIsConstant rcvrIsConstant  |
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	
	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetBytecodePC := target ].
	
	argIsConstant := self ssTop type = SSConstant.
	"they can't be both constants because we do not have instructions manipulating two constants, 
	if this is the case, which can happen due to annotable constants that can be moved in memory 
	with become and therefore can't resolve #== at compilation time, still write the rcvr into a 
	register as if it was not a constant. It's uncommon anyway."
	rcvrIsConstant := argIsConstant not and: [(self ssValue: 1) type = SSConstant]. 
	
	self 
		allocateEqualsEqualsRegistersArgNeedsReg: argIsConstant not 
		rcvrNeedsReg: rcvrIsConstant not 
		into: [ :rcvr :arg | rcvrReg:= rcvr. argReg := arg ].
	
	"If not followed by a branch, resolve to true or false."
	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse]) ifFalse:
		[ ^ self genEqualsEqualsNoBranchArgIsConstant: argIsConstant rcvrIsConstant: rcvrIsConstant argReg: argReg rcvrReg: rcvrReg].
	
	"If branching the stack must be flushed for the merge"
	self ssFlushTo: simStackPtr - 2.
	
	self genEqualsEqualsComparisonArgIsConstant: argIsConstant rcvrIsConstant: rcvrIsConstant argReg: argReg rcvrReg: rcvrReg.
	self ssPop: 2.

	"Further since there is a following conditional jump bytecode, define
	 non-merge fixups and leave the cond bytecode to set the mergeness."
	(self fixupAt: nextPC - initialPC) notAFixup
		ifTrue: "The next instruction is dead.  we can skip it."
			[deadCode := true.
		 	 self ensureFixupAt: targetBytecodePC - initialPC.
			 self ensureFixupAt: postBranchPC - initialPC]
		ifFalse:
			[self ssPushConstant: objectMemory trueObject]. "dummy value"
		
	self genConditionalBranch: (branchDescriptor isBranchTrue ifTrue: [JumpZero] ifFalse: [JumpNonZero])
		operand: (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.

	"If the branch is dead, then we can just fall through postBranchPC (only a nop in-between), else 
	we need to jump over the code of the branch"
	deadCode ifFalse: [self Jump: (self ensureNonMergeFixupAt: postBranchPC - initialPC)].
	^0
]

{ #category : #initialization }
StackToRegisterMappingCogit >> generateEnilopmarts [
	"Enilopmarts transfer control from C into machine code (backwards trampolines).
	 Override to add version for generic and PIC-specific entry with reg args."
	super generateEnilopmarts.

	self cppIf: Debug
		ifTrue:
			[realCECallCogCodePopReceiverArg0Regs :=
				self genEnilopmartFor: ReceiverResultReg
					and: Arg0Reg
					forCall: true
					called: 'realCECallCogCodePopReceiverArg0Regs'.
			 ceCallCogCodePopReceiverArg0Regs := #callCogCodePopReceiverArg0Regs.
			 realCECallCogCodePopReceiverArg1Arg0Regs :=
				self genEnilopmartFor: ReceiverResultReg
					and: Arg0Reg
					and: Arg1Reg
					forCall: true
					called: 'realCECallCogCodePopReceiverArg1Arg0Regs'.
			 ceCallCogCodePopReceiverArg1Arg0Regs := #callCogCodePopReceiverArg1Arg0Regs]
		ifFalse:
			[ceCallCogCodePopReceiverArg0Regs :=
				self genEnilopmartFor: ReceiverResultReg
					and: Arg0Reg
					forCall: true
					called: 'ceCallCogCodePopReceiverArg0Regs'.
			 ceCallCogCodePopReceiverArg1Arg0Regs :=
				self genEnilopmartFor: ReceiverResultReg
					and: Arg0Reg
					and: Arg1Reg
					forCall: true
					called: 'ceCallCogCodePopReceiverArg1Arg0Regs'].

	"These are special versions of the ceCallCogCodePopReceiverAndClassRegs enilopmart that also
	 pop register args from the stack to undo the pushing of register args in the abort/miss trampolines."
	ceCall0ArgsPIC := self genCallPICEnilopmartNumArgs: 0.
	self numRegArgs >= 1 ifTrue:
		[ceCall1ArgsPIC := self genCallPICEnilopmartNumArgs: 1.
		 self numRegArgs >= 2 ifTrue:
			[ceCall2ArgsPIC := self genCallPICEnilopmartNumArgs: 2.
			 self assert: self numRegArgs = 2]]
]

{ #category : #initialization }
StackToRegisterMappingCogit >> generateMissAbortTrampolines [
	"Generate the run-time entries for the various method and PIC entry misses and aborts.
	 Read the class-side method trampolines for documentation on the various trampolines"
	0 to: self numRegArgs + 1 do:
		[:numArgs|
		methodAbortTrampolines
			at: numArgs
			put: (self genMethodAbortTrampolineFor: numArgs)].
	0 to: self numRegArgs + 1 do:
		[:numArgs|
		picAbortTrampolines
			at: numArgs
			put: (self genPICAbortTrampolineFor: numArgs)].
	0 to: self numRegArgs + 1 do:
		[:numArgs|
		picMissTrampolines
			at: numArgs
			put: (self genPICMissTrampolineFor: numArgs)]
]

{ #category : #initialization }
StackToRegisterMappingCogit >> generateSendTrampolines [
	"Override to generate code to push the register arg(s) for <= numRegArg arity sends."
	0 to: NumSendTrampolines - 1 do:
		[:numArgs|
		ordinarySendTrampolines
			at: numArgs
			put: (self genSendTrampolineFor: #ceSend:super:to:numArgs:
					  numArgs: numArgs
					  called: (self trampolineName: 'ceSend' numArgs: numArgs)
					  arg: ClassReg
					  arg: (self trampolineArgConstant: false)
					  arg: ReceiverResultReg
					  arg: (self numArgsOrSendNumArgsReg: numArgs))].

	"Generate these in the middle so they are within [firstSend, lastSend]."
	NewspeakVM ifTrue: [self generateNewspeakSendTrampolines].
	BytecodeSetHasDirectedSuperSend ifTrue:
		[0 to: NumSendTrampolines - 1 do:
			[:numArgs|
			directedSuperSendTrampolines
				at: numArgs
				put: (self genSendTrampolineFor: #ceSend:above:to:numArgs:
						  numArgs: numArgs
						  called: (self trampolineName: 'ceDirectedSuperSend' numArgs: numArgs)
						  arg: ClassReg
						  arg: TempReg
						  arg: ReceiverResultReg
						  arg: (self numArgsOrSendNumArgsReg: numArgs))]].

	0 to: NumSendTrampolines - 1 do:
		[:numArgs|
		superSendTrampolines
			at: numArgs
			put: (self genSendTrampolineFor: #ceSend:super:to:numArgs:
					  numArgs: numArgs
					  called: (self trampolineName: 'ceSuperSend' numArgs: numArgs)
					  arg: ClassReg
					  arg: (self trampolineArgConstant: true)
					  arg: ReceiverResultReg
					  arg: (self numArgsOrSendNumArgsReg: numArgs))].
	firstSend := ordinarySendTrampolines at: 0.
	lastSend := superSendTrampolines at: NumSendTrampolines - 1
]

{ #category : #initialization }
StackToRegisterMappingCogit >> generateTracingTrampolines [
	"Generate trampolines for tracing.  In the simulator we can save a lot of time
	 and avoid noise instructions in the lastNInstructions log by short-cutting these
	 trampolines, but we need them in the real vm."
	ceTraceLinkedSendTrampoline :=
		self genTrampolineFor: #ceTraceLinkedSend:
			called: 'ceTraceLinkedSendTrampoline'
			arg: ReceiverResultReg
			regsToSave: CallerSavedRegisterMask..
	ceTraceBlockActivationTrampoline :=
		self genTrampolineFor: #ceTraceBlockActivation
			called: 'ceTraceBlockActivationTrampoline'
			regsToSave: CallerSavedRegisterMask..
	ceTraceStoreTrampoline :=
		self genTrampolineFor: #ceTraceStoreOf:into:
			called: 'ceTraceStoreTrampoline'
			arg: TempReg
			arg: ReceiverResultReg
			regsToSave: CallerSavedRegisterMask..
	self cCode: [] inSmalltalk:
		[ceTraceLinkedSendTrampoline := self simulatedTrampolineFor: #ceShortCutTraceLinkedSend:.
		 ceTraceBlockActivationTrampoline := self simulatedTrampolineFor: #ceShortCutTraceBlockActivation:.
		 ceTraceStoreTrampoline := self simulatedTrampolineFor: #ceShortCutTraceStore:]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> initSimStackForFramefulMethod: startpc [
	<var: #desc type: #'CogSimStackEntry *'>
	simSelf
		type: SSBaseOffset;
		spilled: true;
		register: FPReg;
		offset: FoxMFReceiver.
	optStatus 
		isReceiverResultRegLive: false;
		ssEntry: (self addressOf: simSelf).
	simSpillBase := methodOrBlockNumTemps. "N.B. Includes num args"
	simStackPtr := simSpillBase - 1.
	"args"
	0 to: methodOrBlockNumArgs - 1 do:
		[:i| | desc |
		desc := self simStackAt: i.
		desc
			type: SSBaseOffset;
			spilled: true;
			register: FPReg;
			offset: FoxCallerSavedIP + ((methodOrBlockNumArgs - i) * objectMemory wordSize);
			bcptr: startpc].
	"temps"
	methodOrBlockNumArgs to: simStackPtr do:
		[:i| | desc |
		desc := self simStackAt: i.
		desc
			type: SSBaseOffset;
			spilled: true;
			register: FPReg;
			offset: FoxMFReceiver - (i - methodOrBlockNumArgs + 1 * objectMemory wordSize);
			bcptr: startpc]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> initSimStackForFramelessBlock: startpc [
	"The register receiver (the closure itself) and args are pushed by the closure value primitive(s)
	 and hence a frameless block has all arguments and copied values pushed to the stack.  However,
	 the method receiver (self) is put in the ReceiverResultRegister by the block entry."
	| desc |
	<var: #desc type: #'CogSimStackEntry *'>
	simSelf
		type: SSRegister;
		spilled: false;
		register: ReceiverResultReg.
	optStatus
		isReceiverResultRegLive: true;
		ssEntry: (self addressOf: simSelf).
	self assert: methodOrBlockNumTemps >= methodOrBlockNumArgs.
	0 to: methodOrBlockNumTemps - 1 do:
		[:i|
		desc := self simStackAt: i.
		desc
			type: SSBaseOffset;
			spilled: true;
			register: SPReg;
			offset: ((backEnd hasLinkRegister
								ifTrue: [methodOrBlockNumArgs - 1- i]
								ifFalse: [methodOrBlockNumArgs - i]) * objectMemory wordSize);
			bcptr: startpc].
	simSpillBase := simStackPtr := methodOrBlockNumTemps - 1
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> initSimStackForFramelessMethod: startpc [
	| desc |
	<var: #desc type: #'CogSimStackEntry *'>
	simSelf
		type: SSRegister;
		spilled: false;
		register: ReceiverResultReg.
	optStatus
		isReceiverResultRegLive: true;
		ssEntry: (self addressOf: simSelf).
	self assert: methodOrBlockNumTemps >= methodOrBlockNumArgs.
	self assert: self numRegArgs <= 2.
	(methodOrBlockNumArgs between: 1 and: self numRegArgs)
		ifTrue:
			[desc := self simStackAt: 0.
			 desc
				type: SSRegister;
				spilled: false;
				register: Arg0Reg;
				bcptr: startpc.
			 methodOrBlockNumArgs > 1 ifTrue:
				[desc := self simStackAt: 1.
				 desc
					type: SSRegister;
					spilled: false;
					register: Arg1Reg;
					bcptr: startpc]]
		ifFalse:
			[0 to: methodOrBlockNumArgs - 1 do:
				[:i|
				desc := self simStackAt: i.
				desc
					type: SSBaseOffset;
					register: SPReg;
					spilled: true;
					offset: ((backEnd hasLinkRegister
								ifTrue: [methodOrBlockNumArgs - 1- i]
								ifFalse: [methodOrBlockNumArgs - i]) * objectMemory wordSize);
					bcptr: startpc]].
	simSpillBase := simStackPtr := methodOrBlockNumArgs - 1
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> initializeFixupAt: targetIndex [
	"Make sure there's a flagged fixup at the targetIndex (pc relative to first pc) in fixups.
	 These are the targets  of backward branches.  A backward branch fixup's simStackPtr
	 needs to be set when generating the code for the bytecode at the targetIndex.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction."
	<returnTypeC: #'BytecodeFixup *'>
	| fixup |
	<var: #fixup type: #'BytecodeFixup *'>
	fixup := self fixupAt: targetIndex.
	fixup
		becomeMergeFixup;
		setIsBackwardBranchFixup.
	^fixup
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> isPushNil: descriptor pc: pc nExts: nExts method: aMethodObj [
	<inline: true>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	^self perform: numPushNilsFunction
		with: descriptor
		with: pc
		with: nExts
		with: aMethodObj
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> liveRegisters [
	| regsSet |
	needsFrame
		ifTrue: [regsSet := 0]
		ifFalse:
			[regsSet := self registerMaskFor: ReceiverResultReg.
			 (methodOrBlockNumArgs <= self numRegArgs
			  and: [methodOrBlockNumArgs > 0]) ifTrue:
				[regsSet := regsSet bitOr: (self registerMaskFor: Arg0Reg).
				 (self numRegArgs > 1 and: [methodOrBlockNumArgs > 1]) ifTrue:
					[regsSet := regsSet bitOr: (self registerMaskFor: Arg1Reg)]]].
	(simSpillBase max: 0) to: simStackPtr do:
		[:i|
		regsSet := regsSet bitOr: (self simStackAt: i) registerMask].
	^regsSet
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> mapDeadDescriptorIfNeeded: descriptor [ 
	"insert nops for dead code that is mapped so that bc 
	 to mc mapping is not many to one"
	<var: #descriptor type: #'BytecodeDescriptor *'>
	self flag: #annotateInstruction .
	(descriptor isMapped
		or: [inBlock and: [descriptor isMappedInBlock]]) 
		ifTrue: [self annotateBytecode: self Nop].
	^ 0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> marshallAbsentReceiverSendArguments: numArgs [
	self assert: needsFrame.
	self ssAllocateCallReg: ReceiverResultReg.
	self putSelfInReceiverResultReg.

	"Spill everything on the simulated stack that needs spilling (that below arguments).
	 Marshall arguments to stack and/or registers depending on arg count.
	 If the args don't fit in registers push receiver and args (spill everything).  Assume
	 receiver already in ResultReceiverReg so shuffle args and push it if necessary."
	self ssFlushTo: simStackPtr - numArgs.
	numArgs > self numRegArgs
		ifTrue:
			["The arguments must be pushed to the stack, and hence the receiver
			   must be inserted beneath the args.  Reduce or eliminate the argument
			   shuffle by only moving already spilled items."
			| numSpilled |
			numSpilled := self numberOfSpillsInTopNItems: numArgs.
			numSpilled > 0
				ifTrue:
					[self MoveMw: 0 r: SPReg R: TempReg.
					 self PushR: TempReg.
					 2 to: numSpilled do:
						[:index|
						self MoveMw: index * objectMemory wordSize r: SPReg R: TempReg.
						self MoveR: TempReg Mw: index - 1 * objectMemory wordSize r: SPReg].
					 self MoveR: ReceiverResultReg Mw: numSpilled * objectMemory wordSize r: SPReg]
				ifFalse:
					[self PushR: ReceiverResultReg].
			self ssFlushTo: simStackPtr]
		"Move the args to the register arguments, being careful to do
		 so last to first so e.g. previous contents don't get overwritten.
		 Also check for any arg registers in use by other args."
		ifFalse:
			[numArgs > 0 ifTrue:
				[(self numRegArgs > 1 and: [numArgs > 1])
					ifTrue:
						[self ssAllocateRequiredReg: Arg0Reg upThrough: simStackPtr - 2.
						 self ssAllocateRequiredReg: Arg1Reg upThrough: simStackPtr - 1]
					ifFalse:
						[self ssAllocateRequiredReg: Arg0Reg upThrough: simStackPtr - 1]].
			 (self numRegArgs > 1 and: [numArgs > 1]) ifTrue:
				[(self simStackAt: simStackPtr) popToReg: Arg1Reg].
			 numArgs > 0 ifTrue:
				[(self simStackAt: simStackPtr - numArgs + 1)
					popToReg: Arg0Reg]].
	self ssPop: numArgs
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> marshallSendArguments: numArgs [ 
	"Spill everything on the simulated stack that needs spilling (that below receiver and arguments).
	 Marshall receiver and arguments to stack and/or registers depending on arg count.
	 If the args don't fit in registers push receiver and args (spill everything), but still assign
	 the receiver to ReceiverResultReg."
	self ssFlushTo: simStackPtr - numArgs - 1.
	numArgs > self numRegArgs
		ifTrue:
			"If there are no spills and no references to ReceiverResultReg
			 the fetch of ReceiverResultReg from the stack can be avoided
			 by assigning directly to ReceiverResultReg and pushing it."
			[| numSpilled anyRefs |
			numSpilled := self numberOfSpillsInTopNItems: numArgs + 1.
			anyRefs := self anyReferencesToRegister: ReceiverResultReg inTopNItems: numArgs + 1.
			(numSpilled > 0 or: [anyRefs])
				ifTrue:
					[self ssFlushTo: simStackPtr.
					 (self simStackAt: simStackPtr - numArgs)
						storeToReg: ReceiverResultReg]
				ifFalse:
					[(self simStackAt: simStackPtr - numArgs)
						storeToReg: ReceiverResultReg;
					 	type: SSRegister;
						register: ReceiverResultReg.
					 self ssFlushTo: simStackPtr]]
		ifFalse:
			"Move the args to the register arguments, being careful to do
			 so last to first so e.g. previous contents don't get overwritten.
			 Also check for any arg registers in use by other args."
			[numArgs > 0 ifTrue:
				[(self numRegArgs > 1 and: [numArgs > 1])
					ifTrue:
						[self ssAllocateRequiredReg: Arg0Reg upThrough: simStackPtr - 2.
						 self ssAllocateRequiredReg: Arg1Reg upThrough: simStackPtr - 1]
					ifFalse:
						[self ssAllocateRequiredReg: Arg0Reg upThrough: simStackPtr - 1]].
			 (self numRegArgs > 1 and: [numArgs > 1]) ifTrue:
				[(self simStackAt: simStackPtr) popToReg: Arg1Reg].
			 numArgs > 0 ifTrue:
				[(self simStackAt: simStackPtr - numArgs + 1)
					popToReg: Arg0Reg].
			 (self simStackAt: simStackPtr - numArgs)
				popToReg: ReceiverResultReg].
	self ssPop: numArgs + 1
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> maybeCountCounter [
	"This is a hook for SistaCogit"
	<inline: true>
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> maybeCountFixup [
	"This is a hook for RegisterAllocatingCogit"
	<inline: true>
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> maybeInitNumCounters [
	"This is a hook for SistaCogit"
	<inline: true>
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> maybeInitNumFixups [
	"This is a hook for RegisterAllocatingCogit"
	<inline: true>
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> mergeWithFixupIfRequired: fixup [
	"If this bytecode has a fixup, some kind of merge needs to be done. There are 4 cases:
		1) the bytecode has no fixup (fixup isNotAFixup)
			do nothing
		2) the bytecode has a non merge fixup
			the fixup has needsNonMergeFixup.
			The code generating non merge fixup (currently only special selector code) is responsible
				for the merge so no need to do it.
			We set deadCode to false as the instruction can be reached from jumps.
		3) the bytecode has a merge fixup, but execution flow *cannot* fall through to the merge point.
			the fixup has needsMergeFixup and deadCode = true.
			ignores the current simStack as it does not mean anything 
			restores the simStack to the state the jumps to the merge point expects it to be.
		4) the bytecode has a merge fixup and execution flow *can* fall through to the merge point.
			the fixup has needsMergeFixup and deadCode = false.
			flushes the stack to the stack pointer so the fall through execution path simStack is 
				in the state the merge point expects it to be. 
			restores the simStack to the state the jumps to the merge point expects it to be.
			
	In addition, if this is a backjump merge point, we patch the fixup to hold the current simStackPtr 
	for later assertions."
	
	<var: #fixup type: #'BytecodeFixup *'>
	"case 1"
	fixup notAFixup ifTrue: [^ 0].

	"case 2"
	fixup isNonMergeFixup ifTrue: [deadCode := false. ^ 0 ].

	"cases 3 and 4"
	self assert: fixup isMergeFixup.
	self traceMerge: fixup.
	deadCode 
		ifTrue: [simStackPtr := fixup simStackPtr] "case 3"
		ifFalse: [self ssFlushTo: simStackPtr]. "case 4"
	"cases 3 and 4"
	deadCode := false.
	fixup isBackwardBranchFixup ifTrue: [fixup simStackPtr: simStackPtr].
	fixup targetInstruction: self Label.
	self assert: simStackPtr = fixup simStackPtr.
	self cCode: '' inSmalltalk:
		[self assert: fixup simStackPtr = (self debugStackPointerFor: bytecodePC)].
	self restoreSimStackAtMergePoint: fixup.
	
	^0
]

{ #category : #trampolines }
StackToRegisterMappingCogit >> methodAbortTrampolineFor: numArgs [
	^methodAbortTrampolines at: (numArgs min: self numRegArgs + 1)
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> needsFrameIfExtBGT2: stackDelta [
	^extB < 0 or: [extB > 2]
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> needsFrameIfFollowsSend: stackDelta [
	"As of August 2013, the code generator can't deal with spills in frameless methods (the
	 issue is to do with the stack offset to get at an argument, which is changed when there's a spill).
	 The only context in a spill is needed in a frameless method that I can think of is sends
	 following sends as in e.g. TextColor>>#dominates: other ^other class == self class.
	 Only need to check for the frameless sends since all other sends will force a frame."

	self assert: (prevBCDescriptor notNil and: [prevBCDescriptor needsFrameFunction notNil]).
	^prevBCDescriptor generator == #genSpecialSelectorEqualsEquals
	  or: [prevBCDescriptor generator == #genSpecialSelectorClass]
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> needsFrameIfMod16GENumArgs: stackDelta [
	^byte0 \\ 16 >= methodOrBlockNumArgs
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> needsFrameIfStackGreaterThanOne: stackDelta [
	"As of August 2013, the code generator can't deal with spills in frameless methods (the
	 issue is to do with the stack offset to get at an argument, which is changed when there's a spill).
	 In e.g. TextColor>>#dominates: other ^other class == self class the second send of class
	 needs also rto allocate a register that the first one used, but the first one's register can't be
	 spilled.  So avoid this by only allowing class to be sent if the stack contains a single element."

	^stackDelta > 1
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> numPushNils: descriptor pc: pc nExts: nExts method: aMethodObj [
	<inline: true>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	^self perform: numPushNilsFunction
		with: descriptor
		with: pc
		with: nExts
		with: aMethodObj
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> numRegArgs [
	<doNotGenerate>
	^objectRepresentation numRegArgs
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> numberOfSpillsInTopNItems: n [
	simStackPtr to: simStackPtr - n + 1 by: -1 do:
		[:i| (self simStackAt: i) type = SSSpill ifTrue:
			[^n - (simStackPtr - i)]].
	^0
]

{ #category : #trampolines }
StackToRegisterMappingCogit >> picAbortTrampolineFor: numArgs [
	^picAbortTrampolines at: (numArgs min: self numRegArgs + 1)
]

{ #category : #testing }
StackToRegisterMappingCogit >> prevInstIsPCAnnotated [
	| prevIndex prevInst |
	<var: #prevInst type: #'AbstractInstruction *'>
	opcodeIndex > 0 ifFalse:
		[^false].
	prevIndex := opcodeIndex - 1.
	[prevIndex <= 0 ifTrue: [^false].
	 prevInst := self abstractInstructionAt: prevIndex.
	 (self isPCMappedAnnotation: (prevInst annotation ifNil: [0])) ifTrue:
		[^true].
	 prevInst opcode = Label]
		whileTrue:
			[prevIndex := prevIndex - 1].
	^false
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> printSimStack [
	<doNotGenerate>
	self printSimStack: simStack toDepth: simStackPtr spillBase: simSpillBase
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> printSimStack: aSimStack toDepth: limit spillBase: spillBase [
	<doNotGenerate>
	coInterpreter transcript ensureCr.
	limit < 0 ifTrue:
		[^coInterpreter transcript nextPutAll: 'simStackEmpty'; cr; flush].
	0 to: limit do:
		[:i|
		coInterpreter transcript print: i.
		i = spillBase
			ifTrue: [coInterpreter transcript nextPutAll: ' sb'; tab]
			ifFalse: [coInterpreter transcript tab; tab].
		(aSimStack at: i) printStateOn: coInterpreter transcript.
		coInterpreter transcript cr; flush]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> pushNilSize: aMethodObj numInitialNils: numInitialNils [
	<inline: true>
	^self perform: pushNilSizeFunction with: aMethodObj with: numInitialNils
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> putSelfInReceiverResultReg [
	<inline: true>
	 (self addressOf: simSelf) storeToReg: ReceiverResultReg
		
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> reinitializeFixupsFrom: start through: end [
	"When a block must be recompiled due to overestimating the
	 numInitialNils fixups must be restored, which means rescannning
	 since backward branches need their targets initialized."
	| descriptor nExts pc distance targetPC |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	pc := start.
	nExts := 0.
	[pc <= end] whileTrue:
		[(self fixupAt: pc - initialPC) reinitialize.
		 byte0 := (objectMemory fetchByte: pc ofObject: methodObj) + bytecodeSetOffset.
		 descriptor := self generatorAt: byte0.
		 (descriptor isBranch
		  and: [self isBackwardBranch: descriptor at: pc exts: nExts in: methodObj]) ifTrue:
			[distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 self initializeFixupAt: targetPC - initialPC].
		 descriptor isBlockCreation
			ifTrue:
				[distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
				 pc := pc + descriptor numBytes + distance]
			ifFalse: [pc := pc + descriptor numBytes].
		 nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0]]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> restoreSimStackAtMergePoint: fixup [
	<inline: true>
	"All the execution paths reaching a merge point expect everything to be
	spilled on stack and the optStatus is unknown. Throw away all simStack and 
	optStatus optimization state."
	simSpillBase := methodOrBlockNumTemps.
	optStatus isReceiverResultRegLive: false.
	methodOrBlockNumTemps to: simStackPtr do:
		[:i|
			(self simStackAt: i)
				type: SSSpill;
				offset: FoxMFReceiver - (i - methodOrBlockNumArgs + 1 * objectMemory bytesPerOop);
				register: FPReg;
				spilled: true].
	^ 0
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> scanBlock: blockStart [
	"Scan the block to determine if the block needs a frame or not"
	| descriptor pc end framelessStackDelta nExts pushingNils numPushNils |
	<var: #blockStart type: #'BlockStart *'>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	needsFrame := false.
	prevBCDescriptor := nil.
	methodOrBlockNumArgs := blockStart numArgs.
	inBlock := true.
	pc := blockStart startpc.
	end := blockStart startpc + blockStart span.
	framelessStackDelta := nExts := extA := extB := 0.
	pushingNils := true.
	[pc < end] whileTrue:
		[byte0 := (objectMemory fetchByte: pc ofObject: methodObj) + bytecodeSetOffset.
		 descriptor := self generatorAt: byte0.
		 descriptor isExtension ifTrue:
			[self loadSubsequentBytesForDescriptor: descriptor at: pc.
			 self perform: descriptor generator].
		 needsFrame ifFalse:
			[(descriptor needsFrameFunction isNil
			  or: [self perform: descriptor needsFrameFunction with: framelessStackDelta])
				ifTrue: [needsFrame := true]
				ifFalse: [framelessStackDelta := framelessStackDelta + descriptor stackDelta]].
		 objectRepresentation maybeNoteDescriptor: descriptor blockStart: blockStart.
		 (pushingNils
		  and: [descriptor isExtension not]) ifTrue:
			["Count the initial number of pushed nils acting as temp initializers.  We can't tell
			  whether an initial pushNil is an operand reference or a temp initializer, except
			  when the pushNil is a jump target (has a fixup), which never happens:
					self systemNavigation browseAllSelect:
						[:m| | ebc |
						(ebc := m embeddedBlockClosures
									select: [:ea| ea decompile statements first isMessage]
									thenCollect: [:ea| ea decompile statements first selector]) notEmpty
						and: [(#(whileTrue whileFalse whileTrue: whileFalse:) intersection: ebc) notEmpty]]
			  or if the bytecode set has a push multiple nils bytecode.  We simply count initial nils.
			  Rarely we may end up over-estimating.  We will correct by checking the stack depth
			  at the end of the block in compileBlockBodies."
			 (numPushNils := self numPushNils: descriptor pc: pc nExts: nExts method: methodObj) > 0
				ifTrue:
					[self assert: (descriptor numBytes = 1
									or: [descriptor generator == #genPushClosureTempsBytecode]).
					 blockStart numInitialNils: blockStart numInitialNils + numPushNils]
				ifFalse:
					[pushingNils := false]].
		 pc := self nextBytecodePCFor: descriptor at: pc exts: nExts in: methodObj.
		 descriptor isExtension
			ifTrue: [nExts := nExts + 1]
			ifFalse: [nExts := extA := extB := 0].
		 prevBCDescriptor := descriptor].
	"It would be nice of this wasn't necessary but alas we need to do the eager
	 scan for frameless methods so that we don't end up popping too much off
	 the simulated stack, e.g. for pushNil; returnTopFromBlock methods."
	needsFrame ifFalse:
		[self assert: (framelessStackDelta >= 0 and: [blockStart numInitialNils >= framelessStackDelta]).
		 blockStart numInitialNils: blockStart numInitialNils - framelessStackDelta].
	^0
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> scanMethod [
	"Scan the method (and all embedded blocks) to determine
		- what the last bytecode is; extra bytes at the end of a method are used to encode things like source pointers or temp names
		- if the method needs a frame or not
		- what are the targets of any backward branches.
		- how many blocks it creates
	 Answer the block count or on error a negative error code"
	| latestContinuation nExts descriptor pc numBlocks distance targetPC framelessStackDelta seenInstVarStore |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	needsFrame := useTwoPaths := seenInstVarStore := false.
	self maybeInitNumFixups.
	self maybeInitNumCounters.
	prevBCDescriptor := nil.
	NewspeakVM ifTrue:
		[numIRCs := 0].
	(primitiveIndex > 0
	 and: [coInterpreter isQuickPrimitiveIndex: primitiveIndex]) ifTrue:
		[^0].
	pc := latestContinuation := initialPC.
	numBlocks := framelessStackDelta := nExts := extA := extB := 0.
	[pc <= endPC] whileTrue:
		[byte0 := (objectMemory fetchByte: pc ofObject: methodObj) + bytecodeSetOffset.
		 descriptor := self generatorAt: byte0.
		 descriptor isExtension ifTrue:
			[descriptor opcode = Nop ifTrue: "unknown bytecode tag; see Cogit class>>#generatorTableFrom:"
				[^EncounteredUnknownBytecode].
			 self loadSubsequentBytesForDescriptor: descriptor at: pc.
			 self perform: descriptor generator].
		 (descriptor isReturn
		  and: [pc >= latestContinuation]) ifTrue:
			[endPC := pc].

		  needsFrame ifFalse:
			[(descriptor needsFrameFunction isNil
			  or: [self perform: descriptor needsFrameFunction with: framelessStackDelta])
					ifTrue:
						["With immutability we win simply by avoiding a frame build if the receiver is young and not immutable."
						 self cppIf: IMMUTABILITY
							ifTrue: [descriptor is1ByteInstVarStore
									ifTrue: [useTwoPaths := true]
									ifFalse: [needsFrame := true. useTwoPaths := false]]
							ifFalse: [needsFrame := true. useTwoPaths := false]]
					ifFalse:
						[framelessStackDelta := framelessStackDelta + descriptor stackDelta.
						 "Without immutability we win if there are two or more stores and the receiver is new."
						 self cppIf: IMMUTABILITY
							ifTrue: []
							ifFalse:
								[descriptor is1ByteInstVarStore ifTrue:
									[seenInstVarStore
										ifTrue: [useTwoPaths := true]
										ifFalse: [seenInstVarStore := true]]]]].

		 descriptor isBranch ifTrue:
			[distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 (self isBackwardBranch: descriptor at: pc exts: nExts in: methodObj)
				ifTrue: [self initializeFixupAt: targetPC - initialPC]
				ifFalse:
					[latestContinuation := latestContinuation max: targetPC.
					 self maybeCountFixup.
					 self maybeCountCounter]].
		 descriptor isBlockCreation ifTrue:
			[numBlocks := numBlocks + 1.
			 distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 latestContinuation := latestContinuation max: targetPC.
			 self maybeCountFixup].

		 NewspeakVM ifTrue:
			[descriptor hasIRC ifTrue:
				[numIRCs := numIRCs + 1]].
		 pc := pc + descriptor numBytes.
		 descriptor isExtension
			ifTrue: [nExts := nExts + 1]
			ifFalse: [nExts := extA := extB := 0].
		 prevBCDescriptor := descriptor].
	^numBlocks
]

{ #category : #initialization }
StackToRegisterMappingCogit >> setInterpreter: aCoInterpreter [
	"Initialization of the code generator in the simulator.
	 These objects already exist in the generated C VM
	 or are used only in the simulation."
	<doNotGenerate>
	super setInterpreter: aCoInterpreter.

	methodAbortTrampolines := CArrayAccessor on: (Array new: self numRegArgs + 2).
	picAbortTrampolines := CArrayAccessor on: (Array new: self numRegArgs + 2).
	picMissTrampolines := CArrayAccessor on: (Array new: self numRegArgs + 2).

	simStack := CArrayAccessor on: ((1 to: self class simStackSlots) collect: [:i| self simStackEntryClass new cogit: self]).
	simSelf := self simStackEntryClass new cogit: self.
	optStatus := CogSSOptStatus new.

	debugFixupBreaks := self class initializationOptions at: #debugFixupBreaks ifAbsent: [Set new].

	numPushNilsFunction := self class numPushNilsFunction.
	pushNilSizeFunction := self class pushNilSizeFunction
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> simStackAt: index [
	<cmacro: '(index) (simStack + (index))'>
	<returnTypeC: #'CogSimStackEntry *'>
	^self addressOf: (simStack at: index)
]

{ #category : #initialization }
StackToRegisterMappingCogit >> simStackEntryClass [
	<doNotGenerate>
	^CogSimStackEntry
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> simStackSlots [
	"Answer the number of slots toinclude in a simulated stack.
	 This needs to be big enough to include all slots in a context
	 plus some overflow for safety."
	<inline: true>
	^((LargeContextSlots - CtxtTempFrameStart max: 64) * 11 // 10)
]

{ #category : #testing }
StackToRegisterMappingCogit >> sistaNeedsStoreCheck [
	<inline: true>
	"The store check can be ignored if the value assigned doesn't need it (immediate, etc)
	In addition, the extB low bit is marked by the optimizer if the store check is not required"
	^ self ssTopNeedsStoreCheck and: [ self extBSpecifiesStoreCheck ]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> sistaV1: descriptor Num: pc Push: nExts Nils: aMethodObj [
	"230		11100110	iiiiiiii		PushNClosureTemps iiiiiiii"
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	^descriptor generator == #genPushClosureTempsBytecode
		ifTrue: [objectMemory fetchByte: pc + 1 ofObject: aMethodObj]
		ifFalse: [0]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> sistaV1PushNilSize: aMethodObj numInitialNils: numInitialNils [
	"230		11100110	iiiiiiii		PushNClosureTemps iiiiiiii"
	<inline: true>
	^numInitialNils
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> squeakV3orSistaV1: descriptor Num: pc Push: nExts Nils: aMethodObj [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	^bytecodeSetOffset = 0
		ifTrue: [self v3: descriptor Num: pc Push: nExts Nils: aMethodObj]
		ifFalse: [self sistaV1: descriptor Num: pc Push: nExts Nils: aMethodObj]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> squeakV3orSistaV1PushNilSize: aMethodObj numInitialNils: numInitialNils [
	^(coInterpreter methodUsesAlternateBytecodeSet: aMethodObj)
		ifTrue: [self sistaV1PushNilSize: aMethodObj numInitialNils: numInitialNils]
		ifFalse: [self v3PushNilSize: aMethodObj numInitialNils: numInitialNils]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateCallReg: requiredReg [
	"Allocate a register needed in a run-time call (i.e. flush uses of the
	 register to the real stack).  Since the run-time can smash any and
	 all caller-saved registers also flush all caller-saved registers."
	self ssAllocateRequiredRegMask: (CallerSavedRegisterMask
										bitOr: (self registerMaskFor: requiredReg))
		upThrough: simStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateCallReg: requiredReg1 and: requiredReg2 [
	"Allocate registers needed in a run-time call (i.e. flush uses of the
	 registers to the real stack).  Since the run-time can smash any and
	 all caller-saved registers also flush all caller-saved registers."
	self ssAllocateRequiredRegMask: (CallerSavedRegisterMask
										bitOr: ((self registerMaskFor: requiredReg1)
										bitOr: (self registerMaskFor: requiredReg2)))
		upThrough: simStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateCallReg: requiredReg1 and: requiredReg2 and: requiredReg3 [
	"Allocate registers needed in a run-time call (i.e. flush uses of the
	 registers to the real stack).  Since the run-time can smash any and
	 all caller-saved registers also flush all caller-saved registers."
	self ssAllocateRequiredRegMask: (CallerSavedRegisterMask
										bitOr: ((self registerMaskFor: requiredReg1)
										bitOr: ((self registerMaskFor: requiredReg2)
										bitOr: (self registerMaskFor: requiredReg3))))
		upThrough: simStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateCallReg: requiredReg1 and: requiredReg2 and: requiredReg3 and: requiredReg4 [
	"Allocate registers needed in a run-time call (i.e. flush uses of the
	 registers to the real stack).  Since the run-time can smash any and
	 all caller-saved registers also flush all caller-saved registers."
	self ssAllocateRequiredRegMask: (CallerSavedRegisterMask
										bitOr: ((self registerMaskFor: requiredReg1)
										bitOr: ((self registerMaskFor: requiredReg2)
										bitOr: ((self registerMaskFor: requiredReg3)
										bitOr: (self registerMaskFor: requiredReg4)))))
		upThrough: simStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateRequiredReg: requiredReg [
	self ssAllocateRequiredRegMask: (self registerMaskFor: requiredReg)
		upThrough: simStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateRequiredReg: requiredReg1 and: requiredReg2 [
	self ssAllocateRequiredRegMask: ((self registerMaskFor: requiredReg1)
										bitOr: (self registerMaskFor: requiredReg2))
		upThrough: simStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateRequiredReg: requiredReg upThrough: stackPtr [
	self ssAllocateRequiredRegMask: (self registerMaskFor: requiredReg)
		upThrough: stackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateRequiredRegMask: requiredRegsMask upThrough: stackPtr [
	| lastRequired liveRegs |
	lastRequired := -1.
	"compute live regs while noting the last occurrence of required regs.
	 If these are not free we must spill from simSpillBase to last occurrence.
	 Note we are conservative here; we could allocate FPReg in frameless methods."
	liveRegs := self registerMaskFor: FPReg and: SPReg.
	(simSpillBase max: 0) to: stackPtr do:
		[:i|
		liveRegs := liveRegs bitOr: (self simStackAt: i) registerMask.
		((self simStackAt: i) registerMask bitAnd: requiredRegsMask) ~= 0 ifTrue:
			[lastRequired := i]].
	"If any of requiredRegsMask are live we must spill."
	(liveRegs bitAnd: requiredRegsMask) = 0 ifFalse:
		["Some live, must spill"
		self ssFlushTo: lastRequired.
		self assert: (self liveRegisters bitAnd: requiredRegsMask) = 0]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssFlushTo: index [
	methodOrBlockNumTemps to: simSpillBase - 1 do:
		[:i| self assert: (self simStackAt: i) spilled].
	simSpillBase <= index ifTrue:
		[(simSpillBase max: 0) to: index do:
			[:i|
			self assert: needsFrame.
			(self simStackAt: i)
				ensureSpilledAt: (self frameOffsetOfTemporary: i)
				from: FPReg].
		 simSpillBase := index + 1]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssFlushUpThrough: unaryBlock [
	"Any occurrences on the stack of the value being stored (which is the top of stack)
	 must be flushed, and hence any values colder than them stack."
	<inline: true>
	simStackPtr - 1 to: (simSpillBase max: 0) by: -1 do:
		[ :index |
		(unaryBlock value: (self simStackAt: index)) ifTrue: [ ^ self ssFlushTo: index ] ]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssFlushUpThroughReceiverVariable: slotIndex [
	"Any occurrences on the stack of the value being stored (which is the top of stack)
	 must be flushed, and hence any values colder than them stack."
	<var: #desc type: #'CogSimStackEntry *'>
	self ssFlushUpThrough: 
		[ :desc |  
			desc type = SSBaseOffset
			 and: [desc register = ReceiverResultReg
			 and: [desc offset = (objectRepresentation slotOffsetOfInstVarIndex: slotIndex) ] ] ]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssFlushUpThroughRegister: reg [
	"Any occurrences on the stack of the register must be
	 flushed, and hence any values colder than them stack."
	<var: #desc type: #'CogSimStackEntry *'>
	self ssFlushUpThrough: [ :desc | desc type = SSRegister and: [ desc register = reg ] ]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssFlushUpThroughTemporaryVariable: tempIndex [
	"Any occurrences on the stack of the value being stored (which is the top of stack)
	 must be flushed, and hence any values colder than them stack."
	<var: #desc type: #'CogSimStackEntry *'>
	self ssFlushUpThrough: 
		[ :desc |
			desc type = SSBaseOffset
		 	and: [desc register = FPReg
		 	and: [desc offset = (self frameOffsetOfTemporary: tempIndex) ] ] ]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPop: n [
	self assert: (simStackPtr - n >= (methodOrBlockNumTemps - 1)
				or: [needsFrame not and: [simStackPtr - n >= -1]]).
	simStackPtr := simStackPtr - n
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPush: n [ 
	simStackPtr := simStackPtr + n
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushAnnotatedConstant: literal [
	self ssPush: 1.
	self updateSimSpillBase.
	self ssTop
		type: SSConstant;
		spilled: false;
		constant: literal;
		bcptr: bytecodePC.
	self annotateInstructionForBytecode.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushBase: reg offset: offset [
	self ssPush: 1.
	self updateSimSpillBase.
	self ssTop
		type: SSBaseOffset;
		spilled: false;
		register: reg;
		offset: offset;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushConstant: literal [
	self ssPush: 1.
	self updateSimSpillBase.
	self ssTop
		type: SSConstant;
		spilled: false;
		constant: literal;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushDesc: simStackEntry [
	<var: #simStackEntry type: #SimStackEntry>
	self cCode:
			[simStackEntry type = SSSpill ifTrue:
				[simStackEntry type: SSBaseOffset].
			simStackEntry
				spilled: false;
				bcptr: bytecodePC.
			 simStack
				at: (simStackPtr := simStackPtr + 1)
				put: simStackEntry]
		inSmalltalk:
			[(simStack at: (simStackPtr := simStackPtr + 1))
				copyFrom: simStackEntry;
				type: (simStackEntry type = SSSpill
						ifTrue: [SSBaseOffset]
						ifFalse: [simStackEntry type]);
				spilled: false;
				bcptr: bytecodePC].
	self updateSimSpillBase.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushRegister: reg [
	self ssPush: 1.
	self updateSimSpillBase.
	self ssTop
		type: SSRegister;
		spilled: false;
		register: reg;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssStoreAndReplacePop: popBoolean toReg: reg [
	"In addition to ssStorePop:toReg:, if this is a store and not
	a popInto I change the simulated stack to use the register 
	for the top value"
	| topSpilled |
	topSpilled := self ssTop spilled.
	self ssStorePop: (popBoolean or: [topSpilled]) toReg: reg.
	popBoolean ifFalse: 
		[ topSpilled ifFalse: [self ssPop: 1].
		self ssPushRegister: reg ].
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssStorePop: popBoolean toPreferredReg: preferredReg [
	"Store or pop the top simulated stack entry to a register.
	 Use preferredReg if the entry is not itself a register.
	 Answer the actual register the result ends up in."
	| actualReg |
	actualReg := preferredReg.
	self ssTop type = SSRegister ifTrue: 
		[self assert: self ssTop spilled not.
		 actualReg := self ssTop register].
	self ssStorePop: popBoolean toReg: actualReg. "generates nothing if ssTop is already in actualReg"
	^ actualReg
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssStorePop: popBoolean toReg: reg [
	"Store or pop the top simulated stack entry to a register.
	N.B.: popToReg: and storeToReg: does not generate anything if 
	it moves a register to the same register."	
	popBoolean
		ifTrue: [self ssTop popToReg: reg.
				self ssPop: 1]
		ifFalse: [self ssTop storeToReg: reg].
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssTop [
	<returnTypeC: #'CogSimStackEntry *'>
	^self simStackAt: simStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssTopDescriptor [
	<returnTypeC: #SimStackEntry>
	^simStack at: simStackPtr
]

{ #category : #testing }
StackToRegisterMappingCogit >> ssTopNeedsStoreCheck [
	<inline: true>
	^self ssTop type ~= SSConstant
	  or: [(objectMemory isNonImmediate: self ssTop constant)
		and: [objectRepresentation shouldAnnotateObjectReference:  self ssTop constant]]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssValue: n [
	<returnTypeC: #'CogSimStackEntry *'>
	^self simStackAt: simStackPtr - n
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> traceDescriptor: descriptor [
	<cmacro: '(ign) 0'>
	(compilationTrace anyMask: 2) ifTrue:
		[coInterpreter transcript cr; print: bytecodePC; space; nextPutAll: descriptor generator; flush]
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> traceFixup: fixup [
	<cmacro: '(ign) 0'>
	| index |
	(compilationTrace anyMask: 8) ifTrue:
		[index := (fixups object identityIndexOf: fixup) - 1.
		 coInterpreter transcript
			ensureCr;
			print: bytecodePC; nextPutAll: ' -> '; print: index; nextPut: $/; print: index + initialPC;
			nextPut: $:; space.
			fixup printStateOn: coInterpreter transcript.
			coInterpreter transcript cr; flush]
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> traceMerge: fixup [
	<cmacro: '(ign) 0'>
	| index |
	(compilationTrace anyMask: 4) ifTrue:
		[index := (fixups object identityIndexOf: fixup) - 1.
		 coInterpreter transcript
			ensureCr;
			print: index; nextPut: $/; print: index + initialPC;
			nextPut: $:; space.
			fixup printStateOn: coInterpreter transcript.
			coInterpreter transcript cr; flush]
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> traceSimStack [
	<cmacro: '() 0'>
	(compilationTrace anyMask: 1) ifTrue:
		[self printSimStack]
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> traceSpill: simStackEntry [
	<cmacro: '(ign) 0'>
	(compilationTrace anyMask: 2) ifTrue:
		[coInterpreter transcript cr; print: bytecodePC; space; print: simStackEntry; flush]
]

{ #category : #'peephole optimizations' }
StackToRegisterMappingCogit >> tryCollapseTempVectorInitializationOfSize: slots [
	"If the sequence of bytecodes is
		push: (Array new: 1)
		popIntoTemp: tempIndex
		pushConstant: const or pushTemp: n
		popIntoTemp: 0 inVectorAt: tempIndex
	 collapse this into
		tempAt: tempIndex put: {const or temp}
	 and answer true, otherwise answer false.
	 One might think that we should look for a sequence of more than
	 one pushes and pops but this is extremely rare.
	 Exclude pushRcvr: n to avoid potential complications with context inst vars."
	| pushArrayDesc storeArrayDesc pushValueDesc storeValueDesc tempIndex remoteTempIndex reg |
	<var: #pushArrayDesc type: #'BytecodeDescriptor *'>
	<var: #pushValueDesc type: #'BytecodeDescriptor *'>
	<var: #storeArrayDesc type: #'BytecodeDescriptor *'>
	<var: #storeValueDesc type: #'BytecodeDescriptor *'>
	slots ~= 1 ifTrue:
		[^false].
	pushArrayDesc := self generatorAt: bytecodeSetOffset
										+ (objectMemory
												fetchByte: bytecodePC
												ofObject: methodObj).
	self assert: pushArrayDesc generator == #genPushNewArrayBytecode.
	storeArrayDesc := self generatorAt: bytecodeSetOffset
										+ (objectMemory
												fetchByte: bytecodePC
														+ pushArrayDesc numBytes
												ofObject: methodObj).
	storeArrayDesc generator == #genStoreAndPopTemporaryVariableBytecode
		ifTrue:
			[tempIndex := (objectMemory
								fetchByte: bytecodePC + pushArrayDesc numBytes
								ofObject: methodObj) bitAnd: 16r7]
		ifFalse:
			[storeArrayDesc generator == #genLongStoreAndPopTemporaryVariableBytecode ifFalse:
				[^false].
			 tempIndex := objectMemory
								fetchByte: bytecodePC + pushArrayDesc numBytes + 1
								ofObject: methodObj].
	pushValueDesc := self generatorAt: bytecodeSetOffset
										+ (objectMemory
												fetchByte: bytecodePC
														+ pushArrayDesc numBytes
														+ storeArrayDesc numBytes
												ofObject: methodObj).
	(pushValueDesc generator == #genPushLiteralConstantBytecode
	 or: [pushValueDesc generator == #genPushQuickIntegerConstantBytecode
	 or: [pushValueDesc generator == #genPushTemporaryVariableBytecode]]) ifFalse:
		[^false].
	storeValueDesc := self generatorAt: bytecodeSetOffset
										+ (objectMemory
												fetchByte: bytecodePC
														+ pushArrayDesc numBytes
														+ storeArrayDesc numBytes
														+ pushValueDesc numBytes
												ofObject: methodObj).
	remoteTempIndex := objectMemory
												fetchByte: bytecodePC
														+ pushArrayDesc numBytes
														+ storeArrayDesc numBytes
														+ pushValueDesc numBytes
														+ 2
												ofObject: methodObj.
	(storeValueDesc generator == #genStoreAndPopRemoteTempLongBytecode
	 and: [tempIndex = remoteTempIndex]) ifFalse:
		[^false].

	objectRepresentation genNewArrayOfSize: 1 initialized: false.
	self evaluate: pushValueDesc at: bytecodePC + pushArrayDesc numBytes + storeArrayDesc numBytes.
	reg := self ssStorePop: true toPreferredReg: TempReg.
	objectRepresentation
		genStoreSourceReg: reg
		slotIndex: 0
		intoNewObjectInDestReg: ReceiverResultReg.
	self ssPushRegister: ReceiverResultReg.
	self evaluate: storeArrayDesc at: bytecodePC + pushArrayDesc numBytes.
	bytecodePC := bytecodePC
					"+ pushArrayDesc numBytes this gets added by nextBytecodePCFor:at:exts:in:"
					+ storeArrayDesc numBytes
					+ pushValueDesc numBytes
					+ storeValueDesc numBytes.
	^true
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> updateSimSpillBase [
	simSpillBase > simStackPtr ifTrue:
		[simSpillBase := simStackPtr max: 0].
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> v3: descriptor Num: pc Push: nExts Nils: aMethodObj [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	^descriptor generator == #genPushConstantNilBytecode
		ifTrue: [1]
		ifFalse: [0]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> v3PushNilSize: aMethodObj numInitialNils: numInitialNils [
	<inline: true>
	^numInitialNils
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> v3or4: descriptor Num: pc Push: nExts Nils: aMethodObj [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	^bytecodeSetOffset = 0
		ifTrue: [self v3: descriptor Num: pc Push: nExts Nils: aMethodObj]
		ifFalse: [self v4: descriptor Num: pc Push: nExts Nils: aMethodObj]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> v3or4PushNilSize: aMethodObj numInitialNils: numInitialNils [
	^(coInterpreter methodUsesAlternateBytecodeSet: aMethodObj)
		ifTrue: [self v4PushNilSize: aMethodObj numInitialNils: numInitialNils]
		ifFalse: [self v3PushNilSize: aMethodObj numInitialNils: numInitialNils]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> v4: descriptor Num: pc Push: nExts Nils: aMethodObj [
	"*	77			01001101		Push false [* 1:true, 2:nil, 3:thisContext, ..., -N: pushExplicitOuter: N, N = Extend B]"
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	^(descriptor generator == #genExtPushPseudoVariableOrOuterBytecode
	   and: [self assert: (objectMemory fetchByte: pc ofObject: aMethodObj) = 77.
			nExts = 1
	   and: [(objectMemory fetchByte: pc - 1 ofObject: aMethodObj) = 2]])
		ifTrue: [1]
		ifFalse: [0]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> v4PushNilSize: aMethodObj numInitialNils: numInitialNils [
	"77			01001101				Push false [* 1:true, 2:nil, 3:thisContext, ..., -N: pushExplicitOuter: N, N = Extend B]
	 225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)"
	<inline: true>
	^3 * numInitialNils
]
