Class {
	#name : #TInlineNode,
	#superclass : #TParseNode,
	#instVars : [
		'method'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #accessing }
TInlineNode >> bindVariableUsesIn: aDictionary [
	method _ method bindVariableUsesIn: aDictionary.

]

{ #category : #accessing }
TInlineNode >> copyTree [

	^self class new
		method: method copy
]

{ #category : #accessing }
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

{ #category : #accessing }
TInlineNode >> nodesDo: aBlock [
	method parseTree nodesDo: aBlock.
	aBlock value: self.
]

{ #category : #accessing }
TInlineNode >> printOn: aStream level: anInteger [
	method parseTree printOn: aStream level: anInteger
]

{ #category : #accessing }
TInlineNode >> replaceNodesIn: map [
	^map at: self ifAbsent: [
		method replaceNodesIn: map.
		self]
]
