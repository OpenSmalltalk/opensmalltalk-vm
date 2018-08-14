Extension { #name : #ByteArray }

{ #category : #'*VMMakerCompatibilityForPharo6-accessing' }
ByteArray >> bytesPerElement [
	"Number of bytes in each item.  This multiplied by (self size)*8 gives the number of bits stored."
	^ 1
]
