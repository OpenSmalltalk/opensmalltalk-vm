Class {
	#name : #SlangClass,
	#superclass : #Object,
	#classVars : [
		'ExpensiveAsserts'
	],
	#category : #Slang
}

{ #category : #translation }
SlangClass class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^{}
]

{ #category : #translation }
SlangClass class >> declareCVarsIn: aCCodeGenerator [ 


]

{ #category : #translation }
SlangClass class >> prepareToBeAddedToCodeGenerator: aCCodeGenerator [ 
	"Hook for translation.  e.g. allows a subclass to override its
	 superclass's methods by deleting them before it adds its own."
]

{ #category : #translation }
SlangClass class >> requiredMethodNames: options [
	"Answer a list of method names that should be retained for export or other
	 support reasons.  These are typically entry-points that unless explicitly noted
	 will be deleted by the code generator since it will assume these are not used."
	^#()
]

{ #category : #translation }
SlangClass class >> shouldGenerateDeadCode [
	"Answer if the code generator should generate dead code, e.g. in false ifTrue: [dead] ifFalse: [live].
	 This *may* be useful in debugging (see CCodeGenerator>>nilOrBooleanConstantReceiverOf: et al).
	 But by default we answer false."

	^false
]

{ #category : #'translation support' }
SlangClass >> cCode: codeString [
	"Support for Smalltalk-to-C translation.
	 For translation only; noop when running in Smalltalk.
	 The argument is output literally when generating C code."
	<doNotGenerate>
]

{ #category : #'translation support' }
SlangClass >> cCode: codeStringOrBlock inSmalltalk: aBlock [
	"Support for Smalltalk-to-C translation. The first argument is output when generating C code.
	  But if this code is being simulated in Smalltalk, answer the result of evaluating the given block.
	  If the first argument is a string it is output literally, and if it is a block it is translated.
	  N.B.  If the first argument is a block then replacement happens at TMethod creation time so the use
	  of cCode:inSmalltalk: with a block first argument does not prevent inlining and is hence preferred."
	<doNotGenerate>
	^aBlock value
]

{ #category : #'C pre-processor extensions' }
SlangClass >> defined: aSymbol [
	"Simulated version of the C pre-processor defined()"
	<doNotGenerate>
	^(self class bindingOf: aSymbol)
		ifNil: [false]
		ifNotNil: [:binding| binding value ~~ #undefined]
]

{ #category : #'simulation support' }
SlangClass >> deny: aBooleanOrBlock [
	<doNotGenerate>
	aBooleanOrBlock value ifTrue: [AssertionFailure signal: 'Assertion failed']
]

{ #category : #'debug support' }
SlangClass >> eassert: aBooleanExpressionOrBlock [
	"This is for expensive asserts that we're only interested in checking in extremis.
	 For example now that Spur objStacks are debugged there's no benefit to
	 evaluating isValidObjStack: throughout the mark loop because its damn slow."
	<doNotGenerate>
	ExpensiveAsserts ifTrue:
		[aBooleanExpressionOrBlock value ifFalse:
			[AssertionFailure signal: 'Assertion failed']]
]

{ #category : #'translation support' }
SlangClass >> error [

	<cmacro: ''>
]
