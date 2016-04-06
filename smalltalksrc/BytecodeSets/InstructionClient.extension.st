Extension { #name : #InstructionClient }

{ #category : #'*BytecodeSets-instruction decoding' }
InstructionClient >> blockReturnConstant: value [
	"Return Constant From Block bytecode."


]

{ #category : #'*BytecodeSets-instruction decoding' }
InstructionClient >> callInlinePrimitive: pimIndex [
	"SistaV1:			248 11111000 iiiiiiii mjjjjjjj  Call Primitive #iiiiiiii + ( jjjjjjj * 256)
							m=1 means inlined primitive, no hard return after execution."
]

{ #category : #'*BytecodeSets-instruction decoding' }
InstructionClient >> directedSuperSend: selector numArgs: numArgs [
	"Send Message Above Specific Class With Selector, selector, bytecode.
	 Start the lookup above the class that is the value of the association on
	 top of stack. The arguments  of the message are found in the top numArgs
	 stack locations beneath the association, and the receiver just below them."
]

{ #category : #'*BytecodeSets-instruction decoding' }
InstructionClient >> doNop [
	"Do nothing"


]

{ #category : #'*BytecodeSets-NewsqueakV3-decoding' }
InstructionClient >> pushExplicitOuter: n [ "<Integer>"
	"Push the enclosing object at level n."
]

{ #category : #'*BytecodeSets-NewsqueakV4-decoding' }
InstructionClient >> sendToAbsentDynamicSuperclass: selector "<Symbol>" numArgs: arity [ "<SmallInteger>"
	"Send Message With Selector, selector to the dynamic superclass.
	 The arguments of the message are found in the top numArgs locations
	 on the stack and the receiver is implicitly the receiver of the current method activation."
]

{ #category : #'*BytecodeSets-SistaV1-decoding' }
InstructionClient >> trapIfNotInstanceOf: behaviorOrArrayOfBehavior [
	"If the top of stack is not an instance of either the argument, or, if the argument is an Array,
	  any of the elements of the argument, send the class trap message to the current context."
]
