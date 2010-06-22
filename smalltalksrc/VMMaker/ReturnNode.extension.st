Extension { #name : #ReturnNode }

{ #category : #'*VMMaker-C translation' }
ReturnNode >> asTranslatorNodeIn: aTMethod [
	"make a CCodeGenerator equivalent of me"
	^TReturnNode new 
		setExpression: (expr asTranslatorNodeIn: aTMethod);
		comment: comment
]
