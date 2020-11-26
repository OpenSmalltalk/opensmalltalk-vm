Class {
	#name : #TDefineNode,
	#superclass : #TConstantNode,
	#instVars : [
		'name'
	],
	#category : #'Slang-AST'
}

{ #category : #accessing }
TDefineNode >> constantNumbericValueOrNil [
	"Override so that named constants don't get elided."
	^nil
]

{ #category : #'C code generation' }
TDefineNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C literal."

	aStream nextPutAll: name.
]

{ #category : #testing }
TDefineNode >> isDefine [

	^true
]

{ #category : #comparing }
TDefineNode >> isSameAs: aTParseNode [
	^self class == aTParseNode class
	  and: [value class == aTParseNode value class
	  and: [value = aTParseNode value
	  and: [name = aTParseNode nameOrValue]]]
]

{ #category : #accessing }
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

{ #category : #'C code generation' }
TDefineNode >> printOn: aStream level: level [

	aStream nextPutAll: name
]

{ #category : #accessing }
TDefineNode >> setName: aName value: aValue [
	self name: aName.
	self setValue: aValue.
]
