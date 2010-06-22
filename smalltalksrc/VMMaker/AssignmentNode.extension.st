Extension { #name : #AssignmentNode }

{ #category : #'*VMMaker-C translation' }
AssignmentNode >> asTranslatorNodeIn: aTMethod [
	"make a CCodeGenerator equivalent of me"
	^TAssignmentNode new
		setVariable: (variable asTranslatorNodeIn: aTMethod)
		expression: (value asTranslatorNodeIn: aTMethod);
		comment: comment
]
