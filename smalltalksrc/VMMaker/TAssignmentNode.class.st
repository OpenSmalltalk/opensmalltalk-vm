Class {
	#name : #TAssignmentNode,
	#superclass : #TParseNode,
	#instVars : [
		'variable',
		'expression'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #inlining }
TAssignmentNode >> bindVariableUsesIn: aDictionary [
	"Do NOT bind the variable on the left-hand-side of an assignment statement."
	"was bindVariablesIn:"
	expression _ expression bindVariableUsesIn: aDictionary.

]

{ #category : #'as yet unclassified' }
TAssignmentNode >> bindVariablesIn: aDictionary [

	variable _ variable bindVariablesIn: aDictionary.
	expression _ expression bindVariablesIn: aDictionary.
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> copyTree [

	^self class new
		setVariable: variable copyTree
		expression: expression copyTree
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> emitCCodeOn: aStream level: level generator: aCodeGen [

	| sel |
	self isVariableUpdatingAssignment ifTrue: [
		variable emitCCodeOn: aStream level: level generator: aCodeGen.
		sel _ expression selector.
		sel = #+
			ifTrue: [aStream nextPutAll: ' += ']
			ifFalse: [aStream nextPutAll: ' -= '].
			expression args first emitCCodeOn: aStream level: level generator: aCodeGen.
	] ifFalse: [
		variable emitCCodeOn: aStream level: level generator: aCodeGen.
		aStream nextPutAll: ' = '.
		expression emitCCodeOn: aStream level: level generator: aCodeGen.
	].
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> expression [

	^expression
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> inlineMethodsUsing: aDictionary [

	variable inlineMethodsUsing: aDictionary.
	expression inlineMethodsUsing: aDictionary.
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> isAssignment [

	^true
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> isVariableUpdatingAssignment [
	"Return true if this assignment statement is of one of the forms:
		var = var + ...
		var = var - ...
	Such assignments statements can exploit the C updating assignment operators. For example, 'x += 4' can be generated instead of 'x = x + 4'. This produces better code under some C compilers, most notably the CodeWarrior 68K compiler."

	| sel |
	(expression isSend and: [expression receiver isVariable]) ifFalse: [^ false].
	sel _ expression selector.
	^ (expression receiver name = variable name) and: [(sel = #+) or: [sel = #-]]
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> nodesDo: aBlock [

	variable nodesDo: aBlock.
	expression nodesDo: aBlock.
	aBlock value: self.
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> printOn: aStream level: level [

	variable printOn: aStream level: level.
	aStream nextPutAll: ' _ '.
	expression printOn: aStream level: level + 2.
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> removeAssertions [

	expression removeAssertions
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> replaceNodesIn: aDictionary [

	^aDictionary at: self ifAbsent: [
		variable _ variable replaceNodesIn: aDictionary.
		expression _ expression replaceNodesIn: aDictionary.
		self]
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> setVariable: varNode expression: expressionNode [

	variable _ varNode.
	expression _ expressionNode.
]

{ #category : #'as yet unclassified' }
TAssignmentNode >> variable [

	^variable
]
