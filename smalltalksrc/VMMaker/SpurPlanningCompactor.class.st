"
SpurPlanningCompactor implements the classic planning compaction algorithm for Spur.  It makes at least three passes through the heap.  The first pass plans where live movable objects will go, copying their forwarding field to the next slot in savedFirstFieldsSpace, and setting their forwarding pointer to point to their eventual location.  The second pass updates all pointers in live pointer objects to point to objects' final destinations.  The third pass moves objects to their final positions, unmarking objects as it does so.  If the forwarding fields of live objects in the to-be-moved portion of the entire heap won't fit in savedFirstFieldsSpace, then additional passes are made until the entire heap has been compacted.

Instance Variables
	biasForGC						<Boolean>
	coInterpreter:					<StackInterpreter>
	firstFieldOfRememberedSet		<Oop>
	firstFreeObject					<Oop>
	firstMobileObject				<Oop>
	lastMobileObject				<Oop>
	manager:						<SpurMemoryManager>
	savedFirstFieldsSpace				<SpurContiguousObjStack>
	savedFirstFieldsSpaceWasAllocated	<Boolean>
	scavenger:						<SpurGenerationScavenger>

biasForGC
	- true if compacting for GC, in which case do only one pass, or false if compacting for snapshot, in which case do as many passes as necessary to compact the entire heap.

firstFieldOfRememberedSet
	- the saved first field of the rememberedSet.  The rememberedSet must be relocated specially because it is not a pointer object.  And hence the first field needs to be extracted for proper relocation.

firstFreeObject
	- the first free object in a compaction pass.

firstMobileObject
	- the first mobile object in a compaction.  Unpinned objects from the firstMobileObject through to the lastMobileObject are implicitly forwarded.

lastMobileObject
	- the last mobile object in a compaction.  Unpinned objects from the firstMobileObject through to the lastMobileObject are implicitly forwarded.

savedFirstFieldsSpace
	- the space holding the saved first fields, each overwritten by a forwarding pointer, for the objects from firstMobileObject through to lastMobileObject.

savedFirstFieldsSpaceWasAllocated
	- if true, the memory for savedFirstFieldsSpace was obtained via a call of sqAllocateMemorySegmentOfSize:Above:AllocatedSizeInto:
"
Class {
	#name : #SpurPlanningCompactor,
	#superclass : #CogClass,
	#instVars : [
		'manager',
		'scavenger',
		'coInterpreter',
		'biasForGC',
		'firstFreeObject',
		'firstMobileObject',
		'lastMobileObject',
		'savedFirstFieldsSpace',
		'savedFirstFieldsSpaceWasAllocated',
		'firstFieldOfRememberedSet'
	],
	#pools : [
		'SpurMemoryManagementConstants',
		'VMBasicConstants',
		'VMBytecodeConstants',
		'VMSpurObjectRepresentationConstants'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurPlanningCompactor class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator var: 'savedFirstFieldsSpace' type: #SpurContiguousObjStack
]

