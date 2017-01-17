"
EncoderForNewsqueakV4 encodes a bytecode set for Squeak and Newspeak that lifts limits on number of literals and branch distances, has a single bytecode for send to implicit receiver and extended push integer and push character bytecodes.  Byteodes are ordered by length to make decoding easier.  Bytecodes marked with an * are extensible via a prefix bytecode.

N.B.  Extension bytecodes can only come before extensible bytecodes, and only if valid (one cannot extend a bytecode extensible by Ext A with an Ext B).  An extensible bytecode consumes (and zeros) its extension(s).  Hence the hidden implicit variables holding extensions are always zero except after a valid sequence of extension bytecodes.

1 Byte Bytecodes
	0-15		0000 i i i i 		Push Receiver Variable #iiii
	16-31		0001 i i i i		Push Literal Variable #iiii
	32-63		001 i i i i i		Push Literal #iiiii
	64-71		01000 i i i		Push Temporary Variable #iii
	72-75		010010 i i		Push Temporary Variable #ii + 8
	76			01001100		Push Receiver
*	77			01001101		Push false [* 1:true, 2:nil, 3:thisContext, ..., -N: pushExplicitOuter: N, N = Extend B]
	78			01001110		Push 0
	79			01001111		Push 1
	80-95		0101 i i i i		Send Arithmetic Message #iiii
	96-111		0110 i i i i		Send Special Message #iiii
	112-127	0111 i i i i		Send Literal Selector #iiii With 0 Arguments
	128-143	1000 i i i i		Send Literal Selector #iiii With 1 Argument
	144-159	1001 i i i i		Send Literal Selector #iiii With 2 Arguments
	160-175	1010 i i i i		Send To Absent Implicit Receiver Literal Selector #iiii With 0 Arguments
	176-183	10110 i i i		Pop and Store Receiver Variable #iii
	184-191	10111 i i i		Pop and Store Temporary Variable #iii
	192-199	11000 i i i		Jump iii + 1 (i.e., 1 through 8)
	200-207	11001 i i i		Pop and Jump 0n True iii +1 (i.e., 1 through 8)
	208-215	11010 i i i		Pop and Jump 0n False iii +1 (i.e., 1 through 8)
	216		11011000		Return Receiver From Message
	217		11011001		Return Stack Top From Message
*	218		11011010		Return Stack Top From Block [* return from enclosing block N, N = Extend A]
	219		11011011		Duplicate Stack Top
	220		11011100		Pop Stack Top
*	221		11011101		Nop
	222		11011110		break ?  could have blockCopy: send break, but need pushReceiver & pop result
	223		11011111		UNASSIGNED

2 Byte Bytecodes
*	224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)
*	225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)
*	226		11100010	i i i i i i i i	Push Receiver Variable #iiiiiiii (+ Extend A * 256)
*	227		11100011	i i i i i i i i	Push Literal Variable #iiiiiiii (+ Extend A * 256)
*	228		11100100	i i i i i i i i	Push Literal #iiiiiiii (+ Extend A * 256)
*	229		11100101	i i i i i i i i	Push Integer #iiiiiiii (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)
	230		11100110	i i i i i i i i	Push Temporary Variable #iiiiiiii
	231		11100111	jkkkkkkk	Push (Array new: kkkkkkk) (j = 0)
									&	Pop kkkkkkk elements into: (Array new: kkkkkkk) (j = 1)
*	232		11101000	i i i i i i i i	Store Receiver Variable #iiiiiii (+ Extend A * 256)
*	233		11101001	i i i i i i i i	Store Literal Variable #iiiiiiii (+ Extend A * 256)
	234		11101010	i i i i i i i i	Store Temporary Variable #iiiiiiii
*	235		11101011	i i i i i i i i	Pop and Store Receiver Variable #iiiiiii (+ Extend A * 256)
*	236		11101100	i i i i i i i i	Pop and Store Literal Variable #iiiiiiii (+ Extend A * 256)
	237		11101101	i i i i i i i i	Pop and Store Temporary Variable #iiiiiiii
**	238		11101110	i i i i i j j j	Send Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
**	239		11101111	i i i i i j j j	Send To Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
**	240		11110000	i i i i i j j j	Send To Absent Implicit Receiver Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
**	241		11110001	i i i i i j j j	Send To Absent Dynamic Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
*	242		11110010	i i i i i i i i	Jump i i i i i i i i (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)
*	243		11110011	i i i i i i i i	Pop and Jump 0n True i i i i i i i i (+ Extend B * 256, where Extend B >= 0)
*	244		11110100	i i i i i i i i	Pop and Jump 0n False i i i i i i i i (+ Extend B * 256, where Extend B >= 0)

	245		11110101	xxxxxxxx	UNASSIGNED
	246-247	1111011 i	xxxxxxxx	UNASSIGNED
	248		11111000	xxxxxxxx	UNASSIGNED

3 Byte Bytecodes
	249		11111001	i i i i i i i i	jjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjjj * 256)
	250		11111010 kkkkkkkk	jjjjjjjj		Push Temp At kkkkkkkk In Temp Vector At: jjjjjjjj
	251		11111011 kkkkkkkk	jjjjjjjj		Store Temp At kkkkkkkk In Temp Vector At: jjjjjjjj
	252		11111100 kkkkkkkk	jjjjjjjj		Pop and Store Temp At kkkkkkkk In Temp Vector At: jjjjjjjj
