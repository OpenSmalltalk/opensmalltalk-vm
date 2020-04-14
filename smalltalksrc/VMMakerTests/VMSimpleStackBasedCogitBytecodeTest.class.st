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
		'opcodes'
	],
	#category : #VMMakerTests
}

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> compile: aBlockClosure [ 

	^ self compile: aBlockClosure bytecodes: 1
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> compile: aBlockClosure bytecodes: bytecodes [

	"We estimate the same ammount of bytecode as the Cogit"
	cogit allocateOpcodes: (bytecodes + 10) * 10 bytecodes: bytecodes ifFail: [ self fail ].
	cogit zeroOpcodeIndex.
	
	aBlockClosure value.

	cogit methodLabel address: 0.
	cogit computeMaximumSizes.
	
	codeSize := cogit generateInstructionsAt: initialAddress "methodLabel address + headerSize?".
	cogit methodZone allocate: codeSize.
	lastAddress := cogit outputInstructionsAt: initialAddress.

	opcodes := cogit getOpcodeIndex
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> disassemble [
	
	^ LLVMDisassembler amd64 
		disassembleNext: opcodes
		instructionsIn: (memory memory memoryObject copyFrom: 1 to: 24) asByteArray pc: 0
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitBytecodeTest >> instructionPointer [

	^ self readRegister: UcX86Registers rip
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> newInterpreter [

	^ CogVMSimulator newWithOptions: {#BytesPerWord . 8}
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> newMemory [

	^ Spur64BitMMLECoSimulator new
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> pop [

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
VMSimpleStackBasedCogitBytecodeTest >> popAddress [
	
	^ self pop integerAt: 1 size: self wordSize signed: false
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> push: aByteArray [

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
VMSimpleStackBasedCogitBytecodeTest >> pushAddress: anInteger [

	| aByteArray |
	aByteArray := ByteArray new: self wordSize.
	aByteArray integerAt: 1 put: anInteger size: self wordSize signed: false.
	self push: aByteArray
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitBytecodeTest >> readRegister: aRegisterID [

	registerValue := ByteArray new: self wordSize.
	unicorn register: aRegisterID value readInto: registerValue.
	^ registerValue integerAt: 1 size: self wordSize signed: false
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

{ #category : #running }
VMSimpleStackBasedCogitBytecodeTest >> setUp [

	| stackValueBytes |
	super setUp.
	
	cogit := SimpleStackBasedCogit new setInterpreter: memory coInterpreter.
	memory nilObject: 24.
	memory trueObject: 40.
	memory falseObject: 56.
	
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
	memory memory memoryObject pinInMemory.
	unicorn
		mapHostMemory: memory memory memoryObject
		atAddress: initialAddress
		withPermissions: UnicornConstants permissionAll.

	"Put whatever caller address for now. This is not okeish but it lets tests run for now.
	We should refine these when we properly test returns and sends."
	callerAddress := initialAddress + memory memory size - 24.
	self writeRegister: UcX86Registers rsp value: callerAddress.
	stackValueBytes := ByteArray new: self wordSize.
	stackValueBytes
		integerAt: 1 put: callerAddress
		size: self wordSize
		signed: false.
	unicorn
		memoryAt: callerAddress
		write: stackValueBytes
		size: self wordSize.
	self pushAddress: callerAddress.
	
	unicorn 
		registerInvalidMemoryAccessHook: UcHookType invalidMemoryAccess value 
		doing: [ :type :address :size :value | self halt.].

	

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
	
	self assert: (self returnValue) equals: memory nilObject
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

	self receiverRegister: 75. 
	
	self compile: [ cogit genPushReceiverBytecode ].	
	self runGeneratedCode.
	
	self assert: (self popAddress) equals: 75
]

{ #category : #'tests - single bytecode' }
VMSimpleStackBasedCogitBytecodeTest >> testPushReceiverVariableBytecodeZeroPushesFirstVariable [

	| obj |
	cogit byte0: 0.
	
	obj := self newObjectWithSlots: 1.
	
	self receiverRegister: obj.
	memory storePointer: 0 ofObject: obj withValue: memory falseObject.
	
	self compile: [ cogit genPushReceiverVariableBytecode ].	
	self runGeneratedCode.

	self assert: self popAddress equals: memory falseObject
]

{ #category : #'tests - single bytecode' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnNilLeavesNilInReturnRegister [

	self compile: [ cogit genReturnNil ].	
	self runUntilReturn.

	self assert: self returnValue equals: 24
]

{ #category : #'tests - single bytecode' }
VMSimpleStackBasedCogitBytecodeTest >> testReturnNilReturnsToCaller [

	self compile: [ cogit genReturnNil ].	
	self runUntilReturn.

	self assert: self instructionPointer equals: callerAddress
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> wordSize [
	
	^ memory wordSize
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitBytecodeTest >> writeRegister: anUcX86Registers value: anInteger [ 

	| value |
	value := ByteArray new: self wordSize.
	value integerAt: 1 put: anInteger size: self wordSize signed: false.
	unicorn register: anUcX86Registers value write: value.

]
