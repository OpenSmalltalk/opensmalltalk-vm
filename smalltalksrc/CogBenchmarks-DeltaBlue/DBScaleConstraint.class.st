"
I relate two variables by the linear scaling relationship:
""v2 = (v1 * scale) + offset"". Either v1 or v2 may be changed to maintain this
relationship but the scale factor and offset are considered read-only.

Instance variables:
	scale		scale factor input variable <Variable>
	offset		offset input variable <Variable>
"
Class {
	#name : #DBScaleConstraint,
	#superclass : #DBBinaryConstraint,
	#instVars : [
		'offset',
		'scale'
	],
	#category : #'CogBenchmarks-DeltaBlue'
}

{ #category : #'instance creation' }
DBScaleConstraint class >> var: src var: scale var: offset var: dst strength: strengthSymbol [
	"Install a scale constraint with the given strength on the given variables."

	^(self new) src: src scale: scale offset: offset dst: dst strength: strengthSymbol
]

{ #category : #adding }
DBScaleConstraint >> addToGraph [
	"Add myself to the constraint graph."

	super addToGraph.
	scale addConstraint: self.
	offset addConstraint: self.

]

{ #category : #planning }
DBScaleConstraint >> execute [
	"Enforce this constraint. Assume that it is satisfied."

	direction == #forward
		ifTrue: [v2 value: v1 value * scale value + offset value]
		ifFalse: [v1 value: v2 value - offset value // scale value].
]

{ #category : #planning }
DBScaleConstraint >> inputsDo: aBlock [
	"Evaluate the given block on my current input variable."

	direction == #forward
		ifTrue: [ aBlock 
				value: v1; 
				value: scale; 
				value: offset]
		ifFalse: [ aBlock 
				value: v2; 
				value: scale; 
				value: offset].
]

{ #category : #planning }
DBScaleConstraint >> recalculate [
	"Calculate the walkabout strength, the stay flag, and, if it is 'stay', the value for the current output of this constraint. Assume this constraint is satisfied."

	| in out |
	direction == #forward
		ifTrue: [in := v1. out := v2]
		ifFalse: [out := v1. in := v2].
	out walkStrength: (strength weakest: in walkStrength).
	out stay: (in stay and: [scale stay and: [offset stay]]).
	out stay ifTrue: [self execute].		"stay optimization"
]

{ #category : #adding }
DBScaleConstraint >> removeFromGraph [
	"Remove myself from the constraint graph."

	super removeFromGraph.
	scale ifNotNil: [scale removeConstraint: self].
	offset ifNotNil: [offset removeConstraint: self].

]

{ #category : #initialize }
DBScaleConstraint >> src: srcVar scale: scaleVar offset: offsetVar dst: dstVar strength: strengthSymbol [
	"Initialize myself with the given variables and strength."

	strength := DBStrength of: strengthSymbol.
	v1 := srcVar.
	v2 := dstVar.
	scale := scaleVar.
	offset := offsetVar.
	direction := nil.
	self addConstraint.
]
