Extension { #name : #LiteralNode }

{ #category : #'*VMMaker-C translation' }
LiteralNode >> asTranslatorNodeIn: aTMethod [
	"Answer a TParseNode subclass equivalent of me"

	^TConstantNode new setValue: key
]
