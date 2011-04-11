Class {
	#name : #TVariableNode,
	#superclass : #TParseNode,
	#instVars : [
		'name'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'as yet unclassified' }
TVariableNode >> bindVariableUsesIn: aDictionary [

	^ (aDictionary at: name ifAbsent: [^ self]) copyTree
]

{ #category : #'as yet unclassified' }
TVariableNode >> bindVariablesIn: aDictionary [ 
	^ (aDictionary at: name ifAbsent: [^ self]) copyTree
]

{ #category : #'as yet unclassified' }
TVariableNode >> copyTree [

	^self class new setName: name
]

{ #category : #'as yet unclassified' }
TVariableNode >> emitCCodeOn: aStream level: level generator: aCodeGen [

	name = 'nil'
		ifTrue: [ aStream nextPutAll: (aCodeGen cLiteralFor: nil) ]
		ifFalse: [ aStream nextPutAll: (aCodeGen returnPrefixFromVariable: name) ].
]

{ #category : #testing }
TVariableNode >> isLeaf [

	^true
]

{ #category : #testing }
TVariableNode >> isStructTarget: aCodeGen [
	"Answer if the recever is a struct pointer
	 and hence can be dereferenced using ->"
	^aCodeGen isPointerToStructVariableName: name
]

{ #category : #testing }
TVariableNode >> isVariable [

	^true
]

{ #category : #'as yet unclassified' }
TVariableNode >> name [

	^name
]

{ #category : #accessing }
TVariableNode >> nameOrValue [

	^name
]

{ #category : #printing }
TVariableNode >> printOn: aStream level: level [

	aStream nextPutAll: name.
]

{ #category : #accessing }
TVariableNode >> setName: aString [

	name := aString.
]
