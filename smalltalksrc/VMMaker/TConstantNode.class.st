Class {
	#name : #TConstantNode,
	#superclass : #TParseNode,
	#instVars : [
		'value'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'as yet unclassified' }
TConstantNode >> copyTree [

	^self class new
		setValue: value
]

{ #category : #'as yet unclassified' }
TConstantNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C literal."

	aStream nextPutAll: (aCodeGen cLiteralFor: value).
]

{ #category : #'as yet unclassified' }
TConstantNode >> isConstant [

	^true
]

{ #category : #'as yet unclassified' }
TConstantNode >> isLeaf [

	^true
]

{ #category : #'as yet unclassified' }
TConstantNode >> name [
	^''
]

{ #category : #'as yet unclassified' }
TConstantNode >> nameOrValue [

	^value
]

{ #category : #'as yet unclassified' }
TConstantNode >> printOn: aStream level: level [

	value storeOn: aStream.
]

{ #category : #'as yet unclassified' }
TConstantNode >> setValue: anObject [

	value _ anObject.
]

{ #category : #'as yet unclassified' }
TConstantNode >> value [

	^value
]
