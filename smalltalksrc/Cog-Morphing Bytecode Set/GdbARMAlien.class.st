Class {
	#name : #GdbARMAlien,
	#superclass : #CogProcessorAlien,
	#type : #bytes,
	#classVars : [
		'OpcodeExceptionMap',
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
	super initialize.
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
	offset := (aNumber - 8) asInteger >> 2.
	(offset bitAnd: 16rFF000000) ~= 0 ifTrue: [self error: 'The offset is to far. ARM does not support such far jumps.'].
	^ 16reb000000 bitOr: (offset bitAnd: 16r00FFFFFF)
]

{ #category : #opcodes }
GdbARMAlien >> callOpcode [
	"The call command does not generally exist. The most similar would be bl <offset>"
	^ self branchAndLinkOpcodeWithOffset: 0.
]

{ #category : #accessing }
GdbARMAlien >> cflag [
	^self unsignedLongAt: 577
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
GdbARMAlien >> handleExecutionPrimitiveFailureIn: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Handle an execution primitive failure.  Convert out-of-range call and absolute
	 memory read into register instructions into ProcessorSimulationTrap signals."
	"self printIntegerRegistersOn: Transcript"
	"self printRegistersOn: Transcript"
	
	"| pc opcode |
	((pc := self pc) between: minimumAddress and: memoryArray byteSize - 1) ifTrue:
		[opcode := memoryArray byteAt: pc + 1.
		^self
			perform: (OpcodeExceptionMap at: opcode + 1)
			with: pc
			with: memoryArray
			with: minimumWritableAddress]."
	^self reportPrimitiveFailure
]

{ #category : #accessing }
GdbARMAlien >> ifflags [
	^self unsignedLongAt: 585
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
	^ 16rE1A01001
]

{ #category : #accessing }
GdbARMAlien >> pc [
	^self unsignedLongAt: 73
]

{ #category : #accessing }
GdbARMAlien >> pc: anUnsignedInteger [

	^self unsignedLongAt: 73 put: anUnsignedInteger
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
GdbARMAlien >> primitiveRunInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Run the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 call, jump and memory read/writes into register instructions into ProcessorSimulationTrap signals."
	<primitive: 'primitiveRunInMemoryMinimumAddressReadWrite' module: 'GdbARMPlugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress
					readOnlyBelow: minimumWritableAddress]
		ifFalse: [self reportPrimitiveFailure]

	"self printRegistersOn: Transcript"
]

{ #category : #primitives }
GdbARMAlien >> primitiveSingleStepInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Single-step the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 call, jump and memory read/writes into register instructions into ProcessorSimulationTrap signals."
	<primitive: 'primitiveSingleStepInMemoryMinimumAddressReadWrite' module: 'GdbARMPlugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress
					readOnlyBelow: minimumWritableAddress]
		ifFalse: [self reportPrimitiveFailure]
]

{ #category : #printing }
GdbARMAlien >> printRegisterState: registerStateVector on: aStream [
	| rsvs fields|
	aStream ensureCr.
	rsvs := registerStateVector readStream.
	fields := #(	r0 r1 r2 r3 r4 r5 r6 cr r7 r8 r9 r10 r11 r12 cr sp lr pc eflags cr).
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

{ #category : #accessing }
GdbARMAlien >> reset [
	self primitiveResetCPU
]

{ #category : #opcodes }
GdbARMAlien >> retOpcode [
	"the ret command does not generally exist. the most similar would be mov pc, lr"
	^ self halt.
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
