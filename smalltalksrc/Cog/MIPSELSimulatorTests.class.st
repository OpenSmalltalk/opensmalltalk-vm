Class {
	#name : #MIPSELSimulatorTests,
	#superclass : #TestCase,
	#pools : [
		'MIPSConstants'
	],
	#category : #'Cog-Processors-Tests'
}

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testAddiu [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: V0 R: ZR C: 42).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  2402002A  addiu v0, zr, 42
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: 42].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testAddiuNegative [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: V0 R: ZR C: -42).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  2402FFD6  addiu v0, zr, -42
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: -42].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testAddiuOverflow [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler luiR: T0 C: 16r7FFF).
			stream nextPut: (compiler oriR: T0 R: T0 C: 16rFFFF).
			stream nextPut: (compiler addiuR: V0 R: T0 C: 1).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  3C087FFF  lui t0, 32767
00000004  3508FFFF  ori t0, t0, 65535
00000008  25020001  addiu v0, t0, 1
0000000C  03E00008  jr ra
00000010  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: -1 << 31].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testAddiuUnderflow [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler luiR: T0 C: 16r8000).
			stream nextPut: (compiler addiuR: V0 R: T0 C: -1).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  3C088000  lui t0, -32768
00000004  2502FFFF  addiu v0, t0, -1
00000008  03E00008  jr ra
0000000C  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: (1 << 31) - 1].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testAddu [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler adduR: V0 R: A0 R: A1).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  00851021  addu v0, a0, a1
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 3 with: 4 with: 0 with: 0.
			self assert: result equals: 7.
			result := simulator call: 0 with: 3 with: -4 with: 0 with: 0.
			self assert: result equals: -1.
			result := simulator call: 0 with: -3 with: 4 with: 0 with: 0.
			self assert: result equals: 1.
			result := simulator call: 0 with: 16r7FFFFFFF with: 1 with: 0 with: 0.
			self assert: result equals: (-1 << 31).
			result := simulator call: 0 with: (-1 << 31) with: -1 with: 0 with: 0.
			self assert: result equals: (1 << 31) - 1].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testAnd [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler andR: V0 R: A0 R: A1).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  00851024  and v0, a0, a1
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 2r1101 with: 2r1011 with: 0 with: 0.
			self assert: result equals: 2r1001.
			result := simulator call: 0 with: -1 with: 42 with: 0 with: 0.
			self assert: result equals: 42].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testAndi [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler andiR: V0 R: A0 C: 16rFF).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  308200FF  andi v0, a0, 255
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 16r12345678 with: 0 with: 0 with: 0.
			self assert: result equals: 16r78.
			result := simulator call: 0 with: -1 with: 0 with: 0 with: 0.
			self assert: result equals: 16rFF].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testAndiNegative [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler andiR: V0 R: A0 C: -1). "Immediate is zero-extended, so same as 16rFFFF"
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  3082FFFF  andi v0, a0, 65535
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 16r12345678 with: 0 with: 0 with: 0.
			self assert: result equals: 16r5678.
			result := simulator call: 0 with: -1 with: 0 with: 0 with: 0.
			self assert: result equals: 16rFFFF].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testBeq [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: V0 R: ZR C: 4).
			stream nextPut: (compiler beqR: A0 R: A1 offset: 8).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  24020004  addiu v0, zr, 4
00000004  10850002  beq a0, a1, +8 ; =10
00000008  00000000  nop
0000000C  24020003  addiu v0, zr, 3
00000010  03E00008  jr ra
00000014  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 4.
			result := simulator call: 0 with: 1 with: 0 with: 0 with: 0.
			self assert: result equals: 3].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testBeqDelaySlot [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler beqR: A0 R: A1 offset: 8).
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: V0 C: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  10850002  beq a0, a1, +8 ; =C
00000004  24020003  addiu v0, zr, 3
00000008  24420004  addiu v0, v0, 4
0000000C  03E00008  jr ra
00000010  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 3.
			result := simulator call: 0 with: 1 with: 0 with: 0 with: 0.
			self assert: result equals: 7].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testBgez [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: V0 R: ZR C: 4).
			stream nextPut: (compiler bgezR: A0 offset: 8).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  24020004  addiu v0, zr, 4
00000004  04810002  bgez a0, +8 ; =10
00000008  00000000  nop
0000000C  24020003  addiu v0, zr, 3
00000010  03E00008  jr ra
00000014  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: -1 with: 0 with: 0 with: 0.
			self assert: result equals: 3.
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 4.
			result := simulator call: 0 with: 1 with: 0 with: 0 with: 0.
			self assert: result equals: 4].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testBgezDelaySlot [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler bgezR: A0 offset: 8).
			stream nextPut: (compiler addiuR: V0 R: ZR C: 4). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  04810002  bgez a0, +8 ; =C
00000004  24020004  addiu v0, zr, 4
00000008  24020003  addiu v0, zr, 3
0000000C  03E00008  jr ra
00000010  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: -1 with: 0 with: 0 with: 0.
			self assert: result equals: 3.
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 4.
			result := simulator call: 0 with: 1 with: 0 with: 0 with: 0.
			self assert: result equals: 4].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testBgtz [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: V0 R: ZR C: 4).
			stream nextPut: (compiler bgtzR: A0 offset: 8).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  24020004  addiu v0, zr, 4
00000004  1C800002  bgtz a0, +8 ; =10
00000008  00000000  nop
0000000C  24020003  addiu v0, zr, 3
00000010  03E00008  jr ra
00000014  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: -1 with: 0 with: 0 with: 0.
			self assert: result equals: 3.
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 3.
			result := simulator call: 0 with: 1 with: 0 with: 0 with: 0.
			self assert: result equals: 4].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testBgtzDelaySlot [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler bgtzR: A0 offset: 8).
			stream nextPut: (compiler addiuR: V0 R: ZR C: 4). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  1C800002  bgtz a0, +8 ; =C
00000004  24020004  addiu v0, zr, 4
00000008  24020003  addiu v0, zr, 3
0000000C  03E00008  jr ra
00000010  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: -1 with: 0 with: 0 with: 0.
			self assert: result equals: 3.
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 3.
			result := simulator call: 0 with: 1 with: 0 with: 0 with: 0.
			self assert: result equals: 4].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testBlez [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: V0 R: ZR C: 4).
			stream nextPut: (compiler blezR: A0 offset: 8).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  24020004  addiu v0, zr, 4
