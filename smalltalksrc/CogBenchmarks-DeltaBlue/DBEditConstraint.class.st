"
I mark variables that should, with some level of preference, stay the same. I have one method with zero inputs and one output, which does nothing. Planners may exploit the fact that, if I am satisfied, my output will not change during plan execution. This is called ""stay optimization.""
"
Class {
	#name : #DBEditConstraint,
	#superclass : #DBUnaryConstraint,
	#category : #'CogBenchmarks-DeltaBlue'
}

{ #category : #planning }
DBEditConstraint >> execute [
	"Edit constraints do nothing."
]

{ #category : #testing }
DBEditConstraint >> isInput [
	"I indicate that a variable is to be changed by imperative code."

	^true
]
