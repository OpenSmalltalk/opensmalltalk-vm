"
SpurMemoryManager is a new object representation and garbage collector for the Cog VM's.  Spur is dedicated to Andreas Raab, friend and colleague.  I miss you, Andreas.  The goal for Spur is an overall improvement in Cog of -50% (twice as fast) for memory-intensive benchmarks.

A detailed design sketch is included below after the instance variable descriptions.  The instance variable declarations can be checked for extra and missing declarations by making a literal array out of them and using
	(| ivs |
	ivs := (#(becomeEffectsFlags		<Integer> ...) piecesCutWhere: [:a :b| a = #>]) collect: [:ea| ea first].
	{ivs reject: [:iv| SpurMemoryManager instVarNames includes: iv].
	(SpurMemoryManager instVarNames reject: [:iv| ivs includes: iv]) sort})
The instance variable descriptions can be checked for extra and missing declarations by making a literal string out of them and using
	(| ivs |
	ivs := ('becomeEffectsFlags...' piecesCutWhere: [:a :b| a = Character cr]) select: [:s| s notEmpty and: [s first isLetter]] thenCollect: [:ea| ea withoutTrailingBlanks].
	{ivs reject: [:iv| SpurMemoryManager instVarNames includes: iv].
	(SpurMemoryManager instVarNames reject: [:iv| ivs includes: iv]) sort})

Instance Variables
	becomeEffectsFlags		<Integer>
	bogon						<Integer oop>
	checkForLeaks				<Boolean>
	classTableFirstPage		<Integer oop>
	classTableIndex			<Integer>
	coInterpreter				<StackInterpreter|CoInterpreter (StackInterpreterSimulator|CogVMSimulator)>
	compactionStartUsecs		<Integer>
	compactor					<subclass of SpurCompactor>
	edenBytes					<Integer>
	endOfMemory				<Integer address>
	mournQueue			<Integer objStack oop>
	extraRootCount			<Integer>
	extraRoots					<Array of: oop>
	falseObj					<Integer oop>
	freeLists					<CArray on: memory>
	freeListsMask				<Integer>
	freeOldSpaceStart			<Integer address>
	freeStart					<Integer address>
	gcStartUsecs				<Integer>
	growHeadroom				<Integer>
	heapMap					<CogCheck32BitHeapMap>
	hiddenRootsObj			<Integer oop>
	heapGrowthToSizeGCRatio	<Float>
	heapSizeAtPreviousGC		<Integer>
	invalidObjStackPage		<Integer oop|nil>
	lastHash					<Integer>
	lowSpaceThreshold		<Integer address>
	marking					<Boolean>
	markStack					<Integer objStack oop>
	maxOldSpaceSize			<Integer>
	memory					<Bitmap|LittleEndianBitmap>
	needGCFlag				<Boolean>
	newSpaceLimit				<Integer address>
	newSpaceStart				<Integer address>
	nilObj						<Integer oop>
	numClassTablePages		<Integer>
	objStackInvalidBecause	<String|nil>
	oldSpaceStart				<Integer address>
	oldSpaceUsePriorToScavenge	<Integer>
	pastSpaceStart				<Integer address>
	remapBuffer				<CArrayAccessor on: (Array new: RemapBufferSize)>
	remapBufferCount			<Integer>
	scavengeThreshold		<Integer address>
	scavenger					<SourGenerationScavenger>
	segmentManager			<SpurSegmentManager>
	signalLowSpace			<Boolean>
	shrinkThreshold			<Integer>
	specialObjectsOop			<Integer oop>
	statCoalesces				<Integer>
	statCompactPassCount		<Integer>
	statFGCDeltaUsecs			<Integer>
	statFullGCUsecs			<Integer>
	statFullGCs					<Integer>
	statGCEndUsecs			<Integer>
	statGrowMemory			<Integer>
	statIGCDeltaUsecs			<Integer>
	statIncrGCUsecs			<Integer>
	statIncrGCs					<Integer>
	statMarkCount				<Integer>
	statRootTableCount		<Integer>
	statRootTableOverflows	<Integer>
	statSGCDeltaUsecs		<Integer>
	statScavengeGCUsecs		<Integer>
	statScavenges				<Integer>
	statShrinkMemory			<Integer>
	totalFreeOldSpace			<Integer>
	trueObj						<Integer oop>
	unscannedEphemerons		<SpurContiguousObjStack>
	weaklingStack				<Integer objStack oop>

becomeEffectsFlags
	- a set of flags to limit the work done during become; one of BecameCompiledMethodFlag, BecamePointerObjectFlag

bogon
	- an oop that can be checked for.  Currently allObjectsUnmarked sets it to the first marked object found.

checkForLeaks
	- a set of flags determining when to run leak checks on the heap's contents

classTableFirstPage
	- the first page of the class table which contains all classes known to the VM at known indices

classTableIndex
	- the last known used index in the class table, used to limit the search for empty slots

coInterpreter
	- the VM interpreter using this heap

compactionStartUsecs
	- the microsecond clock value immediatel;y before a cmpaction p[hase starts.  For primitiveVMParameter reporting of time spent in the mark and compaction phases of full GC.

compactor
	- the compactor that compacts oldSpace

edenBytes
	- a variable holding the size of eden at start up only

endOfMemory
	- the address past the last oldSpace segment

mournQueue
	- the oopStack holding triggered ephemerons, and, depending on finalization scheme, bereaved weak arrays

extraRootCount
	- the count of extra roots

extraRoots
	- an array of pointers to variables holding oops that need updating.  used by plugins to update objects they hold on to.

falseObj
	- the oop of the false object; must be the second object in oldSpace

freeLists
	- an array of list heads of free chunks of each size (in allocationUnits).  the 0'th element
	  is the head of a tree of free chunks of size > 63 slots in 64-bits or 31 slots in 32-bits.
	  freeLists is the firstIndexableField of the fourth object in oldSpace.

freeListsMask
	- a bitmap of flags with a 1 set whereever the freeLists has a non-empty entry, used to limit the search for free chunks

freeOldSpaceStart
	- the last used address in oldSpace.  The space between freeOldSpaceStart and endOfMemory can be used for oldSpace allocations.
	  Given freeLists this probably isn't useful and shoud be discarded in favour of endOfMemory.

freeStart
	- the last used address in eden.  this is where new objects are allocated if there is room in eden.

gcPhaseInProgress
	- flag taking values 0, ScavengeInProgress, SlidingCompactionInProgress, for remapObj: to decide what to do.

gcStartUsecs
	- the time in microseconds of the start of the most recent gc, used to compute the duration of a gc.

growHeadroom
	- the minimum ammount of space to grow memory by when a grow is required.

heapMap
	- a bitmap used to check for leaks. a bit is set in the map at each object's header.  every pointer in the heap should point to the header of an object

heapGrowthToSizeGCRatio
	- determines how much heap growth since heapSizeAtPreviousGC at which a full GC will be performed after a scavenge.  This is a stop gap measure running the full GC occasionally until we have implemented an incremental scan-mark-compact GC.

heapSizeAtPreviousGC
	- the size of the heap at the most recent GC, used to decide if a full GC is needed after a scavenge.  See heapGrowthToSizeGCRatio.

hiddenRootsObj
	- the root page of the class table and some other roots (e.g. the mourn queue). its first
	  numClassTablePages elements are pages containing classes. Remaining slots hold other
	  roots the VM needs.  Must be the fifth object in oldSpace.

invalidObjStackPage
	- the offending objStack page, if isValidObjStack: failed, or nil. This is for debugging.

lastHash
	- the last object hash value.  the seed to the pseudo-random number generator for identity hashes.

lowSpaceThreshold
	- the ammount of free memory below which the low space condition should be signalled.

marking
	- a flag set and cleared in markAccessibleObjects to allow ensureRoomOnObjStackAtIndex: to know whether to mark a new obj stack page or not.

markStack
	- the objStack that houses the mark stack.

maxOldSpaceSize
	- the maximum allowed size of old space in bytes.  If zero, there is no limit.

memory
	- in the Simulator this is the single oldSpace segment that contains the codeZone, newSpace and oldSpace.  In C it is effectively the base address of used memory.

needGCFlag
	- a boolean flag set if a scavenge is needed

newSpaceStart
	- the first address in newSpace (the start address of the first of the two survivor spaces, past and future space)

newSpaceLimit
	- the last address in newSpace (the last address in eden)

nilObj
	- the oop of the nil object; must be the first object in oldSpace

numClassTablePages
	- the number of used pages in the classTable

objStackInvalidBecause
	- a string identifying the reason isValidObjStack: failed, or nil.  This is for debugging.

oldSpaceStart
	- the start of oldSpace, which happens to be nilObj.

oldSpaceUsePriorToScavenge
	- a count of oldSpace occupation prior to a scavenge, used to maintain an accurate byte allocation count from start-up.

pastSpaceStart
	- the address past the last object in pastSpace, used to enumerate objects in newSpace.

remapBuffer
	- an Array of objects used to implement pushRemappableOop: et al for compatibility with ObjectMemory.
	  Its functionality isnt needed because Spur will never GC during allocation.  But it muts be present and
	  correct, otherwise many primitives that use pushRemappableOop: et al would have to be rewritten.

remapBufferCount
	- the index of the last used entry in remampBuffer

scavengeThreshold
	- a tidemark in eden.  needGCFlag is set if a newSpace allocation pushes freeStart past scavengeThreshold

scavenger
	- the generation scavenger that collects objects in newSpace

segmentManager
	- the object that manages oldSpace segments.  Segments are largely invisible to the memory manager because
	  the gaps between segments are hidden by bridge objects.

shrinkThreshold
	- the amount of free oldSpace above which the manager should attempt to give memory back to the OS.

signalLowSpace
	- a boolean flag set if the lowSpaceSemaphore should be signalled

specialObjectsOop
	- the oop of the specialObjectsArray object

statCoalesces statCompactPassCount statFGCDeltaUsecs statFullGCUsecs statFullGCs statGCEndUsecs statGrowMemory statIGCDeltaUsecs statIncrGCUsecs statIncrGCs statMarkCount statRootTableCount statRootTableOverflows statSGCDeltaUsecs statScavengeGCUsecs statScavenges statShrinkMemory statSpecialMarkCount statSurvivorCount
	- various statistics

totalFreeOldSpace
	- the total free space on the free lists
	
trueObj
	- the oop of the false object; must be the third object in oldSpace

unscannedEphemerons
	- the set of ephemerons yet to be scanned.  used for identifying firable ephemerons during gc.

weaklingStack
	- the set of weak collections that must be scanned later on in gc to nil their collected referents.



Invariants (far from an exhaustive list; I'm adding to this as they arise; please prompt me to add undocumented ones):

On image load no object contains a forwarding pointer, and the image contains no forwarders. True because
a) the SpurBootstrap eliminates forwarders before saving its transformed image
b) snapshot does a fullGC which will follow forwarding pointers.
This is checked with an assert in swizzleFieldsOfObject:/lastPointerOfWhileSwizzling:.

classTableIndex ranges from classTablePageSize to classTableMask, since the first page is reserved for system classes, and the VM won't assign classes there-in.

Design
The design objectives for the Spur memory manager are

- efficient object representation a la Eliot Miranda's VisualWorks 64-bit object representation that uses a 64-bit header, eliminating direct class references so that all objects refer to their classes indirectly.  Instead the header contains a constant class index, in a field smaller than a full pointer, These class indices are used in inline and first-level method caches, hence they do not have to be updated on GC (although they do have to be traced to be able to GC classes).  Classes are held in a sparse strong table.  The class table needs only to be indexed by an instance's class index in class hierarchy search, in the class primitive, and in tracing live objects in the heap.  The additional header space is allocated to a much expanded identity hash field, reducing hash efficiency problems in identity collections due to the extremely small (11 bit) hash field in the old Squeak GC.  The identity hash field is also a key element of the class index scheme.  A class's identity hash is its index into the class table, so to create an instance of a class one merely copies its identity hash into the class index field of the new instance.  This implies that when classes gain their identity hash they are entered into the class table and their identity hash is that of a previously unused index in the table.  It also implies that there is a maximum number of classes in the table.  The classIndex field could be as narrow as 16 bits (for efficient access); at least for a few years 64k classes should be enough.  But currently we make it the same as the identityHash field, 22 bits, or 4M values.  A class is entered into the class table in the following operations:
	behaviorHash
	adoptInstance
	instantiate
	become  (i.e. if an old class becomes a new class)
		if target class field's = to original's id hash
		   and replacement's id hash is zero
			enter replacement in class table
behaviorHash is a special version of identityHash that must be implemented in the image by any object that can function as a class (i.e. Behavior).

The object representaion must also be simple enough to allow more operations (especially array at:put: and object instantiation to be implemented by the JIT in machine code.  The current Squea object representtion with three different header sizes and two different size formats has discouraged this.

- substantial commonality between 32-bit and 64-bit Implemetations
While the 32-bit and 64-bit implementations are different (32-bits per slot vs 64-bits per slot), the fact that the object header is 64-bit and common between them and that object lengths are rounded up to 64-bits means that most of the memory manager code is common.  As of 9/18/2014:

	SpurMemoryManager selectors size 765
	(SpurMemoryManager selectors reject: [:s| (SpurMemoryManager >> s) messages asArray = #(subclassResponsibility)]) size 721
	Spur32BitMemoryManager selectors size 46
	Spur64BitMemoryManager selectors size 44 (two selectors remaining to be implemented)

In fact the object header looks like

	 MSB:	| 8: numSlots		| (on a byte boundary)
			| 2 bits				|	(msb,lsb = {isMarked,?})
			| 22: identityHash	| (on a word boundary)
			| 3 bits				|	(msb <-> lsb = {isGrey,isPinned,isRemembered}
			| 5: format			| (on a byte boundary)
			| 2 bits				|	(msb,lsb = {isImmutable,?})
			| 22: classIndex		| (on a word boundary) : LSB
					
with the two unused bits being next to the 22-bit classIndex and identityHash fields, allowing expansion there-of.


- more immediate classes.  An immediate Character class would speed up String accessing, especially for WideString, since no instantiation needs to be done on at:put: and no dereference need be done on at:.  In a 32-bit system tag checking is complex since it is thought important to retain 31-bit SmallIntegers.  Hence, as in current Squeak, the least significant bit set implies a SmallInteger, but Characters would likely have a tag pattern of xxx10.  Hence masking with 11 results in two values for SmallInteger, xxx01 and xxx11 (for details see In-line cache probe for immediates below).  30-bit characters are more than adequate for Unicode.  In a 64-bit system we can use the full three bits and usefully implement an immediate Float.  As in VisualWorks a functional representation takes three bits away from the exponent.  Rotating to put the sign bit in the least significant non-tag bit makes expanding and contracting the 8-bit exponent to the 11-bit IEEE double exponent easy and makes comparing negative and positive zero easier (an immediate Float is zero if its unsigned 64-bits are < 16).  So the representation looks like
	| 8 bit exponent | 52 bit mantissa | sign bit | 3 tag bits |
For details see ""60-bit immediate Floats"" below.


- efficient scavenging.  The current Squeak GC uses a slow pointer-reversal collector that writes every field in live objects three times in each collection, twice in the pointer-reversing heap traversal to mark live objects and once to update the pointer to its new location.  A scavenger writes every field of live data twice in each collection, once as it does a block copy of the object when copying to to space, once as it traverses the live pointers in the to space objects.  Of course the block copy is a relatively cheap write.

- lazy become.  Squeak uses direct pointers and Spur retains them.  The JIT's use of inline cacheing provides a cheap way of avoiding scanning the heap as part of a become (which is the simple approach to implementing become in a system with direct pointers).  A becomeForward: on a (set of) non-zero-sized object(s) turns the object into a ""forwarder"" whose first (non-header) word/slot is replaced by a pointer to the target of the becomeForward:.  The forwarder's class index is set to one that identifies fowarders (in fact classIndex 8), and, because it is a special, hidden class index, will always fail an inline cache test.  The inline cache failure code is then responsible for following the forwarding pointer chain (these are Iliffe vectors :) ) and resolving to the actual target.  The system has two main faults, that for a forwarded selector and that for a forwarded receiver.  For the former we want to unforward the current method and for the latter we want to unforward the current frame  See become read barrier below on how we deal with becomes on objects with named inst vars.  We insist that objects are at least 16 bytes in size (see 8-byte alignment below) so that there will always be space for a forwarding pointer.  Since none of the immediate classes can have non-immediate instances and since we allocate the immediate class indices corresponding to their tag pattern (in 32-bits, SmallInteger = 1 & 3, Character = 2; in 64-bits, SmallInteger = , Character = 2, SmallFloat = 4) we can use all the class indices from 0 to 7 for special uses, 0 = free, and e.g. 1 = isForwarded.  In general what's going on here is the implemention of a partial read barrier. Certain operations require a read barrier to ensure access of the target of the forwarder, not the forwarder itself.  Read barriers stink (have poor performance), so we must restrict the read barrier to as few places as possible.  See become read barrier below.  See http://www.mirandabanda.org/cogblog/2013/09/13/lazy-become-and-a-partial-read-barrier/ & http://www.mirandabanda.org/cogblog/2014/02/08/primitives-and-the-partial-read-barrier/.  But we avoid the cost of a read barrier in almost all cases by folding that forwarding check into a dynamic type check that is performwed anyway (sends) or a validation check (primitives checking their arguments).  In the case of a send, or a primitive, the failure handling code checks for forwarders, follow any if found, and if any are found, retries either the send or the primitive.

- pinning.  To support a robust and easy-to-use FFI the memory manager must support temporary pinning where individual objects can be prevented from being moved by the GC for as long as required, either by being one of an in-progress FFI call's arguments, or by having pinning asserted by a primitive (allowing objects to be passed to external code that retains a reference to the object after returning).  Pinning probably implies a per-object ""is-pinned"" bit in the object header.  Objects are only pinnable in old space.  Pinning of new space objects is done via lazy become; i..e an object in new space is forwarded to a pinned copy of the object in old space.

- efficient old space collection.  An incremental collector (a la Dijkstra's three colour algorithm) collects old space, e.g. via an amount of tracing being hung off scavenges and/or old space allocations at an adaptive rate that keeps full garbage collections to a minimum.  It may also be possible to provide cheap compaction by using lazy become: and best-fit (see free space/free list below). [This remains to be implemented].

- 8-byte alignment.  It is advantageous for the FFI, for floating-point access, for object movement and for 32/64-bit compatibility to keep object sizes in units of 8 bytes.  For the FFI, 8-byte alignment means passing objects to code that expects that requirement (such as modern x86 numeric processing instructions).  This implies that
	- the starts of all spaces are aligned on 8-byte boundaries
	- object allocation rounds up the requested size to a multiple of 8 bytes
	- the overflow size field is also 8 bytes

- heap segmentation. This allows incremental heap growth (the current Squeak VM requires a contiguous chunk of memory, meaning an unfortunate trade off between space for objects and space for external code), and returning memory to the OS after GC.

- no GC in any allocation.  In V3, the previous memory manager, any allocation other than the eeInstantiate... API I introduced for ""execution engine"" allocations, may cause a GC.  Consequently primitive smust use the clumsy and inefficient remapBuffer to store oops around allocations.  In Spur, no allocation can cause a GC, consequently primitives need not waste time or effort with the remapBuffer.  The primitive retry machinery is used to retry prmitives that fail with a PrimErrNoMemory error after a GC.  Currently we do this for plugin primitives, not core numbered primitives; the core numbered primities that do alloate are specifically designed to fail on allocation failure, allowing image-level code to control running the GC.
	

Object Size
We keep the minimum object size at 16 bytes so that there is always room for a forwarding pointer.  This implies we cannot support free chunks of 8 bytes in length and that the memory manager refuses to split objects when doing so would leave an 8-byte sliver.  We can do this using a special class index, e.g. 1, so that the method that answers the size of an object looks like

	rawNumSlotsOf: objOop
		^self byteAt: objOop + 7

	rawOverflowSlotsOf: objOop
		^self long32At: objOop - self baseHeaderSize

	numSlotsOf: objOop
		| numSlots |
		numSlots := self rawNumSlotsOf: objOop..
		^numSlots = self numSlotsMask	""overflow slots; (2^32)-1 slots are plenty""
			ifTrue: [self rawOverflowSlotsOf: objOop]
			ifFalse: [numSlots]

Note that the size field of an object (its slot size) reflects the logical size of the object e.g. 0-element array => 0 slot size, 1-element array => 1 slot size). The memory manager rounds up the slot size as appropriate, e.g. (self roundUp: (self slotSizeOf: obj) * 4 to: 8) min: 8 to obtain a byte size.

	bytesInObject: objOop
		| headerNumSlots numSlots |
		headerNumSlots := self rawNumSlotsOf: objOop.
		numSlots := headerNumSlots = self numSlotsMask
						ifTrue: [self rawOverflowSlotsOf: objOop]
						ifFalse: [headerNumSlots = 0 ifTrue: [1] ifFalse: [headerNumSlots]].
		^numSlots + (numSlots bitAnd: 1) << self shiftForWord
		+ (headerNumSlots = self numSlotsMask
			ifTrue: [self baseHeaderSize + self baseHeaderSize]
			ifFalse: [self baseHeaderSize])

Heap growth and shrinkage is handled by allocating and deallocating heap segments from/to the OS via e.g. memory-mapping.  This technique allows space to be released back to the OS by unmapping empty segments.  See ""Segmented Old Space"" below).

The basic approach is to use a fixed size new space and a segmented, growable old space.  The new space is a classic three-space nursery a la Ungar's Generation Scavenging, a large eden for new objects and two smaller survivor spaces that exchange roles on each collection, one being the to space to which surviving objects are copied, the other being the from space of the survivors of the previous collection, i.e. the previous to space.  (This basic algorithm is extended to handle weak arrays and ephemerons).

To provide apparent pinning in new space we rely on lazy become.  Since most pinned objects will be byte data and these do not require stack zone activation scanning, the overhead is simply an old space allocation and forwarding.

To provide pinning in old space, objects hav their ""is pinned"" bit set in the object header (which could be set automaticaly when allocating a large object).  Compaction moves objects from high memory down to low memory using forwarders, and stepping over pinned objects (see Compact below).

Free space in old space is organized by a number of free lists and a free tree.  There are 32 or 64 free lists, depending on word size, indices 1 through wordSize - 1 holding blocks of space of the index * allocationUnit, index 0 holding a semi-balanced ordered tree of free blocks, each node being the head of the list of free blocks of that size.  At the start of the mark phase the free list is thrown away and the sweep phase coalesces free space and reclaimed forwarders, stepping over pinned objects as it proceeds.  We can reuse the forwarding pointer compaction scheme used in the old collector for incremental collections.  Incremental collections merely move unmarked objects to the free lists (as well as nilling weak pointers in weak arrays and scheduling them for finalization).  The occupancy of the free lists is represented by a bitmap in an integer so that an allocation of size wordSize - 1 or less can know whether there exists a free chunk of that size, but more importantly can know whether a free chunk larger than it exists in the fixed size free lists without having to search all larger free list heads.

Incremental Old Space Collection
The (as yet unimplemented) incremental collector (a la Dijkstra's three colour algorithm) collects old space via an amount of tracing being hung off scavenges and/or old space allocations at an adaptive rate that keeps full garbage collections to a minimum.  [N.B. Not sure how to do this yet.  The incremental collector needs to complete a pass often enough to reclaim objects, but infrequent enough not to waste time.  So some form of feedback should work.  In VisualWorks tracing is broken into quanta or work where image-level code determines the size of a quantum based on how fast the machine is, and how big the heap is.  This code could easily live in the VM, controllable through vmParameterAt:put:.  An alternative would be to use the heartbeat to bound quanta by time.  But in any case some amount of incremental collection would be done on old space allocation and scavenging, the ammount being chosen to keep pause times acceptably short, and at a rate to reclaim old space before a full GC is required, i.e. at a rate proportional to the growth in old space]. The incemental collector is a state machine, being either marking, nilling weak pointers, or freeing.  If nilling weak pointers is not done atomically then there must be a read barrier in weak array at: so that reading from an old space weak array that is holding stale un-nilled references to unmarked objects.  Tricks such as including the weak bit in bounds calculations can make this cheap for non-weak arrays.  Alternatively nilling weak pointers can be made an atomic part of incremental collection, which can be made cheaper by maintaining the set of weak arrays (e.g. on a list).  Note that the incremental collector also follows (and eliminates) forwarding pointers as it scans.

The incremental collector implies a more complex write barrier.  Objects are of three colours, black, having been scanned, grey, being scanned, and white, unreached.  A mark stack holds the grey objects.   If the incremental collector is marking and an unmarked white object is stored into a black object then the stored object must become grey, being added to the mark stack.  So the wrte barrier is essentially
	target isYoung ifFalse:
		[newValue isYoung
			ifTrue: [target isInRememberedSet ifFalse:
					[target addToRememberedSet]] ""target now refers to a young object; it is a root for scavenges""
			ifFalse:
				[(target isBlack
				  and: [igc marking
				  and: [newValue isWhite]]) ifTrue:
					[newValue beGrey]]] ""add newValue to IGC's markStack for subsequent scanning""

The incremental collector does not detect already marked objects all of whose references have been overwritten by other stores (e.g. in the above if newValue overwrites the sole remaining reference to a marked object).  So the incremental collector only guarantees to collect all garbage created in cycle N at the end of cycle N + 1.  The cost is hence slightly worse memory density but the benefit, provided the IGC works hard enough, is the elimination of long pauses due to full garbage collections, which become actions of last resort or programmer desire.

Compaction:
The main issue with compaction is handling pinned objects.  Our first two attempts, Incremental Best-Fit Compaction and Pig Compact, performed abysmally.  The current compaction algorithms are SpurPlanningCompactor, and SpurSelectiveCompactor.

Incremental Best-Fit Compaction
[A Failure]
The free list also looks like it allows efficient incremental compaction.  Currently in the 32-bit implementation, but easily affordable in the 64-bit implementation, objects have at least two fields, the first one being a forwarding pointer, the second one rounding up to 8-byte object alignment.  On the free list the first field is used to link the list of free chunks of a given size.  The second field could be used to link free chunks in memory order.  And of course the last free chunk is the chunk before the last run of non-free objects.  We compact by

a) keeping each free list in memory order (including the lists of free chunks off each node in the large free chunk tree)
b) sorting the free chunks in memory order by merge sorting the free lists
c) climbing the free list in memory order.  For each free chunk in the free list search memory from the last free chunk to the end (and from the previous chunk to the next chunk, and so on) looking for a best-fit live object.  That object is then copied into the free chunk, and its corpse is turned into a forwarding pointer.  This works because the compaction does not slide objects, and hence no forwarding blocks are necessary and the algorithm can be made incremental. Various optimizations are possible, e.g. using a bitmap to record the sizes of the first few free chunks on the list when looking for best fits.  The assumptions being
a) the number of objects on the free list is kept small because the IGC incrementally compacts, and so sorting and searching the list is not expensive
b) the incremental collector's following of forwarding pointers reclaims the corpses at the end of memory at a sufficient rate to keep the free list small
c) the rounding of objects to an 8-byte alignment improves the chances of finding a best fit.
Note that this incremental collection is easily amenable to leave pinned objects where they are; they are simply filtered out when looking for a best fit.

Pig Compact
[Another failure]
Pig Compact was an eager algorithm that moved as many objects for the top of memory to the bottom of memory as possible.  We called this ""Pig"" compact, and it was used as the compactor for global mark/sweep, used at least on snapshot.  Free memory was linked in memory ascending order through the first field, using the xor pointer trick to implement a doubly-linked list through a single field.  [Note this design was chosen for the benefit of the 64-bit image where there really is only one spare field.  In the 32-bit system there are at least two fields and the code could be simplified.].  With the doubly-linked list we can access objects at the top of memory by scanning up from the end of the list, and can move objects down into the free space at the front of the list, forwarding objects to their new locations.  Pinned objects are simply left where they are.  After a single pass there will be many forwarders at the top of memory and it will not have been compacted very much.  Memory is then swept to follow forwarders, and then again to free forwarders and coallesce free space.  The entire process is repeated (currently 3 times) to effectively compact memory.  Performance is dreadful.

Planning Compaction
This is an efficient algorithm for full GC, especially snapshot, where we want to fully compact the heap.  See SpurPlanningCompactor.  It uses the fact that there is room for a forwarding pointer in all objects to store the eventual position of an object in the first field.  It therefore first locates a large free chunk, or eden or a memory segment, and uses this to store the first fields of objects that will be compacted.  It then makes at least three passes through the heap.  The first pass plans where live movable objects will go, copying their first field to the next slot in savedFirstFieldsSpace, and setting their forwarding pointer to point to their eventual location.  The second pass updates all pointers in live pointer objects to point to objects' final destinations, including the fields in savedFirstFieldsSpace.  The third pass moves objects to their final positions, unmarking objects as it does so.  If the forwarding fields of live objects in the to-be-moved portion of the entire heap won't fit in savedFirstFieldsSpace, then additional passes are made until the entire heap has been compacted.  Each pass uses a three finger algorithm, a simple extension of the classic two finger algorithm with an extra finger used to identify the lowest pinned object between the to and from fingers.  Objects are moved down, starting at the first free object or chunk, provided that they fit below the lowest pinned object above the to finger.  When an object won't fit the to finger is moved above the pinned object and the third finger is reset to the next pinned object below the from finger, if any.

Segmented Old Space via Bridges
A segmented oldSpace is useful.  It allows growing oldSpace incrementally, adding a segment at a time, and freeing empty segments.  But such a scheme is likely to introduce complexity in object enumeration, and compaction (enumeration would apear to require visiting each segment, compaction must be wthin a segment, etc). Spur turns segmented old space into one that appears to be a single contiguous space by using fake pinned objects to bridge the gaps between segments.  We call these ""bridges"".  The last two words of each segment can be used to hold the header of a pinned object whose overflow size is the distance to the next segment.  The pinned object's classIndex is one of the puns so that it doesn't show up in allInstances or allObjects; this can perhaps also indicate to the incremental collector that it is not to reclaim the object, etc.  Bridge objects need a large enough overflow size field to stretch across large gaps in the address space.  This is no problem in the 32-bit system which has a 32-bit overflow slot coult, 4 times larger than necessary.  But the 64-bit sytsem only has a 56 bit overflow slot count, 5 bits short of spanning a full 64-bit address space.  We expect that this is adequate if we preferrentially allocate segments at one end of the address space or the other (in fact we try and allocate low).


Lazy Become & the Partial Read Barrier
see http://www.mirandabanda.org/cogblog/2013/09/13/lazy-become-and-a-partial-read-barrier/ & http://www.mirandabanda.org/cogblog/2014/02/08/primitives-and-the-partial-read-barrier/.

As described earlier the basic idea behind lazy become is to use forwarding objects that are followed lazily during GC and inline cache miss (message send).  However, a lazy scheme would appear to require a read barrier to avoid accessing the forwarder and make sure the forwarding pointer is followed.  Without hardware support read barriers have poor performance (at least in code density), so we try and avoid the read barrier as much as possible.  The main goals are a) to avoid having to scan all of the heap to fix up pointers, as is done with ObjectMemory, and b) to avoid a read barrier on inst var read, class access, etc.  We're happy to do some scanning of a small subset of the heap, but become: cannot scale to large heaps if it must scan the entire heap.  Objects with named inst vars and CompiledMethods are accessed extensively by the interpreter and jitted code.  We must avoid as much checking of such accesses as possible; We judge an explicit read barrier on all accesses far too expensive.  The accesses the VM makes which notionally require a read barrier are:
- inst vars of thisContext, including stack contents (the receiver of a message and its arguments), which in Cog are the fields of the current stack frame, and the sender chain during (possibly non-local) return
- named inst vars of the receiver
- literals of the current method, in particular variable bindings (a.k.a. literal variables which are global associations), including the methodClass association.
- in primitives, the receiver and arguments, including possible sub-structure.
We have already discussed that we will catch an attempt to create a new activation on a forwarded object through method lookup failing for forwarded objects.  This would occur when e.g. some object referenced by the receiver via its inst vars is pushed on the stack as a message receiver, or e.g. answered as the result of some primitive which accesses object state such as primtive at:  So there is no need for a read barrier when accessing a new receiver or returning its state.  But there is a read barrier in primitives that inspect that sub-state.

We avoid a read barrier on access to receiver inst vars by scanning the stack zone (*) after a become and following pointers to the receiver. (* the Cog VM, following Peter Deutsch's PS Smalltalk VM, lazily maps stack frames to context objects, creating contexts as needed and using stack frames for all method activations.  The stack zone is small (320k default, of which at most half is used to execute Smalltalk, half being reserved for interrupt handlers running on the native stack) and organized as pages.  Context objects serve as proxy objects for stack frames in the stack zone, or as fully fledged activations when activations on a stack page are evicted to the heap as contexts to make room for new activations).

There is one wrinkle in this neat picture for sends that we call the ""stale supersend"" problem.  See the next section.

We can easily avoid read barriers in direct literal access, and class hierarchy walking and message dictionary searching in message lookup (but we do not do so, see next paragraph).  Whenever the become operation becomes one or more pointer objects (and it can e.g. cheaply know if it has becommed a CompiledMethod) both the class table and the stack zone could be scanned.  In the class table we can follow the forwarding pointers in all classes in the table, and we can follow their superclasses.  But we would like to avoid scanning classes many times.  Any superclass that has a non-zero hash must be in the table and will be encountered during the scan of the class table.  Any superclass with a zero hash can be entered into the table at a point subsequent to the current index and hence scanned.  The class scan can also scan method dictionary selectors and follow the method dictionary's array reference (so that dictionaries are valid for lookup) and scan the dictionary's method array iff a CompiledMethod was becommed. (Note that support for object-as-method implies an explicit read barrier in primitiveObjectAsMethod, which is a small overhead there-in).

In fact, scanning the class table is much more expensive than having a read barrier on message lookup, since
- becomes can be frequent (e.g. growing method dictionaries) and so the class table scanning becomes a significant cost in some circumstances
- method cacheing makes lookups rare and hence a small overhead
- the read barriers on fetching the superclass and method dictionary et al on lookup are very cheap because
	a) lookups are rare, in the interpreter at most 4% of message sends are looked up and in the JIT at most 1%
	b) the class indexes likely share cache lines with the state being fetched, and
	c) forwarding is rare so most of the time the VM accesses the class index, finds the object is not forwarded and then fetches the superclass or method dictionary from the same cache line as the class index.
- since lookups are rare (and since nil is never forwarded and explicitly tested for on method dictionary search) the read barrier on fetching selectors in method dictionaries has a small overhead.

Accessing possibly forwarded method literals is fine; these forwarding objects will be pushed on the stack and caught either by the message lookup trap or explicitly in primitives that access arguments.  However, push/store/pop literal variable cannot avoid an explicit check without requiring we scan all methods, which is far too expensive.  So accessing associations from methods (including the method class association for super sends) requires a read barrier.

And of course, all of the scavenger, the incremental scan-mark-compactor and the global garbage collector follow and eliminate forwarding pointers as part of their object graph traversals.

This means explicit read barriers in
- push/store/pop literal variable
- super send
- base frame return (accessing the sender context, its inst vars, and the method class association of its method)
- block activation (the JIT avoids a read barrier on block activation unless a block accesses inst vars)

This leaves primitives where explicit access to object state is done without message sending.  Since primitives check their arguments for validity, and fail without side effects if validation fails, they fail if encountering a forwarding object, and can be retried.  There were a few exceptions to this in the Semaphore installation primitives that assumed a non-Semaphore argument was nil, hence being fooled by forwarders to Semaphores.  These primitives were easily fixed.  So all primitives that examine state fail if they encounter a forwarder amongst that state.  Slang is used to analyse the parse trees of primitives and compute an ""accessor depth"", the depth to which a primitive traverses the object graph of its input arguments.  If a primitive fails then the primitive failure code retrieves the accessor depth for the primitive and, if >= 0, traverses the state to that depth, following (and fixing) any forwarders found.  If any are found the primitive is retried.

Stale Super Sends
Notionally we catch sends to forwarded objects by only checking for forwqarders when a send lookup cache fails, but Smalltalk supersends, once linked, are unchecked, and the lookup starts from a method's methodClass, which requires an explicit read barrier.  So there is no possibility of implicitly checking for forwarding of the receiver of a super send.  Since a super send looks like push: self, marshall arguments, super send, and receivers are never forwarded this may look like a non-problem, but any computation could happen as part of marshalling the supersend arguments, e.g. ^super doSomethingWith: (self become: self somethingElse).  Because self is pushed before argument marshalling, stale forwarded references to self can be left on the stack after a become and before the supersend.

There are three solutions for this problem we have considered.  One is to scan the entire stack after become (and the entire stack of a context faulted back into the stack zone).  This is expensive.  Another is to use checked entry-points for super.  This seems to add a lot of new code and complexity, and works only in jitted code.  The solution we have chosen is to explicitly test for a forwarded receiver.  In the interpreter this is done by sending ensureReceiverUnforwarded in the supersend lookup routines.  In jitted code it is done by adding code to the send site to unforward the receiver after arguments are marshalled and immediately before the send call.  Because super sends are extremely rare this adds little overhead.

61-bit Immediate Floats
Representation for immediate doubles, only used in the 64-bit implementation. Immediate doubles have the same 52 bit mantissa as IEEE double-precision  floating-point, but only have 8 bits of exponent.  So they occupy just less than the middle 1/8th of the double range.  They overlap the normal single-precision floats which also have 8 bit exponents, but exclude the single-precision denormals (exponent-127) and the single-precsion NaNs (exponent +127).  +/- zero is just a pair of values with both exponent and mantissa 0. 
So the non-zero immediate doubles range from 
        +/- 0x3800,0000,0000,0001 / 5.8774717541114d-39 
to      +/- 0x47ff,ffff,ffff,ffff / 6.8056473384188d+38 
The encoded tagged form has the sign bit moved to the least significant bit, which allows for faster encode/decode because offsetting the exponent can't overflow into the sign bit and because testing for +/- 0 is an unsigned compare for <= 0xf: 
    msb                                                                                        lsb 
    [8 exponent subset bits][52 mantissa bits ][1 sign bit][3 tag bits] 
So given the tag is 4, the tagged non-zero bit patterns are 
             0x0000,0000,0000,001[c(8+4)] 
to           0xffff,ffff,ffff,fff[c(8+4)] 
and +/- 0d is 0x0000,0000,0000,000[c(8+4)] 
Encode/decode of non-zero values in machine code looks like: 
						msb                                              lsb 
Decode:				[8expsubset][52mantissa][1s][3tags] 
shift away tags:			[ 000 ][8expsubset][52mantissa][1s] 
add exponent offset:	[     11 exponent     ][52mantissa][1s] 
rot sign:				[1s][     11 exponent     ][52mantissa]

Encode:					[1s][     11 exponent     ][52mantissa] 
rot sign:				[     11 exponent     ][52mantissa][1s] 
sub exponent offset:	[ 000 ][8expsubset][52 mantissa][1s] 
shift:					[8expsubset][52 mantissa][1s][ 000 ] 
or/add tags:			[8expsubset][52mantissa][1s][3tags] 
but is slower in C because 
a) there is no rotate, and 
b) raw conversion between double and quadword must (at least in the source) move bits through memory (quadword = *(q64 *)&doubleVariable). 


Heap Walking
In heap walking the memory manager needs to be able to detect the start of the next object.  This is complicated by the short and long header formats, short being for objects with 254 slots or less, long being for objects with 255 slots or more.  Since an object that has an overflow header must have 255 as its header slot count we can use this as the marker.  The overflow header word also has a numSlots field, set to 255.  The remainder of the overflow size field is used for the object's slot size, the least significant word in 32-bits (for 2^34 bytes, more than the address space), the remaining 56 bits in 64-bits (for 2^59 bytes, which we hope is big enough for bridge objects).  So if the word following an object contains 255 in its numSlots field, it must be the overflow size word of an object with a double header, and the word after that is the header, also with a saturated numSlots field.



Total Number of Classes and Instance-specific Behaviours
While the class index header field has advantages (saving significant header space, especially in 64-bits, providing a non-moving cache tag for inline caches, small constants for instantiating well-known classes instead of having to fetch them from a table such as the specialObjectsArray) it has the downside of limiting the number of classes.  For Smalltalk programs 2^20 to 2^24 classes is adequate for some time to come, but for prototype languages such as JavaScript this is clearly inadequate, and we woud like to support the ability to host prototype languages within Squeak. There is a solution in the form of ""auto-instances"", an idea of Claus Gittinger's.  The idea is to represent prototypes as behaviors that are instances of themselves.  In a classical Smalltalk system a Behavior is an object with the minimal amount of state to function as a class, and in Smalltalk-80 this state is the three instance variables of Behavior, superclass, methodDict and format, which are the only fields in a Behavior that are known to the virtual machine.  A prototype can therefore have its own behavior and inherit from other prototypes or classes, and have sub-prototypes derived from it if a) its first three instance variables are also superclass, methodDict, and format, and b) it is an instance of itself (one can create such objects in a normal Smalltalk system by creating an Array with the desired layout and using a change class primitive to change the class of the Array to itself).  The same effect can be achieved in a VM with class indexes by reserving one class index to indicate that the object is an instance of itself, hence not requiring the object be entered into the class table and in the code that derives the class of an object, requiring one simple test answering the object itself instead of indexing the class table.  There would probably need to be an auto-instantiation primitive that takes a behavior (or prototype) and an instance variable count and answers a new auto-instance with as many instance variables as the sum of the behavior (or prototype) and the instance variable count.  Using this scheme there can be as many auto-instances as available address space allows while retaining the benefits of class indices.

This scheme has obvious implications for the inline cache since all prototypes end up having the same inline cache tag.  Either the inline cache check checks for the auto-instance class tag and substitutes the receiver, or the cacheing machinery refuses to add the auto-instance class tag to any inline cache and failure path code checks for the special case.  Note that in V8 failing monomorphic sends are patched to open PICs (megamorphic sends); V8 does not use closed PICs due to the rationale that polymorphism is high in JavaScript.

Miscellanea:

In-line Cache Probe for Immediates
We would like to keep 31-bit SmallIntegers for the 32-bit system.  Lots of code could be impacted by a change to 30-bit SmallIntegers.  If so, then 
	isImmediate: oop	^(oop bitAnd: 3) ~= 0
	isSmallInteger: oop	^(oop bitAnd: 1) ~= 0
	isCharacter: oop	^(oop bitAnd: 2) = 2
If the in-line cache contains 0 for Characters then the in-line cache code (in x86 machine code) reads as follows, for a branch-free common-case:
	Limm: (aligned)
		andl $0x1, %eax
		j Lcmp
		nops...
	Lentry: (aligned)
		movl %edx, %eax
		andl $0x3, %eax
		jnz Limm
		movl 0(%edx), %eax
		andl $0x3fffff, %eax
	Lcmp:
		cmpl %ecx, %eax
		jnz Lmiss
	LuncheckedEntry:


64-Bit Sizes
We extend the original Squeak 4-bit per-object format field to 5 bits, providing space for 3 odd bits for byte objects (2 for short objects & 1 for 32-bit long objects).  Object sizes are slots, and byte (and short and 32-bit) lengths are computed by subtracting the odd bits from the shifted slot length.  Keeping the format field saves bits because it subsumes the isWeak,isEphemeron,isPointer bits that would be necessary otherwise.  The format field is organized as follows:
	 0 = 0 sized objects (UndefinedObject True False et al)
	 1 = non-indexable objects with inst vars (Point et al)
	 2 = indexable objects with no inst vars (Array et al)
	 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
	 4 = weak indexable objects with inst vars (WeakArray et al)
	 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
	 6 unused, reserved for exotic pointer objects?  e.g. contexts?
	 7 Forwarded Object, 1st field is pointer, rest of fields are ignored
	 8 unused, reserved for exotic non-pointer objects?
	 9 64-bit indexable
	10 - 11 32-bit indexable	(11 unused in 32 bits)
	12 - 15 16-bit indexable	(14 & 15 unused in 32-bits)
	16 - 23 byte indexable		(20-23 unused in 32-bits)
	24 - 31 compiled method	(28-21 unused in 32-bits)


One obvious optimization to images is to add image (de)compression to image loading and snapshot.  The image header remains unchanged but its contents could be compressed, compressing either on snapshot, if requested, or off-line via a special-purpose tool.

Simple Object Representation Improves Code Quality
Given that the Spur object representation is quite regular and simple it has been possible to implement many more performance-critcal operations in machine code.  The exsting VM allocated only Float results in the floating-point primitives, deferring to Interpreter primitives (in the Interpreter's C run-time, invoked by a system-call like stack-switching call) for object instantiation, and closure, indirection vector and context creation.  The Spur JIT now generates machine code for the object instantiation primitives, and closure, indirection vector and context creation.  It also implements the at:put: primitive in machine code and implements both at: and at:put: on WideString in machine code (the previous VM needs to instantiate characters with codes > 255 in at:).  As a result, Spur is substantially faster executing Smalltalk.  The scavenger also has a significant impact on GC-intensive benchmarks.


Issues:
Are class indices in inline caches strong references to classes or weak references?
If strong then they must be scanned during GC and the methodZone must be flushed on fullGC to reclaim all classes (this looks to be a bug in the V3 Cogit).
If weak then when the class table loses references, PICs containing freed classes must be freed and then sends to freed PICs or containing freed clases must be unlinked.
The second approach is faster; the common case is scanning the class table, the uncommon case is freeing classes.  The second approach is better for machine code; in-line caches do not prevent reclamation of classes.  However, the former is better for the scavenger which as a result doesn't have to scan the classes of objects.  The system scavenges much more frequently than it reclaims classes and the number of cog methods to be scanned during scavenge is small.  So I think a strong class table is better after all.  Indeed we use a strong class table with old pages.  So classes are only GCed by the incremental and global GCs, never by the scavenger.
"
Class {
	#name : #SpurMemoryManager,
	#superclass : #CogClass,
	#instVars : [
		'coInterpreter',
		'scavenger',
		'segmentManager',
		'compactor',
		'memory',
		'freeStart',
		'freeOldSpaceStart',
		'scavengeThreshold',
		'newSpaceStart',
		'newSpaceLimit',
		'edenBytes',
		'oldSpaceStart',
		'nilObj',
		'falseObj',
		'trueObj',
		'specialObjectsOop',
		'hiddenRootsObj',
		'classTableFirstPage',
		'classTableIndex',
		'numClassTablePages',
		'endOfMemory',
		'mournQueue',
		'unscannedEphemerons',
		'objStackInvalidBecause',
		'invalidObjStackPage',
		'markStack',
		'weaklingStack',
		'freeLists',
		'freeListsMask',
		'lastHash',
		'signalLowSpace',
		'checkForLeaks',
		'needGCFlag',
		'heapMap',
		'becomeEffectsFlags',
		'pastSpaceStart',
		'heapGrowthToSizeGCRatio',
		'heapSizeAtPreviousGC',
		'oldSpaceUsePriorToScavenge',
		'growHeadroom',
		'shrinkThreshold',
		'marking',
		'remapBuffer',
		'remapBufferCount',
		'extraRootCount',
		'extraRoots',
		'lowSpaceThreshold',
		'totalFreeOldSpace',
		'maxOldSpaceSize',
		'gcPhaseInProgress',
		'gcStartUsecs',
		'gcMarkEndUsecs',
		'gcSweepEndUsecs',
		'compactionStartUsecs',
		'bogon',
		'statCoalesces',
		'statCompactPassCount',
		'statFGCDeltaUsecs',
		'statFullGCUsecs',
		'statCompactionUsecs',
		'statSweepUsecs',
		'statMarkUsecs',
		'statFullGCs',
		'statGCEndUsecs',
		'statGrowMemory',
		'statIGCDeltaUsecs',
		'statIncrGCUsecs',
		'statIncrGCs',
		'statMarkCount',
		'statRootTableCount',
		'statRootTableOverflows',
		'statSGCDeltaUsecs',
		'statScavengeGCUsecs',
		'statScavenges',
		'statShrinkMemory',
		'statAllocatedBytes',
		'statMaxAllocSegmentTime'
	],
	#classVars : [
		'BitsPerByte',
		'ExtraRootsSize',
		'FirstValidClassIndex',
		'MarkObjectsForEnumerationPrimitives',
		'MarkStackRecord',
		'MarkStackRootIndex',
		'MournQueueRootIndex',
		'ObjStackFixedSlots',
		'ObjStackFreex',
		'ObjStackLimit',
		'ObjStackMyx',
		'ObjStackNextx',
		'ObjStackPageSlots',
		'ObjStackTopx',
		'RemapBufferSize',
		'RememberedSetRootIndex',
		'TopHashBit',
		'TopOopBit',
		'WeaklingStackRootIndex'
	],
	#pools : [
		'SpurMemoryManagementConstants',
		'VMBasicConstants',
		'VMBytecodeConstants',
		'VMObjectIndices',
		'VMSpurObjectRepresentationConstants',
		'VMSqueakClassIndices'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurMemoryManager class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^{	SpurGenerationScavenger. SpurScavengeLogRecord. SpurSegmentManager. SpurSegmentInfo }, 
		self compactorClass classesForTranslation,
		SpurNewSpaceSpace withAllSubclasses
		
	
]

{ #category : #accessing }
SpurMemoryManager class >> baseHeaderSize [
	"For CogBlockMethod class>>instVarNamesAndTypesForTranslationDo:"
	^8
]

{ #category : #'word size' }
SpurMemoryManager class >> bytesPerOop [
	"Answer the size of an oop for this manager, which is assumed
	 to be equivalent to the underlying machine's word size."
	^self wordSize
]

{ #category : #'simulation only' }
SpurMemoryManager class >> characterObjectOf: characterCode [
	^characterCode asCharacter
]

{ #category : #accessing }
SpurMemoryManager class >> classIndicesMap [
	"self classIndicesMap"
	| map |
	map := Dictionary new.
	self selectorsAndMethodsDo:
		[:s :m| | mn |
		(('*classindex*' match: s) or: ['*bridge*'match: s])
		and: [mn := m methodNode block.
			(mn statements size = 1
			 and: [mn statements first expr isConstantNumber]) ifTrue:
				[map at: mn statements first expr key put: s]]].
	^map keys sort collect:
		[:n|
		{ n. map at: n }]
]

{ #category : #accessing }
SpurMemoryManager class >> classTableBitmapBytes [
	"Max size of the classTableBitmap.  A liottle too large to contemplate allocating statically."
	^1 << (self basicNew classIndexFieldWidth - (BitsPerByte log: 2) asInteger)
]

{ #category : #'accessing class hierarchy' }
SpurMemoryManager class >> compactorClass [
	"Answer the compaction algorithm to use."
	^Smalltalk classNamed: (InitializationOptions at: #compactorClass ifAbsent: [#SpurPlanningCompactor])
]

{ #category : #translation }
SpurMemoryManager class >> declareCVarsIn: aCCodeGenerator [
	self declareCAsOop: #(	memory freeStart scavengeThreshold newSpaceStart newSpaceLimit pastSpaceStart
							lowSpaceThreshold freeOldSpaceStart oldSpaceStart endOfMemory)
		in: aCCodeGenerator.
	self declareCAsUSqLong: (self allInstVarNames select: [:ivn| ivn endsWith: 'Usecs']), #(statAllocatedBytes)
		in: aCCodeGenerator.
	aCCodeGenerator
		var: #freeListsMask type: #usqInt;
		var: #freeLists type: #'sqInt *';
		var: #objStackInvalidBecause type: #'char *';
		var: #unscannedEphemerons type: #SpurContiguousObjStack;
		var: #heapGrowthToSizeGCRatio type: #float;
		var: #heapSizeAtPreviousGC type: #usqInt;
		var: #totalFreeOldSpace type: #usqInt;
		var: #maxOldSpaceSize type: #usqInt.
	aCCodeGenerator
		var: #oldSpaceUsePriorToScavenge type: #sqLong.
	aCCodeGenerator
		var: #remapBuffer
		declareC: 'sqInt remapBuffer[RemapBufferSize + 1 /* ', (RemapBufferSize + 1) printString, ' */]'.
	aCCodeGenerator
		var: #extraRoots
		declareC: 'sqInt *extraRoots[ExtraRootsSize + 1 /* ', (ExtraRootsSize + 1) printString, ' */]'
]

{ #category : #'api characterization' }
SpurMemoryManager class >> hasSpurMemoryManagerAPI [
	^true
]

{ #category : #analysis }
SpurMemoryManager class >> identify32BitSignedComparisonsInSegmentIO [
	"self identify32BitSignedComparisonsInSegmentIO"
	self identifySignedComparisonsFor: #(ObjectMemory Spur32BitMemoryManager)
		in:	(self organization listAtCategoryNamed: #'image segment in/out')
		noise: #(	'classIndex* >= numOutPointers'
					'count > ptr - start / self bytesPerOop'
					'endSeg - segAddr < self baseHeaderSize + self bytesPerOop'
					'errorCode* > 0'
					'GCModeImageSegment > 0'
					'hash - TopHashBit <= outIndex'
					'limit - ptr <= 8'
					'num* >= self numSlotsMask'
					'num* <= 1'
					'outIndex >= (self numSlotsOf: outPointerArray)'
					'outIndex := self mapOopsFrom: * < 0'
					'segAddr - segStart / 8 + self lastClassIndexPun >= TopHashBit'
					'there > 0'
					'* > self identityHashHalfWordMask'
					'*segmentLimit >= self numSlotsMask*'
					'* > self isForwardedObjectClassIndexPun'
					'* > self lastClassIndexPun')
]

{ #category : #analysis }
SpurMemoryManager class >> identify64BitSignedComparisonsInSegmentIO [
	"self identify64BitSignedComparisonsInSegmentIO"
	self identifySignedComparisonsFor: #(ObjectMemory Spur64BitMemoryManager)
		in:	(self organization listAtCategoryNamed: #'image segment in/out')
		noise: #(	'classIndex* >= numOutPointers'
					'count > ptr - start / self bytesPerOop'
					'endSeg - segAddr < self baseHeaderSize + self bytesPerOop'
					'errorCode* > 0'
					'GCModeImageSegment > 0'
					'hash - TopHashBit <= outIndex'
					'limit - ptr <= 8'
					'num* >= self numSlotsMask'
					'num* <= 1'
					'num* > 0'
					'num* < 1'
					'outIndex >= (self numSlotsOf: outPointerArray)'
					'outIndex := self mapOopsFrom: * < 0'
					'segAddr - segStart / 8 + self lastClassIndexPun >= TopHashBit'
					'there > 0'
					'* > self identityHashHalfWordMask'
					'*segmentLimit >= self numSlotsMask*'
					'* > self isForwardedObjectClassIndexPun'
					'* > self lastClassIndexPun')
]

{ #category : #analysis }
SpurMemoryManager class >> identifySignedComparisonsFor: options in: selectors noise: noise [
	"self identify32BitSignedComparisonsInSegmentIO"
	"self identify64BitSignedComparisonsInSegmentIO"
	| vmm cg halt |
	halt := false.
	vmm := (VMMaker forPlatform: 'Cross')
				interpreterClass: StackInterpreter;
				options: options.
	cg := [vmm buildCodeGeneratorForInterpreter]
			on: Notification
			do: [:ex|
				ex tag == #getVMMaker
					ifTrue: [ex resume: vmm]
					ifFalse: [ex pass]].
	cg vmClass preGenerationHook: cg.
	cg inferTypesForImplicitlyTypedVariablesAndMethods.
	cg retainMethods: self selectors.
	cg prepareMethods.
	cg doInlining: true.
	selectors sort do:
		[:sel|
		(cg methodNamed: sel) ifNotNil:
			[:m|
			m parseTree nodesDo:
				[:node|
				(node isSend
				 and: [(#(< > <= >=) includes: node selector)
				 and: [({node receiver. node args first } anySatisfy:
						[:o| (cg typeFor: o in: m)
								ifNil: [true]
								ifNotNil: [:t| (cg isIntegralCType: t) and: [t first ~= $u]]])
				 and: [noise noneSatisfy: [:n| n match: node printString]]]]) ifTrue:
					[halt ifTrue: [self halt: node printString].
					 Transcript ensureCr; nextPutAll: sel; space; print: node; flush]]]]
]

{ #category : #translation }
SpurMemoryManager class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initBytesPerWord: wordSize [

	BytesPerWord := BytesPerOop := wordSize.
	"N.B.  This is *not* output when generating the interpreter file.
	 It is left to the various sqConfig.h files to define correctly."
	VMBIGENDIAN := Smalltalk endianness == #big.
	SPURVM := true
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initialize [
	"SpurMemoryManager initialize"
	BitsPerByte := 8.

	"Initialize at least the become constants for the Spur bootstrap where the
	 old ObjectMemory simulator is used before a Spur simulator is created.."
	self initializeSpurObjectRepresentationConstants.

	"An obj stack is a stack of objects stored in a hidden root slot, such as
	 the markStack or the ephemeronQueue.  It is a linked list of segments,
	 with the hot end at the head of the list.  It is a word object.  The stack
	 pointer is in ObjStackTopx and 0 means empty.  The list goes through
	 ObjStackNextx. We don't want to shrink objStacks, since they're used
	 in GC and it's good to keep their memory around.  So unused pages
	 created by popping emptied pages are kept on the ObjStackFreex list.
	 ObjStackNextx must be the last field for swizzleObjStackAt:."
	ObjStackPageSlots := 4092. "+ double header = 16k bytes per page in 32-bits"
	ObjStackTopx := 0.
	ObjStackMyx := 1.
	ObjStackFreex := 2.
	ObjStackNextx := 3.
	ObjStackFixedSlots := 4.
	ObjStackLimit := ObjStackPageSlots - ObjStackFixedSlots.
	"The hiddenHootsObject contains the classTable pages and up to 8 additional objects.
	 Currently we use four; the three objStacks, the mark stack, the weaklings and the
	 mourn queue, and the rememberedSet."
	MarkStackRootIndex := self basicNew classTableRootSlots.
	WeaklingStackRootIndex := MarkStackRootIndex + 1.
	MournQueueRootIndex := MarkStackRootIndex + 2.
	RememberedSetRootIndex := MarkStackRootIndex + 3.

	MarkObjectsForEnumerationPrimitives := false.

	"The remap buffer support is for compatibility; Spur doesn't GC during allocation.
	 Eventually this should die."
	RemapBufferSize := 25.

	"Extra roots are for plugin support."
	ExtraRootsSize := 2048. "max. # of external roots"

	"gcPhaseInProgress takes these values to identify phases as required."
	ScavengeInProgress := 1.
	SlidingCompactionInProgress := 2
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initializeCompactClassIndices [
	"Reuse the compact class indices to name known classIndices.
	 This helps reduce the churn in the interpreters."
	"c.f. SpurBootstrap>>defineKnownClassIndices"
	FirstValidClassIndex :=
	ClassLargeNegativeIntegerCompactIndex := 32.
	ClassLargePositiveIntegerCompactIndex := 33.
	ClassFloatCompactIndex := 34.

	ClassMessageCompactIndex := 35.
	ClassMethodContextCompactIndex := 36.
	ClassBlockContextCompactIndex := 0.
	ClassBlockClosureCompactIndex := 37.
	ClassFullBlockClosureCompactIndex := 38.

	ClassByteArrayCompactIndex := 50.
	ClassArrayCompactIndex := 51.
	ClassByteStringCompactIndex := 52.
	ClassBitmapCompactIndex := 53
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initializeObjectHeaderConstants [

	BytesPerWord ifNil: [BytesPerWord := 4].  "May get called on fileIn, so supply default"
	BaseHeaderSize := 8. "This is still needed for VM generation."

	"These are used in image segments"
	self ~~ SpurMemoryManager ifTrue:
		[TopHashBit := 1 << (self basicNew identityHashFieldWidth - 1).
		 TopOopBit := 1 << (self basicNew bytesPerOop * 8 - 1)]
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initializeSpecialObjectIndices [
	"Initialize indices into specialObjects array."

	NilObject := 0.
	FalseObject := 1.
	TrueObject := 2.
	SchedulerAssociation := 3.
	ClassBitmap := 4.
	ClassSmallInteger := 5.
	ClassByteString := ClassString := 6. "N.B.  Actually class ByteString"
	ClassArray := 7.
	"SmalltalkDictionary := 8."  "Do not delete!"
	ClassFloat := 9.
	ClassMethodContext := 10.
	"ClassBlockContext := 11. unused by the VM"
	ClassPoint := 12.
	ClassLargePositiveInteger := 13.
	TheDisplay := 14.
	ClassMessage := 15.
	"ClassCompiledMethod := 16. unused by the VM"
	TheLowSpaceSemaphore := 17.
	ClassSemaphore := 18.
	ClassCharacter := 19.
	SelectorDoesNotUnderstand := 20.
	SelectorCannotReturn := 21.
	ProcessSignalingLowSpace := 22.	"was TheInputSemaphore"
	SpecialSelectors := 23.
	CharacterTable := nil.	"Must be unused by the VM"
	SelectorMustBeBoolean := 25.
	ClassByteArray := 26.
	"ClassProcess := 27. unused"
	CompactClasses := 28.
	TheTimerSemaphore := 29.
	TheInterruptSemaphore := 30.
	SelectorCannotInterpret := 34.
	"Was MethodContextProto := 35."
	ClassBlockClosure := 36.
	"Was BlockContextProto := 37."
	ExternalObjectsArray := 38.
	ClassMutex := 39.
	"Was: ClassTranslatedMethod := 40."
	ProcessInExternalCodeTag := 40.
	TheFinalizationSemaphore := 41.
	ClassLargeNegativeInteger := 42.

	ClassExternalAddress := 43.
	ClassExternalStructure := 44.
	ClassExternalData := 45.
	ClassExternalFunction := 46.
	ClassExternalLibrary := 47.

	SelectorAboutToReturn := 48.
	SelectorRunWithIn := 49.

	SelectorAttemptToAssign := 50.
	"PrimErrTableIndex := 51. in VMClass class>>initializePrimitiveErrorCodes"
	ClassAlien := 52.
	SelectorInvokeCallback := 53.
	ClassUnsafeAlien := 54.

	ClassWeakFinalizer := 55.

	ForeignCallbackProcess := 56.

	SelectorUnknownBytecode := 57.
	SelectorCounterTripped := 58.
	SelectorSistaTrap := 59.
	
	LowcodeContextMark := 60.
	LowcodeNativeContextClass := 61.
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initializeSpurObjectRepresentationConstants [
	"SpurMemoryManager initializeSpurObjectRepresentationConstants"
	BecamePointerObjectFlag := 1.
	BecameCompiledMethodFlag := 2.
	OldBecameNewFlag := 4.
	BecameActiveClassFlag := 8 "For flushing method caches"
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initializeWithOptions: optionsDictionary [
	"SpurMemoryManager initializeWithOptions: Dictionary new"

	super initializeWithOptions: optionsDictionary.
	InitializationOptions
		at: #Spur32BitMemoryManager ifAbsentPut: false;
		at: #Spur64BitMemoryManager ifAbsentPut: false.
	self initialize.
	self initBytesPerWord: (self == SpurMemoryManager
								ifTrue: [optionsDictionary at: #BytesPerWord ifAbsent: [4]]
								ifFalse: [self wordSize]).

	self initializeObjectHeaderConstants. "Initializes BaseHeaderSize so do early"
	self initializeSpurObjectRepresentationConstants.
	self initializeSpecialObjectIndices.
	self initializeCompactClassIndices.
	self initializePrimitiveErrorCodes.

	SpurGenerationScavenger initialize
]

{ #category : #'simulation only' }
SpurMemoryManager class >> isImmediate: anObject [
	self subclassResponsibility
]

{ #category : #translation }
SpurMemoryManager class >> isNonArgumentImplicitReceiverVariableName: aString [
	^#('self' 'coInterpreter' 'manager' 'scavenger' 'segmentManager' 'compactor' 'planningCompactor' 'selectiveCompactor' 'heapMap') includes: aString
]

{ #category : #translation }
SpurMemoryManager class >> isSameLevelObjectAccessor: selector [
	"For accessor depth calculation, answer if selector doesn't traverse into an object, merely deriving a pointer from it."
	^#(arrayValueOf: firstFixedField: firstIndexableField:) includes: selector
]

{ #category : #translation }
SpurMemoryManager class >> isTerminalObjectAccessor: selector [
	"For accessor depth calculation, answer if selector doesn't answer another object object; merely a value."
	^#(byteSizeOf: fetchFloat:ofObject: fetchInteger:ofObject: fetchLong32:ofObject: instanceSizeOf: slotSizeOf: stSizeOf:) includes: selector
]

{ #category : #accessing }
SpurMemoryManager class >> memoryManagerVersion [ 
	^ 'Spur'
]

{ #category : #translation }
SpurMemoryManager class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^#('checkForLeaks' 'maxOldSpaceSize') includes: var
]

{ #category : #accessing }
SpurMemoryManager class >> numSmallIntegerTagBits [
	^self subclassResponsibility
]

{ #category : #accessing }
SpurMemoryManager class >> objectFormatsMap [
	"self objectFormatsMap"
	| map |
	map := Dictionary new.
	self selectorsAndMethodsDo:
		[:s :m| | mn |
		('*format*' match: s)
		and: [mn := m methodNode block.
			(mn statements size = 1
			 and: [mn statements first expr isConstantNumber]) ifTrue:
				[map at: mn statements first expr key put: s]]].
	^map keys sort collect:
		[:n|
		{ n. map at: n }]
]

{ #category : #'accessing class hierarchy' }
SpurMemoryManager class >> objectRepresentationClass [
	^self subclassResponsibility
]

{ #category : #'simulation only' }
SpurMemoryManager class >> simulatorClass [
	^self subclassResponsibility
]

{ #category : #'simulation only' }
SpurMemoryManager class >> vmProxyMajorVersion [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^StackInterpreter vmProxyMajorVersion
]

{ #category : #'simulation only' }
SpurMemoryManager class >> vmProxyMinorVersion [
	^StackInterpreter vmProxyMinorVersion max: 13
]

{ #category : #'word size' }
SpurMemoryManager class >> wordSize [
	"Answer the manager's word size, which is the size of an oop, and which
	 is assumed to be equivalent to the underlying machine's word size."
	^self subclassResponsibility
]

{ #category : #'simulation only' }
SpurMemoryManager >> ISA [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter ISA
]

{ #category : #'simulation tests support' }
SpurMemoryManager >> abandonEmptySegmentForTests [
	"Assume a freshly-loaded image. Eliminate the last segment."
	<doNotGenerate>
	| freeChunk emptySeg |
	freeChunk := self findLargestFreeChunk.
	self assert: totalFreeOldSpace = (self bytesInObject: freeChunk).
	self assert: endOfMemory = (self addressAfter: freeChunk).
	self unlinkSolitaryFreeTreeNode: freeChunk.
	segmentManager numSegments > 1
		ifTrue:
			[emptySeg := segmentManager findEmptySegNearestInSizeTo: (self bytesInObject: freeChunk).
			 segmentManager removeSegment: emptySeg]
		ifFalse:
			[(segmentManager segments at: 0)
				segSize: (segmentManager segments at: 0) segSize - (self bytesInObject: freeChunk).
			 self setLastSegment: (segmentManager segments at: 0);
			 	initSegmentBridgeWithBytes: self bridgeSize at: (self startOfObject: freeChunk)]
]

{ #category : #'compaction - analysis' }
SpurMemoryManager >> abstractCompaction [
	"This method answers a rough estimate of compactibility."
	<doNotGenerate>
	| lowestFree freeChunks used movable |
	lowestFree := SmallInteger maxVal.
	freeChunks := Set new.
	used := Set new.
	movable := Set new.
	self allObjectsInFreeTreeDo:
		[:f|
		(self addressAfter: f) < endOfMemory ifTrue:
			[freeChunks add: f.
			 f < lowestFree ifTrue: [lowestFree := f]]].
	self allOldSpaceObjectsFrom: lowestFree do:
		[:o| | size delta best |
		size := self bytesInObject: o.
		delta := SmallInteger maxVal.
		freeChunks do: [:f| | fs |
			((fs := self bytesInObject: f) >= size) ifTrue:
				[delta > (fs - size) ifTrue:
					[delta := fs - size. best := f]]].
		 best ifNotNil:
			[movable add: o.
			 used add: (freeChunks remove: best)]].
	^{ totalFreeOldSpace. movable inject: 0 into: [:s :o| s + (self bytesInObject: o)]. used inject: 0 into: [:s :o| s + (self bytesInObject: o)] }
]

{ #category : #'object enumeration' }
SpurMemoryManager >> accessibleObjectAfter: objOop [
	"Answer the accessible object following the given object or 
	free chunk in the heap. Return nil when heap is exhausted.
	 This is for primitiveNextObject subsequent to primtiiveSomeObject.
	 It also tries to handle more general use by ordering objects as
		eden
		past
		old
	 but this is tricky becaus ethe order in memory is
		past
		eden
		old"
	<inline: false>
	| objAfter |
	objAfter := objOop.
	(self oop: objAfter isLessThan: nilObj) ifTrue: "object in new space"
		[self assert: ((self isInEden: objOop) or: [self isInPastSpace: objOop]).
		 (self oop: objAfter isGreaterThan: pastSpaceStart) ifTrue:
			["Obj is in eden.  Answer next normal object in eden, if there is one."
			 [objAfter := self objectAfter: objAfter limit: freeStart.
			  self oop: objAfter isLessThan: freeStart] whileTrue:
				[(self isNormalObject: objAfter) ifTrue:
					[^objAfter]].
			 "There wasn't a next object in eden. If past space is empty answer nilObj."
			 pastSpaceStart <= scavenger pastSpace start ifTrue:
				[^nilObj].
			 "If the first object in pastSpace is OK, answer it, otherwise fall through to enumerate past space."
			 objAfter := self objectStartingAt: scavenger pastSpace start.
			 (self isNormalObject: objAfter) ifTrue:
				[^objAfter]].
		 "Either objOop was in pastSpace, or enumeration exhaused eden, so enumerate past space."
		 [objAfter := self objectAfter: objAfter limit: pastSpaceStart.
		  self oop: objAfter isLessThan: pastSpaceStart] whileTrue:
			[(self isNormalObject: objAfter) ifTrue:
				[^objAfter]].
		 ^nilObj].
	[objAfter := self objectAfter: objAfter limit: endOfMemory.
	 objAfter = endOfMemory ifTrue:
		[^nil].
	 (self isNormalObject: objAfter) ifTrue:
		[^objAfter]] repeat
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> activeAndDeferredScan: anEphemeron [
	"Answer whether an ephemeron is active (has an unmarked
	 key) and was pushed on the unscanned ephemerons stack."
	| key |
	<inline: #never>
	self assert: (self isEphemeron: anEphemeron).
	((self isImmediate: (key := self keyOfEphemeron: anEphemeron))
	 or: [self isMarked: key]) ifTrue:
		[^false].
	^self pushOnUnscannedEphemeronsStack: anEphemeron
]

{ #category : #'free space' }
SpurMemoryManager >> addFreeChunkWithBytes: bytes at: address [
	totalFreeOldSpace := totalFreeOldSpace + bytes.
	^self freeChunkWithBytes: bytes at: address
]

{ #category : #'free space' }
SpurMemoryManager >> addFreeSubTree: freeTree [
	"Add a freeChunk sub tree back into the large free chunk tree.
	 This is for allocateOldSpaceChunkOf[Exactly]Bytes:[suchThat:]."
	| bytesInArg treeNode bytesInNode subNode |
	"N.B. *can't* use numSlotsOfAny: because of rounding up of odd slots
	 and/or step in size at 1032 bytes in 32-bits or 2048 bytes in 64-bits."
	self assert: (self isFreeObject: freeTree).
	bytesInArg := self bytesInObject: freeTree.
	self assert: bytesInArg >= (self numFreeLists * self allocationUnit).
	treeNode := freeLists at: 0.
	self assert: treeNode ~= 0.
	[bytesInNode := self bytesInObject: treeNode.
	 "check for overlap; could write this as self oop: (self objectAfter: freeChunk) isLessThanOrEqualTo: child...
	  but that relies on headers being correct, etc.  So keep it clumsy..."
	 self assert: ((self oop: freeTree + bytesInArg - self baseHeaderSize isLessThanOrEqualTo: treeNode)
					or: [self oop: freeTree isGreaterThanOrEqualTo: treeNode + bytesInNode - self baseHeaderSize]).
	 self assert: bytesInNode >= (self numFreeLists * self allocationUnit).
	 self assert: bytesInArg ~= bytesInNode.
	 bytesInNode > bytesInArg
		ifTrue:
			[subNode := self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: treeNode.
			 subNode = 0 ifTrue:
				[self storePointer: self freeChunkSmallerIndex ofFreeChunk: treeNode withValue: freeTree.
				 self storePointer: self freeChunkParentIndex ofFreeChunk: freeTree withValue: treeNode.
				 ^self]]
		ifFalse:
			[subNode := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: treeNode.
			 subNode = 0 ifTrue:
				[self storePointer: self freeChunkLargerIndex ofFreeChunk: treeNode withValue: freeTree.
				 self storePointer: self freeChunkParentIndex ofFreeChunk: freeTree withValue: treeNode.
				 ^self]].
	 treeNode := subNode] repeat
]

{ #category : #'plugin support' }
SpurMemoryManager >> addGCRoot: varLoc [
	"Add the given variable location to the extra roots table."
	<api>
	<var: #varLoc type: #'sqInt *'>
	extraRootCount >= ExtraRootsSize ifTrue: [^false]. "out of space"
	extraRoots at: (extraRootCount := extraRootCount + 1) put: varLoc.
	^true
]

{ #category : #'free space' }
SpurMemoryManager >> addToFreeList: freeChunk bytes: chunkBytes [
	"Add freeChunk to the relevant freeList.
	 For the benefit of sortedFreeObject:, if freeChunk is large, answer the treeNode it
	 is added to, if it is added to the next list of a freeTreeNode, otherwise answer 0."
	| index |
	"coInterpreter transcript ensureCr. coInterpreter print: 'freeing '. self printFreeChunk: freeChunk."
	self assert: (self isFreeObject: freeChunk).
	self assert: chunkBytes = (self bytesInObject: freeChunk).
	"Too slow to be enabled byt default but useful to debug Selective...
	 self deny: (compactor isSegmentBeingCompacted: (segmentManager segmentContainingObj: freeChunk))."
	index := chunkBytes / self allocationUnit.
	index < self numFreeLists ifTrue:
		[self setNextFreeChunkOf: freeChunk withValue: (freeLists at: index) chunkBytes: chunkBytes.
		(self isLilliputianSize: chunkBytes) ifFalse:
			[self storePointer: self freeChunkPrevIndex ofFreeChunk: freeChunk withValue: 0].
		 freeLists at: index put: freeChunk.
		 freeListsMask := freeListsMask bitOr: 1 << index.
		 ^0].

	^self addToFreeTree: freeChunk bytes: chunkBytes
]

{ #category : #'free space' }
SpurMemoryManager >> addToFreeTree: freeChunk bytes: chunkBytes [
	"Add freeChunk to the large free chunk tree.
	 For the benefit of sortedFreeObject:, answer the treeNode it is added
	 to, if it is added to the next list of a freeTreeNode, otherwise answer 0."
	| childBytes parent child |
	self assert: (self isFreeObject: freeChunk).
	self assert: chunkBytes = (self bytesInObject: freeChunk).
	self assert: chunkBytes >= (self numFreeLists * self allocationUnit).
	self
		storePointer: self freeChunkNextIndex ofFreeChunk: freeChunk withValue: 0;
		storePointer: self freeChunkPrevIndex ofFreeChunk: freeChunk withValue: 0;
		storePointer: self freeChunkParentIndex ofFreeChunk: freeChunk withValue: 0;
		storePointer: self freeChunkSmallerIndex ofFreeChunk: freeChunk withValue: 0;
		storePointer: self freeChunkLargerIndex ofFreeChunk: freeChunk withValue: 0.
	"Large chunk list organized as a tree, each node of which is a list of chunks of the same size.
	 Beneath the node are smaller and larger blocks."
	parent := 0.
	child := freeLists at: 0.
	[child ~= 0] whileTrue:
		[childBytes := self bytesInObject: child.
		 "check for overlap; could write this as self oop: (self objectAfter: freeChunk) isLessThanOrEqualTo: child...
		  but that relies on headers being correct, etc.  So keep it clumsy..."
		 self assert: ((self oop: freeChunk + chunkBytes - self baseHeaderSize isLessThanOrEqualTo: child)
						or: [self oop: freeChunk isGreaterThanOrEqualTo: child + childBytes - self baseHeaderSize]).
		 childBytes = chunkBytes ifTrue: "size match; add to list at node."
			[self setNextFreeChunkOf: freeChunk withValue: (self fetchPointer: self freeChunkNextIndex ofFreeChunk: child) isLilliputianSize: false. 
			 self setNextFreeChunkOf: child withValue: freeChunk isLilliputianSize: false.
			 ^child].
		 "walk down the tree"
		 parent := child.
		 child := self fetchPointer: (childBytes > chunkBytes
										ifTrue: [self freeChunkSmallerIndex]
										ifFalse: [self freeChunkLargerIndex])
					ofFreeChunk: child].
	parent = 0 ifTrue:
		[self assert: (freeLists at: 0) = 0.
		 freeLists at: 0 put: freeChunk.
		 freeListsMask := freeListsMask bitOr: 1.
		 ^0].
	self assert: (freeListsMask anyMask: 1).
	"insert in tree"
	self storePointer: self freeChunkParentIndex
			ofFreeChunk: freeChunk
				withValue: parent.
	self storePointer: (childBytes > chunkBytes
									ifTrue: [self freeChunkSmallerIndex]
									ifFalse: [self freeChunkLargerIndex])
			ofFreeChunk: parent
				withValue: freeChunk.
	^0
]

{ #category : #'object enumeration' }
SpurMemoryManager >> addressAfter: objOop [
	"Answer the address immediately following an object."
	^self subclassResponsibility
]

{ #category : #'debug support' }
SpurMemoryManager >> addressCouldBeObj: address [
	<api>
	<inline: false>
	^(address bitAnd: self baseHeaderSize - 1) = 0
	  and: [(self isInOldSpace: address)
		or: [(self isInEden: address)
		or: [(self isInPastSpace: address)
		or: [self scavengeInProgress and: [self isInFutureSpace: address]]]]]
]

{ #category : #'debug support' }
SpurMemoryManager >> addressCouldBeOldObj: address [
	^(address bitAnd: self baseHeaderSize - 1) = 0
	  and: [self isInOldSpace: address]
]

{ #category : #'debug support' }
SpurMemoryManager >> addressCouldBeOop: address [
	<api>
	"Answer if address appears to be that of either an immediate or an object.
	 For code disassembly and assertions."
	^(self isImmediate: address)
	  or: [self addressCouldBeObj: address]
]

{ #category : #snapshot }
SpurMemoryManager >> adjustAllOopsBy: bytesToShift [
	"Adjust all oop references by the given number of bytes. This is
	 done just after reading in an image when the new base address
	 of the object heap is different from the base address in the image,
	 or when loading multiple segments that have been coalesced.  Also
	 set bits in the classTableBitmap corresponding to used classes."

	| obj classIndex |
	self assert: self newSpaceIsEmpty.
	self countNumClassPagesPreSwizzle: bytesToShift.
	(bytesToShift ~= 0
	 or: [segmentManager numSegments > 1]) ifTrue:
		[obj := self objectStartingAt: oldSpaceStart.
		 [self oop: obj isLessThan: freeOldSpaceStart] whileTrue:
			[classIndex := self classIndexOf: obj.
			 classIndex >= self isForwardedObjectClassIndexPun
				ifTrue:
					[self swizzleFieldsOfObject: obj]
				ifFalse:
					[classIndex = self isFreeObjectClassIndexPun ifTrue:
						[self swizzleFieldsOfFreeChunk: obj]].
			 obj := self objectAfter: obj limit: endOfMemory]]
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allExistingNewSpaceObjectsDo: aBlock [
	<inline: true>
	| prevObj prevPrevObj objOop limit |
	prevPrevObj := prevObj := nil.
	"After a scavenge eden is empty, futureSpace is empty, and all newSpace objects are
	  in pastSpace.  Objects are allocated in eden.  So enumerate only eden and pastSpace."
	objOop := self objectStartingAt: scavenger eden start.
	limit := freeStart.
	[self oop: objOop isLessThan: limit] whileTrue:
		[self assert: (self isEnumerableObjectNoAssert: objOop).
		 aBlock value: objOop.
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: freeStart].
	objOop := self objectStartingAt: scavenger pastSpace start.
	limit := pastSpaceStart.
	[self oop: objOop isLessThan: limit] whileTrue:
		[self assert: (self isEnumerableObjectNoAssert: objOop).
		 aBlock value: objOop.
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: limit].
	self touch: prevPrevObj.
	self touch: prevObj
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allExistingObjectsDo: aBlock [
	"Enumerate all objects, excluding any objects created
	 during the execution of allExistingObjectsDo:."
	<inline: true>
	self allExistingNewSpaceObjectsDo: aBlock.
	self allExistingOldSpaceObjectsDo: aBlock
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allExistingOldSpaceObjectsDo: aBlock [
	"Enumerate all old space objects, excluding any objects created
	 during the execution of allExistingOldSpaceObjectsDo:."
	<inline: true>
	| oldSpaceLimit prevObj prevPrevObj objOop |
	prevPrevObj := prevObj := nil.
	objOop := self firstObject.
	oldSpaceLimit := endOfMemory.
	[self assert: objOop \\ self allocationUnit = 0.
	 self oop: objOop isLessThan: oldSpaceLimit] whileTrue:
		[(self isEnumerableObject: objOop) ifTrue:
			[aBlock value: objOop].
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: oldSpaceLimit].
	self touch: prevPrevObj.
	self touch: prevObj
]

{ #category : #'free space' }
SpurMemoryManager >> allFreeHeads [
	<doNotGenerate>
	| freeObjects |
	freeObjects := OrderedCollection new.
	0 to: self numFreeLists - 1 do: [:i| | obj |
		obj := freeLists at: i.
		obj ~= 0 ifTrue: [ freeObjects add: obj ]].
	^freeObjects
]

{ #category : #'free space' }
SpurMemoryManager >> allFreeListHeads [
	<doNotGenerate>
	"Return all the head nodes of the free lists.
	The free lists are all the entries in the freeLists array between 2 and numFreeLists - 1.
	We skip indexes 0 and 1: index 0 is the free tree and index 1 unused"
	
	| freeObjects |
	freeObjects := OrderedCollection new.
	2 to: self numFreeLists - 1 do: [:i| | obj |
		obj := freeLists at: i.
		obj ~= 0 ifTrue: [ freeObjects add: obj ]].
	^freeObjects
]

{ #category : #'free space' }
SpurMemoryManager >> allFreeObjects [
	<doNotGenerate>
	| freeObjects |
	freeObjects := OrderedCollection new.
	self allFreeObjectsDo:
		[:f| freeObjects addLast: f].
	^freeObjects
]

{ #category : #'free space' }
SpurMemoryManager >> allFreeObjectsDo: aBlock [
	| obj |
	1 to: self numFreeLists - 1 do:
		[:i|
		obj := freeLists at: i.
		[obj ~= 0] whileTrue:
			[aBlock value: obj.
			 obj := self fetchPointer: self freeChunkNextIndex ofFreeChunk: obj]].
	self allObjectsInFreeTreeDo: aBlock
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allHeapEntitiesDo: aBlock [
	"N.B. e.g. allObjects relies on the old/new order here."
	<inline: true>
	self allOldSpaceEntitiesDo: aBlock.
	self allNewSpaceEntitiesDo: aBlock
]

{ #category : #'primitive support' }
SpurMemoryManager >> allInstancesOf: aClass [
	"Attempt to answer an array of all objects, excluding those that may
	 be garbage collected as a side effect of allocating the result array.
	 If no memory is available answer the number of instances as a SmallInteger.
	 Since objects are at least 16 bytes big, and the largest SmallInteger covers
	 1/4 of the address space, the count can never overflow."
	| classIndex freeChunk ptr start limit count bytes |
	classIndex := self rawHashBitsOf: aClass.
	classIndex = 0 ifTrue:
		[freeChunk := self allocateSlots: 0 format: self arrayFormat classIndex: ClassArrayCompactIndex.
		 ^freeChunk].
	MarkObjectsForEnumerationPrimitives ifTrue:
		[self markObjects: true]. "may not want to revive objects unnecessarily; but marking is sloooow."
	freeChunk := self allocateLargestFreeChunk. "N.B. Does /not/ update totalFreeOldSpace"
	start := freeChunk + self baseHeaderSize.
	limit := self addressAfter: freeChunk.
	(self isClassAtUniqueIndex: aClass)
		ifTrue:
			[self uniqueIndex: classIndex allInstancesInto: start limit: limit resultsInto: [:c :p| count := c. ptr := p]]
		ifFalse:
			[self ambiguousClass: aClass allInstancesInto: start limit: limit resultsInto: [:c :p| count := c. ptr := p]].
	self assert: (self isEmptyObjStack: markStack).
	MarkObjectsForEnumerationPrimitives
		ifTrue:
			[self assert: self allObjectsUnmarked.
			 self emptyObjStack: weaklingStack]
		ifFalse:
			[self assert: (self isEmptyObjStack: weaklingStack)].
	(count > (ptr - start / self bytesPerOop) "not enough room"
	 or: [limit ~= ptr and: [limit - ptr <= self allocationUnit]]) ifTrue: "can't split a single word"
		[self freeObject: freeChunk.
		 ^self integerObjectOf: count].
	count < self numSlotsMask ifTrue:
		[| smallObj |
		 smallObj := self allocateSlots: count format: self arrayFormat classIndex: ClassArrayCompactIndex.
		 0 to: count - 1 do:
			[:i|
			self storePointerUnchecked: i ofObject: smallObj withValue: (self fetchPointer: i ofFreeChunk: freeChunk)].
		 self freeChunkWithBytes: (self bytesInObject: freeChunk) at: (self startOfObject: freeChunk).
		 self beRootIfOld: smallObj.
		 self checkFreeSpace: GCModeFull.
		 ^smallObj].
	bytes := self largeObjectBytesForSlots: count.
	start := self startOfObject: freeChunk.
	self freeChunkWithBytes: limit - start - bytes at: start + bytes.
	totalFreeOldSpace := totalFreeOldSpace - bytes.
	self rawOverflowSlotsOf: freeChunk put: count.
	self set: freeChunk classIndexTo: ClassArrayCompactIndex formatTo: self arrayFormat.
	self possibleRootStoreInto: freeChunk.
	self checkFreeSpace: GCModeFull.
	self runLeakCheckerFor: GCModeFull.
	^freeChunk
	
	
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allNewSpaceEntitiesDo: aBlock [
	"Enumerate all new space objects, including free objects."
	<inline: true>
	| prevObj prevPrevObj objOop limit |
	prevPrevObj := prevObj := nil.
	"After a scavenge eden is empty, futureSpace is empty, and all newSpace objects are
	  in pastSpace.  Objects are allocated in eden.  So enumerate only pastSpace and eden."
	self assert: (scavenger pastSpace start < scavenger eden start).
	objOop := self objectStartingAt: scavenger pastSpace start.
	limit := pastSpaceStart.
	[self oop: objOop isLessThan: limit] whileTrue:
		[aBlock value: objOop.
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: limit].
	objOop := self objectStartingAt: scavenger eden start.
	[self oop: objOop isLessThan: freeStart] whileTrue:
		[aBlock value: objOop.
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: freeStart].
	self touch: prevPrevObj.
	self touch: prevObj
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allNewSpaceObjectsDo: aBlock [
	"Enumerate all new space objects, excluding free objects."
	<inline: true>
	self allNewSpaceEntitiesDo:
		[:objOop|
		 self assert: (self isEnumerableObjectNoAssert: objOop).
		 aBlock value: objOop]
]

{ #category : #'primitive support' }
SpurMemoryManager >> allObjects [
	"Attempt to answer an array of all objects, excluding those that may
	 be garbage collected as a side effect of allocating the result array.
	 If no memory is available answer the number of objects as a SmallInteger.
	 Since objects are at least 16 bytes big, and the largest SmallInteger covers
	 1/4 of the address space, the count can never overflow."
	| freeChunk ptr start limit count bytes |
	MarkObjectsForEnumerationPrimitives ifTrue:
		[self markObjects: true]. "may not want to revive objects unnecessarily; but marking is sloooow."
	freeChunk := self allocateLargestFreeChunk. "N.B. Does /not/ update totalFreeOldSpace"
	ptr := start := freeChunk + self baseHeaderSize.
	limit := self addressAfter: freeChunk.
	count := 0.
	self allHeapEntitiesDo:
		[:obj| "continue enumerating even if no room so as to unmark all objects."
		 (MarkObjectsForEnumerationPrimitives
				ifTrue: [self isMarked: obj]
				ifFalse: [true]) ifTrue:
			[(self isNormalObject: obj)
				ifTrue:
					[MarkObjectsForEnumerationPrimitives ifTrue:
						[self setIsMarkedOf: obj to: false].
					 count := count + 1.
					 ptr < limit ifTrue:
						[self longAt: ptr put: obj.
						 ptr := ptr + self bytesPerOop]]
				ifFalse:
					[MarkObjectsForEnumerationPrimitives ifTrue:
						[(self isSegmentBridge: obj) ifFalse:
							[self setIsMarkedOf: obj to: false]]]]].
	self assert: (self isEmptyObjStack: markStack).
	MarkObjectsForEnumerationPrimitives
		ifTrue:
			[self assert: self allObjectsUnmarked.
			 self emptyObjStack: weaklingStack]
		ifFalse:
			[self assert: (self isEmptyObjStack: weaklingStack)].
	self assert: count >= self numSlotsMask.
	(count > (ptr - start / self bytesPerOop) "not enough room"
	 or: [limit ~= ptr and: [limit - ptr <= self allocationUnit]]) ifTrue: "can't split a single word"
		[self freeChunkWithBytes: (self bytesInObject: freeChunk) at: (self startOfObject: freeChunk).
		 self checkFreeSpace: GCModeFull.
		 ^self integerObjectOf: count].
	bytes := self largeObjectBytesForSlots: count.
	start := self startOfObject: freeChunk.
	self freeChunkWithBytes: limit - start - bytes at: start + bytes.
	totalFreeOldSpace := totalFreeOldSpace - bytes.
	self rawOverflowSlotsOf: freeChunk put: count.
	self set: freeChunk classIndexTo: ClassArrayCompactIndex formatTo: self arrayFormat.
	self possibleRootStoreInto: freeChunk.
	self checkFreeSpace: GCModeFull.
	self runLeakCheckerFor: GCModeFull.
	^freeChunk
	
	
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allObjectsDo: aBlock [
	<inline: true>
	self allNewSpaceObjectsDo: aBlock.
	self allOldSpaceObjectsDo: aBlock
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allObjectsDoSafely: aBlock [
	<inline: true>
	self allObjectsDo: aBlock
]

{ #category : #'free space' }
SpurMemoryManager >> allObjectsInFreeTree: freeNode do: aBlock [
	| listNode |
	freeNode = 0 ifTrue: [^0].
	listNode := freeNode.
	[listNode ~= 0] whileTrue:
		[aBlock value: listNode.
		 listNode := self fetchPointer: self freeChunkNextIndex ofFreeChunk: listNode].
	self allObjectsInFreeTree: (self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: freeNode)
		do: aBlock.
	self allObjectsInFreeTree: (self fetchPointer: self freeChunkLargerIndex ofFreeChunk: freeNode)
		do: aBlock
]

{ #category : #'free space' }
SpurMemoryManager >> allObjectsInFreeTreeDo: aBlock [
	"Enumerate all objects in the free tree (in order, smaller to larger).
	 This is an iterative version so that the block argument can be
	 inlined by Slang. The trick to an iterative binary tree application is
	 to apply the function on the way back up when returning from a
	 particular direction, in this case up from the larger child."
	<inline: true>
	self freeTreeNodesDo:
		[:freeTreeNode| | next |
		 next := freeTreeNode.
		 [aBlock value: next.
		  next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: next.
		  next ~= 0] whileTrue.
		 freeTreeNode]
]

{ #category : #'gc - global' }
SpurMemoryManager >> allObjectsUnmarked [
	self allObjectsDo:
		[:o| (self isMarked: o) ifTrue: [bogon := o. ^false]].
	^true
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> allOldMarkedWeakObjectsOnWeaklingStack [
	self allOldSpaceEntitiesDo:
		[:o|
		((self isWeakNonImm: o)
		 and: [self isMarked: o]) ifTrue:
			[(self is: o onObjStack: weaklingStack) ifFalse:
				[^false]]].
	^true
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allOldSpaceEntitiesDo: aBlock [
	<inline: true>
	self allOldSpaceEntitiesFrom: self firstObject do: aBlock
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allOldSpaceEntitiesForCoalescingFrom: firstObj do: aBlock [
	<inline: true>
	| prevObj prevPrevObj objOop rawNumSlots rawNumSlotsAfter |
	prevPrevObj := prevObj := nil.
	objOop := firstObj.
	[self assert: objOop \\ self allocationUnit = 0.
	 self oop: objOop isLessThan: endOfMemory] whileTrue:
		[self assert: (self long64At: objOop) ~= 0.
		 rawNumSlots := self rawNumSlotsOf: objOop.
		 aBlock value: objOop.
		 "If the number of slot changes coalescing changed an object from a single to a double header.
		  In future have the block return the vaue.  It should know when things change."
		 self flag: 'future work'.
		 rawNumSlotsAfter := self rawNumSlotsOf: objOop.
		 (rawNumSlotsAfter ~= rawNumSlots
		  and: [rawNumSlotsAfter = self numSlotsMask]) ifTrue:
			[objOop := objOop + self baseHeaderSize.
			 self assert: (self objectAfter: prevObj limit: endOfMemory) = objOop].
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: endOfMemory].
	self touch: prevPrevObj.
	self touch: prevObj
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allOldSpaceEntitiesForCompactingFrom: initialObject to: finalObject do: aBlock [
	<inline: true>
	| limit prevObj prevPrevObj objOop nextObj |
	self assert: (self isOldObject: initialObject).
	self assert: (self oop: finalObject isLessThanOrEqualTo: endOfMemory).
	prevPrevObj := prevObj := nil.
	objOop := initialObject.
	limit := (self oop: finalObject isLessThan: endOfMemory) ifTrue: [self addressAfter: finalObject] ifFalse: [endOfMemory].
	[self assert: objOop \\ self allocationUnit = 0.
	 self oop: objOop isLessThan: limit] whileTrue:
		[self assert: (self long64At: objOop) ~= 0.
		 nextObj := self objectAfter: objOop limit: endOfMemory.
		 aBlock value: objOop value: nextObj.
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := nextObj].
	self touch: prevPrevObj.
	self touch: prevObj
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allOldSpaceEntitiesFrom: initialObject do: aBlock [
	<inline: true>
	| prevObj prevPrevObj objOop |
	self assert: (self isOldObject: initialObject).
	prevPrevObj := prevObj := nil.
	objOop := initialObject.
	[self assert: objOop \\ self allocationUnit = 0.
	 self oop: objOop isLessThan: endOfMemory] whileTrue:
		[self assert: (self long64At: objOop) ~= 0.
		 aBlock value: objOop.
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: endOfMemory].
	self touch: prevPrevObj.
	self touch: prevObj
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allOldSpaceEntitiesFrom: initialObject to: finalObject do: aBlock [
	<inline: true>
	| prevObj prevPrevObj objOop |
	self assert: ((self isNonImmediate: initialObject) and: [segmentManager isInSegments: initialObject]).
	self assert: ((self isNonImmediate: finalObject) and: [segmentManager isInSegments: finalObject]).
	prevPrevObj := prevObj := nil.
	objOop := initialObject.
	[self assert: objOop \\ self allocationUnit = 0.
	 self oop: objOop isLessThanOrEqualTo: finalObject] whileTrue:
		[self assert: (self long64At: objOop) ~= 0.
		 aBlock value: objOop.
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: endOfMemory].
	self touch: prevPrevObj.
	self touch: prevObj
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allOldSpaceObjectsDo: aBlock [
	<inline: true>
	self allOldSpaceObjectsFrom: self firstObject do: aBlock
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allOldSpaceObjectsFrom: initialObject do: aBlock [
	"Enumerate all objects (i.e. exclude bridges, forwarders and free chunks)
	 in oldSpace starting at initialObject."
	<inline: true>
	self allOldSpaceEntitiesFrom: initialObject
		do: [:objOop|
			 (self isEnumerableObject: objOop) ifTrue:
				[aBlock value: objOop]]
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allPastSpaceEntitiesDo: aBlock [
	"Enumerate all past space objects, including free objects."
	<inline: true>
	| prevObj prevPrevObj objOop |
	prevPrevObj := prevObj := nil.
	objOop := self objectStartingAt: scavenger pastSpace start.
	[self oop: objOop isLessThan: pastSpaceStart] whileTrue:
		[aBlock value: objOop.
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: pastSpaceStart].
	self touch: prevPrevObj.
	self touch: prevObj
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allPastSpaceObjectsDo: aBlock [
	"Enumerate all past space objects, excluding free objects."
	<inline: true>
	self allPastSpaceEntitiesDo:
		[:objOop|
		 self assert: (self isEnumerableObjectNoAssert: objOop).
		 aBlock value: objOop]
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> allStrongSlotsOfWeaklingAreMarked: aWeakling [
	"N.B. generateToByDoLimitExpression:negative:on: guards against (unsigned)0 - 1 going +ve"
	0 to: (self numStrongSlotsOfWeakling: aWeakling) - 1 do:
		[:i| | referent |
		referent := self fetchPointer: i ofObject: aWeakling.
		(self isNonImmediate: referent) ifTrue:
			[(self isMarked: referent) ifFalse:
				[^false]]].
	^true
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> allUnscannedEphemeronsAreActive [
	unscannedEphemerons start to: unscannedEphemerons top - self bytesPerOop by: self bytesPerOop do:
		[:p| | key |
		key := self keyOfMaybeFiredEphemeron: (self longAt: p).
		((self isImmediate: key) or: [self isMarked: key]) ifTrue:
			[^false]].
	^true
]

{ #category : #allocation }
SpurMemoryManager >> allocateBytes: numBytes classIndex: classIndex [
	"Allocate an object of numBytes.  Answer nil if no available memory.
	 classIndex must be that of a byte class (e.g. ByteString).
	 The object is *NOT FILLED*."
	<var: #numBytes type: #usqInt>
	self assert: (coInterpreter addressCouldBeClassObj: (self classAtIndex: classIndex)).
	self assert: (self instSpecOfClass: (self classAtIndex: classIndex)) = self firstByteFormat.
	^self
		allocateSlots: (numBytes + self bytesPerOop - 1 // self bytesPerOop)
		format: (self byteFormatForNumBytes: numBytes)
		classIndex: classIndex
]

{ #category : #bootstrap }
SpurMemoryManager >> allocateClassTable [
	<doNotGenerate>
	"Create the class table root with enough slots for many class table pages and some hidden root slots.
	Create only a first mandatory class table page here.
	Others will be created on demand."	
	| classTableRootOop pageOop |
	classTableRootOop := self
		allocateSlotsInOldSpace: self classTableRootSlots + self hiddenRootSlots
		format: self arrayFormat
		classIndex: self arrayClassIndexPun.

	self nilFieldsOf: classTableRootOop.

	"We don't know how many class table pages we need. Seeing an assert in #validateClassTable
	we assume that it needs at least 2"
	0 to: 1  do: [ :index |		
		pageOop := self
			allocateSlotsInOldSpace: self classTablePageSize
			format: self arrayFormat
			classIndex: self arrayClassIndexPun.
		
		self nilFieldsOf: pageOop.
		self storePointer: index ofObject: classTableRootOop withValue: pageOop.
	].

	self setHiddenRootsObj: classTableRootOop.
		
	^ classTableRootOop
]

{ #category : #'free space' }
SpurMemoryManager >> allocateLargestFreeChunk [
	"Answer the largest free chunk in the free lists."
	<inline: false>
	| freeChunk next |
	"would like to use ifNotNil: but the ^next inside the ^blah ifNotNil: confused Slang"
	freeChunk := self findLargestFreeChunk.
	freeChunk ifNil: [^nil].
	"This will be the node, not a list element.  Answer a list element in preference."
	next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: freeChunk.
	next ~= 0 ifTrue:
		[self assert: (self bytesInObject: freeChunk) >= self numFreeLists. "findLargestFreeChunk searches only the tree"
		 self 
			setNextFreeChunkOf: freeChunk 
			withValue: (self fetchPointer: self freeChunkNextIndex ofFreeChunk: next) 
			isLilliputianSize: false.
		 ^next].
	self unlinkSolitaryFreeTreeNode: freeChunk.
	^freeChunk
]

{ #category : #testing }
SpurMemoryManager >> allocateMemoryOfSize: memoryBytes [
	<doNotGenerate>
	| bytesPerElement |
	bytesPerElement := (self memoryClass basicNew: 0) bytesPerElement.
	memory := self memoryClass new: memoryBytes + bytesPerElement - 1 // bytesPerElement
]

{ #category : #testing }
SpurMemoryManager >> allocateMemoryOfSize: memoryBytes initialAddress: initialAddress [
	<doNotGenerate>
	| bytesPerElement |
	bytesPerElement := (self memoryClass basicNew: 0) bytesPerElement.
	memory := self memoryClass new: memoryBytes + bytesPerElement - 1 // bytesPerElement.
	memory initialAddress: initialAddress
]

{ #category : #'spur bootstrap' }
SpurMemoryManager >> allocateMemoryOfSize: memoryBytes newSpaceSize: newSpaceBytes stackSize: stackBytes codeSize: codeBytes [
	"Intialize the receiver for bootsraping an image.
	 Set up a large oldSpace and an empty newSpace and set-up freeStart and scavengeThreshold
	 to allocate in oldSpace.  Later on (in initializePostBootstrap) freeStart and scavengeThreshold
	 will be set to sane values."
	<doNotGenerate>

	self
		allocateMemoryOfSize: memoryBytes
		newSpaceSize: newSpaceBytes
		stackSize: stackBytes
		codeSize: codeBytes
		initialAddress: 0
]

{ #category : #'spur bootstrap' }
SpurMemoryManager >> allocateMemoryOfSize: memoryBytes newSpaceSize: newSpaceBytes stackSize: stackBytes codeSize: codeBytes initialAddress: initialAddress [
	"Intialize the receiver for bootsraping an image.
	 Set up a large oldSpace and an empty newSpace and set-up freeStart and scavengeThreshold
	 to allocate in oldSpace.  Later on (in initializePostBootstrap) freeStart and scavengeThreshold
	 will be set to sane values."
	<doNotGenerate>
	
	self
		allocateMemoryOfSize: memoryBytes
		newSpaceSize: newSpaceBytes
		stackSize: stackBytes
		codeSize: codeBytes
		methodCacheSize: 0
		primitiveTraceLogSize: 0
		rumpCStackSize: 0
		initialAddress: initialAddress
]

{ #category : #asd }
SpurMemoryManager >> allocateMemoryOfSize: memoryBytes newSpaceSize: newSpaceBytes stackSize: stackBytes codeSize: codeBytes methodCacheSize: methodCacheSize primitiveTraceLogSize: primitiveLogSize rumpCStackSize: rumpCStackSize initialAddress: initialAddress [

		"Intialize the receiver for bootsraping an image.
	 Set up a large oldSpace and an empty newSpace and set-up freeStart and scavengeThreshold
	 to allocate in oldSpace.  Later on (in initializePostBootstrap) freeStart and scavengeThreshold
	 will be set to sane values."
	<doNotGenerate>
	self assert: (memoryBytes \\ self allocationUnit = 0
				and: [newSpaceBytes \\ self allocationUnit = 0
				and: [codeBytes \\ self allocationUnit = 0
				and: [initialAddress \\ self allocationUnit = 0 ]]]).
	self allocateMemoryOfSize: memoryBytes + newSpaceBytes + codeBytes + stackBytes + methodCacheSize + primitiveLogSize + rumpCStackSize initialAddress: initialAddress.
	newSpaceStart := initialAddress + codeBytes + stackBytes + methodCacheSize + primitiveLogSize + rumpCStackSize.
	endOfMemory := freeOldSpaceStart := initialAddress + memoryBytes + newSpaceBytes + codeBytes + stackBytes + methodCacheSize + primitiveLogSize + rumpCStackSize.
	"leave newSpace empty for the bootstrap"
	freeStart := newSpaceBytes + newSpaceStart.
	oldSpaceStart := newSpaceLimit := newSpaceBytes + newSpaceStart.
	scavengeThreshold := memory size * memory bytesPerElement. "i.e. /don't/ scavenge."
	scavenger := SpurGenerationScavenger simulatorClass new.
	scavenger manager: self.
	scavenger newSpaceStart: newSpaceStart
				newSpaceBytes: newSpaceBytes
				survivorBytes: newSpaceBytes // self scavengerDenominator.
	compactor := self class compactorClass simulatorClass new manager: self; yourself
]

{ #category : #allocation }
SpurMemoryManager >> allocateNewSpaceSlots: numSlots format: formatField classIndex: classIndex [
	"Allocate an object with numSlots in newSpace.  This is for the `ee' execution engine allocations,
	 and must be satisfied.  If no memory is available, abort.  If the allocation pushes freeStart past
	 scavengeThreshold and a scavenge is not already scheduled, schedule a scavenge."
	| numBytes newObj |
	"Object headers are 8 bytes in length if the slot size fits in the num slots field (max implies overflow),
	 16 bytes otherwise (num slots in preceding word).
	 Objects always have at least one slot, for the forwarding pointer,
	 and are multiples of 8 bytes in length."
	numSlots >= self numSlotsMask
		ifTrue:
			[(self wordSize >= 8 and: [numSlots > 16rffffffff]) ifTrue:
				[^nil]. "overflow size must fit in 32-bits"
			 newObj := freeStart + self baseHeaderSize.
			 numBytes := self largeObjectBytesForSlots: numSlots]
		ifFalse:
			[newObj := freeStart.
			 numBytes := self smallObjectBytesForSlots: numSlots].
	
	freeStart + numBytes > scavengeThreshold ifTrue:
		[needGCFlag ifFalse: [self scheduleScavenge].
		 freeStart + numBytes > scavenger eden limit ifTrue:
			[self error: 'no room in eden for allocateNewSpaceSlots:format:classIndex:'.
			 ^0]].
	numSlots >= self numSlotsMask
		ifTrue: "for header parsing we put a saturated slot count in the prepended overflow size word"
			[self flag: #endianness.
			 self longAt: freeStart put: numSlots.
			 self longAt: freeStart + 4 put: self numSlotsMask << self numSlotsHalfShift.
			 self long64At: newObj put: (self headerForSlots: self numSlotsMask format: formatField classIndex: classIndex)]
		ifFalse:
			[self long64At: newObj put: (self headerForSlots: numSlots format: formatField classIndex: classIndex)].
	self assert: numBytes \\ self allocationUnit = 0.
	self assert: newObj \\ self allocationUnit = 0.
	freeStart := freeStart + numBytes.
	^newObj
]

{ #category : #'free space' }
SpurMemoryManager >> allocateOldSpaceChunkOfBytes: chunkBytes [
	"Answer a chunk of oldSpace from the free lists, if available,
	 otherwise answer nil.  Break up a larger chunk if one of the
	 exact size does not exist.  N.B.  the chunk is simply a pointer, it
	 has no valid header.  The caller *must* fill in the header correctly."
	<var: #chunkBytes type: #usqInt>
	| initialIndex chunk index nodeBytes parent child |
	"for debugging:" "totalFreeOldSpace := self totalFreeListBytes"
	totalFreeOldSpace := totalFreeOldSpace - chunkBytes. "be optimistic (& don't wait for the write)"
	initialIndex := chunkBytes / self allocationUnit.
	(initialIndex < self numFreeLists and: [1 << initialIndex <= freeListsMask]) ifTrue:
		[(freeListsMask anyMask: 1 << initialIndex) ifTrue:
			[(chunk := freeLists at: initialIndex) ~= 0 ifTrue:
				[self assert: chunk = (self startOfObject: chunk).
				 self assertValidFreeObject: chunk.
				 self unlinkFreeChunk: chunk atIndex: initialIndex chunkBytes: chunkBytes.
				^ chunk].
			 freeListsMask := freeListsMask - (1 << initialIndex)].
		 "first search for free chunks of a multiple of chunkBytes in size"
		 index := initialIndex.
		 [(index := index + index) < self numFreeLists
		  and: [1 << index <= freeListsMask]] whileTrue:
			[(freeListsMask anyMask: 1 << index) ifTrue:
				[(chunk := freeLists at: index) ~= 0 ifTrue:
					[self assert: chunk = (self startOfObject: chunk).
					 self assertValidFreeObject: chunk.
					 self unlinkFreeChunk: chunk atIndex: index isLilliputianSize: false.
					 self assert: (self bytesInObject: chunk) = (index * self allocationUnit).
					 self freeChunkWithBytes: index * self allocationUnit - chunkBytes
						at: (self startOfObject: chunk) + chunkBytes.
					^chunk].
				 freeListsMask := freeListsMask - (1 << index)]].
		 "now get desperate and use the first that'll fit.
		  Note that because the minimum free size is 16 bytes (2 * allocationUnit), to
		  leave room for the forwarding pointer/next free link, we can only break chunks
		  that are at least 16 bytes larger, hence start at initialIndex + 2."
		 index := initialIndex + 1.
		 [(index := index + 1) < self numFreeLists
		  and: [1 << index <= freeListsMask]] whileTrue:
			[(freeListsMask anyMask: 1 << index) ifTrue:
				[(chunk := freeLists at: index) ~= 0 ifTrue:
					[self assert: chunk = (self startOfObject: chunk).
					 self assertValidFreeObject: chunk.
					 self unlinkFreeChunk: chunk atIndex: index isLilliputianSize: false.
					 self assert: (self bytesInObject: chunk) = (index * self allocationUnit).
					 self freeChunkWithBytes: index * self allocationUnit - chunkBytes
						at: (self startOfObject: chunk) + chunkBytes.
					^chunk].
				 freeListsMask := freeListsMask - (1 << index)]]].

	"Large chunk, or no space on small free lists.  Search the large chunk list.
	 Large chunk list organized as a tree, each node of which is a list of chunks
	 of the same size. Beneath the node are smaller and larger blocks.
	 When the search ends parent should hold the smallest chunk at least as
	 large as chunkBytes, or 0 if none."
	parent := 0.
	child := freeLists at: 0.
	[child ~= 0] whileTrue:
		[| childBytes |
		 self assertValidFreeObject: child.
		 childBytes := self bytesInObject: child.
		 childBytes = chunkBytes
			ifTrue: "size match; try to remove from list at node."
				[chunk := self fetchPointer: self freeChunkNextIndex
								ofFreeChunk: child.
				 chunk ~= 0 ifTrue:
					[self assertValidFreeObject: chunk.
					 self 
						setNextFreeChunkOf: child 
						withValue: (self fetchPointer: self freeChunkNextIndex ofFreeChunk: chunk) 
						isLilliputianSize: false.
					 ^self startOfObject: chunk].
				 nodeBytes := childBytes.
				 parent := child.
				 child := 0] "break out of loop to remove interior node"
			ifFalse:
				["Note that because the minimum free size is 16 bytes (2 * allocationUnit), to
				  leave room for the forwarding pointer/next free link, we can only break chunks
				  that are at least 16 bytes larger, hence reject chunks < 2 * allocationUnit larger."
				childBytes <= (chunkBytes + self allocationUnit)
					ifTrue: "node too small; walk down the larger size of the tree"
						[child := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: child]
					ifFalse:
						[parent := child. "parent will be smallest node >= chunkBytes + allocationUnit"
						 nodeBytes := childBytes.
						 child := self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: child]]].
	parent = 0 ifTrue:
		[totalFreeOldSpace := totalFreeOldSpace + chunkBytes. "optimism was unfounded"
		 ^nil].

	"self printFreeChunk: parent"
	self assert: (nodeBytes = chunkBytes or: [nodeBytes >= (chunkBytes + (2 * self allocationUnit))]).
	self assert: (self bytesInObject: parent) = nodeBytes.

	"attempt to remove from list"
	chunk := self fetchPointer: self freeChunkNextIndex ofFreeChunk: parent.
	chunk ~= 0 ifTrue:
		[self assert: (chunkBytes = nodeBytes or: [chunkBytes + self allocationUnit < nodeBytes]).
		self 
			setNextFreeChunkOf: parent 
			withValue: (self fetchPointer: self freeChunkNextIndex ofFreeChunk: chunk) 
			isLilliputianSize: false.
		 chunkBytes ~= nodeBytes ifTrue:
			[self freeChunkWithBytes: nodeBytes - chunkBytes
					at: (self startOfObject: chunk) + chunkBytes].
		 ^self startOfObject: chunk].

	"no list; remove the interior node"
	chunk := parent.
	self unlinkSolitaryFreeTreeNode: chunk.

	"if there's space left over, add the fragment back."
	chunkBytes ~= nodeBytes ifTrue:
		[self freeChunkWithBytes: nodeBytes - chunkBytes
				at: (self startOfObject: chunk) + chunkBytes].
	^self startOfObject: chunk
]

{ #category : #'free space' }
SpurMemoryManager >> allocateOldSpaceChunkOfBytes: chunkBytes suchThat: acceptanceBlock [
	"Answer a chunk of oldSpace from the free lists that satisfies acceptanceBlock,
	 if available, otherwise answer nil.  Break up a larger chunk if one of the exact
	 size cannot be found.  N.B.  the chunk is simply a pointer, it has no valid header.
	 The caller *must* fill in the header correctly."
	<var: #chunkBytes type: #usqInt>
	| initialIndex node next prev index child childBytes acceptedChunk acceptedNode |
	<inline: true> "must inline for acceptanceBlock"
	"for debugging:" "totalFreeOldSpace := self totalFreeListBytes"
	totalFreeOldSpace := totalFreeOldSpace - chunkBytes. "be optimistic (& don't wait for the write)"
	initialIndex := chunkBytes / self allocationUnit.
	(initialIndex < self numFreeLists and: [1 << initialIndex <= freeListsMask]) ifTrue:
		[(freeListsMask anyMask: 1 << initialIndex) ifTrue:
			[(node := freeLists at: initialIndex) = 0
				ifTrue: [freeListsMask := freeListsMask - (1 << initialIndex)]
				ifFalse:
					[prev := 0.
					 [node ~= 0] whileTrue:
						[self assert: node = (self startOfObject: node).
						 self assertValidFreeObject: node.
						 next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: node.
						 (acceptanceBlock value: node) ifTrue:
							[prev = 0
								ifTrue: [self unlinkFreeChunk: node atIndex: initialIndex chunkBytes: chunkBytes]
								ifFalse: [self setNextFreeChunkOf: prev withValue: next chunkBytes: chunkBytes].
							 ^node].
						 prev := node.
						 node := next]]].
		 "first search for free chunks of a multiple of chunkBytes in size"
		 index := initialIndex.
		 [(index := index + initialIndex) < self numFreeLists
		  and: [1 << index <= freeListsMask]] whileTrue:
			[(freeListsMask anyMask: 1 << index) ifTrue:
				[(node := freeLists at: index) = 0
					ifTrue: [freeListsMask := freeListsMask - (1 << index)]
					ifFalse:
						[prev := 0.
						 [node ~= 0] whileTrue:
							[self assert: node = (self startOfObject: node).
							  self assertValidFreeObject: node.
							 next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: node.
							 (acceptanceBlock value: node) ifTrue:
								[prev = 0
									ifTrue: [self unlinkFreeChunk: node atIndex: index isLilliputianSize: false.]
									ifFalse: [self setNextFreeChunkOf: prev withValue: next isLilliputianSize: false.]. 
								 self freeChunkWithBytes: index * self allocationUnit - chunkBytes
									at: (self startOfObject: node) + chunkBytes.
								 ^node].
							 prev := node.
							 node := next]]]].
		 "now get desperate and use the first that'll fit.
		  Note that because the minimum free size is 16 bytes (2 * allocationUnit), to
		  leave room for the forwarding pointer/next free link, we can only break chunks
		  that are at least 16 bytes larger, hence start at initialIndex + 2."
		 index := initialIndex + 1.
		 [(index := index + 1) < self numFreeLists
		  and: [1 << index <= freeListsMask]] whileTrue:
			[(freeListsMask anyMask: 1 << index) ifTrue:
				[(node := freeLists at: index) = 0
					ifTrue: [freeListsMask := freeListsMask - (1 << index)]
					ifFalse:
						[prev := 0.
						 [node ~= 0] whileTrue:
							[self assert: node = (self startOfObject: node).
							  self assertValidFreeObject: node.
							 next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: node.
							 (acceptanceBlock value: node) ifTrue:
								[prev = 0
									ifTrue: [self unlinkFreeChunk: node atIndex: index isLilliputianSize: false.]
									ifFalse: [self setNextFreeChunkOf: prev withValue: next isLilliputianSize: false.]. 
								 self freeChunkWithBytes: index * self allocationUnit - chunkBytes
									at: (self startOfObject: node) + chunkBytes.
								 ^node].
							 prev := node.
							 node := next]]]]].

	"Large chunk, or no space on small free lists.  Search the large chunk list.
	 Large chunk list organized as a tree, each node of which is a list of chunks
	 of the same size. Beneath the node are smaller and larger blocks.
	 When the search ends parent should hold the smallest chunk at least as
	 large as chunkBytes, or 0 if none.  acceptedChunk and acceptedNode save
	 us from having to back-up when the acceptanceBlock filters-out all nodes
	 of the right size, but there are nodes of the wrong size it does accept."
	child := freeLists at: 0.
	node := acceptedChunk := acceptedNode := 0.
	[child ~= 0] whileTrue:
		[ self assertValidFreeObject: child.
		 childBytes := self bytesInObject: child.
		 childBytes = chunkBytes ifTrue: "size match; try to remove from list at node."
			[node := child.
			 [prev := node.
			  node := self fetchPointer: self freeChunkNextIndex ofFreeChunk: node.
			  node ~= 0] whileTrue:
				[(acceptanceBlock value: node) ifTrue:
					[self assertValidFreeObject: node.
					 self 
						setNextFreeChunkOf: prev 
						withValue: (self fetchPointer: self freeChunkNextIndex ofFreeChunk: node) 
						isLilliputianSize: false.
					 ^self startOfObject: node]].
			 (acceptanceBlock value: child) ifTrue:
				[next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: child.
				 next = 0
					ifTrue: "no list; remove the interior node"
						[self unlinkSolitaryFreeTreeNode: child]
					ifFalse: "list; replace node with it"
						[self inFreeTreeReplace: child with: next].
				 ^self startOfObject: child]].
		 child ~= 0 ifTrue:
			["Note that because the minimum free size is 16 bytes (2 * allocationUnit), to
			  leave room for the forwarding pointer/next free link, we can only break chunks
			  that are at least 16 bytes larger, hence reject chunks < 2 * allocationUnit larger."
			childBytes <= (chunkBytes + self allocationUnit)
				ifTrue: "node too small; walk down the larger size of the tree"
					[child := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: child]
				ifFalse:
					[self flag: 'we can do better here; preferentially choosing the lowest node. That would be a form of best-fit since we are trying to compact down'.
					 node := child.
					 child := self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: node.
					 acceptedNode = 0 ifTrue:
						[acceptedChunk := node.
						 "first search the list."
						 [acceptedChunk := self fetchPointer: self freeChunkNextIndex
													ofFreeChunk: acceptedChunk.
						  (acceptedChunk ~= 0 and: [acceptanceBlock value: acceptedChunk]) ifTrue:
							[acceptedNode := node].
						  acceptedChunk ~= 0 and: [acceptedNode = 0]] whileTrue.
						 "nothing on the list; will the node do?  This prefers
						  acceptable nodes higher up the tree over acceptable
						  list elements further down, but we haven't got all day..."
						 (acceptedNode = 0
						  and: [acceptanceBlock value: node]) ifTrue:
							[acceptedNode := node.
							 child := 0 "break out of loop now we have an acceptedNode"]]]]].

	acceptedNode ~= 0 ifTrue:
		[acceptedChunk ~= 0 ifTrue:
			[self assert: (self bytesInObject: acceptedChunk) >= (chunkBytes + self allocationUnit).
			 [next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: acceptedNode.
			  next ~= acceptedChunk] whileTrue:
				[acceptedNode := next].
			 self 
				setNextFreeChunkOf: acceptedNode 
				withValue: (self fetchPointer: self freeChunkNextIndex ofFreeChunk: acceptedChunk) 
				isLilliputianSize: false.
			self freeChunkWithBytes: (self bytesInObject: acceptedChunk) - chunkBytes
					at: (self startOfObject: acceptedChunk) + chunkBytes.
			^self startOfObject: acceptedChunk].
		next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: acceptedNode.
		next = 0
			ifTrue: "no list; remove the interior node"
				[self unlinkSolitaryFreeTreeNode: acceptedNode]
			ifFalse: "list; replace node with it"
				[self inFreeTreeReplace: acceptedNode with: next].
		 self assert: (self bytesInObject: acceptedNode) >= (chunkBytes + self allocationUnit).
		 self freeChunkWithBytes: (self bytesInObject: acceptedNode) - chunkBytes
				at: (self startOfObject: acceptedNode) + chunkBytes.
		^self startOfObject: acceptedNode].

	totalFreeOldSpace := totalFreeOldSpace + chunkBytes. "optimism was unfounded"
	^nil
]

{ #category : #'sista support' }
SpurMemoryManager >> allocatePinnedSlots: nSlots [
	<api>
	| obj |
	obj := self allocateSlotsForPinningInOldSpace: nSlots
				bytes: (self objectBytesForSlots: nSlots)
				format: self wordIndexableFormat
				classIndex: 	self wordSizeClassIndexPun.
	obj ifNotNil:
		[self fillObj: obj numSlots: nSlots with: 0].
	^obj
]

{ #category : #allocation }
SpurMemoryManager >> allocateSlots: numSlots format: formatField classIndex: classIndex [
	"Allocate an object with numSlots space.  If there is room beneath scavengeThreshold
	 allocate in newSpace, otherwise alocate in oldSpace.  If there is not room in newSpace
	 and a scavenge is not already scheduled, schedule a scavenge."
	<api>
	^ self allocateSlots: numSlots format: formatField classIndex: classIndex isPinned: false
]

{ #category : #allocation }
SpurMemoryManager >> allocateSlots: numSlots format: formatField classIndex: classIndex isPinned: isPinned [

	<api>
	^ self subclassResponsibility
]

{ #category : #allocation }
SpurMemoryManager >> allocateSlotsForPinningInOldSpace: numSlots bytes: totalBytes format: formatField classIndex: classIndex [
	"Answer the oop of a chunk of space in oldSpace with numSlots slots.  Try and
	 allocate in a segment that already includes pinned objects.  The header of the
	 result will have been filled-in but not the contents."
	<var: #totalBytes type: #usqInt>
	^self subclassResponsibility
]

{ #category : #allocation }
SpurMemoryManager >> allocateSlotsInOldSpace: numSlots bytes: totalBytes format: formatField classIndex: classIndex [
	"Answer the oop of a chunk of space in oldSpace with numSlots slots.  The header
	 will have been filled-in but not the contents.  If no memory is available answer nil."
	<var: #totalBytes type: #usqInt>
	^self subclassResponsibility
]

{ #category : #allocation }
SpurMemoryManager >> allocateSlotsInOldSpace: numSlots format: formatField classIndex: classIndex [
	<inline: true>

	^ self
		allocateSlotsInOldSpace: numSlots
		format: formatField
		classIndex: classIndex
		isPinned: false
]

{ #category : #allocation }
SpurMemoryManager >> allocateSlotsInOldSpace: numSlots format: formatField classIndex: classIndex isPinned: isPinned [
	<inline: true>

	^ isPinned
		ifTrue: [ 
			self
				allocateSlotsForPinningInOldSpace: numSlots
				bytes: (self objectBytesForSlots: numSlots)
				format: formatField
				classIndex: classIndex ]
		ifFalse: [ 
			self
				allocateSlotsInOldSpace: numSlots
				bytes: (self objectBytesForSlots: numSlots)
				format: formatField
				classIndex: classIndex ]
]

{ #category : #allocation }
SpurMemoryManager >> allocateSmallNewSpaceSlots: numSlots format: formatField classIndex: classIndex [
	"Allocate an object with numSlots in newSpace, where numSlots is known to be small.
	 This is for the `ee' execution engine allocations, and must be satisfied.  If no memory
	 is available, abort.  If the allocation pushes freeStart past scavengeThreshold and a
	 scavenge is not already scheduled, schedule a scavenge."
	<inline: true>
	| numBytes newObj |
	self assert: numSlots < self numSlotsMask.
	newObj := freeStart.
	numBytes := self smallObjectBytesForSlots: numSlots.
	self assert: numBytes \\ self allocationUnit = 0.
	self assert: newObj \\ self allocationUnit = 0.
	freeStart + numBytes > scavengeThreshold ifTrue:
		[needGCFlag ifFalse: [self scheduleScavenge].
		 freeStart + numBytes > scavenger eden limit ifTrue:
			[self error: 'no room in eden for allocateSmallNewSpaceSlots:format:classIndex:'.
			 ^0]].
	self long64At: newObj put: (self headerForSlots: numSlots format: formatField classIndex: classIndex).
	freeStart := freeStart + numBytes.
	^newObj
]

{ #category : #allocation }
SpurMemoryManager >> allocationUnit [
	"All objects are a multiple of 8 bytes in length"
	^8
]

{ #category : #'primitive support' }
SpurMemoryManager >> ambiguousClass: aClass allInstancesInto: start limit: limit resultsInto: binaryBlock [
	"Dea with ambiguity and normalize indices."
	<inline: true>
	| expectedIndex count ptr |
	count := 0.
	ptr := start.
	expectedIndex := self rawHashBitsOf: aClass.
	self allHeapEntitiesDo:
		[:obj| | actualIndex | "continue enumerating even if no room so as to unmark all objects and/or normalize class indices."
		 (MarkObjectsForEnumerationPrimitives
				ifTrue: [self isMarked: obj]
				ifFalse: [true]) ifTrue:
			[(self isNormalObject: obj)
				ifTrue:
					[MarkObjectsForEnumerationPrimitives ifTrue:
						[self setIsMarkedOf: obj to: false].
					 actualIndex := self classIndexOf: obj.
					 (self classOrNilAtIndex: actualIndex) = aClass ifTrue:
					 	[actualIndex ~= expectedIndex ifTrue:
							[self setClassIndexOf: obj to: expectedIndex].
						 count := count + 1.
						 ptr < limit ifTrue:
							[self longAt: ptr put: obj.
							 ptr := ptr + self bytesPerOop]]]
				ifFalse:
					[MarkObjectsForEnumerationPrimitives ifTrue:
						[(self isSegmentBridge: obj) ifFalse:
							[self setIsMarkedOf: obj to: false]]]]].
	self purgeDuplicateClassTableEntriesFor: aClass.
	binaryBlock value: count value: ptr

]

{ #category : #'interpreter access' }
SpurMemoryManager >> areIntegers: oop1 and: oop2 [
	"Test oop1 and oop2 to make sure both are SmallIntegers.
	 In 32-bits the tags are 1 = SmallInteger & 3 = SmallInteger, and 2 = Character.
	 In 64-bits the  tags are 1 = SmallInteger, 2 = Character & 4 = SmallFloat64.
	 In both cases we can test for two SmallIntegers by anding them together and
	 if the result still has the least significant bit set then both are SmallIntegers."
	^(oop1 bitAnd: oop2) anyMask: self smallIntegerTag
]

{ #category : #'class table puns' }
SpurMemoryManager >> arrayClassIndexPun [
	"Class puns are class indices not used by any class.  There is an entry
	 for the pun that refers to the notional class of objects with this class
	 index.  But because the index doesn't match the class it won't show up
	 in allInstances, hence hiding the object with a pun as its class index.
	 The puns occupy indices 16 through 31."
	<cmacro>
	^16
]

{ #category : #'header formats' }
SpurMemoryManager >> arrayFormat [
	<api>
	^2
]

{ #category : #'simulation only' }
SpurMemoryManager >> arrayValueOf: arrayOop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter arrayValueOf: arrayOop
]

{ #category : #'free space' }
SpurMemoryManager >> assertFreeChunkPrevHeadZero [
	|min|
	self wordSize = 8 ifTrue: [min := 3] ifFalse: [min := 2].
	min to: self numFreeLists - 1 do:
		[:i| 
		 	(freeLists at: i) ~= 0 ifTrue:
				[self deny: (self isLilliputianSize: (freeLists at: i)).
				 self assert: (self fetchPointer: self freeChunkPrevIndex ofFreeChunk: (freeLists at: i)) = 0]].
	"Large chunks"
	self freeTreeNodesDo: [:freeNode |
		self assert: (self fetchPointer: self freeChunkPrevIndex ofFreeChunk: freeNode) = 0.
		freeNode].
	^ true
]

{ #category : #'free space' }
SpurMemoryManager >> assertInnerValidFreeObject: objOop [
	<inline: #never> "we don't want to inline so we can nest that in an assertion with the return true so the production VM does not generate any code here, while in simulation, the code breaks on the assertion we want to."
	| chunk index |
	self assert: (self oop: (self addressAfter: objOop) isLessThanOrEqualTo: endOfMemory).
	chunk := self fetchPointer: self freeChunkNextIndex ofFreeChunk: objOop.
	self assert: (chunk = 0 or: [self isFreeOop: chunk]).
	(self isLilliputianSize: (self bytesInObject: objOop)) ifFalse:
		["double linkedlist assertions"
		 chunk := self fetchPointer: self freeChunkNextIndex ofFreeChunk: objOop.
		 chunk = 0 ifFalse: 
			[self assert: (self isFreeOop: chunk).
			 self assert: objOop = (self fetchPointer: self freeChunkPrevIndex ofFreeChunk: chunk)].
		chunk := self fetchPointer: self freeChunkPrevIndex ofFreeChunk: objOop.
		index := (self bytesInObject: objOop) / self allocationUnit.
		(index < self numFreeLists and: [1 << index <= freeListsMask]) 
			ifTrue: 
				[(freeLists at: index) = objOop ifTrue: [self assert: chunk = 0]]
			ifFalse: 
				[self freeTreeNodesDo: [:freeNode |
					freeNode = objOop ifTrue: [self assert: chunk = 0]. freeNode]].
		 chunk = 0 ifFalse: 
			[self assert: (self isFreeOop: chunk).
			 self assert: objOop = (self fetchPointer: self freeChunkNextIndex ofFreeChunk: chunk)]].
	(self isLargeFreeObject: objOop) ifTrue: 
		["Tree assertions"
		chunk := self fetchPointer: self freeChunkParentIndex ofFreeChunk: objOop.
		self assert: (chunk = 0 or: [(self isFreeOop: chunk) and: [self isLargeFreeObject: chunk]]).
		chunk := self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: objOop.
		self assert: (chunk = 0 or: [(self isFreeOop: chunk) and: [self isLargeFreeObject: chunk]]).
		chunk := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: objOop.
		self assert: (chunk = 0 or: [(self isFreeOop: chunk) and: [self isLargeFreeObject: chunk]])].
	^ true
]

{ #category : #'free space' }
SpurMemoryManager >> assertValidFreeObject: objOop [
	<inline: true>
	"assertInnerValidFreeObject: is never inlined and always returns true.
	 For the production VM, this is entirely removed.
	 For the other VMs and in simulation, the code breaks at the first warning/assertion failure"
	self assert: (self assertInnerValidFreeObject: objOop)
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> assignClassIndicesAndPinFrom: segmentStart to: segmentLimit outPointers: outPointerArray filling: loadedObjectsArray [
	"This is part of loadImageSegmentFrom:outPointers:.
	 Make a final pass, assigning the real class indices and/or pinning pinned objects."
	| fillIdx objOop |
	objOop := self objectStartingAt: segmentStart.
	fillIdx := 0.
	[self oop: objOop isLessThan: segmentLimit] whileTrue:
		[| classRef classOop classIndex |
		 self storePointerUnchecked: fillIdx ofObject: loadedObjectsArray withValue: objOop.
		 fillIdx := fillIdx + 1.
		 "In the segment, class indices are offset indexes into the segment data,
		  or into outPointers.  See mapOopsFrom:to:outPointers:outHashes: and
		  newOutPointer:at:in:hashes:."
		 classRef := self classIndexOf: objOop.
		 classOop := (classRef anyMask: TopHashBit)
						ifTrue: [self fetchPointer: classRef - TopHashBit ofObject: outPointerArray]
						ifFalse: [classRef - self firstClassIndexPun * self allocationUnit + segmentStart].
		 classIndex := self rawHashBitsOf: classOop.
		 classIndex = 0 ifTrue:
			[classIndex := self ensureBehaviorHash: classOop.
			 classIndex < 0 ifTrue: "Error code e.g. - PrimErrNoMemory"
				[^classIndex negated halt]].
		 self assert: (classIndex > self lastClassIndexPun
					  and: [(self classOrNilAtIndex: classIndex) = classOop]).
		 self setClassIndexOf: objOop to: classIndex.
		 ((self isInNewSpace: objOop)
		  and: [self isPinned: objOop]) ifTrue:
			[| oldClone |
			 oldClone := self cloneInOldSpace: objOop forPinning: true.
			 oldClone ~= 0 ifTrue:
				[self setIsPinnedOf: oldClone to: true.
				 self forward: objOop to: oldClone]].
		 objOop := self objectAfter: objOop limit: segmentLimit]
]

{ #category : #'growing/shrinking memory' }
SpurMemoryManager >> assimilateNewSegment: segInfo [
	"Update after adding a segment.
	 Here we set freeOldSpaceStart & endOfMemory if required."
	<var: #segInfo type: #'SpurSegmentInfo *'>
	segInfo segLimit >= endOfMemory ifTrue:
		[freeOldSpaceStart :=
		 endOfMemory := segInfo segLimit - self bridgeSize]
]

{ #category : #compaction }
SpurMemoryManager >> atLeastClassIndexHalfHeader: obj [
	"PRIVATE: For compaction, answer the bits contaning the
	 classIndex and isPinned bits in the most natural form."
	^self longAt: obj
]

{ #category : #'growing/shrinking memory' }
SpurMemoryManager >> attemptToShrink [
	"Attempt to shrink memory after successfully reclaiming lots of memory.
	 If there's enough memory to shrink then be sure to attept to shrink by
	 at least growHeaqdroom because segments are typically of that size."
	(totalFreeOldSpace > shrinkThreshold
	 and: [totalFreeOldSpace > growHeadroom
	 and: [segmentManager shrinkObjectMemory: (totalFreeOldSpace - growHeadroom max: growHeadroom)]]) ifTrue:
		[statShrinkMemory := statShrinkMemory + 1]
]

{ #category : #accessing }
SpurMemoryManager >> averageObjectSizeInBytes [
	"Answer an approximation of the average object size.  This is a bit of an underestimate.
	 In the 32-bit system average object size is about 11 words per object, including header."
	^8 * self bytesPerOop
]

{ #category : #snapshot }
SpurMemoryManager >> baseAddressOfImage [
	^oldSpaceStart
]

{ #category : #'header access' }
SpurMemoryManager >> baseHeader: obj [
	^self long64At: obj
]

{ #category : #'header format' }
SpurMemoryManager >> baseHeaderSize [
	"Object headers are 8 bytes in length if the slot size fits in the slot size field (max implies overflow),
	 16 bytes otherwise (slot size in preceding word)."
	^8
]

{ #category : #'store check' }
SpurMemoryManager >> beRootIfOld: oop [ 
	"If this object is old, mark it as a root (because a new object
	 may be stored into it)."
	<api>
	<inline: false>
	(self isOldObject: oop) ifTrue:"No, oop is an old object"
		[self possibleRootStoreInto: oop]
]

{ #category : #'plugin support' }
SpurMemoryManager >> become: array1 with: array2 [
	<api>
	^self become: array1 with: array2 twoWay: true copyHash: true
]

{ #category : #'become api' }
SpurMemoryManager >> become: array1 with: array2 twoWay: twoWayFlag copyHash: copyHashFlag [
	"All references to each object in array1 are swapped with all references to the
	 corresponding object in array2. That is, all pointers to one object are replaced
	 with with pointers to the other. The arguments must be arrays of the same length. 
	 Answers PrimNoErr if the primitive succeeds, otherwise a relevant error code."
	"Implementation: Uses lazy forwarding to defer updating references until message send."
	<inline: false>
	| ec |
	self assert: becomeEffectsFlags = 0.
	self runLeakCheckerFor: GCModeBecome.
	(self isArray: array1) ifFalse:
		[^PrimErrBadReceiver].
	((self isArray: array2)
	 and: [(self numSlotsOf: array1) = (self numSlotsOf: array2)]) ifFalse:
		[^PrimErrBadArgument].
	ec := self containsOnlyValidBecomeObjects: array1 and: array2 twoWay: twoWayFlag copyHash: copyHashFlag.
	ec ~= 0 ifTrue:
		[becomeEffectsFlags := 0.
		 ^ec].

	coInterpreter preBecomeAction.
	twoWayFlag
		ifTrue:
			[self innerBecomeObjectsIn: array1 and: array2 copyHash: copyHashFlag]
		ifFalse:
			[self innerBecomeObjectsIn: array1 to: array2 copyHash: copyHashFlag].
	self followSpecialObjectsOop.
	"N.B. perform coInterpreter's postBecomeAction: *before* postBecomeScanClassTable:
	 to allow the coInterpreter to void method cache entries by spotting classIndices that
	 refer to forwarded objects. postBecomeScanClassTable: follows forwarders in the table."
	coInterpreter postBecomeAction: becomeEffectsFlags.
	self postBecomeScanClassTable: becomeEffectsFlags.
	becomeEffectsFlags := 0.

	self assert: self validClassTableHashes.
	self runLeakCheckerFor: GCModeBecome.

	^PrimNoErr "success"
]

{ #category : #'become implementation' }
SpurMemoryManager >> becomeEffectFlagsFor: objOop [
	"Answer the appropriate become effect flags for objOop, or 0 if none.
	 The effect flags determine how much work is done after the become
	 in following forwarding pointers, voiding method caches, etc."
	<inline: false>
	^(self isPointersNonImm: objOop)
		ifTrue:
			[| hash |
			 ((hash := self rawHashBitsOf: objOop) ~= 0
			  and: [(self classAtIndex: hash) = objOop])
				ifTrue: [BecamePointerObjectFlag + BecameActiveClassFlag]
				ifFalse: [BecamePointerObjectFlag]]
		ifFalse:
			[(self isCompiledMethod: objOop)
				ifTrue: [BecameCompiledMethodFlag]
				ifFalse: [0]]
]

{ #category : #'gc - scavenge/compact' }
SpurMemoryManager >> beginSlidingCompaction [
	gcPhaseInProgress := SlidingCompactionInProgress
]

{ #category : #'compaction - analysis' }
SpurMemoryManager >> biggies [
	"This method answers a sorted collection of the objects >= 1,000,000 bytes long,
	 above the lowest large free chunk, sandwiched between nilObj and the end of memory."
	<doNotGenerate>
	| lowestFree biggies |
	lowestFree := SmallInteger maxVal.
	self allObjectsInFreeTreeDo:
		[:f| (self addressAfter: f) < endOfMemory ifTrue: [f < lowestFree ifTrue: [lowestFree := f]]].
	biggies := SortedCollection new.
	self allOldSpaceObjectsFrom: lowestFree do:
		[:f|
		(self bytesInObject: f) >= 1000000 ifTrue:
			[biggies add: f]].
	^{{nilObj hex. #nil}}, (biggies collect: [:f| {f hex. self bytesInObject: f}]), {{endOfMemory hex. #endOfMemory}}
]

{ #category : #'debug support' }
SpurMemoryManager >> bitsSetInFreeSpaceMaskForAllFreeLists [
	0 to: self numFreeLists - 1 do:
		[:i|
		((freeLists at: i) ~= 0
		 and: [1 << i noMask: freeListsMask]) ifTrue:
			[^false]].
	^true
]

{ #category : #'primitive support' }
SpurMemoryManager >> booleanObjectOf: bool [
	<inline: true>
	^bool ifTrue: [trueObj] ifFalse: [falseObj]
]

{ #category : #'simulation only' }
SpurMemoryManager >> booleanValueOf: obj [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter booleanValueOf: obj
]

{ #category : #accessing }
SpurMemoryManager >> bootstrapping [
	<inline: true>
	^false
]

{ #category : #segments }
SpurMemoryManager >> bridgeSize [
	^2 * self baseHeaderSize
]

{ #category : #'header format' }
SpurMemoryManager >> byteFormatForNumBytes: numBytes [
	^self firstByteFormat + (8 - numBytes bitAnd: self wordSize - 1)
]

{ #category : #'header format' }
SpurMemoryManager >> byteFormatMask [
	^16r18
]

{ #category : #'object access' }
SpurMemoryManager >> byteSizeOf: oop [
	<api>
	(self isImmediate: oop) ifTrue: [^0].
	^self numBytesOf: oop
]

{ #category : #'indexing primitive support' }
SpurMemoryManager >> byteSizeOfInstanceOf: classObj errInto: errBlock [
	| instSpec classFormat numSlots |
	classFormat := self formatOfClass: classObj.
	instSpec := self instSpecOfClassFormat: classFormat.
	(self isFixedSizePointerFormat: instSpec) ifFalse:
		[^errBlock value: PrimErrBadReceiver]. "indexable"
	numSlots := self fixedFieldsOfClassFormat: classFormat.
	^self objectBytesForSlots: numSlots
]

{ #category : #'indexing primitive support' }
SpurMemoryManager >> byteSizeOfInstanceOf: classObj withIndexableSlots: nElements errInto: errorBlock [
	| instSpec classFormat numSlots |
	<var: 'numSlots' type: #usqInt>
	classFormat := self formatOfClass: classObj.
	instSpec := self instSpecOfClassFormat: classFormat.
	instSpec caseOf: {
		[self arrayFormat]	->
			[numSlots := nElements].
		[self indexablePointersFormat]	->
			[numSlots := (self fixedFieldsOfClassFormat: classFormat) + nElements].
		[self weakArrayFormat]	->
			[numSlots := (self fixedFieldsOfClassFormat: classFormat) + nElements].
		[self sixtyFourBitIndexableFormat]	->
			[numSlots := self bytesPerOop = 4 ifTrue: [nElements * 2] ifFalse: [nElements]].
		[self firstLongFormat]	->
			[numSlots := self bytesPerOop = 4 ifTrue: [nElements] ifFalse: [nElements + 1 // 2]].
		[self firstShortFormat]	->
			[numSlots := self bytesPerOop = 4 ifTrue: [nElements + 1 // 2] ifFalse: [nElements + 3 // 4]].
		[self firstByteFormat]	->
			[numSlots := nElements + (self bytesPerOop - 1) // self bytesPerOop].
		[self firstCompiledMethodFormat]	-> "Assume nElements is derived from CompiledMethod>>basicSize."
			[numSlots := nElements + (self bytesPerOop - 1) // self bytesPerOop] }
		otherwise: [^errorBlock value: PrimErrBadReceiver]. "non-indexable"
	numSlots >= (1 asUnsignedInteger << (self bytesPerOop * 8 - self logBytesPerOop)) ifTrue:
		[^errorBlock value: (nElements < 0 ifTrue: [PrimErrBadArgument] ifFalse: [PrimErrLimitExceeded])].
	^self objectBytesForSlots: numSlots
]

{ #category : #snapshot }
SpurMemoryManager >> byteSwapped: w [
	self subclassResponsibility
]

{ #category : #'object enumeration' }
SpurMemoryManager >> bytesInObject: objOop [
	"Answer the total number of bytes in an object including header and possible overflow size header."
	self subclassResponsibility
]

{ #category : #'free space' }
SpurMemoryManager >> bytesLeft: includeSwapSpace [
	"Answer the amount of available free space. If includeSwapSpace is true, include
	 possibly available swap space. If includeSwapSpace is false, include possibly available
	 physical memory.  N.B. includeSwapSpace is ignored; answer total heap free space
	 minus the reserve available for flushing the tsack zone."
	^totalFreeOldSpace
	+ (scavenger eden limit - freeStart)
	+ (scavenger pastSpace limit - pastSpaceStart)
	+ (scavenger futureSpace limit - scavenger futureSpace limit)
	- coInterpreter interpreterAllocationReserveBytes
]

{ #category : #'free space' }
SpurMemoryManager >> bytesLeftInOldSpace [
	"Answer the amount of available free old space.  Used by primitiveFullGC
	 to answer the current available memory."
	^totalFreeOldSpace
]

{ #category : #accessing }
SpurMemoryManager >> bytesPerOop [
	self subclassResponsibility
]

{ #category : #'obj stacks' }
SpurMemoryManager >> capacityOfObjStack: objStack [
	| total freeObj |
	objStack = nilObj ifTrue: [^0].
	total := ObjStackLimit negated.
	freeObj := objStack.
	[freeObj ~= 0] whileTrue:
		[total := total + ObjStackLimit.
		 freeObj := self fetchPointer: ObjStackFreex ofObject: freeObj].
	freeObj := objStack.
	[freeObj ~= 0] whileTrue:
		[total := total + ObjStackLimit.
		 freeObj := self fetchPointer: ObjStackNextx ofObject: freeObj].
	^total
]

{ #category : #'interpreter access' }
SpurMemoryManager >> changeClassOf: rcvr to: argClass [
	"Attempt to change the class of the receiver to the argument given that the
	 format of the receiver matches the format of the argument.  If successful,
	 answer 0, otherwise answer an error code indicating the reason for failure. 
	 Fail if the format of the receiver is incompatible with the format of the argument,
	 or if the argument is a fixed class and the receiver's size differs from the size
	 that an instance of the argument should have."
	self subclassResponsibility
]

{ #category : #'object access' }
SpurMemoryManager >> characterObjectOf: characterCode [
	<api>
	^characterCode << self numTagBits + self characterTag
]

{ #category : #accessing }
SpurMemoryManager >> characterTable [
	self shouldNotImplement
]

{ #category : #'object access' }
SpurMemoryManager >> characterTag [
	<api>
	<cmacro>
	^2
]

{ #category : #immediates }
SpurMemoryManager >> characterValueOf: oop [
	"Immediate characters are unsigned"
	<api>
	^oop asUnsignedInteger >> self numTagBits
]

{ #category : #'debug support' }
SpurMemoryManager >> cheapAddressCouldBeInHeap: address [ 
	^(address bitAnd: self wordSize - 1) = 0
	  and: [(self oop: address isGreaterThanOrEqualTo: newSpaceStart)
	  and: [self oop: address isLessThan: endOfMemory]]
]

{ #category : #'plugin support' }
SpurMemoryManager >> cheapIsInMemory: address [
	"Answer if the given address is in ST object memory.  For simulation only."
	<doNotGenerate>
	^address >= newSpaceStart and: [address < endOfMemory]
]

{ #category : #allocation }
SpurMemoryManager >> checkAllocFiller [
	<doNotGenerate>
	"in the Spur bootstrap coInterpreter may not be initialized..."
	^coInterpreter notNil and: [coInterpreter checkAllocFiller]
]

{ #category : #initialization }
SpurMemoryManager >> checkCompactIndex: classIndex isClass: specialIndex named: name [
	"Check that a class the VM assumes is compact has the right index."
	<inline: true> "macrofication of the name arg in invalidCompactClassError only works if this method is inlined so the name is a string literal not a parameter"
	(classIndex ~= 0
	 and: [(self splObj: specialIndex) ~= (self knownClassAtIndex: classIndex)]) ifTrue:
		[self invalidCompactClassError: name]
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> checkForAvailableSlots: slots [
	"Check for slots worth of free space being available.  Answer if that many slots are available.
	 If that many slots are not availabe, schedule a scavenge."
	<inline: true>
	freeStart + (self bytesPerOop * slots) <= scavengeThreshold ifTrue:
		[^true].
	needGCFlag := true.
	^false
]

{ #category : #'debug support' }
SpurMemoryManager >> checkForCompactableObjects [
	"self checkForCompactableObjects"
	<doNotGenerate>
	| firstFree them sizes |
	firstFree := 0.
	self allOldSpaceEntitiesDo: [:o| (firstFree = 0 and: [self isFreeObject: o]) ifTrue: [firstFree := o]].
	firstFree = 0 ifTrue: [^nil].
	sizes := Bag new.
	self allFreeObjectsDo:
		[:f| sizes add: (self bytesInObject: f)].
	them := OrderedCollection new.
	self allOldSpaceObjectsFrom: firstFree do:
		[:o| | b |
		b := self bytesInObject: o.
		(sizes includes: b) ifTrue:
			[them add: o.
			 sizes remove: b]].
	^them isEmpty ifFalse:
		[{them size. them first. them last}]
]

{ #category : #accessing }
SpurMemoryManager >> checkForLeaks [
	^checkForLeaks
]

{ #category : #'debug support' }
SpurMemoryManager >> checkFreeSpace [
	"Bootstrap only"
	<doNotGenerate>
	self checkFreeSpace: GCModeFull
]

{ #category : #'debug support' }
SpurMemoryManager >> checkFreeSpace: gcModes [
	self assert: self bitsSetInFreeSpaceMaskForAllFreeLists.
	self assert: totalFreeOldSpace = self totalFreeListBytes.
	(gcModes > 0
	 and: [checkForLeaks allMask: (GCModeFreeSpace bitOr: gcModes)]) ifTrue:
		[self runLeakCheckerForFreeSpace: GCModeFreeSpace]
]

{ #category : #'debug support' }
SpurMemoryManager >> checkHeapFreeSpaceIntegrity [
	"Perform an integrity/leak check using the heapMap.  Assume clearLeakMapAndMapAccessibleFreeSpace
	 has set a bit at each free chunk's header.  Scan all objects in the heap checking that no pointer points
	 to a free chunk and that all free chunks that refer to others refer to marked chunks.  Answer if all checks pass."
	| ok total |
	<inline: false>
	<var: 'total' type: #usqInt>
	ok := true.
	total := 0.
	0 to: self numFreeLists - 1 do:
		[:i|
		(freeLists at: i) ~= 0 ifTrue:
			[(heapMap heapMapAtWord: (self pointerForOop: (freeLists at: i))) = 0 ifTrue:
				[coInterpreter print: 'leak in free list '; printNum: i; print: ' to non-free '; printHex: (freeLists at: i); cr.
				 self eek.
				 ok := false]]].

	"Excuse the duplication but performance is at a premium and we avoid
	 some tests by splitting the newSpace and oldSpace enumerations."
	self allNewSpaceEntitiesDo:
		[:obj| | fieldOop |
		 (self isFreeObject: obj)
			ifTrue:
				[coInterpreter print: 'young object '; printHex: obj; print: ' is free'; cr.
				 self eek.
				 ok := false]
			ifFalse:
				[0 to: (self numPointerSlotsOf: obj) - 1 do:
					[:fi|
					 fieldOop := self fetchPointer: fi ofObject: obj.
					 (self isNonImmediate: fieldOop) ifTrue:
						[(heapMap heapMapAtWord: (self pointerForOop: fieldOop)) ~= 0 ifTrue:
							[coInterpreter print: 'object leak in '; printHex: obj; print: ' @ '; printNum: fi; print: ' = '; printHex: fieldOop; print: ' is free'; cr.
							 self eek.
							 ok := false]]]]].
	self allOldSpaceEntitiesDo:
		[:obj| | fieldOop |
		(self isFreeObject: obj)
			ifTrue:
				[(heapMap heapMapAtWord: (self pointerForOop: obj)) = 0 ifTrue:
					[coInterpreter print: 'leak in free chunk '; printHex: obj; print: ' is unmapped?! '; cr.
					 self eek.
					 ok := false].
				 fieldOop := self fetchPointer: self freeChunkNextIndex ofFreeChunk: obj.
				 (fieldOop ~= 0
				 and: [(heapMap heapMapAtWord: (self pointerForOop: fieldOop)) = 0]) ifTrue:
					[coInterpreter print: 'leak in free chunk '; printHex: obj; print: ' @ 0 = '; printHex: fieldOop; print: ' is unmapped'; cr.
					 self eek.
					 ok := false].
				(self isLilliputianSize: (self bytesInObject: obj)) ifFalse:
					[fieldOop := self fetchPointer: self freeChunkPrevIndex ofFreeChunk: obj.
					 (fieldOop ~= 0
					 and: [(heapMap heapMapAtWord: (self pointerForOop: fieldOop)) = 0]) ifTrue:
						[coInterpreter print: 'leak in free chunk '; printHex: obj; print: ' @ 0 = '; printHex: fieldOop; print: ' is unmapped'; cr.
						 self eek.
						 ok := false]].
				(self isLargeFreeObject: obj) ifTrue:
					[self freeChunkParentIndex to: self freeChunkLargerIndex do:
						[:fi|
						 fieldOop := self fetchPointer: fi ofFreeChunk: obj.
						 (fieldOop ~= 0
						 and: [(heapMap heapMapAtWord: (self pointerForOop: fieldOop)) = 0]) ifTrue:
							[coInterpreter print: 'leak in free chunk '; printHex: obj; print: ' @ '; printNum: fi; print: ' = '; printHex: fieldOop; print: ' is unmapped'; cr.
							 self eek.
							 ok := false]]].
				total := total + (self bytesInObject: obj)]
			ifFalse:
				[0 to: (self numPointerSlotsOf: obj) - 1 do:
					[:fi|
					 (self isForwarded: obj)
						ifTrue: 
							[self assert: fi = 0. "I'm now trying to use forwarders in GC algorithms..."
							 fieldOop := self fetchPointer: fi ofMaybeForwardedObject: obj] 
						ifFalse: "We keep #fetchPointer:ofObject: API here for assertions"
							[fieldOop := self fetchPointer: fi ofObject: obj].
					 (self isNonImmediate: fieldOop) ifTrue:
						[(heapMap heapMapAtWord: (self pointerForOop: fieldOop)) ~= 0 ifTrue:
							[coInterpreter print: 'object leak in '; printHex: obj; print: ' @ '; printNum: fi; print: ' = '; printHex: fieldOop; print: ' is free'; cr.
							 self eek.
							 ok := false]]]]].
	total ~= totalFreeOldSpace ifTrue:
		[coInterpreter print: 'incorrect totalFreeOldSpace; expected '; printNum: totalFreeOldSpace; print: ' found '; printNum: total; cr.
		 self eek.
		 ok := false].
	^ok
]

{ #category : #'debug support' }
SpurMemoryManager >> checkHeapIntegrity: excludeUnmarkedObjs classIndicesShouldBeValid: classIndicesShouldBeValid [
	"Perform an integrity/leak check using the heapMap.  Assume clearLeakMapAndMapAccessibleObjects
	 has set a bit at each (non-free) object's header.  Scan all objects in the heap checking that every
	 pointer points to a header.  Scan the rememberedSet, remapBuffer and extraRootTable checking
	 that every entry is a pointer to a header. Check that the number of roots is correct and that all
	 rememberedSet entries have their isRemembered: flag set.  Answer if all checks pass."
	| ok numRememberedObjectsInHeap |
	<inline: false>
	self cCode: []
		inSmalltalk:
			["Almost all of the time spent here used to go into the asserts in fetchPointer:ofObject: in the
			  simulator class overrides. Since we know here the indices used are valid we temporarily
			  remove them to claw back that performance."
			(self class whichClassIncludesSelector: #fetchPointer:ofObject:) ~= SpurMemoryManager ifTrue:
				[^self withSimulatorFetchPointerMovedAsideDo:
					[self checkHeapIntegrity: excludeUnmarkedObjs
						classIndicesShouldBeValid: classIndicesShouldBeValid]]].
	ok := true.
	numRememberedObjectsInHeap := 0.
	0 to: self numFreeLists - 1 do:
		[:i|
		(freeLists at: i) ~= 0 ifTrue:
			[(heapMap heapMapAtWord: (self pointerForOop: (freeLists at: i))) ~= 0 ifTrue:
				[coInterpreter print: 'leak in free list '; printNum: i; print: ' to non-free '; printHex: (freeLists at: i); cr.
				 self eek.
				 ok := false]]].

	"Excuse the duplication but performance is at a premium and we avoid
	 some tests by splitting the newSpace and oldSpace enumerations."
	self allNewSpaceEntitiesDo:
		[:obj| | fieldOop classIndex classOop |
		(self isFreeObject: obj)
			ifTrue:
				[coInterpreter print: 'young object '; printHex: obj; print: ' is free'; cr.
				 self eek.
				 ok := false]
			ifFalse:
				[((self isMarked: obj) not and: [excludeUnmarkedObjs]) ifFalse:
					[(self isRemembered: obj) ifTrue:
						[coInterpreter print: 'young object '; printHex: obj; print: ' is remembered'; cr.
						 self eek.
						 ok := false]].
					 (self isForwarded: obj)
						ifTrue:
							[fieldOop := self fetchPointer: 0 ofMaybeForwardedObject: obj.
							 (heapMap heapMapAtWord: (self pointerForOop: fieldOop)) = 0 ifTrue:
								[coInterpreter print: 'object leak in forwarder '; printHex: obj; print: ' to unmapped '; printHex: fieldOop; cr.
								 self eek.
								 ok := false]]
						ifFalse:
							[classOop := self classOrNilAtIndex: (classIndex := self classIndexOf: obj).
							 (classIndicesShouldBeValid
							  and: [classOop = nilObj
							  and: [(self isHiddenObj: obj) not]]) ifTrue:
								[coInterpreter print: 'object leak in '; printHex: obj; print: ' invalid class index '; printHex: classIndex; print: ' -> '; print: (classOop ifNil: ['nil'] ifNotNil: ['nilObj']); cr.
								 self eek.
								 ok := false].
							 0 to: (self numPointerSlotsOf: obj) - 1 do:
								[:fi|
								 fieldOop := self fetchPointer: fi ofObject: obj.
								 (self isNonImmediate: fieldOop) ifTrue:
									[(heapMap heapMapAtWord: (self pointerForOop: fieldOop)) = 0 ifTrue:
										[coInterpreter print: 'object leak in '; printHex: obj; print: ' @ '; printNum: fi; print: ' = '; printHex: fieldOop; cr.
										 self eek.
										 ok := false]]]]]].
	self allOldSpaceEntitiesDo:
		[:obj| | containsYoung fieldOop classIndex classOop |
		(self isFreeObject: obj)
			ifTrue:
				[(heapMap heapMapAtWord: (self pointerForOop: obj)) ~= 0 ifTrue:
					[coInterpreter print: 'leak in free chunk '; printHex: obj; print: ' is mapped?! '; cr.
					 self eek.
					 ok := false].
				 fieldOop := self fetchPointer: self freeChunkNextIndex ofFreeChunk: obj.
				 (fieldOop ~= 0
				 and: [(heapMap heapMapAtWord: (self pointerForOop: fieldOop)) ~= 0]) ifTrue:
					[coInterpreter print: 'leak in free chunk '; printHex: obj; print: ' @ 0 = '; printHex: fieldOop; print: ' is mapped'; cr.
					 self eek.
					 ok := false].
				(self isLilliputianSize: (self bytesInObject: obj)) ifFalse:
					[fieldOop := self fetchPointer: self freeChunkPrevIndex ofFreeChunk: obj.
					 (fieldOop ~= 0
					 and: [(heapMap heapMapAtWord: (self pointerForOop: fieldOop)) ~= 0]) ifTrue:
						[coInterpreter print: 'leak in free chunk '; printHex: obj; print: ' @ 1 = '; printHex: fieldOop; print: ' is mapped'; cr.
						 self eek.
						 ok := false]].
				(self isLargeFreeObject: obj) ifTrue:
					[self freeChunkParentIndex to: self freeChunkLargerIndex do:
						[:fi|
						 fieldOop := self fetchPointer: fi ofFreeChunk: obj.
						 (fieldOop ~= 0
						 and: [(heapMap heapMapAtWord: (self pointerForOop: fieldOop)) ~= 0]) ifTrue:
							[coInterpreter print: 'leak in free chunk '; printHex: obj; print: ' @ '; printNum: fi; print: ' = '; printHex: fieldOop; print: ' is mapped'; cr.
							 self eek.
							 ok := false].]]]
			ifFalse:
				[(excludeUnmarkedObjs and: [(self isMarked: obj) not]) ifFalse:
					[containsYoung := false.
					 (self isRemembered: obj) ifTrue:
						[numRememberedObjectsInHeap := numRememberedObjectsInHeap + 1.
						 (scavenger isInRememberedSet: obj) ifFalse:
							[coInterpreter print: 'remembered object '; printHex: obj; print: ' is not in remembered table'; cr.
							 self eek.
							 ok := false]].
					 (self isForwarded: obj)
						ifTrue:
							[fieldOop := self fetchPointer: 0 ofMaybeForwardedObject: obj.
							 (heapMap heapMapAtWord: (self pointerForOop: fieldOop)) = 0 ifTrue:
								[coInterpreter print: 'object leak in forwarder '; printHex: obj; print: ' to unmapped '; printHex: fieldOop; cr.
								 self eek.
								 ok := false].
							 (self isReallyYoung: fieldOop) ifTrue:
								[containsYoung := true]]
						ifFalse:
							[classOop := self classOrNilAtIndex: (classIndex := self classIndexOf: obj).
							 (classIndicesShouldBeValid
							  and: [classOop = nilObj
							  and: [classIndex > self lastClassIndexPun]]) ifTrue:
								[coInterpreter print: 'object leak in '; printHex: obj; print: ' invalid class index '; printHex: classIndex; print: ' -> '; print: (classOop ifNil: ['nil'] ifNotNil: ['nilObj']); cr.
								 self eek.
								 ok := false].
							 0 to: (self numPointerSlotsOf: obj) - 1 do:
								[:fi|
								 fieldOop := self fetchPointer: fi ofObject: obj.
								 (self isNonImmediate: fieldOop) ifTrue:
									[(self heapMapAtWord: (self pointerForOop: fieldOop)) = 0 ifTrue:
										[coInterpreter print: 'object leak in '; printHex: obj; print: ' @ '; printNum: fi; print: ' = '; printHex: fieldOop; cr.
										 self eek.
										 ok := false].
									 "don't be misled by CogMethods; they appear to be young, but they're not"
									 (self isReallyYoung: fieldOop) ifTrue:
										[containsYoung := true]]]].
					 containsYoung ifTrue:
						[(self isRemembered: obj) ifFalse:
							[coInterpreter print: 'unremembered object '; printHex: obj; print: ' contains young oop(s)'; cr.
							 self eek.
							 ok := false]]]]].
	numRememberedObjectsInHeap ~= scavenger rememberedSetSize ifTrue:
		[coInterpreter
			print: 'root count mismatch. #heap roots ';
			printNum: numRememberedObjectsInHeap;
			print: '; #roots ';
			printNum: scavenger rememberedSetSize;
			cr.
		self eek.
		"But the system copes with overflow..."
		self flag: 'no support for remembered set overflow yet'.
		"ok := rootTableOverflowed and: [needGCFlag]"].
	scavenger rememberedSetWithIndexDo:
		[:obj :i|
		(obj bitAnd: self wordSize - 1) ~= 0
			ifTrue:
				[coInterpreter print: 'misaligned oop in remembered set @ '; printNum: i; print: ' = '; printHex: obj; cr.
				 self eek.
				 ok := false]
			ifFalse:
				[(heapMap heapMapAtWord: (self pointerForOop: obj)) = 0
					ifTrue:
						[coInterpreter print: 'object leak in remembered set @ '; printNum: i; print: ' = '; printHex: obj; cr.
						 self eek.
						 ok := false]
					ifFalse:
						[(self isYoung: obj) ifTrue:
							[coInterpreter print: 'non-root in remembered set @ '; printNum: i; print: ' = '; printHex: obj; cr.
							 self eek.
							 ok := false]]]].
	self objStack: mournQueue do:
		[:i :page| | obj |
		obj := self fetchPointer: i ofObject: page.
		(obj bitAnd: self wordSize - 1) ~= 0
			ifTrue:
				[coInterpreter print: 'misaligned oop in mournQueue @ '; printNum: i; print: ' in '; printHex: page; print: ' = '; printHex: obj; cr.
				 self eek.
				 ok := false]
			ifFalse:
				[(excludeUnmarkedObjs and: [(self isMarked: obj) not]) ifFalse:
					[(heapMap heapMapAtWord: (self pointerForOop: obj)) = 0 ifTrue:
						[coInterpreter print: 'object leak in mournQueue @ '; printNum: i; print: ' in '; printHex: page; print: ' = '; printHex: obj; cr.
						 self eek.
						 ok := false]]]].
	1 to: remapBufferCount do:
		[:ri| | obj |
		obj := remapBuffer at: ri.
		(obj bitAnd: self wordSize - 1) ~= 0
			ifTrue:
				[coInterpreter print: 'misaligned remapRoot @ '; printNum: ri; print: ' = '; printHex: obj; cr.
				 self eek.
				 ok := false]
			ifFalse:
				[(heapMap heapMapAtWord: (self pointerForOop: obj)) = 0 ifTrue:
					[coInterpreter print: 'object leak in remapRoots @ '; printNum: ri; print: ' = '; printHex: obj; cr.
					 self eek.
					 ok := false]]].
	1 to: extraRootCount do:
		[:ri| | obj |
		obj := (extraRoots at: ri) at: 0.
		(obj bitAnd: self wordSize - 1) ~= 0
			ifTrue:
				[coInterpreter print: 'misaligned extraRoot @ '; printNum: ri; print: ' => '; printHex: obj; cr.
				 self eek.
				 ok := false]
			ifFalse:
				[(heapMap heapMapAtWord: (self pointerForOop: obj)) = 0 ifTrue:
					[coInterpreter print: 'object leak in extraRoots @ '; printNum: ri; print: ' => '; printHex: obj; cr.
					 self eek.
					 ok := false]]].
	^ok
]

{ #category : #'debug support' }
SpurMemoryManager >> checkMemoryMap [
	self assert: (self isYoungObject: newSpaceStart).
	self assert: (self isYoungObject: newSpaceLimit - self wordSize).
	self assert: (self isOldObject: newSpaceStart) not.
	self assert: (self isOldObject: newSpaceLimit - self wordSize) not.
	self assert: (self isYoungObject: newSpaceLimit) not.
	self assert: (self isYoungObject: oldSpaceStart) not.
	self assert: (self isYoungObject: endOfMemory) not.
	self assert: (self isOldObject: newSpaceLimit).
	self assert: (self isOldObject: oldSpaceStart).
	self assert: (self isOldObject: endOfMemory)
]

{ #category : #'debug support' }
SpurMemoryManager >> checkOkayOop: oop [
	"Verify that the given oop is legitimate. Check address, header, and size but not class.
	 Answer true if OK.  Otherwise print reason and answer false."
	<api>
	<var: #oop type: #usqInt>
	| classIndex fmt unusedBits unusedBitsInYoungObjects |
	<var: #unusedBits type: #usqLong>

	"address and size checks"
	(self isImmediate: oop) ifTrue: [^true].
	(self addressCouldBeObj: oop) ifFalse:
		[self print: 'oop '; printHex: oop; print: ' is not a valid address'. ^false].

	(self oop: (self addressAfter: oop) isLessThanOrEqualTo: endOfMemory) ifFalse:
		[self print: 'oop '; printHex: oop; print: ' size would make it extend beyond the end of memory'. ^false].

	"header type checks"
	(classIndex := self classIndexOf: oop) >= self firstClassIndexPun ifFalse:
		[self print: 'oop '; printHex: oop; print: ' is a free chunk, or bridge, not an object'. ^false].
	((self rawNumSlotsOf: oop) = self numSlotsMask
	 and: [(self rawNumSlotsOf: oop - self baseHeaderSize) ~= self numSlotsMask]) ifTrue:
		[self print: 'oop '; printHex: oop; print: ' header has overflow header word, but overflow word does not have a saturated numSlots field'. ^false].

	"format check"
	fmt := self formatOf: oop.
	(fmt = 6) | (fmt = 8) ifTrue:
		[self print: 'oop '; printHex: oop; print: ' has an unknown format type'. ^false].
	(fmt = self forwardedFormat) ~= (classIndex = self isForwardedObjectClassIndexPun) ifTrue:
		[self print: 'oop '; printHex: oop; print: ' has mis-matched format/classIndex fields; only one of them is the isForwarded value'. ^false].

	"specific header bit checks"
	unusedBits := (1 << self classIndexFieldWidth)
				   bitOr: (1 << (self identityHashFieldWidth + 32)).
	((self long64At: oop) bitAnd: unusedBits) ~= 0 ifTrue:
		[self print: 'oop '; printHex: oop; print: ' has some unused header bits set; should be zero'. ^false].

	unusedBitsInYoungObjects := self newSpaceRefCountMask.
	((self longAt: oop) bitAnd: unusedBitsInYoungObjects) ~= 0 ifTrue:
		[self print: 'oop '; printHex: oop; print: ' has some header bits unused in young objects set; should be zero'. ^false].
	^true
]

{ #category : #'debug support' }
SpurMemoryManager >> checkOkayYoungReferrer: obj [
	"Verify that the given obj is a valid youngReferrer. Check remembered is set and
	 is in remembered set.  Answer true if OK.  Otherwise print reason and answer false.
	 Assumes the object contains young references."

	(self oop: obj isLessThan: newSpaceLimit) ifTrue:
		[^true].

	(self isRemembered: obj) ifFalse:
		[ self print: 'remembered bit is not set in '; printHex: obj; cr. ^false ].

	(scavenger isInRememberedSet: obj) ifTrue: [^true].

	self printHex: obj; print: ' has remembered bit set but is not in remembered set'; cr.

	^false

]

{ #category : #'debug support' }
SpurMemoryManager >> checkOopHasOkayClass: obj [
	"Attempt to verify that the given obj has a reasonable behavior. The class must be a
	 valid, non-integer oop and must not be nilObj. It must be a pointers object with three
	 or more fields. Finally, the instance specification field of the behavior must match that
	 of the instance. If OK answer true.  If  not, print reason and answer false."

	<api>
	<var: #obj type: #usqInt>
	| objClass objFormat |
	<var: #objClass type: #usqInt>

	(self checkOkayOop: obj) ifFalse:
		[^false].
	objClass := self cCoerce: (self fetchClassOfNonImm: obj) to: #usqInt.

	(self isImmediate: objClass) ifTrue:
		[self print: 'obj '; printHex: obj; print: ' an immediate is not a valid class or behavior'; cr. ^false].
	(self okayOop: objClass) ifFalse:
		[self print: 'obj '; printHex: obj; print: ' class obj is not ok'; cr. ^false].
	((self isPointersNonImm: objClass) and: [(self numSlotsOf: objClass) >= 3]) ifFalse:
		[self print: 'obj '; printHex: obj; print: ' a class (behavior) must be a pointers object of size >= 3'; cr. ^false].
	objFormat := (self isBytes: obj)
						ifTrue: [(self formatOf: obj) bitClear: 7]  "ignore extra bytes size bits"
						ifFalse: [self formatOf: obj].

	(self instSpecOfClass: objClass) ~= objFormat ifTrue:
		[self print: 'obj '; printHex: obj; print: ' and its class (behavior) formats differ'; cr. ^false].
	^true
]

{ #category : #'debug support' }
SpurMemoryManager >> checkOopIntegrity: obj named: name [
	<inline: false>
	<var: #name type: #'char *'>
	(heapMap heapMapAtWord: (self pointerForOop: obj)) ~= 0 ifTrue:
		[^true].
	coInterpreter print: name; print: ' leak '; printHex: obj; cr.
	^false
]

{ #category : #'debug support' }
SpurMemoryManager >> checkOopIntegrity: obj named: name index: i [
	<inline: false>
	<var: #name type: #'char *'>
	(heapMap heapMapAtWord: (self pointerForOop: obj)) ~= 0 ifTrue:
		[^true].
	coInterpreter print: name; print: ' leak @ '; printNum: i; print: ' = '; printHex: obj; cr.
	^false
]

{ #category : #'simulation only' }
SpurMemoryManager >> checkedIntegerValueOf: intOop [
	<doNotGenerate>
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter checkedIntegerValueOf: intOop
]

{ #category : #'memory access' }
SpurMemoryManager >> checkedLongAt: byteAddress [
	"Assumes zero-based array indexing."
	<api>
	(self isInMemory: byteAddress) ifFalse:
		[self warning: 'checkedLongAt bad address'.
		 coInterpreter primitiveFail].
	^self longAt: byteAddress
]

{ #category : #accessing }
SpurMemoryManager >> classAlien [
	^self splObj: ClassAlien
]

{ #category : #'plugin support' }
SpurMemoryManager >> classArray [
	<api>
	^self splObj: ClassArray
]

{ #category : #'class table' }
SpurMemoryManager >> classAtIndex: classIndex [
	<api>
	<inline: true>
	| classTablePage |
	self assert: (classIndex >= 0 and: [classIndex <= self tagMask or: [classIndex >= self arrayClassIndexPun and: [classIndex <= self classIndexMask]]]).
	classTablePage := self fetchPointer: classIndex >> self classTableMajorIndexShift
							ofObject: hiddenRootsObj.
	classTablePage = nilObj ifTrue:
		[^nil].
	^self
		fetchPointer: (classIndex bitAnd: self classTableMinorIndexMask)
		ofObject: classTablePage
]

{ #category : #'class table' }
SpurMemoryManager >> classAtIndex: classIndex put: objOop [
	"for become & GC of classes"
	| classTablePage |
	self assert: (classIndex <= self tagMask or: [classIndex >= self arrayClassIndexPun]).
	self assert: (objOop = nilObj
				 or: [((self rawHashBitsOf: objOop) = classIndex						"normal entry"
					  or: [(self classAtIndex: (self rawHashBitsOf: objOop)) = objOop])	"become forces duplicate entry"
					and: [coInterpreter objCouldBeClassObj: objOop]]).
	classTablePage := self fetchPointer: classIndex >> self classTableMajorIndexShift
							ofObject: hiddenRootsObj.
	classTablePage = nilObj ifTrue:
		[self error: 'attempt to add class to empty page'].
	^self
		storePointer: (classIndex bitAnd: self classTableMinorIndexMask)
		ofObject: classTablePage
		withValue: objOop
]

{ #category : #'plugin support' }
SpurMemoryManager >> classBitmap [
	^self splObj: ClassBitmap
]

{ #category : #'plugin support' }
SpurMemoryManager >> classByteArray [
	"a.k.a. self fetchPointer: ClassByteArrayCompactIndex ofObject: classTableFirstPage"
	^self splObj: ClassByteArray
]

{ #category : #'plugin support' }
SpurMemoryManager >> classCharacter [
	^self splObj: ClassCharacter
]

{ #category : #accessing }
SpurMemoryManager >> classExternalAddress [
	^self splObj: ClassExternalAddress
]

{ #category : #instantiation }
SpurMemoryManager >> classExternalAddressIndex [
	<api>
	^ self ensureBehaviorHash: self classExternalAddress
]

{ #category : #accessing }
SpurMemoryManager >> classExternalData [
	^self splObj: ClassExternalData
]

{ #category : #accessing }
SpurMemoryManager >> classExternalFunction [
	^self splObj: ClassExternalFunction
]

{ #category : #accessing }
SpurMemoryManager >> classExternalLibrary [
	^self splObj: ClassExternalLibrary
]

{ #category : #accessing }
SpurMemoryManager >> classExternalStructure [
	^self splObj: ClassExternalStructure
]

{ #category : #'plugin support' }
SpurMemoryManager >> classFloat [
	^self splObj: ClassFloat
]

{ #category : #'interpreter access' }
SpurMemoryManager >> classForClassTag: classIndex [
	<inline: true>
	"No need to check this; classAtIndex: has a stricter assert:
		self assert: classIndex ~= self isForwardedObjectClassIndexPun."
	^self classAtIndex: classIndex
]

{ #category : #'header format' }
SpurMemoryManager >> classFormatForInstanceFormat: aFormat [
	"Clear any odd bits from the format so that it matches its class's format"
	aFormat < self firstLongFormat ifTrue:
		[^aFormat].
	aFormat >= self firstByteFormat ifTrue:
		[^aFormat bitAnd: -8].
	^aFormat >= self firstShortFormat
		ifTrue: [aFormat bitAnd: -4]
		ifFalse: [aFormat bitAnd: -2]
]

{ #category : #'object access' }
SpurMemoryManager >> classFormatFromInstFormat: instFormat [
	"0 = 0 sized objects (UndefinedObject True False et al)
	 1 = non-indexable objects with inst vars (Point et al)
	 2 = indexable objects with no inst vars (Array et al)
	 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
	 4 = weak indexable objects with inst vars (WeakArray et al)
	 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
	 6 unused, reserved for exotic pointer objects?
	 7 Forwarded Object, 1st field is pointer, rest of fields are ignored
	 8 unused, reserved for exotic non-pointer objects?
	 9 64-bit indexable
	 10 - 11 32-bit indexable
	 12 - 15 16-bit indexable
	 16 - 23 byte indexable
	 24 - 31 compiled method"
	<inline: true>
	instFormat >= self firstByteFormat ifTrue: "this is likely the common case"
		[^instFormat bitAnd: -8].
	instFormat <= self sixtyFourBitIndexableFormat ifTrue:
		[^instFormat].
	instFormat < self firstShortFormat ifTrue:
		[^instFormat bitAnd: -2].
	^instFormat bitAnd: -4
]

{ #category : #'header format' }
SpurMemoryManager >> classIndexFieldWidth [
	"22-bit class mask => ~ 4M classes"
	^22
]

{ #category : #'header format' }
SpurMemoryManager >> classIndexMask [
	<api>
	<cmacro>
	"22-bit class mask => ~ 4M classes"
	^16r3fffff
]

{ #category : #'header access' }
SpurMemoryManager >> classIndexOf: objOop [
	"Answer objOop's classIndex from the object header.
	 A note on performance:
		This routine uses longAt:, which does a 32-bit load on the 32-bit system, and a 64-bit load
		on the 64-bit system.  Since the only 64-bit implementation(s) is/are little-endian, and
		since all of isGrey,isPinned,isRemembered,format,isUmmutable and classIndex fit within
		the least significant 32-bits we could use long32At: to access these, in the hope that the
		32-bit access will be quicker on 64-bits by virtue of fetching half the bits.  But experiments
		show that doing this does not produce any increase; at least any signal is lost in the noise."
	<api>
	^(self longAt: objOop) bitAnd: self classIndexMask
]

{ #category : #'header access' }
SpurMemoryManager >> classIndexOfHeader: aHeader [
	<inline: true>
	^aHeader bitAnd: self classIndexMask
]

{ #category : #'class table puns' }
SpurMemoryManager >> classIsItselfClassIndexPun [
	"Class puns are class indices not used by any class.  There is an entry
	 for the pun that refers to the notional class of objects with this class
	 index.  But because the index doesn't match the class it won't show up
	 in allInstances, hence hiding the object with a pun as its class index.
	 The puns occupy indices 16 through 31."
	<cmacro>
	^31
]

{ #category : #'plugin support' }
SpurMemoryManager >> classLargeNegativeInteger [
	^self knownClassAtIndex: ClassLargeNegativeIntegerCompactIndex
]

{ #category : #'plugin support' }
SpurMemoryManager >> classLargePositiveInteger [
	^self knownClassAtIndex: ClassLargePositiveIntegerCompactIndex
]

{ #category : #'plugin support' }
SpurMemoryManager >> classMutex [
	^self splObj: ClassMutex
]

{ #category : #'class table' }
SpurMemoryManager >> classOrNilAtIndex: classIndex [
	<api>
	| classTablePage |
	self assert: (classIndex <= self tagMask or: [classIndex >= self arrayClassIndexPun]).
	classTablePage := self fetchPointer: classIndex >> self classTableMajorIndexShift
							ofObject: hiddenRootsObj.
	classTablePage = nilObj ifTrue:
		[^nilObj].
	^self
		fetchPointer: (classIndex bitAnd: self classTableMinorIndexMask)
		ofObject: classTablePage
]

{ #category : #'plugin support' }
SpurMemoryManager >> classPoint [
	^self splObj: ClassPoint
]

{ #category : #'plugin support' }
SpurMemoryManager >> classSemaphore [
	^self splObj: ClassSemaphore
]

{ #category : #accessing }
SpurMemoryManager >> classSmallInteger [
	<api>
	^self splObj: ClassSmallInteger
]

{ #category : #accessing }
SpurMemoryManager >> classString [
	^self splObj: ClassByteString
]

{ #category : #'class table' }
SpurMemoryManager >> classTableEntriesDo: binaryBlock [
	"Evaluate binaryBlock with all non-nil entries in the classTable and their index."
	<inline: true>
	0 to: numClassTablePages - 1 do:
		[:i| | page |
		 page := self fetchPointer: i ofObject: hiddenRootsObj.
		 0 to: self classTablePageSize - 1 do:
			[:j| | classOrNil |
			classOrNil := self fetchPointer: j ofObject: page.
			classOrNil ~= nilObj ifTrue:
				[binaryBlock
					value: classOrNil
					value: i << self classTableMajorIndexShift + j]]]
]

{ #category : #accessing }
SpurMemoryManager >> classTableFirstPage [
	<cmacro>
	^classTableFirstPage
]

{ #category : #accessing }
SpurMemoryManager >> classTableIndex [
	^classTableIndex
]

{ #category : #'spur bootstrap' }
SpurMemoryManager >> classTableIndex: n [
	classTableIndex := n
]

{ #category : #'class table' }
SpurMemoryManager >> classTableMajorIndexShift [
	<api>
	<cmacro>
	"1024 entries per page (2^10); 22 bit classIndex implies 2^12 pages"
	^10
]

{ #category : #'class table' }
SpurMemoryManager >> classTableMinorIndexMask [
	<api>
	"1024 entries per page (2^10); 22 bit classIndex implies 2^12 pages"
	"self basicNew classTableMinorIndexMask"
	^1 << self classTableMajorIndexShift - 1
]

{ #category : #'spur bootstrap' }
SpurMemoryManager >> classTableObjectsDo: aBlock [
	"for the bootstrap..."
	<doNotGenerate>
	0 to: self classTableRootSlots - 1 do:
		[:i| | page |
		page := self fetchPointer: i ofObject: hiddenRootsObj.
		0 to: (self numSlotsOf: page) - 1 do:
			[:j| | classOrNil |
			classOrNil := self fetchPointer: j ofObject: page.
			classOrNil ~= nilObj ifTrue:
				[aBlock value: classOrNil]]]
]

{ #category : #'class table' }
SpurMemoryManager >> classTablePageSize [
	"1024 entries per page (2^10); 22 bit classIndex implies 2^12 pages"
	"self basicNew classTablePageSize"
	<api>
	^1 << self classTableMajorIndexShift
]

{ #category : #accessing }
SpurMemoryManager >> classTableRootObj [
	<api>
	"For Cogit & bootstrap"
	^hiddenRootsObj
]

{ #category : #'class table' }
SpurMemoryManager >> classTableRootSlots [
	"Answer the number of slots for class table pages in the hidden root object."
	^1 << (self classIndexFieldWidth - self classTableMajorIndexShift)
]

{ #category : #'interpreter access' }
SpurMemoryManager >> classTagForClass: classObj [
	"Answer the classObj's identityHash to use as a tag in the first-level method lookup cache."
	<api>
	^self ensureBehaviorHash: classObj
]

{ #category : #'interpreter access' }
SpurMemoryManager >> classTagForSpecialObjectsIndex: splObjIndex compactClassIndex: compactClassIndex [
	"Answer the compactClassIndex to use as a tag in the first-level method lookup cache."
	^compactClassIndex
]

{ #category : #accessing }
SpurMemoryManager >> classUnsafeAlien [
	^self splObj: ClassUnsafeAlien
]

{ #category : #'debug support' }
SpurMemoryManager >> clearLeakMapAndMapAccessibleFreeSpace [
	"Perform an integrity/leak check using the heapMap.  Set a bit at each free chunk's header."
	<inline: false>
	heapMap clearHeapMap.
	self allOldSpaceEntitiesFrom: self firstObject
		do: [:objOop|
			(self isFreeObject: objOop) ifTrue:
				[heapMap heapMapAtWord: (self pointerForOop: objOop) Put: 1]]
]

{ #category : #'debug support' }
SpurMemoryManager >> clearLeakMapAndMapAccessibleObjects [
	"Perform an integrity/leak check using the heapMap.  Set a bit at each object's header."
	<inline: false>
	heapMap clearHeapMap.
	self allObjectsDo:
		[:oop| heapMap heapMapAtWord: (self pointerForOop: oop) Put: 1]
]

{ #category : #'become implementation' }
SpurMemoryManager >> cleverSwapHeaders: obj1 and: obj2 copyHashFlag: copyHashFlag [
	"swap headers, but swapping headers swaps remembered bits and hashes;
	 remembered bits must be unswapped and hashes may be unswapped if
	 copyHash is false."
	"This variant doesn't tickle a compiler bug in gcc and clang.  See naiveSwapHeaders:and:copyHashFlag:"
	<inline: true>
	| header1 header2 remembered |
	header1 := self long64At: obj1.
	header2 := self long64At: obj2.
	remembered := (header1 bitXor: header2) bitAnd: 1 << self rememberedBitShift.
	remembered ~= 0 ifTrue:
		[header1 := header1 bitXor: remembered.
		 header2 := header2 bitXor: remembered].
	"swapping headers swaps hash; if not copyHashFlag then unswap hash"
	copyHashFlag ifFalse:
		[| hashBits |
		 hashBits := (header1 bitXor: header2) bitAnd: self identityHashFullWordMask.
		 hashBits ~= 0 ifTrue:
			[header1 := header1 bitXor: hashBits.
			 header2 := header2 bitXor: hashBits]].
	self long64At: obj1 put: header2.
	self long64At: obj2 put: header1
]

{ #category : #allocation }
SpurMemoryManager >> clone: objOop [
	| numSlots fmt newObj |
	numSlots := self numSlotsOf: objOop.
	fmt := self formatOf: objOop.
	numSlots > self maxSlotsForNewSpaceAlloc
		ifTrue:
			[newObj := self allocateSlotsInOldSpace: numSlots
							format: fmt
							classIndex: (self classIndexOf: objOop)]
		ifFalse:
			[newObj := self allocateSlots: numSlots
							format: fmt
							classIndex: (self classIndexOf: objOop)].
	newObj ifNil:
		[^0].
	(self isPointersFormat: fmt)
		ifTrue:
			[| hasYoung |
			 hasYoung := false.
			 0 to: numSlots - 1 do:
				[:i| | oop |
				oop := self fetchPointer: i ofObject: objOop.
				(self isNonImmediate: oop) ifTrue:
					[(self isForwarded: oop) ifTrue:
						[oop := self followForwarded: oop].
					((self isNonImmediate: oop)
					 and: [self isYoungObject: oop]) ifTrue:
						[hasYoung := true]].
				self storePointerUnchecked: i
					ofObject: newObj
					withValue: oop].
			(hasYoung
			 and: [(self isYoungObject: newObj) not]) ifTrue:
				[scavenger remember: newObj]]
		ifFalse:
			[0 to: numSlots - 1 do:
				[:i|
				self storePointerUnchecked: i
					ofObject: newObj
					withValue: (self fetchPointer: i ofObject: objOop)].
			 fmt >= self firstCompiledMethodFormat ifTrue:
				[coInterpreter maybeFixClonedCompiledMethod: newObj.
				 ((self isOldObject: newObj)
				  and: [(self isYoungObject: objOop) or: [self isRemembered: objOop]]) ifTrue:
					[scavenger remember: newObj]]].
	^newObj
]

{ #category : #allocation }
SpurMemoryManager >> cloneInOldSpace: objOop forPinning: forPinning [
	<inline: false>
	| numSlots fmt newObj hash |
	numSlots := self numSlotsOf: objOop.
	fmt := self formatOf: objOop.
	
	forPinning
		ifTrue:
			[newObj := self allocateSlotsForPinningInOldSpace: numSlots
							bytes: (self objectBytesForSlots: numSlots)
							format: fmt
							classIndex: (self classIndexOf: objOop)]
		ifFalse:
			[newObj := self allocateSlotsInOldSpace: numSlots
							bytes: (self objectBytesForSlots: numSlots)
							format: fmt
							classIndex: (self classIndexOf: objOop)].
	newObj ifNil:
		[^0].
	(self isPointersFormat: fmt)
		ifTrue:
			[| hasYoung |
			 hasYoung := false.
			 0 to: numSlots - 1 do:
				[:i| | oop |
				oop := self fetchPointer: i ofObject: objOop.
				((self isNonImmediate: oop)
				 and: [self isForwarded: oop]) ifTrue:
					[oop := self followForwarded: oop].
				((self isNonImmediate: oop)
				 and: [self isYoungObject: oop]) ifTrue:
					[hasYoung := true].
				self storePointerUnchecked: i
					ofObject: newObj
					withValue: oop].
			hasYoung ifTrue:
				[scavenger remember: newObj]]
		ifFalse:
			[0 to: numSlots - 1 do:
				[:i|
				self storePointerUnchecked: i
					ofObject: newObj
					withValue: (self fetchPointer: i ofObject: objOop)].
			 fmt >= self firstCompiledMethodFormat ifTrue:
				[coInterpreter maybeFixClonedCompiledMethod: newObj.
				 ((self isYoungObject: objOop) or: [self isRemembered: objOop]) ifTrue:
					[scavenger remember: newObj]]].
	(hash := self rawHashBitsOf: objOop) ~= 0 ifTrue:
		[self setHashBitsOf: newObj to: hash].
	(self isObjImmutable: objOop) ifTrue:
		[self setIsImmutableOf: newObj to: true].
	^newObj
]

{ #category : #simulation }
SpurMemoryManager >> coInterpreter [
	<doNotGenerate>
	^coInterpreter
]

{ #category : #simulation }
SpurMemoryManager >> coInterpreter: aCoInterpreter [
	<doNotGenerate>
	coInterpreter := aCoInterpreter.
	scavenger ifNotNil:
		[scavenger coInterpreter: aCoInterpreter].
	compactor ifNotNil:
		[compactor coInterpreter: aCoInterpreter]
]

{ #category : #'gc - global' }
SpurMemoryManager >> coalesce: obj1 and: obj2 [
	self subclassResponsibility
]

{ #category : #'gc - global' }
SpurMemoryManager >> coallesceFreeChunk: objOop [
	"Attempt to coallesce objOop with the following objects in memory.
	 Answer the possibly changed start of objOop after coallescing."
	| here next |
	here := objOop.
	self assert: (self isRemembered: here) not.
	"Because lastBridge is marked loop below will terminate on reaching lastBridge."
	self assert: (self isMarked: segmentManager lastBridge).
	next := self objectAfter: here limit: endOfMemory.
	[self isMarked: next] whileFalse: "coalescing; rare case"
		[self assert: (self isRemembered: next) not.
		 statCoalesces := statCoalesces + 1.
		 here := self coalesce: here and: next.
		 next := self objectAfter: here limit: endOfMemory].
	^here
]

{ #category : #'object access' }
SpurMemoryManager >> compactClassIndexOf: objOop [
	<api>
	<inline: true>
	^self classIndexOf: objOop
]

{ #category : #'class membership' }
SpurMemoryManager >> compactIndexOfClass: objOop [
	self assert: (self rawHashBitsOf: objOop) ~= 0.
	^self rawHashBitsOf: objOop
]

{ #category : #'compaction - analysis' }
SpurMemoryManager >> compactionIssues [
	<doNotGenerate>
	"Compaction isn't working well.  It rarely moves more than a few tens of kilobytes.  Why?
	 Load an image and before you run it, or just before a GC, run these anaylsis routines.
	 e.g.
		self abstractCompaction #(63230272 75456 63210648)
	 shows we can move 75456 bytes of objects, but that would use 63210648 of free space.
	 i.e. there are lots of big free chunks in play, not many small ones that fit the bill.

		self largeFreeChunkDistribution
			#(	#('16r31C788' #nil)
				#('16r1423AC0' 2061864)
				#('16r1B705E8' 1515200)
				#('16r1D31D20' 2011152)
				#('16r1F37818' 1491480)
				#('16r2225968' 1450512)
				#('16r24C92C8' 48575672)  (16r24C92C8 + 48575672) hex '16r531C780' a free chunk
				#('16r531C788' #endOfMemory))
	 shows there's plenty of large free chunks.  And the trailing 16-byte free chunk shows coallescing is not working properly.

		self biggies #(#('16r31C788' #nil) #('16r531C788' #endOfMemory))
	 shows there are no large objects to be moved.

	 So... looks like compaction should hold onto the lowest large chunk and preferentially move objects into that.
	 Let's call it a pig.  Compaction needs to whittle away at the pig.

	 e.g.
		self abstractPigCompaction #(2061864 0 2061864 18759 2018224 34757)
	 shows we can move 18759 objects that will occupy 2018224 bytes into that
	 low pig of 2061864 bytes."
]

{ #category : #accessing }
SpurMemoryManager >> compactor [
	"This is really only for tests..."
	^compactor
]

{ #category : #'header format' }
SpurMemoryManager >> compiledMethodFormatForNumBytes: numBytes [
	^self firstCompiledMethodFormat + (8 - numBytes bitAnd: self wordSize - 1)
]

{ #category : #'free space' }
SpurMemoryManager >> computeFreeSpacePostSwizzle [
	totalFreeOldSpace := self totalFreeListBytes.
	self checkFreeSpace: 0
]

{ #category : #'become implementation' }
SpurMemoryManager >> containsOnlyValidBecomeObjects: array1 and: array2 twoWay: isTwoWay copyHash: copyHash [
	"Answer 0 if neither array contains an object inappropriate for the become operation.
	 Otherwise answer an informative error code for the first offending object found:
		Can't become: immediates => PrimErrInappropriate
		Shouldn't become pinned objects => PrimErrObjectIsPinned.
		Shouldn't become immutable objects => PrimErrNoModification.
		Can't copy hash into immediates => PrimErrInappropriate.
		Two-way become may require memory to create copies => PrimErrNoMemory.
	 As a side-effect unforward any forwarders in the two arrays if answering 0."
	<inline: true>
	| fieldOffset effectsFlags oop1 oop2 size |
	fieldOffset := self lastPointerOf: array1.
	effectsFlags := size := 0.
	"array1 is known to be the same size as array2"
	[fieldOffset >= self baseHeaderSize] whileTrue:
		[oop1 := self longAt: array1 + fieldOffset.
		 (self isOopForwarded: oop1) ifTrue:
			[oop1 := self followForwarded: oop1.
			 self longAt: array1 + fieldOffset put: oop1].
		 self ifOopInvalidForBecome: oop1 errorCodeInto: [:errCode| ^errCode].
		 effectsFlags := effectsFlags bitOr: (self becomeEffectFlagsFor: oop1).
		 oop2 := self longAt: array2 + fieldOffset.
		 (self isOopForwarded: oop2) ifTrue:
			[oop2 := self followForwarded: oop2.
			 self longAt: array2 + fieldOffset put: oop2].
		 isTwoWay
			ifTrue:
				[self ifOopInvalidForBecome: oop2 errorCodeInto: [:errCode| ^errCode].
				 size := size + (self bytesInObject: oop1) + (self bytesInObject: oop2).
				 effectsFlags := effectsFlags bitOr: (self becomeEffectFlagsFor: oop2)]
			ifFalse:
				[(copyHash and: [(self isImmediate: oop2) or: [self isImmutable: oop2]]) ifTrue:
					[^PrimErrInappropriate]].
		 fieldOffset := fieldOffset - self bytesPerOop].
	size >= (totalFreeOldSpace + (scavengeThreshold - freeStart)) ifTrue:
		[^PrimErrNoMemory].
	"only set flags after checking all args."
	becomeEffectsFlags := effectsFlags.
	^0
]

{ #category : #simulation }
SpurMemoryManager >> convertToArray [
	<doNotGenerate>
	"I dont believe it -- this *just works*"

	memory:= memory as: Array
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> copyObj: objOop toAddr: segAddr stopAt: endSeg savedFirstFields: savedFirstFields index: i [
	"This is part of storeImageSegmentInto:outPointers:roots:.
	 Copy objOop into the segment beginning at segAddr, and forward it to the copy,
	 saving its first field in savedFirstField, and setting its marked bit to indicate it has
	 been copied.  If it is a class in the class table, set the copy's hash to 0 for reassignment
	 on load, and mark it as a class by setting its isRemembered bit.
	 Answer the next segmentAddr if successful.  Answer an appropriate error code if not"

	"Copy the object..."
	| bodySize copy hash |
	<inline: false>
	self deny: (self isCopiedIntoSegment: objOop).
	bodySize := self bytesInObject: objOop.
	(self oop: segAddr + bodySize isGreaterThanOrEqualTo: endSeg) ifTrue:
		[^PrimErrWritePastObject halt].
	self memcpy: segAddr asVoidPointer _: (self startOfObject: objOop) asVoidPointer _: bodySize.
	copy := self objectStartingAt: segAddr.

	"Clear remembered, mark bits of all headers copied into the segment (except classes)"
	self
		setIsRememberedOf: copy to: false;
		setIsMarkedOf: copy to: false.

	"Make any objects with hidden dynamic state (contexts, methods) look like normal objects."
	self ifAProxy: objOop updateCopy: copy.

	"If the object is a class, zero its identityHash (which is its classIndex) and set its
	 isRemembered bit.  It will be assigned a new hash and entered into the table on load."
	hash := self rawHashBitsOf: objOop.
	(hash > self lastClassIndexPun and: [(self classOrNilAtIndex: hash) = objOop]) ifTrue:
		[self setHashBitsOf: copy to: 0.
		 self setIsRememberedOf: copy to: true].

	"Now forward the object to its copy in the segment."
	self storePointerUnchecked: i ofObject: savedFirstFields withValue: (self fetchPointer: 0 ofObject: objOop);
		storePointerUnchecked: 0 ofObject: objOop withValue: copy;
		markAsCopiedIntoSegment: objOop.

	"Answer the new end of segment"
	^segAddr + bodySize
]

{ #category : #'debug support' }
SpurMemoryManager >> countMarkedAndUnmarkdObjects: printFlags [
	"print the count of marked and unmarked objects.
	 In addition if 1 is set in printFlags, short-print marked objects,
	 and/or if 2 is set, short-print unmarked obejcts."
	<api>
	| nm nu |
	nm := nu := 0.
	self allObjectsDo:
		[:o|
		(self isMarked: o)
			ifTrue:
				[nm := nm + 1.
				 (printFlags anyMask: 1) ifTrue:
					[coInterpreter shortPrintOop: o]]
			ifFalse:
				[nu := nu + 1.
				 (printFlags anyMask: 2) ifTrue:
					[coInterpreter shortPrintOop: o]]].
	self print: 'n marked: '; printNum: nm; cr.
	self print: 'n unmarked: '; printNum: nu; cr
]

{ #category : #'class table' }
SpurMemoryManager >> countNumClassPagesPreSwizzle: bytesToShift [
	"Compute the used size of the class table before swizzling.  Needed to
	 initialize the classTableBitmap which is populated during adjustAllOopsBy:"
	| firstObj classTableRoot nilObjPreSwizzle |
	firstObj := self objectStartingAt: oldSpaceStart. "a.k.a. nilObj"
	"first five objects are nilObj, falseObj, trueObj, freeListsObj, classTableRootObj"
	classTableRoot := self noInlineObjectAfter:
							(self noInlineObjectAfter:
									(self noInlineObjectAfter:
											(self noInlineObjectAfter: firstObj
												limit: endOfMemory)
										limit: endOfMemory)
								limit: endOfMemory)
							limit: endOfMemory.
	nilObjPreSwizzle := oldSpaceStart - bytesToShift.
	numClassTablePages := self numSlotsOf: classTableRoot.
	self assert: numClassTablePages = (self classTableRootSlots + self hiddenRootSlots).
	2 to: numClassTablePages - 1 do:
		[:i|
		(self fetchPointer: i ofObject: classTableRoot) = nilObjPreSwizzle ifTrue:
			[numClassTablePages := i.
			 ^self]]
	
]

{ #category : #'allocation accounting' }
SpurMemoryManager >> currentAllocatedBytes [
	"Compute the current allocated bytes since last set.
	 This is the cumulative total in statAllocatedBytes plus the allocation since the last scavenge."
	| use |
	"Slang infers the type of the difference between two unsigned variables as signed.
	 In this case we want it to be unsigned."
	<var: 'use' type: #usqInt>
	use := segmentManager totalOldSpaceCapacity - totalFreeOldSpace.
	^statAllocatedBytes
	 + (freeStart - scavenger eden start)
	 + (use - oldSpaceUsePriorToScavenge)
]

{ #category : #'interpreter access' }
SpurMemoryManager >> dbgFloatValueOf: oop [
	"Answer the C double precision floating point value of the argument,
	 or if it is not, answer 0."

	self subclassResponsibility
]

{ #category : #snapshot }
SpurMemoryManager >> defaultEdenBytes [
	"Answer the default amount of memory to allocate for the eden space.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file.
	 The shootout tests seem to plateau at 5 or 6Mb.

	 Originally, both the 32-bit and 64-bit versions used the same 4Mb default.  Measuring
	 the simulator on image start-up, the 64-bit system's eden at the same point in start-up
	 (the first copyBits) is only 8% larger in bytes because it allocates 26% fewer objects.
	 Some 21% of the objects in the 32-bit version's eden are large integers and floats that
	 are representable as 64-bit immediates.

	 But when running benchmarks such as the computer language shootout's binary trees,
	 using the same amount of memory for the 64-bit system causes a significant slow-down
	 and a lot of compactions.  So we now use 4Mb for 32-bits and 7Mb for 64-bits."
	<inline: false>
	^self subclassResponsibility

	"self systemNavigation browseAllCallsOn: #start: and: #limit:"

	"Here are the expressions used to collect the above-mentioned figures:"
	"freeStart - self newSpaceStart"
	"| n | n := 0. self allNewSpaceObjectsDo: [:o| n := n + 1]. n"
	"| f | f := 0. self allNewSpaceObjectsDo: [:o| (self isFloatObject: o) ifTrue: [f := f + 1]]. f"
	"| l | l := 0. self allNewSpaceObjectsDo: [:o|
		(((self classIndexOf: o)
			between: ClassLargeNegativeIntegerCompactIndex
			and: ClassLargePositiveIntegerCompactIndex)
		 and: [(self numBytesOfBytes: o) <= 8
		 and: [self isIntegerValue: (coInterpreter signed64BitValueOf: o)]]) ifTrue: [l := l + 1]]. l"
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> dequeueMourner [
	"Answer the top mourner (ephemeron or weak array) from the queue or
	 nil if the queue is empty. We don't care about order; ephemerons are
	 fired in an arbitrary order based on where they are in the heap."
	^mournQueue ~= nilObj ifTrue:
		[self popObjStack: mournQueue]
]

{ #category : #'free space' }
SpurMemoryManager >> detachFreeObject: freeChunk [
	<inline: true>
	| chunkBytes |
	chunkBytes := self bytesInObject: freeChunk.
	totalFreeOldSpace := totalFreeOldSpace - chunkBytes.
	self unlinkFreeChunk: freeChunk chunkBytes: chunkBytes
]

{ #category : #'simulation only' }
SpurMemoryManager >> disownVM: flags [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter disownVM: flags
]

{ #category : #accessing }
SpurMemoryManager >> displayObject [
	^self splObj: TheDisplay
]

{ #category : #'allocation accounting' }
SpurMemoryManager >> doAllocationAccountingForScavenge [
	<inline: true>
	statAllocatedBytes := self currentAllocatedBytes
]

{ #category : #'become implementation' }
SpurMemoryManager >> doBecome: obj1 and: obj2 copyHash: copyHashFlag [
	"Inner dispatch for two-way become.
	 N.B. At least in current two-way become use copyHashFlag is false."
	| o1ClassIndex o2ClassIndex |
	"in-lined
			classIndex := (self isInClassTable: obj) ifTrue: [self rawHashBitsOf: obj] ifFalse: [0]
	 for speed."
	o1ClassIndex := self rawHashBitsOf: obj1.
	(o1ClassIndex ~= 0 and: [(self classAtIndex: o1ClassIndex) ~= obj1]) ifTrue:
		[o1ClassIndex := 0].
	o2ClassIndex := self rawHashBitsOf: obj2.
	(o2ClassIndex ~= 0 and: [(self classAtIndex: o2ClassIndex) ~= obj2]) ifTrue:
		[o2ClassIndex := 0].

	"Refuse to do an in-place become on classes since their being
	 forwarded is used in the flush method cache implementations."
	((self numSlotsOf: obj1) = (self numSlotsOf: obj2)
	 and: [o1ClassIndex = 0
	 and: [o2ClassIndex = 0]]) ifTrue:
		[self inPlaceBecome: obj1 and: obj2 copyHashFlag: copyHashFlag.
		 ^self].
	self outOfPlaceBecome: obj1 and: obj2 copyHashFlag: copyHashFlag.
	"if copyHashFlag then nothing changes, since hashes were also swapped."
	copyHashFlag ifTrue:
		[^self].
	"if copyHash is false then the classTable entries must be updated.
	 We leave the following until postBecomeScanClassTable:, but must
	 swap the forwarders if two active classes have been becommed,
	 and assign hashes if not."
	o1ClassIndex ~= 0
		ifTrue:
			[o2ClassIndex ~= 0
				ifTrue:
					[self classAtIndex: o1ClassIndex put: obj2.
					 self classAtIndex: o2ClassIndex put: obj1]
				ifFalse: "o2 wasn't in the table; set its hash"
					[| newObj2 |
					 newObj2 := self followForwarded: obj1.
					 self assert: (self rawHashBitsOf: newObj2) = 0.
					 self setHashBitsOf: newObj2 to: o1ClassIndex]]
		ifFalse:
			[o2ClassIndex ~= 0 ifTrue: "o1 wasn't in the table; set its hash"
				[| newObj1 |
				 newObj1 := self followForwarded: obj2.
				 self assert: (self rawHashBitsOf: newObj1) = 0.
				 self setHashBitsOf: newObj1 to: o2ClassIndex]]
]

{ #category : #'become implementation' }
SpurMemoryManager >> doBecome: obj1 to: obj2 copyHash: copyHashFlag [
	"one-way become with or without copying obj1's hash into obj2.
	 Straight-forward, even for classes.  With classes we end up with two entries
	 for obj2.  Which is current depends on copyHashFlag.  If copyHashFlag is true
	 then the entry at obj1's hash is valid, otherwise the the existing one at obj2's
	 hash.  When all the instances with the old hash have been collected, the GC will
	 discover this and expunge obj2 at the unused index (see markAndTraceClassOf:)."
	self forward: obj1 to: obj2.
	copyHashFlag ifTrue: [self setHashBitsOf: obj2 to: (self rawHashBitsOf: obj1)].
	((self isOldObject: obj1)
	 and: [self isYoung: obj2]) ifTrue:
		[becomeEffectsFlags := becomeEffectsFlags bitOr: OldBecameNewFlag].
	self deny: (self isOopForwarded: obj2)
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> doScavenge: tenuringCriterion [
	"The inner shell for scavenge, abstrascted out so globalGarbageCollect can use it."
	<inline: false>
	self doAllocationAccountingForScavenge.
	gcPhaseInProgress := ScavengeInProgress.
	pastSpaceStart := scavenger scavenge: tenuringCriterion.
	self assert: (self
					oop: pastSpaceStart
					isGreaterThanOrEqualTo: scavenger pastSpace start
					andLessThanOrEqualTo: scavenger pastSpace limit).
	freeStart := scavenger eden start.
	self initSpaceForAllocationCheck: (self addressOf: scavenger eden) limit: scavengeThreshold.
	gcPhaseInProgress := 0.
	self resetAllocationAccountingAfterGC
]

{ #category : #accessing }
SpurMemoryManager >> edenBytes [
	<doNotGenerate>
	^scavenger edenBytes
]

{ #category : #accessing }
SpurMemoryManager >> edenBytes: bytes [
	edenBytes := bytes
]

{ #category : #instantiation }
SpurMemoryManager >> eeInstantiateClassIndex: knownClassIndex format: objFormat numSlots: numSlots [
	"Instantiate an instance of a compact class.  ee stands for execution engine and
	 implies that this allocation will *NOT* cause a GC.  N.B. the instantiated object
	 IS NOT FILLED and must be completed before returning it to Smalltalk. Since this
	 call is used in routines that do just that we are safe.  Break this rule and die in GC.
	 Result is guaranteed to be young."
	<api>
	<inline: true>
	self assert: (numSlots >= 0 and: [knownClassIndex ~= 0 and: [(self knownClassAtIndex: knownClassIndex) ~= nilObj]]).
	self assert: (objFormat < self firstByteFormat
					ifTrue: [objFormat]
					ifFalse: [objFormat bitAnd: self byteFormatMask])
				= (self instSpecOfClass: (self knownClassAtIndex: knownClassIndex)).
	^self allocateNewSpaceSlots: numSlots format: objFormat classIndex: knownClassIndex
]

{ #category : #instantiation }
SpurMemoryManager >> eeInstantiateMethodContextSlots: numSlots [
	"Allocate a new MethodContext.  ee stands for execution engine and
	 implies that this allocation will *NOT* cause a GC.  N.B. the instantiated object
	 IS NOT FILLED and must be completed before returning it to Smalltalk. Since this
	 call is used in routines that do just that we are safe.  Break this rule and die in GC.
	 Result is guaranteed to be young."
	<inline: true>
	<inline: true>
	^self
		allocateNewSpaceSlots: numSlots
		format: self indexablePointersFormat
		classIndex: ClassMethodContextCompactIndex
]

{ #category : #instantiation }
SpurMemoryManager >> eeInstantiateSmallClass: classObj numSlots: numSlots [
	"Instantiate an instance of a class, with only a few slots.  ee stands for execution
	 engine and implies that this allocation will *NOT* cause a GC.  N.B. the instantiated
	 object IS NOT FILLED and must be completed before returning it to Smalltalk. Since
	 this call is used in routines that do just that we are safe.  Break this rule and die in GC.
	 Result is guaranteed to be young.  We assume this is only used on classes that are
	 already in the class table."
	<inline: true>
	self assert: (self rawHashBitsOf: classObj) ~= 0.
	^self
		eeInstantiateSmallClassIndex: (self rawHashBitsOf: classObj)
		format: (self instSpecOfClass: classObj)
		numSlots: numSlots
]

{ #category : #instantiation }
SpurMemoryManager >> eeInstantiateSmallClassIndex: knownClassIndex format: objFormat numSlots: numSlots [
	"Instantiate a small instance of a compact class.  ee stands for execution engine and
	 implies that this allocation will *NOT* cause a GC.  small implies the object will have
	 less than 255 slots. N.B. the instantiated object IS NOT FILLED and must be completed
	 before returning it to Smalltalk. Since this call is used in routines that do just that we
	 are safe.  Break this rule and die in GC.  Result is guaranteed to be young."
	<inline: true>
	self assert: (numSlots >= 0 and: [knownClassIndex ~= 0 and: [(self knownClassAtIndex: knownClassIndex) ~= nilObj]]).
	self assert: (objFormat < self firstByteFormat
					ifTrue: [objFormat]
					ifFalse: [objFormat bitAnd: self byteFormatMask])
				= (self instSpecOfClass: (self knownClassAtIndex: knownClassIndex)).
	^self allocateSmallNewSpaceSlots: numSlots format: objFormat classIndex: knownClassIndex
]

{ #category : #'debug support' }
SpurMemoryManager >> eek [
	<inline: true>
]

{ #category : #'obj stacks' }
SpurMemoryManager >> emptyObjStack: objStack [
	"Remove all the entries on the stack.  Do so by setting Topx to 0
	 on the first page, and adding all subsequent pages to the free list."
	| nextPage nextNextPage |
	objStack = nilObj ifTrue:
		[^self].
	self eassert: [self isValidObjStack: objStack].
	self storePointer: ObjStackTopx ofObjStack: objStack withValue: 0.
	nextPage := self fetchPointer: ObjStackNextx ofObject: objStack.
	[nextPage ~= 0] whileTrue:
		[nextNextPage := self fetchPointer: ObjStackNextx ofObject: nextPage.
		 self storePointer: ObjStackFreex
			ofObjStack: nextPage
			withValue: (self fetchPointer: ObjStackFreex ofObject: objStack).
		 self storePointer: ObjStackNextx ofObjStack: nextPage withValue: 0.
		 self storePointer: ObjStackFreex ofObjStack: objStack withValue: nextPage.
		 nextPage := nextNextPage].
	self storePointer: ObjStackNextx ofObjStack: objStack withValue: 0.
	self eassert: [self isValidObjStack: objStack]
]

{ #category : #accessing }
SpurMemoryManager >> endOfMemory [
	<cmacro: '() GIV(endOfMemory)'>
	^endOfMemory
]

{ #category : #accessing }
SpurMemoryManager >> endOfMemory: anInteger [ 
	<doNotGenerate>
	endOfMemory := anInteger
]

{ #category : #'gc - scavenge/compact' }
SpurMemoryManager >> endSlidingCompaction [
	gcPhaseInProgress := 0
]

{ #category : #'memory access' }
SpurMemoryManager >> endianness [
	<doNotGenerate>
	self subclassResponsibility
]

{ #category : #'class table' }
SpurMemoryManager >> ensureBehaviorHash: aBehavior [
	| hash err |
	<inline: true>
	self assert: (coInterpreter addressCouldBeClassObj: aBehavior).
	^(hash := self rawHashBitsOf: aBehavior) ~= 0
		ifTrue:
			[hash]
		ifFalse:
			[(coInterpreter objCouldBeClassObj: aBehavior)
				ifFalse: [PrimErrBadReceiver negated]
				ifTrue:
					[(err := self enterIntoClassTable: aBehavior) ~= 0
						ifTrue: [err negated]
						ifFalse: [self rawHashBitsOf: aBehavior]]]
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> ensureHasOverflowHeader: arrayArg forwardIfCloned: forwardIfCloned [
	"If arrayArg is too short to be truncated, clone it so that the clone is long enough.
	 Answer nil if it can't be cloned."
	<inline: false>
	(self hasOverflowHeader: arrayArg) ifTrue:
		[^arrayArg].
	^(self
		allocateSlots: self numSlotsMask + 1
		format: (self formatOf: arrayArg)
		classIndex: (self classIndexOf: arrayArg)) ifNotNil:
			[:clonedArray|
			 self memcpy: clonedArray + self baseHeaderSize
				 _: arrayArg + self baseHeaderSize
				 _: (self numSlotsOf: arrayArg) * self bytesPerOop.
			 (self isRemembered: arrayArg) ifTrue:
				[scavenger remember:  clonedArray].
			 forwardIfCloned ifTrue:
				[self forward: arrayArg to: clonedArray].
			 clonedArray]
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> ensureNoNewObjectsIn: outPointerArray [
	"This is part of loadImageSegmentFrom:outPointers:.
	 Since the remembered bit is currently used to identify classes in the segment, setting remembered bits
	 in new objects in the segment is difficult.  Instead simply arrange that there are no new objects in
	 outPointerArray, obviating the need to remember any of the loaded objects in the segment."
	| scanClassTable |
	scanClassTable := false.
	0 to: (self numSlotsOf: outPointerArray) - 1 do:
		[:i| | oop clone hash |
		 oop := self fetchPointer: i ofObject: outPointerArray.
		 (self isYoung: oop) ifTrue:
			[clone := self cloneInOldSpace: oop forPinning: false.
			 clone = 0 ifTrue:
				[^PrimErrNoMemory halt].
			 ((hash := self rawHashBitsOf: oop) ~= 0
			  and: [(self classOrNilAtIndex: hash) = oop]) ifTrue:
				[scanClassTable := true].
			 self forward: oop to: clone.
			 self storePointerUnchecked: i ofObject: outPointerArray withValue: clone]].
	scanClassTable ifTrue:
		[self postBecomeScanClassTable: BecamePointerObjectFlag].
	^0
]

{ #category : #'obj stacks' }
SpurMemoryManager >> ensureRoomOnObjStackAt: objStackRootIndex [
	"An obj stack is a stack of objects stored in a hidden root slot, such as
	 the markStack or the ephemeronQueue.  It is a linked list of segments,
	 with the hot end at the head of the list.  It is a word object.  The stack
	 pointer is in ObjStackTopx and 0 means empty.  The list goes through
	 ObjStackNextx. We don't want to shrink objStacks, since they're used
	 in GC and its good to keep their memory around.  So unused pages
	 created by popping emptying pages are kept on the ObjStackFreex list."
	| stackOrNil freeOrNewPage |
	stackOrNil := self fetchPointer: objStackRootIndex ofObject: hiddenRootsObj.
	(stackOrNil = nilObj
	 or: [(self fetchPointer: ObjStackTopx ofObject: stackOrNil) >= ObjStackLimit]) ifTrue:
		[freeOrNewPage := stackOrNil = nilObj
								ifTrue: [0]
								ifFalse: [self fetchPointer: ObjStackFreex ofObject: stackOrNil].
		 freeOrNewPage ~= 0
			ifTrue: "the free page list is always on the new page."
				[self storePointer: ObjStackFreex ofObjStack: stackOrNil withValue: 0.
				 self assert: (marking not or: [self isMarked: freeOrNewPage])]
			ifFalse:
				[freeOrNewPage := self allocateSlotsInOldSpace: ObjStackPageSlots
										format: self wordIndexableFormat
										classIndex: self wordSizeClassIndexPun.
				 freeOrNewPage ifNil: 
					["Allocate a new segment an retry. This is very uncommon. But it happened to me (Clement)."
					 self growOldSpaceByAtLeast: ObjStackPageSlots.
					 freeOrNewPage := self allocateSlotsInOldSpace: ObjStackPageSlots
										format: self wordIndexableFormat
										classIndex: self wordSizeClassIndexPun.
					freeOrNewPage ifNil: [self error: 'no memory to allocate or extend obj stack']].
				 self storePointer: ObjStackFreex ofObjStack: freeOrNewPage withValue: 0.
				 marking ifTrue: [self setIsMarkedOf: freeOrNewPage to: true]].
		 self storePointer: ObjStackMyx ofObjStack: freeOrNewPage withValue: objStackRootIndex;
			  storePointer: ObjStackNextx ofObjStack: freeOrNewPage withValue: (stackOrNil = nilObj ifTrue: [0] ifFalse: [stackOrNil]);
			  storePointer: ObjStackTopx ofObjStack: freeOrNewPage withValue: 0;
			  storePointer: objStackRootIndex ofObject: hiddenRootsObj withValue: freeOrNewPage.
		 self assert: (self isValidObjStackAt: objStackRootIndex).
		 "Added a new page; now update and answer the relevant cached first page."
		 stackOrNil := self updateRootOfObjStackAt: objStackRootIndex with: freeOrNewPage].
	self assert: (self isValidObjStackAt: objStackRootIndex).
	^stackOrNil
]

{ #category : #'interpreter access' }
SpurMemoryManager >> ensureSemaphoreUnforwardedThroughContext: aSemaphore [
	"Make sure that the aSemaphore is followed through to the suspendedContext of the first link."
	<inline: true>
	| proc ctxt |
	proc := self fetchPointer: FirstLinkIndex ofObject: aSemaphore.
	(self isForwarded: proc) ifTrue:
		[self followForwardedObjectFields: aSemaphore toDepth: 1.
		 proc := self fetchPointer: FirstLinkIndex ofObject: aSemaphore].
	self deny: (self isForwarded: proc).
	ctxt := self fetchPointer: SuspendedContextIndex ofObject: proc.
	(self isForwarded: ctxt) ifTrue:
		[ctxt := self followForwarded: ctxt.
		 self storePointer: SuspendedContextIndex ofObject: proc withValue: ctxt]
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> enterClassesIntoClassTableFrom: segmentStart to: segmentLimit [
 	"This is part of loadImageSegmentFrom:outPointers:.
	 Scan for classes contained in the segment, entering them into the class table,
	 and clearing their isRemembered: bit. Classes are at the front, after the root
	 array and have the remembered bit set. If the attempt succeeds, answer 0,
	 otherwise remove all entered entries and answer an error code."
	| objOop errorCode|
	objOop := self objectAfter: (self objectStartingAt: segmentStart).
	[(self oop: objOop isLessThan: segmentLimit)
	 and: [self isRemembered: objOop]] whileTrue:
		[self setIsRememberedOf: objOop to: false.
		 (errorCode := self enterIntoClassTable: objOop) ~= 0 ifTrue:
			[| oop |
			 oop := objOop.
			 objOop := self objectAfter: (self objectStartingAt: segmentStart).
			 [self oop: objOop isLessThan: oop] whileTrue:
				[self expungeFromClassTable: objOop.
				 objOop := self objectAfter: objOop limit: segmentLimit].
			 ^errorCode halt].
		 objOop := self objectAfter: objOop limit: segmentLimit].
	^0
]

{ #category : #'class table' }
SpurMemoryManager >> enterIntoClassTable: aBehavior [
	"Enter aBehavior into the class table and answer 0.  Otherwise answer a primitive failure code."
	<inline: false>
	| initialMajorIndex majorIndex minorIndex page |
	majorIndex := classTableIndex >> self classTableMajorIndexShift.
	initialMajorIndex := majorIndex.
	"classTableIndex should never index the first page; it's reserved for known classes"
	self assert: initialMajorIndex > 0.
	minorIndex := classTableIndex bitAnd: self classTableMinorIndexMask.

	[page := self fetchPointer: majorIndex ofObject: hiddenRootsObj.
	 page = nilObj ifTrue:
		[page := self allocateSlotsInOldSpace: self classTablePageSize
					format: self arrayFormat
					classIndex: self arrayClassIndexPun.
		 page ifNil:
			[^PrimErrNoMemory].
		 self fillObj: page numSlots: self classTablePageSize with: nilObj.
		 self storePointer: majorIndex
			ofObject: hiddenRootsObj
			withValue: page.
		 numClassTablePages := numClassTablePages + 1.
		 minorIndex := 0].
	 minorIndex to: self classTablePageSize - 1 do:
		[:i|
		(self fetchPointer: i ofObject: page) = nilObj ifTrue:
			[classTableIndex := majorIndex << self classTableMajorIndexShift + i.
			 "classTableIndex must never index the first page, which is reserved for classes known to the VM."
			 self assert: classTableIndex >= (1 << self classTableMajorIndexShift).
			 self storePointer: i
				ofObject: page
				withValue: aBehavior.
			 self setHashBitsOf: aBehavior to: classTableIndex.
			 self assert: (self classAtIndex: (self rawHashBitsOf: aBehavior)) = aBehavior.
			 ^0]].
	 majorIndex := (majorIndex + 1 bitAnd: self classIndexMask) max: 1.
	 majorIndex = initialMajorIndex ifTrue: "wrapped; table full"
		[^PrimErrLimitExceeded]] repeat
]

{ #category : #'header formats' }
SpurMemoryManager >> ephemeronFormat [
	^5
]

{ #category : #'debug support' }
SpurMemoryManager >> existInstancesInNewSpaceOf: classObj [
	| classIndex |
	classIndex := self rawHashBitsOf: classObj.
	self allNewSpaceObjectsDo:
		[:obj|
		(self classIndexOf: obj) = classIndex ifTrue:
			[^true]].
	^false
]

{ #category : #'class table' }
SpurMemoryManager >> expungeDuplicateAndUnmarkedClasses: expungeUnmarked [
	"Bits have been set in the classTableBitmap corresponding to
	 used classes.  Any class in the class table that does not have a
	 bit set has no instances with that class index.  However, becomeForward:
	 can create duplicate entries, and these duplicate entries wont match their
	 identityHash. So expunge duplicates by eliminating unmarked entries that
	 don't occur at their identityHash."
	1 to: numClassTablePages - 1 do: "Avoid expunging the puns by not scanning the 0th page."
		[:i| | classTablePage |
		classTablePage := self fetchPointer: i ofObject: hiddenRootsObj.
		 0 to: self classTablePageSize - 1 do:
			[:j| | classOrNil classIndex |
			 classOrNil := self fetchPointer: j ofObject: classTablePage.
			 classIndex := i << self classTableMajorIndexShift + j.
			 self assert: (classOrNil = nilObj or: [coInterpreter addressCouldBeClassObj: classOrNil]).
			 "only remove a class if it is at a duplicate entry or it is unmarked and we're expunging unmarked classes."
			 classOrNil = nilObj
				ifTrue:
					[classIndex < classTableIndex ifTrue:
						[classTableIndex := classIndex]]
				ifFalse:
					[((expungeUnmarked and: [(self isMarked: classOrNil) not])
					   or: [(self rawHashBitsOf: classOrNil) ~= classIndex]) ifTrue:
						[self storePointerUnchecked: j
							ofObject: classTablePage
							withValue: nilObj.
						 "but if it is marked, it should still be in the table at its correct index."
						 self assert: ((expungeUnmarked and: [(self isMarked: classOrNil) not])
									or: [(self classAtIndex: (self rawHashBitsOf: classOrNil)) = classOrNil]).
						 "If the removed class is before the classTableIndex, set the
						  classTableIndex to point to the empty slot so as to reuse it asap."
						 classIndex < classTableIndex ifTrue:
							[classTableIndex := classIndex]]]]].
	"classTableIndex must never index the first page, which is reserved for classes known to the VM."
	self assert: classTableIndex >= (1 << self classTableMajorIndexShift)
]

{ #category : #'class table' }
SpurMemoryManager >> expungeFromClassTable: aBehavior [
	"Remove aBehavior from the class table."
	<inline: false>
	| classIndex majorIndex minorIndex classTablePage |
	self assert: (self isInClassTable: aBehavior).
	classIndex := self rawHashBitsOf: aBehavior.
	majorIndex := classIndex >> self classTableMajorIndexShift.
	minorIndex := classIndex bitAnd: self classTableMinorIndexMask.
	classTablePage := self fetchPointer: majorIndex ofObject: hiddenRootsObj.
	self assert: classTablePage ~= classTableFirstPage.
	self assert: (self numSlotsOf: classTablePage) = self classTablePageSize.
	self assert: (self fetchPointer: minorIndex ofObject: classTablePage) = aBehavior.
	self storePointerUnchecked: minorIndex ofObject: classTablePage withValue: nilObj.
	"If the removed class is before the classTableIndex, set the
	 classTableIndex to point to the empty slot so as to reuse it asap."
	classIndex < classTableIndex ifTrue:
		[classTableIndex := classIndex].
	"classTableIndex must never index the first page, which is reserved for classes known to the VM."
	self assert: classTableIndex >= (1 << self classTableMajorIndexShift)
]

{ #category : #'simulation only' }
SpurMemoryManager >> failed [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter failed
]

{ #category : #accessing }
SpurMemoryManager >> falseObject [
	<api>
	^falseObj
]

{ #category : #accessing }
SpurMemoryManager >> falseObject: anOop [
	"For mapInterpreterOops"
	falseObj := anOop
]

{ #category : #'object access' }
SpurMemoryManager >> fetchByte: byteIndex ofObject: objOop [
	<api>
	^self byteAt: objOop + self baseHeaderSize + byteIndex
]

{ #category : #'object access' }
SpurMemoryManager >> fetchClassOf: oop [
	| tagBits |
	^(tagBits := oop bitAnd: self tagMask) ~= 0
		ifTrue: [self fetchPointer: tagBits ofObject: classTableFirstPage]
		ifFalse: [self fetchClassOfNonImm: oop]
]

{ #category : #'object access' }
SpurMemoryManager >> fetchClassOfNonImm: objOop [
	<inline: #never>
	| classIndex |
	classIndex := self classIndexOf: objOop.
	classIndex <= self classIsItselfClassIndexPun ifTrue:
		[classIndex = self classIsItselfClassIndexPun ifTrue:
			[^objOop].
		 "Answer nil to avoid the assert failure in classOrNilAtIndex:"
		 classIndex = self isForwardedObjectClassIndexPun ifTrue:
			[^nilObj]].
	self assert: classIndex >= self arrayClassIndexPun.
	^self classOrNilAtIndex: classIndex
]

{ #category : #'interpreter access' }
SpurMemoryManager >> fetchClassTagOf: oop [
	self subclassResponsibility
]

{ #category : #'interpreter access' }
SpurMemoryManager >> fetchClassTagOfNonImm: obj [
	"In Spur an object's classIndex is the tag in all method caches."
	^self classIndexOf: obj
]

{ #category : #'simulation only' }
SpurMemoryManager >> fetchInteger: fieldIndex ofObject: objectPointer [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter fetchInteger: fieldIndex ofObject: objectPointer
]

{ #category : #'object access' }
SpurMemoryManager >> fetchLong32: fieldIndex ofFloatObject: oop [
	"index by word size, and return a pointer as long as the word size"
	^self subclassResponsibility
]

{ #category : #'object access' }
SpurMemoryManager >> fetchLong32: fieldIndex ofObject: oop [
	"index by 32-bit units, and return a 32-bit value. Intended to replace fetchWord:ofObject:"

	^self long32At: oop + self baseHeaderSize + (fieldIndex << 2)
]

{ #category : #'object access' }
SpurMemoryManager >> fetchLong64: longIndex ofObject: objOop [
	<returnTypeC: #sqLong>
	^self long64At: objOop + self baseHeaderSize + (longIndex << 3)
]

{ #category : #'heap management' }
SpurMemoryManager >> fetchPointer: fieldIndex ofFreeChunk: objOop [
	^self longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
]

{ #category : #'heap management' }
SpurMemoryManager >> fetchPointer: fieldIndex ofMaybeForwardedObject: objOop [
	^self longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
]

{ #category : #'object access' }
SpurMemoryManager >> fetchPointer: fieldIndex ofObject: objOop [
	<api>
	^self longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
]

{ #category : #'object access' }
SpurMemoryManager >> fetchShort16: shortIndex ofObject: objOop [
	^self shortAt: objOop + self baseHeaderSize + (shortIndex << 1)
]

{ #category : #'object access' }
SpurMemoryManager >> fetchUnsignedShort16: shortIndex ofObject: objOop [
	^self cCoerceSimple: (self shortAt: objOop + self baseHeaderSize + (shortIndex << 1)) to: #'unsigned short'
]

{ #category : #instantiation }
SpurMemoryManager >> fillObj: objOop numSlots: numSlots with: fillValue [
	self subclassResponsibility
]

{ #category : #'free space' }
SpurMemoryManager >> findLargestFreeChunk [
	"Answer, but do not remove, the largest free chunk in the free lists."
	| treeNode childNode |
	treeNode := freeLists at: 0.
	treeNode = 0 ifTrue:
		[^nil].
	[self assertValidFreeObject: treeNode.
	 self assert: (self bytesInObject: treeNode) >= (self numFreeLists * self allocationUnit).
	 childNode := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: treeNode.
	 childNode ~= 0] whileTrue:
		[treeNode := childNode].
	^treeNode
]

{ #category : #'debug support' }
SpurMemoryManager >> findString: aCString [
	"Print the oops of all string-like things that have the same characters as aCString"
	<api>
	<var: #aCString type: #'char *'>
	| cssz |
	cssz := self strlen: aCString.
	self allObjectsDo:
		[:obj|
		 ((self isBytesNonImm: obj)
		  and: [(self lengthOf: obj) = cssz
		  and: [(self strncmp: aCString _: (self pointerForOop: obj + self baseHeaderSize) _: cssz) = 0]]) ifTrue:
			[coInterpreter printHex: obj; space; printOopShort: obj; cr]]
]

{ #category : #'debug support' }
SpurMemoryManager >> findStringBeginningWith: aCString [
	"Print the oops of all string-like things that start with the same characters as aCString"
	<api>
	<var: #aCString type: #'char *'>
	| cssz |
	cssz := self strlen: aCString.
	self allObjectsDo:
		[:obj|
		 ((self isBytesNonImm: obj)
		  and: [(self lengthOf: obj) >= cssz
		  and: [(self strncmp: aCString _: (self pointerForOop: obj + self baseHeaderSize) _: cssz) = 0]]) ifTrue:
				[coInterpreter printHex: obj; space; printNum: (self lengthOf: obj); space; printOopShort: obj; cr]]
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> fireAllUnscannedEphemerons [
	self assert: (self noUnscannedEphemerons) not.
	self assert: self allUnscannedEphemeronsAreActive.
	unscannedEphemerons start to: unscannedEphemerons top - self bytesPerOop by: self bytesPerOop do:
		[:p|
		coInterpreter fireEphemeron: (self longAt: p)]
]

{ #category : #'object enumeration' }
SpurMemoryManager >> firstAccessibleObject [
	<inline: false>
	self assert: nilObj = oldSpaceStart.
	"flush newSpace to settle the enumeration."
	self flushNewSpace.
	^nilObj
]

{ #category : #'header formats' }
SpurMemoryManager >> firstByteFormat [
	<api>
	<cmacro>
	^16
]

{ #category : #'object access' }
SpurMemoryManager >> firstBytePointerOfDataObject: objOop [
	<returnTypeC: #'void *'>
	<api>
	<inline: true>
	| fmt |
	fmt := self formatOf: objOop.
	fmt < self firstLongFormat ifTrue: [ ^ 0 ].
	^ self firstFixedField: objOop
]

{ #category : #'class table puns' }
SpurMemoryManager >> firstClassIndexPun [
	"Class puns are class indices not used by any class.  There is an entry
	 for the pun that refers to the notional class of objects with this class
	 index.  But because the index doesn't match the class it won't show up
	 in allInstances, hence hiding the object with a pun as its class index.
	 The puns occupy indices 16 through 31."
	<cmacro>
	^16
]

{ #category : #'header formats' }
SpurMemoryManager >> firstCompiledMethodFormat [
	<api>
	<cmacro>
	^24
]

{ #category : #'object access' }
SpurMemoryManager >> firstFixedField: objOop [
	<returnTypeC: #'void *'>
	^ self pointerForOop: objOop + self baseHeaderSize
]

{ #category : #'debug support' }
SpurMemoryManager >> firstFixedFieldOfMaybeImmediate: oop [
	"for the message send breakpoint; selectors can be immediates."
	<inline: false>
	^(self isImmediate: oop)
		ifTrue: [oop asVoidPointer]
		ifFalse: [self firstFixedField: oop]
]

{ #category : #'object format' }
SpurMemoryManager >> firstIndexableField: objOop [
	"NOTE: overridden in various simulator subclasses to add coercion to CArray, so please duplicate any changes.
	 There are only two important cases, both for objects with named inst vars, i.e. formats 2,3 & 5.
	 The first indexable field for formats 2 & 5 is the slot count (by convention, even though that's off the end
	 of the object).  For 3 we must go to the class."
	| fmt classFormat |
	<returnTypeC: #'void *'>
	fmt := self formatOf: objOop.
	fmt <= self weakArrayFormat ifTrue:
		[fmt = self arrayFormat ifTrue: "array starts at 0."
			[^self pointerForOop: objOop + self baseHeaderSize].
		 fmt >= self indexablePointersFormat ifTrue: "indexable with inst vars; need to delve into the class format word"
			[classFormat := self formatOfClass: (self fetchClassOfNonImm: objOop).
			 ^self pointerForOop: objOop
								+ self baseHeaderSize
								+ ((self fixedFieldsOfClassFormat: classFormat) << self shiftForWord)].
		 "otherwise not indexable"
		 ^0].
	"All bit objects, and indeed CompiledMethod, though this is a no-no, start at 0"
	(fmt >= self sixtyFourBitIndexableFormat
	 and: [fmt < self firstCompiledMethodFormat]) ifTrue:
		[^self pointerForOop: objOop + self baseHeaderSize].
	"otherwise not indexable"
	^0
]

{ #category : #'free space' }
SpurMemoryManager >> firstLilliputianChunk [
	^freeLists at: self lilliputianChunkIndex
]

{ #category : #'header formats' }
SpurMemoryManager >> firstLongFormat [
	<api>
	<cmacro>
	^10
]

{ #category : #'object enumeration' }
SpurMemoryManager >> firstObject [
	"Return the first object or free chunk in the heap."

	^nilObj
]

{ #category : #snapshot }
SpurMemoryManager >> firstSegmentBytes [
	<doNotGenerate>
	^segmentManager firstSegmentBytes
]

{ #category : #snapshot }
SpurMemoryManager >> firstSegmentSize: firstSegmentSize [
	<doNotGenerate>
	"even an empty segment needs a bridge ;-)"
	self assert: firstSegmentSize >= (2 * self baseHeaderSize).
	segmentManager firstSegmentSize: firstSegmentSize
]

{ #category : #'header formats' }
SpurMemoryManager >> firstShortFormat [
	<api>
	<cmacro>
	^12
]

{ #category : #'header formats' }
SpurMemoryManager >> firstStringyFakeFormat [
	"A fake format for the interpreter used to mark indexable strings in
	 the interpreter's at cache.  This is larger than any format."
	^32
]

{ #category : #'indexing primitive support' }
SpurMemoryManager >> firstValidIndexOfIndexableObject: obj withFormat: fmt [
	"Answer the one-relative index of the first valid index in an indexbale object
	 with the given format.  This is 1 for all objects except compiled methods
	 where the first index is beyond the last literal.
	 Used for safer bounds-checking on methods."
	^fmt >= self firstCompiledMethodFormat
		ifTrue: [coInterpreter firstByteIndexOfMethod: obj]
		ifFalse: [1]
]

{ #category : #forwarding }
SpurMemoryManager >> fixFollowedField: fieldIndex ofObject: anObject withInitialValue: initialValue [
	"Private helper for followField:ofObject: to avoid code duplication for rare case."
	<inline: #never>
	| objOop |
	self assert: (self isOopForwarded: initialValue).
	"inlined followForwarded: for speed (one less test)"
	objOop := initialValue.
	[objOop := self fetchPointer: 0 ofMaybeForwardedObject: objOop.
	 self isOopForwarded: objOop] whileTrue.
	self storePointer: fieldIndex ofObject: anObject withValue: objOop.
	^objOop
]

{ #category : #'object format' }
SpurMemoryManager >> fixedFieldsFieldWidth [
	<api>
	<cmacro>
	^16
]

{ #category : #'object format' }
SpurMemoryManager >> fixedFieldsOf: objOop format: fmt length: wordLength [
	| class |
	<inline: true>
	"N.B. written to fall through to fetchClassOfNonImm: et al for forwarders
	 so as to trigger an assert fail."
	(fmt >= self sixtyFourBitIndexableFormat or: [fmt = self arrayFormat]) ifTrue:
		[^0].  "indexable fields only"
	fmt < self arrayFormat ifTrue:
		[^wordLength].  "fixed fields only (zero or more)"
	class := self fetchClassOfNonImm: objOop.
	^self fixedFieldsOfClassFormat: (self formatOfClass: class)
]

{ #category : #'object format' }
SpurMemoryManager >> fixedFieldsOfClass: objOop [
	^self fixedFieldsOfClassFormat: (self formatOfClass: objOop)
]

{ #category : #'object format' }
SpurMemoryManager >> fixedFieldsOfClassFormat: classFormat [
	<api>
	^classFormat bitAnd: self fixedFieldsOfClassFormatMask
]

{ #category : #'object format' }
SpurMemoryManager >> fixedFieldsOfClassFormatMask [
	<api>
	^1 << self fixedFieldsFieldWidth - 1
]

{ #category : #'interpreter access' }
SpurMemoryManager >> floatObjectOf: aFloat [
	self subclassResponsibility
]

{ #category : #'interpreter access' }
SpurMemoryManager >> floatValueOf: oop [
	"Answer the C double precision floating point value of the argument,
	 or fail if it is not a Float, and answer 0.
	 Note: May be called by translated primitive code."

	self subclassResponsibility
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> flushEden [
	"Fush everything in eden.  Do so by doing a non-tenuring scavenge."
	self scavengingGCTenuringIf: DontTenure.
	self assert: pastSpaceStart = scavenger pastSpace start.
	self assert: freeStart = scavenger eden start
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> flushNewSpace [
	"Fush everything in new space.  Do so by setting the tenure
	 threshold above everything in newSpace, i.e. newSpaceLimit."
	| savedTenuringThreshold |
	savedTenuringThreshold := scavenger getRawTenuringThreshold.
	scavenger setRawTenuringThreshold: newSpaceLimit.
	self scavengingGCTenuringIf: TenureByAge.
	scavenger setRawTenuringThreshold: savedTenuringThreshold.
	self assert: scavenger rememberedSetSize = 0.
	self assert: pastSpaceStart = scavenger pastSpace start.
	self assert: freeStart = scavenger eden start
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> flushNewSpaceInstancesOf: aClass [
	| classIndex |
	classIndex := self rawHashBitsOf: aClass.
	classIndex = 0 ifTrue: "no instances; nothing to do"
		[^self].
	scavenger tenuringClassIndex: classIndex.
	self scavengingGCTenuringIf: TenureByClass.
	self assert: (self existInstancesInNewSpaceOf: aClass) not
]

{ #category : #'selective compaction' }
SpurMemoryManager >> followClassTable [
	"In addition to postBecomeScanClassTable:, I follow the pages in the class table.
	 Because hiddenRootsObj follows nil, false, true and the freeLists, it can never be forwarded."
	self deny: (self isForwarded: hiddenRootsObj).
	0 to: numClassTablePages - 1 do:
		[:i| | page |
		page := self followField: i ofObject: hiddenRootsObj.
		0 to: (self numSlotsOf: page) - 1 do:
			[:j| | classOrNil |
			classOrNil := self fetchPointer: j ofObject: page.
			classOrNil ~= nilObj ifTrue:
				[(self isForwarded: classOrNil) ifTrue:
					[classOrNil := self followForwarded: classOrNil.
					 self storePointer: j ofObject: page withValue: classOrNil].
				 (self rawHashBitsOf: classOrNil) = 0 ifTrue:
					[self storePointerUnchecked: j ofObject: page withValue: nilObj.
					 "If the removed class is before the classTableIndex, set the
					  classTableIndex to point to the empty slot so as to reuse it asap."
					 (i << self classTableMajorIndexShift + j) < classTableIndex ifTrue:
						[classTableIndex := i << self classTableMajorIndexShift + j]]]]].
	"classTableIndex must never index the first page, which is reserved for classes known to the VM."
	self assert: classTableIndex >= (1 << self classTableMajorIndexShift).
	self assert: self validClassTableRootPages
]

{ #category : #forwarding }
SpurMemoryManager >> followField: fieldIndex ofObject: anObject [
	"Make sure the oop at fieldIndex in anObject is not forwarded (follow the
	 forwarder there-in if so).  Answer the (possibly followed) oop at fieldIndex."
	| objOop |
	objOop := self fetchPointer: fieldIndex ofObject: anObject.
	(self isOopForwarded: objOop) ifTrue:
		[objOop := self fixFollowedField: fieldIndex ofObject: anObject withInitialValue: objOop].
	^objOop
]

{ #category : #forwarding }
SpurMemoryManager >> followForwarded: objOop [
	"Follow a forwarding pointer.  THis must be a loop because we cannot prevent forwarders to
	 forwarders being created by lazy become.  Consider the following example by Igor Stasenko:
		array := { a. b. c }.
		- array at: 1 points to &a. array at: 2 points to &b. array at: 3 points to &c
		a becomeForward: b
		- array at: 1 still points to &a. array at: 2 still points to &b. array at: 3 still points to &c
		b becomeForward: c.
		- array at: 1 still points to &a. array at: 2 still points to &b. array at: 3 still points to &c
		- when accessing array first one has to follow a forwarding chain:
		&a -> &b -> c"
	<api>
	| referent |
	self assert: (self isUnambiguouslyForwarder: objOop).
	referent := self fetchPointer: 0 ofMaybeForwardedObject: objOop.
	[(self isOopForwarded: referent)] whileTrue:
		[referent := self fetchPointer: 0 ofMaybeForwardedObject: referent].
	^referent
]

{ #category : #'obj stacks' }
SpurMemoryManager >> followForwardedInObjStack: objStack atIndex: objStackRootIndex [
	"Post-compact, follow forwarders in an obj stack."
	| firstPage stackOrNil index field |
	objStack = nilObj ifTrue:
		[^objStack].
	stackOrNil := objStack.
	(self isForwarded: stackOrNil) ifTrue:
		[stackOrNil := self followForwarded: stackOrNil.
		 self updateRootOfObjStackAt: objStackRootIndex with: stackOrNil].
	firstPage := stackOrNil.
	[self assert: (self numSlotsOfAny: stackOrNil) = ObjStackPageSlots.
	 self assert: (self fetchPointer: ObjStackMyx ofObject: stackOrNil) = objStackRootIndex.
	 "There are four fixed slots in an obj stack, and a Topx of 0 indicates empty, so
	   if there were 5 slots in an oop stack, full would be 2, and the last 0-rel index is 4.
	   Hence the last index is topx + fixed slots - 1, or topx + ObjStackNextx"
	 index := (self fetchPointer: ObjStackTopx ofObject: stackOrNil) + ObjStackNextx.
	 "follow forwarded fields including ObjStackNextx and leave field containing the next link."
	 [field := self fetchPointer: index ofObject: stackOrNil.
	  (field ~= 0 and: [(self isNonImmediate: field) and: [self isForwarded: field]]) ifTrue:
		[field := self followForwarded: field.
		 self storePointer: index ofObjStack: stackOrNil withValue: field].
	  (index := index - 1) > ObjStackFreex] whileTrue.
	  self assert: field = (self fetchPointer: ObjStackNextx ofObject: stackOrNil).
	 (stackOrNil := field) ~= 0] whileTrue.
	[stackOrNil := self fetchPointer: ObjStackFreex ofObject: firstPage.
	 stackOrNil ~= 0] whileTrue:
		[(self isForwarded: stackOrNil) ifTrue:
			[stackOrNil := self followForwarded: stackOrNil.
			 self storePointer: ObjStackFreex ofObjStack: firstPage withValue: stackOrNil].
		 firstPage := stackOrNil].
	self assert: (self isValidObjStackAt: objStackRootIndex)
]

{ #category : #compaction }
SpurMemoryManager >> followForwardedObjStacks [
	"Compaction will move objStack pages as well as ordinary objects.
	 So they need their slots followed."
	self followForwardedInObjStack: markStack atIndex: MarkStackRootIndex.
	self followForwardedInObjStack: weaklingStack atIndex: WeaklingStackRootIndex.
	self followForwardedInObjStack: mournQueue atIndex: MournQueueRootIndex
]

{ #category : #forwarding }
SpurMemoryManager >> followForwardedObjectFields: objOop toDepth: depth [
	"Follow pointers in the object to depth.
	 Answer if any forwarders were found.
	 How to avoid cyclic structures?? A temproary mark bit?"
	<api>
	<inline: false>
	| oop found |
	found := false.
	self assert: ((self isPointers: objOop) or: [self isOopCompiledMethod: objOop]).
	0 to: (self numPointerSlotsOf: objOop) - 1 do:
		[:i|
		 oop := self fetchPointer: i ofObject: objOop.
		 (self isNonImmediate: oop) ifTrue:
			[(self isForwarded: oop) ifTrue:
				[found := true.
				 oop := self followForwarded: oop.
				 self storePointer: i ofObject: objOop withValue: oop].
			(depth > 0
			 and: [(self hasPointerFields: oop)
			 and: [self followForwardedObjectFields: oop toDepth: depth - 1]]) ifTrue:
				[found := true]]].
	^found
]

{ #category : #forwarding }
SpurMemoryManager >> followMaybeForwarded: objOop [
	<inline: true>
	^(self isOopForwarded: objOop)
		ifTrue: [self noInlineFollowForwarded: objOop]
		ifFalse: [objOop]
]

{ #category : #forwarding }
SpurMemoryManager >> followObjField: fieldIndex ofObject: anObject [
	"Make sure the obj at fieldIndex in anObject is not forwarded (follow the
	 forwarder there-in if so).  Answer the (possibly followed) obj at fieldIndex."
	| objOop |
	objOop := self fetchPointer: fieldIndex ofObject: anObject.
	self assert: (self isNonImmediate: objOop).
	(self isForwarded: objOop) ifTrue:
		[objOop := self fixFollowedField: fieldIndex ofObject: anObject withInitialValue: objOop].
	^objOop
]

{ #category : #forwarding }
SpurMemoryManager >> followOopField: fieldIndex ofObject: anObject [
	"Make sure the oop at fieldIndex in anObject is not forwarded (follow the
	 forwarder there-in if so).  Answer the (possibly followed) oop at fieldIndex."
	| oop |
	oop := self fetchPointer: fieldIndex ofObject: anObject.
	(self isOopForwarded: oop) ifTrue:
		[oop := self fixFollowedField: fieldIndex ofObject: anObject withInitialValue: oop].
	^oop
]

{ #category : #'selective compaction' }
SpurMemoryManager >> followProcessList [
	"Eagerly patch all process related forwarders, except suspended contexts which are lazily patched in wakeHighestPriority"
	| scheduler processLists processList proc |
	scheduler := self followField: ValueIndex ofObject: (self splObj: SchedulerAssociation).
	self followField: ActiveProcessIndex ofObject: scheduler.
	processLists := self followField: ProcessListsIndex ofObject: scheduler.
	0 to: (self numSlotsOf: processLists) - 1 do: [:i |
		processList := self followField: i ofObject: processLists.
		self followField: LastLinkIndex ofObject: processList.
		proc := self followField: FirstLinkIndex ofObject: processList.
		[proc = nilObj] whileFalse: [proc := self followField: NextLinkIndex ofObject: proc]].
]

{ #category : #'become implementation' }
SpurMemoryManager >> followSpecialObjectsOop [
	(self isForwarded: specialObjectsOop) ifTrue:
		[specialObjectsOop := self followForwarded: specialObjectsOop].
	self followForwardedObjectFields: specialObjectsOop toDepth: 0.
]

{ #category : #'object access' }
SpurMemoryManager >> followedKeyOfEphemeron: objOop [
	"Answer the object the ephemeron guards.  This is its first element."
	self assert: ((self isNonImmediate: objOop) and: [self isEphemeron: objOop]).
	^self followOopField: 0 ofObject: objOop
]

{ #category : #'object access' }
SpurMemoryManager >> followedKeyOfMaybeFiredEphemeron: objOop [
	"Answer the object the ephemeron guards.  This is its first element."
	self assert: ((self isNonImmediate: objOop) and: [self isMaybeFiredEphemeron: objOop]).
	^self followOopField: 0 ofObject: objOop
]

{ #category : #'header format' }
SpurMemoryManager >> formatFieldWidthShift [
	<cmacro>
	"The format field contains 5 bits."
	^5
]

{ #category : #'header format' }
SpurMemoryManager >> formatMask [
	<api>
	<cmacro>
	"0 = 0 sized objects (UndefinedObject True False et al)
	 1 = non-indexable objects with inst vars (Point et al)
	 2 = indexable objects with no inst vars (Array et al)
	 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
	 4 = weak indexable objects with inst vars (WeakArray et al)
	 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
	 6,7,8 unused
	 9 64-bit indexable
	 10 - 11 32-bit indexable
	 12 - 15 16-bit indexable
	 16 - 23 byte indexable
	 24 - 31 compiled method"
	^16r1f
]

{ #category : #'object access' }
SpurMemoryManager >> formatOf: objOop [
	"0 = 0 sized objects (UndefinedObject True False et al)
	 1 = non-indexable objects with inst vars (Point et al)
	 2 = indexable objects with no inst vars (Array et al)
	 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
	 4 = weak indexable objects with inst vars (WeakArray et al)
	 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
	 6 unused, reserved for exotic pointer objects?
	 7 Forwarded Object, 1st field is pointer, rest of fields are ignored
	 8 unused, reserved for exotic non-pointer objects?
	 9 64-bit indexable
	 10 - 11 32-bit indexable	(11 unused in 32 bits)
	 12 - 15 16-bit indexable	(14 & 15 unused in 32-bits)
	 16 - 23 byte indexable		(20-23 unused in 32-bits)
	 24 - 31 compiled method	(28-31 unused in 32-bits)"
	"A note on performance.  Since the format field is, by design, aligned on a byte boundary
	 in the fourth byte of the header we could access it via
		^(self byteAt: objOop + 3) bitAnd: self formatMask
	 but al least on e.g. Core i7 x86-64 using the clang 6 compiler, this makes no difference,
	 or at least any change is in the noise."
	^(self longAt: objOop) >> self formatShift bitAnd: self formatMask
]

{ #category : #'object format' }
SpurMemoryManager >> formatOfClass: classPointer [
	<api>
	<inline: true>
	^self integerValueOf: (self fetchPointer: InstanceSpecificationIndex ofObject: classPointer)
]

{ #category : #'object access' }
SpurMemoryManager >> formatOfHeader: header [
	"0 = 0 sized objects (UndefinedObject True False et al)
	 1 = non-indexable objects with inst vars (Point et al)
	 2 = indexable objects with no inst vars (Array et al)
	 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
	 4 = weak indexable objects with inst vars (WeakArray et al)
	 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
	 6 unused, reserved for exotic pointer objects?
	 7 Forwarded Object, 1st field is pointer, rest of fields are ignored
	 8 unused, reserved for exotic non-pointer objects?
	 9 64-bit indexable
	 10 - 11 32-bit indexable
	 12 - 15 16-bit indexable
	 16 - 23 byte indexable
	 24 - 31 compiled method"
	<var: 'header' type: #usqLong>
	^header >> self formatShift bitAnd: self formatMask
]

{ #category : #'header format' }
SpurMemoryManager >> formatShift [
	<api>
	<cmacro>
	^24
]

{ #category : #'become implementation' }
SpurMemoryManager >> forward: obj1 to: obj2 [
	self set: obj1 classIndexTo: self isForwardedObjectClassIndexPun formatTo: self forwardedFormat.
	self cppIf: IMMUTABILITY ifTrue: [ self setIsImmutableOf: obj1 to: false ].
	self storePointer: 0 ofForwarder: obj1 withValue: obj2.
	"For safety make sure the forwarder has a slot count that includes its contents."
	(self rawNumSlotsOf: obj1) = 0 ifTrue:
		[self rawNumSlotsOf: obj1 put: 1]
]

{ #category : #'become implementation' }
SpurMemoryManager >> forwardSurvivor: obj1 to: obj2 [
	"This version of forward:to: can use an unchecked store because it is known that obj1 is young."
	self assert: (self isInNewSpace: obj1).
	self assert: ((self isInFutureSpace: obj2) or: [self isInOldSpace: obj2]).
	self storePointerUnchecked: 0 ofObject: obj1 withValue: obj2.
	self set: obj1 classIndexTo: self isForwardedObjectClassIndexPun formatTo: self forwardedFormat
]

{ #category : #'become implementation' }
SpurMemoryManager >> forwardUnchecked: obj1 to: obj2 [
	"This version of forward:to: can use an unchecked store because it is known that both obj1 and obj2 are old."
	self assert: ((self isInOldSpace: obj1) and: [self isInOldSpace: obj2]).
	self storePointerUnchecked: 0 ofObject: obj1 withValue: obj2.
	self set: obj1 classIndexTo: self isForwardedObjectClassIndexPun formatTo: self forwardedFormat
]

{ #category : #'header formats' }
SpurMemoryManager >> forwardedFormat [
	"A special format used by the GC to follow only the first pointer."
	^7
]

{ #category : #'debug support' }
SpurMemoryManager >> forwardersIn: anObject [
	"Answer if anObject is itself forwarded, or is a pointer object containing any references to forwarded objects."
	(self isForwarded: anObject) ifTrue:
		[^true].
	0 to: (self numPointerSlotsOf: anObject) - 1 do:
		[:i| | oop |
		 oop := self fetchPointer: i ofMaybeForwardedObject: anObject.
		 ((self isNonImmediate: oop)
		  and: [self isForwarded: oop]) ifTrue:
			[^true]].
	^false
]

{ #category : #'free space' }
SpurMemoryManager >> freeChunkLargerIndex [
	"for organizing the tree of large free chunks."
	^4
]

{ #category : #'free space' }
SpurMemoryManager >> freeChunkNextIndex [
	"for linking objecs on each free list, or, during pigCompact, doubly-
	 linking the free objects in address order using the xor link hack."
	^0
]

{ #category : #'free space' }
SpurMemoryManager >> freeChunkParentIndex [
	"for organizing the tree of large free chunks."
	^2
]

{ #category : #'free space' }
SpurMemoryManager >> freeChunkPrevIndex [
	"For linking objecs on each free list, doubly-linking the free objects.
	 Free chunks of size 1 do not have a prev index."
	^1
]

{ #category : #'free space' }
SpurMemoryManager >> freeChunkSmallerIndex [
	"for organizing the tree of large free chunks."
	^3
]

{ #category : #'free space' }
SpurMemoryManager >> freeChunkWithBytes: bytes at: address [
	<inline: false>
	| freeChunk |
	self assert: (self isInOldSpace: address).
	self assert: (segmentManager segmentContainingObj: address) = (segmentManager segmentContainingObj: address + bytes).
	freeChunk := self initFreeChunkWithBytes: bytes at: address.
	self addToFreeList: freeChunk bytes: bytes.
	self assert: freeChunk = (self objectStartingAt: address).
	^freeChunk
]

{ #category : #'free space' }
SpurMemoryManager >> freeListHeadsEmpty [
	0 to: self numFreeLists - 1 do:
		[:i| (freeLists at: i) ~= 0 ifTrue: [^false]].
	^true
]

{ #category : #'free space' }
SpurMemoryManager >> freeListsObj [
	self assert: (self firstIndexableField: (self oldSpaceObjectAfter: trueObj)) = freeLists.
	^self oldSpaceObjectAfter: trueObj
]

{ #category : #'free space' }
SpurMemoryManager >> freeListsObject [
	^self objectAfter: trueObj
]

{ #category : #'free space' }
SpurMemoryManager >> freeObject: objOop [
	"Free an object in oldSpace.  Coalesce if possible to reduce fragmentation."
	<api>
	<inline: false>
	| bytes start next |
	self assert: (self isInOldSpace: objOop).
	(self isRemembered: objOop) ifTrue:
		[scavenger forgetObject: objOop].
	bytes := self bytesInObject: objOop.
	start := self startOfObject: objOop.
	next := self objectStartingAt: start + bytes.
	(self isFreeObject: next) ifTrue:
		[self detachFreeObject: next.
		 bytes := bytes + (self bytesInObject: next)].
	totalFreeOldSpace := totalFreeOldSpace + bytes.
	^self freeChunkWithBytes: bytes at: start
]

{ #category : #snapshot }
SpurMemoryManager >> freeOldSpaceStart [
	^freeOldSpaceStart
]

{ #category : #'free space' }
SpurMemoryManager >> freeSize [
	^totalFreeOldSpace
]

{ #category : #'debug support' }
SpurMemoryManager >> freeSpaceCharacterisation [
	<doNotGenerate>
	| n s |
	n := 0.
	s := Bag new.
	self allFreeObjectsDo:
		[:f| n := n + 1. s add: (self bytesInObject: f)].
	^{ n. s sortedCounts. s sortedElements }
]

{ #category : #accessing }
SpurMemoryManager >> freeStart [
	"This is a horrible hack and only works because C macros are generated after Interpreter variables."
	<cmacro: '() GIV(freeStart)'>
	^freeStart
]

{ #category : #'free space' }
SpurMemoryManager >> freeTreeNodesDo: aBlock [
	"Enumerate all nodes in the free tree (in order, smaller to larger),
	 but *not* including the next nodes of the same size off each tree node.
	 This is an iterative version so that the block argument can be
	 inlined by Slang. The trick to an iterative binary tree application is
	 to apply the function on the way back up when returning from a
	 particular direction, in this case up from the larger child.

	 N.B For the convenience of rebuildFreeTreeFromSortedFreeChunks
	 aBlock *MUST* answer the freeTreeNode it was invoked with, or
	 its replacement if it was replaced by aBlock."
	<inline: true>
	| treeNode cameFrom |
	treeNode := freeLists at: 0.
	treeNode = 0 ifTrue:
		[^self].
	cameFrom := -1.
	[| smallChild largeChild |
	 self assert: (self bytesInObject: treeNode) >= (self numFreeLists * self allocationUnit).
	 smallChild := self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: treeNode.
	 largeChild := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: treeNode.
	 self assert: (smallChild = 0 or: [treeNode = (self fetchPointer: self freeChunkParentIndex ofFreeChunk: smallChild)]).
	 self assert: (largeChild = 0 or: [treeNode = (self fetchPointer: self freeChunkParentIndex ofFreeChunk: largeChild)]).
	 "apply if the node has no children, or it has no large children and we're
	  returning from the small child, or we're returning from the large child."
	 ((smallChild = 0 and: [largeChild = 0])
	  or: [largeChild = 0
			ifTrue: [cameFrom = smallChild]
			ifFalse: [cameFrom = largeChild]])
		ifTrue:
			[treeNode := aBlock value: treeNode.
			 "and since we've applied we must move on up"
			 cameFrom := treeNode.
			 treeNode := self fetchPointer: self freeChunkParentIndex ofFreeChunk: treeNode]
		ifFalse:
			[(smallChild ~= 0 and: [cameFrom ~= smallChild])
				ifTrue:
					[treeNode := smallChild]
				ifFalse:
					[self assert: largeChild ~= 0.
					 treeNode := largeChild].
			 cameFrom := -1].
	 treeNode ~= 0] whileTrue
]

{ #category : #'free space' }
SpurMemoryManager >> freeTreeOverlapCheck [
	<doNotGenerate>
	"Assumes no 2 consecutive free chunks"
	self allObjectsInFreeTreeDo: [:freeNode1|
		self allObjectsInFreeTreeDo: [:freeNode2|
			freeNode1 == freeNode2
				ifFalse: 
					[|start1 start2 end1 end2|
					start1 := self startOfObject: freeNode1.
					start2 := self startOfObject: freeNode2.
					end1 := start1 + (self bytesInObject: freeNode1).
					end2 := start2 + (self bytesInObject: freeNode2).
					"
					Transcript 
						show: '['; show: start1; show: ';'; 
						show: end1; show: '];'; cr; show: '['; show: start2;
						show: ';'; show: end2; show: ']'; cr.
					"
					self assert: (start2 > end1 or: [end2 < start1]).
					self assert: (start1 > end2 or: [start1 < start2])]]].
]

{ #category : #'simulation only' }
SpurMemoryManager >> fullDisplayUpdate [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter fullDisplayUpdate
]

{ #category : #'gc - global' }
SpurMemoryManager >> fullGC [
	"Perform a full eager compacting GC.  Answer the size of the largest free chunk."
	<returnTypeC: #usqLong>
	<inline: #never> "for profiling"
	needGCFlag := false.
	gcStartUsecs := coInterpreter ioUTCMicrosecondsNow.
	statMarkCount := 0.
	coInterpreter preGCAction: GCModeFull.
	self globalGarbageCollect.
	coInterpreter postGCAction: GCModeFull.
	statGCEndUsecs := coInterpreter ioUTCMicrosecondsNow.
	self updateFullGCStats.
	^(freeLists at: 0) ~= 0
		ifTrue: [self bytesInObject: self findLargestFreeChunk]
		ifFalse: [0]
]

{ #category : #'gc - global' }
SpurMemoryManager >> fullGCLock [
	"Spur never has a need to lock GC because it does not move pinned objects."
	^0
]

{ #category : #snapshot }
SpurMemoryManager >> garbageCollectForSnapshot [
	self flushNewSpace. "There is no place to put newSpace in the snapshot file."
	self flag: 'If we wanted to shrink the rememberedSet prior to snapshot this is the place to do it.'.
	compactor biasForSnapshot.
	self fullGC.
	compactor biasForGC.
	segmentManager prepareForSnapshot.
	self checkFreeSpace: GCModeFull
]

{ #category : #accessing }
SpurMemoryManager >> gcStartUsecs [
	^gcStartUsecs
]

{ #category : #accessing }
SpurMemoryManager >> getHeapGrowthToSizeGCRatio [
	<returnTypeC: #float>
	^heapGrowthToSizeGCRatio
]

{ #category : #'simulation only' }
SpurMemoryManager >> getStackPointer [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter getStackPointer
]

{ #category : #'simulation only' }
SpurMemoryManager >> getThisSessionID [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter getThisSessionID
]

{ #category : #'gc - global' }
SpurMemoryManager >> globalGarbageCollect [
	<inline: true> "inline into fullGC"
	self assert: self validObjStacks.
	self assert: (self isEmptyObjStack: markStack).
	self assert: (self isEmptyObjStack: weaklingStack).

	"Mark objects /before/ scavenging, to empty the rememberedTable of unmarked roots."
	self markObjects: true.
	gcMarkEndUsecs := coInterpreter ioUTCMicrosecondsNow.
	
	scavenger forgetUnmarkedRememberedObjects.
	self doScavenge: MarkOnTenure.

	"Mid-way the leak check must be more lenient.  Unmarked classes will have been
	 expunged from the table, but unmarked instances will not yet have been reclaimed."
	self runLeakCheckerFor: GCModeFull
		excludeUnmarkedObjs: true
		classIndicesShouldBeValid: true.

	compactionStartUsecs := coInterpreter ioUTCMicrosecondsNow.
	segmentManager prepareForGlobalSweep. "for notePinned:"
	compactor compact.
	self attemptToShrink.
	self setHeapSizeAtPreviousGC.

	self assert: self validObjStacks.
	self assert: (self isEmptyObjStack: markStack).
	self assert: (self isEmptyObjStack: weaklingStack).
	self assert: self allObjectsUnmarked.
	self runLeakCheckerFor: GCModeFull
]

{ #category : #'object testing' }
SpurMemoryManager >> goodContextSize: oop [
	| numSlots |
	numSlots := self numSlotsOf: oop.
	^numSlots = SmallContextSlots or: [numSlots = LargeContextSlots]
]

{ #category : #'header format' }
SpurMemoryManager >> greyBitShift [
	<cmacro>
	"bit 2 of 3-bit field above format (little endian)"
	^31
]

{ #category : #accessing }
SpurMemoryManager >> growHeadroom [
	^growHeadroom
]

{ #category : #accessing }
SpurMemoryManager >> growHeadroom: aValue [
	^growHeadroom := aValue
]

{ #category : #'growing/shrinking memory' }
SpurMemoryManager >> growOldSpaceByAtLeast: minAmmount [
	"Attempt to grow memory by at least minAmmount.
	 Answer the size of the new segment, or nil if the attempt failed."
	| ammount headroom total start interval |
	<var: #segInfo type: #'SpurSegmentInfo *'>
	"statGrowMemory counts attempts, not successes."
	statGrowMemory := statGrowMemory + 1."we need to include overhead for a new object header plus the segment bridge."
	ammount := minAmmount + (self baseHeaderSize * 2 + self bridgeSize).
	"round up to the nearest power of two."
	ammount := 1 << (ammount - 1) highBit.
	"and grow by at least growHeadroom."
	ammount := ammount max: growHeadroom.

	"Now apply the maxOldSpaceSize limit, if one is in effect."
	maxOldSpaceSize > 0 ifTrue:
		[total := segmentManager totalBytesInSegments.
		 total >= maxOldSpaceSize ifTrue:
			[^nil].
		 headroom := maxOldSpaceSize - total.
		 headroom < ammount ifTrue:
			[headroom < (minAmmount + (self baseHeaderSize * 2 + self bridgeSize)) ifTrue:
				[^nil].
			 ammount := headroom]].
		 
	start := coInterpreter ioUTCMicrosecondsNow.
	^(segmentManager addSegmentOfSize: ammount) ifNotNil:
		[:segInfo|
		 self assimilateNewSegment: segInfo.
		 "and add the new free chunk to the free list; done here
		  instead of in assimilateNewSegment: for the assert"
		 self addFreeChunkWithBytes: segInfo segSize - self bridgeSize at: segInfo segStart.
		 self assert: (self addressAfter: (self objectStartingAt: segInfo segStart))
					= (segInfo segLimit - self bridgeSize).
		 self checkFreeSpace: GCModeFreeSpace.
		 segmentManager checkSegments.
		 interval := coInterpreter ioUTCMicrosecondsNow - start.
		 interval > statMaxAllocSegmentTime ifTrue: [statMaxAllocSegmentTime := interval].
		 segInfo segSize]
]

{ #category : #'growing/shrinking memory' }
SpurMemoryManager >> growToAccomodateContainerWithNumSlots: numSlots [
	"Grow memory to accomodate a container (an Array) with numSlots.
	 Grow by at least the growHeadroom.  Supports allInstancesOf: and allObjects."
	| delta |
	delta := self baseHeaderSize * 2 + (numSlots * self bytesPerOop).
	self growOldSpaceByAtLeast: (growHeadroom max: delta)
]

{ #category : #'header access' }
SpurMemoryManager >> hasIdentityHash: objOop [
	<inline: true>
	^self cCode: [self rawHashBitsOf: objOop]
		inSmalltalk: [(self rawHashBitsOf: objOop) ~= 0]
]

{ #category : #'header access' }
SpurMemoryManager >> hasOverflowHeader: objOop [
	^(self rawNumSlotsOf: objOop) = self numSlotsMask
]

{ #category : #'object testing' }
SpurMemoryManager >> hasPointerFields: oop [
	<inline: true>
	^(self isNonImmediate: oop)
	  and: [self hasPointerFieldsNonImm: oop]
]

{ #category : #'object testing' }
SpurMemoryManager >> hasPointerFieldsNonImm: oop [
	<inline: true>
	^self isAnyPointerFormat: (self formatOf: oop)
]

{ #category : #'interpreter access' }
SpurMemoryManager >> hasSixtyFourBitImmediates [
	"The V3 64-bit memory manager has 64-bit oops, but its SmallIntegers only have
	 31 bits of precision.  The Spur 64-bit memory manager has 61-bit immediates."
	^self subclassResponsibility
]

{ #category : #'api characterization' }
SpurMemoryManager >> hasSpurMemoryManagerAPI [
	^true
]

{ #category : #'object testing' }
SpurMemoryManager >> hasYoungReferents: objOop [
	0 to: (self numPointerSlotsOf: objOop) - 1 do:
		[:i| | oop |
		oop := self fetchPointer: i ofObject: objOop.
		(self isYoung: oop) ifTrue:
			[^true]].
	^false
]

{ #category : #'header access' }
SpurMemoryManager >> hashBitsOf: objOop [
	| hash |
	hash := self rawHashBitsOf: objOop.
	hash = 0 ifTrue:
		["would like to assert
			self assert: (coInterpreter addressCouldBeClassObj: objOop) not
		  but instance-specific behaviors that are instances of themselves may
		  fail this test."
		 hash := self newHashBitsOf: objOop].
	^hash
]

{ #category : #'header format' }
SpurMemoryManager >> headerForSlots: numSlots format: formatField classIndex: classIndex [
	<api>
	"The header format in LSB is
	 MSB:	| 8: numSlots		| (on a byte boundary)
			| 2 bits				|	(msb,lsb = {isMarked,?})
			| 22: identityHash	| (on a word boundary)
			| 3 bits				|	(msb <-> lsb = {isGrey,isPinned,isRemembered}
			| 5: format			| (on a byte boundary)
			| 2 bits				|	(msb,lsb = {isImmutable,?})
			| 22: classIndex		| (on a word boundary) : LSB
	 The remaining bits (7) are used for
		isImmutable	(bit 23)
		isRemembered	(bit 29)
		isPinned		(bit 30)
		isGrey			(bit 31)
		isMarked		(bit 55)
	 leaving 2 unused bits, each next to a 22-bit field, allowing those fields to be
	 expanded to 23 bits..  The three bit field { isGrey, isPinned, isRemembered }
	 is for bits that are never set in young objects.  This allows the remembered
	 table to be pruned when full by using these bits as a reference count of
	 newSpace objects from the remembered table. Objects with a high count
	 should be tenured to prune the remembered table."
	<returnTypeC: #usqLong>
	<inline: true>
	^ ((self cCoerceSimple: numSlots to: #usqLong) << self numSlotsFullShift)
	+ (formatField << self formatShift)
	+ classIndex
]

{ #category : #'header format' }
SpurMemoryManager >> headerForSlots: numSlots hash: hash format: formatField classIndex: classIndex [
	"The header format in LSB is
	 MSB:	| 8: numSlots		| (on a byte boundary)
			| 2 bits				|	(msb,lsb = {isMarked,?})
			| 22: identityHash	| (on a word boundary)
			| 3 bits				|	(msb <-> lsb = {isGrey,isPinned,isRemembered}
			| 5: format			| (on a byte boundary)
			| 2 bits				|	(msb,lsb = {isImmutable,?})
			| 22: classIndex		| (on a word boundary) : LSB
	 The remaining bits (7) are used for
		isImmutable	(bit 23)
		isRemembered	(bit 29)
		isPinned		(bit 30)
		isGrey			(bit 31)
		isMarked		(bit 55)
	 leaving 2 unused bits, each next to a 22-bit field, allowing those fields to be
	 expanded to 23 bits..  The three bit field { isGrey, isPinned, isRemembered }
	 is for bits that are never set in young objects.  This allows the remembered
	 table to be pruned when full by using these bits as a reference count of
	 newSpace objects from the remembered table. Objects with a high count
	 should be tenured to prune the remembered table."
	<returnTypeC: #usqLong>
	<inline: true>
	^ ((self cCoerceSimple: numSlots to: #usqLong) << self numSlotsFullShift)
	+ ((self cCoerceSimple: hash to: #usqLong) << self identityHashFullWordShift)
	+ (formatField << self formatShift)
	+ classIndex
]

{ #category : #'method access' }
SpurMemoryManager >> headerIndicatesAlternateBytecodeSet: methodHeader [
	"A negative header selects the alternate bytecode set."
	<api>
	<inline: true>
	self subclassResponsibility
]

{ #category : #'debug support' }
SpurMemoryManager >> heapMap [
	^heapMap
]

{ #category : #'class table' }
SpurMemoryManager >> hiddenRootSlots [
	"Answer the number of extra root slots in the root of the hidden root object."
	^8
]

{ #category : #accessing }
SpurMemoryManager >> hiddenRootsObject [
	^hiddenRootsObj
]

{ #category : #'header format' }
SpurMemoryManager >> identityHashFieldWidth [
	^22
]

{ #category : #'header access' }
SpurMemoryManager >> identityHashFullWordMask [
	^16r3fffff00000000
]

{ #category : #'header access' }
SpurMemoryManager >> identityHashFullWordShift [
	<api>
	<cmacro>
	^32
]

{ #category : #'header format' }
SpurMemoryManager >> identityHashHalfWordMask [
	<api>
	<cmacro>
	^16r3fffff
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> ifAProxy: objOop updateCopy: copy [
	"This is part of storeImageSegmentInto:outPointers:roots:.
	 If the object being copied to the segment is weird and has exotic state,
	 i.e. a married context or a jitted method, update the copy with the vanilla state."

	(self isContext: objOop) ifTrue:
		[| numMediatedSlots |
		 (coInterpreter isMarriedOrWidowedContext: objOop)
			ifTrue:
				["Since the context is here via objectsReachableFromRoots: we know it cannot be divorced.
				  I'd like to assert coInterpreter checkIsStillMarriedContext: objOop currentFP: framePointer,
				  here but that requires access to framePointer."
				 numMediatedSlots := coInterpreter numSlotsOfMarriedContext: objOop.
				 0 to: numMediatedSlots - 1 do:
					[:i| | oop |
					 oop := coInterpreter fetchPointer: i ofMarriedContext: objOop.
					 self storePointerUnchecked: i ofObject: copy withValue: oop]]
			ifFalse:
				[numMediatedSlots := self numPointerSlotsOf: objOop].
		 "And make sure to nil the slots beyond the top of stack..."
		 numMediatedSlots to: (self numSlotsOf: objOop) - 1 do:
			[:i| self storePointerUnchecked: i ofObject: copy withValue: nilObj]]
]

{ #category : #'become implementation' }
SpurMemoryManager >> ifOopInvalidForBecome: oop errorCodeInto: aBlock [
	"Evaluates aBlock with an appropriate error if oop is invalid for become."
	<inline: true>
	(self isImmediate: oop) ifTrue:
		[^aBlock value: PrimErrInappropriate].
	(self isPinned: oop) ifTrue:
		[^aBlock value: PrimErrObjectIsPinned].
	(self isObjImmutable: oop) ifTrue:
		[^aBlock value: PrimErrNoModification]
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> imageFormatVersion [
	"Return a magic constant that changes when the image format changes.
	 Since the image reading code uses this to detect byte ordering, one
	 must avoid version numbers that are invariant under byte reversal."
	^self subclassResponsibility
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> imageSegmentVersion [
	| wholeWord |
	"a more complex version that tells both the word reversal and the endianness of the machine
	 it came from.  Low half of word is e.g. 6521.  Top byte is top byte of #doesNotUnderstand: on
	 this machine. ($d on the Mac or $s on the PC)"

	wholeWord := self long32At: (self splObj: SelectorDoesNotUnderstand) + self baseHeaderSize. "first data word, 'does'"
	^coInterpreter imageFormatVersion bitOr: (wholeWord bitAnd: 16rFF000000)
]

{ #category : #snapshot }
SpurMemoryManager >> imageSizeToWrite [
	"when asked, newSpace should be empty."
	self assert: self newSpaceIsEmpty.
	^segmentManager totalBytesInNonEmptySegments
]

{ #category : #'header format' }
SpurMemoryManager >> immutableBitMask [
	"mask the immutable bit in the base header word"
	<api>
	<option: #IMMUTABILITY>
	^ 1 << self immutableBitShift
]

{ #category : #'header format' }
SpurMemoryManager >> immutableBitShift [
	<cmacro>
	"bit 1 of 2-bit field above classIndex (little endian)"
	^23
]

{ #category : #'free space' }
SpurMemoryManager >> inFreeTreeReplace: treeNode with: newNode [
	"Part of reorderReversedTreeList:.  Switch treeNode with newNode in
	 the tree, but do nothing to the list linked through freeChunkNextIndex."
	| relative |
	self storePointer: self freeChunkPrevIndex ofFreeChunk: newNode withValue: 0.
	"copy parent, smaller, larger"
	self freeChunkParentIndex to: self freeChunkLargerIndex do:
		[:i|
		relative := self fetchPointer: i ofFreeChunk: treeNode.
		i = self freeChunkParentIndex
			ifTrue:
				[relative = 0
					ifTrue: "update root to point to newNode"
						[self assert: (freeLists at: 0) = treeNode.
						 freeLists at: 0 put: newNode]
					ifFalse: "replace link from parent to treeNode with link to newNode."
						[self storePointer: (treeNode = (self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: relative)
												ifTrue: [self freeChunkSmallerIndex]
												ifFalse: [self freeChunkLargerIndex])
							ofFreeChunk: relative
							withValue: newNode]]
			ifFalse:
				[relative ~= 0 ifTrue:
					[self assert: (self fetchPointer: self freeChunkParentIndex ofFreeChunk: relative) = treeNode.
					 self storePointer: self freeChunkParentIndex ofFreeChunk: relative withValue: newNode]].
		self storePointer: i ofFreeChunk: newNode withValue: relative.
		self storePointer: i ofFreeChunk: treeNode withValue: 0]
]

{ #category : #'debug support' }
SpurMemoryManager >> inLineRunLeakCheckerFor: gcModes excludeUnmarkedObjs: excludeUnmarkedObjs classIndicesShouldBeValid: classIndicesShouldBeValid [
	<inline: true>
	(gcModes anyMask: checkForLeaks) ifTrue:
		[(gcModes anyMask: GCModeFull)
			ifTrue: [coInterpreter reverseDisplayFrom: 0 to: 7]
			ifFalse: [coInterpreter reverseDisplayFrom: 8 to: 15].
		 self clearLeakMapAndMapAccessibleObjects.
		 self asserta: (self checkHeapIntegrity: excludeUnmarkedObjs classIndicesShouldBeValid: classIndicesShouldBeValid).
		 self asserta: coInterpreter checkInterpreterIntegrity = 0.
		 self asserta: coInterpreter checkStackIntegrity.
		 self asserta: (coInterpreter checkCodeIntegrity: gcModes)]
]

{ #category : #'debug printing' }
SpurMemoryManager >> inOrderPrintFreeTree: freeChunk printList: printNextList [
	"print free chunks in freeTree in order."
	<api>
	| next |
	(next := self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: freeChunk) ~= 0 ifTrue:
		[self inOrderPrintFreeTree: next printList: printNextList].
	self printFreeChunk: freeChunk printAsTreeNode: true.
	printNextList ifTrue:
		[next := freeChunk.
		 [(next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: next) ~= 0] whileTrue:
			[coInterpreter tab.
			 self printFreeChunk: next printAsTreeNode: false]].
	(next := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: freeChunk) ~= 0 ifTrue:
		[self inOrderPrintFreeTree: next printList: printNextList]
]

{ #category : #'become implementation' }
SpurMemoryManager >> inPlaceBecome: obj1 and: obj2 copyHashFlag: copyHashFlag [
	<inline: #never> "in an effort to fix a compiler bug with two-way become post r3427"
	"Do become in place by swapping object contents."
	| o1HasYoung o2HasYoung fmt |
	self assert: (self numSlotsOf: obj1) = (self numSlotsOf: obj2).
	self assert: ((self rawHashBitsOf: obj1) = 0
				 or: [(self classOrNilAtIndex: (self rawHashBitsOf: obj1)) ~= obj1]).
	self assert: ((self rawHashBitsOf: obj2) = 0
				 or: [(self classOrNilAtIndex: (self rawHashBitsOf: obj2)) ~= obj2]).
	"swap headers, but swapping headers swaps remembered bits and hashes;
	 remembered bits must be unswapped and hashes may be unswapped if
	 copyHash is false."
	false
		ifTrue: [self naiveSwapHeaders: obj1 and: obj2 copyHashFlag: copyHashFlag]
		ifFalse: [self cleverSwapHeaders: obj1 and: obj2 copyHashFlag: copyHashFlag].
	o1HasYoung := o2HasYoung := false.
	0 to: (self numSlotsOf: obj1) - 1 do:
		[:i| | temp1 temp2 |
		temp1 := self fetchPointer: i ofObject: obj1.
		temp2 := self fetchPointer: i ofObject: obj2.
		self storePointerUnchecked: i ofObject: obj1 withValue: temp2.
		self storePointerUnchecked: i ofObject: obj2 withValue: temp1.
		(self isYoung: temp2) ifTrue:
			[o1HasYoung := true].
		(self isYoung: temp1) ifTrue:
			[o2HasYoung := true]].
	(o1HasYoung and: [self isOldObject: obj1]) ifTrue:
		[fmt := self formatOf: obj1.
		 (self isPureBitsFormat: fmt) ifFalse:
			[self possibleRootStoreInto: obj1]].
	(o2HasYoung and: [self isOldObject: obj2]) ifTrue:
		[fmt := self formatOf: obj2.
		 (self isPureBitsFormat: fmt) ifFalse:
			[self possibleRootStoreInto: obj2]]
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> inactiveOrFailedToDeferScan: anEphemeron [
	"Answer whether an ephemeron is inactive (has a marked key) or,
	 if active, failed to fit on the unscanned ephemerons stack."
	| key |
	self assert: (self isEphemeron: anEphemeron).
	((self isImmediate: (key := self keyOfEphemeron: anEphemeron))
	 or: [self isMarked: key]) ifTrue:
		[^true].
	^(self pushOnUnscannedEphemeronsStack: anEphemeron) not
]

{ #category : #'free space' }
SpurMemoryManager >> increaseFreeOldSpaceBy: bytes [ 
	totalFreeOldSpace := totalFreeOldSpace + bytes

]

{ #category : #'gc - global' }
SpurMemoryManager >> incrementalGC [
	self shouldNotImplement
]

{ #category : #'debug support' }
SpurMemoryManager >> indexOf: anElement in: anObject [
	<api>
	| fmt numSlots |
	fmt := self formatOf: anObject.

	fmt <= self lastPointerFormat ifTrue:
		[numSlots := self numSlotsOf: anObject.
		 0 to: numSlots do:
			[:i| anElement = (self fetchPointer: i ofMaybeForwardedObject: anObject) ifTrue: [^i]].
		-1].

	fmt >= self firstByteFormat ifTrue:
		[fmt >= self firstCompiledMethodFormat ifTrue:
			[^self primitiveFailFor: PrimErrUnsupported].
		 numSlots := self numBytesOfBytes: anObject.
		 0 to: numSlots do:
			[:i| (self fetchByte: i ofObject: anObject) ifTrue: [^i]].
		-1].

	fmt >= self firstShortFormat ifTrue:
		[numSlots := self num16BitUnitsOf: anObject.
		 0 to: numSlots do:
			[:i| anElement = (self fetchUnsignedShort16: i ofObject: anObject) ifTrue: [^i]].
		-1].

	fmt = self sixtyFourBitIndexableFormat ifTrue:
		[numSlots := self num64BitUnitsOf: anObject.
		 0 to: numSlots do:
			[:i| anElement = (self fetchLong64: i ofObject: anObject) ifTrue: [^i]].
		-1].

	fmt >= self firstLongFormat ifTrue:
		[numSlots := self num32BitUnitsOf: anObject.
		 0 to: numSlots do:
			[:i| anElement = (self fetchLong32: i ofObject: anObject) ifTrue: [^i]].
		-1].

	^-1
]

{ #category : #'header formats' }
SpurMemoryManager >> indexablePointersFormat [
	<api>
	<cmacro>
	^3
]

{ #category : #'free space' }
SpurMemoryManager >> initFreeChunkWithBytes: numBytes at: address [
	<var: #numBytes type: #usqLong>
	^self subclassResponsibility
]

{ #category : #segments }
SpurMemoryManager >> initSegmentBridgeWithBytes: numBytes at: address [
	<var: #numBytes type: #usqLong>
	^self subclassResponsibility
]

{ #category : #allocation }
SpurMemoryManager >> initSpaceForAllocationCheck: aNewSpace limit: limit [
	<var: 'aNewSpace' type: #'SpurNewSpaceSpace *'>
	<var: 'limit' type: #usqInt>
	memory ifNotNil:
		[self checkAllocFiller ifTrue:
			[aNewSpace start
				to: limit - 1
				by: self wordSize
				do: [:p| self longAt: p put: p]]]
]

{ #category : #snapshot }
SpurMemoryManager >> initialHeadroom: extraVmMemory givenFreeOldSpaceInImage: freeOldSpaceInImage [
	"Answer how much headroom to allocate, if any, on loading the image.
	 If the image already conatins lots of free space, we should not allocate lots more."
	<inline: true>
	| headroom |
	headroom := extraVmMemory = 0
					ifTrue: [growHeadroom ifNil: [16*1024*1024]]
					ifFalse: [extraVmMemory].
	freeOldSpaceInImage >= headroom ifTrue:
		[^0].
	freeOldSpaceInImage >= (headroom * 7 // 8) ifTrue:
		[^headroom // 8].
	freeOldSpaceInImage >= (headroom * 3 // 4) ifTrue:
		[^headroom // 4].
	freeOldSpaceInImage >= (headroom * 5 // 8) ifTrue:
		[^headroom * 3 // 8].
	freeOldSpaceInImage >= (headroom // 2) ifTrue:
		[^headroom // 2].
	^headroom
]

{ #category : #'object enumeration' }
SpurMemoryManager >> initialInstanceOf: classObj [
	<inline: false>
	| classIndex |
	classIndex := self rawHashBitsOf: classObj.
	classIndex = 0 ifTrue:
		[^nil].
	"flush instances in newSpace to settle the enumeration."
	self flushNewSpaceInstancesOf: classObj.
	self allObjectsDo:
		[:objOop|
		classIndex = (self classIndexOf: objOop) ifTrue:
			[^objOop]].
	^nil
]

{ #category : #initialization }
SpurMemoryManager >> initialize [
	"We can put all initializations that set something to 0 or to false here.
	 In C all global variables are initialized to 0, and 0 is false."
	remapBuffer := Array new: RemapBufferSize.
	remapBufferCount := extraRootCount := 0. "see below"
	freeListsMask := totalFreeOldSpace := lowSpaceThreshold := 0.
	checkForLeaks := 0.
	needGCFlag := signalLowSpace := marking := false.
	becomeEffectsFlags := gcPhaseInProgress := 0.
	statScavenges := statIncrGCs := statFullGCs := 0.
	statMaxAllocSegmentTime := 0.
	statMarkUsecs := statSweepUsecs := statScavengeGCUsecs := statIncrGCUsecs := statFullGCUsecs := statCompactionUsecs := statGCEndUsecs := gcSweepEndUsecs := 0.
	statSGCDeltaUsecs := statIGCDeltaUsecs := statFGCDeltaUsecs := 0.
	statGrowMemory := statShrinkMemory := statRootTableCount := statAllocatedBytes := 0.
	statRootTableOverflows := statMarkCount := statCompactPassCount := statCoalesces := 0.

	"We can initialize things that are allocated but are lazily initialized."
	unscannedEphemerons := SpurContiguousObjStack new.

	"we can initialize things that are virtual in C."
	scavenger := SpurGenerationScavenger simulatorClass new manager: self; yourself.
	segmentManager := SpurSegmentManager simulatorClass new manager: self; yourself.
	compactor := self class compactorClass simulatorClass new manager: self; yourself.

	"We can also initialize here anything that is only for simulation."
	heapMap := CogCheck32BitHeapMap new.

	"N.B. We *don't* initialize extraRoots because we don't simulate it."
	maxOldSpaceSize := self class initializationOptions
							ifNotNil: [:initOpts| initOpts at: #maxOldSpaceSize ifAbsent: [0]]
							ifNil: [0]
]

{ #category : #bootstrap }
SpurMemoryManager >> initializeFreeList [

	| freeListOop |
	freeListOop := self objectMemory
		allocateSlots: self numFreeLists
		format: self wordIndexableFormat
		classIndex: self wordSizeClassIndexPun.
	0 to: self numFreeLists - 1 do: [ :i |
		self
			storePointerUnchecked: i
			ofObject: freeListOop
			withValue: 0].
	self initializeFreeSpacePostLoad: freeListOop.
	^ freeListOop
]

{ #category : #bootstrap }
SpurMemoryManager >> initializeFreeListInOldSpace: inOldSpace [

	| freeListOop |
	
	freeListOop := inOldSpace ifTrue: [
		self objectMemory
			allocateSlotsInOldSpace: self numFreeLists
			format: self wordIndexableFormat
			classIndex: self wordSizeClassIndexPun.
	] ifFalse: [ 
		self objectMemory
			allocateSlots: self numFreeLists
			format: self wordIndexableFormat
			classIndex: self wordSizeClassIndexPun.
	].
	0 to: self numFreeLists - 1 do: [ :i |
		self
			storePointerUnchecked: i
			ofObject: freeListOop
			withValue: 0].
	^ freeListOop
]

{ #category : #snapshot }
SpurMemoryManager >> initializeFreeSpacePostLoad: freeListObj [
	"Reinitialize the free list info.  The freeLists object needs to be swizzled
	 because its neither a free, nor a pointer object.  Free objects have already
	 been swizzled in adjustAllOopsBy:"
	
	self assert: (self numSlotsOf: freeListObj) = self numFreeLists.
	self assert: (self formatOf: freeListObj) = self wordIndexableFormat.
	freeLists := self firstIndexableField: freeListObj.
	freeListsMask := 0.
	0 to: self numFreeLists - 1 do:
		[:i|
		(freeLists at: i) ~= 0 ifTrue:
			[freeListsMask := freeListsMask bitOr: (1 << i).
			 freeLists at: i put: (segmentManager swizzleObj: (freeLists at: i))]]
]

{ #category : #'gc - global' }
SpurMemoryManager >> initializeMarkStack [
	self ensureRoomOnObjStackAt: MarkStackRootIndex
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> initializeNewSpaceVariables [
	<inline: #never>
	
	1halt.
	
	freeStart := scavenger eden start.
	pastSpaceStart := scavenger pastSpace start.
	scavengeThreshold := scavenger eden limit
							- (scavenger edenBytes // 64)
							- coInterpreter interpreterAllocationReserveBytes.
	newSpaceStart := scavenger pastSpace start min: scavenger futureSpace start.
	self assert: newSpaceStart < scavenger eden start.
	self initSpaceForAllocationCheck: (self addressOf: scavenger eden) limit: scavengeThreshold
]

{ #category : #initialization }
SpurMemoryManager >> initializeObjectMemory: bytesToShift [
	"Initialize object memory variables at startup time. Assume endOfMemory at al are
	 initialised by the image-reading code via setHeapBase:memoryLimit:endOfMemory:.
	 endOfMemory is assumed to point to the end of the last object in the image.
	 Assume: image reader also initializes the following variables:
		specialObjectsOop
		lastHash"
	<inline: false>
	| freeListObj |
	"Catch mis-initializations leading to bad translations to C"
	self assert: self baseHeaderSize = self baseHeaderSize.
	self assert: (self maxSlotsForAlloc * self wordSize) asInteger > 0.
	self bootstrapping ifFalse:
		[self
			initSegmentBridgeWithBytes: self bridgeSize
			at: endOfMemory - self bridgeSize].
	segmentManager adjustSegmentSwizzlesBy: bytesToShift.
	"image may be at a different address; adjust oops for new location"
	self adjustAllOopsBy: bytesToShift.
	specialObjectsOop := segmentManager swizzleObj: specialObjectsOop.

	"heavily used special objects"
	nilObj		:= self splObj: NilObject.
	falseObj	:= self splObj: FalseObject.
	trueObj		:= self splObj: TrueObject.

	"In Cog we insist that nil, true & false are next to each other (Cogit generates tighter
	 conditional branch code as a result).  In addition, Spur places the free lists and
	 class table root page immediately following them."
	self assert: nilObj = oldSpaceStart.
	self assert: falseObj = (self oldSpaceObjectAfter: nilObj).
	self assert: trueObj = (self oldSpaceObjectAfter: falseObj).
	freeListObj := self oldSpaceObjectAfter: trueObj.
	self setHiddenRootsObj: (self oldSpaceObjectAfter: freeListObj).
	markStack := self swizzleObjStackAt: MarkStackRootIndex.
	weaklingStack := self swizzleObjStackAt: WeaklingStackRootIndex.
	mournQueue := self swizzleObjStackAt: MournQueueRootIndex.
	self assert: self validObjStacks.
	self assert: (self isEmptyObjStack: markStack).
	self assert: (self isEmptyObjStack: weaklingStack).

	self initializeFreeSpacePostLoad: freeListObj.
	segmentManager collapseSegmentsPostSwizzle.
	self updateFreeLists.
	self computeFreeSpacePostSwizzle.
	compactor postSwizzleAction.
	self initializeOldSpaceFirstFree: freeOldSpaceStart. "initializes endOfMemory, freeStart, free space"
	self initializeNewSpaceVariables.
	scavenger initializeRememberedSet.
	segmentManager checkSegments.
	compactor biasForGC.

	"These defaults should depend on machine size; e.g. too small on a powerful laptop, too big on a Pi."
	growHeadroom := 16*1024*1024.		"headroom when growing"
	shrinkThreshold := 32*1024*1024.		"free space before shrinking"
	self setHeapSizeAtPreviousGC.
	heapGrowthToSizeGCRatio := 0.333333. "By default GC after scavenge if heap has grown by a third since the last GC"
]

{ #category : #'free space' }
SpurMemoryManager >> initializeOldSpaceFirstFree: startOfFreeOldSpace [
	<var: 'startOfFreeOldSpace' type: #usqInt>
	| limit freeOldStart freeChunk |
	<var: 'limit' type: #usqInt>
	<var: 'freeOldStart' type: #usqInt>
	limit := endOfMemory - self bridgeSize.
	limit > startOfFreeOldSpace ifTrue:
		[totalFreeOldSpace := totalFreeOldSpace + (limit - startOfFreeOldSpace).
		 freeOldStart := startOfFreeOldSpace.
		 self wordSize > 4 ifTrue:
			[[limit - freeOldStart >= (1 << 32)] whileTrue:
				[freeChunk := self freeChunkWithBytes: (1 << 32) at: freeOldStart.
				 freeOldStart := freeOldStart + (1 << 32).
				 self assert: freeOldStart = (self addressAfter: freeChunk)]].
		freeOldStart < limit ifTrue:
			[freeChunk := self freeChunkWithBytes: limit - freeOldStart at: freeOldStart.
			 self assert: (self addressAfter: freeChunk) = limit]].
	endOfMemory := endOfMemory - self bridgeSize.
	freeOldSpaceStart := endOfMemory.
	self checkFreeSpace: GCModeFreeSpace
]

{ #category : #'spur bootstrap' }
SpurMemoryManager >> initializePostBootstrap [
	"The heap has just been bootstrapped into a modified newSpace occupying all of memory
	 above newSpace (and the codeZone). Put things back to some kind of normalcy."
	freeOldSpaceStart := freeStart.
	freeStart := scavenger eden start.
	pastSpaceStart := scavenger pastSpace start.
	scavengeThreshold := scavenger eden limit - (scavenger edenBytes // 64)
]

{ #category : #'gc - global' }
SpurMemoryManager >> initializeUnscannedEphemerons [
	"Initialize unscannedEphemerons to use the largest free chunk
	 or unused eden space, which ever is the larger."
	
	| largestFree sizeOfUnusedEden |
	largestFree := self findLargestFreeChunk.
	sizeOfUnusedEden := scavenger eden limit - freeStart.
	(largestFree notNil
	 and: [(self numSlotsOfAny: largestFree) > (sizeOfUnusedEden / self wordSize)])
		ifTrue:
			[unscannedEphemerons
				start: largestFree
					+ self baseHeaderSize
					+ (self freeChunkLargerIndex + 1 * self wordSize);
				limit: (self addressAfter: largestFree)]
		ifFalse:
			[unscannedEphemerons
				start: freeStart;
				limit: scavenger eden limit].
	unscannedEphemerons top: unscannedEphemerons start
]

{ #category : #'gc - global' }
SpurMemoryManager >> initializeWeaklingStack [
	self ensureRoomOnObjStackAt: WeaklingStackRootIndex
]

{ #category : #'become implementation' }
SpurMemoryManager >> innerBecomeObjectsIn: array1 and: array2 copyHash: copyHashFlag [
	"Inner loop of two-way become."
	0 to: (self numSlotsOf: array1) - 1 do:
		[:i| | obj1 obj2 |
		"At first blush it would appear unnecessary to use followField: here since
		 the validation in become:with:twoWay:copyHash: follows forwarders.  But
		 there's nothing to ensure all elements of each array are unique and don't
		 appear in the other array.  So the enumeration could encounter an object
		 already becommed earlier in the same enumeration."
		obj1 := self followField: i ofObject: array1.
		obj2 := self followField: i ofObject: array2.
		obj1 ~= obj2 ifTrue:
			[self doBecome: obj1 and: obj2 copyHash: copyHashFlag.
			 self followField: i ofObject: array1.
			 self followField: i ofObject: array2]]
]

{ #category : #'become implementation' }
SpurMemoryManager >> innerBecomeObjectsIn: array1 to: array2 copyHash: copyHashFlag [
	"Inner loop of one-way become."
	0 to: (self numSlotsOf: array1) - 1 do:
		[:i| | obj1 obj2 |
		"At first blush it would appear unnecessary to use followField: here since
		 the validation in become:with:twoWay:copyHash: follows forwarders.  But
		 there's nothing to ensure all elements of each array is unique and doesn't
		 appear in the other array.  So the enumeration could encounter an object
		 already becommed earlier in the same enumeration."
		obj1 := self followField: i ofObject: array1.
		obj2 := self followField: i ofObject: array2.
		obj1 ~= obj2 ifTrue:
			[self doBecome: obj1 to: obj2 copyHash: copyHashFlag.
			 self followField: i ofObject: array1.
			 self assert: (self isOopForwarded: obj2) not]]
]

{ #category : #'header formats' }
SpurMemoryManager >> instSpecForImmediateClasses [
	"Use the format for forwarded objects for immediate classes.  Immediate classes (SmallInteger,
	 Character, etc) can't be instantiated, so the inst spec should be an invalid one to cause the
	 instantiation primitives to fail.  The forwardedFormat is internal to the SpurMemoryManager,
	 used to mark forwarded objects only, and so is suitable."
	^self forwardedFormat
]

{ #category : #'object format' }
SpurMemoryManager >> instSpecOfClass: classPointer [
	"This field in a class's format inst var corresponds to the 5-bit format field stored in every object header"

	^self instSpecOfClassFormat: (self formatOfClass: classPointer)
]

{ #category : #'object format' }
SpurMemoryManager >> instSpecOfClassFormat: classFormat [
	<api>
	^classFormat >> self fixedFieldsFieldWidth bitAnd: self formatMask
]

{ #category : #'object enumeration' }
SpurMemoryManager >> instanceAfter: objOop [
	| actualObj classIndex |
	actualObj := objOop.
	classIndex := self classIndexOf: objOop.

	(self isInEden: objOop) ifTrue:
		[[actualObj := self objectAfter: actualObj limit: freeStart.
		  self oop: actualObj isLessThan: freeStart] whileTrue:
			[classIndex = (self classIndexOf: actualObj) ifTrue:
				[^actualObj]].
		 actualObj := (self oop: pastSpaceStart isGreaterThan: scavenger pastSpace start)
						ifTrue: [self objectStartingAt: scavenger pastSpace start]
						ifFalse: [nilObj]].

	(self isInPastSpace: actualObj) ifTrue:
		[[actualObj := self objectAfter: actualObj limit: pastSpaceStart.
		  self oop: actualObj isLessThan: pastSpaceStart] whileTrue:
			[classIndex = (self classIndexOf: actualObj) ifTrue:
				[^actualObj]].
		 actualObj := nilObj].

	[actualObj := self objectAfter: actualObj limit: endOfMemory.
	 self oop:actualObj isLessThan: endOfMemory] whileTrue:
		[classIndex = (self classIndexOf: actualObj) ifTrue:
			[^actualObj]].
	^nil
]

{ #category : #'interpreter access' }
SpurMemoryManager >> instanceSizeOf: classObj [
	<api>
	"Answer the number of slots in a class.  For example the instanceSizeOf: 
	 ClassPoint is 2, for the x & y slots. The instance size of non-pointer classes is 0."
	self assert: (coInterpreter addressCouldBeClassObj: classObj).

	^(self formatOfClass: classObj) bitAnd: self fixedFieldsOfClassFormatMask
]

{ #category : #instantiation }
SpurMemoryManager >> instantiateClass: classObj [

	^ self instantiateClass: classObj isPinned: false
]

{ #category : #instantiation }
SpurMemoryManager >> instantiateClass: classObj indexableSize: nElements [
	<api>

	^ self instantiateClass: classObj indexableSize: nElements isPinned: false
]

{ #category : #instantiation }
SpurMemoryManager >> instantiateClass: classObj indexableSize: nElements isPinned: isPinned [
	<api>

	^ self subclassResponsibility
]

{ #category : #instantiation }
SpurMemoryManager >> instantiateClass: classObj isPinned: isPinned [
	| instSpec classFormat numSlots classIndex newObj |
	classFormat := self formatOfClass: classObj.
	instSpec := self instSpecOfClassFormat: classFormat.
	(self isFixedSizePointerFormat: instSpec) ifFalse:
		[^nil].
	classIndex := self ensureBehaviorHash: classObj.
	classIndex < 0 ifTrue:
		[coInterpreter primitiveFailFor: classIndex negated.
		 ^nil].
	numSlots := self fixedFieldsOfClassFormat: classFormat.
	newObj := self allocateSlots: numSlots format: instSpec classIndex: classIndex isPinned: isPinned.
	newObj ifNotNil:
		[self fillObj: newObj numSlots: numSlots with: nilObj].
	^newObj
]

{ #category : #instantiation }
SpurMemoryManager >> instantiateCompiledMethodClass: classObj indexableSize: nElements [
	<var: #nElements type: #usqInt>
	"Allocate an instance of a CompiledMethod class."
	^self subclassResponsibility
]

{ #category : #immediates }
SpurMemoryManager >> integerObjectOf: value [
	"Convert the integer value, assumed to be in SmallInteger range, into a tagged SmallInteger object.
	 In C, use a shift and an add to set the tag bit.
	 In Smalltalk we have to work harder because the simulator works with strictly positive bit patterns."
	^self subclassResponsibility
]

{ #category : #immediates }
SpurMemoryManager >> integerObjectOfCharacterObject: oop [
	self subclassResponsibility
]

{ #category : #immediates }
SpurMemoryManager >> integerValueOf: oop [
	^self subclassResponsibility
]

{ #category : #simulation }
SpurMemoryManager >> interpreter [
	<doNotGenerate>
	^coInterpreter
]

{ #category : #'simulation only' }
SpurMemoryManager >> ioLoadFunction: functionName From: moduleName [
	"hack around the CoInterpreter/ObjectMemory split refactoring.
	 provide accurate types for the VMPluginCodeGenerator."
	<doNotGenerate>
	<returnTypeC: #'void *'>
	<var: #functionName type: #'char *'>
	<var: #moduleName type: #'char *'>
	^coInterpreter ioLoadFunction: functionName From: moduleName
]

{ #category : #'simulation only' }
SpurMemoryManager >> ioLoadModule: moduleNameIndex OfLength: moduleLength [
	<doNotGenerate>
	<returnTypeC: #'void *'>
	"Dummy - provided by support code"
	^0
]

{ #category : #'simulation only' }
SpurMemoryManager >> ioUTCMicrosecondsNow [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter ioUTCMicrosecondsNow
]

{ #category : #'simulation only' }
SpurMemoryManager >> is: oop KindOf: classNameString [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter is: oop KindOf: classNameString
]

{ #category : #'simulation only' }
SpurMemoryManager >> is: oop KindOfClass: aClass [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter is: oop KindOfClass: aClass
]

{ #category : #'object access' }
SpurMemoryManager >> is: oop instanceOf: classOop [
	"Answer if oop is an instance of the given class."

	<inline: true>
	| tag |
	tag := self fetchClassTagOf: oop.
	^tag = (self rawHashBitsOf: classOop)
]

{ #category : #'object access' }
SpurMemoryManager >> is: oop instanceOf: classOop compactClassIndex: compactClassIndex [
	"Answer if oop is an instance of the given class. If the class has a (non-zero)
	 compactClassIndex use that to speed up the check.  N.B. Inlining should
	 result in classOop not being accessed if oop's compact class index and
	 compactClassIndex are non-zero."

	<inline: true>
	(self isImmediate: oop) ifTrue:
		[^false].

	^self isClassOfNonImm: oop equalTo: classOop compactClassIndex: compactClassIndex
]

{ #category : #'obj stacks' }
SpurMemoryManager >> is: oop onObjStack: objStack [
	<inline: false>
	| index nextPage |
	objStack = nilObj ifTrue:
		[^false].
	self assert: (self numSlotsOfAny: objStack) = ObjStackPageSlots.
	"There are four fixed slots in an obj stack, and a Topx of 0 indicates empty, so
	  if there were 6 slots in an oop stack, full would be 2, and the last 0-rel index is 5."
	index := (self fetchPointer: ObjStackTopx ofObject: objStack) + ObjStackNextx.
	[index >= ObjStackFixedSlots] whileTrue:
		[oop = (self fetchPointer: index ofObject: objStack) ifTrue:
			[^true].
		 index := index - 1].
	nextPage := self fetchPointer: ObjStackNextx ofObject: objStack.
	nextPage ~= 0 ifTrue:
		[(self is: oop onObjStack: nextPage) ifTrue:
			[^true]].
	^false
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> is: hash outPointerClassHashFor: oop in: outPointerArray limit: outIndex [
	"This is part of storeImageSegmentInto:outPointers:roots:.
	 suspect; what about false positives?"
	^(hash anyMask: TopHashBit)
	  and: [hash - TopHashBit <= outIndex
	  and: [oop = (self fetchPointer: hash - TopHashBit ofObject: outPointerArray)]]
]

{ #category : #'header formats' }
SpurMemoryManager >> isAnyPointerFormat: format [
	"the inverse of isPureBitsFormat:"
	<inline: true>
	^format <= self lastPointerFormat or: [format >= self firstCompiledMethodFormat]
]

{ #category : #'object testing' }
SpurMemoryManager >> isArray: oop [
	"Answer true if this is an indexable object with pointer elements, e.g., an array"
	^(self isNonImmediate: oop) and: [self isArrayNonImm: oop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isArrayNonImm: oop [
	<api>
	"Answer if this is an indexable object with pointer elements, e.g., an array"
	^ (self formatOf: oop) = self arrayFormat
]

{ #category : #'simulation only' }
SpurMemoryManager >> isBooleanObject: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter isBooleanObject: oop
]

{ #category : #'object testing' }
SpurMemoryManager >> isBytes: oop [
	"Answer true if the argument contains indexable bytes. See comment in formatOf:"
	"Note: Includes CompiledMethods."
	^(self isNonImmediate: oop) and: [self isBytesNonImm: oop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isBytesNonImm: objOop [
	"Answer true if the argument contains indexable bytes. See comment in formatOf:"
	^(self formatOf: objOop) >= self firstByteFormat
]

{ #category : #immediates }
SpurMemoryManager >> isCharacterObject: oop [
	<api>
	^self isImmediateCharacter: oop
]

{ #category : #immediates }
SpurMemoryManager >> isCharacterValue: anInteger [
	<api>
	^self isInRangeCharacterCode: anInteger
]

{ #category : #'class table' }
SpurMemoryManager >> isClassAtUniqueIndex: aClass [
	"Answer if aClass exists at only one index in the class table.  Be careful not to
	 be misled by classes that have puns, such as Array."
	| expectedIndex |
	expectedIndex := self rawHashBitsOf: aClass.
	self classTableEntriesDo:
		[:entry :index|
		 (entry = aClass
		  and: [index ~= expectedIndex
		  and: [index > self lastClassIndexPun]]) ifTrue:
			[^false]].
	^true
]

{ #category : #'object testing' }
SpurMemoryManager >> isClassOfNonImm: objOop equalTo: classOop [
	<inline: true>
	self assert: (self isNonImmediate: objOop).
	^(self classIndexOf: objOop) = (self rawHashBitsOf: classOop)
]

{ #category : #'object access' }
SpurMemoryManager >> isClassOfNonImm: oop equalTo: classOop compactClassIndex: knownClassIndex [
	"Answer if the given (non-immediate) object is an instance of the given class
	 that may have a knownClassIndex (if knownClassIndex is non-zero).  This method
	 is misnamed given SPur's architecture (where all objects have ``compact'' class indices)
	 but is so-named for compatibility with ObjectMemory.
	 N.B. Inlining and/or compiler optimization should result in classOop not being
	 accessed if knownClassIndex is non-zero."

	| ccIndex |
	<inline: true>
	self assert: (self isImmediate: oop) not.

	ccIndex := self classIndexOf: oop.
	knownClassIndex ~= 0
		ifTrue:
			[^knownClassIndex = ccIndex]
		ifFalse:
			[^classOop = (self classAtIndex: ccIndex)]
]

{ #category : #'debug support' }
SpurMemoryManager >> isCompactInstance: oop [
	"For assert checking"
	^false
]

{ #category : #'object testing' }
SpurMemoryManager >> isCompiledMethod: objOop [
    "Answer whether the argument object is of compiled method format"
	<api>
    ^(self formatOf: objOop) >= self firstCompiledMethodFormat
]

{ #category : #'header formats' }
SpurMemoryManager >> isCompiledMethodFormat: format [
	^format >= self firstCompiledMethodFormat
]

{ #category : #'object testing' }
SpurMemoryManager >> isCompiledMethodHeader: objHeader [
    "Answer whether the argument header has compiled method format"
    ^(self formatOfHeader: objHeader) >= self firstCompiledMethodFormat
]

{ #category : #'object testing' }
SpurMemoryManager >> isContext: oop [
	<inline: true>
	^(self isNonImmediate: oop)
	   and: [(self classIndexOf: oop) = ClassMethodContextCompactIndex]
]

{ #category : #'header access' }
SpurMemoryManager >> isContextHeader: aHeader [
	<inline: true>
	^(self classIndexOfHeader: aHeader) = ClassMethodContextCompactIndex
]

{ #category : #'object testing' }
SpurMemoryManager >> isContextNonImm: oop [
	<inline: true>
	^(self classIndexOf: oop) = ClassMethodContextCompactIndex
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> isCopiedIntoSegment: anObjectInTheHeap [
	"This is part of storeImageSegmentInto:outPointers:roots:."
	<inline: true>
	^self isMarked: anObjectInTheHeap
]

{ #category : #'obj stacks' }
SpurMemoryManager >> isEmptyObjStack: objStack [
	objStack = nilObj ifTrue:
		[^true].
	self eassert: [self isValidObjStack: objStack].
	^0 = (self fetchPointer: ObjStackTopx ofObject: objStack)
	  and: [0 = (self fetchPointer: ObjStackNextx ofObject: objStack)]
]

{ #category : #'object enumeration' }
SpurMemoryManager >> isEnumerableObject: objOop [
	"Answer if objOop should be included in an allObjects...Do: enumeration.
	 Non-objects should be excluded; these are bridges and free chunks."
	| classIndex |
	<inline: true>
	classIndex := self classIndexOf: objOop.
	self assert: ((self long64At: objOop) ~= 0
				  and: [classIndex < (numClassTablePages * self classTablePageSize)]).
	^classIndex >= self isForwardedObjectClassIndexPun
]

{ #category : #'object enumeration' }
SpurMemoryManager >> isEnumerableObjectNoAssert: objOop [
	"Answer if objOop should be included in an allObjects...Do: enumeration.
	 This is for assert-checking only."
	| classIndex |
	classIndex := self classIndexOf: objOop.
	^classIndex >= self isForwardedObjectClassIndexPun
	  and: [classIndex < (numClassTablePages * self classTablePageSize)]
]

{ #category : #'object testing' }
SpurMemoryManager >> isEphemeron: objOop [
	self assert: (self isNonImmediate: objOop).
	^self isEphemeronFormat: (self formatOf: objOop)
]

{ #category : #'header formats' }
SpurMemoryManager >> isEphemeronFormat: format [
	<inline: true>
	^format = self ephemeronFormat
]

{ #category : #'header format' }
SpurMemoryManager >> isFixedSizePointerFormat: format [
	<api>
	^format <= self nonIndexablePointerFormat
	  or: [format = self ephemeronFormat]
]

{ #category : #'interpreter access' }
SpurMemoryManager >> isFloatInstance: oop [
	self subclassResponsibility
]

{ #category : #'simulation only' }
SpurMemoryManager >> isFloatObject: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter isFloatObject: oop
]

{ #category : #'interpreter access' }
SpurMemoryManager >> isFloatOrInt: anOop [
	"Answer if anOop is either a SmallInteger or a Float."

	self subclassResponsibility
]

{ #category : #'object testing' }
SpurMemoryManager >> isForwarded: objOop [
	"Answer if objOop is that if a forwarder.  Take advantage of isForwardedObjectClassIndexPun
	 being a power of two to generate a more efficient test than the straight-forward
		(self classIndexOf: objOop) = self isForwardedObjectClassIndexPun
	 at the cost of this being ambiguous with free chunks.  So either never apply this to free chunks
	 or guard with (self isFreeObject: foo) not.  So far the idiom has been to guard with isFreeObject:"
	<api>
	<inline: true>
	"self assert: (self isFreeObject: objOop) not."
	^(self longAt: objOop) noMask: self classIndexMask - self isForwardedObjectClassIndexPun
]

{ #category : #'class table' }
SpurMemoryManager >> isForwardedClassTag: classIndex [
	^classIndex = self isForwardedObjectClassIndexPun
]

{ #category : #'class table puns' }
SpurMemoryManager >> isForwardedObjectClassIndexPun [
	"Answer the class index of a forwarder.  We choose 8 so as not to
	 be confused with any immediate class (whose classIndex matches
	 its instances tag pattern), and because it is a power of two, which
	 allows us to generate a slightly slimmer test for isForwarded:."
	<api>
	<cmacro>
	^8
]

{ #category : #'object testing' }
SpurMemoryManager >> isFreeObject: objOop [
	^(self classIndexOf: objOop) = self isFreeObjectClassIndexPun
]

{ #category : #'class table puns' }
SpurMemoryManager >> isFreeObjectClassIndexPun [
	<cmacro>
	^0
]

{ #category : #'object testing' }
SpurMemoryManager >> isFreeOop: oop [
	^(self isNonImmediate: oop) and: [self isFreeObject: oop]
]

{ #category : #'header access' }
SpurMemoryManager >> isGrey: objOop [
	^((self longAt: objOop) >> self greyBitShift bitAnd: 1) ~= 0
]

{ #category : #'debug support' }
SpurMemoryManager >> isHiddenObj: objOop [
	^(self classIndexOf: objOop) <= self lastClassIndexPun
]

{ #category : #'object testing' }
SpurMemoryManager >> isImmediate: oop [
	<api>
	^oop anyMask: self tagMask
]

{ #category : #'object testing' }
SpurMemoryManager >> isImmediateCharacter: oop [
	^self subclassResponsibility
]

{ #category : #'interpreter access' }
SpurMemoryManager >> isImmediateFloat: oop [
	self subclassResponsibility
]

{ #category : #'header access' }
SpurMemoryManager >> isImmutable: objOop [
	^((self longAt: objOop) >> self immutableBitShift bitAnd: 1) ~= 0
]

{ #category : #'class table' }
SpurMemoryManager >> isInClassTable: objOop [
	| hash |
	hash := self rawHashBitsOf: objOop.
	^hash ~= 0
	 and: [(self classAtIndex: hash) = objOop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isInEden: objOop [
	^self
		oop: objOop
		isGreaterThanOrEqualTo: scavenger eden start
		andLessThan: freeStart
]

{ #category : #'object testing' }
SpurMemoryManager >> isInFutureSpace: address [
	^self
		oop: address
		isGreaterThanOrEqualTo: scavenger futureSpace start
		andLessThan: scavenger futureSurvivorStart
]

{ #category : #'plugin support' }
SpurMemoryManager >> isInMemory: address [ 
	"Answer if the given address is in ST object memory."
	(self isInNewSpace: address) ifTrue:
		[^(self isInEden: address)
			or: [(self isInPastSpace: address)
			or: [self scavengeInProgress and: [self isInFutureSpace: address]]]].
	^segmentManager isInSegments: address
]

{ #category : #'object testing' }
SpurMemoryManager >> isInNewSpace: objOop [
	^(self oop: objOop isLessThan: newSpaceLimit)
	  and: [self oop: objOop isGreaterThanOrEqualTo: newSpaceStart]
]

{ #category : #'object testing' }
SpurMemoryManager >> isInOldSpace: address [
	<api>
	^self
		oop: address
		isGreaterThanOrEqualTo: oldSpaceStart
		andLessThan: endOfMemory
]

{ #category : #'object testing' }
SpurMemoryManager >> isInPastSpace: address [
	^self
		oop: address
		isGreaterThanOrEqualTo: scavenger pastSpace start
		andLessThan: pastSpaceStart
]

{ #category : #immediates }
SpurMemoryManager >> isInRangeCharacterCode: characterCode [
	^characterCode between: 0 and: (1 << 30) - 1
]

{ #category : #'object testing' }
SpurMemoryManager >> isIndexable: objOop [
	| fmt |
	fmt := self formatOf: objOop.
	^self isIndexableFormat: fmt
]

{ #category : #'header formats' }
SpurMemoryManager >> isIndexableFormat: format [
	^format >= self arrayFormat
	  and: [format <= self weakArrayFormat
			or: [format >= self sixtyFourBitIndexableFormat]]
]

{ #category : #'interpreter access' }
SpurMemoryManager >> isInstanceOfClassLargeNegativeInteger: oop [
	"Answer if the oop is a large negative integer instance."
	^(self isNonImmediate: oop) and: [(self classIndexOf: oop) = ClassLargeNegativeIntegerCompactIndex]
]

{ #category : #'interpreter access' }
SpurMemoryManager >> isInstanceOfClassLargePositiveInteger: oop [
	"Answer if the oop is a large positive integer instance."
	^(self isNonImmediate: oop) and: [(self classIndexOf: oop) = ClassLargePositiveIntegerCompactIndex]
]

{ #category : #'object testing' }
SpurMemoryManager >> isIntegerObject: oop [
	^self subclassResponsibility
]

{ #category : #'interpreter access' }
SpurMemoryManager >> isIntegerValue: intValue [
	"Answer if the given value can be represented as a Smalltalk integer value."
	^self subclassResponsibility
]

{ #category : #'simulation only' }
SpurMemoryManager >> isKindOfInteger: oop [
	<doNotGenerate>
	^coInterpreter isKindOfInteger: oop
]

{ #category : #'free space' }
SpurMemoryManager >> isLargeFreeObject: objOop [
	^(self bytesInObject: objOop) >= (self numFreeLists * self allocationUnit)
]

{ #category : #'interpreter access' }
SpurMemoryManager >> isLargeIntegerInstance: oop [
	"Answer if the oop is a large positive or negative integer instance."
	^(self isNonImmediate: oop) and: [((self classIndexOf: oop) - ClassLargeNegativeIntegerCompactIndex) asUnsignedInteger <= 1]
]

{ #category : #'simulation only' }
SpurMemoryManager >> isLargeNegativeIntegerObject: oop [
	<doNotGenerate>
	^coInterpreter isLargeNegativeIntegerObject: oop
]

{ #category : #'simulation only' }
SpurMemoryManager >> isLargePositiveIntegerObject: oop [
	<doNotGenerate>
	^coInterpreter isLargePositiveIntegerObject: oop
]

{ #category : #'free space' }
SpurMemoryManager >> isLilliputianSize: chunkBytes [
	"Answer if chunkBytes (which includes an object header) is too small to hold both
	 a next free chunk and a previous free chunk pointer. This is always false in 32-bits, 
	but in 64 bits small chunk of size 2 are lilliputian."
	self subclassResponsibility
]

{ #category : #'object testing' }
SpurMemoryManager >> isLong64s: oop [
	"Answer if the argument contains only indexable 64-bit double words (no oops). See comment in formatOf:"

	^(self isNonImmediate: oop)
	  and: [self isLong64sNonImm: oop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isLong64sNonImm: objOop [
	"Answer if the argument contains only indexable 64-bit double words (no oops). See comment in formatOf:"

	^(self formatOf: objOop) = self sixtyFourBitIndexableFormat
]

{ #category : #'header access' }
SpurMemoryManager >> isMarked: objOop [
	<api>
	self subclassResponsibility
]

{ #category : #'object testing' }
SpurMemoryManager >> isMaybeFiredEphemeron: objOop [
	^self isMaybeFiredEphemeronFormat: (self formatOf: objOop)
]

{ #category : #'header formats' }
SpurMemoryManager >> isMaybeFiredEphemeronFormat: format [
	"Answer if an object's format could be that of an ephemeron.  When ephemerons are born
	 their format is ephemeronFormat, but when they fire their format is changed to 3 (inst vars
	 plus indexable fields) or 1 (objects with inst vars), we haven't decided which yet."
	^format <= self lastPointerFormat and: [format odd]
]

{ #category : #'object enumeration' }
SpurMemoryManager >> isMobileObject: objOop [
	"Answer if objOop should be moved during compaction.  Non-objects
	 (free chunks & bridges), forwarders and pinned objects are excluded."
	| classIndex |
	<inline: true>
	classIndex := self classIndexOf: objOop.
	self assert: ((self long64At: objOop) ~= 0
				  and: [classIndex < (numClassTablePages * self classTablePageSize)]).
	^classIndex > self isForwardedObjectClassIndexPun
	  and: [(self isPinned: objOop) not]
]

{ #category : #'object enumeration' }
SpurMemoryManager >> isMobileObjectHeader: objHeader [
	"Answer if an object with header objHeader should be moved during compaction.
	 Non-objects (free chunks & bridges), forwarders and pinned objects are excluded."
	<inline: true>
	^(objHeader >> self pinnedBitShift bitAnd: 1) = 0
	  and: [(self classIndexOfHeader: objHeader) > self isForwardedObjectClassIndexPun]
]

{ #category : #'object testing' }
SpurMemoryManager >> isNonImmediate: oop [
	<api>
	^oop noMask: self tagMask
]

{ #category : #'object testing' }
SpurMemoryManager >> isNonIntegerImmediate: oop [
	<inline: true>
	^self isImmediate: oop
]

{ #category : #'object testing' }
SpurMemoryManager >> isNonIntegerNonImmediate: oop [
	<inline: true>
	^self isNonImmediate: oop
]

{ #category : #'object testing' }
SpurMemoryManager >> isNonIntegerObject: oop [
	^self subclassResponsibility
]

{ #category : #'object enumeration' }
SpurMemoryManager >> isNormalObject: objOop [
	^(self classIndexOf: objOop) > self lastClassIndexPun
]

{ #category : #'object testing' }
SpurMemoryManager >> isObjEphemeron: objOop [
	^self isEphemeronFormat: (self formatOf: objOop)
]

{ #category : #'header access' }
SpurMemoryManager >> isObjImmutable: anOop [
	<inline: true>
	^self cppIf: IMMUTABILITY
		ifTrue: [self isImmutable: anOop]
		ifFalse: [false]
]

{ #category : #'object testing' }
SpurMemoryManager >> isOldObject: objOop [
	<api>
	"Answer if obj is old. Require that obj is non-immediate."
	self assert: (self isNonImmediate: objOop).
	^self oop: objOop isGreaterThanOrEqualTo: oldSpaceStart
]

{ #category : #'object testing' }
SpurMemoryManager >> isOopCompiledMethod: oop [ 
    "Answer whether the oop is an object of compiled method format"
	<api>
    ^(self isNonImmediate: oop)
	 and: [(self formatOf: oop) >= self firstCompiledMethodFormat]
]

{ #category : #'object testing' }
SpurMemoryManager >> isOopForwarded: oop [
	<api>
	^(self isNonImmediate: oop) and: [self isForwarded: oop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isOopImmutable: oop [
	<api>
	^(self isImmediate: oop)
	  or: [self isImmutable: oop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isOopMutable: oop [
	<api>
	^(self isNonImmediate: oop)
	  and: [(self isImmutable: oop) not]
]

{ #category : #'header access' }
SpurMemoryManager >> isPinned: objOop [
	<api>
	^((self longAt: objOop) >> self pinnedBitShift bitAnd: 1) ~= 0
]

{ #category : #'object testing' }
SpurMemoryManager >> isPointers: oop [
	"Answer if the argument has only fields that can hold oops. See comment in formatOf:"

	^(self isNonImmediate: oop) and: [self isPointersNonImm: oop]
]

{ #category : #'header formats' }
SpurMemoryManager >> isPointersFormat: format [
	^format <= self lastPointerFormat
]

{ #category : #'object testing' }
SpurMemoryManager >> isPointersNonImm: objOop [
	"Answer if the argument has only fields that can hold oops. See comment in formatOf:"
	^(self formatOf: objOop) <= self lastPointerFormat
]

{ #category : #'simulation only' }
SpurMemoryManager >> isPositiveMachineIntegerObject: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter isPositiveMachineIntegerObject: oop
]

{ #category : #'header formats' }
SpurMemoryManager >> isPureBitsFormat: format [
	"the inverse of isAnyPointerFormat:"
	^format >= self sixtyFourBitIndexableFormat
	  and: [format < self firstCompiledMethodFormat]
]

{ #category : #'object testing' }
SpurMemoryManager >> isPureBitsNonImm: objOop [
	"Answer if the argument contains only indexable words (no oops). See comment in formatOf:"

	^self isPureBitsFormat: (self formatOf: objOop)
]

{ #category : #'object testing' }
SpurMemoryManager >> isReallyYoung: oop [
	<api>
	"Answer if oop is young."
	^(self isNonImmediate: oop)
	 and: [self isReallyYoungObject: oop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isReallyYoungObject: obj [
	<api>
	"Answer if obj is young. This for compatibility with SqueakV3 where
	 the GC makes all objects young during full GC.  Spur doesn't do so."
	^self isYoungObject: obj
]

{ #category : #'header access' }
SpurMemoryManager >> isRemembered: objOop [
	^((self longAt: objOop) >> self rememberedBitShift bitAnd: 1) ~= 0
]

{ #category : #'object enumeration' }
SpurMemoryManager >> isRememberedObjectHeader: objHeader [
	"Answer if an object with header objHeader is remembered."
	<inline: true>
	^(objHeader >> self rememberedBitShift bitAnd: 1) ~= 0
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> isScavengeSurvivor: oop [
	<doNotGenerate>
	^scavenger isScavengeSurvivor: oop
]

{ #category : #segments }
SpurMemoryManager >> isSegmentBridge: objOop [
	"Maybe this should be in SpurSegmentManager only"
	^(self classIndexOf: objOop) = self segmentBridgePun
]

{ #category : #'object testing' }
SpurMemoryManager >> isSemaphoreObj: anObj [
	^(self classIndexOf: anObj) = (self rawHashBitsOf: (self splObj: ClassSemaphore))
]

{ #category : #'object testing' }
SpurMemoryManager >> isSemaphoreOop: anOop [
	^(self isNonImmediate: anOop)
	 and: [self isSemaphoreObj: anOop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isShorts: oop [
	"Answer if the argument contains only indexable 16-bit half words (no oops). See comment in formatOf:"

	^(self isNonImmediate: oop)
	  and: [self isShortsNonImm: oop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isShortsNonImm: objOop [
	"Answer if the argument contains only indexable 16-bit half words (no oops). See comment in formatOf:"

	^(self formatOf: objOop) between: self firstShortFormat and: self firstByteFormat - 1
]

{ #category : #'object testing' }
SpurMemoryManager >> isUnambiguouslyForwarder: objOop [
	"This version is private to SpurMemoryManager (for asserts, etc).  It does not
	 take advantage of the power-of0two optimization in isForwarded:."
	<api>
	^(self classIndexOf: objOop) = self isForwardedObjectClassIndexPun
]

{ #category : #'header access' }
SpurMemoryManager >> isUnmarked: objOop [
	"For debugging using printOopsSuchThat:"
	<api>
	^(self isMarked: objOop) not
]

{ #category : #'class table' }
SpurMemoryManager >> isValidClassIndex: classIndex [
	| classTablePage |
	classIndex <= 0 ifTrue:
		[^false].
	(classIndex <= self tagMask or: [classIndex >= self arrayClassIndexPun]) ifFalse:
		[^false].
	classIndex >= (1 << self classIndexFieldWidth) ifTrue:
		[^false].
	classTablePage := self fetchPointer: classIndex >> self classTableMajorIndexShift
							ofObject: hiddenRootsObj.
	classTablePage = nilObj ifTrue:
		[^false].
	(self addressCouldBeObj: classTablePage) ifFalse:
		[^false].
	^coInterpreter addressCouldBeClassObj:
		(self
			fetchPointer: (classIndex bitAnd: self classTableMinorIndexMask)
			ofObject: classTablePage)
]

{ #category : #'class table' }
SpurMemoryManager >> isValidClassTag: classIndex [
	<api>
	| classOrNil |
	self assert: (classIndex between: 0 and: 1 << self classIndexFieldWidth - 1).
	classOrNil := self classOrNilAtIndex: classIndex.
	^classOrNil ~= nilObj
	 and: [(self rawHashBitsOf: classOrNil) = classIndex]
]

{ #category : #'obj stacks' }
SpurMemoryManager >> isValidObjStack: objStack [
	"Answer if the obj stack at objStackRootIndex is valid."
	((self addressCouldBeObj: objStack)
	 and: [(self numSlotsOfAny: objStack) = ObjStackPageSlots]) ifFalse:
		[objStackInvalidBecause := 'first page not obj or wrong size'.
		 invalidObjStackPage := objStack.
		 ^false].
	^self isValidObjStackPage: objStack
		myIndex: (self fetchPointer: ObjStackMyx ofObject: objStack)
		firstPage: true
]

{ #category : #'obj stacks' }
SpurMemoryManager >> isValidObjStackAt: objStackRootIndex [
	"Answer if the obj stack at objStackRootIndex is valid."
	| stackOrNil |
	stackOrNil := self fetchPointer: objStackRootIndex ofObject: hiddenRootsObj.
	^stackOrNil = nilObj
	  or: [self isValidObjStackPage: stackOrNil myIndex: objStackRootIndex firstPage: true]
]

{ #category : #'obj stacks' }
SpurMemoryManager >> isValidObjStackPage: objStackPage [
	"for the Spur 32- to 64-bit bootstrap"
	<doNotGenerate>
	^self
		isValidObjStackPage: objStackPage
		myIndex: ((self numSlotsOfAny: objStackPage) = ObjStackPageSlots ifTrue:
					[self fetchPointer: ObjStackMyx ofObject: objStackPage])
]

{ #category : #'obj stacks' }
SpurMemoryManager >> isValidObjStackPage: objStackPage myIndex: myx [
	"Just check the page itself."
	<inline: false>
	(self classIndexOf: objStackPage) = self wordSizeClassIndexPun ifFalse:
		[objStackInvalidBecause := 'wrong class index'.
		 invalidObjStackPage := objStackPage.
		 ^false].
	(self formatOf: objStackPage) = self wordIndexableFormat ifFalse:
		[objStackInvalidBecause := 'wrong format'.
		 invalidObjStackPage := objStackPage.
		 ^false].
	(self numSlotsOfAny: objStackPage) = ObjStackPageSlots ifFalse:
		[objStackInvalidBecause := 'wrong num slots'.
		 invalidObjStackPage := objStackPage.
		 ^false].
	myx = (self fetchPointer: ObjStackMyx ofObject: objStackPage) ifFalse:
		[objStackInvalidBecause := 'wrong myx'.
		 invalidObjStackPage := objStackPage.
		 ^false].
	(marking and: [(self isMarked: objStackPage) not]) ifTrue:
		[objStackInvalidBecause := 'marking but page is unmarked'.
		 invalidObjStackPage := objStackPage.
		 ^false].
	^true
]

{ #category : #'obj stacks' }
SpurMemoryManager >> isValidObjStackPage: objStackPage myIndex: myx firstPage: isFirstPage [
	"Answer if the obj stack at stackRootIndex is valid."
	| page freeOrNextPage index |
	<inline: false>
	(self isValidObjStackPage: objStackPage myIndex: myx) ifFalse:
		[^false].
	freeOrNextPage := self fetchPointer: ObjStackFreex ofObject: objStackPage.
	[freeOrNextPage ~= 0] whileTrue:
		[isFirstPage ifFalse:
			[objStackInvalidBecause := 'free page on other than first page'.
			 invalidObjStackPage := objStackPage.
			 ^false].
		 freeOrNextPage = (self fetchPointer: ObjStackNextx ofObject: objStackPage) ifTrue:
			[objStackInvalidBecause := 'free page = next page'.
			 invalidObjStackPage := freeOrNextPage.
			^false].
		 (self isValidObjStackPage: freeOrNextPage myIndex: myx) ifFalse:
			[objStackInvalidBecause := self stretch: objStackInvalidBecause cat: ', on next page'.
			^false].
		 page := self fetchPointer: ObjStackFreex ofObject: freeOrNextPage.
		 (page = freeOrNextPage
		  or: [page = objStackPage]) ifTrue:
			[objStackInvalidBecause := 'circularity in free page list'.
			 invalidObjStackPage := page.
			^false].
		 freeOrNextPage := page].
	isFirstPage ifTrue:
		[(myx between: self classTableRootSlots and: self classTableRootSlots + self hiddenRootSlots - 1) ifFalse:
			[objStackInvalidBecause := 'myx out of range'.
			 invalidObjStackPage := objStackPage.
			 ^false].
		 (self fetchPointer: myx ofObject: hiddenRootsObj) = objStackPage ifFalse:
			[objStackInvalidBecause := 'firstPage is not root'.
			 invalidObjStackPage := objStackPage.
			 ^false]].
	index := self fetchPointer: ObjStackTopx ofObject: objStackPage.
	(index between: 0 and: ObjStackLimit) ifFalse:
		[objStackInvalidBecause := 'bad topx'.
		 invalidObjStackPage := objStackPage.
		 ^false].
	freeOrNextPage := self fetchPointer: ObjStackNextx ofObject: objStackPage.
	freeOrNextPage = 0 ifTrue:
		[^true].
	freeOrNextPage = objStackPage ifTrue:
		[objStackInvalidBecause := 'circularity in objStack page list'.
		 invalidObjStackPage := objStackPage.
		 ^false].
	^self isValidObjStackPage: freeOrNextPage myIndex: myx firstPage: false
]

{ #category : #'object testing' }
SpurMemoryManager >> isWeak: oop [
	"Answer if the argument has only weak fields that can hold oops. See comment in formatOf:"
	^(self isNonImmediate: oop) and: [self isWeakNonImm: oop]
]

{ #category : #'header formats' }
SpurMemoryManager >> isWeakFormat: format [
	<inline: true>
	^format = self weakArrayFormat
]

{ #category : #'object testing' }
SpurMemoryManager >> isWeakNonImm: objOop [
	<inline: true>
	^self isWeakFormat: (self formatOf: objOop)
]

{ #category : #'object testing' }
SpurMemoryManager >> isWords: oop [
	"Answer if the argument contains only indexable words (no oops). See comment in formatOf:"

	^(self isNonImmediate: oop)
	  and: [self isWordsNonImm: oop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isWordsNonImm: objOop [
	"Answer if the argument contains only indexable words (no oops). See comment in formatOf:"

	^self subclassResponsibility
]

{ #category : #'object testing' }
SpurMemoryManager >> isWordsOrBytes: oop [
	"Answer if the contains only indexable words or bytes (no oops). See comment in formatOf:"
	"Note: Excludes CompiledMethods."
	^(self isNonImmediate: oop)
	  and: [self isWordsOrBytesNonImm: oop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isWordsOrBytesNonImm: objOop [
	"Answer if the contains only indexable words or bytes (no oops). See comment in formatOf:"
	"Note: Excludes CompiledMethods."
	^self isPureBitsFormat: (self formatOf: objOop)
]

{ #category : #'object testing' }
SpurMemoryManager >> isYoung: oop [
	<api>
	"Answer if oop is young."
	^(self isNonImmediate: oop)
	 and: [self oop: oop isLessThan: newSpaceLimit]
]

{ #category : #'object testing' }
SpurMemoryManager >> isYoungObject: objOop [
	<api>
	"Answer if obj is young. Require that obj is non-immediate."
	self assert: (self isNonImmediate: objOop).
	^self oop: objOop isLessThan: newSpaceLimit
]

{ #category : #'object access' }
SpurMemoryManager >> keyOfEphemeron: objOop [
	"Answer the object the ephemeron guards.  This is its first element."
	self assert: ((self isNonImmediate: objOop) and: [self isObjEphemeron: objOop]).
	^self fetchPointer: 0 ofObject: objOop
]

{ #category : #'object access' }
SpurMemoryManager >> keyOfMaybeFiredEphemeron: objOop [
	"Answer the object the ephemeron guards.  This is its first element."
	self assert: ((self isNonImmediate: objOop) and: [self isMaybeFiredEphemeron: objOop]).
	^self fetchPointer: 0 ofObject: objOop
]

{ #category : #'class table' }
SpurMemoryManager >> knownClassAtIndex: classIndex [
	self assert: (classIndex between: 1 and: self classTablePageSize).
	^self fetchPointer: classIndex ofObject: classTableFirstPage
]

{ #category : #'compaction - analysis' }
SpurMemoryManager >> largeFreeChunkDistribution [
	"This method answers a sorted collection of the free chunks >= 1,000,000 bytes long,
	 sandwiched between nilObj and the end of memory (ignoring the large chunk often found at the end of the heap)."
	<doNotGenerate>
	| freeChunks |
	freeChunks := SortedCollection new.
	self allObjectsInFreeTreeDo:
		[:f|
		((self addressAfter: f) < endOfMemory
		 and: [(self bytesInObject: f) >= 1000000]) ifTrue:
			[freeChunks add: f]].
	^{{nilObj hex. #nil}}, (freeChunks collect: [:f| {f hex. self bytesInObject: f}]), {{endOfMemory hex. #endOfMemory}}
]

{ #category : #allocation }
SpurMemoryManager >> largeObjectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object with an overflow header, including header bytes."
	<returnTypeC: #usqInt>
	^self subclassResponsibility
]

{ #category : #'class table puns' }
SpurMemoryManager >> lastClassIndexPun [
	"Class puns are class indices not used by any class.  There is an entry
	 for the pun that refers to the notional class of objects with this class
	 index.  But because the index doesn't match the class it won't show up
	 in allInstances, hence hiding the object with a pun as its class index.
	 The puns occupy indices 16 through 31."
	<cmacro>
	^31
]

{ #category : #accessing }
SpurMemoryManager >> lastHash [
	^lastHash
]

{ #category : #accessing }
SpurMemoryManager >> lastHash: seed [
	lastHash := seed
]

{ #category : #'header formats' }
SpurMemoryManager >> lastPointerFormat [
	^5
]

{ #category : #'object enumeration' }
SpurMemoryManager >> lastPointerOf: objOop [ 
	"Answer the byte offset of the last pointer field of the given object.
	 Works with CompiledMethods, as well as ordinary objects."
	<api>
	<inline: true>
	| fmt contextSize header |
	fmt := self formatOf: objOop.
	self assert: fmt ~= self forwardedFormat.
	fmt <= self lastPointerFormat ifTrue:
		[(fmt = self indexablePointersFormat
		  and: [self isContextNonImm: objOop]) ifTrue:
			["contexts end at the stack pointer"
			contextSize := coInterpreter fetchStackPointerOf: objOop.
			^CtxtTempFrameStart - 1 + contextSize * self bytesPerOop + self baseHeaderSize].
		^(self numSlotsOf: objOop) - 1 * self bytesPerOop + self baseHeaderSize  "all pointers"].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	header := self methodHeaderOf: objOop.
	^self lastPointerOfMethodHeader: header
]

{ #category : #'object enumeration' }
SpurMemoryManager >> lastPointerOfArray: objOop [ 
	"Answer the byte offset of the last pointer field of the given array."
	self assert: (self isArray: objOop).
	^(self numSlotsOf: objOop) - 1 * self bytesPerOop + self baseHeaderSize
]

{ #category : #'object enumeration' }
SpurMemoryManager >> lastPointerOfMethodHeader: methodHeader [ 
	"Answer the byte offset of the last pointer field of a
	 CompiledMethod with the given header."
	<inline: true>
	^(self literalCountOfMethodHeader: methodHeader)
	  + LiteralStart - 1 * self bytesPerOop + self baseHeaderSize
]

{ #category : #snapshot }
SpurMemoryManager >> lastPointerOfWhileSwizzling: objOop [ 
	"Answer the byte offset of the last pointer field of the given object.
	 Works with CompiledMethods, as well as ordinary objects.
	 Does not examine the stack pointer of contexts to be sure to swizzle
	 the nils that fill contexts on snapshot.
	 It is invariant that on image load no object contains a forwarding pointer,
	 and the image contains no forwarders (see class comment)."
	<api>
	<inline: true>
	| fmt header |
	fmt := self formatOf: objOop.
	self assert: fmt ~= self forwardedFormat.
	fmt <= self lastPointerFormat ifTrue:
		[^(self numSlotsOf: objOop) - 1 * self bytesPerOop + self baseHeaderSize  "all pointers"].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	header := self methodHeaderOf: objOop.
	^self lastPointerOfMethodHeader: header
]

{ #category : #'debug support' }
SpurMemoryManager >> leakCheckBecome [
	<api>
	^(checkForLeaks bitAnd: GCModeBecome) ~= 0
]

{ #category : #'debug support' }
SpurMemoryManager >> leakCheckFullGC [
	<api>
	^(checkForLeaks bitAnd: GCModeFull) ~= 0
]

{ #category : #'debug support' }
SpurMemoryManager >> leakCheckImageSegments [
	^(checkForLeaks bitAnd: GCModeImageSegment) ~= 0
]

{ #category : #'debug support' }
SpurMemoryManager >> leakCheckIncremental [
	<api>
	^(checkForLeaks bitAnd: GCModeIncremental) ~= 0
]

{ #category : #'debug support' }
SpurMemoryManager >> leakCheckNewSpaceGC [
	<api>
	^(checkForLeaks bitAnd: GCModeNewSpace) ~= 0
]

{ #category : #'object access' }
SpurMemoryManager >> lengthOf: objOop [
	"Answer the number of indexable units in the given object.
	 For a CompiledMethod, the size of the method header (in bytes) should
	 be subtracted from the result."

	<api>
	<inline: true>
	^self lengthOf: objOop format: (self formatOf: objOop)
]

{ #category : #'object access' }
SpurMemoryManager >> lengthOf: objOop baseHeader: header format: fmt [ 
	<var: #header type: #usqLong>
	"Compatibility; does not really suit the Spur format.
	 Answer the number of indexable bytes or words in the given object.
	 For a CompiledMethod, the size of the method header (in bytes) should
	 be subtracted from the result of this method."
	^self lengthOf: objOop format: fmt
]

{ #category : #'object access' }
SpurMemoryManager >> lengthOf: objOop format: fmt [
	"Answer the number of indexable units in the given object.
	 For a CompiledMethod, the size of the method header (in bytes)
	 should be subtracted from the result of this method."
	^self subclassResponsibility
]

{ #category : #'debug support' }
SpurMemoryManager >> lengthOfMaybeImmediate: oop [
	"for the message send breakpoint; selectors can be immediates."
	<inline: false>
	(self isImmediate: oop) ifTrue: [^0].
	^self lengthOf: oop
]

{ #category : #'free space' }
SpurMemoryManager >> lilliputianChunkIndex [
	"See isLilliputianSize:"
	^(self baseHeaderSize + self allocationUnit) // self allocationUnit

]

{ #category : #'method access' }
SpurMemoryManager >> literalCountOf: methodPointer [
	<api>
	^self literalCountOfMethodHeader: (self methodHeaderOf: methodPointer)
]

{ #category : #'method access' }
SpurMemoryManager >> literalCountOfMethodHeader: header [
	<api>
	<inline: true>
	self assert: (self isIntegerObject: header).
	^coInterpreter literalCountOfAlternateHeader: header
]

{ #category : #'interpreter access' }
SpurMemoryManager >> loadFloatOrIntFrom: floatOrInt [
	"If floatOrInt is an integer, then convert it to a C double float and return it.
	 If it is a Float, then load its value and return it.
	 Otherwise fail -- ie return with primErrorCode non-zero."

	self subclassResponsibility
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> loadImageSegmentFrom: segmentWordArray outPointers: outPointerArray [
	"This primitive is called from Smalltalk as...
		<imageSegment> loadSegmentFrom: aWordArray outPointers: anArray."

	"This primitive will load a binary image segment created by primitiveStoreImageSegment.
	 It expects the outPointer array to be of the proper size, and the wordArray to be well formed.
	 It will return as its value the original array of roots, and the segmentWordArray will become an
	 array of the loaded objects.  If this primitive should fail, the segmentWordArray will, sadly, have
	 been reduced to an unrecognizable and unusable jumble.  But what more could you have done
	 with it anyway?

	 The primitive, if it succeeds, also becomes the segmentWordArray into the array of loaded objects.
	 This allows fixing up of loaded objects directly, without nextObject, which Spur doesn't support."

	<inline: #never>
	| segmentLimit segmentStart segVersion errorCode numLoadedObjects loadedObjectsArray |

	segmentLimit := self numSlotsOf: segmentWordArray.
	(self objectBytesForSlots: segmentLimit) < (self allocationUnit "version info" + self baseHeaderSize "one object header") ifTrue:
		[^PrimErrBadArgument halt].

	"Verify format.  If the format is wrong, word-swap (since ImageSegment data are 32-bit longs).
	 If it is still wrong, undo the damage and fail."
	segVersion := self longAt: segmentWordArray + self baseHeaderSize.
	(coInterpreter readableFormat: (segVersion bitAnd: 16rFFFFFF "low 3 bytes")) ifFalse:
		[self reverseBytesIn32BitWordsIn: segmentWordArray.
		 segVersion := self longAt: segmentWordArray + self baseHeaderSize.
		 (coInterpreter readableFormat: (segVersion bitAnd: 16rFFFFFF "low 3 bytes")) ifFalse:
			[self reverseBytesIn32BitWordsIn: segmentWordArray.
			 ^PrimErrBadArgument halt]].

	segmentStart := segmentWordArray + self baseHeaderSize + self allocationUnit.
	segmentLimit := segmentLimit * self bytesPerOop + segmentWordArray + self baseHeaderSize.

	"Notionally reverse the Byte type objects if the data is from opposite endian machine.
	 Test top byte.  $d on the Mac or $s on the PC.  Rest of word is equal.  If Spur is ever
	 ported to big-endian machines then the segment may have to be byte/word swapped,
	 but so far it only runs on little-endian machines, so for now just fail if endianness is wrong."
	self flag: #endianness.
	(segVersion >> 24 bitAnd: 16rFF) ~= (self imageSegmentVersion >> 24 bitAnd: 16rFF) ifTrue:
		"Reverse the byte-type objects once"
		[true
			ifTrue: [^PrimErrBadArgument halt]
			ifFalse:
				[self byteSwapByteObjectsFrom: (self objectStartingAt: segmentStart)
					to: segmentLimit
					flipFloatsIf: false]].

	"Avoid having to remember by arranging that there are no young outPointers if segment is in old space."
	(self isOldObject: segmentWordArray) ifTrue:
		[errorCode := self ensureNoNewObjectsIn: outPointerArray.
		 errorCode ~= 0 ifTrue:
			[^errorCode]].

	"scan through mapping oops and validating class references. Defer entering any
	 class objects into the class table and/or pinning objects until a second pass."
	errorCode := self mapOopsAndValidateClassRefsFrom: segmentStart to: segmentLimit outPointers: outPointerArray.
	errorCode > 0 ifTrue:
		[^errorCode].
	numLoadedObjects := errorCode negated.
	loadedObjectsArray := self allocateSlots: numLoadedObjects format: self arrayFormat classIndex: ClassArrayCompactIndex.
	loadedObjectsArray ifNil:
		[^PrimErrNoMemory halt].

	"Scan for classes contained in the segment, entering them into the class table.
	 Classes are at the front, after the root array and have the remembered bit set."
	errorCode := self enterClassesIntoClassTableFrom: segmentStart to: segmentLimit.
	errorCode ~= 0 ifTrue:
		[^errorCode].

	"Make a final pass, assigning class indices and/or pinning pinned objects and collecting the loaded objects in loadedObjectsArray"
	self assignClassIndicesAndPinFrom: segmentStart to: segmentLimit outPointers: outPointerArray filling: loadedObjectsArray.

	"Evaporate the container, leaving the newly loaded objects in place."
	(self hasOverflowHeader: segmentWordArray)
		ifTrue: [self rawOverflowSlotsOf: segmentWordArray put: self allocationUnit / self bytesPerOop]
		ifFalse: [self rawNumSlotsOf: segmentWordArray put: self allocationUnit / self bytesPerOop].

	"Finally forward the segmentWordArray to the loadedObjectsArray"
	self forward: segmentWordArray to: loadedObjectsArray.
	
	self runLeakCheckerFor: GCModeImageSegment.

	^self objectStartingAt: segmentStart
]

{ #category : #'header format' }
SpurMemoryManager >> logBytesPerOop [
	self subclassResponsibility
]

{ #category : #'debug printing' }
SpurMemoryManager >> longPrintInstancesOf: aClassOop [
	"Scan the heap printing the oops of any and all objects that are instances of aClassOop"
	<api>
	| classIndex |
	classIndex := self rawHashBitsOf: aClassOop.
	classIndex ~= self isFreeObjectClassIndexPun ifTrue:
		[self longPrintInstancesWithClassIndex: classIndex]
]

{ #category : #'debug printing' }
SpurMemoryManager >> longPrintInstancesWithClassIndex: classIndex [
	"Scan the heap printing any and all objects whose classIndex equals the argument."
	<api>
	<inline: false>
	self allHeapEntitiesDo:
		[:obj|
		 (self classIndexOf: obj) = classIndex ifTrue:
			[coInterpreter longPrintOop: obj; cr]]
]

{ #category : #'debug printing' }
SpurMemoryManager >> longPrintReferencesTo: anOop [
	"Scan the heap long printing the oops of any and all objects that refer to anOop"
	| prntObj |
	<api>
	prntObj := false.
	self allObjectsDo:
		[:obj| | i |
		((self isPointersNonImm: obj) or: [self isCompiledMethod: obj]) ifTrue:
			[(self isCompiledMethod: obj)
				ifTrue:
					[i := (self literalCountOf: obj) + LiteralStart]
				ifFalse:
					[(self isContextNonImm: obj)
						ifTrue: [i := CtxtTempFrameStart + (coInterpreter fetchStackPointerOf: obj)]
						ifFalse: [i := self numSlotsOf: obj]].
			[(i := i - 1) >= 0] whileTrue:
				[anOop = (self fetchPointer: i ofObject: obj) ifTrue:
					[coInterpreter printHex: obj; print: ' @ '; printNum: i; cr.
					 prntObj := true.
					 i := 0]].
			prntObj ifTrue:
				[prntObj := false.
				 coInterpreter longPrintOop: obj]]]
]

{ #category : #'simulation only' }
SpurMemoryManager >> lookupAddress: address [
	"If address appears to be that of a Symbol or a few well-known objects (such as classes) answer it, otherwise answer nil.
	 For code disassembly"
	<doNotGenerate>
	| fmt size string class classSize maybeThisClass classNameIndex thisClassIndex |
	((self addressCouldBeObj: address)
	 and: [(thisClassIndex := self classIndexOf: address) > 0]) ifFalse:
		[^address = scavengeThreshold ifTrue:
			['scavengeThreshold']].
	address - self baseHeaderSize = hiddenRootsObj ifTrue:
		[^'(hiddenRootsObj+baseHeaderSize)'].
	fmt := self formatOf: address.
	size := self lengthOf: address baseHeader: (self baseHeader: address) format: fmt.
	size = 0 ifTrue:
		[^address caseOf: { [nilObj] -> ['nil']. [trueObj] -> ['true']. [falseObj] -> ['false'] } otherwise: []].
	((fmt between: self firstByteFormat and: self firstCompiledMethodFormat - 1) "indexable byte fields"
	and: [(size between: 1 and: 64)
	and: [(Scanner isLiteralSymbol: (string := (0 to: size - 1) collect: [:i| Character value: (self fetchByte: i ofObject: address)]))
		or: [NewspeakVM and: [string noneSatisfy: [:c| c isSeparator or: [c asInteger > 126]]]]]]) ifTrue:
		[^'#', (ByteString withAll: string)].
	class := self noCheckClassAtIndex: thisClassIndex.
	(class isNil or: [class = nilObj]) ifTrue:
		[^nil].
	"address is either a class or a metaclass, or an instance of a class or invalid.  determine which."
	classNameIndex := coInterpreter classNameIndex.
	thisClassIndex := coInterpreter thisClassIndex.
	((classSize := self numSlotsOf: class) <= (classNameIndex max: thisClassIndex)
	 or: [classSize > 255]) ifTrue:
		[^nil].
	"Address could be a class or a metaclass"
	(fmt = 1 and: [size > classNameIndex]) ifTrue:
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
		[:maybeClassName|
		(size = 2
		 and: [fmt = self nonIndexablePointerFormat
		 and: ['#ClassBinding' = maybeClassName]]) ifTrue:
			[^'a ClassBinding '
				, ((self lookupAddress: (self fetchPointer: KeyIndex ofObject: address)) ifNil: [''])
				, ((self lookupAddress: (self fetchPointer: ValueIndex ofObject: address)) ifNil: [''] ifNotNil: [:val| ' -> ', val])].
		'a(n) ', maybeClassName allButFirst]
]

{ #category : #'free space' }
SpurMemoryManager >> lowSpaceThreshold: threshold [
	lowSpaceThreshold := threshold.
	"N.B. The threshold > 0 guard eliminates a warning when
		self lowSpaceThreshold: 0
	 is inlined into setSignalLowSpaceFlagAndSaveProcess"
	(threshold > 0
	 and: [totalFreeOldSpace < threshold]) ifTrue:
		[self growOldSpaceByAtLeast: threshold - totalFreeOldSpace].
	self assert: totalFreeOldSpace >= lowSpaceThreshold
]

{ #category : #'gc - global' }
SpurMemoryManager >> mapExtraRoots [
	(self shouldRemapObj: specialObjectsOop) ifTrue:
		[specialObjectsOop := self remapObj: specialObjectsOop].
	self assert: remapBufferCount = 0.
	"1 to: remapBufferCount do:
		[:i | | oop |
		oop := remapBufferCount at: i.
		((self isImmediate: oop) or: [self isFreeObject: oop]) ifFalse:
			[(self shouldRemapObj: oop) ifTrue:
				[remapBuffer at: i put: (self remapObj: oop)]]]."
	1 to: extraRootCount do:
		[:i | | oop |
		oop := (extraRoots at: i) at: 0.
		((self isImmediate: oop) or: [self isFreeObject: oop]) ifFalse:
			[(self shouldRemapObj: oop) ifTrue:
				[(extraRoots at: i) at: 0 put: (self remapObj: oop)]]]
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> mapMournQueue [
	<inline: #never>
	self objStack: mournQueue do:
		[:i :page| | mourner |
		mourner := self fetchPointer: i ofObject: page.
		(self isNonImmediate: mourner) ifTrue: "someone could try and become weaklings into immediates..."
			[(self isForwarded: mourner) ifTrue:
				[mourner := self followForwarded: mourner].
			 (scavenger isScavengeSurvivor: mourner) ifFalse:
				[mourner := scavenger copyAndForwardMourner: mourner].
			 "we could check for change but writes are cheasp with write buffers..."
			 self storePointerUnchecked: i ofObject: page withValue: mourner]]
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> mapOopsAndValidateClassRefsFrom: segmentStart to: segmentLimit outPointers: outPointerArray [
	"This is part of loadImageSegmentFrom:outPointers:.
	 Scan through mapping oops and validating class references.  Defer
	 entering any class objects into the class table and/or pinning objects
	 until the second pass in assignClassIndicesAndPinFrom:to:outPointers:."
	<var: 'segmentLimit' type: #usqInt>
	| numOutPointers numSegObjs objOop |
	<var: #oop type: #usqInt>
	numOutPointers := self numSlotsOf: outPointerArray.
	numSegObjs := 0.
	objOop := self objectStartingAt: segmentStart.
	[self oop: objOop isLessThan: segmentLimit] whileTrue:
		[| classIndex hash oop mappedOop |
		 numSegObjs := numSegObjs + 1.
		 "No object in the segment should be marked.  If is is something is wrong."
		 (self isMarked: objOop) ifTrue:
			[^PrimErrInappropriate halt].
		 classIndex := self classIndexOf: objOop.
		 "validate the class ref, but don't update it until any internal classes have been added to the class table."
		 (classIndex anyMask: TopHashBit)
			ifTrue:
				[classIndex := classIndex - TopHashBit.
				 classIndex >= numOutPointers ifTrue:
					[^PrimErrBadIndex halt].
				 mappedOop := self fetchPointer: classIndex ofObject: outPointerArray.
				 hash := self rawHashBitsOf: mappedOop.
				 (hash = 0 "class has yet to be instantiated"
				  or: [hash > self lastClassIndexPun and: [(self classOrNilAtIndex: hash) = mappedOop]]) ifFalse:
					[^PrimErrInappropriate halt]]
			ifFalse: "The class is contained within the segment."
				[(oop := classIndex - self firstClassIndexPun * self allocationUnit + segmentStart) >= segmentLimit ifTrue:
					[^PrimErrBadIndex halt].
				 (self rawHashBitsOf: oop) ~= 0 ifTrue:
					[^PrimErrInappropriate halt]].
		 0 to: (self numPointerSlotsOf: objOop) - 1 do:
			[:i|
			 oop := self fetchPointer: i ofObject: objOop.
			 (self isNonImmediate: oop) ifTrue:
				[(oop anyMask: TopOopBit)
					ifTrue:
						[(oop := oop - TopOopBit / self bytesPerOop) >= numOutPointers ifTrue:
							[^PrimErrBadIndex halt].
						 mappedOop := self fetchPointer: oop ofObject: outPointerArray]
					ifFalse:
						[(oop bitAnd: self allocationUnit - 1) ~= 0 ifTrue:
							[^PrimErrInappropriate halt].
						 (mappedOop := oop + segmentStart) >= segmentLimit ifTrue:
							[^PrimErrBadIndex halt]].
				 self storePointerUnchecked: i ofObject: objOop withValue: mappedOop]].
		 objOop := self objectAfter: objOop limit: segmentLimit].
	^numSegObjs negated
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> mapOopsFrom: segStart to: segAddr outPointers: outPointerArray outHashes: savedOutHashes [
	"This is part of storeImageSegmentInto:outPointers:roots:.
	 Now scan, adding out pointers to the outPointersArray; all objects in arrayOfObjects
	 have had their first fields set to point to their copies in segmentWordArray.  Answer
	 the outIndex if the scan succeded.  Fail if outPointers is too small and answer -1.

	 As established by copyObj:toAddr:startAt:stopAt:savedFirstFields:index:,
	 the marked bit is set for all objects in the segment
	 the remembered bit is set for all classes in the segment.

	 Class indices should be set as follows (see assignClassIndicesAndPinFrom:to:outPointers:filling:)
	 - class indices for classes in the segment "
	| objOop objIndex outIndex |
	outIndex := objIndex := 0. "objIndex is for debugging; it mirrors indices in the sender's arrayOfObjects."
	self fillObj: outPointerArray numSlots: (self numSlotsOf: outPointerArray) with: nilObj.
	objOop := self objectStartingAt: segStart.
	[self oop: objOop isLessThan: segAddr] whileTrue:
		[| heapOop oop hash segIndex |
		 heapOop := self fetchClassOfNonImm: objOop.
		 "Set the classIndex of the instance.  This is a segment offset (segAddr - segStart / allocationUnit) for instances of
		  classes within the segment, and an outPointer index (index in outPointers + TopHashBit) for classes outside the segment."
		 (self isCopiedIntoSegment: heapOop)
			ifTrue: "oop is a class in the segment; storeImageSegmentInto:outPointers:roots: established offset is within range."
				[oop := self fetchPointer: 0 ofObject: heapOop.
				 self assert: (self oop: oop isGreaterThanOrEqualTo: segStart andLessThan: segAddr).
				 segIndex := oop - segStart / self allocationUnit + self firstClassIndexPun.
				 (segIndex anyMask: TopHashBit) ifTrue: "Too many classes in the segment"
					[^-1 halt]]
			ifFalse: "oop is an outPointer; locate or allocate its oop"
				[hash := self rawHashBitsOf: heapOop.
				 (self is: hash outPointerClassHashFor: heapOop in: outPointerArray limit: outIndex)
					ifTrue: [segIndex := hash]
					ifFalse: "oop is a new outPointer; allocate its oop"
						[outIndex := self newOutPointer: heapOop at: outIndex in: outPointerArray hashes: savedOutHashes.
						 outIndex = 0 ifTrue: "no room in outPointers; fail"
							[^-1 halt].
						 segIndex := self rawHashBitsOf: heapOop].
				 self assert: (segIndex anyMask: TopHashBit)].
		 self setClassIndexOf: objOop to: segIndex.
		 0 to: (self numPointerSlotsOf: objOop) - 1 do:
			[:i|
			 heapOop := self fetchPointer: i ofObject: objOop.
			 (self isNonImmediate: heapOop) ifTrue:
				[(self isCopiedIntoSegment: heapOop)
					ifTrue: "oop is an object in the segment."
						[oop := self fetchPointer: 0 ofObject: heapOop.
						 self assert: (self oop: oop isGreaterThanOrEqualTo: segStart andLessThan: segAddr).
						 oop := oop - segStart]
					ifFalse: "oop is an outPointer; locate or allocate its oop"
						[hash := self rawHashBitsOf: heapOop.
						(self is: hash outPointerClassHashFor: heapOop in: outPointerArray limit: outIndex)
							ifTrue: [oop := hash - TopHashBit * self bytesPerOop + TopOopBit]
							ifFalse: "oop is a new outPointer; allocate its oop"
								[outIndex := self newOutPointer: heapOop at: outIndex in: outPointerArray hashes: savedOutHashes.
								 outIndex = 0 ifTrue: "no room in outPointers; fail"
									[^-1 halt].
								 self assert: ((self rawHashBitsOf: heapOop) anyMask: TopHashBit).
								 oop := (self rawHashBitsOf: heapOop) - TopHashBit * self bytesPerOop + TopOopBit]].
				 self storePointerUnchecked: i ofObject: objOop withValue: oop]].
		 objOop := self objectAfter: objOop limit: segAddr.
		 objIndex := objIndex + 1].
	^outIndex
]

{ #category : #'primitive support' }
SpurMemoryManager >> mark: objOop [
	<inline: true>
	self setIsMarkedOf: objOop to: true
]

{ #category : #'gc - global' }
SpurMemoryManager >> markAccessibleObjectsAndFireEphemerons [
	self assert: marking.
	self assert: self validClassTableRootPages.
	self assert: segmentManager allBridgesMarked.
	self cCode: [] "for debugging markAndTrace: set (MarkStackRecord := OrderedCollection new)"
		inSmalltalk: [MarkStackRecord ifNotNil: [MarkStackRecord resetTo: 1]].

	"This must come first to enable stack page reclamation.  It clears
	  the trace flags on stack pages and so must precede any marking.
	  Otherwise it will clear the trace flags of reached pages."
	coInterpreter initStackPageGC.
	self markAndTraceHiddenRoots.
	self markAndTraceExtraRoots.
	self assert: self validClassTableRootPages.
	coInterpreter markAndTraceInterpreterOops: true.
	self assert: self validObjStacks.
	self markWeaklingsAndMarkAndFireEphemerons.
	self assert: self validObjStacks
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> markAllUnscannedEphemerons [
	"After firing the unscanned ephemerons we must scan-mark them.
	 The wrinkle is that doing so may add more ephemerons to the set.
	 So we remove the first element, by overwriting it with the last element,
	 and decrementing the top, and then markAndTrace its contents."
	self assert: (self noUnscannedEphemerons) not.
	self assert: self allUnscannedEphemeronsAreActive.
	[unscannedEphemerons top > unscannedEphemerons start] whileTrue:
		[| ephemeron key lastptr |
		 ephemeron := self longAt: unscannedEphemerons start.
		 lastptr := unscannedEphemerons top - self bytesPerOop.
		 lastptr > unscannedEphemerons start ifTrue:
			[self longAt: unscannedEphemerons start put: (self longAt: lastptr)].
		 unscannedEphemerons top: lastptr.
		 key := self followedKeyOfMaybeFiredEphemeron: ephemeron.
		 self setIsMarkedOf: ephemeron to: false. "to get it to be fully scanned in markAndTrace:"
		 self
			markAndTrace: key;
			markAndTrace: ephemeron]
]

{ #category : #'gc - global' }
SpurMemoryManager >> markAndShouldScan: objOop [
	"Helper for markAndTrace:.
	 Mark the argument, and answer if its fields should be scanned now.
	 Immediate objects don't need to be marked.
	 Already marked objects have already been processed.
	 Pure bits objects don't need scanning, although their class does.
	 Weak objects should be pushed on the weakling stack.
	 Anything else need scanning."
	| format |
	<inline: true>
	(self isImmediate: objOop) ifTrue:
		[^false].
	"if markAndTrace: is to follow and eliminate forwarding pointers
	 in its scan it cannot be handed an r-value which is forwarded."
	self assert: (self isForwarded: objOop) not.
	(self isMarked: objOop) ifTrue:
		[^false].
	self setIsMarkedOf: objOop to: true.
	format := self formatOf: objOop.
	(self isPureBitsFormat: format) ifTrue: "avoid pushing non-pointer objects on the markStack."
		["Avoid tracing classes of non-objects on the heap, e.g. IRC caches, Sista counters."
		 (self classIndexOf: objOop) > self lastClassIndexPun ifTrue:
			[self markAndTraceClassOf: objOop].
		 ^false].
	format = self weakArrayFormat ifTrue: "push weaklings on the weakling stack to scan later"
		[self push: objOop onObjStack: weaklingStack.
		 ^false].
	(format = self ephemeronFormat
	 and: [self activeAndDeferredScan: objOop]) ifTrue:
		[^false].
	^true
]

{ #category : #'gc - global' }
SpurMemoryManager >> markAndTrace: objOop [
	"Mark the argument, and all objects reachable from it, and any remaining objects
	 on the mark stack. Follow forwarding pointers in the scan."
	<api>
	<inline: #never>
	"if markAndTrace: is to follow and eliminate forwarding pointers
	 in its scan it cannot be handed an r-value which is forwarded.
	 The assert for this is in markAndShouldScan:"
	(self markAndShouldScan: objOop) ifFalse:
		[^self].

	"Now scan the object, and any remaining objects on the mark stack."
	self markLoopFrom: objOop
]

{ #category : #'gc - global' }
SpurMemoryManager >> markAndTraceClassOf: objOop [
	"Ensure the class of the argument is marked, pushing it on the markStack if not already marked.
	 And for one-way become, which can create duplicate entries in the class table, make sure
	 objOop's classIndex refers to the classObj's actual classIndex.
	 Note that this is recursive, but the metaclass chain should terminate quickly."
	<inline: false>
	| classIndex classObj realClassIndex |
	classIndex := self classIndexOf: objOop.
	classObj := self classOrNilAtIndex: classIndex.
	self assert: (coInterpreter objCouldBeClassObj: classObj).
	realClassIndex := self rawHashBitsOf: classObj.
	(classIndex ~= realClassIndex
	 and: [classIndex > self lastClassIndexPun]) ifTrue:
		[self setClassIndexOf: objOop to: realClassIndex].
	(self isMarked: classObj) ifFalse:
		[self setIsMarkedOf: classObj to: true.
		 self markAndTraceClassOf: classObj.
		 self push: classObj onObjStack: markStack]
]

{ #category : #'gc - global' }
SpurMemoryManager >> markAndTraceExtraRoots [
	| oop |
	self assert: remapBufferCount = 0.
	"1 to: remapBufferCount do:
		[:i|
		 oop := remapBuffer at: i.
		 ((self isImmediate: oop) or: [self isFreeObject: oop]) ifFalse:
			[self markAndTrace: oop]]."
	1 to: extraRootCount do:
		[:i|
		oop := (extraRoots at: i) at: 0.
		((self isImmediate: oop) or: [self isFreeObject: oop]) ifFalse:
			[self markAndTrace: oop]]
]

{ #category : #'gc - global' }
SpurMemoryManager >> markAndTraceHiddenRoots [
	"The hidden roots hold both the class table pages and the obj stacks,
	 and hence need special treatment.  The obj stacks must be marked
	 specially; their pages must be marked, but only the contents of the
	 mournQueue should be marked.

	 If a class table page is weak we can mark and trace the hiddenRoots,
	 which will not trace through class table pages because they are weak.
	 But if class table pages are strong, we must mark the pages and *not*
	 trace them so that only classes reachable from the true roots will be
	 marked, and unreachable classes will be left unmarked."

	self markAndTraceObjStack: markStack andContents: false.
	self markAndTraceObjStack: weaklingStack andContents: false.
	self markAndTraceObjStack: mournQueue andContents: true.

	self setIsMarkedOf: self rememberedSetObj to: true.
	self setIsMarkedOf: self freeListsObj to: true.

	(self isWeakNonImm: classTableFirstPage) ifTrue:
		[^self markAndTrace: hiddenRootsObj].

	self setIsMarkedOf: hiddenRootsObj to: true.
	self markAndTrace: classTableFirstPage.
	1 to: numClassTablePages - 1 do:
		[:i| self setIsMarkedOf: (self fetchPointer: i ofObject: hiddenRootsObj)
				to: true]
]

{ #category : #'obj stacks' }
SpurMemoryManager >> markAndTraceObjStack: stackOrNil andContents: markAndTraceContents [
	"An obj stack is a stack of objects stored in a hidden root slot, such
	 as the markStack or the ephemeronQueue.  It is a linked list of
	 segments, with the hot end at the head of the list.  It is a word object.
	 The stack pointer is in ObjStackTopx and 0 means empty."
	<inline: false>
	| index field |
	stackOrNil = nilObj ifTrue:
		[^self].
	self setIsMarkedOf: stackOrNil to: true.
	self assert: (self numSlotsOfAny: stackOrNil) = ObjStackPageSlots.
	field := self fetchPointer: ObjStackNextx ofObject: stackOrNil.
	field ~= 0 ifTrue:
		[self markAndTraceObjStack: field andContents: markAndTraceContents].
	field := stackOrNil.
	[field := self fetchPointer: ObjStackFreex ofObject: field.
	 field ~= 0] whileTrue:
		[self setIsMarkedOf: field to: true].
	markAndTraceContents ifFalse:
		[^self].
	"There are four fixed slots in an obj stack, and a Topx of 0 indicates empty, so
	  if there were 6 slots in an oop stack, full would be 2, and the last 0-rel index is 5."
	index := (self fetchPointer: ObjStackTopx ofObject: stackOrNil) + ObjStackNextx.
	[index >= ObjStackFixedSlots] whileTrue:
		[field := self followObjField: index ofObject: stackOrNil.
		 (self isImmediate: field) ifFalse:
			[self markAndTrace: field].
		 index := index - 1]
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> markAndTraceWeaklingsFrom: startIndex [
	"Mark weaklings on the weaklingStack, ignoring startIndex
	 number of elements on the bottom of the stack.  Answer
	 the size of the stack *before* the enumeration began."
	^self objStack: weaklingStack from: startIndex do:
		[:weakling|
		 self deny: (self isForwarded: weakling).
		 self markAndTraceClassOf: weakling.
		"N.B. generateToByDoLimitExpression:negative:on: guards against (unsigned)0 - 1 going +ve"
		 0 to: (self numStrongSlotsOfWeakling: weakling) - 1 do:
			[:i| | field |
			field := self followOopField: i ofObject: weakling.
			((self isImmediate: field) or: [self isMarked: field]) ifFalse:
				[self markAndTrace: field]]]
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> markAsCopiedIntoSegment: anObjectInTheHeap [
	"This is part of storeImageSegmentInto:outPointers:roots:."
	<inline: true>
	self setIsMarkedOf: anObjectInTheHeap to: true
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> markInactiveEphemerons [
	"Go through the unscanned ephemerons, marking the inactive ones, and
	 removing them from the unscanned ephemerons. Answer if any inactive
	 ones were found. We cannot fire the ephemerons until all are found to
	 be active since scan-marking an inactive ephemeron later in the set may
	 render a previously-observed active ephemeron as inactive."
	| foundInactive ptr |
	foundInactive := false.
	ptr := unscannedEphemerons start.
	[ptr < unscannedEphemerons top] whileTrue:
		[| ephemeron key |
		 key := self followedKeyOfEphemeron: (ephemeron := self longAt: ptr).
		 ((self isImmediate: key) or: [self isMarked: key])
			ifTrue:
				[foundInactive := true.
				 "Now remove the inactive ephemeron from the set, and scan-mark it.
				  Scan-marking it may add more ephemerons to the set."
				 unscannedEphemerons top: unscannedEphemerons top - self bytesPerOop.
				 unscannedEphemerons top > ptr ifTrue:
					[self longAt: ptr put: (self longAt: unscannedEphemerons top)].
				 self markAndTrace: ephemeron]
			ifFalse:
				[ptr := ptr + self bytesPerOop]].
	^foundInactive
]

{ #category : #'gc - global' }
SpurMemoryManager >> markLoopFrom: objOop [
	"Scan objOop and all objects on the mark stack, until the mark stack is empty.
	 N.B. When the incremental GC is written this will probably be refactored as
	 markLoopFrom: objOop while: aBlock"
	<inline: true>
	| objToScan field index numStrongSlots scanLargeObject |

	"Now scan the object, and any remaining objects on the mark stack."
	objToScan := objOop.
	"To avoid overflowing the mark stack when we encounter large objects, we
	 push the obj, then its numStrongSlots, and then index the object from the stack."
	[(self isImmediate: objToScan)
		ifTrue: [scanLargeObject := true]
		ifFalse:
			[numStrongSlots := self numStrongSlotsOfInephemeral: objToScan.
			 scanLargeObject := numStrongSlots > self traceImmediatelySlotLimit].
	 scanLargeObject
		ifTrue: "scanning a large object. scan until hitting an unmarked object, then switch to it, if any."
			[(self isImmediate: objToScan)
				ifTrue:
					[index := self integerValueOf: objToScan.
					 objToScan := self topOfObjStack: markStack]
				ifFalse:
					[index := numStrongSlots.
					 self markAndTraceClassOf: objToScan].
			 [index > 0] whileTrue:
				[index := index - 1.
				 field := self fetchPointer: index ofObject: objToScan.
				 (self isNonImmediate: field) ifTrue:
					[(self isForwarded: field) ifTrue: "fixFollowedField: is /not/ inlined"
						[field := self fixFollowedField: index ofObject: objToScan withInitialValue: field].
					 (self markAndShouldScan: field) ifTrue:
						[index > 0 ifTrue:
							[(self topOfObjStack: markStack) ~= objToScan ifTrue: 
								[self push: objToScan onObjStack: markStack].
							 self push: (self integerObjectOf: index) onObjStack: markStack].
						 objToScan := field.
						 index := -1]]].
			 index >= 0 ifTrue: "if loop terminated without finding an unmarked referent, switch to top of stack."
				[objToScan := self popObjStack: markStack.
				 objToScan = objOop ifTrue:
					[objToScan := self popObjStack: markStack]]]
		ifFalse: "scanning a small object. scan, marking, pushing unmarked referents, then switch to the top of the stack."
			[index := numStrongSlots.
			 self markAndTraceClassOf: objToScan.
			 [index > 0] whileTrue:
				[index := index - 1.
				 field := self fetchPointer: index ofObject: objToScan.
				 (self isNonImmediate: field) ifTrue:
					[(self isForwarded: field) ifTrue: "fixFollowedField: is /not/ inlined"
						[field := self fixFollowedField: index ofObject: objToScan withInitialValue: field].
					 (self markAndShouldScan: field) ifTrue:
						[self push: field onObjStack: markStack.
						 ((self rawNumSlotsOf: field) > self traceImmediatelySlotLimit
						  and: [(numStrongSlots := self numStrongSlotsOfInephemeral: field) > self traceImmediatelySlotLimit]) ifTrue:
							[self push: (self integerObjectOf: numStrongSlots) onObjStack: markStack]]]].
			 objToScan := self popObjStack: markStack].
	 objToScan notNil] whileTrue
]

{ #category : #'gc - global' }
SpurMemoryManager >> markObjects: objectsShouldBeUnmarkedAndUnmarkedClassesShouldBeExpunged [
	<inline: #never> "for profiling"
	"Mark all accessible objects.  objectsShouldBeUnmarkedAndUnmarkedClassesShouldBeExpunged
	 is true if all objects are unmarked and/or if unmarked classes shoud be removed from the class table."
	"If the incremental collector is running mark bits may be set; stop it and clear them if necessary."
	self cCode: '' inSmalltalk: [coInterpreter transcript nextPutAll: 'marking...'; flush].
	self runLeakCheckerFor: GCModeFull.

	self shutDownIncrementalGC: objectsShouldBeUnmarkedAndUnmarkedClassesShouldBeExpunged.
	self initializeUnscannedEphemerons.
	self initializeMarkStack.
	self initializeWeaklingStack.
	marking := true.
	self markAccessibleObjectsAndFireEphemerons.
	self expungeDuplicateAndUnmarkedClasses: objectsShouldBeUnmarkedAndUnmarkedClassesShouldBeExpunged.
	self nilUnmarkedWeaklingSlots.
	marking := false
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> markObjectsIn: arrayOfRoots [
	"This is part of storeImageSegmentInto:outPointers:roots:."
	self setIsMarkedOf: arrayOfRoots to: true.
	0 to: (self numSlotsOf: arrayOfRoots) - 1 do:
		[:i| | oop |
		oop := self followField: i ofObject: arrayOfRoots.
		(self isNonImmediate: oop) ifTrue:
			[self setIsMarkedOf: oop to: true]]
]

{ #category : #'spur bootstrap' }
SpurMemoryManager >> markStack [
	^markStack
]

{ #category : #accessing }
SpurMemoryManager >> markStack: anOop [ 
	<doNotGenerate>
	markStack := anOop
]

{ #category : #'gc - global' }
SpurMemoryManager >> markWeaklingsAndMarkAndFireEphemerons [
	"After the initial scan-mark is complete ephemerons can be processed.
	 Weaklings have accumulated on the weaklingStack, but more may be
	 uncovered during ephemeron processing.  So trace the strong slots
	 of the weaklings, and as ephemerons are processed ensure any newly
	 reached weaklings are also traced."
	| numTracedWeaklings |
	<inline: false>
	numTracedWeaklings := 0.
	[coInterpreter markAndTraceUntracedReachableStackPages.
	 coInterpreter markAndTraceMachineCodeOfMarkedMethods.
	 "Make sure all reached weaklings have their strong slots traced before firing ephemerons..."
	 [numTracedWeaklings := self markAndTraceWeaklingsFrom: numTracedWeaklings.
	  (self sizeOfObjStack: weaklingStack) > numTracedWeaklings] whileTrue.
	 self noUnscannedEphemerons ifTrue:
		[coInterpreter
			markAndTraceUntracedReachableStackPages;
	 		markAndTraceMachineCodeOfMarkedMethods;
			freeUntracedStackPages;
			freeUnmarkedMachineCode.
		 ^self].
	 self markInactiveEphemerons ifFalse:
		[self fireAllUnscannedEphemerons].
	 self markAllUnscannedEphemerons]
		repeat
]

{ #category : #'header format' }
SpurMemoryManager >> markedBitFullShift [
	<cmacro>
	"bit 1 of 2-bit field above identityHash (little endian)"
	^55
]

{ #category : #'header format' }
SpurMemoryManager >> markedBitHalfShift [
	<cmacro>
	"bit 1 of 2-bit field above identityHash (little endian)"
	^23
]

{ #category : #'interpreter access' }
SpurMemoryManager >> maxCInteger [
	self subclassResponsibility
]

{ #category : #accessing }
SpurMemoryManager >> maxIdentityHash [
	^self identityHashHalfWordMask
]

{ #category : #accessing }
SpurMemoryManager >> maxOldSpaceSize [
	<cmacro: '() maxOldSpaceSize'>
	^maxOldSpaceSize
]

{ #category : #instantiation }
SpurMemoryManager >> maxSlotsForAlloc [
	"Answer the maximum number of slots we are willing to attempt to allocate in an object.
	 Must fit in 32-bits; c.f. bytesInObject:"
	^self subclassResponsibility
]

{ #category : #instantiation }
SpurMemoryManager >> maxSlotsForNewSpaceAlloc [
	"Almost entirely arbitrary, but we dont want 1Mb bitmaps allocated in eden.
	 But this choice means no check for numSlots > maxSlotsForNewSpaceAlloc
	 for non-variable allocations."
	^self fixedFieldsOfClassFormatMask
]

{ #category : #'interpreter access' }
SpurMemoryManager >> maxSmallInteger [
	self subclassResponsibility
]

{ #category : #'object testing' }
SpurMemoryManager >> maybeMethodClassOf: methodObj seemsToBeInstantiating: format [
	"Answers if the code is installed in a class instantiating objects with the format. Used in primitive 
	 generation to make a quick path based on where the method is installed. This method cannot
	 be used as a guarantee as there can be false positive, it's just a heuristic.
	 Tries to interpret the last literal of the method as a behavior (more than 3 fields, 3rd field a Smi).
	 If it can be interpreted as a behavior, answers if instSpec matches the format, else answers false."
	<api>
	| maybeClassObj maybeFormat instSpec|
	maybeClassObj := coInterpreter methodClassOf: methodObj.
	(self isPointersNonImm: maybeClassObj) ifFalse: [^false].
	(self numSlotsOfAny: maybeClassObj) > InstanceSpecificationIndex ifFalse: [^false].
	maybeFormat := self fetchPointer: InstanceSpecificationIndex ofObject: maybeClassObj.
	(self isIntegerObject: maybeFormat) ifFalse: [^false].
	instSpec := self instSpecOfClassFormat: (self integerValueOf: maybeFormat).
	^ instSpec = format
]

{ #category : #'interpreter access' }
SpurMemoryManager >> maybeSplObj: index [
	<api>
	"Answer one of the objects in the SpecialObjectsArray, if in range, otherwise answer nil."
	^index < (self numSlotsOf: specialObjectsOop) ifTrue:
		[self fetchPointer: index ofObject: specialObjectsOop]
]

{ #category : #simulation }
SpurMemoryManager >> memcpy: destAddress _: sourceAddress _: bytes [
	"For SpurGenerationScavenger>>copyToFutureSpace:bytes:. N.B. If ranges overlap, must use memmove."
	<doNotGenerate>
	sourceAddress isCollection ifTrue:
		[^super memcpy: destAddress _: sourceAddress _: bytes].
	self deny: ((destAddress <= sourceAddress and: [destAddress asInteger + bytes > sourceAddress])
				or: [sourceAddress <= destAddress and: [sourceAddress asInteger + bytes > destAddress]]).
	^self memmove: destAddress _: sourceAddress _: bytes
]

{ #category : #simulation }
SpurMemoryManager >> memmove: destAddress _: sourceAddress _: bytes [
	"Emulate the c library memmove function"
	<doNotGenerate>
	| dst src  |
	dst := destAddress asInteger.
	src := sourceAddress asInteger.
	self assert: bytes \\ 8 + (dst \\ 8) + (src \\ 8) = 0.
	memory bytesPerElement = 8
		ifTrue:
			[destAddress > sourceAddress
				ifTrue:
					[bytes - 8 to: 0 by: -8 do:
						[:i| self long64At: dst + i put: (self long64At: src + i)]]
				ifFalse:
					[0 to: bytes - 8 by: 8 do:
						[:i| self long64At: dst + i put: (self long64At: src + i)]]]
		ifFalse:
			[destAddress > sourceAddress
				ifTrue:
					[bytes - 4 to: 0 by: -4 do:
						[:i| self long32At: dst + i put: (self long32At: src + i)]]
				ifFalse:
					[0 to: bytes - 4 by: 4 do:
						[:i| self long32At: dst + i put: (self long32At: src + i)]]]
]

{ #category : #accessing }
SpurMemoryManager >> memory [
	<cmacro: '() GIV(memory)'>
	^memory
]

{ #category : #accessing }
SpurMemoryManager >> memory: aValue [
	^memory := aValue
]

{ #category : #accessing }
SpurMemoryManager >> memoryActiveProcess [

	^ self fetchPointer: ActiveProcessIndex ofObject: self memorySchedulerPointer
]

{ #category : #snapshot }
SpurMemoryManager >> memoryBaseForImageRead [
	"Answer the address to read the image into."
	^oldSpaceStart
]

{ #category : #simulation }
SpurMemoryManager >> memoryClass [
	"Answer the class to use for the memory inst var in simulation.
	 Answer nil if a suitable class isn't available."
	<doNotGenerate>
	^self subclassResponsibility
]

{ #category : #snapshot }
SpurMemoryManager >> memoryLimit [
	^endOfMemory
]

{ #category : #accessing }
SpurMemoryManager >> memorySchedulerPointer [

	^ self fetchPointer: ValueIndex ofObject: (self splObj: SchedulerAssociation)
]

{ #category : #'simulation only' }
SpurMemoryManager >> methodArgumentCount [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter methodArgumentCount
]

{ #category : #'interpreter access' }
SpurMemoryManager >> methodCacheHashOf: selector with: classTag [
	"Sicne class tags are indices or immediate tags, it is necessary to shift the class
	 tag w.r.t. the selector to include the full class index/immediate tags in the hash."
	<inline: true>
	^selector bitXor: classTag << 2 "num cache probes - 1"
]

{ #category : #compaction }
SpurMemoryManager >> methodHeaderFromSavedFirstField: oop [
	self assert: (self isIntegerObject: oop).
	^oop
]

{ #category : #'memory access' }
SpurMemoryManager >> methodHeaderOf: methodObj [
	"Answer the method header of a CompiledMethod object."
	self assert: (self isCompiledMethod: methodObj).
	^self fetchPointer: HeaderIndex ofObject: methodObj
]

{ #category : #'simulation only' }
SpurMemoryManager >> methodReturnBool: boolean [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter methodReturnBool: boolean
]

{ #category : #'simulation only' }
SpurMemoryManager >> methodReturnFloat: aFloat [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter methodReturnFloat: aFloat
]

{ #category : #'simulation only' }
SpurMemoryManager >> methodReturnInteger: integer [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter methodReturnInteger: integer
]

{ #category : #'simulation only' }
SpurMemoryManager >> methodReturnReceiver [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter methodReturnReceiver
]

{ #category : #'simulation only' }
SpurMemoryManager >> methodReturnString: aCString [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter methodReturnString: aCString
]

{ #category : #'simulation only' }
SpurMemoryManager >> methodReturnValue: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter methodReturnValue: oop
]

{ #category : #allocation }
SpurMemoryManager >> minSlotsForShortening [
	"Answer the minimum number of additional slots to allocate in an object to always be able to shorten it.
	 This is enough slots to allocate a minimum-sized object."
	<api>
	^self allocationUnit * 2 / self bytesPerOop
]

{ #category : #'interpreter access' }
SpurMemoryManager >> minSmallInteger [
	self subclassResponsibility
]

{ #category : #'spur bootstrap' }
SpurMemoryManager >> mournQueue [
	^mournQueue
]

{ #category : #accessing }
SpurMemoryManager >> mournQueue: anOop [ 
	<doNotGenerate>
	mournQueue := anOop
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> moveClassesForwardsIn: arrayOfObjects [
	"This is part of storeImageSegmentInto:outPointers:roots:.
	 Both to expand the max size of segment and to reduce the length of the
	 load-time pass that adds classes to the class table, move classes to the
	 front of arrayOfObjects, leaving the root array as the first element.
	 Answer the number of classes in the segment."
	| nClasses there |
	nClasses := there := 0. "if > 0, this is the index of the first non-class past the first element."
	1 to: (self numSlotsOf: arrayOfObjects) - 1 do:
		[:here| | objOop hash tempObjOop |
		 objOop := self fetchPointer: here ofObject: arrayOfObjects.
		 hash := self rawHashBitsOf: objOop.
		 (hash > self lastClassIndexPun and: [(self classOrNilAtIndex: hash) = objOop])
			ifTrue:
				[nClasses := nClasses + 1.
				 there > 0 ifTrue: "if there is zero we're in a run of classes at the start so don't move"
					[tempObjOop := self fetchPointer: there ofObject: arrayOfObjects.
					 self storePointerUnchecked: there ofObject: arrayOfObjects withValue: objOop.
					 self storePointerUnchecked: here ofObject: arrayOfObjects withValue: tempObjOop.
					 there := there + 1]]
			ifFalse:
				[there = 0 ifTrue:
					[there := here]]].
	^nClasses
]

{ #category : #'become implementation' }
SpurMemoryManager >> naiveSwapHeaders: obj1 and: obj2 copyHashFlag: copyHashFlag [
	"swap headers, but swapping headers swaps remembered bits and hashes;
	 remembered bits must be unswapped and hashes may be unswapped if
	 copyHash is false."
	"This variant tickles a compiler bug in gcc and clang. See cleverSwapHeaders:and:copyHashFlag:"
	<inline: true>
	| headerTemp remembered1 remembered2 hashTemp |
	remembered1 := self isRemembered: obj1.
	remembered2 := self isRemembered: obj2.
	headerTemp := self long64At: obj1.
	self long64At: obj1 put: (self long64At: obj2).
	self long64At: obj2 put: headerTemp.
	self setIsRememberedOf: obj1 to: remembered1.
	self setIsRememberedOf: obj2 to: remembered2.
	"swapping headers swaps hash; if !copyHashFlag undo hash copy"
	copyHashFlag ifFalse:
		[hashTemp := self rawHashBitsOf: obj1.
		 self setHashBitsOf: obj1 to: (self rawHashBitsOf: obj2).
		 self setHashBitsOf: obj2 to: hashTemp]
]

{ #category : #accessing }
SpurMemoryManager >> needGCFlag [
	^needGCFlag
]

{ #category : #accessing }
SpurMemoryManager >> needGCFlag: anInteger [
	needGCFlag := anInteger ~= 0
]

{ #category : #'header access' }
SpurMemoryManager >> newHashBitsOf: objOop [
	| hash |
	hash := self newObjectHash bitAnd: self identityHashHalfWordMask.
	self setHashBitsOf: objOop to: hash.
	^hash
]

{ #category : #accessing }
SpurMemoryManager >> newObjectHash [
	"Use a slight variation on D.H. Lehmer's linear congruential generator from 1951.
	 See e.g. http://en.wikipedia.org/wiki/Linear_congruential_generator."
	| hash |
	[lastHash := self cCode: [lastHash * 16807] "7 raisedTo: 5"
					inSmalltalk: [lastHash := lastHash * 16807 bitAnd: 16rFFFFFFFF].
	 hash := lastHash + (lastHash >> 4). "adding the top bits gives much better spread.  See below:"
	 (hash bitAnd: self identityHashHalfWordMask) = 0] whileTrue.
	^hash

	"the standard algorithm doesn't vary well in the least significant bits:"
	"| r s n |
	r := 1.
	n := 256 * 256 * 256.
	s := Set new: n * 2.
	n timesRepeat:
		[s add: (r bitAnd: n - 1).
		r := r * 16807 bitAnd: 16rFFFFFFFF].
	{ s size. s size / n asFloat. s includes: 0. r hex }
=>	 #(2097152 0.125 false '16r38000001')"

	"this can be improved by adding in shifted upper bits"
	"| r s n |
	r := 1.
	n := 256 * 256 * 256.
	s := Set new: n * 2.
	n timesRepeat:
		[s add: (r + (r bitShift: -8) bitAnd: n - 1).
		r := r * 16807 bitAnd: 16rFFFFFFFF].
	{ s size. s size / n asFloat. s includes: 0. r hex }
=>	#(10702109 0.637895405292511 false '16r38000001')"


"but which shift is best?  Looks like -4:"
"(-2 to: -15 by: -1) do:
	[:shift|
	| r s n |
	r := 1.
	n := 256 * 256 * 256.
	s := Set new: n * 2.
	n timesRepeat:
		[s add: (r + (r bitShift: shift) bitAnd: n - 1).
		r := r * 16807 bitAnd: 16rFFFFFFFF].
	Transcript cr; print: { shift. s size. s size / n asFloat. s includes: 0. r hex }; flush]

#(-2 8388608 0.5 true '16r38000001')
#(-3 8388608 0.5 false '16r38000001')
#(-4 12582503 0.749975621700287 true '16r38000001')
#(-5 11468379 0.6835686564445495 false '16r38000001')
#(-6 11013442 0.656452298164368 true '16r38000001')
#(-7 10804094 0.643974184989929 true '16r38000001')
#(-8 10702109 0.637895405292511 false '16r38000001')
#(-9 10703730 0.637992024421692 false '16r38000001')
#(-10 7865201 0.468802511692047 false '16r38000001')
#(-11 8444092 0.503307104110718 false '16r38000001')
#(-12 10703317 0.6379674077034 true '16r38000001')
#(-13 10701116 0.637836217880249 true '16r38000001')
#(-14 10689443 0.637140452861786 true '16r38000001')
#(-15 7853923 0.4681302905082702 true '16r38000001')"
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> newOutPointer: oop at: outIndex in: outPointerArray hashes: savedOutHashes [
	"This is part of storeImageSegmentInto:outPointers:roots:.
	 oop is a new outPointer; allocate its oop, and answer the new outIndex.
	 If outPointerArray is full, answer 0."
	<inline: true>
	outIndex >= (self numSlotsOf: outPointerArray) ifTrue:
					["no room in outPointers; fail"
					 ^0].
	self storePointer: outIndex ofObject: outPointerArray withValue: oop.
	self storeLong32: outIndex ofObject: savedOutHashes withValue: (self rawHashBitsOf: oop).
	self setHashBitsOf: oop to: outIndex + TopHashBit.
	^outIndex + 1
]

{ #category : #accessing }
SpurMemoryManager >> newSpaceBytes [
	^edenBytes
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> newSpaceIsEmpty [
	^freeStart = scavenger eden start
	  and: [pastSpaceStart = scavenger pastSpace start]
]

{ #category : #accessing }
SpurMemoryManager >> newSpaceLimit [
	<cmacro: '() GIV(newSpaceLimit)'>
	^newSpaceLimit
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> newSpaceRefCountMask [
	"The three bit field { isGrey, isPinned, isRemembered } is for bits
	 that are never set in young objects.  This allows the remembered
	 table to be pruned when full by using these bits as a reference
	 count of newSpace objects from the remembered table. Objects
	 with a high count should be tenured to prune the remembered table."
	^1 << self greyBitShift
	  bitOr: (1 << self pinnedBitShift
	  bitOr: 1 << self rememberedBitShift)
]

{ #category : #accessing }
SpurMemoryManager >> newSpaceSize [
	^(freeStart - scavenger eden start)
	 + (pastSpaceStart - scavenger pastSpace start)
]

{ #category : #accessing }
SpurMemoryManager >> newSpaceStart [
	^newSpaceStart
]

{ #category : #'primitive support' }
SpurMemoryManager >> nilFieldsOf: obj [ 
	0 to: (self numSlotsOf: obj) - 1 do:
		[:i|
		self storePointerUnchecked: i ofObject: obj withValue: nilObj]
]

{ #category : #accessing }
SpurMemoryManager >> nilObject [
	<api>
	^nilObj
]

{ #category : #accessing }
SpurMemoryManager >> nilObject: anOop [
	"For mapInterpreterOops"
	nilObj := anOop
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> nilUnmarkedWeaklingSlots [
	"Nil the unmarked slots in the weaklings on the
	 weakling stack, finalizing those that lost references.
	 Finally, empty the weaklingStack."
	<inline: #never> "for profiling"
	self cCode: '' inSmalltalk: [coInterpreter transcript nextPutAll: 'nilling...'; flush].
	self eassert: [self allOldMarkedWeakObjectsOnWeaklingStack].
	weaklingStack = nilObj ifTrue:
		[^self].
	self objStack: weaklingStack from: 0 do:
		[:weakling| | anyUnmarked |
		anyUnmarked := self nilUnmarkedWeaklingSlotsIn: weakling.
		anyUnmarked ifTrue:
			["fireFinalization: could grow the mournQueue and if so,
			  additional pages must be marked to avoid being GC'ed."
			 self assert: marking.
			 coInterpreter fireFinalization: weakling]].
	self emptyObjStack: weaklingStack
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> nilUnmarkedWeaklingSlotsIn: aWeakling [
	"Nil the unmarked slots in aWeakling and
	 answer if any unmarked slots were found."
	<inline: true>
	| anyUnmarked |
	anyUnmarked := false.
	self assert: (self allStrongSlotsOfWeaklingAreMarked: aWeakling).
	"N.B. generateToByDoLimitExpression:negative:on: guards against (unsigned)0 - 1 going +ve"
	(self numStrongSlotsOfWeakling: aWeakling) to: (self numSlotsOf: aWeakling) - 1 do:
		[:i| | referent |
		referent := self fetchPointer: i ofObject: aWeakling.
		(self isNonImmediate: referent) ifTrue:
			[(self isUnambiguouslyForwarder: referent) ifTrue:
				[referent := self fixFollowedField: i ofObject: aWeakling withInitialValue: referent].
			 ((self isImmediate: referent) or: [self isMarked: referent]) ifFalse:
				[self storePointerUnchecked: i ofObject: aWeakling withValue: nilObj.
				 anyUnmarked := true]]].
	^anyUnmarked
]

{ #category : #'class table' }
SpurMemoryManager >> noCheckClassAtIndex: classIndex [
	| classTablePage |
	classTablePage := self fetchPointer: classIndex >> self classTableMajorIndexShift
							ofObject: hiddenRootsObj.
	classTablePage = nilObj ifTrue:
		[^nil].
	^self
		fetchPointer: (classIndex bitAnd: self classTableMinorIndexMask)
		ofObject: classTablePage
]

{ #category : #'obj stacks' }
SpurMemoryManager >> noCheckPush: objOop onObjStack: objStack [
	<inline: false>
	"Push an element on an objStack.  Split from push:onObjStack: for testing."
	| topx |
	self eassert: [self isValidObjStack: objStack].
	self cCode: '' "for debugging markAndTrace: set (MarkStackRecord := OrderedCollection new)"
		inSmalltalk:
			[MarkStackRecord ifNotNil:
				[(self fetchPointer: ObjStackMyx ofObject: objStack) = MarkStackRootIndex ifTrue:
					[MarkStackRecord addLast: {#push. objOop}]]].
	topx := self fetchPointer: ObjStackTopx ofObject: objStack.
	topx >= ObjStackLimit
		ifTrue:
			[self noCheckPush: objOop
				onObjStack: (self ensureRoomOnObjStackAt: (self fetchPointer: ObjStackMyx ofObject: objStack))]
		ifFalse:
			[self storePointer: ObjStackFixedSlots + topx ofObjStack: objStack withValue: objOop.
			 self storePointer: ObjStackTopx ofObjStack: objStack withValue: topx + 1].
	^objOop
]

{ #category : #forwarding }
SpurMemoryManager >> noFixupFollowField: fieldIndex ofObject: anObject [
	"Make sure the oop at fieldIndex in anObject is not forwarded (follow the
	 forwarder there-in if so).  Answer the (possibly followed) oop at fieldIndex."
	| objOop |
	objOop := self fetchPointer: fieldIndex ofObject: anObject.
	(self isOopForwarded: objOop) ifTrue:
		[objOop := self followForwarded: objOop].
	^objOop
]

{ #category : #forwarding }
SpurMemoryManager >> noInlineFollowForwarded: objOop [
	<inline: false>
	^self followForwarded: objOop
]

{ #category : #'object enumeration' }
SpurMemoryManager >> noInlineObjectAfter: objOop limit: limit [
	"Object parsing.
	1. all objects have at least a word following the header, for a forwarding pointer.
	2. objects with an overflow size have a preceeing word with a saturated numSlots.  If the word
	   following an object doesn't have a saturated numSlots field it must be a single-header object.
	   If the word following does have a saturated numSlots it must be the overflow size word."
	<inline: false>
	^self objectAfter: objOop limit: limit
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> noUnscannedEphemerons [
	^unscannedEphemerons top = unscannedEphemerons start
]

{ #category : #'header formats' }
SpurMemoryManager >> nonIndexablePointerFormat [
	<api>
	^1
]

{ #category : #'object access' }
SpurMemoryManager >> num16BitUnitsOf: objOop [ 
	"Answer the number of 16-bit units in the given non-immediate object.
	 N..B. Rounds down 8-bit units, so a 5 byte object has 2 16-bit units.
	 Does not adjust the size of contexts by stackPointer."
	^(self numBytesOf: objOop) >> 1
]

{ #category : #'object access' }
SpurMemoryManager >> num32BitUnitsOf: objOop [ 
	"Answer the number of 32-bit units in the given non-immediate object.
	 N..B. Rounds down 8-bit units, so a 7 byte object has 1 32-bit unit.
	 Does not adjust the size of contexts by stackPointer."
	^(self numBytesOf: objOop) >> 2
]

{ #category : #'object access' }
SpurMemoryManager >> num64BitUnitsOf: objOop [ 
	"Answer the number of 16-bit units in the given non-immediate object.
	 N..B. Rounds down 8-bit units, so a 15 byte object has 1 64-bit unit.
	 Does not adjust the size of contexts by stackPointer."
	^(self numBytesOf: objOop) >> 3
]

{ #category : #'object access' }
SpurMemoryManager >> numBytesOf: objOop [ 
	"Answer the number of indexable bytes in the given non-immediate object.
	 Does not adjust the size of contexts by stackPointer."
	<api>
	| fmt numBytes |
	<inline: true>
	fmt := self formatOf: objOop.
	numBytes := self numSlotsOf: objOop.
	numBytes := numBytes << self shiftForWord.
	fmt >= self firstByteFormat ifTrue: "bytes (the common case), including CompiledMethod"
		[^numBytes - (fmt bitAnd: 7)].
	fmt <= self sixtyFourBitIndexableFormat ifTrue:
		[^numBytes].
	fmt >= self firstShortFormat ifTrue:
		[^numBytes - ((fmt bitAnd: 3) << 1)].
	"fmt >= self firstLongFormat"
	^numBytes - ((fmt bitAnd: 1) << 2)
]

{ #category : #'object access' }
SpurMemoryManager >> numBytesOfBytes: objOop [ 
	"Answer the number of indexable bytes in the given non-immediate byte-indexable object."
	| fmt |
	<inline: true>
	fmt := self formatOf: objOop.
	self assert: fmt >= self firstByteFormat.
	^(self numSlotsOf: objOop) << self shiftForWord - (fmt bitAnd: 7)
]

{ #category : #'object format' }
SpurMemoryManager >> numFixedSlotsOf: objOop [
	<inline: true>
	^self fixedFieldsOfClassFormat: (self formatOfClass: (self fetchClassOfNonImm: objOop))
]

{ #category : #'free space' }
SpurMemoryManager >> numFreeLists [
	"Answer the number of free lists.  We use freeListsMask, a bitmap, to avoid
	 reading empty list heads.  This should fit in a machine word to end up in a
	 register during free chunk allocation."
	^self subclassResponsibility
]

{ #category : #'object access' }
SpurMemoryManager >> numPointerSlotsOf: objOop [
	"Answer the number of pointer fields in the given object.
	 Works with CompiledMethods, as well as ordinary objects."
	<api>
	<inline: true>
	| fmt contextSize numLiterals header |
	fmt := self formatOf: objOop.
	fmt <= self lastPointerFormat ifTrue:
		[(fmt = self indexablePointersFormat
		  and: [self isContextNonImm: objOop]) ifTrue:
			["contexts end at the stack pointer"
			contextSize := coInterpreter fetchStackPointerOf: objOop.
			^CtxtTempFrameStart + contextSize].
		^self numSlotsOf: objOop  "all pointers"].
	fmt = self forwardedFormat ifTrue: [^1].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	header := self methodHeaderOf: objOop.
	numLiterals := self literalCountOfMethodHeader: header.
	^numLiterals + LiteralStart
]

{ #category : #segments }
SpurMemoryManager >> numSegments [
	<doNotGenerate>
	^segmentManager numSegments
]

{ #category : #'header format' }
SpurMemoryManager >> numSlotsForBytes: numBytes [
	^numBytes + (self wordSize - 1) // self wordSize
]

{ #category : #allocation }
SpurMemoryManager >> numSlotsForShortening: objOop toIndexableSize: indexableSize [
	self subclassResponsibility
]

{ #category : #'header format' }
SpurMemoryManager >> numSlotsFullShift [
	<api>
	<cmacro>
	^56
]

{ #category : #'header format' }
SpurMemoryManager >> numSlotsHalfShift [
	<api>
	<cmacro>
	^24
]

{ #category : #'header format' }
SpurMemoryManager >> numSlotsMask [
	<api>
	<cmacro>
	"8-bit slot count
		max 64-bit small obj size 254 * 8 =  2032 bytes
		max 32-bit small obj size 254 * 4 =   1016 bytes"
	^255
]

{ #category : #'object access' }
SpurMemoryManager >> numSlotsOf: objOop [
	<returnTypeC: #usqInt>
	<api>
	| numSlots |
	self flag: #endianness.
	"numSlotsOf: should not be applied to free or forwarded objects."
	self assert: (self classIndexOf: objOop) > self isForwardedObjectClassIndexPun.
	numSlots := self rawNumSlotsOf: objOop.
	^numSlots = self numSlotsMask	"overflow slots; (2^32)-1 slots are plenty"
		ifTrue: [self rawOverflowSlotsOf: objOop]
		ifFalse: [numSlots]
]

{ #category : #'object access' }
SpurMemoryManager >> numSlotsOfAny: objOop [
	"A private internal version of numSlotsOf: that is happy to be applied to free or forwarded objects."
	<returnTypeC: #usqInt>
	| numSlots |
	numSlots := self rawNumSlotsOf: objOop.
	^numSlots = self numSlotsMask
		ifTrue: [self rawOverflowSlotsOf: objOop] "overflow slots; (2^32)-1 slots are plenty"
		ifFalse: [numSlots]
]

{ #category : #'interpreter access' }
SpurMemoryManager >> numSmallIntegerBits [
	self subclassResponsibility
]

{ #category : #'interpreter access' }
SpurMemoryManager >> numSmallIntegerTagBits [
	^self subclassResponsibility
]

{ #category : #'object access' }
SpurMemoryManager >> numStrongSlotsOf: objOop format: fmt ephemeronInactiveIf: criterion [
	"Answer the number of strong pointer fields in the given object.
	 Works with CompiledMethods, as well as ordinary objects."
	<var: 'criterion' declareC: 'int (*criterion)(sqInt key)'>
	<inline: true>
	| numSlots  contextSize numLiterals header |
	fmt <= self lastPointerFormat ifTrue:
		[numSlots := self numSlotsOf: objOop.
		 fmt <= self arrayFormat ifTrue:
			[^numSlots].
		 fmt = self indexablePointersFormat ifTrue:
			[(self isContextNonImm: objOop) ifTrue:
				[coInterpreter setTraceFlagOnContextsFramesPageIfNeeded: objOop.
				 "contexts end at the stack pointer"
				 contextSize := coInterpreter fetchStackPointerOf: objOop.
				 ^CtxtTempFrameStart + contextSize].
			 ^numSlots].
		 fmt = self weakArrayFormat ifTrue:
			[^self fixedFieldsOfClass: (self fetchClassOfNonImm: objOop)].
		 self assert: fmt = self ephemeronFormat.
		 ^(self perform: criterion with: (self keyOfEphemeron: objOop))
			ifTrue: [numSlots]
			ifFalse: [0]].
	fmt = self forwardedFormat ifTrue: [^1].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	header := self methodHeaderOf: objOop.
	numLiterals := self literalCountOfMethodHeader: header.
	^numLiterals + LiteralStart
]

{ #category : #'object access' }
SpurMemoryManager >> numStrongSlotsOfInephemeral: objOop [
	"Answer the number of strong pointer fields in the given object,
	 which is .expected not to be an active ephemeron.
	 Works with CompiledMethods, as well as ordinary objects."
	<inline: true>
	| fmt numSlots  contextSize numLiterals header |
	fmt := self formatOf: objOop.
	self assert: (fmt ~= self ephemeronFormat or: [self isMarked: (self keyOfEphemeron: objOop)]).
	fmt <= self lastPointerFormat ifTrue:
		[numSlots := self numSlotsOf: objOop.
		 fmt <= self arrayFormat ifTrue:
			[^numSlots].
		 fmt = self indexablePointersFormat ifTrue:
			[(self isContextNonImm: objOop) ifTrue:
				[coInterpreter setTraceFlagOnContextsFramesPageIfNeeded: objOop.
				 "contexts end at the stack pointer"
				 contextSize := coInterpreter fetchStackPointerOf: objOop.
				 ^CtxtTempFrameStart + contextSize].
			 ^numSlots].
		 fmt = self weakArrayFormat ifTrue:
			[^self fixedFieldsOfClass: (self fetchClassOfNonImm: objOop)]].
	fmt = self forwardedFormat ifTrue: [^1].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	header := self methodHeaderOf: objOop.
	numLiterals := self literalCountOfMethodHeader: header.
	^numLiterals + LiteralStart
]

{ #category : #'object access' }
SpurMemoryManager >> numStrongSlotsOfWeakling: objOop [
	"Answer the number of strong pointer fields in the given weakling."
	<api>
	<inline: true>
	self assert: (self formatOf: objOop) = self weakArrayFormat.
	^self fixedFieldsOfClass: (self fetchClassOfNonImm: objOop)
]

{ #category : #scavenger }
SpurMemoryManager >> numSurvivorSpaces [
	"there are two survivor spaces, futureSPace & pastSpace."
	^2
]

{ #category : #'object access' }
SpurMemoryManager >> numTagBits [
	^self subclassResponsibility
]

{ #category : #'debug support' }
SpurMemoryManager >> numberOfForwarders [
	| n |
	n := 0.
	self allHeapEntitiesDo:
		[:o|
		(self isUnambiguouslyForwarder: o) ifTrue:
			[n := n + 1]].
	^n
]

{ #category : #'obj stacks' }
SpurMemoryManager >> objStack: objStack do: aBlock [
	"Evaluate aBinaryBlock with all indices and pages of elements in objStack"
	<inline: true>
	| objStackPage |
	objStack = nilObj ifTrue:
		[^self].
	self eassert: [self isValidObjStack: objStack].
	objStackPage := objStack.
	[objStackPage ~= 0] whileTrue:
		[| numOnThisPage |
		 numOnThisPage := self fetchPointer: ObjStackTopx ofObject: objStackPage.
		 numOnThisPage + ObjStackFixedSlots - 1 to: ObjStackFixedSlots by: -1 do:
			[:i| aBlock value: i value: objStackPage].
		 objStackPage := self fetchPointer: ObjStackNextx ofObject: objStackPage]
]

{ #category : #'obj stacks' }
SpurMemoryManager >> objStack: objStack from: start do: aBlock [
	"Evaluate aBlock with all elements from start (0-relative) in objStack.
	 Answer the size of the stack *before* the enumeration commences.
	 This evaluates in top-of-stack-to-bottom order.  N.B. this is also stable
	 if aBlock causes new elements to be added to the objStack, but
	 unstable if aBlock causes elements to be removed."
	<inline: true>
	| size objStackPage numToEnumerate |
	self eassert: [self isValidObjStack: weaklingStack].
	size := self fetchPointer: ObjStackTopx ofObject: objStack.
	objStackPage := self fetchPointer: ObjStackNextx ofObject: objStack.
	[objStackPage ~= 0] whileTrue:
		[size := size + ObjStackLimit.
		 self assert: (self fetchPointer: ObjStackTopx ofObject: objStackPage) = ObjStackLimit.
		 objStackPage := self fetchPointer: ObjStackNextx ofObject: objStackPage].
	numToEnumerate := size - start.
	objStackPage := objStack.
	[numToEnumerate > 0] whileTrue:
		[| numOnThisPage numToEnumerateOnThisPage topIndex |
		 numOnThisPage := self fetchPointer: ObjStackTopx ofObject: objStackPage.
		 numToEnumerateOnThisPage := numToEnumerate min: numOnThisPage.
		 topIndex := numOnThisPage + ObjStackFixedSlots - 1.
		 topIndex
			to: topIndex - numToEnumerateOnThisPage + 1
			by: -1
			do:	[:i|
				self assert: (self isWeak: (self fetchPointer: i ofObject: objStackPage)).
				aBlock value: (self fetchPointer: i ofObject: objStackPage)].
		 numToEnumerate := numToEnumerate - numToEnumerateOnThisPage.
		 objStackPage := self fetchPointer: ObjStackNextx ofObject: objStackPage].
	^size
]

{ #category : #'object enumeration' }
SpurMemoryManager >> objectAfter: objOop [
	<api>
	"Object parsing.
	1. all objects have at least a word following the header, for a forwarding pointer.
	2. objects with an overflow size have a preceeing word with a saturated slotSize.  If the word following
	    an object doesn't have a saturated size field it must be a single-header object.  If the word following
	   does have a saturated slotSize it must be the overflow size word."
	<inline: false>
	(self oop: objOop isLessThan: newSpaceLimit) ifTrue:
		[(self isInEden: objOop) ifTrue:
			[^self objectAfter: objOop limit: freeStart].
		 (self isInPastSpace: objOop) ifTrue:
			[^self objectAfter: objOop limit: pastSpaceStart].
		 ^self objectAfter: objOop limit: scavenger futureSurvivorStart].
	^self objectAfter: objOop limit: endOfMemory
]

{ #category : #'object enumeration' }
SpurMemoryManager >> objectAfter: objOop limit: limit [
	"Object parsing.
	1. all objects have at least a word following the header, for a forwarding pointer.
	2. objects with an overflow size have a preceding word with a saturated numSlots.  If the word
	   following an object doesn't have a saturated numSlots field it must be a single-header object.
	   If the word following does have a saturated numSlots it must be the overflow size word."
	^self subclassResponsibility
]

{ #category : #'object enumeration' }
SpurMemoryManager >> objectBefore: objOop [
	<api>
	| prev |
	prev := nil.
	(self oop: objOop isLessThan: newSpaceLimit) ifTrue:
		[self allNewSpaceEntitiesDo:
			[:o|
			 (self oop: o isGreaterThanOrEqualTo: objOop) ifTrue:
				[^prev].
			 prev := o].
		 ^prev].
	self allOldSpaceEntitiesDo:
		[:o|
		 (self oop: o isGreaterThanOrEqualTo: objOop) ifTrue:
			[^prev].
		 prev := o].
	^prev
]

{ #category : #allocation }
SpurMemoryManager >> objectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object with the given
	 number of slots, including header and possible overflow size header."
	<returnTypeC: #usqInt>
	self subclassResponsibility
]

{ #category : #simulation }
SpurMemoryManager >> objectMemory [
	<doNotGenerate>
	^self
]

{ #category : #'object enumeration' }
SpurMemoryManager >> objectStartingAt: address [
	"For enumerating objects find the header of the first object in a space.
	 If the object starts with an overflow size field it will start at the next allocationUnit.
	 c.f. numSlotsOf:"
	| numSlots |
	numSlots := self rawNumSlotsOf: address.
	^numSlots = self numSlotsMask
		ifTrue: [address + self baseHeaderSize]
		ifFalse: [address]
]

{ #category : #'header access' }
SpurMemoryManager >> objectWithRawSlotsHasOverflowHeader: rawNumSlots [
	^rawNumSlots = self numSlotsMask
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> objectsReachableFromRoots: arrayOfRoots [
	"This is part of storeImageSegmentInto:outPointers:roots:.
	 Answer an Array of all the objects only reachable from the argument, an Array of root objects,
	 starting with arrayOfRoots.  If there is no space, answer a SmallInteger whose value is the
	 number of slots required.  This is used to collect the objects to include in an image segment
	 on Spur, separate from creating the segment, hence simplifying the implementation.
	 Thanks to Igor Stasenko for this idea."

	| freeChunk ptr start limit count oop objOop |
	<var: #freeChunk type: #usqInt> "& hence start & ptr are too; limit is also because of addressAfter:"
	<inline: #never>
	self assert: (self isArray: arrayOfRoots).
	"Mark all objects except those only reachable from the arrayOfRoots by marking
	 each object in arrayOfRoots and then marking all reachable objects (from the
	 system roots).  This leaves unmarked only objects reachable from the arrayOfRoots.
	 N.B. A side-effect of the marking is that all forwarders in arrayOfRoots will be followed."
 	self assert: self allObjectsUnmarked.
	self markObjectsIn: arrayOfRoots.
	self markObjects: false.

	"After the mark phase all unreachable weak slots will have been nilled
	 and all active ephemerons fired."
	self assert: (self isEmptyObjStack: markStack).
	self assert: (self isEmptyObjStack: weaklingStack).
	self assert: self noUnscannedEphemerons.

	"Now unmark the roots before collecting the transitive closure of unmarked objects accessible from the roots."
	self unmarkObjectsIn: arrayOfRoots.

	"Use the largest free chunk to answer the result."
	freeChunk := self allocateLargestFreeChunk. "N.B. Does /not/ update totalFreeOldSpace"
	totalFreeOldSpace := totalFreeOldSpace - (self bytesInObject: freeChunk). "but must update so that growth in the markStack does not cause assert fails."
	ptr := start := freeChunk + self baseHeaderSize.
	limit := self addressAfter: freeChunk.
	count := 0.

	"First put the arrayOfRoots; order is important."
	self noCheckPush: arrayOfRoots onObjStack: markStack.

	"Now collect the roots and the transitive closure of unmarked objects from them."
	[self isEmptyObjStack: markStack] whileFalse:
		[objOop := self popObjStack: markStack.
		 self assert: (self isMarked: objOop).
		 count := count + 1.
		 ptr < limit ifTrue:
			[self longAt: ptr put: objOop.
			 ptr := ptr + self bytesPerOop].
		 oop := self fetchClassOfNonImm: objOop.
		 (self isMarked: oop) ifFalse:
			[self setIsMarkedOf: oop to: true.
			 self noCheckPush: oop onObjStack: markStack].
		 ((self isContextNonImm: objOop)
		  and: [coInterpreter isStillMarriedContext: objOop]) "widow now, before the copy loop"
			ifTrue:
				[0 to: (coInterpreter numSlotsOfMarriedContext: objOop) - 1 do:
					[:i|
					 oop := coInterpreter fetchPointer: i ofMarriedContext: objOop.
					 ((self isImmediate: oop)
					  or: [self isMarked: oop]) ifFalse:
						[self setIsMarkedOf: oop to: true.
						 self noCheckPush: oop onObjStack: markStack]]]
			ifFalse:
				[0 to: (self numPointerSlotsOf: objOop) - 1 do:
					[:i|
					 oop := self fetchPointer: i ofObject: objOop.
					 ((self isImmediate: oop)
					  or: [self isMarked: oop]) ifFalse:
						[self setIsMarkedOf: oop to: true.
						 self noCheckPush: oop onObjStack: markStack]]]].

	self unmarkAllObjects.

	"Now try and allocate the result"
	(count > (ptr - start / self bytesPerOop) "not enough room"
	 or: [limit ~= ptr and: [limit - ptr <= self allocationUnit]]) ifTrue: "can't split a single word"
		[self freeObject: freeChunk.
		 self checkFreeSpace: GCModeImageSegment.
		 ^self integerObjectOf: count].
	"There's room; set the format, & classIndex and shorten."
	self setFormatOf: freeChunk to: self arrayFormat.
	self setClassIndexOf: freeChunk to: ClassArrayCompactIndex.
	self shorten: freeChunk toIndexableSize: count.
	(self isForwarded: freeChunk) ifTrue:
		[freeChunk := self followForwarded: freeChunk].
	self possibleRootStoreInto: freeChunk.
	self checkFreeSpace: GCModeImageSegment.
	self runLeakCheckerFor: GCModeImageSegment.
	^freeChunk
]

{ #category : #'plugin support' }
SpurMemoryManager >> obsoleteDontUseThisFetchWord: fieldIndex ofObject: oop [
	"This message is deprecated but supported for a while via a tweak to sqVirtualMachine.[ch] Use fetchLong32, fetchLong64 or fetchPointer instead for new code"
	<api>
	^self fetchLong32: fieldIndex ofObject: oop
]

{ #category : #'debug support' }
SpurMemoryManager >> okayOop: signedOop [
	"Verify that the given oop is legitimate. Check address, header, and size but not class."

	| oop classIndex fmt unusedBits unusedBitsInYoungObjects |
	<var: #oop type: #usqInt>
	<var: #unusedBits type: #usqLong>
	oop := self cCoerce: signedOop to: #usqInt.

	"address and size checks"
	(self isImmediate: oop) ifTrue: [^true].
	(self addressCouldBeObj: oop) ifFalse:
		[self error: 'oop is not a valid address'. ^false].

	(self oop: (self addressAfter: oop) isLessThanOrEqualTo: endOfMemory) ifFalse:
		[self error: 'oop size would make it extend beyond the end of memory'. ^false].

	"header type checks"
	(classIndex := self classIndexOf: oop) >= self firstClassIndexPun ifFalse:
		[self error: 'oop is a free chunk, or bridge, not an object'. ^false].
	((self rawNumSlotsOf: oop) = self numSlotsMask
	 and: [(self rawNumSlotsOf: oop - self baseHeaderSize) ~= self numSlotsMask]) ifTrue:
		[self error: 'oop header has overflow header word, but overflow word does not have a saturated numSlots field'. ^false].

	"format check"
	fmt := self formatOf: oop.
	(fmt = 6) | (fmt = 8) ifTrue:
		[self error: 'oop has an unknown format type'. ^false].
	(fmt = self forwardedFormat) ~= (classIndex = self isForwardedObjectClassIndexPun) ifTrue:
		[self error: 'oop has mis-matched format/classIndex fields; only one of them is the isForwarded value'. ^false].

	"specific header bit checks"
	unusedBits := (1 << self classIndexFieldWidth)
				   bitOr: (1 << (self identityHashFieldWidth + 32)).
	((self long64At: oop) bitAnd: unusedBits) ~= 0 ifTrue:
		[self error: 'some unused header bits are set; should be zero'. ^false].

	unusedBitsInYoungObjects := ((1 << self greyBitShift)
								   bitOr: (1 << self pinnedBitShift))
								   bitOr: (1 << self rememberedBitShift).
	((self longAt: oop) bitAnd: unusedBitsInYoungObjects) ~= 0 ifTrue:
		[self error: 'some header bits unused in young objects are set; should be zero'. ^false].
	^true

]

{ #category : #'object access' }
SpurMemoryManager >> oldRawNumSlotsOf: objOop [
	<returnTypeC: #usqInt>
	^self subclassResponsibility
]

{ #category : #'object enumeration' }
SpurMemoryManager >> oldSpaceObjectAfter: objOop [
	<api>
	"Object parsing.
	1. all objects have at least a word following the header, for a forwarding pointer.
	2. objects with an overflow size have a preceeing word with a saturated slotSize.  If the word following
	    an object doesn't have a saturated size field it must be a single-header object.  If the word following
	   does have a saturated slotSize it must be the overflow size word."
	<inline: false>
	^self objectAfter: objOop limit: endOfMemory
]

{ #category : #accessing }
SpurMemoryManager >> oldSpaceSize [
	^segmentManager totalBytesInSegments
]

{ #category : #accessing }
SpurMemoryManager >> oldSpaceStart [
	<cmacro: '() GIV(oldSpaceStart)'>
	^oldSpaceStart
]

{ #category : #'become implementation' }
SpurMemoryManager >> outOfPlaceBecome: obj1 and: obj2 copyHashFlag: copyHashFlag [
	<inline: #never> "in an effort to fix a compiler bug with two-way become post r3427"
	"Allocate two new objects, n1 & n2.  Copy the contents appropriately. Convert
	 obj1 and obj2 into forwarding objects pointing to n2 and n1 respectively"
	| clone1 clone2 |
	clone1 := (self isContextNonImm: obj1)
				ifTrue: [coInterpreter cloneContext: obj1]
				ifFalse: [self clone: obj1].
	clone2 := (self isContextNonImm: obj2)
				ifTrue: [coInterpreter cloneContext: obj2]
				ifFalse: [self clone: obj2].
	(self isObjImmutable: obj1) ifTrue:
		[self setIsImmutableOf: clone1 to: true].
	(self isObjImmutable: obj2) ifTrue:
		[self setIsImmutableOf: clone2 to: true].
	copyHashFlag
		ifTrue:
			[self setHashBitsOf: clone1 to: (self rawHashBitsOf: obj1).
			 self setHashBitsOf: clone2 to: (self rawHashBitsOf: obj2)]
		ifFalse:
			[self setHashBitsOf: clone1 to: (self rawHashBitsOf: obj2).
			 self setHashBitsOf: clone2 to: (self rawHashBitsOf: obj1)].
	self
		forward: obj1 to: clone2;
		forward: obj2 to: clone1.
	((self isYoungObject: obj1) ~= (self isYoungObject: clone2)
	 or: [(self isYoungObject: obj2) ~= (self isYoungObject: clone1)]) ifTrue:
		[becomeEffectsFlags := becomeEffectsFlags bitOr: OldBecameNewFlag]
]

{ #category : #'simulation only' }
SpurMemoryManager >> ownVM: flags [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter ownVM: flags
]

{ #category : #accessing }
SpurMemoryManager >> pastSpaceStart [
	<cmacro: '() GIV(pastSpaceStart)'>
	^pastSpaceStart
]

{ #category : #'primitive support' }
SpurMemoryManager >> pinObject: objOop [
	"Attempt to pin objOop, which must not be immediate.
	 If the attempt succeeds answer objOop's (possibly moved) oop.
	 If the attempt fails, which can only occur if there is no memory, answer 0."
	<inline: false>
	| oldClone seg |
	<var: #seg type: #'SpurSegmentInfo *'>
	self assert: (self isNonImmediate: objOop).
	self flag: 'policy decision here. if already old, do we clone in a segment containing pinned objects or merely pin?'.
	"We choose to clone to keep pinned objects together to reduce fragmentation,
	 if the object is not too large, assuming that pinning is rare and that fragmentation is a bad thing.
	 Too large is defined as over 1mb.  The size of a 640x480x4 bitmap is 1228800."
	(self isOldObject: objOop) ifTrue:
		[(self numBytesOf: objOop) > (1024 * 1024) ifTrue:
			[self setIsPinnedOf: objOop to: true.
			 ^objOop].
		 seg := segmentManager segmentContainingObj: objOop.
		 seg containsPinned ifTrue:
			[self setIsPinnedOf: objOop to: true.
			 ^objOop].
		 segmentManager someSegmentContainsPinned ifFalse:
			[self setIsPinnedOf: objOop to: true.
			 seg containsPinned: true.
			 ^objOop]].
	oldClone := self cloneInOldSpace: objOop forPinning: true.
	oldClone ~= 0 ifTrue:
		[becomeEffectsFlags := self becomeEffectFlagsFor: objOop.
		 self setIsPinnedOf: oldClone to: true.
		 self forward: objOop to: oldClone.
		 self followSpecialObjectsOop.
		 coInterpreter postBecomeAction: becomeEffectsFlags.
		 self postBecomeScanClassTable: becomeEffectsFlags.
		 becomeEffectsFlags := 0].
	^oldClone
]

{ #category : #'header format' }
SpurMemoryManager >> pinnedBitShift [
	<cmacro>
	"bit 1 of 3-bit field above format (little endian)"
	^30
]

{ #category : #'simulation only' }
SpurMemoryManager >> pop: nItems [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter pop: nItems
]

{ #category : #'simulation only' }
SpurMemoryManager >> pop: nItems thenPush: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter pop: nItems thenPush: oop
]

{ #category : #'obj stacks' }
SpurMemoryManager >> popObjStack: objStack [
	| topx top nextPage myx |
	self eassert: [self isValidObjStack: objStack].
	topx := self fetchPointer: ObjStackTopx ofObject: objStack.
	topx = 0 ifTrue:
		[self assert: (self fetchPointer: ObjStackNextx ofObject: objStack) = 0.
		 self cCode: [] "for debugging markAndTrace: set (MarkStackRecord := OrderedCollection new)"
			inSmalltalk:
				[(self fetchPointer: ObjStackMyx ofObject: objStack) = MarkStackRootIndex ifTrue:
					[MarkStackRecord ifNotNil:
						[MarkStackRecord addLast: {#EMPTY. nil}]]].
		^nil].
	topx := topx - 1.
	top := self fetchPointer: topx + ObjStackFixedSlots ofObject: objStack.
	self cCode: [] "for debugging markAndTrace: set (MarkStackRecord := OrderedCollection new)"
		inSmalltalk:
			[(self fetchPointer: ObjStackMyx ofObject: objStack) = MarkStackRootIndex ifTrue:
				[MarkStackRecord ifNotNil:
					[(MarkStackRecord last first = #push and: [MarkStackRecord last last = top])
						ifTrue: [MarkStackRecord removeLast]
						ifFalse: [MarkStackRecord addLast: {#pop. top}]]]].
	self storePointer: ObjStackTopx ofObjStack: objStack withValue: topx.
	(topx = 0
	 and: [(nextPage := self fetchPointer: ObjStackNextx ofObject: objStack) ~= 0])
		ifTrue:
			[self storePointer: ObjStackFreex ofObjStack: nextPage withValue: objStack.
			 self storePointer: ObjStackNextx ofObjStack: objStack withValue: 0.
			 myx := self fetchPointer: ObjStackMyx ofObject: objStack.
			 self updateRootOfObjStackAt: myx with: nextPage.
			 self eassert: [self isValidObjStack: nextPage]]
		ifFalse:
			[self eassert: [self isValidObjStack: objStack]].
	^top
]

{ #category : #'interpreter access' }
SpurMemoryManager >> popRemappableOop [
	"Pop and return the possibly remapped object from the remap buffer.
	 We support this excessence for compatibility with ObjectMemory.
	 Spur doesn't GC during allocation."
	<api>
	| oop |
	oop := remapBuffer at: remapBufferCount.
	remapBufferCount := remapBufferCount - 1.
	^oop
]

{ #category : #'simulation only' }
SpurMemoryManager >> positive32BitIntegerFor: integerValue [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter positive32BitIntegerFor: integerValue
]

{ #category : #'simulation only' }
SpurMemoryManager >> positive32BitValueOf: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter positive32BitValueOf: oop
]

{ #category : #'simulation only' }
SpurMemoryManager >> positive64BitIntegerFor: integerValue [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter positive64BitIntegerFor: integerValue
]

{ #category : #'simulation only' }
SpurMemoryManager >> positive64BitValueOf: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter positive64BitValueOf: oop
]

{ #category : #'simulation only' }
SpurMemoryManager >> positiveMachineIntegerFor: integerValue [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter positiveMachineIntegerFor: integerValue
]

{ #category : #'simulation only' }
SpurMemoryManager >> positiveMachineIntegerValueOf: integerValue [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter positiveMachineIntegerValueOf: integerValue
]

{ #category : #'store check' }
SpurMemoryManager >> possibleRootStoreInto: destObj [
	<inline: true>
	(self isRemembered: destObj) ifFalse:
		[scavenger remember: destObj]
]

{ #category : #'become implementation' }
SpurMemoryManager >> postBecomeScanClassTable: effectsFlags [
	"Scan the class table post-become (iff an active class object was becommed) to ensure no
	 forwarding pointers, and no unhashed classes exist in the class table.

	 Note that one-way become can cause duplications in the class table.
	 When can these be eliminated?  We use the classTableBitmap to mark classTable entries
	 (not the classes themselves, since marking a class doesn't help in knowing if its index is used).
	 On image load, and during incrememtal scan-mark and full GC, classIndices are marked.
	 We can somehow avoid following classes from the classTable until after this mark phase."
	self assert: self validClassTableRootPages.

	(effectsFlags anyMask: BecamePointerObjectFlag) ifFalse: [^self].

	0 to: numClassTablePages - 1 do:
		[:i| | page |
		page := self fetchPointer: i ofObject: hiddenRootsObj.
		self assert: (self isForwarded: page) not.
		0 to: (self numSlotsOf: page) - 1 do:
			[:j| | classOrNil |
			classOrNil := self fetchPointer: j ofObject: page.
			classOrNil ~= nilObj ifTrue:
				[(self isForwarded: classOrNil) ifTrue:
					[classOrNil := self followForwarded: classOrNil.
					 self storePointer: j ofObject: page withValue: classOrNil].
				 (self rawHashBitsOf: classOrNil) = 0 ifTrue:
					[self storePointerUnchecked: j ofObject: page withValue: nilObj.
					 "If the removed class is before the classTableIndex, set the
					  classTableIndex to point to the empty slot so as to reuse it asap."
					 (i << self classTableMajorIndexShift + j) < classTableIndex ifTrue:
						[classTableIndex := i << self classTableMajorIndexShift + j]]]]].
	"classTableIndex must never index the first page, which is reserved for classes known to the VM."
	self assert: classTableIndex >= (1 << self classTableMajorIndexShift)
]

{ #category : #snapshot }
SpurMemoryManager >> postSnapshot [
	<doNotGenerate>
	segmentManager postSnapshot
]

{ #category : #compaction }
SpurMemoryManager >> prepareObjStackForPlanningCompactor: objStack [
	"SpurPlanningCompactor overwrites the first fields of all moved objects, and saves these
	 fields in a data structure from which they can only be retrieved while scanning the heap.
	 The first field of an objStack page is its stack index, and so to know how many fields in an
	 objStack page to update it is necessary to save the ObjStackTopx field somewhere temporarily.
	 We use the hash field."

	| stackOrNil |
	objStack = nilObj ifTrue:
		[^self].
	stackOrNil := objStack.
	[self assert: (self numSlotsOfAny: stackOrNil) = ObjStackPageSlots.
	 self setHashBitsOf: stackOrNil to: (self fetchPointer: ObjStackTopx ofObject: stackOrNil).
	 (stackOrNil := self fetchPointer: ObjStackNextx ofObject: stackOrNil) ~= 0] whileTrue
]

{ #category : #compaction }
SpurMemoryManager >> prepareObjStacksForPlanningCompactor [
	"SpurPlanningCompactor overwrites the first fields of all moved objects, and saves these
	 fields in a data structure from which they can only be retrieved while scanning the heap.
	 The first field of an objStack page is its stack index, and so to know how many fields in an
	 objStack page to update it is necessary to save the ObjStackTopx field somewhere temporarily.
	 We use the hash field."

	self
		prepareObjStackForPlanningCompactor: markStack;
		prepareObjStackForPlanningCompactor: weaklingStack;
		prepareObjStackForPlanningCompactor: mournQueue
]

{ #category : #accessing }
SpurMemoryManager >> primitiveErrorTable [
	<api>
	^self splObj: PrimErrTableIndex
]

{ #category : #'simulation only' }
SpurMemoryManager >> primitiveFail [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter primitiveFail
]

{ #category : #'simulation only' }
SpurMemoryManager >> primitiveFailFor: reasonCode [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter primitiveFailFor: reasonCode
]

{ #category : #'simulation only' }
SpurMemoryManager >> primitiveFailForFFIException: errorCode at: pc [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter primitiveFailForFFIException: errorCode at: pc
]

{ #category : #'simulation only' }
SpurMemoryManager >> primitiveFailForOSError: reasonCode [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter primitiveFailForOSError: reasonCode
]

{ #category : #'simulation only' }
SpurMemoryManager >> primitiveFailureCode [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter primitiveFailureCode
]

{ #category : #'debug printing' }
SpurMemoryManager >> print64BitMemoryFrom: start to: end [
	<doNotGenerate>
	| wordSize64 address |
	wordSize64 := 8.
	address := start bitAnd: (wordSize64 - 1) bitInvert.
	[address < end] whileTrue:
		[coInterpreter printHex: address; printChar: $:; space; printHex: (self long64At: address); cr.
		 address := address + wordSize64]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printActivationsOf: aMethodObj [
	"Scan the heap printing the oops of any and all contexts that refer to anOop"
	<api>
	self allObjectsDo:
		[:obj| 
		 ((self isContextNonImm: obj)
		  and: [aMethodObj = (self fetchPointer: MethodIndex ofObject: obj)]) ifTrue:
			[coInterpreter
				printHex: obj; space; printOopShort: obj; print: ' pc ';
				printHex: (self fetchPointer: InstructionPointerIndex ofObject: obj); cr]]
]

{ #category : #'debug support' }
SpurMemoryManager >> printAdjacentFreeChunks [
	"self printAdjacentFreeChunks"
	<doNotGenerate>
	| uncoalesced |
	uncoalesced := OrderedCollection new.
	self allOldSpaceEntitiesDo:
		[:e| | s |
		((self isFreeObject: e)
		 and: [(s := self objectAfter: e limit: endOfMemory) < endOfMemory
		 and: [self isFreeObject: s]]) ifTrue:
			[uncoalesced addLast: e]].
	uncoalesced do:
		[:f|
		self printFreeChunk: f. coInterpreter printHexnp: (self objectAfter: f limit: endOfMemory); cr] 

]

{ #category : #'debug printing' }
SpurMemoryManager >> printBogons [
	<api>
	compactor printTheBogons: bogon
]

{ #category : #'debug printing' }
SpurMemoryManager >> printContextReferencesTo: anOop [
	"Scan the heap printing the oops of any and all contexts that refer to anOop"
	<api>
	self allObjectsDo:
		[:obj| | i |
		 (self isContextNonImm: obj) ifTrue:
			[i := CtxtTempFrameStart + (coInterpreter fetchStackPointerOf: obj).
			 [(i := i - 1) >= 0] whileTrue:
				[anOop = (self fetchPointer: i ofObject: obj) ifTrue:
					[coInterpreter
						printHex: obj; print: ' @ '; printNum: i; space; printOopShort: obj;
						print: ' pc '; printHex: (self fetchPointer: InstructionPointerIndex ofObject: obj); cr.
					 i := 0]]]]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printEntity: oop [
	<api>
	| printFlags |
	printFlags := false.
	coInterpreter printHex: oop; space.
	(self addressCouldBeObj: oop) ifFalse:
		[^coInterpreter print: ((self isImmediate: oop) ifTrue: ['immediate'] ifFalse: ['unknown'])].
	coInterpreter
		print: ((self isFreeObject: oop) ifTrue: ['free'] ifFalse:
				[(self isSegmentBridge: oop) ifTrue: ['bridge'] ifFalse:
				[(self isForwarded: oop) ifTrue: ['forwarder'] ifFalse:
				[(self classIndexOf: oop) <= self lastClassIndexPun ifTrue: [printFlags := true. 'pun/obj stack'] ifFalse:
				[printFlags := true. 'object']]]]);
		space; printHexnpnp: (self rawNumSlotsOf: oop); print: '/'; printHexnpnp: (self bytesInObject: oop); print: '/'; printNum: (self bytesInObject: oop).
	printFlags ifTrue:
		[coInterpreter
			space;
			print: ((self formatOf: oop) <= 16rF ifTrue: ['f:0'] ifFalse: ['f:']);
			printHexnpnp: (self formatOf: oop);
			print: ((self isGrey: oop) ifTrue: [' g'] ifFalse: [' .']);
			print: ((self isImmutable: oop) ifTrue: ['i'] ifFalse: ['.']);
			print: ((self isMarked: oop) ifTrue: ['m'] ifFalse: ['.']);
			print: ((self isPinned: oop) ifTrue: ['p'] ifFalse: ['.']);
			print: ((self isRemembered: oop) ifTrue: ['r'] ifFalse: ['.'])].
	coInterpreter cr
]

{ #category : #'debug printing' }
SpurMemoryManager >> printForwarders [
	<api>
	self allHeapEntitiesDo:
		[:objOop|
		 (self isUnambiguouslyForwarder: objOop) ifTrue:
			[coInterpreter printHex: objOop; cr]]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printFreeChunk: freeChunk [
	<api>
	self printFreeChunk: freeChunk printAsTreeNode: true
]

{ #category : #'debug printing' }
SpurMemoryManager >> printFreeChunk: freeChunk printAsTreeNode: printAsTreeNode [
	| numBytes |
	numBytes := self bytesInObject: freeChunk.
	coInterpreter
		print: 'freeChunk '; printHexPtrnp: freeChunk.
	printAsTreeNode ifTrue:
		[coInterpreter
			print: ((freeChunk = (freeLists at: 0)) ifTrue: [' + '] ifFalse: [' - ']);
			printHexPtrnp:(self addressAfter: freeChunk)].
	coInterpreter
		print: ' bytes '; printNum: numBytes;
		print: ' next '; printHexPtrnp: (self fetchPointer: self freeChunkNextIndex
											ofFreeChunk: freeChunk).
	(self isLilliputianSize: numBytes) ifFalse: 
		[coInterpreter
			print: ' prev '; printHexPtrnp: (self fetchPointer: self freeChunkPrevIndex
											ofFreeChunk: freeChunk).].
	(numBytes >= (self numFreeLists * self allocationUnit)
	 and: [printAsTreeNode]) ifTrue:
		[coInterpreter
			print: ' ^ '; printHexPtrnp: (self fetchPointer: self freeChunkParentIndex
											ofFreeChunk: freeChunk);
			print: ' < '; printHexPtrnp: (self fetchPointer: self freeChunkSmallerIndex
											ofFreeChunk: freeChunk);
			print: ' > '; printHexPtrnp: (self fetchPointer: self freeChunkLargerIndex
											ofFreeChunk: freeChunk)].
	coInterpreter cr
]

{ #category : #'debug support' }
SpurMemoryManager >> printFreeChunks [
	"This version goes through memory, printing all free chunks.
	 Other versions go through the free lists.  This one will show
	 all free chunks even if the free lists are corrupt."
	<api>
	| seenNewFreeChunk |
	seenNewFreeChunk := false.
	self allNewSpaceEntitiesDo:
		[:o|
		(self isFreeObject: o) ifTrue:
			[seenNewFreeChunk ifFalse:
				[coInterpreter print: 'NewSpace CONTAINS FREE OBJECT(S)!!'; cr.
				 seenNewFreeChunk := true].
			 self printFreeChunk: o]].
	self allOldSpaceEntitiesDo:
		[:o|
		(self isFreeObject: o) ifTrue:
			[self printFreeChunk: o]]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printFreeList: chunkOrIndex [
	<api>
	| freeChunk |
	(chunkOrIndex >= 0 and: [chunkOrIndex < self numFreeLists]) ifTrue:
		[^self printFreeList: (freeLists at: chunkOrIndex)].
	freeChunk := chunkOrIndex.
	[freeChunk ~= 0] whileTrue:
		[self printFreeChunk: freeChunk.
		 freeChunk := self fetchPointer: self freeChunkNextIndex ofFreeChunk: freeChunk]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printFreeListHeads [
	<api>
	| expectedMask |
	expectedMask := 0.
	0 to: self numFreeLists - 1 do:
		[:i|
		coInterpreter printHex: (freeLists at: i).
		(freeLists at: i) ~= 0 ifTrue:
			[expectedMask := expectedMask + (1 << i)].
		i + 1 \\ (32 >> self logBytesPerOop) = 0
			ifTrue: [coInterpreter cr]
			ifFalse: [coInterpreter print: '  ']].
	coInterpreter
		cr;
		print: 'mask: '; printHexnp: freeListsMask;
		print: ' expected: '; printHexnp: expectedMask;
		cr
]

{ #category : #'debug printing' }
SpurMemoryManager >> printFreeTree [
	<api>
	self printFreeTreeChunk: (freeLists at: 0)
]

{ #category : #'debug printing' }
SpurMemoryManager >> printFreeTreeChunk: chunkOrZero [
	<inline: false> "Slang is blind-sided by the inlining of printFreeTreeChunk: into printFreeTree."
	chunkOrZero > 0 ifTrue:
		[self printFreeTreeChunk: (self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: chunkOrZero).
		 self printFreeChunk: chunkOrZero.
		 self printFreeTreeChunk: (self fetchPointer: self freeChunkLargerIndex ofFreeChunk: chunkOrZero)]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printHeaderOf: objOop [
	<api>
	"N.B. No safety bounds checks!!  We need to look e.g. at corpses."
	coInterpreter printHexnp: objOop.
	(self numSlotsOfAny: objOop) >= self numSlotsMask
		ifTrue: [coInterpreter
					print: ' hdr16 slotf '; printHexnp: (self numSlotsOfAny: objOop - self allocationUnit);
					print: ' slotc '; printHexnp: (self rawOverflowSlotsOf: objOop); space]
		ifFalse: [coInterpreter print: ' hdr8 slots '; printHexnp: (self numSlotsOfAny: objOop)].
	coInterpreter
		space;
		printChar: ((self isMarked: objOop) ifTrue: [$M] ifFalse: [$m]);
		printChar: ((self isGrey: objOop) ifTrue: [$G] ifFalse: [$g]);
		printChar: ((self isPinned: objOop) ifTrue: [$P] ifFalse: [$p]);
		printChar: ((self isRemembered: objOop) ifTrue: [$R] ifFalse: [$r]);
		printChar: ((self isImmutable: objOop) ifTrue: [$I] ifFalse: [$i]);
		print: ' hash '; printHexnp: (self rawHashBitsOf: objOop);
		print: ' fmt '; printHexnp: (self formatOf: objOop);
		print: ' cidx '; printHexnp: (self classIndexOf: objOop);
		cr
]

{ #category : #'debug printing' }
SpurMemoryManager >> printHeaderTypeOf: objOop [
	coInterpreter
		print: ((self numSlotsOfAny: objOop) >= self numSlotsMask
					ifTrue: [' hdr16 ']
					ifFalse: [' hdr8 ']);
		printChar: ((self isImmutable: objOop) ifTrue: [$i] ifFalse: [$.]);
		printChar: ((self isRemembered: objOop) ifTrue: [$r] ifFalse: [$.]);
		printChar: ((self isPinned: objOop) ifTrue: [$p] ifFalse: [$.]);
		printChar: ((self isMarked: objOop) ifTrue: [$m] ifFalse: [$.]);
		printChar: ((self isGrey: objOop) ifTrue: [$g] ifFalse: [$.])
]

{ #category : #'debug printing' }
SpurMemoryManager >> printInstancesOf: aClassOop [
	"Scan the heap printing the oops of any and all objects that are instances of aClassOop"
	<api>
	| classIndex |
	classIndex := self rawHashBitsOf: aClassOop.
	classIndex ~= self isFreeObjectClassIndexPun ifTrue:
		[self printInstancesWithClassIndex: classIndex]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printInstancesWithClassIndex: classIndex [
	"Scan the heap printing the oops of any and all objects whose classIndex equals the argument."
	<api>
	<inline: false>
	self allHeapEntitiesDo:
		[:obj|
		 (self classIndexOf: obj) = classIndex ifTrue:
			[coInterpreter printHex: obj; cr]]
]

{ #category : #'class table' }
SpurMemoryManager >> printInvalidClassTableEntries [
	"Print the objects in the classTable that have bad hashes."
	<api>
	self validClassTableRootPages ifFalse:
		[coInterpreter print: 'class table invalid; cannot print'; cr.
		 ^self].

	self classTableEntriesDo:
		[:classOrNil :index| | hash |
		 ((self isForwarded: classOrNil)
		  or: [(hash := self rawHashBitsOf: classOrNil) = 0
		  or: [(self noCheckClassAtIndex: hash) ~= classOrNil]]) ifTrue:
			[coInterpreter
				print: 'entry '; printHex: index;
				print: ' oop '; printHex: classOrNil;
				print: ' hash '; printHex: hash; print: ' => '; printHex: (self classAtIndex: hash);
				cr]]
]

{ #category : #'class table' }
SpurMemoryManager >> printInvalidClassTableHashes [
	"Print the entries in the classTable that have invalid hashes."

	self validClassTableRootPages ifFalse:
		[^false].

	self classTableEntriesDo:
		[:entry :index| | hash |
		 (self isForwarded: entry)
			ifTrue:
				[coInterpreter printHex: entry; print: ' @ '; printHex: index; print: ' forwarder']
			ifFalse:
				[hash := self rawHashBitsOf: entry.
				 hash = 0
					ifTrue:
						[coInterpreter printHex: entry; print: ' @ '; printHex: index; print: ' no hash']
					ifFalse:
						[(self noCheckClassAtIndex: hash) ~= entry ifTrue:
							[coInterpreter printHex: entry; print: ' @ '; printHex: index; print: ' bad hash: '; printHex: hash]]]]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printMarkedOops [
	<api>
	<option: #LLDB>
	self printOopsSuchThat: #isMarked
]

{ #category : #'debug printing' }
SpurMemoryManager >> printMemoryFrom: start to: end [
	<doNotGenerate>
	| address |
	address := start bitAnd: (self wordSize - 1) bitInvert.
	[address < end] whileTrue:
		[coInterpreter printHex: address; printChar: $:; space; printHex: (self longAt: address); cr.
		 address := address + self wordSize]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printMethodImplementorsOf: anOop [
	"Scan the heap printing the oops of any and all methods that implement anOop"
	<api>
	self allObjectsDo:
		[:obj|
		 ((self isCompiledMethod: obj)
		  and: [(coInterpreter maybeSelectorOfMethod: obj) = anOop]) ifTrue:
			[coInterpreter printHex: obj; space; printOopShort: obj; cr]]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printMethodReferencesTo: anOop [
	"Scan the heap printing the oops of any and all methods that refer to anOop"
	<api>
	self allObjectsDo:
		[:obj| | i |
		 (self isCompiledMethod: obj) ifTrue:
			[i := (self literalCountOf: obj) + LiteralStart - 1.
			[(i := i - 1) >= 0] whileTrue:
				[anOop = (self fetchPointer: i ofObject: obj) ifTrue:
					[coInterpreter printHex: obj; print: ' @ '; printNum: i; space; printOopShort: obj; cr.
					 i := 0]]]]
]

{ #category : #'obj stacks' }
SpurMemoryManager >> printObjStack: objStack [
	<api>
	objStack = nilObj
		ifTrue:
			[coInterpreter print: 'nil'; cr]
		ifFalse:
			[self printObjStackPage: objStack
				myIndex: (self fetchPointer: ObjStackMyx ofObject: objStack)
				pageType: ObjStackMyx]
]

{ #category : #'obj stacks' }
SpurMemoryManager >> printObjStackPage: objStackPage myIndex: myx pageType: pageType [
	| freeOrNextPage page isFirstPage isNextPage isFreePage |
	<inline: false>
	isFirstPage := pageType = ObjStackMyx.
	isNextPage := pageType = ObjStackNextx.
	isFreePage := pageType = ObjStackFreex.
	self printObjStackPage: objStackPage
		myIndex: myx
		tag: (isFirstPage ifTrue: ['head'] ifFalse: [isFreePage ifTrue: ['free'] ifFalse: ['next']]).
	(isFirstPage or: [isNextPage]) ifTrue:
		[coInterpreter tab; print: 'topx: '; printNum: (self fetchPointer: ObjStackTopx ofObject: objStackPage); print: ' next: '; printHex: (self fetchPointer: ObjStackNextx ofObject: objStackPage).
		 isFirstPage ifTrue:
			[coInterpreter print: ' free: '; printHex: (self fetchPointer: ObjStackFreex ofObject: objStackPage)].
		 coInterpreter cr].
	isFirstPage ifTrue:
		[freeOrNextPage := self fetchPointer: ObjStackFreex ofObject: objStackPage.
		 [freeOrNextPage ~= 0] whileTrue:
			[self printObjStackPage: freeOrNextPage myIndex: myx pageType: ObjStackFreex.
			 page := self fetchPointer: ObjStackFreex ofObject: freeOrNextPage.
			 (page = freeOrNextPage
			  or: [page = objStackPage]) ifTrue:
				[coInterpreter print: 'circularity in free page list!!'; cr.
				 page := 0].
			 freeOrNextPage := page]].
	freeOrNextPage := self fetchPointer: ObjStackNextx ofObject: objStackPage.
	freeOrNextPage ~= 0 ifTrue:
		[self printObjStackPage: freeOrNextPage myIndex: myx pageType: ObjStackNextx]
]

{ #category : #'obj stacks' }
SpurMemoryManager >> printObjStackPage: objStackPage myIndex: myx tag: pageType [
	<var: 'pageType' type: #'char *'>
	<inline: false>
	coInterpreter
		print: pageType; space; printHex: objStackPage; space;
		print: 'cx '; printNum: (self classIndexOf: objStackPage);
		print: ' ('; printNum: self wordSizeClassIndexPun;
		print: ') fmt '; printNum: (self formatOf: objStackPage);
		print: ' ('; printNum: self wordIndexableFormat;
		print: ') sz '; printNum: (self numSlotsOfAny: objStackPage);
		print: ' ('; printNum: ObjStackPageSlots;
		print: ') myx: '; printNum: (self fetchPointer: ObjStackMyx ofObject: objStackPage);
		print: ' ('; printNum: myx;
		print: ((self isMarked: objStackPage) ifTrue: [') mkd'] ifFalse: [') unmkd']);
		cr
]

{ #category : #'debug printing' }
SpurMemoryManager >> printObjectsFrom: startAddress to: endAddress [
	<api>
	| oop |
	oop := self objectBefore: startAddress.
	oop := oop
				ifNil: [startAddress]
				ifNotNil: [(self objectAfter: oop) = startAddress
							ifTrue: [startAddress]
							ifFalse: [oop]].
	[self oop: oop isLessThan: endAddress] whileTrue:
		[((self isFreeObject: oop)
		 or: [self isSegmentBridge: oop]) ifFalse:
			[coInterpreter printOop: oop].
		oop := self objectAfter: oop]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printObjectsWithHash: hash [
	"Scan the heap printing the oops of any and all objects whose hash equals the argument."
	<api>
	self allHeapEntitiesDo:
		[:obj|
		 (self rawHashBitsOf: obj) = hash ifTrue:
			[coInterpreter shortPrintOop: obj; cr]]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printOopsExcept: function [
	<api>
	<var: #function declareC: 'sqInt (*function)(sqInt)'>
	<inline: #never>
	| n |
	n := 0.
	self allHeapEntitiesDo:
		[:o|
		(self perform: function with: o) ifFalse:
			[n := n + 1.
			 self printEntity: o]].
	n > 4 ifTrue: "rabbits"
		[self printNum: n; print: ' objects'; cr]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printOopsFrom: startAddress to: endAddress [
	<api>
	| oop limit firstNonEntity inEmptySpace lastNonEntity |
	oop := self objectBefore: startAddress.
	limit := endAddress asUnsignedIntegerPtr min: endOfMemory.
	oop := oop
				ifNil: [startAddress]
				ifNotNil: [(self objectAfter: oop) = startAddress
							ifTrue: [startAddress]
							ifFalse: [oop]].
	inEmptySpace := false.
	[self oop: oop isLessThan: limit] whileTrue:
		[self printEntity: oop.
		 [oop := self objectAfter: oop.
		  (self long64At: oop) = 0] whileTrue:
			[inEmptySpace ifFalse:
				[inEmptySpace := true.
				 firstNonEntity := oop].
			 lastNonEntity := oop].
		 inEmptySpace ifTrue:
			[inEmptySpace := false.
			 coInterpreter
				print: 'skipped empty space from '; printHexPtrnp: firstNonEntity;
				print:' to '; printHexPtrnp: lastNonEntity; cr.
			 oop := self objectStartingAt: oop]]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printOopsSuchThat: function [
	<api>
	<var: #function declareC: 'sqInt (*function)(sqInt)'>
	<inline: #never>
	| n |
	n := 0.
	self allHeapEntitiesDo:
		[:o|
		(self perform: function with: o) ifTrue:
			[n := n + 1.
			 self printEntity: o]].
	n > 4 ifTrue: "rabbits"
		[self printNum: n; print: ' objects'; cr]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printReferencesTo: anOop [
	"Scan the heap printing the oops of any and all objects that refer to anOop"
	<api>
	self allObjectsDo:
		[:obj| | i |
		 i := self numPointerSlotsOf: obj.
		 [(i := i - 1) >= 0] whileTrue:
			[anOop = (self fetchPointer: i ofMaybeForwardedObject: obj) ifTrue:
				[coInterpreter printHex: obj; print: ' @ '; printNum: i; space; printOopShort: obj; cr.
				 i := 0]]]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printUnmarkedOops [
	<api>
	<option: #LLDB>
	self printOopsExcept: #isMarked
]

{ #category : #'class table' }
SpurMemoryManager >> purgeDuplicateClassTableEntriesFor: aClass [
	"Given that either marking or allInstances has ensured that
	 all instances of aClass have the class's hash as their class
	 index, ensure aClass is in the table only at its hash (or a pun)."
	| expectedIndex |
	expectedIndex := self rawHashBitsOf: aClass.
	self classTableEntriesDo:
		[:entry :index|
		 (entry = aClass
		  and: [index ~= expectedIndex
		  and: [index > self lastClassIndexPun]]) ifTrue:
			[self classAtIndex: index put: nilObj.
			 index < classTableIndex ifTrue:
				[classTableIndex := index]]].
	"classTableIndex must never index the first page, which is reserved for classes known to the VM."
	self assert: classTableIndex >= (1 << self classTableMajorIndexShift)
]

{ #category : #'simulation only' }
SpurMemoryManager >> push: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter push: oop
]

{ #category : #'obj stacks' }
SpurMemoryManager >> push: objOop onObjStack: objStack [
	<inline: true>
	self assert: (self addressCouldBeOop: objOop).
	(self isImmediate: objOop)
		ifTrue:
			[self assert: objStack = markStack.
			 self assert: (self addressCouldBeObj: (self topOfObjStack:
							(0 = (self fetchPointer: ObjStackTopx ofObject: objStack)
								ifTrue: [self fetchPointer: ObjStackNextx ofObject: objStack]
								ifFalse: [objStack])))]
		ifFalse: "There should be no weaklings on the mark stack."
			[self assert: (objStack = markStack and: [self isWeakNonImm: objOop]) not.
			"There should only be weaklings on the weaklingStack"
			 self assert: (objStack ~= weaklingStack or: [self isWeakNonImm: objOop])].
	^self noCheckPush: objOop onObjStack: objStack
]

{ #category : #'simulation only' }
SpurMemoryManager >> pushBool: trueOrFalse [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter pushBool: trueOrFalse
]

{ #category : #'simulation only' }
SpurMemoryManager >> pushFloat: f [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter pushFloat: f
]

{ #category : #'simulation only' }
SpurMemoryManager >> pushInteger: integerValue [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter pushInteger: integerValue
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> pushOnUnscannedEphemeronsStack: anEphemeron [
	"Attempt to push anEphemeron on the unscanned ephemerons stack
	 and answer if the attempt succeeded.  Note that the ephemeron
	 stack overflowing isn't a disaster; it simply means treating the
	 ephemeron as strong in this GC cycle."
	<inline: false>
	self assert: (self isEphemeron: anEphemeron).
	unscannedEphemerons top >= unscannedEphemerons limit ifTrue:
		[^false].
	self longAt: unscannedEphemerons top put: anEphemeron.
	unscannedEphemerons top: unscannedEphemerons top + self bytesPerOop.
	^true
]

{ #category : #'interpreter access' }
SpurMemoryManager >> pushRemappableOop: oop [
	"Record the given object in a the remap buffer. Objects in this buffer are remapped
	 when a compaction occurs. This facility is used by the interpreter to ensure that
	 objects in temporary variables are properly remapped.
	 We support this excessence for compatibility with ObjectMemory.
	 Spur doesn't GC during allocation."
	<api>
	self assert: (self addressCouldBeOop: oop).
	remapBuffer at: (remapBufferCount := remapBufferCount + 1) put: oop.
	remapBufferCount <= RemapBufferSize ifFalse:
		[self error: 'remapBuffer overflow']
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> queueMourner: anEphemeronOrWeakArray [
	"Add the ephemeron to the queue and make it non-ephemeral, to avoid subsequent firing.
	 Alas this means that other ephemerons on the same object not identified in this sccavenge
	 or GC will not fire until later.  But that's life."
	self assert: ((self isNonImmediate: anEphemeronOrWeakArray)
				and: [(self formatOf: anEphemeronOrWeakArray) = self ephemeronFormat
				   or: [(self formatOf: anEphemeronOrWeakArray) = self weakArrayFormat]]).
	self deny: ((self formatOf: anEphemeronOrWeakArray) = self ephemeronFormat
				and: [self is: anEphemeronOrWeakArray onObjStack: mournQueue]).
	self ensureRoomOnObjStackAt: MournQueueRootIndex.
	self push: anEphemeronOrWeakArray onObjStack: mournQueue
]

{ #category : #'interpreter access' }
SpurMemoryManager >> rawClassTagForClass: classObj [
	"Answer the classObj's identityHash to use as a tag in a class comparison."
	^self rawHashBitsOf: classObj
]

{ #category : #'header access' }
SpurMemoryManager >> rawHashBitsOf: objOop [
	<api>
	self flag: #endianness.
	^(self long32At: objOop + 4) bitAnd: self identityHashHalfWordMask
]

{ #category : #'object access' }
SpurMemoryManager >> rawNumSlotsOf: objOop [
	<returnTypeC: #usqInt>
	<inline: true>
	self flag: #endian.
	^self byteAt: objOop + 7
]

{ #category : #'object access' }
SpurMemoryManager >> rawNumSlotsOf: objOop put: aByte [
	<returnTypeC: #usqInt>
	<inline: true>
	self flag: #endian.
	^self byteAt: objOop + 7 put: aByte
]

{ #category : #'object access' }
SpurMemoryManager >> rawOverflowSlotsOf: objOop [
	<returnTypeC: #usqInt>
	self subclassResponsibility
]

{ #category : #'object access' }
SpurMemoryManager >> rawOverflowSlotsOf: objOop put: numSlots [
	<returnTypeC: #usqInt>
	self subclassResponsibility
]

{ #category : #snapshot }
SpurMemoryManager >> readHeapFromImageFile: f dataBytes: numBytes [
	"Read numBytes of image data from f into memory at memoryBaseForImageRead.
	 Answer the number of bytes written."
	<doNotGenerate>
	^segmentManager readHeapFromImageFile: f dataBytes: numBytes
]

{ #category : #compaction }
SpurMemoryManager >> relocateObjStackForPlanningCompactor: objStack [
	"Relocate all objStack pages that comprise objStack."
	| stackOrNil freeList next relocated result |
	objStack = nilObj ifTrue:
		[^objStack].
	stackOrNil := objStack.
	freeList := self fetchPointer: ObjStackFreex ofObject: objStack.
	[self assert: (self numSlotsOfAny: stackOrNil) = ObjStackPageSlots.
	 "There are four fixed slots in an obj stack, and a Topx of 0 indicates empty, so
	   if there were 5 slots in an oop stack, full would be 2, and the last 0-rel index is 4.
	   Hence the last index is topx + fixed slots - 1, or topx + ObjStackNextx"
	 next := self fetchPointer: ObjStackNextx ofObject: stackOrNil.
	 relocated := compactor
					relocateObjectsInHeapEntity: stackOrNil
					from: ObjStackFreex
					to: ObjStackNextx + (self rawHashBitsOf: stackOrNil).
	 stackOrNil = objStack ifTrue:
		[result := relocated].
	 self setHashBitsOf: stackOrNil to: 0.
	 next ~= 0]
		whileTrue:
			[stackOrNil := next].
	[freeList ~= 0] whileTrue:
		[self assert: (self numSlotsOfAny: freeList) = ObjStackPageSlots.
		 next := self fetchPointer: ObjStackFreex ofObject: freeList.
		 compactor
			relocateObjectsInHeapEntity: freeList
			from: ObjStackFreex
			to: ObjStackFreex.
		 freeList := next].
	^relocated
]

{ #category : #compaction }
SpurMemoryManager >> relocateObjStacksForPlanningCompactor [
	"Relocate all non-empty objStack pages, following the objStacks from the roots."

	markStack := self relocateObjStackForPlanningCompactor: markStack.
	weaklingStack := self relocateObjStackForPlanningCompactor: weaklingStack.
	mournQueue := self relocateObjStackForPlanningCompactor: mournQueue
]

{ #category : #'gc - global' }
SpurMemoryManager >> remap: oop [
	self shouldNotImplement
]

{ #category : #'interpreter access' }
SpurMemoryManager >> remapBuffer [
	"We support this excessence for compatibility with ObjectMemory.
	 Spur doesn't GC during allocation."
	^remapBuffer
]

{ #category : #accessing }
SpurMemoryManager >> remapBufferCount [
	<cmacro: '() GIV(remapBufferCount)'>
	^remapBufferCount
]

{ #category : #'gc - scavenge/compact' }
SpurMemoryManager >> remapObj: objOop [
	"Scavenge or simply follow objOop.  Answer the new location of objOop.
	 The send should have been guarded by a send of shouldRemapOop:.
	 The method is called remapObj: for compatibility with ObjectMemory.
	 Defer to the compactor to choose the actual method, there being a
	 difference between the vanilla method and that used with a sliding
	 compactor where objects are not marked as forwarded."
	<doNotGenerate>
	^compactor remapObj: objOop
]

{ #category : #'header format' }
SpurMemoryManager >> rememberedBitShift [
	<api>
	<cmacro>
	"bit 0 of 3-bit field above format (little endian)"
	^29
]

{ #category : #scavenger }
SpurMemoryManager >> rememberedSetObj [
	^self fetchPointer: RememberedSetRootIndex ofObject: hiddenRootsObj
]

{ #category : #scavenger }
SpurMemoryManager >> rememberedSetObj: anObj [
	self assert: (self isOldObject: anObj).
	self storePointerUnchecked: RememberedSetRootIndex ofObject: hiddenRootsObj withValue: anObj
]

{ #category : #'plugin support' }
SpurMemoryManager >> removeGCRoot: varLoc [
	"Remove the given variable location to the extra roots table."
	<api>
	<var: #varLoc type: #'sqInt *'>
	1 to: extraRootCount do:
		[:i|
		varLoc = (extraRoots at: i) ifTrue: "swap varLoc with last entry"
			[extraRoots at: i put: (extraRoots at: extraRootCount).
			 extraRootCount := extraRootCount - 1.
			 ^true]].
	^false "not found"
]

{ #category : #'allocation accounting' }
SpurMemoryManager >> resetAllocationAccountingAfterGC [
	"oldSpaceUsePriorToScavenge is used to maintain an accurate allocation count.
	 Since scavenging may tenure objects and tenuring does not count as allocation (that
	 would count twice) we must compute heapSizeAtPreviousGC after any tenuring.
	 fullGC reclaims space which does not count as deallocation (that would not count
	 allocations at all), so we must reset heapSizeAtPreviousGC after GC also."
	<inline: true>
	oldSpaceUsePriorToScavenge := segmentManager totalOldSpaceCapacity - totalFreeOldSpace
]

{ #category : #'free space' }
SpurMemoryManager >> resetFreeListHeads [
	freeListsMask := 0.
	0 to: self numFreeLists - 1 do:
		[:i| freeLists at: i put: 0]
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> restoreObjectsIn: objArray savedHashes: savedHashes [
	"This is part of storeImageSegmentInto:outPointers:roots:.
	 Enumerate the objects in objArray, unmarking them and restoring their hashes
	 from the corresponding 32-bit slots in savedHashes.  The first unused entry in
	 objArray will have a non-hash value entry in savedHashes.  Free savedHashes."
	<inline: true>
	0 to: (self numSlotsOf: objArray) - 1 do:
		[:i| | hash oop |
		(hash := self fetchLong32: i ofObject: savedHashes) > self maxIdentityHash ifTrue:
			[(self isInOldSpace: savedHashes) ifTrue:
				[self freeObject: savedHashes].
			 ^self].
		oop := self fetchPointer: i ofObject: objArray.
		self setHashBitsOf: oop to: hash.
		self setIsMarkedOf: oop to: false].
	(self isInOldSpace: savedHashes) ifTrue:
		[self freeObject: savedHashes]
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> restoreObjectsIn: objArray upTo: limitOrTag savedFirstFields: savedFirstFields [
	"This is part of storeImageSegmentInto:outPointers:roots:.
	 Enumerate the objects in objArray, unmarking them and restoring their saved first fields
	 from the corresponding slot in savedFirstFields.  The first unused entry in
	 objArray will have a non-hash value entry in savedHashes.  Free savedFirstFields."
	<inline: true>
	| numSlots |
	numSlots := limitOrTag = -1 ifTrue: [self numSlotsOf: objArray] ifFalse: [limitOrTag].
	0 to: numSlots - 1 do:
		[:i| | oop |
		oop := self fetchPointer: i ofObject: objArray.
		self storePointerUnchecked: 0 ofObject: oop withValue: (self fetchPointer: i ofObject: savedFirstFields).
		self setIsMarkedOf: oop to: false].
	(self isInOldSpace: savedFirstFields) ifTrue:
		[self freeObject: savedFirstFields]
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> return: errCode restoringObjectsIn: firstArray savedFirstFields: savedFirstFields and: secondArray savedHashes: savedHashes [
	<inline: false>
	"This is part of storeImageSegmentInto:outPointers:roots:."
	self cCode: [] inSmalltalk: [errCode ~= 0 ifTrue: [self halt]].
	self restoreObjectsIn: firstArray upTo: -1 savedFirstFields: savedFirstFields.
	self restoreObjectsIn: secondArray savedHashes: savedHashes.
	self runLeakCheckerFor: GCModeImageSegment.
	self assert: self allObjectsUnmarked.
	^errCode
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> return: errCode restoringObjectsIn: firstArray upTo: limitOrTag savedFirstFields: savedFirstFields [
	<inline: false>
	"This is part of storeImageSegmentInto:outPointers:roots:."
	self cCode: [] inSmalltalk: [errCode ~= 0 ifTrue: [self halt]].
	self restoreObjectsIn: firstArray upTo: limitOrTag savedFirstFields: savedFirstFields.
	self runLeakCheckerFor: GCModeImageSegment.
	self assert: self allObjectsUnmarked.
	^errCode
]

{ #category : #snapshot }
SpurMemoryManager >> reverseBytesFrom: startAddr to: stopAddr [
	"Byte-swap the given range of memory (not inclusive of stopAddr!)."
	| addr |
	addr := startAddr.
	[self oop: addr isLessThan: stopAddr] whileTrue:
		[self longAt: addr put: (self byteSwapped: (self longAt: addr)).
		addr := addr + self wordSize]
]

{ #category : #snapshot }
SpurMemoryManager >> reverseBytesIn32BitWordsFrom: startAddr to: stopAddr [
	"Byte-swap the given range of memory (not inclusive of stopAddr!)."
	| addr |
	addr := startAddr.
	[self oop: addr isLessThan: stopAddr] whileTrue:
		[self long32At: addr put: ((self long32At: addr) byteSwap32).
		 addr := addr + 4]
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> reverseBytesIn32BitWordsIn: segmentWordArray [
	"This exists to get around a compiler bug in Apple LLVM version 7.0.0 (clang-700.1.76)
	 that was avoiding the second comparison of segVersion after the first byte swap."
	<inline: #never>
	self reverseBytesIn32BitWordsFrom: segmentWordArray + self baseHeaderSize
		to: (self addressAfter: segmentWordArray)
]

{ #category : #snapshot }
SpurMemoryManager >> reverseBytesInMemory [
	self reverseBytesFrom: oldSpaceStart to: endOfMemory
]

{ #category : #scavenger }
SpurMemoryManager >> rootTableCapacity [
	<cmacro: '() GIV(rememberedSetLimit)'>
	^scavenger rememberedSetLimit
]

{ #category : #accessing }
SpurMemoryManager >> rootTableCount [
	<cmacro: '() GIV(rememberedSetSize)'>
	^scavenger rememberedSetSize
]

{ #category : #allocation }
SpurMemoryManager >> roundBytesToAllocationUnit: bytes [
	^bytes + (self allocationUnit - 1) bitClear: self allocationUnit - 1
]

{ #category : #snapshot }
SpurMemoryManager >> roundUpHeapSize: heapSize [
	<var: 'heapSize' type: #usqInt>
	| bit |
	bit := heapSize highBit - 1 * 3 // 4.
	^(heapSize anyMask: (1 << bit - 1))
		ifTrue: [(heapSize bitClear: (1 << bit - 1)) + (1 << bit)]
		ifFalse: [heapSize]
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> rtRefCountOf: obj [
	"Answer the rt reference count of obj; this is the three bit field comprised
	 of isGrey,isPinned,isRemembered.  See computeRefCountToShrinkRT."
	^(self longAt: obj) >> self rememberedBitShift bitAnd: MaxRTRefCount
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> rtRefCountOf: obj put: refCount [
	"Set the rt reference count of obj; this is the three bit field comprised
	 of isGrey,isPinned,isRemembered.  See computeRefCountToShrinkRT."
	self subclassResponsibility
]

{ #category : #'debug support' }
SpurMemoryManager >> runLeakCheckerFor: gcModes [
	<inline: false>
	^self
		inLineRunLeakCheckerFor: gcModes
		excludeUnmarkedObjs: false
		classIndicesShouldBeValid: true
]

{ #category : #'debug support' }
SpurMemoryManager >> runLeakCheckerFor: gcModes excludeUnmarkedObjs: excludeUnmarkedObjs classIndicesShouldBeValid: classIndicesShouldBeValid [
	<inline: false>
	self inLineRunLeakCheckerFor: gcModes
		excludeUnmarkedObjs: excludeUnmarkedObjs
		classIndicesShouldBeValid: classIndicesShouldBeValid
]

{ #category : #'debug support' }
SpurMemoryManager >> runLeakCheckerForFreeSpace: gcModes [
	<inline: false>
	(gcModes anyMask: GCModeFreeSpace) ifTrue:
		[coInterpreter reverseDisplayFrom: 16 to: 19.
		 self clearLeakMapAndMapAccessibleFreeSpace.
		 self asserta: self checkHeapFreeSpaceIntegrity]
]

{ #category : #'debug support' }
SpurMemoryManager >> runLeakCheckerForFullGC [
	<doNotGenerate>
	"Support for the Spur bootstrap"
	self runLeakCheckerFor: GCModeFull
]

{ #category : #'debug printing' }
SpurMemoryManager >> safePrintStringOf: oop [
	| target |
	(self isOopForwarded: oop)
		ifTrue: [target := self followForwarded: oop]
		ifFalse: [target := oop].
	^coInterpreter printStringOf: target
]

{ #category : #testing }
SpurMemoryManager >> scavengeInProgress [
	^gcPhaseInProgress == ScavengeInProgress
]

{ #category : #accessing }
SpurMemoryManager >> scavengeThreshold [
	^scavengeThreshold
]

{ #category : #accessing }
SpurMemoryManager >> scavengeThresholdAsExtent [
	^scavengeThreshold - scavenger eden start
]

{ #category : #'spur bootstrap' }
SpurMemoryManager >> scavenger [
	<doNotGenerate>
	^scavenger
]

{ #category : #scavenger }
SpurMemoryManager >> scavengerDenominator [
	"David's paper uses 140Kb eden + 2 x 28kb survivor spaces,
	 which is 5 7ths for eden and 1 7th each for the survivor spaces.
	 So express scavenger sizes in 7ths"
	^7
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> scavengingGC [
	"Run the scavenger."

	self scavengingGCTenuringIf: TenureByAge
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> scavengingGCTenuringIf: tenuringCriterion [
	"Run the scavenger."
	<inline: false>
	self assert: remapBufferCount = 0.
	(self asserta: scavenger eden limit - freeStart > coInterpreter interpreterAllocationReserveBytes) ifFalse:
		[coInterpreter tab;
			printNum: scavenger eden limit - freeStart; space;
			printNum: coInterpreter interpreterAllocationReserveBytes; space;
			printNum: coInterpreter interpreterAllocationReserveBytes - (scavenger eden limit - freeStart); cr].
	self checkMemoryMap.
	self checkFreeSpace: GCModeNewSpace.
	self runLeakCheckerFor: GCModeNewSpace.

	coInterpreter
		preGCAction: GCModeNewSpace;
		"would prefer this to be in mapInterpreterOops, but
		 compatibility with ObjectMemory dictates it goes here."
		flushMethodCacheFrom: newSpaceStart to: newSpaceLimit.
	needGCFlag := false.

	gcStartUsecs := coInterpreter ioUTCMicrosecondsNow.

	self doScavenge: tenuringCriterion.

	statScavenges := statScavenges + 1.
	statGCEndUsecs := coInterpreter ioUTCMicrosecondsNow.
	statSGCDeltaUsecs := statGCEndUsecs - gcStartUsecs.
	statScavengeGCUsecs := statScavengeGCUsecs + statSGCDeltaUsecs.
	statRootTableCount := scavenger rememberedSetSize.

	scavenger logScavenge.

	coInterpreter postGCAction: GCModeNewSpace.

	self runLeakCheckerFor: GCModeNewSpace.
	self checkFreeSpace: GCModeNewSpace
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> scheduleScavenge [
	needGCFlag := true.
	coInterpreter forceInterruptCheck
]

{ #category : #'class table puns' }
SpurMemoryManager >> segmentBridgePun [
	<cmacro>
	^3
]

{ #category : #accessing }
SpurMemoryManager >> segmentManager [
	^segmentManager
]

{ #category : #'header access' }
SpurMemoryManager >> set: objOop classIndexTo: classIndex formatTo: format [
	"0 = 0 sized objects (UndefinedObject True False et al)
	 1 = non-indexable objects with inst vars (Point et al)
	 2 = indexable objects with no inst vars (Array et al)
	 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
	 4 = weak indexable objects with inst vars (WeakArray et al)
	 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
	 6 unused, reserved for exotic pointer objects?
	 7 Forwarded Object, 1st field is pointer, rest of fields are ignored
	 8 unused, reserved for exotic non-pointer objects?
	 9 64-bit indexable
	 10 - 11 32-bit indexable
	 12 - 15 16-bit indexable
	 16 - 23 byte indexable
	 24 - 31 compiled method"
	self subclassResponsibility
]

{ #category : #'spur bootstrap' }
SpurMemoryManager >> setCheckForLeaks: integerFlags [
	" 0 = do nothing.
	  1 = check for leaks on fullGC (GCModeFull).
	  2 = check for leaks on scavenger (GCModeNewSpace).
	  4 = check for leaks on incremental (GCModeIncremental)
	  8 = check for leaks on become (GCModeBecome)
	 16 = check for leaks on image segments (GCModeImageSegment)"
	checkForLeaks := integerFlags
]

{ #category : #'header access' }
SpurMemoryManager >> setClassIndexOf: objOop to: classIndex [
	self subclassResponsibility
]

{ #category : #'allocation accounting' }
SpurMemoryManager >> setCurrentAllocatedBytesTo: n [
	"Reset the allocation count to n (n will typically be zero).  Since we wish to
	 discount the current use we must set statAllocatedBytes to n and update
	 oldSpaceUsePriorToScavenge to discount the current allocated bytes."
	| delta |
	delta := self currentAllocatedBytes - statAllocatedBytes.
	statAllocatedBytes := n.
	oldSpaceUsePriorToScavenge := oldSpaceUsePriorToScavenge + delta.
	self assert: self currentAllocatedBytes = n
]

{ #category : #snapshot }
SpurMemoryManager >> setEndOfMemory: newEndOfMemory [
	"Set by the segment manager after swizzling the image,
	 and by the SpurBootstrap on writing out the transformed image."
	endOfMemory := newEndOfMemory.
	freeOldSpaceStart > newEndOfMemory ifTrue:
		[freeOldSpaceStart := newEndOfMemory]
]

{ #category : #'header access' }
SpurMemoryManager >> setFormatOf: objOop to: format [
	"0 = 0 sized objects (UndefinedObject True False et al)
	 1 = non-indexable objects with inst vars (Point et al)
	 2 = indexable objects with no inst vars (Array et al)
	 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
	 4 = weak indexable objects with inst vars (WeakArray et al)
	 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
	 6 unused, reserved for exotic pointer objects?
	 7 Forwarded Object, 1st field is pointer, rest of fields are ignored
	 8 unused, reserved for exotic non-pointer objects?
	 9 64-bit indexable
	 10 - 11 32-bit indexable
	 12 - 15 16-bit indexable
	 16 - 23 byte indexable
	 24 - 31 compiled method"
	self subclassResponsibility
]

{ #category : #'free space' }
SpurMemoryManager >> setFree: objOop [
	<inline: true>
	"turn the object into a free chunk, zeroing classIndex, format, isGrey,isPinned,isRemembered,isImmutable & ?."
	self long32At: objOop put: 0
]

{ #category : #snapshot }
SpurMemoryManager >> setFreeOldSpaceStart: newFreeOldSpaceStart [
	"Set by the segment manager on parsing the image."
	freeOldSpaceStart := newFreeOldSpaceStart
]

{ #category : #'header access' }
SpurMemoryManager >> setHashBitsOf: objOop to: hash [
	self flag: #endianness.
	self assert: (hash between: 0 and: self identityHashHalfWordMask).
	self long32At: objOop + 4
		put: ((self long32At: objOop + 4) bitClear: self identityHashHalfWordMask) + hash
]

{ #category : #snapshot }
SpurMemoryManager >> setHeapBase: baseOfHeap memoryLimit: memLimit endOfMemory: memEnd [
	"Set the dimensions of the heap, answering the start of oldSpace. edenBytes holds the desired ``size of eden''
	 which is actually the total size of new space minus the reserve.  edenBytes is then divided up between eden
	 and the two survivor spaces, where each survivor space is a scavengerDenominator (one seventh) of the total."
	"Transcript
		cr; nextPutAll: 'heapBase: '; print: baseOfHeap; nextPut: $/; nextPutAll: baseOfHeap hex;
		nextPutAll: ' memLimit '; print: memLimit; nextPut: $/; nextPutAll: memLimit hex;
		nextPutAll: ' memEnd '; print: memEnd; nextPut: $/; nextPutAll: memEnd hex; cr; flush."
	"This is more than a little counter-intuitive.  Eden must include interpreterAllocationReserveBytes."
	<inline: #never>
	| reserve |
	reserve := coInterpreter interpreterAllocationReserveBytes.
	newSpaceStart := baseOfHeap.
	newSpaceLimit := baseOfHeap + edenBytes + reserve.
	scavenger newSpaceStart: newSpaceStart
				newSpaceBytes: newSpaceLimit - newSpaceStart
				survivorBytes: newSpaceLimit - newSpaceStart - reserve // self scavengerDenominator.

	freeStart := scavenger eden start.
	pastSpaceStart := scavenger pastSpace start.

	oldSpaceStart := newSpaceLimit.
	freeOldSpaceStart := memEnd.
	endOfMemory := memLimit.

	^baseOfHeap
]

{ #category : #accessing }
SpurMemoryManager >> setHeapGrowthToSizeGCRatio: aDouble [
	<var: #aDouble type: #double>
	heapGrowthToSizeGCRatio := aDouble.
	^0
]

{ #category : #'allocation accounting' }
SpurMemoryManager >> setHeapSizeAtPreviousGC [
	"heapSizeAtPreviousGC is used to invoke full GC when lots of oldSpace objects are created.
	 Also reset oldSpaceUsePriorToScavenge."
	<inline: true>
	heapSizeAtPreviousGC := segmentManager totalOldSpaceCapacity - totalFreeOldSpace.
	self resetAllocationAccountingAfterGC
]

{ #category : #'class table' }
SpurMemoryManager >> setHiddenRootsObj: anOop [
	hiddenRootsObj := anOop.
	self cCode: [self assert: self validClassTableRootPages]
		inSmalltalk: [numClassTablePages ifNotNil:
						[self assert: self validClassTableRootPages]].
	classTableFirstPage := self fetchPointer: 0 ofObject: hiddenRootsObj.
	self assert: (self numSlotsOf: classTableFirstPage) - 1 = self classTableMinorIndexMask.
	"Hack fix.  A bug in markAndTraceClassOf: caused the class of the first class table page
	 to be changed from its pun.  This can be restored manually, but we do it here too."
	self flag: 'remove at some stage'.
	(self classIndexOf: classTableFirstPage) ~= self arrayClassIndexPun ifTrue:
		[self setClassIndexOf: classTableFirstPage to: self arrayClassIndexPun].
	"Set classTableIndex to the start of the last used page (excepting first page).
	 Set numClassTablePages to the number of used pages."
	numClassTablePages := self classTableRootSlots.
	2 to: numClassTablePages - 1 do:
		[:i|
		(self fetchPointer: i ofObject: hiddenRootsObj) = nilObj ifTrue:
			[numClassTablePages := i.
			 classTableIndex := (numClassTablePages - 1 max: 1) << self classTableMajorIndexShift.
			 ^self]].
	"no unused pages; set it to the start of the second page."
	classTableIndex := 1 << self classTableMajorIndexShift
]

{ #category : #'header access' }
SpurMemoryManager >> setIsGreyOf: objOop to: aBoolean [
	self subclassResponsibility
]

{ #category : #'header access' }
SpurMemoryManager >> setIsImmutableOf: objOop to: aBoolean [
	self subclassResponsibility
]

{ #category : #'header access' }
SpurMemoryManager >> setIsMarkedOf: objOop to: aBoolean [
	self subclassResponsibility
]

{ #category : #'header access' }
SpurMemoryManager >> setIsPinnedOf: objOop to: aBoolean [
	self subclassResponsibility
]

{ #category : #'header access' }
SpurMemoryManager >> setIsRememberedOf: objOop to: aBoolean [
	self subclassResponsibility
]

{ #category : #'growing/shrinking memory' }
SpurMemoryManager >> setLastSegment: segInfo [
	"Update after removing a segment.
	 Here we cut back endOfMemory if required."
	<var: #segInfo type: #'SpurSegmentInfo *'>
	| currentEnd |
	<var: #currentEnd type: #usqInt>
	currentEnd := segInfo segLimit - self bridgeSize.
	currentEnd <= endOfMemory ifTrue:
		[endOfMemory := currentEnd.
		 freeOldSpaceStart > currentEnd ifTrue:
			[freeOldSpaceStart :=currentEnd]]
]

{ #category : #accessing }
SpurMemoryManager >> setMaxOldSpaceSize: limit [
	<var: #limit type: #usqInt>
	maxOldSpaceSize := limit.
	^0
]

{ #category : #'free space' }
SpurMemoryManager >> setNextFreeChunkOf: freeChunk withValue: nextFreeChunk chunkBytes: chunkBytes [
	self 
		setNextFreeChunkOf: freeChunk 
		withValue: nextFreeChunk 
		isLilliputianSize: (self isLilliputianSize: chunkBytes) 
	
	
]

{ #category : #'free space' }
SpurMemoryManager >> setNextFreeChunkOf: freeChunk withValue: nextFreeChunk isLilliputianSize: lilliputian [ 
	<inline: true> "Inlining is quite important since isLilliputianSize: is often true/false"
	self 
		storePointer: self freeChunkNextIndex 
		ofFreeChunk: freeChunk 
		withValue: nextFreeChunk.
	(nextFreeChunk ~= 0 and: [lilliputian not]) ifTrue:
		[self 
			storePointer: self freeChunkPrevIndex 
			ofFreeChunk: nextFreeChunk 
			withValue: freeChunk]
	
	
]

{ #category : #'free space' }
SpurMemoryManager >> setObjectFree: objOop [
	"Mark an object free, but do not add it to the free lists.  The wrinkle here
	 is that we don't tolerate a zero-slot count in a free object so that the
	 (self long64At: objOop) ~= 0 assert in isEnumerableObject: isn't triggered."
		 
	(self rawNumSlotsOf: objOop) = 0 ifTrue:
		[self rawNumSlotsOf: objOop put: 1].
	self setFree: objOop
]

{ #category : #'word size' }
SpurMemoryManager >> shiftForAllocationUnit [
	^3
]

{ #category : #'word size' }
SpurMemoryManager >> shiftForWord [
	<api>
	^self subclassResponsibility
]

{ #category : #'debug printing' }
SpurMemoryManager >> shortPrintObjectsFrom: startAddress to: endAddress [
	<api>
	| oop |
	oop := self objectBefore: startAddress.
	oop := oop
				ifNil: [startAddress]
				ifNotNil: [(self objectAfter: oop) = startAddress
							ifTrue: [startAddress]
							ifFalse: [oop]].
	[self oop: oop isLessThan: endAddress] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[coInterpreter shortPrintOop: oop].
		oop := self objectAfter: oop]
]

{ #category : #allocation }
SpurMemoryManager >> shorten: objOop toIndexableSize: indexableSize [
	"Reduce the number of indexable fields in objOop, a pointer object, to nSlots. Convert the
	 unused residual to a free chunk. Without changes to numSlotsForShortening:toIndexableSize:
	 this only works for arrayFormat and longFormat objects.
	 Answer the number of bytes returned to free memory, which may be zero if no change was possible."
	self subclassResponsibility
]

{ #category : #'debug support' }
SpurMemoryManager >> shouldBreakForLookupIn: lookupClass given: breakClassTag [
	<inline: true>
	^breakClassTag notNil
	  and: [lookupClass == breakClassTag
			or: [(self rawHashBitsOf: lookupClass) == breakClassTag]]
]

{ #category : #'gc - scavenge/compact' }
SpurMemoryManager >> shouldRemapObj: objOop [
	"Answer if the obj should be scavenged (or simply followed). The method is called
	 shouldRemapObj: for compatibility with ObjectMemory.  Defer to the compactor
	 to choose the actual test, there being a difference between the vanilla test and
	 that used with a sliding compactor where objects are not marked as forwarded."
	<doNotGenerate>
	^compactor shouldRemapObj: objOop
]

{ #category : #'gc - scavenge/compact' }
SpurMemoryManager >> shouldRemapOop: oop [
	<api>
	"Answer if the oop should be scavenged.. The method is called
	 shouldRemapOop: for compatibility with ObjectMemory."
	<inline: true>
	^(self isNonImmediate: oop)
	   and: [self shouldRemapObj: oop]
]

{ #category : #'simulation only' }
SpurMemoryManager >> showDisplayBits: aForm Left: l Top: t Right: r Bottom: b [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter showDisplayBits: aForm Left: l Top: t Right: r Bottom: b
]

{ #category : #'free space' }
SpurMemoryManager >> shrinkThreshold [
	^shrinkThreshold
]

{ #category : #'free space' }
SpurMemoryManager >> shrinkThreshold: aValue [
	shrinkThreshold := aValue
]

{ #category : #'gc - incremental' }
SpurMemoryManager >> shutDownIncrementalGC: objectsShouldBeUnmarked [
	"If the incremental collector is running mark bits may be set; stop it and clear them if necessary."
	self flag: 'need to implement the inc GC first...'.
	objectsShouldBeUnmarked ifTrue:
		[self assert: self allObjectsUnmarked]
]

{ #category : #accessing }
SpurMemoryManager >> signalLowSpace [
	^signalLowSpace
]

{ #category : #accessing }
SpurMemoryManager >> signalLowSpace: aValue [
	^signalLowSpace := aValue
]

{ #category : #'simulation only' }
SpurMemoryManager >> signalSemaphoreWithIndex: index [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter signalSemaphoreWithIndex: index
]

{ #category : #'simulation only' }
SpurMemoryManager >> signed32BitIntegerFor: integerValue [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter signed32BitIntegerFor: integerValue
]

{ #category : #'simulation only' }
SpurMemoryManager >> signed32BitValueOf: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter signed32BitValueOf: oop
]

{ #category : #'simulation only' }
SpurMemoryManager >> signed64BitIntegerFor: integerValue [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter signed64BitIntegerFor: integerValue
]

{ #category : #'simulation only' }
SpurMemoryManager >> signed64BitValueOf: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter signed64BitValueOf: oop
]

{ #category : #'simulation only' }
SpurMemoryManager >> signedMachineIntegerValueOf: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter signedMachineIntegerValueOf: oop
]

{ #category : #'header formats' }
SpurMemoryManager >> sixtyFourBitIndexableFormat [
	<api>
	<cmacro>
	^9
]

{ #category : #'class table puns' }
SpurMemoryManager >> sixtyFourBitLongsClassIndexPun [
	"Class puns are class indices not used by any class.  There may be
	 an entry for the pun that refers to the notional class of objects with
	 this class index.  But because the index doesn't match the class it
	 won't show up in allInstances, hence hiding the object with a pun as
	 its class index. The puns occupy indices 16 through 31."
	<cmacro>
	^19
]

{ #category : #'object access' }
SpurMemoryManager >> sizeBitsOf: objOop [
	"Answer the number of bytes in the given object, including its base header, rounded up to an integral number of words.
	 Hence, were it not for the fact that zero-sized objects have at least room for a forwarding pointer,
	 objOop + (self sizeBitsOf: objOop) is the address immediately following objOop."
	"Note: byte indexable objects need to have low bits subtracted from this size to find the address beyond the last byte."
	^(self numSlotsOf: objOop) << self shiftForWord + self baseHeaderSize
]

{ #category : #'object access' }
SpurMemoryManager >> sizeBitsOfSafe: objOop [
	^self sizeBitsOf: objOop
]

{ #category : #'free space' }
SpurMemoryManager >> sizeOfFree: objOop [
	"For compatibility with ObjectMemory, answer the size of a free chunk in bytes.
	 Do *not* use internally."
	self assert: (self isFreeObject: objOop).
	^self bytesInObject: objOop
]

{ #category : #'free space' }
SpurMemoryManager >> sizeOfLargestFreeChunk [
	"Answer the size of largest free chunk in oldSpace."
	| freeChunk |
	freeChunk := self findLargestFreeChunk.
	freeChunk ifNil:
		[63 to: 1 by: -1 do:
			[:i|
			(freeLists at: i) ifNotNil:
				[:chunk| ^self bytesInObject: chunk]].
		 ^0].
	^self bytesInObject: freeChunk
]

{ #category : #'obj stacks' }
SpurMemoryManager >> sizeOfObjStack: objStack [
	| total objStackPage |
	objStack = nilObj ifTrue: [^0].
	total := self fetchPointer: ObjStackTopx ofObject: objStack.
	objStackPage := objStack.
	[objStackPage := self fetchPointer: ObjStackNextx ofObject: objStackPage.
	 objStackPage ~= 0] whileTrue:
		[total := total + ObjStackLimit.
		 self assert: (self fetchPointer: ObjStackTopx ofObject: objStackPage) = ObjStackLimit].
	^total
]

{ #category : #'simulation only' }
SpurMemoryManager >> sizeOfSTArrayFromCPrimitive: cPtr [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter sizeOfSTArrayFromCPrimitive: cPtr
]

{ #category : #testing }
SpurMemoryManager >> slidingCompactionInProgress [
	^gcPhaseInProgress == SlidingCompactionInProgress
]

{ #category : #'gc - scavenge/compact' }
SpurMemoryManager >> slidingCompactionRemapObj: objOop [
	"Scavenge or simply follow objOop.  Answer the new location of objOop.
	 The send should have been guarded by a send of shouldRemapOop:.
	 The method is called remapObj: for compatibility with ObjectMemory."
	<inline: true>
	| resolvedObj |
	self assert: (self shouldRemapOop: objOop).
	(self isForwarded: objOop)
		ifTrue:
			[resolvedObj := self followForwarded: objOop]
		ifFalse:
			[self deny: (self isInFutureSpace: objOop).
			 resolvedObj := objOop].
	gcPhaseInProgress > 0 ifTrue:
		[self scavengeInProgress
			ifTrue:
				[((self isReallyYoung: resolvedObj) "don't scavenge immediate, old, or CogMethod objects."
				  and: [(self isInFutureSpace: resolvedObj) not]) ifTrue: 
					[^scavenger copyAndForward: resolvedObj]]
			ifFalse:
				[self assert: self slidingCompactionInProgress.
				 (compactor isMobile: objOop) ifTrue:
					[^self fetchPointer: 0 ofObject: objOop]]].
	^resolvedObj
]

{ #category : #'gc - scavenge/compact' }
SpurMemoryManager >> slidingCompactionShouldRemapObj: objOop [
	<inline: true>
	"Answer if the obj should be scavenged, or simply followed. Sent via the compactor
	 from shouldRemapObj:.  We test for being already scavenged because mapStackPages
	 via mapInterpreterOops may be applied twice in the context of a global GC where a
	 scavenge, followed by a scan-mark-free, and final compaction passes may result in
	 scavenged fields being visited twice."
	^(self isForwarded: objOop)
	   or: [gcPhaseInProgress > 0 "Hence either scavengeInProgress or slidingCompactionInProgress"
		   and: [self scavengeInProgress
					ifTrue: [(self isReallyYoungObject: objOop)
							and: [(self isInFutureSpace: objOop) not]]
					ifFalse: [compactor isMobile: objOop]]]
]

{ #category : #'object access' }
SpurMemoryManager >> slotSizeOf: oop [
	"*DO NOT CONFUSE THIS WITH numSlotsOf:.
	 This is an ObjectMemory compatibility method with questionable semantics.
	 Answers the number of slots in the receiver.
	 If the receiver is a byte object, return the number of bytes.
	 Otherwise return the number of words."
	(self isImmediate: oop) ifTrue: [^0].
	^self lengthOf: oop
]

{ #category : #'cog jit support' }
SpurMemoryManager >> smallIntegerTag [
	<api>
	<cmacro>
	^1
]

{ #category : #allocation }
SpurMemoryManager >> smallObjectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object without an overflow header, including header bytes."
	<returnTypeC: #usqInt>
	^self subclassResponsibility
]

{ #category : #accessing }
SpurMemoryManager >> specialObjectsOop [
	^specialObjectsOop
]

{ #category : #accessing }
SpurMemoryManager >> specialObjectsOop: anObject [
	"For mapInterpreterOops"
	specialObjectsOop := anObject
]

{ #category : #'interpreter access' }
SpurMemoryManager >> splObj: index [
	<api>
	<inline: true>
	"Return one of the objects in the specialObjectsArray"
	^self fetchPointer: index ofObject: specialObjectsOop
]

{ #category : #'interpreter access' }
SpurMemoryManager >> splObj: index put: anObject [
	"Set one of the objects in the SpecialObjectsArray"
	self storePointer: index ofObject: specialObjectsOop withValue: anObject
]

{ #category : #'simulation only' }
SpurMemoryManager >> sqAllocateMemorySegmentOfSize: segmentSize Above: minAddress AllocatedSizeInto: allocSizePtrOrBlock [
	<doNotGenerate>
	"Simulate heap growth by growing memory by segmentSize + a delta.
	 To test bridges alternate the delta between 0 bytes and 1M bytes
	 depending on the number of segments.
	 The delta will be the distance between segments to be bridged."
	| delta newMemory start |
	self assert: segmentSize \\ memory bytesPerElement = 0.
	delta := segmentManager numSegments odd ifTrue: [1024 * 1024] ifFalse: [0].
	"A previous shrink may have freed up memory.  Don't bother to grow if there's already room.
	 At minAddress there is a hole of segmentSize or it is the segLimit of the last segment.
	 However there is no hole of segmentSize + delta guaranteed..."
	0 to: segmentManager numSegments - 1 do:
			[:i| | segment bridge |
			segment := segmentManager segments at: i.
			bridge := segmentManager bridgeAt: i.
			(segment segLimit >= minAddress 
				and: [(self bytesInObject: bridge) - self bridgeSize >= (segmentSize + delta)]) ifTrue: [ 
					allocSizePtrOrBlock value: segmentSize.
					^ segment segLimit + delta] ].
	start := memory size * memory bytesPerElement + delta.
	newMemory := memory class new: memory size + (segmentSize + delta / memory bytesPerElement).
	newMemory replaceFrom: 1 to: memory size with: memory startingAt: 1.
	memory := newMemory.
	allocSizePtrOrBlock value: segmentSize.
	^start
]

{ #category : #'simulation only' }
SpurMemoryManager >> sqDeallocateMemorySegmentAt: startAddress OfSize: ammount [
	"This is a nop in the simulator, except for SpurPlanningCompactor which may
	 release at the end of memory, allowing the simulator to shrink memory."
	<doNotGenerate>
	startAddress >= endOfMemory ifTrue:
		[self halt]
]

{ #category : #'simulation only' }
SpurMemoryManager >> stObject: objOop at: indexOop put: valueOop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter stObject: objOop at: indexOop put: valueOop
]

{ #category : #'object access' }
SpurMemoryManager >> stSizeOf: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter stSizeOf: oop
]

{ #category : #'simulation only' }
SpurMemoryManager >> stackFloatValue: offset [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter stackFloatValue: offset
]

{ #category : #'simulation only' }
SpurMemoryManager >> stackIntegerValue: offset [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter stackIntegerValue: offset
]

{ #category : #'simulation only' }
SpurMemoryManager >> stackObjectValue: offset [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter stackObjectValue: offset
]

{ #category : #'simulation only' }
SpurMemoryManager >> stackValue: offset [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter stackValue: offset
]

{ #category : #'obj stacks' }
SpurMemoryManager >> stackValue: offset ofObjStack: objStackPage [
	| topx nextPage |
	self assert: offset >= 0.
	topx := self fetchPointer: ObjStackTopx ofObject: objStackPage.
	offset < topx ifTrue:
		[^self fetchPointer: ObjStackTopx + offset ofObject: objStackPage].
	nextPage := self fetchPointer: ObjStackNextx ofObject: objStackPage.
	nextPage = 0 ifTrue:
		[^nil].
	^self stackValue: offset - topx ofObjStack: nextPage
]

{ #category : #accessing }
SpurMemoryManager >> startOfMemory [
	"Return the start of object memory. Use a macro so as not to punish the debug VM."
	<cmacro: '() GIV(memory)'>
	<returnTypeC: #usqInt>
	^0
]

{ #category : #'object enumeration' }
SpurMemoryManager >> startOfObject: objOop [
	"Answer the start of objOop, which is either the address of the overflow
	 size word, or objOop itself, depending on the size of the object.  This may
	 be applied to any kind of object, normal, forwarders or free chunks."
	<returnTypeC: #usqInt>
	^(self hasOverflowHeader: objOop)
		ifTrue: [objOop - self baseHeaderSize]
		ifFalse: [objOop]
]

{ #category : #'object enumeration' }
SpurMemoryManager >> startOfObject: objOop given: rawNumSlots [
	"Answer the start of objOop, which is either the address of the overflow
	 size word, or objOop itself, depending on the size of the object.  This may
	 be applied to any kind of object, normal, forwarders or free chunks."
	<returnTypeC: #usqInt>
	^(self objectWithRawSlotsHasOverflowHeader: rawNumSlots)
		ifTrue: [objOop - self baseHeaderSize]
		ifFalse: [objOop]
]

{ #category : #accessing }
SpurMemoryManager >> statCompMoveCount [
	"Spur never compacts by moving; but it does make compaction passes."
	^statCompactPassCount
]

{ #category : #accessing }
SpurMemoryManager >> statCompactPassCount [
	^statCompactPassCount
]

{ #category : #accessing }
SpurMemoryManager >> statCompactPassCount: anInteger [
	^statCompactPassCount := anInteger
]

{ #category : #accessing }
SpurMemoryManager >> statCompactionUsecs [
	^statCompactionUsecs
]

{ #category : #accessing }
SpurMemoryManager >> statFGCDeltaUsecs [
	^statFGCDeltaUsecs
]

{ #category : #accessing }
SpurMemoryManager >> statFullGCUsecs [
	^statFullGCUsecs
]

{ #category : #accessing }
SpurMemoryManager >> statFullGCs [
	^statFullGCs
]

{ #category : #accessing }
SpurMemoryManager >> statGCEndUsecs [
	^statGCEndUsecs
]

{ #category : #accessing }
SpurMemoryManager >> statGrowMemory [
	^statGrowMemory
]

{ #category : #accessing }
SpurMemoryManager >> statIGCDeltaUsecs [
	^statIGCDeltaUsecs
]

{ #category : #accessing }
SpurMemoryManager >> statIncrGCUsecs [
	^statIncrGCUsecs
]

{ #category : #accessing }
SpurMemoryManager >> statIncrGCs [
	^statIncrGCs
]

{ #category : #accessing }
SpurMemoryManager >> statMarkCount [
	^statMarkCount
]

{ #category : #accessing }
SpurMemoryManager >> statMarkUsecs [
	^statMarkUsecs
]

{ #category : #accessing }
SpurMemoryManager >> statMaxAllocSegmentTime [
	^statMaxAllocSegmentTime
]

{ #category : #accessing }
SpurMemoryManager >> statMaxAllocSegmentTime: aValue [
	statMaxAllocSegmentTime := aValue
]

{ #category : #accessing }
SpurMemoryManager >> statMkFwdCount [
	^0
]

{ #category : #accessing }
SpurMemoryManager >> statNumGCs [
	"Part of InterpreterProxy's 1.14 API"
	<export: true>
	^statScavenges + statIncrGCs + statFullGCs
]

{ #category : #accessing }
SpurMemoryManager >> statRootTableCount [
	^statRootTableCount
]

{ #category : #accessing }
SpurMemoryManager >> statRootTableOverflows [
	^statRootTableOverflows
]

{ #category : #accessing }
SpurMemoryManager >> statSGCDeltaUsecs [
	^statSGCDeltaUsecs
]

{ #category : #accessing }
SpurMemoryManager >> statScavengeGCUsecs [
	^statScavengeGCUsecs
]

{ #category : #accessing }
SpurMemoryManager >> statScavenges [
	^statScavenges
]

{ #category : #accessing }
SpurMemoryManager >> statShrinkMemory [
	^statShrinkMemory
]

{ #category : #accessing }
SpurMemoryManager >> statSpecialMarkCount [
	^0
]

{ #category : #accessing }
SpurMemoryManager >> statSurvivorCount [
	<doNotGenerate>
	^scavenger statSurvivorCount
]

{ #category : #accessing }
SpurMemoryManager >> statSweepCount [
	^0
]

{ #category : #accessing }
SpurMemoryManager >> statSweepUsecs [
	^statSweepUsecs
]

{ #category : #accessing }
SpurMemoryManager >> statTenures [
	<doNotGenerate>
	^scavenger statTenures
]

{ #category : #accessing }
SpurMemoryManager >> statTenures: aValue [
	<doNotGenerate>
	scavenger statTenures: aValue
]

{ #category : #'object access' }
SpurMemoryManager >> storeByte: byteIndex ofObject: oop withValue: valueByte [
	^self byteAt: oop + self baseHeaderSize + byteIndex put: valueByte
]

{ #category : #accessing }
SpurMemoryManager >> storeCheckBoundary [
	"A renaming for the Cogit, which couldn't make sense of GIV(newSpaceLimit)"
	<api>
	^newSpaceLimit
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> storeImageSegmentInto: segmentWordArrayArg outPointers: outPointerArrayArg roots: arrayOfRootsArg [
	"This primitive is called from Squeak as...
		<imageSegment> storeSegmentFor: arrayOfRoots into: aWordArray outPointers: anArray.

	 This primitive will store a binary image segment (in the same format as objects in the heap) of the
	 set of objects in arrayOfObjects.  All pointers from within the set to objects outside the set will be
	 copied into the array of outPointers.  In their place in the image segment will be an oop equal to the
	 offset in the outPointer array (the first would be 8), but with the high bit set.

	 Since Spur has a class table the load primitive must insert classes that have instances into the
	 class table.  This primitive marks such classes using the isRemembered bit, which isn't meaningful
	 as a remembered bit in the segment.

	 The primitive expects the segmentWordArray and outPointerArray to be more than adequately long.
	 In this case it returns normally, and truncates the two arrays to exactly the right size.

	 The primitive can fail for the following reasons with the specified failure codes:
		PrimErrGenericError:		the segmentWordArray is too small for the version stamp
		PrimErrWritePastObject:	the segmentWordArray is too small to contain the reachable objects
		PrimErrBadIndex:			the outPointerArray is too small
		PrimErrNoMemory:			additional allocations failed
		PrimErrLimitExceeded:		there is no room in the hash field to store out pointer indices or class references."
	<inline: false>
	| segmentWordArray outPointerArray arrayOfRoots
	  arrayOfObjects savedFirstFields savedOutHashes segStart segAddr endSeg outIndex numClassesInSegment |
	<var: 'segAddr' type: #usqInt>
	((self isObjImmutable: segmentWordArrayArg)
	 or: [self isObjImmutable: outPointerArrayArg]) ifTrue:
		[^PrimErrNoModification].
	"Since segmentWordArrayArg & outPointerArrayArg may get shortened, they can't be pinned."
	((self isPinned: segmentWordArrayArg)
	 or: [self isPinned: outPointerArrayArg]) ifTrue:
		[^PrimErrObjectIsPinned].
	(self numSlotsOf: outPointerArrayArg) > self maxIdentityHash ifTrue:
		[^PrimErrLimitExceeded].

	self runLeakCheckerFor: GCModeImageSegment.

	"First scavenge to collect any new space garbage that refers to the graph."
	self scavengingGC.
	segmentWordArray := self updatePostScavenge: segmentWordArrayArg.
	outPointerArray := self updatePostScavenge: outPointerArrayArg.
	arrayOfRoots := self updatePostScavenge: arrayOfRootsArg.
	self deny: (self forwardersIn: outPointerArray).
	self deny: (self forwardersIn: arrayOfRoots).
	
	"Now compute the transitive closure, collecting the sequence of objects to be stored in the arrayOfObjects array.
	 Included in arrayOfObjects are the arrayOfRoots and all its contents.  All objects have been unmarked."
	arrayOfObjects := self objectsReachableFromRoots: arrayOfRoots.
	arrayOfObjects ifNil:
		[^PrimErrNoMemory].
	"If objectsReachableFromRoots: answers an integer there is not enough continuous free space in which to allocate the
	 reachable objects.  If there is sufficient free space then answer an error code to prompt a compacting GC and a retry."
	(self isIntegerObject: arrayOfObjects) ifTrue:
		[totalFreeOldSpace - self allocationUnit >= (self integerValueOf: arrayOfObjects) ifTrue:
			[^PrimErrNeedCompaction].
		 ^PrimErrNoMemory].

	self assert: self allObjectsUnmarked. "work to be done when the incremental GC is written"
	self deny: (self forwardersIn: arrayOfObjects).

	"Both to expand the max size of segment and to reduce the length of the
	 load-time pass that adds classes to the class table, move classes to the
	 front of arrayOfObjects, leaving the root array as the first element."
	numClassesInSegment := self moveClassesForwardsIn: arrayOfObjects.

	"The scheme is to copy the objects into segmentWordArray, and then map the oops in segmentWordArray.
	 Therefore the primitive needs to both map efficiently originals to copies in segmentWordArray and
	 be able to undo any side-effects if the primitive fails because either segmentWordArray or outPointerArray
	 is too small.  The mapping is done by having the objects to be stored in arrayOfObjects refer to their mapped
	 locations through their first field, just like a forwarding pointer, but without becoming a forwarder, saving their
	 first field in savedFirstFields, and the objects in outPointerArray pointing to their locations in the outPointerArray
	 through their identityHashes, saved in savedOutHashes.
	 Since arrayOfObjects and its savedFirstFields, and outPointerArray and its saved hashes, can be enumerated
	 side-by-side, the hashes can be restored to the originals.  So the first field of the heap object corresponding to
	 an object in arrayOfObjects is set to its location in segmentWordArray, and the hash of an object in outPointerArray
	 is set to its index in outPointerArray plus the top hash bit.  Classes in arrayOfObjects have their marked bit set.
	 Oops in objects in segmentWordArray are therefore mapped by accessing the original oop, and following its first
	 field. Class indices in segmentWordArray are mapped by fetching the original class, and testing its marked bit.
	 If marked, the first field is followed to access the class copy in the segment.  Out pointers (objects and classes,
	 which are unmarked), the object's identityHash is set (eek!!) to its index in the outPointerArray. So savedOutHashes
	 parallels the outPointerArray. The saved hash array is initialized with an out-of-range hash value so that the first
	 unused entry can be identified."

	savedFirstFields := self allocateSlots: (self numSlotsOf: arrayOfObjects)
							format: self wordIndexableFormat
							classIndex: self wordSizeClassIndexPun.
	savedOutHashes := self allocateSlots: (self numSlotsForBytes: (self numSlotsOf: outPointerArray) * 4)
							format: self firstLongFormat
							classIndex: self thirtyTwoBitLongsClassIndexPun.
	(savedFirstFields isNil or: [savedOutHashes isNil]) ifTrue:
		[self freeObject: arrayOfObjects.
		 (savedFirstFields notNil and: [self isInOldSpace: savedFirstFields]) ifTrue:
			[self freeObject: savedFirstFields].
		 (savedOutHashes notNil and: [self isInOldSpace: savedOutHashes]) ifTrue:
			[self freeObject: savedOutHashes].
		 ^PrimErrNoMemory].

	self fillObj: savedFirstFields numSlots: (self numSlotsOf: savedFirstFields) with: 0.
	self fillObj: savedOutHashes numSlots: (self numSlotsOf: savedOutHashes) with: self savedOutHashFillValue.

	segAddr := segmentWordArray + self baseHeaderSize.
	endSeg := self addressAfter: segmentWordArray.

	"Write a version number for byte order and version check."
	segAddr >= endSeg ifTrue: [^PrimErrGenericFailure].
	self long32At: segAddr put: self imageSegmentVersion.
	self long32At: segAddr + 4 put: self imageSegmentVersion.
	segStart := segAddr := segAddr + self allocationUnit.

	self assert: arrayOfRoots = (self fetchPointer: 0 ofObject: arrayOfObjects).

	"Copy all reachable objects to the segment, setting the marked bit for all objects (clones) in the segment,
	 and the remembered bit for all classes (clones) in the segment."
	0 to: (self numSlotsOf: arrayOfObjects) - 1 do:
		[:i| | newSegAddrOrError objOop |
		"Check that classes in the segment are addressable.  Since the top bit of the hash field is used to tag
		 classes external to the segment, the segment offset must not inadvertently set this bit.  This limit still
		 allows for a million or more classes."
		(i = numClassesInSegment
		 and: [segAddr - segStart / self allocationUnit + self lastClassIndexPun >= TopHashBit]) ifTrue:
			[^self return: PrimErrLimitExceeded
					restoringObjectsIn: arrayOfObjects upTo: i savedFirstFields: savedFirstFields].
		objOop := self fetchPointer: i ofObject: arrayOfObjects.
		self deny: ((self isImmediate: objOop) or: [self isForwarded: objOop]).
		newSegAddrOrError := self copyObj: objOop
									toAddr: segAddr
									stopAt: endSeg
									savedFirstFields: savedFirstFields
									index: i.
		(self oop: newSegAddrOrError isLessThan: segStart) ifTrue:
			[^self return: newSegAddrOrError
					restoringObjectsIn: arrayOfObjects upTo: i savedFirstFields: savedFirstFields].
		 segAddr := newSegAddrOrError].

	"Check that it can be safely shortened."
	(endSeg ~= segAddr
	 and: [endSeg - segAddr < (self baseHeaderSize + self bytesPerOop)]) ifTrue:
		[^self return: PrimErrWritePastObject
				restoringObjectsIn: arrayOfObjects upTo: -1 savedFirstFields: savedFirstFields].

	"Now scan, adding out pointers to the outPointersArray; all objects in arrayOfObjects
	 have their first field pointing to the corresponding copy in segmentWordArray."
	(outIndex := self mapOopsFrom: segStart
					to: segAddr
					outPointers: outPointerArray
					outHashes: savedOutHashes) < 0 ifTrue: "no room in outPointers; fail"
		[^self return: PrimErrBadIndex
				restoringObjectsIn: arrayOfObjects savedFirstFields: savedFirstFields
				and: outPointerArray savedHashes: savedOutHashes].

	"We're done.  Shorten the results, restore hashes and return."
	self shorten: segmentWordArray toIndexableSize: segAddr - (segmentWordArray + self baseHeaderSize) / 4.
	self shorten: outPointerArray toIndexableSize: outIndex.
	^self return: PrimNoErr
		restoringObjectsIn: arrayOfObjects savedFirstFields: savedFirstFields
		and: outPointerArray savedHashes: savedOutHashes
]

{ #category : #'simulation only' }
SpurMemoryManager >> storeInteger: fieldIndex ofObject: objectPointer withValue: integerValue [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter storeInteger: fieldIndex ofObject: objectPointer withValue: integerValue
]

{ #category : #'object access' }
SpurMemoryManager >> storeLong32: fieldIndex ofObject: obj withValue: valueWord [
	^self long32At: obj + self baseHeaderSize + (fieldIndex << 2) put: valueWord
]

{ #category : #'object access' }
SpurMemoryManager >> storeLong64: longIndex ofObject: objOop withValue: value [
	<var: #value type: #sqLong>
	^self long64At: objOop + self baseHeaderSize + (longIndex << 3) put: value
]

{ #category : #'heap management' }
SpurMemoryManager >> storePointer: fieldIndex ofForwarder: objOop withValue: valuePointer [

	self assert: (self isForwarded: objOop).
	self assert: (self isOopForwarded: valuePointer) not.

	(self isOldObject: objOop) ifTrue: "most stores into young objects"
		[(self isYoung: valuePointer) ifTrue:
			[self possibleRootStoreInto: objOop]].

	^self
		longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'heap management' }
SpurMemoryManager >> storePointer: fieldIndex ofFreeChunk: objOop withUncheckedValue: valuePointer [

	self assert: (self isFreeObject: objOop).
	^self
		longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'heap management' }
SpurMemoryManager >> storePointer: fieldIndex ofFreeChunk: objOop withValue: valuePointer [

	self assert: (self isFreeObject: objOop).
	self assert: (valuePointer = 0 or: [self isFreeObject: valuePointer]).		
	^self
		longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'object access' }
SpurMemoryManager >> storePointer: fieldIndex ofObjStack: objStackPage withValue: thang [
	self assert: (self formatOf: objStackPage) = self wordIndexableFormat.
	self cCode: []
		inSmalltalk:
			[fieldIndex caseOf: {
				[ObjStackTopx]		->	[self assert: (thang between: 0 and: ObjStackLimit)].
				[ObjStackMyx]		->	[self assert: (thang between: MarkStackRootIndex and: MournQueueRootIndex)].
				[ObjStackFreex]	->	[self assert: (thang = 0
														or: [(self addressCouldBeObj: thang)
															and: [(self numSlotsOfAny: thang) = ObjStackPageSlots
															and: [(self formatOf: thang) = self wordIndexableFormat]]])].
				[ObjStackNextx]	->	[self assert: (thang = 0
														or: [(self addressCouldBeObj: thang)
															and: [(self numSlotsOfAny: thang) = ObjStackPageSlots
															and: [(self formatOf: thang) = self wordIndexableFormat]]])]. }
				otherwise: []].
	^self
		longAt: objStackPage + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: thang
]

{ #category : #'object access' }
SpurMemoryManager >> storePointer: fieldIndex ofObject: objOop withValue: valuePointer [
	"Note must check here for stores of young objects into old ones."
	self assert: (self isForwarded: objOop) not.

	(self isOldObject: objOop) ifTrue: "most stores into young objects"
		[(self isYoung: valuePointer) ifTrue:
			[self possibleRootStoreInto: objOop]].

	^self
		longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'object access' }
SpurMemoryManager >> storePointerImmutabilityCheck: fieldIndex ofObject: objOop withValue: valuePointer [
	"Note must check here for stores of young objects into old ones."
	<inline: true> "Must be inlined for the normal send in cannotAssign:to:withIndex:"

	self cppIf: IMMUTABILITY ifTrue: 
		[self deny: (self isImmediate: objOop).
		 (self isImmutable: objOop) ifTrue: 
			[^coInterpreter cannotAssign: valuePointer to: objOop withIndex: fieldIndex]].

	self storePointer: fieldIndex ofObject: objOop withValue: valuePointer
]

{ #category : #'heap management' }
SpurMemoryManager >> storePointerNoAssert: fieldIndex ofFreeChunk: objOop withValue: valuePointer [

	^self
		longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'object access' }
SpurMemoryManager >> storePointerUnchecked: fieldIndex ofMaybeForwardedObject: objOop withValue: valuePointer [
	^self
		longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'object access' }
SpurMemoryManager >> storePointerUnchecked: fieldIndex ofObject: objOop withValue: valuePointer [
	<api>
	self assert: (self isOopForwarded: objOop) not.
	^self
		longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'object access' }
SpurMemoryManager >> storeShort16: shortIndex ofObject: objOop withValue: value [
	^self
		shortAt: objOop + self baseHeaderSize + (shortIndex << 1)
		put: (self cCode: [value] inSmalltalk: [value bitAnd: 16rFFFF])
]

{ #category : #'primitive support' }
SpurMemoryManager >> stringForCString: aCString [
	"Answer a new String copied from a null-terminated C string,
	 or nil if out of memory."
	<api>
	<var: 'aCString' type: 'const char *'>
	<inline: false>
	| len newString |
	len := self strlen: aCString.
	newString := self
					allocateSlots: (self numSlotsForBytes: len)
					format: (self byteFormatForNumBytes: len)
					classIndex: ClassByteStringCompactIndex.
	newString ifNotNil:
		[self strncpy: (self cCoerceSimple: newString + self baseHeaderSize to: #'char *')
			_: aCString
			_: len]. "(char *)strncpy()"
	^newString
]

{ #category : #'simulation only' }
SpurMemoryManager >> stringOf: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter stringOf: oop
]

{ #category : #'simulation only' }
SpurMemoryManager >> success: boolean [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter success: boolean
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> sufficientSpaceAfterGC: numBytes [
	"This is ObjectMemory's funky entry-point into its incremental GC,
	 which is a stop-the-world a young generation reclaimer.  In Spur
	 we run the scavenger.  Answer if space is not low."

	| heapSizePostGC |
	self assert: numBytes = 0.
	self scavengingGCTenuringIf: TenureByAge.
	heapSizePostGC := segmentManager totalOldSpaceCapacity - totalFreeOldSpace.
	(heapSizePostGC - heapSizeAtPreviousGC) asFloat / heapSizeAtPreviousGC >= heapGrowthToSizeGCRatio ifTrue:
		[self fullGC].
	[totalFreeOldSpace < growHeadroom
	 and: [(self growOldSpaceByAtLeast: 0) notNil]] whileTrue:
		[totalFreeOldSpace >= growHeadroom ifTrue:
			[^true]].
	lowSpaceThreshold > totalFreeOldSpace ifTrue: "space is low"
		[lowSpaceThreshold := 0. "avoid signalling low space twice"
		 ^false].
	^true
]

{ #category : #allocation }
SpurMemoryManager >> sufficientSpaceToInstantiate: classObj indexableSize: indexableFields [
	self shouldNotImplement
]

{ #category : #'simulation only' }
SpurMemoryManager >> superclassOf: classPointer [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter superclassOf: classPointer
]

{ #category : #snapshot }
SpurMemoryManager >> swizzleFieldsOfFreeChunk: chunk [
	<inline: true>
	| field chunkBytes |
	field := self fetchPointer: self freeChunkNextIndex ofFreeChunk: chunk.
	field ~= 0 ifTrue:
		[self storePointerNoAssert: self freeChunkNextIndex
			ofFreeChunk: chunk
			withValue: (segmentManager swizzleObj: field)].
	chunkBytes := self bytesInObject: chunk.
	false ifTrue: "The prevPointer is not guaranteed to be valid in older images.
				 updateListStartingAt: via updateFreeLists does restore the prev pointer
				 in all small free lists, so simply avoid swizzling it now."
		[(self isLilliputianSize: chunkBytes) ifFalse:
			[field := self fetchPointer: self freeChunkPrevIndex ofFreeChunk: chunk.
			 field ~= 0 ifTrue:
				[self storePointerNoAssert: self freeChunkPrevIndex
					ofFreeChunk: chunk
					withValue: (segmentManager swizzleObj: field)]]].
	chunkBytes >= (self numFreeLists * self allocationUnit) ifTrue:
		[self freeChunkParentIndex to: self freeChunkLargerIndex do:
			[:index|
			 field := self fetchPointer: index ofFreeChunk: chunk.
			 field ~= 0 ifTrue:
				[self storePointerNoAssert: index
					ofFreeChunk: chunk
					withValue: (segmentManager swizzleObj: field)]]]
]

{ #category : #snapshot }
SpurMemoryManager >> swizzleFieldsOfObject: oop [
	| fieldAddr fieldOop |
	<inline: true>
	fieldAddr := oop + (self lastPointerOfWhileSwizzling: oop).
	[self oop: fieldAddr isGreaterThanOrEqualTo: oop + self baseHeaderSize] whileTrue:
		[fieldOop := self longAt: fieldAddr.
		 (self isNonImmediate: fieldOop) ifTrue:
			[self longAt: fieldAddr put: (segmentManager swizzleObj: fieldOop)].
		 fieldAddr := fieldAddr - self bytesPerOop]
]

{ #category : #'obj stacks' }
SpurMemoryManager >> swizzleObjStackAt: objStackRootIndex [
	"On load, swizzle the pointers in an obj stack. Answer the obj stack's oop."
	| firstPage page stackOrNil index field |
	firstPage := stackOrNil := self fetchPointer: objStackRootIndex ofObject: hiddenRootsObj.
	stackOrNil = nilObj ifTrue:
		[^stackOrNil].
	[self assert: (self numSlotsOfAny: stackOrNil) = ObjStackPageSlots.
	 self assert: (self fetchPointer: ObjStackMyx ofObject: stackOrNil) = objStackRootIndex.
	 "There are four fixed slots in an obj stack, and a Topx of 0 indicates empty, so
	   if there were 5 slots in an oop stack, full would be 2, and the last 0-rel index is 4.
	   Hence the last index is topx + fixed slots - 1, or topx + ObjStackNextx"
	 index := (self fetchPointer: ObjStackTopx ofObject: stackOrNil) + ObjStackNextx.
	 "swizzle fields including ObjStackNextx, excluding ObjStackFreex and leave field containing the next link."
	 [field := self fetchPointer: index ofObject: stackOrNil.
	  (field = 0 or: [self isImmediate: field]) ifFalse:
		[field := segmentManager swizzleObj: field.
		 self storePointer: index ofObjStack: stackOrNil withValue: field].
	  (index := index - 1) >= ObjStackNextx] whileTrue.
	 (stackOrNil := field) ~= 0] whileTrue.
	(stackOrNil := self fetchPointer: ObjStackFreex ofObject: firstPage) ~=  0 ifTrue:
		[page := firstPage.
		 [stackOrNil := segmentManager swizzleObj: stackOrNil.
		  self storePointer: ObjStackFreex ofObjStack: page withValue: stackOrNil.
		  page := stackOrNil.
		  (stackOrNil := self fetchPointer: ObjStackFreex ofObject: page) ~=  0] whileTrue].
	self assert: (self isValidObjStackAt: objStackRootIndex).
	^self fetchPointer: objStackRootIndex ofObject: hiddenRootsObj
]

{ #category : #'word size' }
SpurMemoryManager >> tagMask [
	^self subclassResponsibility
]

{ #category : #'plugin support' }
SpurMemoryManager >> tenuringIncrementalGC [
	"Do an incremental GC that tenures all surviving young objects to old space."
	<api>
	self flushNewSpace
]

{ #category : #accessing }
SpurMemoryManager >> tenuringThreshold [
	"In the scavenger the tenuring threshold is effectively a number of bytes of objects,
	 accessed as a proportion of pastSpace from 0 to 1.   In the Squeak image the tenuring
	 threshold is an object count. Marry the two notions by multiplying the proportion by
	 the size of pastSpace and dividing by the average object size, as derived from observation."
	^(scavenger scavengerTenuringThreshold * scavenger pastSpaceBytes // self averageObjectSizeInBytes) asInteger
]

{ #category : #accessing }
SpurMemoryManager >> tenuringThreshold: threshold [
	"c.f. tenuringThreshold"
	threshold < 0 ifTrue:
		[^PrimErrBadArgument].
	scavenger scavengerTenuringThreshold:
		(threshold * self averageObjectSizeInBytes) asFloat
		/ scavenger pastSpaceBytes asFloat.
	^0
]

{ #category : #'class table puns' }
SpurMemoryManager >> thirtyTwoBitLongsClassIndexPun [
	"Class puns are class indices not used by any class.  There may be
	 an entry for the pun that refers to the notional class of objects with
	 this class index.  But because the index doesn't match the class it
	 won't show up in allInstances, hence hiding the object with a pun as
	 its class index. The puns occupy indices 16 through 31."
	<cmacro>
	^18
]

{ #category : #'obj stacks' }
SpurMemoryManager >> topOfObjStack: objStack [
	| topx |
	"This assert is tricky.  push:onObjStack: may call topOfObjStack: just after pushing an
	 empty page on the stack, and will ask if the second page is valid."
	self eassert: [self isValidObjStackPage: objStack
					myIndex: (self fetchPointer: ObjStackMyx ofObject: objStack)
					firstPage: (objStack = (self fetchPointer: (self fetchPointer: ObjStackMyx ofObject: objStack) ofObject: hiddenRootsObj))].
	topx := self fetchPointer: ObjStackTopx ofObject: objStack.
	topx = 0 ifTrue:
		[self assert: (self fetchPointer: ObjStackNextx ofObject: objStack) = 0.
		^nil].
	^self fetchPointer: topx + ObjStackFixedSlots - 1 ofObject: objStack
]

{ #category : #'interpreter access' }
SpurMemoryManager >> topRemappableOop [
	<api>
	"Answers the top of the remappable oop stack. Useful when writing loops.
	 We support this excessence for compatibility with ObjectMemory.
	 Spur doesn't GC during allocation."
	^remapBuffer at: remapBufferCount
]

{ #category : #'indexing primitive support' }
SpurMemoryManager >> totalByteSizeOf: oop [
	<returnTypeC: #usqLong>
	^(self isImmediate: oop)
		ifTrue: [0]
		ifFalse: [self bytesInObject: oop]
]

{ #category : #'free space' }
SpurMemoryManager >> totalFreeListBytes [
	"This method both computes the actual number of free bytes by traversing all free objects
	 on the free lists/tree, and checks that the tree is valid.  It is used mainly by checkFreeSpace."
	| totalFreeBytes bytesInChunk listNode nextNode |
	totalFreeBytes := 0.
	1 to: self numFreeLists - 1 do:
		[:i| 
		bytesInChunk := i * self allocationUnit.
		listNode := freeLists at: i.
		[listNode ~= 0] whileTrue:
			[totalFreeBytes := totalFreeBytes + bytesInChunk.
			 self assertValidFreeObject: listNode.
			 self assert: bytesInChunk = (self bytesInObject: listNode).
			 nextNode := self fetchPointer: self freeChunkNextIndex ofFreeChunk: listNode.
			 self assert: nextNode ~= listNode.
			 listNode := nextNode]].

	self freeTreeNodesDo:
		[:treeNode|
		 bytesInChunk := self bytesInObject: treeNode.
		 self assert: bytesInChunk / self allocationUnit >= self numFreeLists.
		 listNode := treeNode.
		 [listNode ~= 0] whileTrue:
			["self printFreeChunk: listNode"
			 self assertValidFreeObject: listNode.
			 self assert: (listNode = treeNode
						  or: [(self fetchPointer: self freeChunkParentIndex ofFreeChunk: listNode) = 0]).
			 totalFreeBytes := totalFreeBytes + bytesInChunk.
			 self assert: bytesInChunk = (self bytesInObject: listNode).
			 nextNode := self fetchPointer: self freeChunkNextIndex ofFreeChunk: listNode.
			 self assert: nextNode ~= listNode.
			 listNode := nextNode].
		 treeNode].
	^totalFreeBytes
]

{ #category : #'debug support' }
SpurMemoryManager >> totalFreeOldSpace [
	<doNotGenerate>
	^ totalFreeOldSpace
]

{ #category : #accessing }
SpurMemoryManager >> totalFreeOldSpace: anInteger [
	totalFreeOldSpace := anInteger
]

{ #category : #accessing }
SpurMemoryManager >> totalMemorySize [
	^scavenger newSpaceCapacity + segmentManager totalBytesInSegments
]

{ #category : #'gc - global' }
SpurMemoryManager >> traceImmediatelySlotLimit [
	"Arbitrary level at which to defer tracing large objects until later.
	 The average slot size of Smalltalk objects is typically near 8.
	 We do require traceImmediatelySlotLimit to be < numSlotsMask."
	^64
]

{ #category : #'simulation only' }
SpurMemoryManager >> transcript [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter transcript
]

{ #category : #accessing }
SpurMemoryManager >> trueObject [
	<api>
	^trueObj
]

{ #category : #accessing }
SpurMemoryManager >> trueObject: anOop [
	"For mapInterpreterOops"
	trueObj := anOop
]

{ #category : #simulation }
SpurMemoryManager >> unalignedLong32At: index [
	"Support for primitiveFFIIntegerAt[Put]"
	<doNotGenerate>
	| odd hi lo |
	(odd := index bitAnd: 3) = 0 ifTrue:
		[^self long32At: index].
	lo := self long32At: index - odd.
	hi := self long32At: index + 4 - odd.
	^lo >> (odd * 8) + ((hi bitAnd: 1 << (odd * 8) - 1) << (4 - odd * 8))
]

{ #category : #simulation }
SpurMemoryManager >> unalignedLong32At: index put: aValue [
	"Support for primitiveFFIIntegerAt[Put]"
	<doNotGenerate>
	| odd hi lo mask |
	aValue < 0 ifTrue:
		[self unalignedLong64At: index put: (aValue bitAnd: 16rFFFFFFFF).
		 ^aValue].
	(odd := index bitAnd: 3) = 0 ifTrue:
		[^self long32At: index put: aValue].
	mask := 1 << (odd * 8) - 1.
	lo := self long32At: index - odd.
	self long32At: index - odd
		put: (lo bitAnd: mask)
			+ ((aValue bitAnd: 1 << (4 - odd * 8) - 1) << (odd * 8)).
	hi := self long32At: index + 4 - odd.
	self long32At: index + 4 - odd
		put: (hi bitClear: mask) + (aValue >> (4 - odd * 8) bitAnd: mask).
	^aValue
]

{ #category : #simulation }
SpurMemoryManager >> unalignedLong64At: index [
	"Support for primitiveFFIIntegerAt[Put]"
	<doNotGenerate>
	| odd hi lo |
	(odd := index bitAnd: 7) = 0 ifTrue:
		[^self long64At: index].
	lo := self long64At: index - odd.
	hi := self long64At: index + 8 - odd.
	^lo >> (odd * 8) + ((hi bitAnd: 1 << (odd * 8) - 1) << (8 - odd * 8))
]

{ #category : #simulation }
SpurMemoryManager >> unalignedLong64At: index put: aValue [
	"Support for primitiveFFIIntegerAt[Put]"
	<doNotGenerate>
	| odd hi lo mask |
	aValue < 0 ifTrue:
		[self unalignedLong64At: index put: (aValue bitAnd: 16rFFFFFFFFFFFFFFFF).
		 ^aValue].
	(odd := index bitAnd: 7) = 0 ifTrue:
		[^self long64At: index put: aValue].
	mask := 1 << (odd * 8) - 1.
	lo := self long64At: index - odd.
	self long64At: index - odd
		put: (lo bitAnd: mask)
			+ ((aValue bitAnd: 1 << (8 - odd * 8) - 1) << (odd * 8)).
	hi := self long64At: index + 8 - odd.
	self long64At: index + 8 - odd
		put: (hi bitClear: mask) + (aValue >> (8 - odd * 8) bitAnd: mask).
	^aValue
]

{ #category : #simulation }
SpurMemoryManager >> unalignedShortAt: index [
	"Support for primitiveFFIIntegerAt[Put]"
	<doNotGenerate>
	| hi lo |
	(index bitAnd: 1) = 0 ifTrue:
		[^self shortAt: index].
	lo := self shortAt: index - 1.
	hi := self shortAt: index + 1.
	^lo >> 8 + ((hi bitAnd: 16rFF) << 8)
]

{ #category : #simulation }
SpurMemoryManager >> unalignedShortAt: index put: aValue [
	"Support for primitiveFFIIntegerAt[Put]"
	<doNotGenerate>
	(index bitAnd: 1) = 0 ifTrue:
		[^self shortAt: index put: aValue].
	self shouldBeImplemented.
	^aValue
]

{ #category : #'primitive support' }
SpurMemoryManager >> uniqueIndex: classIndex allInstancesInto: start limit: limit resultsInto: binaryBlock [
	<inline: true>
	| count ptr |
	count := 0.
	ptr := start.
	self allHeapEntitiesDo:
		[:obj| "continue enumerating even if no room so as to unmark all objects."
		 (MarkObjectsForEnumerationPrimitives
				ifTrue: [self isMarked: obj]
				ifFalse: [true]) ifTrue:
			[(self isNormalObject: obj)
				ifTrue:
					[MarkObjectsForEnumerationPrimitives ifTrue:
						[self setIsMarkedOf: obj to: false].
					 (self classIndexOf: obj) = classIndex ifTrue:
					 	[count := count + 1.
						 ptr < limit ifTrue:
							[self longAt: ptr put: obj.
							 ptr := ptr + self bytesPerOop]]]
				ifFalse:
					[MarkObjectsForEnumerationPrimitives ifTrue:
						[(self isSegmentBridge: obj) ifFalse:
							[self setIsMarkedOf: obj to: false]]]]].
	binaryBlock value: count value: ptr

]

{ #category : #'free space' }
SpurMemoryManager >> unlinkFreeChunk: chunk atIndex: index chunkBytes: chunkBytes [
	^self 
		unlinkFreeChunk: chunk 
		atIndex: index 
		isLilliputianSize: (self isLilliputianSize: chunkBytes) 
]

{ #category : #'free space' }
SpurMemoryManager >> unlinkFreeChunk: chunk atIndex: index isLilliputianSize: lilliputian [ 
	"Unlink and answer a small chunk from one of the fixed size freeLists"
	<inline: true> "inlining is important because isLilliputianSize: is often true"
	|next|
	self assert: ((self bytesInObject: chunk) = (index * self allocationUnit)
				and: [index > 1 "a.k.a. (self bytesInObject: chunk) > self allocationUnit"
				and: [(self startOfObject: chunk) = chunk]]).
			
	"For some reason the assertion is not compiled correctly"
	self cCode: '' inSmalltalk: [self assert: (self isLilliputianSize: (self bytesInObject: chunk)) = lilliputian].
	
	freeLists
		at: index 
		put: (next := self
				fetchPointer: self freeChunkNextIndex
				ofFreeChunk: chunk).
	(lilliputian not and: [next ~= 0]) ifTrue:
		[self storePointer: self freeChunkPrevIndex ofFreeChunk: next withValue: 0].
	^chunk
]

{ #category : #'free space' }
SpurMemoryManager >> unlinkFreeChunk: freeChunk chunkBytes: chunkBytes [
	"Unlink a free object from the free lists. Do not alter totalFreeOldSpace. Used for coalescing."
	| index next prev |
	index := chunkBytes / self allocationUnit.
	
	"Pathological 64 bits case - size 1 - single linked list"
	(self isLilliputianSize: chunkBytes) ifTrue:
		[^self unlinkLilliputianChunk: freeChunk index: index].
	
	prev := self fetchPointer: self freeChunkPrevIndex ofFreeChunk: freeChunk.
	"Has prev element: update double linked list"
	prev ~= 0 ifTrue:
		[self 
			setNextFreeChunkOf: prev 
			withValue: (self fetchPointer: self freeChunkNextIndex ofFreeChunk: freeChunk) 
			chunkBytes: chunkBytes.
		 ^freeChunk].
	
	"Is the beginning of a list"
	"Small chunk"
	(index < self numFreeLists and: [1 << index <= freeListsMask]) ifTrue: 
		[self unlinkFreeChunk: freeChunk atIndex: index isLilliputianSize: false.
		 ^freeChunk].
	"Large chunk"
	 next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: freeChunk.
	 next = 0
		ifTrue: "no list; remove the interior node"
			[self unlinkSolitaryFreeTreeNode: freeChunk]
		ifFalse: "list; replace node with it"
			[self inFreeTreeReplace: freeChunk with: next].
	^freeChunk
	
	

	
]

{ #category : #'free space' }
SpurMemoryManager >> unlinkLilliputianChunk: freeChunk index: index [
	| node prev next |
	<inline: #never> "for profiling"
	 node := freeLists at: index.
	 prev := 0.
	 [node ~= 0] whileTrue:
		[self assert: node = (self startOfObject: node).
		 self assertValidFreeObject: node.
		 next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: node.
		 node = freeChunk ifTrue:
			[prev = 0
				ifTrue: [self unlinkFreeChunk: freeChunk atIndex: index isLilliputianSize: true]
				ifFalse: [self setNextFreeChunkOf: prev withValue: next isLilliputianSize: true].
			 ^freeChunk].
		 prev := node.
		 node := next].
	 self error: 'freeChunk not found in lilliputian chunk free list'
	
	

	
]

{ #category : #'free space' }
SpurMemoryManager >> unlinkSolitaryFreeTreeNode: freeTreeNode [
	"Unlink a freeTreeNode.  Assumes the node has no list (null next link)."
	| parent smaller larger |
	self assert: (self fetchPointer: self freeChunkNextIndex ofFreeChunk: freeTreeNode) = 0.

	"case 1. interior node has one child, P = parent, N = node, S = subtree (mirrored for large vs small)
			___				  ___
			| P |				  | P |
		    _/_				_/_
		    | N |		=>		| S |
		 _/_
		 | S |

	 case 2: interior node has two children, , P = parent, N = node, L = smaller, left subtree, R = larger, right subtree.
	 add the left subtree to the bottom left of the right subtree (mirrored for large vs small) 
			___				  ___
			| P |				  | P |
		    _/_				_/_
		    | N |		=>		| R |
		 _/_  _\_		    _/_
		 | L | | R |		    | L |"

	smaller := self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: freeTreeNode.
	larger := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: freeTreeNode.
	parent := self fetchPointer: self freeChunkParentIndex ofFreeChunk: freeTreeNode.
	parent = 0
		ifTrue: "no parent; stitch the subnodes back into the root"
			[smaller = 0
				ifTrue:
					[larger ~= 0 ifTrue:
						[self storePointer: self freeChunkParentIndex ofFreeChunk: larger withValue: 0].
					 freeLists at: 0 put: larger]
				ifFalse:
					[self storePointer: self freeChunkParentIndex ofFreeChunk: smaller withValue: 0.
					 freeLists at: 0 put: smaller.
					 larger ~= 0 ifTrue:
						[self addFreeSubTree: larger]]]
		ifFalse: "parent; stitch back into appropriate side of parent."
			[smaller = 0
				ifTrue: [self storePointer: (freeTreeNode = (self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: parent)
											ifTrue: [self freeChunkSmallerIndex]
											ifFalse: [self freeChunkLargerIndex])
							ofFreeChunk: parent
							withValue: larger.
						larger ~= 0 ifTrue:
							[self storePointer: self freeChunkParentIndex
								ofFreeChunk: larger
								withValue: parent]]
				ifFalse:
					[self storePointer: (freeTreeNode = (self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: parent)
											ifTrue: [self freeChunkSmallerIndex]
											ifFalse: [self freeChunkLargerIndex])
						ofFreeChunk: parent
						withValue: smaller.
					 self storePointer: self freeChunkParentIndex
						ofFreeChunk: smaller
						withValue: parent.
					 larger ~= 0 ifTrue:
						[self addFreeSubTree: larger]]]
]

{ #category : #'primitive support' }
SpurMemoryManager >> unmarkAllObjects [
	self allHeapEntitiesDo:
		[:obj|
		 (self isMarked: obj) ifTrue:
			[(self isNormalObject: obj)
				ifTrue:
					[self setIsMarkedOf: obj to: false]
				ifFalse:
					[(self isSegmentBridge: obj) ifFalse:
						[self setIsMarkedOf: obj to: false]]]].

]

{ #category : #'image segment in/out' }
SpurMemoryManager >> unmarkObjectsIn: arrayOfRoots [
	"This is part of storeImageSegmentInto:outPointers:roots:."
	0 to: (self numSlotsOf: arrayOfRoots) - 1 do:
		[:i| | oop |
		oop := self followField: i ofObject: arrayOfRoots.
		(self isNonImmediate: oop) ifTrue:
			[self setIsMarkedOf: oop to: false]]
]

{ #category : #compaction }
SpurMemoryManager >> unmarkSurvivingObjectsForCompact [
	self allPastSpaceObjectsDo:
		[:objOop|
		(self isMarked: objOop) ifTrue:
			[self setIsMarkedOf: objOop to: false]]
]

{ #category : #'primitive support' }
SpurMemoryManager >> unpinObject: objOop [
	self assert: (self isNonImmediate: objOop).
	self setIsPinnedOf: objOop to: false.
	^0
]

{ #category : #initialization }
SpurMemoryManager >> updateFreeLists [
	"Snapshot did not guarantee the state of the freelist prevLink, so we need to update it.
	 Effectively transforms the freechunk single linked list in double linked list."
	|min|
	"Small chunks"
	"Skip in 64 bits size 1 which is single linked list - pathological case"
	self wordSize = 8 ifTrue: [min := 3] ifFalse: [min := 2].
	min to: self numFreeLists - 1 do:
		[:i| self updateListStartingAt: (freeLists at: i)].
	"Large chunks"
	self freeTreeNodesDo: [:freeNode |
		self updateListStartingAt: freeNode.
		freeNode]
]

{ #category : #'gc - global' }
SpurMemoryManager >> updateFullGCStats [	
	"Stats updated (since VM start-up): 
	1) number of full GCs,
	2) time spent in full GC,
	3) time spent in compaction (included in 2)
	4) time spent in sweep phase (included in 2 & 3, 0 if no sweep phase)
	5) time spent in mark phase (included in 2)"
	statFullGCs := statFullGCs + 1.
	statFullGCUsecs := statFullGCUsecs + (statGCEndUsecs - gcStartUsecs).
	statCompactionUsecs := statCompactionUsecs + (statGCEndUsecs - compactionStartUsecs).
	gcSweepEndUsecs = 0 ifFalse: [statSweepUsecs := statSweepUsecs + (gcSweepEndUsecs - compactionStartUsecs)].
	statMarkUsecs := statMarkUsecs + (gcMarkEndUsecs - gcStartUsecs).
]

{ #category : #initialization }
SpurMemoryManager >> updateListStartingAt: freeNode [ 
	|prev obj|
	freeNode = 0 ifTrue: [^self].
	self deny: (self isLilliputianSize: (self bytesInObject: freeNode)).
	prev := freeNode.
	self storePointer: self freeChunkPrevIndex ofFreeChunk: prev withValue: 0.
	[obj := self fetchPointer: self freeChunkNextIndex ofFreeChunk: prev.
	 obj ~= 0] whileTrue:
		[self storePointer: self freeChunkPrevIndex ofFreeChunk: obj withValue: prev.
		 prev := obj]
]

{ #category : #'image segment in/out' }
SpurMemoryManager >> updatePostScavenge: anObj [
	<inline: true>
	^(self isForwarded: anObj) ifTrue: [self followForwarded: anObj] ifFalse: [anObj]
]

{ #category : #'obj stacks' }
SpurMemoryManager >> updateRootOfObjStackAt: objStackRootIndex with: newRootPage [
	self storePointer: objStackRootIndex
		ofObject: hiddenRootsObj
		withValue: newRootPage.
	objStackRootIndex caseOf: {
		[MarkStackRootIndex]		->	[markStack := newRootPage].
		[WeaklingStackRootIndex]	->	[weaklingStack := newRootPage].
		[MournQueueRootIndex]	->	[mournQueue := newRootPage] }.
	^newRootPage
]

{ #category : #accessing }
SpurMemoryManager >> updateSweepEndUsecs [
	gcSweepEndUsecs := coInterpreter ioUTCMicrosecondsNow.
]

{ #category : #'class table' }
SpurMemoryManager >> validClassTableHashes [
	"Check the hashes of classes in the table.  The tricky thing here is that classes may be duplicated
	 in the table.  So each entry must be in the table at its hash, even if it is elsewhere in the table."

	self validClassTableRootPages ifFalse:
		[^false].

	self classTableEntriesDo:
		[:classOrNil :ignored| | hash |
		 (self isForwarded: classOrNil) ifTrue:
			[^0].
		  hash := self rawHashBitsOf: classOrNil.
		  hash = 0 ifTrue:
			[^false].
		  (self noCheckClassAtIndex: hash) ~= classOrNil ifTrue:
			[^false]].

	^true
]

{ #category : #'class table' }
SpurMemoryManager >> validClassTableRootPages [
	"Answer if hiddenRootsObj is of the right size with the
	 expected contents, and if numClassTablePages is correct."

	(self numSlotsOf: hiddenRootsObj) = (self classTableRootSlots + self hiddenRootSlots) ifFalse:
		[^false].

	"is it in range?"
	(numClassTablePages > 1 and: [numClassTablePages <= self classTableRootSlots]) ifFalse:
		[^false].
	"are all pages the right size?"
	0 to: numClassTablePages - 1 do:
		[:i| | obj |
		 obj := self fetchPointer: i ofObject: hiddenRootsObj.
		 ((self addressCouldBeObj: obj)
		  and: [(self numSlotsOf: obj) = self classTablePageSize]) ifFalse:
			[^false]].
	"are all entries beyond numClassTablePages nil?"
	numClassTablePages to: self classTableRootSlots - 1 do:
		[:i|
		(self fetchPointer: i ofObject: hiddenRootsObj) ~= nilObj ifTrue:
			[^false]].
	^true
]

{ #category : #'free space' }
SpurMemoryManager >> validFreeTree [
	<api>
	^(self validFreeTreeChunk: (freeLists at: 0) parent: 0) isNil
]

{ #category : #'free space' }
SpurMemoryManager >> validFreeTreeChunk: chunk [
	<inline: false>
	(segmentManager segmentContainingObj: chunk) ifNil:
		[^false].
	^(self validFreeTreeChunk: chunk parent: (self fetchPointer: self freeChunkParentIndex ofFreeChunk: chunk)) isNil
]

{ #category : #'free space' }
SpurMemoryManager >> validFreeTreeChunk: chunk parent: parent [
	<var: 'reason' type: #'const char *'>
	<returnTypeC: #'const char *'>
	chunk = 0 ifTrue:
		[^nil].
	(self addressCouldBeOldObj: chunk) ifFalse:
		[^'not in old space'].
	(self bytesInObject: chunk) / self allocationUnit < self numFreeLists ifTrue:
		[^'too small'].
	parent ~= (self fetchPointer: self freeChunkParentIndex ofFreeChunk: chunk) ifTrue:
		[^'bad parent'].

	(segmentManager segmentContainingObj: chunk) ~~ (segmentManager segmentContainingObj: (self addressAfter: chunk)) ifTrue:
		[^'not in one segment'].
	(self validFreeTreeChunk: (self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: chunk) parent: chunk) ifNotNil:
		[:reason| ^reason].
	(self validFreeTreeChunk: (self fetchPointer: self freeChunkLargerIndex ofFreeChunk: chunk) parent: chunk) ifNotNil:
		[:reason| ^reason].
	^nil
]

{ #category : #'obj stacks' }
SpurMemoryManager >> validObjStacks [
	^(markStack = nilObj or: [self isValidObjStack: markStack])
	  and: [(weaklingStack = nilObj or: [self isValidObjStack: weaklingStack])
	  and: [mournQueue = nilObj or: [self isValidObjStack: mournQueue]]]
]

{ #category : #'gc - scavenge/compact' }
SpurMemoryManager >> vanillaRemapObj: objOop [
	"Scavenge or simply follow objOop.  Answer the new location of objOop.
	 The send should have been guarded by a send of shouldRemapOop:.
	 The method is called remapObj: for compatibility with ObjectMemory."
	<inline: true>
	| resolvedObj |
	self assert: (self shouldRemapOop: objOop).
	(self isForwarded: objOop)
		ifTrue:
			[resolvedObj := self followForwarded: objOop]
		ifFalse:
			[self deny: (self isInFutureSpace: objOop).
			 resolvedObj := objOop].
	(self scavengeInProgress
	 and: [(self isReallyYoung: resolvedObj) "don't scavenge immediate, old, or CogMethod objects."
	 and: [(self isInFutureSpace: resolvedObj) not]]) ifTrue: 
		[^scavenger copyAndForward: resolvedObj].
	^resolvedObj
]

{ #category : #'gc - scavenge/compact' }
SpurMemoryManager >> vanillaShouldRemapObj: objOop [
	<inline: true>
	"Answer if the obj should be scavenged, or simply followed. Sent via the compactor
	 from shouldRemapObj:.  We test for being already scavenged because mapStackPages
	 via mapInterpreterOops may be applied twice in the context of a global GC where a
	 scavenge, followed by a scan-mark-free, and final compaction passes may result in
	 scavenged fields being visited twice."
	^(self isForwarded: objOop)
	  or: [(self isReallyYoungObject: objOop)
		 and: [(self isInFutureSpace: objOop) not]]
]

{ #category : #'memory access' }
SpurMemoryManager >> vmEndianness [
	<api>
	"1 = big, 0 = little"
	^self cCode: [VMBIGENDIAN] inSmalltalk: [self subclassResponsibility]
]

{ #category : #'class table puns' }
SpurMemoryManager >> weakArrayClassIndexPun [
	"Class puns are class indices not used by any class.  There is an entry
	 for the pun that refers to the notional class of objects with this class
	 index.  But because the index doesn't match the class it won't show up
	 in allInstances, hence hiding the object with a pun as its class index.
	 The puns occupy indices 16 through 31."
	<cmacro>
	^17
]

{ #category : #'header formats' }
SpurMemoryManager >> weakArrayFormat [
	<api>
	<cmacro>
	^4
]

{ #category : #'spur bootstrap' }
SpurMemoryManager >> weaklingStack [
	^weaklingStack
]

{ #category : #accessing }
SpurMemoryManager >> weaklingStack: anOop [ 
	<doNotGenerate>
	weaklingStack := anOop
]

{ #category : #'debug printing' }
SpurMemoryManager >> whereIsMaybeHeapThing: anOop [
	<returnTypeC: 'char *'>
	(self isInNewSpace: anOop) ifTrue:
		[(self isInEden: anOop) ifTrue: [^' is in eden'].
		 (self isInFutureSpace: anOop) ifTrue: [^' is in future space'].
		 (self isInPastSpace: anOop) ifTrue: [^' is in past space'].
		 ^' is in new space'].
	(self isInOldSpace: anOop) ifTrue:
		[(segmentManager segmentContainingObj: anOop) ifNotNil:
			[^' is in old space'].
		 ^' is between old space segments'].
	^nil
]

{ #category : #'debug support' }
SpurMemoryManager >> withSimulatorFetchPointerMovedAsideDo: aBlock [
	"For performance, remove the simulator implementation of fetchPointer:ofObject:
	 while aBlock is running and answer the block's result."
	| theMethod |
	theMethod := self class lookupSelector: #fetchPointer:ofObject:.
	self deny: (theMethod isNil or: [theMethod methodClass == SpurMemoryManager]).
	theMethod methodClass basicRemoveSelector: #fetchPointer:ofObject:.
	^aBlock ensure:
		[theMethod methodClass
			basicAddSelector: #fetchPointer:ofObject:
			withMethod: theMethod]
]

{ #category : #'header formats' }
SpurMemoryManager >> wordIndexableFormat [
	"Either firstLongFormat or sixtyFourBitIndexableFormat"
	^self subclassResponsibility
]

{ #category : #'word size' }
SpurMemoryManager >> wordSize [
	"Answer the manager's word size, which is the size of an oop, and which
	 is assumed to be equivalent to the underlying machine's word size."
	^self subclassResponsibility
]

{ #category : #'class table puns' }
SpurMemoryManager >> wordSizeClassIndexPun [
	^self subclassResponsibility
]

{ #category : #simulation }
SpurMemoryManager >> writeEnableMemory [
	<doNotGenerate>
	memory class == ReadOnlyArrayWrapper ifTrue:
		[memory := memory array]
]

{ #category : #snapshot }
SpurMemoryManager >> writeImageSegmentsToFile: aBinaryStream [
	<doNotGenerate>
	^segmentManager writeImageSegmentsToFile: aBinaryStream
]

{ #category : #simulation }
SpurMemoryManager >> writeProtectMemory [
	<doNotGenerate>
	memory class ~~ ReadOnlyArrayWrapper ifTrue:
		[memory := ReadOnlyArrayWrapper around: memory]
]
