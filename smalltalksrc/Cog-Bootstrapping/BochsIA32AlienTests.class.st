Class {
	#name : #BochsIA32AlienTests,
	#superclass : #TestCase,
	#instVars : [
		'processor'
	],
	#category : #'Cog-Processors-Tests'
}

{ #category : #tests }
BochsIA32AlienTests >> callTrapPerformance: n [
	"Call a function that is out-of-range.  Ensure the call is trapped."
	"self new testCallTrap"
	| memory |
	 "The address is out of range of memory every which way (whether relative or absolute and whether big-endian or little."
	memory := ByteArray new: 1024.
	memory replaceFrom: 1 to: 5 with: { self processor callOpcode. 0. 16r80. 16r80. 0. } asByteArray.
	self processor
			eip: 0;
			esp: (memory size - 4). "Room for return address"
	1 to: n do:
		[:ign|
		[self processor singleStepIn: memory]
			on: ProcessorSimulationTrap
			do: [:ex|]].

	"QSystemProfiler spyOn: [BochsIA32AlienTests new callTrapPerformance: 1024*128]"
	"Time millisecondsToRun: [BochsIA32AlienTests new callTrapPerformance: 1024*128] 2463"
	"Time millisecondsToRun: [1 to: 1024*1024*64 do: [:ign| nil yourself]] 636"
	"Time millisecondsToRun: [1 to: 1024*1024*64 do: [:ign| nil perform: #ifNotNilDo: with: nil]] 3639"
	"Time millisecondsToRun: [1 to: 1024*1024*64 do: [:ign| nil perform: #ifNotNilDo:ifNil: with: nil with: nil]] 12401"
]

{ #category : #accessing }
BochsIA32AlienTests >> integerRegisterGetters [
	^#(eax ecx edx ebx esp ebp esi edi eip)
]

{ #category : #accessing }
BochsIA32AlienTests >> integerRegisterSetters [
	^#(eax: ecx: edx: ebx: esp: ebp: esi: edi: eip:)
]

{ #category : #accessing }
BochsIA32AlienTests >> nfib [
	"long fib(long n) { return n <= 1 ? 1 : fib(n-1) + fib(n-2) + 1; }
	 as compiled by Microsoft Visual C++ V6 (12.00.8804) cl /O2 /Fc"
	"| bat nfib ip |
	bat := BochsIA32AlienTests new.
	nfib := bat nfib asByteArray.
	ip := 0.
	20 timesRepeat:
		[bat processor disassembleInstructionAt: ip In: nfib into:
			[:da :len|
			Transcript nextPutAll: da; cr; flush.
			ip := ip + len]]"
	^#("00000" 16r56							"push    esi"
		"00001" 16r8B 16r74 16r24 16r08		"mov     esi, DWORD PTR _n$[esp]"
		"00005" 16r83 16rFE 16r01				"cmp     esi, 1"
		"00008" 16r7F 16r07						"jg      SHORT $L528"
		"0000a" 16rB8 16r01 16r00 16r00 16r00	"mov     eax, 1"
		"0000f" 16r5E							"pop     esi"
		"00010" 16rC3							"ret     0"
"
$L528:"
		"00011" 16r8D 16r46 16rFE				"lea     eax, DWORD PTR [esi-2]"
		"00014" 16r57							"push    edi"
		"00015" 16r50							"push    eax"
		"00016" 16rE8 16rE5 16rFF 16rFF 16rFF   "call    _fib"
		"0001b" 16r4E							"dec     esi"
		"0001c" 16r8B 16rF8						"mov     edi, eax"
		"0001e" 16r56							"push    esi"
		"0001f" 16rE8 16rDC 16rFF 16rFF 16rFF   "call    _fib"
		"00024" 16r83 16rC4 16r08				"add     esp, 8"
		"00027" 16r8D 16r44 16r07 16r01		"lea     eax, DWORD PTR [edi+eax+1]"
		"0002b" 16r5F							"pop     edi"
		"0002c" 16r5E							"pop     esi"
		"0002d" 16rC3							"ret     0")
]

{ #category : #accessing }
BochsIA32AlienTests >> processor [
	processor ifNil:
		[processor := BochsIA32Alien new].
	^processor
]

{ #category : #execution }
BochsIA32AlienTests >> runNFib: n disassemble: disassemble printRegisters: printRegisters [
	"Run nfib wth the argument. Answer the result."
	"self new runNFib: 5 disassemble: true printRegisters: true"
	| memory |
	memory := ByteArray new: 4096 * 2 withAll: self processor nopOpcode.
	memory
		replaceFrom: 1 to: self nfib size with: self nfib asByteArray startingAt: 1;
		longAt: memory size - 3 put: n bigEndian: false; "argument n"
		longAt: memory size - 7 put: self nfib size bigEndian: false.  "return address"
	self processor
		eip: 0;
		esp: (memory size - 8). "Room for return address and argument n"
	printRegisters ifTrue:
		[self processor printRegistersOn: Transcript.
		 Transcript cr; flush].
	"run until something goes wrong."
	self processor runInMemory: memory readExecuteOnlyBelow: memory size / 2.
	printRegisters ifTrue:
		[self processor printRegistersOn: Transcript.
		 Transcript cr; flush].
	^self processor eax
]

{ #category : #execution }
BochsIA32AlienTests >> singleStepNFib: n disassemble: disassemble printRegisters: printRegisters [
	"Run nfib wth the argument. Answer the result."
	"self new runNFib: 5 disassemble: true printRegisters: true"
	| memory finalSP |
	memory := ByteArray new: 4096 * 2 withAll: self processor nopOpcode.
	finalSP := memory size - 4. "Stop when we return to the nop following nfib"
	memory
		replaceFrom: 1 to: self nfib size with: self nfib asByteArray startingAt: 1;
		longAt: memory size - 3 put: n bigEndian: false; "argument n"
		longAt: memory size - 7 put: self nfib size bigEndian: false.  "return address"
	self processor
			eip: 0;
			esp: (memory size - 8). "Room for return address and argument n"
	printRegisters ifTrue:
		[self processor printRegistersOn: Transcript.
		 Transcript cr; flush].
	[disassemble ifTrue:
		[Transcript nextPutAll: (self processor disassembleNextInstructionIn: memory); cr; flush].
	 self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2.
	 printRegisters ifTrue:
		[self processor printRegistersOn: Transcript.
		 Transcript cr; flush].
	 self processor esp ~= finalSP] whileTrue.
	^self processor eax
]

{ #category : #tests }
BochsIA32AlienTests >> testCPUHasSSE2 [
	"Use the CPUID instruction to check if SSE2 is supported.  Cog
	 uses SSE2 instructions for machine-code floating-point primitives."
	self processor eax: 0. "get vendor identfication string"
	self processor eip: 0; singleStepIn: (ByteArray with: 16r0F with: 16rA2 with: 16r90) "cpuid;nop".
	self assert: self processor eip = 2.
	self assert: self processor eax >= 1.
	self processor eax: 1.
	self processor eip: 0; singleStepIn: (ByteArray with: 16r0F with: 16rA2 with: 16r90) "cpuid;nop".
	self assert: self processor eip = 2.
	self assert: (self processor edx bitAnd: 1 << 26) ~= 0

	"self new testCPUHasSSE2"
]

{ #category : #tests }
BochsIA32AlienTests >> testCPUID [
	| vendorString |
	self processor
			eip: 0;
			eax: 0. "get vendor identfication string"
	self processor singleStepIn: (ByteArray with: 16r0F with: 16rA2 with: 16r90) "cpuid;nop".
	self assert: self processor eip = 2.
	self assert: self processor eax ~= 0.
	vendorString := (ByteArray new: 12)
						longAt: 1 put: self processor ebx bigEndian: false;
						longAt: 5 put: self processor edx bigEndian: false;
						longAt: 9 put: self processor ecx bigEndian: false;
						asString.
	self assert: (vendorString = 'GenuineIntel'
				or: [vendorString = 'AuthenticAMD'])
]

{ #category : #tests }
BochsIA32AlienTests >> testCallTrap [
	"Call a function that is out-of-range.  Ensure the call is trapped."
	"self new testCallTrap"
	| memory |
	 "The address is out of range of memory every which way (whether relative or absolute and whether big-endian or little."
	memory := ByteArray new: 1024.
	memory replaceFrom: 1 to: 5 with: { self processor callOpcode. 0. 16r80. 16r80. 0. } asByteArray.
	self processor
			eip: 0;
			esp: (memory size - 4). "Room for return address"
	self should: [self processor singleStepIn: memory]
		raise: ProcessorSimulationTrap
		withExceptionDo:
			[:pst|
			self assert: pst address = ((memory longAt: 2 bigEndian: false) + 5 "length of call instr").
			self assert: pst pc = 0.
			self assert: pst type = #call].

	"| memory |
	memory := ByteArray new: 1024.
	memory replaceFrom: 1 to: 5 with: { BochsIA32Alien new callOpcode. 0. 16r80. 16r80. 0. } asByteArray.
	BochsIA32AlienTests new processor
		eip: 0;
		esp: (memory size - 4);
		singleStepIn: memory;
		printRegistersOn: Transcript.
	Transcript flush"
]

{ #category : #tests }
BochsIA32AlienTests >> testExecutionTrap [
	"Execute a run of nops.  test executing beyond the executable limit is trapped."
	"self new testExecutionTrap"
	| memory |
	 "The address is out of range of memory every which way (whether relative or absolute and whether big-endian or little."
	memory := ByteArray new: 4096 * 2 withAll: self processor nopOpcode.
	self processor
			eip: 0;
			esp: (memory size - 4). "Room for return address"
	self should: [self processor runInMemory: memory minimumAddress: 0 readOnlyBelow: memory size / 2]
		raise: Error
		withExceptionDo:
			[:err|
			self assert: self processor pc = (memory size / 2).
			self assert: ('*EIP*> CS.limit*' match: err messageText)].
	self processor eip: 0.
	self should: [[self processor singleStepIn: memory minimumAddress: 0 readOnlyBelow: memory size / 2] repeat]
		raise: Error
		withExceptionDo:
			[:err|
			self assert: self processor pc = (memory size / 2).
			self assert: ('*EIP*> CS.limit*' match: err messageText)]
]

{ #category : #tests }
BochsIA32AlienTests >> testMOVSD [
	"Test MOVSD indirecting through edx."
	"self new testMOVSD"
	self processor
		edx: 0;
		eip: 0;
		singleStepIn: {16rF2. 16r0F. 16r10. 16r42. 16r04. 16r90. 16r01. 16r02. 16r03. 16r04. 16r05. 16r06} asByteArray "movsd %ds:0x4(%edx), %xmm0;nop;garbage".
	self assert: self processor eip = 5.
	self assert: self processor xmm0low = 16r0605040302019004
]

{ #category : #tests }
BochsIA32AlienTests >> testNfib1 [
	"self new testNfib1"
	self should: [self runNFib: 1 disassemble: false printRegisters: false]
		raise: Error.
	self deny: (self processor eip between: 1 and: self nfib size).
	self assert: self processor eax = 1 benchFib
]

{ #category : #tests }
BochsIA32AlienTests >> testNfib16 [
	"self new testNfib16"
	self should: [self runNFib: 16 disassemble: false printRegisters: false]
		raise: Error.
	self deny: (self processor eip between: 1 and: self nfib size).
	self assert: self processor eax = 16 benchFib
]

{ #category : #tests }
BochsIA32AlienTests >> testNfib2 [
	"self new testNfib2"
	self should: [self runNFib: 2 disassemble: false printRegisters: false]
		raise: Error.
	self deny: (self processor eip between: 1 and: self nfib size).
	self assert: self processor eax = 2 benchFib
]

{ #category : #tests }
BochsIA32AlienTests >> testNfib4 [
	"self new testNfib4"
	self should: [self runNFib: 4 disassemble: false printRegisters: false]
		raise: Error.
	self deny: (self processor eip between: 1 and: self nfib size).
	self assert: self processor eax = 4 benchFib
]

{ #category : #tests }
BochsIA32AlienTests >> testResetCPU [
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
BochsIA32AlienTests >> testStepNfib1 [
	"self new testNfib1"
	self singleStepNFib: 1 disassemble: false printRegisters: false.
	self assert: self processor eip = self nfib size.
	self assert: self processor eax = 1 benchFib
]

{ #category : #tests }
BochsIA32AlienTests >> testStepNfib2 [
	"self new testNfib2"
	self singleStepNFib: 2 disassemble: false printRegisters: false.
	self assert: self processor eip = self nfib size.
	self assert: self processor eax = 2 benchFib
]

{ #category : #tests }
BochsIA32AlienTests >> testStepNfib4 [
	"self new testNfib4"
	self singleStepNFib: 4 disassemble: false printRegisters: false.
	self assert: self processor eip = self nfib size.
	self assert: self processor eax = 4 benchFib
]
