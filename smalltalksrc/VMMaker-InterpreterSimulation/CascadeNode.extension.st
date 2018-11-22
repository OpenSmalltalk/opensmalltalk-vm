Extension { #name : #CascadeNode }

{ #category : #'*VMMaker-C translation' }
CascadeNode >> asTranslatorNode [
"make a CCodeGenerator equivalent of me"
	^TStmtListNode new
		setArguments: #()
		statements: (messages collect:
			[ :msg | msg asTranslatorNode receiver: receiver asTranslatorNode ]);
		comment: comment
]
