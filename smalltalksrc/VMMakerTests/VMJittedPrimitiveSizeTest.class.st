Class {
	#name : #VMJittedPrimitiveSizeTest,
	#superclass : #VMJittedPrimitivesTest,
	#instVars : [
		'stop'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #helpers }
VMJittedPrimitiveSizeTest >> assertFallsThrough [

	self runFrom: initialAddress until: stop address.
	self assert: machineSimulator instructionPointerValue equals: stop address
]

{ #category : #running }
VMJittedPrimitiveSizeTest >> setUp [

	super setUp.
	self
		compile: [ 
			cogit objectRepresentation genPrimitiveSize.
			stop := cogit Stop ]
		bytecodes: 10.
]

{ #category : #'tests - bit indexable' }
VMJittedPrimitiveSizeTest >> testPrimitiveSize16bitIndexableShouldReturnNumberOf16bitSlots [

	| integerArray |

	integerArray := self new16BitIndexableOfSize: 7.

	self prepareStackForSendReceiver: integerArray.
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self runUntilReturn.

	self
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue)
		equals: 7
]

{ #category : #'tests - bit indexable' }
VMJittedPrimitiveSizeTest >> testPrimitiveSize32bitIndexableShouldReturnNumberOf32bitSlots [

	| integerArray |

	integerArray := self new32BitIndexableOfSize: 7.

	self prepareStackForSendReceiver: integerArray.
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self runUntilReturn.
	
	self
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue)
		equals: 7
]

{ #category : #'tests - bit indexable' }
VMJittedPrimitiveSizeTest >> testPrimitiveSize32bitIndexableWithExtraHeaderShouldReturnNumberOf32bitSlots [

	| integerArray aSize bytesPerSlot desiredByteSize numberOfWordSizeSlots padding |

	aSize := 32768.
	bytesPerSlot := 4.

	desiredByteSize := aSize * bytesPerSlot roundUpTo: self wordSize.
	numberOfWordSizeSlots := desiredByteSize / self wordSize.
	padding := desiredByteSize / bytesPerSlot - aSize.
	integerArray := memory
		  allocateSlotsInOldSpace: numberOfWordSizeSlots
		  format: memory firstLongFormat + padding
		  classIndex: self nextOrdinaryClassIndex.

	self prepareStackForSendReceiver: integerArray.

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self runUntilReturn.
	
	self
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue)
		equals: 32768
]

{ #category : #'tests - bit indexable' }
VMJittedPrimitiveSizeTest >> testPrimitiveSize64bitIndexableShouldReturnNumberOf64bitSlots [

	| integerArray |

	integerArray := self new64BitIndexableOfSize: 7.

	self prepareStackForSendReceiver: integerArray.
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self runUntilReturn.

	self
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue)
		equals: 7
]

{ #category : #'tests - bit indexable' }
VMJittedPrimitiveSizeTest >> testPrimitiveSize8bitIndexableShouldReturnNumberOf8bitSlots [

	| integerArray |

	integerArray := self new8BitIndexableOfSize: 7.

	self prepareStackForSendReceiver: integerArray.
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self runUntilReturn.
	
	self
		assert: (memory integerValueOf: machineSimulator receiverRegisterValue)
		equals: 7
]

{ #category : #'tests - pointer indexable' }
VMJittedPrimitiveSizeTest >> testPrimitiveSizeArrayShouldReturnPointerSizedSlots [
	
	| array |

	array := self newObjectWithSlots: 7.

	self prepareStackForSendReceiver: array.	
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self runUntilReturn.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 7)
]

{ #category : #'tests - fixed pointer layout' }
VMJittedPrimitiveSizeTest >> testPrimitiveSizeFixedObjectShouldFallThrough [
	
	| objectWithInstanceVariables |
	
	objectWithInstanceVariables := memory
		allocateNewSpaceSlots: 3 "It has slots, but we should not access them"
		format: 1 "object with instance variables"
		classIndex: self nextOrdinaryClassIndex.
	
	self prepareStackForSendReceiver: objectWithInstanceVariables.

	self assertFallsThrough
]

{ #category : #'tests - fixed pointer layout' }
VMJittedPrimitiveSizeTest >> testPrimitiveSizeImmediateCharacterShouldFallThrough [
	
	self prepareStackForSendReceiver: (memory characterObjectOf: $a codePoint).

	self assertFallsThrough
]

{ #category : #'tests - fixed pointer layout' }
VMJittedPrimitiveSizeTest >> testPrimitiveSizeImmediateFloatShouldFallThrough [

	"Floats are not immediate in 32 bits"
	self wordSize = 4 ifTrue: [ ^self skip ].
	
	self prepareStackForSendReceiver: (memory floatObjectOf: 1.0).

	self assertFallsThrough
]

{ #category : #'tests - fixed pointer layout' }
VMJittedPrimitiveSizeTest >> testPrimitiveSizeImmediateIntegerShouldFallThrough [
	
	self prepareStackForSendReceiver: (memory integerObjectOf: 17).

	self assertFallsThrough
]
