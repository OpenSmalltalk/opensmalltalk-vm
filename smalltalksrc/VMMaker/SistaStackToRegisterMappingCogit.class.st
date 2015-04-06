"
A SistaStackToRegisterMappingCogit is a refinement of StackToRegisterMappingCogit that generates code suitable for dynamic optimization by Sista, the Speculative Inlining Smalltalk Architecture, a project by Clément Bera and Eliot Miranda.  Sista is an optimizer that exists in the Smalltalk image, /not/ in the VM,  and optimizes by substituting normal bytecoded methods by optimized bytecoded methods that may use special bytecodes for which the Cogit can generate faster code.  These bytecodes eliminate overheads such as bounds checks or polymorphic code (indexing Array, ByteArray, String etc).  But the bulk of the optimization performed is in inlining blocks and sends for the common path.

The basic scheme is that SistaStackToRegisterMappingCogit generates code containing performance counters.  When these counters trip, a callback into the image is performed, at which point Sista analyses some portion of the stack, looking at performance data for the methods on the stack, and optimises based on the stack and performance data.  Execution then resumes in the optimized code.

SistaStackToRegisterMappingCogit adds counters to conditional branches.  Each branch has an executed and a taken count, implemented at the two 16-bit halves of a single 32-bit word.  Each counter pair is initialized with initialCounterValue.  On entry to the branch the executed count is decremented and if the count goes below zero the ceMustBeBooleanAdd[True|False] trampoline called.  The trampoline distinguishes between true mustBeBoolean and counter trips because in the former the register temporarily holding the counter value will contain zero.  Then the condition is tested, and if the branch is taken the taken count is decremented.  The two counter values allow an optimizer to collect basic block execution paths and to know what are the ""hot"" paths through execution that are worth agressively optimizing.  Since conditional branches are about 1/6 as frequent as sends, and since they can be used to determine the hot path through code, they are a better choice to count than, for example, method or block entry.

SistaStackToRegisterMappingCogit implements picDataFor:into: that fills an Array with the state of the counters in a method and the state of each linked send in a method.  This is used to implement a primitive used by the optimizer to answer the branch and send data for a method as an Array.

Instance Variables
	counterIndex:			<Integer>
	counterMethodCache:	<CogMethod>
	counters:				<Array of AbstractInstruction>
	initialCounterValue:		<Integer>
	numCounters:			<Integer>
	picData:				<Integer Oop>
	picDataIndex:			<Integer>
	prevMapAbsPCMcpc:	<Integer>

counterIndex
	- xxxxx

counterMethodCache
	- xxxxx

counters
	- xxxxx

initialCounterValue
	- xxxxx

numCounters
	- xxxxx

picData
	- xxxxx

picDataIndex
	- xxxxx

prevMapAbsPCMcpc
	- xxxxx

"
Class {
	#name : #SistaStackToRegisterMappingCogit,
	#superclass : #StackToRegisterMappingCogit,
	#instVars : [
		'picDataIndex',
		'picData',
		'numCounters',
		'counters',
		'counterIndex',
		'initialCounterValue',
		'ceTrapTrampoline'
	],
	#classVars : [
		'CounterBytes',
		'MaxCounterValue'
	],
	#pools : [
		'VMSqueakClassIndices'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
SistaStackToRegisterMappingCogit class >> additionalHeadersDo: aBinaryBlock [
	"Evaluate aBinaryBlock with the names and contents of
	 any additional header files that need to be generated."
	aBinaryBlock
		value: 'cogmethod.h'
		value: SistaCogMethod cogMethodHeader
]

