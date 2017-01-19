Extension { #name : #InstructionStream }

{ #category : #'*BytecodeSets-NewsqueakV3-decoding' }
InstructionStream >> interpretNSV3Extension: offset in: method for: client [
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
					super: true
					numArgs: byte2 // 32].
		offset = 6 ifTrue:   "Second extended send"
			[^client send: (method literalAt: byte2 \\ 64 + 1)
					super: false
					numArgs: byte2 // 64]].
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

{ #category : #'*BytecodeSets-NewsqueakV4-decoding' }
InstructionStream >> interpretNSV4ExtendedPush: extB for: client [
	"Implement the extended push for non-zero extensions."
	"77			01001101				Push false [* 1:true, 2:nil, 3:thisContext, ..., -N: pushExplicitOuter: N, N = Extend B]"
	extB < 0 ifTrue:
		[^client pushExplicitOuter: extB negated].
	extB < 2 ifTrue:
		[^client pushConstant: extB = 1].
	extB = 2 ifTrue:
		[^client pushConstant: nil].
	extB = 3 ifTrue:
		[^client pushActiveContext].
	self error: 'undefined extended push'
]

{ #category : #'*BytecodeSets-NewsqueakV4-decoding' }
InstructionStream >> interpretNSV4Jump [
	"If the instruction at pc is an unconditional jump, interpret it, advancing the pc,
	 and answering the jump distance. Otherwise answer nil."

	"	192-199	11000 i i i				Jump iii + 1 (i.e., 1 through 8)
	 *	225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)
	 *	242		11110010	i i i i i i i i	Jump i i i i i i i i (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	| method byte nextpc extA extB |
	method := self method.
	"consume and compute any extensions first."
	extA := extB := 0.
	nextpc := pc. "must not advance pc unless this is a jump."
	[byte := self method at: nextpc.
	 nextpc := nextpc + 1.
	 byte >= 224 and: [byte <= 225]] whileTrue:
		[| extByte |
		 extByte := self method at: nextpc.
		 nextpc := nextpc + 1.
		 byte = 224
			ifTrue:
				[extA := (extA bitShift: 8) + extByte]
			ifFalse:
				[extB := (extB = 0 and: [extByte > 127])
							ifTrue: [extByte - 256]
							ifFalse: [(extB bitShift: 8) + extByte]]].
	(byte between: 192 and: 199) ifTrue:
		[pc := nextpc.
		 ^byte - 191].
	byte = 242 ifTrue:
		[byte := method at: nextpc.
		 pc := nextpc + 1.
		 ^(extB bitShift: 8) + byte].
	^nil
]

{ #category : #'*BytecodeSets-NewsqueakV4-decoding' }
InstructionStream >> interpretNSV4JumpIfCond [
	"If the instruction at pc is a conditional jump, interpret it, advancing the pc,
	 and answering the jump distance. Otherwise answer nil."

	"	200-207	11001 i i i				Pop and Jump 0n True iii +1 (i.e., 1 through 8)
		208-215	11010 i i i				Pop and Jump 0n False iii +1 (i.e., 1 through 8)
	 *	225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)
	 *	243		11110011	i i i i i i i i	Pop and Jump 0n True i i i i i i i i (+ Extend B * 256, where Extend B >= 0)
	 *	244		11110100	i i i i i i i i	Pop and Jump 0n False i i i i i i i i (+ Extend B * 256, where Extend B >= 0)"
	| method byte nextpc extA extB |
	method := self method.
	"consume and compute any extensions first."
	extA := extB := 0.
	nextpc := pc. "must not advance pc unless this is a jump."
	[byte := self method at: nextpc.
	 nextpc := nextpc + 1.
	 byte >= 224 and: [byte <= 225]] whileTrue:
		[| extByte |
		 extByte := self method at: nextpc.
		 nextpc := nextpc + 1.
		 byte = 224
			ifTrue:
				[extA := (extA bitShift: 8) + extByte]
			ifFalse:
				[extB := (extB = 0 and: [extByte > 127])
							ifTrue: [extByte - 256]
							ifFalse: [(extB bitShift: 8) + extByte]]].
	(byte between: 200 and: 215) ifTrue:
		[pc := nextpc.
		 ^(byte bitAnd: 7) + 1].
	(byte between: 243 and: 244) ifTrue:
		[byte := method at: nextpc.
		 pc := nextpc + 1.
		 ^(extB bitShift: 8) + byte].
	^nil
]

{ #category : #'*BytecodeSets-NewsqueakV4-decoding' }
InstructionStream >> interpretNext2ByteNSV4Instruction: bytecode for: client extA: extA extB: extB startPC: startPC [
	"Send to the argument, client, a message that specifies the next instruction.
	 This method handles the two-byte codes.
	 For a table of the bytecode set, see EncoderForNewsqueakV4's class comment."

	| byte method |
	method := self method.
	byte := self method at: pc.
	pc := pc + 1.
	"We do an inline quasi-binary search on bytecode"
	bytecode < 235 ifTrue:
		[bytecode < 231 ifTrue:
			[bytecode < 229 ifTrue:
				[| literal |
				 bytecode = 226 ifTrue:
					[^client pushReceiverVariable: (extA bitShift: 8) + byte].
				 literal := method literalAt: (extA bitShift: 8) + byte + 1.
				 bytecode = 227 ifTrue:
					[^client pushLiteralVariable: literal].
				 ^client pushConstant: literal].
			bytecode = 229 ifTrue:
				[^client pushConstant: (extB bitShift: 8) + byte].
			^client pushTemporaryVariable: byte].
		bytecode = 231 ifTrue:
			[^byte < 128
				ifTrue: [client pushNewArrayOfSize: byte]
				ifFalse: [client pushConsArrayWithElements: byte - 128]].
		bytecode = 232 ifTrue:
			[^client storeIntoReceiverVariable: (extA bitShift: 8) + byte].
		bytecode = 233 ifTrue:
			[^client storeIntoLiteralVariable: (method literalAt: (extA bitShift: 8) + byte + 1)].
		^client storeIntoTemporaryVariable: byte].
	bytecode < 238 ifTrue:
		[bytecode = 235 ifTrue:
			[^client popIntoReceiverVariable: (extA bitShift: 8) + byte].
		 bytecode = 236 ifTrue:
			[^client popIntoLiteralVariable: (method literalAt: (extA bitShift: 8) + byte + 1)].
		 ^client popIntoTemporaryVariable: byte].
	bytecode < 242 ifTrue:
		[| selector numArgs |
		 selector := method literalAt: (extA bitShift: 5) + (byte // 8) + 1.
		 numArgs := (extB bitShift: 3) + (byte \\ 8).
		 bytecode = 238 ifTrue:
			[^client send: selector super: false numArgs: numArgs].
		 bytecode = 239 ifTrue:
			[^client send: selector super: true numArgs: numArgs].
		 bytecode = 240 ifTrue:
			[^client sendToAbsentImplicitReceiver: selector numArgs: numArgs].
		 ^client sendToAbsentDynamicSuperclass: selector numArgs: numArgs].
	bytecode < 245 ifTrue:
		[bytecode = 242 ifTrue:
			[^client jump: (extB bitShift: 8) + byte].
		 ^client jump: (extB bitShift: 8) + byte if: bytecode = 243].
	bytecode = 245 ifTrue:
		[| selector numArgs |
		 selector := method literalAt: (extA bitShift: 5) + (byte // 8) + 1.
		 numArgs := (extB bitShift: 3) + (byte \\ 8).
		 ^client sendToAbsentSelf: selector numArgs: numArgs].
	"246-247	1111011 i	xxxxxxxx	UNASSIGNED
	 248-249	1111100 i	xxxxxxxx	UNASSIGNED"
	^self unusedBytecode: client at: startPC
]

{ #category : #'*BytecodeSets-SistaV1-decoding' }
InstructionStream >> interpretNext2ByteSistaV1Instruction: bytecode for: client extA: extA extB: extB startPC: startPC [
	"Send to the argument, client, a message that specifies the next instruction.
	 This method handles the two-byte codes.
	 For a table of the bytecode set, see EncoderForV1's class comment."

	| byte method |
	method := self method.
	byte := self method at: pc.
	pc := pc + 1.
	"We do an inline quasi-binary search on bytecode"
	bytecode < 234 ifTrue: "pushes"
		[bytecode < 231 ifTrue:
			[bytecode < 229 ifTrue:
				[| literal |
				 bytecode = 226 ifTrue:
					[^client pushReceiverVariable: (extA bitShift: 8) + byte].
				 literal := method literalAt: (extA bitShift: 8) + byte + 1.
				 bytecode = 227 ifTrue:
					[^client pushLiteralVariable: literal].
				 ^client pushConstant: literal].
			bytecode = 229 ifTrue:
				[^client pushTemporaryVariable: byte]. 
			^client pushClosureTemps: byte]. 
		bytecode = 231 ifTrue:
			[^byte < 128
				ifTrue: [client pushNewArrayOfSize: byte]
				ifFalse: [client pushConsArrayWithElements: byte - 128]].
		bytecode = 232 ifTrue:
			[^client pushConstant: (extB bitShift: 8) + byte].
		^client pushConstant: (Character value: (extB bitShift: 8) + byte)].
	bytecode < 240 ifTrue: "sends and jump"
		[bytecode < 236 ifTrue: "sends"
			[(bytecode = 235 and: [extB >= 64]) ifTrue:
				[^client
					directedSuperSend: (method literalAt: (extA bitShift: 5) + (byte // 8) + 1)
					numArgs: (extB - 64 bitShift: 3) + (byte \\ 8)].
			 ^client
				send: (method literalAt: (extA bitShift: 5) + (byte // 8) + 1)
				super: bytecode = 235
				numArgs: (extB bitShift: 3) + (byte \\ 8)].
		 bytecode = 236 ifTrue:
			[^self unusedBytecode: client at: startPC].
		bytecode = 237 ifTrue:
			[^client jump: (extB bitShift: 8) + byte].
		 ^client jump: (extB bitShift: 8) + byte if: bytecode = 238].
	bytecode < 243 ifTrue:
		[bytecode = 240 ifTrue:
			[^client popIntoReceiverVariable: (extA bitShift: 8) + byte].
		 bytecode = 241 ifTrue:
			[^client popIntoLiteralVariable: (method literalAt: (extA bitShift: 8) + byte + 1)].
		 ^client popIntoTemporaryVariable: byte].
	bytecode = 243 ifTrue:
		[^client storeIntoReceiverVariable: (extA bitShift: 8) + byte].
	bytecode = 244 ifTrue:
		[^client storeIntoLiteralVariable: (method literalAt: (extA bitShift: 8) + byte + 1)].
	bytecode = 245 ifTrue:
		[^client storeIntoTemporaryVariable: byte].
	"246-247	1111011 i	xxxxxxxx	UNASSIGNED"
	^self unusedBytecode: client at: startPC
]

{ #category : #'*BytecodeSets-NewsqueakV4-decoding' }
InstructionStream >> interpretNext3ByteNSV4Instruction: bytecode for: client extA: extA extB: extB startPC: startPC [
	"Send to the argument, client, a message that specifies the next instruction.
	 This method handles the three-byte codes.
	 For a table of the bytecode set, see EncoderForNewsqueakV4's class comment."

	| method byte2 byte3 |
	method := self method.
	byte2 := method at: pc.
	byte3 := method at: pc + 1.
	pc := pc + 2.
	"we search the bytecodes by static frequency"
	bytecode = 253 ifTrue:
		["253		11111101 eeiiikkk		jjjjjjjj		Push Closure Num Copied iii (+ Ext A // 16 * 8) Num Args kkk (+ Ext A \\ 16 * 8) BlockSize jjjjjjjj (+ Ext B * 256). ee = num extensions"
		 ^client
			pushClosureCopyNumCopiedValues: ((byte2 bitShift: -3) bitAnd: 7) + (extA // 16 bitShift: 3)
			numArgs: (byte2 bitAnd: 7) + (extA \\ 16 bitShift: 3)
			blockSize: byte3 + (extB bitShift: 8)].
	bytecode = 250 ifTrue:
		[^client pushRemoteTemp: byte2 inVectorAt: byte3].
	bytecode = 252 ifTrue:
		[^client popIntoRemoteTemp: byte2 inVectorAt: byte3].
	bytecode = 251 ifTrue:
		[^client storeIntoRemoteTemp: byte2 inVectorAt: byte3].
	bytecode = 249 ifTrue:
		[^client callPrimitive: byte2 + (byte3 bitShift: 8)].
	bytecode = 254 ifTrue:
		[| selector numArgs depth |
		 selector := method literalAt: (extA bitShift: 5) + (byte2 // 8) + 1.
		 numArgs := (extB bitShift: 3) + (byte2 \\ 8).
		depth := byte3.
		 ^client sendToAbsentOuter: selector numArgs: numArgs depth: depth].
	"255-255	11111111	xxxxxxxx	yyyyyyyy	UNASSIGNED"
	^self unusedBytecode: client at: startPC
]

{ #category : #'*BytecodeSets-SistaV1-decoding' }
InstructionStream >> interpretNext3ByteSistaV1Instruction: bytecode for: client extA: extA extB: extB startPC: startPC [
	"Send to the argument, client, a message that specifies the next instruction.
	 This method handles the three-byte codes.
	 For a table of the bytecode set, see EncoderForSistaV1's class comment."

	| method byte2 byte3 literal |
	method := self method.
	byte2 := method at: pc.
	byte3 := method at: pc + 1.
	pc := pc + 2.

	"**	248	(2)	11111000 	iiiiiiii		mssjjjjj		Call Primitive #iiiiiiii + (jjjjj * 256) 
									m=1 means inlined primitive, no hard return after execution. 
									ss defines the unsafe operation set used to encode the operations. 
									(ss = 0 means sista unsafe operations, ss = 01 means lowcode operations, other numbers are not used)
									Lowcode inlined primitives may have extensions."
	bytecode = 248 ifTrue:
		[| primitiveSetSelector primitiveNumber |
		 byte3 < 128 ifTrue:
			[ "Maybe this should be restricted to the 13 bit primitiveNumber too..."
			 ^client callPrimitive: byte2 + (byte3 bitShift: 8)].
		 primitiveSetSelector := (byte3 bitShift: -5) bitAnd: 3.
		 primitiveNumber := byte2 + ((byte3 bitAnd: 31) bitShift: 8).
		 primitiveSetSelector = 0 ifTrue: "Sista inline primitives"
			[^client callInlinePrimitive: byte2 + (byte3 - 128 bitShift: 8)].
		 primitiveSetSelector = 1 ifTrue: "Lowcode inline primitives"
			[^client callLowcodeInlinePrimitive: byte2 + (byte3 - 128 bitShift: 8) extA: extA extB: extB].
		 "fall through to ^self unusedBytecode: client at: startPC below"].

	"*	249		11111001	xxxxxxxx	siyyyyyy	push Closure Compiled block literal index xxxxxxxx (+ Extend A * 256) numCopied yyyyyy receiverOnStack: s = 1 ignoreOuterContext: i = 1"
	bytecode = 249 ifTrue:
		[literal := method literalAt: (extA bitShift: 8) + byte2 + 1.
		 ^client pushFullClosure: literal numCopied: (byte3 bitAnd: 16r3F)].
	bytecode = 250 ifTrue:
		["**	250  11111010  eeiiikkk  jjjjjjjj  Push Closure Num Copied iii (+ExtA//16*8) Num Args kkk (+ ExtA\\16*8) BlockSize jjjjjjjj (+ExtB*256). ee = num extensions"
		 ^client
			pushClosureCopyNumCopiedValues: ((byte2 bitShift: -3) bitAnd: 7) + (extA // 16 bitShift: 3)
			numArgs: (byte2 bitAnd: 7) + (extA \\ 16 bitShift: 3)
			blockSize: byte3 + (extB bitShift: 8)].
	bytecode = 251 ifTrue:
		[^client pushRemoteTemp: byte2 inVectorAt: byte3].
	bytecode = 252 ifTrue:
		[^client storeIntoRemoteTemp: byte2 inVectorAt: byte3].
	bytecode = 253 ifTrue:
		[^client popIntoRemoteTemp: byte2 inVectorAt: byte3].
	"**	254		11111110	kkkkkkkk	jjjjjjjj		branch If Not Instance Of Behavior/Array Of Behavior kkkkkkkk (+ Extend A * 256, where Extend A >= 0) distance jjjjjjjj (+ Extend B * 256, where Extend B >= 0)"
	bytecode = 254 ifTrue: "The sign bit of extB inverts the operation.  Would like to have extB < -128, but this is good enough for now."
		[extB < 0 ifTrue: [^client branchIfInstanceOf: literal distance: (extB + 128 bitShift: 8) + byte3].
		 ^client branchIfNotInstanceOf: literal distance: (extB bitShift: 8) + byte3].
	^self unusedBytecode: client at: startPC
]

{ #category : #'*BytecodeSets-NewsqueakV3-decoding' }
InstructionStream >> interpretNextNSV3InstructionFor: client [ 
	"Send to the argument, client, a message that specifies the type of the 
	 next instruction."

	| byte type offset method |
	method := self method.  
	byte := method at: pc.
	type := byte // 16.  
	offset := byte \\ 16.  
	pc := pc+1.
	"We do an inline binary search on each of the possible 16 values of type."
	type < 8 ifTrue:
		[type < 4 ifTrue:
			[type < 2 ifTrue:
				[type = 0 ifTrue:
					[^ client pushReceiverVariable: offset].
				^ client pushTemporaryVariable: offset].				"type = 1"
			type = 2 ifTrue: 
				[^ client pushConstant: (method literalAt: offset + 1)].
			^ client pushConstant: (method literalAt: offset + 17)].		"type = 3"
		type < 6 ifTrue:
			[type = 4 ifTrue:
				[^ client pushLiteralVariable: (method literalAt: offset + 1)].
			^ client pushLiteralVariable: (method literalAt: offset + 17)]."type = 5"
		type = 6 ifTrue:
			[offset < 8 ifTrue:
				[^ client popIntoReceiverVariable: offset].
			^ client popIntoTemporaryVariable: offset - 8].
		"type = 7"
		offset = 0 ifTrue: [^ client pushReceiver].
		offset < 8 ifTrue: [^ client pushConstant: (SpecialConstants at: offset)].
		offset = 8 ifTrue: [^ client methodReturnReceiver].
		offset < 12 ifTrue: [^ client methodReturnConstant: (SpecialConstants at: offset - 8)].
		offset = 12 ifTrue: [^ client methodReturnTop].
		offset = 13 ifTrue: [^ client blockReturnTop].
		offset = 14 ifTrue:
			[| byte2 |
			byte := method at: pc.
			pc := pc+1.
			byte2 := method at: pc.
			pc := pc+1.
			^ client sendToDynamicSuperclass: (method literalAt: byte2 + 1) numArgs: byte].
		 "offset = 15"
		byte := method at: pc.
		pc := pc+1.
		^ client pushImplicitReceiverForMessage: (method literalAt: byte + 1)].
	type < 12 ifTrue:
		[type < 10 ifTrue:
			[type = 8 ifTrue:
				[^ self
					interpretNSV3Extension: offset
					in: method
					for: client].
			"type = 9 (short jumps)"
			offset < 8 ifTrue: [^ client jump: offset + 1].
			^ client jump: offset - 8 + 1 if: false].
		type = 10 ifTrue: "(long jumps)"
			[byte := method at: pc.
			pc := pc + 1.
			offset < 8 ifTrue: [^ client jump: offset - 4 * 256 + byte].
			^ client jump: (offset bitAnd: 3) * 256 + byte if: offset < 12].
		"type = 11; arithmetic special selector sends"
		^ client
			send: (Smalltalk specialSelectorAt: offset + 1)
			super: false
			numArgs: (Smalltalk specialNargsAt: offset + 1)].
		type = 12 ifTrue: "non-arithmetic special selector sends"
			[^ client
				send: (Smalltalk specialSelectorAt: offset + 17)
				super: false
				numArgs: (Smalltalk specialNargsAt: offset + 17)].
	"type = 13, 14 or 15"
	^ client
		send: (method literalAt: offset + 1)
		super: false
		numArgs: type - 13 "0, 1 & 2"
]

{ #category : #'*BytecodeSets-NewsqueakV4-decoding' }
InstructionStream >> interpretNextNSV4InstructionFor: client [
	"Send to the argument, client, a message that specifies the next instruction."

	| byte div16 offset method extA extB savedPC |
	method := self method.
	"For a table of the bytecode set, see EncoderForNewsqueakV4's class comment."
	"consume and compute any extensions first."
	extA := extB := 0.
	savedPC := pc.
	[byte := self method at: pc.
	 pc := pc + 1.
	 byte >= 224 and: [byte <= 225]] whileTrue:
		[| extByte |
		 extByte := self method at: pc.
		 pc := pc + 1.
		 byte = 224
			ifTrue:
				[extA := (extA bitShift: 8) + extByte]
			ifFalse:
				[extB := (extB = 0 and: [extByte > 127])
							ifTrue: [extByte - 256]
							ifFalse: [(extB bitShift: 8) + extByte]]].
	div16 := byte // 16.
	offset := byte \\ 16.
	"We do an inline quasi-binary search on each of the possible 16 values of div16"
	div16 < 12 ifTrue:
		[div16 < 4 ifTrue:
			[div16 < 2 ifTrue:
				[div16 = 0 ifTrue:
					 [^client pushReceiverVariable: offset].
				^client pushLiteralVariable: (method literalAt: offset + 1)]. "div16 = 1"
			 ^client pushConstant: (method literalAt: byte \\ 32 + 1)].
		 div16 = 4 ifTrue:
			[offset < 12 ifTrue:
				[^client pushTemporaryVariable: offset].
			 offset < 14 ifTrue:
				[offset = 12 ifTrue:
					[^client pushReceiver].
				 extB = 0 ifTrue:
					[^client pushConstant: false].
				 ^self interpretNSV4ExtendedPush: extB for: client].
			 ^client pushConstant: offset - 14]. "0 & 1"
		"short sends"
		div16 < 7 ifTrue: "special selector sends"
			[div16 = 5 ifTrue:
				[^client
					send: (Smalltalk specialSelectorAt: offset + 1)
					super: false
					numArgs: (Smalltalk specialNargsAt: offset + 1)].
			 ^client
				send: (Smalltalk specialSelectorAt: offset + 17)
				super: false
				numArgs: (Smalltalk specialNargsAt: offset + 17)].
		div16 < 10 ifTrue: "vanilla sends, div16 = 7, 8 & 9"
			[^client
				send: (method literalAt: offset + 1)
				super: false
				numArgs: div16 - 7].
		"implicit receiver send, div16 = 10"
		 div16 = 10 ifTrue:
			[^client
				sendToAbsentImplicitReceiver: (method literalAt: offset + 1)
				numArgs: 0].
		"short store pops"
		offset < 8 ifTrue:
			[^client popIntoReceiverVariable: offset].
		^client popIntoTemporaryVariable: offset - 8].
	"div16 >= 12"
	div16 < 14 ifTrue:
		[div16 = 12 ifTrue:
			[offset < 8 ifTrue:
				[^client jump: offset + 1].
			 ^client jump: offset - 7 if: true].
		 offset < 8 ifTrue:
			[^client jump: offset + 1 if: false].
		 offset < 11 ifTrue:
		 	[offset = 8 ifTrue: [^client methodReturnReceiver].
			 offset = 9 ifTrue: [^client methodReturnTop].
			 extA > 0 ifTrue:
				[^client blockReturnTopFromLevel: extA].
			 ^client blockReturnTop].
		 offset = 11 ifTrue:
			[^client doDup].
		 offset = 12 ifTrue:
			[^client doPop].
		 offset = 13 ifTrue:
			[^client doNop].
		"222		11011110		break ?  could have blockCopy: send break, but need a receiver and a pop result"
		"223		11011111		UNASSIGNED"
		^self unusedBytecode: client at: savedPC].
	"2 byte and 3 byte codes"
	byte < 249 ifTrue:
		[^self interpretNext2ByteNSV4Instruction: byte for: client extA: extA extB: extB startPC: savedPC].
	^self interpretNext3ByteNSV4Instruction: byte for: client extA: extA extB: extB startPC: savedPC
]

{ #category : #'*BytecodeSets-SistaV1-decoding' }
InstructionStream >> interpretNextSistaV1InstructionFor: client [
	"Send to the argument, client, a message that specifies the next instruction."

	| byte div16 offset method extA extB savedPC |
	method := self method.
	"For a table of the bytecode set, see EncoderForSistaV1's class comment."
	"consume and compute any extensions first."
	extA := extB := 0.
	savedPC := pc.
	[byte := self method at: pc.
	 pc := pc + 1.
	 byte >= 16rE0 and: [byte <= 16rE1]] whileTrue:
		[| extByte |
		 extByte := self method at: pc.
		 pc := pc + 1.
		 byte = 16rE0
			ifTrue:
				[extA := (extA bitShift: 8) + extByte]
			ifFalse:
				[extB := (extB = 0 and: [extByte > 127])
							ifTrue: [extByte - 256]
							ifFalse: [(extB bitShift: 8) + extByte]]].
	div16 := byte // 16.
	offset := byte \\ 16.
	"We do an inline quasi-binary search on each of the possible 16 values of div16"
	div16 < 11 ifTrue:
		[div16 < 6 ifTrue:
			[div16 < 4 ifTrue:
				[div16 < 2 ifTrue:
					[div16 = 0 ifTrue:
						 [^client pushReceiverVariable: offset].
					^client pushLiteralVariable: (method literalAt: offset + 1)]. "div16 = 1"
				 ^client pushConstant: (method literalAt: byte \\ 32 + 1)].
			 div16 = 4 ifTrue:
				[offset < 12 ifTrue:
					[^client pushTemporaryVariable: offset].
				 offset = 12 ifTrue:
					[^client pushReceiver].
				 offset = 13 ifTrue:
					[^client pushConstant: true].
				 offset = 14 ifTrue:
					[^client pushConstant: false].
				 offset = 15 ifTrue:
					[^client pushConstant: nil]].
			"div16 = 5"
			 offset < 2 ifTrue:
				[^client pushConstant: offset].
			 offset = 2 ifTrue:
				[^self interpretSistaV1ExtendedPush: extB for: client].
			 offset = 3 ifTrue:
				[^client doDup].
			
			 offset = 8 ifTrue:
				[^client methodReturnReceiver].
			 offset = 9 ifTrue:
				[^client methodReturnConstant: true].
			 offset = 10 ifTrue:
				[^client methodReturnConstant: false].
			 offset = 11 ifTrue:
				[^client methodReturnConstant: nil].
			 offset = 12 ifTrue:
				[^client methodReturnTop].
			 offset = 13 ifTrue:
				[^client blockReturnConstant: nil].
			 offset = 14 ifTrue:
				[^client blockReturnTop].
			 offset = 15 ifTrue:
				[^client doNop].
			 ^self unusedBytecode: client at: savedPC].
		"short sends"
		div16 = 6 ifTrue:
			[^client
				send: (Smalltalk specialSelectorAt: offset + 1)
				super: false
				numArgs: (Smalltalk specialNargsAt: offset + 1)].
		 div16 = 7 ifTrue:
			[^client
				send: (Smalltalk specialSelectorAt: offset + 17)
				super: false
				numArgs: (Smalltalk specialNargsAt: offset + 17)].
		^client
			send: (method literalAt: offset + 1)
			super: false
			numArgs: div16 - 8].
	"div16 >= 11; bytecode >= 176"
	div16 < 14 ifTrue:
		[div16 = 11 ifTrue:
			[offset < 8 ifTrue:
				[^client jump: offset + 1].
			 ^client jump: offset - 7 if: true].
		 div16 = 12 ifTrue:
			[offset < 8 ifTrue:
				[^client jump: offset + 1 if: false].
			 ^client popIntoReceiverVariable: offset - 8].
		 "div16 = 13"
		 offset < 8 ifTrue:
		 	[^client popIntoTemporaryVariable: offset].
		 offset = 8 ifTrue: [ ^ client doPop ].
		 offset = 9 ifTrue: [ ^ client trap ].
		 ^self unusedBytecode: client at: savedPC].
	"2 byte and 3 byte codes"
	byte < 248 ifTrue:
		[^self interpretNext2ByteSistaV1Instruction: byte for: client extA: extA extB: extB startPC: savedPC].
	^self interpretNext3ByteSistaV1Instruction: byte for: client extA: extA extB: extB startPC: savedPC
]

{ #category : #'*BytecodeSets-SistaV1-decoding' }
InstructionStream >> interpretSistaV1ExtendedPush: extB for: client [
	"Implement the extended push for non-zero extensions."
	"*	82			01010010			Push thisContext, (then Extend B = 1 => push thisProcess)"
	extB = 0 ifTrue:
		[^client pushActiveContext].
	extB = 1 ifTrue:
		[^client pushActiveProcess].
	self error: 'undefined extended push'
]

{ #category : #'*BytecodeSets-SistaV1-decoding' }
InstructionStream >> interpretSistaV1Jump [
	"If the instruction at pc is an unconditional jump, interpret it, advancing the pc,
	 and answering the jump distance. Otherwise answer nil."

	"	176-183	10110 iii				Jump iii + 1 (i.e., 1 through 8)
	 *	225/16rE1	11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)
	 *	237		11101101	iiiiiiii		Jump #iiiiiiii (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	| method byte nextpc extB |
	method := self method.
	"consume and compute any extension first."
	extB := 0.
	nextpc := pc. "must not advance pc unless this is a jump."
	[byte := self method at: nextpc.
	 nextpc := nextpc + 1.
	 byte = 16rE1] whileTrue:
		[| extByte |
		 extByte := self method at: nextpc.
		 nextpc := nextpc + 1.
		 extB := (extB = 0 and: [extByte > 127])
					ifTrue: [extByte - 256]
					ifFalse: [(extB bitShift: 8) + extByte]].
	(byte between: 176 and: 183) ifTrue:
		[pc := nextpc.
		 ^byte - 191].
	byte = 237 ifTrue:
		[byte := method at: nextpc.
		 pc := nextpc + 1.
		 ^(extB bitShift: 8) + byte].
	^nil
]

{ #category : #'*BytecodeSets-SistaV1-decoding' }
InstructionStream >> interpretSistaV1JumpIfCond [
	"If the instruction at pc is a conditional jump, interpret it, advancing the pc,
	 and answering the jump distance. Otherwise answer nil."

	"	184-191	10111 iii				Pop and Jump 0n True iii +1 (i.e., 1 through 8)
		192-199	11000 iii				Pop and Jump 0n False iii +1 (i.e., 1 through 8)
	 *	225/E1		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)
	 *	238		11101110	iiiiiiii		Pop and Jump 0n True #iiiiiiii (+ Extend B * 256, where Extend B >= 0)
	 *	239		11101111	iiiiiiii		Pop and Jump 0n False #iiiiiiii (+ Extend B * 256, where Extend B >= 0)"
	| method byte nextpc extB |
	method := self method.
	"consume and compute any extension first."
	extB := 0.
	nextpc := pc. "must not advance pc unless this is a jump."
	[byte := self method at: nextpc.
	 nextpc := nextpc + 1.
	 byte = 16rE1] whileTrue:
		[| extByte |
		 extByte := self method at: nextpc.
		 nextpc := nextpc + 1.
		 extB := (extB = 0 and: [extByte > 127])
					ifTrue: [extByte - 256]
					ifFalse: [(extB bitShift: 8) + extByte]].
	(byte between: 184 and: 199) ifTrue:
		[pc := nextpc.
		 ^(byte bitAnd: 7) + 1].
	(byte between: 238 and: 239) ifTrue:
		[byte := method at: nextpc.
		 pc := nextpc + 1.
		 ^(extB bitShift: 8) + byte].
	^nil
]

{ #category : #'*BytecodeSets-NewsqueakV4-decoding' }
InstructionStream >> pushExplicitOuter: n [ "<Integer>"
	self subclassResponsibility
]
