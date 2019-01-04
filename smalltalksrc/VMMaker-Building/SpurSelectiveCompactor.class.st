"
SpurSelectiveCompactor compacts memory by selecting the memory segments with the most free space and compacting only those, to limit fragmentation while being really quick to perform. The algorithm is fast mostly because it does not update pointers: they are updated lazily during the next marking phase, so there is no need to read the fields of objects in other memory segments that the one compacted.

The algorithm works as follow. First, a global sweep pass iterates over the memory linearly, changing unmarked objects to free chunks and concatenating free chunks. During the global sweep phase, the segments of the heap are analysed to determine the percentage of occupation. Second, the least occupied segments are compacted by copying the remaining live objects into an entirely free segment, called regionToFill (we detail later in the paragraph where regionToFill comes from), changing their values to forwarding objects and marking the free chunks as unavailable (removed from free list and marked as data objects). Third, the next marking phase removes all forwarders. Fourth, at the beginning of the next compaction phase the compacted segments from the previous GC can be entirely marked as free space (No need to check anything inside, there were only forwarders and trash data). One of the compacted segment is then selected as the segmentToFill, others are just marked as free chunks. 

The compaction is effectively partial, compacting only the most critical segments of the heap to limit fragmentation. Compaction time is crazy low, since a low number of objects are moved and pointer updated is lazily done during the next marking phase, while still preventing memory fragmentation.

Now this works well when biasForGC is true, but when performing a snapshot, the compactor is just total crap (we need to figure out a solution).

segmentToFill <SegInfo> the segment that will be filled through the copying algorithm
lastLilliputianChunk <Oop to FreeChunk> This is used as a performance trick for lilliputian free chunks. See below.

Segment abuse:
The swizzle field of segInfo is abused by using the low 8 bits for occupation and the 9th bit as isBeingCompacted bit.

Performance trick for lilliputian chunks:
Specific free chunks (called lilliputian, see isLilliputianSize:) are managed using a single linked list instead of a double linked list since there's not enough room in the free chunk for the back pointer. During the sweep phase this is not a problem since we're rebuilding the free chunk structure, but during selective compaction we're detaching free chunks from the free chunk structure and that can be horribly slow (10 seconds sometimes at 20Gb heap due to many iteration over the single linked list). To work around this problem, the sweep phase use lastLilliputianChunk variable to sort the lilliputian free chunk single linked list in ascending address order (See interceptAddFreeChunkWithBytes:at:). During the selective compation phase, the same variable is re-used to iterate at most once over the single linked list while detaching lilliputian chunks (See incrementalUnlinkSmallChunk:). In addition, each segment is annotated during the sweep phase with the last lilliputian chunk it holds. Hence, during the compaction phase, the linked list is iterated but the iteration can jump to the last chunk of the previous segment to compact.
"
Class {
	#name : #SpurSelectiveCompactor,
	#superclass : #SpurSweeper,
	#instVars : [
		'segmentToFill',
		'lastLilliputianChunk'
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
	<inline: #never> "for profiling, though we profile selectiveCompaction and sweep separatly."
	self resetFreeLists.
	self freePastSegmentsAndSetSegmentToFill.
	self globalSweepAndSegmentOccupationAnalysis.
	self assert: self sortedLilliputianChunks.
	manager updateSweepEndUsecs.
	self selectiveCompaction.
	
]

