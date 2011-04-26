Class {
	#name : #TDefineNode,
	#superclass : #TConstantNode,
	#instVars : [
		'name'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'C code generation' }
TDefineNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C literal."

	aStream nextPutAll: name.
]

{ #category : #accessing }
TDefineNode >> name [
	^name asString
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
