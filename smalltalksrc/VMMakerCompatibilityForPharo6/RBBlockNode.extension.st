Extension { #name : #RBBlockNode }

{ #category : #'*VMMakerCompatibilityForPharo6-C translation' }
RBBlockNode >> asTranslatorNodeIn: aTMethod [
	"Answer a TParseNode subclass equivalent of me"
	| statementList |
	statementList := OrderedCollection new.
	body statements do:
		[:s | | newS |
		 newS := s asTranslatorNodeIn: aTMethod.
		 "inline the statement list returned when a CascadeNode is translated and/or when ifNotNil: is transformed"
		 newS isStmtList
			ifTrue:  [statementList addAll: newS statements]
			ifFalse: [statementList add: newS]].
	^TStmtListNode new
		setArguments: (arguments asArray collect: [:arg | arg name])
		statements: statementList;
		comment: self missingCommentNeededForCTranslation
]

{ #category : #'*VMMakerCompatibilityForPharo6-testing' }
RBBlockNode >> isBlockNode [
	^true
]

{ #category : #'*VMMakerCompatibilityForPharo6-C translation' }
RBBlockNode >> isPotentialCCaseLabel: stmt in: aTMethod [
	(stmt isVariable
	 or: [stmt isLiteralNode
		and: [stmt isConstantNumber or: [stmt literalValue isSymbol]]]) ifTrue:
		[^true].
	stmt isMessage ifTrue:
		[| selector implementingClass method |
		 selector := stmt selector.
		 (#(* + -) includes: selector) ifTrue:
			[^(self isPotentialCCaseLabel: stmt receiver in: aTMethod)
			   and: [self isPotentialCCaseLabel: stmt arguments first in: aTMethod]].

		 (selector = #asSymbol
		  and: [stmt receiver isLiteralNode
		  and: [stmt receiver literalValue isSymbol]]) ifTrue:
			[^true].

		 (stmt arguments isEmpty
		  and: [implementingClass := aTMethod definingClass whichClassIncludesSelector: selector.
			   implementingClass ifNil:
				[implementingClass := aTMethod definingClass objectMemoryClass whichClassIncludesSelector: selector].
			   method := implementingClass >> selector.
			   (method isQuick
				or: [(method literalAt: 1) isInteger
					and: [method numLiterals = 3]])
		   and: [(implementingClass basicNew perform: selector) isInteger]]) ifTrue:
				[^true]].
	^false
]

{ #category : #'*VMMakerCompatibilityForPharo6-C translation' }
RBBlockNode >> isPotentialCCaseLabelIn: aTMethod [
	body statements size ~= 1 ifTrue: [^false].
	^self isPotentialCCaseLabel: body statements first in: aTMethod
]
