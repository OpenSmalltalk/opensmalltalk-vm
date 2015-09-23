Class {
	#name : #BochsX64Alien,
	#superclass : #CogProcessorAlien,
	#type : #bytes,
	#classVars : [
		'ExtendedOpcodeExceptionMap',
		'OpcodeExceptionMap',
		'PostBuildStackDelta'
	],
	#category : #'Cog-Processors'
}

{ #category : #'instance creation' }
BochsX64Alien class >> dataSize [
	^22672
]

{ #category : #'class initialization' }
BochsX64Alien class >> initialize [
	"BochsX64Alien initialize"
	| it |
	it := self basicNew.
	PostBuildStackDelta := 0.
	OpcodeExceptionMap := Array new: 256 withAll: #handleExecutionPrimitiveFailureAt:in:.
	OpcodeExceptionMap
		at: 1 + it callOpcode			put: #handleCallFailureAt:in:;
		at: 1 + it jmpOpcode			put: #handleJmpFailureAt:in:;
		at: 1 + it retOpcode			put: #handleRetFailureAt:in:;
		at: 1 + it movALObOpcode	put: #handleMovALObFailureAt:in:;
		at: 1 + it movObALOpcode	put: #handleMovObALFailureAt:in:;
		at: 1 + it movGvEvOpcode	put: #handleMovGvEvFailureAt:in:;
		at: 1 + it movEvGvOpcode	put: #handleMovEvGvFailureAt:in:;
		at: 1 + it movGbEbOpcode	put: #handleMovGbEbFailureAt:in:;
		at: 1 + it movEbGbOpcode	put: #handleMovEbGbFailureAt:in:.
	ExtendedOpcodeExceptionMap := Array new: 256 withAll: #handleExecutionPrimitiveFailureAt:in:.
	ExtendedOpcodeExceptionMap
		at: 1 + it movGvEbOpcode put: #handleMovGvEbFailureAt:in:
]

{ #category : #'instance creation' }
BochsX64Alien class >> primitiveNewCPU [
	"Answer the address of a new Bochs C++ class bx_cpu_c/BX_CPU_C x64 (x86-64) CPU emulator instance."
	<primitive: 'primitiveNewCPU' module: 'BochsX64Plugin'>
	^self primitiveFailed
]

{ #category : #'Cog API' }
BochsX64Alien >> abstractInstructionCompilerClass [
	^CogX64Compiler
]

{ #category : #'Cog API' }
BochsX64Alien >> bitsInWord [
	^64
]

{ #category : #opcodes }
BochsX64Alien >> callOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA8"
	^16rE8
]

{ #category : #'tests support' }
BochsX64Alien >> convertIntegerToInternal: anInteger [
	"Conversion for 64-bit processors."
	^anInteger signedIntToLong64
]

{ #category : #'tests support' }
BochsX64Alien >> convertInternalToInteger: unsigned [
	"Conversion for 64-bit processors."
	^unsigned signedIntFromLong64
]

{ #category : #accessing }
BochsX64Alien >> cr0 [
	^self unsignedLongLongAt: 1225
]

{ #category : #accessing }
BochsX64Alien >> cr0: anUnsignedInteger [
	^self unsignedLongLongAt: 1225 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> cr1 [
	^self unsignedLongLongAt: 1229
]

{ #category : #accessing }
BochsX64Alien >> cr1: anUnsignedInteger [
	^self unsignedLongLongAt: 1229 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> cr2 [
	^self unsignedLongLongAt: 1233
]

{ #category : #accessing }
BochsX64Alien >> cr2: anUnsignedInteger [
	^self unsignedLongLongAt: 1233 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> cr3 [
	^self unsignedLongLongAt: 1241
]

{ #category : #accessing }
BochsX64Alien >> cr3: anUnsignedInteger [
	^self unsignedLongLongAt: 1241 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> cr4 [
	^self unsignedLongLongAt: 1253
]

{ #category : #accessing }
BochsX64Alien >> cr4: anUnsignedInteger [
	^self unsignedLongLongAt: 1253 put: anUnsignedInteger
]

{ #category : #execution }
BochsX64Alien >> flushICacheFrom: startAddress "<Integer>" to: endAddress [ "<Integer>"
	self primitiveFlushICacheFrom: startAddress To: endAddress
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> fp [
	^self rbp
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> fp: anAddress [
	"Set whatever the processor considers its frame pointer to anAddress."
	self rbp: anAddress
]

{ #category : #'error handling' }
BochsX64Alien >> handleExecutionPrimitiveFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Handle an execution primitive failure for an unhandled opcode."
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
BochsX64Alien >> handleExecutionPrimitiveFailureIn: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress [
	"Handle an execution primitive failure.  Convert out-of-range call and absolute
	 memory read into register instructions into ProcessorSimulationTrap signals."
	"self printIntegerRegistersOn: Transcript"
	"self printRegistersOn: Transcript"
	| pc opcode offset |
	((pc := self rip) between: minimumAddress and: memoryArray byteSize - 1) ifTrue:
		[opcode := memoryArray byteAt: pc + (offset := 1).
		 (opcode bitAnd: 16rF8) = self rexPrefix ifTrue: "skip rex prefix if present"
			[opcode := memoryArray byteAt: pc + (offset := 2)].
		 opcode ~= 16r0f ifTrue:
			[^self
				perform: (OpcodeExceptionMap at: opcode + 1)
				with: pc
				with: memoryArray].
		 opcode := memoryArray byteAt: pc + offset + 1.
		 ^self
				perform: (ExtendedOpcodeExceptionMap at: opcode + 1)
				with: pc
				with: memoryArray].
	^self reportPrimitiveFailure
]

{ #category : #'processor setup' }
BochsX64Alien >> initializeStackFor: aCogit [
	"Different cpus need different stack alignment etc, so handle the details here."
	"This is for testing.  On many OS's the stack must remain aligned;
	 e.g. IA32 using SSE requires 16 byte alignment."
	| stackAlignment |
	stackAlignment := 16.
	aCogit setStackAlignment: stackAlignment expectedSPOffset: 0 expectedFPOffset: 8.
	self assert: stackAlignment isPowerOfTwo.
	PostBuildStackDelta :=  stackAlignment > 8
								ifTrue: [stackAlignment - 8]
								ifFalse: [0]
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> integerRegisterState [
	^{	self rax. self rbx. self rcx. self rdx. self rsp. self rbp. self rsi. self rdi.
		self r8. self r9. self r10. self r11. self r12. self r13. self r14. self r15.
		self rip. self rflags }
]

{ #category : #opcodes }
BochsX64Alien >> jmpOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA8"
	^16rE9
]

{ #category : #opcodes }
BochsX64Alien >> lockPrefix [
	^16rF0
]

{ #category : #opcodes }
BochsX64Alien >> movALObOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA7"
	^16rA1
]

{ #category : #opcodes }
BochsX64Alien >> movEbGbOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2"
	^16r88
]

{ #category : #opcodes }
BochsX64Alien >> movEvGvOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA8"
	^16r89
]

{ #category : #opcodes }
BochsX64Alien >> movGbEbOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2"
	^16r8A
]

{ #category : #opcodes }
BochsX64Alien >> movGvEbOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A3, pA14"
	^16rB6
]

{ #category : #opcodes }
BochsX64Alien >> movGvEvOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA8"
	^16r8B
]

{ #category : #opcodes }
BochsX64Alien >> movObALOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA7"
	^16rA3
]

{ #category : #opcodes }
BochsX64Alien >> nopOpcode [
	^16r90
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> pc [
	^self rip
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> pc: anAddress [
	"Set whatever the processor considers its program counter to anAddress."
	self rip: anAddress
]

{ #category : #primitives }
BochsX64Alien >> primitiveDisassembleAt: address inMemory: memoryArray [ "<Bitmap|ByteArray>"
	"Answer an Array of the size and the disassembled code string for the instruction at the current instruction pointer in memory."
	<primitive: 'primitiveDisassembleAtInMemory' module: 'BochsX64Plugin'>
	^self primitiveFailed
]

{ #category : #primitives }
BochsX64Alien >> primitiveErrorAndLog [
	"Answer an array of the current error code and log contents"
	<primitive: 'primitiveErrorAndLog' module: 'BochsX64Plugin'>
	^self primitiveFailed
]

{ #category : #primitives }
BochsX64Alien >> primitiveFlushICacheFrom: startAddress "<Integer>" To: endAddress [ "<Integer>"
	"Flush the icache in the requested range"
	<primitive: 'primitiveFlushICacheFromTo' module: 'BochsX64Plugin'>
	^self primitiveFailed
]

{ #category : #primitives }
BochsX64Alien >> primitiveResetCPU [
	"Reset the receiver to registers all zero, and protected 32-bit mode."
	<primitive: 'primitiveResetCPU' module: 'BochsX64Plugin'>
	^self reportPrimitiveFailure
]

{ #category : #primitives }
BochsX64Alien >> primitiveRunInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Run the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 calls, jumps and memory read/writes into ProcessorSimulationTrap signals."
	<primitive: 'primitiveRunInMemoryMinimumAddressReadWrite' module: 'BochsX64Plugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress]
		ifFalse: [self reportPrimitiveFailure]

	"self printRegistersOn: Transcript"
]

{ #category : #primitives }
BochsX64Alien >> primitiveSingleStepInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Single-step the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 calls, jumps and memory read/writes into ProcessorSimulationTrap signals."
	<primitive: 'primitiveSingleStepInMemoryMinimumAddressReadWrite' module: 'BochsX64Plugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress]
		ifFalse: [self reportPrimitiveFailure]
]

{ #category : #printing }
BochsX64Alien >> printFields: fields inRegisterState: registerStateVector on: aStream [
	| rsvs |
	aStream ensureCr.
	rsvs := registerStateVector readStream.
	fields withIndexDo:
		[:sym :index| | val |
		sym = #cr
			ifTrue: [aStream cr]
			ifFalse:
				[(val := rsvs next) isNil ifTrue: [^self].
				(sym beginsWith: 'xmm')
					ifTrue:
						[aStream nextPutAll: sym; nextPut: $:; space.
						 val printOn: aStream base: 16 length: 16 padded: true.
						 aStream space; nextPut: $(.
						 "At the image level Float is apparently in big-endian format"
						 ((Float basicNew: 2)
						 	at: 2 put: (val bitAnd: 16rFFFFFFFF);
							at: 1 put: (val bitShift: -32);
							yourself)
								printOn: aStream.
						 aStream nextPut: $)]
					ifFalse:
						[aStream nextPutAll: sym; nextPut: $:; space.
						 val printOn: aStream base: 16 length: 8 padded: true.
						 #eflags == sym
							ifTrue:
								[aStream space.
								 'C-P-A-ZS---O' withIndexDo:
									[:flag :bitIndex|
									flag ~= $- ifTrue:
										[aStream nextPut: flag; nextPutAll: 'F='; print: (val bitAnd: 1 << (bitIndex - 1)) >> (bitIndex - 1); space]]]
							ifFalse:
								[val > 16 ifTrue:
									[aStream space; nextPut: $(.
									 val printOn: aStream base: 10 length: 1 padded: false.
									 aStream nextPut: $)]]].
						(fields at: index + 1) ~~ #cr ifTrue:
							[aStream tab]]]
]

{ #category : #printing }
BochsX64Alien >> printIntegerRegistersOn: aStream [
	self printRegisterState: self integerRegisterState on: aStream.
	aStream flush
]

{ #category : #printing }
BochsX64Alien >> printRegisterState: registerStateVector on: aStream [
	self printFields:
			((registerStateVector size < 26
			  or: [(19 to: 26) allSatisfy: [:i| (registerStateVector at: i) isZero]])
				ifTrue:
					[#(	rax rbx rcx rdx cr
						rsp rbp rsi rdi cr
						r8 r9 r10 r11 cr
						r12 r13 r14 r15 cr
						rip rflags cr)]
				ifFalse:
					[#(	rax rbx rcx rdx cr
						rsp rbp rsi rdi cr
						r8 r9 r10 r11 cr
						r12 r13 r14 r15 cr
						rip rflags cr
						xmm0low xmm1low cr
						xmm2low xmm3low cr
						xmm4low xmm5low cr
						xmm6low xmm7low cr )])
		inRegisterState: registerStateVector
		on: aStream
]

{ #category : #accessing }
BochsX64Alien >> r10 [
	^self unsignedLongLongAt: 549
]

{ #category : #accessing }
BochsX64Alien >> r10: anUnsignedInteger [
	^self unsignedLongLongAt: 549 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r11 [
	^self unsignedLongLongAt: 557
]

{ #category : #accessing }
BochsX64Alien >> r11: anUnsignedInteger [
	^self unsignedLongLongAt: 557 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r12 [
	^self unsignedLongLongAt: 565
]

{ #category : #accessing }
BochsX64Alien >> r12: anUnsignedInteger [
	^self unsignedLongLongAt: 565 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r13 [
	^self unsignedLongLongAt: 573
]

{ #category : #accessing }
BochsX64Alien >> r13: anUnsignedInteger [
	^self unsignedLongLongAt: 573 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r14 [
	^self unsignedLongLongAt: 581
]

{ #category : #accessing }
BochsX64Alien >> r14: anUnsignedInteger [
	^self unsignedLongLongAt: 581 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r15 [
	^self unsignedLongLongAt: 589
]

{ #category : #accessing }
BochsX64Alien >> r15: anUnsignedInteger [
	^self unsignedLongLongAt: 589 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r8 [
	^self unsignedLongLongAt: 533
]

{ #category : #accessing }
BochsX64Alien >> r8: anUnsignedInteger [
	^self unsignedLongLongAt: 533 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r9 [
	^self unsignedLongLongAt: 541
]

{ #category : #accessing }
BochsX64Alien >> r9: anUnsignedInteger [
	^self unsignedLongLongAt: 541 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rax [
	^self unsignedLongLongAt: 469
]

{ #category : #accessing }
BochsX64Alien >> rax: anUnsignedInteger [
	^self unsignedLongLongAt: 469 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rbp [
	^self unsignedLongLongAt: 509
]

{ #category : #accessing }
BochsX64Alien >> rbp: anUnsignedInteger [
	^self unsignedLongLongAt: 509 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rbx [
	^self unsignedLongLongAt: 493
]

{ #category : #accessing }
BochsX64Alien >> rbx: anUnsignedInteger [
	^self unsignedLongLongAt: 493 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rcx [
	^self unsignedLongLongAt: 477
]

{ #category : #accessing }
BochsX64Alien >> rcx: anUnsignedInteger [
	^self unsignedLongLongAt: 477 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rdi [
	^self unsignedLongLongAt: 525
]

{ #category : #accessing }
BochsX64Alien >> rdi: anUnsignedInteger [
	^self unsignedLongLongAt: 525 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rdx [
	^self unsignedLongLongAt: 485
]

{ #category : #accessing }
BochsX64Alien >> rdx: anUnsignedInteger [
	^self unsignedLongLongAt: 485 put: anUnsignedInteger
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> registerState [
	^{	self rax. self rbx. self rcx. self rdx. self rsp. self rbp. self rsi. self rdi.
		self r8. self r9. self r10. self r11. self r12. self r13. self r14. self r15.
		self rip. self rflags.
		self xmm0low. self xmm1low. self xmm2low. self xmm3low.
		self xmm4low. self xmm5low. self xmm6low. self xmm7low }
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> registerStateSetters [
	^#(rax: rbx: rcx: rdx: rsp: rbp: rsi: rdi: r8: r9: r10: r11: r12: r13: r14: r15:
		rip: rflags:
		xmm0low: xmm1low: xmm2low: xmm3low:
		xmm4low: xmm5low: xmm6low: xmm7low: )
]

{ #category : #primitives }
BochsX64Alien >> reset [
	self primitiveResetCPU.
	"Enable SSE extensions by setting the OSFXSR (Operating System FXSAVE/FXRSTOR Support) bit"
	self cr4: (self cr4 bitOr: 1 << 9)
]

{ #category : #opcodes }
BochsX64Alien >> retOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA7"
	^16rC3
]

{ #category : #opcodes }
BochsX64Alien >> rexPrefix [
	^16r48
]

{ #category : #accessing }
BochsX64Alien >> rflags [
	^self unsignedLongLongAt: 621
]

{ #category : #accessing }
BochsX64Alien >> rflags: anUnsignedInteger [
	^self unsignedLongLongAt: 621 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rip [
	^self unsignedLongLongAt: 597
]

{ #category : #accessing }
BochsX64Alien >> rip: anUnsignedInteger [
	^self unsignedLongLongAt: 597 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rsi [
	^self unsignedLongLongAt: 517
]

{ #category : #accessing }
BochsX64Alien >> rsi: anUnsignedInteger [
	^self unsignedLongLongAt: 517 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rsp [
	^self unsignedLongLongAt: 501
]

{ #category : #accessing }
BochsX64Alien >> rsp: anUnsignedInteger [
	^self unsignedLongLongAt: 501 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> saveRip [
	^self unsignedLongAt: 1913
]

{ #category : #accessing }
BochsX64Alien >> saveRip: anUnsignedInteger [
	^self unsignedLongAt: 1913 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> saveRsp [
	^self unsignedLongAt: 1921
]

{ #category : #accessing }
BochsX64Alien >> saveRsp: anUnsignedInteger [
	^self unsignedLongAt: 1921 put: anUnsignedInteger
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> setFramePointer: framePointer stackPointer: stackPointer [
	"Initialize the processor's frame and stack pointers"
	self rbp: framePointer.
	self rsp: stackPointer
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> sp [
	^self rsp
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> sp: anAddress [
	"Set whatever the processor considers its stack pointer to anAddress."
	self rsp: anAddress
]

{ #category : #accessing }
BochsX64Alien >> stopReason [
	^self unsignedByteAt: 1973
]

{ #category : #accessing }
BochsX64Alien >> stopReason: anUnsignedInteger [
	^self unsignedByteAt: 1973 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm0high [
	^self unsignedLongLongAt: 1421
]

{ #category : #accessing }
BochsX64Alien >> xmm0high: anUnsignedInteger [
	^self unsignedLongLongAt: 1421 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm0low [
	^self unsignedLongLongAt: 1413
]

{ #category : #accessing }
BochsX64Alien >> xmm0low: anUnsignedInteger [
	^self unsignedLongLongAt: 1413 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm1high [
	^self unsignedLongLongAt: 1437
]

{ #category : #accessing }
BochsX64Alien >> xmm1high: anUnsignedInteger [
	^self unsignedLongLongAt: 1437 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm1low [
	^self unsignedLongLongAt: 1429
]

{ #category : #accessing }
BochsX64Alien >> xmm1low: anUnsignedInteger [
	^self unsignedLongLongAt: 1429 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm2high [
	^self unsignedLongLongAt: 1453
]

{ #category : #accessing }
BochsX64Alien >> xmm2high: anUnsignedInteger [
	^self unsignedLongLongAt: 1453 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm2low [
	^self unsignedLongLongAt: 1445
]

{ #category : #accessing }
BochsX64Alien >> xmm2low: anUnsignedInteger [
	^self unsignedLongLongAt: 1445 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm3high [
	^self unsignedLongLongAt: 1469
]

{ #category : #accessing }
BochsX64Alien >> xmm3high: anUnsignedInteger [
	^self unsignedLongLongAt: 1469 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm3low [
	^self unsignedLongLongAt: 1461
]

{ #category : #accessing }
BochsX64Alien >> xmm3low: anUnsignedInteger [
	^self unsignedLongLongAt: 1461 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm4high [
	^self unsignedLongLongAt: 1485
]

{ #category : #accessing }
BochsX64Alien >> xmm4high: anUnsignedInteger [
	^self unsignedLongLongAt: 1485 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm4low [
	^self unsignedLongLongAt: 1477
]

{ #category : #accessing }
BochsX64Alien >> xmm4low: anUnsignedInteger [
	^self unsignedLongLongAt: 1477 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm5high [
	^self unsignedLongLongAt: 1501
]

{ #category : #accessing }
BochsX64Alien >> xmm5high: anUnsignedInteger [
	^self unsignedLongLongAt: 1501 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm5low [
	^self unsignedLongLongAt: 1493
]

{ #category : #accessing }
BochsX64Alien >> xmm5low: anUnsignedInteger [
	^self unsignedLongLongAt: 1493 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm6high [
	^self unsignedLongLongAt: 1517
]

{ #category : #accessing }
BochsX64Alien >> xmm6high: anUnsignedInteger [
	^self unsignedLongLongAt: 1517 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm6low [
	^self unsignedLongLongAt: 1509
]

{ #category : #accessing }
BochsX64Alien >> xmm6low: anUnsignedInteger [
	^self unsignedLongLongAt: 1509 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm7high [
	^self unsignedLongLongAt: 1533
]

{ #category : #accessing }
BochsX64Alien >> xmm7high: anUnsignedInteger [
	^self unsignedLongLongAt: 1533 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm7low [
	^self unsignedLongLongAt: 1525
]

{ #category : #accessing }
BochsX64Alien >> xmm7low: anUnsignedInteger [
	^self unsignedLongLongAt: 1525 put: anUnsignedInteger
]
