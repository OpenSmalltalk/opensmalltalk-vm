Class {
	#name : #TInlineNode,
	#superclass : #TParseNode,
	#instVars : [
		'method'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #transformations }
TInlineNode >> bindVariableUsesIn: aDictionary [
	method := method bindVariableUsesIn: aDictionary.

]

{ #category : #transformations }
TInlineNode >> bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen [
	"Answer either the receiver, if it contains no references to the given variables, or a new node with the given variables rebound."
	| newMethod |
	newMethod := method bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen.
	^newMethod = method
		ifTrue: [self]
		ifFalse: [self shallowCopy
					method: newMethod;
					yourself]
]

{ #category : #'C code generation' }
TInlineNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	method emitInlineOn: aStream level: level generator: aCodeGen.

]

{ #category : #testing }
TInlineNode >> isInline [
	^true
]

{ #category : #accessing }
TInlineNode >> method [
	^method
]

{ #category : #accessing }
TInlineNode >> method: aTMethod [
	method := aTMethod
]

{ #category : #enumerating }
TInlineNode >> nodesDo: aBlock [
	"Apply aBlock to all nodes in the receiver.
	 N.B. This is assumed to be bottom-up, leaves first."
	method parseTree nodesDo: aBlock.
	aBlock value: self
]

{ #category : #enumerating }
TInlineNode >> nodesDo: aBlock parent: parent [
	"Apply aBlock to all nodes in the receiver with each node's parent.
	 N.B. This is assumed to be bottom-up, leaves first."
	method parseTree nodesDo: aBlock parent: self.
	aBlock value: self value: parent
]

{ #category : #enumerating }
TInlineNode >> nodesDo: aBlock parent: parent unless: cautionaryBlock [

	(cautionaryBlock value: self value: parent) ifTrue: [^self].
	method parseTree nodesDo: aBlock parent: self unless: cautionaryBlock.
	aBlock value: self value: parent
]

{ #category : #enumerating }
TInlineNode >> nodesDo: aBlock unless: cautionaryBlock [

	(cautionaryBlock value: self) ifTrue: [^self].
	method parseTree nodesDo: aBlock unless: cautionaryBlock.
	aBlock value: self.
]

{ #category : #copying }
TInlineNode >> postCopy [

	method := method copy
]

{ #category : #printing }
TInlineNode >> printOn: aStream level: anInteger [
	method parseTree printOn: aStream level: anInteger
]

{ #category : #transformations }
TInlineNode >> replaceNodesIn: map [
	^map at: self ifAbsent: [
		method replaceNodesIn: map.
		self]
]

{ #category : #inlining }
TInlineNode >> shouldExpand [
	^method extractExpandCaseDirective
]

{ #category : #'type inference' }
TInlineNode >> typeOrNilFrom: aCodeGenerator in: aTMethod [
	^method returnType
]
