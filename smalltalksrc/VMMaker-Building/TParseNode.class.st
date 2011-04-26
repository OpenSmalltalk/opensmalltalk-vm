"
A TParseNode is node in the parse tree of a TMethod. Subclasses correspond to different types of nodes in a method parse tree. The tree of translation parse nodes mirrors the parse tree of a Smalltalk method, and is used for translating a Smalltalk method to C source.
"
Class {
	#name : #TParseNode,
	#superclass : #Object,
	#instVars : [
		'comment'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #utilities }
TParseNode >> allCalls [
	"Answer a collection of selectors for the messages sent in this parse tree."

	| calls |
	calls := Set new: 100.
	self nodesDo:
		[ :node |
		node isSend ifTrue:
			[((calls add: node selector) = #asSymbol
			  and: [node receiver isConstant
			  and: [node receiver value isSymbol]]) ifTrue:
				[calls add: node receiver value]]].
	^calls
]

{ #category : #transformations }
TParseNode >> bindVariableUsesIn: aDictionary [
	"Bind uses of all variables in the given dictionary, but do not change variables that appear on the left-hand-side of an assignment statement."

	^ self

]

{ #category : #transformations }
TParseNode >> bindVariablesIn: aDictionary [

	^self
]

{ #category : #accessing }
TParseNode >> comment: aComment [

	comment := aComment 
]

{ #category : #'C code generation' }
TParseNode >> emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen [
	^self emitCCodeOn: aStream level: level generator: aCodeGen
]

{ #category : #'C code generation' }
TParseNode >> emitCCodeAsExpressionOn: aStream level: level generator: aCodeGen [
	^self emitCCodeOn: aStream level: level generator: aCodeGen
]

{ #category : #'C code generation' }
TParseNode >> emitCCodeOn: aStream level: lev generator: gen [
	self subclassResponsibility.
]

{ #category : #'C code generation' }
TParseNode >> emitCCodeOn: aStream prependToEnd: aNodeOrNil level: lev generator: gen [
	aNodeOrNil ifNotNil:
		[aNodeOrNil prependCCodeOn: aStream level: lev generator: gen].
	self emitCCodeOn: aStream level: lev generator: gen
]

{ #category : #'C code generation' }
TParseNode >> emitCCommentOn: aStream level: level [
	"Emit the transferred Smalltalk comments as C comments."

	comment ifNotNil: [
		comment isString ifTrue: [^self].	"safety catch"
		aStream cr.
		1 to: comment size do: [:index | 
			aStream 
				tab: level;
				nextPutAll: '/* ';
				nextPutAll: (comment at: index);
				nextPutAll: ' */';
				cr].
		aStream cr]
]

{ #category : #testing }
TParseNode >> endsWithReturn [

	^false
]

{ #category : #testing }
TParseNode >> hasExplicitReturn [

	self nodesDo: [ :node |
		node isReturn ifTrue: [ ^true ].
	].
	^false
]

{ #category : #testing }
TParseNode >> isAssertion [
	^false
]

{ #category : #testing }
TParseNode >> isAssignment [

	^false
]

{ #category : #testing }
TParseNode >> isCaseStmt [

	^false
]

{ #category : #testing }
TParseNode >> isComment [

	^false
]

{ #category : #testing }
TParseNode >> isConstant [

	^false
]

{ #category : #testing }
TParseNode >> isGoTo [

	^false
]

{ #category : #testing }
TParseNode >> isInline [
	^false
]

{ #category : #testing }
TParseNode >> isLabel [

	^false
]

{ #category : #testing }
TParseNode >> isLeaf [
	"Answer true if the receiver is a variable or a constant node."

	^false
]

{ #category : #testing }
TParseNode >> isPreprocessorDirective [
	^false
]

{ #category : #testing }
TParseNode >> isReturn [

	^false
]

{ #category : #testing }
TParseNode >> isReturningIf [
	^false
]

{ #category : #testing }
TParseNode >> isSend [

	^false
]

{ #category : #testing }
TParseNode >> isStmtList [

	^false
]

{ #category : #testing }
TParseNode >> isSwitch [
	^false
]

{ #category : #testing }
TParseNode >> isTParseNode [
	^true
]

{ #category : #testing }
TParseNode >> isVariable [

	^false
]

{ #category : #accessing }
TParseNode >> nameOrValue [

	self error: 'object is neither variable nor constant'
]

{ #category : #utilities }
TParseNode >> nodeCount [
	"Answer the number of nodes in this parseTree (a rough measure of its size)."

	| cnt |
	cnt := 0.
	self nodesDo: [ :n | cnt := cnt + 1 ].
	^cnt
]

{ #category : #enumerating }
TParseNode >> nodesDo: aBlock [

	aBlock value: self.
]

{ #category : #enumerating }
TParseNode >> nodesDo: aBlock unless: cautionaryBlock [

	(cautionaryBlock value: self) ifTrue: [^self].
	aBlock value: self
]

{ #category : #printing }
TParseNode >> printOn: aStream [ 
	"Append a description of the receiver onto the given stream."

	self printOn: aStream level: 0.
]

{ #category : #printing }
TParseNode >> printOn: aStream level: anInteger [ 
	"Typically overridden. If control actually gets here, avoid recursion loop by sending to super."

	super printOn: aStream.
]

{ #category : #transformations }
TParseNode >> removeAssertions [
	"default: do nothing"
]

{ #category : #transformations }
TParseNode >> replaceNodesIn: aDictionary [

	^aDictionary at: self ifAbsent: [self]
]

{ #category : #testing }
TParseNode >> structTargetKind: aCodeGen [
	"Answer if the recever evaluates to a struct or struct pointer
	 and hence can be dereferenced using . or ->.  Answer any of
	 #struct #pointer or nil"
	^nil
]
