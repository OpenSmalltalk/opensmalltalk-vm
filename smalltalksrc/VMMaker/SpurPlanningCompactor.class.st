"
SpurPlanningCompactor implements the classic planning compaction algorithm for Spur.  It uses the fact that there is room for a forwarding pointer in all objects to store the eventual position of an object in the first field.  It therefore first locates a large free chunk, or eden or a memory segment, to use as the savedFirstFieldsSpace, which it uses to store the first fields of objects that will be compacted.  It then makes at least three passes through the heap.

The first pass plans where live movable objects will go, copying their first field to the next slot in savedFirstFieldsSpace, and setting their forwarding pointer to point to their eventual location (see planCompactSavingForwarders).  The second pass updates all pointers in live pointer objects to point to objects' final destinations, including the fields in savedFirstFieldsSpace (see updatePointers and updatePointersInMobileObjects).  The third pass moves objects to their final positions, unmarking objects, and restoring saved first fields as it does so (see copyAndUnmark: and copyAndUnmarkMobileObjects).  If the forwarding fields of live objects in the to-be-moved portion of the entire heap won't fit in savedFirstFieldsSpace, then additional passes can be made until the entire heap has been compacted.  When snapshotting multiple passes are made, but when doing a normal GC only one pass is made.

Each pass uses a three finger algorithm, a simple extension of the classic two finger algorithm with an extra finger used to identify the lowest pinned object between the to and from fingers.  Objects are moved down, starting at the first free object or chunk, provided that they fit below the lowest pinned object above the to finger.  When an object won't fit the to finger is moved above the pinned object and the third finger is reset to the next pinned object below the from finger, if any.

Instance Variables
	anomaly							<Oop>
	biasForGC							<Boolean>
	firstFieldOfRememberedSet			<Oop>
	firstFreeObject						<Oop>
	firstMobileObject					<Oop>
	lastMobileObject					<Oop>
	mobileStart							<Integer address>
	objectAfterLastMobileObject		<Oop|nil>
	savedFirstFieldsSpace				<SpurContiguousObjStack>
	savedFirstFieldsSpaceWasAllocated	<Boolean>

anomaly
	- if any bogus object is detected by asserts, etc, it is stored in anomaly

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

mobileStart
	- the address of the first byte in firstFreeObject

objectAfterLastMobileObject
	- the object following the last object that can be moved, used when more than one pass is needed.

savedFirstFieldsSpace
	- the space holding the saved first fields, each overwritten by a forwarding pointer, for the objects from firstMobileObject through to lastMobileObject.

savedFirstFieldsSpaceWasAllocated
	- if true, the memory for savedFirstFieldsSpace was obtained via a call of sqAllocateMemorySegmentOfSize:Above:AllocatedSizeInto:
"
Class {
	#name : #SpurPlanningCompactor,
	#superclass : #SpurCompactor,
	#instVars : [
		'anomaly',
		'biasForGC',
		'firstFieldOfRememberedSet',
		'firstFreeObject',
		'firstMobileObject',
		'lastMobileObject',
		'mobileStart',
		'objectAfterLastMobileObject',
		'savedFirstFieldsSpace',
		'savedFirstFieldsSpaceNotInOldSpace'
	],
	#pools : [
		'VMBytecodeConstants'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurPlanningCompactor class >> declareCVarsIn: aCCodeGenerator [
	super declareCVarsIn: aCCodeGenerator.
	self declareCAsOop: (self instVarNames select: [:iv| iv endsWith: 'Object']) in: aCCodeGenerator.
	aCCodeGenerator
		var: 'savedFirstFieldsSpace' type: #SpurContiguousObjStack
]

