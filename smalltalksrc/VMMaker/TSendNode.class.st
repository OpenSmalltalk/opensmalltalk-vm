Class {
	#name : #TSendNode,
	#superclass : #TParseNode,
	#instVars : [
		'selector',
		'receiver',
		'arguments',
		'isBuiltinOperator',
		'isExpression'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #accessing }
TSendNode >> args [

	^arguments
]

{ #category : #converting }
TSendNode >> asExpression [
	"Sender expects to use this node as a simple expression rather than as as statement"

	self isExpression: true.
	^self
]

{ #category : #transformations }
TSendNode >> bindVariableUsesIn: aDictionary [

	receiver := receiver bindVariableUsesIn: aDictionary.
	arguments := arguments collect: [ :a | a bindVariableUsesIn: aDictionary ].
]

{ #category : #transformations }
TSendNode >> bindVariablesIn: aDictionary [

	receiver := receiver bindVariablesIn: aDictionary.
	arguments := arguments collect: [ :a | a bindVariablesIn: aDictionary ].
]

{ #category : #'as yet unclassified' }
TSendNode >> copyTree [

	^self class new
		setSelector: selector
		receiver: receiver copyTree
		arguments: (arguments collect: [ :arg | arg copyTree ])
		isBuiltInOp: isBuiltinOperator
]

{ #category : #'C code generation' }
TSendNode >> emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen [
	"Emit the receiver in a form that can be passed as an argument."

	"If the selector is a built-in construct, translate it and return"
	(aCodeGen emitBuiltinConstructAsArgumentFor: self asExpression on: aStream level: level) ifFalse:
		["If it is a pointer dereference generate it"
		(self emitCCodeAsPointerDereferenceOn: aStream level: level generator: aCodeGen) ifFalse:
			["Otherwise generate the vanilla C function call."
			 self emitCCodeAsFunctionCallOn: aStream level: level generator: aCodeGen]]
]

{ #category : #'C code generation' }
TSendNode >> emitCCodeAsExpressionOn: aStream level: level generator: aCodeGen [
	^self emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen
]

{ #category : #'C code generation' }
TSendNode >> emitCCodeAsFunctionCallOn: aStream level: level generator: aCodeGen [

	"Translate this message send into a C function call"
	"Special case for pluggable modules. Replace messages to interpreterProxy
	 by interpreterProxy->message(..) if the message is not builtin"
	(aCodeGen isGeneratingPluginCode
	 and: [receiver isVariable
	 and: ['interpreterProxy' = receiver name
	 and: [self isBuiltinOperator not]]]) ifTrue:
		[aStream nextPutAll:'interpreterProxy->'].
	"Translate this message send into a C function call."
	aStream nextPutAll: (aCodeGen cFunctionNameFor: selector); nextPut: $(.
	"Only include the receiver as the first argument in certain cases.
	 The receiver is always included if it is an expression.
	 If it is a variable:
		 If the vmClass says it is an implicit variable, don't include it.
		 If the variable is 'self' and the method being called is not in
		 the method set (i.e. it is some external code), don't include it."
	(self shouldIncludeReceiverAsFirstArgument: aCodeGen) ifTrue:
		[receiver emitCCodeOn: aStream level: level generator: aCodeGen.
		arguments isEmpty ifFalse:
			[aStream nextPutAll: ', ']].
	arguments do:
		[ :arg| arg emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen]
		separatedBy: [aStream nextPut: $,; space].
	aStream nextPut: $)
]

{ #category : #'C code generation' }
TSendNode >> emitCCodeAsPointerDereferenceOn: aStream level: level generator: aCodeGen [
	"If appropriate, translate this message send as a pointer dereference"

	(self isStructSend: aCodeGen) ifFalse:
		[^false].

	aStream nextPut: $(.
	receiver  emitCCodeAsExpressionOn: aStream level: 0 generator: aCodeGen.
	aStream nextPut: $-; nextPut: $>.
	aStream nextPutAll: (aCodeGen cFunctionNameFor: selector).
	arguments isEmpty ifFalse:
		[self assert: arguments size = 1.
		 aStream nextPutAll: ' = '.
		 arguments first emitCCodeAsExpressionOn: aStream level: level generator: aCodeGen].
	aStream nextPut: $).
	^true
]

{ #category : #'C code generation' }
TSendNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	"Emit the receiver as a statement."

	"If the selector is a built-in construct, translate it and return"
	(aCodeGen emitBuiltinConstructFor: self on: aStream level: level) ifFalse:
		["If it is a pointer dereference generate it"
		(self emitCCodeAsPointerDereferenceOn: aStream level: level generator: aCodeGen) ifFalse:
			["Otherwise generate the vanilla C function call."
			 self emitCCodeAsFunctionCallOn: aStream level: level generator: aCodeGen]]
]

{ #category : #'as yet unclassified' }
TSendNode >> inlineMethodsUsing: aDictionary [

	arguments := arguments collect: [ :arg |
		arg inlineMethodsUsing: aDictionary.
	].
	"xxx inline this message if it is in the dictionary xxx"
]

{ #category : #testing }
TSendNode >> isAssertion [
	^(selector beginsWith: 'assert') or: [selector beginsWith: 'verify']
]

{ #category : #testing }
TSendNode >> isBuiltinOperator [

	^ isBuiltinOperator
]

{ #category : #testing }
TSendNode >> isBuiltinOperator: builtinFlag [

	isBuiltinOperator := builtinFlag.
]

{ #category : #'as yet unclassified' }
TSendNode >> isDirective [
	"Preprocessor directive, e.g. a cpp macro"

	^ {	#preprocessorExpression: .
		#isDefined:inSmalltalk:comment:ifTrue:ifFalse: .
		#isDefined:inSmalltalk:comment:ifTrue: .
		#isDefinedTrueExpression:inSmalltalk:comment:ifTrue:ifFalse:
		} identityIncludes: selector
]

{ #category : #accessing }
TSendNode >> isExpression [
	"Answer the value of isExpression. True if this node is expected to be used
	as an expression. Normally false but may be set by #asExpression to indicate
	that this node should be translated as a simple expression rather than as
	a statement."

	^ isExpression ifNil: [isExpression := false]
]

{ #category : #accessing }
TSendNode >> isExpression: anObject [
	"Set the value of isExpression"

	isExpression := anObject
]

{ #category : #testing }
TSendNode >> isSend [

	^true
]

{ #category : #testing }
TSendNode >> isStructSend: aCodeGen [
	"Answer if the recever is a send of a structure accessor.
	 This is tricky.  We want
		foo bar => foo->bar
		foo bar: expr => foo->bar = expr
	 but only if both foo is a struct type and bar is a field accessor.
	 The tricky cases are self-sends within struct class methods.  Here we need to
	 distinguish between self-sends of ordinary methods from self sends of accessors."
	^arguments size <= 1
	   and: [(receiver isStructTarget: aCodeGen)
	   and: [(aCodeGen methodNamed: selector)
				ifNil: [false]
				ifNotNil: [:method| method isStructAccessor]]]
]

{ #category : #testing }
TSendNode >> isStructTarget: aCodeGen [
	"Answer if the recever evaluates to a struct pointer
	 and hence can be dereferenced using ->"
	selector == #cCoerceSimple:to: ifTrue:
		[^aCodeGen isTypePointerToStruct: arguments last value].

	^aCodeGen selectorReturnsPointerToStruct: selector
]

{ #category : #enumerating }
TSendNode >> nodesDo: aBlock [

	receiver nodesDo: aBlock.
	arguments do: [ :arg | arg nodesDo: aBlock ].
	aBlock value: self.
]

{ #category : #'as yet unclassified' }
TSendNode >> printOn: aStream level: level [

	| keywords |
	receiver printOn: aStream level: level.
	arguments size = 0 ifTrue: [
		aStream space; nextPutAll: selector.
		^self
	].
	keywords := selector keywords.
	1 to: keywords size do: [ :i |
		aStream space.
		aStream nextPutAll: (keywords at: i); space.
		(arguments at: i) printOn: aStream level: level + 1.
	].
]

{ #category : #accessing }
TSendNode >> receiver [

	^receiver
]

{ #category : #accessing }
TSendNode >> receiver: aNode [

	receiver := aNode.
]

{ #category : #transformations }
TSendNode >> removeAssertions [
	receiver removeAssertions.
	arguments do: [:arg | arg removeAssertions].
]

{ #category : #transformations }
TSendNode >> replaceNodesIn: aDictionary [

	^aDictionary at: self ifAbsent: [
		receiver := receiver replaceNodesIn: aDictionary.
		arguments := arguments collect: [ :a | a replaceNodesIn: aDictionary ].
		self]
]

{ #category : #'as yet unclassified' }
TSendNode >> requiresCLineTerminator [

	^ (self isComment or: [self isDirective]) not

]

{ #category : #accessing }
TSendNode >> selector [

	^selector
]

{ #category : #accessing }
TSendNode >> setSelector: aSymbol receiver: rcvrNode arguments: argList [

	selector := aSymbol.
	receiver := rcvrNode.
	arguments := argList asArray.
	isBuiltinOperator := false.
]

{ #category : #accessing }
TSendNode >> setSelector: aSymbol receiver: rcvrNode arguments: argList isBuiltInOp: builtinFlag [

	selector := aSymbol.
	receiver := rcvrNode.
	arguments := argList asArray.
	isBuiltinOperator := builtinFlag.
]

{ #category : #'C code generation' }
TSendNode >> shouldExcludeReceiverAsFirstArgument: aCodeGen [
	"Only include the receiver as the first argument in certain cases.
	 The receiver is always included if it is an expression.
	 If it is a variable:
		 If the vmClass says it is an implicit variable, don't include it.
		 If the method's definingClass says it is an implicit variable, don't include it.
		 If the variable is 'self' and the method being called is not in
		 the method set (i.e. it is some external code), don't include it."
	| m |
	^receiver isVariable
	    and: [(aCodeGen isNonArgumentImplicitReceiverVariableName: receiver name)
		    or: [(receiver name beginsWith: 'self')
			    and: [(receiver name = 'self' or: [receiver name beginsWith: 'self_in_'])
			    and: [(m := aCodeGen methodNamed: selector) isNil
					or: [m typeForSelf == #implicit]]]]]
]

{ #category : #'C code generation' }
TSendNode >> shouldIncludeReceiverAsFirstArgument: aCodeGen [
	"Only include the receiver as the first argument in certain cases.
	 The receiver is always included if it is an expression.
	 If it is a variable:
		 If the vmClass says it is an implicit variable, don't include it.
		 If the variable is 'self' and the method being called is not in
		 the method set (i.e. it is some external code), don't include it."
	^(self shouldExcludeReceiverAsFirstArgument: aCodeGen) not
]
