'From Squeak3.2gamma of 15 January 2002 [latest update: #4823] on 17 April 2002 at 12:00:26 pm'!
"Change Set:		CGeneratorEnhancements-ajh
Date:			12 February 2002
Author:			Anthony Hannan (ajh18@cornell.edu)

This is part of the New Block Closure Version set of changes.  Please refer to http://minnow.cc.gatech.edu/squeak/BlockClosureVersion.

This changeset can be used independently of the block closure version.  However, the block closure version expects it.

This changeset avoids sharing temps of cases inlined into methods like interpret.  This produces faster code because the C compiler does not have to keep vars around across cases allowing it to optimize vars out of existence using registers.

This changeset will also customize cases that goto a shared label early enough. Before these were not customized because it thought the case was larger than it ends up being because of the goto."!


!Object methodsFor: 'translation support' stamp: 'ajh 1/30/2002 19:30'!
sharedCodeNamed: label inCase: caseNumber
	"For translation only; noop when running in Smalltalk."
	"DO NOT USE THIS IN A METHOD THAT TAKES ARGS.  The args will be named differently when inlined.  Pass args in globals that will become local to the interpret funtion, like currentBytecode.  See inlineDispatchesInMethodNamed:localizingVars: and its senders"! !


!CCodeGenerator methodsFor: 'inlining' stamp: 'ajh 1/30/2002 21:16'!
inlineDispatchesInMethodNamed: selector localizingVars: varsList
	"Inline dispatches (case statements) in the method with the given name."

	| m varString |
	m _ self methodNamed: selector.
	m = nil ifFalse: [
		m inlineCaseStatementBranches2In: self localizingVars: varsList.
		m parseTree nodesDo: [ :n |
			n isCaseStmt ifTrue: [
				n customizeShortCasesForDispatchVar: 'currentBytecode' into: m.
			].
		].
	].
	variables _ variables asOrderedCollection.
	varsList do: [ :v |
		varString _ v asString.
		variables remove: varString ifAbsent: [].
		(variableDeclarations includesKey: varString) ifTrue: [
			m declarations at: v asString put: (variableDeclarations at: varString).
			variableDeclarations removeKey: varString.
		].
	].
! !


!TMethod methodsFor: 'inlining' stamp: 'ajh 1/30/2002 16:55'!
inlineCaseStatementBranches2In: aCodeGen localizingVars: varsList
	"This version does not share temp names in the hope that the C compiler will be able to do local optimization better -ajh 1/30/2002"

	| stmt sel meth newStatements usedVars exitLabel |
	parseTree nodesDo: [ :n |
		n isCaseStmt ifTrue: [
			n cases do: [ :stmtNode |
				stmt _ stmtNode statements first.
				stmt isSend ifTrue: [
					sel _ stmt selector.
					meth _ aCodeGen methodNamed: sel.
					((meth ~= nil) and:
					 [meth hasNoCCode and:
					 [meth args size = 0]]) ifTrue: [
						meth _ meth copy.
						meth renameVarsForInliningInto: self in: aCodeGen.
						meth args, meth locals do: [ :v |
							(locals includes: v) ifFalse: [locals addLast: v]].
						meth declarations associationsDo: [ :assoc |
							declarations add: assoc].

						meth hasReturn ifTrue: [
							exitLabel _ self unusedLabelForInliningInto: self.
							meth exitVar: nil label: exitLabel.
							labels add: exitLabel.
						] ifFalse: [ exitLabel _ nil ].

						meth renameLabelsForInliningInto: self.
						meth labels do: [ :label | labels add: label ].
						newStatements _ stmtNode statements asOrderedCollection.
						newStatements removeFirst.

						exitLabel ~= nil ifTrue: [
							newStatements addFirst:
								(TLabeledCommentNode new
									setLabel: exitLabel comment: 'end case').
						].

						newStatements addAllFirst: meth statements.
						newStatements addFirst:
							(TLabeledCommentNode new setComment: meth selector).
						stmtNode setStatements: newStatements.
					].
				].
			].
		].
	].
	usedVars _ (locals, args) asSet.
	"make local versions of the given globals"
	varsList do: [ :var |
		(usedVars includes: var) ifFalse: [ locals addFirst: var asString ].
	].
! !


