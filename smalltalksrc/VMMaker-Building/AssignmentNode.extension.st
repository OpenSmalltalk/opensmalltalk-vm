Extension { #name : #AssignmentNode }

{ #category : #'*VMMaker-C translation' }
AssignmentNode >> asTranslatorNodeIn: aTMethod [
	"make a CCodeGenerator equivalent of me"
	| varNode valueNode |
	varNode := variable asTranslatorNodeIn: aTMethod.
	valueNode := value asTranslatorNodeIn: aTMethod.
	valueNode isStmtList ifFalse:
		[^TAssignmentNode new
			setVariable: varNode
			expression: valueNode;
			comment: comment].
	^TStmtListNode new
		setStatements: valueNode statements allButLast,
					{ TAssignmentNode new
						setVariable: varNode
						expression: valueNode statements last;
						comment: comment };
		yourself
]