00000004  18800002  blez a0, +8 ; =10
00000008  00000000  nop
0000000C  24020003  addiu v0, zr, 3
00000010  03E00008  jr ra
00000014  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: -1 with: 0 with: 0 with: 0.
			self assert: result equals: 4.
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 4.
			result := simulator call: 0 with: 1 with: 0 with: 0 with: 0.
			self assert: result equals: 3].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testBlezDelaySlot [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler blezR: A0 offset: 8).
			stream nextPut: (compiler addiuR: V0 R: ZR C: 4). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  18800002  blez a0, +8 ; =C
00000004  24020004  addiu v0, zr, 4
00000008  24020003  addiu v0, zr, 3
0000000C  03E00008  jr ra
00000010  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: -1 with: 0 with: 0 with: 0.
			self assert: result equals: 4.
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 4.
			result := simulator call: 0 with: 1 with: 0 with: 0 with: 0.
			self assert: result equals: 3].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testBltz [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: V0 R: ZR C: 4).
			stream nextPut: (compiler bltzR: A0 offset: 8).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  24020004  addiu v0, zr, 4
00000004  04800002  bltz a0, +8 ; =10
00000008  00000000  nop
0000000C  24020003  addiu v0, zr, 3
00000010  03E00008  jr ra
00000014  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: -1 with: 0 with: 0 with: 0.
			self assert: result equals: 4.
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 3.
			result := simulator call: 0 with: 1 with: 0 with: 0 with: 0.
			self assert: result equals: 3].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testBltzDelaySlot [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler bltzR: A0 offset: 8).
			stream nextPut: (compiler addiuR: V0 R: ZR C: 4). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  04800002  bltz a0, +8 ; =C
00000004  24020004  addiu v0, zr, 4
00000008  24020003  addiu v0, zr, 3
0000000C  03E00008  jr ra
00000010  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: -1 with: 0 with: 0 with: 0.
			self assert: result equals: 4.
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 3.
			result := simulator call: 0 with: 1 with: 0 with: 0 with: 0.
			self assert: result equals: 3].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testBne [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: V0 R: ZR C: 4).
			stream nextPut: (compiler bneR: A0 R: A1 offset: 8).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  24020004  addiu v0, zr, 4
00000004  14850002  bne a0, a1, +8 ; =10
00000008  00000000  nop
0000000C  24020003  addiu v0, zr, 3
00000010  03E00008  jr ra
00000014  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 3.
			result := simulator call: 0 with: 1 with: 0 with: 0 with: 0.
			self assert: result equals: 4].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testBneDelaySlot [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler bneR: A0 R: A1 offset: 8).
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: V0 C: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  14850002  bne a0, a1, +8 ; =C
00000004  24020003  addiu v0, zr, 3
00000008  24420004  addiu v0, v0, 4
0000000C  03E00008  jr ra
00000010  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 7.
			result := simulator call: 0 with: 1 with: 0 with: 0 with: 0.
			self assert: result equals: 3].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testBreak [
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler break: 0)]
		disassembly:
'00000000  0000000D  break
'		run: 
			[:simulator | 
			self should: [simulator call: 0 with: 0 with: 0 with: 0 with: 0] raise: Error].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testDiv [
	"Strangely, objdump is unable to disassemble this sequence."	
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler divR: A0 R: A1).
			stream nextPut: (compiler mfloR: V0).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  0085001A  div a0, a1
00000004  00001012  mflo v0
00000008  03E00008  jr ra
0000000C  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 3 with: 7 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -3 with: 7 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: 3 with: -7 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -3 with: -7 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: 7 with: 3 with: 0 with: 0.
			self assert: result equals: 2.
			result := simulator call: 0 with: -7 with: 3 with: 0 with: 0.
			self assert: result equals: -2.
			result := simulator call: 0 with: 7 with: -3 with: 0 with: 0.
			self assert: result equals: -2.
			result := simulator call: 0 with: -7 with: -3 with: 0 with: 0.
			self assert: result equals: 2.
			result := simulator call: 0 with: 42 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -16r80000000 with: -1 with: 0 with: 0.
			self assert: result equals: -16r80000000].	
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler divR: A0 R: A1).
			stream nextPut: (compiler mfhiR: V0).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  0085001A  div a0, a1
00000004  00001010  mfhi v0
00000008  03E00008  jr ra
0000000C  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 3 with: 7 with: 0 with: 0.
			self assert: result equals: 3.
			result := simulator call: 0 with: -3 with: 7 with: 0 with: 0.
			self assert: result equals: -3.
			result := simulator call: 0 with: 3 with: -7 with: 0 with: 0.
			self assert: result equals: 3.
			result := simulator call: 0 with: -3 with: -7 with: 0 with: 0.
			self assert: result equals: -3.
			result := simulator call: 0 with: 7 with: 3 with: 0 with: 0.
			self assert: result equals: 1.
			result := simulator call: 0 with: -7 with: 3 with: 0 with: 0.
			self assert: result equals: -1.
			result := simulator call: 0 with: 7 with: -3 with: 0 with: 0.
			self assert: result equals: 1.
			result := simulator call: 0 with: -7 with: -3 with: 0 with: 0.
			self assert: result equals: -1.
			result := simulator call: 0 with: 42 with: 0 with: 0 with: 0.
			self assert: result equals: 42.
			result := simulator call: 0 with: -16r80000000 with: -1 with: 0 with: 0.
			self assert: result equals: 0].
]

