Class {
	#name : #SpurContiguousObjStack,
	#superclass : #SpurNewSpaceSpace,
	#instVars : [
		'top'
	],
	#category : 'VMMaker-SpurMemoryManager'
}

{ #category : #printing }
SpurContiguousObjStack >> printOn: aStream [
	<doNotGenerate>
	super printOn: aStream.
	top ifNotNil:
		[aStream nextPutAll: ' top: '; nextPutAll: top hex]
]

{ #category : #accessing }
SpurContiguousObjStack >> top [
	"Answer the value of top"

	^ top
]

{ #category : #accessing }
SpurContiguousObjStack >> top: anObject [
	"Set the value of top"

	^top := anObject
]
