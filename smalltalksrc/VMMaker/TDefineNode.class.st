Class {
	#name : #TDefineNode,
	#superclass : #TConstantNode,
	#instVars : [
		'name'
	],
	#category : 'VMMaker-Translation to C'
}

{ #category : #'as yet unclassified' }
TDefineNode >> copyTree [

	^self class new
		setName: name value: value
]

{ #category : #'as yet unclassified' }
TDefineNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C literal."

	aStream nextPutAll: name.
]

{ #category : #'as yet unclassified' }
TDefineNode >> name [
	^name
]

{ #category : #'as yet unclassified' }
TDefineNode >> name: aName [
	name _ aName
]

{ #category : #'as yet unclassified' }
TDefineNode >> nameOrValue [
	^name
]

{ #category : #'as yet unclassified' }
TDefineNode >> setName: aName value: aValue [
	self name: aName.
	self setValue: aValue.
]
