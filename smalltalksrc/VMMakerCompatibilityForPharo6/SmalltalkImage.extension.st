Extension { #name : #SmalltalkImage }

{ #category : #'*VMMakerCompatibilityForPharo6-accessing' }
SmalltalkImage >> endianness [
	"Pluralitas non est ponenda sine necessitate..."
	^EndianDetector endianness
]
