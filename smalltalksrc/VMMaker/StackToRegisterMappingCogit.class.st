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
		'isPushNilFunction',
		'pushNilSizeFunction',
		'callerSavedRegMask',
		'methodOrBlockNumTemps',
		'regArgsHaveBeenPushed',
		'simSelf',
		'simStack',
		'simStackPtr',
		'simSpillBase',
		'optStatus',
		'ceEnterCogCodePopReceiverArg0Regs',
		'ceEnterCogCodePopReceiverArg1Arg0Regs',
		'methodAbortTrampolines',
		'picAbortTrampolines',
		'picMissTrampolines',
		'ceEnter0ArgsPIC',
		'ceEnter1ArgsPIC',
		'ceEnter2ArgsPIC',
		'debugStackPointers',
		'debugFixupBreaks',
		'debugBytecodePointers',
		'realCEEnterCogCodePopReceiverArg0Regs',
		'realCEEnterCogCodePopReceiverArg1Arg0Regs',
		'deadCode'
	],
	#pools : [
		'CogCompilationConstants',
		'VMMethodCacheConstants',
		'VMObjectIndices',
		'VMStackFrameOffsets'
	],
	#classInstVars : [
		'isPushNilFunction',
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
		var: 'ceEnter0ArgsPIC'
			declareC: 'void (*ceEnter0ArgsPIC)(void)';
		var: 'ceEnter1ArgsPIC'
			declareC: 'void (*ceEnter1ArgsPIC)(void)';
		var: 'ceEnter2ArgsPIC'
			declareC: 'void (*ceEnter2ArgsPIC)(void)';
		var: #ceEnterCogCodePopReceiverArg0Regs
			declareC: 'void (*ceEnterCogCodePopReceiverArg0Regs)(void)';
		var: #realCEEnterCogCodePopReceiverArg0Regs
			declareC: 'void (*realCEEnterCogCodePopReceiverArg0Regs)(void)';
		var: #ceEnterCogCodePopReceiverArg1Arg0Regs
			declareC: 'void (*ceEnterCogCodePopReceiverArg1Arg0Regs)(void)';
		var: #realCEEnterCogCodePopReceiverArg1Arg0Regs
			declareC: 'void (*realCEEnterCogCodePopReceiverArg1Arg0Regs)(void)';
		var: 'simStack'
			declareC: 'CogSimStackEntry simStack[', ((CoInterpreter bindingOf: #LargeContextSize) value * 5 / 4 // BytesPerWord) asString, ']';
		var: 'simSelf'
			type: #CogSimStackEntry;
		var: #optStatus
			type: #CogSSOptStatus;
		var: 'isPushNilFunction'
			declareC: 'sqInt (* const isPushNilFunction)(struct _BytecodeDescriptor *,sqInt,sqInt,sqInt) = ', (aCodeGen cFunctionNameFor: self isPushNilFunction);
		var: 'pushNilSizeFunction'
			declareC: 'sqInt (* const pushNilSizeFunction)(sqInt) = ', (aCodeGen cFunctionNameFor: self pushNilSizeFunction);
		var: 'prevBCDescriptor'
			type: #'BytecodeDescriptor *'.

	aCodeGen
		addSelectorTranslation: #register to: (aCodeGen cFunctionNameFor: 'registerr');
		addSelectorTranslation: #register: to: (aCodeGen cFunctionNameFor: 'registerr:')
]

{ #category : #'class initialization' }
StackToRegisterMappingCogit class >> initializeBytecodeTableForNewspeakV3PlusClosures [
	"StackToRegisterMappingCogit initializeBytecodeTableForNewspeakV3PlusClosures"

	isPushNilFunction := #v3:Is:Push:Nil:.
	pushNilSizeFunction := #v3PushNilSize:.
	NSSendIsPCAnnotated := true. "IsNSSendCall used by PushImplicitReceiver"
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

		(3 126 126 genDynamicSuperSendBytecode isMapped)		"Newspeak"
		(2 127 127 genPushImplicitReceiverBytecode isMapped)	"Newspeak"

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
		(2 138 138 genPushNewArrayBytecode)

		(2 139 139 genPushExplicitOuterSendReceiverBytecode isMapped)	"Newspeak"

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
StackToRegisterMappingCogit class >> initializeBytecodeTableForNewspeakV3PlusClosuresNewspeakV4Hybrid [
	"StackToRegisterMappingCogit initializeBytecodeTableForNewspeakV3PlusClosuresNewspeakV4Hybrid"

	super initializeBytecodeTableForNewspeakV3PlusClosuresNewspeakV4Hybrid.
	isPushNilFunction := #v3or4:Is:Push:Nil:.
	pushNilSizeFunction := #v3or4PushNilSize:
]

{ #category : #'class initialization' }
StackToRegisterMappingCogit class >> initializeBytecodeTableForNewspeakV4 [
	"StackToRegisterMappingCogit initializeBytecodeTableForNewspeakV4"

	isPushNilFunction := #v4:Is:Push:Nil:.
	pushNilSizeFunction := #v4PushNilSize:.
	NSSendIsPCAnnotated := false. "IsNSSendCall used by SendAbsentImplicit"
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
		(1  77   77 genExtPushPseudoVariableOrOuterBytecode)
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
		(1 160 175	genSendAbsentImplicit0ArgsBytecode isMapped)

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
		(2 240 240 genExtSendAbsentImplicitBytecode isMapped)
		(2 241 241 genExtSendAbsentDynamicSuperBytecode isMapped)

		(2 242 242 genExtUnconditionalJump	branch isMapped "because of interrupt check" v4:Long:Branch:Distance:)
		(2 243 243 genExtJumpIfTrue			branch isBranchTrue isMapped "because of mustBeBoolean" v4:Long:Branch:Distance:)
		(2 244 244 genExtJumpIfFalse			branch isBranchFalse isMapped "because of mustBeBoolean" v4:Long:Branch:Distance:)

		(2 245 248	unknownBytecode)

		"3 byte bytecodes"
		(3 249 249 callPrimitiveBytecode)
		(3 250 250 genPushRemoteTempLongBytecode)
		(3 251 251 genStoreRemoteTempLongBytecode)
		(3 252 252 genStoreAndPopRemoteTempLongBytecode)
		(3 253 253 genExtPushClosureBytecode block v4:Block:Code:Size:)

		(3 254 255	unknownBytecode))
]

{ #category : #'class initialization' }
StackToRegisterMappingCogit class >> initializeBytecodeTableForSqueakV3PlusClosures [
	"StackToRegisterMappingCogit initializeBytecodeTableForSqueakV3PlusClosures"

	isPushNilFunction := #v3:Is:Push:Nil:.
	pushNilSizeFunction := #v3PushNilSize:.
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
		(2 138 138 genPushNewArrayBytecode)

		(1 139 139 unknownBytecode)

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
StackToRegisterMappingCogit class >> initializeMiscConstants [
	super initializeMiscConstants.
	NumTrampolines := NewspeakVM
							ifTrue: [58]
							ifFalse: [50]
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

{ #category : #accessing }
StackToRegisterMappingCogit class >> isPushNilFunction [
	"Answer the value of isPushNilFunction"

	^ isPushNilFunction
]

{ #category : #translation }
StackToRegisterMappingCogit class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^(super mustBeGlobal: var)
	   or: [#('ceEnterCogCodePopReceiverArg0Regs' 'ceEnterCogCodePopReceiverArg1Arg0Regs'
			'realCEEnterCogCodePopReceiverArg0Regs' 'realCEEnterCogCodePopReceiverArg1Arg0Regs'
			'ceEnter0ArgsPIC' 'ceEnter1ArgsPIC' 'ceEnter2ArgsPIC') includes: var]
]

{ #category : #'class initialization' }
StackToRegisterMappingCogit class >> newInitializeBytecodeTableForNewspeakV3PlusClosures [
	"StackToRegisterMappingCogit newInitializeBytecodeTableForNewspeakV3PlusClosures"

	isPushNilFunction := #v3:Is:Push:Nil:.
	pushNilSizeFunction := #v3PushNilSize:.
	NSSendIsPCAnnotated := true. "IsNSSendCall used by PushImplicitReceiver"
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

		(3 126 126 genDynamicSuperSendBytecode isMapped)		"Newspeak"
		(2 127 127 genPushImplicitReceiverBytecode isMapped)	"Newspeak"

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
		(2 138 138 genPushNewArrayBytecode)

		(2 139 139 genPushExplicitOuterSendReceiverBytecode isMapped)	"Newspeak"

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
StackToRegisterMappingCogit class >> newInitializeBytecodeTableForNewspeakV3PlusClosuresNewspeakV4Hybrid [
	"StackToRegisterMappingCogit newInitializeBytecodeTableForNewspeakV3PlusClosuresNewspeakV4Hybrid"

	super newInitializeBytecodeTableForNewspeakV3PlusClosuresNewspeakV4Hybrid.
	isPushNilFunction := #v3or4:Is:Push:Nil:.
	pushNilSizeFunction := #v3or4PushNilSize:
]

{ #category : #'class initialization' }
StackToRegisterMappingCogit class >> newInitializeBytecodeTableForNewspeakV4 [
	"StackToRegisterMappingCogit newInitializeBytecodeTableForNewspeakV4"

	isPushNilFunction := #v4:Is:Push:Nil:.
	pushNilSizeFunction := #v4PushNilSize:.
	NSSendIsPCAnnotated := false. "IsNSSendCall used by SendAbsentImplicit"
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
		(1  77   77 genExtPushPseudoVariableOrOuterBytecode)
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
		(1 160 175	genSendAbsentImplicit0ArgsBytecode isMapped)

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
		(2 240 240 genExtSendAbsentImplicitBytecode isMapped)
		(2 241 241 genExtSendAbsentDynamicSuperBytecode isMapped)

		(2 242 242 genExtUnconditionalJump	branch isMapped "because of interrupt check" v4:Long:Branch:Distance:)
		(2 243 243 genExtJumpIfTrue			branch isBranchTrue isMapped "because of mustBeBoolean" v4:Long:Branch:Distance:)
		(2 244 244 genExtJumpIfFalse			branch isBranchFalse isMapped "because of mustBeBoolean" v4:Long:Branch:Distance:)

		(2 245 248	unknownBytecode)

		"3 byte bytecodes"
		(3 249 249 callPrimitiveBytecode)
		(3 250 250 genPushRemoteTempLongBytecode)
		(3 251 251 genStoreRemoteTempLongBytecode)
		(3 252 252 genStoreAndPopRemoteTempLongBytecode)
		(3 253 253 genExtPushClosureBytecode block v4:Block:Code:Size:)

		(3 254 255	unknownBytecode))
]

{ #category : #'class initialization' }
StackToRegisterMappingCogit class >> newInitializeBytecodeTableForSqueakV3PlusClosures [
	"StackToRegisterMappingCogit newInitializeBytecodeTableForSqueakV3PlusClosures"

	isPushNilFunction := #v3:Is:Push:Nil:.
	pushNilSizeFunction := #v3PushNilSize:.
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
		(2 138 138 genPushNewArrayBytecode)

		(1 139 139 unknownBytecode)

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

{ #category : #translation }
StackToRegisterMappingCogit class >> prepareToBeAddedToCodeGenerator: aCCodeGenerator [
	"Override to avoid repeating SimpleStackBasedCogit's preparations and remove the methods we override."
	self selectors do:
		[:sel|
		 (superclass whichClassIncludesSelector: sel) ifNotNil:
			[aCCodeGenerator removeMethodForSelector: sel]]
]

{ #category : #accessing }
StackToRegisterMappingCogit class >> pushNilSizeFunction [
	"Answer the value of pushNilSizeFunction"

	^ pushNilSizeFunction
]

{ #category : #translation }
StackToRegisterMappingCogit class >> requiredMethodNames: options [
	^(super requiredMethodNames: options)
		add: self isPushNilFunction;
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

{ #category : #'bytecode generators' }
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
	| liveRegs |
	liveRegs := self liveRegisters.
	(liveRegs anyMask: (self registerMaskFor: Arg0Reg)) ifFalse:
		[^Arg0Reg].
	(liveRegs anyMask: (self registerMaskFor: Arg1Reg)) ifFalse:
		[^Arg1Reg].
	(liveRegs anyMask: (self registerMaskFor: ClassReg)) ifFalse:
		[^ClassReg].
	(liveRegs anyMask: (self registerMaskFor: ReceiverResultReg)) ifFalse:
		[^ReceiverResultReg].
	(liveRegs anyMask: (self registerMaskFor: SendNumArgsReg)) ifFalse:
		[^SendNumArgsReg].
	self error: 'no available register'.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> availableRegisterOrNil [
	<returnTypeC: #sqInt>
	| liveRegs |
	liveRegs := self liveRegisters.
	(liveRegs anyMask: (self registerMaskFor: Arg1Reg)) ifFalse:
		[^Arg1Reg].
	(liveRegs anyMask: (self registerMaskFor: Arg0Reg)) ifFalse:
		[^Arg0Reg].
	(liveRegs anyMask: (self registerMaskFor: SendNumArgsReg)) ifFalse:
		[^SendNumArgsReg].
	(liveRegs anyMask: (self registerMaskFor: ClassReg)) ifFalse:
		[^ClassReg].
	(liveRegs anyMask: (self registerMaskFor: ReceiverResultReg)) ifFalse:
		[^ReceiverResultReg].
	^nil
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

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> ceEnter0ArgsPIC [
	<api: 'extern void (*ceEnter0ArgsPIC)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceEnter0ArgsPIC numArgs: 1
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> ceEnter1ArgsPIC [
	<api: 'extern void (*ceEnter1ArgsPIC)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceEnter1ArgsPIC numArgs: 1
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> ceEnter2ArgsPIC [
	<api: 'extern void (*ceEnter2ArgsPIC)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceEnter2ArgsPIC numArgs: 2
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> ceEnterCogCodePopReceiverArg0Regs [
	<api: 'extern void (*ceEnterCogCodePopReceiverArg0Regs)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceEnterCogCodePopReceiverArg0Regs numArgs: 2
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> ceEnterCogCodePopReceiverArg1Arg0Regs [
	<api: 'extern void (*ceEnterCogCodePopReceiverArg1Arg0Regs)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceEnterCogCodePopReceiverArg1Arg0Regs numArgs: 3
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> ceShortCutTraceStore: aProcessorSimulationTrap [
	<doNotGenerate>
	self shortcutTrampoline: aProcessorSimulationTrap
		to: [coInterpreter
				ceTraceStoreOf: (processor registerAt: (methodLabel concreteRegister: TempReg))
				into: (processor registerAt: (methodLabel concreteRegister: ReceiverResultReg))]
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
	 descriptor numBytes > 1 ifTrue:
		[byte1 := objectMemory fetchByte: bytecodePC + 1 ofObject: methodObj.
		 descriptor numBytes > 2 ifTrue:
			[byte2 := objectMemory fetchByte: bytecodePC + 2 ofObject: methodObj.
			 descriptor numBytes > 3 ifTrue:
				[byte3 := objectMemory fetchByte: bytecodePC + 3 ofObject: methodObj.
				 descriptor numBytes > 4 ifTrue:
					[self notYetImplemented]]]].
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
	  initialStackPtr initialOpcodeIndex initialAnnotationIndex |
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
		 [self compileBlockEntry: blockStart.
		  initialStackPtr := simStackPtr.
		  (result := self compileAbstractInstructionsFrom: blockStart startpc + ((self pushNilSize: methodObj) * blockStart numInitialNils)
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
				 annotationIndex := initialAnnotationIndex].
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
	 lookup cache followed by a call of ceSendFromOpenPIC: if the probe fails.
	 Override to push the register args when calling ceSendFromOpenPIC:"
	| jumpSelectorMiss jumpClassMiss itsAHit jumpBCMethod routine |
	<var: #jumpSelectorMiss type: #'AbstractInstruction *'>
	<var: #jumpClassMiss type: #'AbstractInstruction *'>
	<var: #itsAHit type: #'AbstractInstruction *'>
	<var: #jumpBCMethod type: #'AbstractInstruction *'>
	self compilePICProlog: numArgs.
	entry := objectRepresentation genGetClassTagOf: ReceiverResultReg into: ClassReg scratchReg: TempReg.

	"Do first of three probes.  See CoInterpreter>>lookupInMethodCacheSel:classTag:"
	self flag: #lookupInMethodCacheSel:classTag:. "so this method shows up as a sender of lookupInMethodCacheSel:class:"
	self MoveR: ClassReg R: SendNumArgsReg.
	self annotate: (self XorCw: selector R: ClassReg) objRef: selector.
	self LogicalShiftLeftCq: ShiftForWord R: ClassReg.
	self AndCq: MethodCacheMask << ShiftForWord R: ClassReg.
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheSelector << ShiftForWord)
		r: ClassReg
		R: TempReg.
	self annotate: (self CmpCw: selector R: TempReg) objRef: selector.
	jumpSelectorMiss := self JumpNonZero: 0.
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheClass << ShiftForWord)
		r: ClassReg
		R: TempReg.
	self CmpR: SendNumArgsReg R: TempReg.
	jumpClassMiss := self JumpNonZero: 0.

	itsAHit := self Label.
	"Fetch the method.  The interpret trampoline requires the bytecoded method in SendNumArgsReg"
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheMethod << ShiftForWord)
		r: ClassReg
		R: SendNumArgsReg.
	"If the method is compiled jump to its unchecked entry-point, otherwise interpret it."
	objectRepresentation
		genLoadSlot: HeaderIndex sourceReg: SendNumArgsReg destReg: TempReg.
	self MoveR: TempReg R: ClassReg.
	jumpBCMethod := objectRepresentation genJumpSmallIntegerInScratchReg: TempReg.
	jumpBCMethod jmpTarget: interpretCall.
	self AddCq: cmNoCheckEntryOffset R: ClassReg.
	self JumpR: ClassReg.

	"First probe missed.  Do second of three probes.  Shift hash right one and retry."
	jumpSelectorMiss jmpTarget: (jumpClassMiss jmpTarget: self Label).
	self MoveR: SendNumArgsReg R: ClassReg.
	self annotate: (self XorCw: selector R: ClassReg) objRef: selector.
	self LogicalShiftLeftCq: ShiftForWord - 1 R: ClassReg.
	self AndCq: MethodCacheMask << ShiftForWord R: ClassReg.
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheSelector << ShiftForWord)
		r: ClassReg
		R: TempReg.
	self annotate: (self CmpCw: selector R: TempReg) objRef: selector.
	jumpSelectorMiss := self JumpNonZero: 0.
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheClass << ShiftForWord)
		r: ClassReg
		R: TempReg.
	self CmpR: SendNumArgsReg R: TempReg.
	self JumpZero: itsAHit.

	"Second probe missed.  Do last probe.  Shift hash right two and retry."
	jumpSelectorMiss jmpTarget: self Label.
	self MoveR: SendNumArgsReg R: ClassReg.
	self annotate: (self XorCw: selector R: ClassReg) objRef: selector.
	ShiftForWord > 2 ifTrue:
		[self LogicalShiftLeftCq: ShiftForWord - 1 R: ClassReg].
	self AndCq: MethodCacheMask << ShiftForWord R: ClassReg.
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheSelector << ShiftForWord)
		r: ClassReg
		R: TempReg.
	self annotate: (self CmpCw: selector R: TempReg) objRef: selector.
	jumpSelectorMiss := self JumpNonZero: 0.
	self MoveMw: coInterpreter methodCacheAddress asUnsignedInteger + (MethodCacheClass << ShiftForWord)
		r: ClassReg
		R: TempReg.
	self CmpR: SendNumArgsReg R: TempReg.
	self JumpZero: itsAHit.

	"Last probe missed.  Call ceSendFromOpenPIC: to do the full lookup."
	jumpSelectorMiss jmpTarget: self Label.
	self genPushRegisterArgsForNumArgs: numArgs.
	self genSaveStackPointers.
	self genLoadCStackPointers.
	methodLabel addDependent: (self annotateAbsolutePCRef: (self MoveCw: methodLabel asInteger R: SendNumArgsReg)).
	cStackAlignment > BytesPerWord ifTrue:
		[backEnd
			genAlignCStackSavingRegisters: false
			numArgs: 1
			wordAlignment: cStackAlignment / BytesPerWord].
	backEnd genPassReg: SendNumArgsReg asArgument: 0.
	routine := self cCode: '(sqInt)ceSendFromInLineCacheMiss'
					inSmalltalk: [self simulatedAddressFor: #ceSendFromInLineCacheMiss:].
	self annotateCall: (self Call: routine)
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

{ #category : #'bytecode generators' }
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

{ #category : #debugging }
StackToRegisterMappingCogit >> enterCogCodePopReceiverArg0Regs [
	"This is a static version of ceEnterCogCodePopReceiverArg0Regs
	 for break-pointing when debugging in C."
	<api>
	<inline: false>
	"This exists only for break-pointing."
	self cCode: [self realCEEnterCogCodePopReceiverArg0Regs]
		inSmalltalk: [self ceEnterCogCodePopReceiverArg0Regs]
]

{ #category : #debugging }
StackToRegisterMappingCogit >> enterCogCodePopReceiverArg1Arg0Regs [
	"This is a static version of ceEnterCogCodePopReceiverArg1Arg0Regs
	 for break-pointing when debugging in C."
	<api>
	<inline: false>
	"This exists only for break-pointing."
	self cCode: [self realCEEnterCogCodePopReceiverArg1Arg0Regs]
		inSmalltalk: [self ceEnterCogCodePopReceiverArg1Arg0Regs]
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> fixupAt: index [
	<cmacro: '(index) (&fixups[index])'>
	<returnTypeC: #'BytecodeFixup *'>
	(debugFixupBreaks includes: index) ifTrue:
		[self halt].
	^self addressOf: (fixups at: index)
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
	self CmpCq: objectMemory classFloatCompactIndex R: SendNumArgsReg.
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
	self genPushRegisterArgsForNumArgs: methodOrBlockNumArgs.
	jumpFailClass := self Jump: 0.
	jumpImmediate jmpTarget: self Label.
	objectRepresentation smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt := objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg].
	objectRepresentation genConvertSmallIntegerToIntegerInScratchReg: ClassReg.
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
	self CmpCq: objectMemory classFloatCompactIndex R: SendNumArgsReg.
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
	objectRepresentation genConvertSmallIntegerToIntegerInScratchReg: Arg0Reg.
	self ConvertR: Arg0Reg Rd: DPFPReg1.
	self Jump: compare.
	jumpFail jmpTarget: self Label.
	objectRepresentation smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt jmpTarget: jumpFail getJmpTarget].
	^0
]

{ #category : #initialization }
StackToRegisterMappingCogit >> genEnterPICEnilopmartNumArgs: numArgs [
	"Generate special versions of the ceEnterCogCodePopReceiverAndClassRegs
	 enilopmart that also pop register args from the stack to undo the pushing of
	 register args in the abort/miss trampolines."
	<returnTypeC: 'void (*genEnterPICEnilopmartNumArgs(sqInt numArgs))(void)'>
	| size endAddress enilopmart |
	opcodeIndex := 0.
	self genLoadStackPointers.
	self PopR: ClassReg. "cacheTag"
	self PopR: TempReg. "entry-point"
	self PopR: SendNumArgsReg. "retpc"
	numArgs > 0 ifTrue:
		[numArgs > 1 ifTrue:
			[self PopR: Arg1Reg.
			 self assert: self numRegArgs = 2].
		 self PopR: Arg0Reg].
	self PopR: ReceiverResultReg.
	self PushR: SendNumArgsReg. "retpc"
	self JumpR: TempReg.
	self computeMaximumSizes.
	size := self generateInstructionsAt: methodZoneBase.
	endAddress := self outputInstructionsAt: methodZoneBase.
	self assert: methodZoneBase + size = endAddress.
	enilopmart := methodZoneBase.
	methodZoneBase := self alignUptoRoutineBoundary: endAddress.
	backEnd nopsFrom: endAddress to: methodZoneBase - 1.
	self recordGeneratedRunTime: (self trampolineName: 'ceEnterPIC' numArgs: numArgs) address: enilopmart.
	^self cCoerceSimple: enilopmart to: #'void (*)(void)'
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genExtPushClosureBytecode [
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
	numCopied > 0 ifTrue:
		[self ssFlushTo: simStackPtr].
	optStatus isReceiverResultRegLive: false.
	self ssAllocateCallReg: SendNumArgsReg and: ReceiverResultReg.
	"see ceClosureCopyDescriptor:"
	self MoveCq: numArgs + (numCopied << 6) + (bytecodePC + 4 "1 relative" << 12) R: SendNumArgsReg.
	self CallRT: ceClosureCopyTrampoline.
	numCopied > 0 ifTrue:
		[self AddCq: numCopied * BytesPerWord R: SPReg.
		 self ssPop: numCopied].
	^self ssPushRegister: ReceiverResultReg
]

{ #category : #'trampoline support' }
StackToRegisterMappingCogit >> genExternalizePointersForPrimitiveCall [
	" Override to push the register receiver and register arguments, if any."
	self genPushRegisterArgs.
	^super genExternalizePointersForPrimitiveCall
]

{ #category : #'bytecode generators' }
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
			[self CallRT: ceTraceStoreTrampoline].
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
		 self CallRT: ceTraceStoreTrampoline].
	^objectRepresentation
		genStoreSourceReg: valueReg
		slotIndex: slotIndex
		destReg: ReceiverResultReg
		scratchReg: TempReg
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genGetImplicitReceiverFor: selector forPush: forPushSendBar [
	"Cached implicit receiver implementation.  Caller looks like
		mov selector, ClassReg
				call cePushImplicitReceiver
				br continue
		Lclass	.word
		Lmixin:	.word
		continue:
	 If class matches class of receiver then mixin contains either 0 or the implicit receiver.
	 If 0, answer the actual receiver.  This is done in the trampoline.
	 See generateNewspeakRuntime."
	self ssAllocateCallReg: SendNumArgsReg and: ReceiverResultReg and: ClassReg and: Arg1Reg.
	^super genGetImplicitReceiverFor: selector forPush: forPushSendBar
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genJumpBackTo: targetBytecodePC [
	self ssFlushTo: simStackPtr.
	^super genJumpBackTo: targetBytecodePC
]

{ #category : #'bytecode generators' }
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

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genJumpTo: targetBytecodePC [
	self ssFlushTo: simStackPtr.
	^super genJumpTo: targetBytecodePC
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genMarshalledSend: selector numArgs: numArgs [
	<inline: false>
	(objectMemory isYoung: selector) ifTrue:
		[hasYoungReferent := true].
	self assert: needsFrame.
	numArgs > 2 ifTrue:
		[self MoveCq: numArgs R: SendNumArgsReg].
	self MoveCw: selector R: ClassReg.
	self CallSend: (sendTrampolines at: (numArgs min: NumSendTrampolines - 1)).
	optStatus isReceiverResultRegLive: false.
	^self ssPushRegister: ReceiverResultReg
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genMarshalledSendDynamicSuper: selector numArgs: numArgs [
	<inline: false>
	(objectMemory isYoung: selector) ifTrue:
		[hasYoungReferent := true].
	self assert: needsFrame.
	numArgs > 2 ifTrue:
		[self MoveCq: numArgs R: SendNumArgsReg].
	self MoveCw: selector R: ClassReg.
	self CallNewspeakSend: (dynamicSuperSendTrampolines at: (numArgs min: NumSendTrampolines - 1)).
	optStatus isReceiverResultRegLive: false.
	^self ssPushRegister: ReceiverResultReg
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genMarshalledSendSuper: selector numArgs: numArgs [
	<inline: false>
	(objectMemory isYoung: selector) ifTrue:
		[hasYoungReferent := true].
	self assert: needsFrame.
	numArgs > 2 ifTrue:
		[self MoveCq: numArgs R: SendNumArgsReg].
	self MoveCw: selector R: ClassReg.
	self CallSend: (superSendTrampolines at: (numArgs min: NumSendTrampolines - 1)).
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
	self compileTrampolineFor: #ceStackOverflow:
		callJumpBar: true
		numArgs: 1
		arg: SendNumArgsReg
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: nil.
	jumpSICMiss jmpTarget: self Label.
	self genPushRegisterArgsForAbortMissNumArgs: numArgs.
	^self genTrampolineFor: #ceSICMiss:
		called: (self trampolineName: 'ceMethodAbort' numArgs: (numArgs <= self numRegArgs ifTrue: [numArgs] ifFalse: [-1]))
		callJumpBar: true
		numArgs: 1
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: nil
		appendOpcodes: true
]

{ #category : #initialization }
StackToRegisterMappingCogit >> genPICAbortTrampolineFor: numArgs [
	"Generate the abort for a PIC.  This abort performs either a call of
	 ceInterpretMethodFromPIC:receiver: to handle invoking an uncogged
	 target or a call of ceMNUFromPICMNUMethod:receiver: to handle an
	 MNU dispatch in a closed PIC.  It distinguishes the two by testing
	 ClassReg.  If the register is zero then this is an MNU."
	opcodeIndex := 0. 
	self genPushRegisterArgsForAbortMissNumArgs: numArgs.
	^self genInnerPICAbortTrampoline: (self trampolineName: 'cePICAbort' numArgs: (numArgs <= self numRegArgs ifTrue: [numArgs] ifFalse: [-1]))
]

{ #category : #initialization }
StackToRegisterMappingCogit >> genPICMissTrampolineFor: numArgs [
	<inline: false>
	| startAddress |
	startAddress := methodZoneBase.
	opcodeIndex := 0.
	"N.B. a closed PIC jumps to the miss routine, not calls it, so there is only one retpc on the stack."
	self genPushRegisterArgsForNumArgs: numArgs.
	self genTrampolineFor: #ceCPICMiss:receiver:
		called: (self trampolineName: 'cePICMiss' numArgs: (numArgs <= self numRegArgs ifTrue: [numArgs] ifFalse: [-1]))
		callJumpBar: true
		numArgs: 2
		arg: ClassReg
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: nil
		appendOpcodes: true.
	^startAddress
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPopStackBytecode [
	self annotateBytecodeIfAnnotated: self ssTop.
	self ssTop spilled ifTrue:
		[self AddCq: BytesPerWord R: SPReg].
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
StackToRegisterMappingCogit >> genPrimitiveAsFloat [
	| jumpFailAlloc |
	<var: #jumpFailAlloc type: #'AbstractInstruction *'>
	self MoveR: ReceiverResultReg R: TempReg.
	objectRepresentation genConvertSmallIntegerToIntegerInScratchReg: TempReg.
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
	objectRepresentation genConvertSmallIntegerToIntegerInScratchReg: ClassReg.
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
				[self MoveMw: BytesPerWord r: SPReg R: ReceiverResultReg].
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
	objectRepresentation genConvertIntegerToSmallIntegerInScratchReg: TempReg.
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
	objectRepresentation genConvertIntegerToSmallIntegerInScratchReg: TempReg.
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
	| jumpFalse |
	<var: #jumpFalse type: #'AbstractInstruction *'>
	self CmpR: Arg0Reg R: ReceiverResultReg.
	jumpFalse := self JumpNonZero: 0.
	self annotate: (self MoveCw: objectMemory trueObject R: ReceiverResultReg)
		objRef: objectMemory trueObject.
	self RetN: 0.
	jumpFalse jmpTarget: (self annotate: (self MoveCw: objectMemory falseObject R: ReceiverResultReg)
								objRef: objectMemory falseObject).
	self RetN: 0.
	^0
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveIdentityHash [
	| jumpSI jumpNotSet |
	<var: #jumpSI type: #'AbstractInstruction *'>
	<var: #jumpNotSet type: #'AbstractInstruction *'>
	self MoveR: ReceiverResultReg R: ClassReg.
	jumpSI := objectRepresentation genJumpSmallIntegerInScratchReg: ClassReg.
	objectRepresentation genGetHashFieldNonImmOf: ReceiverResultReg asSmallIntegerInto: TempReg.
	objectRepresentation isHashSetOnInstanceCreation ifFalse:
		[self CmpCq: ConstZero R: TempReg.
		 jumpNotSet := self JumpZero: 0].
	self MoveR: TempReg R: ReceiverResultReg.
	self RetN: 0.
	objectRepresentation isHashSetOnInstanceCreation ifFalse:
		[jumpNotSet jmpTarget: self Label.
		 self compileFallbackToInterpreterPrimitive].
	jumpSI jmpTarget: self Label.
	^0
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
	| r |
	(r := objectRepresentation genInnerPrimitiveNew: 0) < 0 ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveNewWithArg [
	| r |
	(r := objectRepresentation genInnerPrimitiveNewWithArg: 0) < 0 ifTrue:
		[^r].
	^self compileFallbackToInterpreterPrimitive
]

{ #category : #'primitive generators' }
StackToRegisterMappingCogit >> genPrimitiveNotIdentical [
	"Receiver and arg in registers.
	 Stack looks like
		return address"
	| jumpFalse |
	<var: #jumpFalse type: #'AbstractInstruction *'>
	self CmpR: Arg0Reg R: ReceiverResultReg.
	jumpFalse := self JumpZero: 0.
	self annotate: (self MoveCw: objectMemory trueObject R: ReceiverResultReg)
		objRef: objectMemory trueObject.
	self RetN: 0.
	jumpFalse jmpTarget: (self annotate: (self MoveCw: objectMemory falseObject R: ReceiverResultReg)
								objRef: objectMemory falseObject).
	self RetN: 0.
	^0
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
	objectRepresentation genConvertIntegerToSmallIntegerInScratchReg: TempReg.
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
	self ssAllocateCallReg: ReceiverResultReg.
	self CallRT: ceActiveContextTrampoline.
	^self ssPushRegister: ReceiverResultReg
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPushClosureCopyCopiedValuesBytecode [
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
	numCopied > 0 ifTrue:
		[self ssFlushTo: simStackPtr].
	optStatus isReceiverResultRegLive: false.
	self ssAllocateCallReg: SendNumArgsReg and: ReceiverResultReg.
	"see ceClosureCopyDescriptor:"
	self MoveCq: numArgs + (numCopied << 6) + (bytecodePC + 5 "1 relative" << 12) R: SendNumArgsReg.
	self CallRT: ceClosureCopyTrampoline.
	numCopied > 0 ifTrue:
		[self AddCq: numCopied * BytesPerWord R: SPReg.
		 self ssPop: numCopied].
	^self ssPushRegister: ReceiverResultReg
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPushExplicitOuterSendReceiver: level [
	"Uncached push explicit outer send receiver"
	self assert: needsFrame. "because this should always be followed by a send"
	optStatus isReceiverResultRegLive: false.
	self ssAllocateCallReg: SendNumArgsReg.
	self MoveCq: level R: SendNumArgsReg.
	self CallRT: ceExplicitReceiverTrampoline.
	^self ssPushRegister: ReceiverResultReg
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPushImplicitReceiverBytecode [
	| result |
	result := self genGetImplicitReceiverFor: (self getLiteral: byte1) forPush: true.
	result ~= 0 ifTrue:
		[^result].
	^self ssPushRegister: ReceiverResultReg
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPushLiteral: literal [
	^self ssPushConstant: literal
]

{ #category : #'bytecode generators' }
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
		genLoadSlot: ValueIndex
		sourceReg: TempReg
		destReg: freeReg.
	self ssPushRegister: freeReg.
	^0
]

{ #category : #'bytecode generators' }
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
	self MoveCq: size R: SendNumArgsReg.
	self CallRT: ceCreateNewArrayTrampoline.
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
	^self ssPushDesc: simSelf
]

{ #category : #'bytecode generators' }
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
		[self genPushRegisterArgsForNumArgs: methodOrBlockNumArgs.
		regArgsHaveBeenPushed := true]
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> genPushRegisterArgsForAbortMissNumArgs: numArgs [
	"Ensure that the register args are pushed before the outer and
	 inner retpcs at an entry miss for arity <= self numRegArgs.  The
	 outer retpc is that of a call at a send site.  The inner is the call
	 from a method or PIC abort/miss to the trampoline."

	"This won't be as clumsy on a RISC.  But putting the receiver and
	 args above the return address means the CoInterpreter has a
	 single machine-code frame format which saves us a lot of work."

	"Iff there are register args convert
		base	->	outerRetpc		(send site retpc)
		sp		->	innerRetpc		(PIC abort/miss retpc)
	 to
		base	->	receiver
					(arg0)
					(arg1)
					outerRetpc
		sp		->	innerRetpc		(PIC abort/miss retpc)"
	numArgs <= self numRegArgs ifTrue:
		[self assert: self numRegArgs <= 2.
		 numArgs = 0 ifTrue:
			[self MoveMw: 0 r: SPReg R: TempReg.
			 self PushR: TempReg.
			 self MoveMw: BytesPerWord * 2 r: SPReg R: TempReg.
			 self MoveR: TempReg Mw: BytesPerWord r: SPReg.
			 self MoveR: ReceiverResultReg Mw: 2 * BytesPerWord r: SPReg.
			 ^self].
		 numArgs = 1 ifTrue:
			[self MoveMw: BytesPerWord r: SPReg R: TempReg.
			 self PushR: TempReg.
			 self MoveMw: BytesPerWord r: SPReg R: TempReg.
			 self PushR: TempReg.
			 self MoveR: ReceiverResultReg Mw: 3 * BytesPerWord r: SPReg.
			 self MoveR: Arg0Reg Mw: 2 * BytesPerWord r: SPReg.
			 ^self].
		 numArgs = 2 ifTrue:
			[self PushR: Arg1Reg.
			 self MoveMw: BytesPerWord * 2 r: SPReg R: TempReg.
			 self PushR: TempReg.
			 self MoveMw: BytesPerWord * 2 r: SPReg R: TempReg.
			 self PushR: TempReg.
			 self MoveR: ReceiverResultReg Mw: 4 * BytesPerWord r: SPReg.
			 self MoveR: Arg0Reg Mw: 3 * BytesPerWord r: SPReg.
			 ^self]]
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> genPushRegisterArgsForNumArgs: numArgs [
	"Ensure that the register args are pushed before the retpc for arity <= self numRegArgs."
	"This won't be as clumsy on a RISC.  But putting the receiver and
	 args above the return address means the CoInterpreter has a
	 single machine-code frame format which saves us a lot of work."
	numArgs <= self numRegArgs ifTrue:
		[self MoveMw: 0 r: SPReg R: TempReg. "Save return address"
		 self MoveR: ReceiverResultReg Mw: 0 r: SPReg.
		 self assert: self numRegArgs <= 2.
		 numArgs > 0 ifTrue:
			[self PushR: Arg0Reg.
			 numArgs > 1 ifTrue:
				[self PushR: Arg1Reg]].
		self PushR: TempReg] "Restore return address"
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

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genPushTemporaryVariable: index [
	^self ssPushDesc: (simStack at: index)
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genReturnTopFromBlock [
	self assert: inBlock.
	self ssTop popToReg: ReceiverResultReg.
	self ssPop: 1.
	needsFrame ifTrue:
		[self MoveR: FPReg R: SPReg.
		 self PopR: FPReg].
	self RetN: methodOrBlockNumArgs + 1 * BytesPerWord.
	^0
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genReturnTopFromMethod [
	self ssTop popToReg: ReceiverResultReg.
	self ssPop: 1.
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSend: selector numArgs: numArgs [
	self marshallSendArguments: numArgs.
	^self genMarshalledSend: selector numArgs: numArgs
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSendAbsentDynamicSuper: selector numArgs: numArgs [
	"OK, we could do better and avoid spilling ReceiverResultReg if we refactored
	 marshallImplicitReceiverSendArguments: to take a flag saying whether the
	 receiver was in ReceiverResultReg (absent receiver send) or on the stack
	 (absent dynamic super send) and in the latter case loading ReceiverResultReg
	 from the stack after marshalling.  But this is a rare bytecode so for the moment
	 don't bother."
	self ssAllocateCallReg: ReceiverResultReg.
	self MoveMw: FoxMFReceiver r: FPReg R: ReceiverResultReg.
	self marshallImplicitReceiverSendArguments: numArgs.
	^self genMarshalledSendDynamicSuper: selector numArgs: numArgs
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSendAbsentImplicit: selector numArgs: numArgs [
	"Get the implicit receiver and marshall arguments, shuffling the
	 stack to push the implicit receiver if necessary. Then send."
	<inline: false>
	| result |
	"This must not be PC-mapped"
	result := self genGetImplicitReceiverFor: selector forPush: false.
	result ~= 0 ifTrue:
		[^result].
	self marshallImplicitReceiverSendArguments: numArgs.
	^self genMarshalledSend: selector numArgs: numArgs
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSendDynamicSuper: selector numArgs: numArgs [
	self marshallSendArguments: numArgs.
	^self genMarshalledSendDynamicSuper: selector numArgs: numArgs
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSendSuper: selector numArgs: numArgs [
	self marshallSendArguments: numArgs.
	^self genMarshalledSendSuper: selector numArgs: numArgs
]

{ #category : #initialization }
StackToRegisterMappingCogit >> genSendTrampolineFor: aRoutine numArgs: numArgs called: aString arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 [
	"Generate a trampoline with four arguments.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	| startAddress |
	<inline: false>
	startAddress := methodZoneBase.
	opcodeIndex := 0.
	self genPushRegisterArgsForNumArgs: numArgs.
	self genTrampolineFor: aRoutine
		called: aString
		callJumpBar: true
		numArgs: 3
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: nil
		saveRegs: false
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
	self genPushRegisterArgsForNumArgs: numArgs.
	self genTrampolineFor: aRoutine
		called: aString
		callJumpBar: true
		numArgs: 4
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: regOrConst3
		saveRegs: false
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
	| jumpDouble jumpFail jumpTrue jumpCond |
	<var: #jumpFPOpcodeGenerator declareC: 'AbstractInstruction *(*jumpFPOpcodeGenerator)(void *)'>
	<var: #jumpDouble type: #'AbstractInstruction *'>
	<var: #jumpFail type: #'AbstractInstruction *'>
	<var: #jumpTrue type: #'AbstractInstruction *'>
	<var: #jumpCond type: #'AbstractInstruction *'>	
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
	objectRepresentation genGetCompactClassIndexNonImmOf: Arg0Reg into: SendNumArgsReg.
	self CmpCq: objectMemory classFloatCompactIndex R: SendNumArgsReg.
	jumpFail := self JumpNonZero: 0.
	
	"It was a Float, so convert the receiver to double and perform the operation"
	objectRepresentation genConvertSmallIntegerToIntegerInScratchReg: ReceiverResultReg.
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
	jumpFail jmpTarget: self Label.
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
		numArgs: 1.
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
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSpecialSelectorEqualsEquals [
	| argReg rcvrReg nextPC postBranchPC targetBytecodePC nExts
	  primDescriptor branchDescriptor jumpEqual jumpNotEqual resultReg |
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpEqual type: #'AbstractInstruction *'>
	<var: #jumpNotEqual type: #'AbstractInstruction *'>
	self flag: 'rewrite this crap.'.
	self ssPop: 2.
	resultReg := self availableRegisterOrNil.
	resultReg ifNil:
		[(self numRegArgs > 1 and: [needsFrame not and: [methodOrBlockNumArgs = 2]]) ifTrue:
			[self halt].
		self ssAllocateRequiredReg: (resultReg := Arg1Reg)].
	self ssPush: 2.
	(self ssTop type = SSConstant
	 and: [self ssTop spilled not]) "if spilled we must generate a real pop"
		ifTrue:
			[(self ssValue: 1) type = SSRegister
				ifTrue: [rcvrReg := (self ssValue: 1) register]
				ifFalse:
					[(self ssValue: 1) popToReg: (rcvrReg := resultReg)].
			(objectRepresentation shouldAnnotateObjectReference: self ssTop constant)
				ifTrue: [self annotate: (self CmpCw: self ssTop constant R: rcvrReg)
							objRef: self ssTop constant]
				ifFalse: [self CmpCq: self ssTop constant R: rcvrReg].
			self ssPop: 1]
		ifFalse:
			[argReg := self ssStorePop: true toPreferredReg: TempReg.
			 rcvrReg := argReg = resultReg
							ifTrue: [TempReg]
							ifFalse: [resultReg].
			self ssTop popToReg: rcvrReg.
			self CmpR: argReg R: rcvrReg].
	self ssPop: 1; ssPushRegister: resultReg.
	primDescriptor := self generatorAt: byte0.
	nextPC := bytecodePC + primDescriptor numBytes.
	nExts := 0.
	[branchDescriptor := self generatorAt: (objectMemory fetchByte: nextPC ofObject: methodObj) + (byte0 bitAnd: 256).
	 branchDescriptor isExtension] whileTrue:
		[nExts := nExts + 1.
		 nextPC := nextPC + branchDescriptor numBytes].
	(branchDescriptor isBranchTrue
	 or: [branchDescriptor isBranchFalse])
		ifTrue:
			[self ssFlushTo: simStackPtr - 1.
			 targetBytecodePC := nextPC
								+ branchDescriptor numBytes
								+ (self spanFor: branchDescriptor at: nextPC exts: nExts in: methodObj).
			 postBranchPC := nextPC + branchDescriptor numBytes.
			 (self fixupAt: nextPC - initialPC) targetInstruction = 0 ifTrue: "The next instruction is dead.  we can skip it."
				[deadCode := true.
				 self ssPop: 1. "the conditional branch bytecodes pop the item tested from the stack."
				 self ensureFixupAt: targetBytecodePC - initialPC.
				 self ensureFixupAt: postBranchPC - initialPC].
			 self gen: (branchDescriptor isBranchTrue
						ifTrue: [JumpZero]
						ifFalse: [JumpNonZero])
				operand: (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.
			 self Jump: (self ensureNonMergeFixupAt: postBranchPC - initialPC)]
		ifFalse:
			[jumpNotEqual := self JumpNonZero: 0.
			 self annotate: (self MoveCw: objectMemory trueObject R: resultReg)
				objRef: objectMemory trueObject.
			 jumpEqual := self Jump: 0.
			 jumpNotEqual jmpTarget: (self annotate: (self MoveCw: objectMemory falseObject R: resultReg)
											objRef: objectMemory falseObject).
			 jumpEqual jmpTarget: self Label].
	resultReg == ReceiverResultReg ifTrue:
		[optStatus isReceiverResultRegLive: false].
	^0
]

{ #category : #'bytecode generators' }
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
	 traceStores > 0 ifTrue:
		[self MoveR: topReg R: TempReg.
		 self CallRT: ceTraceStoreTrampoline].
	^objectRepresentation
		genStoreSourceReg: topReg
		slotIndex: ValueIndex
		destReg: ReceiverResultReg
		scratchReg: TempReg
]

{ #category : #'bytecode generators' }
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

{ #category : #'bytecode generators' }
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

{ #category : #'bytecode generators' }
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

{ #category : #'bytecode generators' }
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
			 self RetN: methodOrBlockNumArgs + 1 * BytesPerWord]
		ifFalse:
			[self RetN: ((methodOrBlockNumArgs > self numRegArgs
						"A method with an interpreter prim will push its register args for the prim.  If the failure
						 body is frameless the args must still be popped, see e.g. Behavior>>nextInstance."
						or: [regArgsHaveBeenPushed])
							ifTrue: [methodOrBlockNumArgs + 1 * BytesPerWord]
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
			[realCEEnterCogCodePopReceiverArg0Regs :=
				self genEnilopmartFor: ReceiverResultReg
					and: Arg0Reg
					called: 'realCEEnterCogCodePopReceiverArg0Regs'.
			 ceEnterCogCodePopReceiverArg0Regs := #enterCogCodePopReceiverArg0Regs.
			 realCEEnterCogCodePopReceiverArg1Arg0Regs :=
				self genEnilopmartFor: ReceiverResultReg
					and: Arg0Reg							
					and: Arg1Reg
					called: 'realCEEnterCogCodePopReceiverArg1Arg0Regs'.
			 ceEnterCogCodePopReceiverArg1Arg0Regs := #enterCogCodePopReceiverArg1Arg0Regs]
		ifFalse:
			[ceEnterCogCodePopReceiverArg0Regs :=
				self genEnilopmartFor: ReceiverResultReg
					and: Arg0Reg
					called: 'ceEnterCogCodePopReceiverArg0Regs'.
			 ceEnterCogCodePopReceiverArg1Arg0Regs :=
				self genEnilopmartFor: ReceiverResultReg
					and: Arg0Reg							
					and: Arg1Reg
					called: 'ceEnterCogCodePopReceiverArg1Arg0Regs'].

	"These are special versions of the ceEnterCogCodePopReceiverAndClassRegs enilopmart that also
	 pop register argsfrom the stack to undo the pushing of register args in the abort/miss trampolines."
	ceEnter0ArgsPIC := self genEnterPICEnilopmartNumArgs: 0.
	self numRegArgs >= 1 ifTrue:
		[ceEnter1ArgsPIC := self genEnterPICEnilopmartNumArgs: 1.
		 self numRegArgs >= 2 ifTrue:
			[ceEnter1ArgsPIC := self genEnterPICEnilopmartNumArgs: 2.
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
			put: (self genPICMissTrampolineFor: numArgs)].
	self cCode: '' inSmalltalk:
		[simulatedTrampolines
			at: (self simulatedAddressFor: #ceSendFromInLineCacheMiss:)
			put: #ceSendFromInLineCacheMiss:]
]

{ #category : #initialization }
StackToRegisterMappingCogit >> generateSendTrampolines [
	"Override to generate code to push the register arg(s) for <= numRegArg arity sends."
	0 to: NumSendTrampolines - 2 do:
		[:numArgs|
		sendTrampolines
			at: numArgs
			put: (self genSendTrampolineFor: #ceSend:super:to:numArgs:
					  numArgs: numArgs
					  called: (self trampolineName: 'ceSend' numArgs: numArgs)
					  arg: ClassReg
					  arg: 0
					  arg: ReceiverResultReg
					  arg: numArgs)].
	sendTrampolines
		at: NumSendTrampolines - 1
		put: (self genSendTrampolineFor: #ceSend:super:to:numArgs:
					numArgs: self numRegArgs + 1
					called: (self trampolineName: 'ceSend' numArgs: -1)
					arg: ClassReg
					arg: 0
					arg: ReceiverResultReg
					arg: SendNumArgsReg).
	self cppIf: NewspeakVM
		ifTrue:
			[0 to: NumSendTrampolines - 2 do:
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
							arg: SendNumArgsReg)].
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
	firstSend := sendTrampolines at: 0.
	lastSend := superSendTrampolines at: NumSendTrampolines - 1
]

{ #category : #initialization }
StackToRegisterMappingCogit >> generateTracingTrampolines [
	"Generate trampolines for tracing.  In the simulator we can save a lot of time
	 and avoid noise instructions in the lastNInstructions log by short-cutting these
	 trampolines, but we need them in the real vm."
	ceTraceLinkedSendTrampoline
		:= self cCode:
					[self genSafeTrampolineFor: #ceTraceLinkedSend:
						called: 'ceTraceLinkedSendTrampoline'
						arg: ReceiverResultReg]
				inSmalltalk:
					[| a |
					 simulatedTrampolines
						at: (a := self simulatedAddressFor: #ceShortCutTraceLinkedSend:)
						put: #ceShortCutTraceLinkedSend:.
					 a].
	ceTraceBlockActivationTrampoline
		:= self cCode:
					[self genTrampolineFor: #ceTraceBlockActivation
						called: 'ceTraceBlockActivationTrampoline']
				inSmalltalk:
					[| a |
					 simulatedTrampolines
						at: (a := self simulatedAddressFor: #ceShortCutTraceBlockActivation:)
						put: #ceShortCutTraceBlockActivation:.
					 a].
	ceTraceStoreTrampoline
		:= self cCode:
					[self genSafeTrampolineFor: #ceTraceStoreOf:into:
						called: 'ceTraceStoreTrampoline'
						arg: TempReg
						arg: ReceiverResultReg]
				inSmalltalk:
					[| a |
					simulatedTrampolines
						at: (a := self simulatedAddressFor: #ceShortCutTraceStore:)
						put: #ceShortCutTraceStore:.
					 a]
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
			offset: FoxCallerSavedIP + ((methodOrBlockNumArgs - i) * BytesPerWord);
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
			offset: FoxMFReceiver - (i - methodOrBlockNumArgs + 1 * BytesPerWord);
			bcptr: startpc]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> initSimStackForFramelessBlock: startpc [
	"The register receiver (he closure itself) and args are pushed by the closure value primitive(s)
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
	self assert: self numRegArgs <= 2.
	0 to: methodOrBlockNumTemps - 1 do:
		[:i|
		desc := self simStackAt: i.
		desc
			type: SSBaseOffset;
			spilled: true;
			annotateUse: false;
			register: SPReg;
			offset: ((methodOrBlockNumTemps - i) * BytesPerWord);
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
	self assert: (methodOrBlockNumTemps = methodOrBlockNumArgs
				or: [coInterpreter isQuickPrimitiveIndex: primitiveIndex]).
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
					offset: ((methodOrBlockNumArgs - i) * BytesPerWord);
					bcptr: startpc]].
	simSpillBase := simStackPtr := methodOrBlockNumArgs - 1
]

{ #category : #initialization }
StackToRegisterMappingCogit >> initializeBackend [
	super initializeBackend.
	callerSavedRegMask := backEnd callerSavedRegisterMask
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
	^self perform: isPushNilFunction
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
StackToRegisterMappingCogit >> marshallImplicitReceiverSendArguments: numArgs [
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
						self MoveMw: index * BytesPerWord r: SPReg R: TempReg.
						self MoveR: TempReg Mw: index - 1 * BytesPerWord r: SPReg].
					 self MoveR: ReceiverResultReg Mw: numSpilled * BytesPerWord r: SPReg]
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
			mergeAt: FoxMFReceiver - (i - methodOrBlockNumArgs + 1 * BytesPerOop)
			from: FPReg]
]

{ #category : #trampolines }
StackToRegisterMappingCogit >> methodAbortTrampolineFor: numArgs [
	^methodAbortTrampolines at: (numArgs min: self numRegArgs + 1)
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

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> numRegArgs [
	<api>
	"Use of the macro allows the compiler to avoid the call and test in cointerpreter.c"
	<cmacro: '() 1'>
	^1
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
	(self isPCMappedAnnotation: annotation annotation
			alternateInstructionSet: bytecodeSetOffset > 0) ifFalse:
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
StackToRegisterMappingCogit >> pushNilSize: aMethodObj [
	<inline: true>
	^self perform: pushNilSizeFunction with: aMethodObj
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
	| descriptor pc end framelessStackDelta nExts pushingNils |
	<var: #blockStart type: #'BlockStart *'>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	needsFrame := false.
	prevBCDescriptor := nil.
	methodOrBlockNumArgs := blockStart numArgs.
	inBlock := true.
	pc := blockStart startpc.
	end := blockStart startpc + blockStart span.
	framelessStackDelta := nExts := 0.
	pushingNils := true.
	[pc < end] whileTrue:
		[byte0 := (objectMemory fetchByte: pc ofObject: methodObj) + bytecodeSetOffset.
		 descriptor := self generatorAt: byte0.
		 needsFrame ifFalse:
			[(descriptor needsFrameFunction isNil
			  or: [self perform: descriptor needsFrameFunction with: framelessStackDelta])
				ifTrue: [needsFrame := true]
				ifFalse: [framelessStackDelta := framelessStackDelta + descriptor stackDelta]].
		 (pushingNils
		  and: [descriptor isExtension not]) ifTrue:
			["Count the initial number of pushed nils acting as temp initializers.  We can't tell
			  whether an initial pushNil is an operand reference or a temp initializer, except
			  when the pushNil is a jump target (has a fixup) in which case it is definitely an
			  operand reference.  So rarely we may end up over-estimating.  We will correct
			  by checking the stack depth at the end of the block in compileBlockBodies."
			 (pushingNils := (self isPushNil: descriptor pc: pc nExts: nExts method: methodObj)
							  and: [(self fixupAt: pc - initialPC) targetInstruction = 0]) ifTrue:
				[self assert: descriptor numBytes = 1. "see compileMethodBody"
				 blockStart numInitialNils: blockStart numInitialNils + 1]].
		 pc := self nextBytecodePCFor: descriptor at: pc exts: nExts in: methodObj.
		 nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0].
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
	(primitiveIndex > 0
	 and: [coInterpreter isQuickPrimitiveIndex: primitiveIndex]) ifTrue:
		[^0].
	pc := latestContinuation := initialPC.
	numBlocks := framelessStackDelta := nExts := 0.
	[pc <= endPC] whileTrue:
		[byte0 := (objectMemory fetchByte: pc ofObject: methodObj) + bytecodeSetOffset.
		descriptor := self generatorAt: byte0.
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
		pc := pc + descriptor numBytes.
		nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0].
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

	isPushNilFunction := self class isPushNilFunction.
	pushNilSizeFunction := self class pushNilSizeFunction.
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> simStackAt: index [
	<cmacro: '(index) (simStack + (index))'>
	<returnTypeC: #'CogSimStackEntry *'>
	^self addressOf: (simStack at: index)
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

{ #category : #'span functions' }
StackToRegisterMappingCogit >> v3: descriptor Is: pc Push: nExts Nil: aMethodObj [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	^descriptor generator == #genPushConstantNilBytecode
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> v3PushNilSize: aMethodObj [
	<inline: true>
	^1
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> v3or4: descriptor Is: pc Push: nExts Nil: aMethodObj [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	^(self v3: descriptor Is: pc Push: nExts Nil: aMethodObj)
	  or: [self v4: descriptor Is: pc Push: nExts Nil: aMethodObj]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> v3or4PushNilSize: aMethodObj [
	^(coInterpreter methodUsesAlternateBytecodeSet: aMethodObj)
		ifTrue: [self v4PushNilSize: aMethodObj]
		ifFalse: [self v3PushNilSize: aMethodObj]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> v4: descriptor Is: pc Push: nExts Nil: aMethodObj [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	^descriptor generator == #genExtPushPseudoVariableOrOuterBytecode
	  and: [self assert: (objectMemory fetchByte: pc ofObject: aMethodObj) = 77.
			nExts = 1
	  and: [(objectMemory fetchByte: pc - 1 ofObject: aMethodObj) = 2]]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> v4PushNilSize: aMethodObj [
	"77			01001101				Push false [* 1:true, 2:nil, 3:thisContext, ..., -N: pushExplicitOuter: N, N = Extend B]
	 225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)"
	<inline: true>
	^3
]