**	253		11111101 eei i i kkk	jjjjjjjj		Push Closure Num Copied iii (+ Ext A // 16 * 8) Num Args kkk (+ Ext A \\ 16 * 8) BlockSize jjjjjjjj (+ Ext B * 256). ee = num extensions

	254-255	1111111 i	xxxxxxxx	yyyyyyyy	UNASSIGNED
"
Class {
	#name : #EncoderForNewsqueakV4,
	#superclass : #BytecodeEncoder,
	#category : #'BytecodeSets-NewsqueakV4'
}

{ #category : #'compiled method support' }
EncoderForNewsqueakV4 class >> bindingReadScanBlockFor: litVarIndex using: scanner [
	"Answer a block argument for InstructionStream>>scanFor: that answers true
	 for reads of the value of the binding with zero-relative index litVarIndex.
	 N.B. Don't assume the compiler uses the most compact encoding available."

	"	16-31		0001 i i i i				Push Literal Variable #iiii
	 *	224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)
	 *	227		11100011	i i i i i i i i	Push Literal Variable #iiiiiiii (+ Extend A * 256)"
	| extension |
	extension := 0.
	^[:b| | prevext |
	   prevext := extension.
	   extension := b = 224 ifTrue: [scanner followingByte bitShift: 8] ifFalse: [0].
	   (b < 32 and: [b >= 16 and: [b - 16 = litVarIndex]])
	    or: [b = 227
			and: [scanner followingByte + prevext = litVarIndex]]]
]

{ #category : #'compiled method support' }
EncoderForNewsqueakV4 class >> bindingWriteScanBlockFor: litVarIndex using: scanner [
	"Answer a block argument for InstructionStream>>scanFor: that answers true
	 for writes of the value of the binding with zero-relative index litVarIndex.
	 N.B. Don't assume the compiler uses the most compact encoding available."

	"*	224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)
	 *	233		11101001	i i i i i i i i	Store Literal Variable #iiiiiiii (+ Extend A * 256)
	 *	236		11101100	i i i i i i i i	Pop and Store Literal Variable #iiiiiiii (+ Extend A * 256)"
	| extension |
	extension := 0.
	^[:b| | prevext |
	   prevext := extension.
	   extension := b = 224 ifTrue: [scanner followingByte bitShift: 8] ifFalse: [0].
	   (b = 233 or: [b = 236])
	   and: [scanner followingByte + prevext = litVarIndex]]
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> bytecodeSize: bytecode [
	"Answer the number of bytes in the bytecode."
	bytecode < 224 ifTrue: [^1].
	bytecode < 249 ifTrue: [^2].
	^3
]

{ #category : #'bytecode decoding' }
EncoderForNewsqueakV4 class >> callPrimitiveCode [
	"Answer the call primitive bytecode, if it exists in the encoder's bytecode set, or nil if not.
	 249		11111001	i i i i i i i i	jjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjjj * 256)"
	^249
]

{ #category : #'compiled method support' }
EncoderForNewsqueakV4 class >> createClosureScanBlock [
	"Answer a block argument for InstructionStream>>scanFor: that answers true
	 for block closure creation bytecodes.  ote that with this interface we can't answer
	 true for the extension in front of a push closure bytecode and so the interface may
	 have to change at some point."

	"*	224	11100000	aaaaaaaa			Extend A (Ext A = Ext A prev * 256 + Ext A)
	 *	225	11100001	sbbbbbbb			Extend B (Ext B = Ext B prev * 256 + Ext B)
	 **	253	11111101 eei i i kkk	jjjjjjjj	Push Closure Num Copied iii (+ Ext A // 16 * 8) Num Args kkk (+ Ext A \\ 16 * 8) BlockSize jjjjjjjj (+ Ext B * 256). ee = num extensions"
	^[:b| b = 253]
]

{ #category : #'compiled method support' }
EncoderForNewsqueakV4 class >> extensionsAt: bcpc in: method into: aTrinaryBlock [
	"If the bytecode at pc is an extension then evaluate aBinaryBlock with the values of extA and extB and number of extension *bytes*.
	 If the bytecode at pc is not extended then evaluate aBinaryBlock with 0 and 0.
	224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)
	225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)"
 
	| scanpc byte extByte extA extB |
	scanpc := bcpc.
	"There may be an extension (it could be a false positive).  We must scan as fast as possible..."
	extA := extB := 0.
	[byte := method at: scanpc.
	 byte >= 224 and: [byte <= 225]] whileTrue: 
		[extByte := method at: scanpc + 1.
		 scanpc := scanpc + 2.
		 byte = 224
			ifTrue:
				[extA := (extA bitShift: 8) + extByte]
			ifFalse:
				[extB := (extB = 0 and: [extByte > 127])
					ifTrue: [extByte - 256]
					ifFalse: [(extB bitShift: 8) + extByte]]].
	^aTrinaryBlock value: extA value: extB value: scanpc - bcpc


"Why use
	byte >= 224 and: [byte <= 225]
 and not
	(byte bitAnd: 16rFE) = 16rE0
 ?
 | n |
 n := 100000000.
 #(0 224) collect:
	[:byte|
	{ Time millisecondsToRun: [1 to: n do: [:i| (byte >= 224 and: [byte <= 225]) ifTrue: []]].
	   Time millisecondsToRun: [1 to: n do: [:i| (byte bitAnd: 16rFE) = 16rE0 ifTrue: []]] }] #(#(297 599) #(702 671))"
]

{ #category : #'compiled method support' }
EncoderForNewsqueakV4 class >> instVarReadScanBlockFor: varIndexCode using: scanner [
	"Answer a block argument for InstructionStream>>scanFor: that answers true
	 for reads of the inst var with zero-relative index varIndexCode.
	 N.B. Don't assume the compiler uses the most compact encoding available."

	"	0-15		0000 i i i i 				Push Receiver Variable #iiii
	*	224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)
	*	226		11100010	i i i i i i i i	Push Receiver Variable #iiiiiiii (+ Extend A * 256)"
	| extension |
	extension := 0.
	^[:b| | prevext |
	   prevext := extension.
	   extension := b = 224 ifTrue: [scanner followingByte bitShift: 8] ifFalse: [0].
	   (b < 16 and: [b = varIndexCode])
	    or: [b = 226
			and: [scanner followingByte + prevext = varIndexCode]]]
]

{ #category : #'compiled method support' }
EncoderForNewsqueakV4 class >> instVarWriteScanBlockFor: varIndexCode using: scanner [
	"Answer a block argument for InstructionStream>>scanFor: that answers true
	 for writes of the inst var with zero-relative index varIndexCode.
	 N.B. Don't assume the compiler uses the most compact encoding available."

	"	176-183	10110 i i i				Pop and Store Receiver Variable #iii
	*	224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)
	*	232		11101000	i i i i i i i i	Store Receiver Variable #iiiiiii (+ Extend A * 256)
	*	235		11101011	i i i i i i i i	Pop and Store Receiver Variable #iiiiiii (+ Extend A * 256)"
	| extension |
	extension := 0.
	^[:b| | prevext |
	   prevext := extension.
	   extension := b = 224 ifTrue: [scanner followingByte bitShift: 8] ifFalse: [0].
	   (b >= 176
	    and: [b < 184
	    and: [b - 176 = varIndexCode]])
	   or: [(b = 232 or: [b = 235])
		  and: [scanner followingByte + prevext = varIndexCode]]]
]

{ #category : #'compiled method support' }
EncoderForNewsqueakV4 class >> interpretJumpIfCondIn: anInstructionStream [
	"Double-dispatch through the encoder to select the correct conditional jump decoder for the instruction set."
	^anInstructionStream interpretNSV4JumpIfCond
]

{ #category : #'compiled method support' }
EncoderForNewsqueakV4 class >> interpretJumpIn: anInstructionStream [
	"Double-dispatch through the encoder to select the correct unconditional jump decoder for the instruction set."
	^anInstructionStream interpretNSV4Jump
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> interpretNextInstructionFor: aClient in: anInstructionStream [
	"Double-dispatch through the encoder to select the correct instruction set decoder."
	^anInstructionStream interpretNextNSV4InstructionFor: aClient
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> isBlockReturnAt: pc in: method [
	"Answer whether the bytecode at pc is a return from block."
	"218		11011010		Return Stack Top From Block [* return from enclosing block N, N = Extend A]"
	^(self nonExtensionBytecodeAt: pc in: method) = 218
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> isBranchIfFalseAt: pc in: method [
	"Answer whether the bytecode at pc is a conditional branch-if-false."

	"	208-215	11010 i i i				Pop and Jump 0n False iii +1 (i.e., 1 through 8)
	 *	244		11110100	i i i i i i i i	Pop and Jump 0n False i i i i i i i i (+ Extend B * 256, where Extend B >= 0)"
	| byte |
	byte := self nonExtensionBytecodeAt: pc in: method.
	^byte >= 208 and: [byte <= 215 or: [byte = 244]]
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> isBranchIfTrueAt: pc in: method [
	"Answer whether the bytecode at pc is a conditional branch-if-true."

	"	200-207	11001 i i i				Pop and Jump 0n True iii +1 (i.e., 1 through 8)
	 *	243		11110011	i i i i i i i i	Pop and Jump 0n True i i i i i i i i (+ Extend B * 256, where Extend B >= 0)"
	| byte |
	byte := self nonExtensionBytecodeAt: pc in: method.
	^byte >= 200 and: [byte <= 207 or: [byte = 243]]
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> isExtension: bytecode [
	"Answer if the bytecode is an extension bytecode, i.e. one that extends
	 the range of the following bytecode."
	^bytecode >= 16rE0 and: [bytecode <= 16rE1]
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> isJumpAt: pc in: method [
	"Answer whether the bytecode at pc is an (unconditional) jump."

	"	192-199	11000 i i i				Jump iii + 1 (i.e., 1 through 8)
	 *	225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)
	 *	242		11110010	i i i i i i i i	Jump i i i i i i i i (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	| byte |
	byte := self nonExtensionBytecodeAt: pc in: method.
	^byte >= 192 and: [byte <= 199 or: [byte = 242]]
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> isJustPopAt: pc in: method [
	"Answer whether the bytecode at pc is a pop."

	^(method at: pc) = 220 "220		11011100		Pop Stack Top"
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> isRealSendAt: pc in: method [
	"Answer whether the bytecode at pc is a real message-send, not blockCopy:."

	^self isSendAt: pc in: method
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> isReturnAt: pc in: method [
	"Answer whether the bytecode at pc is a return from block."
	"216		11011000		Return Receiver From Message
	 217		11011001		Return Stack Top From Message
	 218		11011010		Return Stack Top From Block [* return from enclosing block N, N = Extend A]"
	^(self nonExtensionBytecodeAt: pc in: method) between: 216 and: 218
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> isReturnTopFromMethodAt: pc in: method [
	"Answer whether the bytecode at pc is a return stack top from method."

	^(method at: pc) = 217
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> isSendAt: pc in: method [
	"Answer whether the bytecode at pc is a message-send."

	"	80-95		0101 i i i i		Send Arithmetic Message #iiii
		96-111		0110 i i i i		Send Special Message #iiii
		112-127	0111 i i i i		Send Literal Selector #iiii With 0 Arguments
		128-143	1000 i i i i		Send Literal Selector #iiii With 1 Argument
		144-159	1001 i i i i		Send Literal Selector #iiii With 2 Arguments
		160-175	1010 i i i i		Send To Absent Implicit Receiver Literal Selector #iiii With 0 Arguments
	 *	224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)
	 *	225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)
	 **	238		11101110	i i i i i j j j	Send Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
	 **	239		11101111	i i i i i j j j	Send To Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
	 **	240		11110000	i i i i i j j j	Send To Absent Implicit Receiver Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
	 **	241		11110001	i i i i i j j j	Send To Absent Dynamic Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
	 **	245		11110101	i i i i i j j j	Send To Absent Self Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
	 ** 254	 		11111110	i i i i i j j j	kkkkkkkk	Send To Absent Outer Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments Depth kkkkkkkk"
	| byte |
	byte := self nonExtensionBytecodeAt: pc in: method.
	^(((byte >= 80 and: [byte <= 175])
		or: [byte <= 241 and: [byte >= 238]])
		or: [byte == 245] or: [byte == 254])
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> isStoreAt: pc in: method [
	"Answer whether the bytecode at pc is a store or store-pop."

	"	176-183	10110 i i i						Pop and Store Receiver Variable #iii
		184-191	10111 i i i						Pop and Store Temporary Variable #iii
	 *	224		11100000	aaaaaaaa			Extend A (Ext A = Ext A prev * 256 + Ext A)
	 *	232		11101000	i i i i i i i i			Store Receiver Variable #iiiiiii (+ Extend A * 256)
	 *	233		11101001	i i i i i i i i			Store Literal Variable #iiiiiiii (+ Extend A * 256)
		234		11101010	i i i i i i i i			Store Temporary Variable #iiiiiiii
	 *	235		11101011	i i i i i i i i			Pop and Store Receiver Variable #iiiiiii (+ Extend A * 256)
	 *	236		11101100	i i i i i i i i			Pop and Store Literal Variable #iiiiiiii (+ Extend A * 256)
		237		11101101	i i i i i i i i			Pop and Store Temporary Variable #iiiiiiii
		251		11111011 kkkkkkkk	jjjjjjjj	Store Temp At kkkkkkkk In Temp Vector At: jjjjjjjj
		252		11111100 kkkkkkkk	jjjjjjjj	Pop and Store Temp At kkkkkkkk In Temp Vector At: jjjjjjjj"

	| byte |
	byte := self nonExtensionBytecodeAt: pc in: method.
	^byte >= 176
	  and: [byte <= 191
		 or: [(byte between: 232 and: 237)
		 or: [(byte between: 251 and: 252)]]]
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> isStorePopAt: pc in: method [
	"Answer whether the bytecode at pc is a store-pop."

	"	176-183	10110 i i i						Pop and Store Receiver Variable #iii
		184-191	10111 i i i						Pop and Store Temporary Variable #iii
	 *	224		11100000	aaaaaaaa			Extend A (Ext A = Ext A prev * 256 + Ext A)
	 *	235		11101011	i i i i i i i i			Pop and Store Receiver Variable #iiiiiii (+ Extend A * 256)
	 *	236		11101100	i i i i i i i i			Pop and Store Literal Variable #iiiiiiii (+ Extend A * 256)
		237		11101101	i i i i i i i i			Pop and Store Temporary Variable #iiiiiiii
		252		11111100 kkkkkkkk	jjjjjjjj	Pop and Store Temp At kkkkkkkk In Temp Vector At: jjjjjjjj"

	| byte |
	byte := self nonExtensionBytecodeAt: pc in: method.
	^byte >= 176
	  and: [byte <= 191
		 or: [(byte between: 235 and: 237)
		 or: [byte = 252]]]
]

{ #category : #scanning }
EncoderForNewsqueakV4 class >> method: method refersInBytecodeToLiteral: aLiteral specialSelectorIndex: specialOrNil [
	"Answer if method refers to the literal aLiteral in the bytecode, as opposed to in its literal frame."

	"*	77			01001101				Push false [* 1:true, 2:nil, 3:thisContext, ..., -N: pushExplicitOuter: N, N = Extend B]
		78			01001110				Push 0
		79			01001111				Push 1
		80-95		0101 i i i i				Send Arithmetic Message #iiii
		96-111		0110 i i i i				Send Special Message #iiii
	 *	225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)
	 *	229		11100101	i i i i i i i i	Push Integer #iiiiiiii (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	| byte extended scanner |
	specialOrNil ifNotNil:
		[byte := specialOrNil + 79.
		^(InstructionStream on: method) scanFor: [:b| b = byte]].
	extended := false.
	aLiteral isInteger ifTrue:
		[(aLiteral >= -32768 and: [aLiteral <= 32767]) ifFalse: [^false].
		 scanner := InstructionStream on: method.
		 (aLiteral >= 0 and: [aLiteral <= 255]) ifTrue:
			[aLiteral <= 1 ifTrue:
				[byte := aLiteral + 80.
				 ^scanner scanFor: [:b| b = byte]].
			 ^scanner scanFor:
				[:b|
				(b = 229
				 and: [extended not
				 and: [scanner followingByte = aLiteral]])
				or: [extended := b = 225.
					false]]].
		 byte := (aLiteral bitShift: -8) bitAnd: 255.
		^scanner scanFor:
			[:b|
			(b = 229
			 and: [extended
			 and: [scanner followingByte = (aLiteral bitAnd: 255)]])
			or: [extended := b = 225 and: [scanner followingByte = byte].
				false]]].
	byte := #(false true nil) identityIndexOf: aLiteral ifAbsent: 0.
	byte = 0 ifTrue:
		[^false].
	scanner := InstructionStream on: method.
	byte = 1 ifTrue:
		[^scanner scanFor:
			[:b|
			(b = 77
			 and: [extended not])
			or: [extended := b = 225.
				false]]].
	byte := byte - 1.
	^scanner scanFor:
		[:b|
		(b = 77
		 and: [extended])
		or: [extended := b = 225 and: [scanner followingByte = byte].
			false]]
]

{ #category : #scanning }
EncoderForNewsqueakV4 class >> method: method writesField: varIndex [
	"Answer if method stores into the instance variable indexed by varIndex.
	 N.B. Don't assume the compiler uses the most compact encoding available.
		176-183	10110 i i i				Pop and Store Receiver Variable #iii
	*	224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)
	*	232		11101000	i i i i i i i i	Store Receiver Variable #iiiiiii (+ Extend A * 256)
	*	235		11101011	i i i i i i i i	Pop and Store Receiver Variable #iiiiiii (+ Extend A * 256)"
	| varIndexCode scanner extension |
	method isQuick ifTrue: [^false].
	varIndexCode := varIndex - 1.
	extension := 0.
	^(scanner := InstructionStream on: method) scanFor:
		[:b| | prevext |
		prevext := extension.
		extension := b = 224 ifTrue: [scanner followingByte bitShift: 8] ifFalse: [0].
		b >= 176
		and: [b - 176 = varIndexCode
			  or: [(b = 232 or: [b = 235])
				  and: [scanner followingByte + prevext = varIndexCode]]]]
]

{ #category : #'bytecode decoding' }
EncoderForNewsqueakV4 class >> pcOfBlockCreationBytecodeForBlockStartingAt: startpc in: method [
	"Answer the pc of the push closure bytecode whose block starts at startpc in method.
	 May need to back up to include extension bytecodes.
	 253		11111101 eei i i kkk	jjjjjjjj		Push Closure Num Copied iii (+ Ext A // 16 * 8) Num Args kkk (+ Ext A \\ 16 * 8) BlockSize jjjjjjjj (+ Ext B * 256). ee = num extensions"
	| numExtensions |
	self assert: (method at: startpc - 3) = 253.
	numExtensions := (method at: startpc - 2) >> 6.
	^startpc - 3 - (numExtensions * 2)
]

{ #category : #'bytecode decoding' }
EncoderForNewsqueakV4 class >> pushClosureBytecodeSize [
	"Answer the size of the push closure bytecode.
	 253		11111101 eei i i kkk	jjjjjjjj		Push Closure Num Copied iii (+ Ext A // 16 * 8) Num Args kkk (+ Ext A \\ 16 * 8) BlockSize jjjjjjjj (+ Ext B * 256). ee = num extensions"
	^3
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> selectorToSendOrItselfFor: anInstructionStream in: method at: pc [
	"If anInstructionStream is at a send bytecode then answer the send's selector,
	 otherwise answer anInstructionStream itself.  The rationale for answering
	 anInstructionStream instead of, say, nil, is that potentially any existing object
	 can be used as a selector, but since anInstructionStream postdates the method,
	 it can't be one of them.

	 The compilcation is that for convenience we assume the pc could be
	 pointing to the raw send bytecode after its extensions, or at the extension
	 preceeding the raw send bytecode.
	80-95		0101 i i i i		Send Arithmetic Message #iiii
	96-111		0110 i i i i		Send Special Message #iiii
	112-127	0111 i i i i		Send Literal Selector #iiii With 0 Arguments
	128-143	1000 i i i i		Send Literal Selector #iiii With 1 Argument
	144-159	1001 i i i i		Send Literal Selector #iiii With 2 Arguments
	160-175	1010 i i i i		Send To Absent Implicit Receiver Literal Selector #iiii With 0 Arguments
	224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)
	225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)
	238		11101110	i i i i i j j j	Send Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
	239		11101111	i i i i i j j j	Send To Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
	240		11110000	i i i i i j j j	Send To Absent Implicit Receiver Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
	241		11110001	i i i i i j j j	Send To Absent Dynamic Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
	245		11110101	i i i i i j j j	Send To Absent Self Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
	254	 	11111110	i i i i i j j j	kkkkkkkk	Send To Absent Outer Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments Depth kkkkkkkk"

	| byte |
	byte := method at: pc.
	byte < 80 ifTrue:
		[^anInstructionStream].
	byte <= 175 ifTrue: 
		["special byte or short send"
		 ^byte >= 112
			ifTrue: [method literalAt: (byte bitAnd: 15) + 1]
			ifFalse: [Smalltalk specialSelectorAt: byte - 79]].
	byte < 238 ifTrue:
		[(byte >= 224 and: [byte <= 225]) ifTrue:
			[^self extensionsAt: pc in: method into:
				[:extA :extB :nExtBytes| | byteAfter index |
				byteAfter := method at: pc + nExtBytes.
				(byteAfter >= 238 and: [byteAfter <= 241])
					ifTrue:
						[index := ((method at: pc + nExtBytes + 1) bitShift: -3) + (extA bitShift: 5).
						 method literalAt: index + 1]
					ifFalse: [anInstructionStream]]].
		^anInstructionStream].
	(byte <= 241 or: [byte == 245 or: [byte == 254]])
		ifFalse: [^anInstructionStream].
	"they could be extended..."
	^self extensionsFor: pc in: method into:
		[:extA :extB :nExtBytes| | index |
		 index := ((method at: pc + 1) bitShift: -3) + (extA bitShift: 5).
		 method literalAt: index + 1]
]

{ #category : #'instruction stream support' }
EncoderForNewsqueakV4 class >> superSendScanBlockUsing: scanner [
	"Answer a block argument for InstructionStream>>scanFor:
	 that answers true for super sends."

	"*	224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)
	 *	225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)
	 **	239		11101111	i i i i i j j j	Send To Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments
	 **	241		11110001	i i i i i j j j	Send To Absent Dynamic Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
					
	^[:instr | instr = 239 or: [instr = 241]]
]

{ #category : #'compiled method support' }
EncoderForNewsqueakV4 class >> supportsClosures [
	"Answer if the instruction set supports closures (contains
	 closure creation and indirect temp access bytecodes)."

	^true
]

{ #category : #'bytecode decoding' }
EncoderForNewsqueakV4 class >> unusedBytecode [
	"Answer the opcode of a single-byte unused bytecode, if it exists in the encoder's bytecode set, or nil if not."
	^223
]

{ #category : #'method encoding' }
EncoderForNewsqueakV4 >> computeMethodHeaderForNumArgs: numArgs numTemps: numTemps numLits: numLits primitive: primitiveIndex accessModifier: accessModifier [
	numArgs > 15 ifTrue:
		[^self error: 'Cannot compile -- too many arguments'].
	numTemps > 63 ifTrue:
		[^self error: 'Cannot compile -- too many temporary variables'].
	numLits > 65535 ifTrue:
		[^self error: 'Cannot compile -- too many literals'].
	^(CompiledMethod headerFlagForEncoder: self)
	+ (accessModifier = #protected ifTrue: [1 bitShift: 29] ifFalse: [0])
	+ (accessModifier = #private ifTrue: [1 bitShift: 28] ifFalse: [0])
	+ (numArgs bitShift: 24)
	+ (numTemps bitShift: 18)
	"+ (largeBit bitShift: 17)" "largeBit gets filled in later"
	+ (primitiveIndex > 0 ifTrue: [1 bitShift: 16] ifFalse: [0])
	+ numLits
]

{ #category : #encoding }
EncoderForNewsqueakV4 >> encodeLiteral: object [
	| literal |
	literal := class literalScannedAs: object notifying: self.
	^(self isSpecialLiteral: literal)
		ifTrue:
			[SpecialLiteralNode new
				name: object
				key: literal
				index: nil
				type: LdLitType]
		ifFalse:
			[self
				name: object
				key: literal
				class: LiteralNode
				type: LdLitType
				set: litSet]
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genBranchPopFalse: distance [
	(distance > 0 and: [distance < 9]) ifTrue:
		["208-215	11010 i i i		Pop and Jump 0n False iii +1 (i.e., 1 through 8)"
		 stream nextPut: 207 + distance.
		 ^self].
	^self genBranchPopFalseLong: distance
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genBranchPopFalseLong: distance [
	"244		11110100	i i i i i i i i	Pop and Jump 0n False i i i i i i i i (+ Extend B * 256)"
	| distanceMod256 |
	(distance < 0 or: [distance > 32767]) ifTrue:
		[^self outOfRangeError: 'distance' index: distance range: 0 to: 32767].
	distanceMod256 := (distance < 0 or: [distance > 255])
								ifTrue:
									[self genUnsignedSingleExtendB: (distance bitShift: -8).
									 distance bitAnd: 255]
								ifFalse: [distance].
	stream
		nextPut: 244;
		nextPut: distanceMod256
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genBranchPopTrue: distance [
	(distance > 0 and: [distance < 9]) ifTrue:
		["200-207	11001 i i i		Pop and Jump 0n True iii +1 (i.e., 1 through 8)"
		 stream nextPut: 199 + distance.
		 ^self].
	^self genBranchPopTrueLong: distance
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genBranchPopTrueLong: distance [
	"243		11110011	i i i i i i i i	Pop and Jump 0n True i i i i i i i i (+ Extend B * 256)"
	| distanceMod256 |
	(distance < 0 or: [distance > 32767]) ifTrue:
		[^self outOfRangeError: 'distance' index: distance range: 0 to: 32767].
	(distance > 0 and: [distance < 9]) ifTrue:
		["200-207	11001 i i i		Pop and Jump 0n True iii +1 (i.e., 1 through 8)"
		 stream nextPut: 199 + distance.
		 ^self].
	distanceMod256 := (distance < 0 or: [distance > 255])
								ifTrue:
									[self genUnsignedSingleExtendB: (distance bitShift: -8).
									 distance bitAnd: 255]
								ifFalse: [distance].
	stream
		nextPut: 243;
		nextPut: distanceMod256
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genCallPrimitive: primitiveIndex [
	"249		11111001	i i i i i i i i	jjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjjj * 256)"
	"N.B. We could have made CallPrimitive a 2-byte code taking an extension, but that would
	 complicate the VM's determination of the primitive number and the primitive error code
	 store since the extension, being optional, would make the sequence variable length."
	(primitiveIndex < 1 or: [primitiveIndex > 65535]) ifTrue:
		[self outOfRangeError: 'primitive index' index: primitiveIndex range: 1 to: 65535].
	stream
		nextPut: 249;
		nextPut: (primitiveIndex bitAnd: 255);
		nextPut: (primitiveIndex bitShift: -8)
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genDup [
	"219		11011011		Duplicate Stack Top"
	stream nextPut: 219
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genExt1: aSmallInteger [ 
	self shouldBeImplemented
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genJump: distance [
	(distance > 0 and: [distance < 9]) ifTrue:
		["192-199	11000 i i i		Jump iii + 1 (i.e., 1 through 8)"
		 stream nextPut: 191 + distance.
		 ^self].
	"243		11110011	i i i i i i i i	Jump i i i i i i i i (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	^self genJumpLong: distance
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genJumpLong: distance [
	"242		11110010	i i i i i i i i	Jump i i i i i i i i (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	(distance between: -32768 and: 32767) ifFalse:
		[^self outOfRangeError: 'index' index: distance range: -32768 to: 32767].
	(distance < 0 or: [distance > 255]) ifTrue:
		[self genSignedSingleExtendB: (distance bitShift: -8)].
	stream
		nextPut: 242;
		nextPut: (distance bitAnd: 255)
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genNop [
	"221		11011101		Nop"
	stream nextPut: 221
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPop [
	"220		11011100		Pop Stack Top"
	stream nextPut: 220
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushClosureCopyNumCopiedValues: numCopied numArgs: numArgs jumpSize: jumpSize [
	"253		11111101 eeiiikkk		jjjjjjjj		Push Closure Num Copied iii (+ Ext A // 16 * 8) Num Args kkk (+ Ext A \\ 16 * 8) BlockSize jjjjjjjj (+ Ext B * 256). ee = num extensions"
	"Including numExtensions makes decoding the bytecode quicker since it obviates having to scan from the beginning of a method."
	| numExtensions numCopiedMod8 numArgsMod8 extA |
	(jumpSize < 0 or: [jumpSize > 65535]) ifTrue:
		[^self outOfRangeError: 'block size' index: jumpSize range: 0 to: 65535].
	(numCopied < 0 or: [numCopied > 127]) ifTrue:
		[^self outOfRangeError: 'num copied' index: numCopied range: 0 to: 127].
	(numArgs < 0 or: [numArgs > 127]) ifTrue:
		[^self outOfRangeError: 'num args' index: numArgs range: 0 to: 127].
	extA := numExtensions := 0.
	(numArgsMod8 := numArgs) > 7 ifTrue:
		[extA := numArgs // 8.
		 numArgsMod8 := numArgsMod8 \\ 8].
	(numCopiedMod8 := numCopied) > 7 ifTrue:
		[extA := extA + (numCopied // 8 * 16).
		 numCopiedMod8 := numCopiedMod8 \\ 8].
	extA ~= 0 ifTrue:
		[self genUnsignedSingleExtendA: extA.
		 numExtensions := 1].
	jumpSize > 255 ifTrue:
		[numExtensions := numExtensions + 1.
		 self genUnsignedSingleExtendB: jumpSize // 256].
	stream
		nextPut: 253;
		nextPut: (numExtensions bitShift: 6) + (numCopiedMod8 bitShift: 3) + numArgsMod8;
		nextPut: (jumpSize bitAnd: 16rFF)
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushConsArray: size [
	(size < 0 or: [size > 127]) ifTrue:
		[^self outOfRangeError: 'size' index: size range: 0 to: 127].
	"231		11100111	jkkkkkkk	Push (Array new: kkkkkkk) (j = 0)
									&	Pop kkkkkkk elements into: (Array new: kkkkkkk) (j = 1)"
	stream
		nextPut: 231;
		nextPut: size + 128
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushExplicitOuter: level [
	"77			01001101		Push false [* 1:true, 2:nil, 3:thisContext, ..., -N: pushExplicitOuter: N, N = Extend B]"
	(level > 0 and: [level <= 127]) ifTrue:
		[^self outOfRangeError: 'level' index: level range: 1 to: 127].
	self genSignedSingleExtendB: level negated.
	stream nextPut: 77
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushInstVar: instVarIndex [
	(instVarIndex between: 0 and: 15) ifTrue:
		["0-15 	0000iiii 	Push Receiver Variable #iiii"
		 stream nextPut: 0 + instVarIndex.
		 ^self].
	self genPushInstVarLong: instVarIndex
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushInstVarLong: instVarIndex [
	"226		11100010	i i i i i i i i	Push Receiver Variable #iiiiiiii (+ Extend A * 256)"
	"See also MaybeContextInstanceVariableNode"
	(instVarIndex < 0 or: [instVarIndex > 4095]) ifTrue:
		[^self outOfRangeError: 'index' index: instVarIndex range: 0 to: 4095].
	instVarIndex > 255 ifTrue:
		[self genUnsignedSingleExtendA: instVarIndex // 256].
	stream
		nextPut: 226;
		nextPut: instVarIndex \\ 256
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushInteger: anInteger [
	"78			01001110				Push 0
	 79			01001111				Push 1
	 229		11100101	i i i i i i i i	Push Integer #iiiiiiii (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	"Why restrict the range to 16 bits when we could encode arbitrarily large integers?
	 Well, 16 bits requires 4 bytes (extB + byte, 78 + byte) and so beyond this range we lose space
	 verses a single-byte pushLiteral and a 4 byte integer literal on 32-bits.  And generating the same
	 bytecode on 64-bit and 32-bit is important if we want to be able to load binary code from one to
	 the other (e.g. via Fuel)."
	anInteger = 0 ifTrue:
		[stream nextPut: 78.
		 ^self].
	anInteger = 1 ifTrue:
		[stream nextPut: 79.
		 ^self].
	(anInteger < -32768 or: [anInteger > 32767]) ifTrue:
		[^self outOfRangeError: 'integer' index: anInteger range: -32768 to: 32767].
	(anInteger < 0 or: [anInteger > 255]) ifTrue:
		[self genSignedSingleExtendB: (anInteger bitShift: -8)].
	stream
		nextPut: 229;
		nextPut: (anInteger bitAnd: 255)
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushLiteral: literalIndex [
	| extendedIndex |
	(literalIndex < 0 or: [literalIndex > 65535]) ifTrue:
		[^self outOfRangeError: 'index' index: literalIndex range: 0 to: 65536].
	literalIndex < 32 ifTrue: 
		["32-63 	001iiiii 	Push Literal #iiiii"
		 stream nextPut: 32 + literalIndex.
		 ^self].
	"228		11100100	i i i i i i i i	Push Literal #iiiiiiii (+ Extend A * 256)"
	(extendedIndex := literalIndex) > 255 ifTrue:
		[self genUnsignedSingleExtendA: extendedIndex // 256.
		 extendedIndex := extendedIndex \\ 256].
	stream
		nextPut: 228;
		nextPut: extendedIndex
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushLiteralVar: literalIndex [
	| extendedIndex |
	(literalIndex < 0 or: [literalIndex > 65535]) ifTrue:
		[^self outOfRangeError: 'index' index: literalIndex range: 0 to: 65535].
	literalIndex < 16 ifTrue: 
		["16-31		0001 i i i i		Push Literal Variable #iiii"
		 stream nextPut: 16 + literalIndex.
		 ^self].
	"227		11100011	i i i i i i i i	Push Literal Variable #iiiiiiii (+ Extend A * 256)"
	(extendedIndex := literalIndex) > 255 ifTrue:
		[self genUnsignedSingleExtendA: extendedIndex // 256.
		 extendedIndex := extendedIndex \\ 256].
	stream
		nextPut: 227;
		nextPut: extendedIndex
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushNewArray: size [
	(size < 0 or: [size > 127]) ifTrue:
		[^self outOfRangeError: 'size' index: size range: 0 to: 127].
	"231		11100111	jkkkkkkk	Push (Array new: kkkkkkk) (j = 0)
									&	Pop kkkkkkk elements into: (Array new: kkkkkkk) (j = 1)"
	stream
		nextPut: 231;
		nextPut: size
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushReceiver [
	"76			01001100		Push Receiver"
	stream nextPut: 76
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushRemoteTemp: tempIndex inVectorAt: tempVectorIndex [
	"250		11111010 kkkkkkkk	jjjjjjjj		Push Temp At kkkkkkkk In Temp Vector At: jjjjjjjj"
	(tempIndex < 0 or: [tempIndex >= 256]) ifTrue:
		[^self outOfRangeError: 'remoteTempIndex' index: tempIndex range: 0 to: 255].
	(tempVectorIndex < 0 or: [tempVectorIndex >= 256]) ifTrue:
		[^self outOfRangeError: 'tempVectorIndex' index: tempVectorIndex range: 0 to: 255].
	stream
		nextPut: 250;
		nextPut: tempIndex;
		nextPut: tempVectorIndex
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushSpecialLiteral: aLiteral [
	"77			01001101				Push false [* 1:true, 2:nil, 3:thisContext, ..., -N: pushExplicitOuter: N, N = Extend B]
	 229		11100101	i i i i i i i i	Push Integer #iiiiiiii (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	| index |
	aLiteral isInteger ifTrue:
		[^self genPushInteger: aLiteral].
	index := #(false true nil)
					indexOf: aLiteral
					ifAbsent: [^self error: 'push special literal: ', aLiteral printString,  ' is not one of true false nil'].
	index > 1 ifTrue:
		[self genUnsignedSingleExtendB: index - 1].
	stream nextPut: 77
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushTemp: tempIndex [
	(tempIndex < 0 or: [tempIndex > 63]) ifTrue:
		[^self outOfRangeError: 'index' index: tempIndex range: 0 to: 63].
	tempIndex < 12 ifTrue: 
		["64-71		01000 i i i		Push Temporary Variable #iii
		   72-75	010010 i i		Push Temporary Variable #ii + 8"
		 stream nextPut: 64 + tempIndex.
		 ^self].
	"230		11100110	i i i i i i i i	Push Temporary Variable #iiiiiiii"
	stream
		nextPut: 230;
		nextPut: tempIndex
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genPushThisContext [
	"77			01001101		Push false [* 1:true, 2:nil, 3:thisContext, ..., -N: pushExplicitOuter: N, N = Extend B]"
	self genSignedSingleExtendB: 3.
	stream nextPut: 77
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genReturnReceiver [
	"216		11011000		Return Receiver From Message"
	stream nextPut: 216
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genReturnSpecialLiteral: aLiteral [
	self shouldNotImplement
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genReturnTop [
	"217		11011001		Return Stack Top From Message"
	stream nextPut: 217
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genReturnTopToCaller [
	"218		11011010		Return Stack Top From Block [* return from enclosing block N]"
	stream nextPut: 218
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genSend: selectorLiteralIndex numArgs: nArgs [
	| extendedIndex extendedNArgs |
	(selectorLiteralIndex < 0 or: [selectorLiteralIndex > 65535]) ifTrue:
		[^self outOfRangeError: 'selectorLiteralIndex' index: selectorLiteralIndex range: 0 to: 65535].
	(nArgs < 0 or: [nArgs > 31]) ifTrue:
		[^self outOfRangeError: 'numArgs' index: nArgs range: 0 to: 31 "!!"].
	(selectorLiteralIndex < 16 and: [nArgs < 3]) ifTrue: 
	 	["112-127	0111 i i i i		Send Literal Selector #iiii With 0 Arguments
		   128-143	1000 i i i i		Send Literal Selector #iiii With 1 Argument
		   144-159	1001 i i i i		Send Literal Selector #iiii With 2 Arguments"
		 stream nextPut: 112 + (nArgs * 16) + selectorLiteralIndex.
		 ^self].
	(extendedIndex := selectorLiteralIndex) > 31 ifTrue:
		[self genUnsignedSingleExtendA: extendedIndex // 32.
		 extendedIndex := extendedIndex \\ 32].
	(extendedNArgs := nArgs) > 7 ifTrue:
		[self genUnsignedSingleExtendB: extendedNArgs // 8.
		 extendedNArgs := extendedNArgs \\ 8].
	"238		11101110	i i i i i j j j	Send Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	stream
		nextPut: 238;
		nextPut: extendedNArgs + (extendedIndex * 8)
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genSendAbsentDynamicSuper: selectorLiteralIndex numArgs: nArgs [
	| extendedIndex extendedNArgs |
	(selectorLiteralIndex < 0 or: [selectorLiteralIndex > 65535]) ifTrue:
		[^self outOfRangeError: 'selectorLiteralIndex' index: selectorLiteralIndex range: 0 to: 65535].
	(nArgs < 0 or: [nArgs > 31]) ifTrue:
		[^self outOfRangeError: 'numArgs' index: nArgs range: 0 to: 31 "!!"].
	(extendedIndex := selectorLiteralIndex) > 31 ifTrue:
		[self genUnsignedSingleExtendA: extendedIndex // 32.
		 extendedIndex := extendedIndex \\ 32].
	(extendedNArgs := nArgs) > 7 ifTrue:
		[self genUnsignedSingleExtendB: extendedNArgs // 8.
		 extendedNArgs := extendedNArgs \\ 8].
	"241		11110001	i i i i i j j j	Send To Absent Dynamic Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	stream
		nextPut: 241;
		nextPut: extendedNArgs + (extendedIndex * 8)
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genSendAbsentImplicit: selectorLiteralIndex numArgs: nArgs [
	| extendedIndex extendedNArgs |
	(selectorLiteralIndex < 0 or: [selectorLiteralIndex > 65535]) ifTrue:
		[^self outOfRangeError: 'selectorLiteralIndex' index: selectorLiteralIndex range: 0 to: 65535].
	(nArgs < 0 or: [nArgs > 31]) ifTrue:
		[^self outOfRangeError: 'numArgs' index: nArgs range: 0 to: 31 "!!"].
	(selectorLiteralIndex < 16 and: [nArgs = 0]) ifTrue: 
	 	["160-175	1010 i i i i		Send To Absent Implicit Receiver Literal Selector #iiii With 0 Arguments"
		 stream nextPut: 160 + selectorLiteralIndex.
		 ^self].
	(extendedIndex := selectorLiteralIndex) > 31 ifTrue:
		[self genUnsignedSingleExtendA: extendedIndex // 32.
		 extendedIndex := extendedIndex \\ 32].
	(extendedNArgs := nArgs) > 7 ifTrue:
		[self genUnsignedSingleExtendB: extendedNArgs // 8.
		 extendedNArgs := extendedNArgs \\ 8].
	"240		11110000	i i i i i j j j	Send To Absent Implicit Receiver Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	stream
		nextPut: 240;
		nextPut: extendedNArgs + (extendedIndex * 8)
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genSendImplicit: selectorLiteralIndex numArgs: nArgs [
	| extendedIndex extendedNArgs |
	(selectorLiteralIndex < 0 or: [selectorLiteralIndex > 65535]) ifTrue:
		[^self outOfRangeError: 'selectorLiteralIndex' index: selectorLiteralIndex range: 0 to: 65535].
	(nArgs < 0 or: [nArgs > 31]) ifTrue:
		[^self outOfRangeError: 'numArgs' index: nArgs range: 0 to: 31 "!!"].
	(selectorLiteralIndex < 16 and: [nArgs = 0]) ifTrue: 
	 	["160-175	1010 i i i i		Send To Implicit Receiver Literal Selector #iiii With 0 Arguments"
		 stream nextPut: 160 + selectorLiteralIndex.
		 ^self].
	(extendedIndex := selectorLiteralIndex) > 31 ifTrue:
		[self genUnsignedSingleExtendA: extendedIndex // 32.
		 extendedIndex := extendedIndex \\ 32].
	(extendedNArgs := nArgs) > 7 ifTrue:
		[self genUnsignedSingleExtendB: extendedNArgs // 8.
		 extendedNArgs := extendedNArgs \\ 8].
	"240		11110000	i i i i i j j j	Send To Implicit Receiver Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	stream
		nextPut: 240;
		nextPut: extendedNArgs + (extendedIndex * 8)
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genSendSpecial: specialSelectorIndex numArgs: nArgs [
	self assert: (specialSelectorIndex between: 1 and: Smalltalk specialSelectorSize).
	self assert: nArgs = (Smalltalk specialNargsAt: specialSelectorIndex).
	"Special selector sends.
		80-95		0101 i i i i		Send Arithmetic Message #iiii
		96-111		0110 i i i i		Send Special Message #iiii"
	stream nextPut: specialSelectorIndex + 79
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genSendSuper: selectorLiteralIndex numArgs: nArgs [
	| extendedIndex extendedNArgs |
	(selectorLiteralIndex < 0 or: [selectorLiteralIndex > 65535]) ifTrue:
		[^self outOfRangeError: 'selectorLiteralIndex' index: selectorLiteralIndex range: 0 to: 65535].
	(nArgs < 0 or: [nArgs > 31]) ifTrue:
		[^self outOfRangeError: 'numArgs' index: nArgs range: 0 to: 31 "!!"].
	(extendedIndex := selectorLiteralIndex) > 31 ifTrue:
		[self genUnsignedSingleExtendA: extendedIndex // 32.
		 extendedIndex := extendedIndex \\ 32].
	(extendedNArgs := nArgs) > 7 ifTrue:
		[self genUnsignedSingleExtendB: extendedNArgs // 8.
		 extendedNArgs := extendedNArgs \\ 8].
	"239		11101111	i i i i i j j j	Send To Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	stream
		nextPut: 239;
		nextPut: extendedNArgs + (extendedIndex * 8)
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genSignedSingleExtendB: extendedIndex [
	(extendedIndex between: -128 and: 127) ifFalse:
		[^self outOfRangeError: 'index' index: extendedIndex range: -128 to: 127].
	"225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)"
	stream
		nextPut: 225;
		nextPut: (extendedIndex >= 0 ifTrue: [extendedIndex] ifFalse: [extendedIndex + 256]) 
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genStoreInstVar: instVarIndex [
	"232		11101000	i i i i i i i i	Store Receiver Variable #iiiiiii (+ Extend A * 256)"
	self genStoreInstVarLong: instVarIndex
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genStoreInstVarLong: instVarIndex [
	"232		11101000	i i i i i i i i	Store Receiver Variable #iiiiiii (+ Extend A * 256)"
	(instVarIndex < 0 or: [instVarIndex > 4095]) ifTrue:
		[^self outOfRangeError: 'index' index: instVarIndex range: 0 to: 4095].
	instVarIndex > 255 ifTrue:
		[self genUnsignedSingleExtendA: instVarIndex // 256].
	stream
		nextPut: 232;
		nextPut: instVarIndex \\ 256
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genStoreLiteralVar: literalIndex [
	"233		11101001	i i i i i i i i	Store Literal Variable #iiiiiiii (+ Extend A * 256)"
	(literalIndex < 0 or: [literalIndex > 65535]) ifTrue:
		[^self outOfRangeError: 'index' index: literalIndex range: 0 to: 65535].
	literalIndex > 255 ifTrue: 
		[self genUnsignedSingleExtendA: literalIndex // 256].
	stream
		nextPut: 233;
		nextPut: literalIndex \\ 256
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genStorePopInstVar: instVarIndex [
	"176-183	10110 i i i				Pop and Store Receiver Variable #iii
	 235		11101011	i i i i i i i i	Pop and Store Receiver Variable #iiiiiii (+ Extend A * 256)"
	(instVarIndex < 0 or: [instVarIndex > 7]) ifTrue:
		[^self genStorePopInstVarLong: instVarIndex].
	stream nextPut: 176 + instVarIndex
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genStorePopInstVarLong: instVarIndex [
	"235		11101011	i i i i i i i i	Pop and Store Receiver Variable #iiiiiii (+ Extend A * 256)"
	(instVarIndex < 0 or: [instVarIndex > 4095]) ifTrue:
		[^self outOfRangeError: 'index' index: instVarIndex range: 0 to: 4095].
	instVarIndex > 255 ifTrue:
		[self genUnsignedSingleExtendA: instVarIndex // 256].
	stream
		nextPut: 235;
		nextPut: instVarIndex \\ 256
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genStorePopLiteralVar: literalIndex [
	"236		11101100	i i i i i i i i	Pop and Store Literal Variable #iiiiiiii (+ Extend A * 256)"
	(literalIndex < 0 or: [literalIndex > 65535]) ifTrue:
		[^self outOfRangeError: 'index' index: literalIndex range: 0 to: 65535].
	literalIndex > 255 ifTrue: 
		[self genUnsignedSingleExtendA: literalIndex // 256].
	stream
		nextPut: 236;
		nextPut: literalIndex \\ 256
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genStorePopRemoteTemp: tempIndex inVectorAt: tempVectorIndex [
	"252		11111100 kkkkkkkk	jjjjjjjj		Pop and Store Temp At kkkkkkkk In Temp Vector At: jjjjjjjj"
	(tempIndex < 0 or: [tempIndex >= 256]) ifTrue:
		[^self outOfRangeError: 'remoteTempIndex' index: tempIndex range: 0 to: 255].
	(tempVectorIndex < 0 or: [tempVectorIndex >= 256]) ifTrue:
		[^self outOfRangeError: 'tempVectorIndex' index: tempVectorIndex range: 0 to: 255].
	stream
		nextPut: 252;
		nextPut: tempIndex;
		nextPut: tempVectorIndex
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genStorePopTemp: tempIndex [
	"184-191	10111 i i i				Pop and Store Temporary Variable #iii
	 237		11101101	i i i i i i i i	Pop and Store Temporary Variable #iiiiiiii"
	(tempIndex < 0 or: [tempIndex > 63]) ifTrue:
		[^self outOfRangeError: 'index' index: tempIndex range: 0 to: 63].
	tempIndex < 8 ifTrue:
		[stream nextPut: 184 + tempIndex.
		 ^self].
	stream
		nextPut: 237;
		nextPut: tempIndex
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genStoreRemoteTemp: tempIndex inVectorAt: tempVectorIndex [
	"251		11111011 kkkkkkkk	jjjjjjjj		Store Temp At kkkkkkkk In Temp Vector At: jjjjjjjj"
	(tempIndex < 0 or: [tempIndex >= 256]) ifTrue:
		[^self outOfRangeError: 'remoteTempIndex' index: tempIndex range: 0 to: 255].
	(tempVectorIndex < 0 or: [tempVectorIndex >= 256]) ifTrue:
		[^self outOfRangeError: 'tempVectorIndex' index: tempVectorIndex range: 0 to: 255].
	stream
		nextPut: 251;
		nextPut: tempIndex;
		nextPut: tempVectorIndex
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genStoreTemp: tempIndex [
	"234		11101010	i i i i i i i i	Store Temporary Variable #iiiiiiii"
	(tempIndex < 0 or: [tempIndex > 63]) ifTrue:
		[^self outOfRangeError: 'index' index: tempIndex range: 0 to: 63].
	stream
		nextPut: 234;
		nextPut: tempIndex
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genUnsignedMultipleExtendA: extendedIndex [
	"224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)"
	extendedIndex > 255 ifTrue:
		[self genUnsignedMultipleExtendA: extendedIndex // 256].
	stream
		nextPut: 224;
		nextPut: extendedIndex \\ 256
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genUnsignedSingleExtendA: extendedIndex [
	(extendedIndex between: 0 and: 255) ifFalse:
		[^self outOfRangeError: 'index' index: extendedIndex range: 0 to: 255].
	"224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)"
	stream
		nextPut: 224;
		nextPut: extendedIndex
]

{ #category : #'bytecode generation' }
EncoderForNewsqueakV4 >> genUnsignedSingleExtendB: extendedIndex [
	(extendedIndex between: 0 and: 255) ifFalse:
		[^self outOfRangeError: 'index' index: extendedIndex range: 0 to: 255].
	"225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)"
	stream
		nextPut: 225;
		nextPut: extendedIndex
]

{ #category : #'special literal encodings' }
EncoderForNewsqueakV4 >> if: code isSpecialLiteralForReturn: aBlock [
	"No special literal encodings for return."
	^false
]

{ #category : #'special literal encodings' }
EncoderForNewsqueakV4 >> isSpecialLiteral: literal [
	^literal isInteger and: [literal between: -32768 and: 32767]
]

{ #category : #'special literal encodings' }
EncoderForNewsqueakV4 >> isSpecialLiteralForPush: literal [
	^literal == false
	  or: [literal == true
	  or: [literal == nil
	  or: [literal isInteger and: [literal between: -32768 and: 32767]]]]
]

{ #category : #accessing }
EncoderForNewsqueakV4 >> maxIndexableLiterals [
	"Answer the maximum number of literals supported by the receiver's
	 bytecode set."
	^65536
]

{ #category : #testing }
EncoderForNewsqueakV4 >> supportsClosureOpcodes [
	^true
]

{ #category : #testing }
EncoderForNewsqueakV4 >> supportsFullBlocks [
	"Answer if the instruction set supports full closures (closure creation from
	 specfic methods instead of bytecodes embedded in an outer home method)."
	
	^false
]

{ #category : #testing }
EncoderForNewsqueakV4 >> usesAlternateBytecodeSet [
	"Answer if the receiver encodes the alternate bytecode set (indicated by the sign flag set in a CompiledMethod's header)."
	^true
]
