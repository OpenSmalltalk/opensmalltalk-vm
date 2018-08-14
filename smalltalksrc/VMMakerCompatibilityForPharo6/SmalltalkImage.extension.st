Extension { #name : #SmalltalkImage }

{ #category : #'*VMMakerCompatibilityForPharo6-accessing' }
SmalltalkImage >> endianness [
	"Pluralitas non est ponenda sine necessitate..."
	^EndianDetector endianness
]

{ #category : #'*VMMakerCompatibilityForPharo6-special objects' }
SmalltalkImage >> primitiveErrorTable [
	"Smalltalk primitiveErrorTable"
	^self specialObjectsArray at: 52
]
