"
SpurSweeper is a sweep-only algorithm, setting the compactor to SpurSweeper effectively changes the fullGC to a mark-sweep non-moving algorithm. 

SpurSweeper is a reference implementation if one wants to evaluate GC performance and compare it to a Mark-Sweep. It's also the only non-moving GC available right now which can be convenient for some experiments. One of the main reason why it was implemented is because advanced compaction algorithm includes a sweep phase (See SelectiveCompactor for example) and SpurSweeper allows to debug the sweep phase separatedly.

"
Class {
	#name : #SpurSweeper,
	#superclass : #SpurCompactor,
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #api }
SpurSweeper >> biasForGC [
]

{ #category : #api }
SpurSweeper >> biasForSnapshot [
]

{ #category : #'sweep phase' }
SpurSweeper >> bulkFreeChunkFrom: objOop [
	"The old space entity before objOop is necessarily a marked object. Attempts to free as many bytes 
	from objOop start as possible, looking ahead to free contiguous freechunks / unmarked objects"
	| bytes start next currentObj |
	self assert: ((manager isMarked: objOop) not or: [manager isFreeObject: objOop]).
	start := manager startOfObject: objOop.
	currentObj := objOop.
	bytes := 0.
	[bytes := bytes + (manager bytesInObject: currentObj).
	(manager isRemembered: currentObj)
		ifTrue: 
			[self assert: (manager isFreeObject: currentObj) not.
			 scavenger forgetObject: currentObj].
	next := manager objectStartingAt: start + bytes.
	self assert: ((manager oop: next isLessThan: manager endOfMemory)
		or: [next = manager endOfMemory and: [(self canUseAsFreeSpace: next) not]]).
	self canUseAsFreeSpace: next] 
		whileTrue: [currentObj := next].
	
	^self interceptAddFreeChunkWithBytes: bytes at: start
]

{ #category : #'sweep phase' }
SpurSweeper >> canUseAsFreeSpace: objOop [
	<inline: true>
	^ (manager isFreeObject: objOop) or: [(manager isMarked: objOop) not]
]

{ #category : #api }
SpurSweeper >> compact [
	<inline: #never> "for profiling"
	self resetFreeLists.
	self globalSweep.
	manager updateSweepEndUsecs
]

{ #category : #'sweep phase' }
SpurSweeper >> globalSweep [
	"Iterate over all entities, in order, making large free chunks from free chunks and unmarked objects, 
	unmarking live objects and rebuilding the free lists."

	| currentEntity |
	currentEntity := manager firstObject.
	[self oop: currentEntity isLessThan: manager endOfMemory] whileTrue:
		[(self canUseAsFreeSpace: currentEntity) 
			ifTrue: [currentEntity := self bulkFreeChunkFrom: currentEntity]
			ifFalse: [self unmark: currentEntity].
		 currentEntity := manager objectAfter: currentEntity limit: manager endOfMemory].
			
	manager checkFreeSpace: GCModeFull.
	manager unmarkSurvivingObjectsForCompact.

	
]

{ #category : #'sweep phase' }
SpurSweeper >> interceptAddFreeChunkWithBytes: bytes at: start [
	<inline: true>
	^manager addFreeChunkWithBytes: bytes at: start

]

{ #category : #api }
SpurSweeper >> resetFreeLists [
	manager resetFreeListHeads.
	manager totalFreeOldSpace: 0.
]

{ #category : #'sweep phase' }
SpurSweeper >> unmark: objOop [
	self assert: ((manager isMarked: objOop) and: [(manager isFreeObject: objOop) not]).
	(manager isSegmentBridge: objOop) ifFalse: [manager setIsMarkedOf: objOop to: false].
	(manager isPinned: objOop) ifTrue: [manager segmentManager notePinned: objOop]
]
