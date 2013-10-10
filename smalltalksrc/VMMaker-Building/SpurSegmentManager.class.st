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
		'segments',
		'firstSegmentSize',
		'numSegmentsAllocated'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #snapshot }
SpurSegmentManager >> collapseSegmentsPostSwizzle [
	"The image has been loaded, old segments reconstructed, and the
	  loaded image swizzled into a single contiguous segment.  Collapse
	 the segments, and free the old bridges."
	| bridge |
	firstSegmentSize ifNil: "true when used by SpurBootstrap to transform an image"
		[^self].

	numSegmentsAllocated := numSegments.
	numSegments := 0.
	"segment sizes include the two-header-word bridge at the end of each segment."
	bridge := firstSegmentSize + manager newSpaceLimit - manager baseHeaderSize.
	1 to: numSegmentsAllocated - 1 do:
		[:i|
		 manager
			freeChunkWithBytes: 2 * manager baseHeaderSize
			at: bridge - manager baseHeaderSize.
		 bridge := bridge + (segments at: i) segSize].
	"now bridge is pointing to last bridge in loaded image.  free the bridge, add a
	 bridge at the end of memory, and cut back end of memory to before the bridge."
	manager
		freeChunkWithBytes: 2 * manager baseHeaderSize
		at: bridge - manager baseHeaderSize.
	"now update the segment to reflect the coallesced segments"
	numSegments := 1.
	(segments at: 0)
		start: manager newSpaceLimit;
		segSize: manager endOfMemory.
	"finally plant a bridge at the end of the coallesced segment and cut back the
	 manager's ntion of the end of memory to immediately before the bridge."
	bridge := manager endOfMemory - (2 * manager baseHeaderSize).
	manager
		initSegmentBridgeWithBytes: 2 * manager baseHeaderSize at: bridge;
		setEndOfMemory: bridge
]