{ #category : #analysis }
SpurPlanningCompactor class >> identify32BitSignedComparisons [
	"self identify32BitSignedComparisons"
	self identifySignedComparisonsFor: #(ObjectMemory Spur32BitMemoryManager)
		noise: #('(manager bytesInObject: largestFreeChunk) >= spaceEstimate'
				'(self classIndexOf: o*) > self isForwardedObjectClassIndexPun'
				'GCModeFull > 0'
				'ReceiverIndex + (objectMemory integerValueOf: sp*) < (objectMemory lengthOf: o*)'
				'availableSpace > 0'
				'bytes + 2 * 8 > availableSpace'
				'fmt* < manager firstCompiledMethodFormat'
				'fmt* < self firstCompiledMethodFormat'
				'fmt* <= 5'
				'gcPhaseInProgress > 0'
				'i <= finishIndex'
				'numPointerSlots > 0'
				'scavenger rememberedSetSize > 0')
]

{ #category : #analysis }
SpurPlanningCompactor class >> identify64BitSignedComparisons [
	"self identify64BitSignedComparisons"
	self identifySignedComparisonsFor: #(ObjectMemory Spur64BitMemoryManager)
		noise: #('(manager bytesInObject: largestFreeChunk) >= spaceEstimate'
				'(self classIndexOf: o*) > self isForwardedObjectClassIndexPun'
				'GCModeFull > 0'
				'ReceiverIndex + (objectMemory integerValueOf: sp*) < (objectMemory lengthOf: o*)'
				'availableSpace > 0'
				'bytes + 2 * 8 > availableSpace'
				'fmt* < manager firstCompiledMethodFormat'
				'fmt* < self firstCompiledMethodFormat'
				'fmt* <= 5'
				'gcPhaseInProgress > 0'
				'i <= finishIndex'
				'numPointerSlots > 0'
				'scavenger rememberedSetSize > 0')
]

