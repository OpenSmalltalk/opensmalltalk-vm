Extension { #name : #InstructionPrinter }

{ #category : #'*BytecodeSets-instruction decoding' }
InstructionPrinter >> blockReturnConstant: value [ 
	"Print the Return Constant From Block bytecode."

	self print: 'blockReturn: ', value printString
]

{ #category : #'*BytecodeSets-SistaV1-decoding' }
InstructionPrinter >> branchIfNotInstanceOf: behaviorOrArrayOfBehavior distance: distance [
	"If the object on top of stack has the type -or one of the type- present in the literal
	 (the literal is a behavior or an array of behavior), then pop it. Else jumps by the distance."
	self print: 'branchIfNotInstanceOf: ', behaviorOrArrayOfBehavior printString, ' distance: ', distance printString
]

{ #category : #'*BytecodeSets-instruction decoding' }
InstructionPrinter >> callInlinePrimitive: index [
	"Print the callInlinePrimitive."
	self print: 'callInlinePrimitive: ' , ((#((1000 ' class')
										(1001 ' pointer numSlots')
										(1002 ' pointer basicSize')
										(1003 ' byte8Type format numBytes')
										(1004 ' short16Type format numSho')
										(1005 ' word32Type format numWord')
										(1006 ' doubleWord64Type format n')

										(1010 ' ensure number of bytes available')
										(1011 ' fixed pointer basicNew')

										(1020 ' identityHash (non-immediate, non-Behavior, has hash)')
										(1021 ' identityHash (SmallInteger)')
										(1022 ' identityHash (Character)')
										(1023 ' identityHash (SmallFloat64)')
										(1024 ' identityHash (Behavior, has hash?)')

										(1030 ' immediateAsInteger (Character)')
										(1031 ' immediateAsInteger (SmallFloat64)')

										(2000 ' SmallInteger #+')
										(2001 ' SmallInteger #-')
										(2002 ' SmallInteger #*')
										(2003 ' SmallInteger #/')
										(2004 ' SmallInteger #//')
										(2005 ' SmallInteger #\\')
										(2006 ' SmallInteger #quo:')

										(2011 ' Variable-sized pointers new (new:). Array, etc')
										(2012 ' Variable-sized byte new (new:). ByteArray, ByteString, etc')
										(2013 ' Variable-sized 16-bit new (new:). DoubleByteArray, etc')
										(2014 ' Variable-sized 32-bit new (new:). Bitmap, FloatArray, etc')
										(2015 ' Variable-sized 64-bit new (new:). DoubleWordArray, etc')

										(2016 ' SmallInteger #bitAnd:')
										(2017 ' SmallInteger #bitOr:')
										(2018 ' SmallInteger #bitXor:')
										(2019 ' SmallInteger #bitShiftLeft:')
										(2019 ' SmallInteger #bitShiftRight:')

										(2032 ' SmallInteger #>')
										(2033 ' SmallInteger #<')
										(2034 ' SmallInteger #>=')
										(2035 ' SmallInteger #<=')
										(2036 ' SmallInteger #=')
										(2037 ' SmallInteger #~=')

										(2064 ' Pointer Object>>at:')
										(2065 ' Byte Object>>at:')
										(2066 ' 16-bit Word Object>>at:')
										(2067 ' Word Object>>at:')
										(2068 ' DoubleWord Object>>at:')
										(2069 ' QuadWord Object>>at:')

										(3000 ' Pointer Object>>at:put:')
										(3001 ' Byte Object>>at:put:')
										(3002 ' Word Object>>at:put:')
										(3003 ' DoubleWord Object>>at:put')
										(3004 ' QuadWord Object>>at:put:'))
											detect: [:tuple| tuple first = index]
											ifNone: [{index printString}]) last)
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
