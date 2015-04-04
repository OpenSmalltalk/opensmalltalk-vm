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
		'debugBytecodePointers',
		'realCECallCogCodePopReceiverArg0Regs',
		'realCECallCogCodePopReceiverArg1Arg0Regs',
		'deadCode'
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
	  { CogSSBytecodeFixup. CogSimStackEntry. CogSSOptStatus }
]

{ #category : #documentation }
StackToRegisterMappingCogit class >> callingConvention [
	"The Smalltalk-to-Smalltalk calling convention aims to trade simplicity of compilation against
	 effectiveness of optimization.  Most Smalltalk methods, and certainly most performance-
	 critical primitives have two or less arguments.  So arranging that the receiver and up to two
	 args args are in registers arranges that performance-critical primitives can access their
	 arguments in registers.  So if the argument count is <= numRegArgs nothing is passed on
	 the stack and everything is passed in ReceiverResultReg, Arg0Reg et al.  Above numRegArgs
	 everything is passed on the stack.

	 To save the CoInterpreter from change we shuffle the retpc and push the register args in
	 the prolog so that the frame format is unchanged by register args.  Also, the trampolines for
	 unlinked sends do the same, as does the code preceeding an interpreter primitive.  It turns
	 out that this protocol is faster than always pushing arguments.  Comparing benchFib with the
	 shuffling protocol against an always-push protocol on a 2.66 GHz Core i7 (MacBook Pro) , the
	 shuffling protocol is 6.3% faster than the always push protocol.

	 Not shuffling the stack and pushing register arguments after frame build is faster yet again,
	 5.8% faster that the stack shuffle.  So it might be worth-while to change the CoInterpreter's
	 frame management to allow numArgs <= numRegArgs frames to push receiver and arguments
	 after saving the return pc.  This implies changes in stack-to-context mapping, GC,
	 interpreter-to-machine code frame conversion and no doubt else where.

	 Hence the calling convention is

		- if the number of arguments is less than or equal to numRegArgs then the receiver and arguments
		  are passed in registers.  numRegArgs is currently 1, but will become 2 once the code generator
		  generates machine code primitives which take 2 arguments (i.e. once the object representation
		  makes it feasible to implement at:put: in machine code numRegArgs will be raised to 2).  The receiver
		  is passed in ReceiverResultReg, the first argument in Arg0Reg (esi on x86) and the second argument
		  (if numRegArgs = 2) in Arg1Reg (edi on x86).

		- if the number of arguments is greater than numRegArgs then the calling convention is as for
		  SimpleStackBasedCogIt; ReceiverResultReg contains the receiver, and the receiver and arguments
		  are all on the stack, receiver furthest from top-of-stack.  If the argument count is > 2 then argument
		  count is passed in SendNumArgsReg (for the benefit of the run-time linking routines; it is ignored in
		  linked sends).

		On return the result is in ReceiverResultReg.  The callee removes arguments from the stack.

		Note that if a machine code method contains a call to an interpreter primitive it will push any register
		arguments on the stack before calling the primitive so that to the primitive the stack looks the same
		as it does in the interpreter.

		Within all machine code primitives except primitiveClosureValue all arguments are taken form registers
	 	since no machine code primitiver has more than numRegArgs arguments.  primitiveClosureValue pushes
		its register arguments immedately only for laziness to be able to reuse SimpleStackBasedCogit's code.

		Within machine code methods with interpreter primtiives the register arguments are pushed before calling
		the interpreter primitive.  In normal methods and if not already done so in [primitive code, the register
		arguments are pushed during frame build.  If a method is compiled frameless it will access its arguments
		 in registers."
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
			declareC: 'CogSimStackEntry simStack[', ((CoInterpreter bindingOf: #LargeContextSlots) value * 5 // 4) asString, ']';
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
	self flag:
'Special selector send class must be inlined to agree with the interpreter, which
 inlines class.  If class is sent to e.g. a general instance of ProtoObject then unless
 class is inlined there will be an MNU.  It must be that the Cointerpreter and Cogit
 have identical semantics.  We get away with not hardwiring the other special
 selectors either because in the Cointerpreter they are not inlined or because they
 are inlined only to instances of classes for which there will always be a method.'.
	self generatorTableFrom: #(
		"1 byte bytecodes"
		(1    0   15 genPushReceiverVariableBytecode needsFrameNever: 1)
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
		(2 224 224 extABytecode extension					needsFrameNever: 0)
		(2 225 225 extBBytecode extension					needsFrameNever: 0)
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

		(2 245 245	genExtSendAbsentSelfBytecode isMapped)

		(2 246 248	unknownBytecode)

		"3 byte bytecodes"
		(3 249 249 callPrimitiveBytecode)
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
		(1    0   15 genPushReceiverVariableBytecode			needsFrameNever: 1)
		(1  16   31 genPushLitVarDirSup16CasesBytecode	needsFrameNever: 1)
		(1  32   63 genPushLiteralConstantBytecode			needsFrameNever: 1)
		(1  64   75 genPushTemporaryVariableBytecode		needsFrameIfMod16GENumArgs: 1)
		(1  76   76 genPushReceiverBytecode					needsFrameNever: 1)
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

		"stores"
		(1 200 207 genStoreAndPopReceiverVariableBytecode needsFrameNever: -1) "N.B. not frameless if immutability"
		(1 208 215 genStoreAndPopTemporaryVariableBytecode)

		(1 216 216 genPopStackBytecode needsFrameNever: -1)

		(1 217 217 genUnconditionnalTrapBytecode isMapped)

		(1 218 223 unknownBytecode)

		"2 byte bytecodes"
		(2 224 224 extABytecode extension)
		(2 225 225 extBBytecode extension)

		"pushes"
		(2 226 226 genExtPushReceiverVariableBytecode		needsFrameNever: 1)
		(2 227 227 genExtPushLitVarDirSupBytecode			needsFrameNever: 1)
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
StackToRegisterMappingCogit class >> initializeBytecodeTableForSqueakV3PlusClosures [
	"StackToRegisterMappingCogit initializeBytecodeTableForSqueakV3PlusClosures"

	numPushNilsFunction := #v3:Num:Push:Nils:.
	pushNilSizeFunction := #v3PushNilSize:numInitialNils:.
	FirstSpecialSelector := 176.
	self flag:
'Special selector send class must be inlined to agree with the interpreter, which
 inlines class.  If class is sent to e.g. a general instance of ProtoObject then unless
 class is inlined there will be an MNU.  It must be that the Cointerpreter and Cogit
 have identical semantics.  We get away with not hardwiring the other special
 selectors either because in the Cointerpreter they are not inlined or because they
 are inlined only to instances of classes for which there will always be a method.'.
	self generatorTableFrom: #(
		(1    0   15 genPushReceiverVariableBytecode needsFrameNever: 1)
		(1  16   31 genPushTemporaryVariableBytecode needsFrameIfMod16GENumArgs: 1)
		(1  32   63 genPushLiteralConstantBytecode needsFrameNever: 1)
		(1  64   95 genPushLiteralVariableBytecode needsFrameNever: 1)
		(1  96 103 genStoreAndPopReceiverVariableBytecode needsFrameNever: -1) "N.B. not frameless if immutability"
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

	super initializeBytecodeTableForSqueakV3PlusClosuresNewspeakV4Hybrid..
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
StackToRegisterMappingCogit class >> initializeMiscConstants [
	super initializeMiscConstants.
	NumTrampolines := NewspeakVM
							ifTrue: [70]
							ifFalse: [52]
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
	^true
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
	preceeds the target of 2 jumpCond L1.  i.e. the merge base at 7 L2 is the stack pointer at 4 jump L2, which
	preceeds the target of 2 jumpCond L1.  So at 2 jumpCond L1 we copy the stack pointer to the merge base
	at 5 L1, /and/ to the preceeding 4 jump L2, and when we reach 4 jump L2, propagate the merge base to 7 L2.

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
		span: span.
	^blockStart
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> annotateBytecodeIfAnnotated: aSimStackEntry [
	<var: #aSimStackEntry type: #'CogSimStackEntry *'>
	<inline: false>
	aSimStackEntry annotateUse ifTrue:
		[self annotateBytecode: (self prevInstIsPCAnnotated
									ifTrue: [self Nop]
									ifFalse: [self Label]).
		 aSimStackEntry annotateUse: false]
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

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> availableRegister [
	| reg |
	reg := self availableRegisterOrNil.
	reg ifNil: [self error: 'no available register'].
	^reg
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> availableRegisterOrNil [
	^backEnd availableRegisterOrNilFor: self liveRegisters
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
				ceTraceStoreOf: (processor registerAt: (backEnd concreteRegister: TempReg))
				into: (processor registerAt: (backEnd concreteRegister: ReceiverResultReg))]
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileAbstractInstructionsFrom: start through: end [
	"Loop over bytecodes, dispatching to the generator for each bytecode, handling fixups in due course."
	| nextOpcodeIndex descriptor nExts fixup result |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #fixup type: #'BytecodeFixup *'>
	self traceSimStack.
	bytecodePC := start.
	nExts := 0.
	descriptor := nil.
	deadCode := false.
	[self cCode: '' inSmalltalk:
		[(debugBytecodePointers includes: bytecodePC) ifTrue: [self halt]].
	fixup := self fixupAt: bytecodePC - initialPC.
	fixup targetInstruction asUnsignedInteger > 0
		ifTrue:
			[deadCode := false.
	 		 fixup targetInstruction asUnsignedInteger >= 2 ifTrue:
				[self merge: fixup
					afterContinuation: (descriptor notNil
										and: [descriptor isUnconditionalBranch
											or: [descriptor isReturn]]) not]]
		ifFalse: "If there's no fixup following a return there's no jump to that code and it is dead."
			[(descriptor notNil and: [descriptor isReturn]) ifTrue:
				[deadCode := true]].
	 self cCode: '' inSmalltalk:
		[deadCode ifFalse:
			[self assert: simStackPtr + (needsFrame ifTrue: [0] ifFalse: [1])
						= (self debugStackPointerFor: bytecodePC)]].
	 byte0 := (objectMemory fetchByte: bytecodePC ofObject: methodObj) + bytecodeSetOffset.
	 descriptor := self generatorAt: byte0.
	 self loadSubsequentBytesForDescriptor: descriptor at: bytecodePC.
	 nextOpcodeIndex := opcodeIndex.
	 result := deadCode
				ifTrue: "insert nops for dead code that is mapped so that bc to mc mapping is not many to one"
					[(descriptor isMapped
					  or: [inBlock and: [descriptor isMappedInBlock]]) ifTrue:
						[self annotateBytecode: self Nop].
						0]
				ifFalse:
					[self perform: descriptor generator].
	 descriptor isExtension ifFalse: "extended bytecodes must consume their extensions"
		[self assert: (extA = 0 and: [extB = 0])].
	 self traceDescriptor: descriptor; traceSimStack.
	 (fixup targetInstruction asUnsignedInteger between: 1 and: 2) ifTrue:
		["There is a fixup for this bytecode.  It must point to the first generated
		   instruction for this bytecode.  If there isn't one we need to add a label."
		 opcodeIndex = nextOpcodeIndex ifTrue:
			[self Label].
		 fixup targetInstruction: (self abstractInstructionAt: nextOpcodeIndex)].
	 bytecodePC := self nextBytecodePCFor: descriptor at: bytecodePC exts: nExts in: methodObj.
	 result = 0 and: [bytecodePC <= end]] whileTrue:
		[nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0]].
	self checkEnoughOpcodes.
	^result
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileBlockBodies [
	<inline: false>
	| result compiledBlocksCount blockStart savedNeedsFrame savedNumArgs savedNumTemps
	  initialStackPtr initialOpcodeIndex initialAnnotationIndex initialIndexOfIRC |
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
		 self scanBlock: blockStart.
		 initialOpcodeIndex := opcodeIndex.
		 initialAnnotationIndex := annotationIndex.
		 self cppIf: #NewspeakVM ifTrue:
			[initialIndexOfIRC := indexOfIRC].
		 [self compileBlockEntry: blockStart.
		  initialStackPtr := simStackPtr.
		  (result := self compileAbstractInstructionsFrom: blockStart startpc + (self pushNilSize: methodObj numInitialNils: blockStart numInitialNils)
						through: blockStart startpc + blockStart span - 1) < 0 ifTrue:
			[^result].
		  "If the final simStackPtr is less than the initial simStackPtr then scanBlock: over-
		   estimated the number of initial nils (because it assumed one or more pushNils to
		   produce an operand were pushNils to initialize temps.  This is very rare, so
		   compensate by checking, adjusting numInitialNils and recompiling the block body."
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
									[:i|
									abstractOpcodes
										at: i
										put: (processor abstractInstructionCompilerClass for: self)]].
				 opcodeIndex := initialOpcodeIndex.
				 annotationIndex := initialAnnotationIndex.
				 self cppIf: #NewspeakVM ifTrue:
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
				[self
					annotate: (self MoveCw: objectMemory nilObject R: TempReg)
					objRef: objectMemory nilObject.
				 1 to: blockStart numInitialNils do:
					[:ign| self PushR: TempReg]]
			ifFalse:
				[self
					annotate: (self PushCw: objectMemory nilObject)
					objRef: objectMemory nilObject].
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
	needsFrame ifFalse:
		[self initSimStackForFramelessMethod: initialPC.
		 ^0].
	self genPushRegisterArgs.
	super compileFrameBuild.
	self initSimStackForFramefulMethod: initialPC
]

{ #category : #'in-line cacheing' }
StackToRegisterMappingCogit >> compileOpenPIC: selector numArgs: numArgs [
	"Compile the code for an open PIC.  Perform a probe of the first-level method
	 lookup cache followed by a call of ceSendFromInLineCacheMiss: if the probe fails.
	 Override to push the register args when calling ceSendFromInLineCacheMiss:"
	| jumpSelectorMiss jumpClassMiss itsAHit jumpBCMethod |
	<var: #jumpSelectorMiss type: #'AbstractInstruction *'>
	<var: #jumpClassMiss type: #'AbstractInstruction *'>
	<var: #itsAHit type: #'AbstractInstruction *'>
	<var: #jumpBCMethod type: #'AbstractInstruction *'>
	self compilePICAbort: numArgs.
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
	backEnd genPushRegisterArgsForNumArgs: numArgs.
	self genSmalltalkToCStackSwitch.
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
		[^self genSend: (self getLiteral: byte2) numArgs: (byte1 bitAnd: 31)].
	opType = 1 ifTrue:
		[^self genSendSuper: (self getLiteral: byte2) numArgs: (byte1 bitAnd: 31)].
	"We need a map entry for this bytecode for correct parsing.
	 The sends will get an IsSend entry anyway.  The other cases need a
	 fake one.  We could of course special case the scanning but that's silly."
	opType caseOf: {
			[2]	->	[(coInterpreter isReadMediatedContextInstVarIndex: byte2)
						ifTrue: [self genPushMaybeContextReceiverVariable: byte2]
						ifFalse: [self genPushReceiverVariable: byte2.
								self ssTop annotateUse: true.
								^0]].
			[3]	->	[self genPushLiteralIndex: byte2.
					 self ssTop annotateUse: true.
					 ^0].
			[4]	->	[self genPushLiteralVariable: byte2.].
			[7]	->	[self genStorePop: false LiteralVariable: byte2] }
		otherwise: "5 & 6"
			[(coInterpreter isWriteMediatedContextInstVarIndex: byte2)
				ifTrue: [self genStorePop: opType = 6 MaybeContextReceiverVariable: byte2]
				ifFalse: [self genStorePop: opType = 6 ReceiverVariable: byte2]].
	"We need a map entry for this bytecode for correct parsing (if the method builds a frame).
	 We could of course special case the scanning but that's silly (or is it?)."
	self assert: needsFrame.
	"genPushMaybeContextInstVar, pushListVar, store & storePop all generate code"
	self assert: self prevInstIsPCAnnotated not.
	self annotateBytecode: self Label.
	^0
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> duplicateTopBytecode [
	| desc |
	<var: #desc type: #CogSimStackEntry>
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
		 (fixup targetInstruction asUnsignedInteger > 1
		  and: [fixup simStackPtr > -2]) ifTrue: "ignore backward branch targets"
				[self assert: fixup simStackPtr = simStackPtr]].
	fixup targetInstruction asUnsignedInteger <= 1
		ifTrue: "convert a non-merge into a merge"
			[fixup targetInstruction: (self cCoerceSimple: 2 to: #'AbstractInstruction *').
			 fixup simStackPtr: simStackPtr]
		ifFalse:
			[fixup simStackPtr <= -2
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
	fixup targetInstruction = 0 ifTrue:
		[fixup targetInstruction: (self cCoerceSimple: 1 to: #'AbstractInstruction *')].
	self cCode: '' inSmalltalk:
		[fixup targetInstruction asUnsignedInteger > 1 ifTrue:
			[self assert:
					(fixup simStackPtr = -2 "backward branch target"
					 or: [fixup simStackPtr = (self debugStackPointerFor: targetIndex + initialPC)])]].
	^fixup
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> ensureReceiverResultRegContainsSelf [
	needsFrame
		ifTrue:
			[(optStatus isReceiverResultRegLive
			 and: [optStatus ssEntry = (self addressOf: simSelf)]) ifFalse:
				[self ssAllocateRequiredReg: ReceiverResultReg.
				 (self addressOf: simSelf) storeToReg: ReceiverResultReg].
			optStatus
				isReceiverResultRegLive: true;
				ssEntry: (self addressOf: simSelf)]
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

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> fixupAt: index [
	<cmacro: '(index) (&fixups[index])'>
	<returnTypeC: #'BytecodeFixup *'>
	(debugFixupBreaks includes: index) ifTrue:
		[self halt].
	^self addressOf: (fixups at: index)
]

{ #category : #'inline primitive generators' }
StackToRegisterMappingCogit >> genBinaryConstOpVarInlinePrimitive: prim [
	"Const op var version of binary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#binaryInlinePrimitive:"
	| ra val untaggedVal adjust |
	(ra := backEnd availableRegisterOrNilFor: self liveRegisters) ifNil:
		[self ssAllocateRequiredReg:
			(ra := optStatus isReceiverResultRegLive
					ifTrue: [Arg0Reg]
					ifFalse: [ReceiverResultReg])].
	ra = ReceiverResultReg ifTrue:
		[optStatus isReceiverResultRegLive: false].
	self ssTop popToReg: ra.
	self ssPop: 1.
	val := self ssTop constant.
	self ssPop: 1.
	untaggedVal := val - objectMemory smallIntegerTag.
	prim caseOf: {
		"0 through 6, +, -, *, /, //, \\, quo:, SmallInteger op SmallInteger => SmallInteger, no overflow"
		[0]	->	[self AddCq: untaggedVal R: ra].
		[1]	->	[self MoveCq: val R: TempReg.
				 self SubR: ra R: TempReg.
				 objectRepresentation genAddSmallIntegerTagsTo: TempReg.
				 self MoveR: TempReg R: ra].
		[2]	->	[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: ra.
				 self MoveCq: (objectMemory integerValueOf: val) R: TempReg.
				 self MulR: TempReg R: ra.
				 objectRepresentation genAddSmallIntegerTagsTo: ra].

		"2016 through 2019, bitAnd:, bitOr:, bitXor, bitShift:, SmallInteger op SmallInteger => SmallInteger, no overflow"

		"2032	through 2037, >, <, >=, <=. =, ~=, SmallInteger op SmallInteger => Boolean (flags?? then in jump bytecodes if ssTop is a flags value, just generate the instruction!!)"
		[32] -> [ self CmpCq: val R: ra.
				self genBinaryInlineComparison: JumpGreater opFalse: JumpLess destReg: ra ].
		[33] -> [ self CmpCq: val R: ra.
				self genBinaryInlineComparison: JumpLess opFalse: JumpGreater destReg: ra ].
		[34] -> [ self CmpCq: val R: ra.
				self genBinaryInlineComparison: JumpGreaterOrEqual opFalse: JumpLessOrEqual destReg: ra ].
		[35] -> [ self CmpCq: val R: ra.
				self genBinaryInlineComparison: JumpLessOrEqual opFalse: JumpGreaterOrEqual destReg: ra ].
		[36] -> [ self CmpCq: val R: ra.
				self genBinaryInlineComparison: JumpZero opFalse: JumpNonZero destReg: ra ].
		[37] -> [ self CmpCq: val R: ra.
				self genBinaryInlineComparison: JumpNonZero opFalse: JumpZero destReg: ra ].

		"2064	through 2068, Pointer Object>>at:, Byte Object>>at:, Short16 Word Object>>at: LongWord32 Object>>at: Quad64Word Object>>at:. obj op 0-rel SmallInteger => oop"
		[64] ->	[self genConvertSmallIntegerToIntegerInReg: ra.
				adjust := (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
				adjust ~= 0 ifTrue: [ self AddCq: adjust R: ra. ]. 
				self MoveCq: val R: TempReg.
				self MoveXwr: ra R: TempReg R: ra].
		[65] ->	[self genConvertSmallIntegerToIntegerInReg: ra.
				adjust := objectMemory baseHeaderSize - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
				self AddCq: adjust R: ra.
				self MoveCq: val R: TempReg.
				self MoveXbr: ra R: TempReg R: ra]

	}
	otherwise: [^EncounteredUnknownBytecode].
	self ssPushRegister: ra.
	^0
]

{ #category : #'inline primitive generators' }
StackToRegisterMappingCogit >> genBinaryInlineComparison: opTrue opFalse: opFalse destReg: destReg [
	"Inlined comparison. opTrue = jump for true and opFalse = jump for false"
	| nextPC branchDescriptor nExts |	
	nextPC := bytecodePC + 3.
	nExts := 0.	
	[branchDescriptor := self generatorAt: (objectMemory fetchByte: nextPC ofObject: methodObj) + (byte0 bitAnd: 256).
	 branchDescriptor isExtension] whileTrue:
		[nExts := nExts + 1.
	 	 nextPC := nextPC + branchDescriptor numBytes].
	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse])
		ifTrue: "This is the path where the inlined comparison is followed immediately by a branch"
			[| targetBytecodePC postBranchPC |
			targetBytecodePC := nextPC
					+ branchDescriptor numBytes
					+ (self spanFor: branchDescriptor at: nextPC exts: nExts in: methodObj).
			postBranchPC := nextPC + branchDescriptor numBytes.
			self ssPushConstant: objectMemory trueObject. "dummy object"
			self gen: (branchDescriptor isBranchTrue ifTrue: [opTrue] ifFalse: [opFalse])
				operand: (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.
			self Jump: (self ensureNonMergeFixupAt: postBranchPC - initialPC)]
		ifFalse: "This is the path where the inlined comparison is *not* followed immediately by a branch"
			[| condJump jump |
			condJump := self gen: opTrue operand: 0.
	 		self 
				annotate: (self MoveCw: objectMemory falseObject R: destReg) 
				objRef: objectMemory falseObject.
	 		jump := self Jump: 0.
			condJump jmpTarget: (self 
				annotate: (self MoveCw: objectMemory trueObject R: destReg) 
				objRef: objectMemory trueObject).
			jump jmpTarget: self Label].
	^ 0
]

{ #category : #'inline primitive generators' }
StackToRegisterMappingCogit >> genBinaryVarOpConstInlinePrimitive: prim [
	"Var op const version of inline binary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#binaryInlinePrimitive:"
	| rr val untaggedVal |
	(rr := backEnd availableRegisterOrNilFor: self liveRegisters) ifNil:
		[self ssAllocateRequiredReg:
			(rr := optStatus isReceiverResultRegLive
					ifTrue: [Arg0Reg]
					ifFalse: [ReceiverResultReg])].
	rr = ReceiverResultReg ifTrue:
		[optStatus isReceiverResultRegLive: false].
	val := self ssTop constant.
	self ssPop: 1.
	self ssTop popToReg: rr.
	self ssPop: 1.
	untaggedVal := val - objectMemory smallIntegerTag.
	prim caseOf: {
		"0 through 6, +, -, *, /, //, \\, quo:, SmallInteger op SmallInteger => SmallInteger, no overflow"
		[0]	->	[self AddCq: untaggedVal R: rr].
		[1]	->	[self SubCq: untaggedVal R: rr ].
		[2]	->	[self flag: 'could use MulCq:R'.
				 objectRepresentation genShiftAwaySmallIntegerTagsInScratchReg: rr.
				 self MoveCq: (objectMemory integerValueOf: val) R: TempReg.
				 self MulR: TempReg R: rr.
				 objectRepresentation genAddSmallIntegerTagsTo: rr].

		"2016 through 2019, bitAnd:, bitOr:, bitXor, bitShift:, SmallInteger op SmallInteger => SmallInteger, no overflow"

		"2032	through 2037, >, <, >=, <=. =, ~=, SmallInteger op SmallInteger => Boolean (flags?? then in jump bytecodes if ssTop is a flags value, just generate the instruction!!)
		Here the comparison is reversed (cst on the left, reg on the right) so I inverted opTrue and opFalse"
		[32] -> [ self CmpCq: val R: rr.
				self genBinaryInlineComparison: JumpLess opFalse: JumpGreater destReg: rr ].
		[33] -> [ self CmpCq: val R: rr.
				self genBinaryInlineComparison: JumpGreater opFalse: JumpLess destReg: rr ].
		[34] -> [ self CmpCq: val R: rr.
				self genBinaryInlineComparison: JumpLessOrEqual opFalse: JumpGreaterOrEqual destReg: rr ].
		[35] -> [ self CmpCq: val R: rr.
				self genBinaryInlineComparison: JumpGreaterOrEqual opFalse: JumpLessOrEqual destReg: rr ].
		[36] -> [ self CmpCq: val R: rr.
				self genBinaryInlineComparison: JumpNonZero opFalse: JumpZero destReg: rr ].
		[37] -> [ self CmpCq: val R: rr.
				self genBinaryInlineComparison: JumpZero opFalse: JumpNonZero destReg: rr ].

		"2064	through 2068, Pointer Object>>at:, Byte Object>>at:, Short16 Word Object>>at: LongWord32 Object>>at: Quad64Word Object>>at:. obj op 0-rel SmallInteger => oop"
		[64] ->	[self genConvertSmallIntegerToIntegerInReg: rr.
				self MoveCq: (objectMemory integerValueOf: val) + (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1 R: TempReg.
				self MoveXwr: TempReg R: rr R: rr ].
		[65] ->	[self genConvertSmallIntegerToIntegerInReg: rr.
				self MoveCq: (objectMemory integerValueOf: val) + objectMemory baseHeaderSize - 1 R: TempReg.
				self MoveXbr: TempReg R: rr R: rr ]

	}
	otherwise: [^EncounteredUnknownBytecode].
	self ssPushRegister: rr.
	^0
]

{ #category : #'inline primitive generators' }
StackToRegisterMappingCogit >> genBinaryVarOpVarInlinePrimitive: prim [
	"Var op var version of binary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#binaryInlinePrimitive:"
	| ra rr adjust |
	(rr := backEnd availableRegisterOrNilFor: self liveRegisters) ifNil:
		[self ssAllocateRequiredReg:
			(rr := optStatus isReceiverResultRegLive
					ifTrue: [Arg0Reg]
					ifFalse: [ReceiverResultReg])].
	(ra := backEnd availableRegisterOrNilFor: (self liveRegisters bitOr: (self registerMaskFor: rr))) ifNil:
		[self ssAllocateRequiredReg: (ra := Arg1Reg)].
	(rr = ReceiverResultReg or: [ra = ReceiverResultReg]) ifTrue:
		[optStatus isReceiverResultRegLive: false].
	self ssTop popToReg: ra.
	self ssPop: 1.
	self ssTop popToReg: rr.
	self ssPop: 1.
	prim caseOf: {
		"0 through 6, +, -, *, /, //, \\, quo:, SmallInteger op SmallInteger => SmallInteger, no overflow"
		[0]	->	[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: ra.
				 self AddR: ra R: rr].
		[1]	->	[self SubR: ra R: rr.
				 objectRepresentation genAddSmallIntegerTagsTo: rr].
		[2]	->	[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: rr.
				 objectRepresentation genShiftAwaySmallIntegerTagsInScratchReg: ra.
				 self MulR: ra R: rr.
				 objectRepresentation genAddSmallIntegerTagsTo: rr].

		"2016 through 2019, bitAnd:, bitOr:, bitXor, bitShift:, SmallInteger op SmallInteger => SmallInteger, no overflow"

		"2032	through 2037, >, <, >=, <=. =, ~=, SmallInteger op SmallInteger => Boolean (flags?? then in jump bytecodes if ssTop is a flags value, just generate the instruction!!)"
		[32] -> [ self CmpR: rr R: ra.
				self genBinaryInlineComparison: JumpGreater opFalse: JumpLess destReg: rr ].
		[33] -> [ self CmpR: rr R: ra.
				self genBinaryInlineComparison: JumpLess opFalse: JumpGreater destReg: rr ].
		[34] -> [ self CmpR: rr R: ra.
				self genBinaryInlineComparison: JumpGreaterOrEqual opFalse: JumpLessOrEqual destReg: rr ].
		[35] -> [ self CmpR: rr R: ra.
				self genBinaryInlineComparison: JumpLessOrEqual opFalse: JumpGreaterOrEqual destReg: rr ].
		[36] -> [ self CmpR: rr R: ra.
				self genBinaryInlineComparison: JumpZero opFalse: JumpNonZero destReg: rr ].
		[37] -> [ self CmpR: rr R: ra.
				self genBinaryInlineComparison: JumpNonZero opFalse: JumpZero destReg: rr ].

		"2064	through 2068, Pointer Object>>at:, Byte Object>>at:, Short16 Word Object>>at: LongWord32 Object>>at: Quad64Word Object>>at:. obj op 0-rel SmallInteger => oop"
		[64] ->	[self genConvertSmallIntegerToIntegerInReg: ra.
				adjust := (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
				adjust ~= 0 ifTrue: [ self AddCq: adjust R: ra. ]. 
				self MoveXwr: ra R: rr R: rr ].
		[65] ->	[self genConvertSmallIntegerToIntegerInReg: ra.
				adjust := objectMemory baseHeaderSize - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
				self AddCq: adjust R: ra.
				self MoveXbr: ra R: rr R: rr ]

	}
	otherwise: [^EncounteredUnknownBytecode].
	self ssPushRegister: rr.
	^0
]

{ #category : #initialization }
StackToRegisterMappingCogit >> genCallPICEnilopmartNumArgs: numArgs [
	"Generate special versions of the ceCallCogCodePopReceiverAndClassRegs
	 enilopmart that also pop register args from the stack to undo the pushing of
	 register args in the abort/miss trampolines."
	<returnTypeC: 'void (*genCallPICEnilopmartNumArgs(sqInt numArgs))(void)'>
	| size endAddress enilopmart |
	opcodeIndex := 0.
	backEnd maybeEstablishVarBase. "Must happen first; value may be used in genLoadStackPointers"
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
	backEnd nopsFrom: endAddress to: methodZoneBase - 1.
	self recordGeneratedRunTime: (self trampolineName: 'ceCallPIC' numArgs: numArgs) address: enilopmart.
	^self cCoerceSimple: enilopmart to: #'void (*)(void)'
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genCallPrimitiveBytecode [
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#inlinePrimitiveBytecode:"
	| prim |
	byte2 < 128 ifTrue:
		[^EncounteredUnknownBytecode].
	prim := byte2 - 128 << 8 + byte1.

	prim < 1000 ifTrue:
		[^self genNullaryInlinePrimitive: prim].

	prim < 2000 ifTrue:
		[^self genUnaryInlinePrimitive: prim - 1000].
		
	prim < 3000 ifTrue:
		[self ssTop type = SSConstant ifTrue:
			[^self genBinaryVarOpConstInlinePrimitive: prim - 2000].
		 (self ssValue: 1) type = SSConstant ifTrue:
			[^self genBinaryConstOpVarInlinePrimitive: prim - 2000].
		 ^self genBinaryVarOpVarInlinePrimitive: prim - 2000].

	prim < 4000 ifTrue:
		[^self genTrinaryInlinePrimitive: prim - 3000].

	^EncounteredUnknownBytecode
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genDoubleArithmetic: arithmeticOperator preOpCheck: preOpCheckOrNil [
	"Receiver and arg in registers.
	 Stack looks like
		return address"
	<var: #preOpCheckOrNil declareC: 'AbstractInstruction *(*preOpCheckOrNil)(int rcvrReg, int argReg)'>
	| jumpFailClass jumpFailAlloc jumpFailCheck jumpImmediate jumpNonInt doOp |
	<var: #jumpFailClass type: #'AbstractInstruction *'>
	<var: #jumpFailAlloc type: #'AbstractInstruction *'>
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	<var: #jumpNonInt type: #'AbstractInstruction *'>
	<var: #jumpFailCheck type: #'AbstractInstruction *'>
	<var: #doOp type: #'AbstractInstruction *'>
	self MoveR: Arg0Reg R: TempReg.
	objectRepresentation genGetDoubleValueOf: ReceiverResultReg into: DPFPReg0.
	self MoveR: Arg0Reg R: ClassReg.
	jumpImmediate := objectRepresentation genJumpImmediateInScratchReg: TempReg.
	objectRepresentation genGetCompactClassIndexNonImmOf: Arg0Reg into: SendNumArgsReg.
	objectRepresentation genCmpClassFloatCompactIndexR: SendNumArgsReg.
	jumpFailClass := self JumpNonZero: 0.
	objectRepresentation genGetDoubleValueOf: Arg0Reg into: DPFPReg1.
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
	self RetN: 0.
	"We need to push the register args on two paths; this one and the interpreter primitive path.
	But the interpreter primitive path won't unless regArgsHaveBeenPushed is false."
	self assert: methodOrBlockNumArgs <= self numRegArgs.
	jumpFailClass jmpTarget: self Label.
	preOpCheckOrNil ifNotNil:
		[jumpFailCheck jmpTarget: jumpFailClass getJmpTarget].
	backEnd genPushRegisterArgsForNumArgs: methodOrBlockNumArgs.
	jumpFailClass := self Jump: 0.
	jumpImmediate jmpTarget: self Label.
	objectRepresentation smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg].
	objectRepresentation genConvertSmallIntegerToIntegerInReg: ClassReg.
	self ConvertR: ClassReg Rd: DPFPReg1.
	self Jump: doOp.
	jumpFailAlloc jmpTarget: self Label.
	self compileFallbackToInterpreterPrimitive.
	jumpFailClass jmpTarget: self Label.
	objectRepresentation smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt jmpTarget: jumpFailClass getJmpTarget].
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genDoubleComparison: jumpOpcodeGenerator invert: invertComparison [
	"Receiver and arg in registers.
	 Stack looks like
		return address"
	<var: #jumpOpcodeGenerator declareC: 'AbstractInstruction *(*jumpOpcodeGenerator)(void *)'>
	| jumpFail jumpImmediate jumpNonInt jumpCond compare |
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	<var: #jumpNonInt type: #'AbstractInstruction *'>
	<var: #jumpCond type: #'AbstractInstruction *'>
	<var: #compare type: #'AbstractInstruction *'>
	<var: #jumpFail type: #'AbstractInstruction *'>
	self MoveR: Arg0Reg R: TempReg.
	objectRepresentation genGetDoubleValueOf: ReceiverResultReg into: DPFPReg0.
	jumpImmediate := objectRepresentation genJumpImmediateInScratchReg: TempReg.
	objectRepresentation genGetCompactClassIndexNonImmOf: Arg0Reg into: SendNumArgsReg.
	objectRepresentation genCmpClassFloatCompactIndexR: SendNumArgsReg.
	jumpFail := self JumpNonZero: 0.
	objectRepresentation genGetDoubleValueOf: Arg0Reg into: DPFPReg1.
	invertComparison "May need to invert for NaNs"
		ifTrue: [compare := self CmpRd: DPFPReg0 Rd: DPFPReg1]
		ifFalse: [compare := self CmpRd: DPFPReg1 Rd: DPFPReg0].
	jumpCond := self perform: jumpOpcodeGenerator with: 0. "FP jumps are a little weird"
	self annotate: (self MoveCw: objectMemory falseObject R: ReceiverResultReg)
		objRef: objectMemory falseObject.
	self RetN: 0.
	jumpCond jmpTarget: (self annotate: (self MoveCw: objectMemory trueObject R: ReceiverResultReg)
								objRef: objectMemory trueObject).
	self RetN: 0.
	jumpImmediate jmpTarget: self Label.
	objectRepresentation smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg].
	objectRepresentation genConvertSmallIntegerToIntegerInReg: Arg0Reg.
	self ConvertR: Arg0Reg Rd: DPFPReg1.
	self Jump: compare.
	jumpFail jmpTarget: self Label.
	objectRepresentation smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt jmpTarget: jumpFail getJmpTarget].
	^0
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genExtPushClosureBytecode [
	"Block compilation.  At this point in the method create the block.  Note its start
	 and defer generating code for it until after the method and any other preceeding
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

	objectRepresentation createsClosuresInline ifTrue:
		[self assert: objectRepresentation getActiveContextAllocatesInMachineCode.
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
		 ^self ssPushRegister: ReceiverResultReg].

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
	^self ssPushRegister: ReceiverResultReg
]

{ #category : #'trampoline support' }
StackToRegisterMappingCogit >> genExternalizePointersForPrimitiveCall [
	" Override to push the register receiver and register arguments, if any."
	self genPushRegisterArgs.
	^super genExternalizePointersForPrimitiveCall
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genFramelessStorePop: popBoolean ReceiverVariable: slotIndex [
	<inline: false>
	| topReg valueReg constVal |
	self assert: needsFrame not.
	self ssFlushUpThroughReceiverVariable: slotIndex.
	"Avoid store check for immediate values"
	constVal := self ssTop maybeConstant.
	(self ssTop type = SSConstant
	 and: [(objectRepresentation shouldAnnotateObjectReference: constVal) not]) ifTrue:
		[self ensureReceiverResultRegContainsSelf.
		 self ssStorePop: popBoolean toPreferredReg: TempReg.
		 traceStores > 0 ifTrue:
			[backEnd saveAndRestoreLinkRegAround:
				[self CallRT: ceTraceStoreTrampoline]].
		 ^objectRepresentation
			genStoreImmediateInSourceReg: TempReg
			slotIndex: slotIndex
			destReg: ReceiverResultReg].
	(topReg := self ssTop registerOrNil) isNil ifTrue:
		[topReg := ClassReg].
	valueReg := self ssStorePop: popBoolean toPreferredReg: topReg.
	"Note that ReceiverResultReg remains live after ceStoreCheckTrampoline."
	self ensureReceiverResultRegContainsSelf.
	 traceStores > 0 ifTrue:
		[self MoveR: valueReg R: TempReg.
		 backEnd saveAndRestoreLinkRegAround:
			[self CallRT: ceTraceStoreTrampoline]].
	^objectRepresentation
		genStoreSourceReg: valueReg
		slotIndex: slotIndex
		destReg: ReceiverResultReg
		scratchReg: TempReg
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genJumpBackTo: targetBytecodePC [
	self ssFlushTo: simStackPtr.
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
		 "Must enter any annotatedConstants into the map"
		 desc annotateUse ifTrue:
			[self annotateBytecode: (self prevInstIsPCAnnotated
											ifTrue: [self Nop]
											ifFalse: [self Label])].
		 "Must annotate the bytecode for correct pc mapping."
		 self annotateBytecode: (desc constant = boolean
									ifTrue: [self Jump: fixup]
									ifFalse: [self prevInstIsPCAnnotated
												ifTrue: [self Nop]
												ifFalse: [self Label]]).
		 ^0].
	desc popToReg: TempReg.
	"Cunning trick by LPD.  If true and false are contiguous subtract the smaller.
	 Correct result is either 0 or the distance between them.  If result is not 0 or
	 their distance send mustBeBoolean."
	self assert: (objectMemory objectAfter: objectMemory falseObject) = objectMemory trueObject.
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

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genJumpTo: targetBytecodePC [
	self ssFlushTo: simStackPtr.
	^super genJumpTo: targetBytecodePC
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genMarshalledSend: selector numArgs: numArgs sendTable: sendTable [
	<inline: false>
	<var: #sendTable type: #'sqInt *'>
	| annotation |
	(objectMemory isYoung: selector) ifTrue:
		[hasYoungReferent := true].
	self assert: needsFrame.
	annotation := self annotationForSendTable: sendTable.
	numArgs > 2 ifTrue:
		[self MoveCq: numArgs R: SendNumArgsReg].
	self MoveCw: selector R: ClassReg.
	self annotate: (self Call: (sendTable at: (numArgs min: NumSendTrampolines - 1)))
		with: annotation.
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
	opcodeIndex := 0.
	self CmpCq: 0 R: ReceiverResultReg.
	jumpSICMiss := self JumpNonZero: 0.

	"The abort sequencer has pushed the LinkReg a second time.
	 Overwrite it with the right one."
	backEnd hasLinkRegister ifTrue:
		[self MoveR: LinkReg Mw: 0 r: SPReg].
	self compileTrampolineFor: #ceStackOverflow:
		numArgs: 1
		arg: SendNumArgsReg
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
		pushLinkReg: false "The LinkReg has already been set above."
		resultReg: nil.
	jumpSICMiss jmpTarget: self Label.
	backEnd genPushRegisterArgsForAbortMissNumArgs: numArgs.
	^self genTrampolineFor: #ceSICMiss:
		called: (self trampolineName: 'ceMethodAbort' numArgs: (numArgs <= self numRegArgs ifTrue: [numArgs] ifFalse: [-1]))
		numArgs: 1
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
		pushLinkReg: false "The LinkReg will have been pushed in genPushRegisterArgsForAbortMissNumArgs: above."
		resultReg: nil
		appendOpcodes: true
]

{ #category : #'inline primitive generators' }
StackToRegisterMappingCogit >> genNullaryInlinePrimitive: prim [
	"Nullary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#nullaryInlinePrimitive:"

	^EncounteredUnknownBytecode
]

{ #category : #initialization }
StackToRegisterMappingCogit >> genPICAbortTrampolineFor: numArgs [
	"Generate the abort for a PIC.  This abort performs either a call of
	 ceInterpretMethodFromPIC:receiver: to handle invoking an uncogged
	 target or a call of ceMNUFromPICMNUMethod:receiver: to handle an
	 MNU dispatch in a closed PIC.  It distinguishes the two by testing
	 ClassReg.  If the register is zero then this is an MNU."
	opcodeIndex := 0. 
	backEnd genPushRegisterArgsForAbortMissNumArgs: numArgs.
	^self genInnerPICAbortTrampoline: (self trampolineName: 'cePICAbort' numArgs: (numArgs <= self numRegArgs ifTrue: [numArgs] ifFalse: [-1]))
]

{ #category : #initialization }
StackToRegisterMappingCogit >> genPICMissTrampolineFor: numArgs [
	<inline: false>
	| startAddress |
	startAddress := methodZoneBase.
	opcodeIndex := 0.
	"N.B. a closed PIC jumps to the miss routine, not calls it, so there is only one retpc on the stack."
	backEnd genPushRegisterArgsForNumArgs: numArgs.
	self genTrampolineFor: #ceCPICMiss:receiver:
		called: (self trampolineName: 'cePICMiss' numArgs: (numArgs <= self numRegArgs ifTrue: [numArgs] ifFalse: [-1]))
		numArgs: 2
		arg: ClassReg
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		saveRegs: false
		pushLinkReg: true
		resultReg: nil
		appendOpcodes: true.
	^startAddress
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPopStackBytecode [
	self annotateBytecodeIfAnnotated: self ssTop.
	self ssTop spilled ifTrue:
		[self AddCq: objectMemory wordSize R: SPReg].
	self ssPop: 1.
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveAdd [
	| jumpNotSI jumpOvfl |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpOvfl type: #'AbstractInstruction *'>
	self MoveR: Arg0Reg R: TempReg.
	self MoveR: Arg0Reg R: ClassReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	objectRepresentation genRemoveSmallIntegerTagsInScratchReg: ClassReg.
	self AddR: ReceiverResultReg R: ClassReg.
	jumpOvfl := self JumpOverflow: 0.
	self MoveR: ClassReg R: ReceiverResultReg.
	self RetN: 0.
	jumpOvfl jmpTarget: (jumpNotSI jmpTarget: self Label).
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveAsCharacter [
	| na r |
	na := coInterpreter argumentCountOf: methodObj.
	na <= 1 ifTrue:
		[(r := objectRepresentation
				genInnerPrimitiveAsCharacter: 0
				inReg: (na = 0 ifTrue: [ReceiverResultReg] ifFalse: [Arg0Reg])) < 0 ifTrue:
			[^r]].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveAsFloat [
	| jumpFailAlloc |
	<var: #jumpFailAlloc type: #'AbstractInstruction *'>
	self MoveR: ReceiverResultReg R: TempReg.
	objectRepresentation genConvertSmallIntegerToIntegerInReg: TempReg.
	self ConvertR: TempReg Rd: DPFPReg0.
	jumpFailAlloc := objectRepresentation
						genAllocFloatValue: DPFPReg0
						into: SendNumArgsReg
						scratchReg: ClassReg
						scratchReg: TempReg.
	self MoveR: SendNumArgsReg R: ReceiverResultReg.
	self RetN: 0.
	jumpFailAlloc jmpTarget: self Label.
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveAt [
	| r |
	self assert: self numRegArgs >= 1.
	(r := objectRepresentation genInnerPrimitiveAt: 0) < 0 ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveAtPut [
	| r |
	((r := objectRepresentation genInnerPrimitiveAtPut: 0) < 0
	 and: [r ~= UnimplementedPrimitive]) ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveBitAnd [
	| jumpNotSI |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	self MoveR: Arg0Reg R: TempReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	"Whether the SmallInteger tags are zero or non-zero, oring them together will preserve them."
	self AndR: Arg0Reg R: ReceiverResultReg.
	self RetN: 0.
	jumpNotSI jmpTarget: self Label.
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveBitOr [
	| jumpNotSI |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	self MoveR: Arg0Reg R: TempReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	"Whether the SmallInteger tags are zero or non-zero, oring them together will preserve them."
	self OrR: Arg0Reg R: ReceiverResultReg.
	self RetN: 0.
	jumpNotSI jmpTarget: self Label.
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveBitShift [
	"Receiver and arg in registers.
	 Stack looks like
		return address

	rTemp := rArg0
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
	self assert: self numRegArgs >= 1.
	self MoveR: Arg0Reg R: TempReg.
	self MoveR: Arg0Reg R: ClassReg.
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
	self RetN: 0.
	jumpNegative jmpTarget: (self NegateR: ClassReg).
	self CmpCq: objectRepresentation numSmallIntegerBits R: ClassReg. "N.B. FLAGS := ClassReg - 31"
	jumpInRange := self JumpLessOrEqual: 0.
	self MoveCq: objectRepresentation numSmallIntegerBits R: ClassReg.
	jumpInRange jmpTarget: (self ArithmeticShiftRightR: ClassReg R: ReceiverResultReg).
	objectRepresentation genSetSmallIntegerTagsIn: ReceiverResultReg.
	self RetN: 0.
	jumpNotSI jmpTarget: (jumpTooBig jmpTarget: (jumpOvfl jmpTarget: self Label)).
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveBitXor [
	| jumpNotSI |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	self MoveR: Arg0Reg R: TempReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	"Clear one or the other tag so that xoring will preserve them."
	objectRepresentation genRemoveSmallIntegerTagsInScratchReg: Arg0Reg.
	self XorR: Arg0Reg R: ReceiverResultReg.
	self RetN: 0.
	jumpNotSI jmpTarget: self Label.
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveCharacterValue [
	| r |
	(r := objectRepresentation genInnerPrimitiveCharacterValue: 0) < 0 ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveClass [
	"Depending on argument count the argument is either
		0 args: ReceiverResultReg
		1 args: Arg0Reg
		N args: top of stack (assuming 1 reg arg for now)"
	| reg |
	methodOrBlockNumArgs = 1
		ifTrue:
			[reg := Arg0Reg]
		ifFalse:
			[methodOrBlockNumArgs > 0 ifTrue:
				[self MoveMw: objectMemory wordSize r: SPReg R: ReceiverResultReg].
			reg := ReceiverResultReg].
	(objectRepresentation
			genGetClassObjectOf: reg
			into: ReceiverResultReg
			scratchReg: TempReg
			instRegIsReceiver: methodOrBlockNumArgs = 0) = BadRegisterSet ifTrue:
		[objectRepresentation
			genGetClassObjectOf: reg
			into: ClassReg
			scratchReg: TempReg
			instRegIsReceiver: methodOrBlockNumArgs = 0.
		 self MoveR: ClassReg R: ReceiverResultReg].
	self RetN: 0.
	^0
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
StackToRegisterMappingCogit >> genPrimitiveDiv [
	| jumpNotSI jumpZero jumpExact jumpSameSign convert |
	<var: #convert type: #'AbstractInstruction *'>
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpExact type: #'AbstractInstruction *'>
	<var: #jumpSameSign type: #'AbstractInstruction *'>
	self MoveR: Arg0Reg R: TempReg.
	self MoveR: Arg0Reg R: ClassReg.
	self MoveR: Arg0Reg R: Arg1Reg.
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
	self RetN: 0.
	"test for overflow; the only case is SmallInteger minVal // -1"
	jumpExact jmpTarget:
		(self CmpCq: (1 << (objectRepresentation numSmallIntegerBits - 1)) R: TempReg).
	self JumpLess: convert.
	jumpZero jmpTarget: (jumpNotSI jmpTarget: self Label).
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveDivide [
	| jumpNotSI jumpZero jumpInexact jumpOverflow |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpInexact type: #'AbstractInstruction *'>
	<var: #jumpOverflow type: #'AbstractInstruction *'>
	self MoveR: Arg0Reg R: TempReg.
	self MoveR: Arg0Reg R: ClassReg.
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
	self RetN: 0.
	jumpOverflow jmpTarget: (jumpInexact jmpTarget: (jumpZero jmpTarget: (jumpNotSI jmpTarget: self Label))).
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveFloatSquareRoot [
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
	self RetN: 0.
	jumpFailAlloc jmpTarget: self Label.
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveIdentical [
	"Receiver and arg in registers.
	 Stack looks like
		return address"
	^objectRepresentation
		genInnerPrimitiveIdentical: 0
		orNotIf: false
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveIdentityHash [
	| r |
	(r := objectRepresentation genInnerPrimitiveIdentityHash: 0) < 0 ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveMod [
	| jumpNotSI jumpZero jumpExact jumpSameSign |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpExact type: #'AbstractInstruction *'>
	<var: #jumpSameSign type: #'AbstractInstruction *'>
	self MoveR: Arg0Reg R: TempReg.
	self MoveR: Arg0Reg R: ClassReg.
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
	self RetN: 0.
	jumpZero jmpTarget: (jumpNotSI jmpTarget: self Label).
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveMultiply [
	| jumpNotSI jumpOvfl |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpOvfl type: #'AbstractInstruction *'>
	self MoveR: Arg0Reg R: TempReg.
	self MoveR: Arg0Reg R: ClassReg.
	self MoveR: ReceiverResultReg R: Arg1Reg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	objectRepresentation genShiftAwaySmallIntegerTagsInScratchReg: ClassReg.
	objectRepresentation genRemoveSmallIntegerTagsInScratchReg: Arg1Reg.
	self MulR: Arg1Reg R: ClassReg.
	jumpOvfl := self JumpOverflow: 0.
	objectRepresentation genSetSmallIntegerTagsIn: ClassReg.
	self MoveR: ClassReg R: ReceiverResultReg.
	self RetN: 0.
	jumpOvfl jmpTarget: (jumpNotSI jmpTarget: self Label).
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveNew [
	| r numArgs |
	NewspeakVM
		ifTrue:
			[numArgs := coInterpreter argumentCountOf: methodObj.
			 numArgs = 1 ifTrue:
				[((r := objectRepresentation genInnerPrimitiveMirrorNew: 0) < 0
				  and: [r ~= UnimplementedPrimitive]) ifTrue:
					[^r]].
			 numArgs = 0 ifTrue:
				[((r := objectRepresentation genInnerPrimitiveNew: 0) < 0
				  and: [r ~= UnimplementedPrimitive]) ifTrue:
					[^r]]]
		ifFalse:
			[((r := objectRepresentation genInnerPrimitiveNew: 0) < 0
			  and: [r ~= UnimplementedPrimitive]) ifTrue:
				[^r]].
	"Call the interpreter primitive either when the machine-code primitive
	 fails, or if the machine-code primitive is unimplemented."
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveNewWithArg [
	| r numArgs |
	NewspeakVM
		ifTrue:
			[numArgs := coInterpreter argumentCountOf: methodObj.
			 numArgs = 2 ifTrue:
				[((r := objectRepresentation genInnerPrimitiveMirrorNewWithArg: 0) < 0
				  and: [r ~= UnimplementedPrimitive]) ifTrue:
					[^r]].
			 numArgs = 1 ifTrue:
				[((r := objectRepresentation genInnerPrimitiveNewWithArg: 0) < 0
				  and: [r ~= UnimplementedPrimitive]) ifTrue:
					[^r]]]
		ifFalse:
			[((r := objectRepresentation genInnerPrimitiveNewWithArg: 0) < 0
			  and: [r ~= UnimplementedPrimitive]) ifTrue:
				[^r]].
	"Call the interpreter primitive either when the machine-code primitive
	 fails, or if the machine-code primitive is unimplemented."
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveNotIdentical [
	"Receiver and arg in registers.
	 Stack looks like
		return address"
	^objectRepresentation
		genInnerPrimitiveIdentical: 0
		orNotIf: true
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveQuo [
	| jumpNotSI jumpZero jumpOverflow |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpOverflow type: #'AbstractInstruction *'>
	self MoveR: Arg0Reg R: TempReg.
	self MoveR: Arg0Reg R: ClassReg.
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
	self RetN: 0.
	jumpOverflow jmpTarget: (jumpZero jmpTarget: (jumpNotSI jmpTarget: self Label)).
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveSize [
	| r |
	(r := objectRepresentation genInnerPrimitiveSize: 0) < 0 ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveStringAt [
	| r |
	self assert: self numRegArgs >= 1.
	(r := objectRepresentation genInnerPrimitiveStringAt: 0) < 0 ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveStringAtPut [
	| r |
	((r := objectRepresentation genInnerPrimitiveStringAtPut: 0) < 0
	 and: [r ~= UnimplementedPrimitive]) ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveSubtract [
	| jumpNotSI jumpOvfl |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpOvfl type: #'AbstractInstruction *'>
	self MoveR: Arg0Reg R: TempReg.
	jumpNotSI := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	self MoveR: ReceiverResultReg R: TempReg.
	self SubR: Arg0Reg R: TempReg.
	jumpOvfl := self JumpOverflow: 0.
	objectRepresentation genAddSmallIntegerTagsTo: TempReg.
	self MoveR: TempReg R: ReceiverResultReg.
	self RetN: 0.
	jumpOvfl jmpTarget: (jumpNotSI jmpTarget: self Label).
	^0
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
	 and defer generating code for it until after the method and any other preceeding
	 blocks.  The block's actual code will be compiled later."
	"143   10001111 llllkkkk jjjjjjjj iiiiiiii	Push Closure Num Copied llll Num Args kkkk BlockSize jjjjjjjjiiiiiiii"
	| startpc numArgs numCopied |
	self assert: needsFrame.
	startpc := bytecodePC + (self generatorAt: byte0) numBytes.
	self addBlockStartAt: startpc "0 relative"
		numArgs: (numArgs := byte1 bitAnd: 16rF)
		numCopied: (numCopied := byte1 >> 4)
		span: (byte2 << 8) + byte3.

	objectRepresentation createsClosuresInline ifTrue:
		[self assert: objectRepresentation getActiveContextAllocatesInMachineCode.
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
		 ^self ssPushRegister: ReceiverResultReg].

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
	^self ssPushRegister: ReceiverResultReg
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genPushEnclosingObjectAt: level [
	"Uncached push enclosing object"
	optStatus isReceiverResultRegLive: false.
	self ssAllocateCallReg: SendNumArgsReg.
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
	freeReg := self ssAllocatePreferredReg: ClassReg.
	association := self getLiteral: literalIndex.
	"N.B. Do _not_ use ReceiverResultReg to avoid overwriting receiver in assignment in frameless methods."
	"So far descriptors are not rich enough to describe the entire dereference so generate the register
	 load but don't push the result.  There is an order-of-evaluation issue if we defer the dereference."
	self annotate: (self MoveCw: association R: TempReg) objRef: association.
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
StackToRegisterMappingCogit >> genPushMaybeContextReceiverVariable: slotIndex [ 
	<inline: false>
	| jmpSingle jmpDone |
	<var: #jmpSingle type: #'AbstractInstruction *'>
	<var: #jmpDone type: #'AbstractInstruction *'>
	self assert: needsFrame.
	self ssAllocateCallReg: ReceiverResultReg and: SendNumArgsReg.
	self ensureReceiverResultRegContainsSelf.
	((self registerMaskFor: ReceiverResultReg) anyMask: callerSavedRegMask) ifTrue:
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
	(optStatus isReceiverResultRegLive
	  and: [optStatus ssEntry = (self addressOf: simSelf)]) ifTrue:
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
		[backEnd genPushRegisterArgsForNumArgs: methodOrBlockNumArgs.
		regArgsHaveBeenPushed := true]
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPushRemoteTempLongBytecode [
	self ssAllocateRequiredReg: ClassReg and: SendNumArgsReg.
	self MoveMw: (self frameOffsetOfTemporary: byte2) r: FPReg R: ClassReg.
	objectRepresentation
		genLoadSlot: byte1
		sourceReg: ClassReg
		destReg: SendNumArgsReg.
	^self ssPushRegister: SendNumArgsReg
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genPushTemporaryVariable: index [
	"If a frameless method (not a block), only argument temps can be accessed.
	 This is assured by the use of needsFrameIfMod16GENumArgs: in pushTemp."
	self assert: (inBlock or: [needsFrame or: [index < methodOrBlockNumArgs]]).
	^self ssPushDesc: (simStack at: index)
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
StackToRegisterMappingCogit >> genSend: selector numArgs: numArgs [
	self marshallSendArguments: numArgs.
	^self genMarshalledSend: selector numArgs: numArgs sendTable: ordinarySendTrampolines
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSendAbsentDynamicSuper: selector numArgs: numArgs [
	<inline: false>
	self marshallAbsentReceiverSendArguments: numArgs.
	^self genMarshalledSend: selector numArgs: numArgs sendTable: dynamicSuperSendTrampolines
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSendAbsentImplicitOrOuter: selector numArgs: numArgs depth: depth sendTable: sendTable [
	<var: #sendTable type: #'sqInt *'>
	| nsSendCache |
	(objectMemory isYoung: selector) ifTrue:
		[hasYoungReferent := true].

	nsSendCache := theIRCs + (NumOopsPerNSC * objectMemory bytesPerOop * indexOfIRC).
	indexOfIRC := indexOfIRC + 1.
	self assert: (objectMemory isInOldSpace: nsSendCache).
	self initializeNSSendCache: nsSendCache selector: selector numArgs: numArgs depth: depth.

	self ssAllocateCallReg: SendNumArgsReg.

	"This leaves the method receiver on the stack, which might not be the implicit receiver. But we care
	 not: the callee will use ReceiverResultReg to build its frame, not the value beneath the arguments."
	self marshallAbsentReceiverSendArguments: numArgs.

	"Load the cache last so it is a fixed distance from the call."
	self MoveCw: nsSendCache R: SendNumArgsReg.
	self CallNewspeakSend: (sendTable at: (numArgs min: NumSendTrampolines - 1)).

	optStatus isReceiverResultRegLive: false.
	self ssPushRegister: ReceiverResultReg.
	^0
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSendAbsentSelf: selector numArgs: numArgs [
	<inline: false>
	self marshallAbsentReceiverSendArguments: numArgs.
	^self genMarshalledSend: selector numArgs: numArgs sendTable: selfSendTrampolines
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genSendDirectedSuper: selector numArgs: numArgs [
	self halt: 'do all that good stuff moving the literal variable to an argument reg, etc...'.
	self marshallSendArguments: numArgs.
	^self genMarshalledSend: selector numArgs: numArgs sendTable: superSendTrampolines
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genSendDynamicSuper: selector numArgs: numArgs [
	self marshallSendArguments: numArgs.
	^self genMarshalledSend: selector numArgs: numArgs sendTable: dynamicSuperSendTrampolines
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genSendSuper: selector numArgs: numArgs [
	self marshallSendArguments: numArgs.
	^self genMarshalledSend: selector numArgs: numArgs sendTable: superSendTrampolines
]

{ #category : #initialization }
StackToRegisterMappingCogit >> genSendTrampolineFor: aRoutine numArgs: numArgs called: aString arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 [
	"Generate a trampoline with three arguments.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	| startAddress |
	<inline: false>
	startAddress := methodZoneBase.
	opcodeIndex := 0.
	backEnd genPushRegisterArgsForNumArgs: numArgs.
	self genTrampolineFor: aRoutine
		called: aString
		numArgs: 3
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: nil
		saveRegs: false
		pushLinkReg: true
		resultReg: nil
		appendOpcodes: true.
	^startAddress
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
	opcodeIndex := 0.
	backEnd genPushRegisterArgsForNumArgs: numArgs.
	self genTrampolineFor: aRoutine
		called: aString
		numArgs: 4
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: regOrConst3
		saveRegs: false
		pushLinkReg: true
		resultReg: nil
		appendOpcodes: true.
	^startAddress
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genSmallIntegerComparison: jumpOpcode [
	| jumpFail jumpTrue |
	<var: #jumpFail type: #'AbstractInstruction *'>
	<var: #jumpTrue type: #'AbstractInstruction *'>
	self MoveR: Arg0Reg R: TempReg.
	jumpFail := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	self CmpR: Arg0Reg R: ReceiverResultReg. "N.B. FLAGS := RRReg - Arg0Reg"
	jumpTrue := self gen: jumpOpcode.
	self annotate: (self MoveCw: objectMemory falseObject R: ReceiverResultReg)
		objRef: objectMemory falseObject.
	self RetN: 0.
	jumpTrue jmpTarget: (self annotate: (self MoveCw: objectMemory trueObject R: ReceiverResultReg)
								objRef: objectMemory trueObject).
	self RetN: 0.
	jumpFail jmpTarget: self Label.
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genSmallIntegerComparison: jumpOpcode orDoubleComparison: jumpFPOpcodeGenerator [
	"Stack looks like
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
	self MoveR: Arg0Reg R: TempReg.
	jumpDouble := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	self CmpR: Arg0Reg R: ReceiverResultReg. "N.B. FLAGS := RRReg - Arg0Reg"
	jumpTrue := self gen: jumpOpcode.
	self annotate: (self MoveCw: objectMemory falseObject R: ReceiverResultReg)
		objRef: objectMemory falseObject.
	self RetN: 0.
	jumpTrue jmpTarget: (self annotate: (self MoveCw: objectMemory trueObject R: ReceiverResultReg)
								objRef: objectMemory trueObject).
	self RetN: 0.
	
	"Argument may be a Float : let us check or fail"
	jumpDouble jmpTarget: self Label.
	objectRepresentation smallIntegerIsOnlyImmediateType ifFalse:
		[self MoveR: ClassReg R: TempReg.
		 jumpNonInt := objectRepresentation genJumpImmediateInScratchReg: TempReg].
	objectRepresentation genGetCompactClassIndexNonImmOf: Arg0Reg into: SendNumArgsReg.
	objectRepresentation genCmpClassFloatCompactIndexR: SendNumArgsReg.
	jumpFail := self JumpNonZero: 0.

	"It was a Float, so convert the receiver to double and perform the operation"
	objectRepresentation genConvertSmallIntegerToIntegerInReg: ReceiverResultReg.
	self ConvertR: ReceiverResultReg Rd: DPFPReg0.
	objectRepresentation genGetDoubleValueOf: Arg0Reg into: DPFPReg1.
	self CmpRd: DPFPReg1 Rd: DPFPReg0.
	jumpCond := self perform: jumpFPOpcodeGenerator with: 0. "FP jumps are a little weird"
	self annotate: (self MoveCw: objectMemory falseObject R: ReceiverResultReg)
		objRef: objectMemory falseObject.
	self RetN: 0.
	jumpCond jmpTarget: (self annotate: (self MoveCw: objectMemory trueObject R: ReceiverResultReg)
							objRef: objectMemory trueObject).
	self RetN: 0.

	objectRepresentation smallIntegerIsOnlyImmediateType
		ifTrue: [jumpFail jmpTarget: self Label]
		ifFalse: [jumpNonInt jmpTarget: (jumpFail jmpTarget: self Label)].
	^0
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSpecialSelectorArithmetic [
	| primDescriptor rcvrIsConst argIsConst rcvrIsInt argIsInt rcvrInt argInt result
	 jumpNotSmallInts jumpContinue annotateInst instToAnnotate |
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpNotSmallInts type: #'AbstractInstruction *'>
	<var: #jumpContinue type: #'AbstractInstruction *'>
	<var: #instToAnnotate type: #'AbstractInstruction *'>
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
			["Must enter any annotatedConstants into the map"
			 self annotateBytecodeIfAnnotated: (self ssValue: 1).
			 self annotateBytecodeIfAnnotated: self ssTop.
			 "Must annotate the bytecode for correct pc mapping."
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
			 annotateInst := self ssTop annotateUse.
			 self ssPop: 2.
			 self MoveR: ReceiverResultReg R: TempReg]
		ifFalse:
			[self marshallSendArguments: 1.
			 self MoveR: Arg0Reg R: TempReg.
			 rcvrIsInt ifFalse:
				[objectRepresentation isSmallIntegerTagNonZero
					ifTrue: [self AndR: ReceiverResultReg R: TempReg]
					ifFalse: [self OrR: ReceiverResultReg R: TempReg]]].
	jumpNotSmallInts := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	primDescriptor opcode caseOf: {
		[AddRR] -> [argIsInt
						ifTrue:
							[instToAnnotate := self AddCq: argInt - ConstZero R: ReceiverResultReg.
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
							[instToAnnotate := self SubCq: argInt - ConstZero R: ReceiverResultReg.
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
						ifTrue: [instToAnnotate := self AndCq: argInt R: ReceiverResultReg]
						ifFalse: [self AndR: Arg0Reg R: ReceiverResultReg].
					jumpContinue := self Jump: 0].
		[OrRR]	-> [argIsInt
						ifTrue: [instToAnnotate := self OrCq: argInt R: ReceiverResultReg]
						ifFalse: [self OrR: Arg0Reg R: ReceiverResultReg].
					jumpContinue := self Jump: 0] }.
	jumpNotSmallInts jmpTarget: self Label.
	argIsInt ifTrue:
		[annotateInst ifTrue: [self annotateBytecode: instToAnnotate].
		 self MoveCq: argInt R: Arg0Reg].
	self genMarshalledSend: (coInterpreter specialSelector: byte0 - self firstSpecialSelectorBytecodeOffset)
		numArgs: 1
		sendTable: ordinarySendTrampolines.
	jumpContinue jmpTarget: self Label.
	^0
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSpecialSelectorClass [
	| topReg |
	topReg := self ssTop registerOrNil.
	self ssPop: 1.
	(topReg isNil or: [topReg = ClassReg])
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
	| nextPC postBranchPC targetBytecodePC primDescriptor branchDescriptor nExts
	  rcvrIsInt argIsInt rcvrInt argInt result jumpNotSmallInts inlineCAB annotateInst |
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpNotSmallInts type: #'AbstractInstruction *'>
	self ssFlushTo: simStackPtr - 2.
	primDescriptor := self generatorAt: byte0.
	argIsInt := self ssTop type = SSConstant
				 and: [objectMemory isIntegerObject: (argInt := self ssTop constant)].
	rcvrIsInt := (self ssValue: 1) type = SSConstant
				 and: [objectMemory isIntegerObject: (rcvrInt := (self ssValue: 1) constant)].

	(argIsInt and: [rcvrIsInt]) ifTrue:
		[self cCode: '' inSmalltalk: "In Simulator ints are unsigned..."
				[rcvrInt := objectMemory integerValueOf: rcvrInt.
				argInt := objectMemory integerValueOf: argInt].
		 primDescriptor opcode caseOf: {
			[JumpLess]				-> [result := rcvrInt < argInt].
			[JumpLessOrEqual]		-> [result := rcvrInt <= argInt].
			[JumpGreater]			-> [result := rcvrInt > argInt].
			[JumpGreaterOrEqual]	-> [result := rcvrInt >= argInt].
			[JumpZero]				-> [result := rcvrInt = argInt].
			[JumpNonZero]			-> [result := rcvrInt ~= argInt] }.
		 "Must enter any annotatedConstants into the map"
		 self annotateBytecodeIfAnnotated: (self ssValue: 1).
		 self annotateBytecodeIfAnnotated: self ssTop.
		 "Must annotate the bytecode for correct pc mapping."
		 self ssPop: 2.
		 ^self ssPushAnnotatedConstant: (result
											ifTrue: [objectMemory trueObject]
											ifFalse: [objectMemory falseObject])].

	nextPC := bytecodePC + primDescriptor numBytes.
	nExts := 0.
	[branchDescriptor := self generatorAt: (objectMemory fetchByte: nextPC ofObject: methodObj) + (byte0 bitAnd: 256).
	 branchDescriptor isExtension] whileTrue:
		[nExts := nExts + 1.
		 nextPC := nextPC + branchDescriptor numBytes].
	"Only interested in inlining if followed by a conditional branch."
	inlineCAB := branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse].
	"Further, only interested in inlining = and ~= if there's a SmallInteger constant involved.
	 The relational operators successfully statically predict SmallIntegers; the equality operators do not."
	(inlineCAB and: [primDescriptor opcode = JumpZero or: [primDescriptor opcode = JumpNonZero]]) ifTrue:
		[inlineCAB := argIsInt or: [rcvrIsInt]].
	inlineCAB ifFalse:
		[^self genSpecialSelectorSend].

	targetBytecodePC := nextPC
							+ branchDescriptor numBytes
							+ (self spanFor: branchDescriptor at: nextPC exts: nExts in: methodObj).
	postBranchPC := nextPC + branchDescriptor numBytes.
	argIsInt
		ifTrue:
			[(self ssValue: 1) popToReg: ReceiverResultReg.
			 annotateInst := self ssTop annotateUse.
			 self ssPop: 2.
			 self MoveR: ReceiverResultReg R: TempReg]
		ifFalse:
			[self marshallSendArguments: 1.
			 self MoveR: Arg0Reg R: TempReg.
			 rcvrIsInt ifFalse:
				[objectRepresentation isSmallIntegerTagNonZero
					ifTrue: [self AndR: ReceiverResultReg R: TempReg]
					ifFalse: [self OrR: ReceiverResultReg R: TempReg]]].
	jumpNotSmallInts := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	argIsInt
		ifTrue: [annotateInst
					ifTrue: [self annotateBytecode: (self CmpCq: argInt R: ReceiverResultReg)]
					ifFalse: [self CmpCq: argInt R: ReceiverResultReg]]
		ifFalse: [self CmpR: Arg0Reg R: ReceiverResultReg].
	"Cmp is weird/backwards so invert the comparison.  Further since there is a following conditional
	 jump bytecode define non-merge fixups and leave the cond bytecode to set the mergeness."
	self gen: (branchDescriptor isBranchTrue
				ifTrue: [primDescriptor opcode]
				ifFalse: [self inverseBranchFor: primDescriptor opcode])
		operand: (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.
	self Jump: (self ensureNonMergeFixupAt: postBranchPC - initialPC).
	jumpNotSmallInts jmpTarget: self Label.
	argIsInt ifTrue:
		[self MoveCq: argInt R: Arg0Reg].
	^self genMarshalledSend: (coInterpreter specialSelector: byte0 - self firstSpecialSelectorBytecodeOffset)
		numArgs: 1
		sendTable: ordinarySendTrampolines.
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSpecialSelectorEqualsEquals [
	| nextPC postBranchPC targetBytecodePC primDescriptor branchDescriptor nExts
	  unforwardArg unforwardRcvr jumpEqual jumpNotEqual rcvrReg argReg result |
	<var: #jumpEqual type: #'AbstractInstruction *'>
	<var: #jumpNotEqual type: #'AbstractInstruction *'>
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	primDescriptor := self generatorAt: byte0.
	"forwarders have been followed in cog:selector:"
	(self ssTop type = SSConstant
	 and: [(self ssValue: 1) type = SSConstant]) ifTrue:
		[self assert: primDescriptor isMapped not.
		 result := self ssTop constant = (self ssValue: 1) constant
									ifTrue: [objectMemory trueObject]
									ifFalse: [objectMemory falseObject].
		 self ssPop: 2.
		 ^self ssPushConstant: result].

	nextPC := bytecodePC + primDescriptor numBytes.
	nExts := 0.
	[branchDescriptor := self generatorAt: (objectMemory fetchByte: nextPC ofObject: methodObj) + (byte0 bitAnd: 256).
	 branchDescriptor isExtension] whileTrue:
		[nExts := nExts + 1.
		 nextPC := nextPC + branchDescriptor numBytes].
	"If branching the stack must be flushed for the merge"
	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse]) ifTrue:
		[self ssFlushTo: simStackPtr - 2].

	unforwardRcvr := (self ssValue: 1) type ~= SSConstant
						or: [objectRepresentation shouldAnnotateObjectReference: (self ssValue: 1) constant].
	unforwardArg := self ssTop type ~= SSConstant
						or: [objectRepresentation shouldAnnotateObjectReference: self ssTop constant].

	"Don't use ReceiverResultReg for receiver to keep ReceiverResultReg live.
	 Optimize e.g. rcvr == nil, the common case for ifNil: et al."
	needsFrame
		ifTrue: 
			[unforwardArg ifTrue:
				[self ssAllocateRequiredReg: (argReg := Arg0Reg) upThrough: simStackPtr - 1].
			 self ssAllocateRequiredReg: (rcvrReg := Arg1Reg) upThrough: simStackPtr - 2]
		ifFalse:
			[unforwardArg ifTrue:
				[argReg := self ssAllocatePreferredReg: ClassReg].
			 rcvrReg := self ssAllocatePreferredReg: SendNumArgsReg].
	unforwardArg
		ifTrue:
			[self ssTop popToReg: argReg.
			 objectRepresentation genEnsureOopInRegNotForwarded: argReg scratchReg: TempReg.
			 (self ssValue: 1) popToReg: rcvrReg.
			 unforwardRcvr ifTrue:
				[objectRepresentation genEnsureOopInRegNotForwarded: rcvrReg scratchReg: TempReg].
			 self CmpR: argReg R: rcvrReg]
		ifFalse:
			[(self ssValue: 1) popToReg: rcvrReg.
			 unforwardRcvr ifTrue:
				[objectRepresentation genEnsureOopInRegNotForwarded: rcvrReg scratchReg: TempReg].
			 self CmpCq: self ssTop constant R: rcvrReg].
	self ssPop: 2.

	"If not followed by a branch, resolve to true or false."
	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse]) ifFalse:
		[jumpNotEqual := self JumpNonZero: 0.
		 self annotate: (self MoveCw: objectMemory trueObject R: rcvrReg)
			objRef: objectMemory trueObject.
		 jumpEqual := self Jump: 0.
		 jumpNotEqual jmpTarget: (self annotate: (self MoveCw: objectMemory falseObject R: rcvrReg)
										objRef: objectMemory falseObject).
		 jumpEqual jmpTarget: self Label.
		 self ssPushRegister: rcvrReg.
		 ^0].

	"Further since there is a following conditional jump bytecode, define
	 non-merge fixups and leave the cond bytecode to set the mergeness."
	targetBytecodePC := nextPC
							+ branchDescriptor numBytes
							+ (self spanFor: branchDescriptor at: nextPC exts: nExts in: methodObj).
	postBranchPC := nextPC + branchDescriptor numBytes.
	(self fixupAt: nextPC - initialPC) targetInstruction = 0
		ifTrue: "The next instruction is dead.  we can skip it."
			[deadCode := true.
		 	 self ensureFixupAt: targetBytecodePC - initialPC.
			 self ensureFixupAt: postBranchPC - initialPC]
		ifFalse:
			[self ssPushConstant: objectMemory trueObject]. "dummy value"
	self gen: (branchDescriptor isBranchTrue ifTrue: [JumpZero] ifFalse: [JumpNonZero])
		operand: (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.
	self Jump: (self ensureNonMergeFixupAt: postBranchPC - initialPC).
	^0
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genStorePop: popBoolean LiteralVariable: litVarIndex [
	<inline: false>
	| topReg valueReg association constVal |
	self flag: 'with better register allocation this wouldn''t need a frame.  e.g. use SendNumArgs instead of ReceiverResultReg'.
	self assert: needsFrame.
	optStatus isReceiverResultRegLive: false.
	"N.B.  No need to check the stack for references because we generate code for
	 literal variable loads that stores the result in a register, deferring only the register push."
	association := self getLiteral: litVarIndex.
	constVal := self ssTop maybeConstant.
	"Avoid store check for immediate values"
	(self ssTop type = SSConstant
	 and: [(objectRepresentation shouldAnnotateObjectReference: constVal) not]) ifTrue:
		[self ssAllocateRequiredReg: ReceiverResultReg.
		 self annotate: (self MoveCw: association R: ReceiverResultReg) objRef: association.
		 objectRepresentation
			genEnsureObjInRegNotForwarded: ReceiverResultReg
			scratchReg: TempReg.
		 self ssStorePop: popBoolean toPreferredReg: TempReg.
		 traceStores > 0 ifTrue:
			[self CallRT: ceTraceStoreTrampoline].
		 ^objectRepresentation
			genStoreImmediateInSourceReg: TempReg
			slotIndex: ValueIndex
			destReg: ReceiverResultReg].
	((topReg := self ssTop registerOrNil) isNil
	 or: [topReg = ReceiverResultReg]) ifTrue:
		[topReg := ClassReg].
	self ssPop: 1.
	self ssAllocateCallReg: topReg. "for the ceStoreCheck call in genStoreSourceReg:... below"
	self ssPush: 1.
	valueReg := self ssStorePop: popBoolean toPreferredReg: topReg.
	valueReg = ReceiverResultReg ifTrue:
		[self MoveR: valueReg R: topReg].
	self ssAllocateCallReg: ReceiverResultReg.
	self annotate: (self MoveCw: association R: ReceiverResultReg) objRef: association.
	objectRepresentation genEnsureObjInRegNotForwarded: ReceiverResultReg scratchReg: TempReg.
	traceStores > 0 ifTrue:
		[self MoveR: topReg R: TempReg.
		 self CallRT: ceTraceStoreTrampoline].
	^objectRepresentation
		genStoreSourceReg: topReg
		slotIndex: ValueIndex
		destReg: ReceiverResultReg
		scratchReg: TempReg
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genStorePop: popBoolean MaybeContextReceiverVariable: slotIndex [
	<inline: false>
	| jmpSingle jmpDone valueReg |
	<var: #jmpSingle type: #'AbstractInstruction *'>
	<var: #jmpDone type: #'AbstractInstruction *'>
	self assert: needsFrame.
	self ssFlushUpThroughReceiverVariable: slotIndex.
	"Note that ReceiverResultReg remains live after both
	 ceStoreContextInstVarTrampoline and ceStoreCheckTrampoline."
	self ensureReceiverResultRegContainsSelf.
	self ssPop: 1.
	self ssAllocateCallReg: ClassReg and: SendNumArgsReg. "for the ceStoreCheck call in genStoreSourceReg:... below"
	self ssPush: 1.
	objectRepresentation
		genLoadSlot: SenderIndex
		sourceReg: ReceiverResultReg
		destReg: TempReg.
	valueReg := self ssStorePop: popBoolean toPreferredReg: ClassReg.
	valueReg ~= ClassReg ifTrue:
		[self MoveR: valueReg R: ClassReg].
	jmpSingle := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg.
	self MoveCq: slotIndex R: SendNumArgsReg.
	self CallRT: ceStoreContextInstVarTrampoline.
	jmpDone := self Jump: 0.
	jmpSingle jmpTarget: self Label.
	traceStores > 0 ifTrue:
		[self MoveR: ClassReg R: TempReg.
		 self CallRT: ceTraceStoreTrampoline].
	objectRepresentation
		genStoreSourceReg: ClassReg
		slotIndex: slotIndex
		destReg: ReceiverResultReg
		scratchReg: TempReg.
	jmpDone jmpTarget: self Label.
	^0
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genStorePop: popBoolean ReceiverVariable: slotIndex [
	<inline: false>
	| topReg valueReg constVal |
	needsFrame ifFalse:
		[^self genFramelessStorePop: popBoolean ReceiverVariable: slotIndex].
	self ssFlushUpThroughReceiverVariable: slotIndex.
	"Avoid store check for immediate values"
	constVal := self ssTop maybeConstant.
	(self ssTop type = SSConstant
	 and: [(objectRepresentation shouldAnnotateObjectReference: constVal) not]) ifTrue:
		[self ensureReceiverResultRegContainsSelf.
		 self ssStorePop: popBoolean toPreferredReg: TempReg.
		 traceStores > 0 ifTrue:
			[self CallRT: ceTraceStoreTrampoline].
		 ^objectRepresentation
			genStoreImmediateInSourceReg: TempReg
			slotIndex: slotIndex
			destReg: ReceiverResultReg].
	((topReg := self ssTop registerOrNil) isNil
	 or: [topReg = ReceiverResultReg]) ifTrue:
		[topReg := ClassReg].
	self ssPop: 1.
	self ssAllocateCallReg: topReg. "for the ceStoreCheck call in genStoreSourceReg:... below"
	self ssPush: 1.
	valueReg := self ssStorePop: popBoolean toPreferredReg: topReg.
	valueReg = ReceiverResultReg ifTrue:
		[self MoveR: valueReg R: topReg].
	"Note that ReceiverResultReg remains live after ceStoreCheckTrampoline."
	self ensureReceiverResultRegContainsSelf.
	 traceStores > 0 ifTrue:
		[self MoveR: topReg R: TempReg.
		 self CallRT: ceTraceStoreTrampoline].
	^objectRepresentation
		genStoreSourceReg: topReg
		slotIndex: slotIndex
		destReg: ReceiverResultReg
		scratchReg: TempReg
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genStorePop: popBoolean RemoteTemp: slotIndex At: remoteTempIndex [
	<inline: false>
	| topReg valueReg constVal topSpilled |
	self assert: needsFrame.
	optStatus isReceiverResultRegLive: false.
	"N.B.  No need to check the stack for references because we generate code for
	 remote temp loads that stores the result in a register, deferring only the register push."
	"Avoid store check for immediate values"
	constVal := self ssTop maybeConstant.
	(self ssTop type = SSConstant
	 and: [(objectRepresentation shouldAnnotateObjectReference: constVal) not]) ifTrue:
		[self ssAllocateRequiredReg: ReceiverResultReg.
		 self MoveMw: (self frameOffsetOfTemporary: remoteTempIndex) r: FPReg R: ReceiverResultReg.
		 self ssStorePop: popBoolean toPreferredReg: TempReg.
		 traceStores > 0 ifTrue:
			[self CallRT: ceTraceStoreTrampoline].
		 ^objectRepresentation
			genStoreImmediateInSourceReg: TempReg
			slotIndex: slotIndex
			destReg: ReceiverResultReg].
	((topReg := self ssTop registerOrNil) isNil
	 or: [topReg = ReceiverResultReg]) ifTrue:
		[topReg := ClassReg].
	self ssPop: 1.
	"for the ceStoreCheck call in genStoreSourceReg:... below"
	self ssAllocateCallReg: topReg and: ReceiverResultReg.
	self ssPush: 1.
	topSpilled := self ssTop spilled.
	valueReg := self ssStorePop: (popBoolean or: [topSpilled]) toPreferredReg: topReg.
	valueReg = ReceiverResultReg ifTrue:
		[self MoveR: valueReg R: topReg].
	popBoolean ifFalse:
		[topSpilled ifFalse: [self ssPop: 1].
		 self ssPushRegister: topReg].
	self MoveMw: (self frameOffsetOfTemporary: remoteTempIndex) r: FPReg R: ReceiverResultReg.
	 traceStores > 0 ifTrue:
		[self MoveR: topReg R: TempReg.
		 self CallRT: ceTraceStoreTrampoline].
	^objectRepresentation
		genStoreSourceReg: topReg
		slotIndex: slotIndex
		destReg: ReceiverResultReg
		scratchReg: TempReg
]

{ #category : #'bytecode generator support' }
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

{ #category : #'inline primitive generators' }
StackToRegisterMappingCogit >> genTrinaryInlinePrimitive: prim [
	"Unary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#trinaryInlinePrimitive:"

	| ra rr adjust |
	(rr := backEnd availableRegisterOrNilFor: self liveRegisters) ifNil:
		[self ssAllocateRequiredReg:
			(rr := optStatus isReceiverResultRegLive
					ifTrue: [Arg0Reg]
					ifFalse: [ReceiverResultReg])].
	(ra := backEnd availableRegisterOrNilFor: (self liveRegisters bitOr: (self registerMaskFor: rr))) ifNil:
		[self ssAllocateRequiredReg: (ra := Arg1Reg)].
	(rr = ReceiverResultReg or: [ra = ReceiverResultReg]) ifTrue:
		[optStatus isReceiverResultRegLive: false].
	self ssTop popToReg: TempReg.
	self ssPop: 1.
	self ssTop popToReg: ra.
	self ssPop: 1.
	self ssTop popToReg: rr.
	self ssPop: 1.
	self ssPushRegister: TempReg.
	self genConvertSmallIntegerToIntegerInReg: ra.
	"Now: ra is the variable object, rr is long, TempReg holds the value to store."
	prim caseOf: {
		"0 - 1 pointerAt:put: and byteAt:Put:"
		[0] ->	[ adjust := (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
				adjust ~= 0 ifTrue: [ self AddCq: adjust R: ra. ]. 
				self MoveR: TempReg Xwr: ra R: rr ].
		[1] ->	[ self genConvertSmallIntegerToIntegerInReg: TempReg.
				adjust := objectMemory baseHeaderSize - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
				self AddCq: adjust R: ra.
				self MoveR: TempReg Xbr: ra R: rr ]
	}
	otherwise: [^EncounteredUnknownBytecode].
	^0
]

{ #category : #'inline primitive generators' }
StackToRegisterMappingCogit >> genUnaryInlinePrimitive: prim [
	"Unary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#unaryInlinePrimitive:"
	| rcvrReg resultReg |
	self ssTop type = SSRegister
		ifTrue: [rcvrReg := self ssTop register]
		ifFalse:
			[(rcvrReg := backEnd availableRegisterOrNilFor: self liveRegisters) ifNil:
				[self ssAllocateRequiredReg:
					(rcvrReg := optStatus isReceiverResultRegLive
							ifTrue: [Arg0Reg]
							ifFalse: [ReceiverResultReg])]].
	self ssTop popToReg: rcvrReg.
	self ssPop: 1.
	(resultReg := backEnd availableRegisterOrNilFor: self liveRegisters) ifNil:
		[self ssFlushUpThroughRegister: rcvrReg].
	prim
		caseOf: {
			[1] ->	"01		unchecked pointer numSlots"
				[resultReg ifNil: [resultReg := rcvrReg].
				 objectRepresentation
					genGetNumSlotsOf: rcvrReg into: resultReg;
					genConvertIntegerToSmallIntegerInScratchReg: resultReg.
				 self ssPushRegister: resultReg].
			[3] ->	"03 unchecked byte numBytes"
				[resultReg ifNil: [resultReg := rcvrReg].
				 objectRepresentation
					genGetNumBytesOf: rcvrReg into: resultReg;
					genConvertIntegerToSmallIntegerInScratchReg: resultReg.
				 self ssPushRegister: resultReg].
				  }
		otherwise:
			[^EncounteredUnknownBytecode].
	^0
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genUpArrowReturn [
	"Generate a method return from within a method or a block.
	 Frameless method activation looks like
				receiver
				args
		sp->	ret pc.
	 Return pops receiver and arguments off the stack.  Callee pushes the result."
	inBlock ifTrue:
		[self assert: needsFrame.
		 self annotateBytecode: (self CallRT: ceNonLocalReturnTrampoline).
		 ^0].
	needsFrame
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

	"Slang needs these apparently superfluous asSymbol sends."
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
StackToRegisterMappingCogit >> generateNewspeakSendTrampolines [
	"Self send, dynamic super send, and implicit receiver send. TODO: outer send."
	"Override to generate code to push the register arg(s) for <= numRegArg arity sends."
	<option: #NewspeakVM>
	0 to: NumSendTrampolines - 2 do:
		[:numArgs|
		selfSendTrampolines
			at: numArgs
			put: (self genSendTrampolineFor: #ceSelfSend:to:numArgs:
					  numArgs: numArgs
					  called: (self trampolineName: 'ceSelfSend' numArgs: numArgs)
					  arg: ClassReg
					  arg: ReceiverResultReg
					  arg: numArgs)].
	selfSendTrampolines
		at: NumSendTrampolines - 1
		put: (self genSendTrampolineFor: #ceSelfSend:to:numArgs:
					numArgs: self numRegArgs + 1
					called: (self trampolineName: 'ceSelfSend' numArgs: -1)
					arg: ClassReg
					arg: ReceiverResultReg
					arg: SendNumArgsReg).

	0 to: NumSendTrampolines - 2 do:
		[:numArgs|
		dynamicSuperSendTrampolines
			at: numArgs
			put: (self genSendTrampolineFor: #ceDynamicSuperSend:to:numArgs:
					  numArgs: numArgs
					  called: (self trampolineName: 'ceDynSuperSend' numArgs: numArgs)
					  arg: ClassReg
					  arg: ReceiverResultReg
					  arg: numArgs)].
	dynamicSuperSendTrampolines
		at: NumSendTrampolines - 1
		put: (self genSendTrampolineFor: #ceDynamicSuperSend:to:numArgs:
					numArgs: self numRegArgs + 1
					called: (self trampolineName: 'ceDynSuperSend' numArgs: -1)
					arg: ClassReg
					arg: ReceiverResultReg
					arg: SendNumArgsReg).

	0 to: NumSendTrampolines - 2 do:
		[:numArgs|
		implicitReceiverSendTrampolines
			at: numArgs
			put: (self 
				genNSSendTrampolineFor: #ceImplicitReceiverSend:receiver:
				numArgs: numArgs
				called: (self trampolineName: 'ceImplicitReceiverSend' numArgs: numArgs))].
	implicitReceiverSendTrampolines
		at: NumSendTrampolines - 1
		put: (self 
			genNSSendTrampolineFor: #ceImplicitReceiverSend:receiver:
			numArgs: self numRegArgs + 1
			called: (self trampolineName: 'ceImplicitReceiverSend' numArgs: -1)).

	0 to: NumSendTrampolines - 2 do:
		[:numArgs|
		outerSendTrampolines
			at: numArgs
			put: (self 
				genNSSendTrampolineFor: #ceOuterSend:receiver:
				numArgs: numArgs
				called: (self trampolineName: 'ceOuterSend' numArgs: numArgs))].
	outerSendTrampolines
		at: NumSendTrampolines - 1
		put: (self 
			genNSSendTrampolineFor: #ceOuterSend:receiver:
			numArgs: self numRegArgs + 1
			called: (self trampolineName: 'ceOuterSend' numArgs: -1)).
]

{ #category : #initialization }
StackToRegisterMappingCogit >> generateSendTrampolines [
	"Override to generate code to push the register arg(s) for <= numRegArg arity sends."
	0 to: NumSendTrampolines - 2 do:
		[:numArgs|
		ordinarySendTrampolines
			at: numArgs
			put: (self genSendTrampolineFor: #ceSend:super:to:numArgs:
					  numArgs: numArgs
					  called: (self trampolineName: 'ceSend' numArgs: numArgs)
					  arg: ClassReg
					  arg: 0
					  arg: ReceiverResultReg
					  arg: numArgs)].
	ordinarySendTrampolines
		at: NumSendTrampolines - 1
		put: (self genSendTrampolineFor: #ceSend:super:to:numArgs:
					numArgs: self numRegArgs + 1
					called: (self trampolineName: 'ceSend' numArgs: -1)
					arg: ClassReg
					arg: 0
					arg: ReceiverResultReg
					arg: SendNumArgsReg).

	"Generate these in the middle so they are within [firstSend, lastSend]."
	self cppIf: NewspeakVM ifTrue: [self generateNewspeakSendTrampolines].

	0 to: NumSendTrampolines - 2 do:
		[:numArgs|
		superSendTrampolines
			at: numArgs
			put: (self genSendTrampolineFor: #ceSend:super:to:numArgs:
					  numArgs: numArgs
					  called: (self trampolineName: 'ceSuperSend' numArgs: numArgs)
					  arg: ClassReg
					  arg: 1
					  arg: ReceiverResultReg
					  arg: numArgs)].
	superSendTrampolines
		at: NumSendTrampolines - 1
		put: (self genSendTrampolineFor: #ceSend:super:to:numArgs:
					numArgs: self numRegArgs + 1
					called: (self trampolineName: 'ceSuperSend' numArgs: -1)
					arg: ClassReg
					arg: 1
					arg: ReceiverResultReg
					arg: SendNumArgsReg).
	firstSend := ordinarySendTrampolines at: 0.
	lastSend := superSendTrampolines at: NumSendTrampolines - 1
]

{ #category : #initialization }
StackToRegisterMappingCogit >> generateTracingTrampolines [
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
			arg: TempReg
			arg: ReceiverResultReg.
	self cCode: [] inSmalltalk:
		[ceTraceLinkedSendTrampoline := self simulatedTrampolineFor: #ceShortCutTraceLinkedSend:.
		 ceTraceBlockActivationTrampoline := self simulatedTrampolineFor: #ceShortCutTraceBlockActivation:.
		 ceTraceStoreTrampoline := self simulatedTrampolineFor: #ceShortCutTraceStore:]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> initSimStackForFramefulMethod: startpc [
	<var: #desc type: #'CogSimStackEntry *'>
	optStatus isReceiverResultRegLive: false.
	simSelf
		type: SSBaseOffset;
		spilled: true;
		annotateUse: false;
		register: FPReg;
		offset: FoxMFReceiver.
	simSpillBase := methodOrBlockNumTemps. "N.B. Includes num args"
	simStackPtr := simSpillBase - 1.
	"args"
	0 to: methodOrBlockNumArgs - 1 do:
		[:i| | desc |
		desc := self simStackAt: i.
		desc
			type: SSBaseOffset;
			spilled: true;
			annotateUse: false;
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
			annotateUse: false;
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
		annotateUse: false;
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
			annotateUse: false;
			register: SPReg;
			offset: ((methodOrBlockNumTemps - i) * objectMemory wordSize);
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
		annotateUse: false;
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
				annotateUse: false;
				register: Arg0Reg;
				bcptr: startpc.
			 methodOrBlockNumArgs > 1 ifTrue:
				[desc := self simStackAt: 1.
				 desc
					type: SSRegister;
					spilled: false;
					annotateUse: false;
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
					annotateUse: false;
					offset: ((methodOrBlockNumArgs - i) * objectMemory wordSize);
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
		targetInstruction: (self cCoerceSimple: 2 to: #'AbstractInstruction *');
		simStackPtr: -2.
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

{ #category : #testing }
StackToRegisterMappingCogit >> isValidFramelessRegister: reg [
	"Answer if the receiver is valid in a frameless method."
	^reg = ReceiverResultReg or: [reg = Arg0Reg]
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

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> marshallAbsentReceiverSendArguments: numArgs [
	self assert: needsFrame.
	self ssAllocateCallReg: ReceiverResultReg.
	self MoveMw: FoxMFReceiver r: FPReg R: ReceiverResultReg.

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

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> merge: fixup afterContinuation: mergeWithContinuation [
	"Merge control flow at a fixup.  The fixup holds the simStackPtr at the jump to this target.
	 See stackToRegisterMapping on the class side for a full description."
	<var: #fixup type: #'BytecodeFixup *'>
	self traceMerge: fixup.
	"For now we don't try and preserve the optimization status through merges."
	optStatus isReceiverResultRegLive: false.
	"If this instruction follows a return or an unconditional branch then the
	 current simStackPtr is irrelevant and we continue with that of the fixup."
	mergeWithContinuation ifFalse:
		[self assert: fixup targetInstruction asUnsignedInteger >= 2.  "Must have a valid simStackPtr"
		 simStackPtr := fixup simStackPtr].
	fixup targetInstruction asUnsignedInteger <= 2 ifTrue:
		["This is either a forward or backward branch target.
		  The stack must be flushed."
		 self ssFlushTo: simStackPtr.
		 fixup simStackPtr <= -2 ifTrue:
			"This is the target of a backward branch.  It doesn't have a simStackPtr yet."
			[fixup simStackPtr: simStackPtr].
		 fixup targetInstruction: self Label].
	self assert: simStackPtr >= fixup simStackPtr.
	self cCode: '' inSmalltalk:
		[self assert: fixup simStackPtr = (self debugStackPointerFor: bytecodePC)].
	simStackPtr := fixup simStackPtr.
	simSpillBase := methodOrBlockNumTemps.
	"For now throw away all type information for values on the stack, but sometime consider
	 the more sophisticated merge described in the class side stackToRegisterMapping."
	methodOrBlockNumTemps to: simStackPtr do:
		[:i|
		(self simStackAt: i)
			mergeAt: FoxMFReceiver - (i - methodOrBlockNumArgs + 1 * objectMemory bytesPerOop)
			from: FPReg]
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
	| annotation prevIndex prevInst |
	<var: #annotation type: #'InstructionAnnotation *'>
	<var: #prevInst type: #'AbstractInstruction *'>
	annotationIndex > 0 ifFalse:
		[^false].
	annotation := self addressOf: (annotations at: annotationIndex - 1).
	(self isPCMappedAnnotation: annotation annotation) ifFalse:
		[^false].
	prevIndex := opcodeIndex - 1.
	[prevIndex <= 0 ifTrue: [^false].
	 prevInst := self abstractInstructionAt: prevIndex.
	 annotation instruction = prevInst ifTrue:
		[^true].
	 prevInst opcode = Label]
		whileTrue:
			[prevIndex := prevIndex - 1].
	^false
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> printSimStack [
	<doNotGenerate>
	coInterpreter transcript ensureCr.
	simStackPtr < 0 ifTrue:
		[^coInterpreter transcript nextPutAll: 'simStackEmpty'; cr; flush].
	0 to: simStackPtr do:
		[:i|
		coInterpreter transcript print: i.
		i = simSpillBase
			ifTrue: [coInterpreter transcript nextPutAll: ' sb'; tab]
			ifFalse: [coInterpreter transcript tab; tab].
		(simStack at: i) printStateOn: coInterpreter transcript.
		coInterpreter transcript cr; flush]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> pushNilSize: aMethodObj numInitialNils: numInitialNils [
	<inline: true>
	^self perform: pushNilSizeFunction with: aMethodObj with: numInitialNils
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
		[(self fixupAt: pc - initialPC)
			targetInstruction: 0;
			simStackPtr: nil.
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

{ #category : #trampolines }
StackToRegisterMappingCogit >> returnRegForStoreCheck [
	"We must ensure the ReceiverResultReg is live across the store check so that
	 we can store into receiver inst vars in a frameless method since self exists
	 only in ReceiverResultReg in a frameless method.  So if ReceiverResultReg is
	 caller-saved we use the fact that ceStoreCheck: answers its argument to
	 reload ReceiverResultReg cheaply.  Otherwise we don't care about the result
	 and use the cResultRegister, effectively a no-op (see compileTrampoline...)"

	^((self registerMaskFor: ReceiverResultReg) anyMask: callerSavedRegMask)
		ifTrue: [ReceiverResultReg]
		ifFalse: [backEnd cResultRegister]
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
		 blockStart numInitialNils: blockStart numInitialNils - framelessStackDelta]
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> scanMethod [
	"Scan the method (and all embedded blocks) to determine
		- what the last bytecode is; extra bytes at the end of a method are used to encode things like source pointers or temp names
		- if the method needs a frame or not
		- what are the targets of any backward branches.
		- how many blocks it creates
	 Answer the block count or on error a negative error code"
	| latestContinuation nExts descriptor pc numBlocks distance targetPC framelessStackDelta |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	needsFrame := false.
	inBlock := false.
	prevBCDescriptor := nil.
	self cppIf: #NewspeakVM ifTrue:
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
				ifTrue: [needsFrame := true]
				ifFalse: [framelessStackDelta := framelessStackDelta + descriptor stackDelta]].
		 descriptor isBranch ifTrue:
			[distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 (self isBackwardBranch: descriptor at: pc exts: nExts in: methodObj)
				ifTrue: [self initializeFixupAt: targetPC - initialPC]
				ifFalse: [latestContinuation := latestContinuation max: targetPC]].
		 descriptor isBlockCreation ifTrue:
			[numBlocks := numBlocks + 1.
			 distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 latestContinuation := latestContinuation max: targetPC].
		 self cppIf: #NewspeakVM ifTrue:
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

	simStack := CArrayAccessor on: ((1 to: 256) collect: [:i| CogSimStackEntry new cogit: self]).
	simSelf := CogSimStackEntry new cogit: self.
	optStatus := CogSSOptStatus new.

	debugFixupBreaks := Set new.
	debugBytecodePointers := Set new.

	numPushNilsFunction := self class numPushNilsFunction.
	pushNilSizeFunction := self class pushNilSizeFunction
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> simStackAt: index [
	<cmacro: '(index) (simStack + (index))'>
	<returnTypeC: #'CogSimStackEntry *'>
	^self addressOf: (simStack at: index)
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
	^numInitialNils = 0 ifTrue: [0] ifFalse: [2]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> squeakV3orSistaV1: descriptor Num: pc Push: nExts Nils: aMethodObj [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	| numNils |
	(numNils := self v3: descriptor Num: pc Push: nExts Nils: aMethodObj) > 0 ifTrue:
		[^numNils].
	^self sistaV1: descriptor Num: pc Push: nExts Nils: aMethodObj
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
	self ssAllocateRequiredRegMask: (callerSavedRegMask
										bitOr: (self registerMaskFor: requiredReg))
		upThrough: simStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateCallReg: requiredReg1 and: requiredReg2 [
	self ssAllocateRequiredRegMask: (callerSavedRegMask
										bitOr: ((self registerMaskFor: requiredReg1)
										bitOr: (self registerMaskFor: requiredReg2)))
		upThrough: simStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateCallReg: requiredReg1 and: requiredReg2 and: requiredReg3 [
	self ssAllocateRequiredRegMask: (callerSavedRegMask
										bitOr: ((self registerMaskFor: requiredReg1)
										bitOr: ((self registerMaskFor: requiredReg2)
										bitOr: (self registerMaskFor: requiredReg3))))
		upThrough: simStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateCallReg: requiredReg1 and: requiredReg2 and: requiredReg3 and: requiredReg4 [
	self ssAllocateRequiredRegMask: (callerSavedRegMask
										bitOr: ((self registerMaskFor: requiredReg1)
										bitOr: ((self registerMaskFor: requiredReg2)
										bitOr: ((self registerMaskFor: requiredReg3)
										bitOr: (self registerMaskFor: requiredReg4)))))
		upThrough: simStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocatePreferredReg: preferredReg [
	| preferredMask lastPreferred liveRegs |
	lastPreferred := -1.
	"compute live regs while noting the last occurrence of preferredReg.
	 If there are none free we must spill from simSpillBase to last occurrence."
	preferredMask := (self registerMaskFor: preferredReg).
	liveRegs := self registerMaskFor: TempReg and: FPReg and: SPReg.
	(simSpillBase max: 0) to: simStackPtr do:
		[:i|
		liveRegs := liveRegs bitOr: (self simStackAt: i) registerMask.
		(liveRegs bitAnd: preferredMask) ~= 0 ifTrue:
			[lastPreferred := i]].
	"If preferredReg is not live we can allocate it."
	(liveRegs bitAnd: (self registerMaskFor: preferredReg)) = 0 ifTrue:
		[^preferredReg].
	"If any other is not live we can allocate it."
	GPRegMin to: GPRegMax do:
		[:reg|
		(liveRegs bitAnd: (self registerMaskFor: reg)) = 0 ifTrue:
			[^reg]].
	"All live, must spill"
	self ssFlushTo: lastPreferred.
	self assert: (self liveRegisters bitAnd: preferredMask) = 0.
	^preferredReg
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
StackToRegisterMappingCogit >> ssFlushUpThroughReceiverVariable: slotIndex [
	"Any occurrences on the stack of the value being stored (which is the top of stack)
	 must be flushed, and hence any values colder than them stack."
	<var: #desc type: #'CogSimStackEntry *'>
	simStackPtr - 1 to: (simSpillBase max: 0) by: -1 do:
		[:index| | desc |
		desc := self simStackAt: index.
		(desc type = SSBaseOffset
		 and: [desc register = ReceiverResultReg
		 and: [desc offset = (objectRepresentation slotOffsetOfInstVarIndex: slotIndex)]]) ifTrue:
			[self ssFlushTo: index.
			 ^self]]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssFlushUpThroughRegister: reg [
	"Any occurrences on the stack of the register must be
	 flushed, and hence any values colder than them stack."
	<var: #desc type: #'CogSimStackEntry *'>
	simStackPtr - 1 to: (simSpillBase max: 0) by: -1 do:
		[:index| | desc |
		desc := self simStackAt: index.
		(desc type = SSRegister
		 and: [desc register = reg]) ifTrue:
			[self ssFlushTo: index.
			 ^self]]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssFlushUpThroughTemporaryVariable: tempIndex [
	"Any occurrences on the stack of the value being stored (which is the top of stack)
	 must be flushed, and hence any values colder than them stack."
	<var: #desc type: #'CogSimStackEntry *'>
	simStackPtr - 1 to: simSpillBase by: -1 do:
		[:index| | desc |
		desc := self simStackAt: index.
		(desc type = SSBaseOffset
		 and: [desc register = FPReg
		 and: [desc offset = (self frameOffsetOfTemporary: tempIndex)]]) ifTrue:
			[self ssFlushTo: index.
			 ^self]]
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
	simSpillBase > simStackPtr ifTrue:
		[simSpillBase := simStackPtr max: 0].
	self ssTop
		type: SSConstant;
		annotateUse: true;
		spilled: false;
		constant: literal;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushBase: reg offset: offset [
	self ssPush: 1.
	simSpillBase > simStackPtr ifTrue:
		[simSpillBase := simStackPtr max: 0].
	self ssTop
		type: SSBaseOffset;
		spilled: false;
		annotateUse: false;
		register: reg;
		offset: offset;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushConstant: literal [
	self ssPush: 1.
	simSpillBase > simStackPtr ifTrue:
		[simSpillBase := simStackPtr max: 0].
	self ssTop
		type: SSConstant;
		spilled: false;
		annotateUse: false;
		constant: literal;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushDesc: simStackEntry [
	<var: #simStackEntry type: #CogSimStackEntry>
	self cCode:
			[simStackEntry type = SSSpill ifTrue:
				[simStackEntry type: SSBaseOffset].
			simStackEntry
				spilled: false;
				annotateUse: false;
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
				annotateUse: false;
				bcptr: bytecodePC].
	simSpillBase > simStackPtr ifTrue:
		[simSpillBase := simStackPtr max: 0].
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushRegister: reg [
	self ssPush: 1.
	simSpillBase > simStackPtr ifTrue:
		[simSpillBase := simStackPtr max: 0].
	self ssTop
		type: SSRegister;
		spilled: false;
		annotateUse: false;
		register: reg;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssStorePop: popBoolean toPreferredReg: preferredReg [
	"Store or pop the top simulated stack entry to a register.
	 Pop to preferredReg if the entry is not itself a register.
	 Answer the actual register the result ends up in."
	| actualReg |
	actualReg := preferredReg.
	popBoolean
		ifTrue: [(self ssTop type = SSRegister and: [self ssTop spilled not])
					ifTrue: [self assert: self ssTop annotateUse not.
							actualReg := self ssTop register]
					ifFalse: [self ssTop popToReg: preferredReg].
				self ssPop: 1]
		ifFalse: [self ssTop type = SSRegister
					ifTrue: [self assert: self ssTop annotateUse not.
							actualReg := self ssTop register]
					ifFalse: [self ssTop storeToReg: preferredReg]].
	^actualReg
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssTop [
	<returnTypeC: #'CogSimStackEntry *'>
	^self simStackAt: simStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssTopDescriptor [
	<returnTypeC: #CogSimStackEntry>
	^simStack at: simStackPtr
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
	| numNils |
	(numNils := self v3: descriptor Num: pc Push: nExts Nils: aMethodObj) > 0 ifTrue:
		[^numNils].
	^self v4: descriptor Num: pc Push: nExts Nils: aMethodObj
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
