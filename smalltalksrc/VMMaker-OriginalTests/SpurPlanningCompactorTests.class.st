Class {
	#name : #SpurPlanningCompactorTests,
	#superclass : #LongTestCase,
	#pools : [
		'VMBasicConstants',
		'VMSqueakClassIndices'
	],
	#category : #'VMMaker-OriginalTests'
}

{ #category : #debugger }
SpurPlanningCompactorTests class >> defaultIntegerBaseInDebugger [
	^VMClass defaultIntegerBaseInDebugger
]

{ #category : #utilities }
SpurPlanningCompactorTests class >> preenImage [
	"Assume there's a Pharo bootstrap core32.image in ../oscogvm/image/core32.image.
	 We should find out where the image directory is and write a download script to get it.
	 But for now assume it's there.  See e.g.
		https://bintray.com/pharo-project/pharo/Pharo/201701061402-32bit#files"
	"[SpurPlanningCompactorTests preenImage] timeToRun"
	Spur32BitPreen new
		writeDefaultHeader: true;
		savedWindowSize: 640@480;
		preenImage: '../oscogvm/image/core32'
]

{ #category : #accessing }
SpurPlanningCompactorTests class >> resources [
	^{SpurImageTestResource}
]

{ #category : #private }
SpurPlanningCompactorTests >> checkForLeaksIn: om [
	om setCheckForLeaks: GCModeFreeSpace + GCModeFull;
		runLeakCheckerFor: GCModeFull;
		checkFreeSpace: GCModeFull
]

{ #category : #failures }
SpurPlanningCompactorTests >> expectedFailures [
	^(SpurImageTestResource imageNameForTests asFileReference exists)
		ifTrue: [#()]
		ifFalse: [self testSelectors]
]

{ #category : #private }
SpurPlanningCompactorTests >> initializedVM [
	| newVM |
	newVM := self resources anyOne current emptyVM cloneSimulation.
	newVM
		openOn: SpurImageTestResource imageNameForTests extraMemory: 0;
		initStackPages.
	newVM objectMemory
		initializeMarkStack; "The Pharo bootstrap has no mark or weakling stacks :-)"
		initializeWeaklingStack.
	^newVM
]

{ #category : #tests }
SpurPlanningCompactorTests >> testCompactedHeap [
	"First test for valid compactibility of an already compacted heap via fullGC"
	| freeSpace om |
	om := self initializedVM objectMemory.
	freeSpace := om bytesLeftInOldSpace.
	om fullGC.
	self assert: freeSpace equals: om bytesLeftInOldSpace.
	self checkForLeaksIn: om.
	om fullGC.
	self assert: freeSpace equals: om bytesLeftInOldSpace.
	self checkForLeaksIn: om
]

{ #category : #tests }
SpurPlanningCompactorTests >> testIncompactibleHeap [
	| errored |
	errored := false.
	"First test for incompactibility via fullGC"
	[self initializedVM objectMemory
		abandonEmptySegmentForTests;
		fullGC]
		on: Error
		do: [:ex|
			errored := true.
			self assert: ex messageText = 'uncompactable heap; no unmarked objects found'].
	self assert: errored.

	"Now check for incompactibility by directly calling compact"
	errored := false.
	"First test for incompactibility via fullGC"
	[| om |
	 om := self initializedVM objectMemory.
	 om abandonEmptySegmentForTests.
	 om allOldSpaceObjectsDo: [:o| om setIsMarkedOf: o to: true].
	 om compactor compact]
		on: Error
		do: [:ex|
			errored := true.
			self assert: ex messageText = 'uncompactable heap; no unmarked objects found'].
	self assert: errored
]

{ #category : #tests }
SpurPlanningCompactorTests >> testInitializedVM [
	self checkForLeaksIn: self initializedVM objectMemory
]

{ #category : #tests }
SpurPlanningCompactorTests >> testMultiPassRandomAssortments [
	"Test that the compactor can handle multi-pass compaction of some
	 number of random assortments of live, pinned, dead, and free chunks."
	<timeout: 60>
	| random |
	random := Random new.
	10 timesRepeat:
		[| theVM |
		 theVM := self initializedVM.
		 theVM objectMemory compactor forceMultiPass.
		 self testRandomAssortment: (random next: 3000) readStream
			with: theVM]
]

{ #category : #tests }
SpurPlanningCompactorTests >> testMultiPassRandomAssortmentsWithNewSegment [
	"Test that the compactor can handle multi-pass compaction of some number of
	 random assortments of live, pinned, dead, and free chunks allocated in a new segment."
	<timeout: 60>
	| random |
	random := Random new.
	10 timesRepeat:
		[| theVM |
		 theVM := self initializedVM.
		 theVM objectMemory compactor forceMultiPass.
		 self testRandomAssortmentWithNewSegment: (random next: 5000) readStream
			with: theVM]
]

{ #category : #private }
SpurPlanningCompactorTests >> testRandomAssortment: random with: theVM [
	"Test that the compactor can handle a random assortment of live, pinned, dead, and free chunks."
	| om lastObj obj expectedFreeSpace liveFill pinFill liveCount pinCount totalLive totalPinned pinned |
	random reset. "random is a read stream on 3000 random numbers; for repeatability"
	om := theVM objectMemory.
	om allOldSpaceObjectsDo: [:o| om setIsMarkedOf: o to: true. lastObj := o].
	pinFill := 16r99999900.
	liveFill := 16r55AA0000.
	liveCount := pinCount := expectedFreeSpace := 0.
	pinned := Set new.
	1000 timesRepeat:
		[| nSlots next newObj |
		 nSlots := (random next * 300) rounded. "Make sure we stray into overflow size field territory."
		 newObj := om allocateSlotsInOldSpace: nSlots format: om firstLongFormat classIndex: ClassByteArrayCompactIndex.
		 (next := random next) > 0.95
			ifTrue: "pinned"
				[om
					fillObj: newObj numSlots: nSlots with: pinFill + (pinCount := pinCount + 1);
					setIsPinnedOf: newObj to: true]
			ifFalse: "mobile"
				[om
					fillObj: newObj numSlots: nSlots with: liveFill + (liveCount := liveCount + 1)].
		 (next := random next) >= 0.333
			ifTrue:
				[om setIsMarkedOf: newObj to: true.
				 (om isPinned: newObj) ifTrue:
					[pinned add: newObj]]
			ifFalse: "dead or free"
				[expectedFreeSpace := expectedFreeSpace + (om bytesInObject: newObj).
				 (om isPinned: newObj) "Must check /before/ setObjectFree: which clears all bits"
					ifTrue: [pinCount := pinCount - 1]
					ifFalse: [liveCount := liveCount - 1].
				 next >= 0.2
					ifTrue: [om setIsMarkedOf: newObj to: false]
					ifFalse: [om setObjectFree: newObj]]].
	totalPinned := pinCount.
	totalLive := liveCount.
	self assert: totalPinned < (totalPinned + totalLive / 10). "should average 5%"

	"useful pre-compaction printing:"
	false ifTrue:
		[liveCount := pinCount := 0.
		 om allOldSpaceEntitiesFrom: (om objectAfter: lastObj) to: (om objectBefore: om endOfMemory) do:
			[:o|
			om coInterpreter print:
				((om isMarked: o)
					ifTrue: [(((om isPinned: o)
									ifTrue: [pinCount := pinCount + 1]
									ifFalse: [liveCount := liveCount + 1])
								printPaddedWith: Character space to: 3 base: 10), ' '] 
					ifFalse: ['     ']).
			 om printEntity: o].
		 om allOldSpaceEntitiesFrom: (om objectAfter: lastObj) to: (om objectBefore: om endOfMemory) do:
			[:o|
			((om isMarked: o) and: [om isPinned: o]) ifTrue:
				[om printEntity: o]]].

	expectedFreeSpace := expectedFreeSpace + om bytesLeftInOldSpace.
	om compactor compact.
	self assert: expectedFreeSpace equals: om bytesLeftInOldSpace.
	self assert: om allObjectsUnmarked.

	"useful post-compaction printing:"
	false ifTrue:
		[liveCount := pinCount := 0.
		 om allOldSpaceEntitiesFrom: (om objectAfter: lastObj) to: (om objectBefore: om endOfMemory) do:
			[:o|
			om coInterpreter print:
				((om isFreeObject: o)
					ifFalse: [(((om isPinned: o)
									ifTrue: [pinCount := pinCount + 1]
									ifFalse: [liveCount := liveCount + 1])
								printPaddedWith: Character space to: 3 base: 10), ' '] 
					ifTrue: ['     ']).
			 om printEntity: o].
		 om allOldSpaceEntitiesFrom: (om objectAfter: lastObj) to: (om objectBefore: om endOfMemory) do:
			[:o|
			(om isPinned: o) ifTrue:
				[om printEntity: o]]].

	"First check and/or count populations..."
	liveCount := pinCount := 0.
	om allOldSpaceObjectsFrom: (om objectAfter: lastObj) do:
		[:o|
		(om isPinned: o)
			ifTrue:
				[pinCount := pinCount + 1.
				 self assert: (pinned includes: o)]
			ifFalse: [liveCount := liveCount + 1]].
	self assert: totalPinned equals: pinCount.
	self assert: totalLive equals: liveCount.

	"Now check fills, which also tests update of first field on move..."
	liveCount := pinCount := 0.
	obj := lastObj.
	1 to: totalLive + totalPinned do:
		[:n| | expectedFill actualFill |
		 [obj := om objectAfter: obj. (om isEnumerableObject: obj) or: [obj >= om endOfMemory]] whileFalse.
		 expectedFill := (om isPinned: obj)
							ifTrue: [pinFill + (pinCount := pinCount + 1)]
							ifFalse: [liveFill + (liveCount := liveCount + 1)].
		 1 to: (om numSlotsOf: obj) do:
			[:i| self assert: expectedFill equals: (actualFill := om fetchPointer: i - 1 ofObject: obj)]].
	"They should be the last objects..."
	self assert: (om isFreeObject: (om objectAfter: obj)).
	self assert: om endOfMemory equals: (om addressAfter: (om objectAfter: obj)).
	self checkForLeaksIn: om
]

{ #category : #private }
SpurPlanningCompactorTests >> testRandomAssortmentWithNewSegment: random with: theVM [
	"Test that the compactor can handle a random assortment of live, pinned, dead, and free chunks,
	 with some allocation in a new segment.  No live pinned objects are created in the new segment
	 to obtain the situation that the last segment is entirely empty after compaction.  This tests shrinkage."
	| om pig lastObj obj expectedFreeSpace liveFill pinFill liveCount pinCount totalLive totalPinned pinned |
	random reset. "random is a read stream on 3000 random numbers; for repeatability"
	om := theVM objectMemory.
	om allOldSpaceObjectsDo: [:o| om setIsMarkedOf: o to: true. lastObj := o].

	pinFill := 16r99999900.
	liveFill := 16r55AA0000.
	liveCount := pinCount := expectedFreeSpace := 0.
	pinned := Set new.

	1000 timesRepeat:
		[| nSlots next newObj |
		 nSlots := (random next * 300) rounded. "Make sure we stray into overflow size field territory."
		 newObj := om allocateSlotsInOldSpace: nSlots format: om firstLongFormat classIndex: ClassByteArrayCompactIndex.
		 (next := random next) > 0.95
			ifTrue: "pinned"
				[om
					fillObj: newObj numSlots: nSlots with: pinFill + (pinCount := pinCount + 1);
					setIsPinnedOf: newObj to: true]
			ifFalse: "mobile"
				[om
					fillObj: newObj numSlots: nSlots with: liveFill + (liveCount := liveCount + 1)].
		 (next := random next) >= 0.333
			ifTrue:
				[om setIsMarkedOf: newObj to: true.
				 (om isPinned: newObj) ifTrue:
					[pinned add: newObj]]
			ifFalse: "dead or free"
				[expectedFreeSpace := expectedFreeSpace + (om bytesInObject: newObj).
				 (om isPinned: newObj) "Must check /before/ setObjectFree: which clears all bits"
					ifTrue: [pinCount := pinCount - 1]
					ifFalse: [liveCount := liveCount - 1].
				 next >= 0.2
					ifTrue: [om setIsMarkedOf: newObj to: false]
					ifFalse: [om setObjectFree: newObj]]].

	 pig := om allocateSlotsInOldSpace: (om numSlotsOfAny: om findLargestFreeChunk) format: om firstLongFormat classIndex: ClassByteArrayCompactIndex.
	 self deny: pig isNil.
	 self assert: 0 equals: om bytesLeftInOldSpace.
	 om growOldSpaceByAtLeast: om growHeadroom // 2.
	 self assert: om growHeadroom equals: om bytesLeftInOldSpace + om bridgeSize.
	 expectedFreeSpace := expectedFreeSpace + (om bytesInObject: pig).

	1000 timesRepeat:
		[| nSlots next newObj |
		 nSlots := (random next * 300) rounded. "Make sure we stray into overflow size field territory."
		 newObj := om allocateSlotsInOldSpace: nSlots format: om firstLongFormat classIndex: ClassByteArrayCompactIndex.
		 "No pinned objects in second segment."
		 om fillObj: newObj numSlots: nSlots with: liveFill + (liveCount := liveCount + 1).
		 (next := random next) >= 0.333
			ifTrue:
				[om setIsMarkedOf: newObj to: true.
				 (om isPinned: newObj) ifTrue:
					[pinned add: newObj]]
			ifFalse: "dead or free"
				[expectedFreeSpace := expectedFreeSpace + (om bytesInObject: newObj).
				 liveCount := liveCount - 1.
				 next >= 0.2
					ifTrue: [om setIsMarkedOf: newObj to: false]
					ifFalse: [om setObjectFree: newObj]]].

	totalPinned := pinCount.
	totalLive := liveCount.
	self assert: totalPinned < (totalPinned + totalLive / 20). "should average 2.5%"

	"useful pre-compaction printing:"
	false ifTrue:
		[liveCount := pinCount := 0.
		 om allOldSpaceEntitiesFrom: (om objectAfter: lastObj) to: (om objectBefore: om endOfMemory) do:
			[:o|
			om coInterpreter print:
				((om isMarked: o)
					ifTrue: [(((om isPinned: o)
									ifTrue: [pinCount := pinCount + 1]
									ifFalse: [liveCount := liveCount + 1])
								printPaddedWith: Character space to: 3 base: 10), ' '] 
					ifFalse: ['     ']).
			 om printEntity: o].
		 om allOldSpaceEntitiesFrom: (om objectAfter: lastObj) to: (om objectBefore: om endOfMemory) do:
			[:o|
			((om isMarked: o) and: [om isPinned: o]) ifTrue:
				[om printEntity: o]]].

	expectedFreeSpace := expectedFreeSpace + om bytesLeftInOldSpace.
	om compactor compact.
	self assert: expectedFreeSpace equals: om bytesLeftInOldSpace.
	self assert: om allObjectsUnmarked.

	"useful post-compaction printing:"
	false ifTrue:
		[liveCount := pinCount := 0.
		 om allOldSpaceEntitiesFrom: (om objectAfter: lastObj) to: (om objectBefore: om endOfMemory) do:
			[:o|
			om coInterpreter print:
				((om isFreeObject: o)
					ifFalse: [(((om isPinned: o)
									ifTrue: [pinCount := pinCount + 1]
									ifFalse: [liveCount := liveCount + 1])
								printPaddedWith: Character space to: 3 base: 10), ' '] 
					ifTrue: ['     ']).
			 om printEntity: o].
		 om allOldSpaceEntitiesFrom: (om objectAfter: lastObj) to: (om objectBefore: om endOfMemory) do:
			[:o|
			(om isPinned: o) ifTrue:
				[om printEntity: o]]].

	"First check and/or count populations..."
	liveCount := pinCount := 0.
	om allOldSpaceObjectsFrom: (om objectAfter: lastObj) do:
		[:o|
		(om isPinned: o)
			ifTrue:
				[pinCount := pinCount + 1.
				 self assert: (pinned includes: o)]
			ifFalse: [liveCount := liveCount + 1]].
	self assert: totalPinned equals: pinCount.
	self assert: totalLive equals: liveCount.

	"Now check fills, which also tests update of first field on move..."
	liveCount := pinCount := 0.
	obj := lastObj.
	1 to: totalLive + totalPinned do:
		[:n| | expectedFill actualFill |
		 [obj := om objectAfter: obj. (om isEnumerableObject: obj) or: [obj >= om endOfMemory]] whileFalse.
		 expectedFill := (om isPinned: obj)
							ifTrue: [pinFill + (pinCount := pinCount + 1)]
							ifFalse: [liveFill + (liveCount := liveCount + 1)].
		 1 to: (om numSlotsOf: obj) do:
			[:i| self assert: expectedFill equals: (actualFill := om fetchPointer: i - 1 ofObject: obj)]].
	"the Last segment should be empty"
	self assert: (om segmentManager isEmptySegment: (om segmentManager segments at: 1)).
	"They should be the last objects, followed by a free object to the end fo the first segment, a bridge, then an empty segment with a single free object in it."
	self assert: (om isFreeObject: (om objectAfter: obj)).
	self assert: (om isSegmentBridge: (om objectAfter: (om objectAfter: obj))).
	self assert: (om isFreeObject: (om objectAfter: (om objectAfter: (om objectAfter: obj)))).
	self assert: om endOfMemory equals: (om addressAfter: (om objectAfter: (om objectAfter: (om objectAfter: obj)))).

	"And the memory should shrink if the shrinkThreshold is low enough"
	om shrinkThreshold: om growHeadroom.
	om attemptToShrink.
	self assert: om segmentManager numSegments = 1.
	self checkForLeaksIn: om
]

{ #category : #tests }
SpurPlanningCompactorTests >> testRandomAssortments [
	"Test that the compactor can handle some number of random assortments of live, pinned, dead, and free chunks."
	<timeout: 60>
	| random |
	random := Random new.
	10 timesRepeat:
		[self testRandomAssortment: (random next: 3000) readStream
			with: self initializedVM]
]

{ #category : #tests }
SpurPlanningCompactorTests >> testRandomAssortmentsWithNewSegment [
	"Test that the compactor can handle some number of random assortments of live, pinned, dead, and free chunks
	 allocated in a new segment."
	<timeout: 60>
	| random |
	random := Random new.
	10 timesRepeat:
		[self testRandomAssortmentWithNewSegment: (random next: 6000) readStream
			with: self initializedVM]
]

{ #category : #tests }
SpurPlanningCompactorTests >> testRunOfContiguousPinnedObjects [
	"Test that the compactor can handle a long run of adjacent pinned objects across which it can and must move some unpinned objects."
	| om expectedFreeSpace firstPinnedObj gapObj obj |
	om := self initializedVM objectMemory.
	om allOldSpaceObjectsDo: [:o| om setIsMarkedOf: o to: true].
	"First create a gap"
	gapObj := om allocateSlotsInOldSpace: 100 format: om firstLongFormat classIndex: ClassArrayCompactIndex.
	om fillObj: gapObj numSlots: 100 with: om falseObject.
	self deny: (om isMarked: gapObj).
	"Now a long run of pinned objects."
	20 timesRepeat:
		[obj := om allocateSlotsInOldSpace: 4 format: om firstLongFormat classIndex: ClassBitmapCompactIndex.
		 om
			fillObj: obj numSlots: 4 with: 16r99999999;
			setIsPinnedOf: obj to: true;
			setIsMarkedOf: obj to: true.
		 firstPinnedObj ifNil:
			[firstPinnedObj := obj]].
	"Now something to move around it."
	obj := om allocateSlotsInOldSpace: 100 format: om firstLongFormat classIndex: ClassBitmapCompactIndex.
	om fillObj: obj numSlots: 100 with: 16r55AA55AA;
		setIsMarkedOf: obj to: true.
	"And something to move to the end of it."
	obj := om allocateSlotsInOldSpace: 100 format: om firstLongFormat classIndex: ClassBitmapCompactIndex.
	om fillObj: obj numSlots: 100 with: 16rAA55AA55;
		setIsMarkedOf: obj to: true.

	"useful debugging:""om printOopsFrom: gapObj to: om endOfMemory"
	expectedFreeSpace := om bytesLeftInOldSpace + (om bytesInObject: gapObj).
	om compactor compact.
	self assert: expectedFreeSpace equals: om bytesLeftInOldSpace.
	self assert: om allObjectsUnmarked.

	"The first mobile object past the pinned objects should have moved."
	self assert: ClassBitmapCompactIndex equals: (om classIndexOf: gapObj).
	self deny: (om isPinned: gapObj). 
	0 to: 99 do: [:i| self assert: 16r55AA55AA equals: (om fetchPointer: i ofObject: gapObj)].
	"The pinned objects should not have moved."
	obj := firstPinnedObj.
	20 timesRepeat:
		[self assert: ClassBitmapCompactIndex equals: (om classIndexOf: obj).
		 0 to: 3 do: [:i| self assert: 16r99999999 equals: (om fetchPointer: i ofObject: obj)].
		 obj := om objectAfter: obj].
	"The last object should have moved down."
	self assert: ClassBitmapCompactIndex equals: (om classIndexOf: obj).
	self deny: (om isPinned: obj). 
	0 to: 99 do: [:i| self assert: 16rAA55AA55 equals: (om fetchPointer: i ofObject: obj)].
	"It should be the last object..."
	self assert: (om isFreeObject: (om objectAfter: obj)).
	self assert: om endOfMemory equals: (om addressAfter: (om objectAfter: obj))
		
]

{ #category : #tests }
SpurPlanningCompactorTests >> testRunOfNonContiguousPinnedObjects [
	"Test that the compactor can handle a long run of adjacent pinned objects separated by small ammounts of free space, across which it can and must move some unpinned objects."
	| om expectedFreeSpace firstPinnedObj gapObj obj numPins |
	om := self initializedVM objectMemory.
	om allOldSpaceObjectsDo: [:o| om setIsMarkedOf: o to: true].
	"First create a gap"
	gapObj := om allocateSlotsInOldSpace: 100 format: om firstLongFormat classIndex: ClassArrayCompactIndex.
	om fillObj: gapObj numSlots: 100 with: om falseObject.
	self deny: (om isMarked: gapObj).
	"Now a long run of pinned objects."
	(numPins := 20) timesRepeat:
		[obj := om allocateSlotsInOldSpace: 4 format: om firstLongFormat classIndex: ClassBitmapCompactIndex.
		 om
			fillObj: obj numSlots: 4 with: 16r99999999;
			setIsPinnedOf: obj to: true;
			setIsMarkedOf: obj to: true.
		 firstPinnedObj ifNil:
			[firstPinnedObj := obj].
		 om allocateSlotsInOldSpace: 4 format: om firstLongFormat classIndex: ClassArrayCompactIndex].
	"Now something to move around it."
	obj := om allocateSlotsInOldSpace: 100 format: om firstLongFormat classIndex: ClassBitmapCompactIndex.
	om fillObj: obj numSlots: 100 with: 16r55AA55AA;
		setIsMarkedOf: obj to: true.
	"And something to move to the end of it."
	obj := om allocateSlotsInOldSpace: 100 format: om firstLongFormat classIndex: ClassBitmapCompactIndex.
	om fillObj: obj numSlots: 100 with: 16rAA55AA55;
		setIsMarkedOf: obj to: true.

	"useful debugging:""om printOopsFrom: gapObj to: om endOfMemory"
	expectedFreeSpace := om bytesLeftInOldSpace + (om bytesInObject: gapObj) + ((om bytesInObject: firstPinnedObj) * numPins).
	om compactor compact.
	self assert: expectedFreeSpace equals: om bytesLeftInOldSpace.
	self assert: om allObjectsUnmarked.

	"The first mobile object past the pinned objects should have moved."
	self assert: ClassBitmapCompactIndex equals: (om classIndexOf: gapObj).
	self deny: (om isPinned: gapObj). 
	0 to: 99 do: [:i| self assert: 16r55AA55AA equals: (om fetchPointer: i ofObject: gapObj)].
	"The pinned objects should not have moved."
	obj := firstPinnedObj.
	1 to: numPins do:
		[:n|
		 self assert: ClassBitmapCompactIndex equals: (om classIndexOf: obj).
		 0 to: 3 do: [:i| self assert: 16r99999999 equals: (om fetchPointer: i ofObject: obj)].
		 obj := om objectAfter: obj.
		 n < numPins ifTrue:
			[self assert: (om isFreeObject: obj).
			 obj := om objectAfter: obj]].
	"The last object should have moved down."
	self assert: ClassBitmapCompactIndex equals: (om classIndexOf: obj).
	self deny: (om isPinned: obj). 
	0 to: 99 do: [:i| self assert: 16rAA55AA55 equals: (om fetchPointer: i ofObject: obj)].
	"It should be the last object..."
	self assert: (om isFreeObject: (om objectAfter: obj)).
	self assert: om endOfMemory equals: (om addressAfter: (om objectAfter: obj))
		
]

{ #category : #tests }
SpurPlanningCompactorTests >> testRunOfNonContiguousPinnedObjectsWithSpaceInBetween [
	"Test that the compactor can handle a long run of adjacent pinned objects separated by large ammounts of free space, into which it can and must move some unpinned objects."
	| om expectedFreeSpace firstPinnedObj gapObj obj numPins firstFreeObj |
	om := self initializedVM objectMemory.
	om allOldSpaceObjectsDo: [:o| om setIsMarkedOf: o to: true].
	"First create a gap"
	gapObj := om allocateSlotsInOldSpace: 100 format: om firstLongFormat classIndex: ClassArrayCompactIndex.
	om fillObj: gapObj numSlots: 100 with: om falseObject.
	self deny: (om isMarked: gapObj).
	"Now a long run of pinned objects."
	(numPins := 10) timesRepeat:
		[obj := om allocateSlotsInOldSpace: 4 format: om firstLongFormat classIndex: ClassBitmapCompactIndex.
		 om
			fillObj: obj numSlots: 4 with: 16r99999999;
			setIsPinnedOf: obj to: true;
			setIsMarkedOf: obj to: true.
		 firstPinnedObj ifNil:
			[firstPinnedObj := obj].
		 obj := om allocateSlotsInOldSpace: 104 format: om firstLongFormat classIndex: ClassArrayCompactIndex.
		 firstFreeObj ifNil:
			[firstFreeObj := obj]].
	self deny: (om isMarked: firstFreeObj).
	"Now some objects to move around and into the run of pinned objects."
	numPins timesRepeat:
		[obj := om allocateSlotsInOldSpace: 100 format: om firstLongFormat classIndex: ClassBitmapCompactIndex.
		 om fillObj: obj numSlots: 100 with: 16r55AA55AA;
			setIsMarkedOf: obj to: true.
		 obj := om allocateSlotsInOldSpace: 100 format: om firstLongFormat classIndex: ClassBitmapCompactIndex.
		 om fillObj: obj numSlots: 100 with: 16rAA55AA55;
			setIsMarkedOf: obj to: true].

	"useful debugging:""om printOopsFrom: gapObj to: om endOfMemory"
	expectedFreeSpace := om bytesLeftInOldSpace + (om bytesInObject: gapObj) + ((om bytesInObject: firstFreeObj) * numPins).
	om compactor compact.
	self assert: expectedFreeSpace equals: om bytesLeftInOldSpace.
	self assert: om allObjectsUnmarked.

	"The first mobile object past the pinned objects should have moved. The pinned objects should not have moved.
	 We should see moved obj, pinned obj, (moved obj, free obj, pinned obj) +"
	obj := gapObj.
	1 to: numPins do:
		[:n|
		 self assert: ClassBitmapCompactIndex equals: (om classIndexOf: obj).
		 self deny: (om isPinned: obj). 
		 0 to: 99 do: [:i| self assert: (n odd ifTrue: [16r55AA55AA] ifFalse: [16rAA55AA55]) equals: (om fetchPointer: i ofObject: obj)].
		 obj := om objectAfter: obj.
		 n > 1 ifTrue:
			[self assert: (om isFreeObject: obj).
			 obj := om objectAfter: obj].
		 self assert: ClassBitmapCompactIndex equals: (om classIndexOf: obj).
		 self assert: (om isPinned: obj).
		 0 to: 3 do: [:i| self assert: 16r99999999 equals: (om fetchPointer: i ofObject: obj)].
		 obj := om objectAfter: obj].
	"The last objects should have moved down."
	1 to: numPins do:
		[:n|
		 self assert: ClassBitmapCompactIndex equals: (om classIndexOf: obj).
		 self deny: (om isPinned: obj). 
		 0 to: 99 do: [:i| self assert: (n odd ifTrue: [16r55AA55AA] ifFalse: [16rAA55AA55]) equals: (om fetchPointer: i ofObject: obj)]..
		 obj := om objectAfter: obj].
	"They should be the last objects..."
	self assert: (om isFreeObject: obj).
	self assert: om endOfMemory equals: (om addressAfter: obj)
		
]

{ #category : #tests }
SpurPlanningCompactorTests >> testRunOfObjectsWithExtraSegment [
	"Test that the compactor can handle compacting more than one segment and shortening the memory."
	| om expectedFreeSpace pig gapObj obj |
	om := self initializedVM objectMemory.
	om allOldSpaceObjectsDo: [:o| om setIsMarkedOf: o to: true].
	"First create a gap"
	gapObj := om allocateSlotsInOldSpace: 100 format: om firstLongFormat classIndex: ClassArrayCompactIndex.
	om fillObj: gapObj numSlots: 100 with: om falseObject.
	self deny: (om isMarked: gapObj).
	expectedFreeSpace := om bytesInObject: gapObj.
	"Now some objects, a gap to a new segment and another run of objects."
	1 to: 2 do:
		[:i|
		10 timesRepeat:
			[obj := om allocateSlotsInOldSpace: 50 format: om firstLongFormat classIndex: ClassBitmapCompactIndex.
			 om fillObj: obj numSlots: 50 with: 16r55AA55AA;
				setIsMarkedOf: obj to: true.
			 obj := om allocateSlotsInOldSpace: 260 format: om firstLongFormat classIndex: ClassBitmapCompactIndex.
			om fillObj: obj numSlots: 260 with: 16rAA55AA55;
				setIsMarkedOf: obj to: true].
		i = 1 ifTrue:
			[pig := om allocateSlotsInOldSpace: (om numSlotsOfAny: om findLargestFreeChunk) format: om firstLongFormat classIndex: ClassBitmapCompactIndex.
			 self deny: pig isNil.
			 self assert: 0 equals: om bytesLeftInOldSpace.
			 om growOldSpaceByAtLeast: om growHeadroom // 2.
			 self assert: om growHeadroom equals: om bytesLeftInOldSpace + om bridgeSize.
			 expectedFreeSpace := expectedFreeSpace + (om bytesInObject: pig)]].

	"useful debugging:""om printOopsFrom: gapObj to: om endOfMemory"
	expectedFreeSpace := expectedFreeSpace + om bytesLeftInOldSpace.
	om compactor compact.
	self assert: expectedFreeSpace equals: om bytesLeftInOldSpace.
	self assert: om allObjectsUnmarked.

	"The first mobile object past the pinned objects should have moved."
	self assert: ClassBitmapCompactIndex equals: (om classIndexOf: gapObj).
	obj := gapObj.
	"The objects have moved."
	20 timesRepeat:
		[self assert: ClassBitmapCompactIndex equals: (om classIndexOf: obj).
		 0 to: (om numSlotsOf: obj) - 1 do: [:i| self assert: 16r55AA55AA equals: (om fetchPointer: i ofObject: obj)].
		 obj := om objectAfter: obj.
		 self assert: ClassBitmapCompactIndex equals: (om classIndexOf: obj).
		 0 to: (om numSlotsOf: obj) - 1 do: [:i| self assert: 16rAA55AA55 equals: (om fetchPointer: i ofObject: obj)].
		 obj := om objectAfter: obj].
	"the Last segment should be empty"
	self assert: (om segmentManager isEmptySegment: (om segmentManager segments at: 1)).
	"They should be the last objects, followed by a free object to the end fo the first segment, a bridge, then an empty segment with a single free object in it."
	self assert: (om isFreeObject: obj).
	self assert: (om isSegmentBridge: (om objectAfter: obj)).
	self assert: (om isFreeObject: (om objectAfter: (om objectAfter: obj))).
	self assert: om endOfMemory equals: (om addressAfter: (om objectAfter: (om objectAfter: obj))).

	"And the memory should shrink if the shrinkThreshold is low enough"
	om shrinkThreshold: om growHeadroom.
	om attemptToShrink.
	self assert: om segmentManager numSegments = 1
]
