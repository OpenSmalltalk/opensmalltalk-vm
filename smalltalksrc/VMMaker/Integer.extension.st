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
