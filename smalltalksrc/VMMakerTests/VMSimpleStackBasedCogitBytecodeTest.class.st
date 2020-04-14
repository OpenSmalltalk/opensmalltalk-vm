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
		'obj'
	],
	#category : #VMMakerTests
}

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> assertStackRemainsUnchangedDuring: aBlockClosure [ 
	
	| before |
	before := self stackPointerRegisterValue.
	aBlockClosure value.
	
	self
		assert: self stackPointerRegisterValue
		equals: before
]

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

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> doPopIntoReceiverVariableBytecodeStoresVariableAt: instanceVariableToWrite [

	"Create an object with at least `instanceVariableToWrite` instance variables.
	In memory, instance variables are 0-indexed so substract 1"
	obj := self newObjectWithSlots: instanceVariableToWrite.
	
	"The receiver should be in a receiver register based on Cog's calling convention"
	self receiverRegister: obj.

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

	| stackAddressIntegerValue poppedByteArray |

	"Getting address from stack register"
	stackAddressIntegerValue := self stackPointerRegisterValue.

	"Putting the value in the stack memory"
	poppedByteArray := unicorn memoryAt: stackAddressIntegerValue readNext: self wordSize.

	"Updating SP"
	self stackPointerRegisterValue: stackAddressIntegerValue.
	
	^ poppedByteArray
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> popAddress [
	
	^ self pop integerAt: 1 size: self wordSize signed: false
]

{ #category : #helpers }
VMSimpleStackBasedCogitBytecodeTest >> push: aByteArray [

	| stackAddressIntegerValue |
	self assert: aByteArray size equals: self wordSize.

	"Getting address from stack register"
	stackAddressIntegerValue := self stackPointerRegisterValue.

	"Updating SP"
	stackAddressIntegerValue := stackAddressIntegerValue - self wordSize.
	self stackPointerRegisterValue: stackAddressIntegerValue.
	
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

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitBytecodeTest >> stackPointerRegisterValue [

	^ self readRegister: UcX86Registers rsp
]

{ #category : #'helpers - registers' }
VMSimpleStackBasedCogitBytecodeTest >> stackPointerRegisterValue: aValue [
	
	self writeRegister: UcX86Registers rsp value: aValue
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

{ #category : #'tests - single bytecode - pop into inst var' }
VMSimpleStackBasedCogitBytecodeTest >> testPopIntoThirdReceiverVariableBytecodePopsValue [

	"The block pushed and then pops.
	The stack should remain unchanged after the execution"
	self assertStackRemainsUnchangedDuring: [ self doPopIntoReceiverVariableBytecodeStoresVariableAt: 3 ]
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

	| obj |	
	"Create an object with at least `instanceVariableToWrite` instance variables.
	In memory, instance variables are 0-indexed so substract 1"
	obj := self newObjectWithSlots: instanceVariableToWrite.
	memory storePointer: instanceVariableToWrite - 1 ofObject: obj withValue: memory falseObject.
	
	"The receiver should be in a receiver register based on Cog's calling convention"
	self receiverRegister: obj.
	
	"The first byte of the push receiver instance variable bytecode family is used to identify which variable (0-based again)"
	cogit byte0: instanceVariableToWrite - 1.		
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
