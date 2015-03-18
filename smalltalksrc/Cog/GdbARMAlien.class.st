"
I am a wrapper around the ARMulator CPU instance and emulator routines and I give access to disassembling using libopcodes. My C-part must be compiled with -DMODET, because otherwise my offesets are wrong by one field.
"
Class {
	#name : #GdbARMAlien,
	#superclass : #CogProcessorAlien,
	#type : #bytes,
	#classVars : [
		'LongConstReg',
		'LongConstStep',
		'LongConstValue',
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

{ #category : #primitives }
GdbARMAlien class >> primitiveNewCPU [
	"Answer the address of a new ARMulator C type ARMul_State instance."
	<primitive: 'primitiveNewCPU' module: 'GdbARMPlugin'>
	^self primitiveFailed
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
GdbARMAlien >> byteSwappedNopOpcode [
	"For the Tsts class which keeps filling BitMaps with nop, provide one swapped so it turns out correct when disassembled
	mov r0, r0 swapped -> "
	^ 16r00000A0E1
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> cResultRegister [
	self r0
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> cResultRegister: aValue [
	self r0: aValue
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> callerSavedSmashRegisterAccessors [
	^#(r0: r1: r2: r3: )
]

{ #category : #accessing }
GdbARMAlien >> cflag [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
	^self unsignedLongAt: 573
]

{ #category : #accessing }
GdbARMAlien >> cflag: unsignedInteger [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
	^self unsignedLongAt: 573 put: unsignedInteger
]

{ #category : #disassembly }
GdbARMAlien >> decorateDisassembly: anInstructionString for: aSymbolManager [
	| parts strm hexNum string |

	"break up the string"
	parts:= anInstructionString subStrings: '	 ,:'.
	"part 1 is the address, part 2 is the instruction. Last part is sometimes a hex number"
	
	"is this a mov of a literal number?"
	((parts at: 2) includesSubString: 'mov')
		ifTrue:[ 
			"clear the flags & running total"
			LongConstReg := nil.
			LongConstValue := 0.
			LongConstStep := 0.
			(parts at:4) first = $#
				ifTrue:["looks a good candidate"
					LongConstReg :=(parts at: 3). "the target register"
					(parts last beginsWith: '0x') ifTrue:[
						LongConstValue :=(NumberParser on: (parts last allButFirst:2)) nextUnsignedIntegerBase: 16].
					LongConstStep := 1].
			"not a likely candidate, just return the string"			
			^anInstructionString].
	
	"is this a build of a literal number?"
	(((parts at: 2) includesSubString: 'orr') and:[LongConstStep >0])
		ifTrue:["add to running total if the register matches"
			LongConstReg = (parts at: 3) 
				ifTrue:[
					(parts at:5) first = $#
						ifTrue:["looks a good candidate with the # indicating a const - due to disassembler idiocy we have to check for both hex
							and dec values. "
							(parts last beginsWith: '0x') 
								ifTrue:[ LongConstValue :=  LongConstValue +((NumberParser on: (parts last allButFirst:2)) nextUnsignedIntegerBase: 16)]
								ifFalse:[ LongConstValue := LongConstValue + ((NumberParser on: (parts at:5) allButFirst) nextUnsignedIntegerBase: 10) ].
							LongConstStep:= LongConstStep +1].
					LongConstStep = 4
						ifTrue:["we've completed a pattern of mov/orr/orr/orr, so print the value it built" 
							^anInstructionString, ' (', LongConstReg , ' = ', LongConstValue hex8, ((aSymbolManager lookupAddress: LongConstValue) ifNil: [''] ifNotNil:[:val| ' = ', val]), ')']]
				ifFalse:[ LongConstStep := 0.
						LongConstReg := nil.
						LongConstValue := 0].
			"either not a likely candidate orpartway through the pattern, so just return the string"			
			^anInstructionString].
	

	strm :=anInstructionString readStream.
	strm skip: 9. "the instruction address"
	
	strm upToAll: '0x'. "see if there is a hex number"
	strm atEnd ifTrue:[^anInstructionString]. "if not, leave it be"

	"extract the number"		
	hexNum := (NumberParser on: strm) nextUnsignedIntegerBase: 16.
	"is there an intersting address with this?"
	(string := aSymbolManager lookupAddress: hexNum) ifNil: [^anInstructionString].
	^ anInstructionString, ' = ', string
]

{ #category : #disassembly }
GdbARMAlien >> decorateDisassembly: anInstructionString for: aSymbolManager fromAddress: address [
	| word opcode rotate mode operand |
	word := aSymbolManager objectMemory longAt: address.
	(self instructionIsAnyB: word)
		ifTrue:
			[operand := word bitAnd: 16rFFFFFF.
			 (operand anyMask: 16r800000) ifTrue:
				[operand := operand - 16r1000000].
			 operand := operand * 4 + address + 8 bitAnd: aSymbolManager addressSpaceMask]
		ifFalse:
			[opcode := word >> 21 bitAnd: 16rF.
			 opcode ~= CogARMCompiler orOpcode ifTrue:
				[^anInstructionString].
			rotate := word >> 8 bitAnd: 16rF.
			 mode := word >> 25 bitAnd: 7.
			 "CogARMCompiler always uses a 0 rotate in the last operand of the final ORR when building long constants."
			 (mode = 1 and: [rotate ~= 0]) ifTrue:
				[^anInstructionString].
			 operand := aSymbolManager backEnd literalBeforeFollowingAddress: address + 4].
	"is there an intersting address with this?"
	^(aSymbolManager lookupAddress: operand)
		ifNotNil: [:string| anInstructionString, ' = ', (operand printStringRadix: 16), ' = ', string]
		ifNil: [anInstructionString, ' = ', (operand printStringRadix: 16)]
]

{ #category : #accessing }
GdbARMAlien >> eflags [
	
	^ (((self nflag << 5 bitOr: self zflag << 4) 
			bitOr: self cflag << 3) 
				bitOr: self vflag << 2)
					bitOr: self ifflags
]

{ #category : #accessing }
GdbARMAlien >> eflags: anUnsignedInteger [
	"set the processor flags from the integer"
	self nflag: (anUnsignedInteger >> 5 bitAnd: 1).
	self zflag: (anUnsignedInteger >> 4 bitAnd: 1).
	self cflag: (anUnsignedInteger >> 3 bitAnd: 1).
	self vflag: (anUnsignedInteger >> 2 bitAnd: 1).
	self ifflags: (anUnsignedInteger bitAnd: 3)
]

{ #category : #accessing }
GdbARMAlien >> endCondition [
"why did the simulator stop?"
	^self unsignedLongAt: 5
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> endianness [
	^#little
]

{ #category : #accessing }
GdbARMAlien >> errorCode [
"simulator error code"
	^self unsignedLongAt: 9
]

{ #category : #testing }
GdbARMAlien >> extractOffsetFromBL: instr [
"we are told this is a BL <offset> instruction, so work out the offset it encodes"
	| relativeJump |
	relativeJump := instr bitAnd: 16r00FFFFFF.
	relativeJump := (relativeJump bitAt: 24) = 1 
						ifTrue: [((relativeJump bitOr: 16r3F000000) << 2) signedIntFromLong]
						ifFalse: [relativeJump << 2].
	^relativeJump
]

{ #category : #execution }
GdbARMAlien >> flushICacheFrom: startAddress "<Integer>" to: endAddress [ "<Integer>"
	self primitiveFlushICacheFrom: startAddress To: endAddress
]

{ #category : #accessing }
GdbARMAlien >> fp [
"fp is r11"
	^self r11
]

{ #category : #accessing }
GdbARMAlien >> fp: anUnsignedInteger [

	^self r11: anUnsignedInteger
]

{ #category : #'error handling' }
GdbARMAlien >> handleCallFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a call into a ProcessorSimulationTrap signal."
	|  callAddress failedInstruction|
	"grab the instruction at issue"
	failedInstruction := memoryArray unsignedLongAt: pc + 1 bigEndian: false.
	(self instructionIsBL: failedInstruction)
		ifFalse:[self halt].
	"short jump via BL, therefore we have a 24bit signed integer offset"
	callAddress := (pc + 8 + (self extractOffsetFromBL: failedInstruction)).

	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 4
			address: callAddress signedIntToLong
			type: #call)
		signal
]

{ #category : #'error handling' }
GdbARMAlien >> handleExecutionPrimitiveFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Handle an execution primitive failure for an otherwise unhandled opcode."
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
GdbARMAlien >> handleExecutionPrimitiveFailureIn: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress [ "<Integer>"
	"Handle an execution primitive failure.  Convert out-of-range call and absolute
	 memory read into register instructions into ProcessorSimulationTrap signals."
	"self printRegistersOn: Transcript"
	| pc |
	self endCondition = 5 ifTrue:[self pc: self priorPc].
	((pc := self pc) between: minimumAddress and: memoryArray byteSize - 1) ifTrue:
		[(self instructionTypeAt: pc in: memoryArray)
			caseOf: {
				[#Call] 			-> [^self handleCallFailureAt: pc in: memoryArray].
				[#LongCall] 	-> [^self handleLongCallFailureAt: pc in: memoryArray].
				[#Jump] 		-> [^self handleJmpFailureAt: pc in: memoryArray].
				[#LongJump] 	-> [^self handleLongJmpFailureAt: pc in: memoryArray].
				[#MoveAwR]	-> [^self handleMoveAwRFailureAt: pc in: memoryArray].
				[#MoveMbrR]	-> [^self handleMoveMbrRFailureAt: pc in: memoryArray].
				[#MoveRAw]	-> [^self handleMoveRAwFailureAt: pc in: memoryArray].
				[#MoveRMbr]	-> [^self handleMoveRMbrFailureAt: pc in: memoryArray].
				[#Ret]			-> [^self handleRetFailureAt: pc in: memoryArray].} 
			otherwise: [^self handleExecutionPrimitiveFailureAt: pc in: memoryArray]].

	pc = 0 ifTrue:[self halt: 'pc should not be 0 at this point; simulator failure'].

	((pc := self lr - 4) between: minimumAddress and: memoryArray byteSize - 1) ifTrue:
		[(self instructionTypeAt: pc in: memoryArray)
			caseOf: {
				[#Call] 		-> [^self handleCallFailureAt: pc in: memoryArray].
				[#LongCall] -> [^self handleLongCallFailureAt: pc in: memoryArray].
				[#Jump] 	-> [^self handleJmpFailureAt: pc in: memoryArray].
				[#LongJump] 	-> [^self handleLongJmpFailureAt: pc in: memoryArray].
				[#Ret]		-> [^self handleRetFailureAt: pc in: memoryArray].} 
			otherwise: [^self handleExecutionPrimitiveFailureAt: pc in: memoryArray]].
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
GdbARMAlien >> handleJmpFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a jump into a ProcessorSimulationTrap signal."
	|  callAddress failedInstruction|
	"grab the instruction at issue"
	failedInstruction := memoryArray unsignedLongAt: pc + 1 bigEndian: false.
	(self instructionIsB: failedInstruction)
		ifFalse:[self halt].
	"short jump via B, therefore we have a 24bit signed integer offset"
	callAddress := (pc + 8 + (self extractOffsetFromBL: failedInstruction)).

	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 4
			address: callAddress signedIntToLong
			type: #jump)
		signal
]

{ #category : #'error handling' }
GdbARMAlien >> handleLongCallFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a long call into a ProcessorSimulationTrap signal."
	|  callAddress failedInstruction|
	"grab the instruction at issue"
	failedInstruction := memoryArray unsignedLongAt: pc + 1 bigEndian: false.
	"Hmm. Perhaps we ought to test for an actual BLX here rather than assuming?"
	(self instructionIsBLX: failedInstruction)
				ifFalse:[ self halt: 'failed call type test'].
	"The memoryArray starts indexing from 1, whereas the pc is based on 0-indexing, therefore all access-offsets are one greater than expected" 
	"address, combined from prior four MOV/ORR instructions. See CogARMCompiler>concretizeLongCall"
	callAddress := (memoryArray byteAt: pc -3) 
						+ ((memoryArray byteAt: pc - 7) << 8) 
						+ ((memoryArray byteAt: pc - 11) << 16) 
						+ ((memoryArray byteAt: pc - 15) << 24).
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 4
			address: callAddress signedIntToLong
			type: #call)
		signal
]

{ #category : #'error handling' }
GdbARMAlien >> handleLongJmpFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a long jump into a ProcessorSimulationTrap signal."
	|  callAddress failedInstruction|
	"grab the instruction at issue"
	failedInstruction := memoryArray unsignedLongAt: pc + 1 bigEndian: false.
	"Hmm. Perhaps we ought to test for an actual BX here rather than assuming?"
	(self instructionIsBX: failedInstruction)
				ifFalse:[ self halt: 'failed call type test'].
	"The memoryArray starts indexing from 1, whereas the pc is based on 0-indexing, therefore all access-offsets are one greater than expected" 
	"address, combined from prior four MOV/ORR instructions. See CogARMCompiler>concretizeLongCall"
	callAddress := (memoryArray byteAt: pc -3) 
						+ ((memoryArray byteAt: pc - 7) << 8) 
						+ ((memoryArray byteAt: pc - 11) << 16) 
						+ ((memoryArray byteAt: pc - 15) << 24).
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 4
			address: callAddress signedIntToLong
			type: #jump)
		signal
]

{ #category : #'error handling' }
GdbARMAlien >> handleMoveAwRFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a register load from an Address into a ProcessorSimulationTrap signal."
	((memoryArray byteAt: pc + 4) = 16rE5  "test for 0xE59X as the most significant two bytes - X being the index of the RISCTempReg (or 0xA in current code).
		LDR Rx, [RiscTempReg, #0]"
		and: [(memoryArray byteAt: pc + 3) = (16r90 + CogARMCompiler ARMTempReg)])
		ifTrue:
			[(ProcessorSimulationTrap
					pc: pc
					nextpc: pc + 4 
					address: (memoryArray byteAt: pc -3) "address, combined from prior four MOV/ORR instructions. See CogARMCompiler>concretizeMoveAwR"
								+ ((memoryArray byteAt: pc - 7) << 8) 
								+ ((memoryArray byteAt: pc - 11) << 16) 
								+ ((memoryArray byteAt: pc - 15) << 24)
					type: #read
					accessor: (self registerStateSetters at: ("destination register" (memoryArray byteAt: pc + 2) >> 4) + 1))
				signal]
		ifFalse:
			[self reportPrimitiveFailure]
]

{ #category : #'error handling' }
GdbARMAlien >> handleMoveMbrRFailureAt: pc in: memoryArray [ 
	"Convert an execution primitive failure for a byte register load into a ProcessorSimulationTrap signal."
	"generated by MoveMbrR"
	"might be ldrb destReg, [srcReg, #immediate] or ldrb destReg, [srcReg, RISCTempReg] "

	"first test for ldrb destReg, [srcReg, RISCTempReg]
	-test for 0xE7DX as the most significant three nibbles"
	((memoryArray byteAt: pc + 4) = 16rE7 and: [(memoryArray byteAt: pc + 3) >> 4 = 13])
		ifTrue: [(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4
				address: (memoryArray byteAt: pc - 3)
						+ ((memoryArray byteAt: pc - 7)
								<< 8) + ((memoryArray byteAt: pc - 11)
							<< 16) + ((memoryArray byteAt: pc - 15)
							<< 24)
				type: #read
				accessor: ("work out the dest register name"self registerStateSetters at: (memoryArray byteAt: pc + 2) >> 4 + 1)) signal
			]
		ifFalse: [self reportPrimitiveFailure]
]

{ #category : #'error handling' }
GdbARMAlien >> handleMoveRAwFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a register write into Memory at a predefined address into a ProcessorSimulationTrap signal."
	"LEA RISCTempReg
	str srcReg, [RISCTempReg]"
	"first we check this is a str r?, [sl]"
	^((memoryArray byteAt: pc + 4) = 16rE5 
		and: [(memoryArray byteAt: pc + 3) = (16r80 + CogARMCompiler ARMTempReg)])
		ifTrue:
			[(ProcessorSimulationTrap
					pc: pc
					nextpc: pc + 4
					address: (memoryArray byteAt: pc -3) 
								+ ((memoryArray byteAt: pc - 7) << 8) 
								+ ((memoryArray byteAt: pc - 11) << 16) 
								+ ((memoryArray byteAt: pc - 15) <<24)
					type: #write
					accessor: ("work out the dest register name" self registerStateNames at: ((memoryArray byteAt: pc + 2) >> 4) + 1))
				signal]
		ifFalse:
			[self reportPrimitiveFailure]
]

{ #category : #'error handling' }
GdbARMAlien >> handleMoveRMbrFailureAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Convert an execution primitive failure for a byte register write into a ProcessorSimulationTrap signal."
	"generated by MoveRMbr"

	"might be strb destReg, [srcReg, #immediate] or strb destReg, [srcReg, RISCTempReg] "

	"first test for ldrb destReg, [srcReg, RISCTempReg]
	-test for 0xE7CX as the most significant three nibbles"
	((memoryArray byteAt: pc + 4) = 16rE7 and: [(memoryArray byteAt: pc + 3) >> 4 = 16rC])
		ifTrue: [(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4
				address: (memoryArray byteAt: pc - 3)
						+ ((memoryArray byteAt: pc - 7)
								<< 8) + ((memoryArray byteAt: pc - 11)
							<< 16) + ((memoryArray byteAt: pc - 15)
							<< 24)
				type: #write
				accessor: ("work out the dest register name"self registerStateNames at: (memoryArray byteAt: pc + 2) >> 4 + 1)) signal
]
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
			address: self lr " for popping off stack version of retiurn -> (memoryArray unsignedLongAt: self sp -3) "
			type: #return
			"don't quite know what to do with this yet ->accessor: #pc:")
		signal
]

{ #category : #accessing }
GdbARMAlien >> ifflags [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
	^self unsignedLongAt: 581
]

{ #category : #accessing }
GdbARMAlien >> ifflags: unsignedInteger [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
	^self unsignedLongAt: 581 put: unsignedInteger
]

{ #category : #'processor setup' }
GdbARMAlien >> initializeStackFor: aCogit [
"Different cpus need different stack alignment etc, so handle the details here."
	| stackAlignment |
	stackAlignment := 8.
	aCogit setStackAlignment: stackAlignment expectedSPOffset: 0 expectedFPOffset: 0.
	self assert: stackAlignment isPowerOfTwo.
	PostBuildStackDelta :=  stackAlignment > 8
								ifTrue: [stackAlignment - 8]
								ifFalse: [0]
]

{ #category : #testing }
GdbARMAlien >> instructionIsAddSP: instr [
"is this aadd sp, sp, #? -  instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: (16rFFFFF00)) = (16r28DD000)]
]

{ #category : #testing }
GdbARMAlien >> instructionIsAlignSP: instr [
"is this a bics sp, sp, #7 -  instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: (16rFFFFFFF)) = (16r3DDD007)]
]

{ #category : #testing }
GdbARMAlien >> instructionIsAnyB: instr [
	"is this any of the B BX BL or BLX <offset> instructions?"
	^(instr >> 25 bitAnd: 7) = 5
]

{ #category : #testing }
GdbARMAlien >> instructionIsB: instr [
"is this a B <offset> instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: (16rF<<24)) = (16rA<<24)]
]

{ #category : #testing }
GdbARMAlien >> instructionIsBL: instr [
"is this a BL <offset> instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: (16rF<<24)) = (16rB<<24)]
]

{ #category : #testing }
GdbARMAlien >> instructionIsBLX: instr [
"is this a BLX <targetReg> instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: 16r0FFFFFF0) = 16r12FFF30]
]

{ #category : #testing }
GdbARMAlien >> instructionIsBX: instr [
"is this a BX <targetReg> instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: 16r0FFFFFF0) = 16r12FFF10]
]

{ #category : #testing }
GdbARMAlien >> instructionIsLDR: instr [
"is this a LDR instruction?"
	| foo |
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" 
		and: [foo := (instr >> 20 bitAnd: 16rFF).
			foo = 16r51 "ldr r1, [r2, #imm]"
				or:[foo = 16r59 "ldr r1, [r2, #-imm]"
				or:[foo = 16r79 "ldr r1, [r2, r3]"]]]
]

{ #category : #testing }
GdbARMAlien >> instructionIsLDR: instr byReg: rn [
"is this a LDR r1, [r2, rn] instruction? Special case to detect MoveAwR case"
	| foo |
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [foo := (instr >> 20 bitAnd: 16rFF). foo = 16r59  and:[(instr >>16 bitAnd: 16rF) = rn]]
]

{ #category : #testing }
GdbARMAlien >> instructionIsLDRB: instr [
"is this a LDRB instruction?"
	| foo |
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" 
		and: [foo := (instr >> 20 bitAnd: 16rFF).
			foo = 16r55 "ldrb r1, [r2, #imm]"
				or:[foo = 16r5D "ldrb r1, [r2, #-imm]"
				or:[foo = 16r7D "ldrb r1, [r2, r3]"]]]
]

{ #category : #testing }
GdbARMAlien >> instructionIsLDRSP: instr [
"is this a LDR sp, [??] instruction? Special case to detect LDR sp, [] affecting stack pointer"
	^(self instructionIsLDR: instr)  and:[(instr >>12 bitAnd: 16rF) = 13]
]

{ #category : #testing }
GdbARMAlien >> instructionIsPop: instr [
"is this a pop - ldr r??, [sp], #4 -  instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: (16rFFF0FFF)) = (16r49D0004)]
]

{ #category : #testing }
GdbARMAlien >> instructionIsPush: instr [
"is this a push -str r??, [sp, #-4] -  instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: (16rFFF0FFF)) = (16r52D0004)]
]

{ #category : #testing }
GdbARMAlien >> instructionIsReturnViaLR: instr [
"is this a MOV pc, lr instruction?"
	^instr =  16rE1A0F00E
]

{ #category : #testing }
GdbARMAlien >> instructionIsSTR: instr [
"is this a STR instruction?"
	| foo |
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [foo := (instr >> 20 bitAnd: 16rFF). foo = 16r58 "str r1, [r2, #imm]" or:[foo = 16r50 "str r1, [r2, #-imm]" or:[foo = 16r78 "str r1, [r2, r3]"]]]
]

{ #category : #testing }
GdbARMAlien >> instructionIsSTR: instr byReg: rn [
"is this a STR r1, [r2, rn] instruction? Special case to detect MoveRAw case"
	| foo |
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [foo := (instr >> 20 bitAnd: 16rFF). foo = 16r58  and:[(instr >>16 bitAnd: 16rF) = rn]]
]

{ #category : #testing }
GdbARMAlien >> instructionIsSTRB: instr [
"is this a STRB instruction?"
	| foo |
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [foo := (instr >> 20 bitAnd: 16rFF). foo = 16r54 "strb r1, [r2, #imm]" or:[foo = 16r5c "strb r1, [r2, #-imm]" or:[foo = 16r7c "strb r1, [r2, r3]"]]]
]

{ #category : #testing }
GdbARMAlien >> instructionIsSTRSP: instr [
"is this a STR sp, [??] instruction? Special case to detect STR sp, [] affecting stack pointer"
	^(self instructionIsSTR: instr)  and:[(instr >>12 bitAnd: 16rF) = 13]
]

{ #category : #'error handling' }
GdbARMAlien >> instructionTypeAt: pc "<Integer>" in: memoryArray [ "<Bitmap|ByteArray>"
	"Identify which type of instruction is at pc in memoryArray. For the time being, only those instructions needed for PrimitiveFailure are identified."
	| RISCTempReg lastInstruction typeOperandStatus |
	RISCTempReg := CogARMCompiler ARMTempReg.
	lastInstruction := memoryArray unsignedLongAt:  pc + 1 bigEndian: false .
	"self disassembleFrom: pc - 16 to: pc + 11 in: memoryArray on: Transcript cr"
	
	"Ret"
	(self instructionIsReturnViaLR: lastInstruction ) ifTrue: [^#Ret].

	"Call"
	(self instructionIsBL: lastInstruction) ifTrue: [^#Call].
	"long call"
	(self instructionIsBLX: lastInstruction) ifTrue: [^#LongCall].
	
	
	"Jump"
	(self instructionIsB: lastInstruction) ifTrue: [^#Jump].
	"long Jump"
	(self instructionIsBX: lastInstruction) ifTrue: [^#LongJump].
		
	typeOperandStatus := lastInstruction >> 20 bitAnd: 16rFF.
	"MoveRMbr"
	(self instructionIsSTRB: lastInstruction) ifTrue: [^#MoveRMbr].
		
	"MoveRAw"
	(self instructionIsSTR: lastInstruction byReg: RISCTempReg) ifTrue: [^#MoveRAw].
		
	"MoveMbrR"
	(self instructionIsLDRB: lastInstruction) ifTrue: [^#MoveMbrR].
		
	"MoveAwR"
	(self instructionIsLDR: lastInstruction byReg: RISCTempReg) ifTrue: [^#MoveAwR].
	
	
	^#UnidentifiedInstruction
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> integerRegisterState [
	^{	self r0. self r1. self r2. self r3. self r4. self r5. self r6. self r7. self r8. 
		self r9. self r10. self fp. self r12. self sp. self lr. self pc}
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
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
	^self unsignedLongAt: 565
]

{ #category : #accessing }
GdbARMAlien >> nflag: unsignedInteger [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
	^self unsignedLongAt: 565 put: unsignedInteger
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

{ #category : #opcodes }
GdbARMAlien >> popPcOpcode [
"See also CogARMCompiler>concretizePopR"
	^16rE49DF004
]

{ #category : #execution }
GdbARMAlien >> popWordIn: aMemory [ 
	| sp word |
	word := aMemory unsignedLongAt: (sp := self sp) + 1 bigEndian: false.
	self sp: sp + 4.
	^word
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

{ #category : #accessing }
GdbARMAlien >> postTrapCorrectedPC [
	"return the pc - 8 for trap handling - remember the ARM alwayshas that funky +8 offset vs the actual instruction running/failig"
	^self pc -8
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
	 calls, jumps and memory read/writes into ProcessorSimulationTrap signals.
	Note that minWriteMaxExecAddress is both the minimum writeable address AND the maximum executable address"
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
GdbARMAlien >> printFields: fields inRegisterState: registerStateVector on: aStream [
	| rsvs |
	aStream ensureCr.
	rsvs := registerStateVector readStream.
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
	self printFields: #(	r0 r1 r2 r3 cr
						r4 r5 r6 r7 cr
						r8 r9 r10 fp cr
						r12 sp lr pc eflags cr)
		inRegisterState: registerStateVector
		on: aStream
]

{ #category : #printing }
GdbARMAlien >> printRegisterStateExceptPC: registerStateVector on: aStream [
	self printFields: #(	r0 r1 r2 r3 cr
						r4 r5 r6 r7 cr
						r8 r9 r10 fp cr
						r12 sp lr eflags cr)
		inRegisterState: registerStateVector
		on: aStream
]

{ #category : #accessing }
GdbARMAlien >> priorPc [
"where did the simulator stop just before a prefetch abort?"
	^self unsignedLongAt: 609
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

{ #category : #accessing }
GdbARMAlien >> rawCPSR [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
"read the raw value of the cpsr from the alien structure"
	^self unsignedLongAt: 533
]

{ #category : #accessing }
GdbARMAlien >> register: int0to15 [
"return the value of register"
	self assert:[int0to15 between: 0 and:15].
	^self unsignedLongAt: 13 + (4 * int0to15)
]

{ #category : #accessing }
GdbARMAlien >> registerAt: index [ 
	^self perform: (self registerStateNames at: index + 1)
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> registerState [
	^{	self r0. self r1. self r2. self r3. self r4. self r5. self r6. self r7.
		self r8. self r9. self r10. self fp. self r12. self sp. self lr. self pc. self eflags }
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
"a list of register setting messages used to initialise or reset registers"
	^#(	r0: r1: r2: r3: r4: r5: r6: r7: r8: r9: r10: fp: r12: sp: lr: pc: eflags:)
]

{ #category : #accessing }
GdbARMAlien >> reset [
	self primitiveResetCPU
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> retpcIn: aMemory [
"the return address is on the stack, apparently"
	^aMemory unsignedLongAt: self fp + 5 bigEndian: false
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> setFramePointer: framePointer stackPointer: stackPointer [
	"Initialize the processor's frame and stack pointers"
	self fp: framePointer.
	self sp: stackPointer
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> setRegisterState: aRegisterStateArray [
	"N.B. keep in sync with voidRegisterState"

	self r0:  (aRegisterStateArray at: 1).
	self r1: (aRegisterStateArray at: 2).
	self r2: (aRegisterStateArray at: 3).
	self r3: (aRegisterStateArray at: 4).
	self r4: (aRegisterStateArray at: 5).
	self r5: (aRegisterStateArray at: 6).
	self r6: (aRegisterStateArray at: 7).
	self r7: (aRegisterStateArray at: 8).
	self r8: (aRegisterStateArray at: 9).
	self r9: (aRegisterStateArray at: 10).
	self r10: (aRegisterStateArray at: 11).
	self fp: (aRegisterStateArray at: 12).
	self r12: (aRegisterStateArray at: 13).
	self sp: (aRegisterStateArray at: 14).
	self lr: (aRegisterStateArray at: 15).
	self pc: (aRegisterStateArray at: 16).
	self eflags:  (aRegisterStateArray at: 17).
]

{ #category : #accessing }
GdbARMAlien >> sflag [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
	^self unsignedLongAt: 585
]

{ #category : #accessing }
GdbARMAlien >> sflag: unsignedInteger [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
	^self unsignedLongAt: 585 put: unsignedInteger
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
	self pushWord: self fp in: aMemory.
	self fp: self sp.
	PostBuildStackDelta ~= 0 ifTrue:
		[self sp: self sp - PostBuildStackDelta]. "In order to satisfy the CStackAlignment check by cogit, which is only valid on IA32 platforms."
	self pc: address
]

{ #category : #'execution simulation' }
GdbARMAlien >> simulateJumpCallOf: address memory: aMemory [
	"Simulate a frame-building jump of address.  Build a frame since
	a) this is used for calls into the run-time which are unlikely to be leaf-calls"
	"This method builds a stack frame as expected by the simulator, not as defined by ARM aapcs-abi.
	In ARM aapcs, every method can define for itself, wether it wants to push lr (nextpc), and wether it 
	uses a frame pointer. The standard never mentions a fp. It merely defines r4-r11 to be callee-saved."

	self assert: self sp \\ 8 = 0. "This check ensures, that we conform with ARM abi. Before doing anything to the stack, we ensure 2-word alignment."
	self pushWord: self fp in: aMemory.
	self fp: self sp.
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
"simulate a return; this may get a bit more complicated since we are trying to compensate for the IA32 automagically pushing the return address whereas the ARM doesn't."
self halt.
	PostBuildStackDelta ~= 0 ifTrue:
		[self sp: self sp + PostBuildStackDelta].
	self fp: (self popWordIn: aMemory).
	self lr: (self popWordIn: aMemory).
	self pc: self lr
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> smashCallerSavedRegistersWithValuesFrom: base by: step [
	self callerSavedSmashRegisterAccessors
	   withIndexDo:
		[:accessor :index|
		self perform: accessor with: index - 1 * step + base]
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
GdbARMAlien >> tflag [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
"This would be the Thumb flag if we have it -which depends rather oddly on the compiletime flags used to build the ARMulator. Sigh"
	^self unsignedLongAt: 589
]

{ #category : #accessing }
GdbARMAlien >> tflag: unsignedInteger [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
"This would be the Thumb flag if we have it -which depends rather oddly on the compiletime flags used to build the ARMulator. Sigh"
	^self unsignedLongAt: 589 put: unsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> vflag [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
	^self unsignedLongAt: 577
]

{ #category : #accessing }
GdbARMAlien >> vflag: unsignedInteger [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
	^self unsignedLongAt: 577 put: unsignedInteger
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> voidRegisterState [
	"N.B. keep in sync with setRegisterState:"
	self setRegisterState: (Array new: 17 withAll: 0)
]

{ #category : #printing }
GdbARMAlien >> writePopPushDetailsIn: memory in: transcript for: aCogit [ 
	"if the next instruction is a pop or push, or a ldr/str that touches the
	SP, write the details ontranscript"
	| instr |
	[instr := memory unsignedLongAt: self pc + 1 bigEndian: false]
		on: Error
		do: [:ex | ^ self].
	(self instructionIsPop: instr)
		ifTrue: [^transcript tab; nextPutAll: 'POP ' , (memory unsignedLongAt: self sp + 1 bigEndian: false) hex , ' from ' , self sp hex; cr].
	(self instructionIsPush: instr)
		ifTrue: [^transcript tab; nextPutAll: 'PUSH ' , (self register: (instr bitAnd: 61440)
							>> 12) hex , ' to ' , (self sp - 4) hex; cr].
	(self instructionIsLDRSP: instr)
		ifTrue: [| val |
			val := self r10 > memory size
						ifTrue: [aCogit simulatedVariableAt: self r10]
						ifFalse: [memory unsignedLongAt: self r10 + 1 bigEndian: false].
			^transcript tab; nextPutAll: 'LOAD SP ' , val hex , ' from ' , self r10 hex; cr].
	(self instructionIsSTRSP: instr)
		ifTrue: [^transcript tab; nextPutAll: 'STORE SP ' , self sp hex , ' to ' , self r10 hex; cr].
	(self instructionIsAlignSP: instr)
		ifTrue: [^transcript tab; nextPutAll: 'ALIGN SP ' , self sp hex; cr].
	(self instructionIsAddSP: instr) ifTrue:[^transcript tab; nextPutAll: 'ADD ', (instr bitAnd: 16rFF) asString,' to SP = ' , self sp hex; cr]
]

{ #category : #accessing }
GdbARMAlien >> zflag [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
	^self unsignedLongAt: 569
]

{ #category : #accessing }
GdbARMAlien >> zflag: unsignedInteger [
"The ARM cpsr flags are kept as individual fields in the Alien structure. The address here is the 1-based byte offset into the ARMul_State structure"
	^self unsignedLongAt: 569 put: unsignedInteger
]
