Class {
	#name : #TGoToNode,
	#superclass : #TParseNode,
	#instVars : [
		'label'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'as yet unclassified' }
TGoToNode >> copyTree [

	^self class new setLabel: label
]

{ #category : #'C code generation' }
TGoToNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C goto statement."

	aStream nextPutAll: 'goto '.
	aStream nextPutAll: label.
]

{ #category : #testing }
TGoToNode >> isGoTo [

	^true
]

{ #category : #accessing }
TGoToNode >> label [

	^label
]

{ #category : #printing }
TGoToNode >> printOn: aStream level: level [

	aStream nextPutAll: 'goto '.
	aStream nextPutAll: label.
]

{ #category : #accessing }
TGoToNode >> setLabel: aString [

	label := aString.
]
