Class {
	#name : #VMCogBytecodeTest,
	#superclass : #VMSpurMemoryManagerTest,
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
VMCogBytecodeTest >> testReturnNil [

	| cogit codeSize |
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
	cogit outputInstructionsAt: 0.
	
	1halt.
]
