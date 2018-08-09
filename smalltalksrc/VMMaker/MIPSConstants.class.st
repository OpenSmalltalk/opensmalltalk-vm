"
MIPS opcodes and register names.
"
Class {
	#name : #MIPSConstants,
	#superclass : #SharedPool,
	#classVars : [
		'A0',
		'A1',
		'A2',
		'A3',
		'ADDIU',
		'ADDU',
		'AND',
		'ANDI',
		'AT',
		'BEQ',
		'BGEZ',
		'BGTZ',
		'BLEZ',
		'BLTZ',
		'BNE',
		'BREAK',
		'DIV',
		'FP',
		'GP',
		'HintLoad',
		'HintStore',
		'J',
		'JAL',
		'JALR',
		'JR',
		'K0',
		'K1',
		'LB',
		'LBU',
		'LH',
		'LHU',
		'LUI',
		'LW',
		'MFHI',
		'MFLO',
		'MULT',
		'OR',
		'ORI',
		'OneInstruction',
		'PREF',
		'R0',
		'R1',
		'R10',
		'R11',
		'R12',
		'R13',
		'R14',
		'R15',
		'R16',
		'R17',
		'R18',
		'R19',
		'R2',
		'R20',
		'R21',
		'R22',
		'R23',
		'R24',
		'R25',
		'R26',
		'R27',
		'R28',
		'R29',
		'R3',
		'R30',
		'R31',
		'R4',
		'R5',
		'R6',
		'R7',
		'R8',
		'R9',
		'RA',
		'REGIMM',
		'S0',
		'S1',
		'S2',
		'S3',
		'S4',
		'S5',
		'S6',
		'S7',
		'SB',
		'SH',
		'SLL',
		'SLLV',
		'SLT',
		'SLTI',
		'SLTIU',
		'SLTU',
		'SP',
		'SPECIAL',
		'SRA',
		'SRAV',
		'SRL',
		'SRLV',
		'SUBU',
		'SW',
		'T0',
		'T1',
		'T2',
		'T3',
		'T4',
		'T5',
		'T6',
		'T7',
		'T8',
		'T9',
		'TwoInstructions',
		'V0',
		'V1',
		'XOR',
		'XORI',
		'ZR'
	],
	#category : 'VMMaker-JIT'
}

{ #category : #'as yet unclassified' }
MIPSConstants class >> initialize [
	super initialize.
	
	OneInstruction := 4.
	TwoInstructions := 8.
	
	HintLoad := 0.
	HintStore := 1.
		
	self initializeRegisters.
	self initializeOpcodes.
	self initializeSpecialFunctions.
	self initializeRegImmRts.
]

{ #category : #'as yet unclassified' }
MIPSConstants class >> initializeOpcodes [
	SPECIAL := 0.
	REGIMM := 1.
	J := 2.
	JAL := 3.
	BEQ := 4.
	BNE := 5.
	BLEZ := 6.
	BGTZ := 7.
	ADDIU := 9.
	SLTI := 10.
	SLTIU := 11.
	ANDI := 12.
	ORI := 13.
	XORI := 14.
	LUI := 15.
	LB := 32.
	LH := 33.
	LW := 35.
	LBU := 36.
	LHU := 37.
	SB := 40.
	SH := 41.
	SW := 43.
	PREF := 51.
]

{ #category : #'as yet unclassified' }
MIPSConstants class >> initializeRegImmRts [
	BLTZ := 0.
	BGEZ := 1.
]

{ #category : #'as yet unclassified' }
MIPSConstants class >> initializeRegisters [
	self flag: #OABI.
	R0 := ZR := 0. "Hardwired zero"
	R1 := AT := 1. "Assembler temp - used to expand psuedo instructions"
	R2 := V0 := 2. "ABI: result register"
	R3 := V1 := 3. "ABI: result register"
	R4 := A0 := 4. "ABI: argument register"
	R5 := A1 := 5. "ABI: argument register"
	R6 := A2 := 6. "ABI: argument register"
	R7 := A3 := 7. "ABI: argument register"
	R8 := T0 := 8. "ABI: volatile"
	R9 := T1 := 9. "ABI: volatile"
	R10 := T2 := 10. "ABI: volatile"
	R11 := T3 := 11. "ABI: volatile"
	R12 := T4 := 12. "ABI: volatile"
	R13 := T5 := 13. "ABI: volatile"
	R14 := T6 := 14. "ABI: volatile"
	R15 := T7 := 15. "ABI: volatile"
	R16 := S0 := 16. "ABI: preserved"
	R17 := S1 := 17. "ABI: preserved"
	R18 := S2 := 18. "ABI: preserved"
	R19 := S3 := 19. "ABI: preserved"
	R20 := S4 := 20. "ABI: preserved"
	R21 := S5 := 21. "ABI: preserved"
	R22 := S6 := 22. "ABI: preserved"
	R23 := S7 := 23. "ABI: preserved"
	R24 := T8 := 24. "ABI: volatile"
	R25 := T9 := 25. "Special use in some position-independent code"
	R26 := K0 := 26. "Reserved for OS"
	R27 := K1 := 27. "Reserved for OS"
	R28 := GP := 28. "Special use in some position-independent code"
	R29 := SP := 29. "Stack pointer"
	R30 := FP := 30. "Frame pointer"
	R31 := RA := 31. "Link register"

	
]

{ #category : #'as yet unclassified' }
MIPSConstants class >> initializeSpecialFunctions [
	SLL := 0.
	SRL := 2.
	SRA := 3.
	SLLV := 4.
	SRLV := 6.
	SRAV := 7.
	JR := 8.
	JALR := 9.
	BREAK := 13.
	MFHI := 16.
	MFLO := 18.
	MULT := 24.
	DIV := 26.
	ADDU := 33.
	SUBU := 35.
	AND := 36.
	OR := 37.
	XOR := 38.
	SLT := 42.
	SLTU := 43.
]

{ #category : #'as yet unclassified' }
MIPSConstants class >> nameForRegister: registerNumber [
	^#(zr at v0 v1 a0 a1 a2 a3
		t0 t1 t2 t3 t4 t5 t6 t7
		s0 s1 s2 s3 s4 s5 s6 s7
		t8 t9 k0 k1 gp sp fp ra) at: registerNumber + 1
]
