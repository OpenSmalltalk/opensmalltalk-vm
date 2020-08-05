"
StackToRegisterMappingCogit is an optimizing code generator that eliminates a lot of stack operations and inlines some special selector arithmetic.  It does so by a simple stack-to-register mapping scheme based on deferring the generation of code to produce operands until operand-consuming operations.  The operations that consume operands are sends, stores and returns.  This scheme was first conceived by L. Peter Deutch in the HPS Smalltalk VM (the VisualWorks VM).  Thank you, Peter.

See methods in the class-side documentation protocol for more detail.

Instance Variables
	compilationPass:								<Integer>
	currentCallCleanUpSize:						<Integer>
	ceCall0ArgsPIC:									<Integer>
	ceCall1ArgsPIC:									<Integer>
	ceCall2ArgsPIC:									<Integer>
	ceCallCogCodePopReceiverArg0Regs:			<Integer>
	ceCallCogCodePopReceiverArg1Arg0Regs:		<Integer>
	deadCode										<Boolean>
	debugBytecodePointers:						<Set of Integer>
	debugFixupBreaks:								<Set of Integer>
	debugStackPointers:							<CArrayAccessor of (Integer|nil)>
	hasNativeFrame								<Boolean>
	methodAbortTrampolines:						<CArrayAccessor of Integer>
	methodOrBlockNumTemps:						<Integer>
	numPushNilsFunction:							<Symbol>
	picAbortTrampolines:							<CArrayAccessor of Integer>
	picMissTrampolines:							<CArrayAccessor of Integer>
	pushNilSizeFunction:							<Symbol>
	realCECallCogCodePopReceiverArg0Regs:		<Integer>
	realCECallCogCodePopReceiverArg1Arg0Regs:	<Integer>
	regArgsHaveBeenPushed:						<Boolean>
	simNativeSpillBase:								<Integer>
	simNativeStack:								<CArrayAccessor of CogSimStackNativeEntry>
	simNativeStackPtr:								<Integer>
	simNativeStackSize:							<Integer>
	simSpillBase:									<Integer>
	simStack:										<CArrayAccessor of CogSimStackEntry>
	simStackPtr:									<Integer>
	traceSimStack:									<Integer>
	useTwoPaths									<Boolean>

compilationPass
	- counter indicating whether on the first pass through bytecodes in a V3-style embedded block or not.  The V3 closure implementation uses pushNil to initialize temporary variables and this makes an initial pushNil ambiguous.  With the V3 bytecode set, the JIT must compile to the end of the block to discover if a pushNil is for initializing a temp or to produce an operand.

currentCallCleanUpSize
	- the number of bytes to remove from the stack in a Lowcode call.

ceCall0ArgsPIC ceCall1ArgsPIC ceCall2ArgsPIC
	- the trampoline for entering an N-arg PIC

ceCallCogCodePopReceiverArg0Regs ceCallCogCodePopReceiverArg1Arg0Regs
	- the trampoline for invokinging a method with N register args
	
debugBytecodePointers
	- a Set of bytecode pcs for setting breakpoints (simulation only)

deadCode
	- set to true to indicate that the next bytecode (up to the next fixup) is not reachable.  Used to avoid generating dead code.

debugFixupBreaks
	- a Set of fixup indices for setting breakpoints (simulation only)

debugStackPointers
	- an Array of stack depths for each bytecode for code verification (simulation only)

hasNativeFrame
	- set to true when Lowcode creates a native stack frame for Lowcode callouts.

methodAbortTrampolines
	- a CArrayAccessor of abort trampolines for 0, 1, 2 and N args

methodOrBlockNumTemps
	- the number of method or block temps (including args) in the current compilation unit (method or block)

numPushNilsFunction
	- the function used to determine the number of push nils at the beginning of a block.  This abstracts away from the specific bytecode set(s).

picAbortTrampolines
	- a CArrayAccessor of abort trampolines for 0, 1, 2 and N args

picMissTrampolines
	- a CArrayAccessor of abort trampolines for 0, 1, 2 and N args

pushNilSizeFunction
	- the function used to determine the number of bytes in the push nils bytecode(s) at the beginning of a block.  This abstracts away from the specific bytecode set(s).

realCECallCogCodePopReceiverArg0Regs realCECallCogCodePopReceiverArg1Arg0Regs
	- the real trampolines for invoking machine code with N reg args when in the Debug regime

regArgsHaveBeenPushed
	- whether the register args have been pushed before frame build (e.g. when an interpreter primitive is called)

simNativeSpillBase
	- the variable tracking how much of the Lowcode simulation stack has been spilled to the real stack

simNativeStack
	- the Lowcode simulation stack itself

simNativeStackPtr
	- the pointer to the top of the Lowcode simulation stack

simNativeStackSize
	- the size of the Lowcode stack so far

simSpillBase
	- the variable tracking how much of the simulation stack has been spilled to the real stack

