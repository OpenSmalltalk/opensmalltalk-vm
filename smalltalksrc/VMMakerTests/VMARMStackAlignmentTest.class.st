Class {
	#name : #VMARMStackAlignmentTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#instVars : [
		'instructions'
	],
	#pools : [
		'CogAbstractRegisters'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #'building suites' }
VMARMStackAlignmentTest class >> testParameters [

	^ ParametrizedTestMatrix new
		addCase: { #ISA -> #'aarch64'. #wordSize -> 8};
		yourself
]

{ #category : #'as yet unclassified' }
VMARMStackAlignmentTest >> addInstruction: anInstruction [ 

	instructions add: anInstruction 
]

{ #category : #'as yet unclassified' }
VMARMStackAlignmentTest >> disassembleInstructions [

	^ self disassembleFrom: initialAddress opcodes: instructions size
]

{ #category : #'as yet unclassified' }
VMARMStackAlignmentTest >> runInstructions [

	^ self runFrom: initialAddress until: initialAddress + (instructions size * 4)
]

{ #category : #tests }
VMARMStackAlignmentTest >> setUp [

	super setUp.
	instructions := OrderedCollection new.
	
	machineSimulator stackPointerRegisterValue: interpreter rumpCStackAddress
]

{ #category : #tests }
VMARMStackAlignmentTest >> testUnAlignedStackWriteShouldGenerateError [
	"To start the stack pointer should be aligned"

	"Precondition for all tests. SP should be aligned to the stack alignment required by the platform"

	[ self stackPointerRegisterValue \\ cogit stackPointerAlignment = 0 ] 
		whileFalse: [ 
		self pushAddress: 16rBEEF "a small integer to mark..." ].

	self
		assert: machineSimulator stackPointerRegisterValue
			\\ cogit stackPointerAlignment
		equals: 0.

	machineSimulator
		writeRegister: UcARM64Registers sp
		value: machineSimulator stackPointerRegisterValue.


	self addInstruction: (cogit backend
			 movSize: 1
			 destinationRegister: ReceiverResultReg
			 imm: 12345
			 shift: 0).

	self addInstruction: (cogit backend
			 strSize: 1
			 baseRegister: 31
			 signedOffset: -8
			 sourceRegister: ReceiverResultReg
			 preIndex: 1). "word size, size of the elements in the stack" "Access before incrementing"

	self addInstruction: (cogit backend
			 strSize: 1
			 baseRegister: 31
			 signedOffset: -8
			 sourceRegister: ReceiverResultReg
			 preIndex: 1). "word size, size of the elements in the stack" "Access before incrementing"

	self writeInstructions.

	[	self runInstructions.
		self fail ]
		on: UnicornError
		do: [ :e | 
			self
				assert: e messageText
				equals: 'Unhandled CPU exception (UC_ERR_EXCEPTION)' ]
]

{ #category : #tests }
VMARMStackAlignmentTest >> testUnAlignedStackWriteShouldPass [

	"To start the stack pointer should be aligned"	
	"Precondition for all tests. SP should be aligned to the stack alignment required by the platform"
	[self stackPointerRegisterValue \\ cogit stackPointerAlignment = 0]
		whileFalse: [ self pushAddress: 16rBEEF "a small integer to mark..." ].

	self assert: machineSimulator stackPointerRegisterValue \\ cogit stackPointerAlignment equals: 0.

	machineSimulator writeRegister: UcARM64Registers sp value: machineSimulator stackPointerRegisterValue.

	self addInstruction: 
		(cogit backend 
			movSize: 1 
			destinationRegister: ReceiverResultReg 
			imm: 12345 shift: 0).

	self addInstruction: 
		(cogit backend strSize: 1
			baseRegister: SPReg
			signedOffset: 16 "word size, size of the elements in the stack"
			sourceRegister: ReceiverResultReg
			preIndex: 1 "Access before incrementing").

	self addInstruction: 
		(cogit backend strSize: 1
			baseRegister: SPReg
			signedOffset: 16 "word size, size of the elements in the stack"
			sourceRegister: ReceiverResultReg
			preIndex: 1 "Access before incrementing").

	self writeInstructions.
	self shouldnt: [self runInstructions] raise: Error.
	
	

]

{ #category : #'as yet unclassified' }
VMARMStackAlignmentTest >> writeInstructions [
	
	initialAddress := cogit methodZone allocate: instructions size * 4 .

	instructions withIndexDo: [ :instruction :index | 
		memory long32At: initialAddress + (index - 1 * 4)	 put: instruction ].

	
]
