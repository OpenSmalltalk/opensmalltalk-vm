Class {
	#name : #TStmtListNode,
	#superclass : #TParseNode,
	#instVars : [
		'arguments',
		'statements'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #accessing }
TStmtListNode >> args [

	^arguments
]

{ #category : #converting }
TStmtListNode >> asExpression [

	^ (self statements size = 1)
		ifTrue: [statements first]
		ifFalse: [self error: 'multiple statements can not serve as a simple expression']
]

{ #category : #transformations }
TStmtListNode >> bindVariableUsesIn: aDictionary [

	statements := statements collect: [ :s | s bindVariableUsesIn: aDictionary ].
]

{ #category : #transformations }
TStmtListNode >> bindVariablesIn: aDictionary [

	statements := statements collect: [ :s | s bindVariablesIn: aDictionary ].
]

{ #category : #'as yet unclassified' }
TStmtListNode >> copyTree [

	^self class new
		setArguments: arguments copy
		statements: (statements collect: [ :s | s copyTree ])
]

{ #category : #'C code generation' }
TStmtListNode >> emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen [

	| statementWasComment |
	statementWasComment := false.
	statements
		do:
			[:s |
			s emitCCommentOn: aStream level: level.
			s emitCCodeAsArgumentOn: aStream level: 0 generator: aCodeGen.
			statementWasComment := s isComment]
		separatedBy:
			[((self endsWithCloseBracket: aStream)
			  or: [statementWasComment]) ifFalse: [aStream nextPut: $,]]
]

{ #category : #'as yet unclassified' }
TStmtListNode >> emitCCodeOn: aStream level: level generator: aCodeGen [

	statements do: [:s |
		s emitCCommentOn: aStream level: level.
		aStream tab: level.
		s emitCCodeOn: aStream level: level generator: aCodeGen.
		(((self endsWithCloseBracket: aStream) not
			and: [(s isComment) not])
				and: [s requiresCLineTerminator])
			ifTrue: [aStream nextPut: $;].
		aStream cr].

]

{ #category : #testing }
TStmtListNode >> endsWithCloseBracket: aStream [
	"Answer true if the given stream ends in a $} character."

	| ch pos |
	(pos := aStream position) > 0 ifTrue: [
		aStream position: pos - 1.
		ch := aStream next].
	^ ch = $}

]

{ #category : #'as yet unclassified' }
TStmtListNode >> inlineMethodsUsing: aDictionary [

	statements do: [ :s | s inlineMethodsUsing: aDictionary ].
]

{ #category : #testing }
TStmtListNode >> isNilStmtListNode [

	|stmt|
	statements size = 1 ifFalse: [^false].
	stmt := statements at: 1.
	^ stmt isVariable and: [stmt name = 'nil']
]

{ #category : #testing }
TStmtListNode >> isStmtList [

	^true
]

{ #category : #enumerating }
TStmtListNode >> nodesDo: aBlock [

	statements do: [ :s | s nodesDo: aBlock ].	
	aBlock value: self.
]

{ #category : #printing }
TStmtListNode >> printOn: aStream level: level [

	aStream nextPut: $[.
	arguments size > 0 ifTrue: [
		arguments do: [ :arg | aStream nextPutAll: ' :', arg ].
		aStream nextPutAll: ' | '.
	].
	self printStatementsOn: aStream level: level.
	aStream nextPut: $].
]

{ #category : #printing }
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

{ #category : #transformations }
TStmtListNode >> removeAssertions [
	| newStatements |
	newStatements := OrderedCollection new: statements size.
	statements do: [ :stmt |
		stmt isAssertion ifFalse: [
			newStatements add: (stmt removeAssertions; yourself).
		]
	].
	self setStatements: newStatements asArray
]

{ #category : #transformations }
TStmtListNode >> replaceNodesIn: aDictionary [

	^aDictionary at: self ifAbsent: [
		statements := statements collect: [ :s | s replaceNodesIn: aDictionary ].
		self]
]

{ #category : #accessing }
TStmtListNode >> setArguments: argList [

	arguments := argList.
]

{ #category : #accessing }
TStmtListNode >> setArguments: argList statements: statementList [
	"Initialize this method using the given information."

	arguments := argList.
	statements := statementList.
]

{ #category : #accessing }
TStmtListNode >> setStatements: stmtList [

	statements := stmtList asOrderedCollection.
]

{ #category : #accessing }
TStmtListNode >> statements [

	^statements
]
