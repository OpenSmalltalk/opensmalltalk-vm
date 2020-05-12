Class {
	#name : #VMSpurMemoryManagerTest,
	#superclass : #ParametrizedTestCase,
	#instVars : [
		'newSpaceSize',
		'stackSize',
		'memory',
		'oldSpaceSize',
		'nextIndex',
		'objectHeaderSize',
		'zeroSizedObjectClassIndex',
		'emptyObjectSize',
		'initialAddress'
	],
	#category : #VMMakerTests
}

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
	memory specialObjectsOop: (self newObjectWithSlots: 20).
	
	memory scavengingGCTenuringIf: 1.
	self deny: memory needGCFlag.
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newInterpreter [

	^ StackInterpreterSimulator newWithOptions: {#BytesPerWord . 8}
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newMemory [

	^ Spur64BitMMLESimulator new
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
	
	| oop |
	oop := memory
			allocateSlotsInOldSpace: slots
			format: memory arrayFormat
			classIndex: anIndex.
	oop ifNotNil: [ memory fillObj: oop numSlots: slots with: memory nilObject ].
	^ oop
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

{ #category : #running }
VMSpurMemoryManagerTest >> setUp [
	
	| interpreter |
	super setUp.

	"100 k at least to put the class table in the old space.
	Get total size be a multiple of 4K so Unicorn CPU emulator accepts it"
	oldSpaceSize := 999 * 1024.
 	newSpaceSize := 1 * 1024.
	stackSize := 16 * 1024.
	initialAddress := 16r1000000.
	
	objectHeaderSize := 8 "bytes".
	emptyObjectSize := objectHeaderSize + 8 "minimum required single empty slot, to use for forwarders".
	
	"Set it to bootstrapping to allow smaller memories"
	interpreter := self newInterpreter.
	memory := self newMemory.
	
	memory coInterpreter: interpreter.
	interpreter objectMemory: memory.
	
	memory bootstrapping: true.
	
	memory
		allocateMemoryOfSize: oldSpaceSize
		newSpaceSize: newSpaceSize
		stackSize: stackSize
		codeSize: self initialCodeSize
		initialAddress: initialAddress.
	memory initializePostBootstrap.
	memory setHeapSizeAtPreviousGC.
	memory segmentManager collapseSegmentsPostSwizzle.
	
	"Schedule a GC, so it does not try to schedule one"
	memory needGCFlag: 1.
]

{ #category : #accessing }
VMSpurMemoryManagerTest >> sizeOfObjectWithSlots: slots [

	^ objectHeaderSize + ((slots min: 1 "at least one for the forwarder pointer") * memory wordSize "bytes")
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> zeroSizedObjectClassIndex [

	^ zeroSizedObjectClassIndex ifNil: [ self nextOrdinaryClassIndex ]
]
