"
I am an abstract class representing a system-maintainable relationship (or ""constraint"") between a set of variables. I supply a strength instance variable; concrete subclasses provide a means of storing the constrained variables and other information required to represent a constraint.

Instance variables:
	strength			the strength of this constraint <Strength>
"
Class {
	#name : #DBAbstractConstraint,
	#superclass : #Object,
	#instVars : [
		'strength'
	],
	#category : #'Cog-Benchmarks-DeltaBlue'
}

{ #category : #adding }
DBAbstractConstraint >> addConstraint [
	"Activate this constraint and attempt to satisfy it."

	self addToGraph.
	DBPlanner current incrementalAdd: self.
]

{ #category : #adding }
DBAbstractConstraint >> addToGraph [
	"Add myself to the constraint graph."

	self subclassResponsibility
]

{ #category : #planning }
DBAbstractConstraint >> chooseMethod: mark [
	"Decide if I can be satisfied and record that decision. The output of
	 the choosen method must not have the given mark and must have a
	 walkabout strength less than that of this constraint."

	self subclassResponsibility
]

{ #category : #adding }
DBAbstractConstraint >> destroyConstraint [
	"Deactivate this constraint, remove it from the constraint graph,
	 possibly causing other constraints to be satisfied, and destroy it."

	(self isSatisfied) ifTrue: [DBPlanner current incrementalRemove: self].
	self removeFromGraph.
	self release.
]

{ #category : #planning }
DBAbstractConstraint >> execute [
	"Enforce this constraint. Assume that it is satisfied."

	self subclassResponsibility
]

{ #category : #planning }
DBAbstractConstraint >> inputsDo: aBlock [
	"Assume that I am satisfied. Evaluate the given block on all my current
	 input variables."

	self subclassResponsibility
]

{ #category : #planning }
DBAbstractConstraint >> inputsKnown: mark [
	"Assume that I am satisfied. Answer true if all my current inputs are
	 known. A variable is known if either a) it is 'stay' (i.e. it is a
	 constant at plan execution time), b) it has the given mark (indicating
	 that it has been computed by a constraint appearing earlier in the
	 plan), or c) it is not determined by any constraint."

	self inputsDo:
		[ :v |
		 (v mark = mark or: [v stay or: [v determinedBy isNil]]) ifFalse:
			[^false]].
	^true
]

{ #category : #testing }
DBAbstractConstraint >> isInput [
	"Normal constraints are not input constraints. An input constraint is
	 one that depends on external state, such as the mouse, the keyboard,
	 a clock, or some arbitrary piece of imperative code."

	^false
]

{ #category : #testing }
DBAbstractConstraint >> isSatisfied [
	"Answer true if this constraint is satisfied in the current solution."

	self subclassResponsibility
]

{ #category : #printing }
DBAbstractConstraint >> longPrintOn: aStream [

	aStream nextPut: $(.
	self shortPrintOn: aStream.
	aStream space; nextPutAll: self strength printString.
	(self isSatisfied)
		ifTrue:
			[aStream cr; space; space; space.
			 self inputsDo:
				[ :in | aStream nextPutAll: 'v', in printString, ' '].
			aStream nextPutAll: '-> '.
			aStream nextPutAll: 'v', self output printString]
		ifFalse:
			[aStream space; nextPutAll: 'UNSATISFIED'].
	aStream nextPut: $); cr.
]

{ #category : #planning }
DBAbstractConstraint >> markUnsatisfied [
	"Record the fact that I am unsatisfied."

	self subclassResponsibility
]

{ #category : #planning }
DBAbstractConstraint >> output [
	"Answer my current output variable. Raise an error if I am not
	 currently satisfied."

	self subclassResponsibility
]

{ #category : #printing }
DBAbstractConstraint >> printOn: aStream [

	self shortPrintOn: aStream
]

{ #category : #planning }
DBAbstractConstraint >> recalculate [
	"Calculate the walkabout strength, the stay flag, and, if it is 'stay',
	 the value for the current output of this constraint. Assume this
	 constraint is satisfied."

	self subclassResponsibility
]

{ #category : #adding }
DBAbstractConstraint >> removeFromGraph [
	"Remove myself from the constraint graph."

	self subclassResponsibility
]

{ #category : #planning }
DBAbstractConstraint >> satisfy: mark [
	"Attempt to find a way to enforce this (still unsatisfied) constraint.
	 If successful, record the solution, perhaps modifying the current
	 dataflow graph.  Answer the constraint that this constraint overrides,
	 if there is one, or nil, if there isn't."

	| overridden out |
	self chooseMethod: mark.
	self isSatisfied
		ifTrue:			"constraint can be satisfied"
			["mark inputs to allow cycle detection in addPropagate"
			 self inputsDo: [ :in | in mark: mark].
			 out := self output.
			 overridden := out determinedBy.
			 overridden ifNotNil: [overridden markUnsatisfied].
			 out determinedBy: self.
			 (DBPlanner current addPropagate: self mark: mark) ifFalse:
				[self notify:
					('Cycle encountered adding:\   ',
					 self printString,
					 '\Constraint removed.') withCRs.
				 ^nil].
			 out mark: mark]
		ifFalse:			"constraint cannot be satisfied"
			[overridden := nil.
			 (strength sameAs: (DBStrength required)) ifTrue:
				[self notify: 'Failed to satisfy a required constraint']].
	^ overridden
]

{ #category : #printing }
DBAbstractConstraint >> shortPrintOn: aStream [

	aStream nextPutAll: self class name, '(', self printString, ')'.
]

{ #category : #accessing }
DBAbstractConstraint >> strength [
	^ strength
]

{ #category : #accessing }
DBAbstractConstraint >> strength: anObject [
	strength := anObject
]
