Extension { #name : #BytecodeEncoder }

{ #category : #'*BytecodeSets-opcode sizing' }
BytecodeEncoder >> sizeTrapIfNotInstanceOf: litIndex [
	^self sizeOpcodeSelector: #genTrapIfNotInstanceOf: withArguments: {litIndex}
]

{ #category : #'*BytecodeSets-bytecode decoding' }
BytecodeEncoder class >> stackDeltaForPrimitive: primitiveIndex in: method [
	"This is the default implementation.  Subclasses with inline primitives will need to override."
	^0
]