{ #category : #snapshot }
SpurSegmentManager >> firstSegmentBytes [
	^(segments at: 0) segSize
]

{ #category : #initialization }
SpurSegmentManager >> firstSegmentSize: firstSegSize [
	"Remember firstSegSize for subsequent image segment parsing."
	firstSegmentSize := firstSegSize
]

{ #category : #'simulation only' }
SpurSegmentManager >> initializeFromFreeChunks: freeChunks [
	"For testing, create a set of segments using the freeChunks as bridges."
	numSegments := freeChunks size.
	freeChunks do:
		[:f|
		manager initSegmentBridgeWithBytes: (manager bytesInObject: f) at: (manager startOfObject: f).
		self assert: (manager isSegmentBridge: f)].
	segments := (1 to: numSegments) collect:
					[:i| | bridge start size |
					bridge := freeChunks at: i.
					start := i = 1
								ifTrue: [manager newSpaceLimit]
								ifFalse: [manager addressAfter: (freeChunks at: i - 1)].
					size := bridge + manager baseHeaderSize - start.
					SpurSegmentInfo new
						start: start;
						segSize: size;
						yourself].
	segments := CArrayAccessor on: segments.
	freeChunks do:
		[:bridge| self assert: (manager isValidSegmentBridge: bridge)]
]

{ #category : #initialization }
SpurSegmentManager >> manager: aSpurMemoryManager [
	manager := aSpurMemoryManager.
	numSegments ifNil:
		[numSegments := 0]
]

{ #category : #accessing }
SpurSegmentManager >> numSegments [
	^numSegments
]

{ #category : #snapshot }
SpurSegmentManager >> parseSegmentsInNewlyLoadedImage: firstSegmentShift [
	"Skip through the bridge objects, counting the number of segments.
	 Then allocate the segment info and scan again, computing the swizzle
	 ammounts for each segment."
	| bridge nextSegmentSize oldBase newBase segInfo bridgeSpan |
	<var: 'segInfo' type: 'SpurSegmentInfo *'>
	firstSegmentSize ifNil: "true when used by SpurBootstrap to transform an image"
		[^self].

	numSegments := 0.
	"segment sizes include the two-header-word bridge at the end of each segment."
	bridge := firstSegmentSize + manager newSpaceLimit - manager baseHeaderSize.
	[numSegments := numSegments + 1.
	 nextSegmentSize := manager longLongAt: bridge.
	 nextSegmentSize ~= 0] whileTrue:
		[bridge := bridge + nextSegmentSize].
	segments := self
					cCode: [self c: numSegments alloc: (self sizeof: SpurSegmentInfo)]
					inSmalltalk: [CArrayAccessor on: ((1 to: numSegments) collect: [:i| SpurSegmentInfo new])].

	numSegments := 0.
	oldBase := manager newSpaceLimit - firstSegmentShift.
	newBase := manager newSpaceLimit.
	nextSegmentSize := firstSegmentSize.
	bridge := firstSegmentSize + manager newSpaceLimit - manager baseHeaderSize.
	[segInfo := self addressOf: (segments at: numSegments).
	 segInfo
		start: oldBase;
		segSize: nextSegmentSize;
		swizzle: newBase - oldBase.
	 numSegments := numSegments + 1.
	 bridgeSpan := manager bytesPerSlot * (manager rawOverflowSlotsOf: bridge).
	 oldBase := oldBase + nextSegmentSize + bridgeSpan.
	 newBase := newBase + nextSegmentSize.
	 nextSegmentSize := manager longLongAt: bridge.
	 nextSegmentSize ~= 0] whileTrue:
		[bridge := bridge + nextSegmentSize].
	"newBase should point just past the last bridge."
	self assert: (manager longLongAt: newBase - manager baseHeaderSize) = 0.
	"set freeOldSpaceStart now for adjustAllOopsBy:"
	manager setFreeOldSpaceStart: newBase
]

{ #category : #snapshot }
SpurSegmentManager >> swizzleObj: objOop [
	1 to: numSegments - 1 do:
		[:i|
		objOop < (segments at: i) start ifTrue:
			[^objOop + (segments at: i - 1) swizzle]].
	^objOop + (segments at: numSegments - 1) swizzle
]

{ #category : #snapshot }
SpurSegmentManager >> totalBytesInSegments [
	| total |
	total := 0.
	0 to: numSegments - 1 do:
		[:i|
		total := total + (segments at: i) segSize].
	^total
]

{ #category : #snapshot }
SpurSegmentManager >> writeImageToFile: aBinaryStream [
	| total |
	total := 0.
	firstSegmentSize ifNotNil:
		[self assert: firstSegmentSize = (segments at: 0) segSize].
	0 to: numSegments - 1 do:
		[:i| | nextSegSize |
		nextSegSize := i = (numSegments - 1)
							ifTrue: [0]
							ifFalse: [(segments at: i + 1) segSize].
		total := total + (self writeSegment: (segments at: i)
							nextSegmentSize: nextSegSize
							toFile: aBinaryStream)].
	^total
]

{ #category : #snapshot }
SpurSegmentManager >> writeSegment: aSpurSegmentInfo nextSegmentSize: nextSegSize toFile: aBinaryStream [
	<var: 'aSpurSegmentInfo' type: 'SpurSegmentInfo *'>
	<var: 'aBinaryStream' type: #'FILE *'>
	| bridge savedHeader nWritten |
	<var: 'savedHeader' type: #usqLong>
	bridge := aSpurSegmentInfo start + aSpurSegmentInfo segSize - manager baseHeaderSize.
	self assert: (manager isValidSegmentBridge: bridge).
	savedHeader := manager longLongAt: bridge.
	manager longLongAt: bridge put: nextSegSize.
	nWritten := self cCode:
						[self
							sq: aSpurSegmentInfo start
							Image: 1
							File: aSpurSegmentInfo segSize
							Write: aBinaryStream]
					inSmalltalk:
						[aBinaryStream
							next: aSpurSegmentInfo segSize / 4
							putAll: manager memory
							startingAt: aSpurSegmentInfo start / 4 + 1.
						 aSpurSegmentInfo segSize].
	manager longLongAt: bridge put: savedHeader.
	^nWritten
]
