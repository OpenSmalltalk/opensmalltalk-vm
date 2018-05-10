"
Abstract class, in addition to SpurSweeper, while sweeping the heap I annotate segments with occupation rate. This is then used by compacting algorithms to compact only segments which are not used that much.
"
Class {
	#name : #SpurAnalysingSweeperCompactor,
	#superclass : #SpurSweeper,
	#instVars : [
		'segmentToFill'
	],
	#classVars : [
		'MaxOccupationForCompaction'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurAnalysingSweeperCompactor class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator var: 'segmentToFill' type: #'SpurSegmentInfo *'
]

{ #category : #initialization }
SpurAnalysingSweeperCompactor class >> initialize [
	super initialize.
	"If the segment is occupied by more than MaxOccupationForCompaction, 
	 it's not worth compacting it, whatever the rest of the system looks like.
	 MaxOccupationForCompaction is included in [0;16rFFFF]."
	MaxOccupationForCompaction := 16rA000. "Basically if segment is occupied by more than 60%, not worth compacting"
]

{ #category : #'segment to fill' }
SpurAnalysingSweeperCompactor >> allocateSegmentToFill [
	| res |
	res := manager growOldSpaceByAtLeast: manager growHeadroom.
	res ifNil: [self error: 'not enough memory for selective compaction'].
]

{ #category : #compaction }
SpurAnalysingSweeperCompactor >> assertNoSegmentBeingCompacted [
	"Assertion only - no segment is being claimed at this point"
	| segInfo |
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	0 to: manager numSegments - 1 do:
		[:i|
		 segInfo := self addressOf: (manager segmentManager segments at: i).
		 self deny: (self isSegmentBeingCompacted: segInfo)].
	
]

{ #category : #api }
SpurAnalysingSweeperCompactor >> compact [
	self subclassResponsibility
]

{ #category : #compaction }
SpurAnalysingSweeperCompactor >> compactSegment: segInfo freeStart: initialFreeStart [
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	| currentEntity fillStart bytesToCopy numSlots bridge |
	fillStart := initialFreeStart.
	bridge := manager segmentManager bridgeFor: segInfo.
	currentEntity := manager objectStartingAt: segInfo segStart.
	[self oop: currentEntity isLessThan: bridge] whileTrue:
		[(manager isFreeObject: currentEntity)
			ifTrue: 
				["To avoid confusing too much Spur (especially the leak/free checks), we mark the free chunk as a word object."
				 manager detachFreeObject: currentEntity.
				 manager set: currentEntity classIndexTo: manager wordSizeClassIndexPun formatTo: manager wordIndexableFormat]
			ifFalse: 
				["Copy the object in segmentToFill and replace it by a forwarder."
				 self assert: (manager isPinned: currentEntity) not. 
				 numSlots := manager numSlotsOfAny: currentEntity.
				 bytesToCopy := manager bytesInObject: currentEntity.
				 self assert: (manager objectBytesForSlots: numSlots) = (manager bytesInObject: currentEntity).
				 manager mem: fillStart asVoidPointer cp: (manager startOfObject: currentEntity) asVoidPointer y: bytesToCopy.
				 self assert: (manager baseHeader: (manager objectStartingAt: fillStart)) = (manager baseHeader: currentEntity).
				 self assert: (manager fetchPointer: numSlots - 1 ofObject: (manager objectStartingAt: fillStart)) = (manager fetchPointer: numSlots - 1 ofObject: currentEntity).
				 manager forward: currentEntity to: (manager objectStartingAt: fillStart).
				 fillStart := fillStart + (manager objectBytesForSlots: numSlots).
				 self assert: (manager isForwarded: currentEntity).
				 self assert: fillStart < (segmentToFill segLimit - manager bridgeSize)].
		 currentEntity := manager objectAfter: currentEntity limit: manager endOfMemory].
	self assert: currentEntity = bridge.
	^ fillStart
]

{ #category : #compaction }
SpurAnalysingSweeperCompactor >> compactSegmentsToCompact [
	"Forwards all objects in segments to compact and removes their freechunks"
	| segInfo fillStart |
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	fillStart := segmentToFill segStart.
	
	 "Removes initial free chunk in segment to fill... (Segment is entirely free)"
	manager detachFreeObject: (manager objectStartingAt: fillStart).
	
	 "Compact each segment to compact..."
	0 to: manager numSegments - 1 do:
		[:i| 
		 segInfo := self addressOf: (manager segmentManager segments at: i).
		(self isSegmentBeingCompacted: segInfo)
			ifTrue: [fillStart := self compactSegment: segInfo freeStart: fillStart ]].
		
	 "Final free chunk in segment to fill..."
	 manager 
		addFreeChunkWithBytes: segmentToFill segSize - manager bridgeSize + segmentToFill segStart - fillStart 
		at: fillStart.
	
	self postCompactionAction
	
]

{ #category : #compaction }
SpurAnalysingSweeperCompactor >> computeSegmentsToCompact [
	"Compute segments to compact: least occupied.
	 Answers true if at least 1 segment is being compacted."
	| canStillClaim aboutToClaim aboutToClaimSegment atLeastOneSegmentToCompact |
	<var: 'aboutToClaimSegment' type: #'SpurSegmentInfo *'>
	atLeastOneSegmentToCompact := false.
	aboutToClaimSegment := self findNextSegmentToCompact.
	"Segment to fill is one of the segment compacted last GC. 
	 If no segment were compacted last GC, and that there is 
	 at least one segment to compact, allocate a new one."
	aboutToClaimSegment ifNil: [^false].
	segmentToFill ifNil: [self findOrAllocateSegmentToFill].
	canStillClaim := segmentToFill segSize - manager bridgeSize.
	[aboutToClaimSegment ifNil: [^atLeastOneSegmentToCompact].
	 aboutToClaim := aboutToClaimSegment segSize - manager bridgeSize * ((self occupationOf: aboutToClaimSegment) + 1) // 16rFFFF. "+1 to round up, this is approx"
	 aboutToClaim < canStillClaim ] whileTrue: 
		[self markSegmentAsBeingCompacted: aboutToClaimSegment.
		 atLeastOneSegmentToCompact := true.
		 canStillClaim := canStillClaim - aboutToClaim.
		 aboutToClaimSegment := self findNextSegmentToCompact].
	^atLeastOneSegmentToCompact
]

{ #category : #'segment to fill' }
SpurAnalysingSweeperCompactor >> findAndSetSegmentToFill [
	| segInfo firstEntity |
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	0 to: manager numSegments - 1 do:
		[:i| 
		 segInfo := self addressOf: (manager segmentManager segments at: i).
		 firstEntity := manager objectStartingAt: segInfo segStart.
		 ((manager isFreeObject: firstEntity) and: [(manager objectAfter: firstEntity limit: manager endOfMemory) = (manager segmentManager bridgeFor: segInfo)])
			ifTrue: [segmentToFill := segInfo. ^0]].
	
]

{ #category : #compaction }
SpurAnalysingSweeperCompactor >> findNextSegmentToCompact [
	"Answers the next segment to compact or nil if none.
	  The next segment to compact:
	 - cannot be segment 0 (Segment 0 has specific objects 
	  (nil, true, etc.) and special size computed at start-up 
	  that we don't want to deal with)
	 - cannot have a high occupation rate (> MaxOccupationForCompaction)"
	| leastOccupied leastOccupiedSegment tempOccupied segInfo |
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	leastOccupied := 16rFFFF.
	1 to: manager numSegments - 1 do:
		[:i|
		 segInfo := self addressOf: (manager segmentManager segments at: i).
		 ((self isSegmentBeingCompacted: segInfo) or: [segInfo containsPinned or: [manager segmentManager isEmptySegment: segInfo] ])
			ifFalse: 
				[(tempOccupied := self occupationOf: segInfo) <= leastOccupied
					ifTrue: [ leastOccupied := tempOccupied.
							 leastOccupiedSegment := segInfo ]]].
	leastOccupied > MaxOccupationForCompaction ifTrue: [^nil].
	^ leastOccupiedSegment
]

{ #category : #'segment to fill' }
SpurAnalysingSweeperCompactor >> findOrAllocateSegmentToFill [
	"There was no compacted segments from past GC that we can directly re-use.
	 We need either to find an empty segment or allocate a new one."
	self findAndSetSegmentToFill.
	segmentToFill ifNotNil: [^0].
	"No empty segment. We need to allocate a new one"
	self allocateSegmentToFill.
	"We don't know which segment it is that we've just allocated... So we look for it... This is a bit dumb."
	self findAndSetSegmentToFill.
	self assert: segmentToFill ~~ nil.
	
]

{ #category : #'segment access' }
SpurAnalysingSweeperCompactor >> freeSegment: segInfo [
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	 manager addFreeChunkWithBytes: segInfo segSize - manager bridgeSize at: segInfo segStart.
]

{ #category : #'sweep phase' }
SpurAnalysingSweeperCompactor >> globalSweepAndSegmentOccupationAnalysis [
	self internalGlobalSweepAndSegmentOccupationAnalysis.
	manager checkFreeSpace: GCModeFull.
	manager unmarkSurvivingObjectsForCompact.
]

{ #category : #'sweep phase' }
SpurAnalysingSweeperCompactor >> internalGlobalSweepAndSegmentOccupationAnalysis [
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
SpurAnalysingSweeperCompactor >> isSegmentBeingCompacted: segInfo [ 
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	"Swizzle is abused bit 16 isBeingCompacted bits 0-15 occupation"
	^ segInfo swizzle anyMask: 1 << 16
]

{ #category : #'segment access' }
SpurAnalysingSweeperCompactor >> markSegmentAsBeingCompacted: segInfo [ 
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	"Swizzle is abused bit 16 isBeingCompacted bits 0-15 occupation"
	segInfo swizzle: (segInfo swizzle bitOr: 1 << 16)
]

{ #category : #'segment access' }
SpurAnalysingSweeperCompactor >> occupationOf: segInfo [ 
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	"Swizzle is abused bit 16 isBeingCompacted bits 0-15 occupation"
	^segInfo swizzle bitAnd: 16rFFFF
]

{ #category : #compaction }
SpurAnalysingSweeperCompactor >> postCompactionAction [
	self postForwardingAction
]

{ #category : #compaction }
SpurAnalysingSweeperCompactor >> postForwardingAction [
	| allFlags |
	"For now we don't optimize and just follow everything everywhere on stack and in caches, let's see in the profiler if we need to optimize with those cases. My guess is that this is < 100 microSecond"
	manager followSpecialObjectsOop.
	allFlags := BecamePointerObjectFlag + BecameActiveClassFlag bitOr: BecameCompiledMethodFlag.
	manager coInterpreter postBecomeAction: allFlags.
	manager postBecomeScanClassTable: allFlags.
]

{ #category : #api }
SpurAnalysingSweeperCompactor >> postSwizzleAction [
	"Since the compact abuses the swizzle field of segment, it needs to be rest after start-up."
	| segInfo |
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	0 to: manager numSegments - 1 do:
		[:i|
		 segInfo := self addressOf: (manager segmentManager segments at: i).
		 segInfo swizzle: 0 ]
]

{ #category : #compaction }
SpurAnalysingSweeperCompactor >> selectiveCompaction [
	"Figures out which segments to compact and compact them into segmentToFill"
	| atLeastOneSegmentToCompact |
	self assertNoSegmentBeingCompacted.
	atLeastOneSegmentToCompact := self computeSegmentsToCompact.
	"If no compaction we don't pay forwarding cost (stack scan, cache scan, etc.)
	 and we don't allocate segmentToFill if none available."
	atLeastOneSegmentToCompact 
		ifTrue:
			[self assert: segmentToFill ~~ nil.
		 	 self compactSegmentsToCompact].
	manager checkFreeSpace: GCModeFull.
]

{ #category : #'segment access' }
SpurAnalysingSweeperCompactor >> setOccupationAtIndex: segmentIndex used: used unused: unused [
	"WARNING: Resets the isCompacted bit"
	"Swizzle is abused bit 16 isBeingCompacted bits 0-15 occupation
	 Setting occupation resets the claim bit"
	| occupation segInfo |
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	segInfo := self addressOf: (manager segmentManager segments at: segmentIndex).
	occupation := used * 16rFFFF // (used + unused).
	segInfo swizzle: occupation
]
