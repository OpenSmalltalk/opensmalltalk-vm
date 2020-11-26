Class {
	#name : #Scanner,
	#superclass : #Object,
	#category : #'Slang-ToRemove'
}

{ #category : #scanning }
Scanner >> scanTokens: aString [ 

	^ (RBScanner on: aString readStream) contents
]

{ #category : #accessing }
Scanner >> typedScanTokens: textOrString [ 
	"Answer an Array that has been tokenized with literals mapped to literals,
	 special characters mapped to symbols and variable names and keywords
	 to strings. This methiod accepts _ (underscore) as an assignment token
	 irrespective of whether the system prefers := as the assignment token."

	^ (self scanTokens: textOrString)
		collect: [ :e | | value |
			value := e value.
			e isSpecial ifTrue: [ value := value asSymbol ].
			value ]
]
