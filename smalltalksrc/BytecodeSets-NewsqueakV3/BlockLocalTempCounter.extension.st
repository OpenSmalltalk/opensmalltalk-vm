Extension { #name : #BlockLocalTempCounter }

{ #category : #'*BytecodeSets-instruction decoding' }
BlockLocalTempCounter >> blockReturnConstant: value [
	"Return Constant From Block bytecode."
	scanner pc < blockEnd ifTrue:
		[self doJoin]
]

{ #category : #'*BytecodeSets-instruction decoding' }
BlockLocalTempCounter >> directedSuperSend: selector numArgs: numArgs [
	"Send Message Above Specific Class With Selector, selector, bytecode.
	 Start the lookup above the class that is the value of the association on
	 top of stack. The arguments  of the message are found in the top numArgs
	 stack locations beneath the association, and the receiver just below them."

	stackPointer := stackPointer - (numArgs + 1)
]
