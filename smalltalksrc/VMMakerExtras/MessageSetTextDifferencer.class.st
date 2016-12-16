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
	left ifNil:
		[right ifNil:
			[currentCompiledMethod := nil.
			 ^''].
		 ^rightSet contents].
	right isNil ifTrue:
		[^leftSet contents].
	^TextDiffBuilder buildDisplayPatchFrom: left source to: right source
]
