"
SpurMemoryManager is a new object representation and garbage collector for the Cog VM's.  Spur is dedicated to Andreas Raab, friend and colleague.  I miss you, Andreas.  The goal for Spur is an overall improvement in Cog of -50% (twice as fast) for memory-intensive benchmarks.  

An intensive design sketch is included below after the instance variable descriptions.

Instance Variables
	checkForLeaks:				<Boolean>
	classTableFirstPage:		<Integer oop>
	classTableIndex:			<Integer>
	classTableRootObj:			<Integer oop>
	coInterpreter:				<StackInterpreter|CoInterpreter>
	endOfMemory:				<Integer address>
	falseObj:					<Integer oop>
	freeListMask:				<Integer (64-bit)>
	freeLists:					<CArrayAccessor on: (Array new: 64)>
	freeOldSpaceStart:			<Integer address>
	freeStart:					<Integer address>
	heapMap:					<CogCheck32BitHeapMap>
	lastHash:					<Integer>
	memory:					<Bitmap|LittleEndianBitmap>
	needGCFlag:				<Boolean>
	newSpaceLimit:				<Integer address>
	nilObj:						<Integer oop>
	scavengeThreshold:		<Integer address>
	scavenger:					<SourGenerationScavenger>
	signalLowSpace:			<Boolean>
	specialObjectsOop:		<Integer oop>
	startOfMemory:				<Integer address>
	trueObj:					<Integer oop>

checkForLeaks
	- a set of flags determining when to run leak checks on the heap's contents

classTableFirstPage
	- the first page of the class table which contains all classes known to the VM at known indices

classTableIndex
	- the last known used index in the class table, used to limit the search for empty slots

classTableRootObj
	- the root page of the class table. its elements are pages containing classes.

coInterpreter
	- the VM interpreter using this heap

endOfMemory
	- the address past the last oldSpace segment

falseObj
	- the oop of the false object

freeListMask
	- a bitmap of flags with a 1 set whereever the freeLists has a non-empty entry, used to limit the search for free chunks

freeLists
	- an array of list heads of free chunks of each size (in allocationUnits).  the 0'th element is the head of a tree of free chunks of size > 63 slots.

freeOldSpaceStart
	- the last used address in oldSpace.  The space between freeOldSpaceStart and endOfMemory can be used for oldSpace allocations.

freeStart
	- the last used address in eden.  this is where new objects are allocated if there is room in eden.

heapMap
	- a bitmap used to check for leaks. a bit is set in the map at each object's header.  every pointer in the heap should point to the header of an object

lastHash
	- the last object hash value.  a pseudo-randome number generator.

memory
	- in the Simulator this is the single oldSpace segment that contains the codeZone, newSpace and oldSpace.  In C it is effectively the base address of used memory.

needGCFlag
	- a boolean flag set if a scavenge is needed

newSpaceLimit
	- the last address in newSpace (the last address in eden)

nilObj
	- the oop of the nil object

scavengeThreshold
	- a tidemark in eden. needGCFlag is set if a newSpace allocation pushes freeStart past scavengethreshold

scavenger
	- the generation scavenger that collects objects in newSpace

signalLowSpace
	- a boolean flag set if the lowSpaceSemaphore should be signalled

specialObjectsOop
	- the oop of the specialObjectsArray object

startOfMemory
	- the first address in newSpace (the first address in either pastSpace or futureSpace)

trueObj
	- the oop of the false object

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
We shall probably keep the minimum object size at 16 bytes so that there is always room for a forwarding pointer.  But this implies that we will need to implement an 8-byte filler to fill holes between objects > 16 bytes whose length mod 16 bytes is 8 bytes and following pinned objects.  We can do this using a special class index, e.g. 1, so that the method that answers the size of an object looks like, e.g.
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

Note that the size field of an object (its slot size) reflects the logical size of the object e.g. 0-element array => 0 slot size, 1-element array => 1 slot size). The memory manager rounds up the slot size as appropriate, e.g. (sef roundUp: (self slotSizeOf: obj) * 4 to: 8) min: 8.

Heap growth and shrinkage will be handled by allocating and deallocating heap segments from/to the OS via e.g. memory-mapping.  This technique allows space to be released back to the OS by unmapping empty segments.  See ""Segmented Old Space"" below).

The basic approach is to use a fixed size new space and a growable old space.  The new space is a classic three-space nursery a la Ungar's Generation Scavenging, a large eden for new objects and two smaller survivor spaces that exchange roles on each collection, one being the to space to which surviving objects are copied, the other being the from space of the survivors of the previous collection, i.e. the previous to space.  (This basic algorithm must be extended for weak arrays and ephemerons).

To provide apparent pinning in new space we rely on lazy become.  Since most pinned objects will be byte data and these do not require stack zone activation scanning, the overhead is simply an old space allocation and corpsing.

To provide pinning in old space, large objects are implicitly pinned (because it is expensive to move large objects and, because they are both large and relatively rare, they contribute little to overall fragmentation - as in aggregates, small objects can be used to fill-in the spaces between karge objects).  Hence, objects above a particular size are automatically allocated in old space, rather than new space.  Small objects are pinned as per objects in new space, by asserting the pin bit, which will be set automaticaly when allocating a large object.  As a last resort, or by programmer control (the fullGC primitive) old space is collected via mark-sweep (mark-compact) and so the mark phase must build the list of pinned objects around which the sweep/compact phase must carefully step.

Free space in old space is organized by a free list/free tree as in Eliot's VisualWorks 5i old space allocator.  There are 64 free lists, indices 1 through 63 holding blocks of space of that size, index 0 holding a semi-balanced ordered tree of free blocks, each node being the head of the list of free blocks of that size.  At the start of the mark phase the free list is thrown away and the sweep phase coallesces free space and steps over pinned objects as it proceeds.  We can reuse the forwarding pointer compaction scheme used in the old collector.  Incremental collections merely move unmarked objects to the free lists (as well as nilling weak pointers in weak arrays and scheduling them for finalization).  The occupancy of the free lists is represented by a bitmap in a 64-bit integer so that an allocation of size 63 or less can know whether there exists a free chunk of that size, but more importantly can know whether a free chunk larger than it exists in the fixed size free lists without having to search all larger free list heads.

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
In heap walking the memory manager needs to be able to detect the start of the next object.  This is complicated by the short and long header formats, short being for objects with 254 slots or less, long being for objects with 255 slots or more.  The class index field can be used to mark special objects.  In particular the tagged class indices 1 through 7, which correspond to objects with tag bits 1 through 7 (SmallInteger = 1, 3, 5, 7, Character = e.g. 2, and SmallFloat = e.g. 4) never occur in the class index fields of normal objects.  So if the size doubleword uses all bits other than the class field (44 bits is an adequate maximum size of 2^46 bytes, ~ 10^14 bytes) then size doubleword s can be marked by using one of the tag class indexes in its class field.  To identify the next object the VM fetches the doubleword immediately following the current object (object bodies being rounded up to 8 bytes in the 32-bit VM).  If the doubleword's class index field is the size doubleword class index pun, e.g. 1, then it is a size field and the object header is the doubleword following that, and the object's slots start after that.  if not, the object header is that doubleword and the object's slots follow that.

Total Number of Classes and Instance-specific Behaviours
While the class index header field has advantages (saving significant header space, especially in 64-bits, providing a non-moving cache tag for inline caches, small constants for instantiating well-known classes instead of having to fetch them from a table such as the specialObjectsArray) it has the downside of limiting the number of classes.  For Smalltalk programs 2^20 to 2^24 classes is adequate for some time to come, but for prototype languages such as JavaScript this is clearly inadequate, and we woud like to support the ability to host prototype languages within Squeak. There is a solution in the form of ""auto-instances"", an idea of Claus Gittinger's.  The idea is to represent prototypes as behaviors that are instances of themselves.  In a classical Smalltalk system a Behavior is an object with the minimal amount of state to function as a class, and in Smalltalk-80 this state is the three instance variables of Behavior, superclass, methodDict and format, which are the only fields in a Behavior that are known to the virtual machine.  A prototype can therefore have its own behavior and inherit from other prototypes or classes, and have sub-prototypes derived from it if a) its first three instance variables are also superclass, methodDict, and format, and b) it is an instance of itself (one can create such objects in a normal Smalltalk system by creating an Array with the desired layout and using a change class primitive to change the class of the Array to itself).  The same effect can be achieved in a VM with class indexes by reserving one class index to indicate that the object is an instance of itself, hence not requiring the object be entered into the class table and in the code that derives the class of an object, requiring one simple test answering the object itself instead of indexing the class table.  There would probably need to be an auto-instantiation primitive that takes a behavior (or prototype) and an instance variable count and answers a new auto-instance with as many instance variables as the sum of the behavior (or prototype) and the instance variable count.  Using this scheme there can be as many auto-instances as available address space allows while retaining the benefits of class indices.

