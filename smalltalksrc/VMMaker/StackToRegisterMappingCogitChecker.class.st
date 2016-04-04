Class {
	#name : #StackToRegisterMappingCogitChecker,
	#superclass : #StackToRegisterMappingCogit,
	#category : 'VMMaker-Tests'
}

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogitChecker >> scanBlock: blockStart [
	super scanBlock: blockStart.
	needsFrame ifTrue:
		[| tempCount |
		 tempCount := coInterpreter tempCountForBlockStartingAt: blockStart startpc + 1 in: methodObj.
		 blockStart numInitialNils ~= tempCount ifTrue:
			[blockStart numInitialNils: tempCount]]
]
