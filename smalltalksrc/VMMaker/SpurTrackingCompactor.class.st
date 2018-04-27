"
SpurTrackingCompactor is a derived simplified implementation of Garbage First (G1) algorithm (Java 9 default GC).

SpurTrackingCompactor compacts memory by selecting the memory segments with the most free space and compacting only those, to limit fragmentation while being really quick to perform. To update efficiently the references to moved objects, SpurTrackingCompactor uses a per segment remembered table in the form with a card marking scheme, hence when compacting segments, instead of scanning all the heap for pointer updates, it scans only the moved objects and the objects remembered for the segment. Since segments compacted are almost free segments, the remembered table is small upon compaction.

This algorithm requires extra GC write barriers and higher aligment in segments for efficient write barrier (bits in the pointer are used to know to which segment an object belongs). 


"
Class {
	#name : #SpurTrackingCompactor,
	#superclass : #SpurAnalysingSweeper,
	#category : #'VMMaker-SpurMemoryManager'
}
