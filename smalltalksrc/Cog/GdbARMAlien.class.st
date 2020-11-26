"
I am a wrapper around the ARMulator CPU instance and emulator routines and I give access to disassembling using libopcodes. My C-part must be compiled with -DMODET, because otherwise my offsets are wrong by one field.
"
Class {
	#name : #GdbARMAlien,
	#superclass : #CogProcessorAlien,
	#type : #bytes,
	#classVars : [
		'BadCPUInstance',
		'ExecutionError',
		'InstructionPrefetchError',
		'LongConstReg',
		'LongConstStep',
		'LongConstValue',
		'MemoryLoadBoundsError',
		'MemoryWriteBoundsError',
		'NoError',
		'PanicError',
		'PostBuildStackDelta',
		'SomethingLoggedError',
		'UnsupportedOperationError'
	],
	#category : #'Cog-Processors'
}

{ #category : #'instance creation' }
GdbARMAlien class >> dataSize [
	^1792
]

{ #category : #'instance creation' }
GdbARMAlien class >> implementationClass [
	^Smalltalk wordSize = 8 ifTrue: [GdbARMAlien64] ifFalse: [self]
]

{ #category : #'class initialization' }
GdbARMAlien class >> initialize [
	"GdbARMAlien initialize"

	PostBuildStackDelta := 0.

	"Return errors from GdbARMPlugin.h"
	NoError := 0.
	ExecutionError := 1.
	BadCPUInstance := 2.
	MemoryLoadBoundsError := 3.
	MemoryWriteBoundsError := 4.
	InstructionPrefetchError := 5.
	PanicError := 6.
	UnsupportedOperationError := 7.
	SomethingLoggedError := 8
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
	^self r0
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> cResultRegister: aValue [
	self r0: aValue
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

{ #category : #accessing }
GdbARMAlien >> d0 [
	^self unsignedLongLongAt: 1533
]

{ #category : #accessing }
GdbARMAlien >> d0: anUnsignedInteger [
	^self unsignedLongLongAt: 1533 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d1 [
	^self unsignedLongLongAt: 1541
]

{ #category : #accessing }
GdbARMAlien >> d10 [
	^self unsignedLongLongAt: 1613
]

{ #category : #accessing }
GdbARMAlien >> d10: anUnsignedInteger [
	^self unsignedLongLongAt: 1613 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d11 [
	^self unsignedLongLongAt: 1621
]

{ #category : #accessing }
GdbARMAlien >> d11: anUnsignedInteger [
	^self unsignedLongLongAt: 1621 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d12 [
	^self unsignedLongLongAt: 1629
]

{ #category : #accessing }
GdbARMAlien >> d12: anUnsignedInteger [
	^self unsignedLongLongAt: 1629 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d13 [
	^self unsignedLongLongAt: 1637
]

{ #category : #accessing }
GdbARMAlien >> d13: anUnsignedInteger [
	^self unsignedLongLongAt: 1637 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d14 [
	^self unsignedLongLongAt: 1645
]

{ #category : #accessing }
GdbARMAlien >> d14: anUnsignedInteger [
	^self unsignedLongLongAt: 1645 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d15 [
	^self unsignedLongLongAt: 1653
]

{ #category : #accessing }
GdbARMAlien >> d15: anUnsignedInteger [
	^self unsignedLongLongAt: 1653 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d16 [
	^self unsignedLongLongAt: 1661
]

{ #category : #accessing }
GdbARMAlien >> d16: anUnsignedInteger [
	^self unsignedLongLongAt: 1661 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d17 [
	^self unsignedLongLongAt: 1669
]

{ #category : #accessing }
GdbARMAlien >> d17: anUnsignedInteger [
	^self unsignedLongLongAt: 1669 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d18 [
	^self unsignedLongLongAt: 1677
]

{ #category : #accessing }
GdbARMAlien >> d18: anUnsignedInteger [
	^self unsignedLongLongAt: 1677 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d19 [
	^self unsignedLongLongAt: 1685
]

{ #category : #accessing }
GdbARMAlien >> d19: anUnsignedInteger [
	^self unsignedLongLongAt: 1685 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d1: anUnsignedInteger [
	^self unsignedLongLongAt: 1541 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d2 [
	^self unsignedLongLongAt: 1549
]

{ #category : #accessing }
GdbARMAlien >> d20 [
	^self unsignedLongLongAt: 1693
]

{ #category : #accessing }
GdbARMAlien >> d20: anUnsignedInteger [
	^self unsignedLongLongAt: 1693 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d21 [
	^self unsignedLongLongAt: 1701
]

{ #category : #accessing }
GdbARMAlien >> d21: anUnsignedInteger [
	^self unsignedLongLongAt: 1701 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d22 [
	^self unsignedLongLongAt: 1709
]

{ #category : #accessing }
GdbARMAlien >> d22: anUnsignedInteger [
	^self unsignedLongLongAt: 1709 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d23 [
	^self unsignedLongLongAt: 1717
]

{ #category : #accessing }
GdbARMAlien >> d23: anUnsignedInteger [
	^self unsignedLongLongAt: 1717 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d24 [
	^self unsignedLongLongAt: 1725
]

{ #category : #accessing }
GdbARMAlien >> d24: anUnsignedInteger [
	^self unsignedLongLongAt: 1725 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d25 [
	^self unsignedLongLongAt: 1733
]

{ #category : #accessing }
GdbARMAlien >> d25: anUnsignedInteger [
	^self unsignedLongLongAt: 1733 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d26 [
	^self unsignedLongLongAt: 1741
]

{ #category : #accessing }
GdbARMAlien >> d26: anUnsignedInteger [
	^self unsignedLongLongAt: 1741 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d27 [
	^self unsignedLongLongAt: 1749
]

{ #category : #accessing }
GdbARMAlien >> d27: anUnsignedInteger [
	^self unsignedLongLongAt: 1749 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d28 [
	^self unsignedLongLongAt: 1757
]

{ #category : #accessing }
GdbARMAlien >> d28: anUnsignedInteger [
	^self unsignedLongLongAt: 1757 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d29 [
	^self unsignedLongLongAt: 1765
]

{ #category : #accessing }
GdbARMAlien >> d29: anUnsignedInteger [
	^self unsignedLongLongAt: 1765 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d2: anUnsignedInteger [
	^self unsignedLongLongAt: 1549 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d3 [
	^self unsignedLongLongAt: 1557
]

{ #category : #accessing }
GdbARMAlien >> d30 [
	^self unsignedLongLongAt: 1773
]

{ #category : #accessing }
GdbARMAlien >> d30: anUnsignedInteger [
	^self unsignedLongLongAt: 1773 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d31 [
	^self unsignedLongLongAt: 1781
]

{ #category : #accessing }
GdbARMAlien >> d31: anUnsignedInteger [
	^self unsignedLongLongAt: 1781 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d3: anUnsignedInteger [
	^self unsignedLongLongAt: 1557 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d4 [
	^self unsignedLongLongAt: 1565
]

{ #category : #accessing }
GdbARMAlien >> d4: anUnsignedInteger [
	^self unsignedLongLongAt: 1565 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d5 [
	^self unsignedLongLongAt: 1573
]

{ #category : #accessing }
GdbARMAlien >> d5: anUnsignedInteger [
	^self unsignedLongLongAt: 1573 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d6 [
	^self unsignedLongLongAt: 1581
]

{ #category : #accessing }
GdbARMAlien >> d6: anUnsignedInteger [
	^self unsignedLongLongAt: 1581 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d7 [
	^self unsignedLongLongAt: 1589
]

{ #category : #accessing }
GdbARMAlien >> d7: anUnsignedInteger [
	^self unsignedLongLongAt: 1589 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d8 [
	^self unsignedLongLongAt: 1597
]

{ #category : #accessing }
GdbARMAlien >> d8: anUnsignedInteger [
	^self unsignedLongLongAt: 1597 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien >> d9 [
	^self unsignedLongLongAt: 1605
]

{ #category : #accessing }
GdbARMAlien >> d9: anUnsignedInteger [
	^self unsignedLongLongAt: 1605 put: anUnsignedInteger
]

{ #category : #disassembly }
GdbARMAlien >> decorateDisassembly: anInstructionString for: aSymbolManager fromAddress: address [
"Decode what we can of the instruction and decorate it with useful stuff"
	| word opcode rotate mode operand memory addressinatorBlock|
	addressinatorBlock :=
		[:value| | string |
		(value notNil
		 and: [(string := aSymbolManager lookupAddress: value) notNil])
			ifTrue: [ ' = ', value hex, ' = ', string]
			ifFalse: ['']].
	
	word := (memory:= aSymbolManager objectMemory) longAt: address.
	(self instructionIsAnyB: word)
		ifTrue:
			[((self instructionIsB: word) or: [self instructionIsBL: word]) ifTrue:
				["We can extract the offset from a plain B/BL instruction"
				 operand := self extractOffsetFromBL: word..
				 operand := operand + address + 8 bitAnd: aSymbolManager addressSpaceMask].
			"We can't extract the offset from a  BX/BLX instructions register, unless we're at the current pc,
			 because otherwise its current value has nothing to do with the value when this instruction is executed."
			(self pc = address
			 and: [(self instructionIsBX: word) or: [self instructionIsBLX: word]]) ifTrue:
					[operand := (self perform: (self registerStateGetters at: (word bitAnd: 15) + 1))]]
		ifFalse:
			[(self instructionIsAnyLoadStore: word)
				ifTrue:
					[|baseR lit|
					"first see if this is a load via the varBase register - quick access globals. We'll trust
					that nobody makes a nasty instruction that uses this reg in a mean way" 
					operand := (baseR := (word >> 16 bitAnd: 15)) = CogARMCompiler VarBaseReg
									ifTrue: [aSymbolManager varBaseAddress + (word bitAnd: 1 << 12 - 1)]
									ifFalse: [self pc = address ifTrue:
												[(self register: baseR) + (self extractOffsetFromLoadStore: word)]].
					"See if this is a pc-relative literal load"
					baseR = CogARMCompiler PCReg ifTrue:
						[lit := memory longAt: (aSymbolManager backEnd pcRelativeAddressAt: address).
						 ^(aSymbolManager lookupAddress: lit)
							ifNotNil: [:label| anInstructionString, ' ', label]
							ifNil: [anInstructionString, ' ', lit hex]].
					"look for SP operations -pop/push"
					 (self instructionIsPush: word) ifTrue: "push - "
						[|srcR|
						srcR := word >>12 bitAnd: 16rF.
						^ (anInstructionString readStream upTo: $}), '}', (self pc = address ifTrue: ['  (', (self register: srcR) hex, ') to ',  (self sp - 4) hex] ifFalse: [''])].
					(self instructionIsPop: word) ifTrue: "pop - " 
						[^ (anInstructionString readStream upTo: $}), '}', (self pc = address ifTrue: ['  (', (memory longAt: self sp) hex, ') ' , ' from ' , self sp hex] ifFalse: [''])].

					"look for a ld/st of the sp"
					(self instructionIsLDRSP: word) ifTrue:
						[^anInstructionString, '; Load SP from ', (addressinatorBlock value: operand)].
					(self instructionIsSTRSP: word) ifTrue:
						[^anInstructionString, '; Save SP to ', (addressinatorBlock value: operand)]]
				ifFalse:
					["check for SP changers not relating to read/writing data"
					 (self instructionIsAlignSP: word) ifTrue:
						[^anInstructionString, ' ALIGN SP ', (self pc = address ifTrue: [self sp hex] ifFalse: [''])].
					 (self instructionIsAddSP: word) ifTrue:
						[^anInstructionString, ' ADD ', (word bitAnd: 16rFF) asString,' to SP ', (self pc = address ifTrue: ['= ' , self sp hex] ifFalse: [''])].

					 "check for the end of a mov/orr/orr/orr set filling a reg with a const"
					 opcode := word >> 21 bitAnd: 16rF.
					 (opcode ~= CogARMCompiler orOpcode
					  or: [aSymbolManager cogit backEnd literalLoadInstructionBytes = 4]) ifTrue:
						[^anInstructionString].
					 rotate := word >> 8 bitAnd: 16rF.
					 mode := word >> 25 bitAnd: 7.
					 "CogARMCompiler always uses a 0 rotate in the last operand of the final ORR when building long constants."
					 (mode = 1 and: [rotate ~= 0]) ifTrue:
						[^anInstructionString].
					 operand := aSymbolManager backEnd literalBeforeFollowingAddress: address + 4]].
	"is there an interesting address with this?"
	^anInstructionString, (addressinatorBlock value: operand)
]

{ #category : #disassembly }
GdbARMAlien >> disassembleFrom: startAddress to: endAddress in: memory for: aSymbolManager "<Cogit>" labels: labelDictionary on: aStream [
	| address |
	address := startAddress.
	[address <= endAddress] whileTrue:
		[[:sizeArg :stringArg| | size string index offset |
		size := sizeArg.
		string := stringArg.
		(aSymbolManager labelForPC: address) ifNotNil:
			[:label| aStream nextPutAll: label; nextPut: $:; cr].
		(labelDictionary at: address ifAbsent: []) ifNotNil:
			[:label|
			self printLabel: label on: aStream at: address for: aSymbolManager.
			label isArray ifTrue:
				[string := nil.
				 size := label third]].
		string ifNotNil:
			[aStream nextPutAll: (self decorateDisassembly: string for: aSymbolManager fromAddress: address).
			 (string includesSubstring: ': ldr	') ifTrue:"i.e. colon space 'ldr' tab" 
				[(index := string indexOfSubCollection: ' [pc, #' startingAt: 1) > 0
					ifTrue:
						[offset := Integer readFrom: (ReadStream on: string from: index + 7 to: (string indexOf: $] startingAt: index + 7) - 1)]
					ifFalse:
						[(string indexOfSubCollection: ' [pc]' startingAt: 1) > 0 ifTrue:
							[offset := 0]].
				 offset ifNotNil:
					[offset := address + 8 + offset.
					 labelDictionary
						at: offset
						ifPresent:
							[:entry|
							entry isString
								ifTrue: [labelDictionary at: offset put: {#literal. offset. 4. entry}]
								ifFalse: [self assert: (entry isArray and: [entry first == #literal])]]
						ifAbsentPut: [{#literal. offset. 4}]]]].
		aStream cr; flush.
		address := address + size]
			valueWithArguments: (self
									primitiveDisassembleAt: address
									inMemory: memory)].
	(labelDictionary at: address ifAbsent: []) ifNotNil:
		[:label| self printLabel: label on: aStream at: address for: aSymbolManager]
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

{ #category : #'accessing-abstract' }
GdbARMAlien >> extractOffsetFromLoadStore: instr [
"work out the address offset implied by instr.
We assume it has been determined it is actually a load store before attaching any meaning to the result.
If it is post-indexed, then the offset must be 0, no matter what else is encoded.
If the instr is immediate-offset, pull the relevent bits out of instr.
If it is register-offset, pull the value from the indicated register."
	|offset shiftAmt shiftType |

	"post-indexed means no offset to the read address"
	(instr bitAnd: 1 << 24) = 0 ifTrue:[^0].
	
	(self instructionIsImmediateOffsetLoadStore: instr)
		ifTrue:["two cases apply - a 12bit immediate for 010 group instructions and an 8bit for 000 group ldrh stuff"
			(instr >> 25 bitAnd: 7) = 2
				ifTrue:[ "immed word or byte op, with 12bit offset"
					offset := instr bitAnd: 16rFFF]
				ifFalse:["halfword 8bit offset"
					offset := (instr bitAnd: 16rF00)>>4 bitOr: (instr bitAnd: 16rF)]].

	(self instructionIsRegisterOffsetLoadStore: instr)
		ifTrue:["both forms use same offset-reg encoding"
			offset := self perform:(self registerStateGetters at:(instr bitAnd: 16rF) + 1).
			(instr >> 25 bitAnd: 7) = 3
				ifTrue:[ "register offset with assorted modifiers"
					"sort out modifiers"
					shiftType := instr >> 5 bitAnd: 3.
					shiftAmt := instr  >>7 bitAnd: 16r1F.
					shiftType = 0"lsl" ifTrue:[offset := offset << shiftAmt.].
					shiftType = 1"lsr" ifTrue:[offset := offset >> shiftAmt].
					shiftType = 2"asr" ifTrue:[offset := offset  >>> shiftAmt].
					"I refuse to countenance using ROR or RRX here. Just Say No" ]
				"halfword stuff register offset uses no modifiers in the form we suport. See ARM DDI0406A p. A8-156"].

	"all forms have the bit 23 up/down flag to account for"
	(instr bitAnd: 1<<23) = 0
						ifTrue:["-ve offset" ^offset negated]
						ifFalse:["+ve offset" ^offset]	
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

{ #category : #accessing }
GdbARMAlien >> fpCPSR [
"The VFP cpsr flags are kept as a single word in the Alien structure. Return just the top 4 bits, the actual flags"
	^(self unsignedLongAt: 1789) >>28
]

{ #category : #'floating-point emulation' }
GdbARMAlien >> handleBasicDoubleArithmetic: instr at: pc [
	"Emulate a basic math - add/sub/mul/div -  VFP instruction."
	| rn rd rm vn vm |
	rn := instr >> 16 bitAnd: 15.
	rd := instr >> 12 bitAnd: 15.
	rm := instr bitAnd: 15.
	vn := Float fromIEEE64BitWord: (self perform: (self registerStateGetters at: rn + 18)). "Assume accesses fp regs"
	vm := Float fromIEEE64BitWord: (self perform: (self registerStateGetters at: rm + 18)). "Assume accesses fp regs"

	"simplest to match the entire instruction pattern rather than mess around shifting and masking and merging"
	(instr  bitAnd: 16rFF00FF0)
		caseOf: {
		[16rE200B00 "FMULD"]	->
			[| r |
			 r := vn * vm.
			 self perform: (self registerStateSetters at: rd + 18) with: r asIEEE64BitWord].
		[16rE300B00 "FADDD"]	->
			[| r |
			 r := vn + vm.
			 self perform: (self registerStateSetters at: rd + 18) with: r asIEEE64BitWord].
		[16rE300B40 "FSUBD"]	->
			[| r |
			 r := vn - vm.
			 self perform: (self registerStateSetters at: rd + 18) with: r asIEEE64BitWord].
		[16rE800B00"FDIVD"]	->
			[| r |
			 r := vn / vm.
			 self perform: (self registerStateSetters at: rd + 18) with: r asIEEE64BitWord].}
		otherwise: [self reportPrimitiveFailure].
	self pc: pc + 4
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
	| pcOnEntry pc instr |
	pc := pcOnEntry := self pc.
	self endCondition = InstructionPrefetchError ifTrue:
		[pc := self pc: self priorPc].

	(pc between: minimumAddress and: memoryArray byteSize - 1) ifTrue:
		[instr := memoryArray unsignedLongAt:  pc + 1 bigEndian: false.

		 (self endCondition = InstructionPrefetchError) ifTrue:
			[^self handleFailingBranch: instr to: pcOnEntry at: pc].

		 (self instructionIsAnyLoadStore: instr) ifTrue:
			[^self handleFailingLoadStore: instr at: pc].

		 (self instructionIsAnyFPArithmetic: instr) ifTrue:
			[^self handleFailingFPArithmetic: instr at: pc].

		 ^self handleExecutionPrimitiveFailureAt: pc in: memoryArray].

	^self reportPrimitiveFailure
]

{ #category : #'floating-point emulation' }
GdbARMAlien >> handleExtendedDoubleArithmetic: instr at: pc [
	"Emulate an extended math - cmp/sqrt/sitod -  VFP instruction."
	| rn rd rm vn vm vd |
	rn := instr >> 16 bitAnd: 15.
	rd := instr >> 12 bitAnd: 15.
	rm := instr bitAnd: 15.
	vn := Float fromIEEE64BitWord: (self perform: (self registerStateGetters at: rn + 18)). "Assume accesses fp regs"
	vm := Float fromIEEE64BitWord: (self perform: (self registerStateGetters at: rm + 18)). "Assume accesses fp regs"

	"simplest to match the entire instruction pattern rather than mess around shifting and masking and merging"
	(instr  bitAnd: 16rFF00FF0)
		caseOf: {
		[16rEB80B80 "FCMPD"]	->
			["read rd, compare with rm (ignore rn) and set FPSCR NZCV flags. Sigh"
				vd := Float fromIEEE64BitWord: (self perform: (self registerStateGetters at: rd + 18)).
				self break].
		[16rEB80BC0 "FSITOD"]	->
			[| r |
			 r := vm asFloat.
			 self perform: (self registerStateSetters at: rd + 18) with: r asIEEE64BitWord].
		[16rEB10BC0 "FSQRTD"]	->
			[| r |
			 r := vm sqrt.
			 self perform: (self registerStateSetters at: rd + 18) with: r asIEEE64BitWord].
		}
		otherwise: [self reportPrimitiveFailure].
	self pc: pc + 4
]

{ #category : #'floating-point emulation' }
GdbARMAlien >> handleFPLoadStore: instr at: pc [
	"Emulate a VFP load/store instruction."
	| rn rd offset |
	rn := instr >> 16 bitAnd: 15.
	rd := instr >> 12 bitAnd: 15.
	offset := instr bitAnd: 16rFF.

	"examine the U and Lbits"
	(instr >>20  bitAnd: 16rF)
		caseOf: {
		[0"Store neg"]	->
			[| r addr|
			addr := (self register: rn) - (offset<<2).
			 r := self perform: (self registerStateGetters at: rd + 18).
			 self unsignedLongLongAt: addr put: r].
		[1"Load neg"]	->
			[| r addr|
			addr := (self register: rn) - (offset<<2).
			r := self unsignedLongLongAt: addr.
			 self perform: (self registerStateSetters at: rd + 18) with: r ].
		[8"Store pos"]	->
			[| r addr|
			addr := (self register: rn) + (offset<<2).
			 r := self perform: (self registerStateGetters at: rd + 18).
			 self unsignedLongLongAt: addr put: r].
		[9"Load pos"]	->
			[| r addr|
			addr := (self register: rn) + (offset<<2).
			r := self unsignedLongLongAt: addr.
			 self perform: (self registerStateSetters at: rd + 18) with: r ].}
		otherwise: [self reportPrimitiveFailure].
	self pc: pc + 4
]

{ #category : #'floating-point emulation' }
GdbARMAlien >> handleFPStatus: instr at: pc [
	"Emulate transferring the FP status to the ARM CPSR."
	| fpcpsr |
	fpcpsr := self fpCPSR.
	self vflag: (fpcpsr bitAnd: 1).
	self cflag: ((fpcpsr >>1) bitAnd: 1).
	self zflag: ((fpcpsr >>2) bitAnd: 1).
	self nflag: ((fpcpsr >>3) bitAnd: 1).
	self pc: pc + 4
]

{ #category : #'error handling' }
GdbARMAlien >> handleFailingBranch: instr to: address at: pc [
	(self instructionIsBL: instr) ifTrue:
		[self assert: address = (pc + 8 + (self extractOffsetFromBL: instr)) signedIntToLong.
		 ^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4
				address: (pc + 8 + (self extractOffsetFromBL: instr)) signedIntToLong
				type: #call)
			signal].
	(self instructionIsBLX: instr) ifTrue:
		[self assert: address = (self perform: (self registerStateGetters at: (instr bitAnd: 15) + 1)).
		 ^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4
				address: (self perform: (self registerStateGetters at: (instr bitAnd: 15) + 1))
				type: #call)
			signal].
	(self instructionIsBX: instr) ifTrue:
		[self assert: address = (self perform: (self registerStateGetters at: (instr bitAnd: 15) + 1)).
		 ^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4
				address: (self perform: (self registerStateGetters at: (instr bitAnd: 15) + 1))
				type: #jump)
			signal].
	(self instructionIsB: instr) ifTrue:
		[self assert: address = (pc + 8 + (self extractOffsetFromBL: instr)) signedIntToLong.
		 ^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4
				address: (pc + 8 + (self extractOffsetFromBL: instr)) signedIntToLong
				type: #jump)
			signal].
	(self instructionIsReturnViaLR: instr) ifTrue:
		[^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4
				address: self lr
				type: #return)
			signal].
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
GdbARMAlien >> handleFailingFPArithmetic: instr at: pc [
	
	"basic arithmetic"
	(instr bitAnd: 16rF400FB0) = 16rE000B00 ifTrue:
		[^self handleBasicDoubleArithmetic: instr at: pc].
	
	"extension instructions sqrt/cmp/sitod"
	(instr bitAnd: 16rFF00F70) = 16rEB00B40 ifTrue:
		[^self handleExtendedDoubleArithmetic: instr at: pc].
	
	"move ARM reg to coproc reg. "
	(instr bitAnd: 16rFF00FFF) = 16rE000A10 ifTrue:
		[^self handleRegToDoubleTransfer: instr at: pc].

	"move FPSCR reg to ARM CPSR"
	(instr bitAnd: 16rFFFFFFF) = 16rEF1FA10 ifTrue:
		[^self handleFPStatus: instr at: pc].

	"load and store ops. All doubles; we only use FLDD & FSTD"
	(instr bitAnd: 16rF600F00) = 16rD000B00 ifTrue:
		[^self handleFPLoadStore: instr at: pc].
	
	
	^self reportPrimitiveFailure
]

{ #category : #'error handling' }
GdbARMAlien >> handleFailingLoadStore: instr at: pc [
	"See e.g. ARM DDI0406A pp. A8-120, 124, 128, 132, 152, 156, etc. etc"
	| baseReg destReg srcReg offset |

	"find the register used as the base of the address and the register to load into or store from"
	baseReg := self registerStateGetters at: (instr >> 16 bitAnd: 15)+ 1.
	srcReg :=  self registerStateGetters at: (instr >> 12 bitAnd: 15)+ 1.
	destReg := self registerStateSetters at: (instr >> 12 bitAnd: 15) + 1.

	"work out the relevant offset, whether an immediate or register value"
	offset := self extractOffsetFromLoadStore: instr.
	
	(self instructionIsLDR: instr) ifTrue:
		[^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4 
				address: (self perform: baseReg) + offset
				type: #read
				accessor: destReg)
			signal].
	(self instructionIsLDRB: instr) ifTrue:
		[^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4 
				address: (self perform: baseReg) + offset
				type: #read
				accessor: destReg)
			signal].
	(self instructionIsLDRH: instr) ifTrue:
		[^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4 
				address: (self perform: baseReg) + offset
				type: #read
				accessor: destReg)
			signal].
	(self instructionIsSTR: instr) ifTrue:
		[^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4 
				address: (self perform: baseReg) + offset
				type: #write
				accessor: srcReg)
			signal].
	(self instructionIsSTRB: instr) ifTrue:
		[^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4 
				address: (self perform: baseReg) + offset
				type: #write
				accessor: srcReg)
			signal].
	(self instructionIsSTRH: instr) ifTrue:
		[^(ProcessorSimulationTrap
				pc: pc
				nextpc: pc + 4 
				address: (self perform: baseReg) + offset
				type: #write
				accessor: srcReg)
			signal].

	self error: 'handleFailingLoadStore:at: invoked for non-load/store?'
]

{ #category : #'floating-point emulation' }
GdbARMAlien >> handleOneRegTransferDoubleArithmetic: instr at: pc [
	"Emulate a one-register transfer VFP instruction."
	| rn rd rm vn vm |
	rn := instr >> 16 bitAnd: 15.
	rd := instr >> 12 bitAnd: 15.
	rm := instr bitAnd: 15.
	vn := Float fromIEEE64BitWord: (self perform: (self registerStateGetters at: rn + 18)). "Assume accesses fp regs"
	vm := Float fromIEEE64BitWord: (self perform: (self registerStateGetters at: rm + 18)). "Assume accesses fp regs"
	(instr >> 18 bitAnd: 31)
		caseOf: {
		[8 "FMULD"]	->
			[| r |
			 r := vn * vm.
			 self perform: (self registerStateSetters at: rd + 18) with: r asIEEE64BitWord].
		[12"FADDD/FSUBD"]	->
			[self shouldBeImplemented].
		[32"FDIVD"]	->
			[self shouldBeImplemented].
		[45"FCMPD"]	->
			[self shouldBeImplemented]. }
		otherwise: [self reportPrimitiveFailure].
	self pc: pc + 4
]

{ #category : #'floating-point emulation' }
GdbARMAlien >> handleRegToDoubleTransfer: instr at: pc [
	"Emulate an ARM to VFP instruction."
	| rn rd vn |
	rn := (instr >> 16 bitAnd: 15) << 1 bitOr: (instr >>6 bitAnd: 1).
	rd := instr >> 12 bitAnd: 15.
	vn := self register: rn.

	self perform: (self registerStateSetters at: rd + 18) with: vn.
	self pc: pc + 4
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
	aCogit setStackAlignment: 8 expectedSPOffset: 0 expectedFPOffset: 0.
	PostBuildStackDelta := 0
]

{ #category : #testing }
GdbARMAlien >> instructionIsAddSP: instr [
"is this an add sp, sp, #? -  instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: (16rFFFFF00)) = (16r28DD000)]
]

{ #category : #testing }
GdbARMAlien >> instructionIsAlignSP: instr [
"is this a subs sp, sp, #4 -  instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: (16rFFFFFFF)) = (16r2DDD004)]
]

{ #category : #testing }
GdbARMAlien >> instructionIsAnyB: instr [ 
	"is this any of the B BX BL or BLX <offset> instructions?"
	^ (self instructionIsB: instr)
		or: [self instructionIsBL: instr]
		or: [self instructionIsBLX: instr]
		or: [self instructionIsBX: instr]
]

{ #category : #testing }
GdbARMAlien >> instructionIsAnyFPArithmetic: instr [
	"Identify VFP instructions.
	 See C3.1 - C3.4 in the ARM ARM v5 DDI01001."
	| cp isFP |
	
	"All FP instructions are coprocessor instructions on coproc 10 or 11"
	cp := instr>>8 bitAnd: 16rF.
	isFP := cp = 10 or:[cp = 11].
	(isFP and: [(instr>>25 bitAnd: 7) = 6]) ifTrue: [^true].
	(isFP and: [(instr>>24 bitAnd: 16rF) = 16rE]) ifTrue: [^true].
	
	"nope"
	^false
]

{ #category : #testing }
GdbARMAlien >> instructionIsAnyLoadStore: instr [
	"is this any of the LDR,STR instructions?
	We handle byte, word, and halfword versions but NOT NOT signed extend, double or privileged versions"
	
	^(self instructionIsImmediateOffsetLoadStore: instr) or:[self instructionIsRegisterOffsetLoadStore: instr]
]

{ #category : #testing }
GdbARMAlien >> instructionIsB: instr [
"is this a B <offset> instruction?"
	"first test for non-NV condition code; some important instructions use it"
	instr >> 28 = 16rF ifTrue:[^false].
	"See ARM DDI0406A p. A8-44"
	^ (instr bitAnd: (16rF<<24)) = (16rA<<24)
]

{ #category : #testing }
GdbARMAlien >> instructionIsBL: instr [
"is this a BL <offset> instruction?"
	"first test for non-NV condition code; some important instructions use it"
	instr >> 28 = 16rF ifTrue:[^false].
	"see ARM DDI0406A p. A8-58"
	^(instr bitAnd: (16rF<<24)) = (16rB<<24)
]

{ #category : #testing }
GdbARMAlien >> instructionIsBLX: instr [
"is this a BLX <targetReg> instruction? We DO NOT support the BLX immed version"
	"first test for non-NV condition code; some important instructions use it"
	instr >> 28 = 16rF ifTrue:[^false].
	"See ARM DDI0406A p A8-60"
 	^(instr bitAnd: 16r0FFFFFF0) = 16r12FFF30
]

{ #category : #testing }
GdbARMAlien >> instructionIsBX: instr [
"is this a BX <targetReg> instruction?"
	"first test for non-NV condition code; some important instructions use it"
	instr >> 28 = 16rF ifTrue:[^false].
	"See ARM DDI0406A p. A8-62"
 	^(instr bitAnd: 16r0FFFFFF0) = 16r12FFF10
]

{ #category : #testing }
GdbARMAlien >> instructionIsImmediateOffsetLoadStore: instr [
	"is this any of the immediate offset LDR,STR instructions?"
	| op1 |
	"first test for non-NV condition code; some important instructions use it"
	instr >> 28 = 16rF ifTrue:[^false].
	"test for 010 group of load/stores"
	op1 := instr >>25 bitAnd: 7.
	op1 = 2 ifTrue:[^true].

	"test for the ridiculously muddled 000 group"
	op1 > 0 ifTrue:[^false].
	"bit 21 must not be 1 and bit 22 must be 1"
	(instr bitAnd: 3 <<21) = (2<<21) ifFalse:[^false].
	"bits 4:7need to be 16rB for our purpose"
	^(instr bitAnd: 16rF0) = 16rB0
	
	
]

{ #category : #testing }
GdbARMAlien >> instructionIsLDR: instr [
"is this a LDR instruction?"
	| foo |
	"first test for non-NV condition code; some important instructions use it"
	instr >> 28 = 16rF ifTrue:[^false].
	"See ARM DDI0406A p. A8-120"
	foo := (instr >> 20 bitAnd: 16rE5).
	^foo = 16r41 "ldr r1, [r2, #+/-imm]"
		or:[foo = 16r61 "ldr r1, [r2, r3]"]
]

{ #category : #testing }
GdbARMAlien >> instructionIsLDRB: instr [
"is this a LDRB instruction?"
	| foo |
	"first test for non-NV condition code; some important instructions use it"
	instr >> 28 = 16rF ifTrue:[^false].
	"See ARM DDI0406A p. A8-128"
	foo := (instr >> 20 bitAnd: 16rE5).
	^foo = 16r45 "ldrb r1, [r2, #+/-imm]"
		or:[foo = 16r65 "ldrb r1, [r2, r3]"]
]

{ #category : #testing }
GdbARMAlien >> instructionIsLDRH: instr [
"is this a LDRH instruction?"
	| foo |
	"first test for non-NV condition code; some important instructions use it"
	instr >> 28 = 16rF ifTrue:[^false].
	"See ARM DDI0406A p. A8-154"
	(instr bitAnd: 16rF0) = 16rB0 ifFalse:[^false].
	foo := (instr >> 20 bitAnd: 16rE3).
	^foo = 16r3 "ldrh r1, [r2, #+/-imm]"
		or:[foo = 16r1 "ldrh r1, [r2, r3]"]
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
GdbARMAlien >> instructionIsRegisterOffsetLoadStore: instr [
	"is this any of the register offset LDR,STR instructions?"
	| op1 |
	"first test for non-NV condition code; some important instructions use it"
	instr >> 28 = 16rF ifTrue:[^false].
	
	op1 := instr >>25 bitAnd: 7.
	"test for the 011 group - check bit 4 as well"
	(op1 = 3 and:[(instr bitAnd: 16r10) = 0]) ifTrue:[^true].
	"test for the ridiculously muddled 000 group"
	op1 > 0 ifTrue:[^false].
	"bit 21 & 22 must not be 1"
	(instr bitAnd: 3 <<21) = 0 ifFalse:[^false].
	"bits 4:7need to be 16rB for our purpose"
	^(instr bitAnd: 16rF0) = 16rB0
	
	
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
	"first test for non-NV condition code; some important instructions use it"
	instr >> 28 = 16rF ifTrue:[^false].
	"See ARM DDI0406A p. A8-382"
 	foo := (instr >> 20 bitAnd: 16rE5). 
	^foo = 16r40 "str r1, [r2, #+/-imm]" 
		or:[foo = 16r60] "str r1, [r2, #-imm]"
]

{ #category : #testing }
GdbARMAlien >> instructionIsSTRB: instr [
"is this a STRB instruction?"
	| foo |
	"first test for non-NV condition code; some important instructions use it"
	instr >> 28 = 16rF ifTrue:[^false].
	"See ARM DDI0406A p. A8-388"
 	foo := (instr >> 20 bitAnd: 16rE5). 
	^foo = 16r44 "strb r1, [r2, #+/-imm]" 
		or:[foo = 16r64] "strb r1, [r2, #-imm]"
]

{ #category : #testing }
GdbARMAlien >> instructionIsSTRH: instr [
"is this a STRH instruction?"
	| foo |
	"first test for non-NV condition code; some important instructions use it"
	instr >> 28 = 16rF ifTrue:[^false].
	"See ARM DDI0406A p. A8-154"
	(instr bitAnd: 16rF0) = 16rB0 ifFalse:[^false].
	foo := (instr >> 20 bitAnd: 16rE3).
	^foo = 16r4 "strh r1, [r2, #+/-imm]"
		or:[foo = 16r0 "strh r1, [r2, r3]"]
]

{ #category : #testing }
GdbARMAlien >> instructionIsSTRSP: instr [
"is this a STR sp, [??] instruction? Special case to detect STR sp, [] affecting stack pointer"
	^(self instructionIsSTR: instr)  and:[(instr >>12 bitAnd: 16rF) = 13]
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> integerRegisterState [
	^{	self r0. self r1. self r2. self r3. self r4. self r5. self r6. self r7. self r8. 
		self r9. self sl. self fp. self r12. self sp. self lr. self pc}
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
			ifTrue: [self perform: (self registerStateGetters at: i)]
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
GdbARMAlien >> printLabel: label on: aStream at: address for: aSymbolManager [
	"Print label on aStream.  The label is either a triple of {type, printer, size} or a simple string."
	label isArray
		ifTrue: [label first == #literal
					ifTrue:
						[label size = 4 ifTrue:
							[aStream nextPutAll: label last; nextPut: $:; cr].
						 aStream
							nextPutAll: (address printStringBase: 16 length: 8 padded: true) asLowercase;
							nextPut: $:; space;
							nextPutAll: ((aSymbolManager objectMemory longAt: address) printStringBase: 16 length: 8 padded: true) asLowercase.
						 (aSymbolManager lookupAddress: (aSymbolManager objectMemory longAt: address)) ifNotNil:
							[:name| aStream space; nextPutAll: name]]
					ifFalse:
						[aStream
							nextPutAll: label first;
							nextPut: $:; cr;
							nextPutAll: (address printStringBase: 16 length: 8 padded: true) asLowercase;
							nextPut: $:; space;
							nextPutAll: (aSymbolManager perform: label second with: address) asString]]
		ifFalse: [aStream nextPutAll: label; nextPut: $:; cr]
]

{ #category : #printing }
GdbARMAlien >> printOn: aStream [
	| first |
	first := true.
	aStream nextPutAll: 'an ARMAlien ('.
	self registerState with: self registerStateGetters do: [ :state :getter |
		first
			ifTrue: [first := false]
			ifFalse: [aStream << ', '].
		getter first = $d
			ifTrue:
				[aStream
					<< getter << ': '
					<< (Float fromIEEE64BitWord: state)]
			ifFalse:
				[getter == #eflags
					ifTrue:
						[aStream
							<< 'NZCVIF: '
							<< (state printStringBase: 2 length: 6 padded: true)]
					ifFalse:
						[aStream
							<< getter << ': '
							<< (state printStringBase: 16)]]]
]

{ #category : #printing }
GdbARMAlien >> printRegisterState: registerStateVector on: aStream [
	self printFields: #(	r0 r1 r2 r3 cr
						r4 r5 r6 r7 cr
						r8 r9 sl fp cr
						r12 sp lr pc eflags cr)
		inRegisterState: registerStateVector
		on: aStream
]

{ #category : #printing }
GdbARMAlien >> printRegisterStateExceptPC: registerStateVector on: aStream [
	self printFields: #(	r0 r1 r2 r3 cr
						r4 r5 r6 r7 cr
						r8 r9 sl fp cr
						r12 sp lr eflags cr)
		inRegisterState: registerStateVector
		on: aStream
]

{ #category : #accessing }
GdbARMAlien >> priorPc [
"where did the simulator stop just before a prefetch abort?"
	^self unsignedLongAt: 609
]

{ #category : #accessing }
GdbARMAlien >> priorPc: val [
"set the priorPC cached pc so it isn't random nonsense"
	^self unsignedLongAt: 609 put: val
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
	^self perform: (self registerStateGetters at: index + 1)
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> registerState [
	^{	self r0. self r1. self r2. self r3. self r4. self r5. self r6. self r7.
		self r8. self r9. self sl. self fp. self r12. self sp. self lr. self pc. self eflags.
		self d0. self d1. self d2. self d3. self d4. self d5. self d6. self d7.
		self d8. self d9. self d10. self d11. self d12. self d13. self d14. self d15 }
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> registerStateGetters [
	^#(	r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 sl fp r12 sp lr pc eflags
		d0 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14 d15)
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> registerStatePCIndex [
	^16
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> registerStateSetters [
	^#(	r0: r1: r2: r3: r4: r5: r6: r7: r8: r9: sl: fp: r12: sp: lr: pc: eflags:
		d0: d1: d2: d3: d4: d5: d6: d7: d8: d9: d10: d11: d12: d13: d14: d15:)
]

{ #category : #accessing }
GdbARMAlien >> reset [
	self priorPc: 0;
		primitiveResetCPU
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> retpcIn: aMemory [
	"The return address is on the stack, having been pushed by either
	 simulateCallOf:nextpc:memory: or simulateJumpCallOf:memory:"
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

	self pushWord: self lr in: aMemory.
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
	self pushWord: self lr in: aMemory.
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
	PostBuildStackDelta ~= 0 ifTrue:
		[self sp: self sp + PostBuildStackDelta].
	self fp: (self popWordIn: aMemory).
	"According to tpr, most C compilers implement return by simply
	 popping into the pc, rather than popping through the link register."
	self pc: (self popWordIn: aMemory)
]

{ #category : #accessing }
GdbARMAlien >> sl [
	^self unsignedLongAt: 53
]

{ #category : #accessing }
GdbARMAlien >> sl: anUnsignedInteger [

	^self unsignedLongAt: 53 put: anUnsignedInteger
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> smashABICallerSavedRegistersWithValuesFrom: base by: step [
	"limited list of registers to clear out when simulating an ABI call.
	 Smash neither R0 nor R1 since many abi calls return 2 results or a 64-bit dual-reg value.
	 LR has to be left alone becasue a leaf call doesn't push it."

	#(r2: r3: r9: r12:) withIndexDo:
		[:accessor :index|
		self perform: accessor with: index - 1 * step + base]
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> smashCallerSavedRegistersWithValuesFrom: base by: step in: aMemory [
	#(r0: r1: r2: r3: r9: r12: lr:) withIndexDo:
		[:accessor :index|
		self perform: accessor with: index - 1 * step + base]
]

{ #category : #'accessing-abstract' }
GdbARMAlien >> smashRegisterAccessors [
	^#(r0: r1: r2: r3: r4: r5: r6: r7: r8: r9: r10: "11=FP" r12: "13=SP, 14=LR, 15=PC")
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
