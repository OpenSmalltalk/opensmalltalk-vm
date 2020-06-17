Class {
	#name : #VMSimpleStackBasedCogitAbstractTest,
	#superclass : #VMSpurMemoryManagerTest,
	#instVars : [
		'cogit',
		'codeSize',
		'callerAddress',
		'registerValue',
		'opcodes',
		'stackMemory',
		'stackMemoryStartAddress',
		'stackMemoryEndAddress',
		'isa',
		'obj',
		'selectorIndex',
		'sendAddress',
		'sendTrampolineAddress',
		'sentSelector',
		'selectorAtIndex',
		'inlineCacheMissTrampoline',
		'machineSimulator'
	],
	#pools : [
		'CogCompilationConstants',
		'CogMethodConstants',
		'VMBytecodeConstants'
	],
	#category : #VMMakerTests
}

{ #category : #'building suites' }
VMSimpleStackBasedCogitAbstractTest class >> testParameters [

	^ ParametrizedTestMatrix new
		addCase: { #ISA -> #'X64'. #wordSize -> 8};
		addCase: { #ISA -> #'IA32'. #wordSize -> 4};
		addCase: { #ISA -> #'ARMv5'. #wordSize -> 4};
		"forSelector: #ISA addOptions: #( X64 IA32 ARMv5 );"
		yourself
]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> ISA: anISA [

	isa := anISA
]

{ #category : #accessing }
VMSimpleStackBasedCogitAbstractTest >> abstractInstructions [

	^ (0 to: cogit getOpcodeIndex - 1)
		collect: [ :i | cogit abstractOpcodes at: i ]
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> assertPushed: anOop after: aBlockClosure [
	
	| before after |
	before := machineSimulator stackPointerRegisterValue.
	aBlockClosure value.
	after := machineSimulator stackPointerRegisterValue.
	
	self assert: after equals: before - self wordSize.
	self assert: (self readMemoryAt: after) equals: anOop
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> assertStackRemainsUnchangedDuring: aBlockClosure [ 
	
	| before |
	before := machineSimulator stackPointerRegisterValue.
	aBlockClosure value.
	
	self
		assert: machineSimulator stackPointerRegisterValue
		equals: before
]

{ #category : #accessing }
VMSimpleStackBasedCogitAbstractTest >> callerAddress [
	^ callerAddress
]

{ #category : #accessing }
VMSimpleStackBasedCogitAbstractTest >> cogit [
	^ cogit
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> compile: aBlockClosure [ 
	"Compiles some native code using the code inside the block closure as builder.
	This version assumes the block has a single 1-bytecode statement 
	  => this is used to estimate the amount of memory to preallocate for the geneated code.
	Return the address to the generated piece of code."
	^ self compile: aBlockClosure bytecodes: 1
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> compile: aBlockClosure bytecodes: bytecodes [
	
	^ self compile: aBlockClosure bytecodes: bytecodes headerSize: 0
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> compile: aBlockClosure bytecodes: bytecodes headerSize: headerSize [
	
	"Compiles some native code using the code inside the block closure as builder.
	The bytecodes variable contains an estimate of the number of bytecodes generated
	  => this is used to estimate the amount of memory to preallocate for the geneated code.
	Return the address to the generated piece of code."

	"We estimate the same ammount of bytecode as the Cogit"
	| allocatedAddress |
	cogit allocateOpcodes: (bytecodes + 10) * 10 bytecodes: bytecodes ifFail: [ self fail ].
	cogit zeroOpcodeIndex.
	cogit maxLitIndex: -1.
	cogit methodLabel address: cogit methodZone freeStart.
	
	aBlockClosure value.

	cogit computeMaximumSizes.
	
	"methodLabel address + headerSize?"
	codeSize := cogit generateInstructionsAt: cogit methodZone freeStart + headerSize.
	allocatedAddress := cogit methodZone allocate: (cogit methodZone roundUpLength: codeSize + headerSize).
	cogit outputInstructionsAt: allocatedAddress + headerSize.
	opcodes := cogit getOpcodeIndex.
	
	^ allocatedAddress
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitAbstractTest >> compileSpecialSend [
	
	"We will call to this address"
	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: sentSelector numArgs put: sendTrampolineAddress.
	
	self createFramefulCallFrom: callerAddress.
	cogit byte0: 176 + (selectorIndex - 1 / 2).
	sendAddress := self compile: [ cogit genSpecialSelectorSend ].
]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitAbstractTest >> createFramefulCallFrom: anAddress [

	self
		createFramefulCallFrom: anAddress
		receiver: memory nilObject
		arguments: #()
		temporaries: #()
]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitAbstractTest >> createFramefulCallFrom: returnAddress receiver: receiver arguments: arguments [

	self createFramefulCallFrom: returnAddress receiver: receiver arguments: arguments temporaries: #()
]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitAbstractTest >> createFramefulCallFrom: returnAddress receiver: receiver arguments: arguments temporaries: temps [

	"I create a frameful call for machine code. 

	 Stacks grow down:

			receiver for method activations/closure for block activations
			arg0
			...
			argN
			caller's method ip/base frame's sender context
	fp->	saved fp
			method
			frame flags
			context (uninitialized)
			receiver
			first temp
			...
	sp->	Nth temp"
	
	"The first part is the same with or without frame, as it is pushed by the caller"
	
	| builder |
	builder := self machineCodeFrameBuilder.
	builder returnAddress: returnAddress.
	builder receiver: receiver.
	builder arguments: arguments.
	builder temporaries: temps.
	builder buildFrame
]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitAbstractTest >> createFramelessCallFrom: anAddress [

	self
		createFramelessCallFrom: anAddress
		receiver: memory nilObject
		arguments: #()
]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitAbstractTest >> createFramelessCallFrom: returnAddress receiver: receiver arguments: arguments [.

	"I create a frameless call
	
	Frameless method activation looks like
			receiver
			args
	sp->	ret pc.
	"
	self pushAddress: receiver.
	arguments do: [ :anArgument | self pushAddress: anArgument ].

	self pushAddress: returnAddress.

	machineSimulator hasLinkRegister 
		ifTrue: [ machineSimulator linkRegisterValue: returnAddress ].	

	machineSimulator receiverRegisterValue: receiver.

	"We initialize the internal Cogit state by hand because we don't have a method to cog"	
"	cogit methodOrBlockNumTemps: 0.
	cogit initSimStackForFramelessMethod: 1".
	cogit methodOrBlockNumArgs: arguments size.
	cogit needsFrame: false.
	cogit inBlock: 0.
"	cogit regArgsHaveBeenPushed: false".


]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitAbstractTest >> createInterpreterFramefulCallFrom: returnAddress receiver: receiver arguments: arguments temporaries: temps [

	"I create a frameful call for interpreter.
	Pay attention I am different than a machine code framefull context!! 

	 Stacks grow down:

			receiver for method activations/closure for block activations
			arg0
			...
			argN
			caller's method ip/base frame's sender context
	fp->	saved fp
			method
			context (initialized to nil)
			frame flags (interpreter only)
			saved method ip (initialized to 0; interpreter only)
			first temp
			...
	sp->	Nth temp"
	
	"The first part is the same with or without frame, as it is pushed by the caller"
	self createFramelessCallFrom: returnAddress receiver: receiver arguments: arguments.

	"These are pushed when activating the method"	
	self pushAddress: machineSimulator framePointerRegisterValue.
	machineSimulator framePointerRegisterValue: machineSimulator stackPointerRegisterValue.

	self pushAddress: (memory nilObject bitOr: 1). "method"
	self pushAddress: memory nilObject. "context"
	self pushAddress: 0. "flags"
	self pushAddress: 0. "method ip"

	self pushAddress: receiver.

	temps do: [ :aTemporary | self pushAddress: aTemporary ].
	
	cogit needsFrame: true.
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitAbstractTest >> createSpecialSelectorArray [

	| specialObjectsOop  |
	specialObjectsOop := self newObjectWithSlots: 24.
	selectorIndex := Smalltalk specialSelectors indexOf: sentSelector.
	obj := self newObjectWithSlots: selectorIndex + 1.
	memory
		storePointer: selectorIndex - 1
		ofObject: obj withValue: (selectorAtIndex := memory integerObjectOf: 77 "Some object to test").
	memory
		storePointer: selectorIndex
		ofObject: obj withValue: (memory integerObjectOf: sentSelector numArgs).
	memory storePointer: 23 ofObject: specialObjectsOop withValue: obj.
	memory specialObjectsOop: specialObjectsOop.
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> disassemble [
	
	^ self disassembleFrom: initialAddress
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> disassembleFrom: anIndex [
	
	^ self disassembleFrom: anIndex opcodes: opcodes
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> disassembleFrom: anIndex opcodes: numberOfInstructions [
	
	^ machineSimulator disassembler
		printImmediatesInHexa;
		disassembleNext: numberOfInstructions
		instructionsIn: (memory memory memoryObject
			copyFrom: anIndex - initialAddress + 1
			to: memory memory memoryObject size)
		startAddress: anIndex
		pc: 0
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitAbstractTest >> framePointerRegisterValue [

	^ self readRegister: UcX86Registers rbp
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitAbstractTest >> framePointerRegisterValue: aValue [
	
	self writeRegister: UcX86Registers rbp value: aValue
]

{ #category : #'helpers - cog methods' }
VMSimpleStackBasedCogitAbstractTest >> generateCogMethod: aBlockClosure selector: anSelectorOop [ 

	| targetCog allocatedAddress |

	allocatedAddress := self compile: [ 
			cogit compileAbort.
			cogit compileEntry.
			aBlockClosure value ] 
		  bytecodes: 1 headerSize: (cogit sizeof: CogMethod).
	
	targetCog := cogit cogMethodSurrogateAt: allocatedAddress.
	targetCog selector: anSelectorOop.
	targetCog blockSize: cogit methodZone freeStart - allocatedAddress.
	
	^ targetCog

]

{ #category : #accessing }
VMSimpleStackBasedCogitAbstractTest >> getLastAddress [
	
	^ machineSimulator getLastAddress: self abstractInstructions.
]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> initialCodeSize [
	^ 4 * 1024
]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> initializeInitialStackFrame [

	"I will create the initial stack with a well-known caller address so we know if the code comes back
	correctly. The address should be in a valid space of the memory if not unicorn complains. 
	So we just put it in the start of the stack"
	callerAddress := stackMemoryStartAddress.
	self createFramelessCallFrom: callerAddress receiver: memory nilObject arguments: #().
	

]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> initializeStackMemory [.

	stackMemoryStartAddress := initialAddress + self initialCodeSize.
	stackMemoryEndAddress := stackMemoryStartAddress + stackSpaceSize.

	"The stack pointer is at the top of the stack"
	machineSimulator stackPointerRegisterValue: stackMemoryEndAddress.
	machineSimulator framePointerRegisterValue: stackMemoryEndAddress.
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitAbstractTest >> instructionPointer [

	^ self readRegister: UcX86Registers rip
]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitAbstractTest >> machineCodeFrameBuilder [

	| builder |
	builder := VMMachineCodeFrameBuilderForTest new.
	builder initializeWithTest: self.
	^ builder
]

{ #category : #accessing }
VMSimpleStackBasedCogitAbstractTest >> machineSimulator [
	^ machineSimulator
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> newInterpreter [

	| theMemory |
	theMemory := self newMemory.

	CogVMSimulatorLSB
		initializeWithOptions: {
			#BytesPerWord. 8.
			#ObjectMemory. theMemory class name.
			#bytecodeTableInitializer. #initializeBytecodeTableForSqueakV3PlusClosures}
		objectMemoryClass: theMemory class.
		
		
	^ CogVMSimulatorLSB basicNew
		objectMemory: theMemory;
		basicInitialize
]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> newMemory [

	^ self wordSize = 4
		ifTrue: [ Spur32BitCoMemoryManager simulatorClass new ]
		ifFalse: [ Spur64BitCoMemoryManager simulatorClass new ]
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> openMachineDebugger [
	
	VMMachineCodeDebugger new
		cogit: cogit;
		machineSimulator: machineSimulator;
		openWithSpec.
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> openMachineDebuggerAt: anAddress [
	
	VMMachineCodeDebugger new
		cogit: cogit;
		machineSimulator: machineSimulator;
		initialInstructionToDisassemble: anAddress;
		openWithSpec.
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitAbstractTest >> pop [

	| stackAddressIntegerValue poppedByteArray |

	"Getting address from stack register"
	stackAddressIntegerValue := machineSimulator stackPointerRegisterValue.

	"Putting the value in the stack memory"
	poppedByteArray := self top.

	"Updating SP"
	machineSimulator stackPointerRegisterValue: stackAddressIntegerValue + self wordSize.
	
	^ poppedByteArray
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitAbstractTest >> popAddress [
	
	^ self pop integerAt: 1 size: self wordSize signed: false
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> primitiveTraceLogSize [
	
	^ 256 * 8 "word size"
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitAbstractTest >> push: aByteArray [

	| stackAddressIntegerValue |
	self assert: aByteArray size equals: self wordSize.

	"Getting address from stack register"
	stackAddressIntegerValue := machineSimulator stackPointerRegisterValue.

	"Updating SP"
	stackAddressIntegerValue := stackAddressIntegerValue - self wordSize.
	machineSimulator stackPointerRegisterValue: stackAddressIntegerValue.
	
	"Putting the value in the stack memory"
	machineSimulator
		memoryAt: stackAddressIntegerValue
		write: aByteArray
		size: self wordSize.

]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitAbstractTest >> pushAddress: anInteger [

	| aByteArray |
	aByteArray := ByteArray new: self wordSize.
	aByteArray integerAt: 1 put: anInteger size: self wordSize signed: false.
	self push: aByteArray
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> readMemoryAt: anAddress [

	| bytes |
	bytes := machineSimulator memoryAt: anAddress readNext: self wordSize.
	^ bytes integerAt: 1 size: self wordSize signed: false
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitAbstractTest >> readRegister: aRegisterID [

	registerValue := ByteArray new: self wordSize.
	machineSimulator register: aRegisterID value readInto: registerValue.
	^ registerValue integerAt: 1 size: self wordSize signed: false
]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitAbstractTest >> readTemporaryValueAt: anIndex [

	"
	fp->	saved fp
			method
			context (initialized to nil)
			receiver
			first temp	
			...
	sp->	Nth temp
	
		The first temporary is the 6th value from the FP to the top of the stack.
		It is negative because the stack begins from a high address and after each push the SP is goingDown
	
		THIS METHOD ONLY WORK IN FRAMEFUL MACHINE FRAMES
	"
	
	self assert: cogit needsFrame.
	
	^ self readMemoryAt: machineSimulator framePointerRegisterValue  - ((3 + anIndex) * self wordSize)
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> receiverRegister: anInteger [ 

	self writeRegister: UcX86Registers rdx value: anInteger
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitAbstractTest >> returnValue [

	^ self readRegister: UcX86Registers rdx
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> runFrom: startAddress until: endAddress [

	self runFrom: startAddress until: endAddress timeout: 1000 "microseconds"
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> runFrom: startAddress until: endAddress timeout: microseconds [

	machineSimulator startAt: startAddress
		until: endAddress
		timeout: microseconds
		count: 0.
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> runGeneratedCode [
	"The different platforms generates code in a different way, so the number of opcodes can not be valid. Eg: ARM generates more instructions per opcode. It has to calculate the instructions to run differently"

	machineSimulator
		doRunGeneratedCodeStartAt: initialAddress
		instructions: self abstractInstructions
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> runUntilReturn [

	machineSimulator startAt: 16r1000000
		until: callerAddress
		timeout: 0
		count: 3000.

]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> runUntilReturnFrom: anAddress [

	machineSimulator startAt: anAddress
		until: callerAddress
		timeout: 0
		count: 0.

]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> setUp [
	super setUp.
	
	SimpleStackBasedCogit initializeWithOptions: (Cogit asOptionsDictionary: { #ISA . isa }).
	cogit := SimpleStackBasedCogit new setInterpreter: memory coInterpreter.
	memory coInterpreter cogit: cogit.
	memory cogit: cogit.
	cogit objectRepresentation class initializeMiscConstants.
	cogit entryOffset: (cogit sizeof: CogMethod).
	
	memory nilObject: (self newObjectWithSlots: 0).
	memory trueObject: (self newObjectWithSlots: 0).
	memory falseObject: (self newObjectWithSlots: 0).
	
	"We don't access its contents, but we need it to be after nil, true and false"
	memory hiddenRootsObject: (self newObjectWithSlots: 0).

	"Initializing Unicorn processor"
	self setUpCPUSimulator.
	self initializeStackMemory.
	
	cogit processor machineSimulator: machineSimulator.
	cogit setStackAlignment: 16 expectedSPOffset: 0 expectedFPOffset: 0.
	cogit initializeBackend.
	cogit methodZone manageFrom: initialAddress to: initialAddress + self initialCodeSize.
	cogit methodZoneBase: initialAddress.
	cogit minCallAddress: initialAddress.
	cogit cogCodeBase: initialAddress.
	memory coInterpreter cogCodeSize: self initialCodeSize.
	memory coInterpreter heapBase: memory newSpaceStart.
	cogit generateStackPointerCapture.
	cogit methodZone manageFrom: cogit cogCodeBase to: initialAddress + self initialCodeSize.


	self initializeInitialStackFrame.
	
	memory coInterpreter numStackPages: 8.

	self initializeOldSpaceForScavenger.
]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> setUpCPUSimulator [

	machineSimulator := UnicornSimulator perform: isa asSymbol.
	machineSimulator memory: memory.
	memory memory memoryObject pinInMemory.
	machineSimulator mapMemory: memory memory memoryObject at: initialAddress.
]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitAbstractTest >> setUpCogMethodEntry [
	
	cogit ceCPICMissTrampoline: (self compile: [ cogit RetN: 0 ]).
	cogit cePICAbortTrampoline: (self compile: [ cogit RetN: 0 ]).
	cogit ceMethodAbortTrampoline: (self compile: [ cogit RetN: 0 ]).
	
	"This is the function a megamorphic PIC will jump when there is a miss"
	inlineCacheMissTrampoline := cogit simulatedAddressFor: #ceSendFromInLineCacheMiss:.
	
	cogit computeEntryOffsets.
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitAbstractTest >> stackPointerRegisterValue [

	^ self readRegister: UcX86Registers esp
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitAbstractTest >> stackPointerRegisterValue: aValue [
	
	self writeRegister: UcX86Registers rsp value: aValue
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitAbstractTest >> top [

	| stackAddressIntegerValue |

	"Getting address from stack register"
	stackAddressIntegerValue := machineSimulator stackPointerRegisterValue.
	^ machineSimulator memoryAt: stackAddressIntegerValue readNext: self wordSize.
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitAbstractTest >> topAddress [
	
	^ self top integerAt: 1 size: self wordSize signed: false
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitAbstractTest >> writeRegister: anUcX86Registers value: anInteger [ 

	| value |
	value := ByteArray new: self wordSize.
	value integerAt: 1 put: anInteger size: self wordSize signed: false.
	machineSimulator register: anUcX86Registers value write: value.

]
