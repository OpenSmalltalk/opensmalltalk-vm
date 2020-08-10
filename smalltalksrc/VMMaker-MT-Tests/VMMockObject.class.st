Class {
	#name : #VMMockObject,
	#superclass : #Object,
	#instVars : [
		'objectMemory'
	],
	#category : #'VMMaker-MT-Tests'
}

{ #category : #'instance creation' }
VMMockObject class >> new [

	^ self basicNew
]

{ #category : #accessing }
VMMockObject >> fetchPointer: anInteger [ 

	^ objectMemory addressOf: ((self class allSlots at: anInteger + 2) read: self)
]

{ #category : #accessing }
VMMockObject >> objectMemory: aSpurMockMemory [ 
	objectMemory := aSpurMockMemory.
	self initialize.
]

{ #category : #accessing }
VMMockObject >> storePointer: anInteger withValue: aValue [

	^ (self class allSlots at: anInteger + 2)
		write: (objectMemory objectFor: aValue)
		to: self
]
