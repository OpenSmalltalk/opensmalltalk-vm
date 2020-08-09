Class {
	#name : #StackToRegisterMappingCogitChecker,
	#superclass : #StackToRegisterMappingCogit,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #'compile abstract instructions' }
StackToRegisterMappingCogitChecker >> scanBlock: blockStart [
	| result |
	 (result := super scanBlock: blockStart) < 0 ifTrue: [^result].
	needsFrame ifTrue:
		[| tempCount |
		 tempCount := coInterpreter tempCountForBlockStartingAt: blockStart startpc + 1 in: methodObj.
		 blockStart numInitialNils ~= tempCount ifTrue:
			[blockStart numInitialNils: tempCount]].
	^0
]
