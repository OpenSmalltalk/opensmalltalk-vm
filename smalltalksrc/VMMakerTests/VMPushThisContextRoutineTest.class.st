Class {
	#name : #VMPushThisContextRoutineTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#pools : [
		'VMSqueakClassIndices'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #tests }
VMPushThisContextRoutineTest >> setUp [

	| contextClass |

	super setUp.

	contextClass := self
		newClassInOldSpaceWithSlots: Context allSlots size
		instSpec: Context instSpec.
		
	memory setHashBitsOf: contextClass to: ClassMethodContextCompactIndex.
		
	memory
		storePointer: ClassMethodContextCompactIndex
		ofObject: memory classTableFirstPage
		withValue: contextClass

]

{ #category : #tests }
VMPushThisContextRoutineTest >> testMarriedContextReturnsSpouseObject [

	| isLargeContext isInBlock routine numberOfArguments methodObject contextOop |
	isLargeContext := false.
	isInBlock := 0 "non-block, i.e., a normal method".
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	numberOfArguments := 3.
	contextOop := memory integerObjectOf: 42.

	methodObject := methodBuilder newMethod 
		isSmall: false;
		numberOfArguments: numberOfArguments;
		buildMethod.

	self machineCodeFrameBuilder
		returnAddress: callerAddress;
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
		
	"Push the address of the caller of the routine"
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.
	self prepareCall.
	self runFrom: routine until: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: contextOop
]

{ #category : #tests }
VMPushThisContextRoutineTest >> testNewMarriedContextHasLargeSize [

	| isLargeContext isInBlock routine numberOfArguments |
	isLargeContext := true.
	isInBlock := 0 "non-block, i.e., a normal method".
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	self machineCodeFrameBuilder
		returnAddress: callerAddress;
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
		
	"Push the address of the caller of the routine"
	self prepareCall.
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.

	self runFrom: routine until: callerAddress.	

	self assert: (memory numSlotsOf: machineSimulator receiverRegisterValue) equals: LargeContextSlots.
]

{ #category : #tests }
VMPushThisContextRoutineTest >> testNewMarriedContextHasSmallSize [

	| isLargeContext isInBlock routine numberOfArguments |
	isLargeContext := false.
	isInBlock := 0 "non-block, i.e., a normal method".
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	self machineCodeFrameBuilder
		returnAddress: callerAddress;
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

	"Push the address of the caller of the routine"
	cogit backend hasLinkRegister
		ifFalse: [ self pushAddress: callerAddress ].

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.
	
	self runFrom: routine until: callerAddress.	
	
	self assert: (memory numSlotsOf: machineSimulator receiverRegisterValue) equals: SmallContextSlots
]

{ #category : #tests }
VMPushThisContextRoutineTest >> testNewMarriedLargeContextHasCorrectStackPointer [

	| isLargeContext isInBlock routine numberOfArguments expectedStackPointer |
	isLargeContext := true.
	isInBlock := 0 "non-block, i.e., a normal method".
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	self machineCodeFrameBuilder
		returnAddress: callerAddress;
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
		
	"Push the address of the caller of the routine"
	cogit backend hasLinkRegister
		ifFalse: [ self pushAddress: callerAddress ].

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.

	self runFrom: routine until: callerAddress.	
	
	expectedStackPointer := ((machineSimulator framePointerRegisterValue - machineSimulator smalltalkStackPointerRegisterValue) / wordSize) - ( 3 "Stack elements to not count due to call convention") + 3 "num arguments".
	
	self assert: (memory fetchPointer: StackPointerIndex ofObject: machineSimulator receiverRegisterValue ) equals: (memory integerObjectOf: expectedStackPointer).
]

{ #category : #tests }
VMPushThisContextRoutineTest >> testNewMarriedSmallContextHasArguments [

	| isLargeContext isInBlock routine numberOfArguments |
	isLargeContext := false.
	isInBlock := 0 "non-block, i.e., a normal method".
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	self machineCodeFrameBuilder
		returnAddress: callerAddress;
		receiver: memory trueObject;
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
		
	"Push the address of the caller of the routine"
	self prepareCall.

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.

	self runFrom: routine until: callerAddress.	
	
	self assert: (memory fetchPointer: Context allSlots size +0 ofObject: machineSimulator receiverRegisterValue ) equals: (memory integerObjectOf: 1).
	self assert: (memory fetchPointer: Context allSlots size +1 ofObject: machineSimulator receiverRegisterValue ) equals: (memory integerObjectOf: 2).
	self assert: (memory fetchPointer: Context allSlots size +2 ofObject: machineSimulator receiverRegisterValue ) equals: (memory integerObjectOf: 3).		
]

{ #category : #tests }
VMPushThisContextRoutineTest >> testNewMarriedSmallContextHasClosureInNil [

	| isLargeContext isInBlock routine numberOfArguments |
	isLargeContext := false.
	isInBlock := 0 "non-block, i.e., a normal method".
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	self machineCodeFrameBuilder
		returnAddress: callerAddress;
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
		
	"Push the address of the caller of the routine"
	self prepareCall.

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.

	self runFrom: routine until: callerAddress.	

	self assert: (memory fetchPointer: ClosureIndex ofObject: machineSimulator receiverRegisterValue ) equals: (memory nilObject).
]

{ #category : #tests }
VMPushThisContextRoutineTest >> testNewMarriedSmallContextHasClosureInSetOne [

	| isLargeContext isInBlock routine numberOfArguments |
	isLargeContext := false.
	isInBlock := InVanillaBlock "non-block, i.e., a normal method".
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	self machineCodeFrameBuilder
		returnAddress: callerAddress;
		receiver: memory trueObject;
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
		
	"Push the address of the caller of the routine"
	self prepareCall.

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.

	self runFrom: routine until: callerAddress.	

	self assert: (memory fetchPointer: ClosureIndex ofObject: machineSimulator receiverRegisterValue ) equals: (memory trueObject).
]

{ #category : #tests }
VMPushThisContextRoutineTest >> testNewMarriedSmallContextHasCorrectStackPointer [

	| isLargeContext isInBlock routine numberOfArguments methodObject contextOop expectedStackPointer |
	isLargeContext := false.
	isInBlock := 0 "non-block, i.e., a normal method".
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	contextOop := memory integerObjectOf: 42.
	methodObject := self newMethodWithSmallContext: false WithArguments: numberOfArguments.
	self machineCodeFrameBuilder
		returnAddress: callerAddress;
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
		
	"Push the address of the caller of the routine"
	self prepareCall.

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.

	self runFrom: routine until: callerAddress.	
	
	expectedStackPointer := ((machineSimulator framePointerRegisterValue - machineSimulator smalltalkStackPointerRegisterValue) / wordSize) - ( 3 "Stack elements to not count due to call convention") + 3 "num arguments".
	
	self assert: (memory fetchPointer: StackPointerIndex ofObject: machineSimulator receiverRegisterValue ) equals: (memory integerObjectOf: expectedStackPointer).
]

{ #category : #tests }
VMPushThisContextRoutineTest >> testNewMarriedSmallContextHasReceiver [

	| isLargeContext isInBlock routine numberOfArguments |
	isLargeContext := false.
	isInBlock := 0 "non-block, i.e., a normal method".
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	self machineCodeFrameBuilder
		returnAddress: callerAddress;
		receiver: memory trueObject;
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
		
	"Push the address of the caller of the routine"
	self prepareCall.

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.

	self runFrom: routine until: callerAddress.	
	
	self assert: (memory fetchPointer: ReceiverIndex ofObject: machineSimulator receiverRegisterValue ) equals: (memory trueObject).
]

{ #category : #tests }
VMPushThisContextRoutineTest >> testNewMarriedSmallContextHasTemporaries [

	| isLargeContext isInBlock routine numberOfArguments |
	isLargeContext := false.
	isInBlock := 0 "non-block, i.e., a normal method".
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	self machineCodeFrameBuilder
		returnAddress: callerAddress;
		receiver: memory trueObject;
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
		
	"Push the address of the caller of the routine"
	self prepareCall.

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.

	self runFrom: routine until: callerAddress.	
	
	"The temporaries are not copied they are initialized in nil"
	
	self assert: (memory fetchPointer: Context allSlots size + numberOfArguments + 0 ofObject: machineSimulator receiverRegisterValue ) equals: (memory nilObject).
	self assert: (memory fetchPointer: Context allSlots size + numberOfArguments + 1 ofObject: machineSimulator receiverRegisterValue ) equals: (memory nilObject).
	self assert: (memory fetchPointer: Context allSlots size + numberOfArguments + 2 ofObject: machineSimulator receiverRegisterValue ) equals: (memory nilObject).
	self assert: (memory fetchPointer: Context allSlots size + numberOfArguments + 3 ofObject: machineSimulator receiverRegisterValue ) equals: (memory nilObject).				
]

{ #category : #tests }
VMPushThisContextRoutineTest >> testSingleContextReturnsNewSpouseInNewSpace [

	| isLargeContext isInBlock routine numberOfArguments methodObject contextOop |
	isLargeContext := false.
	isInBlock := 0 "non-block, i.e., a normal method".
	cogit objectRepresentation ceScheduleScavengeTrampoline: (self compile: [ cogit Stop ]).
	routine := self compile: [ cogit objectRepresentation genGetActiveContextLarge: isLargeContext inBlock: isInBlock ].
	
	numberOfArguments := 3.
	contextOop := memory integerObjectOf: 42.
	methodObject := self newMethodWithSmallContext: false WithArguments: numberOfArguments.
	self machineCodeFrameBuilder
		returnAddress: callerAddress;
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

	"Push the address of the caller of the routine"
	self prepareCall.

	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator sendNumberOfArgumentsRegisterValue: numberOfArguments.

	self runFrom: routine until: callerAddress.	
	
	self assert: (memory isYoung: machineSimulator receiverRegisterValue)
]
