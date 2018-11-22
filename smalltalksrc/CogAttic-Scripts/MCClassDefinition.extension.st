Extension { #name : #MCClassDefinition }

{ #category : #'*CogAttic-method prototypes squeak 4.3' }
MCClassDefinition >> MCClassDefinitionPROTOTYPEkindOfSubclass [
	type = #normal ifTrue: [^' subclass: '].
	type = #variable ifTrue: [^' variableSubclass: '].
	type = #bytes ifTrue: [^' variableByteSubclass: '].
	type = #compiledMethod ifTrue: [^' variableByteSubclass: ' ].
	type = #words ifTrue: [^' variableWordSubclass: '].
	type = #weak ifTrue: [^' weakSubclass: ' ].
	type = #ephemeron ifTrue: [^' ephemeronSubclass: ' ].
	type = #immediate ifTrue: [^' immediateSubclass: ' ].
	self error: 'Unrecognized class type'
]
