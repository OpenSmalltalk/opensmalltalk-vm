Extension { #name : #ParseNode }

{ #category : #'*VMMaker-C translation' }
ParseNode >> asTranslatorNodeIn: aTMethod [
	"make a CCodeGenerator equivalent of me"

	^TNotImplementedNode new parseNode: self
]
