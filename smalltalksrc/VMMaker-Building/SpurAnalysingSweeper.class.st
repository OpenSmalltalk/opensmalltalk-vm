"
Abstract class, in addition to SpurSweeper, while sweeping the heap I annotate segments with occupation rate. This can be used by a compacting algorithm to compact only segments which are not used a lot.
"
Class {
	#name : #SpurAnalysingSweeper,
	#superclass : #SpurSweeper,
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #'sweep phase' }
SpurAnalysingSweeper >> globalSweepAndSegmentOccupationAnalysis [
	self internalGlobalSweepAndSegmentOccupationAnalysis.
	manager checkFreeSpace: GCModeFull.
	manager unmarkSurvivingObjectsForCompact.
]

{ #category : #'sweep phase' }
SpurAnalysingSweeper >> internalGlobalSweepAndSegmentOccupationAnalysis [
	"Iterate over old space, free unmarked objects, annotate each segment with each occupation"
	| currentEntity nextBridge start segmentIndex currentUsed currentUnused |
	currentEntity := manager firstObject.
	nextBridge := manager segmentManager bridgeAt: 0.
	segmentIndex := currentUnused := currentUsed := 0.
	[self oop: currentEntity isLessThan: manager endOfMemory] whileTrue:
		[currentEntity = nextBridge
			ifTrue: 
				["End of segment, set occupation"
				  self 
					setOccupationAtIndex: segmentIndex
					used: currentUsed 
					unused: currentUnused.
				  currentUnused := currentUsed := 0.
				  segmentIndex := segmentIndex + 1.
				  self unmark: currentEntity.
				  nextBridge := manager segmentManager bridgeAt: segmentIndex]
			ifFalse: 
				["In-segment, sweep and compute occupation"
				 (self canUseAsFreeSpace: currentEntity) 
					ifTrue: 
						["bulkFreeChunkFrom: may change a 1 word header
						object to a double word header object"
						start := manager startOfObject: currentEntity.
						self bulkFreeChunkFrom: currentEntity.
						currentEntity := manager objectStartingAt: start.
						currentUnused := currentUnused + (manager numSlotsOfAny: currentEntity)]
					ifFalse: 
						[self unmark: currentEntity.
						 currentUsed := currentUsed + (manager numSlotsOfAny: currentEntity)]].
		 currentEntity := manager objectAfter: currentEntity limit: manager endOfMemory].
	"set last segment (last bridge = endOfMemory)"	
	self 
		setOccupationAtIndex: segmentIndex
		used: currentUsed 
		unused: currentUnused.
]

{ #category : #'segment access' }
SpurAnalysingSweeper >> occupationOf: segInfo [ 
	self subclassResponsibility
]

{ #category : #'segment access' }
SpurAnalysingSweeper >> setOccupationAtIndex: segmentIndex used: used unused: unused [
	self subclassResponsibility
]
