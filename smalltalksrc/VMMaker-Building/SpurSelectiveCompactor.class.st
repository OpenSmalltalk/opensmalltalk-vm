"
SpurSelectiveCompactor compacts memory by selecting the memory segments with the most free space and compacting only those, to limit fragmentation while being really quick to perform. The algorithm is fast mostly because it does not update pointers: they are updated lazily during the next marking phase, so there is no need to read the fields of objects in other memory segments that the one compacted.

The algorithm works as follow. First, a global sweep pass iterates over the memory linearly, changing unmarked objects to free chunks and concatenating free chunks. During the global sweep phase, the segments of the heap are analysed to determine the percentage of occupation. Second, the least occupied segments are compacted by copying the remaining live objects into an entirely free segment, called regionToFill (we detail later in the paragraph where regionToFill comes from), changing their values to forwarding objects and marking the free chunks as unavailable (removed from free list and marked as data objects). Third, the next marking phase removes all forwarders. Fourth, at the beginning of the next compaction phase the compacted segments from the previous GC can be entirely marked as free space (No need to check anything inside, there were only forwarders and trash data). One of the compacted segment is then selected as the segmentToFill, others are just marked as free chunks. 

The compaction is effectively partial, compacting only the most critical segments of the heap to limit fragmentation. Compaction time is crazy low, since a low number of objects are moved and pointer updated is lazily done during the next marking phase, while still preventing memory fragmentation.

Now this works well when biasForGC is true, but when performing a snapshot, the compactor is just total crap (we need to figure out a solution).

segmentToFill <SegInfo> the segment that will be filled through the copying algorithm

