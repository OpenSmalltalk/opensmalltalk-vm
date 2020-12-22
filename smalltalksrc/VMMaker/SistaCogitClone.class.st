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
SistaCogitClone class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^super ancilliaryClasses copyWith: SistaCogMethod
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

{ #category : #'accessing class hierarchy' }
SistaCogitClone class >> methodZoneClass [
	^SistaMethodZone
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

{ #category : #'compile abstract instructions' }
SistaCogitClone >> decodePushIntegerLongBefore: bcpc in: aMethodObj [
	<inline: true>
	| distance upperByte | 
	distance := objectMemory fetchByte: bcpc - 1 ofObject: aMethodObj.
	upperByte := objectMemory fetchByte: bcpc - 3 ofObject: aMethodObj.
	upperByte > 127 ifTrue: [upperByte := upperByte - 256].
	^ (upperByte << 8) + distance.
		 
]

{ #category : #accessing }
SistaCogitClone >> defaultCogCodeSize [
	"Return the default number of bytes to allocate for native code at startup.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file."
	<api>
	^2 * backEnd getDefaultCogCodeSize
]

{ #category : #disassembly }
SistaCogitClone >> disassembleMethod: surrogateOrAddress on: aStream [
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
SistaCogitClone >> genAtPutInlinePrimitive: prim [
	"The store check requires rr to be ReceiverResultReg"
	prim caseOf: {
		"3000	pointerAt:put:
		 Mutable pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)"
		[0] ->	[self genPointerAtPutMaybeContext: false storeCheck: false immutabilityCheck: false].
		"3001	storeCheckPointerAt:put:
		 Mutable pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)"
		[1] ->	[self genPointerAtPutMaybeContext: false storeCheck: true immutabilityCheck: false].
		"3002	maybeContextPointerAt:put:
		 Mutable pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)"
		[2] ->	[self genPointerAtPutMaybeContext: true storeCheck: false immutabilityCheck: false].
		"3003	maybeContextStoreCheckPointerAt:put:
		 Mutable pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)"
		[3] ->	[self genPointerAtPutMaybeContext: true storeCheck: true immutabilityCheck: false].
		"3004	byteAt:put:
		 Mutable byte object, Smi, 8 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)"
		[4] ->	[self genByteAtPut].
	}
	otherwise: [^EncounteredUnknownBytecode].
	^0
]

{ #category : #'inline primitive binary generators' }
SistaCogitClone >> genBinaryAtConstInlinePrimitive: primIndex [
	"2064	pointerAt:
	Pointer object (Fixed sized or not) and not a context, Smi =>  (1-based, optimised if arg1 is a constant)
	2065	maybeContextPointerAt:
	Pointer object (Fixed sized or not), Smi =>  (1-based, optimised if arg1 is a constant)
	2066	byteAt:
	byte object, Smi => 8 bits unsigned Smi (1-based, optimised if arg1 is a constant)
	2067	shortAt:
	short object, Smi => 16 bits unsigned Smi (1-based, optimised if arg1 is a constant)
	2068	wordAt:
	word object, Smi => 32 bits unsigned Smi (1-based, optimised if arg1 is a constant)
	2069	doubleWordAt:
	double word object, Smi => 64 bits unsigned Smi or LargePositiveInteger (1-based, optimised if arg1 is a constant)"
	| rr val zeroBasedIndex |
	val := self ssTop constant.
	rr := primIndex = 65 
		ifFalse: [self allocateRegForStackEntryAt: 1]
		ifTrue: [self ssAllocateRequiredReg: ReceiverResultReg.
				self voidReceiverResultRegContainsSelf.
				ReceiverResultReg].
	(self ssValue: 1) popToReg: rr.
	self ssPop: 2.
	zeroBasedIndex := (objectMemory integerValueOf: val) - 1.
	primIndex caseOf: {
		[64] ->	[objectRepresentation genLoadSlot: zeroBasedIndex sourceReg: rr destReg: rr].
		[65] ->	[self ssAllocateRequiredReg: SendNumArgsReg.
				 ^self genPushMaybeContextSlotIndex: zeroBasedIndex].
		[66] ->	[self MoveMb: zeroBasedIndex + objectMemory baseHeaderSize r: rr R: rr.
				 objectRepresentation genConvertIntegerToSmallIntegerInReg: rr]
	}
	otherwise: [^EncounteredUnknownBytecode].
	^self ssPushRegister: rr
]

{ #category : #'inline primitive binary generators' }
SistaCogitClone >> genBinaryAtInlinePrimitive: primIndex [
	"2064	pointerAt:
	Pointer object (Fixed sized or not) and not a context, Smi =>  (1-based, optimised if arg1 is a constant)
	2065	maybeContextPointerAt:
	Pointer object (Fixed sized or not), Smi =>  (1-based, optimised if arg1 is a constant)
	2066	byteAt:
	byte object, Smi => 8 bits unsigned Smi (1-based, optimised if arg1 is a constant)
	2067	shortAt:
	short object, Smi => 16 bits unsigned Smi (1-based, optimised if arg1 is a constant)
	2068	wordAt:
	word object, Smi => 32 bits unsigned Smi (1-based, optimised if arg1 is a constant)
	2069	doubleWordAt:
	double word object, Smi => 64 bits unsigned Smi or LargePositiveInteger (1-based, optimised if arg1 is a constant)"
	| ra rr adjust |
	self allocateRegForStackTopTwoEntriesInto: [:rTop :rNext | ra := rTop. rr := rNext ].
	self ssTop popToReg: ra.
	self ssPop: 1.
	self ssTop popToReg: rr.
	self ssPop: 1.
	primIndex caseOf: {
		[64] ->	[objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				adjust := (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1.
				adjust ~= 0 ifTrue: [ self AddCq: adjust R: ra. ]. 
				self MoveXwr: ra R: rr R: rr ].
		[66] ->	[objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				adjust := objectMemory baseHeaderSize - 1. 
				self AddCq: adjust R: ra.
				self MoveXbr: ra R: rr R: rr.
				objectRepresentation genConvertIntegerToSmallIntegerInReg: rr].
	}
	otherwise: [^EncounteredUnknownBytecode].
	^self ssPushRegister: rr
]

{ #category : #'inline primitive binary generators' }
SistaCogitClone >> genBinaryCompInlinePrimitive: primIndex [
	"2032	>
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2033	<
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2034	>=
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2035	<=
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2036	=
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2037	~=
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2038	rawEqualsEquals:
	not a forwarder, not a forwarder => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2039	rawNotEqualsEquals:
	not a forwarder, not a forwarder => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)"
	|resultReg otherReg opTrue opFalse invertedOpTrue invertedOpFalse|
	self assert: (primIndex between: 32 and: 39).
	primIndex caseOf: {
		[32]	->	[opTrue := JumpGreater. opFalse := JumpLessOrEqual. invertedOpTrue := JumpLess. invertedOpFalse := JumpGreaterOrEqual].
		[33]	->	[opTrue := JumpLess. opFalse := JumpGreaterOrEqual. invertedOpTrue := JumpGreater. invertedOpFalse := JumpLessOrEqual].
		[34]	->	[opTrue := JumpGreaterOrEqual. opFalse := JumpLess. invertedOpTrue := JumpLessOrEqual. invertedOpFalse := JumpGreater].
		[35]	->	[opTrue := JumpLessOrEqual. opFalse := JumpGreater. invertedOpTrue := JumpGreaterOrEqual. invertedOpFalse := JumpLess].
		[36]	->	[opTrue := JumpZero. opFalse := JumpNonZero. invertedOpTrue := JumpZero. invertedOpFalse := JumpNonZero].
		[37]	->	[opTrue := JumpNonZero. opFalse := JumpZero. invertedOpTrue := JumpNonZero. invertedOpFalse := JumpZero].
		[38]	->	[opTrue := JumpZero. opFalse := JumpNonZero. invertedOpTrue := JumpZero. invertedOpFalse := JumpNonZero].
		[39]	->	[opTrue := JumpNonZero. opFalse := JumpZero. invertedOpTrue := JumpNonZero. invertedOpFalse := JumpZero].
	}.
	"Gen comparison"
	self ssTop type = SSConstant 
		ifTrue: [resultReg := self allocateRegForStackEntryAt: 1.
				(self ssValue: 1) popToReg: resultReg.
				self genCmpConstant: self ssTop constant R: resultReg.
				self ssPop: 2.
				self genBinaryInlineComparison: opTrue opFalse: opFalse destReg: resultReg.
				^self ssPushRegister: resultReg].
	(self ssValue: 1) type = SSConstant 
		ifTrue: [resultReg := self allocateRegForStackEntryAt: 0.
				self ssTop popToReg: resultReg.
				self genCmpConstant: (self ssValue: 1) constant R: resultReg.
				self ssPop: 2.
				self genBinaryInlineComparison: invertedOpTrue opFalse: invertedOpFalse destReg: resultReg.
				^self ssPushRegister: resultReg].
	otherReg := self allocateRegForStackEntryAt: 0.	
	self ssTop popToReg: otherReg.
	resultReg := self allocateRegForStackEntryAt: 1 notConflictingWith: (self registerMaskFor: otherReg).	
	(self ssValue: 1) popToReg: resultReg.
	self CmpR: otherReg R: resultReg.
	self ssPop: 2.
	self genBinaryInlineComparison: opTrue opFalse: opFalse destReg: resultReg.
	^self ssPushRegister: resultReg
	
	
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
		[2]	->	[objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
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

{ #category : #'inline primitive binary generators' }
SistaCogitClone >> genBinaryConstOpVarSmiInlinePrimitive: primIndex [
	| ra val untaggedVal |
	ra := self allocateRegForStackEntryAt: 0.
	self ssTop popToReg: ra.
	self ssPop: 1.
	val := self ssTop constant.
	self ssPop: 1.
	untaggedVal := val - objectMemory smallIntegerTag.
	primIndex caseOf: {
		"2000	+
		Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[0]	->	[self AddCq: untaggedVal R: ra].
		"2001	-
		Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[1]	->	[self MoveCq: val R: TempReg.
				 self SubR: ra R: TempReg.
				 objectRepresentation genAddSmallIntegerTagsTo: TempReg.
				 self MoveR: TempReg R: ra].
		"2002	*
		Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[2]	->	[objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				 self MoveCq: untaggedVal R: TempReg.
				 self MulR: TempReg R: ra.
				 objectRepresentation genSetSmallIntegerTagsIn: ra].
		
		"2016	bitAnd:
		 Smi, Smi => Smi (optimised if one operand is a constant)"
		[16] -> [ self AndCq: val R: ra ].
		"2017	bitOr:
		Smi, Smi => Smi (optimised if one operand is a constant)"
		[17] -> [ self OrCq: val R: ra ].
		"2018	bitXor:
		Smi, Smi => Smi (optimised if one operand is a constant)"
		[18] -> [ self XorCw: untaggedVal R: ra. ].
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

{ #category : #'inline primitive binary generators' }
SistaCogitClone >> genBinaryInlinePrimitive: primIndex [
	"Bulk comments: each sub-method has its own comment with the specific case.
	2000	+
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2001	-
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2002	*
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2003	/
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2004	//
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2005	\
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2006	quo:
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2016	bitAnd:
	Smi, Smi => Smi (optimised if one operand is a constant)
	2017	bitOr:
	Smi, Smi => Smi (optimised if one operand is a constant)
	2018	bitXor:
	Smi, Smi => Smi (optimised if one operand is a constant)
	2019	bitShiftLeft:
	Smi greater or equal to 0, Smi greater or equal to 0 => Smi (no overflow, optimised if arg1 is a constant)
	2020	bitShiftRight:
	Smi, Smi greater or equal to 0 => Smi (optimised if arg1 is a constant)
	2032	>
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2033	<
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2034	>=
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2035	<=
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2036	=
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2037	~=
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2038	rawEqualsEquals:
	not a forwarder, not a forwarder => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2039	rawNotEqualsEquals:
	not a forwarder, not a forwarder => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2048	rawNew:
	literal which is a fixed-sized behavior, Smi => instance of receiver, fields nilled out (optimised if arg1 is a constant)
	2049	rawNewNoInit:
	literal which is a fixed-sized behavior, Smi => instance of receiver (Fields of returned value contain undefined data, optimised if arg1 is a constant)
	2064	pointerAt:
	Pointer object (Fixed sized or not) and not a context, Smi =>  (1-based, optimised if arg1 is a constant)
	2065	maybeContextPointerAt:
	Pointer object (Fixed sized or not), Smi =>  (1-based, optimised if arg1 is a constant)
	2066	byteAt:
	byte object, Smi => 8 bits unsigned Smi (1-based, optimised if arg1 is a constant)
	2067	shortAt:
	short object, Smi => 16 bits unsigned Smi (1-based, optimised if arg1 is a constant)
	2068	wordAt:
	word object, Smi => 32 bits unsigned Smi (1-based, optimised if arg1 is a constant)
	2069	doubleWordAt:
	double word object, Smi => 64 bits unsigned Smi or LargePositiveInteger (1-based, optimised if arg1 is a constant)"
	(primIndex <= 18 and: [primIndex <= 2 or: [primIndex > 6]])  ifTrue: 
		[self ssTop type = SSConstant 
			ifTrue: [^self genBinaryVarOpConstSmiInlinePrimitive: primIndex].
		(self ssValue: 1) type = SSConstant 
			ifTrue: [^self genBinaryConstOpVarSmiInlinePrimitive: primIndex].
		^self genBinaryVarOpVarSmiInlinePrimitive: primIndex].
	primIndex <= 6 ifTrue: [^self genDivInlinePrimitive: primIndex].
	primIndex = 19 ifTrue: [^self genBinarySmiBitShiftLeftInlinePrimitive].
	primIndex = 20 ifTrue: [^self genBinarySmiBitShiftRightInlinePrimitive].
	primIndex < 32 ifTrue: [^EncounteredUnknownBytecode].
	primIndex <= 39 ifTrue: [^self genBinaryCompInlinePrimitive: primIndex].
	primIndex < 48 ifTrue: [^EncounteredUnknownBytecode].
	primIndex <= 49 ifTrue: [^self genBinaryNewInlinePrimitive: primIndex].
	primIndex < 64 ifTrue: [^EncounteredUnknownBytecode].
	primIndex <= 69 ifTrue: 
		[self ssTop type = SSConstant
			ifTrue: [^self genBinaryAtConstInlinePrimitive: primIndex].
		^self genBinaryAtInlinePrimitive: primIndex].
	^EncounteredUnknownBytecode
]

{ #category : #'inline primitive binary generators' }
SistaCogitClone >> genBinaryNewInlinePrimitive: primIndex [
	"2048	rawNew:
	literal which is a variable-sized behavior, Smi => instance of receiver, fields nilled/zeroed out (optimised if arg1 is a constant)
	2049	rawNewNoInit:
	literal which is a variable-sized behavior, Smi => instance of receiver (Fields of returned value contain undefined data, optimised if arg1 is a constant)"
	| resultReg classObj classFormat argInt |

	"Assertion"
	(self ssValue: 1) type = SSConstant ifFalse: [^UnimplementedOperation].
	
	"It would be nice to deal with variable-sized allocation on non-constant.
	We need to see, however, than inlined allocation cannot deal with large allocations (i.e.
	allocation directly in old space, > 65k currently. So Scorch still needs to perform range analysis
	or generate 2 paths at the bytecode level in this case."
	self ssTop type = SSConstant ifFalse: [^UnimplementedOperation].
	
	classObj := (self ssValue: 1) constant.
	self assert: (objectMemory isNonImmediate: classObj).
	self assert: (coInterpreter objCouldBeClassObj: classObj).
	self deny: (objectMemory isFixedSizePointerFormat: (objectMemory instSpecOfClassFormat: (objectMemory formatOfClass: classObj))).
	objectMemory classTagForClass: classObj. "Ensure Behavior hash"
	
	"Actual code"
	resultReg := self allocateRegNotConflictingWith: 0.
	classFormat := objectMemory instSpecOfClassFormat: (objectMemory formatOfClass: classObj).
	argInt := objectMemory integerValueOf: self ssTop constant.
	self ssPop: 2.
	self ssPushRegister: resultReg.
	(classFormat = objectMemory arrayFormat or: [classFormat = objectMemory indexablePointersFormat]) ifTrue: 
		[^objectRepresentation genGetInstanceOfPointerClass: classObj into: resultReg initializingIf: primIndex = 48 numVariableSlots: argInt].
	(classFormat = objectMemory firstByteFormat) ifTrue: 
		[^objectRepresentation genGetInstanceOfByteClass: classObj into: resultReg initializingIf: primIndex = 48 numBytes: argInt].
	^UnimplementedOperation
]

{ #category : #'inline primitive binary generators' }
SistaCogitClone >> genBinarySmiBitShiftLeftInlinePrimitive [
	"2019	bitShiftLeft:
	Smi greater or equal to 0, Smi greater or equal to 0 => Smi (no overflow, optimised if arg1 is a constant)"
	| rr ra |
	rr := self allocateRegForStackEntryAt: 1.
	(self ssValue: 1) popToReg: rr.
	objectRepresentation genRemoveSmallIntegerTagsInScratchReg: rr.
	self ssTop type = SSConstant 
		ifTrue: [self LogicalShiftLeftCq: (objectMemory integerValueOf: self ssTop constant) R: rr]
		ifFalse: [ra := self allocateRegForStackEntryAt: 0 notConflictingWith: (self registerMaskFor: rr).
				self ssTop popToReg: ra.
				objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				self LogicalShiftLeftR: ra R: rr.].
	objectRepresentation genAddSmallIntegerTagsTo: rr.
	self ssPop: 2.
	^self ssPushRegister: rr

]

{ #category : #'inline primitive binary generators' }
SistaCogitClone >> genBinarySmiBitShiftRightInlinePrimitive [
	"2019	bitShiftLeft:
	Smi greater or equal to 0, Smi greater or equal to 0 => Smi (no overflow, optimised if arg1 is a constant)"
	| rr ra |
	rr := self allocateRegForStackEntryAt: 1.
	(self ssValue: 1) popToReg: rr.
	self ssTop type = SSConstant 
		ifTrue: [self ArithmeticShiftRightCq: (objectMemory integerValueOf: self ssTop constant) R: rr]
		ifFalse: [ra := self allocateRegForStackEntryAt: 0 notConflictingWith: (self registerMaskFor: rr).
				self ssTop popToReg: ra.
				objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				 self ArithmeticShiftRightR: ra R: rr].
	objectRepresentation genClearAndSetSmallIntegerTagsIn: rr.
	self ssPop: 2.
	^self ssPushRegister: rr
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
				 objectRepresentation genConvertSmallIntegerToIntegerInReg: rr.
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

{ #category : #'inline primitive binary generators' }
SistaCogitClone >> genBinaryVarOpConstSmiInlinePrimitive: primIndex [
	| rr val untaggedVal |
	self assert: primIndex <= 18.
	val := self ssTop constant.
	self ssPop: 1.
	rr := self allocateRegForStackEntryAt: 0.
	self ssTop popToReg: rr.
	self ssPop: 1.
	untaggedVal := val - objectMemory smallIntegerTag.
	primIndex caseOf: {
		"2000	+
		 Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[0]	->	[self AddCq: untaggedVal R: rr].
		"2001	-
		 Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[1]	->	[self SubCq: untaggedVal R: rr ].
		"2002	*
		 Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[2]	->	[self flag: 'could use MulCq:R'.
				 objectRepresentation genConvertSmallIntegerToIntegerInReg: rr.
				 self MoveCq: untaggedVal R: TempReg.
				 self MulR: TempReg R: rr.
				 objectRepresentation genSetSmallIntegerTagsIn: rr].
		
		"2016	bitAnd:
		 Smi, Smi => Smi (optimised if one operand is a constant)"
		[16] -> [ self AndCq: val R: rr ].
		"2017	bitOr:
		 Smi, Smi => Smi (optimised if one operand is a constant)"
		[17] -> [ self OrCq: val R: rr ].
		"2018	bitXor:
		 Smi, Smi => Smi (optimised if one operand is a constant)"
		[18] -> [ self flag: 'could use XorCq:'.
				self XorCw: untaggedVal R: rr. ]

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
		[2]	->	[self genConvertSmallIntegerToIntegerInReg: rr.
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

{ #category : #'inline primitive binary generators' }
SistaCogitClone >> genBinaryVarOpVarSmiInlinePrimitive: primIndex [
	| ra rr |
	self allocateRegForStackTopTwoEntriesInto: [:rTop :rNext | ra := rTop. rr := rNext ].
	self ssTop popToReg: ra.
	self ssPop: 1.
	self ssTop popToReg: rr.
	self ssPop: 1.
	primIndex caseOf: {
		"2000	+
		Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[0]	->	[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: ra.
				 self AddR: ra R: rr].
		"2001	-
		Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[1]	->	[self SubR: ra R: rr.
				 objectRepresentation genAddSmallIntegerTagsTo: rr].
		"2002	*
		Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[2]	->	[self genConvertSmallIntegerToIntegerInReg: rr.
				 self genRemoveSmallIntegerTagsInScratchReg: ra.
				 self MulR: ra R: rr.
				 self genSetSmallIntegerTagsIn: rr].
			
		"2016	bitAnd:
		 Smi, Smi => Smi (optimised if one operand is a constant)"
		[16] -> [ self AndR: ra R: rr ].
		"2017	bitOr:
		Smi, Smi => Smi (optimised if one operand is a constant)"
		[17] -> [ self OrR: ra R: rr ].
		"2018	bitXor:
		Smi, Smi => Smi (optimised if one operand is a constant)"
		[18] -> [objectRepresentation genRemoveSmallIntegerTagsInScratchReg: ra. 
				self XorR: ra R: rr. ]
	}
	otherwise: [^EncounteredUnknownBytecode].
	self ssPushRegister: rr.
	^0
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genByteAtPut [
	| ra1 ra2 rr adjust |
	self 
		allocateRegForStackTopThreeEntriesInto: [:rTop :rNext :rThird | ra2 := rTop. ra1 := rNext. rr := rThird ] 
		thirdIsReceiver: false.
	self assert: (rr ~= ra1 and: [rr ~= ra2 and: [ra1 ~= ra2]]).
	self ssTop popToReg: ra2.
	self ssPop: 1.
	self ssTop popToReg: ra1.
	self ssPop: 1.
	self ssTop popToReg: rr.
	self ssPop: 1.
	adjust := objectMemory baseHeaderSize - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
	objectRepresentation genConvertSmallIntegerToIntegerInReg: ra1.
	objectRepresentation genConvertSmallIntegerToIntegerInReg: ra2.
	self AddCq: adjust R: ra1.
	self MoveR: ra2 Xbr: ra1 R: rr.
	objectRepresentation genConvertIntegerToSmallIntegerInReg: ra2.
	^self ssPushRegister: ra2
]

{ #category : #'mapped inline primitive generators' }
SistaCogitClone >> genByteAtPutImmutabilityCheck [
	| ra1 ra2 rr adjust mutableJump immutabilityFailure indexIsCst |
	<var: #mutableJump type: #'AbstractInstruction *'>
	<var: #immutabilityFailure type: #'AbstractInstruction *'>
	"Assumes rr is not a context and no store check is needed"
	indexIsCst := (self ssValue: 1) type = SSConstant.
	rr := ReceiverResultReg.
	ra1 := TempReg.
	ra2 := ClassReg.
	self voidReceiverResultRegContainsSelf.
	self ssFlushTo: simStackPtr - 1. "we use top value immediately after, so it does not require flush"
	self ssTop popToReg: ra2.
	adjust := objectMemory baseHeaderSize - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
	indexIsCst
		ifFalse:
			[(self ssValue: 1) popToReg: ra1.
			objectRepresentation genConvertSmallIntegerToIntegerInReg: ra1.
			self AddCq: adjust R: ra1]
		ifTrue: [self MoveCq: (objectMemory integerValueOf: (self ssValue: 1) constant) + adjust R: ra1].
	(self ssValue: 2) popToReg: rr.
	self ssPop: 3.
	self ssPushRegister: ra2.

	"Everything is flushed except returned value. All regs are unused except rr ra1 ra2"
	mutableJump := self genJumpMutable: rr scratchReg: Arg0Reg.
	self PushR: ra2. "flush sim stack top"
	self SubCq: 1 + adjust R: ra1. "index 0-relative for trampoline, ra1 unused afterwards"
	objectRepresentation genVarIndexCallStoreTrampoline.
	self PopR: ra2. "restore sim stack top"
	immutabilityFailure := self Jump: 0.
	
	mutableJump jmpTarget: (self MoveR: ra2 R: Arg0Reg).
	objectRepresentation genConvertSmallIntegerToIntegerInReg: Arg0Reg.
	self MoveR: Arg0Reg Xbr: ra1 R: rr.
	
	immutabilityFailure jmpTarget: self Label.
	^0
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genByteEqualsInlinePrimitive: prim [

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
			[ self assert: self ssTop spilled not.
			  str1Reg := self allocateRegForStackEntryAt: 1 notConflictingWith: self emptyRegisterMask.
			  str2Reg := self allocateRegForStackEntryAt: 2 notConflictingWith: (self registerMaskFor: str1Reg).
			  lenReg := self allocateRegForStackEntryAt: 0 notConflictingWith: (self registerMaskFor: str1Reg and: str2Reg).
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
SistaCogitClone >> genByteEqualsInlinePrimitiveCmp: str1Reg with: str2Reg scratch1: scratch1Reg scratch2: scratch2Reg field: index [
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
SistaCogitClone >> genByteEqualsInlinePrimitiveResult: jmp returnReg: reg [
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

{ #category : #'mapped inline primitive generators' }
SistaCogitClone >> genCallMappedInlinedPrimitive [
	"SistaV1:	236		11101100	iiiiiiii		callMappedInlinedPrimitive"
	^ self genMappedInlinePrimitive: byte1
]

{ #category : #'bytecode generators' }
SistaCogitClone >> genCallPrimitiveBytecode [
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
	self assert: primSet = 0.
	
	^ self genSistaInlinePrimitive: prim
]

{ #category : #'mapped inline primitive generators' }
SistaCogitClone >> genDirectCall [
	"250	directCall
	literal index of the method to call on top of stack =>  (variable number of parameters)"
	| newMethod newMethodHeader newMethodArgCount sendTable annotation litIndex |
	self assert: (self ssTop type = SSConstant and: [objectMemory isCompiledMethod: self ssTop constant]).
	litIndex := objectMemory integerValueOf: self ssTop constant.
	newMethod := self getLiteral: litIndex.
	self ssPop: 1.
	self flag: #TODO. "One needs to finish the implementation with the annotation and the sendTable"
	sendTable := 1. "directCallSendTable"
	annotation := 1. "directCallAnnotation"
	newMethodHeader := self rawHeaderOf: newMethod.
	newMethodArgCount := self argumentCountOfMethodHeader: methodHeader.
	"The receiver cannot be a forwader"
	"numArgs >= (NumSendTrampolines - 1) ifTrue:
		[self MoveCq: newMethodArgCount R: SendNumArgsReg]."
	"Load inline cache with method index"
	"self MoveUniqueC32: litIndex R: ClassReg.
	(self Call: (sendTable at: (newMethodArgCount min: NumSendTrampolines - 1))) annotation: annotation.
	self voidReceiverOptStatus.
	self ssPushRegister: ReceiverResultReg."
	^ EncounteredUnknownBytecode "Need to finish implementation"
]

{ #category : #'inline primitive binary generators' }
SistaCogitClone >> genDivInlinePrimitive: primIndex [
	"2003	/
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant) "
	"2004	//
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant) "
	"2005	\\
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant) "
	"2006	quo:
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant) "
	
	"We don't deal with constants here. Too complex and does nto bring much"
	| ra rr jumpExact jumpSameSign |
	<var: #jumpExact type: #'AbstractInstruction *'>
	<var: #jumpSameSign type: #'AbstractInstruction *'>
	self allocateRegForStackTopTwoEntriesInto: [:rTop :rNext | ra := rTop. rr := rNext ].
	self ssTop popToReg: ra.
	self ssPop: 1.
	self ssTop popToReg: rr.
	self ssPop: 1.
	self assert: backEnd canDivQuoRem.
	"arg non zero, no overflow check. / remains (unused in optimised code)"
	primIndex caseOf: {
		[4] ->	[objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				objectRepresentation genConvertSmallIntegerToIntegerInReg: rr.
				self DivR: ra R: rr Quo: rr Rem: TempReg.
				"If remainder is zero, success"
				self CmpCq: 0 R: TempReg.
				jumpExact := self JumpZero: 0.
				"If arg and remainder signs are different we must round down."
				objectRepresentation genConvertIntegerToSmallIntegerInReg: ra.
				self XorR: TempReg R: ra.
				(self lastOpcode setsConditionCodesFor: JumpZero) ifFalse:
					[self CmpCq: 0 R: ra].
				jumpSameSign := self JumpGreaterOrEqual: 0.
				self SubCq: 1 R: rr.
				jumpSameSign jmpTarget: (jumpExact jmpTarget: self Label).
				objectRepresentation genConvertIntegerToSmallIntegerInReg: rr ].
		[5] ->	[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: ra.
				objectRepresentation genRemoveSmallIntegerTagsInScratchReg: rr.
			 	self DivR: ra R: rr Quo: TempReg Rem: rr.
				"If remainder is zero we're done."
				self CmpCq: 0 R: rr.
				jumpExact := self JumpZero: 0.
				"If arg and remainder signs are different we must reflect around zero."
				self XorR: rr R: ra.
				(self lastOpcode setsConditionCodesFor: JumpZero) ifFalse:
					[self CmpCq: 0 R: ra].
				jumpSameSign := self JumpGreaterOrEqual: 0.
				self XorR: rr R: ra.
				self AddR: ra R: rr.
				jumpSameSign jmpTarget: (jumpExact jmpTarget: self Label).
				objectRepresentation genSetSmallIntegerTagsIn: rr ].
		[6] ->	[objectRepresentation genConvertSmallIntegerToIntegerInReg: ra.
				objectRepresentation genConvertSmallIntegerToIntegerInReg: rr.
				self DivR: ra R: rr Quo: rr Rem: ra.
				objectRepresentation genConvertIntegerToSmallIntegerInReg: rr].
	} otherwise: [^EncounteredUnknownBytecode].
	self ssPushRegister: rr.
	^0
]

{ #category : #'mapped inline primitive generators' }
SistaCogitClone >> genEnsureEnoughSlots [
	"50	EnsureEnoughWords
	 literal which is a Smi => ret value is receiver"
	|slots skip|
	<var: #skip type: #'AbstractInstruction *'>
	self assert: (self ssTop type = SSConstant and: [objectMemory isIntegerObject: self ssTop constant]).
	slots := objectMemory integerValueOf: self ssTop constant.
	self ssFlushTo: simStackPtr - 1.
	self
		MoveAw: objectMemory freeStartAddress R: TempReg;
		CmpCq: objectMemory getScavengeThreshold - (objectMemory bytesPerOop * slots) R: TempReg.
	skip := self JumpBelow: 0.
	objectRepresentation genSetGCNeeded.
	self CallRT: ceCheckForInterruptTrampoline.
	skip jmpTarget: self Label.
	self annotateBytecode: skip getJmpTarget.
	^0
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

{ #category : #'bytecode generator support' }
SistaCogitClone >> genFallsThroughCountLogicCounterReg: counterReg counterAddress: counterAddress [
	<inline: true>
	"Gen this when the branch has not been taken and forwarders have been followed."
	self SubCq: 1 R: counterReg. "Count untaken"
	self MoveR: counterReg A32: counterAddress. "write back"
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genJumpBinaryInlinePrimitive: primIndex [
	| target testReg |
	self assert: self ssTop type = SSConstant.
	target := self eventualTargetOf: ((objectMemory integerValueOf: self ssTop constant) + 3 + bytecodePC).
	testReg := self allocateRegForStackEntryAt: 1.
	(self ssValue: 1) popToReg: testReg.
	self ssPop: 2.
	primIndex caseOf: {
		"7016	jumpIfWritable:
		 Not a forwarder, literal which is a Smi"
		[16]	->	[self cppIf: #IMMUTABILITY
						ifTrue: [(objectRepresentation genJumpMutable: testReg scratchReg: TempReg) jmpTarget: (self ensureFixupAt: target).]
						ifFalse: [self Jump: (self ensureFixupAt: target)].
					^0].
		"7017	jumpIfReadOnly:
		 Not a forwarder, literal which is a Smi"
		[17]	->	[self cppIf: #IMMUTABILITY
						ifTrue: [(objectRepresentation genJumpImmutable: testReg scratchReg: TempReg) jmpTarget: (self ensureFixupAt: target)]
						ifFalse: [0"Do nothing - fall through"].
					^0].
		"7018	jumpIfYoung:
		 Not a forwarder, literal which is a Smi"
		[18]	->	[self CmpCw: objectMemory storeCheckBoundary R: testReg.
	 				 self JumpBelow: (self ensureFixupAt: target).
					 ^0].
		"7019	jumpIfOld:
		 Not a forwarder, literal which is a Smi"
		[19]	->	[self CmpCw: objectMemory storeCheckBoundary R: testReg.
	 				 self JumpAboveOrEqual: (self ensureFixupAt: target).
					^0].
	}. 
	^ EncounteredUnknownBytecode
	
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genJumpTrinaryInlinePrimitive: primIndex [
	"Note: those tests work with forwarders (wrong class index)"
	| testReg target behavior targetFixUp |
	<var: #targetFixUp type: #'BytecodeFixup *'>
	self assert: self ssTop type = SSConstant.
	self assert: (self ssValue: 1) type = SSConstant.
	testReg := self allocateRegForStackEntryAt: 2.
	(self ssValue: 2) popToReg: testReg.
	behavior := (self ssValue: 1) constant.
	target := self eventualTargetOf: ((objectMemory integerValueOf: self ssTop constant) + 3 + bytecodePC).
	self ssPop: 3.
	targetFixUp := self cCoerceSimple: (self ensureFixupAt: target) to: #'AbstractInstruction *'.
	primIndex caseOf: {
	[0] -> 	["8000	jumpIfInstanceOf:distance:
			 Anything, literal which is a Behavior, literal which is a Smi"
			objectRepresentation branchIf: testReg instanceOfBehavior: behavior target: targetFixUp.
			^0].
	[1] -> 	["8001	jumpIfNotInstanceOf:distance:
			 Anything, literal which is a Behavior, literal which is a Smi"
			 objectRepresentation branchIf: testReg notInstanceOfBehavior: behavior target: targetFixUp.
			^0].
	[2] -> 	["8002	jumpIfInstanceOfOneOf:distance:
			 Anything, Array of behaviors, literal which is a Smi"
			 objectRepresentation branchIf: testReg instanceOfBehaviors: behavior target: targetFixUp.
			^0].
	[3] -> 	["8003	jumpIfNotInstanceOfOneOf:distance:
			  Anything, Array of behaviors, literal which is a Smi"
			 objectRepresentation branchIf: testReg notInstanceOfBehaviors: behavior target: targetFixUp.
			^0].
	}.
	^ EncounteredUnknownBytecode
	
	
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genJumpUnaryInlinePrimitive: primIndex [
	"6000	backjumpNoInterrupt
	 literal which is a Smi"
	primIndex = 0 ifTrue: 
		[|targetBytecodePC|
		 self assert: self ssTop type = SSConstant.
		 targetBytecodePC := (objectMemory integerValueOf: self ssTop constant) + 3 + bytecodePC.
		 self ssPop: 1.
		 self ssFlushTo: simStackPtr.
		 deadCode := true. "can't fall through"
		 self Jump: (self fixupAt: targetBytecodePC).
		 ^0].
	^EncounteredUnknownBytecode
]

{ #category : #'mapped inline primitive generators' }
SistaCogitClone >> genMappedInlinePrimitive: primIndex [
	"SistaV1:	236		11101100	iiiiiiii		callMappedInlinedPrimitive"
	"Number of arguments:
	 0-49 nullary
	 50-99 unary
	 100-149  binary
	 150-199 trinary
	 200-255 variable"
	"Specification:
	50	EnsureEnoughWords
	literal which is a Smi => ret value is receiver
	150	immCheckPointerAt:put:
	pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	151	immCheckStoreCheckPointerAt:put:
	pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	152	immCheckMaybeContextPointerAt:put:
	pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	153	immCheckMaybeContextStoreCheckPointerAt:put:
	pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	154	immCheckByteAt:put:
	byte object, Smi, 8 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)
	155	immCheckShortAt:put:
	short object, Smi, 16 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)
	156	immCheckWordAt:put:
	word object, Smi, 32 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)
	157	immCheckDoubleWordAt:put:
	double word object, Smi, 64 bits unsigned Smi or LargePositiveInteger => arg2 (1-based, optimised if arg1 is a constant)
	250	directCall
	method to call on top of stack =>  (variable number of parameters)"
	primIndex caseOf: 
	{ 
		[50] ->	 [^self genEnsureEnoughSlots].
		[150] -> [^self genPointerAtPutMaybeContext: false storeCheck: false immutabilityCheck: true].
		[151] -> [^self genPointerAtPutMaybeContext: false storeCheck: true immutabilityCheck: true].
		[152] -> [^self genPointerAtPutMaybeContext: true storeCheck: false immutabilityCheck: true].
		[153] -> [^self genPointerAtPutMaybeContext: true storeCheck: true immutabilityCheck: true].
		[154] -> [self cppIf: #IMMUTABILITY
					ifTrue: [^self genByteAtPutImmutabilityCheck]
					ifFalse: [self genByteAtPut.
							self annotateBytecode: self Label.
							 ^0]].
		[155] -> [^EncounteredUnknownBytecode "not implemented, missing short instruction in Cog RTL"].
		[156] -> [^EncounteredUnknownBytecode "not implemented, need to deal with LargePositiveInteger in 32 bits"].
		[157] -> [^EncounteredUnknownBytecode "not implemented, need to deal with LargePositiveInteger in 64 bits"].
		[250] -> [^self genDirectCall].
	} otherwise: [^EncounteredUnknownBytecode].
	
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genMoveAndAdjustSSEntry: ssEntry into: reg [
	<var: #ssEntry type: #'SimStackEntry *'>
	<inline: true>
	| adjust |
	adjust := (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
	ssEntry type = SSConstant 
		ifTrue: [self MoveCq: (objectMemory integerValueOf: ssEntry constant) + adjust R: reg.
			      ssEntry spilled ifTrue: [self AddCq: objectMemory wordSize R: SPReg]]
		ifFalse: 
			[ssEntry popToReg: reg.
			 objectRepresentation genConvertSmallIntegerToIntegerInReg: reg.
			 adjust ~= 0 ifTrue: [ self AddCq: adjust R: reg. ]].	
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
	<option: #SistaVM>
	^EncounteredUnknownBytecode
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genPointerAtPutConstantMaybeContext: maybeContext storeCheck: needsStoreCheck immutabilityCheck: needsImmCheck [ 
	| rcvrReg valReg indexCst |
	indexCst := (objectMemory integerValueOf: (self ssValue: 1) constant) - 1.
	"we want to have on top of stack the value to write descriptor."
	(maybeContext or: [needsImmCheck]) 
		ifTrue: [ valReg := ClassReg.
				 self voidReceiverResultRegContainsSelf.
				 rcvrReg := ReceiverResultReg ]
		ifFalse: [ valReg := self allocateRegForStackEntryAt: 0 notConflictingWith: 0.
				  needsStoreCheck 
					ifFalse: [rcvrReg := self allocateRegForStackEntryAt: 2 notConflictingWith: (self registerMaskFor: valReg)]
					ifTrue: [self voidReceiverResultRegContainsSelf.
							rcvrReg := ReceiverResultReg]].
	"If rcvr is valReg, we flush it. Could generate a move instead but not that common"
	self ssAllocateRequiredReg: valReg upThrough: simStackPtr - 2.
	self ssAllocateRequiredReg: rcvrReg upThrough: simStackPtr - 3.
	self ssTop popToReg: valReg.
	self ssPop: 1.
	self ssTop spilled ifTrue: [self AddCq: objectRepresentation wordSize R: SPReg].
	self ssPop: 1.
	self ssTop popToReg: rcvrReg.
	self ssPop: 1.
	self ssPushRegister: valReg.
			
	maybeContext
		ifFalse: 
			[^self 
				genGenericStorePop: false 
				slotIndex: indexCst
				destReg: rcvrReg 
				needsStoreCheck: needsStoreCheck 
				needsRestoreRcvr: false 
				needsImmutabilityCheck: needsImmCheck]
		ifTrue:
			[^self
				genGenericStorePop: false 
				MaybeContextSlotIndex: indexCst
				needsStoreCheck: needsStoreCheck 
				needsRestoreRcvr: false 
				needsImmutabilityCheck: needsImmCheck]
]

{ #category : #'mapped inline primitive generators' }
SistaCogitClone >> genPointerAtPutImmCheckAndStoreCheck [
	| ra1 ra2 rr adjust scratchReg immutableJump jmpImmediate jmpDestYoung jmpSourceOld jumpRemembered indexIsCst |
	<var: #jmpSourceOld type: #'AbstractInstruction *'>
	<var: #jmpDestYoung type: #'AbstractInstruction *'>
	<var: #jmpImmediate type: #'AbstractInstruction *'>
	<var: #immutableJump type: #'AbstractInstruction *'>
	<var: #jumpRemembered type: #'AbstractInstruction *'>
	"Assumes rr is not a context and no store check is needed"
	indexIsCst := (self ssValue: 1) type = SSConstant.
	self ssFlushTo: simStackPtr - 3.
	rr := ReceiverResultReg.
	ra1 := TempReg.
	ra2 := ClassReg.
	scratchReg := Arg0Reg.
	adjust := (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
	(self ssValue: 2) popToReg: rr.
	indexIsCst
		ifFalse:
			[(self ssValue: 1) popToReg: ra1.
			objectRepresentation genConvertSmallIntegerToIntegerInReg: ra1.
			adjust ~= 0 ifTrue: [self AddCq: adjust R: ra1]]
		ifTrue: [self MoveCq: (objectMemory integerValueOf: (self ssValue: 1) constant) + adjust R: ra1].
	self ssTop popToReg: ra2.
	self ssPop: 3.
	self ssPushRegister: ra2.
	self voidReceiverResultRegContainsSelf.

	immutableJump := self genJumpImmutable: rr scratchReg: scratchReg.
	self MoveR: ra2 Xwr: ra1 R: rr.
	
	"store check"
	jmpImmediate := self genJumpImmediate: ra2.
	"Get the old/new boundary in scratchReg"
	self MoveCw: objectMemory storeCheckBoundary R: scratchReg.
	"Is target young?  If so we're done"
	self CmpR: scratchReg R: rr. "N.B. FLAGS := destReg - scratchReg"
	jmpDestYoung := self JumpBelow: 0.
	"Is value stored old?  If so we're done."
	self CmpR: scratchReg R: ra2. "N.B. FLAGS := valueReg - scratchReg"
	jmpSourceOld := self JumpAboveOrEqual: 0.
	"value is young and target is old.
	 Need to remember this only if the remembered bit is not already set."
	jumpRemembered := objectRepresentation genIfRequiredCheckRememberedBitOf: rr scratch: scratchReg.
	"Set the inst var index for the benefit of the immutability check. The trampoline will
	 repeat the check to choose between the immutbality violation and the store check."
	immutableJump jmpTarget: self Label.
	self PushR: ra2.
	self SubCq: 1 + adjust R: ra1. "index 0-relative for trampoline, ra1 unused afterwards"
	objectRepresentation genVarIndexCallStoreTrampoline.
	self PopR: ra2.
	jmpImmediate jmpTarget:
	(jmpDestYoung jmpTarget:
	(jmpSourceOld jmpTarget:
		self Label)).
	self setIfRequiredTargetOf: jumpRemembered toTargetOf: jmpImmediate.
	
	^0
]

{ #category : #'mapped inline primitive generators' }
SistaCogitClone >> genPointerAtPutImmCheckButNoStoreCheck [
	| ra1 ra2 rr adjust mutableJump immutabilityFailure indexIsCst |
	<var: #mutableJump type: #'AbstractInstruction *'>
	<var: #immutabilityFailure type: #'AbstractInstruction *'>
	"Assumes rr is not a context and no store check is needed"
	indexIsCst := (self ssValue: 1) type = SSConstant.
	self ssFlushTo: simStackPtr - 3.
	rr := ReceiverResultReg.
	ra1 := TempReg.
	ra2 := ClassReg.
	(self ssValue: 2) popToReg: rr.
	adjust := (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
	indexIsCst
		ifFalse:
			[(self ssValue: 1) popToReg: ra1.
			objectRepresentation genConvertSmallIntegerToIntegerInReg: ra1.
			adjust ~= 0 ifTrue: [self AddCq: adjust R: ra1]]
		ifTrue: [self MoveCq: (objectMemory integerValueOf: (self ssValue: 1) constant) + adjust R: ra1].
	self ssTop popToReg: ra2.
	self ssPop: 3.
	self ssPushRegister: ra2.
	self voidReceiverResultRegContainsSelf.

	mutableJump := self genJumpMutable: rr scratchReg: Arg0Reg.
	"simStack is flushed, but result is not"
	self PushR: ra2.
	self SubCq: 1 + adjust R: ra1. "index 0-relative for trampoline, ra1 unused afterwards"
	objectRepresentation genVarIndexCallStoreTrampoline.
	self PopR: ra2.
	immutabilityFailure := self Jump: 0.
	
	mutableJump jmpTarget: self Label.
	self MoveR: ra2 Xwr: ra1 R: rr.
	immutabilityFailure jmpTarget: self Label.
	^0
]

{ #category : #'mapped inline primitive generators' }
SistaCogitClone >> genPointerAtPutMaybeContext: maybeContext storeCheck: needsStoreCheck immutabilityCheck: needsImmCheck [
	"150	immCheckPointerAt:put:
	pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	151	immCheckStoreCheckPointerAt:put:
	pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	152	immCheckMaybeContextPointerAt:put:
	pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	153	immCheckMaybeContextStoreCheckPointerAt:put:
	pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)"
	| index |
	index := self ssValue: 1.
	"Instruction always annoted - uncommon, IMMUTABILITY disabled. We need a Nop since previous instr can be annotated."
	self cppIf: #IMMUTABILITY ifTrue: [] ifFalse: [ needsImmCheck ifTrue: [ self annotateBytecode: self Nop ] ].
	"Optimised case if arg1 is constant"
	index type = SSConstant 
		ifTrue:  [^self genPointerAtPutConstantMaybeContext: maybeContext storeCheck: needsStoreCheck immutabilityCheck: needsImmCheck].
	maybeContext ifTrue: [^EncounteredUnknownBytecode "not implemented, not used right now, for tempAt: optimisation on non constant"].
	self cppIf: #IMMUTABILITY ifTrue:
		[needsImmCheck
			ifTrue: [needsStoreCheck
				ifTrue: [^self genPointerAtPutImmCheckAndStoreCheck]
				ifFalse: [^self genPointerAtPutImmCheckButNoStoreCheck] ] ].
	^self genPointerAtPutStoreCheck: needsStoreCheck
]

{ #category : #'mapped inline primitive generators' }
SistaCogitClone >> genPointerAtPutStoreCheck: needsStoreCheck [ 
	| ra1 ra2 rr adjust |
	"Assumes rr is not a context and no immutability check is needed"
	"The store check requires rr to be ReceiverResultReg"
	self 
		allocateRegForStackTopThreeEntriesInto: [:rTop :rNext :rThird | ra2 := rTop. ra1 := rNext. rr := rThird ] 
		thirdIsReceiver: needsStoreCheck.
	self assert: (rr ~= ra1 and: [rr ~= ra2 and: [ra1 ~= ra2]]).
	self ssTop popToReg: ra2.
	self ssPop: 1.
	self ssTop popToReg: ra1.
	self ssPop: 1.
	self ssTop popToReg: rr.
	self ssPop: 1.
	objectRepresentation genConvertSmallIntegerToIntegerInReg: ra1.
	adjust := (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1. "shift by baseHeaderSize and then move from 1 relative to zero relative"
	adjust ~= 0 ifTrue: [ self AddCq: adjust R: ra1. ]. 
	self MoveR: ra2 Xwr: ra1 R: rr.
	needsStoreCheck ifTrue: 
		[ self assert: needsFrame. 
		objectRepresentation genStoreCheckReceiverReg: rr valueReg: ra2 scratchReg: TempReg inFrame: true].
	self ssPushRegister: ra2.
	^0
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genQuaternaryInlinePrimitive: prim [
	^ EncounteredUnknownBytecode
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genQuinaryInlinePrimitive: prim [
	^ EncounteredUnknownBytecode
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genSistaInlinePrimitive: prim [
	"SistaV1:	248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution. This is the dispatch for unmapped sista inlined primitives."
	
	prim < 1000 ifTrue:
		[^self genNullaryInlinePrimitive: prim].

	prim < 2000 ifTrue:
		[^self genUnaryInlinePrimitive: prim - 1000].
	
	prim < 3000 ifTrue:
		[^self genBinaryInlinePrimitive: prim - 2000].

	prim < 4000 ifTrue:
		[^self genTrinaryInlinePrimitive: prim - 3000].
	
	prim < 5000 ifTrue: 
		[^self genQuaternaryInlinePrimitive: prim - 4000].
	
	prim < 6000 ifTrue: 
		[^self genQuinaryInlinePrimitive: prim - 5000].
		
	 prim < 7000 ifTrue:
		[^self genJumpUnaryInlinePrimitive: prim - 6000].
	
 	prim < 8000 ifTrue:
		[^self genJumpBinaryInlinePrimitive: prim - 7000].
	
	^ self genJumpTrinaryInlinePrimitive: prim - 8000.
]

{ #category : #'bytecode generators' }
SistaCogitClone >> genSpecialSelectorComparisonWithoutCounters [
	"This method is there because if I put directly the super send in genSpecialSelectorComparison Slang does not correctly translte the code to C, it does not correctly type one of the branchDescriptor to BytecodeDescriptor"
	^ super genSpecialSelectorComparison
]

{ #category : #'inline primitive generators' }
SistaCogitClone >> genTrinaryInlinePrimitive: prim [
	"Bulk comment, each sub method has its own comment
	3000	pointerAt:put:
	Mutable pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	3001	storeCheckPointerAt:put:
	Mutable pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	3002	maybeContextPointerAt:put:
	Mutable pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	3003	maybeContextStoreCheckPointerAt:put:
	Mutable pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	3004	byteAt:put:
	Mutable byte object, Smi, 8 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)
	3005	shortAt:put:
	Mutable short object, Smi, 16 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)
	3006	wordAt:put:
	Mutable word object, Smi, 32 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)
	3007	doubleWordAt:put:
	Mutable double word object, Smi, 64 bits unsigned Smi or LargePositiveInteger => arg2 (1-based, optimised if arg1 is a constant)
	3021 is deprecated."
	prim <= 7 ifTrue: [^self genAtPutInlinePrimitive: prim].
	prim = 21 ifTrue: [^self genByteEqualsInlinePrimitive: prim].
	^ EncounteredUnknownBytecode
]

{ #category : #'inline primitive unary generators' }
SistaCogitClone >> genUnaryClassPrimitive [ 
	"1000	rawClass
	not a forwarder => Behavior (Same as class special send, but receiver is not a forwarder)"
	
	"Important performance note:
	In Scorch, typically a value is known as not being a forwarder if there is a trap.
	If the trap is due to a monomorphic send, the #class send leads to:
		trapIf: X notInstanceOf: C
		X rawClass
	therefore X rawClass is simplified in Scorch to the cst:C
	The rawClass is therefore used only for PICs. 
		trapIf: X notInstanceOf: C, C', C''
		X rawClass
	This unsafe operation is important to avoid register flush, but the performance 
	difference in differencing rawClass for immediate and rawClass for non immediate 
	classes is not that relevant"
	
	| topReg jumpIsImm destReg |
	<var: #jumpIsImm type: #'AbstractInstruction *'>
	topReg := self allocateRegForStackEntryAt: 0 notConflictingWith: 0.
	destReg := self allocateRegNotConflictingWith: (self registerMaskFor: topReg).
	self ssTop popToReg: topReg.
	
	"1. Read the class index"
	self MoveR: topReg R: TempReg.
	self AndCq: objectMemory tagMask R: TempReg.
	jumpIsImm := self JumpNonZero: 0.
	self flag: #endianness.
	"Get least significant half of header word in destReg"
	self MoveMw: 0 r: topReg R: TempReg.
	"mask off class index"
	self AndCq: objectMemory classIndexMask R: TempReg.
	
	"2. Read the class from class index"
	jumpIsImm jmpTarget: self Label.
	objectRepresentation genGetClassObjectOfClassIndex: TempReg into: destReg scratchReg: topReg.
	self ssPop: 1.
	^self ssPushRegister: destReg
]

{ #category : #'inline primitive unary generators' }
SistaCogitClone >> genUnaryConvertInlinePrimitive: primIndex [
	| resultReg |
	self assert: (primIndex between: 30 and: 32).
	primIndex caseOf: {
		"1030	characterAsInteger
		 Character => 22 bits strictly positive Smi (Unicode)"
		[30] -> [resultReg := self allocateRegForStackEntryAt: 0. 
				self ssTop popToReg: resultReg.
				objectRepresentation genConvertCharacterToSmallIntegerInReg: resultReg].
		"1031	smallFloatAsInteger
		 SmallFloat => Smi"
		[31] -> [^EncounteredUnknownBytecode "to implement"].
		"1032	smiAsFloat
		 Smi => SmallFloat"
		[32] -> [resultReg := self allocateRegForStackEntryAt: 0. 
				self ssTop popToReg: resultReg.
				self assert: self processorHasDoublePrecisionFloatingPointSupport.
				self MoveR: resultReg R: TempReg.
				self genConvertSmallIntegerToIntegerInReg: TempReg.
				self ConvertR: TempReg Rd: DPFPReg0.
				self flag: #TODO. "Should never fail"
				self
					genAllocFloatValue: DPFPReg0
					into: resultReg
					scratchReg: TempReg
					scratchReg: NoReg. "scratch2 for V3 only"] 
	}.
	self ssPop: 1.
	^self ssPushRegister: resultReg
]

{ #category : #'inline primitive unary generators' }
SistaCogitClone >> genUnaryHashInlinePrimitive: primIndex [
	| rcvrReg resultReg |
	self assert: (primIndex between: 20 and: 23).
	primIndex caseOf: {
		"1020	objectIdentityHash
		 non-immediate and non-behavior => 22 bits strictly positive Smi"
		[20] ->	[rcvrReg := self allocateRegForStackEntryAt: 0.
				 resultReg := self allocateRegNotConflictingWith: (self registerMaskFor: rcvrReg).
				 self ssTop popToReg: rcvrReg.
				 objectRepresentation genGetIdentityHash: rcvrReg resultReg: resultReg].
		"1021	smiIdentityHash
		 Smi => Smi"
		[21] -> [resultReg := self allocateRegForStackEntryAt: 0. 
				self ssTop popToReg: resultReg].		
		"1022	charIdentityHash
		 Character => 22 bits strictly positive Smi"
		[22] -> [resultReg := self allocateRegForStackEntryAt: 0. 
				self ssTop popToReg: resultReg.
				objectRepresentation genConvertCharacterToSmallIntegerInReg: resultReg].
		"1023	smallfloatIdentityHash
		 SmallFloat => Smi"
		[23] -> [resultReg := self allocateRegForStackEntryAt: 0. 
				objectRepresentation genConvertSmallFloatToSmallFloatHashAsIntegerInReg: resultReg scratch: TempReg].
		"1024	behaviorIdentityHash
		 Behavior => 22 bits strictly positive Smi"
		[24] -> [^EncounteredUnknownBytecode "not implemented"].	
		}.
		self ssPop: 1.
		^self ssPushRegister: resultReg
]

{ #category : #'inline primitive unary generators' }
SistaCogitClone >> genUnaryInlinePrimitive: primIndex [
	"Bulk comments: each sub-method has its own comment with the specific case.
	1000	rawClass
	not a forwarder => Behavior (Same as class special send, but receiver is not a forwarder)
	1001	numSlots
	pointer object => Smi between 0 and SmallInteger maxVal // 4 - 1 (Answers total size in pointer-sized slots)
	1002	numBytes
	byte object => Smi between 0 and SmallInteger maxVal - 9 (Includes compiled code)
	1003	numShorts
	short object => Smi between 0 and SmallInteger maxVal - 9
	1004	numWords
	word object => Smi between 0 and SmallInteger maxVal - 9
	1005	numDoubleWords
	double word object => Smi between 0 and SmallInteger maxVal - 9
	1011	RawNew
	literal which is a fixed-sized behavior => instance of the receiver with fields nilled out
	1012	RawNewNoInit
	literal which is a fixed-sized behavior => instance of the receiver (Fields of returned value contain undefined data)
	1020	objectIdentityHash
	non-immediate and non-behavior => 22 bits strictly positive Smi
	1021	smiIdentityHash
	Smi => Smi
	1022	charIdentityHash
	Character => 22 bits strictly positive Smi
	1023	smallfloatIdentityHash
	SmallFloat => Smi
	1024	behaviorIdentityHash
	Behavior => 22 bits strictly positive Smi
	1030	characterAsInteger
	Character => 22 bits strictly positive Smi (Unicode)
	1031	smallFloatAsInteger
	SmallFloat => Smi
	1032	smiAsFloat
	Smi => SmallFloat
	1040	unforward
	Anything => Not a forwarder
	1041	possibleRoot
	non-immediate, not a forwarder => receiver is returned (should be effect-only) (If old, becomes gray and remembered to allow many unchecked stores in a row afterwards)"
	primIndex = 0 ifTrue: [^self genUnaryClassPrimitive].
	primIndex <= 6 ifTrue: [^self genUnarySizeInlinePrimitive: primIndex].
	primIndex < 11 ifTrue: [^EncounteredUnknownBytecode].
	primIndex <= 12 ifTrue: [^self genUnaryNewInlinePrimitive: primIndex].
	primIndex < 20 ifTrue: [^EncounteredUnknownBytecode].
	primIndex <= 24 ifTrue: [^self genUnaryHashInlinePrimitive: primIndex].
	primIndex < 30 ifTrue: [^EncounteredUnknownBytecode].
	primIndex <= 32 ifTrue: [^self genUnaryConvertInlinePrimitive: primIndex].
	primIndex = 39 ifTrue: [^self genUnaryUnforwardNonImmediateInlinePrimitive].
	primIndex = 40 ifTrue: [^self genUnaryUnforwardInlinePrimitive].
	primIndex = 41 ifTrue: [^self genUnaryPossibleRootInlinePrimitive].
	^EncounteredUnknownBytecode
]

{ #category : #'inline primitive unary generators' }
SistaCogitClone >> genUnaryNewInlinePrimitive: primIndex [ 
	"1011	RawNew
	 literal which is a fixed-sized behavior => instance of the receiver with fields nilled out
	1012	RawNewNoInit
	literal which is a fixed-sized behavior => instance of the receiver (Fields of returned value contain undefined data)"
	| resultReg classObj |
	self assert: (self ssTop type = SSConstant).
	classObj := self ssTop constant.
	self assert: (objectMemory isNonImmediate: classObj).
	self assert: (coInterpreter objCouldBeClassObj: classObj).
	self assert: (objectMemory isFixedSizePointerFormat: (objectMemory instSpecOfClassFormat: (objectMemory formatOfClass: classObj))).
	objectMemory classTagForClass: classObj. "Ensure Behavior hash"
	resultReg := self allocateRegNotConflictingWith: 0.
	objectRepresentation genGetInstanceOfPointerClass: classObj into: resultReg initializingIf: primIndex = 11 numVariableSlots: 0.
	self ssPop: 1.
	^self ssPushRegister: resultReg
]

{ #category : #'inline primitive unary generators' }
SistaCogitClone >> genUnaryPossibleRootInlinePrimitive [
	"1041	possibleRoot
	 non-immediate, not a forwarder => receiver is returned (should be effect-only) (If old, becomes gray and remembered to allow many unchecked stores in a row afterwards)"
	| topReg jmpDestYoung jmpAlreadyRemembered|
	<var: #jmpDestYoung type: #'AbstractInstruction *'>
	<var: #jmpAlreadyRemembered type: #'AbstractInstruction *'>
	topReg := self allocateRegForStackEntryAt: 0 notConflictingWith: 0.
	self ssTop popToReg: topReg.
	self MoveCw: objectMemory storeCheckBoundary R: TempReg.
	 self CmpR: TempReg R: topReg.
	 jmpDestYoung := self JumpBelow: 0.
	 objectRepresentation checkRememberedInTrampoline ifFalse: 
		[jmpAlreadyRemembered := objectRepresentation genCheckRememberedBitOf: topReg scratch: TempReg].
	 objectRepresentation callStoreCheckTrampoline.
	 jmpDestYoung jmpTarget: self Label.
	 objectRepresentation checkRememberedInTrampoline ifFalse: 
		[jmpAlreadyRemembered jmpTarget: self Label].
	self ssPop: 1.
	^self ssPushRegister: topReg
]

{ #category : #'inline primitive unary generators' }
SistaCogitClone >> genUnarySizeInlinePrimitive: primIndex [ 
	| rcvrReg resultReg |
	self assert: (primIndex between: 1 and: 6).
	rcvrReg := self allocateRegForStackEntryAt: 0 notConflictingWith: 0.
	resultReg := self allocateRegNotConflictingWith: (self registerMaskFor: rcvrReg).
	self ssTop popToReg: rcvrReg.
	self ssPop: 1.
	self ssPushRegister: resultReg.
	primIndex caseOf: {
		"1001	numSlots
		 pointer object => Smi between 0 and SmallInteger maxVal // 4 - 1 (Answers total size in pointer-sized slots)"
		[1]	->	[objectRepresentation
					genGetNumSlotsOf: rcvrReg into: resultReg;
					genConvertIntegerToSmallIntegerInReg: resultReg].
		"1002	numBytes
		 byte object => Smi between 0 and SmallInteger maxVal - 9 (Includes compiled code)"
		[2]	->	[objectRepresentation
					genGetNumBytesOf: rcvrReg into: resultReg;
					genConvertIntegerToSmallIntegerInReg: resultReg].
		"1003	numShorts
		 short object => Smi between 0 and SmallInteger maxVal - 9"
		[3]	->	[^EncounteredUnknownBytecode "not implemented"].
		"1004	numWords
		 word object => Smi between 0 and SmallInteger maxVal - 9"
		[5]	->	[^EncounteredUnknownBytecode "not implemented"].
		"1005	numDoubleWords 
		 double word object => Smi between 0 and SmallInteger maxVal - 9"
		[6]	->	[^EncounteredUnknownBytecode "not implemented"].
	}..
	^ 0
]

{ #category : #'inline primitive unary generators' }
SistaCogitClone >> genUnaryUnforwardInlinePrimitive [
	"1040	unforward
	 Anything => Not a forwarder"
	| topReg |
	topReg := self allocateRegForStackEntryAt: 0 notConflictingWith: 0.
	self ssTop popToReg: topReg.
	objectRepresentation genEnsureOopInRegNotForwarded: topReg scratchReg: TempReg.
	self ssPop: 1.
	^self ssPushRegister: topReg
]

{ #category : #'inline primitive unary generators' }
SistaCogitClone >> genUnaryUnforwardNonImmediateInlinePrimitive [
	"1039	unforwardNonImmediate
	 non immediate => Not a forwarder"
	| topReg |
	topReg := self allocateRegForStackEntryAt: 0 notConflictingWith: 0.
	self ssTop popToReg: topReg.
	objectRepresentation genEnsureObjInRegNotForwarded: topReg scratchReg: TempReg.
	self ssPop: 1.
	^self ssPushRegister: topReg
]

{ #category : #'bytecode generators' }
SistaCogitClone >> genUnconditionalTrapBytecode [
	"SistaV1: *	217		Trap"
	self ssFlushTo: simStackPtr.
	self CallRT: ceTrapTrampoline.
	self annotateBytecode: self Label.
	deadCode := true.
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

{ #category : #accessing }
SistaCogitClone >> getCogCodeZoneThreshold [
	<doNotGenerate>
	^methodZone getCogCodeZoneThreshold
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

{ #category : #'simulation only' }
SistaCogitClone >> isTrapAt: retpc [
	"For stack depth checking."
	<doNotGenerate>
	^(backEnd isCallPrecedingReturnPC: retpc)
	 and: [(backEnd callTargetFromReturnAddress: retpc) = ceTrapTrampoline]
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
SistaCogitClone >> maybeDealWithUnsafeJumpForDescriptor: descriptor pc: pc latestContinuation: latestContinuation [
	"Mapped: 250	backjumpAlwaysInterrupt
	 Unmapped: 6000	backjumpNoInterrupt 
				 7016-7020 jumpWritable/Young
				 8000-8003 type branches
	In all cases the distance is an integer pushed on stack just before with pushIntegerLong:"
	<var: #descriptor type: #'BytecodeDescriptor *'>
	| distance targetPC byte01 byte02 newContinuation |
	newContinuation := latestContinuation.
	descriptor hasUnsafeJump ifTrue:
		[ byte01 := objectMemory fetchByte: pc + 1 ofObject: methodObj.
		  byte02 := objectMemory fetchByte: pc + 2 ofObject: methodObj.
		  distance := self decodePushIntegerLongBefore: pc in: methodObj.
		  targetPC := pc + descriptor numBytes + distance.
		  descriptor isMapped 
			ifTrue: [ byte01 = 250 ifTrue: 
				[ "mapped always interrupt backjump" 
				 self maybeCountFixup: descriptor.
				 self initializeFixupAt: targetPC ] ]
			ifFalse: 
				[ byte02 >> 5 = 2r100 ifTrue: 
					[ "inlined sista primitive" 
					| prim |
					prim := (byte02 bitAnd: 16r1F) << 8 + byte01.
					prim >= 7000
						ifTrue: 
							["branch forward"
							 self maybeCountFixup: descriptor.
							 newContinuation := latestContinuation max: targetPC ]
						ifFalse: 
							[prim >= 6000 ifTrue: 
								["no interrupt back jump"
								self maybeCountFixup: descriptor.
								self initializeFixupAt: targetPC]]]]].
	^newContinuation
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

{ #category : #'compile abstract instructions' }
SistaCogitClone >> maybeUnsafeJumpContinuation: latestContinuation at: bcpc for: descriptor in: aMethodObj [
	<inline: true>
	"Note: ignore backward jumps."
	<var: #descriptor type: #'BytecodeDescriptor *'>
	| distance targetPC byte01 byte02 newContinuation | 
	newContinuation := latestContinuation.
	descriptor hasUnsafeJump ifTrue:
		[ byte01 := objectMemory fetchByte: bcpc + 1 ofObject: aMethodObj.
		  byte02 := objectMemory fetchByte: bcpc + 2 ofObject: aMethodObj.
		  "pushIntegerLong"
		  distance := self decodePushIntegerLongBefore: bcpc in: methodObj.
		  targetPC := bcpc + descriptor numBytes + distance.
		  descriptor isMapped 
			ifFalse: 
				[ byte02 >> 5 = 2r100 ifTrue: 
					[ "inlined sista primitive" 
					| prim |
					prim := (byte02 bitAnd: 16r1F) << 8 + byte01.
					prim >= 7000
						ifTrue: 
							["branch forward"
							 newContinuation := latestContinuation max: targetPC ]]]].
	^newContinuation
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

{ #category : #accessing }
SistaCogitClone >> setCogCodeZoneThreshold: threshold [
	<doNotGenerate>
	^methodZone setCogCodeZoneThreshold: threshold
]
