"
Instances of SpurSegmentManager manage oldSpace, which is organized as a sequence of segments.  Segments can be obtained from the operating system and returned to the operating system when empty and shrinkage is required.  Segments are kept invisible from the SpurMemoryManager by using ""bridge"" objects, ""fake"" pinned objects to bridge the gaps between segments.  A pinned object header occupies the last 16 bytes of each segment, and the pinned object's size is the distance to the start of the next segment.  So when the memory manager enumerates objects it skips over these bridges and memory appears linear.  The constraint is that segments obtained from the operating system must be at a higher address than the first segment.  The maximum size of large objects, being an overflow slot size, should be big enough to bridge the gaps, because in 32-bits the maximum size is 2^32 slots.  In 64-bits the maximum size of large objects is 2^56 slots, or 2^59 bits, which we hope will suffice.

When an image is written to a snapshot file the second word of the header of the bridge at the end of each segment is replaced by the size of the following segment, the segments are written to the file, and the second word of each bridge is restored.  Hence the length of each segment is derived from the bridge at the end of the preceeding segment.  The length of the first segment is stored in the image header as firstSegmentBytes.  The start of each segment is also derived from the bridge as a delta from the start of the previous segment.  The start of The first segment is stored in the image header as startOfMemory.

On load all segments are read into one single segment, eliminating the bridge objects, and computing the swizzle distance for each segment, based on where the segments were in memory when the image file was written, and where the coallesced segment ends up on load.  Then the segment is traversed, swizzling pointers by selecting the relevant swizzle for each oop's segment.

Instance Variables
	numSegments:		<Integer>
	segments:			<Array of SpurSegmentInfo>
	manager:			<SpurMemoryManager>

numSegments
	- the number of segments

segments
	- the start addresses, lengths and offsets to adjust oops on image load, for each segment

manager
	- the SpurMemoryManager whose oldSpace is managed (simulation only).
"
Class {
	#name : #SpurSegmentManager,
	#superclass : #CogClass,
	#instVars : [
		'manager',
		'numSegments',
		'segments'
	],
	#category : #'VMMaker-SpurMemoryManager'
}
