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
		'machineSimulator',
		'send1TrampolineAddress',
		'send2TrampolineAddress',
		'send3TrampolineAddress'
	],
	#pools : [
		'CogAbstractRegisters',
		'CogCompilationConstants',
		'CogMethodConstants',
		'VMBytecodeConstants',
		'VMSqueakClassIndices'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #'building suites' }
VMSimpleStackBasedCogitAbstractTest class >> testParameters [

	^ ParametrizedTestMatrix new
		addCase: { #ISA -> #'aarch64'. #wordSize -> 8};
		addCase: { #ISA -> #'IA32'. #wordSize -> 4};
		addCase: { #ISA -> #'X64'. #wordSize -> 8};
		addCase: { #ISA -> #'ARMv5'. #wordSize -> 4};
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
	before := machineSimulator smalltalkStackPointerRegisterValue.
	aBlockClosure value.
	after := machineSimulator smalltalkStackPointerRegisterValue.
	
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
	^ self compile: aBlockClosure bytecodes: 2
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

	| allocatedAddress |

	"Generate the IR"
	self compileWithoutOutput: aBlockClosure bytecodes: bytecodes.

	"Then output the machine code"
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

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> compileTrampoline: aBlock named: aTrampolineName [

	| startAddress | 

	cogit methodZone freeStart: cogit methodZoneBase.

	startAddress := self compile: aBlock.

	cogit outputInstructionsForGeneratedRuntimeAt: startAddress.
	cogit recordGeneratedRunTime: aTrampolineName address: startAddress.
	cogit recordRunTimeObjectReferences.

	cogit methodZoneBase: cogit methodZone freeStart.

	^ startAddress
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> compileWithoutOutput: aBlockClosure bytecodes: bytecodes [
	
	"Call a compilation block initializing the compiler before.
	This method does not generate the machine code, just the IR.
	
	This is useful in two cases:
	  - compiler intrinsics (routines and trampolines) are written to output the machine code directly
	  - this is used as the first part of the #compile:bytecodes:header: to initialize the compiler"

	cogit allocateOpcodes: (bytecodes + 10) * 10 bytecodes: bytecodes ifFail: [ self fail ].
	cogit zeroOpcodeIndex.
	cogit maxLitIndex: -1.
	cogit methodLabel address: cogit methodZone freeStart.
	
	^ aBlockClosure value
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

	self prepareCall.
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

	^ machineSimulator framePointerRegisterValue
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitAbstractTest >> framePointerRegisterValue: aValue [
	
	machineSimulator framePointerRegisterValue: aValue
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
VMSimpleStackBasedCogitAbstractTest >> initializeStackMemory [
	
	| page |
	stackMemoryStartAddress := self interpreter stackPages minStackAddress.

	page := memory coInterpreter stackPages newStackPage.

	"The stack pointer is at the top of the stack"
	machineSimulator smalltalkStackPointerRegisterValue: page baseAddress.
	machineSimulator framePointerRegisterValue: page baseAddress.
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitAbstractTest >> instructionPointer [

	^ self readRegister: machineSimulator instructionPointerRegister
]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> jitCompilerClass [

	^ SimpleStackBasedCogit
]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> jitOptions [

	^ Dictionary newFromPairs: { 
		#ISA. isa.
		#IMMUTABILITY. false.
		#ObjectMemory. self memoryClass name }
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

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> memoryClass [

	^ self wordSize = 4
		ifTrue: [ Spur32BitCoMemoryManager ]
		ifFalse: [ Spur64BitCoMemoryManager ]
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
VMSimpleStackBasedCogitAbstractTest >> newJitCompiler [

	| compiler |
	self jitCompilerClass initializeWithOptions: (Cogit asOptionsDictionary: self jitOptions).

	compiler := self jitCompilerClass new 
		setInterpreter: memory coInterpreter;
		yourself.

	interpreter cogMethodZone: compiler methodZone.
	^ compiler

]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> newMemory [

	^ self memoryClass simulatorClass new
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> openMachineDebugger [
	
	self openMachineDebuggerAt: initialAddress
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> openMachineDebuggerAt: anAddress [
	
	^ VMMachineCodeDebugger new
		cogit: cogit;
		machineSimulator: machineSimulator;
		initialInstructionToDisassemble: anAddress;
		openWithSpec.
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitAbstractTest >> pop [

	| stackAddressIntegerValue poppedByteArray |

	"Getting address from stack register"
	stackAddressIntegerValue := machineSimulator smalltalkStackPointerRegisterValue.

	"Putting the value in the stack memory"
	poppedByteArray := self top.

	"Updating SP"
	machineSimulator smalltalkStackPointerRegisterValue: stackAddressIntegerValue + self wordSize.
	
	^ poppedByteArray
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitAbstractTest >> popAddress [
	
	^ self pop integerAt: 1 size: self wordSize signed: false
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> prepareCall [

	machineSimulator hasLinkRegister 
		ifTrue: [ 
			"The caller IP in ARM is in the linkRegister"
			machineSimulator linkRegisterValue: callerAddress ]
		ifFalse: [ 
			"I need to push the caller IP, as this is a message send"
			self pushAddress:  callerAddress ]

]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> prepareStackForSendReceiver: aReceiver [

	self prepareStackForSendReceiver: aReceiver arguments: #()
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> prepareStackForSendReceiver: aReceiver arguments: arguments [ 	

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self pushAddress: aReceiver.
	arguments do: [ :anArgument | self pushAddress: anArgument ].
	
	self machineSimulator receiverRegisterValue: aReceiver.

	"If the cogit is the StackToRegisterMapping the arguments should go in the registers also"
	(cogit isKindOf: StackToRegisterMappingCogit) ifTrue: [
		arguments size >= 1 ifTrue: [ self machineSimulator argument0RegisterValue: (arguments at: 1) ].
		arguments size > 1 ifTrue: [ self halt ]].
	
	self prepareCall
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
	stackAddressIntegerValue := machineSimulator smalltalkStackPointerRegisterValue.

	"Updating SP"
	stackAddressIntegerValue := stackAddressIntegerValue - self wordSize.
	machineSimulator smalltalkStackPointerRegisterValue: stackAddressIntegerValue.
	
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

	^ self readRegister:  machineSimulator receiverRegister
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> runFrom: startAddress until: endAddress [

	^ self runFrom: startAddress until: endAddress timeout: 1000. "microseconds"

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
		startAt: initialAddress
		until: self getLastAddress
		timeout: 0
		count: 0
]

{ #category : #helpers }
VMSimpleStackBasedCogitAbstractTest >> runUntilReturn [

	machineSimulator startAt: initialAddress
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

{ #category : #accessing }
VMSimpleStackBasedCogitAbstractTest >> sentSelector [
	^ sentSelector
]

{ #category : #accessing }
VMSimpleStackBasedCogitAbstractTest >> sentSelector: anObject [
	sentSelector := anObject
]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> setUp [
	super setUp.

	cogit := self newJitCompiler.
	memory coInterpreter cogit: cogit.
	memory cogit: cogit.
	cogit objectRepresentation class initializeMiscConstants.
	cogit entryOffset: (cogit sizeof: CogMethod).
	
	memory nilObject: (self newObjectWithSlots: 0).
	memory trueObject: (self newObjectWithSlots: 0).
	memory falseObject: (self newObjectWithSlots: 0).
	
	"We don't access its contents, but we need it to be after nil, true and false"
	memory hiddenRootsObject: (self newObjectWithSlots: 0).

	cogit setStackAlignment: 16 expectedSPOffset: 0 expectedFPOffset: 0.
	cogit initializeBackend.
	cogit methodZone manageFrom: initialAddress to: initialAddress + self initialCodeSize.
	cogit methodZoneBase: initialAddress.
	cogit minCallAddress: initialAddress.
	cogit cogCodeBase: initialAddress.
	memory coInterpreter cogCodeSize: self initialCodeSize.
	memory coInterpreter heapBase: memory newSpaceStart.
	cogit initializeProcessor.
	
	machineSimulator := cogit processor machineSimulator.
	
	cogit generateStackPointerCapture.
	cogit methodZone manageFrom: cogit cogCodeBase to: initialAddress + self initialCodeSize.

	memory coInterpreter numStackPages: 8.

	self initializeOldSpaceForScavenger.
	self initializeStackMemory.
	self initializeInitialStackFrame.	
]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> setUpCPUSimulator [

	machineSimulator := UnicornSimulator perform: isa asSymbol.
	machineSimulator memory: memory.
	memory memory memoryObject pinInMemory.
	machineSimulator mapMemory: memory memory memoryObject at: initialAddress.
]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> setUpCogMethodEntry [
	
	cogit allocateOpcodes: 80 bytecodes: 0 ifFail: [ self error: 'Could not allocate opcodes' ].
	cogit generateEnilopmarts.
	cogit maybeGenerateCheckFeatures.
			
	self setUpTrampolines.
	
	"This is the function a megamorphic PIC will jump when there is a miss"
	inlineCacheMissTrampoline := cogit simulatedAddressFor: #ceSendFromInLineCacheMiss:.
	
	cogit computeEntryOffsets.
	
	cogit methodZone manageFrom: cogit methodZoneBase to: cogit methodZoneBase + self initialCodeSize.
]

{ #category : #running }
VMSimpleStackBasedCogitAbstractTest >> setUpTrampolines [

	"Create a send trampoline so we can stop..."
	sendTrampolineAddress := self compileTrampoline: [ cogit RetN: 0 ] named: #send0argsTrampoline.
	cogit ordinarySendTrampolineAt: 0 "args" put: sendTrampolineAddress.
	
	send1TrampolineAddress := self compileTrampoline: [ cogit RetN: 0 ] named: #send1argsTrampoline.
	cogit ordinarySendTrampolineAt: 1 "args" put: send1TrampolineAddress.

	send2TrampolineAddress := self compileTrampoline: [ cogit RetN: 0 ] named: #send2argsTrampoline.
	cogit ordinarySendTrampolineAt: 2 "args" put: send2TrampolineAddress.

	send3TrampolineAddress := self compileTrampoline: [ cogit RetN: 0 ] named: #send3argsTrampoline.
	cogit ordinarySendTrampolineAt: 3 "args" put: send3TrampolineAddress.


	cogit ceCPICMissTrampoline: (self compileTrampoline: [ cogit RetN: 0 ] named:#ceCPICMissTrampoline).
	cogit cePICAbortTrampoline: (self compileTrampoline: [ cogit RetN: 0 ] named:#cePICAbortTrampoline).
	cogit ceMethodAbortTrampoline: (self compileTrampoline: [ cogit RetN: 0 ] named:#ceMethodAbortTrampoline).

]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitAbstractTest >> stackAddressAt: index [

	^ (self stackAt: index)
		integerAt: 1
		size: self wordSize 
		signed: false
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitAbstractTest >> stackAt: index [

	| stackAddressIntegerValue |

	"Getting address from stack register"
	stackAddressIntegerValue := machineSimulator smalltalkStackPointerRegisterValue + (index * self wordSize).
	^ machineSimulator memoryAt: stackAddressIntegerValue readNext: self wordSize.
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitAbstractTest >> stackPointerRegisterValue [

	^ machineSimulator stackPointerRegisterValue
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitAbstractTest >> stackPointerRegisterValue: aValue [

	machineSimulator stackPointerRegisterValue: aValue
]

{ #category : #accessing }
VMSimpleStackBasedCogitAbstractTest >> temporaryRegisterValue [
	
	^ self machineSimulator temporaryRegisterValue 
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitAbstractTest >> top [

	^ self stackAt: 0
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitAbstractTest >> topAddress [
	
	^ self top integerAt: 1 size: self wordSize signed: false
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitAbstractTest >> writeRegister: aRegister value: anInteger [ 

	| value |
	value := ByteArray new: self wordSize.
	value integerAt: 1 put: anInteger size: self wordSize signed: false.
	machineSimulator register: aRegister value write: value.

]
