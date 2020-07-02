Class {
	#name : #CogInLineLiteralsARMCompiler,
	#superclass : #CogARMCompiler,
	#category : #'VMMaker-JIT'
}

{ #category : #'inline cacheing' }
CogInLineLiteralsARMCompiler >> callFullTargetFromReturnAddress: callSiteReturnAddress [
	"Answer the address that the call immediately preceding callSiteReturnAddress will jump to."
	"this is also used by #jumpLongTargetBeforeFollowingAddress: and so we check for both call and jump related instructions; later on we can use simpler tests once it feels safe to assume we get here always with a call/jump in the proper place"
	| call |
	call := self instructionBeforeAddress: callSiteReturnAddress.
	self assert: ((self instructionIsBX: call) or: [self instructionIsBLX: call]).
	"A Long Call/Jump. Extract the value saved to RISCTempReg from all the instructions before."
	^self extract32BitOperandFrom4Instructionspreceding: callSiteReturnAddress - 4
]

{ #category : #accessing }
CogInLineLiteralsARMCompiler >> cmpC32RTempByteSize [
	^20
]

{ #category : #initialization }
CogInLineLiteralsARMCompiler >> cogit: aCogit [
	<doNotGenerate>
	"There is no support for synthesizing 64-bit constants using inline instructions in this code generator."
	self assert: aCogit objectMemory wordSize = 4.
	super cogit: aCogit
]

{ #category : #testing }
CogInLineLiteralsARMCompiler >> extract32BitOperandFrom4InstructionsPreceding: addr [
	<inline: true>
	^(objectMemory byteAt: addr -4) 
	 + ((objectMemory byteAt: addr - 8) << 8) 
	 + ((objectMemory byteAt: addr - 12) << 16) 
	 + ((objectMemory byteAt: addr - 16) << 24)
]

{ #category : #accessing }
CogInLineLiteralsARMCompiler >> getDefaultCogCodeSize [
	"Return the default number of bytes to allocate for native code at startup.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file."
	<inline: true>
	^1024 * 1536
]

{ #category : #'inline cacheing' }
CogInLineLiteralsARMCompiler >> inlineCacheTagAt: callSiteReturnAddress [
	"Answer the inline cache tag for the return address of a send."
	self assert: (self instructionIsBL: (self instructionBeforeAddress: callSiteReturnAddress)).
	^self extract32BitOperandFrom4InstructionsPreceding: callSiteReturnAddress - 4
]

{ #category : #testing }
CogInLineLiteralsARMCompiler >> insert32BitOperand: operand into4InstructionsPreceding: addr [
	<inline: true>
	objectMemory
		byteAt: addr -   4 put: (operand			bitAnd: 16rFF);
		byteAt: addr -   8 put: (operand >>   8	bitAnd: 16rFF);
		byteAt: addr - 12 put: (operand >> 16	bitAnd: 16rFF);
		byteAt: addr - 16 put: (operand >> 24	bitAnd: 16rFF)
]

{ #category : #testing }
CogInLineLiteralsARMCompiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction."
	^self isJump or: [opcode = AlignmentNops]
]

{ #category : #'inline cacheing' }
CogInLineLiteralsARMCompiler >> literal32BeforeFollowingAddress: followingAddress [
	"Answer the 32-bit constant loaded by a MOV/ORR/ORR/ORR
	 or MOV/ORR/ORR/ORR/PUSH, or MOV/ORR/ORR/ORR/CMP sequence, just before this address:"
	^(self instructionIsOR: (self instructionBeforeAddress: followingAddress))
		ifTrue: [self extract32BitOperandFrom4InstructionsPreceding: followingAddress]
		ifFalse: [self extract32BitOperandFrom4InstructionsPreceding: followingAddress - 4]
]

{ #category : #'inline cacheing' }
CogInLineLiteralsARMCompiler >> literalBeforeFollowingAddress: followingAddress [
	"Answer the long constant loaded by a MOV/ORR/ORR/ORR
	 or MOV/ORR/ORR/ORR/PUSH, or MOV/ORR/ORR/ORR/CMP sequence, just before this address:"
	^(self instructionIsOR: (self instructionBeforeAddress: followingAddress))
		ifTrue: [self extract32BitOperandFrom4InstructionsPreceding: followingAddress]
		ifFalse: [self extract32BitOperandFrom4InstructionsPreceding: followingAddress - 4]
]

{ #category : #accessing }
CogInLineLiteralsARMCompiler >> literalLoadInstructionBytes [
	"Answer the size of a literal load instruction.  With in-line literals this is 4 instructions."
	<inline: true>
	^16
]

{ #category : #accessing }
CogInLineLiteralsARMCompiler >> loadLiteralByteSize [
	"Answer the byte size of a MoveCwR opcode's corresponding machine code. On ARM this is a single instruction pc-relative register load - unless we have made a mistake and not turned on the out of line literals manager"
	^16
]

{ #category : #'generate machine code - support' }
CogInLineLiteralsARMCompiler >> moveCw: constant intoR: destReg [
	"Emit a load of aWord into destReg.  Because most ARM instruction enable using a (8-12bit) offset relative to a
	 register, the LS Byte can be included in that instruction, saving one instruction. This is done in a decorator,
	 e.g. concretizeDataOperationCwR:  Generates along the lines of
		MOV destReg, #<constantByte3>, 12
		ORR destReg, destReg, #<constantByte2>, 8
		ORR destReg, destReg, #<constantByte1>, 4
		ORR destReg, destReg, #<constantByte0>, 0
	 with minimal choice of the rotation (last digit).
	 The same register can be modified multiple times, because the operation is (inclusive) or."
	 <var: 'constant' type: #usqInt>
	<inline: true>
	"self assert: destReg < 12."

	self machineCodeAt: 0 put: (self mov: destReg imm: (constant >>24 bitAnd: 16rFF) ror: 8).
	self machineCodeAt: 4 put: (self orr: destReg imm: (constant >> 16 bitAnd: 16rFF) ror: 16).
	self machineCodeAt: 8 put: (self orr: destReg imm: (constant >> 8 bitAnd: 16rFF) ror: 24).
	self machineCodeAt: 12 put: (self orr: destReg imm: (constant bitAnd: 16rFF) ror: 0).
	^16
]

{ #category : #'inline cacheing' }
CogInLineLiteralsARMCompiler >> relocateMethodReferenceBeforeAddress: pc by: delta [
	"If possible we generate the method address using pc-relative addressing.
	 If so we don't need to relocate it in code.  So check if pc-relative code was
	 generated, and if not, adjust a long sequence.  There are two cases, a push
	 or a register load.  If a push, then there is a register load, but in the instruction
	 before."
	| pcPrecedingLoad reference |
	pcPrecedingLoad := (self instructionIsPush: (self instructionBeforeAddress: pc))
							ifTrue: [pc - 4]
							ifFalse: [pc].
	"If the load is not done via pc-relative addressing we have to relocate."
	(self isPCRelativeValueLoad: (self instructionBeforeAddress: pcPrecedingLoad)) ifFalse:
		[reference := self extract32BitOperandFrom4InstructionsPreceding: pcPrecedingLoad.
		 reference := reference + delta.
		 self insert32BitOperand: reference into4InstructionsPreceding: pcPrecedingLoad]
]

{ #category : #'inline cacheing' }
CogInLineLiteralsARMCompiler >> rewriteFullTransferAt: callSiteReturnAddress target: callTargetAddress expectedInstruction: expectedInstruction [
	"Rewrite a CallFull or JumpFull instruction to transfer to a different target.
	 This variant is used to rewrite cached primitive calls.   Answer the extent
	 of the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	"cogit disassembleFrom: callSiteReturnAddress - 20 to: callSiteReturnAddress - 1"
	self assert: (self instructionBeforeAddress: callSiteReturnAddress) = expectedInstruction.
	self insert32BitOperand: callTargetAddress into4InstructionsPreceding: callSiteReturnAddress - 4.
	self assert: (self callFullTargetFromReturnAddress: callSiteReturnAddress) signedIntToLong = callTargetAddress.
	^20
]

{ #category : #'inline cacheing' }
CogInLineLiteralsARMCompiler >> rewriteInlineCacheAt: callSiteReturnAddress tag: cacheTag target: callTargetAddress [
	"Rewrite an inline cache to call a different target for a new tag.  This variant is used
	 to link unlinked sends in ceSend:to:numArgs: et al.  Answer the extent of the code
	 change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	| call callDistance |
	false
		ifTrue: [self assert: callTargetAddress >= cogit minCallAddress]
		ifFalse: [callTargetAddress >= cogit minCallAddress ifFalse:
					[self error: 'linking callsite to invalid address']].
	callDistance := (callTargetAddress - (callSiteReturnAddress + 8 "pc offset"- 4 "return offset")) signedIntToLong.
	self assert: (self isInImmediateJumpRange: callDistance). "we don't support long call updates here"
	call := self bl: callDistance.
	objectMemory longAt: (self instructionAddressBefore: callSiteReturnAddress ) put: call.
	self insert32BitOperand: cacheTag into4InstructionsPreceding: (self instructionAddressBefore: callSiteReturnAddress ).
	self assert: (self callTargetFromReturnAddress: callSiteReturnAddress) = callTargetAddress.
	self assert: (self extract32BitOperandFrom4InstructionsPreceding: (self instructionAddressBefore: callSiteReturnAddress )) = cacheTag.
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 20 to: callSiteReturnAddress - 1]."
	^20
]

{ #category : #'inline cacheing' }
CogInLineLiteralsARMCompiler >> rewriteInlineCacheTag: cacheTag at: callSiteReturnAddress [
	"Rewrite an inline cache with a new tag.  This variant is used
	 by the garbage collector."
	self insert32BitOperand: cacheTag into4InstructionsPreceding: callSiteReturnAddress -4
]

{ #category : #'generate machine code' }
CogInLineLiteralsARMCompiler >> sizePCDependentInstructionAt: eventualAbsoluteAddress [
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceding instruction or to an absolute address is
	 between that instruction's address (which by now is its eventual absolute
	 address) or absolute address and eventualAbsoluteAddress.

	 ARM is simple; the 26-bit call/jump range means no short jumps.  This routine
	 only has to determine the targets of jumps, not determine sizes."

	opcode = AlignmentNops ifTrue:
		[| alignment |
		 address := eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: (self isJump or: [opcode = Call or: [opcode = CallFull]]).
	self isJump ifTrue: [self resolveJumpTarget].
	address := eventualAbsoluteAddress.
	^machineCodeSize := maxSize
]

{ #category : #'inline cacheing' }
CogInLineLiteralsARMCompiler >> storeLiteral: literal beforeFollowingAddress: followingAddress [
	"Rewrite the long constant loaded by a MOV/ORR/ORR/ORR
	 or MOV/ORR/ORR/ORR/PUSH  sequence, just before this address:"
	^(self instructionIsOR: (self instructionBeforeAddress: followingAddress))
		ifTrue: [self insert32BitOperand: literal into4InstructionsPreceding: followingAddress]
		ifFalse: [self insert32BitOperand: literal into4InstructionsPreceding: followingAddress - 4]
]
