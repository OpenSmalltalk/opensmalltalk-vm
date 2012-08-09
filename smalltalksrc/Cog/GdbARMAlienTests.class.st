Class {
	#name : #GdbARMAlienTests,
	#superclass : #TestCase,
	#instVars : [
		'processor'
	],
	#category : #'Cog-Processors-Tests'
}

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

{ #category : #accessing }
GdbARMAlienTests >> registerGetters [
	^#(r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 lr sp pc)
]

{ #category : #accessing }
GdbARMAlienTests >> registerSetters [
	^#(r0: r1: r2: r3: r4: r5: r6: r7: r8: r9: r10: r11: r12: lr: sp: pc:)
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
GdbARMAlienTests >> testCallTrap [
	"Call a function that is out-of-range.  Ensure the call is trapped."
	"self new testCallTrap"
	| memory |
	memory := Bitmap new: 256 withAll: self processor nopOpcode.
	memory longAt: 1 put: (self processor branchAndLinkOpcodeWithOffset: 1024) bigEndian: false.
	memory := memory asByteArray.
	self processor
			pc: 0;
			sp: (memory size - 4); "Room for return address"
			singleStepIn: memory.
			"We have to step twice, because the first step only changes the pc, but does not fetch anything from the address it points to."
	self should: [self processor singleStepIn: memory]
		raise: Error
		withExceptionDo:
			[:pst|
			self assert: self processor pc = 1024.
			self assert: self processor lr = 4.
			self assert: pst pc = 0.
			self assert: pst nextpc = 4.
			self assert: pst address = 1024.
			self assert: pst type = #call].
]

{ #category : #tests }
GdbARMAlienTests >> testDisassembling [

	| memory result |
	memory := WordArray new: 2.
	memory at: 1 put: 16rEF200000.
	result := self processor
		disassembleInstructionAt: 0 
		In: memory 
		into: [:str :len | 
			self 
				assert: len = 4;
				assert: str = 'svc	0x00200000'].
]

{ #category : #tests }
GdbARMAlienTests >> testExecutionTrap [
	"Execute a run of nops.  test executing beyond the executable limit is trapped."
	"self new testExecutionTrap"
	| memory |
	 "The address is out of range of memory every which way (whether relative or absolute and whether big-endian or little."
	memory := (Bitmap new: 1024 * 2 withAll: self processor nopOpcode) asByteArray.
	self processor
			pc: 0;
			sp: (memory size - 4). "Room for return address"
	self should: [self processor runInMemory: memory minimumAddress: 0 readOnlyBelow: memory size / 2]
		raise: Error
		withExceptionDo:
			[:err|
			self assert: self processor pc = (memory size / 2).
			self assert: ('Error 0: Illegal Instruction fetch address (0x00001000).' match: err messageText)].
	self processor pc: 0.
	self should: [[self processor singleStepIn: memory minimumAddress: 0 readOnlyBelow: memory size / 2] repeat]
		raise: Error
		withExceptionDo:
			[:err|
			self assert: self processor pc = (memory size / 2).
			self assert: ('Error 0: Illegal Instruction fetch address (0x00001000).' match: err messageText)]
]

{ #category : #tests }
GdbARMAlienTests >> testFlags [
	"self new testFlags"
	| memory |
	memory := Bitmap new: 3.
	memory longAt: 1 put: 16rE3A03001 bigEndian: false. "MOV r3, #1"
	memory longAt: 5 put: 16rE3530001 bigEndian: false. "CMP r3, #1"
	memory := memory asByteArray.
	self processor
		disassembleInstructionAt: 0 
		In: memory 
		into: [:str :len | 
			self 
				assert: len = 4;
				assert: str = 'mov	r3, #1'].
	self processor
		disassembleInstructionAt: 4 
		In: memory 
		into: [:str :len | 
			self 
				assert: len = 4;
				assert: str = 'cmp	r3, #1'].
	self processor
		pc: 0;
		singleStepIn: memory;
		singleStepIn: memory.
	self 
		assert: self processor pc = 16r8;
		assert: self processor r3 = 1;
		assert: self processor zflag = 1;
		assert: self processor cflag = 1;
		assert: self processor vflag = 0;
		assert: self processor nflag = 0.
	self processor reset.
	self assert: self processor eflags = 3. "IFFlags are both set."
]

{ #category : #tests }
GdbARMAlienTests >> testNfib1 [
	"self new testNfib1"
	self should: [self runNFib: 1 disassemble: false printRegisters: false]
		raise: Error
		withExceptionDo: 
			[:err| self assert: err messageText = 'Error 0: Illegal Instruction fetch address (0x00001000).'].
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
GdbARMAlienTests >> testResetCPU [
	"self new testResetCPU"
	self registerSetters do:
		[:setter|
		self processor perform: setter with: 16r55555555].
	self registerGetters do:
		[:getter|
		self assert: 16r55555555 = (self processor perform: getter)].
	self processor reset.
	self registerGetters do:
		[:getter|
		self assert: 0 = (self processor perform: getter)]
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
