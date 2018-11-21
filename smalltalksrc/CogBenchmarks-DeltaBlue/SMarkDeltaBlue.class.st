"
One-way constraint solver Benchmark. The main focus in DeltaBlue is on polymorphism and object-oriented programming

To run the benchmark, execute the expression 'SMarkDeltaBlue run: 10'.
"
Class {
	#name : #SMarkDeltaBlue,
	#superclass : #SMarkSuite,
	#category : #'CogBenchmarks-DeltaBlue'
}

{ #category : #benchmarking }
SMarkDeltaBlue >> benchDeltaBlue [
	"This the combined benchmark."
	
	| n |
	
	n := self problemSize.
	
	DBStrength initialize.
	
	self doChain: n. 
	self doProjection: n
]

{ #category : #defaults }
SMarkDeltaBlue >> defaultProblemSize [
	^ 20000
]

{ #category : #benchmarking }
SMarkDeltaBlue >> doChain: n [

	| vars editConstraint plan planner |

	planner := DBPlanner new.
	vars := (1 to: n+1) collect: [ :i | DBVariable new].

	"thread a chain of equality constraints through the variables"
	1 to: n do:
		[ :i || v1 v2 |
		 v1 := vars at: i.
		 v2 := vars at: i + 1.
		 DBEqualityConstraint var: v1 var: v2 strength: #required].

	DBStayConstraint var: vars last strength: #strongDefault.
	editConstraint := DBEditConstraint var: (vars first) strength: #preferred.
	plan := planner extractPlanFromConstraints: (Array with: editConstraint).
	1 to: 100 do: [ :v | 
		vars first value: v.
		plan execute.
		vars last value ~= v ifTrue: [self error: 'Chain test failed!!']].
	editConstraint destroyConstraint
]

{ #category : #benchmarking }
SMarkDeltaBlue >> doProjection: n [
	"This test constructs a two sets of variables related to each other by
	 a simple linear transformation (scale and offset)."

	| scale offset src dst planner dests |
	planner := DBPlanner new.
	dests := OrderedCollection new.
	scale := DBVariable value: 10.
	offset := DBVariable value: 1000.
	1 to: n do:
		[ :i |
		src := DBVariable value: i.
		dst := DBVariable value: i.
		dests add: dst.
		DBStayConstraint var: src strength: #default.
		DBScaleConstraint var: src var: scale var: offset var: dst strength: #required].

	planner changeVar: src newValue: 17.
	dst value ~= 1170 ifTrue: [self error: 'Projection test 1 failed!!'].

	planner changeVar: dst newValue: 1050.
	src value ~= 5 ifTrue: [self error: 'Projection test 2 failed!!'].

	planner changeVar: scale newValue: 5.
	1 to: n - 1 do: [ :i |
		(dests at: i) value ~= (i*5 + 1000)
			ifTrue: [self error: 'Projection test 3 failed!!']].

	planner changeVar: offset newValue: 2000.
	1 to: n - 1 do: [ :i |
		(dests at: i) value ~= (i*5 + 2000)
			ifTrue: [self error: 'Projection test 4 failed!!']].
]

{ #category : #accessing }
SMarkDeltaBlue >> problemSize [
	<omniUnenforced> "Hint for the OMOP that it is part of the meta infrastructure"
	| ps |
	ps := super problemSize.
	
	ps isInteger ifFalse: [	^ self defaultProblemSize].
		
	^ ps
]
