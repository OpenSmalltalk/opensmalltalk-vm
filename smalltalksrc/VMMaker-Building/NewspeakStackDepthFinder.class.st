Class {
	#name : #NewspeakStackDepthFinder,
	#superclass : #StackDepthFinder,
	#category : #'VMMaker-Support'
}

{ #category : #'instruction decoding' }
NewspeakStackDepthFinder >> callPrimitive: primitiveIndex [
	"Call Primitive bytecode.  Effectively a no-op."
]

{ #category : #private }
NewspeakStackDepthFinder >> interpretNewspeakExtension: offset in: method for: client [
	| type offset2 byte2 byte3 byte4 |
	offset <= 6 ifTrue: 
		["Extended op codes 128-134"
		byte2 := method at: pc. pc := pc + 1.
		offset <= 2 ifTrue:
			["128-130:  extended pushes and pops"
			type := byte2 // 64.
			offset2 := byte2 \\ 64.
			offset = 0 ifTrue: 
				[type = 0 ifTrue: [^client pushReceiverVariable: offset2].
				type = 1 ifTrue: [^client pushTemporaryVariable: offset2].
				type = 2  ifTrue: [^client pushConstant: (method literalAt: offset2 + 1)].
				type = 3 ifTrue: [^client pushLiteralVariable: (method literalAt: offset2 + 1)]].
			offset = 1 ifTrue: 
				[type = 0 ifTrue: [^client storeIntoReceiverVariable: offset2].
				type = 1 ifTrue: [^client storeIntoTemporaryVariable: offset2].
				type = 2 ifTrue: [self error: 'illegalStore'].
				type = 3 ifTrue: [^client storeIntoLiteralVariable: (method literalAt: offset2 + 1)]].
			offset = 2 ifTrue: 
				[type = 0 ifTrue: [^client popIntoReceiverVariable: offset2].
				type = 1 ifTrue: [^client popIntoTemporaryVariable: offset2].
				type = 2 ifTrue: [self error: 'illegalStore'].
				type = 3  ifTrue: [^client popIntoLiteralVariable: (method literalAt: offset2 + 1)]]].
		"131-134: extended sends"
		offset = 3 ifTrue:  "Single extended send"
			[^client send: (method literalAt: byte2 \\ 32 + 1)
					super: false numArgs: byte2 // 32].
		offset = 4 ifTrue:    "Double extended do-anything"
			[byte3 := method at: pc. pc := pc + 1.
			type := byte2 // 32.
			type = 0 ifTrue: [^client send: (method literalAt: byte3 + 1)
									super: false numArgs: byte2 \\ 32].
			type = 1 ifTrue: [^client send: (method literalAt: byte3 + 1)
									super: true numArgs: byte2 \\ 32].
			type = 2 ifTrue: [^client pushReceiverVariable: byte3].
			type = 3 ifTrue: [^client pushConstant: (method literalAt: byte3 + 1)].
			type = 4 ifTrue: [^client pushLiteralVariable: (method literalAt: byte3 + 1)].
			type = 5 ifTrue: [^client storeIntoReceiverVariable: byte3].
			type = 6 ifTrue: [^client popIntoReceiverVariable: byte3].
			type = 7 ifTrue: [^client storeIntoLiteralVariable: (method literalAt: byte3 + 1)]].
		offset = 5 ifTrue:  "Single extended send to super"
			[^client send: (method literalAt: byte2 \\ 32 + 1)
					super: true numArgs: byte2 // 32].
		offset = 6 ifTrue:   "Second extended send"
			[^client send: (method literalAt: byte2 \\ 64 + 1)
					super: false numArgs: byte2 // 64]].
	offset = 7 ifTrue: [^client doPop].
	offset = 8 ifTrue: [^client doDup].
	offset = 9 ifTrue: [^client pushActiveContext].
	byte2 := method at: pc. pc := pc + 1.
	offset = 10 ifTrue:
		[^byte2 < 128
			ifTrue: [client pushNewArrayOfSize: byte2]
			ifFalse: [client pushConsArrayWithElements: byte2 - 128]].
	offset = 11 ifTrue: "139: pushExplicitOuter"
		[^client pushExplicitOuter: (method literalAt: byte2 + 1)].
	byte3 := method at: pc.  pc := pc + 1.
	offset = 12 ifTrue: [^client pushRemoteTemp: byte2 inVectorAt: byte3].
	offset = 13 ifTrue: [^client storeIntoRemoteTemp: byte2 inVectorAt: byte3].
	offset = 14 ifTrue: [^client popIntoRemoteTemp: byte2 inVectorAt: byte3].
	"offset = 15"
	byte4 := method at: pc.  pc := pc + 1.
	^client
		pushClosureCopyNumCopiedValues: (byte2 bitShift: -4)
		numArgs: (byte2 bitAnd: 16rF)
		blockSize: (byte3 * 256) + byte4
]

{ #category : #decoding }
NewspeakStackDepthFinder >> interpretNextInstructionFor: client [
	joins at: pc put: stackp.
	^self interpretNextNewspeakInstructionFor: client
]

{ #category : #decoding }
NewspeakStackDepthFinder >> interpretNextNewspeakInstructionFor: client [
	"Send to the argument, client, a message that specifies the next instruction."

	| byte type offset method |
	method := self method.
	method usesAlternateBytecodeSet ifTrue:
		[^self alternateInterpretNextInstructionFor: client].
	byte := method at: pc.
	type := byte // 16.
	offset := byte \\ 16.
	pc := pc+1.
	"We do an inline binary search on each of the possible 16 values of type:
	The old, cleaner but slow code is retained as a comment below"
	type < 8 ifTrue:
		[type < 4 ifTrue:
			[type < 2 ifTrue:
				[type = 0 ifTrue:
					 [^client pushReceiverVariable: offset].
				^client pushTemporaryVariable: offset]. "type = 1"
			 type = 2 ifTrue:
				[^client pushConstant: (method literalAt: offset + 1)].
			 ^client pushConstant: (method literalAt: offset + 17)]. "type = 3"
		 type < 6 ifTrue:
			[type = 4 ifTrue:
				[^client pushLiteralVariable: (method literalAt: offset + 1)].
			 ^client pushLiteralVariable: (method literalAt: offset + 17)]. "type = 5"
		 type = 6 ifTrue:
			[offset < 8
				ifTrue: [^client popIntoReceiverVariable: offset]
				ifFalse: [^client popIntoTemporaryVariable: offset - 8]].
		 "type = 7"
		 offset = 0 ifTrue: [^client pushReceiver].
		 offset < 8 ifTrue: [^client pushConstant: (SpecialConstants at: offset)].
		 offset = 8 ifTrue: [^client methodReturnReceiver].
		 offset < 12 ifTrue: [^client methodReturnConstant: (SpecialConstants at: offset - 8)].
		 offset = 12 ifTrue: [^client methodReturnTop].
		 offset = 13 ifTrue: [^client blockReturnTop].
		 offset = 14 ifTrue:
			[| byte2 |
			 byte := method at: pc.
			 pc := pc+1.
			byte2 := method at: pc.
			 pc := pc+1.
			^client sendToDynamicSuperclass: (method literalAt: byte2 + 1) numArgs: byte].
		 offset = 15 ifTrue:
			[byte := method at: pc.
			 pc := pc+1.
			^client pushImplicitReceiverForMessage: (method literalAt: byte + 1)]].
	type < 12 ifTrue:
		[type < 10 ifTrue:
			[type = 8 ifTrue:
				[^self interpretNewspeakExtension: offset in: method for: client].
			 "type = 9 (short jumps)"
			 offset < 8 ifTrue: [^client jump: offset + 1].
			 ^client jump: offset - 8 + 1 if: false].
		type= 10 ifTrue: "type = 10 (long jumps)"
			[byte := method at: pc.
			 pc := pc + 1.
			 offset < 8 ifTrue: [^client jump: offset - 4 * 256 + byte].
			 ^client jump: (offset bitAnd: 3) * 256 + byte if: offset < 12].
		"type = 11 (arithmetic special selector sends)"
		^client
			send: (Smalltalk specialSelectorAt: offset + 1)
			super: false
			numArgs: (Smalltalk specialNargsAt: offset + 1)].
	type = 12 ifTrue: "(miscellaneous special selector sends)"
		[^client
			send: (Smalltalk specialSelectorAt: offset + 17)
			super: false
			numArgs: (Smalltalk specialNargsAt: offset + 17)].
	"type = 13, 14 or 15"
	^client
		send: (method literalAt: offset + 1)
		super: false
		numArgs: type - 13


"    old code
	type=0 ifTrue: [^client pushReceiverVariable: offset].
	type=1 ifTrue: [^client pushTemporaryVariable: offset].
	type=2 ifTrue: [^client pushConstant: (method literalAt: offset+1)].
	type=3 ifTrue: [^client pushConstant: (method literalAt: offset+17)].
	type=4 ifTrue: [^client pushLiteralVariable: (method literalAt: offset+1)].
	type=5 ifTrue: [^client pushLiteralVariable: (method literalAt: offset+17)].
	type=6
		ifTrue: [offset<8
					ifTrue: [^client popIntoReceiverVariable: offset]
					ifFalse: [^client popIntoTemporaryVariable: offset-8]].
	type=7
		ifTrue: [offset=0 ifTrue: [^client pushReceiver].
				offset<8 ifTrue: [^client pushConstant: (SpecialConstants at: offset)].
				offset=8 ifTrue: [^client methodReturnReceiver].
				offset<12 ifTrue: [^client methodReturnConstant:
												(SpecialConstants at: offset-8)].
				offset=12 ifTrue: [^client methodReturnTop].
				offset=13 ifTrue: [^client blockReturnTop].
				^self error: 'unusedBytecode'].
	type=8 ifTrue: [^self interpretExtension: offset in: method for: client].
	type=9
		ifTrue:  short jumps
			[offset<8 ifTrue: [^client jump: offset+1].
			^client jump: offset-8+1 if: false].
	type=10
		ifTrue:  long jumps
			[byte:= method at: pc.  pc:= pc+1.
			offset<8 ifTrue: [^client jump: offset-4*256 + byte].
			^client jump: (offset bitAnd: 3)*256 + byte if: offset<12].
	type=11
		ifTrue:
			[^client
				send: (Smalltalk specialSelectorAt: offset+1)
				super: false
				numArgs: (Smalltalk specialNargsAt: offset+1)].
	type=12
		ifTrue:
			[^client
				send: (Smalltalk specialSelectorAt: offset+17)
				super: false
				numArgs: (Smalltalk specialNargsAt: offset+17)].
	type>12
		ifTrue:
			[^client send: (method literalAt: offset+1)
					super: false
					numArgs: type-13]"
]

{ #category : #'instruction decoding' }
NewspeakStackDepthFinder >> pushExplicitOuter: level [
	"Push receiver for explcit outer, on Top Of Stack bytecode."
	self push
]

{ #category : #'instruction decoding' }
NewspeakStackDepthFinder >> pushImplicitReceiverForMessage: selector [
	"Push implicit receiver for selector on top of stack bytecode."
	self push
]

{ #category : #'instruction decoding' }
NewspeakStackDepthFinder >> sendToAbsentDynamicSuperclass: selector numArgs: numArgs [
	"Dynamic Superclass Send Message With Selector, selector, to absent implicit receiver bytecode."
	self drop: numArgs - 1 "e.g. if no args pushes a result"
]

{ #category : #'instruction decoding' }
NewspeakStackDepthFinder >> sendToAbsentImplicitReceiver: selector numArgs: numArgs [
	"Send Message With Selector, selector, to absent implicit receiver bytecode."
	self drop: numArgs - 1 "e.g. if no args pushes a result"
]

{ #category : #'instruction decoding' }
NewspeakStackDepthFinder >> sendToDynamicSuperclass: selector numArgs: numArgs [
	"Send Message With Selector, selector, to dynamic superclass bytecode."
	self drop: numArgs
]
