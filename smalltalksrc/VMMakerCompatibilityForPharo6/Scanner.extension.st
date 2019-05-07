Extension { #name : #Scanner }

{ #category : #'*VMMakerCompatibilityForPharo6' }
Scanner >> typedScanTokens: textOrString [ 
	"Answer an Array that has been tokenized with literals mapped to literals,
	 special characters mapped to symbols and variable names and keywords
	 to strings. This methiod accepts _ (underscore) as an assignment token
	 irrespective of whether the system prefers := as the assignment token."
	| s |
	self initScannerForTokenization.
	self scan: (ReadStream on: textOrString asString).
	s := WriteStream on: (Array new: 16).
	[tokenType == #doIt] whileFalse:
		[(token == #- 
		  and: [(self typeTableAt: hereChar) == #xDigit]) ifTrue: 
			[self scanToken.
			 token := token negated].
		s nextPut: token.
		self scanToken].
	^s contents

	"Scanner new typedScanTokens: (Scanner sourceCodeAt: #typedScanTokens:)"
]
