Extension { #name : #CascadeNode }

{ #category : #'*VMMaker-C translation' }
CascadeNode >> asTranslatorNodeIn: aTMethod [
	"make a CCodeGenerator equivalent of me"
	^TStmtListNode new
		setArguments: #()
		statements:
			(Array streamContents:
				[:s| | receiverNode |
				receiverNode := receiver asTranslatorNodeIn: aTMethod.
				receiverNode isLeaf ifFalse:
					[| varNode |
					 varNode := aTMethod newCascadeTempFor: receiverNode.
					 s nextPut: (TAssignmentNode new
								setVariable: varNode
								expression: receiverNode).
					receiverNode := varNode].
				messages do:
					[ :msg | s nextPut: ((msg asTranslatorNodeIn: aTMethod) receiver: receiverNode)]]);
		comment: comment
]
