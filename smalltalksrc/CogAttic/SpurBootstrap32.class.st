Class {
	#name : #SpurBootstrap32,
	#superclass : #SpurBootstrap,
	#category : #'CogAttic-Bootstrapping'
}

{ #category : #bootstrap }
SpurBootstrap32 >> fillInBitsObject: newObj from: oldObj [
	0 to: (oldHeap numSlotsOf: oldObj) - 1 do:
		[:i|
		newHeap
			storeLong32: i
			ofObject: newObj
			withValue: (oldHeap fetchLong32: i ofObject: oldObj)]
]

{ #category : #'word size' }
SpurBootstrap32 >> wordSize [
	^4
]

{ #category : #'word size' }
SpurBootstrap32 >> wordSizeMask [
	^3
]
