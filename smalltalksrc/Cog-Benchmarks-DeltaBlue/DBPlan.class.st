"
A Plan is an ordered list of constraints to be executed in sequence to resatisfy all currently satisfiable constraints in the face of one or more changing inputs.
"
Class {
	#name : #DBPlan,
	#superclass : #OrderedCollection,
	#category : #'Cog-Benchmarks-DeltaBlue'
}

{ #category : #planning }
DBPlan >> execute [
	"Execute my constraints in order."

	self do: [: c | c execute].
]