{ #category : #analysis }
SpurPlanningCompactor class >> identifyMul: options noise: noise [
	"Mul can overflow...
	SpurPlanningCompactor identifyMul: #(
	ObjectMemory Spur32BitMemoryManager
	compactorClass SpurSelectiveCompactor) noise: #()"
	| vmm cg |
	vmm := (VMMaker forPlatform: 'Cross')
				interpreterClass: StackInterpreter;
				options: options.
	cg := [vmm buildCodeGeneratorForInterpreter]
			on: Notification
			do: [:ex|
				ex tag == #getVMMaker
					ifTrue: [ex resume: vmm]
					ifFalse: [ex pass]].
	cg vmClass preGenerationHook: cg.
	cg inferTypesForImplicitlyTypedVariablesAndMethods.
	cg retainMethods: self selectors.
	cg prepareMethods.
	cg doInlining: true.
	self selectors sort do:
		[:sel|
		(cg methodNamed: sel) ifNotNil:
			[:m|
			m parseTree nodesDo:
				[:node|
				(node isSend
				 and: [#* = node selector]) ifTrue:
					[Transcript ensureCr; nextPutAll: sel; space; print: node; flush]]]]
]

{ #category : #analysis }
SpurPlanningCompactor class >> identifySignedComparisonsFor: options noise: noise [
	"self identify32BitSignedComparisons"
	"self identify64BitSignedComparisons"
	| vmm cg |
	vmm := (VMMaker forPlatform: 'Cross')
				interpreterClass: StackInterpreter;
				options: options.
	cg := [vmm buildCodeGeneratorForInterpreter]
			on: Notification
			do: [:ex|
				ex tag == #getVMMaker
					ifTrue: [ex resume: vmm]
					ifFalse: [ex pass]].
	cg vmClass preGenerationHook: cg.
	cg inferTypesForImplicitlyTypedVariablesAndMethods.
	cg retainMethods: self selectors.
	cg prepareMethods.
	cg doInlining: true.
	self selectors sort do:
		[:sel|
		(cg methodNamed: sel) ifNotNil:
			[:m|
			m parseTree nodesDo:
				[:node|
				(node isSend
				 and: [(#(< > <= >=) includes: node selector)
				 and: [({node receiver. node args first } anySatisfy:
						[:o| (cg typeFor: o in: m)
								ifNil: [true]
								ifNotNil: [:t| (cg isIntegralCType: t) and: [t first ~= $u]]])
				 and: [noise noneSatisfy: [:n| n match: node printString]]]]) ifTrue:
					[Transcript ensureCr; nextPutAll: sel; space; print: node; flush]]]]
]

{ #category : #simulation }
SpurPlanningCompactor class >> simulatorClass [
	^SpurPlanningCompactorSimulator
]

{ #category : #'compaction - api' }
SpurPlanningCompactor >> biasForGC [
	<inline: true>
	biasForGC := true
]

{ #category : #'compaction - api' }
SpurPlanningCompactor >> biasForSnapshot [
	biasForGC := false
]

{ #category : #private }
SpurPlanningCompactor >> check: obj [
	"No-op in the real class."
	<inline: true>
]

{ #category : #private }
SpurPlanningCompactor >> coalesceFrom: maybeStartOfFree [
	"manager printOopsFrom: maybeStartOfFree to: manager endOfMemory"
	<var: 'maybeStartOfFree' type: #usqInt>
	|obj next objBytes nextBytes|
	<var: 'obj' type: #usqInt>
	<var: 'next' type: #usqInt>
	maybeStartOfFree >= manager endOfMemory ifTrue:
		[^self].
	obj := manager objectStartingAt: maybeStartOfFree.
	[next := manager oldSpaceObjectAfter: obj.
	 next < manager endOfMemory] whileTrue:
		[((manager isFreeObject: obj) and: [manager isFreeObject: next])
			ifTrue:
				[objBytes := manager bytesInObject: obj.
				 nextBytes := manager bytesInObject: next.
				 manager unlinkFreeChunk: obj chunkBytes: objBytes.
				 manager unlinkFreeChunk: next chunkBytes: nextBytes.
				 obj := manager freeChunkWithBytes: objBytes + nextBytes at: (manager startOfObject: obj)]
			ifFalse:
				[obj := next]]
]

{ #category : #'compaction - api' }
SpurPlanningCompactor >> compact [
	"Sweep all of old space, sliding unpinned marked objects down over free and unmarked objects.
	 Let the segmentManager mark which segments contain pinned objects via notePinned:."
	| finalPass firstPass |
	<inline: #never> "for profiling"
	self initializeScanCheckingForFullyCompactedHeap ifTrue:
		[^self unmarkObjectsInFullyCompactedHeap].
	self initializeCompaction.
	firstPass := true.
	[finalPass := self planCompactSavingForwarders.
	 self assert: (self validRelocationPlanInPass: finalPass) = 0.
	 self updatePointers.
	 self copyAndUnmark: firstPass.
	 "Would like to check here, but can't if multi-pass."
	 false ifTrue: [manager checkFreeSpace: GCModeFull].
	 "Currently we do only a single pass if a normal GC, assuming that a pass will
	  always compact plenty of space. But we should perhaps check this assumption
	  by looking at the large free tree and seeing that the ratio of the largest free
	  chunk to the total ammount of free space is high."
	 finalPass or: [biasForGC]] whileFalse:
		[firstPass := false.
		 self reinitializeScanFrom: firstFreeObject.
		 firstMobileObject > firstFreeObject ifFalse: 
			["We get here when firstFreeObject is the last object in memory. 
		   	 firstMobileObject may be random value from previous compaction
		   	 in this case, and heap is fully compacted. Abort compaction."
		  	 "We set firstFreeObject to firstMobileObject for unmarking."
			 firstFreeObject := firstMobileObject.
			 self unmarkObjectsFromFirstFreeObject.
		  	 manager checkFreeSpace: GCModeFull.
			 ^self endCompaction].
		 self updateSavedFirstFieldsSpaceIfNecessary].
	manager checkFreeSpace: GCModeFull.
	self endCompaction
]

{ #category : #compaction }
SpurPlanningCompactor >> copyAndUnmark: firstPass [
	"Sweep the heap, unmarking all objects and moving mobile objects to their correct positions,
	 restoring their savedFirstFields."
	<inline: #never>
	| finalPass |
	self logPhase: 'copying and unmarking...'.
	firstPass ifTrue:
		[self unmarkInitialImmobileObjects].
	finalPass := self copyAndUnmarkMobileObjects.
	(self thereAreObjectsToMove
	 and: [finalPass not
	 and: [biasForGC]]) ifTrue: "only ever one pass if biasForGC is true."
		[self unmarkObjectsFromFirstFreeObject]
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
	| toFinger top previousPin startOfPreviousPin |
	<var: 'o' type: #usqInt>
	<var: 'top' type: #usqInt>
	<var: 'toFinger' type: #usqInt>
	<var: 'previousPin' type: #usqInt>
	<var: 'startOfPreviousPin' type: #usqInt>
	self deny: (manager isMarked: firstFreeObject).
	toFinger := manager startOfObject: firstFreeObject.
	top := savedFirstFieldsSpace start.
	startOfPreviousPin := 0.
	manager allOldSpaceEntitiesForCompactingFrom: firstFreeObject to: (lastMobileObject ifNil: manager nilObject) do:
		[:o :n|
		 self check: o.
		 self assert: (previousPin
						ifNil: [toFinger <= (manager startOfObject: o)]
						ifNotNil: [(manager isMarked: previousPin) and: [toFinger <= startOfPreviousPin]]).
		 self assert: (savedFirstFieldsSpaceNotInOldSpace or: [toFinger < top]).
		 (manager isMarked: o) ifTrue:
			[(manager isPinned: o)
				ifTrue:
					[previousPin ifNil:
						[previousPin := o. startOfPreviousPin := manager startOfObject: o]]
				ifFalse:
					[| availableSpace bytes |
					 bytes := manager bytesInObject: o.
					 [toFinger <= startOfPreviousPin
					  and: [bytes ~= (availableSpace := startOfPreviousPin - toFinger)
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
							[previousPin := manager oldSpaceObjectAfter: previousPin].
						 previousPin >= o
							ifTrue: [previousPin := nil. startOfPreviousPin := 0]
							ifFalse: [startOfPreviousPin := manager startOfObject: previousPin]].
					 self copyAndUnmarkObject: o to: toFinger bytes: bytes firstField: (manager longAt: top).
					 toFinger := toFinger + bytes.
					 (top := top + manager bytesPerOop) >= savedFirstFieldsSpace limit ifTrue:
						[self assert: savedFirstFieldsSpace top = (top - manager bytesPerOop).
						 self assert: n = objectAfterLastMobileObject.
						 previousPin ifNil: [previousPin := n. startOfPreviousPin := manager startOfObject: n].
						 "Create a free object for firstFreeObject to be set to on the next pass, but
						   do not link it into the free tree as it will be written over in that next pass."
						 toFinger < startOfPreviousPin
							ifTrue:
								[firstFreeObject := manager initFreeChunkWithBytes: startOfPreviousPin - toFinger at: toFinger]
							ifFalse:
								[firstFreeObject := previousPin].
						^false]]]].
	self freeFrom: toFinger upTo: manager endOfMemory nextObject: (previousPin ifNil: [objectAfterLastMobileObject ifNil: [manager objectAfter: firstFreeObject]]).
	self coalesceFrom: toFinger.
	^true
]

{ #category : #compaction }
SpurPlanningCompactor >> copyAndUnmarkObject: o to: toFinger bytes: bytes firstField: firstField [
	"Copy the object to toFinger, clearing its mark bit both in the target and the corpse,
	 and restoring its firstField, which was overwritten with a forwarding pointer."
	<inline: true>
	| numSlots destObj start |
	manager setIsMarkedOf: o to: false.
	numSlots := manager rawNumSlotsOf: o.
	destObj := (manager objectWithRawSlotsHasOverflowHeader: numSlots)
					ifTrue: [toFinger + manager baseHeaderSize]
					ifFalse: [toFinger].
	start := manager startOfObject: o given: numSlots.
	"memmove must be used since the ranges may overlap."
	manager
		memmove: toFinger asVoidPointer _: start asVoidPointer _: bytes;
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
	self recordMovementOf: o to: toFinger savedFirstFieldPtr: savedFirstFieldPtr
]

{ #category : #private }
SpurPlanningCompactor >> freeFrom: initialToFinger upTo: limit nextObject: nextObject [
	"Free from toFinger up to limit, dealing with possible intervening pinned objects."
	<inline: false>
	<var: 'limit' type: #usqInt>
	<var: 'initialToFinger' type: #usqInt>
	| toFinger obj objStart |
	<var: 'objStart' type: #usqInt>
	<var: 'toFinger' type: #usqInt>
	self cCode: [] inSmalltalk:
		[coInterpreter cr; cr; print: 'freeing at '; printHexnp: initialToFinger; print: ' up to '; printHexnp: limit; cr].
	toFinger := initialToFinger.
	objStart := manager startOfObject: nextObject.
	toFinger < objStart ifTrue:
		[manager addFreeChunkWithBytes: objStart - toFinger at: toFinger].
	toFinger := objStart.
	[objStart < limit] whileTrue:
		[obj := manager objectStartingAt: objStart.
		 ((manager isMarked: obj) and: [manager isPinned: obj])
			ifTrue:
				[self unmarkPinned: obj.
				 toFinger < objStart ifTrue:
					[manager addFreeChunkWithBytes: objStart - toFinger at: toFinger].
				 toFinger := objStart := manager addressAfter: obj]
			ifFalse:
				[objStart := manager addressAfter: obj]].
	limit > toFinger ifTrue:
		[manager addFreeChunkWithBytes: limit - toFinger at: toFinger]
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
	"Scan for firstFreeObject and firstMobileObject from the start of memory.
	 Answer if the heap is already fully compacted."
	firstMobileObject := lastMobileObject := objectAfterLastMobileObject := nil.
	self reinitializeScanFrom: manager hiddenRootsObject.
	firstFreeObject ifNil:
		[self error: 'uncompactable heap; no unmarked objects found'].
	^firstMobileObject >= manager endOfMemory
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
	| toFinger top previousPin startOfPreviousPin |
	<var: 'o' type: #usqInt>
	<var: 'top' type: #usqInt>
	<var: 'toFinger' type: #usqInt>
	<var: 'previousPin' type: #usqInt>
	<var: 'startOfPreviousPin' type: #usqInt>
	savedFirstFieldsSpace top < savedFirstFieldsSpace start ifTrue:
		[self logPhase: 'planning...'].
	self deny: (manager isMarked: firstFreeObject).
	toFinger := manager startOfObject: firstFreeObject.
	top := savedFirstFieldsSpace start.
	startOfPreviousPin := 0.
	manager allOldSpaceEntitiesFrom: firstFreeObject do:
		[:o|
		 self check: o.
		 self assert: (previousPin
						ifNil: [toFinger <= (manager startOfObject: o)]
						ifNotNil: [(manager isMarked: previousPin) and: [toFinger <= startOfPreviousPin]]).
		 self assert: (savedFirstFieldsSpaceNotInOldSpace or: [toFinger < top]).
		 (manager isMarked: o) ifTrue:
			[(manager isPinned: o)
				ifTrue:
					[previousPin ifNil:
						[previousPin := o. startOfPreviousPin := manager startOfObject: o]]
				ifFalse:
					[| availableSpace bytes |
					 bytes := manager bytesInObject: o.
					 [toFinger <= startOfPreviousPin
					  and: [bytes ~= (availableSpace := startOfPreviousPin - toFinger)
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
							[previousPin := manager oldSpaceObjectAfter: previousPin].
						 previousPin >= o
							ifTrue: [previousPin := nil. startOfPreviousPin := 0]
							ifFalse: [startOfPreviousPin := manager startOfObject: previousPin]].
					 self forwardMobileObject: o to: toFinger savedFirstFieldPtr: top.
					 toFinger := toFinger + bytes.
					 (top := top + manager bytesPerOop) >= savedFirstFieldsSpace limit ifTrue:
						[savedFirstFieldsSpace top: top - manager bytesPerOop.
						 objectAfterLastMobileObject := manager oldSpaceObjectAfter: lastMobileObject.
						 ^false]]]].
	"If the heap is already fully compacted there will be no lastMobileObject..."
	lastMobileObject ifNotNil:
		[savedFirstFieldsSpace top: top - manager bytesPerOop.
		 objectAfterLastMobileObject := manager oldSpaceObjectAfter: lastMobileObject].
	^true
]

{ #category : #'debug support' }
SpurPlanningCompactor >> printTheBogons: aBogon [
	<inline: true>
	coInterpreter
		print: 'bogon '; printHexnp: aBogon; cr;
		print: 'anomaly '; printHexnp: anomaly; cr
]

{ #category : #private }
SpurPlanningCompactor >> recordMovementOf: o to: toFinger savedFirstFieldPtr: savedFirstFieldPtr [
	"No-op in the real class."
	<inline: true>
]

{ #category : #compaction }
SpurPlanningCompactor >> reinitializeScanFrom: initialObject [
	"Search for firstFreeObject and firstMobileObject from initialObject, which is the
	 hiddenRootsObject on the first pass, and the objectAfterLastMobileObject on
	 subsequent passes)."
	firstMobileObject := manager endOfMemory.
	firstFreeObject := self scanForFirstFreeAndFirstMobileObjectFrom: initialObject.
	firstFreeObject ifNotNil:
		[mobileStart := manager startOfObject: firstFreeObject].
	objectAfterLastMobileObject ifNotNil:
		[manager allOldSpaceEntitiesFrom: firstFreeObject to: objectAfterLastMobileObject do:
			[:o|
			 ((manager isPinned: o)
			  or: [(manager isMarked: o) not
			  or: [objectAfterLastMobileObject = o]]) ifFalse:
				[manager setIsMarkedOf: o to: false]].
		 firstMobileObject := objectAfterLastMobileObject]
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
	^savedFirstFieldsSpaceNotInOldSpace not
	 and: [self oop: savedFirstFieldsSpace start isGreaterThan: manager nilObject]
]

{ #category : #'space management' }
SpurPlanningCompactor >> savedFirstFieldsSpaceWasAllocated [
	<inline: true>
	^savedFirstFieldsSpaceNotInOldSpace
	 and: [self oop: savedFirstFieldsSpace start isGreaterThan: manager nilObject]
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

{ #category : #private }
SpurPlanningCompactor >> thereAreObjectsToMove [
	<inline: true>
	^lastMobileObject notNil
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
SpurPlanningCompactor >> unmarkObjectsFromFirstFreeObject [
	"Sweep the final immobile heap, freeing and coalescing unmarked and free objects,
	 and unmarking all marked objects up to the end of memory."
	| startOfFree freeBytes |
	freeBytes := 0.
	manager allOldSpaceEntitiesFrom: firstFreeObject do:
		[:o|
		self check: o.
		(manager isMarked: o)
			ifFalse:
				[startOfFree ifNil: [startOfFree := manager startOfObject: o].
				 freeBytes := freeBytes + (manager bytesInObject: o)]
			ifTrue:
				[startOfFree ifNotNil:
					[manager addFreeChunkWithBytes: freeBytes at: startOfFree.
					 startOfFree := nil.
					 freeBytes := 0].
				 (manager isPinned: o)
					ifTrue: [self unmarkPinned: o]
					ifFalse: [manager setIsMarkedOf: o to: false]]].
	startOfFree ifNotNil:
		[manager addFreeChunkWithBytes: freeBytes at: startOfFree].
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
	self thereAreObjectsToMove ifFalse:
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
		(self oop: o isGreaterThanOrEqualTo: firstFreeObject) ifTrue:
			[^self].
		"would like to assert this, but it isn't true if more than one pass: self assert: (manager isMarked: o)."
		self updatePointersIn: o]
]

{ #category : #compaction }
SpurPlanningCompactor >> updatePointersInManagerHeapEntities [
	"The special non-pointer objects containing pointers, which are the objStacks and the rememberedSet,
	 must be updated manually since they will not be recognized as containing pointers in the normal sweep."
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
	| toFinger top previousPin startOfPreviousPin |
	<var: 'o' type: #usqInt>
	<var: 'top' type: #usqInt>
	<var: 'toFinger' type: #usqInt>
	<var: 'previousPin' type: #usqInt>
	<var: 'startOfPreviousPin' type: #usqInt>
	self deny: (manager isMarked: firstFreeObject).
	toFinger := manager startOfObject: firstFreeObject.
	top := savedFirstFieldsSpace start.
	startOfPreviousPin := 0.
	manager allOldSpaceEntitiesFrom: firstFreeObject do:
		[:o|
		 self check: o.
		 self assert: (previousPin
						ifNil: [toFinger <= (manager startOfObject: o)]
						ifNotNil: [(manager isMarked: previousPin) and: [toFinger <= startOfPreviousPin]]).
		 (manager isMarked: o) ifTrue:
			[(manager isPinned: o)
				ifTrue:
					[previousPin ifNil:
						[previousPin := o. startOfPreviousPin := manager startOfObject: o].
					 self updatePointersIn: o]
				ifFalse:
					[| availableSpace bytes |
					 bytes := manager bytesInObject: o.
					 [toFinger <= startOfPreviousPin
					  and: [bytes ~= (availableSpace := startOfPreviousPin - toFinger)
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
							[previousPin := manager oldSpaceObjectAfter: previousPin].
						 previousPin >= o
							ifTrue: [previousPin := nil. startOfPreviousPin := 0]
							ifFalse: [startOfPreviousPin := manager startOfObject: previousPin]].
					 self updatePointersIn: o savedFirstFieldPointer: top.
					 toFinger := toFinger + bytes.
					 (top := top + manager bytesPerOop) >= savedFirstFieldsSpace limit ifTrue:
						[self assert: savedFirstFieldsSpace top = (top - manager bytesPerOop).
						 ^false]]]].
	self assert: savedFirstFieldsSpace top = (top - manager bytesPerOop).
	^true
]

{ #category : #compaction }
SpurPlanningCompactor >> updatePointersInObjectsOverflowingSavedFirstFieldsSpace [
	"Sweep the final immobile heap, is any (those objects with no room in savedFirstFieldsSpace
	 in the current pass) updating all references to mobile objects to their eventual locations."
	manager allOldSpaceObjectsFrom: objectAfterLastMobileObject do:
		[:o|
		self check: o.
		(manager isMarked: o) ifTrue:
			[self updatePointersIn: o]]
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
	(self savedFirstFieldsSpaceInFreeChunk
	 and: [savedFirstFieldsSpace start < lastMobileObject]) ifTrue:
		[(self findHighestSuitableFreeBlock: savedFirstFieldsSpace limit - savedFirstFieldsSpace start)
			ifNotNil:
				[:largestFreeChunk|
				 self useFreeChunkForSavedFirstFieldsSpace: largestFreeChunk]
			ifNil:
				[self useEdenForSavedFirstFieldsSpace]].

	savedFirstFieldsSpace top: savedFirstFieldsSpace start - manager bytesPerOop
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
	self assert: (manager validFreeTreeChunk: highestSuitableFreeBlock).
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
	| roundedSize allocatedSize |
	<var: #segAddress type: #'void *'>
	roundedSize := spaceEstimate + 1023 // 1024 * 1024.
	(manager "sent to the manager so that the simulator can increase memory to simulate a new segment"
		sqAllocateMemorySegmentOfSize: roundedSize
		Above: (manager segmentManager firstGapOfSizeAtLeast: roundedSize)
		AllocatedSizeInto: (self cCode: [self addressOf: allocatedSize]
								inSmalltalk: [[:sz| allocatedSize := sz]])) ifNotNil:
		[:segAddress|
		 savedFirstFieldsSpace
			start: segAddress asUnsignedIntegerPtr;
			limit: segAddress asUnsignedIntegerPtr + allocatedSize.
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
					[^savedFirstFieldsSpace top + manager bytesPerOop - savedFirstFieldsSpace start / manager bytesPerOop
					   = nMobiles
						ifTrue: [0]
						ifFalse: [3]]]]].
	"N.B. written this way so that if there are no mobiles the expression evaluates to 0 in Smalltalk /and/ in C unsigned arithmetic."
	^savedFirstFieldsSpace top + manager bytesPerOop - savedFirstFieldsSpace start / manager bytesPerOop
	  = nMobiles
		ifTrue: [0]
		ifFalse: [4]
]
