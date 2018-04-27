"
SpurTrackingCompactor is a derived simplified implementation of Garbage First (G1) algorithm (Java 9 default GC).

SpurTrackingCompactor compacts memory by selecting the memory segments with the most free space and compacting only those, to limit fragmentation while being really quick to perform. To update efficiently the references to moved objects, SpurTrackingCompactor uses a per segment remembered table in the form with a card marking scheme, hence when compacting segments, instead of scanning all the heap for pointer updates, it scans only the moved objects and the objects remembered for the segment. Since segments compacted are almost free segments, the remembered table is small upon compaction.

This algorithm requires extra GC write barriers and higher aligment in segments for efficient write barrier (bits in the pointer are used to know to which segment an object belongs). 

TODO:
followTrackedReference and reference tracking
Implement global card mark with 1 byte per 1024 byte (1 bit has object, 7 bits starting index of object in the range covered)
Implement per segment card mark with 1 bit per 1024 bytes.
Implement cards for 2Gb (2Mb global card and 250kb), allow only segments within the 2 Gb range to avoid issues
- Sweep phase can update global card to avoid changing whole VM
- Write barrier: based on some bits in pointer, figure out which card to dirty and in which segment's card mark
- followTrackReference is commented with idea: find what to follow and heap and follow all.

"
Class {
	#name : #SpurTrackingCompactor,
	#superclass : #SpurAnalysingSweeperCompactor,
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #api }
SpurTrackingCompactor >> compact [
	<inline: #never>
	self globalSweepAndSegmentOccupationAnalysis.
	self selectiveCompaction.
	
]

{ #category : #compaction }
SpurTrackingCompactor >> followAllObjectsInSegmentToFill [
	| currentEntity bridge |
	bridge := manager segmentManager bridgeFor: segmentToFill.
	currentEntity := manager objectStartingAt: segmentToFill segStart.
	[self oop: currentEntity isLessThan: bridge] whileTrue:
		[((manager isEnumerableObject: currentEntity) and: [manager isPointersNonImm: currentEntity])
			ifTrue: 
				[0 to: (manager numSlotsOfAny: currentEntity) do: 
					[:i | self followField: i ofObject: currentEntity]]].
	self assert: currentEntity = bridge.
]

{ #category : #compaction }
SpurTrackingCompactor >> followTrackedReferences [
	"Each segment has a remembered set in the form of a card table. We need to create a local card table, bitAnd it with all compacted segments, then follow all dirty areas"
	1halt. #TODO.	
]

{ #category : #compaction }
SpurTrackingCompactor >> freeCompactedSegments [
	0 to: manager numSegments - 1 do:
		[:i| self freeSegment: (self addressOf: (manager segmentManager segments at: i))].
		
]

{ #category : #compaction }
SpurTrackingCompactor >> postCompactionAction [
	self followAllObjectsInSegmentToFill. "deal with inner segment references"
	self followTrackedReferences. "partial heap scan"
	self freeCompactedSegments.
	self postForwardingAction.
]
