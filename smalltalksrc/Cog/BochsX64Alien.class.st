"
I am a wrapper around the Bochs C++ x86_64 CPU emulator.
"
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

{ #category : #'instance creation' }
BochsX64Alien class >> implementationClass [
	^Smalltalk wordSize = 8 ifTrue: [BochsX64Alien64] ifFalse: [self]
]

{ #category : #'class initialization' }
BochsX64Alien class >> initialize [
	"BochsX64Alien initialize"
	| it |
	it := self basicNew.
	OpcodeExceptionMap := Array new: 256 withAll: #handleExecutionPrimitiveFailureAt:in:rex:.
	OpcodeExceptionMap
		at: 1 + it twoByteEscape				put: #handleTwoByteEscapeFailureAt:in:rex:;
		at: 1 + it operandSizeOverridePrefix	put: #handleOperandSizeOverridePrefixFailureAt:in:rex:;
		at: 1 + it callOpcode		put: #handleCallFailureAt:in:rex:;
		at: 1 + it jmpOpcode		put: #handleJmpFailureAt:in:rex:;
		at: 1 + it retOpcode		put: #handleRetFailureAt:in:rex:;
		at: 1 + it movALObOpcode	put: #handleMovALObFailureAt:in:rex:;
		at: 1 + it movAXOvOpcode	put: #handleMovAXOvFailureAt:in:rex:;
		at: 1 + it movObALOpcode	put: #handleMovObALFailureAt:in:rex:;
		at: 1 + it movOvAXOpcode	put: #handleMovOvAXFailureAt:in:rex:;
		at: 1 + it movGvEvOpcode	put: #handleMovGvEvFailureAt:in:rex:;
		at: 1 + it movEvGvOpcode	put: #handleMovEvGvFailureAt:in:rex:;
		at: 1 + it movGbEbOpcode	put: #handleMovGbEbFailureAt:in:rex:;
		at: 1 + it movEbGbOpcode	put: #handleMovEbGbFailureAt:in:rex:;
		at: 1 + 16rFE				put: #handleGroup4FailureAt:in:rex:; "Table A6 One-Byte and Two-Byte Opcode ModRM Extensions"
		at: 1 + 16rFF				put: #handleGroup5FailureAt:in:rex:. "Table A6 One-Byte and Two-Byte Opcode ModRM Extensions"
	ExtendedOpcodeExceptionMap := Array new: 256 withAll: #handleExecutionPrimitiveFailureAt:in:rex:.
	ExtendedOpcodeExceptionMap
		at: 1 + it movGvEbOpcode put: #handleMovGvEbFailureAt:in:rex:
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

{ #category : #accessing }
BochsX64Alien >> al [
	^self unsignedByteAt: 469
]

{ #category : #accessing }
BochsX64Alien >> al: anUnsignedInteger [
	^self unsignedByteAt: 469 put: anUnsignedInteger
]

{ #category : #'Cog API' }
BochsX64Alien >> bitsInWord [
	^64
]

{ #category : #accessing }
BochsX64Alien >> bl [
	^self unsignedByteAt: 493
]

{ #category : #accessing }
BochsX64Alien >> bl: anUnsignedInteger [
	^self unsignedByteAt: 493 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> bpl [
	^self unsignedByteAt: 509
]

{ #category : #accessing }
BochsX64Alien >> bpl: anUnsignedInteger [
	^self unsignedByteAt: 509 put: anUnsignedInteger
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> cResultRegister: aValue [
	^self rax: aValue
]

{ #category : #opcodes }
BochsX64Alien >> callOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA8"
	^16rE8
]

{ #category : #accessing }
BochsX64Alien >> cl [
	^self unsignedByteAt: 477
]

{ #category : #accessing }
BochsX64Alien >> cl: anUnsignedInteger [
	^self unsignedByteAt: 477 put: anUnsignedInteger
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

{ #category : #disassembly }
BochsX64Alien >> decorateDisassembly: anInstructionString for: aSymbolManager "<Cogit>" fromAddress: address [
	| string i1 i2 v o extra |
	string := PrintCodeBytes
				ifTrue: [anInstructionString]
				ifFalse: [anInstructionString copyFrom: 1 to: (anInstructionString lastIndexOf: $:) - 1]. "trailing space useful for parsing numbers"
	aSymbolManager relativeBaseForDisassemblyInto:
		[:baseAddress :baseName|
		string := baseName, '+', (address - baseAddress printStringBase: 16 length: 4 padded: true), (string copyFrom: (string indexOf: $:) + 1 to: string size)].
	((i1 := string indexOfSubCollection: '%ds:(') > 0
	or: [(i1 := string indexOfSubCollection: '%ss:(') > 0]) ifTrue:
		[string := string copyReplaceFrom: i1 to: i1 + 3 with: ''].
	(i1 := string indexOfSubCollection: '%ds:0x') > 0 ifTrue:
		[i2 := i1 + 6.
		 ['0123456789abcdef' includes: (string at: i2)] whileTrue: [i2 := i2 + 1].
		 (v := string copyFrom: i2 to: (i2 + 5 min: string size)) = '(%rbx)' ifTrue:
			[o := Integer readFrom: (ReadStream on: string from: i1 + 6 to: i2 - 1) base: 16.
		 	 (aSymbolManager lookupAddress: aSymbolManager varBaseAddress + o) ifNotNil:
				[:varName| extra := ' = ', varName]].
		 v = '(%rip)' ifTrue:
			[o := anInstructionString size - (anInstructionString lastIndexOf: $:) - 1 / 3. "Count number of instruction bytes to find size of instruction"
			 o := o + address. "Add address of instruction"
			 o := o + (Integer readFrom: (ReadStream on: string from: i1 + 6 to: i2 - 1) base: 16) signedIntFromLong64. "Add offset to yield pc-relative address"
		 	 (aSymbolManager lookupAddress: o) ifNotNil:
				[:methodName| extra := ' = ', methodName]].
		 v = ReceiverResultRegDereference ifTrue:
			[o := Integer readFrom: (ReadStream on: string from: i1 + 6 to: i2 - 1) base: 16.
		 	 (aSymbolManager lookupInstVarOffset: o) ifNotNil:
				[:varName| string := string copyReplaceFrom: i1 to: i2 - 1 with: varName,'@',o printString. i2 := 0]].
		 i2 ~= 0 ifTrue:
			[string := string
				copyReplaceFrom: i1
				to: i2 - 1
				with: (aSymbolManager lookupCHexString: (string copyFrom: i1 + 4 to: i2 - 1))]].
	(i1 := string indexOfSubCollection: '%ss:0x') > 0 ifTrue:
		[i2 := i1 + 6.
		 ['0123456789abcdef' includes: (string at: i2)] whileTrue: [i2 := i2 + 1].
		 ((string at: i2) = $(
		  and: [(string at: i2 + 1) = $%]) ifTrue:
			[o := Integer readFrom: (ReadStream on: string from: i1 + 6 to: i2 - 1) base: 16.
			 o := (o bitAnd: (1 bitShift: 31) - 1) - (o bitAnd: (1 bitShift: 31)).
			 ((string copyFrom: i2 to: (i2 + 5 min: string size)) = '(%rbp)' and: [PrintTempNames]) ifTrue:
				[(aSymbolManager lookupFrameOffset: o) ifNotNil:
					[:varName| string := string copyReplaceFrom: i1 to: i2 - 1 with: varName,'@',o printString. i2 := 0].
			i2 ~= 0 ifTrue: [string := string copyReplaceFrom: i1 to: i2 - 1 with: o printString]]]].
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
					with: (aSymbolManager lookupCHexString: (string copyFrom: i1 + 1 to: i2 - 1)).
		 i1 := string indexOfSubCollection: '+0x'. "calls & jumps"
		 i1 > 0 ifTrue:
			[o := Integer readFrom: (i2 := ReadStream on: string from: i1 + 3 to: string size) base: 16.
			 o := ((o bitAnd: (1 bitShift: 63) - 1) - (o bitAnd: (1 bitShift: 63))) printStringRadix: 16.
			 o := o first = $1
					ifTrue: [o copyReplaceFrom: 1 to: 3 with: '+0x']
					ifFalse: [o copyReplaceFrom: 2 to: 4 with: '0x'].
			 string := string copyReplaceFrom: i1 to: i2 position with: o]].
	^extra
		ifNil: [string]
		ifNotNil:
			[PrintCodeBytes
				ifTrue: [i1 := string lastIndexOf: $:.
						string copyReplaceFrom: i1 - 1 to: i1 - 2 with: extra]
				ifFalse: [string, ';', extra]]
]

{ #category : #accessing }
BochsX64Alien >> dil [
	^self unsignedByteAt: 525
]

{ #category : #accessing }
BochsX64Alien >> dil: anUnsignedInteger [
	^self unsignedByteAt: 525 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> dl [
	^self unsignedByteAt: 485
]

{ #category : #accessing }
BochsX64Alien >> dl: anUnsignedInteger [
	^self unsignedByteAt: 485 put: anUnsignedInteger
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> endianness [
	^#little
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> floatingPointRegisterStateSetters [
	^#(	xmm0low: xmm1low: xmm2low: xmm3low:
		xmm4low: xmm5low: xmm6low: xmm7low:
		xmm9low: xmm9low: xmm10low: xmm11low:
		xmm12low: xmm13low: xmm14low: xmm15low:)
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
BochsX64Alien >> handleCallFailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Convert an execution primitive failure for a call into a ProcessorSimulationTrap signal."
	| relativeJump |
	self assert: rexByteOrNil isNil.
	relativeJump := memoryArray longAt: pc + 2 bigEndian: false.
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 5
			address: (pc + 5 + relativeJump) signedIntToLong64
			type: #call)
		signal
]

{ #category : #'error handling' }
BochsX64Alien >> handleExecutionPrimitiveFailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Handle an execution primitive failure for an unhandled opcode."
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
BochsX64Alien >> handleExecutionPrimitiveFailureIn: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress [
	"Handle an execution primitive failure.  Convert out-of-range call and absolute
	 memory read into register instructions into ProcessorSimulationTrap signals."
	"self printIntegerRegistersOn: Transcript"
	"self printRegistersOn: Transcript"
	| pc opcode rexByteOrNil offset |
	((pc := self rip) between: minimumAddress and: memoryArray byteSize - 1) ifTrue:
		[opcode := memoryArray byteAt: pc + (offset := 1).
		 (opcode bitAnd: 16rF8) = self rexPrefix ifTrue: "skip rex prefix if present"
			[rexByteOrNil := opcode.
			 opcode := memoryArray byteAt: pc + (offset := 2)].
		 ^self
			perform: (OpcodeExceptionMap at: opcode + 1)
			with: pc
			with: memoryArray
			with: rexByteOrNil].
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
BochsX64Alien >> handleGroup5FailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Convert an execution primitive failure for a group 5 instruction into the relevant ProcessorSimulationTrap signal."
	| modrmByte getter |
	self assert: rexByteOrNil isNil.
	modrmByte := memoryArray byteAt: pc + 2.
	(modrmByte >> 3 bitAnd: 7)
		caseOf: {
			[2 "Call Ev"]	->	[getter := self registerStateGetters at: (modrmByte bitAnd: 7) + 1.
							^(ProcessorSimulationTrap
									pc: pc
									nextpc: pc + 2
									address: (self perform: getter)
									type: #call)
								signal].
			[4 "Jump Ev"]	->	[getter := self registerStateGetters at: (modrmByte bitAnd: 7) + 1.
							^(ProcessorSimulationTrap
									pc: pc
									nextpc: pc + 2
									address: (self perform: getter)
									type: #jump)
								signal] }
]

{ #category : #'error handling' }
BochsX64Alien >> handleJmpFailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Convert an execution primitive failure for a jmp into a ProcessorSimulationTrap signal."
	|  relativeJump |
	self assert: rexByteOrNil isNil.
	relativeJump := memoryArray longAt: pc + 2 bigEndian: false.
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 5
			address: (pc + 5 + relativeJump) signedIntToLong64
			type: #jump)
		signal
]

{ #category : #'error handling' }
BochsX64Alien >> handleMovALObFailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Convert an execution primitive failure for a read into al into a ProcessorSimulationTrap signal."
	rexByteOrNil ifNotNil:
		[self assert: rexByteOrNil = 16r48.
		 ^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 10
				address: (memoryArray unsignedLong64At: pc + 3)
				type: #read
				accessor: #al:)
			signal].
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 5
			address: (memoryArray unsignedLongAt: pc + 2)
			type: #read
			accessor: #al:)
		signal
]

{ #category : #'error handling' }
BochsX64Alien >> handleMovAXOvFailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Convert an execution primitive failure for a read into rax/eax into a ProcessorSimulationTrap signal."
	rexByteOrNil ifNotNil:
		[self assert: rexByteOrNil = 16r48.
		 ^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 10
				address: (memoryArray unsignedLong64At: pc + 3)
				type: #read
				accessor: #rax:)
			signal].
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 5
			address: (memoryArray unsignedLongAt: pc + 2)
			type: #read
			accessor: #eax:)
		signal
]

{ #category : #'error handling' }
BochsX64Alien >> handleMovEbGbFailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Convert an execution primitive failure for a byte register write into a ProcessorSimulationTrap signal."
	| modrmByte offset size baseReg srcReg |
	modrmByte := memoryArray byteAt: pc + 3.
	(modrmByte bitAnd: 16rC0) caseOf: {
		[16r80 "ModRegRegDisp32"] -> [offset := memoryArray unsignedLongAt: pc + 4 bigEndian: false.
										 size := 7].
		[16r40 "ModRegRegDisp8"] -> [offset := memoryArray byteAt: pc + 4.
										offset > 127 ifTrue: [offset := offset - 256].
										 size := 4].
		[16r0 "ModRegInd"] -> [offset := 0.
								size := 3]}
		otherwise: [self reportPrimitiveFailure].
	srcReg := (modrmByte >> 3 bitAnd: 7) + ((rexByteOrNil bitAnd: 4) bitShift: 1).
	baseReg := (modrmByte bitAnd: 7) + ((rexByteOrNil bitAnd: 1) bitShift: 3).
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + size
			address: (((self perform: (self registerStateGetters at: baseReg + 1))
					+ offset)
						bitAnd: 16rFFFFFFFFFFFFFFFF)
			type: #write
			accessor: (#(al cl dl bl spl bpl sil dil r8l r9l r10l r11l r12l r13l r14l r15l) at: srcReg + 1))
		signal
]

{ #category : #'error handling' }
BochsX64Alien >> handleMovEvGvFailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Convert an execution primitive failure for a register write into a ProcessorSimulationTrap signal."
	| modrmByte getter base offset |
	self assert: rexByteOrNil notNil.
	modrmByte := memoryArray byteAt: pc + 3.
	getter := self registerStateGetters at: ((modrmByte >> 3 bitAnd: 7) + ((rexByteOrNil bitAnd: 4) << 1) + 1).
	(modrmByte bitAnd: 16rC7) = 16r5 ifTrue: "ModRegInd & disp32"
		[^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 7
				address: (memoryArray unsignedLongAt: pc + 4 bigEndian: false)
				type: #write
				accessor: getter)
			signal].
	(modrmByte bitAnd: 16rC0) = 16r80 ifTrue: "ModRegRegDisp32"
		[offset := memoryArray longAt: pc + 4 bigEndian: false.
		 base := self registerStateGetters at: ((modrmByte bitAnd: 7) + ((rexByteOrNil bitAnd: 1) << 3) + 1).
		 ^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 7
				address: (self perform: base) + offset
				type: #write
				accessor: getter)
			signal].
	(modrmByte bitAnd: 16rC0) = 16r40 ifTrue: "ModRegRegDisp8"
		[offset := memoryArray unsignedByteAt: pc + 4.
		 offset > 127 ifTrue: [offset := offset - 256].
		 base := self registerStateGetters at: ((modrmByte bitAnd: 7) + ((rexByteOrNil bitAnd: 1) << 3) + 1).
		 ^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4
				address: (self perform: base) + offset
				type: #write
				accessor: getter)
			signal].
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
BochsX64Alien >> handleMovGbEbFailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Convert an execution primitive failure for a byte register load into a ProcessorSimulationTrap signal."
	| modrmByte offset size |
	modrmByte := memoryArray byteAt: pc + 3.
	(modrmByte bitAnd: 16rC0) caseOf: {
		[16r80 "ModRegRegDisp32"] -> [offset := memoryArray unsignedLongAt: pc + 4 bigEndian: false.
										 size := 7].
		[16r40 "ModRegRegDisp8"] -> [offset := memoryArray byteAt: pc + 4.
										offset > 127 ifTrue: [offset := offset - 256].
										 size := 4] }
		otherwise: [self reportPrimitiveFailure].
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + size
			address: (((self perform: (self registerStateGetters at: (modrmByte bitAnd: 7) + ((rexByteOrNil bitAnd: 1) bitShift: 3) + 1))
					+ offset)
						bitAnd: 16rFFFFFFFFFFFFFFFF)
			type: #read
			accessor: (#(al: cl: dl: bl: spl: bpl: sil: dil: r8l: r9l: r10l: r11l: r12l: r13l: r14l: r15l:) at: ((modrmByte >> 3 bitAnd: 7) + ((rexByteOrNil bitAnd: 4) bitShift: 1) + 1)))
		signal
]

{ #category : #'error handling' }
BochsX64Alien >> handleMovGvEbFailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Convert an execution primitive failure for a register load into a ProcessorSimulationTrap signal."
	| modrmByte mode srcIsSP srcVal dst offset |
	self shouldBeImplemented.
	modrmByte := memoryArray byteAt: pc + 3.
	mode := modrmByte >> 6 bitAnd: 3.
	srcIsSP := (modrmByte bitAnd: 7) = 4.
	srcVal := self perform: (#(eax ecx edx ebx esp ebp esi edi) at: (modrmByte bitAnd: 7) + 1).
	dst := #(eax: ecx: edx: ebx: esp: ebp: esi: edi:) at: ((modrmByte >> 3 bitAnd: 7) + 1).
	mode = 1 ifTrue: "ModRegRegDisp8"
		[offset := memoryArray byteAt: pc + (srcIsSP ifTrue: [5] ifFalse: [4]). "1-relative"
		 offset > 127 ifTrue: [offset := offset - 256].
		 ^(ProcessorSimulationTrap
					pc: pc
					nextpc: pc + (srcIsSP ifTrue: [5] ifFalse: [4])
					address: ((srcVal + offset) bitAnd: 16rFFFFFFFF)
					type: #read
					accessor: dst)
				signal].
	mode = 2 ifTrue: "ModRegRegDisp32"
		[offset := memoryArray unsignedLongAt: pc + (srcIsSP ifTrue: [5] ifFalse: [4]). "1-relative"
		 ^(ProcessorSimulationTrap
					pc: pc
					nextpc: pc + (srcIsSP ifTrue: [8] ifFalse: [7])
					address: ((srcVal + offset) bitAnd: 16rFFFFFFFF)
					type: #read
					accessor: dst)
				signal].
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
BochsX64Alien >> handleMovGvEvFailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Convert an execution primitive failure for a register load into a ProcessorSimulationTrap signal."
	| modrmByte getter setter offset |
	self assert: rexByteOrNil notNil.
	modrmByte := memoryArray byteAt: pc + 3.
	setter := self registerStateSetters at: ((modrmByte >> 3 bitAnd: 7) + ((rexByteOrNil bitAnd: 4) << 1) + 1).
	(modrmByte bitAnd: 16rC7) = 16r5 ifTrue: "ModRegInd & disp32"
		[^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 7
				address: (memoryArray unsignedLongAt: pc + 4 bigEndian: false)
				type: #read
				accessor: setter)
			signal].
	getter := self registerStateGetters at: ((modrmByte bitAnd: 7) + ((rexByteOrNil bitAnd: 1) << 3) + 1).
	(modrmByte bitAnd: 16rC0) = 16r80 ifTrue: "ModRegRegDisp32"
		[offset := memoryArray longAt: pc + 4 bigEndian: false.
		 ^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 7
				address: (self perform: getter) + offset
				type: #read
				accessor: setter)
			signal].
	(modrmByte bitAnd: 16rC0) = 16r40 ifTrue: "ModRegRegDisp8"
		[offset := memoryArray byteAt: pc + 4.
		 offset > 16r7F ifTrue:
			[offset := offset - 16r100].
		 ^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4
				address: (self perform: getter) + offset
				type: #read
				accessor: setter)
			signal].
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
BochsX64Alien >> handleMovObALFailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Convert an execution primitive failure for a write of al into a ProcessorSimulationTrap signal."
	self assert: rexByteOrNil = 16r48.
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 10
			address: (memoryArray unsignedLong64At: pc + 3)
			type: #write
			accessor: #al)
		signal
]

{ #category : #'error handling' }
BochsX64Alien >> handleMovOvAXFailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Convert an execution primitive failure for a write of rax into a ProcessorSimulationTrap signal."
	self assert: rexByteOrNil = 16r48.
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 10
			address: (memoryArray unsignedLong64At: pc + 3)
			type: #write
			accessor: #rax)
		signal
]

{ #category : #'error handling' }
BochsX64Alien >> handleRetFailureAt: pc "<Integer>" in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [ "<Integer|nil>"
	"Convert an execution primitive failure for a ret into a ProcessorSimulationTrap signal."
	self shouldBeImplemented.
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 1
			address: (memoryArray unsignedLong64At: self rsp + 1)
			type: #return
			accessor: #rip:)
		signal
]

{ #category : #'error handling' }
BochsX64Alien >> handleTwoByteEscapeFailureAt: pc in: memoryArray "<Bitmap|ByteArray>" rex: rexByteOrNil [
	"Handle an execution primitive failure for the 0f prefix.  Convert failures into ProcessorSimulationTrap signals."
	"self printIntegerRegistersOn: Transcript"
	"self printRegistersOn: Transcript"
	| opcode offset |
	"assume 0fh opcode or 0fh rex opcode"
	offset := rexByteOrNil ifNil: [1] ifNotNil: [2].
	opcode := memoryArray byteAt: pc + offset + 1.
	 ^self
			perform: (ExtendedOpcodeExceptionMap at: opcode + 1)
			with: pc
			with: memoryArray
			with: rexByteOrNil
]

{ #category : #'processor setup' }
BochsX64Alien >> initializeStackFor: aCogit [
	"Different cpus need different stack alignment etc, so handle the details here."
	"From the System V ABI:
	 3.2.2 The Stack Frame
	 ...	The end of the input argument area shall be aligned on a 16 (32, if __m256 is
		passed on stack) byte boundary. In other words, the value (%rsp + 8) is always
		a multiple of 16 (32) when control is transferred to the function entry point."
	| stackAlignment |
	stackAlignment := 32.
	aCogit setStackAlignment: stackAlignment expectedSPOffset: 0 expectedFPOffset: 16.
	PostBuildStackDelta := stackAlignment > 16
								ifTrue: [stackAlignment - 16]
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
	^16rA0
]

{ #category : #opcodes }
BochsX64Alien >> movAXOvOpcode [
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
	^16rA2
]

{ #category : #opcodes }
BochsX64Alien >> movOvAXOpcode [
	"[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2B: Instruction Set Reference, N-Z.
		table A2, pA7"
	^16rA3
]

{ #category : #opcodes }
BochsX64Alien >> nopOpcode [
	^16r90
]

{ #category : #opcodes }
BochsX64Alien >> operandSizeOverridePrefix [
	^16r66
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

{ #category : #execution }
BochsX64Alien >> popWordIn: aMemory [ 
	| sp word |
	word := aMemory long64At: (sp := self rsp) + 1.
	self rsp: sp + 8.
	^word
]

{ #category : #execution }
BochsX64Alien >> postCallArgumentsNumArgs: numArgs "<Integer>" in: memory [ "<ByteArray|Bitmap>"
	"Answer an argument vector of the requested size after a Win64 or SysV
	 ABI call.  On X64 this simply means accessing register arguments.
	 For compatibility with Cog/Slang we answer unsigned values."
	self assert: numArgs <= 4.
	^((CogX64Compiler isSysV
				ifTrue: [#(rdi rsi rdx rcx r8 r9)]
				ifFalse: [#(rcx rdx r8 r9)]) copyFrom: 1 to: numArgs) collect:
		[:getter|
		self perform: getter]
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
	"Print the registers, somewhat nicely formatted"
	| lastIndex |
	"First find out what floating point registers are used, and only print the ones up through the last non-zero one."
	lastIndex := (registerStateVector size to: 19 by: -1) detect: [:i| (registerStateVector at: i) ~= 0] ifNone: [0].
	lastIndex := lastIndex > 0
					ifTrue: [lastIndex - 18 + 1 // 2 * 3 + 23]
					ifFalse: [23].
	self printFields:
			(#(	rax rbx rcx rdx cr
				rsp rbp rsi rdi cr
				r8 r9 r10 r11 cr
				r12 r13 r14 r15 cr
				rip rflags cr
				xmm0low xmm1low cr
				xmm2low xmm3low cr
				xmm4low xmm5low cr
				xmm6low xmm7low cr
				xmm8low xmm9low cr
				xmm10low xmm11low cr
				xmm12low xmm13low cr
				xmm14low xmm15low cr )
					copyFrom: 1 to: lastIndex)
		inRegisterState: registerStateVector
		on: aStream
]

{ #category : #printing }
BochsX64Alien >> printRegisterStateExceptPC: registerStateVector on: aStream [
	self printFields:
			((registerStateVector size < 34
			  or: [(19 to: 34) allSatisfy: [:i| (registerStateVector at: i) isZero]])
				ifTrue:
					[#(	rax rbx rcx rdx cr
						rsp rbp rsi rdi cr
						r8 r9 r10 r11 cr
						r12 r13 r14 r15 cr)]
				ifFalse:
					[#(	rax rbx rcx rdx cr
						rsp rbp rsi rdi cr
						r8 r9 r10 r11 cr
						r12 r13 r14 r15 cr
						xmm0low xmm1low cr
						xmm2low xmm3low cr
						xmm4low xmm5low cr
						xmm6low xmm7low cr )])
		inRegisterState: registerStateVector
		on: aStream
]

{ #category : #execution }
BochsX64Alien >> pushWord: aValue in: aMemory [
	| sp |
	sp := (self rsp: self rsp - 8).
	aMemory long64At: sp + 1 put: aValue
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
BochsX64Alien >> r10l [
	^self unsignedByteAt: 549
]

{ #category : #accessing }
BochsX64Alien >> r10l: anUnsignedInteger [
	^self unsignedByteAt: 549 put: anUnsignedInteger
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
BochsX64Alien >> r11l [
	^self unsignedByteAt: 557
]

{ #category : #accessing }
BochsX64Alien >> r11l: anUnsignedInteger [
	^self unsignedByteAt: 557 put: anUnsignedInteger
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
BochsX64Alien >> r12l [
	^self unsignedByteAt: 565
]

{ #category : #accessing }
BochsX64Alien >> r12l: anUnsignedInteger [
	^self unsignedByteAt: 565 put: anUnsignedInteger
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
BochsX64Alien >> r13l [
	^self unsignedByteAt: 573
]

{ #category : #accessing }
BochsX64Alien >> r13l: anUnsignedInteger [
	^self unsignedByteAt: 573 put: anUnsignedInteger
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
BochsX64Alien >> r14l [
	^self unsignedByteAt: 581
]

{ #category : #accessing }
BochsX64Alien >> r14l: anUnsignedInteger [
	^self unsignedByteAt: 581 put: anUnsignedInteger
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
BochsX64Alien >> r15l [
	^self unsignedByteAt: 589
]

{ #category : #accessing }
BochsX64Alien >> r15l: anUnsignedInteger [
	^self unsignedByteAt: 589 put: anUnsignedInteger
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
BochsX64Alien >> r8l [
	^self unsignedByteAt: 533
]

{ #category : #accessing }
BochsX64Alien >> r8l: anUnsignedInteger [
	^self unsignedByteAt: 533 put: anUnsignedInteger
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
BochsX64Alien >> r9l [
	^self unsignedByteAt: 541
]

{ #category : #accessing }
BochsX64Alien >> r9l: anUnsignedInteger [
	^self unsignedByteAt: 541 put: anUnsignedInteger
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
		self xmm4low. self xmm5low. self xmm6low. self xmm7low.
		self xmm8low. self xmm9low. self xmm10low. self xmm11low.
		self xmm12low. self xmm13low. self xmm14low. self xmm5low }
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> registerStateGetters [
	^#(	rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r10 r11 r12 r13 r14 r15
		rip rflags
		xmm0low xmm1low xmm2low xmm3low
		xmm4low xmm5low xmm6low xmm7low
		xmm9low xmm9low xmm10low xmm11low
		xmm12low xmm13low xmm14low xmm15low)
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> registerStatePCIndex [
	^17
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> registerStateSetters [
	^#(	rax: rcx: rdx: rbx: rsp: rbp: rsi: rdi: r8: r9: r10: r11: r12: r13: r14: r15:
		rip: rflags:
		xmm0low: xmm1low: xmm2low: xmm3low:
		xmm4low: xmm5low: xmm6low: xmm7low:
		xmm9low: xmm9low: xmm10low: xmm11low:
		xmm12low: xmm13low: xmm14low: xmm15low:)
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

{ #category : #'accessing-abstract' }
BochsX64Alien >> retpcIn: aMemory [
	^aMemory long64At: self rbp + 9
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

{ #category : #accessing }
BochsX64Alien >> sil [
	^self unsignedByteAt: 517
]

{ #category : #accessing }
BochsX64Alien >> sil: anUnsignedInteger [
	^self unsignedByteAt: 517 put: anUnsignedInteger
]

{ #category : #execution }
BochsX64Alien >> simulateCallOf: address nextpc: nextpc memory: aMemory [
	"Simulate a frame-building call of address.  Build a frame since
	a) this is used for calls into the run-time which are unlikely to be leaf-calls, and
	b) stack alignment needs to be realistic for assert checking

	From the System V ABI:
	 3.2.2 The Stack Frame
	 ...	The end of the input argument area shall be aligned on a 16 (32, if __m256 is
		passed on stack) byte boundary. In other words, the value (%rsp + 8) is always
		a multiple of 16 (32) when control is transferred to the function entry point."
	self pushWord: nextpc in: aMemory.
	self pushWord: self rbp in: aMemory.
	self rbp: self rsp.
	PostBuildStackDelta ~= 0 ifTrue:
		[self rsp: self rsp - PostBuildStackDelta].
	self rip: address
]

{ #category : #execution }
BochsX64Alien >> simulateJumpCallOf: address memory: aMemory [
	"Simulate a frame-building jump call of address (i.e. do not push the return pc
	 as this has already been done).  Build a frame since
	a) this is used for calls into the run-time which are unlikely to be leaf-calls, and
	b) stack alignment needs to be realistic for assert checking for platforms such as Mac OS X"
	self pushWord: self rbp in: aMemory.
	self rbp: self rsp.
	PostBuildStackDelta ~= 0 ifTrue:
		[self rsp: self rsp - PostBuildStackDelta].
	self rip: address
]

{ #category : #execution }
BochsX64Alien >> simulateLeafCallOf: address nextpc: nextpc memory: aMemory [
	self pushWord: nextpc in: aMemory.
	self rip: address
]

{ #category : #execution }
BochsX64Alien >> simulateReturnIn: aMemory [
	PostBuildStackDelta ~= 0 ifTrue:
		[self rsp: self rsp + PostBuildStackDelta].
	self rbp: (self popWordIn: aMemory).
	self rip: (self popWordIn: aMemory)
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> smashCallerSavedRegistersWithValuesFrom: base by: step in: aMemory [
	| volatileRegisters |
	CogX64Compiler isSysV
		ifTrue:
			[volatileRegisters := #(rax: rcx: rdx: rsi: rdi: r8: r9: r10: r11:)]
		ifFalse: "We should also save the registers to the shadow parameter space."
			[volatileRegisters := #(rax: rcx: rdx: r8: r9: r10: r11:).
			 #(rcx rdx r8 r9) withIndexDo:
				[:getter :index|
				 aMemory
					unsignedLong64At: self rbp + 9 + (index * 8) "skip saved fp and retpc; aMemory is 1-relative"
					put: (self perform: getter)]].
	volatileRegisters withIndexDo:
		[:setter :index|
		self perform: setter with: index - 1 * step + base]
]

{ #category : #'accessing-abstract' }
BochsX64Alien >> smashRegisterAccessors [
	^#(rax: rbx: rcx: rdx: rsi: rdi: r8: r9: r10: r11: r12: r13: r14: r15:)
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
BochsX64Alien >> spl [
	^self unsignedByteAt: 501
]

{ #category : #accessing }
BochsX64Alien >> spl: anUnsignedInteger [
	^self unsignedByteAt: 501 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> stopReason [
	^self unsignedByteAt: 1973
]

{ #category : #accessing }
BochsX64Alien >> stopReason: anUnsignedInteger [
	^self unsignedByteAt: 1973 put: anUnsignedInteger
]

{ #category : #opcodes }
BochsX64Alien >> twoByteEscape [
	^16r0f
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
BochsX64Alien >> xmm10high [
	^self unsignedLongLongAt: 1581
]

{ #category : #accessing }
BochsX64Alien >> xmm10high: anUnsignedInteger [
	^self unsignedLongLongAt: 1581 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm10low [
	^self unsignedLongLongAt: 1573
]

{ #category : #accessing }
BochsX64Alien >> xmm10low: anUnsignedInteger [
	^self unsignedLongLongAt: 1573 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm11high [
	^self unsignedLongLongAt: 1597
]

{ #category : #accessing }
BochsX64Alien >> xmm11high: anUnsignedInteger [
	^self unsignedLongLongAt: 1597 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm11low [
	^self unsignedLongLongAt: 1589
]

{ #category : #accessing }
BochsX64Alien >> xmm11low: anUnsignedInteger [
	^self unsignedLongLongAt: 1589 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm12high [
	^self unsignedLongLongAt: 1613
]

{ #category : #accessing }
BochsX64Alien >> xmm12high: anUnsignedInteger [
	^self unsignedLongLongAt: 1613 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm12low [
	^self unsignedLongLongAt: 1605
]

{ #category : #accessing }
BochsX64Alien >> xmm12low: anUnsignedInteger [
	^self unsignedLongLongAt: 1605 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm13high [
	^self unsignedLongLongAt: 1629
]

{ #category : #accessing }
BochsX64Alien >> xmm13high: anUnsignedInteger [
	^self unsignedLongLongAt: 1629 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm13low [
	^self unsignedLongLongAt: 1621
]

{ #category : #accessing }
BochsX64Alien >> xmm13low: anUnsignedInteger [
	^self unsignedLongLongAt: 1621 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm14high [
	^self unsignedLongLongAt: 1645
]

{ #category : #accessing }
BochsX64Alien >> xmm14high: anUnsignedInteger [
	^self unsignedLongLongAt: 1645 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm14low [
	^self unsignedLongLongAt: 1637
]

{ #category : #accessing }
BochsX64Alien >> xmm14low: anUnsignedInteger [
	^self unsignedLongLongAt: 1637 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm15high [
	^self unsignedLongLongAt: 1661
]

{ #category : #accessing }
BochsX64Alien >> xmm15high: anUnsignedInteger [
	^self unsignedLongLongAt: 1661 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm15low [
	^self unsignedLongLongAt: 1653
]

{ #category : #accessing }
BochsX64Alien >> xmm15low: anUnsignedInteger [
	^self unsignedLongLongAt: 1653 put: anUnsignedInteger
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

{ #category : #accessing }
BochsX64Alien >> xmm8high [
	^self unsignedLongLongAt: 1549
]

{ #category : #accessing }
BochsX64Alien >> xmm8high: anUnsignedInteger [
	^self unsignedLongLongAt: 1549 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm8low [
	^self unsignedLongLongAt: 1541
]

{ #category : #accessing }
BochsX64Alien >> xmm8low: anUnsignedInteger [
	^self unsignedLongLongAt: 1541 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm9high [
	^self unsignedLongLongAt: 1565
]

{ #category : #accessing }
BochsX64Alien >> xmm9high: anUnsignedInteger [
	^self unsignedLongLongAt: 1565 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm9low [
	^self unsignedLongLongAt: 1557
]

{ #category : #accessing }
BochsX64Alien >> xmm9low: anUnsignedInteger [
	^self unsignedLongLongAt: 1557 put: anUnsignedInteger
]
