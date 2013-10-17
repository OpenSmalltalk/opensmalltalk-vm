Class {
	#name : #SpurContiguousObjStack,
	#superclass : #SpurNewSpaceSpace,
	#instVars : [
		'top'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

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
