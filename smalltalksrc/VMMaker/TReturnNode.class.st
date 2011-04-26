Class {
	#name : #TReturnNode,
	#superclass : #TParseNode,
	#instVars : [
		'expression'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #transformations }
TReturnNode >> bindVariableUsesIn: aDictionary [

	expression := expression bindVariableUsesIn: aDictionary.
]

{ #category : #transformations }
TReturnNode >> bindVariablesIn: aDictionary [

	expression := expression bindVariablesIn: aDictionary.
]

{ #category : #'C code generation' }
TReturnNode >> emitCCodeOn: aStream level: level generator: aCodeGen [

	(expression isSwitch
	 or: [expression isCaseStmt]) ifTrue:
		[^expression emitCCodeOn: aStream addToEndOfCases: self level: level generator: aCodeGen].

	('void' = aCodeGen currentMethod returnType) ifTrue: [
		"If the function is void, don't say 'return x' instead say ' x; return' "
		expression isLeaf ifFalse: [
			expression emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen.	
			aStream nextPutAll: ';'; space.
		].
		aStream nextPutAll: 'return'.
	] ifFalse: [
		aStream nextPutAll: 'return'.
		aStream space.
		expression emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen
	].
]

{ #category : #testing }
TReturnNode >> endsWithReturn [

	^true
]

{ #category : #accessing }
TReturnNode >> expression [

	^expression
]

{ #category : #testing }
TReturnNode >> isReturn [

	^true
]

{ #category : #enumerating }
TReturnNode >> nodesDo: aBlock [

	expression nodesDo: aBlock.
	aBlock value: self.
]

{ #category : #enumerating }
TReturnNode >> nodesDo: aBlock unless: cautionaryBlock [

	(cautionaryBlock value: self) ifTrue: [^self].
	expression nodesDo: aBlock unless: cautionaryBlock.
	aBlock value: self.
]

{ #category : #copying }
TReturnNode >> postCopy [

	expression := expression copy
]

{ #category : #'C code generation' }
TReturnNode >> prependCCodeOn: aStream level: level generator: aCCodeGenerator [ 
	aStream nextPutAll: 'return '
]

{ #category : #printing }
TReturnNode >> printOn: aStream level: level [

	aStream nextPut: $^.
	expression printOn: aStream level: level.
]

{ #category : #transformations }
TReturnNode >> removeAssertions [
	expression removeAssertions
]

{ #category : #transformations }
TReturnNode >> replaceNodesIn: aDictionary [

	^aDictionary at: self ifAbsent: [
		expression := expression replaceNodesIn: aDictionary.
		self]
]

{ #category : #accessing }
TReturnNode >> setExpression: aNode [

	expression := aNode.
]
