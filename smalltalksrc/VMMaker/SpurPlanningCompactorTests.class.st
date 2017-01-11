Class {
	#name : #SpurPlanningCompactorTests,
	#superclass : #TestCase,
	#instVars : [
		'emptyVM'
	],
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

{ #category : #'initialize-release' }
SpurPlanningCompactorTests >> initialize [
	emptyVM := StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager
																 compactorClass SpurPlanningCompactor)
]

{ #category : #private }
SpurPlanningCompactorTests >> initializedVM [
	| newVM |
	newVM := emptyVM cloneSimulation.
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
	"Now a long run of pinned objects."
	50 timesRepeat:
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


	expectedFreeSpace := om bytesLeftInOldSpace + (om bytesInObject: gapObj).
	om compactor compact.
	self assert: expectedFreeSpace equals: om bytesLeftInOldSpace.
	om allOldSpaceObjectsDo: [:o| self deny: (om isMarked: o)].

	"The first mobile object past the pinned objects should have moved."
	self assert: ClassBitmapCompactIndex equals: (om classIndexOf: gapObj).
	self deny: (om isPinned: gapObj). 
	0 to: 99 do: [:i| self assert: 16r55AA55AA equals: (om fetchPointer: i ofObject: gapObj)].
	"The pinned objects should not have moved."
	obj := firstPinnedObj.
	50 timesRepeat:
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
