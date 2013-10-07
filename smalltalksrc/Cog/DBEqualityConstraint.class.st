"
I constrain two variables to have the same value: ""v1 = v2"".
"
Class {
	#name : #DBEqualityConstraint,
	#superclass : #DBBinaryConstraint,
	#category : #'Cog-Benchmarks-DeltaBlue'
}

{ #category : #planning }
DBEqualityConstraint >> execute [
	"Enforce this constraint. Assume that it is satisfied."
 
	direction == #forward
		ifTrue: [v2 value: v1 value]
		ifFalse: [v1 value: v2 value].
]
