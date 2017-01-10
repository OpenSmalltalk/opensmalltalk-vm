Class {
	#name : #SpurPlanningCompactorTests,
	#superclass : #TestCase,
	#instVars : [
		'emptyVM'
	],
	#category : #'VMMaker-Tests'
}

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
	^emptyVM cloneSimulation
		openOn: self class imageNameForTests extraMemory: 0;
		initStackPages;
		yourself
]

{ #category : #tests }
SpurPlanningCompactorTests >> testIncompactibleHeap [
	| errored |
	errored := false.
	[self initializedVM objectMemory
		initializeMarkStack; "The Pharo bootstrap has no mark or weakling stacks :-)"
		initializeWeaklingStack;
		abandonEmptySegmentForTests;
		fullGC]
		on: Error
		do: [:ex|
			errored := true.
			self assert: ex messageText = 'uncompactable heap; no unmarked objects found'].
	self assert: errored
]