This scheme has obvious implications for the inline cache since all prototypes end up having the same inline cache tag.  Either the inline cache check checks for the auto-instance class tag and substitutes the receiver, or the cacheing machinery refuses to add the auto-instance class tag to any inline cache and failure path code checks for the special case.  Note that in V8 failing monomorphic sends are patched to open PICs (megamorphic sends); V8 does not use closed PICs due to the rationale that polymorphism is high in JavaScript.

Miscellanea
One obvious optimization to images is to add image (de)compression to image loading and snapshot.  The image header remains unchanged but its contents could be compressed, compressing either on snapshot, if requested, or off-line via a special-purpose tool.

Issues:
In-line cache probe for immediates
We would like to keep 31-bit SmallIntegers for the 32-bit system.  Lots of code could be impacted by a change to 30-bit SmallIntegers.  If so, then 
	isImmediate: oop	^(oop bitAnd: 3) ~= 0
	isSmallInteger: oop	^(oop bitAnd: 1) ~= 0
	isCharacter: oop	^(oop bitAnd: 2) = 2
If the in-line cache contains 0 for Characters then the in-line cache code (in x86 machine code) could read
	Lentry:
		movl %edx, %eax	# copy receiver to temp
		andl $0x3, %eax	# test for immediate receiver
		jz Lnon-imm
		andl $0x1, %eax	# map immediate receiver to cache tag, SmallInteger => 1, Character => 0
		j Lcmp
	Lnon-imm:
		movl 0x4(%edx), %eax # move header word containing class index to %eax
		andl $0xfffff, %eax		# mask off class index (shift may be faster and/or shorter)
	Lcmp:
		cmpl %ecx, %eax		# compact in-line cache to receiver's cache tag
		jnz Lmiss
or, for a branch-free common-case,
	Limm:
		andl $0x1, %eax
		j Lcmp
	Lentry:
		movl %edx, %eax
		andl $0x3, %eax
		jnz Limm
		movl 0x4(%edx), %eax
		andl $0xfffff, %eax
	Lcmp:
		cmpl %ecx, %eax
		jnz Lmiss

64-Bit sizes:
How do we avoid the Size4Bit for 64-bits?  The format word encodes the number of odd bytes, but currently has only 4 bits and hence only supports odd bytes of 0 - 3.  We need odd bytes of 0 - 7.  But I don't like the separate Size4Bit.  Best to change the VI code and have a 5 bit format?  We lose one bit but save two bits (isEphemeron and isWeak (or three, if isPointers)) for a net gain of one (or two)

Further, keep Squeak's format idea or go for separate bits?  For 64-bits we need a 5 bit format field.  This contrasts with isPointers, isWeak, isEphemeron, 3 odd size bits (or byte size)..  format field is quite economical.

Hence I think format needs to be made a 5 bit field with room for 4 bits of odd bytes for 64-bit images.  So then

0 = 0 sized objects (UndefinedObject True False et al)
1 = non-indexable objects with inst vars (Point et al)
2 = indexable objects with no inst vars (Array et al)
3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
4 = weak indexable objects with inst vars (WeakArray et al)
5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)

and here it gets messy, we need 8 CompiledMethod values, 8 byte values, 4 16-bit values, 2 32-bit values and a 64-bit value, = 23 values, 23 + 5 = 30, so there may be room.

9 (?) 64-bit indexable
10 - 11 32-bit indexable
12 - 15 16-bit indexable
16 - 23 byte indexable
24 - 31 compiled method

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
		'memory',
		'freeStart',
		'freeOldSpaceStart',
		'scavengeThreshold',
		'newSpaceLimit',
		'nilObj',
		'falseObj',
		'trueObj',
		'specialObjectsOop',
		'classTableRootObj',
		'classTableFirstPage',
		'classTableIndex',
		'startOfMemory',
		'endOfMemory',
		'freeLists',
		'freeListsMask',
		'lastHash',
		'signalLowSpace',
		'checkForLeaks',
		'needGCFlag',
		'heapMap',
		'becomeEffectsFlags',
		'pastSpaceStart',
		'gcStartUsecs',
		'statScavenges',
		'statGCEndUsecs',
		'statIGCDeltaUsecs',
		'statIncrGCUsecs',
		'statScavengeGCUsecs',
		'statFullGCUsecs',
		'statSGCDeltaUsecs',
		'statFGCDeltaUsecs',
		'scavengeInProgress',
		'statIncrGCs',
		'statFullGCs',
		'remapBuffer',
		'remapBufferCount',
		'lowSpaceThreshold',
		'totalFreeOldSpace',
		'sortedFreeChunks'
	],
	#classVars : [
		'CheckObjectOverwrite',
		'FirstValidClassIndex',
		'RemapBufferSize'
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

