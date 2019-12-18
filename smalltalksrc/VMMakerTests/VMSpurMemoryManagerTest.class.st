Class {
	#name : #VMSpurMemoryManagerTest,
	#superclass : #TestCase,
	#instVars : [
		'newSpaceSize',
		'stackSize',
		'memory',
		'oldSpaceSize',
		'nextIndex',
		'objectHeaderSize',
		'zeroSizedObjectClassIndex',
		'emptyObjectSize'
	],
	#category : #VMMakerTests
}

{ #category : #'tests-2-instantiation' }
VMSpurMemoryManagerTest >> fillEden [

	"Allocate enough objects to fill the eden."
	1
		to: memory scavenger eden size // emptyObjectSize
		do: [ :index | self newZeroSizedObject ]
]

{ #category : #'tests-scavenge' }
VMSpurMemoryManagerTest >> initializeOldSpaceForScavenger [

	"Create a nil object required to initialize several fields"
	memory nilObject: self newZeroSizedObject.

	"Initialize Stack"
	memory coInterpreter desiredNumStackPages: 8.
	memory coInterpreter initStackPages.
	memory coInterpreter bootstrapping: true.

	"Initialize Special Root objects"
	memory coInterpreter method: memory nilObject.
	memory coInterpreter instructionPointer: memory nilObject.
	memory coInterpreter newMethod: memory nilObject.
	memory coInterpreter profileProcess: memory nilObject.
	memory coInterpreter profileMethod: memory nilObject.
	memory coInterpreter profileSemaphore: memory nilObject.
	memory mournQueue: memory nilObject.
	memory specialObjectsOop: memory nilObject.
	
	"Initialize old space with free list, class table, hidden roots and remembered set to be able to scavenge"
	memory initializeFreeList.
	memory segmentManager collapseSegmentsPostSwizzle.
	memory updateFreeLists.
	memory computeFreeSpacePostSwizzle.
	memory initializeOldSpaceFirstFree: memory freeOldSpaceStart.
	memory allocateClassTable.	
	memory scavenger initializeRememberedSet.
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newObjectWithSlots: slots [
	
	^ self newObjectWithSlots: slots classIndex: memory arrayClassIndexPun
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newObjectWithSlots: slots classIndex: anIndex [
	
	| oop |
	oop := memory
			allocateSlots: slots
			format: memory arrayFormat
			classIndex: anIndex.
	memory nilFieldsOf: oop.
	^ oop
]

{ #category : #'tests-scavenge' }
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

	"100 k at least to put the class table in the old space"
	oldSpaceSize := 100 * 1024.
 	newSpaceSize := 1 * 1024.
	stackSize := 16 * 1024.
	
	objectHeaderSize := 8 "bytes".
	emptyObjectSize := objectHeaderSize + 8 "minimum required single empty slot, to use for forwarders".
	
	"Set it to bootstrapping to allow smaller memories"
	interpreter := StackInterpreterSimulator newWithOptions: {#BytesPerWord . 8}.
	memory := Spur64BitMMLESimulator new.
	
	memory coInterpreter: interpreter.
	interpreter objectMemory: memory.
	
	memory
		allocateMemoryOfSize: oldSpaceSize
		newSpaceSize: newSpaceSize
		stackSize: stackSize
		codeSize: 0.
	memory initializePostBootstrap.
	memory setHeapSizeAtPreviousGC.
	
	"Schedule a GC, so it does not try to schedule one"
	memory needGCFlag: 1.
]

{ #category : #accessing }
VMSpurMemoryManagerTest >> sizeOfObjectWithSlots: slots [

	^ objectHeaderSize + ((slots min: 1 "at least one for the forwarder pointer") * memory wordSize "bytes")
]

{ #category : #'tests-memory-bootstrap' }
VMSpurMemoryManagerTest >> testClassTableHasTablePagesAndHiddenRoots [

	| tableRoot |
	
	memory coInterpreter desiredNumStackPages: 8.
	memory coInterpreter initStackPages.
	memory coInterpreter bootstrapping: true.
	memory nilObject: self newZeroSizedObject.

	memory coInterpreter method: memory nilObject.
	memory coInterpreter instructionPointer: memory nilObject.
	memory coInterpreter newMethod: memory nilObject.
	memory coInterpreter profileProcess: memory nilObject.
	memory coInterpreter profileMethod: memory nilObject.
	memory coInterpreter profileSemaphore: memory nilObject.
	memory mournQueue: memory nilObject.
	memory specialObjectsOop: memory nilObject.
	
	"Initialize old space with free list, class table, hidden roots and remembered set to be able to scavenge"
	memory initializeFreeList.
	memory segmentManager collapseSegmentsPostSwizzle.
	memory updateFreeLists.
	memory computeFreeSpacePostSwizzle.
	memory initializeOldSpaceFirstFree: memory freeOldSpaceStart.


	tableRoot := memory allocateClassTable.
	
	self
		assert: (memory numSlotsOf: tableRoot)
		equals: memory classTableRootSlots + memory hiddenRootSlots
]

{ #category : #'tests-memory-bootstrap' }
VMSpurMemoryManagerTest >> testFreeListHasAsManySlotsAsRequiredByTheVM [

	| freeListOop |
	freeListOop := memory initializeFreeList.

	self assert: (memory numSlotsOf: freeListOop) equals: memory numFreeLists
]

{ #category : #'tests-memory-bootstrap' }
VMSpurMemoryManagerTest >> testFreeListIsWordIndexable [

	| freeListOop |
	freeListOop := memory initializeFreeList.

	self assert: (memory formatOf: freeListOop) equals: memory wordIndexableFormat
]

{ #category : #'tests-2-instantiation' }
VMSpurMemoryManagerTest >> testInstantiateNewObjectMovesFreeStartAfterObject [
	
	| freeStartBefore |
	freeStartBefore := memory freeStart.
	self newZeroSizedObject.
	
	"New zero sized object has 64bit header + 1 * 64bit empty slot = 16bytes"
	self assert: memory freeStart equals: freeStartBefore + emptyObjectSize
]

{ #category : #'tests-memory-bootstrap' }
VMSpurMemoryManagerTest >> testNewFreeListHasAllSlotsInitializedInZero [

	| freeListOop |
	freeListOop := memory initializeFreeList.

	0 to: memory numFreeLists - 1 do: [ :i |
		self assert: (memory fetchPointer: i ofObject: freeListOop) equals: 0 ]
]

{ #category : #'tests-1-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryEdenEndIsAtTheStartOfOldSpace [

	self assert: memory scavenger eden limit equals: memory oldSpaceStart
]

{ #category : #'tests-1-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryEdenIsRestOfNewSpace [
	
	self
		assert: memory scavenger eden size
		equals: newSpaceSize - memory scavenger pastSpace size - memory scavenger futureSpace size
]

{ #category : #'tests-1-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryFreeStartIsEdenStart [
	
	self assert: memory freeStart equals: memory scavenger eden start
]

{ #category : #'tests-1-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryFutureSpaceEndIsAtTheStartOfEden [

	self assert: memory scavenger futureSpace limit equals: memory scavenger eden start
]

{ #category : #'tests-1-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryFutureSpaceIsRoughlyOneSeventhOfNewSpace [
	
	self assert: memory scavenger futureSpace size equals: (newSpaceSize // 7 truncateTo: memory allocationUnit)
]

{ #category : #'tests-1-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryFutureSurvivorSpaceIsAtFutureSpaceStart [
	
	"The future survivor start indicates during the execution of the scavenger, where the next free space in future space starts."
	
	self assert: memory scavenger futureSurvivorStart equals: memory scavenger futureSpace start
]

{ #category : #'tests-1-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryLimitIsSumOfSpaces [
	
	self assert: memory memoryLimit equals: oldSpaceSize + newSpaceSize + stackSize
]

{ #category : #'tests-1-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryNewSpaceLimitIsNewSpaceStartPlusSize [
	
	self assert: memory newSpaceLimit equals: newSpaceSize + stackSize
]

{ #category : #'tests-1-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryNewSpaceStartIsStackSize [

	self assert: memory newSpaceStart equals: stackSize
]

{ #category : #'tests-1-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryPastSpaceEndIsAtTheStartOfFutureSpace [

	self assert: memory scavenger pastSpace limit equals: memory scavenger futureSpace start
]

{ #category : #'tests-1-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryPastSpaceFreeStartIsAtPastSpaceStart [
	
	" - pastSpaceStart points to where the free space in the past space starts => it **does** move
	  - scavenger pastSpace start points to the actual beginning of the past space => it does not move"
	
	self assert: memory pastSpaceStart equals: memory scavenger pastSpace start
]

{ #category : #'tests-1-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryPastSpaceIsAtTheStartOfNewSpace [
	
	self assert: memory scavenger pastSpace start equals: memory newSpaceStart
]

{ #category : #'tests-1-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryPastSpaceIsRoughlyOneSeventhOfNewSpace [
	
	self assert: memory scavenger pastSpaceBytes equals: (newSpaceSize // 7 truncateTo: memory allocationUnit)
]

{ #category : #'tests-2-instantiation' }
VMSpurMemoryManagerTest >> testNewObjectAfterEdenLimitThrowsError [

	"Allocate enough objects to fill the eden."
	self fillEden.
	
	"Allocating one more object should not be allowed, and should throw an error"
	[ self newZeroSizedObject.
		
		"Fail the test if it does not raise an exception"
		self fail ] on: Error do: [ :error | 
			self assert: error messageText equals: 'no room in eden for allocateNewSpaceSlots:format:classIndex:' ]
]

{ #category : #'tests-2-instantiation' }
VMSpurMemoryManagerTest >> testNewObjectInEdenDoesNotModifyFutureSpace [
	
	| futureSpaceStartBefore |
	futureSpaceStartBefore := memory scavenger futureSurvivorStart.
	self newZeroSizedObject.
	
	self assert: memory scavenger futureSurvivorStart equals: futureSpaceStartBefore
]

{ #category : #'tests-2-instantiation' }
VMSpurMemoryManagerTest >> testNewObjectInEdenDoesNotModifyPastSpace [
	
	| pastSpaceStartBefore |
	pastSpaceStartBefore := memory pastSpaceStart.
	self newZeroSizedObject.
	
	self assert: memory pastSpaceStart equals: pastSpaceStartBefore
]

{ #category : #'tests-2-instantiation' }
VMSpurMemoryManagerTest >> testNewObjectPositionIsBeforeObjectHeader [
	
	| freeStartBefore oop |
	freeStartBefore := memory freeStart.
	
	oop := self newZeroSizedObject.
	
	self assert: oop equals: freeStartBefore
]

{ #category : #'tests-scavenge' }
VMSpurMemoryManagerTest >> testScavengeEmptyMemoryShouldExchangePastAndFutureSpaces [

	| oldPastSpaceStart oldFutureSpaceStart |
	
	self initializeOldSpaceForScavenger.
	
	oldPastSpaceStart := memory scavenger pastSpace start.
	oldFutureSpaceStart := memory scavenger futureSpace start.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assert: memory scavenger pastSpace start equals: oldFutureSpaceStart.
	self assert: memory scavenger futureSpace start equals: oldPastSpaceStart.
]

{ #category : #'tests-scavenge' }
VMSpurMemoryManagerTest >> testScavengeNonSurvivorShouldEmptyEden [

	self initializeOldSpaceForScavenger.
	
	"Nil should survive."
	"A new object not referenced should not survive."
	self newZeroSizedObject.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assert: memory freeStart equals: memory scavenger eden start
]

{ #category : #'tests-scavenge' }
VMSpurMemoryManagerTest >> testScavengeNonSurvivorShouldOnlyCopySurvivorObjectToPastSpace [

	self initializeOldSpaceForScavenger.
	
	"Only Nil should survive."
	"A new object not referenced should not survive."
	self newObjectWithSlots: 1.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assert: memory pastSpaceStart equals: memory scavenger pastSpace start + emptyObjectSize
]

{ #category : #'tests-scavenge' }
VMSpurMemoryManagerTest >> testScavengeShouldCopySurvivorObjectReferencedFromStackToPastSpace [

	| newObjectOop page pointer newObjectHash newObjectAddress |
	self initializeOldSpaceForScavenger.
	memory lastHash: 1.
	
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).
	
	page := memory coInterpreter stackPages newStackPage.
	pointer := page baseAddress.
	memory coInterpreter stackPointer: pointer + memory wordSize.
	"Receiver"
	memory coInterpreter push: memory nilObject.
	"sender context"
	memory coInterpreter push: memory nilObject.
	"base frame's saved fp is null"
	memory coInterpreter push: 0.
	page
		baseFP: memory coInterpreter stackPointer;
		headFP: memory coInterpreter stackPointer.
	"method"
	memory coInterpreter push: newObjectOop.
	"Flags: this stack frame is single. I.e., it has no context object.
	Otherwise GC fails with an assertion looking for it in the heap"
	memory coInterpreter push: (memory coInterpreter 
		encodeFrameFieldHasContext: false
		isBlock: false
		numArgs: 0).
	"context"
	memory coInterpreter push: memory nilObject.
	"rcvr"
	memory coInterpreter push: memory nilObject.
	"frame stack => empty"
	"ip"
	memory coInterpreter push: (memory nilObject + memory baseHeaderSize - 2).
	page headSP: memory coInterpreter stackPointer.
	memory coInterpreter setStackPageAndLimit: page.
	memory coInterpreter setStackPointersFromPage: page.
	memory coInterpreter popStack.

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	newObjectAddress := memory scavenger pastSpace start + emptyObjectSize.
	self assert: (memory hashBitsOf: newObjectAddress) equals: newObjectHash
]

{ #category : #'tests-scavenge' }
VMSpurMemoryManagerTest >> testScavengeShouldCopySurvivorObjectToPastSpace [

	self initializeOldSpaceForScavenger.
	
	"Nil should survive.
	It is referenced by the roots because many of their slots are nilled."
	memory doScavenge: 1 "TenureByAge".
	
	self assert: memory pastSpaceStart equals: memory scavenger pastSpace start + emptyObjectSize
]

{ #category : #'tests-scavenge' }
VMSpurMemoryManagerTest >> testScavengeSurvivorShouldEmptyEden [

	self initializeOldSpaceForScavenger.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assert: memory freeStart equals: memory scavenger eden start
]

{ #category : #'tests-scavenge' }
VMSpurMemoryManagerTest >> testScavengeTwiceShouldExchangePastAndFutureSpacesBackAndForth [

	| oldPastSpaceStart oldFutureSpaceStart |

	self initializeOldSpaceForScavenger.
	
	oldPastSpaceStart := memory scavenger pastSpace start.
	oldFutureSpaceStart := memory scavenger futureSpace start.
	
	2 timesRepeat: [ memory doScavenge: 1 "TenureByAge" ].
	
	self assert: memory scavenger pastSpace start equals: oldPastSpaceStart.
	self assert: memory scavenger futureSpace start equals: oldFutureSpaceStart.
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> zeroSizedObjectClassIndex [

	^ zeroSizedObjectClassIndex ifNil: [ self nextOrdinaryClassIndex ]
]
