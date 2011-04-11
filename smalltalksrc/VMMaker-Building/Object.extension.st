Extension { #name : #Object }

{ #category : #'*VMMaker-translation support' }
Object >> asIf: aClass var: aString [

	|index|
	index := aClass allInstVarNames 
		indexOf: aString
		ifAbsent: [self error: 'must use instVar name'].
	^self instVarAt: index

]

{ #category : #'*VMMaker-translation support' }
Object >> asIf: aClass var: aString asValue: someClass [

	^(self asIf: aClass var: aString) asValue: someClass

]

{ #category : #'*VMMaker-translation support' }
Object >> asIf: aClass var: aString put: aValue [

	|index|
	index := aClass allInstVarNames 
		indexOf: aString
		ifAbsent: [self error: 'must use instVar name'].
	^self instVarAt: index put: aValue

]

{ #category : #'*VMMaker-translation support' }
Object >> asOop: aClass [

	(self class isVariable and: [self class instSize > 0])
		ifTrue: [self error: 'cannot auto-coerce indexable objects with named instance variables'].
	(aClass ccgCanConvertFrom: self)
		ifFalse: [self error: 'incompatible object for this coercion'].
	^self
]

{ #category : #'*VMMaker-translation support' }
Object >> asSmallIntegerObj [

	^self
]

{ #category : #'*VMMaker-translation support' }
Object >> asValue: aClass [

	^self
]

{ #category : #'*VMMaker-translation support' }
Object >> buildCodeGeneratorUpTo: aClass [
	"Build a CCodeGenerator for this class. By default, generate only the
	the methods for aClass."
	 | cg |
	cg := self codeGeneratorClass new initialize.
	cg declareModuleName: self name.
	cg addClass: aClass.
	^cg

]

{ #category : #'*VMMaker-translation support' }
Object >> cCode: codeString [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'*VMMaker-translation support' }
Object >> cCode: codeStringOrBlock inSmalltalk: aBlock [
	"Support for Smalltalk-to-C translation. The first argument is output when generating C code.
	 But if this code is being simulated in Smalltalk, answer the result of evaluating the given block.
	 If the first argument is a string it is output literally, and if it is a block it is translated."

	^aBlock value

]

{ #category : #'*VMMaker-translation support' }
Object >> cCoerce: value to: cType [
	"Type coercion for translation only; just return the value when running in Smalltalk."

	^ value
]

{ #category : #'*VMMaker-plugin generation' }
Object class >> ccg: cg emitLoadFor: aString from: anInteger on: aStream [

	cg emitLoad: aString asNakedOopFrom: anInteger on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Object class >> ccg: cg generateCoerceToOopFrom: aNode on: aStream [

	cg emitCExpression: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Object class >> ccg: cg generateCoerceToValueFrom: aNode on: aStream [

	cg emitCExpression: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Object class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asKindOf: self from: anInteger
]

{ #category : #'*VMMaker-plugin generation' }
Object class >> ccgCanConvertFrom: anObject [

	^anObject isKindOf: self
]

{ #category : #'*VMMaker-plugin generation' }
Object class >> ccgDeclareCForVar: aSymbolOrString [

	^'sqInt ', aSymbolOrString
]

{ #category : #'*VMMaker-translation support' }
Object >> codeGeneratorClass [
	^CCodeGenerator
]

{ #category : #'*VMMaker-translation support' }
Object >> debugCode: aBlock [ 
	"Sending this message tells the code generator that there is debug code in 
	aBlock. Debug code will be be generated only, if the correponding flag 
	has been set by TestCodeGenerator>>generateDebugCode:.
	In ST simulation just perform the debug code."
	aBlock value
]

{ #category : #'*VMMaker-translation support' }
Object >> export: aBoolean [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'*VMMaker-translation support' }
Object >> inline: inlineFlag [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'*VMMaker-translation support' }
Object >> isCObjectAccessor [

	^ false
]

{ #category : #'*VMMaker-translation support' }
Object >> isDefined: directiveString inSmalltalk: conditionBlock comment: commentStringOrNil ifTrue: trueExpressionOrBlock [
	"When translated, produces #ifdef #endif CPP directives.
	Example usage:

	self isDefined: 'HAVE_FOO'
		inSmalltalk: [self isFoo]
		comment: 'some platforms do not support foo properly'
		ifTrue: [self doThingsThatWorkIfFooIsPresent]

	Generated C code:
	
	# ifdef HAVE_FOO  // some platforms do not support foo properly
 		doThingsThatWorkIfFooIsPresent();
	# endif  // HAVE_FOO
	"

	^ self isDefined: directiveString
			inSmalltalk: conditionBlock
			comment: commentStringOrNil
			ifTrue: trueExpressionOrBlock
			ifFalse: []

]

{ #category : #'*VMMaker-translation support' }
Object >> isDefined: directiveString inSmalltalk: conditionBlock comment: commentStringOrNil ifTrue: trueExpressionOrBlock ifFalse: falseExpressionOrBlockOrNil [
	"When translated, produces #ifdef #else #endif CPP directives.
	Example usage:

	Smalltalk Slang:
		self isDefined: 'HAVE_FOO'
			inSmalltalk: [self isFoo]
			comment: 'some platforms do not support foo properly'
			ifTrue: [self doThingsThatWorkIfFooIsPresent]
			ifFalse: [self doSomethingElseInstead]

	Generated C code:
		# ifdef HAVE_FOO  // some platforms do not support foo properly
			doThingsThatWorkIfFooIsPresent();
		# else
			doSomethingElseInstead();
		# endif  // HAVE_FOO

	Smalltalk Slang:
		hasFoo := self isDefined: 'HAVE_FOO'
					inSmalltalk: [self isFoo]
					comment: 'some platforms do not support foo properly'
					ifTrue: [true]
					ifFalse: [false].

	Generated C code:
		hasFoo =
	# ifdef HAVE_FOO  // some platforms do not support foo properly
			1
	# else
			0
	# endif  // HAVE_FOO
 		;

	"

	^ conditionBlock value
		ifTrue: [trueExpressionOrBlock value]
		ifFalse: [falseExpressionOrBlockOrNil value]

]

{ #category : #'*VMMaker-translation support' }
Object >> isDefinedTrueExpression: condition inSmalltalk: conditionBlock comment: commentStringOrNil ifTrue: trueExpressionOrBlock ifFalse: falseExpressionOrBlockOrNil [
	"When translated, produces #if (condition) #else #endif CPP directives.
	Example usage:

		self isDefinedTrueExpression: 'BytesPerWord == 8'
			inSmalltalk: [BytesPerWord = 8]
			comment: 'conditional on object word size'
			ifTrue: [self doSomethingFor64BitWord]
			ifFalse: [self doSomethingFor32BitWord]"

	^ conditionBlock value
		ifTrue: [trueExpressionOrBlock value]
		ifFalse: [falseExpressionOrBlockOrNil value]

]

{ #category : #'*VMMaker-translation support' }
Object >> preprocessorExpression: directive [
	"For translation only; noop when running in Smalltalk.
	When translated, emits directive as a C preprocessor directive.

	Example usage:

	self preprocessorExpression: 'ifdef HAS_FOO'.
	self doFooStuff.
	self preprocessorExpression: 'endif'.
	
	Generated C code:
	
	# ifdef HAS_FOO
		doFooStuff();
	# endif
	"
]

{ #category : #'*VMMaker-translation support' }
Object >> primitive: primName [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'*VMMaker-translation support' }
Object >> primitive: primName parameters: parms [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'*VMMaker-translation support' }
Object >> primitive: primID parameters: parmSpecs receiver: rcvrSpec [
"belongs in CCG package"
	| tMethod |
	tMethod := SmartSyntaxPluginTMethod new 
		fromContext: thisContext sender 
		primitive: primID 
		parameters: parmSpecs 
		receiver: rcvrSpec.
	^tMethod simulatePrologInContext: thisContext sender
]

{ #category : #'*VMMaker-translation support' }
Object >> remapOop: oopOrList in: aBlock [
	"For translation only; noop when running in Smalltalk."
	^aBlock value
]

{ #category : #'*VMMaker-translation support' }
Object >> returnTypeC: typeString [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'*VMMaker-translation support' }
Object >> sharedCodeNamed: label inCase: caseNumber [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'*VMMaker-translation support' }
Object >> stAt: index [

	^self at: index
]

{ #category : #'*VMMaker-translation support' }
Object >> stAt: index put: value [

	^self at: index put: value
]

{ #category : #'*VMMaker-translation support' }
Object >> stSize [

	^self size
]

{ #category : #'*VMMaker-translation support' }
Object >> static: aBoolean [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'*VMMaker-translation support' }
Object >> suppressFailureGuards: failureGuardFlag [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'*VMMaker-translation support' }
Object >> touch: something [
	"For translation only; eliminated by CCodeGenerator"
]

{ #category : #'*VMMaker-translation support' }
Object >> var: varSymbol declareC: declString [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'*VMMaker-translation support' }
Object >> var: varSymbol type: typeString [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'*VMMaker-translation support' }
Object >> var: varSymbol type: typeString array: array [
	"For translation only; noop when running in Smalltalk."
]
