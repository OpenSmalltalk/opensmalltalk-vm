Extension { #name : #Integer }

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> coerceTo: cTypeString sim: interpreter [

	cTypeString last = $* ifTrue: [  "C pointer"
		^ CArray new interpreter: interpreter address: self unitSize:
			((cTypeString first: 4) = 'char' ifTrue: [1] ifFalse: [4])
	].
	^ self  "C number (int, char, float, etc)"
]
