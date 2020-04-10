Class {
	#name : #VMCogBytecodeTest,
	#superclass : #VMSpurMemoryManagerTest,
	#instVars : [
		'cogit',
		'codeSize',
		'lastAddress',
		'unicorn',
		'rdxValue'
	],
	#category : #VMMakerTests
}

{ #category : #helpers }
VMCogBytecodeTest >> newInterpreter [

	^ CogVMSimulator newWithOptions: {#BytesPerWord . 8}
]

{ #category : #helpers }
VMCogBytecodeTest >> newMemory [

	^ Spur64BitMMLECoSimulator new
]

{ #category : #running }
VMCogBytecodeTest >> setUp [

	super setUp.
	
	cogit := StackToRegisterMappingCogit new setInterpreter: memory coInterpreter.
	memory nilObject: 24.
	memory hiddenRootsObject: 100.
	
	cogit methodZone manageFrom: 0 to: 23.

	"We initialize the internal Cogit state by hand because we don't have a method to cog"	
	cogit methodOrBlockNumArgs: 0.
	cogit methodOrBlockNumTemps: 0.
	cogit initSimStackForFramelessMethod: 1.
	cogit needsFrame: false.
	cogit inBlock: 0.
	cogit regArgsHaveBeenPushed: false.
	
	"Initializing Unicorn with 2MB memory and a stack at the end"
	
	unicorn := Unicorn x8664.
	unicorn
		mapMemoryOfSize: 2 * 1024 * 1024
		atAddress: 16r1000000
		withPermissions: UnicornConstants permissionAll.
			
	unicorn register: UcX86Registers rsp value write:  #[8 0 31 1 0 0 0 0]. 
	
	unicorn 
		registerInvalidMemoryAccessHook: UcHookType invalidMemoryAccess value 
		doing: [ :type :address :size :value | self halt.].

	

]

{ #category : #tests }
VMCogBytecodeTest >> testPushNil [

	| cogit codeSize |
	cogit := StackToRegisterMappingCogit new setInterpreter: memory coInterpreter.
	memory nilObject: 24.
	memory hiddenRootsObject: 100.

	"We initialize the internal Cogit state by hand because we don't have a method to cog"	
	cogit methodOrBlockNumArgs: 0.
	cogit methodOrBlockNumTemps: 0.
	cogit initSimStackForFramelessMethod: 1.
	cogit needsFrame: false.
	cogit inBlock: 0.
	cogit regArgsHaveBeenPushed: false.
	
	cogit allocateOpcodes: 1 bytecodes: 1 ifFail: [ self fail ].
	cogit zeroOpcodeIndex.
	
	cogit genPushConstantNilBytecode.

	cogit methodLabel address: 0.
	cogit computeMaximumSizes.
	
	codeSize := cogit generateInstructionsAt: 0 "methodLabel address + headerSize?".
	1halt.
]

{ #category : #tests }
VMCogBytecodeTest >> testReturnNilLeavesNilInReturnRegister [

	| cogit codeSize lastAddress unicorn rdxValue |
	cogit := StackToRegisterMappingCogit new setInterpreter: memory coInterpreter.
	memory nilObject: 24.
	memory hiddenRootsObject: 100.
	
	cogit methodZone manageFrom: 0 to: 23.

	"We initialize the internal Cogit state by hand because we don't have a method to cog"	
	cogit methodOrBlockNumArgs: 0.
	cogit methodOrBlockNumTemps: 0.
	cogit initSimStackForFramelessMethod: 1.
	cogit needsFrame: false.
	cogit inBlock: 0.
	cogit regArgsHaveBeenPushed: false.
	
	cogit allocateOpcodes: 2 bytecodes: 1 ifFail: [ self fail ].
	cogit zeroOpcodeIndex.
	
	cogit genReturnNil .

	cogit methodLabel address: 0.
	cogit computeMaximumSizes.
	
	codeSize := cogit generateInstructionsAt: 0 "methodLabel address + headerSize?".
	cogit methodZone allocate: codeSize.
	lastAddress := cogit outputInstructionsAt: 0.
	
	unicorn := Unicorn x8664.
	unicorn
		mapMemoryOfSize: 2 * 1024 * 1024
		atAddress: 16r1000000
		withPermissions: UnicornConstants permissionAll.
	
	unicorn
		memoryAt: 16r1000000
		write: memory memory asByteArray
		size: lastAddress.
	
	unicorn startAt: 16r1000000
		until: 16r1000000 + lastAddress - 1
		timeout: 0
		count: 0.
	
	rdxValue := #[ 0 0 0 0 0 0 0 0].
	unicorn register: UcX86Registers rdx value readInto: rdxValue.
	self assert: (rdxValue longAt: 1) equals: 24
]

{ #category : #tests }
VMCogBytecodeTest >> testReturnNilReturnsToCaller [

	cogit allocateOpcodes: 2 bytecodes: 1 ifFail: [ self fail ].
	cogit zeroOpcodeIndex.
	
	cogit genReturnNil .

	cogit methodLabel address: 0.
	cogit computeMaximumSizes.
	
	codeSize := cogit generateInstructionsAt: 0 "methodLabel address + headerSize?".
	cogit methodZone allocate: codeSize.
	lastAddress := cogit outputInstructionsAt: 0.
	
	unicorn register: UcX86Registers rsp value write:  #[0 0 31 1 0 0 0 0]. 
	unicorn
		memoryAt: 16r11F0000
		write:  #[0 0 30 1 0 0 0 0]
		size: 8.

	"Install the code in the memory"
	unicorn
		memoryAt: 16r1000000
		write: memory memory asByteArray
		size: lastAddress.
	
	unicorn startAt: 16r1000000
		until: 16r11E0000
		timeout: 0
		count: 0.

	rdxValue := #[ 0 0 0 0 0 0 0 0].
	unicorn register: UcX86Registers rip value readInto: rdxValue.
	self assert: (rdxValue longAt: 1) equals: 16r11E0000
]
