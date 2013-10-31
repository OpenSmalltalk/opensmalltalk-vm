"
SpurMemoryManager is a new object representation and garbage collector for the Cog VM's.  Spur is dedicated to Andreas Raab, friend and colleague.  I miss you, Andreas.  The goal for Spur is an overall improvement in Cog of -50% (twice as fast) for memory-intensive benchmarks.  

A detailed design sketch is included below after the instance variable descriptions.

Instance Variables
	becomeEffectsFlags		<Integer>
	checkForLeaks:				<Boolean>
	classTableBitmap			<CArrayAccessor on: ByteArray>
	classTableFirstPage:		<Integer oop>
	classTableIndex:			<Integer>
	coInterpreter:				<StackInterpreter|CoInterpreter (StackInterpreterSimulator|CogVMSimulator)>
	endOfMemory:				<Integer address>
	falseObj:					<Integer oop>
	firstFreeChunk				<Integer address|nil>
	freeLists:					<CArray on: memory>
	freeListMask:				<Integer>
	freeOldSpaceStart:			<Integer address>
	freeStart:					<Integer address>
	gcStartUsecs:				<Integer>
	heapMap:					<CogCheck32BitHeapMap>
	hiddenRootsObj:			<Integer oop>
	lastHash:					<Integer>
	lowSpaceThreshold:		<Integer address>
	marking:					<Boolean>
	memory:					<Bitmap|LittleEndianBitmap>
	needGCFlag:				<Boolean>
	newSpaceLimit:				<Integer address>
	nilObj:						<Integer oop>
	numClassTablePages:		<Integer>
	pastSpaceStart:			<Integer address>
	remapBuffer:				<CArrayAccessor on: (Array new: RemapBufferSize)>
	remapBufferCount:			<Integer>
	scavengeInProgress:		<Boolean>
	scavengeThreshold:		<Integer address>
	scavenger:					<SourGenerationScavenger>
	segmentManager:			<SpurSegmentManager>
	signalLowSpace:			<Boolean>
	shrinkThreshold			<Integer>
	specialObjectsOop:		<Integer oop>
	startOfMemory:				<Integer address>
	statFGCDeltaUsecs:		<Integer>
	statFullGCUsecs:			<Integer>
	statFullGCs:					<Integer>
	statGCEndUsecs:			<Integer>
	statGrowMemory:			<Integer>
	statIGCDeltaUsecs:			<Integer>
	statIncrGCUsecs:			<Integer>
	statIncrGCs:				<Integer>
	statMarkCount:				<Integer>
	statMkFwdCount:			<Integer>
	statRootTableCount:		<Integer>
	statRootTableOverflows:	<Integer>
	statSGCDeltaUsecs:		<Integer>
	statScavengeGCUsecs:		<Integer>
	statScavenges:				<Integer>
	statShrinkMemory:			<Integer>
	statSpecialMarkCount:		<Integer>
	statSurvivorCount:			<Integer>
	statSweepCount:			<Integer>
	totalFreeOldSpace:			<Integer>
	trueObj:					<Integer oop>

becomeEffectsFlags
	- a set of flags to limit the work done during become; one of BecameCompiledMethodFlag, BecamePointerObjectFlag
	
checkForLeaks
	- a set of flags determining when to run leak checks on the heap's contents

classTableBitmap
	- a bitmap used to mark used classTable entries (i.e. marks classIndices, not class objects), used to reclaim unused entries.

classTableFirstPage
	- the first page of the class table which contains all classes known to the VM at known indices

classTableIndex
	- the last known used index in the class table, used to limit the search for empty slots

coInterpreter
	- the VM interpreter using this heap

endOfMemory
	- the address past the last oldSpace segment

falseObj
	- the oop of the false object; must be the second object in oldSpace

firstFreeChunk
	- the free chunk at the lowest address discovered during global gc's sweep through the heap.  used in compaction.

freeLists
	- an array of list heads of free chunks of each size (in allocationUnits).  the 0'th element
	  is the head of a tree of free chunks of size > 63 slots in 64-bits or 31 slots in 32-bits.
	  freeLists is the firstIndexableField of the fourth object in oldSpace.

freeListMask
	- a bitmap of flags with a 1 set whereever the freeLists has a non-empty entry, used to limit the search for free chunks

freeOldSpaceStart
	- the last used address in oldSpace.  The space between freeOldSpaceStart and endOfMemory can be used for oldSpace allocations.
	  Given freeLists this probably isn't useful and shoud be discarded in favouf of endOfMemory.

freeStart
	- the last used address in eden.  this is where new objects are allocated if there is room in eden.

gcStartUsecs
	- the time in microseconds of the start of the most recent gc, used to compute the duration of a gc.

heapMap
	- a bitmap used to check for leaks. a bit is set in the map at each object's header.  every pointer in the heap should point to the header of an object

hiddenRootsObj
	- the root page of the class table and some other toos (e.g. the ephemeron queue). its first
	  numClassTablePages elements are pages containing classes. Remaining slots hold other
	  roots the VM needs.  Must be the fifth object in oldSpace.

lastHash
	- the last object hash value.  a pseudo-randome number generator.

lowSpaceThreshold
	- the ammount of free memory below which the low space condition should be signalled.

marking
	- a flag set and cleared in markAccessibleObjects to allow ensureRoomOnObjStackAtIndex: to know whether to mark a new obj stack page or not.

memory
	- in the Simulator this is the single oldSpace segment that contains the codeZone, newSpace and oldSpace.  In C it is effectively the base address of used memory.

needGCFlag
	- a boolean flag set if a scavenge is needed

newSpaceLimit
	- the last address in newSpace (the last address in eden)

nilObj
	- the oop of the nil object; must be the first object in oldSpace

numClassTablePages:
	- the number of used pages in the classTable

pastSpaceStart
	- the address past the last object in pastSpace, used to enumerate objects in newSpace.

remampBuffer:
	- an Array of objects used to implement pushRemappableOop: et al for compatibility with ObjectMemory.
	  Its functionality isnt needed because Spur will never GC during allocation.  But it muts be present and
	  correct, otherwise many primitives that use pushRemappableOop: et al would have to be rewritten.

remapBufferCount:
	- the index of the last used entry in remampBuffer

scavengeInProgress
	- flag indicating what it says it does

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

startOfMemory
	- the first address in newSpace (the first address in either pastSpace or futureSpace)

statFGCDeltaUsecs statFullGCUsecs statFullGCs statGCEndUsecs statGrowMemory statIGCDeltaUsecs statIncrGCUsecs statIncrGCs statMarkCount statMkFwdCount statRootTableCount statRootTableOverflows statSGCDeltaUsecs statScavengeGCUsecs statScavenges statShrinkMemory statSpecialMarkCount statSurvivorCount statSweepCount
	- various statistics

totalFreeOldSpace
	- the total free space on the free lists
	
trueObj
	- the oop of the false object; must be the third object in oldSpace


Invariants (far from an exhaustive list; I'm adding to this as they arise; please prompt me to add undocumented ones):

On image load no object contains a forwarding pointer, and the image contains no forwarders. True because
a) the SpurBootstrap eliminates forwarders before saving its transformed image
b) snapshot does a fullGC which will follow forwarding pointers.
This is checked with an assert in swizzleFieldsOfObject:/lastPointerOfWhileSwizzling:.

classTableIndex ranges from classTablePageSize to classTableMask, since the first page is reserved for system classes, and the VM won't assign classes there-in.

Design
The design objectives for the Spur memory manager are

- efficient object representation a la Eliot Miranda's VisualWorks 64-bit object representation that uses a 64-bit header, eliminating direct class references so that all objects refer to their classes indirectly.  Instead the header contains a constant class index, in a field smaller than a full pointer, These class indices are used in inline and first-level method caches, hence they do not have to be updated on GC (although they do have to be traced to be able to GC classes).  Classes are held in a sparse weak table.  The class table needs only to be indexed by an instance's class index in class hierarchy search, in the class primitive, and in tracing live objects in the heap.  The additional header space is allocated to a much expanded identity hash field, reducing hash efficiency problems in identity collections due to the extremely small (11 bit) hash field in the old Squeak GC.  The identity hash field is also a key element of the class index scheme.  A class's identity hash is its index into the class table, so to create an instance of a class one merely copies its identity hash into the class index field of the new instance.  This implies that when classes gain their identity hash they are entered into the class table and their identity hash is that of a previously unused index in the table.  It also implies that there is a maximum number of classes in the table.  The classIndex field could be as narrow as 16 bits (for efficient access); at least for a few years 64k classes should be enough.  But currently we make it the same as the identityHash field, 22 bits, or 4M values.  A class is entered into the class table in the following operations:
	behaviorHash
	adoptInstance
	instantiate
	become  (i.e. if an old class becomes a new class)
		if target class field's = to original's id hash
		   and replacement's id hash is zero
			enter replacement in class table
behaviorHash is a special version of identityHash that must be implemented in the image by any object that can function as a class (i.e. Behavior).

- more immediate classes.  An immediate Character class would speed up String accessing, especially for WideString, since no instatiation needs to be done on at:put: and no dereference need be done on at:.  In a 32-bit system tag checking is complex since it is thought important to retain 31-bit SmallIntegers.  Hence, as in current Squeak, the least significant bit set implies a SmallInteger, but Characters would likely have a tag pattern of xxx10.  Hence masking with 11 results in two values for SmallInteger, xxx01 and xxx11 (for details see In-line cache probe for immediates below).  30-bit characters are more than adequate for Unicode.  In a 64-bit system we can use the full three bits and usefully implement an immediate Float.  As in VisualWorks a functional representation takes three bits away from the exponent.  Rotating to put the sign bit in the least significant non-tag bit makes expanding and contracting the 8-bit exponent to the 11-bit IEEE double exponent easy and makes comparing negative and positive zero easier (an immediate Float is zero if its unsigned 64-bits are < 16).  So the representation looks like
	| 8 bit exponent | 52 bit mantissa | sign bit | 3 tag bits |
For details see ""60-bit immediate Floats"" below.


- efficient scavenging.  The current Squeak GC uses a slow pointer-reversal collector that writes every field in live objects three times in each collection, twice in the pointer-reversing heap traversal to mark live objects and once to update the pointer to its new location.  A scavenger writes every field of live data twice in each collection, once as it does a block copy of the object when copying to to space, once as it traverses the live pointers in the to space objects.  Of course the block copy is a relatively cheap write.

- lazy become.  The JIT's use of inline cacheing provides a cheap way of avoiding scanning the heap as part of a become (which is the simple approach to implementing become in a system with direct pointers).  A becomeForward: on a (set of) non-zero-sized object(s) turns the object into a ""corpse"" or ""forwarding object"" whose first (non-header) word/slot is replaced by a pointer to the target of the becomeForward:.  The corpse's class index is set to one that identifies corpses (let's say classIndex 1), and, because it is a special, hidden class index, will always fail an inline cache test.  The inline cache failure code is then responsible for following the forwarding pointer chain (these are Iliffe vectors :) ) and resolving to the actual target.  (In the interpreter there needs to be a similar check when probing the method cache).   It has yet to be determined exactly how this is done (e.g. change the receiver register and/or stack contents and retry the send, perhaps scanning the current activation).  See become read barrier below on how we deal with becomes on objects with named inst vars.  We insist that objects are at least 16 bytes in size (see 8-byte alignment below) so that there will always be space for a forwarding pointer.  Since none of the immediate classes can have non-immediate instances and since we allocate the immediate class indices corresponding to their tag pattern (SmallInteger = 1 & 3, Character = 2, SmallFloat = 5?) we can use all the class indices from 0 to 7 for special uses, 0 = free, and e.g. 1 = isForwarded.  In general what;s going on here is the implemention of a partial read barrier. Certain operations require a read barrier to ensure access of the target of the forwarding corpse, not the corpse itself.  Read barriers stink, so we must restrict the read barrier to as few places as possible.  See become read barrier below.

- pinning.  To support a robust and easy-to-use FFI the memory manager must support temporary pinning where individual objects can be prevented from being moved by the GC for as long as required, either by being one of an in-progress FFI call's arguments, or by having pinning asserted by a primitive (allowing objects to be passed to external code that retains a reference to the object after returning).  Pinning probably implies a per-object ""is-pinned"" bit in the object header.  Pinning will be done via lazy become; i..e an object in new space will be becommed into a pinned object in old space.  We will only support pinning in old space.

- efficient old space collection.  An incremental collector (a la Dijkstra's three colour algorithm) collects old space, e.g. via an amount of tracing being hung off scavenges and/or old space allocations at an adaptive rate that keeps full garbage collections to a minimum.  It may also be possible to provide cheap compaction by using lazy become: and best-fit (see free space/free list below).

- 8-byte alignment.  It is advantageous for the FFI, for floating-point access, for object movement and for 32/64-bit compatibility to keep object sizes in units of 8 bytes.  For the FFI, 8-byte alignment means passing objects to code that expects that requirement (such as modern x86 numeric processing instructions).  This implies that
	- the starts of all spaces are aligned on 8-byte boundaries
	- object allocation rounds up the requested size to a multiple of 8 bytes
	- the overflow size field is also 8 bytes
We shall probably keep the minimum object size at 16 bytes so that there is always room for a forwarding pointer.  But this implies either that we round object lengths up to units of 16 bytes (current choice) or that we need to implement an 8-byte filler to fill holes between objects > 16 bytes whose length mod 16 bytes is 8 bytes and following pinned objects.  We can do this using a special class index, e.g. 1, so that the method that answers the size of an object looks like, e.g.
	chunkSizeOf: oop
		<var: #oop type: #'object *'>
		^object classIndex = 1
			ifTrue: [BaseHeaderSize]
			ifFalse: [BaseHeaderSize
				  + (object slotSize = OverflowSlotSize
						ifTrue: [OverflowSizeBytes]
						ifFalse: [0])
				  + (object slotSize * BytesPerSlot)]

	chunkStartOf: oop
		<var: #oop type: #'object *'>
		^(self cCoerceSimple: oop to: #'char *')
			- ((object classIndex = 1
			    or: [object slotSize ~= OverflowSlotSize])
					ifTrue: [0]
					ifFalse: [OverflowSizeBytes])

Note that the size field of an object (its slot size) reflects the logical size of the object e.g. 0-element array => 0 slot size, 1-element array => 1 slot size). The memory manager rounds up the slot size as appropriate, e.g. (self roundUp: (self slotSizeOf: obj) * 4 to: 8) min: 8.

Heap growth and shrinkage will be handled by allocating and deallocating heap segments from/to the OS via e.g. memory-mapping.  This technique allows space to be released back to the OS by unmapping empty segments.  See ""Segmented Old Space"" below).

The basic approach is to use a fixed size new space and a growable old space.  The new space is a classic three-space nursery a la Ungar's Generation Scavenging, a large eden for new objects and two smaller survivor spaces that exchange roles on each collection, one being the to space to which surviving objects are copied, the other being the from space of the survivors of the previous collection, i.e. the previous to space.  (This basic algorithm must be extended for weak arrays and ephemerons).

To provide apparent pinning in new space we rely on lazy become.  Since most pinned objects will be byte data and these do not require stack zone activation scanning, the overhead is simply an old space allocation and corpsing.

To provide pinning in old space, large objects are implicitly pinned (because it is expensive to move large objects and, because they are both large and relatively rare, they contribute little to overall fragmentation - as in aggregates, small objects can be used to fill-in the spaces between karge objects).  Hence, objects above a particular size are automatically allocated in old space, rather than new space.  Small objects are pinned as per objects in new space, by asserting the pin bit, which will be set automaticaly when allocating a large object.  As a last resort, or by programmer control (the fullGC primitive) old space is collected via mark-sweep (mark-compact) and so the mark phase must build the list of pinned objects around which the sweep/compact phase must carefully step.

Free space in old space is organized by a number of free lists and a free tree .  There are 32 or 64 free lists, depending on word size, indices 1 through wordSize - 1 holding blocks of space of the index * allocationUnit, index 0 holding a semi-balanced ordered tree of free blocks, each node being the head of the list of free blocks of that size.  At the start of the mark phase the free list is thrown away and the sweep phase coalesces free space and steps over pinned objects as it proceeds.  We can reuse the forwarding pointer compaction scheme used in the old collector.  Incremental collections merely move unmarked objects to the free lists (as well as nilling weak pointers in weak arrays and scheduling them for finalization).  The occupancy of the free lists is represented by a bitmap in an integer so that an allocation of size wordSize - 1 or less can know whether there exists a free chunk of that size, but more importantly can know whether a free chunk larger than it exists in the fixed size free lists without having to search all larger free list heads.

Incremental Old Space Collection
The incremental collector (a la Dijkstra's three colour algorithm) collects old space via an amount of tracing being hung off scavenges and/or old space allocations at an adaptive rate that keeps full garbage collections to a minimum.  [N.B. Not sure how to do this yet.  The incremental collector needs to complete a pass often enough to reclaim objects, but infrequent enough not to waste time.  So some form of feedback should work.  In VisualWorks tracing is broken into quanta or work where image-level code determines the size of a quantum based on how fast the machine is, and how big the heap is.  This code could easily live in the VM, controllable through vmParameterAt:put:.  An alternative would be to use the heartbeat to bound quanta by time.  But in any case some amount of incremental collection would be done on old space allocation and scavenging, the ammount being chosen to keep pause times acceptably short, and at a rate to reclaim old space before a full GC is required, i.e. at a rate proportional to the growth in old space]. The incemental collector is a state machine, being either marking, nilling weak pointers, or freeing.  If nilling weak pointers is not done atomically then there must be a read barrier in weak array at: so that reading from an old space weak array that is holding stale un-nilled references to unmarked objects.  Tricks such as including the weak bit in bounds calculations can make this cheap for non-weak arrays.  Alternatively nilling weak pointers can be made an atomic part of incremental collection, which can be made cheaper by maintaining the set of weak arrays (e.g. on a list).  Note that the incremental collector also follows (and eliminates) forwarding pointers as it scans.

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

Incremental Best-Fit Compaction
The free list also looks like it allows efficient incremental compaction.  Currently in the 32-bit implementation, but easily affordable in the 64-bit implementation, objects have at least two fields, the first one being a forwarding pointer, the second one rounding up to 8-byte object alignment.  On the free list the first field is used to link the list of free chunks of a given size.  The second field could be used to link free chunks in memory order.  And of course the last free chunk is the chunk before the last run of non-free objects.  We compact by

a) keeping each free list in memory order (including the lists of free chunks off each node in the large free chunk tree)
b) sorting the free chunks in memory order by merge sorting the free lists
c) climbing the free list in memory order.  For each free chunk in the free list search memory from the last free chunk to the end (and from the previous chunk to the next chunk, and so on) looking for a best-fit live object.  That object is then copied into the free chunk, and its corpse is turned into a forwarding pointer.  This works because the compaction does not slide objects, and hence no forwarding blocks are necessary and the algorithm can be made incremental. Various optimizations are possible, e.g. using a bitmap to record the sizes of the first few free chunks on the list when looking for best fits.  The assumptions being
a) the number fo objects on the free list is kept small because the IGC incrementally compacts, and so sorting and searching the list is not expensive
b) the incremental collector's following of forwarding pointers reclaims the corpses at the end of memory at a sufficient rate to keep the free list small
c) the rounding of objects to an 8-byte alignment improves the chances of finding a best fit.
Note that this incremental collection is easily amenable to leave pinned objects where they are; they are simply filtered out when looking for a best fit.

Segmented Old Space
A segmented oldSpace is useful.  It allows growing oldSpace incrementally, adding a segment at a time, and freeing empty segments.  But such a scheme is likely to introduces complexity in object enumeration, and compaction (enumeration would apear to require visiting each segment, compaction must be wthin a segment, etc). One idea that might fly to allow a segmented old space that appears to be a single contiguous spece is to use fake pinned objects to bridge the gaps between segments.  The last two words of each segment can be used to hold the header of a pinned object whose size is the distance to the next segment.  The pinned object's classIndex can be one of the puns so that it doesn't show up in allInstances; this can perhaps also indicate to the incremental collector that it is not to reclaim the object, etc.  However, free objects would need a large enough size field to stretch across large gaps in the address space.  The current design limits the overflow size field to a 32-bit slot count, which wouldn't be large enough in a 64-bit implementation.  The overflow size field is at most 7 bytes since the overflow size word also contains a maxed-out 8-bit slot count (for object parsing).  A byte can be stolen from e.g. the identityHash field to beef up the size to a full 64-bits.


Lazy become & the become read barrier.

As described earlier the basic idea behind lazy become is to use corpses (forwarding objects) that are followed lazily during GC and inline cache miss.  However, a lazy scheme would appear to require a read barrier to avoid accessing the coirpse and mak sure wel follow the forwarding pointer.  Without hardware support read barriers have poor performance, so we must restrict the read barrier as much as possible.  The main goal is to avoid having to scan all of the heap to fix up pointers, as is done with ObjectMemory.  We're happy to do some scanning of a small subset oif the heap, but become: cannot scale to large heaps if it must scan the entire heap.  Objects with named inst vars and CompiledMethods are accessed extensively by the interpreter and jitted code.  We must avoid as much checking of such accesses as possible; We judge an explicit read barrier on all accesses far too expensive.  The accesses the VM makes which notionally require a read barrier are:
- inst vars of thisContext, including stack contents (the receiver of a message and its arguments), which in Cog are the fields of the current stack frame, and the sender chain during (possibly non-local) return
- named inst vars of the receiver
- literals of the current method, in particular variable bindings (a.k.a. literal variables which are global associations), including the methodClass association.
- in primitives, the receiver and arguments, including possible sub-structure.
We have already discussed that we will catch an attempt to create a new activation on a forwarded object therough method lookup failing for forwarded objects.  This would occur when e.g. some object referenced by the receiver via its inst vars is pushed on the stack as a message receiver, or e.g. answered as the result of some primtiive which accesses object state such as primtive at:  So there is no need for a read barrier when accessing a new receiver or returning its state.  But there must presumably be a read barrier in primitives that inspect that sub-state.

However, we can easily avoid read barriers in direct literal access, and class hierarchy walking and message dictionary searching in message lookup.  Whenever the become operation becomes one or more pointer objects (and it can e.g. cheaply know if it has becommed a CompiledMethod) both the class table and the stack zone are scanned.  In the class table we can follow the forwarding pointers in all classes in the table, and we can follow their superclasses.  But we would like to avoid scanning classes many times.  Any superclass that has a non-zero hash must be in the table and will be encountered during the scan of the class table.  Any superclass with a zero hash can be entered into the table at a point subsequent to the current index and hence scanned.  The class scan can also scan method dictionary selectors and follow the methiod dictionary's array reference (so that dictionaries are valid for lookup) and scan the dictionary's method array iff a CompiledMethod was becommed. (Note that support for object-as-method implies an explicit read barrier in primitiveObjectAsMethod, which is a small overhead there-in).

Accessing possibly forwarded method literals is fine; these forwarding objects will be pushed on the stack and caught either by the message lookup trap or explicitly in primitives that access arguments.  However, push/store/pop literal variable cannot avoid an explicit check without requiring we scan all methods, which will be far too expensive.  To avoid a check on super send when accessing a method's method class association, we must check the method class associations of any method in the stack zone, and in the method of any context faulted into the stack zone on return.

We avoid a read barrier on access to receiver inst vars by scanning the stack zone and following pointers to the receiver.

Amd of course, all of the scavenger, the incremental scan-mark-compactor and the global garbage collector follow and eliminate forwarding pointers as part of their object graph traversals.

This means explicit read barriers in
- push/store/pop literal variable
- return (accessing the sender context, its inst vars, and the method class association of its method)
- primitives that inspect the class and/or state of their arguments, excepting immediates.  e.g. in at:put: (almost) no checks are required because the receiver will have been caught by the message send trap, the index is a SmallInteger and the argument is either an immediate Character (in String>>at:put:) or a possibly forwarded object stored into an array; i.e. the argument's state is inspected only if it is an immediate (the exception is 64-bit indexable and 32-bit indexable floats & bitmaps which could take LargeIntegers whose contents are copied into the relevant field).  But e.g. in beCursor extensive checks are required because the primitive inspects a couple of form instances, and a point that are sub-state of the Cursor object.

One approach would be an explicit call in the primitive, made convenient via providing something like ensureNoForwardingPointersIn: obj toDepth: n, which in beCursor's case would look like interpreter ensureNoForwardingPointersIn: cursorObj toDepth: 3 (the offset point of the mask form).
Another approach would be to put an explicit read barrier in store/fetchPointer:ofObject:[withValue:] et al, but provide an additional api (e.g. store/fetchPointer:ofNonForwardedObject:[withValue:] et al) and use it in the VM's internals.  The former approach is error-prone, but the latter approach is potentially ugly, touching nearly all of the core VM code.  It would appear that one of these two approaches must be chosen.

61-bit immediate Floats
Representation for immediate doubles, only used in the 64-bit implementation. Immediate doubles have the same 52 bit mantissa as IEEE double-precision  floating-point, but only have 8 bits of exponent.  So they occupy just less than the middle 1/8th of the double range.  They overlap the normal single-precision floats which also have 8 bit exponents, but exclude the single-precision denormals (exponent-127) and the single-precsion NaNs (exponent +127).  +/- zero is just a pair of values with both exponent and mantissa 0. 
So the non-zero immediate doubles range from 
        +/- 0x3800,0000,0000,0001 / 5.8774717541114d-39 
to      +/- 0x47ff,ffff,ffff,ffff / 6.8056473384188d+38 
The encoded tagged form has the sign bit moved to the least significant bit, which allows for faster encode/decode because offsetting the exponent can't overflow into the sign bit and because testing for +/- 0 is an unsigned compare for <= 0xf: 
    msb                                                                                        lsb 
    [8 exponent subset bits][52 mantissa bits ][1 sign bit][3 tag bits] 
So assuming the tag is 5, the tagged non-zero bit patterns are 
             0x0000,0000,0000,001[d/5] 
to           0xffff,ffff,ffff,fff[d/5] 
and +/- 0d is 0x0000,0000,0000,000[d/5] 
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
b) raw conversion between double and quadword must (at least in the source) move bits through memory ( quadword = *(q64 *)&doubleVariable). 


Heap Walking
In heap walking the memory manager needs to be able to detect the start of the next object.  This is complicated by the short and long header formats, short being for objects with 254 slots or less, long being for objects with 255 slots or more.  Since an object that has an overflow header must have 255 as its header slot count we can use this as the marker.  The overflow header word also has a numSlots field, set to 255.  The remainder of the overflow size field is used for the object's slot size, the least significant word in 32-bits (for 2^34 bytes, more than the address space), the remaining 56 bits in 64-bits (for 2^59 bytes, which we hope is big enough for bridge objects).  So if the word following an object contains 255 in its numSlots field, it must be the overflow size word of an object with a double header, and the word after that is the header, also with a saturated numSlots field.

Total Number of Classes and Instance-specific Behaviours
While the class index header field has advantages (saving significant header space, especially in 64-bits, providing a non-moving cache tag for inline caches, small constants for instantiating well-known classes instead of having to fetch them from a table such as the specialObjectsArray) it has the downside of limiting the number of classes.  For Smalltalk programs 2^20 to 2^24 classes is adequate for some time to come, but for prototype languages such as JavaScript this is clearly inadequate, and we woud like to support the ability to host prototype languages within Squeak. There is a solution in the form of ""auto-instances"", an idea of Claus Gittinger's.  The idea is to represent prototypes as behaviors that are instances of themselves.  In a classical Smalltalk system a Behavior is an object with the minimal amount of state to function as a class, and in Smalltalk-80 this state is the three instance variables of Behavior, superclass, methodDict and format, which are the only fields in a Behavior that are known to the virtual machine.  A prototype can therefore have its own behavior and inherit from other prototypes or classes, and have sub-prototypes derived from it if a) its first three instance variables are also superclass, methodDict, and format, and b) it is an instance of itself (one can create such objects in a normal Smalltalk system by creating an Array with the desired layout and using a change class primitive to change the class of the Array to itself).  The same effect can be achieved in a VM with class indexes by reserving one class index to indicate that the object is an instance of itself, hence not requiring the object be entered into the class table and in the code that derives the class of an object, requiring one simple test answering the object itself instead of indexing the class table.  There would probably need to be an auto-instantiation primitive that takes a behavior (or prototype) and an instance variable count and answers a new auto-instance with as many instance variables as the sum of the behavior (or prototype) and the instance variable count.  Using this scheme there can be as many auto-instances as available address space allows while retaining the benefits of class indices.

