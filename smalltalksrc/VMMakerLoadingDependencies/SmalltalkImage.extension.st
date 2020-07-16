Extension { #name : #SmalltalkImage }

{ #category : #'*VMMakerLoadingDependencies' }
SmalltalkImage >> endianness [
	"Pluralitas non est ponenda sine necessitate..."
	^EndianDetector endianness
]
