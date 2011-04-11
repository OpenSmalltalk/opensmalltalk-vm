Class {
	#name : #TCaseStmtNode,
	#superclass : #TParseNode,
	#instVars : [
		'expression',
		'firsts',
		'lasts',
		'cases'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'as yet unclassified' }
TCaseStmtNode >> assumesCurrentBytecodeMatchesCaseValue: statementList [
	"Test for the special case of certain methods that rely on the value of
	the currentBytecode variable to be expanded to a constant. This is a
	performance optimization that permits the next bytecode to be fetched
	early while not affecting the prior value of currentBytecode, which
	will have been translated to a constant.
	
	See senders of #'requires currentBytecode to be expanded to a constant'
	for methods that rely on this behavior."

	| trickySelectors commentString firstLine |
	trickySelectors := {
			#pushLiteralConstantBytecode .
			#pushLiteralVariableBytecode .
			#pushReceiverVariableBytecode .
			#pushTemporaryVariableBytecode .
			#storeAndPopTemporaryVariableBytecode .
			#storeAndPopReceiverVariableBytecode
		}.
	firstLine := statementList statements first.
	firstLine isComment ifTrue: [
		commentString := firstLine asString.
		trickySelectors detect: [:e | commentString includesSubString: e]
			ifNone: [^ false].
		^ true].
	^ false
]

