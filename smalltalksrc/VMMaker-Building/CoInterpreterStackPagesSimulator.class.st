"
I am a class that helps simulate the StackInterpreter's stack organization.
"
Class {
	#name : #CoInterpreterStackPagesSimulator,
	#superclass : #CoInterpreterStackPages,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #simulation }
CoInterpreterStackPagesSimulator >> oopForPointer: aPointer [
	"Simulation support.  Pointers and oops are the same when simulating; answer aPointer."

	^aPointer
]

{ #category : #accessing }
CoInterpreterStackPagesSimulator >> surrogateAtAddress: anAddress [ 
	^pageMap at: anAddress
]
