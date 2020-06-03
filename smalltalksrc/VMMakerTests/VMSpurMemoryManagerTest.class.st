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
		'methodCacheSize',
		'rumpCStackSize'
	],
	#category : #VMMakerTests
}

{ #category : #'helper-frame' }
VMSpurMemoryManagerTest >> frameBuilder [
	^ VMFrameBuilderForTest new
		initializeForTest: self;
		yourself

]

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

{ #category : #helpers }
VMSpurMemoryManagerTest >> makeBaseFrameWithMethod: aMethodOop context: aContextOop receiver: aReceiverOop args: argsOops andStack: stackOops [
	
	| page pointer |
	page := memory coInterpreter stackPages newStackPage.
	pointer := page baseAddress.
	memory coInterpreter stackPointer: pointer + memory wordSize.
	"Receiver"
	memory coInterpreter push: aReceiverOop.
	argsOops do: [ :e | memory coInterpreter push: e ].
	"sender context"
	memory coInterpreter push: memory nilObject.
	"base frame's saved fp is null"
	memory coInterpreter push: 0.
	page
		baseFP: memory coInterpreter stackPointer;
		headFP: memory coInterpreter stackPointer.
	"method"
	memory coInterpreter push: aMethodOop.
	"Flags: this stack frame is single. I.e., it has no context object.
	Otherwise GC fails with an assertion looking for it in the heap"
	memory coInterpreter push: (memory coInterpreter 
		encodeFrameFieldHasContext: (aContextOop ~= memory nilObject)
		isBlock: false
		numArgs: argsOops size).
	"context"
	memory coInterpreter push: aContextOop.
	"rcvr"
	memory coInterpreter push: aReceiverOop.
	"frame stack => empty"
	stackOops do: [ :e | memory coInterpreter push: e ].
	"ip"
	memory coInterpreter push: (aMethodOop + memory baseHeaderSize - 2).
	page headSP: memory coInterpreter stackPointer.
	memory coInterpreter setStackPageAndLimit: page.
	memory coInterpreter setStackPointersFromPage: page.
	memory coInterpreter popStack.
	
	"Mark context as married by setting its sender to the frame pointer plus SmallInteger
	 tags and the InstructionPointer to the saved fp (which ensures correct alignment
	 w.r.t. the frame when we check for validity) plus SmallInteger tags."
	(aContextOop ~= memory nilObject) ifTrue: [ 
		memory
			storePointerUnchecked: 0 "SenderIndex"
			ofObject: aContextOop
			withValue: (memory coInterpreter withSmallIntegerTags: page baseFP) ]
]

{ #category : #accessor }
VMSpurMemoryManagerTest >> memory [
	^ memory
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newInterpreter [

	StackInterpreterSimulatorLSB
		initializeWithOptions: {
			#BytesPerWord. 8.
			#ObjectMemory. #Spur64BitMemoryManager}
		objectMemoryClass: Spur64BitMemoryManager.
	^ StackInterpreterSimulatorLSB basicNew
		objectMemory: self newMemory;
		basicInitialize
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newMemory [

	^ Spur64BitMemoryManager simulatorClass new
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
]

{ #category : #accessing }
VMSpurMemoryManagerTest >> sizeOfObjectWithSlots: slots [

	^ objectHeaderSize + ((slots min: 1 "at least one for the forwarder pointer") * memory wordSize "bytes")
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> zeroSizedObjectClassIndex [

	^ zeroSizedObjectClassIndex ifNil: [ self nextOrdinaryClassIndex ]
]
