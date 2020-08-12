Class {
	#name : #VMMockArray,
	#superclass : #VMMockObject,
	#instVars : [
		'array'
	],
	#category : #'VMMaker-MT-Tests'
}

{ #category : #'instance creation' }
VMMockArray class >> new: size [

	^ self new
		array: (Array new: size);
		yourself
]

{ #category : #accessing }
VMMockArray >> array: aCollection [ 
	array := aCollection
]

{ #category : #accessing }
VMMockArray >> at: anIndex [

	^ array at: anIndex
]

{ #category : #accessing }
VMMockArray >> at: anIndex put: aValue [

	array at: anIndex put: aValue
]

{ #category : #accessing }
VMMockArray >> fetchPointer: anInteger [

	^ objectMemory addressOf: (array at: anInteger + 1)
]

{ #category : #accessing }
VMMockArray >> numSlots [

	^ array size
]

{ #category : #accessing }
VMMockArray >> size [

	^ array size
]

{ #category : #accessing }
VMMockArray >> storePointer: anInteger withValue: aValue [

	^ array at: anInteger + 1 put: (objectMemory objectFor: aValue)
]