This scheme has obvious implications for the inline cache since all prototypes end up having the same inline cache tag.  Either the inline cache check checks for the auto-instance class tag and substitutes the receiver, or the cacheing machinery refuses to add the auto-instance class tag to any inline cache and failure path code checks for the special case.  Note that in V8 failing monomorphic sends are patched to open PICs (megamorphic sends); V8 does not use closed PICs due to the rationale that polymorphism is high in JavaScript.

Miscellanea
In-line cache probe for immediates
We would like to keep 31-bit SmallIntegers for the 32-bit system.  Lots of code could be impacted by a change to 30-bit SmallIntegers.  If so, then 
	isImmediate: oop	^(oop bitAnd: 3) ~= 0
	isSmallInteger: oop	^(oop bitAnd: 1) ~= 0
	isCharacter: oop	^(oop bitAnd: 2) = 2
If the in-line cache contains 0 for Characters then the in-line cache code (in x86 machine code) reads as follows, for a branch-free common-case:
	Limm:
		andl $0x1, %eax
		j Lcmp
	Lentry:
		movl %edx, %eax
		andl $0x3, %eax
		jnz Limm
		movl 0(%edx), %eax
		andl $0x3fffff, %eax
	Lcmp:
		cmpl %ecx, %eax
		jnz Lmiss

64-Bit sizes:
We extend the original Squeak 4-bit format field to 5 bits, providing space for 3 odd bits for byte objects (2 for short objects & 1 for 32-bit long objects).  Object sizes are slots, and byte (and short and 32-bit) lengths are computed by subtracting the odd bits from the shifted slot length.  Keeping the format field saves bits because it subsumes the isWeak,isEphemeron,isPointer bits that would be necessary otherwise.  The format field is organized as follows:
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

Issues:
Are class indices in inline caches strong references to classes or weak references?
If strong then they must be scanned during GC and the methodZone must be flushed on fullGC to reclaim all classes (this looks to be a bug in the V3 Cogit).
If weak then when the class table loses references, PICs containing freed classes must be freed and then sends to freed PICs or containing freed clases must be unlinked.
The second approach is faster; the common case is scanning the class table, the uncommon case is freeing classes.  The second approach is better for machine code; in-line caches do not prevent reclamation of classes.  However, the former is better for the scavengerm which as a result doesnt have to scan the classes of objects.  The sytsem scavenges much more frequently than it reclaims classes and the number of cog methods to be scanned during scavenge is small.  So I think a strong class table is better after all.
"
Class {
	#name : #SpurMemoryManager,
	#superclass : #CogClass,
	#instVars : [
		'coInterpreter',
		'scavenger',
		'segmentManager',
		'memory',
		'freeStart',
		'freeOldSpaceStart',
		'scavengeThreshold',
		'newSpaceLimit',
		'nilObj',
		'falseObj',
		'trueObj',
		'specialObjectsOop',
		'hiddenRootsObj',
		'classTableFirstPage',
		'classTableIndex',
		'numClassTablePages',
		'classTableBitmap',
		'startOfMemory',
		'endOfMemory',
		'ephemeronQueue',
		'unscannedEphemerons',
		'objStackInvalidBecause',
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
		'growHeadroom',
		'shrinkThreshold',
		'gcStartUsecs',
		'scavengeInProgress',
		'marking',
		'remapBuffer',
		'remapBufferCount',
		'extraRootCount',
		'extraRoots',
		'lowSpaceThreshold',
		'totalFreeOldSpace',
		'firstFreeChunk',
		'highestObjects',
		'statCoalesces',
		'statCompactPassCount',
		'statFGCDeltaUsecs',
		'statFullGCUsecs',
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
		'statSpecialMarkCount',
		'statSurvivorCount'
	],
	#classVars : [
		'BitsPerByte',
		'CheckObjectOverwrite',
		'EphemeronQueueRootIndex',
		'ExtraRootsSize',
		'FirstValidClassIndex',
		'MarkStackRecord',
		'MarkStackRootIndex',
		'ObjStackFixedSlots',
		'ObjStackFreex',
		'ObjStackLimit',
		'ObjStackMyx',
		'ObjStackNextx',
		'ObjStackPageSlots',
		'ObjStackTopx',
		'RemapBufferSize',
		'WeaklingStackRootIndex'
	],
	#pools : [
		'SpurMemoryManagementConstants',
		'VMBasicConstants',
		'VMObjectIndices',
		'VMSpurObjectRepresentationConstants',
		'VMSqueakClassIndices',
		'VMSqueakV3BytecodeConstants'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurMemoryManager class >> additionalHeadersDo: aBinaryBlock [
	"Evaluate aBinaryBlock with the names and contents of
	 any additional header files that need to be generated."
]

