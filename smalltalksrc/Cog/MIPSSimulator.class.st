"
Simulator for 32-bit MIPS, without implementation of memory access.
"
Class {
	#name : #MIPSSimulator,
	#superclass : #Object,
	#instVars : [
		'memory',
		'registers',
		'pc',
		'instructionCount',
		'inDelaySlot',
		'readableBase',
		'writableBase',
		'exectuableBase',
		'readableLimit',
		'writableLimit',
		'exectuableLimit',
		'jumpingPC',
		'hi',
		'lo'
	],
	#classVars : [
		'EndSimulationPC'
	],
	#pools : [
		'MIPSConstants'
	],
	#category : #'Cog-Processors'
}

{ #category : #'as yet unclassified' }
MIPSSimulator class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #'as yet unclassified' }
MIPSSimulator class >> initialize [
	super initialize.
	EndSimulationPC := 16rABABABAB.
	OneInstruction := 4.
	TwoInstructions := 8.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> addImmediateUnsigned: instruction [
	"Unsigned here means the instruction doesn't generate exceptions,
	 not that the immediate is unsigned."
	| rsValue immediate result |
	rsValue := self unsignedRegister: instruction rs.
	immediate := instruction signedImmediate.
	result := rsValue + immediate bitAnd: 16rFFFFFFFF. "No exception on overflow"
	self unsignedRegister: instruction rt put: result.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> addUnsigned: instruction [
	"Unsigned here means the instruction doesn't generate exceptions."
	| rsValue rtValue result |
	rsValue := self unsignedRegister: instruction rs.
	rtValue := self unsignedRegister: instruction rt.
	result := rsValue + rtValue bitAnd: 16rFFFFFFFF. "No exception on overflow"
	self unsignedRegister: instruction rd put: result.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> andImmediate: instruction [
	| rsValue immediate result |
	rsValue := self unsignedRegister: instruction rs.
	immediate := instruction unsignedImmediate.
	result := rsValue bitAnd: immediate.
	self unsignedRegister: instruction rt put: result.
]

{ #category : #'processor api' }
MIPSSimulator >> bitsInWord [
	^32
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> bitwiseAnd: instruction [
	| rsValue rtValue result |
	rsValue := self signedRegister: instruction rs.
	rtValue := self signedRegister: instruction rt.
	result := rsValue bitAnd: rtValue.
	self signedRegister: instruction rd put: result.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> bitwiseOr: instruction [
	| rsValue rtValue result |
	rsValue := self signedRegister: instruction rs.
	rtValue := self signedRegister: instruction rt.
	result := rsValue bitOr: rtValue.
	self signedRegister: instruction rd put: result.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> bitwiseXor: instruction [
	| rsValue rtValue result |
	rsValue := self signedRegister: instruction rs.
	rtValue := self signedRegister: instruction rt.
	result := rsValue bitXor: rtValue.
	self signedRegister: instruction rd put: result.
]

{ #category : #'instructions - control' }
MIPSSimulator >> branchEqual: instruction [
	| rsValue rtValue |
	self assert: inDelaySlot not.
	rsValue := self signedRegister: instruction rs.
	rtValue := self signedRegister: instruction rt.
	self doBranch: rsValue = rtValue offset: instruction signedImmediate << 2.
]

{ #category : #'instructions - control' }
MIPSSimulator >> branchGreaterEqualZero: instruction [
	| rsValue |
	self assert: inDelaySlot not.
	rsValue := self signedRegister: instruction rs.
	self doBranch: rsValue >= 0 offset: instruction signedImmediate << 2.
]

{ #category : #'instructions - control' }
MIPSSimulator >> branchGreaterThanZero: instruction [
	| rsValue |
	self assert: inDelaySlot not.
	rsValue := self signedRegister: instruction rs.
	self doBranch: rsValue > 0 offset: instruction signedImmediate << 2.
]

{ #category : #'instructions - control' }
MIPSSimulator >> branchLessEqualZero: instruction [
	| rsValue |
	self assert: inDelaySlot not.
	rsValue := self signedRegister: instruction rs.
	self doBranch: rsValue <= 0 offset: instruction signedImmediate << 2.
]

{ #category : #'instructions - control' }
MIPSSimulator >> branchLessThanZero: instruction [
	| rsValue |
	self assert: inDelaySlot not.
	rsValue := self signedRegister: instruction rs.
	self doBranch: rsValue < 0 offset: instruction signedImmediate << 2.
]

{ #category : #'instructions - control' }
MIPSSimulator >> branchNotEqual: instruction [
	| rsValue rtValue |
	self assert: inDelaySlot not.
	rsValue := self signedRegister: instruction rs.
	rtValue := self signedRegister: instruction rt.
	self doBranch: rsValue ~= rtValue offset: instruction signedImmediate << 2.
]

{ #category : #'instructions - control' }
MIPSSimulator >> break: instruction [
	self error: 'Break!'
]

{ #category : #'processor api' }
MIPSSimulator >> cResultRegister: cResult [
	^self unsignedRegister: V0 put: cResult
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> call: entryPC [
	| zapValue |
	zapValue := self unsigned32ToSigned32: 16rBABABABA.
	^self call: entryPC with: zapValue with: zapValue with: zapValue with: zapValue
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> call: entryPC with: arg0 with: arg1 with: arg2 with: arg3 [.
	
	pc := entryPC.
	self unsignedRegister: RA put: EndSimulationPC.
	self signedRegister: A0 put: arg0.
	self signedRegister: A1 put: arg1.
	self signedRegister: A2 put: arg2.
	self signedRegister: A3 put: arg3.
	
	self execute.
	
	^self signedRegister: V0.
]

{ #category : #'processor api' }
MIPSSimulator >> convertIntegerToInternal: anInteger [
	"Default conversion for 32-bit processors.  64-bit processors override."
	^anInteger signedIntToLong
]

{ #category : #'processor api' }
MIPSSimulator >> convertInternalToInteger: unsigned [
	"Default conversion for 32-bit processors.  64-bit processors override."
	^unsigned signedIntFromLong
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> currentInstruction [
	^[(MIPSDisassembler new disassemble: memory from: pc to: pc + 4)]
		ifError: ['Cannot disassemble', String cr].
]

{ #category : #'processor api' }
MIPSSimulator >> disassembleFrom: startAddress to: endAddress in: memory for: aSymbolManager "<Cogit>" labels: labelDictionary on: aStream [
	MIPSDisassembler new 
		disassemble: memory
		from: startAddress
		to: endAddress
		for: aSymbolManager
		labels: labelDictionary
		on: aStream.
]

{ #category : #'processor api' }
MIPSSimulator >> disassembleFrom: startAddress to: endAddress in: memory on: aStream [
	MIPSDisassembler new 
		disassemble: memory
		from: startAddress
		to: endAddress
		for: nil
		labels: nil
		on: aStream.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> divideSigned: instruction [
	"Strangely, the MIPS reference manual does not indicate which division is used, but testing on some hardware shows it is truncated division (rather than floored division or Euclidean division)."	
	| rsValue rtValue |
	rsValue := self signedRegister: instruction rs.
	rtValue := self signedRegister: instruction rt.
	rtValue = 0 ifTrue: 
		["No exception is signalled"
		 lo := rtValue. 
		 hi := rsValue.
		 ^self].
	(rtValue = -1 and: [rsValue = -16r80000000]) ifTrue:
		["Only overflow case"
		 lo := rsValue. 
		 hi := 0.
		 ^self].
	lo := rsValue quo: rtValue.
	hi := rsValue rem: rtValue.

]

{ #category : #'as yet unclassified' }
MIPSSimulator >> doBranch: taken offset: offset [
	| nextPC |
	pc := pc + OneInstruction.
	nextPC := pc + offset. "Branch target is relative to the delay slot."
	self executeDelaySlot.
	taken ifTrue: [pc := nextPC - OneInstruction "Account for general increment"].
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> execute [
	[pc ~= EndSimulationPC] whileTrue: [self step].
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> executeDelaySlot [
	| instruction |
	self assert: inDelaySlot not.
	inDelaySlot := true.
	instructionCount := instructionCount + 1.
	"Transcript print: instructionCount; nextPutAll: ' D '; nextPutAll: self currentInstruction; flush."
	instruction := MIPSInstruction new value: (self fetchInstruction: pc).
	instruction decodeFor: self.
	inDelaySlot := false.
]

{ #category : #'processor api' }
MIPSSimulator >> flushICacheFrom: startAddress "<Integer>" to: endAddress [ "<Integer>"
]

{ #category : #registers }
MIPSSimulator >> fp [
	^self unsignedRegister: FP
]

{ #category : #registers }
MIPSSimulator >> fp: anInteger [
	^self unsignedRegister: FP put: anInteger
]

{ #category : #registers }
MIPSSimulator >> getterForRegister: registerNumber [
	^#(zr at v0 v1 a0 a1 a2 a3
		t0 t1 t2 t3 t4 t5 t6 t7
		s0 s1 s2 s3 s4 s5 s6 s7
		t8 t9 k0 k1 gp sp fp ra) at: registerNumber + 1
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> initialize [
	registers := Array new: 32 withAll: 0.
	pc := 0.
	hi := 0.
	lo := 0.
	inDelaySlot := false.
	instructionCount := 0.
]

{ #category : #'processor api' }
MIPSSimulator >> initializeStackFor: aCogit [
	self flag: #OABI.
	aCogit setStackAlignment: 8 expectedSPOffset: 0 expectedFPOffset: 0.
	
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> initializeWithMemory: aByteArray [
	memory := aByteArray.
	readableBase := 0.
	writableBase := 0.
	exectuableBase := 0.
	readableLimit := memory size.
	writableLimit := memory size.
	exectuableLimit := memory size.
]

{ #category : #'instructions - control' }
MIPSSimulator >> jump: instruction [
	| nextPC |
	self assert: inDelaySlot not.
	jumpingPC := pc.
	pc := pc + OneInstruction.
	nextPC := (pc bitAnd: 16rF0000000) + (instruction target << 2). "Region is that of the delay slot."	
	self executeDelaySlot.
	pc := nextPC - OneInstruction. "Account for general increment"
]

{ #category : #'instructions - control' }
MIPSSimulator >> jumpAndLink: instruction [
	| nextPC |
	self assert: inDelaySlot not.
	self unsignedRegister: RA put: pc + TwoInstructions. "Return past delay slot."
	jumpingPC := pc.
	pc := pc + OneInstruction.
	nextPC := (pc bitAnd: 16rF0000000) + (instruction target << 2). "Region is that of the delay slot."	
	self executeDelaySlot.
	pc := nextPC - OneInstruction. "Account for general increment"
]

{ #category : #'instructions - control' }
MIPSSimulator >> jumpAndLinkRegister: instruction [
	| nextPC |
	self assert: inDelaySlot not.
	self unsignedRegister: instruction rd put: pc + TwoInstructions. "Return past delay slot."
	nextPC := self unsignedRegister: instruction rs.
	jumpingPC := pc.
	pc := pc + OneInstruction.
	self executeDelaySlot.
	pc := nextPC.
	pc := pc - OneInstruction. "Account for general increment"
]

{ #category : #'instructions - control' }
MIPSSimulator >> jumpRegister: instruction [
	| nextPC |
	self assert: inDelaySlot not.
	nextPC := self unsignedRegister: instruction rs.
	jumpingPC := pc.
	pc := pc + OneInstruction.
	self executeDelaySlot.
	pc := nextPC.
	pc := pc - OneInstruction. "Account for general increment"
]

{ #category : #'instructions - memory' }
MIPSSimulator >> loadByte: instruction [
	| base address value |
	base := self unsignedRegister: instruction rs.
	address := base + instruction signedImmediate.
	value := self signedByte: address.
	self signedRegister: instruction rt put: value.
]

{ #category : #'instructions - memory' }
MIPSSimulator >> loadByteUnsigned: instruction [
	| base address value |
	base := self unsignedRegister: instruction rs.
	address := base + instruction signedImmediate.
	value := self unsignedByte: address.
	self unsignedRegister: instruction rt put: value.
]

{ #category : #'instructions - memory' }
MIPSSimulator >> loadHalfword: instruction [
	| base address value |
	base := self unsignedRegister: instruction rs.
	address := base + instruction signedImmediate.
	value := self signedHalfword: address.
	self signedRegister: instruction rt put: value.
]

{ #category : #'instructions - memory' }
MIPSSimulator >> loadHalfwordUnsigned: instruction [
	| base address value |
	base := self unsignedRegister: instruction rs.
	address := base + instruction signedImmediate.
	value := self unsignedHalfword: address.
	self unsignedRegister: instruction rt put: value.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> loadUpperImmediate: instruction [
	| result |
	self assert: instruction rs = 0.
	result := instruction signedImmediate << 16.
	self signedRegister: instruction rt put: result.
]

{ #category : #'instructions - memory' }
MIPSSimulator >> loadWord: instruction [
	| base address value |
	base := self unsignedRegister: instruction rs.
	address := base + instruction signedImmediate.
	value := self signedWord: address.
	self signedRegister: instruction rt put: value.
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> memory [
	^memory
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> moveFromHigh: instruction [
	self signedRegister: instruction rd put: hi.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> moveFromLow: instruction [
	self signedRegister: instruction rd put: lo.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> multiplySigned: instruction [
	| rsValue rtValue result |
	rsValue := self signedRegister: instruction rs.
	rtValue := self signedRegister: instruction rt.
	result := rsValue * rtValue.
	result := self signed64ToUnsigned64: result.
	hi := self unsigned32ToSigned32: result >> 32.
	lo := self unsigned32ToSigned32: (result bitAnd: 16rFFFFFFFF).
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> orImmediate: instruction [
	| rsValue immediate result |
	rsValue := self unsignedRegister: instruction rs.
	immediate := instruction unsignedImmediate.
	result := rsValue bitOr: immediate.
	self unsignedRegister: instruction rt put: result.
]

{ #category : #'processor api' }
MIPSSimulator >> pc [
	^pc
]

{ #category : #'processor api' }
MIPSSimulator >> pc: newPC [
	pc := newPC.
]

{ #category : #'processor api' }
MIPSSimulator >> popWordIn: aMemory [ 
	| sp word |
	word := aMemory unsignedLongAt: (sp := self sp) + 1 bigEndian: false.
	self sp: sp + 4.
	^word
]

{ #category : #'processor api' }
MIPSSimulator >> postCallArgumentsNumArgs: numArgs "<Integer>" in: memory [ "<ByteArray|Bitmap>"
	"Answer an argument vector of the requested size after a vanilla ABI call. 
	 We assume that all arguments are single word arguments, which can not be
	 supplied on co-processor-registers. For compatibility with Cog/Slang we answer
	 unsigned values."
	self flag: #OABI.
	
	numArgs = 0 ifTrue: 
		[^{}].
	numArgs = 1 ifTrue: 
		[^{self unsignedRegister: A0}].
	numArgs = 2 ifTrue:
		[^{self unsignedRegister: A0. self unsignedRegister: A1}].
	numArgs = 3 ifTrue:
		[^{self unsignedRegister: A0. self unsignedRegister: A1. self unsignedRegister: A2}].
	numArgs = 4 ifTrue:
		[^{self unsignedRegister: A0. self unsignedRegister: A1. self unsignedRegister: A2. self unsignedRegister: A3}].
	self unimplemented.
]

{ #category : #'instructions - memory' }
MIPSSimulator >> prefetch: instruction [
	self assert: (instruction rt = HintLoad or: [instruction rt = HintStore]).
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> printOn: stream [
	stream nextPutAll: self class name; nextPut: $:; cr.
	self printRegistersOn: stream.
	stream nextPutAll: self currentInstruction.
]

{ #category : #registers }
MIPSSimulator >> printRegistersOn: stream [
	0 to: 31 do:
		[:reg |
		stream space.
		stream nextPutAll: (MIPSConstants nameForRegister: reg).
		stream space.
		(self unsignedRegister: reg) printOn: stream base: 16 nDigits: 8.
		stream space.
		(self signedRegister: reg) printOn: stream.
		stream cr].

	stream nextPutAll: ' hi '.
	hi printOn: stream base: 16 nDigits: 8.
	stream space.
	hi printOn: stream.
	stream cr.
	
	stream nextPutAll: ' lo '.
	lo printOn: stream base: 16 nDigits: 8.
	stream space.
	lo printOn: stream.
	stream cr.
	
	stream nextPutAll: ' pc '.
	pc printOn: stream base: 16 nDigits: 8.
	stream space.
	pc printOn: stream.
	stream cr.
]

{ #category : #'processor api' }
MIPSSimulator >> pushWord: aValue in: aMemory [
	aMemory longAt: (self sp: self sp - 4) + 1 put: aValue bigEndian: false
]

{ #category : #registers }
MIPSSimulator >> ra [
	^self unsignedRegister: RA
]

{ #category : #registers }
MIPSSimulator >> ra: anInteger [
	^self unsignedRegister: RA put: anInteger
]

{ #category : #'processor api' }
MIPSSimulator >> reset [
	^self initialize
]

{ #category : #'processor api' }
MIPSSimulator >> retpcIn: aMemory [
	"The return address is on the stack, having been pushed by either
	 simulateCallOf:nextpc:memory: or simulateJumpCallOf:memory:"
	^aMemory unsignedLongAt: self fp + 5 bigEndian: false
]

{ #category : #'processor api' }
MIPSSimulator >> runInMemory: aMemory minimumAddress: minimumAddress readOnlyBelow: minimumWritableAddress [
	"Note that minimumWritableAddress is both the minimum writeable address AND the maximum executable address"
	memory := aMemory.
	readableBase := minimumAddress.
	writableBase := minimumWritableAddress.
	exectuableBase := minimumAddress.
	readableLimit := aMemory byteSize.
	writableLimit := aMemory byteSize.
	exectuableLimit := minimumWritableAddress.
	self execute.
]

{ #category : #registers }
MIPSSimulator >> s0 [
	^self unsignedRegister: S0
]

{ #category : #registers }
MIPSSimulator >> s0: anInteger [
	^self unsignedRegister: S0 put: anInteger
]

{ #category : #registers }
MIPSSimulator >> s1 [
	^self unsignedRegister: S1
]

{ #category : #registers }
MIPSSimulator >> s1: anInteger [
	^self unsignedRegister: S1 put: anInteger
]

{ #category : #registers }
MIPSSimulator >> s2 [
	^self unsignedRegister: S2
]

{ #category : #registers }
MIPSSimulator >> s2: anInteger [
	^self unsignedRegister: S2 put: anInteger
]

{ #category : #registers }
MIPSSimulator >> s3 [
	^self unsignedRegister: S3
]

{ #category : #registers }
MIPSSimulator >> s3: anInteger [
	^self unsignedRegister: S3 put: anInteger
]

{ #category : #registers }
MIPSSimulator >> s4 [
	^self unsignedRegister: S4
]

{ #category : #registers }
MIPSSimulator >> s4: anInteger [
	^self unsignedRegister: S4 put: anInteger
]

{ #category : #registers }
MIPSSimulator >> s5 [
	^self unsignedRegister: S5
]

{ #category : #registers }
MIPSSimulator >> s5: anInteger [
	^self unsignedRegister: S5 put: anInteger
]

{ #category : #registers }
MIPSSimulator >> s6 [
	^self unsignedRegister: S6
]

{ #category : #registers }
MIPSSimulator >> s6: anInteger [
	^self unsignedRegister: S6 put: anInteger
]

{ #category : #'processor api' }
MIPSSimulator >> setFramePointer: fp stackPointer: sp [
	self unsignedRegister: SP put: sp.
	self unsignedRegister: FP put: fp.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> setOnLessThan: instruction [
	| rsValue rtValue result |
	rsValue := self signedRegister: instruction rs.
	rtValue := self signedRegister: instruction rt.
	result := rsValue < rtValue ifTrue: [1] ifFalse: [0].
	self signedRegister: instruction rd put: result.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> setOnLessThanImmediate: instruction [
	| rsValue immediate result |
	rsValue := self signedRegister: instruction rs.
	immediate := instruction signedImmediate.
	result := rsValue < immediate ifTrue: [1] ifFalse: [0].
	self signedRegister: instruction rt put: result.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> setOnLessThanImmediateUnsigned: instruction [
	"The immediate is still sign-extended; it is the comparison that is unsigned."
	| rsValue immediate result |
	rsValue := self unsignedRegister: instruction rs.
	immediate := self signed32ToUnsigned32: instruction signedImmediate.
	result := rsValue < immediate ifTrue: [1] ifFalse: [0].
	self signedRegister: instruction rt put: result.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> setOnLessThanUnsigned: instruction [
	| rsValue rtValue result |
	rsValue := self unsignedRegister: instruction rs.
	rtValue := self unsignedRegister: instruction rt.
	result := rsValue < rtValue ifTrue: [1] ifFalse: [0].
	self signedRegister: instruction rd put: result.
]

{ #category : #registers }
MIPSSimulator >> setterForRegister: registerNumber [
	^#(zr: at: v0: v1: a0: a1: a2: a3:
		t0: t1: t2: t3: t4: t5: t6: t7:
		s0: s1: s2: s3: s4: s5: s6: s7:
		t8: t9: k0: k1: gp: sp: fp: ra:) at: registerNumber + 1
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> shiftLeftLogical: instruction [
	| result rtValue shiftAmount |
	self assert: instruction rs = 0.
	rtValue := self unsignedRegister: instruction rt.
	shiftAmount := instruction sa.
	result := (rtValue << shiftAmount) bitAnd: 16rFFFFFFFF.
	self unsignedRegister: instruction rd put: result.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> shiftLeftLogicalVariable: instruction [
	| result rtValue shiftAmount |
	rtValue := self unsignedRegister: instruction rt.
	shiftAmount := self unsignedRegister: instruction rs.
	(31 allMask: shiftAmount) ifFalse: 
		["MIPS will use only the low 5 bits for this shift, but we probably
		  don't want to generate any code that hits this behavior."
		self error].
	result := (rtValue << shiftAmount) bitAnd: 16rFFFFFFFF.
	self unsignedRegister: instruction rd put: result.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> shiftRightArithmetic: instruction [
	| result rtValue shiftAmount |
	self assert: instruction rs = 0.
	rtValue := self signedRegister: instruction rt.
	shiftAmount := instruction sa.
	result := rtValue >> shiftAmount.
	self signedRegister: instruction rd put: result.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> shiftRightArithmeticVariable: instruction [
	| result rtValue shiftAmount |
	rtValue := self signedRegister: instruction rt.
	shiftAmount := self unsignedRegister: instruction rs.
	(31 allMask: shiftAmount) ifFalse:
		["MIPS will use only the low 5 bits for this shift, but we probably
		  don't want to generate any code that hits this behavior."
		self error].
	result := rtValue >> shiftAmount.
	self signedRegister: instruction rd put: result.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> shiftRightLogical: instruction [
	| result rtValue shiftAmount |
	self assert: instruction rs = 0.
	rtValue := self unsignedRegister: instruction rt.
	shiftAmount := instruction sa.
	result := rtValue >> shiftAmount.
	self unsignedRegister: instruction rd put: result.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> shiftRightLogicalVariable: instruction [
	| result rtValue shiftAmount |
	rtValue := self unsignedRegister: instruction rt.
	shiftAmount := self unsignedRegister: instruction rs.
	(31 allMask: shiftAmount) ifFalse:
		["MIPS will use only the low 5 bits for this shift, but we probably
		  don't want to generate any code that hits this behavior."
		self error].
	result := rtValue >> shiftAmount.
	self unsignedRegister: instruction rd put: result.
]

{ #category : #converting }
MIPSSimulator >> signed32ToUnsigned32: signedValue [
	self assert: (signedValue between: -16r80000000 and: 16r7FFFFFFF).
	signedValue < 0 ifTrue: [^signedValue + 16r100000000].
	^signedValue
]

{ #category : #converting }
MIPSSimulator >> signed64ToUnsigned64: signedValue [
	self assert: (signedValue between: -16r8000000000000000 and: 16r7FFFFFFFFFFFFFFF).
	signedValue < 0 ifTrue: [^signedValue + 16r10000000000000000].
	^signedValue
]

{ #category : #registers }
MIPSSimulator >> signedRegister: registerNumber [
	registerNumber == ZR ifTrue: [^0] ifFalse: [^registers at: registerNumber + 1].
]

{ #category : #registers }
MIPSSimulator >> signedRegister: registerNumber put: signedValue [
	self assert: (signedValue between: -16r80000000 and: 16r7FFFFFFF).
	registerNumber == ZR ifFalse: [^registers at: registerNumber + 1 put: signedValue].
]

{ #category : #'processor api' }
MIPSSimulator >> simulateCallOf: address nextpc: nextpc memory: aMemory [
	"Simulate a frame-building call of address.  Build a frame since
	a) this is used for calls into the run-time which are unlikely to be leaf-calls"
	
	self flag: #todo. "Why are we building a frame exactly? Frame building is a callee's job, which I'd expect to be done by some code under simulation. --rmacnak"
	
	self pushWord: self ra in: aMemory.
	self pushWord: self fp in: aMemory.
	self fp: self sp.
	pc := address.
]

{ #category : #'processor api' }
MIPSSimulator >> simulateJumpCallOf: address memory: aMemory [
	"Simulate a frame-building jump of address.  Build a frame since
	a) this is used for calls into the run-time which are unlikely to be leaf-calls"
	"This method builds a stack frame as expected by the simulator, not as defined by ARM aapcs-abi.
	In ARM aapcs, every method can define for itself, wether it wants to push lr (nextpc), and wether it 
	uses a frame pointer. The standard never mentions a fp. It merely defines r4-r11 to be callee-saved."

	self assert: self sp \\ 8 = 0. "This check ensures, that we conform with ARM abi. Before doing anything to the stack, we ensure 2-word alignment."
	self pushWord: self ra in: aMemory.
	self pushWord: self fp in: aMemory.
	self fp: self sp.
	"PostBuildStackDelta ~= 0 ifTrue:
		[self sp: self sp - PostBuildStackDelta]." "In order to satisfy the CStackAlignment check by cogit, which is only valid on IA32 platforms."
	self pc: address
]

{ #category : #'processor api' }
MIPSSimulator >> simulateLeafCallOf: address nextpc: nextpc memory: aMemory [
	self unsignedRegister: RA put: nextpc.
	pc := address.
]

{ #category : #'processor api' }
MIPSSimulator >> simulateReturnIn: aMemory [
	"PostBuildStackDelta ~= 0 ifTrue:
		[self sp: self sp + PostBuildStackDelta]."
	self fp: (self popWordIn: aMemory).
	"According to tpr, most C compilers implement return by simply
	 popping into the pc, rather than popping through the link register."
	self pc: (self popWordIn: aMemory)
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> singleStepIn: aByteArray [
	self initializeWithMemory: aByteArray.
	self step.
]

{ #category : #'processor api' }
MIPSSimulator >> smashCallerSavedRegistersWithValuesFrom: base by: step in: aMemory [
	"i.e., smashVolatileRegisters"
	self flag: #OABI.
	self unsignedRegister: AT put: 0 * step + base.
	self unsignedRegister: V0 put: 1 * step + base.
	self unsignedRegister: V1 put: 2 * step + base.
	self unsignedRegister: A0 put: 3 * step + base.
	self unsignedRegister: A1 put: 4 * step + base.
	self unsignedRegister: A2 put: 5 * step + base.
	self unsignedRegister: A3 put: 6 * step + base.
	self unsignedRegister: T0 put: 7 * step + base.
	self unsignedRegister: T1 put: 8 * step + base.
	self unsignedRegister: T2 put: 9 * step + base.
	self unsignedRegister: T3 put: 10 * step + base.
	self unsignedRegister: T4 put: 11 * step + base.
	self unsignedRegister: T5 put: 12 * step + base.
	self unsignedRegister: T6 put: 13 * step + base.
	self unsignedRegister: T7 put: 14 * step + base.
	self unsignedRegister: T8 put: 15 * step + base.
	self unsignedRegister: T9 put: 16 * step + base.
	self unsignedRegister: GP put: 17 * step + base.
	self unsignedRegister: RA put: 18 * step + base
]

{ #category : #'processor api' }
MIPSSimulator >> smashRegistersWithValuesFrom: base by: step [
	2 to: 31 do: [:index | self unsignedRegister: index put: index - 1 * step + base].

]

{ #category : #registers }
MIPSSimulator >> sp [
	^self unsignedRegister: SP
]

{ #category : #registers }
MIPSSimulator >> sp: anInteger [
	^self unsignedRegister: SP put: anInteger
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> step [
	"If the next instruction is a branch, its delay slot will also be executed."	
	| instruction |
	"Transcript print: instructionCount; nextPutAll: ' X '; nextPutAll: self currentInstruction; flush"
	instruction := MIPSInstruction new value: (self fetchInstruction: pc).
	instruction decodeFor: self.
	pc := pc + OneInstruction.
	instructionCount := instructionCount + 1.
]

{ #category : #'instructions - memory' }
MIPSSimulator >> storeByte: instruction [
	| base address value |
	base := self unsignedRegister: instruction rs.
	address := base + instruction signedImmediate.
	value := (self signedRegister: instruction rt) bitAnd: 16rFF.
	self unsignedByte: address put: value.
]

{ #category : #'instructions - memory' }
MIPSSimulator >> storeHalfword: instruction [
	| base address value |
	base := self unsignedRegister: instruction rs.
	address := base + instruction signedImmediate.
	value := (self signedRegister: instruction rt) bitAnd: 16rFFFF.
	self unsignedHalfword: address put: value.
]

{ #category : #'instructions - memory' }
MIPSSimulator >> storeWord: instruction [
	| base address value |
	base := self unsignedRegister: instruction rs.
	address := base + instruction signedImmediate.
	value := self signedRegister: instruction rt.
	self signedWord: address put: value.
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> subtractUnsigned: instruction [
	"Unsigned here means the instruction doesn't generate exceptions."
	| rsValue rtValue result |
	rsValue := self unsignedRegister: instruction rs.
	rtValue := self unsignedRegister: instruction rt.
	result := rsValue - rtValue bitAnd: 16rFFFFFFFF. "No exception on overflow"
	self unsignedRegister: instruction rd put: result.
]

{ #category : #converting }
MIPSSimulator >> unsigned32ToSigned32: unsignedValue [
	self assert: (unsignedValue between: 0 and: 16rFFFFFFFF).
	unsignedValue >= 16r80000000 ifTrue: [^unsignedValue - 16r100000000].
	^unsignedValue
]

{ #category : #registers }
MIPSSimulator >> unsignedRegister: registerNumber [
	registerNumber == ZR 
		ifTrue: [^0]
		ifFalse: [^self signed32ToUnsigned32: (registers at: registerNumber + 1)].
]

{ #category : #registers }
MIPSSimulator >> unsignedRegister: registerNumber put: unsignedValue [
	registerNumber == ZR ifFalse:
		[^registers at: registerNumber + 1 put: (self unsigned32ToSigned32: unsignedValue)].
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> xorImmediate: instruction [
	| rsValue immediate result |
	rsValue := self unsignedRegister: instruction rs.
	immediate := instruction unsignedImmediate.
	result := rsValue bitXor: immediate.
	self unsignedRegister: instruction rt put: result.
]
