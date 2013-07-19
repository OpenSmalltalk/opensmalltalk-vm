Class {
	#name : #TSendNode,
	#superclass : #TParseNode,
	#instVars : [
		'selector',
		'receiver',
		'arguments',
		'isBuiltinOperator'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #accessing }
TSendNode >> args [

	^arguments
]

{ #category : #private }
TSendNode >> arguments: aSequence [
	arguments := aSequence
]

{ #category : #'inlining support' }
TSendNode >> argumentsForInliningCodeGenerator: aCodeGen [
	^(self shouldIncludeReceiverAsFirstArgument: aCodeGen)
		ifTrue: [{receiver}, arguments]
		ifFalse: [arguments]
]

{ #category : #transformations }
TSendNode >> bindVariableUsesIn: aDictionary [

	receiver := receiver bindVariableUsesIn: aDictionary.
	arguments := arguments collect: [ :a | a bindVariableUsesIn: aDictionary ].
]

{ #category : #transformations }
TSendNode >> bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen [
	"Answer either the receiver, if it contains no references to the given variables, or a new node with the given variables rebound.
	 Attempt to constant-fold and answer a constant node commented with the original expression.
	 Commenting with the original expression is important because it allows us to detect shared cases.
	 e.g. currentBytecode bitAnd: 15 is the same in case 1 and case 17, but '1 /* 1 bitAnd: 15 */' differs
	 from '1 /* 17 bitAnd: 15 */', whereas '1 /* currentBytecode bitAnd: 15 */' doesn't change."
	| newReceiver newArguments |
	newReceiver := receiver bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen.
	newArguments := arguments collect: [:a| a bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen].
	(newReceiver = receiver
	 and: [newArguments = arguments]) ifTrue:
		[^self].
	(constantFold
	 and: [newReceiver isConstant and: [newReceiver value isInteger]
	 and: [(newArguments allSatisfy: [:ea| ea isConstant and: [ea value isInteger]])
	 and: [codeGen isBuiltinSelector: selector]]]) ifTrue:
		[| value |
		value := [newReceiver value perform: selector withArguments: (newArguments collect: [:ea| ea value])]
					on: Error
					do: [:ea| nil].
		 (value isInteger
		 or: [value == true
		 or: [value == false]]) ifTrue:
			[^TConstantNode new
				setValue: value;
				"We assume Message prints its keywords and arguments interleaved.
				 e.g. that (Message selector: #between:and: arguments: #(0 1)) printString = 'between: 0 and: 1'"
				comment: (receiver isLeaf
								ifTrue: [receiver printString]
								ifFalse: ['(', receiver printString, ')']),
							' ',
							(Message selector: selector arguments: (arguments collect: [:ea| ea value])) printString;
				yourself]].
	^self shallowCopy
		receiver: newReceiver;
		arguments: newArguments;
		yourself
		
]

{ #category : #transformations }
TSendNode >> bindVariablesIn: aDictionary [

	receiver := receiver bindVariablesIn: aDictionary.
	arguments := arguments collect: [ :a | a bindVariablesIn: aDictionary ].
]

{ #category : #'C code generation' }
TSendNode >> emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen [
	"Emit the receiver in a form that can be passed as an argument."

	"If the selector is a built-in construct, translate it and return"
	(aCodeGen emitBuiltinConstructAsArgumentFor: self on: aStream level: level) ifFalse:
		["If it is a pointer dereference generate it"
		(self emitCCodeAsFieldReferenceOn: aStream level: level generator: aCodeGen) ifFalse:
			["Otherwise generate the vanilla C function call."
			 self emitCCodeAsFunctionCallOn: aStream level: level generator: aCodeGen]]
]

{ #category : #'C code generation' }
TSendNode >> emitCCodeAsExpressionOn: aStream level: level generator: aCodeGen [
	^self emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen
]

{ #category : #'C code generation' }
TSendNode >> emitCCodeAsFieldReferenceOn: aStream level: level generator: aCodeGen [
	"If appropriate, translate this message send as a pointer dereference"

	(self isStructSend: aCodeGen) ifFalse:
		[^false].

	aStream nextPut: $(.
	receiver  emitCCodeAsExpressionOn: aStream level: 0 generator: aCodeGen.
	(receiver structTargetKind: aCodeGen) caseOf: {
		[#pointer] -> [aStream nextPut: $-; nextPut: $>].
		[#struct] -> [aStream nextPut: $.] }.
	aStream nextPutAll: (aCodeGen cFunctionNameFor: selector).
	arguments isEmpty ifFalse:
		[self assert: arguments size = 1.
		 aStream nextPutAll: ' = '.
		 arguments first emitCCodeAsExpressionOn: aStream level: level generator: aCodeGen].
	aStream nextPut: $).
	^true
]

{ #category : #'C code generation' }
TSendNode >> emitCCodeAsFunctionCallOn: aStream level: level generator: aCodeGen [

	"Translate this message send into a C function call"
	"Special case for pluggable modules. Replace messages to interpreterProxy
	 by interpreterProxy->message(..) if the message is not builtin"
	(aCodeGen messageReceiverIsInterpreterProxy: self) ifTrue:
		[(aCodeGen noteUsedPluginFunction: selector) ifTrue:
			[aStream nextPutAll: 'interpreterProxy->']].
	"Translate this message send into a C function call."
	aStream nextPutAll: (aCodeGen cFunctionNameFor: selector); nextPut: $(.
	"Only include the receiver as the first argument in certain cases.
	 The receiver is always included if it is an expression.
	 If it is a variable:
		 If the vmClass says it is an implicit variable, don't include it.
		 If the variable is 'self' and the method being called is not in
		 the method set (i.e. it is some external code), don't include it."
	(self shouldExcludeReceiverAsFirstArgument: aCodeGen) ifFalse:
		[receiver emitCCodeOn: aStream level: level generator: aCodeGen.
		 arguments isEmpty ifFalse:
			[aStream nextPutAll: ', ']].
	arguments
		do: [ :arg| arg emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen]
		separatedBy: [aStream nextPut: $,; space].
	aStream nextPut: $)
]

{ #category : #'C code generation' }
TSendNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	"Emit the receiver as a statement."

	"If the selector is a built-in construct, translate it and return"
	(aCodeGen emitBuiltinConstructFor: self on: aStream level: level) ifFalse:
		["If it is a pointer dereference generate it"
		(self emitCCodeAsFieldReferenceOn: aStream level: level generator: aCodeGen) ifFalse:
			["Otherwise generate the vanilla C function call."
			 self emitCCodeAsFunctionCallOn: aStream level: level generator: aCodeGen]]
]

{ #category : #testing }
TSendNode >> endsWithReturn [
	^self isReturningIf
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

{ #category : #testing }
TSendNode >> isLiteralArrayDeclaration [
	^selector == #cCoerce:to:
	  and: [arguments first isConstant
	  and: [arguments first value isLiteral
	  and: [arguments first value isCollection]]]
]

{ #category : #testing }
TSendNode >> isNonNullCCode [
	^(#(cCode: cCode:inSmalltalk:) includes: selector)
	   and: [arguments first isConstant
	   and: [arguments first value notEmpty]]
]

{ #category : #testing }
TSendNode >> isPreprocessorDirective [
	^#(cPreprocessorDirective: cppIf:ifTrue:ifFalse: cppIf:ifTrue:) includes: selector
]

{ #category : #testing }
TSendNode >> isReturningIf [
	^(#(ifTrue:ifFalse: ifFalse:ifTrue:) includes: selector)
	   and: [arguments allSatisfy: [:arg| arg endsWithReturn]]
]

{ #category : #'C code generation' }
TSendNode >> isSelfReference: varNode [
	^(varNode name beginsWith: 'self')
	  and: [varNode name = 'self' or: [varNode name beginsWith: 'self_in_']]
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
		foo bar => foo.bar
		foo bar: expr => foo->bar = expr
		foo bar: expr => foo.bar = expr
	 depending on whether foo is a struct or a pointer to a struct,
	 but only if both foo is a struct type and bar is a field accessor.
	 The tricky cases are self-sends within struct class methods.  Here we need to
	 distinguish between self-sends of ordinary methods from self sends of accessors."
	^arguments size <= 1
	   and: [(receiver structTargetKind: aCodeGen) notNil
	   and: [(aCodeGen methodNamed: selector)
				ifNil: [false]
				ifNotNil: [:method| method isStructAccessor]]]
]

{ #category : #testing }
TSendNode >> isValueExpansion [
	"Answer if the receiver is of the form literalBlock value[: arg]"
	^receiver isStmtList
	 and: [selector keywords allSatisfy: [:k| #('value' 'value:') includes: k]]
]

{ #category : #testing }
TSendNode >> needsTrailingSemicolon [
	"Answer if, when emitted as a statement (in particular in a TStmtList), the
	 receiver needs a trailing semicolon.  Preprocessor directives and special expansions do not."
	^(self isPreprocessorDirective
	   or: [self isValueExpansion
	   or: [selector == #expandDereferenceInterpreterProxyFunctionTable]]) not
]

{ #category : #enumerating }
TSendNode >> nodesDo: aBlock [
	"Apply aBlock to all nodes in the receiver.
	 N.B. This is assumed to be bottom-up, leaves first."
	receiver nodesDo: aBlock.
	arguments do: [ :arg | arg nodesDo: aBlock ].
	aBlock value: self
]

{ #category : #enumerating }
TSendNode >> nodesDo: aBlock unless: cautionaryBlock [

	(cautionaryBlock value: self) ifTrue: [^self].
	receiver nodesDo: aBlock unless: cautionaryBlock.
	arguments do: [ :arg | arg nodesDo: aBlock unless: cautionaryBlock].
	aBlock value: self.
]

{ #category : #copying }
TSendNode >> postCopy [

	receiver := receiver copy.
	arguments := (arguments collect: [ :arg | arg copy ])
]

{ #category : #printing }
TSendNode >> printOn: aStream level: level [
	| possiblyParenthesize |
	possiblyParenthesize :=
		[:node :newLevel|
		(node isSend
		 and: [node selector precedence >= 3]) ifTrue:
			[aStream nextPut: $(].
		node printOn: aStream level: newLevel.
		(node isSend
		 and: [node selector precedence >= 3]) ifTrue:
			[aStream nextPut: $)]].

	possiblyParenthesize value: receiver value: level.
	arguments size = 0 ifTrue:
		[aStream space; nextPutAll: selector.
		^self].
	selector keywords with: (arguments first: selector numArgs) do:
		[:keyword :arg |
		aStream space; nextPutAll: keyword; space.
		possiblyParenthesize value: arg value: level + 1]
]

{ #category : #accessing }
TSendNode >> receiver [

	^receiver
]

{ #category : #private }
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
		 the method set (i.e. it is some external code), don't include it.
		 If it is a struct send of something the vm says is an implicit variable, don't include it."
	| m |
	(receiver isSend
	 and: [receiver receiver isVariable
	 and: [self isSelfReference: receiver receiver]]) ifTrue:
		[^aCodeGen isNonArgumentImplicitReceiverVariableName: receiver selector].

	^receiver isVariable
	    and: [(aCodeGen isNonArgumentImplicitReceiverVariableName: receiver name)
		    or: [(self isSelfReference: receiver)
			    and: [(m := aCodeGen methodNamed: selector) isNil
					or: [m typeForSelf == #implicit]]]]
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

{ #category : #testing }
TSendNode >> structTargetKind: aCodeGen [
	"Answer if the recever evaluates to a struct or struct pointer
	 and hence can be dereferenced using . or ->.  Answer any of
	 #struct #pointer or nil.  Right now we don't need or support
	 structure return so this method answers either #pointer or nil."
	selector == #cCoerceSimple:to: ifTrue:
		[^(VMStructType isTypePointerToStruct: arguments last value) ifTrue:
			[#pointer]].

	^(aCodeGen selectorReturnsPointerToStruct: selector) ifTrue:
		[#pointer]
]