{ #category : #transformations }
TCaseStmtNode >> bindVariableUsesIn: aDictionary [

	expression := expression bindVariableUsesIn: aDictionary.
	cases := cases collect: [ :c | c bindVariableUsesIn: aDictionary ].
]

{ #category : #transformations }
TCaseStmtNode >> bindVariablesIn: aDictionary [

	expression := expression bindVariablesIn: aDictionary.
	cases := cases collect: [ :c | c bindVariablesIn: aDictionary ].
]

{ #category : #accessing }
TCaseStmtNode >> cases [

	^cases
]

{ #category : #'as yet unclassified' }
TCaseStmtNode >> copyTree [

	^self class new
		setExpression: expression copyTree
		firsts: firsts copy
		lasts: lasts copy
		cases: (cases collect: [ :case | case copyTree ])
]

{ #category : #'as yet unclassified' }
TCaseStmtNode >> customizeCase: caseParseTree forVar: varName from: firstIndex to: lastIndex in: codeGen method: aTMethod [
	"Return a collection of copies of the given parse tree, each of which has the value of the case index substituted for the given variable."

	| newCases dict newCase |
	newCases := OrderedCollection new.
	firstIndex to: lastIndex do: [ :caseIndex |
		dict := Dictionary new.
		dict at: varName put: (TConstantNode new setValue: caseIndex).
		newCase := caseParseTree copyTree bindVariableUsesIn: dict.
		self processSharedCodeBlocks: newCase forCase: caseIndex in: codeGen method: aTMethod.
		newCases addLast: newCase.
	].
	^ newCases
]

{ #category : #'as yet unclassified' }
TCaseStmtNode >> customizeShortCasesForDispatchVar: varName in: codeGen method: aTMethod [
	"Make customized versions of a short bytecode methods, substituting a constant having the case index value for the given variable. This produces better code for short bytecodes such as instance variable pushes that encode the index of the instance variable in the bytecode."

	| newFirsts newLasts newCases l f case expanded |
	newFirsts := OrderedCollection new.
	newLasts := OrderedCollection new.
	newCases := OrderedCollection new.
	1 to: cases size do: [ :i |
		l := lasts at: i.
		f := firsts at: i.
		case := cases at: i.
		expanded := false.
		(l - f) > 1 ifTrue: [  "case code covers multiple cases"
			(case nodeCount < 60
				or: [self assumesCurrentBytecodeMatchesCaseValue: case]) ifTrue: [
					newFirsts addAll: (f to: l) asArray.
					newLasts addAll: (f to: l) asArray.
					newCases addAll: (self customizeCase: case forVar: varName from: f to: l in: codeGen method: aTMethod).
					expanded := true
			]
		].
		expanded ifFalse: [
			self processSharedCodeBlocks: case forCase: f in: codeGen method: aTMethod.
			newFirsts addLast: f.
			newLasts addLast: l.
			newCases addLast: case.
		]
	].
	firsts := newFirsts asArray.
	lasts := newLasts asArray.
	cases := newCases asArray.

]

{ #category : #'as yet unclassified' }
TCaseStmtNode >> emitCCodeOn: aStream level: level generator: aCodeGen [

	| indent |
	indent := (String new: level) collect: [ :ch | Character tab ].
	aStream nextPutAll: 'switch ('.
	expression asExpression emitCCodeOn: aStream level: level generator: aCodeGen.
	aStream nextPutAll: ') {'; cr.
	1 to: cases size do: [ :i |
		(firsts at: i) to: (lasts at: i) do: [ :caseIndex |
			aStream nextPutAll: indent, 'case ', caseIndex printString, ':'; cr.
		].
		(cases at: i) emitCCodeOn: aStream level: level + 1 generator: aCodeGen.
		aStream nextPutAll: indent; tab; nextPutAll: 'break;'.
		aStream cr.
	].
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #accessing }
TCaseStmtNode >> expression [

	^expression
]

{ #category : #'as yet unclassified' }
TCaseStmtNode >> inlineMethodsUsing: aDictionary [

	expression inlineMethodsUsing: aDictionary.
	cases do: [ :c | c inlineMethodsUsing: aDictionary ].
]

{ #category : #testing }
TCaseStmtNode >> isCaseStmt [

	^true
]

{ #category : #enumerating }
TCaseStmtNode >> nodesDo: aBlock [

	expression nodesDo: aBlock.
	cases do: [ :c | c nodesDo: aBlock ].
	aBlock value: self.
]

{ #category : #printing }
TCaseStmtNode >> printOn: aStream level: level [

	aStream crtab: level.
	aStream nextPutAll: 'select '.
	expression printOn: aStream level: level.
	aStream nextPutAll: ' in'.
	1 to: cases size do: [ :i |
		(firsts at: i) to: (lasts at: i) do: [ :caseIndex |
			aStream crtab: level.
			aStream nextPutAll: 'case ', caseIndex printString, ':'.
		].
		aStream crtab: level + 1.
		(cases at: i) printOn: aStream level: level + 1.
	].
	aStream crtab: level.
	aStream nextPutAll: 'end select'.
]

{ #category : #transformations }
TCaseStmtNode >> processSharedCodeBlocks: caseTree forCase: caseIndex in: codeGen method: aTMethod [
	"Process any shared code blocks in the case parse tree for the given case, either inlining them or making them a 'goto sharedLabel'."
	| map meth sharedNode exitLabel |
	exitLabel := nil.

	[sharedNode := nil.
	map := IdentityDictionary new.
	caseTree nodesDo:[:node|
		(node isSend 
			and:[(meth := codeGen methodNamed: node selector) notNil
			and:[meth sharedCase notNil]]) ifTrue:[
			meth sharedCase = caseIndex ifTrue:[
				sharedNode := meth.
				map at: node put: (TLabeledCommentNode new setComment: 'goto ', meth sharedLabel).
			] ifFalse:[
				map at: node put: (TGoToNode new setLabel: meth sharedLabel).
			].
		].
	].
	caseTree replaceNodesIn: map.
	"recursively expand"
	sharedNode == nil] whileFalse:[
		meth := sharedNode copy.
		(meth hasReturn) ifTrue: [
			exitLabel ifNil:[
				exitLabel := aTMethod unusedLabelForInliningInto: aTMethod.
				aTMethod labels add: exitLabel.
			].
			meth exitVar: nil label: exitLabel.
		].
		meth renameLabelsForInliningInto: aTMethod.
		aTMethod labels addAll: meth labels.
		caseTree setStatements: (caseTree statements copyWith: meth asInlineNode).
	].
	exitLabel ifNotNil:[
		caseTree setStatements: (caseTree statements copyWith:
			(TLabeledCommentNode new setLabel: exitLabel comment: 'end case')).

	].
]

{ #category : #transformations }
TCaseStmtNode >> removeAssertions [
	expression removeAssertions.
	cases do: [ :case | case removeAssertions ].
]

{ #category : #transformations }
TCaseStmtNode >> replaceNodesIn: aDictionary [

	^aDictionary at: self ifAbsent: [
		expression := expression replaceNodesIn: aDictionary.
		cases := cases collect: [ :c | c replaceNodesIn: aDictionary ].
		self]
]

{ #category : #'as yet unclassified' }
TCaseStmtNode >> setExpression: aNode firsts: firstsList lasts: lastsList cases: caseList [

	expression := aNode.
	firsts := firstsList.
	lasts := lastsList.
	cases := caseList.
]

{ #category : #accessing }
TCaseStmtNode >> setExpression: aNode selectors: selectorList arguments: anArray [
	"Initialize the node from the given set of selectors."
	"Note: Each case is a statement list with containing one statement, a send to self of a selector from the given selector list. Having statement list nodes makes inlining easier later."

	| selfNode stmt lastSel firstInRun sel |
	expression := aNode.
	selfNode := TVariableNode new setName: 'self'.
	firsts := OrderedCollection new: 400.
	lasts := OrderedCollection new: 400.
	cases := OrderedCollection new: 400.
	lastSel := selectorList first.
	firstInRun := 0.
	1 to: selectorList size do: [ :i |
		sel := selectorList at: i.
		sel ~= lastSel ifTrue: [
			firsts add: firstInRun.
			lasts add: i - 2.
			stmt := TSendNode new setSelector: lastSel receiver: selfNode arguments: anArray.
			cases add: (TStmtListNode new setArguments: #() statements: (Array with: stmt)).
			lastSel := sel.
			firstInRun := i - 1.
		].
	].
	firsts add: firstInRun.
	lasts add: selectorList size - 1.
	stmt := TSendNode new setSelector: lastSel receiver: selfNode arguments: anArray.
	cases add: (TStmtListNode new setArguments: #() statements: (Array with: stmt)).
]
