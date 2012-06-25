Extension { #name : #AssignmentNode }

{ #category : #'*VMMaker-C translation' }
AssignmentNode >> anyReturns: aSequenceOfNodes [
	aSequenceOfNodes do:
		[:node|
		node nodesDo:
			[:n|
			n isReturn ifTrue:
				[^true]]].
	^false
]

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
	 "This is a super expansion.  We are in trouble if any statement other than the last is a return."
	(self anyReturns: valueNode statements allButLast) ifTrue:
		[self error: 'haven''t implemented pushing down assignments into other than the last return'].
	"As of 6/25/2012 19:30 superExpansionNodeFor:args: elides the final return."
	self assert: valueNode statements last isReturn not.
	^TStmtListNode new
		setStatements: valueNode statements allButLast,
					{ TAssignmentNode new
						setVariable: varNode
						expression: valueNode statements last;
						comment: comment };
		yourself
]
