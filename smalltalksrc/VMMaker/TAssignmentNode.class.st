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
TAssignmentNode >> bindVariablesIn: aDictionary [

	variable := variable bindVariablesIn: aDictionary.
	expression := expression bindVariablesIn: aDictionary.
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> copyTree [

	^self class new
		setVariable: variable copyTree
		expression: expression copyTree
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

{ #category : #accessing }
TAssignmentNode >> expression [

	^expression
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> inlineMethodsUsing: aDictionary [

	variable inlineMethodsUsing: aDictionary.
	expression inlineMethodsUsing: aDictionary.
]

{ #category : #testing }
TAssignmentNode >> isAssignment [

	^true
]

{ #category : #testing }
TAssignmentNode >> isStructTarget: aCodeGen [
	"Answer if the recever evaluates to a struct pointer
	 and hence can be dereferenced using ->"
	^variable isStructTarget: aCodeGen
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

	variable nodesDo: aBlock.
	expression nodesDo: aBlock.
	aBlock value: self.
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
TAssignmentNode >> setVariable: varNode expression: expressionNode [

	variable := varNode.
	expression := expressionNode.
]

{ #category : #accessing }
TAssignmentNode >> variable [

	^variable
]
