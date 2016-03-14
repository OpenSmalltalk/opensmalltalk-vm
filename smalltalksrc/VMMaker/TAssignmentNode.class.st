Class {
	#name : #TAssignmentNode,
	#superclass : #TParseNode,
	#instVars : [
		'variable',
		'expression'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #transformations }
TAssignmentNode >> bindVariableUsesIn: aDictionary [
	"Do NOT bind the variable on the left-hand-side of an assignment statement."
	"was bindVariablesIn:"
	expression := expression bindVariableUsesIn: aDictionary.

]

{ #category : #transformations }
TAssignmentNode >> bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen [
	"Answer either the receiver, if it contains no references to the given variables, or a new node with the given variables rebound."
	"Do NOT bind the variable on the left-hand-side of an assignment statement."
	| boundExpression |
	boundExpression := expression bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen.
	^boundExpression == expression
		ifTrue: [self]
		ifFalse: [self shallowCopy
					setVariable: variable expression: boundExpression;
					yourself]
]

{ #category : #transformations }
TAssignmentNode >> bindVariablesIn: aDictionary [

	variable := variable bindVariablesIn: aDictionary.
	expression := expression bindVariablesIn: aDictionary.
]

{ #category : #'C code generation' }
TAssignmentNode >> emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen [
	aStream nextPut: $(.
	self emitCCodeOn: aStream level: level generator: aCodeGen.
	aStream nextPut: $)
]

{ #category : #'C code generation' }
TAssignmentNode >> emitCCodeAsExpressionOn: aStream level: level generator: aCodeGen [
	aStream nextPut: $(.
	self emitCCodeOn: aStream level: level generator: aCodeGen.
	aStream nextPut: $)
]

{ #category : #'C code generation' }
TAssignmentNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	expression isSwitch ifTrue:
		[^expression emitCCodeOn: aStream addToEndOfCases: self level: level generator: aCodeGen].
	expression isLiteralArrayDeclaration ifTrue:
		[^self emitLiteralArrayDeclarationOn: aStream level: level generator: aCodeGen].
	(expression isSend and: [expression isValueExpansion]) ifTrue:
		[^self emitValueExpansionOn: aStream level: level generator: aCodeGen].
	(expression isStmtList and: [expression statements size > 1]) ifTrue:
		[^self emitStatementListExpansion: expression on: aStream level: level generator: aCodeGen].
	variable emitCCodeOn: aStream level: level generator: aCodeGen.
	self isVariableUpdatingAssignment
		ifTrue:
			[aStream
				space;
				nextPutAll: expression selector;	"+ or -"
				nextPut: $=;
				space.
			expression args first emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen]
		ifFalse:
			[aStream space; nextPut: $=; space.
			 expression emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen]
]

{ #category : #'C code generation' }
TAssignmentNode >> emitLiteralArrayDeclarationOn: aStream level: level generator: aCCodeGen [
	| type |
	type := expression args last value.
	self assert: type last = $*.
	aStream
		crtab: level;
		nextPutAll: '{ static ';
		nextPutAll: (aCCodeGen
						arrayInitializerCalled: 'aLiteralArray'
						for: expression args first value
						sizeString: nil
						type: type allButLast) withBlanksTrimmed;
		nextPut: $;;
		crtab: level + 1;
		nextPutAll: variable name;
		nextPutAll: ' = aLiteralArray;';
		crtab: level;
		nextPut: $};
		cr
]

{ #category : #'C code generation' }
TAssignmentNode >> emitStatementListExpansion: stmtList on: aStream level: level generator: aCodeGen [
	stmtList statements last = variable ifTrue:
		[^expression emitCCodeOn: aStream level: level generator: aCodeGen].
	stmtList copy
		assignLastExpressionTo: variable;
		emitCCodeOn: aStream level: level generator: aCodeGen
]

{ #category : #'C code generation' }
TAssignmentNode >> emitValueExpansionOn: aStream level: level generator: aCodeGen [
	| stmtList lastStmt copy |
	self assert: (expression isSend and: [expression isValueExpansion]).
	stmtList := expression receiver.
	lastStmt := stmtList statements last.
	lastStmt = variable ifTrue:
		[^expression emitCCodeOn: aStream level: level generator: aCodeGen].
	copy := stmtList copy.
	copy statements
		at: stmtList statements size
		put: (TAssignmentNode new
				setVariable: variable
				expression: lastStmt).
	(TSendNode new
			setSelector: expression selector
			receiver: copy
			arguments: expression args)
		emitCCodeOn: aStream level: level generator: aCodeGen.
]

{ #category : #accessing }
TAssignmentNode >> expression [

	^expression
]

{ #category : #testing }
TAssignmentNode >> isAssignment [

	^true
]

{ #category : #testing }
TAssignmentNode >> isSameAs: aTParseNode [
	^aTParseNode isAssignment
	 and: [(variable isSameAs: aTParseNode variable)
	 and: [expression isSameAs: aTParseNode expression]]
]

{ #category : #testing }
TAssignmentNode >> isVariableUpdatingAssignment [
	"Return true if this assignment statement is of one of the forms:
		var = var + ...
		var = var - ...
	Such assignments statements can exploit the C updating assignment operators. For example, 'x += 4' can be generated instead of 'x = x + 4'. This produces better code under some C compilers, most notably the CodeWarrior 68K compiler."

	| sel |
	(expression isSend and: [expression receiver isVariable]) ifFalse: [^ false].
	sel := expression selector.
	^ (expression receiver name = variable name) and: [(sel = #+) or: [sel = #-]]
]

{ #category : #enumerating }
TAssignmentNode >> nodesDo: aBlock [
	"Apply aBlock to all nodes in the receiver.
	 N.B. This is assumed to be bottom-up, leaves first."
	variable nodesDo: aBlock.
	expression nodesDo: aBlock.
	aBlock value: self
]

{ #category : #enumerating }
TAssignmentNode >> nodesDo: aBlock parent: parent [
	"Apply aBlock to all nodes in the receiver with each node's parent.
	 N.B. This is assumed to be bottom-up, leaves first."
	variable nodesDo: aBlock parent: self.
	expression nodesDo: aBlock parent: self.
	aBlock value: self value: parent
]

{ #category : #enumerating }
TAssignmentNode >> nodesDo: aBlock parent: parent unless: cautionaryBlock [

	(cautionaryBlock value: self value: parent) ifTrue: [^self].
	variable nodesDo: aBlock parent: self unless: cautionaryBlock.
	expression nodesDo: aBlock parent: self unless: cautionaryBlock.
	aBlock value: self value: parent
]

{ #category : #enumerating }
TAssignmentNode >> nodesDo: aBlock unless: cautionaryBlock [

	(cautionaryBlock value: self) ifTrue: [^self].
	variable nodesDo: aBlock unless: cautionaryBlock.
	expression nodesDo: aBlock unless: cautionaryBlock.
	aBlock value: self.
]

{ #category : #copying }
TAssignmentNode >> postCopy [

	variable := variable copy.
	expression := expression copy
]

{ #category : #'C code generation' }
TAssignmentNode >> prependCCodeOn: aStream level: level generator: aCodeGen [
	variable emitCCodeOn: aStream level: level generator: aCodeGen.
	aStream
		space;
		nextPutAll: (self isVariableUpdatingAssignment
						ifTrue: [expression selector "+ or -"]
						ifFalse: ['']);
		nextPut: $=;
		space
]

{ #category : #printing }
TAssignmentNode >> printOn: aStream level: level [

	variable printOn: aStream level: level.
	aStream nextPutAll: ' := '.
	expression printOn: aStream level: level + 2.
]

{ #category : #transformations }
TAssignmentNode >> removeAssertions [

	expression removeAssertions
]

{ #category : #transformations }
TAssignmentNode >> replaceNodesIn: aDictionary [

	^aDictionary at: self ifAbsent: [
		variable := variable replaceNodesIn: aDictionary.
		expression := expression replaceNodesIn: aDictionary.
		self]
]

{ #category : #accessing }
TAssignmentNode >> setExpression: expressionNode [

	expression := expressionNode
]

{ #category : #accessing }
TAssignmentNode >> setVariable: varNode expression: expressionNode [
	self assert: (expressionNode isGoTo or: [expressionNode isLabel]) not.
	variable := varNode.
	expression := expressionNode.
]

{ #category : #testing }
TAssignmentNode >> structTargetKindIn: aCodeGen [
	"Answer if the recever evaluates to a struct or struct pointer
	 and hence can be dereferenced using . or ->.  Answer any of
	 #struct #pointer or nil"
	^variable structTargetKindIn: aCodeGen
]

{ #category : #accessing }
TAssignmentNode >> variable [

	^variable
]

{ #category : #accessing }
TAssignmentNode >> variableNameOrNil [
	^variable variableNameOrNil
]
