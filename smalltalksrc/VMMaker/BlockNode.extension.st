Extension { #name : #BlockNode }

{ #category : #'*VMMaker-C translation' }
BlockNode >> asTranslatorNodeIn: aTMethod [
	"make a CCodeGenerator equivalent of me"
	| statementList |
	statementList := OrderedCollection new.
	statements
		do: [:s | | newS | 
			newS := s asTranslatorNodeIn: aTMethod.
			newS isStmtList
				ifTrue: ["inline the statement list returned when a CascadeNode is 
					translated "
					statementList addAll: newS statements]
				ifFalse: [statementList add: newS]].
	^ TStmtListNode new
		setArguments: (arguments asArray
				collect: [:arg | arg key])
		statements: statementList;
		 comment: comment
]
