Class {
	#name : #MessageSetTextDifferencer,
	#superclass : #MessageSetDifferencer,
	#category : #'VMMakerExtras-Tools'
}

{ #category : #contents }
MessageSetTextDifferencer >> contents [
	"Answer the contents of the receiver"

	| left right |
	left := leftSet selection.
	right := rightSet selection.
	(left isNil and: [right isNil]) ifTrue:
		[currentCompiledMethod := nil.
		 ^''].
	left isNil ifTrue:
		[^rightSet contents].
	right isNil ifTrue:
		[^leftSet contents].
	^TextDiffBuilder buildDisplayPatchFrom: rightSet contents to: leftSet contents
]
