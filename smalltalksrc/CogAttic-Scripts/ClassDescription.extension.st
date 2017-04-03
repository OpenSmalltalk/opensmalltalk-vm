Extension { #name : #ClassDescription }

{ #category : #'*CogAttic-method prototypes squeak' }
ClassDescription >> ClassDescriptionPROTOTYPEupdateMethodBindingsTo: aBinding [
	"ClassBuilder support for maintaining valid method bindings."
	methodDict do: [:method| method methodClassAssociation: aBinding]
]
