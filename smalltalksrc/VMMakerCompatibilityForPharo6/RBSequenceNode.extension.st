Extension { #name : #RBSequenceNode }

{ #category : #'*VMMakerCompatibilityForPharo6-C translation' }
RBSequenceNode >> asTranslatorNodeIn: aTMethod [ 
	"Answer a TParseNode subclass equivalent of me"
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
		setArguments: (parent isMethod
							ifTrue: [#()]
							ifFalse: [parent arguments asArray collect: [:arg | arg name]])
		statements: statementList;
		comment: self commentOrNil
]
