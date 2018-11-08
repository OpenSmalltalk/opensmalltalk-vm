Extension { #name : #WordArray }

{ #category : #'*VMMakerCompatibilityForPharo6-accessing' }
WordArray >> bytesPerElement [
	"Number of bytes in each item.  This multiplied by (self size)*8 gives the number of bits stored."
	^ 4
]
