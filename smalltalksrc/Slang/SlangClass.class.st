Class {
	#name : #SlangClass,
	#superclass : #Object,
	#classVars : [
		'ExpensiveAsserts'
	],
	#category : #'Slang-Types'
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
SlangClass class >> defineAtCompileTime: anObject [

	"Override to define at translation time those variables that need to
	 be defined at compile time only in plugins, but not in the main VM,
	 because the VM generated is specific to these varables."
	^ false
]

{ #category : #translation }
SlangClass class >> isStructClass [
	"The various VMStructType classes override this."
	^false
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

{ #category : #translation }
SlangClass class >> typeForSelf [
	"Answer the type to give self if appropriate, or nil if not."
	^nil
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

{ #category : #accessing }
SlangClass >> cogitClass [
	
	self subclassResponsibility
]

{ #category : #'translation support' }
SlangClass >> cppIf: conditionBlockOrSymbolValue ifTrue: trueExpressionOrBlock ifFalse: falseExpressionOrBlockOrNil [
	"When translated, produces #if (condition) #else #endif CPP directives.
	 Example usage:

		self cppIf: [BytesPerWord = 8]
			ifTrue: [self doSomethingFor64Bit]
			ifFalse: [self doSomethingFor32Bit]
		self cppIf: BytesPerWord = 8
			ifTrue: [self doSomethingFor64Bit]
			ifFalse: [self doSomethingFor32Bit]
		self cppIf: #A_GLOBAL
			ifTrue: [self doSomethingFor64Bit]
			ifFalse: [self doSomethingFor32Bit]"
	<doNotGenerate>
	^(conditionBlockOrSymbolValue value
		ifNil: [false]
		ifNotNil: [:value|
			value isInteger
				ifTrue: [value ~= 0]
				ifFalse:
					[value isSymbol
						ifTrue: [(self class bindingOf: value)
									ifNil: [false]
									ifNotNil: [:binding| binding value]]
						ifFalse: [value]]])
		ifTrue: trueExpressionOrBlock
		ifFalse: falseExpressionOrBlockOrNil
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

{ #category : #accessing }
SlangClass >> initializationOptions [
	
	self subclassResponsibility
]

{ #category : #accessing }
SlangClass >> interpreterClass [
	
	self subclassResponsibility
]

{ #category : #accessing }
SlangClass >> objectMemoryClass [
	
	self subclassResponsibility
]

{ #category : #'translation support' }
SlangClass >> sizeof: objectSymbolOrClass [
	<doNotGenerate>
	| index |
	objectSymbolOrClass isInteger ifTrue:
		[^self class objectMemoryClass wordSize].
	(#(usqInt sqInt) includes: objectSymbolOrClass) ifTrue: [^self class objectMemoryClass bytesPerOop].
	objectSymbolOrClass isSymbol ifTrue:
		[(objectSymbolOrClass last == $*
		 or: [#(#long #'unsigned long' #'sqIntptr_t'  #'usqIntptr_t' #'size_t') includes: objectSymbolOrClass]) ifTrue:
			[^self class objectMemoryClass wordSize].
		index := #(	#sqLong #usqLong #double
					#int #'unsigned int' #float
					#short #'unsigned short'
					#char #'unsigned char' #'signed char')
						indexOf: objectSymbolOrClass
						ifAbsent:
							[self error: 'unrecognized C type name'].
		^#(8 8 8
			4 4 4
			2 2
			1 1 1) at: index].
	^(objectSymbolOrClass isBehavior
		ifTrue: [objectSymbolOrClass]
		ifFalse: [objectSymbolOrClass class])
			alignedByteSizeOf: objectSymbolOrClass
			forClient: self
]
