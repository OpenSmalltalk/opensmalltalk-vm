Class {
	#name : #GdbARMAlienTests,
	#superclass : #TestCase,
	#instVars : [
		'processor'
	],
	#category : #'Cog-Processors-Tests'
}

{ #category : #accessing }
GdbARMAlienTests >> integerRegisterGetters [
	^#(r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 sl fp r12 lr sp pc)
]

{ #category : #accessing }
GdbARMAlienTests >> integerRegisterSetters [
	^#(r0: r1: r2: r3: r4: r5: r6: r7: r8: r9: r10: fp: r12: lr: sp: pc:)
]

{ #category : #accessing }
GdbARMAlienTests >> memory [ 
"build a memory for this test; a ByteArray of 1024 bytes, filled with NOPs"
	| mem nop|
	nop := CogARMCompiler new mov: 0  rn: 0.
	mem := ByteArray new: 1024.
	1 to: 1024  by: 4do:[:i|
		mem unsignedLongAt: i put: nop bigEndian: false].
	^mem
]

{ #category : #accessing }
GdbARMAlienTests >> nfib [
	"long fib(long n) { return n <= 1 ? 1 : fib(n-1) + fib(n-2) + 1; }
	 as compiled by arm-elf-gnuabi-gcc fib.c -c -marm
	also, the jumps are changed by hand."
	"| bat nfib ip |
	bat := GdbARMAlienTests new.
	nfib := bat nfib asWordArray.
	ip := 0.
	23 timesRepeat:
		[bat processor disassembleInstructionAt: ip In: nfib into:
			[:da :len|
			Transcript nextPutAll: da; cr; flush.
			ip := ip + len]]"
	^#("00000000 <fib>:
	   0:"		16re92d4810 		"push	{r4, fp, lr}	fp = r11, sp is changed in this command
	   4:"		16re28db008 		"add	fp, sp, #8	now, the frame pointer is changed
	   8:"		16re24dd00c 		"sub	sp, sp, #12
	   c:"		16re50b0010 		"str	r0, [fp, #-16]
	  10:"		16re51b3010 		"ldr	r3, [fp, #-16]	r3 <- [fp-16] <- r0
	  14:"		16re3530001 		"cmp	r3, #1
	  18:"		16rda00000c 		"ble	50 <fib+0x50>
	  1c:"		16re51b3010 		"ldr	r3, [fp, #-16]
	  20:"		16re2433001 		"sub	r3, r3, #1
	  24:"		16re1a00003 		"mov	r0, r3
	  28:"		16rebfffff4 		"bl	0 <fib>
	  2c:"		16re1a04000 		"mov	r4, r0
	  30:"		16re51b3010 		"ldr	r3, [fp, #-16]
	  34:"		16re2433002	 	"sub	r3, r3, #2
	  38:"		16re1a00003 		"mov	r0, r3
	  3c:"		16rebffffef 		"bl	0 <fib>
	  40:"		16re1a03000 		"mov	r3, r0
	  44:"		16re0843003 		"add	r3, r4, r3
	  48:"		16re2833001 		"add	r3, r3, #1
	  4c:"		16rea000000 		"b	54 <fib+0x54>
	  50:"		16re3a03001 		"mov	r3, #1
	  54:"		16re1a00003 		"mov	r0, r3
	  58:"		16re24bd008 		"sub	sp, fp, #8
	  5c:"		16re8bd8810 		"pop	{r4, fp, pc}")
]

{ #category : #accessing }
GdbARMAlienTests >> processor [
	processor ifNil:
		[processor := GdbARMAlien new].
	^processor
]

{ #category : #execution }
GdbARMAlienTests >> runNFib: n disassemble: disassemble printRegisters: printRegisters [
	"Run nfib wth the argument. Answer the result."
	"self new runNFib: 5 disassemble: true printRegisters: true"
	| memory |
	memory := Bitmap new: 1024 * 2 withAll: self processor nopOpcode.
	memory replaceFrom: 1 to: self nfib size with: self nfib asWordArray startingAt: 1.
	self processor
		r0: n;"argument n"
		lr: memory size * 2; "return address"
		pc: 0;
		sp: (memory size * 4) - 16.
	printRegisters ifTrue:
		[self processor printRegistersOn: Transcript.
		 Transcript cr; flush].
	"run until something goes wrong."
	self processor runInMemory: memory readExecuteOnlyBelow: memory size / 2.
	printRegisters ifTrue:
		[self processor printRegistersOn: Transcript.
		 Transcript cr; flush].
	^self processor r0
]

{ #category : #execution }
GdbARMAlienTests >> singleStepNFib: n disassemble: disassemble printRegisters: printRegisters [
	"Run nfib wth the argument. Answer the result."
	"self new runNFib: 5 disassemble: true printRegisters: true"
	| memory |
	memory := WordArray new: 1024 * 2 withAll: self processor nopOpcode.
	memory replaceFrom: 1 to: self nfib size with: self nfib asWordArray startingAt: 1.
	self processor
		r0: n; "argument n"
		lr: self nfib size * 4;  "return address"
		pc: 0;
		sp: (memory size * 4 - 12). "Room for return address, frame pointer and r4"
	printRegisters ifTrue:
		[self processor printRegistersOn: Transcript.
		 Transcript cr; flush].
	[disassemble ifTrue:
		[Transcript nextPutAll: (self processor disassembleNextInstructionIn: memory); cr; flush].
	 self processor singleStepIn: memory readExecuteOnlyBelow: memory size * 4 / 2.
	 printRegisters ifTrue:
		[self processor printRegistersOn: Transcript.
		 Transcript cr; flush].
	"stop, once we leave the nfib code and step through the nops after that."
	 self processor pc < (self nfib size * 4)] whileTrue.
	^self processor r0
]

{ #category : #tests }
GdbARMAlienTests >> testCall [
	"Call a function that is in-range."
	
	"self new testCall"
	| memory |
	memory := self memory.
	self processor reset.

	memory unsignedLongAt: 5 put: (CogARMCompiler new mov: 10 imm: 0 ror: 0)  bigEndian: false. 
	memory unsignedLongAt: 9 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false.
	memory unsignedLongAt: 13 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false. 
	memory unsignedLongAt: 17 put: (CogARMCompiler new orr: 10 imm: 40 ror: 0) bigEndian: false. 

	memory unsignedLongAt: 21 put: (CogARMCompiler new bl: 12) bigEndian: false.

	memory unsignedLongAt: 25 put: (CogARMCompiler new mov:5imm: 99 ror:0 ) bigEndian: false.
	memory unsignedLongAt: 41 put: (CogARMCompiler new mov: 4 imm: 42 ror: 0) bigEndian: false.
	memory unsignedLongAt: 45 put: (CogARMCompiler new bx: 14) bigEndian: false.
	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory.
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self processor singleStepIn: memory.
	self processor singleStepIn: memory.
	self processor singleStepIn: memory.
	self assert: processor pc = 16r14.
	self processor singleStepIn: memory.
	self assert: processor pc = 16r28 "check the call".
	self processor singleStepIn: memory.
	self assert: processor r4 = 42.
	self processor singleStepIn: memory.
	self processor singleStepIn: memory.

	self assert: self processor pc = 16r1C.
	self assert: self processor lr = 16r18.
	self assert: self processor r5 = 99

]

{ #category : #tests }
GdbARMAlienTests >> testCallTrap [
	"Call a function that is out-of-range.  Ensure the call is trapped."
	"self new testCallTrap"
	| memory |
	memory := self memory.
	memory unsignedLongAt: 5 put: (CogARMCompiler new bl: 1020) bigEndian: false.
	"Can't do this diassemble until after the #asByteArray - "
	"processor disassembleFrom: 0 to:16 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory.
			"We have to step twice, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self should: [self processor singleStepIn: memory]
		raise: ProcessorSimulationTrap
		withExceptionDo:
			[:pst|
			self assert: self processor pc = 4.
			self assert: self processor lr = 8.
			self assert: pst pc = 4.
			self assert: pst nextpc = 8.
			self assert: pst address = 1032.
			self assert: pst type = #call].
]

{ #category : #tests }
GdbARMAlienTests >> testCallTrap2 [
	"Call a function that is out-of-range.  Ensure the call is trapped
	This version calls well outside the memory array."
	"self new testCallTrap2"
	| memory |
	memory := self memory.
	memory unsignedLongAt: 5 put: (CogARMCompiler new bl: 16rFF00) bigEndian: false.
	"Can't do this diassemble until after the #asByteArray - "
	"processor disassembleFrom: 0 to:16 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory.
			"We have to step twice, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self should: [self processor singleStepIn: memory]
		raise: ProcessorSimulationTrap
		withExceptionDo:
			[:pst|
			self assert: self processor pc = 16r4.
			self assert: self processor lr = 8.
			self assert: pst pc = 4.
			self assert: pst nextpc = 8.
			self assert: pst address  = 16rFF0C.
			self assert: pst type = #call].
]

{ #category : #tests }
GdbARMAlienTests >> testCallTrap3 [
	"Call a function that is out-of-range.  Ensure the call is trapped
	This version calls well outside the memory array negatively"
	"self new testCallTrap3"
	| memory |
	memory := self memory.
	memory unsignedLongAt: 5 put: (CogARMCompiler new bl: -16rFF00) bigEndian: false.
	"Can't do this diassemble until after the #asByteArray - "
	"processor disassembleFrom: 0 to:16 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory.
			"We have to step twice, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self should: [self processor singleStepIn: memory]
		raise: ProcessorSimulationTrap
		withExceptionDo:
			[:pst|
			self assert: self processor pc = 16r4.
			self assert: self processor lr = 8.
			self assert: pst pc = 4.
			self assert: pst nextpc = 8.
			self assert: pst address  = 16rFFFF010C.
			self assert: pst type = #call].
]

{ #category : #tests }
GdbARMAlienTests >> testDisassembling [
	"self new testDisassembling"

	| memory result |
	memory := WordArray new: 2.
	memory at: 1 put:  (CogARMCompiler new add: 15 rn: 10 imm: 100 ror:0).
	result := self processor
		disassembleInstructionAt: 0 
		In: memory 
		into: [:str :len | 
			self 
				assert: len = 4;
				assert: str = '00000000: add	pc, sl, #100	; 0x64'].
]

{ #category : #tests }
GdbARMAlienTests >> testExecutionTrap [
	"Execute a run of nops.  test executing beyond the executable limit is trapped."
	"self new testExecutionTrap"
	| memory |
	 "Run through NOPs until we hit the limit set by readOnlyBelow: "
	memory := (Bitmap new: 1024 * 2 withAll: self processor nopOpcode) asByteArray.
	self processor
			pc: 0;
			sp: (memory size - 4). "Room for return address"
	self should: [self processor runInMemory: memory minimumAddress: 0 readOnlyBelow: memory size / 2]
		raise: Error
		withExceptionDo:
			[:err|
			self assert: self processor pc = (memory size / 2-4).
			self assert: ('Error 0: Illegal Instruction fetch address (0x1000).' match: err messageText)].
	self processor reset;  pc: 0.
	self should: [[self processor singleStepIn: memory minimumAddress: 0 readOnlyBelow: memory size / 2] repeat]
		raise: Error
		withExceptionDo:
			[:err|
			self assert: self processor pc = (memory size / 2- 4).
			self assert: ('Error 0: Illegal Instruction fetch address (0x1000).' match: err messageText)]
]

{ #category : #tests }
GdbARMAlienTests >> testFlags [
"test the processor flag state reading and setting"
	"self new testFlags"
	| memory |
	memory := Bitmap new: 5.
	self processor reset.
	memory longAt: 1 put: 16rE3A03001 bigEndian: false. "MOV r3, #1"
	memory longAt: 5 put: 16rE3530001 bigEndian: false. "CMP r3, #1"
	memory longAt: 9 put: 16r13A00003 bigEndian: false. "MOVNE r0, #3"
	memory longAt: 13 put: 16r03A00005 bigEndian: false. "MOVEQ r0, #5"
	memory := memory asByteArray.
	self processor
		disassembleInstructionAt: 0 
		In: memory 
		into: [:str :len | 
			self 
				assert: len = 4;
				assert: str equals: '00000000: mov	r3, #1'].
	self processor
		disassembleInstructionAt: 4 
		In: memory 
		into: [:str :len | 
			self 
				assert: len = 4;
				assert: str equals: '00000004: cmp	r3, #1'].
	self processor
		disassembleInstructionAt: 8 
		In: memory 
		into: [:str :len | 
			self 
				assert: len = 4;
				assert: str equals: '00000008: movne	r0, #3'].
	self processor
		disassembleInstructionAt: 12 
		In: memory 
		into: [:str :len | 
			self 
				assert: len = 4;
				assert: str equals: '0000000c: moveq	r0, #5'].
	self processor
		pc: 0;
		singleStepIn: memory;
		singleStepIn: memory;
		singleStepIn: memory;
		assert: self processor r0 = 0;
		singleStepIn: memory.
	self 
		assert: self processor pc = 16;
		assert: self processor r3 = 1;
		assert: self processor r0 = 5;
		assert: self processor zflag = 1;
		assert: self processor cflag = 1;
		assert: self processor vflag = 0;
		assert: self processor nflag = 0.
	self processor reset.
	self assert: self processor eflags = 3. "IFFlags are both set."
]

{ #category : #tests }
GdbARMAlienTests >> testJump [
	"Jump in-range."
	
	"self new testJump"
	| memory |
	memory := self memory.
	self processor reset.

	memory unsignedLongAt: 5 put: (CogARMCompiler new mov: 10 imm: 0 ror: 0)  bigEndian: false. 
	memory unsignedLongAt: 9 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false.
	memory unsignedLongAt: 13 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false. 
	memory unsignedLongAt: 17 put: (CogARMCompiler new orr: 10 imm: 40 ror: 0) bigEndian: false. 

	memory unsignedLongAt: 21 put: (CogARMCompiler new b: 12) bigEndian: false.

	memory unsignedLongAt: 25 put: (CogARMCompiler new mov:5imm: 99 ror:0 ) bigEndian: false.
	memory unsignedLongAt: 41 put: (CogARMCompiler new mov: 4 imm: 42 ror: 0) bigEndian: false.
	memory unsignedLongAt: 45 put: (CogARMCompiler new bx: 14) bigEndian: false.
	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory.
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self processor singleStepIn: memory.
	self processor singleStepIn: memory.
	self processor singleStepIn: memory.
	self assert: processor pc = 16r14.
	self processor singleStepIn: memory.
	self assert: processor pc = 16r28 "check the call".
	self processor singleStepIn: memory.
	self assert: processor r4= 42.

]

{ #category : #tests }
GdbARMAlienTests >> testJumpTrap [
	"Jump a function that is out-of-range.  Ensure the call is trapped."
	"self new testJumpTrap"
	| memory |
	memory := self memory.
	memory unsignedLongAt: 5 put: (CogARMCompiler new b: 1020) bigEndian: false.
	"Can't do this diassemble until after the #asByteArray - "
	"processor disassembleFrom: 0 to:16 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory.
			"We have to step twice, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self should: [self processor singleStepIn: memory]
		raise: ProcessorSimulationTrap
		withExceptionDo:
			[:pst|
			self assert: self processor pc = 4.
			self assert: self processor lr = 0.
			self assert: pst pc = 4.
			self assert: pst nextpc = 8.
			self assert: pst address = 1032.
			self assert: pst type = #jump].
]

{ #category : #tests }
GdbARMAlienTests >> testLongCall [
	"Long-Call a function that is in-range."
	
	"self new testLongCall"
	| memory |
	memory := self memory.
	self processor reset.

	memory unsignedLongAt: 5 put: (CogARMCompiler new mov: 10 imm: 0 ror: 0)  bigEndian: false. 
	memory unsignedLongAt: 9 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false.
	memory unsignedLongAt: 13 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false. 
	memory unsignedLongAt: 17 put: (CogARMCompiler new orr: 10 imm: 40 ror: 0) bigEndian: false. 

	memory unsignedLongAt: 21 put: (CogARMCompiler new blx: 10) bigEndian: false.

	memory unsignedLongAt: 25 put: (CogARMCompiler new mov:5imm: 99 ror:0 ) bigEndian: false.
	memory unsignedLongAt: 41 put: (CogARMCompiler new mov: 4 imm: 42 ror: 0) bigEndian: false.
	memory unsignedLongAt: 45 put: (CogARMCompiler new bx: 14) bigEndian: false.
	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory.
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self processor singleStepIn: memory.
	self processor singleStepIn: memory.
	self processor singleStepIn: memory.
	self assert: processor pc = 16r14.
	self processor singleStepIn: memory.
	self assert: processor pc = 16r28 "check the call".
	self processor singleStepIn: memory.
	self assert: processor r4 = 42.
	self processor singleStepIn: memory.
	self processor singleStepIn: memory.

	self assert: self processor pc = 16r1C.
	self assert: self processor lr = 16r18.
	self assert: self processor r5 = 99

]

{ #category : #tests }
GdbARMAlienTests >> testLongCallTrap [
	"Long-Call a function that is above-range."
	
	"self new testLongCallTrap"
	| memory |
	memory := self memory.
	self processor reset.

	memory unsignedLongAt: 5 put: (CogARMCompiler new mov: 10 imm: 0 ror: 0)  bigEndian: false. 
	memory unsignedLongAt: 9 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false.
	memory unsignedLongAt: 13 put: (CogARMCompiler new orr: 10 imm: 4 ror: 24) bigEndian: false. 
	memory unsignedLongAt: 17 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false. 

	memory unsignedLongAt: 21 put: (CogARMCompiler new blx: 10) bigEndian: false.

	memory unsignedLongAt: 25 put: (CogARMCompiler new mov:5imm: 99 ror:0 ) bigEndian: false.
	memory unsignedLongAt: 41 put: (CogARMCompiler new mov: 4 imm: 42 ror: 0) bigEndian: false.
	memory unsignedLongAt: 45 put: (CogARMCompiler new bx: 14) bigEndian: false.
	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory.
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self should: [self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory]
		raise: ProcessorSimulationTrap
		withExceptionDo:
			[:pst|
			self assert: self processor pc = 16r14.
			self assert: self processor lr = 16r18.
			self assert: pst pc = 16r14.
			self assert: pst nextpc = 16r18.
			self assert: pst address = 1024.
			self assert: pst type = #call].
]

{ #category : #tests }
GdbARMAlienTests >> testLongCallTrap2 [
	"Long-Call a function that is way outside range."
	
	"self new testLongCallTrap2"
	| memory |
	memory := self memory.
	self processor reset.

	memory unsignedLongAt: 5 put: (CogARMCompiler new mov: 10 imm: 16rFF ror: 8)  bigEndian: false. 
	memory unsignedLongAt: 9 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false.
	memory unsignedLongAt: 13 put: (CogARMCompiler new orr: 10 imm: 4 ror: 24) bigEndian: false. 
	memory unsignedLongAt: 17 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false. 

	memory unsignedLongAt: 21 put: (CogARMCompiler new blx: 10) bigEndian: false.

	memory unsignedLongAt: 25 put: (CogARMCompiler new mov:5imm: 99 ror:0 ) bigEndian: false.
	memory unsignedLongAt: 41 put: (CogARMCompiler new mov: 4 imm: 42 ror: 0) bigEndian: false.
	memory unsignedLongAt: 45 put: (CogARMCompiler new bx: 14) bigEndian: false.
	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory.
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self should: [self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory]
		raise: ProcessorSimulationTrap
		withExceptionDo:
			[:pst|
			self assert: self processor pc = 16r14.
			self assert: self processor lr = 16r18.
			self assert: pst pc = 16r14.
			self assert: pst nextpc = 16r18.
			self assert: pst address = 16rFF000400.
			self assert: pst type = #call].
]

{ #category : #tests }
GdbARMAlienTests >> testLongJump [
	"Jump in-range."
	
	"self new testLongJump"
	| memory |
	memory := self memory.
	self processor reset.

	memory unsignedLongAt: 5 put: (CogARMCompiler new mov: 10 imm: 0 ror: 0)  bigEndian: false. 
	memory unsignedLongAt: 9 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false.
	memory unsignedLongAt: 13 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false. 
	memory unsignedLongAt: 17 put: (CogARMCompiler new orr: 10 imm: 40 ror: 0) bigEndian: false. 

	memory unsignedLongAt: 21 put: (CogARMCompiler new bx: 10) bigEndian: false.

	memory unsignedLongAt: 25 put: (CogARMCompiler new mov:5imm: 99 ror:0 ) bigEndian: false.
	memory unsignedLongAt: 41 put: (CogARMCompiler new mov: 4 imm: 42 ror: 0) bigEndian: false.
	memory unsignedLongAt: 45 put: (CogARMCompiler new bx: 14) bigEndian: false.
	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory.
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self processor singleStepIn: memory.
	self processor singleStepIn: memory.
	self processor singleStepIn: memory.
	self assert: processor pc = 16r14.
	self processor singleStepIn: memory.
	self assert: processor pc = 16r28 "check the call".
	self processor singleStepIn: memory.
	self assert: processor r4= 42.

]

{ #category : #tests }
GdbARMAlienTests >> testLongJumpAddressForming [
	"self new testLongJumpAddressForming"
	"test of the somewhat loopy code used in CogARMCompiler>concretizeConditionalJumpLong: to generate the oading of a long address for jumps"
	| memory |
	memory := self memory.
	self processor reset.
	memory unsignedLongAt: 1 put: (CogARMCompiler new mov: 10 imm: 16r7F ror: 8)  bigEndian: false. 
	memory unsignedLongAt: 5 put: (CogARMCompiler new orr: 10 imm: 16rFF ror: 16) bigEndian: false.
	memory unsignedLongAt: 9 put: (CogARMCompiler new orr: 10 imm: 16rFE ror: 24) bigEndian: false. 
	memory unsignedLongAt: 13 put: (CogARMCompiler new orr: 10 imm: 16r68 ror: 0) bigEndian: false. 

	self processor
		disassembleInstructionAt: 0 
		In: memory 
		into: [:str :len | 
			self 
				assert: len = 4;
				assert: str equals: '00000000: mov	sl, #2130706432	; 0x7f000000'].
	self processor
		disassembleInstructionAt: 4 
		In: memory 
		into: [:str :len | 
			self 
				assert: len = 4;
				assert: str equals: '00000004: orr	sl, sl, #16711680	; 0xff0000'].
	self processor
		disassembleInstructionAt: 8 
		In: memory 
		into: [:str :len | 
			self 
				assert: len = 4;
				assert: str equals: '00000008: orr	sl, sl, #65024	; 0xfe00'].
	self processor
		disassembleInstructionAt: 12 
		In: memory 
		into: [:str :len | 
			self 
				assert: len = 4;
				assert: str equals: '0000000c: orr	sl, sl, #104	; 0x68'].
	self processor
		pc: 0;
		singleStepIn: memory;
		singleStepIn: memory;
		singleStepIn: memory;
		singleStepIn: memory.
	self 
		assert: self processor pc = 16;
		assert: self processor sl = 16r7FFFFE68;
		assert: self processor zflag = 0;
		assert: self processor cflag = 0;
		assert: self processor vflag = 0;
		assert: self processor nflag = 0.

]

{ #category : #tests }
GdbARMAlienTests >> testLongJumpTrap [
	"Long-Jump a function that is above-range."
	
	"self new testLongJumpTrap"
	| memory |
	memory := self memory.
	self processor reset.

	memory unsignedLongAt: 5 put: (CogARMCompiler new mov: 10 imm: 0 ror: 0)  bigEndian: false. 
	memory unsignedLongAt: 9 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false.
	memory unsignedLongAt: 13 put: (CogARMCompiler new orr: 10 imm: 4 ror: 24) bigEndian: false. 
	memory unsignedLongAt: 17 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false. 

	memory unsignedLongAt: 21 put: (CogARMCompiler new bx: 10) bigEndian: false.

	memory unsignedLongAt: 25 put: (CogARMCompiler new mov:5imm: 99 ror:0 ) bigEndian: false.
	memory unsignedLongAt: 41 put: (CogARMCompiler new mov: 4 imm: 42 ror: 0) bigEndian: false.
	memory unsignedLongAt: 45 put: (CogARMCompiler new bx: 14) bigEndian: false.
	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory.
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self should: [self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory.
				self processor singleStepIn: memory]
		raise: ProcessorSimulationTrap
		withExceptionDo:
			[:pst|
			self assert: self processor pc = 16r14.
			self assert: pst pc = 16r14.
			self assert: pst nextpc = 16r18.
			self assert: pst address = 1024.
			self assert: pst type =  #jump].
]

{ #category : #tests }
GdbARMAlienTests >> testMoveAwR [
	"Read a register from a constant address that is in-range."
	
	"self new testMoveAwR"
	| memory |
	memory := self memory.
	self processor reset.

	"LEA sl, #16r228"
	memory unsignedLongAt: 5 put: (CogARMCompiler new mov: 10 imm: 0 ror: 0)  bigEndian: false. 
	memory unsignedLongAt: 9 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false.
	memory unsignedLongAt: 13 put: (CogARMCompiler new orr: 10 imm: 2 ror: 24) bigEndian: false. 
	memory unsignedLongAt: 17 put: (CogARMCompiler new orr: 10 imm: 40 ror: 0) bigEndian: false. 
	"LDR R5, [sl]"
	memory unsignedLongAt: 21 put: (CogARMCompiler new ldr: 5 rn: 10 plusImm: 0) bigEndian: false.

	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	memory unsignedLongAt: 16r228 + 1 put: 99.
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
	self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
	self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
	self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
	self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
	self assert:[processor r5 = 99]

]

{ #category : #tests }
GdbARMAlienTests >> testMoveAwRTrap1 [
	"Read from a register at a constant address that is out-of--range."
	
	"self new testMoveAwRTrap1"
	| memory |
	memory := self memory.
	self processor reset.

	"LEA sl, #16rFF00001FC"
	memory unsignedLongAt: 5 put: (CogARMCompiler new mov: 10 imm: 16rFF ror: 8)  bigEndian: false. 
	memory unsignedLongAt: 9 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false.
	memory unsignedLongAt: 13 put: (CogARMCompiler new orr: 10 imm: 1 ror: 24) bigEndian: false. 
	memory unsignedLongAt: 17 put: (CogARMCompiler new orr: 10 imm: 16rFC ror: 0) bigEndian: false. 
	"STR R5, [sl]"
	memory unsignedLongAt: 21 put: (CogARMCompiler new ldr: 5 rn: 10 plusImm: 0) bigEndian: false.

	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	
	self should: [self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2]
		raise: ProcessorSimulationTrap
		withExceptionDo:
			[:pst|
			self assert: self processor pc = 16r14.
			self assert: pst pc = 16r14.
			self assert: pst nextpc = 16r18.
			self assert: pst address = 16rFF0001FC.
			self assert: pst type = #read]
]

{ #category : #tests }
GdbARMAlienTests >> testMoveRAw [
	"Write a register to a constant address that is in-range."
	
	"self new testMoveRAw"
	| memory |
	memory := self memory.
	self processor reset.

	"LEA sl, #16r3FC"
	memory unsignedLongAt: 5 put: (CogARMCompiler new mov: 10 imm: 0 ror: 0)  bigEndian: false. 
	memory unsignedLongAt: 9 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false.
	memory unsignedLongAt: 13 put: (CogARMCompiler new orr: 10 imm: 2 ror: 24) bigEndian: false. 
	memory unsignedLongAt: 17 put: (CogARMCompiler new orr: 10 imm: 40 ror: 0) bigEndian: false. 
	"STR R5, [sl]"
	memory unsignedLongAt: 21 put: (CogARMCompiler new str: 5 rn: 10 plusImm: 0) bigEndian: false.

	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			r5: 99;
			singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
	self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
	self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
	self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
	self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
	self assert:[(memory unsignedLongAt: (processor sl) + 1) = processor r5]

]

{ #category : #tests }
GdbARMAlienTests >> testMoveRAwTrap1 [
	"Write a register to a constant address that is below-range."
	
	"self new testMoveRAwTrap1"
	| memory |
	memory := self memory.
	self processor reset.

	"LEA sl, #16r1FC"
	memory unsignedLongAt: 5 put: (CogARMCompiler new mov: 10 imm: 0 ror: 0)  bigEndian: false. 
	memory unsignedLongAt: 9 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false.
	memory unsignedLongAt: 13 put: (CogARMCompiler new orr: 10 imm: 1 ror: 24) bigEndian: false. 
	memory unsignedLongAt: 17 put: (CogARMCompiler new orr: 10 imm: 16rFC ror: 0) bigEndian: false. 
	"STR R5, [sl]"
	memory unsignedLongAt: 21 put: (CogARMCompiler new str: 5 rn: 10 plusImm: 0) bigEndian: false.

	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			r5: 99;
			singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	
	self should: [self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2]
		raise: ProcessorSimulationTrap
		withExceptionDo:
			[:pst|
			self assert: self processor pc = 16r14.
			self assert: pst pc = 16r14.
			self assert: pst nextpc = 16r18.
			self assert: pst address = 16r1FC.
			self assert: pst type = #write]
]

{ #category : #tests }
GdbARMAlienTests >> testMoveRAwTrap2 [
	"Write a register to a constant address that is below-range."
	
	"self new testMoveRAwTrap2"
	| memory |
	memory := self memory.
	self processor reset.

	"LEA sl, #16r1FC"
	memory unsignedLongAt: 5 put: (CogARMCompiler new mov: 10 imm: 0 ror: 0)  bigEndian: false. 
	memory unsignedLongAt: 9 put: (CogARMCompiler new orr: 10 imm: 0 ror: 0) bigEndian: false.
	memory unsignedLongAt: 13 put: (CogARMCompiler new orr: 10 imm: 16rFF ror: 24) bigEndian: false. 
	memory unsignedLongAt: 17 put: (CogARMCompiler new orr: 10 imm: 16rFC ror: 0) bigEndian: false. 
	"STR R5, [sl]"
	memory unsignedLongAt: 21 put: (CogARMCompiler new str: 5 rn: 10 plusImm: 0) bigEndian: false.

	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	self processor
			pc: 4;
			sp: (memory size - 4); "Room for return address"
			r5: 99;
			singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	
	self should: [self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2]
		raise: ProcessorSimulationTrap
		withExceptionDo:
			[:pst|
			self assert: self processor pc = 16r14.
			self assert: pst pc = 16r14.
			self assert: pst nextpc = 16r18.
			self assert: pst address = 16rFFFC.
			self assert: pst type = #write]
]

{ #category : #tests }
GdbARMAlienTests >> testNfib1 [
	"self new testNfib1"
	self should: [self runNFib: 1 disassemble: false printRegisters: false]
		raise: Error
		withExceptionDo: 
			[:err| self assert: err messageText = 'Error 0: Illegal Instruction fetch address (0x1000).'].
	self deny: (self processor pc between: 0 and: self nfib size).
	self assert: self processor r0 = 1 benchFib
]

{ #category : #tests }
GdbARMAlienTests >> testNfib16 [
	"self new testNfib16"
	self should: [self runNFib: 16 disassemble: false printRegisters: false]
		raise: Error.
	self deny: (self processor pc between: 0 and: self nfib size).
	self assert: self processor r0 = 16 benchFib
]

{ #category : #tests }
GdbARMAlienTests >> testNfib2 [
	"self new testNfib2"
	self should: [self runNFib: 2 disassemble: false printRegisters: false]
		raise: Error.
	self deny: (self processor pc between: 0 and: self nfib size).
	self assert: self processor r0 = 2 benchFib
]

{ #category : #tests }
GdbARMAlienTests >> testNfib4 [
	"self new testNfib4"
	self should: [self runNFib: 4 disassemble: false printRegisters: false]
		raise: Error.
	self deny: (self processor pc between: 0 and: self nfib size).
	self assert: self processor r0 = 4 benchFib
]

{ #category : #tests }
GdbARMAlienTests >> testQuickDisassemby [
	"self new testQuickDisassemby"

	| memory result |
	memory := WordArray new: 2.
	memory at: 1 put: (CogARMCompiler new orr: 6  imm: 16r3F ror: 16).
	result := self processor
		disassembleInstructionAt: 0 
		In: memory 
		into: [:str :len | 
			^str =  '00000000: orr	r6, r6, #4128768	; 0x3f0000'].
]

{ #category : #execution }
GdbARMAlienTests >> testQuickDisassembyOf: word [
	"self new testQuickDisassembyOf: 3858758348"

	| memory result |
	memory := WordArray new: 2.
	memory at: 1 put: word.
	result := self processor
		disassembleInstructionAt: 0 
		In: memory 
		into: [:str :len | 
			^str].
]

{ #category : #execution }
GdbARMAlienTests >> testResetCPU [
	"self new testResetCPU"
	self integerRegisterSetters do:
		[:setter|
		self processor perform: setter with: 16r55555555].
	self integerRegisterGetters do:
		[:getter|
		self assert: 16r55555555 = (self processor perform: getter)].
	self processor reset.
	self integerRegisterGetters do:
		[:getter|
		self assert: 0 = (self processor perform: getter)]
]

{ #category : #tests }
GdbARMAlienTests >> testReturnTrap [
	"return above-range with a bad address"
	
	"self new testReturnTrap"
	| memory badAddress|
	badAddress := 16r1E000000. 
	memory := self memory.
	self processor reset.

	"pop the stack into pc to emulate a return via stack as generated in  various trampoline code"	
	memory unsignedLongAt: 1 put: (CogARMCompiler new mov: 15 rn: 14) bigEndian: false.

	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	self processor
			pc: 0;
			sp: (memory size - 4); "Room for return address"
			lr: badAddress;
			singleStepIn: memory readExecuteOnlyBelow: memory size /2 .
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self should: [self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2]
		raise: ProcessorSimulationTrap
		withExceptionDo:
			[:pst|
			self assert: self processor pc = 0.
			self assert: pst pc = 0.
			self assert: pst nextpc = 4.
			self assert: pst address = badAddress.
			self assert: pst type = #return].
]

{ #category : #tests }
GdbARMAlienTests >> testReturnTrapWithThumbBug [
	"return above-range with a bad address that ends in 1 - which triggers an ARM sim bug"
	
	"self new testReturnTrapWithThumbBug"
	| memory badAddress|
	badAddress := 16r1E000001. "this will try to set thumb mode"
	memory := self memory.
	self processor reset.

	"pop the stack into pc to emulate a return via stack as generated in  various trampoline code"	
	memory unsignedLongAt: 1 put: (CogARMCompiler new mov: 15 rn: 14) bigEndian: false.

	
	"processor disassembleFrom: 0 to: 60 in: memory on: Transcript cr"
	self processor
			pc: 0;
			sp: (memory size - 4); "Room for return address"
			lr: badAddress;
			singleStepIn: memory readExecuteOnlyBelow: memory size /2 .
			"We have to step several times, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self should: [self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2.
				self processor singleStepIn: memory readExecuteOnlyBelow: memory size /2]
		raise: ProcessorSimulationTrap
		withExceptionDo:
			[:pst|
			self assert: self processor pc = 0.
			self assert: pst pc = 0.
			self assert: pst nextpc = 4.
			self assert: pst address = badAddress.
			self assert: pst type = #return].
]

{ #category : #tests }
GdbARMAlienTests >> testStepNfib1 [
	"self new testStepNfib1"
	self singleStepNFib: 1 disassemble: false printRegisters: false.
	self assert: self processor pc = (self nfib asWordArray size * 4).
	self assert: self processor r0 = 1 benchFib
]

{ #category : #tests }
GdbARMAlienTests >> testStepNfib2 [
	"self new testStepNfib2"
	self singleStepNFib: 2 disassemble: false printRegisters: false.
	self assert: self processor pc = (self nfib size * 4).
	self assert: self processor r0 = 2 benchFib
]

{ #category : #tests }
GdbARMAlienTests >> testStepNfib4 [
	"self new testStepNfib4"
	self singleStepNFib: 4 disassemble: false printRegisters: false.
	self assert: self processor pc = (self nfib size * 4).
	self assert: self processor r0 = 4 benchFib
]
