Class {
	#name : #TStmtListNode,
	#superclass : #TParseNode,
	#instVars : [
		'arguments',
		'statements'
	],
	#category : 'VMMaker-Translation to C'
}

{ #category : #'as yet unclassified' }
TStmtListNode >> args [

	^arguments
]

{ #category : #'as yet unclassified' }
TStmtListNode >> bindVariableUsesIn: aDictionary [

	statements _ statements collect: [ :s | s bindVariableUsesIn: aDictionary ].
]

{ #category : #'as yet unclassified' }
TStmtListNode >> bindVariablesIn: aDictionary [

	statements _ statements collect: [ :s | s bindVariablesIn: aDictionary ].
]

{ #category : #'as yet unclassified' }
TStmtListNode >> copyTree [

	^self class new
		setArguments: arguments copy
		statements: (statements collect: [ :s | s copyTree ])
]

{ #category : #'as yet unclassified' }
TStmtListNode >> emitCCodeOn: aStream level: level generator: aCodeGen [

	statements do: [:s |
		s emitCCommentOn: aStream level: level.
		aStream tab: level.
		s emitCCodeOn: aStream level: level generator: aCodeGen.
		((self endsWithCloseBracket: aStream) or:
		 [s isComment])
			ifFalse: [aStream nextPut: $;].
		aStream cr].

]

{ #category : #'as yet unclassified' }
TStmtListNode >> endsWithCloseBracket: aStream [
	"Answer true if the given stream ends in a $} character."

	| ch pos |
	(pos _ aStream position) > 0 ifTrue: [
		aStream position: pos - 1.
		ch _ aStream next].
	^ ch = $}

]

{ #category : #'as yet unclassified' }
TStmtListNode >> inlineMethodsUsing: aDictionary [

	statements do: [ :s | s inlineMethodsUsing: aDictionary ].
]

{ #category : #'as yet unclassified' }
TStmtListNode >> isNilStmtListNode [

	|stmt|
	statements size = 1 ifFalse: [^false].
	stmt _ statements at: 1.
	^ stmt isVariable and: [stmt name = 'nil']
]

{ #category : #'as yet unclassified' }
TStmtListNode >> isStmtList [

	^true
]

{ #category : #'as yet unclassified' }
TStmtListNode >> nodesDo: aBlock [

	statements do: [ :s | s nodesDo: aBlock ].	
	aBlock value: self.
]

{ #category : #'as yet unclassified' }
TStmtListNode >> printOn: aStream level: level [

	aStream nextPut: $[.
	arguments size > 0 ifTrue: [
		arguments do: [ :arg | aStream nextPutAll: ' :', arg ].
		aStream nextPutAll: ' | '.
	].
	self printStatementsOn: aStream level: level.
	aStream nextPut: $].
]

{ #category : #'as yet unclassified' }
TStmtListNode >> printStatementsOn: aStream level: level [

	statements size > 1 ifTrue: [ aStream crtab: level + 1 ].
	1 to: statements size do: [ :i |
		(statements at: i) printOn: aStream level: level.
		i = statements size ifTrue: [
			(statements size > 1) ifTrue: [
				aStream crtab: level.
			].
		] ifFalse: [
			aStream nextPut: $.; crtab: level + 1.
		].
	].
]

{ #category : #'as yet unclassified' }
TStmtListNode >> removeAssertions [
	| newStatements |
	newStatements _ OrderedCollection new: statements size.
	statements do: [ :stmt |
		stmt isAssertion ifFalse: [
			newStatements add: (stmt removeAssertions; yourself).
		]
	].
	self setStatements: newStatements asArray
]

{ #category : #'as yet unclassified' }
TStmtListNode >> replaceNodesIn: aDictionary [

	^aDictionary at: self ifAbsent: [
		statements _ statements collect: [ :s | s replaceNodesIn: aDictionary ].
		self]
]

{ #category : #'as yet unclassified' }
TStmtListNode >> setArguments: argList [

	arguments _ argList.
]

{ #category : #'as yet unclassified' }
TStmtListNode >> setArguments: argList statements: statementList [
	"Initialize this method using the given information."

	arguments _ argList.
	statements _ statementList.
]

{ #category : #'as yet unclassified' }
TStmtListNode >> setStatements: stmtList [

	statements _ stmtList asOrderedCollection.
]

{ #category : #'as yet unclassified' }
TStmtListNode >> statements [

	^statements
]
