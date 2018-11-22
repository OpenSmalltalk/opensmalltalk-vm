Extension { #name : #ArrayedCollection }

{ #category : #'*VMMakerCompatibilityForPharo6-accessing' }
ArrayedCollection >> bytesPerElement [
	| bytesPerElementOrZero |
	bytesPerElementOrZero := #[0 0 0 0 0 0 0 0 8 4 4 2 2 2 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1] at: self class instSpec.
	^bytesPerElementOrZero = 0
		ifTrue: [Smalltalk wordSize]
		ifFalse: [bytesPerElementOrZero]
]
