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
		'inDelaySlot'
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

{ #category : #'as yet unclassified' }
MIPSSimulator >> call: entryPC [
	| zapValue |
	zapValue := self unsigned32ToSigned32: 16rBABABABA.
	^self call: entryPC with: zapValue with: zapValue with: zapValue with: zapValue
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> call: entryPC with: arg0 with: arg1 with: arg2 with: arg3. [
	
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
MIPSSimulator >> disassembleFrom: startAddress to: endAddress in: memory for: aSymbolManager "<Cogit>" labels: labelDictionary on: aStream [
	MIPSDisassembler new 
		disassemble: memory
		from: startAddress
		to: endAddress
		for: aSymbolManager
		labels: labelDictionary
		on: aStream.
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
MIPSSimulator >> endianness [
	^#little
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> execute [
	| instruction |
	[pc ~= EndSimulationPC] whileTrue: 
		[instruction := MIPSInstruction new value: (self unsignedWord: pc).
		 instruction decodeFor: self.
		 pc := pc + OneInstruction].
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> executeDelaySlot [
	| instruction |
	self assert: inDelaySlot not.
	inDelaySlot := true.
	instruction := MIPSInstruction new value: (self unsignedWord: pc).
	instruction decodeFor: self.
	inDelaySlot := false.
]

{ #category : #'processor api' }
MIPSSimulator >> flushICacheFrom: startAddress "<Integer>" to: endAddress [ "<Integer>"
]

{ #category : #'processor api' }
MIPSSimulator >> fp [
	^self signedRegister: FP
]

{ #category : #'processor api' }
MIPSSimulator >> initializeStackFor: aCogit [
	self flag: #OABI.
	aCogit setStackAlignment: 8 expectedSPOffset: 0 expectedFPOffset: 0.
	self initializeWithMemory: ByteArray new.
	
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> initializeWithMemory: aByteArray [
	memory := aByteArray.
	registers := Array new: 32 withAll: 0.
	pc := 0.
	inDelaySlot := false.
	instructionCount := 0.
]

{ #category : #'instructions - control' }
MIPSSimulator >> jump: instruction [
	| nextPC |
	self assert: inDelaySlot not.
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
	pc := pc + OneInstruction.
	self executeDelaySlot.
	pc := nextPC.
	pc := pc - 4. "Account for general increment"
]

{ #category : #'instructions - control' }
MIPSSimulator >> jumpRegister: instruction [
	| nextPC |
	self assert: inDelaySlot not.
	nextPC := self unsignedRegister: instruction rs.
	pc := pc + OneInstruction.
	self executeDelaySlot.
	pc := nextPC.
	pc := pc - 4. "Account for general increment"
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
MIPSSimulator >> orImmediate: instruction [
	| rsValue immediate result |
	rsValue := self unsignedRegister: instruction rs.
	immediate := instruction unsignedImmediate.
	result := rsValue bitOr: immediate.
	self unsignedRegister: instruction rt put: result.
]

{ #category : #'as yet unclassified' }
MIPSSimulator >> printOn: stream [
	stream nextPutAll: self class name; nextPut: $:; cr.
	0 to: 31 do:
		[:reg | | hex |
		stream space.
		stream nextPutAll: (MIPSConstants nameForRegister: reg).
		stream space.
		hex := (self unsignedRegister: reg) printStringBase: 16.
		8 - hex size timesRepeat: [stream nextPut: $0].
		stream nextPutAll: hex.
		stream space.
		(self signedRegister: reg) printOn: stream.
		stream cr].
	
]

{ #category : #'processor api' }
MIPSSimulator >> setFramePointer: fp stackPointer: sp [
	self signedRegister: SP put: sp.
	self signedRegister: FP put: fp.
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

{ #category : #registers }
MIPSSimulator >> signedRegister: registerNumber [ 
	registerNumber == ZR ifTrue: [^0] ifFalse: [^registers at: registerNumber + 1].
]

{ #category : #registers }
MIPSSimulator >> signedRegister: registerNumber put: signedValue [
	self assert: (signedValue between: -16r80000000 and: 16r7FFFFFFF).
	registerNumber == ZR ifFalse: [registers at: registerNumber + 1 put: signedValue].
]

{ #category : #'processor api' }
MIPSSimulator >> sp [
	^self signedRegister: SP
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
		[registers at: registerNumber + 1 put: (self unsigned32ToSigned32: unsignedValue)].
]

{ #category : #'instructions - arithmetic' }
MIPSSimulator >> xorImmediate: instruction [
	| rsValue immediate result |
	rsValue := self unsignedRegister: instruction rs.
	immediate := instruction unsignedImmediate.
	result := rsValue bitXor: immediate.
	self unsignedRegister: instruction rt put: result.
]
