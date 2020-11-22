Class {
	#name : #VMARMV8SpecificEncodingTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#category : #'VMMakerTests-JitTests'
}

{ #category : #'building suites' }
VMARMV8SpecificEncodingTest class >> testParameters [

	^ ParametrizedTestMatrix new
		addCase: { #ISA -> #'aarch64'. #wordSize -> 8};
		yourself
]

{ #category : #'tests - MoveRMwr' }
VMARMV8SpecificEncodingTest >> armInstructionAt: index [

	| addr inst |
	addr := initialAddress + ((index - 1) * 8).
	inst := memory long32At: addr.
	
	^ inst aarch64Disassembled
]

{ #category : #'tests - MoveMbrR' }
VMARMV8SpecificEncodingTest >> doTestEncodeMoveMbrR: constant [

	| expectedAddress expectedValue |
	
	expectedAddress := initialAddress + 1024.
	expectedValue := 16r10.

	self compile: [
		cogit MoveMb: constant r: ReceiverResultReg R: Arg0Reg].
	
	memory byteAt: expectedAddress put: expectedValue.
	
	machineSimulator argument0RegisterValue: 0.
	machineSimulator receiverRegisterValue: expectedAddress + constant negated.

	self runGeneratedCode.
	
	self 
		assert: machineSimulator argument0RegisterValue 
		equals: expectedValue.

]

{ #category : #'tests - MoveMwrR' }
VMARMV8SpecificEncodingTest >> doTestEncodeMoveMwrR: constant [

	| expectedAddress expectedValue |
	
	expectedAddress := initialAddress + 1024.
	expectedValue := 16r10001000.

	self compile: [
		cogit MoveMw: constant r: ReceiverResultReg R: Arg0Reg].
	
	memory long32At: expectedAddress put: expectedValue.
	
	machineSimulator argument0RegisterValue: 0.
	machineSimulator receiverRegisterValue: expectedAddress + constant negated.

	self runGeneratedCode.
	
	self 
		assert: machineSimulator argument0RegisterValue 
		equals: expectedValue.

]

{ #category : #'tests - MoveRMwr' }
VMARMV8SpecificEncodingTest >> doTestEncodeMoveRMwr: constant [

	| expectedAddress expectedValue |
	
	expectedAddress := initialAddress + 400.
	expectedValue := 16r100.

	self compile: [
		cogit MoveR: ReceiverResultReg Mw: constant r: Arg0Reg].
	
	machineSimulator receiverRegisterValue: 16r100.
	machineSimulator argument0RegisterValue: expectedAddress + constant negated.

	self runGeneratedCode.
	
	self 
		assert: (memory long64At: expectedAddress) 
		equals: expectedValue.

]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeCmpCqRNonEncodeable12BitConstant [

	| constant |
	constant := 32768 << 3 + 1.
	self compile: [		 
		cogit CmpCq: constant R: ReceiverResultReg ].
	
	machineSimulator receiverRegisterValue: constant.
	self runGeneratedCode.
	
	"Assert Cmp was equals"
	self assert: machineSimulator zero
]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeCmpCqRWithNegative12BitConstant [

	| negativeConstant12Bits |
	negativeConstant12Bits := (1 << 12 - 1) negated.
	self compile: [		 
		cogit CmpCq: negativeConstant12Bits R: ReceiverResultReg ].
	
	machineSimulator receiverRegisterValue: (1 << 12 - 1) bitInvert64 + 1.
	self runGeneratedCode.
	
	"Assert Cmp was equals"
	self assert: machineSimulator zero
]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeCmpCqRWithNegative12ShiftableBitConstant [

	| negativeConstant12Bits |
	negativeConstant12Bits := ((1 << 12 - 1) << 12) negated.
	self compile: [		 
		cogit CmpCq: negativeConstant12Bits R: ReceiverResultReg ].
	
	machineSimulator receiverRegisterValue: ((1 << 12 - 1) << 12) bitInvert64 + 1.
	self runGeneratedCode.
	
	"Assert Cmp was equals"
	self assert: machineSimulator zero
]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeCmpCqRWithNegative13ShiftableBitConstant [

	| negativeConstant12Bits |
	negativeConstant12Bits := ((1 << 12 - 1) << 13) negated.
	self compile: [		 
		cogit CmpCq: negativeConstant12Bits R: ReceiverResultReg ].
	
	machineSimulator receiverRegisterValue: ((1 << 12 - 1) << 13) bitInvert64 + 1.
	self runGeneratedCode.
	
	"Assert Cmp was equals"
	self assert: machineSimulator zero
]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeCmpCqRWithNegativeConstant [

	| negativeConstant12Bits |
	negativeConstant12Bits := -1.
	self compile: [		 
		cogit CmpCq: negativeConstant12Bits R: ReceiverResultReg ].
	
	machineSimulator receiverRegisterValue: 1 bitInvert64 + 1.
	self runGeneratedCode.
	
	"Assert Cmp was equals"
	self assert: machineSimulator zero
]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeCmpCqRWithPositive12BitConstant [

	| positiveConstant12Bits |
	positiveConstant12Bits := 1 << 12 - 1.
	self compile: [		 
		cogit CmpCq: positiveConstant12Bits R: ReceiverResultReg ].
	
	machineSimulator receiverRegisterValue: positiveConstant12Bits.
	self runGeneratedCode.
	
	"Assert Cmp was equals"
	self assert: machineSimulator zero
]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeCmpCqRWithPositiveBigConstant [

	| positiveConstant12Bits |
	positiveConstant12Bits := 134217729.
	self compile: [		 
		cogit CmpCq: positiveConstant12Bits R: ReceiverResultReg ].
	
	machineSimulator receiverRegisterValue: positiveConstant12Bits.
	self runGeneratedCode.
	
	"Assert Cmp was equals"
	self assert: machineSimulator zero
]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeCmpCqRWithPositiveShiftable12BitConstant [

	| positiveConstant12Bits |
	positiveConstant12Bits := (1 << 12 - 1) << 12.
	self compile: [		 
		cogit CmpCq: positiveConstant12Bits R: ReceiverResultReg ].
	
	machineSimulator receiverRegisterValue: positiveConstant12Bits.
	self runGeneratedCode.
	
	"Assert Cmp was equals"
	self assert: machineSimulator zero
]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeCmpCqRWithPositiveShiftable13BitConstant [

	| positiveConstant12Bits |
	positiveConstant12Bits := (1 << 12 - 1) << 13.
	self compile: [		 
		cogit CmpCq: positiveConstant12Bits R: ReceiverResultReg ].
	
	machineSimulator receiverRegisterValue: positiveConstant12Bits.
	self runGeneratedCode.
	
	"Assert Cmp was equals"
	self assert: machineSimulator zero
]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeMoveCqRWithEncodeableLargeNumber [


	| constantValue |
	constantValue := 16rF234 << 16.
	self compile: [		 
		cogit MoveCq: constantValue R: 24 ].

	self runGeneratedCode.
	
	"Assert Cmp was equals"
	self assert: machineSimulator x24 equals: constantValue
]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeMoveCqRWithLargeConstant [


	| constantValue |
	constantValue := 281474841613120.
	self compile: [		 
		cogit MoveCq: constantValue R: 24 ].

	self runGeneratedCode.
	
	"Assert Cmp was equals"
	self assert: machineSimulator x24 equals: constantValue
]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeMoveCqRWithNegativeLargeConstant [


	| constantValue completementValue |
	constantValue := -281474841613120.
	completementValue := constantValue negated bitInvert64 + 1.
	
	self compile: [		 
		cogit MoveCq: constantValue R: 24 ].

	self runGeneratedCode.
	
	"Assert Cmp was equals"
	self assert: machineSimulator x24 hex equals: completementValue hex
]

{ #category : #'tests - MoveMbrR' }
VMARMV8SpecificEncodingTest >> testEncodeMoveMbrRWithNegative9BitConstant [

	self doTestEncodeMoveMbrR: -256.


]

{ #category : #'tests - MoveMbrR' }
VMARMV8SpecificEncodingTest >> testEncodeMoveMbrRWithNegativeNon9BitConstant [

	self doTestEncodeMoveMbrR: -1024.


]

{ #category : #'tests - MoveMbrR' }
VMARMV8SpecificEncodingTest >> testEncodeMoveMbrRWithPositive9BitConstant [

	self doTestEncodeMoveMbrR: 255.


]

{ #category : #'tests - MoveMbrR' }
VMARMV8SpecificEncodingTest >> testEncodeMoveMbrRWithPositiveNon9BitConstant [

	self doTestEncodeMoveMbrR: 1024.


]

{ #category : #'tests - MoveMwrR' }
VMARMV8SpecificEncodingTest >> testEncodeMoveMwrRWithNegative9BitConstant [

	self doTestEncodeMoveMwrR: -256
	
]

{ #category : #'tests - MoveMwrR' }
VMARMV8SpecificEncodingTest >> testEncodeMoveMwrRWithNegativeNon9BitConstant [

	self doTestEncodeMoveMwrR: -20056
	
]

{ #category : #'tests - MoveMwrR' }
VMARMV8SpecificEncodingTest >> testEncodeMoveMwrRWithPositive12BitConstant [

	self doTestEncodeMoveMwrR: 16r100
	
]

{ #category : #'tests - MoveMwrR' }
VMARMV8SpecificEncodingTest >> testEncodeMoveMwrRWithPositiveNon9BitConstant [

	self doTestEncodeMoveMwrR: 20056
	
]

{ #category : #'tests - MoveRMwr' }
VMARMV8SpecificEncodingTest >> testEncodeMoveRMwrWithNegative9BitConstant [

	self doTestEncodeMoveRMwr: -256.

	"This should be encoded in a single machine instruction"
	self
		assert: (self armInstructionAt: 1) assemblyCodeString
		equals: 'stur	x23, [x3, #-256]'
]

{ #category : #'tests - MoveRMwr' }
VMARMV8SpecificEncodingTest >> testEncodeMoveRMwrWithNon9BitButShiftableConstant [

	self doTestEncodeMoveRMwr: 512

]

{ #category : #'tests - MoveRMwr' }
VMARMV8SpecificEncodingTest >> testEncodeMoveRMwrWithNon9BitNegativeConstant [

	self doTestEncodeMoveRMwr: -61440

]

{ #category : #'tests - MoveRMwr' }
VMARMV8SpecificEncodingTest >> testEncodeMoveRMwrWithPositive9BitConstant [

	self doTestEncodeMoveRMwr: 256

]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeOrCqRWithEncodableConstant [

	self compile: [
		cogit OrCq: 16rFF R: ReceiverResultReg ].
	
	machineSimulator receiverRegisterValue: 16r100.
	self runGeneratedCode.
	
	self assert: machineSimulator receiverRegisterValue equals: 16r1FF
]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeOrCqRWithLargeConstant [

	self compile: [
		cogit OrCq: 67108865 R: ReceiverResultReg ].
	
	machineSimulator receiverRegisterValue: 16r100.
	self runGeneratedCode.
	
	self assert: machineSimulator receiverRegisterValue equals: (67108865 bitOr: 16r100)
]

{ #category : #'tests - cmpCqR' }
VMARMV8SpecificEncodingTest >> testEncodeOrCqRWithNonEncodableConstant [

	self compile: [
		cogit OrCq: 16r12345678 R: ReceiverResultReg ].
	
	machineSimulator receiverRegisterValue: 16r100.
	self runGeneratedCode.
	
	self assert: machineSimulator receiverRegisterValue equals: (16r12345678 bitOr: 16r100)
]
