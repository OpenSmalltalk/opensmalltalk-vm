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
		'counterMethodCache',
		'prevMapAbsPCMcpc'
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
	aCodeGen
		var: 'counters'
			type: #'AbstractInstruction *'
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
SistaStackToRegisterMappingCogit class >> initializeWithOptions: optionsDictionary [

	super initializeWithOptions: optionsDictionary.
	CounterBytes := 4.
	MaxCounterValue := (1 << 16) - 1
]

{ #category : #testing }
SistaStackToRegisterMappingCogit >> addressIsInInstructions: address [
	<var: #address type: #'AbstractInstruction *'>
	^self cCode:
			'address >= &abstractOpcodes[0] && address < &abstractOpcodes[opcodeIndex]
			|| address >= &counters[0] && address < &counters[counterIndex]'
		inSmalltalk:
			[((abstractOpcodes object identityIndexOf: address) between: 1 and: opcodeIndex)
			or: [(counters object identityIndexOf: address) between: 1 and: counterIndex]]
]

{ #category : #initialization }
SistaStackToRegisterMappingCogit >> allocateCounters [
	"Allocate the structures used to manage counting conditional branch
	 compilation.  This  needs to be a macro since the structures are alloca'ed
	 (stack allocated) to ensure their being freed when compilation is done."
	<cmacro: '() do { \
		counters = numCounters ? alloca(sizeof(AbstractInstruction) * numCounters) : 0; \
} while (0)'>
	counters := CArrayAccessor on:
					((1 to: numCounters) collect:
						[:ign| backEnd class new])
]

{ #category : #'method map' }
SistaStackToRegisterMappingCogit >> bytecodePCFor: mcpc startBcpc: startbcpc in: cogMethod [
	"Answer the zero-relative bytecode pc matching the machine code pc argument in
	 cogMethod, given the start of the bytecodes for cogMethod's block or method object."
	<api>
	<var: #cogMethod type: #'CogBlockMethod *'>
	^self
		mapFor: cogMethod
		bcpc: startbcpc
		performUntil: #find:Mcpc:Bcpc:MatchingMcpc:
		arg: mcpc asVoidPointer
]

{ #category : #'compile abstract instructions' }
SistaStackToRegisterMappingCogit >> compileBlockBodies [
	"override to maintain counterIndex when recompiling blocks; sigh."
	<inline: false>
	| result compiledBlocksCount blockStart savedNeedsFrame savedNumArgs savedNumTemps
	  initialStackPtr initialOpcodeIndex initialAnnotationIndex initialCounterIndex |
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
				 self reinitializeCountersFrom: initialCounterIndex to: counterIndex - 1.
				 self cCode: 'bzero(abstractOpcodes + initialOpcodeIndex,
									(opcodeIndex - initialOpcodeIndex) * sizeof(AbstractInstruction))'
					inSmalltalk: [initialOpcodeIndex to: opcodeIndex - 1 do:
									[:i|
									abstractOpcodes
										at: i
										put: (processor abstractInstructionCompilerClass for: self)]].
				 opcodeIndex := initialOpcodeIndex.
				 annotationIndex := initialAnnotationIndex.
				 counterIndex := initialCounterIndex].
		compiledBlocksCount := compiledBlocksCount + 1].
	needsFrame := savedNeedsFrame.
	methodOrBlockNumArgs := savedNumArgs.
	methodOrBlockNumTemps := savedNumTemps.
	^0
]

{ #category : #'method introspection' }
SistaStackToRegisterMappingCogit >> counterAt: index in: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	"zero-relative counter access"
	^objectMemory longAt: cogMethod asUnsignedInteger + cogMethod blockSize - (cogMethod numCounters - index * CounterBytes)
]

{ #category : #'method introspection' }
SistaStackToRegisterMappingCogit >> counterAt: index put: aValue in: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	"zero-relative counter access"
	^objectMemory
		longAt: cogMethod asUnsignedInteger + cogMethod blockSize - (cogMethod numCounters - index * CounterBytes)
		put: aValue
]

{ #category : #disassembly }
SistaStackToRegisterMappingCogit >> disassembleMethod: surrogateOrAddress on: aStream [
	<doNotGenerate>
	| cogMethod firstCounter |
	cogMethod := super disassembleMethod: surrogateOrAddress on: aStream.
	(cogMethod cmType = CMMethod
	 and: [cogMethod numCounters > 0]) ifTrue:
		[aStream nextPutAll: 'counters:'; cr.
		 firstCounter := cogMethod address + cogMethod blockSize - (cogMethod numCounters * CounterBytes).
		 0 to: cogMethod numCounters - 1 do:
			[:i| | addr |
			 addr := i * CounterBytes + firstCounter.
			 addr printOn: aStream base: 16.
			 aStream nextPut: $:; space.
			 (objectMemory longAt: addr) printOn: aStream base: 16.
			 aStream cr].
		 aStream flush]
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
SistaStackToRegisterMappingCogit >> fillInMethodHeader: method size: size selector: selector [
	super fillInMethodHeader: method size: size selector: selector.
	method numCounters: counterIndex.
	^method
]

{ #category : #'generate machine code' }
SistaStackToRegisterMappingCogit >> fillInOPICHeader: pic size: size numArgs: numArgs selector: selector [
	pic numCounters: 0.
	^super fillInOPICHeader: pic size: size numArgs: numArgs selector: selector
]

{ #category : #'method map' }
SistaStackToRegisterMappingCogit >> find: descriptor Mcpc: mcpc Bcpc: bcpc MatchingBcpc: targetBcpc [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #mcpc type: #'char *'>
	<var: #targetBcpc type: #'void *'>
	^targetBcpc asInteger = bcpc ifTrue: [mcpc asInteger] ifFalse: [0]
]

{ #category : #'method map' }
SistaStackToRegisterMappingCogit >> find: descriptor Mcpc: mcpc Bcpc: bcpc MatchingMcpc: targetMcpc [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #mcpc type: #'char *'>
	<var: #targetMcpc type: #'void *'>
	^targetMcpc = mcpc ifTrue: [bcpc] ifFalse: [0]
]

{ #category : #'method map' }
SistaStackToRegisterMappingCogit >> findMcpc: mcpc Bcpc: bcpc MatchingBcpc: targetBcpc [
	<doNotGenerate>
	self shouldNotImplement
]

{ #category : #'method map' }
SistaStackToRegisterMappingCogit >> findMcpc: mcpc Bcpc: bcpc MatchingMcpc: targetMcpc [
	<doNotGenerate>
	self shouldNotImplement
]

{ #category : #'bytecode generators' }
SistaStackToRegisterMappingCogit >> genJumpIf: boolean to: targetBytecodePC [
	"The heart of performance counting in Sista.  Conditional branches are 6 times less
	 frequent than sends and can provide basic block frequencies (send counters can't).
	 Each conditional has a 32-bit counter split into an upper 16 bits counting executions
	 and a lower half counting untaken executions of the branch.  Executing the branch
	 decrements the upper half, tripping if the count goes negative.  Not taking the branch
	 decrements the lower half.  N.B. We *do not* eliminate dead branches (true ifTrue:/true ifFalse:)
	 so that scanning for send and branch data is simplified and that branch data is correct."
	<inline: false>
	| desc ok counter countTripped retry |
	<var: #desc type: #'CogSimStackEntry *'>
	<var: #ok type: #'AbstractInstruction *'>
	<var: #retry type: #'AbstractInstruction *'>
	<var: #counter type: #'AbstractInstruction *'>
	<var: #countTripped type: #'AbstractInstruction *'>
	self ssFlushTo: simStackPtr - 1.
	desc := self ssTop.
	self ssPop: 1.
	retry := self Label.
	desc popToReg: TempReg.

	self ssAllocateRequiredReg: SendNumArgsReg. "Use this as the count reg."
	counter := self addressOf: (counters at: counterIndex).
	counterIndex := counterIndex + 1.
	self flag: 'will need to use MoveAw32:R: if 64 bits'.
	self assert: BytesPerWord = CounterBytes.
	counter addDependent: (self annotateAbsolutePCRef: (self MoveAw: counter asUnsignedInteger R: SendNumArgsReg)).
	self SubCq: 16r10000 R: SendNumArgsReg. "Count executed"
	"Don't write back if we trip; avoids wrapping count back to initial value, and if we trip we don't execute."
	countTripped := self JumpCarry: 0.
	counter addDependent: (self annotateAbsolutePCRef:
		(self MoveR: SendNumArgsReg Aw: counter asUnsignedInteger)). "write back"

	"Cunning trick by LPD.  If true and false are contiguous subtract the smaller.
	 Correct result is either 0 or the distance between them.  If result is not 0 or
	 their distance send mustBeBoolean."
	self assert: (objectMemory objectAfter: objectMemory falseObject) = objectMemory trueObject.
	self annotate: (self SubCw: boolean R: TempReg) objRef: boolean.
	self JumpZero: (self ensureFixupAt: targetBytecodePC - initialPC).

	self SubCq: 1 R: SendNumArgsReg. "Count untaken"
	counter addDependent: (self annotateAbsolutePCRef:
		(self MoveR: SendNumArgsReg Aw: counter asUnsignedInteger)). "write back"

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
	"If we're in an image which hasn't got the Sista code loaded then the ceCounterTripped: trampoline
	 will return directly to machine code, returning the boolean.  So the code should jump back to the
	 retry point. This is the return address of the non-inlined method that yields the boolean to be tested.
	 If ceCounterTripped: does not return it will examine the branch to retry to reposition the PC to that point."
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
	self compileTrampolineFor: #ceCounterTripped:
		callJumpBar: true
		numArgs: 1
		arg: TempReg
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: nil.
	"For the case where the ceCounterTripped: call returns (e.g. because there's no callback selector
	 installed), the call to the ceSendMustBeBooleanAddTrue/FalseTrampoline is followed by a jump
	 back to the return address of the send that yields the boolean to be tested.  For this case copy
	 the C result to ReceiverResultReg, to reload it with the boolean to be tested."
	backEnd cResultRegister ~= ReceiverResultReg ifTrue:
		[self MoveR: backEnd cResultRegister R: ReceiverResultReg].
	"If the objectRepresentation does want true & false to be mobile then we need to record these addresses."
	self assert: (objectRepresentation shouldAnnotateObjectReference: boolean) not.
	jumpMBB jmpTarget: (self AddCq: boolean R: TempReg).
	^self genTrampolineFor: #ceSendMustBeBoolean:
		called: trampolineName
		callJumpBar: true
		numArgs: 1
		arg: TempReg
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
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
	  rcvrIsInt argIsInt rcvrInt argInt result jumpNotSmallInts inlineCAB annotateInst counter countTripped |
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpNotSmallInts type: #'AbstractInstruction *'>
	<var: #counter type: #'AbstractInstruction *'>
	<var: #countTripped type: #'AbstractInstruction *'>
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
	counter := self addressOf: (counters at: counterIndex).
	self flag: 'will need to use MoveAw32:R: if 64 bits'.
	self assert: BytesPerWord = CounterBytes.
	counter addDependent: (self annotateAbsolutePCRef:
		(self MoveAw: counter asUnsignedInteger R: SendNumArgsReg)).
	self SubCq: 16r10000 R: SendNumArgsReg. "Count executed"
	"If counter trips simply abort the inlined comparison and send continuing to the following
	 branch *without* writing back.  A double decrement will not trip the second time."
	countTripped := self JumpCarry: 0.
	counter addDependent: (self annotateAbsolutePCRef:
		(self MoveR: SendNumArgsReg Aw: counter asUnsignedInteger)). "write back"

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
	counter addDependent: (self annotateAbsolutePCRef:
		(self MoveR: SendNumArgsReg Aw: counter asUnsignedInteger)). "write back"
	self Jump: (self ensureNonMergeFixupAt: postBranchPC - initialPC).
	countTripped jmpTarget: (jumpNotSmallInts jmpTarget: self Label).
	argIsInt ifTrue:
		[self MoveCq: argInt R: Arg0Reg].
	^self genMarshalledSend: (coInterpreter specialSelector: byte0 - self firstSpecialSelectorBytecodeOffset)
		numArgs: 1
]

{ #category : #'bytecode generators' }
SistaStackToRegisterMappingCogit >> genSpecialSelectorEqualsEquals [
	"Override to count inlined branches if followed by a conditional branch.
	 We borrow the following conditional branch's counter and when about to
	 inline the comparison we decrement the counter (without writing it back)
	 and if it trips simply abort the inlining, falling back to the normal send which
	 will then continue to the conditional branch which will trip and enter the abort."
	| nextPC postBranchPC targetBytecodePC primDescriptor branchDescriptor nExts
	  counter countTripped |
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	<var: #counter type: #'AbstractInstruction *'>
	<var: #countTripped type: #'AbstractInstruction *'>
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
	self marshallSendArguments: 1.

	self ssAllocateRequiredReg: SendNumArgsReg. "Use this as the count reg."
	counter := self addressOf: (counters at: counterIndex).
	self flag: 'will need to use MoveAw32:R: if 64 bits'.
	self assert: BytesPerWord = CounterBytes.
	counter addDependent: (self annotateAbsolutePCRef:
		(self MoveAw: counter asUnsignedInteger R: SendNumArgsReg)).
	self SubCq: 16r10000 R: SendNumArgsReg. "Count executed"
	"If counter trips simply abort the inlined comparison and send continuing to the following
	 branch *without* writing back.  A double decrement will not trip the second time."
	countTripped := self JumpCarry: 0.
	counter addDependent: (self annotateAbsolutePCRef:
		(self MoveR: SendNumArgsReg Aw: counter asUnsignedInteger)). "write back"

	self CmpR: Arg0Reg R: ReceiverResultReg.
	"Cmp is weird/backwards so invert the comparison.  Further since there is a following conditional
	 jump bytecode define non-merge fixups and leave the cond bytecode to set the mergeness."
	self gen: (branchDescriptor isBranchTrue ifTrue: [JumpZero] ifFalse: [JumpNonZero])
		operand: (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.
	self SubCq: 1 R: SendNumArgsReg. "Count untaken"
	counter addDependent: (self annotateAbsolutePCRef:
		(self MoveR: SendNumArgsReg Aw: counter asUnsignedInteger)). "write back"
	self Jump: (self ensureNonMergeFixupAt: postBranchPC - initialPC).
	countTripped jmpTarget: self Label.
	^self genMarshalledSend: (coInterpreter specialSelector: byte0 - self firstSpecialSelectorBytecodeOffset)
		numArgs: 1
]

{ #category : #'generate machine code' }
SistaStackToRegisterMappingCogit >> generateCogMethod: selector [
	"We handle jump sizing simply.  First we make a pass that asks each
	 instruction to compute its maximum size.  Then we make a pass that
	 sizes jumps based on the maxmimum sizes.  Then we make a pass
	 that fixes up jumps.  When fixing up a jump the jump is not allowed to
	 choose a smaller offset but must stick to the size set in the second pass.

	 Override to add counters"
	<returnTypeC: #'CogMethod *'>
	| codeSize headerSize mapSize countersSize totalSize startAddress result method |
	<var: #method type: #'CogMethod *'>
	headerSize := self sizeof: CogMethod.
	methodLabel address: headerSize negated.
	self computeMaximumSizes.
	methodLabel concretizeAt: (methodZone allocate: 0).
	codeSize := self generateInstructionsAt: methodLabel address + headerSize.
	mapSize := self generateMapAt: 0 start: methodLabel address + cmNoCheckEntryOffset.
	countersSize := counterIndex * CounterBytes.
	totalSize := methodZone roundUpLength: headerSize + codeSize + mapSize + countersSize.
	totalSize > MaxMethodSize ifTrue:
		[^self cCoerceSimple: MethodTooBig to: #'CogMethod *'].
	startAddress := methodZone allocate: totalSize.
	startAddress = 0 ifTrue:
		[^self cCoerceSimple: InsufficientCodeSpace to: #'CogMethod *'].
	self assert: startAddress + cmEntryOffset = entry address.
	self assert: startAddress + cmNoCheckEntryOffset = noCheckEntry address.
	self regenerateCounterReferences: startAddress + totalSize.
	result := self outputInstructionsAt: startAddress + headerSize.
	self assert: startAddress + headerSize + codeSize = result.
	backEnd nopsFrom: result to: startAddress + totalSize - mapSize.
	self generateMapAt: startAddress + totalSize - countersSize - 1 start: startAddress + cmNoCheckEntryOffset.
	self fillInBlockHeadersAt: startAddress.
	self fillInCounters: counterIndex atEndAddress: startAddress + totalSize.
	method := self fillInMethodHeader: (self cCoerceSimple: startAddress to: #'CogMethod *')
					size: totalSize
					selector: selector.
	postCompileHook notNil ifTrue:
		[self perform: postCompileHook with: method with: primInvokeLabel.
		 postCompileHook := nil].
	processor flushICacheFrom: startAddress to: startAddress + headerSize + codeSize.
	^method
]

{ #category : #'method introspection' }
SistaStackToRegisterMappingCogit >> getJumpTargetPCAt: pc [
	<api>
	^backEnd jumpTargetPCAt: pc
]

{ #category : #'simulation only' }
SistaStackToRegisterMappingCogit >> handleWriteSimulationTrap: aProcessorSimulationTrap [
	<doNotGenerate>
	| address end |
	address := aProcessorSimulationTrap address.
	(address >= methodZone freeStart
	or: [address <= methodZoneBase]) ifTrue:
		[^super handleWriteSimulationTrap: aProcessorSimulationTrap].

	(counterMethodCache isNil
	 or: [address < counterMethodCache
	 or: [counterMethodCache address + counterMethodCache blockSize < address]]) ifTrue:
		[counterMethodCache := methodZone methodFor: address].
	end := counterMethodCache address + counterMethodCache blockSize.
	self assert: (address
					between: end - (CounterBytes * counterMethodCache numCounters)
					and: end).
	objectMemory longAt: address put: (processor perform: aProcessorSimulationTrap registerAccessor).
	processor pc: aProcessorSimulationTrap nextpc
]

{ #category : #initialization }
SistaStackToRegisterMappingCogit >> initialize [
	super initialize.
	cogMethodSurrogateClass := BytesPerWord = 4
											ifTrue: [CogSistaMethodSurrogate32]
											ifFalse: [CogSistaMethodSurrogate64]
]

{ #category : #initialization }
SistaStackToRegisterMappingCogit >> initializeCodeZoneFrom: startAddress upTo: endAddress [
	initialCounterValue := MaxCounterValue.
	numCounters := 0.
	self allocateCounters.
	super initializeCodeZoneFrom: startAddress upTo: endAddress
]

{ #category : #initialization }
SistaStackToRegisterMappingCogit >> initializeCounters [
	"Initialize the counter labels for the current compilation.  We give them bogus
	 addresses since we can't determine their address until after the map is generated.
	 So we have to regenerate their dependent instructions after map generation."
	self reinitializeCountersFrom: 0 to: numCounters - 1.
	counterIndex := 0
]

{ #category : #'method map' }
SistaStackToRegisterMappingCogit >> mapFor: cogMethod bcpc: startbcpc performUntil: functionSymbol arg: arg [
	"Machine-code <-> bytecode pc mapping support.  Evaluate functionSymbol
	 for each mcpc, bcpc pair in the map until the function returns non-zero,
	 answering that result, or 0 if it fails to.  This works only for frameful methods."
	<var: #cogMethod type: #'CogBlockMethod *'>
	<var: #functionSymbol declareC: 'sqInt (*functionSymbol)(BytecodeDescriptor * desc, char *mcpc, sqInt bcpc, void *arg)'>
	<var: #arg type: #'void *'>
	| isInBlock mcpc bcpc endbcpc map mapByte homeMethod aMethodObj result
	  latestContinuation byte descriptor bsOffset nExts |
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
			 self assert: ((objectMemory byteAt: map) >> AnnotationShift = IsAbsPCReference
						 or: [(objectMemory byteAt: map) >> AnnotationShift = IsObjectReference
						 or: [(objectMemory byteAt: map) >> AnnotationShift = IsRelativeCall
						 or: [(objectMemory byteAt: map) >> AnnotationShift = IsDisplacementX2N]]]).
			 latestContinuation := startbcpc.
			 aMethodObj := homeMethod methodObject.
			 endbcpc := (objectMemory byteLengthOf: aMethodObj) - 1.
			 bsOffset := self bytecodeSetOffsetForHeader: homeMethod methodHeader]
		ifFalse:
			[isInBlock := true.
			 homeMethod := cogMethod cmHomeMethod.
			 map := self findMapLocationForMcpc: cogMethod asUnsignedInteger + (self sizeof: CogBlockMethod)
						inMethod: homeMethod.
			 self assert: map ~= 0.
			 self assert: ((objectMemory byteAt: map) >> AnnotationShift = HasBytecodePC "fiducial"
						 or: [(objectMemory byteAt: map) >> AnnotationShift = IsDisplacementX2N]).
			 [(objectMemory byteAt: map) >> AnnotationShift ~= HasBytecodePC] whileTrue:
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
	"as a hack for collecting counters, remember the prev mcpc in a static variable."
	prevMapAbsPCMcpc := 0.
	"The stack check maps to the start of the first bytecode,
	 the first bytecode being effectively after frame build."
	result := self perform: functionSymbol
					with: nil
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
				[| annotation nextBcpc |
				annotation := mapByte >> AnnotationShift.
				mcpc := mcpc + (mapByte bitAnd: DisplacementMask).
				(self isPCMappedAnnotation: annotation alternateInstructionSet: bsOffset > 0) ifTrue:
					[[byte := (objectMemory fetchByte: bcpc ofObject: aMethodObj) + bsOffset.
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
					"All subsequent bytecodes except backward branches map to the
					 following bytecode. Backward branches map to themselves other-
					 wise mapping could cause premature breaking out of loops." 
					result := self perform: functionSymbol
									with: descriptor
									with: (self cCoerceSimple: mcpc to: #'char *')
									with: ((descriptor isBranch
										   and: [self isBackwardBranch: descriptor at: bcpc exts: nExts in: aMethodObj])
											ifTrue: [bcpc]
											ifFalse: [bcpc + descriptor numBytes])
									with: arg.
					 result ~= 0 ifTrue:
						[^result].
					 bcpc := nextBcpc.
					 nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0]].
				annotation = IsAbsPCReference ifTrue:
					[self assert: mcpc ~= 0.
					 prevMapAbsPCMcpc := mcpc]]
			ifFalse:
				[mcpc := mcpc + (mapByte >= DisplacementX2N
									ifTrue: [mapByte - DisplacementX2N << AnnotationShift]
									ifFalse: [mapByte])].
		 map := map - 1].
	^0
]

{ #category : #'method map' }
SistaStackToRegisterMappingCogit >> mapStartFor: cogMethod [
	"Answer the address of the first byte of the method map."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	^cogMethod asUnsignedInteger + cogMethod blockSize - (cogMethod numCounters * CounterBytes) - 1
]

{ #category : #'compile abstract instructions' }
SistaStackToRegisterMappingCogit >> maybeAllocAndInitCounters [
	<inline: true>
	self allocateCounters; initializeCounters
]

{ #category : #'method map' }
SistaStackToRegisterMappingCogit >> mcPCFor: bcpc startBcpc: startbcpc in: cogMethod [
	"Answer the absolute machine code pc matching the zero-relative bytecode pc argument
	 in cogMethod, given the start of the bytecodes for cogMethod's block or method object."
	<api>
	<var: #cogMethod type: #'CogBlockMethod *'>
	| absPC |
	absPC := self
				mapFor: cogMethod
				bcpc: startbcpc
				performUntil: #find:Mcpc:Bcpc:MatchingBcpc:
				arg: bcpc asVoidPointer.
	^absPC ~= 0
		ifTrue: [absPC asUnsignedInteger - cogMethod asUnsignedInteger]
		ifFalse: [absPC]
]

{ #category : #'method introspection' }
SistaStackToRegisterMappingCogit >> picDataFor: descriptor Mcpc: mcpc Bcpc: bcpc Method: cogMethodArg [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #mcpc type: #'char *'>
	<var: #cogMethodArg type: #'void *'>
	| entryPoint tuple |
	descriptor isNil ifTrue:
		[^0].
	descriptor isBranch ifTrue:
		["it's a branch; conditional?"
		 (descriptor isBranchTrue or: [descriptor isBranchFalse]) ifTrue:
			[tuple := self picDataForConditionalBranch: prevMapAbsPCMcpc at: bcpc.
			 tuple = 0 ifTrue: [^PrimErrNoMemory].
			 objectMemory storePointer: picDataIndex ofObject: picData withValue: tuple.
			 picDataIndex := picDataIndex + 1].
		 ^0].
	"infer it's a send; alas we can't just test the descriptor because of the bloody
	 doubleExtendedDoAnythingBytecode which does sends as well as other things."
	(backEnd isCallPreceedingReturnPC: mcpc asUnsignedInteger) ifFalse:
		[^0].
	entryPoint := backEnd callTargetFromReturnAddress: mcpc asUnsignedInteger.
	entryPoint <= methodZoneBase ifTrue: "send is not linked, or is not a send"
		[^0].
	self targetMethodAndSendTableFor: entryPoint into: "It's a linked send; find which kind."
		[:targetMethod :sendTable|
		 tuple := self picDataForSendTo: targetMethod
					methodClassIfSuper: (sendTable = superSendTrampolines ifTrue:
												[coInterpreter methodClassOf:
													(self cCoerceSimple: cogMethodArg to: #'CogMethod *') methodObject])
					at: mcpc
					bcpc: bcpc + 1 - descriptor numBytes].
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
	picDataIndex := 0.
	picData := arrayObj.
	errCode := self
					mapFor: (self cCoerceSimple: cogMethod to: #'CogBlockMethod *')
					bcpc: (coInterpreter startPCOfMethod: cogMethod methodObject)
					performUntil: #picDataFor:Mcpc:Bcpc:Method:
					arg: cogMethod asVoidPointer.
	errCode ~= 0 ifTrue:
		[self assert: errCode = PrimErrNoMemory.
		 ^-1].
	cogMethod blockEntryOffset ~= 0 ifTrue:
		[errCode := self blockDispatchTargetsFor: cogMethod
						perform: #picDataForBlockEntry:Method:
						arg: cogMethod asVoidPointer.
		 errCode ~= 0 ifTrue:
			[self assert: errCode = PrimErrNoMemory.
			 ^-1]].
	^picDataIndex
]

{ #category : #'method introspection' }
SistaStackToRegisterMappingCogit >> picDataForBlockEntry: blockEntryMcpc Method: cogMethod [
	"Collect the branch and send data for the block method starting at blockEntryMcpc, storing it into picData."
	| cogBlockMethod |
	<var: #cogBlockMethod type: #'CogBlockMethod *'>
	cogBlockMethod := self cCoerceSimple: blockEntryMcpc - (self sizeof: CogBlockMethod)
							  to: #'CogBlockMethod *'.
	cogBlockMethod stackCheckOffset = 0 ifTrue:
		[^0].
	^self
		mapFor: cogBlockMethod
		bcpc: cogBlockMethod startpc
		performUntil: #picDataFor:Mcpc:Bcpc:Method:
		arg: cogMethod
]

{ #category : #'method introspection' }
SistaStackToRegisterMappingCogit >> picDataForConditionalBranch: counterReferenceMcpc at: bcpc [
	| address counter executedCount tuple untakenCount |
	<var: #counter type: #'unsigned long'>
	tuple := objectMemory
				eeInstantiateClassIndex: ClassArrayCompactIndex
				format: objectMemory arrayFormat
				numSlots: 3.
	tuple = 0 ifTrue:
		[^0].
	self assert: CounterBytes = 4.
	address := backEnd counterTargetFromFollowingAddress: counterReferenceMcpc.
	counter := objectMemory longAt: address.
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
	| tuple |
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
		[objectMemory
			storePointer: 1
				ofObject: tuple
					withValue: (methodClassOrNil ifNil:
								[objectRepresentation classForInlineCacheTag: (backEnd inlineCacheTagAt: sendMcpc asUnsignedInteger)]);
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
SistaStackToRegisterMappingCogit >> print: desc Mcpc: mcpc Bcpc: bcpc on: aStream [
	<doNotGenerate>
	aStream ensureCr.
	mcpc printOn: aStream base: 16.
	aStream space; tab; print: bcpc; cr; flush.
	^0
]

{ #category : #'simulation only' }
SistaStackToRegisterMappingCogit >> printCountersFor: cogMethod on: aStream [
	| firstCounter |
	firstCounter := cogMethod address + cogMethod blockSize - (cogMethod numCounters * CounterBytes).
	0 to: cogMethod numCounters - 1 do:
		[:i| | addr |
		addr := i * CounterBytes + firstCounter.
		addr printOn: aStream base: 16.
		aStream nextPut: $:; space.
		(objectMemory longAt: addr) printOn: aStream base: 16.
		aStream cr]
]

{ #category : #'method map' }
SistaStackToRegisterMappingCogit >> printMcpc: mcpc Bcpc: bcpc on: aStream [
	<doNotGenerate>
	self shouldNotImplement
]

{ #category : #'method map' }
SistaStackToRegisterMappingCogit >> printPCMapPairsFor: cogMethod on: aStream [
	<doNotGenerate>
	(self subMethodsAsRangesFor: cogMethod)
		do: [:sm|
			self mapFor: sm cogMethod bcpc: sm startpc performUntil: #print:Mcpc:Bcpc:on: arg: aStream]
		separatedBy: [aStream tab; next: 2 put: $=; cr]
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

{ #category : #'generate machine code' }
SistaStackToRegisterMappingCogit >> regenerateCounterReferences: methodEndAddress [
	<var: #label type: #'AbstractInstruction *'>
	<var: #dependentInstruction type: #'AbstractInstruction *'>
	0 to: counterIndex - 1 do:
		[:i| | label dependentInstruction |
		label := self addressOf: (counters at: i).
		label address: methodEndAddress - ((counterIndex - i) * CounterBytes).
		dependentInstruction := label dependent.
		[dependentInstruction concretizeAt: dependentInstruction address.
		 dependentInstruction := dependentInstruction dependent.
		 dependentInstruction ~= nil] whileTrue]
]

{ #category : #initialization }
SistaStackToRegisterMappingCogit >> reinitializeCountersFrom: start to: stop [
	"Reinitialize the counter labels in the given range.  We give them bogus
	 addresses since we can't determine their address until after the map
	 is generated.  So we have to regenerate their dependent instructions
	 after map generation."
	| label |
	<var: #label type: #'AbstractInstruction *'>
	start to: stop do:
		[:i|
		label := self addressOf: (counters at: i).
		label
			opcode: Label;
			dependent: nil;
			address: methodZone zoneEnd - (numCounters + i * CounterBytes)]
]

{ #category : #'sista callbacks' }
SistaStackToRegisterMappingCogit >> resetCountersIn: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<api>
	self
		fillInCounters: cogMethod numCounters
		atEndAddress: cogMethod asUnsignedInteger + cogMethod blockSize
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
				ifFalse:
					[latestContinuation := latestContinuation max: targetPC.
					 (descriptor isBranchTrue or: [descriptor isBranchFalse]) ifTrue:
						[numCounters := numCounters + 1]]].
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
