"
I implement the main dispatch case statements for bytecode and primitive dispatch.  See TMethod classPool associationAt: #CaseStatements
"
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

{ #category : #transformations }
TCaseStmtNode >> bindVariableUsesIn: aDictionary [

	expression := expression bindVariableUsesIn: aDictionary.
	cases := cases collect: [ :c | c bindVariableUsesIn: aDictionary ].
]

{ #category : #transformations }
TCaseStmtNode >> bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen [
	"Answer either the receiver, if it contains no references to the given variables, or a new node with the given variables rebound."
	| newExpression newCases |
	newExpression := expression bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen.
	newCases := cases collect: [:c| c bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen].
	^(newExpression = expression
	   and: [newCases = cases])
		ifTrue: [self]
		ifFalse: [self shallowCopy
					setExpression: newExpression cases: newCases;
					yourself]
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

{ #category : #transformations }
TCaseStmtNode >> customizeCase: caseParseTree forVar: varName from: firstIndex to: lastIndex in: codeGen method: aTMethod expandedCases: seen [
	"Return a collection of copies of the given parse tree, each of which has the value of the case index substituted for the given variable."

	| newCases dict newCase |
	newCases := OrderedCollection new.
	firstIndex to: lastIndex do:
		[ :caseIndex |
		dict := Dictionary new.
		dict at: varName put: (TConstantNode new setValue: caseIndex).
		newCase := caseParseTree copy bindVariableUsesIn: dict andConstantFoldIf: true in: codeGen.
		self processSharedCodeBlocks: newCase forCase: caseIndex in: codeGen method: aTMethod expandedCases: seen.
		newCases addLast: newCase].
	^newCases
]

{ #category : #transformations }
TCaseStmtNode >> customizeShortCasesForDispatchVar: varName in: codeGen method: aTMethod [
	"Make customized versions of short bytecode methods, substituting a constant having the case index value for the given variable.
	 This produces better code for short bytecodes such as instance variable pushes that encode the index of the instance variable in the bytecode."

	| newFirsts newLasts newCases seen |
	newFirsts := OrderedCollection new.
	newLasts := OrderedCollection new.
	newCases := OrderedCollection new.
	seen := Set new.	"So that sharedCodeNamed:inCase:'s can be used in multiple bytecode set
						 configurations we need to expand the code only once."
	1 to: cases size do:
		[ :i | | l f case expanded |
		l := lasts at: i.
		f := firsts at: i.
		case := cases at: i.
		expanded := false.
		((l - f) > 1  "case code covers multiple cases"
		 and: [case shouldExpand]) ifTrue:
				[newFirsts addAll: (f to: l) asArray.
				 newLasts addAll: (f to: l) asArray.
				 newCases addAll: (self customizeCase: case forVar: varName from: f to: l in: codeGen method: aTMethod expandedCases: seen).
				 expanded := true].
		expanded ifFalse:
			[self processSharedCodeBlocks: case forCase: f in: codeGen method: aTMethod expandedCases: seen.
			 newFirsts addLast: f.
			 newLasts addLast: l.
			 newCases addLast: case]].
	firsts := newFirsts asArray.
	lasts := newLasts asArray.
	cases := newCases asArray
]

{ #category : #'C code generation' }
TCaseStmtNode >> emitCCodeOn: aStream addToEndOfCases: aNodeOrNil level: level generator: aCodeGen [

	| indent |
	indent := String new: level withAll: Character tab.
	aStream crtab: level.
	aStream nextPutAll: 'switch ('.
	expression emitCCodeAsArgumentOn: aStream level: level generator: aCodeGen.
	aStream nextPutAll: ') {'; cr.
	cases withIndexDo:
		[:case :i|
		(firsts at: i) to: (lasts at: i) do:
			[ :caseIndex |
			aStream nextPutAll: indent; nextPutAll: 'case '; print: caseIndex; nextPut: $:; cr].
		  case emitCCodeOn: aStream prependToEnd: aNodeOrNil level: level + 1 generator: aCodeGen.
		  (aNodeOrNil notNil and: [aNodeOrNil isReturn]) ifFalse:
			[aStream crtab: level + 1; nextPutAll: 'break;']].
	aStream
		crtab: level;
		nextPutAll: 'default:';
		crtab: level + 1;
		nextPutAll: 'error("Case not found");'.
	aNodeOrNil ifNotNil:
		[aStream crtab: level + 1.
		 (aNodeOrNil copy setExpression: (TConstantNode new setValue: -1))
			emitCCodeOn: aStream level: level generator: aCodeGen.
		 aStream nextPut: $;].
	aStream
		crtab: level;
		nextPut: $}
]

{ #category : #'C code generation' }
TCaseStmtNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	| printMod expansions duplicates |
	printMod := false.
	(expression isVariable
	 and: [expression name = 'currentBytecode']) ifTrue:
		[printMod := true.
		 aStream nextPutAll: 'bytecodeDispatchDebugHook();'; cr; crtab: level.
		 aCodeGen outputAsmLabel: 'bytecodeDispatch' on: aStream.
		 aStream crtab: level].
	aStream nextPutAll: 'switch ('.
	expression emitCCodeOn: aStream level: level generator: aCodeGen.
	aStream nextPutAll: ') {'; cr.
	expansions := aCodeGen suppressAsmLabelsWhile:
						[cases collect:
							[:case|
							self filterCommentsFrom:
								(String streamContents:
									[:s|
									case emitCCodeOn: s level: 0 generator: aCodeGen])]].
	duplicates := Set new.
	1 to: cases size do:
		[:i|
		(duplicates includes: i) ifFalse:
			[(duplicates addAll: ((i to: cases size) select: [:j| (expansions at: i) = (expansions at: j)])) do:
				[:k|
				(firsts at: k) to: (lasts at: k) do:
					[:caseIndex|
					aStream tab: level; nextPutAll: 'case '; print: caseIndex; nextPut: $:.
					(caseIndex > 255 and: [printMod]) ifTrue:
						[aStream nextPutAll: ' /*'; print: (caseIndex bitAnd: 255); nextPutAll: '*/'].
					aStream cr]].
			(cases at: i) emitCCodeOn: aStream level: level + 1 generator: aCodeGen.
			aStream tab: level + 1; nextPutAll: 'break;'; cr]].
	aStream tab: level; nextPut: $}
]

{ #category : #accessing }
TCaseStmtNode >> expression [

	^expression
]

{ #category : #private }
TCaseStmtNode >> filterCommentsFrom: aString [
	"elide any /* comment */ occurrences from aString."
	| i |
	i := aString indexOfSubCollection: '/*'startingAt: 1 ifAbsent: [^aString].
	^(aString copyFrom: 1 to: i - 1),
	  (self filterCommentsFrom:
		(aString
			copyFrom: (aString indexOfSubCollection: '*/' startingAt: i + 2) + 2
			to: aString size))
]

{ #category : #testing }
TCaseStmtNode >> isCaseStmt [

	^true
]

{ #category : #enumerating }
TCaseStmtNode >> nodesDo: aBlock [
	"Apply aBlock to all nodes in the receiver.
	 N.B. This is assumed to be bottom-up, leaves first."
	expression nodesDo: aBlock.
	cases do: [ :c | c nodesDo: aBlock ].
	aBlock value: self
]

{ #category : #enumerating }
TCaseStmtNode >> nodesDo: aBlock parent: parent [
	"Apply aBlock to all nodes in the receiver with each node's parent.
	 N.B. This is assumed to be bottom-up, leaves first."
	expression nodesDo: aBlock parent: self.
	cases do: [:c| c nodesDo: aBlock parent: self].
	aBlock value: self value: parent
]

{ #category : #enumerating }
TCaseStmtNode >> nodesDo: aBlock parent: parent unless: cautionaryBlock [

	(cautionaryBlock value: self value: parent) ifTrue: [^self].
	expression nodesDo: aBlock parent: self unless: cautionaryBlock.
	cases do: [ :c | c nodesDo: aBlock parent: self unless: cautionaryBlock].
	aBlock value: self value: parent
]

{ #category : #enumerating }
TCaseStmtNode >> nodesDo: aBlock unless: cautionaryBlock [

	(cautionaryBlock value: self) ifTrue: [^self].
	expression nodesDo: aBlock unless: cautionaryBlock.
	cases do: [ :c | c nodesDo: aBlock  unless: cautionaryBlock].
	aBlock value: self
]

{ #category : #copying }
TCaseStmtNode >> postCopy [

	expression := expression copy.
	firsts := firsts copy.
	lasts := lasts copy.
	cases := (cases collect: [ :case | case copy ])
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
TCaseStmtNode >> processSharedCodeBlocks: caseTree forCase: caseIndex in: codeGen method: aTMethod expandedCases: seen [
	"Process any shared code blocks in the case parse tree for the given case, either inlining them or making them a 'goto sharedLabel'."
	| caseMethod map meth sharedNode exitLabel |
	exitLabel := nil.
	"caseTree is expected to be a TStmtListNode whose first element is a comment
	 and whose second element is a TInlineNode for a method."
	caseMethod := caseTree statements second method.
	[sharedNode := nil.
	 map := IdentityDictionary new.
	 caseTree nodesDo:
		[:node|
		(sharedNode isNil
		and: [node isSend 
		and:[(meth := codeGen methodNamed: node selector) notNil
		and:[meth sharedCase notNil]]]) ifTrue:
			[(meth sharedCase = (meth sharedCase isSymbol
									ifTrue: [caseMethod selector]
									ifFalse: [caseIndex])
			  and: [(seen includes: meth sharedLabel) not])
				ifTrue:
					["If the bytecode (the caseMethod) ends with a message that has a lastCase (and lastLabel) then
					  that will be converted into a goto and control will continue to that code,  If the bytecode does
					  /not/ end with a message that has a lastCase (and lastLabel) then control should not continue to
					  that shared case.  expandViaFallThrough captures this, true for the former, false for the latter."
					 | expandViaFallThrough |
					 expandViaFallThrough := false.
					 caseMethod statements last isSend ifTrue:
						[(codeGen methodNamed: caseMethod statements last selector) ifNotNil:
							[:m| expandViaFallThrough := m sharedCase notNil]].
					 seen add: meth sharedLabel.
					 map
						at: node
						put: (expandViaFallThrough
								ifTrue: [sharedNode := meth.
										TLabeledCommentNode new setComment: 'goto ', meth sharedLabel]
								ifFalse: ["Still need recursive expansjon to continue but don't want
										  to duplicate the node, so substitue an empty method."
										 sharedNode := TLabeledCommentNode new setComment: 'null '.
										 meth copy
											renameLabelsForInliningInto: aTMethod;
											addLabelsTo: aTMethod;
											asInlineNode])]
				ifFalse:
					[map at: node put: (TGoToNode new setLabel: meth sharedLabel)]]].
	 caseTree replaceNodesIn: map.
	 "recursively expand"
	 sharedNode notNil]
		whileTrue:
			[sharedNode isTMethod ifTrue:
				[meth := sharedNode copy.
				 meth hasReturn ifTrue:
					[exitLabel ifNil:
						[exitLabel := aTMethod unusedLabelForInliningInto: aTMethod.
						 aTMethod labels add: exitLabel].
					meth exitVar: nil label: exitLabel].
				meth
					renameLabelsForInliningInto: aTMethod;
					addLabelsTo: aTMethod.
				caseTree setStatements: (caseTree statements copyWith: meth asInlineNode)]].
	exitLabel ifNotNil:
		[caseTree setStatements: (caseTree statements copyWith:
			(TLabeledCommentNode new setLabel: exitLabel comment: 'end case'))]
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

{ #category : #private }
TCaseStmtNode >> setExpression: newExpression cases: newCases [
	expression := newExpression.
	cases := newCases
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