!TParseNode methodsFor: 'as yet unclassified' stamp: 'ajh 1/30/2002 22:11'!
renameLabelsInto: destMethod
	"Rename any labels that would clash with those of the destination method."

	| destLabels usedLabels labelMap newLabelName myLabels used l |
	destLabels _ destMethod labels asSet.
	usedLabels _ destLabels copy.  "usedLabels keeps track of labels in use"

	"Remove unused labels while collecting the rest"
	used _ OrderedCollection new.
	self nodesDo: [:n | n isGoTo ifTrue: [used add: n label]].
	myLabels _ OrderedCollection new.
	self nodesDo: [:n | (n isLabel and: [(l _ n label) notNil]) ifTrue: [
		((l first = $l and: [l allButFirst allSatisfy: [:c | c isDigit]])
		 and: [(used includes: l) not])
			ifTrue: [n setLabel: nil]  "remove label"
			ifFalse: [myLabels add: l]  "keep label if used or global name"
	]].

	"Build map to new unique names"
	usedLabels addAll: myLabels.
	labelMap _ Dictionary new: 100.
	myLabels do: [:str |
		(destLabels includes: str) ifTrue: [
			newLabelName _ TMethod basicNew unusedNamePrefixedBy: 'l' avoiding: usedLabels.
			labelMap at: str put: newLabelName.
		].
	].

	"Rename labels to unique names"
	self nodesDo: [ :node |
		(node isGoTo and: [labelMap includesKey: node label]) ifTrue: [
			node setLabel: (labelMap at: node label).
		].
		(node isLabel and: [labelMap includesKey: node label]) ifTrue: [
			node setLabel: (labelMap at: node label).
		].
	].

	"Tell my owning method about the new labels"
	myLabels do: [ :label |
		destMethod labels add: (labelMap at: label ifAbsent: [label]).
	].
! !


!TCaseStmtNode methodsFor: 'as yet unclassified' stamp: 'ajh 1/30/2002 21:55'!
customizeCase: caseParseTree forVar: varName from: firstIndex to: lastIndex into: destMethod
	"Return a collection of copies of the given parse tree, each of which has the value of the case index substituted for the given variable."

	| newCases dict newCase |
	newCases _ OrderedCollection new.
	firstIndex to: lastIndex do: [ :caseIndex |
		dict _ Dictionary new.
		dict at: varName put: (TConstantNode new setValue: caseIndex).
		newCase _ caseParseTree copyTree bindVariableUsesIn: dict.
		self fixSharedCodeBlocksForCase: caseIndex in: newCase.
		newCase renameLabelsInto: destMethod.
		newCases addLast: newCase.
	].
	^ newCases! !

!TCaseStmtNode methodsFor: 'as yet unclassified' stamp: 'ajh 1/30/2002 21:16'!
customizeShortCasesForDispatchVar: varName into: destMethod
	"Make customized versions of a short bytecode methods, substituting a constant having the case index value for the given variable. This produces better code for short bytecodes such as instance variable pushes that encode the index of the instance variable in the bytecode."

	| newFirsts newLasts newCases l f case expanded css |
	newFirsts _ OrderedCollection new.
	newLasts _ OrderedCollection new.
	newCases _ OrderedCollection new.
	1 to: cases size do: [ :i |
		l _ lasts at: i.
		f _ firsts at: i.
		case _ cases at: i.
		expanded _ false.
		(l - f) > 0 ifTrue: [  "case code covers multiple cases"
			css _ self customizeCase: case forVar: varName from: f to: l into: destMethod.
			(case nodeCount < 60 or: [css allSatisfy: [:c | c nodeCount < 60]]) ifTrue: [
				newFirsts addAll: (f to: l) asArray.
				newLasts addAll: (f to: l) asArray.
				newCases addAll: css.
				expanded _ true.
			].
		].
		expanded ifFalse: [
			self fixSharedCodeBlocksForCase: f in: case.
			newFirsts addLast: f.
			newLasts addLast: l.
			newCases addLast: case.
		].
	].
	firsts _ newFirsts asArray.
	lasts _ newLasts asArray.
	cases _ newCases asArray.
! !

TCaseStmtNode removeSelector: #customizeCase:forVar:from:to:!
TCaseStmtNode removeSelector: #customizeShortCasesForDispatchVar:!
