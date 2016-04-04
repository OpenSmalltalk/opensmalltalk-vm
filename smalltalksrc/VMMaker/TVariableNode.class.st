Class {
	#name : #TVariableNode,
	#superclass : #TParseNode,
	#instVars : [
		'name'
	],
	#category : 'VMMaker-Translation to C'
}

{ #category : #transformations }
TVariableNode >> bindVariableUsesIn: aDictionary [

	^ (aDictionary at: name ifAbsent: [^ self]) copy
]

{ #category : #transformations }
TVariableNode >> bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen [
	"Answer either the receiver, if it is not a reference to one of the given variables, or the replacement if it is."
	^(aDictionary at: name ifAbsent: [^self]) copy
]

{ #category : #transformations }
TVariableNode >> bindVariablesIn: aDictionary [ 
	^ (aDictionary at: name ifAbsent: [^ self]) copy
]

{ #category : #'C code generation' }
TVariableNode >> emitCCodeOn: aStream level: level generator: aCodeGen [

	aStream nextPutAll: (name = 'nil'
						ifTrue: [ aCodeGen cLiteralFor: nil ]
						ifFalse: [ aCodeGen returnPrefixFromVariable: name ])
]

{ #category : #'as yet unclassified' }
TVariableNode >> hasSideEffect [
	"Answer if the parse tree rooted at this node has a side-effect or not."
	^false
]

{ #category : #testing }
TVariableNode >> isLeaf [

	^true
]

{ #category : #comparing }
TVariableNode >> isSameAs: aTParseNode [
	^aTParseNode isVariable
	 and: [name = aTParseNode name]
]

{ #category : #testing }
TVariableNode >> isVariable [

	^true
]

{ #category : #accessing }
TVariableNode >> name [

	^name asString
]

{ #category : #accessing }
TVariableNode >> nameOrValue [

	^name
]

{ #category : #enumerating }
TVariableNode >> nodesDo: aBlock parent: parent [
	"Apply aBlock to all nodes in the receiver with each node's parent.
	 N.B. This is assumed to be bottom-up, leaves first."
	aBlock value: self value: parent
]

{ #category : #printing }
TVariableNode >> printOn: aStream level: level [

	aStream nextPutAll: name.
]

{ #category : #accessing }
TVariableNode >> setName: aString [

	name := aString.
]

{ #category : #testing }
TVariableNode >> structTargetKindIn: aCodeGen [
	"Answer if the recever evaluates to a struct or struct pointer
	 and hence can be dereferenced using . or ->.  Answer any of
	 #struct #pointer or nil"
	^aCodeGen structTargetKindForVariableName: name
]

{ #category : #accessing }
TVariableNode >> variableNameOrNil [
	^name
]
