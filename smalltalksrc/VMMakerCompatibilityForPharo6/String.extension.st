Extension { #name : #String }

{ #category : #'*VMMakerCompatibilityForPharo6-converting' }
String >> asDisplayText [
	"Answer a DisplayText whose text string is the receiver."

	^DisplayText text: self asText
]
