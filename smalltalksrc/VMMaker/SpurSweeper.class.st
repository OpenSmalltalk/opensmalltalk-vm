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
	[bytes := bytes + self bytesInObject: currentObj.
	self freeEntity: currentObj.
	next := manager objectStartingAt: start + bytes.
	self canUseNextEntityAsFreeSpace: next] 
		whileTrue: [currentObj := next].
	
	manager totalFreeOldSpace: manager totalFreeOldSpace + bytes.
	^manager freeChunkWithBytes: bytes at: start
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

{ #category : #initialization }
SpurSweeper >> coInterpreter: aVMSimulator [
	<doNotGenerate>
	super coInterpreter: aVMSimulator.
	aggressiveCompactor coInterpreter: aVMSimulator.
]

{ #category : #api }
SpurSweeper >> compact [
	"Unless we're snapshotting, use a non-compacting sweep algorithm"
	<inline: #never> "for profiling"
	biasForGC
		ifTrue: [self globalSweep]
		ifFalse: [aggressiveCompactor compact]
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
	"allOldSpaceEntitiesDo: computes the address of the next object only once the block has been evaluated,
	 hence when we rewrite object iterated over as a larger free chunk, the next object is the object after the chunk"
	self allOldSpaceEntitiesDo: 
		[:objOop | (self canUseAsFreeSpace: objOop) ifTrue: [self bulkFreeChunkFrom: objOop]].
	
]

{ #category : #initialization }
SpurSweeper >> initialize [
	aggressiveCompactor := SpurPlanningCompactor new.
]

{ #category : #'sweep phase' }
SpurSweeper >> isSingleFreeObject: objOop [
	<inline: true>
	| next |
	^ (manager isFreeObject: objOop) and: 
		[next := manager objectAfter: objOop limit: manager endOfMemory.
		(manager oop: next isGreaterThanOrEqualTo: manager endOfMemory) or: [manager isMarked: next]]
]

{ #category : #initialization }
SpurSweeper >> manager: aSpurNBitMMXEndianSimulator [
	<doNotGenerate>
	super manager: aSpurNBitMMXEndianSimulator.
	aggressiveCompactor manager: aSpurNBitMMXEndianSimulator
]
