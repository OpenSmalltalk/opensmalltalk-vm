Class {
	#name : #TReturnNode,
	#superclass : #TParseNode,
	#instVars : [
		'expression'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'as yet unclassified' }
TReturnNode >> bindVariableUsesIn: aDictionary [

	expression := expression bindVariableUsesIn: aDictionary.
]

{ #category : #'as yet unclassified' }
TReturnNode >> bindVariablesIn: aDictionary [

	expression := expression bindVariablesIn: aDictionary.
]

{ #category : #'as yet unclassified' }
TReturnNode >> copyTree [

	^self class new
		setExpression: expression copyTree
]

{ #category : #'as yet unclassified' }
TReturnNode >> emitCCodeOn: aStream level: level generator: aCodeGen [

	aStream nextPutAll: 'return '.
	expression emitCCodeOn: aStream level: level generator: aCodeGen.
]

{ #category : #'as yet unclassified' }
TReturnNode >> expression [

	^expression
]

{ #category : #'as yet unclassified' }
TReturnNode >> inlineMethodsUsing: aDictionary [

	expression := expression inlineMethodsUsing: aDictionary.
]

{ #category : #'as yet unclassified' }
TReturnNode >> isReturn [

	^true
]

{ #category : #'as yet unclassified' }
TReturnNode >> nodesDo: aBlock [

	expression nodesDo: aBlock.
	aBlock value: self.
]

{ #category : #'as yet unclassified' }
TReturnNode >> printOn: aStream level: level [

	aStream nextPut: $^.
	expression printOn: aStream level: level.
]

{ #category : #'as yet unclassified' }
TReturnNode >> removeAssertions [
	expression removeAssertions
]

{ #category : #'as yet unclassified' }
TReturnNode >> replaceNodesIn: aDictionary [

	^aDictionary at: self ifAbsent: [
		expression := expression replaceNodesIn: aDictionary.
		self]
]

{ #category : #'as yet unclassified' }
TReturnNode >> setExpression: aNode [

	expression := aNode.
]
