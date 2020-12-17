Extension { #name : #EncoderForV3PlusClosures }

{ #category : #'*VMMaker' }
EncoderForV3PlusClosures class >> extensionsAt: pc in: aCompiledMethod into: trinaryBlock [
	"If the bytecode at pc is an extension then evaluate aTrinaryBlock
	 with the values of extA and extB and number of extension *bytes*.
	 If the bytecode at pc is not an extension then evaluate with 0, 0, 0.
	 There are no extensions in the SqueakV3/Smalltalk-80 bytecode set, so..." 
	^trinaryBlock value: 0 value: 0 value: 0
]
