Class {
	#name : #CogInLineLiteralsX64Compiler,
	#superclass : #CogX64Compiler,
	#category : #'VMMaker-JIT'
}

{ #category : #'class initialization' }
CogInLineLiteralsX64Compiler class >> initializeAbstractRegistersSysV [
	"Assign the abstract registers with the identities/indices of the relevant concrete registers."

	super initializeAbstractRegistersSysV.
	RISCTempReg := R8
]

{ #category : #'class initialization' }
CogInLineLiteralsX64Compiler class >> initializeAbstractRegistersWin64 [
	"Assign the abstract registers with the identities/indices of the relevant concrete registers."

	super initializeAbstractRegistersWin64.
	RISCTempReg := R11
]

{ #category : #testing }
CogInLineLiteralsX64Compiler class >> isRISCTempRegister: reg [
	"For tests to filter-out bogus values left in the RISCTempRegister, if any."
	^reg = RISCTempReg
]

{ #category : #'generate machine code' }
CogInLineLiteralsX64Compiler >> computeSizeOfArithCqR [
	"With CqR we assume constants are 32-bits or less."
	<inline: true>
	(self isQuick: (operands at: 0)) ifTrue:
		[^4].
	(self is32BitSignedImmediate: (operands at: 0)) ifTrue:
		[^(operands at: 1) = RAX ifTrue: [6] ifFalse: [7]].
	^10 "movabsq" + 3 "r op r"
]

{ #category : #'generate machine code' }
CogInLineLiteralsX64Compiler >> computeSizeOfArithCwR [
	<inline: true>
	^10 "MoveCwR" +  3 "ArithRR"
]

{ #category : #'generate machine code' }
CogInLineLiteralsX64Compiler >> concretizeArithCwR: x64opcode [
	| value reg reverse |
	value := operands at: 0.
	reg := operands at: 1.
	reverse := x64opcode = 16r85 or: [x64opcode = 16r39]. "Tst & Cmp; backwards"
	machineCode
		at:  0 put: (self rexR: RISCTempReg x: 0 b: RISCTempReg);
		at:  1 put: 16rB8 + (RISCTempReg bitAnd: 7);
		at:  2 put: (value bitAnd: 16rFF);
		at:  3 put: (value >> 8 bitAnd: 16rFF);
		at:  4 put: (value >> 16 bitAnd: 16rFF);
		at:  5 put: (value >> 24 bitAnd: 16rFF);
		at:  6 put: (value >> 32 bitAnd: 16rFF);
		at:  7 put: (value >> 40 bitAnd: 16rFF);
		at:  8 put: (value >> 48 bitAnd: 16rFF);
		at:  9 put: (value >> 56 bitAnd: 16rFF);
		at: 10 put: (reverse
					ifTrue: [self rexR: RISCTempReg x: 0 b: reg]
					ifFalse: [self rexR: reg x: 0 b: RISCTempReg]);
		at: 11 put: x64opcode;
		at: 12 put: (reverse
					ifTrue: [self mod: ModReg RM: reg RO: RISCTempReg]
					ifFalse: [self mod: ModReg RM: RISCTempReg RO: reg]).
	self assert: (machineCode at: 12) > 16r90. "See literalBeforeFollowingAddress:"
	^machineCodeSize := 13
]

{ #category : #'generate machine code' }
CogInLineLiteralsX64Compiler >> concretizeMoveCwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg offset |
	value := operands at: 0.
	reg := operands at: 1.
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
		at:  0 put: (self rexR: 0 x: 0 b: reg);
		at:  1 put: 16rB8 + (reg bitAnd: 7);
		at:  2 put: (value bitAnd: 16rFF);
		at:  3 put: (value >> 8 bitAnd: 16rFF);
		at:  4 put: (value >> 16 bitAnd: 16rFF);
		at:  5 put: (value >> 24 bitAnd: 16rFF);
		at:  6 put: (value >> 32 bitAnd: 16rFF);
		at:  7 put: (value >> 40 bitAnd: 16rFF);
		at:  8 put: (value >> 48 bitAnd: 16rFF);
		at:  9 put: (value >> 56 bitAnd: 16rFF).
	"Add a nop to disambiguate between MoveCwR/PushCw and ArithCwR, which ends with a (self mod: ModReg RM: 0 RO: 0)"
	machineCode at: 10 put: 16r90.
	^machineCodeSize := 11
]

{ #category : #'as yet unclassified' }
CogInLineLiteralsX64Compiler >> concretizeMovePatcheableC32R [
	
	^ self concretizeMoveC32R
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
			at: 0 put: (self rexR: RISCTempReg x: 0 b: 0);
			at: 1 put: 16r8D; "LoadEffectiveAddress"
			at: 2 put: (self mod: ModRegInd RM: 5 RO: RISCTempReg);
			at: 3 put: (offset bitAnd: 16rFF);
			at: 4 put: (offset >> 8 bitAnd: 16rFF);
			at: 5 put: (offset >> 16 bitAnd: 16rFF);
			at: 6 put: (offset >> 24 bitAnd: 16rFF);
			at: 7 put: 16r41;
			at: 8 put: 16r48 + RISCTempReg.
		^machineCodeSize := 9].
	machineCode
		at:  0 put: (self rexR: RISCTempReg x: 0 b: RISCTempReg);
		at:  1 put: 16rB8 + (RISCTempReg bitAnd: 7);
		at:  2 put: (value bitAnd: 16rFF);
		at:  3 put: (value >> 8 bitAnd: 16rFF);
		at:  4 put: (value >> 16 bitAnd: 16rFF);
		at:  5 put: (value >> 24 bitAnd: 16rFF);
		at:  6 put: (value >> 32 bitAnd: 16rFF);
		at:  7 put: (value >> 40 bitAnd: 16rFF);
		at:  8 put: (value >> 48 bitAnd: 16rFF);
		at:  9 put: (value >> 56 bitAnd: 16rFF);
		at: 10 put: 16r41;
		at: 11 put: 16r48 + RISCTempReg. "The 48 will disambiguate between MoveCwR, PushCw and ArithCwR, which ends with a (self mod: ModReg RM: 0 RO: 0)"
	self assert: (machineCode at: 11) < 16r90. "see literalBeforeFollowingAddress:"
	^machineCodeSize := 12
]

{ #category : #accessing }
CogInLineLiteralsX64Compiler >> getDefaultCogCodeSize [
	"Answer the default number of bytes to allocate for native code at startup.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file."
	<inline: true>
	^1024 * 1400
]

{ #category : #'inline cacheing' }
CogInLineLiteralsX64Compiler >> inlineCacheTagAt: callSiteReturnAddress [
	"Answer the inline cache tag for the return address of a send."
	^self literal32BeforeFollowingAddress: callSiteReturnAddress - 5
]

{ #category : #testing }
CogInLineLiteralsX64Compiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction."
	^self isJump or: [opcode = AlignmentNops]
]

{ #category : #'inline cacheing' }
CogInLineLiteralsX64Compiler >> literal32BeforeFollowingAddress: followingAddress [
	"Answer the 32-bit literal embedded in the instruction immediately preceding followingAddress."
	^cogit
		cCoerceSimple: (self unalignedLong32At: followingAddress - 4)
		to: #'unsigned int'
]

{ #category : #'inline cacheing' }
CogInLineLiteralsX64Compiler >> literalBeforeFollowingAddress: followingAddress [
	"Answer the literal embedded in the instruction immediately preceding followingAddress.
	 This is used in the MoveCwR, PushCw and ArithCwR cases; these are distinguished by a
	 nop following the literal load in MoveCwR, a 16r48 + reg ending the PushCw sequence, and
	 a (self mod: ModReg RM: rX RO: rY) ending the ArithCwR sequence, which is at least 16rC0."
	| lastByte base |
	lastByte := objectMemory byteAt: followingAddress - 1.
	base := followingAddress - (lastByte = 16r90
									ifTrue: [9]				"MoveCwR"
									ifFalse:
										[lastByte < 16r90
											ifTrue: [10]		"PushCw"
											ifFalse: [11]]).	"ArithCwR"
	^objectMemory unalignedLongAt: base
	
	"(Symbol allSymbols select: [:s| '*Cw:R:' match: s]), {#PushCw:} collect: [:s| {s. (self systemNavigation allCallsOn: s localToPackage: #VMMaker) size}]"
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
	opcode >= FirstShortJump
		ifTrue:
			[machineCodeSize := (self isQuick: maximumSpan)
									ifTrue: [2]
									ifFalse: [opcode = Jump
												ifTrue: [5]
												ifFalse: [6]]]
		ifFalse:
			[machineCodeSize := opcode caseOf:
									{	[JumpLong]				->	[5].
										[JumpFull]				->	[12].
										[JumpLongZero]		->	[6].
										[JumpLongNonZero]	->	[6] }].
	^machineCodeSize "Slang can't inline the switch into the ifTrue:ifFalse: correctly"
]

{ #category : #'inline cacheing' }
CogInLineLiteralsX64Compiler >> storeLiteral: literal beforeFollowingAddress: followingAddress [
	"Rewrite the literal in the instruction immediately preceding followingAddress.
	 This is used in the MoveCwR, PushCw and CmpCwR cases; these are distinguished by a
	 nop following the literal load in MoveCwR, a 16r50 + reg ending the PushCw sequence, and
	 a (self mod: ModReg RM: rX RO: rY) ending the CmpCwR sequence, which is at least 16rC0."
	| lastByte base |
	lastByte := objectMemory byteAt: followingAddress - 1.
	base := followingAddress - (lastByte <= 16r90
									ifTrue:
										[lastByte = 16r90
											ifTrue: [9]		"MoveCwR"
											ifFalse: [10]]	"PushCw"
									ifFalse: [11]).			"ArithCwR"
	objectMemory unalignedLongAt: base put: literal
]
