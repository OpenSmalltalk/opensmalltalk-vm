Class {
	#name : #VMJittedPrimitivesTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#instVars : [
		'classFloat'
	],
	#pools : [
		'CogRTLOpcodes'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #private }
VMJittedPrimitivesTest class >> isAbstract [
	^ self == VMJittedPrimitivesTest
]

{ #category : #helpers }
VMJittedPrimitivesTest >> executePrimitiveWithReceiver: receiverOop withArgument: argumentOop [
	
	"Simulate a primitive execution having an object as receiver and a single argument
	  - the receiver goes to the receiver register
	  - the argument should be pushed to the stack
	If we are in a system without a link register, we need to push the caller IP to the stack to simulate a call"
	
	self prepareStackForSendReceiver: receiverOop arguments: { argumentOop }.
	
	self runUntilReturn.

]

{ #category : #helpers }
VMJittedPrimitivesTest >> new16BitIndexableOfSize: aSize [

	^ self newBitIndexableOfSize: aSize bytesPerSlot: 2 format: memory firstShortFormat
]

{ #category : #helpers }
VMJittedPrimitivesTest >> new32BitIndexableOfSize: aSize [

	^ self newBitIndexableOfSize: aSize bytesPerSlot: 4 format: memory firstLongFormat
]

{ #category : #helpers }
VMJittedPrimitivesTest >> new64BitIndexableOfSize: aSize [

	^ memory
		allocateNewSpaceSlots: aSize
		format: memory sixtyFourBitIndexableFormat
		classIndex: self nextOrdinaryClassIndex.
]

{ #category : #helpers }
VMJittedPrimitivesTest >> new8BitIndexableOfSize: aSize [

	^ self newBitIndexableOfSize: aSize bytesPerSlot: 1 format: memory firstByteFormat
]

{ #category : #helpers }
VMJittedPrimitivesTest >> newBitIndexableOfSize: aSize bytesPerSlot: bytesPerSlot format: format [

	| padding numberOfWordSizeSlots desiredByteSize |
	desiredByteSize := aSize * bytesPerSlot roundUpTo: self wordSize.
	numberOfWordSizeSlots := desiredByteSize / self wordSize.
	padding := desiredByteSize / bytesPerSlot - aSize.
	^ memory
		  allocateNewSpaceSlots: numberOfWordSizeSlots
		  format: format + padding
		  classIndex: self nextOrdinaryClassIndex
]

{ #category : #helpers }
VMJittedPrimitivesTest >> prepareStackForSendReceiver: aReceiver arguments: arguments [ 	

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self pushAddress: aReceiver.
	arguments do: [ :anArgument | self pushAddress: anArgument ].
	self machineSimulator receiverRegisterValue: aReceiver.

	machineSimulator hasLinkRegister 
		ifTrue: [ machineSimulator linkRegisterValue: callerAddress "The caller IP in ARM is in the linkRegister"]
		ifFalse: [ self pushAddress:  callerAddress. " I need to push the caller IP, as this is a message send" ]

]

{ #category : #helpers }
VMJittedPrimitivesTest >> setUp [

	super setUp.

	classFloat := self newClassInOldSpaceWithSlots: 0 instSpec: memory firstLongFormat.
	memory setHashBitsOf: classFloat to: ClassFloatCompactIndex.
	memory
		storePointer: ClassFloatCompactIndex
		ofObject: memory classTableFirstPage
		withValue: classFloat.
]
