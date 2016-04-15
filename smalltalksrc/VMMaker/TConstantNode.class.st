Class {
	#name : #TConstantNode,
	#superclass : #TParseNode,
	#instVars : [
		'value'
	],
	#category : 'VMMaker-Translation to C'
}

{ #category : #testing }
TConstantNode >> constantNumbericValueOrNil [

	^value isNumber ifTrue: [value]
]

{ #category : #'C code generation' }
TConstantNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C literal."
	aStream nextPutAll: (aCodeGen cLiteralFor: value).
	comment ifNotNil:
		[aStream
			nextPutAll: ' /* ';
			nextPutAll: comment;
			nextPutAll: ' */']
]

{ #category : #testing }
TConstantNode >> hasSideEffect [
	"Answer if the parse tree rooted at this node has a side-effect or not."
	^false
]

{ #category : #testing }
TConstantNode >> isConstant [

	^true
]

{ #category : #testing }
TConstantNode >> isLeaf [

	^true
]

{ #category : #comparing }
TConstantNode >> isSameAs: aTParseNode [
	^aTParseNode isConstant
	 and: [value class == aTParseNode value class
	 and: [value = aTParseNode value]]
]

{ #category : #accessing }
TConstantNode >> name [
	^''
]

{ #category : #accessing }
TConstantNode >> nameOrValue [

	^value
]

{ #category : #enumerating }
TConstantNode >> nodesDo: aBlock parent: parent [
	"Apply aBlock to all nodes in the receiver with each node's parent.
	 N.B. This is assumed to be bottom-up, leaves first."
	aBlock value: self value: parent
]

{ #category : #printing }
TConstantNode >> printOn: aStream level: level [
	value isSymbol
		ifTrue: [aStream nextPutAll: (value copyWithout: $:)]
		ifFalse: [value storeOn: aStream]
]

{ #category : #accessing }
TConstantNode >> setValue: anObject [

	value := anObject.
]

{ #category : #accessing }
TConstantNode >> value [

	^value
]
