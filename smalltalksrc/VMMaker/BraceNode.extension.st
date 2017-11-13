Extension { #name : #BraceNode }

{ #category : #'*VMMaker-C translation' }
BraceNode >> asTranslatorNodeIn: aTMethod [
	"make a CCodeGenerator equivalent of me."

	"This is for case statements"
	(elements allSatisfy:
		[:elem|
		elem isMessageNode
		and: [elem selector key = #->]]) ifTrue:
		[self assert: (elements allSatisfy:
			[:elem|
			elem receiver isBlockNode
			and: [elem arguments first isBlockNode
			and: [elem receiver isPotentialCCaseLabelIn: aTMethod]]]).
		^TBraceCaseNode new
			caseLabels: (elements collect: [:elem| elem receiver asTranslatorNodeIn: aTMethod]);
			cases: (elements collect: [:elem| elem arguments first asTranslatorNodeIn: aTMethod]);
			comment: comment].

	"This is for varargs selectors (variants of printf:)"
	^elements collect: [:elem| elem asTranslatorNodeIn: aTMethod]
]
