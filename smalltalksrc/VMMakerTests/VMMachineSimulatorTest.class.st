Class {
	#name : #VMMachineSimulatorTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#pools : [
		'CogAbstractRegisters'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #'tests - instruction exception' }
VMMachineSimulatorTest >> testInstructionExceptionHasCorrectInstructionAddress [

	| label lastInstruction subInstruction breakInstruction |
	self compile: [ 
		cogit MoveCq: 0 R: TempReg.
		cogit MoveCq: 5 R: ClassReg.
		label := cogit Label.
		cogit AddCq: 1 R: TempReg.
		subInstruction := cogit SubCq: 1 R: ClassReg.
		breakInstruction := cogit Stop.
		cogit JumpNonZero: label.

		"This instruction should not be called"
		lastInstruction := cogit Call: 16rFFFFF0.  ].

	[	self machineSimulator
			startAt: initialAddress
			until: lastInstruction address
			timeout: 0
			count: 0.
	] on: UnicornError do: [ :e | 
		self assert: self machineSimulator lastExecutedInstructionAddress equals: breakInstruction address.	
		^ self ].
	
	self fail.

]

{ #category : #'tests - instruction exception' }
VMMachineSimulatorTest >> testInstructionExceptionIsRaisedAsUnicornError [

	| label lastInstruction subInstruction breakInstruction |
	self compile: [ 
		cogit MoveCq: 0 R: TempReg.
		cogit MoveCq: 5 R: ClassReg.
		label := cogit Label.
		cogit AddCq: 1 R: TempReg.
		subInstruction := cogit SubCq: 1 R: ClassReg.
		breakInstruction := cogit Stop.
		cogit JumpNonZero: label.

		"This instruction should not be called"
		lastInstruction := cogit Call: 16rFFFFF0.  ].

	[	self machineSimulator
			startAt: initialAddress
			until: lastInstruction address
			timeout: 0
			count: 0.
	] on: Error do: [ :e | 
		self assert: e class equals: UnicornError.	
		^ self ].
	
	self fail.

]

{ #category : #'tests - memory access exception' }
VMMachineSimulatorTest >> testMemoryAccessExceptionComesWithCorrectAddress [

	| lastInstruction invalidAccessInstruction invalidAddressHandled |
	self compile: [ 
		cogit MoveCq: 16rFFFF0000 R: TempReg.
		invalidAccessInstruction := cogit MoveMb: 0 r: TempReg R: ClassReg.
		"This instruction should not be called"
		lastInstruction := cogit Call: 16rFFFFF0.  ].
	
	invalidAddressHandled := false.
	
	self machineSimulator invalidAccessHandler: [:invalidAccess | 
		invalidAddressHandled := true.
		self 
			assert: invalidAccess address 
			equals: 16rFFFF0000.
		false ].
	
	self
		runFrom: initialAddress
		until: lastInstruction address
		timeout: 0.


	self assert: invalidAddressHandled
]

{ #category : #'tests - memory access exception' }
VMMachineSimulatorTest >> testMemoryAccessExceptionHandledCountIsRespected [

	| label lastInstruction invalidAddressHandled addInstruction jumpInstruction expectedAddress |

	self timeLimit: 30 minutes.

	self compile: [ 
		cogit MoveCq: 0 R: TempReg.
		cogit MoveCq: 16rFFFF0000 R: ClassReg.
		cogit MoveMb: 0 r: ClassReg R: ReceiverResultReg. 

		label := cogit Label.
		addInstruction := cogit AddCq: 1 R: TempReg.
		jumpInstruction := cogit Jump: label.
		"This instruction is never reach"
		lastInstruction := cogit RetN: 0 ].

	self machineSimulator invalidAccessHandler: [:invalidAccess | 
		invalidAddressHandled := true.
		self 
			assert: invalidAccess address 
			equals: 16rFFFF0000.
			
		self machineSimulator receiverRegisterValue: 1.
		"Continue executing after exception"
		true ].
	

	self machineSimulator
		startAt: initialAddress
		until: lastInstruction address
		timeout: 0
		count: 10. 
	
	"ARM v8 generates two instructions for MoveMbrR, so it will execute and instruction less"
	expectedAddress := isa = #aarch64 ifTrue: [addInstruction address] ifFalse: [jumpInstruction address].
	
	
	self 
		assert: self machineSimulator instructionPointerValue 
		equals: expectedAddress
]

{ #category : #'tests - memory access exception' }
VMMachineSimulatorTest >> testMemoryAccessExceptionHandledTimeoutIsRespected [

	| label lastInstruction invalidAddressHandled |

	self compile: [ 
		cogit MoveCq: 0 R: TempReg.
		cogit MoveCq: 16rFFFF0000 R: ClassReg.
		cogit MoveMb: 0 r: ClassReg R: ReceiverResultReg. 

		label := cogit Label.
		cogit AddCq: 1 R: TempReg.
		cogit Jump: label.
		"This instruction is never reach"
		lastInstruction := cogit RetN: 0 ].


	self machineSimulator invalidAccessHandler: [:invalidAccess | 
		invalidAddressHandled := true.
		self 
			assert: invalidAccess address 
			equals: 16rFFFF0000.
			
		self machineSimulator receiverRegisterValue: 1.
		true ].
	

	[ self
		runFrom: initialAddress
		until: lastInstruction address
		timeout: 1000 ]
			on: UnicornTimeout
			do: [ :e | self assert: e messageText equals: ''. ^ self ].
			
	self fail.
]

{ #category : #'tests - memory access exception' }
VMMachineSimulatorTest >> testMemoryAccessExceptionHandledUntilAddressIsRespected [

	| label invalidAddressHandled addInstruction jumpInstruction |

	self compile: [ 
		cogit MoveCq: 0 R: TempReg.
		cogit MoveCq: 16rFFFF0000 R: ClassReg.
		cogit MoveMb: 0 r: ClassReg R: ReceiverResultReg. 

		label := cogit Label.
		addInstruction := cogit AddCq: 1 R: TempReg.
		jumpInstruction := cogit Jump: label.
		"This instruction is never reach"
		cogit RetN: 0 ].

	self machineSimulator invalidAccessHandler: [:invalidAccess | 
		invalidAddressHandled := true.
		self 
			assert: invalidAccess address 
			equals: 16rFFFF0000.
			
		self machineSimulator receiverRegisterValue: 1.
		"Continue executing after exception"
		true ].
	

	self machineSimulator
		startAt: initialAddress
		until: jumpInstruction address
		timeout: 1000
		count: 0.
	
	self assert: self temporaryRegisterValue equals: 1
]

{ #category : #'tests - memory access exception' }
VMMachineSimulatorTest >> testMemoryAccessExceptionHandledUntilAddressIsRespectedCorrectInstructionPointer [

	| label invalidAddressHandled addInstruction jumpInstruction |

	self compile: [ 
		cogit MoveCq: 0 R: TempReg.
		cogit MoveCq: 16rFFFF0000 R: ClassReg.
		cogit MoveMb: 0 r: ClassReg R: ReceiverResultReg. 

		label := cogit Label.
		addInstruction := cogit AddCq: 1 R: TempReg.
		jumpInstruction := cogit Jump: label.
		"This instruction is never reach"
		cogit RetN: 0 ].

	self machineSimulator invalidAccessHandler: [:invalidAccess | 
		invalidAddressHandled := true.
		self 
			assert: invalidAccess address 
			equals: 16rFFFF0000.
			
		self machineSimulator receiverRegisterValue: 1.
		"Continue executing after exception"
		true ].
	

	self machineSimulator
		startAt: initialAddress
		until: jumpInstruction address
		timeout: 1000
		count: 0.
	
	self assert: self machineSimulator instructionPointerValue equals: jumpInstruction address
]

{ #category : #'tests - memory access exception' }
VMMachineSimulatorTest >> testMemoryAccessExceptionInCallContinuesToCorrectPC [

	| lastInstruction invalidAddressHandled returningPoint |
	self compile: [ 
		cogit MoveCq: 0 R: TempReg. 
		cogit CallFull: 16r7FFF0000.
		returningPoint := cogit MoveCq: 99 R: TempReg. 
		lastInstruction := cogit RetN: 0].
	
	invalidAddressHandled := false.
	
	self machineSimulator invalidAccessHandler: [:invalidAccess | 
		invalidAddressHandled := true.
		self machineSimulator instructionPointerValue: returningPoint address.
		true].

	self
		runFrom: initialAddress
		until: lastInstruction address
		timeout: 0.


	self assert: self temporaryRegisterValue equals: 99.
	self assert: invalidAddressHandled
]

{ #category : #'tests - memory access exception' }
VMMachineSimulatorTest >> testMemoryAccessExceptionInCallHasUpdatedPC [

	| lastInstruction invalidAddressHandled |
	self compile: [ 
		cogit CallFull: 16r7FFF0000.
		lastInstruction := cogit RetN: 0].
	
	invalidAddressHandled := false.
	
	self machineSimulator invalidAccessHandler: [:invalidAccess | 
		self 
			assert: self machineSimulator instructionPointerValue 
			equals: 16r7FFF0000.
		invalidAddressHandled := true.
		false].
	
	self
		runFrom: initialAddress
		until: lastInstruction address
		timeout: 0.


	self assert: invalidAddressHandled
]

{ #category : #'tests - memory access exception' }
VMMachineSimulatorTest >> testMemoryAccessExceptionInJumpContinuesToCorrectPC [

	| lastInstruction invalidAddressHandled returningPoint |
	self compile: [ 
		cogit MoveCq: 0 R: TempReg. 
		cogit JumpFull: 16r7FFF0000.
		returningPoint := cogit MoveCq: 99 R: TempReg. 
		lastInstruction := cogit RetN: 0].
	
	invalidAddressHandled := false.
	
	self machineSimulator invalidAccessHandler: [:invalidAccess | 
		invalidAddressHandled := true.
		self machineSimulator instructionPointerValue: returningPoint address.
		true].
	
	self
		runFrom: initialAddress
		until: lastInstruction address
		timeout: 0.


	self assert: self temporaryRegisterValue equals: 99.
	self assert: invalidAddressHandled
]

{ #category : #'tests - memory access exception' }
VMMachineSimulatorTest >> testMemoryAccessExceptionInJumpHasUpdatedPC [

	| lastInstruction invalidAddressHandled |
	self compile: [ 
		cogit JumpFull: 16r7FFF0000.
		lastInstruction := cogit RetN: 0].
	
	invalidAddressHandled := false.
	
	self machineSimulator invalidAccessHandler: [:invalidAccess | 
		self 
			assert: self machineSimulator instructionPointerValue 
			equals: 16r7FFF0000.
		invalidAddressHandled := true.
		false].
	
	self
		runFrom: initialAddress
		until: lastInstruction address
		timeout: 0.


	self assert: invalidAddressHandled
]

{ #category : #'tests - memory access exception' }
VMMachineSimulatorTest >> testMemoryAccessExceptionInstructionPointerInCorrectAddress [

	| lastInstruction invalidAccessInstruction invalidAddressHandled exptectedAddress |
	self timeLimit: 30 minutes.

	self compile: [ 
		cogit MoveCq: 16rFFFF0000 R: TempReg.
		cogit MoveCq: 0 R: ClassReg.

		invalidAccessInstruction := cogit MoveMb: 0 r: TempReg R: ClassReg.
		"This instruction should not be called"
		lastInstruction := cogit Call: 16rFFFFF0.  ].
	
	invalidAddressHandled := false.
	
	"In ArmV8 the MoveMbrR are two instructions"
	isa = #aarch64 
		ifTrue: [ exptectedAddress := invalidAccessInstruction address + 4 ]
		ifFalse: [ exptectedAddress := invalidAccessInstruction address ].
	
	self machineSimulator invalidAccessHandler: [:invalidAccess | 
		invalidAddressHandled := true.
		self 
			assert: self machineSimulator lastExecutedInstructionAddress 
			equals: exptectedAddress.
		false ].
	
	self
		runFrom: initialAddress
		until: lastInstruction address
		timeout: 0.

	self assert: invalidAddressHandled
]

{ #category : #'tests - normal execution' }
VMMachineSimulatorTest >> testNormalExecutionCountIsRespected [

	| label lastInstruction subInstruction |
	self compile: [ 
		cogit MoveCq: 0 R: TempReg.
		cogit MoveCq: 5 R: ClassReg.
		label := cogit Label.
		cogit AddCq: 1 R: TempReg.
		subInstruction := cogit SubCq: 1 R: ClassReg.
		cogit JumpNonZero: label.

		"This instruction should not be called"
		lastInstruction := cogit Call: 16rFFFFF0.  ].

	self machineSimulator
		startAt: initialAddress
		until: lastInstruction address
		timeout: 0
		count: 10.

	self assert: self machineSimulator temporaryRegisterValue equals: 3.
	self assert: self machineSimulator classRegisterValue equals: 2.

]

{ #category : #'tests - normal execution' }
VMMachineSimulatorTest >> testNormalExecutionCountIsRespectedAndHasCorrectInstructionPointer [

	| label lastInstruction subInstruction jumpInstruction |
	self compile: [ 
		cogit MoveCq: 0 R: TempReg.
		cogit MoveCq: 5 R: ClassReg.
		label := cogit Label.
		cogit AddCq: 1 R: TempReg.
		subInstruction := cogit SubCq: 1 R: ClassReg.
		jumpInstruction := cogit JumpNonZero: label.

		"This instruction should not be called"
		lastInstruction := cogit Call: 16rFFFFF0.  ].

	self machineSimulator
		startAt: initialAddress
		until: lastInstruction address
		timeout: 0
		count: 10.

	self assert: self machineSimulator instructionPointerValue equals: jumpInstruction address.

]

{ #category : #'tests - normal execution' }
VMMachineSimulatorTest >> testNormalExecutionRespectTimeout [

	| label lastInstruction |
	self compile: [ 
		cogit MoveCq: 0 R: TempReg.
		label := cogit Label.
		cogit AddCq: 1 R: TempReg.
		cogit Jump: label.
		"This instruction is never reach"
		lastInstruction := cogit RetN: 0 ].

	[ self
		runFrom: initialAddress
		until: lastInstruction address
		timeout: 1000 ]
			on: UnicornTimeout
			do: [ :e | self assert: e messageText equals: ''. ^ self ].
			
	self fail.
]

{ #category : #'tests - normal execution' }
VMMachineSimulatorTest >> testNormalExecutionRespectTimeoutUpdatesInstructionPointer [

	| label lastInstruction |
	self compile: [ 
		cogit MoveCq: 0 R: TempReg.
		label := cogit Label.
		cogit AddCq: 1 R: TempReg.
		cogit Jump: label.
		"This instruction is never reach"
		lastInstruction := cogit RetN: 0 ].

	[ self
		runFrom: initialAddress
		until: lastInstruction address
		timeout: 1000 ]
			on: UnicornTimeout
			do: [ :e | 
				self deny: self machineSimulator instructionPointerValue equals: initialAddress.
				self assert: e messageText equals: ''. ^ self ].
			
	self fail.
]

{ #category : #'tests - normal execution' }
VMMachineSimulatorTest >> testNormalExecutionUntilAddressIsRespected [

	| label lastInstruction |
	self compile: [ 
		cogit MoveCq: 0 R: TempReg.
		cogit MoveCq: 5 R: ClassReg.
		label := cogit Label.
		cogit AddCq: 1 R: TempReg.
		cogit SubCq: 1 R: ClassReg.
		cogit JumpNonZero: label.

		"This instruction should not be called"
		lastInstruction := cogit Call: 16rFFFFF0.  ].

	self
		runFrom: initialAddress
		until: lastInstruction address
		timeout: 0.

	self assert: self instructionPointer equals: lastInstruction address
]
