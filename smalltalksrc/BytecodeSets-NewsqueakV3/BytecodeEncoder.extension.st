Extension { #name : #BytecodeEncoder }

{ #category : #'*BytecodeSets-opcode sizing' }
BytecodeEncoder >> sizeCallInlinePrimitive: primitiveIndex [
	^self sizeOpcodeSelector: #genCallInlinePrimitive: withArguments: {primitiveIndex}
]

{ #category : #'*BytecodeSets-opcode sizing' }
BytecodeEncoder >> sizeSendAbsentDynamicSuperclass: selectorLiteralIndex numArgs: numArgs [
	^self sizeOpcodeSelector: #genSendAbsentDynamicSuper:numArgs: withArguments: {selectorLiteralIndex. numArgs}
]

{ #category : #'*BytecodeSets-opcode sizing' }
BytecodeEncoder >> sizeSendAbsentImplicit: selectorLiteralIndex numArgs: numArgs [
	^self sizeOpcodeSelector: #genSendAbsentImplicit:numArgs: withArguments: {selectorLiteralIndex. numArgs}
]

{ #category : #'*BytecodeSets-opcode sizing' }
BytecodeEncoder >> sizeSendDirectedSuper: selectorLiteralIndex numArgs: numArgs [
	^self sizeOpcodeSelector: #genSendDirectedSuper:numArgs: withArguments: {selectorLiteralIndex. numArgs}
]

{ #category : #'*BytecodeSets-opcode sizing' }
BytecodeEncoder >> sizeSendImplicit: selectorLiteralIndex numArgs: numArgs [
	^self sizeOpcodeSelector: #genSendImplicit:numArgs: withArguments: {selectorLiteralIndex. numArgs}
]

{ #category : #'*BytecodeSets-opcode sizing' }
BytecodeEncoder >> sizeTrapIfNotInstanceOf: litIndex [
	^self sizeOpcodeSelector: #genTrapIfNotInstanceOf: withArguments: {litIndex}
]

{ #category : #'*BytecodeSets-bytecode decoding' }
BytecodeEncoder class >> stackDeltaForPrimitive: primitiveIndex in: method [
	"This is the default implementation.  Subclasses with inline primitives will need to override."
	^0
]