{ #category : #execution }
MIPSELSimulatorTests >> testGenerateInto: generateBlock disassembly: expectedDisassembly run: executeBlock [
	| actualDisassembly compiler memory stopInstr instructions simulator |	
	MIPSConstants initialize.
	compiler := CogMIPSELCompiler new.
	
	stopInstr := compiler stop.
	memory := ByteArray new: 1024.
	1 to: 1024 by: 4 do:
		[:i | memory unsignedLongAt: i put: stopInstr bigEndian: false].

	instructions := Array streamContents: [:stream | generateBlock value: stream value: compiler].
	instructions withIndexDo: 
		[:instr :i | memory unsignedLongAt: (4 * (i - 1)) + 1 put: instr bigEndian: false].
	
	actualDisassembly := MIPSDisassembler new disassemble: memory from: 0 to: instructions size * 4.
	self assert: actualDisassembly equals: expectedDisassembly.
	
	simulator := MIPSELSimulator new initializeWithMemory: memory.
	executeBlock value: simulator.
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testJ [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3).
			stream nextPut: (compiler jA: 16r10).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: V0 C: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  24020003  addiu v0, zr, 3
00000004  08000004  j 10
00000008  00000000  nop
0000000C  24420004  addiu v0, v0, 4
00000010  03E00008  jr ra
00000014  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: 3].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testJDelaySlot [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler jA: 16rC).
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: V0 C: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  08000003  j C
00000004  24020003  addiu v0, zr, 3
00000008  24420004  addiu v0, v0, 4
0000000C  03E00008  jr ra
00000010  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: 3].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testJal [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: T0 R: RA C: 0).
			stream nextPut: (compiler jalA: 16r1C).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: V0 C: 3).
			stream nextPut: (compiler jR: T0).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler stop).
			stream nextPut: (compiler addiuR: V0 R: ZR C: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  27E80000  addiu t0, ra, 0
00000004  0C000007  jal 1C
00000008  00000000  nop
0000000C  24420003  addiu v0, v0, 3
00000010  01000008  jr t0
00000014  00000000  nop
00000018  0000000D  break
0000001C  24020004  addiu v0, zr, 4
00000020  03E00008  jr ra
00000024  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: 7].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testJalDelaySlot [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: T0 R: RA C: 0).
			stream nextPut: (compiler jalA: 16r1C).
			stream nextPut: (compiler addiuR: V0 R: ZR C: 11). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: V0 C: 3).
			stream nextPut: (compiler jR: T0).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler stop).
			stream nextPut: (compiler addiuR: V0 R: V0 C: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  27E80000  addiu t0, ra, 0
00000004  0C000007  jal 1C
00000008  2402000B  addiu v0, zr, 11
0000000C  24420003  addiu v0, v0, 3
00000010  01000008  jr t0
00000014  00000000  nop
00000018  0000000D  break
0000001C  24420004  addiu v0, v0, 4
00000020  03E00008  jr ra
00000024  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: 18].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testJalr [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: T0 R: RA C: 0).
			stream nextPut: (compiler addiuR: T9 R: ZR C: 16r20).
			stream nextPut: (compiler jalR: T9).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: V0 C: 3).
			stream nextPut: (compiler jR: T0).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler stop).
			stream nextPut: (compiler addiuR: V0 R: ZR C: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  27E80000  addiu t0, ra, 0
00000004  24190020  addiu t9, zr, 32
00000008  0320F809  jalr t9
0000000C  00000000  nop
00000010  24420003  addiu v0, v0, 3
00000014  01000008  jr t0
00000018  00000000  nop
0000001C  0000000D  break
00000020  24020004  addiu v0, zr, 4
00000024  03E00008  jr ra
00000028  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: 7].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testJalrDelaySlot [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: T0 R: RA C: 0).
			stream nextPut: (compiler addiuR: T9 R: ZR C: 16r20).
			stream nextPut: (compiler jalR: T9).
			stream nextPut: (compiler addiuR: V0 R: ZR C: 11). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: V0 C: 3).
			stream nextPut: (compiler jR: T0).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler stop).
			stream nextPut: (compiler addiuR: V0 R: V0 C: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  27E80000  addiu t0, ra, 0
00000004  24190020  addiu t9, zr, 32
00000008  0320F809  jalr t9
0000000C  2402000B  addiu v0, zr, 11
00000010  24420003  addiu v0, v0, 3
00000014  01000008  jr t0
00000018  00000000  nop
0000001C  0000000D  break
00000020  24420004  addiu v0, v0, 4
00000024  03E00008  jr ra
00000028  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: 18].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testJr [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3).
			stream nextPut: (compiler addiuR: T9 R: ZR C: 16r14).
			stream nextPut: (compiler jR: T9).
			stream nextPut: (compiler nop). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: V0 C: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  24020003  addiu v0, zr, 3
00000004  24190014  addiu t9, zr, 20
00000008  03200008  jr t9
0000000C  00000000  nop
00000010  24420004  addiu v0, v0, 4
00000014  03E00008  jr ra
00000018  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: 3].
]

