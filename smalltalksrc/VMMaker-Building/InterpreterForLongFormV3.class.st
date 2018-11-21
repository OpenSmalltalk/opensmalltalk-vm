"
I interpret only the long-form bytecodes, making room for lots of additional bytecodes.



Misc notes:
 I do not need to reimplement booleanCheat: to only check for long jumps since it only gets called by the inlined arithmetic primitives which I don't implement.
"
Class {
	#name : #InterpreterForLongFormV3,
	#superclass : #Interpreter,
	#category : #'VMMaker-Interpreter'
}

{ #category : #initialization }
InterpreterForLongFormV3 class >> initializeBytecodeTable [
	"Interpreter initializeBytecodeTable"
	"Note: This table will be used to generate a C switch statement."

	BytecodeTable := Array new: 256.
	self table: BytecodeTable from:
	#(
		(  0  111 unknownBytecode)

		(112 pushReceiverBytecode)
		(113 pushConstantTrueBytecode)
		(114 pushConstantFalseBytecode)
		(115 pushConstantNilBytecode)
		(116 pushConstantMinusOneBytecode)
		(117 pushConstantZeroBytecode)
		(118 pushConstantOneBytecode)
		(119 pushConstantTwoBytecode)
		(120 returnReceiver)
		(121 returnTrue)
		(122 returnFalse)
		(123 returnNil)
		(124 returnTopFromMethod)
		(125 returnTopFromBlock)

		(126 127 unknownBytecode)

		(128 extendedPushBytecode)
		(129 extendedStoreBytecode)
		(130 extendedStoreAndPopBytecode)
		(131 singleExtendedSendBytecode)
		(132 doubleExtendedDoAnythingBytecode)
		(133 singleExtendedSuperBytecode)
		(134 secondExtendedSendBytecode)
		(135 popStackBytecode)
		(136 duplicateTopBytecode)

		(137 pushActiveContextBytecode)
		(138 pushNewArrayBytecode)
		(139 unknownBytecode)
		(140 pushRemoteTempLongBytecode)
		(141 storeRemoteTempLongBytecode)
		(142 storeAndPopRemoteTempLongBytecode)
		(143 pushClosureCopyCopiedValuesBytecode)

		(144 159 unknownBytecode)

		(160 167 longUnconditionalJump)
		(168 171 longJumpIfTrue)
		(172 175 longJumpIfFalse)

		"176-255 were send bytecodes"
		(176 255 unknownBytecode)
	).
]

{ #category : #accessing }
InterpreterForLongFormV3 class >> sourceFileName [
	"Answer the filename for the core interpreter"

	^'interp-lfv3.c'
]