Segment abuse:
The swizzle field of segInfo is abused by using the low 8 bits for occupation and the 9th bit as isBeingCompacted bit.
"
Class {
	#name : #SpurSelectiveCompactor,
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
SpurSelectiveCompactor class >> declareCVarsIn: aCCodeGenerator [
	super declareCVarsIn: aCCodeGenerator.
	aCCodeGenerator var: 'segmentToFill' type: #'SpurSegmentInfo *'
]

{ #category : #initialization }
SpurSelectiveCompactor class >> initialize [
	super initialize.
	"If the segment is occupied by more than MaxOccupationForCompaction, 
	 it's not worth compacting it, whatever the rest of the system looks like.
	 MaxOccupationForCompaction is included in [0;16rFFFF]."
	MaxOccupationForCompaction := 16rD000. "81%"
]

{ #category : #simulation }
SpurSelectiveCompactor class >> simulatorClass [
	^ SpurSelectiveCompactor"Simulator"
]

{ #category : #'segment to fill' }
SpurSelectiveCompactor >> allocateSegmentToFill [
	| res |
	res := manager growOldSpaceByAtLeast: manager growHeadroom.
	res ifNil: [self error: 'not enough memory for selective compaction'].
]

{ #category : #compaction }
SpurSelectiveCompactor >> assertNoSegmentBeingCompacted [
	"Assertion only - no segment is being claimed at this point"
	| segInfo |
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	0 to: manager numSegments - 1 do:
		[:i|
		 segInfo := self addressOf: (manager segmentManager segments at: i).
		 self deny: (self isSegmentBeingCompacted: segInfo)].
	
]

{ #category : #api }
SpurSelectiveCompactor >> compact [
	<inline: #never> "for profiling"
	self freePastSegmentsAndSetSegmentToFill.
	self globalSweepAndSegmentOccupationAnalysis.
	self selectiveCompaction.
	
]

{ #category : #compaction }
SpurSelectiveCompactor >> compactSegment: segInfo freeStart: initialFreeStart [
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	| currentEntity fillStart bytesToCopy bridge copy |
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
				 bytesToCopy := manager bytesInObject: currentEntity.
				 manager mem: fillStart asVoidPointer cp: (manager startOfObject: currentEntity) asVoidPointer y: bytesToCopy.
				 copy := manager objectStartingAt: fillStart.
				 (manager isRemembered: copy) ifTrue: 
					["copy has the remembered bit set, but is not in the remembered table."
					 manager setIsRememberedOf: copy to: false.
					 scavenger remember: copy].
				 manager forward: currentEntity to: (manager objectStartingAt: fillStart).
				 fillStart := fillStart + bytesToCopy.
				 self assert: (self oop: fillStart isLessThan: (segmentToFill segLimit - manager bridgeSize))].
		 currentEntity := manager objectAfter: currentEntity limit: manager endOfMemory].
	self assert: currentEntity = bridge.
	^ fillStart
]

{ #category : #compaction }
SpurSelectiveCompactor >> compactSegmentsToCompact [
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
SpurSelectiveCompactor >> computeSegmentsToCompact [
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
	 aboutToClaim := self sizeClaimedIn: aboutToClaimSegment.
	 aboutToClaim < canStillClaim ] whileTrue: 
		[self markSegmentAsBeingCompacted: aboutToClaimSegment.
		 atLeastOneSegmentToCompact := true.
		 canStillClaim := canStillClaim - aboutToClaim.
		 aboutToClaimSegment := self findNextSegmentToCompact].
	^atLeastOneSegmentToCompact
]

{ #category : #'segment to fill' }
SpurSelectiveCompactor >> findAndSetSegmentToFill [
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
SpurSelectiveCompactor >> findNextSegmentToCompact [
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
	leastOccupied > MaxOccupationForCompaction ifTrue:
		[^self cCoerceSimple: nil to: #'SpurSegmentInfo *'].
	^leastOccupiedSegment
]

{ #category : #'segment to fill' }
SpurSelectiveCompactor >> findOrAllocateSegmentToFill [
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
SpurSelectiveCompactor >> freePastSegmentsAndSetSegmentToFill [	
	"The first segment being claimed met becomes the segmentToFill. The others are just freed."
	| segInfo |
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	segmentToFill := nil.
	0 to: manager numSegments - 1 do:
		[:i|
		 segInfo := self addressOf: (manager segmentManager segments at: i).
		 (self isSegmentBeingCompacted: segInfo)
			ifTrue: 
				[self freeSegment: segInfo.
				 segmentToFill ifNil: [segmentToFill := segInfo]]]
]

{ #category : #'segment access' }
SpurSelectiveCompactor >> freeSegment: segInfo [
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	 manager addFreeChunkWithBytes: segInfo segSize - manager bridgeSize at: segInfo segStart.
]

{ #category : #'sweep phase' }
SpurSelectiveCompactor >> globalSweepAndSegmentOccupationAnalysis [
	self internalGlobalSweepAndSegmentOccupationAnalysis.
	manager checkFreeSpace: GCModeFull.
	manager unmarkSurvivingObjectsForCompact.
]

{ #category : #'sweep phase' }
SpurSelectiveCompactor >> internalGlobalSweepAndSegmentOccupationAnalysis [
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
						currentUnused := currentUnused + (manager bytesInObject: currentEntity)]
					ifFalse: 
						[self unmark: currentEntity.
						 currentUsed := currentUsed + (manager bytesInObject: currentEntity)]].
		 currentEntity := manager objectAfter: currentEntity limit: manager endOfMemory].
	"set last segment (last bridge = endOfMemory)"	
	self 
		setOccupationAtIndex: segmentIndex
		used: currentUsed 
		unused: currentUnused.
]

{ #category : #'segment access' }
SpurSelectiveCompactor >> isSegmentBeingCompacted: segInfo [ 
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	"Swizzle is abused bit 16 isBeingCompacted bits 0-15 occupation"
	^ segInfo swizzle anyMask: 1 << 16
]

{ #category : #'segment access' }
SpurSelectiveCompactor >> markSegmentAsBeingCompacted: segInfo [ 
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	"Swizzle is abused bit 16 isBeingCompacted bits 0-15 occupation"
	segInfo swizzle: (segInfo swizzle bitOr: 1 << 16)
]

{ #category : #'segment access' }
SpurSelectiveCompactor >> occupationOf: segInfo [ 
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	"Swizzle is abused bit 16 isBeingCompacted bits 0-15 occupation"
	^segInfo swizzle bitAnd: 16rFFFF
]

{ #category : #compaction }
SpurSelectiveCompactor >> postCompactionAction [
	| allFlags |
	"For now we don't optimize and just follow everything everywhere on stack and in caches, let's see in the profiler if we need to optimize with those cases. My guess is that this is < 100 microSecond"
	manager followSpecialObjectsOop.
	allFlags := BecamePointerObjectFlag + BecameActiveClassFlag bitOr: BecameCompiledMethodFlag.
	"should be gcMode Become - gcMode flag is cleared after postBecomeAction"
	manager coInterpreter postBecomeAction: allFlags.
	manager postBecomeScanClassTable: allFlags.
	manager coInterpreter setGCMode: GCModeFull.
	
	"Not sure the following are needed...
	coInterpreter mapInterpreterOops.
	manager mapExtraRoots."
	self assert: manager validClassTableHashes.
]

{ #category : #api }
SpurSelectiveCompactor >> postSwizzleAction [
	"Since the compact abuses the swizzle field of segment, it needs to be reset after start-up."
	| segInfo |
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	0 to: manager numSegments - 1 do:
		[:i|
		 segInfo := self addressOf: (manager segmentManager segments at: i).
		 segInfo swizzle: 0 ]
]

{ #category : #compaction }
SpurSelectiveCompactor >> selectiveCompaction [
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
SpurSelectiveCompactor >> setOccupationAtIndex: segmentIndex used: used unused: unused [
	"WARNING: Resets the isCompacted bit"
	"Swizzle is abused bit 16 isBeingCompacted bits 0-15 occupation
	 Setting occupation resets the claim bit"
	| occupation segInfo |
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	segInfo := self addressOf: (manager segmentManager segments at: segmentIndex).
	"careful with overflow here..."
	occupation := ((used asFloat / (used + unused)) * 16rFFFF) asInteger.
	self assert: (occupation between: 0 and: 16rFFFF).
	segInfo swizzle: occupation
]

{ #category : #'segment access' }
SpurSelectiveCompactor >> sizeClaimedIn: segment [ 
	<var: 'segment' type: #'SpurSegmentInfo *'>
	<var: 'ratio' type: #'double'>
	"careful with overflow here"
	"roundedup used ratio (+1 to round up)"
	| ratio |
	ratio := ((self occupationOf: segment) + 1) asFloat / 16rFFFF.
	^(ratio * (segment segSize - manager bridgeSize)) asInteger 
]
