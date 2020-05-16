Class {
	#name : #UnicornInvalidMemoryAccess,
	#superclass : #Error,
	#instVars : [
		'type',
		'address',
		'size'
	],
	#category : #VMMakerTests
}

{ #category : #accessing }
UnicornInvalidMemoryAccess >> address [
	^ address
]

{ #category : #accessing }
UnicornInvalidMemoryAccess >> address: anObject [
	address := anObject
]

{ #category : #accessing }
UnicornInvalidMemoryAccess >> size [
	^ size
]

{ #category : #accessing }
UnicornInvalidMemoryAccess >> size: anObject [
	size := anObject
]

{ #category : #accessing }
UnicornInvalidMemoryAccess >> type [
	^ type
]

{ #category : #accessing }
UnicornInvalidMemoryAccess >> type: anObject [
	type := anObject
]
