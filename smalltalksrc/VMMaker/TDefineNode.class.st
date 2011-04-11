Class {
	#name : #TDefineNode,
	#superclass : #TConstantNode,
	#instVars : [
		'name'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'as yet unclassified' }
TDefineNode >> copyTree [

	^self class new
		setName: name value: value
]

{ #category : #'C code generation' }
TDefineNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C literal."

	aStream nextPutAll: name.
]

{ #category : #'as yet unclassified' }
TDefineNode >> name [
	^name
]

{ #category : #accessing }
TDefineNode >> name: aName [
	name := aName
]

{ #category : #accessing }
TDefineNode >> nameOrValue [
	^name
]

{ #category : #accessing }
TDefineNode >> setName: aName value: aValue [
	self name: aName.
	self setValue: aValue.
]
