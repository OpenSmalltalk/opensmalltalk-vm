Extension { #name : #ReturnNode }

{ #category : #'*VMMaker-C translation' }
ReturnNode >> asTranslatorNodeIn: aTMethod [
	"Make a CCodeGenerator equivalent of a return.
	 Since super calls are expanded the return must be elided from super expansions."
	(expr isMessage
	 and: [expr receiver isVariableNode and: [expr receiver key = 'super']]) ifTrue:
		[^expr asTranslatorNodeIn: aTMethod].
	^TReturnNode new 
		setExpression: (expr asTranslatorNodeIn: aTMethod);
		comment: comment
]

{ #category : #'*VMMaker-C translation' }
ReturnNode >> isReturn [
	^true
]