simStack
	- the simulation stack itself, comprising the receiver, arguments, temporaries, and volatile stack contents.  The receiver is the 0'th entry, and the 1st is that of the first argument, etc.

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
		'simStack',
		'simStackPtr',
		'simSpillBase',
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
		'useTwoPaths',
		'currentCallCleanUpSize',
		'simNativeStack',
		'simNativeStackPtr',
		'simNativeSpillBase',
		'simNativeStackSize',
		'hasNativeFrame',
		'compilationPass'
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
StackToRegisterMappingCogit class >> ancilliaryClasses [
	^super ancilliaryClasses,
	  { self basicNew simStackEntryClass. self basicNew bytecodeFixupClass. CogSSOptStatus } ,
	(LowcodeVM ifTrue: [ { self basicNew simStackNativeEntryClass } ] ifFalse: [ #() ])
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
	LowcodeVM ifTrue: [
		aCodeGen var: 'simNativeStack'
			declareC: 'CogSimStackNativeEntry simNativeStack[', self simNativeStackSlots asString, ']'
	].

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
		(1  16   31 genPushLiteralVariable16CasesBytecode			needsFrameNever: 1)
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
		(2 227 227 genExtPushLiteralVariableBytecode			needsFrameNever: 1)
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
		(2 236 236 genCallMappedInlinedPrimitive isMapped hasUnsafeJump)

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
		(3 248 248 genCallPrimitiveBytecode hasUnsafeJump)
		(3 249 249 genExtPushFullClosureBytecode)
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
		(1 200 200 genSpecialSelectorNotEqualsEquals needsFrameNever: notMapped -1) "not mapped because it is directly inlined (for now)"
		(1 201 207 genSpecialSelectorSend isMapped) " #value #value: #do: #new #new: #x #y"
		(1 208 223 genSendLiteralSelector0ArgsBytecode isMapped)
		(1 224 239 genSendLiteralSelector1ArgBytecode isMapped)
		(1 240 255 genSendLiteralSelector2ArgsBytecode isMapped))
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
	SSSpill := 4.
	
	" Native simulation stack"
	SSNativeRegister := 5.
	SSRegisterPair := 6.
	SSRegisterDoubleFloat := 7.
	SSRegisterSingleFloat := 8.

	SSSpillNative := 9.
	SSSpillInt64 := 10.
	SSSpillFloat32 := 11.
	SSSpillFloat64 := 12.

	SSConstantInt32 := 13.
	SSConstantInt64 := 14.
	SSConstantFloat32 := 15.
	SSConstantFloat64 := 16.
	SSConstantNativePointer := 17.
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
StackToRegisterMappingCogit class >> simNativeStackSlots [
	^ self basicNew simNativeStackSlots
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
StackToRegisterMappingCogit >> allocateFloatRegNotConflictingWith: regMask [
	| reg |
	"if there's a free register, use it"
	reg := backEnd availableFloatRegisterOrNoneFor: (self liveFloatRegisters bitOr: regMask).
	reg = NoReg ifTrue: "No free register, choose one that does not conflict with regMask"
		[reg := self freeAnyFloatRegNotConflictingWith: regMask].
	^ reg
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
	| stackEntry mask |
	stackEntry := self ssValue: index.
	mask := stackEntry registerMaskOrNone.
	(mask ~= 0 and: [mask noMask: regMask]) ifTrue: 
		[self flag: #TODO.
		"When one does pushDup on a SSRegister
		 followed by an operation reusing the register 
		 but mutating the value of the register, then the value that was 
		 dup is now refering to the register with a mutated value which
		 is incorrect. This problem is serious as it can happen also with 
		 multiple unsafe instructions (no dup involved)
		 This is not a problem if the operation reusing the register is not 
		 mutating the value of if all the dup values are used in the same 
		 operation.
		 => I think we should introduce allocateRegMutatingStackEntryAt:
		notConflictingWith:upThrough:, used by operations mutating the reg
		value and flushing partially the stack if somewhere between simSpill
		and the ssEntries used by the operation someone uses also the same
		register."
		 ^stackEntry registerOrNone].
	^self allocateRegNotConflictingWith: regMask
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
	
	(self ssTop registerOrNone ~= NoReg and: [ thirdIsReceiver not or: [ self ssTop registerOrNone ~= ReceiverResultReg ] ]) ifTrue: 
		[ topRegistersMask := self registerMaskFor: (rTop := self ssTop registerOrNone)].
	((self ssValue: 1) registerOrNone ~= NoReg and: [ thirdIsReceiver not or: [ (self ssValue: 1) registerOrNone ~= ReceiverResultReg ] ]) ifTrue: 
		[ topRegistersMask := topRegistersMask bitOr: (self registerMaskFor: (rNext := (self ssValue: 1) registerOrNone))].
	((self ssValue: 2) registerOrNone ~= NoReg and: [thirdIsReceiver not or: [ (self ssValue: 2) registerOrNone = ReceiverResultReg ] ]) ifTrue: 
		[ topRegistersMask := topRegistersMask bitOr: (self registerMaskFor: (rThird := (self ssValue: 2) registerOrNone))].
	
	rThird = NoReg ifTrue:
		[ thirdIsReceiver 
			ifTrue:
				[ rThird := ReceiverResultReg.  "Free ReceiverResultReg if it was not free"
				self ssAllocateRequiredReg: ReceiverResultReg.
				self voidReceiverResultRegContainsSelf ]
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
	
	self ssTop  registerOrNone ~= NoReg ifTrue: 
		[ rTop := self ssTop registerOrNone].
	(self ssValue: 1)  registerOrNone ~= NoReg ifTrue: 
		[ topRegistersMask := self registerMaskFor: (rNext := (self ssValue: 1) registerOrNone)].
	
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
		[self voidReceiverResultRegContainsSelf].
	^ reg
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeFloat2: aBlock [
	<option: #LowcodeVM>
	<inline: true>

	| rNext rTop topRegistersMask |
	topRegistersMask := 0.
	rTop := rNext := NoReg.

	self ssNativeTop  nativeFloatRegisterOrNone ~= NoReg ifTrue: 
		[ rTop := self ssNativeTop nativeFloatRegisterOrNone].
	(self ssNativeValue: 1)  nativeFloatRegisterOrNone ~= NoReg ifTrue: 
		[ topRegistersMask := self registerMaskFor: (rNext := (self ssNativeValue: 1) nativeFloatRegisterOrNone)].
	
	rTop = NoReg ifTrue:
		[ rTop := self allocateFloatRegNotConflictingWith: topRegistersMask ].
	
	rNext = NoReg ifTrue:
		[ rNext := self allocateFloatRegNotConflictingWith: (self registerMaskFor: rTop) ].
	self deny: (rTop = NoReg or: [rNext = NoReg]).

	^ aBlock value: rTop value: rNext

]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeFloat2ResultInteger: aBlock [
	<option: #LowcodeVM>
	<inline: true>

	| frNext frTop topRegistersMask rResult |
	topRegistersMask := 0.
	frTop := frNext := NoReg.
	rResult := NoReg.

	self ssNativeTop  nativeFloatRegisterOrNone ~= NoReg ifTrue: 
		[ frTop := self ssNativeTop nativeFloatRegisterOrNone].
	(self ssNativeValue: 1)  nativeFloatRegisterOrNone ~= NoReg ifTrue: 
		[ topRegistersMask := self registerMaskFor: (frNext := (self ssNativeValue: 1) nativeFloatRegisterOrNone)].
	
	frTop = NoReg ifTrue:
		[ frTop := self allocateFloatRegNotConflictingWith: topRegistersMask ].
	
	frNext = NoReg ifTrue:
		[ frNext := self allocateFloatRegNotConflictingWith: (self registerMaskFor: frTop) ].
	
	"Result"
	rResult := self allocateRegNotConflictingWith: 0.

	self deny: (frTop = NoReg or: [frNext = NoReg or: [rResult = NoReg]]).

	^ aBlock value: frTop value: frNext value: rResult

]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeFloat: aBlock [
	<option: #LowcodeVM>
	<inline: true>

	| frTop topRegistersMask |
	topRegistersMask := 0.
	frTop := NoReg.

	self ssNativeTop nativeFloatRegisterOrNone ~= NoReg ifTrue: 
		[ frTop := self ssNativeTop nativeFloatRegisterOrNone].
	
	frTop = NoReg ifTrue:
		[ frTop := self allocateFloatRegNotConflictingWith: topRegistersMask ].
	self deny: (frTop = NoReg).

	^ aBlock value: frTop

]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeFloatInteger: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	"Used by storeFloat32ToMemory and storeFloat64ToMemory"
	| frTop rTop |
	frTop := rTop := NoReg.

	"Integer registers"
	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue: 
		[ rTop := self ssNativeTop nativeRegisterOrNone].

	rTop = NoReg ifTrue:
		[ rTop := self allocateRegNotConflictingWith: 0 ].

	"Float registers"
	(self ssNativeValue: 1) nativeFloatRegisterOrNone ~= NoReg ifTrue: 
		[ frTop := (self ssNativeValue: 1) nativeFloatRegisterOrNone].
	
	frTop = NoReg ifTrue:
		[ frTop := self allocateFloatRegNotConflictingWith: 0 ].
	
	self deny: (frTop = NoReg or: [rTop = NoReg]).

	^ aBlock value: frTop value: rTop
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeFloatResultFloat: aBlock [
	<option: #LowcodeVM>
	<inline: true>

	| frTop frResult |
	frTop := NoReg.
	frResult := NoReg.

	"Float argument"
	self ssNativeTop nativeFloatRegisterOrNone ~= NoReg ifTrue: 
		[ frTop := self ssNativeTop nativeFloatRegisterOrNone].
	
	frTop = NoReg ifTrue:
		[ frTop := self allocateFloatRegNotConflictingWith: self emptyRegisterMask ].
	
	"Float result".
	frResult := self allocateFloatRegNotConflictingWith: (self registerMaskFor: frTop).
	self deny: (frTop = NoReg or: [frResult = NoReg]).

	^ aBlock value: frTop value: frResult

]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeFloatResultInteger2: aBlock [
	<option: #LowcodeVM>
	<inline: true>

	| frTop rResult rResult2 |
	frTop := NoReg.
	rResult2 := rResult := NoReg.

	"Float argument"
	self ssNativeTop nativeFloatRegisterOrNone ~= NoReg ifTrue: 
		[ frTop := self ssNativeTop nativeFloatRegisterOrNone].
	
	frTop = NoReg ifTrue:
		[ frTop := self allocateFloatRegNotConflictingWith: self emptyRegisterMask ].
	
	"Integer result".
	rResult := self allocateRegNotConflictingWith: (self emptyRegisterMask).
	rResult2 := self allocateRegNotConflictingWith: (self registerMaskFor: rResult).
	
	self deny: (frTop = NoReg or: [rResult = NoReg or: [rResult2 = NoReg]]).

	^ aBlock value: frTop value: rResult value: rResult2


]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeFloatResultInteger: aBlock [
	<option: #LowcodeVM>
	<inline: true>

	| frTop rResult |
	frTop := NoReg.
	rResult := NoReg.

	"Float argument"
	self ssNativeTop nativeFloatRegisterOrNone ~= NoReg ifTrue: 
		[ frTop := self ssNativeTop nativeFloatRegisterOrNone].
	
	frTop = NoReg ifTrue:
		[ frTop := self allocateFloatRegNotConflictingWith: self emptyRegisterMask ].
	
	"Integer result".
	rResult := self allocateRegNotConflictingWith: (self emptyRegisterMask).
	
	self deny: (frTop = NoReg or: [rResult = NoReg]).

	^ aBlock value: frTop value: rResult


]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeFloatResultOop: aBlock [
	<option: #LowcodeVM>
	<inline: true>

	| frTop rResult |
	frTop := NoReg.
	rResult := NoReg.

	"Float argument"
	self ssNativeTop  nativeFloatRegisterOrNone ~= NoReg ifTrue: 
		[ frTop := self ssNativeTop nativeFloatRegisterOrNone].
	
	frTop = NoReg ifTrue:
		[ frTop := self allocateFloatRegNotConflictingWith: self emptyRegisterMask ].
	
	"Integer result".
	rResult := self allocateRegNotConflictingWith: (self emptyRegisterMask).
	
	self deny: (frTop = NoReg or: [rResult = NoReg]).

	^ aBlock value: frTop value: rResult


]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeInteger2: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rNext rTop topRegistersMask |
	topRegistersMask := 0.
	rTop := rNext := NoReg.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
		self ssNativeTop nativeRegisterSecondOrNone ~= NoReg ifTrue:
			[ rNext := self ssNativeTop nativeRegisterSecondOrNone]
	].

	rNext = NoReg ifTrue: [
		(self ssNativeValue: 1)  nativeRegisterOrNone ~= NoReg ifTrue: 
			[ topRegistersMask := self registerMaskFor: (rNext := (self ssNativeValue: 1) nativeRegisterOrNone)].
	].

	rTop = NoReg ifTrue:
		[ rTop := self allocateRegNotConflictingWith: topRegistersMask ].
	
	rNext = NoReg ifTrue:
		[ rNext := self allocateRegNotConflictingWith: (self registerMaskFor: rTop) ].

	self deny: (rTop = NoReg or: [rNext = NoReg]).
	^ aBlock value: rTop value: rNext
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeInteger2ResultFloat: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rNext rTop topRegistersMask frResult |
	topRegistersMask := 0.
	rTop := rNext := NoReg.
	frResult := NoReg.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
		self ssNativeTop nativeRegisterSecondOrNone ~= NoReg ifTrue:
			[ rNext := self ssNativeTop nativeRegisterSecondOrNone]
	].

	rNext = NoReg ifTrue: [
		(self ssNativeValue: 1)  nativeRegisterOrNone ~= NoReg ifTrue: 
			[ topRegistersMask := self registerMaskFor: (rNext := (self ssNativeValue: 1) nativeRegisterOrNone)].
	].

	rTop = NoReg ifTrue:
		[ rTop := self allocateRegNotConflictingWith: topRegistersMask ].
	
	rNext = NoReg ifTrue:
		[ rNext := self allocateRegNotConflictingWith: (self registerMaskFor: rTop) ].

	"Results"
	frResult := self allocateFloatRegNotConflictingWith: self emptyRegisterMask.
	
	self deny: (rTop = NoReg or: [rNext = NoReg or: [frResult = NoReg]]).
	
	^ aBlock value: rTop value: rNext value: frResult
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeInteger2ResultInteger2: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rNext rTop topRegistersMask rResult rResult2 |
	topRegistersMask := 0.
	rTop := rNext := NoReg.
	rResult := rResult2 := NoReg.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
		self ssNativeTop nativeRegisterSecondOrNone ~= NoReg ifTrue:
			[ rNext := self ssNativeTop nativeRegisterSecondOrNone]
	].

	rNext = NoReg ifTrue: [
		(self ssNativeValue: 1)  nativeRegisterOrNone ~= NoReg ifTrue: 
			[ topRegistersMask := self registerMaskFor: (rNext := (self ssNativeValue: 1) nativeRegisterOrNone)].
	].

	rTop = NoReg ifTrue:
		[ rTop := self allocateRegNotConflictingWith: topRegistersMask ].
	
	rNext = NoReg ifTrue:
		[ rNext := self allocateRegNotConflictingWith: (self registerMaskFor: rTop) ].

	self deny: (rTop = NoReg or: [rNext = NoReg]).

	"Results"
	rResult := self allocateFloatRegNotConflictingWith: (self registerMaskFor: rTop and: rNext).
	rResult2 := self allocateFloatRegNotConflictingWith: (self registerMaskFor: rTop and: rNext and: rResult).
	self deny: (rResult = NoReg or: [rResult2 = NoReg]).
	
	^ aBlock value: rTop value: rNext value: rResult value: rResult2
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeInteger2ResultInteger: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rNext rTop topRegistersMask rResult |
	topRegistersMask := 0.
	rTop := rNext := NoReg.
	rResult := NoReg.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
		self ssNativeTop nativeRegisterSecondOrNone ~= NoReg ifTrue:
			[ rNext := self ssNativeTop nativeRegisterSecondOrNone]
	].

	rNext = NoReg ifTrue: [
		(self ssNativeValue: 1)  nativeRegisterOrNone ~= NoReg ifTrue: 
			[ topRegistersMask := self registerMaskFor: (rNext := (self ssNativeValue: 1) nativeRegisterOrNone)].
	].

	rTop = NoReg ifTrue:
		[ rTop := self allocateRegNotConflictingWith: topRegistersMask ].
	
	rNext = NoReg ifTrue:
		[ rNext := self allocateRegNotConflictingWith: (self registerMaskFor: rTop) ].

	self deny: (rTop = NoReg or: [rNext = NoReg]).

	"Results"
	rResult := self allocateFloatRegNotConflictingWith: (self registerMaskFor: rTop and: rNext).
	self deny: (rResult = NoReg).
	
	^ aBlock value: rTop value: rNext value: rResult
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeInteger2ResultOop: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rNext rTop topRegistersMask rResult |
	topRegistersMask := 0.
	rTop := rNext := NoReg.
	rResult := NoReg.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
		self ssNativeTop nativeRegisterSecondOrNone ~= NoReg ifTrue:
			[ rNext := self ssNativeTop nativeRegisterSecondOrNone]
	].

	rNext = NoReg ifTrue: [
		(self ssNativeValue: 1)  nativeRegisterOrNone ~= NoReg ifTrue: 
			[ topRegistersMask := self registerMaskFor: (rNext := (self ssNativeValue: 1) nativeRegisterOrNone)].
	].

	rTop = NoReg ifTrue:
		[ rTop := self allocateRegNotConflictingWith: topRegistersMask ].
	
	rNext = NoReg ifTrue:
		[ rNext := self allocateRegNotConflictingWith: (self registerMaskFor: rTop) ].

	self deny: (rTop = NoReg or: [rNext = NoReg]).

	"Results"
	rResult := self allocateFloatRegNotConflictingWith: (self registerMaskFor: rTop and: rNext).
	self deny: (rResult = NoReg).
	
	^ aBlock value: rTop value: rNext value: rResult
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeInteger3: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rNext rNextNext nativeValueIndex rTop nextRegisterMask |
	rTop := rNext := rNextNext := NoReg.
	nativeValueIndex := 1.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
		self ssNativeTop nativeRegisterSecondOrNone ~= NoReg ifTrue:
			[ rNext := self ssNativeTop nativeRegisterSecondOrNone]
	].

	rNext = NoReg ifTrue: [
		(self ssNativeValue: nativeValueIndex)  nativeRegisterOrNone ~= NoReg ifTrue:  [
			rNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			(self ssNativeValue: nativeValueIndex) nativeRegisterSecondOrNone ~= NoReg ifTrue: [
				rNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterSecondOrNone.
			].
			nativeValueIndex := nativeValueIndex + 1
		].
	].

	rNextNext = NoReg ifTrue: [
		(self ssNativeValue: nativeValueIndex)  nativeRegisterOrNone ~= NoReg ifTrue:  [
			rNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
		].
	].

	rTop = NoReg ifTrue: [
		nextRegisterMask := 0.
		rNext ~= NoReg ifTrue: [ nextRegisterMask := self registerMaskFor: rNext].
		rNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNext)].
		rTop := self allocateRegNotConflictingWith: nextRegisterMask
	].
	
	rNext = NoReg ifTrue: [
		nextRegisterMask := self registerMaskFor: rTop.
		rNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNext)].
		rNext := self allocateRegNotConflictingWith: nextRegisterMask
	].

	rNextNext = NoReg ifTrue: [
		nextRegisterMask := self registerMaskFor: rTop and: rNext.
		rNextNext := self allocateRegNotConflictingWith: nextRegisterMask
	].

	self deny: (rTop = NoReg or: [rNext = NoReg or: [rNextNext = NoReg]]).
	^ aBlock value: rTop value: rNext value: rNextNext
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeInteger3ResultInteger: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rNext rNextNext rResult nativeValueIndex rTop nextRegisterMask |
	rTop := rNext := rNextNext := NoReg.
	nativeValueIndex := 1.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
		self ssNativeTop nativeRegisterSecondOrNone ~= NoReg ifTrue:
			[ rNext := self ssNativeTop nativeRegisterSecondOrNone]
	].

	rNext = NoReg ifTrue: [
		(self ssNativeValue: nativeValueIndex)  nativeRegisterOrNone ~= NoReg ifTrue:  [
			rNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			(self ssNativeValue: nativeValueIndex) nativeRegisterSecondOrNone ~= NoReg ifTrue: [
				rNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterSecondOrNone.
			].
			nativeValueIndex := nativeValueIndex + 1
		].
	].

	rNextNext = NoReg ifTrue: [
		(self ssNativeValue: nativeValueIndex)  nativeRegisterOrNone ~= NoReg ifTrue:  [
			rNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
		].
	].

	rTop = NoReg ifTrue: [
		nextRegisterMask := 0.
		rNext ~= NoReg ifTrue: [ nextRegisterMask := self registerMaskFor: rNext].
		rNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNext)].
		rTop := self allocateRegNotConflictingWith: nextRegisterMask
	].
	
	rNext = NoReg ifTrue: [
		nextRegisterMask := self registerMaskFor: rTop.
		rNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNext)].
		rNext := self allocateRegNotConflictingWith: nextRegisterMask
	].

	rNextNext = NoReg ifTrue: [
		nextRegisterMask := self registerMaskFor: rTop and: rNext.
		rNextNext := self allocateRegNotConflictingWith: nextRegisterMask
	].

	self deny: (rTop = NoReg or: [rNext = NoReg or: [rNextNext = NoReg]]).
	
	"Allocate the result"
	rResult := self allocateRegNotConflictingWith: (self registerMaskFor: rTop and: rNext and: rNextNext).
	self deny: (rResult = NoReg).
	
	^ aBlock value: rTop value: rNext value: rNextNext value: rResult

]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeInteger4: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rNext rNextNext rNextNextNext nativeValueIndex rTop nextRegisterMask |
	rTop := rNext := rNextNext := rNextNextNext := NoReg.
	nativeValueIndex := 1.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
		self ssNativeTop nativeRegisterSecondOrNone ~= NoReg ifTrue:
			[ rNext := self ssNativeTop nativeRegisterSecondOrNone]
	].

	rNext = NoReg ifTrue: [
		(self ssNativeValue: nativeValueIndex)  nativeRegisterOrNone ~= NoReg ifTrue:  [
			rNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			(self ssNativeValue: nativeValueIndex) nativeRegisterSecondOrNone ~= NoReg ifTrue: [
				rNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			].
			nativeValueIndex := nativeValueIndex + 1
		].
	].

	rNextNext = NoReg ifTrue: [
		(self ssNativeValue: nativeValueIndex)  nativeRegisterOrNone ~= NoReg ifTrue:  [
			rNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			(self ssNativeValue: nativeValueIndex) nativeRegisterSecondOrNone ~= NoReg ifTrue: [
				rNextNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterSecondOrNone.
			].
			nativeValueIndex := nativeValueIndex + 1
		].
	].

	rNextNextNext = NoReg ifTrue: [
		(self ssNativeValue: nativeValueIndex)  nativeRegisterOrNone ~= NoReg ifTrue:  [
			rNextNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			nativeValueIndex := nativeValueIndex + 1
		].
	].

	rTop = NoReg ifTrue: [
		nextRegisterMask := 0.
		rNext ~= NoReg ifTrue: [ nextRegisterMask := self registerMaskFor: rNext].
		rNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNext)].
		rNextNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNextNext)].
		rTop := self allocateRegNotConflictingWith: nextRegisterMask
	].
	
	rNext = NoReg ifTrue: [
		nextRegisterMask := self registerMaskFor: rTop.
		rNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNext)].
		rNextNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNextNext)].
		rNext := self allocateRegNotConflictingWith: nextRegisterMask
	].

	rNextNext = NoReg ifTrue: [
		nextRegisterMask := self registerMaskFor: rTop and: rNext.
		rNextNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNextNext)].
		rNextNext := self allocateRegNotConflictingWith: nextRegisterMask
	].

	rNextNextNext = NoReg ifTrue: [
		nextRegisterMask := self registerMaskFor: rTop and: rNext and: rNextNext.
		rNextNextNext := self allocateRegNotConflictingWith: nextRegisterMask
	].

	self deny: (rTop = NoReg or: [rNext = NoReg or: [rNextNext = NoReg or: [rNextNextNext = NoReg]]]).
	^ aBlock value: rTop value: rNext value: rNextNext value: rNextNextNext
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeInteger4ResultInteger2: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rNext rNextNext rNextNextNext nativeValueIndex rTop nextRegisterMask rResult rResult2 |
	rTop := rNext := rNextNext := rNextNextNext := NoReg.
	rResult := rResult2 := NoReg.
	nativeValueIndex := 1.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
		self ssNativeTop nativeRegisterSecondOrNone ~= NoReg ifTrue:
			[ rNext := self ssNativeTop nativeRegisterSecondOrNone]
	].

	rNext = NoReg ifTrue: [
		(self ssNativeValue: nativeValueIndex)  nativeRegisterOrNone ~= NoReg ifTrue:  [
			rNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			(self ssNativeValue: nativeValueIndex) nativeRegisterSecondOrNone ~= NoReg ifTrue: [
				rNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			].
			nativeValueIndex := nativeValueIndex + 1
		].
	].

	rNextNext = NoReg ifTrue: [
		(self ssNativeValue: nativeValueIndex)  nativeRegisterOrNone ~= NoReg ifTrue:  [
			rNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			(self ssNativeValue: nativeValueIndex) nativeRegisterSecondOrNone ~= NoReg ifTrue: [
				rNextNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterSecondOrNone.
			].
			nativeValueIndex := nativeValueIndex + 1
		].
	].

	rNextNextNext = NoReg ifTrue: [
		(self ssNativeValue: nativeValueIndex)  nativeRegisterOrNone ~= NoReg ifTrue:  [
			rNextNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			nativeValueIndex := nativeValueIndex + 1
		].
	].

	rTop = NoReg ifTrue: [
		nextRegisterMask := 0.
		rNext ~= NoReg ifTrue: [ nextRegisterMask := self registerMaskFor: rNext].
		rNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNext)].
		rNextNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNextNext)].
		rTop := self allocateRegNotConflictingWith: nextRegisterMask
	].
	
	rNext = NoReg ifTrue: [
		nextRegisterMask := self registerMaskFor: rTop.
		rNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNext)].
		rNextNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNextNext)].
		rNext := self allocateRegNotConflictingWith: nextRegisterMask
	].

	rNextNext = NoReg ifTrue: [
		nextRegisterMask := self registerMaskFor: rTop and: rNext.
		rNextNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNextNext)].
		rNextNext := self allocateRegNotConflictingWith: nextRegisterMask
	].

	rNextNextNext = NoReg ifTrue: [
		nextRegisterMask := self registerMaskFor: rTop and: rNext and: rNextNext.
		rNextNextNext := self allocateRegNotConflictingWith: nextRegisterMask
	].

	self deny: (rTop = NoReg or: [rNext = NoReg or: [rNextNext = NoReg or: [rNextNextNext = NoReg]]]).
	
	"Result registers"
	rResult := self allocateRegNotConflictingWith: (self registerMaskFor: rTop and: rNext and: rNextNext and: rNextNextNext).
	rResult2 := self allocateRegNotConflictingWith: (self registerMaskFor: rTop and: rNext and: rNextNext and: rNextNextNext and: rResult).
	
	^ aBlock value: rTop value: rNext value: rNextNext value: rNextNextNext value: rResult value: rResult2

]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeInteger4ResultInteger: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rNext rNextNext rNextNextNext nativeValueIndex rTop nextRegisterMask rResult |
	rTop := rNext := rNextNext := rNextNextNext := NoReg.
	rResult := NoReg.
	nativeValueIndex := 1.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
		self ssNativeTop nativeRegisterSecondOrNone ~= NoReg ifTrue:
			[ rNext := self ssNativeTop nativeRegisterSecondOrNone]
	].

	rNext = NoReg ifTrue: [
		(self ssNativeValue: nativeValueIndex)  nativeRegisterOrNone ~= NoReg ifTrue:  [
			rNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			(self ssNativeValue: nativeValueIndex) nativeRegisterSecondOrNone ~= NoReg ifTrue: [
				rNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			].
			nativeValueIndex := nativeValueIndex + 1
		].
	].

	rNextNext = NoReg ifTrue: [
		(self ssNativeValue: nativeValueIndex)  nativeRegisterOrNone ~= NoReg ifTrue:  [
			rNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			(self ssNativeValue: nativeValueIndex) nativeRegisterSecondOrNone ~= NoReg ifTrue: [
				rNextNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterSecondOrNone.
			].
			nativeValueIndex := nativeValueIndex + 1
		].
	].

	rNextNextNext = NoReg ifTrue: [
		(self ssNativeValue: nativeValueIndex)  nativeRegisterOrNone ~= NoReg ifTrue:  [
			rNextNextNext := (self ssNativeValue: nativeValueIndex) nativeRegisterOrNone.
			nativeValueIndex := nativeValueIndex + 1
		].
	].

	rTop = NoReg ifTrue: [
		nextRegisterMask := 0.
		rNext ~= NoReg ifTrue: [ nextRegisterMask := self registerMaskFor: rNext].
		rNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNext)].
		rNextNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNextNext)].
		rTop := self allocateRegNotConflictingWith: nextRegisterMask
	].
	
	rNext = NoReg ifTrue: [
		nextRegisterMask := self registerMaskFor: rTop.
		rNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNext)].
		rNextNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNextNext)].
		rNext := self allocateRegNotConflictingWith: nextRegisterMask
	].

	rNextNext = NoReg ifTrue: [
		nextRegisterMask := self registerMaskFor: rTop and: rNext.
		rNextNextNext ~= NoReg ifTrue: [ nextRegisterMask := nextRegisterMask bitOr: (self registerMaskFor: rNextNextNext)].
		rNextNext := self allocateRegNotConflictingWith: nextRegisterMask
	].

	rNextNextNext = NoReg ifTrue: [
		nextRegisterMask := self registerMaskFor: rTop and: rNext and: rNextNext.
		rNextNextNext := self allocateRegNotConflictingWith: nextRegisterMask
	].

	self deny: (rTop = NoReg or: [rNext = NoReg or: [rNextNext = NoReg or: [rNextNextNext = NoReg]]]).
	
	"Result registers"
	rResult := self allocateRegNotConflictingWith: (self registerMaskFor: rTop and: rNext and: rNextNext and: rNextNextNext).
	
	^ aBlock value: rTop value: rNext value: rNextNext value: rNextNextNext value: rResult

]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeInteger7ResultInteger: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	"Effective address 64. This instruction should not be generated on 32-bits mode"
	self abort

]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeInteger: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rTop |
	rTop := NoReg.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
	].

	rTop = NoReg ifTrue:
		[ rTop := self allocateRegNotConflictingWith: self emptyRegisterMask].

	self deny: (rTop = NoReg).
	^ aBlock value: rTop
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeIntegerOop2: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rTop rOopTop rOopNext topRegisterMask oopTopRegisterMask |
	rTop := rOopTop := rOopNext := NoReg.
	oopTopRegisterMask := topRegisterMask := 0.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
		oopTopRegisterMask := self registerMaskFor: rTop.
	].

	self ssTop registerOrNone ~= NoReg ifTrue:  [
		rOopTop := self ssTop registerOrNone.
		topRegisterMask := self registerMaskFor: rOopTop.
	].

	(self ssValue: 1) registerOrNone ~= NoReg ifTrue: [
		rOopNext := (self ssValue: 1) registerOrNone.
		topRegisterMask := topRegisterMask bitOr: (self registerMaskFor: rOopNext).
		oopTopRegisterMask := oopTopRegisterMask bitOr: (self registerMaskFor: rOopNext).
	].

	rTop = NoReg ifTrue: [
		rTop := self allocateRegNotConflictingWith: topRegisterMask
	].

	rOopTop = NoReg ifTrue: [
		rOopTop := self allocateRegNotConflictingWith: oopTopRegisterMask
	].

	rOopNext = NoReg ifTrue: [
		rOopNext := self allocateRegNotConflictingWith: (self registerMaskFor: rTop and: rOopTop)
	].

	self deny: (rTop = NoReg or: [rOopTop = NoReg or: [rOopNext = NoReg]]).
	^ aBlock value: rTop value: rOopTop value: rOopNext
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeIntegerOop: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rTop rOopTop topRegisterMask |
	rTop := rOopTop := NoReg.
	topRegisterMask := 0.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
	].

	self ssTop registerOrNone ~= NoReg ifTrue:  [
		rOopTop := self ssTop registerOrNone.
		topRegisterMask := self registerMaskFor: rOopTop.
	].

	rTop = NoReg ifTrue: [
		rTop := self allocateRegNotConflictingWith: topRegisterMask
	].

	rOopTop = NoReg ifTrue: [
		rOopTop := self allocateRegNotConflictingWith: (self registerMaskFor: rTop)
	].

	self deny: (rTop = NoReg or: [rOopTop = NoReg]).
	^ aBlock value: rTop value: rOopTop

]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeIntegerOopResultOop: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rTop rOopTop rOopResult topRegisterMask |
	rTop := rOopTop:= NoReg.
	rOopResult := NoReg.
	topRegisterMask := 0.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
	].

	self ssTop registerOrNone ~= NoReg ifTrue:  [
		rOopTop := self ssTop registerOrNone.
		topRegisterMask := self registerMaskFor: rOopTop.
	].

	rTop = NoReg ifTrue: [
		rTop := self allocateRegNotConflictingWith: topRegisterMask
	].

	rOopTop = NoReg ifTrue: [
		rOopTop := self allocateRegNotConflictingWith: (self registerMaskFor: rTop)
	].

	rOopResult := self allocateRegNotConflictingWith: (self registerMaskFor: rTop and: rOopTop).

	self deny: (rTop = NoReg or: [rOopTop = NoReg or: [rOopResult = NoReg]]).
	
	^ aBlock value: rTop value: rOopTop value: rOopResult

]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeIntegerResultFloat: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rTop frResult|
	rTop := NoReg.
	frResult := NoReg.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
	].

	rTop = NoReg ifTrue:
		[ rTop := self allocateRegNotConflictingWith: self emptyRegisterMask].
	
	frResult := self allocateFloatRegNotConflictingWith: self emptyRegisterMask.

	self deny: (rTop = NoReg or: [frResult = NoReg]).
	^ aBlock value: rTop value: frResult
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeIntegerResultInteger2: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rTop rResult rResult2 |
	rTop := NoReg.
	rResult := rResult := NoReg.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
	].

	rTop = NoReg ifTrue:
		[ rTop := self allocateRegNotConflictingWith: self emptyRegisterMask].
	
	rResult := self allocateRegNotConflictingWith: (self registerMaskFor: rTop).
	rResult2 := self allocateRegNotConflictingWith: (self registerMaskFor: rTop and: rResult).

	self deny: (rTop = NoReg or: [rResult = NoReg or: [rResult2 = NoReg]]).
	^ aBlock value: rTop value: rResult value: rResult2
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeIntegerResultInteger: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rTop rResult|
	rTop := NoReg.
	rResult := NoReg.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
	].

	rTop = NoReg ifTrue:
		[ rTop := self allocateRegNotConflictingWith: self emptyRegisterMask].
	
	rResult := self allocateRegNotConflictingWith: (self registerMaskFor: rTop).

	self deny: (rTop = NoReg or: [rResult = NoReg]).
	^ aBlock value: rTop value: rResult
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeIntegerResultOop: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rTop rResult|
	rTop := NoReg.
	rResult := NoReg.

	self ssNativeTop nativeRegisterOrNone ~= NoReg ifTrue:  [
		rTop := self ssNativeTop nativeRegisterOrNone.
	].

	rTop = NoReg ifTrue:
		[ rTop := self allocateRegNotConflictingWith: self emptyRegisterMask].
	
	rResult := self allocateRegNotConflictingWith: (self registerMaskFor: rTop).

	self deny: (rTop = NoReg or: [rResult = NoReg]).
	^ aBlock value: rTop value: rResult
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeOop2: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rOopTop rOopNext oopTopRegisterMask |
	rOopTop := rOopNext := NoReg.
	oopTopRegisterMask := 0.

	self ssTop registerOrNone ~= NoReg ifTrue:  [
		rOopTop := self ssTop registerOrNone.
		"Ensure we are not using a duplicated register."
		(self isOopRegister: rOopTop usedBefore: 0) ifTrue: [
			rOopTop := NoReg
		]
	].

	(self ssValue: 1) registerOrNone ~= NoReg ifTrue: [
		rOopNext := (self ssValue: 1) registerOrNone.
		"Ensure we are not using a duplicated register."
		(self isOopRegister: rOopNext usedBefore: 1) ifTrue: [
			rOopNext := NoReg
		].
		rOopNext ~= NoReg ifTrue: [ 
			oopTopRegisterMask := self registerMaskFor: rOopNext.
		].
	].

	rOopTop = NoReg ifTrue: [
		rOopTop := self allocateRegNotConflictingWith: oopTopRegisterMask
	].

	rOopNext = NoReg ifTrue: [
		rOopNext := self allocateRegNotConflictingWith: (self registerMaskFor: rOopTop)
	].

	self deny: (rOopTop = NoReg or: [rOopNext = NoReg ]).
	^ aBlock value: rOopTop value: rOopNext
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeOop2ResultInteger: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rOopTop rOopNext rResult oopTopRegisterMask |
	rOopTop := rOopNext := NoReg.
	rResult := NoReg.
	oopTopRegisterMask := 0.

	self ssTop registerOrNone ~= NoReg ifTrue:  [
		rOopTop := self ssTop registerOrNone.
		"Ensure we are not using a duplicated register."
		(self isOopRegister: rOopTop usedBefore: 0) ifTrue: [
			rOopTop := NoReg
		]
	].

	(self ssValue: 1) registerOrNone ~= NoReg ifTrue: [
		rOopNext := (self ssValue: 1) registerOrNone.
		"Ensure we are not using a duplicated register."
		(self isOopRegister: rOopNext usedBefore: 1) ifTrue: [
			rOopNext := NoReg
		].
		rOopNext ~= NoReg ifTrue: [ 
			oopTopRegisterMask := self registerMaskFor: rOopNext.
		].
	].

	rOopTop = NoReg ifTrue: [
		rOopTop := self allocateRegNotConflictingWith: oopTopRegisterMask
	].

	rOopNext = NoReg ifTrue: [
		rOopNext := self allocateRegNotConflictingWith: (self registerMaskFor: rOopTop).
	].

	rResult := self allocateRegNotConflictingWith: (self registerMaskFor: rOopTop and: rOopNext).
	
	self deny: (rOopTop = NoReg or: [rOopNext = NoReg or: [rResult = NoReg]]).
	^ aBlock value: rOopTop value: rOopNext value: rResult
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeOop: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rOopTop  |
	rOopTop := NoReg.

	self ssTop registerOrNone ~= NoReg ifTrue:  [
		rOopTop := self ssTop registerOrNone.
		"Ensure we are not using a duplicated register."
		(self isOopRegister: rOopTop usedBefore: 0) ifTrue: [
			rOopTop := NoReg
		]
	].

	rOopTop = NoReg ifTrue: [
		rOopTop := self allocateRegNotConflictingWith: (self emptyRegisterMask)
	].

	self deny: (rOopTop = NoReg).
	^ aBlock value: rOopTop
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeOopResultFloat: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rOopTop  frResult |
	rOopTop := NoReg.
	frResult := NoReg.

	self ssTop registerOrNone ~= NoReg ifTrue:  [
		rOopTop := self ssTop registerOrNone.
		"Ensure we are not using a duplicated register."
		(self isOopRegister: rOopTop usedBefore: 0) ifTrue: [
			rOopTop := NoReg
		]
	].

	rOopTop = NoReg ifTrue: [
		rOopTop := self allocateRegNotConflictingWith: (self emptyRegisterMask)
	].

	frResult := self allocateFloatRegNotConflictingWith: (self emptyRegisterMask).

	self deny: (rOopTop = NoReg or: [frResult = NoReg]).
	^ aBlock value: rOopTop value: frResult
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeOopResultInteger2: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rOopTop rResult rResult2 |
	rOopTop := NoReg.
	rResult := rResult2 := NoReg.

	self ssTop registerOrNone ~= NoReg ifTrue:  [
		rOopTop := self ssTop registerOrNone.
		"Ensure we are not using a duplicated register."
		(self isOopRegister: rOopTop usedBefore: 0) ifTrue: [
			rOopTop := NoReg
		]
	].

	rOopTop = NoReg ifTrue: [
		rOopTop := self allocateRegNotConflictingWith: (self emptyRegisterMask)
	].

	rResult := self allocateRegNotConflictingWith: (self registerMaskFor: rOopTop).
	rResult2 := self allocateRegNotConflictingWith: (self registerMaskFor: rOopTop and: rResult).

	self deny: (rOopTop = NoReg or: [rResult = NoReg]).
	^ aBlock value: rOopTop value: rResult value: rResult2
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeOopResultInteger: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rOopTop rResult |
	rOopTop := NoReg.
	rResult := NoReg.

	self ssTop registerOrNone ~= NoReg ifTrue:  [
		rOopTop := self ssTop registerOrNone.
		"Ensure we are not using a duplicated register."
		(self isOopRegister: rOopTop usedBefore: 0) ifTrue: [
			rOopTop := NoReg
		]
	].

	rOopTop = NoReg ifTrue: [
		rOopTop := self allocateRegNotConflictingWith: (self emptyRegisterMask)
	].

	rResult := self allocateRegNotConflictingWith: (self registerMaskFor: rOopTop).

	self deny: (rOopTop = NoReg or: [rResult = NoReg]).
	^ aBlock value: rOopTop value: rResult
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeOopResultOop: aBlock [
	<option: #LowcodeVM>
	<inline: true>
	
	| rOopTop rResult |
	rOopTop := NoReg.
	rResult := NoReg.

	self ssTop registerOrNone ~= NoReg ifTrue:  [
		rOopTop := self ssTop registerOrNone.
		"Ensure we are not using a duplicated register."
		(self isOopRegister: rOopTop usedBefore: 0) ifTrue: [
			rOopTop := NoReg
		]
	].

	rOopTop = NoReg ifTrue: [
		rOopTop := self allocateRegNotConflictingWith: (self emptyRegisterMask)
	].

	rResult := self allocateRegNotConflictingWith: (self registerMaskFor: rOopTop).

	self deny: (rOopTop = NoReg or: [rResult = NoReg]).
	^ aBlock value: rOopTop value: rResult
	
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeResultFloat: aBlock [
	<option: #LowcodeVM>
	<inline: true>

	| frResult |
	frResult := NoReg.

	"Float result".
	frResult := self allocateFloatRegNotConflictingWith: (self emptyRegisterMask).
	self deny: (frResult = NoReg).

	^ aBlock value: frResult

]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeResultInteger2: aBlock [
	<option: #LowcodeVM>
	<inline: true>

	| rResult rResult2 |
	rResult := rResult2 := NoReg.

	"Float result".
	rResult := self allocateRegNotConflictingWith: (self emptyRegisterMask).
	rResult2 := self allocateRegNotConflictingWith: (self registerMaskFor: rResult).
	self deny: (rResult = NoReg or: [rResult2 = NoReg]).

	^ aBlock value: rResult value: rResult2

]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> allocateRegistersForLowcodeResultInteger: aBlock [
	<option: #LowcodeVM>
	<inline: true>

	| rResult |
	rResult := NoReg.

	"Float result".
	rResult := self allocateRegNotConflictingWith: (self emptyRegisterMask).
	self deny: (rResult = NoReg).

	^ aBlock value: rResult

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
StackToRegisterMappingCogit >> anyReferencesToRegister: reg inAllButTopNItems: n [
	| regMask |
	regMask := self registerMaskFor: reg.
	simStackPtr - n to: 0 by: -1 do:
		[:i|
		((self simStackAt: i) registerMask anyMask: regMask) ifTrue:
			[^true]].
	^false
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
	<inline: true>
	"Would like to assert simply simSpillBase > methodOrBlockNumTemps but can't because
	 of the initialNils hack for nested blocks in SqueakV3PlusClosures"
	self assert: (simSpillBase >= methodOrBlockNumTemps
				or: [self maybeCompilingFirstPassOfBlockWithInitialPushNil and: [simSpillBase > methodOrBlockNumArgs]]).
	(needsFrame and: [simSpillBase > 0]) ifTrue:
		[self assert: (self simStackAt: simSpillBase - 1) spilled == true.
		 self assert: (simSpillBase > simStackPtr or: [(self simStackAt: simSpillBase) spilled == false])].
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

{ #category : #'inline ffi' }
StackToRegisterMappingCogit >> beginHighLevelCall: alignment [
	<option: #LowcodeVM>
	| mask actualAlignment |

	"Store the smalltalk pointers"
	self ssFlushAll.
	self MoveR: SPReg Aw: coInterpreter stackPointerAddress.
	self MoveR: FPReg Aw: coInterpreter framePointerAddress.
	backEnd hasLinkRegister ifTrue: [
		self MoveAw: coInterpreter instructionPointerAddress R: LinkReg
	].

	"Load the C pointers"
	self MoveAw: self cStackPointerAddress R: SPReg.

	"Load the native stack frame pointer"
	self MoveMw: self frameOffsetOfNativeFramePointer r: FPReg R: FPReg.
	self SubCq: 1 R: FPReg.

	actualAlignment := (alignment max: BytesPerWord).
	actualAlignment > BytesPerWord ifTrue: [
		mask := actualAlignment negated.
		self AndCq: mask R: SPReg.
	].
	currentCallCleanUpSize := 0.
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

{ #category : #'inline ffi' }
StackToRegisterMappingCogit >> callSwitchToCStack [
	<option: #LowcodeVM>
	self MoveAw: self cFramePointerAddress R: FPReg.
	^0
]

{ #category : #'inline ffi' }
StackToRegisterMappingCogit >> callSwitchToSmalltalkStack [
	<option: #LowcodeVM>
	"Restore the link register"
	backEnd hasVarBaseRegister ifTrue:
		[self MoveCq: self varBaseAddress R: VarBaseReg].
	backEnd hasLinkRegister ifTrue: [
		self MoveAw: coInterpreter instructionPointerAddress R: LinkReg
	].
	backEnd genLoadStackPointers.
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
	[self maybeHaltIfDebugPC.
	 self mergeWithFixupIfRequired: (fixup := self fixupAt: bytecodePC).
	 descriptor := self loadBytesAndGetDescriptor.
	 nextOpcodeIndex := opcodeIndex.
	 result := deadCode
				ifTrue: [self mapDeadDescriptorIfNeeded: descriptor]
				ifFalse: [self perform: descriptor generator].
	 result = 0 ifTrue: [self assertExtsAreConsumed: descriptor].
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
	  initialStackPtr initialOpcodeIndex initialIndexOfIRC initialCounterIndex |
	<var: #blockStart type: #'BlockStart *'>
	self assert: blockCount > 0.
	"scanBlock: in compileBlockEntry: sets both of these appropriately for each block."
	savedNeedsFrame := needsFrame.
	savedNumArgs := methodOrBlockNumArgs.
	savedNumTemps := methodOrBlockNumTemps.
	inBlock := InVanillaBlock.
	compiledBlocksCount := 0.
	[compiledBlocksCount < blockCount] whileTrue:
		[compilationPass := 1.
		 blockStart := self blockStartAt: compiledBlocksCount.
		 (result := self scanBlock: blockStart) < 0 ifTrue: [^result].
		 initialOpcodeIndex := opcodeIndex.
		 initialCounterIndex := self maybeCounterIndex."for SistaCogit"
		 literalsManager saveForRecompile.
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
				[self assert: (initialStackPtr > simStackPtr or: [deadCode]).
				 compilationPass := compilationPass + 1. "for asserts"
				 blockStart numInitialNils: blockStart numInitialNils + simStackPtr - initialStackPtr.
				 blockStart fakeHeader dependent: nil.
				 self reinitializeFixupsFrom: blockStart startpc + blockStart numInitialNils
					through: blockStart startpc + blockStart span - 1.
				 self cCode: 'bzero(abstractOpcodes + initialOpcodeIndex,
									(opcodeIndex - initialOpcodeIndex) * sizeof(AbstractInstruction))'
					inSmalltalk: [initialOpcodeIndex to: opcodeIndex - 1 do:
									[:i| abstractOpcodes at: i put: (CogCompilerClass for: self)]].
				 opcodeIndex := initialOpcodeIndex.
				 self maybeSetCounterIndex: initialCounterIndex. "For SistaCogit"
				 literalsManager resetForRecompile ].
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
				[self genPushConstant: objectMemory nilObject]]
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
StackToRegisterMappingCogit >> compileFullBlockFramelessEntry: numCopied [
	"Make sure ReceiverResultReg holds the receiver, loaded from
	 the closure, which is what is initially in ReceiverResultReg"
	self initSimStackForFramelessBlock: initialPC.
	super compileFullBlockFramelessEntry: numCopied
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> compileFullBlockMethodFrameBuild: numCopied [
	<option: #SistaV1BytecodeSet>
	useTwoPaths ifTrue: 
		[ "method with only inst var store, we compile only slow path for now" 
		 useTwoPaths := false.
		 self cppIf: IMMUTABILITY ifTrue: [ needsFrame := true ] ].
	needsFrame ifFalse:
		[self assert: numCopied = 0.
		 self compileFullBlockFramelessEntry: numCopied.
		 self initSimStackForFramelessBlock: initialPC.
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
	^(debugStackPointers at: bcpc) + (needsFrame ifTrue: [0] ifFalse: [1])
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
			self cppIf: IMMUTABILITY ifTrue: [ "genStorePop:...ReceiverVariable: annotate; don't annotate twice" ^0 ]].
	"We need a map entry for this bytecode for correct parsing (if the method builds a frame)."
	self assert: needsFrame.
	"genPushMaybeContextInstVar, pushLitVar, store & storePop all generate code"
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

{ #category : #'inline ffi' }
StackToRegisterMappingCogit >> endHighLevelCallWithCleanup [
	<option: #LowcodeVM>
	currentCallCleanUpSize > 0 ifTrue: [
		self AddCq: currentCallCleanUpSize R: SPReg
	].
   self callSwitchToSmalltalkStack.

]

{ #category : #'inline ffi' }
StackToRegisterMappingCogit >> endHighLevelCallWithoutCleanup [
	<option: #LowcodeVM>
	self callSwitchToSmalltalkStack.
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> ensureFixupAt: targetPC [
	"Make sure there's a flagged fixup at the target pc in fixups.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction."
	<returnTypeC: #'BytecodeFixup *'>
	| fixup |
	<var: #fixup type: #'BytecodeFixup *'>
	fixup := self fixupAt:  targetPC.
	self traceFixup: fixup merge: true.
	self cCode: '' inSmalltalk:
		[self assert: simStackPtr = (self debugStackPointerFor: targetPC).
		 (fixup isMergeFixupOrIsFixedUp
		  and: [fixup isBackwardBranchFixup not]) ifTrue: "ignore backward branch targets"
			[self assert: fixup simStackPtr = simStackPtr]].
	fixup isNonMergeFixupOrNotAFixup
		ifTrue: "convert a non-merge into a merge"
			[fixup becomeMergeFixup.
			 fixup simStackPtr: simStackPtr.
			 LowcodeVM ifTrue: [
				 fixup simNativeStackPtr: simNativeStackPtr.
				 fixup simNativeStackSize: simNativeStackSize]]
		ifFalse:
			[fixup isBackwardBranchFixup
				ifTrue: "this is the target of a backward branch and
						 so doesn't have a simStackPtr assigned yet."
					[fixup simStackPtr: simStackPtr.
		 			 LowcodeVM ifTrue:
			 			[fixup simNativeStackPtr: simNativeStackPtr.
			 			 fixup simNativeStackSize: simNativeStackSize]]
				ifFalse:
					[self assert: fixup simStackPtr = simStackPtr.
					 LowcodeVM ifTrue:
				 		[self assert: fixup simNativeStackPtr = simNativeStackPtr.
		 			 	 self assert: fixup simNativeStackSize = simNativeStackSize]]].
	fixup recordBcpc: bytecodePC.
	^fixup
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> ensureNonMergeFixupAt: targetPC [
	"Make sure there's a flagged fixup at the target pc in fixups.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction."
	<returnTypeC: #'BytecodeFixup *'>
	| fixup |
	<var: #fixup type: #'BytecodeFixup *'>
	fixup := self fixupAt:  targetPC.
	self traceFixup: fixup merge: true.
	fixup notAFixup ifTrue:
		[fixup becomeNonMergeFixup].
	self cCode: '' inSmalltalk:
		[fixup isMergeFixupOrIsFixedUp ifTrue:
			[self assert:
					(fixup isBackwardBranchFixup
					 or: [fixup simStackPtr = (self debugStackPointerFor: targetPC)])]].
	fixup recordBcpc: bytecodePC.
	^fixup
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> ensureReceiverResultRegContainsSelf [
	needsFrame
		ifTrue:
			[self receiverIsInReceiverResultReg ifFalse:
				[self ssAllocateRequiredReg: ReceiverResultReg.
				 self putSelfInReceiverResultReg.
				 self simSelf liveRegister: ReceiverResultReg]]
		ifFalse:
			[self assert: (self simSelf type = SSRegister
						  and: [self simSelf register = ReceiverResultReg
						  and: [self receiverIsInReceiverResultReg]])]
]

{ #category : #'peephole optimizations' }
StackToRegisterMappingCogit >> evaluate: descriptor at: pc [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	byte0 := objectMemory fetchByte: pc ofObject: methodObj.
	self assert: descriptor = (self generatorAt: bytecodeSetOffset + byte0).
	self loadSubsequentBytesForDescriptor: descriptor at: pc.
	self perform: descriptor generator
]

{ #category : #'peephole optimizations' }
StackToRegisterMappingCogit >> eventualTargetOf: targetBytecodePC [
	"Attempt to follow a branch to a pc.  Handle branches to unconditional jumps and
	 branches to push: aBoolean; conditional branch pairs.  If the branch cannot be
	 followed answer targetBytecodePC. It is not possible to follow jumps to conditional
	 branches because the stack changes depth.  That following is left to the genJumpIf:to:
	 clients."

	| currentTarget nextPC nExts descriptor span cond |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	nextPC := currentTarget := targetBytecodePC.
	[ nExts := 0.
	 [descriptor := self generatorForPC: nextPC.
	  descriptor isReturn ifTrue: [^currentTarget]. "avoid stepping off the end of methods"
	  descriptor isExtension]
		whileTrue:
			[nExts := nExts + 1.
			 nextPC := nextPC + descriptor numBytes].
	 descriptor isUnconditionalBranch
		ifTrue:
			[span := self spanFor: descriptor at: nextPC exts: nExts in: methodObj.
			 span < 0 ifTrue: "Do *not* follow backward branches; these are interrupt points and should not be elided."
				[^currentTarget].
			 nextPC := nextPC + descriptor numBytes + span]
		ifFalse:
			[descriptor generator == #genPushConstantTrueBytecode ifTrue: [ cond := true ]
			 ifFalse: [ descriptor generator == #genPushConstantFalseBytecode ifTrue: [ cond := false ]
			 ifFalse: [ ^currentTarget ] ].
			 "Don't step into loops across a pushTrue; jump:if: boundary, so as not to confuse stack depth fixup."
			 (self fixupAt: nextPC) isBackwardBranchFixup ifTrue:
				[^currentTarget].
			 nextPC := self eventualTargetOf: nextPC + descriptor numBytes.
			 nExts := 0.
			 [descriptor := self generatorForPC: nextPC.
			  descriptor isReturn ifTrue: [^currentTarget]. "avoid stepping off the end of methods"
			  descriptor isExtension]
				whileTrue:
					[nExts := nExts + 1.
					 nextPC := nextPC + descriptor numBytes].
			 descriptor isBranch ifFalse:
				[^currentTarget].
			 descriptor isUnconditionalBranch ifTrue:
				[^currentTarget].
			 nextPC := cond == descriptor isBranchTrue
									ifTrue: [nextPC
											+ descriptor numBytes
											+ (self spanFor: descriptor at: nextPC exts: nExts in: methodObj)]
									ifFalse: [nextPC + descriptor numBytes]].
	 currentTarget := nextPC]
		repeat
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
	 If the instruction found is a branch, also answers the pc after the branch and the pc targeted by the branch.
	 For convenience, avoiding duplication in the senders, it follows those two pcs to their eventual targets."
	| primDescriptor nextPC nExts branchDescriptor targetBytecodePC postBranchPC |
	<inline: true>
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	
	primDescriptor := self generatorAt: byte0.

	nextPC := bytecodePC + primDescriptor numBytes.
	nExts := 0.
	[[branchDescriptor := self generatorForPC: nextPC.
	  branchDescriptor isExtension] whileTrue:
		[nExts := nExts + 1.
		 nextPC := nextPC + branchDescriptor numBytes].
	 branchDescriptor isUnconditionalBranch]
		whileTrue:
			[nextPC := self eventualTargetOf: nextPC
											+ branchDescriptor numBytes
											+ (self spanFor: branchDescriptor at: nextPC exts: nExts in: methodObj)].

	targetBytecodePC := postBranchPC := 0.

	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse])
		ifTrue: 
			[targetBytecodePC := self eventualTargetOf: nextPC
														+ branchDescriptor numBytes
														+ (self spanFor: branchDescriptor at: nextPC exts: nExts in: methodObj).
			 postBranchPC := self eventualTargetOf: nextPC + branchDescriptor numBytes]
		ifFalse:
			[nextPC := bytecodePC + primDescriptor numBytes].

	fourArgBlock value: branchDescriptor value: nextPC value: postBranchPC value: targetBytecodePC
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> fixupAtIndex: index [
	"The fixups Array maps to bytecode pcs such that initialPC maps to index 0.
	 fixupAt: does the conversion.  Override to add breakpointing for fixups of bytecode PCs."
	<cmacro: '(index) (&fixups[index])'>
	<returnTypeC: #'BytecodeFixup *'>
	((debugFixupBreaks includes: index + initialPC)
	 and: [breakMethod isNil or: [methodObj = breakMethod]]) ifTrue:
		[self halt].
	^self addressOf: (fixups at: index)
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> freeAnyFloatRegNotConflictingWith: regMask [
	"Spill the closest register on stack not conflicting with regMask. 
	Assertion Failure if regMask has already all the registers"
	<var: #desc type: #'CogSimStackEntry *'>
	| reg index |
	self assert: needsFrame.
	reg := NoReg.
	index := simSpillBase max: 0.
	LowcodeVM ifTrue: [
		index := simNativeSpillBase max: 0.
		[reg = NoReg and: [index < simNativeStackPtr]] whileTrue: 
			[ | desc |
			 desc := self simNativeStackAt: index.
			(desc type = SSRegisterSingleFloat or: [desc type = SSRegisterDoubleFloat]) ifTrue:
				[(regMask anyMask: (self registerMaskFor: desc register)) ifFalse: 
					[reg := desc register]].
			 index := index + 1].
	].
	self deny: reg = NoReg.
	self ssAllocateRequiredFloatReg: reg.
	^reg
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

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genCallPrimitiveBytecode [
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#inlinePrimitiveBytecode:"
	| prim primSet |
	byte2 < 128 ifTrue:
		[^bytecodePC = initialPC
			ifTrue: [0]
			ifFalse: [EncounteredUnknownBytecode]].
	prim := byte2 - 128 << 8 + byte1.
	primSet := prim >> 13 bitAnd: 3.
	prim := prim bitAnd: 8191.
	LowcodeVM
		ifTrue:
			[
			primSet = 1 ifTrue: [
				prim < 1000 ifTrue:
					[^self genLowcodeNullaryInlinePrimitive: prim].

				prim < 2000 ifTrue:
					[^self genLowcodeUnaryInlinePrimitive: prim - 1000].
				
				prim < 3000 ifTrue:
					[^ self genLowcodeBinaryInlinePrimitive: prim - 2000].

				prim < 4000 ifTrue:
					[^self genLowcodeTrinaryInlinePrimitive: prim - 3000].
			]
		].

	^EncounteredUnknownBytecode
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genCmpArgIsConstant: argIsConstant rcvrIsConstant: rcvrIsConstant argReg: argReg rcvrReg: rcvrReg [
	"Generates the Cmp instruction for the top two ssStack values. 
	ssTop is called the argument and ssValue: 1 is called the receiver.
	0 or 1 value on ssStack is a constant (but not 2). If a value is a constant, then noReg is passed as argReg or rcvrReg.
	The instruction is different if one of the operands is a constant.
	In the case of the v3 memory manager, the constant could be annotable."
	<inline: true>
	self assert: (argReg ~= NoReg or: [rcvrReg ~= NoReg]).
	argIsConstant 
		ifTrue: [ self genCmpConstant: self ssTop constant R: rcvrReg ]
		ifFalse: [ rcvrIsConstant
			ifTrue: [ self genCmpConstant: (self ssValue: 1) constant R: argReg ]
			ifFalse: [ self CmpR: argReg R: rcvrReg ] ].
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
	extA := numExtB := extB := 0.

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
	self voidReceiverResultRegContainsSelf.
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
		ifFalse: [self simSelf storeToReg: (reg := TempReg)].
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
			numExtB := 0.
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
	numExtB := 0.
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
						needsImmutabilityCheck: needsImmCheck ].
			self cppIf: IMMUTABILITY ifTrue: [ needsImmCheck ifFalse: [self annotateBytecode: self Label ] ] ].
	^ 0
]

{ #category : #'trampoline support' }
StackToRegisterMappingCogit >> genExternalizePointersForPrimitiveCall [
	" Override to push the register receiver and register arguments, if any."
	self genPushRegisterArgs.
	^super genExternalizePointersForPrimitiveCall
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genForwardersInlinedIdenticalOrNotIf: orNot [
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
		[^ self 
			genIdenticalNoBranchArgIsConstant: unforwardArg not
			rcvrIsConstant: unforwardRcvr not
			argReg: argReg 
			rcvrReg: rcvrReg 
			orNotIf: orNot].
	
	"If branching the stack must be flushed for the merge"
	self ssFlushTo: simStackPtr - 2.
	
	label := self Label.
	self genCmpArgIsConstant: unforwardArg not rcvrIsConstant: unforwardRcvr not argReg: argReg rcvrReg: rcvrReg.
	self ssPop: 2.

	"Since there is a following conditional jump bytecode (unless there is deadCode),
	 define non-merge fixups and leave the cond bytecode to set the mergeness."
	(self fixupAt: nextPC) notAFixup
		ifTrue: "The next instruction is dead.  we can skip it."
			[deadCode := true.
		 	 self ensureFixupAt: targetBytecodePC.
			 self ensureFixupAt: postBranchPC]
		ifFalse:
			[self deny: deadCode]. "push dummy value below"

	self assert: (unforwardArg or: [unforwardRcvr]).
	orNot == branchDescriptor isBranchTrue "orNot is true for ~~"
		ifFalse: "a == b ifTrue: ... or a ~~ b ifFalse: ... jump on equal to target pc"
			[fixup := self ensureNonMergeFixupAt: postBranchPC.
			 self JumpZero:  (self ensureNonMergeFixupAt: targetBytecodePC)]
		ifTrue: "a == b ifFalse: ... or a ~~ b ifTrue: ... jump on equal to post-branch pc"
			[fixup := self ensureNonMergeFixupAt: targetBytecodePC.
			 self JumpZero: (self ensureNonMergeFixupAt: postBranchPC)].
		
	"The forwarders checks need to jump back to the comparison (label) if a forwarder is found, else 
	 jump forward either to the next forwarder check or to the postBranch or branch target (fixup)."
	(unforwardArg and: [unforwardRcvr]) ifTrue:
		[objectRepresentation genEnsureOopInRegNotForwarded: argReg scratchReg: TempReg jumpBackTo: label].
	objectRepresentation 
		genEnsureOopInRegNotForwarded: (unforwardRcvr ifTrue: [rcvrReg] ifFalse: [argReg]) 
		scratchReg: TempReg 
		ifForwarder: label
		ifNotForwarder: fixup.
		
	"Not reached, execution flow has jumped to fixup"
	deadCode ifFalse:
		[self ssPushConstant: objectMemory trueObject]. "dummy value"
	^0
]

{ #category : #'bytecode generator stores' }
StackToRegisterMappingCogit >> genGenericStorePop: popBoolean MaybeContextSlotIndex: slotIndex needsStoreCheck: needsStoreCheck needsRestoreRcvr: needsRestoreReceiver needsImmutabilityCheck: needsImmCheck [
	"Generates a store into an object that *may* be a context.
	Multiple settings:
	- needsStoreCheck (young into old object check)
	- needRestoreRcvr (ensures the recevier is live across the store)
	- needsImmCheck (do the call-back if the receiver is immutable)"
	<inline: true>
	<var: #mutableJump type: #'AbstractInstruction *'>
	<var: #immutabilityFailure type: #'AbstractInstruction *'>
	| immutabilityFailure mutableJump |
	"The reason we need a frame here is that assigning to an inst var of a context may
	 involve wholesale reorganization of stack pages, and the only way to preserve the
	 execution state of an activation in that case is if it has a frame."
	self assert: needsFrame.
	self 
		cppIf: IMMUTABILITY
		ifTrue:
			[needsImmCheck
				ifTrue: 
					[mutableJump := objectRepresentation genJumpMutable: ReceiverResultReg scratchReg: TempReg.
					 objectRepresentation genStoreTrampolineCall: slotIndex.
					 needsRestoreReceiver ifTrue: [ self putSelfInReceiverResultReg ].
					 immutabilityFailure := self Jump: 0.
					 mutableJump jmpTarget: self Label.]].
	self ssPop: 1.
	self ssAllocateCallReg: ClassReg and: SendNumArgsReg. "for ceStoreContextInstVarTrampoline"
	self ssPush: 1.
	objectRepresentation
		genLoadSlot: SenderIndex
		sourceReg: ReceiverResultReg
		destReg: TempReg.
	self ssStoreAndReplacePop: popBoolean toReg: ClassReg.
	self ssFlushTo: simStackPtr.
	self MoveCq: slotIndex R: SendNumArgsReg.
	self CallRT: ceStoreContextInstVarTrampoline.
	self 
		cppIf: IMMUTABILITY
		ifTrue:
			[needsImmCheck ifTrue:[immutabilityFailure jmpTarget: self Label]].
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
	"We have two very different paths as only the immutability path requires a specific register 
	for the value on top of stack as well as the stack flush.
	N.B. If IMMUTABILITY then ReceiverResultReg/destReg will be smashed if needsImmCheck.
		If not IMMUTABILITY then ReceiverResultReg will be preserved by the ceStoreCheck trampoline."
	| topReg |
	<inline: true>
	self cppIf: IMMUTABILITY ifTrue:
		[needsImmCheck ifTrue: 
			[self ssAllocateRequiredReg: ClassReg upThrough: simStackPtr - 1. "If already classReg don't spill it"
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
StackToRegisterMappingCogit >> genIdenticalNoBranchArgIsConstant: argIsConstant rcvrIsConstant: rcvrIsConstant argReg: argReg rcvrReg: rcvrRegOrNone orNotIf: orNot [
	"Generates the machine code for #== in the case where the instruction is not followed by a branch"
	| label jumpEqual jumpNotEqual resultReg |
	<var: #label type: #'AbstractInstruction *'>
	<var: #jumpEqual type: #'AbstractInstruction *'>
	<var: #jumpNotEqual type: #'AbstractInstruction *'>
	label := self Label.
	self genCmpArgIsConstant: argIsConstant rcvrIsConstant: rcvrIsConstant argReg: argReg rcvrReg: rcvrRegOrNone.
	self ssPop: 2.
	resultReg := rcvrRegOrNone = NoReg ifTrue: [argReg] ifFalse: [rcvrRegOrNone].
	jumpEqual := self JumpZero: 0.
	 argIsConstant ifFalse:
		[objectRepresentation genEnsureOopInRegNotForwarded: argReg scratchReg: TempReg jumpBackTo: label].
	 rcvrIsConstant ifFalse:
		[objectRepresentation genEnsureOopInRegNotForwarded: rcvrRegOrNone scratchReg: TempReg jumpBackTo: label].
	 orNot ifFalse: [self genMoveFalseR: resultReg] ifTrue: [self genMoveTrueR: resultReg].
	 jumpNotEqual := self Jump: 0.
	 jumpEqual jmpTarget: (orNot ifFalse: [self genMoveTrueR: resultReg] ifTrue: [self genMoveFalseR: resultReg]).
	 jumpNotEqual jmpTarget: self Label.
	 self ssPushRegister: resultReg.
	 ^0
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genInlineClosure: startpc numArgs: numArgs numCopied: numCopied [
	<inline: true>
	self assert: objectRepresentation getActiveContextAllocatesInMachineCode.
	 self voidReceiverResultRegContainsSelf.
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

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genInlinedIdenticalOrNotIf: orNot [
	"Decompose code generation for #== into a common constant-folding version,
	 followed by a double dispatch throguh the objectRepresentation to a version
	 that doesn't deal with forwarders and a version that does."
	| primDescriptor result |
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	primDescriptor := self generatorAt: byte0.
	
	((objectRepresentation isUnannotatableConstant: self ssTop)
	 and: [ objectRepresentation isUnannotatableConstant: (self ssValue: 1) ]) ifTrue:
		[self assert: primDescriptor isMapped not.
		 result := (orNot
					ifFalse: [self ssTop constant = (self ssValue: 1) constant]
					ifTrue: [self ssTop constant ~= (self ssValue: 1) constant])
									ifTrue: [objectMemory trueObject]
									ifFalse: [objectMemory falseObject].
		 self ssPop: 2.
		 ^self ssPushConstant: result].

	^objectRepresentation genInlinedIdenticalOrNotIfGuts: orNot
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
	| desc fixup ok eventualTarget |
	<var: #desc type: #'CogSimStackEntry *'>
	<var: #fixup type: #'BytecodeFixup *'>
	<var: #ok type: #'AbstractInstruction *'>
	eventualTarget := self eventualTargetOf: targetBytecodePC.
	self ssFlushTo: simStackPtr - 1.
	desc := self ssTop.
	self ssPop: 1.
	(self stackEntryIsBoolean: desc) ifTrue:
		["Must arrange there's a fixup at the target whether it is jumped to or
		  not so that the simStackPtr can be kept correct."
		 fixup := self ensureFixupAt: eventualTarget.
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
	self JumpZero: (self ensureFixupAt: eventualTarget).
	
	self extASpecifiesNoMustBeBoolean ifTrue: 
		[ extA := 0. 
		self annotateBytecode: self lastOpcode.
		^ 0].
	extA := 0.
	
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
StackToRegisterMappingCogit >> genJumpTo: targetBytecodePC [
	| eventualTarget generator fixup |
	eventualTarget := self eventualTargetOf: targetBytecodePC.
	(eventualTarget > bytecodePC
	 and: [self stackTopIsBoolean
	 and: [(generator := self generatorForPC: eventualTarget) isConditionalBranch]])
		ifTrue:
			[eventualTarget := eventualTarget
							  + generator numBytes
							  + (generator isBranchTrue == (self ssTop constant = objectMemory trueObject)
									ifTrue: [self spanFor: generator at: eventualTarget exts: 0 in: methodObj]
									ifFalse: [0]).
			self ssPop: 1.
			self ssFlushTo: simStackPtr.
			fixup := self ensureFixupAt: eventualTarget.
			self ssPop: -1]
		ifFalse:
			[self ssFlushTo: simStackPtr.
			fixup := self ensureFixupAt: eventualTarget].
	deadCode := true. "can't fall through"
	self Jump: fixup.
	^0
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
	destReg = ReceiverResultReg ifTrue: [self voidReceiverResultRegContainsSelf].
	self ssAllocateRequiredReg: destReg.
	self genMoveConstant: association R: destReg.
	objectRepresentation genEnsureObjInRegNotForwarded: destReg scratchReg: TempReg.
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genLoadTemp: objectIndex in: destReg [
	destReg = ReceiverResultReg ifTrue: [self voidReceiverResultRegContainsSelf].
	self ssAllocateRequiredReg: destReg. 
	self MoveMw: (self frameOffsetOfTemporary: objectIndex) r: FPReg R: destReg.
]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeAdd32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self AddR: second R: first.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeAdd64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh first second firstLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger4: [:secondLowValue :secondHighValue :firstLowValue :firstHighValue |
			secondLow := secondLowValue.
			secondHigh := secondHighValue.
			firstLow := firstLowValue.
			firstHigh := firstHighValue.
		].

		self ssNativeTop nativePopToReg: secondLow secondReg: secondHigh.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: firstLow secondReg: firstHigh.
		self ssNativePop: 1.

		self AddR: secondLow R: firstLow.
		self AddcR: secondHigh R: firstHigh.
		self ssPushNativeRegister: firstLow secondRegister: firstHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
			second := secondValue.
			first := firstValue.
		].

		self ssNativeTop nativePopToReg: second.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: first.
		self ssNativePop: 1.

		self AddR: second R: first.
		self ssPushNativeRegister: first.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeAlloca32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| size |
	self allocateRegistersForLowcodeInteger: [:sizeValue |
		size := sizeValue.
	].

	self ssNativeTop nativePopToReg: size.
	self ssNativePop: 1.

	self MoveAw: coInterpreter nativeStackPointerAddress R: TempReg.
	self SubR: size R: TempReg.
	self AndCq: -16 R: TempReg.
	self MoveR: TempReg R: size.
	self MoveR: size Aw: coInterpreter nativeStackPointerAddress.
	self ssPushNativeRegister: size.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeAlloca64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| sizeHigh size sizeLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2: [:sizeLowValue :sizeHighValue |
			sizeLow := sizeLowValue.
			sizeHigh := sizeHighValue.
		].

		self ssNativeTop nativePopToReg: sizeLow secondReg: sizeHigh.
		self ssNativePop: 1.

		self SubR: sizeLow R: SPReg.
		self MoveR: SPReg R: sizeLow.
		self ssPushNativeRegister: sizeLow.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger: [:sizeValue |
			size := sizeValue.
		].

		self ssNativeTop nativePopToReg: size.
		self ssNativePop: 1.

		self SubR: size R: SPReg.
		self MoveR: SPReg R: size.
		self ssPushNativeRegister: size.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeAnd32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self AndR: second R: first.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeAnd64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh first second firstLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger4: [:secondLowValue :secondHighValue :firstLowValue :firstHighValue |
			secondLow := secondLowValue.
			secondHigh := secondHighValue.
			firstLow := firstLowValue.
			firstHigh := firstHighValue.
		].

		self ssNativeTop nativePopToReg: secondLow secondReg: secondHigh.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: firstLow secondReg: firstHigh.
		self ssNativePop: 1.

		self AndR: secondLow R: firstLow.
		self AndR: secondHigh R: firstHigh.
		self ssPushNativeRegister: firstLow secondRegister: firstHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
			second := secondValue.
			first := firstValue.
		].

		self ssNativeTop nativePopToReg: second.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: first.
		self ssNativePop: 1.

		self AndR: second R: first.
		self ssPushNativeRegister: first.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeArithmeticRightShift32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value shiftAmount |
	self allocateRegistersForLowcodeInteger2: [:shiftAmountValue :valueValue |
		shiftAmount := shiftAmountValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: shiftAmount.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self ArithmeticShiftRightR: shiftAmount R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeArithmeticRightShift64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value result shiftAmountHigh shiftAmount resultLow valueLow resultHigh shiftAmountLow valueHigh |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:shiftAmountValue :valueValue :resultValue |
		shiftAmount := shiftAmountValue.
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: shiftAmount.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeBeginCall [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| alignment |
	alignment := extA.

	self beginHighLevelCall: alignment.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators dispatch generated code' }
StackToRegisterMappingCogit >> genLowcodeBinaryInlinePrimitive: prim [
	<option: #LowcodeVM>	"Lowcode instruction generator dispatch"
	prim
		caseOf: {
			[0]	-> [ ^ self genLowcodeByteSizeOf ].
			[1]	-> [ ^ self genLowcodeFirstFieldPointer ].
			[2]	-> [ ^ self genLowcodeFirstIndexableFieldPointer ].
			[3]	-> [ ^ self genLowcodeIsBytes ].
			[4]	-> [ ^ self genLowcodeIsFloatObject ].
			[5]	-> [ ^ self genLowcodeIsIndexable ].
			[6]	-> [ ^ self genLowcodeIsIntegerObject ].
			[7]	-> [ ^ self genLowcodeIsPointers ].
			[8]	-> [ ^ self genLowcodeIsWords ].
			[9]	-> [ ^ self genLowcodeIsWordsOrBytes ].
			[10]	-> [ ^ self genLowcodeOopSmallIntegerToInt32 ].
			[11]	-> [ ^ self genLowcodeOopSmallIntegerToInt64 ].
			[12]	-> [ ^ self genLowcodeOopToBoolean32 ].
			[13]	-> [ ^ self genLowcodeOopToBoolean64 ].
			[14]	-> [ ^ self genLowcodeOopToFloat32 ].
			[15]	-> [ ^ self genLowcodeOopToFloat64 ].
			[16]	-> [ ^ self genLowcodeOopToInt32 ].
			[17]	-> [ ^ self genLowcodeOopToInt64 ].
			[18]	-> [ ^ self genLowcodeOopToPointer ].
			[19]	-> [ ^ self genLowcodeOopToPointerReinterpret ].
			[20]	-> [ ^ self genLowcodeOopToUInt32 ].
			[21]	-> [ ^ self genLowcodeOopToUInt64 ].
			[22]	-> [ ^ self genLowcodePin ].
			[23]	-> [ ^ self genLowcodeUnpin ].
		}
		otherwise: [ ^ EncounteredUnknownBytecode ].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeBoolean32ToOop [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value inst cont object trueJump |
	self allocateRegistersForLowcodeIntegerResultOop: [:valueValue :objectValue |
		value := valueValue.
		object := objectValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self CmpCq: 0 R: value.
	trueJump := self JumpNonZero: 0.
	"False"
	self annotate: (self MoveCw: objectMemory falseObject R: value) objRef: objectMemory falseObject.
	cont := self Jump: 0.
	"True"
	inst := self MoveCw: objectMemory trueObject R: value.
	trueJump jmpTarget: inst.
	self annotate: inst objRef: objectMemory trueObject.
	cont jmpTarget: self Label.
	self ssPushRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeBoolean64ToOop [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value inst trueJump2 cont valueLow object trueJump valueHigh |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2ResultOop: [:valueLowValue :valueHighValue :objectValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
			object := objectValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self OrR: valueLow R: valueHigh.
		trueJump := self JumpNonZero: 0.
		"False"
		self annotate: (self MoveCw: objectMemory falseObject R: valueLow) objRef: objectMemory falseObject.
		cont := self Jump: 0.
		"True"
		inst := self MoveCw: objectMemory trueObject R: valueLow.
		trueJump jmpTarget: inst.
		self annotate: inst objRef: objectMemory trueObject.
		cont jmpTarget: self Label.
		self ssPushRegister: valueLow.

	] ifFalse: [
		self allocateRegistersForLowcodeIntegerResultOop: [:valueValue :objectValue |
			value := valueValue.
			object := objectValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self CmpCq: 0 R: value.
		trueJump := self JumpNonZero: 0.
		"False"
		self annotate: (self MoveCw: objectMemory falseObject R: value) objRef: objectMemory falseObject.
		cont := self Jump: 0.
		"True"
		inst := self MoveCw: objectMemory trueObject R: value.
		trueJump jmpTarget: inst.
		self annotate: inst objRef: objectMemory trueObject.
		cont jmpTarget: self Label.
		self ssPushRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeByteSizeOf [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object value |
	self allocateRegistersForLowcodeOopResultInteger: [:objectValue :valueValue |
		object := objectValue.
		value := valueValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	self ssFlushAll.
	objectRepresentation genLcByteSizeOf: object to: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeCallArgumentFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssNativeTop nativeStackPopToReg: DPFPReg0.
	self ssNativePop: 1.
	self MoveRs: DPFPReg0 M32: BytesPerWord negated r: SPReg.
	self SubCq: BytesPerWord R: SPReg.
	currentCallCleanUpSize := currentCallCleanUpSize + BytesPerWord.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeCallArgumentFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssNativeTop nativeStackPopToReg: DPFPReg0.
	self ssNativePop: 1.
	self MoveRd: DPFPReg0 M64: -8 r: SPReg.
	self SubCq: 8 R: SPReg.
	currentCallCleanUpSize := currentCallCleanUpSize + 8.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeCallArgumentInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	self PushR: TempReg.
	currentCallCleanUpSize := currentCallCleanUpSize + BytesPerWord.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeCallArgumentInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	BytesPerWord = 4 ifTrue: [
	self ssNativeTop nativeStackPopToReg: TempReg secondReg: ReceiverResultReg.
	self ssNativePop: 1.
	self PushR: TempReg.
	self PushR: ReceiverResultReg.
	currentCallCleanUpSize := currentCallCleanUpSize + 8.
	] ifFalse: [
	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	self PushR: TempReg.
	currentCallCleanUpSize := currentCallCleanUpSize + BytesPerWord.
	].

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeCallArgumentPointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	self PushR: TempReg.
	currentCallCleanUpSize := currentCallCleanUpSize + BytesPerWord.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeCallArgumentSpace [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	"Allocate space"
	self SubCq: extA R: SPReg.
	currentCallCleanUpSize := currentCallCleanUpSize + extA.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeCallArgumentStructure [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	"Fetch the pointer"
	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	"Allocate space"
	self SubCq: extA R: SPReg.
	currentCallCleanUpSize := currentCallCleanUpSize + extA.
	"Copy the structure"
	backEnd genMemCopy: TempReg to: SPReg constantSize: extA.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeCallInstruction [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| function |
	function := extA.

	self CallRT: function.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeCallPhysical [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| registerID |
	registerID := extA.

	self CallR: registerID.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeCheckSessionIdentifier [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| expectedSession |
	expectedSession := extA.

	self ssPushNativeConstantInt32: (expectedSession = coInterpreter getThisSessionID ifTrue: [1] ifFalse: [0]).

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeCompareAndSwap32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| newValue check oldValue value |
	self allocateRegistersForLowcodeInteger3ResultInteger: [:newValueValue :oldValueValue :checkValue :valueValue |
		newValue := newValueValue.
		oldValue := oldValueValue.
		check := checkValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: newValue.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: oldValue.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: check.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeDiv32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self DivR: second R: first Quo: first Rem: second.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeDiv64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh result resultLow resultHigh first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :resultValue |
		second := secondValue.
		first := firstValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeDuplicateFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value dup2 |
	self allocateRegistersForLowcodeFloatResultFloat: [:valueValue :dup2Value |
		value := valueValue.
		dup2 := dup2Value.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self MoveRs: value Rs: dup2.
	self ssPushNativeRegisterSingleFloat: value;
	ssPushNativeRegisterSingleFloat: dup2.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeDuplicateFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value dup2 |
	self allocateRegistersForLowcodeFloatResultFloat: [:valueValue :dup2Value |
		value := valueValue.
		dup2 := dup2Value.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self MoveRd: value Rd: dup2.
	self ssPushNativeRegisterDoubleFloat: value;
	ssPushNativeRegisterDoubleFloat: dup2.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeDuplicateInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value dup2 |
	self allocateRegistersForLowcodeIntegerResultInteger: [:valueValue :dup2Value |
		value := valueValue.
		dup2 := dup2Value.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self MoveR: value R: dup2.
	self ssPushNativeRegister: value;
	ssPushNativeRegister: dup2.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeDuplicateInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value dup2Low dup2 valueLow dup2High valueHigh |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2ResultInteger2: [:valueLowValue :valueHighValue :dup2LowValue :dup2HighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
			dup2Low := dup2LowValue.
			dup2High := dup2HighValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self MoveR: valueLow R: dup2Low.
		self MoveR: valueHigh R: dup2High.
		self ssPushNativeRegister: valueLow secondRegister: valueHigh.
		self ssPushNativeRegister: dup2Low secondRegister: dup2High.

	] ifFalse: [
		self allocateRegistersForLowcodeIntegerResultInteger: [:valueValue :dup2Value |
			value := valueValue.
			dup2 := dup2Value.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self MoveR: value R: dup2.
		self ssPushNativeRegister: value.
		self ssPushNativeRegister: dup2.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeDuplicatePointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| dup2 pointerValue |
	self allocateRegistersForLowcodeIntegerResultInteger: [:pointerValueValue :dup2Value |
		pointerValue := pointerValueValue.
		dup2 := dup2Value.
	].

	self ssNativeTop nativePopToReg: pointerValue.
	self ssNativePop: 1.

	self MoveR: pointerValue R: dup2.
	self ssPushNativeRegister: pointerValue;
	ssPushNativeRegister: dup2.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeEffectiveAddress32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| index base offset scale |
	self allocateRegistersForLowcodeInteger4: [:offsetValue :scaleValue :indexValue :baseValue |
		offset := offsetValue.
		scale := scaleValue.
		index := indexValue.
		base := baseValue.
	].

	self ssNativeTop nativePopToReg: offset.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: scale.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: index.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: base.
	self ssNativePop: 1.

	self MulR: scale R: index.
	self AddR: index R: base.
	self AddR: offset R: base.
	self ssPushNativeRegister: base.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeEffectiveAddress64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| base index indexLow indexHigh scaleHigh offsetLow scaleLow offset offsetHigh result scale |
	self allocateRegistersForLowcodeInteger4ResultInteger: [:offsetValue :scaleValue :indexValue :baseValue :resultValue |
		offset := offsetValue.
		scale := scaleValue.
		index := indexValue.
		base := baseValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: offset.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: scale.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: index.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: base.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeEndCall [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self endHighLevelCallWithCleanup.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeEndCallNoCleanup [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self endHighLevelCallWithoutCleanup.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFirstFieldPointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object |
	self allocateRegistersForLowcodeOop: [:objectValue |
		object := objectValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcFirstFieldPointer: object.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFirstIndexableFieldPointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object |
	self allocateRegistersForLowcodeOop: [:objectValue |
		object := objectValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcFirstIndexableFieldPointer: object.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32Add [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeFloat2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self AddRs: second Rs: first.
	self ssPushNativeRegisterSingleFloat: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32Div [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeFloat2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self DivRs: second Rs: first.
	self ssPushNativeRegisterSingleFloat: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32Equal [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value contJump falseJump first second |
	self allocateRegistersForLowcodeFloat2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpRs: second Rs: first.
	falseJump := self JumpFPNotEqual: 0.
	"True result"
	self MoveCq: 1 R: value.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: value.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32Great [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value contJump falseJump first second |
	self allocateRegistersForLowcodeFloat2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpRs: second Rs: first.
	falseJump := self JumpFPLessOrEqual: 0.
	"True result"
	self MoveCq: 1 R: value.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: value.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32GreatEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value contJump falseJump first second |
	self allocateRegistersForLowcodeFloat2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpRs: second Rs: first.
	falseJump := self JumpFPLess: 0.
	"True result"
	self MoveCq: 1 R: value.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: value.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32Less [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value contJump falseJump first second |
	self allocateRegistersForLowcodeFloat2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpRs: second Rs: first.
	falseJump := self JumpFPGreaterOrEqual: 0.
	"True result"
	self MoveCq: 1 R: value.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: value.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32LessEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value contJump falseJump first second |
	self allocateRegistersForLowcodeFloat2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpRs: second Rs: first.
	falseJump := self JumpFPGreater: 0.
	"True result"
	self MoveCq: 1 R: value.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: value.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32Mul [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeFloat2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self MulRs: second Rs: first.
	self ssPushNativeRegisterSingleFloat: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32Neg [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value result |
	self allocateRegistersForLowcodeFloatResultFloat: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self XorRs: result Rs: result.
	self SubRs: value Rs: result.
	self ssPushNativeRegisterSingleFloat: result.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32NotEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value contJump falseJump first second |
	self allocateRegistersForLowcodeFloat2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpRs: second Rs: first.
	falseJump := self JumpFPEqual: 0.
	"True result"
	self MoveCq: 1 R: value.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: value.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32Sqrt [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeFloat: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self SqrtRs: value.
	self ssPushNativeRegisterSingleFloat: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32Sub [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeFloat2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self SubRs: second Rs: first.
	self ssPushNativeRegisterSingleFloat: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32ToFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| singleFloatValue |
	self allocateRegistersForLowcodeFloat: [:singleFloatValueValue |
		singleFloatValue := singleFloatValueValue.
	].

	self ssNativeTop nativePopToReg: singleFloatValue.
	self ssNativePop: 1.

	self ConvertRs: singleFloatValue Rd: singleFloatValue.
	self ssPushNativeRegisterDoubleFloat: singleFloatValue.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32ToInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value result |
	self allocateRegistersForLowcodeFloatResultInteger: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self ConvertRs: value R: result.
	self ssPushNativeRegister: result.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32ToInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| resultLow resultHigh value result |
	self allocateRegistersForLowcodeFloatResultInteger: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32ToOop [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| singleFloatValue object |
	self allocateRegistersForLowcodeFloatResultOop: [:singleFloatValueValue :objectValue |
		singleFloatValue := singleFloatValueValue.
		object := objectValue.
	].

	self ssNativeTop nativePopToReg: singleFloatValue.
	self ssNativePop: 1.

	self ssFlushAll.
	objectRepresentation genLcFloat32: singleFloatValue toOop: object.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32ToUInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value result |
	self allocateRegistersForLowcodeFloatResultInteger: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self ConvertRs: value R: result.
	self ssPushNativeRegister: result.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat32ToUInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| resultLow resultHigh value result |
	self allocateRegistersForLowcodeFloatResultInteger: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64Add [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeFloat2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self AddRd: second Rd: first.
	self ssPushNativeRegisterDoubleFloat: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64Div [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeFloat2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self DivRd: second Rd: first.
	self ssPushNativeRegisterDoubleFloat: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64Equal [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value contJump falseJump first second |
	self allocateRegistersForLowcodeFloat2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpRd: second Rd: first.
	falseJump := self JumpFPNotEqual: 0.
	"True result"
	self MoveCq: 1 R: value.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: value.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64Great [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value contJump falseJump first second |
	self allocateRegistersForLowcodeFloat2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpRd: second Rd: first.
	falseJump := self JumpFPLessOrEqual: 0.
	"True result"
	self MoveCq: 1 R: value.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: value.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64GreatEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value contJump falseJump first second |
	self allocateRegistersForLowcodeFloat2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpRd: second Rd: first.
	falseJump := self JumpFPLess: 0.
	"True result"
	self MoveCq: 1 R: value.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: value.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64Less [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value contJump falseJump first second |
	self allocateRegistersForLowcodeFloat2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpRd: second Rd: first.
	falseJump := self JumpFPGreaterOrEqual: 0.
	"True result"
	self MoveCq: 1 R: value.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: value.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64LessEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value contJump falseJump first second |
	self allocateRegistersForLowcodeFloat2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpRd: second Rd: first.
	falseJump := self JumpFPGreater: 0.
	"True result"
	self MoveCq: 1 R: value.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: value.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64Mul [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeFloat2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self MulRd: second Rd: first.
	self ssPushNativeRegisterDoubleFloat: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64Neg [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value result |
	self allocateRegistersForLowcodeFloatResultFloat: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self XorRd: result Rd: result.
	self SubRd: value Rd: result.
	self ssPushNativeRegisterDoubleFloat: result.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64NotEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value contJump falseJump first second |
	self allocateRegistersForLowcodeFloat2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpRd: second Rd: first.
	falseJump := self JumpFPEqual: 0.
	"True result"
	self MoveCq: 1 R: value.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: value.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64Sqrt [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeFloat: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self SqrtRd: value.
	self ssPushNativeRegisterDoubleFloat: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64Sub [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeFloat2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self SubRd: second Rd: first.
	self ssPushNativeRegisterDoubleFloat: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64ToFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| floatValue |
	self allocateRegistersForLowcodeFloat: [:floatValueValue |
		floatValue := floatValueValue.
	].

	self ssNativeTop nativePopToReg: floatValue.
	self ssNativePop: 1.

	self ConvertRd: floatValue Rs: floatValue.
	self ssPushNativeRegisterSingleFloat: floatValue.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64ToInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| floatValue int32Result |
	self allocateRegistersForLowcodeFloatResultInteger: [:floatValueValue :int32ResultValue |
		floatValue := floatValueValue.
		int32Result := int32ResultValue.
	].

	self ssNativeTop nativePopToReg: floatValue.
	self ssNativePop: 1.

	self ConvertRd: floatValue R: int32Result.
	self ssPushNativeRegister: int32Result.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64ToInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| floatValue int64ResultLow int64Result int64ResultHigh |
	self allocateRegistersForLowcodeFloatResultInteger: [:floatValueValue :int64ResultValue |
		floatValue := floatValueValue.
		int64Result := int64ResultValue.
	].

	self ssNativeTop nativePopToReg: floatValue.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64ToOop [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| floatValue object |
	self allocateRegistersForLowcodeFloatResultOop: [:floatValueValue :objectValue |
		floatValue := floatValueValue.
		object := objectValue.
	].

	self ssNativeTop nativePopToReg: floatValue.
	self ssNativePop: 1.

	self ssFlushAll.
	objectRepresentation genLcFloat64: floatValue toOop: object.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64ToUInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| floatValue int64Result |
	self allocateRegistersForLowcodeFloatResultInteger: [:floatValueValue :int64ResultValue |
		floatValue := floatValueValue.
		int64Result := int64ResultValue.
	].

	self ssNativeTop nativePopToReg: floatValue.
	self ssNativePop: 1.

	self ConvertRd: floatValue R: int64Result.
	self ssPushNativeRegister: int64Result.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFloat64ToUInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| floatValue int64ResultLow int64Result int64ResultHigh |
	self allocateRegistersForLowcodeFloatResultInteger: [:floatValueValue :int64ResultValue |
		floatValue := floatValueValue.
		int64Result := int64ResultValue.
	].

	self ssNativeTop nativePopToReg: floatValue.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeFree [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer |
	self allocateRegistersForLowcodeInteger: [:pointerValue |
		pointer := pointerValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.

	self ssFlushAll.
	pointer ~= ReceiverResultReg ifTrue: [self MoveR: pointer R: ReceiverResultReg ].
	self CallRT: ceFreeTrampoline.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInstantiateIndexable32Oop [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| indexableSize object classOop |
	self allocateRegistersForLowcodeIntegerOopResultOop: [:indexableSizeValue :classOopValue :objectValue |
		indexableSize := indexableSizeValue.
		classOop := classOopValue.
		object := objectValue.
	].

	self ssNativeTop nativePopToReg: indexableSize.
	self ssNativePop: 1.
	self ssTop popToReg: classOop.
	self ssPop: 1.

	self ssFlushAll.
	objectRepresentation genLcInstantiateOop: classOop indexableSize: indexableSize.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInstantiateIndexableOop [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| indexableSize object classOop |
	indexableSize := extA.
	self allocateRegistersForLowcodeOopResultOop: [:classOopValue :objectValue |
		classOop := classOopValue.
		object := objectValue.
	].

	self ssTop popToReg: classOop.
	self ssPop: 1.

	self ssFlushAll.
	objectRepresentation genLcInstantiateOop: classOop constantIndexableSize: indexableSize.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInstantiateOop [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| classOop |
	self allocateRegistersForLowcodeOop: [:classOopValue |
		classOop := classOopValue.
	].

	self ssTop popToReg: classOop.
	self ssPop: 1.

	self ssFlushAll.
	objectRepresentation genLcInstantiateOop: classOop.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt32Equal [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second falseJump contJump first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpR: second R: first.
	falseJump := self JumpNonZero: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt32Great [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second falseJump contJump first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpR: second R: first.
	falseJump := self JumpLessOrEqual: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt32GreatEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second falseJump contJump first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpR: second R: first.
	falseJump := self JumpLess: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt32Less [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second falseJump contJump first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpR: second R: first.
	falseJump := self JumpGreaterOrEqual: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt32LessEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second falseJump contJump first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpR: second R: first.
	falseJump := self JumpGreater: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt32NotEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second falseJump contJump first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpR: second R: first.
	falseJump := self JumpZero: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt32ToFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value result |
	self allocateRegistersForLowcodeIntegerResultFloat: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self ConvertR: value Rs: result.
	self ssPushNativeRegisterSingleFloat: result.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt32ToFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value result |
	self allocateRegistersForLowcodeIntegerResultFloat: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self ConvertR: value Rd: result.
	self ssPushNativeRegisterDoubleFloat: result.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt32ToOop [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self ssFlushAll.
	objectRepresentation genLcInt32ToOop: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt32ToPointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	"TODO: Perform a NOP here"
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt64Equal [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| falseLabel first contJump falseJump secondLow secondHigh second falseJump2 firstHigh firstLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger4: [:secondLowValue :secondHighValue :firstLowValue :firstHighValue |
			secondLow := secondLowValue.
			secondHigh := secondHighValue.
			firstLow := firstLowValue.
			firstHigh := firstHighValue.
		].

		self ssNativeTop nativePopToReg: secondLow secondReg: secondHigh.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: firstLow secondReg: firstHigh.
		self ssNativePop: 1.

		self CmpR: secondHigh R: firstHigh.
		falseJump := self JumpNonZero: 0.
		self CmpR: secondLow R: firstLow.
		falseJump2 := self JumpNonZero: 0.
		"True result"
		self MoveCq: 1 R: firstLow.
		contJump := self Jump: 0.
		"False result"
		falseLabel := self MoveCq: 0 R: firstLow.
		falseJump jmpTarget: falseLabel.
		falseJump2 jmpTarget: falseLabel.
		contJump jmpTarget: self Label.
		self ssPushNativeRegister: firstLow.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
			second := secondValue.
			first := firstValue.
		].

		self ssNativeTop nativePopToReg: second.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: first.
		self ssNativePop: 1.

		self CmpR: second R: first.
		falseJump := self JumpNonZero: 0.
		"True result"
		self MoveCq: 1 R: first.
		contJump := self Jump: 0.
		"False result"
		falseJump jmpTarget: self Label.
		self MoveCq: 0 R: first.
		contJump jmpTarget: self Label.
		self ssPushNativeRegister: first.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt64Great [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh value first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt64GreatEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh value first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt64Less [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh value first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt64LessEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh value first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt64NotEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| falseLabel first contJump falseJump secondLow secondHigh second falseJump2 firstHigh firstLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger4: [:secondLowValue :secondHighValue :firstLowValue :firstHighValue |
			secondLow := secondLowValue.
			secondHigh := secondHighValue.
			firstLow := firstLowValue.
			firstHigh := firstHighValue.
		].

		self ssNativeTop nativePopToReg: secondLow secondReg: secondHigh.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: firstLow secondReg: firstHigh.
		self ssNativePop: 1.

		self CmpR: secondHigh R: firstHigh.
		falseJump := self JumpNonZero: 0.
		self CmpR: secondLow R: firstLow.
		falseJump2 := self JumpNonZero: 0.
		"False result"
		self MoveCq: 0 R: firstLow.
		contJump := self Jump: 0.
		"True result"
		falseLabel := self MoveCq: 1 R: firstLow.
		falseJump jmpTarget: falseLabel.
		falseJump2 jmpTarget: falseLabel.
		contJump jmpTarget: self Label.
		self ssPushNativeRegister: firstLow.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
			second := secondValue.
			first := firstValue.
		].

		self ssNativeTop nativePopToReg: second.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: first.
		self ssNativePop: 1.

		self CmpR: second R: first.
		falseJump := self JumpZero: 0.
		"True result"
		self MoveCq: 1 R: first.
		contJump := self Jump: 0.
		"False result"
		falseJump jmpTarget: self Label.
		self MoveCq: 0 R: first.
		contJump jmpTarget: self Label.
		self ssPushNativeRegister: first.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt64ToFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow result |
	self allocateRegistersForLowcodeIntegerResultFloat: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt64ToFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow result |
	self allocateRegistersForLowcodeIntegerResultFloat: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt64ToOop [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self ssFlushAll.
		objectRepresentation genLcInt64ToOop: valueLow highPart: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger: [:valueValue |
			value := valueValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self ssFlushAll.
		objectRepresentation genLcInt64ToOop: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeInt64ToPointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self ssPushNativeRegister: valueLow.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger: [:valueValue |
			value := valueValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self ssPushNativeRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeIsBytes [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object value |
	self allocateRegistersForLowcodeOopResultInteger: [:objectValue :valueValue |
		object := objectValue.
		value := valueValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcIsBytes: object to: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeIsFloatObject [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object value |
	self allocateRegistersForLowcodeOopResultInteger: [:objectValue :valueValue |
		object := objectValue.
		value := valueValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcIsFloatObject: object to: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeIsIndexable [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object value |
	self allocateRegistersForLowcodeOopResultInteger: [:objectValue :valueValue |
		object := objectValue.
		value := valueValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcIsIndexable: object to: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeIsIntegerObject [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object value |
	self allocateRegistersForLowcodeOopResultInteger: [:objectValue :valueValue |
		object := objectValue.
		value := valueValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcIsIntegerObject: object to: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeIsPointers [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object value |
	self allocateRegistersForLowcodeOopResultInteger: [:objectValue :valueValue |
		object := objectValue.
		value := valueValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcIsPointers: object to: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeIsWords [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object value |
	self allocateRegistersForLowcodeOopResultInteger: [:objectValue :valueValue |
		object := objectValue.
		value := valueValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcIsWords: object to: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeIsWordsOrBytes [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object value |
	self allocateRegistersForLowcodeOopResultInteger: [:objectValue :valueValue |
		object := objectValue.
		value := valueValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcIsWordsOrBytes: object to: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLeftShift32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value shiftAmount |
	self allocateRegistersForLowcodeInteger2: [:shiftAmountValue :valueValue |
		shiftAmount := shiftAmountValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: shiftAmount.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self LogicalShiftLeftR: shiftAmount R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLeftShift64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value result shiftAmountHigh shiftAmount resultLow valueLow resultHigh shiftAmountLow valueHigh |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:shiftAmountValue :valueValue :resultValue |
		shiftAmount := shiftAmountValue.
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: shiftAmount.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadArgumentAddress [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:pointerValue |
		pointer := pointerValue.
	].


	self loadNativeArgumentAddress: baseOffset to: pointer.
	self ssPushNativeRegister: pointer.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadArgumentFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| floatValue baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultFloat: [:floatValueValue |
		floatValue := floatValueValue.
	].


	self loadNativeArgumentAddress: baseOffset to: TempReg.
	self MoveM32: 0 r: TempReg Rs: floatValue.
	self ssPushNativeRegisterSingleFloat: floatValue.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadArgumentFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| doubleValue baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultFloat: [:doubleValueValue |
		doubleValue := doubleValueValue.
	].


	self loadNativeArgumentAddress: baseOffset to: TempReg.
	self MoveM64: 0 r: TempReg Rd: doubleValue.
	self ssPushNativeRegisterDoubleFloat: doubleValue.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadArgumentInt16 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:valueValue |
		value := valueValue.
	].


	self loadNativeArgumentAddress: baseOffset to: TempReg.
	self MoveM16: 0 r: TempReg R: value.
	self SignExtend16R: value R: value.
	self ssPushNativeRegister: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadArgumentInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:valueValue |
		value := valueValue.
	].


	self loadNativeArgumentAddress: baseOffset to: TempReg.
	self MoveM32: 0 r: TempReg R: value.
	self ssPushNativeRegister: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadArgumentInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow baseOffset |
	baseOffset := extA.
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeResultInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].


		"TODO: Check the endianness"
		self loadNativeArgumentAddress: baseOffset to: TempReg.
		self MoveM32: 0 r: TempReg R: valueLow.
		self MoveM32: 4 r: TempReg R: valueHigh.
		self ssPushNativeRegister: valueLow secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeResultInteger: [:valueValue |
			value := valueValue.
		].


		self loadNativeArgumentAddress: baseOffset to: TempReg.
		self MoveM64: 0 r: TempReg R: value.
		self ssPushNativeRegister: value.

	].
		extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadArgumentInt8 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:valueValue |
		value := valueValue.
	].


	self loadNativeArgumentAddress: baseOffset to: TempReg.
	self MoveM8: 0 r: TempReg R: value.
	self SignExtend8R: value R: value.
	self ssPushNativeRegister: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadArgumentPointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointerResult baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:pointerResultValue |
		pointerResult := pointerResultValue.
	].


	self loadNativeArgumentAddress: baseOffset to: TempReg.
	self MoveMw: 0 r: TempReg R: pointerResult.
	self ssPushNativeRegister: pointerResult.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadArgumentUInt16 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:valueValue |
		value := valueValue.
	].


	self loadNativeArgumentAddress: baseOffset to: TempReg.
	self MoveM16: 0 r: TempReg R: value.
	self ssPushNativeRegister: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadArgumentUInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:valueValue |
		value := valueValue.
	].


	self loadNativeArgumentAddress: baseOffset to: TempReg.
	self MoveM32: 0 r: TempReg R: value.
	self ssPushNativeRegister: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadArgumentUInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow baseOffset |
	baseOffset := extA.
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeResultInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].


		"TODO: Check the endianness"
		self loadNativeArgumentAddress: baseOffset to: TempReg.
		self MoveM32: 0 r: TempReg R: valueLow.
		self MoveM32: 4 r: TempReg R: valueHigh.
		self ssPushNativeRegister: valueLow secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeResultInteger: [:valueValue |
			value := valueValue.
		].


		self loadNativeArgumentAddress: baseOffset to: TempReg.
		self MoveM64: 0 r: TempReg R: value.
		self ssPushNativeRegister: value.

	].
		extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadArgumentUInt8 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:valueValue |
		value := valueValue.
	].


	self loadNativeArgumentAddress: baseOffset to: TempReg.
	self MoveM8: 0 r: TempReg R: value.
	self ssPushNativeRegister: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadFloat32FromMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer value |
	self allocateRegistersForLowcodeIntegerResultFloat: [:pointerValue :valueValue |
		pointer := pointerValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.

	self MoveM32: 0 r: pointer Rs: value.
	self ssPushNativeRegisterSingleFloat: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadFloat64FromMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer value |
	self allocateRegistersForLowcodeIntegerResultFloat: [:pointerValue :valueValue |
		pointer := pointerValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.

	self MoveM64: 0 r: pointer Rd: value.
	self ssPushNativeRegisterDoubleFloat: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadInt16FromMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer value |
	self allocateRegistersForLowcodeIntegerResultInteger: [:pointerValue :valueValue |
		pointer := pointerValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.

	self MoveM16: 0 r: pointer R: value.
	self SignExtend16R: value R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadInt32FromMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer value |
	self allocateRegistersForLowcodeIntegerResultInteger: [:pointerValue :valueValue |
		pointer := pointerValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.

	self MoveM32: 0 r: pointer R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadInt64FromMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh pointer value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeIntegerResultInteger2: [:pointerValue :valueLowValue :valueHighValue |
			pointer := pointerValue.
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssNativeTop nativePopToReg: pointer.
		self ssNativePop: 1.

		"TODO: Check the endianness"
		self MoveM32: 0 r: pointer R: valueLow.
		self MoveM32: 4 r: pointer R: valueHigh.
		self ssPushNativeRegister: valueLow secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeIntegerResultInteger: [:pointerValue :valueValue |
			pointer := pointerValue.
			value := valueValue.
		].

		self ssNativeTop nativePopToReg: pointer.
		self ssNativePop: 1.

		self MoveM64: 0 r: pointer R: value.
		self ssPushNativeRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadInt8FromMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer value |
	self allocateRegistersForLowcodeIntegerResultInteger: [:pointerValue :valueValue |
		pointer := pointerValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.

	self MoveM8: 0 r: pointer R: value.
	self SignExtend8R: value R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadLocalAddress [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:pointerValue |
		pointer := pointerValue.
	].


	self loadNativeLocalAddress: baseOffset to: pointer.
	self ssPushNativeRegister: pointer.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadLocalFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| floatValue baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultFloat: [:floatValueValue |
		floatValue := floatValueValue.
	].


	self loadNativeLocalAddress: baseOffset to: TempReg.
	self MoveM32: 0 r: TempReg Rs: floatValue.
	self ssPushNativeRegisterSingleFloat: floatValue.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadLocalFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| doubleValue baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultFloat: [:doubleValueValue |
		doubleValue := doubleValueValue.
	].


	self loadNativeLocalAddress: baseOffset to: TempReg.
	self MoveM64: 0 r: TempReg Rd: doubleValue.
	self ssPushNativeRegisterDoubleFloat: doubleValue.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadLocalInt16 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:valueValue |
		value := valueValue.
	].


	self loadNativeLocalAddress: baseOffset to: TempReg.
	self MoveM16: 0 r: TempReg R: value.
	self SignExtend16R: value R: value.
	self ssPushNativeRegister: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadLocalInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:valueValue |
		value := valueValue.
	].


	self loadNativeLocalAddress: baseOffset to: TempReg.
	self MoveM32: 0 r: TempReg R: value.
	self ssPushNativeRegister: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadLocalInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow baseOffset |
	baseOffset := extA.
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeResultInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].


		"TODO: Check the endianness"
		self loadNativeLocalAddress: baseOffset to: TempReg.
		self MoveM32: 0 r: TempReg R: valueLow.
		self MoveM32: 4 r: TempReg R: valueHigh.
		self ssPushNativeRegister: valueLow secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeResultInteger: [:valueValue |
			value := valueValue.
		].


		self loadNativeLocalAddress: baseOffset to: TempReg.
		self MoveM64: 0 r: TempReg R: value.
		self ssPushNativeRegister: value.

	].
		extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadLocalInt8 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:valueValue |
		value := valueValue.
	].


	self loadNativeLocalAddress: baseOffset to: TempReg.
	self MoveM8: 0 r: TempReg R: value.
	self SignExtend8R: value R: value.
	self ssPushNativeRegister: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadLocalPointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointerResult baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:pointerResultValue |
		pointerResult := pointerResultValue.
	].


	self loadNativeLocalAddress: baseOffset to: TempReg.
	self MoveMw: 0 r: TempReg R: pointerResult.
	self ssPushNativeRegister: pointerResult.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadLocalUInt16 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:valueValue |
		value := valueValue.
	].


	self loadNativeLocalAddress: baseOffset to: TempReg.
	self MoveM16: 0 r: TempReg R: value.
	self ssPushNativeRegister: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadLocalUInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:valueValue |
		value := valueValue.
	].


	self loadNativeLocalAddress: baseOffset to: TempReg.
	self MoveM32: 0 r: TempReg R: value.
	self ssPushNativeRegister: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadLocalUInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow baseOffset |
	baseOffset := extA.
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeResultInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].


		"TODO: Check the endianness"
		self loadNativeLocalAddress: baseOffset to: TempReg.
		self MoveM32: 0 r: TempReg R: valueLow.
		self MoveM32: 4 r: TempReg R: valueHigh.
		self ssPushNativeRegister: valueLow secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeResultInteger: [:valueValue |
			value := valueValue.
		].


		self loadNativeLocalAddress: baseOffset to: TempReg.
		self MoveM64: 0 r: TempReg R: value.
		self ssPushNativeRegister: value.

	].
		extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadLocalUInt8 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeResultInteger: [:valueValue |
		value := valueValue.
	].


	self loadNativeLocalAddress: baseOffset to: TempReg.
	self MoveM8: 0 r: TempReg R: value.
	self ssPushNativeRegister: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadObjectAt [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| fieldIndex object |
	self allocateRegistersForLowcodeIntegerOop: [:fieldIndexValue :objectValue |
		fieldIndex := fieldIndexValue.
		object := objectValue.
	].

	self ssNativeTop nativePopToReg: fieldIndex.
	self ssNativePop: 1.
	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcLoadObject: object at: fieldIndex.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadObjectField [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| fieldIndex object |
	fieldIndex := extA.
	self allocateRegistersForLowcodeOop: [:objectValue |
		object := objectValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcLoadObject: object field: fieldIndex.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadPointerFromMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointerResult pointer |
	self allocateRegistersForLowcodeIntegerResultInteger: [:pointerValue :pointerResultValue |
		pointer := pointerValue.
		pointerResult := pointerResultValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.

	self MoveMw: 0 r: pointer R: pointerResult.
	self ssPushNativeRegister: pointerResult.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadUInt16FromMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer value |
	self allocateRegistersForLowcodeIntegerResultInteger: [:pointerValue :valueValue |
		pointer := pointerValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.

	self MoveM16: 0 r: pointer R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadUInt32FromMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer value |
	self allocateRegistersForLowcodeIntegerResultInteger: [:pointerValue :valueValue |
		pointer := pointerValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.

	self MoveM32: 0 r: pointer R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadUInt64FromMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh pointer value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeIntegerResultInteger2: [:pointerValue :valueLowValue :valueHighValue |
			pointer := pointerValue.
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssNativeTop nativePopToReg: pointer.
		self ssNativePop: 1.

		"TODO: Check the endianness"
		self MoveM32: 0 r: pointer R: valueLow.
		self MoveM32: 4 r: pointer R: valueHigh.
		self ssPushNativeRegister: valueLow secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeIntegerResultInteger: [:pointerValue :valueValue |
			pointer := pointerValue.
			value := valueValue.
		].

		self ssNativeTop nativePopToReg: pointer.
		self ssNativePop: 1.

		self MoveM64: 0 r: pointer R: value.
		self ssPushNativeRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLoadUInt8FromMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer value |
	self allocateRegistersForLowcodeIntegerResultInteger: [:pointerValue :valueValue |
		pointer := pointerValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.

	self MoveM8: 0 r: pointer R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLocalFrameSize [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| alignedSize size |
	size := extA.

	self assert: needsFrame.
	hasNativeFrame := true.
	"Align the size to 16 bytes."
	alignedSize := size + 15 bitAnd: -16.
	"Mark the stack frame"
	self annotate: (self MoveCw: (objectMemory splObj: LowcodeContextMark) R: TempReg) objRef: (objectMemory splObj: LowcodeContextMark).
	self MoveR: TempReg Mw: self frameOffsetOfNativeFrameMark r: FPReg.
	"Fetch the stack"
	self MoveAw: coInterpreter nativeStackPointerAddress R: TempReg.
	self AddCq: 1 R: TempReg.
	self MoveR: TempReg Mw: self frameOffsetOfPreviousNativeStackPointer r: FPReg.
	"Store the frame pointer"
	self SubCq: alignedSize R: TempReg.
	self MoveR: TempReg Mw: self frameOffsetOfNativeFramePointer r: FPReg.
	"Store the new stack pointer"
	self MoveR: TempReg Mw: self frameOffsetOfNativeStackPointer r: FPReg.
	"Allocate space for the locals"
	self SubCq: 1 + coInterpreter defaultNativeStackFrameSize R: TempReg.
	self MoveR: TempReg Aw: coInterpreter nativeStackPointerAddress.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLockRegisters [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssFlushAll.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeLockVM [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeMalloc32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer size |
	self allocateRegistersForLowcodeIntegerResultInteger: [:sizeValue :pointerValue |
		size := sizeValue.
		pointer := pointerValue.
	].

	self ssNativeTop nativePopToReg: size.
	self ssNativePop: 1.

	self ssFlushAll.
	size ~= ReceiverResultReg ifTrue: [self MoveR: size R: ReceiverResultReg ].
	self CallRT: ceMallocTrampoline.
	self MoveR: TempReg R: pointer.
	self ssPushNativeRegister: pointer.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeMalloc64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| sizeHigh size sizeLow pointer |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2ResultInteger: [:sizeLowValue :sizeHighValue :pointerValue |
			sizeLow := sizeLowValue.
			sizeHigh := sizeHighValue.
			pointer := pointerValue.
		].

		self ssNativeTop nativePopToReg: sizeLow secondReg: sizeHigh.
		self ssNativePop: 1.

		self ssFlushAll.
		sizeLow ~= ReceiverResultReg ifTrue: [self MoveR: sizeLow R: ReceiverResultReg ].
		self CallRT: ceMallocTrampoline.
		self MoveR: TempReg R: pointer.
		self ssPushNativeRegister: pointer.

	] ifFalse: [
		self allocateRegistersForLowcodeIntegerResultInteger: [:sizeValue :pointerValue |
			size := sizeValue.
			pointer := pointerValue.
		].

		self ssNativeTop nativePopToReg: size.
		self ssNativePop: 1.

		self ssFlushAll.
		size ~= ReceiverResultReg ifTrue: [self MoveR: size R: ReceiverResultReg ].
		self CallRT: ceMallocTrampoline.
		self MoveR: TempReg R: pointer.
		self ssPushNativeRegister: pointer.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeMemcpy32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| source size dest |
	self allocateRegistersForLowcodeInteger3: [:sizeValue :sourceValue :destValue |
		size := sizeValue.
		source := sourceValue.
		dest := destValue.
	].

	self ssNativeTop nativePopToReg: size.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: source.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: dest.
	self ssNativePop: 1.

	self ssFlushAll.
	backEnd genMemCopy: source to: dest size: size.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeMemcpy64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| source sizeLow sizeHigh dest size |
	self allocateRegistersForLowcodeInteger3: [:sizeValue :sourceValue :destValue |
		size := sizeValue.
		source := sourceValue.
		dest := destValue.
	].

	self ssNativeTop nativePopToReg: size.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: source.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: dest.
	self ssNativePop: 1.

	self ssFlushAll.
	backEnd genMemCopy: source to: dest size: sizeLow.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeMemcpyFixed [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| source size dest |
	size := extA.
	self allocateRegistersForLowcodeInteger2: [:sourceValue :destValue |
		source := sourceValue.
		dest := destValue.
	].

	self ssNativeTop nativePopToReg: source.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: dest.
	self ssNativePop: 1.

	size = BytesPerWord ifTrue: [
	self MoveMw: 0 r: source R: TempReg.
	self MoveR: TempReg Mw: 0 r: dest.
	] ifFalse: [
	self ssFlushAll.
	backEnd genMemCopy: source to: dest constantSize: size.
	].

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeMoveFloat32ToPhysical [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssNativeTop nativeStackPopToReg: extA.
	self ssNativePop: 1.
	currentCallCleanUpSize := currentCallCleanUpSize + BytesPerWord.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeMoveFloat64ToPhysical [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssNativeTop nativeStackPopToReg: extA.
	self ssNativePop: 1.
	currentCallCleanUpSize := currentCallCleanUpSize + 8.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeMoveInt32ToPhysical [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssNativeTop nativeStackPopToReg: extA.
	self ssNativePop: 1.
	currentCallCleanUpSize := currentCallCleanUpSize + BytesPerWord.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeMoveInt64ToPhysical [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssNativeTop nativeStackPopToReg: extA.
	self ssNativePop: 1.
	currentCallCleanUpSize := currentCallCleanUpSize + 8.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeMovePointerToPhysical [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssNativeTop nativeStackPopToReg: extA.
	self ssNativePop: 1.
	currentCallCleanUpSize := currentCallCleanUpSize + BytesPerWord.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeMul32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self MulR: second R: first.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeMul64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh result resultLow resultHigh first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :resultValue |
		second := secondValue.
		first := firstValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeNeg32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self NegateR: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeNeg64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		"Two complement negation"
		self NotR: valueLow.
		self NotR: valueHigh.
		self AddCq: 1 R: valueLow.
		self AddcCq: 0 R: valueHigh.
		self ssPushNativeRegister: valueLow secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger: [:valueValue |
			value := valueValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self NegateR: value.
		self ssPushNativeRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeNot32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self NotR: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeNot64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self NotR: valueLow.
		self NotR: valueHigh.
		self ssPushNativeRegister: valueLow secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger: [:valueValue |
			value := valueValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self NotR: value.
		self ssPushNativeRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators dispatch generated code' }
StackToRegisterMappingCogit >> genLowcodeNullaryInlinePrimitive: prim [
	<option: #LowcodeVM>	"Lowcode instruction generator dispatch"
	prim
		caseOf: {
			[0]	-> [ ^ self genLowcodeBoolean32ToOop ].
			[1]	-> [ ^ self genLowcodeBoolean64ToOop ].
			[2]	-> [ ^ self genLowcodeFloat32ToOop ].
			[3]	-> [ ^ self genLowcodeFloat64ToOop ].
			[4]	-> [ ^ self genLowcodeInt32ToOop ].
			[5]	-> [ ^ self genLowcodeInt64ToOop ].
			[6]	-> [ ^ self genLowcodePointerToOop ].
			[7]	-> [ ^ self genLowcodePointerToOopReinterprer ].
			[8]	-> [ ^ self genLowcodeSmallInt32ToOop ].
			[9]	-> [ ^ self genLowcodeUint32ToOop ].
			[10]	-> [ ^ self genLowcodeUint64ToOop ].
		}
		otherwise: [ ^ EncounteredUnknownBytecode ].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value contJump falseJump first second |
	self allocateRegistersForLowcodeOop2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssTop popToReg: second.
	self ssPop: 1.
	self ssTop popToReg: first.
	self ssPop: 1.

	self CmpR: second R: first.
	falseJump := self JumpNonZero: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopNotEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second falseJump contJump first |
	self allocateRegistersForLowcodeOop2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssTop popToReg: second.
	self ssPop: 1.
	self ssTop popToReg: first.
	self ssPop: 1.

	self CmpR: second R: first.
	falseJump := self JumpZero: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopSmallIntegerToInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object |
	self allocateRegistersForLowcodeOop: [:objectValue |
		object := objectValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genConvertSmallIntegerToIntegerInReg: object.
	self ssPushNativeRegister: object.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopSmallIntegerToInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh object value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeOopResultInteger2: [:objectValue :valueLowValue :valueHighValue |
			object := objectValue.
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssTop popToReg: object.
		self ssPop: 1.

		objectRepresentation genConvertSmallIntegerToIntegerInReg: object.
		self MoveCq: 0 R: valueHigh.
		self ssPushNativeRegister: object secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeOopResultInteger: [:objectValue :valueValue |
			object := objectValue.
			value := valueValue.
		].

		self ssTop popToReg: object.
		self ssPop: 1.

		objectRepresentation genConvertSmallIntegerToIntegerInReg: object.
		self ssPushNativeRegister: object.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopToBoolean32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object |
	self allocateRegistersForLowcodeOop: [:objectValue |
		object := objectValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	self annotate: (self SubCw: objectMemory falseObject R: object) objRef: objectMemory falseObject.
	self ssPushNativeRegister: object.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopToBoolean64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh object value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeOopResultInteger2: [:objectValue :valueLowValue :valueHighValue |
			object := objectValue.
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssTop popToReg: object.
		self ssPop: 1.

		self MoveCq: 0 R: valueHigh.
		self annotate: (self SubCw: objectMemory falseObject R: object) objRef: objectMemory falseObject.
		self ssPushNativeRegister: object secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeOopResultInteger: [:objectValue :valueValue |
			object := objectValue.
			value := valueValue.
		].

		self ssTop popToReg: object.
		self ssPop: 1.

		self annotate: (self SubCw: objectMemory falseObject R: object) objRef: objectMemory falseObject.
		self ssPushNativeRegister: object.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopToFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object value |
	self allocateRegistersForLowcodeOopResultFloat: [:objectValue :valueValue |
		object := objectValue.
		value := valueValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	self ssFlushAll.
	objectRepresentation genLcOop: object toFloat32: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopToFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object value |
	self allocateRegistersForLowcodeOopResultFloat: [:objectValue :valueValue |
		object := objectValue.
		value := valueValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	self ssFlushAll.
	objectRepresentation genLcOop: object toFloat64: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopToInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object |
	self allocateRegistersForLowcodeOop: [:objectValue |
		object := objectValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	self ssFlushAll.
	objectRepresentation genLcOopToInt32: object.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopToInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh object value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeOopResultInteger2: [:objectValue :valueLowValue :valueHighValue |
			object := objectValue.
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssTop popToReg: object.
		self ssPop: 1.

		self ssFlushAll.
		objectRepresentation genLcOop: object toInt64: valueLow highPart: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeOopResultInteger: [:objectValue :valueValue |
			object := objectValue.
			value := valueValue.
		].

		self ssTop popToReg: object.
		self ssPop: 1.

		self ssFlushAll.
		objectRepresentation genLcOopToInt64: object.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopToPointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object |
	self allocateRegistersForLowcodeOop: [:objectValue |
		object := objectValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcOopToPointer: object.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopToPointerReinterpret [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object pointer |
	self allocateRegistersForLowcodeOopResultInteger: [:objectValue :pointerValue |
		object := objectValue.
		pointer := pointerValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	"TODO: Generate a nop here"
	self ssPushNativeRegister: object.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopToUInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object value |
	self allocateRegistersForLowcodeOopResultInteger: [:objectValue :valueValue |
		object := objectValue.
		value := valueValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	self ssFlushAll.
	objectRepresentation genLcOopToUInt32: object.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOopToUInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh object value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeOopResultInteger2: [:objectValue :valueLowValue :valueHighValue |
			object := objectValue.
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssTop popToReg: object.
		self ssPop: 1.

		self ssFlushAll.
		objectRepresentation genLcOop: object toUInt64: valueLow highPart: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeOopResultInteger: [:objectValue :valueValue |
			object := objectValue.
			value := valueValue.
		].

		self ssTop popToReg: object.
		self ssPop: 1.

		self ssFlushAll.
		objectRepresentation genLcOopToUInt64: object.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOr32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second result first |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :resultValue |
		second := secondValue.
		first := firstValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self OrR: second R: first.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeOr64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh first second firstLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger4: [:secondLowValue :secondHighValue :firstLowValue :firstHighValue |
			secondLow := secondLowValue.
			secondHigh := secondHighValue.
			firstLow := firstLowValue.
			firstHigh := firstHighValue.
		].

		self ssNativeTop nativePopToReg: secondLow secondReg: secondHigh.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: firstLow secondReg: firstHigh.
		self ssNativePop: 1.

		self OrR: secondLow R: firstLow.
		self OrR: secondHigh R: firstHigh.
		self ssPushNativeRegister: firstLow secondRegister: firstHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
			second := secondValue.
			first := firstValue.
		].

		self ssNativeTop nativePopToReg: second.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: first.
		self ssNativePop: 1.

		self OrR: second R: first.
		self ssPushNativeRegister: first.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self callSwitchToCStack.
	self MoveCw: extA R: TempReg.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	backEnd cFloatResultToRs: DPFPReg0.
	self ssPushNativeRegisterSingleFloat: DPFPReg0.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self callSwitchToCStack.
	self MoveCw: extA R: TempReg.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	backEnd cFloatResultToRd: DPFPReg0.
	self ssPushNativeRegisterDoubleFloat: DPFPReg0.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallIndirectFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	self callSwitchToCStack.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	backEnd cFloatResultToRs: DPFPReg0.
	self ssPushNativeRegisterSingleFloat: DPFPReg0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallIndirectFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	self callSwitchToCStack.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	backEnd cFloatResultToRd: DPFPReg0.
	self ssPushNativeRegisterDoubleFloat: DPFPReg0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallIndirectInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	self callSwitchToCStack.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	self MoveR: backEnd cResultRegister R: ReceiverResultReg.
	self ssPushNativeRegister: ReceiverResultReg.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallIndirectInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	self callSwitchToCStack.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	BytesPerWord = 4 ifTrue: [
	self MoveR: backEnd cResultRegisterLow R: ReceiverResultReg.
	self MoveR: backEnd cResultRegisterHigh R: Arg0Reg.
	self ssPushNativeRegister: ReceiverResultReg secondRegister: Arg0Reg.
	] ifFalse: [
	self MoveR: backEnd cResultRegister R: ReceiverResultReg.
	self ssPushNativeRegister: ReceiverResultReg.
	].

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallIndirectPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	self callSwitchToCStack.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	self MoveR: backEnd cResultRegister R: ReceiverResultReg.
	self ssPushNativeRegister: ReceiverResultReg.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallIndirectStructure [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	"Push the result space"
	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	self PushR: TempReg.
	"Fetch the function pointer"
	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	"Call the function"
	self callSwitchToCStack.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	"Fetch the result"
	self MoveR: backEnd cResultRegister R: ReceiverResultReg.
	self ssPushNativeRegister: ReceiverResultReg.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallIndirectVoid [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	self callSwitchToCStack.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self callSwitchToCStack.
	self MoveCw: extA R: TempReg.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	self MoveR: backEnd cResultRegister R: ReceiverResultReg.
	self ssPushNativeRegister: ReceiverResultReg.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self callSwitchToCStack.
	self MoveCw: extA R: TempReg.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	BytesPerWord = 4 ifTrue: [
	self MoveR: backEnd cResultRegisterLow R: ReceiverResultReg.
	self MoveR: backEnd cResultRegisterHigh R: Arg0Reg.
	self ssPushNativeRegister: ReceiverResultReg secondRegister: Arg0Reg.
	] ifFalse: [
	self MoveR: backEnd cResultRegister R: ReceiverResultReg.
	self ssPushNativeRegister: ReceiverResultReg.
	].
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self callSwitchToCStack.
	self MoveCw: extA R: TempReg.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	self MoveR: backEnd cResultRegister R: ReceiverResultReg.
	self ssPushNativeRegister: ReceiverResultReg.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallStructure [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	"Push the result space"
	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	self PushR: TempReg.
	"Call the function"
	self callSwitchToCStack.
	self MoveCw: extA R: TempReg.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	"Fetch the result"
	self MoveR: backEnd cResultRegister R: ReceiverResultReg.
	self ssPushNativeRegister: ReceiverResultReg.
	extA := 0.
	extB := 0.
	numExtB := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallVoid [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self callSwitchToCStack.
	self MoveCw: extA R: TempReg.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCallout [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self callSwitchToCStack.
	self MoveCw: extA R: TempReg.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePerformCalloutIndirect [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssNativeTop nativeStackPopToReg: TempReg.
	self ssNativePop: 1.
	self callSwitchToCStack.
	self CallRT: ceFFICalloutTrampoline.
	self annotateBytecode: self Label.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePin [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object |
	self allocateRegistersForLowcodeOop: [:objectValue |
		object := objectValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePlaftormCode [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePointerAddConstantOffset [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| base offset |
	offset := extB.
	self allocateRegistersForLowcodeInteger: [:baseValue |
		base := baseValue.
	].

	self ssNativeTop nativePopToReg: base.
	self ssNativePop: 1.

	self AddCq: offset R: base.
	self ssPushNativeRegister: base.

	extB := 0.
	numExtB := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePointerAddOffset32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| base offset |
	self allocateRegistersForLowcodeInteger2: [:offsetValue :baseValue |
		offset := offsetValue.
		base := baseValue.
	].

	self ssNativeTop nativePopToReg: offset.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: base.
	self ssNativePop: 1.

	self AddR: offset R: base.
	self ssPushNativeRegister: base.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePointerAddOffset64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| offsetHigh base offset offsetLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger3: [:offsetLowValue :offsetHighValue :baseValue |
			offsetLow := offsetLowValue.
			offsetHigh := offsetHighValue.
			base := baseValue.
		].

		self ssNativeTop nativePopToReg: offsetLow secondReg: offsetHigh.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: base.
		self ssNativePop: 1.

		self AddR: offsetLow R: base.
		self ssPushNativeRegister: base.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger2: [:offsetValue :baseValue |
			offset := offsetValue.
			base := baseValue.
		].

		self ssNativeTop nativePopToReg: offset.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: base.
		self ssNativePop: 1.

		self AddR: offset R: base.
		self ssPushNativeRegister: base.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePointerEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second falseJump contJump first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpR: second R: first.
	falseJump := self JumpNonZero: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePointerNotEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second falseJump contJump first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpR: second R: first.
	falseJump := self JumpZero: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePointerToInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer |
	self allocateRegistersForLowcodeInteger: [:pointerValue |
		pointer := pointerValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.

	"TODO: Perform a NOP here"
	self ssPushNativeRegister: pointer.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePointerToInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| resultLow pointer result resultHigh |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeIntegerResultInteger2: [:pointerValue :resultLowValue :resultHighValue |
			pointer := pointerValue.
			resultLow := resultLowValue.
			resultHigh := resultHighValue.
		].

		self ssNativeTop nativePopToReg: pointer.
		self ssNativePop: 1.

		self MoveR: pointer R: resultLow.
		self MoveCq: 0 R: resultHigh.
		self ssPushNativeRegister: resultLow secondRegister: resultHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeIntegerResultInteger: [:pointerValue :resultValue |
			pointer := pointerValue.
			result := resultValue.
		].

		self ssNativeTop nativePopToReg: pointer.
		self ssNativePop: 1.

		self ssPushNativeRegister: pointer.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePointerToOop [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer pointerClassLiteral |
	pointerClassLiteral := self getLiteral: extA.
	self allocateRegistersForLowcodeInteger: [:pointerValue |
		pointer := pointerValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.

	self ssFlushAll.
	objectRepresentation genLcPointerToOop: pointer class: pointerClassLiteral.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePointerToOopReinterprer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer |
	self allocateRegistersForLowcodeInteger: [:pointerValue |
		pointer := pointerValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.

	"TODO: Generate a nop here"
	self ssPushRegister: pointer.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePopFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeFloat: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.


	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePopFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeFloat: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.


	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePopInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.


	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePopInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.


	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePopMultipleNative [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssPopNativeSize: extA.
	extA := 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePopPointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointerValue |
	self allocateRegistersForLowcodeInteger: [:pointerValueValue |
		pointerValue := pointerValueValue.
	].

	self ssNativeTop nativePopToReg: pointerValue.
	self ssNativePop: 1.


	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushCalloutResultFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	backEnd cFloatResultToRs: DPFPReg0.
	self ssPushNativeRegisterSingleFloat: DPFPReg0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushCalloutResultFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	backEnd cFloatResultToRd: DPFPReg0.
	self ssPushNativeRegisterDoubleFloat: DPFPReg0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushCalloutResultInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self MoveR: backEnd cResultRegister R: ReceiverResultReg.
	self ssPushNativeRegister: ReceiverResultReg.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushCalloutResultInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	BytesPerWord = 4 ifTrue: [
	self MoveR: backEnd cResultRegisterLow R: ReceiverResultReg.
	self MoveR: backEnd cResultRegisterHigh R: Arg0Reg.
	self ssPushNativeRegister: ReceiverResultReg secondRegister: Arg0Reg.
	] ifFalse: [
	self MoveR: backEnd cResultRegister R: ReceiverResultReg.
	self ssPushNativeRegister: ReceiverResultReg.
	].

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushCalloutResultPointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self MoveR: backEnd cResultRegister R: ReceiverResultReg.
	self ssPushNativeRegister: ReceiverResultReg.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushConstantUInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| constant |
	constant := extA.

	self ssPushNativeConstantInt32: constant.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushConstantUInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| constant |
	constant := extA.

	self ssPushNativeConstantInt64: constant.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushNullPointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssPushNativeConstantPointer: 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushOne32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssPushNativeConstantInt32: 1.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushOne64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssPushNativeConstantInt64: 1.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushOneFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssPushNativeConstantFloat32: 1.0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushOneFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssPushNativeConstantFloat64: 1.0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushPhysicalFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| registerID |
	registerID := extA.

	self abort.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushPhysicalFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| registerID |
	registerID := extA.

	self abort.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushPhysicalInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| registerID |
	registerID := extA.

	self abort.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushPhysicalInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| registerID |
	registerID := extA.

	self abort.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushPhysicalPointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| registerID |
	registerID := extA.

	self abort.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushSessionIdentifier [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssPushNativeConstantInt32: coInterpreter getThisSessionID.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushZero32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssPushNativeConstantInt32: 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushZero64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssPushNativeConstantInt64: 0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushZeroFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssPushNativeConstantFloat32: 0.0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodePushZeroFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self ssPushNativeConstantFloat64: 0.0.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeRem32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self DivR: second R: first Quo: second Rem: first.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeRem64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh result resultLow resultHigh first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :resultValue |
		second := secondValue.
		first := firstValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeRightShift32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value shiftAmount |
	self allocateRegistersForLowcodeInteger2: [:shiftAmountValue :valueValue |
		shiftAmount := shiftAmountValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: shiftAmount.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self LogicalShiftRightR: shiftAmount R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeRightShift64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value result shiftAmountHigh shiftAmount resultLow valueLow resultHigh shiftAmountLow valueHigh |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:shiftAmountValue :valueValue :resultValue |
		shiftAmount := shiftAmountValue.
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: shiftAmount.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeSignExtend32From16 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self SignExtend16R: value R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeSignExtend32From8 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self SignExtend8R: value R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeSignExtend64From16 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value isNegative cont valueLow valueHigh |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self SignExtend16R: valueLow R: valueLow.
		"Check the sign to set the high word"
		self CmpCq: 0 R: valueLow.
		"Positive"
		isNegative := self JumpLess: 0.
		self MoveCq: 0 R: valueHigh.
		cont := self Jump: 0.
		"Negative"
		isNegative jmpTarget: (self MoveCq: -1 R: valueHigh).
		cont jmpTarget: self Label.
		self ssPushNativeRegister: valueLow secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger: [:valueValue |
			value := valueValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self SignExtend16R: value R: value.
		self ssPushNativeRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeSignExtend64From32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value result resultLow resultHigh isNegative cont |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeIntegerResultInteger2: [:valueValue :resultLowValue :resultHighValue |
			value := valueValue.
			resultLow := resultLowValue.
			resultHigh := resultHighValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self MoveR: value R: resultLow.
		"Check the sign to set the high word"
		self CmpCq: 0 R: value.
		"Positive"
		isNegative := self JumpLess: 0.
		self MoveCq: 0 R: resultHigh.
		cont := self Jump: 0.
		"Negative"
		isNegative jmpTarget: (self MoveCq: -1 R: resultHigh).
		cont jmpTarget: self Label.
		self ssPushNativeRegister: resultLow secondRegister: resultHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeIntegerResultInteger: [:valueValue :resultValue |
			value := valueValue.
			result := resultValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self SignExtend32R: value R: value.
		self ssPushNativeRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeSignExtend64From8 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value result resultLow resultHigh isNegative valueLow cont valueHigh |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2ResultInteger2: [:valueLowValue :valueHighValue :resultLowValue :resultHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
			resultLow := resultLowValue.
			resultHigh := resultHighValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self SignExtend8R: valueLow R: valueLow.
		"Check the sign to set the high word"
		self CmpCq: 0 R: valueLow.
		"Positive"
		isNegative := self JumpLess: 0.
		self MoveCq: 0 R: valueHigh.
		cont := self Jump: 0.
		"Negative"
		isNegative jmpTarget: (self MoveCq: -1 R: valueHigh).
		cont jmpTarget: self Label.
		self ssPushNativeRegister: valueLow secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeIntegerResultInteger: [:valueValue :resultValue |
			value := valueValue.
			result := resultValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self ZeroExtend16R: value R: value.
		self ssPushNativeRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeSmallInt32ToOop [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	objectRepresentation genConvertIntegerToSmallIntegerInReg: value.
	self ssPushRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreFloat32ToMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| floatValue pointer |
	self allocateRegistersForLowcodeFloatInteger: [:floatValueValue :pointerValue |
		floatValue := floatValueValue.
		pointer := pointerValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: floatValue.
	self ssNativePop: 1.

	self MoveRs: floatValue M32: 0 r: pointer.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreFloat64ToMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| doubleValue pointer |
	self allocateRegistersForLowcodeFloatInteger: [:doubleValueValue :pointerValue |
		doubleValue := doubleValueValue.
		pointer := pointerValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: doubleValue.
	self ssNativePop: 1.

	self MoveRd: doubleValue M64: 0 r: pointer.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreInt16ToMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer value |
	self allocateRegistersForLowcodeInteger2: [:pointerValue :valueValue |
		pointer := pointerValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self MoveR: value R: TempReg.
	self MoveR: TempReg M16: 0 r: pointer.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreInt32ToMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer value |
	self allocateRegistersForLowcodeInteger2: [:pointerValue :valueValue |
		pointer := pointerValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self MoveR: value M32: 0 r: pointer.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreInt64ToMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh pointer value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger3: [:pointerValue :valueLowValue :valueHighValue |
			pointer := pointerValue.
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssNativeTop nativePopToReg: pointer.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self MoveR: valueLow M32: 0 r: pointer.
		self MoveR: valueHigh M32: 4 r: pointer.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger2: [:pointerValue :valueValue |
			pointer := pointerValue.
			value := valueValue.
		].

		self ssNativeTop nativePopToReg: pointer.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self MoveR: value M64: 0 r: pointer.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreInt8ToMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointer value |
	self allocateRegistersForLowcodeInteger2: [:pointerValue :valueValue |
		pointer := pointerValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: pointer.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self MoveR: value R: TempReg.
	self MoveR: TempReg M8: 0 r: pointer.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreLocalFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeFloat: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self loadNativeLocalAddress: baseOffset to: TempReg.
	self MoveRs: value M32: 0 r: TempReg.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreLocalFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeFloat: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self loadNativeLocalAddress: baseOffset to: TempReg.
	self MoveRd: value M64: 0 r: TempReg.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreLocalInt16 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self MoveR: value R: TempReg.
	self loadNativeLocalAddress: baseOffset to: value.
	self MoveR: TempReg M16: 0 r: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreLocalInt32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self loadNativeLocalAddress: baseOffset to: TempReg.
	self MoveR: value M32: 0 r: TempReg.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreLocalInt64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow baseOffset |
	baseOffset := extA.
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self loadNativeLocalAddress: baseOffset to: TempReg.
		self MoveR: valueLow M32: 0 r: TempReg.
		self MoveR: valueHigh M32: 4 r: TempReg.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger: [:valueValue |
			value := valueValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self MoveR: value M64: 0 r: TempReg.

	].
		extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreLocalInt8 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self MoveR: value R: TempReg.
	self loadNativeLocalAddress: baseOffset to: value.
	self MoveR: TempReg M8: 0 r: value.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreLocalPointer [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| pointerValue baseOffset |
	baseOffset := extA.
	self allocateRegistersForLowcodeInteger: [:pointerValueValue |
		pointerValue := pointerValueValue.
	].

	self ssNativeTop nativePopToReg: pointerValue.
	self ssNativePop: 1.

	self loadNativeLocalAddress: baseOffset to: TempReg.
	self MoveR: pointerValue Mw: 0 r: TempReg.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreObjectField [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| fieldIndex object value |
	fieldIndex := extA.
	self allocateRegistersForLowcodeOop2: [:valueValue :objectValue |
		value := valueValue.
		object := objectValue.
	].

	self ssTop popToReg: value.
	self ssPop: 1.
	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcStore: value object: object field: fieldIndex.

	extA := 0.
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStoreObjectFieldAt [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| fieldIndex object value |
	self allocateRegistersForLowcodeIntegerOop2: [:fieldIndexValue :valueValue :objectValue |
		fieldIndex := fieldIndexValue.
		value := valueValue.
		object := objectValue.
	].

	self ssTop popToReg: value.
	self ssPop: 1.
	self ssNativeTop nativePopToReg: fieldIndex.
	self ssNativePop: 1.
	self ssTop popToReg: object.
	self ssPop: 1.

	objectRepresentation genLcStore: value object: object at: fieldIndex.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeStorePointerToMemory [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| memoryPointer pointerValue |
	self allocateRegistersForLowcodeInteger2: [:memoryPointerValue :pointerValueValue |
		memoryPointer := memoryPointerValue.
		pointerValue := pointerValueValue.
	].

	self ssNativeTop nativePopToReg: memoryPointer.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: pointerValue.
	self ssNativePop: 1.

	self MoveR: pointerValue Mw: 0 r: memoryPointer.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeSub32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self SubR: second R: first.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeSub64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh first second firstLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger4: [:secondLowValue :secondHighValue :firstLowValue :firstHighValue |
			secondLow := secondLowValue.
			secondHigh := secondHighValue.
			firstLow := firstLowValue.
			firstHigh := firstHighValue.
		].

		self ssNativeTop nativePopToReg: secondLow secondReg: secondHigh.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: firstLow secondReg: firstHigh.
		self ssNativePop: 1.

		self SubR: secondLow R: firstLow.
		self SubbR: secondHigh R: firstHigh.
		self ssPushNativeRegister: firstLow secondRegister: firstHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
			second := secondValue.
			first := firstValue.
		].

		self ssNativeTop nativePopToReg: second.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: first.
		self ssNativePop: 1.

		self SubR: second R: first.
		self ssPushNativeRegister: first.

	].
	^ 0


]

{ #category : #'inline primitive generators dispatch generated code' }
StackToRegisterMappingCogit >> genLowcodeTrinaryInlinePrimitive: prim [
	<option: #LowcodeVM>	"Lowcode instruction generator dispatch"
	prim
		caseOf: {
			[0]	-> [ ^ self genLowcodeOopEqual ].
			[1]	-> [ ^ self genLowcodeOopNotEqual ].
			[2]	-> [ ^ self genLowcodeStoreObjectField ].
			[3]	-> [ ^ self genLowcodeStoreObjectFieldAt ].
		}
		otherwise: [ ^ EncounteredUnknownBytecode ].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeTruncate32To16 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self AndCq: 16rFFFF R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeTruncate32To8 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self AndCq: 16rFF R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeTruncate64To16 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self AndCq: 16rFFFF R: valueLow.
		self ssPushNativeRegister: valueLow.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger: [:valueValue |
			value := valueValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self AndCq: 16rFFFF R: value.
		self ssPushNativeRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeTruncate64To32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self ssPushNativeRegister: valueLow.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger: [:valueValue |
			value := valueValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self AndCq: 16rFFFFFFFF R: value.
		self ssPushNativeRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeTruncate64To8 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow result |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2ResultInteger: [:valueLowValue :valueHighValue :resultValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
			result := resultValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self AndCq: 16rFF R: valueLow.
		self ssPushNativeRegister: valueLow.

	] ifFalse: [
		self allocateRegistersForLowcodeIntegerResultInteger: [:valueValue :resultValue |
			value := valueValue.
			result := resultValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self AndCq: 16rFF R: value.
		self ssPushNativeRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUdiv32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self DivR: second R: first Quo: first Rem: second.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUdiv64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh result resultLow resultHigh first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :resultValue |
		second := secondValue.
		first := firstValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint32Great [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second falseJump contJump first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpR: second R: first.
	falseJump := self JumpBelowOrEqual: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint32GreatEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second falseJump contJump first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpR: second R: first.
	falseJump := self JumpBelow: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint32Less [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second falseJump contJump first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpR: second R: first.
	falseJump := self JumpAboveOrEqual: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint32LessEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second falseJump contJump first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self CmpR: second R: first.
	falseJump := self JumpAbove: 0.
	"True result"
	self MoveCq: 1 R: first.
	contJump := self Jump: 0.
	"False result"
	falseJump jmpTarget: self Label.
	self MoveCq: 0 R: first.
	contJump jmpTarget: self Label.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint32ToFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value result |
	self allocateRegistersForLowcodeIntegerResultFloat: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self ConvertR: value Rs: result.
	self ssPushNativeRegisterSingleFloat: result.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint32ToFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value result |
	self allocateRegistersForLowcodeIntegerResultFloat: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self ConvertR: value Rd: result.
	self ssPushNativeRegisterDoubleFloat: result.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint32ToOop [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self ssFlushAll.
	objectRepresentation genLcUInt32ToOop: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint64Great [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh value first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint64GreatEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh value first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint64Less [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh value first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint64LessEqual [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh value first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :valueValue |
		second := secondValue.
		first := firstValue.
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint64ToFloat32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow result |
	self allocateRegistersForLowcodeIntegerResultFloat: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint64ToFloat64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow result |
	self allocateRegistersForLowcodeIntegerResultFloat: [:valueValue :resultValue |
		value := valueValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUint64ToOop [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh object value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2ResultOop: [:valueLowValue :valueHighValue :objectValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
			object := objectValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self ssFlushAll.
		objectRepresentation genLcUInt64ToOop: valueLow highPart: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeIntegerResultOop: [:valueValue :objectValue |
			value := valueValue.
			object := objectValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self ssFlushAll.
		objectRepresentation genLcUInt64ToOop: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUmul32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self MulR: second R: first.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUmul64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh result resultLow resultHigh first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :resultValue |
		second := secondValue.
		first := firstValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators dispatch generated code' }
StackToRegisterMappingCogit >> genLowcodeUnaryInlinePrimitive2: prim [
	<option: #LowcodeVM>	"Lowcode instruction generator dispatch"
	prim
		caseOf: {
			[60]	-> [ ^ self genLowcodeFloat64ToFloat32 ].
			[61]	-> [ ^ self genLowcodeFloat64ToInt32 ].
			[62]	-> [ ^ self genLowcodeFloat64ToInt64 ].
			[63]	-> [ ^ self genLowcodeFloat64ToUInt32 ].
			[64]	-> [ ^ self genLowcodeFloat64ToUInt64 ].
			[65]	-> [ ^ self genLowcodeFree ].
			[66]	-> [ ^ self genLowcodeInstantiateIndexable32Oop ].
			[67]	-> [ ^ self genLowcodeInstantiateIndexableOop ].
			[68]	-> [ ^ self genLowcodeInstantiateOop ].
			[69]	-> [ ^ self genLowcodeInt32Equal ].
			[70]	-> [ ^ self genLowcodeInt32Great ].
			[71]	-> [ ^ self genLowcodeInt32GreatEqual ].
			[72]	-> [ ^ self genLowcodeInt32Less ].
			[73]	-> [ ^ self genLowcodeInt32LessEqual ].
			[74]	-> [ ^ self genLowcodeInt32NotEqual ].
			[75]	-> [ ^ self genLowcodeInt32ToFloat32 ].
			[76]	-> [ ^ self genLowcodeInt32ToFloat64 ].
			[77]	-> [ ^ self genLowcodeInt32ToPointer ].
			[78]	-> [ ^ self genLowcodeInt64Equal ].
			[79]	-> [ ^ self genLowcodeInt64Great ].
			[80]	-> [ ^ self genLowcodeInt64GreatEqual ].
			[81]	-> [ ^ self genLowcodeInt64Less ].
			[82]	-> [ ^ self genLowcodeInt64LessEqual ].
			[83]	-> [ ^ self genLowcodeInt64NotEqual ].
			[84]	-> [ ^ self genLowcodeInt64ToFloat32 ].
			[85]	-> [ ^ self genLowcodeInt64ToFloat64 ].
			[86]	-> [ ^ self genLowcodeInt64ToPointer ].
			[87]	-> [ ^ self genLowcodeLeftShift32 ].
			[88]	-> [ ^ self genLowcodeLeftShift64 ].
			[89]	-> [ ^ self genLowcodeLoadArgumentAddress ].
			[90]	-> [ ^ self genLowcodeLoadArgumentFloat32 ].
			[91]	-> [ ^ self genLowcodeLoadArgumentFloat64 ].
			[92]	-> [ ^ self genLowcodeLoadArgumentInt16 ].
			[93]	-> [ ^ self genLowcodeLoadArgumentInt32 ].
			[94]	-> [ ^ self genLowcodeLoadArgumentInt64 ].
			[95]	-> [ ^ self genLowcodeLoadArgumentInt8 ].
			[96]	-> [ ^ self genLowcodeLoadArgumentPointer ].
			[97]	-> [ ^ self genLowcodeLoadArgumentUInt16 ].
			[98]	-> [ ^ self genLowcodeLoadArgumentUInt32 ].
			[99]	-> [ ^ self genLowcodeLoadArgumentUInt64 ].
			[100]	-> [ ^ self genLowcodeLoadArgumentUInt8 ].
			[101]	-> [ ^ self genLowcodeLoadFloat32FromMemory ].
			[102]	-> [ ^ self genLowcodeLoadFloat64FromMemory ].
			[103]	-> [ ^ self genLowcodeLoadInt16FromMemory ].
			[104]	-> [ ^ self genLowcodeLoadInt32FromMemory ].
			[105]	-> [ ^ self genLowcodeLoadInt64FromMemory ].
			[106]	-> [ ^ self genLowcodeLoadInt8FromMemory ].
			[107]	-> [ ^ self genLowcodeLoadLocalAddress ].
			[108]	-> [ ^ self genLowcodeLoadLocalFloat32 ].
			[109]	-> [ ^ self genLowcodeLoadLocalFloat64 ].
			[110]	-> [ ^ self genLowcodeLoadLocalInt16 ].
			[111]	-> [ ^ self genLowcodeLoadLocalInt32 ].
			[112]	-> [ ^ self genLowcodeLoadLocalInt64 ].
			[113]	-> [ ^ self genLowcodeLoadLocalInt8 ].
			[114]	-> [ ^ self genLowcodeLoadLocalPointer ].
			[115]	-> [ ^ self genLowcodeLoadLocalUInt16 ].
			[116]	-> [ ^ self genLowcodeLoadLocalUInt32 ].
			[117]	-> [ ^ self genLowcodeLoadLocalUInt64 ].
			[118]	-> [ ^ self genLowcodeLoadLocalUInt8 ].
			[119]	-> [ ^ self genLowcodeLoadObjectAt ].
		}
		otherwise: [ ^ self genLowcodeUnaryInlinePrimitive3: prim ].
	^ 0


]

{ #category : #'inline primitive generators dispatch generated code' }
StackToRegisterMappingCogit >> genLowcodeUnaryInlinePrimitive3: prim [
	<option: #LowcodeVM>	"Lowcode instruction generator dispatch"
	prim
		caseOf: {
			[120]	-> [ ^ self genLowcodeLoadObjectField ].
			[121]	-> [ ^ self genLowcodeLoadPointerFromMemory ].
			[122]	-> [ ^ self genLowcodeLoadUInt16FromMemory ].
			[123]	-> [ ^ self genLowcodeLoadUInt32FromMemory ].
			[124]	-> [ ^ self genLowcodeLoadUInt64FromMemory ].
			[125]	-> [ ^ self genLowcodeLoadUInt8FromMemory ].
			[126]	-> [ ^ self genLowcodeLocalFrameSize ].
			[127]	-> [ ^ self genLowcodeLockRegisters ].
			[128]	-> [ ^ self genLowcodeLockVM ].
			[129]	-> [ ^ self genLowcodeMalloc32 ].
			[130]	-> [ ^ self genLowcodeMalloc64 ].
			[131]	-> [ ^ self genLowcodeMemcpy32 ].
			[132]	-> [ ^ self genLowcodeMemcpy64 ].
			[133]	-> [ ^ self genLowcodeMemcpyFixed ].
			[134]	-> [ ^ self genLowcodeMoveFloat32ToPhysical ].
			[135]	-> [ ^ self genLowcodeMoveFloat64ToPhysical ].
			[136]	-> [ ^ self genLowcodeMoveInt32ToPhysical ].
			[137]	-> [ ^ self genLowcodeMoveInt64ToPhysical ].
			[138]	-> [ ^ self genLowcodeMovePointerToPhysical ].
			[139]	-> [ ^ self genLowcodeMul32 ].
			[140]	-> [ ^ self genLowcodeMul64 ].
			[141]	-> [ ^ self genLowcodeNeg32 ].
			[142]	-> [ ^ self genLowcodeNeg64 ].
			[143]	-> [ ^ self genLowcodeNot32 ].
			[144]	-> [ ^ self genLowcodeNot64 ].
			[145]	-> [ ^ self genLowcodeOr32 ].
			[146]	-> [ ^ self genLowcodeOr64 ].
			[147]	-> [ ^ self genLowcodePerformCallout ].
			[148]	-> [ ^ self genLowcodePerformCalloutIndirect ].
			[149]	-> [ ^ self genLowcodePushCalloutResultFloat32 ].
			[150]	-> [ ^ self genLowcodePushCalloutResultFloat64 ].
			[151]	-> [ ^ self genLowcodePushCalloutResultInt32 ].
			[152]	-> [ ^ self genLowcodePushCalloutResultInt64 ].
			[153]	-> [ ^ self genLowcodePushCalloutResultPointer ].
			[161]	-> [ ^ self genLowcodePlaftormCode ].
			[162]	-> [ ^ self genLowcodePointerAddConstantOffset ].
			[163]	-> [ ^ self genLowcodePointerAddOffset32 ].
			[164]	-> [ ^ self genLowcodePointerAddOffset64 ].
			[165]	-> [ ^ self genLowcodePointerEqual ].
			[166]	-> [ ^ self genLowcodePointerNotEqual ].
			[167]	-> [ ^ self genLowcodePointerToInt32 ].
			[168]	-> [ ^ self genLowcodePointerToInt64 ].
			[169]	-> [ ^ self genLowcodePopFloat32 ].
			[170]	-> [ ^ self genLowcodePopFloat64 ].
			[171]	-> [ ^ self genLowcodePopInt32 ].
			[172]	-> [ ^ self genLowcodePopInt64 ].
			[173]	-> [ ^ self genLowcodePopMultipleNative ].
			[174]	-> [ ^ self genLowcodePopPointer ].
			[175]	-> [ ^ self genLowcodePushConstantUInt32 ].
			[176]	-> [ ^ self genLowcodePushConstantUInt64 ].
			[177]	-> [ ^ self genLowcodePushNullPointer ].
			[178]	-> [ ^ self genLowcodePushOne32 ].
			[179]	-> [ ^ self genLowcodePushOne64 ].
			[180]	-> [ ^ self genLowcodePushOneFloat32 ].
			[181]	-> [ ^ self genLowcodePushOneFloat64 ].
			[182]	-> [ ^ self genLowcodePushPhysicalFloat32 ].
			[183]	-> [ ^ self genLowcodePushPhysicalFloat64 ].
			[184]	-> [ ^ self genLowcodePushPhysicalInt32 ].
			[185]	-> [ ^ self genLowcodePushPhysicalInt64 ].
			[186]	-> [ ^ self genLowcodePushPhysicalPointer ].
		}
		otherwise: [ ^ self genLowcodeUnaryInlinePrimitive4: prim ].
	^ 0


]

{ #category : #'inline primitive generators dispatch generated code' }
StackToRegisterMappingCogit >> genLowcodeUnaryInlinePrimitive4: prim [
	<option: #LowcodeVM>	"Lowcode instruction generator dispatch"
	prim
		caseOf: {
			[187]	-> [ ^ self genLowcodePushSessionIdentifier ].
			[188]	-> [ ^ self genLowcodePushZero32 ].
			[189]	-> [ ^ self genLowcodePushZero64 ].
			[190]	-> [ ^ self genLowcodePushZeroFloat32 ].
			[191]	-> [ ^ self genLowcodePushZeroFloat64 ].
			[192]	-> [ ^ self genLowcodeRem32 ].
			[193]	-> [ ^ self genLowcodeRem64 ].
			[194]	-> [ ^ self genLowcodeRightShift32 ].
			[195]	-> [ ^ self genLowcodeRightShift64 ].
			[196]	-> [ ^ self genLowcodeSignExtend32From16 ].
			[197]	-> [ ^ self genLowcodeSignExtend32From8 ].
			[198]	-> [ ^ self genLowcodeSignExtend64From16 ].
			[199]	-> [ ^ self genLowcodeSignExtend64From32 ].
			[200]	-> [ ^ self genLowcodeSignExtend64From8 ].
			[201]	-> [ ^ self genLowcodeStoreFloat32ToMemory ].
			[202]	-> [ ^ self genLowcodeStoreFloat64ToMemory ].
			[203]	-> [ ^ self genLowcodeStoreInt16ToMemory ].
			[204]	-> [ ^ self genLowcodeStoreInt32ToMemory ].
			[205]	-> [ ^ self genLowcodeStoreInt64ToMemory ].
			[206]	-> [ ^ self genLowcodeStoreInt8ToMemory ].
			[207]	-> [ ^ self genLowcodeStoreLocalFloat32 ].
			[208]	-> [ ^ self genLowcodeStoreLocalFloat64 ].
			[209]	-> [ ^ self genLowcodeStoreLocalInt16 ].
			[210]	-> [ ^ self genLowcodeStoreLocalInt32 ].
			[211]	-> [ ^ self genLowcodeStoreLocalInt64 ].
			[212]	-> [ ^ self genLowcodeStoreLocalInt8 ].
			[213]	-> [ ^ self genLowcodeStoreLocalPointer ].
			[214]	-> [ ^ self genLowcodeStorePointerToMemory ].
			[215]	-> [ ^ self genLowcodeSub32 ].
			[216]	-> [ ^ self genLowcodeSub64 ].
			[217]	-> [ ^ self genLowcodeTruncate32To16 ].
			[218]	-> [ ^ self genLowcodeTruncate32To8 ].
			[219]	-> [ ^ self genLowcodeTruncate64To16 ].
			[220]	-> [ ^ self genLowcodeTruncate64To32 ].
			[221]	-> [ ^ self genLowcodeTruncate64To8 ].
			[222]	-> [ ^ self genLowcodeUdiv32 ].
			[223]	-> [ ^ self genLowcodeUdiv64 ].
			[224]	-> [ ^ self genLowcodeUint32Great ].
			[225]	-> [ ^ self genLowcodeUint32GreatEqual ].
			[226]	-> [ ^ self genLowcodeUint32Less ].
			[227]	-> [ ^ self genLowcodeUint32LessEqual ].
			[228]	-> [ ^ self genLowcodeUint32ToFloat32 ].
			[229]	-> [ ^ self genLowcodeUint32ToFloat64 ].
			[230]	-> [ ^ self genLowcodeUint64Great ].
			[231]	-> [ ^ self genLowcodeUint64GreatEqual ].
			[232]	-> [ ^ self genLowcodeUint64Less ].
			[233]	-> [ ^ self genLowcodeUint64LessEqual ].
			[234]	-> [ ^ self genLowcodeUint64ToFloat32 ].
			[235]	-> [ ^ self genLowcodeUint64ToFloat64 ].
			[236]	-> [ ^ self genLowcodeUmul32 ].
			[237]	-> [ ^ self genLowcodeUmul64 ].
			[238]	-> [ ^ self genLowcodeUnlockRegisters ].
			[239]	-> [ ^ self genLowcodeUnlockVM ].
			[240]	-> [ ^ self genLowcodeUrem32 ].
			[241]	-> [ ^ self genLowcodeUrem64 ].
			[242]	-> [ ^ self genLowcodeXor32 ].
			[243]	-> [ ^ self genLowcodeXor64 ].
			[244]	-> [ ^ self genLowcodeZeroExtend32From16 ].
			[245]	-> [ ^ self genLowcodeZeroExtend32From8 ].
			[246]	-> [ ^ self genLowcodeZeroExtend64From16 ].
		}
		otherwise: [ ^ self genLowcodeUnaryInlinePrimitive5: prim ].
	^ 0


]

{ #category : #'inline primitive generators dispatch generated code' }
StackToRegisterMappingCogit >> genLowcodeUnaryInlinePrimitive5: prim [
	<option: #LowcodeVM>	"Lowcode instruction generator dispatch"
	prim
		caseOf: {
			[247]	-> [ ^ self genLowcodeZeroExtend64From32 ].
			[248]	-> [ ^ self genLowcodeZeroExtend64From8 ].
		}
		otherwise: [ ^ EncounteredUnknownBytecode ].
	^ 0


]

{ #category : #'inline primitive generators dispatch generated code' }
StackToRegisterMappingCogit >> genLowcodeUnaryInlinePrimitive: prim [
	<option: #LowcodeVM>	"Lowcode instruction generator dispatch"
	prim
		caseOf: {
			[0]	-> [ ^ self genLowcodeAdd32 ].
			[1]	-> [ ^ self genLowcodeAdd64 ].
			[2]	-> [ ^ self genLowcodeAlloca32 ].
			[3]	-> [ ^ self genLowcodeAlloca64 ].
			[4]	-> [ ^ self genLowcodeAnd32 ].
			[5]	-> [ ^ self genLowcodeAnd64 ].
			[6]	-> [ ^ self genLowcodeArithmeticRightShift32 ].
			[7]	-> [ ^ self genLowcodeArithmeticRightShift64 ].
			[8]	-> [ ^ self genLowcodeBeginCall ].
			[9]	-> [ ^ self genLowcodeCallArgumentFloat32 ].
			[10]	-> [ ^ self genLowcodeCallArgumentFloat64 ].
			[11]	-> [ ^ self genLowcodeCallArgumentInt32 ].
			[12]	-> [ ^ self genLowcodeCallArgumentInt64 ].
			[13]	-> [ ^ self genLowcodeCallArgumentPointer ].
			[14]	-> [ ^ self genLowcodeCallArgumentSpace ].
			[15]	-> [ ^ self genLowcodeCallArgumentStructure ].
			[16]	-> [ ^ self genLowcodeCallInstruction ].
			[17]	-> [ ^ self genLowcodeCallPhysical ].
			[18]	-> [ ^ self genLowcodeCheckSessionIdentifier ].
			[19]	-> [ ^ self genLowcodeCompareAndSwap32 ].
			[20]	-> [ ^ self genLowcodeDiv32 ].
			[21]	-> [ ^ self genLowcodeDiv64 ].
			[22]	-> [ ^ self genLowcodeDuplicateFloat32 ].
			[23]	-> [ ^ self genLowcodeDuplicateFloat64 ].
			[24]	-> [ ^ self genLowcodeDuplicateInt32 ].
			[25]	-> [ ^ self genLowcodeDuplicateInt64 ].
			[26]	-> [ ^ self genLowcodeDuplicatePointer ].
			[27]	-> [ ^ self genLowcodeEffectiveAddress32 ].
			[28]	-> [ ^ self genLowcodeEffectiveAddress64 ].
			[29]	-> [ ^ self genLowcodeEndCall ].
			[30]	-> [ ^ self genLowcodeEndCallNoCleanup ].
			[31]	-> [ ^ self genLowcodeFloat32Add ].
			[32]	-> [ ^ self genLowcodeFloat32Div ].
			[33]	-> [ ^ self genLowcodeFloat32Equal ].
			[34]	-> [ ^ self genLowcodeFloat32Great ].
			[35]	-> [ ^ self genLowcodeFloat32GreatEqual ].
			[36]	-> [ ^ self genLowcodeFloat32Less ].
			[37]	-> [ ^ self genLowcodeFloat32LessEqual ].
			[38]	-> [ ^ self genLowcodeFloat32Mul ].
			[39]	-> [ ^ self genLowcodeFloat32Neg ].
			[40]	-> [ ^ self genLowcodeFloat32NotEqual ].
			[41]	-> [ ^ self genLowcodeFloat32Sqrt ].
			[42]	-> [ ^ self genLowcodeFloat32Sub ].
			[43]	-> [ ^ self genLowcodeFloat32ToFloat64 ].
			[44]	-> [ ^ self genLowcodeFloat32ToInt32 ].
			[45]	-> [ ^ self genLowcodeFloat32ToInt64 ].
			[46]	-> [ ^ self genLowcodeFloat32ToUInt32 ].
			[47]	-> [ ^ self genLowcodeFloat32ToUInt64 ].
			[48]	-> [ ^ self genLowcodeFloat64Add ].
			[49]	-> [ ^ self genLowcodeFloat64Div ].
			[50]	-> [ ^ self genLowcodeFloat64Equal ].
			[51]	-> [ ^ self genLowcodeFloat64Great ].
			[52]	-> [ ^ self genLowcodeFloat64GreatEqual ].
			[53]	-> [ ^ self genLowcodeFloat64Less ].
			[54]	-> [ ^ self genLowcodeFloat64LessEqual ].
			[55]	-> [ ^ self genLowcodeFloat64Mul ].
			[56]	-> [ ^ self genLowcodeFloat64Neg ].
			[57]	-> [ ^ self genLowcodeFloat64NotEqual ].
			[58]	-> [ ^ self genLowcodeFloat64Sqrt ].
			[59]	-> [ ^ self genLowcodeFloat64Sub ].
		}
		otherwise: [ ^ self genLowcodeUnaryInlinePrimitive2: prim ].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUnlockRegisters [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	"Do nothing for now"

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUnlockVM [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUnpin [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| object |
	self allocateRegistersForLowcodeOop: [:objectValue |
		object := objectValue.
	].

	self ssTop popToReg: object.
	self ssPop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUrem32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self DivR: second R: first Quo: second Rem: first.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeUrem64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh result resultLow resultHigh first second firstLow |
	self allocateRegistersForLowcodeInteger2ResultInteger: [:secondValue :firstValue :resultValue |
		second := secondValue.
		first := firstValue.
		result := resultValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self abort.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeXor32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| second first |
	self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
		second := secondValue.
		first := firstValue.
	].

	self ssNativeTop nativePopToReg: second.
	self ssNativePop: 1.
	self ssNativeTop nativePopToReg: first.
	self ssNativePop: 1.

	self XorR: second R: first.
	self ssPushNativeRegister: first.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeXor64 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| secondLow secondHigh firstHigh first second firstLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger4: [:secondLowValue :secondHighValue :firstLowValue :firstHighValue |
			secondLow := secondLowValue.
			secondHigh := secondHighValue.
			firstLow := firstLowValue.
			firstHigh := firstHighValue.
		].

		self ssNativeTop nativePopToReg: secondLow secondReg: secondHigh.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: firstLow secondReg: firstHigh.
		self ssNativePop: 1.

		self XorR: secondLow R: firstLow.
		self XorR: secondHigh R: firstHigh.
		self ssPushNativeRegister: firstLow secondRegister: firstHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger2: [:secondValue :firstValue |
			second := secondValue.
			first := firstValue.
		].

		self ssNativeTop nativePopToReg: second.
		self ssNativePop: 1.
		self ssNativeTop nativePopToReg: first.
		self ssNativePop: 1.

		self XorR: second R: first.
		self ssPushNativeRegister: first.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeZeroExtend32From16 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self ZeroExtend16R: value R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeZeroExtend32From8 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| value |
	self allocateRegistersForLowcodeInteger: [:valueValue |
		value := valueValue.
	].

	self ssNativeTop nativePopToReg: value.
	self ssNativePop: 1.

	self ZeroExtend8R: value R: value.
	self ssPushNativeRegister: value.

	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeZeroExtend64From16 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self ZeroExtend16R: valueLow R: valueLow.
		self MoveCq: 0 R: valueHigh.
		self ssPushNativeRegister: valueLow secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger: [:valueValue |
			value := valueValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self ZeroExtend16R: value R: value.
		self ssPushNativeRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeZeroExtend64From32 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| resultLow resultHigh value result |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeIntegerResultInteger2: [:valueValue :resultLowValue :resultHighValue |
			value := valueValue.
			resultLow := resultLowValue.
			resultHigh := resultHighValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self MoveR: value R: resultLow.
		self MoveCq: 0 R: resultHigh.
		self ssPushNativeRegister: resultLow secondRegister: resultHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeIntegerResultInteger: [:valueValue :resultValue |
			value := valueValue.
			result := resultValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self ZeroExtend32R: value R: value.
		self ssPushNativeRegister: value.

	].
	^ 0


]

{ #category : #'inline primitive generators generated code' }
StackToRegisterMappingCogit >> genLowcodeZeroExtend64From8 [
	<option: #LowcodeVM>
	<inline: true>
	"Generated by the Lowcode instruction generator."
	| valueHigh value valueLow |
	BytesPerWord = 4 ifTrue: [
		self allocateRegistersForLowcodeInteger2: [:valueLowValue :valueHighValue |
			valueLow := valueLowValue.
			valueHigh := valueHighValue.
		].

		self ssNativeTop nativePopToReg: valueLow secondReg: valueHigh.
		self ssNativePop: 1.

		self ZeroExtend8R: valueLow R: valueLow.
		self MoveCq: 0 R: valueHigh.
		self ssPushNativeRegister: valueLow secondRegister: valueHigh.

	] ifFalse: [
		self allocateRegistersForLowcodeInteger: [:valueValue |
			value := valueValue.
		].

		self ssNativeTop nativePopToReg: value.
		self ssNativePop: 1.

		self ZeroExtend8R: value R: value.
		self ssPushNativeRegister: value.

	].
	^ 0


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
	 and: [annotation
			between: IsDirectedSuperSend
			and: IsDirectedSuperBindingSend]) ifTrue:
		[self genMoveConstant: tempOop R: TempReg].
	self genLoadInlineCacheWithSelector: selectorIndex.
	(self Call: (sendTable at: (numArgs min: NumSendTrampolines - 1))) annotation: annotation.
	self voidReceiverOptStatus.
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

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genOutlineClosure: startpc numArgs: numArgs numCopied: numCopied [
	<inline: true>
	numCopied > 0 ifTrue:
		[self ssFlushTo: simStackPtr].
	self voidReceiverResultRegContainsSelf.
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
	^methodOrBlockNumArgs <= self numRegArgs
		ifTrue: [self RetN: 0]
		ifFalse: [super genPrimReturn]
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
	self voidReceiverResultRegContainsSelf.
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
	self voidReceiverResultRegContainsSelf.
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
StackToRegisterMappingCogit >> genPushLiteralIndex: literalIndex [ "<SmallInteger>"
	"Override to avoid the BytecodeSetHasDirectedSuperSend check, which is unnecessary
	 here given the simulation stack."
	<inline: false>
	| literal |
	literal := self getLiteral: literalIndex.
	^self genPushLiteral: literal
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> genPushLiteralVariable: literalIndex [
	<inline: false>
	| association freeReg |
	association := self getLiteral: literalIndex.
	"If followed by a directed super send bytecode, avoid generating any code yet.
	 The association will be passed to the directed send trampoline in a register
	 and fully dereferenced only when first linked.  It will be ignored in later sends."
	BytecodeSetHasDirectedSuperSend ifTrue:
		[self deny: directedSendUsesBinding.
		 self nextDescriptorExtensionsAndNextPCInto:
			[:descriptor :exta :extb :followingPC|
			(self isDirectedSuper: descriptor extA: exta extB: extb) ifTrue:
				[self ssPushConstant: association.
				 directedSendUsesBinding := true.
				 ^0]]].
	freeReg := self allocateRegNotConflictingWith: 0.
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
		self voidReceiverResultRegContainsSelf].
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
	self voidReceiverResultRegContainsSelf.
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
	self receiverIsInReceiverResultReg ifTrue:
		[^self ssPushRegister: ReceiverResultReg].
	^self ssPushDesc: self ssSelfDescriptor
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
	TempVectReadBarrier
		ifTrue: [objectRepresentation
				genEnsureObjInRegNotForwarded: tempVectReg
				scratchReg: TempReg].
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
	self assert: (inBlock > 0 or: [needsFrame or: [index < methodOrBlockNumArgs]]).
	^self ssPushDesc: (simStack at: index + 1)
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genReturnReceiver [
	"In a frameless method ReceiverResultReg already contains self.
	 In a frameful method, ReceiverResultReg /may/ contain self."
	needsFrame ifTrue:
		[self receiverIsInReceiverResultReg ifFalse:
			[self putSelfInReceiverResultReg]].
	^self genUpArrowReturn
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genReturnTopFromBlock [
	self assert: inBlock > 0.
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
	| result |
	self assert: self ssTop type = SSConstant.
	tempOop := self ssTop constant.
	self ssPop: 1.
	self marshallSendArguments: numArgs.
	result := self
				genMarshalledSend: selectorIndex
				numArgs: numArgs
				sendTable: (directedSendUsesBinding
								ifTrue: [directedSuperBindingSendTrampolines]
								ifFalse: [directedSuperSendTrampolines]).
	directedSendUsesBinding := false.
	^result
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
StackToRegisterMappingCogit >> genSistaExtStoreAndPopReceiverVariableBytecodePopBoolean: popBoolean [
	<inline: true>
	| index needsStoreCheck needsImmCheck maybeContext result |
	needsStoreCheck := self sistaNeedsStoreCheck.
	needsImmCheck := self extBSpecifiesImmCheck.
	"Long form and short form exist for popInto. Only the long form exists for store.
	Store have an explicit flag to mark context accessing, while popInto context accessing are done through the long form,
	hence generate the context form if the flag is set or if this is a popInto."
	maybeContext := popBoolean or: [self extBSpecifiesMaybeContext].
	extB := 0.
	numExtB := 0.
	index := byte1 + (extA << 8).
	extA := 0.
	result := ((coInterpreter isWriteMediatedContextInstVarIndex: index) and: [maybeContext])
		ifTrue: [self 
				genStorePop: popBoolean 
				MaybeContextReceiverVariable: index 
				needsStoreCheck: needsStoreCheck 
				needsImmutabilityCheck: needsImmCheck]
		ifFalse: [self 
				 genStorePop: popBoolean 
				 ReceiverVariable: index 
				 needsStoreCheck: needsStoreCheck 
				 needsImmutabilityCheck: needsImmCheck].
	self cppIf: IMMUTABILITY ifTrue: [ needsImmCheck ifFalse: [self annotateBytecode: self Label ] ].
	^result
]

{ #category : #'bytecode generators' }
StackToRegisterMappingCogit >> genSistaExtStoreLiteralVariableBytecodePopBoolean: boolean [
	<inline: true>
	| index needsStoreCheck needsImmCheck |
	needsStoreCheck := self sistaNeedsStoreCheck.
	needsImmCheck := self extBSpecifiesImmCheck.
	index := byte1 + (extA << 8).
	extA := numExtB := extB := 0.
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

	argIsInt := ((argIsConst := self ssTop type = SSConstant)
				 and: [objectMemory isIntegerObject: (argInt := self ssTop constant)])
				 or: [self mclassIsSmallInteger and: [self ssTop isSameEntryAs: self simSelf]].

	rcvrIsInt := ((rcvrIsConst := (self ssValue: 1) type = SSConstant)
				  and: [objectMemory isIntegerObject: (rcvrInt := (self ssValue: 1) constant)])
				or: [self mclassIsSmallInteger and: [(self ssValue: 1) isSameEntryAs: self simSelf]].

	(argIsInt and: [argIsConst and: [rcvrIsInt and: [rcvrIsConst]]]) ifTrue:
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

	argIsConst
		ifTrue:
			[self ssFlushTo: simStackPtr - 2.
			 (self ssValue: 1) popToReg: ReceiverResultReg.
			 self ssPop: 2]
		ifFalse:
			[self marshallSendArguments: 1].
	jumpNotSmallInts := (rcvrIsInt and: [argIsInt]) ifFalse:
							[argIsInt
								ifTrue: [objectRepresentation genJumpNotSmallInteger: ReceiverResultReg]
								ifFalse:
									[rcvrIsInt
										ifTrue: [objectRepresentation genJumpNotSmallInteger: Arg0Reg]
										ifFalse: [objectRepresentation genJumpNotSmallIntegersIn: ReceiverResultReg and: Arg0Reg scratch: TempReg]]].
	primDescriptor opcode caseOf: {
		[AddRR] -> [argIsConst
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
							 (rcvrIsInt and: [rcvrIsConst])
								ifTrue: [self MoveCq: rcvrInt R: ReceiverResultReg]
								ifFalse:
									[self SubR: Arg0Reg R: ReceiverResultReg.
									 objectRepresentation genSetSmallIntegerTagsIn: ReceiverResultReg]]].
		[SubRR] -> [argIsConst
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
		[AndRR] -> [argIsConst
						ifTrue: [self AndCq: argInt R: ReceiverResultReg]
						ifFalse: [self AndR: Arg0Reg R: ReceiverResultReg].
					jumpContinue := jumpNotSmallInts ifNotNil: [self Jump: 0]].
		[OrRR]	-> [argIsConst
						ifTrue: [self OrCq: argInt R: ReceiverResultReg]
						ifFalse: [self OrR: Arg0Reg R: ReceiverResultReg].
					jumpContinue := jumpNotSmallInts ifNotNil: [self Jump: 0]] }.
	jumpNotSmallInts
		ifNil: [jumpContinue ifNil: "overflow cannot happen"
				[self annotateInstructionForBytecode.
				 self ssPushRegister: ReceiverResultReg.
				 ^0]]
		ifNotNil:
			[jumpNotSmallInts jmpTarget: self Label].
	argIsConst ifTrue:
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
	| nextPC postBranchPC targetPC primDescriptor branchDescriptor
	  rcvrIsInt rcvrIsConst argIsIntConst argInt jumpNotSmallInts inlineCAB index |
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpNotSmallInts type: #'AbstractInstruction *'>
	self ssFlushTo: simStackPtr - 2.
	primDescriptor := self generatorAt: byte0.
	argIsIntConst := self ssTop type = SSConstant
				 and: [objectMemory isIntegerObject: (argInt := self ssTop constant)].
	rcvrIsInt := ((rcvrIsConst := (self ssValue: 1) type = SSConstant)
				  and: [objectMemory isIntegerObject: (self ssValue: 1) constant])
				or: [self mclassIsSmallInteger and: [(self ssValue: 1) isSameEntryAs: self simSelf]].

	(argIsIntConst and: [rcvrIsInt and: [rcvrIsConst]]) ifTrue:
		[^ self genStaticallyResolvedSpecialSelectorComparison].

	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetPC := target ].

	"Only interested in inlining if followed by a conditional branch."
	inlineCAB := branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse].
	"Further, only interested in inlining = and ~= if there's a SmallInteger constant involved.
	 The relational operators successfully statically predict SmallIntegers; the equality operators do not."
	(inlineCAB and: [primDescriptor opcode = JumpZero or: [primDescriptor opcode = JumpNonZero]]) ifTrue:
		[inlineCAB := argIsIntConst or: [rcvrIsInt]].
	inlineCAB ifFalse:
		[^self genSpecialSelectorSend].

	argIsIntConst
		ifTrue:
			[(self ssValue: 1) popToReg: ReceiverResultReg.
			 self ssPop: 2]
		ifFalse:
			[self marshallSendArguments: 1].
	jumpNotSmallInts := (rcvrIsInt and: [argIsIntConst]) ifFalse:
							[argIsIntConst
								ifTrue: [objectRepresentation genJumpNotSmallInteger: ReceiverResultReg]
								ifFalse:
									[rcvrIsInt
										ifTrue: [objectRepresentation genJumpNotSmallInteger: Arg0Reg]
										ifFalse: [objectRepresentation genJumpNotSmallIntegersIn: ReceiverResultReg and: Arg0Reg scratch: TempReg]]].
	argIsIntConst
		ifTrue: [self CmpCq: argInt R: ReceiverResultReg]
		ifFalse: [self CmpR: Arg0Reg R: ReceiverResultReg].
	"Cmp is weird/backwards so invert the comparison.  Further since there is a following conditional
	 jump bytecode define non-merge fixups and leave the cond bytecode to set the mergeness."
	self genConditionalBranch: (branchDescriptor isBranchTrue
				ifTrue: [primDescriptor opcode]
				ifFalse: [self inverseBranchFor: primDescriptor opcode])
		operand: (self ensureNonMergeFixupAt: targetPC) asUnsignedInteger.
	self Jump: (self ensureNonMergeFixupAt: postBranchPC).
	jumpNotSmallInts ifNil:
		[self annotateInstructionForBytecode.
		 self ensureFixupAt: postBranchPC.
		 self ensureFixupAt: targetPC.
		 deadCode := true.
		 ^0].
	jumpNotSmallInts jmpTarget: self Label.
	argIsIntConst ifTrue:
		[self MoveCq: argInt R: Arg0Reg].
	index := byte0 - self firstSpecialSelectorBytecodeOffset.
	^self genMarshalledSend: index negated - 1 numArgs: 1 sendTable: ordinarySendTrampolines
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
	self voidReceiverResultRegContainsSelf.
	self MoveMw: (self frameOffsetOfTemporary: remoteTempIndex) r: FPReg R: ReceiverResultReg.
	TempVectReadBarrier
		ifTrue: [objectRepresentation
				genEnsureObjInRegNotForwarded: ReceiverResultReg
				scratchReg: TempReg].
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
	(self simStackAt: tempIndex + 1) bcptr: bytecodePC. "for debugging"
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
	deadCode := true. "can't fall through"
	inBlock > 0 ifTrue:
		[self assert: needsFrame.
		 self ssFlushTo: simStackPtr.
		 self CallRT: ceNonLocalReturnTrampoline.
		 self annotateBytecode: self Label.
		 ^0].
	(self cppIf: IMMUTABILITY ifTrue: [needsFrame and: [useTwoPaths not]] ifFalse: [needsFrame])
		ifTrue:
			[LowcodeVM ifTrue: [ hasNativeFrame ifTrue: [ self leaveNativeFrame ] ].
			 self MoveR: FPReg R: SPReg.
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
StackToRegisterMappingCogit >> genVanillaInlinedIdenticalOrNotIf: orNot [
	| nextPC postBranchPC targetPC branchDescriptor
	  rcvrReg argReg argIsConstant rcvrIsConstant  |
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	
	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetPC := target ].
	
	argIsConstant := self ssTop type = SSConstant.
	"They can't be both constants to use correct machine opcodes.
	 However annotable constants can't be resolved statically, hence we need to careful."
	rcvrIsConstant := argIsConstant not and: [(self ssValue: 1) type = SSConstant].
	
	self 
		allocateEqualsEqualsRegistersArgNeedsReg: argIsConstant not 
		rcvrNeedsReg: rcvrIsConstant not 
		into: [ :rcvr :arg | rcvrReg:= rcvr. argReg := arg ].
	
	"If not followed by a branch, resolve to true or false."
	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse]) ifFalse:
		[^ self 
			genIdenticalNoBranchArgIsConstant: argIsConstant 
			rcvrIsConstant: rcvrIsConstant 
			argReg: argReg 
			rcvrReg: rcvrReg 
			orNotIf: orNot].
	
	"If branching the stack must be flushed for the merge"
	self ssFlushTo: simStackPtr - 2.
	
	self genCmpArgIsConstant: argIsConstant rcvrIsConstant: rcvrIsConstant argReg: argReg rcvrReg: rcvrReg.
	self ssPop: 2.

	"Further since there is a following conditional jump bytecode, define
	 non-merge fixups and leave the cond bytecode to set the mergeness."
	(self fixupAt: nextPC) notAFixup
		ifTrue: "The next instruction is dead.  we can skip it."
			[deadCode := true.
		 	 self ensureFixupAt: targetPC.
			 self ensureFixupAt: postBranchPC]
		ifFalse:
			[self deny: deadCode]. "push dummy value below"
		

	orNot == branchDescriptor isBranchTrue "orNot is true for ~~"
		ifFalse: "a == b ifTrue: ... or a ~~ b ifFalse: ... jump on equal to target pc"
			[self JumpZero:  (self ensureNonMergeFixupAt: targetPC).
			 self Jump: (self ensureNonMergeFixupAt: postBranchPC)]
		ifTrue: "a == b ifFalse: ... or a ~~ b ifTrue: ... jump on equal to post-branch pc"
			[self ensureNonMergeFixupAt: targetPC.
			 self JumpZero: (self ensureNonMergeFixupAt: postBranchPC).
			 self Jump: (self ensureNonMergeFixupAt: targetPC)].

	"Not reached, execution flow has jumped to fixup"
	deadCode ifFalse:
		[self ssPushConstant: objectMemory trueObject]. "dummy value"
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

{ #category : #'generate machine code' }
StackToRegisterMappingCogit >> generateInstructionsAt: eventualAbsoluteAddress [
	"Size pc-dependent instructions and assign eventual addresses to all instructions.
	 Answer the size of the code.
	 Compute forward branches based on virtual address (abstract code starts at 0),
	 assuming that any branches branched over are long.
	 Compute backward branches based on actual address.
	 Reuse the fixups array to record the pc-dependent instructions that need to have
	 their code generation postponed until after the others.

	 Override to andd handling for null branches (branches to the immediately following
	 instruction) occasioned by StackToRegisterMapping's following of jumps."
	| absoluteAddress pcDependentIndex abstractInstruction fixup |
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	<var: #fixup type: #'BytecodeFixup *'>
	absoluteAddress := eventualAbsoluteAddress.
	pcDependentIndex := 0.
	0 to: opcodeIndex - 1 do:
		[:i|
		self maybeBreakGeneratingAt: absoluteAddress.
		abstractInstruction := self abstractInstructionAt: i.
		abstractInstruction isPCDependent
			ifTrue:
				[abstractInstruction sizePCDependentInstructionAt: absoluteAddress.
				 (abstractInstruction isJump
				  and: [(i + 1 < opcodeIndex
				  		and: [abstractInstruction getJmpTarget == (self abstractInstructionAt: i + 1)])
					or: [i + 2 < opcodeIndex
						and: [abstractInstruction getJmpTarget == (self abstractInstructionAt: i + 2)
						and: [(self abstractInstructionAt: i + 1) opcode = Nop]]]])
					ifTrue:
						[abstractInstruction
							opcode: Nop;
							concretizeAt: absoluteAddress]
					ifFalse:
						[fixup := self fixupAtIndex: pcDependentIndex.
						 pcDependentIndex := pcDependentIndex + 1.
						 fixup instructionIndex: i].
				 absoluteAddress := absoluteAddress + abstractInstruction machineCodeSize]
			ifFalse:
				[absoluteAddress := abstractInstruction concretizeAt: absoluteAddress]].
	0 to: pcDependentIndex - 1 do:
		[:j|
		fixup := self fixupAtIndex: j.
		abstractInstruction := self abstractInstructionAt: fixup instructionIndex.
		self maybeBreakGeneratingAt: abstractInstruction address.
		abstractInstruction concretizeAt: abstractInstruction address].
	^absoluteAddress - eventualAbsoluteAddress
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
			put: (self genPICMissTrampolineFor: numArgs)].
	ceReapAndResetErrorCodeTrampoline := self genTrampolineFor: #ceReapAndResetErrorCodeFor:
												called: 'ceReapAndResetErrorCodeTrampoline'
												arg: ClassReg
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
						  arg: (self numArgsOrSendNumArgsReg: numArgs)).
			directedSuperBindingSendTrampolines
				at: numArgs
				put: (self genSendTrampolineFor: #ceSend:aboveClassBinding:to:numArgs:
						  numArgs: numArgs
						  called: (self trampolineName: 'ceDirectedSuperBindingSend' numArgs: numArgs)
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
StackToRegisterMappingCogit >> generateSistaRuntime [
	"No sita vm"
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
	simStackPtr := methodOrBlockNumTemps. "N.B. Includes num args"
	simSpillBase := methodOrBlockNumTemps + 1.
	LowcodeVM ifTrue:
		[simNativeSpillBase := simNativeStackPtr := -1.
		 simNativeStackSize := 0].
	self simSelf
		type: SSBaseOffset;
		spilled: true;
		register: FPReg;
		offset: FoxMFReceiver;
		liveRegister: NoReg.
	"args"
	1 to: methodOrBlockNumArgs do:
		[:i| | desc |
		desc := self simStackAt: i.
		desc
			type: SSBaseOffset;
			spilled: true;
			register: FPReg;
			offset: FoxCallerSavedIP + ((methodOrBlockNumArgs - i + 1) * objectMemory wordSize);
			bcptr: startpc].
	"temps"
	methodOrBlockNumArgs + 1 to: simStackPtr do:
		[:i| | desc |
		desc := self simStackAt: i.
		desc
			type: SSBaseOffset;
			spilled: true;
			register: FPReg;
			offset: FoxMFReceiver - (i - methodOrBlockNumArgs * objectMemory wordSize);
			bcptr: startpc]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> initSimStackForFramelessBlock: startpc [
	"The register receiver (the closure itself) and args are pushed by the closure value primitive(s)
	 and hence a frameless block has all arguments and copied values pushed to the stack.  However,
	 the method receiver (self) is put in the ReceiverResultReg by the block entry."
	<var: #desc type: #'CogSimStackEntry *'>
	self simSelf
		type: SSRegister;
		spilled: false;
		register: ReceiverResultReg;
		liveRegister: ReceiverResultReg.
	self assert: methodOrBlockNumTemps >= methodOrBlockNumArgs.
	1 to: methodOrBlockNumTemps do:
		[:i| | desc |
		desc := self simStackAt: i.
		desc
			type: SSBaseOffset;
			spilled: true;
			register: SPReg;
			offset: ((backEnd hasLinkRegister
								ifTrue: [methodOrBlockNumArgs - i]
								ifFalse: [methodOrBlockNumArgs + 1 - i]) * objectMemory wordSize);
			bcptr: startpc].
	simStackPtr := methodOrBlockNumTemps. "N.B. Includes num args"
	simSpillBase := methodOrBlockNumTemps + 1.
	LowcodeVM ifTrue:
		[simNativeSpillBase := simNativeStackPtr := -1.
		 simNativeStackSize := 0]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> initSimStackForFramelessMethod: startpc [
	| desc |
	<var: #desc type: #'CogSimStackEntry *'>
	self simSelf
		type: SSRegister;
		spilled: false;
		register: ReceiverResultReg;
		liveRegister: ReceiverResultReg.
	self assert: methodOrBlockNumTemps = methodOrBlockNumArgs.
	self assert: self numRegArgs <= 2.
	(methodOrBlockNumArgs between: 1 and: self numRegArgs)
		ifTrue:
			[desc := self simStackAt: 1.
			 desc
				type: SSRegister;
				spilled: false;
				register: Arg0Reg;
				bcptr: startpc.
			 methodOrBlockNumArgs > 1 ifTrue:
				[desc := self simStackAt: 2.
				 desc
					type: SSRegister;
					spilled: false;
					register: Arg1Reg;
					bcptr: startpc]]
		ifFalse:
			[1 to: methodOrBlockNumArgs do:
				[:i|
				desc := self simStackAt: i.
				desc
					type: SSBaseOffset;
					register: SPReg;
					spilled: true;
					offset: ((backEnd hasLinkRegister
								ifTrue: [methodOrBlockNumArgs - i]
								ifFalse: [methodOrBlockNumArgs + 1 - i]) * objectMemory wordSize);
					bcptr: startpc]].
	simStackPtr := methodOrBlockNumArgs.
	simSpillBase := methodOrBlockNumArgs + 1.
	LowcodeVM ifTrue:
		[simNativeSpillBase := simNativeStackPtr := -1.
		 simNativeStackSize := 0]
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> initializeFixup: fixup [
	"Initialize a fixup.  These are the targets of backward branches.  A backward branch fixup's
	 simStackPtr needs to be set when generating the code for the bytecode at the targetPC.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction."
	<var: #fixup type: #'BytecodeFixup *'>
	<inline: true>
	fixup
		becomeMergeFixup;
		setIsBackwardBranchFixup
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> initializeFixupAt: targetPC [
	"Make sure there's a flagged fixup at the targetPC in fixups.
	 These are the targets of backward branches.  A backward branch fixup's simStackPtr
	 needs to be set when generating the code for the bytecode at the targetPC.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction."
	<inline: true>
	| fixup |
	fixup := self fixupAt: targetPC.
	self initializeFixup: fixup
]

{ #category : #'inline primitive register allocation' }
StackToRegisterMappingCogit >> isOopRegister: register usedBefore: stackIndex [
	<option: #LowcodeVM>
	<inline: true>
	| index |
	index := simSpillBase max: 0.
	index to: simStackPtr - stackIndex do: [ :i |
		(self simStackAt: index) registerOrNone = register ifTrue: [ 
			^ true
		]
	].

	^ false
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
StackToRegisterMappingCogit >> leaveNativeFrame [
	<option: #LowcodeVM>
	self assert: needsFrame.
	self MoveMw: self frameOffsetOfPreviousNativeStackPointer r: FPReg R: TempReg.
	self SubCq: 1 R: TempReg.
	self MoveR: TempReg Aw: coInterpreter nativeStackPointerAddress
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> liveFloatRegisters [
	| regsSet |
	regsSet := 0.
	(simSpillBase max: 0) to: simStackPtr do:
		[:i|
		regsSet := regsSet bitOr: (self simStackAt: i) floatRegisterMask].
	LowcodeVM ifTrue: [ 
		(simNativeSpillBase max: 0) to: simNativeStackPtr do:
			[:i|
			regsSet := regsSet bitOr: (self simNativeStackAt: i) nativeFloatRegisterMask].
	].
	^regsSet
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
	LowcodeVM ifTrue: [ 
		(simNativeSpillBase max: 0) to: simNativeStackPtr do:
			[:i|
			regsSet := regsSet bitOr: (self simNativeStackAt: i) nativeRegisterMask].
	].
	^regsSet
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> mapDeadDescriptorIfNeeded: descriptor [ 
	"insert nops for dead code that is mapped so that bc 
	 to mc mapping is not many to one"
	<var: #descriptor type: #'BytecodeDescriptor *'>
	self flag: #annotateInstruction .
	(descriptor isMapped
		or: [inBlock > 0 and: [descriptor isMappedInBlock]]) 
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

{ #category : #debugging }
StackToRegisterMappingCogit >> maybeCompilingFirstPassOfBlockWithInitialPushNil [
	"For assert checking; or rather for avoiding assert fails when dealing with the hack for block temps in the SqueakV3PlusClosures bytecode set."
	^inBlock = InVanillaBlock and: [methodOrBlockNumTemps > methodOrBlockNumArgs and: [compilationPass = 1]]
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> maybeCountCounter [
	"This is a hook for SistaCogit"
	<inline: true>
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> maybeCountFixup: descriptor [
	"This is a hook for RegisterAllocatingCogit"
	<inline: true>
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> maybeCounterIndex [
	"Hook for SistaCogit to allow it to reuse compileBlockBodies"
	<inline: true>
	^0
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

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> maybeSetCounterIndex: value [
	"Hook for SistaCogit to allow it to reuse compileBlockBodies"
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

	self assertCorrectSimStackPtr.

	"case 1"
	fixup notAFixup ifTrue:
		[^0].

	"case 2"
	fixup isNonMergeFixup ifTrue:
		[deadCode := false. ^0].

	"cases 3 and 4"
	self assert: fixup isMergeFixup.
	self traceMerge: fixup.
	deadCode
		ifTrue: "case 3"
			["Would like to assert fixup simStackPtr >= methodOrBlockNumTemps
			   but can't because of the initialNils hack."
			 self assert: (fixup simStackPtr >= methodOrBlockNumTemps
						or: [self maybeCompilingFirstPassOfBlockWithInitialPushNil]).
			 simStackPtr := fixup simStackPtr.
			 LowcodeVM ifTrue:
				[simNativeStackPtr := fixup simNativeStackPtr.
				simNativeStackSize := fixup simNativeStackSize]]
		ifFalse: "case 4"
			[self ssFlushTo: simStackPtr].

	"cases 3 and 4"
	deadCode := false.
	fixup isBackwardBranchFixup ifTrue:
		[fixup simStackPtr: simStackPtr.
		LowcodeVM ifTrue:
			[fixup simNativeStackPtr: simNativeStackPtr.
			 fixup simNativeStackSize: simNativeStackSize]].
	fixup targetInstruction: self Label.
	self assert: simStackPtr = fixup simStackPtr.
	LowcodeVM ifTrue:
		[self assert: simNativeStackPtr = fixup simNativeStackPtr.
		 self assert: simNativeStackSize = fixup simNativeStackSize].

	self cCode: '' inSmalltalk:
		[self assert: fixup simStackPtr = (self debugStackPointerFor: bytecodePC)].
	self restoreSimStackAtMergePoint: fixup.

	^0
]

{ #category : #trampolines }
StackToRegisterMappingCogit >> methodAbortTrampolineFor: numArgs [
	^methodAbortTrampolines at: (numArgs min: self numRegArgs + 1)
]

{ #category : #testing }
StackToRegisterMappingCogit >> methodFoundInvalidPostScan [
	"Frameless methods with local temporaries cause problems,
	 mostly in asserts, and yet they matter not at all for performance.
	 Shun them."
	needsFrame ifFalse:
		[^methodOrBlockNumTemps > methodOrBlockNumArgs].
	^super methodFoundInvalidPostScan
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

{ #category : #'debug printing' }
StackToRegisterMappingCogit >> printRegisterMask: registerMask [
	<doNotGenerate>
	^String streamContents: [:s| self printRegisterMask: registerMask on: s]
]

{ #category : #'debug printing' }
StackToRegisterMappingCogit >> printRegisterMask: registerMask on: aStream [
	<doNotGenerate>
	| first |
	aStream nextPut: ${.
	registerMask = 0
		ifTrue:
			[aStream nextPutAll: 'NoReg']
		ifFalse:
			[first := true.
			 0 to: 31 do:
				[:reg|
				(registerMask anyMask: 1 << reg) ifTrue:
					[first ifFalse: [aStream space].
					 first := false.
					 aStream nextPutAll: (backEnd nameForRegister: reg)]]].
	aStream nextPut: $}; flush
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> printSimStack [
	<doNotGenerate>
	self printSimStack: simStack toDepth: simStackPtr spillBase: simSpillBase on: coInterpreter transcript
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> printSimStack: aSimStackOrFixup [
	<doNotGenerate>
	(aSimStackOrFixup isKindOf: CogRASSBytecodeFixup)
		ifTrue:
			[self printSimStack: aSimStackOrFixup mergeSimStack toDepth: aSimStackOrFixup simStackPtr spillBase: -1 on: coInterpreter transcript]
		ifFalse:
			[self printSimStack: aSimStackOrFixup toDepth: simStackPtr spillBase: simSpillBase on: coInterpreter transcript]
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> printSimStack: aSimStack toDepth: limit spillBase: spillBase on: aStream [
	<doNotGenerate>
	| tempNames width tabWidth |
	aStream ensureCr.
	limit < 0 ifTrue:
		[^aStream nextPutAll: 'simStackEmpty'; cr; flush].
	aSimStack ifNil:
		[^aStream nextPutAll: 'nil simStack'; cr; flush].
	(self class initializationOptions at: #tempNames ifAbsent: nil) ifNotNil:
		[:tempNamesDictOrNil |	 | tab longest |
		 tempNames := tempNamesDictOrNil at: (self class initializationOptions at: #startpc ifAbsent: [initialPC]) + 1.
		 longest := tempNames inject: '' into: [:m :t| m size >= t size ifTrue: [m] ifFalse: [t]].
		 tabWidth := self widthInDefaultFontOf: (tab := String with: Character tab).
		 width := self widthInDefaultFontOf: longest, tab.
		 width <= ((self widthInDefaultFontOf: longest, (String with: Character space)) + 4) ifTrue:
			[width := width + tabWidth]].
	0 to: limit do:
		[:i|
		width ifNotNil:
			[self put: (tempNames at: i ifAbsent: [i = 0 ifTrue: ['self'] ifFalse: ['']]) paddedTo: width tabWidth: tabWidth on: aStream].
		aStream print: i.
		i = simStackPtr ifTrue:
			[aStream nextPutAll: '<-' ].
		i = spillBase ifTrue:
			[aStream nextPutAll: '(sb)'].
		aStream tab: (i = spillBase ifTrue: [1] ifFalse: [2]).
		(aSimStack at: i) printStateOn: aStream.
		aStream cr; flush].
	simSpillBase > limit ifTrue:
		[aStream nextPutAll: '(sb: '; print: simSpillBase; nextPut: $); cr; flush]
]

{ #category : #'span functions' }
StackToRegisterMappingCogit >> pushNilSize: aMethodObj numInitialNils: numInitialNils [
	<inline: true>
	^self perform: pushNilSizeFunction with: aMethodObj with: numInitialNils
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> put: aString paddedTo: compositionWidth tabWidth: tabWidth on: aStream [
	<doNotGenerate>
	| fittedString size width |
	fittedString := aString.
	size := fittedString size.
	[(width := self widthInDefaultFontOf: fittedString) > compositionWidth] whileTrue:
		[size := size - 2.
		 fittedString := aString contractTo: size].
	aStream
		nextPutAll: fittedString;
		tab: compositionWidth - width + (width \\ tabWidth) // tabWidth + 1
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> putSelfInReceiverResultReg [
	<inline: true>
	 self simSelf storeToReg: ReceiverResultReg
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> receiverIsInReceiverResultReg [
	"Used to mark ReceiverResultReg as dead or not containing simSelf.
	 Used when the simStack has already been flushed, e.g. for sends."
	<inline: true>
	^self simSelf liveRegister = ReceiverResultReg
]

{ #category : #accessing }
StackToRegisterMappingCogit >> regArgsHaveBeenPushed: aBoolean [
	regArgsHaveBeenPushed := aBoolean
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
		[(self fixupAt: pc) reinitialize.
		 byte0 := (objectMemory fetchByte: pc ofObject: methodObj) + bytecodeSetOffset.
		 descriptor := self generatorAt: byte0.
		 (descriptor isBranch
		  and: [self isBackwardBranch: descriptor at: pc exts: nExts in: methodObj]) ifTrue:
			[distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 self initializeFixupAt: targetPC].
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
	"All the execution paths reaching a merge point expect everything
	 to be spilled on stack. Throw away all simStack optimization state."
	self voidReceiverOptStatus.
	methodOrBlockNumTemps + 1 to: simStackPtr do:
		[:i|
		 (self simStackAt: i)
			type: SSSpill;
			offset: FoxMFReceiver - (i - methodOrBlockNumArgs * objectMemory bytesPerOop);
			register: FPReg;
			spilled: true].
	simSpillBase := simStackPtr + 1.
	LowcodeVM ifTrue:
		[0 to: simNativeStackPtr do:
			[ :i |
			(self simNativeStackAt: i)
				ensureIsMarkedAsSpilled].
		simNativeSpillBase := simNativeStackPtr + 1].
	^ 0
]

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogit >> scanBlock: blockStart [
	"Scan the block to determine if the block needs a frame or not"
	| descriptor pc end framelessStackDelta nExts pushingNils numPushNils |
	<var: #blockStart type: #'BlockStart *'>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	needsFrame := false.
	LowcodeVM ifTrue: [ hasNativeFrame := false ].
	prevBCDescriptor := nil.
	methodOrBlockNumArgs := blockStart numArgs.
	inBlock := InVanillaBlock.
	pc := blockStart startpc.
	end := blockStart startpc + blockStart span.
	framelessStackDelta := nExts := extA := numExtB := extB := 0.
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
					[self assert: descriptor numBytes = 1.
					 blockStart numInitialNils: blockStart numInitialNils + numPushNils]
				ifFalse:
					[pushingNils := false]].
		 pc := self nextBytecodePCFor: descriptor at: pc exts: nExts in: methodObj.
		 descriptor isExtension
			ifTrue: [nExts := nExts + 1]
			ifFalse: [nExts := extA := numExtB := extB := 0].
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
	LowcodeVM ifTrue: [ hasNativeFrame := false ].
	self maybeInitNumFixups.
	self maybeInitNumCounters.
	prevBCDescriptor := nil.
	(primitiveIndex > 0
	 and: [coInterpreter isQuickPrimitiveIndex: primitiveIndex]) ifTrue:
		[^0].
	pc := latestContinuation := initialPC.
	numBlocks := framelessStackDelta := nExts := extA := numExtB := extB := 0.
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
			 self maybeCountFixup: descriptor.
			 (self isBackwardBranch: descriptor at: pc exts: nExts in: methodObj)
				ifTrue: [self initializeFixupAt: targetPC]
				ifFalse:
					[latestContinuation := latestContinuation max: targetPC.
					 self maybeCountCounter]].
			
		 latestContinuation := self 
			maybeDealWithUnsafeJumpForDescriptor: descriptor 
			pc: pc 
			latestContinuation: latestContinuation.
		
		 descriptor isBlockCreation ifTrue:
			[numBlocks := numBlocks + 1.
			 distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 latestContinuation := latestContinuation max: targetPC.
			 self maybeCountFixup: descriptor].

		 pc := pc + descriptor numBytes.
		 nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [extA := numExtB := extB := 0].
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
	simNativeStack := CArrayAccessor on: ((1 to: self class simNativeStackSlots) collect: [:i| self simStackNativeEntryClass new cogit: self]).

	debugFixupBreaks := self class initializationOptions at: #debugFixupBreaks ifAbsent: [Set new].

	numPushNilsFunction := self class numPushNilsFunction.
	pushNilSizeFunction := self class pushNilSizeFunction
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> simNativeStackAt: index [
	<cmacro: '(index) (simNativeStack + (index))'>
	<returnTypeC: #'CogSimStackNativeEntry *'>
	^self addressOf: (simNativeStack at: index)
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> simNativeStackSlots [
	"Answer the number of slots toinclude in a simulated stack.
	 This needs to be big enough to include all slots in a context
	 plus some overflow for safety."
	<inline: true>
	^((LargeContextSlots - CtxtTempFrameStart max: 64) * 11 // 10)
]

{ #category : #accessing }
StackToRegisterMappingCogit >> simSelf [
	<cmacro: '() simStack'>
	<returnTypeC: #'CogSimStackEntry *'>
	^self simStackAt: 0
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

{ #category : #initialization }
StackToRegisterMappingCogit >> simStackNativeEntryClass [
	<doNotGenerate>
	^CogSimStackNativeEntry
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> simStackPrintString [
	<doNotGenerate>
	^String streamContents: [:s| self printSimStack: simStack toDepth: simStackPtr spillBase: simSpillBase on: s]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> simStackSlots [
	"Answer the number of slots to include in a simulated stack.
	 This needs to be big enough to include all stack slots in a context
	 plus a slot for the receiver and some overflow for safety."
	<inline: true>
	^((LargeContextSlots - CtxtTempFrameStart + 1 max: 64) * 11 // 10)
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
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	^descriptor generator == #genPushConstantNilBytecode
		ifTrue: [1]
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
	<inline: true>
	self ssAllocateRequiredRegMask: (CallerSavedRegisterMask
										bitOr: (self registerMaskFor: requiredReg))
		upThrough: simStackPtr
		upThroughNative: simNativeStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateCallReg: requiredReg1 and: requiredReg2 [
	"Allocate registers needed in a run-time call (i.e. flush uses of the
	 registers to the real stack).  Since the run-time can smash any and
	 all caller-saved registers also flush all caller-saved registers."
	<inline: true>
	self ssAllocateRequiredRegMask: (CallerSavedRegisterMask
										bitOr: ((self registerMaskFor: requiredReg1)
										bitOr: (self registerMaskFor: requiredReg2)))
		upThrough: simStackPtr
		upThroughNative: simNativeStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateCallReg: requiredReg1 and: requiredReg2 and: requiredReg3 [
	"Allocate registers needed in a run-time call (i.e. flush uses of the
	 registers to the real stack).  Since the run-time can smash any and
	 all caller-saved registers also flush all caller-saved registers."
	<inline: true>
	self ssAllocateRequiredRegMask: (CallerSavedRegisterMask bitOr:
										(self registerMaskFor: requiredReg1 and: requiredReg2 and: requiredReg3))
		upThrough: simStackPtr
		upThroughNative: simNativeStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateCallReg: requiredReg1 and: requiredReg2 and: requiredReg3 and: requiredReg4 [
	"Allocate registers needed in a run-time call (i.e. flush uses of the
	 registers to the real stack).  Since the run-time can smash any and
	 all caller-saved registers also flush all caller-saved registers."
	<inline: true>
	self ssAllocateRequiredRegMask: (CallerSavedRegisterMask
										bitOr: ((self registerMaskFor: requiredReg1)
										bitOr: ((self registerMaskFor: requiredReg2)
										bitOr: ((self registerMaskFor: requiredReg3)
										bitOr: (self registerMaskFor: requiredReg4)))))
		upThrough: simStackPtr
		upThroughNative: simNativeStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateRequiredFloatReg: requiredReg [
	self ssAllocateRequiredFloatRegMask: (self registerMaskFor: requiredReg)
		upThrough: simStackPtr upThroughNative: simNativeStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateRequiredFloatRegMask: requiredRegsMask upThrough: stackPtr upThroughNative: nativeStackPtr [
	| lastRequired lastRequiredNative liveRegs |
	lastRequired := -1.
	lastRequiredNative := -1.
	"compute live regs while noting the last occurrence of required regs.
	 If these are not free we must spill from simSpillBase to last occurrence.
	 Note we are conservative here; we could allocate FPReg in frameless methods."
	liveRegs := NoReg.
	(simSpillBase max: 0) to: stackPtr do:
		[:i|
		liveRegs := liveRegs bitOr: (self simStackAt: i) registerMask.
		((self simStackAt: i) floatRegisterMask bitAnd: requiredRegsMask) ~= 0 ifTrue:
			[lastRequired := i]].
	self assert: lastRequiredNative = simNativeStackPtr.
	(simNativeSpillBase max: 0) to: nativeStackPtr do:
		[:i|
		liveRegs := liveRegs bitOr: (self simNativeStackAt: i) nativeRegisterMask.
		((self simNativeStackAt: i) floatRegisterMask bitAnd: requiredRegsMask) ~= 0 ifTrue:
			[lastRequiredNative := i]].

	"If any of requiredRegsMask are live we must spill."
	(liveRegs bitAnd: requiredRegsMask) = 0 ifFalse:
		["Some live, must spill"
		self ssFlushTo: lastRequired.
		self assert: (self liveFloatRegisters bitAnd: requiredRegsMask) = 0]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateRequiredReg: requiredReg [
	<inline: true>
	self ssAllocateRequiredRegMask: (self registerMaskFor: requiredReg)
		upThrough: simStackPtr
		upThroughNative: simNativeStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateRequiredReg: requiredReg1 and: requiredReg2 [
	<inline: true>
	self ssAllocateRequiredRegMask: ((self registerMaskFor: requiredReg1)
										bitOr: (self registerMaskFor: requiredReg2))
		upThrough: simStackPtr
		upThroughNative: simNativeStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateRequiredReg: requiredReg upThrough: stackPtr [
	<inline: true>
	self ssAllocateRequiredRegMask: (self registerMaskFor: requiredReg)
		upThrough: stackPtr
		upThroughNative: simNativeStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssAllocateRequiredRegMask: requiredRegsMask upThrough: stackPtr upThroughNative: nativeStackPtr [
	| lastRequired lastRequiredNative liveRegs |
	lastRequired := -1.
	lastRequiredNative := -1.
	"compute live regs while noting the last occurrence of required regs.
	 If these are not free we must spill from simSpillBase to last occurrence.
	 Note we are conservative here; we could allocate FPReg in frameless methods."
	liveRegs := self registerMaskFor: FPReg and: SPReg.
	(simSpillBase max: 0) to: stackPtr do:
		[:i|
		liveRegs := liveRegs bitOr: (self simStackAt: i) registerMask.
		((self simStackAt: i) registerMask anyMask: requiredRegsMask) ifTrue:
			[lastRequired := i]].
	LowcodeVM ifTrue:
		[self assert: nativeStackPtr = simNativeStackPtr.
		 (simNativeSpillBase max: 0) to: nativeStackPtr do:
			[:i|
			liveRegs := liveRegs bitOr: (self simNativeStackAt: i) nativeRegisterMask.
			((self simNativeStackAt: i) nativeRegisterMask anyMask: requiredRegsMask) ifTrue:
				[lastRequiredNative := i]]].
	"If any of requiredRegsMask are live we must spill."
	(liveRegs anyMask: requiredRegsMask) ifTrue:
		[self ssFlushTo: lastRequired.
		 self deny: (self liveRegisters anyMask: requiredRegsMask)]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssFlushAll [
	<inline: true>
	self ssFlushTo: simStackPtr.
	self voidReceiverResultRegContainsSelf.
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssFlushTo: index [
	<inline: true>
	self assert: self tempsValidAndVolatileEntriesSpilled.
	LowcodeVM ifTrue:
		[self ssNativeFlushTo: simNativeStackPtr].
	simSpillBase <= index ifTrue:
		[(((simSpillBase max: methodOrBlockNumTemps + 1) min: simStackPtr) min: index) to: index do:
			[:i|
			self assert: needsFrame.
			(self simStackAt: i)
				ensureSpilledAt: (self frameOffsetOfTemporary: i - 1) "frameOffsetOfTemporary: is 0-relative"
				from: FPReg].
		 simSpillBase := index + 1]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssFlushUpThrough: unaryBlock [
	"Any occurrences on the stack of the value being stored (which is the top of stack)
	 must be flushed, and hence any values colder than them stack."
	<inline: true>
	self assert: simSpillBase >= 0.
	simStackPtr - 1 to: simSpillBase by: -1 do:
		[ :index |
		(unaryBlock value: (self simStackAt: index)) ifTrue: [ ^ self ssFlushTo: index ] ]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssFlushUpThroughReceiverVariable: slotIndex [
	"Any occurrences on the stack of the value being stored (which is the top of stack)
	 must be flushed, and hence any values colder than them stack."
	<var: #desc type: #'CogSimStackEntry *'>
	LowcodeVM ifTrue: [ self ssNativeFlushTo: simNativeStackPtr. ].
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
	LowcodeVM ifTrue: [ self ssNativeFlushTo: simNativeStackPtr ].
	self ssFlushUpThrough: [ :desc | desc type = SSRegister and: [ desc register = reg ] ]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssFlushUpThroughTemporaryVariable: tempIndex [
	"Any occurrences on the stack of the value being stored (which is the top of stack)
	 must be flushed, and hence any values colder than them stack."
	<var: #desc type: #'CogSimStackEntry *'>
	| offset |
	LowcodeVM ifTrue: [ self ssNativeFlushTo: simNativeStackPtr ].
	offset := (self simStackAt: tempIndex + 1) offset.
	self assert: offset = (self frameOffsetOfTemporary: tempIndex).
	self ssFlushUpThrough: 
		[ :desc |
			desc type = SSBaseOffset
		 	and: [desc register = FPReg
		 	and: [desc offset = offset ] ] ]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssNativeFlushTo: index [
	<option: #LowcodeVM>
	| loadedPointer allocatedScratchRegister |
	simNativeSpillBase <= index ifTrue: [
		loadedPointer := false.
		allocatedScratchRegister := false.

		(simNativeSpillBase max: 0) to: index do:  [:i|
			loadedPointer ifFalse: [
				self MoveMw: self frameOffsetOfNativeFramePointer r: FPReg R: TempReg.
				loadedPointer := true.
			].

			((self simNativeStackAt: i) spillingNeedsScratchRegister and: [allocatedScratchRegister not ]) ifTrue: [
				self PushR: FPReg.
				allocatedScratchRegister := true.
			].

			(self simNativeStackAt: i)
				ensureSpilledSP: TempReg scratchRegister: FPReg
		].

		simNativeSpillBase := index + 1.

		allocatedScratchRegister ifTrue: [
			self PopR: FPReg.
		].

		loadedPointer ifTrue: [
			self SubCq: simNativeStackSize R: TempReg.
			self MoveR: TempReg Mw: self frameOffsetOfNativeStackPointer r: FPReg.
		]
	]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssNativePop: n [
	<option: #LowcodeVM>
	self assert: (simNativeStackPtr - n >= -1).
	simNativeStackPtr := simNativeStackPtr - n.
	simNativeStackPtr >= 0 ifTrue: [
		simNativeStackSize := self ssNativeTop offset
	] ifFalse: [
		simNativeStackSize := 0.
	]
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssNativePush: n [ 
	<option: #LowcodeVM>
	simNativeStackPtr := simNativeStackPtr + n
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssNativeTop [
	<option: #LowcodeVM>
	<inline: true>
	<returnTypeC: #'CogSimStackNativeEntry *'>
	self assert: simNativeStackPtr >= 0.
	^self simNativeStackAt: simNativeStackPtr
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssNativeValue: n [
	<returnTypeC: #'CogSimStackNativeEntry *'>
	<option: #LowcodeVM>
	^self simNativeStackAt: simNativeStackPtr - n
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPop: n [
	self assert: (simStackPtr - n >= methodOrBlockNumTemps
				or: [(needsFrame not and: [simStackPtr - n >= 0])
				or: [self maybeCompilingFirstPassOfBlockWithInitialPushNil]]).
	simStackPtr := simStackPtr - n.
	self updateSimSpillBase
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPopNativeSize: popSize [
	<option: #LowcodeVM>
	| poppingSize stackPosition popCount |
	poppingSize := 0.
	stackPosition := simNativeStackPtr.
	[ poppingSize < popSize and: [ stackPosition >= 0 ] ] whileTrue: [
		poppingSize := poppingSize + (self simNativeStackAt: stackPosition) stackSpillSize.
		stackPosition := stackPosition - 1
	].

	self assert: poppingSize = popSize.
	popCount := simNativeStackPtr - stackPosition.
	self ssNativePop: popCount.
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPush: n [ 
	simStackPtr := simStackPtr + n
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushAnnotatedConstant: literal [
	self ssPushConstant: literal.
	self annotateInstructionForBytecode.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushBase: reg offset: offset [
	self ssPush: 1.
	self ssTop
		type: SSBaseOffset;
		spilled: false;
		register: reg;
		offset: offset;
		bcptr: bytecodePC.
	self updateSimSpillBase.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushConstant: literal [
	self ssPush: 1.
	self ssTop
		type: SSConstant;
		spilled: false;
		constant: literal;
		bcptr: bytecodePC.
	self updateSimSpillBase.
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
StackToRegisterMappingCogit >> ssPushNativeConstantFloat32: aFloat32 [
	<option: #LowcodeVM>
	<var: #aFloat32 type: #float>
	self ssNativePush: 1.
	simNativeSpillBase > simNativeStackPtr ifTrue:
		[simNativeSpillBase := simNativeStackPtr max: 0].
	simNativeStackSize := simNativeStackSize + BytesPerWord.
	self ssNativeTop
		type: SSConstantFloat32;
		spilled: false;
		offset: simNativeStackSize;
		constantFloat32: aFloat32;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushNativeConstantFloat64: aFloat64 [
	<option: #LowcodeVM>
	<var: #aFloat64 type: #double>
	self ssNativePush: 1.
	simNativeSpillBase > simNativeStackPtr ifTrue:
		[simNativeSpillBase := simNativeStackPtr max: 0].
	simNativeStackSize := simNativeStackSize + 8.
	self ssNativeTop
		type: SSConstantFloat64;
		spilled: false;
		offset: simNativeStackSize;
		constantFloat64: aFloat64;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushNativeConstantInt32: anInt32 [
	<option: #LowcodeVM>
	self ssNativePush: 1.
	simNativeSpillBase > simNativeStackPtr ifTrue:
		[simNativeSpillBase := simNativeStackPtr max: 0].
	simNativeStackSize := simNativeStackSize + BytesPerWord.
	self ssNativeTop
		type: SSConstantInt32;
		spilled: false;
		offset: simNativeStackSize;
		constantInt32: anInt32;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushNativeConstantInt64: anInt64 [
	<option: #LowcodeVM>
	<var: #anInt64 type: #sqLong>
	self ssNativePush: 1.
	simNativeSpillBase > simNativeStackPtr ifTrue:
		[simNativeSpillBase := simNativeStackPtr max: 0].
	simNativeStackSize := simNativeStackSize + 8.
	self ssNativeTop
		type: SSConstantInt64;
		spilled: false;
		offset: simNativeStackSize;
		constantInt64: anInt64;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushNativeConstantPointer: aNativePointer [
	<option: #LowcodeVM>
	self ssNativePush: 1.
	simNativeSpillBase > simNativeStackPtr ifTrue:
		[simNativeSpillBase := simNativeStackPtr max: 0].
	simNativeStackSize := simNativeStackSize + BytesPerWord.
	self ssNativeTop
		type: SSConstantNativePointer;
		spilled: false;
		offset: simNativeStackSize;
		constantNativePointer: aNativePointer;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushNativeRegister: reg [
	<option: #LowcodeVM>
	self ssNativePush: 1.
	simNativeSpillBase > simNativeStackPtr ifTrue:
		[simNativeSpillBase := simNativeStackPtr max: 0].
	simNativeStackSize := simNativeStackSize + BytesPerWord.
	self ssNativeTop
		type: SSNativeRegister;
		spilled: false;
		offset: simNativeStackSize;
		register: reg;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushNativeRegister: reg secondRegister: secondReg [
	<option: #LowcodeVM>
	self ssNativePush: 1.
	simNativeSpillBase > simNativeStackPtr ifTrue:
		[simNativeSpillBase := simNativeStackPtr max: 0].
	simNativeStackSize := simNativeStackSize + 8.
	self ssNativeTop
		type: SSRegisterPair;
		spilled: false;
		offset: simNativeStackSize;
		register: reg;
		registerSecond: secondReg;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushNativeRegisterDoubleFloat: reg [
	<option: #LowcodeVM>
	self ssNativePush: 1.
	simNativeSpillBase > simNativeStackPtr ifTrue:
		[simNativeSpillBase := simNativeStackPtr max: 0].
	simNativeStackSize := simNativeStackSize + 8.
	self ssNativeTop
		type: SSRegisterDoubleFloat;
		spilled: false;
		offset: simNativeStackSize;
		register: reg;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushNativeRegisterSingleFloat: reg [
	<option: #LowcodeVM>
	self ssNativePush: 1.
	simNativeSpillBase > simNativeStackPtr ifTrue:
		[simNativeSpillBase := simNativeStackPtr max: 0].
	simNativeStackSize := simNativeStackSize + BytesPerWord.
	self ssNativeTop
		type: SSRegisterSingleFloat;
		spilled: false;
		offset: simNativeStackSize;
		register: reg;
		bcptr: bytecodePC.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssPushRegister: reg [
	self ssPush: 1.
	self ssTop
		type: SSRegister;
		spilled: false;
		register: reg;
		bcptr: bytecodePC.
	self updateSimSpillBase.
	^0
]

{ #category : #'simulation stack' }
StackToRegisterMappingCogit >> ssSelfDescriptor [
	<returnTypeC: #SimStackEntry>
	<inline: true>
	^simStack at: 0
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
	<inline: true>
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

{ #category : #testing }
StackToRegisterMappingCogit >> stackEntryIsBoolean: simStackEntry [
	<var: #simStackEntry type: #'CogSimStackEntry *'>
	<inline: true>
	^simStackEntry type = SSConstant
	  and: [simStackEntry constant = objectMemory trueObject
			or: [simStackEntry constant = objectMemory falseObject]]
]

{ #category : #testing }
StackToRegisterMappingCogit >> stackTopIsBoolean [
	<inline: true>
	^simStackPtr >= methodOrBlockNumArgs and: [self stackEntryIsBoolean: self ssTop]
]

{ #category : #debugging }
StackToRegisterMappingCogit >> tempsValidAndVolatileEntriesSpilled [
	"Answer if the stack is valid up to, but not including, simSpillBase."
	| culprit |
	1 to: methodOrBlockNumTemps do:
		[:i|
		 ((self simStackAt: i) type = SSBaseOffset
		   or: [self maybeCompilingFirstPassOfBlockWithInitialPushNil]) ifFalse:
			[culprit ifNil: [culprit := i].
			 ^false]].
	methodOrBlockNumTemps + 1 to: simSpillBase - 1 do:
		[:i|
		 (self simStackAt: i) spilled ifFalse:
			[culprit ifNil: [culprit := i].
			 ^false]].
	^true
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> traceDescriptor: descriptor [
	<cmacro: '(ign) 0'>
	(compilationTrace anyMask: 2) ifTrue:
		[coInterpreter transcript cr; print: bytecodePC; space; nextPutAll: descriptor generator.
		 deadCode ifTrue: [coInterpreter transcript nextPutAll: ' => deadCode'].
		 coInterpreter flush]
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> traceFixup: fixup merge: isMerge [
	<cmacro: '(igu,ana) 0'>
	| index |
	(compilationTrace anyMask: 32) ifTrue:
		[index := (fixups object identityIndexOf: fixup) - 1.
		 coInterpreter transcript
			ensureCr;
			print: bytecodePC; nextPutAll: ' -> '; print: index; nextPut: $/; print: index + initialPC;
			nextPut: $:; space.
		 isMerge
			ifTrue: [fixup printStateOn: coInterpreter transcript]
			ifFalse: [coInterpreter transcript nextPutAll: 'non-merge'].
		 coInterpreter transcript cr; flush]
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> traceMerge: fixup [
	<cmacro: '(ign) 0'>
	| index |
	(compilationTrace anyMask: 16) ifTrue:
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
	(compilationTrace anyMask: 4) ifTrue:
		[self printSimStack]
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> traceSpill: simStackEntry [
	<cmacro: '(ign) 0'>
	(compilationTrace anyMask: 8) ifTrue:
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
	pushArrayDesc := self generatorForPC: bytecodePC.
	self assert: pushArrayDesc generator == #genPushNewArrayBytecode.
	storeArrayDesc := self generatorForPC: bytecodePC + pushArrayDesc numBytes.
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
	pushValueDesc := self generatorForPC: bytecodePC
										+ pushArrayDesc numBytes
										+ storeArrayDesc numBytes.
	(pushValueDesc generator == #genPushLiteralConstantBytecode
	 or: [pushValueDesc generator == #genPushQuickIntegerConstantBytecode
	 or: [pushValueDesc generator == #genPushTemporaryVariableBytecode]]) ifFalse:
		[^false].
	storeValueDesc := self generatorForPC: bytecodePC
											+ pushArrayDesc numBytes
											+ storeArrayDesc numBytes
											+ pushValueDesc numBytes.
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
	"Something volatile has been pushed on the stack; update simSpillBase accordingly."
	<inline: true>
	self assert: ((simSpillBase > methodOrBlockNumTemps
				and: [simStackPtr >= methodOrBlockNumTemps])
				or: [self maybeCompilingFirstPassOfBlockWithInitialPushNil]).
	simSpillBase > simStackPtr
		ifTrue:
			[simSpillBase := simStackPtr + 1.
			 [simSpillBase - 1 > methodOrBlockNumTemps
			   and: [(self simStackAt: simSpillBase - 1) spilled not]] whileTrue:
				[simSpillBase := simSpillBase - 1]]
		ifFalse:
			[[(self simStackAt: simSpillBase) spilled
			   and: [simSpillBase <= simStackPtr]] whileTrue:
				[simSpillBase := simSpillBase + 1]].
	methodOrBlockNumTemps + 1 to: (simSpillBase - 1 min: simStackPtr) do:
		[:i|
		self assert: (self simStackAt: i) spilled == true].
	self assert: (simSpillBase > simStackPtr or: [(self simStackAt: simSpillBase) spilled == false])
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

{ #category : #testing }
StackToRegisterMappingCogit >> violatesEnsureSpilledSpillAssert [
	^true
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> voidReceiverOptStatus [
	"Used to mark ReceiverResultReg as dead or not containing simSelf.
	 Used when the simStack has already been flushed, e.g. for sends."
	<inline: true>
	self simSelf liveRegister: NoReg
]

{ #category : #'bytecode generator support' }
StackToRegisterMappingCogit >> voidReceiverResultRegContainsSelf [
	"Used when ReceiverResultReg is allocated for other than simSelf, and
	 there may be references to ReceiverResultReg which need to be spilled."
	| spillIndex |
	self voidReceiverOptStatus.
	spillIndex := 0.
	(methodOrBlockNumTemps + 1 max: simSpillBase) to: simStackPtr do:
		[:i|
		(self simStackAt: i) registerOrNone = ReceiverResultReg ifTrue:
			[spillIndex := i]].
	spillIndex > 0 ifTrue:
		[self ssFlushTo: spillIndex]
]

{ #category : #'simulation only' }
StackToRegisterMappingCogit >> widthInDefaultFontOf: aString [
	<doNotGenerate>
	^(NewParagraph new
		compose: aString asText
		style: TextStyle default
		from: 1
		in: Display boundingBox;
		adjustRightX)
		extent x
]
