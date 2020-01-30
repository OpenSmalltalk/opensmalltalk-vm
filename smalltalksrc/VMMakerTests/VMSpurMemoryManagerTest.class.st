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

	"100 k at least to put the class table in the old space"
	oldSpaceSize := 1000 * 1024.
 	newSpaceSize := 1 * 1024.
	stackSize := 16 * 1024.
	
	objectHeaderSize := 8 "bytes".
	emptyObjectSize := objectHeaderSize + 8 "minimum required single empty slot, to use for forwarders".
	
	"Set it to bootstrapping to allow smaller memories"
	interpreter := StackInterpreterSimulator newWithOptions: {#BytesPerWord . 8}.
	memory := Spur64BitMMLESimulator new.
	
	memory coInterpreter: interpreter.
	interpreter objectMemory: memory.
	
	memory bootstrapping: true.
	
	memory
		allocateMemoryOfSize: oldSpaceSize
		newSpaceSize: newSpaceSize
		stackSize: stackSize
		codeSize: 0.
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
