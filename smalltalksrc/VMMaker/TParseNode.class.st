Class {
	#name : #TParseNode,
	#superclass : #Object,
	#instVars : [
		'comment'
	],
	#category : 'VMMaker-Translation to C'
}

{ #category : #'as yet unclassified' }
TParseNode >> allCalls [
	"Answer a collection of selectors for the messages sent in this parse tree."

	| calls |
	calls _ Set new: 100.
	self nodesDo: [ :node |
		node isSend ifTrue: [ calls add: node selector ].
	].
	^calls
]

{ #category : #'as yet unclassified' }
TParseNode >> bindVariableUsesIn: aDictionary [
	"Bind uses of all variables in the given dictionary, but do not change variables that appear on the left-hand-side of an assignment statement."

	^ self

]

{ #category : #'as yet unclassified' }
TParseNode >> bindVariablesIn: aDictionary [

	^self
]

{ #category : #'emit comments' }
TParseNode >> comment: aComment [

	comment _ aComment 
]

{ #category : #'emit comments' }
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

{ #category : #'as yet unclassified' }
TParseNode >> hasExplicitReturn [

	self nodesDo: [ :node |
		node isReturn ifTrue: [ ^true ].
	].
	^false
]

{ #category : #'as yet unclassified' }
TParseNode >> inlineMethodsUsing: aDictionary [

	self
]

{ #category : #'as yet unclassified' }
TParseNode >> isAssertion [
	^false
]

{ #category : #'as yet unclassified' }
TParseNode >> isAssignment [

	^false
]

{ #category : #'as yet unclassified' }
TParseNode >> isCaseStmt [

	^false
]

{ #category : #'as yet unclassified' }
TParseNode >> isComment [

	^false
]

{ #category : #'as yet unclassified' }
TParseNode >> isConstant [

	^false
]

{ #category : #'as yet unclassified' }
TParseNode >> isGoTo [

	^false
]

{ #category : #'as yet unclassified' }
TParseNode >> isLabel [

	^false
]

{ #category : #'as yet unclassified' }
TParseNode >> isLeaf [
	"Answer true if the receiver is a variable or a constant node."

	^false
]

{ #category : #'as yet unclassified' }
TParseNode >> isReturn [

	^false
]

{ #category : #'as yet unclassified' }
TParseNode >> isSend [

	^false
]

{ #category : #'as yet unclassified' }
TParseNode >> isStmtList [

	^false
]

{ #category : #'as yet unclassified' }
TParseNode >> isVariable [

	^false
]

{ #category : #'as yet unclassified' }
TParseNode >> nameOrValue [

	self error: 'object is neither variable nor constant'
]

{ #category : #'as yet unclassified' }
TParseNode >> nodeCount [
	"Answer the number of nodes in this parseTree (a rough measure of its size)."

	| cnt |
	cnt _ 0.
	self nodesDo: [ :n | cnt _ cnt + 1 ].
	^cnt
]

{ #category : #'as yet unclassified' }
TParseNode >> nodesDo: aBlock [

	aBlock value: self.
]

{ #category : #'as yet unclassified' }
TParseNode >> nodesVarCheckDo: aBlock [

	aBlock value: self.
]

{ #category : #'as yet unclassified' }
TParseNode >> printOn: aStream [ 
	"Append a description of the receiver onto the given stream."

	self printOn: aStream level: 0.
]

{ #category : #'as yet unclassified' }
TParseNode >> printOn: aStream level: anInteger [ 
	"Typically overridden. If control actually gets here, avoid recursion loop by sending to super."

	super printOn: aStream.
]

{ #category : #'as yet unclassified' }
TParseNode >> removeAssertions [
	"default: do nothing"
]

{ #category : #'as yet unclassified' }
TParseNode >> replaceNodesIn: aDictionary [

	^aDictionary at: self ifAbsent: [self]
]
