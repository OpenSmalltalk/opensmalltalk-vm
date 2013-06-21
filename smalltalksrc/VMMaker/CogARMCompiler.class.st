"
I generate ARM instructions from CogAbstractInstructions.  For reference see
http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.set.architecture/index.html

The Architecture Reference Manual used is that of version 5, which includes some version 6 instructions. Of those, only pld is used(for PrefetchAw).

This class does not take any special action to flush the instruction cache on instruction-modification.
"
Class {
	#name : #CogARMCompiler,
	#superclass : #CogAbstractInstruction,
	#classVars : [
		'AL',
		'CArg0Reg',
		'CArg1Reg',
		'CArg2Reg',
		'CArg3Reg',
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
	
	CArg0Reg := 0. CArg1Reg := 1. CArg2Reg := 2. CArg3Reg := 3.
	
	RISCTempReg := R10.
	
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

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> at: offset moveCw: constant intoR: destReg [
	"This loads aWord into the inter-opcode temporary register. Because most ARM instruction enable using a (8-12bit) offset relative to a register, the LS Byte can be included in that instruction, saving one instruction. This is done in a decorator, e.g. CmpCqR"
	"Generates:along the lines of
	MOV destReg, #<constantByte3>, 12
	ORR destReg, destReg, #<constantByte2>, 8
	ORR destReg, destReg, #<constantByte1>, 4
	ORR destReg, destReg, #<constantByte0>, 0
	with minimal choice of the rotation (last digit)"
	"The same area can be modified multiple times, because the opperation is (inclusive) or."
	<inline: true>
	0 to: 12 by: 4 do: [ :i | | rightRingRotation |
		rightRingRotation := self minimalRightRingRotationFor: constant initialRotation: 12 - i.
		machineCode
			at: offset + i + 3 put: 16rE3;
			at: offset + i + 2 put: (16r80 bitOr: destReg);
			at: offset + i + 1 put: ((rightRingRotation at: 1) bitOr: destReg << 4);
			at: offset + i"+0"put: (rightRingRotation at: 2).
		].
	machineCode at: offset + 2 put: 16rA0. "only the first operation need be MOV"
	^16
]

{ #category : #encoding }
CogARMCompiler >> c: c t: t o: o s: s [
	"c : 4 bit, t: 3 bit, o: 4 bit, s: 1bit"
	"the leftmost 12bit of (most) ARM instruction"
	<inline: true>
	^ c << 28 bitOr: ((t << 25) bitOr: ((o << 21) bitOr: (s << 20)))
]

{ #category : #encoding }
CogARMCompiler >> c: conditionCode t: type o: flagsOrOpcode s: doUpdateStatusRegister rn:  sourceRegister rd: targetRegister [
	<inline: true>
	^(self c: conditionCode t: type o: flagsOrOpcode s: doUpdateStatusRegister) 
		bitOr: (sourceRegister << 16 bitOr: targetRegister << 12)
]

{ #category : #encoding }
CogARMCompiler >> c: conditionCode t: type o: flagsOrOpcode s: doUpdateStatusRegister rn:  sourceRegister rd: targetRegister shifterOperand: so [
	<inline: true>
	^(self c: conditionCode t: type o: flagsOrOpcode s: doUpdateStatusRegister rn: sourceRegister rd: targetRegister) bitOr: so
]

{ #category : #abi }
CogARMCompiler >> cResultRegister [
	"Answer the abstract register for the C result register.
	 Only partially implemented.  Works on x86 since TempReg = EAX = C result reg."
	^R0
]

{ #category : #'inline cacheing' }
CogARMCompiler >> callTargetFromReturnAddress: callSiteReturnAddress [
	"Answer the address the call immediately preceeding callSiteReturnAddress will jump to."
	| callDistance call |
	call := self instructionBeforeAddress: callSiteReturnAddress.
	self assert: call ~= 0. "andeq r0, r0 will not be generated, not even as nops"
	(self isBranch: call)
		ifTrue: [ callDistance := (call bitAnd: 16r00FFFFFF) << 2.
			"The distance is a signed 24bit number. Therefore, the highest (26th) bit has to be expanded"
			(callDistance bitAnd: 16r02000000) ~= 0 
				ifTrue: [callDistance := callDistance bitOr: 16rFC000000]]
		ifFalse: [ "A Long Jump. Extract the value saved to RISCTempReg from all the instructions before."
			self notYetImplemented ].
	^callSiteReturnAddress + 4 + callDistance signedIntFromLong
]

{ #category : #accessing }
CogARMCompiler >> callerSavedRegisterMask [
	"registers r0-r3, the lowest four, +lr"
		^16r40F
]

{ #category : #testing }
CogARMCompiler >> callsAreRelative [
	^true
]

{ #category : #testing }
CogARMCompiler >> canDivQuoRem [
	^false
]

{ #category : #testing }
CogARMCompiler >> canMulRR [
	^true
]

{ #category : #'generate machine code' }
CogARMCompiler >> computeMaximumSize [
	"Because we don't use Thumb, each ARM instruction has 4 bytes. Some abstract opcodes need more than one instruction."
	
	| rotateableAt0then4or20Block |
	rotateableAt0then4or20Block := [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 4]
											ifFalse: [maxSize := 20]].
	
	
	(opcode between: FirstShortJump and: LastJump) ifTrue: [^maxSize := 16].
	
	opcode
		caseOf: {
			[Label]					-> [^maxSize := 0].
			[AlignmentNops]		-> [^maxSize := (operands at: 0) - 1].
			[MoveAwR]				-> [^maxSize := 16].
			[MoveCqR]				-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 4]
											ifFalse: [maxSize := 16]].
			[MoveCwR]				-> [^maxSize := 16].
			[MoveRAw]				-> [^maxSize := 16].
			[MoveRMwr]			-> [self is12BitValue: (operands at: 1)
											ifTrue: [ :u :i | ^maxSize := 4]
											ifFalse: [ ^maxSize := 20 ]].
			[MoveRMbr]				-> [self is12BitValue: (operands at: 1)
											ifTrue: [ :u :i | ^maxSize := 4]
											ifFalse: [ ^maxSize := 20 ]].
			[MoveMwrR]			-> [self is12BitValue: (operands at: 0)
											ifTrue: [ :u :i | ^maxSize := 4]
											ifFalse: [ ^maxSize := 20 ]].
			[MoveMbrR]				-> [self is12BitValue: (operands at: 0)
											ifTrue: [ :u :i | ^maxSize := 4]
											ifFalse: [ ^maxSize := 20 ]].
			[PrefetchAw] 			-> [^maxSize := 16].
			[Call]					-> [^maxSize := 20 "recomputed in #sizePCDependentInstruction."].
			[RetN]					-> [^(operands at: 0) = 0 
											ifTrue: [maxSize := 4]
											ifFalse: [maxSize := 8]].
			[CmpCqR]				-> [rotateableAt0then4or20Block value].
			[AddCqR]				-> [rotateableAt0then4or20Block value].
			[SubCqR]				-> [rotateableAt0then4or20Block value].
			[AndCqR]				-> [rotateableAt0then4or20Block value].
			[OrCqR]					-> [rotateableAt0then4or20Block value].
			[XorCqR]				-> [rotateableAt0then4or20Block value].
			[CmpCwR]				-> [^maxSize := 20].
			[AddCwR]				-> [^maxSize := 20].
			[SubCwR]				-> [^maxSize := 20].
			[AndCwR]				-> [^maxSize := 20].
			[OrCwR]				-> [^maxSize := 20].
			[XorCwR]				-> [^maxSize := 20].
			[JumpR]					-> [^maxSize := 4].
			[JumpFPEqual]			-> [^maxSize := 8].
			[JumpFPNotEqual]		-> [^maxSize := 8].
			[JumpFPLess]			-> [^maxSize := 8].
			[JumpFPGreaterOrEqual]-> [^maxSize := 8].
			[JumpFPGreater]		-> [^maxSize := 8].
			[JumpFPLessOrEqual]	-> [^maxSize := 8].
			[JumpFPOrdered]		-> [^maxSize := 8].
			[JumpFPUnordered]		-> [^maxSize := 8].
			[JumpLong]				-> [^maxSize := 16].
			[JumpLongZero]		-> [^maxSize := 16].
			[JumpLongNonZero]	-> [^maxSize := 16].
			[LoadEffectiveAddressMwrR] -> [rotateableAt0then4or20Block value].
			[PushCw]				-> [^maxSize := 20].
		}
		otherwise: [^maxSize := 4].
	^4 "to keep C compiler quiet"

]

{ #category : #encoding }
CogARMCompiler >> concreteRegister: registerIndex [
	 "Map a possibly abstract register into a concrete one.  Abstract registers
	  (defined in CogAbstractOpcodes) are all negative.  If registerIndex is
	 negative assume it is an abstract register."
	
	"N.B. According to BSABI, R0-R3 are caller-save, R4-R12 are callee save.
	Note that R9 might be a special register for the implementation. In some slides it is refered to as sb. R10 can contain the stack limit (sl), R11 the fp. R12 is an intra-procedure scratch instruction pointer for link purposes. It can also be used.
	R10 is used as temporary inside a single abstract opcode implementation"
	"R0-R3 are used when calling back to the interpreter. Using them would require saving and restoring their values, so they are omitted so far. R12 is the only unused register at the moment.."
	^registerIndex
		caseOf: {
			[TempReg]				-> [R7].
			[ClassReg]				-> [R8].
			[ReceiverResultReg]	-> [R9].
			[SendNumArgsReg]		-> [R6].
			[SPReg]					-> [SP].
			[FPReg]					-> [R11].
			[Arg0Reg]				-> [R4].
			[Arg1Reg]				-> [R5].
			[LinkReg]				-> [LR]. }
		otherwise:
			[self assert: (registerIndex between: R0 and: PC).
			 registerIndex]
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeAddCqR [
	"Will get inlined into concretizeAt: switch."
	"Try whether the quick constant is a small negative number. If it is, optimize."
	<inline: true>
	self rotateable8bitImmediate: (operands at: 0)
		ifTrue: [ :rot :immediate | | reg |
			reg := self concreteRegister: (operands at: 1).
			self machineCodeAt: 0 put: ((self t: 1 o: 4 s: 1) bitOr: reg << 16).
			machineCode at: 0 put: immediate.
			machineCode at: 1 put: (reg << 4 bitOr: rot).
			^machineCodeSize := 4]
		ifFalse: [
			self rotateable8bitImmediate: (operands at: 0) negated
				ifTrue: [ :r :i | 
						opcode := SubCqR.
						operands at: 0 put: (operands at: 0) negated.
						^self concretizeDataOperationCqR: 2]
				ifFalse: [^self concretizeDataOperationCwR: 4]]
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

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeArithmeticShiftRightCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := self concreteRegister: (operands at: 1).
	"cond 000 1101 0 0000 dest dist -100 srcR"
	self machineCodeAt: 0 put: (self t: 0 o: 16rD s: 0 rn: 0 rd: reg 
									shifterOperand: (distance << 7 bitOr: (64 bitOr: reg))).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeArithmeticShiftRightRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| destReg distReg |
	distReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
	"cond 000 1101 0 0000 dest dist 0101 srcR"
	self machineCodeAt: 0 put: (self t: 0 o: 16rD s: 0 rn: 0 rd: destReg 
									shifterOperand: (distReg << 8 bitOr: (80 bitOr: destReg))).
	^machineCodeSize := 4
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
	self assert: (operands at: 0) \\ 4 = 0.
	offset := (operands at: 0) signedIntFromLong - (address + 8 "normal pc offset") signedIntFromLong.
	(self isQuick: offset)
		ifTrue: [
			self machineCodeAt: 0 put: (self t: 5 o: 8) + (offset >> 2 bitAnd: 16r00FFFFFF). "BL offset"
			^machineCodeSize := 4]
		ifFalse: [
			self error: 'While we know how to generate a long distance call, we can''t update such a send site yet. Please restart with smaller cache size'.
			self concretizeConditionalJumpLong: AL.
			"move the actual jump two instructions further, inserting the pc back-up to lr and the pc push."
			self machineCodeAt: 16 put: (self machineCodeAt: 12).
		"Because the pc always points to the actual address + 8, the value at pc is the address of the instruction after the branch"
			"mov lr, pc"
			self machineCodeAt: 12 put: (self t: 0 o: 16rD s: 0 rn: 0 rd: LR shifterOperand: PC).
			^machineCodeSize := 20]
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeCmpCqR [
	"Will get inlined into concretizeAt: switch."
	"All other data operations write back their results. The write back register should be zero for CMP."
	<inline: true>
	| size |
	size := self concretizeDataOperationCqR: 16rA.
	machineCode at: size - 3 put: ((machineCode at: size -3) bitAnd: 16rFF).
	^size

]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeCmpCwR [
	"Will get inlined into concretizeAt: switch."
	"All other data operations write back their results. The write back register should be zero for CMP."
	<inline: true>
	| size |
	size := self concretizeDataOperationCwR: 16rA.
	machineCode at: size - 3 put: ((machineCode at: size -3) bitAnd: 16rFF).
	^size
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeCmpRR [
	"Will get inlined into concretizeAt: switch."
	"All other data operations write back their results. The write back register should be zero for CMP."
	<inline: true>
	| size |
	size := self concretizeDataOperationRR: 16rA.
	machineCode at: size - 3 put: ((machineCode at: size -3) bitAnd: 16rFF).
	^size
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeConditionalJump: conditionCode [
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| offset |
	offset := self computeJumpTargetOffsetPlus: 8.
 	(self isQuick: offset)
		ifTrue: [
			self machineCodeAt: 0 put: (self c: conditionCode t: 5 o: 0 s: 0) + (offset >> 2 bitAnd: 16r00FFFFFF). "B offset"
			^machineCodeSize := 4]
		ifFalse: [
			^self concretizeConditionalJumpLong: conditionCode]
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeConditionalJumpLong: conditionCode [
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| jumpTarget |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := self longJumpTargetAddress.
	self at: 0 moveCw: jumpTarget intoR: RISCTempReg.
	"add pc, r3, #<byte 0>"
	self machineCodeAt: 12 put: (self c: conditionCode t: 1 o: 4 s: 0 rn: RISCTempReg rd: PC shifterOperand: (jumpTarget bitAnd: 16rFF)).
	^machineCodeSize := 16
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeDataOperationCqR: opcode [
	"Will get inlined into concretizeAt: switch."
	"4 == Add, 2 == Sub, Xor == 1, And == 0, Or == 12"
	<inline: true>
	self 
		rotateable8bitImmediate: (operands at: 0) 
		ifTrue: [:rot :immediate | | reg |
			reg := self concreteRegister: (operands at: 1).
			self machineCodeAt: 0 put: ((self t: 1 o: opcode s: 1) bitOr: reg << 16).
			machineCode at: 0 put: immediate.
			machineCode at: 1 put: (reg << 4 bitOr: rot).
			^machineCodeSize := 4]
		ifFalse: [^self concretizeDataOperationCwR: opcode].
	
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeDataOperationCwR: opcode [
	"Will get inlined into concretizeAt: switch."
	"Load the word into the RISCTempReg, then cmp R, RISCTempReg"
	<inline: true>
	| constant srcDestReg |
	constant := operands at: 0.
	srcDestReg := (self concreteRegister: (operands at: 1)).
	self at: 0 moveCw: constant intoR: RISCTempReg.
	self machineCodeAt: 16 
		put: ((self t: 0 o: opcode s: 1) bitOr: ((srcDestReg << 16 bitOr: srcDestReg <<12) bitOr: RISCTempReg)).
	^machineCodeSize := 20.
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeDataOperationRR: opcode [
	"Will get inlined into concretizeAt: switch."
	"Load the word into the RISCTempReg, then cmp R, RISCTempReg"
	<inline: true>
	| destReg srcReg |
	srcReg := self concreteRegister: (operands at: 0).
	destReg := (self concreteRegister: (operands at: 1)).
	self machineCodeAt: 0 
		put: (self t: 0 o: opcode s: 1 rn: destReg rd: destReg shifterOperand: srcReg).
	^machineCodeSize := 4.
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
CogARMCompiler >> concretizeJumpR [
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| reg |
	reg := self concreteRegister: (operands at: 0).
	"mov pc, r?, #0"
	self machineCodeAt: 0 put: (self t: 0 o: 16rD s: 0 rn: 0 rd: PC shifterOperand: reg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeLoadEffectiveAddressMwrR [
	"Will get inlined into concretizeAt: switch."
	"destReg = destReg + offset"
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
	self rotateable8bitImmediate: offset
		ifTrue: [ :rot :immediate | 
			self machineCodeAt: 0 
				"add destReg, srcReg, #immediate"
				put: (self t: 1 o: 4 s: 0 rn: srcReg rd: destReg shifterOperand: (rot <<8 bitOr: immediate)).
			^machineCodeSize := 4]
		ifFalse: [ 
			self at: 0 moveCw: offset intoR: RISCTempReg.
			"add destReg, srcReg, RISCTempReg"
			self machineCodeAt: 16 put: (self t: 0 o: 4 s: 0 rn: srcReg rd: destReg shifterOperand: RISCTempReg).
			^machineCodeSize := 20 ]
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeLogicalShiftLeftCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := self concreteRegister: (operands at: 1).
	"cond 000 1101 0 0000 dest dista 000 srcR"
	self machineCodeAt: 0 put: (self t: 0 o: 16rD s: 0 rn: 0 rd: reg shifterOperand: (distance << 7 bitOr: reg)).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeLogicalShiftLeftRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| destReg distReg |
	distReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
	"cond 000 1101 0 0000 dest dist 0001 srcR"
	self machineCodeAt: 0 put: (self t: 0 o: 16rD s: 0 rn: 0 rd: destReg 
									shifterOperand: (distReg << 8 bitOr: (16 bitOr: destReg))).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeLogicalShiftRightCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := self concreteRegister: (operands at: 1).
	"cond 000 1101 0 0000 dest dist -010 srcR"
	self machineCodeAt: 0 put: (self t: 0 o: 16rD s: 0 rn: 0 rd: reg 
									shifterOperand: (distance << 7 bitOr: (32 bitOr: reg))).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeLogicalShiftRightRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| destReg distReg |
	distReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
	"cond 000 1101 0 0000 dest dist 0011 srcR"
	self machineCodeAt: 0 put: (self t: 0 o: 16rD s: 0 rn: 0 rd: destReg 
									shifterOperand: (distReg << 8 bitOr: (48 bitOr: destReg))).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveAwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcAddr destReg |
	srcAddr := operands at: 0.
	destReg := self concreteRegister: (operands at: 1).
	"load the address into RISCTempReg"
	self at: 0 moveCw: srcAddr intoR: RISCTempReg.
	"Moving allows building an 8bit offset, so the lowest byte can be used in this instruction and we save 4 byte."
	machineCode
		at: 15 put: 16rE5; "LDR srcReg, [R3, +LSB(addr)]"
		at: 14 put: (16r90 bitOr: RISCTempReg);
		at: 13 put: (destReg << 4).
	^machineCodeSize := 16
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveCqR [
	"Will get inlined into concretizeAt: switch."
	"If the quick constant is in fact a shiftable 8bit, generate the apropriate MOV, otherwise do what is necessary for a whole word."
	<inline: true>
	self 
		rotateable8bitImmediate: (operands at: 0) 
		ifTrue: [:rot :immediate | | reg |
			reg := self concreteRegister: (operands at: 1).
			self machineCodeAt: 0 put: (self t: 1 o: 16rD s: 0).
			machineCode at: 0 put: immediate.
			machineCode at: 1 put: (reg << 4 bitOr: rot).
			^machineCodeSize := 4]
		ifFalse: [^self concretizeMoveCwR].
	
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveCwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| constant destReg |
	constant := operands at: 0.
	destReg := self concreteRegister: (operands at: 1).
	self at: 0 moveCw: constant intoR: destReg.
	^machineCodeSize := 16.
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveMbrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
	self is12BitValue: offset
		ifTrue: [ :u :immediate | 
			self machineCodeAt: 0 
				"ldr destReg, [srcReg, #immediate]"
				put: (self t: 2 o: (16rA bitOr: u <<2) s: 1 rn: srcReg rd: destReg shifterOperand: immediate).
			^machineCodeSize := 4]
		ifFalse: [ 
			self at: 0 moveCw: offset intoR: RISCTempReg.
			"ldr destReg, [srcReg, RISCTempReg]"
			self machineCodeAt: 16 put: (self t: 3 o: 16rE s: 1 rn: srcReg rd: destReg shifterOperand: RISCTempReg).
			^machineCodeSize := 20 ]
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveMwrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
	self is12BitValue: offset
		ifTrue: [ :u :immediate | 
			self machineCodeAt: 0 
				"ldr destReg, [srcReg, #immediate]"
				put: (self t: 2 o: (8 bitOr: u <<2) s: 1 rn: srcReg rd: destReg shifterOperand: immediate).
			^machineCodeSize := 4]
		ifFalse: [ 
			self at: 0 moveCw: offset intoR: RISCTempReg.
			"ldr destReg, [srcReg, RISCTempReg]"
			self machineCodeAt: 16 put: (self t: 3 o: 16rC s: 1 rn: srcReg rd: destReg shifterOperand: RISCTempReg).
			^machineCodeSize := 20 ]
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRAw [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destAddr |
	srcReg := self concreteRegister: (operands at: 0).
	destAddr := operands at: 1.
	"load the address into R3"
	self at: 0 moveCw: destAddr intoR: RISCTempReg.
	machineCode 
		at: 15 put: 16rE5; "STR srcReg, [R3, +LSB(addr)]"
		at: 14 put: (16r80 bitOr: RISCTempReg);
		at: 13 put: (srcReg << 4).
	^machineCodeSize := 16
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRMbr [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := self concreteRegister: (operands at: 0).
	offset := operands at: 1.
	destReg := self concreteRegister: (operands at: 2).
	self is12BitValue: offset
		ifTrue: [ :u :immediate | 
			self machineCodeAt: 0 
			"strb 	destReg, [srcReg, #immediate]"
				put: (self t: 2 o: (16rA bitOr: u<<2) s: 0 rn: destReg rd: srcReg shifterOperand: immediate).
			^machineCodeSize := 4]
		ifFalse: [ 
			self at: 0 moveCw: offset intoR: RISCTempReg.
			"strb 	destReg, [srcReg, RISCTempReg]"
			self machineCodeAt: 16 put: (self t: 3 o: 16rE s: 0 rn: srcReg rd: destReg shifterOperand: RISCTempReg).
			^machineCodeSize := 20 ]
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRMwr [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := self concreteRegister: (operands at: 0).
	offset := operands at: 1.
	destReg := self concreteRegister: (operands at: 2).
	self is12BitValue: offset
		ifTrue: [ :u :immediate | 
			self machineCodeAt: 0 
			"strb 	destReg, [srcReg, #immediate]"
				put: (self t: 2 o: (8 bitOr: u<<2) s: 0 rn: destReg rd: srcReg shifterOperand: immediate).
			^machineCodeSize := 4]
		ifFalse: [ 
			self at: 0 moveCw: offset intoR: RISCTempReg.
			"strb 	destReg, [srcReg, RISCTempReg]"
			self machineCodeAt: 16 put: (self t: 3 o: 16rC s: 0 rn: srcReg rd: destReg shifterOperand: RISCTempReg).
			^machineCodeSize := 20 ]
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destReg |
	srcReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
	"cond 000 1101 0 0000 dest 0000 0000 srcR"
	self machineCodeAt: 0 put: (self t: 0 o: 16rD s: 0 rn: 0 rd: destReg shifterOperand: srcReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRX16rR [
	"Will get inlined into concretizeAt: switch."
	"Write the word in R(src) into memory at address (base+2*index)"
	<inline: true>
	| index base src |
	src := self concreteRegister: (operands at: 0).
	index := self concreteRegister: (operands at: 1).
	base := self concreteRegister: (operands at: 2).
	"str		src, [base, +index, LSL #1]"
	"cond 011 1100 0 base srcR 00001 00 0 inde"
	self machineCodeAt: 0 put: (self t: 3 o: 16rC s: 0 rn: base rd: src shifterOperand: (16r080 bitOr: index)).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRXbrR [
	"Will get inlined into concretizeAt: switch."
	"Write the word in R(src) into memory at address (base+1*index)"
	<inline: true>
	| index base src |
	src := self concreteRegister: (operands at: 0).
	index := self concreteRegister: (operands at: 1).
	base := self concreteRegister: (operands at: 2).
	"str		src, [base, +index, LSL #0]"
	"cond 011 1100 0 base srcR 00000 00 0 inde"
	self machineCodeAt: 0 put: (self t: 3 o: 16rC s: 0 rn: base rd: src shifterOperand: index).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRXwrR [
	"Will get inlined into concretizeAt: switch."
	"Write the word in R(src) into memory at address (base+4*index)"
	<inline: true>
	| index base src |
	src := self concreteRegister: (operands at: 0).
	index := self concreteRegister: (operands at: 1).
	base := self concreteRegister: (operands at: 2).
	"str		src, [base, +index, LSL #2]"
	"cond 011 1100 0 base srcR 00010 00 0 inde"
	self machineCodeAt: 0 put: (self t: 3 o: 16rC s: 0 rn: base rd: src shifterOperand: (16r100 bitOr: index)).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveXbrRR [
	"Will get inlined into concretizeAt: switch."
	
	<inline: true>
	| index base dest |
	index := self concreteRegister: (operands at: 0).
	base := self concreteRegister: (operands at: 1).
	dest := self concreteRegister: (operands at: 2).
	"LDR	dest, [base, +index, LSL #0]"
	"cond 011 1100 1 base dest 00000 00 0 inde"
	self machineCodeAt: 0 put: (self t: 3 o: 16rC s: 1 rn: base rd: dest shifterOperand: index).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveXwrRR [
	"Will get inlined into concretizeAt: switch."
	
	<inline: true>
	| index base dest |
	index := self concreteRegister: (operands at: 0).
	base := self concreteRegister: (operands at: 1).
	dest := self concreteRegister: (operands at: 2).
	"LDR	dest, [base, +index, LSL #2]"
	"cond 011 1100 1 base dest 00010 00 0 inde"
	self machineCodeAt: 0 put: (self t: 3 o: 16rC s: 1 rn: base rd: dest shifterOperand: (16r100 bitOr: index)).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeNegateR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := self concreteRegister: (operands at: 0).
	"rsb r?, r?, #0"
	self machineCodeAt: 0 put: (self t: 1 o: 3 s: 0 rn: reg rd: reg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeNop [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	self machineCodeAt: 0 put: 16rE1A01001.
	^machineCodeSize := 4
			
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizePopR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| destReg |
	destReg := self concreteRegister: (operands at: 0).
	"cond | 010 | 0100 | 1 | -Rn- | -Rd- | 0000 0000 0100 " "LDR destReg, [SP], #4"
	self machineCodeAt: 0 put: (self t: 2 o: 4 s: 1 rn: SP rd: destReg shifterOperand: 4).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizePrefetchAw [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand |
	addressOperand := operands at: 0.
	self at: 0 moveCw: addressOperand intoR: RISCTempReg.
	"pld	[RISCTempReg, +<byte 0>]"
	"u = 1, I = 0"
	"1111 0101 1101 RTem 1111 0000 byte"
	machineCode
		at: 15 put: 16rF5;
		at: 14 put: (16rD0 bitOr: RISCTempReg);
		at: 13 put: 16rF0.
	^machineCodeSize := 16
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizePushCw [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| word |
	word := operands at: 0.
	self at: 0 moveCw: word intoR: RISCTempReg.
	self machineCodeAt: 16 put: (self t: 2 o: 9 s: 0 rn: SP rd: RISCTempReg shifterOperand: 4).
	^machineCodeSize := 20
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizePushR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg |
	srcReg := self concreteRegister: (operands at: 0).
	"cond | 010 | 1001 | 0 | -Rn- | -Rd- | 0000 0000 0100" "STR srcReg, [sp, #-4]"
	self machineCodeAt: 0 put: (self t: 2 o: 9 s: 0 rn: SP rd: srcReg shifterOperand: 4).
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

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeSubCqR [
	"Will get inlined into concretizeAt: switch."
	"Try whether the quick constant is a small negative number. If it is, optimize."
	<inline: true>
	self rotateable8bitImmediate: (operands at: 0)
		ifTrue: [ :rot :immediate | | reg |
			reg := self concreteRegister: (operands at: 1).
			self machineCodeAt: 0 put: ((self t: 1 o: 2 s: 1) bitOr: reg << 16).
			machineCode at: 0 put: immediate.
			machineCode at: 1 put: (reg << 4 bitOr: rot).
			^machineCodeSize := 4]
		ifFalse: [
			self rotateable8bitImmediate: (operands at: 0) negated
				ifTrue: [ :r :i | 
						opcode := AddCqR.
						operands at: 0 put: (operands at: 0) negated.
						^self concretizeDataOperationCqR: 4]
				ifFalse: [^self concretizeDataOperationCwR: 2]]
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
		[JumpLong]					-> [^self concretizeConditionalJumpLong: AL].
		[JumpLongZero]			-> [^self concretizeConditionalJumpLong: EQ].
		[JumpLongNonZero]		-> [^self concretizeConditionalJumpLong: NE].
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
		[JumpBelow]				-> [^self concretizeConditionalJump: CC]. "unsigned lower"
		[JumpAboveOrEqual]		-> [^self concretizeConditionalJump: CS]. "unsigned greater or equal"
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
		[AddCwR]					-> [^self concretizeDataOperationCwR: 4].
		[AddRR]						-> [^self concretizeDataOperationRR: 4].
		"[AddRdRd]					-> [^self concretizeSEE2OpRdRd: 16r58]."
		[AndCqR]					-> [^self concretizeDataOperationCqR: 0].
		[AndCwR]					-> [^self concretizeDataOperationCwR: 0].
		[AndRR]						-> [^self concretizeDataOperationRR: 0].
		[CmpCqR]					-> [^self concretizeCmpCqR].
		[CmpCwR]					-> [^self concretizeCmpCwR].
		[CmpRR]					-> [^self concretizeCmpRR].
		[CmpRdRd]					-> [^self concretizeCmpRdRd].
		"[DivRdRd]					-> [^self concretizeSEE2OpRdRd: 16r5E].
		[MulRdRd]					-> [^self concretizeSEE2OpRdRd: 16r59]."
		[OrCqR]						-> [^self concretizeDataOperationCqR: 16rC].
		[OrCwR]					-> [^self concretizeDataOperationCwR: 16rC].
		[OrRR]						-> [^self concretizeDataOperationRR: 16rC].
		[SubCqR]					-> [^self concretizeSubCqR].
		[SubCwR]					-> [^self concretizeDataOperationCwR: 2].
		[SubRR]						-> [^self concretizeDataOperationRR: 2].
		"[SubRdRd]					-> [^self concretizeSEE2OpRdRd: 16r5C]."
		[SqrtRd]						-> [^self concretizeSqrtRd].
		[XorCqR]						-> [^self concretizeDataOperationCqR: 1].
		[XorCwR]						-> [^self concretizeDataOperationCwR: 1].
		[XorRR]							-> [^self concretizeDataOperationRR: 1].
		[NegateR]						-> [^self concretizeNegateR].
		[LoadEffectiveAddressMwrR]	-> [^self concretizeLoadEffectiveAddressMwrR].
		[ArithmeticShiftRightCqR]		-> [^self concretizeArithmeticShiftRightCqR].
		[LogicalShiftRightCqR]			-> [^self concretizeLogicalShiftRightCqR].
		[LogicalShiftLeftCqR]			-> [^self concretizeLogicalShiftLeftCqR].
		[ArithmeticShiftRightRR]			-> [^self concretizeArithmeticShiftRightRR].
		[LogicalShiftLeftRR]				-> [^self concretizeLogicalShiftLeftRR].
		[LogicalShiftRightRR]			-> [^self concretizeLogicalShiftRightRR].
		"Data Movement"
		[MoveCqR]			-> [^self concretizeMoveCqR].
		[MoveCwR]			-> [^self concretizeMoveCwR].
		[MoveRR]			-> [^self concretizeMoveRR].
		[MoveAwR]			-> [^self concretizeMoveAwR].
		[MoveRAw]			-> [^self concretizeMoveRAw].
		"While the two MoveMbR and MoveMwR are quite similar (off by 1 bit), they differ way more to
		MoveM16R and MoveM64R. Because of that, they are not merged."
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
		[ConvertRRd]		-> [^self concretizeConvertRRd].
		"ARM specific opcodes" 
		[LDMFD]			-> [^self concretizeLDMFD].
		[STMFD]			-> [^self concretizeSTMFD]	}
]

{ #category : #assertions }
CogARMCompiler >> genGetLeafCallStackPointerFunction [
	cogit MoveR: SP R: R0.
	cogit RetN: 0
]

{ #category : #abi }
CogARMCompiler >> genPassConst: constant asArgument: zeroRelativeArgIndex [
	zeroRelativeArgIndex caseOf: {
		[0] -> [cogit MoveCq: constant R: CArg0Reg].
		[1] -> [cogit MoveCq: constant R: CArg1Reg].
		[2] -> [cogit MoveCq: constant R: CArg2Reg].
		[3] -> [cogit MoveCq: constant R: CArg3Reg].}.
	^0
]

{ #category : #abi }
CogARMCompiler >> genPassReg: abstractRegister asArgument: zeroRelativeArgIndex [
	zeroRelativeArgIndex caseOf: {
		[0] -> [cogit MoveR: abstractRegister R: CArg0Reg].
		[1] -> [cogit MoveR: abstractRegister R: CArg1Reg].
		[2] -> [cogit MoveR: abstractRegister R: CArg2Reg].
		[3] -> [cogit MoveR: abstractRegister R: CArg3Reg].}.
	^0
]

{ #category : #abi }
CogARMCompiler >> genRestoreRegisters [
	"Load the general purpose registers after the return of a trampoline call."
	"Because no registers were saved we don't restore any."
	"cogit
		gen: LDMFD operand: 16r7F"
]

{ #category : #abi }
CogARMCompiler >> genSaveRegisters [
	"Save the general purpose registers for a trampoline call."
	"Save none, because we use only callee saved registers."
	"cogit
		gen: STMFD operand: 16r7F"
]

{ #category : #'abstract instructions' }
CogARMCompiler >> genSubstituteReturnAddress: retpc [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^cogit MoveCw: retpc R: LR
]

{ #category : #testing }
CogARMCompiler >> hasDoublePrecisionFloatingPointSupport [
	"might be true, but is for the forseeable future disabled"
	^false
]

{ #category : #testing }
CogARMCompiler >> hasLinkRegister [
	^true "lr"
]

{ #category : #testing }
CogARMCompiler >> hasPCDependentInstruction [
	"e.g. B, BL: Branch, Branch and Link"
	^true
]

{ #category : #'inline cacheing' }
CogARMCompiler >> instructionBeforeAddress: followingAddress [
	"Answer the instruction immediately preceeding followingAddress."
	^  ((objectMemory byteAt: followingAddress - 1) << 24)
	+  ((objectMemory byteAt: followingAddress - 2) << 16)
	+  ((objectMemory byteAt: followingAddress - 3) << 8)
	+   (objectMemory byteAt: followingAddress - 4)

]

{ #category : #testing }
CogARMCompiler >> is12BitValue: constant ifTrue: trueAlternativeBlock	ifFalse: falseAlternativeBlock [
	"For LDR and STR, there is an instruction allowing for one instruction encoding if the offset is encodable in 12 bit."
	constant abs <= 4095 "(2 raisedTo: 12)-1"
		ifTrue: [
			constant >= 0 
				ifTrue: [trueAlternativeBlock value: 1 value: constant]
				ifFalse: [trueAlternativeBlock value: 0 value: constant abs]]
		ifFalse: falseAlternativeBlock
]

{ #category : #testing }
CogARMCompiler >> isBranch: anInstruction [

	^ (anInstruction >> 24 bitAnd: 16r0E) = 16rA
]

{ #category : #testing }
CogARMCompiler >> isCallPreceedingReturnPC: mcpc [
	"Assuming mcpc is a return pc answer if the instruction before it is a call."
	"There are two types of calls: BL and (MOV, ORR, ORR, ADD, ADD)"
	"PUSH {pc} is not sufficient as a test, because pc may be pushed using the PushR opcode"
	^ (objectMemory byteAt: mcpc - 3) >> 4 = 16rB "BL" 
			or: [ (objectMemory longAt: mcpc - 4) >> 12 = ((self t: 1 o: 4 s: 0 rn: RISCTempReg rd: PC)"add pc, r3, 0" >> 12) ]
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

{ #category : #accessing }
CogARMCompiler >> machineCodeAt: anOffset [
	"read aWord from machineCode, with little endian"
	<inline: true>
	^((machineCode at: anOffset"+0")"<< 0" bitOr: (machineCode at: anOffset + 1) << 8) 
		bitOr: ((machineCode at: anOffset + 2) << 16 bitOr: (machineCode at: anOffset + 3) << 24)

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

{ #category : #encoding }
CogARMCompiler >> minimalRightRingRotationFor: constant initialRotation: iniRightRingRotation [
	"Given a constant and some initial rotation, tries to minimize that rotation in an effort to encode the according byte in constant. This is used, to encode the last 12bit of many operations, for which a 8bit immediate rotated by (2*)4bit is available. That immediate need be encoded with minimal rotation."
	| byte rightRingRotation |
	rightRingRotation := iniRightRingRotation.
		"Counter rotation to get the according byte. Because Smalltalk does not have left ring shift, shift further right."
		rightRingRotation ~= 0 ifTrue: [
			byte := constant >> (-2 * rightRingRotation + 32) bitAnd: 16rFF.
			"For 0, the shift has to be 0. For other immediates, the encoding with minimal rightRingRotation should be choosen."
			byte = 0
				ifTrue: [ rightRingRotation := 0]
				ifFalse: [
					0 to: 2 do: [ :j | 
						(byte bitAnd: 16r03) = 0
							ifTrue: [ rightRingRotation := rightRingRotation - 1.
									byte := byte >> 2 ]]]]
			ifFalse: [ byte := constant bitAnd: 16rFF].
	^{rightRingRotation. byte}
]

{ #category : #printing }
CogARMCompiler >> nameForRegister: reg [ "<Integer>"
	
	<doNotGenerate>
	^#(LR SP PC CArg0Reg CArg0Reg CArg1Reg CArg2Reg CArg3Reg) detect: [:sym| (self class classPool at: sym) = reg] 
		ifNone: [super nameForRegister: reg]
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
	 None, See genSaveRegisters."
	<cmacro: '(self) 0'>
	^0
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> padIfPossibleWithNopsFrom: startAddr to: endAddr [
	| nullBytes |
	nullBytes := (endAddr - startAddr + 1) \\ 4.
	self nopsFrom: startAddr to: endAddr - nullBytes.
	endAddr - nullBytes + 1 to: endAddr 
		do: [ :p | objectMemory byteAt: p put: 16r0]
]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteInlineCacheAt: callSiteReturnAddress tag: cacheTag target: callTargetAddress [
	"Rewrite an inline cache to call a different target for a new tag.  This variant is used
	 to link unlinked sends in ceSend:to:numArgs: et al.  Answer the extent of the code
	 change which is used to compute the range of the icache to flush."
	
	"chacheTag contains an oop to the selector which need be loaded before jumping"
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	| call callDistance |
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 20 to: callSiteReturnAddress -1]."
	false
		ifTrue: [self assert: callTargetAddress >= cogit minCallAddress]
		ifFalse: [callTargetAddress >= cogit minCallAddress ifFalse:
					[self error: 'linking callsite to invalid address']].
	callDistance := (callTargetAddress - (callSiteReturnAddress + 8 "pc offset"- 4 "return offset")) signedIntToLong.
	
	self assert: (self isQuick: callDistance). "we don't support long call updates, yet"
	call := (self t: 5 o: 8)"BL" + (callDistance >> 2 bitAnd: 16rFFFFFF).
	objectMemory
		byteAt: callSiteReturnAddress - 1 put: (call >> 24 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 2 put: (call >> 16 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 3 put: (call >>   8 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 4 put: (call            bitAnd: 16rFF).
	
	"The cacheTag is loaded byte by byte. Each byte needs to be encoded with minimal right ring rotation. See also #at:moveCw:intoR:"
	-20 to: -8 by: 4 do: [ :offset || rotation |
		rotation := self minimalRightRingRotationFor: cacheTag initialRotation: (offset + 8) negated.
		(offset + 8) ~= 0 ifTrue: [ "in case of decoration which may change the last instrution, we should not overwrite bits 9 to 12"
			objectMemory 
				byteAt: callSiteReturnAddress + offset + 1 
				put: (((objectMemory byteAt: callSiteReturnAddress - offset + 1) 
							bitAnd: 16rF0)
						bitOr: (rotation at: 1))].
		objectMemory
			byteAt: callSiteReturnAddress + offset
			put: (rotation at: 2)].

	self assert: (self callTargetFromReturnAddress: callSiteReturnAddress) signedIntToLong = callTargetAddress.
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 20 to: callSiteReturnAddress - 1]."
	^20
]

{ #category : #testing }
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

	| target maximumSpan abstractInstruction |
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	opcode = AlignmentNops ifTrue:
		[| alignment |
		 address := eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: (self isJump or: [opcode = Call]).
	self isJump ifTrue: [self resolveJumpTarget].
	target := operands at: 0.
	abstractInstruction := cogit cCoerceSimple: target to: #'AbstractInstruction *'.
	"maximumSpan calculation copied from CogIA32Compiler TODO: extract method?"
	(self isAnInstruction: abstractInstruction)
		ifTrue:
			[maximumSpan := abstractInstruction address
							- (((cogit abstractInstruction: self follows: abstractInstruction)
								ifTrue: [eventualAbsoluteAddress]
								ifFalse: [address]) + 2)]
		ifFalse:
			[maximumSpan := target - (eventualAbsoluteAddress + 2)].
	address := eventualAbsoluteAddress.
	^machineCodeSize := opcode = Call 
				ifTrue: [(self isQuick: maximumSpan) ifTrue: [4] ifFalse: [20]]
				ifFalse: [(self isLongJump not and: [self isQuick: maximumSpan])
								ifTrue: [4]
								ifFalse: [16]] "load address to register, add"
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

{ #category : #encoding }
CogARMCompiler >> t: type o: flagsOrOpcode s: doUpdateStatusRegister rn:  sourceRegister rd: targetRegister shifterOperand: so [
	<inline: true>
	^(self t: type o: flagsOrOpcode s: doUpdateStatusRegister rn: sourceRegister rd: targetRegister) bitOr: so
]
