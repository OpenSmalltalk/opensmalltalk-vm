"
I am an abstract superclass for constraints having two possible output variables.

Instance variables:
	v1, v2		possible output variables <Variable>
	direction		one of:
					#forward (v2 is output)
					#backward (	v1 is output)
					nil (not satisfied)
"
Class {
	#name : #DBBinaryConstraint,
	#superclass : #DBAbstractConstraint,
	#instVars : [
		'direction',
		'v1',
		'v2'
	],
	#category : #'CogBenchmarks-DeltaBlue'
}

{ #category : #'instance creation' }
DBBinaryConstraint class >> var: variable1 var: variable2 strength: strengthSymbol [
	"Install a constraint with the given strength equating the given
	 variables."

	^(self new) var: variable1 var: variable2 strength: strengthSymbol
]

{ #category : #adding }
DBBinaryConstraint >> addToGraph [
	"Add myself to the constraint graph."

	v1 addConstraint: self.
	v2 addConstraint: self.
	direction := nil.
]

{ #category : #planning }
DBBinaryConstraint >> chooseMethod: mark [
	"Decide if I can be satisfied and which way I should flow based on the relative strength of the variables I relate, and record that decision."

	v1 mark == mark ifTrue:		"forward or nothing"
		[ ^ direction := ((v2 mark ~= mark) and: [strength stronger: v2 walkStrength])
			ifTrue: [ #forward ]
			ifFalse: [ nil ] ].

	v2 mark == mark ifTrue:		"backward or nothing"
		[ ^ direction := ((v1 mark ~= mark) and: [strength stronger: v1 walkStrength])
			ifTrue: [ #backward ]
			ifFalse: [ nil ] ].

	"if we get here, neither variable is marked, so we have choice"
	(v1 walkStrength weaker: v2 walkStrength)
		ifTrue:
			[ ^ direction := (strength stronger: v1 walkStrength)
				ifTrue: [ #backward ]
				ifFalse: [ nil ]]
		ifFalse:
			[ ^ direction := (strength stronger: v2 walkStrength)
				ifTrue: [ #forward ]
				ifFalse: [ nil ]]. 
]

{ #category : #planning }
DBBinaryConstraint >> execute [
	"Enforce this constraint. Assume that it is satisfied."

	self subclassResponsibility
]

{ #category : #planning }
DBBinaryConstraint >> inputsDo: aBlock [
	"Evaluate the given block on my current input variable."

	direction == #forward
		ifTrue: [ aBlock value: v1 ]
		ifFalse: [ aBlock value: v2 ].
]

{ #category : #testing }
DBBinaryConstraint >> isSatisfied [
	"Answer true if this constraint is satisfied in the current solution."

	^ direction notNil
]

{ #category : #planning }
DBBinaryConstraint >> markUnsatisfied [
	"Record the fact that I am unsatisfied."

	direction := nil.
]

{ #category : #planning }
DBBinaryConstraint >> output [
	"Answer my current output variable."

	^ direction == #forward
		ifTrue: [ v2 ]
		ifFalse: [ v1 ]
]

{ #category : #planning }
DBBinaryConstraint >> recalculate [
	"Calculate the walkabout strength, the stay flag, and, if it is 'stay',
         the value for the current output of this constraint. Assume this
	 constraint is satisfied."

	| in out |
	direction == #forward
		ifTrue: [in := v1. out := v2]
		ifFalse: [in := v2. out := v1].
	out walkStrength: (strength weakest: in walkStrength).
	out stay: in stay.
	out stay ifTrue: [ self execute ].		"stay optimization"
]

{ #category : #adding }
DBBinaryConstraint >> removeFromGraph [
	"Remove myself from the constraint graph."

	v1 ifNotNil: [v1 removeConstraint: self].
	v2 ifNotNil: [v2 removeConstraint: self].
	direction := nil.
]

{ #category : #initialize }
DBBinaryConstraint >> var: variable1 var: variable2 strength: strengthSymbol [
	"Initialize myself with the given variables and strength."

	strength := DBStrength of: strengthSymbol.
	v1 := variable1.
	v2 := variable2.
	direction := nil.
	self addConstraint.
]
