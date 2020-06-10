Class {
	#name : #UnicornInvalidMemoryAccess,
	#superclass : #Error,
	#instVars : [
		'type',
		'address',
		'size',
		'value'
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

{ #category : #testing }
UnicornInvalidMemoryAccess >> isFetch [
	
	^ self type value anyMask: UcMemoryAccessType UC_MEM_FETCH value
]

{ #category : #accessing }
UnicornInvalidMemoryAccess >> messageText [

	^ type item asString, ' at ', address hex
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

{ #category : #accessing }
UnicornInvalidMemoryAccess >> value [
	^ value
]

{ #category : #accessing }
UnicornInvalidMemoryAccess >> value: anObject [
	value := anObject
]
