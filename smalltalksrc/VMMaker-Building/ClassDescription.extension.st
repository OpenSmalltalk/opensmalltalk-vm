Extension { #name : #ClassDescription }

{ #category : #'*VMMaker-accessing' }
ClassDescription >> >>> aSelector [
	"Convenience for creating MethodReferences"
	^MethodReference class: self selector: aSelector
]
