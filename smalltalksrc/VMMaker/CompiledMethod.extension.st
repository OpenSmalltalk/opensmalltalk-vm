Extension { #name : #CompiledMethod }

{ #category : #'*VMMaker-support' }
CompiledMethod >> abstractDetailedSymbolic [
	^String streamContents: [:s| (RelativeDetailedInstructionPrinter on: self) printInstructionsOn: s]
]

{ #category : #'*VMMaker-C translation' }
CompiledMethod >> asTranslationMethodOfClass: aTMethodClass [

	^ self parseTree asTranslationMethodOfClass: aTMethodClass
]

{ #category : #'*VMMaker-C translation' }
CompiledMethod >> asTranslationMethodOfClass: aTMethodClass forCodeGenerator: aCodeGenerator [

	^ self parseTree asTranslationMethodOfClass: aTMethodClass forCodeGenerator: aCodeGenerator
]

{ #category : #'*VMMaker-support' }
CompiledMethod >> detailedSymbolic [
	^String streamContents: [:s| (DetailedInstructionPrinter on: self) printInstructionsOn: s]
]
