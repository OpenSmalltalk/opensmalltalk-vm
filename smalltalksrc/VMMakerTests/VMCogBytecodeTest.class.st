Class {
	#name : #VMCogBytecodeTest,
	#superclass : #VMSpurMemoryManagerTest,
	#instVars : [
		'cogit',
		'codeSize',
		'lastAddress',
		'unicorn',
		'callerAddress',
		'registerValue',
		'opcodes'
	],
	#category : #VMMakerTests
}

{ #category : #helpers }
VMCogBytecodeTest >> compile: aBlockClosure opcodes: anInteger [ 

	^ self compile: aBlockClosure opcodes: anInteger bytecodes: 1
]

{ #category : #helpers }
VMCogBytecodeTest >> compile: aBlockClosure opcodes: amountOfInstructions bytecodes: bytecodes [

	opcodes := amountOfInstructions.
	cogit allocateOpcodes: amountOfInstructions bytecodes: bytecodes ifFail: [ self fail ].
	cogit zeroOpcodeIndex.
	
	aBlockClosure value.

	cogit methodLabel address: 0.
	cogit computeMaximumSizes.
	
	codeSize := cogit generateInstructionsAt: 0 "methodLabel address + headerSize?".
	cogit methodZone allocate: codeSize.
	lastAddress := cogit outputInstructionsAt: 0.

	
	"Install the code in the memory"
	unicorn
		memoryAt: 16r1000000
		write: memory memory asByteArray
		size: lastAddress.

]

{ #category : #helpers }
VMCogBytecodeTest >> disassemble [
	
	^ LLVMDisassembler amd64 
		disassembleNext: opcodes
		instructionsIn: (memory memory copyFrom: 1 to: 24) asByteArray pc: 0
]

{ #category : #'helpers - registers' }
VMCogBytecodeTest >> instructionPointer [

	^ self readRegister: UcX86Registers rip
]

{ #category : #helpers }
VMCogBytecodeTest >> newInterpreter [

	^ CogVMSimulator newWithOptions: {#BytesPerWord . 8}
]

{ #category : #helpers }
VMCogBytecodeTest >> newMemory [

	^ Spur64BitMMLECoSimulator new
]

{ #category : #helpers }
VMCogBytecodeTest >> pop [

	| stackAddress stackAddressIntegerValue poppedByteArray |

	stackAddress := ByteArray new: self wordSize.
	unicorn register: UcX86Registers rsp value readInto: stackAddress. 

	"Getting address from stack register"
	stackAddressIntegerValue := stackAddress integerAt: 1 size: self wordSize signed: false.

	"Putting the value in the stack memory"
	poppedByteArray := unicorn memoryAt: stackAddressIntegerValue readNext: self wordSize.

	"Updating SP"
	stackAddressIntegerValue := stackAddressIntegerValue + self wordSize.
	stackAddress integerAt: 1 put: stackAddressIntegerValue size: self wordSize signed: false.
	unicorn register: UcX86Registers rsp value write: stackAddress.
	
	^ poppedByteArray
]

{ #category : #helpers }
VMCogBytecodeTest >> popAddress [
	
	^ self pop integerAt: 1 size: self wordSize signed: false
]

{ #category : #helpers }
VMCogBytecodeTest >> push: aByteArray [

	| stackAddress stackAddressIntegerValue |

	self assert: aByteArray size equals: self wordSize.

	stackAddress := ByteArray new: self wordSize.
	
	unicorn register: UcX86Registers rsp value readInto: stackAddress. 

	"Getting address from stack register"
	stackAddressIntegerValue := stackAddress integerAt: 1 size: self wordSize signed: false.

	"Updating SP"
	stackAddressIntegerValue := stackAddressIntegerValue - self wordSize.
	stackAddress integerAt: 1 put: stackAddressIntegerValue size: self wordSize signed: false.
	unicorn register: UcX86Registers rsp value write: stackAddress.
	
	"Putting the value in the stack memory"
	unicorn
		memoryAt: stackAddressIntegerValue
		write: aByteArray
		size: self wordSize.

]

{ #category : #helpers }
VMCogBytecodeTest >> pushAddress: anInteger [

	| aByteArray |
	aByteArray := ByteArray new: self wordSize.
	aByteArray integerAt: 1 put: anInteger size: self wordSize signed: false.
	self push: aByteArray
]

{ #category : #'helpers - registers' }
VMCogBytecodeTest >> readRegister: aRegisterID [

	registerValue := ByteArray new: self wordSize.
	unicorn register: aRegisterID value readInto: registerValue.
	^ registerValue integerAt: 1 size: self wordSize signed: false
]

{ #category : #'helpers - registers' }
VMCogBytecodeTest >> returnValue [

	^ self readRegister: UcX86Registers rdx
]

{ #category : #helpers }
VMCogBytecodeTest >> runGeneratedCode [

	unicorn startAt: 16r1000000
		until: 16r1000000 + lastAddress - 1
		timeout: 0
		count: 0.

]

{ #category : #helpers }
VMCogBytecodeTest >> runUntilReturn [

	unicorn startAt: 16r1000000
		until: callerAddress
		timeout: 0
		count: 0.

]

{ #category : #running }
VMCogBytecodeTest >> setUp [

	super setUp.
	
	cogit := SimpleStackBasedCogit new setInterpreter: memory coInterpreter.
	memory nilObject: 24.
	memory hiddenRootsObject: 100.
	
	cogit methodZone manageFrom: 0 to: 23.

	"We initialize the internal Cogit state by hand because we don't have a method to cog"	
	cogit methodOrBlockNumArgs: 0.
"	cogit methodOrBlockNumTemps: 0.
	cogit initSimStackForFramelessMethod: 1".
	cogit needsFrame: false.
	cogit inBlock: 0.
"	cogit regArgsHaveBeenPushed: false".
	
	"Initializing Unicorn with 2MB memory and a stack at the end"
	
	unicorn := Unicorn x8664.
	unicorn
		mapMemoryOfSize: 2 * 1024 * 1024
		atAddress: 16r1000000
		withPermissions: UnicornConstants permissionAll.
			
	unicorn register: UcX86Registers rsp value write:  #[8 0 31 1 0 0 0 0]. 
	callerAddress := 16r11E0000.
	self pushAddress: callerAddress.	
	
	unicorn 
		registerInvalidMemoryAccessHook: UcHookType invalidMemoryAccess value 
		doing: [ :type :address :size :value | self halt.].

	

]

{ #category : #tests }
VMCogBytecodeTest >> testPushNil [
	
	1halt.
	self compile: [ cogit genPushConstantNilBytecode ] opcodes: 1.	
	self runGeneratedCode.
	
	self assert: (self popAddress) equals: 24
]

{ #category : #tests }
VMCogBytecodeTest >> testPushNilAndThenReturn [
	
	self compile: [ 
		cogit genPushConstantNilBytecode.
		cogit genReturnTopFromMethod ] opcodes: 2 bytecodes: 2.	
	self runGeneratedCode.
	
	self assert: (self returnValue) equals: 24
]

{ #category : #tests }
VMCogBytecodeTest >> testReturnNilLeavesNilInReturnRegister [

	self compile: [ cogit genReturnNil ] opcodes: 2.	
	self runUntilReturn.

	self assert: self returnValue equals: 24
]

{ #category : #tests }
VMCogBytecodeTest >> testReturnNilReturnsToCaller [

	self compile: [ cogit genReturnNil ] opcodes: 2.	
	self runUntilReturn.

	self assert: self instructionPointer equals: callerAddress
]

{ #category : #helpers }
VMCogBytecodeTest >> wordSize [
	
	^ memory wordSize
]
