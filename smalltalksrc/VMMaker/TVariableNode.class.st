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

{ #category : #'as yet unclassified' }
TVariableNode >> isLeaf [

	^true
]

{ #category : #'as yet unclassified' }
TVariableNode >> isVariable [

	^true
]

{ #category : #'as yet unclassified' }
TVariableNode >> name [

	^name
]

{ #category : #'as yet unclassified' }
TVariableNode >> nameOrValue [

	^name
]

{ #category : #'as yet unclassified' }
TVariableNode >> printOn: aStream level: level [

	aStream nextPutAll: name.
]

{ #category : #'as yet unclassified' }
TVariableNode >> setName: aString [

	name := aString.
]