{ #category : #translation }
SpurPlanningCompactor class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #'compaction - api' }
SpurPlanningCompactor >> biasForGC [
	biasForGC := true
]

{ #category : #'compaction - api' }
SpurPlanningCompactor >> biasForSnapshot [
	biasForGC := false
]

{ #category : #'instance initialization' }
SpurPlanningCompactor >> coInterpreter: aVMSimulator [
	<doNotGenerate>
	coInterpreter := aVMSimulator
]

{ #category : #'compaction - api' }
SpurPlanningCompactor >> compact [
	"Sweep all of old space, sliding unpinned marked objects down over free and unmarked objects.
	 Let the segmentManager mark which segments contain pinned objects via notePinned:."
	| onePass |
	<inline: #never> "for profiling"
	self initializeScanCheckingForFullyCompactedHeap ifTrue:
		[^self unmarkObjectsInFullyCompactedHeap].
	self initializeCompaction.
	[onePass := self planCompactSavingForwarders.
	 self updatePointers.
	 self copyAndUnmark.
	 manager checkFreeSpace: GCModeFull.
	 onePass or: [biasForGC]] whileFalse:
		[self reinitializeScan;
			updateSavedFirstFieldsSpaceIfNecessary].
	self endCompaction
]

{ #category : #compaction }
SpurPlanningCompactor >> continueCopyAndUnmarkMobileObjectsFrom: anUnpinnedEntity withTop: top [
	"copyAndUnmarkMobileObjects has encountered a run of pinned objects around which
	 it cannot compact, but savedFirstFieldsSpace is still not full.  Continue the pass with a
	 new firstFreeObject, resetting it before continuing.
	 Answer if the end of the heap was reached (savedFirstFieldsSpace has not overflowed)."
	| result savedFirstFreeObject savedFirstMobileObject nextFreeObject |
	self assert: (self oop: anUnpinnedEntity isLessThan: manager endOfMemory).
	self deny: (manager isPinned: anUnpinnedEntity).
	savedFirstFreeObject := firstFreeObject.
	savedFirstMobileObject := firstMobileObject.
	nextFreeObject := self scanForFirstFreeAndFirstMobileObjectFrom: anUnpinnedEntity.
	firstMobileObject := savedFirstMobileObject.
	nextFreeObject ifNil:
		[^true].
	firstFreeObject := nextFreeObject.
	result := self copyAndUnmarkMobileObjectsWithTop: top.
	firstFreeObject := savedFirstFreeObject.
	^result
]

{ #category : #compaction }
SpurPlanningCompactor >> continuePlanCompactSavingForwardersFrom: anUnpinnedEntity [
	"planCompactSavingForwarders has encountered a run of pinned objects around which
	 it cannot compact, but savedFirstFieldsSpace is still not full.  Continue the pass with a
	 new firstFreeObject, resetting it before continuing.
	 Answer if the end of the heap was reached (savedFirstFieldsSpace has not overflowed)."
	| result savedFirstFreeObject savedFirstMobileObject nextFreeObject |
	self assert: (self oop: anUnpinnedEntity isLessThan: manager endOfMemory).
	self deny: (manager isPinned: anUnpinnedEntity).
	savedFirstFreeObject := firstFreeObject.
	savedFirstMobileObject := firstMobileObject.
	nextFreeObject := self scanForFirstFreeAndFirstMobileObjectFrom: anUnpinnedEntity.
	firstMobileObject := savedFirstMobileObject.
	nextFreeObject ifNil:
		[^true].
	firstFreeObject := nextFreeObject.
	result := self planCompactSavingForwarders.
	firstFreeObject := savedFirstFreeObject.
	^result
]

{ #category : #compaction }
SpurPlanningCompactor >> continueUpdatePointersInMobileObjectsFrom: anUnpinnedEntity withTop: top [
	"updatePointersInMobileObjects has encountered a run of pinned objects around which
	 planCompactSavingForwarders cannot compact, but savedFirstFieldsSpace is still not full.
	 Continue the pass with a new firstFreeObject , resetting it before continuing.
	 Answer if the end of the heap was reached (savedFirstFieldsSpace has not overflowed)."
	| result savedFirstFreeObject savedFirstMobileObject nextFreeObject |
	self assert: (self oop: anUnpinnedEntity isLessThan: manager endOfMemory).
	self deny: (manager isPinned: anUnpinnedEntity).
	savedFirstFreeObject := firstFreeObject.
	savedFirstMobileObject := firstMobileObject.
	nextFreeObject := self scanForFirstFreeAndFirstMobileObjectFrom: anUnpinnedEntity.
	firstMobileObject := savedFirstMobileObject.
	nextFreeObject ifNil:
		[^true].
	firstFreeObject := nextFreeObject.
	result := self updatePointersInMobileObjectsWithTop: top.
	firstFreeObject := savedFirstFreeObject.
	^result
]

{ #category : #compaction }
SpurPlanningCompactor >> copyAndUnmark [
	"Sweep the heap, unmarking all objects and moving mobile objects to their correct positions,
	 restoring their savedFirstFields."
	| onePass |
	self logPhase: 'copying and unmarking...'.
	self unmarkInitialImmobileObjects.
	"If savedFirstFieldsSpace is empty there is nothing to move, and no second pass."
	savedFirstFieldsSpace top < savedFirstFieldsSpace start ifTrue:
		[self assert: firstMobileObject >= manager endOfMemory.
		 ^self].
	onePass := self copyAndUnmarkMobileObjectsWithTop: savedFirstFieldsSpace start - manager bytesPerOop.
	onePass ifFalse:
		[self unmarkObjectsOverflowingSavedFirstFieldsSpace]
]

{ #category : #compaction }
SpurPlanningCompactor >> copyAndUnmarkMobileObjectsWithTop: initialTop [
	"Sweep the mobile portion of the heap, moving objects to their eventual locations, and clearing their marked bits.
	 Remember to update the savedFirstFields of pointer objects, as these have been forwarded.
	 This enumeration matches those in planCompactSavingForwarders and updatePointersInMobileObjects."

	| toFinger top previousPin |
	toFinger := manager startOfObject: firstFreeObject.
	top := initialTop.
	self deny: (manager isMarked: firstFreeObject).
	manager allOldSpaceEntitiesForCompactingFrom: firstFreeObject do:
		[:o| | availableSpace |
		 self assert: (previousPin isNil or: [toFinger < previousPin]).
		 (manager isMarked: o) ifTrue:
			[(manager isPinned: o)
				ifTrue:
					[(manager isSegmentBridge: o) ifFalse:
						[manager setIsMarkedOf: o to: false.
						 manager segmentManager notePinned: o].
					 previousPin ifNotNil:
						[| limit |
						 limit := manager startOfObject: previousPin.
						 manager addFreeChunkWithBytes: limit - toFinger at: toFinger.
						 toFinger := manager addressAfter: previousPin.
						 self assert: toFinger < (manager startOfObject: o)].
					 previousPin := o]
				ifFalse:
					[| bytes next |
					 (top := top + manager bytesPerOop) >= savedFirstFieldsSpace limit ifTrue:
						[self freeFrom: toFinger upTo: (manager startOfObject: o) previousPin: previousPin.
						 ^false].
					 [previousPin notNil
					  and: [availableSpace := (manager startOfObject: previousPin) - toFinger.
							bytes := manager bytesInObject: o.
							bytes ~= availableSpace
							 and: [bytes + (2 * manager allocationUnit) < availableSpace]]] whileTrue:
						["The object does not fit in the space between toFinger and previousPin.
						  Move toFinger beyond previousPin and update previousPin appropriately."
						 availableSpace > 0 ifTrue:
							[manager addFreeChunkWithBytes: availableSpace at: toFinger].
						 toFinger := manager addressAfter: previousPin.
						 next := manager objectStartingAt: toFinger.
						 next >= o ifTrue:
							[^self continueCopyAndUnmarkMobileObjectsFrom: next withTop: top].
						 previousPin := (manager isPinned: next) ifTrue: [next]].
					 bytes := self copyAndUnmarkObject: o to: toFinger firstField: (manager longAt: top).
					 toFinger := toFinger + bytes]]].
	self freeFrom: toFinger upTo: manager endOfMemory previousPin: previousPin.
	^true
]

{ #category : #compaction }
SpurPlanningCompactor >> copyAndUnmarkObject: o to: toFinger firstField: firstField [
	"Copy the object to toFinger, clearing its mark bit and restoring its firstField, which was overwritten with a forwarding pointer.
	 Answer the number of bytes in the object, including overflow header."
	<inline: true>
	| bytes numSlots destObj start |
	numSlots := manager rawNumSlotsOf: o.
	destObj := (manager objectWithRawSlotsHasOverflowHeader: numSlots)
					ifTrue: [toFinger + manager baseHeaderSize]
					ifFalse: [toFinger].
	bytes := manager bytesInObject: o given: numSlots.
	start := manager startOfObject: o given: numSlots.
	manager
		mem: toFinger asVoidPointer cp: start asVoidPointer y: bytes;
		setIsMarkedOf: destObj to: false;
		storePointerUnchecked: 0 ofObject: destObj withValue: firstField.
	^bytes
]

{ #category : #compaction }
SpurPlanningCompactor >> endCompaction [
	manager
		unmarkSurvivingObjectsForCompact;
		endSlidingCompaction.
	self repinRememberedSet.
	self releaseSavedFirstFieldsSpace
]

{ #category : #'space management' }
SpurPlanningCompactor >> findHighestSuitableFreeBlock: spaceEstimate [
	"If a freeBlock of size at least spaceEstimate exists high enough in the heap, choose it."
	<inline: true>
	manager findLargestFreeChunk ifNotNil:
		[:largestFreeChunk|
		(manager bytesInObject: largestFreeChunk) >= spaceEstimate ifTrue:
			[^largestFreeChunk]].
	^nil
]

{ #category : #private }
SpurPlanningCompactor >> firstUnpinnedObjectFollowing: pinnedObj [
	| nextObj |
	self assert: (manager isPinned: pinnedObj).
	nextObj := pinnedObj.
	[nextObj := manager objectAfter: nextObj limit: manager endOfMemory.
	 nextObj >= manager endOfMemory ifTrue:
		[^manager endOfMemory].
	 manager isPinned: nextObj] whileTrue.
	^nextObj
]

{ #category : #private }
SpurPlanningCompactor >> freeFrom: toFinger upTo: limit previousPin: previousPinOrNil [
	"Free from toFinger up to limit, dealing with a possible intervening run of pinned objects starting at previousPinOrNil."
	| effectiveToFinger firstUnpinned |
	self cCode: [] inSmalltalk:
		[coInterpreter cr; cr; print: 'freeing at '; printHexnp: toFinger; print: ' up to '; printHexnp: limit; print: ' pin '; printHexnp: previousPinOrNil; cr].
	effectiveToFinger := toFinger.
	previousPinOrNil ifNotNil:
		[manager addFreeChunkWithBytes: (manager startOfObject: previousPinOrNil) - toFinger at: toFinger.
		 firstUnpinned := self firstUnpinnedObjectFollowing: previousPinOrNil.
		 firstUnpinned >= limit ifTrue:
			[^self].
		 effectiveToFinger := manager startOfObject: firstUnpinned].
	manager addFreeChunkWithBytes: limit - effectiveToFinger at: effectiveToFinger
]

{ #category : #'instance initialization' }
SpurPlanningCompactor >> initialize [
	biasForGC := true.
	savedFirstFieldsSpace := SpurContiguousObjStack new.
	savedFirstFieldsSpaceWasAllocated := false
]

{ #category : #compaction }
SpurPlanningCompactor >> initializeCompaction [
	manager checkFreeSpace: GCModeFull.
	self selectSavedFirstFieldsSpace.
	self unpinRememberedSet.
	manager
		resetFreeListHeads;
		totalFreeOldSpace: 0;
		beginSlidingCompaction.
	savedFirstFieldsSpace top: savedFirstFieldsSpace start - manager bytesPerOop
]

{ #category : #compaction }
SpurPlanningCompactor >> initializeScanCheckingForFullyCompactedHeap [
	"Scan for firstFreeObject and firstMobileObject from the start of memory.
	 Answer if the heap is already fully compacted."
	firstFreeObject := manager hiddenRootsObject.
	self reinitializeScan.
	^firstMobileObject >= manager endOfMemory
]

{ #category : #private }
SpurPlanningCompactor >> isMobile: obj [
	<inline: true>
	^(self oop: obj isGreaterThanOrEqualTo: firstMobileObject andLessThanOrEqualTo:  lastMobileObject)
	 and: [(manager isPinned: obj) not]
]

{ #category : #private }
SpurPlanningCompactor >> isPostMobile: obj [
	"For asserts"
	^self oop: obj isGreaterThanOrEqualTo: firstFreeObject andLessThanOrEqualTo:  lastMobileObject
]

{ #category : #private }
SpurPlanningCompactor >> logPhase: phaseName [
	<inline: true>
	self cCode: '' inSmalltalk: [coInterpreter transcript nextPutAll: phaseName; flush].
]

{ #category : #'instance initialization' }
SpurPlanningCompactor >> manager: aSpurNBitMMXEndianSimulator [
	<doNotGenerate>
	manager := aSpurNBitMMXEndianSimulator.
	aSpurNBitMMXEndianSimulator coInterpreter ifNotNil:
		[:coint| coInterpreter := coint].
	aSpurNBitMMXEndianSimulator scavenger ifNotNil:
		[:scav| scavenger := scav]
]

{ #category : #private }
SpurPlanningCompactor >> numPointerSlotsWhileCompactingOf: obj savedFirstFieldPointer: firstFieldPtrOrNil [
	"This is a version of SpurMemoryManager>>numPointerSlotsOf: that deals with the
	 possibility of obj being a CompiledMethod whose header is in savedFirstFieldsSpace.
	 Answer the number of pointer fields in the given object.
	 Works with CompiledMethods, as well as ordinary objects."
	<inline: true>
	| fmt contextSize numLiterals header |
	fmt := manager formatOf: obj.
	fmt <= manager lastPointerFormat ifTrue:
		[(fmt = manager indexablePointersFormat
		  and: [manager isContextNonImm: obj]) ifTrue:
			["contexts end at the stack pointer"
			contextSize := coInterpreter fetchStackPointerOf: obj.
			^CtxtTempFrameStart + contextSize].
		^manager numSlotsOf: obj  "all pointers"].
	self deny: fmt = manager forwardedFormat.
	fmt < manager firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	self assert: firstFieldPtrOrNil notNil == (self isMobile: obj).
	header := firstFieldPtrOrNil
				ifNil: [manager methodHeaderOf: obj]
				ifNotNil: [manager methodHeaderFromSavedFirstField: (manager longAt: firstFieldPtrOrNil)].
	numLiterals := manager literalCountOfMethodHeader: header.
	^numLiterals + LiteralStart
]

{ #category : #private }
SpurPlanningCompactor >> numPointerSlotsWhileCompactingOf: obj withFormat: fmt savedFirstFieldPointer: firstFieldPtrOrNil [
	"This is a version of SpurMemoryManager>>numPointerSlotsOf: that deals with the
	 possibility of obj being a CompiledMethod whose header is in savedFirstFieldsSpace.
	 Answer the number of pointer fields in the given object.
	 Works with CompiledMethods, as well as ordinary objects."
	<inline: true>
	| contextSize numLiterals header |
	fmt <= manager lastPointerFormat ifTrue:
		[(fmt = manager indexablePointersFormat
		  and: [manager isContextNonImm: obj]) ifTrue:
			["contexts end at the stack pointer"
			contextSize := coInterpreter fetchStackPointerOf: obj.
			^CtxtTempFrameStart + contextSize].
		^manager numSlotsOf: obj  "all pointers"].
	self deny: fmt = manager forwardedFormat.
	fmt < manager firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	self assert: firstFieldPtrOrNil notNil == (self isMobile: obj).
	header := firstFieldPtrOrNil
				ifNil: [manager methodHeaderOf: obj]
				ifNotNil: [manager methodHeaderFromSavedFirstField: (manager longAt: firstFieldPtrOrNil)].
	numLiterals := manager literalCountOfMethodHeader: header.
	^numLiterals + LiteralStart
]

{ #category : #compaction }
SpurPlanningCompactor >> planCompactSavingForwarders [
	"Sweep the heap from firstFreeObject forwarding marked objects to where they
	 can be moved to, saving their forwarding pointer in savedFirstFieldsSpace.
	 Continue until either the end of the heap is reached or savedFirstFieldsSpace is full.
	 Answer if the end of the heap was reached (savedFirstFieldsSpace has not overflowed).

	 Note that this method is potentially recursive. If skipping a run of pinned objects
	 causes the the algorithm to encounter another run of immobile objects it will
	 recurse via continuePlanCompactSavingForwardersFrom:.

	 This enumeration matches those in updatePointersInMobileObjects and copyAndUnmarkMobileObjects."

	| toFinger top previousPin |
	savedFirstFieldsSpace top < savedFirstFieldsSpace start ifTrue:
		[self logPhase: 'planning...'].
	toFinger := manager startOfObject: firstFreeObject.
	top := savedFirstFieldsSpace top.
	self deny: (manager isMarked: firstFreeObject).
	manager allOldSpaceEntitiesFrom: firstFreeObject do:
		[:o|
		 self assert: (previousPin isNil or: [toFinger < previousPin]).
		 (manager isMarked: o) ifTrue:
			[(manager isPinned: o)
				ifTrue: "The empty gaps between two adjacent pinned objects (when not filled below) are freed."
					[previousPin ifNotNil:
						[self assert: (manager startOfObject: previousPin) - toFinger >= (manager allocationUnit * 2).
						 toFinger := manager addressAfter: previousPin.
						 self assert: toFinger < (manager startOfObject: o)].
					 previousPin := o]
				ifFalse:
					[| availableSpace bytes next |
					 (top := top + manager bytesPerOop) >= savedFirstFieldsSpace limit ifTrue:
						[savedFirstFieldsSpace top: top.
						 ^false].
					 [previousPin notNil
					  and: [availableSpace := (manager startOfObject: previousPin) - toFinger.
							bytes := manager bytesInObject: o.
							bytes ~= availableSpace
							 and: [bytes + (2 * manager allocationUnit) < availableSpace]]] whileTrue:
						["The object does not fit in the space between toFinger and previousPin.
						  Move toFinger beyond previousPin and update previousPin appropriately."
						 toFinger := manager addressAfter: previousPin.
						 next := manager objectStartingAt: toFinger.
						 next >= o ifTrue:
							[savedFirstFieldsSpace top: top.
							 ^self continuePlanCompactSavingForwardersFrom: next].
						 previousPin := (manager isPinned: next) ifTrue: [next]].
					 lastMobileObject := o.
					 manager
						longAt: top put: (manager fetchPointer: 0 ofObject: o);
					 	storePointerUnchecked: 0 "Don't use forward:to:; we dont want to alter the object in any way other than by setting the forwarding pointer"
							ofObject: o
								withValue: ((manager hasOverflowHeader: o)
											ifTrue: [toFinger + manager baseHeaderSize]
											ifFalse: [toFinger]).
					 toFinger := toFinger + (manager bytesInObject: o)]]].
	savedFirstFieldsSpace top: top.
	^true
]

{ #category : #compaction }
SpurPlanningCompactor >> reinitializeScan [
	firstMobileObject := manager endOfMemory.
	firstFreeObject := self scanForFirstFreeAndFirstMobileObjectFrom: firstFreeObject.
	firstFreeObject ifNil:
		[self error: 'uncompactable heap; no unmarked objects found']
]

{ #category : #'space management' }
SpurPlanningCompactor >> releaseSavedFirstFieldsSpace [
	<inline: true>
	savedFirstFieldsSpaceWasAllocated ifTrue:
		[manager
			sqDeallocateMemorySegmentAt: savedFirstFieldsSpace start asVoidPointer
			OfSize: savedFirstFieldsSpace limit - savedFirstFieldsSpace start.
		 savedFirstFieldsSpaceWasAllocated := false]
]

{ #category : #compaction }
SpurPlanningCompactor >> relocateObjectsInHeapEntity: heapEntity from: startIndex to: finishIndex [
	"Sweep the fields in some non-pointer heap entity (objStackPage, rememberedSet),
	 updating all references to mobile objects to their eventual locations.  Answer the
	 heapEntity's eventual location."
	<inline: true>
	startIndex to: finishIndex do:
		[:i| | oop fwd |
		 oop := manager fetchPointer: i ofObject: heapEntity.
		 ((manager isNonImmediate: oop) and: [self isMobile: oop]) ifTrue:
			[self assert: (manager isMarked: oop).
			 fwd := manager fetchPointer: 0 ofObject: oop.
			 self assert: (self isPostMobile: fwd).
			 manager storePointerUnchecked: i ofObject: heapEntity withValue: fwd]].
	^(self isMobile: heapEntity)
		ifTrue: [manager fetchPointer: 0 ofObject: heapEntity]
		ifFalse: [heapEntity]
]

{ #category : #'gc - scavenge/compact' }
SpurPlanningCompactor >> remapObj: objOop [
	"Scavenge or simply follow objOop.  Answer the new location of objOop.
	 The send should have been guarded by a send of shouldRemapOop:.
	 The method is called remapObj: for compatibility with ObjectMemory."
	<api>
	<inline: false>
	^manager slidingCompactionRemapObj: objOop
]

{ #category : #private }
SpurPlanningCompactor >> repinRememberedSet [
	<inline: true>
	scavenger rememberedSetSize > 0 ifTrue:
		[manager storePointerUnchecked: 0 ofObject: manager rememberedSetObj withValue: firstFieldOfRememberedSet].
	manager setIsPinnedOf: manager rememberedSetObj to: true.
	scavenger relocateRememberedSet
]

{ #category : #compaction }
SpurPlanningCompactor >> scanForFirstFreeAndFirstMobileObjectFrom: initialObject [
	"Scan from initialObject, setting firstMobileObject to the first marked object after
	 the first free object found. Answer the first free object found, or nil if none."
	<inline: false>
	| firstFree |
	manager allOldSpaceEntitiesFrom: initialObject do:
		[:o|
		(manager isMarked: o)
			ifTrue:
				[firstFree ifNotNil:
					[firstMobileObject := o.
					 ^firstFree]]
			ifFalse:
				[firstFree ifNil:
					[firstFree := o]]].
	^firstFree
]

{ #category : #'space management' }
SpurPlanningCompactor >> selectSavedFirstFieldsSpace [
	"To compact the heap the algorithm must save the first field (used for the forwarding pointer)
	 of all moved objects. This is done in savedFirstFieldsSpace, a contiguous block of memory borrowed
	 for the duration of compaction. In a 32-bit system a typical upper bound on the space needed
	 is about 1/40 of the heap size.  The default new space size of 4Mb provides an eden of about
	 3.6 Mb, which would serve the needs of a 144 Mb heap.  The default segment increment of
	 16 Mb would serve the needs of a 640 Mb heap. Make an estimate of the size needed, and
	 either use eden, a large free chunk, or a newly-allocated segment, falling back on eden if
	 the alternatives can't be had."
	<inline: true>
	| spaceEstimate sizeOfEden |
	spaceEstimate := manager endOfMemory - manager firstObject // 40.
	sizeOfEden := scavenger eden limit - scavenger eden start.
	spaceEstimate > sizeOfEden ifTrue:
		[(self findHighestSuitableFreeBlock: spaceEstimate) ifNotNil:
			[:highestSuitableFreeBlock|
			 (spaceEstimate > (manager sizeOfFree: highestSuitableFreeBlock)
			  and: [self useSegmentForSavedFirstFieldsSpace: spaceEstimate]) ifTrue:
				[^self].
			 (manager sizeOfFree: highestSuitableFreeBlock) > sizeOfEden ifTrue:
				[self useFreeChunkForSavedFirstFieldsSpace: highestSuitableFreeBlock.
				 ^self]]].
	self useEdenForSavedFirstFieldsSpace
]

{ #category : #'gc - scavenge/compact' }
SpurPlanningCompactor >> shouldRemapObj: objOop [
	"Answer if the obj should be scavenged, or simply followed. Sent via the compactor
	 from shouldRemapObj:.  We test for being already scavenged because mapStackPages
	 via mapInterpreterOops may be applied twice in the context of a global GC where a
	 scavenge, followed by a scan-mark-free, and final compaction passes may result in
	 scavenged fields being visited twice."
	<api>
	<inline: false>
	^manager slidingCompactionShouldRemapObj: objOop
]

{ #category : #compaction }
SpurPlanningCompactor >> unmarkInitialImmobileObjects [
	"Sweep the initial immobile heap, unmarking all objects up to the first mobile object."
	manager allOldSpaceObjectsFrom: manager firstObject do:
		[:o|
		o >= firstMobileObject ifTrue:
			[^self].
		manager setIsMarkedOf: o to: false]
]

{ #category : #compaction }
SpurPlanningCompactor >> unmarkObjectsInFullyCompactedHeap [
	self unmarkInitialImmobileObjects.
	manager unmarkSurvivingObjectsForCompact
]

{ #category : #compaction }
SpurPlanningCompactor >> unmarkObjectsOverflowingSavedFirstFieldsSpace [
	self shouldBeImplemented
]

{ #category : #private }
SpurPlanningCompactor >> unpinRememberedSet [
	<inline: true>
	firstFieldOfRememberedSet := manager fetchPointer: 0 ofObject: manager rememberedSetObj.
	manager setIsPinnedOf: manager rememberedSetObj to: false
]

{ #category : #compaction }
SpurPlanningCompactor >> updatePointers [
	"Sweep the heap, updating all objects to their eventual locations.
	 Remember to update the savedFirstFields of pointer objects, as these have been forwarded."
	| onePass |
	self logPhase: 'updating pointers...'.
	"If savedFirstFieldsSpace is empty there is nothing to do."
	savedFirstFieldsSpace top < savedFirstFieldsSpace start ifTrue:
		[^self].
	coInterpreter mapInterpreterOops.
	self updatePointersInManagerHeapEntities.
	self updatePointersInSurvivingObjects.
	self updatePointersInInitialImmobileObjects.
	onePass := self updatePointersInMobileObjectsWithTop: savedFirstFieldsSpace start - manager bytesPerOop.
	onePass ifFalse:
		[self updatePointersInObjectsOverflowingSavedFirstFieldsSpace]
]

{ #category : #compaction }
SpurPlanningCompactor >> updatePointersFrom: start to: finish in: obj [
	<inline: true>
	start to: finish do:
		[:i| | oop fwd |
		 oop := manager fetchPointer: i ofObject: obj.
		 ((manager isNonImmediate: oop) and: [self isMobile: oop]) ifTrue:
			[self assert: (manager isMarked: oop).
			 fwd := manager fetchPointer: 0 ofObject: oop.
			 self assert: (self isPostMobile: fwd).
			 manager storePointerUnchecked: i ofObject: obj withValue: fwd]]
]

{ #category : #compaction }
SpurPlanningCompactor >> updatePointersIn: obj [
	"Sweep the pointer fields in obj, updating all references to mobile objects to their eventual locations."
	<inline: true>
	| numPointerSlots |
	numPointerSlots := manager numPointerSlotsOf: obj.
	0 to: numPointerSlots - 1 do:
		[:i| | oop fwd |
		 oop := manager fetchPointer: i ofObject: obj.
		 ((manager isNonImmediate: oop) and: [self isMobile: oop]) ifTrue:
			[self assert: ((manager isMarked: oop) or: [obj = manager hiddenRootsObject]).
			 fwd := manager fetchPointer: 0 ofObject: oop.
			 self assert: (self isPostMobile: fwd).
			 manager storePointerUnchecked: i ofObject: obj withValue: fwd]]
]

{ #category : #compaction }
SpurPlanningCompactor >> updatePointersIn: obj savedFirstFieldPointer: firstFieldPtrOrNil [
	"Sweep the pointer fields in obj, updating all references to mobile objects to their eventual locations.
	 firstFieldPtrOrNil is supplied for mobile objects so that the saved first field can be updated, and so that
	 the first field of a compiled method (which is its header, or reference to a CogMethod holding its header)
	 can be retrieved."
	<inline: false>
	| fmt numPointerSlots |
	fmt := manager formatOf: obj.
	numPointerSlots := self numPointerSlotsWhileCompactingOf: obj withFormat: fmt savedFirstFieldPointer: firstFieldPtrOrNil.
	(fmt <= manager lastPointerFormat "excludes CompiledMethod"
	 and: [numPointerSlots > 0]) ifTrue:
		[| oop fwd |
		 "Relocate the saved first field; Note that CompiledMethods can be excluded since their
		  first field is either a SmallInteger or a reference to a CogMethod outside of oldSpace."
		 oop := manager longAt: firstFieldPtrOrNil.
		 ((manager isNonImmediate: oop) and: [self isMobile: oop]) ifTrue:
			[self assert: (manager isMarked: oop).
			 fwd := manager fetchPointer: 0 ofObject: oop.
			 self assert: (self isPostMobile: fwd).
			 manager longAt: firstFieldPtrOrNil put: fwd]].
	1 to: numPointerSlots - 1 do:
		[:i| | oop fwd |
		 oop := manager fetchPointer: i ofObject: obj.
		 ((manager isNonImmediate: oop) and: [self isMobile: oop]) ifTrue:
			[self assert: ((manager isMarked: oop) or: [obj = manager hiddenRootsObject]).
			 fwd := manager fetchPointer: 0 ofObject: oop.
			 self assert: (self isPostMobile: fwd).
			 manager storePointerUnchecked: i ofObject: obj withValue: fwd]]
]

{ #category : #compaction }
SpurPlanningCompactor >> updatePointersInInitialImmobileObjects [
	"Sweep the initial immobile heap, updating all references to mobile objects to their eventual locations."
	manager allOldSpaceObjectsFrom: manager firstObject do:
		[:o|
		o >= firstFreeObject ifTrue:
			[^self].
		self assert: (manager isMarked: o).
		self updatePointersIn: o]
]

{ #category : #compaction }
SpurPlanningCompactor >> updatePointersInManagerHeapEntities [
	"The special non-pointer objects containing pointers, which are the objStacks and the rememberedSet,
	 must be updated manually sicme they will not be recognized as containing pointers in the normal sweep."
	manager relocateObjStacksForPlanningCompactor.
	(scavenger rememberedSetSize > 0
	 and: [self isMobile: firstFieldOfRememberedSet]) ifTrue:
		[firstFieldOfRememberedSet := manager fetchPointer: 0 ofObject: firstFieldOfRememberedSet].
	self relocateObjectsInHeapEntity: manager rememberedSetObj from: 1 to: scavenger rememberedSetSize - 1
	"Note that we /must not/ set the rememberedSetObj here since it is a slot in the hiddenRootsObj
	 and will be updated normally in updatePointersInInitialImmobileObjects.  So do not do
	(self isMobile: manager rememberedSetObj) ifTrue:
		[manager rememberedSetObj: (manager fetchPointer: 0 ofObject: manager rememberedSetObj)]"
]

{ #category : #compaction }
SpurPlanningCompactor >> updatePointersInMobileObjectsWithTop: initialTop [
	"Sweep the mobile portion of the heap, updating all references to objects to their eventual locations.
	 Remember to update the savedFirstFields of pointer objects, as these have been forwarded.
	 This enumeration matches that in planCompactSavingForwarders and copyAndUnmarkMobileObjects."

	| toFinger top previousPin |
	toFinger := manager startOfObject: firstFreeObject.
	top := initialTop.
	self deny: (manager isMarked: firstFreeObject).
	manager allOldSpaceEntitiesFrom: firstFreeObject do:
		[:o|
		 self assert: (previousPin isNil or: [toFinger < previousPin]).
		 (manager isMarked: o) ifTrue:
			[(manager isPinned: o)
				ifTrue: "The empty gaps between two adjacent pinned objects (when not filled below) are freed."
					[self updatePointersIn: o.
					 previousPin ifNotNil:
						[toFinger := manager addressAfter: previousPin].
					 previousPin := o]
				ifFalse:
					[| availableSpace bytes next |
					 (top := top + manager bytesPerOop) >= savedFirstFieldsSpace limit ifTrue:
						[^false].
					 [previousPin notNil
					  and: [availableSpace := (manager startOfObject: previousPin) - toFinger.
							bytes := manager bytesInObject: o.
							bytes ~= availableSpace
							 and: [bytes + (2 * manager allocationUnit) < availableSpace]]] whileTrue:
						["The object does not fit in the space between toFinger and previousPin.
						  Move toFinger beyond previousPin and update previousPin appropriately."
						 toFinger := manager addressAfter: previousPin.
						 next := manager objectStartingAt: toFinger.
						 next >= o ifTrue:
							[^self continueUpdatePointersInMobileObjectsFrom: next withTop: top].
						 previousPin := (manager isPinned: next) ifTrue: [next]].
					 self updatePointersIn: o savedFirstFieldPointer: top.
					 toFinger := toFinger + (manager bytesInObject: o)]]].
	^true
]

{ #category : #compaction }
SpurPlanningCompactor >> updatePointersInObjectsOverflowingSavedFirstFieldsSpace [
	"Sweep the final immobile heap, is any (those objects with no room in savedFirstFieldsSpace
	 in the current pass) updating all references to mobile objects to their eventual locations."
	manager allOldSpaceObjectsFrom: (manager objectAfter: lastMobileObject) do:
		[:o|
		self assert: (manager isMarked: o).
		self updatePointersIn: o]
]

{ #category : #compaction }
SpurPlanningCompactor >> updatePointersInSurvivingObjects [
	"Sweep pastSpace, updating all references to mobile objects to their eventual locations."
	manager allPastSpaceObjectsDo:
		[:o|
		self assert: (manager isMarked: o).
		self updatePointersIn: o]
]

{ #category : #'space management' }
SpurPlanningCompactor >> updateSavedFirstFieldsSpaceIfNecessary [
	"If savedFirstFieldsSpace is a free chunk then it may need to be repositioned if there is more than one pass."

	((manager isInOldSpace: savedFirstFieldsSpace start)
	 and: [savedFirstFieldsSpaceWasAllocated not]) ifTrue:
		[self useFreeChunkForSavedFirstFieldsSpace: manager findLargestFreeChunk].

	savedFirstFieldsSpace top: savedFirstFieldsSpace start - manager bytesPerOop.
	manager resetFreeListHeads
]

{ #category : #'space management' }
SpurPlanningCompactor >> useEdenForSavedFirstFieldsSpace [
	"Use teden to hold the savedFirstFieldsSpace."
	<inline: true>
	savedFirstFieldsSpace
		start: scavenger eden start;
		limit: scavenger eden limit
]

{ #category : #'space management' }
SpurPlanningCompactor >> useFreeChunkForSavedFirstFieldsSpace: highestSuitableFreeBlock [
	"Use the supplied free chunk to hold the savedFirstFieldsSpace.
	 Invoked when eden is found not to be big enough for the job."
	<inline: true>
	savedFirstFieldsSpace
		start: highestSuitableFreeBlock;
		limit: (manager addressAfter: highestSuitableFreeBlock)
]

{ #category : #'space management' }
SpurPlanningCompactor >> useSegmentForSavedFirstFieldsSpace: spaceEstimate [
	"Attempt to allocate a memory segment large enough to hold the savedFirstFieldsSpace.
	 Invoked when neither eden nor a large free chunk are found to be big enough for the
	 job."
	| allocatedSize |
	(manager "sent to the manager so that the simulator can increase memory to simulate a new segment"
		sqAllocateMemorySegmentOfSize: spaceEstimate
		Above: (self firstGapOfSizeAtLeast: spaceEstimate)
		AllocatedSizeInto: (self cCode: [self addressOf: allocatedSize]
								inSmalltalk: [[:sz| allocatedSize := sz]])) ifNotNil:
		[:segAddress|
		 savedFirstFieldsSpaceWasAllocated := true.
		 savedFirstFieldsSpace
			start: segAddress;
			limit: segAddress + allocatedSize.
		 ^true].
	^false
]
