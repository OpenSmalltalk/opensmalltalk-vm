"
I am a class that helps simulate the StackInterpreter's stack organization.
"
Class {
	#name : #CoInterpreterStackPagesSimulator,
	#superclass : #CoInterpreterStackPages,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
CoInterpreterStackPagesSimulator >> pages [
	^pages
]

{ #category : #accessing }
CoInterpreterStackPagesSimulator >> surrogateAtAddress: anAddress [ 
	^pageMap at: anAddress
]
