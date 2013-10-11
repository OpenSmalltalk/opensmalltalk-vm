Extension { #name : #BraceNode }

{ #category : #'*VMMaker-C translation' }
BraceNode >> asTranslatorNodeIn: aTMethod [
	"make a CCodeGenerator equivalent of me"
	self assert: (elements allSatisfy:
		[:elem|
		elem isMessageNode
		and: [elem selector key = #->
		and: [elem receiver isBlockNode
		and: [elem arguments first isBlockNode
		and: [elem receiver isPotentialCCaseLabelIn: aTMethod]]]]]).
	^TBraceCaseNode new
		caseLabels: (elements collect: [:elem| elem receiver asTranslatorNodeIn: aTMethod]);
		cases: (elements collect: [:elem| elem arguments first asTranslatorNodeIn: aTMethod]);
		comment: comment
]