{ #category : #'tests - control' }
MIPSELSimulatorTests >> testJrDelaySlot [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler addiuR: T9 R: ZR C: 16r10).
			stream nextPut: (compiler jR: T9).
			stream nextPut: (compiler addiuR: V0 R: ZR C: 3). "Delay slot"
			stream nextPut: (compiler addiuR: V0 R: V0 C: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  24190010  addiu t9, zr, 16
00000004  03200008  jr t9
00000008  24020003  addiu v0, zr, 3
0000000C  24420004  addiu v0, v0, 4
00000010  03E00008  jr ra
00000014  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: 3].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testLb [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler lbR: V0 base: A0 offset: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  80820004  lb v0, 4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator memory at: 16rE4 + 1 put: 42.
			simulator memory at: 16rE5 + 1 put: 43.
			simulator memory at: 16rE6 + 1 put: 44.
			simulator memory at: 16rE7 + 1 put: 45.
			simulator memory at: 16rF4 + 1 put: 16r100 - 42.
			simulator memory at: 16rF5 + 1 put: 16r100 - 43.
			simulator memory at: 16rF6 + 1 put: 16r100 - 44.
			simulator memory at: 16rF7 + 1 put: 16r100 - 45.
			result := simulator call: 0 with: 16rE0 with: 0 with: 0 with: 0.
			self assert: result equals: 42.
			result := simulator call: 0 with: 16rE1 with: 0 with: 0 with: 0.
			self assert: result equals: 43.
			result := simulator call: 0 with: 16rE2 with: 0 with: 0 with: 0.
			self assert: result equals: 44.
			result := simulator call: 0 with: 16rE3 with: 0 with: 0 with: 0.
			self assert: result equals: 45.
			result := simulator call: 0 with: 16rF0 with: 0 with: 0 with: 0.
			self assert: result equals: -42.
			result := simulator call: 0 with: 16rF1 with: 0 with: 0 with: 0.
			self assert: result equals: -43.
			result := simulator call: 0 with: 16rF2 with: 0 with: 0 with: 0.
			self assert: result equals: -44.
			result := simulator call: 0 with: 16rF3 with: 0 with: 0 with: 0.
			self assert: result equals: -45].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testLbNegativeOffset [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler lbR: V0 base: A0 offset: -4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  8082FFFC  lb v0, -4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator memory at: 16rE4 + 1 put: 42.
			simulator memory at: 16rE5 + 1 put: 43.
			simulator memory at: 16rE6 + 1 put: 44.
			simulator memory at: 16rE7 + 1 put: 45.
			simulator memory at: 16rF4 + 1 put: 16r100 - 42.
			simulator memory at: 16rF5 + 1 put: 16r100 - 43.
			simulator memory at: 16rF6 + 1 put: 16r100 - 44.
			simulator memory at: 16rF7 + 1 put: 16r100 - 45.
			result := simulator call: 0 with: 16rE8 with: 0 with: 0 with: 0.
			self assert: result equals: 42.
			result := simulator call: 0 with: 16rE9 with: 0 with: 0 with: 0.
			self assert: result equals: 43.
			result := simulator call: 0 with: 16rEA with: 0 with: 0 with: 0.
			self assert: result equals: 44.
			result := simulator call: 0 with: 16rEB with: 0 with: 0 with: 0.
			self assert: result equals: 45.
			result := simulator call: 0 with: 16rF8 with: 0 with: 0 with: 0.
			self assert: result equals: -42.
			result := simulator call: 0 with: 16rF9 with: 0 with: 0 with: 0.
			self assert: result equals: -43.
			result := simulator call: 0 with: 16rFA with: 0 with: 0 with: 0.
			self assert: result equals: -44.
			result := simulator call: 0 with: 16rFB with: 0 with: 0 with: 0.
			self assert: result equals: -45].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testLbu [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler lbuR: V0 base: A0 offset: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  90820004  lbu v0, 4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator memory at: 16rE4 + 1 put: 42.
			simulator memory at: 16rE5 + 1 put: 43.
			simulator memory at: 16rE6 + 1 put: 44.
			simulator memory at: 16rE7 + 1 put: 45.
			simulator memory at: 16rF4 + 1 put: 16r100 - 42.
			simulator memory at: 16rF5 + 1 put: 16r100 - 43.
			simulator memory at: 16rF6 + 1 put: 16r100 - 44.
			simulator memory at: 16rF7 + 1 put: 16r100 - 45.
			result := simulator call: 0 with: 16rE0 with: 0 with: 0 with: 0.
			self assert: result equals: 42.
			result := simulator call: 0 with: 16rE1 with: 0 with: 0 with: 0.
			self assert: result equals: 43.
			result := simulator call: 0 with: 16rE2 with: 0 with: 0 with: 0.
			self assert: result equals: 44.
			result := simulator call: 0 with: 16rE3 with: 0 with: 0 with: 0.
			self assert: result equals: 45.
			result := simulator call: 0 with: 16rF0 with: 0 with: 0 with: 0.
			self assert: result equals: 16r100 - 42.
			result := simulator call: 0 with: 16rF1 with: 0 with: 0 with: 0.
			self assert: result equals: 16r100 - 43.
			result := simulator call: 0 with: 16rF2 with: 0 with: 0 with: 0.
			self assert: result equals: 16r100 - 44.
			result := simulator call: 0 with: 16rF3 with: 0 with: 0 with: 0.
			self assert: result equals: 16r100 - 45].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testLbuNegativeOffset [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler lbuR: V0 base: A0 offset: -4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  9082FFFC  lbu v0, -4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator memory at: 16rE4 + 1 put: 42.
			simulator memory at: 16rE5 + 1 put: 43.
			simulator memory at: 16rE6 + 1 put: 44.
			simulator memory at: 16rE7 + 1 put: 45.
			simulator memory at: 16rF4 + 1 put: 16r100 - 42.
			simulator memory at: 16rF5 + 1 put: 16r100 - 43.
			simulator memory at: 16rF6 + 1 put: 16r100 - 44.
			simulator memory at: 16rF7 + 1 put: 16r100 - 45.
			result := simulator call: 0 with: 16rE8 with: 0 with: 0 with: 0.
			self assert: result equals: 42.
			result := simulator call: 0 with: 16rE9 with: 0 with: 0 with: 0.
			self assert: result equals: 43.
			result := simulator call: 0 with: 16rEA with: 0 with: 0 with: 0.
			self assert: result equals: 44.
			result := simulator call: 0 with: 16rEB with: 0 with: 0 with: 0.
			self assert: result equals: 45.
			result := simulator call: 0 with: 16rF8 with: 0 with: 0 with: 0.
			self assert: result equals: 16r100 - 42.
			result := simulator call: 0 with: 16rF9 with: 0 with: 0 with: 0.
			self assert: result equals: 16r100 - 43.
			result := simulator call: 0 with: 16rFA with: 0 with: 0 with: 0.
			self assert: result equals: 16r100 - 44.
			result := simulator call: 0 with: 16rFB with: 0 with: 0 with: 0.
			self assert: result equals: 16r100 - 45].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testLh [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler lhR: V0 base: A0 offset: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  84820004  lh v0, 4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator memory at: 16rE4 + 1 put: 42.
			simulator memory at: 16rE5 + 1 put: 43.
			simulator memory at: 16rE6 + 1 put: 44.
			simulator memory at: 16rE7 + 1 put: 45.
			simulator memory at: 16rF4 + 1 put: 16r100 - 42.
			simulator memory at: 16rF5 + 1 put: 16r100 - 43.
			simulator memory at: 16rF6 + 1 put: 16r100 - 44.
			simulator memory at: 16rF7 + 1 put: 16r100 - 45.
			result := simulator call: 0 with: 16rE0 with: 0 with: 0 with: 0.
			self assert: result equals: 16r2B2A.
			self should: [simulator call: 0 with: 16rE1 with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rE2 with: 0 with: 0 with: 0.
			self assert: result equals: 16r2D2C.
			self should: [simulator call: 0 with: 16rE3 with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rF0 with: 0 with: 0 with: 0.
			self assert: result equals:  -16r2A2A.
			self should: [simulator call: 0 with: 16rF1 with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rF2 with: 0 with: 0 with: 0.
			self assert: result equals: -16r2C2C.
			self should: [simulator call: 0 with: 16rF3 with: 0 with: 0 with: 0] raise: Error].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testLhNegativeOffset [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler lhR: V0 base: A0 offset: -4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  8482FFFC  lh v0, -4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator memory at: 16rE4 + 1 put: 42.
			simulator memory at: 16rE5 + 1 put: 43.
			simulator memory at: 16rE6 + 1 put: 44.
			simulator memory at: 16rE7 + 1 put: 45.
			simulator memory at: 16rF4 + 1 put: 16r100 - 42.
			simulator memory at: 16rF5 + 1 put: 16r100 - 43.
			simulator memory at: 16rF6 + 1 put: 16r100 - 44.
			simulator memory at: 16rF7 + 1 put: 16r100 - 45.
			result := simulator call: 0 with: 16rE8 with: 0 with: 0 with: 0.
			self assert: result equals: 16r2B2A.
			self should: [simulator call: 0 with: 16rE9 with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rEA with: 0 with: 0 with: 0.
			self assert: result equals: 16r2D2C.
			self should: [simulator call: 0 with: 16rEB with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rF8 with: 0 with: 0 with: 0.
			self assert: result equals:  -16r2A2A.
			self should: [simulator call: 0 with: 16rF9 with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rFA with: 0 with: 0 with: 0.
			self assert: result equals: -16r2C2C.
			self should: [simulator call: 0 with: 16rFB with: 0 with: 0 with: 0] raise: Error].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testLhu [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler lhuR: V0 base: A0 offset: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  94820004  lhu v0, 4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator memory at: 16rE4 + 1 put: 42.
			simulator memory at: 16rE5 + 1 put: 43.
			simulator memory at: 16rE6 + 1 put: 44.
			simulator memory at: 16rE7 + 1 put: 45.
			simulator memory at: 16rF4 + 1 put: 16r100 - 42.
			simulator memory at: 16rF5 + 1 put: 16r100 - 43.
			simulator memory at: 16rF6 + 1 put: 16r100 - 44.
			simulator memory at: 16rF7 + 1 put: 16r100 - 45.
			result := simulator call: 0 with: 16rE0 with: 0 with: 0 with: 0.
			self assert: result equals: 16r2B2A.
			self should: [simulator call: 0 with: 16rE1 with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rE2 with: 0 with: 0 with: 0.
			self assert: result equals: 16r2D2C.
			self should: [simulator call: 0 with: 16rE3 with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rF0 with: 0 with: 0 with: 0.
			self assert: result equals: 16rD5D6.
			self should: [simulator call: 0 with: 16rF1 with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rF2 with: 0 with: 0 with: 0.
			self assert: result equals: 16rD3D4.
			self should: [simulator call: 0 with: 16rF3 with: 0 with: 0 with: 0] raise: Error].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testLhuNegativeOffset [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler lhuR: V0 base: A0 offset: -4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  9482FFFC  lhu v0, -4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator memory at: 16rE4 + 1 put: 42.
			simulator memory at: 16rE5 + 1 put: 43.
			simulator memory at: 16rE6 + 1 put: 44.
			simulator memory at: 16rE7 + 1 put: 45.
			simulator memory at: 16rF4 + 1 put: 16r100 - 42.
			simulator memory at: 16rF5 + 1 put: 16r100 - 43.
			simulator memory at: 16rF6 + 1 put: 16r100 - 44.
			simulator memory at: 16rF7 + 1 put: 16r100 - 45.
			result := simulator call: 0 with: 16rE8 with: 0 with: 0 with: 0.
			self assert: result equals: 16r2B2A.
			self should: [simulator call: 0 with: 16rE9 with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rEA with: 0 with: 0 with: 0.
			self assert: result equals: 16r2D2C.
			self should: [simulator call: 0 with: 16rEB with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rF8 with: 0 with: 0 with: 0.
			self assert: result equals: 16rD5D6.
			self should: [simulator call: 0 with: 16rF9 with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rFA with: 0 with: 0 with: 0.
			self assert: result equals: 16rD3D4.
			self should: [simulator call: 0 with: 16rFB with: 0 with: 0 with: 0] raise: Error].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testLoadLargeLiteral [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler luiR: V0 C: 16r3FFF).
			stream nextPut: (compiler oriR: V0 R: V0 C: 16rFFFF).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  3C023FFF  lui v0, 16383
00000004  3442FFFF  ori v0, v0, 65535
00000008  03E00008  jr ra
0000000C  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: 16r3FFFFFFF].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testLui [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler luiR: V0 C: 42).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  3C02002A  lui v0, 42
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: 42 << 16].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testLuiNegative [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler luiR: V0 C: -42).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  3C02FFD6  lui v0, -42
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: -42 << 16].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testLw [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler lwR: V0 base: A0 offset: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  8C820004  lw v0, 4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator memory at: 16rE4 + 1 put: 42.
			simulator memory at: 16rE5 + 1 put: 43.
			simulator memory at: 16rE6 + 1 put: 44.
			simulator memory at: 16rE7 + 1 put: 45.
			simulator memory at: 16rF4 + 1 put: 16r100 - 42.
			simulator memory at: 16rF5 + 1 put: 16r100 - 43.
			simulator memory at: 16rF6 + 1 put: 16r100 - 44.
			simulator memory at: 16rF7 + 1 put: 16r100 - 45.
			result := simulator call: 0 with: 16rE0 with: 0 with: 0 with: 0.
			self assert: result equals: 16r2D2C2B2A.
			self should: [simulator call: 0 with: 16rE1 with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rE2 with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rE3 with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rF0 with: 0 with: 0 with: 0.
			self assert: result equals: -16r2C2B2A2A.
			self should: [simulator call: 0 with: 16rF1 with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rF2 with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rF3 with: 0 with: 0 with: 0] raise: Error].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testLwNegativeOffset [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler lwR: V0 base: A0 offset: -4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  8C82FFFC  lw v0, -4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator memory at: 16rE4 + 1 put: 42.
			simulator memory at: 16rE5 + 1 put: 43.
			simulator memory at: 16rE6 + 1 put: 44.
			simulator memory at: 16rE7 + 1 put: 45.
			simulator memory at: 16rF4 + 1 put: 16r100 - 42.
			simulator memory at: 16rF5 + 1 put: 16r100 - 43.
			simulator memory at: 16rF6 + 1 put: 16r100 - 44.
			simulator memory at: 16rF7 + 1 put: 16r100 - 45.
			result := simulator call: 0 with: 16rE8 with: 0 with: 0 with: 0.
			self assert: result equals: 16r2D2C2B2A.
			self should: [simulator call: 0 with: 16rE9 with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rEA with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rEB with: 0 with: 0 with: 0] raise: Error.
			result := simulator call: 0 with: 16rF8 with: 0 with: 0 with: 0.
			self assert: result equals: -16r2C2B2A2A.
			self should: [simulator call: 0 with: 16rF9 with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rFA with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rFB with: 0 with: 0 with: 0] raise: Error].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testMult [
	"Strangely, objdump is unable to disassemble this sequence."	
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler multR: A0 R: A1).
			stream nextPut: (compiler mfloR: V0).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  00850018  mult a0, a1
00000004  00001012  mflo v0
00000008  03E00008  jr ra
0000000C  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 3 with: 5 with: 0 with: 0.
			self assert: result equals: 15.
			result := simulator call: 0 with: -3 with: 5 with: 0 with: 0.
			self assert: result equals: -15.
			result := simulator call: 0 with: 3 with: -5 with: 0 with: 0.
			self assert: result equals: -15.
			result := simulator call: 0 with: -3 with: -5 with: 0 with: 0.
			self assert: result equals: 15.
			result := simulator call: 0 with: 5 with: 3 with: 0 with: 0.
			self assert: result equals: 15.
			result := simulator call: 0 with: -5 with: 3 with: 0 with: 0.
			self assert: result equals: -15.
			result := simulator call: 0 with: 5 with: -3 with: 0 with: 0.
			self assert: result equals: -15.
			result := simulator call: 0 with: -5 with: -3 with: 0 with: 0.
			self assert: result equals: 15.
			result := simulator call: 0 with: 16r1000000 with: 16r4567 with: 0 with: 0.
			self assert: result equals: 16r67000000.
			result := simulator call: 0 with: 16r7FFFFFFF with: 16r7FFFFFFF with: 0 with: 0.
			self assert: result equals: 1].	
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler multR: A0 R: A1).
			stream nextPut: (compiler mfhiR: V0).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  00850018  mult a0, a1
00000004  00001010  mfhi v0
00000008  03E00008  jr ra
0000000C  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 3 with: 5 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -3 with: 5 with: 0 with: 0.
			self assert: result equals: -1.
			result := simulator call: 0 with: 3 with: -5 with: 0 with: 0.
			self assert: result equals: -1.
			result := simulator call: 0 with: -3 with: -5 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: 5 with: 3 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -5 with: 3 with: 0 with: 0.
			self assert: result equals: -1.
			result := simulator call: 0 with: 5 with: -3 with: 0 with: 0.
			self assert: result equals: -1.
			result := simulator call: 0 with: -5 with: -3 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: 16r1000000 with: 16r4567 with: 0 with: 0.
			self assert: result equals: 16r45.
			result := simulator call: 0 with: 16r7FFFFFFF with: 16r7FFFFFFF with: 0 with: 0.
			self assert: result equals:  16r3FFFFFFF].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testOr [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler orR: V0 R: A0 R: A1).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  00851025  or v0, a0, a1
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 2r101 with: 2r011 with: 0 with: 0.
			self assert: result equals: 2r111.
			result := simulator call: 0 with: -1 with: 42 with: 0 with: 0.
			self assert: result equals: -1].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testOri [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler oriR: V0 R: ZR C: 16rFFFF).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  3402FFFF  ori v0, zr, 65535
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: 16rFFFF].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testOriNegative [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler oriR: V0 R: ZR C: -42).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  3402FFD6  ori v0, zr, 65494
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0.
			self assert: result equals: 16r10000 - 42].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testPref [
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler prefR: A0 offset: 0 hint: HintLoad).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  CC800000  pref load, 0(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			"No exception even though the address is not part of memory."
			simulator call: 0 with: -42 with: 0 with: 0 with: 0].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testSb [
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sbR: A1 base: A0 offset: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  A0850004  sb a1, 4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator call: 0 with: 16rE0 with: 42 with: 0 with: 0.
			simulator call: 0 with: 16rE1 with: 43 with: 0 with: 0.
			simulator call: 0 with: 16rE2 with: 44 with: 0 with: 0.
			simulator call: 0 with: 16rE3 with: 45 with: 0 with: 0.
			simulator call: 0 with: 16rF0 with: -42 with: 0 with: 0.
			simulator call: 0 with: 16rF1 with: -43 with: 0 with: 0.
			simulator call: 0 with: 16rF2 with: -44 with: 0 with: 0.
			simulator call: 0 with: 16rF3 with: -45 with: 0 with: 0.
			self assert: (simulator memory at: 16rE4 + 1) equals: 42.
			self assert: (simulator memory at: 16rE5 + 1) equals: 43.
			self assert: (simulator memory at: 16rE6 + 1) equals: 44.
			self assert: (simulator memory at: 16rE7 + 1) equals: 45.
			self assert: (simulator memory at: 16rF4 + 1) equals: 16r100 - 42.
			self assert: (simulator memory at: 16rF5 + 1) equals: 16r100 - 43.
			self assert: (simulator memory at: 16rF6 + 1) equals: 16r100 - 44.
			self assert: (simulator memory at: 16rF7 + 1) equals: 16r100 - 45].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testSbNegativeOffset [
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sbR: A1 base: A0 offset: -4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  A085FFFC  sb a1, -4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator call: 0 with: 16rE8 with: 42 with: 0 with: 0.
			simulator call: 0 with: 16rE9 with: 43 with: 0 with: 0.
			simulator call: 0 with: 16rEA with: 44 with: 0 with: 0.
			simulator call: 0 with: 16rEB with: 45 with: 0 with: 0.
			simulator call: 0 with: 16rF8 with: -42 with: 0 with: 0.
			simulator call: 0 with: 16rF9 with: -43 with: 0 with: 0.
			simulator call: 0 with: 16rFA with: -44 with: 0 with: 0.
			simulator call: 0 with: 16rFB with: -45 with: 0 with: 0.
			self assert: (simulator memory at: 16rE4 + 1) equals: 42.
			self assert: (simulator memory at: 16rE5 + 1) equals: 43.
			self assert: (simulator memory at: 16rE6 + 1) equals: 44.
			self assert: (simulator memory at: 16rE7 + 1) equals: 45.
			self assert: (simulator memory at: 16rF4 + 1) equals: 16r100 - 42.
			self assert: (simulator memory at: 16rF5 + 1) equals: 16r100 - 43.
			self assert: (simulator memory at: 16rF6 + 1) equals: 16r100 - 44.
			self assert: (simulator memory at: 16rF7 + 1) equals: 16r100 - 45].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testSh [
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler shR: A1 base: A0 offset: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  A4850004  sh a1, 4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator call: 0 with: 16rE0 with: 16r2B2A with: 0 with: 0.
			self should: [simulator call: 0 with: 16rE1 with: 0 with: 0 with: 0] raise: Error.
			simulator call: 0 with: 16rE2 with: 16r2D2C with: 0 with: 0.
			self should: [simulator call: 0 with: 16rE3 with: 0 with: 0 with: 0] raise: Error.
			simulator call: 0 with: 16rF0 with: -16r2A2A with: 0 with: 0.
			self should: [simulator call: 0 with: 16rF1 with: 0 with: 0 with: 0] raise: Error.
			simulator call: 0 with: 16rF2 with: -16r2C2C with: 0 with: 0.
			self should: [simulator call: 0 with: 16rF3 with: 0 with: 0 with: 0] raise: Error.
			self assert: (simulator memory at: 16rE4 + 1) equals: 42.
			self assert: (simulator memory at: 16rE5 + 1) equals: 43.
			self assert: (simulator memory at: 16rE6 + 1) equals: 44.
			self assert: (simulator memory at: 16rE7 + 1) equals: 45.
			self assert: (simulator memory at: 16rF4 + 1) equals: 16r100 - 42.
			self assert: (simulator memory at: 16rF5 + 1) equals: 16r100 - 43.
			self assert: (simulator memory at: 16rF6 + 1) equals: 16r100 - 44.
			self assert: (simulator memory at: 16rF7 + 1) equals: 16r100 - 45].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testShNegativeOffset [
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler shR: A1 base: A0 offset: -4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  A485FFFC  sh a1, -4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator call: 0 with: 16rE8 with: 16r2B2A with: 0 with: 0.
			self should: [simulator call: 0 with: 16rE9 with: 0 with: 0 with: 0] raise: Error.
			simulator call: 0 with: 16rEA with: 16r2D2C with: 0 with: 0.
			self should: [simulator call: 0 with: 16rEB with: 0 with: 0 with: 0] raise: Error.
			simulator call: 0 with: 16rF8 with: -16r2A2A with: 0 with: 0.
			self should: [simulator call: 0 with: 16rF9 with: 0 with: 0 with: 0] raise: Error.
			simulator call: 0 with: 16rFA with: -16r2C2C with: 0 with: 0.
			self should: [simulator call: 0 with: 16rFB with: 0 with: 0 with: 0] raise: Error.
			self assert: (simulator memory at: 16rE4 + 1) equals: 42.
			self assert: (simulator memory at: 16rE5 + 1) equals: 43.
			self assert: (simulator memory at: 16rE6 + 1) equals: 44.
			self assert: (simulator memory at: 16rE7 + 1) equals: 45.
			self assert: (simulator memory at: 16rF4 + 1) equals: 16r100 - 42.
			self assert: (simulator memory at: 16rF5 + 1) equals: 16r100 - 43.
			self assert: (simulator memory at: 16rF6 + 1) equals: 16r100 - 44.
			self assert: (simulator memory at: 16rF7 + 1) equals: 16r100 - 45].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSll [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sllR: V0 R: A0 C: 2).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  00041080  sll v0, a0, 2
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 42 with: 0 with: 0 with: 0.
			self assert: result equals: 42 << 2.
			result := simulator call: 0 with: -42 with: 0 with: 0 with: 0.
			self assert: result equals: -42 << 2].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSllLarge [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sllR: V0 R: A0 C: 31).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  000417C0  sll v0, a0, 31
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: 42 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -42 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: 1 with: 0 with: 0 with: 0.
			self assert: result equals: -16r80000000.
			result := simulator call: 0 with: -1 with: 0 with: 0 with: 0.
			self assert: result equals: -16r80000000].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSllv [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sllvR: V0 R: A0 R: A1).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  00A41004  sllv v0, a0, a1
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 42 with: 2 with: 0 with: 0.
			self assert: result equals: 42 << 2.
			result := simulator call: 0 with: -42 with: 2 with: 0 with: 0.
			self assert: result equals: -42 << 2].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSlt [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sltR: V0 R: A0 R: A1).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  0085102A  slt v0, a0, a1
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 3 with: 4 with: 0 with: 0.
			self assert: result equals: 1.
			result := simulator call: 0 with: 4 with: 3 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -3 with: 4 with: 0 with: 0.
			self assert: result equals: 1.
			result := simulator call: 0 with: 4 with: -3 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: 5 with: 5 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -5 with: -5 with: 0 with: 0.
			self assert: result equals: 0].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSlti [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sltiR: V0 R: A0 C: 3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  28820003  slti v0, a0, 3
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 3 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: 4 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -3 with: 0 with: 0 with: 0.
			self assert: result equals: 1].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSltiNegative [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sltiR: V0 R: A0 C: -3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  2882FFFD  slti v0, a0, -3
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 3 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: 4 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -3 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -4 with: 0 with: 0 with: 0.
			self assert: result equals: 1].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSltiu [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sltiuR: V0 R: A0 C: 3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  2C820003  sltiu v0, a0, 3
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 2 with: 0 with: 0 with: 0.
			self assert: result equals: 1.
			result := simulator call: 0 with: 3 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: 4 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -3 with: 0 with: 0 with: 0.
			self assert: result equals: 0].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSltiuNegative [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sltiuR: V0 R: A0 C: -3).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  2C82FFFD  sltiu v0, a0, -3
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 2 with: 0 with: 0 with: 0.
			self assert: result equals: 1.
			result := simulator call: 0 with: 3 with: 0 with: 0 with: 0.
			self assert: result equals: 1.
			result := simulator call: 0 with: 4 with: 0 with: 0 with: 0.
			self assert: result equals: 1.
			result := simulator call: 0 with: -2 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -3 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -4 with: 0 with: 0 with: 0.
			self assert: result equals: 1].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSltu [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sltuR: V0 R: A0 R: A1).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  0085102B  sltu v0, a0, a1
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 3 with: 4 with: 0 with: 0.
			self assert: result equals: 1.
			result := simulator call: 0 with: 4 with: 3 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -3 with: 4 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: 4 with: -3 with: 0 with: 0.
			self assert: result equals: 1.
			result := simulator call: 0 with: 5 with: 5 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -5 with: -5 with: 0 with: 0.
			self assert: result equals: 0].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSra [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sraR: V0 R: A0 C: 2).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  00041083  sra v0, a0, 2
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 42 with: 0 with: 0 with: 0.
			self assert: result equals: 42 >> 2.
			result := simulator call: 0 with: -42 with: 0 with: 0 with: 0.
			self assert: result equals: -42 >> 2].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSraLarge [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sraR: V0 R: A0 C: 31).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  000417C3  sra v0, a0, 31
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: 42 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -42 with: 0 with: 0 with: 0.
			self assert: result equals: -1].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSrav [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler sravR: V0 R: A0 R: A1).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  00A41007  srav v0, a0, a1
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 42 with: 2 with: 0 with: 0.
			self assert: result equals: 42 >> 2.
			result := simulator call: 0 with: -42 with: 2 with: 0 with: 0.
			self assert: result equals: -42 >> 2].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSrl [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler srlR: V0 R: A0 C: 2).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  00041082  srl v0, a0, 2
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 42 with: 0 with: 0 with: 0.
			self assert: result equals: 42 >> 2.
			result := simulator call: 0 with: -42 with: 0 with: 0 with: 0.
			self assert: result equals: (16r100000000 - 42) >> 2].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSrlLarge [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler srlR: V0 R: A0 C: 31).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  000417C2  srl v0, a0, 31
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: 42 with: 0 with: 0 with: 0.
			self assert: result equals: 0.
			result := simulator call: 0 with: -42 with: 0 with: 0 with: 0.
			self assert: result equals: 1].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSrlv [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler srlvR: V0 R: A0 R: A1).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  00A41006  srlv v0, a0, a1
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 42 with: 2 with: 0 with: 0.
			self assert: result equals: 42 >> 2.
			result := simulator call: 0 with: -42 with: 2 with: 0 with: 0.
			self assert: result equals: (16r100000000 - 42) >> 2].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testSubu [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler subuR: V0 R: A0 R: A1).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  00851023  subu v0, a0, a1
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 3 with: 4 with: 0 with: 0.
			self assert: result equals: -1.
			result := simulator call: 0 with: 3 with: -4 with: 0 with: 0.
			self assert: result equals: 7.
			result := simulator call: 0 with: -3 with: 4 with: 0 with: 0.
			self assert: result equals: -7.
			result := simulator call: 0 with: 16r7FFFFFFF with: -1 with: 0 with: 0.
			self assert: result equals: (-1 << 31).
			result := simulator call: 0 with: (-1 << 31) with: 1 with: 0 with: 0.
			self assert: result equals: (1 << 31) - 1].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testSw [
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler swR: A1 base: A0 offset: 4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  AC850004  sw a1, 4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator call: 0 with: 16rE0 with: 16r2D2C2B2A with: 0 with: 0.
			self should: [simulator call: 0 with: 16rE1 with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rE2 with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rE3 with: 0 with: 0 with: 0] raise: Error.
			simulator call: 0 with: 16rF0 with: -16r2C2B2A2A with: 0 with: 0.
			self should: [simulator call: 0 with: 16rF1 with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rF2 with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rF3 with: 0 with: 0 with: 0] raise: Error.
			self assert: (simulator memory at: 16rE4 + 1) equals: 42.
			self assert: (simulator memory at: 16rE5 + 1) equals: 43.
			self assert: (simulator memory at: 16rE6 + 1) equals: 44.
			self assert: (simulator memory at: 16rE7 + 1) equals: 45.
			self assert: (simulator memory at: 16rF4 + 1) equals: 16r100 - 42.
			self assert: (simulator memory at: 16rF5 + 1) equals: 16r100 - 43.
			self assert: (simulator memory at: 16rF6 + 1) equals: 16r100 - 44.
			self assert: (simulator memory at: 16rF7 + 1) equals: 16r100 - 45].
]

