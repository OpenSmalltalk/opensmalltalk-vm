Class {
	#name : #VMJittedPrimitiveAtTest,
	#superclass : #VMJittedPrimitivesTest,
	#instVars : [
		'stop'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #helpers }
VMJittedPrimitiveAtTest >> assertFallsThrough [

	self runFrom: initialAddress until: stop address.
	self assert: machineSimulator instructionPointerValue equals: stop address
]

{ #category : #running }
VMJittedPrimitiveAtTest >> setUp [

	super setUp.
	self
		compile: [ 
			cogit objectRepresentation genPrimitiveAt.
			stop := cogit Stop ]
		bytecodes: 10.
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt16bitIndexableFirstPaddingOutOfBoundsShouldFallThrough [

	| integerArray offset |

	"A 1 slot-long 16-bit indexable object has 1 64 bits slot with 4 16-bit slots inside.
	1 16-bit slot is used, others are padding to fit 64bits.
	2th is then in bounds of the object but padding => fail"
	offset := 2.
	integerArray := self new16BitIndexableOfSize: 1.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt16bitIndexableOutOfBoundsShouldFallThrough [

	| integerArray offset |

	"A 1 slot-long 16-bit indexable object has 1 64 bits slot with 4 16-bit slots inside.
	1 16-bit slot is used, others are padding to fit 64bits.
	5th is then out of bounds => fail"
	offset := 5.
	integerArray := self new16BitIndexableOfSize: 4.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt16bitIndexableSecondPaddingOutOfBoundsShouldFallThrough [

	| integerArray offset |

	"A 1 slot-long 16-bit indexable object has 1 64 bits slot with 4 16-bit slots inside.
	1 16-bit slot is used, others are padding to fit 64bits.
	3rd is then in bounds of the object but padding => fail"
	offset := 3.
	integerArray := self new16BitIndexableOfSize: 1.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt16bitIndexableShouldReturnValue [

	| integerArray offset |

	"A 1 slot-long 16-bit indexable object has 1 64 bits slot with 4 16-bit slots inside.
	1 16-bit slot is used, others are padding to fit 64bits.
	5th is then out of bounds => fail"
	offset := 1.
	integerArray := self new16BitIndexableOfSize: 1.

	memory
		storeByte: offset - 1
		ofObject: integerArray
		withValue: 17.

	self
		prepareStackForSendReceiver: integerArray
		arguments: { memory integerObjectOf: offset }.
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self runUntilReturn.

	self
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue)
		equals: 17
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt16bitIndexableThirdPaddingOutOfBoundsShouldFallThrough [

	| integerArray offset |

	"A 1 slot-long 16-bit indexable object has 1 64 bits slot with 4 16-bit slots inside.
	1 16-bit slot is used, others are padding to fit 64bits.
	4th is then in bounds of the object but padding => fail"
	offset := 4.
	integerArray := self new16BitIndexableOfSize: 1.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt32bitIndexableOutOfBoundsAtPaddingShouldFallThrough [

	| integerArray offset |

	"A 32-bit indexable object has 4 slots in 32 bits.
	3 slots are used, last one is padding to fit 64bits.
	4th is then in bounds of the object but unused => fail"
	offset := 4.
	integerArray := self new32BitIndexableOfSize: 3.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt32bitIndexableOutOfBoundsShouldFallThrough [

	| integerArray offset |

	"A 32-bit indexable object has 4 slots in 32 bits.
	3 slots are used, last one is padding to fit 64bits.
	5th is out of object bounds"
	offset := 5.
	integerArray := self new32BitIndexableOfSize: 3.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt32bitIndexableShouldReturnValue [

	| integerArray offset |
	
	integerArray := self new32BitIndexableOfSize: 3.
	offset := 2.

	memory
		storeLong32: offset - 1
		ofObject: integerArray
		withValue: 17.

	self
		prepareStackForSendReceiver: integerArray
		arguments: { memory integerObjectOf: offset }.
	machineSimulator baseRegisterValue: cogit varBaseAddress.

	self runUntilReturn.

	self
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue)
		equals: 17
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
VMJittedPrimitiveAtTest >> testPrimitiveAt8bitIndexableFifthPaddingOutOfBoundsShouldFallThrough [

	| integerArray offset |

	"A 1 slot-long 8-bit indexable object has 1 64 bits slot with 8 8-bit slots inside.
	1 8-bit slot is used, others are padding to fit 64bits."
	offset := 6.
	integerArray := self new8BitIndexableOfSize: 1.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt8bitIndexableFirstPaddingOutOfBoundsShouldFallThrough [

	| integerArray offset |

	"A 1 slot-long 8-bit indexable object has 1 64 bits slot with 8 8-bit slots inside.
	1 8-bit slot is used, others are padding to fit 64bits."
	offset := 2.
	integerArray := self new8BitIndexableOfSize: 1.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt8bitIndexableFourthPaddingOutOfBoundsShouldFallThrough [

	| integerArray offset |

	"A 1 slot-long 8-bit indexable object has 1 64 bits slot with 8 8-bit slots inside.
	1 8-bit slot is used, others are padding to fit 64bits."
	offset := 5.
	integerArray := self new8BitIndexableOfSize: 1.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt8bitIndexableOutOfBoundsShouldFallThrough [

	| integerArray offset |

	"A 1 slot-long 8-bit indexable object has 1 64 bits slot with 8 8-bit slots inside.
	1 8-bit slot is used, others are padding to fit 64bits."
	offset := 9.
	integerArray := self new8BitIndexableOfSize: 4.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt8bitIndexableSecondPaddingOutOfBoundsShouldFallThrough [

	| integerArray offset |

	"A 1 slot-long 8-bit indexable object has 1 64 bits slot with 8 8-bit slots inside.
	1 8-bit slot is used, others are padding to fit 64bits."
	offset := 3.
	integerArray := self new8BitIndexableOfSize: 1.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt8bitIndexableSeventhPaddingOutOfBoundsShouldFallThrough [

	| integerArray offset |

	"A 1 slot-long 8-bit indexable object has 1 64 bits slot with 8 8-bit slots inside.
	1 8-bit slot is used, others are padding to fit 64bits."
	offset := 8.
	integerArray := self new8BitIndexableOfSize: 1.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt8bitIndexableShouldReturnValue [

	| integerArray offset |

	"A 1 slot-long 8-bit indexable object has 1 64 bits slot with 8 8-bit slots inside.
	1 8-bit slot is used, others are padding to fit 64bits."
	offset := 1.
	integerArray := self new8BitIndexableOfSize: 1.

	memory
		storeByte: offset - 1
		ofObject: integerArray
		withValue: 17.

	self
		prepareStackForSendReceiver: integerArray
		arguments: { memory integerObjectOf: offset }.
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self runUntilReturn.

	self
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue)
		equals: 17
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt8bitIndexableSixthPaddingOutOfBoundsShouldFallThrough [

	| integerArray offset |

	"A 1 slot-long 8-bit indexable object has 1 64 bits slot with 8 8-bit slots inside.
	1 8-bit slot is used, others are padding to fit 64bits."
	offset := 7.
	integerArray := self new8BitIndexableOfSize: 1.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
]

{ #category : #'tests - primitiveAt' }
VMJittedPrimitiveAtTest >> testPrimitiveAt8bitIndexableThirdPaddingOutOfBoundsShouldFallThrough [

	| integerArray offset |

	"A 1 slot-long 8-bit indexable object has 1 64 bits slot with 8 8-bit slots inside.
	1 8-bit slot is used, others are padding to fit 64bits."
	offset := 4.
	integerArray := self new8BitIndexableOfSize: 1.

	self prepareStackForSendReceiver: integerArray arguments: { memory integerObjectOf: offset }.

	self assertFallsThrough
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
