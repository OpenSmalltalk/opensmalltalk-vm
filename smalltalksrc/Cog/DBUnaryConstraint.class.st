"
I am an abstract superclass for constraints having a single possible output variable.

Instance variables:
	output		possible output variable <Variable>
	satisfied		true if I am currently satisfied <Boolean>
"
Class {
	#name : #DBUnaryConstraint,
	#superclass : #DBAbstractConstraint,
	#instVars : [
		'output',
		'satisfied'
	],
	#category : #'Cog-Benchmarks-DeltaBlue'
}

{ #category : #'instance creation' }
DBUnaryConstraint class >> var: aVariable strength: strengthSymbol [
	"Install an edit constraint with the given strength on the given
	 variable."

	^(self new) var: aVariable strength: strengthSymbol
]

{ #category : #adding }
DBUnaryConstraint >> addToGraph [
	"Add myself to the constraint graph."

	output addConstraint: self.
	satisfied := false.
]

{ #category : #planning }
DBUnaryConstraint >> chooseMethod: mark [
	"Decide if I can be satisfied and record that decision."

	satisfied :=
		output mark ~= mark and:
		[strength stronger: output walkStrength].
]

{ #category : #planning }
DBUnaryConstraint >> execute [
	"Enforce this constraint. Assume that it is satisfied."

	self subclassResponsibility
]

{ #category : #planning }
DBUnaryConstraint >> inputsDo: aBlock [
	"I have no input variables."
]

{ #category : #testing }
DBUnaryConstraint >> isSatisfied [
	"Answer true if this constraint is satisfied in the current solution."

	^satisfied
]

{ #category : #planning }
DBUnaryConstraint >> markUnsatisfied [
	"Record the fact that I am unsatisfied."

	satisfied := false.
]

{ #category : #planning }
DBUnaryConstraint >> output [
	"Answer my current output variable."

	^ output
]

{ #category : #planning }
DBUnaryConstraint >> recalculate [
	"Calculate the walkabout strength, the stay flag, and, if it is 'stay',
	 the value for the current output of this constraint. Assume this
	 constraint is satisfied."

	output walkStrength: strength.
	output stay: self isInput not.
	output stay ifTrue: [self execute].	"stay optimization"
]

{ #category : #adding }
DBUnaryConstraint >> removeFromGraph [
	"Remove myself from the constraint graph."

	output ifNotNil: [ :out | out removeConstraint: self].
	satisfied := false.
]

{ #category : #initialize }
DBUnaryConstraint >> var: aVariable strength: strengthSymbol [
	"Initialize myself with the given variable and strength."

	strength := DBStrength of: strengthSymbol.
	output := aVariable.
	satisfied := false.
	self addConstraint.
]
