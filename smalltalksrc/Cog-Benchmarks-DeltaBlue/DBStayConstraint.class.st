"
I mark variables that should, with some level of preference, stay the same.
I have one method with zero inputs and one output, which does nothing. Planners
may exploit the fact that, if I am satisfied, my output will not change during
plan execution. This is called ""stay optimization.""
"
Class {
	#name : #DBStayConstraint,
	#superclass : #DBUnaryConstraint,
	#category : #'Cog-Benchmarks-DeltaBlue'
}

{ #category : #planning }
DBStayConstraint >> execute [
	"Stay constraints do nothing."
]
