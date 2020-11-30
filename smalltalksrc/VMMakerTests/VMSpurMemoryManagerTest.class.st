Class {
	#name : #VMSpurMemoryManagerTest,
	#superclass : #ParametrizedTestCase,
	#instVars : [
		'newSpaceSize',
		'memory',
		'interpreter',
		'oldSpaceSize',
		'nextIndex',
		'objectHeaderSize',
		'zeroSizedObjectClassIndex',
		'emptyObjectSize',
		'initialAddress',
		'stackSpaceSize',
		'stackBuilder',
		'methodCacheSize',
		'rumpCStackSize',
		'wordSize',
		'methodBuilder',
		'v3Method'
	],
	#pools : [
		'VMBasicConstants',
		'VMBytecodeConstants',
		'VMObjectIndices',
		'VMSqueakClassIndices'
	],
	#category : #'VMMakerTests-MemoryTests'
}

{ #category : #helpers }
VMSpurMemoryManagerTest >> createActiveProcess [

	| processorOopAssociation processorOop processorListsArray priorities |

	"The ScheduleAssocation should be initialized to a valid Processor object"
	processorOopAssociation := self newObjectWithSlots: 2.
	processorOop := self newObjectWithSlots: 2.
	priorities := 2.
	processorListsArray := self newObjectWithSlots: priorities.
	1 to: priorities do: [ :index | 
		"Put an empty linked list in each"
		memory storePointer: index - 1 ofObject: processorListsArray withValue: (self newObjectWithSlots: 2) ].
	
	memory splObj: SchedulerAssociation put: processorOopAssociation.
	memory storePointer: ValueIndex ofObject: processorOopAssociation withValue: processorOop.
	memory storePointer: ProcessListsIndex ofObject: processorOop withValue: processorListsArray.

	"Create a new process with the 4 mandatory instance variables and set it as active process"
	memory storePointer: ActiveProcessIndex ofObject: processorOop withValue:  (self newObjectWithSlots: 4).

]

{ #category : #helpers }
VMSpurMemoryManagerTest >> createMethodOopFromPharoMethod: aPharoCompiledMethod [

	| methodOop |
	v3Method := aPharoCompiledMethod methodClass compiler
		            encoderClass: EncoderForV3PlusClosures;
		            options: #( - optionFullBlockClosure );
		            compile: aPharoCompiledMethod sourceCode.

	methodOop := methodBuilder
		             fillFromPharoMethod: v3Method;
		             buildMethod.
	^ methodOop
]

{ #category : #accessing }
VMSpurMemoryManagerTest >> initialCodeSize [
	^ 0
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> initializeOldSpaceForFullGC [

	| ourArrayClass |

	memory markStack: memory nilObject.
	memory weaklingStack: memory nilObject.
	
	ourArrayClass := self newObjectWithSlots: 3.
	memory
		storePointer: "InstanceSpecificationIndex" 2
		ofObject: ourArrayClass
		withValue: (memory integerObjectOf: Array format).
	memory ensureBehaviorHash: ourArrayClass.
	
	memory storePointer: 16 ofObject: memory classTableFirstPage withValue: ourArrayClass.
	memory shrinkThreshold: 0.
	memory growHeadroom: 10*1024*1024.
	
	memory flushNewSpace.
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> initializeOldSpaceForScavenger [

	| freeListOop firstClassTablePage |
	memory coInterpreter bootstrapping: true.

	"Initialize old space with free list, class table, hidden roots and remembered set to be able to scavenge"
	memory initializeFreeList.
	memory segmentManager collapseSegmentsPostSwizzle.
	memory updateFreeLists.
	memory initializeOldSpaceFirstFree: memory freeOldSpaceStart.

	"Create a nil object required to initialize several fields"
	memory nilObject: (self newOldSpaceObjectWithSlots: 0).
	"Create false object required to initialize several fields"
	memory falseObject: (self newOldSpaceObjectWithSlots: 0).
	"Create true object required to initialize several fields"
	memory trueObject: (self newOldSpaceObjectWithSlots: 0).

	"Initialize Stack"
	memory coInterpreter desiredNumStackPages: 8.
	memory coInterpreter initStackPages.

	"Initialize Special Root objects"
	memory coInterpreter method: memory nilObject.
	memory coInterpreter instructionPointer: memory nilObject.
	memory coInterpreter newMethod: memory nilObject.
	memory coInterpreter profileProcess: memory nilObject.
	memory coInterpreter profileMethod: memory nilObject.
	memory coInterpreter profileSemaphore: memory nilObject.
	memory mournQueue: memory nilObject.
	memory specialObjectsOop: memory nilObject.
		
	freeListOop := memory initializeFreeListInOldSpace: true.
	memory initializeFreeSpacePostLoad: freeListOop.
	memory computeFreeSpacePostSwizzle.
		
	memory endOfMemory: memory endOfMemory + memory bridgeSize.
	
	memory initializeOldSpaceFirstFree: (memory addressAfter: freeListOop).
	
	memory allocateClassTable.
	
	firstClassTablePage := memory fetchPointer: 0 ofObject: memory hiddenRootsObject.
	
	memory scavenger initializeRememberedSet.
	memory scavenger remember: memory hiddenRootsObject.
	memory scavenger remember: firstClassTablePage. 
	memory specialObjectsOop: (self newObjectWithSlots: 60).
	
	memory scavengingGCTenuringIf: 1.
	self deny: memory needGCFlag.
]

{ #category : #accessor }
VMSpurMemoryManagerTest >> interpreter [
	^ interpreter
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> interpreterClass [ 
	^ StackInterpreterSimulatorLSB
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> jitMethod: aPharoCompiledMethod selector: aSelectorOop [

	| methodOop |
	"We are using V3 bytecode, so we need to recompile the method"
	methodOop := self createMethodOopFromPharoMethod:
		             aPharoCompiledMethod.
	^ cogit cog: methodOop selector: aSelectorOop
]

{ #category : #tests }
VMSpurMemoryManagerTest >> keepObjectInVMVariable1: anOop [
	interpreter newMethod: anOop
]

{ #category : #tests }
VMSpurMemoryManagerTest >> keepObjectInVMVariable2: anOop [
	interpreter profileSemaphore: anOop
]

{ #category : #tests }
VMSpurMemoryManagerTest >> keepObjectInVMVariable3: anOop [
	interpreter profileMethod: anOop
]

{ #category : #tests }
VMSpurMemoryManagerTest >> keptObjectInVMVariable1 [
	^ interpreter newMethod
]

{ #category : #tests }
VMSpurMemoryManagerTest >> keptObjectInVMVariable2 [
	^ interpreter profileSemaphore
]

{ #category : #tests }
VMSpurMemoryManagerTest >> keptObjectInVMVariable3 [
	^ interpreter profileMethod
]

{ #category : #accessor }
VMSpurMemoryManagerTest >> memory [
	^ memory
]

{ #category : #'helpers - classes' }
VMSpurMemoryManagerTest >> newClassInOldSpaceWithSlots: numberOfSlots instSpec: format [
	| newClass formatWithSlots |

	newClass := memory
		allocateSlotsInOldSpace: 3
		format: memory nonIndexablePointerFormat
		classIndex: memory arrayClassIndexPun.
	
	memory storePointer: 0 ofObject: newClass withValue: memory nilObject.
	memory storePointer: 1 ofObject: newClass withValue: memory nilObject.
	
	formatWithSlots := format << 16 + numberOfSlots. 
	memory storePointer: 2 ofObject: newClass withValue: (memory integerObjectOf: formatWithSlots ).
		
	^ newClass	
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newInterpreter [
	memory := self newMemory.

	self interpreterClass
		initializeWithOptions:
			{#BytesPerWord.
			self wordSize.
			#ObjectMemory.
			memory class name}
		objectMemoryClass: memory class.

	^ self interpreterClass basicNew
		objectMemory: memory;
		basicInitialize
]

{ #category : #running }
VMSpurMemoryManagerTest >> newMemory [

	^ self wordSize = 4
		ifTrue: [ Spur32BitMemoryManager simulatorClass new ]
		ifFalse: [ Spur64BitMemoryManager simulatorClass new ]
]

{ #category : #'helpers - methods' }
VMSpurMemoryManagerTest >> newMethodWithSmallContext: isSmall WithArguments: arguments [
	
	| method methodHeader |

	"Create a bytecode compiled method object containing the given literal at the given index"
	
	method := self
		newOldSpaceObjectWithSlots: 0 "# of literals" + 1 "one extra for the header"
		format: (memory compiledMethodFormatForNumBytes: 0)
		classIndex: 16r10.
	methodHeader := (arguments bitShift: 24)
						+ (0 "nTemps" bitShift: 18)
						+ ((isSmall ifTrue: [ 0 "small frame" ] ifFalse: [ 1 "small frame" ]) bitShift: 17)
						+ 0 "number of literaps"
						+ 0 "primitive".
	memory storePointer: 0 ofObject: method withValue: (memory integerObjectOf: methodHeader).

	^ method
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newObjectWithSlots: slots [
	
	^ self newObjectWithSlots: slots classIndex: memory arrayClassIndexPun
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newObjectWithSlots: slots classIndex: anIndex [
	
	^ self newObjectWithSlots: slots format: memory arrayFormat classIndex: anIndex
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newObjectWithSlots: slots format: aFormat classIndex: anIndex [
	
	| oop |
	oop := memory
			allocateSlots: slots
			format: aFormat
			classIndex: anIndex.
	oop ifNotNil: [ memory fillObj: oop numSlots: slots with: memory nilObject ].
	^ oop
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newOldSpaceObjectWithSlots: slots [
	
	^ self newOldSpaceObjectWithSlots: slots classIndex: memory arrayClassIndexPun
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newOldSpaceObjectWithSlots: slots classIndex: anIndex [
	
	^ self
		newOldSpaceObjectWithSlots: slots
		format: memory arrayFormat
		classIndex: anIndex
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newOldSpaceObjectWithSlots: slots format: aFormat classIndex: anIndex [
	
	| oop |
	oop := memory
			allocateSlotsInOldSpace: slots
			format: aFormat
			classIndex: anIndex.
	oop ifNotNil: [ memory fillObj: oop numSlots: slots with: memory nilObject ].
	^ oop
]

{ #category : #'helpers - frames' }
VMSpurMemoryManagerTest >> newSmallContextReceiver: anOop method: aMethodOop arguments: aCollectionOfArgumentsOop temporaries: aCollectionOfTemporariesOop ip: anIp [

	| newCtx numArgs numTemps |
	newCtx := memory eeInstantiateMethodContextSlots: SmallContextSlots.

	numArgs := aCollectionOfArgumentsOop size.
	numTemps := aCollectionOfTemporariesOop size.

	memory storePointerUnchecked: SenderIndex
		ofObject: newCtx
		withValue: memory nilObject.
		
	memory storePointerUnchecked: InstructionPointerIndex
		ofObject: newCtx
		withValue: (memory integerObjectOf: anIp).

	memory storePointerUnchecked: StackPointerIndex
		ofObject: newCtx
		withValue: (memory integerObjectOf: numArgs + numTemps).
		
	memory storePointerUnchecked: MethodIndex
		ofObject: newCtx
		withValue: aMethodOop.

	memory storePointerUnchecked: ClosureIndex ofObject: newCtx withValue: memory nilObject.

	memory storePointerUnchecked: ReceiverIndex
		ofObject: newCtx
		withValue: anOop.
	
	1 to: numArgs do:
		[:i|
		memory storePointerUnchecked: ReceiverIndex + i
			ofObject: newCtx
			withValue: (aCollectionOfArgumentsOop at: i)].

	1 to: numTemps do:
			[:i|
			memory storePointerUnchecked: ReceiverIndex + i + numArgs
				ofObject: newCtx
				withValue: (aCollectionOfTemporariesOop at: i)].
	
	^ newCtx
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newString: aString [
	| vmString |
	vmString := self
		newOldSpaceObjectWithSlots: aString size
		format: memory firstByteFormat
		classIndex: ByteString hash.

	aString
		doWithIndex: [ :char :index | 
			memory
				storeByte: index - 1
				ofObject: vmString
				withValue: char asInteger ].

	^ vmString
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newZeroSizedObject [
	
	^ memory
		allocateNewSpaceSlots: 0
		format: 0 "zero sized object"
		classIndex: self zeroSizedObjectClassIndex.
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> nextOrdinaryClassIndex [
	
	^ nextIndex
		ifNil: [ nextIndex := memory classTablePageSize ]
		ifNotNil: [ nextIndex := nextIndex + 1 ]
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> primitiveTraceLogSize [
	^ 0
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> roundToPageSize: anInteger [ 

	"Unicorn simulator requires mapped memory to be multiple of 4096"
	| pageSize remainder |
	pageSize := 4096.
	remainder := anInteger \\ pageSize.
	remainder = 0 ifTrue: [ ^ anInteger ].

	^ anInteger + (pageSize - remainder)
]

{ #category : #running }
VMSpurMemoryManagerTest >> setContextClassIntoClassTable [
	| aClass |
	aClass := self
		newClassInOldSpaceWithSlots: 0
		instSpec: Array instSpec.
	memory setHashBitsOf: aClass to: ClassMethodContextCompactIndex.
	memory
		storePointer: ClassMethodContextCompactIndex
		ofObject: memory classTableFirstPage
		withValue: aClass
]

{ #category : #running }
VMSpurMemoryManagerTest >> setMethodClassIntoClassTable [
	| aClass |
	aClass := self
		newClassInOldSpaceWithSlots: 0
		instSpec: CompiledMethod instSpec.
	memory setHashBitsOf: aClass to: 16 "not necessarily ok, this is not enforced by the VM".
	memory
		storePointer: 16 "not necessarily ok, this is not enforced by the VM"
		ofObject: memory classTableFirstPage
		withValue: aClass
]

{ #category : #running }
VMSpurMemoryManagerTest >> setUp [
	super setUp.

	"100 k at least to put the class table in the old space.
	Get total size be a multiple of 4K so Unicorn CPU emulator accepts it"
	oldSpaceSize := 999 * 1024.
 	newSpaceSize := 1 * 1024.
	stackSpaceSize := 9 * 4096.
	methodCacheSize := 4096 * self wordSize.
	rumpCStackSize := 0.
	
	initialAddress := 16r1000000.
	
	objectHeaderSize := 8 "bytes. Always.".
	emptyObjectSize := objectHeaderSize + 8 "minimum required single empty slot, to use for forwarders".
	
	"Set it to bootstrapping to allow smaller memories"
	interpreter := self newInterpreter.
	memory := interpreter objectMemory.
	
	memory coInterpreter: interpreter.
	interpreter objectMemory: memory.
	
	memory bootstrapping: true.
	
	memory
		allocateMemoryOfSize: oldSpaceSize
		newSpaceSize: newSpaceSize
		stackSize: stackSpaceSize
		codeSize: self initialCodeSize
		methodCacheSize: methodCacheSize
		primitiveTraceLogSize: (self roundToPageSize: self primitiveTraceLogSize)
		rumpCStackSize: rumpCStackSize
		initialAddress: initialAddress.
	memory initializePostBootstrap.
	memory setHeapSizeAtPreviousGC.
	memory segmentManager collapseSegmentsPostSwizzle.
	
	"Schedule a GC, so it does not try to schedule one"
	memory needGCFlag: 1.
	
		methodBuilder := VMMethodBuilder new
		interpreter: interpreter; 
		memory: memory;
		yourself.

	stackBuilder := VMStackBuilder new
		interpreter: interpreter; 
		memory: memory;
		methodBuilder: methodBuilder;
		yourself.
]

{ #category : #running }
VMSpurMemoryManagerTest >> setUpScheduler [
	
	"The ScheduleAssocation should be initialized to a valid Processor object"
	| processorOopAssociation processorOop processorListArray processorListPriority1 processorListPriority2 activeProcessOop |
	processorOopAssociation := self newObjectWithSlots: 2.
	processorOop := self newObjectWithSlots: 2.
	processorListArray := self newObjectWithSlots: 2.
	
	processorListPriority1 := self newObjectWithSlots: 2.
	processorListPriority2 := self newObjectWithSlots: 2.
	
	memory storePointer: 0 ofObject: processorListArray withValue: processorListPriority1. 
	memory storePointer: 1 ofObject: processorListArray withValue: processorListPriority2.
	
	memory splObj: SchedulerAssociation put: processorOopAssociation.
	memory storePointer: ValueIndex ofObject: processorOopAssociation withValue: processorOop.
	memory storePointer: ProcessListsIndex ofObject: processorOop withValue: processorListArray.
	memory lastHash: 1.
	
	activeProcessOop := self newObjectWithSlots: 4 "Creates the active process".
	memory 
		storePointer: PriorityIndex 
		ofObject: activeProcessOop 
		withValue: (memory integerObjectOf: 0).
	
	memory memoryActiveProcess: activeProcessOop.
]

{ #category : #accessing }
VMSpurMemoryManagerTest >> sizeOfObjectWithSlots: slots [

	^ objectHeaderSize + ((slots min: 1 "at least one for the forwarder pointer") * memory wordSize "bytes")
]

{ #category : #accessing }
VMSpurMemoryManagerTest >> wordSize [
	
	^ wordSize ifNil: [ 8 ]
]

{ #category : #accessing }
VMSpurMemoryManagerTest >> wordSize: aWordSize [

	wordSize := aWordSize
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> zeroSizedObjectClassIndex [

	^ zeroSizedObjectClassIndex ifNil: [ self nextOrdinaryClassIndex ]
]
