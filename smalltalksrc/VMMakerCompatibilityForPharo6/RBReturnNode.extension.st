Extension { #name : #RBReturnNode }

{ #category : #'*VMMakerCompatibilityForPharo6-C translation' }
RBReturnNode >> asTranslatorNodeIn: aTMethod [
	"Answer a TParseNode subclass equivalent of a return."
	| exprTranslation lastExpr |
	exprTranslation := value asTranslatorNodeIn: aTMethod.
	(value isMessage
	 and: [value receiver isVariable
	 and: [value receiver name = 'super'
	 and: [exprTranslation isStmtList]]]) ifTrue:
		["super expansions containing returns are fine, and (as of 6/25/2012 19:27) the last
		  return is elided from the expansion by TMethod>>superExpansionNodeFor:args:. 
		  So we need to ensure the last expression is a return and simply reuse any other
		  returns in the expansion."
		lastExpr := exprTranslation statements last.
		(lastExpr isReturn
		 or: [lastExpr isReturningIf]) ifFalse:
			[exprTranslation statements
				at: exprTranslation statements size
				put:
					(TReturnNode new 
						setExpression: lastExpr;
						comment: self missingCommentNeededForCTranslation;
						yourself)].
		 ^exprTranslation].
	^TReturnNode new 
		setExpression: exprTranslation;
		comment: self missingCommentNeededForCTranslation;
		yourself
]
