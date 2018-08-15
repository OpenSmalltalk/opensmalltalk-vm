Extension { #name : #ParseNode }

{ #category : #'*VMMaker-C translation' }
ParseNode >> asTranslatorNodeIn: aTMethod [
	"Answer a TParseNode subclass equivalent of me"
	self subclassResponsibility
]

{ #category : #'*VMMaker-C translation' }
ParseNode >> isAssignmentEqualsEqualsNil [
	^false
]

{ #category : #'*VMMaker-C translation' }
ParseNode >> isReturn [
	^false
]
