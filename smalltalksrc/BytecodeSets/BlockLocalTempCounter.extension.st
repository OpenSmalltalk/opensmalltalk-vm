Extension { #name : #BlockLocalTempCounter }

{ #category : #'*BytecodeSets-instruction decoding' }
BlockLocalTempCounter >> blockReturnConstant: value [
	"Return Constant From Block bytecode."
	scanner pc < blockEnd ifTrue:
		[self doJoin]
]
