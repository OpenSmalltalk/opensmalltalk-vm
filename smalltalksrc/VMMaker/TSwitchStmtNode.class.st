"
I implement a Smalltalk
	foo caseOf: { [IntegerConstant | GlobalVariable] -> [expr] }
statement converting it into a C switch statement.  I make some effort to discover identical right-hand-side cases.
"
Class {
	#name : #TSwitchStmtNode,
	#superclass : #TParseNode,
	#instVars : [
		'expression',
		'cases',
		'otherwiseOrNil',
		'switchVariable'
	],
	#category : 'VMMaker-Translation to C'
}

{ #category : #transformations }
TSwitchStmtNode >> bindVariableUsesIn: aDictionary [
	expression := expression bindVariableUsesIn: aDictionary.
	cases := (cases collect:
				[:pair| "<Array with: <Array with: ParseTreeNode> with: TStmtListNode"
				{ pair first collect: [:labelNode| labelNode bindVariableUsesIn: aDictionary].
				   pair last bindVariableUsesIn: aDictionary }]).
	otherwiseOrNil ifNotNil:
		[otherwiseOrNil := otherwiseOrNil bindVariableUsesIn: aDictionary]
]

{ #category : #transformations }
TSwitchStmtNode >> bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen [
	"Answer either the receiver, if it contains no references to the given variables, or a new node with the given variables rebound."
	| newExpression newCases newOtherwise |
	newExpression := expression bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen.
	newCases := cases collect:
					[:pair| "<Array with: <Array with: ParseTreeNode> with: TStmtListNode"
					{ pair first collect: [:labelNode| labelNode bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen].
					   pair last bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen}].
	newOtherwise := otherwiseOrNil ifNotNil:
						[otherwiseOrNil bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen].
	^(newExpression = expression
	   and: [newCases = cases
	   and: [newOtherwise = otherwiseOrNil]])
		ifTrue: [self]
		ifFalse:
			[self shallowCopy
				expression: newExpression;
				cases: newCases;
				otherwiseOrNil: newOtherwise;
				yourself]
]

{ #category : #transformations }
TSwitchStmtNode >> bindVariablesIn: aDictionary [
	expression := expression bindVariablesIn: aDictionary.
	cases := (cases collect:
				[:pair| "<Array with: <Array with: ParseTreeNode> with: TStmtListNode"
				{ pair first collect: [:labelNode| labelNode bindVariablesIn: aDictionary].
				   pair last bindVariablesIn: aDictionary }]).
	otherwiseOrNil ifNotNil:
		[otherwiseOrNil := otherwiseOrNil bindVariablesIn: aDictionary]
]

{ #category : #accessing }
TSwitchStmtNode >> cases [
	"Answer the value of cases"

	^ cases
]

{ #category : #accessing }
TSwitchStmtNode >> cases: anObject [
	"Set the value of cases"

	cases := anObject
]

{ #category : #'instance initialization' }
TSwitchStmtNode >> createCasesFromBraceNode: aTBraceNode [
	"Answer a sequence of tuples of { labels. case } for a TBraceNode, making
	 sure to collect equivalent cases together under a signle sequence of labels."
	| casesToStrings stringsToLabels newCases |
	casesToStrings := Dictionary new.
	stringsToLabels := Dictionary new.
	newCases := OrderedCollection new: aTBraceNode caseLabels size.
	aTBraceNode caseLabels with: aTBraceNode cases do:
		[:label :case| | printString |
		printString := casesToStrings at: case put: case printString.
		(stringsToLabels at: printString ifAbsentPut: [OrderedCollection new]) addLast: label].

	aTBraceNode caseLabels with: aTBraceNode cases do:
		[:label :case| | printString labels |
		printString := casesToStrings at: case.
		label = (labels := (stringsToLabels at: printString) asArray) first ifTrue:
			[newCases addLast: { labels collect: [:ea| ea statements first]. case}]].

	^newCases
]

{ #category : #'C code generation' }
TSwitchStmtNode >> emitCCodeAsExpressionOn: aStream level: level generator: aCodeGen [
	"Emit the receiver as an if-the-else chain."
	| varName n |
	self assert: (expression isVariable or: [switchVariable notNil]).
	aStream nextPut: $(.
	switchVariable
		ifNil: [varName := String streamContents: [:s| expression emitCCodeOn: s level: 0 generator: aCodeGen].
			aStream nextPutAll: varName]
		ifNotNil:
			[varName := switchVariable.
			 aStream nextPut: $(; nextPutAll: varName; nextPutAll: ' = '.
			 expression emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen.
			 aStream nextPut: $)].
	n := 0.
	cases do:
		[:tuple|
		 [:labels :case|
		  labels do:
			[:label|
			 n > 0 ifTrue:
				[aStream nextPutAll: varName].
			 aStream nextPutAll: ' == '.
			 label emitCCodeAsArgumentOn: aStream level: level + 1 generator: aCodeGen.
			 aStream nextPut: $).
			 aStream crtab: level + n + 1.
			 aStream nextPutAll: '? ('.
			 (TStmtListNode new setArguments: #() statements: case statements)
			 	emitCCodeAsArgumentOn: aStream
				level: level + 2
				generator: aCodeGen.
			 aStream nextPut: $); crtab: level + n + 1; nextPutAll: ': ('.
			 n := n + 1]]
			valueWithArguments: tuple].
	otherwiseOrNil
		ifNotNil: [otherwiseOrNil emitCCodeAsArgumentOn: aStream level: level + 1 generator: aCodeGen]
		ifNil: [aStream nextPutAll: 'error("Case not found and no otherwise clause"), 0'].
	aStream next: n - 1 put: $)
]

{ #category : #'C code generation' }
TSwitchStmtNode >> emitCCodeOn: aStream addToEndOfCases: aNodeOrNil level: level generator: aCodeGen [

	aStream crtab: level.
	aStream nextPutAll: 'switch ('.
	expression emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen.
	aStream nextPutAll: ') {'.
	cases do:
		[:tuple|
		 [:labels :case|
		  labels do:
			[:label|
			 aStream
				crtab: level;
				nextPutAll: 'case '.
			label emitCCodeAsArgumentOn: aStream level: level + 1 generator: aCodeGen.
			aStream nextPut: $:].
		  aStream crtab: level + 1.
		  case emitCCodeOn: aStream prependToEnd: aNodeOrNil level: level + 1 generator: aCodeGen]
			valueWithArguments: tuple.
		  (aNodeOrNil notNil and: [aNodeOrNil isReturn]) ifFalse:
			[aStream crtab: level + 1; nextPutAll: 'break;']].
	aStream
		crtab: level;
		nextPutAll: 'default:';
		crtab: level + 1.
	otherwiseOrNil
		ifNotNil: [otherwiseOrNil emitCCodeOn: aStream prependToEnd: aNodeOrNil level: level + 1 generator: aCodeGen]
		ifNil: [aStream nextPutAll: 'error("Case not found and no otherwise clause");'.
			   aNodeOrNil ifNotNil:
				[aStream crtab: level + 1.
				 (aNodeOrNil copy setExpression: (TConstantNode new setValue: -1))
					emitCCodeOn: aStream level: level generator: aCodeGen.
				 aStream nextPut: $;]].
	aStream
		crtab: level;
		nextPut: $}
]

{ #category : #'C code generation' }
TSwitchStmtNode >> emitCCodeOn: aStream level: level generator: aCodeGen [

	aStream crtab: level.
	aStream nextPutAll: 'switch ('.
	expression emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen.
	aStream nextPutAll: ') {'.
	cases do:
		[:tuple|
		 [:labels :case|
		  labels do:
			[:label|
			 aStream
				crtab: level;
				nextPutAll: 'case '.
			label emitCCodeAsArgumentOn: aStream level: level + 1 generator: aCodeGen.
			aStream nextPut: $:].
		  aStream crtab: level + 1.
		  case emitCCodeOn: aStream level: level + 1 generator: aCodeGen.
		  case endsWithReturn ifFalse:
			[aStream tab: level + 1; nextPutAll: 'break;']]
			valueWithArguments: tuple].
	aStream
		crtab: level;
		nextPutAll: 'default:';
		crtab: level + 1.
	otherwiseOrNil
		ifNotNil:
			[otherwiseOrNil emitCCodeOn: aStream level: level + 1 generator: aCodeGen.
			(self stream: aStream endsWithAnyOf: '};') ifFalse:
				[aStream nextPut: $;]]
		ifNil: [aStream nextPutAll: 'error("Case not found and no otherwise clause");'].
	aStream
		crtab: level;
		nextPut: $}
]

{ #category : #accessing }
TSwitchStmtNode >> expression [
	"Answer the value of expression"

	^ expression
]

{ #category : #accessing }
TSwitchStmtNode >> expression: anObject [
	"Set the value of expression"

	expression := anObject
]

{ #category : #'instance initialization' }
TSwitchStmtNode >> expression: expr cases: aTBraceNode otherwiseOrNil: otherwiseOrNilNode [

	self expression: expr.
	self cases: (self createCasesFromBraceNode: aTBraceNode).
	self otherwiseOrNil: otherwiseOrNilNode
]

{ #category : #testing }
TSwitchStmtNode >> isSwitch [
	^true
]

{ #category : #enumerating }
TSwitchStmtNode >> nodesDo: aBlock [
	"Apply aBlock to all nodes in the receiver.
	 N.B. This is assumed to be bottom-up, leaves first."
	expression nodesDo: aBlock.
	cases do:
		[:pair|
		pair first do: [:node| node nodesDo: aBlock].
		pair last nodesDo: aBlock].
	otherwiseOrNil ifNotNil:
		[otherwiseOrNil nodesDo: aBlock].
	aBlock value: self
]

{ #category : #enumerating }
TSwitchStmtNode >> nodesDo: aBlock parent: parent [
	"Apply aBlock to all nodes in the receiver with each node's parent.
	 N.B. This is assumed to be bottom-up, leaves first."
	expression nodesDo: aBlock parent: self.
	cases do:
		[:pair|
		pair first do: [:node| node nodesDo: aBlock parent: self.].
		pair last nodesDo: aBlock parent: self.].
	otherwiseOrNil ifNotNil:
		[otherwiseOrNil nodesDo: aBlock parent: self].
	aBlock value: self value: parent
]

{ #category : #enumerating }
TSwitchStmtNode >> nodesDo: aBlock parent: parent unless: cautionaryBlock [

	(cautionaryBlock value: self value: parent) ifTrue: [^self].
	expression nodesDo: aBlock parent: self unless: cautionaryBlock.
	cases do:
		[:pair|
		pair first do: [:node| node nodesDo: aBlock parent: self unless: cautionaryBlock].
		pair last nodesDo: aBlock parent: self unless: cautionaryBlock].
	otherwiseOrNil ifNotNil:
		[otherwiseOrNil nodesDo: aBlock parent: self unless: cautionaryBlock]
]

{ #category : #enumerating }
TSwitchStmtNode >> nodesDo: aBlock unless: cautionaryBlock [

	(cautionaryBlock value: self) ifTrue: [^self].
	expression nodesDo: aBlock unless: cautionaryBlock.
	cases do:
		[:pair|
		pair first do: [:node| node nodesDo: aBlock unless: cautionaryBlock].
		pair last nodesDo: aBlock unless: cautionaryBlock].
	otherwiseOrNil ifNotNil:
		[otherwiseOrNil nodesDo: aBlock unless: cautionaryBlock]
]

{ #category : #accessing }
TSwitchStmtNode >> otherwiseOrNil [
	"Answer the value of otherwiseOrNil"

	^ otherwiseOrNil
]

{ #category : #accessing }
TSwitchStmtNode >> otherwiseOrNil: anObject [
	"Set the value of otherwiseOrNil"

	otherwiseOrNil := anObject
]

{ #category : #copying }
TSwitchStmtNode >> postCopy [
	expression := expression copy.
	cases := (cases collect:
				[:pair| "<Array with: <Array with: ParseTreeNode> with: TStmtListNode"
				{ pair first collect: [:labelNode| labelNode copy].
				   pair last copy }]).
	otherwiseOrNil := otherwiseOrNil copy
]

{ #category : #printing }
TSwitchStmtNode >> printOn: aStream level: level [

	aStream crtab: level.
	aStream nextPutAll: 'switch ('.
	expression printOn: aStream level: level.
	aStream nextPutAll: ') {'.
	cases do:
		[:tuple|
		 [:labels :case|
		  labels do:
			[:label|
			 aStream
				crtab: level;
				nextPutAll: 'case '.
			label printOn: aStream level: level + 1.
			aStream nextPut: $:].
		  aStream crtab: level + 1.
		  case printOn: aStream level: level + 1.
		  aStream crtab: level + 1; nextPutAll: 'break;']
			valueWithArguments: tuple].
	otherwiseOrNil ifNotNil:
		[aStream
			crtab: level;
			nextPutAll: 'default:';
			crtab: level + 1.
		 otherwiseOrNil printOn: aStream level: level + 1].
	aStream
		crtab: level;
		nextPut: $}
]

{ #category : #transformations }
TSwitchStmtNode >> removeAssertions [
	expression removeAssertions.
	cases do:
		[:pair| "<Array with: <Array with: ParseTreeNode> with: TStmtListNode"
		pair first do: [:labelNode| labelNode removeAssertions].
		pair last removeAssertions].
	otherwiseOrNil ifNotNil:
		[otherwiseOrNil removeAssertions]
]

{ #category : #transformations }
TSwitchStmtNode >> replaceNodesIn: aDictionary [
	^aDictionary
		at: self
		ifAbsent:
			[expression := expression replaceNodesIn: aDictionary.
			 cases := (cases collect:
						[:pair| "<Array with: <Array with: ParseTreeNode> with: TStmtListNode"
						{ pair first collect: [:labelNode| labelNode replaceNodesIn: aDictionary].
						   pair last replaceNodesIn: aDictionary }]).
			 otherwiseOrNil ifNotNil:
				[otherwiseOrNil := otherwiseOrNil replaceNodesIn: aDictionary].
			 self]
]

{ #category : #accessing }
TSwitchStmtNode >> switchVariable [
	"Answer the value of switchVariable"

	^ switchVariable
]

{ #category : #accessing }
TSwitchStmtNode >> switchVariable: anObject [
	"Set the value of switchVariable"

	switchVariable := anObject
]
