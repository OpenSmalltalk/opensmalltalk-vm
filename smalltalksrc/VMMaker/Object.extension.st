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
	^(Notification new tag: #getSimulator; signal)
		ifNotNil: [:simulator| aClass ccg: simulator generateCoerceToOopFrom: self on: nil]
		ifNil: [self]
]

{ #category : #'*VMMaker-translation support' }
Object >> asValue: aClass [

	^self
]

{ #category : #'*VMMaker-translation support' }
Object >> cCoerce: value to: cType [
	"Type coercion for translation only; just return the value when running in Smalltalk."

	^ value
]

{ #category : #'*VMMaker-plugin generation' }
Object class >> ccg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	^cg emitCExpression: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Object class >> ccg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg emitCExpression: aNode on: aStream
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
Object >> debugCode: aBlock [ 
	"Sending this message tells the code generator that there is debug code in 
	aBlock. Debug code will be be generated only, if the correponding flag 
	has been set by TestCodeGenerator>>generateDebugCode:.
	In ST simulation just perform the debug code."
	false ifTrue: [aBlock value]
]

{ #category : #'*VMMaker-translation support' }
Object >> isCObjectAccessor [

	^ false
]

{ #category : #'*VMMaker-translation support' }
Object >> isInterpreterPlugin [
	^false
]

{ #category : #'*VMMaker-translation support' }
Object >> isTParseNode [
	^false
]

{ #category : #'*VMMaker-translation support' }
Object >> returnTypeC: typeString [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'*VMMaker-translation support' }
Object >> stAt: index [
	"Simulation of generateStAt:on:indent:"
	
	^(Notification new tag: #getSimulator; signal)
		ifNotNil: [:simulator| simulator stObject: self at: index]
		ifNil: [self at: index]
]

{ #category : #'*VMMaker-translation support' }
Object >> stAt: index put: value [
	"Simulation of generateStAtPut:on:indent:"
	
	^(Notification new tag: #getSimulator; signal)
		ifNotNil: [:simulator| simulator getInterpreter stObject: self at: index put: value]
		ifNil: [self at: index put: value]
]

{ #category : #'*VMMaker-translation support' }
Object >> stSize [

	^self size
]

{ #category : #'*VMMaker-translation support' }
Object >> suppressFailureGuards: failureGuardFlag [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'*VMMaker-translation support' }
Object >> touch: something [
	"For translation only; eliminated by CCodeGenerator.  Used to squash unused varable warnings."
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
