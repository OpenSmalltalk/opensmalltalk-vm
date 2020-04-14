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

	memoryObject
		integerAt: (address - 1 * self bytesPerElement + 1) - initialAddress
		put: a32BitValue
		size: self bytesPerElement
		signed: false
]

{ #category : #accessing }
SpurSimulatedMemory >> bytesPerElement [
	
	^ 4
]

{ #category : #accessing }
SpurSimulatedMemory >> initialAddress: anAddress [

	initialAddress := anAddress
]

{ #category : #initialization }
SpurSimulatedMemory >> initializeSlots: anInteger [ 
	
	memoryObject := ByteArray new: anInteger * self bytesPerElement
]

{ #category : #converting }
SpurSimulatedMemory >> memoryObject [
	
	^ memoryObject
]

{ #category : #accessing }
SpurSimulatedMemory >> size [

	^ memoryObject size
]
