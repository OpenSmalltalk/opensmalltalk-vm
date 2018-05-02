"
SpurSlidingCompactor compacts memory completely by sliding objects down in memory.  It does so by using a buffer (compactedCopySpace) to hold a copy of compacted objects in some region of the heap being compacted.  Starting at the first object above free space (up until a pinned object), objects are copied into CCS until it fills up, and as objects are copied, their originals are forwarded to the location they would occupy.  Once the CCS is full, or all of the heap has been copied to it, memory is scanned searching for oops in the range being compacted, and oops are updated to their actual positions.  Then the contents of the CCS are block copied into place.  The process repeats until all of the heap has been compacted.  This will leave one contiguous free chunk in the topmost occupied segment (ignoring pinned objects).  The number of passes made to follow forwarders is approximately the allocated size of the heap divided by the size of CCS; the larger CCS the more objects that can be compacted in one go (ignoring the effect of pinned objects).

Instance Variables
	coInterpreter:				<StackInterpreter>
	compactedCopySpace:		<SpurNewSpaceSpace>
	manager:					<SpurMemoryManager>
	scavenger:					<SpurGenerationScavenger>

compactedCopySpace
	- a large contiguous region of memory used to copy objects into during compaction.  The compactor may try and allocate a segment, use a large free chunk or use eden for this memory.
"
Class {
	#name : #SpurSlidingCompactor,
	#superclass : #SpurCompactor,
	#instVars : [
		'compactedCopySpace'
	],
	#category : 'VMMaker-SpurMemoryManager'
}

{ #category : #'compaction - api' }
SpurSlidingCompactor >> biasForGC [
	<inline: true>
]

{ #category : #'compaction - api' }
SpurSlidingCompactor >> biasForSnapshot [
	<inline: true>
]

{ #category : #'compaction - api' }
SpurSlidingCompactor >> compact [
	"Sweep all of old space, sliding unpinned marked objects down over free and unmarked objects.
	 Let the segmentManager mark which segments contain pinned objects via notePinned:.
		destination: nil or the start of a run of free and/or unmarked objects
		pinnedObject: nil or the pinned object found in the sweep around which unpinned objects must be copied."
	| destination pinnedObject |
	<inline: #never> "for profiling"
	manager checkFreeSpace: GCModeFull.
	manager resetFreeListHeads.
	self selectCompactedCopySpace.
	destination := pinnedObject := nil.
	manager allOldSpaceEntitiesFrom: manager firstObject do:
		[:o|
		 (manager isMarked: o)
			ifTrue: "forwarders should have been followed in markAndTrace:"
				[self assert: (manager isForwarded: o) not.
				 destination
					ifNil:
						[manager setIsMarkedOf: o to: false.
						 (manager isPinned: o) ifTrue:
							[manager segmentManager notePinned: o]]
					ifNotNil:
						[(manager isPinned: o)
							ifTrue:
								[manager segmentManager notePinned: o.
								 destination := self copyObjectsInCompactedCopySpaceTo: destination followingUpTo: o.
								 (manager startOfObject: o) - destination > manager allocationUnit
									ifTrue: "Possible to move objects below the pinnedObject"
										[pinnedObject
											ifNil: []
											ifNotNil: [].
										 pinnedObject := o]
									ifFalse: "Impossible; ensure there's a free chunk if necessary."
										[pinnedObject
											ifNil: []
											ifNotNil: [].
										 destination := nil]] "WAIT; NEED AT LEAST 2 WORDS FOR FREE CHUNK"
							ifFalse:
								[manager setIsMarkedOf: o to: false.
								 (self fitsInCompactedCopySpace: o) ifFalse:
									[destination := self copyObjectsInCompactedCopySpaceTo: destination followingUpTo: o].
								  (self fitsInCompactedCopySpace: o)
									ifFalse: [destination := self slideHugeObject: o downTo: destination]
									ifTrue:
										[self copyToCompactedCopySpace: o andForwardTargetedAt: destination]]]]
			ifFalse: "unmarked; two cases, an unreachable object or a free chunk. Should be faster to set free than to check if already free..."
				[destination ifNil: [destination := manager startOfObject: o].
				 manager setObjectFree: o]]
]
