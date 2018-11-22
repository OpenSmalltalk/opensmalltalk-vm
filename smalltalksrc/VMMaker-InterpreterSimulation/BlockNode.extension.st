Extension { #name : #BlockNode }

{ #category : #'*VMMaker-C translation' }
BlockNode >> asTranslatorNode [
	"make a CCodeGenerator equivalent of me"
	| statementList newS |
	statementList := OrderedCollection new.
	statements
		do: [:s | 
			newS := s asTranslatorNode.
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
