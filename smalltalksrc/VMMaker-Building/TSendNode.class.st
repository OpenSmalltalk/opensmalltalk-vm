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

{ #category : #'as yet unclassified' }
TSendNode >> args [

	^arguments
]

{ #category : #'as yet unclassified' }
TSendNode >> bindVariableUsesIn: aDictionary [

	receiver _ receiver bindVariableUsesIn: aDictionary.
	arguments _ arguments collect: [ :a | a bindVariableUsesIn: aDictionary ].
]

{ #category : #'as yet unclassified' }
TSendNode >> bindVariablesIn: aDictionary [

	receiver _ receiver bindVariablesIn: aDictionary.
	arguments _ arguments collect: [ :a | a bindVariablesIn: aDictionary ].
]

{ #category : #'as yet unclassified' }
TSendNode >> copyTree [

	^self class new
		setSelector: selector
		receiver: receiver copyTree
		arguments: (arguments collect: [ :arg | arg copyTree ])
		isBuiltInOp: isBuiltinOperator
]

{ #category : #'as yet unclassified' }
TSendNode >> emitCCodeOn: aStream level: level generator: aCodeGen [

	"If the selector is a built-in construct, translate it and return"
	(aCodeGen emitBuiltinConstructFor: self on: aStream level: level) ifTrue: [ ^self ].

	"Special case for pluggable modules. Replace messages to interpreterProxy
	by interpreterProxy->message(..) if the message is not builtin"
	(aCodeGen isGeneratingPluginCode and:[
		receiver isVariable and:[
			'interpreterProxy' = receiver name and:[
				self isBuiltinOperator not]]]) 
		ifTrue:[aStream nextPutAll:'interpreterProxy->'].
	"Translate this message send into a C function call."
	aStream nextPutAll: (aCodeGen cFunctionNameFor: selector), '('.
	(receiver isVariable and:
	 [('self' = receiver name) or: ['interpreterProxy' = receiver name]]) ifFalse: [
		"self is omitted from the arguments list of the generated call"
		"Note: special case for translated BitBltSimulator--also omit
		 the receiver if this is a send to the variable 'interpreterProxy'"
		receiver emitCCodeOn: aStream level: level generator: aCodeGen.
		arguments isEmpty ifFalse: [ aStream nextPutAll: ', ' ].
	].
	1 to: arguments size do: [ :i |
		(arguments at: i) emitCCodeOn: aStream level: level generator: aCodeGen.
		i < arguments size ifTrue: [ aStream nextPutAll: ', ' ].
	].
	aStream nextPutAll: ')'.
]

{ #category : #'as yet unclassified' }
TSendNode >> inlineMethodsUsing: aDictionary [

	arguments _ arguments collect: [ :arg |
		arg inlineMethodsUsing: aDictionary.
	].
	"xxx inline this message if it is in the dictionary xxx"
]

{ #category : #'as yet unclassified' }
TSendNode >> isAssertion [
	^(selector beginsWith: 'assert') or: [selector beginsWith: 'verify']
]

{ #category : #'as yet unclassified' }
TSendNode >> isBuiltinOperator [

	^ isBuiltinOperator
]

{ #category : #'as yet unclassified' }
TSendNode >> isBuiltinOperator: builtinFlag [

	isBuiltinOperator _ builtinFlag.
]

{ #category : #'as yet unclassified' }
TSendNode >> isSend [

	^true
]

{ #category : #'as yet unclassified' }
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
	keywords _ selector keywords.
	1 to: keywords size do: [ :i |
		aStream space.
		aStream nextPutAll: (keywords at: i); space.
		(arguments at: i) printOn: aStream level: level + 1.
	].
]

{ #category : #'as yet unclassified' }
TSendNode >> receiver [

	^receiver
]

{ #category : #'as yet unclassified' }
TSendNode >> receiver: aNode [

	receiver _ aNode.
]

{ #category : #'as yet unclassified' }
TSendNode >> removeAssertions [
	receiver removeAssertions.
	arguments do: [:arg | arg removeAssertions].
]

{ #category : #'as yet unclassified' }
TSendNode >> replaceNodesIn: aDictionary [

	^aDictionary at: self ifAbsent: [
		receiver _ receiver replaceNodesIn: aDictionary.
		arguments _ arguments collect: [ :a | a replaceNodesIn: aDictionary ].
		self]
]

{ #category : #'as yet unclassified' }
TSendNode >> selector [

	^selector
]

{ #category : #'as yet unclassified' }
TSendNode >> setSelector: aSymbol receiver: rcvrNode arguments: argList [

	selector _ aSymbol.
	receiver _ rcvrNode.
	arguments _ argList asArray.
	isBuiltinOperator _ false.
]

{ #category : #'as yet unclassified' }
TSendNode >> setSelector: aSymbol receiver: rcvrNode arguments: argList isBuiltInOp: builtinFlag [

	selector _ aSymbol.
	receiver _ rcvrNode.
	arguments _ argList asArray.
	isBuiltinOperator _ builtinFlag.
]
