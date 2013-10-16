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
		'numSegInfos',
		'segments',
		'firstSegmentSize',
		'canSwizzle'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurSegmentManager class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator var: #segments type: #'SpurSegmentInfo *'
]

{ #category : #translation }
SpurSegmentManager class >> isNonArgumentImplicitReceiverVariableName: instVarName [
	^instVarName = 'manager'
]

{ #category : #'growing/shrinking memory' }
SpurSegmentManager >> addSegmentOfSize: ammount [
	<returnTypeC: #'SpurSegmentInfo *'>
	| allocatedSize |
	<var: #newSeg type: #'SpurSegmentInfo *'>
	(manager "sent to the manager so that the simulator can increase memory to simulate a new segment"
			sqAllocateMemorySegmentOfSize: ammount
			Above: manager newSpaceLimit
			AllocatedSizeInto: (self cCode: [self addressOf: allocatedSize]
									inSmalltalk: [[:sz| allocatedSize := sz]])) ifNotNil:
		[:segAddress| | newSegIndex newSeg |
		 newSegIndex := self insertSegmentFor: segAddress.
		 newSeg := self addressOf: (segments at: newSegIndex).
		 newSeg
			segStart: segAddress;
			segSize: allocatedSize.
		 self bridgeFrom: (self addressOf: (segments at: newSegIndex - 1)) to: newSeg.
		 self bridgeFrom: newSeg to: (newSegIndex = (numSegments - 1) ifFalse:
										[self addressOf: (segments at: newSegIndex + 1)]).
		 "and add the new free chunk to the free list; done here
		  instead of in assimilateNewSegment: for the assert"
		 manager addFreeChunkWithBytes: allocatedSize - manager bridgeSize at: newSeg segStart.
		 self assert: (manager addressAfter: (manager objectStartingAt: newSeg segStart))
					= (newSeg segStart + newSeg segSize - manager bridgeSize).
		 ^newSeg].
	^nil
]

{ #category : #snapshot }
SpurSegmentManager >> adjustSegmentSwizzlesBy: firstSegmentShift [
	"Adjust swizzles by firstSegmentShift."
	<var: 'segInfo' type: 'SpurSegmentInfo *'>
	| oldBaseAddr |
	oldBaseAddr := manager memoryBaseForImageRead - firstSegmentShift.
	0 to: numSegments - 1 do:
		[:i| | segInfo |
		 segInfo := self addressOf: (segments at: i).
		 segInfo
			segStart: segInfo segStart + oldBaseAddr;
			swizzle: segInfo swizzle - oldBaseAddr].
	canSwizzle := true
]

{ #category : #private }
SpurSegmentManager >> allocateOrExtendSegmentInfos [
	"Increase the number of allocated segInfos by 16."
	<returnTypeC: #void>
	| newNumSegs |
	numSegInfos = 0 ifTrue:
		[numSegInfos := 16.
		 segments := self
						cCode: [self c: numSegInfos alloc: (self sizeof: SpurSegmentInfo)]
						inSmalltalk: [CArrayAccessor on: ((1 to: numSegInfos) collect: [:i| SpurSegmentInfo new])].
		 ^self].
	newNumSegs := numSegInfos + 16.
	segments := self
						cCode: [self re: newNumSegs * (self sizeof: SpurSegmentInfo) alloc: segments]
						inSmalltalk: [CArrayAccessor on: segments object,
									((numSegInfos to: newNumSegs) collect: [:i| SpurSegmentInfo new])].
	self cCode:
		[segments = 0 ifTrue:
			[self error: 'out of memory; cannot allocate more segments'].
		 self
			me: segments + numSegInfos
			ms: 0
			et: newNumSegs - numSegInfos * (self sizeof: SpurSegmentInfo)].
	numSegInfos := newNumSegs
]

{ #category : #'growing/shrinking memory' }
SpurSegmentManager >> bridgeFrom: aSegment to: nextSegmentOrNil [
	"Create a bridge from aSegment to the next segment,
	 or create a terminating bridge if there is no next segment."
	<var: #aSegment type: #'SpurSegmentInfo *'>
	<var: #nextSegmentOrNil type: #'SpurSegmentInfo *'>
	| segEnd clifton bridgeSpan |
	segEnd := aSegment segStart + aSegment segSize.
	clifton := segEnd - manager bridgeSize. "clifton is where the Avon bridge begins..."
	bridgeSpan := nextSegmentOrNil
					ifNil: [manager bridgeSize]
					ifNotNil: [nextSegmentOrNil segStart - segEnd + manager bridgeSize].
	manager initSegmentBridgeWithBytes: bridgeSpan at: clifton.
	"the revised bridge should get us to the new segment"
	self assert: (nextSegmentOrNil isNil
				 or: [(manager addressAfter: (manager objectStartingAt: clifton)) = nextSegmentOrNil segStart])

]

{ #category : #snapshot }
SpurSegmentManager >> collapseSegmentsPostSwizzle [
	"The image has been loaded, old segments reconstructed, and the
	  loaded image swizzled into a single contiguous segment.  Collapse
	  the segments intio one."
	| bridge |
	canSwizzle := false.
	firstSegmentSize ifNil: "true when used by SpurBootstrap to transform an image"
		[^self].

	numSegments := 1.
	(self addressOf: (segments at: 0))
		segStart: manager newSpaceLimit;
		segSize: manager endOfMemory - manager newSpaceLimit.
	"finally plant a bridge at the end of the coallesced segment and cut back the
	 manager's notion of the end of memory to immediately before the bridge."
	bridge := manager endOfMemory - manager bridgeSize.
	manager
		initSegmentBridgeWithBytes: manager bridgeSize at: bridge;
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

{ #category : #initialization }
SpurSegmentManager >> initialize [
	numSegments := numSegInfos := 0.
	canSwizzle := false
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
						segStart: start;
						segSize: size;
						yourself].
	segments := CArrayAccessor on: segments.
	freeChunks allButLast do:
		[:bridge| self assert: (manager isValidSegmentBridge: bridge)]
]

{ #category : #'growing/shrinking memory' }
SpurSegmentManager >> insertSegmentFor: segAddress [
	"Reserve a new segInfo for segAddress.  If segAddress
	 is in the middle of the existing segments, shuffle them
	 up to make room. Answer the new segment's index."
	| segIndex lastSegIndex |
	self assert: segAddress > ((segments at: 0) segStart + (segments at: 0) segSize).
	numSegments = numSegInfos ifTrue:
		[self allocateOrExtendSegmentInfos].
	self assert: numSegments < numSegInfos.
	segIndex := lastSegIndex := numSegments - 1.
	numSegments := numSegments + 1.
	[segAddress > ((segments at: segIndex) segStart
					+ (segments at: segIndex) segSize) ifTrue:
		[segIndex := segIndex + 1.
		 lastSegIndex to: segIndex by: -1 do:
			[:idx| segments at: idx + 1 put: (segments at: idx)].
		 ^segIndex].
	 segIndex := segIndex - 1]
		repeat
]

{ #category : #testing }
SpurSegmentManager >> isInSegments: address [
	0 to: numSegments - 1 do:
		[:i|
		address < (segments at: i) segStart ifTrue:
			[^false].
		address < ((segments at: i) segStart + (segments at: i) segSize) ifTrue:
			[^true]].
	^false
]

{ #category : #initialization }
SpurSegmentManager >> manager: aSpurMemoryManager [
	manager := aSpurMemoryManager
]

{ #category : #accessing }
SpurSegmentManager >> numSegments [
	<cmacro: '() GIV(numSegments)'>
	^numSegments
]

{ #category : #private }
SpurSegmentManager >> readHeapFrom: f at: location dataBytes: numBytes [
	"Read numBytes from f into mmory at location.  Answer the number of bytes read."
	^self cCode:
			[self
				sq: (self pointerForOop: location)
				Image: (self sizeof: #char)
				File: numBytes
				Read: f]
		inSmalltalk:
			[(f	readInto: manager memory
				startingAt: location // 4 + 1
				count: numBytes // 4)
			 * 4]
]

{ #category : #snapshot }
SpurSegmentManager >> readHeapFromImageFile: f dataBytes: numBytes [
	"Read numBytes of image data from f into memory at memoryBaseForImageRead.
	 Answer the number of bytes written.  In addition, read each segment, build up the
	 segment info, while eliminating the bridge objects that end each segment and
	 give the size of the subsequent segment."
	| bytesRead totalBytesRead bridge nextSegmentSize oldBase newBase segInfo bridgeSpan |
	<var: 'segInfo' type: 'SpurSegmentInfo *'>
	self allocateOrExtendSegmentInfos.

	"segment sizes include the two-header-word bridge at the end of each segment."
	numSegments := totalBytesRead := 0.
	oldBase := 0. "N.B. still must be adjusted by oldBaseAddr."
	newBase := manager newSpaceLimit.
	nextSegmentSize := firstSegmentSize.
	bridge := firstSegmentSize + manager newSpaceLimit - manager baseHeaderSize.
	[segInfo := self addressOf: (segments at: numSegments).
	 segInfo
		segStart: oldBase;					"N.B. still must be adjusted by oldBaseAddr."
		segSize: nextSegmentSize;
		swizzle: newBase - oldBase.	"N.B. still must be adjusted by oldBaseAddr."
	 bytesRead := self readHeapFrom: f at: newBase dataBytes: nextSegmentSize.
	 bytesRead > 0 ifTrue:
			[totalBytesRead := totalBytesRead + bytesRead].
	 bytesRead ~= nextSegmentSize ifTrue:
		[^totalBytesRead].
	 numSegments := numSegments + 1.
	 bridgeSpan := manager bytesPerSlot * (manager rawOverflowSlotsOf: bridge).
	 oldBase := oldBase + nextSegmentSize + bridgeSpan.
	 newBase := newBase + nextSegmentSize - manager bridgeSize.
	 nextSegmentSize := manager longLongAt: bridge.
	 nextSegmentSize ~= 0] whileTrue:
		[bridge := bridge - manager bridgeSize + nextSegmentSize].
	"newBase should point just past the last bridge. all others should have been eliminated."
	self assert: newBase - manager newSpaceLimit
				= (totalBytesRead - (numSegments * manager bridgeSize)).
	"set freeOldSpaceStart now for adjustAllOopsBy:"
	manager setFreeOldSpaceStart: newBase.
	^totalBytesRead
]

{ #category : #snapshot }
SpurSegmentManager >> swizzleObj: objOop [
	<inline: false>
	self assert: canSwizzle.
	numSegments - 1 to: 1 by: -1 do:
		[:i|
		objOop >= (segments at: i) segStart ifTrue:
			[^objOop + (segments at: i) swizzle]].
	^objOop + (segments at: 0) swizzle
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
		total := total + (self writeSegment: (self addressOf: (segments at: i))
							nextSegmentSize: nextSegSize
							toFile: aBinaryStream)].
	^total
]

{ #category : #snapshot }
SpurSegmentManager >> writeSegment: aSpurSegmentInfo nextSegmentSize: nextSegSize toFile: aBinaryStream [
	<var: 'aSpurSegmentInfo' type: #'SpurSegmentInfo *'>
	<var: 'aBinaryStream' type: #'FILE *'>
	| bridge savedHeader nWritten |
	<var: 'savedHeader' type: #usqLong>
	bridge := aSpurSegmentInfo segStart + aSpurSegmentInfo segSize - manager baseHeaderSize.
	"last seg may be beyond endOfMemory/freeOldSpaceStart"
	self assert: ((manager isValidSegmentBridge: bridge) or: [nextSegSize = 0]).
	savedHeader := manager longLongAt: bridge.
	manager longLongAt: bridge put: nextSegSize.
	nWritten := self cCode:
						[self
							sq: aSpurSegmentInfo segStart
							Image: 1
							File: aSpurSegmentInfo segSize
							Write: aBinaryStream]
					inSmalltalk:
						[aBinaryStream
							next: aSpurSegmentInfo segSize / 4
							putAll: manager memory
							startingAt: aSpurSegmentInfo segStart / 4 + 1.
						 aSpurSegmentInfo segSize].
	manager longLongAt: bridge put: savedHeader.
	^nWritten
]
