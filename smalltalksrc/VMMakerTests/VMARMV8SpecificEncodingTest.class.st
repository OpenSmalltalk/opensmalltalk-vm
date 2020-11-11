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
