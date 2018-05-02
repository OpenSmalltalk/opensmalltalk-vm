"
SpurSelectiveCompactor compacts memory by selecting the memory segments with the most free space and compacting only those, to limit fragmentation while being really quick to perform. The algorithm is fast mostly because it does not update pointers: they are updated lazily during the next marking phase, so there is no need to read the fields of objects in other memory segments that the one compacted.

The algorithm works as follow. First, a global sweep pass iterates over the memory linearly, changing unmarked objects to free chunks and concatenating free chunks. During the global sweep phase, the segments of the heap are analysed to determine the percentage of occupation. Second, the least occupied segments are compacted by copying the remaining live objects into an entirely free segment, called regionToFill (we detail later in the paragraph where regionToFill comes from), changing their values to forwarding objects and marking the free chunks as unavailable (removed from free list and marked as data objects). Third, the next marking phase removes all forwarders. Fourth, at the beginning of the next compaction phase the compacted segments from the previous GC can be entirely marked as free space (No need to check anything inside, there were only forwarders and trash data). One of the compacted segment is then selected as the segmentToFill, others are just marked as free chunks. 

The compaction is effectively partial, compacting only the most critical segments of the heap to limit fragmentation. Compaction time is crazy low, since a low number of objects are moved and pointer updated is lazily done during the next marking phase, while still preventing memory fragmentation.

Now this works well when biasForGC is true, but when performing a snapshot, the compactor is just total crap (we need to figure out a solution).

segmentToFill <SegInfo> the segment that will be filled through the copying algorithm

------------------------

Segment abuse:
The swizzle field of segInfo is abused by using the low 8 bits for occupation and the 9th bit as isBeingCompacted bit.

TODO: check it seems when memory is decreasing rapidly many empty segment are kept (14 and not 4 - Bug in totalFreeSpace?)

"
Class {
	#name : #SpurSelectiveCompactor,
	#superclass : #SpurAnalysingSweeperCompactor,
	#category : 'VMMaker-SpurMemoryManager'
}

{ #category : #simulation }
SpurSelectiveCompactor class >> simulatorClass [
	^SpurSelectiveCompactorSimulator
]

{ #category : #api }
SpurSelectiveCompactor >> compact [
	<inline: #never> "for profiling"
	self freePastSegmentsAndSetSegmentToFill.
	self globalSweepAndSegmentOccupationAnalysis.
	self selectiveCompaction.
	
]

{ #category : #freeing }
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
