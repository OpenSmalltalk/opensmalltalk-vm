"
This benchmark is an implementation of the DeltaBlue Constraint Solver described in `The DeltaBlue Algorithm: An Incremental Constraint Hierarchy Solver'', by Bjorn N. Freeman-Benson and John Maloney, Communications of the ACM, January 1990 (also as University of Washington TR 89-08-06).

"
Class {
	#name : #DBPlanner,
	#superclass : #Object,
	#instVars : [
		'currentMark'
	],
	#classInstVars : [
		'currentPlanner'
	],
	#category : #'Cog-Benchmarks-DeltaBlue'
}

{ #category : #accessing }
DBPlanner class >> current [
	^ currentPlanner
]

{ #category : #'instance creation' }
DBPlanner class >> new [
	^ currentPlanner := super new
]

{ #category : #private }
DBPlanner >> addConstraintsConsuming: v to: aCollection [

	| determiningC |
	determiningC := v determinedBy.
	v constraints do:
		[ :c |
		 (c == determiningC or: [c isSatisfied not]) ifFalse:
			[aCollection add: c]].
]

{ #category : #private }
DBPlanner >> addPropagate: c mark: mark [
	"Recompute the walkabout strengths and stay flags of all variables
	 downstream of the given constraint and recompute the actual values
	 of all variables whose stay flag is true. If a cycle is detected,
	 remove the given constraint and answer false. Otherwise, answer true.

	 Details: Cycles are detected when a marked variable is encountered
	 downstream of the given constraint. The sender is assumed to have
	 marked the inputs of the given constraint with the given mark. Thus,
	 encountering a marked node downstream of the output constraint means
	 that there is a path from the constraint's output to one of its
	 inputs."

	| todo d |
	todo := OrderedCollection with: c.
	[todo isEmpty] whileFalse:
		[d := todo removeFirst.
		 (d output mark = mark) ifTrue:
			[self incrementalRemove: c.
			 ^ false].
		 d recalculate.
		 self addConstraintsConsuming: d output to: todo].
	^ true
]

{ #category : #private }
DBPlanner >> changeVar: aVariable newValue: newValue [

	| editConstraint plan |
	editConstraint := DBEditConstraint var: aVariable strength: #preferred.
	plan := self extractPlanFromConstraints: (Array with: editConstraint).
	10 timesRepeat: [
		aVariable value: newValue.
		plan execute].
	editConstraint destroyConstraint.
]

{ #category : #private }
DBPlanner >> constraintsConsuming: v do: aBlock [

	| determiningC |
	determiningC := v determinedBy.
	v constraints do:
		[ :c |
		 (c == determiningC or: [c isSatisfied not]) ifFalse:
			[aBlock value: c]].
]

{ #category : #planning }
DBPlanner >> extractPlanFromConstraints: constraints [
	"Extract a plan for resatisfaction starting from the outputs of the
	 given constraints, usually a set of input constraints."

	| sources |
	sources := OrderedCollection new.
	constraints do:
		[: c | (c isInput and: [c isSatisfied]) ifTrue: [sources add: c]].
	^self makePlan: sources
]

{ #category : #planning }
DBPlanner >> extractPlanFromVariables: variables [
	"Extract a plan from the dataflow graph having the given variables. It
	 is assumed that the given set of variables is complete, or at least
	 that it contains all the input variables."

	| sources |
	sources := OrderedCollection new.
	variables do:
		[: v |
		 (v constraints) do:
			[: c | (c isInput and: [c isSatisfied]) ifTrue: [sources add: c]]].
	^self makePlan: sources
]

{ #category : #adding }
DBPlanner >> incrementalAdd: c [
	"Attempt to satisfy the given constraint and, if successful,
	 incrementally update the dataflow graph.

	 Details: If satifying the constraint is successful, it may override a
	 weaker constraint on its output. The algorithm attempts to resatisfy
	 that constraint using some other method. This process is repeated
	 until either a) it reaches a variable that was not previously
	 determined by any constraint or b) it reaches a constraint that
	 is too weak to be satisfied using any of its methods. The variables
	 of constraints that have been processed are marked with a unique mark
	 value so that we know where we've been. This allows the algorithm to
	 avoid getting into an infinite loop even if the constraint graph has
	 an inadvertent cycle."

	| mark overridden |
	mark := self newMark.
	overridden := c satisfy: mark.
	[overridden isNil] whileFalse:
		[overridden := overridden satisfy: mark].
]

{ #category : #adding }
DBPlanner >> incrementalRemove: c [
	"Entry point for retracting a constraint. Remove the given constraint,
	 which should be satisfied, and incrementally update the dataflow
	 graph.

	 Details: Retracting the given constraint may allow some currently
	 unsatisfiable downstream constraint be satisfied. We thus collect a
	 list of unsatisfied downstream constraints and attempt to satisfy
	 each one in turn. This list is sorted by constraint strength,
	 strongest first, as a heuristic for avoiding unnecessarily adding
	 and then overriding weak constraints."

	| out unsatisfied |
	out := c output.
	c markUnsatisfied.
	c removeFromGraph.
	unsatisfied := self removePropagateFrom: out.
	unsatisfied do: [: u | self incrementalAdd: u].
]

{ #category : #initialize }
DBPlanner >> initialize [

	super initialize.

	currentMark := 1.
]

{ #category : #planning }
DBPlanner >> makePlan: sources [
	"Extract a plan for resatisfaction starting from the given satisfied
	 source constraints, usually a set of input constraints. This method
	 assumes that stay optimization is desired; the plan will contain only
	 constraints whose output variables are not stay. Constraints that do
	 no computation, such as stay and edit constraints, are not included
	 in the plan.

	 Details: The outputs of a constraint are marked when it is added to
	 the plan under construction. A constraint may be appended to the plan
	 when all its input variables are known. A variable is known if either
	 a) the variable is marked (indicating that has been computed by a
	 constraint appearing earlier in the plan), b) the variable is 'stay'
	 (i.e. it is a constant at plan execution time), or c) the variable
	 is not determined by any constraint. The last provision is for past
	 states of history variables, which are not stay but which are also
	 not computed by any constraint."

	| mark plan todo c |
	mark := self newMark.
	plan := DBPlan new.
	todo := sources.
	[todo isEmpty] whileFalse:
		[c := todo removeFirst.
		 ((c output mark ~= mark) and:		"not in plan already and..."
		  [c inputsKnown: mark]) ifTrue:	"eligible for inclusion"
			[plan addLast: c.
			 c output mark: mark.
			 self addConstraintsConsuming: c output to: todo]].
	^ plan
]

{ #category : #private }
DBPlanner >> newMark [
	"Select a previously unused mark value.

	 Details: We just keep incrementing. If necessary, the counter will
	 turn into a LargePositiveInteger. In that case, it will be a bit
	 slower to compute the next mark but the algorithms will all behave
	 correctly. We reserve the value '0' to mean 'unmarked'. Thus, this
	 generator starts at '1' and will never produce '0' as a mark value."

	^currentMark := currentMark + 1
]

{ #category : #planning }
DBPlanner >> propagateFrom: v [
	"The given variable has changed. Propagate new values downstream."

	| todo c |
	todo := OrderedCollection new.
	self addConstraintsConsuming: v to: todo.
	[todo isEmpty] whileFalse:
		[c := todo removeFirst.
		 c execute.
		 self addConstraintsConsuming: c output to: todo].
]

{ #category : #private }
DBPlanner >> removePropagateFrom: out [
	"Update the walkabout strengths and stay flags of all variables
	 downstream of the given constraint. Answer a collection of unsatisfied
	 constraints sorted in order of decreasing strength."

	| unsatisfied todo v |
	unsatisfied := SortedCollection sortBlock:
		[ :c1 :c2 | c1 strength stronger: c2 strength].
	out determinedBy: nil.
	out walkStrength: DBStrength absoluteWeakest.
	out stay: true.
	todo := OrderedCollection with: out.
	[todo isEmpty] whileFalse:
		[v := todo removeFirst.
		 v constraints do:
		 	[ :c | c isSatisfied ifFalse: [unsatisfied add: c]].
		 self constraintsConsuming: v do:
			[ :c |
			 c recalculate.
			 todo add: c output]].
	^ unsatisfied
]
