Extension { #name : #CompiledMethod }

{ #category : #'*VMMaker-support' }
CompiledMethod >> abstractDetailedSymbolic [
	^String streamContents: [:s| (RelativeDetailedInstructionPrinter on: self) printInstructionsOn: s]
]

{ #category : #'*VMMaker-C translation' }
CompiledMethod >> asTranslationMethodOfClass: aTMethodClass [
 	"Answer a TMethod (or subclass) derived from the receiver."
	^((CompiledMethod includesSelector: #ast)
			ifTrue: [self parseTree] "Pharo Opal Bytecode Compiler"
			ifFalse: [self methodNode]) "Squeak Smalltalk-80 Bytecode Compiler"
		asTranslationMethodOfClass: aTMethodClass
]

{ #category : #'*VMMaker-support' }
CompiledMethod >> detailedSymbolic [
	^String streamContents: [:s| (DetailedInstructionPrinter on: self) printInstructionsOn: s]
]
