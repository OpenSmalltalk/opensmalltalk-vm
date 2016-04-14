Class {
	#name : #TGoToNode,
	#superclass : #TParseNode,
	#instVars : [
		'label'
	],
	#category : 'VMMaker-Translation to C'
}

{ #category : #'C code generation' }
TGoToNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C goto statement."

	aStream nextPutAll: 'goto '.
	aStream nextPutAll: label.
]

{ #category : #'C code generation' }
TGoToNode >> emitCCodeOn: aStream prependToEnd: aNodeOrNil level: lev generator: gen [
	self emitCCodeOn: aStream level: lev generator: gen
]

{ #category : #testing }
TGoToNode >> isGoTo [

	^true
]

{ #category : #accessing }
TGoToNode >> label [

	^label
]

{ #category : #enumerating }
TGoToNode >> nodesDo: aBlock parent: parent [
	aBlock value: self value: parent
]

{ #category : #printing }
TGoToNode >> printOn: aStream level: level [

	aStream nextPutAll: 'goto '.
	aStream nextPutAll: label.
]

{ #category : #accessing }
TGoToNode >> setLabel: aString [
	label := aString
]
