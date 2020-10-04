Class {
	#name : #VMJittedPrimitiveAtTest,
	#superclass : #VMJittedPrimitivesTest,
	#instVars : [
		'stop'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> assertFallsThrough [

	self runFrom: initialAddress until: stop address.
	self assert: machineSimulator instructionPointerValue equals: stop address
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> new64BitIndexableOfSize: aSize [

	^ memory
		allocateNewSpaceSlots: aSize
		format: 9 "object with 64bit indexable values"
		classIndex: self nextOrdinaryClassIndex.
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> setUp [

	super setUp.
	self
		compile: [ 
			cogit objectRepresentation genPrimitiveAt.
			stop := cogit Stop ]
		bytecodes: 10.
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt64bitIndexableOutOfBoundsShouldFallThrough [

	| integerArray offset |
	
	"64bit indexable objects are not implemented in 32 bits"
	self wordSize ~= 8 ifTrue: [ ^ self skip ].

	integerArray := self new64BitIndexableOfSize: 3.
	offset := 5.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt64bitIndexableWithLargeIntegerIn32BitsShouldFallthrough [

	| integerArray offset |
	
	"64bit indexable objects are not implemented in 32 bits
	Test that even if the index is within bounds this falls through"
	self wordSize ~= 4 ifTrue: [ ^ self skip ].

	integerArray := self new64BitIndexableOfSize: 3.
	offset := 2.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt64bitIndexableWithLargeIntegerShouldReturnValue [

	| integerArray offset |
	
	"64bit indexable objects are not implemented in 32 bits"
	self wordSize ~= 8 ifTrue: [ ^ self skip ].

	integerArray := self new64BitIndexableOfSize: 3.
	offset := 2.

	memory
		storeLong64: offset - 1
		ofObject: integerArray
		withValue: SmallInteger maxVal + 1.

	self
		prepareStackForSendReceiver: integerArray
		arguments: { (memory integerObjectOf: offset) }.
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self runUntilReturn.

	self
		assert: (memory signed64BitValueOf: machineSimulator receiverRegisterValue)
		equals: SmallInteger maxVal + 1
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt64bitIndexableWithSmallIntegerShouldReturnValue [

	| integerArray offset |
	
	"64bit indexable objects are not implemented in 32 bits"
	self wordSize ~= 8 ifTrue: [ ^ self skip ].

	integerArray := self new64BitIndexableOfSize: 3.
	offset := 2.

	memory
		storeLong64: offset - 1
		ofObject: integerArray
		withValue: 17.

	self
		prepareStackForSendReceiver: integerArray
		arguments: { (memory integerObjectOf: offset) }.
	
	self runUntilReturn.

	self
		assert: machineSimulator receiverRegisterValue
		equals: (memory integerObjectOf: 17)
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAtArrayOutOfBoundsShouldFallThrough [
	
	| offset array |
	
	offset := 11.
	array := self newObjectWithSlots: 10.
	
	self prepareStackForSendReceiver: array arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAtArrayShouldAccessValue [
	
	| offset array |

	offset := 5.
	array := self newObjectWithSlots: 10.
	memory storePointer: offset - 1 ofObject: array withValue: memory falseObject.
	
	self executePrimitiveWithReceiver: array withArgument: (memory integerObjectOf: offset).
	
	self assert: machineSimulator receiverRegisterValue equals: memory falseObject
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAtFixedObjectWithInstanceVariablesShouldFallThrough [
	
	| objectWithInstanceVariables |
	
	objectWithInstanceVariables := memory
		allocateNewSpaceSlots: 3 "It has slots, but we should not access them"
		format: 1 "object with instance variables"
		classIndex: self nextOrdinaryClassIndex.
	
	self
		prepareStackForSendReceiver: objectWithInstanceVariables
		arguments: { memory integerObjectOf: 1 }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAtFixedObjectWithNoInstanceVariablesShouldFallThrough [
	
	| objectWithNoInstanceVariables |
	
	objectWithNoInstanceVariables := self newZeroSizedObject.
	
	self
		prepareStackForSendReceiver: objectWithNoInstanceVariables
		arguments: { memory integerObjectOf: 1 }.
	self runFrom: initialAddress until: stop address.

	self assert: machineSimulator instructionPointerValue equals: stop address
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAtSmallIntegerShouldFallThrough [
		
	machineSimulator receiverRegisterValue: (memory integerObjectOf: 17).
	self runFrom: initialAddress until: stop address.

	self assert: machineSimulator instructionPointerValue equals: stop address
]
