Extension { #name : #BlockNode }

{ #category : #'*VMMaker-C translation' }
BlockNode >> asTranslatorNodeIn: aTMethod [
	"make a CCodeGenerator equivalent of me"
	| statementList |
	statementList := OrderedCollection new.
	statements do:
		[:s | | newS |
		 newS := s asTranslatorNodeIn: aTMethod.
		 "inline the statement list returned when a CascadeNode is translated and/or when ifNotNil: is transformed"
		 newS isStmtList
			ifTrue:  [statementList addAll: newS statements]
			ifFalse: [statementList add: newS]].
	^TStmtListNode new
		setArguments: (arguments asArray collect: [:arg | arg key])
		statements: statementList;
		comment: comment
]

{ #category : #'*VMMaker-C translation' }
BlockNode >> isPotentialCCaseLabel: stmt in: aTMethod [
	(stmt isVariableNode
	 or: [stmt isLiteralNode
		and: [stmt isConstantNumber or: [stmt literalValue isSymbol]]]) ifTrue:
		[^true].
	stmt isMessageNode ifTrue:
		[| selector method |
		 selector := stmt selector key.
		 (#(* + -) includes: selector) ifTrue:
			[^(self isPotentialCCaseLabel: stmt receiver in: aTMethod)
			   and: [self isPotentialCCaseLabel: stmt arguments first in: aTMethod]].

		 (selector = #asSymbol
		  and: [stmt receiver isLiteralNode
		  and: [stmt receiver literalValue isSymbol]]) ifTrue:
			[^true].

		 (stmt arguments isEmpty
		  and: [method := (aTMethod definingClass whichClassIncludesSelector: selector) >> selector.
			   (method isQuick
				or: [(method literalAt: 1) isInteger
					and: [method numLiterals = 3]])
		   and: [(aTMethod definingClass basicNew perform: selector) isInteger]]) ifTrue:
				[^true]].
	^false
]

{ #category : #'*VMMaker-C translation' }
BlockNode >> isPotentialCCaseLabelIn: aTMethod [
	| stmt |
	statements size ~= 1 ifTrue: [^false].
	stmt := statements first.
	^self isPotentialCCaseLabel: stmt in: aTMethod
]
