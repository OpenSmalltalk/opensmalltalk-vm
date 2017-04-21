"
A SistaCogit is a refinement of RegisterAllocatingCogit that generates code suitable for dynamic optimization by Sista, the Speculative Inlining Smalltalk Architecture, a project by Clément Bera and Eliot Miranda.  Sista is an optimizer that exists in the Smalltalk image, /not/ in the VM,  and optimizes by substituting normal bytecoded methods by optimized bytecoded methods that may use special bytecodes for which the Cogit can generate faster code.  These bytecodes eliminate overheads such as bounds checks or polymorphic code (indexing Array, ByteArray, String etc).  But the bulk of the optimization performed is in inlining blocks and sends for the common path.

The basic scheme is that SistaCogit generates code containing performance counters.  When these counters trip, a callback into the image is performed, at which point Sista analyses some portion of the stack, looking at performance data for the methods on the stack, and optimises based on the stack and performance data.  Execution then resumes in the optimized code.

SistaCogit adds counters to conditional branches.  Each branch has an executed and a taken count, implemented at the two 16-bit halves of a single 32-bit word.  Each counter pair is initialized with initialCounterValue.  On entry to the branch the executed count is decremented and if the count goes below zero the ceMustBeBooleanAdd[True|False] trampoline called.  The trampoline distinguishes between true mustBeBoolean and counter trips because in the former the register temporarily holding the counter value will contain zero.  Then the condition is tested, and if the branch is taken the taken count is decremented.  The two counter values allow an optimizer to collect basic block execution paths and to know what are the ""hot"" paths through execution that are worth agressively optimizing.  Since conditional branches are about 1/6 as frequent as sends, and since they can be used to determine the hot path through code, they are a better choice to count than, for example, method or block entry.

SistaCogit implements picDataFor:into: that fills an Array with the state of the counters in a method and the state of each linked send in a method.  This is used to implement a primitive used by the optimizer to answer the branch and send data for a method as an Array.

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
	#name : #SistaCogit,
	#superclass : #StackToRegisterMappingCogit,
	#instVars : [
		'numCounters',
		'counters',
		'counterIndex',
		'initialCounterValue',
		'ceTrapTrampoline',
		'branchReachedOnlyForCounterTrip'
	],
	#classVars : [
		'CounterBytes',
		'MaxCounterValue'
	],
	#pools : [
		'VMSqueakClassIndices'
	],
	#category : 'VMMaker-JIT'
}

