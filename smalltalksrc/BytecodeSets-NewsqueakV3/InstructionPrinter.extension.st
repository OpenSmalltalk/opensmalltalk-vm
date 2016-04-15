Extension { #name : #InstructionPrinter }

{ #category : #'*BytecodeSets-instruction decoding' }
InstructionPrinter >> blockReturnConstant: value [ 
	"Print the Return Constant From Block bytecode."

	self print: 'blockReturn: ', value printString
]

{ #category : #'*BytecodeSets-instruction decoding' }
InstructionPrinter >> callInlinePrimitive: index [
	"Print the callInlinePrimitive."

	self print: 'callInlinePrimitive: ' , index printString
]

{ #category : #'*BytecodeSets-instruction decoding' }
InstructionPrinter >> directedSuperSend: selector "<Symbol>" numArgs: numArgs [ "<SmallInteger>"
	self print: 'directedSuperSend: ' , (self stringForSelector: selector numArgs: numArgs)
]

{ #category : #'*BytecodeSets-SistaV1-decoding' }
InstructionPrinter >> pushClosureTemps: numTemps [
	self print: 'pushClosureTemps: ', numTemps printString
]

{ #category : #'*BytecodeSets-NewsqueakV3-decoding' }
InstructionPrinter >> pushExplicitOuter: n [ 
	"Print the Push the Active Context's Receiver for an outer send at level (method literalAt: litIndex) bytecode."

	self print: 'pushExplicitOuter: ', n asString
]

{ #category : #'*BytecodeSets-instruction decoding' }
InstructionPrinter >> pushFullClosure: cb numCopied: num [
	self print: 'pushFullClosure: ' , cb selector , ' numCopied: ' , num
]

{ #category : #'*BytecodeSets-NewsqueakV3-decoding' }
InstructionPrinter >> pushImplicitReceiverForMessage: aSymbol [ 
	"Print the Push Active Context's Receiver for an outer send of aSymbol on Top Of Stack bytecode."

	self print: 'pushImplicitReceiverFor: ', aSymbol asString
]

{ #category : #'*BytecodeSets-NewsqueakV4-decoding' }
InstructionPrinter >> sendToAbsentDynamicSuperclass: selector "<Symbol>" numArgs: numArgs [ "<SmallInteger>"
	self print: '(absent receiver) dynamicSuperSend: ' , (self stringForSelector: selector numArgs: numArgs)
]

{ #category : #'*BytecodeSets-NewsqueakV4-decoding' }
InstructionPrinter >> sendToAbsentImplicitReceiver: selector "<Symbol>" numArgs: arity [ "<SmallInteger>"
	self print: '(absent receiver) implicitReceiverSend: ', selector
]

{ #category : #'*BytecodeSets-SistaV1-decoding' }
InstructionPrinter >> trapIfNotInstanceOf: behaviorOrArrayOfBehavior [
	"If the top of stack is not an instance of either the argument, or, if the argument is an Array,
	  any of the elements of the argument, send the class trap message to the current context."
	self print: 'trapIfNotInstanceOf: ', behaviorOrArrayOfBehavior printString
]
