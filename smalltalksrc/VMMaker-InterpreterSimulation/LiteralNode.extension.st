Extension { #name : #LiteralNode }

{ #category : #'*VMMaker-C translation' }
LiteralNode >> asTranslatorNode [
"make a CCodeGenerator equivalent of me"

	^TConstantNode new setValue: key
]
