Extension { #name : #LiteralNode }

{ #category : #'*VMMaker-C translation' }
LiteralNode >> asTranslatorNodeIn: aTMethod [
	"make a CCodeGenerator equivalent of me"

	^TConstantNode new setValue: key
]
