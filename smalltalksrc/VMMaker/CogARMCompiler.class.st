Class {
	#name : #CogARMCompiler,
	#superclass : #CogAbstractInstruction,
	#classVars : [
		'LR',
		'PC',
		'R0',
		'R1',
		'R10',
		'R11',
		'R12',
		'R2',
		'R3',
		'R4',
		'R5',
		'R6',
		'R7',
		'R8',
		'R9',
		'SP'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'class initialization' }
CogARMCompiler class >> initialize [
	super initialize.
	
	"Initialize various ARM instruction-related constants."
	"CogARMCompiler initialize"
	
	R0 := 0. R1 := 1.
	R2 := 2. R3 := 3.
	R4 := 4. R5 := 5.
	R6 := 6. R7 := 7.
	R8 := 8. R9 := 9.
	R10 := 10. R11 := 11.
	R12 := 12.
	SP := 13.
	LR := 14.
	PC := 15
]

{ #category : #'generate machine code' }
CogARMCompiler >> computeMaximumSize [
	"Because we don't use Thumb, each instruction has a multiple of 4 bytes. Most have exactly 4, but some abstract opcodes need more than one instruction."
	opcode 
		caseOf: {
			[Label]				-> [^maxSize := 0].
			[AlignmentNops]	-> [^maxSize := (operands at: 0) - 1].
			[MoveRAw]			-> [^maxSize := 16 "3 for loadAllButLSB"].
			[RetN]				-> [^(operands at: 0) = 0 
										ifTrue: [maxSize := 4]
										ifFalse: [maxSize := 8]]} 
		otherwise: [^maxSize := 4].
	^4 "to keep C compiler quiet"

]

{ #category : #encoding }
CogARMCompiler >> concreteRegister: registerIndex [
	 "Map a possibly abstract register into a concrete one.  Abstract registers
	  (defined in CogAbstractOpcodes) are all negative.  If registerIndex is
	 negative assume it is an abstract register."
	
	"N.B. According to BSABI, R0-R3 are caller-save, R4-R12 are callee save.
	Note that R9 might be a special register for the implementation. In some slides it is refered to as sb. R10 contains the stack limit (sl), R11 the fp. R12 is an intra-procedure scratch instruction pointer for link purposes.
	R3 is used as temporary inside a single abstract opcode implementation"

	^registerIndex
		caseOf: {
			[TempReg]				-> [R0].
			[ClassReg]				-> [R1].
			[ReceiverResultReg]	-> [R2].
			[SendNumArgsReg]		-> [R6].
			[SPReg]					-> [SP].
			[FPReg]					-> [R11].
			[Arg0Reg]				-> [R4].
			[Arg1Reg]				-> [R5] }
		otherwise:
			[self assert: (registerIndex between: R0 and: PC).
			 registerIndex]
]

{ #category : #'generate machine code' }
CogARMCompiler >> concretizeAt: actualAddress [
	"Generate concrete machine code for the instruction at actualAddress,
	 setting machineCodeSize, and answer the following address."

	self assert: actualAddress \\ 4 = 0.
	address := actualAddress.
	self dispatchConcretize.
	self assert: (maxSize = nil or: [maxSize >= machineCodeSize]).
	^actualAddress + machineCodeSize
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRAw [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destAddr loadSize |
	srcReg := self concreteRegister: (operands at: 0).
	destAddr := operands at: 1.
	"load the address into R3"
	loadSize := self loadAllButLSBWord: destAddr.
	machineCode 
		at: loadSize + 3 put: 16rE5; "STR srcReg, [R3, +LSB(addr)]"
		at: loadSize + 2 put: 16r83;
		at: loadSize + 1 put: (srcReg << 4);
		at: loadSize put: (destAddr bitAnd: 16rFF).
	^machineCodeSize := loadSize + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destReg |
	srcReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: 16rE1A0F00F.
	machineCode
		at: 1 put: (16rF0 bitAnd: destReg << 4);
		at: 0 put: (16r0F bitAnd: srcReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeRetN [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset |
	offset := operands at: 0.
	offset = 0 ifTrue:
		[self machineCodeAt: 0 put: 16rE8BD8000. "pop	{pc}"
		^machineCodeSize := 4].
	self assert: offset < 32. "We have an 8 bit immediate. If needed, we could rotate it less than 30 bit."
	self machineCodeAt: 0 put: 16rE28DDFFF. "add sp, sp, #n, 14"
	machineCode
		at: 0 put: offset. "no bit-mask needed, because of the assert"
	self machineCodeAt: 4 put: 16rE8BD8000.  "pop	{pc}"
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogARMCompiler >> dispatchConcretize [
	"Attempt to generate concrete machine code for the instruction at address.
	 This is the inner dispatch of concretizeAt: actualAddress which exists only
	 to get around the branch size limits in the SqueakV3 (blue book derived)
	 bytecode set."

	opcode caseOf: {
		"Noops & Pseudo Ops"
		[Label]					-> [^self concretizeLabel].
		[AlignmentNops]		-> [^self concretizeAlignmentNops].
		[Fill16]					-> [^self concretizeFill16].
		[Fill32]					-> [^self concretizeFill32].
		[FillFromWord]			-> [^self concretizeFillFromWord].
		[Nop]					-> [^self concretizeNop].
		"Specific Control/Data Movement"
		"[LDM]					-> [^self concretizeLDM].
		[STM]					-> [^self concretizeSTM]."
		"Control"
		[Call]						-> [^self concretizeCall].
		[JumpR]						-> [^self concretizeJumpR].
		[JumpLong]					-> [^self concretizeJumpLong].
		"[JumpLongZero]			-> [^self concretizeConditionalJumpLong: 16r??].
		[JumpLongNonZero]		-> [^self concretizeConditionalJumpLong: 16r??]."
		[Jump]						-> [^self concretizeJump].
		"[JumpZero]				-> [^self concretizeConditionalJump: 16r??].
		[JumpNonZero]				-> [^self concretizeConditionalJump: 16r??].
		[JumpNegative]				-> [^self concretizeConditionalJump: 16r??].
		[JumpNonNegative]			-> [^self concretizeConditionalJump: 16r??].
		[JumpOverflow]				-> [^self concretizeConditionalJump: 16r??].
		[JumpNoOverflow]			-> [^self concretizeConditionalJump: 16r??].
		[JumpCarry]				-> [^self concretizeConditionalJump: 16r??].
		[JumpNoCarry]				-> [^self concretizeConditionalJump: 16r??].
		[JumpLess]					-> [^self concretizeConditionalJump: 16r??].
		[JumpGreaterOrEqual]		-> [^self concretizeConditionalJump: 16r??].
		[JumpGreater]				-> [^self concretizeConditionalJump: 16r??].
		[JumpLessOrEqual]			-> [^self concretizeConditionalJump: 16r??].
		[JumpBelow]				-> [^self concretizeConditionalJump: 16r??].
		[JumpAboveOrEqual]		-> [^self concretizeConditionalJump: 16r??].
		[JumpAbove]				-> [^self concretizeConditionalJump: 16r??].
		[JumpBelowOrEqual]		-> [^self concretizeConditionalJump: 16r??].
		[JumpFPEqual]				-> [^self concretizeConditionalJump: 16r??].
		[JumpFPNotEqual]			-> [^self concretizeConditionalJump: 16r??].
		[JumpFPLess]				-> [^self concretizeConditionalJump: 16r??].
		[JumpFPGreaterOrEqual]	-> [^self concretizeConditionalJump: 16r??].
		[JumpFPGreater]			-> [^self concretizeConditionalJump: 16r??].
		[JumpFPLessOrEqual]		-> [^self concretizeConditionalJump: 16r??].
		[JumpFPOrdered]			-> [^self concretizeConditionalJump: 16r??].
		[JumpFPUnordered]			-> [^self concretizeConditionalJump: 16r??]."
		[RetN]						-> [^self concretizeRetN].
		"Arithmetic"
		[AddCqR]					-> [^self concretizeAddCqR].
		[AddCwR]					-> [^self concretizeAddCwR].
		[AddRR]						-> [^self concretizeAddRR].
		"[AddRdRd]					-> [^self concretizeSEE2OpRdRd: 16r58]."
		[AndCqR]					-> [^self concretizeAndCqR].
		[AndCwR]					-> [^self concretizeAndCwR].
		[AndRR]						-> [^self concretizeAndRR].
		[CmpCqR]					-> [^self concretizeCmpCqR].
		[CmpCwR]					-> [^self concretizeCmpCwR].
		[CmpRR]					-> [^self concretizeCmpRR].
		[CmpRdRd]					-> [^self concretizeCmpRdRd].
		"[DivRdRd]					-> [^self concretizeSEE2OpRdRd: 16r5E].
		[MulRdRd]					-> [^self concretizeSEE2OpRdRd: 16r59]."
		[OrCqR]						-> [^self concretizeOrCqR].
		[OrCwR]					-> [^self concretizeOrCwR].
		[OrRR]						-> [^self concretizeOrRR].
		[SubCqR]					-> [^self concretizeSubCqR].
		[SubCwR]					-> [^self concretizeSubCwR].
		[SubRR]						-> [^self concretizeSubRR].
		"[SubRdRd]					-> [^self concretizeSEE2OpRdRd: 16r5C]."
		[SqrtRd]						-> [^self concretizeSqrtRd].
		[XorCwR]						-> [^self concretizeXorCwR].
		[XorRR]							-> [^self concretizeXorRR].
		[NegateR]						-> [^self concretizeNegateR].
		[LoadEffectiveAddressMwrR]	-> [^self concretizeLoadEffectiveAddressMwrR].
		[ArithmeticShiftRightCqR]		-> [^self concretizeArithmeticShiftRightCqR].
		[LogicalShiftRightCqR]			-> [^self concretizeLogicalShiftRightCqR].
		[LogicalShiftLeftCqR]			-> [^self concretizeLogicalShiftLeftCqR].
		[ArithmeticShiftRightRR]			-> [^self concretizeArithmeticShiftRightRR].
		[LogicalShiftLeftRR]				-> [^self concretizeLogicalShiftLeftRR].
		"Data Movement"
		[MoveCqR]			-> [^self concretizeMoveCqR].
		[MoveCwR]			-> [^self concretizeMoveCwR].
		[MoveRR]			-> [^self concretizeMoveRR].
		[MoveAwR]			-> [^self concretizeMoveAwR].
		[MoveRAw]			-> [^self concretizeMoveRAw].
		[MoveMbrR]			-> [^self concretizeMoveMbrR].
		[MoveRMbr]			-> [^self concretizeMoveRMbr].
		[MoveM16rR]		-> [^self concretizeMoveM16rR].
		[MoveM64rRd]		-> [^self concretizeMoveM64rRd].
		[MoveMwrR]		-> [^self concretizeMoveMwrR].
		[MoveXbrRR]		-> [^self concretizeMoveXbrRR].
		[MoveXwrRR]		-> [^self concretizeMoveXwrRR].
		[MoveRXwrR]		-> [^self concretizeMoveRXwrR].
		[MoveRMwr]		-> [^self concretizeMoveRMwr].
		[MoveRdM64r]		-> [^self concretizeMoveRdM64r].
		[PopR]				-> [^self concretizePopR].
		[PushR]				-> [^self concretizePushR].
		[PushCw]			-> [^self concretizePushCw].
		[PrefetchAw]		-> [^self concretizePrefetchAw].
		"Conversion"
		[ConvertRRd]		-> [^self concretizeConvertRRd] }
]

{ #category : #assertions }
CogARMCompiler >> genGetLeafCallStackPointerFunction [
	cogit MoveR: SP R: R0.
	cogit RetN: 0
]

{ #category : #abi }
CogARMCompiler >> genSaveRegisters [
	"Save the general purpose registers for a trampoline call."
	"eliot => lars, this should probably save r0 through r12, since SP, LR and PC
	have specific purposes and don't need to be saved.  Save r0 through r11 if r12
	is being used as a frame pointer.  This can use the store multiple instruction STM,
	for which you'll need to add a class var to CogARMCompiler, because it is specific
	to ARM. HTH"
	self shouldBeImplemented
]

{ #category : #testing }
CogARMCompiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction."
	^self isJump or: [opcode = AlignmentNops]
]

{ #category : #abi }
CogARMCompiler >> leafCallStackPointerDelta [
	"Answer the delta from the stack pointer after a call to the stack pointer
	 immediately prior to the call.  This is used to compute the stack pointer
	 immediately prior to  call from within a leaf routine, which in turn is used
	 to capture the c stack pointer to use in trampolines back into the C run-time."
	"This might actually be false, since directly after a call, lr, fp and variable registers need be pushed onto the stack. It depends on the implementation of call."
	^0
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> loadAllButLSBWord: aWord [
	"This loads aWord into the inter-opcode temporary register. Because most ARM instruction enable using a (8-12bit) offset relative to a register, the LS Byte can be included in that instruction, saving one instruction."
	"The temporary register within abstract opcodes is R3"
	self 
		machineCodeAt: 0   put: 16rE3A03C00; "mov R3, #<second lowest byte>, 12"
		machineCodeAt: 4   put: 16rE3833800; "orr R3, R3, #<third lowest byte>, 8"
		machineCodeAt: 8   put: 16rE3833400. "orr R3, R3, #<most significant byte>, 4"
	"fill in the bytes"
	machineCode 
		at: 0 put: (aWord >> 8   bitAnd: 16rFF);
		at: 4 put: (aWord >> 12 bitAnd: 16rFF);
		at: 8 put: (aWord >> 24 bitAnd: 16rFF).
	^12
]

{ #category : #accessing }
CogARMCompiler >> machineCodeAt: anOffset put: aWord [
	"add aWord to machineCode, with little endian"
	machineCode
		at: anOffset + 3 put: (16rFF bitAnd: aWord >> 24);
		at: anOffset + 2 put: (16rFF bitAnd: aWord >> 16);
		at: anOffset + 1 put: (16rFF bitAnd: aWord >> 8);
		at: anOffset"+ 0"put: (16rFF bitAnd: aWord">> 0")
]

{ #category : #'generate machine code' }
CogARMCompiler >> machineCodeBytes [
	"Answer the maximum number of bytes of machine code generated for any abstract instruction.
	 e.g. MoveRAw =>
			mov R3, #<addressByte1>, 12
			orr R3, R3, #<addressByte2>, 8
			orr R3, R3, #<addressByte3>, 4
			STR srcReg, [R3, + addressByte0]"
	^16
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> nopsFrom: startAddr to: endAddr [
	self assert: endAddr - startAddr + 1 \\ 4 = 0.
	startAddr to: endAddr by: 4 do:
		[:p| objectMemory 
			byteAt: p put: 16r01;
			byteAt: p+1 put: 16r10;
			byteAt: p+2 put: 16rA0;
			byteAt: p+3 put: 16rE1]
]

{ #category : #abi }
CogARMCompiler >> numberOfSaveableRegisters [
	"Answer the number of registers to be saved in a trampoline call that saves registers.
	 R0 through R12, See genSaveRegisters."
	<cmacro: '() 13'>
	^13
]

{ #category : #accessing }
CogARMCompiler >> stackPageInterruptHeadroomBytes [
	"Return a minimum amount of headroom for each stack page (in bytes).  In a
	 JIT the stack has to have room for interrupt handlers which will run on the stack.
	According to ARM architecture v5 reference manual chapter A2.6, the basic interrupt procedure does not push anything onto the stack. It uses SPSR_err and R14_err to preserve state. Afterwards, it calls an interrupt procedure. So leave some room."
	^128 "32 words"
]
