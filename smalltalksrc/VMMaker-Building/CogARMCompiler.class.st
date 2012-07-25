Class {
	#name : #CogARMCompiler,
	#superclass : #CogAbstractInstruction,
	#classVars : [
		'AL',
		'CC',
		'CS',
		'EQ',
		'GE',
		'GT',
		'HI',
		'LDMFD',
		'LE',
		'LR',
		'LS',
		'LT',
		'MI',
		'NE',
		'PC',
		'PL',
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
		'RISCTempReg',
		'SP',
		'STMFD',
		'VC',
		'VS'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'class initialization' }
CogARMCompiler class >> initialize [
	
	"Initialize various ARM instruction-related constants."
	"CogARMCompiler initialize"
	
	| specificOpcodes refs conditionCodes |
	super initialize.
	self ~~ CogARMCompiler ifTrue: [^self].
	
	R0 := 0. R1 := 1.
	R2 := 2. R3 := 3.
	R4 := 4. R5 := 5.
	R6 := 6. R7 := 7.
	R8 := 8. R9 := 9.
	R10 := 10. R11 := 11.
	R12 := 12.
	SP := 13.
	LR := 14.
	PC := 15.
	
	RISCTempReg := R3.
	
	"Condition Codes"
	conditionCodes := #(EQ NE CS CC MI PL VS VC HI LS GE LT GT LE AL).
	conditionCodes withIndexDo: [ :classVarName :value | 
		self classPool
			declare: classVarName from: Undeclared;
			at: classVarName put: value - 1].
	
	"Specific instructions"
	LastRTLCode isNil ifTrue:
		[CogRTLOpcodes initialize].
	specificOpcodes := #(LDMFD STMFD).
	refs := (thisContext method literals select: [:l| l isVariableBinding and: [classPool includesKey: l key]]) collect:
				[:ea| ea key].
	(classPool keys reject: [:k| (specificOpcodes includes: k) or: [refs includes: k] or: [conditionCodes includes: k]]) do:
		[:k|
		Undeclared declare: k from: classPool].
	specificOpcodes withIndexDo:
		[:classVarName :value|
		self classPool
			declare: classVarName from: Undeclared;
			at: classVarName put: value + LastRTLCode - 1]
]

