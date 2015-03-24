Extension { #name : #EncoderForV3 }

{ #category : #'*BytecodeSets-special literal encodings' }
EncoderForV3 >> isSpecialLiteralForPush: literal [
	^literal == false
	  or: [literal == true
	  or: [literal == nil
	  or: [literal isInteger and: [literal between: -1 and: 2]]]]
]
