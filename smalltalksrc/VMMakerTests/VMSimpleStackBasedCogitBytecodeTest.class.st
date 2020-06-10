Class {
	#name : #VMSimpleStackBasedCogitBytecodeTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#category : #VMMakerTests
}

{ #category : #'tests - extended store bytecode - store inst var' }
VMSimpleStackBasedCogitBytecodeTest >> doExtendedStoreStoresInstanceVariableIndex: instanceVariableToWrite [

	"Create an object with at least `instanceVariableToWrite` instance variables.
	In memory, instance variables are 0-indexed so substract 1"
	obj := self newObjectWithSlots: instanceVariableToWrite.
	
	"The receiver should be in a receiver register based on Cog's calling convention"
	machineSimulator receiverRegisterValue: obj.

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
	machineSimulator receiverRegisterValue: obj.

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

	self assert: machineSimulator returnRegisterValue equals: anAddress
]

{ #category : #'tests - single bytecode - return' }
VMSimpleStackBasedCogitBytecodeTest >> doTestReturnReturnsToCallerWithFrame: isFrameful onBlock: compilationBlock [

	isFrameful 
		ifTrue: [self createFramefulCallFrom: callerAddress]
		ifFalse: [self createFramelessCallFrom: callerAddress].		
	
	self compile: compilationBlock.	
	self runUntilReturn.

	self assert: machineSimulator instructionPointerValue equals: callerAddress
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
	machineSimulator receiverRegisterValue: obj.
	
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

{ #category : #'tests - jumps' }
VMSimpleStackBasedCogitBytecodeTest >> testJumpForwardJumpsOverAnInstruction [
	
	cogit methodObj: (self newMethodWithBytecodes: #[144 122 121]).
	
	self compile: [ | fixup nextOpcodeIndex |
		cogit byte0: 144.
		cogit bytecodePC: 8. "The method has a header so, the first bytecode is in offset 8"
		cogit genShortUnconditionalJump.  
		
		cogit byte0: 122.
		cogit bytecodePC: 9.
		cogit genReturnFalse.
		
		cogit byte0: 121.
		cogit bytecodePC: 10. 
		"We need to store the value to know if the bytecode has generated instructions"
		nextOpcodeIndex := cogit getOpcodeIndex.
		cogit genReturnTrue.
		"As the bytecode is the target of a jump it has a fixup. We need to process it"
		fixup := cogit fixupAt: 10.
		cogit patchFixupTargetIfNeeded: fixup nextOpcodeIndex: nextOpcodeIndex. ] bytecodes: 3.	

	self runGeneratedCode.
	
	self assert: machineSimulator receiverRegisterValue equals: memory trueObject
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
	
	self assert: machineSimulator receiverRegisterValue equals: memory nilObject
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

	machineSimulator receiverRegisterValue: 75. 
	
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
	machineSimulator receiverRegisterValue: obj.
	
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

	self assert: (self readMemoryAt: machineSimulator stackPointerRegisterValue) equals: memory falseObject.
	
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

{ #category : #'tests - thisContext' }
VMSimpleStackBasedCogitBytecodeTest >> testPushThisContextForFullBlockWithFullFrameCallsLargeFullBlockTrampoline [

	| numberOfArguments methodObject method |
	
	cogit ceLargeActiveContextInFullBlockTrampoline: (self compile: [ cogit RetN: 0 ]).
	
	self 
		createFramefulCallFrom: callerAddress 
		receiver: memory nilObject
		arguments: { memory falseObject . memory trueObject . memory falseObject }
		temporaries: #().
	numberOfArguments := 3.
	methodObject := self newMethodWithSmallContext: false WithArguments: numberOfArguments.
	method := self compile: [
		cogit inBlock: InFullBlock.
		cogit methodOrBlockNumArgs: numberOfArguments.
		cogit methodObj: methodObject.
		cogit genPushActiveContextBytecode ].
	
	self runFrom: method until: cogit ceLargeActiveContextInFullBlockTrampoline.
	
	self assert: machineSimulator instructionPointerValue equals: cogit ceLargeActiveContextInFullBlockTrampoline.
	self assert: machineSimulator sendNumberOfArgumentsRegisterValue equals: numberOfArguments.
]

{ #category : #'tests - thisContext' }
VMSimpleStackBasedCogitBytecodeTest >> testPushThisContextForFullBlockWithSmallFrameCallsLargeFullBlockTrampoline [

	| numberOfArguments methodObject method |
	
	cogit ceSmallActiveContextInFullBlockTrampoline: (self compile: [ cogit RetN: 0 ]).
	
	self 
		createFramefulCallFrom: callerAddress 
		receiver: memory nilObject
		arguments: { memory falseObject . memory trueObject . memory falseObject }
		temporaries: #().
	numberOfArguments := 3.
	methodObject := self newMethodWithSmallContext: true WithArguments: numberOfArguments.
	method := self compile: [
		cogit inBlock: InFullBlock.
		cogit methodOrBlockNumArgs: numberOfArguments.
		cogit methodObj: methodObject.
		cogit genPushActiveContextBytecode ].
	
	self runFrom: method until: cogit ceSmallActiveContextInFullBlockTrampoline.
	
	self assert: machineSimulator instructionPointerValue equals: cogit ceSmallActiveContextInFullBlockTrampoline.
	self assert: machineSimulator sendNumberOfArgumentsRegisterValue equals: numberOfArguments.
]

{ #category : #'tests - thisContext' }
VMSimpleStackBasedCogitBytecodeTest >> testPushThisContextForMethodWithLargeFrameCallsLargeMethodTrampoline [

	| numberOfArguments methodObject method |
	
	cogit ceLargeActiveContextInMethodTrampoline: (self compile: [ cogit RetN: 0 ]).
	
	self 
		createFramefulCallFrom: callerAddress 
		receiver: memory nilObject
		arguments: { memory falseObject . memory trueObject . memory falseObject }
		temporaries: #().
	numberOfArguments := 3.
	methodObject := self newMethodWithSmallContext: false WithArguments: numberOfArguments.
	method := self compile: [ 
		cogit methodOrBlockNumArgs: numberOfArguments.
		cogit methodObj: methodObject.
		cogit genPushActiveContextBytecode ].
	
	self runFrom: method until: cogit ceLargeActiveContextInMethodTrampoline.
	
	self assert: machineSimulator instructionPointerValue equals: cogit ceLargeActiveContextInMethodTrampoline.
	self assert: machineSimulator sendNumberOfArgumentsRegisterValue equals: numberOfArguments.
]

{ #category : #'tests - thisContext' }
VMSimpleStackBasedCogitBytecodeTest >> testPushThisContextForMethodWithSmallFrameCallsSmallMethodTrampoline [

	| numberOfArguments methodObject method |
	
	cogit ceSmallActiveContextInMethodTrampoline: (self compile: [ cogit RetN: 0 ]).
	
	self 
		createFramefulCallFrom: callerAddress 
		receiver: memory nilObject
		arguments: { memory falseObject . memory trueObject . memory falseObject }
		temporaries: #().
	numberOfArguments := 3.
	methodObject := self newMethodWithSmallContext: true WithArguments: numberOfArguments.
	method := self compile: [ 
		cogit methodOrBlockNumArgs: numberOfArguments.
		cogit methodObj: methodObject.
		cogit genPushActiveContextBytecode ].
	
	self runFrom: method until: cogit ceSmallActiveContextInMethodTrampoline.
	
	self assert: machineSimulator instructionPointerValue equals: cogit ceSmallActiveContextInMethodTrampoline.
	self assert: machineSimulator sendNumberOfArgumentsRegisterValue equals: numberOfArguments.
]

{ #category : #'tests - thisContext' }
VMSimpleStackBasedCogitBytecodeTest >> testPushThisContextForVanillaBlockWithLargeFrameCallsLargeVanillaBlockTrampoline [

	| numberOfArguments methodObject method |
	
	cogit ceLargeActiveContextInBlockTrampoline: (self compile: [ cogit RetN: 0 ]).
	
	self 
		createFramefulCallFrom: callerAddress 
		receiver: memory nilObject
		arguments: { memory falseObject . memory trueObject . memory falseObject }
		temporaries: #().
	numberOfArguments := 3.
	methodObject := self newMethodWithSmallContext: false WithArguments: numberOfArguments.
	method := self compile: [
		cogit inBlock: InVanillaBlock.
		cogit methodOrBlockNumArgs: numberOfArguments.
		cogit methodObj: methodObject.
		cogit genPushActiveContextBytecode ].
	
	self runFrom: method until: cogit ceLargeActiveContextInBlockTrampoline.
	
	self assert: machineSimulator instructionPointerValue equals: cogit ceLargeActiveContextInBlockTrampoline.
	self assert: machineSimulator sendNumberOfArgumentsRegisterValue equals: numberOfArguments.
]

{ #category : #'tests - thisContext' }
VMSimpleStackBasedCogitBytecodeTest >> testPushThisContextForVanillaBlockWithSmallFrameCallsLargeVanillaBlockTrampoline [

	| numberOfArguments methodObject method |
	
	cogit ceSmallActiveContextInBlockTrampoline: (self compile: [ cogit RetN: 0 ]).
	
	self 
		createFramefulCallFrom: callerAddress 
		receiver: memory nilObject
		arguments: { memory falseObject . memory trueObject . memory falseObject }
		temporaries: #().
	numberOfArguments := 3.
	methodObject := self newMethodWithSmallContext: true WithArguments: numberOfArguments.
	method := self compile: [
		cogit inBlock: InVanillaBlock.
		cogit methodOrBlockNumArgs: numberOfArguments.
		cogit methodObj: methodObject.
		cogit genPushActiveContextBytecode ].
	
	self runFrom: method until: cogit ceSmallActiveContextInBlockTrampoline.
	
	self assert: machineSimulator instructionPointerValue equals: cogit ceSmallActiveContextInBlockTrampoline.
	self assert: machineSimulator sendNumberOfArgumentsRegisterValue equals: numberOfArguments.
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
	self runFrom: sendAddress until: self getLastAddress.		
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
	self runFrom: sendAddress until: self getLastAddress.
	
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
		assert: machineSimulator classRegisterValue
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
		assert: machineSimulator classRegisterValue
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
	
	self assert: machineSimulator receiverRegisterValue equals: memory falseObject
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
		assert: machineSimulator classRegisterValue
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
		assert: machineSimulator classRegisterValue
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
	machineSimulator returnRegisterValue: (memory integerObjectOf: 42).
	self runFrom: machineSimulator instructionPointerValue until: self getLastAddress.
	
	self assert: self popAddress equals: (memory integerObjectOf: 42).
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendNotEqualsEqualsWithIdenticalObjectsPushesFalse [

	sendAddress := self compile: [ cogit genSpecialSelectorNotEqualsEquals ].
	
	"Push receiver, arg then send"
	self pushAddress: memory nilObject.
	self pushAddress: memory nilObject.
	self runFrom: sendAddress until: self getLastAddress.
	
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
	self runFrom: sendAddress until: self getLastAddress.
	
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
	
	machineSimulator sendNumberOfArgumentsRegisterValue: (previousValue := 42).
	
	"Push receiver, arg, then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self
		assert: machineSimulator sendNumberOfArgumentsRegisterValue
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
			a integerAt: 1 put: machineSimulator classRegisterValue size: self wordSize signed: false.
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
	
	self assert: machineSimulator receiverRegisterValue equals: memory falseObject
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
		assert: machineSimulator classRegisterValue
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
	machineSimulator returnRegisterValue: (memory integerObjectOf: 42).
	self runFrom: machineSimulator instructionPointerValue until: self getLastAddress.
	
	self assert: self popAddress equals: (memory integerObjectOf: 42).
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendTwoArgSpecialMessageDoesNotMovesIntoSendNumArgsRegister [
	
	| previousValue |
	sentSelector := #at:put:.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	machineSimulator sendNumberOfArgumentsRegisterValue: (previousValue := 42).
	
	"Push receiver, arg1, arg2 then send"
	self pushAddress: memory falseObject.
	self pushAddress: memory trueObject.
	self pushAddress: (memory integerObjectOf: 7).
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self
		assert: machineSimulator sendNumberOfArgumentsRegisterValue
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
			a integerAt: 1 put: machineSimulator classRegisterValue size: self wordSize signed: false.
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
	
	self assert: machineSimulator receiverRegisterValue equals: memory falseObject
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
			a integerAt: 1 put: machineSimulator classRegisterValue size: self wordSize signed: false.
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
	machineSimulator returnRegisterValue: (memory integerObjectOf: 42).
	self runFrom: machineSimulator instructionPointerValue until: self getLastAddress.
	
	self assert: self popAddress equals: (memory integerObjectOf: 42).
]

{ #category : #'tests - special sends' }
VMSimpleStackBasedCogitBytecodeTest >> testSendZeroArgSpecialMessageDoesNotMovesIntoSendNumArgsRegister [
	
	| previousValue |
	sentSelector := #atEnd.
	self createSpecialSelectorArray.
	self compileSpecialSend.
	
	machineSimulator sendNumberOfArgumentsRegisterValue: (previousValue := 42).
	
	"Push receiver, then send"
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	self
		assert: machineSimulator sendNumberOfArgumentsRegisterValue
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
			a integerAt: 1 put: machineSimulator classRegisterValue size: self wordSize signed: false.
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
	
	self assert: machineSimulator receiverRegisterValue equals: memory falseObject
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
		assert: machineSimulator classRegisterValue
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
	machineSimulator returnRegisterValue: (memory integerObjectOf: 42).
	self runFrom: machineSimulator instructionPointerValue until: self getLastAddress.
	
	self assert: self popAddress equals: (memory integerObjectOf: 42).
]
