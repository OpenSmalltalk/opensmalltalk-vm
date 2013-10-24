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
	calls := Set new: 32.
	self nodesDo:
		[:node|
		node isSend ifTrue:
			[calls add: node selector].
		(node isConstant and: [node value isSymbol]) ifTrue:
			[calls add: node value]].
	^calls
]

{ #category : #enumerating }
TParseNode >> anySatisfy: aBlock [
	self nodesDo: [:n| (aBlock value: n) ifTrue: [^true]].
	^false
]

{ #category : #enumerating }
TParseNode >> anySatisfy: aBlock unless: cautionaryBlock [
	self
		nodesDo: [:n| (aBlock value: n) ifTrue: [^true]]
		unless: cautionaryBlock.
	^false
]

{ #category : #transformations }
TParseNode >> bindVariableUsesIn: aDictionary [
	"Bind uses of all variables in the given dictionary, but do not change variables that appear on the left-hand-side of an assignment statement."

	^ self

]

{ #category : #transformations }
TParseNode >> bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen [
	"Answer either the receiver, if it contains no references to the given variables, or a new node with the given variables rebound.
	 But do not change variables that appear on the left-hand-side of an assignment statement."
	^self

]

{ #category : #transformations }
TParseNode >> bindVariablesIn: aDictionary [

	^self
]

{ #category : #enumerating }
TParseNode >> collect: aBlock [
	| nodes |
	nodes := OrderedCollection new.
	self nodesDo: [:n| (aBlock value: n) ifTrue: [nodes add: n]].
	^nodes
]

{ #category : #accessing }
TParseNode >> comment [
	^comment
]

{ #category : #accessing }
TParseNode >> comment: aComment [

	comment := aComment 
]

{ #category : #enumerating }
TParseNode >> detect: aBlock [
	^self detect: aBlock ifNone: [self error: 'Node is not in the tree']
]

{ #category : #enumerating }
TParseNode >> detect: aBlock ifNone: defaultBlock [
	self nodesDo: [:n| (aBlock value: n) ifTrue: [^n]].
	^defaultBlock value
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
	self emitCCodeAsExpressionOn: aStream
		level: ((aNodeOrNil notNil and: [self isLeaf]) ifTrue: [0] ifFalse: [lev])
		generator: gen
]

{ #category : #'C code generation' }
TParseNode >> emitCCommentOn: aStream level: level [
	"Emit the transferred Smalltalk comments as C comments."

	comment ifNotNil:
		[comment isString ifTrue: [^self].	"safety catch"
		 aStream cr.
		 1 to: comment size do: [:index | 
			aStream tab: level; nextPutAll: '/* '.
			((comment at: index) findTokens: Character cr)
				do: [:line| aStream nextPutAll: line withBlanksTrimmed]
				separatedBy: [aStream crtab: level; next: 3 put: Character space].
			aStream nextPutAll: ' */'; cr].
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
TParseNode >> isLiteralArrayDeclaration [
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

{ #category : #testing }
TParseNode >> needsTrailingSemicolon [
	"Answer if, when emitted as a statement (in particular in a TStmtList), the
	 receiver needs a trailing semicolon.  Subclasses redefine as appropriate."
	^true
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
	"Apply aBlock to all nodes in the receiver.
	 N.B. This is assumed to be bottom-up, leaves first."
	aBlock value: self
]

{ #category : #enumerating }
TParseNode >> nodesDo: aBlock parent: parent [
	"Apply aBlock to all nodes in the receiver with each node's parent.
	 N.B. This is assumed to be bottom-up, leaves first."
	self subclassResponsibility
]

{ #category : #enumerating }
TParseNode >> nodesDo: aBlock unless: cautionaryBlock [
	"Evaluate aBlock for all nodes in  the tree except those for which cautionaryBlock
	 answers true or are children of those for which cautionaryBlock answers true."
	(cautionaryBlock value: self) ifFalse:
		[aBlock value: self]
]

{ #category : #enumerating }
TParseNode >> nodesWithParentsDo: aBlock [
	"Apply aBlock to all nodes in the receiver with each node's parent.
	 N.B. This is assumed to be bottom-up, leaves first."
	self nodesDo: aBlock parent: nil
]

{ #category : #enumerating }
TParseNode >> noneSatisfy: aBlock [
	self nodesDo: [:n| (aBlock value: n) ifTrue: [^false]].
	^true
]

{ #category : #enumerating }
TParseNode >> noneSatisfy: aBlock unless: cautionaryBlock [
	self
		nodesDo: [:n| (aBlock value: n) ifTrue: [^false]]
		unless: cautionaryBlock.
	^true
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
TParseNode >> structTargetKindIn: aCodeGen [
	"Answer if the recever evaluates to a struct or struct pointer
	 and hence can be dereferenced using . or ->.  Answer any of
	 #struct #pointer or nil"
	^nil
]
