"
An encoder for the Newsqueak V3 bytecode set.  It adds the following bytecodes that are part of the first Newspeak bytecode set.

	127 	01111111 kkkkkkkk 		Push Implicit Receiver For Selector (self literalAt: kkkkkkkk)
	126 	01111110 jjjjjjjj kkkkkkkk 	Send Selector (self literalAt: kkkkkkkk) To Dynamic Superclass With NumArgs jjjjjjjj
	139	01000101 kkkkkkkk		Push Explicit Outer Receiver For Level (self literalAt: kkkkkkkk)
"
Class {
	#name : #EncoderForNewsqueakV3,
	#superclass : #EncoderForV3PlusClosures,
	#category : #'BytecodeSets-NewsqueakV3'
}

{ #category : #'instruction stream support' }
EncoderForNewsqueakV3 class >> bytecodeSize: bytecode [
	"Answer the number of bytes in the bytecode."
	bytecode <= 125 ifTrue:
		[^1].
	bytecode >= 176 ifTrue:
		[^1].
	bytecode >= 160 ifTrue: "long jumps"
		[^2].
	bytecode >= 144 ifTrue: "short jumps"
		[^1].
	"126, 127 & extensions"
	^#(3 2 2 2 2 2 3 2 2 1 1 1 2 2 3 3 3 4) at: bytecode - 125
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV3 class >> interpretNextInstructionFor: aClient in: anInstructionStream [
	"Double-dispatch through the encoder to select the correct instruction set decoder."
	^anInstructionStream interpretNextNSV3InstructionFor: aClient
]