{ #category : #compaction }
SpurSelectiveCompactor >> compactSegment: segInfo freeStart: initialFreeStart segIndex: segIndex [
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	| currentEntity fillStart bytesToCopy bridge copy |
	fillStart := initialFreeStart.
	bridge := manager segmentManager bridgeFor: segInfo.
	currentEntity := manager objectStartingAt: segInfo segStart.
	self deny: segIndex = 0. "Cannot compact seg 0"
	lastLilliputianChunk := self lastLilliputianChunkAtIndex: segIndex - 1.
	[self oop: currentEntity isLessThan: bridge] whileTrue:
		[(manager isFreeObject: currentEntity)
			ifTrue: 
				["To avoid confusing too much Spur (especially the leak/free checks), we mark the free chunk as a word object."
				 (manager isLilliputianSize: (manager bytesInObject: currentEntity)) 
					ifTrue: [self incrementalUnlinkLilliputianChunk: currentEntity] "Performance hack for single linked list"
					ifFalse: [manager detachFreeObject: currentEntity].
				 manager set: currentEntity classIndexTo: manager wordSizeClassIndexPun formatTo: manager wordIndexableFormat]
			ifFalse: 
				["Copy the object in segmentToFill and replace it by a forwarder."
				 self assert: (manager isPinned: currentEntity) not. 
				 bytesToCopy := manager bytesInObject: currentEntity.
				 manager memcpy: fillStart asVoidPointer _: (manager startOfObject: currentEntity) asVoidPointer _: bytesToCopy.
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
			ifTrue: [fillStart := self compactSegment: segInfo freeStart: fillStart segIndex: i]].
		
	 "Final free chunk in segment to fill..."
	 manager 
		addFreeChunkWithBytes: segmentToFill segSize - manager bridgeSize + segmentToFill segStart - fillStart 
		at: fillStart.
	
	self postCompactionAction
	
]

{ #category : #compaction }
SpurSelectiveCompactor >> computeSegmentsToCompact [
	"Compute segments to compact: least occupied.
	 Answers true if compaction should be done 
	 (at least 1 segment is being compacted and
	 there is a segment to compact into)."
	| canStillClaim aboutToClaim aboutToClaimSegment atLeastOneSegmentToCompact |
	<var: 'aboutToClaimSegment' type: #'SpurSegmentInfo *'>
	atLeastOneSegmentToCompact := false.
	aboutToClaimSegment := self findNextSegmentToCompact.
	"Segment to fill is one of the segment compacted last GC. 
	 If no segment were compacted last GC, and that there is 
	 at least one segment to compact, allocate a new one."
	aboutToClaimSegment ifNil: [^false].
	segmentToFill ifNil:
		[self findOrAllocateSegmentToFill.
		 segmentToFill ifNil: ["Abort compaction"^false]].
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
			ifTrue: [segmentToFill := segInfo. ^i]].
	^-1
	
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
	| segIndex |
	self findAndSetSegmentToFill.
	segmentToFill ifNotNil: [^0].
	"No empty segment. We need to allocate a new one"
	(manager growOldSpaceByAtLeast: manager growHeadroom) ifNil: ["failed to allocate"^0].
	"We don't know which segment it is that we've just allocated... So we look for it... This is a bit dumb."
	segIndex := self findAndSetSegmentToFill.
	"Lilliputian performance hack management... Last lilliputian of new segment is same as prev because no lilliputian in new segment"
	self setLastLilliputianChunkAtindex: segIndex to: (self lastLilliputianChunkAtIndex: segIndex - 1).
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
				[manager 
					initFreeChunkWithBytes: segInfo segSize - manager bridgeSize 
					at: segInfo segStart.
				 segmentToFill ifNil: [segmentToFill := segInfo]]]
]

{ #category : #'sweep phase' }
SpurSelectiveCompactor >> globalSweepAndSegmentOccupationAnalysis [
	<inline: #never> "profiling"
	"Iterate over old space, free unmarked objects, annotate each segment with each occupation"
	| currentEntity nextBridge segmentIndex currentUsed currentUnused |
	lastLilliputianChunk := 0. "performance hack for single linked list"
	currentEntity := manager firstObject.
	nextBridge := manager segmentManager bridgeAt: 0.
	segmentIndex := currentUnused := currentUsed := 0.
	self setLastLilliputianChunkAtindex: 0 to: 0.
	[self oop: currentEntity isLessThan: manager endOfMemory] whileTrue:
		[currentEntity = nextBridge "End of segment, set occupation"
			ifTrue: 
				[self 
					setOccupationAtIndex: segmentIndex
					used: currentUsed 
					unused: currentUnused.
				  self setLastLilliputianChunkAtindex: segmentIndex to: lastLilliputianChunk.
				  currentUnused := currentUsed := 0.
				  segmentIndex := segmentIndex + 1.
				  nextBridge := manager segmentManager bridgeAt: segmentIndex]
			ifFalse: 
				[(self canUseAsFreeSpace: currentEntity) "In-segment, sweep and compute occupation"
					ifTrue: 
						[currentEntity := self bulkFreeChunkFrom: currentEntity.
						 currentUnused := currentUnused + (manager bytesInObject: currentEntity)]
					ifFalse: 
						[self unmark: currentEntity.
						 currentUsed := currentUsed + (manager bytesInObject: currentEntity)]].
		 currentEntity := manager objectAfter: currentEntity limit: manager endOfMemory].
	"set last segment details"	
	self 
		setOccupationAtIndex: segmentIndex
		used: currentUsed 
		unused: currentUnused.
	self setLastLilliputianChunkAtindex: segmentIndex to: lastLilliputianChunk.
	"we set the nextFreeChunk of last chunk at the end of the loop to avoid to set it at each iteration"
	lastLilliputianChunk ~= 0 ifTrue:
	 	[manager setNextFreeChunkOf: lastLilliputianChunk withValue: 0 isLilliputianSize: true].
		
	manager checkFreeSpace: GCModeFull.
	manager unmarkSurvivingObjectsForCompact.
]

{ #category : #compaction }
SpurSelectiveCompactor >> incrementalLilliputianSmallChunk: freeChunk [
	"This is duplicate form #unlinkSmallChunk:index: for performance hack (single iteration of single linked list)"
	<inline: #never> "for profiling"
	| node next |
	self assert: (manager bytesInObject: freeChunk) = (manager baseHeaderSize + manager allocationUnit).
	self assert: manager lilliputianChunkIndex = ((manager bytesInObject: freeChunk) / manager allocationUnit).
	lastLilliputianChunk = 0 ifTrue: "first incremental unlink"
		[(freeChunk = manager firstLilliputianChunk) 
			ifTrue: [^manager unlinkFreeChunk: freeChunk atIndex: manager lilliputianChunkIndex isLilliputianSize: true]
			ifFalse: [lastLilliputianChunk := manager firstLilliputianChunk]].
	 node := manager fetchPointer: manager freeChunkNextIndex ofFreeChunk: lastLilliputianChunk.
	 [node ~= 0] whileTrue:
		[self assert: node = (manager startOfObject: node).
		 manager assertValidFreeObject: node.
		 next := manager fetchPointer: manager freeChunkNextIndex ofFreeChunk: node.
		 node = freeChunk ifTrue:
			[^manager setNextFreeChunkOf: lastLilliputianChunk withValue: next isLilliputianSize: true].
		 lastLilliputianChunk := node.
		 node := next].
	 self error: 'freeChunk not found in lilliputian chunk free list'

	

]

{ #category : #'sweep phase' }
SpurSelectiveCompactor >> interceptAddFreeChunkWithBytes: bytes at: start [
	<inline: true>
	| freeChunk |
	(manager isLilliputianSize: bytes) ifTrue: "build size 1 free chunk in ascending addresses order"
		[lastLilliputianChunk = 0
			ifTrue: [^lastLilliputianChunk := manager addFreeChunkWithBytes: bytes at: start]
			ifFalse: 
				[manager increaseFreeOldSpaceBy: bytes.
				 freeChunk := manager initFreeChunkWithBytes: bytes at: start.
				 manager setNextFreeChunkOf: lastLilliputianChunk withValue: freeChunk isLilliputianSize: true.
				 "we set the nextFreeChunk of last chunk at the end of the loop to avoid to set it at each iteration"
				 ^lastLilliputianChunk := freeChunk]].
	^manager addFreeChunkWithBytes: bytes at: start

]

{ #category : #'segment access' }
SpurSelectiveCompactor >> isSegmentBeingCompacted: segInfo [ 
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	"Swizzle is abused bit 16 isBeingCompacted bits 0-15 occupation"
	^ segInfo swizzle anyMask: 1 << 16
]

{ #category : #'segment access' }
SpurSelectiveCompactor >> lastLilliputianChunkAtIndex: segIndex [
	<inline: true>
	"Abuse lastFreeObject field, can be used during compaction only, used for different purpose during snapshot"
	^(self addressOf: (manager segmentManager segments at: 0)) lastFreeObject
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
	"Note: there is not the OldBecameNewFlag"
	"gcMode flag is cleared after postBecomeAction, reset it."
	manager coInterpreter postBecomeAction: allFlags.
	manager coInterpreter setGCMode: GCModeFull.
	
	"Special to selective, crazy objects can be forwarded..."
	"manager postBecomeScanClassTable: allFlags. => Done in followClassTable"
	manager followClassTable.
	manager followProcessList.
	manager followForwardedObjStacks.
	
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
	| shouldCompact |
	<inline: #never> "profiling"
	self assertNoSegmentBeingCompacted.
	"Should compact only if there is at least 1 segment to compact 
	 and there is a segment to compact into"
	shouldCompact := self computeSegmentsToCompact.
	"If no compaction we don't pay forwarding cost (stack scan, cache scan, etc.)
	 and we don't allocate segmentToFill if none available."
	shouldCompact ifTrue:
		[self assert: segmentToFill ~~ nil.
		 self compactSegmentsToCompact].
	manager checkFreeSpace: GCModeFull.
]

{ #category : #'segment access' }
SpurSelectiveCompactor >> setLastLilliputianChunkAtindex: segIndex to: chunk [ 
	<inline: true>
	"Abuse lastFreeObject field, can be used during compaction only, used for different purpose during snapshot"
	(self addressOf: (manager segmentManager segments at: 0)) lastFreeObject: chunk
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

{ #category : #'sweep phase' }
SpurSelectiveCompactor >> sortedLilliputianChunks [
	|current next|
	current := manager firstLilliputianChunk.
	current = 0 ifTrue: [^true]. "no node"
	[next := manager fetchPointer: manager freeChunkNextIndex ofFreeChunk: current.
	 next = 0] whileFalse:
		[(manager oop: current isLessThan: next) ifFalse: [^false].
		 current := next].
	^ true

]

{ #category : #'segment access' }
SpurSelectiveCompactor >> unmarkSegmentAsBeingCompacted: segInfo [ 
	<inline: true> "So it is not generated if unused"
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	"Swizzle is abused bit 16 isBeingCompacted bits 0-15 occupation"
	segInfo swizzle: (segInfo swizzle bitAnd: 16rFFFF)
]
