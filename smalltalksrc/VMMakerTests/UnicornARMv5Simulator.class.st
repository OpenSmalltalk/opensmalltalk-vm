Class {
	#name : #UnicornARMv5Simulator,
	#superclass : #UnicornSimulator,
	#category : #VMMakerTests
}

{ #category : #registers }
UnicornARMv5Simulator >> baseRegister [

	^ UcARMRegisters r10
]

{ #category : #registers }
UnicornARMv5Simulator >> classRegister [
	
	^ UcARMRegisters r2
]

{ #category : #'as yet unclassified' }
UnicornARMv5Simulator >> createUnicorn [

	^ Unicorn arm
]

{ #category : #disassembling }
UnicornARMv5Simulator >> disassembler [
	
	^ LLVMDisassembler armv5
]

{ #category : #executing }
UnicornARMv5Simulator >> doRunGeneratedCodeStartAt: initialAddress instructions: instructions [

	"The Cogit for ARM generates more instructions per abstract opcode.
	So, it is using the fact that all the instructions are 4 bytes to calculate the number of instructions.
	The number of instructions should be affected by the amount of literals that have been generated.
	As the literals are generated in the code, we have to skip their execution"

	| numberOfInstructions |
	numberOfInstructions := ((self getLastAddress: instructions) - initialAddress) / 4.

	^ unicorn startAt: initialAddress
		until: 0
		timeout: 0
		count: numberOfInstructions.
]

{ #category : #registers }
UnicornARMv5Simulator >> fp [
	^ self readRegister: UcARMRegisters fp
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

{ #category : #registers }
UnicornARMv5Simulator >> pc [
	^ self readRegister: UcARMRegisters pc
]

{ #category : #registers }
UnicornARMv5Simulator >> r0 [
	^ self readRegister: UcARMRegisters r0
]

{ #category : #registers }
UnicornARMv5Simulator >> r1 [
	^ self readRegister: UcARMRegisters r1
]

{ #category : #registers }
UnicornARMv5Simulator >> r10 [
	^ self readRegister: UcARMRegisters r10
]

{ #category : #registers }
UnicornARMv5Simulator >> r2 [
	^ self readRegister: UcARMRegisters r2
]

{ #category : #registers }
UnicornARMv5Simulator >> r3 [
	^ self readRegister: UcARMRegisters r3
]

{ #category : #registers }
UnicornARMv5Simulator >> r4 [
	^ self readRegister: UcARMRegisters r4
]

{ #category : #registers }
UnicornARMv5Simulator >> r5 [
	^ self readRegister: UcARMRegisters r5
]

{ #category : #registers }
UnicornARMv5Simulator >> r6 [
	^ self readRegister: UcARMRegisters r6
]

{ #category : #registers }
UnicornARMv5Simulator >> r7 [
	^ self readRegister: UcARMRegisters r7
]

{ #category : #registers }
UnicornARMv5Simulator >> r8 [
	^ self readRegister: UcARMRegisters r8
]

{ #category : #registers }
UnicornARMv5Simulator >> r9 [
	^ self readRegister: UcARMRegisters r9
]

{ #category : #registers }
UnicornARMv5Simulator >> receiverRegister [
	
	^ UcARMRegisters r5
]

{ #category : #accessing }
UnicornARMv5Simulator >> registerDescriptors [

	^ #(lr pc sp fp r0 r1 r2 r3 r4 r5 r6 r7 r8 r9)
		collect: [ :e | 
			UnicornRegisterDescriptor new
				simulator: self;
				name: e;
				yourself ]
]

{ #category : #registers }
UnicornARMv5Simulator >> sendNumberOfArgumentsRegister [
	
	^ UcARMRegisters r6
]

{ #category : #registers }
UnicornARMv5Simulator >> sp [
	^ self readRegister: UcARMRegisters sp
]

{ #category : #registers }
UnicornARMv5Simulator >> stackPointerRegister [
	
	^ UcARMRegisters sp
]

{ #category : #executing }
UnicornARMv5Simulator >> startAt: begin until: until timeout: timeout count: count [ 

	| error result |
	result := self doStartAt: begin until: until timeout: timeout count: count.

	stopReason ifNotNil: [ 
		error := stopReason.
		stopReason := nil.
		error signal ].
	
	"If we did not stop for a known reason, verify the error code of the function"
	unicorn verifyErrorCode: result.
	
	"Verify we stopped because we arrived to the right end addres and not a timeout"
	(until = 0 or: [ self instructionPointerValue = until ]) ifFalse: [
		UnicornTimeout new
			target: until;
			signal ]
]

{ #category : #accessing }
UnicornARMv5Simulator >> wordSize [
	^ 4
]
