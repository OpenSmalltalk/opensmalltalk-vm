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

{ #category : #accessing }
TInlineNode >> copyTree [

	^self class new
		method: method copy
]

{ #category : #'C code generation' }
TInlineNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	method emitInlineOn: aStream level: level generator: aCodeGen.

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
	method parseTree nodesDo: aBlock.
	aBlock value: self.
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
