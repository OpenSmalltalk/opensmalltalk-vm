Class {
	#name : #VMSimpleStackBasedCogitBytecodeTest,
	#superclass : #VMSpurMemoryManagerTest,
	#instVars : [
		'cogit',
		'codeSize',
		'lastAddress',
		'unicorn',
		'callerAddress',
		'registerValue',
		'opcodes',
		'stackMemory',
		'stackMemoryStartAddress',
		'stackMemoryEndAddress',
		'isa',
		'wordSize',
		'obj',
		'selectorIndex',
		'sendAddress',
		'sendTrampolineAddress',
		'sentSelector',
		'selectorAtIndex'
	],
	#category : #VMMakerTests
}

{ #category : #'building suites' }
VMSimpleStackBasedCogitBytecodeTest class >> testParameters [

	^ ParametrizedTestMatrix new
		addCase: { #ISA -> #'X64'. #wordSize -> 8};
		addCase: { #ISA -> #'IA32'. #wordSize -> 4};
		"forSelector: #ISA addOptions: #( X64 IA32 ARMv5 );"
		yourself
]

{ #category : #running }
VMSimpleStackBasedCogitBytecodeTest >> ISA: anISA [

	isa := anISA
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> assertPushed: anOop after: aBlockClosure [
	
	| before after |
	before := unicorn stackPointerRegisterValue.
	aBlockClosure value.
	after := unicorn stackPointerRegisterValue.
	
	self assert: after equals: before - self wordSize.
	self assert: (self readMemoryAt: after) equals: anOop
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> assertStackRemainsUnchangedDuring: aBlockClosure [ 
	
	| before |
	before := unicorn stackPointerRegisterValue.
	aBlockClosure value.
	
	self
		assert: unicorn stackPointerRegisterValue
		equals: before
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> compile: aBlockClosure [ 
	"Compiles some native code using the code inside the block closure as builder.
	This version assumes the block has a single 1-bytecode statement 
	  => this is used to estimate the amount of memory to preallocate for the geneated code.
	Return the address to the generated piece of code."
	^ self compile: aBlockClosure bytecodes: 1
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> compile: aBlockClosure bytecodes: bytecodes [
	
	"Compiles some native code using the code inside the block closure as builder.
	The bytecodes variable contains an estimate of the number of bytecodes generated
	  => this is used to estimate the amount of memory to preallocate for the geneated code.
	Return the address to the generated piece of code."

	"We estimate the same ammount of bytecode as the Cogit"
	| allocatedAddress |
	cogit allocateOpcodes: (bytecodes + 10) * 10 bytecodes: bytecodes ifFail: [ self fail ].
	cogit zeroOpcodeIndex.
	cogit maxLitIndex: -1.
	
	aBlockClosure value.

	cogit methodLabel address: 0.
	cogit computeMaximumSizes.
	
	"methodLabel address + headerSize?"
	codeSize := cogit generateInstructionsAt: cogit methodZone freeStart.
	allocatedAddress := cogit methodZone allocate: codeSize.
	lastAddress := cogit outputInstructionsAt: allocatedAddress.

	opcodes := cogit getOpcodeIndex.
	
	^ allocatedAddress
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> compileSpecialSend [
	
	"We will call to this address"
	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: sentSelector numArgs put: sendTrampolineAddress.
	
	self createFramefulCallFrom: callerAddress.
	cogit byte0: 176 + (selectorIndex - 1 / 2).
	sendAddress := self compile: [ cogit genSpecialSelectorSend ].
]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitBytecodeTest >> createFramefulCallFrom: anAddress [

	self
		createFramefulCallFrom: anAddress
		receiver: memory nilObject
		arguments: #()
		temporaries: #()
]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitBytecodeTest >> createFramefulCallFrom: returnAddress receiver: receiver arguments: arguments [

	self createFramefulCallFrom: returnAddress receiver: receiver arguments: arguments temporaries: #()
]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitBytecodeTest >> createFramefulCallFrom: returnAddress receiver: receiver arguments: arguments temporaries: temps [

	"I create a frameful call for machine code. 

			receiver for method activations/closure for block activations
			arg0
			...
			argN
			caller's saved ip/this stackPage (for a base frame)
	fp->	saved fp
			method
			context (initialized to nil)
			receiver
			first temp
			...
	sp->	Nth temp	
	"
	
	"The first part is the same with or without frame, as it is pushed by the caller"
	self createFramelessCallFrom: returnAddress receiver: receiver arguments: arguments.

	"
		In a machine code frame
		the flag indicating if the context is valid is the least significant bit of the method pointer
		the flag for a block activation is the next most significant bit of the method pointer"
	
	"These are pushed when activating the method"	
	self pushAddress: unicorn framePointerRegisterValue.
	unicorn framePointerRegisterValue: unicorn stackPointerRegisterValue.

	self pushAddress: (memory nilObject bitOr: 1). "method"
	self pushAddress: memory nilObject. "context"

	self pushAddress: receiver.
	temps do: [ :aTemporary | self pushAddress: aTemporary ].
	
	cogit needsFrame: true.
]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitBytecodeTest >> createFramelessCallFrom: anAddress [

	self
		createFramelessCallFrom: anAddress
		receiver: memory nilObject
		arguments: #()
]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitBytecodeTest >> createFramelessCallFrom: returnAddress receiver: receiver arguments: arguments [.

	"I create a frameless call
	
	Frameless method activation looks like
			receiver
			args
	sp->	ret pc.
	"
	self pushAddress: receiver.
	arguments do: [ :anArgument | self pushAddress: anArgument ].
	self pushAddress: returnAddress.	

	unicorn receiverRegisterValue: receiver.

	"We initialize the internal Cogit state by hand because we don't have a method to cog"	
"	cogit methodOrBlockNumTemps: 0.
	cogit initSimStackForFramelessMethod: 1".
	cogit methodOrBlockNumArgs: arguments size.
	cogit needsFrame: false.
	cogit inBlock: 0.
"	cogit regArgsHaveBeenPushed: false".


]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> createSpecialSelectorArray [

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
VMSimpleStackBasedCogitBytecodeTest >> disassemble [
	
	^ self disassembleFrom: 1
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> disassembleFrom: anIndex [
	
	^ self disassembleFrom: anIndex opcodes: opcodes
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> disassembleFrom: anIndex opcodes: numberOfInstructions [
	
	^ LLVMDisassembler amd64
		printImmediatesInHexa;
		disassembleNext: numberOfInstructions
		instructionsIn: (memory memory memoryObject
			copyFrom: anIndex - initialAddress + 1
			to: memory memory memoryObject size)
		startAddress: anIndex
		pc: 0
]

{ #category : #'tests - extended store bytecode - store inst var' }
VMSimpleStackBasedCogitBytecodeTest >> doExtendedStoreStoresInstanceVariableIndex: instanceVariableToWrite [

	"Create an object with at least `instanceVariableToWrite` instance variables.
	In memory, instance variables are 0-indexed so substract 1"
	obj := self newObjectWithSlots: instanceVariableToWrite.
	
	"The receiver should be in a receiver register based on Cog's calling convention"
	unicorn receiverRegisterValue: obj.

	self doExtendedStoreStoresVariableType: 0 index: instanceVariableToWrite.
]

{ #category : #'tests - extended store bytecode - store inst var' }
VMSimpleStackBasedCogitBytecodeTest >> doExtendedStoreStoresVariableType: type index: index [

	"Type = 0 is instance variable"
	"Type = 1 is temp variable"
	"Type = 2 is unused/invalid"
	"Type = 3 is literal variable (~association)"
	
	"The object is filled with nils.
	Push false into the stack and execute the store and pop bytecode."	
	self pushAddress: memory falseObject.
	
	"Set an address as store check trampoline.
	The bytecode below will jump to it if it is a old -> young store"
	cogit objectRepresentation ceStoreCheckTrampoline: memory nilObject.
	
	"The first byte of the push receiver instance variable bytecode family is used to identify which variable (0-based again)"
	cogit byte1: type << 6 + index - 1.
	self compile: [ cogit extendedStoreBytecode ].	
	self runGeneratedCode.
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> doPopIntoReceiverVariableBytecodeStoresVariableAt: instanceVariableToWrite [

	"Create an object with at least `instanceVariableToWrite` instance variables.
	In memory, instance variables are 0-indexed so substract 1"
	obj := self newObjectWithSlots: instanceVariableToWrite.
	
	"The receiver should be in a receiver register based on Cog's calling convention"
	unicorn receiverRegisterValue: obj.

	"The object is filled with nils.
	Push false into the stack and execute the store and pop bytecode."	
	self pushAddress: memory falseObject.
	
	"Set an address as store check trampoline.
	The bytecode below will jump to it if it is a old -> young store"
	cogit objectRepresentation ceStoreCheckTrampoline: memory nilObject.
	
	"The first byte of the push receiver instance variable bytecode family is used to identify which variable (0-based again)"
	cogit byte0: instanceVariableToWrite - 1.		
	self compile: [ 
		cogit genStoreAndPopReceiverVariableBytecode ].	
	self runGeneratedCode.
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> doTestReturnCleansStackWithFrame: isFrameful onBlock: generationBlock [

	| oldFP oldSP |

	"After the execution of the return the stack should be in the same state than before sending the message"	
	oldFP := self framePointerRegisterValue.
	oldSP := self stackPointerRegisterValue.

	isFrameful 
		ifTrue: [self createFramefulCallFrom: callerAddress]
		ifFalse: [self createFramelessCallFrom: callerAddress].		
	
	self compile: generationBlock.	
	self runUntilReturn.

	self assert: oldFP equals: self framePointerRegisterValue.
	self assert: oldSP equals: self stackPointerRegisterValue.
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> doTestReturnReturnsObjectInReturnRegister: anAddress withFrame: isFrameful onBlock: compilationBlock [

	isFrameful 
		ifTrue: [self createFramefulCallFrom: callerAddress]
		ifFalse: [self createFramelessCallFrom: callerAddress].		
	
	self compile: compilationBlock.	
	self runUntilReturn.

	self assert: unicorn returnRegisterValue equals: anAddress
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> doTestReturnReturnsToCallerWithFrame: isFrameful onBlock: compilationBlock [

	isFrameful 
		ifTrue: [self createFramefulCallFrom: callerAddress]
		ifFalse: [self createFramelessCallFrom: callerAddress].		
	
	self compile: compilationBlock.	
	self runUntilReturn.

	self assert: unicorn instructionPointerValue equals: callerAddress
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitBytecodeTest >> framePointerRegisterValue [

	^ self readRegister: UcX86Registers rbp
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitBytecodeTest >> framePointerRegisterValue: aValue [
	
	self writeRegister: UcX86Registers rbp value: aValue
]

{ #category : #'helpers - methods' }
VMSimpleStackBasedCogitBytecodeTest >> generateCogMethod: aBlockClosure selector: anSelectorOop [ 

	| targetCog targetCogAddress |

	targetCog := cogit cogMethodSurrogateAt: (cogit methodZone allocate: (cogit sizeof: CogMethod)).
	targetCog selector: anSelectorOop.

	targetCogAddress := self compile: [
		cogit compileAbort.
		cogit compileEntry.
		aBlockClosure value
	].
	
	^ targetCog

]

{ #category : #running }
VMSimpleStackBasedCogitBytecodeTest >> initialCodeSize [
	^ 4 * 1024
]

{ #category : #running }
VMSimpleStackBasedCogitBytecodeTest >> initializeInitialStackFrame [

	"I will create the initial stack with a well-known caller address so we know if the code comes back
	correctly. The address should be in a valid space of the memory if not unicorn complains. 
	So we just put it in the start of the stack"

	callerAddress := stackMemoryStartAddress.
	self createFramelessCallFrom: callerAddress receiver: memory nilObject arguments: #().
	

]

{ #category : #running }
VMSimpleStackBasedCogitBytecodeTest >> initializeStackMemory [.

	stackMemoryStartAddress := initialAddress + self initialCodeSize.
	stackMemoryEndAddress := stackMemoryStartAddress + stackSpaceSize.

	"The stack pointer is at the top of the stack"
	unicorn stackPointerRegisterValue: stackMemoryEndAddress.
	

]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitBytecodeTest >> instructionPointer [

	^ self readRegister: UcX86Registers rip
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> newInterpreter [

	| theMemory |
	theMemory := self newMemory.

	CogVMSimulatorLSB
		initializeWithOptions: {
			#BytesPerWord. 8.
			#ObjectMemory. theMemory class name}
		objectMemoryClass: theMemory class.
		
		
	^ CogVMSimulatorLSB basicNew
		objectMemory: theMemory;
		basicInitialize
]

{ #category : #running }
VMSimpleStackBasedCogitBytecodeTest >> newMemory [

	^ wordSize = 4
		ifTrue: [ Spur32BitCoMemoryManager simulatorClass new ]
		ifFalse: [ Spur64BitCoMemoryManager simulatorClass new ]
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> openMachineDebugger [
	
	VMMachineCodeDebugger new
		cogit: cogit;
		machineSimulator: unicorn;
		openWithSpec.
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> openMachineDebuggerAt: anInteger [ 
	
	unicorn instructionPointerValue: anInteger.
	self openMachineDebugger
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitBytecodeTest >> peek [

	| stackAddressIntegerValue peekedByteArray |

	"Getting address from stack register"
	stackAddressIntegerValue := unicorn stackPointerRegisterValue.

	"Putting the value in the stack memory"
	peekedByteArray := unicorn memoryAt: stackAddressIntegerValue readNext: self wordSize.
	
	^ peekedByteArray
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitBytecodeTest >> peekAddress [
	
	^ self peek integerAt: 1 size: self wordSize signed: false
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitBytecodeTest >> pop [

	| stackAddressIntegerValue poppedByteArray |

	"Getting address from stack register"
	stackAddressIntegerValue := unicorn stackPointerRegisterValue.

	"Putting the value in the stack memory"
	poppedByteArray := unicorn memoryAt: stackAddressIntegerValue readNext: self wordSize.

	"Updating SP"
	unicorn stackPointerRegisterValue: stackAddressIntegerValue + self wordSize.
	
	^ poppedByteArray
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitBytecodeTest >> popAddress [
	
	^ self pop integerAt: 1 size: self wordSize signed: false
]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitBytecodeTest >> push: aByteArray [

	| stackAddressIntegerValue |
	self assert: aByteArray size equals: self wordSize.

	"Getting address from stack register"
	stackAddressIntegerValue := unicorn stackPointerRegisterValue.

	"Updating SP"
	stackAddressIntegerValue := stackAddressIntegerValue - self wordSize.
	unicorn stackPointerRegisterValue: stackAddressIntegerValue.
	
	"Putting the value in the stack memory"
	unicorn
		memoryAt: stackAddressIntegerValue
		write: aByteArray
		size: self wordSize.

]

{ #category : #'helpers - stack' }
VMSimpleStackBasedCogitBytecodeTest >> pushAddress: anInteger [

	| aByteArray |
	aByteArray := ByteArray new: self wordSize.
	aByteArray integerAt: 1 put: anInteger size: self wordSize signed: false.
	self push: aByteArray
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> readMemoryAt: anAddress [

	| bytes |
	bytes := unicorn memoryAt: anAddress readNext: self wordSize.
	^ bytes integerAt: 1 size: self wordSize signed: false
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitBytecodeTest >> readRegister: aRegisterID [

	registerValue := ByteArray new: self wordSize.
	unicorn register: aRegisterID value readInto: registerValue.
	^ registerValue integerAt: 1 size: self wordSize signed: false
]

{ #category : #'helpers - frames' }
VMSimpleStackBasedCogitBytecodeTest >> readTemporaryValueAt: anIndex [

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
	
	^ self readMemoryAt: unicorn framePointerRegisterValue  - ((3 + anIndex) * self wordSize)
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> receiverRegister: anInteger [ 

	self writeRegister: UcX86Registers rdx value: anInteger
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitBytecodeTest >> returnValue [

	^ self readRegister: UcX86Registers rdx
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> runFrom: startAddress until: endAddress [

	self runFrom: startAddress until: endAddress timeout: 300 "microseconds"
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> runFrom: startAddress until: endAddress timeout: microseconds [

	unicorn startAt: startAddress
		until: endAddress
		timeout: microseconds
		count: 0.

	"Verify we stopped because we arrived to the right end addres and not a timeout"
	unicorn instructionPointerValue = endAddress ifFalse: [
		UnicornTimeout new
			target: endAddress;
			signal ]
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> runGeneratedCode [

	unicorn startAt: initialAddress
		until: 0
		timeout: 0
		count: opcodes.

]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> runUntilReturn [

	unicorn startAt: 16r1000000
		until: callerAddress
		timeout: 0
		count: 0.

]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> runUntilReturnFrom: anAddress [

	unicorn startAt: anAddress
		until: callerAddress
		timeout: 0
		count: 0.

]

{ #category : #running }
VMSimpleStackBasedCogitBytecodeTest >> setUp [
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
	self initializeInitialStackFrame.
	
	cogit methodZone manageFrom: initialAddress to: initialAddress + self initialCodeSize.
	cogit methodZoneBase: initialAddress.
	cogit minCallAddress: initialAddress.
	cogit cogCodeBase: initialAddress.
	memory coInterpreter cogCodeSize: self initialCodeSize.
	memory coInterpreter heapBase: stackMemoryEndAddress.
	
	memory coInterpreter numStackPages: 8.

	self initializeOldSpaceForScavenger.
]

{ #category : #running }
VMSimpleStackBasedCogitBytecodeTest >> setUpCPUSimulator [

	unicorn := UnicornSimulator perform: isa asSymbol.
	memory memory memoryObject pinInMemory.
	unicorn mapMemory: memory memory memoryObject at: initialAddress.
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitBytecodeTest >> stackPointerRegisterValue [

	^ self readRegister: UcX86Registers esp
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitBytecodeTest >> stackPointerRegisterValue: aValue [
	
	self writeRegister: UcX86Registers rsp value: aValue
]

{ #category : #'tests - extended push bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedPushPushesInstanceVariable1 [

	self testExtendedPushPushesInstanceVariable: 1
]

{ #category : #'tests - extended push bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedPushPushesInstanceVariable2 [

	self testExtendedPushPushesInstanceVariable: 2
]

{ #category : #'tests - extended push bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedPushPushesInstanceVariable3 [

	self testExtendedPushPushesInstanceVariable: 3
]

{ #category : #'tests - extended push bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedPushPushesInstanceVariable32 [

	self testExtendedPushPushesInstanceVariable: 32
]

{ #category : #'tests - extended push bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedPushPushesInstanceVariable64 [

	self testExtendedPushPushesInstanceVariable: 64
]

{ #category : #'tests - extended push bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedPushPushesInstanceVariable: instanceVariableToWrite [

	self testExtendedPushPushesVariableType: 0 "Instance variable type" index: instanceVariableToWrite
]

{ #category : #'tests - extended push bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedPushPushesVariableType: type index: instanceVariableToWrite [

	"Type = 0 is instance variable"
	"Type = 1 is temp variable"
	"Type = 2 is literal object"
	"Type = 3 is literal variable (~association)"

	"Create an object with at least `instanceVariableToWrite` instance variables.
	In memory, instance variables are 0-indexed so substract 1"
	obj := self newObjectWithSlots: instanceVariableToWrite.
	memory storePointer: instanceVariableToWrite - 1 ofObject: obj withValue: memory falseObject.
	
	"The receiver should be in a receiver register based on Cog's calling convention"
	unicorn receiverRegisterValue: obj.
	
	"The first byte of the push receiver instance variable bytecode family is used to identify which variable (0-based again)"
	cogit byte1: type << 6 + instanceVariableToWrite - 1.
	self compile: [ cogit extendedPushBytecode ].	
	self runGeneratedCode.

	self assert: self popAddress equals: memory falseObject
]

{ #category : #'tests - extended store bytecode - store inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedStoreInstanceVariableIndex1LeavesStackUnchanged [

	"Check that we push a false that is not popped"
	self assertPushed: memory falseObject after: [ self doExtendedStoreStoresInstanceVariableIndex: 1 ]
]

{ #category : #'tests - extended store bytecode - store inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedStoreInstanceVariableIndex2LeavesStackUnchanged [

	"Check that we push a false that is not popped"
	self assertPushed: memory falseObject after: [ self doExtendedStoreStoresInstanceVariableIndex: 2 ]
]

{ #category : #'tests - extended store bytecode - store inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedStoreInstanceVariableIndex32LeavesStackUnchanged [

	"Check that we push a false that is not popped"
	self assertPushed: memory falseObject after: [ self doExtendedStoreStoresInstanceVariableIndex: 32 ]
]

{ #category : #'tests - extended store bytecode - store inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedStoreInstanceVariableIndex64LeavesStackUnchanged [

	"Check that we push a false that is not popped"
	self assertPushed: memory falseObject after: [ self doExtendedStoreStoresInstanceVariableIndex: 64 ]
]

{ #category : #'tests - extended store bytecode - store inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedStoreStoresInstanceVariableIndex1 [

	self testExtendedStoreStoresInstanceVariableIndex: 1
]

{ #category : #'tests - extended store bytecode - store inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedStoreStoresInstanceVariableIndex2 [

	self testExtendedStoreStoresInstanceVariableIndex: 2
]

{ #category : #'tests - extended store bytecode - store inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedStoreStoresInstanceVariableIndex32 [

	self testExtendedStoreStoresInstanceVariableIndex: 32
]

{ #category : #'tests - extended store bytecode - store inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedStoreStoresInstanceVariableIndex64 [

	self testExtendedStoreStoresInstanceVariableIndex: 64
]

{ #category : #'tests - extended store bytecode - store inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testExtendedStoreStoresInstanceVariableIndex: instanceVariableToWrite [

	self doExtendedStoreStoresInstanceVariableIndex: instanceVariableToWrite.

	"After execution false should be popped from the stack and false should be stored in the object's variable (0-based)."
	self assert: (memory fetchPointer: instanceVariableToWrite - 1 ofObject: obj) equals: memory falseObject
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopInto3rdTempPopsValue [

	self testPopIntoTempPopsValueAt: 3
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopInto3rdTempUpdatesTemporaryWithFalse [

	self testPopIntoTempUpdatesVariableAt: 3
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopInto4thTempPopsValue [

	self testPopIntoTempPopsValueAt: 4
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopInto4thTempUpdatesTemporaryWithFalse [

	self testPopIntoTempUpdatesVariableAt: 4
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopInto5thTempPopsValue [

	self testPopIntoTempPopsValueAt: 5
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopInto5thTempUpdatesTemporaryWithFalse [

	self testPopIntoTempUpdatesVariableAt: 5
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopInto6thTempPopsValue [

	self testPopIntoTempPopsValueAt: 6
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopInto6thTempUpdatesTemporaryWithFalse [

	self testPopIntoTempUpdatesVariableAt: 6
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopInto7thTempPopsValue [

	self testPopIntoTempPopsValueAt: 7
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopInto7thTempUpdatesTemporaryWithFalse [

	self testPopIntoTempUpdatesVariableAt: 7
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoEighthReceiverVariableBytecodePopsValue [

	"The block pushed and then pops.
	The stack should remain unchanged after the execution"
	self assertStackRemainsUnchangedDuring: [ self doPopIntoReceiverVariableBytecodeStoresVariableAt: 8 ]
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoFifthReceiverVariableBytecodePopsValue [

	"The block pushed and then pops.
	The stack should remain unchanged after the execution"
	self assertStackRemainsUnchangedDuring: [ self doPopIntoReceiverVariableBytecodeStoresVariableAt: 5 ]
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoFirstReceiverVariableBytecodePopsValue [

	"The block pushed and then pops.
	The stack should remain unchanged after the execution"
	self assertStackRemainsUnchangedDuring: [ self doPopIntoReceiverVariableBytecodeStoresVariableAt: 1 ]
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoFirstTempPopsValue [

	self testPopIntoTempPopsValueAt: 1
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoFirstTempUpdatesTemporaryWithFalse [

	self testPopIntoTempUpdatesVariableAt: 1
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoFourthReceiverVariableBytecodePopsValue [

	"The block pushed and then pops.
	The stack should remain unchanged after the execution"
	self assertStackRemainsUnchangedDuring: [ self doPopIntoReceiverVariableBytecodeStoresVariableAt: 4 ]
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoReceiverVariableBytecodeStoresEigthInstanceVariable [

	self testPopIntoReceiverVariableBytecodeStoresVariableAt: 8
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoReceiverVariableBytecodeStoresFifthInstanceVariable [

	self testPopIntoReceiverVariableBytecodeStoresVariableAt: 5
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoReceiverVariableBytecodeStoresFirstInstanceVariable [

	self testPopIntoReceiverVariableBytecodeStoresVariableAt: 1
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoReceiverVariableBytecodeStoresFourthInstanceVariable [

	self testPopIntoReceiverVariableBytecodeStoresVariableAt: 4
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoReceiverVariableBytecodeStoresSecondInstanceVariable [

	self testPopIntoReceiverVariableBytecodeStoresVariableAt: 2
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoReceiverVariableBytecodeStoresSeventhInstanceVariable [

	self testPopIntoReceiverVariableBytecodeStoresVariableAt: 7
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoReceiverVariableBytecodeStoresSixthInstanceVariable [

	self testPopIntoReceiverVariableBytecodeStoresVariableAt: 6
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoReceiverVariableBytecodeStoresThirdInstanceVariable [

	self testPopIntoReceiverVariableBytecodeStoresVariableAt: 3
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoReceiverVariableBytecodeStoresVariableAt: instanceVariableToWrite [

	self doPopIntoReceiverVariableBytecodeStoresVariableAt: instanceVariableToWrite.

	"After execution false should be popped from the stack and false should be stored in the object's variable (0-based)."
	self assert: (memory fetchPointer: instanceVariableToWrite - 1 ofObject: obj) equals: memory falseObject
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoSecondReceiverVariableBytecodePopsValue [

	"The block pushed and then pops.
	The stack should remain unchanged after the execution"
	self assertStackRemainsUnchangedDuring: [ self doPopIntoReceiverVariableBytecodeStoresVariableAt: 2 ]
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoSecondTempPopsValue [

	self testPopIntoTempPopsValueAt: 2
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoSecondTempUpdatesTemporaryWithFalse [

	self testPopIntoTempUpdatesVariableAt: 2
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoSeventhReceiverVariableBytecodePopsValue [

	"The block pushed and then pops.
	The stack should remain unchanged after the execution"
	self assertStackRemainsUnchangedDuring: [ self doPopIntoReceiverVariableBytecodeStoresVariableAt: 7 ]
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoSixthReceiverVariableBytecodePopsValue [

	"The block pushed and then pops.
	The stack should remain unchanged after the execution"
	self assertStackRemainsUnchangedDuring: [ self doPopIntoReceiverVariableBytecodeStoresVariableAt: 6 ]
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoTempPopsValueAt: tempVariableUnderTest [

	| temporaries |
	
	temporaries  := (1 to: tempVariableUnderTest) 
		collect: [ :anIndex | memory nilObject].

	self 
		createFramefulCallFrom: callerAddress 
		receiver: memory nilObject 
		arguments: #() 
		temporaries: temporaries.

	"The bytecode of the push temporary variable is used to identify the index (from 0 to 7) and it starts from 104 to 111"
	cogit byte0: tempVariableUnderTest - 1 + 104.
	self compile: [ cogit genStoreAndPopTemporaryVariableBytecode ].	

	"I push two values, so I can test that the false is pop out"
	self pushAddress: memory trueObject.
	self pushAddress: memory falseObject.

	self runGeneratedCode.

	self assert: self popAddress equals: memory trueObject
]

{ #category : #'tests - single bytecode - pop into temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoTempUpdatesVariableAt: tempVariableUnderTest [

	| temporaries |
	
	temporaries  := (1 to: tempVariableUnderTest) 
		collect: [ :anIndex | memory nilObject].

	self 
		createFramefulCallFrom: callerAddress 
		receiver: memory nilObject 
		arguments: #() 
		temporaries: temporaries.

	"The bytecode of the push temporary variable is used to identify the index (from 0 to 7) and it starts from 104 to 111"
	cogit byte0: tempVariableUnderTest - 1 + 104.
	self compile: [ cogit genStoreAndPopTemporaryVariableBytecode ].	

	self pushAddress: memory falseObject.

	self runGeneratedCode.

	self assert: (self readTemporaryValueAt: tempVariableUnderTest) equals: memory falseObject
]

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoThirdReceiverVariableBytecodePopsValue [

	"The block pushed and then pops.
	The stack should remain unchanged after the execution"
	self assertStackRemainsUnchangedDuring: [ self doPopIntoReceiverVariableBytecodeStoresVariableAt: 3 ]
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPush10thTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 10
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPush10thTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 10
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPush11thTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 11
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPush11thTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 11
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPush12thTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 12
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPush12thTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 12
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPush13thTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 13
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPush13thTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 13
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPush14thTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 14
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPush14thTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 14
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPush15thTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 15
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPush15thTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 15
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPush3rdTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 3
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPush4thTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 4
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPush4thTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 4
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPush5thTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 5
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPush5thTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 5
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPush6thTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 6
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPush6thTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 6
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPush7thTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 7
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPush7thTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 7
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPush8thTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 8
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPush8thTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 8
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPush9thTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 9
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPush9thTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 9
]

{ #category : #'tests - single bytecode' }
VMSimpleStackBasedCogitBytecodeTest >> testPushConstantFalseBytecodePushesFalse [
	
	self compile: [ cogit genPushConstantFalseBytecode ].	
	self runGeneratedCode.
	
	self assert: (self popAddress) equals: memory falseObject
]

{ #category : #'tests - two bytecodes' }
VMSimpleStackBasedCogitBytecodeTest >> testPushConstantNilAndThenReturn [
	
	self compile: [ 
		cogit genPushConstantNilBytecode.
		cogit genReturnTopFromMethod ] bytecodes: 2.

	self runGeneratedCode.
	
	self assert: unicorn receiverRegisterValue equals: memory nilObject
]

{ #category : #'tests - single bytecode' }
VMSimpleStackBasedCogitBytecodeTest >> testPushConstantNilBytecodePushesNil [
	
	self compile: [ cogit genPushConstantNilBytecode ].	
	self runGeneratedCode.
	
	self assert: (self popAddress) equals: memory nilObject
]

{ #category : #'tests - single bytecode' }
VMSimpleStackBasedCogitBytecodeTest >> testPushConstantTrueBytecodePushesTrue [
	
	self compile: [ cogit genPushConstantTrueBytecode ].	
	self runGeneratedCode.
	
	self assert: (self popAddress) equals: memory trueObject
]

{ #category : #'tests - single bytecode' }
VMSimpleStackBasedCogitBytecodeTest >> testPushConstantZeroBytecodePushesASmallIntegerZero [
	
	self compile: [ cogit genPushConstantZeroBytecode ].	
	self runGeneratedCode.
	
	self assert: (self popAddress) equals: (memory integerObjectOf: 0)
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPushFirstTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 1
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPushFirstTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 1
]

{ #category : #'tests - single bytecode' }
VMSimpleStackBasedCogitBytecodeTest >> testPushQuickIntegerMinusOnePushesAMinusOne [
	
	cogit byte0: 116. 
	
	self compile: [ cogit genPushQuickIntegerConstantBytecode ].	
	self runGeneratedCode.
	
	self assert: (self popAddress) equals: (memory integerObjectOf: -1)
]

{ #category : #'tests - single bytecode' }
VMSimpleStackBasedCogitBytecodeTest >> testPushQuickIntegerOnePushesOne [
	
	cogit byte0: 118. 
	
	self compile: [ cogit genPushQuickIntegerConstantBytecode ].	
	self runGeneratedCode.
	
	self assert: (self popAddress) equals: (memory integerObjectOf: 1)
]

{ #category : #'tests - single bytecode' }
VMSimpleStackBasedCogitBytecodeTest >> testPushQuickIntegerTwoPushesTwo [
	
	cogit byte0: 119. 
	
	self compile: [ cogit genPushQuickIntegerConstantBytecode ].	
	self runGeneratedCode.
	
	self assert: (self popAddress) equals: (memory integerObjectOf: 2)
]

{ #category : #'tests - single bytecode' }
VMSimpleStackBasedCogitBytecodeTest >> testPushQuickIntegerZeroPushesAZero [
	
	cogit byte0: 117. 
	
	self compile: [ cogit genPushQuickIntegerConstantBytecode ].	
	self runGeneratedCode.
	
	self assert: (self popAddress) equals: (memory integerObjectOf: 0)
]

{ #category : #'tests - single bytecode' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverBytecodePushesTheReceiver [

	unicorn receiverRegisterValue: 75. 
	
	self compile: [ cogit genPushReceiverBytecode ].	
	self runGeneratedCode.
	
	self assert: (self popAddress) equals: 75
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesEighthVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 8
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesEleventhVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 11
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesFifteenthVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 15
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesFifthVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 5
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesFirstVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 1
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesFourteenthVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 14
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesFourthVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 4
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesNinthVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 9
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesSecondVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 2
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesSeventhVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 7
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesSixteenthVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 16
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesSixthVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 6
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesTenthVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 10
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesThirdVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 3
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesThirteenthVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 13
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesTwelfthVariable [

	self testPushReceiverVariableBytecodeZeroPushesVariableAt: 12
]

{ #category : #'tests - single bytecode - push inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesVariableAt: instanceVariableToWrite [

	"Create an object with at least `instanceVariableToWrite` instance variables.
	In memory, instance variables are 0-indexed so substract 1"
	obj := self newObjectWithSlots: instanceVariableToWrite.
	memory storePointer: instanceVariableToWrite - 1 ofObject: obj withValue: memory falseObject.
	
	"The receiver should be in a receiver register based on Cog's calling convention"
	unicorn receiverRegisterValue: obj.
	
	"The first byte of the push receiver instance variable bytecode family is used to identify which variable (0-based again)"
	cogit byte0: instanceVariableToWrite - 1.		
	self compile: [ cogit genPushReceiverVariableBytecode ].	
	self runGeneratedCode.

	self assert: self popAddress equals: memory falseObject
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPushSecondTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 2
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPushSecondTempVariableWithArgumentsPushesArgument [

	self testPushTempVariablePushesArgumentAt: 2
]

{ #category : #'tests - single bytecode - push temp - arg' }
VMSimpleStackBasedCogitBytecodeTest >> testPushTempVariablePushesArgumentAt: tempVariableUnderTest [

	| arguments |
	
	arguments  := (1 to: tempVariableUnderTest) collect: [ :anIndex | 
		anIndex = tempVariableUnderTest ifTrue: [ memory falseObject ] ifFalse: [memory nilObject]].

	self 
		createFramefulCallFrom: callerAddress 
		receiver: memory nilObject 
		arguments: arguments 
		temporaries: #().

	"The bytecode of the push temporary variable is used to identify the index (from 0 to 15) and it starts from 16 to 31"
	cogit byte0: tempVariableUnderTest - 1 + 16.
	self compile: [ cogit genPushTemporaryVariableBytecode ].	

	self runGeneratedCode.

	self assert: self popAddress equals: memory falseObject
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPushTempVariablePushesVariableAt: tempVariableUnderTest [

	| temporaries |
	
	temporaries  := (1 to: tempVariableUnderTest) collect: [ :anIndex | 
		anIndex = tempVariableUnderTest ifTrue: [ memory falseObject ] ifFalse: [memory nilObject]].

	self 
		createFramefulCallFrom: callerAddress 
		receiver: memory nilObject 
		arguments: #() 
		temporaries: temporaries.

	self assert: (self readMemoryAt: unicorn stackPointerRegisterValue) equals: memory falseObject.
	
	"The bytecode of the push temporary variable is used to identify the index (from 0 to 15) and it starts from 16 to 31"
	cogit byte0: tempVariableUnderTest - 1 + 16.
	self compile: [ cogit genPushTemporaryVariableBytecode ].	

	self runGeneratedCode.

	self assert: self popAddress equals: memory falseObject
]

{ #category : #'tests - single bytecode - push temp' }
VMSimpleStackBasedCogitBytecodeTest >> testPushThirdTempVariablePushesVariable [

	self testPushTempVariablePushesVariableAt: 3
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnNilFramefulCleansStack [

	self doTestReturnCleansStackWithFrame: true onBlock: [ cogit genReturnNil ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnNilFramefulLeavesNilInReturnRegister [

	self
		doTestReturnReturnsObjectInReturnRegister: memory nilObject
		withFrame: true
		onBlock: [ cogit genReturnNil ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnNilFramefulReturnsToCaller [

	self doTestReturnReturnsToCallerWithFrame: true onBlock: [ cogit genReturnNil ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnNilFramelessCleansStack [

	self doTestReturnCleansStackWithFrame: false onBlock: [ cogit genReturnNil ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnNilFramelessLeavesNilInReturnRegister [

	self
		doTestReturnReturnsObjectInReturnRegister: memory nilObject
		withFrame: false
		onBlock: [ cogit genReturnNil ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnNilFramelessReturnsToCaller [

	self doTestReturnReturnsToCallerWithFrame: false onBlock: [ cogit genReturnNil ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnTopFramefulLeavesTopObjectInReturnRegister [

	self
		doTestReturnReturnsObjectInReturnRegister: memory falseObject
		withFrame: true
		onBlock: [ 
			self pushAddress: memory falseObject.
			cogit genReturnTopFromMethod ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnTopFramefullCleansStack [

	self doTestReturnCleansStackWithFrame: true onBlock: [ 
		self pushAddress: memory falseObject.
		cogit genReturnTopFromMethod ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnTopFramefullReturnsToCaller [

	self doTestReturnReturnsToCallerWithFrame: true onBlock: [ 
		self pushAddress: memory falseObject.
		cogit genReturnTopFromMethod ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnTopFramelesCleansStack [

	self doTestReturnCleansStackWithFrame: false onBlock: [ 
		self pushAddress: memory falseObject.
		cogit genReturnTopFromMethod ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnTopFramelessLeavesTopObjectInReturnRegister [

	self
		doTestReturnReturnsObjectInReturnRegister: memory falseObject
		withFrame: false
		onBlock: [ 
			self pushAddress: memory falseObject.
			cogit genReturnTopFromMethod ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnTopFramelessReturnsToCaller [

	self doTestReturnReturnsToCallerWithFrame: false onBlock: [ 
		self pushAddress: memory falseObject.
		cogit genReturnTopFromMethod ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnTrueFramefulCleansStack [

	self
		doTestReturnCleansStackWithFrame: true
		onBlock: [ cogit genReturnTrue ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnTrueFramefulLeavesTrueObjectInReturnRegister [

	self
		doTestReturnReturnsObjectInReturnRegister: memory trueObject
		withFrame: true
		onBlock: [ 
			cogit genReturnTrue ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnTrueFramefulReturnsToCaller [

	self
		doTestReturnReturnsToCallerWithFrame: true
		onBlock: [ cogit genReturnTrue ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnTrueFramelessCleansStack [

	self
		doTestReturnCleansStackWithFrame: false
		onBlock: [ cogit genReturnTrue ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnTrueFramelessLeavesTrueObjectInReturnRegister [

	self
		doTestReturnReturnsObjectInReturnRegister: memory trueObject
		withFrame: false
		onBlock: [ 
			cogit genReturnTrue ]
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnTrueFramelessReturnsToCaller [

	self
		doTestReturnReturnsToCallerWithFrame: false
		onBlock: [ cogit genReturnTrue ]
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendEqualsEqualsWithIdenticalObjectsPushesTrue [

	sendAddress := self compile: [ cogit genSpecialSelectorEqualsEquals ].
	
	"Push receiver, arg then send"
	self pushAddress: memory nilObject.
	self pushAddress: memory nilObject.
	self runFrom: sendAddress until: lastAddress.
	
	self
		assert: self popAddress
		equals: memory trueObject
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendEqualsEqualsWithNonIdenticalObjectsPushesFalse [

	sendAddress := self compile: [ cogit genSpecialSelectorEqualsEquals ].
	
	"Push receiver, arg then send"
	self pushAddress: memory nilObject.
	self pushAddress: memory trueObject.
	self runFrom: sendAddress until: lastAddress.
	
	self
		assert: self popAddress
		equals: memory falseObject
]

{ #category : #'tests - sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendLiteralOneWithZeroArgsMovesSelectorIndexClassRegisterIn64bits [
	
	| selector literalIndex |
	self wordSize = 4 ifTrue: [ ^ self skip ].

	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: 0 "num args" put: sendTrampolineAddress.
	
	self createFramefulCallFrom: callerAddress.
	
	literalIndex := 1.
	"The literal index is extracted from the byte0 of the instruction
	It is encoded with the bytecode number.
	The 208 is the first bytecode to send messages with zero arguments.
	The literal taken starts from zero in 208, one in 209... and so on"
	cogit byte0: 208 + literalIndex.
	selector := memory falseObject.
	cogit methodObj: (self newMethodWithLiteral: selector at: literalIndex).

	"The method will have 3 literals.
	The first literal is the methodHeader (smallInteger with flags).
	Literal 0 -> we are not using it (now it is nil)
	Literal 1 -> our selector"
	
	sendAddress := self compile: [ cogit genSendLiteralSelector0ArgsBytecode ].

	"Push receiver, arg, then send"
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self
		assert: unicorn classRegisterValue
		equals: literalIndex
]

{ #category : #'tests - sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendLiteralOneWithZeroArgsMovesSelectorIntoClassRegisterIn32bits [
	
	| selector literalIndex |
	self wordSize = 8 ifTrue: [ ^ self skip ].

	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: 0 "num args" put: sendTrampolineAddress.
	
	self createFramefulCallFrom: callerAddress.
	
	literalIndex := 1.
	cogit byte0: literalIndex.
	selector := memory falseObject.
	cogit methodObj: (self newMethodWithLiteral: selector at: literalIndex).
	sendAddress := self compile: [ cogit genSendLiteralSelector0ArgsBytecode ].

	"Push receiver, arg, then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self
		assert: unicorn classRegisterValue
		equals: selector
]

{ #category : #'tests - sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendLiteralZeroWithZeroArgsMovesReceiverFromStackTopIntoReceiverRegister [

	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: 0 "num args" put: sendTrampolineAddress.
	
	self createFramefulCallFrom: callerAddress.
	
	cogit byte0: 0.
	cogit methodObj: (self newMethodWithLiteral: memory falseObject at: 0).
	sendAddress := self compile: [ cogit genSendLiteralSelector0ArgsBytecode ].

	"Push receiver then send"
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self assert: unicorn receiverRegisterValue equals: memory falseObject
]

{ #category : #'tests - sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendLiteralZeroWithZeroArgsMovesSelectorIndexClassRegisterIn64bits [
	
	| selector literalIndex |
	self wordSize = 4 ifTrue: [ ^ self skip ].

	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: 0 "num args" put: sendTrampolineAddress.
	
	self createFramefulCallFrom: callerAddress.
	
	cogit byte0: 0.
	selector := memory falseObject.
	cogit methodObj: (self newMethodWithLiteral: selector at: (literalIndex := 0)).
	sendAddress := self compile: [ cogit genSendLiteralSelector0ArgsBytecode ].

	"Push receiver, arg, then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self
		assert: unicorn classRegisterValue
		equals: literalIndex
]

{ #category : #'tests - sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendLiteralZeroWithZeroArgsMovesSelectorIntoClassRegisterIn32bits [
	
	| selector |
	self wordSize = 8 ifTrue: [ ^ self skip ].

	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: 0 "num args" put: sendTrampolineAddress.
	
	self createFramefulCallFrom: callerAddress.
	
	cogit byte0: 0.
	selector := memory falseObject.
	cogit methodObj: (self newMethodWithLiteral: selector at: 0).
	sendAddress := self compile: [ cogit genSendLiteralSelector0ArgsBytecode ].

	"Push receiver, arg, then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self
		assert: unicorn classRegisterValue
		equals: selector
]

{ #category : #'tests - sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendLiteralZeroWithZeroArgsPushesReturnValueFromReceiverRegisterAfterReturn [

	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: 0 "num args" put: sendTrampolineAddress.
	
	self createFramefulCallFrom: callerAddress.
	
	cogit byte0: 0.
	cogit methodObj: (self newMethodWithLiteral: memory falseObject at: 0).
	sendAddress := self compile: [ cogit genSendLiteralSelector0ArgsBytecode ].

	"Push receiver, arg, then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	"Now return from called function/method and execute until the end of the send instruction"
	unicorn returnRegisterValue: (memory integerObjectOf: 42).
	self runFrom: unicorn instructionPointerValue until: lastAddress.
	
	self assert: self popAddress equals: (memory integerObjectOf: 42).
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendNotEqualsEqualsWithIdenticalObjectsPushesFalse [

	sendAddress := self compile: [ cogit genSpecialSelectorNotEqualsEquals ].
	
	"Push receiver, arg then send"
	self pushAddress: memory nilObject.
	self pushAddress: memory nilObject.
	self runFrom: sendAddress until: lastAddress.
	
	self
		assert: self popAddress
		equals: memory falseObject
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendNotEqualsEqualsWithNonIdenticalObjectsPushesTrue [

	sendAddress := self compile: [ cogit genSpecialSelectorNotEqualsEquals ].
	
	"Push receiver, arg then send"
	self pushAddress: memory nilObject.
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: lastAddress.
	
	self
		assert: self popAddress
		equals: memory trueObject
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendOneArgSpecialMessageDoesNotMovesIntoSendNumArgsRegister [
	
	| previousValue |
	sentSelector := #+.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	unicorn sendNumberOfArgumentsRegisterValue: (previousValue := 42).
	
	"Push receiver, arg, then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self
		assert: unicorn sendNumberOfArgumentsRegisterValue
		equals: previousValue
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendOneArgSpecialMessageMovesNegatedSelectorIndexIntoClassRegisterIn64bits [
	
	| signed |
	
	self wordSize = 4 ifTrue: [ self skip ].
	
	sentSelector := #+.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	"Push receiver, arg, then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	signed := (ByteArray new: self wordSize)
		in: [ :a | 
			a integerAt: 1 put: unicorn classRegisterValue size: self wordSize signed: false.
			a integerAt: 1 size: self wordSize signed: true ].
	self
		assert: signed
		equals: (selectorIndex + 1 / 2) negated
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendOneArgSpecialMessageMovesReceiverFromStackTopIntoReceiverRegister [

	sentSelector := #+.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	"Push receiver, arg, then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self assert: unicorn receiverRegisterValue equals: memory falseObject
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendOneArgSpecialMessageMovesSelectorIntoClassRegisterIn32bits [
	
	self wordSize = 8 ifTrue: [ self skip ].
	
	sentSelector := #+.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	"Push receiver, arg, then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self
		assert: unicorn classRegisterValue
		equals: selectorAtIndex
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendOneArgSpecialMessagePushesReturnValueFromReceiverRegisterAfterReturn [
	
	sentSelector := #+.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	"Push receiver, arg, then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	"Now return from called function/method and execute until the end of the send instruction"
	unicorn returnRegisterValue: (memory integerObjectOf: 42).
	self runFrom: unicorn instructionPointerValue until: lastAddress.
	
	self assert: self popAddress equals: (memory integerObjectOf: 42).
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendTwoArgSpecialMessageDoesNotMovesIntoSendNumArgsRegister [
	
	| previousValue |
	sentSelector := #at:put:.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	unicorn sendNumberOfArgumentsRegisterValue: (previousValue := 42).
	
	"Push receiver, arg1, arg2 then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self pushAddress: (memory integerObjectOf: 7).
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self
		assert: unicorn sendNumberOfArgumentsRegisterValue
		equals: previousValue
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendTwoArgSpecialMessageMovesNegatedSelectorIndexIntoClassRegisterIn64bits [
	
	| signed |
	
	self wordSize = 4 ifTrue: [ self skip ].
	
	sentSelector := #at:put:.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	"Push receiver, arg1, arg2 then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self pushAddress: (memory integerObjectOf: 7).
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	signed := (ByteArray new: self wordSize)
		in: [ :a | 
			a integerAt: 1 put: unicorn classRegisterValue size: self wordSize signed: false.
			a integerAt: 1 size: self wordSize signed: true ].
	self
		assert: signed
		equals: (selectorIndex + 1 / 2) negated
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendTwoArgSpecialMessageMovesReceiverFromStackTopIntoReceiverRegister [
	
	sentSelector := #at:put:.
	self createSpecialSelectorArray.
	self compileSpecialSend.

	"Push receiver, arg1, arg2 then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self pushAddress: (memory integerObjectOf: 7).
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self assert: unicorn receiverRegisterValue equals: memory falseObject
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendTwoArgSpecialMessageMovesSelectorIntoClassRegisterIn32bits [
	
	| signed |
	
	self wordSize = 4 ifTrue: [ self skip ].
	
	sentSelector := #at:put:.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	"Push receiver, arg1, arg2 then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self pushAddress: (memory integerObjectOf: 7).
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	signed := (ByteArray new: self wordSize)
		in: [ :a | 
			a integerAt: 1 put: unicorn classRegisterValue size: self wordSize signed: false.
			a integerAt: 1 size: self wordSize signed: true ].
	self
		assert: signed
		equals: (selectorIndex + 1 / 2) negated
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendTwoArgSpecialMessagePushesReturnValueFromReceiverRegisterAfterReturn [
	
	sentSelector := #at:put:.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	"Push receiver, arg1, arg2 then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self pushAddress: (memory integerObjectOf: 7).
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	"Now return from called function/method and execute until the end of the send instruction"
	unicorn returnRegisterValue: (memory integerObjectOf: 42).
	self runFrom: unicorn instructionPointerValue until: lastAddress.
	
	self assert: self popAddress equals: (memory integerObjectOf: 42).
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendZeroArgSpecialMessageDoesNotMovesIntoSendNumArgsRegister [
	
	| previousValue |
	sentSelector := #atEnd.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	unicorn sendNumberOfArgumentsRegisterValue: (previousValue := 42).
	
	"Push receiver, then send"
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self
		assert: unicorn sendNumberOfArgumentsRegisterValue
		equals: previousValue
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendZeroArgSpecialMessageMovesNegatedSelectorIndexIntoClassRegisterIn64Bits [
	
	| signed |
	
	self wordSize = 4 ifTrue: [ self skip ].
	
	sentSelector := #atEnd.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	"Push receiver, then send"
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	signed := (ByteArray new: self wordSize)
		in: [ :a | 
			a integerAt: 1 put: unicorn classRegisterValue size: self wordSize signed: false.
			a integerAt: 1 size: self wordSize signed: true ].
	self
		assert: signed
		equals: (selectorIndex + 1 / 2) negated
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendZeroArgSpecialMessageMovesReceiverFromStackTopIntoReceiverRegister [
	
	sentSelector := #atEnd.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	"Push receiver, then send"
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self assert: unicorn receiverRegisterValue equals: memory falseObject
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendZeroArgSpecialMessageMovesSelectorIntoClassRegisterIn32Bits [
	
	self wordSize = 8 ifTrue: [ self skip ].
	
	sentSelector := #atEnd.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	"Push receiver, then send"
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self
		assert: unicorn classRegisterValue
		equals: selectorAtIndex
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendZeroArgSpecialMessagePushesReturnValueFromReceiverRegisterAfterReturn [
	
	sentSelector := #atEnd.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	"Push receiver, then send"
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	"Now return from called function/method and execute until the end of the send instruction"
	unicorn returnRegisterValue: (memory integerObjectOf: 42).
	self runFrom: unicorn instructionPointerValue until: lastAddress.
	
	self assert: self popAddress equals: (memory integerObjectOf: 42).
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> wordSize [
	
	^ memory wordSize
]

{ #category : #running }
VMSimpleStackBasedCogitBytecodeTest >> wordSize: aWordSize [

	wordSize := aWordSize
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitBytecodeTest >> writeRegister: anUcX86Registers value: anInteger [ 

	| value |
	value := ByteArray new: self wordSize.
	value integerAt: 1 put: anInteger size: self wordSize signed: false.
	unicorn register: anUcX86Registers value write: value.

]
