Class {
	#name : #SistaCogitClone,
	#superclass : #SistaRegisterAllocatingCogit,
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
SistaCogitClone class >> additionalHeadersDo: aBinaryBlock [
	"Evaluate aBinaryBlock with the names and contents of
	 any additional header files that need to be generated."
	aBinaryBlock
		value: 'cogmethod.h'
		value: SistaCogMethod cogMethodHeader
]

{ #category : #translation }
SistaCogitClone class >> ancilliaryClasses: options [
	^(super ancilliaryClasses: options) copyWith: SistaCogMethod
]

{ #category : #translation }
SistaCogitClone class >> declareCVarsIn: aCodeGen [
	aCodeGen var: 'counters' type: #usqInt
]

{ #category : #'class initialization' }
SistaCogitClone class >> initializeWithOptions: optionsDictionary [

	super initializeWithOptions: optionsDictionary.
	CounterBytes := 4.
	MaxCounterValue := (1 << 16) - 1
]

{ #category : #accessing }
SistaCogitClone class >> numTrampolines [
	^super numTrampolines + 1

	"Cogit withAllSubclasses collect: [:c| {c. (c instVarNames select: [:ea| ea beginsWith: 'ce']) size}]"
	"self instVarNames select: [:ea| ea beginsWith: 'ce']"
]

{ #category : #'in-line cacheing' }
SistaCogitClone >> allowEarlyOpenPICPromotion [
	<inline: true>
	^ false
]

{ #category : #'compile abstract instructions' }
SistaCogitClone >> compileCogFullBlockMethod: numCopied [
	<option: #SistaV1BytecodeSet>
	counters := 0.
	^super compileCogFullBlockMethod: numCopied
]

{ #category : #'compile abstract instructions' }
SistaCogitClone >> compileCogMethod: selector [
	counters := 0.
	^super compileCogMethod: selector
]

{ #category : #'compile abstract instructions' }
SistaCogitClone >> compileFrameBuild [
	"Override to prefetch counters, if any."
	super compileFrameBuild.
	counters ~= 0 ifTrue:
		[self PrefetchAw: counters]
]

{ #category : #'compile abstract instructions' }
SistaCogitClone >> compileFullBlockMethodFrameBuild: numCopied [
	"Override to prefetch counters if any"
	super compileFullBlockMethodFrameBuild: numCopied.
	counters ~= 0 ifTrue:
		[self PrefetchAw: counters]
]

{ #category : #disassembly }
SistaCogitClone >> disassembleMethod: surrogateOrAddress on: aStream [
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
			 (objectMemory long32At: addr) printOn: aStream base: 16.
			 aStream cr].
		 aStream flush]
]

{ #category : #accessing }
SistaCogitClone >> estimateOfAbstractOpcodesPerBytecodes [
	"Due to the counter logic, the estimation is higher"
	<inline: true>
	^ 11
]

{ #category : #'generate machine code' }
SistaCogitClone >> fillInCPICHeader: pic numArgs: numArgs numCases: numCases hasMNUCase: hasMNUCase selector: selector [
	pic counters: 0.
	^super fillInCPICHeader: pic numArgs: numArgs numCases: numCases hasMNUCase: hasMNUCase selector: selector
]

{ #category : #'generate machine code' }
SistaCogitClone >> fillInCounters: nCounters atEndAddress: endAddress [
	endAddress - (nCounters * CounterBytes)
		to: endAddress - CounterBytes
		by: CounterBytes
		do: [:address|
			objectMemory
				long32At: address
				put: (initialCounterValue << 16 + initialCounterValue)]
]

{ #category : #'generate machine code' }
SistaCogitClone >> fillInCounters: nCounters atStartAddress: startAddress [
	startAddress
		to: startAddress + (nCounters - 1 * CounterBytes)
		by: CounterBytes
		do: [:address|
			objectMemory
				long32At: address
				put: (initialCounterValue << 16 + initialCounterValue)]
]

{ #category : #'generate machine code' }
SistaCogitClone >> fillInMethodHeader: method size: size selector: selector [
	super fillInMethodHeader: method size: size selector: selector.
	self fillInCounters: numCounters atStartAddress: counters.
	method counters: counters.
	^method
]

{ #category : #'generate machine code' }
SistaCogitClone >> fillInOPICHeader: pic numArgs: numArgs selector: selector [
	pic counters: 0.
	^super fillInOPICHeader: pic numArgs: numArgs selector: selector
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genBinaryConstOpVarInlinePrimitive: prim [
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

		"2016 through 2019, bitAnd:, bitOr:, bitXor, bitShift:, SmallInteger op SmallInteger => SmallInteger, no overflow"
		[16] -> [ self AndCq: val R: ra ].
		[17] -> [ self OrCq: val R: ra ].
		[18] -> [ self XorCw: untaggedVal R: ra. ].

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
SistaCogitClone >> genBinaryInlineComparison: opTrue opFalse: opFalse destReg: destReg [
	"Inlined comparison. opTrue = jump for true and opFalse = jump for false"
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	| nextPC branchDescriptor targetBytecodePC postBranchPC |	
		
	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetBytecodePC := target ].
	
	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse])
		ifTrue: "This is the path where the inlined comparison is followed immediately by a branch"
			[ (self fixupAt: nextPC - initialPC) notAFixup
				ifTrue: "The next instruction is dead.  we can skip it."
					[deadCode := true.
				 	 self ensureFixupAt: targetBytecodePC - initialPC.
					 self ensureFixupAt: postBranchPC - initialPC ]
				ifFalse:
					[self ssPushConstant: objectMemory trueObject]. "dummy value"
			self genConditionalBranch: (branchDescriptor isBranchTrue ifTrue: [opTrue] ifFalse: [opFalse])
				operand: (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger. 
			deadCode ifFalse: [ self Jump: (self ensureNonMergeFixupAt: postBranchPC - initialPC) ] ]
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
SistaCogitClone >> genBinaryVarOpConstInlinePrimitive: prim [
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

		"2016 through 2019, bitAnd:, bitOr:, bitXor, bitShift:, SmallInteger op SmallInteger => SmallInteger, no overflow"
		[16] -> [ self AndCq: val R: rr ].
		[17] -> [ self OrCq: val R: rr ].
		[18] -> [ self flag: 'could use XorCq:'.
				self XorCw: untaggedVal R: rr. ].

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
SistaCogitClone >> genBinaryVarOpVarInlinePrimitive: prim [
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

		"2016 through 2019, bitAnd:, bitOr:, bitXor, bitShift:, SmallInteger op SmallInteger => SmallInteger, no overflow"
		[16] -> [ self AndR: ra R: rr ].
		[17] -> [ self OrR: ra R: rr ].
		[18] -> [objectRepresentation genRemoveSmallIntegerTagsInScratchReg: ra. 
				self XorR: ra R: rr. ].


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

{ #category : #'bytecode generators' }
SistaCogitClone >> genCallPrimitiveBytecode [
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#inlinePrimitiveBytecode:"
	| prim |
	byte2 < 128 ifTrue:
		[^bytecodePC = initialPC
			ifTrue: [0]
			ifFalse: [EncounteredUnknownBytecode]].
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

{ #category : #'bytecode generator support' }
SistaCogitClone >> genExecutionCountLogicInto: binaryBlock counterReg: counterReg [
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
SistaCogitClone >> genExtJumpIfNotInstanceOfBehaviorsBytecode [
	"SistaV1: *	254		11111110	kkkkkkkk	jjjjjjjj		branch If Not Instance Of Behavior/Array Of Behavior kkkkkkkk (+ Extend A * 256, where Extend A >= 0) distance jjjjjjjj (+ Extend B * 256, where Extend B >= 0)"
								
	| reg literal distance targetFixUp inverse |
	
	"We loose the information of in which register is stack top 
	when jitting the branch target so we need to flush everything. 
	We could use a fixed register here...."
	reg := self allocateRegForStackEntryAt: 0.
	self ssTop popToReg: reg.
	self ssFlushTo: simStackPtr. "flushed but the value is still in reg"
	
	self genPopStackBytecode.
	
	literal := self getLiteral: (extA * 256 + byte1).
	extA := 0.
	extB < 0 
		ifTrue: [extB := extB + 128. inverse := true]
		ifFalse: [inverse := false].
	distance := extB * 256 + byte2.
	extB := 0.
	numExtB := 0.
	
	targetFixUp := self cCoerceSimple: (self ensureFixupAt: bytecodePC + 3 + distance - initialPC) to: #'AbstractInstruction *'.
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
SistaCogitClone >> genFallsThroughCountLogicCounterReg: counterReg counterAddress: counterAddress [
	<inline: true>
	"Gen this when the branch has not been taken and forwarders have been followed."
	self SubCq: 1 R: counterReg. "Count untaken"
	self MoveR: counterReg A32: counterAddress. "write back"
]

{ #category : #'bytecode generators' }
SistaCogitClone >> genForwardersInlinedIdenticalOrNotIf: orNot [
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
	
	"We could use (branchDescriptor isBranchTrue xor: orNot) to simplify this."
	orNot 
		ifFalse: [branchDescriptor isBranchTrue
					ifTrue: 
						[ fixup := (self ensureNonMergeFixupAt: postBranchPC - initialPC) asUnsignedInteger.
						self JumpZero:  (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger ]
					ifFalse: "branchDescriptor is branchFalse"
						[ fixup := (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.
						self JumpZero: (self ensureNonMergeFixupAt: postBranchPC - initialPC) asUnsignedInteger ]]
		ifTrue: [branchDescriptor isBranchTrue
					ifFalse: "branchDescriptor is branchFalse"
						[ fixup := (self ensureNonMergeFixupAt: postBranchPC - initialPC) asUnsignedInteger.
						self JumpZero:  (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger ]
					ifTrue:
						[ fixup := (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.
						self JumpZero: (self ensureNonMergeFixupAt: postBranchPC - initialPC) asUnsignedInteger ]].
	
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
	
	(self fixupAt: nextPC - initialPC) notAFixup ifTrue: [ branchReachedOnlyForCounterTrip := true ].
	
	^ 0
]

{ #category : #initialization }
SistaCogitClone >> genMustBeBooleanTrampolineFor: boolean called: trampolineName [
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
SistaCogitClone >> genNullaryInlinePrimitive: prim [
	"Nullary inline primitives."
	"SistaV1: 248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 See EncoderForSistaV1's class comment and StackInterpreter>>#nullaryInlinePrimitive:"

	<option: #SistaVM>
	^EncounteredUnknownBytecode
]

{ #category : #'bytecode generators' }
SistaCogitClone >> genSpecialSelectorComparisonWithoutCounters [
	"This method is there because if I put directly the super send in genSpecialSelectorComparison Slang does not correctly translte the code to C, it does not correctly type one of the branchDescriptor to BytecodeDescriptor"
	^ super genSpecialSelectorComparison
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genTrinaryInlinePrimitive: prim [
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
				objectRepresentation genConvertIntegerToSmallIntegerInReg: ra2. ]
	}
	otherwise: [^EncounteredUnknownBytecode].
	self ssPushRegister: ra2.
	^0
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genUnaryInlinePrimitive: prim [
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
					genGetInstanceOf: self ssTop constant
						into: resultReg
							initializingIf: self extBSpecifiesInitializeInstance) ~= 0 ifTrue:
					[^ShouldNotJIT]. "e.g. bad class"
				 self ssPop: 1]
				  }
		otherwise:
			[^EncounteredUnknownBytecode].
	extB := 0.
	numExtB := 0.
	self ssPushRegister: resultReg.
	^0
]

{ #category : #'bytecode generators' }
SistaCogitClone >> genUnconditionalTrapBytecode [
	"SistaV1: *	217		Trap"
	self ssFlushTo: simStackPtr.
	self CallRT: ceTrapTrampoline.
	self annotateBytecode: self Label.
	^0
]

{ #category : #'bytecode generators' }
SistaCogitClone >> genUnoptimizedSpecialSelectorComparison [
	"This method is there because if I put directly the super send in genSpecialSelectorComparison Slang does not correctly translte the code to C, it does not correctly type one of the branchDescriptor to BytecodeDescriptor"
	^ super genSpecialSelectorComparison
]

{ #category : #initialization }
SistaCogitClone >> generateSistaRuntime [
	"Trap sends Sista trap message to context with top of stack, so we don't need any arguments..."
	ceTrapTrampoline := self genTrampolineFor: #ceSistaTrap called: 'ceSistaTrapTrampoline'
]

{ #category : #'method introspection' }
SistaCogitClone >> getJumpTargetPCAt: pc [
	<api>
	^backEnd jumpTargetPCAt: pc
]

{ #category : #initialization }
SistaCogitClone >> initialize [
	super initialize.
	branchReachedOnlyForCounterTrip := false.
	cogMethodSurrogateClass := (objectMemory ifNil: [self class objectMemoryClass]) wordSize = 4
										ifTrue: [CogSistaMethodSurrogate32]
										ifFalse: [CogSistaMethodSurrogate64]
]

{ #category : #initialization }
SistaCogitClone >> initializeCodeZoneFrom: startAddress upTo: endAddress [
	initialCounterValue := MaxCounterValue.
	super initializeCodeZoneFrom: startAddress upTo: endAddress
]

{ #category : #'compile abstract instructions' }
SistaCogitClone >> maybeAllocAndInitCounters [
	<inline: true>
	self assert: counters = 0.
	counterIndex := 0.
	numCounters = 0 ifTrue:
		[^true].
	counters := objectRepresentation allocateCounters: numCounters.
	^counters ~= 0
]

{ #category : #'compile abstract instructions' }
SistaCogitClone >> maybeCountCounter [
	<inline: true>
	numCounters := numCounters + 1
]

{ #category : #'compile abstract instructions' }
SistaCogitClone >> maybeCounterIndex [
	<inline: true>
	^counterIndex
]

{ #category : #'compile abstract instructions' }
SistaCogitClone >> maybeFreeCounters [
	<inline: true>
	counters ~= 0 ifTrue:
		[objectRepresentation freeCounters: counters]
]

{ #category : #compaction }
SistaCogitClone >> maybeFreeCountersOf: aCogMethod [
	"Free any counters in the method."
	<inline: true>
	objectRepresentation freeCounters: aCogMethod counters
]

{ #category : #'compile abstract instructions' }
SistaCogitClone >> maybeInitNumCounters [
	<inline: true>
	numCounters := 0
]

{ #category : #'garbage collection' }
SistaCogitClone >> maybeMarkCountersIn: cogMethod [
	"In SIsta Spur counters are held on the heap in pinned objects which must be marked
	 to avoid them being garbage collected.  This is the hook through which that happens."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	objectRepresentation maybeMarkCounters: cogMethod counters
]

{ #category : #'compile abstract instructions' }
SistaCogitClone >> maybeSetCounterIndex: value [
	<inline: true>
	counterIndex := value
]

{ #category : #'simulation only' }
SistaCogitClone >> methodsCompiledToMachineCodeInto: arrayObject [
	<doNotGenerate>
	^methodZone methodsCompiledToMachineCodeInto: arrayObject
]

{ #category : #'simulation only' }
SistaCogitClone >> numMethods [
	<doNotGenerate>
	^methodZone numMethods
]

{ #category : #'method introspection' }
SistaCogitClone >> picDataFor: descriptor Annotation: isBackwardBranchAndAnnotation Mcpc: mcpc Bcpc: bcpc Method: cogMethodArg [
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
SistaCogitClone >> picDataFor: cogMethod into: arrayObj [
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
SistaCogitClone >> picDataForBlockEntry: blockEntryMcpc Method: cogMethod [
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
SistaCogitClone >> picDataForCounter: counter at: bcpc [
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
SistaCogitClone >> picDataForSendTo: cogMethod methodClassIfSuper: methodClassOrNil at: sendMcpc bcpc: sendBcpc [
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
SistaCogitClone >> populate: tuple withPICInfoFor: cPIC firstCacheTag: firstCacheTag [
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
SistaCogitClone >> printPICDataForMethods [
	<doNotGenerate>
	methodZone methodsDo:
		[:cogMethod|
		cogMethod cmType = CMMethod ifTrue:
			[(coInterpreter picDataFor: cogMethod) ifNotNil:
				[:thePicData|
				coInterpreter printOop: thePicData]]]
]

{ #category : #'sista callbacks' }
SistaCogitClone >> resetCountersIn: cogMethod [
	<doNotGenerate>
	objectRepresentation resetCountersIn: cogMethod
]
