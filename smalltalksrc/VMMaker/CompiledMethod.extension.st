Extension { #name : #CompiledMethod }

{ #category : #'*VMMaker-support' }
CompiledMethod >> abstractDetailedSymbolic [
	^String streamContents: [:s| (RelativeDetailedInstructionPrinter on: self) printInstructionsOn: s]
]

{ #category : #'*VMMaker-support' }
CompiledMethod >> detailedSymbolic [
	^String streamContents: [:s| (DetailedInstructionPrinter on: self) printInstructionsOn: s]
]

{ #category : #'*VMMaker-support' }
CompiledMethod >> usesAlternateBytecodeSet [
	"only an issue in vmcompiledmethodproxy stuff"
	^false
]
