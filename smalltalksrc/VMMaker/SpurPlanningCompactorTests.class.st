Class {
	#name : #SpurPlanningCompactorTests,
	#superclass : #TestCase,
	#pools : [
		'VMSqueakClassIndices'
	],
	#category : #'VMMaker-Tests'
}

{ #category : #debugger }
SpurPlanningCompactorTests class >> defaultIntegerBaseInDebugger [
	^VMClass defaultIntegerBaseInDebugger
]

{ #category : #accessing }
SpurPlanningCompactorTests class >> imageNameForTests [
	"self imageNameForTests"
	| baseImageName |
	baseImageName := 'core32-preen.image'.
	#('.' 'oscogvm/image' '../oscogvm/image') do:
		[:dirName|
		 ((FileDirectory default directoryExists: dirName)
		  and: [(FileDirectory on: dirName) fileExists: baseImageName]) ifTrue:
			[^dirName, '/', baseImageName]].
	self error: 'cannot find ', baseImageName
]

{ #category : #utilities }
SpurPlanningCompactorTests class >> preenImage [
	"Assume there's a Pharo bootstrap core32.image in ../oscogvm/image/core32.image.
	 We should find out where the image directory is and write a download script to get it.
	 But for now assume it's there."
	"[SpurPlanningCompactorTests preenImage] timeToRun"
	Spur32BitPreen new
		writeDefaultHeader: true;
		savedWindowSize: 640@480;
		preenImage: '../oscogvm/image/core32'
]

{ #category : #accessing }
SpurPlanningCompactorTests class >> resources [
	^{SpurPlanningCompactorTestsImageResource}
]

{ #category : #private }
SpurPlanningCompactorTests >> initializedVM [
	| newVM |
	newVM := self resources anyOne current emptyVM cloneSimulation.
	newVM
		openOn: self class imageNameForTests extraMemory: 0;
		initStackPages.
	newVM objectMemory
		initializeMarkStack; "The Pharo bootstrap has no mark or weakling stacks :-)"
		initializeWeaklingStack.
	^newVM
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
