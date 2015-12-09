Class {
	#name : #CogInLineLiteralsX64Compiler,
	#superclass : #CogX64Compiler,
	#classVars : [
		'ConcreteRISCTempReg'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'class initialization' }
CogInLineLiteralsX64Compiler class >> initialize [
	ConcreteRISCTempReg := self basicNew concreteRegister: RISCTempReg
]

{ #category : #testing }
CogInLineLiteralsX64Compiler class >> isConcreteRISCTempRegister: concreteRegister [
	"For tests to filter-out bogus values left in the ConcreteRISCTempRegister, if any."
	^concreteRegister = ConcreteRISCTempReg
]

{ #category : #'generate machine code' }
CogInLineLiteralsX64Compiler >> computeSizeOfArithCqR [
	"With CqR we assume constants are 32-bits or less."
	<inline: true>
	(self isQuick: (operands at: 0)) ifTrue:
		[^4].
	(self isSignExtendedFourByteValue: (operands at: 0)) ifTrue:
		[^(self concreteRegister: (operands at: 1)) = RAX
			ifTrue: [6]
			ifFalse: [7]].
	^10 "movabsq" + 3 "r op r"
]

{ #category : #'generate machine code' }
CogInLineLiteralsX64Compiler >> computeSizeOfArithCwR [
	<inline: true>
	^10 "MoveCwR" +  3 "ArithRR"
]

{ #category : #encoding }
CogInLineLiteralsX64Compiler >> concreteRegister: registerIndex [
	 "Map a possibly abstract register into a concrete one.  Abstract registers
	  (defined in CogAbstractOpcodes) are all negative.  If registerIndex is
	 negative assume it is an abstract register.

	[1] Figure 3.4 Register Usage in
		System V Application Binary Interface
		AMD64 Architecture Processor Supplement


	N.B. RAX RCX & RDX are caller-save (scratch) registers.  Hence we use RCX for class and RDX for
		receiver/result since these are written in all normal sends."

	^registerIndex
		caseOf: {
			[TempReg]				-> [RAX].
			[ClassReg]				-> [RCX].
			[ReceiverResultReg]	-> [RDX].
			[SendNumArgsReg]		-> [R9].
			[SPReg]					-> [RSP].
			[FPReg]					-> [RBP].
			[Arg0Reg]				-> [RDI]. "So as to agree with C ABI arg 0"
			[Arg1Reg]				-> [RSI]. "So as to agree with C ABI arg 1"
			[VarBaseReg]			-> [RBX]. "Must be callee saved"
			[RISCTempReg]			-> [R8].
			[Scratch0Reg]			-> [R10].
			[Scratch1Reg]			-> [R11].
			[Scratch2Reg]			-> [R12].
			[Scratch3Reg]			-> [R13].
			[Scratch4Reg]			-> [R14].
			[Scratch5Reg]			-> [R15] }
		otherwise:
			[self assert: (registerIndex between: RAX and: R15).
			 registerIndex]
]

{ #category : #'generate machine code' }
CogInLineLiteralsX64Compiler >> concretizeArithCwR: opcode [
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	machineCode
		at:  0 put: (self rexR: ConcreteRISCTempReg x: 0 b: ConcreteRISCTempReg);
		at:  1 put: 16rB8 + (ConcreteRISCTempReg bitAnd: 7);
		at:  2 put: (value bitAnd: 16rFF);
		at:  3 put: (value >> 8 bitAnd: 16rFF);
		at:  4 put: (value >> 16 bitAnd: 16rFF);
		at:  5 put: (value >> 24 bitAnd: 16rFF);
		at:  6 put: (value >> 32 bitAnd: 16rFF);
		at:  7 put: (value >> 40 bitAnd: 16rFF);
		at:  8 put: (value >> 48 bitAnd: 16rFF);
		at:  9 put: (value >> 56 bitAnd: 16rFF);
		at: 10 put: (opcode = 16r85 "Tst; backwards"
					ifTrue: [self rexR: ConcreteRISCTempReg x: 0 b: reg]
					ifFalse: [self rexR: reg x: 0 b: ConcreteRISCTempReg]);
		at: 11 put: opcode;
		at: 12 put: (opcode = 16r85 "Tst; backwards"
					ifTrue: [self mod: ModReg RM: reg RO: ConcreteRISCTempReg]
					ifFalse: [self mod: ModReg RM: ConcreteRISCTempReg RO: reg]).
	^machineCodeSize := 13
]

{ #category : #'generate machine code' }
CogInLineLiteralsX64Compiler >> concretizeMoveCwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg offset |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	(self isAnInstruction: (cogit cCoerceSimple: value to: #'AbstractInstruction *')) ifTrue:
		[value := (cogit cCoerceSimple: value to: #'AbstractInstruction *') address].
	(cogit addressIsInCurrentCompilation: value) ifTrue:
		[offset := value - (address + 7).
		 machineCode
			at: 0 put: (self rexR: reg x: 0 b: 0);
			at: 1 put: 16r8D; "LoadEffectiveAddress"
			at: 2 put: (self mod: ModRegInd RM: 5 RO: reg);
			at: 3 put: (offset bitAnd: 16rFF);
			at: 4 put: (offset >> 8 bitAnd: 16rFF);
			at: 5 put: (offset >> 16 bitAnd: 16rFF);
			at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 7].
	machineCode
		at:  0 put: (self rexR: reg x: 0 b: reg);
		at:  1 put: 16rB8 + (reg bitAnd: 7);
		at:  2 put: (value bitAnd: 16rFF);
		at:  3 put: (value >> 8 bitAnd: 16rFF);
		at:  4 put: (value >> 16 bitAnd: 16rFF);
		at:  5 put: (value >> 24 bitAnd: 16rFF);
		at:  6 put: (value >> 32 bitAnd: 16rFF);
		at:  7 put: (value >> 40 bitAnd: 16rFF);
		at:  8 put: (value >> 48 bitAnd: 16rFF);
		at:  9 put: (value >> 56 bitAnd: 16rFF).
	opcode = MoveCqR ifTrue:
		[^machineCodeSize := 10].
	"Add a nop to disambiguate between MoveCwR/PushCwR and ArithCwR, which ends with a (self mod: ModReg RM: 0 RO: 0)"
	machineCode at: 10 put: 16r90.
	self assert: (self mod: ModReg RM: 0 RO: 0) > 16r90.
	^machineCodeSize := 11
]

{ #category : #'generate machine code' }
CogInLineLiteralsX64Compiler >> concretizePushCw [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value offset |
	value := operands at: 0.
	(self isAnInstruction: (cogit cCoerceSimple: value to: #'AbstractInstruction *')) ifTrue:
		[value := (cogit cCoerceSimple: value to: #'AbstractInstruction *') address].
	(cogit addressIsInCurrentCompilation: value) ifTrue:
		[offset := value - (address + 7).
		 machineCode
			at: 0 put: (self rexR: ConcreteRISCTempReg x: 0 b: 0);
			at: 1 put: 16r8D; "LoadEffectiveAddress"
			at: 2 put: (self mod: ModRegInd RM: 5 RO: ConcreteRISCTempReg);
			at: 3 put: (offset bitAnd: 16rFF);
			at: 4 put: (offset >> 8 bitAnd: 16rFF);
			at: 5 put: (offset >> 16 bitAnd: 16rFF);
			at: 6 put: (offset >> 24 bitAnd: 16rFF);
			at: 7 put: 16r41;
			at: 8 put: 16r48 + ConcreteRISCTempReg.
		^machineCodeSize := 9].
	machineCode
		at:  0 put: (self rexR: ConcreteRISCTempReg x: 0 b: ConcreteRISCTempReg);
		at:  1 put: 16rB8 + (ConcreteRISCTempReg bitAnd: 7);
		at:  2 put: (value bitAnd: 16rFF);
		at:  3 put: (value >> 8 bitAnd: 16rFF);
		at:  4 put: (value >> 16 bitAnd: 16rFF);
		at:  5 put: (value >> 24 bitAnd: 16rFF);
		at:  6 put: (value >> 32 bitAnd: 16rFF);
		at:  7 put: (value >> 40 bitAnd: 16rFF);
		at:  8 put: (value >> 48 bitAnd: 16rFF);
		at:  9 put: (value >> 56 bitAnd: 16rFF);
		at: 10 put: 16r41;
		at: 11 put: 16r48 + ConcreteRISCTempReg. "The 48 will disambiguate between MoveCwR, PushCwR and ArithCwR, which ends with a (self mod: ModReg RM: 0 RO: 0)"
		self assert: ConcreteRISCTempReg >= 8.
	self assert: (self mod: ModReg RM: 0 RO: 0) > 16r57.
	^machineCodeSize := 12
]

{ #category : #'inline cacheing' }
CogInLineLiteralsX64Compiler >> inlineCacheTagAt: callSiteReturnAddress [
	"Answer the inline cache tag for the return address of a send."
	^self thirtyTwoBitLiteralBefore: callSiteReturnAddress - 5
]

{ #category : #testing }
CogInLineLiteralsX64Compiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction."
	^self isJump or: [opcode = AlignmentNops]
]

{ #category : #'inline cacheing' }
CogInLineLiteralsX64Compiler >> literal32BeforeFollowingAddress: followingAddress [
	"Answer the 32-bit literal embedded in the instruction immediately preceding followingAddress."
	^  ((objectMemory byteAt: followingAddress - 1) << 24)
	+  ((objectMemory byteAt: followingAddress - 2) << 16)
	+  ((objectMemory byteAt: followingAddress - 3) << 8)
	+   (objectMemory byteAt: followingAddress - 4)
]

{ #category : #'inline cacheing' }
CogInLineLiteralsX64Compiler >> literalBeforeFollowingAddress: followingAddress [
	"Answer the literal embedded in the instruction immediately preceding followingAddress.
	 This is used in the MoveCwR, PushCwR and CmpCwR cases; these are distinguished by a
	 nop following the literal load in MoveCwR, a 16r50 + reg ending the PushCwR sequence, and
	 a (self mod: ModReg RM: rX RO: rY) ending the CmpCwR sequence, which is at least 16rC0."
	| lastByte base |
	lastByte := objectMemory byteAt: followingAddress - 1.
	base := followingAddress - (lastByte <= 16r90
									ifTrue:
										[lastByte = 16r90
											ifTrue: [9]		"MoveCwR"
											ifFalse: [10]]	"PushCwR"
									ifFalse: [11]).			"ArithCwR"
	^self cCode: [objectMemory unalignedLongAt: base]
		inSmalltalk:
			[   (objectMemory byteAt: base)
			+ ((objectMemory byteAt: base + 1) << 8)
			+ ((objectMemory byteAt: base + 2) << 16)
			+ ((objectMemory byteAt: base + 3) << 24)
			+ ((objectMemory byteAt: base + 4) << 32)
			+ ((objectMemory byteAt: base + 5) << 40)
			+ ((objectMemory byteAt: base + 6) << 48)
			+ ((objectMemory byteAt: base + 7) << 52)]
]

{ #category : #accessing }
CogInLineLiteralsX64Compiler >> loadLiteralByteSize [
	<inline: true>
	^self moveCwRByteSize
]

{ #category : #accessing }
CogInLineLiteralsX64Compiler >> moveCwRByteSize [
	"With in-line literals we use an 11 byte sequence for loading a 64-bit immediate,
	 which is one more than strictly necessary.  We plant a nop at the end of the
	 sequence to allow us to distinguish between this and the
	 (self mod: ModReg RM: rX RO: rY) at the end of an ArithCwR sequence."
	<inline: true>
	^11
]

{ #category : #accessing }
CogInLineLiteralsX64Compiler >> pushCwByteSize [
	"With in-line literals we use a 12 byte sequence for loading a 64-bit immediate, which
	 is one more than strictly necessary.  The sequence ends with a 16r50 + reg opcode
	 (PushR) to allow us to distinguish between this and the (self mod: ModReg RM: rX RO: rY)
	 at the end of an ArithCwR sequence."
	<inline: true>
	^12
]

{ #category : #'generate machine code' }
CogInLineLiteralsX64Compiler >> sizePCDependentInstructionAt: eventualAbsoluteAddress [
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceding instruction or to an absolute address is
	 between that instruction's address (which by now is its eventual absolute
	 address) or absolute address and eventualAbsoluteAddress."

	| target maximumSpan abstractInstruction |
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	opcode = AlignmentNops ifTrue:
		[| alignment |
		 address := eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: self isJump.
	target := operands at: 0.
	abstractInstruction := cogit cCoerceSimple: target to: #'AbstractInstruction *'.
	(self isAnInstruction: abstractInstruction)
		ifTrue:
			[maximumSpan := abstractInstruction address
							- (((cogit abstractInstruction: self follows: abstractInstruction)
								ifTrue: [eventualAbsoluteAddress]
								ifFalse: [address]) + 2)]
		ifFalse:
			[maximumSpan := target - (eventualAbsoluteAddress + 2)].
	address := eventualAbsoluteAddress.
	^machineCodeSize := opcode >= FirstShortJump
							ifTrue:
								[(self isQuick: maximumSpan)
									ifTrue: [2]
									ifFalse: [opcode = Jump
												ifTrue: [5]
												ifFalse: [6]]]
							ifFalse:
								[opcode caseOf:
									{	[JumpLong]				->	[5].
										[JumpFull]				->	[12].
										[JumpLongZero]		->	[6].
										[JumpLongNonZero]	->	[6] }]
]

{ #category : #'inline cacheing' }
CogInLineLiteralsX64Compiler >> storeLiteral: literal beforeFollowingAddress: followingAddress [
	"Rewrite the literal in the instruction immediately preceding followingAddress.
	 This is used in the MoveCwR, PushCwR and CmpCwR cases; these are distinguished by a
	 nop following the literal load in MoveCwR, a 16r50 + reg ending the PushCwR sequence, and
	 a (self mod: ModReg RM: rX RO: rY) ending the CmpCwR sequence, which is at least 16rC0."
	| lastByte base |
	lastByte := objectMemory byteAt: followingAddress - 1.
	base := followingAddress - (lastByte <= 16r90
									ifTrue:
										[lastByte = 16r90
											ifTrue: [9]		"MoveCwR"
											ifFalse: [10]]	"PushCwR"
									ifFalse: [11]).			"ArithCwR"
	self cCode: [objectMemory unalignedLongAt: base put: literal]
		inSmalltalk:
			[objectMemory
				byteAt: base put: (literal bitAnd: 16rFF);
				byteAt: base + 1 put: ((literal >> 8) bitAnd: 16rFF);
				byteAt: base + 2 put: ((literal >> 16) bitAnd: 16rFF);
				byteAt: base + 3 put: ((literal >> 24) bitAnd: 16rFF);
				byteAt: base + 4 put: ((literal >> 32) bitAnd: 16rFF);
				byteAt: base + 5 put: ((literal >> 40) bitAnd: 16rFF);
				byteAt: base + 6 put: ((literal >> 48) bitAnd: 16rFF);
				byteAt: base + 7 put: ((literal >> 52) bitAnd: 16rFF)]
]
