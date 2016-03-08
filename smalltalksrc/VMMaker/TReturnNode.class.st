Class {
	#name : #TReturnNode,
	#superclass : #TParseNode,
	#instVars : [
		'expression'
	],
	#category : 'VMMaker-Translation to C'
}

{ #category : #transformations }
TReturnNode >> bindVariableUsesIn: aDictionary [

	expression := expression bindVariableUsesIn: aDictionary.
]

{ #category : #transformations }
TReturnNode >> bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen [
	"Answer either the receiver, if it contains no references to the given variables, or a new node with the given variables rebound."
	| newExpression |
	newExpression := expression bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen.
	^newExpression = expression
		ifTrue: [self]
		ifFalse:
			[self shallowCopy
				setExpression: newExpression;
				yourself]
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

	(expression isSend and: [expression isValueExpansion]) ifTrue:
		[^self emitValueExpansionOn: aStream level: level generator: aCodeGen].

	'void' = aCodeGen currentMethod returnType ifTrue: "If the function is void, don't say 'return x' instead say ' x; return' "
		[expression isLeaf ifFalse:
			[expression emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen.	
			 aStream nextPut: $;; crtab: level].
		 aStream nextPutAll: 'return'.
		 ^self].
	aStream nextPutAll: 'return '.
	expression
		emitCCodeAsArgumentOn: aStream
		level: (expression isStmtList ifTrue: [level + 1] ifFalse: [level])
		generator: aCodeGen
]

{ #category : #'C code generation' }
TReturnNode >> emitValueExpansionOn: aStream level: level generator: aCodeGen [
	| stmtList lastStmt copy |
	self assert: (expression isSend and: [expression isValueExpansion]).
	stmtList := expression receiver.
	lastStmt := stmtList statements last.
	lastStmt isReturn ifTrue:
		[^expression emitCCodeOn: aStream level: level generator: aCodeGen].
	copy := stmtList copy.
	copy statements
		at: stmtList statements size
		put: (TReturnNode new setExpression: lastStmt).
	copy emitCCodeOn: aStream level: level generator: aCodeGen
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
	"Apply aBlock to all nodes in the receiver.
	 N.B. This is assumed to be bottom-up, leaves first."
	expression nodesDo: aBlock.
	aBlock value: self
]

{ #category : #enumerating }
TReturnNode >> nodesDo: aBlock parent: parent [
	"Apply aBlock to all nodes in the receiver with each node's parent.
	 N.B. This is assumed to be bottom-up, leaves first."
	expression nodesDo: aBlock parent: self.
	aBlock value: self value: parent
]

{ #category : #enumerating }
TReturnNode >> nodesDo: aBlock parent: parent unless: cautionaryBlock [

	(cautionaryBlock value: self value: parent) ifTrue: [^self].
	expression nodesDo: aBlock parent: self unless: cautionaryBlock.
	aBlock value: self value: parent
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
