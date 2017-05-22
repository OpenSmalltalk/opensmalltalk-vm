"
I am a refinement of ObjectMemory that eliminates the need for pushRemappableOop:/popRemappableOop in the interpreter proper.  Certain primitives that do major allocation may still want to provoke a garbage collection and hence may still need to remap private pointers.  But the interpreter subclass of this class does not have to provided it reserves sufficient space for it to make progress to the next scavenge point (send or backward branch).
"
Class {
	#name : #NewObjectMemory,
	#superclass : #ObjectMemory,
	#instVars : [
		'coInterpreter',
		'freeStart',
		'reserveStart',
		'scavengeThreshold',
		'needGCFlag',
		'fullGCLock',
		'edenBytes',
		'checkForLeaks',
		'statGCEndUsecs',
		'heapMap'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #translation }
NewObjectMemory class >> declareCVarsIn: aCCodeGenerator [
	self declareCAsOop: #(freeStart reserveStart scavengeThreshold)
		in: aCCodeGenerator.
	aCCodeGenerator var: #statGCEndUsecs type: #usqLong
]

{ #category : #'class initialization' }
NewObjectMemory class >> initialize [
	"This is for Monticello package loading"
	self initializeWithOptions: Dictionary new
]

{ #category : #translation }
NewObjectMemory class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^(super mustBeGlobal: var)
	   or: ['checkForLeaks' = var]
]

{ #category : #'accessing class hierarchy' }
NewObjectMemory class >> objectRepresentationClass [
	^CogObjectRepresentationForSqueakV3
]

{ #category : #translation }
NewObjectMemory class >> prepareToBeAddedToCodeGenerator: aCodeGen [
	"Remove the methods and instance variables we don't use."

	self ~~ NewObjectMemory ifTrue: "No Need to repeat in NewCoObjectMemory"
		[^self].

	aCodeGen
		removeMethodForSelector: #markPhase; "we implement markPhase:"
		removeMethodForSelector: #printWronglySizedContexts. "we implement printWronglySizedContexts:"
	"This class uses freeStart in place of freeBlock.  It does
	 not maintain an allocationCount nor stats there-of.
	 Having an interpreter that uses a stack zone, it doesn't
	 need an optimized context allocator."
	aCodeGen
		removeVariable: 'freeBlock';
		removeVariable: 'allocationCount';
		removeVariable: 'allocationsBetweenGCs';
		removeVariable: 'statAllocationCount';
		removeVariable: 'freeContexts';
		removeVariable: 'freeLargeContexts';
		removeVariable: 'statGCEndTime' "replaced by statGCEndUsecs"
]

{ #category : #simulation }
NewObjectMemory class >> simulatorClass [
	^NewObjectMemorySimulator
]

{ #category : #'object enumeration' }
NewObjectMemory >> accessibleObjectAfter: oop [ 
	"Return the accessible object following the given object or 
	free chunk in the heap. Return nil when heap is exhausted."
	| obj |
	obj := self objectAfter: oop.
	[self oop: obj isLessThan: freeStart] whileTrue:
		[(self isFreeObject: obj) ifFalse: [^obj].
		 obj := self objectAfter: obj].
	^nil
]

{ #category : #'debug support' }
NewObjectMemory >> addressCouldBeObj: address [
	<api>
	"Answer if address appears to be that of an object, which implies it is
	 safe to fetch the class and size. For code disassembly and assertions."
	^(address bitAnd: 3) = 0
	  and: [address asUnsignedInteger >= self startOfMemory
	  and: [address asUnsignedInteger < freeStart
	  and: [(self headerType: address) ~= HeaderTypeGC]]]
]

{ #category : #'debug support' }
NewObjectMemory >> addressCouldBeObjWhileForwarding: address [
	"Answer if address appears to be that of an object, which implies it is
	 safe to fetch the class and size. For code disassembly and assertions."
	^(address bitAnd: 3) = 0
	  and: [address asUnsignedInteger >= self startOfMemory
	  and: [address asUnsignedInteger < freeStart]]
]

{ #category : #initialization }
NewObjectMemory >> adjustAllOopsBy: bytesToShift [ 
	"Adjust all oop references by the given number of bytes. This is
	 done just after reading in an image when the new base address
	 of the object heap is different from the base address in the image."
	"di 11/18/2000 - return number of objects found"

	| oop nextOop totalObjects |
	<inline: false>
	bytesToShift = 0 ifTrue: [^300000].
	"this is probably an improvement over the previous answer of nil,
	 but maybe we should do the obejct counting loop and simply
	 guard the adjustFieldsAndClass... with a bytesToShift = 0 ifFalse: ?"
	totalObjects := 0.
	oop := self firstObject.
	[self oop: oop isLessThan: freeStart] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[totalObjects := totalObjects + 1.
			 self adjustFieldsAndClassOf: oop by: bytesToShift].
		 nextOop := self objectAfter: oop.
		 self assert: (self oop: oop isLessThan: nextOop).
		 oop := nextOop].
	^totalObjects
]

{ #category : #'primitive support' }
NewObjectMemory >> allInstancesOf: aBehavior [
	"Attempt to answer all instances of aBehavior, failing if there is not enough room."
	| count container fillPointer obj byteSize afterPreAllocatedObject |
	"Allocate a large header Array of sufficient size to require a large header.
	 Reset its size later."
	container := self instantiateClass: (self splObj: ClassArray) indexableSize: self minLargeHeaderSize.
	self sizeHeader: container putBodySize: 0.
	afterPreAllocatedObject := freeStart.
	freeStart := fillPointer := (self firstFixedField: container) asInteger.
	count := 0.
	obj := self firstObject.
	[self oop: obj isLessThan: container] whileTrue:
		[(self isFreeObject: obj) ifFalse:
			[(self fetchClassOfNonImm: obj) = aBehavior ifTrue:
				[count := count + 1.
				 fillPointer < reserveStart ifTrue:
					[self longAt: fillPointer put: obj.
					 fillPointer := fillPointer + self bytesPerOop]]].
		 obj := self accessibleObjectAfter: obj].
	fillPointer >= reserveStart ifTrue: "didn't fit.  refill with allocation check pattern and answer count."
		[self maybeFillWithAllocationCheckFillerFrom: freeStart to: fillPointer.
		 ^self integerObjectOf: count].
	byteSize := fillPointer - (self firstFixedField: container) asInteger.
	self sizeHeader: container putBodySize: byteSize.
	"Need to refill with the allocation check pattern if we shortened the object."
	fillPointer < afterPreAllocatedObject ifTrue:
		[self maybeFillWithAllocationCheckFillerFrom: fillPointer to: afterPreAllocatedObject].
	freeStart := fillPointer.
	^container
]

{ #category : #'object enumeration' }
NewObjectMemory >> allObjectsDo: aBlock [
	<inline: true>
	| oop |
	oop := self firstObject.
	[oop asUnsignedInteger < freeStart] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[aBlock value: oop].
		 oop := self objectAfter: oop]
]

{ #category : #'object enumeration' }
NewObjectMemory >> allObjectsDoSafely: aBlock [
	<inline: true>
	| oop |
	oop := self firstObject.
	[oop asUnsignedInteger < freeStart] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[aBlock value: oop].
		 oop := self objectAfterWhileForwarding: oop]
]

{ #category : #'primitive support' }
NewObjectMemory >> allObjectsUnmarked [
	self allObjectsDo:
		[:o| (self isMarked: o) ifTrue: [^false]].
	^true
]

{ #category : #allocation }
NewObjectMemory >> allocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOopArg h3: extendedSize doFill: doFill format: format [
	"Allocate a new object of the given size and number of header words. (Note: byteSize already includes space for the base header word.) Initialize the header fields of the new object and fill the remainder of the object with a value appropriate for the format.
	May cause a GC"

	| newObj classOop |
	<inline: true>
	<var: #i type: #usqInt>
	<var: #end type: #usqInt>
	newObj := self allocateChunk: byteSize + (hdrSize - 1 * self wordSize).
	newObj = 0
		ifTrue:
			["remap classOop because GC may move the classOop"
			hdrSize > 1 ifTrue: [self pushRemappableOop: classOopArg].
			newObj := self allocateChunkAfterGC: byteSize + (hdrSize - 1 * self wordSize).
			hdrSize > 1 ifTrue: [classOop := self popRemappableOop].
			newObj = 0 ifTrue: [^newObj]]
		ifFalse: [classOop := classOopArg].

	hdrSize = 3 ifTrue:
		[self longAt: newObj put: (extendedSize bitOr: HeaderTypeSizeAndClass).
		 self longAt: newObj + self wordSize put: (classOop bitOr: HeaderTypeSizeAndClass).
		 self longAt: newObj + (self wordSize*2) put: (baseHeader bitOr: HeaderTypeSizeAndClass).
		 newObj := newObj + (self wordSize*2)].

	hdrSize = 2 ifTrue:
		[self longAt: newObj put: (classOop bitOr: HeaderTypeClass).
		 self longAt: newObj + self wordSize put: (baseHeader bitOr: HeaderTypeClass).
		 newObj := newObj + self wordSize].

	hdrSize = 1 ifTrue:
		[self longAt: newObj put: (baseHeader bitOr: HeaderTypeShort)].

	"clear new object"
	doFill ifTrue:
		[| fillWord end i |
		 fillWord := format <= self lastPointerFormat
						ifTrue: [nilObj] "if pointers, fill with nil oop"
						ifFalse: [0].
		 end := newObj + byteSize.
		 i := newObj + self wordSize. "skip header"
		 [i < end] whileTrue:
			[self longAt: i put: fillWord.
			 i := i + self wordSize].
		 self assert: i = freeStart.].
	DoExpensiveAssertionChecks ifTrue:
		[self okayOop: newObj.
		 self oopHasOkayClass: newObj.
		 (self safeObjectAfter: newObj) = freeStart ifFalse:
			[self error: 'allocate bug: did not set header of new oop correctly']].

	^newObj
]

{ #category : #allocation }
NewObjectMemory >> allocateChunk: byteSize [ 
	"Allocate a chunk of the given size. Sender must be sure that the requested size
	 includes enough space for the header word(s).  This version is for normal allocations
	 and refuses to allocate beyond the interpreter's reserveStart.  If the allocation takes
	 freeStart over the scavenge threshold schedule a garbage collection.  If this returns 0
	 the client should prepare for garbage collection and retry using allocateChunkAfterGC:"
	| newChunk newFreeStart |
	<inline: true>
	<var: #newChunk type: #usqInt>
	<var: #newFreeStart type: #usqInt>
	newChunk := freeStart.
	newFreeStart := freeStart + byteSize.
	newFreeStart < scavengeThreshold ifTrue:
		[freeStart := newFreeStart.
		 ^self oopForPointer: newChunk].

	self scheduleIncrementalGC.
	freeStart <= reserveStart ifTrue:
		[freeStart := newFreeStart.
		 ^self oopForPointer: newChunk].

	^0
]

{ #category : #allocation }
NewObjectMemory >> allocateChunkAfterGC: byteSize [ 
	"Garbage collect and then allocate a chunk of the given size. Sender must be sure
	 that the requested size includes enough space for the header word(s)."
	| newChunk enoughSpace |
	<inline: true>
	<var: #newChunk type: #usqInt>
	enoughSpace := self sufficientSpaceToAllocate: byteSize.
	enoughSpace ifFalse:
		["signal that space is running low, but proceed with allocation if possible"
		 self setSignalLowSpaceFlagAndSaveProcess].
	(self oop: freeStart + byteSize isGreaterThan: reserveStart) ifTrue:
		[^0 "Allocation failed.  Client should e.g. fail the primtive"].

	"if we get here, there is enough space for allocation to succeed "
	newChunk := freeStart.
	freeStart := freeStart + byteSize.
	^self oopForPointer: newChunk
]

{ #category : #allocation }
NewObjectMemory >> allocateInterpreterChunk: byteSize [ 
	"Allocate a chunk of the given size. Sender must be sure that the requested size
	 includes enough space for the header word(s).  This version is for interpreter
	 allocations and will allocate beyond the interpreter's reserveStart.  If the allocation
	 takes freeStart over the scavenge threshold schedule a garbage collection."
	| newChunk newFreeStart |
	<inline: true>
	<var: #newChunk type: #usqInt>
	<var: #newFreeStart type: #usqInt>

	newChunk := freeStart.
	newFreeStart := freeStart + byteSize.
	newFreeStart < scavengeThreshold ifTrue:
		[freeStart := newFreeStart.
		 ^self oopForPointer: newChunk].

	"Don't thrash doing collections when over the scavengeThreshold.
	 Only schedule an incrementalGC if this allocation took us over the threshold."
	freeStart < scavengeThreshold ifTrue:
		[self scheduleIncrementalGC].

	newFreeStart < reserveStart ifTrue:
		[freeStart := newFreeStart.
		 ^self oopForPointer: newChunk].

	"space is low.  A scavenge may reclaim sufficient space and this may be a
	 false alarm.  We actually check for low space after the incremental collection.
	 But we really do need to do a scavenge promptly, if only to check for low
	 space.  We cannot do a garbage collect now without moving pointers under
	 the VM's feet, which is too error-prone and inefficient to contemplate."

	self scheduleIncrementalGC.

	freeStart <= endOfMemory ifTrue:
		[freeStart := newFreeStart.
		 ^self oopForPointer: newChunk].

	self error: 'out of memory'.
	^nil
]

{ #category : #simulation }
NewObjectMemory >> allocateMemoryOfSize: limit [
	<doNotGenerate>
	super allocateMemoryOfSize: limit.
	freeStart := memoryLimit
]

{ #category : #snapshot }
NewObjectMemory >> baseAddressOfImage [
	"Answer the base address of the image data written to a sapshot."
	^self startOfMemory
]

{ #category : #become }
NewObjectMemory >> become: array1 with: array2 twoWay: twoWayFlag copyHash: copyHashFlag [
	"All references to each object in array1 are swapped with all references to the corresponding object in array2. That is, all pointers to one object are replaced with with pointers to the other. The arguments must be arrays of the same length. 
	Returns PrimNoErr if the primitive succeeds."
	"Implementation: Uses forwarding blocks to update references as done in compaction."
	| start |
	self runLeakCheckerFor: GCModeBecome.
	(self isArray: array1) ifFalse:
		[^PrimErrBadReceiver].
	((self isArray: array2)
	 and: [(self lastPointerOf: array1) = (self lastPointerOf: array2)]) ifFalse:
		[^PrimErrBadArgument].
	(twoWayFlag or: [copyHashFlag])
		ifTrue: [(self containOnlyOops: array1 and: array2) ifFalse: [^PrimErrInappropriate]]
		ifFalse: [(self containOnlyOops: array1) ifFalse: [^PrimErrInappropriate]].

	(self prepareForwardingTableForBecoming: array1 with: array2 twoWay: twoWayFlag) ifFalse:
		[^PrimErrNoMemory]. "fail; not enough space for forwarding table"

	(self allYoung: array1 and: array2)
		ifTrue: [start := youngStart"sweep only the young objects plus the roots"]
		ifFalse: [start := self startOfMemory"sweep all objects"].
	coInterpreter preBecomeAction.
	self mapPointersInObjectsFrom: start to: freeStart.
	twoWayFlag
		ifTrue: [self restoreHeadersAfterBecoming: array1 with: array2]
		ifFalse: [self restoreHeadersAfterForwardBecome: copyHashFlag].
	coInterpreter postBecomeAction: 0.

	self initializeMemoryFirstFree: freeStart. "re-initialize memory used for forwarding table"
	self runLeakCheckerFor: GCModeBecome.

	^PrimNoErr "success"
]

{ #category : #'garbage collection' }
NewObjectMemory >> biasToGrow [
	self growObjectMemory: (growHeadroom*3/2) - self freeSize
]

{ #category : #allocation }
NewObjectMemory >> bytesLeft: includingSwap [
	^self freeSize + (self sqMemoryExtraBytesLeft: includingSwap)
]

{ #category : #'primitive support' }
NewObjectMemory >> characterValueOf: oop [
	<api>
	(self isCharacterObject: oop) ifFalse:
		[coInterpreter primitiveFailFor: PrimErrUnsupported.
		 ^-1].
	^self integerValueOf: (self fetchPointer: 0 ofObject: oop)
]

{ #category : #allocation }
NewObjectMemory >> checkAllocFiller [
	<doNotGenerate>
	"in the Spur bootstrap coInterpreter may not be initialized..."
	^coInterpreter notNil and: [coInterpreter checkAllocFiller]
]

{ #category : #accessing }
NewObjectMemory >> checkForLeaks [
	^checkForLeaks
]

{ #category : #'memory access' }
NewObjectMemory >> checkHeapIntegrity [
	"Perform an integrity/leak check using the heapMap.  Assume
	 clearLeakMapAndMapAccessibleObjects has set a bit at each
	 object's header.  Scan all objects in the heap checking that every
	 pointer points to a header.  Scan the rootTable, remapBuffer and
	 extraRootTable checking that every entry is a pointer to a header.
	 Check that the number of roots is correct and that all rootTable
	 entries have their rootBit set. Answer if all checks pass."
	| ok obj sz hdr fmt fi fieldOop numRootsInHeap |
	<inline: false>
	ok := true.
	numRootsInHeap := 0.
	obj := self firstObject.
	[self oop: obj isLessThan: self startOfFreeSpace] whileTrue:
		[(self isFreeObject: obj)
			ifTrue:
				[sz := self sizeOfFree: obj]
			ifFalse:
				[hdr := self baseHeader: obj.
				 (self isYoungRootHeader: hdr) ifTrue:
					[numRootsInHeap := numRootsInHeap + 1].
				 (self compactClassIndexOfHeader: hdr) = 0 ifTrue:
					[fieldOop := (self classHeader: obj) bitAnd: AllButTypeMask.
					 ((self isIntegerObject: fieldOop)
					   or: [(heapMap heapMapAtWord: (self pointerForOop: fieldOop)) = 0]) ifTrue:
						[self print: 'object leak in '; printHex: obj; print: ' class = '; printHex: fieldOop; cr.
						 self eek.
						 ok := false]].
				 fmt := self formatOfHeader: hdr.
				 (fmt <= 4 "pointers" or: [fmt >= 12 "compiled method"]) ifTrue:
					[fmt >= 12
						ifTrue: [fi := (self literalCountOf: obj) + LiteralStart]
						ifFalse: [(fmt = 3 and: [self isContextHeader: hdr])
									ifTrue: [fi := CtxtTempFrameStart + (coInterpreter fetchStackPointerOf: obj)]
									ifFalse: [fi := self lengthOf: obj]].
					[(fi := fi - 1) >= 0] whileTrue:
						[fieldOop := self fetchPointer: fi ofObject: obj.
						 (self isNonIntegerObject: fieldOop) ifTrue:
							[(fieldOop bitAnd: self wordSize - 1) ~= 0
								ifTrue:
									[self print: 'misaligned oop in '; printHex: obj; print: ' @ '; printNum: fi; print: ' = '; printHex: fieldOop; cr.
									 self eek.
									 ok := false]
								ifFalse:
									[(heapMap heapMapAtWord: (self pointerForOop: fieldOop)) = 0 ifTrue:
										[self print: 'object leak in '; printHex: obj; print: ' @ '; printNum: fi; print: ' = '; printHex: fieldOop; cr.
										 self eek.
										 ok := false]]]]].
				 sz := self sizeBitsOf: obj].
		 obj := self oopFromChunk: obj + sz].
	numRootsInHeap ~= rootTableCount ifTrue:
		[self print: 'root count mismatch. #heap roots '; printNum: numRootsInHeap; print: '; #roots '; printNum: rootTableCount; cr.
		"But the system copes with overflow..."
		ok := rootTableOverflowed and: [needGCFlag]].
	1 to: rootTableCount do:
		[:ri|
		obj := rootTable at: ri.
		(obj bitAnd: self wordSize - 1) ~= 0
			ifTrue:
				[self print: 'misaligned oop in rootTable @ '; printNum: ri; print: ' = '; printHex: obj; cr.
				 self eek.
				 ok := false]
			ifFalse:
				[(heapMap heapMapAtWord: (self pointerForOop: obj)) = 0
					ifTrue:
						[self print: 'object leak in rootTable @ '; printNum: ri; print: ' = '; printHex: obj; cr.
						 self eek.
						 ok := false]
					ifFalse:
						[hdr := self baseHeader: obj.
						 (self isYoungRootHeader: hdr) ifFalse:
							[self print: 'non-root in rootTable @ '; printNum: ri; print: ' = '; printHex: obj; cr.
							 self eek.
							 ok := false]]]].
	1 to: remapBufferCount do:
		[:ri|
		obj := remapBuffer at: ri.
		(obj bitAnd: self wordSize - 1) ~= 0
			ifTrue:
				[self print: 'misaligned remapRoot @ '; printNum: ri; print: ' = '; printHex: obj; cr.
				 self eek.
				 ok := false]
			ifFalse:
				[(heapMap heapMapAtWord: (self pointerForOop: obj)) = 0
					ifTrue:
						[self print: 'object leak in remapRoots @ '; printNum: ri; print: ' = '; printHex: obj; cr.
						 self eek.
						 ok := false]]].
	1 to: extraRootCount do:
		[:ri|
		obj := (extraRoots at: ri) at: 0.
		(obj bitAnd: self wordSize - 1) ~= 0
			ifTrue:
				[self print: 'misaligned extraRoot @ '; printNum: ri; print: ' => '; printHex: obj; cr.
				 self eek.
				 ok := false]
			ifFalse:
				[(heapMap heapMapAtWord: (self pointerForOop: obj)) = 0
					ifTrue:
						[self print: 'object leak in extraRoots @ '; printNum: ri; print: ' => '; printHex: obj; cr.
						 self eek.
						 ok := false]]].
	^ok
]

{ #category : #'debug support' }
NewObjectMemory >> checkOkayOop: oop [
	"Verify that the given oop is legitimate. Check address, header, and size but not class.
	 Answer true if OK.  Otherwise print reason and answer false."

	<api>
	<var: #oop type: #usqInt>
	| sz type fmt unusedBit |

	"address and size checks"
	(self isIntegerObject: oop) ifTrue: [ ^true ].
	((self oop: oop isGreaterThanOrEqualTo: self startOfMemory) and: [self oop: oop isLessThan: freeStart])
		ifFalse: [ self print: 'oop '; printHex: oop; print: ' is not a valid address'; cr. ^false ].
	((oop \\ self wordSize) = 0)
		ifFalse: [ self print: 'oop '; printHex: oop; print: ' is not a word-aligned address'; cr. ^false ].
	sz := self sizeBitsOf: oop.
	(self oop: oop + sz isLessThanOrEqualTo: freeStart)
		ifFalse: [ self print: 'oop '; printHex: oop; print: ' size would make it extend beyond the end of memory'; cr. ^false ].

	"header type checks"
	type := self headerType: oop.
	type = HeaderTypeFree
		ifTrue:  [ self print: 'oop '; printHex: oop; print: ' is a free chunk, not an object'; cr. ^false ].
	type = HeaderTypeShort ifTrue: [
		(self compactClassIndexOf: oop) = 0
			ifTrue:  [ self print: 'oop '; printHex: oop; print: ' cannot have zero compact class field in a short header'; cr. ^false ].
	].
	type = HeaderTypeClass ifTrue: [
		((oop >= self wordSize) and: [(self headerType: oop - self wordSize) = type])
			ifFalse: [ self print: 'oop '; printHex: oop; print: ' class header word has wrong type'; cr. ^false ].
	].
	type = HeaderTypeSizeAndClass ifTrue: [
		((oop >= (self wordSize*2)) and:
		 [(self headerType: oop - (self wordSize*2)) = type and:
		 [(self headerType: oop - self wordSize) = type]])
			ifFalse: [ self print: 'oop '; printHex: oop; print: ' class header word has wrong type'; cr. ^false ].
	].

	"format check"
	fmt := self formatOf: oop.
	((fmt = 5) | (fmt = 7))
		ifTrue:  [ self print: 'oop '; printHex: oop; print: ' has an unknown format type'; cr. ^false ].

	"mark and root bit checks"
	unusedBit := 16r20000000.
	self wordSize = 8
		ifTrue:
			[unusedBit := unusedBit << 16.
			 unusedBit := unusedBit << 16].
	((self longAt: oop) bitAnd: unusedBit) = 0
		ifFalse: [ self print: 'oop '; printHex: oop; print: ' unused header bit 30 is set; should be zero'; cr. ^false ].
"xxx
	((self longAt: oop) bitAnd: MarkBit) = 0
		ifFalse: [ self print: 'mark bit should not be set except during GC' ].
xxx"
	((self isYoungRoot: oop) and: [oop >= youngStart])
		ifTrue: [ self print: 'oop '; printHex: oop; print: ' root bit is set in a young object'; cr. ^false ].
	^true

]

{ #category : #'debug support' }
NewObjectMemory >> checkOopIntegrity: obj named: name [
	<inline: false>
	<var: #name type: #'char *'>
	(heapMap heapMapAtWord: (self pointerForOop: obj)) ~= 0 ifTrue:
		[^true].
	coInterpreter print: name; print: ' leak '; printHex: obj; cr.
	^false
]

{ #category : #'cog jit support' }
NewObjectMemory >> classFieldOffset [
	<api>
	<cmacro: '() (0 - BaseHeaderSize)'>
	^0 - self baseHeaderSize
]

{ #category : #'interpreter access' }
NewObjectMemory >> classForClassTag: classObj [
	"Compatibility with SpurObjectMemory.  In ObjectMemory there is no distinction between a
	 classTag in the first-level method cache and a class itself."
	^classObj
]

{ #category : #'interpreter access' }
NewObjectMemory >> classTagForClass: classObj [
	"Compatibility with SpurObjectMemory.  In ObjectMemory there is no distinction between a
	 classTag in the first-level method cache and a class itself."
	^classObj
]

{ #category : #'interpreter access' }
NewObjectMemory >> classTagForSpecialObjectsIndex: splObjIndex compactClassIndex: compactClassIndex [
	"For compatibility with Spur.  Answer the class tag to use to lookup a method in the
	 first-level method lookup cache."
	^self splObj: splObjIndex
]

{ #category : #'debug support' }
NewObjectMemory >> clearLeakMapAndMapAccessibleObjects [
	"Perform an integrity/leak check using the heapMap.  Set a bit at each object's header."
	| obj sz nextHeader |
	<inline: false>
	<var: #obj type: #usqInt>
	<var: #sz type: #usqInt>
	<var: #nextHeader type: #usqInt>
	heapMap clearHeapMap.
	obj := self firstObject.
	[self oop: obj isLessThan: freeStart] whileTrue:
		[(self isFreeObject: obj)
			ifTrue:
				[sz := self sizeOfFree: obj]
			ifFalse:
				[heapMap heapMapAtWord: (self pointerForOop: obj) Put: 1.
				 sz := self sizeBitsOf: obj].
		nextHeader := obj + sz.
		obj := self oopFromChunk: nextHeader].
]

{ #category : #allocation }
NewObjectMemory >> clone: obj [
	"Return a shallow copy of the given object. May cause GC.
	 Assume: Oop is a real object, not a small integer.
	 Override to assert it's not a married context and maybe fix cloned methods."
	| extraHdrBytes bytes newChunk remappedOop fromIndex toIndex lastFrom newOop header hash |
	<inline: false>
	<var: #lastFrom type: #usqInt>
	<var: #fromIndex type: #usqInt>
	self assert: ((self isContext: obj) not
				or: [(coInterpreter isMarriedOrWidowedContext: obj) not]). 

	self assert: (self isNonIntegerObject: obj).
	extraHdrBytes := self extraHeaderBytes: obj.
	bytes := self sizeBitsOf: obj.
	bytes := bytes + extraHdrBytes.

	"allocate space for the copy, remapping obj in case of a GC"
	self pushRemappableOop: obj.
	"check it is safe to allocate this much memory. Return 0 if not"
	(self sufficientSpaceToAllocate: 2500 + bytes) ifFalse:[^0].
	newChunk := self allocateChunk: bytes.
	remappedOop := self popRemappableOop.

	"copy old to new including all header words"
	toIndex := newChunk - self wordSize.  "loop below uses pre-increment"
	fromIndex := (remappedOop - extraHdrBytes) - self wordSize.
	lastFrom := fromIndex + bytes.
	[fromIndex < lastFrom] whileTrue:
		[self longAt: (toIndex := toIndex + self wordSize)
			put: (self longAt: (fromIndex := fromIndex + self wordSize))].
	newOop := newChunk + extraHdrBytes.  "convert from chunk to oop"

	"fix base header: compute new hash and clear Mark and Root bits"
	hash := self newObjectHash.
	header := (self longAt: newOop) bitAnd: 16r1FFFF.
	"use old ccIndex, format, size, and header-type fields"
	header := header bitOr: ((hash << HashBitsOffset) bitAnd: HashBits).
	self longAt: newOop put: header.
	(self isCompiledMethodHeader: header) ifTrue:
		[coInterpreter maybeFixClonedCompiledMethod: newOop].
	^newOop

]

{ #category : #'cog jit support' }
NewObjectMemory >> compactClassFieldWidth [
	<api>
	<cmacro>
	^5
]

{ #category : #'interpreter access' }
NewObjectMemory >> dbgFloatValueOf: oop [
	"Answer the C double precision floating point value of the argument,
	 or if it is not, answer 0."

	| isFloat result |
	<returnTypeC: #double>
	<var: #result type: #double>
	isFloat := self isFloatInstance: oop.
	isFloat ifTrue:
		[self cCode: '' inSmalltalk: [result := Float new: 2].
		 self fetchFloatAt: oop + self baseHeaderSize into: result.
		 ^result].
	^0.0
]

{ #category : #'interpreter access' }
NewObjectMemory >> decrementFullGCLock [
	self assert: fullGCLock > 0.
	(fullGCLock := fullGCLock - 1) < 0 ifTrue:
		[fullGCLock := 0]
]

{ #category : #initialization }
NewObjectMemory >> defaultEdenBytes [
	"Return the default amount of memory to allocate before doing a scavenge (incremental GC).
	 This default suits Qwaq Forums (specifically loading).  The actual value can be set via
	 vmParameterAt: and/or a preference in the ini file."
	<inline: false>
	^2 * 1024 * 1024
]

{ #category : #accessing }
NewObjectMemory >> edenBytes [
	^edenBytes
]

{ #category : #accessing }
NewObjectMemory >> edenBytes: aValue [
	^edenBytes := aValue
]

{ #category : #allocation }
NewObjectMemory >> eeAllocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize [
	"Allocate a new object of the given size and number of header words. (Note: byteSize already includes
	 space for the base header word.) Initialize the header fields of the new object.
	 Does *not* initialize the objects' fields. Will *not* cause a GC.  This version is for the execution engine's use only."

	| newObj |
	<inline: true>
	newObj := self allocateInterpreterChunk: byteSize + (hdrSize - 1 * self wordSize).
	newObj = 0 ifTrue: [^newObj].
	hdrSize = 3 ifTrue:
		[self longAt: newObj put: (extendedSize bitOr: HeaderTypeSizeAndClass).
		 self longAt: newObj + self wordSize put: (classOop bitOr: HeaderTypeSizeAndClass).
		 self longAt: newObj + (self wordSize*2) put: (baseHeader bitOr: HeaderTypeSizeAndClass).
		 newObj := newObj + (self wordSize*2)].

	 hdrSize = 2 ifTrue:
		[self longAt: newObj put: (classOop bitOr: HeaderTypeClass).
		 self longAt: newObj + self wordSize put: (baseHeader bitOr: HeaderTypeClass).
		 newObj := newObj + self wordSize].

	 hdrSize = 1 ifTrue:
		[self longAt: newObj put: (baseHeader bitOr: HeaderTypeShort)].

	DoExpensiveAssertionChecks ifTrue:
		[self okayOop: newObj.
		 self oopHasOkayClass: newObj.
		 (self safeObjectAfter: newObj) = freeStart ifFalse:
			[self error: 'allocate bug: did not set header of new oop correctly']].

	^newObj
]

{ #category : #allocation }
NewObjectMemory >> eeAllocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill format: format [
	"Allocate a new object of the given size and number of header words. (Note: byteSize already includes
	 space for the base header word.) Initialize the header fields of the new object and fill the remainder of
	 the object with the given value.  Will not cause a GC.  This version is for the execution engine"

	| newObj |
	<inline: true>
	<var: #i type: 'usqInt'>
	<var: #end type: 'usqInt'>
	newObj := self allocateInterpreterChunk: byteSize + (hdrSize - 1 * self wordSize).
	newObj = 0 ifTrue: [^newObj].
	hdrSize = 3 ifTrue:
		[self longAt: newObj put: (extendedSize bitOr: HeaderTypeSizeAndClass).
		 self longAt: newObj + self wordSize put: (classOop bitOr: HeaderTypeSizeAndClass).
		 self longAt: newObj + (self wordSize*2) put: (baseHeader bitOr: HeaderTypeSizeAndClass).
		 newObj := newObj + (self wordSize*2)].

	 hdrSize = 2 ifTrue:
		[self longAt: newObj put: (classOop bitOr: HeaderTypeClass).
		 self longAt: newObj + self wordSize put: (baseHeader bitOr: HeaderTypeClass).
		 newObj := newObj + self wordSize].

	 hdrSize = 1 ifTrue:
		[self longAt: newObj put: (baseHeader bitOr: HeaderTypeShort)].

	"clear new object"
	doFill ifTrue:
		[| fillWord end i |
		 fillWord := format <= self lastPointerFormat
					ifTrue: [nilObj] "if pointers, fill with nil oop"
					ifFalse: [0].
		 end := newObj + byteSize.
		 i := newObj + self wordSize.
		 [i < end] whileTrue:
			[self longAt: i put: fillWord.
			 i := i + self wordSize]].

	DoExpensiveAssertionChecks ifTrue:
		[self okayOop: newObj.
		 self oopHasOkayClass: newObj.
		 (self safeObjectAfter: newObj) = freeStart ifFalse:
			[self error: 'allocate bug: did not set header of new oop correctly']].

	^newObj
]

{ #category : #'interpreter access' }
NewObjectMemory >> eeInstantiateAndInitializeClass: classPointer indexableSize: size [ 
	"NOTE: This method supports the backward-compatible split instSize field of the 
	 class format word. The sizeHiBits will go away and other shifts change by 2 
	 when the split fields get merged in an (incompatible) image change.
	 Will *not* cause a GC.  The instantiated object is initialized."

	| hash header1 header2 cClass byteSize format binc header3 hdrSize sizeHiBits bm1 classFormat |
	<inline: false>
	"cannot have a negative indexable field count"
	self assert: size >= 0.
	hash := self newObjectHash.
	classFormat := self formatOfClass: classPointer.
	"Low 2 bits are 0"
	header1 := (classFormat bitAnd: 16r1FF00) bitOr: (hash bitAnd: HashMaskUnshifted) << HashBitsOffset.
	header2 := classPointer.
	header3 := 0.
	sizeHiBits := (classFormat bitAnd: 16r60000) >> 9.
	cClass := header1 bitAnd: CompactClassMask. "compact class field from format word"
	byteSize := (classFormat bitAnd: SizeMask + Size4Bit) + sizeHiBits.
		"size in bytes -- low 2 bits are 0"
	"Note this byteSize comes from the format word of the class which is pre-shifted
		to 4 bytes per field.  Need another shift for 8 bytes per word..."
	byteSize := byteSize << (self shiftForWord-2).
	format := self formatOfHeader: classFormat.
	self flag: #sizeLowBits.
	format < self firstByteFormat
		ifTrue:
			[format = self firstLongFormat
				ifTrue: "long32 bitmaps"
					[bm1 := self wordSize-1.
					byteSize := byteSize + (size * 4) + bm1 bitAnd: LongSizeMask. "round up"
					binc := bm1 - ((size * 4) + bm1 bitAnd: bm1). "odd bytes"
					"extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
					header1 := header1 bitOr: (binc bitAnd: 4)]
				ifFalse: "Arrays and 64-bit bitmaps"
					[byteSize := byteSize + (size * self wordSize)]]
		ifFalse:
			["Strings and Methods"
			bm1 := self wordSize-1.
			byteSize := byteSize + size + bm1 bitAnd: LongSizeMask. "round up"
			binc := bm1 - (size + bm1 bitAnd: bm1). "odd bytes"
			"low bits of byte size go in format field"
			header1 := header1 bitOr: (binc bitAnd: 3) << self instFormatFieldLSB.
			"extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
			header1 := header1 bitOr: (binc bitAnd: 4)].
	byteSize > 255
		ifTrue: "requires size header word"
			[header3 := byteSize.
			header1 := header1]
		ifFalse: [header1 := header1 bitOr: byteSize].
	hdrSize := header3 > 0
					ifTrue: [3] "requires full header"
					ifFalse: [cClass = 0 ifTrue: [2] ifFalse: [1]].
	^self eeAllocate: byteSize headerSize: hdrSize h1: header1 h2: header2 h3: header3 doFill: true format: format
]

{ #category : #'interpreter access' }
NewObjectMemory >> eeInstantiateClass: classPointer indexableSize: size [ 
	"NOTE: This method supports the backward-compatible split instSize field of the 
	 class format word. The sizeHiBits will go away and other shifts change by 2 
	 when the split fields get merged in an (incompatible) image change.
	 Will *not* cause a GC.
	 Note that the instantiated object IS NOT FILLED and must be completed before
	 returning it to Smalltalk. Since this call is used in routines that do just that we are
	 safe.  Break this rule and die."
	<api>
	| hash header1 header2 cClass byteSize format binc header3 hdrSize sizeHiBits bm1 classFormat |
	<inline: false>
	"cannot have a negative indexable field count"
	self assert: size >= 0.
	hash := self newObjectHash.
	classFormat := self formatOfClass: classPointer.
	"Low 2 bits are 0"
	header1 := (classFormat bitAnd: 16r1FF00) bitOr: (hash bitAnd: HashMaskUnshifted) << HashBitsOffset.
	header2 := classPointer.
	header3 := 0.
	sizeHiBits := (classFormat bitAnd: 16r60000) >> 9.
	cClass := header1 bitAnd: CompactClassMask. "compact class field from format word"
	byteSize := (classFormat bitAnd: SizeMask + Size4Bit) + sizeHiBits.
		"size in bytes -- low 2 bits are 0"
	"Note this byteSize comes from the format word of the class which is pre-shifted
		to 4 bytes per field.  Need another shift for 8 bytes per word..."
	byteSize := byteSize << (self shiftForWord-2).
	format := self formatOfHeader: classFormat.
	self flag: #sizeLowBits.
	format < self firstByteFormat
		ifTrue:
			[format = self firstLongFormat
				ifTrue: "long32 bitmaps"
					[bm1 := self wordSize-1.
					byteSize := byteSize + (size * 4) + bm1 bitAnd: LongSizeMask. "round up"
					binc := bm1 - ((size * 4) + bm1 bitAnd: bm1). "odd bytes"
					"extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
					header1 := header1 bitOr: (binc bitAnd: 4)]
				ifFalse: "Arrays and 64-bit bitmaps"
					[byteSize := byteSize + (size * self wordSize)]]
		ifFalse:
			["Strings and Methods"
			bm1 := self wordSize-1.
			byteSize := byteSize + size + bm1 bitAnd: LongSizeMask. "round up"
			binc := bm1 - (size + bm1 bitAnd: bm1). "odd bytes"
			"low bits of byte size go in format field"
			header1 := header1 bitOr: (binc bitAnd: 3) << self instFormatFieldLSB.
			"extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
			header1 := header1 bitOr: (binc bitAnd: 4)].
	byteSize > 255
		ifTrue: "requires size header word"
			[header3 := byteSize.
			header1 := header1]
		ifFalse: [header1 := header1 bitOr: byteSize].
	hdrSize := header3 > 0
					ifTrue: [3] "requires full header"
					ifFalse: [cClass = 0 ifTrue: [2] ifFalse: [1]].
	^self eeAllocate: byteSize headerSize: hdrSize h1: header1 h2: header2 h3: header3
]

{ #category : #'interpreter access' }
NewObjectMemory >> eeInstantiateClassIndex: compactClassIndex format: objFormat numSlots: numSlots [
	"Instantiate an instance of a compact class.  ee stands for execution engine and
	 implies that this allocation will *NOT* cause a GC.  N.B. the instantiated object
	 IS NOT FILLED and must be completed before returning it to Smalltalk. Since this
	 call is used in routines that do just that we are safe.  Break this rule and die in GC.
	 Result is guaranteed to be young."
	<api>
	| hash header1 header2 byteSize header3 hdrSize |
	<inline: false>
	"cannot have a negative indexable field count"
	self assert: (numSlots >= 0 and: [compactClassIndex ~= 0]).
	self assert: (objFormat < self firstByteFormat
					ifTrue: [objFormat]
					ifFalse: [objFormat bitAnd: self byteFormatMask])
				= (self instSpecOfClass: (self compactClassAt: compactClassIndex)).
	hash := self newObjectHash.
	"Low 2 bits are 0"
	header1 := (objFormat << self instFormatFieldLSB
					bitOr: compactClassIndex << 12)
					bitOr: (hash bitAnd: HashMaskUnshifted) << HashBitsOffset.
	self assert: "sizeHiBits" ((self formatOfClass: (self compactClassAt: compactClassIndex)) bitAnd: 16r60000) >> 9 = 0.
	self flag: #sizeLowBits.
	"size in bytes -- low 2 bits are 0; may need another shift if 64-bits.
	 strangely, size includes size of header, but only of single header.
	 why include header size at all?  gives us an extra word."
	byteSize := numSlots << (self shiftForWord + (self shiftForWord-2)) + self baseHeaderSize.
	(self wordSize = 8 "David, please check this!!"
	 and: [objFormat >= self firstLongFormat "32-bit longs and byte objects"
	 and: [(numSlots bitAnd: 1) ~= 0]]) ifTrue:
		["extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
		 header1 := header1 bitOr: 4].
	byteSize > 255 "requires size header word/full header"
		ifTrue: [header3 := byteSize. hdrSize := 3. header2 := self compactClassAt: compactClassIndex]
		ifFalse: [header1 := header1 bitOr: byteSize. hdrSize := 1].
	^self eeAllocate: byteSize headerSize: hdrSize h1: header1 h2: header2 h3: header3
]

{ #category : #'interpreter access' }
NewObjectMemory >> eeInstantiateMethodContextSlots: numSlots [ 
	"This version of instantiateClass assumes that the total object 
	 size is under 256 bytes, the limit for objects with only one or 
	 two header words. Note that the size is specified in bytes 
	 and should include four bytes for the base header word.
	 Will *not* cause a GC. Result is guaranteed to be young."
	| sizeInBytes hash header1 |
	self assert: (numSlots = SmallContextSlots or: [numSlots = LargeContextSlots]).
	sizeInBytes := numSlots * self bytesPerOop + self baseHeaderSize.
	self assert: sizeInBytes <= SizeMask.
	hash := self newObjectHash.
	header1 := (hash bitAnd: HashMaskUnshifted) << HashBitsOffset bitOr: self formatOfMethodContextMinusSize.
	self assert: (header1 bitAnd: CompactClassMask) > 0. "contexts must be compact"
	self assert: (header1 bitAnd: SizeMask) = 0.
	"OR size into header1.  Must not do this if size > SizeMask"
	header1 := header1 + sizeInBytes.
	^self eeAllocate: sizeInBytes headerSize: 1 h1: header1 h2: nil h3: nil
]

{ #category : #'interpreter access' }
NewObjectMemory >> eeInstantiateSmallClass: classPointer numSlots: numSlots [
	"This version of instantiateClass assumes that the total object size is under
	 256 bytes, the limit for objects with only one or two header words. 
	 NOTE this code will only work for sizes that are an integral number of words
		(hence not a 32-bit LargeInteger in a 64-bit system).
	 Note that the created small object IS NOT FILLED and must be completed before returning it to Squeak.
	 Since this call is used in routines that do just that we are safe. Break this rule and die in GC.
	 Will *not* cause a GC. Result is guaranteed to be young."

	| sizeInBytes hash header1 header2 hdrSize |
	sizeInBytes := numSlots << self shiftForWord + self baseHeaderSize.
	self assert: sizeInBytes <= 252.
	hash := self newObjectHash.
	header1 := (hash bitAnd: HashMaskUnshifted) << HashBitsOffset bitOr: (self formatOfClass: classPointer).
	header2 := classPointer.
	hdrSize := (header1 bitAnd: CompactClassMask) > 0 "is this a compact class"
				ifTrue: [1]
				ifFalse: [2].
	header1 := header1 + (sizeInBytes - (header1 bitAnd: SizeMask+Size4Bit)).
	^self eeAllocate: sizeInBytes headerSize: hdrSize h1: header1 h2: header2 h3: 0
]

{ #category : #'interpreter access' }
NewObjectMemory >> eeInstantiateSmallClassIndex: compactClassIndex format: objFormat numSlots: numSlots [
	"This version of instantiateClass assumes that the total object size is under
	 256 bytes, the limit for objects with only one or two header words. 
	 NOTE this code will only work for sizes that are an integral number of words
		(hence not a 32-bit LargeInteger in a 64-bit system).
	 Note that the created small object IS NOT FILLED and must be completed before returning it to Squeak.
	 Since this call is used in routines that do just that we are safe. Break this rule and die in GC.
	 Will *not* cause a GC. Result is guaranteed to be young."

	| sizeInBytes hash header1 |
	"cannot have a negative indexable field count"
	self assert: (numSlots >= 0 and: [compactClassIndex ~= 0]).
	self assert: (objFormat < self firstByteFormat
					ifTrue: [objFormat]
					ifFalse: [objFormat bitAnd: self byteFormatMask])
				= (self instSpecOfClass: (self compactClassAt: compactClassIndex)).
	sizeInBytes := numSlots << self shiftForWord + self baseHeaderSize.
	self assert: sizeInBytes <= 252.
	hash := self newObjectHash.
	header1 := (objFormat << self instFormatFieldLSB
					bitOr: compactClassIndex << 12)
					bitOr: (hash bitAnd: HashMaskUnshifted) << HashBitsOffset.
	header1 := header1 + (sizeInBytes - (header1 bitAnd: SizeMask+Size4Bit)).
	^self eeAllocate: sizeInBytes headerSize: 1 h1: header1 h2: 0 h3: 0
]

{ #category : #'memory access' }
NewObjectMemory >> eek [
	<inline: true>
]

{ #category : #accessing }
NewObjectMemory >> falseObject: anOop [
	"For mapInterpreterOops"
	falseObj := anOop
]

{ #category : #'interpreter access' }
NewObjectMemory >> fetchClassTagOf: oop [
	"Compatibility with SpurObjectMemory.  In ObjectMemory there is no distinction between a
	 classTag in the first-level method cache and a class itself."
	^self fetchClassOf: oop
]

{ #category : #'interpreter access' }
NewObjectMemory >> fetchClassTagOfNonImm: oop [
	"Compatibility with SpurObjectMemory.  In ObjectMemory there is no distinction between a
	 classTag in the first-level method cache and a class itself."
	^self fetchClassOfNonImm: oop
]

{ #category : #'debug support' }
NewObjectMemory >> findString: aCString [
	"Print the oops of all string-like things that have the same characters as aCString"
	<api>
	<var: #aCString type: #'char *'>
	| cssz obj sz |
	cssz := self strlen: aCString.
	obj := self firstObject.
	[self oop: obj isLessThan: freeStart] whileTrue:
		[(self isFreeObject: obj)
			ifTrue:
				[sz := self sizeOfFree: obj]
			ifFalse:
				[((self isBytesNonImm: obj)
				  and: [(self lengthOf: obj) = cssz
				  and: [(self str: aCString n: (self pointerForOop: obj + self baseHeaderSize) cmp: cssz) = 0]]) ifTrue:
					[coInterpreter printHex: obj; space; printOopShort: obj; cr].
				 sz := self sizeBitsOf: obj].
		 obj := self oopFromChunk: obj + sz]
]

{ #category : #'debug support' }
NewObjectMemory >> findStringBeginningWith: aCString [
	"Print the oops of all string-like things that start with the same characters as aCString"
	<api>
	<var: #aCString type: #'char *'>
	| cssz obj sz |
	cssz := self strlen: aCString.
	obj := self firstObject.
	[self oop: obj isLessThan: freeStart] whileTrue:
		[(self isFreeObject: obj)
			ifTrue:
				[sz := self sizeOfFree: obj]
			ifFalse:
				[((self isBytesNonImm: obj)
				  and: [(self lengthOf: obj) >= cssz
				  and: [(self str: aCString n: (self pointerForOop: obj + self baseHeaderSize) cmp: cssz) = 0]]) ifTrue:
					[coInterpreter printHex: obj; space; printNum: (self lengthOf: obj); space; printOopShort: obj; cr].
				 sz := self sizeBitsOf: obj].
		 obj := self oopFromChunk: obj + sz]
]

{ #category : #'object enumeration' }
NewObjectMemory >> firstAccessibleObject [
	"Return the first accessible object in the heap."
	| obj |
	obj := self firstObject.
	[self oop: obj isLessThan: freeStart] whileTrue:
		[(self isFreeObject: obj) ifFalse: [^obj].
		 obj := self objectAfter: obj].
	self error: 'heap is empty'.
	^nil
]

{ #category : #'indexing primitive support' }
NewObjectMemory >> firstValidIndexOfIndexableObject: obj withFormat: fmt [
	"Answer the one-relative index of the first valid index in an indexbale object
	 with the given format.  This is 1 for all objects except compiled methods
	 where the first index is beyond the last literal.
	 Used for safer bounds-checking on methods."
	^fmt >= self firstCompiledMethodFormat
		ifTrue: [coInterpreter firstByteIndexOfMethod: obj]
		ifFalse: [1]
]

{ #category : #'interpreter access' }
NewObjectMemory >> floatObjectOf: aFloat [
	| newFloatObj |
	<inline: false>
	<var: #aFloat type: #double>
	newFloatObj := self
						eeInstantiateSmallClassIndex: ClassFloatCompactIndex
						format: self firstLongFormat
						numSlots: (self sizeof: #double) / self bytesPerOop.
	self storeFloatAt: newFloatObj + self baseHeaderSize from: aFloat.
	^newFloatObj
]

{ #category : #'interpreter access' }
NewObjectMemory >> floatValueOf: oop [
	"Answer the C double precision floating point value of the argument,
	 or fail if it is not a Float, and answer 0.
	 Note: May be called by translated primitive code."

	| isFloat result |
	<returnTypeC: #double>
	<var: #result type: #double>
	isFloat := self isFloatInstance: oop.
	isFloat ifTrue:
		[self cCode: '' inSmalltalk: [result := Float new: 2].
		 self fetchFloatAt: oop + self baseHeaderSize into: result.
		 ^result].
	coInterpreter primitiveFail.
	^0.0
]

{ #category : #'frame access' }
NewObjectMemory >> formatOfMethodContext [
	"Answer the class format word for MethodContext which is used to instantiate
	 contexts without needing to fetch it from the class MethodContext itself."
	^(ClassMethodContextCompactIndex << 12)
	+ (self indexablePointersFormat << self instFormatFieldLSB) "Pointers+Variable"
	+ (CtxtTempFrameStart + (self baseHeaderSize / self wordSize) << 2)
]

{ #category : #'frame access' }
NewObjectMemory >> formatOfMethodContextMinusSize [
	"Answer the class format word for MethodContext which is used to instantiate
	 contexts without needing to fetch it from the class MethodContext itself."
	^(ClassMethodContextCompactIndex << 12)
	+ (self indexablePointersFormat << self instFormatFieldLSB) "Pointers+Variable"
]

{ #category : #become }
NewObjectMemory >> freeObject: obj header: objHeader [
	(self isContextHeader: objHeader) ifTrue:
		[(self asserta: ((coInterpreter isStillMarriedContext: obj) not)) ifFalse:
			[self error: 'attempt to free married context']].
	super freeObject: obj header: objHeader
]

{ #category : #allocation }
NewObjectMemory >> freeSize [
	"Return the instantaneous amount of free memory which is that
	 from the allocation pointer freeStart up to the reserve start."
	^(self oop: freeStart isLessThan: reserveStart)
		ifTrue: [(self cCoerce: reserveStart to: #usqInt) - (self cCoerce: freeStart to: #usqInt)]
		ifFalse: [0]
]

{ #category : #accessing }
NewObjectMemory >> freeStart [
	"This is a horrible hack and only works because C macros are generated after Interpreter variables."
	<cmacro: '() GIV(freeStart)'>
	^freeStart
]

{ #category : #'garbage collection' }
NewObjectMemory >> fullCompaction [
	"Move all accessible objects down to leave one big free chunk at the end of memory.
	 Assume:
		Incremental GC has just been done to maximimize forwarding table space.
		sweepPhaseForFullGC has already set compStart.
	 Need not and can not move objects below the first free chunk."
	| sz |
	self assert: compStart = (self lowestFreeAfter: self startOfMemory).
	compStart = freeStart ifTrue:
		["memory is already compact; only free chunk is at the end "
		 ^self initializeMemoryFirstFree: freeStart].
	(sz := self fwdTableSize: 8) < totalObjectCount ifTrue:
		["Try to grow OM to make a single pass full GC"
		 self growObjectMemory: totalObjectCount - sz + 10000 * 8].
	"work up through memory until all free space is at the end"
	[compStart < freeStart] whileTrue:
		["free chunk returned by incCompBody becomes start of next compaction"
		 compStart := self incCompBody]
]

{ #category : #'garbage collection' }
NewObjectMemory >> fullGC [
	"Do a mark/sweep garbage collection of the entire object memory.
	 Free inaccessible objects but do not move them."

	<inline: false>
	fullGCLock > 0 ifTrue:
		[self warning: 'aborting fullGC because fullGCLock > 0'.
		 ^self].
	self runLeakCheckerFor: GCModeFull.
	self preGCAction: GCModeFull.
	needGCFlag := false.
	gcStartUsecs := self ioUTCMicrosecondsNow.
	statSweepCount := statMarkCount := statMkFwdCount := statCompMoveCount := 0.
	self clearRootsTable.
	self initWeakTableForIncrementalGC: false.
	youngStart := self startOfMemory.  "process all of memory"
	self markPhase: true.
	"Sweep phase returns the number of survivors.
	Use the up-to-date version instead the one from startup."
	totalObjectCount := self sweepPhaseForFullGC.
	self runLeakCheckerFor: GCModeFull.
	self fullCompaction.
	statFullGCs := statFullGCs + 1.
	statGCEndUsecs := self ioUTCMicrosecondsNow.
	statFullGCUsecs := statFullGCUsecs + (statGCEndUsecs - gcStartUsecs).
	self capturePendingFinalizationSignals.

	youngStart := freeStart.  "reset the young object boundary"
	self attemptToShrink.
	self postGCAction: GCModeFull.
	self runLeakCheckerFor: GCModeFull
]

{ #category : #accessing }
NewObjectMemory >> fullGCLock [
	^fullGCLock
]

{ #category : #'gc -- compaction' }
NewObjectMemory >> fwdTableInit: blkSize [
	"Set the limits for a table of two- or three-word forwarding blocks above the last used oop. The pointer fwdTableNext moves up to fwdTableLast. Used for compaction of memory and become-ing objects. Returns the number of forwarding blocks available."

	<inline: false>
	"set endOfMemory to just after a minimum-sized free block"
	self setSizeOfFree: freeStart to: self baseHeaderSize.
	self setEndOfMemory: freeStart + self baseHeaderSize.

	"make a fake free chunk at endOfMemory for use as a sentinal in memory scans"
	self setSizeOfFree: endOfMemory to: self baseHeaderSize.

	"use all memory free between freeStart and memoryLimit for forwarding table"
	"Note: Forward blocks must be quadword aligned."
	fwdTableNext := (endOfMemory + self baseHeaderSize + 7) bitAnd: WordMask-7.
	self flag: #Dan.  "Above line does not do what it says (quadword is 16 or 32 bytes)"

	fwdTableLast := memoryLimit - blkSize.  "last forwarding table entry"

	"return the number of forwarding blocks available"
	^(fwdTableLast - fwdTableNext) // blkSize  "round down"
]

{ #category : #'gc -- compaction' }
NewObjectMemory >> fwdTableSize: blkSize [
	"Estimate the number of forwarding blocks available for compaction"
	| eom fwdFirst fwdLast |
	<inline: false>

	eom := freeStart + self baseHeaderSize.
	"use all memory free between freeStart and memoryLimit for forwarding table"

	"Note: Forward blocks must be quadword aligned."
	fwdFirst := (eom + self baseHeaderSize + 7) bitAnd: WordMask-7.
	self flag: #Dan.  "Above line does not do what it says (quadword is 16 or 32 bytes)"

	fwdLast := memoryLimit - blkSize.  "last forwarding table entry"

	"return the number of forwarding blocks available"
	^ (fwdLast - fwdFirst) // blkSize  "round down"
]

{ #category : #allocation }
NewObjectMemory >> growObjectMemory: delta [ 
	"Attempt to grow the object memory by the given delta amount."
	| limit |
	statGrowMemory := statGrowMemory + 1.
	limit := self sqGrowMemory: memoryLimit By: delta.
	limit = memoryLimit ifFalse:
		[self setMemoryLimit: limit - 24. "remove a tad for safety"
		 self initializeMemoryFirstFree: freeStart]
]

{ #category : #'debug support' }
NewObjectMemory >> heapMap [
	^heapMap
]

{ #category : #'image segment in/out' }
NewObjectMemory >> imageSegmentVersion [
	| wholeWord |
	"a more complex version that tells both the word reversal and the endianness of the machine it came from.  Low half of word is 6502.  Top byte is top byte of #doesNotUnderstand: on this machine. ($d on the Mac or $s on the PC)"

	wholeWord := self longAt: (self splObj: SelectorDoesNotUnderstand) + self baseHeaderSize.
		"first data word, 'does' "
	^coInterpreter imageFormatVersion bitOr: (wholeWord bitAnd: 16rFF000000)
]

{ #category : #snapshot }
NewObjectMemory >> imageSizeToWrite [
	"Answer the number of bytes that will be written to
	 the image file in a snapshot, excluding the header."
	^freeStart - self startOfMemory
]

{ #category : #accessing }
NewObjectMemory >> inGC [
	^gcStartUsecs > statGCEndUsecs
]

{ #category : #'gc -- compaction' }
NewObjectMemory >> incCompBody [
	"Move objects to consolidate free space into one big chunk. Return the newly created free chunk."

	| bytesToBeFreed |
	<inline: false>
	"reserve memory for forwarding table"
	self fwdTableInit: self wordSize*2.  "Two-word blocks"

	"assign new oop locations, reverse their headers, and initialize forwarding blocks"
	bytesToBeFreed := self incCompMakeFwd.

	"update pointers to point at new oops"
	self mapPointersInObjectsFrom: youngStart to: freeStart.

	"move the objects and restore their original headers; return the new free chunk"
	^self incCompMove: bytesToBeFreed
]

{ #category : #'gc -- compaction' }
NewObjectMemory >> incCompMakeFwd [
	"Create and initialize forwarding blocks for all non-free objects  
	 following compStart. If the supply of forwarding blocks is exhausted,  
	 set compEnd to the first chunk above the area to be compacted;
	 otherwise, set it to endOfMemory. Return the number of bytes to be freed."
	| bytesToBeFreed oop fwdBlock newOop |
	<inline: false>
	bytesToBeFreed := 0.
	oop := self oopFromChunk: compStart.
	self assert: (self oop: oop isGreaterThan: self startOfMemory andLessThan: freeStart).
	[self oop: oop isLessThan: freeStart] whileTrue:
		[statMkFwdCount := statMkFwdCount + 1.
		 self assert: (self oop: oop isGreaterThan: self startOfMemory andLessThan: freeStart).
		 (self isFreeObject: oop)
			ifTrue: [bytesToBeFreed := bytesToBeFreed + (self sizeOfFree: oop)]
			ifFalse: "create a forwarding block for oop"
				[fwdBlock := self fwdBlockGet: self wordSize*2.
				 "Two-word block"
				 fwdBlock = nil ifTrue: "stop; we have used all available forwarding blocks"
					[compEnd := self chunkFromOop: oop.
					 ^bytesToBeFreed].
				newOop := oop - bytesToBeFreed.
				self assert: (self oop: newOop isGreaterThan: self startOfMemory andLessThan: freeStart).
				self initForwardBlock: fwdBlock mapping: oop to: newOop withBackPtr: false].
			oop := self objectAfterWhileForwarding: oop].
	compEnd := freeStart.
	^bytesToBeFreed
]

{ #category : #'gc -- compaction' }
NewObjectMemory >> incCompMove: bytesFreed [
	"Move all non-free objects between compStart and compEnd to their new  
	locations, restoring their headers in the process. Create a new free  
	block at the end of memory. Return the newly created free chunk. "
	"Note: The free block used by the allocator always must be the last free  
	block in memory. It may take several compaction passes to make all  
	free space bubble up to the end of memory."
	| oop next fwdBlock newOop header bytesToMove firstWord lastWord newFreeChunk sz target |
	<inline: false>
	<var: #firstWord type: 'usqInt'>
	<var: #lastWord type: 'usqInt'>
	<var: #w type: 'usqInt'>
	newOop := nil.
	oop := self oopFromChunk: compStart.
	[self oop: oop isLessThan: compEnd] whileTrue:
		[statCompMoveCount := statCompMoveCount + 1.
		next := self objectAfterWhileForwarding: oop.
		(self isFreeObject: oop) ifFalse:
			["a moving object; unwind its forwarding block"
			fwdBlock := self forwardingPointerOf: oop.
			self assert: (self fwdBlockValid: fwdBlock).
			newOop := self longAt: fwdBlock.
			header := self longAt: fwdBlock + self wordSize.
			self longAt: oop put: header. "restore the original header"
			bytesToMove := oop - newOop. "move the oop (including any extra header words) "
			sz := self sizeBitsOf: oop.
			firstWord := oop - (self extraHeaderBytes: oop).
			lastWord := oop + sz - self baseHeaderSize.
			target := firstWord - bytesToMove.
			firstWord to: lastWord by: self wordSize do:
				[:w | 
				self longAt: target put: (self longAt: w).
				target := target + self wordSize]].
		oop := next].
	newOop = nil
		ifTrue: ["no objects moved"
			oop := self oopFromChunk: compStart.
			((self isFreeObject: oop) and: [(self objectAfter: oop) = (self oopFromChunk: compEnd)])
				ifTrue: [newFreeChunk := oop]
				ifFalse: [newFreeChunk := freeStart]]
		ifFalse: ["initialize the newly freed memory chunk"
			"newOop is the last object moved; free chunk starts right after it"
			newFreeChunk := newOop + (self sizeBitsOf: newOop).
			self setSizeOfFree: newFreeChunk to: bytesFreed].
	next := self safeObjectAfter: newFreeChunk.
	self assert: (next = freeStart or: [next = (self oopFromChunk: compEnd)]).
	next = freeStart
		ifTrue: [self initializeMemoryFirstFree: newFreeChunk]
		ifFalse: ["newFreeChunk is not at end of memory; re-install freeStart.
				 This will be the case when a compaction needs more than one pass."
			self initializeMemoryFirstFree: freeStart].
	^newFreeChunk
]

{ #category : #'interpreter access' }
NewObjectMemory >> incrementFullGCLock [
	fullGCLock := fullGCLock + 1
]

{ #category : #'garbage collection' }
NewObjectMemory >> incrementalCompaction [
	"Move objects down to make one big free chunk. Compact the 
	last N objects (where N = number of forwarding table 
	entries) of the young object area."
	"Assume: compStart was set during the sweep phase"
	compStart = freeStart
		ifTrue: ["Note: If compStart = freeStart then either the young 
			space is already compact  or there are enough forwarding table entries to do a 
			one-pass incr. compaction."
			self initializeMemoryFirstFree: freeStart]
		ifFalse: [self incCompBody]
]

{ #category : #'garbage collection' }
NewObjectMemory >> incrementalGC [
	"Do a mark/sweep garbage collection of just the young object
	area of object memory (i.e., objects above youngStart), using
	the root table to identify objects containing pointers to
	young objects from the old object area."
	| survivorCount weDidGrow |
	<inline: false>

	rootTableOverflowed ifTrue:
		["root table overflow; cannot do an incremental GC because some roots are missing.
		 (this should be very rare)"
		 statRootTableOverflows := statRootTableOverflows + 1.
		 ^self fullGC].
	self runLeakCheckerFor: GCModeNewSpace.
	coInterpreter preGCAction: GCModeNewSpace.
	needGCFlag := false.
	gcStartUsecs := self ioUTCMicrosecondsNow.
	statSweepCount := statMarkCount := statMkFwdCount := statCompMoveCount := 0.
	self initWeakTableForIncrementalGC: true.
	"implicitly process memory from youngStart to freeStart"
	self markPhase: false.
	self assert: weakRootCount <= WeakRootTableSize.
	1 to: weakRootCount do:
		[:i| self finalizeReference: (weakRoots at: i)].
	survivorCount := self sweepPhase.
	self runLeakCheckerFor: GCModeNewSpace.
	self incrementalCompaction.
	statIncrGCs := statIncrGCs + 1.
	statGCEndUsecs := self ioUTCMicrosecondsNow.
	statIGCDeltaUsecs := statGCEndUsecs - gcStartUsecs.
	statIncrGCUsecs := statIncrGCUsecs + statIGCDeltaUsecs.
	self capturePendingFinalizationSignals.
	
	statRootTableCount  := rootTableCount.
	statSurvivorCount := survivorCount.
	weDidGrow := false.
	(((survivorCount > tenuringThreshold)
	 or: [rootTableCount >= RootTableRedZone])
	 or: [forceTenureFlag == true]) ifTrue:
		["move up the young space boundary if
		  * there are too many survivors:
			this limits the number of objects that must be
			processed on future incremental GC's
		  * we're about to overflow the roots table:
			this limits the number of full GCs that may be caused
			by root table overflows in the near future"
		forceTenureFlag := false.
		statTenures := statTenures + 1.
		self clearRootsTable.
		((self freeSize < growHeadroom)
		 and: [gcBiasToGrow > 0]) ifTrue:
			[self biasToGrow.
			 weDidGrow := true].
		youngStart := freeStart].
	self attemptToShrink.
	coInterpreter postGCAction: GCModeNewSpace.
	
	self runLeakCheckerFor: GCModeNewSpace.
	weDidGrow ifTrue:
		[self biasToGrowCheckGCLimit]
]

{ #category : #'gc -- compaction' }
NewObjectMemory >> initForwardBlock: fwdBlock mapping: objOop to: newOop withBackPtr: backFlag [
	"Initialize the given forwarding block to map oop to newOop, 
	and replace oop's header with a pointer to the fowarding block."
	"Details: The mark bit is used to indicate that an oop is 
	forwarded. When an oop is forwarded, its header (minus the 
	mark bit) contains the address of its forwarding block. (The 
	forwarding block address is actually shifted right by one bit 
	so that its top-most bit does not conflict with the header's 
	mark bit; since fowarding blocks are stored on word 
	boundaries, the low two bits of the address are always zero.) 
	The first word of the forwarding block is the new oop; the 
	second word is the oop's orginal header. In the case of a 
	forward become, a four-word block is used, with the third 
	field being a backpointer to the old oop (for header fixup), 
	and the fourth word is unused. The type bits of the 
	forwarding header are the same as those of the original 
	header. "
	| originalHeader originalHeaderType |
	<inline: true>
	self assert: fwdBlock ~= nil. "ran out of forwarding blocks in become"
	self deny: (self hasForwardingBlock: objOop). "'object already has a forwarding table entry"
	originalHeader := self longAt: objOop.
	originalHeaderType := originalHeader bitAnd: TypeMask.
	self longAt: fwdBlock put: newOop.
	self longAt: fwdBlock + self wordSize put: originalHeader.
	backFlag ifTrue: [self longAt: fwdBlock + (self wordSize*2) put: objOop].
	self longAt: objOop put: (fwdBlock >> 1 bitOr: (MarkBit bitOr: originalHeaderType))
]

{ #category : #initialization }
NewObjectMemory >> initialize [
	<doNotGenerate>
	"Initialize NewObjectMemory when simulating the VM inside Smalltalk."
	super initialize.
	checkForLeaks := fullGCLock := 0.
	needGCFlag := false.
	heapMap := CogCheck32BitHeapMap new
]

{ #category : #initialization }
NewObjectMemory >> initializeMemoryFirstFree: firstFree [ 
	"Initialize endOfMemory to the top of oop storage space, reserving some space
	 for forwarding blocks, and set freeStart from which space is allocated."
	"Note: The amount of space reserved for forwarding blocks should be chosen to
	  ensure that incremental compactions can usually be done in a single pass.
	  However, there should be enough forwarding blocks so a full compaction can be done
	  in a reasonable number of passes, say ten. (A full compaction requires N object-moving
	  passes, where N = number of non-garbage objects / number of forwarding blocks).

	di 11/18/2000 Re totalObjectCount: Provide a margin of one byte per object to be
	 used for forwarding pointers at GC time. Since fwd blocks are 8 bytes, this means
	 an absolute worst case of 8 passes to compact memory. In most cases it will be
	 adequate to do compaction in a single pass. "
	| fwdBlockBytes totalReserve |
	"reserve space for forwarding blocks and the interpreter.  We can sacrifice
	 forwarding block space at the cost of slower compactions but we cannot
	 safely sacrifice interpreter allocation headroom."
	fwdBlockBytes := totalObjectCount bitAnd: WordMask - self wordSize + 1.
	totalReserve := fwdBlockBytes + self interpreterAllocationReserveBytes.
	(self oop: memoryLimit - totalReserve isLessThan: firstFree + self baseHeaderSize) ifTrue:
		["reserve enough space for a minimal free block of BaseHeaderSize bytes.
		  We are apparently in an emergency situation here because we have no space
		  for reserve and forwarding blocks.  But a full GC will occur immediately in	
		  sufficientSpaceAfterGC: which will grow memory and restore the reserve."
		 fwdBlockBytes := memoryLimit - (firstFree  + self baseHeaderSize)].

	"set endOfMemory reserveStart and freeStart"
	self setEndOfMemory: memoryLimit - fwdBlockBytes.
	reserveStart := endOfMemory - self interpreterAllocationReserveBytes.
	freeStart := firstFree. "bytes available for oops"
	scavengeThreshold := freeStart + edenBytes min: reserveStart.
	self maybeFillWithAllocationCheckFillerFrom: freeStart to: scavengeThreshold.

	self assert: (self oop: freeStart isLessThan: reserveStart).
	"We would like to assert this but can't because in GC situations it may be false.  It is
	established by sufficientSpaceToAllocate: and sufficientSpaceAfterGC:"
	false ifTrue: [self assert: (self oop: reserveStart isLessThan: endOfMemory)].
	self assert: (self oop: endOfMemory isLessThan: memoryLimit)
]

{ #category : #initialization }
NewObjectMemory >> initializeObjectMemory: bytesToShift [
	"Initialize object memory variables at startup time. Assume endOfMemory is initially set (by the image-reading code) to the end of the last object in the image. Initialization redefines endOfMemory to be the end of the object allocation area based on the total available memory, but reserving some space for forwarding blocks."
	"Assume: image reader initializes the following variables:
		memory
		endOfMemory
		memoryLimit
		specialObjectsOop
		lastHash
	"
	"di 11/18/2000 fix slow full GC"
	<inline: false>

	"set the start of the young object space"
	youngStart := freeStart := endOfMemory.

	"image may be at a different address; adjust oops for new location"
	totalObjectCount := self adjustAllOopsBy: bytesToShift.

	self initializeMemoryFirstFree: endOfMemory. "initializes endOfMemory, freeStart"

	specialObjectsOop := specialObjectsOop + bytesToShift.

	"heavily used special objects"
	nilObj	:= self splObj: NilObject.
	falseObj	:= self splObj: FalseObject.
	trueObj	:= self splObj: TrueObject.

	rootTableCount := 0.
	rootTableOverflowed := false.
	lowSpaceThreshold := 0.
	signalLowSpace := false.
	compStart := 0.
	compEnd := 0.
	fwdTableNext := 0.
	fwdTableLast := 0.
	remapBufferCount := 0.
	tenuringThreshold := 2000.  "tenure all suriving objects if survivor count is over this threshold"
	growHeadroom := 4*1024*1024. "four megabytes of headroom when growing"
	shrinkThreshold := 8*1024*1024. "eight megabytes of free space before shrinking"

	"garbage collection statistics"
	statFullGCs := 0.
	statFullGCUsecs := 0.
	statIncrGCs := 0.
	statIncrGCUsecs := 0.
	statTenures := 0.
	statRootTableOverflows := 0.
	statGrowMemory := 0.
	statShrinkMemory := 0.
	forceTenureFlag := 0.
	gcBiasToGrow := 0.
	gcBiasToGrowGCLimit := 0.
	extraRootCount := 0.

]

{ #category : #'cog jit support' }
NewObjectMemory >> instFormatFieldLSB [
	<api>
	<cmacro>
	^8
]

{ #category : #'cog jit support' }
NewObjectMemory >> instFormatFieldWidth [
	<api>
	<cmacro>
	^4
]

{ #category : #accessing }
NewObjectMemory >> interpreter [
	<doNotGenerate>
	^coInterpreter
]

{ #category : #'internal interpreter access' }
NewObjectMemory >> isContextHeader: aHeader [
	<inline: true>
	"c.f. {BlockContext. MethodContext. PseudoContext} collect: [:class| class -> class indexIfCompact]"
	^(self compactClassIndexOfHeader: aHeader) = ClassMethodContextCompactIndex
]

{ #category : #'image segment in/out' }
NewObjectMemory >> isPlatformFloatOrderVersion: imageVersion [
	"Answer if floats are stored in the platform's float order for the given imageVersion.
	 Prior to this version they were always in big-endian (e.g. PowerPC) format."
	^imageVersion >= 6505
]

{ #category : #'memory access' }
NewObjectMemory >> isYoungObject: obj [
	<api>
	"Answer if obj is young. Assume obj is non-immediate."
	self assert: (self isNonImmediate: obj).
	^self oop: obj isGreaterThanOrEqualTo: youngStart
]

{ #category : #'object enumeration' }
NewObjectMemory >> lastPointerOf: objOop [ 
	"Return the byte offset of the last pointer field of the given object.  
	 Can be used even when the type bits are not correct.
	 Works with CompiledMethods, as well as ordinary objects."
	<api>
	<inline: true>
	| fmt header contextSize |
	header := self baseHeader: objOop.
	fmt := self formatOfHeader: header.
	fmt <= self lastPointerFormat ifTrue:
		[(fmt = self indexablePointersFormat
		  and: [self isContextHeader: header]) ifTrue:
			["contexts end at the stack pointer"
			contextSize := coInterpreter fetchStackPointerOf: objOop.
			^CtxtTempFrameStart + contextSize * self bytesPerOop].
		^(self sizeBitsOfSafe: objOop) - self baseHeaderSize  "all pointers"].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	header := self methodHeaderOf: objOop.
	^self lastPointerOfMethodHeader: header
]

{ #category : #'object enumeration' }
NewObjectMemory >> lastPointerOf: objOop recordWeakRoot: recordWeakRoot [ "<Boolean>"
	"Return the byte offset of the last pointer field of the given object.  
	 Works with CompiledMethods, as well as ordinary objects. 
	 Can be used even when the type bits are not correct.
	 This is a version of lastPointerOf: for markAndTrace:.
	 Already overridden to trace stack pages for the StackInterpreter.
	 Override to ask coInterpreter to determine literalCount of methods."
	| fmt sz header contextSize numOops |
	<inline: true>
	header := self baseHeader: objOop.
	fmt := self formatOfHeader: header.
	fmt <= self lastPointerFormat ifTrue:
		[fmt >= self indexablePointersFormat ifTrue:
			[fmt = self lastPointerFormat ifTrue:
				[(recordWeakRoot and: [weakRootCount >= 0]) ifTrue:
					["And remember as weak root"
					 (weakRootCount := weakRootCount + 1) <= WeakRootTableSize ifFalse:
						[self error: 'weakRoots table overflow'].
					 weakRoots at: weakRootCount put: objOop].
				"Do not trace the object's indexed fields if it's a weak class"
				numOops := self nonWeakFieldsOf: objOop. "so nonWeakFieldsOf: may be inlined"
				^numOops * self wordSize].
			"So fmt is 3"
			(self isContextHeader: header) ifTrue:
				[coInterpreter setTraceFlagOnContextsFramesPageIfNeeded: objOop.
				 "contexts end at the stack pointer avoiding having to init fields beyond it"
				 contextSize := coInterpreter fetchStackPointerOf: objOop.
				 self assert: ReceiverIndex + contextSize < (self lengthOf: objOop baseHeader: header format: fmt).
				 ^CtxtTempFrameStart + contextSize * self bytesPerOop]].
		 sz := self sizeBitsOfSafe: objOop.
		 ^sz - self baseHeaderSize  "all pointers" ].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	header := self methodHeaderOf: objOop.
	^self lastPointerOfMethodHeader: header
]

{ #category : #'object enumeration' }
NewObjectMemory >> lastPointerOfMethodHeader: methodHeader [ 
	"Answer the byte offset of the last pointer field of a
	 CompiledMethod with the given header.  Use a temp to
	 allow inlining given MULTIPLEBYTECODESETS complications."
	<inline: true>
	| numLiterals |
	numLiterals := self literalCountOfMethodHeader: methodHeader.
	^numLiterals + LiteralStart - 1 * self bytesPerOop + self baseHeaderSize
]

{ #category : #'gc -- compaction' }
NewObjectMemory >> lastPointerWhileForwarding: objOop [ 
	"The given object may have its header word in a forwarding block. Find  
	 the offset of the last pointer in the object in spite of this obstacle."
	| header fmt size contextSize |
	<inline: true>
	header := self headerWhileForwardingOf: objOop.
	fmt := self formatOfHeader: header.
	fmt <= self lastPointerFormat ifTrue:
		[(fmt = self indexablePointersFormat
		  and: [self isContextHeader: header]) ifTrue:
			["contexts end at the stack pointer"
			 contextSize := coInterpreter nacFetchStackPointerOf: objOop.
			 self assert: ReceiverIndex + contextSize < (self lengthOf: objOop baseHeader: header format: fmt).
			 ^CtxtTempFrameStart + contextSize * self bytesPerOop].
		 "do sizeBitsOf: using the header we obtained"
		 size := (header bitAnd: TypeMask) = HeaderTypeSizeAndClass
					ifTrue: [(self sizeHeader: objOop) bitAnd: AllButTypeMask]
					ifFalse: [header bitAnd: SizeMask].
		 ^size - self baseHeaderSize].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"
	"CompiledMethod: contains both pointers and bytes"
	self assert: (self isCompiledMethodHeader: header).
	header := self noCheckMethodHeaderOf: objOop.
	^self lastPointerOfMethodHeader: header
]

{ #category : #'debug support' }
NewObjectMemory >> leakCheckBecome [
	<api>
	^(checkForLeaks bitAnd: GCModeBecome) ~= 0
]

{ #category : #'debug support' }
NewObjectMemory >> leakCheckFullGC [
	<api>
	^(checkForLeaks bitAnd: GCModeFull) ~= 0
]

{ #category : #'debug support' }
NewObjectMemory >> leakCheckNewSpaceGC [
	<api>
	^(checkForLeaks bitAnd: 2) ~= 0
]

{ #category : #'memory access' }
NewObjectMemory >> literalCountOfMethodHeader: methodHeader [
	<api>
	<inline: true>
	self assert: (self isIntegerObject: methodHeader).
	^(self headerIndicatesAlternateBytecodeSet: methodHeader)
		ifTrue: [coInterpreter literalCountOfAlternateHeader: methodHeader]
		ifFalse: [coInterpreter literalCountOfOriginalHeader: methodHeader]
]

{ #category : #'image segment in/out' }
NewObjectMemory >> loadImageSegmentFrom: segmentWordArray outPointers: outPointerArray [
	"This primitive is called from Squeak as...
		<imageSegment> loadSegmentFrom: aWordArray outPointers: anArray."

"This primitive will load a binary image segment created by primitiveStoreImageSegment.  It expects the outPointer array to be of the proper size, and the wordArray to be well formed.  It will return as its value the original array of roots, and the erstwhile segmentWordArray will have been truncated to a size of one word, i.e. retaining the version stamp.  If this primitive should fail, the segmentWordArray will, sadly, have been reduced to an unrecognizable and unusable jumble.  But what more could you have done with it anyway?"

	| endSeg segOop fieldPtr fieldOop doingClass lastPtr extraSize mapOop lastOut outPtr hdrTypeBits header data |
	<inline: false>
	<var: #endSeg type: #usqInt>
	<var: #segOop type: #usqInt>
	<var: #fieldPtr type: #usqInt>
	<var: #lastOut type: #usqInt>
	<var: #outPtr type: #usqInt>
	<var: #lastPtr type: #usqInt>

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	lastOut := outPointerArray + (self lastPointerOf: outPointerArray).
	endSeg := segmentWordArray + (self sizeBitsOf: segmentWordArray) - self baseHeaderSize.

	"Version check.  Byte order of the WordArray now"
	data := self longAt: segmentWordArray + self baseHeaderSize.
	(coInterpreter readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse:
		"Not readable -- try again with reversed bytes..."
		[self reverseBytesFrom: segmentWordArray + self baseHeaderSize to: endSeg + self wordSize.
		data := self longAt: segmentWordArray + self baseHeaderSize.
		(coInterpreter readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse:
			"Still NG -- put things back and fail"
			[self reverseBytesFrom: segmentWordArray + self baseHeaderSize to: endSeg + self wordSize.
			DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^PrimErrBadArgument]].
	"Reverse the Byte type objects if the data is from opposite endian machine.
	 Revese the words in Floats if from an earlier version with different Float order.
	 Test top byte.  $d on the Mac or $s on the PC.  Rest of word is equal."
	(data >> 16) = (self imageSegmentVersion >> 16)
		ifTrue:
			"Need to swap floats if the segment is being loaded into a little-endian VM from a version
			 that keeps Floats in big-endian word order as was the case prior to the 6505 image format."
			[(self isPlatformFloatOrderVersion: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse:
				[self vmEndianness ~= 1 "~= 1 => little-endian" ifTrue:
					[segOop := self oopFromChunk: segmentWordArray + self baseHeaderSize + self wordSize.
					 self wordSwapFloatsFrom: segOop to: endSeg + self wordSize]]]
		ifFalse: "Reverse the byte-type objects once"
			[segOop := self oopFromChunk: segmentWordArray + self baseHeaderSize + self wordSize.
				 "Oop of first embedded object"
			self byteSwapByteObjectsFrom: segOop
				to: endSeg + self wordSize
				flipFloatsIf: (self isPlatformFloatOrderVersion: (data bitAnd: 16rFFFF "low 2 bytes"))].

	"Proceed through the segment, remapping pointers..."
	segOop := self oopFromChunk: segmentWordArray + self baseHeaderSize + self wordSize.
	[segOop <= endSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type = 0 or 1) -- start with that."
					fieldPtr := segOop - self wordSize.  doingClass := true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr := segOop + self baseHeaderSize.  doingClass := false].
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"
		lastPtr > endSeg ifTrue:
			[DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^PrimErrBadIndex "out of bounds"].

		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop := self longAt: fieldPtr.
			doingClass ifTrue:
				[hdrTypeBits := self headerType: fieldPtr.
				fieldOop := fieldOop - hdrTypeBits].
			(self isIntegerObject: fieldOop)
				ifTrue:
					["Integer -- nothing to do"
					fieldPtr := fieldPtr + self wordSize]
				ifFalse:
					[(fieldOop bitAnd: 3) = 0 ifFalse:
						[^PrimErrBadIndex "bad oop"].
					(fieldOop bitAnd: 16r80000000) = 0
						ifTrue: ["Internal pointer -- add segment offset"
								mapOop := fieldOop + segmentWordArray]
						ifFalse: ["External pointer -- look it up in outPointers"
								outPtr := outPointerArray + (fieldOop bitAnd: 16r7FFFFFFF).
								outPtr > lastOut ifTrue:
									[^PrimErrBadIndex "out of bounds"].
								mapOop := self longAt: outPtr].
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr := fieldPtr + 8.
								doingClass := false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr := fieldPtr + self wordSize].
					segOop < youngStart ifTrue:
						[self possibleRootStoreInto: segOop value: mapOop]]].
		segOop := self objectAfter: segOop].

	"Again, proceed through the segment checking consistency..."
	segOop := self oopFromChunk: segmentWordArray + self baseHeaderSize + self wordSize.
	[segOop <= endSeg] whileTrue:
		[(self oopHasAcceptableClass: segOop) ifFalse:
			[^PrimErrInappropriate "inconsistency"].
		fieldPtr := segOop + self baseHeaderSize.		"first field"
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"
		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop := self longAt: fieldPtr.
			(self oopHasAcceptableClass: fieldOop) ifFalse:
				[^PrimErrInappropriate "inconsistency"].
			fieldPtr := fieldPtr + self wordSize].
		segOop := self objectAfter: segOop].

	"Truncate the segment word array to size = BytesPerWord (vers stamp only)"
	extraSize := self extraHeaderBytes: segmentWordArray.
	hdrTypeBits := self headerType: segmentWordArray.
	extraSize = 8
		ifTrue: [self longAt: segmentWordArray-extraSize put: self baseHeaderSize + self wordSize + hdrTypeBits]
		ifFalse: [header := self longAt: segmentWordArray.
				self longAt: segmentWordArray
					put: header - (header bitAnd: SizeMask) + self baseHeaderSize + self wordSize].	
	"and return the roots array which was first in the segment"
	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	^self oopFromChunk: segmentWordArray + self baseHeaderSize + self wordSize
]

{ #category : #'debug printing' }
NewObjectMemory >> longPrintReferencesTo: anOop [
	"Scan the heap long printing the oops of any and all objects that refer to anOop"
	| oop i prntObj |
	<api>
	prntObj := false.
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[((self isPointersNonImm: oop) or: [self isCompiledMethod: oop]) ifTrue:
			[(self isCompiledMethod: oop)
				ifTrue:
					[i := (self literalCountOf: oop) + LiteralStart]
				ifFalse:
					[(self isContextNonImm: oop)
						ifTrue: [i := CtxtTempFrameStart + (coInterpreter fetchStackPointerOf: oop)]
						ifFalse: [i := self lengthOf: oop]].
			[(i := i - 1) >= 0] whileTrue:
				[anOop = (self fetchPointer: i ofObject: oop) ifTrue:
					[self printHex: oop; print: ' @ '; printNum: i; cr.
					 prntObj := true.
					 i := 0]].
			prntObj ifTrue:
				[prntObj := false.
				 coInterpreter longPrintOop: oop]].
		 oop := self accessibleObjectAfter: oop]
]

{ #category : #simulation }
NewObjectMemory >> lookupAddress: address [
	"If address appears to be that of a Symbol or a few well-known objects (such as classes) answer it, otherwise answer nil.
	 For code disassembly"
	<doNotGenerate>
	| fmt size string class classSize maybeThisClass classNameIndex thisClassIndex |
	(self addressCouldBeObj: address) ifFalse:
		[^nil].
	fmt := self formatOf: address.
	size := self lengthOf: address baseHeader: (self baseHeader: address) format: fmt.
	size = 0 ifTrue:
		[^address caseOf: { [nilObj] -> ['nil']. [trueObj] -> ['true']. [falseObj] -> ['false'] } otherwise: []].
	((fmt between: 8 and: 11) "indexable byte fields"
	and: [(size between: 1 and: 64)
	and: [Scanner isLiteralSymbol: (string := (0 to: size - 1) collect: [:i| Character value: (self fetchByte: i ofObject: address)])]]) ifTrue:
		[^'#', (ByteString withAll: string)].
	class := self fetchClassOfNonImm: address.
	((self addressCouldBeObj: class)
	 and: [(self headerType: class) ~= HeaderTypeShort]) ifFalse:
		[^nil].
	"address is either a class or a metaclass, or an instance of a class or invalid.  determine which."
	classNameIndex := coInterpreter classNameIndex.
	thisClassIndex := coInterpreter thisClassIndex.
	((classSize := self lengthOf: class baseHeader: (self baseHeader: address) format: fmt) <= (classNameIndex max: thisClassIndex)
	 or: [classSize > 255]) ifTrue:
		[^nil].
	"Address could be a class or a metaclass"
	(fmt = 1 and: [size >= classNameIndex]) ifTrue:
		["Is address a class? If so class's thisClass is address."
		 (self lookupAddress: (self fetchPointer: classNameIndex ofObject: address)) ifNotNil:
			[:maybeClassName|
			(self fetchPointer: thisClassIndex ofObject: class) = address ifTrue:
				[^maybeClassName allButFirst]].
		"Is address a Metaclass?  If so class's name is Metaclass and address's thisClass holds the class name"
		((self isBytes: (self fetchPointer: classNameIndex ofObject: class))
		 and: [(self lookupAddress: (self fetchPointer: classNameIndex ofObject: class)) = '#Metaclass'
		 and: [size >= thisClassIndex]]) ifTrue:
			[maybeThisClass := self fetchPointer: thisClassIndex ofObject: address.
			(self lookupAddress: (self fetchPointer: classNameIndex ofObject: maybeThisClass)) ifNotNil:
				[:maybeThisClassName| ^maybeThisClassName allButFirst, ' class']]].
	^(self lookupAddress: (self fetchPointer: classNameIndex ofObject: class)) ifNotNil:
		[:maybeClassName| 'a(n) ', maybeClassName allButFirst]
]

{ #category : #'gc -- compaction' }
NewObjectMemory >> mapPointersInObjectsFrom: memStart to: memEnd [
	"Use the forwarding table to update the pointers of all non-free objects in the given range of memory.
	 Also remap pointers in root objects which may contains pointers into the given memory range, and
	 don't forget to flush the method cache based on the range."
	<inline: false>
	(self shouldRemapObj: nilObj) ifTrue:
		[nilObj := self remapObj: nilObj].
	(self shouldRemapObj: falseObj) ifTrue:
		[falseObj := self remapObj: falseObj].
	(self shouldRemapObj: trueObj) ifTrue:
		[trueObj := self remapObj: trueObj].
	(self shouldRemapObj: specialObjectsOop) ifTrue:
		[specialObjectsOop := self remapObj: specialObjectsOop].
	"update interpreter variables"
	coInterpreter
		mapInterpreterOops;
		flushMethodCacheFrom: memStart to: memEnd.
	self remapRemapBufferAndExtraRoots.
	self updatePointersInRootObjectsFrom: memStart to: memEnd.
	self updatePointersInRangeFrom: memStart to: memEnd
]

{ #category : #'primitive support' }
NewObjectMemory >> mark: obj [
	<inline: true>
	self baseHeader: obj put: ((self baseHeader: obj) bitOr: MarkBit)
]

{ #category : #'gc -- mark and sweep' }
NewObjectMemory >> markPhase: fullGCFlag [
	"Mark phase of the mark and sweep garbage collector. Set 
	 the mark bits of all reachable objects. Free chunks are 
	 untouched by this process."
	"Assume: All non-free objects are initially unmarked. Root 
	 objects were unmarked when they were made roots.
	 (Make sure this stays true!!)."
	| oop statMarkCountPriorToStackPageFreeing |
	<inline: false>
	"trace the interpreter's objects, including the active stacks
	 and special objects array"
	self markAndTraceInterpreterOops: fullGCFlag.
	statSpecialMarkCount := statMarkCount.
	"trace the roots"
	1 to: rootTableCount do:
		[:i | 
		oop := rootTable at: i.
		self markAndTrace: oop].
	1 to: extraRootCount do:
		[:i|
		oop := (extraRoots at: i) at: 0.
		((self isIntegerObject: oop) or: [self isFreeObject: oop]) ifFalse:
			[self markAndTrace: oop]].
	statMarkCountPriorToStackPageFreeing := statMarkCount.
	"Only safe to free stack pages after all roots have been traced."
	self markAndTraceAndMaybeFreeStackPages: fullGCFlag.
	"Only safe to free any machine code methods after all
	 stack pages have been traced."
	self markAndTraceOrFreeMachineCode: fullGCFlag.
	statSpecialMarkCount := statSpecialMarkCount + (statMarkCount - statMarkCountPriorToStackPageFreeing)
]

{ #category : #allocation }
NewObjectMemory >> maybeFillWithAllocationCheckFillerFrom: start to: end [
	"Fill free memory with a bit pattern for checking if the last object has been overwritten."
	<inline: true>
	<var: 'start' type: #usqInt>
	<var: 'end' type: #usqInt>
	<var: 'p' type: #usqInt>
	self checkAllocFiller ifTrue:
		[start to: end by: self wordSize do:
			[:p| self longAt: p put: p]]
]

{ #category : #'interpreter access' }
NewObjectMemory >> methodCacheHashOf: selector with: classTag [
	"Since class tags are class objects, and classes are aligned on a 4 byte boundary there
	 is no need to shift the class to include the least significant bits of the class in the hash."
	<inline: true>
	^selector bitXor: classTag
]

{ #category : #'primitive support' }
NewObjectMemory >> minLargeHeaderSize [
	"Answer the smallest byte size requiring a large header."
	^256
]

{ #category : #accessing }
NewObjectMemory >> needGCFlag [
	^needGCFlag
]

{ #category : #allocation }
NewObjectMemory >> newObjectHash [
	"Derive the new object hash from the allocation pointer.  This is less costly than
	 using lastHash because it avoids the read-modify-write cycle to update lastHash.
	 Since the size of eden is a power of two and larger than the hash range this provides
	 a well-distributed and fairly random set of values."
	<inline: true>
	^freeStart >> self shiftForWord
]

{ #category : #accessing }
NewObjectMemory >> newSpaceBytes [
	^self edenBytes
]

{ #category : #accessing }
NewObjectMemory >> newSpaceSize [
	^freeStart - self startOfMemory
]

{ #category : #'primitive support' }
NewObjectMemory >> nilFieldsOf: arrayObj [ 
	0 to: (self lengthOf: arrayObj) - 1 do:
		[:i|
		self storePointerUnchecked: i ofObject: arrayObj withValue: nilObj]
]

{ #category : #accessing }
NewObjectMemory >> nilObject: anOop [
	"For mapInterpreterOops"
	nilObj := anOop
]

{ #category : #'garbage collection' }
NewObjectMemory >> noteAsRoot: oop headerLoc: headerLoc [ 
	"Record that the given oop in the old object area points to an object in the young area.
	 HeaderLoc is usually = oop, but may be an addr in a forwarding block."
	| header |
	<inline: true>
	header := self longAt: headerLoc.
	(self isYoungRootHeader: header) ifFalse:
		"record oop as root only if not already recorded"
		[rootTableCount < RootTableSize
			ifTrue:
				"record root if there is enough room in the roots table.
				 IMPORTANT: since clearRootsTable is the only thing that clears root bits
				 do *not* set the root bit unless an object is in the root table.  checking
				 routines will complain about the root bit being unset instead of the table
				 being full, but that's life"
				[rootTableCount := rootTableCount + 1.
				 rootTable at: rootTableCount put: oop.
				 self longAt: headerLoc put: (header bitOr: RootBit).
				 rootTableCount >= RootTableRedZone ifTrue:
					"if we're now in the red zone force an IGC ASAP"
					[self scheduleIncrementalGC]]
			ifFalse: "note overflow; will need to do a fullGC instead of an incremental."
				[rootTableOverflowed := true]]
]

{ #category : #'debug printing' }
NewObjectMemory >> numReferencesTo: anOop [
	"Answer the number of objects that refer to anOop, other than anOop."
	| oop i n |
	oop := self firstAccessibleObject.
	n := 0.
	[oop = nil] whileFalse:
		[((self isPointersNonImm: oop) or: [self isCompiledMethod: oop]) ifTrue:
			[(self isCompiledMethod: oop)
				ifTrue:
					[i := (self literalCountOf: oop) + LiteralStart]
				ifFalse:
					[(self isContextNonImm: oop)
						ifTrue: [i := CtxtTempFrameStart + (coInterpreter fetchStackPointerOf: oop)]
						ifFalse: [i := self lengthOf: oop]].
			[(i := i - 1) >= 0] whileTrue:
				[anOop = (self fetchPointer: i ofObject: oop) ifTrue:
					[anOop ~= oop ifTrue:
						[n := n + 1].
					 i := 0]]].
		 oop := self accessibleObjectAfter: oop].
	^n
]

{ #category : #'object enumeration' }
NewObjectMemory >> objectAfter: oop [ 
	"Return the object or free chunk immediately following the 
	given object or free chunk in memory. Return endOfMemory 
	when enumeration is complete."
	| sz |
	<api>
	<inline: true>
	(self asserta: (self oop: oop isLessThan: freeStart)) ifFalse:
		[self error: 'no objects after the end of memory'].
	(self isFreeObject: oop)
		ifTrue: [sz := self sizeOfFree: oop]
		ifFalse: [sz := self sizeBitsOf: oop].
	^self oopFromChunk: oop + sz
]

{ #category : #'debug support' }
NewObjectMemory >> okayOop: signedOop [
	"Verify that the given oop is legitimate. Check address, header, and size but not class."

	| sz type fmt unusedBit oop |
	<var: #oop type: #usqInt>
	oop := self cCoerce: signedOop to: #usqInt.

	"address and size checks"
	(self isIntegerObject: oop) ifTrue: [ ^true ].
	(oop >= self startOfMemory and: [oop < freeStart])
		ifFalse: [ self error: 'oop is not a valid address'. ^false ].
	((oop \\ self wordSize) = 0)
		ifFalse: [ self error: 'oop is not a word-aligned address'. ^false ].
	sz := self sizeBitsOf: oop.
	(oop + sz) <= freeStart
		ifFalse: [ self error: 'oop size would make it extend beyond the end of memory'. ^false ].

	"header type checks"
	type := self headerType: oop.
	type = HeaderTypeFree
		ifTrue:  [ self error: 'oop is a free chunk, not an object'. ^false ].
	type = HeaderTypeShort ifTrue: [
		(self compactClassIndexOf: oop) = 0
			ifTrue:  [ self error: 'cannot have zero compact class field in a short header'. ^false ].
	].
	type = HeaderTypeClass ifTrue: [
		((oop >= self wordSize) and: [(self headerType: oop - self wordSize) = type])
			ifFalse: [ self error: 'class header word has wrong type'. ^false ].
	].
	type = HeaderTypeSizeAndClass ifTrue: [
		((oop >= (self wordSize*2)) and:
		 [(self headerType: oop - (self wordSize*2)) = type and:
		 [(self headerType: oop - self wordSize) = type]])
			ifFalse: [ self error: 'class header word has wrong type'. ^false ].
	].

	"format check"
	fmt := self formatOf: oop.
	((fmt = 5) | (fmt = 7))
		ifTrue:  [ self error: 'oop has an unknown format type'. ^false ].

	"mark and root bit checks"
	unusedBit := 16r20000000.
	self wordSize = 8
		ifTrue:
			[unusedBit := unusedBit << 16.
			 unusedBit := unusedBit << 16].
	((self longAt: oop) bitAnd: unusedBit) = 0
		ifFalse: [ self error: 'unused header bit 30 is set; should be zero'. ^false ].
"xxx
	((self longAt: oop) bitAnd: MarkBit) = 0
		ifFalse: [ self error: 'mark bit should not be set except during GC' ].
xxx"
	((self isYoungRoot: oop) and: [oop >= youngStart])
		ifTrue: [ self error: 'root bit is set in a young object'. ^false ].
	^true

]

{ #category : #'image segment in/out' }
NewObjectMemory >> oopHasAcceptableClass: signedOop [
	"Similar to oopHasOkayClass:, except that it only returns true or false."

	| oopClass formatMask behaviorFormatBits oopFormatBits oop |
	<var: #oop type: #usqInt>
	<var: #oopClass type: #usqInt>

	(self isIntegerObject: signedOop) ifTrue: [^ true].

	oop := self cCoerce: signedOop to: #usqInt.
	(self addressCouldBeObj: oop) ifFalse: [^ false].

	oopClass := self cCoerce: (self fetchClassOfNonImm: oop) to: #usqInt.
	(self addressCouldBeObj: oopClass) ifFalse: [^ false].
	(oopClass + (self sizeBitsOf: oopClass)) <= freeStart ifFalse: [^ false].

	((self isPointersNonImm: oopClass) and: [(self lengthOf: oopClass) >= 3]) ifFalse: [^ false].

	formatMask := (self isBytesNonImm: oop)
						ifTrue: [16rC00]  "ignore extra bytes size bits"
						ifFalse: [16rF00].

	behaviorFormatBits := (self formatOfClass: oopClass) bitAnd: formatMask.
	oopFormatBits := (self baseHeader: oop) bitAnd: formatMask.
	behaviorFormatBits = oopFormatBits ifFalse: [^ false].
	^ true
]

{ #category : #'primitive support' }
NewObjectMemory >> pinObject: objOop [
	"For forward-compatibility with Spur.  Fail; ObjectMemory does not support pinning."
	<api>
	coInterpreter primitiveFailFor: PrimErrUnsupported.
	^0
]

{ #category : #become }
NewObjectMemory >> prepareForwardingTableForBecoming: array1 with: array2 twoWay: twoWayFlag [ 
	"Ensure that there are enough forwarding blocks to 
	accomodate this become, then prepare forwarding blocks for 
	the pointer swap. Return true if successful."
	"Details: Doing a GC might generate enough space for 
	forwarding blocks if we're short. However, this is an 
	uncommon enough case that it is better handled by primitive 
	fail code at the Smalltalk level."

	"Important note on multiple references to same object  - since the preparation of
	fwdBlocks is NOT idempotent we get VM crashes if the same object is referenced more
	than once in such a way as to require multiple fwdBlocks.
	oop1 forwardBecome: oop1 is ok since only a single fwdBlock is needed.
	oop1 become: oop1 would fail because the second fwdBlock woudl not have the actual object
	header but rather the mutated ref to the first fwdBlock.
	Further problems can arise with an array1 or array2 that refer multiply to the same 
	object. This would notbe expected input for programmer writen code but might arise from
	automatic usage such as in ImageSegment loading.
	To avoid the simple and rather common case of oop1 become*: oop1, we skip such pairs
	and simply avoid making fwdBlocks - it is redundant anyway"
	| entriesNeeded entriesAvailable fieldOffset oop1 oop2 fwdBlock fwdBlkSize |
	entriesNeeded := (self lastPointerOf: array1) // self wordSize. "need enough entries for all oops"
	"Note: Forward blocks must be quadword aligned - see fwdTableInit:."
	twoWayFlag
		ifTrue: ["Double the number of blocks for two-way become"
			entriesNeeded := entriesNeeded * 2.
			fwdBlkSize := self wordSize * 2]
		ifFalse: ["One-way become needs backPointers in fwd blocks."
			fwdBlkSize := self wordSize * 4].
	entriesAvailable := self fwdTableInit: fwdBlkSize.
	entriesAvailable < entriesNeeded ifTrue:
		[self initializeMemoryFirstFree: freeStart.
		 "re-initialize the free block"
		 ^false].
	fieldOffset := self lastPointerOf: array1.
	[fieldOffset >= self baseHeaderSize] whileTrue:
		[oop1 := self longAt: array1 + fieldOffset.
		 oop2 := self longAt: array2 + fieldOffset.
		 "if oop1 == oop2, no need to do any work for this pair.
		  May still be other entries in the arrays though so keep looking"
		 oop1 ~= oop2 ifTrue:
			[(self hasForwardingBlock: oop1) ifFalse: "Don't allocate multiple forwarding entries for duplicates."
				[fwdBlock := self fwdBlockGet: fwdBlkSize.
				 self
					initForwardBlock: fwdBlock
					mapping: oop1
					to: oop2
					withBackPtr: twoWayFlag not].
			 (twoWayFlag
			  and: [(self hasForwardingBlock: oop2) not]) ifTrue: "Again don't get confused by duplicates"
				["Second block maps oop2 back to oop1 for two-way become"
						fwdBlock := self fwdBlockGet: fwdBlkSize.
						self
							initForwardBlock: fwdBlock
							mapping: oop2
							to: oop1
							withBackPtr: twoWayFlag not]].
		fieldOffset := fieldOffset - self wordSize].
	^true
]

{ #category : #'debug printing' }
NewObjectMemory >> printActivationsOf: aMethodObj [
	"Scan the heap printing the oops of any and all contexts that refer to anOop"
	| oop |
	<api>
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[((self isContextNonImm: oop)
		  and: [aMethodObj = (self fetchPointer: MethodIndex ofObject: oop)]) ifTrue:
			[coInterpreter
				printHex: oop; space; printOopShort: oop; print: ' pc ';
				printHex: (self fetchPointer: InstructionPointerIndex ofObject: oop); cr].
		 oop := self accessibleObjectAfter: oop]
]

{ #category : #'debug printing' }
NewObjectMemory >> printContextReferencesTo: anOop [
	"Scan the heap printing the oops of any and all contexts that refer to anOop"
	| oop i |
	<api>
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[(self isContextNonImm: oop) ifTrue:
			[i := CtxtTempFrameStart + (coInterpreter fetchStackPointerOf: oop)].
			 [(i := i - 1) >= 0] whileTrue:
				[anOop = (self fetchPointer: i ofObject: oop) ifTrue:
					[coInterpreter
						printHex: oop; print: ' @ '; printNum: i; space; printOopShort: oop;
						print: ' pc '; printHex: (self fetchPointer: InstructionPointerIndex ofObject: oop); cr.
					 i := 0]].
		 oop := self accessibleObjectAfter: oop]
]

{ #category : #'debug printing' }
NewObjectMemory >> printHeaderTypeOf: obj [
	(self headerType: obj) caseOf: {
		[HeaderTypeFree]			-> [coInterpreter print: ' HeaderTypeFree (4 bytes)'].
		[HeaderTypeShort]			-> [coInterpreter print: ' HeaderTypeShort (4 bytes)'].
		[HeaderTypeClass]			-> [coInterpreter print: ' HeaderTypeClass (8 bytes)'].
		[HeaderTypeSizeAndClass]	-> [coInterpreter print: ' HeaderTypeSizeAndClass (12 bytes)'] }
]

{ #category : #'debug printing' }
NewObjectMemory >> printMemField: memField name: name size: length [
	<var: #memField type: #usqInt>
	<var: #name type: #'char *'>
	self print: name; tab; printHexPtr: memField asVoidPointer;
		printChar: $/; printNum: memField;
		print: ' sz: '; printHex: length.
	length ~= 0 ifTrue:
		[self printChar: $/; printNum: length].
	self cr
]

{ #category : #'debug printing' }
NewObjectMemory >> printMemory [
	self printMemField: self startOfMemory name: 'memory      ' size: youngStart - self startOfMemory.
	self printMemField: youngStart name: 'youngStart  ' size: freeStart - youngStart.
	freeStart <= scavengeThreshold
		ifTrue:
			[self printMemField: freeStart name: 'freeStart   ' size: reserveStart - freeStart.
			 self printMemField: scavengeThreshold name: 'scavenge@   ' size: scavengeThreshold-freeStart]
		ifFalse:
			[self printMemField: scavengeThreshold name: 'scavenge@   ' size: scavengeThreshold-freeStart.
			 self printMemField: freeStart name: 'freeStart   ' size: reserveStart - freeStart].
	self printMemField: reserveStart name: 'reserveStart' size: endOfMemory - reserveStart.
	self printMemField: endOfMemory name: 'endOfMemory ' size: memoryLimit - endOfMemory.
	self printMemField: memoryLimit name: 'memoryLimit ' size: 0
]

{ #category : #printing }
NewObjectMemory >> printMemoryFrom: start to: end [
	<doNotGenerate>
	| address |
	address := start bitAnd: (self wordSize - 1) bitInvert.
	[address < end] whileTrue:
		[coInterpreter printHex: address; printChar: $:; space; printHex: (self longAt: address); cr.
		 address := address + self wordSize]
]

{ #category : #'debug printing' }
NewObjectMemory >> printObjectsFrom: startAddress to: endAddress [
	<api>
	| oop |
	oop := startAddress.
	[self oop: oop isLessThan: endAddress] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[coInterpreter printOop: oop].
		oop := self objectAfter: oop].
]

{ #category : #'debug printing' }
NewObjectMemory >> printReferencesTo: anOop [
	"Scan the heap printing the oops of any and all objects that refer to anOop"
	| oop i |
	<api>
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[((self isPointersNonImm: oop) or: [self isCompiledMethod: oop]) ifTrue:
			[(self isCompiledMethod: oop)
				ifTrue:
					[i := (self literalCountOf: oop) + LiteralStart]
				ifFalse:
					[(self isContextNonImm: oop)
						ifTrue: [i := CtxtTempFrameStart + (coInterpreter fetchStackPointerOf: oop)]
						ifFalse: [i := self lengthOf: oop]].
			[(i := i - 1) >= 0] whileTrue:
				[anOop = (self fetchPointer: i ofObject: oop) ifTrue:
					[coInterpreter printHex: oop; print: ' @ '; printNum: i; space; printOopShort: oop; cr.
					 i := 0]]].
		 oop := self accessibleObjectAfter: oop]
]

{ #category : #'debug printing' }
NewObjectMemory >> printWronglySizedContexts [
	"Override.  We implement printWronglySizedContexts:"
	<doNotGenerate>
	super printWronglySizedContexts
]

{ #category : #'debug printing' }
NewObjectMemory >> printWronglySizedContexts: printContexts [
	"Scan the heap printing the oops of any and all contexts whose size is not either SmallContextSize or LargeContextSize"
	| oop |
	<api>
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[((self isContextNonImm: oop)
		   and: [self badContextSize: oop]) ifTrue:
			[self printHex: oop; space; printNum: (self numBytesOf: oop); cr.
			 printContexts ifTrue:
				[coInterpreter printContext: oop]].
		 oop := self accessibleObjectAfter: oop]
]

{ #category : #'interpreter access' }
NewObjectMemory >> rawClassTagForClass: classObj [
	"Compatibility with SpurObjectMemory.  In ObjectMemory there is no distinction between a
	 classTag in the first-level method cache and a class itself."
	^classObj
]

{ #category : #'header access' }
NewObjectMemory >> rawHashBitsOf: objOop [
	"Compatibility with Spur."
	^self hashBitsOf: objOop
]

{ #category : #become }
NewObjectMemory >> restoreHeaderOf: obj to: objHeader [
	super restoreHeaderOf: obj to: objHeader.
	(self isContextHeader: objHeader) ifTrue:
		[(self asserta: ((coInterpreter isStillMarriedContext: obj) not)) ifFalse:
			[self error: 'attempt to become married context']]
]

{ #category : #'image segment in/out' }
NewObjectMemory >> restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut [

	"Restore headers smashed by forwarding links"
	| tablePtr oop header |
	tablePtr := firstIn.
	[self oop: tablePtr isLessThanOrEqualTo: lastIn] whileTrue:
		[oop := self longAt: tablePtr.
		header := self longAt: hdrBaseIn + (tablePtr-firstIn).
		self longAt: oop put: header.
		tablePtr := tablePtr + self wordSize].
	tablePtr := firstOut.
	[self oop: tablePtr isLessThanOrEqualTo: lastOut] whileTrue:
		[oop := self longAt: tablePtr.
		header := self longAt: hdrBaseOut + (tablePtr-firstOut).
		self longAt: oop put: header.
		tablePtr := tablePtr + self wordSize].
	
	"Clear all mark bits"
	oop := self firstObject.
	[self oop: oop isLessThan: freeStart] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[self longAt: oop put: ((self longAt: oop) bitAnd: AllButMarkBit)].
		oop := self objectAfter: oop]
]

{ #category : #snapshot }
NewObjectMemory >> reverseBytesInMemory [
	self reverseBytesFrom: self startOfMemory to: freeStart
]

{ #category : #'header access' }
NewObjectMemory >> rightType: headerWord [
	"Compute the correct header type for an object based on the size and compact class fields of the given base header word, rather than its type bits. This is used during marking, when the header type bits are used to record the state of tracing."

	^(headerWord bitAnd: SizeMask) = 0  "zero size field in header word"
		ifTrue: [HeaderTypeSizeAndClass]
		ifFalse:
			[(headerWord bitAnd: CompactClassMask) = 0
				ifTrue: [HeaderTypeClass]
				ifFalse: [HeaderTypeShort]]
]

{ #category : #'debug support' }
NewObjectMemory >> runLeakCheckerFor: gcModes [
	<inline: false>
	(gcModes anyMask: checkForLeaks) ifTrue:
		[(gcModes anyMask: GCModeFull)
			ifTrue: [coInterpreter reverseDisplayFrom: 0 to: 7]
			ifFalse: [coInterpreter reverseDisplayFrom: 8 to: 15].
		 self clearLeakMapAndMapAccessibleObjects.
		 self assert: self checkHeapIntegrity.
		 self assert: coInterpreter checkInterpreterIntegrity = 0.
		 self assert: coInterpreter checkStackIntegrity.
		 self assert: (coInterpreter checkCodeIntegrity: gcModes).
		 self validate "simulation only"]
]

{ #category : #'object enumeration' }
NewObjectMemory >> safeObjectAfter: oop [ 
	"Return the object or start of free space immediately following the 
	 given object or free chunk in memory. Return freeStart when
	 enumeration is complete.  This is for assertion checking only."
	| sz |
	(self isFreeObject: oop)
		ifTrue: [sz := self sizeOfFree: oop]
		ifFalse: [sz := self sizeBitsOf: oop].
	^(oop + sz) asUnsignedInteger >= freeStart
		ifTrue: [freeStart asInteger]
		ifFalse: [self oopFromChunk: oop + sz]
]

{ #category : #'debug printing' }
NewObjectMemory >> safePrintStringOf: oop [
	"Version of printStringOf: that copes with forwarding during garbage collection."
	| fmt header cnt i |
	<inline: false>
	(self isIntegerObject: oop) ifTrue:
		[^nil].
	(self oop: oop isGreaterThanOrEqualTo: self startOfMemory andLessThan: freeStart) ifFalse:
		[^nil].
	(oop bitAnd: (self wordSize - 1)) ~= 0 ifTrue:
		[^nil].
	header := self headerWhileForwardingOf: oop.
	fmt := self formatOfHeader: header.
	fmt < 8 ifTrue: [ ^nil ].

	cnt := 100 min: (self lengthOf: oop baseHeader: header format: fmt).
	i := 0.

	[i < cnt] whileTrue:
		[self printChar: (self fetchByte: i ofObject: oop).
		 i := i + 1].
	coInterpreter flush.
	^oop
]

{ #category : #accessing }
NewObjectMemory >> scavengeThreshold [
	^scavengeThreshold
]

{ #category : #'garbage collection' }
NewObjectMemory >> scheduleIncrementalGC [
	needGCFlag := true.
	coInterpreter forceInterruptCheck
]

{ #category : #'debug support' }
NewObjectMemory >> setCheckForLeaks: integerFlags [
	"0 = do nothing.
	 1 = check for leaks on fullGC.
	 2 = check for leaks on incrementalGC.
	 8 = check for leaks on become"
	checkForLeaks := integerFlags
]

{ #category : #initialization }
NewObjectMemory >> setEndOfMemory: newEndOfMemory [
	super setEndOfMemory: newEndOfMemory.
	freeStart isNil ifTrue:
		[freeStart := newEndOfMemory]
]

{ #category : #allocation }
NewObjectMemory >> shorten: obj toIndexableSize: nSlots [
	"Reduce the number of indexable fields in obj, a pointer object, to nSlots. Convert the
	unused residual to a free chunk. Word and byte indexable objects are not changed.
	Answer the number of bytes returned to free memory, which may be zero if no change
	was possible."
	| deltaBytes desiredLength fixedFields fmt hdr totalLength
	 indexableFields |
	<api>
	(self isPointersNonImm: obj) ifFalse: [^0].
	nSlots >  0
		ifFalse: [^0]. "no change if nSlots is zero, error if nSlots is negative"
	hdr := self baseHeader: obj.
	fmt := self formatOfHeader: hdr.
	totalLength := self lengthOf: obj baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: obj format: fmt length: totalLength.
	indexableFields := totalLength - fixedFields.
	nSlots >= indexableFields
		ifTrue: [^0]. "no change, or error if attempting to increase size into next chunk"
	desiredLength := fixedFields + nSlots.		
	deltaBytes := (totalLength - desiredLength) * self wordSize.
	obj + self baseHeaderSize + (totalLength * self wordSize) = freeStart
		ifTrue: "Shortening the last object.  Need to reduce freeStart."
			[self maybeFillWithAllocationCheckFillerFrom: obj + self baseHeaderSize + (desiredLength * self wordSize) to: freeStart.
			freeStart := obj + self baseHeaderSize + (desiredLength * self wordSize)]
		ifFalse: "Shortening some interior object.  Need to create a free block."
			[self setSizeOfFree: obj + self baseHeaderSize + (desiredLength * self wordSize)
				to: deltaBytes].
	(self headerType: obj) caseOf:	{
		[HeaderTypeSizeAndClass] ->
			[self longAt: (obj - (self baseHeaderSize * 2)) put: (self sizeHeader: obj) - deltaBytes].
		[HeaderTypeClass] ->
			[self longAt: obj put: ((hdr bitClear: SizeMask) bitOr: (hdr bitAnd: SizeMask) - deltaBytes)].
		[HeaderTypeShort] ->
			[self longAt: obj put: ((hdr bitClear: SizeMask) bitOr: (hdr bitAnd: SizeMask) - deltaBytes)] }.
	^deltaBytes
]

{ #category : #allocation }
NewObjectMemory >> shrinkObjectMemory: delta [ 
	"Attempt to shrink the object memory by the given delta 
	amount "
	| limit |
	statShrinkMemory := statShrinkMemory + 1. 
	limit := self sqShrinkMemory: memoryLimit By: delta.
	limit = memoryLimit ifFalse:
		[self setMemoryLimit: limit - 24. "remove a tad for safety"
		 self initializeMemoryFirstFree: freeStart]
]

{ #category : #'object access' }
NewObjectMemory >> sizeBitsOf: oop [
	"Answer the number of bytes in the given object, including its base header, rounded up to an integral number of words."
	"Note: byte indexable objects need to have low bits subtracted from this size."
	<inline: true>
	| header |
	header := self baseHeader: oop.
	^(header bitAnd: TypeMask) = HeaderTypeSizeAndClass
		ifTrue: [(self sizeHeader: oop) bitAnd: LongSizeMask]
		ifFalse: [header bitAnd: SizeMask]
]

{ #category : #'object access' }
NewObjectMemory >> sizeBitsOfSafe: oop [
	"Compute the size of the given object from the cc and size fields in its header.
	 This works even if its type bits are not correct."

	| header type |
	header := self baseHeader: oop.
	type := self rightType: header.
	^type = HeaderTypeSizeAndClass
		ifTrue: [(self sizeHeader: oop) bitAnd: AllButTypeMask]
		ifFalse: [header bitAnd: SizeMask]
]

{ #category : #'primitive support' }
NewObjectMemory >> sizeHeader: obj putBodySize: byteSize [
	"Too lazy to set the odd bits right now.  Just insist on a multiple of 4 bytes."
	self assert: byteSize \\ 4 = 0.
	self longAt: obj - (self wordSize*2)
		put: ((byteSize + self wordSize bitAnd: LongSizeMask)
				bitOr: ((self longAt: obj - (self wordSize*2)) bitClear: LongSizeMask))
]

{ #category : #'cog jit support' }
NewObjectMemory >> smallIntegerTag [
	^1
]

{ #category : #'memory access' }
NewObjectMemory >> startOfFreeSpace [
	<inline: true>
	^freeStart
]

{ #category : #accessing }
NewObjectMemory >> statGCEndUsecs [
	^statGCEndUsecs
]

{ #category : #'image segment in/out' }
NewObjectMemory >> storeImageSegmentInto: segmentWordArray outPointers: outPointerArray roots: arrayOfRoots [

"This primitive will store a binary image segment (in the same format as the Squeak image file) of the receiver and every object in its proper tree of subParts (ie, that is not refered to from anywhere else outside the tree).  All pointers from within the tree to objects outside the tree will be copied into the array of outpointers.  In their place in the image segment will be an oop equal to the offset in the outPointer array (the first would be 4). but with the high bit set."

"The primitive expects the array and wordArray to be more than adequately long.  In this case it returns normally, and truncates the two arrays to exactly the right size.  To simplify truncation, both incoming arrays are required to be 256 bytes or more long (ie with 3-word headers).  If either array is too small, the primitive will fail, but in no other case.

During operation of the primitive, it is necessary to convert from both internal and external oops to their mapped values.  To make this fast, the headers of the original objects in question are replaced by the mapped values (and this is noted by adding the forbidden XX header type).  Tables are kept of both kinds of oops, as well as of the original headers for restoration.

To be specific, there are two similar two-part tables, the outpointer array, and one in the upper fifth of the segmentWordArray.  Each grows oops from the bottom up, and preserved headers from halfway up.

In case of either success or failure, the headers must be restored.  In the event of primitive failure, the table of outpointers must also be nilled out (since the garbage in the high half will not have been discarded."

	| savedYoungStart lastOut lastIn firstIn lastSeg endSeg segOop fieldPtr fieldOop mapOop
	  doingClass lastPtr extraSize hdrTypeBits hdrBaseIn hdrBaseOut header firstOut versionOffset |
	<inline: false>
	<var: #firstIn type: #usqInt>
	<var: #lastIn type: #usqInt>
	<var: #firstOut type: #usqInt>
	<var: #lastOut type: #usqInt>
	<var: #hdrBaseIn type: #usqInt>
	<var: #hdrBaseOut type: #usqInt>
	<var: #lastSeg type: #usqInt>
	<var: #endSeg type: #usqInt>
	<var: #fieldPtr type: #usqInt>
	<var: #lastPtr type: #usqInt>
	<var: #segOop type: #usqInt>
	<var: #savedYoungStart type: #usqInt>

	((self headerType: outPointerArray) = HeaderTypeSizeAndClass			"Must be 3-word header"
	and: [(self headerType: segmentWordArray) = HeaderTypeSizeAndClass])	"Must be 3-word header"
		ifFalse: [^PrimErrGenericFailure].

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	"Use the top half of outPointers for saved headers."
	firstOut := outPointerArray + self baseHeaderSize.
	lastOut := firstOut - self wordSize.
	hdrBaseOut := outPointerArray + ((self lastPointerOf: outPointerArray) // (self wordSize*2) * self wordSize). "top half"

	lastSeg := segmentWordArray.
	endSeg := segmentWordArray + (self sizeBitsOf: segmentWordArray) - self wordSize.

	"Write a version number for byte order and version check"
	versionOffset := self wordSize.
	lastSeg := lastSeg + versionOffset.
	lastSeg > endSeg ifTrue: [^PrimErrGenericFailure].
	self longAt: lastSeg put: self imageSegmentVersion.

	"Allocate top 1/8 of segment for table of internal oops and saved headers"
	firstIn := endSeg - ((self sizeBitsOf: segmentWordArray) // (self wordSize*8) * self wordSize).  "Take 1/8 of seg"
	lastIn := firstIn - self wordSize.
	hdrBaseIn := firstIn + ((self sizeBitsOf: segmentWordArray) // (self wordSize*16) * self wordSize). "top half of that"

	"First mark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitOr: MarkBit).
	lastPtr := arrayOfRoots + (self lastPointerOf: arrayOfRoots).
	fieldPtr := arrayOfRoots + self baseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop := self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitOr: MarkBit)].
		fieldPtr := fieldPtr + self wordSize].

	"Then do a mark pass over all objects.  This will stop at our marked roots,
	thus leaving our segment unmarked in their shadow."
	savedYoungStart := youngStart.
	youngStart := self startOfMemory.  "process all of memory"
	self markAndTraceInterpreterOops: false.	"and special objects array"
	youngStart := savedYoungStart.
	
	"Finally unmark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitAnd: AllButMarkBit).
	fieldPtr := arrayOfRoots + self baseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop := self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitAnd: AllButMarkBit)].
		fieldPtr := fieldPtr + self wordSize].

	"All external objects, and only they, are now marked.
	Copy the array of roots into the segment, and forward its oop."
	lastIn := lastIn + self wordSize.
	(lastIn >= hdrBaseIn
	 or: [0 = (lastSeg := self copyObj: arrayOfRoots toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn))]) ifTrue:
		[lastIn := lastIn - self wordSize.
		self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
		^self primitiveFailCodeAfterCleanup: outPointerArray].

	"Now run through the segment fixing up all the pointers.
	Note that more objects will be added to the segment as we make our way along."
	segOop := self oopFromChunk: segmentWordArray + versionOffset + self baseHeaderSize.
	[segOop <= lastSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type=0 or 1) -- start with that."
					fieldPtr := segOop - self wordSize.  doingClass := true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr := segOop + self baseHeaderSize.  doingClass := false].
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"

		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop := self longAt: fieldPtr.
			doingClass ifTrue:
				[hdrTypeBits := fieldOop bitAnd: TypeMask.
				fieldOop := fieldOop - hdrTypeBits].
			(self isIntegerObject: fieldOop)
				ifTrue: ["Just an integer -- nothing to do"
						fieldPtr := fieldPtr + self wordSize]
				ifFalse:
				[header := self longAt: fieldOop.
				(header bitAnd: TypeMask) = HeaderTypeFree
					ifTrue: ["Has already been forwarded -- this is the link"
							mapOop := header bitAnd: AllButTypeMask]
					ifFalse:
					[((self longAt: fieldOop) bitAnd: MarkBit) = 0
						ifTrue:
							["Points to an unmarked obj -- an internal pointer.
							Copy the object into the segment, and forward its oop."
							lastIn := lastIn + self wordSize.
							(lastIn >= hdrBaseIn
							or: [0 = (lastSeg := self copyObj: fieldOop toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn))]) ifTrue:
								["Out of space in segment"
								lastIn := lastIn - self wordSize.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^self primitiveFailCodeAfterCleanup: outPointerArray].
							mapOop := (self longAt: fieldOop) bitAnd: AllButTypeMask]
						ifFalse:
							["Points to a marked obj -- an external pointer.
							Map it as a tagged index in outPointers, and forward its oop."
							lastOut := lastOut + self wordSize.
							lastOut >= hdrBaseOut ifTrue:
								["Out of space in outPointerArray"
								lastOut := lastOut - self wordSize.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^self primitiveFailCodeAfterCleanup: outPointerArray].
.							mapOop := lastOut - outPointerArray bitOr: 16r80000000.
							self forward: fieldOop to: mapOop
								savingOopAt: lastOut andHeaderAt: hdrBaseOut + (lastOut - firstOut)]].
					"Replace the oop by its mapped value"
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr := fieldPtr + (self wordSize*2).
								doingClass := false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr := fieldPtr + self wordSize]]].
		segOop := self objectAfter: segOop].

	self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.

	"Truncate the outPointerArray..."
	((outPointerArray + (self lastPointerOf: outPointerArray) - lastOut) < 12
		or: [(endSeg - lastSeg) < 12]) ifTrue:
			["Not enough room to insert simple 3-word headers"
			^self primitiveFailCodeAfterCleanup: outPointerArray].
	extraSize := self extraHeaderBytes: segmentWordArray.
	hdrTypeBits := self headerType: segmentWordArray.
	"Copy the 3-word wordArray header to establish a free chunk."
	self transfer: 3
		from: segmentWordArray - extraSize
		to: lastOut+self wordSize.
	"Adjust the size of the original as well as the free chunk."
	self longAt: lastOut+self wordSize
		put: outPointerArray + (self lastPointerOf: outPointerArray) - lastOut - extraSize + hdrTypeBits.
	self longAt: outPointerArray-extraSize
		put: lastOut - firstOut + (self wordSize*2) + hdrTypeBits.
	"Note that pointers have been stored into roots table"
	self beRootIfOld: outPointerArray.

	"Truncate the image segment..."
	"Copy the 3-word wordArray header to establish a free chunk."
	self transfer: 3
		from: segmentWordArray - extraSize
		to: lastSeg+self wordSize.
	"Adjust the size of the original as well as the free chunk."
	self longAt: segmentWordArray-extraSize
		put: lastSeg - segmentWordArray + self baseHeaderSize + hdrTypeBits.
	self longAt: lastSeg+self wordSize
		put: endSeg - lastSeg - extraSize + hdrTypeBits.

	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	^PrimNoErr
]

{ #category : #allocation }
NewObjectMemory >> sufficientSpaceAfterGC: minFree [ 
	"Return true if there is enough free space after doing a garbage collection. If not, signal that space is low."
	<inline: false>
	| oldLimit |
	self incrementalGC. "try to recover some space"

	(self oop: freeStart + minFree isLessThanOrEqualTo: reserveStart) ifTrue:
		[^true].

	signalLowSpace ifTrue:
		[^false]. "give up; problem is already noted"

	self fullGC. "try harder"
	"for stability, require more free space after doing an expensive full GC"
	(self oop: freeStart + minFree + 15000 isLessThan: reserveStart) ifTrue:
		[^true].

	"still not enough; attempt to grow object memory"

	[oldLimit := memoryLimit.
	 self growObjectMemory: minFree + 15000 + growHeadroom.
	 self oop: freeStart + minFree + 15000 isLessThan: reserveStart]
		whileFalse: "If the memoryLimit doesn't change then presumably the platform can't grow anymore." 
			[oldLimit = memoryLimit ifTrue: [^false]].
	^true
]

{ #category : #allocation }
NewObjectMemory >> sufficientSpaceToAllocate: bytes [
	"Return true if there is enough space to allocate the given number of bytes, perhaps after doing a garbage collection."

	| minFree |
	<inline: true>
	minFree := (lowSpaceThreshold + bytes + self baseHeaderSize + self wordSize - 1) bitClear: self wordSize - 1.

	"check for low-space"
	(self oop: freeStart + minFree isLessThanOrEqualTo: reserveStart) ifTrue:
		[^true].
	^self sufficientSpaceAfterGC: minFree
]

{ #category : #'gc -- mark and sweep' }
NewObjectMemory >> sweepPhase [
	"Sweep memory from youngStart through the end of memory. Free all 
	inaccessible objects and coalesce adjacent free chunks. Clear the mark 
	bits of accessible objects. Compute the starting point for the first pass of 
	incremental compaction (compStart). Return the number of surviving 
	objects. "
	"Details: Each time a non-free object is encountered, decrement the 
	number of available forward table entries. If all entries are spoken for 
	(i.e., entriesAvailable reaches zero), set compStart to the last free 
	chunk before that object or, if there is no free chunk before the given 
	object, the first free chunk after it. Thus, at the end of the sweep 
	phase, compStart through compEnd spans the highest collection of 
	non-free objects that can be accomodated by the forwarding table. This 
	information is used by the first pass of incremental compaction to 
	ensure that space is initially freed at the end of memory. Note that 
	there should always be at least one free chunk--the one at the end of 
	the heap."
	| entriesAvailable survivors freeChunk firstFree oop oopHeader oopHeaderType hdrBytes oopSize freeChunkSize freeStartLocal |
	<inline: false>
	<var: #oop type: #usqInt>
	<var: #freeStartLocal type: #usqInt>
	entriesAvailable := self fwdTableInit: self wordSize*2.
	survivors := 0.
	freeChunk := nil.
	firstFree := nil.
	"will be updated later"
	freeStartLocal := freeStart.
	oop := self oopFromChunk: youngStart.
	[oop < freeStartLocal]
		whileTrue: ["get oop's header, header type, size, and header size"
			statSweepCount := statSweepCount + 1.
			oopHeader := self baseHeader: oop.
			oopHeaderType := oopHeader bitAnd: TypeMask.
			hdrBytes := headerTypeBytes at: oopHeaderType.
			(oopHeaderType bitAnd: 1) = 1
				ifTrue: [oopSize := oopHeader bitAnd: SizeMask]
				ifFalse: [oopHeaderType = HeaderTypeSizeAndClass
						ifTrue: [oopSize := (self sizeHeader: oop) bitAnd: LongSizeMask]
						ifFalse: ["free chunk" oopSize := oopHeader bitAnd: LongSizeMask]].
			(oopHeader bitAnd: MarkBit) = 0
				ifTrue: ["object is not marked; free it"
					"<-- Finalization support: We need to mark each oop chunk as free -->"
					self longAt: oop - hdrBytes put: HeaderTypeFree.
					freeChunk ~= nil
						ifTrue: ["enlarge current free chunk to include this oop"
							freeChunkSize := freeChunkSize + oopSize + hdrBytes]
						ifFalse: ["start a new free chunk"
							freeChunk := oop - hdrBytes.
							"chunk may start 4 or 8 bytes before oop"
							freeChunkSize := oopSize + (oop - freeChunk).
							"adjust size for possible extra header bytes"
							firstFree = nil ifTrue: [firstFree := freeChunk]]]
				ifFalse: ["object is marked; clear its mark bit and possibly adjust 
					the compaction start"
					self longAt: oop put: (oopHeader bitAnd: AllButMarkBit).
					"<-- Finalization support: Check if we're running about a weak class -->"
					(self isWeakNonImm: oop) ifTrue: [self finalizeReference: oop].
					entriesAvailable > 0
						ifTrue: [entriesAvailable := entriesAvailable - 1]
						ifFalse: ["start compaction at the last free chunk before this object"
							firstFree := freeChunk].
					freeChunk ~= nil
						ifTrue: ["record the size of the last free chunk"
							self longAt: freeChunk put: ((freeChunkSize bitAnd: LongSizeMask) bitOr: HeaderTypeFree).
							freeChunk := nil].
					survivors := survivors + 1].
			oopSize = 0 ifTrue:
				[self error: 'zero sized object encountered in sweep'].
			oop := self oopFromChunk: oop + oopSize].
	freeChunk ~= nil
		ifTrue: ["record size of final free chunk"
			self longAt: freeChunk put: ((freeChunkSize bitAnd: LongSizeMask) bitOr: HeaderTypeFree)].
	oop = freeStart
		ifFalse: [self error: 'sweep failed to find exact end of memory'].
	compStart := firstFree = nil
					ifTrue: [freeStart]
					ifFalse: [firstFree].
	^survivors
]

{ #category : #'garbage collection' }
NewObjectMemory >> sweepPhaseForFullGC [
	"Sweep memory from youngStart through the end of memory. Free all
	 inaccessible objects and coalesce adjacent free chunks. Clear the mark
	 bits of accessible objects. Compute the starting point for the first pass
	 of incremental compaction (compStart). Return the number of surviving
	 objects.  Unlike sweepPhase this always leaves compStart pointing at the
	 first free chunk."
	| survivors freeChunk firstFree oop oopHeader oopHeaderType hdrBytes oopSize freeChunkSize endOfMemoryLocal |
	<inline: false>
	<var: #oop type: #usqInt>
	<var: #endOfMemoryLocal type: #usqInt>
	self fwdTableInit: self wordSize*2.
	survivors := 0.
	freeChunk := nil.
	firstFree := nil.
	"will be updated later"
	endOfMemoryLocal := endOfMemory.
	oop := self oopFromChunk: youngStart.
	[oop < endOfMemoryLocal]
		whileTrue: ["get oop's header, header type, size, and header size"
			statSweepCount := statSweepCount + 1.
			oopHeader := self baseHeader: oop.
			oopHeaderType := oopHeader bitAnd: TypeMask.
			hdrBytes := headerTypeBytes at: oopHeaderType.
			(oopHeaderType bitAnd: 1) = 1
				ifTrue: [oopSize := oopHeader bitAnd: SizeMask]
				ifFalse: [oopHeaderType = HeaderTypeSizeAndClass
						ifTrue: [oopSize := (self sizeHeader: oop) bitAnd: LongSizeMask]
						ifFalse: [self assert: (oopHeader bitAnd: MarkBit) = 0.
								oopSize := oopHeader bitAnd: LongSizeMask]].
			(oopHeader bitAnd: MarkBit) = 0
				ifTrue: ["object is not marked; free it"
					"<-- Finalization support: We need to mark each oop chunk as free -->"
					self longAt: oop - hdrBytes put: HeaderTypeFree.
					freeChunk ~= nil
						ifTrue: ["enlarge current free chunk to include this oop"
							freeChunkSize := freeChunkSize + oopSize + hdrBytes]
						ifFalse: ["start a new free chunk"
							freeChunk := oop - hdrBytes.
							"chunk may start 4 or 8 bytes before oop"
							freeChunkSize := oopSize + (oop - freeChunk).
							"adjust size for possible extra header bytes"
							firstFree = nil ifTrue: [firstFree := freeChunk]]]
				ifFalse: ["object is marked; clear its mark bit and possibly adjust 
					the compaction start"
					self longAt: oop put: (oopHeader bitAnd: AllButMarkBit).
					"<-- Finalization support: Check if we're running about a weak class -->"
					(self isWeakNonImm: oop) ifTrue: [self finalizeReference: oop].
					freeChunk ~= nil
						ifTrue: ["record the size of the last free chunk"
							self longAt: freeChunk put: ((freeChunkSize bitAnd: LongSizeMask) bitOr: HeaderTypeFree).
							freeChunk := nil].
					survivors := survivors + 1].
			oop := self oopFromChunk: oop + oopSize].
	freeChunk ~= nil
		ifTrue: ["record size of final free chunk"
			self longAt: freeChunk put: ((freeChunkSize bitAnd: LongSizeMask) bitOr: HeaderTypeFree)].
	oop = endOfMemory
		ifTrue: [freeStart := endOfMemory]
		ifFalse: [self error: 'sweep failed to find exact end of memory'].
	firstFree = nil
		ifTrue: [self error: 'expected to find at least one free object']
		ifFalse: [compStart := firstFree].

	^ survivors
]

{ #category : #accessing }
NewObjectMemory >> trueObject: anOop [
	"For mapInterpreterOops"
	trueObj := anOop
]

{ #category : #'primitive support' }
NewObjectMemory >> unmarkAllObjects [
	| oop hdr |
	oop := self firstObject.
	[oop asUnsignedInteger < freeStart] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[hdr := self baseHeader: oop.
			 (hdr bitAnd: MarkBit) ~= 0 ifTrue:
				[self baseHeader: oop put: (hdr bitAnd: AllButMarkBit)]].
		 oop := self objectAfter: oop]
]

{ #category : #'primitive support' }
NewObjectMemory >> unpinObject: objOop [
	"For forward-compatibility with Spur.  Fail; ObjectMemory does not support pinning."
	<api>
	coInterpreter primitiveFailFor: PrimErrUnsupported
]

{ #category : #simulation }
NewObjectMemory >> validate [
	"Validate all the objects in the heap."
	self cCode: [] inSmalltalk: [
	| oop prev |
	self interpreter transcript show: 'Validating...'.
	oop := self firstObject.
	[oop < freeStart] whileTrue:
		[self validate: oop.
		prev := oop.  "look here if debugging prev obj overlapping this one"
		oop := self safeObjectAfter: oop].
	self touch: prev.  "Don't offer to delete this please"
	self interpreter transcript show: 'done.'; cr]
]

{ #category : #simulation }
NewObjectMemory >> validate: oop [
	<doNotGenerate>
	| header type cc sz fmt nextChunk | 
	header := self longAt: oop.
	type := header bitAnd: 3.
	type = 2 ifFalse: [type = (self rightType: header) ifFalse: [self halt]].
	sz := (header bitAnd: SizeMask) >> 2.
	nextChunk := oop + ((self isFreeObject: oop)
							ifTrue: [self sizeOfFree: oop]
							ifFalse: [self sizeBitsOf: oop]).
	nextChunk >= freeStart
		ifTrue:
			[nextChunk ~= freeStart ifTrue: [self halt]]
		ifFalse:
			[(self headerType: nextChunk) = 0 ifTrue:
				[(self headerType: (nextChunk + (self wordSize*2))) = 0 ifFalse: [self halt]].
			(self headerType: nextChunk) = 1 ifTrue:
				[(self headerType: (nextChunk + self wordSize)) = 1 ifFalse: [self halt]]].
	type = 2 ifTrue: "free block"
		[^self].
	fmt := self formatOfHeader: header.
	cc := self compactClassIndexOfHeader: header.
	cc > 16 ifTrue: [self halt].	"up to 32 are legal, but not used"
	type = 0 ifTrue:
		["three-word header"
		((self longAt: oop-self wordSize) bitAnd: 3) = type ifFalse: [self halt].
		((self longAt: oop-(self wordSize*2)) bitAnd: 3) = type ifFalse: [self halt].
		((self longAt: oop-self wordSize) = type) ifTrue: [self halt].	"Class word is 0"
		sz = 0 ifFalse: [self halt]].
	type = 1 ifTrue:
		["two-word header"
		((self longAt: oop-self wordSize) bitAnd: 3) = type ifFalse: [self halt].
		cc > 0 ifTrue: [sz = 1 ifFalse: [self halt]].
		sz = 0 ifTrue: [self halt]].
	type = 3 ifTrue:
		["one-word header"
		cc = 0 ifTrue: [self halt]].
	fmt = 5 ifTrue: [self halt].
	fmt = 7 ifTrue: [self halt].
	fmt >= self firstCompiledMethodFormat ifTrue: "must have integer header"
		[(self isIntegerObject: (self longAt: oop + self wordSize)) ifFalse: [self halt]].
]

{ #category : #'image segment in/out' }
NewObjectMemory >> verifyCleanHeaders [
	| oop |
	oop := self firstObject.
	[self oop: oop isLessThan: freeStart] whileTrue:
		[(self isFreeObject: oop)
			ifTrue: ["There should only be one free block at end of memory."
					(self objectAfter: oop) = endOfMemory
						ifFalse: [self error: 'Invalid obj with HeaderTypeBits = Free.']]
			ifFalse: [(self isMarked: oop) ifTrue:
						[self error: 'Invalid obj with MarkBit set.']].
		oop := self objectAfter: oop]
]

{ #category : #'debug printing' }
NewObjectMemory >> whereIsMaybeHeapThing: anOop [
	<returnTypeC: 'char *'>
	(self oop: anOop isGreaterThanOrEqualTo: self startOfMemory andLessThan: endOfMemory) ifTrue:
		[(self oop: anOop isLessThan: freeStart) ifTrue:
			[^' is in old space'].
		 (self oop: anOop isLessThan: reserveStart) ifTrue:
			[^' is in new space'].
		 ^' is above reserve start'].
	^nil
]

{ #category : #'image segment in/out' }
NewObjectMemory >> wordSwapFloatsFrom: startOop to: stopAddr [
	"Swap the most and least significant words of Floats in a range of the image."
	| oop temp |
	oop := startOop.
	[self oop: oop isLessThan: stopAddr] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[((self formatOf: oop) = self firstLongFormat
			 and: [(self compactClassIndexOf: oop) = ClassFloatCompactIndex]) ifTrue:
				[temp := self longAt: oop + self baseHeaderSize.
				 self longAt: oop + self baseHeaderSize put: (self longAt: oop + self baseHeaderSize + 4).
				 self longAt: oop + self baseHeaderSize + 4 put: temp]].
		oop := self objectAfter: oop]
]

{ #category : #'cog jit support' }
NewObjectMemory >> youngStart [
	<cmacro: '() GIV(youngStart)'>
	^youngStart
]
