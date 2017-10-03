"
SpurSweeper is a sweep-only algorithm, setting the compactor to SpurSweeper effectively changes the fullGC to a mark-sweep non-moving algorithm. 

SpurSweeper has two main purposes:
1. SpurSelectiveCompactor includes a sweep algorithm, inherited from SpurSweeper, and SpurSweeper allows to debug it separatedly.
2. SpurSweeper is a non-moving GC which can be convenient in some cases (For example when accessing objects from C in a concurrent thread called with ThreadedFFI, the C code can access the objects during fullGC since there won't be conflict with object fields being updated while being read).

For snapshots a non-compacting algortihm does not make sense, hence a more aggressive compactor is called instead (see #compact).
"
Class {
	#name : #SpurSweeper,
	#superclass : #SpurCompactor,
	#instVars : [
		'biasForGC',
		'aggressiveCompactor'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #api }
SpurSweeper >> biasForGC [
	biasForGC := true.
]

{ #category : #api }
SpurSweeper >> biasForSnapshot [
	biasForGC := false.
]

{ #category : #'sweep phase' }
SpurSweeper >> bulkFreeChunkFrom: objOop [
	"ObjOop is either a freeChunk or an object to free, always in old space. The old space entity before objOop is necessarily a marked object.
	 Attempts to free as many byte from objOop, looking ahead for multiple freechunks / objects to free in a row"
	| bytes start next currentObj |
	
	"Avoids pathological case, not point in dealing with non-mergeable free chunks, we would remove them and re-add them to the free list."
	(self isSingleFreeObject: objOop) ifTrue: [^0].
	
	"We free unmarked objects and freechunks next to each others and merge them at the same time"
	start := manager startOfObject: objOop.
	currentObj := objOop.
	bytes := 0.
	[bytes := bytes + (manager bytesInObject: currentObj).
	self freeEntity: currentObj.
	next := manager objectStartingAt: start + bytes.
	self canUseNextEntityAsFreeSpace: next] 
		whileTrue: [currentObj := next].
	
	manager addFreeChunkWithBytes: bytes at: start.
	
	^ next
]

{ #category : #'sweep phase' }
SpurSweeper >> canUseAsFreeSpace: objOop [
	<inline: true>
	^ (manager isFreeObject: objOop) or: [(manager isMarked: objOop) not]
]

{ #category : #'sweep phase' }
SpurSweeper >> canUseNextEntityAsFreeSpace: next [
	<inline: true>
	^ (manager oop: next isLessThan: manager endOfMemory) and: [self canUseAsFreeSpace: next]
]

{ #category : #api }
SpurSweeper >> compact [
	<inline: #never> "for profiling"
	biasForGC
		ifTrue: [self globalSweep]
		ifFalse: ["Should use a compacting algo instead"self globalSweep]
]

{ #category : #'sweep phase' }
SpurSweeper >> freeEntity: entity [
	<inline: true>
	(manager isFreeObject: entity) 
		ifFalse: "Freed old space objects are removed from remembered table"
			[(manager isRemembered: entity) ifTrue:
				[scavenger forgetObject: entity]]
		ifTrue:  "Merged old space free chunks are removed from free list"
			[manager detachFreeObject: entity]
	
]

{ #category : #'sweep phase' }
SpurSweeper >> globalSweep [
	"Iterate over all entities, in order, if the entity is a free chunk or unmarked object, 
	 make a new big piece of free chunk, else unmark the object which stay live."

	| currentEntity start |
	currentEntity := manager firstObject.
	[self oop: currentEntity isLessThan: manager endOfMemory] whileTrue:
		[(self canUseAsFreeSpace: currentEntity) 
			ifTrue: ["bulkFreeChunkFrom: may change a 1 word header
					object to a double word header object"
					start := manager startOfObject: currentEntity.
					self bulkFreeChunkFrom: currentEntity.
					currentEntity := manager objectStartingAt: start]
			ifFalse: [self unmark: currentEntity].
		 currentEntity := manager objectAfter: currentEntity limit: manager endOfMemory].
			
	manager checkFreeSpace: GCModeFull.
		
	manager unmarkSurvivingObjectsForCompact.
	
]

{ #category : #'sweep phase' }
SpurSweeper >> isSingleFreeObject: objOop [
	<inline: true>
	| next |
	^ (manager isFreeObject: objOop) and: 
		[next := manager objectAfter: objOop limit: manager endOfMemory.
		(manager oop: next isGreaterThanOrEqualTo: manager endOfMemory) or: [manager isMarked: next]]
]

{ #category : #api }
SpurSweeper >> remapObj: objOop [
	<api>
	<inline: false>
	^manager vanillaRemapObj: objOop
]

{ #category : #api }
SpurSweeper >> shouldRemapObj: objOop [
	<api>
	^manager vanillaShouldRemapObj: objOop
]

{ #category : #'sweep phase' }
SpurSweeper >> unmark: objOop [
	self assert: ((manager isMarked: objOop) and: [(manager isFreeObject: objOop) not]).
	(manager isSegmentBridge: objOop) ifFalse: [manager setIsMarkedOf: objOop to: false].
	(manager isPinned: objOop) ifTrue: [manager segmentManager notePinned: objOop]
]
