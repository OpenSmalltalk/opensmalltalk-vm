"
Instances of SpurSegmentManager manage oldSpace, which is organized as a sequence of segments.  Segments can be obtained from the operating system and returned to the operating system when empty and shrinkage is required.  Segments are kept invisible from the SpurMemoryManager by using ""bridge"" objects, ""fake"" pinned objects to bridge the gaps between segments.  A pinned object header occupies the last 16 bytes of each segment, and the pinned object's size is the distance to the start of the next segment.  So when the memory manager enumerates objects it skips over these bridges and memory appears linear.  The constraint is that segments obtained from the operating system must be at a higher address than the first segment.  The maximum size of large objects, being an overflow slot size, should be big enough to bridge the gaps, because in 32-bits the maximum size is 2^32 slots.  In 64-bits the maximum size of large objects is 2^56 slots, or 2^59 bits, which we hope will suffice.

When an image is written to a snapshot file the second word of the header of the bridge at the end of each segment is replaced by the size of the following segment, the segments are written to the file, and the second word of each bridge is restored.  Hence the length of each segment is derived from the bridge at the end of the preceeding segment.  The length of the first segment is stored in the image header as firstSegmentBytes.  The start of each segment is also derived from the bridge as a delta from the start of the previous segment.  The start of The first segment is stored in the image header as startOfMemory.

On load all segments are read into one single segment, eliminating the bridge objects, and computing the swizzle distance for each segment, based on where the segments were in memory when the image file was written, and where the coalesced segment ends up on load.  Then the segment is traversed, swizzling pointers by selecting the relevant swizzle for each oop's segment.

Instance Variables
	manager						<SpurMemoryManager>
	numSegments					<Integer>
	numSegInfos					<Integer>
	segments						<Array of SpurSegmentInfo>
	firstSegmentSize				<Integer>
	canSwizzle						<Boolean>
	sweepIndex					<Integer>
	preferredPinningSegment		<SpurSegmentInfo>
	totalHeapSizeIncludingBridges	<integer>

canSwizzle
	- a flag set and cleared during initialization to validate that swizzling is only performed at the right time

firstSegmentSize
	- the size of the first segment when loading an image

manager
	- the memory manager the receiver manages segments for (simulation only)
	
numSegInfos
	- the size of the segments array in units of SpurSegmentInfo size
	
numSegments
	- the number of segments (the number of used entries in segments, <= numSegInfos)

preferredPinningSegment
	- the segment in which objects should be copied when pinned, so as to cluster pinned objects in as few segments as possible.  As yet unimplemented.

segments
	- the start addresses, lengths and offsets to adjust oops on image load, for each segment

sweepIndex
	- a segment index used to optimize setting the containsPinned flag on segments during freeUnmarkedObjectsAndSortAndCoalesceFreeSpace

totalHeapSizeIncludingBridges
	- the total size of all segments, used to compute heap usage
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
		'canSwizzle',
		'sweepIndex',
		'preferredPinningSegment',
		'totalHeapSizeIncludingBridges'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurSegmentManager class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator
		var: #segments type: #'SpurSegmentInfo *';
		var: #totalHeapSizeIncludingBridges type: #usqInt
]