{ #category : #translation }
SistaCogit class >> additionalHeadersDo: aBinaryBlock [
	"Evaluate aBinaryBlock with the names and contents of
	 any additional header files that need to be generated."
	aBinaryBlock
		value: 'cogmethod.h'
		value: SistaCogMethod cogMethodHeader
]

{ #category : #translation }
SistaCogit class >> ancilliaryClasses: options [
	^(super ancilliaryClasses: options) copyWith: SistaCogMethod
]

{ #category : #translation }
SistaCogit class >> declareCVarsIn: aCodeGen [
	aCodeGen var: 'counters' type: #usqInt
]

{ #category : #'class initialization' }
SistaCogit class >> initializeWithOptions: optionsDictionary [

	super initializeWithOptions: optionsDictionary.
	CounterBytes := 4.
	MaxCounterValue := (1 << 16) - 1
]

{ #category : #'accessing class hierarchy' }
SistaCogit class >> methodZoneClass [
	^SistaMethodZone
]

{ #category : #accessing }
SistaCogit class >> numTrampolines [
	^super numTrampolines + 1

	"Cogit withAllSubclasses collect: [:c| {c. (c instVarNames select: [:ea| ea beginsWith: 'ce']) size}]"
	"self instVarNames select: [:ea| ea beginsWith: 'ce']"
]

{ #category : #'in-line cacheing' }
SistaCogit >> allowEarlyOpenPICPromotion [
	<inline: true>
	^ false
]

{ #category : #'compile abstract instructions' }
SistaCogit >> compileCogFullBlockMethod: numCopied [
	<option: #SistaV1BytecodeSet>
	counters := 0.
	^super compileCogFullBlockMethod: numCopied
]

{ #category : #'compile abstract instructions' }
SistaCogit >> compileCogMethod: selector [
	counters := 0.
	^super compileCogMethod: selector
]

{ #category : #'compile abstract instructions' }
SistaCogit >> compileFrameBuild [
	"Override to prefetch counters, if any."
	super compileFrameBuild.
	counters ~= 0 ifTrue:
		[self PrefetchAw: counters]
]

{ #category : #'compile abstract instructions' }
SistaCogit >> compileFullBlockMethodFrameBuild: numCopied [
	"Override to prefetch counters if any"
	super compileFullBlockMethodFrameBuild: numCopied.
	counters ~= 0 ifTrue:
		[self PrefetchAw: counters]
]

{ #category : #accessing }
SistaCogit >> defaultCogCodeSize [
	"Return the default number of bytes to allocate for native code at startup.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file."
	<api>
	^2 * backEnd getDefaultCogCodeSize
]

{ #category : #disassembly }
SistaCogit >> disassembleMethod: surrogateOrAddress on: aStream [
	<doNotGenerate>
	| cogMethod |
	cogMethod := super disassembleMethod: surrogateOrAddress on: aStream.
	(cogMethod cmType = CMMethod
	 and: [cogMethod counters ~= 0]) ifTrue:
		[aStream nextPutAll: 'counters:'; cr.
		 0 to: (objectRepresentation numCountersFor: cogMethod counters) - 1 do:
			[:i| | addr |
			 addr := i * CounterBytes + counters.
			 addr printOn: aStream base: 16.
			 aStream nextPut: $:; space.
			 (objectMemory long32At: addr) printOn: aStream base: 16.
			 aStream cr].
		 aStream flush]
]

{ #category : #accessing }
SistaCogit >> estimateOfAbstractOpcodesPerBytecodes [
	"Due to the counter logic, the estimation is higher"
	<inline: true>
	^ 11
]

{ #category : #'generate machine code' }
SistaCogit >> fillInCPICHeader: pic numArgs: numArgs numCases: numCases hasMNUCase: hasMNUCase selector: selector [
	pic counters: 0.
	^super fillInCPICHeader: pic numArgs: numArgs numCases: numCases hasMNUCase: hasMNUCase selector: selector
]

{ #category : #'generate machine code' }
SistaCogit >> fillInCounters: nCounters atEndAddress: endAddress [
	endAddress - (nCounters * CounterBytes)
		to: endAddress - CounterBytes
		by: CounterBytes
		do: [:address|
			objectMemory
				long32At: address
				put: (initialCounterValue << 16 + initialCounterValue)]
]

{ #category : #'generate machine code' }
SistaCogit >> fillInCounters: nCounters atStartAddress: startAddress [
	startAddress
		to: startAddress + (nCounters - 1 * CounterBytes)
		by: CounterBytes
		do: [:address|
			objectMemory
				long32At: address
				put: (initialCounterValue << 16 + initialCounterValue)]
]

{ #category : #'generate machine code' }
SistaCogit >> fillInMethodHeader: method size: size selector: selector [
	super fillInMethodHeader: method size: size selector: selector.
	self fillInCounters: numCounters atStartAddress: counters.
	method counters: counters.
	^method
]

{ #category : #'generate machine code' }
SistaCogit >> fillInOPICHeader: pic numArgs: numArgs selector: selector [
	pic counters: 0.
	^super fillInOPICHeader: pic numArgs: numArgs selector: selector
]

{ #category : #'inline primitive generators' }
SistaCogit >> genAtPutInlinePrimitive: prim [
	"Unary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#trinaryInlinePrimitive:"
	| ra1 ra2 rr adjust needsStoreCheck |
	"The store check requires rr to be ReceiverResultReg"
	needsStoreCheck := (objectRepresentation isUnannotatableConstant: self ssTop) not.
	self 
		allocateRegForStackTopThreeEntriesInto: [:rTop :rNext :rThird | ra2 := rTop. ra1 := rNext. rr := rThird ] 
		thirdIsReceiver: (prim = 0 and: [ needsStoreCheck ]).
	self assert: (rr ~= ra1 and: [rr ~= ra2 and: [ra1 ~= ra2]]).
	self ssTop popToReg: ra2.
	self ssPop: 1.
	self ssTop popToReg: ra1.
	self ssPop: 1.
	self ssTop popToReg: rr.
	self ssPop: 1.
	objectRepresentation genConvertSmallIntegerToIntegerInReg: ra1.
	"Now: ra is the variable object, rr is long, TempReg holds the value to store."
	self flag: #TODO. "This is not really working as the immutability and store check needs to be present. "
	prim caseOf: {
		"0 - 1 pointerAt:put: and byteAt:Put:"
		[0] ->	[ adjust := (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
				adjust ~= 0 ifTrue: [ self AddCq: adjust R: ra1. ]. 
				self MoveR: ra2 Xwr: ra1 R: rr.
				"I added needsStoreCheck so if you initialize an array with a Smi such as 0 or a boolean you don't need the store check"
				needsStoreCheck ifTrue: 
					[ self assert: needsFrame. 
					objectRepresentation genStoreCheckReceiverReg: rr valueReg: ra2 scratchReg: TempReg inFrame: true] ].
		[1] ->	[ objectRepresentation genConvertSmallIntegerToIntegerInReg: ra2.
				adjust := objectMemory baseHeaderSize - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
				self AddCq: adjust R: ra1.
				self MoveR: ra2 Xbr: ra1 R: rr.
				objectRepresentation genConvertIntegerToSmallIntegerInReg: ra2. ].
	}
	otherwise: [^EncounteredUnknownBytecode].
	self ssPushRegister: ra2.
	^0
]

{ #category : #'inline primitive generators' }
SistaCogit >> genBinaryConstOpVarInlinePrimitive: prim [
	"Const op var version of binary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#binaryInlinePrimitive:"
	<option: #SistaVM>
	| ra val untaggedVal adjust |
	ra := self allocateRegForStackEntryAt: 0.
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
		[2]	->	[objectRepresentation genShiftAwaySmallIntegerTagsInScratchReg: ra.
				 self MoveCq: untaggedVal R: TempReg.
				 self MulR: TempReg R: ra.
				 objectRepresentation genSetSmallIntegerTagsIn: ra].

		"2011 through 2015	Variable-sized pointers new, byte new, 16-bit new, 32-bit new, 64-bit new"

		"2016 through 2020, bitAnd:, bitOr:, bitXor, bitShiftLeft:, bitShiftRight:, SmallInteger op SmallInteger => SmallInteger, no overflow"
		[16] -> [ self AndCq: val R: ra ].
		[17] -> [ self OrCq: val R: ra ].
		[18] -> [ self XorCw: untaggedVal R: ra. ].
		[19] -> [ objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				 self MoveCq: untaggedVal R: TempReg.
				 self LogicalShiftLeftR: ra R: TempReg.
				 objectRepresentation genAddSmallIntegerTagsTo: TempReg.
				 self MoveR: TempReg R: ra].
		[20] ->	[objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				 self MoveCq: untaggedVal R: TempReg.
				 self ArithmeticShiftRightR: ra R: TempReg.
				 objectRepresentation genClearAndSetSmallIntegerTagsIn: TempReg.
				 self MoveR: TempReg R: ra].

		"2032	through 2037, >, <, >=, <=. =, ~=, SmallInteger op SmallInteger => Boolean (flags?? then in jump bytecodes if ssTop is a flags value, just generate the instruction!!)"
		"CmpCqR is SubRCq so everything is reversed, but because no CmpRCq things are reversed again and we invert the sense of the jumps."
		[32] -> [ self CmpCq: val R: ra.
				self genBinaryInlineComparison: JumpLess opFalse: JumpGreaterOrEqual destReg: ra ].
		[33] -> [ self CmpCq: val R: ra.
				self genBinaryInlineComparison: JumpGreater opFalse: JumpLessOrEqual destReg: ra ].
		[34] -> [ self CmpCq: val R: ra.
				self genBinaryInlineComparison: JumpLessOrEqual opFalse: JumpGreater destReg: ra ].
		[35] -> [ self CmpCq: val R: ra.
				self genBinaryInlineComparison: JumpGreaterOrEqual opFalse: JumpLess destReg: ra ].
		[36] -> [ self CmpCq: val R: ra.
				self genBinaryInlineComparison: JumpZero opFalse: JumpNonZero destReg: ra ].
		[37] -> [ self CmpCq: val R: ra.
				self genBinaryInlineComparison: JumpNonZero opFalse: JumpZero destReg: ra ].

		"2064	through 2068, Pointer Object>>at:, Byte Object>>at:, Short16 Word Object>>at: LongWord32 Object>>at: Quad64Word Object>>at:. obj op 0-rel SmallInteger => oop"
		[64] ->	[objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				adjust := (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
				adjust ~= 0 ifTrue: [ self AddCq: adjust R: ra. ]. 
				self genMoveConstant: val R: TempReg.
				self MoveXwr: ra R: TempReg R: ra].
		[65] ->	[objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				adjust := objectMemory baseHeaderSize - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
				self AddCq: adjust R: ra.
				self genMoveConstant: val R: TempReg.
				self MoveXbr: ra R: TempReg R: ra.
				objectRepresentation genConvertIntegerToSmallIntegerInReg: ra]
	}
	otherwise: [^EncounteredUnknownBytecode].
	self ssPushRegister: ra.
	^0
]

{ #category : #'inline primitive generators' }
SistaCogit >> genBinaryInlineComparison: opTrue opFalse: opFalse destReg: destReg [
	"Inlined comparison. opTrue = jump for true and opFalse = jump for false"
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	| nextPC branchDescriptor targetBytecodePC postBranchPC |	
		
	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetBytecodePC := target ].

	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse])
		ifTrue: "This is the path where the inlined comparison is followed immediately by a branch"
			[ (self fixupAt: nextPC) notAFixup
				ifTrue: "The next instruction is dead.  we can skip it."
					[deadCode := true.
				 	 self ensureFixupAt: targetBytecodePC.
					 self ensureFixupAt: postBranchPC ]
				ifFalse:
					[self ssPushConstant: objectMemory trueObject]. "dummy value"
			self genConditionalBranch: (branchDescriptor isBranchTrue ifTrue: [opTrue] ifFalse: [opFalse])
				operand: (self ensureNonMergeFixupAt: targetBytecodePC) asUnsignedInteger.
			"We can only elide the jump if the pc after nextPC is the same as postBranchPC.
			 Branch following means it may not be."
			self nextDescriptorExtensionsAndNextPCInto:
				[:iguana1 :iguana2 :iguana3 :followingPC| nextPC := followingPC].
			(deadCode and: [nextPC = postBranchPC]) ifFalse:
				[ self Jump: (self ensureNonMergeFixupAt: postBranchPC) ] ]
		ifFalse: "This is the path where the inlined comparison is *not* followed immediately by a branch"
			[| condJump jump |
			condJump := self genConditionalBranch: opTrue operand: 0.
			self genMoveFalseR: destReg.
	 		jump := self Jump: 0.
			condJump jmpTarget: (self genMoveTrueR: destReg).
			jump jmpTarget: self Label].
	^ 0
]

{ #category : #'inline primitive generators' }
SistaCogit >> genBinaryVarOpConstInlinePrimitive: prim [
	"Var op const version of inline binary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#binaryInlinePrimitive:"
	<option: #SistaVM>
	| rr val untaggedVal |
	val := self ssTop constant.
	self ssPop: 1.
	rr := self allocateRegForStackEntryAt: 0.
	self ssTop popToReg: rr.
	self ssPop: 1.
	untaggedVal := val - objectMemory smallIntegerTag.
	prim caseOf: {
		"0 through 6, +, -, *, /, //, \\, quo:, SmallInteger op SmallInteger => SmallInteger, no overflow"
		[0]	->	[self AddCq: untaggedVal R: rr].
		[1]	->	[self SubCq: untaggedVal R: rr ].
		[2]	->	[self flag: 'could use MulCq:R'.
				 objectRepresentation genShiftAwaySmallIntegerTagsInScratchReg: rr.
				 self MoveCq: untaggedVal R: TempReg.
				 self MulR: TempReg R: rr.
				 objectRepresentation genSetSmallIntegerTagsIn: rr].

		"2016 through 2020, bitAnd:, bitOr:, bitXor, bitShiftLeft:, bitShiftRight:, SmallInteger op SmallInteger => SmallInteger, no overflow"
		[16] -> [ self AndCq: val R: rr ].
		[17] -> [ self OrCq: val R: rr ].
		[18] -> [ self flag: 'could use XorCq:'.
				self XorCw: untaggedVal R: rr. ].
		[19] -> [ objectRepresentation genRemoveSmallIntegerTagsInScratchReg: rr.
				 self LogicalShiftLeftCq: (objectMemory integerValueOf: val) R: rr.
				 objectRepresentation genAddSmallIntegerTagsTo: rr ].
		[20] ->	[self ArithmeticShiftRightCq: (objectMemory integerValueOf: val) R: rr.
				 objectRepresentation genClearAndSetSmallIntegerTagsIn: rr].

		"2032	through 2037, >, <, >=, <=. =, ~=, SmallInteger op SmallInteger => Boolean (flags?? then in jump bytecodes if ssTop is a flags value, just generate the instruction!!)"
		"CmpCqR is SubRCq so everything is reversed."
		[32] -> [ self CmpCq: val R: rr.
				self genBinaryInlineComparison: JumpGreater opFalse: JumpLessOrEqual destReg: rr ].
		[33] -> [ self CmpCq: val R: rr.
				self genBinaryInlineComparison: JumpLess opFalse: JumpGreaterOrEqual destReg: rr ].
		[34] -> [ self CmpCq: val R: rr.
				self genBinaryInlineComparison: JumpGreaterOrEqual opFalse: JumpLess destReg: rr ].
		[35] -> [ self CmpCq: val R: rr.
				self genBinaryInlineComparison: JumpLessOrEqual opFalse: JumpGreater destReg: rr ].
		[36] -> [ self CmpCq: val R: rr.
				self genBinaryInlineComparison: JumpZero opFalse: JumpNonZero destReg: rr ].
		[37] -> [ self CmpCq: val R: rr.
				self genBinaryInlineComparison: JumpNonZero opFalse: JumpZero destReg: rr ].

		"2064	through 2068, Pointer Object>>at:, Byte Object>>at:, Short16 Word Object>>at: LongWord32 Object>>at: Quad64Word Object>>at:. obj op 0-rel SmallInteger => oop"
		[64] ->	[objectRepresentation genLoadSlot: (objectMemory integerValueOf: val) - 1 sourceReg: rr destReg: rr].
		[65] ->	[self MoveCq: (objectMemory integerValueOf: val) + objectMemory baseHeaderSize - 1 R: TempReg.
				self MoveXbr: TempReg R: rr R: rr.
				objectRepresentation genConvertIntegerToSmallIntegerInReg: rr]

	}
	otherwise: [^EncounteredUnknownBytecode].
	self ssPushRegister: rr.
	^0
]

{ #category : #'inline primitive generators' }
SistaCogit >> genBinaryVarOpVarInlinePrimitive: prim [
	"Var op var version of binary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#binaryInlinePrimitive:"
	<option: #SistaVM>
	| ra rr adjust |
	self allocateRegForStackTopTwoEntriesInto: [:rTop :rNext | ra := rTop. rr := rNext ].
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
		[2]	->	[self genShiftAwaySmallIntegerTagsInScratchReg: rr.
				 self genRemoveSmallIntegerTagsInScratchReg: ra.
				 self MulR: ra R: rr.
				 self genSetSmallIntegerTagsIn: rr].
		"[4]	->	[].
		[5]	->	[].
		[6]	->	[]."

		"2016 through 2020, bitAnd:, bitOr:, bitXor, bitShiftLeft:, bitShiftRight:, SmallInteger op SmallInteger => SmallInteger, no overflow"
		[16] -> [ self AndR: ra R: rr ].
		[17] -> [ self OrR: ra R: rr ].
		[18] -> [objectRepresentation genRemoveSmallIntegerTagsInScratchReg: ra. 
				self XorR: ra R: rr. ].
		[19] -> [ objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				 objectRepresentation genRemoveSmallIntegerTagsInScratchReg: rr.
				 self LogicalShiftLeftR: ra R: rr.
				 objectRepresentation genAddSmallIntegerTagsTo: rr].
		[20] ->	[objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				 self ArithmeticShiftRightR: ra R: rr.
				 objectRepresentation genClearAndSetSmallIntegerTagsIn: rr.].


		"2032	through 2037, >, <, >=, <=. =, ~=, SmallInteger op SmallInteger => Boolean (flags?? then in jump bytecodes if ssTop is a flags value, just generate the instruction!!)"
		"CmpCqR is SubRCq so everything is reversed."
		[32] -> [ self CmpR: ra R: rr.
				self genBinaryInlineComparison: JumpGreater opFalse: JumpLessOrEqual destReg: rr ].
		[33] -> [ self CmpR: ra R: rr.
				self genBinaryInlineComparison: JumpLess opFalse: JumpGreaterOrEqual destReg: rr ].
		[34] -> [ self CmpR: ra R: rr.
				self genBinaryInlineComparison: JumpGreaterOrEqual opFalse: JumpLess destReg: rr ].
		[35] -> [ self CmpR: ra R: rr.
				self genBinaryInlineComparison: JumpLessOrEqual opFalse: JumpGreater destReg: rr ].
		[36] -> [ self CmpR: ra R: rr.
				self genBinaryInlineComparison: JumpZero opFalse: JumpNonZero destReg: rr ].
		[37] -> [ self CmpR: ra R: rr.
				self genBinaryInlineComparison: JumpNonZero opFalse: JumpZero destReg: rr ].

		"2064	through 2068, Pointer Object>>at:, Byte Object>>at:, Short16 Word Object>>at: LongWord32 Object>>at: Quad64Word Object>>at:. obj op 0-rel SmallInteger => oop"
		[64] ->	[objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				adjust := (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
				adjust ~= 0 ifTrue: [ self AddCq: adjust R: ra. ]. 
				self MoveXwr: ra R: rr R: rr ].
		[65] ->	[objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				adjust := objectMemory baseHeaderSize - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
				self AddCq: adjust R: ra.
				self MoveXbr: ra R: rr R: rr.
				objectRepresentation genConvertIntegerToSmallIntegerInReg: rr]

	}
	otherwise: [^EncounteredUnknownBytecode].
	self ssPushRegister: rr.
	^0
]

{ #category : #'inline primitive generators' }
SistaCogit >> genByteEqualsInlinePrimitive: prim [

	"3021	Byte Object >> equals:length:	
	The receiver and the arguments are both byte objects and have both the same size (length in bytes). 
	The length argument is a smallinteger. 
	Answers true if all fields are equal, false if not. 
	Comparison is bulked to word comparison."
	
	"Overview: 
	 1.	The primitive is called like that: [byteObj1 equals: byteObj2 length: length].
	  	In the worst case we use 5 registers including TempReg 
		and we produce a loop bulk comparing words.
	 2.	The common case is a comparison against a cst: [byteString = 'foo'].
		which produces in Scorch [byteString equals: 'foo' length: 3].
		We try to generate fast code for this case with 3 heuristics:
		- specific fast code if len is a constant
		- unroll the loop if len < 2 * wordSize
		- compile-time reads if str1 or str2 is a constant and loop is unrolled.
		We use 3 registers including TempReg in the common case. 
		We could use 1 less reg if the loop is unrolled, the instr is followed by a branch
		AND one operand is a constant, but this is complicated enough.
	3.	We ignore the case where all operands are constants 
		(We assume Scorch simplifies it, it works but it is not optimised)"
		
	| str1Reg str2Reg lenReg extraReg jmp jmp2 needjmpZeroSize needLoop unroll jmpZeroSize instr lenCst mask |
	<var: #jmp type: #'AbstractInstruction *'>
	<var: #instr type: #'AbstractInstruction *'>
	<var: #jmp2 type: #'AbstractInstruction *'>
	<var: #jmpZeroSize type: #'AbstractInstruction *'>

	"--- quick path for empty string---"
	"This path does not allocate registers and right shift on negative int later in the code.
	 Normally this is resolved by Scorch but we keep it for correctness and consistency"
	self ssTop type = SSConstant ifTrue: 
		[ lenCst := objectMemory integerValueOf: self ssTop constant.
		  lenCst = 0 ifTrue: [ self ssPop: 3. self ssPushConstant: objectMemory trueObject. ^ 0 ] ].

	"--- Allocating & loading registers --- "
	needLoop := (self ssTop type = SSConstant and: [ lenCst <= (objectMemory wordSize * 2) ]) not.
	unroll := needLoop not and: [lenCst > objectMemory wordSize ].
	needLoop 
		ifTrue: 
			[ str1Reg := self allocateRegForStackEntryAt: 1 notConflictingWith: self emptyRegisterMask.
			  str2Reg := self allocateRegForStackEntryAt: 2 notConflictingWith: (self registerMaskFor: str1Reg).
			  lenReg := self allocateRegForStackEntryAt: 0 notConflictingWith: (self registerMaskFor:str1Reg and: str2Reg).
			  (self ssValue: 1) popToReg: str1Reg.
			  (self ssValue: 2) popToReg: str2Reg.
			  extraReg := self allocateRegNotConflictingWith: (self registerMaskFor: str1Reg and: str2Reg and: lenReg)]
		ifFalse: 
			[ mask := self emptyRegisterMask.
			  (self ssValue: 1) type = SSConstant ifFalse: 
				[ str1Reg := self allocateRegForStackEntryAt: 1 notConflictingWith: mask.
				  (self ssValue: 1) popToReg: str1Reg.
				  mask := mask bitOr: (self registerMaskFor: str1Reg) ].
			  (self ssValue: 2) type = SSConstant ifFalse: 
				[ str2Reg := self allocateRegForStackEntryAt: 2 notConflictingWith: mask.
				  (self ssValue: 2) popToReg: str2Reg.
				  mask := mask bitOr: (self registerMaskFor: str2Reg) ].
			  extraReg := self allocateRegNotConflictingWith: mask].
	
	"--- Loading LenReg (or statically resolving it) --- "
	"LenReg is loaded with (lenInBytes + objectMemory baseHeaderSize - 1 >> shiftForWord)
	 LenReg is the index for the last word to compare with MoveXwr:r:R:.
	 The loop iterates from LenReg to first word of ByteObj"
	self ssTop type = SSConstant 
		ifTrue: "common case, str = 'foo'. We can precompute lenReg."
			[ lenCst := lenCst + objectMemory baseHeaderSize - 1 >> objectMemory shiftForWord.
			  needLoop ifTrue: [self MoveCq: lenCst R: lenReg ].
			  needjmpZeroSize := false] 
		ifFalse: "uncommon case, str = str2. lenReg in word computed at runtime."
			[ self ssTop popToReg: lenReg.
			  objectRepresentation genConvertSmallIntegerToIntegerInReg: lenReg.
			  self CmpCq: 0 R: lenReg.
			  jmpZeroSize := self JumpZero: 0.
			  needjmpZeroSize := true.
			  self AddCq: objectMemory baseHeaderSize - 1 R: lenReg.
			  self ArithmeticShiftRightCq: objectMemory shiftForWord R: lenReg ].
	
	"--- Comparing the strings --- "
	"LenReg has the index of the last word to read (unless no loop). 
	 We decrement it to adjust -1 (0 in 64 bits) while comparing"
	needLoop 
		ifTrue:
			[instr := self MoveXwr: lenReg R: str1Reg R: extraReg.
			self MoveXwr: lenReg R: str2Reg R: TempReg.
			self CmpR: extraReg R: TempReg.
			jmp := self JumpNonZero: 0. "then string are not equal (jmp target)"
			self AddCq: -1 R: lenReg.
			self CmpCq: (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1 R: lenReg. "first word of ByteObj, stop looping."
			self JumpNonZero: instr]
		ifFalse: "Common case, only 1 or 2 word to check: no lenReg allocation, cst micro optimisations"
			[self genByteEqualsInlinePrimitiveCmp: str1Reg with: str2Reg scratch1: extraReg scratch2: TempReg field: 0.
			jmp := self JumpNonZero: 0. "then string are not equal (jmp target)"
			unroll ifTrue: "unrolling more than twice generate more instructions than the loop so we don't do it"
				[self genByteEqualsInlinePrimitiveCmp: str1Reg with: str2Reg scratch1: extraReg scratch2: TempReg field: 1.
				jmp2 := self JumpNonZero: 0. "then string are not equal (jmp target)"]].
	needjmpZeroSize ifTrue: [ jmpZeroSize jmpTarget: self Label ].
	"fall through, strings are equal"
	
	"--- Pushing the result or pipelining a branch --- "	
	self ssPop: 3.
	self genByteEqualsInlinePrimitiveResult: jmp returnReg: extraReg.
	unroll ifTrue: [jmp2 jmpTarget: jmp getJmpTarget].
	^0
]

{ #category : #'inline primitive generators' }
SistaCogit >> genByteEqualsInlinePrimitiveCmp: str1Reg with: str2Reg scratch1: scratch1Reg scratch2: scratch2Reg field: index [
	| shift |
	<inline: true>
	shift := objectMemory baseHeaderSize + (index * objectMemory wordSize).
	(self ssValue: 1) type = SSConstant 
		ifTrue: [self MoveCq: (objectMemory fetchPointer: index ofObject: (self ssValue: 1) constant) R: scratch1Reg]
		ifFalse: [self MoveMw: shift r: str1Reg R: scratch1Reg].
	 (self ssValue: 2) type = SSConstant 
		ifTrue: [self MoveCq: (objectMemory fetchPointer: index ofObject: (self ssValue: 2) constant) R: scratch2Reg]
		ifFalse: [self MoveMw: shift r: str2Reg R: scratch2Reg].
	self CmpR: scratch1Reg R: scratch2Reg.
]

{ #category : #'inline primitive generators' }
SistaCogit >> genByteEqualsInlinePrimitiveResult: jmp returnReg: reg [
	"Byte equal is falling through if the result is true, or jumping using jmp if the result is false.
	 The method is required to set the jump target of jmp.
	 We look ahead for a branch and pipeline the jumps if possible..
	 ReturnReg is used only if not followed immediately by a branch."
	| branchDescriptor nextPC postBranchPC targetBytecodePC localJump canElide |
	<var: #localJump type: #'AbstractInstruction *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetBytecodePC := target ].
	
	"Case 1 - not followed by a branch"
	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse])
		ifFalse: 
			[self genMoveTrueR: reg.
			 localJump := self Jump: 0.
			 jmp jmpTarget: (self genMoveFalseR: reg).
			 localJump jmpTarget: self Label.
			 self ssPushRegister: reg.
			^ 0].

	"Case 2 - followed by a branch"
	(self fixupAt: nextPC) notAFixup
		ifTrue: "The next instruction is dead.  we can skip it."
			[deadCode := true.
		 	 self ensureFixupAt: targetBytecodePC.
			 self ensureFixupAt: postBranchPC ]
		ifFalse:
			[self ssPushConstant: objectMemory trueObject]. "dummy value"
	"We can only elide the jump if the pc after nextPC is the same as postBranchPC.
	 Branch following means it may not be."
	self nextDescriptorExtensionsAndNextPCInto:
		[:iguana1 :iguana2 :iguana3 :followingPC| nextPC := followingPC].
	canElide := deadCode and: [nextPC = postBranchPC].
	 branchDescriptor isBranchTrue
		ifTrue: 
			[ self Jump: (self ensureNonMergeFixupAt: targetBytecodePC).
			  canElide 
					ifFalse: [ jmp jmpTarget: (self ensureNonMergeFixupAt: postBranchPC) ]
					ifTrue: [ jmp jmpTarget: self Label ] ]
		ifFalse: [ canElide ifFalse: [ self Jump: (self ensureNonMergeFixupAt: postBranchPC).
				 jmp jmpTarget: (self ensureNonMergeFixupAt: targetBytecodePC) ] ].
	^0
]

{ #category : #'bytecode generators' }
SistaCogit >> genCallPrimitiveBytecode [
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
	
	self assert: primSet = 0.
	
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
	
	prim < 5000 ifTrue: 
		[^self genQuaternaryInlinePrimitive: prim - 4000].
	
	prim < 6000 ifTrue: 
		[^self genQuinaryInlinePrimitive: prim - 5000].
		
	^EncounteredUnknownBytecode
]

{ #category : #'bytecode generator support' }
SistaCogit >> genCounterTripOnlyJumpIf: boolean to: targetBytecodePC [ 
	"Specific version if the branch is only reached while falling through if the counter trips after an inlined #== branch. We do not regenerate the counter logic in this case to avoid 24 bytes instructions."
	
	<var: #ok type: #'AbstractInstruction *'>
	<var: #mustBeBooleanTrampoline type: #'AbstractInstruction *'>

	| ok mustBeBooleanTrampoline |

	extA := 0.

	self ssFlushTo: simStackPtr - 1.
	
	self ssTop popToReg: TempReg.
	
	self ssPop: 1.

	counterIndex := counterIndex + 1. "counters are increased / decreased in the inlined branch"

	"We need SendNumArgsReg because of the mustBeBooleanTrampoline"
	self ssAllocateRequiredReg: SendNumArgsReg.
	self MoveCq: 1 R: SendNumArgsReg.
	
	"The first time this is reached, it calls necessarily the counter trip for the trampoline because SendNumArgsReg is non zero"
	mustBeBooleanTrampoline := self genCallMustBeBooleanFor: boolean.
	self annotateBytecode: self Label.

	"Cunning trick by LPD.  If true and false are contiguous subtract the smaller.
	 Correct result is either 0 or the distance between them.  If result is not 0 or
	 their distance send mustBeBoolean."
	self assert: (objectMemory objectAfter: objectMemory falseObject) = objectMemory trueObject.
	self genSubConstant: boolean R: TempReg.
	self JumpZero: (self ensureFixupAt: targetBytecodePC).

	self CmpCq: (boolean = objectMemory falseObject
					ifTrue: [objectMemory trueObject - objectMemory falseObject]
					ifFalse: [objectMemory falseObject - objectMemory trueObject])
		R: TempReg.
		
	ok := self JumpZero: 0.
	self MoveCq: 0 R: SendNumArgsReg. "if counterReg is 0 this is a mustBeBoolean, not a counter trip."		

	self Jump: mustBeBooleanTrampoline.
	
	ok jmpTarget: self Label.
	^0
]

{ #category : #'bytecode generator support' }
SistaCogit >> genExecutionCountLogicInto: binaryBlock counterReg: counterReg [
	<var: #countTripped type: #'AbstractInstruction *'>
	<inline: true>
	| counterAddress countTripped |
	counterAddress := counters + (CounterBytes * counterIndex).
	self MoveA32: counterAddress R: counterReg.
	self SubCq: 16r10000 R: counterReg. "Count executed"
	"If counter trips simply abort the comparison continuing to the following
	 branch *without* writing back.  A double decrement will not trip the second time."
	countTripped := self JumpCarry: 0.
	self MoveR: counterReg A32: counterAddress. "write back"
	binaryBlock value: counterAddress value: countTripped
]

{ #category : #'bytecode generators' }
SistaCogit >> genExtJumpIfNotInstanceOfBehaviorsBytecode [
	"SistaV1: *	254		11111110	kkkkkkkk	jjjjjjjj		branch If Not Instance Of Behavior/Array Of Behavior kkkkkkkk (+ Extend A * 256, where Extend A >= 0) distance jjjjjjjj (+ Extend B * 256, where Extend B >= 0)"
	| reg literal distance targetFixUp inverse |

	"We lose the information of in which register is stack top 
	 when jitting the branch target so we need to flush everything. 
	 We could use a fixed register here...."
	reg := self allocateRegForStackEntryAt: 0.
	self ssTop popToReg: reg.
	self ssPop: 1.
	self ssFlushTo: simStackPtr. "flushed but the value is still in reg"

	literal := self getLiteral: (extA * 256 + byte1).
	(inverse := extB < 0) ifTrue:
		[extB := extB + 128].
	distance := extB * 256 + byte2.
	extA := extB := numExtB := 0.

	targetFixUp := self cCoerceSimple: (self ensureFixupAt: bytecodePC + 3 + distance) to: #'AbstractInstruction *'.
	inverse
		ifFalse: 
			[(objectMemory isArrayNonImm: literal)
				ifTrue: [objectRepresentation branchIf: reg notInstanceOfBehaviors: literal target: targetFixUp]
				ifFalse: [objectRepresentation branchIf: reg notInstanceOfBehavior: literal target: targetFixUp] ]
		ifTrue:
			[(objectMemory isArrayNonImm: literal)
				ifTrue: [objectRepresentation branchIf: reg instanceOfBehaviors: literal target: targetFixUp]
				ifFalse: [objectRepresentation branchIf: reg instanceOfBehavior: literal target: targetFixUp]].

	^0
]

{ #category : #'bytecode generator support' }
SistaCogit >> genFallsThroughCountLogicCounterReg: counterReg counterAddress: counterAddress [
	<inline: true>
	"Gen this when the branch has not been taken and forwarders have been followed."
	self SubCq: 1 R: counterReg. "Count untaken"
	self MoveR: counterReg A32: counterAddress. "write back"
]

{ #category : #'bytecode generators' }
SistaCogit >> genForwardersInlinedIdenticalOrNotIf: orNot [
	"Override to count inlined branches if followed by a conditional branch.
	 We borrow the following conditional branch's counter and when about to
	 inline the comparison we decrement the counter (without writing it back)
	 and if it trips simply abort the inlining, falling back to the normal send which
	 will then continue to the conditional branch which will trip and enter the abort."
	| nextPC postBranchPC targetBytecodePC branchDescriptor counterReg fixup jumpEqual jumpNotEqual
	  counterAddress countTripped unforwardArg unforwardRcvr argReg rcvrReg regMask |
	<var: #fixup type: #'BytecodeFixup *'>
	<var: #countTripped type: #'AbstractInstruction *'>
	<var: #label type: #'AbstractInstruction *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpEqual type: #'AbstractInstruction *'>
	<var: #jumpNotEqual type: #'AbstractInstruction *'>

	((coInterpreter isOptimizedMethod: methodObj) or: [needsFrame not]) ifTrue:
		[^super genForwardersInlinedIdenticalOrNotIf: orNot].

	regMask := 0.
	
	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetBytecodePC := target ].
	
	unforwardRcvr := (objectRepresentation isUnannotatableConstant: (self ssValue: 1)) not.
	unforwardArg := (objectRepresentation isUnannotatableConstant: self ssTop) not.
	
	"If an operand is an annotable constant, it may be forwarded, so we need to store it into a 
	register so the forwarder check can jump back to the comparison after unforwarding the constant.
	However, if one of the operand is an unnanotable constant, does not allocate a register for it 
	(machine code will use operations on constants)."
	rcvrReg:= argReg := NoReg.
	self 
		allocateEqualsEqualsRegistersArgNeedsReg: unforwardArg 
		rcvrNeedsReg: unforwardRcvr 
		into: [ :rcvr :arg | rcvrReg:= rcvr. argReg := arg ].
		
	argReg ~= NoReg ifTrue: [ regMask := self registerMaskFor: argReg ].
	rcvrReg ~= NoReg ifTrue: [ regMask := regMask bitOr: (self registerMaskFor: rcvrReg) ].
	
	"Only interested in inlining if followed by a conditional branch."
	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse]) ifFalse:
		[^ self 
			genIdenticalNoBranchArgIsConstant: unforwardArg not
			rcvrIsConstant: unforwardRcvr not
			argReg: argReg 
			rcvrReg: rcvrReg 
			orNotIf: orNot].
	
	"If branching the stack must be flushed for the merge"
	self ssFlushTo: simStackPtr - 2.
	
	unforwardArg ifTrue: [ objectRepresentation genEnsureOopInRegNotForwarded: argReg scratchReg: TempReg ].
	unforwardRcvr ifTrue: [ objectRepresentation genEnsureOopInRegNotForwarded: rcvrReg scratchReg: TempReg ].
	
	counterReg := self allocateRegNotConflictingWith: regMask.
	self 
		genExecutionCountLogicInto: [ :cAddress :countTripBranch | 
			counterAddress := cAddress. 
			countTripped := countTripBranch ] 
		counterReg: counterReg.
	
	self assert: (unforwardArg or: [ unforwardRcvr ]).
	self genCmpArgIsConstant: unforwardArg not rcvrIsConstant: unforwardRcvr not argReg: argReg rcvrReg: rcvrReg.
	self ssPop: 2.
	
	orNot == branchDescriptor isBranchTrue "orNot is true for ~~"
		ifFalse:
			[ fixup := (self ensureNonMergeFixupAt: postBranchPC) asUnsignedInteger.
			self JumpZero:  (self ensureNonMergeFixupAt: targetBytecodePC) asUnsignedInteger ]
		ifTrue:
			[ fixup := (self ensureNonMergeFixupAt: targetBytecodePC) asUnsignedInteger.
			self JumpZero: (self ensureNonMergeFixupAt: postBranchPC) asUnsignedInteger ].
	
	self genFallsThroughCountLogicCounterReg: counterReg counterAddress: counterAddress.
	self Jump: fixup.
	
	countTripped jmpTarget: self Label.
	
	"inlined version of #== ignoring the branchDescriptor if the counter trips to have normal state for the optimizer"
	self ssPop: -2. 
	self genCmpArgIsConstant: unforwardArg not rcvrIsConstant: unforwardRcvr not argReg: argReg rcvrReg: rcvrReg.
	self ssPop: 2. 
	
	"This code necessarily directly falls through the jumpIf: code which pops the top of the stack into TempReg. 
	We therefore directly assign the result to TempReg to save one move instruction"
	jumpEqual := orNot ifFalse: [self JumpZero: 0] ifTrue: [self JumpNonZero: 0].
	self genMoveFalseR: TempReg.
	jumpNotEqual := self Jump: 0.
	jumpEqual jmpTarget: (self genMoveTrueR: TempReg).
	jumpNotEqual jmpTarget: self Label.
	self ssPushRegister: TempReg.
	
	(self fixupAt: nextPC) notAFixup ifTrue: [ branchReachedOnlyForCounterTrip := true ].
	
	^ 0
]

{ #category : #'bytecode generator support' }
SistaCogit >> genJumpIf: boolean to: targetBytecodePC [
	"The heart of performance counting in Sista.  Conditional branches are 6 times less
	 frequent than sends and can provide basic block frequencies (send counters can't).
	 Each conditional has a 32-bit counter split into an upper 16 bits counting executions
	 and a lower half counting untaken executions of the branch.  Executing the branch
	 decrements the upper half, tripping if the count goes negative.  Not taking the branch
	 decrements the lower half.  N.B. We *do not* eliminate dead branches (true ifTrue:/true ifFalse:)
	 so that scanning for send and branch data is simplified and that branch data is correct."
	<inline: false>
	| ok counterAddress countTripped retry nextPC nextDescriptor desc eventualTarget |
	<var: #ok type: #'AbstractInstruction *'>
	<var: #desc type: #'CogSimStackEntry *'>
	<var: #retry type: #'AbstractInstruction *'>
	<var: #countTripped type: #'AbstractInstruction *'>
	<var: #nextDescriptor type: #'BytecodeDescriptor *'>

	"In optimized code we don't generate counters to improve performance"
	(coInterpreter isOptimizedMethod: methodObj) ifTrue: [ ^ super genJumpIf: boolean to: targetBytecodePC ].
	
	"If the branch is reached only for the counter trip trampoline 
	(typically, var1 == var2 ifTrue: falls through to the branch only for the trampoline)
	we generate a specific path to drastically reduce the number of machine instructions"
	branchReachedOnlyForCounterTrip ifTrue: 
		[ branchReachedOnlyForCounterTrip := false.
		^ self genCounterTripOnlyJumpIf: boolean to: targetBytecodePC ].
	
	"We detect and: / or:, if found, we don't generate the counters to avoid pathological counter slow down"
	boolean = objectMemory falseObject ifTrue:
		[ nextPC := bytecodePC + (self generatorAt: byte0) numBytes.
		  nextDescriptor := self generatorAt: (objectMemory fetchByte: nextPC ofObject: methodObj) + bytecodeSetOffset.
		  nextDescriptor generator ==  #genPushConstantTrueBytecode ifTrue: [ ^ super genJumpIf: boolean to: targetBytecodePC ].
		  nextDescriptor := self generatorAt: (objectMemory fetchByte: targetBytecodePC ofObject: methodObj) + bytecodeSetOffset.
		  nextDescriptor generator == #genPushConstantFalseBytecode ifTrue: [ ^ super genJumpIf: boolean to: targetBytecodePC ].  ].

	extA := 0. "We ignore the noMustBeBoolean flag. It should not be present in methods with counters, and if it is we don't care."

	"We don't generate counters on branches on true/false, the basicblock usage can be inferred"
	desc := self ssTop.
	(desc type == SSConstant
	 and: [desc constant = objectMemory trueObject or: [desc constant = objectMemory falseObject]]) ifTrue:
		[ ^ super genJumpIf: boolean to: targetBytecodePC ].

	eventualTarget := self eventualTargetOf: targetBytecodePC.

	self ssFlushTo: simStackPtr - 1.
	desc popToReg: TempReg.
	self ssPop: 1.

	"We need SendNumArgsReg because of the mustBeBooleanTrampoline"
	self ssAllocateRequiredReg: SendNumArgsReg.

	retry := self Label.
	self 
		genExecutionCountLogicInto: [ :cAddress :countTripBranch | 
			counterAddress := cAddress. 
			countTripped := countTripBranch ] 
		counterReg: SendNumArgsReg.
	counterIndex := counterIndex + 1.

	"Cunning trick by LPD.  If true and false are contiguous subtract the smaller.
	 Correct result is either 0 or the distance between them.  If result is not 0 or
	 their distance send mustBeBoolean."
	self assert: (objectMemory objectAfter: objectMemory falseObject) = objectMemory trueObject.
	self genSubConstant: boolean R: TempReg.
	self JumpZero: (self ensureFixupAt: eventualTarget).

	self genFallsThroughCountLogicCounterReg: SendNumArgsReg counterAddress: counterAddress.

	self CmpCq: (boolean = objectMemory falseObject
					ifTrue: [objectMemory trueObject - objectMemory falseObject]
					ifFalse: [objectMemory falseObject - objectMemory trueObject])
		R: TempReg.
	ok := self JumpZero: 0.
	self MoveCq: 0 R: SendNumArgsReg. "if counterReg is 0 this is a mustBeBoolean, not a counter trip."
	
	countTripped jmpTarget: (self genCallMustBeBooleanFor: boolean).
						
	"If we're in an image which hasn't got the Sista code loaded then the ceCounterTripped:
	 trampoline will return directly to machine code, returning the boolean.  So the code should
	 jump back to the retry point. The trampoline makes sure that TempReg has been reloaded."
	
	"Clément: For some reason if I write self annotateBytecode: (self Jump: retry) the annotation is not at the correct place."
	"Eliot: Annotations apply the the address following an instruction, and the annotation must be for the return address
	 of the call (since this is the address the run-time sees), so it must be on a label before the jump, not after the jump."
	self annotateBytecode: self Label.
	self Jump: retry.
	
	ok jmpTarget: self Label.
	^0
]

{ #category : #initialization }
SistaCogit >> genMustBeBooleanTrampolineFor: boolean called: trampolineName [
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
	self zeroOpcodeIndex.
	self CmpCq: 0 R: SendNumArgsReg.
	jumpMBB := self JumpZero: 0.
	"Open-code self compileTrampolineFor: #ceCounterTripped: numArgs: 1 arg: TempReg ...
	 so we can restore ResultReceiverReg."
	self genSmalltalkToCStackSwitch: true.
	self
		compileCallFor: #ceCounterTripped:
		numArgs: 1
		arg: TempReg
		arg: nil
		arg: nil
		arg: nil
		resultReg: TempReg "(*)"
		regsToSave: self emptyRegisterMask.
	"(*) For the case where the ceCounterTripped: call returns (e.g. because there's no callback selector
	 installed), the call to the ceSendMustBeBooleanAddTrue/FalseTrampoline is followed by a jump
	 back to the start of the counter/condition test sequence.  For this case copy the C result to
	 TempReg (the register that is tested), to reload it with the boolean to be tested."
	backEnd genLoadStackPointers.
	backEnd hasLinkRegister ifTrue:
		[self PopR: LinkReg].
	"To keep ResultReceiverReg live if optStatus thought it was, simply reload it
	 from the frame pointer.  This avoids having to reload it in the common case
	 (counter does not trip) if it was live.  Note we can't use putSelfInReceiverResultReg
	 when generating trampolines because simSelf has not yet been initialized."
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
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: true
]

{ #category : #'inline primitive generators' }
SistaCogit >> genNullaryInlinePrimitive: prim [
	"Nullary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#nullaryInlinePrimitive:"

	<option: #SistaVM>
	^EncounteredUnknownBytecode
]

{ #category : #'inline primitive generators' }
SistaCogit >> genQuaternaryInlinePrimitive: prim [
	"Quaternary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#quaternaryInlinePrimitive:"
	| needStoreCheck sourceReg stopReg objReg adjust jmp cmp isStartCst isStopCst startCst stopCst iteratorReg |
	<var: #jmp type: #'AbstractInstruction *'>
	<var: #cmp type: #'AbstractInstruction *'>
	prim = 0 ifFalse: [^EncounteredUnknownBytecode].
	
	"4000	Pointer Object>> fillFrom:to:with: The receiver is a Pointer object. the middle two arguments are smallintegers. Last argument is any object. Fills the object in between the two indexes with last argument. Receiver is guaranteed to be mutable. The pointer accesses are raw (no inst var check). If ExtB is set to 1, no store check is present. Else a single store check is done for the bulk operation. Answers the receiver."
	needStoreCheck := self sistaNeedsStoreCheck.
	extB := numExtB := 0.
	
	"Allocate reg for src, objToStore, iterator and stop."
	sourceReg := needStoreCheck 
		ifTrue: [	self ssAllocateRequiredReg: ReceiverResultReg.
				self voidReceiverResultRegContainsSelf.
				ReceiverResultReg ]
		ifFalse: [ self allocateRegForStackEntryAt: 3 notConflictingWith: self emptyRegisterMask ].
	(self ssValue: 3) popToReg: sourceReg.
	objReg := self allocateRegForStackEntryAt: 0 notConflictingWith: (self registerMaskFor: sourceReg).
	self ssTop popToReg: objReg.
	
	"Set up iterator to first index to write and stop to last index to write"
	adjust := (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
	isStartCst := (self ssValue: 2) type = SSConstant.
	isStopCst := (self ssValue: 1) type = SSConstant.
	isStartCst ifTrue: [startCst := adjust + (objectMemory integerValueOf: (self ssValue: 2) constant)].
	isStopCst ifTrue: [stopCst := adjust + (objectMemory integerValueOf: (self ssValue: 1) constant)].
	
	(isStartCst
	and: [isStopCst
	and: [stopCst - startCst < 7 ]]) "The other path generates at least 7 instructions"
		ifTrue: ["unroll"
				startCst
					to: stopCst
					do: [ :i | self MoveMw: i r: sourceReg R: objReg ] ]
		ifFalse: ["loop"
				stopReg := self allocateRegNotConflictingWith: (self registerMaskFor: sourceReg and: objReg).
				iteratorReg := self allocateRegNotConflictingWith: (self registerMaskFor: sourceReg and: objReg and: stopReg).
				isStartCst 
					ifTrue: [ self MoveCq: startCst R: iteratorReg ]
					ifFalse: [ (self ssValue: 2) popToReg: iteratorReg. 
							 adjust ~= 0 ifTrue: [ self AddCq: adjust R: iteratorReg ] ].
				isStopCst 
					ifTrue: [ self MoveCq: stopCst R: stopReg ]
					ifFalse: [ (self ssValue: 1) popToReg: stopReg. 
							 adjust ~= 0 ifTrue: [ self AddCq: adjust R: stopReg ] ].
				cmp := self CmpR: stopReg R: iteratorReg.
				jmp := self JumpAbove: 0.
				self MoveR: objReg Xwr: iteratorReg R: sourceReg.
				self AddCq: 1 R: iteratorReg.
				self Jump: cmp.
				jmp jmpTarget: self Label].
			
	needStoreCheck ifTrue: [objectRepresentation genStoreCheckReceiverReg: sourceReg valueReg: objReg scratchReg: TempReg inFrame: true].
	
	self ssPop: 4.
	self ssPushRegister: sourceReg.
	 ^0
]

{ #category : #'inline primitive generators' }
SistaCogit >> genQuinaryInlinePrimitive: prim [
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#quaternaryInlinePrimitive:"
	^EncounteredUnknownBytecode
]

{ #category : #'bytecode generators' }
SistaCogit >> genSpecialSelectorComparison [
	"Override to count inlined branches if followed by a conditional branch.
	 We borrow the following conditional branch's counter and when about to
	 inline the comparison we decrement the counter (without writing it back)
	 and if it trips simply abort the inlining, falling back to the normal send which
	 will then continue to the conditional branch which will trip and enter the abort."
	| nextPC postBranchPC targetPC primDescriptor branchDescriptor
	  rcvrIsInt rcvrIsConst argIsIntConst argInt jumpNotSmallInts inlineCAB
	  counterAddress countTripped counterReg index |
	<var: #countTripped type: #'AbstractInstruction *'>
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpNotSmallInts type: #'AbstractInstruction *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>

	(coInterpreter isOptimizedMethod: methodObj) ifTrue: [ ^ self genSpecialSelectorComparisonWithoutCounters ].

	self ssFlushTo: simStackPtr - 2.
	primDescriptor := self generatorAt: byte0.
	argIsIntConst := self ssTop type = SSConstant
				 and: [objectMemory isIntegerObject: (argInt := self ssTop constant)].
	rcvrIsInt := ((rcvrIsConst := (self ssValue: 1) type = SSConstant)
				  and: [objectMemory isIntegerObject:(self ssValue: 1) constant])
				or: [self mclassIsSmallInteger and: [(self ssValue: 1) isSameEntryAs: (self addressOf: simSelf)]].

	"short-cut the jump if operands are SmallInteger constants."
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

	counterReg := self allocateRegNotConflictingWith: (self registerMaskFor: ReceiverResultReg and: Arg0Reg).
	self 
		genExecutionCountLogicInto: [ :cAddress :countTripBranch | 
			counterAddress := cAddress. 
			countTripped := countTripBranch ] 
		counterReg: counterReg.

	argIsIntConst
		ifTrue: [self CmpCq: argInt R: ReceiverResultReg]
		ifFalse: [self CmpR: Arg0Reg R: ReceiverResultReg].
	"Cmp is weird/backwards so invert the comparison.  Further since there is a following conditional
	 jump bytecode define non-merge fixups and leave the cond bytecode to set the mergeness."
	self genConditionalBranch: (branchDescriptor isBranchTrue
				ifTrue: [primDescriptor opcode]
				ifFalse: [self inverseBranchFor: primDescriptor opcode])
		operand: (self ensureNonMergeFixupAt: targetPC) asUnsignedInteger.
		
	self genFallsThroughCountLogicCounterReg: counterReg counterAddress: counterAddress.
	
	self Jump: (self ensureNonMergeFixupAt: postBranchPC).
	countTripped jmpTarget: self Label.
	jumpNotSmallInts
		ifNil: [(self fixupAt: nextPC) notAFixup ifTrue:
				[branchReachedOnlyForCounterTrip := true]]
		ifNotNil: [jumpNotSmallInts jmpTarget: countTripped getJmpTarget].
	
	argIsIntConst ifTrue:
		[self MoveCq: argInt R: Arg0Reg].
	index := byte0 - self firstSpecialSelectorBytecodeOffset.
	^self genMarshalledSend: index negated - 1 numArgs: 1 sendTable: ordinarySendTrampolines
]

{ #category : #'bytecode generators' }
SistaCogit >> genSpecialSelectorComparisonWithoutCounters [
	"This method is there because if I put directly the super send in genSpecialSelectorComparison Slang does not correctly translte the code to C, it does not correctly type one of the branchDescriptor to BytecodeDescriptor"
	^ super genSpecialSelectorComparison
]

{ #category : #'inline primitive generators' }
SistaCogit >> genTrinaryInlinePrimitive: prim [
	"trinary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#trinaryInlinePrimitive:"

	prim < 10 ifTrue: [^ self genAtPutInlinePrimitive: prim].
	prim = 21 ifTrue: [^ self genByteEqualsInlinePrimitive: prim].
	^ EncounteredUnknownBytecode
]

{ #category : #'inline primitive generators' }
SistaCogit >> genUnaryInlinePrimitive: prim [
	"Unary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#unaryInlinePrimitive:"
	| rcvrReg resultReg |
	rcvrReg := self allocateRegForStackEntryAt: 0.
	resultReg := self allocateRegNotConflictingWith: (self registerMaskFor: rcvrReg).
	prim
		caseOf: {
					"00		unchecked class"
			[1] ->	"01		unchecked pointer numSlots"
				[self ssTop popToReg: rcvrReg.
				 self ssPop: 1.
				 objectRepresentation
					genGetNumSlotsOf: rcvrReg into: resultReg;
					genConvertIntegerToSmallIntegerInReg: resultReg].
					"02		unchecked pointer basicSize"
			[3] ->	"03		unchecked byte numBytes"
				[self ssTop popToReg: rcvrReg.
				 self ssPop: 1.
				 objectRepresentation
					genGetNumBytesOf: rcvrReg into: resultReg;
					genConvertIntegerToSmallIntegerInReg: resultReg].
					"04		unchecked short16Type format numShorts"
					"05		unchecked word32Type format numWords"
					"06		unchecked doubleWord64Type format numDoubleWords"
			[11] ->	"11		unchecked fixed pointer basicNew"
				[self ssTop type ~= SSConstant ifTrue:
					[^EncounteredUnknownBytecode].
				 (objectRepresentation
					genGetInstanceOfFixedClass: self ssTop constant
						into: resultReg
							initializingIf: self extBSpecifiesInitializeInstance) ~= 0 ifTrue:
					[^ShouldNotJIT]. "e.g. bad class"
				 self ssPop: 1] .
			[20] ->	"20 	identityHash"
				[objectRepresentation genGetIdentityHash: rcvrReg resultReg: resultReg.
				 self ssPop: 1] .
					"21		identityHash (SmallInteger)"
					"22		identityHash (Character)"
					"23		identityHash (SmallFloat64)"
					"24		identityHash (Behavior)"
					"30 	immediateAsInteger (Character)
					 31 	immediateAsInteger (SmallFloat64)
					 35		immediateAsFloat 	  (SmallInteger)	"
			[30] -> 
				[self ssTop popToReg: resultReg.
				 objectRepresentation genConvertCharacterToSmallIntegerInReg: resultReg.
				 self ssPop: 1].
			[35] -> 
				[self assert: self processorHasDoublePrecisionFloatingPointSupport.
				self MoveR: rcvrReg R: TempReg.
				self genConvertSmallIntegerToIntegerInReg: TempReg.
				self ConvertR: TempReg Rd: DPFPReg0.
				self flag: #TODO. "Should never fail"
				self
					genAllocFloatValue: DPFPReg0
					into: resultReg
					scratchReg: TempReg
					scratchReg: NoReg. "scratch2 for V3 only"]
				  }
				
		otherwise:
			[^EncounteredUnknownBytecode].
	extB := 0.
	numExtB := 0.
	self ssPushRegister: resultReg.
	^0
]

{ #category : #'bytecode generators' }
SistaCogit >> genUnconditionalTrapBytecode [
	"SistaV1: *	217		Trap"
	self ssFlushTo: simStackPtr.
	self CallRT: ceTrapTrampoline.
	self annotateBytecode: self Label.
	deadCode := true.
	^0
]

{ #category : #'bytecode generators' }
SistaCogit >> genUnoptimizedSpecialSelectorComparison [
	"This method is there because if I put directly the super send in genSpecialSelectorComparison Slang does not correctly translte the code to C, it does not correctly type one of the branchDescriptor to BytecodeDescriptor"
	^ super genSpecialSelectorComparison
]

{ #category : #initialization }
SistaCogit >> generateSistaRuntime [
	"Trap sends Sista trap message to context with top of stack, so we don't need any arguments..."
	ceTrapTrampoline := self genTrampolineFor: #ceSistaTrap called: 'ceSistaTrapTrampoline'
]

{ #category : #accessing }
SistaCogit >> getCogCodeZoneThreshold [
	<doNotGenerate>
	^methodZone getCogCodeZoneThreshold
]

{ #category : #'method introspection' }
SistaCogit >> getJumpTargetPCAt: pc [
	<api>
	^backEnd jumpTargetPCAt: pc
]

{ #category : #initialization }
SistaCogit >> initialize [
	super initialize.
	branchReachedOnlyForCounterTrip := false.
	cogMethodSurrogateClass := (objectMemory ifNil: [self class objectMemoryClass]) wordSize = 4
										ifTrue: [CogSistaMethodSurrogate32]
										ifFalse: [CogSistaMethodSurrogate64]
]

{ #category : #initialization }
SistaCogit >> initializeCodeZoneFrom: startAddress upTo: endAddress [
	initialCounterValue := MaxCounterValue.
	super initializeCodeZoneFrom: startAddress upTo: endAddress
]

{ #category : #'simulation only' }
SistaCogit >> isTrapAt: retpc [
	"For stack depth checking."
	<doNotGenerate>
	^(backEnd isCallPrecedingReturnPC: retpc)
	 and: [(backEnd callTargetFromReturnAddress: retpc) = ceTrapTrampoline]
]

{ #category : #'compile abstract instructions' }
SistaCogit >> maybeAllocAndInitCounters [
	<inline: true>
	self assert: counters = 0.
	counterIndex := 0.
	numCounters = 0 ifTrue:
		[^true].
	counters := objectRepresentation allocateCounters: numCounters.
	^counters ~= 0
]

{ #category : #'compile abstract instructions' }
SistaCogit >> maybeCountCounter [
	<inline: true>
	numCounters := numCounters + 1
]

{ #category : #'compile abstract instructions' }
SistaCogit >> maybeCounterIndex [
	<inline: true>
	^counterIndex
]

{ #category : #'compile abstract instructions' }
SistaCogit >> maybeFreeCounters [
	<inline: true>
	counters ~= 0 ifTrue:
		[objectRepresentation freeCounters: counters]
]

{ #category : #compaction }
SistaCogit >> maybeFreeCountersOf: aCogMethod [
	"Free any counters in the method."
	<inline: true>
	objectRepresentation freeCounters: aCogMethod counters
]

{ #category : #'compile abstract instructions' }
SistaCogit >> maybeInitNumCounters [
	<inline: true>
	numCounters := 0
]

{ #category : #'garbage collection' }
SistaCogit >> maybeMarkCountersIn: cogMethod [
	"In SIsta Spur counters are held on the heap in pinned objects which must be marked
	 to avoid them being garbage collected.  This is the hook through which that happens."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	objectRepresentation maybeMarkCounters: cogMethod counters
]

{ #category : #'compile abstract instructions' }
SistaCogit >> maybeSetCounterIndex: value [
	<inline: true>
	counterIndex := value
]

{ #category : #'simulation only' }
SistaCogit >> methodsCompiledToMachineCodeInto: arrayObject [
	<doNotGenerate>
	^methodZone methodsCompiledToMachineCodeInto: arrayObject
]

{ #category : #'simulation only' }
SistaCogit >> numMethods [
	<doNotGenerate>
	^methodZone numMethods
]

{ #category : #'method introspection' }
SistaCogit >> picDataFor: descriptor Annotation: isBackwardBranchAndAnnotation Mcpc: mcpc Bcpc: bcpc Method: cogMethodArg [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #mcpc type: #'char *'>
	<var: #cogMethodArg type: #'void *'>
	| annotation entryPoint tuple counter |
	"N.B. Counters are always 32-bits, having two 16-bit halves for the reached and taken counts."
	<var: #counter type: #'unsigned int'>

	descriptor ifNil:
		[^0].
	descriptor isBranch ifTrue:
		["it's a branch; conditional?"
		 (descriptor isBranchTrue or: [descriptor isBranchFalse]) ifTrue:
			[counter := (self
							cCoerce: ((self
											cCoerceSimple: cogMethodArg
											to: #'CogMethod *') counters)
							to: #'usqInt *')
								at: counterIndex.
			 tuple := self picDataForCounter: counter at: bcpc + 1.
			 tuple = 0 ifTrue: [^PrimErrNoMemory].
			 objectMemory storePointer: introspectionDataIndex ofObject: introspectionData withValue: tuple.
			 introspectionDataIndex := introspectionDataIndex + 1.
			 counterIndex := counterIndex + 1].
		 ^0].
	annotation := isBackwardBranchAndAnnotation >> 1.
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
				[association := backEnd literalBeforeInlineCacheTagAt: mcpc asUnsignedInteger.
				 methodClassIfSuper := objectRepresentation valueOfAssociation: association].
			tuple := self picDataForSendTo: targetMethod
						methodClassIfSuper: methodClassIfSuper
						at: mcpc
						bcpc: bcpc + 1].
	tuple = 0 ifTrue: [^PrimErrNoMemory].
	objectMemory storePointer: introspectionDataIndex ofObject: introspectionData withValue: tuple.
	introspectionDataIndex := introspectionDataIndex + 1.
	^0
]

{ #category : #'method introspection' }
SistaCogit >> picDataFor: cogMethod into: arrayObj [
	"Collect the branch and send data for cogMethod, storing it into arrayObj."
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	| errCode |
	cogMethod stackCheckOffset = 0 ifTrue:
		[^0].
	introspectionDataIndex := counterIndex := 0.
	introspectionData := arrayObj.
	errCode := self
					mapFor: (self cCoerceSimple: cogMethod to: #'CogBlockMethod *')
					bcpc: (coInterpreter startPCOfMethod: cogMethod methodObject)
					performUntil: #picDataFor:Annotation:Mcpc:Bcpc:Method:
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
	^introspectionDataIndex
]

{ #category : #'method introspection' }
SistaCogit >> picDataForBlockEntry: blockEntryMcpc Method: cogMethod [
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
		performUntil: #picDataFor:Annotation:Mcpc:Bcpc:Method:
		arg: cogMethod asVoidPointer
]

{ #category : #'method introspection' }
SistaCogit >> picDataForCounter: counter at: bcpc [
	| executedCount tuple untakenCount |
	"N.B. Counters are always 32-bits, having two 16-bit halves for the reached and taken counts."
	<var: #counter type: #'unsigned int'>
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
SistaCogit >> picDataForSendTo: cogMethod methodClassIfSuper: methodClassOrNil at: sendMcpc bcpc: sendBcpc [
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
SistaCogit >> populate: tuple withPICInfoFor: cPIC firstCacheTag: firstCacheTag [
	"Populate tuple (which must be large enough) with the ClosedPIC's target method class pairs.
	 The first entry in tuple contains the bytecode pc for the send, so skip the tuple's first field."
	<var: #cPIC type: #'CogMethod *'>
	| pc cacheTag classOop entryPoint targetMethod value |
	<var: #targetMethod type: #'CogMethod *'>

	1 to: cPIC cPICNumCases do:
		[:i|
		pc := self addressOfEndOfCase: i inCPIC: cPIC.
		cacheTag := i = 1
						ifTrue: [firstCacheTag]
						ifFalse: [backEnd literalBeforeFollowingAddress: pc - backEnd jumpLongConditionalByteSize].
		classOop := objectRepresentation classForInlineCacheTag: cacheTag.
		objectMemory storePointer: i * 2 - 1 ofObject: tuple withValue: classOop.
		entryPoint := i = 1
						ifTrue: [backEnd jumpLongTargetBeforeFollowingAddress: pc]
						ifFalse: [backEnd jumpLongConditionalTargetBeforeFollowingAddress: pc].
		"Find target from jump.  A jump to the MNU entry-point should collect #doesNotUnderstand:"
		(cPIC containsAddress: entryPoint)
			ifTrue:
				[value := objectMemory splObj: SelectorDoesNotUnderstand]
			ifFalse:
				[targetMethod := self cCoerceSimple: entryPoint - cmNoCheckEntryOffset to: #'CogMethod *'.
				 self assert: targetMethod cmType = CMMethod.
				 value := targetMethod methodObject].
		objectMemory storePointer: i * 2 ofObject: tuple withValue: value]
]

{ #category : #tests }
SistaCogit >> printPICDataForMethods [
	<doNotGenerate>
	methodZone methodsDo:
		[:cogMethod|
		cogMethod cmType = CMMethod ifTrue:
			[(coInterpreter picDataFor: cogMethod) ifNotNil:
				[:thePicData|
				coInterpreter printOop: thePicData]]]
]

{ #category : #'sista callbacks' }
SistaCogit >> resetCountersIn: cogMethod [
	<doNotGenerate>
	objectRepresentation resetCountersIn: cogMethod
]

{ #category : #accessing }
SistaCogit >> setCogCodeZoneThreshold: threshold [
	<doNotGenerate>
	^methodZone setCogCodeZoneThreshold: threshold
]
