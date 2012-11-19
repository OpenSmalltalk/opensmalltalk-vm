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

{ #category : #transformations }
TStmtListNode >> bindVariableUsesIn: aDictionary [

	statements := statements collect: [ :s | s bindVariableUsesIn: aDictionary ].
]

{ #category : #transformations }
TStmtListNode >> bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen [
	"Answer either the receiver, if it contains no references to the given variables, or a new node with the given variables rebound."
	| newStatements |
	newStatements := statements collect: [:s| s bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen].
	^newStatements = statements
		ifTrue: [self]
		ifFalse:
			[self shallowCopy
				setStatements: newStatements;
				yourself]
]

{ #category : #transformations }
TStmtListNode >> bindVariablesIn: aDictionary [

	statements := statements collect: [ :s | s bindVariablesIn: aDictionary ].
]

{ #category : #'C code generation' }
TStmtListNode >> emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen [

	| statementWasComment |
	statements size = 1 ifTrue:
		[^statements first emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen].
	statementWasComment := false.
	aStream nextPut: $(. "N.B.  Comma binds weakest of all C operators."
	statements
		do:
			[:s |
			s emitCCommentOn: aStream level: level.
			s emitCCodeAsArgumentOn: aStream level: level + 1 generator: aCodeGen.
			statementWasComment := s isComment]
		separatedBy:
			[((self endsWithCloseBracket: aStream)
			  or: [statementWasComment]) ifFalse: [aStream nextPut: $,].
			aStream crtab: level].
	aStream nextPut: $)
]

{ #category : #'C code generation' }
TStmtListNode >> emitCCodeAsExpressionOn: aStream level: level generator: aCodeGen [
	^self emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen
]

{ #category : #'C code generation' }
TStmtListNode >> emitCCodeOn: aStream level: level generator: aCodeGen [

	self emitCCodeOn: aStream prependToEnd: nil level: level generator: aCodeGen

]

{ #category : #'C code generation' }
TStmtListNode >> emitCCodeOn: aStream prependToEnd: aNodeOrNil level: level generator: aCodeGen [
	self emitCCommentOn: aStream level: level.
	statements withIndexDo:
		[:s :idx|
		s emitCCommentOn: aStream level: level.
		aStream peekLast ~~ Character tab ifTrue:
			[aStream tab: level].
		(aNodeOrNil notNil
		 and: [idx = statements size])
			ifTrue:
				[s emitCCodeOn: aStream prependToEnd: aNodeOrNil level: level generator: aCodeGen]
			ifFalse:
				[s emitCCodeOn: aStream level: level generator: aCodeGen].
		((self endsWithCloseBracket: aStream)
		 or: [s isComment
		 or: [s isPreprocessorDirective
		 or: [s isSend and: [s isValueExpansion]]]]) ifFalse:
			[aStream nextPut: $;].
		aStream cr].

]

{ #category : #testing }
TStmtListNode >> endsWithCloseBracket: aStream [
	"Answer true if the given stream ends in a $} character."

	| ch pos |
	ch := (pos := aStream position) > 0 ifTrue:
			[aStream class = WriteStream "i.e. nested in StreamContents"
				ifTrue: [aStream originalContents at: pos]
				ifFalse: [aStream position: pos - 1; next]].
	^ ch = $}

]

{ #category : #testing }
TStmtListNode >> endsWithReturn [
	"Answer true if the last statement of this lock is a return."

	^statements last isReturn or: [statements last isReturningIf]
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
	"Apply aBlock to all nodes in the receiver.
	 N.B. This is assumed to be bottom-up, leaves first."
	statements do: [ :s | s nodesDo: aBlock ].	
	aBlock value: self
]

{ #category : #enumerating }
TStmtListNode >> nodesDo: aBlock unless: cautionaryBlock [

	(cautionaryBlock value: self) ifTrue: [^self].
	statements do: [ :s | s nodesDo: aBlock unless: cautionaryBlock ].	
	aBlock value: self
]

{ #category : #copying }
TStmtListNode >> postCopy [

	arguments := arguments copy.
	statements := statements collect: [ :s | s copy ]
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

{ #category : #inlining }
TStmtListNode >> shouldExpand [
	^(statements detect: [:stmt| stmt isInline]) shouldExpand
]

{ #category : #accessing }
TStmtListNode >> statements [

	^statements
]
