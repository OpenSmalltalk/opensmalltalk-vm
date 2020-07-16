Class {
	#name : #VMPushThisContextRoutineTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#category : #VMMakerTests
}

{ #category : #tests }
VMPushThisContextRoutineTest >> testMarriedContextReturnsSpouse [

	| isLargeContext isInBlock routine numberOfArguments methodObject callingAddress contextOop |
	isLargeContext := false.
	isInBlock := 0 "non-block, i.e., a normal method".
	callingAddress := self compile: [ cogit Stop ].
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	contextOop := memory integerObjectOf: 42.
	methodObject := self newMethodWithSmallContext: false WithArguments: numberOfArguments.
	self machineCodeFrameBuilder
		spouseContext: contextOop;
		arguments: { 
			memory integerObjectOf: 1.
			memory integerObjectOf: 2.
			memory integerObjectOf: 3. };
		temporaries: { 
			memory integerObjectOf: 4.
			memory integerObjectOf: 5.
			memory integerObjectOf: 6.
			memory integerObjectOf: 7. };
		buildFrame.

	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.
	self pushAddress: callingAddress.
	self runFrom: routine until: callingAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: contextOop
]

{ #category : #tests }
VMPushThisContextRoutineTest >> testNewMarriedContextHasLargeSize [

	| isLargeContext isInBlock routine numberOfArguments methodObject callingAddress contextOop finishedSimulation |
	isLargeContext := true.
	isInBlock := 0 "non-block, i.e., a normal method".
	callingAddress := self compile: [ cogit Stop ].
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	contextOop := memory integerObjectOf: 42.
	methodObject := self newMethodWithSmallContext: false WithArguments: numberOfArguments.
	self machineCodeFrameBuilder
		arguments: { 
			memory integerObjectOf: 1.
			memory integerObjectOf: 2.
			memory integerObjectOf: 3. };
		temporaries: { 
			memory integerObjectOf: 4.
			memory integerObjectOf: 5.
			memory integerObjectOf: 6.
			memory integerObjectOf: 7. };
		buildFrame.

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.
	self pushAddress: callingAddress.

	machineSimulator instructionPointerValue: routine.
	finishedSimulation := false.
	[ finishedSimulation ] whileFalse: [
		[ self runFrom: machineSimulator instructionPointerValue until: callingAddress.
			finishedSimulation := callingAddress = machineSimulator instructionPointerValue ]
			on: UnicornInvalidMemoryAccess do: [ :invalidAccess |
				cogit handleSimulationTrap: (UnicornSimulationTrap simulator: machineSimulator error: invalidAccess) ] ].
	
	self assert: (memory numSlotsOf: machineSimulator receiverRegisterValue) equals: LargeContextSlots
]

{ #category : #tests }
VMPushThisContextRoutineTest >> testNewMarriedContextHasSmallSize [

	| isLargeContext isInBlock routine numberOfArguments methodObject callingAddress contextOop finishedSimulation |
	isLargeContext := false.
	isInBlock := 0 "non-block, i.e., a normal method".
	callingAddress := self compile: [ cogit Stop ].
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	contextOop := memory integerObjectOf: 42.
	methodObject := self newMethodWithSmallContext: false WithArguments: numberOfArguments.
	self machineCodeFrameBuilder
		arguments: { 
			memory integerObjectOf: 1.
			memory integerObjectOf: 2.
			memory integerObjectOf: 3. };
		temporaries: { 
			memory integerObjectOf: 4.
			memory integerObjectOf: 5.
			memory integerObjectOf: 6.
			memory integerObjectOf: 7. };
		buildFrame.

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.
	self pushAddress: callingAddress.

	machineSimulator instructionPointerValue: routine.
	finishedSimulation := false.
	[ finishedSimulation ] whileFalse: [
		[ self runFrom: machineSimulator instructionPointerValue until: callingAddress.
			finishedSimulation := callingAddress = machineSimulator instructionPointerValue ]
			on: UnicornInvalidMemoryAccess do: [ :invalidAccess |
				cogit handleSimulationTrap: (UnicornSimulationTrap simulator: machineSimulator error: invalidAccess) ] ].
	
	self assert: (memory numSlotsOf: machineSimulator receiverRegisterValue) equals: SmallContextSlots
]

{ #category : #tests }
VMPushThisContextRoutineTest >> testSingleContextReturnsNewSpouseInNewSpace [

	| isLargeContext isInBlock routine numberOfArguments methodObject callingAddress contextOop finishedSimulation |
	isLargeContext := false.
	isInBlock := 0 "non-block, i.e., a normal method".
	callingAddress := self compile: [ cogit Stop ].
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	contextOop := memory integerObjectOf: 42.
	methodObject := self newMethodWithSmallContext: false WithArguments: numberOfArguments.
	self machineCodeFrameBuilder
		arguments: { 
			memory integerObjectOf: 1.
			memory integerObjectOf: 2.
			memory integerObjectOf: 3. };
		temporaries: { 
			memory integerObjectOf: 4.
			memory integerObjectOf: 5.
			memory integerObjectOf: 6.
			memory integerObjectOf: 7. };
		buildFrame.

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.
	self pushAddress: callingAddress.

	machineSimulator instructionPointerValue: routine.
	finishedSimulation := false.
	[ finishedSimulation ] whileFalse: [
		[ self runFrom: machineSimulator instructionPointerValue until: callingAddress.
			finishedSimulation := callingAddress = machineSimulator instructionPointerValue ]
			on: UnicornInvalidMemoryAccess do: [ :invalidAccess |
				cogit handleSimulationTrap: (UnicornSimulationTrap simulator: machineSimulator error: invalidAccess) ] ].
	
	self assert: (memory isYoung: machineSimulator receiverRegisterValue)
]
