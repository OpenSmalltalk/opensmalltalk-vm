"
I am a wrapper around the ARMulator CPU instance and emulator routines and I give access to disassembling using libopcodes. My C-part must be compiled with -DMODET, because otherwise my offesets are wrong by one field.
"
Class {
	#name : #GdbARMAlien,
	#superclass : #CogProcessorAlien,
	#type : #bytes,
	#classVars : [
		'PostBuildStackDelta'
	],
	#category : #'Cog-Processors'
}

{ #category : #'instance creation' }
GdbARMAlien class >> dataSize [

	^1536
]

{ #category : #debugger }
GdbARMAlien class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #'class initialization' }
GdbARMAlien class >> initialize [
	"GdbARMAlien initialize"

	PostBuildStackDelta := 0.
]

{ #category : #'instance creation' }
GdbARMAlien class >> new [
	^(self atAddress: self primitiveNewCPU) reset
]

{ #category : #primitives }
GdbARMAlien class >> primitiveNewCPU [
	"Answer the address of a new ARMulator C type ARMul_State instance."
	<primitive: 'primitiveNewCPU' module: 'GdbARMPlugin'>
	^self primitiveFailed
]

{ #category : #accessing }
GdbARMAlien class >> setStackAlignmentDelta: 	stackAlignmentDelta [
	"copy of BochsIA32Alien>>#setStackAlignmentDelta:, because I don't know yet what it's effect is."
	self assert: stackAlignmentDelta isPowerOfTwo.
	PostBuildStackDelta :=  stackAlignmentDelta > 8
								ifTrue: [stackAlignmentDelta - 8]
								ifFalse: [0]
]

{ #category : #'Cog API' }
GdbARMAlien >> abstractInstructionCompilerClass [
	^CogARMCompiler
]

{ #category : #'Cog API' }
GdbARMAlien >> bitsInWord [
	^32
]

{ #category : #opcodes }
GdbARMAlien >> branchAndLinkOpcodeWithOffset: aNumber [
	
	| offset |
	offset := (aNumber - 8) asInteger.
	(offset between: -33554432 and: 33554428) ifFalse: [self error: 'The offset is to far. ARM does not support such far jumps.'].
	^ 16reb000000 bitOr: (offset >> 2 bitAnd: 16r00FFFFFF)

]

{ #category : #'accessing-abstract' }
GdbARMAlien >> cResultRegister [
	self r0
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> cResultRegister: aValue [
	self r0: aValue
]

{ #category : #accessing }
GdbARMAlien >> cflag [
	^self unsignedLongAt: 577
]

{ #category : #disassembly }
GdbARMAlien >> decorateDisassembly: anInstructionString for: aSymbolManager "<Cogit>" fromAddress: address [
	(anInstructionString endsWith: 'mov	r1, r1')
		ifTrue: [^super decorateDisassembly: 'nop' for: aSymbolManager].
	^super decorateDisassembly: anInstructionString for: aSymbolManager
]

{ #category : #accessing }
GdbARMAlien >> eflags [
	
	^ (((self nflag << 5 bitOr: self zflag << 4) 
			bitOr: self cflag << 3) 
				bitOr: self vflag << 2)
					bitOr: self ifflags
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> endianness [
	^#little
]

{ #category : #execution }
GdbARMAlien >> flushICacheFrom: startAddress "<Integer>" to: endAddress [ "<Integer>"
	self primitiveFlushICacheFrom: startAddress To: endAddress
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> fp [
	"According to the use in SVr4"
	^self r11
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> fp: aNumber [
	"According to SVr4, the frame pointer is stored in r11"
	^self r11: aNumber
]

{ #category : #'error handling' }
GdbARMAlien >> handleCallFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a call into a ProcessorSimulationTrap signal."
	|  relativeJump callAddress |
	((memoryArray byteAt: pc + 4) bitAnd: 16rF) = 16rB "BL opcode"
		ifTrue: ["short jump via BL, therefore we have a 24bit signed integer offset"
			relativeJump := (memoryArray unsignedLongAt: pc + 1 bigEndian: false) bitAnd: 16r00FFFFFF.
			relativeJump := (relativeJump bitAt: 24) = 1 
									ifTrue: [((relativeJump bitOr: 16r3F000000) << 2) signedIntFromLong]
									ifFalse: [relativeJump << 2].
			callAddress := (pc + 8 + relativeJump)]
		
		ifFalse: ["long jump using RISCTempReg"
			"The memoryArray starts indexing from 1, whereas the pc is based on 0-indexing, therefore all access-offsets are one greater than expected"
			callAddress := (memoryArray byteAt: pc + 4) 
								+ ((memoryArray byteAt: pc - 4) << 24) 
								+ ((memoryArray byteAt: pc - 8) << 16) 
								+ ((memoryArray byteAt: pc - 12) << 8)].
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 4
			address: callAddress signedIntToLong
			type: #call)
		signal
]

{ #category : #'error handling' }
GdbARMAlien >> handleExecutionPrimitiveFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Handle an execution primitive failure for an unhandled opcode."
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
GdbARMAlien >> handleExecutionPrimitiveFailureIn: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress [ "<Integer>"
	"Handle an execution primitive failure.  Convert out-of-range call and absolute
	 memory read into register instructions into ProcessorSimulationTrap signals."
	"self printRegistersOn: Transcript"
	| pc |
	((pc := self pc) between: minimumAddress and: memoryArray byteSize - 1) ifTrue:
		[(self instructionTypeAt: pc in: memoryArray)
			caseOf: {
				[#Call] 			-> [^self handleCallFailureAt: pc in: memoryArray].
				[#Jump] 		-> [^self handleJmpFailureAt: pc in: memoryArray].
				[#MoveAwR]	-> [^self handleMoveAwRFailureAt: pc in: memoryArray].
				[#MoveMbrR]	-> [^self handleMoveMbrRFailureAt: pc in: memoryArray].
				[#MoveRAw]	-> [^self handleMoveRAwFailureAt: pc in: memoryArray].
				[#MoveRMbr]	-> [^self handleMoveRMbrFailureAt: pc in: memoryArray].
				[#Ret]			-> [^self handleRetFailureAt: pc in: memoryArray].} 
			otherwise: [^self handleExecutionPrimitiveFailureAt: pc in: memoryArray]].
	((pc := self lr - 4) between: minimumAddress and: memoryArray byteSize - 1) ifTrue:
		[(self instructionTypeAt: pc in: memoryArray)
			caseOf: {
				[#Call] 		-> [^self handleCallFailureAt: pc in: memoryArray].
				[#Jump] 	-> [^self handleJmpFailureAt: pc in: memoryArray].
				[#Ret]		-> [^self handleRetFailureAt: pc in: memoryArray].} 
			otherwise: [^self handleExecutionPrimitiveFailureAt: pc in: memoryArray]].
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
GdbARMAlien >> handleJmpFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a jmp into a ProcessorSimulationTrap signal."
	|  relativeJump |
	self halt.
	relativeJump := memoryArray longAt: pc + 2 bigEndian: false.
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 5
			address: (pc + 5 + relativeJump) signedIntToLong
			type: #jump)
		signal
]

{ #category : #'error handling' }
GdbARMAlien >> handleMoveAwRFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a register load from an Address into a ProcessorSimulationTrap signal."
	((memoryArray byteAt: pc + 4) = 16rE5  "test for E593 as the most significant two bytes"
		and: [(memoryArray byteAt: pc + 3) = (16r90 + (CogARMCompiler classPool at: #RISCTempReg))])
		ifTrue:
			[(ProcessorSimulationTrap
					pc: pc
					nextpc: pc + 4 
					address: (memoryArray byteAt: pc + 1) "address, combined from four instructions"
								+ ((memoryArray byteAt: pc - 3) << 24) 
								+ ((memoryArray byteAt: pc - 7) << 16) 
								+ ((memoryArray byteAt: pc - 11) << 8)
					type: #read
					accessor: (self registerStateSetters at: ((memoryArray byteAt: pc + 2) >> 4) + 1))
				signal]
		ifFalse:
			[self reportPrimitiveFailure]
]

{ #category : #'error handling' }
GdbARMAlien >> handleMoveMbrRFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a byte register load into a ProcessorSimulationTrap signal."
	"MoveMbrR"
	| modrmByte |
	self halt.
	^(((modrmByte := memoryArray byteAt: pc + 2) bitAnd: 16rC0) = 16r80) "ModRegRegDisp32"
		ifTrue:
			[(ProcessorSimulationTrap
					pc: pc
					nextpc: pc + 6
					address: ((self perform: (#(eax ecx edx ebx esp ebp esi edi) at: (modrmByte bitAnd: 7) + 1))
							+ (memoryArray unsignedLongAt: pc + 3 bigEndian: false)
								bitAnd: 16rFFFFFFFF)
					type: #read
					accessor: (#(al: cl: dl: bl: ah: ch: dh: bh:) at: ((modrmByte >> 3 bitAnd: 7) + 1)))
				signal]
		ifFalse:
			[self reportPrimitiveFailure]
]

{ #category : #'error handling' }
GdbARMAlien >> handleMoveRAwFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a register write into Memory at a predefined address into a ProcessorSimulationTrap signal."
	^((memoryArray byteAt: pc + 4) = 16rE5 
		and: [(memoryArray byteAt: pc + 3) = (16r80 + (CogARMCompiler classPool at: #RISCTempReg))])
		ifTrue:
			[(ProcessorSimulationTrap
					pc: pc
					nextpc: pc + 4
					address: (memoryArray byteAt: pc + 1) 
								+ ((memoryArray byteAt: pc - 3) << 24) 
								+ ((memoryArray byteAt: pc - 7) << 16) 
								+ ((memoryArray byteAt: pc - 11) << 8)
					type: #write
					accessor: (self registerStateNames at: ((memoryArray byteAt: pc + 2) >> 4) + 1))
				signal]
		ifFalse:
			[self reportPrimitiveFailure]
]

{ #category : #'error handling' }
GdbARMAlien >> handleMoveRMbrFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
		"Convert an execution primitive failure for a byte register write into a ProcessorSimulationTrap signal."
	"MoveRMbr"
	| modrmByte |
	self halt.
	^(((modrmByte := memoryArray byteAt: pc + 2) bitAnd: 16rC0) = 16r80) "ModRegRegDisp32"
		ifTrue:
			[(ProcessorSimulationTrap
					pc: pc
					nextpc: pc + 6
					address: ((self perform: (#(eax ecx edx ebx esp ebp esi edi) at: (modrmByte bitAnd: 7) + 1))
							+ (memoryArray unsignedLongAt: pc + 3 bigEndian: false)
								bitAnd: 16rFFFFFFFF)
					type: #write
					accessor: (#(al cl dl bl ah ch dh bh) at: ((modrmByte >> 3 bitAnd: 7) + 1)))
				signal]
		ifFalse:
			[self reportPrimitiveFailure]
]

{ #category : #'error handling' }
GdbARMAlien >> handleRetFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a ret into a ProcessorSimulationTrap signal."
	self halt.
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 4
			address: (memoryArray unsignedLongAt: self sp + 1)
			type: #return
			accessor: #pc:)
		signal
]

{ #category : #accessing }
GdbARMAlien >> ifflags [
	^self unsignedLongAt: 585
]

{ #category : #'error handling' }
GdbARMAlien >> instructionTypeAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Identify which type of instruction is at pc in memoryArray. For the time beeing, only those instructions needed for PrimitiveFailure are identified."
	| RISCTempReg lastInstruction typeOperandStatus |
	RISCTempReg := CogARMCompiler classPool at: #RISCTempReg.
	lastInstruction := memoryArray unsignedLongAt: pc + 1 bigEndian: false.
	"self disassembleFrom: pc - 16 to: pc + 3 in: memoryArray on: Transcript cr"
	
	"Ret"
	lastInstruction = 16rE8BD8000 ifTrue: [#Ret].

	"Call"
	(((memoryArray byteAt: pc + 4) bitAnd: 16rF) = 16rB "BL opcode"
		or: [(memoryArray unsignedLongAt: pc - 3 bigEndian: false) = 16rE1A0E00F]) ifTrue: [^#Call].
	
	"Jump"
	((memoryArray byteAt: pc + 3) >> 4 = 16rA "B opcode, for short jumps"
		or: [(lastInstruction >> 12 bitAnd: 16r0FFFF) = 
				(16r0280F + (RISCTempReg << 4)) 	"ADD? PC, RISCTempReg, #anything, for JumpLong-Instructions"])
		ifTrue: [^#Jump].
		
	typeOperandStatus := lastInstruction >> 20 bitAnd: 16rFF.
	"MoveRMbr"
	(typeOperandStatus = 16r54 or: [typeOperandStatus = 16r5C] or: [typeOperandStatus = 16r7C])
		ifTrue: [^#MoveRMbr].
		
	"MoveRAw"
	(typeOperandStatus = 16r58 and: [(lastInstruction >> 16 bitAnd: 16rF) = RISCTempReg])
		ifTrue: [^#MoveRAw].
		
	"MoveMbrR"
	(typeOperandStatus = 16r55 or: [typeOperandStatus = 16r5D] or: [typeOperandStatus = 16r7D])
		ifTrue: [^#MoveMbrR].
		
	"MoveAwR"
	((typeOperandStatus = 16r59) and: [(lastInstruction >> 16 bitAnd: 16rF) = RISCTempReg])
		ifTrue: [^#MoveAwR].
	
	
	^#UnidentifiedInstruction
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> integerRegisterState [
	^{	self r0. self r1. self r2. self r3. self r4. self r5. self r6. self r7. self r8. 
		self r9. self r10. self r11. self r12. self sp. self lr. self pc}
]

{ #category : #accessing }
GdbARMAlien >> lr [
	^self unsignedLongAt: 69
]

{ #category : #accessing }
GdbARMAlien >> lr: anUnsignedInteger [

	^self unsignedLongAt: 69 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> nflag [
	^self unsignedLongAt: 569
]

{ #category : #opcodes }
GdbARMAlien >> nopOpcode [
	"mov r0, r0"
	^ 16rE1A00000
]

{ #category : #accessing }
GdbARMAlien >> pc [
	^self unsignedLongAt: 73
]

{ #category : #accessing }
GdbARMAlien >> pc: anUnsignedInteger [

	^self unsignedLongAt: 73 put: anUnsignedInteger
]

{ #category : #execution }
GdbARMAlien >> postCallArgumentsNumArgs: numArgs "<Integer>" in: memory [ "<ByteArray|Bitmap>"
	"Answer an argument vector of the requested size after a vanilla
	 ABI call. For ARM the Procedure Calling Specification can be found in IHI0042D_aapcs.pdf.
	On ARM this typically means accessing r0 through r3 and fetching additional arguments from the stack, acording to pages 20f. aapcs.
	We assume that all arguments are single word arguments, which can not be supplied on co-processor-registers.
	 For compatibility with Cog/Slang we answer unsigned values."
	^(1 to: numArgs) collect: [:i |
		i < 5 
			ifTrue: [self perform: (self registerStateNames at: i)]
			"ARM uses a full descending stack. Directly after calling a procedure, nothing but the arguments are pushed."
			ifFalse: [memory unsignedLongAt: self sp + (i-5)*4 bigEndian: false]].
]

{ #category : #primitives }
GdbARMAlien >> primitiveDisassembleAt: address inMemory: memoryArray [ "<Bitmap|ByteArray>"
	"Answer an Array of the size and the disassembled code string for the instruction at the current instruction pointer in memory."
	<primitive: 'primitiveDisassembleAtInMemory' module: 'GdbARMPlugin'>
	^self primitiveFailed
]

{ #category : #primitives }
GdbARMAlien >> primitiveErrorAndLog [
	"Answer an array of the current error code and log contents"
	<primitive: 'primitiveErrorAndLog' module: 'GdbARMPlugin'>
	^self primitiveFailed
]

{ #category : #primitives }
GdbARMAlien >> primitiveFlushICacheFrom: startAddress "<Integer>" To: endAddress [ "<Integer>"
	"Flush the icache in the requested range"
	<primitive: 'primitiveFlushICacheFromTo' module: 'GdbARMPlugin'>
	^self primitiveFailed
]

{ #category : #primitives }
GdbARMAlien >> primitiveResetCPU [
	"Reset the receiver to registers all zero, and protected 32-bit mode."
	<primitive: 'primitiveResetCPU' module: 'GdbARMPlugin'>
	^self reportPrimitiveFailure
]

{ #category : #primitives }
GdbARMAlien >> primitiveRunInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" maximumAddress: maximimAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Run the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 calls, jumps and memory read/writes into ProcessorSimulationTrap signals."
	<primitive: 'primitiveRunInMemoryMinAddressMaxAddressReadWrite' module: 'GdbARMPlugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress]
		ifFalse: [self reportPrimitiveFailure]

	"self printRegistersOn: Transcript"
]

{ #category : #primitives }
GdbARMAlien >> primitiveRunInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Run the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 calls, jumps and memory read/writes into ProcessorSimulationTrap signals."
	<primitive: 'primitiveRunInMemoryMinimumAddressReadWrite' module: 'GdbARMPlugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress]
		ifFalse: [self reportPrimitiveFailure]

	"self printRegistersOn: Transcript"
]

{ #category : #primitives }
GdbARMAlien >> primitiveSingleStepInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" maximumAddress: maximimAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Single-step the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 calls, jumps and memory read/writes into ProcessorSimulationTrap signals."
	<primitive: 'primitiveSingleStepInMemoryMinAddressMaxAddressReadWrite' module: 'GdbARMPlugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress]
		ifFalse: [self reportPrimitiveFailure]
]

{ #category : #primitives }
GdbARMAlien >> primitiveSingleStepInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Single-step the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 calls, jumps and memory read/writes into ProcessorSimulationTrap signals."
	<primitive: 'primitiveSingleStepInMemoryMinimumAddressReadWrite' module: 'GdbARMPlugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress]
		ifFalse: [self reportPrimitiveFailure]
]

{ #category : #printing }
GdbARMAlien >> printOn: aStream [
	aStream nextPutAll: 'an ARMAlien('.
	self registerState allButLast with: self registerStateNames allButLast do: [ :state :i |
		aStream 
			<< i << ': ' 
			<< (state abs > 15 ifTrue: [state hex] ifFalse: [state asString]) 
			<< ', '].
	aStream << 'NZCVIF: ' 
		<< (self registerState last printStringBase: 2 length: 6 padded: true) << ')'.
]

{ #category : #printing }
GdbARMAlien >> printRegisterState: registerStateVector on: aStream [
	| rsvs fields|
	aStream ensureCr.
	rsvs := registerStateVector readStream.
	fields := #(	r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 sp lr pc eflags cr).
	fields withIndexDo:
		[:sym :index| | val |
		sym = #cr
			ifTrue: [aStream cr]
			ifFalse:
				[(val := rsvs next) isNil ifTrue: [^self].
				aStream nextPutAll: sym; nextPut: $:; space.
				val printOn: aStream base: 16 length: 8 padded: true.
				#eflags == sym
					ifTrue:
						[aStream space.
						 "'FIVCZN'"'--VCZN' withIndexDo:
							[:flag :bitIndex|
							flag ~= $- ifTrue:
								[aStream nextPut: flag; nextPutAll: 'F='; print: (val bitAnd: 1 << (bitIndex - 1)) >> (bitIndex - 1); space]]]
					ifFalse:
						[val > 16 ifTrue:
							[aStream space; nextPut: $(.
							 val printOn: aStream base: 10 length: 1 padded: false.
							 aStream nextPut: $)]].
				(fields at: index + 1) ~~ #cr ifTrue:
					[aStream tab]]]
]

{ #category : #execution }
GdbARMAlien >> pushWord: aValue in: aMemory [
	aMemory longAt: (self sp: self sp - 4) + 1 put: aValue bigEndian: false
]

{ #category : #accessing }
GdbARMAlien >> r0 [
	^self unsignedLongAt: 13
]

{ #category : #accessing }
GdbARMAlien >> r0: anUnsignedInteger [

	^self unsignedLongAt: 13 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> r1 [
	^self unsignedLongAt: 17
]

{ #category : #accessing }
GdbARMAlien >> r10 [
	^self unsignedLongAt: 53
]

{ #category : #accessing }
GdbARMAlien >> r10: anUnsignedInteger [

	^self unsignedLongAt: 53 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> r11 [
	^self unsignedLongAt: 57
]

{ #category : #accessing }
GdbARMAlien >> r11: anUnsignedInteger [

	^self unsignedLongAt: 57 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> r12 [
	^self unsignedLongAt: 61
]

{ #category : #accessing }
GdbARMAlien >> r12: anUnsignedInteger [

	^self unsignedLongAt: 61 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> r1: anUnsignedInteger [

	^self unsignedLongAt: 17 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> r2 [
	^self unsignedLongAt: 21
]

{ #category : #accessing }
GdbARMAlien >> r2: anUnsignedInteger [

	^self unsignedLongAt: 21 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> r3 [
	^self unsignedLongAt: 25
]

{ #category : #accessing }
GdbARMAlien >> r3: anUnsignedInteger [

	^self unsignedLongAt: 25 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> r4 [
	^self unsignedLongAt: 29
]

{ #category : #accessing }
GdbARMAlien >> r4: anUnsignedInteger [

	^self unsignedLongAt: 29 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> r5 [
	^self unsignedLongAt: 33
]

{ #category : #accessing }
GdbARMAlien >> r5: anUnsignedInteger [

	^self unsignedLongAt: 33 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> r6 [
	^self unsignedLongAt: 37
]

{ #category : #accessing }
GdbARMAlien >> r6: anUnsignedInteger [

	^self unsignedLongAt: 37 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> r7 [
	^self unsignedLongAt: 41
]

{ #category : #accessing }
GdbARMAlien >> r7: anUnsignedInteger [

	^self unsignedLongAt: 41 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> r8 [
	^self unsignedLongAt: 45
]

{ #category : #accessing }
GdbARMAlien >> r8: anUnsignedInteger [

	^self unsignedLongAt: 45 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> r9 [
	^self unsignedLongAt: 49
]

{ #category : #accessing }
GdbARMAlien >> r9: anUnsignedInteger [

	^self unsignedLongAt: 49 put: anUnsignedInteger
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> registerState [
	^{	self r0. self r1. self r2. self r3. self r4. self r5. self r6. self r7.
		self r8. self r9. self r10. self r11. self r12. self sp. self lr. self pc. self eflags }
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> registerStateNames [
	^#(	r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 fp r12 sp lr pc eflags)
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> registerStatePCIndex [
	^16
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> registerStateSetters [
	^#(	r0: r1: r2: r3: r4: r5: r6: r7: r8: r9: r10: fp: r12: sp: lr: pc:)
]

{ #category : #accessing }
GdbARMAlien >> reset [
	self primitiveResetCPU
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> setFramePointer: framePointer stackPointer: stackPointer [
	"Initialize the processor's frame and stack pointers"
	self fp: framePointer.
	self sp: stackPointer
]

{ #category : #accessing }
GdbARMAlien >> sflag [
	^self unsignedLongAt: 589
]

{ #category : #'execution simulation' }
GdbARMAlien >> simulateCallOf: address nextpc: nextpc memory: aMemory [
	"Simulate a frame-building call of address.  Build a frame since
	a) this is used for calls into the run-time which are unlikely to be leaf-calls"
	"This method builds a stack frame as expected by the simulator, not as defined by ARM aapcs-abi.
	In ARM aapcs, every method can define for itself, wether it wants to push lr (nextpc), and wether it 
	uses a frame pointer. The standard never mentions a fp. It merely defines r4-r11 to be callee-saved."

	self assert: self sp \\ 8 = 0. "This check ensures, that we conform with ARM abi. Before doing anything to the stack, we ensure 2-word alignment."
	self pushWord: nextpc in: aMemory.
	self pushWord: self r11 in: aMemory.
	self r11: self sp.
	PostBuildStackDelta ~= 0 ifTrue:
		[self sp: self sp - PostBuildStackDelta]. "In order to satisfy the CStackAlignment check by cogit, which is only valid on IA32 platforms."
	self pc: address
]

{ #category : #'execution simulation' }
GdbARMAlien >> simulateLeafCallOf: address nextpc: nextpc memory: aMemory [
	self lr: nextpc.
	self pc: address
]

{ #category : #'execution simulation' }
GdbARMAlien >> simulateLeafReturnIn: aMemory [
	self pc: self lr
]

{ #category : #'execution simulation' }
GdbARMAlien >> simulateReturnIn: aMemory [
	PostBuildStackDelta ~= 0 ifTrue:
		[self sp: self sp + PostBuildStackDelta].
	self r11: (self popWordIn: aMemory).
	self pc: (self popWordIn: aMemory)
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> smashRegisterAccessors [
	^#(r0: r1: r2: r3: r4: r5: r6: r7: r8: r9: r10:)
]

{ #category : #accessing }
GdbARMAlien >> sp [
	^self unsignedLongAt: 65
]

{ #category : #accessing }
GdbARMAlien >> sp: anUnsignedInteger [

	^self unsignedLongAt: 65 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> vflag [
	^self unsignedLongAt: 581
]

{ #category : #accessing }
GdbARMAlien >> zflag [
	^self unsignedLongAt: 573
]
