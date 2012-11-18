Class {
	#name : #TConstantNode,
	#superclass : #TParseNode,
	#instVars : [
		'value'
	],
	#category : #'VMMaker-Translation to C'
}

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
TConstantNode >> isConstant [

	^true
]

{ #category : #testing }
TConstantNode >> isLeaf [

	^true
]

{ #category : #accessing }
TConstantNode >> name [
	^''
]

{ #category : #accessing }
TConstantNode >> nameOrValue [

	^value
]

{ #category : #printing }
TConstantNode >> printOn: aStream level: level [

	value storeOn: aStream.
]

{ #category : #accessing }
TConstantNode >> setValue: anObject [

	value := anObject.
]

{ #category : #accessing }
TConstantNode >> value [

	^value
]
