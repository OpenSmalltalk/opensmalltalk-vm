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
		'statGCEndUsecs'
	],
	#classVars : [
		'AllocationCheckFiller'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #translation }
NewObjectMemory class >> declareCVarsIn: aCCodeGenerator [
	self declareCAsOop: #(freeStart reserveStart scavengeThreshold)
		in: aCCodeGenerator.
	aCCodeGenerator var: #statGCEndUsecs type: #usqLong
]

{ #category : #initialization }
NewObjectMemory class >> initializeWithOptions: optionsDictionary [
	"NewObjectMemory initializeWithOptions: Dictionary new"

	super initializeWithOptions: optionsDictionary.

	"The AllocationCheckFiller is used to fill newSpace and hence check for
	 writes beyond the ends of objects which would overwrite the filler."
	(optionsDictionary includesKey: #AllocationCheckFiller)
		ifTrue:
			[AllocationCheckFiller := optionsDictionary at: #AllocationCheckFiller]
		ifFalse:
			[AllocationCheckFiller isNil ifTrue:
				[AllocationCheckFiller := #(	0				"no allocation check"
											16r55AA55AA	"fill with 16r55AA55AA"
											16rADD4E55)	"fill with address"
												last
				"AllocationCheckFiller := 0"
				"AllocationCheckFiller := 16r55AA55AA"
				"AllocationCheckFiller := 16rADD4E55"]]
]

{ #category : #translation }
NewObjectMemory class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^(super mustBeGlobal: var)
	   or: ['checkForLeaks' = var]
]

{ #category : #translation }
NewObjectMemory class >> prepareToBeAddedToCodeGenerator: aCodeGen [
	"Remove the superclass methods we override
	 and the instance variables we don't use."
	self selectors do:
		[:sel|
		 (superclass whichClassIncludesSelector: sel) ifNotNil:
			[aCodeGen removeMethodForSelector: sel]].
	self ~~ NewObjectMemory ifTrue:
		[^self].
	aCodeGen removeMethodForSelector: #markPhase. "we implement markPhase:"
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

{ #category : #allocation }
NewObjectMemory >> allocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOopArg h3: extendedSize doFill: doFill format: format [
	"Allocate a new object of the given size and number of header words. (Note: byteSize already includes space for the base header word.) Initialize the header fields of the new object and fill the remainder of the object with a value appropriate for the format.
	May cause a GC"

	| newObj classOop |
	<inline: true>
	<var: #i type: 'usqInt'>
	<var: #end type: 'usqInt'>
	newObj := self allocateChunk: byteSize + (hdrSize - 1 * BytesPerWord).
	newObj = 0
		ifTrue:
			["remap classOop because GC may move the classOop"
			hdrSize > 1 ifTrue: [self pushRemappableOop: classOopArg].
			newObj := self allocateChunkAfterGC: byteSize + (hdrSize - 1 * BytesPerWord).
			hdrSize > 1 ifTrue: [classOop := self popRemappableOop].
			newObj = 0 ifTrue: [^newObj]]
		ifFalse: [classOop := classOopArg].

	hdrSize = 3 ifTrue:
		[self longAt: newObj put: (extendedSize bitOr: HeaderTypeSizeAndClass).
		 self longAt: newObj + BytesPerWord put: (classOop bitOr: HeaderTypeSizeAndClass).
		 self longAt: newObj + (BytesPerWord*2) put: (baseHeader bitOr: HeaderTypeSizeAndClass).
		 newObj := newObj + (BytesPerWord*2)].

	hdrSize = 2 ifTrue:
		[self longAt: newObj put: (classOop bitOr: HeaderTypeClass).
		 self longAt: newObj + BytesPerWord put: (baseHeader bitOr: HeaderTypeClass).
		 newObj := newObj + BytesPerWord].

	hdrSize = 1 ifTrue:
		[self longAt: newObj put: (baseHeader bitOr: HeaderTypeShort)].

	"clear new object"
	doFill ifTrue:
		[| fillWord end i |
		 fillWord := format <= 4
					ifTrue: [nilObj] "if pointers, fill with nil oop"
					ifFalse: [0].
		 end := newObj + byteSize.
		 i := newObj + BytesPerWord.
		 [i < end] whileTrue:
			[self longAt: i put: fillWord.
			 i := i + BytesPerWord]].
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
		[(AllocationCheckFiller ~= 0
		  and: [(self longAt: newChunk) ~= (AllocationCheckFiller = 16rADD4E55
												ifTrue: [newChunk]
												ifFalse: [AllocationCheckFiller])]) ifTrue:
			[self error: 'last object overwritten'].
		freeStart := newFreeStart.
		 ^self oopForPointer: newChunk].

	self scheduleIncrementalGC.
	freeStart <= reserveStart ifTrue:
		[freeStart := newFreeStart.
		 ^self oopForPointer: newChunk].

	^0
]

{ #category : #allocation }
NewObjectMemory >> allocateChunkAfterGC: byteSize [ 
	"Garbage colect and then allocate a chunk of the given size. Sender must be sure
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

	"if we get here, there is enough space for allocation to  succeed "
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
	<asmLabel: false>
	<var: #newChunk type: #usqInt>
	<var: #newFreeStart type: #usqInt>

	newChunk := freeStart.
	newFreeStart := freeStart + byteSize.
	newFreeStart < scavengeThreshold ifTrue:
		[(AllocationCheckFiller ~= 0
		  and: [(self longAt: newChunk) ~= (AllocationCheckFiller == 16rADD4E55
												ifTrue: [newChunk]
												ifFalse: [AllocationCheckFiller])]) ifTrue:
			[self error: 'last object overwritten'].
		freeStart := newFreeStart.
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

{ #category : #become }
NewObjectMemory >> become: array1 with: array2 twoWay: twoWayFlag copyHash: copyHashFlag [
	"All references to each object in array1 are swapped with all references to the corresponding object in array2. That is, all pointers to one object are replaced with with pointers to the other. The arguments must be arrays of the same length. 
	Returns PrimNoErr if the primitive succeeds."
	"Implementation: Uses forwarding blocks to update references as done in compaction."
	| start |
	self leakCheckBecome ifTrue:
		[self runLeakCheckerForFullGC: true].
	(self isArray: array1) ifFalse:
		[^PrimErrBadReceiver].
	((self isArray: array2)
	 and: [(self lastPointerOf: array1) = (self lastPointerOf: array2)]) ifFalse:
		[^PrimErrBadArgument].
	twoWayFlag
		ifTrue: [(self containOnlyOops: array1 and: array2) ifFalse: [^PrimErrInappropriate]]
		ifFalse: [(self containOnlyOops: array1) ifFalse: [^PrimErrInappropriate]].

	(self prepareForwardingTableForBecoming: array1 with: array2 twoWay: twoWayFlag) ifFalse:
		[^PrimErrNoMemory]. "fail; not enough space for forwarding table"

	(self allYoung: array1 and: array2)
		ifTrue: [start := youngStart"sweep only the young objects plus the roots"]
		ifFalse: [start := self startOfMemory"sweep all objects"].
	coInterpreter preBecomeAction.
	self mapPointersInObjectsFrom: start to: endOfMemory.
	twoWayFlag
		ifTrue: [self restoreHeadersAfterBecoming: array1 with: array2]
		ifFalse: [self restoreHeadersAfterForwardBecome: copyHashFlag].
	coInterpreter postBecomeAction.

	self initializeMemoryFirstFree: freeStart. "re-initialize memory used for forwarding table"
	self leakCheckBecome ifTrue:
		[self runLeakCheckerForFullGC: true].
	self forceInterruptCheck. "pretty much guaranteed to take a long time, so check for timers etc ASAP"

	^PrimNoErr "success"
]

{ #category : #'garbage collection' }
NewObjectMemory >> biasToGrow [
	<asmLabel: false>
	self growObjectMemory: (growHeadroom*3/2) - self freeSize
]

{ #category : #allocation }
NewObjectMemory >> bytesLeft: includingSwap [
	^self freeSize + (self sqMemoryExtraBytesLeft: includingSwap)
]

{ #category : #accessing }
NewObjectMemory >> checkForLeaks [
	^checkForLeaks
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
	(oop >= self startOfMemory and: [oop < freeStart])
		ifFalse: [ self print: 'oop is not a valid address'; cr. ^false ].
	((oop \\ BytesPerWord) = 0)
		ifFalse: [ self print: 'oop is not a word-aligned address'; cr. ^false ].
	sz := self sizeBitsOf: oop.
	(oop + sz) < freeStart
		ifFalse: [ self print: 'oop size would make it extend beyond the end of memory'; cr. ^false ].

	"header type checks"
	type := self headerType: oop.
	type = HeaderTypeFree
		ifTrue:  [ self print: 'oop is a free chunk, not an object'; cr. ^false ].
	type = HeaderTypeShort ifTrue: [
		(self compactClassIndexOf: oop) = 0
			ifTrue:  [ self print: 'cannot have zero compact class field in a short header'; cr. ^false ].
	].
	type = HeaderTypeClass ifTrue: [
		((oop >= BytesPerWord) and: [(self headerType: oop - BytesPerWord) = type])
			ifFalse: [ self print: 'class header word has wrong type'; cr. ^false ].
	].
	type = HeaderTypeSizeAndClass ifTrue: [
		((oop >= (BytesPerWord*2)) and:
		 [(self headerType: oop - (BytesPerWord*2)) = type and:
		 [(self headerType: oop - BytesPerWord) = type]])
			ifFalse: [ self print: 'class header word has wrong type'; cr. ^false ].
	].

	"format check"
	fmt := self formatOf: oop.
	((fmt = 5) | (fmt = 7))
		ifTrue:  [ self print: 'oop has an unknown format type'; cr. ^false ].

	"mark and root bit checks"
	unusedBit := 16r20000000.
	BytesPerWord = 8
		ifTrue:
			[unusedBit := unusedBit << 16.
			 unusedBit := unusedBit << 16].
	((self longAt: oop) bitAnd: unusedBit) = 0
		ifFalse: [ self print: 'unused header bit 30 is set; should be zero'; cr. ^false ].
"xxx
	((self longAt: oop) bitAnd: MarkBit) = 0
		ifFalse: [ self print: 'mark bit should not be set except during GC' ].
xxx"
	(((self longAt: oop) bitAnd: RootBit) = 1 and:
	 [oop >= youngStart])
		ifTrue: [ self print: 'root bit is set in a young object'; cr. ^false ].
	^true

]

{ #category : #'cog jit support' }
NewObjectMemory >> classFieldOffset [
	<api>
	<cmacro: '() (0 - BaseHeaderSize)'>
	^0 - BaseHeaderSize
]

{ #category : #'cog jit support' }
NewObjectMemory >> classFloatCompactIndex [
	<api>
	^ClassFloatCompactIndex
]

{ #category : #'object enumeration' }
NewObjectMemory >> clearLeakMapAndMapAccessibleObjects [
	"Perform an integrity/leak check using the heapMap.  Set a bit at each object's header."
	| obj sz |
	<inline: false>
	self clearHeapMap.
	obj := self firstObject.
	[self oop: obj isLessThan: freeStart] whileTrue:
		[(self isFreeObject: obj)
			ifTrue:
				[sz := self sizeOfFree: obj]
			ifFalse:
				[self heapMapAtWord: (self pointerForOop: obj) Put: 1.
				 sz := self sizeBitsOf: obj].
		 obj := self oopFromChunk: obj + sz]
]

{ #category : #allocation }
NewObjectMemory >> clone: obj [
	"Return a shallow copy of the given object. May cause GC"
	"Assume: Oop is a real object, not a small integer.
	 Override to assert it's not a married context"
	self assert: ((coInterpreter isContext: obj) not
				or: [(coInterpreter isMarriedOrWidowedContext: obj) not]). 
	^super clone: obj
]

{ #category : #'cog jit support' }
NewObjectMemory >> compactClassFieldLSB [
	<api>
	<cmacro: '() 12'>
	^12
]

{ #category : #'cog jit support' }
NewObjectMemory >> compactClassFieldWidth [
	<api>
	<cmacro: '() 5'>
	^5
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
	 space for the base header word.) Initialize the header fields of the new object and fill the remainder of
	 the object with the given value.  Will not cause a GC.  This version is for the execution engine"

	| newObj |
	<inline: true>
	<asmLabel: false>
	<var: #i type: 'usqInt'>
	<var: #end type: 'usqInt'>
	newObj := self allocateInterpreterChunk: byteSize + (hdrSize - 1 * BytesPerWord).
	newObj = 0 ifTrue: [^newObj].
	hdrSize = 3 ifTrue:
		[self longAt: newObj put: (extendedSize bitOr: HeaderTypeSizeAndClass).
		 self longAt: newObj + BytesPerWord put: (classOop bitOr: HeaderTypeSizeAndClass).
		 self longAt: newObj + (BytesPerWord*2) put: (baseHeader bitOr: HeaderTypeSizeAndClass).
		 newObj := newObj + (BytesPerWord*2)].

	 hdrSize = 2 ifTrue:
		[self longAt: newObj put: (classOop bitOr: HeaderTypeClass).
		 self longAt: newObj + BytesPerWord put: (baseHeader bitOr: HeaderTypeClass).
		 newObj := newObj + BytesPerWord].

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
	<asmLabel: false>
	<var: #i type: 'usqInt'>
	<var: #end type: 'usqInt'>
	newObj := self allocateInterpreterChunk: byteSize + (hdrSize - 1 * BytesPerWord).
	newObj = 0 ifTrue: [^newObj].
	hdrSize = 3 ifTrue:
		[self longAt: newObj put: (extendedSize bitOr: HeaderTypeSizeAndClass).
		 self longAt: newObj + BytesPerWord put: (classOop bitOr: HeaderTypeSizeAndClass).
		 self longAt: newObj + (BytesPerWord*2) put: (baseHeader bitOr: HeaderTypeSizeAndClass).
		 newObj := newObj + (BytesPerWord*2)].

	 hdrSize = 2 ifTrue:
		[self longAt: newObj put: (classOop bitOr: HeaderTypeClass).
		 self longAt: newObj + BytesPerWord put: (baseHeader bitOr: HeaderTypeClass).
		 newObj := newObj + BytesPerWord].

	 hdrSize = 1 ifTrue:
		[self longAt: newObj put: (baseHeader bitOr: HeaderTypeShort)].

	"clear new object"
	doFill ifTrue:
		[| fillWord end i |
		 fillWord := format <= 4
					ifTrue: [nilObj] "if pointers, fill with nil oop"
					ifFalse: [0].
		 end := newObj + byteSize.
		 i := newObj + BytesPerWord.
		 [i < end] whileTrue:
			[self longAt: i put: fillWord.
			 i := i + BytesPerWord]].

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
	byteSize := byteSize << (ShiftForWord-2).
	format := self formatOfHeader: classFormat.
	self flag: #sizeLowBits.
	format < 8
		ifTrue:
			[format = 6
				ifTrue: ["long32 bitmaps"
					bm1 := BytesPerWord-1.
					byteSize := byteSize + (size * 4) + bm1 bitAnd: LongSizeMask. "round up"
					binc := bm1 - ((size * 4) + bm1 bitAnd: bm1). "odd bytes"
					"extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
					header1 := header1 bitOr: (binc bitAnd: 4)]
				ifFalse: [byteSize := byteSize + (size * BytesPerWord) "Arrays and 64-bit bitmaps"]
			]
		ifFalse:
			["Strings and Methods"
			bm1 := BytesPerWord-1.
			byteSize := byteSize + size + bm1 bitAnd: LongSizeMask. "round up"
			binc := bm1 - (size + bm1 bitAnd: bm1). "odd bytes"
			"low bits of byte size go in format field"
			header1 := header1 bitOr: (binc bitAnd: 3) << 8.
			"extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
			header1 := header1 bitOr: (binc bitAnd: 4)].
	byteSize > 255
		ifTrue: ["requires size header word"
			header3 := byteSize.
			header1 := header1]
		ifFalse: [header1 := header1 bitOr: byteSize].
	header3 > 0
		ifTrue: ["requires full header"
			hdrSize := 3]
		ifFalse: [cClass = 0
				ifTrue: [hdrSize := 2]
				ifFalse: [hdrSize := 1]].
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
	byteSize := byteSize << (ShiftForWord-2).
	format := self formatOfHeader: classFormat.
	self flag: #sizeLowBits.
	format < 8
		ifTrue:
			[format = 6
				ifTrue: ["long32 bitmaps"
					bm1 := BytesPerWord-1.
					byteSize := byteSize + (size * 4) + bm1 bitAnd: LongSizeMask. "round up"
					binc := bm1 - ((size * 4) + bm1 bitAnd: bm1). "odd bytes"
					"extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
					header1 := header1 bitOr: (binc bitAnd: 4)]
				ifFalse: [byteSize := byteSize + (size * BytesPerWord) "Arrays and 64-bit bitmaps"]
			]
		ifFalse:
			["Strings and Methods"
			bm1 := BytesPerWord-1.
			byteSize := byteSize + size + bm1 bitAnd: LongSizeMask. "round up"
			binc := bm1 - (size + bm1 bitAnd: bm1). "odd bytes"
			"low bits of byte size go in format field"
			header1 := header1 bitOr: (binc bitAnd: 3) << 8.
			"extra low bit (4) for 64-bit VM goes in 4-bit (betw hdr bits and sizeBits)"
			header1 := header1 bitOr: (binc bitAnd: 4)].
	byteSize > 255
		ifTrue: ["requires size header word"
			header3 := byteSize.
			header1 := header1]
		ifFalse: [header1 := header1 bitOr: byteSize].
	header3 > 0
		ifTrue: ["requires full header"
			hdrSize := 3]
		ifFalse: [cClass = 0
				ifTrue: [hdrSize := 2]
				ifFalse: [hdrSize := 1]].
	^self eeAllocate: byteSize headerSize: hdrSize h1: header1 h2: header2 h3: header3
]

{ #category : #'interpreter access' }
NewObjectMemory >> eeInstantiateMethodContextByteSize: sizeInBytes [ 
	"This version of instantiateClass assumes that the total object 
	 size is under 256 bytes, the limit for objects with only one or 
	 two header words. Note that the size is specified in bytes 
	 and should include four bytes for the base header word.
	 Will *not* cause a GC."
	| hash header1 |
	hash := self newObjectHash.
	header1 := (hash bitAnd: HashMaskUnshifted) << HashBitsOffset bitOr: self formatOfMethodContext.
	self assert: sizeInBytes <= SizeMask.
	self assert: (header1 bitAnd: CompactClassMask) > 0. "contexts must be compact"
	"OR size into header1.  Must not do this if size > SizeMask"
	header1 := header1 + (sizeInBytes - (header1 bitAnd: SizeMask)).
	self flag: #Dan.  "Check details of context sizes"
	^self eeAllocate: sizeInBytes headerSize: 1 h1: header1 h2: nil h3: nil
]

{ #category : #'interpreter access' }
NewObjectMemory >> eeInstantiateSmallClass: classPointer sizeInBytes: sizeInBytes [
	"This version of instantiateClass assumes that the total object
	 size is under 256 bytes, the limit for objects with only one or
	 two header words. Note that the size is specified in bytes
	 and should include 4 or 8 bytes for the base header word.
	 NOTE this code will only work for sizes that are an integral number of words
		(like not a 32-bit LargeInteger in a 64-bit system).
	 Will *not* cause a GC.
	 Note that the created small object IS NOT FILLED and must be completed before returning it to Squeak.
	 Since this call is used in routines that do just that we are safe. Break this rule and die."

	| hash header1 header2 hdrSize |
	"size must be integral number of words"
	self assert: (sizeInBytes bitAnd: (BytesPerWord-1)) = 0.
	hash := self newObjectHash.
	header1 := (hash bitAnd: HashMaskUnshifted) << HashBitsOffset bitOr: (self formatOfClass: classPointer).
	header2 := classPointer.
	hdrSize := (header1 bitAnd: CompactClassMask) > 0 "is this a compact class"
				ifTrue: [1]
				ifFalse: [2].
	header1 := header1 + (sizeInBytes - (header1 bitAnd: SizeMask+Size4Bit)).
	^self eeAllocate: sizeInBytes headerSize: hdrSize h1: header1 h2: header2 h3: 0
]

{ #category : #accessing }
NewObjectMemory >> falseObject: anOop [
	"For mapInterpreterOops"
	falseObj := anOop
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
				[((self isBytesNonInt: obj)
				  and: [(self lengthOf: obj) = cssz
				  and: [(self str: aCString n: (self pointerForOop: obj + BaseHeaderSize) cmp: cssz) = 0]]) ifTrue:
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
				[((self isBytesNonInt: obj)
				  and: [(self lengthOf: obj) >= cssz
				  and: [(self str: aCString n: (self pointerForOop: obj + BaseHeaderSize) cmp: cssz) = 0]]) ifTrue:
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
	^fmt >= 12
		ifTrue: [coInterpreter firstByteIndexOfMethod: obj]
		ifFalse: [1]
]

{ #category : #'frame access' }
NewObjectMemory >> formatOfMethodContext [
	"Answer the class format word for MethodContext which is used to instantiate
	 contexts without needing to fetch it from the class MethodContext itself."
	^(ClassMethodContextCompactIndex << 12)
	+ (3 << 8) "Pointers+Variable"
	+ (CtxtTempFrameStart + (BaseHeaderSize / BytesPerWord) << 2)
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
	^freeStart
]

{ #category : #accessing }
NewObjectMemory >> freeStart: aValue [
	^freeStart := aValue
]

{ #category : #'garbage collection' }
NewObjectMemory >> fullCompaction [
	"Move all accessible objects down to leave one big free chunk at the end of memory.
	 Assume:
		Incremental GC has just been done to maximimize forwarding table space.
		sweepPhaseForFullGC has already set compStart.
	 Need not and can not move objects below the first free chunk."
	| sz |
	<asmLabel: false>
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
	"Do a mark/sweep garbage collection of the entire object memory. Free inaccessible objects but do not move them."

	<inline: false>
	fullGCLock > 0 ifTrue:
		[self warning: 'aborting fullGC because fullGCLock > 0'.
		 ^self].
	self initializeFreeBlocksPreSweep.
	self runLeakCheckerForFullGC: true.
	self preGCAction: GCModeFull.
	gcStartUsecs := self ioUTCMicrosecondsNow.
	statSweepCount := statMarkCount := statMkFwdCount := statCompMoveCount := 0.
	self clearRootsTable.
	self initWeakTableForIncrementalGC: false.
	youngStart := self startOfMemory.  "process all of memory"
	self markPhase: true.
	"Sweep phase returns the number of survivors.
	Use the up-to-date version instead the one from startup."
	totalObjectCount := self sweepPhaseForFullGC.
	self runLeakCheckerForFullGC: true.
	self fullCompaction.
	statFullGCs := statFullGCs + 1.
	statGCEndUsecs := self ioUTCMicrosecondsNow.
	statFullGCUsecs := statFullGCUsecs + (statGCEndUsecs - gcStartUsecs).
	self capturePendingFinalizationSignals.

	youngStart := freeStart.  "reset the young object boundary"
	self postGCAction.
	self runLeakCheckerForFullGC: true
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
	self setSizeOfFree: freeStart to: BaseHeaderSize.
	self setEndOfMemory: freeStart + BaseHeaderSize.

	"make a fake free chunk at endOfMemory for use as a sentinal in memory scans"
	self setSizeOfFree: endOfMemory to: BaseHeaderSize.

	"use all memory free between freeStart and memoryLimit for forwarding table"
	"Note: Forward blocks must be quadword aligned."
	fwdTableNext := (endOfMemory + BaseHeaderSize + 7) bitAnd: WordMask-7.
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

	eom := freeStart + BaseHeaderSize.
	"use all memory free between freeStart and memoryLimit for forwarding table"

	"Note: Forward blocks must be quadword aligned."
	fwdFirst := (eom + BaseHeaderSize + 7) bitAnd: WordMask-7.
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
	self fwdTableInit: BytesPerWord*2.  "Two-word blocks"

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
				[fwdBlock := self fwdBlockGet: BytesPerWord*2.
				 "Two-word block"
				 fwdBlock = nil ifTrue: "stop; we have used all available forwarding blocks"
					[compEnd := self chunkFromOop: oop.
					 ^bytesToBeFreed].
				newOop := oop - bytesToBeFreed.
				self assert: (self oop: newOop isGreaterThan: self startOfMemory andLessThan: freeStart).
				self initForwardBlock: fwdBlock mapping: oop to: newOop withBackPtr: false].
			oop := self objectAfterWhileForwarding: oop].
	compEnd := endOfMemory.
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
			header := self longAt: fwdBlock + BytesPerWord.
			self longAt: oop put: header. "restore the original header"
			bytesToMove := oop - newOop. "move the oop (including any extra header words) "
			sz := self sizeBitsOf: oop.
			firstWord := oop - (self extraHeaderBytes: oop).
			lastWord := oop + sz - BaseHeaderSize.
			target := firstWord - bytesToMove.
			firstWord to: lastWord by: BytesPerWord do:
				[:w | 
				self longAt: target put: (self longAt: w).
				target := target + BytesPerWord]].
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

	rootTableCount >= RootTableSize ifTrue:
		["root table overflow; cannot do an incremental GC (this should be very rare)"
		 statRootTableOverflows := statRootTableOverflows + 1.
		 ^self fullGC].

	self initializeFreeBlocksPreSweep.
	self runLeakCheckerForFullGC: false.

	self preGCAction: GCModeIncr.
	"incremental GC and compaction"

	gcStartUsecs := self ioUTCMicrosecondsNow.
	statSweepCount := statMarkCount := statMkFwdCount := statCompMoveCount := 0.
	self initWeakTableForIncrementalGC: true.
	self markPhase: false.
	self assert: weakRootCount <= WeakRootTableSize.
	1 to: weakRootCount do:
		[:i| self finalizeReference: (weakRoots at: i)].
	survivorCount := self sweepPhase.
	self runLeakCheckerForFullGC: false.
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
	self postGCAction.
	
	self runLeakCheckerForFullGC: false.
	weDidGrow ifTrue:
		[self biasToGrowCheckGCLimit]
]

{ #category : #'gc -- compaction' }
NewObjectMemory >> initForwardBlock: fwdBlock mapping: oop to: newOop withBackPtr: backFlag [ 
	"Initialize the given forwarding block to map oop to newOop, 
	and replace oop's header with a pointer to the fowarding 
	block. "
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
	<asmLabel: false> 
	originalHeader := self longAt: oop.
	self assert: fwdBlock ~= nil. "ran out of forwarding blocks in become"
	self assert: (originalHeader bitAnd: MarkBit) = 0. "'object already has a forwarding table entry"
	originalHeaderType := originalHeader bitAnd: TypeMask.
	self longAt: fwdBlock put: newOop.
	self longAt: fwdBlock + BytesPerWord put: originalHeader.
	backFlag ifTrue: [self longAt: fwdBlock + (BytesPerWord*2) put: oop].
	self longAt: oop put: (fwdBlock >> 1 bitOr: (MarkBit bitOr: originalHeaderType))
]

{ #category : #initialization }
NewObjectMemory >> initialize [
	<doNotGenerate>
	"Initialize NewObjectMemory when simulating the VM inside Smalltalk."
	super initialize.
	checkForLeaks := fullGCLock := 0
]

{ #category : #initialization }
NewObjectMemory >> initializeFreeBlocksPreSweep [
	"Set up the free block in preparation for any kind of sweep through all of memory."
	<inline: true>
	self setSizeOfFree: freeStart to: endOfMemory - freeStart. "bytes available for oops"
	self assert: (self isFreeObject: freeStart).
	self assert: freeStart + (self sizeOfFree: freeStart) = endOfMemory.
	self assert: (freeStart < endOfMemory and: [endOfMemory < memoryLimit])
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
	fwdBlockBytes := totalObjectCount bitAnd: WordMask - BytesPerWord + 1.
	totalReserve := fwdBlockBytes + self interpreterAllocationReserveBytes.
	(self oop: memoryLimit - totalReserve isLessThan: firstFree + BaseHeaderSize) ifTrue:
		["reserve enough space for a minimal free block of BaseHeaderSize bytes.
		  We are apparently in an emergency situation here because we have no space
		  for reserve and forwarding blocks.  But a full GC will occur immediately in	
		  sufficientSpaceAfterGC: which will grow memory and restore the reserve."
		 fwdBlockBytes := memoryLimit - (firstFree  + BaseHeaderSize)].

	"set endOfMemory reserveStart and freeStart"
	self setEndOfMemory: memoryLimit - fwdBlockBytes.
	reserveStart := endOfMemory - self interpreterAllocationReserveBytes.
	freeStart := firstFree. "bytes available for oops"
	scavengeThreshold := freeStart + edenBytes min: reserveStart.
	AllocationCheckFiller ~= 0 ifTrue:
		[freeStart to: scavengeThreshold by: BytesPerWord do:
			[:i| self longAt: i put: (AllocationCheckFiller == 16rADD4E55
									ifTrue: [i]
									ifFalse: [AllocationCheckFiller])]].
	needGCFlag := false.

	self assert: freeStart < reserveStart.
	self assert: reserveStart < endOfMemory.
	self assert: endOfMemory < memoryLimit
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
	youngStart := endOfMemory.

	"image may be at a different address; adjust oops for new location"
	totalObjectCount := self adjustAllOopsBy: bytesToShift.

	self initializeMemoryFirstFree: endOfMemory. "initializes endOfMemory, freeStart"

	specialObjectsOop := specialObjectsOop + bytesToShift.

	"heavily used special objects"
	nilObj	:= self splObj: NilObject.
	falseObj	:= self splObj: FalseObject.
	trueObj	:= self splObj: TrueObject.

	rootTableCount := 0.
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
	<cmacro: '() 8'>
	^8
]

{ #category : #'cog jit support' }
NewObjectMemory >> instFormatFieldWidth [
	<api>
	<cmacro: '() 4'>
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
	^(self compactClassIndexOfHeader: aHeader) == ClassMethodContextCompactIndex
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
	^self oop: obj isGreaterThanOrEqualTo: youngStart
]

{ #category : #'object enumeration' }
NewObjectMemory >> lastPointerOf: oop [ 
	"Return the byte offset of the last pointer field of the given object.  
	 Can be used even when the type bits are not correct.
	 Works with CompiledMethods, as well as ordinary objects."
	| fmt header contextSize numLiterals |
	<inline: true>
	<asmLabel: false>
	header := self baseHeader: oop.
	fmt := self formatOfHeader: header.
	fmt <= 4 ifTrue:
		[(fmt = 3
		  and: [self isContextHeader: header]) ifTrue:
			["contexts end at the stack pointer"
			contextSize := coInterpreter fetchStackPointerOf: oop.
			^CtxtTempFrameStart + contextSize * BytesPerWord].
		^(self sizeBitsOfSafe: oop) - BaseHeaderSize  "all pointers"].
	fmt < 12 ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	numLiterals := coInterpreter literalCountOf: oop.
	^numLiterals * BytesPerWord + BaseHeaderSize
]

{ #category : #'object enumeration' }
NewObjectMemory >> lastPointerOf: oop recordWeakRoot: recordWeakRoot [ "<Boolean>"
	"Return the byte offset of the last pointer field of the given object.  
	 Works with CompiledMethods, as well as ordinary objects. 
	 Can be used even when the type bits are not correct.
	 This is a version of lastPointerOf: for markAndTrace:.
	 Already overridden to trace stack pages for the StackInterpreter.
	 Override to ask coInterpreter to determine literalCount of methods."
	| fmt sz header contextSize numLiterals |
	<inline: true>
	<asmLabel: false>
	header := self baseHeader: oop.
	fmt := self formatOfHeader: header.
	fmt <= 4 ifTrue:
		[fmt >= 3 ifTrue:
			[fmt = 4 ifTrue:
				[(recordWeakRoot and: [weakRootCount >= 0]) ifTrue:
					["And remember as weak root"
					 (weakRootCount := weakRootCount + 1) <= WeakRootTableSize ifFalse:
						[self error: 'weakRoots table overflow'].
					 weakRoots at: weakRootCount put: oop].
				"Do not trace the object's indexed fields if it's a weak class"
				^(self nonWeakFieldsOf: oop) << ShiftForWord].
			"So fmt is 3"
			(self isContextHeader: header) ifTrue:
				[coInterpreter setTraceFlagOnContextsFramesPageIfNeeded: oop.
				 "contexts end at the stack pointer avoiding having to init fields beyond it"
				 contextSize := coInterpreter fetchStackPointerOf: oop.
				 self assert: ReceiverIndex + contextSize < (self lengthOf: oop baseHeader: header format: fmt).
				 ^CtxtTempFrameStart + contextSize * BytesPerWord]].
		 sz := self sizeBitsOfSafe: oop.
		 ^sz - BaseHeaderSize  "all pointers" ].
	fmt < 12 ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	numLiterals := coInterpreter literalCountOf: oop.
	^numLiterals * BytesPerWord + BaseHeaderSize
]

{ #category : #'gc -- compaction' }
NewObjectMemory >> lastPointerWhileForwarding: oop [ 
	"The given object may have its header word in a forwarding block. Find  
	 the offset of the last pointer in the object in spite of this obstacle."
	| header fmt size contextSize numLiterals |
	<inline: true>
	header := self headerWhileForwardingOf: oop.
	fmt := self formatOfHeader: header.
	fmt <= 4 ifTrue:
		[(fmt = 3
		  and: [self isContextHeader: header]) ifTrue:
			["contexts end at the stack pointer"
			 contextSize := coInterpreter nacFetchStackPointerOf: oop.
			 self assert: ReceiverIndex + contextSize < (self lengthOf: oop baseHeader: header format: fmt).
			 ^CtxtTempFrameStart + contextSize * BytesPerWord].
		 "do sizeBitsOf: using the header we obtained"
		 size := (header bitAnd: TypeMask) = HeaderTypeSizeAndClass
					ifTrue: [(self sizeHeader: oop) bitAnd: AllButTypeMask]
					ifFalse: [header bitAnd: SizeMask].
		 ^size - BaseHeaderSize].
	fmt < 12 ifTrue: [^0]. "no pointers"
	"CompiledMethod: contains both pointers and bytes"
	self assert: (header bitAnd: MarkBit) = 0.
	numLiterals := coInterpreter literalCountOf: oop.
	^numLiterals * BytesPerWord + BaseHeaderSize
]

{ #category : #'debug support' }
NewObjectMemory >> leakCheckBecome [
	<api>
	^(checkForLeaks bitAnd: 4) ~= 0
]

{ #category : #'debug support' }
NewObjectMemory >> leakCheckFullGC [
	<api>
	^(checkForLeaks bitAnd: 1) ~= 0
]

{ #category : #'debug support' }
NewObjectMemory >> leakCheckIncrementalGC [
	<api>
	^(checkForLeaks bitAnd: 2) ~= 0
]

{ #category : #'image segment in/out' }
NewObjectMemory >> loadImageSegmentFrom: segmentWordArray outPointers: outPointerArray [
	"This primitive is called from Squeak as...
		<imageSegment> loadSegmentFrom: aWordArray outPointers: anArray."

"This primitive will load a binary image segment created by primitiveStoreImageSegment.  It expects the outPointer array to be of the proper size, and the wordArray to be well formed.  It will return as its value the original array of roots, and the erstwhile segmentWordArray will have been truncated to a size of zero.  If this primitive should fail, the segmentWordArray will, sadly, have been reduced to an unrecognizable and unusable jumble.  But what more could you have done with it anyway?"

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
	endSeg := segmentWordArray + (self sizeBitsOf: segmentWordArray) - BaseHeaderSize.

	"Version check.  Byte order of the WordArray now"
	data := self longAt: segmentWordArray + BaseHeaderSize.
	(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse:
		"Not readable -- try again with reversed bytes..."
		[self reverseBytesFrom: segmentWordArray + BaseHeaderSize to: endSeg + BytesPerWord.
		data := self longAt: segmentWordArray + BaseHeaderSize.
		(self readableFormat: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse:
			"Still NG -- put things back and fail"
			[self reverseBytesFrom: segmentWordArray + BaseHeaderSize to: endSeg + BytesPerWord.
			DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^0]].
	"Reverse the Byte type objects if the data is from opposite endian machine.
	 Revese the words in Floats if from an earlier version with different Float order.
	 Test top byte.  $d on the Mac or $s on the PC.  Rest of word is equal."
	(data >> 16) = (self imageSegmentVersion >> 16)
		ifTrue:
			"Need to swap floats if the segment is being loaded into a little-endian VM from a version
			 that keeps Floats in big-endian word order as was the case prior to the 6505 image format."
			[(self isPlatformFloatOrderVersion: (data bitAnd: 16rFFFF "low 2 bytes")) ifFalse:
				[self vmEndianness ~= 1 "~= 1 => little-endian" ifTrue:
					[segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
					 self wordSwapFloatsFrom: segOop to: endSeg + BytesPerWord]]]
		ifFalse: "Reverse the byte-type objects once"
			[segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
				 "Oop of first embedded object"
			self byteSwapByteObjectsFrom: segOop
				to: endSeg + BytesPerWord
				flipFloatsIf: (self isPlatformFloatOrderVersion: (data bitAnd: 16rFFFF "low 2 bytes"))].

	"Proceed through the segment, remapping pointers..."
	segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
	[segOop <= endSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type = 0 or 1) -- start with that."
					fieldPtr := segOop - BytesPerWord.  doingClass := true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr := segOop + BaseHeaderSize.  doingClass := false].
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"
		lastPtr > endSeg ifTrue:
			[DoAssertionChecks ifTrue: [self verifyCleanHeaders].
			^0 "out of bounds"].

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
					fieldPtr := fieldPtr + BytesPerWord]
				ifFalse:
					[(fieldOop bitAnd: 3) = 0 ifFalse:
						[^0 "bad oop"].
					(fieldOop bitAnd: 16r80000000) = 0
						ifTrue: ["Internal pointer -- add segment offset"
								mapOop := fieldOop + segmentWordArray]
						ifFalse: ["External pointer -- look it up in outPointers"
								outPtr := outPointerArray + (fieldOop bitAnd: 16r7FFFFFFF).
								outPtr > lastOut ifTrue:
									[^0 "out of bounds"].
								mapOop := self longAt: outPtr].
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr := fieldPtr + 8.
								doingClass := false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr := fieldPtr + BytesPerWord].
					segOop < youngStart ifTrue:
						[self possibleRootStoreInto: segOop value: mapOop]]].
		segOop := self objectAfter: segOop].

	"Again, proceed through the segment checking consistency..."
	segOop := self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord.
	[segOop <= endSeg] whileTrue:
		[(self oopHasAcceptableClass: segOop) ifFalse:
			[^0 "inconsistency"].
		fieldPtr := segOop + BaseHeaderSize.		"first field"
		lastPtr := segOop + (self lastPointerOf: segOop).	"last field"
		"Go through all oops, remapping them..."
		[fieldPtr > lastPtr] whileFalse:
			["Examine each pointer field"
			fieldOop := self longAt: fieldPtr.
			(self oopHasAcceptableClass: fieldOop) ifFalse:
				[^0 "inconsistency"].
			fieldPtr := fieldPtr + BytesPerWord].
		segOop := self objectAfter: segOop].

	"Truncate the segment word array to size = BytesPerWord (vers stamp only)"
	extraSize := self extraHeaderBytes: segmentWordArray.
	hdrTypeBits := self headerType: segmentWordArray.
	extraSize = 8
		ifTrue: [self longAt: segmentWordArray-extraSize put: BaseHeaderSize + BytesPerWord + hdrTypeBits]
		ifFalse: [header := self longAt: segmentWordArray.
				self longAt: segmentWordArray
					put: header - (header bitAnd: SizeMask) + BaseHeaderSize + BytesPerWord].	
	"and return the roots array which was first in the segment"
	DoAssertionChecks ifTrue: [self verifyCleanHeaders].
	^self oopFromChunk: segmentWordArray + BaseHeaderSize + BytesPerWord
]

{ #category : #'debug printing' }
NewObjectMemory >> longPrintReferencesTo: anOop [
	"Scan the heap long printing the oops of any and all objects that refer to anOop"
	| oop i prntObj |
	<api>
	prntObj := false.
	oop := self firstAccessibleObject.
	[oop = nil] whileFalse:
		[((self isPointers: oop) or: [self isCompiledMethod: oop]) ifTrue:
			[(self isCompiledMethod: oop)
				ifTrue:
					[i := (self literalCountOf: oop) - 1]
				ifFalse:
					[(self isContext: oop)
						ifTrue: [i := CtxtTempFrameStart + (self fetchStackPointerOf: oop) - 1]
						ifFalse: [i := (self lengthOf: oop) - 1]].
			[i >= 0] whileTrue:
				[anOop = (self fetchPointer: i ofObject: oop) ifTrue:
					[self printHex: oop; print: ' @ '; printNum: i; cr.
					 prntObj := true.
					 i := 0].
				 i := i - 1].
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
	class := self fetchClassOfNonInt: address.
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
	"update interpreter variables"
	coInterpreter mapInterpreterOops.
	1 to: extraRootCount do:
		[:i | | oop |
		oop := (extraRoots at: i) at: 0.
		(self isIntegerObject: oop) ifFalse:
			[(extraRoots at: i) at: 0 put: (self remap: oop)]].
	coInterpreter flushMethodCacheFrom: memStart to: memEnd.
	self updatePointersInRootObjectsFrom: memStart to: memEnd.
	self updatePointersInRangeFrom: memStart to: memEnd
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
		(self isIntegerObject: oop) ifFalse:
			[self markAndTrace: oop]].
	statMarkCountPriorToStackPageFreeing := statMarkCount.
	"Only safe to free stack pages after all roots have been traced."
	self markAndTraceAndMaybeFreeStackPages: fullGCFlag.
	"Only safe to free any machine code methods after all
	 stack pages have been traced."
	self markAndTraceOrFreeMachineCode: fullGCFlag.
	statSpecialMarkCount := statSpecialMarkCount + (statMarkCount - statMarkCountPriorToStackPageFreeing)
]

{ #category : #accessing }
NewObjectMemory >> needGCFlag [
	^needGCFlag
]

{ #category : #accessing }
NewObjectMemory >> needGCFlag: aValue [
	^needGCFlag := aValue
]

{ #category : #allocation }
NewObjectMemory >> newObjectHash [
	"Derive the new object hash from the allocation pointer.  This is less costly than
	 using lastHash because it avoids the read-modify-write cycle to update lastHash.
	 Since the size of eden is a power of two and larger than the hash range this provides
	 a well-distributed and fairly random set of values."
	<inline: true>
	^freeStart >> ShiftForWord
]

{ #category : #accessing }
NewObjectMemory >> nilObject: anOop [
	"For mapInterpreterOops"
	nilObj := anOop
]

{ #category : #'garbage collection' }
NewObjectMemory >> noteAsRoot: oop headerLoc: headerLoc [ 
	"Record that the given oop in the old object area points to an 
	 object in the young area. HeaderLoc is usually = oop, but may
	 be an addr in a forwarding block."
	| header |
	<inline: true>
	<asmLabel: false> 
	header := self longAt: headerLoc.
	(header bitAnd: RootBit) = 0 ifTrue:
		"record oop as root only if not already recorded"
		[rootTableCount < RootTableSize ifTrue:
			"record root if there is enough room in the roots  table "
			[rootTableCount := rootTableCount + 1.
			 rootTable at: rootTableCount put: oop.
			 self longAt: headerLoc put: (header bitOr: RootBit).
			 rootTableCount > RootTableRedZone ifTrue:
				"if we're now in the red zone force an IGC ASAP"
				[self scheduleIncrementalGC]]]
]

{ #category : #'cog jit support' }
NewObjectMemory >> objectRepresentationClass [
	<doNotGenerate>
	^CogObjectRepresentationForSqueakV3
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
	((oop \\ BytesPerWord) = 0)
		ifFalse: [ self error: 'oop is not a word-aligned address'. ^false ].
	sz := self sizeBitsOf: oop.
	(oop + sz) < freeStart
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
		((oop >= BytesPerWord) and: [(self headerType: oop - BytesPerWord) = type])
			ifFalse: [ self error: 'class header word has wrong type'. ^false ].
	].
	type = HeaderTypeSizeAndClass ifTrue: [
		((oop >= (BytesPerWord*2)) and:
		 [(self headerType: oop - (BytesPerWord*2)) = type and:
		 [(self headerType: oop - BytesPerWord) = type]])
			ifFalse: [ self error: 'class header word has wrong type'. ^false ].
	].

	"format check"
	fmt := self formatOf: oop.
	((fmt = 5) | (fmt = 7))
		ifTrue:  [ self error: 'oop has an unknown format type'. ^false ].

	"mark and root bit checks"
	unusedBit := 16r20000000.
	BytesPerWord = 8
		ifTrue:
			[unusedBit := unusedBit << 16.
			 unusedBit := unusedBit << 16].
	((self longAt: oop) bitAnd: unusedBit) = 0
		ifFalse: [ self error: 'unused header bit 30 is set; should be zero'. ^false ].
"xxx
	((self longAt: oop) bitAnd: MarkBit) = 0
		ifFalse: [ self error: 'mark bit should not be set except during GC' ].
xxx"
	(((self longAt: oop) bitAnd: RootBit) = 1 and:
	 [oop >= youngStart])
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

	oop < freeStart ifFalse: [^ false].
	((oop \\ BytesPerWord) = 0) ifFalse: [^ false].
	(oop + (self sizeBitsOf: oop)) <= freeStart ifFalse: [^ false].
	oopClass := self cCoerce: (self fetchClassOfNonInt: oop) to: #usqInt.

	(self isIntegerObject: oopClass) ifTrue: [^ false].
	(oopClass < freeStart) ifFalse: [^ false].
	((oopClass \\ BytesPerWord) = 0) ifFalse: [^ false].
	(oopClass + (self sizeBitsOf: oopClass)) <= freeStart ifFalse: [^ false].
	((self isPointersNonInt: oopClass) and: [(self lengthOf: oopClass) >= 3]) ifFalse: [^ false].
	formatMask := (self isBytesNonInt: oop)
						ifTrue: [16rC00]  "ignore extra bytes size bits"
						ifFalse: [16rF00].

	behaviorFormatBits := (self formatOfClass: oopClass) bitAnd: formatMask.
	oopFormatBits := (self baseHeader: oop) bitAnd: formatMask.
	behaviorFormatBits = oopFormatBits ifFalse: [^ false].
	^ true
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
	entriesNeeded := (self lastPointerOf: array1) // BytesPerWord. "need enough entries for all oops"
	"Note: Forward blocks must be quadword aligned - see fwdTableInit:."
	twoWayFlag
		ifTrue: ["Double the number of blocks for two-way become"
			entriesNeeded := entriesNeeded * 2.
			fwdBlkSize := BytesPerWord * 2]
		ifFalse: ["One-way become needs backPointers in fwd blocks."
			fwdBlkSize := BytesPerWord * 4].
	entriesAvailable := self fwdTableInit: fwdBlkSize.
	entriesAvailable < entriesNeeded ifTrue:
		[self initializeMemoryFirstFree: freeStart.
		 "re-initialize the free block"
		 ^false].
	fieldOffset := self lastPointerOf: array1.
	[fieldOffset >= BaseHeaderSize] whileTrue:
		[oop1 := self longAt: array1 + fieldOffset.
		 oop2 := self longAt: array2 + fieldOffset.
		 "if oop1 == oop2, no need to do any work for this pair.
		  May still be other entries in the arrays though so keep looking"
		 oop1 = oop2 ifFalse:
			[fwdBlock := self fwdBlockGet: fwdBlkSize.
			 self
				initForwardBlock: fwdBlock
				mapping: oop1
				to: oop2
				withBackPtr: twoWayFlag not.
			twoWayFlag ifTrue: "Second block maps oop2 back to oop1 for two-way become"
				[fwdBlock := self fwdBlockGet: fwdBlkSize.
				 self
					initForwardBlock: fwdBlock
					mapping: oop2
					to: oop1
					withBackPtr: twoWayFlag not]].
		fieldOffset := fieldOffset - BytesPerWord].
	^true
]

{ #category : #'debug printing' }
NewObjectMemory >> printMemField: memField name: name size: length [
	<var: #memField type: #usqInt>
	<var: #name type: #'char *'>
	self print: name; tab; printHexPtr: memField;
		printChar: $/; printNum: (self oopForPointer: memField);
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

{ #category : #'debug printing' }
NewObjectMemory >> printObjectsFrom: startAddress to: endAddress [
	<api>
	| oop |
	oop := startAddress.
	[oop < endAddress] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[self printOop: oop].
		oop := self objectAfter: oop].
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
		tablePtr := tablePtr + BytesPerWord].
	tablePtr := firstOut.
	[self oop: tablePtr isLessThanOrEqualTo: lastOut] whileTrue:
		[oop := self longAt: tablePtr.
		header := self longAt: hdrBaseOut + (tablePtr-firstOut).
		self longAt: oop put: header.
		tablePtr := tablePtr + BytesPerWord].
	
	"Clear all mark bits"
	oop := self firstObject.
	[self oop: oop isLessThan: freeStart] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[self longAt: oop put: ((self longAt: oop) bitAnd: AllButMarkBit)].
		oop := self objectAfter: oop]
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

{ #category : #'garbage collection' }
NewObjectMemory >> runLeakCheckerForFullGC: fullGCFlag [
	<inline: false>
	(fullGCFlag
			ifTrue: [self leakCheckFullGC]
			ifFalse: [self leakCheckIncrementalGC]) ifTrue:
		[fullGCFlag
			ifTrue: [self reverseDisplayFrom: 0 to: 7]
			ifFalse: [self reverseDisplayFrom: 8 to: 15].
		 self clearLeakMapAndMapAccessibleObjects.
		 self assert: self checkHeapIntegrity.
		 self assert: self checkInterpreterIntegrity.
		 self assert: self checkStackIntegrity.
		 self assert: (self checkCodeIntegrity: fullGCFlag).
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
	^oop + sz >= freeStart
		ifTrue: [freeStart]
		ifFalse: [self oopFromChunk: oop + sz]
]

{ #category : #'debug printing' }
NewObjectMemory >> safePrintStringOf: oop [
	"Version of printStringOf: that copes with forwarding during garbage collection."
	| fmt header cnt i |
	<inline: false>
	(self isIntegerObject: oop) ifTrue:
		[^nil].
	(oop between: self startOfMemory and: freeStart) ifFalse:
		[^nil].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[^nil].
	header := self headerWhileForwardingOf: oop.
	fmt := self formatOfHeader: header.
	fmt < 8 ifTrue: [ ^nil ].

	cnt := 100 min: (self lengthOf: oop baseHeader: header format: fmt).
	i := 0.

	[i < cnt] whileTrue:
		[self printChar: (self fetchByte: i ofObject: oop).
		 i := i + 1].
	self flush.
	^oop
]

{ #category : #accessing }
NewObjectMemory >> scavengeThreshold [
	^scavengeThreshold
]

{ #category : #'garbage collection' }
NewObjectMemory >> scheduleIncrementalGC [
	<api>
	needGCFlag := true.
	self forceInterruptCheck
]

{ #category : #'debug support' }
NewObjectMemory >> setCheckForLeaks: anInteger [
	"0 = do nothing.
	 1 = check for leaks on fullGC.
	 2 = check for leaks on incrementalGC.
	 4 = check for leaks on become
	 7 = check for leaks on all three."
	checkForLeaks := anInteger
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

{ #category : #'header access' }
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

{ #category : #'header access' }
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
	firstOut := outPointerArray + BaseHeaderSize.
	lastOut := firstOut - BytesPerWord.
	hdrBaseOut := outPointerArray + ((self lastPointerOf: outPointerArray) // (BytesPerWord*2) * BytesPerWord). "top half"

	lastSeg := segmentWordArray.
	endSeg := segmentWordArray + (self sizeBitsOf: segmentWordArray) - BytesPerWord.

	"Write a version number for byte order and version check"
	versionOffset := BytesPerWord.
	lastSeg := lastSeg + versionOffset.
	lastSeg > endSeg ifTrue: [^PrimErrGenericFailure].
	self longAt: lastSeg put: self imageSegmentVersion.

	"Allocate top 1/8 of segment for table of internal oops and saved headers"
	firstIn := endSeg - ((self sizeBitsOf: segmentWordArray) // (BytesPerWord*8) * BytesPerWord).  "Take 1/8 of seg"
	lastIn := firstIn - BytesPerWord.
	hdrBaseIn := firstIn + ((self sizeBitsOf: segmentWordArray) // (BytesPerWord*16) * BytesPerWord). "top half of that"

	"First mark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitOr: MarkBit).
	lastPtr := arrayOfRoots + (self lastPointerOf: arrayOfRoots).
	fieldPtr := arrayOfRoots + BaseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop := self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitOr: MarkBit)].
		fieldPtr := fieldPtr + BytesPerWord].

	"Then do a mark pass over all objects.  This will stop at our marked roots,
	thus leaving our segment unmarked in their shadow."
	savedYoungStart := youngStart.
	youngStart := self startOfMemory.  "process all of memory"
	self markAndTraceInterpreterOops: false.	"and special objects array"
	youngStart := savedYoungStart.
	
	"Finally unmark the rootArray and all root objects."
	self longAt: arrayOfRoots put: ((self longAt: arrayOfRoots) bitAnd: AllButMarkBit).
	fieldPtr := arrayOfRoots + BaseHeaderSize.
	[fieldPtr <= lastPtr] whileTrue:
		[fieldOop := self longAt: fieldPtr.
		(self isIntegerObject: fieldOop) ifFalse:
			[self longAt: fieldOop put: ((self longAt: fieldOop) bitAnd: AllButMarkBit)].
		fieldPtr := fieldPtr + BytesPerWord].

	"All external objects, and only they, are now marked.
	Copy the array of roots into the segment, and forward its oop."
	lastIn := lastIn + BytesPerWord.
	(lastIn >= hdrBaseIn
	 or: [0 = (lastSeg := self copyObj: arrayOfRoots toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn))]) ifTrue:
		[lastIn := lastIn - BytesPerWord.
		self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
		^self primitiveFailCodeAfterCleanup: outPointerArray].

	"Now run through the segment fixing up all the pointers.
	Note that more objects will be added to the segment as we make our way along."
	segOop := self oopFromChunk: segmentWordArray + versionOffset + BaseHeaderSize.
	[segOop <= lastSeg] whileTrue:
		[(self headerType: segOop) <= 1
			ifTrue: ["This object has a class field (type=0 or 1) -- start with that."
					fieldPtr := segOop - BytesPerWord.  doingClass := true]
			ifFalse: ["No class field -- start with first data field"
					fieldPtr := segOop + BaseHeaderSize.  doingClass := false].
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
						fieldPtr := fieldPtr + BytesPerWord]
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
							lastIn := lastIn + BytesPerWord.
							(lastIn >= hdrBaseIn
							or: [0 = (lastSeg := self copyObj: fieldOop toSegment: segmentWordArray addr: lastSeg stopAt: firstIn saveOopAt: lastIn headerAt: hdrBaseIn + (lastIn - firstIn))]) ifTrue:
								["Out of space in segment"
								lastIn := lastIn - BytesPerWord.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^self primitiveFailCodeAfterCleanup: outPointerArray].
							mapOop := (self longAt: fieldOop) bitAnd: AllButTypeMask]
						ifFalse:
							["Points to a marked obj -- an external pointer.
							Map it as a tagged index in outPointers, and forward its oop."
							lastOut := lastOut + BytesPerWord.
							lastOut >= hdrBaseOut ifTrue:
								["Out of space in outPointerArray"
								lastOut := lastOut - BytesPerWord.
								self restoreHeadersFrom: firstIn to: lastIn from: hdrBaseIn and: firstOut to: lastOut from: hdrBaseOut.
								^self primitiveFailCodeAfterCleanup: outPointerArray].
.							mapOop := lastOut - outPointerArray bitOr: 16r80000000.
							self forward: fieldOop to: mapOop
								savingOopAt: lastOut andHeaderAt: hdrBaseOut + (lastOut - firstOut)]].
					"Replace the oop by its mapped value"
					doingClass
						ifTrue: [self longAt: fieldPtr put: mapOop + hdrTypeBits.
								fieldPtr := fieldPtr + (BytesPerWord*2).
								doingClass := false]
						ifFalse: [self longAt: fieldPtr put: mapOop.
								fieldPtr := fieldPtr + BytesPerWord]]].
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
		to: lastOut+BytesPerWord.
	"Adjust the size of the original as well as the free chunk."
	self longAt: lastOut+BytesPerWord
		put: outPointerArray + (self lastPointerOf: outPointerArray) - lastOut - extraSize + hdrTypeBits.
	self longAt: outPointerArray-extraSize
		put: lastOut - firstOut + (BytesPerWord*2) + hdrTypeBits.
	"Note that pointers have been stored into roots table"
	self beRootIfOld: outPointerArray.

	"Truncate the image segment..."
	"Copy the 3-word wordArray header to establish a free chunk."
	self transfer: 3
		from: segmentWordArray - extraSize
		to: lastSeg+BytesPerWord.
	"Adjust the size of the original as well as the free chunk."
	self longAt: segmentWordArray-extraSize
		put: lastSeg - segmentWordArray + BaseHeaderSize + hdrTypeBits.
	self longAt: lastSeg+BytesPerWord
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
	minFree := (lowSpaceThreshold + bytes + BaseHeaderSize + BytesPerWord - 1) bitClear: BytesPerWord - 1.

	"check for low-space"
	(self oop: freeStart + minFree isLessThanOrEqualTo: reserveStart) ifTrue:
		[^true].
	^self sufficientSpaceAfterGC: minFree
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
	self fwdTableInit: BytesPerWord*2.
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
					(self isWeakNonInt: oop) ifTrue: [self finalizeReference: oop].
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

{ #category : #simulation }
NewObjectMemory >> validate [
	"Validate all the objects in the heap.  This is a noop unless simulating, but is sent
	 so we need a null implementation when generating code."
	<cmacro: '() 0'>
	| oop prev |
	self interpreter transcript show: 'Validating...'.
	oop := self firstObject.
	[oop < freeStart] whileTrue:
		[self validate: oop.
		prev := oop.  "look here if debugging prev obj overlapping this one"
		oop := self objectAfter: oop].
	prev := prev.  "Don't offer to delete this please"
	self interpreter transcript show: 'done.'; cr
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
	nextChunk > freeStart ifTrue:
		[oop = freeStart ifFalse: [self halt]].
	(self headerType: nextChunk) = 0 ifTrue:
		[(self headerType: (nextChunk + (BytesPerWord*2))) = 0 ifFalse: [self halt]].
	(self headerType: nextChunk) = 1 ifTrue:
		[(self headerType: (nextChunk + BytesPerWord)) = 1 ifFalse: [self halt]].
	type = 2 ifTrue:
		["free block" ^ self].
	fmt := self formatOfHeader: header.
	cc := self compactClassIndexOfHeader: header.
	cc > 16 ifTrue: [self halt].	"up to 32 are legal, but not used"
	type = 0 ifTrue:
		["three-word header"
		((self longAt: oop-BytesPerWord) bitAnd: 3) = type ifFalse: [self halt].
		((self longAt: oop-(BytesPerWord*2)) bitAnd: 3) = type ifFalse: [self halt].
		((self longAt: oop-BytesPerWord) = type) ifTrue: [self halt].	"Class word is 0"
		sz = 0 ifFalse: [self halt]].
	type = 1 ifTrue:
		["two-word header"
		((self longAt: oop-BytesPerWord) bitAnd: 3) = type ifFalse: [self halt].
		cc > 0 ifTrue: [sz = 1 ifFalse: [self halt]].
		sz = 0 ifTrue: [self halt]].
	type = 3 ifTrue:
		["one-word header"
		cc = 0 ifTrue: [self halt]].
	fmt = 5 ifTrue: [self halt].
	fmt = 7 ifTrue: [self halt].
	fmt >= 12 ifTrue:
		["CompiledMethod -- check for integer header"
		(self isIntegerObject: (self longAt: oop + BytesPerWord)) ifFalse: [self halt]].
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

{ #category : #'image segment in/out' }
NewObjectMemory >> wordSwapFloatsFrom: startOop to: stopAddr [
	"Swap the most and least significant words of Floats in a range of the image."
	| oop temp |
	oop := startOop.
	[self oop: oop isLessThan: stopAddr] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[((self formatOf: oop) = 6
			 and: [(self compactClassIndexOf: oop) = ClassFloatCompactIndex]) ifTrue:
				[temp := self longAt: oop + BaseHeaderSize.
				 self longAt: oop + BaseHeaderSize put: (self longAt: oop + BaseHeaderSize + 4).
				 self longAt: oop + BaseHeaderSize + 4 put: temp]].
		oop := self objectAfter: oop]
]

{ #category : #'cog jit support' }
NewObjectMemory >> youngStart [
	<cmacro: '() GIV(youngStart)'>
	^youngStart
]