{ #category : #encoding }
CogARMCompiler >> c: c t: t o: o s: s [
	"c : 4 bit, t: 3 bit, o: 4 bit, s: 1bit"
	"the leftmost 12bit of (most) ARM instruction"
	<inline: true>
	^ c << 28 bitOr: ((t << 25) bitOr: ((o << 21) bitOr: (s << 20)))
]

{ #category : #'generate machine code' }
CogARMCompiler >> computeMaximumSize [
	"Because we don't use Thumb, each instruction has a multiple of 4 bytes. Most have exactly 4, but some abstract opcodes need more than one instruction."
	opcode 
		caseOf: {
			[Label]				-> [^maxSize := 0].
			[AlignmentNops]	-> [^maxSize := (operands at: 0) - 1].
			[CmpCqR]			-> [^self rotateable8bitImmediate: (operands at: 0)
										ifTrue: [:r :i| maxSize := 4]
										ifFalse: [maxSize := 20]].
			[CmpCwR]			-> [^maxSize := 20].
			[MoveAwR]			-> [^maxSize := 16 "3 for loadAllButLSB"].
			[MoveCqR]			-> [^self rotateable8bitImmediate: (operands at: 0)
										ifTrue: [:r :i| maxSize := 4]
										ifFalse: [maxSize := 16]].
			[MoveCwR]			-> [^maxSize := 16].
			[MoveRAw]			-> [^maxSize := 16 "3 for loadAllButLSB"].
			[RetN]				-> [^(operands at: 0) = 0 
										ifTrue: [maxSize := 4]
										ifFalse: [maxSize := 8]].
			[JumpFPEqual]				-> [^maxSize := 8].
			[JumpFPNotEqual]			-> [^maxSize := 8].
			[JumpFPLess]				-> [^maxSize := 8].
			[JumpFPGreaterOrEqual]	-> [^maxSize := 8].
			[JumpFPGreater]			-> [^maxSize := 8].
			[JumpFPLessOrEqual]		-> [^maxSize := 8].
			[JumpFPOrdered]			-> [^maxSize := 8].
			[JumpFPUnordered]			-> [^maxSize := 8].}
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

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeAlignmentNops [
	<inline: true>
	self assert: machineCodeSize \\ 4 = 0.
	0 to: machineCodeSize - 1 by: 4 do:
		[:p| objectMemory 
			byteAt: p put: 16r01;
			byteAt: p+1 put: 16r10;
			byteAt: p+2 put: 16rA0;
			byteAt: p+3 put: 16rE1]
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
CogARMCompiler >> concretizeCall [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset |
	self assert: (operands at: 0) ~= 0.
	offset := ((operands at: 0) - (address + 8)) signedIntFromLong "signed-conversion for range assertion".
	(self isQuick: offset)
		ifTrue: [
			self machineCodeAt: 0 put: (self t: 5 o: 8) + (offset >> 2 bitAnd: 16r00FFFFFF). "BL offset"
			^machineCodeSize := 4]
		ifFalse: [
			self halt]
	"We should push at least lr. The problem is, that any push added here is only executed after return, and therefore useless."
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeCmpCqR [
	"Will get inlined into concretizeAt: switch."
	"For 0, we can mov reg, #0"
	<inline: true>
	self 
		rotateable8bitImmediate: (operands at: 0) 
		ifTrue: [:rot :immediate | | reg |
			reg := self concreteRegister: (operands at: 1).
			self machineCodeAt: 0 put: ((self t: 1 o: 16rA s: 1) + reg << 12).
			machineCode at: 0 put: immediate.
			machineCode at: 1 put: rot.
			^machineCodeSize := 4]
		ifFalse: [^self concretizeCmpCwR].
	
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeCmpCwR [
	"Will get inlined into concretizeAt: switch."
	"Load the word into the RISCTempReg, then cmp R, RISCTempReg"
	<inline: true>
	| constant cmpReg doubleTempReg |
	constant := operands at: 0.
	cmpReg := (self concreteRegister: (operands at: 1)).
	doubleTempReg := (RISCTempReg << 4 bitOr: RISCTempReg) << 12.
	"load the instructions into machineCode"
	self 
		machineCodeAt: 0   put: (16rE3A00C00 bitOr: RISCTempReg << 12); "MOV dest, #<byte3>, 12"
		machineCodeAt: 4   put: (16rE3800800 bitOr: doubleTempReg); "ORR dest, dest, #<byte2>, 8"
		machineCodeAt: 8   put: (16rE3800400 bitOr: doubleTempReg); "ORR dest, dest, #<byte1>, 4"
		machineCodeAt: 12 put: (16rE3800000 bitOr: doubleTempReg). "ORR dest, dest, #<byte4>, 0"
	"fill in the according bytes"
	machineCode
		at: 0 put: (constant >> 8   bitAnd: 16rFF);
		at: 4 put: (constant >> 12 bitAnd: 16rFF);
		at: 8 put: (constant >> 24 bitAnd: 16rFF);
		at: 12 put: (constant bitAnd: 16rFF).
	self machineCodeAt: 16 
		put: ((self t: 0 o: 16rA s: 1) bitOr: (cmpReg << 16 bitOr: RISCTempReg)).
	^machineCodeSize := 20.
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeConditionalJump: conditionCode [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset |
	self assert: (operands at: 0) ~= 0.
	offset := ((operands at: 0) - (address + 8)) signedIntFromLong "signed-conversion for range assertion".
	self assert: offset <= 33554428 & (offset >= -33554432).
	self machineCodeAt: 0 put: (self c: conditionCode t: 5 o: 0 s: 0) + (offset >> 2 bitAnd: 16r00FFFFFF). "B offset"
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeFPConditionalJump: conditionCode [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset |
	self assert: (operands at: 0) ~= 0.
	offset := ((operands at: 0) - (address + 8)) signedIntFromLong "signed-conversion for range assertion".
	self assert: offset <= 33554428 & (offset >= -33554432).
	self machineCodeAt: 0 put: 16rEF1FA10. "FMSTAT: copy the FPSCR to CPSR"
	self machineCodeAt: 4 put: (self c: conditionCode t: 5 o: 0 s: 0) + (offset >> 2 bitAnd: 16r00FFFFFF). "B offset"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveAwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcAddr destReg loadSize |
	srcAddr := operands at: 0.
	destReg := self concreteRegister: (operands at: 1).
	"load the address into R3"
	loadSize := self loadAllButLSBWord: srcAddr.
	machineCode 
		at: loadSize + 3 put: 16rE5; "LDR srcReg, [R3, +LSB(addr)]"
		at: loadSize + 2 put: (16r90 bitOr: RISCTempReg);
		at: loadSize + 1 put: (destReg << 4);
		at: loadSize put: (srcAddr bitAnd: 16rFF).
	^machineCodeSize := loadSize + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveCqR [
	"Will get inlined into concretizeAt: switch."
	"For 0, we can mov reg, #0"
	<inline: true>
	self 
		rotateable8bitImmediate: (operands at: 0) 
		ifTrue: [:rot :immediate | | reg |
			reg := self concreteRegister: (operands at: 1).
			self machineCodeAt: 0 put: ((self t: 1 o: 16rD s: 0) + reg << 12).
			machineCode at: 0 put: immediate.
			machineCode at: 1 put: rot.
			^machineCodeSize := 4]
		ifFalse: [^self concretizeMoveCwR].
	
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveCwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| constant destReg |
	constant := operands at: 0.
	destReg := (self concreteRegister: (operands at: 1)) << 12.
	"load the instructions into machineCode"
	self 
		machineCodeAt: 0   put: (16rE3A00C00 bitOr: destReg); "MOV dest, #<byte1>, 12"
		machineCodeAt: 4   put: (16rE3830800 bitOr: destReg); "ORR dest, dest, #<byte2>, 8"
		machineCodeAt: 8   put: (16rE3830400 bitOr: destReg); "ORR dest, dest, #<byte3>, 4"
		machineCodeAt: 12 put: (16rE3830000 bitOr: destReg). "ORR dest, dest, #<byte0>, 0"
	"fill in the according bytes"
	machineCode
		at: 0 put: (constant >> 8   bitAnd: 16rFF);
		at: 4 put: (constant >> 12 bitAnd: 16rFF);
		at: 8 put: (constant >> 24 bitAnd: 16rFF);
		at: 12 put: (constant bitAnd: 16rFF).
		
	^machineCodeSize := 16.
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
		at: loadSize + 2 put: (16r80 bitOr: RISCTempReg);
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
CogARMCompiler >> concretizePushR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg |
	srcReg := self concreteRegister: (operands at: 0).
	
	self machineCodeAt: 0 put: ((self t: 4 o: 9) + 16rD0000 bitOr: 1 << srcReg).
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
		"[JumpLongZero]			-> [^self concretizeConditionalJumpLong: EQ].
		[JumpLongNonZero]		-> [^self concretizeConditionalJumpLong: NE]."
		[Jump]						-> [^self concretizeConditionalJump: AL].
		[JumpZero]					-> [^self concretizeConditionalJump: EQ].
		[JumpNonZero]				-> [^self concretizeConditionalJump: NE].
		[JumpNegative]				-> [^self concretizeConditionalJump: MI].
		[JumpNonNegative]			-> [^self concretizeConditionalJump: PL].
		[JumpOverflow]				-> [^self concretizeConditionalJump: VS].
		[JumpNoOverflow]			-> [^self concretizeConditionalJump: VC].
		[JumpCarry]				-> [^self concretizeConditionalJump: CS].
		[JumpNoCarry]				-> [^self concretizeConditionalJump: CC].
		[JumpLess]					-> [^self concretizeConditionalJump: LT].
		[JumpGreaterOrEqual]		-> [^self concretizeConditionalJump: GE].
		[JumpGreater]				-> [^self concretizeConditionalJump: GT].
		[JumpLessOrEqual]			-> [^self concretizeConditionalJump: LE].
		[JumpBelow]				-> [^self concretizeConditionalJump: CS]. "according to http://courses.engr.illinois.edu/ece390/books/labmanual/assembly.html"
		[JumpAboveOrEqual]		-> [^self concretizeConditionalJump: CC]. " --""-- "
		[JumpAbove]				-> [^self concretizeConditionalJump: HI].
		[JumpBelowOrEqual]		-> [^self concretizeConditionalJump: LS].
		[JumpFPEqual]				-> [^self concretizeFPConditionalJump: EQ].
		[JumpFPNotEqual]			-> [^self concretizeFPConditionalJump: NE].
		"[JumpFPLess]				-> [^self concretizeFPConditionalJump: LT].
		[JumpFPGreaterOrEqual]	-> [^self concretizeFPConditionalJump: GE].
		[JumpFPGreater]			-> [^self concretizeFPConditionalJump: GT].
		[JumpFPLessOrEqual]		-> [^self concretizeFPConditionalJump: LE].
		[JumpFPOrdered]			-> [^self concretizeFPConditionalJump: VC].
		[JumpFPUnordered]			-> [^self concretizeFPConditionalJump: VS]."
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
CogARMCompiler >> genPassConst: constant asArgument: zeroRelativeArgIndex [
	cogit
		MoveCq: constant R: TempReg;
		PushR: TempReg.
	^0
]

{ #category : #abi }
CogARMCompiler >> genPassReg: abstractRegister asArgument: zeroRelativeArgIndex [
	cogit PushR: abstractRegister.
	^0
]

{ #category : #abi }
CogARMCompiler >> genSaveRegisters [
	"Save the general purpose registers for a trampoline call."
	"Save r0-r6, all of which are used for variables. Don't save sb(r9), sl(r10), fp(r11), sp or lr"
	cogit
		gen: STMFD operand: 16r7F
]

{ #category : #testing }
CogARMCompiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction."
	^self isJump or: [opcode = AlignmentNops] or: [opcode = Call]
]

{ #category : #testing }
CogARMCompiler >> isQuick: operand [
	<var: #operand type: #'unsigned long'>
	^operand signedIntFromLong between: -33554432 and: 33554428
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
	"The temporary register within abstract opcodes is RISCTempReg"
	self 
		machineCodeAt: 0   put: (16rE3A00C00 bitOr: RISCTempReg << 12); "MOV R3, #<byte1>, 12"
		machineCodeAt: 4   put: 16rE3800800 + (RISCTempReg << 12) + (RISCTempReg << 16); "ORR R3, R3, #<byte2>, 8"
		machineCodeAt: 8   put: 16rE3800800 + (RISCTempReg << 12) + (RISCTempReg << 16). "ORR R3, R3, #<byte3>, 4"
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
	<inline: true>
	machineCode
		at: anOffset + 3 put: (16rFF bitAnd: aWord >> 24);
		at: anOffset + 2 put: (16rFF bitAnd: aWord >> 16);
		at: anOffset + 1 put: (16rFF bitAnd: aWord >> 8);
		at: anOffset"+ 0"put: (16rFF bitAnd: aWord">> 0")
]

{ #category : #'generate machine code' }
CogARMCompiler >> machineCodeBytes [
	"Answer the maximum number of bytes of machine code generated for any abstract instruction.
	 e.g. CmpCwR =>
			mov R3, #<addressByte1>, 12
			orr R3, R3, #<addressByte2>, 8
			orr R3, R3, #<addressByte3>, 4
			orr R3, R3, #<addressByte4>, 0
			cmp R?, R3"
	^20
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

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> rotateable8bitImmediate: constant ifTrue: trueAlternativeBlock ifFalse: falseAlternativeBlock [
	"For data processing operands, there is the immediate shifter_operand variant, 
	where an 8 bit value is ring shifted _right_ by 2*i.
	This is only suitable for quick constant(Cq), which don't change."
	
	(constant bitAnd: 16rFF) = constant ifTrue: [ ^trueAlternativeBlock value: 0 value: constant].
	1 to: 15 do: [:i |
		(constant bitAnd: 16rFF << (i<<1)) = constant 
			ifTrue: [ ^trueAlternativeBlock value: 16 - i value: constant >> (i << 1)]].
	^falseAlternativeBlock value
]

{ #category : #'generate machine code' }
CogARMCompiler >> sizePCDependentInstructionAt: eventualAbsoluteAddress [
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceeding instruction or to an absolute address is
	 between that instruction's address (which by now is its eventual absolute
	 address) or absolute address and eventualAbsoluteAddress."

	| target maximumSpan |
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	opcode = AlignmentNops ifTrue:
		[| alignment |
		 address := eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: (self isJump or: [opcode = Call]).
	target := operands at: 0.
	"maximumSpan calculation copied from CogIA32Compiler TODO: extract method?"
	(self isAnInstruction: (cogit cCoerceSimple: target to: #'void *'))
		ifTrue:
			[| abstractInstruction |
			abstractInstruction := cogit cCoerceSimple: target to: #'AbstractInstruction *'.
			maximumSpan := abstractInstruction address
							- (((cogit abstractInstruction: self follows: abstractInstruction)
								ifTrue: [eventualAbsoluteAddress]
								ifFalse: [address]) + 2)]
		ifFalse:
			[maximumSpan := target - (eventualAbsoluteAddress + 2)].
	address := eventualAbsoluteAddress.
	^machineCodeSize := (self isQuick: maximumSpan)
									ifTrue: [4] "branch"
									ifFalse: [20] "load address to register, mov"
]

{ #category : #accessing }
CogARMCompiler >> stackPageInterruptHeadroomBytes [
	"Return a minimum amount of headroom for each stack page (in bytes).  In a
	 JIT the stack has to have room for interrupt handlers which will run on the stack.
	According to ARM architecture v5 reference manual chapter A2.6, the basic interrupt procedure does not push anything onto the stack. It uses SPSR_err and R14_err to preserve state. Afterwards, it calls an interrupt procedure. So leave some room."
	^128 "32 words"
]

{ #category : #encoding }
CogARMCompiler >> t: type o: flagsOrOpcode [
	<inline: true>
	^self c: AL t: type o: flagsOrOpcode s: 0
]

{ #category : #encoding }
CogARMCompiler >> t: type o: flagsOrOpcode s: doUpdateStatusRegister [
	<inline: true>
	^self c: AL t: type o: flagsOrOpcode s: doUpdateStatusRegister
]

{ #category : #encoding }
CogARMCompiler >> t: type o: flagsOrOpcode s: doUpdateStatusRegister rn:  sourceRegister rd: targetRegister [
	<inline: true>
	^(self c: AL t: type o: flagsOrOpcode s: doUpdateStatusRegister) 
		bitOr: (sourceRegister << 16 bitOr: targetRegister << 12)
]
