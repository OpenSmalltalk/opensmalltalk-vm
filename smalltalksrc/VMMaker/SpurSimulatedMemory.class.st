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

{ #category : #'as yet unclassified' }
SpurSimulatedMemory >> byteSize [
	
	^ self size
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

{ #category : #accessing }
SpurSimulatedMemory >> initialize [

	super initialize.
	initialAddress := 2*1024*1024.
]

{ #category : #initialization }
SpurSimulatedMemory >> initializeSlots: anInteger [ 
	
	"Allocate a memory to hold at least `anInteger` elements of size `self bytesPerElement`.
	This implementation will allocate memory in multiples of 4KB, allocating a bit more memory than required sometimes.
	This is required to run on the unicorn simulator which needs memory in multiples of 4KB."
	| bytesToAllocate trailingBytes |
	bytesToAllocate := anInteger * self bytesPerElement.
	
	"Calculate how many bytes to add to reach 4KB"
	trailingBytes := anInteger * self bytesPerElement \\ (4 * 1024).
	trailingBytes = 0 ifFalse: [ trailingBytes := (4 * 1024) - trailingBytes ].
	
	memoryObject := ByteArray new: bytesToAllocate + trailingBytes
]

{ #category : #loading }
SpurSimulatedMemory >> loadFrom: aMultiByteFileStream size: size inPosition: startingPosition [

	^ aMultiByteFileStream
		  readInto: memoryObject
		  startingAt: startingPosition - initialAddress + 1
		  count: size
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

{ #category : #'as yet unclassified' }
SpurSimulatedMemory >> longAt: address [ 
	
	^ memoryObject
		integerAt: address - initialAddress
		size: 4
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
