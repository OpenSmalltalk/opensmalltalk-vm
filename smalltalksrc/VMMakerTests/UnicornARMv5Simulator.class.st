Class {
	#name : #UnicornARMv5Simulator,
	#superclass : #UnicornSimulator,
	#category : #'VMMakerTests-Unicorn'
}

{ #category : #registers }
UnicornARMv5Simulator >> arg0Register [
	
	^ UcARMRegisters r3
]

{ #category : #accessing }
UnicornARMv5Simulator >> argument0RegisterValue: anInteger [ 

	self writeRegister: UcARMRegisters r3 value: anInteger
]

{ #category : #registers }
UnicornARMv5Simulator >> baseRegister [

	^ UcARMRegisters r10
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> cResultRegister [
	
	^ self r0
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> cReturnRegisterValue: anInteger [ 

	self r0: anInteger 
]

{ #category : #registers }
UnicornARMv5Simulator >> classRegister [
	
	^ UcARMRegisters r2
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> convertIntegerToInternal: anInteger [ 

	anInteger < 0 ifFalse: [ ^ anInteger ].
	
	^ 16rFFFFFFFF - anInteger abs + 1
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> convertInternalToInteger: aTwoComplementNumber [

	(aTwoComplementNumber bitAnd: 1 << 31) = 0 ifTrue: [ 
		^ aTwoComplementNumber ].
	
	^ aTwoComplementNumber - 16rFFFFFFFF - 1
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> createUnicorn [

	"Enable Floating Point...
	https://github.com/unicorn-engine/unicorn/pull/447/files"

"
'00000000':	mov	r3, #15728640
'00000004':	mcr	p15, #0x0, r3, c1, c0, #0x2
'00000008':	isb	sy
'0000000C':	mov	r3, #1073741824
'00000010':	vmsr	fpexc, r3
"

	| bytes mappedMemory |
	bytes := #[ 
	16r0f 16r36 16ra0 16re3
	16r50 16r3f 16r01 16ree
	16r6f 16rf0 16r7f 16rf5
	16r01 16r31 16ra0 16re3
	16r10 16r3a 16re8 16ree ].

	"Put the instructions in a memory region of 4KB.
	Unicorn requires that memory regions are multiple of 4KB.
	Create a region of 4KB and map it also at a multiple of 4KB."
	mappedMemory := ByteArray new: 4096.
	mappedMemory replaceFrom: 1 to: bytes size with: bytes.
	unicorn := Unicorn arm.
	unicorn mapHostMemory: mappedMemory atAddress: 4096 withPermissions: UnicornConstants permissionAll.

	unicorn doStartAt: 4096 until: 0 timeout: 0 count: 5 "instructions".

	"Cleanup: unmap the memory so the ByteArray can be safely get garbage collected and that memory region can be reused"
	unicorn unmapMemoryAt: 4096 size: 4096.
	^ unicorn
]

{ #category : #disassembling }
UnicornARMv5Simulator >> disassembler [
	
	^ LLVMARMDisassembler armv7
]

{ #category : #executing }
UnicornARMv5Simulator >> doStartAt: startAddress until: until timeout: timeout count: count [

	| actualCount result error startTime remainingTimeout currentTime |

	"This implementation is almost the same, because ARMv5 does not accept correctly to run 
	more than one instruction. It has the problem that it misses the count or the current address"

	actualCount := 0.
	self instructionPointerValue: startAddress.
	startTime := Time millisecondClockValue.
	remainingTimeout := timeout.

	[ true ]
		whileTrue: [ 
			[result :=  unicorn
				startAt: self instructionPointerValue
				until: 0
				timeout: 0
				count: 1.
					
				stopReason ifNotNil: [ 
						error := stopReason.
						stopReason := nil.
						error signal ].
		
			"If execution did not stop because of a stop reason, verify the error code"
			unicorn verifyErrorCode: result.

			
					actualCount := actualCount + 1] 
				on: UnicornInvalidMemoryAccess do: [ :invalidAccess |
					self instructionPointerValue = until ifTrue: [ ^ 0 ].
					
					(self handleInvalidAccess: invalidAccess)
						ifFalse: [ ^ result ].
						
					actualCount := actualCount + 1 ].
			
			stopReason ifNotNil: [ ^ result ].
			count = actualCount ifTrue: [ ^ result ].


			timeout ~= 0 ifTrue: [  
				currentTime := Time millisecondClockValue.
				remainingTimeout := remainingTimeout - (currentTime - startTime).
				
				remainingTimeout <= 0
					ifTrue: [ 	
						UnicornTimeout new
								target: until;
								signal ]].

			self instructionPointerValue = until ifTrue: [ ^ result ]]
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> doublePrecisionFloatingPointRegister0Value [

	^ self readFloat64Register: UcARMRegisters d0
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> extractDestinationRegisterFromAssembly: aLLVMInstruction [ 
	
	"In ARM, instructions are usually encoded asSpotterCandidateLink 
	
	INST Destination, Source
	"
	
	^ (aLLVMInstruction assemblyCodeString substrings: String tab, ',') second trimBoth.
]

{ #category : #registers }
UnicornARMv5Simulator >> fp [
	^ self readRegister: UcARMRegisters fp
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> fp: anInteger [ 
	
	self writeRegister: UcARMRegisters fp value: anInteger
]

{ #category : #registers }
UnicornARMv5Simulator >> framePointerRegister [
	
	^ UcARMRegisters fp
]

{ #category : #accessing }
UnicornARMv5Simulator >> getLastAddress: abstractInstructions [ 
	
	| last |
	last := (abstractInstructions reject: [ :e | e isLiteral ]) last.
	^ last address + last machineCodeSize 
]

{ #category : #accessing }
UnicornARMv5Simulator >> getReturnAddress [
	
	^ self linkRegisterValue
]

{ #category : #testing }
UnicornARMv5Simulator >> hasLinkRegister [
	^ true
]

{ #category : #registers }
UnicornARMv5Simulator >> instructionPointerRegister [

	^ UcARMRegisters pc
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> integerRegisterState [
	
	^ #()
]

{ #category : #registers }
UnicornARMv5Simulator >> linkRegister [
	
	^ UcARMRegisters lr
]

{ #category : #accessing }
UnicornARMv5Simulator >> linkRegisterValue [

	^ self readRegister: self linkRegister 
]

{ #category : #registers }
UnicornARMv5Simulator >> linkRegisterValue: aValue [ 

	^ self writeRegister: self linkRegister value: aValue
]

{ #category : #registers }
UnicornARMv5Simulator >> lr [
	^ self readRegister: UcARMRegisters lr	
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> lr: anInteger [ 
	
	self writeRegister: UcARMRegisters lr value: anInteger
]

{ #category : #registers }
UnicornARMv5Simulator >> pc [
	^ self readRegister: UcARMRegisters pc
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> pc: anInteger [ 
	
	self writeRegister: UcARMRegisters pc value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> postCallArgumentsNumArgs: numArgs in: aMemory [ 
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

{ #category : #registers }
UnicornARMv5Simulator >> r0 [
	^ self readRegister: UcARMRegisters r0
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> r0: anInteger [ 
	
	^ self writeRegister: UcARMRegisters r0 value: anInteger
]

{ #category : #registers }
UnicornARMv5Simulator >> r1 [
	^ self readRegister: UcARMRegisters r1
]

{ #category : #registers }
UnicornARMv5Simulator >> r10 [
	^ self readRegister: UcARMRegisters r10
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> r10: anInteger [ 
	
	^ self writeRegister: UcARMRegisters r10 value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> r11: anInteger [ 
	
	^ self writeRegister: UcARMRegisters r11 value: anInteger
]

{ #category : #accessing }
UnicornARMv5Simulator >> r12 [
	
	^ self readRegister: UcARMRegisters r12
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> r12: anInteger [ 

	self writeRegister: UcARMRegisters r12 value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> r1: anInteger [ 
	
	^ self writeRegister: UcARMRegisters r1 value: anInteger
]

{ #category : #registers }
UnicornARMv5Simulator >> r2 [
	^ self readRegister: UcARMRegisters r2
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> r2: anInteger [ 
	
	^ self writeRegister: UcARMRegisters r2 value: anInteger
]

{ #category : #registers }
UnicornARMv5Simulator >> r3 [
	^ self readRegister: UcARMRegisters r3
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> r3: anInteger [ 
	
	^ self writeRegister: UcARMRegisters r3 value: anInteger
]

{ #category : #registers }
UnicornARMv5Simulator >> r4 [
	^ self readRegister: UcARMRegisters r4
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> r4: anInteger [ 
	
	^ self writeRegister: UcARMRegisters r4 value: anInteger
]

{ #category : #registers }
UnicornARMv5Simulator >> r5 [
	^ self readRegister: UcARMRegisters r5
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> r5: anInteger [ 
	
	^ self writeRegister: UcARMRegisters r5 value: anInteger
]

{ #category : #registers }
UnicornARMv5Simulator >> r6 [
	^ self readRegister: UcARMRegisters r6
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> r6: anInteger [ 
	
	^ self writeRegister: UcARMRegisters r6 value: anInteger
]

{ #category : #registers }
UnicornARMv5Simulator >> r7 [
	^ self readRegister: UcARMRegisters r7
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> r7: anInteger [ 
	
	^ self writeRegister: UcARMRegisters r7 value: anInteger
]

{ #category : #registers }
UnicornARMv5Simulator >> r8 [
	^ self readRegister: UcARMRegisters r8
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> r8: anInteger [ 
	
	^ self writeRegister: UcARMRegisters r8 value: anInteger
]

{ #category : #registers }
UnicornARMv5Simulator >> r9 [
	^ self readRegister: UcARMRegisters r9
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> r9: anInteger [ 
	
	^ self writeRegister: UcARMRegisters r9 value: anInteger
]

{ #category : #registers }
UnicornARMv5Simulator >> receiverRegister [
	
	^ UcARMRegisters r5
]

{ #category : #accessing }
UnicornARMv5Simulator >> registerList [

	^ #(lr pc sp fp r0 r1 r2 r3 r4 r5 r6 r7 r8 r9)
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> registerStateGetters [
	
	^#(r0 r1 r2 r3 r4)
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> retpcIn: aMemory [ 
	"The return address is on the stack, having been pushed by either
	 simulateCallOf:nextpc:memory: or simulateJumpCallOf:memory:"
	^aMemory unsignedLongAt: self fp + 5
]

{ #category : #registers }
UnicornARMv5Simulator >> sendNumberOfArgumentsRegister [
	
	^ UcARMRegisters r6
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> simulateJumpCallOf: address memory: aMemory [
	"Simulate a frame-building jump of address.  Build a frame since
	a) this is used for calls into the run-time which are unlikely to be leaf-calls"
	"This method builds a stack frame as expected by the simulator, not as defined by ARM aapcs-abi.
	In ARM aapcs, every method can define for itself, wether it wants to push lr (nextpc), and wether it 
	uses a frame pointer. The standard never mentions a fp. It merely defines r4-r11 to be callee-saved."

	self assert: self sp \\ 8 = 0. "This check ensures, that we conform with ARM abi. Before doing anything to the stack, we ensure 2-word alignment."
	self pushWord: self lr.
	self pushWord: self fp.
	self fp: self sp.
	self pc: address
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> simulateLeafCallOf: address nextpc: nextpc memory: aMemory [

	self lr: nextpc.
	self pc: address
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> simulateReturnIn: aSpurSimulatedMemory [

	self fp: self popWord.
	self pc: self popWord
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> smashCallerSavedRegistersWithValuesFrom: base by: step in: aMemory [
	#(r0: r1: r2: r3: r9: r12: lr:) withIndexDo:
		[:accessor :index|
		self perform: accessor with: index - 1 * step + base]
]

{ #category : #registers }
UnicornARMv5Simulator >> smashRegisterAccessors [

	^ #(r0: r1: r2: r3:)
]

{ #category : #registers }
UnicornARMv5Simulator >> sp [
	^ self readRegister: UcARMRegisters sp
]

{ #category : #registers }
UnicornARMv5Simulator >> stackPointerRegister [
	
	^ UcARMRegisters sp
]

{ #category : #accessing }
UnicornARMv5Simulator >> temporaryRegisterValue [
	
	^ self r0
]

{ #category : #accessing }
UnicornARMv5Simulator >> wordSize [
	^ 4
]
