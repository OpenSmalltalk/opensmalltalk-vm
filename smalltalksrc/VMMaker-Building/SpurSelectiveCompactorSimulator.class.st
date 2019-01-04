Class {
	#name : #SpurSelectiveCompactorSimulator,
	#superclass : #SpurSelectiveCompactor,
	#classVars : [
		'Talking'
	],
	#category : #'VMMaker-SpurMemoryManagerSimulation'
}

{ #category : #initialization }
SpurSelectiveCompactorSimulator class >> initialize [
	super initialize.
	Talking := true.
]

{ #category : #debugging }
SpurSelectiveCompactorSimulator >> checkOnlyForwardersOrWordNonImm: segInfo [
	"Also check this is iterable until bridge 
	 prevEntity is here for debugging only"
	| currentEntity prevEntity bridge |
	self talk: 'Checking segment compacted has fwd/Word only ' , (manager segmentManager indexOfSegment: segInfo) printString.
	bridge := manager segmentManager bridgeFor: segInfo.
	currentEntity := manager objectStartingAt: segInfo segStart.
	[self oop: currentEntity isLessThan: bridge] whileTrue: 
		[self assert: ((manager isWordsNonImm: currentEntity) or: [manager isForwarded: currentEntity]).
		 prevEntity := currentEntity.
		 currentEntity := manager objectAfter: currentEntity limit: manager endOfMemory].
	self assert: currentEntity = bridge.
	self talkNoCr: ' OK'.
]

{ #category : #debugging }
SpurSelectiveCompactorSimulator >> checkSegmentToFillLooksAllRight [
	"Check only 1 free object at the end or none.
	 Check segment is iterable until bridge"
	| currentEntity bridge |
	self talk: 'Checking segment to fill iterable/last is free ' , (manager segmentManager indexOfSegment: segmentToFill) printString.
	bridge := manager segmentManager bridgeFor: segmentToFill.
	currentEntity := manager objectStartingAt: segmentToFill segStart.
	[self oop: currentEntity isLessThan: bridge] whileTrue: 
		[(manager isFreeObject: currentEntity) 
			ifTrue: "should be last entity"
				[self assert: (manager objectAfter: currentEntity limit: manager endOfMemory) = bridge.
				 manager assertValidFreeObject: currentEntity].
		 currentEntity := manager objectAfter: currentEntity limit: manager endOfMemory].
	"End of iteration should end on bridge"
	self assert: currentEntity = bridge.
	self talkNoCr: ' OK'.
]

{ #category : #debugging }
SpurSelectiveCompactorSimulator >> checkSegmentsIterable [
	"Check only 1 free object at the end or none.
	 Check segment is iterable until bridge"
	| currentEntity bridge |
	self talk: 'Checking segments iterable'.
	0 to: manager numSegments - 1 do:
		[:i| | segInfo |
		 segInfo := self addressOf: (manager segmentManager segments at: i).
		 bridge := manager segmentManager bridgeFor: segInfo.
		 currentEntity := manager objectStartingAt: segInfo segStart.
		 [self oop: currentEntity isLessThan: bridge] whileTrue: 
			[currentEntity := manager objectAfter: currentEntity limit: manager endOfMemory].
		 "End of iteration should end on bridge"
		 self assert: currentEntity = bridge.].
	self talkNoCr: ' OK'.
]

{ #category : #api }
SpurSelectiveCompactorSimulator >> compact [
	self talk: '~~ Start selective compaction ~~'.
	self tellMeNumSegmentAndTotalFreeSpace.
	self tellMeWhichSegmentsAreBeingCompacted.
	super compact.
	self tellMeNumSegmentAndTotalFreeSpace.
	self tellMeWhichSegmentsAreBeingCompacted.
	manager runLeakCheckerForFreeSpace: GCModeFreeSpace.
	self talk: '~~ Finished selective compaction ~~'.
	
]

{ #category : #compaction }
SpurSelectiveCompactorSimulator >> compactSegmentsToCompact [
	self talk: 'filling segment ' , (manager segmentManager indexOfSegment: segmentToFill).
	super compactSegmentsToCompact.
	"Now segments to compacts should have been compacted into segment to fill"
	self checkSegmentToFillLooksAllRight.
	
]

{ #category : #compaction }
SpurSelectiveCompactorSimulator >> computeSegmentsToCompact [
	| res |
	res := super computeSegmentsToCompact.
	res	
		ifTrue: [self talk: 'There is something to compact!'.
				self tellMeWhichSegmentsAreBeingCompacted]
		ifFalse: [self talk: 'Nothing to compact!'].
	^ res
]

{ #category : #freeing }
SpurSelectiveCompactorSimulator >> freePastSegmentsAndSetSegmentToFill [
	super freePastSegmentsAndSetSegmentToFill.
	segmentToFill
		ifNil: [self talk: 'No segment to fill so far - will allocate one later if anything to compact']
		ifNotNil: [self talk: 'filling segment ' , (manager segmentManager indexOfSegment: segmentToFill)].
	
]

{ #category : #'sweep phase' }
SpurSelectiveCompactorSimulator >> globalSweepAndSegmentOccupationAnalysis [
	super globalSweepAndSegmentOccupationAnalysis.
	self talk: 'Occupation map: '.
	0 to: manager numSegments - 1 do:
		[:i| | segInfo |
		 segInfo := self addressOf: (manager segmentManager segments at: i).
		 self talkNoCr: i.
		 self talkNoCr: '->'.
		 self talkNoCr: (self occupationOf: segInfo) printString.
		 self talkNoCr: '('.
		 self talkNoCr: ((self occupationOf: segInfo) * 100 * 100 // 16rFFFF / 100) asFloat printString.
		 self talkNoCr: '%);'].
	self checkSegmentsIterable.
	
]

{ #category : #compaction }
SpurSelectiveCompactorSimulator >> markSegmentAsBeingCompacted: segInfo [ 
	super markSegmentAsBeingCompacted: segInfo.
	self talk: 'Marking as being compacted segment ' , (manager segmentManager indexOfSegment: segInfo) printString.
]

{ #category : #compaction }
SpurSelectiveCompactorSimulator >> selectiveCompaction [
	super selectiveCompaction.
	manager allFreeObjectsDo: [:objOop | manager assertValidFreeObject: objOop]
]

{ #category : #debugging }
SpurSelectiveCompactorSimulator >> talk: string [
	Talking ifTrue: [Transcript cr; show: string]
]

{ #category : #debugging }
SpurSelectiveCompactorSimulator >> talkNoCr: string [
	Talking ifTrue: [Transcript show: string]
]

{ #category : #debugging }
SpurSelectiveCompactorSimulator >> tellMeNumSegmentAndTotalFreeSpace [
	self talk: 'numSegments: ' , manager numSegments printString , ', free space: ' , manager totalFreeOldSpace printString.
]

{ #category : #debugging }
SpurSelectiveCompactorSimulator >> tellMeWhichSegmentsAreBeingCompacted [
	<doNotGenerate> 
	| beingCompacted |
	beingCompacted := OrderedCollection new.
	0 to: manager numSegments - 1 do:
		[:i| | segInfo |
		 segInfo := self addressOf: (manager segmentManager segments at: i).
		(self isSegmentBeingCompacted: segInfo) ifTrue: [beingCompacted add: segInfo]].
	self 
		talk: 'Segment being compacted: ' , 
			(beingCompacted collect: [:seg | 
				manager segmentManager indexOfSegment: seg ]) asArray printString
	
]