{ #category : #accessing }
SpurMemoryManager class >> baseHeaderSize [
	"For CogBlockMethod class>>instVarNamesAndTypesForTranslationDo:"
	^8
]

{ #category : #initialization }
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
	"CogObjectMemory initialize"
	CheckObjectOverwrite := true.

	"The remap buffer support is for compatibility; Spur doesn't GC during allocation.
	 Eventually this should die."
	RemapBufferSize := 25
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

{ #category : #initialization }
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
	"PrimErrTableIndex := 51. in Interpreter class>>initializePrimitiveErrorCodes"
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
	BecameClassFlag := 1.
	BecameCompiledMethodFlag := 2.
	BecamePointerObjectFlag := 4
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initializeWithOptions: optionsDictionary [
	"SpurMemoryManager initializeWithOptions: Dictionary new"

	super initializeWithOptions: optionsDictionary.
	self initBytesPerWord: (self == SpurMemoryManager
								ifTrue: [optionsDictionary at: #BytesPerWord ifAbsent: [4]]
								ifFalse: [self wordSize]).
	BytesPerOop := optionsDictionary at: #BytesPerOop ifAbsent: [BytesPerWord].

	self initializeSpurObjectRepresentationConstants.
	self initializeSpecialObjectIndices.
	self initializeCompactClassIndices.
	self initializePrimitiveErrorCodes.
	self initializeObjectHeaderConstants.

	SpurGenerationScavenger initialize
]

{ #category : #accessing }
SpurMemoryManager class >> objectRepresentationClass [
	^self subclassResponsibility
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

{ #category : #'free space' }
SpurMemoryManager >> addToFreeList: freeChunk bytes: chunkBytes [
	| childBytes parent child index |
	"coInterpreter transcript ensureCr. coInterpreter print: 'freeing '. self printFreeChunk: freeChunk."
	self assert: (self isFreeObject: freeChunk).
	self assert: chunkBytes = (self bytesInObject: freeChunk).
	index := chunkBytes / self allocationUnit.
	index < self numFreeLists ifTrue:
		[self storePointer: self freeChunkNextIndex ofFreeChunk: freeChunk withValue: (freeLists at: index).
		 freeLists at: index put: freeChunk.
		 freeListsMask := freeListsMask bitOr: 1 << index.
		 ^self].
	freeListsMask := freeListsMask bitOr: 1.
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
			 ^self].
		 "walk down the tree"
		 parent := child.
		 child := self fetchPointer: (childBytes > chunkBytes
										ifTrue: [self freeChunkSmallerIndex]
										ifFalse: [self freeChunkLargerIndex])
					ofObject: child].
	parent = 0 ifTrue:
		[self assert: (freeLists at: 0) = 0.
		 freeLists at: 0 put: freeChunk.
		 ^self].
	"insert in tree"
	self storePointer: self freeChunkParentIndex
			ofFreeChunk: freeChunk
				withValue: parent.
	 self storePointer: (childBytes > chunkBytes
									ifTrue: [self freeChunkSmallerIndex]
									ifFalse: [self freeChunkLargerIndex])
			ofFreeChunk: parent
				withValue: freeChunk
]

{ #category : #'object enumeration' }
SpurMemoryManager >> addressAfter: objOop [
	"Answer the address immediately following an object."
	^self subclassResponsibility
]

{ #category : #'debug support' }
SpurMemoryManager >> addressCouldBeObj: address [
	<api>
	self flag: #temporary. "include futureSpace for now (while debugging the scavenger)"
	^(address bitAnd: self baseHeaderSize - 1) = 0
	  and: [(self isInOldSpace: address)
		or: (self isInEden: address)
		or: [(self isInSurvivorSpace: address)
		or: [scavengeInProgress and: [self isInFutureSpace: address]]]]
]

{ #category : #'debug support' }
SpurMemoryManager >> addressCouldBeOop: address [ 
	^(self isImmediate: address)
	  or: [self addressCouldBeObj: address]
]

{ #category : #initialization }
SpurMemoryManager >> adjustAllOopsBy: bytesToShift [ 
	"Adjust all oop references by the given number of bytes. This 
	is done just after reading in an image when the new base 
	address of the object heap is different from the base address 
	in the image."

	| obj |
	<inline: false>
	bytesToShift ~= 0 ifTrue:
		[self assert: self newSpaceIsEmpty.
		 obj := self firstObject.
		 [self oop: obj isLessThan: freeOldSpaceStart] whileTrue:
			[(self isFreeObject: obj) ifFalse:
				[self adjustFieldsAndClassOf: obj by: bytesToShift].
			 obj := self objectAfter: obj]]
]

{ #category : #initialization }
SpurMemoryManager >> adjustFieldsAndClassOf: oop by: offsetBytes [ 
	"Adjust all pointers in this object by the given offset."
	| fieldAddr fieldOop |
	<inline: true>
	<asmLabel: false>
	fieldAddr := oop + (self lastPointerOf: oop).
	[self oop: fieldAddr isGreaterThanOrEqualTo: oop + self baseHeaderSize] whileTrue:
		[fieldOop := self longAt: fieldAddr.
		 (self isNonImmediate: fieldOop) ifTrue:
			[self longAt: fieldAddr put: fieldOop + offsetBytes].
		 fieldAddr := fieldAddr - BytesPerOop]
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
	prevPrevObj class.
	prevObj class
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
	prevPrevObj class.
	prevObj class
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
	self allObjectsInFreeTree: (freeLists at: 0) do: aBlock
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
	prevPrevObj class.
	prevObj class
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
	prevPrevObj class.
	prevObj class
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
	prevPrevObj class.
	prevObj class
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
	prevPrevObj class.
	prevObj class
]

{ #category : #simulation }
SpurMemoryManager >> allocateMemoryOfSize: memoryBytes newSpaceSize: newSpaceBytes stackSize: stackBytes codeSize: codeBytes [
	"Intialize the receiver for bootsraping an image.
	 Set up a large oldSpace and an empty newSpace and set-up freeStart and scavengeThreshold
	 to allocate in oldSpace.  Later on (in initializePostBootstrap) freeStart and scavengeThreshold
	 will be set to sane values."
	<doNotGenerate>
	self assert: (memoryBytes \\ self allocationUnit = 0
				and: [newSpaceBytes \\ self allocationUnit = 0
				and: [codeBytes \\ self allocationUnit = 0]]).
	memory := (self endianness == #little
					ifTrue: [LittleEndianBitmap]
					ifFalse: [Bitmap]) new: (memoryBytes + newSpaceBytes + codeBytes + stackBytes) // 4.
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
					edenBytes: newSpaceBytes * 5 // 7 "David's paper uses 140Kb eden + 2 x 28kb survivor spaces :-)"
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
	| initialIndex chunk index nodeBytes parent child smaller larger |
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
			[((freeListsMask anyMask: 1 << index)
			 and: [(chunk := freeLists at: index) ~= 0]) ifTrue:
				[self assert: chunk = (self startOfObject: chunk).
				 self assert: (self isValidFreeObject: chunk).
				 self unlinkFreeChunk: chunk atIndex: index.
				 self assert: (self bytesInObject: chunk) = (index * self allocationUnit).
				 self freeChunkWithBytes: index * self allocationUnit - chunkBytes
					at: (self startOfObject: chunk) + chunkBytes.
				^chunk]].
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
		 self halt.
		 ^nil].

	"self printFreeChunk: parent"
	self assert: (nodeBytes = chunkBytes or: [nodeBytes >= (chunkBytes + (2 * self allocationUnit))]).
	self assert: (self bytesInObject: parent) = nodeBytes.

	"attempt to remove from list"
	chunk := self fetchPointer: self freeChunkNextIndex
					ofFreeChunk: parent.
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

	"no list; remove an interior node; reorder tree simply.  two cases (which have mirrors, for four total):
	 case 1. interior node has one child, P = parent, N = node, S = subtree (mirrored for large vs small)
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

	chunk := parent.
	smaller := self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: chunk.
	larger := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: chunk.
	parent := self fetchPointer: self freeChunkParentIndex ofFreeChunk: chunk.
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
				ifTrue: [self storePointer: (chunk = (self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: parent)
											ifTrue: [self freeChunkSmallerIndex]
											ifFalse: [self freeChunkLargerIndex])
							ofFreeChunk: parent
							withValue: larger.
						self storePointer: self freeChunkParentIndex
							ofObject: larger
							withValue: parent]
				ifFalse:
					[self storePointer: (chunk = (self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: parent)
											ifTrue: [self freeChunkSmallerIndex]
											ifFalse: [self freeChunkLargerIndex])
						ofFreeChunk: parent
						withValue: smaller.
					 self storePointer: self freeChunkParentIndex
						ofObject: smaller
						withValue: parent.
					 larger ~= 0 ifTrue:
						[self addFreeSubTree: larger]]].
	"if there's space left over, add the fragment back."
	chunkBytes ~= nodeBytes ifTrue:
		[self freeChunkWithBytes: nodeBytes - chunkBytes
				at: (self startOfObject: chunk) + chunkBytes].
	^self startOfObject: chunk
]

{ #category : #'free space' }
SpurMemoryManager >> allocateOldSpaceChunkOfExactlyBytes: chunkBytes [
	"Answer a chunk of oldSpace from the free lists, if one of this size
	 is available, otherwise answer nil.  N.B.  the chunk is simply a pointer,
	 it has no valid header.  The caller *must* fill in the header correctly."
	| initialIndex chunk nodeBytes parent child smaller larger |
	"for debugging:" "totalFreeOldSpace := self totalFreeListBytes"

	initialIndex := chunkBytes / self allocationUnit.
	initialIndex < self numFreeLists ifTrue:
		[(1 << initialIndex <= freeListsMask
		 and: [(chunk := freeLists at: initialIndex) ~= 0]) ifTrue:
			[self assert: chunk = (self startOfObject: chunk).
			 self assert: (self isValidFreeObject: chunk).
			totalFreeOldSpace := totalFreeOldSpace - chunkBytes.
			^self unlinkFreeChunk: chunk atIndex: initialIndex].
		 ^nil].

	"Large chunk.  Search the large chunk list.
	 Large chunk list organized as a tree, each node of which is a list of
	 chunks of the same size. Beneath the node are smaller and larger
	 blocks.  When the search ends parent should hold the first chunk of
	 the same size as chunkBytes, or 0 if none."
	parent := chunk := 0.
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
					 totalFreeOldSpace := totalFreeOldSpace - chunkBytes.
					 ^self startOfObject: chunk].
				 child := 0] "break out of loop to remove interior node"
			ifFalse:
				[childBytes < chunkBytes
					ifTrue: "walk down the tree"
						[child := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: child]
					ifFalse:
						[parent := child.
						 nodeBytes := childBytes.
						 child := self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: child]]].
	"if no chunk, there was no exact fit"
	chunk = 0 ifTrue:
		[^nil].

	"self printFreeChunk: parent"
	self assert: nodeBytes = chunkBytes.
	self assert: (self bytesInObject: parent) = chunkBytes.

	"can't be a list; would have removed and returned it above."
	self assert: (self fetchPointer: self freeChunkNextIndex ofFreeChunk: parent) = 0.

	"no list; remove an interior node; reorder tree simply.  two cases (which have mirrors, for four total):
	 case 1. interior node has one child, P = parent, N = node, S = subtree (mirrored for large vs small)
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

	chunk := parent.
	smaller := self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: chunk.
	larger := self fetchPointer: self freeChunkLargerIndex ofFreeChunk: chunk.
	parent := self fetchPointer: self freeChunkParentIndex ofFreeChunk: chunk.
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
				ifTrue: [self storePointer: (chunk = (self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: parent)
											ifTrue: [self freeChunkSmallerIndex]
											ifFalse: [self freeChunkLargerIndex])
							ofFreeChunk: parent
							withValue: larger.
						self storePointer: self freeChunkParentIndex
							ofObject: larger
							withValue: parent]
				ifFalse:
					[self storePointer: (chunk = (self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: parent)
											ifTrue: [self freeChunkSmallerIndex]
											ifFalse: [self freeChunkLargerIndex])
						ofFreeChunk: parent
						withValue: smaller.
					 self storePointer: self freeChunkParentIndex
						ofObject: smaller
						withValue: parent.
					 larger ~= 0 ifTrue:
						[self addFreeSubTree: larger]]].
	^self startOfObject: chunk
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

{ #category : #'class table' }
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
	^2
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
			[self innerBecomeObjectsIn: array1 with: array2 copyHash: copyHashFlag]
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
			[| hash |
			 (hash := self rawHashBitsOf: objOop) = 0
				ifTrue: "Can't identify an abstract class by the class table; it may not be there-in."
					[(coInterpreter objCouldBeClassObj: objOop)
						ifTrue: [BecamePointerObjectFlag + BecameClassFlag]
						ifFalse: [BecamePointerObjectFlag]]
				ifFalse: "if an object has a hash and it's a class it must be in the table."
					[(self classAtIndex: hash) = objOop
						ifTrue: [BecamePointerObjectFlag + BecameClassFlag]
						ifFalse: [BecamePointerObjectFlag]]]
		ifFalse:
			[(self isCompiledMethod: objOop)
				ifTrue: [BecameCompiledMethodFlag]
				ifFalse: [0]]
]

{ #category : #compaction }
SpurMemoryManager >> bestFitCompact [
	"Compact all of memory using best-fit.
	 Sort free space, find the first free chunk. Scan objects following
	 the first free chunk and for each, look for a free chunk of the exact
	 size, copy the object's contents into the free chunk, and forward
	 the object to its new, lower location.  If any didn't fit exactly do a
	 second pass using best fit."

	| firstFailedFit |
	firstFailedFit := self exactFitCompact.
	firstFailedFit = 0 ifTrue:
		[^self]. "either no free space, no high objects, or no misfits."
	self allOldSpaceObjectsFrom: firstFailedFit
		do: [:o| | b |
			((self isForwarded: o)
			 or: [self isPinned: o]) ifFalse:
				[b := self bytesInObject: o.
				(self allocateOldSpaceChunkOfBytes: b) ifNotNil:
					[:f|
					self mem: f
						cp: o
						y: ((self hasOverflowHeader: o)
								ifTrue: [b - self baseHeaderSize]
								ifFalse: [b]).
					(self isRemembered: o) ifTrue:
						[scavenger remember: f].
					self forward: o to: f].
				self checkFreeSpace]].
	self checkFreeSpace
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

{ #category : #'free space' }
SpurMemoryManager >> bytesInFreeTree: freeNode [
	| freeBytes bytesInObject listNode |
	freeNode = 0 ifTrue: [^0].
	freeBytes := 0.
	bytesInObject := self bytesInObject: freeNode.
	self assert: bytesInObject / self allocationUnit >= self numFreeLists.
	listNode := freeNode.
	[listNode ~= 0] whileTrue:
		["self printFreeChunk: listNode"
		 self assert: (self isValidFreeObject: listNode).
		 freeBytes := freeBytes + bytesInObject.
		 self assert: bytesInObject = (self bytesInObject: listNode).
		 listNode := self fetchPointer: self freeChunkNextIndex ofFreeChunk: listNode].
	^freeBytes
	+ (self bytesInFreeTree: (self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: freeNode))
	+ (self bytesInFreeTree: (self fetchPointer: self freeChunkLargerIndex ofFreeChunk: freeNode))
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

{ #category : #'object access' }
SpurMemoryManager >> characterObjectOf: characterCode [ 
	^characterCode << self numTagBits + self characterTag
]

{ #category : #'object access' }
SpurMemoryManager >> characterTag [
	^2
]

{ #category : #immediates }
SpurMemoryManager >> characterValueOf: oop [
	"Immediate characters are unsigned"
	^(self cCoerceSimple: oop to: #'unsigned long') >> self numTagBits
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
				 (scavenger isInRememberedTable: obj) ifFalse:
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
					  and: [obj ~= self freeListsObject]) ifTrue:
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
				[coInterpreter print: 'misaligned oop in rootTable @ '; printNum: i; print: ' = '; printHex: obj; cr.
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
	self flag: 'no support for remap buffer yet'.
	"1 to: remapBufferCount do:
		[:ri|
		obj := remapBuffer at: ri.
		(obj bitAnd: self wordSize - 1) ~= 0
			ifTrue:
				[coInterpreter print: 'misaligned remapRoot @ '; printNum: ri; print: ' = '; printHex: obj; cr.
				 self eek.
				 ok := false]
			ifFalse:
				[(heapMap heapMapAtWord: (self pointerForOop: obj)) = 0
					ifTrue:
						[coInterpreter print: 'object leak in remapRoots @ '; printNum: ri; print: ' = '; printHex: obj; cr.
						 self eek.
						 ok := false]]]."
	self flag: 'no support for extraRoots yet'.
	"1 to: extraRootCount do:
		[:ri|
		obj := (extraRoots at: ri) at: 0.
		(obj bitAnd: self wordSize - 1) ~= 0
			ifTrue:
				[coInterpreter print: 'misaligned extraRoot @ '; printNum: ri; print: ' => '; printHex: obj; cr.
				 self eek.
				 ok := false]
			ifFalse:
				[(heapMap heapMapAtWord: (self pointerForOop: obj)) = 0
					ifTrue:
						[coInterpreter print: 'object leak in extraRoots @ '; printNum: ri; print: ' => '; printHex: obj; cr.
						 self eek.
						 ok := false]]]."
	^ok
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
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^coInterpreter checkedIntegerValueOf: intOop
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
							ofObject: classTableRootObj.
	classTablePage = nilObj ifTrue:
		[^nil].
	^self
		fetchPointer: (classIndex bitAnd: self classTableMinorIndexMask)
		ofObject: classTablePage
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

{ #category : #'class table' }
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
SpurMemoryManager >> classTableIndex [
	^classTableIndex
]

{ #category : #accessing }
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

{ #category : #'object enumeration' }
SpurMemoryManager >> classTableObjectsDo: aBlock [
	0 to: (self numSlotsOf: classTableRootObj) - 1 do:
		[:i| | page |
		page := self fetchPointer: i ofObject: classTableRootObj.
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
	"For mapInterpreterOops & bootstrap"
	^classTableRootObj
]

{ #category : #accessing }
SpurMemoryManager >> classTableRootObj: anOop [
	"For mapInterpreterOops"
	classTableRootObj := anOop.
	classTableFirstPage := self fetchPointer: 0 ofObject: classTableRootObj.
	self assert: (self numSlotsOf: classTableRootObj) = (1 << (self classIndexFieldWidth - self classTableMajorIndexShift)).
	self assert: (self numSlotsOf: classTableFirstPage) - 1 = self classTableMinorIndexMask
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
	scavenger coInterpreter: aCoInterpreter
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

{ #category : #'become implementation' }
SpurMemoryManager >> doBecome: obj1 with: obj2 copyHash: copyHashFlag [
	((self isClassInClassTable: obj1)
	 or: [self isClassInClassTable: obj1]) ifTrue:
		[self halt].
	(self numSlotsOf: obj1) = (self numSlotsOf: obj2)
		ifTrue:
			[self inPlaceBecome: obj1 and: obj2 copyHashFlag: copyHashFlag]
		ifFalse:
			[self outOfPlaceBecome: obj1 and: obj2 copyHashFlag: copyHashFlag]
]

{ #category : #accessing }
SpurMemoryManager >> edenBytes [
	^scavenger eden limit - scavenger eden start
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

{ #category : #accessing }
SpurMemoryManager >> endOfMemory [
	^endOfMemory
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

	[page := self fetchPointer: majorIndex ofObject: classTableRootObj.
	 page = nilObj ifTrue:
		[page := self allocateSlotsInOldSpace: self classTablePageSize
					format: self arrayFormat
					classIndex: self arrayClassIndexPun.
		 page ifNil:
			[^PrimErrNoMemory].
		 self fillObj: page numSlots: self classTablePageSize with: nilObj.
		 self storePointer: majorIndex
			ofObject: classTableRootObj
			withValue: page.
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
			 ^0]].
	 majorIndex := (majorIndex + 1 bitAnd: self classIndexMask) max: 1.
	 majorIndex = initialMajorIndex ifTrue: "wrapped; table full"
		[^PrimErrLimitExceeded]] repeat
]

{ #category : #'header formats' }
SpurMemoryManager >> ephemeronFormat [
	^5
]

{ #category : #compaction }
SpurMemoryManager >> exactFitCompact [
	"Compact all of memory using exact-fit.
	 Sort free space, find the first free chunk. Scan objects following
	 the first free chunk and for each, look for a free chunk of the right
	 size, copy the object's contents into the free chunk, and forward
	 the object to its new, lower location.  Answer the first object that
	 failed to fit (for bestFitCompacts convenience), if there's free space."

	| firstFailedFit |
	self sortFreeSpace.
	firstFailedFit := 0.
	totalFreeOldSpace = 0 ifTrue: [^0].
	self allOldSpaceObjectsFrom: self lowestFreeChunkAssumingSortedFreeSpace
		do: [:o| | b |
			((self isForwarded: o)
			 or: [self isPinned: o]) ifFalse:
				[b := self bytesInObject: o.
				(self allocateOldSpaceChunkOfExactlyBytes: b)
					ifNil: [firstFailedFit = 0 ifTrue: [firstFailedFit := o]]
					ifNotNil:
						[:f|
						self mem: f
							cp: o
							y: ((self hasOverflowHeader: o)
									ifTrue: [b - self baseHeaderSize]
									ifFalse: [b]).
						(self isRemembered: o) ifTrue:
							[scavenger remember: f].
						self forward: o to: f]]].
	self checkFreeSpace.
	^firstFailedFit
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
	self assert: (self isForwarded: objOop) not.
	^self longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
]

{ #category : #'object access' }
SpurMemoryManager >> fetchWordLengthOf: objOop [
	"NOTE: this gives size appropriate for fetchPointer: n, but not in general for, eg, fetchLong32, etc.
	 Unlike lengthOf: this does not adjust the length of a context
	 by the stackPointer and so can be used e.g. by cloneContext:"
	^self numSlotsOf: objOop
]

{ #category : #instantiation }
SpurMemoryManager >> fillObj: objOop numSlots: numSlots with: fillValue [
	self subclassResponsibility
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
	^16
]

{ #category : #'header formats' }
SpurMemoryManager >> firstCompiledMethodFormat [
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
		ifTrue: [oop]
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
	^10
]

{ #category : #'object enumeration' }
SpurMemoryManager >> firstObject [
	"Return the first object or free chunk in the heap."

	^nilObj
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

{ #category : #'generation scavenging' }
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

{ #category : #'generation scavenging' }
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
	 10 - 11 32-bit indexable
	 12 - 15 16-bit indexable
	 16 - 23 byte indexable
	 24 - 31 compiled method"
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
	<var: 'header' type: #usqLong>
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
SpurMemoryManager >> freeChunkSmallerIndex [
	"for organizing the tree of large free chunks."
	^3
]

{ #category : #'free space' }
SpurMemoryManager >> freeChunkWithBytes: bytes at: address [
	<inline: true>
	| freeChunk |
	freeChunk := self initFreeChunkWithBytes: bytes at: address.
	self addToFreeList: freeChunk bytes: bytes.
	^freeChunk
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

{ #category : #'free space' }
SpurMemoryManager >> freeSize [
	^totalFreeOldSpace
]

{ #category : #accessing }
SpurMemoryManager >> freeStart [
	(#(Cogit SimpleStackBasedCogit StackToregisterMappingCogit) includes: thisContext sender class name) ifTrue:
		[self halt].
	^freeStart
]

{ #category : #'object testing' }
SpurMemoryManager >> goodContextSize: oop [
	| numSlots |
	numSlots := self numSlotsOf: oop.
	^numSlots = SmallContextSlots or: [numSlots = LargeContextSlots]
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
			| 2 bits				|
			| 22: identityHash	| (on a word boundary)
			| 3 bits				|	(msb <-> lsb = ?,isPinned,isRemembered
			| 5: format			| (on a byte boundary)
			| 2 bits				|
			| 22: classIndex		| (on a word boundary) : LSB
	 The remaining bits (7) need to be used for
		isGrey
		isMarked
		isRemembered	(bit 29)
		isPinned		(bit 30)
		isImmutable
	 leaving 2 unused bits.  The three bit field containing isPinned, isRemembered
	 is for bits that are never set in young objects.  This allows the remembered
	 table to be pruned when full by using these bits as a reference count of
	 newSpace objects from the remembered table. Objects with a high count
	 should be tenured to prune the remembered table."
	<returnTypeC: #usqLong>
	^ (numSlots << self numSlotsFullShift)
	+ (formatField << self formatShift)
	+ classIndex
]

{ #category : #'debug support' }
SpurMemoryManager >> heapMap [
	^heapMap
]

{ #category : #'header format' }
SpurMemoryManager >> identityHashHalfWordMask [
	^16r3fffff
]

{ #category : #'become implementation' }
SpurMemoryManager >> inPlaceBecome: obj1 and: obj2 copyHashFlag: copyHashFlag [
	"Do become in place by swapping object contents."
	| headerTemp temp1 temp2 o1HasYoung o2HasYoung |
	<var: 'headerTemp' type: #usqLong>
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
	"swapping headers swaps hash; if !copyHashFlagundo hash copy"
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

{ #category : #'header formats' }
SpurMemoryManager >> indexablePointersFormat [
	^3
]

{ #category : #'free space' }
SpurMemoryManager >> initFreeChunkWithBytes: numBytes at: address [
	<var: #numBytes type: #usqLong>
	^self subclassResponsibility
]

{ #category : #allocation }
SpurMemoryManager >> initSpaceForAllocationCheck: aNewSpace [
	CheckObjectOverwrite ifTrue:
		[aNewSpace start
			to: aNewSpace limit - 1
			by: self wordSize
			do: [:p| self longAt: p put: p]]
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
	"We can put all initializatins that set something to 0 or to false here.
	 In C all global variables are initialized to 0, and 0 is false."
	remapBuffer := Array new: RemapBufferSize.
	remapBufferCount := 0.
	freeListsMask := totalFreeOldSpace := lowSpaceThreshold := 0.
	checkForLeaks := 0.
	needGCFlag := signalLowSpace := scavengeInProgress := false.
	becomeEffectsFlags := 0.
	statScavenges := statIncrGCs := statFullGCs := 0.
	statScavengeGCUsecs := statIncrGCUsecs := statFullGCUsecs := 0.
	statSGCDeltaUsecs := statIGCDeltaUsecs := statFGCDeltaUsecs := 0.

	"We can also initialize here anything that is only for simulation."
	heapMap := self wordSize = 4 ifTrue: [CogCheck32BitHeapMap new]
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
	"image may be at a different address; adjust oops for new location"
	self adjustAllOopsBy: bytesToShift.

	specialObjectsOop := specialObjectsOop + bytesToShift.

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
	self assert: (self numSlotsOf: freeListObj) = self numFreeLists.
	self assert: (self formatOf: freeListObj) = (self wordSize = 4
													ifTrue: [self firstLongFormat]
													ifFalse: [self sixtyFourBitIndexableFormat]).
	freeLists := self firstIndexableField: freeListObj.
	self classTableRootObj: (self objectAfter: freeListObj).

	self initializeOldSpaceFirstFree: freeOldSpaceStart. "initializes endOfMemory, freeStart"

	"lowSpaceThreshold := 0.
	signalLowSpace := false.
	remapBufferCount := 0.
	tenuringThreshold := 2000.  ""tenure all suriving objects if survivor count is over this threshold""
	growHeadroom := 4*1024*1024. ""four megabytes of headroom when growing""
	shrinkThreshold := 8*1024*1024. ""eight megabytes of free space before shrinking""

	""garbage collection statistics""
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
	extraRootCount := 0."
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

{ #category : #simulation }
SpurMemoryManager >> initializePostBootstrap [
	"The heap has just been bootstrapped into a modified newSpace occupying all of memory
	 above newSpace (and the codeZone). Put things back to some kind of normalcy."
	freeOldSpaceStart := freeStart.
	freeStart := scavenger eden start.
	pastSpaceStart := scavenger pastSpace start.
	scavengeThreshold := scavenger eden limit - (scavenger edenBytes / 64)
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

{ #category : #'become implementation' }
SpurMemoryManager >> innerBecomeObjectsIn: array1 with: array2 copyHash: copyHashFlag [
	"Inner loop of two-way become."
	0 to: (self numSlotsOf: array1) - 1 do:
		[:i| | obj1 obj2 |
		obj1 := self fetchPointer: i ofObject: array1.
		obj2 := self fetchPointer: i ofObject: array2.
		self doBecome: obj1 with: obj2 copyHash: copyHashFlag.
		(self isForwarded: obj1) ifTrue:
			[obj1 := self followForwarded: obj1.
			 self storePointer: i ofObject: array1 withValue: obj1].
		(self isForwarded: obj2) ifTrue:
			[obj2 := self followForwarded: obj2.
			 self storePointer: i ofObject: array2 withValue: obj2]]
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

{ #category : #'object testing' }
SpurMemoryManager >> isCharacterObject: oop [
	^(oop bitAnd: self tagMask) = self characterTag
]

{ #category : #'become implementation' }
SpurMemoryManager >> isClassInClassTable: objOop [
	| hash |
	hash := self rawHashBitsOf: objOop.
	hash = 0 ifTrue:
		[false].
	^(self classAtIndex: hash) = objOop
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

{ #category : #'class table' }
SpurMemoryManager >> isForwardedObjectClassIndexPun [
	^8 "Not to be confused with that of any immediate class"
]

{ #category : #'object testing' }
SpurMemoryManager >> isFreeObject: objOop [
	^(self classIndexOf: objOop) = self isFreeObjectClassIndexPun
]

{ #category : #'class table' }
SpurMemoryManager >> isFreeObjectClassIndexPun [
	^0
]

{ #category : #'object testing' }
SpurMemoryManager >> isImmediate: oop [ 
	^(oop bitAnd: self tagMask) ~= 0
]

{ #category : #'object testing' }
SpurMemoryManager >> isImmediateCharacter: oop [
	^(oop bitAnd: self tagMask) = 2
]

{ #category : #'object testing' }
SpurMemoryManager >> isInEden: objOop [
	^objOop >= scavenger eden start
	  and: [objOop < freeStart]
]

{ #category : #'object testing' }
SpurMemoryManager >> isInFutureSpace: objOop [
	^objOop >= scavenger futureSpace start
	  and: [objOop < scavenger futureSurvivorStart]
]

{ #category : #'object testing' }
SpurMemoryManager >> isInOldSpace: address [ 
	^address between: newSpaceLimit and: freeOldSpaceStart
]

{ #category : #immediates }
SpurMemoryManager >> isInRangeCharacterCode: characterCode [
	^characterCode >= 0 and: [characterCode < (2 raisedTo: 30)]
]

{ #category : #'object testing' }
SpurMemoryManager >> isInSurvivorSpace: objOop [
	^objOop >= scavenger pastSpace start
	  and: [objOop < pastSpaceStart]
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
	"This list records the valid senders of isIntegerObject: as we replace uses of
	  isIntegerObject: by isImmediate: where appropriate."
	| sel |
	sel := thisContext sender method selector.
	(#(	DoIt
		DoItIn:
		on:do: "from the debugger"
		makeBaseFrameFor:
		quickFetchInteger:ofObject:
		frameOfMarriedContext:
		objCouldBeClassObj:
		isMarriedOrWidowedContext:
		shortPrint:
		bytecodePrimAt
		bytecodePrimAtPut
		commonAt:
		commonAtPut:
		loadFloatOrIntFrom:
		positive32BitValueOf:
		primitiveExternalCall
		checkedIntegerValueOf:
		bytecodePrimAtPut
		commonAtPut:
		primitiveVMParameter
		checkIsStillMarriedContext:currentFP:
		displayBitsOf:Left:Top:Right:Bottom:
		fetchStackPointerOf:
		primitiveContextAt
		primitiveContextAtPut
		subscript:with:storing:format:
		printContext:
		compare31or32Bits:equal:
		signed64BitValueOf:
		primDigitMultiply:negative:
		digitLength:
		isNegativeIntegerValueOf:
		magnitude64BitValueOf:
		primitiveMakePoint
		primitiveAsCharacter
		primitiveInputSemaphore
		baseFrameReturn
		primitiveExternalCall
		primDigitCompare:
		isLiveContext:
		numPointerSlotsOf:
		fileValueOf:
		loadBitBltDestForm
		fetchIntOrFloat:ofObject:ifNil:
		fetchIntOrFloat:ofObject:
		loadBitBltSourceForm
		loadPoint:from:
		primDigitAdd:
		primDigitSubtract:
		positive64BitValueOf:
		digitBitLogic:with:opIndex:
		signed32BitValueOf:
		isNormalized:
		primDigitDiv:negative:
		bytesOrInt:growTo:
		primitiveNewMethod
		isCogMethodReference:
		functionForPrimitiveExternalCall:
		genSpecialSelectorArithmetic
		genSpecialSelectorComparison
		ensureContextHasBytecodePC:
		instVar:ofContext:
		ceBaseFrameReturn:
		inlineCacheTagForInstance:
		primitiveObjectAtPut
		commonVariable:at:put:cacheIndex:
		primDigitBitShiftMagnitude:
		externalInstVar:ofContext:) includes: sel) ifFalse:
		[self halt].
	^(oop bitAnd: 1) ~= 0
]

{ #category : #'interpreter access' }
SpurMemoryManager >> isIntegerValue: intValue [
	"Answer if the given value can be represented as a Smalltalk integer value."
	^self subclassResponsibility
]

{ #category : #'object testing' }
SpurMemoryManager >> isNonImmediate: oop [ 
	^(oop bitAnd: self tagMask) = 0
]

{ #category : #'object testing' }
SpurMemoryManager >> isNonIntegerObject: oop [
	"This list records the valid senders of isNonIntegerObject: as we replace uses of
	  isNonIntegerObject: by isNonImmediate: where appropriate."
	(#(	on:do: "from the dbeugger"
		reverseDisplayFrom:to:
		primitiveObjectAtPut
		isCogMethodReference:) includes: thisContext sender method selector) ifFalse:
		[self halt].
	^(oop bitAnd: 1) = 0
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

{ #category : #'header access' }
SpurMemoryManager >> isPinned: objOop [
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

{ #category : #'generation scavenging' }
SpurMemoryManager >> isScavengeSurvivor: oop [
	<doNotGenerate>
	^scavenger isScavengeSurvivor: oop
]

{ #category : #'class table' }
SpurMemoryManager >> isSegmentSpanningFakeObjectPun [
	^3
]

{ #category : #'free space' }
SpurMemoryManager >> isValidFreeObject: objOop [
	| chunk |
	^(self isFreeObject: objOop)
	  and: [((chunk := (self fetchPointer: self freeChunkNextIndex ofFreeChunk: objOop)) = 0
		   or: [self isFreeObject: chunk])
	  and: [(self bytesInObject: objOop) / self allocationUnit < self numFreeLists
		    or: [((chunk := (self fetchPointer: self freeChunkParentIndex ofFreeChunk: objOop)) = 0
			   or: [self isFreeObject: chunk])
			  and: [((chunk := (self fetchPointer: self freeChunkSmallerIndex ofFreeChunk: objOop)) = 0
				    or: [self isFreeObject: chunk])
			  and: [(chunk := (self fetchPointer: self freeChunkLargerIndex ofFreeChunk: objOop)) = 0
				    or: [self isFreeObject: chunk]]]]]]
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

{ #category : #'header access' }
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
SpurMemoryManager >> leakCheckScavenge [
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

{ #category : #'simulation only' }
SpurMemoryManager >> lookupAddress: address [
	"If address appears to be that of a Symbol or a few well-known objects (such as classes) answer it, otherwise answer nil.
	 For code disassembly"
	<doNotGenerate>
	| fmt size string class classSize maybeThisClass classNameIndex thisClassIndex |
	(self addressCouldBeObj: address) ifFalse:
		[^nil].
	address - self baseHeaderSize = classTableRootObj ifTrue:
		[^'(classTableRoot+baseHeaderSize)'].
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

{ #category : #'free space' }
SpurMemoryManager >> lowestFreeChunkAssumingSortedFreeSpace [
	| lowest |
	lowest := sortedFreeChunks = 0
				ifTrue: [endOfMemory]
				ifFalse: [sortedFreeChunks].
	1 to: self numFreeLists - 1 do:
		[:i| | chunk |
		chunk := freeLists at: i.
		(chunk ~= 0 and: [chunk < lowest]) ifTrue:
			[lowest := chunk]].
	^lowest
]

{ #category : #instantiation }
SpurMemoryManager >> maxSlotsForNewSpaceAlloc [
	"Almost entirely arbitrary, but we dont want 1Mb bitmaps allocated in eden.
	 But this choice means no check for numSlots > maxSlotsForNewSpaceAlloc
	 for non-variable allocations."
	^self fixedFieldsOfClassFormatMask
]

{ #category : #simulation }
SpurMemoryManager >> mem: destAddress cp: sourceAddress y: bytes [
	"For SpurGenerationScavenger>>copyToFutureSpace:bytes:"
	<doNotGenerate>
	^self mem: destAddress mo: sourceAddress ve: bytes
]

{ #category : #accessing }
SpurMemoryManager >> memory [
	^memory
]

{ #category : #accessing }
SpurMemoryManager >> memory: aValue [
	^memory := aValue
]

{ #category : #'simulation only' }
SpurMemoryManager >> methodArgumentCount [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter methodArgumentCount
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

{ #category : #'generation scavenging' }
SpurMemoryManager >> newSpaceIsEmpty [
	^freeStart = scavenger eden start
	  and: [pastSpaceStart = scavenger pastSpace start]
]

{ #category : #accessing }
SpurMemoryManager >> newSpaceLimit [
	^newSpaceLimit
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
	^self subclassResponsibility
]

{ #category : #'object access' }
SpurMemoryManager >> numSlotsOfAny: objOop [
	"A private internal version of numSlotsOf: that is happy to be applied to free or forwarded objects."
	<returnTypeC: #usqInt>
	| numSlots |
	numSlots := self rawNumSlotsOf: objOop..
	^numSlots = self numSlotsMask
		ifTrue: [self longAt: objOop - self baseHeaderSize] "overflow slots; (2^32)-1 slots are plenty"
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
				["contexts end at the stack pointer"
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
	numLiterals := coInterpreter literalCountOf: objOop.
	^numLiterals + LiteralStart
]

{ #category : #'object access' }
SpurMemoryManager >> numTagBits [
	^self subclassResponsibility
]

{ #category : #'object enumeration' }
SpurMemoryManager >> objectAfter: objOop [
	"Object parsing.
	1. all objects have at least a word following the header, for a forwarding pointer.
	2. objects with an overflow size have a preceeing word with a saturated slotSize.  If the word following
	    an object doesn't have a saturated size field it must be a single-header object.  If the word following
	   does have a saturated slotSize it must be the overflow size word."
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

{ #category : #'object enumeration' }
SpurMemoryManager >> oopOfObjectStartingAt: address [
	"Answer the oop of the memory chunk starting at address, which is either the address
	 of the overflow size word, or objOop itself, depending on the size of the object."
	self flag: #endianness.
	^(self longAt: address) >> self numSlotsHalfShift = self numSlotsMask
		ifTrue: [address + self baseHeaderSize]
		ifFalse: [address]
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

{ #category : #'header format' }
SpurMemoryManager >> overflowSlotsMask [
	^self subclassResponsibility
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
	(#(	storePointer:ofObject:withValue:
		storePointer:ofForwarder:withValue:
		inPlaceBecome:and:copyHashFlag:) includes: thisContext sender method selector) ifFalse:
		[self halt].
	(self isRemembered: destObj) ifFalse:
		[scavenger remember: destObj.
		 self setIsRememberedOf: destObj to: true]
]

{ #category : #'become implementation' }
SpurMemoryManager >> postBecomeScanClassTable [
	"Scan the class table post-become (iff a pointer object or compiled method was becommed)"
	(becomeEffectsFlags anyMask: BecamePointerObjectFlag+BecameCompiledMethodFlag) ifFalse: [^self].
	
	0 to: (self numSlotsOf: classTableRootObj) - 1 do:
		[:i| | page |
		page := self fetchPointer: i ofObject: classTableRootObj.
		0 to: (self numSlotsOf: page) - 1 do:
			[:j| | classOrNil |
			classOrNil := self fetchPointer: j ofObject: page.
			classOrNil ~= nilObj ifTrue:
				[(self isForwarded: classOrNil) ifTrue:
					[classOrNil := self followForwarded: classOrNil.
					 self storePointer: j ofObject: page withValue: classOrNil].
				 self scanClassPostBecome: classOrNil effects: becomeEffectsFlags]]]
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
	<doNotGenerate>
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
		((self isPointersNonImm: obj) or: [self isCompiledMethod: obj])
			ifTrue:
				[(self isCompiledMethod: obj)
					ifTrue:
						[i := (coInterpreter literalCountOf: obj) + LiteralStart]
					ifFalse:
						[(self isContextNonImm: obj)
							ifTrue: [i := CtxtTempFrameStart + (coInterpreter fetchStackPointerOf: obj)]
							ifFalse: [i := self lengthOf: obj]].
				[(i := i - 1) >= 0] whileTrue:
					[anOop = (self fetchPointer: i ofObject: obj) ifTrue:
						[coInterpreter printHex: obj; print: ' @ '; printNum: i; space; printOopShort: obj; cr.
						 i := 0]]]
			ifFalse:
				[((self isForwarded: obj)
				 and: [(self fetchPointer: 0 ofMaybeForwardedObject: obj) = anOop]) ifTrue:
					[coInterpreter printHex: obj; print: ' => '; printHex: anOop; cr]]]
]

{ #category : #'simulation only' }
SpurMemoryManager >> push: oop [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	<doNotGenerate>
	^coInterpreter push: oop
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

{ #category : #'garbage collection' }
SpurMemoryManager >> remap: oop [
	self shouldNotImplement
]

{ #category : #'interpreter access' }
SpurMemoryManager >> remapBuffer [
	"We support this excessence for compatibility with ObjectMemory.
	 Spur doesn't GC during allocation."
	^remapBuffer
]

{ #category : #'generation scavenging' }
SpurMemoryManager >> remapObj: objOop [
	"Scavenge or simply follow objOop.  Answer the new location of objOop.  The
	 send should have been guarded by a send of shouldRemapOop: or shouldScavengeObj:.
	 The method is called remapObj: for compatibility with ObjectMemory."
	<inline: false>
	| resolvedObj |
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

{ #category : #'debug support' }
SpurMemoryManager >> runLeakCheckerForFullGC: fullGCFlag [
	<inline: false>
	(fullGCFlag
			ifTrue: [self leakCheckFullGC]
			ifFalse: [self leakCheckScavenge]) ifTrue:
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

{ #category : #'debug support' }
SpurMemoryManager >> scavenger [
	<doNotGenerate>
	^scavenger
]

{ #category : #'generation scavenging' }
SpurMemoryManager >> scavengingGC [
	"Run the scavenger."

	self scavengingGCTenuringIf: TenureByAge
]

{ #category : #'generation scavenging' }
SpurMemoryManager >> scavengingGCTenuringIf: tenuringCriterion [
	"Run the scavenger."

	self assert: remapBufferCount = 0.
	self checkFreeSpace.
	"coInterpreter printCallStackFP: coInterpreter framePointer"

	self runLeakCheckerForFullGC: false.
	coInterpreter
		preGCAction: GCModeIncr;
		"would prefer this to be in mapInterpreterOops, but
		 compatibility with ObjectMemory dictates it goes here."
		flushMethodCacheFrom: startOfMemory to: newSpaceLimit.
	needGCFlag := false.

	gcStartUsecs := coInterpreter ioUTCMicrosecondsNow.

	scavengeInProgress := true.
	scavenger tenuringCriterion: tenuringCriterion.
	pastSpaceStart := scavenger scavenge.
	self assert: (self
					oop: pastSpaceStart
					isGreaterThanOrEqualTo: scavenger pastSpace start
					andLessThanOrEqualTo: scavenger pastSpace limit).
	freeStart := scavenger eden start.
	self initSpaceForAllocationCheck: scavenger eden.
	scavengeInProgress := false.

	statScavenges := statScavenges + 1.
	statGCEndUsecs := coInterpreter ioUTCMicrosecondsNow.
	statSGCDeltaUsecs := statGCEndUsecs - gcStartUsecs.
	statScavengeGCUsecs := statScavengeGCUsecs + statSGCDeltaUsecs.

	coInterpreter postGCAction.
	self runLeakCheckerForFullGC: false.

	self checkFreeSpace
]

{ #category : #'generation scavenging' }
SpurMemoryManager >> scheduleScavenge [
	needGCFlag := true.
	coInterpreter forceInterruptCheck
]

{ #category : #'debug support' }
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

{ #category : #'header access' }
SpurMemoryManager >> setHashBitsOf: objOop to: hash [
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

{ #category : #'generation scavenging' }
SpurMemoryManager >> shouldRemapObj: objOop [
	"Answer if the obj should be scavenged (or simply followed). The method is called
	 shouldRemapObj: for compatibility with ObjectMemory."
	^(self isForwarded: objOop)
	  or: [self isYoung: objOop]
]

{ #category : #'generation scavenging' }
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
	self flag: #temporary.
	^SmallInteger maxVal
]

{ #category : #accessing }
SpurMemoryManager >> signalLowSpace [
	^signalLowSpace
]

{ #category : #'header formats' }
SpurMemoryManager >> sixtyFourBitIndexableFormat [
	^9
]

{ #category : #'class table' }
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
	self storePointer: self freeChunkNextIndex ofObject: list withValue: 0.
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
SpurMemoryManager >> sortFreeSpace [
	"Sort free space for best-fit compaction.  Sort the individual free lists so that
	 the lowest address is at the head of each list.  Sort the large chunks through the
	 freeChunkNextAddressIndex from low to high, with the head in sortedFreeChunks."

	self checkFreeSpace.
	1 to: self numFreeLists - 1 do:
		[:i| self sortFreeListAt: i].
	sortedFreeChunks := 0.
	self allObjectsInFreeTree: (freeLists at: 0) do:
		[:f| | node prev |
		node := sortedFreeChunks.
		prev := 0.
		[node ~= 0
		 and: [node < f]] whileTrue:
			[prev := node.
			node := self fetchPointer: self freeChunkNextAddressIndex ofObject: node].
		"insert the node into the sorted list"
		self assert: (node = 0 or: [node > f]).
		prev = 0
			ifTrue:
				[sortedFreeChunks := f]
			ifFalse:
				[self storePointer: self freeChunkNextAddressIndex
					ofFreeChunk: prev
					withValue: f].
		self storePointer: self freeChunkNextAddressIndex
			ofFreeChunk: f
			withValue: node].
	self assert: self sortedFreeChunksAreSorted.
	self checkFreeSpace
]

{ #category : #'debug support' }
SpurMemoryManager >> sortedFreeChunksAreSorted [
	| chunk next |
	chunk := sortedFreeChunks.
	[chunk ~= 0] whileTrue:
		[next := self fetchPointer: self freeChunkNextAddressIndex ofObject: chunk.
		(next = 0 or: [next > chunk]) ifFalse:
			[^false].
		 chunk := next].
	^true
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

{ #category : #accessing }
SpurMemoryManager >> startOfMemory [
	"Return the start of object memory.  This is immediately after the native code zone.
	 N.B. the stack zone is alloca'ed. Use a macro so as not to punish the debug VM."
	<cmacro: '() heapBase'> "This is for CoInterpreter, not StackInterpreter"
	<returnTypeC: #usqInt>
	self flag: #fixme.
	^startOfMemory
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
SpurMemoryManager >> statNumGCs [
	^statScavenges + statIncrGCs + statFullGCs
]

{ #category : #accessing }
SpurMemoryManager >> statScavenges [
	^statScavenges
]

{ #category : #'object access' }
SpurMemoryManager >> storeByte: byteIndex ofObject: oop withValue: valueByte [
	^self byteAt: oop + self baseHeaderSize + byteIndex put: valueByte
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

{ #category : #'generation scavenging' }
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

{ #category : #'word size' }
SpurMemoryManager >> tagMask [
	^self subclassResponsibility
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

{ #category : #'class table' }
SpurMemoryManager >> thirtyTwoBitLongsClassIndexPun [
	"Class puns are class indices not used by any class.  There may be
	 an entry for the pun that refers to the notional class of objects with
	 this class index.  But because the index doesn't match the class it
	 won't show up in allInstances, hence hiding the object with a pun as
	 its class index. The puns occupy indices 16 through 31."
	^18
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
	| freeBytes bytesInObject obj |
	freeBytes := 0.
	1 to: self numFreeLists - 1 do:
		[:i| 
		bytesInObject := i * self allocationUnit.
		obj := freeLists at: i.
		[obj ~= 0] whileTrue:
			[freeBytes := freeBytes + bytesInObject.
			 self assert: bytesInObject = (self bytesInObject: obj).
			 self assert: (self isValidFreeObject: obj).
			 obj := self fetchPointer: self freeChunkNextIndex ofFreeChunk: obj]].
	^freeBytes + (self bytesInFreeTree: (freeLists at: 0))
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
	<inline: true>
	self assert: ((self bytesInObject: chunk) = (index * self allocationUnit)
				and: [index > 1 "a.k.a. (self bytesInObject: chunk) > self allocationUnit"]).
	freeLists
		at: index
		put: (self
				fetchPointer: self freeChunkNextIndex
				ofFreeChunk: chunk).
	^chunk
]

{ #category : #'class table' }
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
	^4
]

{ #category : #'word size' }
SpurMemoryManager >> wordSize [
	"Answer the manager's word size, whjich is the size of an oop, and which
	 is assumed to be equivslent to the underlying machine's word size."
	^self subclassResponsibility
]
