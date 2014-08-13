Extension { #name : #ClosureExtractor }

{ #category : #'*BytecodeSets-instruction decoding' }
ClosureExtractor >> blockReturnConstant: value [
	currentContext := currentContext sender
]
