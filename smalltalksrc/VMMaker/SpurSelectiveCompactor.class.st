"
SpurSelectiveCompactor compacts memory by selecting the memory regions with the most free space and compacting only those, to limit fragmentation while being really quick to perform. The algorithm is fast mostly because it does not update pointers: they are updated lazily during the next marking phase, so there is no need to read the fields of objects in other memory regions that the one compacted.

The algorithm works as follow. First, a global sweep pass iterates over the memory linearly, changing unmarked objects to free space. During the global sweep phase, the heap is analysed in the form of variable sized regions and the percentage of occupation of each region is computed. Second, the least occupied regions are compacted by copying the remaining live objects into an entirely free region, called regionToFill (we detail later in the paragraph where regionToFill comes from) and changing their values to forwarding objects. The rest of each region being freed is temporarily marked as used with hidden word objects. Third, the next marking phase removes all forwarders. Fourth, at the beginning of the next compaction phase the compacted regions from the previous GC can be entirely marked as free space (No need to check anything inside, there were only forwarders that were removed and hidden word objects). One of the freed region is then selected as the regionToFill, others are just marked as free space. The compaction is effectively partial, compacting only the most critical regions of the heap to limit fragmentation. 

Now this works well when biasForGC is true, but when performing a snapshot, the compactor instead frees the regions held and then calls a more aggressive compactor to decrease the image size.

regionsWithOccupationPercentage <> list of regions with the occupation rate
regionsToReclaim <> regions that will be freed at the beginning of next compaction (After next marking phase)
biasForGC <> if false this is a compaction for snapshot, else normal GC
regionToFill <> the region that will be filled through the copying algorithm


"
Class {
	#name : #SpurSelectiveCompactor,
	#superclass : #SpurSweeper,
	#instVars : [
		'regionsWithOccupationPercentage',
		'regionsToReclaim',
		'regionToFill'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #api }
SpurSelectiveCompactor >> compact [
	<inline: #never> "for profiling"
	biasForGC
		ifTrue: [self internalCompact]
		ifFalse: ["Should use a compacting algo instead"self internalCompact]
	
]

{ #category : #'freeing regions' }
SpurSelectiveCompactor >> freeRegionsFromPastCompactionsAndSetRegionToFill [
	"regionsToReclaim is likely a word object with an index and a list of range of regions to reclaim. Sets the regionToFill"
]

{ #category : #'sweep phase' }
SpurSelectiveCompactor >> globalSweepAndRegionAnalysis [
	"Iterate over the whole memory, free unmarked objects, figure out regions based on the current size of the heap (regions are variable sized based on an estimate, segments and where objects end) and save them in regionsWithOccupationPercentage"
]

{ #category : #api }
SpurSelectiveCompactor >> internalCompact [
	self freeRegionsFromPastCompactionsAndSetRegionToFill.
	self globalSweepAndRegionAnalysis.
	self selectiveCompaction.
]

{ #category : #compaction }
SpurSelectiveCompactor >> selectiveCompaction [
	"Iterate over regionsWithOccupationPercentage, compact regions from the least occupied to the most occupied, stops when the next region to compact is filled with more than MinFreeForCompaction or when the segment to fill is full"
]
