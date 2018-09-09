Extension { #name : #MethodNode }

{ #category : #'*VMMaker-C translation' }
MethodNode >> asTranslationMethodOfClass: aClass [
 	"Answer a TMethod (or subclass) derived from the receiver."
	^aClass new
		setSelector: selectorOrFalse
		definingClass: encoder associationForClass value
		args: arguments
		locals: encoder tempsAndBlockArgs
		block: block
		primitive: primitive
		properties: properties
		comment: comment
]

{ #category : #'*VMMaker-C translation' }
MethodNode >> quickMethodReturnLiteral [
	^self block statements last expr key
]
