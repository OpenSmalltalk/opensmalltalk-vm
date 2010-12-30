Extension { #name : #CompiledMethod }

{ #category : #'*VMMaker-support' }
CompiledMethod >> detailedSymbolic [
	^String streamContents: [:s| (DetailedInstructionPrinter on: self) printInstructionsOn: s]
]
