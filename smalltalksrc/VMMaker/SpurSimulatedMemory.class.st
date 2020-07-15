Class {
	#name : #SpurSimulatedMemory,
	#superclass : #Object,
	#instVars : [
		'memoryObject',
		'initialAddress'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #'instance creation' }
SpurSimulatedMemory class >> new: slots [

	^ self new
		initializeSlots: slots;
		yourself
]

{ #category : #accessing }
SpurSimulatedMemory >> at: address [

	^ memoryObject
		integerAt: (address - 1 * self bytesPerElement + 1) - initialAddress
		size: self bytesPerElement
		signed: false
]

{ #category : #accessing }
SpurSimulatedMemory >> at: address put: a32BitValue [

	^ memoryObject
		integerAt: (address - 1 * self bytesPerElement + 1) - initialAddress
		put: a32BitValue
		size: self bytesPerElement
		signed: false
]

{ #category : #accessing }
SpurSimulatedMemory >> bytesPerElement [
	
	^ 4
]

{ #category : #copying }
SpurSimulatedMemory >> copyFrom: anAddress [

	^ memoryObject
		copyFrom: anAddress - initialAddress + 1
		to: memoryObject size
]

{ #category : #accessing }
SpurSimulatedMemory >> copyFrom: start to: end [
	
	^ memoryObject copyFrom: start - initialAddress + 1 to: end - initialAddress + 1
]

{ #category : #accessing }
SpurSimulatedMemory >> initialAddress [
	^ initialAddress
]

{ #category : #accessing }
SpurSimulatedMemory >> initialAddress: anAddress [

	initialAddress := anAddress
]

{ #category : #initialization }
SpurSimulatedMemory >> initializeSlots: anInteger [ 
	
	memoryObject := ByteArray new: anInteger * self bytesPerElement
]

{ #category : #accessing }
SpurSimulatedMemory >> long64At: address [ 
	
	^ memoryObject
		integerAt: address - initialAddress
		size: 8
		signed: true
]

{ #category : #accessing }
SpurSimulatedMemory >> long64At: address put: aValue [
	
	^ memoryObject
		integerAt: address - initialAddress
		put: aValue
		size: 8
		signed: true
]

{ #category : #accessing }
SpurSimulatedMemory >> longAt: address put: aValue [

	^ memoryObject
		integerAt: address - initialAddress
		put: aValue
		size: 4
		signed: true
]

{ #category : #converting }
SpurSimulatedMemory >> memoryObject [
	
	^ memoryObject
]

{ #category : #accessing }
SpurSimulatedMemory >> size [

	^ memoryObject size
]

{ #category : #accessing }
SpurSimulatedMemory >> unsignedByteAt: anAddress [ 
	
	^ memoryObject
		integerAt: anAddress - initialAddress
		size: 1
		signed: false
]

{ #category : #accessing }
SpurSimulatedMemory >> unsignedByteAt: anAddress put: aValue [
	
	^ memoryObject
		integerAt: anAddress - initialAddress
		put: aValue
		size: 1
		signed: false
]

{ #category : #accessing }
SpurSimulatedMemory >> unsignedLong64At: address [ 

	^ memoryObject
		integerAt: address - initialAddress
		size: 8
		signed: false
]

{ #category : #accessing }
SpurSimulatedMemory >> unsignedLong64At: address put: aValue [ 
	
	^ memoryObject
		integerAt: address - initialAddress
		put: aValue
		size: 8
		signed: false
]

{ #category : #accessing }
SpurSimulatedMemory >> unsignedLongAt: address [

	^ memoryObject
		integerAt: address - initialAddress
		size: 4
		signed: false
]

{ #category : #accessing }
SpurSimulatedMemory >> unsignedLongAt: address put: aValue [ 

	^ memoryObject
		integerAt: address - initialAddress
		put: aValue
		size: 4
		signed: false
]

{ #category : #accessing }
SpurSimulatedMemory >> unsignedShortAt: anAddress [ 
	
	^ memoryObject
		integerAt: anAddress - initialAddress
		size: 2
		signed: false
]

{ #category : #accessing }
SpurSimulatedMemory >> unsignedShortAt: anAddress put: aValue [
	
	^ memoryObject
		integerAt: anAddress - initialAddress
		put: aValue
		size: 2
		signed: false
]