{ #category : #'tests - memory' }
MIPSELSimulatorTests >> testSwNegativeOffset [
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler swR: A1 base: A0 offset: -4).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  AC85FFFC  sw a1, -4(a0)
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			simulator call: 0 with: 16rE8 with: 16r2D2C2B2A with: 0 with: 0.
			self should: [simulator call: 0 with: 16rE9 with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rEA with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rEB with: 0 with: 0 with: 0] raise: Error.
			simulator call: 0 with: 16rF8 with: -16r2C2B2A2A with: 0 with: 0.
			self should: [simulator call: 0 with: 16rF9 with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rFA with: 0 with: 0 with: 0] raise: Error.
			self should: [simulator call: 0 with: 16rFB with: 0 with: 0 with: 0] raise: Error.
			self assert: (simulator memory at: 16rE4 + 1) equals: 42.
			self assert: (simulator memory at: 16rE5 + 1) equals: 43.
			self assert: (simulator memory at: 16rE6 + 1) equals: 44.
			self assert: (simulator memory at: 16rE7 + 1) equals: 45.
			self assert: (simulator memory at: 16rF4 + 1) equals: 16r100 - 42.
			self assert: (simulator memory at: 16rF5 + 1) equals: 16r100 - 43.
			self assert: (simulator memory at: 16rF6 + 1) equals: 16r100 - 44.
			self assert: (simulator memory at: 16rF7 + 1) equals: 16r100 - 45].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testXor [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler xorR: V0 R: A0 R: A1).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  00851026  xor v0, a0, a1
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 2r101 with: 2r011 with: 0 with: 0.
			self assert: result equals: 2r110.
			result := simulator call: 0 with: -1 with: 42 with: 0 with: 0.
			self assert: result equals: 42 bitInvert].
]

{ #category : #'tests - arithmetic' }
MIPSELSimulatorTests >> testXori [
	| result |
	self 
		testGenerateInto: 
			[:stream :compiler | 
			stream nextPut: (compiler xoriR: V0 R: A0 C: 16rABCD).
			stream nextPut: (compiler jR: RA).
			stream nextPut: (compiler nop). "Delay slot"]
		disassembly:
'00000000  3882ABCD  xori v0, a0, 43981
00000004  03E00008  jr ra
00000008  00000000  nop
'		run: 
			[:simulator | 
			result := simulator call: 0 with: 0 with: 0 with: 0 with: 0.
			self assert: result equals: 16rABCD.
			result := simulator call: 0 with: -1 with: 0 with: 0 with: 0.
			self assert: result equals: -16rABCE].
]
