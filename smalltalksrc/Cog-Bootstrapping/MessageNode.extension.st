Extension { #name : #MessageNode }

{ #category : #'*Cog-Explorations-testing' }
MessageNode >> isSingleReturningIf [

	^((special between: 1 and: 2) "ifTrue:/ifFalse:"
	    or: [special between: 15 and: 16]) "ifNil:/ifNotNil:"
		and: [arguments first returns]
]