{ #category : #translation }
SistaStackToRegisterMappingCogit class >> ancilliaryClasses: options [
	^(super ancilliaryClasses: options) copyWith: SistaCogMethod
]

{ #category : #translation }
SistaStackToRegisterMappingCogit class >> declareCVarsIn: aCodeGen [
	aCodeGen var: 'counters' type: #usqInt
]

{ #category : #'class initialization' }
SistaStackToRegisterMappingCogit class >> generatorTableFrom: anArray [
	"Override to replace the unmapped, non-counting inlined #== with a mapped counting inlined #==."
	| table |
	table := super generatorTableFrom: anArray.
	table object do:
		[:descriptor|
		 descriptor generator == #genSpecialSelectorEqualsEquals ifTrue:
			[descriptor
				isMapped: true;
				isMappedInBlock: true;
				needsFrameFunction: nil]].
	^table
]

{ #category : #'class initialization' }
SistaStackToRegisterMappingCogit class >> initializeMiscConstants [
	super initializeMiscConstants.
	NumTrampolines := 53
						+ (NewspeakVM ifTrue: [18] ifFalse: [0])
						+ (BytecodeSetHasDirectedSuperSend ifTrue: [4] ifFalse: [0])
]

{ #category : #'class initialization' }
SistaStackToRegisterMappingCogit class >> initializeWithOptions: optionsDictionary [

	super initializeWithOptions: optionsDictionary.
	CounterBytes := 4.
	MaxCounterValue := (1 << 16) - 1
]

{ #category : #'compile abstract instructions' }
SistaStackToRegisterMappingCogit >> compileBlockBodies [
	"override to maintain counterIndex when recompiling blocks; sigh."
	<inline: false>
	| result compiledBlocksCount blockStart savedNeedsFrame savedNumArgs savedNumTemps
	  initialStackPtr initialOpcodeIndex initialAnnotationIndex initialCounterIndex initialIndexOfIRC |
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
		 initialCounterIndex := counterIndex.
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
				 counterIndex := initialCounterIndex.
				 self cppIf: #NewspeakVM ifTrue:
					[indexOfIRC := initialIndexOfIRC]].
		compiledBlocksCount := compiledBlocksCount + 1].
	needsFrame := savedNeedsFrame.
	methodOrBlockNumArgs := savedNumArgs.
	methodOrBlockNumTemps := savedNumTemps.
	^0
]

{ #category : #'compile abstract instructions' }
SistaStackToRegisterMappingCogit >> compileCogMethod: selector [
	counters := 0.
	^super compileCogMethod: selector
]

{ #category : #'compile abstract instructions' }
SistaStackToRegisterMappingCogit >> compileFrameBuild [
	"Override to prefetch counters, if any."
	super compileFrameBuild.
	counters ~= 0 ifTrue:
		[self PrefetchAw: counters]
]

{ #category : #disassembly }
SistaStackToRegisterMappingCogit >> disassembleMethod: surrogateOrAddress on: aStream [
	<doNotGenerate>
	| cogMethod |
	cogMethod := super disassembleMethod: surrogateOrAddress on: aStream.
	(cogMethod cmType = CMMethod
	 and: [cogMethod counters ~= 0]) ifTrue:
		[aStream nextPutAll: 'counters:'; cr.
		 numCounters := objectRepresentation numCountersFor: counters.
		 0 to: numCounters - 1 do:
			[:i| | addr |
			 addr := i * CounterBytes + counters.
			 addr printOn: aStream base: 16.
			 aStream nextPut: $:; space.
			 (objectMemory longAt: addr) printOn: aStream base: 16.
			 aStream cr].
		 aStream flush]
]

{ #category : #'generate machine code' }
SistaStackToRegisterMappingCogit >> fillInCPICHeader: pic size: size numArgs: numArgs numCases: numCases hasMNUCase: hasMNUCase selector: selector [
	pic counters: 0.
	^super fillInCPICHeader: pic size: size numArgs: numArgs numCases: numCases hasMNUCase: hasMNUCase selector: selector
]

{ #category : #'generate machine code' }
SistaStackToRegisterMappingCogit >> fillInCounters: nCounters atEndAddress: endAddress [
	endAddress - (nCounters * CounterBytes)
		to: endAddress - CounterBytes
		by: CounterBytes
		do: [:address|
			objectMemory
				long32At: address
				put: (initialCounterValue << 16 + initialCounterValue)]
]

{ #category : #'generate machine code' }
SistaStackToRegisterMappingCogit >> fillInCounters: nCounters atStartAddress: startAddress [
	startAddress
		to: startAddress + (nCounters - 1 * CounterBytes)
		by: CounterBytes
		do: [:address|
			objectMemory
				long32At: address
				put: (initialCounterValue << 16 + initialCounterValue)]
]

{ #category : #'generate machine code' }
SistaStackToRegisterMappingCogit >> fillInMethodHeader: method size: size selector: selector [
	super fillInMethodHeader: method size: size selector: selector.
	self fillInCounters: numCounters atStartAddress: counters.
	method counters: counters.
	^method
]

{ #category : #'generate machine code' }
SistaStackToRegisterMappingCogit >> fillInOPICHeader: pic size: size numArgs: numArgs selector: selector [
	pic counters: 0.
	^super fillInOPICHeader: pic size: size numArgs: numArgs selector: selector
]

{ #category : #'bytecode generators' }
SistaStackToRegisterMappingCogit >> genExtTrapIfNotInstanceOfBehaviorsBytecode [
	"SistaV1: *	236		11101100	iiiiiiii		Trap If Not Instance Of Behavior/Array Of Behavior #iiiiiiii (+ Extend A * 256, where Extend A >= 0)"
	| reg litIndex literal branches label numBranches |
	<var: #branches type: #'AbstractInstruction **'>
	reg := self ssStorePop: true toPreferredReg: ReceiverResultReg.
	reg ~= ReceiverResultReg ifTrue:
		[self MoveR: reg R: ReceiverResultReg].
	optStatus isReceiverResultRegLive: false.
	litIndex := extA * 256 + byte1.
	extA := 0.
	literal := self getLiteral: litIndex.
	"Allow an extra branch for Spur, which may have two tag patterns for SmallInteger"
	numBranches := (objectMemory isArrayNonImm: literal)
						ifTrue: [(objectMemory numSlotsOf: literal) + 1]
						ifFalse: [2].
	branches := self alloca: numBranches type: (self cCode: [#'AbstractInstruction *'] inSmalltalk: [backEnd class]).
	numBranches := (objectMemory isArrayNonImm: literal)
						ifTrue: [objectRepresentation branchIfInstanceOfBehaviors: literal branches: branches]
						ifFalse: [objectRepresentation branchIfInstanceOfBehavior: literal branches: branches].
	"Only flush the stack if the class trap traps.  Use ssFlushNoUpdateTo: so we continue compiling as if
	 the stack had not been flushed.  Control does not return after the ceClassTrapTrampoline call."
	self ssFlushNoUpdateTo: simStackPtr.
	self CallRT: ceTrapTrampoline.
	label := self Label.
	0 to: numBranches - 1 do:
		[:i|
		(branches at: i) jmpTarget: label].
	^0
]

{ #category : #'bytecode generator support' }
SistaStackToRegisterMappingCogit >> genJumpIf: boolean to: targetBytecodePC [
	"The heart of performance counting in Sista.  Conditional branches are 6 times less
	 frequent than sends and can provide basic block frequencies (send counters can't).
	 Each conditional has a 32-bit counter split into an upper 16 bits counting executions
	 and a lower half counting untaken executions of the branch.  Executing the branch
	 decrements the upper half, tripping if the count goes negative.  Not taking the branch
	 decrements the lower half.  N.B. We *do not* eliminate dead branches (true ifTrue:/true ifFalse:)
	 so that scanning for send and branch data is simplified and that branch data is correct."
	<inline: false>
	| desc ok counterAddress countTripped retry |
	<var: #ok type: #'AbstractInstruction *'>
	<var: #desc type: #'CogSimStackEntry *'>
	<var: #retry type: #'AbstractInstruction *'>
	<var: #countTripped type: #'AbstractInstruction *'>

	(coInterpreter isOptimizedMethod: methodObj) ifTrue: [ ^ super genJumpIf: boolean to: targetBytecodePC ].

	self ssFlushTo: simStackPtr - 1.
	desc := self ssTop.
	self ssPop: 1.
	desc popToReg: TempReg.

	self ssAllocateRequiredReg: SendNumArgsReg. "Use this as the count reg."
	counterAddress := counters + ((self sizeof: #sqInt) * counterIndex).
	counterIndex := counterIndex + 1.
	self flag: 'will need to use MoveAw32:R: if 64 bits'.
	self assert: objectMemory wordSize = CounterBytes.
	retry := self MoveAw: counterAddress R: SendNumArgsReg.
	self SubCq: 16r10000 R: SendNumArgsReg. "Count executed"
	"Don't write back if we trip; avoids wrapping count back to initial value, and if we trip we don't execute."
	countTripped := self JumpCarry: 0.
	self MoveR: SendNumArgsReg Aw: counterAddress. "write back"

	"Cunning trick by LPD.  If true and false are contiguous subtract the smaller.
	 Correct result is either 0 or the distance between them.  If result is not 0 or
	 their distance send mustBeBoolean."
	self assert: (objectMemory objectAfter: objectMemory falseObject) = objectMemory trueObject.
	self annotate: (self SubCw: boolean R: TempReg) objRef: boolean.
	self JumpZero: (self ensureFixupAt: targetBytecodePC - initialPC).

	self SubCq: 1 R: SendNumArgsReg. "Count untaken"
	self MoveR: SendNumArgsReg Aw: counterAddress. "write back"

	self CmpCq: (boolean == objectMemory falseObject
					ifTrue: [objectMemory trueObject - objectMemory falseObject]
					ifFalse: [objectMemory falseObject - objectMemory trueObject])
		R: TempReg.
	ok := self JumpZero: 0.
	self MoveCq: 0 R: SendNumArgsReg. "if SendNumArgsReg is 0 this is a mustBeBoolean, not a counter trip."
	countTripped jmpTarget:
		(self CallRT: (boolean == objectMemory falseObject
						ifTrue: [ceSendMustBeBooleanAddFalseTrampoline]
						ifFalse: [ceSendMustBeBooleanAddTrueTrampoline])).
	"If we're in an image which hasn't got the Sista code loaded then the ceCounterTripped:
	 trampoline will return directly to machine code, returning the boolean.  So the code should
	 jump back to the retry point. The trampoline makes sure that TempReg has been reloaded."
	self annotateBytecode: self Label.
	self Jump: retry.
	ok jmpTarget: self Label.
	^0
]

{ #category : #initialization }
SistaStackToRegisterMappingCogit >> genMustBeBooleanTrampolineFor: boolean called: trampolineName [
	"This can be entered in one of two states, depending on SendNumArgsReg. See
	 e.g. genJumpIf:to:.  If SendNumArgsReg is non-zero then this has been entered via
	 the initial test of the counter in the jump executed count (i.e. the counter has
	 tripped).  In this case TempReg contains the boolean to be tested and should not
	 be offset, and ceCounterTripped should be invoked with the unoffset TempReg.
	 If SendNumArgsReg is zero then this has been entered for must-be-boolean
	 processing. TempReg has been offset by boolean and must be corrected and
	 ceSendMustBeBoolean: invoked with the corrected value."
	<var: #trampolineName type: #'char *'>
	| jumpMBB |
	<var: #jumpMBB type: #'AbstractInstruction *'>
	<inline: false>
	opcodeIndex := 0.
	self CmpCq: 0 R: SendNumArgsReg.
	jumpMBB := self JumpZero: 0.
	"Open-code self compileTrampolineFor: #ceCounterTripped: numArgs: 1 arg: TempReg ...
	 so we can restore ResultReceiverReg."
	backEnd hasLinkRegister ifTrue:
		[self PushR: LinkReg].
	self genSmalltalkToCStackSwitch.
	self
		compileCallFor: #ceCounterTripped:
		numArgs: 1
		arg: TempReg
		arg: nil
		arg: nil
		arg: nil
		resultReg: TempReg "(*)"
		saveRegs: false.
	"(*) For the case where the ceCounterTripped: call returns (e.g. because there's no callback selector
	 installed), the call to the ceSendMustBeBooleanAddTrue/FalseTrampoline is followed by a jump
	 back to the start of the counter/condition test sequence.  For this case copy the C result to
	 TempReg (the register that is tested), to reload it with the boolean to be tested."
	backEnd genLoadStackPointers.
	backEnd hasLinkRegister ifTrue:
		[self PopR: LinkReg].
	"To keep ResultReceiverReg live if optStatus thiught it was, simply reload it
	 from the frame pointer.  This avoids having to reload it in the common case
	 (counter does not trip) if it was live."
	self MoveMw: FoxMFReceiver r: FPReg R: ReceiverResultReg.
	self RetN: 0.
	"If the objectRepresentation does want true & false to be mobile then we need to record these addresses."
	self assert: (objectRepresentation shouldAnnotateObjectReference: boolean) not.
	jumpMBB jmpTarget: (self AddCq: boolean R: TempReg).
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
SistaStackToRegisterMappingCogit >> genSpecialSelectorComparison [
	"Override to count inlined branches if followed by a conditional branch.
	 We borrow the following conditional branch's counter and when about to
	 inline the comparison we decrement the counter (without writing it back)
	 and if it trips simply abort the inlining, falling back to the normal send which
	 will then continue to the conditional branch which will trip and enter the abort."
	| nextPC postBranchPC targetBytecodePC primDescriptor branchDescriptor nExts
	  rcvrIsInt argIsInt rcvrInt argInt result jumpNotSmallInts inlineCAB annotateInst
	  counterAddress countTripped |
	<var: #countTripped type: #'AbstractInstruction *'>
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpNotSmallInts type: #'AbstractInstruction *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>

	(coInterpreter isOptimizedMethod: methodObj) ifTrue: [ ^ super genSpecialSelectorComparison ].

	self ssFlushTo: simStackPtr - 2.
	primDescriptor := self generatorAt: byte0.
	argIsInt := self ssTop type = SSConstant
				 and: [objectMemory isIntegerObject: (argInt := self ssTop constant)].
	rcvrIsInt := (self ssValue: 1) type = SSConstant
				 and: [objectMemory isIntegerObject: (rcvrInt := (self ssValue: 1) constant)].

	"short-cut the jump if operands are SmallInteger constants."
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

	self ssAllocateRequiredReg: SendNumArgsReg. "Use this as the count reg."
	counterAddress := counters + ((self sizeof: #sqInt) * counterIndex).
	self flag: 'will need to use MoveAw32:R: if 64 bits'.
	self assert: objectMemory wordSize = CounterBytes.
	self MoveAw: counterAddress R: SendNumArgsReg.
	self SubCq: 16r10000 R: SendNumArgsReg. "Count executed"
	"If counter trips simply abort the inlined comparison and send continuing to the following
	 branch *without* writing back.  A double decrement will not trip the second time."
	countTripped := self JumpCarry: 0.
	self MoveR: SendNumArgsReg Aw: counterAddress. "write back"

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
	self SubCq: 1 R: SendNumArgsReg. "Count untaken"
	self MoveR: SendNumArgsReg Aw: counterAddress. "write back"
	self Jump: (self ensureNonMergeFixupAt: postBranchPC - initialPC).
	countTripped jmpTarget: (jumpNotSmallInts jmpTarget: self Label).
	argIsInt ifTrue:
		[self MoveCq: argInt R: Arg0Reg].
	^self genMarshalledSend: (coInterpreter specialSelector: byte0 - self firstSpecialSelectorBytecodeOffset)
		numArgs: 1
		sendTable: ordinarySendTrampolines
]

{ #category : #'bytecode generators' }
SistaStackToRegisterMappingCogit >> genSpecialSelectorEqualsEquals [
	"Override to count inlined branches if followed by a conditional branch.
	 We borrow the following conditional branch's counter and when about to
	 inline the comparison we decrement the counter (without writing it back)
	 and if it trips simply abort the inlining, falling back to the normal send which
	 will then continue to the conditional branch which will trip and enter the abort."
	| nextPC postBranchPC targetBytecodePC primDescriptor branchDescriptor nExts
	  counterAddress countTripped unforwardArg unforwardRcvr |
	<var: #countTripped type: #'AbstractInstruction *'>
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>

	(coInterpreter isOptimizedMethod: methodObj) ifTrue: [ ^ super genSpecialSelectorEqualsEquals ].

	self ssFlushTo: simStackPtr - 2.
	primDescriptor := self generatorAt: byte0.

	nextPC := bytecodePC + primDescriptor numBytes.
	nExts := 0.
	[branchDescriptor := self generatorAt: (objectMemory fetchByte: nextPC ofObject: methodObj) + (byte0 bitAnd: 256).
	 branchDescriptor isExtension] whileTrue:
		[nExts := nExts + 1.
		 nextPC := nextPC + branchDescriptor numBytes].
	"Only interested in inlining if followed by a conditional branch."
	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse]) ifFalse:
		[^self genSpecialSelectorSend].

	targetBytecodePC := nextPC
							+ branchDescriptor numBytes
							+ (self spanFor: branchDescriptor at: nextPC exts: nExts in: methodObj).
	postBranchPC := nextPC + branchDescriptor numBytes.
	unforwardRcvr := (self ssValue: 1) type ~= SSConstant
						or: [objectRepresentation shouldAnnotateObjectReference: (self ssValue: 1) constant].
	unforwardArg := self ssTop type ~= SSConstant
						or: [objectRepresentation shouldAnnotateObjectReference: self ssTop constant].
	self marshallSendArguments: 1.

	self ssAllocateRequiredReg: SendNumArgsReg. "Use this as the count reg."
	counterAddress := counters + ((self sizeof: #sqInt) * counterIndex).
	self flag: 'will need to use MoveAw32:R: if 64 bits'.
	self assert: objectMemory wordSize = CounterBytes.
	self MoveAw: counterAddress R: SendNumArgsReg.
	self SubCq: 16r10000 R: SendNumArgsReg. "Count executed"
	"If counter trips simply abort the inlined comparison and send continuing to the following
	 branch *without* writing back.  A double decrement will not trip the second time."
	countTripped := self JumpCarry: 0.
	self MoveR: SendNumArgsReg Aw: counterAddress. "write back"
	unforwardRcvr ifTrue:
		[objectRepresentation genEnsureOopInRegNotForwarded: ReceiverResultReg scratchReg: TempReg].
	unforwardArg ifTrue:
		[objectRepresentation genEnsureOopInRegNotForwarded: Arg0Reg scratchReg: TempReg].
	self CmpR: Arg0Reg R: ReceiverResultReg.
	"Cmp is weird/backwards so invert the comparison.  Further since there is a following conditional
	 jump bytecode define non-merge fixups and leave the cond bytecode to set the mergeness."
	self gen: (branchDescriptor isBranchTrue ifTrue: [JumpZero] ifFalse: [JumpNonZero])
		operand: (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.
	self SubCq: 1 R: SendNumArgsReg. "Count untaken"
	self MoveR: SendNumArgsReg Aw: counterAddress. "write back"
	self Jump: (self ensureNonMergeFixupAt: postBranchPC - initialPC).
	countTripped jmpTarget: self Label.
	^self genMarshalledSend: (coInterpreter specialSelector: byte0 - self firstSpecialSelectorBytecodeOffset)
		numArgs: 1
		sendTable: ordinarySendTrampolines
]

{ #category : #'bytecode generators' }
SistaStackToRegisterMappingCogit >> genUnconditionnalTrapBytecode [
	"SistaV1: *	217		Trap"
	"Use ssFlushNoUpdateTo: so we continue compiling as if the stack had not been flushed . 
	(typically, this kind of trap is in a branch)  
	Control does not return after the ceClassTrapTrampoline call."
	self ssFlushNoUpdateTo: simStackPtr.
	self CallRT: ceTrapTrampoline.
	^0
]

{ #category : #initialization }
SistaStackToRegisterMappingCogit >> generateSistaRuntime [
	"Trap sends Sista trap message to context with top of stack, so we don't need any arguments..."
	ceTrapTrampoline := self genTrampolineFor: #ceSistaTrap:
									called: 'ceSistaTrapTrampoline'
									arg: ReceiverResultReg
]

{ #category : #'method introspection' }
SistaStackToRegisterMappingCogit >> getJumpTargetPCAt: pc [
	<api>
	^backEnd jumpTargetPCAt: pc
]

{ #category : #initialization }
SistaStackToRegisterMappingCogit >> initialize [
	super initialize.
	cogMethodSurrogateClass := (objectMemory ifNil: [self class objectMemoryClass]) wordSize = 4
										ifTrue: [CogSistaMethodSurrogate32]
										ifFalse: [CogSistaMethodSurrogate64]
]

{ #category : #initialization }
SistaStackToRegisterMappingCogit >> initializeCodeZoneFrom: startAddress upTo: endAddress [
	initialCounterValue := MaxCounterValue.
	super initializeCodeZoneFrom: startAddress upTo: endAddress
]

{ #category : #'method map' }
SistaStackToRegisterMappingCogit >> mapFor: cogMethod bcpc: startbcpc withAnnotationPerformUntil: functionSymbol arg: arg [
	"A version of mapFor:bcpc:performUntil:arg: that passes the annotation instead of the isBackwardBranch flag."
	<var: #cogMethod type: #'CogBlockMethod *'>
	<var: #functionSymbol declareC: 'sqInt (*functionSymbol)(BytecodeDescriptor *desc, sqInt annotation, char *mcpc, sqInt bcpc, void *arg)'>
	<var: #arg type: #'void *'>
	<inline: true>
	| isInBlock mcpc bcpc endbcpc map mapByte homeMethod aMethodObj result
	  latestContinuation byte descriptor bsOffset nExts annotation |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #homeMethod type: #'CogMethod *'>
	self assert: cogMethod stackCheckOffset > 0.
	"In both CMMethod and CMBlock cases find the start of the map and
	 skip forward to the bytecode pc map entry for the stack check."
	cogMethod cmType = CMMethod
		ifTrue:
			[isInBlock := false.
			 homeMethod := self cCoerceSimple: cogMethod to: #'CogMethod *'.
			 self assert: startbcpc = (coInterpreter startPCOfMethodHeader: homeMethod methodHeader).
			 map := self mapStartFor: homeMethod.
			 annotation := (objectMemory byteAt: map) >> AnnotationShift.
			 self assert: (annotation = IsAbsPCReference
						 or: [annotation = IsObjectReference
						 or: [annotation = IsRelativeCall
						 or: [annotation = IsDisplacementX2N]]]).
			 latestContinuation := startbcpc.
			 aMethodObj := homeMethod methodObject.
			 endbcpc := (objectMemory numBytesOf: aMethodObj) - 1.
			 bsOffset := self bytecodeSetOffsetForHeader: homeMethod methodHeader]
		ifFalse:
			[isInBlock := true.
			 homeMethod := cogMethod cmHomeMethod.
			 map := self findMapLocationForMcpc: cogMethod asUnsignedInteger + (self sizeof: CogBlockMethod)
						inMethod: homeMethod.
			 self assert: map ~= 0.
			 annotation := (objectMemory byteAt: map) >> AnnotationShift.
			 self assert: (annotation >> AnnotationShift = HasBytecodePC "fiducial"
						 or: [annotation >> AnnotationShift = IsDisplacementX2N]).
			 [(annotation := (objectMemory byteAt: map) >> AnnotationShift) ~= HasBytecodePC] whileTrue:
				[map := map - 1].
			 map := map - 1. "skip fiducial; i.e. the map entry for the pc immediately following the method header."
			 aMethodObj := homeMethod methodObject.
			 bcpc := startbcpc - (self blockCreationBytecodeSizeForHeader: homeMethod methodHeader).
			 bsOffset := self bytecodeSetOffsetForHeader: homeMethod methodHeader.
			 byte := (objectMemory fetchByte: bcpc ofObject: aMethodObj) + bsOffset.
			 descriptor := self generatorAt: byte.
			 endbcpc := self nextBytecodePCFor: descriptor at: bcpc exts: -1 in: aMethodObj].
	bcpc := startbcpc.
	mcpc := cogMethod asUnsignedInteger + cogMethod stackCheckOffset.
	nExts := 0.
	"The stack check maps to the start of the first bytecode,
	 the first bytecode being effectively after frame build."
	result := self perform: functionSymbol
					with: nil
					with: annotation
					with: (self cCoerceSimple: mcpc to: #'char *')
					with: startbcpc
					with: arg.
	result ~= 0 ifTrue:
		[^result].
	"Now skip up through the bytecode pc map entry for the stack check." 
	[(objectMemory byteAt: map) >> AnnotationShift ~= HasBytecodePC] whileTrue:
		[map := map - 1].
	map := map - 1.
	[(mapByte := objectMemory byteAt: map) ~= MapEnd] whileTrue: "defensive; we exit on bcpc"
		[mapByte >= FirstAnnotation
			ifTrue:
				[| nextBcpc |
				annotation := mapByte >> AnnotationShift.
				mcpc := mcpc + (mapByte bitAnd: DisplacementMask).
				(self isPCMappedAnnotation: annotation) ifTrue:
					[(annotation = IsSendCall
					  and: [(mapByte := objectMemory byteAt: map - 1) >> AnnotationShift = IsAnnotationExtension]) ifTrue:
						[annotation := annotation + (mapByte bitAnd: DisplacementMask).
						 map := map - 1].
					[byte := (objectMemory fetchByte: bcpc ofObject: aMethodObj) + bsOffset.
					  descriptor := self generatorAt: byte.
					  isInBlock
						ifTrue: [bcpc >= endbcpc ifTrue: [^0]]
						ifFalse:
							[(descriptor isReturn and: [bcpc >= latestContinuation]) ifTrue: [^0].
							 (descriptor isBranch or: [descriptor isBlockCreation]) ifTrue:
								[| targetPC |
								 targetPC := self latestContinuationPCFor: descriptor at: bcpc exts: nExts in: aMethodObj.
								 latestContinuation := latestContinuation max: targetPC]].
					  nextBcpc := self nextBytecodePCFor: descriptor at: bcpc exts: nExts in: aMethodObj.
					  descriptor isMapped
					  or: [isInBlock and: [descriptor isMappedInBlock]]] whileFalse:
						[bcpc := nextBcpc.
						 nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0]].
					result := self perform: functionSymbol
									with: descriptor
									with: annotation
									with: (self cCoerceSimple: mcpc to: #'char *')
									with: bcpc
									with: arg.
					 result ~= 0 ifTrue:
						[^result].
					 bcpc := nextBcpc.
					 nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0]]]
			ifFalse:
				[self assert: (mapByte >> AnnotationShift = IsDisplacementX2N
							or: [mapByte >> AnnotationShift = IsAnnotationExtension]).
				 mapByte < (IsAnnotationExtension << AnnotationShift) ifTrue:
					[mcpc := mcpc + (mapByte - DisplacementX2N << AnnotationShift)]].
		 map := map - 1].
	^0
]

{ #category : #'compile abstract instructions' }
SistaStackToRegisterMappingCogit >> maybeAllocAndInitCounters [
	<inline: true>
	self assert: counters = 0.
	counterIndex := 0.
	numCounters = 0 ifTrue:
		[^true].
	counters := objectRepresentation allocateCounters: numCounters.
	^counters ~= 0
]

{ #category : #'compile abstract instructions' }
SistaStackToRegisterMappingCogit >> maybeFreeCounters [
	<inline: true>
	counters ~= 0 ifTrue:
		[objectRepresentation freeCounters: counters]
]

{ #category : #compaction }
SistaStackToRegisterMappingCogit >> maybeFreeCountersOf: aCogMethod [
	"Free any counters in the method."
	<inline: true>
	objectRepresentation freeCounters: aCogMethod counters
]

{ #category : #'garbage collection' }
SistaStackToRegisterMappingCogit >> maybeMarkCountersIn: cogMethod [
	"In SIsta Spur counters are held on the heap in pinned objects which must be marked
	 to avoid them being garbage collected.  This is the hook through which that happens."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	objectRepresentation maybeMarkCounters: cogMethod counters
]

{ #category : #'method introspection' }
SistaStackToRegisterMappingCogit >> picDataFor: descriptor Annotation: annotation Mcpc: mcpc Bcpc: bcpc Method: cogMethodArg [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #mcpc type: #'char *'>
	<var: #cogMethodArg type: #'void *'>
	| entryPoint tuple counter |
	<var: #counter type: #'unsigned long'>

	descriptor isNil ifTrue:
		[^0].
	descriptor isBranch ifTrue:
		["it's a branch; conditional?"
		 (descriptor isBranchTrue or: [descriptor isBranchFalse]) ifTrue:
			[counter := (self
							cCoerce: ((self
											cCoerceSimple: cogMethodArg
											to: #'CogMethod *') counters)
							to: #'unsigned long *')
								at: counterIndex.
			 tuple := self picDataForCounter: counter at: bcpc + 1.
			 tuple = 0 ifTrue: [^PrimErrNoMemory].
			 objectMemory storePointer: picDataIndex ofObject: picData withValue: tuple.
			 picDataIndex := picDataIndex + 1.
			 counterIndex := counterIndex + 1].
		 ^0].
	((self isPureSendAnnotation: annotation)
	 and: [entryPoint := backEnd callTargetFromReturnAddress: mcpc asUnsignedInteger.
		 entryPoint > methodZoneBase]) ifFalse: "send is not linked, or is not a send"
		[^0].
	self targetMethodAndSendTableFor: entryPoint "It's a linked send; find which kind."
		annotation: annotation
		into: [:targetMethod :sendTable| | methodClassIfSuper association |
			methodClassIfSuper := nil.
			sendTable = superSendTrampolines ifTrue:
				[methodClassIfSuper := coInterpreter methodClassOf: (self cCoerceSimple: cogMethodArg to: #'CogMethod *') methodObject].
			sendTable = directedSuperSendTrampolines ifTrue:
				[association := backEnd literalBeforeInlineCacheTagAt: mcpc.
				 methodClassIfSuper := objectRepresentation valueOfAssociation: association].
			tuple := self picDataForSendTo: targetMethod
						methodClassIfSuper: methodClassIfSuper
						at: mcpc
						bcpc: bcpc + 1].
	tuple = 0 ifTrue: [^PrimErrNoMemory].
	objectMemory storePointer: picDataIndex ofObject: picData withValue: tuple.
	picDataIndex := picDataIndex + 1.
	^0
]

{ #category : #'method introspection' }
SistaStackToRegisterMappingCogit >> picDataFor: cogMethod into: arrayObj [
	"Collect the branch and send data for cogMethod, storing it into arrayObj."
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	| errCode |
	cogMethod stackCheckOffset = 0 ifTrue:
		[^0].
	picDataIndex := counterIndex := 0.
	picData := arrayObj.
	errCode := self
					mapFor: (self cCoerceSimple: cogMethod to: #'CogBlockMethod *')
					bcpc: (coInterpreter startPCOfMethod: cogMethod methodObject)
					withAnnotationPerformUntil: #picDataFor:Annotation:Mcpc:Bcpc:Method:
					arg: cogMethod asVoidPointer.
	errCode ~= 0 ifTrue:
		[self assert: errCode = PrimErrNoMemory.
		 ^-1].
	cogMethod blockEntryOffset ~= 0 ifTrue:
		[errCode := self blockDispatchTargetsFor: cogMethod
						perform: #picDataForBlockEntry:Method:
						arg: cogMethod asInteger.
		 errCode ~= 0 ifTrue:
			[self assert: errCode = PrimErrNoMemory.
			 ^-1]].
	^picDataIndex
]

{ #category : #'method introspection' }
SistaStackToRegisterMappingCogit >> picDataForBlockEntry: blockEntryMcpc Method: cogMethod [
	"Collect the branch and send data for the block method starting at blockEntryMcpc, storing it into picData."
	<returnTypeC: #usqInt>
	| cogBlockMethod |
	<var: #cogBlockMethod type: #'CogBlockMethod *'>
	cogBlockMethod := self cCoerceSimple: blockEntryMcpc - (self sizeof: CogBlockMethod)
							  to: #'CogBlockMethod *'.
	cogBlockMethod stackCheckOffset = 0 ifTrue:
		[^0].
	^self
		mapFor: cogBlockMethod
		bcpc: cogBlockMethod startpc
		withAnnotationPerformUntil: #picDataFor:Annotation:Mcpc:Bcpc:Method:
		arg: cogMethod asVoidPointer
]

{ #category : #'method introspection' }
SistaStackToRegisterMappingCogit >> picDataForCounter: counter at: bcpc [
	| executedCount tuple untakenCount |
	<var: #counter type: #'unsigned long'>
	tuple := objectMemory
				eeInstantiateClassIndex: ClassArrayCompactIndex
				format: objectMemory arrayFormat
				numSlots: 3.
	tuple = 0 ifTrue:
		[^0].
	self assert: CounterBytes = 4.
	executedCount := initialCounterValue - (counter >> 16).
	untakenCount := initialCounterValue - (counter bitAnd: 16rFFFF).
	objectMemory
		storePointerUnchecked: 0 ofObject: tuple withValue: (objectMemory integerObjectOf: bcpc);
		storePointerUnchecked: 1 ofObject: tuple withValue: (objectMemory integerObjectOf: executedCount);
		storePointerUnchecked: 2 ofObject: tuple withValue: (objectMemory integerObjectOf: untakenCount).
	^tuple
]

{ #category : #'method introspection' }
SistaStackToRegisterMappingCogit >> picDataForSendTo: cogMethod methodClassIfSuper: methodClassOrNil at: sendMcpc bcpc: sendBcpc [
	"Answer a tuple with the send data for a linked send to cogMethod.
	 If the target is a CogMethod (monomorphic send) answer
		{ bytecode pc, inline cache class, target method }
	 If the target is an open PIC (megamorphic send) answer
		{ bytecode pc, nil, send selector }
	If the target is a closed PIC (polymorphic send) answer
		{ bytecode pc, first class, target method, second class, second target method, ... }"
	<var: #cogMethod type: #'CogMethod *'>
	<var: #sendMcpc type: #'char *'>
	| tuple class |
	tuple := objectMemory
					eeInstantiateClassIndex: ClassArrayCompactIndex
					format: objectMemory arrayFormat
					numSlots: (cogMethod cmType = CMClosedPIC
								ifTrue: [2 * cogMethod cPICNumCases + 1]
								ifFalse: [3]).
	tuple = 0 ifTrue:
		[^0].
	objectMemory storePointerUnchecked: 0 ofObject: tuple withValue: (objectMemory integerObjectOf: sendBcpc).
	cogMethod cmType = CMMethod ifTrue:
		[class := methodClassOrNil ifNil:
					[objectRepresentation classForInlineCacheTag: (backEnd inlineCacheTagAt: sendMcpc asUnsignedInteger)].
		 objectMemory
			storePointer: 1 ofObject: tuple withValue: class;
			storePointer: 2 ofObject: tuple withValue: cogMethod methodObject.
		^tuple].
	cogMethod cmType = CMClosedPIC ifTrue:
		[self populate: tuple withPICInfoFor: cogMethod firstCacheTag: (backEnd inlineCacheTagAt: sendMcpc asUnsignedInteger).
		^tuple].
	cogMethod cmType = CMOpenPIC ifTrue:
		[objectMemory
			storePointerUnchecked: 1 ofObject: tuple withValue: objectMemory nilObject;
			storePointer: 2 ofObject: tuple withValue: cogMethod selector.
		^tuple].
	self error: 'invalid method type'.
	^0 "to get Slang to type this method as answering sqInt"
]

{ #category : #'method introspection' }
SistaStackToRegisterMappingCogit >> populate: tuple withPICInfoFor: cPIC firstCacheTag: firstCacheTag [
	"Populate tuple (which must be large enough) with the ClosedPIC's target method class pairs.
	 The first entry in tuple contains the bytecode pc for the send, so skip the tuple's first field."
	<var: #cPIC type: #'CogMethod *'>
	| pc cacheTag classOop entryPoint targetMethod value |
	<var: #targetMethod type: #'CogMethod *'>
	pc := cPIC asInteger + firstCPICCaseOffset.
	1 to: cPIC cPICNumCases do:
		[:i|
		cacheTag := i = 1
						ifTrue: [firstCacheTag]
						ifFalse: [backEnd literalBeforeFollowingAddress: pc
																		- backEnd jumpLongConditionalByteSize
																		- backEnd loadLiteralByteSize].
		classOop := objectRepresentation classForInlineCacheTag: cacheTag.
		objectMemory storePointer: i * 2 - 1 ofObject: tuple withValue: classOop.
		entryPoint := backEnd jumpLongTargetBeforeFollowingAddress: pc.
		"Find target from jump.  A jump to the MNU entry-point should collect #doesNotUnderstand:"
		(entryPoint asUnsignedInteger < cPIC asUnsignedInteger
		 or: [entryPoint asUnsignedInteger > (cPIC asUnsignedInteger + cPIC blockSize) asUnsignedInteger])
			ifTrue:
				[targetMethod := self cCoerceSimple: entryPoint - cmNoCheckEntryOffset to: #'CogMethod *'.
				 self assert: targetMethod cmType = CMMethod.
				 value := targetMethod methodObject]
			ifFalse:
				[value := objectMemory splObj: SelectorDoesNotUnderstand].
		objectMemory storePointer: i * 2 ofObject: tuple withValue: value.
		pc := pc + cPICCaseSize]
]

{ #category : #'method map' }
SistaStackToRegisterMappingCogit >> printMcpc: mcpc Bcpc: bcpc on: aStream [
	<doNotGenerate>
	self shouldNotImplement
]

{ #category : #tests }
SistaStackToRegisterMappingCogit >> printPICDataForMethods [
	<doNotGenerate>
	methodZone methodsDo:
		[:cogMethod|
		cogMethod cmType = CMMethod ifTrue:
			[(coInterpreter picDataFor: cogMethod) ifNotNil:
				[:thePicData|
				coInterpreter printOop: thePicData]]]
]

{ #category : #'sista callbacks' }
SistaStackToRegisterMappingCogit >> resetCountersIn: cogMethod [
	<doNotGenerate>
	objectRepresentation resetCountersIn: cogMethod
]

{ #category : #'compile abstract instructions' }
SistaStackToRegisterMappingCogit >> scanMethod [
	"Scan the method (and all embedded blocks) to determine
		- what the last bytecode is; extra bytes at the end of a method are used to encode things like source pointers or temp names
		- if the method needs a frame or not
		- what are the targets of any backward branches.
		- how many blocks it creates
		- how many counters it needs/conditional branches it contains
	 Answer the block count or on error a negative error code"
	| latestContinuation nExts descriptor pc numBlocks distance targetPC framelessStackDelta |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	needsFrame := false.
	inBlock := false.
	prevBCDescriptor := nil.
	numCounters := 0.
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
				ifFalse:
					[latestContinuation := latestContinuation max: targetPC.
					 (descriptor isBranchTrue or: [descriptor isBranchFalse]) ifTrue:
						[numCounters := numCounters + 1]]].
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

{ #category : #'simulation stack' }
SistaStackToRegisterMappingCogit >> ssFlushNoUpdateTo: index [
	"This version of ssFlushTo: does /not/ update the simulation stack; it merely generates the spill code.
	 It is used to spill all values to the stack on a rare failing branch (the class trap) when we don't want to
	 flush the stack on the main path and hence mustn't update the simulation stack if there is no spill."
	<var: 'copiedEntry' type: #CogSimStackEntry>
	self assert: needsFrame.
	methodOrBlockNumTemps to: simSpillBase - 1 do:
		[:i| self assert: (self simStackAt: i) spilled].
	simSpillBase <= index ifTrue:
		[(simSpillBase max: 0) to: index do:
			[:i| | copiedEntry |
			copiedEntry := self cCode: [simStack at: index]
								inSmalltalk: [(simStack at: index) copy].
			copiedEntry
				ensureSpilledAt: (self frameOffsetOfTemporary: i)
				from: FPReg]]
]
