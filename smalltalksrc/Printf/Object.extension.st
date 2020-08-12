Extension { #name : #Object }

{ #category : #'*printf' }
Object >> asArgumentArrayForFormatString [

	^{self}
]

{ #category : #'*printf' }
Object >> printLeanString [
	^self printStringLimitedTo: 256
]
