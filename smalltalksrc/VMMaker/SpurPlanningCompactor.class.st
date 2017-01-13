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
		'mobileStart',
		'firstMobileObject',
		'lastMobileObject',
		'savedFirstFieldsSpace',
		'savedFirstFieldsSpaceNotInOldSpace',
		'firstFieldOfRememberedSet',
		'interestingObj',
		'anomaly',
		'objectAfterLastMobileObject'
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
	aCCodeGenerator
		var: 'savedFirstFieldsSpace' type: #SpurContiguousObjStack;
		removeVariable: 'interestingObj'
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

{ #category : #private }
SpurPlanningCompactor >> check: obj [
	<inline: true>
	self cCode: '' inSmalltalk: [obj = interestingObj ifTrue: [self halt]].
	"this debugged the misuse of the largest free chunk:"
	"(manager checkForLeaks bitAnd: GCModeFull+GCModeFreeSpace) = GCModeFull ifTrue:
		[self deny: ((manager isEnumerableObject: obj) and: [(manager heapMapAtWord: obj) = 0])]"
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
	| onePass firstPass |
	<inline: #never> "for profiling"
	self initializeScanCheckingForFullyCompactedHeap ifTrue:
		[^self unmarkObjectsInFullyCompactedHeap].
	self initializeCompaction.
	firstPass := true.
	[onePass := self planCompactSavingForwarders.
	 self assert: (self validRelocationPlanInPass: onePass) = 0.
	 objectAfterLastMobileObject := manager objectAfter: lastMobileObject.
	 self updatePointers.
	 self copyAndUnmark: firstPass.
	 manager checkFreeSpace: GCModeFull.
	 onePass or: [biasForGC]] whileFalse:
		[firstPass := false.
		 self reinitializeScan;
			updateSavedFirstFieldsSpaceIfNecessary].
	self endCompaction
]

{ #category : #compaction }
SpurPlanningCompactor >> copyAndUnmark: firstPass [
	"Sweep the heap, unmarking all objects and moving mobile objects to their correct positions,
	 restoring their savedFirstFields."
	<inline: #never>
	| onePass |
	self logPhase: 'copying and unmarking...'.
	firstPass ifTrue:
		[self unmarkInitialImmobileObjects].
	"If savedFirstFieldsSpace is empty there is nothing to move, and no second pass."
	savedFirstFieldsSpace top < savedFirstFieldsSpace start ifTrue:
		[self assert: (self oop: firstMobileObject isGreaterThanOrEqualTo: manager endOfMemory).
		 ^self].
	onePass := self copyAndUnmarkMobileObjects.
	(onePass not and: [biasForGC]) ifTrue: "only ever one pass if biasForGC is true."
		[self unmarkObjectsAfterLastMobileObject]
]

{ #category : #compaction }
SpurPlanningCompactor >> copyAndUnmarkMobileObjects [
	"Sweep the mobile portion of the heap, moving objects to their eventual locations, and clearing their marked bits.
	 Remember to update the savedFirstFields of pointer objects, as these have been forwarded.
	 Answer if the end of the heap was reached (savedFirstFieldsSpace has not overflowed).

	 The enumerations in planCompactSavingForwarders, updatePointersInMobileObjects and copyAndUnmarkMobileObjects
	 match.  We could implement them as a single enumeration method taking several block arguments, but arguably that
	 would make understanding an already tricky algorithm more difficult.  Instead we tolerate the duplication and encourage
	 the reader to diff the three methods to see where they diverge (e.g. via Cmd-shift-C)."
	<inline: #never>
	| toFinger top previousPin |
	<var: 'top' type: #usqInt>
	<var: 'toFinger' type: #usqInt>
	self deny: (manager isMarked: firstFreeObject).
	toFinger := manager startOfObject: firstFreeObject.
	top := savedFirstFieldsSpace start.
	manager allOldSpaceEntitiesForCompactingFrom: firstFreeObject do:
		[:o :n|
		 self check: o.
		 self assert: (previousPin
						ifNil: [toFinger <= (manager startOfObject: o)]
						ifNotNil: [(manager isMarked: previousPin) and: [toFinger <= (manager startOfObject: previousPin)]]).
		 self assert: (savedFirstFieldsSpaceNotInOldSpace or: [toFinger < top]).
		 o > lastMobileObject ifTrue:
			[self freeFrom: toFinger upTo: manager endOfMemory previousPin: previousPin.
			 ^true].
		 (manager isMarked: o) ifTrue:
			[(manager isPinned: o)
				ifTrue:
					[previousPin ifNil:
						[previousPin := o]]
				ifFalse:
					[| availableSpace bytes |
					 bytes := manager bytesInObject: o.
					 [previousPin notNil
					  and: [availableSpace := (manager startOfObject: previousPin) - toFinger.
							bytes ~= availableSpace
							and: [bytes + (2 * manager allocationUnit) > availableSpace]]] whileTrue:
						["The object does not fit in the space between toFinger and previousPin.
						   Move toFinger up to point at the first unmarked or mobile object after
						   previousPin, or, if previousPin is contiguous with o, to the start of this
						   object.  Update previousPin to be the next pinned object above toFInger
						   and below this object, or nil if no such pinned object exists.
						   Any unfillable gaps between adjacent pinned objects will be freed."
						 availableSpace > 0 ifTrue:
							[manager addFreeChunkWithBytes: availableSpace at: toFinger].
					 	 [self assert: ((manager isMarked: previousPin) and: [manager isPinned: previousPin]).
						  self unmarkPinned: previousPin.
						  toFinger := manager addressAfter: previousPin.
						  previousPin := manager objectStartingAt: toFinger.
						  (manager isMarked: previousPin)
						   and: [(manager isPinned: previousPin)
						   and: [previousPin < o]]]
							whileTrue.
						 "Now previousPin is either equal to o or mobile.
						  Move it to the next pinned object below o"
						 [previousPin >= o
						  or: [(manager isMarked: previousPin)
						  and: [manager isPinned: previousPin]]] whileFalse:
							[previousPin := manager objectAfter: previousPin].
						 previousPin >= o ifTrue:
							[previousPin := nil]].
					 self copyAndUnmarkObject: o to: toFinger bytes: bytes firstField: (manager longAt: top).
					 toFinger := toFinger + bytes.
					 (top := top + manager bytesPerOop) >= savedFirstFieldsSpace limit ifTrue:
						[| done |
						 self assert: savedFirstFieldsSpace top = (top - manager bytesPerOop).
						 done := self noMobileObjectsAfter: n.
						 done
							ifTrue: [self freeAllUnpinnedObjectsFromObject: (previousPin ifNil: [n]) toFinger: toFinger]
							ifFalse: [self freeFrom: toFinger upTo: (manager startOfObject: n) previousPin: previousPin].
						^done]]]].
	self freeFrom: toFinger upTo: manager endOfMemory previousPin: previousPin.
	^true
]

{ #category : #compaction }
SpurPlanningCompactor >> copyAndUnmarkObject: o to: toFinger bytes: bytes firstField: firstField [
	"Copy the object to toFinger, clearing its mark bit and restoring its firstField, which was overwritten with a forwarding pointer.
	 Answer the number of bytes in the object, including overflow header."
	<inline: true>
	| numSlots destObj start |
	numSlots := manager rawNumSlotsOf: o.
	destObj := (manager objectWithRawSlotsHasOverflowHeader: numSlots)
					ifTrue: [toFinger + manager baseHeaderSize]
					ifFalse: [toFinger].
	start := manager startOfObject: o given: numSlots.
	manager
		mem: toFinger asVoidPointer cp: start asVoidPointer y: bytes;
		setIsMarkedOf: destObj to: false;
		storePointerUnchecked: 0 ofObject: destObj withValue: firstField
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
	"If a freeBlock of size at least spaceEstimate exists high enough in the heap, choose it.
	 Ignoring pinned objects for now, the total ammount of shrinkage is expected to be
	 at least totalFreeOldSpace (because of collected objects).  So any free chunk which is
	 at or above endOfMemory - totalFreeOldSpace should not be corrupted during compaction.
	 Let's play with this for a while and see how we get on."
	<inline: true>
	manager findLargestFreeChunk ifNotNil:
		[:largestFreeChunk|
		((manager bytesInObject: largestFreeChunk) >= spaceEstimate
		 and: [largestFreeChunk asUnsignedInteger > (manager endOfMemory - manager freeSize) asUnsignedInteger]) ifTrue:
			[^largestFreeChunk]].
	^nil
]

{ #category : #private }
SpurPlanningCompactor >> findNextMarkedPinnedAfter: unpinnedObj [
	<inline: true>
	| nextObj |
	self deny: ((manager isPinned: unpinnedObj) and: [manager isMarked: unpinnedObj]).
	nextObj := unpinnedObj.
	[nextObj := manager objectAfter: nextObj limit: manager endOfMemory.
	 nextObj >= manager endOfMemory ifTrue:
		[^nil].
	 (manager isPinned: nextObj) and: [manager isMarked: nextObj]] whileFalse.
	^nextObj
]

{ #category : #private }
SpurPlanningCompactor >> forwardMobileObject: o to: toFinger savedFirstFieldPtr: savedFirstFieldPtr [
	"Forward a mobile object to some new location, saving its first field through savedFirstFieldPtr.
	 Don't use forward:to:; we dont want to alter the object in any way other than by setting the forwarding pointer."
	<inline: true>
	lastMobileObject := o.
	manager
		longAt: savedFirstFieldPtr
			put: (manager fetchPointer: 0 ofObject: o);
		storePointerUnchecked: 0
			ofObject: o
				withValue: ((manager hasOverflowHeader: o)
								ifTrue: [toFinger + manager baseHeaderSize]
								ifFalse: [toFinger]).
	^toFinger + (manager bytesInObject: o)
]

{ #category : #private }
SpurPlanningCompactor >> freeAllUnpinnedObjectsFromObject: nextObj toFinger: initialToFinger [
	"Free all space from toFinger up, preserving only marked pinned objects, clearning their marked bits."
	| toFinger nextPinnedObj |
	<var: 'toFinger' type: #usqInt>
	<var: 'nextPinnedObj' type: #usqInt>
	toFinger := initialToFinger.
	nextPinnedObj := nextObj.
	[[nextPinnedObj >= manager endOfMemory
	  or: [(manager isMarked: nextPinnedObj)
		  and: [manager isPinned: nextPinnedObj]]] whileFalse:
		[nextPinnedObj := manager objectAfter: nextPinnedObj].
	 nextPinnedObj < manager endOfMemory] whileTrue:
		[toFinger < (manager startOfObject: nextPinnedObj) ifTrue:
			[manager addFreeChunkWithBytes: (manager startOfObject: nextPinnedObj) - toFinger at: toFinger].
		 self unmarkPinned: nextPinnedObj.
		 toFinger := manager addressAfter: nextPinnedObj.
		 nextPinnedObj := manager objectAfter: nextPinnedObj].
	toFinger < manager endOfMemory ifTrue:
		[manager addFreeChunkWithBytes: manager endOfMemory - toFinger at: toFinger]
]

{ #category : #private }
SpurPlanningCompactor >> freeFrom: toFinger upTo: limit previousPin: previousPinOrNil [
	"Free from toFinger up to limit, dealing with a possible intervening run of pinned objects starting at previousPinOrNil."
	<inline: false>
	| effectiveToFinger pin nextUnpinned start |
	self cCode: [] inSmalltalk:
		[coInterpreter cr; cr; print: 'freeing at '; printHexnp: toFinger; print: ' up to '; printHexnp: limit; print: ' pin '; printHexnp: previousPinOrNil; cr].
	effectiveToFinger := toFinger.
	pin := previousPinOrNil.
	[pin notNil] whileTrue:
		[(start := manager startOfObject: pin) > toFinger ifTrue:
			[manager addFreeChunkWithBytes: start - effectiveToFinger at: effectiveToFinger].
		 nextUnpinned := self unmarkPinnedObjectsAndFindFirstUnpinnedOrFreeEntityFollowing: pin.
		 nextUnpinned >= limit ifTrue:
			[^self].
		 effectiveToFinger := manager startOfObject: nextUnpinned.
		 pin := self findNextMarkedPinnedAfter: nextUnpinned].
	manager addFreeChunkWithBytes: limit - effectiveToFinger at: effectiveToFinger
]

{ #category : #'instance initialization' }
SpurPlanningCompactor >> initialize [
	biasForGC := true.
	savedFirstFieldsSpace := SpurContiguousObjStack new.
	savedFirstFieldsSpaceNotInOldSpace := true
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
	"Scan for firstFreeObject and firstMobileObject from the start of memory (actually
	 from lastMobileObject so that reInitializeScan can work on subsequent passes).
	 Answer if the heap is already fully compacted.  Set "
	firstFreeObject := lastMobileObject := manager hiddenRootsObject.
	self reinitializeScan.
	^firstMobileObject >= manager endOfMemory
]

{ #category : #'instance initialization' }
SpurPlanningCompactor >> interestingObj: obj [
	interestingObj := obj
]

{ #category : #private }
SpurPlanningCompactor >> isMobile: obj [
	<inline: true>
	^(self oop: obj isGreaterThanOrEqualTo: mobileStart andLessThanOrEqualTo: lastMobileObject)
	 and: [(manager isPinned: obj) not]
]

{ #category : #private }
SpurPlanningCompactor >> isPostMobile: obj [
	"For asserts"
	^self oop: obj isGreaterThanOrEqualTo: mobileStart andLessThanOrEqualTo: lastMobileObject
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
SpurPlanningCompactor >> noMobileObjectsAfter: mobileObj [
	self assert: ((manager isMarked: mobileObj) and: [(manager isPinned: mobileObj) not]).
	manager allOldSpaceEntitiesFrom: mobileObj do:
		[:o|
		 ((manager isMarked: o) and: [(manager isPinned: o) not]) ifTrue:
			[^false]].
	^true
]

{ #category : #private }
SpurPlanningCompactor >> numPointerSlotsWhileCompactingOf: obj withFormat: fmt savedFirstFieldPointer: firstFieldPtr [
	"This is a version of SpurMemoryManager>>numPointerSlotsOf: that deals with the
	 possibility of obj being a CompiledMethod whose header is in savedFirstFieldsSpace.
	 Answer the number of pointer fields in the given object.
	 Works with CompiledMethods, as well as ordinary objects."
	<inline: true>
	| contextSize numLiterals header |
	self assert: (firstFieldPtr notNil and: [self isMobile: obj]).
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
	header := manager methodHeaderFromSavedFirstField: (manager longAt: firstFieldPtr).
	numLiterals := manager literalCountOfMethodHeader: header.
	^numLiterals + LiteralStart
]

{ #category : #compaction }
SpurPlanningCompactor >> planCompactSavingForwarders [
	"Sweep the heap from firstFreeObject forwarding marked objects to where they
	 can be moved to, saving their forwarding pointer in savedFirstFieldsSpace.
	 Continue until either the end of the heap is reached or savedFirstFieldsSpace is full.
	 Answer if the end of the heap was reached (savedFirstFieldsSpace has not overflowed).

	 The enumerations in planCompactSavingForwarders, updatePointersInMobileObjects and copyAndUnmarkMobileObjects
	 match.  We could implement them as a single enumeration method taking several block arguments, but arguably that
	 would make understanding an already tricky algorithm more difficult.  Instead we tolerate the duplication and encourage
	 the reader to diff the three methods to see where they diverge (e.g. via Cmd-shift-C)."
	<inline: #never>
	| toFinger top previousPin |
	<var: 'top' type: #usqInt>
	<var: 'toFinger' type: #usqInt>
	savedFirstFieldsSpace top < savedFirstFieldsSpace start ifTrue:
		[self logPhase: 'planning...'].
	self deny: (manager isMarked: firstFreeObject).
	toFinger := manager startOfObject: firstFreeObject.
	top := savedFirstFieldsSpace start.
	manager allOldSpaceEntitiesFrom: firstFreeObject do:
		[:o|
		 self check: o.
		 self assert: (previousPin
						ifNil: [toFinger <= (manager startOfObject: o)]
						ifNotNil: [(manager isMarked: previousPin) and: [toFinger <= (manager startOfObject: previousPin)]]).
		 self assert: (savedFirstFieldsSpaceNotInOldSpace or: [toFinger < top]).
		 (manager isMarked: o) ifTrue:
			[(manager isPinned: o)
				ifTrue:
					[previousPin ifNil:
						[previousPin := o]]
				ifFalse:
					[| availableSpace bytes |
					 bytes := manager bytesInObject: o.
					 [previousPin notNil
					  and: [availableSpace := (manager startOfObject: previousPin) - toFinger.
							bytes ~= availableSpace
							and: [bytes + (2 * manager allocationUnit) > availableSpace]]] whileTrue:
						["The object does not fit in the space between toFinger and previousPin.
						   Move toFinger up to point at the first unmarked or mobile object after
						   previousPin, or, if previousPin is contiguous with o, to the start of this
						   object.  Update previousPin to be the next pinned object above toFInger
						   and below this object, or nil if no such pinned object exists.
						   Any unfillable gaps between adjacent pinned objects will be freed."
					 	 [toFinger := manager addressAfter: previousPin.
						  previousPin := manager objectStartingAt: toFinger.
						  (manager isMarked: previousPin)
						   and: [(manager isPinned: previousPin)
						   and: [previousPin < o]]]
							whileTrue.
						 "Now previousPin is either equal to o or mobile.
						  Move it to the next pinned object below o"
						 [previousPin >= o
						  or: [(manager isMarked: previousPin)
						  and: [manager isPinned: previousPin]]] whileFalse:
							[previousPin := manager objectAfter: previousPin].
						 previousPin >= o ifTrue:
							[previousPin := nil]].
					 self forwardMobileObject: o to: toFinger savedFirstFieldPtr: top.
					 toFinger := toFinger + bytes.
					 (top := top + manager bytesPerOop) >= savedFirstFieldsSpace limit ifTrue:
						[savedFirstFieldsSpace top: top - manager bytesPerOop.
						 ^self noMobileObjectsAfter: o]]]].
	savedFirstFieldsSpace top: top - manager bytesPerOop.
	^true
]

{ #category : #compaction }
SpurPlanningCompactor >> reinitializeScan [
	"Search for firstFreeObject and firstMobileObject from lastMobileObject (which is
	 set to the hiddenRootsObject on the first pass)."
	firstMobileObject := manager endOfMemory.
	firstFreeObject := self scanForFirstFreeAndFirstMobileObjectFrom: lastMobileObject.
	firstFreeObject ifNil:
		[self error: 'uncompactable heap; no unmarked objects found'].
	mobileStart := manager startOfObject: firstFreeObject
]

{ #category : #'space management' }
SpurPlanningCompactor >> releaseSavedFirstFieldsSpace [
	<inline: true>
	self savedFirstFieldsSpaceWasAllocated ifTrue:
		[manager
			sqDeallocateMemorySegmentAt: savedFirstFieldsSpace start asVoidPointer
			OfSize: savedFirstFieldsSpace limit - savedFirstFieldsSpace start]
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

{ #category : #'space management' }
SpurPlanningCompactor >> savedFirstFieldsSpaceInFreeChunk [
	<inline: true>
	^savedFirstFieldsSpaceNotInOldSpace not and: [savedFirstFieldsSpace start >= manager nilObject]
]

{ #category : #'space management' }
SpurPlanningCompactor >> savedFirstFieldsSpaceWasAllocated [
	<inline: true>
	^savedFirstFieldsSpaceNotInOldSpace and: [savedFirstFieldsSpace start >= manager nilObject]
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
				 ^self]].
		 (self useSegmentForSavedFirstFieldsSpace: spaceEstimate) ifTrue:
			[^self]].
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
		self check: o.
		(self oop: o isGreaterThanOrEqualTo: firstMobileObject) ifTrue:
			[^self].
		manager setIsMarkedOf: o to: false]
]

{ #category : #compaction }
SpurPlanningCompactor >> unmarkObjectsAfterLastMobileObject [
	"Sweep the final immobile heap, unmarking all objects up to the end of memory."
	manager allOldSpaceObjectsFrom: objectAfterLastMobileObject do:
		[:o|
		self check: o.
		manager setIsMarkedOf: o to: false]
]

{ #category : #compaction }
SpurPlanningCompactor >> unmarkObjectsInFullyCompactedHeap [
	self unmarkInitialImmobileObjects.
	manager unmarkSurvivingObjectsForCompact
]

{ #category : #private }
SpurPlanningCompactor >> unmarkPinned: pinnedObj [
	<inline: true>
	(manager isSegmentBridge: pinnedObj) ifFalse:
		[manager setIsMarkedOf: pinnedObj to: false.
		 manager segmentManager notePinned: pinnedObj]
]

{ #category : #private }
SpurPlanningCompactor >> unmarkPinnedObjectsAndFindFirstUnpinnedOrFreeEntityFollowing: pinnedObj [
	<inline: true>
	| nextObj |
	self assert: ((manager isPinned: pinnedObj) and: [manager isMarked: pinnedObj]).
	nextObj := pinnedObj.
	[self unmarkPinned: nextObj.
	 nextObj := manager objectAfter: nextObj limit: manager endOfMemory.
	 nextObj >= manager endOfMemory ifTrue:
		[^manager endOfMemory].
	 (manager isPinned: nextObj) and: [manager isMarked: nextObj]] whileTrue.
	^nextObj
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
	<inline: #never>
	| onePass |
	self logPhase: 'updating pointers...'.
	"If savedFirstFieldsSpace is empty there is nothing to do."
	savedFirstFieldsSpace top < savedFirstFieldsSpace start ifTrue:
		[^self].
	self assert: (manager startOfObject: firstFreeObject) = mobileStart.
	coInterpreter mapInterpreterOops.
	manager mapExtraRoots.
	self updatePointersInManagerHeapEntities.
	self updatePointersInSurvivingObjects.
	self updatePointersInInitialImmobileObjects.
	onePass := self updatePointersInMobileObjects.
	onePass ifFalse:
		[self updatePointersInObjectsOverflowingSavedFirstFieldsSpace]
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
SpurPlanningCompactor >> updatePointersIn: obj savedFirstFieldPointer: firstFieldPtr [
	"Sweep the pointer fields in obj, updating all references to mobile objects to their eventual locations.
	 firstFieldPtr is supplied for mobile objects so that the saved first field can be updated, and so that
	 the first field of a compiled method (which is its header, or reference to a CogMethod holding its header)
	 can be retrieved."
	<inline: false>
	| fmt numPointerSlots oop fwd |
	fmt := manager formatOf: obj.
	numPointerSlots := self numPointerSlotsWhileCompactingOf: obj withFormat: fmt savedFirstFieldPointer: firstFieldPtr.
	(fmt <= manager lastPointerFormat "excludes CompiledMethod"
	 and: [numPointerSlots > 0]) ifTrue:
		["Relocate the saved first field; Note that CompiledMethods can be excluded since their
		  first field is either a SmallInteger or a reference to a CogMethod outside of oldSpace."
		 oop := manager longAt: firstFieldPtr.
		 ((manager isNonImmediate: oop) and: [self isMobile: oop]) ifTrue:
			[self assert: (manager isMarked: oop).
			 fwd := manager fetchPointer: 0 ofObject: oop.
			 self assert: (self isPostMobile: fwd).
			 manager longAt: firstFieldPtr put: fwd]].
	1 to: numPointerSlots - 1 do:
		[:i|
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
		self check: o.
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
SpurPlanningCompactor >> updatePointersInMobileObjects [
	"Sweep the mobile portion of the heap, updating all references to objects to their eventual locations.
	 Remember to update the savedFirstFields of pointer objects, as these have been forwarded.
	 Answer if the end of the heap was reached (savedFirstFieldsSpace has not overflowed).

	 The enumerations in planCompactSavingForwarders, updatePointersInMobileObjects and copyAndUnmarkMobileObjects
	 match.  We could implement them as a single enumeration method taking several block arguments, but arguably that
	 would make understanding an already tricky algorithm more difficult.  Instead we tolerate the duplication and encourage
	 the reader to diff the three methods to see where they diverge (e.g. via Cmd-shift-C)."
	| toFinger top previousPin |
	<var: 'top' type: #usqInt>
	<var: 'toFinger' type: #usqInt>
	self deny: (manager isMarked: firstFreeObject).
	toFinger := manager startOfObject: firstFreeObject.
	top := savedFirstFieldsSpace start.
	manager allOldSpaceEntitiesFrom: firstFreeObject do:
		[:o|
		 self check: o.
		 self assert: (previousPin
						ifNil: [toFinger <= (manager startOfObject: o)]
						ifNotNil: [(manager isMarked: previousPin) and: [toFinger <= (manager startOfObject: previousPin)]]).
		 (manager isMarked: o) ifTrue:
			[(manager isPinned: o)
				ifTrue:
					[previousPin ifNil:
						[previousPin := o].
					 self updatePointersIn: o]
				ifFalse:
					[| availableSpace bytes |
					 bytes := manager bytesInObject: o.
					 [previousPin notNil
					  and: [availableSpace := (manager startOfObject: previousPin) - toFinger.
							bytes ~= availableSpace
							and: [bytes + (2 * manager allocationUnit) > availableSpace]]] whileTrue:
						["The object does not fit in the space between toFinger and previousPin.
						   Move toFinger up to point at the first unmarked or mobile object after
						   previousPin, or, if previousPin is contiguous with o, to the start of this
						   object.  Update previousPin to be the next pinned object above toFInger
						   and below this object, or nil if no such pinned object exists.
						   Any unfillable gaps between adjacent pinned objects will be freed."
					 	 [toFinger := manager addressAfter: previousPin.
						  previousPin := manager objectStartingAt: toFinger.
						  (manager isMarked: previousPin)
						   and: [(manager isPinned: previousPin)
						   and: [previousPin < o]]]
							whileTrue.
						 "Now previousPin is either equal to o or mobile.
						  Move it to the next pinned object below o"
						 [previousPin >= o
						  or: [(manager isMarked: previousPin)
						  and: [manager isPinned: previousPin]]] whileFalse:
							[previousPin := manager objectAfter: previousPin].
						 previousPin >= o ifTrue:
							[previousPin := nil]].
					 self updatePointersIn: o savedFirstFieldPointer: top.
					 toFinger := toFinger + bytes.
					 (top := top + manager bytesPerOop) >= savedFirstFieldsSpace limit ifTrue:
						[self assert: savedFirstFieldsSpace top = (top - manager bytesPerOop).
						 ^self noMobileObjectsAfter: o]]]].
	self assert: savedFirstFieldsSpace top = (top - manager bytesPerOop).
	^true
]

{ #category : #compaction }
SpurPlanningCompactor >> updatePointersInObjectsOverflowingSavedFirstFieldsSpace [
	"Sweep the final immobile heap, is any (those objects with no room in savedFirstFieldsSpace
	 in the current pass) updating all references to mobile objects to their eventual locations."
	manager allOldSpaceObjectsFrom: (manager objectAfter: lastMobileObject) do:
		[:o|
		self check: o.
		self assert: (manager isMarked: o).
		self updatePointersIn: o]
]

{ #category : #compaction }
SpurPlanningCompactor >> updatePointersInSurvivingObjects [
	"Sweep pastSpace, updating all references to mobile objects to their eventual locations."
	manager allPastSpaceObjectsDo:
		[:o|
		self check: o.
		self assert: (manager isMarked: o).
		self updatePointersIn: o]
]

{ #category : #'space management' }
SpurPlanningCompactor >> updateSavedFirstFieldsSpaceIfNecessary [
	"If savedFirstFieldsSpace is a free chunk then it may need to be repositioned if there is more than one pass."
	<inline: true>
	self savedFirstFieldsSpaceInFreeChunk ifTrue:
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
		limit: scavenger eden limit.
	savedFirstFieldsSpaceNotInOldSpace := true.
	self deny: self savedFirstFieldsSpaceWasAllocated
]

{ #category : #'space management' }
SpurPlanningCompactor >> useFreeChunkForSavedFirstFieldsSpace: highestSuitableFreeBlock [
	"Use the supplied free chunk to hold the savedFirstFieldsSpace. Invoked when
	 eden is found not to be big enough for the job. Avoid the first few fields so as
	 not to destroy the free chunk and there by confuse object enumeration."
	<inline: true>
	savedFirstFieldsSpace
		start: highestSuitableFreeBlock + (manager freeChunkLargerIndex * manager bytesPerOop);
		limit: (manager addressAfter: highestSuitableFreeBlock).
	savedFirstFieldsSpaceNotInOldSpace := false.
	self deny: self savedFirstFieldsSpaceWasAllocated
]

{ #category : #'space management' }
SpurPlanningCompactor >> useSegmentForSavedFirstFieldsSpace: spaceEstimate [
	"Attempt to allocate a memory segment large enough to hold the savedFirstFieldsSpace.
	 Invoked when neither eden nor a large free chunk are found to be big enough for the job."
	| allocatedSize |
	(manager "sent to the manager so that the simulator can increase memory to simulate a new segment"
		sqAllocateMemorySegmentOfSize: spaceEstimate
		Above: (self firstGapOfSizeAtLeast: spaceEstimate)
		AllocatedSizeInto: (self cCode: [self addressOf: allocatedSize]
								inSmalltalk: [[:sz| allocatedSize := sz]])) ifNotNil:
		[:segAddress|
		 savedFirstFieldsSpace
			start: segAddress;
			limit: segAddress + allocatedSize.
		 savedFirstFieldsSpaceNotInOldSpace := true.
		 self assert: self savedFirstFieldsSpaceWasAllocated.
		 ^true].
	^false
]

{ #category : #private }
SpurPlanningCompactor >> validRelocationPlanInPass: onePass [
	"Answer 0 if all the mobile objects from firstMobileObject to lastMobileObject
	 have sane forwarding addresses, and that savedFirstFieldsSpace is of
	 matching capacity.  Otherwise answer an error code identifying the anomaly."
	| nMobiles toFinger |
	<var: 'toFinger' type: #usqInt>
	<var: 'destination' type: #usqInt>
	nMobiles := 0.
	toFinger := mobileStart.
	anomaly := nil.
	manager allOldSpaceEntitiesFrom: firstMobileObject do:
		[:o| | destination |
		 self check: o.
		 (manager isMarked: o) ifTrue:
			[(manager isPinned: o) ifFalse:
				[nMobiles := nMobiles + 1.
				 destination := manager fetchPointer: 0 ofObject: o.
				 destination >= toFinger ifFalse:
					[anomaly := o. ^1].
				 toFinger := toFinger + (manager bytesInObject: o).
				 (self oop: o isGreaterThan: lastMobileObject) ifTrue:
					[anomaly := o. ^2].
				 o = lastMobileObject ifTrue:
					[^savedFirstFieldsSpace top - savedFirstFieldsSpace start / manager bytesPerOop + 1
					   = nMobiles
						ifTrue: [0]
						ifFalse: [3]]]]].
	^savedFirstFieldsSpace top - savedFirstFieldsSpace start / manager bytesPerOop + 1
	  = nMobiles
		ifTrue: [0]
		ifFalse: [4]
]
