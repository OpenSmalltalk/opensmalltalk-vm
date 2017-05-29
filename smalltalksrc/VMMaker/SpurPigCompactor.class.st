"
SpurPigCompactor implements the second compactioon algorithm implemented for Spur.  It attempts to move ovbjects down from the end of memory to occupy free chunks in low memory.  It uses Knuth's xor-encoding technique to encode a doubly-linked list in the forwarding field of each free chunk (free chunks, like Spiur objects, being known to have at least one field).  This algorithm has poor performance for two reasons.  First, it does not preserve object order, scrambling the order of objects as it moves the highest objects down to the lowest free chunks.  Second it appears to perform badly, occasionally causing very long pauses.

Instance Variables
	coInterpreter:				<StackInterpreter>
	firstFreeChunk:				<Integer>
	lastFreeChunk:				<Integer>
	manager:					<SpurMemoryManager>
	numCompactionPasses:		<Integer>
	scavenger:					<SpurGenerationScavenger>

firstFreeChunk
	- oop of freeChunk or 0

lastFreeChunk
	- oop of freeChunk or 0

numCompactionPasses
	- 2 for normal GC, 3 for snapshot
"
Class {
	#name : #SpurPigCompactor,
	#superclass : #CogClass,
	#instVars : [
		'manager',
		'scavenger',
		'coInterpreter',
		'firstFreeChunk',
		'lastFreeChunk',
		'numCompactionPasses'
	],
	#classVars : [
		'CompactionPassesForGC',
		'CompactionPassesForSnapshot'
	],
	#pools : [
		'SpurMemoryManagementConstants',
		'VMBasicConstants',
		'VMSpurObjectRepresentationConstants'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurPigCompactor class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #'class initialization' }
SpurPigCompactor class >> initialize [
	"Pig compact can be repeated to compact better.  Experience shows that 3 times
	 compacts very well, desirable for snapshots.  But this is overkill for normal GCs."
	CompactionPassesForGC := 2.
	CompactionPassesForSnapshot := 3
]