{ #category : #translation }
SpurSegmentManager class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #translation }
SpurSegmentManager class >> isNonArgumentImplicitReceiverVariableName: instVarName [
	^instVarName = 'manager'
]

{ #category : #'growing/shrinking memory' }
SpurSegmentManager >> addSegmentOfSize: ammount [
	<returnTypeC: #'SpurSegmentInfo *'>
	<inline: false>
	| allocatedSize |
	<var: #newSeg type: #'SpurSegmentInfo *'>
	<var: #segAddress type: #'void *'>
	<var: #allocatedSize type: #'usqInt'>
	self cCode: [] inSmalltalk: [segments ifNil: [^nil]]. "bootstrap"
	(manager "sent to the manager so that the simulator can increase memory to simulate a new segment"
			sqAllocateMemorySegmentOfSize: ammount
			Above: (self firstGapOfSizeAtLeast: ammount)
			AllocatedSizeInto: (self cCode: [self addressOf: allocatedSize]
									inSmalltalk: [[:sz| allocatedSize := sz]])) ifNotNil:
		[:segAddress| | newSegIndex newSeg numSegmentsM1 |
		numSegmentsM1 := numSegments - 1.
		 newSegIndex := self insertSegmentFor: segAddress asUnsignedIntegerPtr.
		 "Simulation insertion code duplicates entries if newSegIndex ~= numSegments - 1"
		 self cCode: '' inSmalltalk: [segments at: newSegIndex put: SpurSegmentInfo new].
		 newSeg := self addressOf: (segments at: newSegIndex).
		 newSeg
			segStart: segAddress asUnsignedIntegerPtr;
			segSize: allocatedSize;
			swizzle: 0. "Required in the C version only"
		 self assert: self segmentOverlap not. "self printSegmentAddresses."
		 self bridgeFrom: (self addressOf: (segments at: newSegIndex - 1)) to: newSeg.
		 self bridgeFrom: newSeg to: (newSegIndex = (numSegmentsM1) ifFalse:
										[self addressOf: (segments at: newSegIndex + 1)]).
		 totalHeapSizeIncludingBridges := totalHeapSizeIncludingBridges + allocatedSize.
		 "test isInMemory:"
		 0 to: numSegmentsM1 do:
			[:i|
			self assert: (self isInSegments: (segments at: i) segStart).
			self assert: (self isInSegments: (segments at: i) segLimit - manager wordSize).
			self assert: ((self isInSegments: (segments at: i) segLimit) not
						or: [i < (numSegmentsM1)
							and: [(segments at: i) segLimit = (segments at: i + 1) segStart]]).
			self assert: ((self isInSegments: (segments at: i) segStart - manager wordSize) not
							or: [i > 0
								and: [(segments at: i - 1) segLimit = (segments at: i) segStart]])].
		 ^newSeg].
	^nil
]

{ #category : #snapshot }
SpurSegmentManager >> adjustSegmentSwizzlesBy: firstSegmentShift [
	"Adjust swizzles by firstSegmentShift.  Also computes segStarts as
	 they were in the image when it was written, so that oops' segments
	 can be determined and hence oops correctly swizzled."
	<inline: false>
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
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

{ #category : #'debug support' }
SpurSegmentManager >> allBridgesMarked [
	0 to: numSegments - 1 do:
		[:i| | bridgeObj |
		 bridgeObj := self bridgeAt: i.
		 self assert: (self isValidSegmentBridge: bridgeObj).
		 (manager isMarked: bridgeObj) ifFalse:
			[^false]].
	^true

	"for debugging:"
	"(0 to: numSegments - 1) select:
		[:i| | bridgeObj |
		 bridgeObj := self bridgeAt: i.
		 self assert: (self isValidSegmentBridge: bridgeObj).
		 manager isMarked: bridgeObj]"
]

{ #category : #private }
SpurSegmentManager >> allocateOrExtendSegmentInfos [
	"Increase the number of allocated segInfos by 16."
	| newNumSegs |
	numSegInfos = 0 ifTrue:
		[numSegInfos := 16.
		 segments := self
						cCode: [self c: numSegInfos alloc: (self sizeof: SpurSegmentInfo)]
						inSmalltalk: [CArrayAccessor on: ((1 to: numSegInfos) collect: [:i| SpurSegmentInfo new])].
		 ^self].
	newNumSegs := numSegInfos + 16.
	segments := self
						cCode: [self re: segments alloc: newNumSegs * (self sizeof: SpurSegmentInfo)]
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

{ #category : #bridges }
SpurSegmentManager >> bridgeAt: segIndex [
	^self bridgeFor: (self addressOf: (segments at: segIndex))
]

{ #category : #bridges }
SpurSegmentManager >> bridgeFor: aSegment [
	<var: 'aSegment' type: #'SpurSegmentInfo *'>
	^manager objectStartingAt: aSegment segLimit - manager bridgeSize
]

{ #category : #'growing/shrinking memory' }
SpurSegmentManager >> bridgeFrom: aSegment to: nextSegmentOrNil [
	"Create a bridge from aSegment to the next segment,
	 or create a terminating bridge if there is no next segment."
	<var: #aSegment type: #'SpurSegmentInfo *'>
	<var: #nextSegmentOrNil type: #'SpurSegmentInfo *'>
	| segEnd clifton bridgeSpan |
	segEnd := aSegment segLimit.
	clifton := segEnd - manager bridgeSize. "clifton is where the Avon bridge begins..."
	bridgeSpan := nextSegmentOrNil
					ifNil: [manager bridgeSize]
					ifNotNil: [nextSegmentOrNil segStart - segEnd + manager bridgeSize].
	self assert: bridgeSpan >= 0.
	manager initSegmentBridgeWithBytes: bridgeSpan at: clifton.
	"the revised bridge should get us to the new segment"
	self assert: (manager addressAfter: (manager objectStartingAt: clifton))
				= (nextSegmentOrNil
						ifNil: [aSegment segLimit]
						ifNotNil: [nextSegmentOrNil segStart])

]

{ #category : #'debug support' }
SpurSegmentManager >> checkSegments [
	self assert: numSegments >= 1.
	0 to: numSegments - 1 do:
		[:i|
		self assert: (manager addressCouldBeObj: (segments at: i) segStart).
		self assert: (self isValidSegmentBridge: (self bridgeAt: i))].
	self assert: (segments at: numSegments - 1) segLimit - manager bridgeSize = manager endOfMemory
]

{ #category : #snapshot }
SpurSegmentManager >> collapseSegmentsPostSwizzle [
	"The image has been loaded, old segments reconstructed, and the heap
	 swizzled into a single contiguous segment.  Collapse the segments into one."
	<inline: false>
	canSwizzle := false.
	self cCode: []
		inSmalltalk:
			[segments ifNil:
				[self allocateOrExtendSegmentInfos]].
	numSegments := 1.
	(segments at: 0)
		segStart: manager oldSpaceStart;
		segSize: (totalHeapSizeIncludingBridges := manager endOfMemory - manager oldSpaceStart).
	manager bootstrapping ifTrue:
		["finally plant a bridge at the end of the coalesced segment and cut back the
		  manager's notion of the end of memory to immediately before the bridge."
		 self assert: manager endOfMemory = (segments at: 0) segLimit.
		 manager
			initSegmentBridgeWithBytes: manager bridgeSize
			at: manager endOfMemory - manager bridgeSize].
	self assert: (manager isSegmentBridge: (self bridgeAt: 0)).
	self assert: (manager numSlotsOfAny: (self bridgeAt: 0)) = 0
]

{ #category : #'simulation only' }
SpurSegmentManager >> computeTotalHeapSizeIncludingBridges [
	totalHeapSizeIncludingBridges := manager endOfMemory - manager oldSpaceStart
]

{ #category : #'growing/shrinking memory' }
SpurSegmentManager >> findEmptySegNearestInSizeTo: size [
	| seg best delta |
	<var: #seg type: #'SpurSegmentInfo *'>
	<var: #best type: #'SpurSegmentInfo *'>
	best := nil.
	delta := size.
	0 to: numSegments - 1 do:
		[:i|
		seg := self addressOf: (segments at: i).
		(self isEmptySegment: seg) ifTrue:
			[best
				ifNil: [best := seg]
				ifNotNil:
					[(size >= (seg segSize * 0.75)
					 and: [(self cCoerce: (seg segSize - size) to: #sqInt ) abs < delta]) ifTrue:
						[best := seg. delta := (self cCoerce: (seg segSize - size) to: #sqInt ) abs]]]].
	^best
]

{ #category : #'growing/shrinking memory' }
SpurSegmentManager >> firstGapOfSizeAtLeast: size [
	"Answer the segment limit of the first segment followed by a gap of at least size bytes."
	0 to: numSegments - 2 do:
		[:i| | bridge |
		bridge := self bridgeAt: i.
		(manager bytesInObject: bridge) - manager bridgeSize >= size ifTrue:
			[^(segments at: i) segLimit asVoidPointer]].
	^(segments at: numSegments - 1) segLimit asVoidPointer
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

{ #category : #'growing/shrinking memory' }
SpurSegmentManager >> indexOfSegment: seg [
	<var: #seg type: #'SpurSegmentInfo *'>
	0 to: numSegments - 1 do:
		[:i|
		seg segStart = (segments at: i) segStart ifTrue:
			[^i]].
	self error: 'segment not found'
]

{ #category : #'spur bootstrap' }
SpurSegmentManager >> initForBootstrap [
	numSegInfos = 0 ifTrue:
		[self allocateOrExtendSegmentInfos]
]

{ #category : #'simulation only' }
SpurSegmentManager >> initSegmentForInImageCompilationFrom: base to: limit [
	<doNotGenerate>
	| bridge |
	self allocateOrExtendSegmentInfos.
	numSegments := 1.
	bridge := manager initSegmentBridgeWithBytes: manager memory byteSize - limit at: limit - manager bridgeSize.
	segments := {SpurSegmentInfo new
						segStart: base;
						segSize: limit - base;
						yourself}.
	segments := CArrayAccessor on: segments
]

{ #category : #initialization }
SpurSegmentManager >> initialize [
	numSegments := numSegInfos := sweepIndex := totalHeapSizeIncludingBridges := 0.
	canSwizzle := false
]

{ #category : #'simulation only' }
SpurSegmentManager >> initializeFromFreeChunks: freeChunks [
	<doNotGenerate>
	"For testing, create a set of segments using the freeChunks as bridges."
	self assert: (freeChunks allSatisfy: [:f| manager hasOverflowHeader: f]).
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
	manager setEndOfMemory: segments last segLimit.
	segments := CArrayAccessor on: segments.
	freeChunks with: segments object do:
		[:bridge :segment|
		self assert: (self isValidSegmentBridge: bridge).
		self assert: bridge = (self bridgeFor: segment)]
]

{ #category : #'growing/shrinking memory' }
SpurSegmentManager >> insertSegmentFor: segAddress [
	"Reserve a new segInfo for segAddress.  If segAddress
	 is in the middle of the existing segments, shuffle them
	 up to make room. Answer the new segment's index."
	| segIndex lastSegIndex |
	self assert: segAddress >= (segments at: 0) segLimit.
	numSegments = numSegInfos ifTrue:
		[self allocateOrExtendSegmentInfos].
	self assert: numSegments < numSegInfos.
	segIndex := lastSegIndex := numSegments - 1.
	numSegments := numSegments + 1.
	[segAddress >= (segments at: segIndex) segLimit ifTrue:
		[segIndex := segIndex + 1.
		 lastSegIndex to: segIndex by: -1 do:
			[:idx| segments at: idx + 1 put: (segments at: idx)].
		 ^segIndex].
	 segIndex := segIndex - 1]
		repeat
]

{ #category : #'growing/shrinking memory' }
SpurSegmentManager >> isEmptySegment: seg [
	<var: #seg type: #'SpurSegmentInfo *'>
	| firstObj |
	firstObj := manager objectStartingAt: seg segStart.
	^(manager isFreeObject: firstObj)
	  and: [(manager addressAfter: firstObj) = (seg segLimit - manager bridgeSize)]
]

{ #category : #testing }
SpurSegmentManager >> isInSegments: address [
	<var: #address type: #usqInt>
	0 to: numSegments - 1 do:
		[:i|
		address < (segments at: i) segStart ifTrue:
			[^false].
		address < (segments at: i) segLimit ifTrue:
			[^true]].
	^false
]

{ #category : #testing }
SpurSegmentManager >> isValidSegmentBridge: objOop [
	"bridges bridge the gaps between segments. They are the last object in each segment."
	^((manager addressCouldBeObj: objOop) or: [objOop = manager endOfMemory])
	  and: [(manager isSegmentBridge: objOop)
	  and: [(manager hasOverflowHeader: objOop)
		or: [(manager numSlotsOfAny: objOop) = 0]]]
]

{ #category : #accessing }
SpurSegmentManager >> lastBridge [
	^self bridgeAt: numSegments - 1
]

{ #category : #accessing }
SpurSegmentManager >> lastSegment [
	^segments at: numSegments - 1
]

{ #category : #initialization }
SpurSegmentManager >> manager: aSpurMemoryManager [
	manager := aSpurMemoryManager
]

{ #category : #snapshot }
SpurSegmentManager >> nextNonEmptySegmentAfter: i [
	"Answer the the next non-empty segment or nil. The size of a segment includes
	 that of its bridge. A segment containing just a free object and a bridge will still
	 have a size of manager bridgeSize after shortening it in prepareForSnapshot."
	<returnTypeC: #'SpurSegmentInfo *'>
	| nextx |
	nextx := i.
	[(nextx := nextx + 1) >= numSegments ifTrue:
		[^nil].
	 (segments at: nextx) segSize > manager bridgeSize ifTrue:
		[^self addressOf: (segments at: nextx)]] repeat
]

{ #category : #pinning }
SpurSegmentManager >> notePinned: objOop [
	"Let the segmentManager mark which segments contain pinned objects"
	self assert: (manager isPinned: objOop).
	(manager isSegmentBridge: objOop)
		ifTrue:
			[manager setIsMarkedOf: objOop to: true]
		ifFalse:
			[[self oop: (segments at: sweepIndex) segLimit isLessThan: objOop] whileTrue:
				[sweepIndex := sweepIndex + 1].
			 (segments at: sweepIndex) containsPinned: true]
]

{ #category : #accessing }
SpurSegmentManager >> numSegments [
	<cmacro: '() GIV(numSegments)'>
	^numSegments
]

{ #category : #snapshot }
SpurSegmentManager >> postSnapshot [
	"Restore all shortened segments to their proper size, re-freeing the trailing space."
	<inline: false>
	| seg |
	<var: #seg type: #'SpurSegmentInfo *'>
	"Set endOfMemory first, to avoid assert fails in freeChunkWithBytes:at:."
	seg := self addressOf: (segments at: numSegments - 1).
	seg lastFreeObject
		ifNil: [self assert: manager endOfMemory = (seg segLimit - manager bridgeSize)]
		ifNotNil: [manager setEndOfMemory: seg savedSegSize + seg segStart - manager bridgeSize].

	numSegments - 1 to: 0 by: -1 do:
		[:i|
		 seg := self addressOf: (segments at: i).
		 seg lastFreeObject ifNotNil:
			[:freeChunk| | address |
			address := seg segLimit - manager bridgeSize.
			seg segSize: seg savedSegSize.
			self bridgeFrom: seg
				to: (i < (numSegments - 1) ifTrue: [self addressOf: (segments at: i + 1)]).
			manager
				addFreeChunkWithBytes: seg segLimit - address - manager bridgeSize
				at: address]].
	self checkSegments.
	manager checkFreeSpace: GCModeFull
]

{ #category : #pinning }
SpurSegmentManager >> prepareForGlobalSweep [
	"Let the segmentManager mark which segments contain pinned objects via notePinned:.
	 For coallesceFreeChunk:, ensure that the last bridge is marked."
	sweepIndex := 0.
	0 to: numSegments - 1 do:
		[:i| (segments at: i) containsPinned: false].
	manager
		setIsMarkedOf: (self bridgeAt: numSegments - 1)
		to: true
]

{ #category : #snapshot }
SpurSegmentManager >> prepareForSnapshot [
	"shorten all segments by any trailing free space."
	<inline: #never>
	<var: #seg type: #'SpurSegmentInfo *'>
	self checkSegments.
	0 to: numSegments - 1 do:
		[:i|
		 (segments at: i)
			savedSegSize: (segments at: i) segSize;
			lastFreeObject: nil].

	"Ideally finding the lastFreeObject of each segment would be
	 done in some linear pass through the heap.  But for now KISS."
	manager freeTreeNodesDo:
		[:freeChunk| | node next seg |
		 node := freeChunk.
		 [node ~= 0] whileTrue:
			[next := manager objectAfter: node limit: manager endOfMemory.
			 (manager isSegmentBridge: next)
				ifTrue:
					[seg := self segmentContainingObj: node.
					 seg lastFreeObject: node.
					 node := 0]
				ifFalse:
					[node := manager
								fetchPointer: manager freeChunkNextIndex
								ofFreeChunk: node]].
		 freeChunk].

	0 to: numSegments - 1 do:
		[:i|
		 (segments at: i) lastFreeObject ifNotNil:
			[:freeChunk|
			manager detachFreeObject: freeChunk.
			(segments at: i)
				segSize: (manager startOfObject: freeChunk)
						+ manager bridgeSize
						- (segments at: i) segStart.
			self bridgeFrom: (self addressOf: (segments at: i))
				to: (i < (numSegments - 1) ifTrue: [self addressOf: (segments at: i + 1)])]].

	"perhaps this should read
		manager setEndOfMemory: 0; assimilateNewSegment: (segments at: numSegments - 1)"
	manager setEndOfMemory: (segments at: numSegments - 1) segLimit - manager bridgeSize
]

{ #category : #'simulation only' }
SpurSegmentManager >> printSegmentAddresses [
	<doNotGenerate>
	"Convenient when debugging segment overlap"
	Transcript show: 'Seg addresses: '; cr.
	0 to: numSegments - 1 do:
		[:i|
			Transcript
				show: (segments at: i) segStart;
				show: ' -> ';
				show: (segments at: i) segLimit;
				show: ' ; '].
			Transcript cr.
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
			[| bytesPerElement |
			 bytesPerElement := manager memory bytesPerElement.
			 (f	readInto: manager memory
				startingAt: location // bytesPerElement + 1
				count: numBytes // bytesPerElement)
			  * bytesPerElement]
]

{ #category : #snapshot }
SpurSegmentManager >> readHeapFromImageFile: f dataBytes: numBytes [
	"Read numBytes of image data from f into memory at memoryBaseForImageRead.
	 Answer the number of bytes written.  In addition, read each segment, build up the
	 segment info for swizzling, while eliminating the bridge objects at the end of each
	 segment that specify the distance to and the size of the subsequent segment."
	<var: #f type: #sqImageFile>
	<inline: false>
	| bytesRead totalBytesRead bridgehead bridge nextSegmentSize oldBase newBase segInfo bridgeSpan |
	<var: 'segInfo' type: #'SpurSegmentInfo *'>
	self allocateOrExtendSegmentInfos.

	"segment sizes include the two-header-word bridge at the end of each segment."
	numSegments := totalBytesRead := 0.
	oldBase := 0. "N.B. still must be adjusted by oldBaseAddr."
	newBase := manager oldSpaceStart.
	nextSegmentSize := firstSegmentSize.
	bridgehead := firstSegmentSize + manager oldSpaceStart - manager bridgeSize.
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
	 (numSegments := numSegments + 1) >= numSegInfos ifTrue:
		[self allocateOrExtendSegmentInfos].
	 bridge := bridgehead + manager baseHeaderSize.
	 bridgeSpan := (manager rawNumSlotsOf: bridgehead) = 0
						ifTrue: [0]
						ifFalse: [manager bytesPerOop * (manager rawOverflowSlotsOf: bridge)].
	 oldBase := oldBase + nextSegmentSize + bridgeSpan.
	 newBase := newBase + nextSegmentSize - manager bridgeSize.
	 nextSegmentSize := (manager long64At: bridge) asUnsignedInteger.
	 nextSegmentSize ~= 0] whileTrue:
		[bridgehead := bridgehead - manager bridgeSize + nextSegmentSize].
	"newBase should point just past the last bridge. all others should have been eliminated."
	self assert: newBase - manager oldSpaceStart
				= (totalBytesRead - (numSegments * manager bridgeSize)).
	"set freeOldSpaceStart now for adjustAllOopsBy:"
	manager setFreeOldSpaceStart: newBase.
	"we're done. nil firstSegmentSize for a subsequent snapshot."
	firstSegmentSize := nil.
	^totalBytesRead
]

{ #category : #'growing/shrinking memory' }
SpurSegmentManager >> removeSegment: emptySeg [
	<var: #emptySeg type: #'SpurSegmentInfo *'>
	| i |
	i := self indexOfSegment: emptySeg.
	self assert: i > 0.

	totalHeapSizeIncludingBridges := totalHeapSizeIncludingBridges - emptySeg segSize.
	manager sqDeallocateMemorySegmentAt: emptySeg segStart asVoidPointer OfSize: emptySeg segSize.

	i to: numSegments - 2 do:
		[:j| segments at: j put: (segments at: j + 1)].
	self cCode: [] inSmalltalk: [segments at: numSegments - 1 put: SpurSegmentInfo new].
	numSegments := numSegments - 1.

	self bridgeFrom: (self addressOf: (segments at: i - 1))
		to: (i <= (numSegments - 1) ifTrue: [self addressOf: (segments at: i)]).

	manager setLastSegment: (self addressOf: (segments at: numSegments - 1))
]

{ #category : #accessing }
SpurSegmentManager >> segmentContainingObj: objOop [
	<export: true>
	<returnTypeC: #'SpurSegmentInfo *'>
	numSegments - 1 to: 0 by: -1 do:
		[:i|
		objOop >= (segments at: i) segStart ifTrue:
			[^self addressOf: (segments at: i)]].
	^nil
]

{ #category : #'growing/shrinking memory' }
SpurSegmentManager >> segmentOverlap [
	"Answers true if a segment overlaps with another one."
	0 to: numSegments - 1 do:
		[:i| | starti endi |
			starti := (segments at: i) segStart.
			endi := (segments at: i) segLimit.
			0 to: numSegments - 1 do:
				[:j| | startj endj |
					startj := (segments at: j) segStart.
					endj := (segments at: j) segLimit.
					i = j ifFalse: 
						[(starti < startj or: [starti >= endj])
							ifFalse: 
								[self cCode: '' inSmalltalk: [self error: 'segment overlap ' , i printString , ' and ' , j printString].
								 ^true].
						 (endi <= startj or: [endi >= endj])
							ifFalse: [self cCode: '' inSmalltalk: [self error: 'segment overlap ' , i printString , ' and ' , j printString].
								 ^true].
						"self printSegmentAddresses"
						]]].
	^false
]

{ #category : #accessing }
SpurSegmentManager >> segments [
	<cmacro: '() GIV(segments)'>
	^segments
]

{ #category : #'growing/shrinking memory' }
SpurSegmentManager >> shrinkObjectMemory: delta [
	"Answer if any shrinkage was achieved."
	<inline: false>
	<var: #delta type: #usqInt>
	| shrinkage emptySeg |
	<var: #shrinkage type: #usqInt>
	<var: #emptySeg type: #'SpurSegmentInfo *'>
	manager checkFreeSpace: GCModeFreeSpace.
	shrinkage := delta.
	[emptySeg := self findEmptySegNearestInSizeTo: shrinkage.
	 (emptySeg isNil
	  or: [emptySeg segSize > shrinkage]) ifTrue:
		[manager checkFreeSpace: GCModeFreeSpace.
		 ^shrinkage < delta].
	 shrinkage := shrinkage - emptySeg segSize.
	 manager detachFreeObject: (manager objectStartingAt: emptySeg segStart).
	 self removeSegment: emptySeg] repeat
]

{ #category : #pinning }
SpurSegmentManager >> someSegmentContainsPinned [
	0 to: numSegments - 1 do:
		[:i| (segments at: i) containsPinned ifTrue: [^true]].
	^false
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
SpurSegmentManager >> totalBytesInNonEmptySegments [
	| total |
	total := 0.
	0 to: numSegments - 1 do:
		[:i|
		(segments at: i) segSize > manager bridgeSize ifTrue:
			[total := total + (segments at: i) segSize]].
	^total
]

{ #category : #accessing }
SpurSegmentManager >> totalBytesInSegments [
	| total |
	<var: #total type: #usqInt>
	total := 0.
	0 to: numSegments - 1 do:
		[:i|
		total := total + (segments at: i) segSize].
	self assert: totalHeapSizeIncludingBridges = total.
	^total
]

{ #category : #accessing }
SpurSegmentManager >> totalOldSpaceCapacity [
	^totalHeapSizeIncludingBridges - (numSegments * manager bridgeSize)
]

{ #category : #snapshot }
SpurSegmentManager >> writeImageSegmentsToFile: aBinaryStream [
	<var: 'aBinaryStream' type: #sqImageFile>
	<inline: false>
	| total |
	self assert: (manager endOfMemory = (segments at: numSegments - 1) segLimit
				 or: [manager endOfMemory + manager bridgeSize = (segments at: numSegments - 1) segLimit]).
	firstSegmentSize ifNotNil:
		[self assert: firstSegmentSize = (segments at: 0) segSize].
	self assert: (segments at: 0) segSize > 0.
	total := 0.
	0 to: numSegments - 1 do:
		[:i|
		(segments at: i) segSize > manager bridgeSize ifTrue:
			[total := total + (self writeSegment: (self addressOf: (segments at: i))
								nextSegment: (self nextNonEmptySegmentAfter: i)
								toFile: aBinaryStream)]].
	^total
]

{ #category : #snapshot }
SpurSegmentManager >> writeSegment: segment nextSegment: nextSegment toFile: aBinaryStream [
	"Write the segment contents, the size of and the distance to the next segment to aBinaryStream."
	<var: 'segment' type: #'SpurSegmentInfo *'>
	<var: 'nextSegment' type: #'SpurSegmentInfo *'>
	<var: 'aBinaryStream' type: #sqImageFile>
	| pier1 pier2 firstSavedBridgeWord secondSavedBridgeWord nWritten |
	<var: 'firstSavedBridgeWord' type: #usqLong>
	<var: 'secondSavedBridgeWord' type: #usqLong>
	pier1 := segment segLimit - manager bridgeSize.
	pier2 := pier1 + manager baseHeaderSize.
	self assert: (self isValidSegmentBridge: (self bridgeFor: segment)).
	self assert: (manager startOfObject: (self bridgeFor: segment)) = pier1.
	"Temporarily change the bridge to bridge to the next non-empty segment.
	 The first double word of the bridge includes the bridge size in slots, and
	 hence specifies the distance to the next segment. The following double
	 word is replaced by the size of the next segment, or 0 if there isn't one."
	firstSavedBridgeWord := manager long64At: pier1.
	secondSavedBridgeWord := manager long64At: pier2.
	self bridgeFrom: segment to: nextSegment.
	manager
		long64At: pier2
		put: (nextSegment ifNil: [0] ifNotNil: [nextSegment segSize]).
	nWritten := self cCode:
						[self
							sq: segment segStart asVoidPointer
							Image: 1
							File: segment segSize
							Write: aBinaryStream]
					inSmalltalk:
						[| bytesPerElement |
						 bytesPerElement := manager memory bytesPerElement.
						 aBinaryStream
							next: segment segSize / bytesPerElement
							putAll: manager memory
							startingAt: segment segStart / bytesPerElement + 1.
						 segment segSize].
	manager
		long64At: pier1 put: firstSavedBridgeWord;
		long64At: pier2 put: secondSavedBridgeWord.
	^nWritten
]
