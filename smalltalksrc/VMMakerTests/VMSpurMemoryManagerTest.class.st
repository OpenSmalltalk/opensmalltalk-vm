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
		'wordSize'
	],
	#pools : [
		'VMBasicConstants',
		'VMBytecodeConstants',
		'VMObjectIndices'
	],
	#category : #'VMMakerTests-MemoryTests'
}

{ #category : #accessing }
VMSpurMemoryManagerTest >> initialCodeSize [
	^ 0
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

{ #category : #accessor }
VMSpurMemoryManagerTest >> memory [
	^ memory
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newInterpreter [

	memory := self newMemory.

	StackInterpreterSimulatorLSB
		initializeWithOptions: {
			#BytesPerWord. self wordSize.
			#ObjectMemory. memory class name}
		objectMemoryClass: memory class.

	^ StackInterpreterSimulatorLSB basicNew
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
VMSpurMemoryManagerTest >> newMethodWithBytecodes: bytes [
	
	| method methodHeader |

	"Create a bytecode compiled method object containing the given literal at the given index"
	method := self
		newOldSpaceObjectWithSlots: 0 "# of literals" + 1 "one extra for the header" + (bytes size // memory wordSize)
		format: (memory compiledMethodFormatForNumBytes: bytes size)
		classIndex: 16r10.
	methodHeader := (0 "nArgs" bitShift: 24)
						+ (0 "nTemps" bitShift: 18)
						+ (0 "small frame")
						+ 0 "number of literaps"
						+ 0 "primitive".
	memory storePointer: 0 ofObject: method withValue: (memory integerObjectOf: methodHeader).
	memory storeByte: 8 ofObject: method withValue: (bytes at: 1).

	^ method
]

{ #category : #'helpers - methods' }
VMSpurMemoryManagerTest >> newMethodWithLiteral: literalObject at: literalIndex [
	
	| method methodHeader |

	"Create a bytecode compiled method object containing the given literal at the given index"
	
	method := self
		newOldSpaceObjectWithSlots: literalIndex + 1 "index is 0 based" + 1 "one extra for the header"
		format: (memory compiledMethodFormatForNumBytes: 0)
		classIndex: 16r10.
	methodHeader := (0 "nArgs" bitShift: 24)
						+ (0 "nTemps" bitShift: 18)
						+ (0 "small frame")
						+ literalIndex + 2 "number of literaps"
						+ 0 "primitive".
	memory storePointer: 0 ofObject: method withValue: (memory integerObjectOf: methodHeader).
	memory
		storePointer: literalIndex + 1
		ofObject: method
		withValue: literalObject.
	^ method
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
VMSpurMemoryManagerTest >> setUp [
	super setUp.

	"100 k at least to put the class table in the old space.
	Get total size be a multiple of 4K so Unicorn CPU emulator accepts it"
	oldSpaceSize := 999 * 1024.
 	newSpaceSize := 1 * 1024.
	stackSpaceSize := 9 * 4096.
	methodCacheSize := 4096 * 8 "wordSize".
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
	
	stackBuilder := VMStackBuilder new
		interpreter: interpreter; 
		memory: memory;
		yourself.

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
