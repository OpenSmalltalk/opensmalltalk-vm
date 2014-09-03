"
I represent a constrained variable. In addition to my value, I maintain the structure of the constraint graph, the current dataflow graph, and various parameters of interest to the DeltaBlue incremental constraint solver.

Instance variables:
	value			my value; changed by constraints, read by client <Object>
	constraints		normal constraints that reference me <Array of Constraint>
	determinedBy	the constraint that currently determines
					my value (or nil if there isn''t one) <Constraint>
	walkStrength		my walkabout strength <Strength>
	stay			true if I am a planning-time constant <Boolean>
	mark			used by the planner to mark constraints <Number>
"
Class {
	#name : #DBVariable,
	#superclass : #Object,
	#instVars : [
		'constraints',
		'determinedBy',
		'mark',
		'stay',
		'value',
		'walkStrength'
	],
	#category : #'CogBenchmarks-DeltaBlue'
}

{ #category : #'instance creation' }
DBVariable class >> value: aValue [

	^self new value: aValue
]

{ #category : #accessing }
DBVariable >> addConstraint: aConstraint [
	"Add the given constraint to the set of all constraints that refer
	 to me."

	constraints add: aConstraint.
]

{ #category : #accessing }
DBVariable >> constraints [
	^ constraints
]

{ #category : #accessing }
DBVariable >> determinedBy [
	^ determinedBy
]

{ #category : #accessing }
DBVariable >> determinedBy: anObject [
	determinedBy := anObject
]

{ #category : #initialize }
DBVariable >> initialize [

	super initialize.

	value := 0.
	constraints := OrderedCollection new: 2.
	determinedBy := nil.
	walkStrength := DBStrength absoluteWeakest.
	stay := true.
	mark := 0.
]

{ #category : #printing }
DBVariable >> longPrintOn: aStream [

	self shortPrintOn: aStream.
	aStream nextPutAll: '   Constraints: '.
	(constraints isEmpty)
		ifTrue: [aStream cr; tab; nextPutAll: 'none']
		ifFalse:
			[constraints do:
				[: c | aStream cr; tab. c shortPrintOn: aStream]].
	(determinedBy isNil) ifFalse:
		[aStream cr; nextPutAll: '   Determined by: '.
		 aStream cr; tab. determinedBy shortPrintOn: aStream].
	aStream cr.
]

{ #category : #accessing }
DBVariable >> mark [
	^ mark
]

{ #category : #accessing }
DBVariable >> mark: anObject [
	mark := anObject
]

{ #category : #printing }
DBVariable >> printOn: aStream [

	self shortPrintOn: aStream
]

{ #category : #accessing }
DBVariable >> removeConstraint: c [
	"Remove all traces of c from this variable."

	constraints remove: c ifAbsent: [].
	determinedBy == c ifTrue: [determinedBy := nil].
]

{ #category : #update }
DBVariable >> setValue: aValue [
	"Attempt to assign the given value to me using a strength of
	 #preferred."

	self setValue: aValue strength: #preferred.
]

{ #category : #update }
DBVariable >> setValue: aValue strength: strengthSymbol [
	"Attempt to assign the given value to me using the given strength."

	| editConstraint |
	editConstraint := DBEditConstraint var: self strength: strengthSymbol.
	(editConstraint isSatisfied) ifTrue:
		[self value: aValue.
		 DBPlanner propagateFrom: self].
	editConstraint destroyConstraint.
]

{ #category : #printing }
DBVariable >> shortPrintOn: aStream [

	aStream nextPutAll: 'V(', self printString, ', '.
	aStream nextPutAll: walkStrength printString, ', '.
	(stay isNil) ifFalse:
		[aStream nextPutAll: (stay ifTrue: ['stay, '] ifFalse: ['changing, '])].
	aStream nextPutAll: value printString.
	aStream nextPutAll: ')'.
	aStream cr.
]

{ #category : #accessing }
DBVariable >> stay [
	^ stay
]

{ #category : #accessing }
DBVariable >> stay: anObject [
	stay := anObject
]

{ #category : #accessing }
DBVariable >> value [
	^ value
]

{ #category : #accessing }
DBVariable >> value: anObject [
	value := anObject
]

{ #category : #accessing }
DBVariable >> walkStrength [
	^ walkStrength
]

{ #category : #accessing }
DBVariable >> walkStrength: anObject [
	walkStrength := anObject
]