{ #category : #'compaction - analysis' }
SpurPigCompactor >> abstractPigCompaction [
	"This method answers a rough estimate of compactibility using a pig (a large free chunk)."
	<doNotGenerate>
	| pig pork moved unmoved nmoved nunmoved |
	pig := self findAPig.
	pork := manager bytesInObject: pig.
	moved := unmoved := nmoved := nunmoved := 0.
	manager allOldSpaceObjectsFrom: pig do:
		[:o| | bytes |
		bytes := manager bytesInObject: o.
		bytes <= pork
			ifTrue:
				[moved := moved + bytes.
				 nmoved := nmoved + 1.
				 pork := pork - bytes]
			ifFalse:
				[unmoved := unmoved + bytes.
				 nunmoved := nunmoved + 1]].
	^{ manager bytesInObject: pig. pork. moved. nmoved. unmoved. nunmoved }
]

{ #category : #'compaction - api' }
SpurPigCompactor >> biasForGC [
	numCompactionPasses := CompactionPassesForGC
]

{ #category : #'compaction - api' }
SpurPigCompactor >> biasForSnapshot [
	numCompactionPasses := CompactionPassesForSnapshot
]

{ #category : #'compaction - asserts' }
SpurPigCompactor >> checkNoForwardersBelowFirstFreeChunk [
	manager allOldSpaceEntitiesDo:
		[:o|
		(self oop: o isGreaterThanOrEqualTo: firstFreeChunk) ifTrue:
			[^true].
		(self asserta: (manager isForwarded: o) not) ifFalse:
			[^false]].
	^true
]

{ #category : #'compaction - asserts' }
SpurPigCompactor >> checkTraversableSortedFreeList [
	| prevFree prevPrevFree freeChunk |
	<api>
	<inline: false>
	prevFree := prevPrevFree := 0.
	firstFreeChunk = 0 ifTrue:
		[^lastFreeChunk = 0].
	freeChunk := firstFreeChunk.
	manager allOldSpaceEntitiesDo:
		[:o| | objOop next limit |
		(manager isFreeObject: o) ifTrue:
			[self assert: o = freeChunk.
			 next := self nextInSortedFreeListLink: freeChunk given: prevFree.
			 limit := next = 0 ifTrue: [manager endOfMemory] ifFalse: [next].
			 "coInterpreter transcript cr; print: freeChunk; tab; print: o; tab; print: prevFree; nextPutAll: '<->'; print: next; flush."
			 objOop := freeChunk.
			 [self oop: (objOop := manager objectAfter: objOop) isLessThan: limit] whileTrue:
				[self assert: (manager isFreeObject: objOop) not].
			 prevPrevFree := prevFree.
			 prevFree := freeChunk.
			 freeChunk := next]].
	self assert: prevFree = lastFreeChunk.
	self assert: (self nextInSortedFreeListLink: lastFreeChunk given: 0) = prevPrevFree.
	self assert: freeChunk = 0.
	^true
]

{ #category : #initialization }
SpurPigCompactor >> coInterpreter: aVMSimulator [
	<doNotGenerate>
	coInterpreter := aVMSimulator
]

{ #category : #'compaction - api' }
SpurPigCompactor >> compact [
	"We'd like to use exact fit followed by best or first fit, but it doesn't work
	 well enough in practice.  So use pig compact.  Fill large free objects starting
	 from low memory with objects taken from the end of memory."
	<inline: #never> "for profiling"
	self freeUnmarkedObjectsAndSortAndCoalesceFreeSpaceForPigCompact.
	manager statCompactPassCount: manager statCompactPassCount + 1.
	self assert: (firstFreeChunk = 0 or: [manager isFreeObject: firstFreeChunk]).
	1 to: numCompactionPasses do:
		[:i|
		 self pigCompact.
		 self eliminateAndFreeForwardersForPigCompact].
	
	"The free lists are zeroed in freeUnmarkedObjectsAndSortAndCoalesceFreeSpaceForPigCompact.
	 They should still be zero here"
	self assert: manager freeListHeadsEmpty.
	self rebuildFreeListsForPigCompact
]

{ #category : #compaction }
SpurPigCompactor >> eliminateAndFreeForwardersForPigCompact [
	"As the final phase of global garbage collect, sweep the heap to follow
	 forwarders, then free forwarders, coalescing with free space as we go."
	<inline: false>
	| lowestForwarder |
	<var: #lowestForwarder type: #usqInt>
	self assert: (manager isForwarded: manager nilObject) not.
	self assert: (manager isForwarded: manager falseObject) not.
	self assert: (manager isForwarded: manager trueObject) not.
	self assert: (manager isForwarded: manager freeListsObj) not.
	self assert: (manager isForwarded: manager hiddenRootsObject) not.
	self assert: (manager isForwarded: manager classTableFirstPage) not.
	manager followSpecialObjectsOop.
	manager followForwardedObjStacks.
	coInterpreter mapInterpreterOops.
	scavenger followRememberedForwardersAndForgetFreeObjectsForPigCompact.
	manager unmarkSurvivingObjectsForCompact.
	lowestForwarder := self sweepToFollowForwardersForPigCompact.
	self sweepToCoallesceFreeSpaceForPigCompactFrom: lowestForwarder.
	self assert: manager numberOfForwarders = 0
]

{ #category : #'compaction - analysis' }
SpurPigCompactor >> findAPig [
	"Answer a large low free chunk."
	<doNotGenerate>
	| pig |
	manager allObjectsInFreeTreeDo:
		[:f|
		(manager bytesInObject: f) >= 1000000 ifTrue:
			[(pig isNil or: [pig > f]) ifTrue:
				[pig := f]]].
	^pig
]

{ #category : #compaction }
SpurPigCompactor >> freeUnmarkedObjectsAndSortAndCoalesceFreeSpaceForPigCompact [
	"Sweep all of old space, freeing unmarked objects, coalescing free chunks, and sorting free space.

	 Doubly-link the free chunks in address order through the freeChunkNextIndex field using the
	 xor trick to use only one field, see e.g.
		The Art of Computer Programming, Vol 1, D.E. Knuth, 3rd Ed, Sec 2.2.4 `Circular Lists', exercise. 18
		http://en.wikipedia.org/wiki/XOR_linked_list.
	 Record the lowest free object in firstFreeChunk and the highest in lastFreeChunk.

	 Let the segmentManager mark which segments contain pinned objects via notePinned:."

	| prevPrevFree prevFree |
	<inline: #never> "for profiling"
	manager checkFreeSpace: GCModeFull.
	"throw away the list heads, including the tree."
	manager resetFreeListHeads.
	firstFreeChunk := prevPrevFree := prevFree := 0.
	manager allOldSpaceEntitiesForCoalescingFrom: manager firstObject do:
		[:o|
		 self assert: (firstFreeChunk = 0 or: [manager isFreeObject: firstFreeChunk]).
		 (manager isMarked: o)
			ifTrue: "forwarders should have been followed in markAndTrace:"
				[self assert: (manager isForwarded: o) not.
				 manager setIsMarkedOf: o to: false. "this will unmark bridges. undo the damage in notePinned:"
				 (manager isPinned: o) ifTrue:
					[manager segmentManager notePinned: o]]
			ifFalse: "unmarked; two cases, an unreachable object or a free chunk."
				[| here |
				 self assert: (manager isRemembered: o) not. "scavenger should have cleared this above"
				 here := manager coallesceFreeChunk: o.
				 manager setObjectFree: here.
				 self inSortedFreeListLink: prevFree to: here given: prevPrevFree.
				 prevPrevFree := prevFree.
				 prevFree := here]].
	prevFree ~= firstFreeChunk ifTrue:
		[manager storePointer: manager freeChunkNextIndex
			ofFreeChunk: prevFree
			withValue: prevPrevFree].
	lastFreeChunk := prevFree.
	self inSortedFreeListLink: lastFreeChunk to: 0 given: prevPrevFree.
	self assert: self checkTraversableSortedFreeList
]

{ #category : #compaction }
SpurPigCompactor >> inSortedFreeListLink: freeChunk to: nextFree given: prevFree [
	 "Doubly-link the free chunk in address order through the freeChunkNextIndex field using the
	  xor trick to use only one field, see e.g.
		The Art of Computer Programming, Vol 1, D.E. Knuth, 3rd Ed, Sec 2.2.4 `Circular Lists', exercise. 18
		http://en.wikipedia.org/wiki/XOR_linked_list."
	freeChunk = 0
		ifTrue:
			[firstFreeChunk := nextFree]
		ifFalse:
			[manager storePointer: manager freeChunkNextIndex
				ofFreeChunk: freeChunk
				withUncheckedValue: (prevFree bitXor: nextFree)]
]

{ #category : #initialization }
SpurPigCompactor >> manager: aSpurNBitMMXEndianSimulator [
	<doNotGenerate>
	manager := aSpurNBitMMXEndianSimulator.
	aSpurNBitMMXEndianSimulator coInterpreter ifNotNil:
		[:coint| coInterpreter := coint].
	aSpurNBitMMXEndianSimulator scavenger ifNotNil:
		[:scav| scavenger := scav]
]

{ #category : #compaction }
SpurPigCompactor >> moveARunOfObjectsStartingAt: startAddress upTo: limit [ 
	"Move the sequence of movable objects starting at startAddress.  Answer the start
	 of the next sequence of movable objects after a possible run of unmovable objects,
	 or the limit, if there are no more movable objects, or 0 if no more compaction can be
	 done. Compaction is done when the search through the freeList has reached the
	 address from which objects are being moved from.

	 There are two broad cases to be dealt with here.  One is a run of smallish objects
	 that can easily be moved into free chunks.  The other is a large object that is unlikely
	 to fit in the typical free chunk. This second pig needs careful handling; it needs to be
	 moved to the lowest place it will fit and not cause the scan to skip lots of smaller
	 free chunks looking in vain for somewhere to put it."
	<var: #startAddress type: #usqInt>
	<var: #limit type: #usqInt>
	<inline: false>
	| here hereObj hereObjHeader prevPrevFreeChunk prevFreeChunk thisFreeChunk maxFreeChunk |
	<var: #here type: #usqInt>
	<var: #there type: #usqInt>
	<var: #nextFree type: #usqInt>
	<var: #endOfFree type: #usqInt>
	<var: #destination type: #usqInt>
	<var: #maxFreeChunk type: #usqInt>
	here := startAddress.
	hereObj := manager objectStartingAt: startAddress.
	hereObjHeader := manager atLeastClassIndexHalfHeader: hereObj.
	prevPrevFreeChunk := prevFreeChunk := 0.
	thisFreeChunk := maxFreeChunk := firstFreeChunk.
	[thisFreeChunk ~= 0] whileTrue:
		[| freeBytes endOfFree nextFree destination there moved |

		 "skip any initial immobile objects"
		 [(manager isMobileObjectHeader: hereObjHeader)] whileFalse:
			[here := manager addressAfter: hereObj.
			 here >= limit ifTrue:
				[^maxFreeChunk >= startAddress ifTrue: [0] ifFalse: [limit]].
			 hereObj := manager objectStartingAt: here.
			 hereObjHeader := manager atLeastClassIndexHalfHeader: hereObj].

		 "grab a free chunk, and the following one, because we want to overwrite this one."
		 self assert: ((manager isFreeObject: firstFreeChunk) and: [manager isFreeObject: thisFreeChunk]).
		 freeBytes		:= manager bytesInObject: thisFreeChunk.
		 nextFree		:= self nextInSortedFreeListLink: thisFreeChunk given: prevFreeChunk.
		 destination	:= manager startOfObject: thisFreeChunk.
		 endOfFree		:= destination + freeBytes.
		 moved			:= false.
		 maxFreeChunk	:= maxFreeChunk max: nextFree.
		 self assert: (nextFree = 0 or: [manager isFreeObject: nextFree]).

		"move as many objects as will fit in freeBytes..."
		 [there := manager addressAfter: hereObj.
		  "N.B. *must* add allocationUnit, not subtract, to avoid unsigned arithmetic issues when freeBytes = 0"
		  (manager isMobileObjectHeader: hereObjHeader)
		  and: [freeBytes > (there - here + manager allocationUnit)
			    or: [freeBytes = (there - here)]]] whileTrue:
			[moved := true.
			 manager mem: destination asVoidPointer cp: here asVoidPointer y: there - here.
			 manager forwardUnchecked: hereObj to: destination + (hereObj - here).
			 destination := destination + (there - here).
			 freeBytes := freeBytes - (there - here).
			 hereObj := manager objectStartingAt: there.
			 here := there.
			 hereObjHeader := manager atLeastClassIndexHalfHeader: hereObj].

		 moved
			ifTrue: "we did overwrite it; we need to repair the free list"
				[| nextNextFree |
				 nextFree ~= 0 ifTrue:
					[nextNextFree  := self nextInSortedFreeListLink: nextFree given: thisFreeChunk.
					 self assert: (manager isFreeObject: nextFree)].
				 (destination > thisFreeChunk "if false couldn't move anything"
				  and: [destination < endOfFree]) "if false, filled entire free chunk"
					ifTrue:
						[thisFreeChunk := manager initFreeChunkWithBytes: endOfFree - destination at: destination.
						 self inSortedFreeListLink: prevFreeChunk to: thisFreeChunk given: prevPrevFreeChunk.
						 self inSortedFreeListLink: thisFreeChunk to: nextFree given: prevFreeChunk.
						 nextFree ~= 0 ifTrue:
							[self inSortedFreeListLink: nextFree to: nextNextFree given: thisFreeChunk].
						 prevPrevFreeChunk := prevFreeChunk.
						 prevFreeChunk := thisFreeChunk.
						 thisFreeChunk := nextFree]
					ifFalse:
						[self inSortedFreeListLink: prevFreeChunk to: nextFree given: prevPrevFreeChunk.
						 nextFree ~= 0 ifTrue:
							[self inSortedFreeListLink: nextFree to: nextNextFree given: prevFreeChunk].
						 thisFreeChunk := nextFree]]
			ifFalse: "out of space (or immobile object); move on up the free list..."
				[prevPrevFreeChunk := prevFreeChunk.
				 prevFreeChunk := thisFreeChunk.
				 thisFreeChunk := nextFree].

		 (manager isMobileObjectHeader: hereObjHeader) ifFalse:
			[^maxFreeChunk >= startAddress ifTrue: [0] ifFalse: [there]].

		 "Was the loop stopped by a pig? If so, try and find space for it"
		 there - here >= (manager averageObjectSizeInBytes * 8) ifTrue: "256b in 32 bit, 512b in 64 bit"
			[| usedChunk |
			 usedChunk := self tryToMovePig: hereObj at: here end: there.
			"if it couldn't be moved we need to advance, so always
			 set here to there whether the pig was moved or not."
			 hereObj := manager objectStartingAt: there.
			 here := there.
			 hereObjHeader := manager atLeastClassIndexHalfHeader: hereObj.
			 "In general it's a bad idea to reset the enumeration; it leads to N^2 behaviour
			  when encountering pigs.  But if the move affected the enumeration this is
			  simpler than resetting the list pointers."
			 (usedChunk = prevPrevFreeChunk
			  or: [usedChunk = prevFreeChunk
			  or: [usedChunk = thisFreeChunk]]) ifTrue:
				["reset the scan for free space back to the start of the list"
				 prevPrevFreeChunk := prevFreeChunk := 0.
				 thisFreeChunk := firstFreeChunk]].

		((here > startAddress and: [there >= limit])
		 or: [maxFreeChunk >= startAddress]) ifTrue:
			[^maxFreeChunk >= startAddress ifTrue: [0] ifFalse: [there]]].
	^here
]

{ #category : #compaction }
SpurPigCompactor >> nextInSortedFreeListLink: freeChunk given: prevFree [
	 "Answer the next free free chunk using the xor trick to use only one field, see e.g.
		The Art of Computer Programming, Vol 1, D.E. Knuth, 3rd Ed, Sec 2.2.4 `Circular Lists', exercise. 18
		http://en.wikipedia.org/wiki/XOR_linked_list."
	<inline: true>
	^((manager fetchPointer: manager freeChunkNextIndex ofFreeChunk: freeChunk) bitXor: prevFree) asUnsignedInteger
]

{ #category : #'compaction - asserts' }
SpurPigCompactor >> noForwardersBelowFirstFreeChunk [
	manager allOldSpaceEntitiesDo:
		[:o|
		 (self oop: o isGreaterThanOrEqualTo: firstFreeChunk) ifTrue:
			[^true].
		 (manager isForwarded: o) ifTrue:
			[^false]].
	^true
]

{ #category : #compaction }
SpurPigCompactor >> pigCompact [
	"Traverse the sorted free list, moving objects from the high-end of
	 memory to the free objects in the low end of memory.  Return when
	 the address at which objects are being copied to meets the address
	 from which objects are being copied from."
	self cCode: '' inSmalltalk: [coInterpreter transcript nextPutAll: 'pig compacting...'; flush].
	self sortedFreeListPairwiseReverseDo:
		[:low :high| | scanAddress |
		 self cCode: '' inSmalltalk: [coInterpreter transcript nextPut: $.; flush].
		 scanAddress := manager addressAfter: low.
		 [self oop: scanAddress isLessThan: high] whileTrue:
			[scanAddress := self moveARunOfObjectsStartingAt: scanAddress upTo: high.
			 scanAddress = 0 ifTrue:
				[^self]]].
	self assert: self checkTraversableSortedFreeList
]

{ #category : #'debug printing' }
SpurPigCompactor >> printSortedFreeList [
	<api>
	| freeChunk prevFree nextFree |
	(firstFreeChunk > 0 and: [lastFreeChunk > firstFreeChunk]) ifFalse:
		[coInterpreter print: 'sorted free list empty or corrupt'; cr.
		 ^self].
	freeChunk := firstFreeChunk.
	prevFree := 0.
	[((manager addressCouldBeObj: freeChunk)
	 and: [manager isFreeObject: freeChunk]) ifFalse:
		[coInterpreter printHexnp: freeChunk; print: ' is not a free chunk!' ; cr.
		 ^self].
	 manager printFreeChunk: freeChunk printAsTreeNode: false.
	 freeChunk ~= lastFreeChunk] whileTrue:
		[nextFree := self nextInSortedFreeListLink: freeChunk given: prevFree.
		 prevFree := freeChunk.
		 freeChunk := nextFree]
]

{ #category : #'debug support' }
SpurPigCompactor >> printTheBogons: aBogon [
	<inline: true>
	coInterpreter
		print: 'bogon '; printHexnp: aBogon; cr
]

{ #category : #compaction }
SpurPigCompactor >> rebuildFreeListsForPigCompact [
	"Rebuild the free lists from the doubly-linked free list."
	<inline: false>
	self assert: self checkTraversableSortedFreeList.
	manager totalFreeOldSpace: 0.
	self sortedFreeListDo:
		[:freeObj| | start bytes |
		 bytes := (manager bytesInObject: freeObj).
		 start := manager startOfObject: freeObj.
		 manager addFreeChunkWithBytes: bytes at: start].
	manager checkFreeSpace: GCModeFull
]

{ #category : #'gc - scavenge/compact' }
SpurPigCompactor >> remapObj: objOop [
	"Scavenge or simply follow objOop.  Answer the new location of objOop.
	 The send should have been guarded by a send of shouldRemapOop:.
	 The method is called remapObj: for compatibility with ObjectMemory."
	<api>
	<inline: false>
	^manager vanillaRemapObj: objOop
]

{ #category : #'gc - scavenge/compact' }
SpurPigCompactor >> shouldRemapObj: objOop [
	<api>
	"Answer if the obj should be scavenged (or simply followed). The method is called
	 shouldRemapObj: for compatibility with ObjectMemory.  Defer to the compactor
	 to choose the actual test, there being a difference between the vanilla test and
	 that used with a sliding compactor where objects are not marked as forwarded."
	^manager vanillaShouldRemapObj: objOop
]

{ #category : #compaction }
SpurPigCompactor >> sortedFreeListDo: aBlock [
	"Evaluate aBlock with ascending entries in the free list"
	| free nextFree prevFree prevPrevFree |
	<var: #free type: #usqInt>
	<var: #nextFree type: #usqInt>
	<var: #prevFree type: #usqInt>
	<var: #prevPrevFree type: #usqInt>
	<inline: true>
	free := firstFreeChunk.
	prevPrevFree := prevFree := 0.
	[free ~= 0] whileTrue:
		[nextFree := self nextInSortedFreeListLink: free given: prevFree.
		 self assert: (manager isFreeObject: free).
		 self assert: (nextFree = 0 or: [nextFree > free and: [manager isFreeObject: nextFree]]).
		 self assert: (prevFree = 0 or: [prevFree < free]).
	 	 aBlock value: free.
		 prevPrevFree := prevFree.
		 prevFree := free.
		 free := nextFree]
]

{ #category : #compaction }
SpurPigCompactor >> sortedFreeListPairwiseReverseDo: aBinaryBlock [
	"Evaluate aBinaryBlock with adjacent entries in the free list, from
	 high address to low address.  The second argument is in fact the
	 start of the next free chunk, not the free chunk itself.  Use
	 endOfMemory - bridgeSize as the second argument in the first evaluation."
	| free prevFree prevPrevFree |
	<var: #free type: #usqInt>
	<var: #prevFree type: #usqInt>
	<var: #prevPrevFree type: #usqInt>
	<inline: true>
	free := lastFreeChunk.
	prevPrevFree := prevFree := 0.
	[free ~= 0] whileTrue:
		[aBinaryBlock value: free value: (prevFree = 0
											ifTrue: [manager endOfMemory - manager bridgeSize]
											ifFalse: [manager startOfObject: prevFree]).
		 "post evaluation of aBinaryBlock the value of free may be invalid
		  because moveARunOfObjectsStartingAt:upTo: may have filled it.
		  So reconstruct the position in the enumeration."
		 prevFree = 0
			ifTrue:
				[self assert: free = lastFreeChunk.
				 prevFree := lastFreeChunk.
				 free := self nextInSortedFreeListLink: lastFreeChunk given: 0]
			ifFalse:
				[self assert: (manager isFreeObject: prevFree).
				 prevPrevFree = 0
					ifTrue:
						[prevPrevFree := lastFreeChunk.
						 prevFree := self nextInSortedFreeListLink: lastFreeChunk given: 0]
					ifFalse:
						[self assert: (manager isFreeObject: prevPrevFree).
						 free := self nextInSortedFreeListLink: prevFree given: prevPrevFree.
						 prevPrevFree := prevFree.
						 prevFree := free].
				 free := self nextInSortedFreeListLink: prevFree given: prevPrevFree]]
]

{ #category : #compaction }
SpurPigCompactor >> sweepToCoallesceFreeSpaceForPigCompactFrom: lowestForwarder [
	"Coallesce free chunks and forwarders, maintaining the doubly-linked free list."
	| lowest firstOfFreeRun startOfFreeRun endOfFreeRun prevPrevFree prevFree |
	<var: #lowestForwarder type: #usqInt>
	lowest := (lowestForwarder = 0 ifTrue: [manager endOfMemory] ifFalse: [lowestForwarder])
				min: (firstFreeChunk = 0 ifTrue: [manager endOfMemory] ifFalse: [firstFreeChunk]).
	firstOfFreeRun := prevPrevFree := prevFree := 0.
	manager allOldSpaceEntitiesFrom: lowest do:
		[:o|
		((manager isFreeObject: o) or: [manager isForwarded: o])
			ifTrue:
				[firstOfFreeRun = 0 ifTrue:
					[manager setObjectFree: o.
					 firstOfFreeRun := o.
					 startOfFreeRun := manager startOfObject: o].
				 endOfFreeRun := o]
			ifFalse:
				[firstOfFreeRun ~= 0 ifTrue:
					[| bytes |
					 bytes := (manager addressAfter: endOfFreeRun) - startOfFreeRun.
					 firstOfFreeRun := manager initFreeChunkWithBytes: bytes at: startOfFreeRun.
					 self inSortedFreeListLink: prevFree to: firstOfFreeRun given: prevPrevFree.
					 prevPrevFree := prevFree.
					 prevFree := firstOfFreeRun.
					 firstOfFreeRun := 0]]].
	firstOfFreeRun ~= 0 ifTrue:
		[| bytes |
		 bytes := (manager addressAfter: endOfFreeRun) - startOfFreeRun.
		 firstOfFreeRun := manager initFreeChunkWithBytes: bytes at: startOfFreeRun.
		 self inSortedFreeListLink: prevFree to: firstOfFreeRun given: prevPrevFree.
		 prevPrevFree := prevFree.
		 prevFree := firstOfFreeRun.
		 firstOfFreeRun := 0].
	prevFree ~= firstFreeChunk ifTrue:
		[manager storePointer: manager freeChunkNextIndex
			ofFreeChunk: prevFree
			withValue: prevPrevFree].
	lastFreeChunk := prevFree.
	self inSortedFreeListLink: lastFreeChunk to: 0 given: prevPrevFree.
	self assert: self checkTraversableSortedFreeList
]

{ #category : #compaction }
SpurPigCompactor >> sweepToFollowForwardersForPigCompact [
	"Sweep, following forwarders in all live objects.
	 Answer the lowest forwarder in oldSpace."
	| lowestForwarder |
	<var: #lowestForwarder type: #usqInt>
	self assert: (manager freeStart = scavenger eden start
				  and: [scavenger futureSurvivorStart = scavenger futureSpace start]).
	manager allPastSpaceObjectsDo:
		[:o|
		(manager isForwarded: o) ifFalse:
			[0 to: (manager numPointerSlotsOf: o) - 1 do:
				[:i| | f |
				f := manager fetchPointer: i ofObject: o.
				(manager isOopForwarded: f) ifTrue:
					[f := manager followForwarded: f.
					 manager storePointerUnchecked: i ofObject: o withValue: f]]]].
	lowestForwarder := 0.
	manager allOldSpaceObjectsDo:
		[:o|
		(manager isForwarded: o)
			ifTrue:
				[lowestForwarder = 0 ifTrue:
					[lowestForwarder := o]]
			ifFalse:
				[0 to: (manager numPointerSlotsOf: o) - 1 do:
					[:i| | f |
					f := manager fetchPointer: i ofObject: o.
					(manager isOopForwarded: f) ifTrue:
						[f := manager followForwarded: f.
						 manager storePointer: i ofObject: o withValue: f]]]].
	^lowestForwarder
]

{ #category : #compaction }
SpurPigCompactor >> tryToMovePig: pigObj at: pigStart end: pigEnd [
	"Try to move a pig (a largish object) to a free chunk in low memory.
	 Answer the freeChunk that was used to house the moved pig, or
	 0 if no free chunk could be found."
	| freeChunk prevFree prevPrevFree pigBytes nextNext |
	prevPrevFree := prevFree := 0.
	freeChunk := firstFreeChunk.
	pigBytes := pigEnd - pigStart.
	[freeChunk ~= 0 and: [freeChunk < pigObj]] whileTrue:
		[| next dest chunkBytes newChunk |
		 next			:= self nextInSortedFreeListLink: freeChunk given: prevFree.
		 dest			:= manager startOfObject: freeChunk.
		 chunkBytes	:= (manager addressAfter: freeChunk) - dest.
		 "N.B. *must* add allocationUnit, not subtract, to avoid unsigned arithmetic issues when chunkBytes = 0"
		 (chunkBytes = pigBytes
		  or: [chunkBytes > (pigBytes + manager allocationUnit)]) ifTrue:
			[manager mem: dest asVoidPointer cp: pigStart asVoidPointer y: pigBytes.
			 manager forwardUnchecked: pigObj to: dest + (pigObj - pigStart).
			 next ~= 0 ifTrue:
				[nextNext  := self nextInSortedFreeListLink: next given: freeChunk].
			 "now either shorten the chunk, or remove it, adjusting the links to keep the list sorted."
			 pigBytes < chunkBytes "if false, filled entire free chunk"
				ifTrue:
					[newChunk := manager initFreeChunkWithBytes: chunkBytes - pigBytes at: dest + pigBytes.
					 self inSortedFreeListLink: prevFree to: newChunk given: prevPrevFree.
					 self inSortedFreeListLink: newChunk to: next given: prevFree.
					 next ~= 0 ifTrue:
						[self inSortedFreeListLink: next to: nextNext given: newChunk]]
				ifFalse:
					[self inSortedFreeListLink: prevFree to: next given: prevPrevFree.
					 next ~= 0 ifTrue:
						[self inSortedFreeListLink: next to: nextNext given: prevFree]].
			 "self checkTraversableSortedFreeList".
			 ^freeChunk].
		 prevPrevFree := prevFree.
		 prevFree := freeChunk.
		 freeChunk := next].
	^0
]
