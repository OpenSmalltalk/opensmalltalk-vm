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

{ #category : #'as yet unclassified' }
TGoToNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C goto statement."

	aStream nextPutAll: 'goto '.
	aStream nextPutAll: label.
]

{ #category : #'as yet unclassified' }
TGoToNode >> isGoTo [

	^true
]

{ #category : #'as yet unclassified' }
TGoToNode >> label [

	^label
]

{ #category : #'as yet unclassified' }
TGoToNode >> printOn: aStream level: level [

	aStream nextPutAll: 'goto '.
	aStream nextPutAll: label.
]

{ #category : #'as yet unclassified' }
TGoToNode >> setLabel: aString [

	label _ aString.
]
