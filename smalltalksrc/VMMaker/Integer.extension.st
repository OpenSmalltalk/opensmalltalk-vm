Extension { #name : #Integer }

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> coerceTo: cTypeString sim: interpreter [

	| unitSize |

	cTypeString last = $* ifTrue: [  "C pointer"
		unitSize _ cTypeString caseOf: {
		['char *'] -> [1].
		['int *'] -> [4].
		['float *'] -> [4].
		['unsigned *'] -> [4].
		['float *'] -> [4].
		}
		otherwise: [ (cTypeString beginsWith: 'char') ifTrue: [1] ifFalse: [4] ].
		^(CArray basicNew)
			interpreter: interpreter address: self unitSize: unitSize;
			yourself.
	].
	^ self  "C number (int, char, float, etc)"
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntFromLong [
	"Self is an unsigned 32-bit integer"

	| sign |
	self < 0 ifTrue: [self error: 'only valid for unsigned ints'].
	sign _ self bitAnd: 16r80000000.
	sign = 0 ifTrue: [^ self].
	^ self - sign - sign
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntFromShort [
	"Self is an unsigned 16-bit integer in twos-comp form"

	| sign |
	self < 0 ifTrue: [self error: 'only valid for unsigned ints'].
	sign _ self bitAnd: 16r8000.
	sign = 0 ifTrue: [^ self].
	^ self - sign - sign
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntToLong [
	"Produces a 32-bit value in twos-comp form.  Sorry no error checking"

	self >= 0
		ifTrue: [^ self]
		ifFalse: [^ self + 16r80000000 + 16r80000000]

]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntToShort [
	"Produces a 16-bit value (0-65k) in twos-comp form.  Sorry no error checking"

	self >= 0
		ifTrue: [^ self]
		ifFalse: [^ self + 16r8000 + 16r8000]

]
