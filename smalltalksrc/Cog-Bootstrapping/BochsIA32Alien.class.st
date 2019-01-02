"
I am a wrapper around the Bochs C++ IA32 CPU emulator.  Note that currently I provide no access to the x87/mmx FPU state, only providing access to the SSE/xmm registers.

Here is the configure script for the configuration this code assumes.  Offsets of fields will change with different configurations so they must agree.

----8<---- conf.COG ----8<----
#!/bin/sh

# this sets up the compile for Cog.  Disable as much inessential stuff
# as possible leaving only the cpu/fpu & memory interface

set echo
# CFLAGS=""-pipe -O3 -fomit-frame-pointer -finline-functions -falign-loops=16 -falign-jumps=16 -falign-functions=16 -falign-labels=16 -falign-loops-max-skip=15 -falign-jumps-max-skip=15 -fprefetch-loop-arrays $CFLAGS""
CFLAGS=""-m32 $CFLAGS""
CFLAGS=""-Dlongjmp=_longjmp -Dsetjmp=_setjmp $CFLAGS""
CFLAGS=""-pipe -O3 -fomit-frame-pointer -finline-functions $CFLAGS""
CFLAGS=""-g $CFLAGS""
CPATH=""/sw/include""
CPPFLAGS=""""
CXXFLAGS=""$CFLAGS""
LDFLAGS=""-L/sw/lib""

export CFLAGS
export CPATH
export CPPFLAGS
export CXXFLAGS
export LDFLAGS

./configure --enable-Cog \
	--enable-cpu-level=6 \
	--enable-sse=2 \
	--enable-assert-checks \
	--with-nogui \
		--disable-x86-64 \
		--disable-pae \
		--disable-large-pages \
		--disable-global-pages \
		--disable-mtrr \
		--disable-sb16 \
		--disable-ne2000 \
		--disable-pci \
		--disable-acpi \
		--disable-apic \
		--disable-clgd54xx \
		--disable-usb \
		--disable-plugins \
	${CONFIGURE_ARGS}

# apic == Advanced programmable Interrupt Controller
# acpi == Advanced Configuration and Power Interface
# pci == Peripheral Component Interconnect local bus
# clgd54xx == Cirrus Logic GD54xx video card
----8<---- conf.COG ----8<----
"
Class {
	#name : #BochsIA32Alien,
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
BochsIA32Alien class >> dataSize [
	^18096
]

{ #category : #'instance creation' }
BochsIA32Alien class >> implementationClass [
	^Smalltalk wordSize = 8 ifTrue: [BochsIA32Alien64] ifFalse: [self]
]

{ #category : #'class initialization' }
BochsIA32Alien class >> initialize [
	"BochsIA32Alien initialize"
	| it |
	it := self basicNew.
	PostBuildStackDelta := 0.
	OpcodeExceptionMap := Array new: 256 withAll: #handleExecutionPrimitiveFailureAt:in:.
	OpcodeExceptionMap
		at: 1 + it callOpcode			put: #handleCallFailureAt:in:;
		at: 1 + it jmpOpcode			put: #handleJmpFailureAt:in:;
		at: 1 + it retOpcode			put: #handleRetFailureAt:in:;
		at: 1 + it movALObOpcode	put: #handleMovALObFailureAt:in:;
		at: 1 + it movAXOvOpcode	put: #handleMovAXOvFailureAt:in:;
		at: 1 + it movObALOpcode	put: #handleMovObALFailureAt:in:;
		at: 1 + it movOvAXOpcode	put: #handleMovOvAXFailureAt:in:;
		at: 1 + it movGvEvOpcode	put: #handleMovGvEvFailureAt:in:;
		at: 1 + it movEvGvOpcode	put: #handleMovEvGvFailureAt:in:;
		at: 1 + it movGbEbOpcode	put: #handleMovGbEbFailureAt:in:;
		at: 1 + it movEbGbOpcode	put: #handleMovEbGbFailureAt:in:.
	ExtendedOpcodeExceptionMap := Array new: 256 withAll: #handleExecutionPrimitiveFailureAt:in:.
	ExtendedOpcodeExceptionMap
		at: 1 + it movGvEbOpcode put: #handleMovGvEbFailureAt:in:
]

{ #category : #primitives }
BochsIA32Alien class >> primitiveNewCPU [
	"Answer the address of a new Bochs C++ class bx_cpu_c/BX_CPU_C x86 CPU emulator instance."
	<primitive: 'primitiveNewCPU' module: 'BochsIA32Plugin'>
	^self primitiveFailed
]

{ #category : #'Cog API' }
BochsIA32Alien >> abstractInstructionCompilerClass [
	^CogIA32Compiler
]

{ #category : #accessing }
BochsIA32Alien >> al [
	^self unsignedByteAt: 469
]

{ #category : #accessing }
BochsIA32Alien >> al: anUnsignedInteger [
	^self unsignedByteAt: 469 put: anUnsignedInteger
]

{ #category : #'Cog API' }
BochsIA32Alien >> bitsInWord [
	^32
]

{ #category : #accessing }
BochsIA32Alien >> bl [
	^self unsignedByteAt: 481
]

{ #category : #accessing }
BochsIA32Alien >> bl: anUnsignedInteger [
	^self unsignedByteAt: 481 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> bpl [
	^self unsignedByteAt: 489
]

{ #category : #accessing }
BochsIA32Alien >> bpl: anUnsignedInteger [
	^self unsignedByteAt: 489 put: anUnsignedInteger
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> cResultRegister [
	^self eax
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> cResultRegister: aValue [
	^self eax: aValue
]

{ #category : #opcodes }
BochsIA32Alien >> callOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA8"
	^16rE8
]

{ #category : #accessing }
BochsIA32Alien >> cl [
	^self unsignedByteAt: 473
]

{ #category : #accessing }
BochsIA32Alien >> cl: anUnsignedInteger [
	^self unsignedByteAt: 473 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> cr0 [
	^self unsignedLongLongAt: 1009
]

{ #category : #accessing }
BochsIA32Alien >> cr0: anUnsignedInteger [
	^self unsignedLongLongAt: 1009 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> cr1 [
	^self unsignedLongLongAt: 1013
]

{ #category : #accessing }
BochsIA32Alien >> cr1: anUnsignedInteger [
	^self unsignedLongLongAt: 1013 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> cr2 [
	^self unsignedLongLongAt: 1017
]

{ #category : #accessing }
BochsIA32Alien >> cr2: anUnsignedInteger [
	^self unsignedLongLongAt: 1017 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> cr3 [
	^self unsignedLongLongAt: 1021
]

{ #category : #accessing }
BochsIA32Alien >> cr3: anUnsignedInteger [
	^self unsignedLongLongAt: 1021 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> cr4 [
	^self unsignedLongLongAt: 1029
]

{ #category : #accessing }
BochsIA32Alien >> cr4: anUnsignedInteger [
	^self unsignedLongLongAt: 1029 put: anUnsignedInteger
]

{ #category : #disassembly }
BochsIA32Alien >> decorateDisassembly: anInstructionString for: aSymbolManager "<Cogit>" fromAddress: address [
	| string i1 i2 v |
	string := anInstructionString.
	aSymbolManager relativeBaseForDisassemblyInto:
		[:baseAddress :baseName|
		string := baseName, '+', (address - baseAddress printStringBase: 16 length: 4 padded: true), (string copyFrom: (string indexOf: $:) + 1 to: string size)].
	(i1 := string indexOfSubCollection: '%ds:0x') > 0 ifTrue:
		[i2 := i1 + 6.
		 ['0123456789abcdef' includes: (string at: i2)] whileTrue: [i2 := i2 + 1].
		 string := string
					copyReplaceFrom: i1 + 4
					to: i2 - 1
					with: (aSymbolManager lookupCHexString: (string copyFrom: i1 + 4 to: i2 - 1))].
	(i1 := string indexOfSubCollection: '%ss:0x') > 0 ifTrue:
		[i2 := i1 + 6.
		 ['0123456789abcdef' includes: (string at: i2)] whileTrue: [i2 := i2 + 1].
		 ((string at: i2) = $(
		 and: [(string at: i2 + 1) = $%]) ifTrue:
			[v := Integer readFrom: (ReadStream on: string from: i1 + 6 to: i2 - 1) base: 16.
			string := string
						copyReplaceFrom: i1
						to: i2 - 1
						with: ((v bitAnd: (1 bitShift: 31) - 1) - (v bitAnd: (1 bitShift: 31))) printString]].
	(i1 := string indexOfSubCollection: '$0x') > 0 ifTrue:
		[i2 := i1 + 3.
		 ['0123456789abcdef' includes: (string at: i2)] whileTrue: [i2 := i2 + 1].
		 string := string
					copyReplaceFrom: i1 + 1
					to: i2 - 1
					with: (aSymbolManager lookupCHexString: (string copyFrom: i1 + 1 to: i2 - 1))].
	((i1 := string indexOf: $() > 1
	 and: [(string at: i1 + 1) isDigit
	 and: [i1 < (i2 := string indexOf: $))]]) ifTrue:
		[string := string
					copyReplaceFrom: i1 + 1
					to: i2 - 1
					with: (aSymbolManager lookupCHexString: (string copyFrom: i1 + 1 to: i2 - 1))].
	PrintCodeBytes ifFalse:
		[string := string copyFrom: 1 to: (string lastIndexOf: $:) - 2].
	^string
]

{ #category : #accessing }
BochsIA32Alien >> dil [
	^self unsignedByteAt: 497
]

{ #category : #accessing }
BochsIA32Alien >> dil: anUnsignedInteger [
	^self unsignedByteAt: 497 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> dl [
	^self unsignedByteAt: 477
]

{ #category : #accessing }
BochsIA32Alien >> dl: anUnsignedInteger [
	^self unsignedByteAt: 477 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> eax [
	^self unsignedLongAt: 469
]

{ #category : #accessing }
BochsIA32Alien >> eax: anUnsignedInteger [
	^self unsignedLongAt: 469 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> ebp [
	^self unsignedLongAt: 489
]

{ #category : #accessing }
BochsIA32Alien >> ebp: anUnsignedInteger [
	^self unsignedLongAt: 489 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> ebx [
	^self unsignedLongAt: 481
]

{ #category : #accessing }
BochsIA32Alien >> ebx: anUnsignedInteger [
	^self unsignedLongAt: 481 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> ecx [
	^self unsignedLongAt: 473
]

{ #category : #accessing }
BochsIA32Alien >> ecx: anUnsignedInteger [
	^self unsignedLongAt: 473 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> edi [
	^self unsignedLongAt: 497
]

{ #category : #accessing }
BochsIA32Alien >> edi: anUnsignedInteger [
	^self unsignedLongAt: 497 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> edx [
	^self unsignedLongAt: 477
]

{ #category : #accessing }
BochsIA32Alien >> edx: anUnsignedInteger [
	^self unsignedLongAt: 477 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> eflags [
	^self unsignedLongAt: 513
]

{ #category : #accessing }
BochsIA32Alien >> eflags: anUnsignedInteger [
	^self unsignedLongAt: 513 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> eip [
	^self unsignedLongAt: 501
]

{ #category : #accessing }
BochsIA32Alien >> eip: anUnsignedInteger [
	^self unsignedLongAt: 501 put: anUnsignedInteger
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> endianness [
	^#little
]

{ #category : #accessing }
BochsIA32Alien >> esi [
	^self unsignedLongAt: 493
]

{ #category : #accessing }
BochsIA32Alien >> esi: anUnsignedInteger [
	^self unsignedLongAt: 493 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> esp [
	^self unsignedLongAt: 485
]

{ #category : #accessing }
BochsIA32Alien >> esp: anUnsignedInteger [
	^self unsignedLongAt: 485 put: anUnsignedInteger
]

{ #category : #execution }
BochsIA32Alien >> flushICacheFrom: startAddress "<Integer>" to: endAddress [ "<Integer>"
	self primitiveFlushICacheFrom: startAddress To: endAddress
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> fp [
	^self ebp
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> fp: anAddress [
	"Set whatever the processor considers its frame pointer to anAddress."
	self ebp: anAddress
]

{ #category : #execution }
BochsIA32Alien >> frameBuildDeltaBytes [
	"Answer how many words are pushed when a frame is built.  This is for the Cogit's stack alignment checking code."
	^4 "4 bytes pushed for $ebp"
]

{ #category : #'error handling' }
BochsIA32Alien >> handleCallFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a call into a ProcessorSimulationTrap signal."
	|  relativeJump |
	relativeJump := memoryArray longAt: pc + 2 bigEndian: false.
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 5
			address: (pc + 5 + relativeJump) signedIntToLong
			type: #call)
		signal
]

{ #category : #'error handling' }
BochsIA32Alien >> handleExecutionPrimitiveFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Handle an execution primitive failure for an unhandled opcode."
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
BochsIA32Alien >> handleExecutionPrimitiveFailureIn: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress [
	"Handle an execution primitive failure.  Convert out-of-range call and absolute
	 memory read into register instructions into ProcessorSimulationTrap signals."
	"self printIntegerRegistersOn: Transcript"
	"self printRegistersOn: Transcript"
	| pc opcode |
	((pc := self eip) between: minimumAddress and: memoryArray byteSize - 1) ifTrue:
		[opcode := memoryArray byteAt: pc + 1.
		 opcode ~= 16r0f ifTrue:
			[^self
				perform: (OpcodeExceptionMap at: opcode + 1)
				with: pc
				with: memoryArray].
		 opcode := memoryArray byteAt: pc + 2.
		 ^self
				perform: (ExtendedOpcodeExceptionMap at: opcode + 1)
				with: pc
				with: memoryArray].
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
BochsIA32Alien >> handleJmpFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a jmp into a ProcessorSimulationTrap signal."
	|  relativeJump |
	relativeJump := memoryArray longAt: pc + 2 bigEndian: false.
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 5
			address: (pc + 5 + relativeJump) signedIntToLong
			type: #jump)
		signal
]

{ #category : #'error handling' }
BochsIA32Alien >> handleMovALObFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a read into al into a ProcessorSimulationTrap signal."
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 5
			address: (memoryArray unsignedLongAt: pc + 2 bigEndian: false)
			type: #read
			accessor: #al:)
		signal
]

{ #category : #'error handling' }
BochsIA32Alien >> handleMovAXOvFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a read into eax into a ProcessorSimulationTrap signal."
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 5
			address: (memoryArray unsignedLongAt: pc + 2 bigEndian: false)
			type: #read
			accessor: #eax:)
		signal
]

{ #category : #'error handling' }
BochsIA32Alien >> handleMovEbGbFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a byte register write into a ProcessorSimulationTrap signal."
	| modrmByte address |
	modrmByte := memoryArray byteAt: pc + 2.
	(modrmByte bitAnd: 7) ~= 4 ifTrue: "MoveRMbr with r = ESP requires an SIB byte"
		[address := (modrmByte bitAnd: 16rC0)
					caseOf: {
						[0 "ModRegInd"]
						->	[memoryArray unsignedLongAt: pc + 3 bigEndian: false].
						[16r80 "ModRegRegDisp32"]
						->	[(self perform: (#(eax ecx edx ebx esp ebp esi edi) at: (modrmByte bitAnd: 7) + 1))
								+ (memoryArray unsignedLongAt: pc + 3 bigEndian: false)
								bitAnd: 16rFFFFFFFF] }
					otherwise: [^self reportPrimitiveFailure].
		^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 6
				address: address
				type: #write
				accessor: (#(al cl dl bl ah ch dh bh) at: ((modrmByte >> 3 bitAnd: 7) + 1)))
			signal].
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
BochsIA32Alien >> handleMovEvGvFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a register write into a ProcessorSimulationTrap signal."
	| modrmByte |
	^((modrmByte := memoryArray byteAt: pc + 2) bitAnd: 16rC7) = 16r5 "ModRegInd & disp32"
		ifTrue:
			[(ProcessorSimulationTrap
					pc: pc
					nextpc: pc + 6
					address: (memoryArray unsignedLongAt: pc + 3 bigEndian: false)
					type: #write
					accessor: (#(eax ecx edx ebx esp ebp esi edi) at: ((modrmByte >> 3 bitAnd: 7) + 1)))
				signal]
		ifFalse:
			[self reportPrimitiveFailure]
]

{ #category : #'error handling' }
BochsIA32Alien >> handleMovGbEbFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a byte register load into a ProcessorSimulationTrap signal."
	| modrmByte address |
	modrmByte := memoryArray byteAt: pc + 2.
	address := (modrmByte bitAnd: 16rC0)
					caseOf: {
						[0 "ModRegInd"]
						->	[memoryArray unsignedLongAt: pc + 3 bigEndian: false].
						[16r80 "ModRegRegDisp32"]
						->	[(self perform: (#(eax ecx edx ebx esp ebp esi edi) at: (modrmByte bitAnd: 7) + 1))
								+ (memoryArray unsignedLongAt: pc + 3 bigEndian: false)
								bitAnd: 16rFFFFFFFF] }
					otherwise: [^self reportPrimitiveFailure].
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 6
			address: address
			type: #read
			accessor: (#(al: cl: dl: bl: ah: ch: dh: bh:) at: ((modrmByte >> 3 bitAnd: 7) + 1)))
		signal
]

{ #category : #'error handling' }
BochsIA32Alien >> handleMovGvEbFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a register load into a ProcessorSimulationTrap signal."
	| modrmByte mode srcIsSP srcVal dst offset |
	modrmByte := memoryArray byteAt: pc + 3.
	mode := modrmByte >> 6 bitAnd: 3.
	dst := #(eax: ecx: edx: ebx: esp: ebp: esi: edi:) at: ((modrmByte >> 3 bitAnd: 7) + 1).
	mode = 0 ifTrue: "ModRegInd"
		[offset := memoryArray unsignedLongAt: pc + 4. "1-relative"
		 ^(ProcessorSimulationTrap
					pc: pc
					nextpc: pc + 7
					address: offset
					type: #read
					accessor: dst)
				signal].
	srcIsSP := (modrmByte bitAnd: 7) = 4.
	srcVal := self perform: (#(eax ecx edx ebx esp ebp esi edi) at: (modrmByte bitAnd: 7) + 1).
	mode = 1 ifTrue: "ModRegRegDisp8"
		[offset := memoryArray byteAt: pc + (srcIsSP ifTrue: [5] ifFalse: [4]). "1-relative"
		 offset > 127 ifTrue: [offset := offset - 256].
		 ^(ProcessorSimulationTrap
					pc: pc
					nextpc: pc + (srcIsSP ifTrue: [5] ifFalse: [4])
					address: (srcVal + offset bitAnd: 16rFFFFFFFF)
					type: #read
					accessor: dst)
				signal].
	mode = 2 ifTrue: "ModRegRegDisp32"
		[offset := memoryArray unsignedLongAt: pc + (srcIsSP ifTrue: [5] ifFalse: [4]). "1-relative"
		 ^(ProcessorSimulationTrap
					pc: pc
					nextpc: pc + (srcIsSP ifTrue: [8] ifFalse: [7])
					address: (srcVal + offset bitAnd: 16rFFFFFFFF)
					type: #read
					accessor: dst)
				signal].
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
BochsIA32Alien >> handleMovGvEvFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a register load into a ProcessorSimulationTrap signal."
	| modrmByte |
	^(((modrmByte := memoryArray byteAt: pc + 2) bitAnd: 16rC7) = 16r5) "ModRegInd & disp32"
		ifTrue:
			[(ProcessorSimulationTrap
					pc: pc
					nextpc: pc + 6
					address: (memoryArray unsignedLongAt: pc + 3 bigEndian: false)
					type: #read
					accessor: (#(eax: ecx: edx: ebx: esp: ebp: esi: edi:) at: ((modrmByte >> 3 bitAnd: 7) + 1)))
				signal]
		ifFalse:
			[self reportPrimitiveFailure]
]

{ #category : #'error handling' }
BochsIA32Alien >> handleMovObALFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a byte write of al into a ProcessorSimulationTrap signal."
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 5
			address: (memoryArray unsignedLongAt: pc + 2 bigEndian: false)
			type: #write
			accessor: #al)
		signal
]

{ #category : #'error handling' }
BochsIA32Alien >> handleMovOvAXFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a write of eax into a ProcessorSimulationTrap signal."
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 5
			address: (memoryArray unsignedLongAt: pc + 2 bigEndian: false)
			type: #write
			accessor: #eax)
		signal
]

{ #category : #'error handling' }
BochsIA32Alien >> handleRetFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a ret into a ProcessorSimulationTrap signal."
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 1
			address: (memoryArray unsignedLongAt: self esp + 1)
			type: #return
			accessor: #eip:)
		signal
]

{ #category : #'processor setup' }
BochsIA32Alien >> initializeStackFor: aCogit [
"Different cpus need different stack alignment etc, so handle the details here."
	"This is for testing.  On many OS's the stack must remain aligned;
	 e.g. IA32 using SSE requires 16 byte alignment."
	| stackAlignment |
	stackAlignment := 16.
	aCogit setStackAlignment: stackAlignment expectedSPOffset: 0 expectedFPOffset: 8.
	PostBuildStackDelta := stackAlignment > 8
								ifTrue: [stackAlignment - 8]
								ifFalse: [0]
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> integerRegisterState [
	^{	self eax. self ebx. self ecx. self edx. self esp. self ebp. self esi. self edi.
		self eip. self eflags }
]

{ #category : #opcodes }
BochsIA32Alien >> jmpOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA8"
	^16rE9
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> leafRetpcIn: aMemory [
	^aMemory unsignedLongAt: self esp + 1 bigEndian: false
]

{ #category : #opcodes }
BochsIA32Alien >> lockPrefix [
	^16rF0
]

{ #category : #opcodes }
BochsIA32Alien >> movALObOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA7"
	^16rA0
]

{ #category : #opcodes }
BochsIA32Alien >> movAXOvOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA7"
	^16rA1
]

{ #category : #opcodes }
BochsIA32Alien >> movEbGbOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2"
	^16r88
]

{ #category : #opcodes }
BochsIA32Alien >> movEvGvOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA8"
	^16r89
]

{ #category : #opcodes }
BochsIA32Alien >> movGbEbOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2"
	^16r8A
]

{ #category : #opcodes }
BochsIA32Alien >> movGvEbOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A3, pA14"
	^16rB6
]

{ #category : #opcodes }
BochsIA32Alien >> movGvEvOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA8"
	^16r8B
]

{ #category : #opcodes }
BochsIA32Alien >> movObALOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA7"
	^16rA2
]

{ #category : #opcodes }
BochsIA32Alien >> movOvAXOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA7"
	^16rA3
]

{ #category : #opcodes }
BochsIA32Alien >> nopOpcode [
	^16r90
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> pc [
	"Return whatever the processor considers its program counter."
	^self eip
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> pc: anAddress [
	"Set whatever the processor considers its program counter to anAddress."
	self eip: anAddress
]

{ #category : #execution }
BochsIA32Alien >> popWordIn: aMemory [ 
	| sp word |
	word := aMemory unsignedLongAt: (sp := self esp) + 1 bigEndian: false.
	self esp: sp + 4.
	^word
]

{ #category : #execution }
BochsIA32Alien >> postCallArgumentsNumArgs: numArgs "<Integer>" in: memory [ "<ByteArray|Bitmap>"
	"Answer an argument vector of the requested size after a vanilla
	 ABI call.  On IA32 this typically means accessing stacked arguments
	 beyond the pushed return address and saved frame pointer.
	 For compatibility with Cog/Slang we answer unsigned values."
	^(9 to: numArgs * 4 + 5 by: 4) collect:
		[:i|
		memory unsignedLongAt: self ebp + i bigEndian: false]
]

{ #category : #primitives }
BochsIA32Alien >> primitiveDisassembleAt: address inMemory: memoryArray [ "<Bitmap|ByteArray>"
	"Answer an Array of the size and the disassembled code string for the instruction at the current instruction pointer in memory."
	<primitive: 'primitiveDisassembleAtInMemory' module: 'BochsIA32Plugin'>
	^self primitiveFailed
]

{ #category : #primitives }
BochsIA32Alien >> primitiveErrorAndLog [
	"Answer an array of the current error code and log contents"
	<primitive: 'primitiveErrorAndLog' module: 'BochsIA32Plugin'>
	^self primitiveFailed
]

{ #category : #primitives }
BochsIA32Alien >> primitiveFlushICacheFrom: startAddress "<Integer>" To: endAddress [ "<Integer>"
	"Flush the icache in the requested range"
	<primitive: 'primitiveFlushICacheFromTo' module: 'BochsIA32Plugin'>
	^self primitiveFailed
]

{ #category : #primitives }
BochsIA32Alien >> primitiveResetCPU [
	"Reset the receiver to registers all zero, and protected 32-bit mode."
	<primitive: 'primitiveResetCPU' module: 'BochsIA32Plugin'>
	^self reportPrimitiveFailure
]

{ #category : #primitives }
BochsIA32Alien >> primitiveRunInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" maximumAddress: maximimAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Run the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 calls, jumps and memory read/writes into ProcessorSimulationTrap signals."
	<primitive: 'primitiveRunInMemoryMinAddressMaxAddressReadWrite' module: 'BochsIA32Plugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress]
		ifFalse: [self reportPrimitiveFailure]

	"self printRegistersOn: Transcript"
]

{ #category : #primitives }
BochsIA32Alien >> primitiveRunInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Run the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 calls, jumps and memory read/writes into ProcessorSimulationTrap signals."
	<primitive: 'primitiveRunInMemoryMinimumAddressReadWrite' module: 'BochsIA32Plugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress]
		ifFalse: [self reportPrimitiveFailure]

	"self printRegistersOn: Transcript"
]

{ #category : #primitives }
BochsIA32Alien >> primitiveSingleStepInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" maximumAddress: maximimAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Single-step the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 calls, jumps and memory read/writes into ProcessorSimulationTrap signals."
	<primitive: 'primitiveSingleStepInMemoryMinAddressMaxAddressReadWrite' module: 'BochsIA32Plugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress]
		ifFalse: [self reportPrimitiveFailure]
]

{ #category : #primitives }
BochsIA32Alien >> primitiveSingleStepInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Single-step the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 calls, jumps and memory read/writes into ProcessorSimulationTrap signals."
	<primitive: 'primitiveSingleStepInMemoryMinimumAddressReadWrite' module: 'BochsIA32Plugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress]
		ifFalse: [self reportPrimitiveFailure]
]

{ #category : #printing }
BochsIA32Alien >> printFields: fields inRegisterState: registerStateVector on: aStream [
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
BochsIA32Alien >> printIntegerRegistersOn: aStream [
	self printRegisterState: self integerRegisterState on: aStream.
	aStream flush
]

{ #category : #printing }
BochsIA32Alien >> printRegisterState: registerStateVector on: aStream [
	"Print the registers, somewhat nicely formatted"
	| lastIndex |
	"First find out what floating point registers are used, and only print the ones up through the last non-zero one."
	lastIndex := (registerStateVector size to: 11 by: -1) detect: [:i| (registerStateVector at: i) ~= 0] ifNone: [0].
	 lastIndex := lastIndex > 0
					ifTrue: [lastIndex - 10 + 1 // 2 * 3 + 13]
					ifFalse: [13].
	self printFields:
			(#(	eax ebx ecx edx cr
				esp ebp esi edi cr
				eip eflags cr
				xmm0low xmm1low cr
				xmm2low xmm3low cr
				xmm4low xmm5low cr
				xmm6low xmm7low cr )
					copyFrom: 1 to: lastIndex)
		inRegisterState: registerStateVector
		on: aStream
]

{ #category : #printing }
BochsIA32Alien >> printRegisterStateExceptPC: registerStateVector on: aStream [
	self printFields:
			((registerStateVector size < 18
			  or: [(11 to: 18) allSatisfy: [:i| (registerStateVector at: i) isZero]])
				ifTrue:
					[#(	eax ebx ecx edx cr
						esp ebp esi edi cr)]
				ifFalse:
					[#(	eax ebx ecx edx cr
						esp ebp esi edi cr
						xmm0low xmm1low cr
						xmm2low xmm3low cr
						xmm4low xmm5low cr
						xmm6low xmm7low cr )])
		inRegisterState: registerStateVector
		on: aStream
]

{ #category : #execution }
BochsIA32Alien >> pushWord: aValue in: aMemory [
	| sp |
	sp := (self esp: self esp - 4).
	aMemory longAt: sp + 1 put: aValue bigEndian: false
]

{ #category : #accessing }
BochsIA32Alien >> registerAt: index [ 
	^self perform: (#(eax ecx edx ebx esp ebp esi edi) at: index + 1)
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> registerState [
	^{	self eax. self ebx. self ecx. self edx. self esp. self ebp. self esi. self edi.
		self eip. self eflags.
		self xmm0low. self xmm1low. self xmm2low. self xmm3low.
		self xmm4low. self xmm5low. self xmm6low. self xmm7low }
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> registerStateGetters [
	^#(	eax ecx edx ebx esp ebp esi edi eip eflags
		xmm0low xmm1low xmm2low xmm3low
		xmm4low xmm5low xmm6low xmm7low )
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> registerStatePCIndex [
	^9
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> registerStateSetters [
	^#(	eax: ecx: edx: ebx: esp: ebp: esi: edi: eip: eflags:
		xmm0low: xmm1low: xmm2low: xmm3low:
		xmm4low: xmm5low: xmm6low: xmm7low: )
]

{ #category : #execution }
BochsIA32Alien >> reset [
	self primitiveResetCPU.
	"Enable SSE extensions by setting the OSFXSR (Operating System FXSAVE/FXRSTOR Support) bit"
	self cr4: (self cr4 bitOr: 1 << 9)
]

{ #category : #opcodes }
BochsIA32Alien >> retOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA7"
	^16rC3
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> retpcIn: aMemory [
	^aMemory unsignedLongAt: self ebp + 5 bigEndian: false
]

{ #category : #accessing }
BochsIA32Alien >> saveEip [
	^self unsignedLongAt: 1533
]

{ #category : #accessing }
BochsIA32Alien >> saveEsp [
	^self unsignedLongAt: 1537
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> setFramePointer: framePointer stackPointer: stackPointer [
	"Initialize the processor's frame and stack pointers"
	self ebp: framePointer.
	self esp: stackPointer
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> setRegisterState: aRegisterStateArray [
	"N.B. keep in sync with voidRegisterState"
	self eax: (aRegisterStateArray at: 1).
	self ebx: (aRegisterStateArray at: 2).
	self ecx: (aRegisterStateArray at: 3).
	self edx: (aRegisterStateArray at: 4).
	self esp: (aRegisterStateArray at: 5).
	self ebp: (aRegisterStateArray at: 6).
	self esi: (aRegisterStateArray at: 7).
	self edi: (aRegisterStateArray at: 8).
	self eip: (aRegisterStateArray at: 9).
	self eflags: (aRegisterStateArray at: 10).
	self xmm0low: (aRegisterStateArray at: 11).
	self xmm1low: (aRegisterStateArray at: 12).
	self xmm2low: (aRegisterStateArray at: 13).
	self xmm3low: (aRegisterStateArray at: 14).
	self xmm4low: (aRegisterStateArray at: 15).
	self xmm5low: (aRegisterStateArray at: 16).
	self xmm6low: (aRegisterStateArray at: 17).
	self xmm7low: (aRegisterStateArray at: 18)
]

{ #category : #accessing }
BochsIA32Alien >> sil [
	^self unsignedByteAt: 493
]

{ #category : #accessing }
BochsIA32Alien >> sil: anUnsignedInteger [
	^self unsignedByteAt: 493 put: anUnsignedInteger
]

{ #category : #execution }
BochsIA32Alien >> simulateCallOf: address nextpc: nextpc memory: aMemory [
	"Simulate a frame-building call of address.  Build a frame since
	a) this is used for calls into the run-time which are unlikely to be leaf-calls, and
	b) stack alignment needs to be realistic for assert checking for platforms such as Mac OS X"
	self pushWord: nextpc in: aMemory.
	self pushWord: self ebp in: aMemory.
	self ebp: self esp.
	PostBuildStackDelta ~= 0 ifTrue:
		[self esp: self esp - PostBuildStackDelta].
	self eip: address
]

{ #category : #execution }
BochsIA32Alien >> simulateJumpCallOf: address memory: aMemory [
	"Simulate a frame-building jump call of address (i.e. do not push the return pc
	 as this has already been done).  Build a frame since
	a) this is used for calls into the run-time which are unlikely to be leaf-calls, and
	b) stack alignment needs to be realistic for assert checking for platforms such as Mac OS X"
	self pushWord: self ebp in: aMemory.
	self ebp: self esp.
	PostBuildStackDelta ~= 0 ifTrue:
		[self esp: self esp - PostBuildStackDelta].
	self eip: address
]

{ #category : #execution }
BochsIA32Alien >> simulateLeafCallOf: address nextpc: nextpc memory: aMemory [
	self pushWord: nextpc in: aMemory.
	self eip: address
]

{ #category : #execution }
BochsIA32Alien >> simulateLeafReturnIn: aMemory [
	self eip: (self popWordIn: aMemory)
]

{ #category : #execution }
BochsIA32Alien >> simulateReturnIn: aMemory [
	PostBuildStackDelta ~= 0 ifTrue:
		[self esp: self esp + PostBuildStackDelta].
	self ebp: (self popWordIn: aMemory).
	self eip: (self popWordIn: aMemory)
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> smashCallerSavedRegistersWithValuesFrom: base by: step in: aMemory [
	#(eax: ecx: edx:)
	   withIndexDo:
		[:accessor :index|
		self perform: accessor with: index - 1 * step + base]
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> smashRegisterAccessors [
	^#(eax: ebx: ecx: edx: esi: edi:)
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> sp [
	^self esp
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> sp: anAddress [
	"Set whatever the processor considers its stack pointer to anAddress."
	self esp: anAddress
]

{ #category : #accessing }
BochsIA32Alien >> spl [
	^self unsignedByteAt: 485
]

{ #category : #accessing }
BochsIA32Alien >> spl: anUnsignedInteger [
	^self unsignedByteAt: 485 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> stopReason [
	^self unsignedByteAt: 1577
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> voidRegisterState [
	"N.B. keep in sync with setRegisterState:"
	self setRegisterState: (Array new: 18 withAll: 0)
]

{ #category : #'accessing-abstract' }
BochsIA32Alien >> withStackPointersInRegisterState: registerState do: aBinaryBlock [
	^aBinaryBlock value: (registerState at: 5) value: (registerState at: 6)
]

{ #category : #accessing }
BochsIA32Alien >> xmm0high [
	^self unsignedLongLongAt: 1185
]

{ #category : #accessing }
BochsIA32Alien >> xmm0high: anUnsignedInteger [
	^self unsignedLongLongAt: 1185 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm0low [
	^self unsignedLongLongAt: 1177
]

{ #category : #accessing }
BochsIA32Alien >> xmm0low: anUnsignedInteger [
	^self unsignedLongLongAt: 1177 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm1high [
	^self unsignedLongLongAt: 1201
]

{ #category : #accessing }
BochsIA32Alien >> xmm1high: anUnsignedInteger [
	^self unsignedLongLongAt: 1201 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm1low [
	^self unsignedLongLongAt: 1193
]

{ #category : #accessing }
BochsIA32Alien >> xmm1low: anUnsignedInteger [
	^self unsignedLongLongAt: 1193 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm2high [
	^self unsignedLongLongAt: 1217
]

{ #category : #accessing }
BochsIA32Alien >> xmm2high: anUnsignedInteger [
	^self unsignedLongLongAt: 1217 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm2low [
	^self unsignedLongLongAt: 1209
]

{ #category : #accessing }
BochsIA32Alien >> xmm2low: anUnsignedInteger [
	^self unsignedLongLongAt: 1209 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm3high [
	^self unsignedLongLongAt: 1233
]

{ #category : #accessing }
BochsIA32Alien >> xmm3high: anUnsignedInteger [
	^self unsignedLongLongAt: 1233 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm3low [
	^self unsignedLongLongAt: 1225
]

{ #category : #accessing }
BochsIA32Alien >> xmm3low: anUnsignedInteger [
	^self unsignedLongLongAt: 1225 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm4high [
	^self unsignedLongLongAt: 1249
]

{ #category : #accessing }
BochsIA32Alien >> xmm4high: anUnsignedInteger [
	^self unsignedLongLongAt: 1249 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm4low [
	^self unsignedLongLongAt: 1241
]

{ #category : #accessing }
BochsIA32Alien >> xmm4low: anUnsignedInteger [
	^self unsignedLongLongAt: 1241 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm5high [
	^self unsignedLongLongAt: 1265
]

{ #category : #accessing }
BochsIA32Alien >> xmm5high: anUnsignedInteger [
	^self unsignedLongLongAt: 1265 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm5low [
	^self unsignedLongLongAt: 1257
]

{ #category : #accessing }
BochsIA32Alien >> xmm5low: anUnsignedInteger [
	^self unsignedLongLongAt: 1257 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm6high [
	^self unsignedLongLongAt: 1281
]

{ #category : #accessing }
BochsIA32Alien >> xmm6high: anUnsignedInteger [
	^self unsignedLongLongAt: 1281 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm6low [
	^self unsignedLongLongAt: 1273
]

{ #category : #accessing }
BochsIA32Alien >> xmm6low: anUnsignedInteger [
	^self unsignedLongLongAt: 1273 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm7high [
	^self unsignedLongLongAt: 1297
]

{ #category : #accessing }
BochsIA32Alien >> xmm7high: anUnsignedInteger [
	^self unsignedLongLongAt: 1297 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien >> xmm7low [
	^self unsignedLongLongAt: 1289
]

{ #category : #accessing }
BochsIA32Alien >> xmm7low: anUnsignedInteger [
	^self unsignedLongLongAt: 1289 put: anUnsignedInteger
]