{ #category : #translation }
SpurMemoryManager class >> ancilliaryClasses: options [
	^{	SpurGenerationScavenger. SpurSegmentManager. SpurSegmentInfo },
		SpurNewSpaceSpace withAllSubclasses
]

{ #category : #accessing }
SpurMemoryManager class >> baseHeaderSize [
	"For CogBlockMethod class>>instVarNamesAndTypesForTranslationDo:"
	^8
]

{ #category : #'simulation only' }
SpurMemoryManager class >> characterObjectOf: characterCode [
	^characterCode asCharacter
]

{ #category : #accessing }
SpurMemoryManager class >> classTableBitmapBytes [
	"Max size of the classTableBitmap.  A liottle too large to contemplate allocating statically."
	^1 << (self basicNew classIndexFieldWidth - (BitsPerByte log: 2) asInteger)
]

{ #category : #translation }
SpurMemoryManager class >> declareCVarsIn: aCCodeGenerator [
	self declareCAsOop: #(	memory freeStart scavengeThreshold newSpaceLimit pastSpaceStart
							lowSpaceThreshold freeOldSpaceStart endOfMemory sortedFreeChunks)
		in: aCCodeGenerator.
	self declareCAsUSqLong: (self allInstVarNames select: [:ivn| ivn endsWith: 'Usecs'])
		in: aCCodeGenerator.
	aCCodeGenerator
		var: #freeLists type: #'sqInt *';
		var: #classTableBitmap type: #'unsigned char *';
		var: #highestObjects type: #SpurCircularBuffer;
		var: #unscannedEphemerons type: #SpurContiguousObjStack.
	aCCodeGenerator
		var: #remapBuffer
		declareC: 'sqInt remapBuffer[RemapBufferSize + 1 /* ', (RemapBufferSize + 1) printString, ' */]'.
	aCCodeGenerator
		var: #extraRoots
		declareC: 'sqInt *extraRoots[ExtraRootsSize + 1 /* ', (ExtraRootsSize + 1) printString, ' */]'.
]

{ #category : #translation }
SpurMemoryManager class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initBytesPerWord: nBytes [

	BytesPerWord := nBytes.
	ShiftForWord := (BytesPerWord log: 2) rounded.
	"The following is necessary to avoid confusing the compiler with shifts that are larger than the width of the type on which they operate.  In gcc, such shifts cause incorrect code to be generated."
	BytesPerWord = 8
		ifTrue:					"64-bit VM"
			[Byte0Mask := 16r00000000000000FF.	Byte0Shift := 0.
			 Byte1Mask := 16r000000000000FF00.	Byte1Shift := 8.
			 Byte2Mask := 16r0000000000FF0000.	Byte2Shift := 16.
			 Byte3Mask := 16r00000000FF000000.	Byte3Shift := 24.
			 Byte4Mask := 16r000000FF00000000.	Byte4Shift := 32.
			 Byte5Mask := 16r0000FF0000000000.	Byte5Shift := 40.
			 Byte6Mask := 16r00FF000000000000.	Byte6Shift := 48.
			 Byte7Mask := 16rFF00000000000000.	Byte7Shift := 56.
			 Bytes3to0Mask := 16r00000000FFFFFFFF.
			 Bytes7to4Mask := 16rFFFFFFFF00000000]
		ifFalse:					"32-bit VM"
			[Byte0Mask := 16r00000000000000FF.	Byte0Shift := 0.
			 Byte1Mask := 16r000000000000FF00.	Byte1Shift := 8.
			 Byte2Mask := 16r0000000000FF0000.	Byte2Shift := 16.
			 Byte3Mask := 16r00000000FF000000.	Byte3Shift := 24.
			 Byte4Mask := nil.							Byte4Shift := 0.	"unused"
			 Byte5Mask := nil.							Byte5Shift := 0.	"unused"
			 Byte6Mask := nil.							Byte6Shift := 0.	"unused"
			 Byte7Mask := nil.							Byte7Shift := 0.	"unused"
			 Bytes3to0Mask := nil.											"unused"
			 Bytes7to4Mask := nil											"unused"].
	Byte1ShiftNegated := Byte1Shift negated.
	Byte3ShiftNegated := Byte3Shift negated.
	Byte4ShiftNegated := Byte4Shift negated.
	Byte5ShiftNegated := Byte5Shift negated.
	Byte7ShiftNegated := Byte7Shift negated.
	"N.B.  This is *not* output when generating the interpreter file.
	 It is left to the various sqConfig.h files to define correctly."
	VMBIGENDIAN := Smalltalk endianness == #big
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initialize [
	"SpurMemoryManager initialize"
	BitsPerByte := 8.

	"An obj stack is a stack of objects stored in a hidden root slot, such as
	 the markStack or the ephemeronQueue.  It is a linked list of segments,
	 with the hot end at the head of the list.  It is a word object.  The stack
	 pointer is in ObjStackTopx and 0 means empty.  The list goes through
	 ObjStackNextx. We don't want to shrink objStacks, since they're used
	 in GC and its good to keep their memory around.  So unused pages
	 created by popping emptying pages are kept on the ObjStackFreex list.
	 ObjStackNextx must be the last field for swizzleObjStackAt:."
	ObjStackPageSlots := 4092. "+ double header = 16k bytes per page in 32-bits"
	ObjStackTopx := 0.
	ObjStackMyx := 1.
	ObjStackFreex := 2.
	ObjStackNextx := 3.
	ObjStackFixedSlots := 4.
	ObjStackLimit := ObjStackPageSlots - ObjStackFixedSlots.
	"There are currently three obj stacks, the mark stack, the weaklings and the ephemeron queue."
	MarkStackRootIndex := self basicNew classTableRootSlots.
	WeaklingStackRootIndex := MarkStackRootIndex + 1.
	EphemeronQueueRootIndex := MarkStackRootIndex + 2.

	CheckObjectOverwrite := true.

	"The remap buffer support is for compatibility; Spur doesn't GC during allocation.
	 Eventually this should die."
	RemapBufferSize := 25.

	"Extra roots are for plugin support."
	ExtraRootsSize := 2048 "max. # of external roots"
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

	ClassByteArrayCompactIndex := 50.
	ClassArrayCompactIndex := 51.
	ClassByteStringCompactIndex := 52.
	ClassBitmapCompactIndex := 53
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initializeObjectHeaderConstants [

	BytesPerWord ifNil: [BytesPerWord := 4].  "May get called on fileIn, so supply default"
	BaseHeaderSize := 8 "Alas so much of the VM uses BaseheaderSize explicitly we don't (yet) make it a message."
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initializeSpecialObjectIndices [
	"Initialize indices into specialObjects array."

	NilObject := 0.
	FalseObject := 1.
	TrueObject := 2.
	SchedulerAssociation := 3.
	ClassBitmap := 4.
	ClassInteger := 5.
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
	SelectorCounterTripped := 58
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initializeSpurObjectRepresentationConstants [
	"SpurMemoryManager initializeSpurObjectRepresentationConstants"
	BecamePointerObjectFlag := 1.
	BecameCompiledMethodFlag := 2.
	"BecameClassFlag := 4" "this turns out not to be actionable"

]

{ #category : #'class initialization' }
SpurMemoryManager class >> initializeWithOptions: optionsDictionary [
	"SpurMemoryManager initializeWithOptions: Dictionary new"

	super initializeWithOptions: optionsDictionary.
	self initialize.
	self initBytesPerWord: (self == SpurMemoryManager
								ifTrue: [optionsDictionary at: #BytesPerWord ifAbsent: [4]]
								ifFalse: [self wordSize]).
	BytesPerOop := optionsDictionary at: #BytesPerOop ifAbsent: [BytesPerWord].

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
	^#('self' 'coInterpreter' 'manager' 'scavenger' 'segmentManager' 'heapMap') includes: aString
]

{ #category : #translation }
SpurMemoryManager class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^'checkForLeaks' = var
]

{ #category : #accessing }
SpurMemoryManager class >> objectRepresentationClass [
	^self subclassResponsibility
]

{ #category : #translation }
SpurMemoryManager class >> prepareToBeAddedToCodeGenerator: aCodeGen [
	"Remove the superclass methods we override."
	self selectors do:
		[:sel|
		 (superclass whichClassIncludesSelector: sel) ifNotNil:
			[aCodeGen removeMethodForSelector: sel]]
]

{ #category : #'simulation only' }
SpurMemoryManager class >> vmProxyMajorVersion [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^StackInterpreter vmProxyMajorVersion
]

{ #category : #'simulation only' }
SpurMemoryManager class >> vmProxyMinorVersion [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^StackInterpreter vmProxyMinorVersion max: 13
]

{ #category : #'word size' }
SpurMemoryManager class >> wordSize [
	^self subclassResponsibility
]

{ #category : #'object enumeration' }
SpurMemoryManager >> accessibleObjectAfter: objOop [
	"Answer the accessible object following the given object or 
	free chunk in the heap. Return nil when heap is exhausted.
	 This is for primitiveNextObject subsequent to primtiiveSomeObject."
	<inline: false>
	| objAfter |
	objAfter := objOop.
	[objAfter := self objectAfter: objAfter limit: freeOldSpaceStart.
	 objAfter = freeOldSpaceStart ifTrue:
		[^nil].
	 (self isNormalObject: objAfter) ifTrue:
		[^objAfter]] repeat
]

{ #category : #'free space' }
SpurMemoryManager >> addFreeChunkWithBytes: bytes at: address [
	self freeChunkWithBytes: bytes at: address.
	totalFreeOldSpace := totalFreeOldSpace + bytes
]

{ #category : #'free space' }
SpurMemoryManager >> addFreeSubTree: freeTree [
	"Add a freeChunk sub tree back into the large free chunk tree.
	 This is for allocateOldSpaceChunkOf[Exactly]Bytes:."
	| slotsInArg treeNode slotsInNode subNode |
	slotsInArg := self numSlotsOfAny: freeTree.
	self assert: slotsInArg / (self allocationUnit / self wordSize) >= self numFreeLists.
	treeNode := freeLists at: 0.
	self assert: treeNode ~= 0.
	[slotsInNode := self numSlotsOfAny: treeNode.
	 self assert: slotsInArg ~= slotsInNode.
	 slotsInNode > slotsInArg
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
	index := chunkBytes / self allocationUnit.
	index < self numFreeLists ifTrue:
		[self storePointer: self freeChunkNextIndex ofFreeChunk: freeChunk withValue: (freeLists at: index).
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
	self assert: chunkBytes = (self bytesInObject: freeChunk).
	self assert: chunkBytes / self allocationUnit >= self numFreeLists.

	self
		storePointer: self freeChunkNextIndex ofFreeChunk: freeChunk withValue: 0;
		storePointer: self freeChunkParentIndex ofFreeChunk: freeChunk withValue: 0;
		storePointer: self freeChunkSmallerIndex ofFreeChunk: freeChunk withValue: 0;
		storePointer: self freeChunkLargerIndex ofFreeChunk: freeChunk withValue: 0.
	"Large chunk list organized as a tree, each node of which is a list of chunks of the same size.
	 Beneath the node are smaller and larger blocks."
	parent := 0.
	child := freeLists at: 0.
	[child ~= 0] whileTrue:
		[childBytes := self bytesInObject: child.
		 childBytes = chunkBytes ifTrue: "size match; add to list at node."
			[self storePointer: self freeChunkNextIndex
					ofFreeChunk: freeChunk
						withValue: (self fetchPointer: self freeChunkNextIndex ofObject: child);
				storePointer: self freeChunkNextIndex
					ofFreeChunk: child
						withValue: freeChunk.
			 ^child].
		 "walk down the tree"
		 parent := child.
		 child := self fetchPointer: (childBytes > chunkBytes
										ifTrue: [self freeChunkSmallerIndex]
										ifFalse: [self freeChunkLargerIndex])
					ofObject: child].
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
		or: [(self isInSurvivorSpace: address)
		or: [scavengeInProgress and: [self isInFutureSpace: address]]]]]
]

{ #category : #'debug support' }
SpurMemoryManager >> addressCouldBeObjWhileScavenging: address [
	^(address bitAnd: self baseHeaderSize - 1) = 0
	  and: [(self isInOldSpace: address)
		or: [(self isInEden: address)
		or: [(self isInSurvivorSpace: address)
		or: [scavengeInProgress and: [self isInFutureSpace: address]]]]]
]

{ #category : #'debug support' }
SpurMemoryManager >> addressCouldBeOop: address [ 
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

	| obj |
	self countNumClassPagesPreSwizzle: bytesToShift;
		ensureAdequateClassTableBitmap.
	(bytesToShift ~= 0
	 or: [segmentManager numSegments > 1])
		ifTrue:
			[self assert: self newSpaceIsEmpty.
			 obj := self objectStartingAt: newSpaceLimit.
			 [self oop: obj isLessThan: freeOldSpaceStart] whileTrue:
				[(self isFreeObject: obj)
					ifTrue: [self swizzleFieldsOfFreeChunk: obj]
					ifFalse:
						[self inClassTableBitmapSet: (self classIndexOf: obj).
						 self swizzleFieldsOfObject: obj].
				 obj := self objectAfter: obj]]
		ifFalse:
			[self assert: self newSpaceIsEmpty.
			 obj := self objectStartingAt: newSpaceLimit.
			 [self oop: obj isLessThan: freeOldSpaceStart] whileTrue:
				[(self isFreeObject: obj) ifFalse:
					[self inClassTableBitmapSet: (self classIndexOf: obj)].
				 obj := self objectAfter: obj]]
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
	[objOop < limit] whileTrue:
		[(self isFreeObject: objOop) ifFalse:
			[aBlock value: objOop].
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: freeStart].
	objOop := self objectStartingAt: scavenger pastSpace start.
	limit := pastSpaceStart.
	[objOop < limit] whileTrue:
		[(self isFreeObject: objOop) ifFalse:
			[aBlock value: objOop].
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
	oldSpaceLimit := freeOldSpaceStart.
	[self assert: objOop \\ self allocationUnit = 0.
	 objOop < oldSpaceLimit] whileTrue:
		[(self isFreeObject: objOop) ifFalse:
			[aBlock value: objOop].
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: freeOldSpaceStart].
	self touch: prevPrevObj.
	self touch: prevObj
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
	<inline: true>
	self allNewSpaceEntitiesDo: aBlock.
	self allOldSpaceEntitiesDo: aBlock
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allNewSpaceEntitiesDo: aBlock [
	"Enumerate all new space objects, including free objects,
	 excluding any objects created during the ennumeration."
	<inline: true>
	| prevObj prevPrevObj objOop limit |
	prevPrevObj := prevObj := nil.
	"After a scavenge eden is empty, futureSpace is empty, and all newSpace objects are
	  in pastSpace.  Objects are allocated in eden.  So enumerate only eden and pastSpace."
	objOop := self objectStartingAt: scavenger eden start.
	[objOop < freeStart] whileTrue:
		[aBlock value: objOop.
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: freeStart].
	objOop := self objectStartingAt: scavenger pastSpace start.
	limit := pastSpaceStart.
	[objOop < limit] whileTrue:
		[aBlock value: objOop.
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: limit].
	self touch: prevPrevObj.
	self touch: prevObj
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allNewSpaceObjectsDo: aBlock [
	"Enumerate all new space objects, excluding any objects created
	 during the execution of allNewSpaceObjectsDo:."
	<inline: true>
	| prevObj prevPrevObj objOop limit |
	prevPrevObj := prevObj := nil.
	"After a scavenge eden is empty, futureSpace is empty, and all newSpace objects are
	  in pastSpace.  Objects are allocated in eden.  So enumerate only eden and pastSpace."
	objOop := self objectStartingAt: scavenger eden start.
	[objOop < freeStart] whileTrue:
		[(self isFreeObject: objOop) ifFalse:
			[aBlock value: objOop].
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: freeStart].
	objOop := self objectStartingAt: scavenger pastSpace start.
	limit := pastSpaceStart.
	[objOop < limit] whileTrue:
		[(self isFreeObject: objOop) ifFalse:
			[aBlock value: objOop].
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: limit].
	self touch: prevPrevObj.
	self touch: prevObj
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allObjectsDo: aBlock [
	<inline: true>
	self allNewSpaceObjectsDo: aBlock.
	self allOldSpaceObjectsDo: aBlock
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

{ #category : #'object enumeration' }
SpurMemoryManager >> allOldSpaceEntitiesDo: aBlock [
	<inline: true>
	| prevObj prevPrevObj objOop |
	prevPrevObj := prevObj := nil.
	objOop := self firstObject.
	[self assert: objOop \\ self allocationUnit = 0.
	 objOop < freeOldSpaceStart] whileTrue:
		[aBlock value: objOop.
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: freeOldSpaceStart].
	self touch: prevPrevObj.
	self touch: prevObj
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allOldSpaceEntitiesForCoalescingDo: aBlock [
	<inline: true>
	| prevObj prevPrevObj objOop rawNumSlots rawNumSlotsAfter |
	prevPrevObj := prevObj := nil.
	objOop := self firstObject.
	[self assert: objOop \\ self allocationUnit = 0.
	 objOop < freeOldSpaceStart] whileTrue:
		[rawNumSlots := self rawNumSlotsOf: objOop.
		 aBlock value: objOop.
		 "If the number of slot changes coalescing changed an object from a single to a double header."
		 rawNumSlotsAfter := self rawNumSlotsOf: objOop.
		 (rawNumSlotsAfter ~= rawNumSlots
		  and: [rawNumSlotsAfter = self numSlotsMask]) ifTrue:
			[objOop := objOop + self baseHeaderSize.
			 self assert: (self objectAfter: prevObj limit: freeOldSpaceStart) = objOop].
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: freeOldSpaceStart].
	self touch: prevPrevObj.
	self touch: prevObj
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allOldSpaceEntitiesFrom: initialObject do: aBlock [
	<inline: true>
	| prevObj prevPrevObj objOop |
	prevPrevObj := prevObj := nil.
	objOop := initialObject.
	[self assert: objOop \\ self allocationUnit = 0.
	 objOop < freeOldSpaceStart] whileTrue:
		[aBlock value: objOop.
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: freeOldSpaceStart].
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
	<inline: true>
	| prevObj prevPrevObj objOop |
	prevPrevObj := prevObj := nil.
	objOop := initialObject.
	[self assert: objOop \\ self allocationUnit = 0.
	 objOop < freeOldSpaceStart] whileTrue:
		[(self isFreeObject: objOop) ifFalse:
			[aBlock value: objOop].
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop limit: freeOldSpaceStart].
	self touch: prevPrevObj.
	self touch: prevObj
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> allUnscannedEphemeronsAreActive [
	unscannedEphemerons start to: unscannedEphemerons top - self wordSize do:
		[:p| | key |
		key := self keyOfEphemeron: (self longAt: p).
		((self isImmediate: key) or: [self isMarked: key]) ifTrue:
			[^false]].
	^true
]

{ #category : #allocation }
SpurMemoryManager >> allocateBytes: numBytes classIndex: classIndex [
	"Allocate an object of numBytes.  Answer nil if no available memory.
	 classIndex must be that of a byte class (e.g. ByteString).
	 The object is *NOT FILLED*."
	self assert: (coInterpreter addressCouldBeClassObj: (self classAtIndex: classIndex)).
	self assert: (self instSpecOfClass: (self classAtIndex: classIndex)) = self firstByteFormat.
	^self
		allocateSlots: (numBytes + self wordSize - 1 // self wordSize)
		format: self firstByteFormat + (self wordSize - numBytes bitAnd: self wordSize - 1)
		classIndex: classIndex
]

{ #category : #'spur bootstrap' }
SpurMemoryManager >> allocateMemoryOfSize: memoryBytes newSpaceSize: newSpaceBytes stackSize: stackBytes codeSize: codeBytes [
	"Intialize the receiver for bootsraping an image.
	 Set up a large oldSpace and an empty newSpace and set-up freeStart and scavengeThreshold
	 to allocate in oldSpace.  Later on (in initializePostBootstrap) freeStart and scavengeThreshold
	 will be set to sane values."
	<doNotGenerate>
	| endBridgeBytes |
	self assert: (memoryBytes \\ self allocationUnit = 0
				and: [newSpaceBytes \\ self allocationUnit = 0
				and: [codeBytes \\ self allocationUnit = 0]]).
	endBridgeBytes := 2 * self baseHeaderSize.
	memory := (self endianness == #little
					ifTrue: [LittleEndianBitmap]
					ifFalse: [Bitmap]) new: (memoryBytes + newSpaceBytes + codeBytes + stackBytes + endBridgeBytes) // 4.
	startOfMemory := codeBytes + stackBytes.
	endOfMemory := freeOldSpaceStart := memoryBytes + newSpaceBytes + codeBytes + stackBytes.
	"leave newSpace empty for the bootstrap"
	freeStart := newSpaceBytes + startOfMemory.
	newSpaceLimit := newSpaceBytes + startOfMemory.
	scavengeThreshold := memory size * 4. "Bitmap is a 4-byte per word array"
	scavenger := SpurGenerationScavengerSimulator new
					manager: self
					newSpaceStart: startOfMemory
					newSpaceBytes: newSpaceBytes
					edenBytes: newSpaceBytes * self scavengerDenominator - self numSurvivorSpaces // self scavengerDenominator
]

{ #category : #allocation }
SpurMemoryManager >> allocateNewSpaceSlots: numSlots format: formatField classIndex: classIndex [
	self subclassResponsibility
]

{ #category : #'free space' }
SpurMemoryManager >> allocateOldSpaceChunkOfBytes: chunkBytes [
	"Answer a chunk of oldSpace from the free lists, if available,
	 otherwise answer nil.  Break up a larger chunk if one of the
	 exact size does not exist.  N.B.  the chunk is simply a pointer, it
	 has no valid header.  The caller *must* fill in the header correctly."
	| initialIndex chunk index nodeBytes parent child |
	"for debugging:" "totalFreeOldSpace := self totalFreeListBytes"
	totalFreeOldSpace := totalFreeOldSpace - chunkBytes. "be optimistic (& don't wait for the write)"
	initialIndex := chunkBytes / self allocationUnit.
	(initialIndex < self numFreeLists and: [1 << initialIndex <= freeListsMask]) ifTrue:
		[(freeListsMask anyMask: 1 << initialIndex) ifTrue:
			[(chunk := freeLists at: initialIndex) ~= 0 ifTrue:
				[self assert: chunk = (self startOfObject: chunk).
				 self assert: (self isValidFreeObject: chunk).
				^self unlinkFreeChunk: chunk atIndex: initialIndex].
			 freeListsMask := freeListsMask - (1 << initialIndex)].
		 "first search for free chunks of a multiple of chunkBytes in size"
		 index := initialIndex.
		 [(index := index + index) < self numFreeLists
		  and: [1 << index <= freeListsMask]] whileTrue:
			[(freeListsMask anyMask: 1 << index) ifTrue:
				[(chunk := freeLists at: index) ~= 0 ifTrue:
					[self assert: chunk = (self startOfObject: chunk).
					 self assert: (self isValidFreeObject: chunk).
					 self unlinkFreeChunk: chunk atIndex: index.
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
					 self assert: (self isValidFreeObject: chunk).
					 self unlinkFreeChunk: chunk atIndex: index.
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
		 self assert: (self isValidFreeObject: child).
		 childBytes := self bytesInObject: child.
		 childBytes = chunkBytes
			ifTrue: "size match; try to remove from list at node."
				[chunk := self fetchPointer: self freeChunkNextIndex
								ofFreeChunk: child.
				 chunk ~= 0 ifTrue:
					[self assert: (self isValidFreeObject: chunk).
					 self storePointer: self freeChunkNextIndex
						ofFreeChunk: child
						withValue: (self fetchPointer: self freeChunkNextIndex
										ofFreeChunk: chunk).
					 ^self startOfObject: chunk].
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
		 self storePointer: self freeChunkNextIndex
			ofFreeChunk: parent
			withValue: (self fetchPointer: self freeChunkNextIndex
							ofFreeChunk: chunk).
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
	| initialIndex node next prev index child acceptedChunk acceptedNode |
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
						 self assert: (self isValidFreeObject: node).
						 next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: node.
						 (acceptanceBlock value: node) ifTrue:
							[prev = 0
								ifTrue: [freeLists at: initialIndex put: next]
								ifFalse: [self storePointer: self freeChunkNextIndex ofFreeChunk: prev withValue: next].
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
							 self assert: (self isValidFreeObject: node).
							 next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: node.
							 (acceptanceBlock value: node) ifTrue:
								[prev = 0
									ifTrue: [freeLists at: index put: next]
									ifFalse: [self storePointer: self freeChunkNextIndex ofFreeChunk: prev withValue: next]. 
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
							 self assert: (self isValidFreeObject: node).
							 next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: node.
							 (acceptanceBlock value: node) ifTrue:
								[prev = 0
									ifTrue: [freeLists at: index put: next]
									ifFalse: [self storePointer: self freeChunkNextIndex ofFreeChunk: prev withValue: next]. 
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
	acceptedChunk := acceptedNode := 0.
	[child ~= 0] whileTrue:
		[| childBytes |
		 self assert: (self isValidFreeObject: child).
		 childBytes := self bytesInObject: child.
		 childBytes = chunkBytes ifTrue: "size match; try to remove from list at node."
			[node := child.
			 [prev := node.
			  node := self fetchPointer: self freeChunkNextIndex ofFreeChunk: node.
			  node ~= 0] whileTrue:
				[(acceptanceBlock value: node) ifTrue:
					[self assert: (self isValidFreeObject: node).
					 self storePointer: self freeChunkNextIndex
						ofFreeChunk: prev
						withValue: (self fetchPointer: self freeChunkNextIndex ofFreeChunk: node).
					 ^self startOfObject: node]].
			 (acceptanceBlock value: node) ifTrue:
				[node := child.
				 child := 0]]. "break out of loop to remove interior node"
		 child ~= 0 ifTrue:
			["Note that because the minimum free size is 16 bytes (2 * allocationUnit), to
			  leave room for the forwarding pointer/next free link, we can only break chunks
			  that are at least 16 bytes larger, hence reject chunks < 2 * allocationUnit larger."
			childBytes <= (chunkBytes + self allocationUnit)
				ifTrue: "node too small; walk down the larger size of the tree"
					[child := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: child]
				ifFalse:
					[acceptedNode = 0 ifTrue:
						[acceptedChunk := child.
						 "first search the list."
						 [acceptedChunk := self fetchPointer: self freeChunkNextIndex
													ofFreeChunk: acceptedChunk.
						  (acceptedChunk ~= 0 and: [acceptanceBlock value: acceptedChunk]) ifTrue:
							[acceptedNode := child].
						  acceptedChunk ~= 0 and: [acceptedNode = 0]] whileTrue.
						 "nothing on the list; will the node do?  This prefers
						  acceptable nodes higher up the tree over acceptable
						  list elements further down, but we haven't got all day..."
						 (acceptedNode = 0
						  and: [acceptanceBlock value: child]) ifTrue:
							[acceptedNode := child]].
					 child := self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: child]]].
	acceptedNode ~= 0 ifTrue:
		[acceptedChunk ~= 0 ifTrue:
			[self assert: (self bytesInObject: acceptedChunk) >= (chunkBytes + self allocationUnit).
			 [next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: acceptedNode.
			  next ~= acceptedChunk] whileTrue:
				[acceptedNode := next].
			 self storePointer: self freeChunkNextIndex
				ofFreeChunk: acceptedNode
				withValue: (self fetchPointer: self freeChunkNextIndex ofFreeChunk: acceptedChunk).
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

{ #category : #'free space' }
SpurMemoryManager >> allocateOldSpaceChunkOfExactlyBytes: chunkBytes [
	"Answer a chunk of oldSpace from the free lists, if one of this size
	 is available, otherwise answer nil.  N.B.  the chunk is simply a pointer,
	 it has no valid header.  The caller *must* fill in the header correctly."
	| index node nodeBytes child |
	"for debugging:" "totalFreeOldSpace := self totalFreeListBytes"

	index := chunkBytes / self allocationUnit.
	index < self numFreeLists ifTrue:
		[(freeListsMask anyMask: 1 << index) ifTrue:
			[(node := freeLists at: index) ~= 0 ifTrue:
				[self assert: node = (self startOfObject: node).
				 self assert: (self isValidFreeObject: node).
				 totalFreeOldSpace := totalFreeOldSpace - chunkBytes.
				 ^self unlinkFreeChunk: node atIndex: index].
			 freeListsMask := freeListsMask - (1 << index)].
		 ^nil].

	"Large chunk.  Search the large chunk list.
	 Large chunk list organized as a tree, each node of which is a list of
	 chunks of the same size. Beneath the node are smaller and larger
	 blocks.  When the search ends parent should hold the first chunk of
	 the same size as chunkBytes, or 0 if none."
	node := 0.
	child := freeLists at: 0.
	[child ~= 0] whileTrue:
		[| childBytes |
		 self assert: (self isValidFreeObject: child).
		 childBytes := self bytesInObject: child.
		 childBytes = chunkBytes
			ifTrue: "size match; try to remove from list at node."
				[node := self fetchPointer: self freeChunkNextIndex
								ofFreeChunk: child.
				 node ~= 0 ifTrue:
					[self assert: (self isValidFreeObject: node).
					 self storePointer: self freeChunkNextIndex
						ofFreeChunk: child
						withValue: (self fetchPointer: self freeChunkNextIndex
										ofFreeChunk: node).
					 totalFreeOldSpace := totalFreeOldSpace - chunkBytes.
					 ^self startOfObject: node].
				 node := child.
				 nodeBytes := childBytes.
				 child := 0] "break out of loop to remove interior node"
			ifFalse:
				[childBytes < chunkBytes
					ifTrue: "walk down the tree"
						[child := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: child]
					ifFalse:
						[nodeBytes := childBytes.
						 child := self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: child]]].
	"if no chunk, there was no exact fit"
	node = 0 ifTrue:
		[^nil].

	"self printFreeChunk: parent"
	self assert: nodeBytes = chunkBytes.
	self assert: (self bytesInObject: node) = chunkBytes.

	"can't be a list; would have removed and returned it above."
	self assert: (self fetchPointer: self freeChunkNextIndex ofFreeChunk: node) = 0.

	"no list; remove the interior node"
	self unlinkSolitaryFreeTreeNode: node.
	totalFreeOldSpace := totalFreeOldSpace - chunkBytes.
	^self startOfObject: node
]

{ #category : #'free space' }
SpurMemoryManager >> allocateOldSpaceChunkOfExactlyBytes: chunkBytes suchThat: acceptanceBlock [
	"Answer a chunk of oldSpace from the free lists that satisfies acceptanceBlock,
	 if one of this size is available, otherwise answer nil.  N.B.  the chunk is simply a
	 pointer, it has no valid header.  The caller *must* fill in the header correctly."
	| index node next prev child childBytes |
	<inline: true> "must inline for acceptanceBlock"
	"for debugging:" "totalFreeOldSpace := self totalFreeListBytes"

	index := chunkBytes / self allocationUnit.
	index < self numFreeLists ifTrue:
		[(freeListsMask anyMask: 1 << index) ifTrue:
			[(node := freeLists at: index) = 0
				ifTrue: [freeListsMask := freeListsMask - (1 << index)]
				ifFalse:
					[prev := 0.
					 [node ~= 0] whileTrue:
						[self assert: node = (self startOfObject: node).
						 self assert: (self isValidFreeObject: node).
						 next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: node.
						 (acceptanceBlock value: node) ifTrue:
							[prev = 0
								ifTrue: [freeLists at: index put: next]
								ifFalse: [self storePointer: self freeChunkNextIndex ofFreeChunk: prev withValue: next].
							 totalFreeOldSpace := totalFreeOldSpace - chunkBytes.
							 ^node].
						 node := next]]].
		 ^nil].

	"Large chunk.  Search the large chunk list.
	 Large chunk list organized as a tree, each node of which is a list of
	 chunks of the same size. Beneath the node are smaller and larger
	 blocks.  When the search ends parent should hold the first chunk of
	 the same size as chunkBytes, or 0 if none."
	node := 0.
	child := freeLists at: 0.
	[child ~= 0] whileTrue:
		[self assert: (self isValidFreeObject: child).
		 childBytes := self bytesInObject: child.
		 childBytes = chunkBytes
			ifTrue: "size match; try to remove from list at node first."
				[node := child.
				 [prev := node.
				  node := self fetchPointer: self freeChunkNextIndex ofFreeChunk: node.
				  node ~= 0] whileTrue:
					[(acceptanceBlock value: node) ifTrue:
						[self assert: (self isValidFreeObject: node).
						 self storePointer: self freeChunkNextIndex
							ofFreeChunk: prev
							withValue: (self fetchPointer: self freeChunkNextIndex ofFreeChunk: node).
						 totalFreeOldSpace := totalFreeOldSpace - chunkBytes.
						 ^self startOfObject: node]].
				 node := child.
				 child := 0] "break out of loop to remove interior node"
			ifFalse: "no size match; walk down the tree"
				[child := self fetchPointer: (childBytes < chunkBytes
												ifTrue: [self freeChunkLargerIndex]
												ifFalse: [self freeChunkSmallerIndex])
							ofFreeChunk: child]].
	"if no chunk, there was no exact fit"
	(node ~= 0 and: [acceptanceBlock value: node]) ifFalse:
		[^nil].

	"self printFreeChunk: parent"
	self assert: (self bytesInObject: node) = chunkBytes.

	next := self fetchPointer: self freeChunkNextIndex ofFreeChunk: node.
	next = 0
		ifTrue: "no list; remove the interior node"
			[self unlinkSolitaryFreeTreeNode: node]
		ifFalse: "list; replace node with it"
			[self inFreeTreeReplace: node with: next].
	totalFreeOldSpace := totalFreeOldSpace - chunkBytes.
	^self startOfObject: node
]

{ #category : #allocation }
SpurMemoryManager >> allocateSlots: numSlots format: formatField classIndex: classIndex [
	self subclassResponsibility
]

{ #category : #allocation }
SpurMemoryManager >> allocateSlotsInOldSpace: numSlots bytes: totalBytes format: formatField classIndex: classIndex [
	"Answer the oop of a chunk of space in oldSpace with numSlots slots.  The header
	 will have been filled-in but not the contents."
	^self subclassResponsibility
]

{ #category : #allocation }
SpurMemoryManager >> allocateSlotsInOldSpace: numSlots format: formatField classIndex: classIndex [
	<inline: true>
	^self
		allocateSlotsInOldSpace: numSlots
		bytes: (self objectBytesForSlots: numSlots)
		format: formatField
		classIndex: classIndex
]

{ #category : #allocation }
SpurMemoryManager >> allocationUnit [
	"All objects are a multiple of 8 bytes in length"
	^8
]

{ #category : #'class table puns' }
SpurMemoryManager >> arrayClassIndexPun [
	"Class puns are class indices not used by any class.  There is an entry
	 for the pun that refers to the notional class of objects with this class
	 index.  But because the index doesn't match the class it won't show up
	 in allInstances, hence hiding the object with a pun as its class index.
	 The puns occupy indices 16 through 31."
	^16
]

{ #category : #'header formats' }
SpurMemoryManager >> arrayFormat [
	<api>
	^2
]

{ #category : #'growing/shrinking memory' }
SpurMemoryManager >> assimilateNewSegment: segInfo [
	"Update after adding a segment.
	 Here we set freeOldSpaceStart & endOfMemory if required."
	<var: #segInfo type: #'SpurSegmentInfo *'>
	segInfo segStart >= endOfMemory ifTrue:
		[freeOldSpaceStart :=
		 endOfMemory := segInfo segStart + segInfo segSize - self bridgeSize]
]

{ #category : #snapshot }
SpurMemoryManager >> baseAddressOfImage [
	^newSpaceLimit
]

{ #category : #'header access' }
SpurMemoryManager >> baseHeader: obj [
	^self longLongAt: obj
]

{ #category : #'header format' }
SpurMemoryManager >> baseHeaderSize [
	"Object headers are 8 bytes in length if the slot size fits in the slot size field (max implies overflow),
	 16 bytes otherwise (slot size in preceeding word)."
	^8
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
	| ec |
	self assert: becomeEffectsFlags = 0.
	self leakCheckBecome ifTrue:
		[self runLeakCheckerForFullGC: true].
	(self isArray: array1) ifFalse:
		[^PrimErrBadReceiver].
	((self isArray: array2)
	 and: [(self numSlotsOf: array1) = (self numSlotsOf: array2)]) ifFalse:
		[^PrimErrBadArgument].
	(twoWayFlag or: [copyHashFlag])
		ifTrue:
			[ec := self containsOnlyValidBecomeObjects: array1 and: array2]
		ifFalse:
			[self followForwardedObjectFields: array2 toDepth: 0.
			ec := self containsOnlyValidBecomeObjects: array1].
	ec ~= 0 ifTrue: [^ec].

	coInterpreter preBecomeAction.
	twoWayFlag
		ifTrue:
			[self innerBecomeObjectsIn: array1 and: array2 copyHash: copyHashFlag]
		ifFalse:
			[self innerBecomeObjectsIn: array1 to: array2 copyHash: copyHashFlag].
	self postBecomeScanClassTable.
	coInterpreter postBecomeAction: becomeEffectsFlags.
	becomeEffectsFlags := 0.

	self leakCheckBecome ifTrue:
		[self runLeakCheckerForFullGC: true].

	^PrimNoErr "success"
]

{ #category : #'become implementation' }
SpurMemoryManager >> becomeEffectFlagsFor: objOop [
	"Answer the appropriate become effect flags for objOop, or 0 if none.
	 The effect flags affect how much work is done after the become in
	 following forwarding pointers."
	<inline: false>
	^(self isPointersNonImm: objOop)
		ifTrue:
			[BecamePointerObjectFlag
			"older code that identified class objects, but it isn't helpful:"
			"| hash |
			 (hash := self rawHashBitsOf: objOop) = 0
				ifTrue: ""Can't identify an abstract class by the class table; it may not be there-in.""
					[(coInterpreter objCouldBeClassObj: objOop)
						ifTrue: [BecamePointerObjectFlag + BecameClassFlag]
						ifFalse: [BecamePointerObjectFlag]]
				ifFalse: ""if an object has a hash and it's a class it must be in the table.""
					[(self classAtIndex: hash) = objOop
						ifTrue: [BecamePointerObjectFlag + BecameClassFlag]
						ifFalse: [BecamePointerObjectFlag]]"]
		ifFalse:
			[(self isCompiledMethod: objOop)
				ifTrue: [BecameCompiledMethodFlag]
				ifFalse: [0]]
]

{ #category : #compaction }
SpurMemoryManager >> bestFitCompact [
	"Compact all of memory using best-fit, assuming free space is sorted
	 and that the highest objects are recorded in highestObjects."

	<inline: false>
	| freePriorToExactFit |
	self checkFreeSpace.
	freePriorToExactFit := totalFreeOldSpace.
	self exactFitCompact.
	self checkFreeSpace.
	highestObjects isEmpty ifTrue:
		[^self]. "either no high objects, or no misfits."
	statCompactPassCount := statCompactPassCount + 1.
	highestObjects reverseDo:
		[:o| | b |
		 self assert: ((self isForwarded: o) or: [self isPinned: o]) not.
		 b := self bytesInObject: o.
		 (self allocateOldSpaceChunkOfBytes: b suchThat: [:f| f < o]) ifNotNil:
			[:f| self copyAndForward: o withBytes: b toFreeChunk: f]].
	self checkFreeSpace.
	self flag: 'this should perhaps be a loop, recharging highestObjects as per exactFitCompact, but for now we assume the number of misfits not in highestObjects is very small'.
	self allOldSpaceObjectsFrom: firstFreeChunk
		do: [:o| | b |
			((self isForwarded: o)
			 or: [self isPinned: o]) ifFalse:
				[b := self bytesInObject: o.
				 (self allocateOldSpaceChunkOfBytes: b suchThat: [:f| f < o]) ifNotNil:
					[:f| self copyAndForward: o withBytes: b toFreeChunk: f]]].
	self checkFreeSpace.
	self touch: freePriorToExactFit
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

{ #category : #segments }
SpurMemoryManager >> bridgeSize [
	^2 * self baseHeaderSize
]

{ #category : #'header format' }
SpurMemoryManager >> byteFormatForNumBytes: numBytes [
	^self firstByteFormat + (numBytes bitAnd: self wordSize - 1)
]

{ #category : #'header format' }
SpurMemoryManager >> byteFormatMask [
	^16r18
]

{ #category : #'object access' }
SpurMemoryManager >> byteLengthOf: objOop [ 
	"Answer the number of indexable bytes in the given object.
	 Does not adjust contexts by stackPointer."
	| fmt numBytes |
	<inline: true>
	<asmLabel: false>
	fmt := self formatOf: objOop.
	numBytes := (self numSlotsOf: objOop) << self shiftForWord.
	fmt <= self sixtyFourBitIndexableFormat ifTrue:
		[^numBytes].
	fmt >= self firstByteFormat ifTrue: "bytes, including CompiledMethod"
		[^numBytes - (fmt bitAnd: 7)].
	fmt >= self firstShortFormat ifTrue:
		[^numBytes - ((fmt bitAnd: 3) << 1)].
	"fmt >= self firstLongFormat"
	^numBytes - ((fmt bitAnd: 1) << 2)
]

{ #category : #'object access' }
SpurMemoryManager >> byteSizeOf: oop [
	<api>
	| format |
	(self isImmediate: oop) ifTrue: [^0].
	format := self formatOf: oop.
	format < self sixtyFourBitIndexableFormat ifTrue:
		[^(self numSlotsOf: oop) << self shiftForWord].
	format >= self firstByteFormat ifTrue:
		[^(self numSlotsOf: oop) << self shiftForWord - (format bitAnd: 7)].
	format >= self firstShortFormat ifTrue:
		[^(self numSlotsOf: oop) << self shiftForWord - ((format bitAnd: 3) << 1)].
	format >= self firstLongFormat ifTrue:
		[^(self numSlotsOf: oop) << self shiftForWord - ((format bitAnd: 1) << 2)].
	^(self numSlotsOf: oop) << self shiftForWord
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
	 physical memory. For a report on the largest free block currently availabe within
	 Squeak memory but not counting extra memory use #primBytesLeft."
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

{ #category : #'header format' }
SpurMemoryManager >> bytesPerSlot [
	^self subclassResponsibility
]

{ #category : #'memory access' }
SpurMemoryManager >> cCoerce: value to: cTypeString [
	"Type coercion. For translation a cast will be emmitted. When running in Smalltalk
	  answer a suitable wrapper for correct indexing."

	^value
		ifNil: [value]
		ifNotNil: [value coerceTo: cTypeString sim: self]
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
	  and: [(self oop: address isGreaterThanOrEqualTo: startOfMemory)
	  and: [self oop: address isLessThan: freeOldSpaceStart]]
]

{ #category : #initialization }
SpurMemoryManager >> checkCompactIndex: classIndex isClass: specialIndex named: name [
	"Check that a class the VM assumes is compact has the right index."
	<inline: true> "macrofication of the name arg in invalidCompactClassError only works if this method is inlined so the name is a string literal not a parameter"
	(classIndex ~= 0
	 and: [(self splObj: specialIndex) ~= (self knownClassAtIndex: classIndex)]) ifTrue:
		[self invalidCompactClassError: name]
]

{ #category : #allocation }
SpurMemoryManager >> checkForLastObjectOverwrite [
	<doNotGenerate>
	self assert: (freeStart >= scavengeThreshold
				or: [CheckObjectOverwrite not
		  		or: [(self longAt: freeStart) = freeStart]])
]

{ #category : #'debug support' }
SpurMemoryManager >> checkFreeSpace [
	self assert: self bitsSetInFreeSpaceMaskForAllFreeLists.
	self assert: totalFreeOldSpace = self totalFreeListBytes
]

{ #category : #'debug support' }
SpurMemoryManager >> checkHeapIntegrity [
	"Perform an integrity/leak check using the heapMap.  Assume
	 clearLeakMapAndMapAccessibleObjects has set a bit at each
	 object's header.  Scan all objects in the heap checking that every
	 pointer points to a header.  Scan the rootTable, remapBuffer and
	 extraRootTable checking that every entry is a pointer to a header.
	 Check that the number of roots is correct and that all rootTable
	 entries have their rootBit set. Answer if all checks pass."
	| prevObj prevPrevObj ok numRememberedRootsInHeap |
	<inline: false>
	ok := true.
	numRememberedRootsInHeap := 0.
	self allHeapEntitiesDo:
		[:obj| | containsYoung fieldOop classIndex classOop |
		(self isFreeObject: obj) ifFalse:
			[containsYoung := false.
			 (self isRemembered: obj) ifTrue:
				[numRememberedRootsInHeap := numRememberedRootsInHeap + 1.
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
					 (self isYoung: fieldOop) ifTrue:
						[containsYoung := true]]
				ifFalse:
					[classOop := self classAtIndex: (classIndex := self classIndexOf: obj).
					 ((classOop isNil or: [classOop = nilObj])
					  and: [(self isHiddenObj: obj) not]) ifTrue:
						[coInterpreter print: 'object leak in '; printHex: obj; print: ' invalid class index '; printHex: classIndex; print: ' -> '; print: (classOop ifNil: ['nil'] ifNotNil: ['nilObj']); cr.
						 self eek.
						 ok := false].
					 self baseHeaderSize to: (self lastPointerOf: obj) by: BytesPerOop do:
						[:ptr|
						 fieldOop := self longAt: obj + ptr.
						 (self isNonImmediate: fieldOop) ifTrue:
							[| fi |
							 fi := ptr - self baseHeaderSize / self wordSize.
							 (fieldOop bitAnd: self wordSize - 1) ~= 0
								ifTrue:
									[coInterpreter print: 'misaligned oop in '; printHex: obj; print: ' @ '; printNum: fi; print: ' = '; printHex: fieldOop; cr.
									 self eek.
									 ok := false]
								ifFalse:
									[(heapMap heapMapAtWord: (self pointerForOop: fieldOop)) = 0 ifTrue:
										[coInterpreter print: 'object leak in '; printHex: obj; print: ' @ '; printNum: fi; print: ' = '; printHex: fieldOop; cr.
										 self eek.
										 ok := false].
									 "don't be misled by CogMethods; they appear to be young, but they're not"
									 ((self isYoung: fieldOop) and: [fieldOop >= startOfMemory]) ifTrue:
										[containsYoung := true]]]]].
					(containsYoung and: [(self isYoung: obj) not]) ifTrue:
						[(self isRemembered: obj) ifFalse:
							[coInterpreter print: 'unremembered object '; printHex: obj; print: ' contains young oop(s)'; cr.
							 self eek.
							 ok := false]]].
		prevPrevObj := prevObj.
		prevObj := obj].
	numRememberedRootsInHeap ~= scavenger rememberedSetSize ifTrue:
		[coInterpreter
			print: 'root count mismatch. #heap roots ';
			printNum: numRememberedRootsInHeap;
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
SpurMemoryManager >> checkOkayOop: oop [
	"Verify that the given oop is legitimate. Check address, header, and size but not class.
	 Answer true if OK.  Otherwise print reason and answer false."
	<api>
	<var: #oop type: #usqInt>
	| classIndex fmt unusedBits unusedBitsInYoungObjects |
	<var: #unusedBits type: #usqLong>

	"address and size checks"
	(self isImmediate: oop) ifTrue: [^true].
	(self addressCouldBeObjWhileScavenging: oop) ifFalse:
		[self print: 'oop '; printHex: oop; print: ' is not a valid address'. ^false].

	(self addressAfter: oop) <= freeOldSpaceStart ifFalse:
		[self print: 'oop '; printHex: oop; print: ' size would make it extend beyond the end of memory'. ^false].

	"header type checks"
	(classIndex := self classIndexOf: oop) >= self firstClassIndexPun ifFalse:
		[self print: 'oop '; printHex: oop; print: ' is a free chunk, or bridge, not an object'. ^false].
	((self rawNumSlotsOf: oop) = self numSlotsMask
	 and: [(self rawNumSlotsOf: oop) - self baseHeaderSize ~= self numSlotsMask]) ifTrue:
		[self print: 'oop '; printHex: oop; print: ' header has overflow header word, but overflow word does not have a saturated numSlots field'. ^false].

	"format check"
	fmt := self formatOf: oop.
	(fmt = 6) | (fmt = 8) ifTrue:
		[self print: 'oop '; printHex: oop; print: ' has an unknown format type'. ^false].
	(fmt = self forwardedFormat) ~= (classIndex = self isForwardedObjectClassIndexPun) ifTrue:
		[self print: 'oop '; printHex: oop; print: ' has mismached format/classIndex fields; only one of them is the isForwarded value'. ^false].

	"specific header bit checks"
	unusedBits := (1 << self classIndexFieldWidth)
				   | (1 << (self identityHashFieldWidth + 32)).
	((self longLongAt: oop) bitAnd: unusedBits) ~= 0 ifTrue:
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
	(byteAddress asUnsignedInteger < self startOfMemory
	 or: [byteAddress asUnsignedInteger > endOfMemory
	 or: [byteAddress asUnsignedInteger > newSpaceLimit
		and: [(segmentManager isInSegments: byteAddress asUnsignedInteger) not]]]) ifTrue:
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
	"a.k.a. self fetchPointer: ClassArrayCompactIndex ofObject: classTableFirstPage"
	^self splObj: ClassArray
]

{ #category : #'class table' }
SpurMemoryManager >> classAtIndex: classIndex [
	| classTablePage |
	self assert: (classIndex <= self tagMask or: [classIndex >= self arrayClassIndexPun]).
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
	self assert: (objOop = nilObj or: [(self rawHashBitsOf: objOop) = classIndex]).
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

{ #category : #'cog jit support' }
SpurMemoryManager >> classFloatCompactIndex [
	<api>
	^ClassFloatCompactIndex
]

{ #category : #'interpreter access' }
SpurMemoryManager >> classForClassTag: classIndex [
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

{ #category : #'header format' }
SpurMemoryManager >> classIndexFieldWidth [
	"22-bit class mask => ~ 4M classes"
	^22
]

{ #category : #'header format' }
SpurMemoryManager >> classIndexMask [
	"22-bit class mask => ~ 4M classes"
	^16r3fffff
]

{ #category : #'header access' }
SpurMemoryManager >> classIndexOf: objOop [
	^(self longAt: objOop) bitAnd: self classIndexMask
]

{ #category : #'header access' }
SpurMemoryManager >> classIndexOfHeader: aHeader [
	<inline: true>
	^aHeader bitAnd: self classIndexMask
]

{ #category : #'class table puns' }
SpurMemoryManager >> classIsItselfClassIndexPun [
	^4
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
	^self splObj: ClassInteger
]

{ #category : #accessing }
SpurMemoryManager >> classString [
	^self splObj: ClassByteString
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
	"1024 entries per page (2^10); 22 bit classIndex implies 2^12 pages"
	^10
]

{ #category : #'class table' }
SpurMemoryManager >> classTableMinorIndexMask [
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
	^1 << self classTableMajorIndexShift
]

{ #category : #accessing }
SpurMemoryManager >> classTableRootObj [
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
	self assert: (coInterpreter addressCouldBeClassObj: classObj).
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
SpurMemoryManager >> clearLeakMapAndMapAccessibleObjects [
	"Perform an integrity/leak check using the heapMap.  Set a bit at each object's header."
	<inline: false>
	heapMap clearHeapMap.
	self allObjectsDo:
		[:oop| heapMap heapMapAtWord: (self pointerForOop: oop) Put: 1]
]

{ #category : #allocation }
SpurMemoryManager >> clone: objOop [
	| numSlots newObj |
	numSlots := self numSlotsOf: objOop.
	
	numSlots > self maxSlotsForNewSpaceAlloc
		ifTrue:
			[newObj := self allocateSlotsInOldSpace: numSlots
							format: (self formatOf: objOop)
							classIndex: (self classIndexOf: objOop)]
		ifFalse:
			[newObj := self allocateSlots: numSlots
							format: (self formatOf: objOop)
							classIndex: (self classIndexOf: objOop)].
	(self isPointersNonImm: objOop)
		ifTrue:
			[0 to: numSlots - 1 do:
				[:i| | oop |
				oop := self fetchPointer: i ofObject: objOop.
				((self isNonImmediate: oop)
				 and: [self isForwarded: oop]) ifTrue:
					[oop := self followForwarded: oop].
				self storePointerUnchecked: i
					ofObject: newObj
					withValue: oop].
			((self isRemembered: objOop)
			 and: [(self isYoung: newObj) not]) ifTrue:
				[scavenger remember: newObj.
				 self setIsRememberedOf: newObj to: true]]
		ifFalse:
			[0 to: numSlots - 1 do:
				[:i|
				self storePointerUnchecked: i
					ofObject: newObj
					withValue: (self fetchPointer: i ofObject: objOop)]].
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
		[scavenger coInterpreter: aCoInterpreter]
]

{ #category : #'gc - global' }
SpurMemoryManager >> coalesce: obj1 and: obj2 [
	self subclassResponsibility
]

{ #category : #'object access' }
SpurMemoryManager >> compactClassIndexOf: objOop [
	^self classIndexOf: objOop
]

{ #category : #'class membership' }
SpurMemoryManager >> compactIndexOfClass: objOop [
	self assert: (self rawHashBitsOf: objOop) ~= 0.
	^self rawHashBitsOf: objOop
]

{ #category : #'become implementation' }
SpurMemoryManager >> containsOnlyValidBecomeObjects: array [
	"Answer 0 if the array contains only unpinned non-immediates.
	 Otherwise answer an informative error code.
	 Can't become: immediates!  Shouldn't become pinned objects."
	| fieldOffset effectsFlags oop |
	fieldOffset := self lastPointerOf: array.
	effectsFlags := 0.
	"same size as array2"
	[fieldOffset >= self baseHeaderSize] whileTrue:
		[oop := self longAt: array + fieldOffset.
		 (self isImmediate: oop) ifTrue: [^PrimErrInappropriate].
		 (self isForwarded: oop) ifTrue:
			[oop := self followForwarded: oop.
			 self longAt: array + fieldOffset put: oop].
		 (self isPinned: oop) ifTrue: [^PrimErrObjectIsPinned].
		 effectsFlags := effectsFlags bitOr: (self becomeEffectFlagsFor: oop).
		 fieldOffset := fieldOffset - BytesPerOop].
	"only set flags after checking all args."
	becomeEffectsFlags := effectsFlags.
	^0
]

{ #category : #'become implementation' }
SpurMemoryManager >> containsOnlyValidBecomeObjects: array1 and: array2 [
	"Answer 0 if neither array contains only unpinned non-immediates.
	 Otherwise answer an informative error code.
	 Can't become: immediates!  Shouldn't become pinned objects."
	| fieldOffset effectsFlags oop |
	fieldOffset := self lastPointerOf: array1.
	effectsFlags := 0.
	"same size as array2"
	[fieldOffset >= self baseHeaderSize] whileTrue:
		[oop := self longAt: array1 + fieldOffset.
		 (self isImmediate: oop) ifTrue: [^PrimErrInappropriate].
		 (self isForwarded: oop) ifTrue:
			[oop := self followForwarded: oop.
			 self longAt: array1 + fieldOffset put: oop].
		 (self isPinned: oop) ifTrue: [^PrimErrObjectIsPinned].
		 effectsFlags := effectsFlags bitOr: (self becomeEffectFlagsFor: oop).
		 oop := self longAt: array2 + fieldOffset.
		 (self isImmediate: oop) ifTrue: [^PrimErrInappropriate].
		 (self isForwarded: oop) ifTrue:
			[oop := self followForwarded: oop.
			 self longAt: array2 + fieldOffset put: oop].
		 (self isPinned: oop) ifTrue: [^PrimErrObjectIsPinned].
		 effectsFlags := effectsFlags bitOr: (self becomeEffectFlagsFor: oop).
		 fieldOffset := fieldOffset - BytesPerOop].
	"only set flags after checking all args."
	becomeEffectsFlags := effectsFlags.
	^0
]

{ #category : #compaction }
SpurMemoryManager >> copyAndForward: objOop withBytes: bytes toFreeChunk: freeChunk [
	"Copy and forward objOop to freeChunk, the inner operation in
	 exact and best fit compact."

	<inline: true>
	| startOfObj freeObj |
	startOfObj := self startOfObject: objOop.
	self mem: freeChunk asVoidPointer cp: startOfObj asVoidPointer y: bytes.
	freeObj := freeChunk + (objOop - startOfObj).
	"leave it to followRememberedForwarders to remember..."
	"(self isRemembered: objOop) ifTrue:
		[scavenger remember: freeObj]."
	self forward: objOop to: freeObj
]

{ #category : #'class table' }
SpurMemoryManager >> countNumClassPagesPreSwizzle: bytesToShift [
	"Compute the used size of the class table before swizzling.  Needed to
	 initialize the classTableBitmap which is populated during adjustAllOopsBy:"
	| firstObj classTableRoot nilObjPreSwizzle |
	firstObj := self objectStartingAt: newSpaceLimit. "a.k.a. nilObj"
	"first five objects are nilObj, falseObj, trueObj, freeListsObj, classTableRootObj"
	classTableRoot := self objectAfter:
							(self objectAfter:
									(self objectAfter:
											(self objectAfter: firstObj
												limit: freeOldSpaceStart)
										limit: freeOldSpaceStart)
								limit: freeOldSpaceStart)
							limit: freeOldSpaceStart.
	nilObjPreSwizzle := newSpaceLimit - bytesToShift.
	numClassTablePages := self numSlotsOf: classTableRoot.
	self assert: numClassTablePages = (self classTableRootSlots + self hiddenRootSlots).
	2 to: numClassTablePages - 1 do:
		[:i|
		(self fetchPointer: i ofObject: classTableRoot) = nilObjPreSwizzle ifTrue:
			[numClassTablePages := i.
			 ^self]]
	
]

{ #category : #snapshot }
SpurMemoryManager >> defaultEdenBytes [
	^2 * 1024 * 1024
	+ (coInterpreter interpreterAllocationReserveBytes
	    * self scavengerDenominator + self numSurvivorSpaces // self scavengerDenominator)
]

{ #category : #'free space' }
SpurMemoryManager >> detachLargeFreeObject: freeChunk [
	| prev next |
	prev := self fetchPointer: self freeChunkPrevIndex ofObject: freeChunk.
	next := self fetchPointer: self freeChunkNextIndex ofObject: freeChunk.
	prev = 0
		ifTrue: "freeChunk is a treeNode"
			[next = 0
				ifTrue: "remove it from the tree"
					[self unlinkSolitaryFreeTreeNode: freeChunk]
				ifFalse: "replace freeChunk by its next node."
					[self unlinkFreeTreeNode: freeChunk withSiblings: next]]
		ifFalse: "freeChunk is a list node; simple"
			[self storePointer: self freeChunkNextIndex ofFreeChunk: prev withValue: next.
			 next ~= 0 ifTrue:
				[self storePointer: self freeChunkPrevIndex ofFreeChunk: next withValue: prev]]
]

{ #category : #accessing }
SpurMemoryManager >> displayObject [
	^self splObj: TheDisplay
]

{ #category : #'become implementation' }
SpurMemoryManager >> doBecome: obj1 and: obj2 copyHash: copyHashFlag [
	"Inner dispatch for two-way become"
	| o1ClassIndex o2ClassIndex |
	copyHashFlag ifFalse:
		["in-lined
			clasIndex := (self isInClassTable: obj) ifTrue: [self rawHashBitsOf: obj] ifFalse: [0]
		 for speed."
		 o1ClassIndex := self rawHashBitsOf: obj1.
		 (o1ClassIndex ~= 0 and: [(self classAtIndex: o1ClassIndex) ~= obj1]) ifTrue:
			[o1ClassIndex := 0].
		 o2ClassIndex := self rawHashBitsOf: obj2.
		 (o2ClassIndex ~= 0 and: [(self classAtIndex: o2ClassIndex) ~= obj2]) ifTrue:
			[o2ClassIndex := 0]].
	(self numSlotsOf: obj1) = (self numSlotsOf: obj2)
		ifTrue:
			[self inPlaceBecome: obj1 and: obj2 copyHashFlag: copyHashFlag]
		ifFalse:
			[self outOfPlaceBecome: obj1 and: obj2 copyHashFlag: copyHashFlag].
	"if copyHashFlag then nothing changes, since hashes were also swapped."
	copyHashFlag ifTrue:
		[^self].
	"if copyHash is false then the classTable entries must be updated."
	o1ClassIndex ~= 0
		ifTrue:
			[o2ClassIndex ~= 0
				ifTrue: "both were in the table; just swap entries"
					[| tmp |
					 tmp := self classAtIndex: o1ClassIndex.
					 self classAtIndex: o1ClassIndex put: obj2.
					 self classAtIndex: o2ClassIndex put: tmp]
				ifFalse: "o2 wasn't in the table; put it there"
					[| newObj2 |
					 newObj2 := self followForwarded: obj2.
					 self assert: (self rawHashBitsOf: newObj2) = 0.
					 self setHashBitsOf: newObj2 to: o1ClassIndex.
					 self classAtIndex: o1ClassIndex put: newObj2]]
		ifFalse:
			[o2ClassIndex ~= 0 ifTrue:
				[| newObj1 |
				 newObj1 := self followForwarded: obj1.
				 self assert: (self rawHashBitsOf: newObj1) = 0.
				 self setHashBitsOf: newObj1 to: o2ClassIndex.
				 self classAtIndex: o2ClassIndex put: newObj1]]
]

{ #category : #'become implementation' }
SpurMemoryManager >> doBecome: obj1 to: obj2 copyHash: copyHashFlag [
	| hashBits |
	self forward: obj1 to: obj2.
	copyHashFlag ifTrue:
		[hashBits := self rawHashBitsOf: obj2.
		 "silently refuse to change the hash of classes; this shouldn't happen anyway."
		 (self classAtIndex: hashBits) ~= obj2 ifTrue:
			[hashBits := self rawHashBitsOf: obj1.
			 self setHashBitsOf: obj2 to: hashBits]]
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> doScavenge: tenuringCriterion [
	"The inner shell for scavenge, abstrascted out so globalGarbageCollect can use it."

	scavengeInProgress := true.
	pastSpaceStart := scavenger scavenge: tenuringCriterion.
	self assert: (self
					oop: pastSpaceStart
					isGreaterThanOrEqualTo: scavenger pastSpace start
					andLessThanOrEqualTo: scavenger pastSpace limit).
	freeStart := scavenger eden start.
	self initSpaceForAllocationCheck: (self addressOf: scavenger eden).
	scavengeInProgress := false
]

{ #category : #accessing }
SpurMemoryManager >> edenBytes [
	<doNotGenerate>
	^scavenger edenBytes
]

{ #category : #snapshot }
SpurMemoryManager >> edenBytes: bytes [
	newSpaceLimit := bytes
]

{ #category : #instantiation }
SpurMemoryManager >> eeInstantiateClassIndex: knownClassIndex format: objFormat numSlots: numSlots [
	"Instantiate an instance of a compact class.  ee stands for execution engine and
	 implies that this allocation will *NOT* cause a GC.  N.B. the instantiated object
	 IS NOT FILLED and must be completed before returning it to Smalltalk. Since this
	 call is used in routines that do just that we are safe.  Break this rule and die in GC.
	 Result is guaranteed to be young."
	<inline: true>
	self assert: (numSlots >= 0 and: [knownClassIndex ~= 0]).
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
	 Result is guaranteed to be young."
	| classIndex |
	<inline: true>
	classIndex := self ensureBehaviorHash: classObj.
	^self
		eeInstantiateClassIndex: classIndex
		format: (self instSpecOfClass: classObj)
		numSlots: numSlots
]

{ #category : #'debug support' }
SpurMemoryManager >> eek [
	<inline: true>
]

{ #category : #'gc - global' }
SpurMemoryManager >> eliminateAndFreeForwarders [
	"As the final phase of global garbage collect, sweep
	 the heap to follow forwarders, then free forwarders"
	| lowestForwarded firstForwarded lastForwarded |
	self assert: (self isForwarded: nilObj) not.
	self assert: (self isForwarded: falseObj) not.
	self assert: (self isForwarded: trueObj) not.
	self assert: (self isForwarded: hiddenRootsObj) not.
	(self isForwarded: specialObjectsOop) ifTrue:
		[specialObjectsOop := self followForwarded: specialObjectsOop].
	scavenger followRememberedForwardersAndForgetFreeObjects.
	self doScavenge: TenureByAge.
	lowestForwarded := 0.
	"sweep, following forwarders in all live objects, and finding the first forwarder."
	self allOldSpaceObjectsDo:
		[:o|
		(self isForwarded: o)
			ifTrue:
				[lowestForwarded = 0 ifTrue:
					[lowestForwarded := o]]
			ifFalse:
				[0 to: (self numPointerSlotsOf: o) - 1 do:
					[:i| | f |
					f := self fetchPointer: i ofObject: o.
					(self isOopForwarded: f) ifTrue:
						[f := self followForwarded: f.
						 self assert: ((self isImmediate: f) or: [self isYoung: f]) not.
						 self storePointerUnchecked: i ofObject: o withValue: f]]]].
	firstForwarded := lastForwarded := 0.
	"sweep from lowest forwarder, coalescing runs of forwarders."
	self allOldSpaceObjectsFrom: lowestForwarded do:
		[:o|
		(self isForwarded: o)
			ifTrue:
				[firstForwarded = 0 ifTrue:
					[firstForwarded := o].
				 lastForwarded := o]
			ifFalse:
				[firstForwarded ~= 0 ifTrue:
					[| start bytes |
					 start := self startOfObject: firstForwarded.
					 bytes := (self addressAfter: lastForwarded) - start.
					 self addFreeChunkWithBytes: bytes at: start].
				 firstForwarded := 0]].
	firstForwarded ~= 0 ifTrue:
		[| start bytes |
		 start := self startOfObject: firstForwarded.
		 bytes := (self addressAfter: lastForwarded) - start.
		 self addFreeChunkWithBytes: bytes at: start].
]

{ #category : #'obj stacks' }
SpurMemoryManager >> emptyObjStack: objStack [
	"Remove all the entries on the stack.  Do so by setting Topx to 0
	 on the first page, and adding all subsequent pages to the free list."
	| nextPage nextNextPage |
	self assert: (self isValidObjStack: objStack).
	self storePointer: ObjStackTopx ofObject: objStack withValue: 0.
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
	self assert: (self isValidObjStack: objStack)
]

{ #category : #accessing }
SpurMemoryManager >> endOfMemory [
	^endOfMemory
]

{ #category : #'class table' }
SpurMemoryManager >> ensureAdequateClassTableBitmap [
	"The classTableBitmap is used to reclaim unused and/or duplicate entries
	 in the classTable.  As such it is notionally 2^(22 - 3) bytes big, or 512k,
	 a little too large to be comfortable allocating statically (especially on small
	 machines).  So make it big enough for the max classTableIndex's base 2 ceiling."
	<inline: false>
	| requiredSize |
	requiredSize := (1 << numClassTablePages highBit)
					* (self classTablePageSize / BitsPerByte).
	self cCode:
			[classTableBitmap ifNotNil:
				[self free: classTableBitmap].
			 classTableBitmap := self malloc: requiredSize.
			 classTableBitmap ifNil:
				[self error: 'could not allocate classTableBitmap'].
			 self me: classTableBitmap ms: 0 et: requiredSize]
		inSmalltalk:
			[classTableBitmap := CArrayAccessor on: (ByteArray new: requiredSize)]
]

{ #category : #'gc - incremental' }
SpurMemoryManager >> ensureAllMarkBitsAreZero [
	"If the incremental collector is running mark bits may be set; stop it and clear them if necessary."
	self flag: 'need to implement the inc GC first...'
]

{ #category : #'class table' }
SpurMemoryManager >> ensureBehaviorHash: aBehavior [
	| newHash err |
	<inline: true>
	self assert: (coInterpreter addressCouldBeClassObj: aBehavior).
	(newHash := self rawHashBitsOf: aBehavior) = 0 ifTrue:
		[(err := self enterIntoClassTable: aBehavior) ~= 0 ifTrue:
			[^err negated].
		 newHash := self rawHashBitsOf: aBehavior.
		 self assert: (self classAtIndex: newHash) = aBehavior].
	^newHash
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
				[self storePointer: ObjStackFreex ofObjStack: stackOrNil withValue: 0]
			ifFalse:
				[freeOrNewPage := self allocateSlotsInOldSpace: ObjStackPageSlots
										format: self wordIndexableFormat
										classIndex: self wordSizeClassIndexPun.
				 freeOrNewPage ifNil: [self error: 'no memory to allocate or extend obj stack'].
				 self storePointer: ObjStackFreex ofObjStack: freeOrNewPage withValue: 0].
		marking ifTrue: [self setIsMarkedOf: freeOrNewPage to: true].
		self storePointer: ObjStackMyx ofObjStack: freeOrNewPage withValue: objStackRootIndex;
			storePointer: ObjStackNextx ofObjStack: freeOrNewPage withValue: (stackOrNil = nilObj ifTrue: [0] ifFalse: [stackOrNil]);
			storePointer: ObjStackTopx ofObjStack: freeOrNewPage withValue: 0;
			storePointer: objStackRootIndex ofObject: hiddenRootsObj withValue: freeOrNewPage.
		self assert: (self isValidObjStackAt: objStackRootIndex).
		"Added a new page; now update and answer the relevant cached first page."
		^self updateRootOfObjStack: objStackRootIndex with: freeOrNewPage].
	self assert: (self isValidObjStackAt: objStackRootIndex).
	^stackOrNil
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
			 self storePointer: i
				ofObject: page
				withValue: aBehavior.
			 self setHashBitsOf: aBehavior to: classTableIndex.
			 self assert: (self classAtIndex: (self rawHashBitsOf: aBehavior)) = aBehavior.
			 "now fault-in method lookup chain."
			 self scanClassPostBecome: aBehavior
				effects: BecamePointerObjectFlag+BecameCompiledMethodFlag.
			 self ensureAdequateClassTableBitmap.
			 ^0]].
	 majorIndex := (majorIndex + 1 bitAnd: self classIndexMask) max: 1.
	 majorIndex = initialMajorIndex ifTrue: "wrapped; table full"
		[^PrimErrLimitExceeded]] repeat
]

{ #category : #'header formats' }
SpurMemoryManager >> ephemeronFormat [
	^5
]

{ #category : #'gc - global' }
SpurMemoryManager >> ephemeronQueue [
	^self fetchPointer: EphemeronQueueRootIndex ofObject: hiddenRootsObj
]

{ #category : #'gc - global' }
SpurMemoryManager >> ephemeronQueue: anObject [
	self storePointer: EphemeronQueueRootIndex ofObject: hiddenRootsObj withValue: anObject
]

{ #category : #compaction }
SpurMemoryManager >> exactFitCompact [
	"Compact all of memory above firstFreeChunk using exact-fit, assuming free
	 space is sorted and that the highest objects are recorded in highestObjects.
	 Note that we don't actually move; we merely copy and forward.  Eliminating
	 forwarders will be done in a final pass.
	 Leave the objects that don't fit exactly, and hence aren't moved, in highestObjects."

	<inline: false>
	| misfits first |
	<var: #misfits type: #usqInt>
	totalFreeOldSpace = 0 ifTrue: [^self].
	misfits := highestObjects last + self wordSize.
	[statCompactPassCount := statCompactPassCount + 1.
	 highestObjects from: misfits - self wordSize reverseDo:
		[:o| | b |
		o < firstFreeChunk ifTrue:
			[misfits = (highestObjects last + self wordSize)
				ifTrue: [highestObjects resetAsEmpty]
				ifFalse: [highestObjects first: misfits].
			 ^self].
		 ((self isForwarded: o) or: [self isPinned: o]) ifFalse:
			[b := self bytesInObject: o.
			 (self allocateOldSpaceChunkOfExactlyBytes: b suchThat: [:f| f < o])
				ifNil:
					[misfits := misfits - self wordSize.
					 misfits < highestObjects start ifTrue:
						[misfits := highestObjects limit].
					 self longAt: misfits put: o]
				ifNotNil:
					[:f| self copyAndForward: o withBytes: b toFreeChunk: f]]].
	 "now highestObjects contains only misfits, if any, from misfits to last.
	  set first to first failure and refill buffer. next cycle will add more misfits.
	  give up on exact-fit when half of the highest objects fail to fit."
	 first := self longAt: highestObjects first.
	 first > firstFreeChunk ifTrue:
		[| highestObjBytes failureBytes savedLimit |
		 highestObjBytes := highestObjects limit - highestObjects start.
		 failureBytes := highestObjects last >= misfits
							ifTrue: [highestObjects last - misfits]
							ifFalse: [highestObjBytes - (misfits - highestObjects last)].
		 failureBytes >= (highestObjBytes // 2) ifTrue:
			[highestObjects first: misfits.
			 ^self].
		 savedLimit := self moveMisfitsToTopOfHighestObjects: misfits.
		 self fillHighestObjectsWithMovableObjectsFrom: firstFreeChunk upTo: first.
		 misfits := self moveMisfitsInHighestObjectsBack: savedLimit]] repeat
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
SpurMemoryManager >> expungeDuplicateClasses [
	"Bits have been set in the classTableBitmap corresponding to
	 used classes.  Any class in the class table that does not have a
	 bit set has no instances with that class index.  However, becomeForward:
	 can create duplicate entries, and these duplicate entries
		a) won't have a bit set on load (because there are no forwarders on load),
		b) wont match their identityHash.
	 So expunge duplicates by eliminating unmarked entries that don't occur at
	 their identityHash."
	1 to: numClassTablePages - 1 do:
		[:i| | classTablePage |
		"optimize scan by only scanning bitmap in regions that have pages."
		classTablePage := self fetchPointer: i ofObject: hiddenRootsObj.
		classTablePage ~= nilObj ifTrue:
			[i << self classTableMajorIndexShift
				to: i << self classTableMajorIndexShift + self classTableMinorIndexMask
				by: 8
				do: [:majorBitIndex| | byteIndex byte classIndex classOrNil |
					"optimize scan by scanning a byte of indices (8 indices) at a time"
					byteIndex := majorBitIndex / BitsPerByte.
					byte := classTableBitmap at: byteIndex.
					byte ~= 255 ifTrue:
						[0 to: 7 do:
							[:minorBitIndex|
							(byte noMask: 1 << minorBitIndex) ifTrue:
								[classIndex := majorBitIndex + minorBitIndex.
								 classOrNil := self fetchPointer: (classIndex bitAnd: self classTableMinorIndexMask)
												   ofObject: classTablePage.
								 self assert: (self classAtIndex: classIndex) = classOrNil.
								 "only remove a class if it is at a duplicate entry"
								 (classOrNil ~= nilObj
								  and: [(self rawHashBitsOf: classOrNil) ~= classIndex]) ifTrue:
									[self storePointerUnchecked: (classIndex bitAnd: self classTableMinorIndexMask)
										ofObject: classTablePage
										withValue: nilObj.
									 "but it should still be in the table at its correct index."
									 self assert: ((self classAtIndex: (self rawHashBitsOf: classOrNil)) = classOrNil)]]]]]]]
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
		[classTableIndex := classIndex]
]

{ #category : #'simulation only' }
SpurMemoryManager >> failed [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter failed
]

{ #category : #accessing }
SpurMemoryManager >> falseObject [
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
	(tagBits := oop bitAnd: self tagMask) ~= 0 ifTrue:
		[^self fetchPointer: tagBits ofObject: classTableFirstPage].
	^self fetchClassOfNonImm: oop
]

{ #category : #'object access' }
SpurMemoryManager >> fetchClassOfNonImm: objOop [
	| classIndex |
	classIndex := self classIndexOf: objOop.
	classIndex = self classIsItselfClassIndexPun ifTrue:
		[^objOop].
	self assert: classIndex >= self arrayClassIndexPun.
	^self classAtIndex: classIndex
]

{ #category : #'interpreter access' }
SpurMemoryManager >> fetchClassTagOf: oop [
	| tagBits |
	(tagBits := oop bitAnd: self tagMask) ~= 0 ifTrue:
		[^(tagBits bitAnd: 1) ~= 0 ifTrue: [1] ifFalse: [tagBits]].
	^self classIndexOf: oop
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
SpurMemoryManager >> fetchLong32: fieldIndex ofObject: oop [
	"index by 32-bit units, and return a 32-bit value. Intended to replace fetchWord:ofObject:"

	^self long32At: oop + self baseHeaderSize + (fieldIndex << 2)
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
	^self longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
]

{ #category : #'object access' }
SpurMemoryManager >> fetchWordLengthOf: objOop [
	"NOTE: this gives size appropriate for fetchPointer: n, but not in general for, eg, fetchLong32, etc.
	 Unlike lengthOf: this does not adjust the length of a context
	 by the stackPointer and so can be used e.g. by cloneContext:"
	^self numSlotsOf: objOop
]

{ #category : #compaction }
SpurMemoryManager >> fillHighestObjectsWithMovableObjectsFrom: startObj upTo: limitObj [
	"Refill highestObjects with movable objects up to, but not including limitObj.
	 c.f. the loop in freeUnmarkedObjectsNilUnmarkedWeaklingSlotsAndSortAndCoalesceFreeSpace."
	| lastHighest highestObjectsWraps |
	lastHighest := highestObjects last.
	highestObjectsWraps := 0.
	self allOldSpaceObjectsFrom: startObj do:
		[:o|
		o >= limitObj ifTrue:
			[highestObjects last: lastHighest.
			 ^self].
		((self isForwarded: o) or: [self isPinned: o]) ifFalse:
			[false "conceptually...: "
				ifTrue: [highestObjects addLast: o]
				ifFalse: "but we inline so we can use the local lastHighest"
					[(lastHighest := lastHighest + self wordSize) >= highestObjects limit ifTrue:
						[highestObjectsWraps := highestObjectsWraps + 1].
					 self longAt: lastHighest put: o]]].
	highestObjects last: lastHighest
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
	[self assert: (self isValidFreeObject: treeNode).
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
		  and: [(self str: aCString n: (self pointerForOop: obj + BaseHeaderSize) cmp: cssz) = 0]]) ifTrue:
			[coInterpreter printHex: obj; space; printOopShort: obj; cr]]
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> fireAllUnscannedEphemerons [
	self assert: (self noUnscannedEphemerons) not.
	self assert: self allUnscannedEphemeronsAreActive.
	unscannedEphemerons start to: unscannedEphemerons top - self wordSize do:
		[:p|
		self queueEphemeron: (self longAt: p)].
	coInterpreter forceInterruptCheck
]

{ #category : #'object enumeration' }
SpurMemoryManager >> firstAccessibleObject [
	<inline: false>
	self assert: nilObj = newSpaceLimit.
	"flush newSpace to settle the enumeration."
	self flushNewSpace.
	^nilObj
]

{ #category : #'header formats' }
SpurMemoryManager >> firstByteFormat [
	<api>
	^16
]

{ #category : #'class table puns' }
SpurMemoryManager >> firstClassIndexPun [
	"Class puns are class indices not used by any class.  There is an entry
	 for the pun that refers to the notional class of objects with this class
	 index.  But because the index doesn't match the class it won't show up
	 in allInstances, hence hiding the object with a pun as its class index.
	 The puns occupy indices 16 through 31."
	^16
]

{ #category : #'header formats' }
SpurMemoryManager >> firstCompiledMethodFormat [
	<api>
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
	fmt <= self lastPointerFormat ifTrue: "pointer; may need to delve into the class format word"
		[(fmt between: self indexablePointersFormat and: self weakArrayFormat) ifTrue:
			[classFormat := self formatOfClass: (self fetchClassOfNonImm: objOop).
			 ^self pointerForOop: objOop
								+ self baseHeaderSize
								+ ((self fixedFieldsOfClassFormat: classFormat) << self wordSize)].
		^self pointerForOop: objOop
							+ self baseHeaderSize
							+ ((self numSlotsOf: objOop) << self wordSize)].
	"All bit objects, and indeed CompiledMethod, though this is a non-no, start at 0"
	self assert: fmt < self firstCompiledMethodFormat.
	^self pointerForOop: objOop + self baseHeaderSize
]

{ #category : #'header formats' }
SpurMemoryManager >> firstLongFormat [
	<api>
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

{ #category : #'object format' }
SpurMemoryManager >> fixedFieldsFieldWidth [
	^16
]

{ #category : #'object format' }
SpurMemoryManager >> fixedFieldsOf: objOop format: fmt length: wordLength [
	| class |
	<inline: true>
	<asmLabel: false>
	(fmt > self lastPointerFormat or: [fmt = 2]) ifTrue: [^0].  "indexable fields only"
	fmt < 2 ifTrue: [^wordLength].  "fixed fields only (zero or more)"
	class := self fetchClassOfNonImm: objOop.
	^self fixedFieldsOfClassFormat: (self formatOfClass: class)
]

{ #category : #'object format' }
SpurMemoryManager >> fixedFieldsOfClass: objOop [
	^self fixedFieldsOfClassFormat: (self formatOfClass: objOop)
]

{ #category : #'object format' }
SpurMemoryManager >> fixedFieldsOfClassFormat: classFormat [
	^classFormat bitAnd: self fixedFieldsOfClassFormatMask
]

{ #category : #'object format' }
SpurMemoryManager >> fixedFieldsOfClassFormatMask [
	^1 << self fixedFieldsFieldWidth - 1
]

{ #category : #'simulation only' }
SpurMemoryManager >> floatValueOf: obj [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter floatValueOf: obj
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> flushNewSpace [
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

{ #category : #'become api' }
SpurMemoryManager >> followForwarded: objOop [
	"Follow a forwarding pointer.  Alas we cannot prevent forwarders to forwarders
	 being created by lazy become.  Consider the following example by Igor Stasenko:
		array := { a. b. c }.
		- array at: 1 points to &a. array at: 2 points to &b. array at: 3 points to &c Ó
		a becomeForward: b
		- array at: 1 still points to &a. array at: 2 still points to &b. array at: 3 still points to &c
		b becomeForward: c.
		- array at: 1 still points to &a. array at: 2 still points to &b. array at: 3 still points to &c
		- when accessing array first one has to follow a forwarding chain:
		&a -> &b -> c"
	| referent |
	self assert: (self isForwarded: objOop).
	referent := self fetchPointer: 0 ofMaybeForwardedObject: objOop.
	[(self isOopForwarded: referent)] whileTrue:
		[referent := self fetchPointer: 0 ofMaybeForwardedObject: referent].
	^referent
]

{ #category : #'become api' }
SpurMemoryManager >> followForwardedObjectFields: objOop toDepth: depth [
	"follow pointers in the object to depth.
	 How to avoid cyclic structures?? A temproary mark bit?"
	| oop |
	self assert: (self isPointers: objOop).
	0 to: (self numSlotsOf: objOop) - 1 do:
		[:i|
		oop := self fetchPointer: i ofObject: objOop.
		((self isNonImmediate: oop)
		 and: [self isForwarded: oop]) ifTrue:
			[oop := self followForwarded: oop.
			self storePointer: i ofObject: objOop withValue: oop].
		depth > 0 ifTrue:
			[self followForwardedObjectFields: objOop toDepth: depth - 1]]
]

{ #category : #'become implementation' }
SpurMemoryManager >> followMaybeForwarded: objOop [
	^(self isForwarded: objOop)
		ifTrue: [self followForwarded: objOop]
		ifFalse: [objOop]
]

{ #category : #'header format' }
SpurMemoryManager >> formatFieldWidthShift [
	"The format field contains 5 bits."
	^5
]

{ #category : #'header format' }
SpurMemoryManager >> formatMask [
	"0 = 0 sized objects (UndefinedObject True False et al)
	 1 = non-indexable objects with inst vars (Point et al)
	 2 = indexable objects with no inst vars (Array et al)
	 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
	 4 = weak indexable objects with inst vars (WeakArray et al)
	 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
	 6,7,8 unused
	 9 (?) 64-bit indexable
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
	 9 (?) 64-bit indexable
	 10 - 11 32-bit indexable	(11 unused in 32 bits)
	 12 - 15 16-bit indexable	(14 & 15 unused in 32-bits)
	 16 - 23 byte indexable		(20-23 unused in 32-bits)
	 24 - 31 compiled method	(28-21 unused in 32-bits)"
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
	 9 (?) 64-bit indexable
	 10 - 11 32-bit indexable
	 12 - 15 16-bit indexable
	 16 - 23 byte indexable
	 24 - 31 compiled method"
	<var: 'header' type: #usqLong>
	^header >> self formatShift bitAnd: self formatMask
]

{ #category : #'header format' }
SpurMemoryManager >> formatShift [
	^24
]

{ #category : #'become implementation' }
SpurMemoryManager >> forward: obj1 to: obj2 [
	self setFormatOf: obj1 to: self forwardedFormat.
	self setClassIndexOf: obj1 to: self isForwardedObjectClassIndexPun.
	self storePointer: 0 ofForwarder: obj1 withValue: obj2
]

{ #category : #'become implementation' }
SpurMemoryManager >> forwardSurvivor: obj1 to: obj2 [
	self assert: (self isInNewSpace: obj1).
	self assert: (self isInFutureSpace: obj2).
	self storePointerUnchecked: 0 ofObject: obj1 withValue: obj2.
	self setFormatOf: obj1 to: self forwardedFormat.
	self setClassIndexOf: obj1 to: self isForwardedObjectClassIndexPun
]

{ #category : #'header formats' }
SpurMemoryManager >> forwardedFormat [
	"A special format used by the GC to follow only the first pointer."
	^7
]

{ #category : #'free space' }
SpurMemoryManager >> freeChunkLargerIndex [
	"for organizing the tree of large free chunks."
	^4
]

{ #category : #'free space' }
SpurMemoryManager >> freeChunkNextAddressIndex [
	"for sorting free chunks in memory order"
	^1
]

{ #category : #'free space' }
SpurMemoryManager >> freeChunkNextIndex [
	"for linking objecs on each free list"
	^0
]

{ #category : #'free space' }
SpurMemoryManager >> freeChunkParentIndex [
	"for organizing the tree of large free chunks."
	^2
]

{ #category : #'free space' }
SpurMemoryManager >> freeChunkPrevIndex [
	"for quickly unlinking nodes in the tree of large free chunks."
	^5
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
	freeChunk := self initFreeChunkWithBytes: bytes at: address.
	self addToFreeList: freeChunk bytes: bytes.
	^freeChunk
]

{ #category : #'free space' }
SpurMemoryManager >> freeListsObj [
	^self objectAfter: trueObj
]

{ #category : #'free space' }
SpurMemoryManager >> freeListsObject [
	^self objectAfter: trueObj
]

{ #category : #'free space' }
SpurMemoryManager >> freeObject: objOop [
	| bytes |
	bytes := self bytesInObject: objOop.
	totalFreeOldSpace := totalFreeOldSpace + bytes.
	^self freeChunkWithBytes: bytes at: (self startOfObject: objOop)
]

{ #category : #snapshot }
SpurMemoryManager >> freeOldSpaceStart [
	^freeOldSpaceStart
]

{ #category : #'free space' }
SpurMemoryManager >> freeSize [
	^totalFreeOldSpace
]

{ #category : #'free space' }
SpurMemoryManager >> freeSmallObject: objOop [
	| bytes index |
	bytes := self bytesInObject: objOop.
	index := bytes / self allocationUnit.
	self assert: index < self numFreeLists.
	self setFree: objOop. 
	self storePointer: self freeChunkNextIndex ofFreeChunk: objOop withValue: (freeLists at: index).
	freeLists at: index put: objOop.
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
	 smallChild := self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: treeNode.
	 largeChild := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: treeNode.
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

{ #category : #'gc - global' }
SpurMemoryManager >> freeUnmarkedObjectsAndSortAndCoalesceFreeSpace [
	"Sweep all of old space, freeing unmarked objects, coalescing free chunks, and sorting free space.

	 Small free chunks are sorted in address order on each small list head.  Large free chunks
	 are sorted on the sortedFreeChunks list.  Record as many of the highest objects as there
	 is room for in highestObjects, a circular buffer, for the use of exactFitCompact.  Use
	 unused eden space for highestObjects.  If highestObjects does not wrap, store 0
	 at highestObjects last.  Record the lowest free object in firstFreeChunk.  Let the
	 segmentManager mark which segments contain pinned objects via notePinned:."

	| lastLargeFree lastHighest highestObjectsWraps sortedFreeChunks |
	<var: #lastHighest type: #usqInt>
	self checkFreeSpace.
	scavenger forgetUnmarkedRememberedObjects.
	segmentManager prepareForGlobalSweep."for notePinned:"
	"for sorting free space throw away the list heads, rebuilding them for small free chunks below."
	self resetFreeListHeads.
	highestObjects initializeStart: freeStart limit: scavenger eden limit.
	lastHighest := highestObjects last "a.k.a. freeStart - wordSize".
	highestObjectsWraps := 0.
	self assert: highestObjects limit - highestObjects start // self wordSize >= 1024.
	firstFreeChunk := sortedFreeChunks := lastLargeFree := 0.
	"Note that if we were truly striving for performance we could split the scan into
	 two phases, one up to the first free object and one after, which would remove
	 the need to test firstFreeChunk when filling highestObjects."
	self allOldSpaceEntitiesForCoalescingDo:
		[:o|
		(self isMarked: o)
			ifTrue: "forwarders should have been followed in markAndTrace:"
				[self assert: (self isForwarded: o) not.
				 self setIsMarkedOf: o to: false.
				 (self isPinned: o) ifTrue:
					[segmentManager notePinned: o].
				 firstFreeChunk ~= 0 ifTrue:
					[false "conceptually...: "
						ifTrue: [highestObjects addLast: o]
						ifFalse: "but we inline so we can use the local lastHighest"
							[(lastHighest := lastHighest + self wordSize) >= highestObjects limit ifTrue:
								[highestObjectsWraps := highestObjectsWraps + 1].
							 self longAt: lastHighest put: o]]]
			ifFalse: "unmarked; two cases, an unreachable object or a free chunk."
				[| here next |
				 self assert: (self isRemembered: o) not. "scavenger should have cleared this above"
				 here := o.
				 next := self objectAfter: here limit: endOfMemory.
				 (self isMarked: next) ifFalse: "coalescing; rare case"
					[self assert: (self isRemembered: o) not.
					 [statCoalesces := statCoalesces + 1.
					  here := self coalesce: here and: next.
					  next := self objectAfter: here limit: endOfMemory.
					  next = endOfMemory or: [self isMarked: next]] whileFalse].
				 firstFreeChunk = 0 ifTrue:
					[firstFreeChunk := here].
				 (self isLargeFreeObject: here)
					ifTrue:
						[lastLargeFree = 0
							ifTrue: [sortedFreeChunks := here]
							ifFalse:
								[self setFree: here.
								 self storePointer: self freeChunkNextAddressIndex ofFreeChunk: lastLargeFree withValue: here].
						 lastLargeFree := here]
					ifFalse:
						[self freeSmallObject: here]]].
	highestObjects last: lastHighest.
	highestObjectsWraps ~= 0 ifTrue:
		[highestObjects first: (lastHighest + self wordSize >= highestObjects limit
								ifTrue: [highestObjects start]
								ifFalse: [lastHighest + self wordSize])].
	lastLargeFree ~= 0 ifTrue:
		[self storePointer: self freeChunkNextAddressIndex ofFreeChunk: lastLargeFree withValue: 0].
	totalFreeOldSpace := self reverseSmallListHeads.
	totalFreeOldSpace := totalFreeOldSpace + (self rebuildFreeTreeFrom: sortedFreeChunks).
	self checkFreeSpace.
	self touch: highestObjectsWraps
]

{ #category : #'gc - global' }
SpurMemoryManager >> fullGC [
	<inline: false>
	needGCFlag := false.
	gcStartUsecs := self ioUTCMicrosecondsNow.
	statMarkCount := 0.
	coInterpreter preGCAction: GCModeFull.
	self globalGarbageCollect.
	coInterpreter postGCAction: GCModeFull.
	statFullGCs := statFullGCs + 1.
	statGCEndUsecs := self ioUTCMicrosecondsNow.
	statFullGCUsecs := statFullGCUsecs + (statGCEndUsecs - gcStartUsecs).
]

{ #category : #'gc - global' }
SpurMemoryManager >> fullGCLock [
	"Spur never has a need to lock GC because it does not move pinned objects."
	^0
]

{ #category : #accessing }
SpurMemoryManager >> gcStartUsecs [
	^gcStartUsecs
]

{ #category : #'gc - global' }
SpurMemoryManager >> globalGarbageCollect [
	self runLeakCheckerForFullGC: true.
	self markObjects.
	self nilUnmarkedWeaklingSlots.
	self freeUnmarkedObjectsAndSortAndCoalesceFreeSpace.
	self bestFitCompact.
	self eliminateAndFreeForwarders.
	self runLeakCheckerForFullGC: true
]

{ #category : #'object testing' }
SpurMemoryManager >> goodContextSize: oop [
	| numSlots |
	numSlots := self numSlotsOf: oop.
	^numSlots = SmallContextSlots or: [numSlots = LargeContextSlots]
]

{ #category : #'header format' }
SpurMemoryManager >> greyBitShift [
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
	| ammount |
	<var: #segInfo type: #'SpurSegmentInfo *'>
	"statGrowMemory counts attempts, not successes."
	statGrowMemory := statGrowMemory + 1.
	"we need to include overhead for a new object header plus the segment bridge."
	ammount := minAmmount + (self baseHeaderSize * 2 + self bridgeSize).
	"round up to the nearest power of two."
	ammount := 1 << (ammount - 1) highBit.
	"and grow by at least growHeadroom."
	ammount := ammount max: growHeadroom.
	^(segmentManager addSegmentOfSize: ammount) ifNotNil:
		[:segInfo|
		 self assimilateNewSegment: segInfo.
		 segInfo segSize]
]

{ #category : #'header access' }
SpurMemoryManager >> hasOverflowHeader: objOop [
	^(self rawNumSlotsOf: objOop) = self numSlotsMask
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
		((self isNonImmediate: oop)
		 and: [self isYoung: oop]) ifTrue:
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
		 hash := self newObjectHash bitAnd: self identityHashHalfWordMask.
		 self setHashBitsOf: objOop to: hash].
	^hash
]

{ #category : #'header format' }
SpurMemoryManager >> headerForSlots: numSlots format: formatField classIndex: classIndex [
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

{ #category : #'debug support' }
SpurMemoryManager >> heapMap [
	^heapMap
]

{ #category : #'class table' }
SpurMemoryManager >> hiddenRootSlots [
	"Answer the number of extra root slots in the root of the hidden root object."
	^8
]

{ #category : #'class table' }
SpurMemoryManager >> hiddenRootsObj: anOop [
	hiddenRootsObj := anOop.
	self cCode: [self assert: self validClassTableRootPages]
		inSmalltalk: [numClassTablePages ifNotNil:
						[self assert: self validClassTableRootPages]]..
	classTableFirstPage := self fetchPointer: 0 ofObject: hiddenRootsObj.
	self assert: (self numSlotsOf: classTableFirstPage) - 1 = self classTableMinorIndexMask.
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

{ #category : #'header format' }
SpurMemoryManager >> identityHashFieldWidth [
	^22
]

{ #category : #'header format' }
SpurMemoryManager >> identityHashHalfWordMask [
	^16r3fffff
]

{ #category : #snapshot }
SpurMemoryManager >> imageSizeToWrite [
	"when asked, newSpace should be empty."
	self assert: self newSpaceIsEmpty.
	^segmentManager totalBytesInSegments
]

{ #category : #'header format' }
SpurMemoryManager >> immutableBitShift [
	"bit 1 of 2-bit field above classIndex (little endian)"
	^23
]

{ #category : #'class table' }
SpurMemoryManager >> inClassTableBitmapSet: classIndex [
	| bit majorIndex |
	self assert: (classIndex >= 0 and: [classIndex <= self classIndexMask]).
	majorIndex := classIndex // BitsPerByte.
	bit := 1 << (classIndex bitAnd: BitsPerByte - 1).
	classTableBitmap
		at: majorIndex
		put: ((classTableBitmap at: majorIndex) bitOr: bit)
]

{ #category : #'free space' }
SpurMemoryManager >> inFreeTreeReplace: treeNode with: newNode [
	"Part of reorderReversedTreeList:.  Switch treeNode with newNode in
	 the tree, but do nothing to the list linked through freeChunkNextIndex."
	| relative |
	"copy parent, smaller, larger"
	self freeChunkParentIndex to: self freeChunkLargerIndex do:
		[:i|
		relative := self fetchPointer: i ofObject: treeNode.
		i = self freeChunkParentIndex
			ifTrue:
				[relative = 0
					ifTrue: "update root to point to newNode"
						[self assert: (freeLists at: 0) = treeNode.
						 freeLists at: 0 put: newNode]
					ifFalse: "replace link from parent to treeNode with link to newNode."
						[self storePointer: (treeNode = (self fetchPointer: self freeChunkSmallerIndex ofObject: relative)
												ifTrue: [self freeChunkSmallerIndex]
												ifFalse: [self freeChunkLargerIndex])
							ofFreeChunk: relative
							withValue: newNode]]
			ifFalse:
				[relative ~= 0 ifTrue:
					[self assert: (self fetchPointer: self freeChunkParentIndex ofObject: relative) = treeNode.
					 self storePointer: self freeChunkParentIndex ofFreeChunk: relative withValue: newNode]].
		self storePointer: i ofFreeChunk: newNode withValue: relative.
		self storePointer: i ofFreeChunk: treeNode withValue: 0]
]

{ #category : #'become implementation' }
SpurMemoryManager >> inPlaceBecome: obj1 and: obj2 copyHashFlag: copyHashFlag [
	"Do become in place by swapping object contents."
	| headerTemp temp1 temp2 o1HasYoung o2HasYoung |
	self assert: (self numSlotsOf: obj1) = (self numSlotsOf: obj2).
	"swap headers, but swapping headers swaps remembered bits;
	 these need to be unswapped."
	temp1 := self isRemembered: obj1.
	temp2 := self isRemembered: obj2.
	headerTemp := self longLongAt: obj1.
	self longLongAt: obj1 put: (self longLongAt: obj2).
	self longLongAt: obj2 put: headerTemp.
	self setIsRememberedOf: obj1 to: temp1.
	self setIsRememberedOf: obj2 to: temp2.
	"swapping headers swaps hash; if !copyHashFlag undo hash copy"
	copyHashFlag ifFalse:
		[temp1 := self rawHashBitsOf: obj1.
		 self setHashBitsOf: obj1 to: (self rawHashBitsOf: obj2).
		 self setHashBitsOf: obj2 to: temp1].
	o1HasYoung := o2HasYoung := false.
	0 to: (self numSlotsOf: obj1) - 1 do:
		[:i|
		temp1 := self fetchPointer: i ofObject: obj1.
		temp2 := self fetchPointer: i ofObject: obj2.
		self storePointerUnchecked: i
			ofObject: obj1
			withValue: temp2.
		self storePointerUnchecked: i
			ofObject: obj2
			withValue: temp1.
		((self isNonImmediate: temp2) and: [self isYoung: temp2]) ifTrue:
			[o1HasYoung := true].
		((self isNonImmediate: temp1) and: [self isYoung: temp1]) ifTrue:
			[o2HasYoung := true]].
	(self isYoung: obj1) ifFalse:
		[o1HasYoung ifTrue:
			[self possibleRootStoreInto: obj1]].
	(self isYoung: obj2) ifFalse:
		[o2HasYoung ifTrue:
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

{ #category : #'gc - global' }
SpurMemoryManager >> incrementalGC [
	self shouldNotImplement
]

{ #category : #'header formats' }
SpurMemoryManager >> indexablePointersFormat [
	<api>
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
SpurMemoryManager >> initSpaceForAllocationCheck: aNewSpace [
	<var: 'aNewSpace' type: #'SpurNewSpaceSpace *'>
	memory ifNotNil:
		[CheckObjectOverwrite ifTrue:
			[aNewSpace start
				to: aNewSpace limit - 1
				by: self wordSize
				do: [:p| self longAt: p put: p]]]
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
	needGCFlag := signalLowSpace := scavengeInProgress := marking := false.
	becomeEffectsFlags := 0.
	statScavenges := statIncrGCs := statFullGCs := 0.
	statScavengeGCUsecs := statIncrGCUsecs := statFullGCUsecs := statGCEndUsecs := 0.
	statSGCDeltaUsecs := statIGCDeltaUsecs := statFGCDeltaUsecs := 0.
	statGrowMemory := statShrinkMemory := statRootTableCount := statSurvivorCount := 0.
	statRootTableOverflows := statMarkCount := statSpecialMarkCount := statCompactPassCount := statCoalesces := 0.

	"We can initialize things that are allocated but are lazily initialized."
	unscannedEphemerons := SpurContiguousObjStack new.
	highestObjects := SpurCircularBuffer new manager: self; yourself.

	"we can initialize things that are virtual in C."
	scavenger := SpurGenerationScavengerSimulator new manager: self; yourself.
	segmentManager := SpurSegmentManager new manager: self; yourself.

	"We can also initialize here anything that is only for simulation."
	heapMap := self wordSize = 4 ifTrue: [CogCheck32BitHeapMap new].

	"N.B. We *don't* initialize extraRoots because we don't simulate it."
]

{ #category : #snapshot }
SpurMemoryManager >> initializeFreeSpacePostLoad: freeListObj [
	"Reinitialize the free list info.  The freeLists object needs to be swizzled
	 because its neither a free, nor a pointer object.  Free objects have already
	 been swizzled in adjustAllOopsBy:"
	
	self assert: (self numSlotsOf: freeListObj) = self numFreeLists.
	self assert: (self formatOf: freeListObj) = (self wordSize = 4
													ifTrue: [self firstLongFormat]
													ifFalse: [self sixtyFourBitIndexableFormat]).

	freeLists := self firstIndexableField: freeListObj.
	0 to: self numFreeLists - 1 do:
		[:i|
		(freeLists at: i) ~= 0 ifTrue:
			[freeListsMask := freeListsMask bitOr: (1 << i).
			 segmentManager numSegments > 0 ifTrue: "false in Spur image bootstrap"
				[freeLists at: i put: (segmentManager swizzleObj: (freeLists at: i))]]].
	totalFreeOldSpace := self totalFreeListBytes
]

{ #category : #'gc - global' }
SpurMemoryManager >> initializeMarkStack [
	self ensureRoomOnObjStackAt: MarkStackRootIndex
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> initializeNewSpaceVariables [
	startOfMemory ifNotNil: "true in bootstrap"
		[^self].
	freeStart := scavenger eden start.
	pastSpaceStart := scavenger pastSpace start.
	scavengeThreshold := scavenger eden limit
							- (scavenger edenBytes / 64)
							- coInterpreter interpreterAllocationReserveBytes.
	startOfMemory := scavenger pastSpace start min: scavenger futureSpace start.
	self assert: startOfMemory < scavenger eden start.
	self initSpaceForAllocationCheck: (self addressOf: scavenger eden)
]

{ #category : #initialization }
SpurMemoryManager >> initializeObjectMemory: bytesToShift [
	"Initialize object memory variables at startup time. Assume endOfMemory is initially set (by the image-reading code) to the end of the last object in the image. Initialization redefines endOfMemory to be the end of the object allocation area based on the total available memory, but reserving some space for forwarding blocks."
	"Assume: image reader initializes the following variables:
		memory
		memoryLimit
		specialObjectsOop
		lastHash
	"
	<inline: false>
	| freeListObj |
	"Catch mis-initializations leading to bad translations to C"
	self assert: BaseHeaderSize = self baseHeaderSize.

	segmentManager adjustSegmentSwizzlesBy: bytesToShift.
	"image may be at a different address; adjust oops for new location"
	self adjustAllOopsBy: bytesToShift.

	segmentManager numSegments > 0 "false if Spur image bootstrap"
		ifTrue: [specialObjectsOop := segmentManager swizzleObj: specialObjectsOop]
		ifFalse: [self assert: bytesToShift = 0].

	"heavily used special objects"
	nilObj		:= self splObj: NilObject.
	falseObj	:= self splObj: FalseObject.
	trueObj		:= self splObj: TrueObject.

	"In Cog we insist that nil, true & false are next to each other (Cogit generates tighter
	 conditional branch code as a result).  In addition, Spur places the free lists and
	 class table root page immediately following them."
	self assert: nilObj = newSpaceLimit.
	self assert: falseObj = (self objectAfter: nilObj).
	self assert: trueObj = (self objectAfter: falseObj).
	freeListObj := self objectAfter: trueObj.
	self reInitializeClassTablePostLoad: (self objectAfter: freeListObj).
	self initializeFreeSpacePostLoad: freeListObj.
	markStack := self swizzleObjStackAt: MarkStackRootIndex.
	weaklingStack := self swizzleObjStackAt: WeaklingStackRootIndex.
	ephemeronQueue := self swizzleObjStackAt: EphemeronQueueRootIndex.

	segmentManager collapseSegmentsPostSwizzle.

	self initializeNewSpaceVariables.
	self initializeOldSpaceFirstFree: freeOldSpaceStart. "initializes endOfMemory, freeStart"

	"These defaults should depend on machine size; e.g. too small on a powerful laptop, too big on a Pi."
	growHeadroom := 16*1024*1024.		"headroom when growing"
	shrinkThreshold := 32*1024*1024.		"free space before shrinking"
]

{ #category : #'free space' }
SpurMemoryManager >> initializeOldSpaceFirstFree: startOfFreeOldSpace [
	<var: 'startOfFreeOldSpace' type: #usqLong>
	| freeOldStart freeChunk |
	<var: 'freeOldStart' type: #usqLong>
	
	endOfMemory > startOfFreeOldSpace ifTrue:
		[totalFreeOldSpace := totalFreeOldSpace + (endOfMemory - startOfFreeOldSpace).
		 freeOldStart := startOfFreeOldSpace.
		 [endOfMemory - freeOldStart >= (2 raisedTo: 32)] whileTrue:
			[freeChunk := self freeChunkWithBytes: (2 raisedTo: 32) at: freeOldStart.
			 freeOldStart := freeOldStart + (2 raisedTo: 32).
			 self assert: freeOldStart = (self addressAfter: freeChunk)].
		freeOldStart < endOfMemory ifTrue:
			[freeChunk := self freeChunkWithBytes: endOfMemory - freeOldStart at: freeOldStart.
			 self assert: (self addressAfter: freeChunk) = endOfMemory]].
	freeOldSpaceStart := endOfMemory.
	self checkFreeSpace
]

{ #category : #'spur bootstrap' }
SpurMemoryManager >> initializePostBootstrap [
	"The heap has just been bootstrapped into a modified newSpace occupying all of memory
	 above newSpace (and the codeZone). Put things back to some kind of normalcy."
	freeOldSpaceStart := freeStart.
	freeStart := scavenger eden start.
	pastSpaceStart := scavenger pastSpace start.
	scavengeThreshold := scavenger eden limit - (scavenger edenBytes / 64)
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
				start: largestFree + self baseHeaderSize;
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
		obj1 := self fetchPointer: i ofObject: array1.
		obj2 := self fetchPointer: i ofObject: array2.
		self doBecome: obj1 and: obj2 copyHash: copyHashFlag.
		(self isForwarded: obj1) ifTrue:
			[obj1 := self followForwarded: obj1.
			 self storePointer: i ofObject: array1 withValue: obj1].
		(self isForwarded: obj2) ifTrue:
			[obj2 := self followForwarded: obj2.
			 self storePointer: i ofObject: array2 withValue: obj2]]
]

{ #category : #'become implementation' }
SpurMemoryManager >> innerBecomeObjectsIn: array1 to: array2 copyHash: copyHashFlag [
	"Inner loop of one-way become."
	0 to: (self numSlotsOf: array1) - 1 do:
		[:i| | obj1 obj2 |
		obj1 := self fetchPointer: i ofObject: array1.
		obj2 := self fetchPointer: i ofObject: array2.
		self doBecome: obj1 to: obj2 copyHash: copyHashFlag.
		(self isForwarded: obj1) ifTrue:
			[obj1 := self followForwarded: obj1.
			 self storePointer: i ofObject: array1 withValue: obj1].
		self assert: (self isForwarded: obj2) not]
]

{ #category : #'object format' }
SpurMemoryManager >> instSpecOfClass: classPointer [
	"This is the same as the field stored in every object header"

	^self instSpecOfClassFormat: (self formatOfClass: classPointer)
]

{ #category : #'object format' }
SpurMemoryManager >> instSpecOfClassFormat: classFormat [
	^classFormat >> self fixedFieldsFieldWidth bitAnd: self formatMask
]

{ #category : #'object enumeration' }
SpurMemoryManager >> instanceAfter: objOop [
	| actualObj classIndex |
	actualObj := objOop.
	classIndex := self classIndexOf: objOop.

	(self isInEden: objOop) ifTrue:
		[[actualObj := self objectAfter: actualObj limit: freeStart.
		  actualObj < freeStart] whileTrue:
			[classIndex = (self classIndexOf: actualObj) ifTrue:
				[^actualObj]].
		 actualObj := pastSpaceStart > scavenger pastSpace start
						ifTrue: [self objectStartingAt: scavenger pastSpace start]
						ifFalse: [nilObj]].

	(self isInSurvivorSpace: actualObj) ifTrue:
		[[actualObj := self objectAfter: actualObj limit: pastSpaceStart.
		  actualObj < pastSpaceStart] whileTrue:
			[classIndex = (self classIndexOf: actualObj) ifTrue:
				[^actualObj]].
		 actualObj := nilObj].

	[actualObj := self objectAfter: actualObj limit: freeOldSpaceStart.
	 actualObj < freeOldSpaceStart] whileTrue:
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
	newObj := self allocateSlots: numSlots format: instSpec classIndex: classIndex.
	newObj ifNotNil:
		[self fillObj: newObj numSlots: numSlots with: nilObj].
	^newObj
]

{ #category : #instantiation }
SpurMemoryManager >> instantiateClass: classObj indexableSize: nElements [
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
	"Immediate characters are unsigned"
	^(self cCoerceSimple: oop to: #'unsigned long') >> 1
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
SpurMemoryManager >> ioLoadFunction: functionString From: pluginString [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter ioLoadFunction: functionString From: pluginString
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

{ #category : #'object testing' }
SpurMemoryManager >> isArray: oop [
	"Answer true if this is an indexable object with pointer elements, e.g., an array"
	^(self isNonImmediate: oop) and: [self isArrayNonImm: oop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isArrayNonImm: oop [
	"Answer true if this is an indexable object with pointer elements, e.g., an array"
	^ (self formatOf: oop) = self arrayFormat
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

{ #category : #'object testing' }
SpurMemoryManager >> isClassOfNonImm: objOop equalTo: classOop [
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
	<asmLabel: false>
	self assert: (self isImmediate: oop) not.

	ccIndex := self classIndexOf: oop.
	knownClassIndex ~= 0 ifTrue:
		[^knownClassIndex = ccIndex].
	^classOop = (self classAtIndex: ccIndex)
]

{ #category : #'object testing' }
SpurMemoryManager >> isCompiledMethod: objOop [
    "Answer whether the argument object is of compiled method format"
	<api>
    ^(self formatOf: objOop) >= 24
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

{ #category : #'obj stacks' }
SpurMemoryManager >> isEmptyObjStack: objStack [
	self assert: (self isValidObjStack: objStack).
	^0 = (self fetchPointer: ObjStackTopx ofObject: objStack)
]

{ #category : #'object testing' }
SpurMemoryManager >> isEphemeron: objOop [
	self assert: (self isNonImmediate: objOop).
	^(self formatOf: objOop) = self ephemeronFormat
]

{ #category : #'header format' }
SpurMemoryManager >> isFixedSizePointerFormat: format [
	^format <= self nonIndexablePointerFormat
	  or: [format = self ephemeronFormat]
]

{ #category : #'simulation only' }
SpurMemoryManager >> isFloatObject: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter isFloatObject: oop
]

{ #category : #'object testing' }
SpurMemoryManager >> isForwarded: objOop [
	^(self classIndexOf: objOop) = self isForwardedObjectClassIndexPun
]

{ #category : #'class table' }
SpurMemoryManager >> isForwardedClassTag: classIndex [
	^classIndex = self isForwardedObjectClassIndexPun
]

{ #category : #'class table puns' }
SpurMemoryManager >> isForwardedObjectClassIndexPun [
	^8 "Not to be confused with that of any immediate class"
]

{ #category : #'object testing' }
SpurMemoryManager >> isFreeObject: objOop [
	^(self classIndexOf: objOop) = self isFreeObjectClassIndexPun
]

{ #category : #'class table puns' }
SpurMemoryManager >> isFreeObjectClassIndexPun [
	^0
]

{ #category : #'header access' }
SpurMemoryManager >> isGrey: objOop [
	^((self longAt: objOop) >> self greyBitShift bitAnd: 1) ~= 0
]

{ #category : #'debug support' }
SpurMemoryManager >> isHiddenObj: objOop [
	^objOop =  self freeListsObject
	  or: [(self numSlotsOfAny: objOop) = ObjStackPageSlots
		and: [self isValidObjStackPage: objOop myIndex: (self fetchPointer: ObjStackMyx ofObject: objOop)]]
]

{ #category : #'object testing' }
SpurMemoryManager >> isImmediate: oop [
	<api>
	^(oop bitAnd: self tagMask) ~= 0
]

{ #category : #'object testing' }
SpurMemoryManager >> isImmediateCharacter: oop [
	^(oop bitAnd: self tagMask) = 2
]

{ #category : #'header access' }
SpurMemoryManager >> isImmutable: objOop [
	^((self longAt: objOop) >> self immutableBitShift bitAnd: 1) ~= 0
]

{ #category : #'class table' }
SpurMemoryManager >> isInClassTable: objOop [
	| hash |
	hash := self rawHashBitsOf: objOop.
	hash = 0 ifTrue:
		[false].
	^(self classAtIndex: hash) = objOop
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
	"Return true if the given address is in ST object memory"
	^(self oop: address isGreaterThanOrEqualTo: startOfMemory)
		and: [(self oop: address isLessThan: newSpaceLimit)
			or: [segmentManager isInSegments: address]]
]

{ #category : #'object testing' }
SpurMemoryManager >> isInNewSpace: objOop [
	^objOop >= startOfMemory
	  and: [objOop < newSpaceLimit]
]

{ #category : #'object testing' }
SpurMemoryManager >> isInOldSpace: address [
	^self
		oop: address
		isGreaterThanOrEqualTo: newSpaceLimit
		andLessThan: freeOldSpaceStart
]

{ #category : #immediates }
SpurMemoryManager >> isInRangeCharacterCode: characterCode [
	^characterCode >= 0 and: [characterCode < (2 raisedTo: 30)]
]

{ #category : #'object testing' }
SpurMemoryManager >> isInSurvivorSpace: address [
	^self
		oop: address
		isGreaterThanOrEqualTo: scavenger pastSpace start
		andLessThan: pastSpaceStart
]

{ #category : #'object testing' }
SpurMemoryManager >> isIndexable: objOop [
	| fmt |
	fmt := self formatOf: objOop.
	^self isIndexableFormat: fmt
]

{ #category : #'object testing' }
SpurMemoryManager >> isIndexableFormat: format [
	^format >= self arrayFormat
	  and: [format <= self weakArrayFormat
			or: [format >= self sixtyFourBitIndexableFormat]]
]

{ #category : #'object testing' }
SpurMemoryManager >> isIntegerObject: oop [
	^(oop bitAnd: 1) ~= 0
]

{ #category : #'interpreter access' }
SpurMemoryManager >> isIntegerValue: intValue [
	"Answer if the given value can be represented as a Smalltalk integer value."
	^self subclassResponsibility
]

{ #category : #'free space' }
SpurMemoryManager >> isLargeFreeObject: objOop [
	^(self bytesInObject: objOop)  / self allocationUnit >= self numFreeLists
]

{ #category : #'header access' }
SpurMemoryManager >> isMarked: objOop [
	self subclassResponsibility
]

{ #category : #'object testing' }
SpurMemoryManager >> isNonImmediate: oop [ 
	^(oop bitAnd: self tagMask) = 0
]

{ #category : #'object testing' }
SpurMemoryManager >> isNonIntegerObject: oop [
	^(oop bitAnd: 1) = 0
]

{ #category : #'object enumeration' }
SpurMemoryManager >> isNormalObject: objOop [
	^(self classIndexOf: objOop) > self lastClassIndexPun
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
	^(self isNonImmediate: oop)
	  and: [(self classIndexOf: oop) = self isForwardedObjectClassIndexPun]
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

{ #category : #'object testing' }
SpurMemoryManager >> isPointersFormat: format [
	^format <= self lastPointerFormat
]

{ #category : #'object testing' }
SpurMemoryManager >> isPointersNonImm: objOop [
	"Answer if the argument has only fields that can hold oops. See comment in formatOf:"
	^(self formatOf: objOop) <= self lastPointerFormat
]

{ #category : #'header access' }
SpurMemoryManager >> isRemembered: objOop [
	^((self longAt: objOop) >> self rememberedBitShift bitAnd: 1) ~= 0
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

{ #category : #'free space' }
SpurMemoryManager >> isValidFreeObject: objOop [
	| chunk |
	^(self addressCouldBeObj: objOop)
	  and: [(self isFreeObject: objOop)
	  and: [((chunk := (self fetchPointer: self freeChunkNextIndex ofFreeChunk: objOop)) = 0
		   or: [self isFreeObject: chunk])
	  and: [(self bytesInObject: objOop) / self allocationUnit < self numFreeLists
		    or: [((chunk := (self fetchPointer: self freeChunkParentIndex ofFreeChunk: objOop)) = 0
			   or: [self isFreeObject: chunk])
			  and: [((chunk := (self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: objOop)) = 0
				    or: [self isFreeObject: chunk])
			  and: [(chunk := (self fetchPointer: self freeChunkLargerIndex ofFreeChunk: objOop)) = 0
				    or: [self isFreeObject: chunk]]]]]]]
]

{ #category : #'obj stacks' }
SpurMemoryManager >> isValidObjStack: objStack [
	"Answer if the obj stack at objStackRootIndex is valid."
	((self addressCouldBeObj: objStack)
	 and: [(self numSlotsOfAny: objStack) = ObjStackPageSlots]) ifFalse:
		[objStackInvalidBecause := 'first page not obj or wrong size'.
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
SpurMemoryManager >> isValidObjStackPage: objStackPage myIndex: myx [
	"Just check the page itself."
	<inline: false>
	(self classIndexOf: objStackPage) = self wordSizeClassIndexPun ifFalse:
		[objStackInvalidBecause := 'wong class index'.
		 ^false].
	(self formatOf: objStackPage) = self wordIndexableFormat ifFalse:
		[objStackInvalidBecause := 'wong format'.
		 ^false].
	(self numSlotsOfAny: objStackPage) = ObjStackPageSlots ifFalse:
		[objStackInvalidBecause := 'wong num slots'.
		 ^false].
	myx = (self fetchPointer: ObjStackMyx ofObject: objStackPage) ifFalse:
		[objStackInvalidBecause := 'wong myx'.
		 ^false].
	^true
]

{ #category : #'obj stacks' }
SpurMemoryManager >> isValidObjStackPage: objStackPage myIndex: myx firstPage: isFirstPage [
	"Answer if the obj stack at stackRootIndex is valid."
	| freeOrNextPage index |
	<inline: false>
	(self isValidObjStackPage: objStackPage myIndex: myx) ifFalse:
		[^false].
	freeOrNextPage := self fetchPointer: ObjStackFreex ofObject: objStackPage.
	[freeOrNextPage ~= 0] whileTrue:
		[isFirstPage ifFalse:
			[objStackInvalidBecause := 'free page on other than first page'.
			 ^false].
		 (self isValidObjStackPage: freeOrNextPage myIndex: myx) ifFalse:
			[objStackInvalidBecause := self str: objStackInvalidBecause cat: ', on next page'.
			^false].
		 freeOrNextPage := self fetchPointer: ObjStackFreex ofObject: freeOrNextPage].
	isFirstPage ifTrue:
		[(myx between: self classTableRootSlots and: self classTableRootSlots + self hiddenRootSlots - 1) ifFalse:
			[objStackInvalidBecause := 'myx out of range'.
			 ^false].
		 (self fetchPointer: myx ofObject: hiddenRootsObj) = objStackPage ifFalse:
			[objStackInvalidBecause := 'firstPage is not root'.
			 ^false]].
	index := self fetchPointer: ObjStackTopx ofObject: objStackPage.
	(index between: 0 and: ObjStackLimit) ifFalse:
		[objStackInvalidBecause := 'bad topx'.
		 ^false].
	freeOrNextPage := self fetchPointer: ObjStackNextx ofObject: objStackPage.
	^freeOrNextPage = 0
	  or: [self isValidObjStackPage: freeOrNextPage myIndex: myx firstPage: false]
]

{ #category : #segments }
SpurMemoryManager >> isValidSegmentBridge: objOop [
	"Maybe this should be in SpurSegmentManager only"
	^(self addressCouldBeObj: objOop)
	 and: [(self isSegmentBridge: objOop)
	 and: [self hasOverflowHeader: objOop]]
]

{ #category : #'object testing' }
SpurMemoryManager >> isWeak: oop [
	"Answer if the argument has only weak fields that can hold oops. See comment in formatOf:"
	^(self isNonImmediate: oop) and: [self isWeakNonImm: oop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isWeakNonImm: objOop [
	^(self formatOf: objOop) = self weakArrayFormat
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
	^(self isNonImmediate: oop)
	  and: [self isWordsOrBytesNonImm: oop]
]

{ #category : #'object testing' }
SpurMemoryManager >> isWordsOrBytesNonImm: objOop [
	^(self formatOf: objOop) > self lastPointerFormat
]

{ #category : #'object testing' }
SpurMemoryManager >> isYoung: objOop [
	^self oop: objOop isLessThan: newSpaceLimit
]

{ #category : #'object access' }
SpurMemoryManager >> keyOfEphemeron: objOop [
	"Answer the object the ephemeron guards.  This is its first element."
	self assert: ((self isNonImmediate: objOop) and: [self isEphemeron: objOop]).
	^self fetchPointer: 0 ofObject: objOop
]

{ #category : #'class table' }
SpurMemoryManager >> knownClassAtIndex: classIndex [
	self assert: (classIndex between: 1 and: self classTablePageSize).
	^self fetchPointer: classIndex ofObject: classTableFirstPage
]

{ #category : #'class table puns' }
SpurMemoryManager >> lastClassIndexPun [
	"Class puns are class indices not used by any class.  There is an entry
	 for the pun that refers to the notional class of objects with this class
	 index.  But because the index doesn't match the class it won't show up
	 in allInstances, hence hiding the object with a pun as its class index.
	 The puns occupy indices 16 through 31."
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
	<asmLabel: false>
	| fmt contextSize numLiterals |
	fmt := self formatOf: objOop.
	self assert: fmt ~= self forwardedFormat.
	fmt <= self lastPointerFormat ifTrue:
		[(fmt = self indexablePointersFormat
		  and: [self isContextNonImm: objOop]) ifTrue:
			["contexts end at the stack pointer"
			contextSize := coInterpreter fetchStackPointerOf: objOop.
			^CtxtTempFrameStart + contextSize * BytesPerOop].
		^(self numSlotsOf: objOop) - 1 * BytesPerOop + self baseHeaderSize  "all pointers"].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	numLiterals := coInterpreter literalCountOf: objOop.
	^numLiterals + LiteralStart - 1 * BytesPerOop + self baseHeaderSize
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
	<asmLabel: false>
	| fmt numLiterals |
	fmt := self formatOf: objOop.
	self assert: fmt ~= self forwardedFormat.
	fmt <= self lastPointerFormat ifTrue:
		[^(self numSlotsOf: objOop) - 1 * BytesPerOop + self baseHeaderSize  "all pointers"].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	numLiterals := coInterpreter literalCountOf: objOop.
	^numLiterals + LiteralStart - 1 * BytesPerOop + self baseHeaderSize
]

{ #category : #'debug support' }
SpurMemoryManager >> leakCheckBecome [
	<api>
	^(checkForLeaks bitAnd: 4) ~= 0
]

{ #category : #'debug support' }
SpurMemoryManager >> leakCheckFullGC [
	<api>
	^(checkForLeaks bitAnd: 1) ~= 0
]

{ #category : #'debug support' }
SpurMemoryManager >> leakCheckIncrementalGC [
	<api>
	^(checkForLeaks bitAnd: 8) ~= 0
]

{ #category : #'debug support' }
SpurMemoryManager >> leakCheckNewSpaceGC [
	<api>
	^(checkForLeaks bitAnd: 2) ~= 0
]

{ #category : #'object access' }
SpurMemoryManager >> lengthOf: objOop [
	"Answer the number of indexable units in the given object.
	 For a CompiledMethod, the size of the method header (in bytes) should
	 be subtracted from the result."

	<api>
	<inline: true>
	<asmLabel: false>
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
	| numSlots |
	<inline: true>
	<asmLabel: false> 
	numSlots := self numSlotsOf: objOop.
	fmt <= self sixtyFourBitIndexableFormat ifTrue:
		[^numSlots].
	fmt >= self firstByteFormat ifTrue: "bytes, including CompiledMethod"
		[^numSlots << self shiftForWord - (fmt bitAnd: 7)].
	fmt >= self firstShortFormat ifTrue:
		[^numSlots << (self shiftForWord - 1) - (fmt bitAnd: 3)].
	"fmt >= self firstLongFormat"
	^numSlots << (self shiftForWord - 2) - (fmt bitAnd: 1)
]

{ #category : #'debug support' }
SpurMemoryManager >> lengthOfMaybeImmediate: oop [
	"for the message send breakpoint; selectors can be immediates."
	<inline: false>
	(self isImmediate: oop) ifTrue: [^0].
	^self lengthOf: oop
]

{ #category : #'primitive support' }
SpurMemoryManager >> loadImageSegmentFrom: segmentWordArray outPointers: outPointerArray [
	"This primitive is called from Squeak as...
		<imageSegment> loadSegmentFrom: aWordArray outPointers: anArray."

"This primitive will load a binary image segment created by primitiveStoreImageSegment.  It expects the outPointer array to be of the proper size, and the wordArray to be well formed.  It will return as its value the original array of roots, and the erstwhile segmentWordArray will have been truncated to a size of zero.  If this primitive should fail, the segmentWordArray will, sadly, have been reduced to an unrecognizable and unusable jumble.  But what more could you have done with it anyway?"

	^PrimErrUnsupported
]

{ #category : #'simulation only' }
SpurMemoryManager >> lookupAddress: address [
	"If address appears to be that of a Symbol or a few well-known objects (such as classes) answer it, otherwise answer nil.
	 For code disassembly"
	<doNotGenerate>
	| fmt size string class classSize maybeThisClass classNameIndex thisClassIndex |
	(self addressCouldBeObj: address) ifFalse:
		[^nil].
	address - self baseHeaderSize = hiddenRootsObj ifTrue:
		[^'(hiddenRootsObj+baseHeaderSize)'].
	fmt := self formatOf: address.
	size := self lengthOf: address baseHeader: (self baseHeader: address) format: fmt.
	size = 0 ifTrue:
		[^address caseOf: { [nilObj] -> ['nil']. [trueObj] -> ['true']. [falseObj] -> ['false'] } otherwise: []].
	((fmt between: self firstByteFormat and: self firstCompiledMethodFormat - 1) "indexable byte fields"
	and: [(size between: 1 and: 64)
	and: [Scanner isLiteralSymbol: (string := (0 to: size - 1) collect: [:i| Character value: (self fetchByte: i ofObject: address)])]]) ifTrue:
		[^'#', (ByteString withAll: string)].
	class := self fetchClassOfNonImm: address.
	(class isNil or: [class = nilObj]) ifTrue:
		[^nil].
	"address is either a class or a metaclass, or an instance of a class or invalid.  determine which."
	classNameIndex := coInterpreter classNameIndex.
	thisClassIndex := coInterpreter thisClassIndex.
	((classSize := self numSlotsOf: class) <= (classNameIndex max: thisClassIndex)
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

{ #category : #'free space' }
SpurMemoryManager >> lowSpaceThreshold: threshold [
	lowSpaceThreshold := threshold.
	totalFreeOldSpace < threshold ifTrue:
		[self growOldSpaceByAtLeast: threshold - totalFreeOldSpace].
	self assert: totalFreeOldSpace >= lowSpaceThreshold
]

{ #category : #'gc - global' }
SpurMemoryManager >> mapExtraRoots [
	self assert: remapBufferCount = 0.
	1 to: extraRootCount do:
		[:i | | oop |
		oop := (extraRoots at: i) at: 0.
		((self isImmediate: oop) or: [self isFreeObject: oop]) ifFalse:
			[(self shouldRemapObj: oop) ifTrue:
				[(extraRoots at: i) at: 0 put: (self remapObj: oop)]]]
]

{ #category : #'gc - global' }
SpurMemoryManager >> markAccessibleObjects [
	self assert: self validClassTableRootPages.
	self assert: segmentManager allBridgesMarked.
	marking := true.
	self cCode: [] "for debugging markAndTrace: set (MarkStackRecord := OrderedCollection new)"
		inSmalltalk: [MarkStackRecord ifNotNil: [MarkStackRecord resetTo: 1]].
	self markAndTraceObjStack: self markStack andContents: false.
	self assert: self validClassTableRootPages.
	self markAndTraceObjStack: self ephemeronQueue andContents: true.
	self assert: self validClassTableRootPages.
	coInterpreter markAndTraceInterpreterOops: true.
	self markAndTrace: self freeListsObj.
	self markAndTrace: hiddenRootsObj.
	self markAndTrace: self specialObjectsOop.
	self markWeaklingsAndMarkAndFireEphemerons.
	marking := false
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> markAllUnscannedEphemerons [
	"After firing the unscanned ephemerons we must scan-mark them.
	 The wrinkle is that doing so may add more ephemerons to the set."
	| ptr |
	self assert: (self noUnscannedEphemerons) not.
	self assert: self allUnscannedEphemeronsAreActive.
	ptr := unscannedEphemerons top - self wordSize.
	[ptr >= unscannedEphemerons start] whileTrue:
		[| ephemeron key |
		 key := self keyOfEphemeron: (ephemeron := self longAt: ptr).
		 self markAndTrace: key;
			markAndTrace: ephemeron.
		 unscannedEphemerons top: unscannedEphemerons top - self wordSize.
		 ptr < unscannedEphemerons top ifTrue:
			["not the last entry; remove it by overwriting it with the last
			  ephemeron (which must have been newly added by markAndTrace:)."
			 self longAt: ptr put: (self longAt: unscannedEphemerons top)].
		ptr := ptr - self wordSize]
]

{ #category : #'gc - global' }
SpurMemoryManager >> markAndTrace: objOop [
	"Mark the argument, and all objects reachable from it, and any remaining objects on the mark stack.
	 Follow forwarding pointers in the scan."
	| objToScan index field |
	self assert: (self isNonImmediate: objOop).
	"if markAndTrace: is to follow and eliminate forwarding pointers
	 in its scan it cannot be handed an r-value which is forwarded."
	self assert: (self isForwarded: objOop) not.
	(self isMarked: objOop) ifTrue:
		[^self].
	"self setIsMarkedOf: objOop to: false" "for debugging"
	self setIsMarkedOf: objOop to: true.

	"Now scan the object, and any remaining objects on the mark stack."
	objToScan := objOop.
	"To avoid overflowing the mark stack when we encounter large objects, we
	 push the obj, then its numStrongSlots, and then index the object from the stack."
	[| numStrongSlots |
	 ((self isImmediate: objToScan)
	 or: [numStrongSlots := self numStrongSlotsOf: objToScan ephemeronInactiveIf: #inactiveOrFailedToDeferScan:.
		 numStrongSlots > self traceImmediatelySlotLimit])
		ifTrue: "scanning a large object. scan until hitting an unmarked object, then switch to it, if any."
			[(self isImmediate: objToScan)
				ifTrue:
					[index := self integerValueOf: objToScan.
					 objToScan := self topOfObjStack: markStack]
				ifFalse:
					[index := numStrongSlots].
			 [index > 0] whileTrue:
				[index := index - 1.
				 field := self fetchPointer: index ofObject: objToScan.
				 (self isOopForwarded: field) ifTrue:
					[field := self followForwarded: field.
					 self storePointerUnchecked: index ofObject: objToScan withValue: field].
				 ((self isImmediate: field)
				  or: [self isMarked: field]) ifFalse:
					[self setIsMarkedOf: field to: true.
					 (self isWeakNonImm: objToScan)
						ifTrue: [self push: field onObjStack: weaklingStack]
						ifFalse:
							[(self topOfObjStack: markStack) ~= objToScan ifTrue: 
								[self push: objToScan onObjStack: markStack].
							 self push: (self integerObjectOf: index) onObjStack: markStack].
					 objToScan := field.
					 index := -1]].
			 index >= 0 ifTrue: "if loop terminated without finding an unmarked referent, switch to top of stack."
				[objToScan := self popObjStack: markStack.
				 objToScan = objOop ifTrue:
					[objToScan := self popObjStack: markStack]]]
		ifFalse: "scanning a small object. scan, marking, pushing unmarked referents, then switch to the top of the stack."
			[index := numStrongSlots.
			 [index > 0] whileTrue:
				[index := index - 1.
				 field := self fetchPointer: index ofObject: objToScan.
				 (self isOopForwarded: field) ifTrue:
					[field := self followForwarded: field.
					 self storePointerUnchecked: index ofObject: objToScan withValue: field].
				 ((self isImmediate: field)
				  or: [self isMarked: field]) ifFalse:
					[self setIsMarkedOf: field to: true.
					 (self isWeakNonImm: field)
						ifTrue: [self push: field onObjStack: weaklingStack]
						ifFalse:
							[self push: field onObjStack: markStack.
							 numStrongSlots := self numStrongSlotsOf: field ephemeronInactiveIf: #inactiveOrFailedToDeferScan:.
							 numStrongSlots > self traceImmediatelySlotLimit ifTrue:
								[self push: (self integerObjectOf: numStrongSlots) onObjStack: markStack]]]].
			 objToScan := self popObjStack: markStack].
	 objToScan notNil] whileTrue
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
	self assert: (self numSlotsOfAny: stackOrNil) = ObjStackPageSlots.
	field := self fetchPointer: ObjStackNextx ofObject: stackOrNil.
	field ~= 0 ifTrue:
		[self markAndTraceObjStack: field andContents: markAndTraceContents].
	field := stackOrNil.
	[field := self fetchPointer: ObjStackFreex ofObject: stackOrNil.
	 field ~= 0] whileTrue:
		[self setIsMarkedOf: field to: true].
	markAndTraceContents ifFalse:
		[^self].
	"There are four fixed slots in an obj stack, and a Topx of 0 indicates empty, so
	  if there were 6 slots in an oop stack, full would be 2, and the last 0-rel index is 5."
	index := (self fetchPointer: ObjStackTopx ofObject: stackOrNil) + ObjStackNextx.
	[index >= ObjStackFixedSlots] whileTrue:
		[field := self fetchPointer: index ofObject: stackOrNil.
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
		 0 to: (self numStrongSlotsOf: weakling ephemeronInactiveIf: nil) - 1 do:
			[:field|
			((self isImmediate: field) or: [self isMarked: field]) ifFalse:
				[self markAndTrace: field]]]
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
		key := self keyOfEphemeron: (ephemeron := self longAt: ptr).
		((self isImmediate: key) or: [self isMarked: key])
			ifTrue:
				[foundInactive := true.
				 "Now remove the inactive ephemeron from the set, and scan-mark it.
				  Scan-marking it may add more ephemerons to the set."
				 unscannedEphemerons top: unscannedEphemerons top - self wordSize.
				 unscannedEphemerons top > ptr ifTrue:
					[self longAt: ptr put: (self longAt: unscannedEphemerons top)].
				 self markAndTrace: ephemeron]
			ifFalse:
				[ptr := ptr + self wordSize]].
	^foundInactive
]

{ #category : #'gc - global' }
SpurMemoryManager >> markObjects [
	"Mark all accessible objects."
	"If the incremental collector is running mark bits may be set; stop it and clear them if necessary."
	self ensureAllMarkBitsAreZero.
	self initializeUnscannedEphemerons.
	self initializeMarkStack.
	self initializeWeaklingStack.
	self markAccessibleObjects
]

{ #category : #'gc - global' }
SpurMemoryManager >> markStack [
	^self fetchPointer: MarkStackRootIndex ofObject: hiddenRootsObj
]

{ #category : #'gc - global' }
SpurMemoryManager >> markStack: anObject [
	self storePointer: MarkStackRootIndex ofObject: hiddenRootsObj withValue: anObject
]

{ #category : #'gc - global' }
SpurMemoryManager >> markWeaklingsAndMarkAndFireEphemerons [
	"After the initial scan-mark is complete ephemerons can be processed.
	 Weaklings have accumulated on the weaklingStack, but more may be
	 uncovered during ephemeron processing.  So trace the strong slots
	 of the weaklings, and as ephemerons are processed ensure any newly
	 reached weaklings are also traced."
	| numTracedWeaklings |
	numTracedWeaklings := 0.
	[coInterpreter markAndTraceUntracedReachableStackPages.
	 numTracedWeaklings := self markAndTraceWeaklingsFrom: numTracedWeaklings.
	 self noUnscannedEphemerons ifTrue:
		[^self].
	 self markInactiveEphemerons ifFalse:
		[self fireAllUnscannedEphemerons].
	 self markAllUnscannedEphemerons]
		repeat
]

{ #category : #'header format' }
SpurMemoryManager >> markedBitFullShift [
	"bit 1 of 2-bit field above identityHash (little endian)"
	^55
]

{ #category : #'header format' }
SpurMemoryManager >> markedBitHalfShift [
	"bit 1 of 2-bit field above identityHash (little endian)"
	^23
]

{ #category : #accessing }
SpurMemoryManager >> maxIdentityHash [
	^self identityHashHalfWordMask
]

{ #category : #instantiation }
SpurMemoryManager >> maxSlotsForNewSpaceAlloc [
	"Almost entirely arbitrary, but we dont want 1Mb bitmaps allocated in eden.
	 But this choice means no check for numSlots > maxSlotsForNewSpaceAlloc
	 for non-variable allocations."
	^self fixedFieldsOfClassFormatMask
]

{ #category : #'interpreter access' }
SpurMemoryManager >> maybeSplObj: index [
	<api>
	"Answer one of the objects in the SpecialObjectsArray, if in range, otherwise answer nil."
	^index < (self numSlotsOf: specialObjectsOop) ifTrue:
		[self fetchPointer: index ofObject: specialObjectsOop]
]

{ #category : #simulation }
SpurMemoryManager >> mem: destAddress cp: sourceAddress y: bytes [
	"For SpurGenerationScavenger>>copyToFutureSpace:bytes:"
	<doNotGenerate>
	^self mem: destAddress mo: sourceAddress ve: bytes
]

{ #category : #accessing }
SpurMemoryManager >> memory [
	<cmacro: '() memory'>
	^memory
]

{ #category : #accessing }
SpurMemoryManager >> memory: aValue [
	^memory := aValue
]

{ #category : #snapshot }
SpurMemoryManager >> memoryBaseForImageRead [
	"Answer the address to read the image into."
	^newSpaceLimit
]

{ #category : #snapshot }
SpurMemoryManager >> memoryLimit [
	^endOfMemory
]

{ #category : #'simulation only' }
SpurMemoryManager >> methodArgumentCount [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter methodArgumentCount
]

{ #category : #compaction }
SpurMemoryManager >> moveMisfitsInHighestObjectsBack: savedLimit [
	"After refilling highestObjects move any misfits back to being
	 adjacent with the new objects, reset the space's limit and
	 answer the pointer to the lowest failure to resume the scan."

	| newMisfitsPosition |
	savedLimit = highestObjects limit ifTrue:
		[^highestObjects last].
	"simple; we didnt fill all the way; just move misfits down."
	(highestObjects first = highestObjects start
	 and: [highestObjects last < highestObjects limit]) ifTrue:
		[newMisfitsPosition := highestObjects limit.
		 self mem: newMisfitsPosition asVoidPointer
			mo: (highestObjects last + self wordSize) asVoidPointer
			ve: savedLimit - newMisfitsPosition.
		 highestObjects limit: savedLimit.
		 ^newMisfitsPosition].
	"tricky to do unless we have last - start's worth of free space.
	 we *don't* want to rotate lots and lots of objects.  We could push
	 misfits onto the mark stack, if it is big enough.
	 limit: | misfits hi <-> lo | lowest candidates | highest candidates | : start
	                                                                   ^ last"
	self shouldBeImplemented.
	^newMisfitsPosition
]

{ #category : #compaction }
SpurMemoryManager >> moveMisfitsToTopOfHighestObjects: misfits [
	"After a cycle of exact-fit compaction highestObjects may contain some
	 number of mobile objects that fail to fit, and more objects may exist to
	 move.  Move existing misfits to top of highestObjects and temporarily
	 shrink highestObjects to refill it without overwriting misfits.  Answer the
	 old limit. moveMisfitsInHighestObjectsBack: will undo the change."

	| oldLimit bytesToMove |
	oldLimit := highestObjects limit.
	misfits = (highestObjects last + self wordSize) ifTrue:
		[highestObjects resetAsEmpty.
		 ^oldLimit].
	misfits <= highestObjects last ifTrue:
		[bytesToMove := highestObjects last + self wordSize - misfits.
		 self mem: (highestObjects limit - bytesToMove) asVoidPointer
			mo: misfits asVoidPointer
			ve: bytesToMove.
		 highestObjects limit: misfits - self wordSize.
		 ^oldLimit].
	"misfits wrapped; move in two stages to preserve ordering"
	bytesToMove := highestObjects last - highestObjects start.
	self mem: (misfits - bytesToMove) asVoidPointer
		mo: misfits asVoidPointer
		ve: oldLimit - misfits.
	highestObjects limit: misfits - bytesToMove.
	self mem: (oldLimit - bytesToMove)  asVoidPointer
		mo: highestObjects start asVoidPointer
		ve: bytesToMove.
	^oldLimit
]

{ #category : #accessing }
SpurMemoryManager >> needGCFlag [
	^needGCFlag
]

{ #category : #accessing }
SpurMemoryManager >> newObjectHash [
	"Use simple algorithm by D.H. Lehmer from 1951, for now."
	lastHash := lastHash * 16807 "7 raisedTo: 5" \\ 16r7ffffffd "(2 raisedTo: 31) - 1".
	self assert: lastHash ~= 0.
	^lastHash
]

{ #category : #accessing }
SpurMemoryManager >> newSpaceBytes [
	"during snapshot load newSpaceLimit holds newSpace size temporarily."
	^newSpaceLimit - coInterpreter interpreterAllocationReserveBytes
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
	^ (1 << self greyBitShift)
	 | (1 << self pinnedBitShift)
	 | (1 << self rememberedBitShift)
]

{ #category : #accessing }
SpurMemoryManager >> newSpaceSize [
	^(freeStart - scavenger eden start)
	 + (pastSpaceStart - scavenger pastSpace start)
]

{ #category : #'primitive support' }
SpurMemoryManager >> nilFieldsOf: obj [ 
	0 to: (self numSlotsOf: obj) - 1 do:
		[:i|
		self storePointerUnchecked: i ofObject: obj withValue: nilObj]
]

{ #category : #accessing }
SpurMemoryManager >> nilObject [
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
	self objStack: weaklingStack from: 0 do:
		[:weakling|
		(self nilUnmarkedWeaklingSlots: weakling) ifTrue:
			[coInterpreter signalFinalization: weakling]].
	self emptyObjStack: weaklingStack
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> nilUnmarkedWeaklingSlots: aWeakling [
	"Nil the unmarked slots in aWeakling and
	 answer if any unmarked slots were found."
	| anyUnmarked |
	anyUnmarked := false.
	(self numStrongSlotsOf: aWeakling ephemeronInactiveIf: nil) to: (self numSlotsOf: aWeakling) - 1 do:
		[:i| | oop |
		oop := self fetchPointer: i ofObject: aWeakling.
		((self isImmediate: oop) or: [self isMarked: oop]) ifFalse:
			[self storePointerUnchecked: i ofObject: aWeakling withValue: nilObj.
			 anyUnmarked := true]].
	^anyUnmarked
]

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> nilUnmarkedWeaklingSlotsIn: aWeakling [
	"Nil the unmarked slots in aWeakling and
	 answer if any unmarked slots were found."
	| anyUnmarked |
	anyUnmarked := false.
	(self numStrongSlotsOf: aWeakling ephemeronInactiveIf: nil) to: (self numSlotsOf: aWeakling) - 1 do:
		[:i| | oop |
		oop := self fetchPointer: i ofObject: aWeakling.
		((self isImmediate: oop) or: [self isMarked: oop]) ifFalse:
			[self storePointerUnchecked: i ofObject: aWeakling withValue: nilObj.
			 anyUnmarked := true]].
	^anyUnmarked
]

{ #category : #'obj stacks' }
SpurMemoryManager >> noCheckPush: objOop onObjStack: objStack [
	"Push an element on an objStack.  Split from push:onObjStack: for testing."
	| topx |
	self assert: (self isValidObjStack: objStack).
	self cCode: [] "for debugging markAndTrace: set (MarkStackRecord := OrderedCollection new)"
		inSmalltalk:
			[objStack = markStack ifTrue:
				[MarkStackRecord ifNotNil: [MarkStackRecord addLast: {#push. objOop}]]].
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

{ #category : #'weakness and ephemerality' }
SpurMemoryManager >> noUnscannedEphemerons [
	^unscannedEphemerons top = unscannedEphemerons start
]

{ #category : #'header formats' }
SpurMemoryManager >> nonIndexablePointerFormat [
	^1
]

{ #category : #'object format' }
SpurMemoryManager >> numFixedSlotsOf: objOop [
	<inline: true>
	<asmLabel: false>
	^self fixedFieldsOfClassFormat: (self formatOfClass: (self fetchClassOfNonImm: objOop))
]

{ #category : #'free space' }
SpurMemoryManager >> numFreeLists [
	"Answer the number of free lists.  We use freeListsMask, a bitmap, to avoid
	 reading empty list heads.  This hsould fit in a machine word to end up in a
	 register during free chunk allocation."
	^self subclassResponsibility
]

{ #category : #'object access' }
SpurMemoryManager >> numPointerSlotsOf: objOop [
	"Answer the number of pointer fields in the given object.
	 Works with CompiledMethods, as well as ordinary objects."
	<api>
	<inline: true>
	<asmLabel: false>
	| fmt contextSize numLiterals |
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
	numLiterals := coInterpreter literalCountOf: objOop.
	^numLiterals + LiteralStart
]

{ #category : #'header format' }
SpurMemoryManager >> numSlotsFullShift [
	^56
]

{ #category : #'header format' }
SpurMemoryManager >> numSlotsHalfShift [
	^24
]

{ #category : #'header format' }
SpurMemoryManager >> numSlotsMask [
	"8-bit slot count
		max 64-bit small obj size 254 * 8 =  2032 bytes
		max 32-bit small obj size 254 * 4 =   1016 bytes"
	^255
]

{ #category : #'object access' }
SpurMemoryManager >> numSlotsOf: objOop [
	<returnTypeC: #usqInt>
	| numSlots |
	self flag: #endianness.
	"numSlotsOf: should not be applied to free or forwarded objects."
	self assert: (self classIndexOf: objOop) > self isForwardedObjectClassIndexPun.
	numSlots := self rawNumSlotsOf: objOop..
	^numSlots = self numSlotsMask	"overflow slots; (2^32)-1 slots are plenty"
		ifTrue: [self rawOverflowSlotsOf: objOop]
		ifFalse: [numSlots]
]

{ #category : #'object access' }
SpurMemoryManager >> numSlotsOfAny: objOop [
	"A private internal version of numSlotsOf: that is happy to be applied to free or forwarded objects."
	<returnTypeC: #usqInt>
	| numSlots |
	numSlots := self rawNumSlotsOf: objOop..
	^numSlots = self numSlotsMask
		ifTrue: [self rawOverflowSlotsOf: objOop] "overflow slots; (2^32)-1 slots are plenty"
		ifFalse: [numSlots]
]

{ #category : #'object access' }
SpurMemoryManager >> numStrongSlotsOf: objOop ephemeronInactiveIf: criterion [
	"Answer the number of strong pointer fields in the given object.
	 Works with CompiledMethods, as well as ordinary objects."
	<api>
	<var: 'criterion' declareC: 'int (*criterion)(sqInt key)'>
	<inline: true>
	<asmLabel: false>
	| fmt numSlots  contextSize numLiterals |
	fmt := self formatOf: objOop.
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
		 ^(criterion isNil or: [self perform: criterion with: (self keyOfEphemeron: objOop)])
			ifTrue: [numSlots]
			ifFalse: [0]].
	fmt = self forwardedFormat ifTrue: [^1].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	numLiterals := coInterpreter literalCountOf: objOop.
	^numLiterals + LiteralStart
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

{ #category : #'obj stacks' }
SpurMemoryManager >> objStack: objStack from: start do: aBlock [
	"Evaluate aBlock with all elements from start (0-relative) in objStack.
	 Answer the size of the stack *before* the enumeration commences.
	 This evaluates in top-of-stack-to-bottom order.  N.B. this is also stable
	 if aBlock causes new elements to be added to the objStack, but
	 unstable if aBlock causes elements to be removed."
	| size objStackPage numToEnumerate |
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
			do:	[:i| aBlock value: (self fetchPointer: i ofObject: objStackPage)].
		 numToEnumerate := numToEnumerate - numToEnumerateOnThisPage.
		 objStackPage := self fetchPointer: ObjStackNextx ofObject: objStackPage].
	^size
]

{ #category : #'object enumeration' }
SpurMemoryManager >> objectAfter: objOop [
	"Object parsing.
	1. all objects have at least a word following the header, for a forwarding pointer.
	2. objects with an overflow size have a preceeing word with a saturated slotSize.  If the word following
	    an object doesn't have a saturated size field it must be a single-header object.  If the word following
	   does have a saturated slotSize it must be the overflow size word."
	<inline: false>
	objOop < newSpaceLimit ifTrue:
		[(self isInEden: objOop) ifTrue:
			[^self objectAfter: objOop limit: freeStart].
		 (self isInSurvivorSpace: objOop) ifTrue:
			[^self objectAfter: objOop limit: pastSpaceStart].
		 ^self objectAfter: objOop limit: scavenger futureSurvivorStart].
	^self objectAfter: objOop limit: freeOldSpaceStart
]

{ #category : #'object enumeration' }
SpurMemoryManager >> objectAfter: objOop limit: limit [
	"Object parsing.
	1. all objects have at least a word following the header, for a forwarding pointer.
	2. objects with an overflow size have a preceeing word with a saturated numSlots.  If the word
	   following an object doesn't have a saturated numSlots field it must be a single-header object.
	   If the word following does have a saturated numSlots it must be the overflow size word."
	^self subclassResponsibility
]

{ #category : #'object enumeration' }
SpurMemoryManager >> objectBefore: objOop [
	| prev |
	prev := nil.
	objOop < newSpaceLimit ifTrue:
		[self allNewSpaceObjectsDo:
			[:o|
			 o >= objOop ifTrue:
				[^prev].
			 prev := o].
		 ^prev].
	self allOldSpaceObjectsDo:
		[:o|
		 o >= objOop ifTrue:
			[^prev].
		 prev := o].
	^prev
]

{ #category : #'object enumeration' }
SpurMemoryManager >> objectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object with the given
	 number of slots, including header and possible overflow size header."
	self subclassResponsibility
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
	(self addressCouldBeObjWhileScavenging: oop) ifFalse:
		[self error: 'oop is not a valid address'. ^false].

	(self addressAfter: oop) <= freeOldSpaceStart ifFalse:
		[self error: 'oop size would make it extend beyond the end of memory'. ^false].

	"header type checks"
	(classIndex := self classIndexOf: oop) >= self firstClassIndexPun ifFalse:
		[self error: 'oop is a free chunk, or bridge, not an object'. ^false].
	((self rawNumSlotsOf: oop) = self numSlotsMask
	 and: [(self rawNumSlotsOf: oop) - self baseHeaderSize ~= self numSlotsMask]) ifTrue:
		[self error: 'oop header has overflow header word, but overflow word does not have a saturated numSlots field'. ^false].

	"format check"
	fmt := self formatOf: oop.
	(fmt = 6) | (fmt = 8) ifTrue:
		[self error: 'oop has an unknown format type'. ^false].
	(fmt = self forwardedFormat) ~= (classIndex = self isForwardedObjectClassIndexPun) ifTrue:
		[self error: 'oop has mismached format/classIndex fields; only one of them is the isForwarded value'. ^false].

	"specific header bit checks"
	unusedBits := (1 << self classIndexFieldWidth)
				   | (1 << (self identityHashFieldWidth + 32)).
	((self longLongAt: oop) bitAnd: unusedBits) ~= 0 ifTrue:
		[self error: 'some unused header bits are set; should be zero'. ^false].

	unusedBitsInYoungObjects := (1 << self greyBitShift)
								   | (1 << self pinnedBitShift)
								   | (1 << self rememberedBitShift).
	((self longAt: oop) bitAnd: unusedBitsInYoungObjects) ~= 0 ifTrue:
		[self error: 'some header bits unused in young objects are set; should be zero'. ^false].
	^true

]

{ #category : #accessing }
SpurMemoryManager >> oldSpaceSize [
	^segmentManager totalBytesInSegments
]

{ #category : #'become implementation' }
SpurMemoryManager >> outOfPlaceBecome: obj1 and: obj2 copyHashFlag: copyHashFlag [
	"Allocate two new objects, n1 & n2.  Copy the contents appropriately. Convert
	 obj1 and obj2 into forwarding objects pointing to n2 and n1 respectively"
	| clone1 clone2 |
	clone1 := (self isContextNonImm: obj1)
				ifTrue: [coInterpreter cloneContext: obj1]
				ifFalse: [self clone: obj1].
	clone2 := (self isContextNonImm: obj2)
				ifTrue: [coInterpreter cloneContext: obj2]
				ifFalse: [self clone: obj2].
	copyHashFlag
		ifTrue:
			[self setHashBitsOf: clone1 to: (self rawHashBitsOf: obj2).
			 self setHashBitsOf: clone2 to: (self rawHashBitsOf: obj1)]
		ifFalse:
			[self setHashBitsOf: clone1 to: (self rawHashBitsOf: obj1).
			 self setHashBitsOf: clone2 to: (self rawHashBitsOf: obj2)].
	self
		forward: obj1 to: clone2;
		forward: obj2 to: clone1
]

{ #category : #'primitive support' }
SpurMemoryManager >> pinObject: objOop [
	<api>
	self shouldBeImplemented
]

{ #category : #'header format' }
SpurMemoryManager >> pinnedBitShift [
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
	self assert: (self isValidObjStack: objStack).
	topx := self fetchPointer: ObjStackTopx ofObject: objStack.
	topx = 0 ifTrue:
		[self assert: (self fetchPointer: ObjStackNextx ofObject: objStack) = 0.
		 self cCode: [] "for debugging markAndTrace: set (MarkStackRecord := OrderedCollection new)"
			inSmalltalk:
				[MarkStackRecord ifNotNil:
					[MarkStackRecord addLast: {#EMPTY. nil}]].
		^nil].
	topx := topx - 1.
	top := self fetchPointer: topx + ObjStackFixedSlots ofObject: objStack.
	self cCode: [] "for debugging markAndTrace: set (MarkStackRecord := OrderedCollection new)"
		inSmalltalk:
			[MarkStackRecord ifNotNil:
				[(MarkStackRecord last first = #push and: [MarkStackRecord last last = top])
					ifTrue: [MarkStackRecord removeLast]
					ifFalse: [MarkStackRecord addLast: {#pop. top}]]].
	self storePointer: ObjStackTopx ofObject: objStack withValue: topx.
	(topx = 0
	 and: [(nextPage := self fetchPointer: ObjStackNextx ofObject: objStack) ~= 0]) ifTrue:
		[self storePointer: ObjStackFreex ofObjStack: nextPage withValue: objStack.
		 self storePointer: ObjStackNextx ofObjStack: objStack withValue: 0.
		 myx := self fetchPointer: ObjStackMyx ofObject: objStack.
		 self updateRootOfObjStack: myx with: nextPage].
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

{ #category : #'store check' }
SpurMemoryManager >> possibleRootStoreInto: destObj [
	(self isRemembered: destObj) ifFalse:
		[scavenger remember: destObj.
		 self setIsRememberedOf: destObj to: true]
]

{ #category : #'become implementation' }
SpurMemoryManager >> postBecomeOrCompactScanClassTable: effectsFlags [
	"Scan the class table post-become (iff a pointer object or compiled method was becommed),
	 or post-compact.
	 Note that one-way become can cause duplications in the class table.
	 When can these be eliminated?  We use the classTableBitmap to mark classTable entries
	 (not the classes themselves, since marking a class doesn't help in knowing if its index is used).
	 On image load, and during incrememtal scan-mark and full GC, classIndices are marked.
	 We can somehow avoid following classes from the classTable until after this mark phase."
	self assert: self validClassTableRootPages.

	(effectsFlags anyMask: BecamePointerObjectFlag+BecameCompiledMethodFlag) ifFalse: [^self].
	
	0 to: numClassTablePages - 1 do:
		[:i| | page |
		page := self fetchPointer: i ofObject: hiddenRootsObj.
		0 to: (self numSlotsOf: page) - 1 do:
			[:j| | classOrNil |
			classOrNil := self fetchPointer: j ofObject: page.
			classOrNil ~= nilObj ifTrue:
				[(self isForwarded: classOrNil) ifTrue:
					[classOrNil := self followForwarded: classOrNil.
					 self storePointer: j ofObject: page withValue: classOrNil].
				 self scanClassPostBecome: classOrNil effects: effectsFlags]]]
]

{ #category : #'become implementation' }
SpurMemoryManager >> postBecomeScanClassTable [
	"Scan the class table post-become (iff a pointer object or compiled method was becommed).
	 Note that one-way become can cause duplications in the class table.
	 When can these be eliminated?  We use the classtableBitmap to mark  classTable entries
	 (not the classes themselves, since marking a class doesn't help in knowing if its index is used).
	 On image load, and during incrememtal scan-mark and full GC, classIndices are marked.
	 We can somehow avoid following classes from the classTable until after this mark phase."

	self assert: self validClassTableRootPages.

	(becomeEffectsFlags anyMask: BecamePointerObjectFlag+BecameCompiledMethodFlag) ifFalse: [^self].
	
	self postBecomeOrCompactScanClassTable: becomeEffectsFlags
]

{ #category : #'become implementation' }
SpurMemoryManager >> postCompactScanClassTable [
	"Scan the class table post-compact.  Ensure all pages and
	 all classes are not forwarded."

	0 to: numClassTablePages - 1 do:
		[:i| | page |
		page := self fetchPointer: i ofObject: hiddenRootsObj.
		(self isForwarded: page) ifTrue: "this check is for eliminateAndFreeForwarders"
			[page := self followForwarded: page.
			 self storePointer: i ofObject: hiddenRootsObj withValue: page]].
	self assert: self validClassTableRootPages.	
	self postBecomeOrCompactScanClassTable: BecamePointerObjectFlag
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
SpurMemoryManager >> primitiveFailureCode [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter primitiveFailureCode
]

{ #category : #'debug printing' }
SpurMemoryManager >> printFreeChunk: freeChunk [
	<api>
	| numBytes |
	numBytes := self bytesInObject: freeChunk.
	coInterpreter
		print: 'freeChunk '; printHexPtrnp: freeChunk;
		print: ' bytes '; printNum: numBytes;
		print: ' next '; printHexPtrnp: (self fetchPointer: self freeChunkNextIndex
											ofFreeChunk: freeChunk).
	numBytes / self allocationUnit > self numFreeLists ifTrue:
		[coInterpreter
			print: ' ^ '; printHexPtrnp: (self fetchPointer: self freeChunkParentIndex
											ofFreeChunk: freeChunk);
			print: ' < '; printHexPtrnp: (self fetchPointer: self freeChunkSmallerIndex
											ofFreeChunk: freeChunk);
			print: ' > '; printHexPtrnp: (self fetchPointer: self freeChunkLargerIndex
											ofFreeChunk: freeChunk)].
	coInterpreter cr
]

{ #category : #'debug printing' }
SpurMemoryManager >> printHeaderTypeOf: objOop [
	coInterpreter print: ((self numSlotsOf: objOop) >= self numSlotsMask
							ifTrue: [' 16 byte header']
							ifFalse: [' 8 byte header'])
]

{ #category : #'debug printing' }
SpurMemoryManager >> printMemoryFrom: start to: end [
	<doNotGenerate>
	| address |
	address := start bitAnd: (self wordSize - 1) bitInvert.
	[address < end] whileTrue:
		[coInterpreter printHex: address; printChar: $:; space; printHex: (self longAt: address); cr.
		 address := address + BytesPerWord]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printReferencesTo: anOop [
	"Scan the heap printing the oops of any and all objects that refer to anOop"
	<api>
	self allObjectsDo:
		[:obj| | i |
		 i := self numPointerSlotsOf: obj.
		 [(i := i - 1) >= 0] whileTrue:
			[anOop = (self fetchPointer: i ofObject: obj) ifTrue:
				[coInterpreter printHex: obj; print: ' @ '; printNum: i; space; printOopShort: obj; cr.
				 i := 0]]]
]

{ #category : #'simulation only' }
SpurMemoryManager >> push: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter push: oop
]

{ #category : #'obj stacks' }
SpurMemoryManager >> push: objOop onObjStack: objStack [
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
	unscannedEphemerons top: unscannedEphemerons top + self wordSize.
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
SpurMemoryManager >> queueEphemeron: anEphemeron [
	self assert: ((self isNonImmediate: anEphemeron)
				and: [(self formatOf: anEphemeron) = self ephemeronFormat]).
	self push: anEphemeron onObjStack: ephemeronQueue
]

{ #category : #'header access' }
SpurMemoryManager >> rawHashBitsOf: objOop [
	self flag: #endianness.
	^(self longAt: objOop + 4) bitAnd: self identityHashHalfWordMask
]

{ #category : #'object access' }
SpurMemoryManager >> rawNumSlotsOf: objOop [
	<returnTypeC: #usqInt>
	^self subclassResponsibility
]

{ #category : #'object access' }
SpurMemoryManager >> rawOverflowSlotsOf: objOop [
	<returnTypeC: #usqInt>
	self subclassResponsibility
]

{ #category : #'class table' }
SpurMemoryManager >> reInitializeClassTablePostLoad: hiddenRoots [
	self hiddenRootsObj: hiddenRoots.
	self expungeDuplicateClasses
]

{ #category : #snapshot }
SpurMemoryManager >> readHeapFromImageFile: f dataBytes: numBytes [
	"Read numBytes of image data from f into memory at memoryBaseForImageRead.
	 Answer the number of bytes written."
	<doNotGenerate>
	^segmentManager readHeapFromImageFile: f dataBytes: numBytes
]

{ #category : #'free space' }
SpurMemoryManager >> rebuildFreeTreeFrom: sortedFreeChunks [
	"post sweep and pre compact, rebuild the large free chunk tree from the
	 sortedFreeChunks list, such that the lists are ordered from low to high address."
	| freeChunk bytes totalBytes |
	"first add all the chunks to the tree.  This will result in almost address-sorted lists.
	 We will need to reorder the lists."
	freeChunk := sortedFreeChunks.
	totalBytes := 0.
	[freeChunk ~= 0] whileTrue:
		[bytes := self bytesInObject: freeChunk.
		 totalBytes := totalBytes + bytes.
		 self addToFreeTree: freeChunk bytes: bytes.
		 freeChunk := self fetchPointer: self freeChunkNextAddressIndex
							ofObject: freeChunk].
	"now reorder the lists to ensure they're in address order, apart from the list head, which should be highest."
	self freeTreeNodesDo:
		[:treeNode| | newTreeNode |
		newTreeNode := self reorderReversedTreeList: treeNode.
		newTreeNode].
	^totalBytes
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
	^remapBufferCount
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> remapObj: objOop [
	"Scavenge or simply follow objOop.  Answer the new location of objOop.  The
	 send should have been guarded by a send of shouldRemapOop: or shouldScavengeObj:.
	 The method is called remapObj: for compatibility with ObjectMemory."
	<inline: false>
	| resolvedObj |
	self assert: (self shouldRemapOop: objOop).
	(self isForwarded: objOop)
		ifTrue:
			[resolvedObj := self followForwarded: objOop.
			(self isYoung: resolvedObj) ifFalse: "a becommed object whose target is in old space"
				[^resolvedObj].
			(self isInFutureSpace: resolvedObj) ifTrue: "already scavenged"
				[^resolvedObj]]
		ifFalse:
			[resolvedObj := objOop].
	^scavenger copyAndForward: resolvedObj
]

{ #category : #'header format' }
SpurMemoryManager >> rememberedBitShift [
	"bit 0 of 3-bit field above format (little endian)"
	^29
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

{ #category : #'free space' }
SpurMemoryManager >> reorderReversedTreeList: treeNode [
	"Once the freeTree has been rebuilt from the sortedFreeChunks list
	 each list will be in a weird order, the list in reverse order, high to low,
	 but the tree node, because it is inserted first, will be the lowest address.
	 Reverse the list so it is sorted low to high, but make the highest address
	 node the first, as this will be allocated from last."
	| first next node prev |
	"first becomes the new head, as this is the last one we want to allocate and we allocate from the list first."
	first := self fetchPointer: self freeChunkNextIndex ofObject: treeNode.
	"no next node, so no change"
	first = 0 ifTrue:
		[^treeNode].
	node := self fetchPointer: self freeChunkNextIndex ofObject: first.
	self storePointer: self freeChunkNextIndex ofFreeChunk: first withValue: treeNode.
	self inFreeTreeReplace: treeNode with: first.
	prev := 0.
	[node ~= 0] whileTrue:
		[next := self fetchPointer: self freeChunkNextIndex ofObject: node.
		 self storePointer: self freeChunkNextIndex ofFreeChunk: node withValue: prev.
		 prev := node.
		 node := next].
	self storePointer: self freeChunkNextIndex ofFreeChunk: treeNode withValue: prev.
	^first
]

{ #category : #'free space' }
SpurMemoryManager >> resetFreeListHeads [
	0 to: self numFreeLists - 1 do:
		[:i| freeLists at: i put: 0]
]

{ #category : #snapshot }
SpurMemoryManager >> reverseBytesFrom: startAddr to: stopAddr [
	"Byte-swap the given range of memory (not inclusive of stopAddr!)."
	| addr |
	addr := startAddr.
	[self oop: addr isLessThan: stopAddr] whileTrue:
		[self longAt: addr put: (self byteSwapped: (self longAt: addr)).
		addr := addr + BytesPerWord]
]

{ #category : #snapshot }
SpurMemoryManager >> reverseBytesInMemory [
	self reverseBytesFrom: newSpaceLimit to: freeOldSpaceStart
]

{ #category : #'free space' }
SpurMemoryManager >> reverseSmallListHeads [
	"After freeUnmarkedObjectsNilUnmarkedWeaklingSlotsAndSortAndCoalesceFreeSpace
	 all small free chunks will be on the free lists in reverse address order.  Reverse each list,
	 summing the ammount of space.  Answer the sum of bytes of free space on these small lists."
	| total |
	total := 0.
	freeListsMask := 0.
	1 to: self numFreeLists - 1 do:
		[:i| | bytes node prev next |
		 bytes := i * self allocationUnit.
		 node := freeLists at: i.
		 node ~= 0 ifTrue:
			[self assert: (self bytesInObject: node) = bytes.
			 freeListsMask := freeListsMask + (1 << i).
			 prev := 0.
			 [node ~= 0] whileTrue:
				[next := self fetchPointer: self freeChunkNextIndex ofObject: node.
				 self storePointer: self freeChunkNextIndex ofFreeChunk: node withValue: prev.
				 prev := node.
				 node := next.
				 total := total + bytes].
			 freeLists at: i put: prev]].
	^total
]

{ #category : #accessing }
SpurMemoryManager >> rootTableCount [
	^scavenger rememberedSetSize
]

{ #category : #'debug support' }
SpurMemoryManager >> runLeakCheckerForFullGC: fullGCFlag [
	<inline: false>
	(fullGCFlag
			ifTrue: [self leakCheckFullGC]
			ifFalse: [self leakCheckNewSpaceGC]) ifTrue:
		[fullGCFlag
			ifTrue: [coInterpreter reverseDisplayFrom: 0 to: 7]
			ifFalse: [coInterpreter reverseDisplayFrom: 8 to: 15].
		 self clearLeakMapAndMapAccessibleObjects.
		 self assert: self checkHeapIntegrity.
		 self assert: coInterpreter checkInterpreterIntegrity.
		 self assert: coInterpreter checkStackIntegrity.
		 self assert: (coInterpreter checkCodeIntegrity: fullGCFlag)]
]

{ #category : #'debug printing' }
SpurMemoryManager >> safePrintStringOf: oop [
	| target |
	target := (self isOopForwarded: oop)
				ifTrue: [self followForwarded: oop]
				ifFalse: [oop].
	^coInterpreter printStringOf: target
]

{ #category : #'become implementation' }
SpurMemoryManager >> scanClassPostBecome: startClassObj effects: becomeEffects [
	"Scan a class in the class table post-become.  Make sure the superclass
	 chain contains no forwarding pointers, and that the method dictionaries
	 are not forwarded either, and that methoidClassAssociations in methods
	 are not followed either."

	| classObj obj obj2 |
	"Algorithm depend on this to terminate loop at root of superclass chain."
	self assert: (self rawHashBitsOf: nilObj) ~= 0.
	self assert: (becomeEffects anyMask: BecamePointerObjectFlag+BecameCompiledMethodFlag). "otherwise why bother?"
	classObj := startClassObj.

	[obj := self fetchPointer: MethodDictionaryIndex ofObject: classObj.
	 self assert: (self isNonImmediate: obj).
	 (self isForwarded: obj) ifTrue:
		[obj := self followForwarded: obj.
		 self storePointer: MethodDictionaryIndex ofObject: classObj withValue: obj].
	 obj2 := self fetchPointer: MethodArrayIndex ofObject: obj.
	 self assert: (self isNonImmediate: obj2).
	 (self isForwarded: obj2) ifTrue:
		[obj2 := self followForwarded: obj2.
		 self storePointer: MethodArrayIndex ofObject: obj withValue: obj2].
	 "Only need to follow pointers in MethodArray if we've became any compiled methods..."
	 (becomeEffects anyMask: BecameCompiledMethodFlag) ifTrue:
		[self followForwardedObjectFields: obj2 toDepth: 0].
	 "But the methodClassAssociations there-in need to be followed if we've done any pointer becomes."
	 (becomeEffects anyMask: BecamePointerObjectFlag) ifTrue:
		[0 to: (self numSlotsOf: obj2) - 1 do:
			[:i|
			obj := self fetchPointer: i ofObject: obj2.
			(self isOopCompiledMethod: obj2) ifTrue:
				[coInterpreter followNecessaryForwardingInMethod: obj2]]].

	 obj := self fetchPointer: SuperclassIndex ofObject: classObj.
	 self assert: (self isNonImmediate: obj).
	 (self isForwarded: obj) ifTrue:
		[obj := self followForwarded: obj.
		 self storePointer: SuperclassIndex ofObject: classObj withValue: obj].

	"If the superclass has an identityHash then either it is nil, or is in the class table.
	 Tail recurse."
	(self rawHashBitsOf: obj) = 0] whileTrue:
		["effectively self scanClassPostBecome: obj"
		 classObj := obj]
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

	self assert: remapBufferCount = 0.
	self assert: (segmentManager numSegments = 0 "true in the spur image bootstrap"
				or: [scavenger eden limit - freeStart > coInterpreter interpreterAllocationReserveBytes]).
	self checkFreeSpace.
	"coInterpreter printCallStackFP: coInterpreter framePointer"

	self runLeakCheckerForFullGC: false.
	coInterpreter
		preGCAction: GCModeScavenge;
		"would prefer this to be in mapInterpreterOops, but
		 compatibility with ObjectMemory dictates it goes here."
		flushMethodCacheFrom: startOfMemory to: newSpaceLimit.
	needGCFlag := false.

	gcStartUsecs := coInterpreter ioUTCMicrosecondsNow.

	self doScavenge: tenuringCriterion.

	statScavenges := statScavenges + 1.
	statGCEndUsecs := coInterpreter ioUTCMicrosecondsNow.
	statSGCDeltaUsecs := statGCEndUsecs - gcStartUsecs.
	statScavengeGCUsecs := statScavengeGCUsecs + statSGCDeltaUsecs.
	statRootTableCount := scavenger rememberedSetSize.

	coInterpreter postGCAction: GCModeScavenge.
	self runLeakCheckerForFullGC: false.

	self checkFreeSpace
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> scheduleScavenge [
	needGCFlag := true.
	coInterpreter forceInterruptCheck
]

{ #category : #'class table puns' }
SpurMemoryManager >> segmentBridgePun [
	^3
]

{ #category : #accessing }
SpurMemoryManager >> segmentManager [
	^segmentManager
]

{ #category : #'spur bootstrap' }
SpurMemoryManager >> setCheckForLeaks: anInteger [
	" 0 = do nothing.
	  1 = check for leaks on fullGC.
	  2 = check for leaks on scavenger.
	  4 = check for leaks on become
	  8 = check for leaks on truly incremental.
	15 = check for leaks on all four."
	checkForLeaks := anInteger
]

{ #category : #'header access' }
SpurMemoryManager >> setClassIndexOf: objOop to: classIndex [
	self subclassResponsibility
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
	 9 (?) 64-bit indexable
	 10 - 11 32-bit indexable
	 12 - 15 16-bit indexable
	 16 - 23 byte indexable
	 24 - 31 compiled method"
	self subclassResponsibility
]

{ #category : #'free space' }
SpurMemoryManager >> setFree: objOop [
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
	self subclassResponsibility
]

{ #category : #snapshot }
SpurMemoryManager >> setHeapBase: heapBase memoryLimit: memLimit endOfMemory: memEnd [
	"Transcript
		cr; nextPutAll: 'heapBase: '; print: heapBase; nextPut: $/; nextPutAll: heapBase hex;
		nextPutAll: ' memLimit '; print: memLimit; nextPut: $/; nextPutAll: memLimit hex;
		nextPutAll: ' memEnd '; print: memEnd; nextPut: $/; nextPutAll: memEnd hex; cr; flush."
	newSpaceLimit := heapBase
					 + self newSpaceBytes
					 + coInterpreter interpreterAllocationReserveBytes.
	freeOldSpaceStart := memEnd.
	endOfMemory := memLimit.
	scavenger
		newSpaceStart: heapBase
		newSpaceBytes: newSpaceLimit - heapBase
		edenBytes: newSpaceLimit - heapBase
				   * (self scavengerDenominator - self numSurvivorSpaces) // self scavengerDenominator.
	freeStart := scavenger eden start.
	pastSpaceStart := scavenger pastSpace start
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

{ #category : #'word size' }
SpurMemoryManager >> shiftForAllocationUnit [
	^3
]

{ #category : #'word size' }
SpurMemoryManager >> shiftForWord [
	^self subclassResponsibility
]

{ #category : #'gc - scavenging' }
SpurMemoryManager >> shouldRemapObj: objOop [
	"Answer if the obj should be scavenged (or simply followed). The method is called
	 shouldRemapObj: for compatibility with ObjectMemory."
	^(self isForwarded: objOop)
	  or: [self isYoung: objOop]
]

{ #category : #'gc - scavenging' }
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

{ #category : #'growing/shrinking memory' }
SpurMemoryManager >> shrinkObjectMemory: delta [ 
	"Attempt to shrink the object memory by the given delta amount."
	self shouldBeImplemented
]

{ #category : #'free space' }
SpurMemoryManager >> shrinkThreshold [
	^shrinkThreshold
]

{ #category : #'free space' }
SpurMemoryManager >> shrinkThreshold: aValue [
	shrinkThreshold := aValue
]

{ #category : #accessing }
SpurMemoryManager >> signalLowSpace [
	^signalLowSpace
]

{ #category : #accessing }
SpurMemoryManager >> signalLowSpace: aValue [
	^signalLowSpace := aValue
]

{ #category : #'header formats' }
SpurMemoryManager >> sixtyFourBitIndexableFormat [
	^9
]

{ #category : #'class table puns' }
SpurMemoryManager >> sixtyFourBitLongsClassIndexPun [
	"Class puns are class indices not used by any class.  There may be
	 an entry for the pun that refers to the notional class of objects with
	 this class index.  But because the index doesn't match the class it
	 won't show up in allInstances, hence hiding the object with a pun as
	 its class index. The puns occupy indices 16 through 31."
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
	"For compatibility with ObjectMemory, answer the size of a free chunk in bytes,
	 ignoring the overflow header.  Do *not* use internally."
	self assert: (self isFreeObject: objOop).
	^self baseHeaderSize + (self wordSize * (self numSlotsOfAny: objOop))
]

{ #category : #'object access' }
SpurMemoryManager >> slotSizeOf: oop [
	"*DO NOT CONFUSE THIS WITH numSlotsOf:.
	 This is an ObjectMemory compatibility method with quesitonable semantics.
	 Answers the number of slots in the receiver.
	 If the receiver is a byte object, return the number of bytes.
	 Otherwise return the number of words."
	(self isImmediate: oop) ifTrue: [^0].
	^self lengthOf: oop
]

{ #category : #'free space' }
SpurMemoryManager >> sortFreeListAt: i [
	"Sort the individual free list i so that the lowest address is at the head of the list.
	 Use an insertion sort with a scan for initially sorted elements."

	| list next head |
	list := freeLists at: i. "list of objects to be inserted"
	list = 0 ifTrue: "empty list; we're done"
		[^self].
	head := list.
	"scan list to find find first out-of-order element"
	[(next := self fetchPointer: self freeChunkNextIndex ofObject: list) > list]
		whileTrue:
			[list := next].
	"no out-of-order elements; list was already sorted; we're done"
	next = 0 ifTrue:
		[^self].
	"detatch already sorted list"
	self storePointer: self freeChunkNextIndex ofFreeChunk: list withValue: 0.
	list := next.
	[list ~= 0] whileTrue:
		[| node prev |
		 "grab next node to be inserted"
		 next := self fetchPointer: self freeChunkNextIndex ofObject: list.
		 "search sorted list for insertion point"
		 prev := 0. "prev node for insertion sort"
		 node := head. "current node for insertion sort"
		 [node ~= 0
		  and: [node < list]] whileTrue:
			[prev := node.
			 node := self fetchPointer: self freeChunkNextIndex ofObject: node].
		 "insert the node into the sorted list"
		 self assert: (node = 0 or: [node > list]).
		 prev = 0
			ifTrue:
				[head := list]
			ifFalse:
				[self storePointer: self freeChunkNextIndex
					ofFreeChunk: prev
					withValue: list].
		 self storePointer: self freeChunkNextIndex
			ofFreeChunk: list
			withValue: node.
		list := next].
	"replace the list with the sorted list"
	freeLists at: i put: head
]

{ #category : #'free space' }
SpurMemoryManager >> sortedFreeObject: objOop [
	self subclassResponsibility
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
	"Simulate heap growth by growing memory by segmentSize + 1Meg.
	 1Meg will be the distance between segments to be bridged."
	| oneMeg newMemory start |
	oneMeg := 1024 * 1024.
	start := memory size * 4 + oneMeg.
	newMemory := memory class new: memory size + (segmentSize + oneMeg / 4).
	newMemory replaceFrom: 1 to: memory size with: memory startingAt: 1.
	memory := newMemory.
	allocSizePtrOrBlock value: segmentSize.
	^start
]

{ #category : #'simulation only' }
SpurMemoryManager >> stObject: objOop at: indexOop put: valueOop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter stObject: objOop at: indexOop put: valueOop
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
	<cmacro: '() memory'>
	<returnTypeC: #usqInt>
	^0
]

{ #category : #simulation }
SpurMemoryManager >> startOfMemory: value [
	startOfMemory := value.
	(freeStart isNil or: [freeStart < value]) ifTrue:
		[freeStart := value]
]

{ #category : #'object enumeration' }
SpurMemoryManager >> startOfObject: objOop [
	"Answer the start of objOop, which is either the address of the overflow size word,
	 or objOop itself, depending on the size of the object.  This may be applied to
	 any kind of object, normal, forwarders or free chunks."
	^(self numSlotsOfAny: objOop) >= self numSlotsMask
		ifTrue: [objOop - self baseHeaderSize]
		ifFalse: [objOop]
]

{ #category : #accessing }
SpurMemoryManager >> statCompMoveCount [
	"Spur never compacts by moving; but it does make compaction passes."
	^statCompactPassCount
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
SpurMemoryManager >> statMkFwdCount [
	^0
]

{ #category : #accessing }
SpurMemoryManager >> statNumGCs [
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
	^statSpecialMarkCount
]

{ #category : #accessing }
SpurMemoryManager >> statSurvivorCount [
	^statSurvivorCount
]

{ #category : #accessing }
SpurMemoryManager >> statSweepCount [
	^0
]

{ #category : #accessing }
SpurMemoryManager >> statTenures [
	<doNotGenerate>
	^scavenger statTenures
]

{ #category : #'object access' }
SpurMemoryManager >> storeByte: byteIndex ofObject: oop withValue: valueByte [
	^self byteAt: oop + self baseHeaderSize + byteIndex put: valueByte
]

{ #category : #'primitive support' }
SpurMemoryManager >> storeImageSegmentInto: segmentWordArray outPointers: outPointerArray roots: arrayOfRoots [
	"This primitive is called from Squeak as...
		<imageSegment> storeSegmentFor: arrayOfRoots into: aWordArray outPointers: anArray."

"This primitive will store a binary image segment (in the same format as the Squeak image file) of the receiver and every object in its proper tree of subParts (ie, that is not refered to from anywhere else outside the tree).  All pointers from within the tree to objects outside the tree will be copied into the array of outpointers.  In their place in the image segment will be an oop equal to the offset in the outPointer array (the first would be 4). but with the high bit set."

"The primitive expects the array and wordArray to be more than adequately long.  In this case it returns normally, and truncates the two arrays to exactly the right size.  To simplify truncation, both incoming arrays are required to be 256 bytes or more long (ie with 3-word headers).  If either array is too small, the primitive will fail, but in no other case.

During operation of the primitive, it is necessary to convert from both internal and external oops to their mapped values.  To make this fast, the headers of the original objects in question are replaced by the mapped values (and this is noted by adding the forbidden XX header type).  Tables are kept of both kinds of oops, as well as of the original headers for restoration.

To be specific, there are two similar two-part tables, the outpointer array, and one in the upper fifth of the segmentWordArray.  Each grows oops from the bottom up, and preserved headers from halfway up.

In case of either success or failure, the headers must be restored.  In the event of primitive failure, the table of outpointers must also be nilled out (since the garbage in the high half will not have been discarded."

	^PrimErrUnsupported
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

{ #category : #'heap management' }
SpurMemoryManager >> storePointer: fieldIndex ofForwarder: objOop withValue: valuePointer [

	self assert: (self isForwarded: objOop).
	self assert: (self isOopForwarded: valuePointer) not.

	(self isYoung: objOop) ifFalse: "most stores into young objects"
		[((self isNonImmediate: valuePointer) and: [self isYoung: valuePointer]) ifTrue:
			[self possibleRootStoreInto: objOop]].

	^self
		longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'heap management' }
SpurMemoryManager >> storePointer: fieldIndex ofFreeChunk: objOop withValue: valuePointer [

	self assert: (self isFreeObject: objOop).
	self assert: (valuePointer = 0 or: [self isFreeObject: objOop]).

	^self
		longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'object access' }
SpurMemoryManager >> storePointer: fieldIndex ofObjStack: objOop withValue: valuePointer [
	self assert: (self formatOf: objOop) = self wordIndexableFormat.
	^self
		longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'object access' }
SpurMemoryManager >> storePointer: fieldIndex ofObject: objOop withValue: valuePointer [
	"Note must check here for stores of young objects into old ones."
	self assert: (self isForwarded: objOop) not.

	(self isYoung: objOop) ifFalse: "most stores into young objects"
		[(self isImmediate: valuePointer) ifFalse:
			[(self isYoung: valuePointer) ifTrue:
				[self possibleRootStoreInto: objOop]]].

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
	self assert: (self isForwarded: objOop) not.
	^self
		longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
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

	self assert: numBytes = 0.
	self scavengingGCTenuringIf: TenureByAge.
	lowSpaceThreshold > totalFreeOldSpace ifTrue: "space is low"
		[lowSpaceThreshold := 0. "avoid signalling low space twice"
		 ^false].
	^true
]

{ #category : #allocation }
SpurMemoryManager >> sufficientSpaceToInstantiate: classObj indexableSize: indexableFields [
	self shouldNotImplement
]

{ #category : #snapshot }
SpurMemoryManager >> swizzleFieldsOfFreeChunk: chunk [
	<inline: true>
	0 to: ((self bytesInObject: chunk) / self allocationUnit > self numFreeLists
			ifTrue: [self freeChunkLargerIndex]
			ifFalse: [self freeChunkNextIndex])
	   do: [:index| | field |
		field := self fetchPointer: index ofFreeChunk: chunk.
		field ~= 0 ifTrue:
			[self storePointer: index
				ofFreeChunk: chunk
				withValue: (segmentManager swizzleObj: field)]]
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
		 fieldAddr := fieldAddr - BytesPerOop]
]

{ #category : #'obj stacks' }
SpurMemoryManager >> swizzleObjStackAt: objStackRootIndex [
	"On load, swizzle the pointers in an obj stack. Answer the obj stack's oop."
	| firstPage stackOrNil index field |
	firstPage := stackOrNil := self fetchPointer: objStackRootIndex ofObject: hiddenRootsObj.
	stackOrNil = nilObj ifTrue:
		[^stackOrNil].
	[self assert: (self numSlotsOfAny: stackOrNil) = ObjStackPageSlots.
	 self assert: (self fetchPointer: ObjStackMyx ofObject: stackOrNil) = objStackRootIndex.
	 "There are four fixed slots in an obj stack, and a Topx of 0 indicates empty, so
	   if there were 5 slots in an oop stack, full would be 2, and the last 0-rel index is 4.
	   Hence the last index is topx + fixed slots - 1, or topx + ObjStackNextx"
	 index := (self fetchPointer: ObjStackTopx ofObject: stackOrNil) + ObjStackNextx.
	 "swizzle fields including ObjStackNextx and leave field containing the next link."
	 [field := self fetchPointer: index ofObject: stackOrNil.
	  (self isImmediate: field) ifFalse:
		[field := segmentManager swizzleObj: field.
		 self storePointer: ObjStackNextx ofObjStack: stackOrNil withValue: field].
	  (index := index - 1) > ObjStackTopx] whileTrue.
	 (stackOrNil := field) ~= 0] whileTrue.
	[stackOrNil := self fetchPointer: ObjStackFreex ofObject: firstPage.
	 stackOrNil ~= 0] whileTrue:
		[field := segmentManager swizzleObj: stackOrNil.
		 self storePointer: ObjStackFreex ofObjStack: firstPage withValue: field.
		 firstPage := stackOrNil].
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
	 threshold is an object count. Marry the two notions  by multiplying the proportion by
	 the size of pastSpace and dividing by the average object size, as derived from observation."
	| averageObjectSize |
	averageObjectSize := 8 * self wordSize.
	^scavenger scavengerTenuringThreshold * scavenger pastSpaceBytes // averageObjectSize
]

{ #category : #accessing }
SpurMemoryManager >> tenuringThreshold: threshold [
	"c.f. tenuringThreshold"
	scavenger scavengerTenuringThreshold:
		(threshold * 8 * self wordSize) asFloat
		/ scavenger pastSpaceBytes asFloat
]

{ #category : #'class table puns' }
SpurMemoryManager >> thirtyTwoBitLongsClassIndexPun [
	"Class puns are class indices not used by any class.  There may be
	 an entry for the pun that refers to the notional class of objects with
	 this class index.  But because the index doesn't match the class it
	 won't show up in allInstances, hence hiding the object with a pun as
	 its class index. The puns occupy indices 16 through 31."
	^18
]

{ #category : #'obj stacks' }
SpurMemoryManager >> topOfObjStack: objStack [
	| topx |
	"This assert is tricky.  push:onObjStack: may call topOfObjStack: just after pushing an
	 empty page on the stack, and will ask if the second page is valid."
	self assert: (self isValidObjStackPage: objStack
					myIndex: (self fetchPointer: ObjStackMyx ofObject: objStack)
					firstPage: (objStack = (self fetchPointer: (self fetchPointer: ObjStackMyx ofObject: objStack) ofObject: hiddenRootsObj))).
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

{ #category : #'free space' }
SpurMemoryManager >> totalFreeListBytes [
	| totalFreeBytes bytesInChunk listNode |
	totalFreeBytes := 0.
	1 to: self numFreeLists - 1 do:
		[:i| 
		bytesInChunk := i * self allocationUnit.
		listNode := freeLists at: i.
		[listNode ~= 0] whileTrue:
			[totalFreeBytes := totalFreeBytes + bytesInChunk.
			 self assert: (self isValidFreeObject: listNode).
			 self assert: bytesInChunk = (self bytesInObject: listNode).
			 listNode := self fetchPointer: self freeChunkNextIndex ofFreeChunk: listNode]].

	self freeTreeNodesDo:
		[:treeNode|
		 bytesInChunk := self bytesInObject: treeNode.
		 self assert: bytesInChunk / self allocationUnit >= self numFreeLists.
		 listNode := treeNode.
		 [listNode ~= 0] whileTrue:
			["self printFreeChunk: listNode"
			 self assert: (self isValidFreeObject: listNode).
			 totalFreeBytes := totalFreeBytes + bytesInChunk.
			 self assert: bytesInChunk = (self bytesInObject: listNode).
			 listNode := self fetchPointer: self freeChunkNextIndex ofFreeChunk: listNode].
		 treeNode].
	^totalFreeBytes
]

{ #category : #accessing }
SpurMemoryManager >> totalMemorySize [
	^scavenger newSpaceCapacity + segmentManager totalBytesInSegments
]

{ #category : #'gc - global' }
SpurMemoryManager >> traceImmediatelySlotLimit [
	"Arbitrary level at which to defer tracing large objects until later.
	 The average slot size of Smalltalk objects is typically near 8."
	^16
]

{ #category : #'simulation only' }
SpurMemoryManager >> transcript [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter transcript
]

{ #category : #accessing }
SpurMemoryManager >> trueObject [
	^trueObj
]

{ #category : #accessing }
SpurMemoryManager >> trueObject: anOop [
	"For mapInterpreterOops"
	trueObj := anOop
]

{ #category : #'free space' }
SpurMemoryManager >> unlinkFreeChunk: chunk atIndex: index [
	"Unlink and answer a small chunk from one of the fixed size freeLists"
	<inline: true>
	self assert: ((self bytesInObject: chunk) = (index * self allocationUnit)
				and: [index > 1 "a.k.a. (self bytesInObject: chunk) > self allocationUnit"
				and: [(self startOfObject: chunk) = chunk]]).
	freeLists
		at: index
		put: (self
				fetchPointer: self freeChunkNextIndex
				ofFreeChunk: chunk).
	^chunk
]

{ #category : #'free space' }
SpurMemoryManager >> unlinkFreeTreeNode: freeTreeNode withSiblings: next [
	"Unlink a freeTreeNode.  Assumes the node has a list (non-null next link)."
	| parent smaller larger |
	parent := self fetchPointer: self freeChunkParentIndex ofObject: freeTreeNode.
	smaller := self fetchPointer: self freeChunkSmallerIndex ofObject: freeTreeNode.
	larger := self fetchPointer: self freeChunkLargerIndex ofObject: freeTreeNode.
	self storePointer: self freeChunkPrevIndex ofFreeChunk: next withValue: 0.
	parent = 0
		ifTrue: [freeLists at: 0 put: next]
		ifFalse:
			[self storePointer: (freeTreeNode = (self fetchPointer: self freeChunkSmallerIndex
												ofObject: parent)
									ifTrue: [self freeChunkSmallerIndex]
									ifFalse: [self freeChunkLargerIndex])
				ofFreeChunk: parent
				withValue: next].
	self storePointer: self freeChunkSmallerIndex ofFreeChunk: next withValue: smaller.
	smaller ~= 0 ifTrue:
		[self storePointer: self freeChunkParentIndex ofFreeChunk: smaller withValue: next].
	self storePointer: self freeChunkLargerIndex ofFreeChunk: next withValue: larger.
	larger ~= 0 ifTrue:
		[self storePointer: self freeChunkParentIndex ofFreeChunk: larger withValue: next]
]

{ #category : #'free space' }
SpurMemoryManager >> unlinkSolitaryFreeTreeNode: freeTreeNode [
	"Unlink a freeTreeNode.  Assumes the node has no list (null next link)."
	| parent smaller larger |
	self assert: (self fetchPointer: self freeChunkNextIndex ofObject: freeTreeNode) = 0.

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
					[self storePointer: self freeChunkParentIndex ofFreeChunk: larger withValue: 0.
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

{ #category : #'obj stacks' }
SpurMemoryManager >> updateRootOfObjStack: objStackRootIndex with: newRootPage [
	self storePointer: objStackRootIndex
		ofObject: hiddenRootsObj
		withValue: newRootPage.
	objStackRootIndex caseOf: {
		[MarkStackRootIndex]			->	[markStack := newRootPage].
		[WeaklingStackRootIndex]		->	[weaklingStack := newRootPage].
		[EphemeronQueueRootIndex]	->	[ephemeronQueue := newRootPage] }.
	self assert: (self isValidObjStack: newRootPage).
	^newRootPage
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
	^17
]

{ #category : #'header formats' }
SpurMemoryManager >> weakArrayFormat [
	<api>
	^4
]

{ #category : #'header formats' }
SpurMemoryManager >> wordIndexableFormat [
	"Either firstLongFormat or sixtyFourBitIndexableFormat"
	^self subclassResponsibility
]

{ #category : #'word size' }
SpurMemoryManager >> wordSize [
	"Answer the manager's word size, whjich is the size of an oop, and which
	 is assumed to be equivslent to the underlying machine's word size."
	^self subclassResponsibility
]

{ #category : #'class table puns' }
SpurMemoryManager >> wordSizeClassIndexPun [
	^self subclassResponsibility
]
