"
SpurMemoryManager is a new object representation and garbage collector for the Cog VM's.  Spur is dedicated to Andreas Raab, friend and colleague.  I miss you, Andreas.  The goal for Spur is an overall improvement in Cog of -50% (twice as fast) for memory-intensive benchmarks.  The objectives for the Spur memory manager are

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

- lazy become.  The JIT's use of inline cacheing provides a cheap way of avoiding scanning the heap as part of a become (which is the simple approach to implementing become in a system with direct pointers).  A becomeForward: on a (set of) non-zero-sized object(s) turns the object into a ""corpse"" or ""forwarding object"" whose first (non-header) word/slot is replaced by a pointer to the target of the becomeForward:.  The corpse's class index is set to one that identifies corpses (let's say classIndex 1), and, because it is a special, hidden class index, will always fail an inline cache test.  The inline cache failure code is then responsible for following the forwarding pointer chain (these are Iliffe vectors :) ) and resolving to the actual target.  (In the interpreter there needs to be a similar check when probing the method cache).   It has yet to be determined exactly how this is done (e.g. change the receiver register and/or stack contents and retry the send, perhaps scanning the current activation).  See below on how we deal with becomes on objects with named inst vars.  We insist that objects are at least 16 bytes in size (see 8-byte alignment below) so that there will always be space for a forwarding pointer.  Since none of the immediate classes can have non-immediate instances and since we allocate the immediate class indices corresponding to their tag pattern (SmallInteger = 1 & 3, Character = 2, SmallFloat = 5?) we can use all the class indices from 0 to 7 for special uses, 0 = free, and e.g. 1 = isForwarded.

- pinning.  To support a robust and easy-to-use FFI the memory manager must support temporary pinning where individual objects can be prevented from being moved by the GC for as long as required, either by being one of an in-progress FFI call's arguments, or by having pinning asserted by a primitive (allowing objects to be passed to external code that retains a reference to the object after returning).  Pinning probably implies a per-object ""is-pinned"" bit in the object header.  Pinning will be done via lazy become; i..e an object in new space will be becommed into a pinned object in old space.  We will only support pinning in old space.

- efficient old space collection.  An incremental collector (a la Dijkstra's three colour algorithm) collects old space, e.g. via an amount of tracing being hung off scavenges and/or old space allocations at an adaptive rate that keeps full garbage collections to a minimum.  It may also be possible to provide cheap compaction by using lazyBecome: and best-fit (see free space/free list below).

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

For the moment we do not tackle the issue of heap growth and shrinkage with the ability to allocate and deallocate heap segments via memory-mapping.  This technique allows space to be released back to the OS by unmapping empty segments.  We may revisit this but it is not a key requirement for the first implementation.  (See ""A segmented oldSpace is useful."" below).

The basic approach is to use a fixed size new space and a growable old space.  The new space is a classic three-space nursery a la Ungar's Generation Scavenging, a large eden for new objects and two smaller survivor spaces that exchange roles on each collection, one being the to space to which surviving objects are copied, the other being the from space of the survivors of the previous collection, i.e. the previous to space.

To provide apparent pinning in new space we rely on lazy become.  Since most pinned objects will be byte data and these do not require stack zone activation scanning, the overhead is simply an old space allocation and corpsing.

To provide pinning in old space, large objects are implicitly pinned (because it is expensive to move large objects and, because they are both large and relatively rare, they contribute little to overall fragmentation - as in aggregates, small objects can be used to fill-in the spaces between karge objects).  Hence, objects above a particular size are automatically allocated in old space, rather than new space.  Small objects are pinned as per objects in new space, by asserting the pin bit, which will be set automaticaly when allocating a large object.  As a last resort, or by programmer control (the fullGC primitive) old space is collected via mark-sweep (mark-compact) and so the mark phase must build the list of pinned objects around which the sweep/compact phase must carefully step.

Free space in old space is organized by a free list/free tree as in Eliot's VisualWorks 5i old space allocator.  There are 64 free lists, indices 1 through 63 holding blocks of space of that size, index 0 holding a semi-balanced ordered tree of free blocks, each node being the head of the list of free blocks of that size.  At the start of the mark phase the free list is thrown away and the sweep phase coallesces free space and steps over pinned objects as it proceeds.  We can reuse the forwarding pointer compaction scheme used in the old collector.  Incremental collections merely move unmarked objects to the free lists (as well as nilling weak pointers in weak arrays and scheduling them for finalization).  The occupancy of the free lists is represented by a bitmap in a 64-bit integer so that an allocation of size 63 or less can know whether there exists a free chunk of that size, but more importantly can know whether a free chunk larger than it exists in the fixed size free lists without having to search all larger free list heads.

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

The free list also looks like it allows efficient incremental compaction.  Surrently in the 32-bit implementation, but easily affordable in the 64-bit implementation, objects have at least two fields, the first one being a forwarding pointer, the second one rounding up to 8-byte object alignment.  On the free list the first field is used to link the list of free chunks of a given size.  The second field could be used to link free chunks in memory order.  And of course the last free chunk is the chunk before the last run of non-free objects.  We compact by

a) keeping each free list in memory order (including the lists of free chunks off each node in the large free chunk tree)
b) sorting the free chunks in memory order by merge sorting the free lists
c) climbing the free list in memory order.  For each free chunk in the free list search memory from the last free chunk to the end (and from the previous chunk to the next chunk, and so on) looking for a best-fit live object.  That object is then copied into the free chunk, and its corpse is turned into a forwarding pointer.  This works because the compaction does not slide objects, and hence no forwarding blocks are necessary and the algorithm can be made incremental. Various optimizations are possible, e.g. using a bitmap to record the sizes of the first few free chunks on the list when looking for best fits.  The assumptions being
a) the number fo objects on the free list is kept small because the IGC incrementally compacts, and so sorting and searching the list is not expensive
b) the incremental collector's following of forwarding pointers reclaims the corpses at the end of memory at a sufficient rate to keep the free list small
c) the rounding of objects to an 8-byte alignment improves the chances of finding a best fit.
Note that this incremental collection is easily amenable to leave pinned objects where they are; they are simply filtered out when looking for a best fit.

A segmented oldSpace is useful.  It allows growing oldSpace incrementally, adding a segment at a time, and freeing empty segments.  But such a scheme is likely to introduces complexity in object enumeration, and compaction (enumeration would apear to require visiting each segment, compaction must be wthin a segment, etc). One idea that might fly to allow a segmented old space that appears to be a single contiguous spece is to use fake pinned objects to bridge the gaps between segments.  The last two words of each segment can be used to hold the header of a pinned object whose size is the distance to the next segment.  The pinned object's classIndex can be one of the puns so that it doesn't show up in allInstances; this can perhaps also indicate to the incremental collector that it is not to reclaim the object, etc.  However, free objects would need a large enough size field to stretch across large gaps in the address space.  The current design limits the overflow size field to a 32-bit slot count, which wouldn't be large enough in a 64-bit implementation.  The overflow size field is at most 7 bytes since the overflow size word also contains a maxed-out 8-bit slot count (for object parsing).  A byte can be stolen from e.g. the identityHash field to beef up the size to a full 64-bits.


Lazy become.

As described earlier the basic idea behind lazy become is to use corpses (forwarding objects) that are followed lazily during GC and inline cache miss.  However, a lazy scheme cannot be used on objects with named inst vars without adding checking to all inst var accesses, which we judge too expensive.  Instead, when becomming objects with named inst vars, we scan all activations in the stack zone, eagerly becomming these references, and we check for corpses when faulting in a context into the stack zone.  Essentially, the invariant is that there are no references to corpses from the receiver slots of stack activations.  A detail is whether we allow or forbid pinning of closure indirection vectors, or scan the entire stack of each activation.  Using a special class index pun for indirection vectors is a cheap way of preventing their becomming/pinning etc.  Although ""don't do that"" (don't attempt to pin/become indirection vectors) is also an acceptable response.

60-bit immediate Floats
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
The second approach is faster; the common case is scanning the class table, the uncommon case is freeing classes.  The second approach is better; in-line caches do not prevent reclamation of classes.
"
Class {
	#name : #SpurMemoryManager,
	#superclass : #CogClass,
	#instVars : [
		'coInterpreter',
		'scavenger',
		'startOfMemory',
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
		'endOfMemory',
		'freeLists',
		'freeListMask',
		'newSpaceStart',
		'checkForLeaks',
		'needGCFlag',
		'heapMap',
		'signalLowSpace'
	],
	#classVars : [
		'CheckObjectOverwrite',
		'NumFreeLists'
	],
	#pools : [
		'VMBasicConstants',
		'VMObjectIndices',
		'VMSqueakClassIndices',
		'VMSqueakV3BytecodeConstants'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

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
	NumFreeLists := 65. "One for each size up to and including 64 slots. One for sizes > 64 slots."
	CheckObjectOverwrite := true
]

{ #category : #'class initialization' }
SpurMemoryManager class >> initializeCompactClassIndices [
	"Reuse the compact class indices to name known classIndices.
	 This helps reduce the churn in the interpreters."
	"c.f. SpurBootstrap>>defineKnownClassIndices"
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
SpurMemoryManager class >> initializeWithOptions: optionsDictionary [
	"SpurMemoryManager initializeWithOptions: Dictionary new"

	self initBytesPerWord: (self == SpurMemoryManager
								ifTrue: [optionsDictionary at: #BytesPerWord ifAbsent: [4]]
								ifFalse: [self wordSize]).
	BytesPerOop := optionsDictionary at: #BytesPerOop ifAbsent: [BytesPerWord].

	self initializeSpecialObjectIndices.
	self initializeCompactClassIndices.
	self initializePrimitiveErrorCodes.
	self initializeObjectHeaderConstants.

	SpurGenerationScavenger initialize
]

{ #category : #'simulation only' }
SpurMemoryManager class >> vmProxyMajorVersion [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^StackInterpreter vmProxyMajorVersion
]

{ #category : #'simulation only' }
SpurMemoryManager class >> vmProxyMinorVersion [
	"hack around the CoInterpreter/ObjectMemory split refactoring"
	^StackInterpreter vmProxyMinorVersion
]

{ #category : #'word size' }
SpurMemoryManager class >> wordSize [
	^self subclassResponsibility
]

{ #category : #'garbage collection' }
SpurMemoryManager >> addToFreeList: freeChunk [
	| chunkBytes childBytes parent child index |
	chunkBytes := self bytesInObject: freeChunk.
	index := chunkBytes / self wordSize.
	index < NumFreeLists ifTrue:
		[self storePointerUnchecked: 0 ofObject: freeChunk withValue: (freeLists at: index).
		 freeLists at: index put: freeChunk.
		 ^self].
	self
		storePointerUnchecked: self freeChunkNextIndex ofObject: freeChunk withValue: 0;
		storePointerUnchecked: self freeChunkParentIndex ofObject: freeChunk withValue: 0;
		storePointerUnchecked: self freeChunkSmallerIndex ofObject: freeChunk withValue: 0;
		storePointerUnchecked: self freeChunkLargerIndex ofObject: freeChunk withValue: 0.
	"Large chunk list organized as a tree, each node of which is a list of chunks of the same size.
	 Beneath the node are smaller and larger blocks."
	parent := 0.
	child := freeLists at: 0.
	[child ~= 0] whileTrue:
		[childBytes := self bytesInObject: child.
		 childBytes = chunkBytes ifTrue: "size match; add to list at node."
			[self storePointerUnchecked: self freeChunkNextIndex
					ofObject: freeChunk
						withValue: (self fetchPointer: self freeChunkNextIndex ofObject: child);
				storePointerUnchecked: self freeChunkNextIndex
					ofObject: child
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
	self storePointerUnchecked: self freeChunkParentIndex
			ofObject: freeChunk
				withValue: parent.
	 self storePointerUnchecked: (childBytes > chunkBytes
									ifTrue: [self freeChunkSmallerIndex]
									ifFalse: [self freeChunkLargerIndex])
			ofObject: parent
				withValue: freeChunk
]

{ #category : #'object enumeration' }
SpurMemoryManager >> addressAfter: objOop [
	"Answer the address immediately following an object."
	^self subclassResponsibility
]

{ #category : #'debug support' }
SpurMemoryManager >> addressCouldBeObj: address [ 
	^(address bitAnd: self baseHeaderSize - 1) = 0
	  and: [(self isInOldSpace: address)
		or: [(self isInEden: address)
		or: [self isInSurvivorSpace: address]]]
]

{ #category : #'object testing' }
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
	self subclassResponsibility
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allNewSpaceObjectsDo: aBlock [
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
	limit := scavenger pastSpace limit.
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
	self allOldSpaceObjectsDo: aBlock.
	self allNewSpaceObjectsDo: aBlock
]

{ #category : #'object enumeration' }
SpurMemoryManager >> allOldSpaceObjectsDo: aBlock [
	<inline: true>
	| prevObj prevPrevObj objOop |
	prevPrevObj := prevObj := nil.
	objOop := self firstObject.
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
SpurMemoryManager >> allocateMemoryOfSize: memoryBytes newSpaceSize: newSpaceBytes codeSize: codeBytes [
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
					ifFalse: [Bitmap]) new: (memoryBytes + newSpaceBytes + codeBytes) // 4.
	startOfMemory := codeBytes.
	endOfMemory := memoryBytes + newSpaceBytes + codeBytes.
	"leave newSpace empty for the bootstrap"
	freeStart := newSpaceBytes + startOfMemory.
	newSpaceStart := startOfMemory.
	newSpaceLimit := newSpaceBytes + startOfMemory.
	scavengeThreshold := memory size * 4. "Bitmap is a 4-byte per word array"
	scavenger := SpurGenerationScavenger new
					manager: self
					memory: memory
					newSpaceStart: newSpaceStart
					newSpaceBytes: newSpaceBytes
					edenBytes: newSpaceBytes * 5 // 7 "David's paper uses 140Kb eden + 2 x 28kb survivor spaces :-)"
]

{ #category : #allocation }
SpurMemoryManager >> allocateSlots: numSlots format: formatField classIndex: classIndex [
	self subclassResponsibility
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

{ #category : #'header format' }
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
	 Does not adjuect contexts by stackPointer."
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

{ #category : #'header format' }
SpurMemoryManager >> bytesPerSlot [
	^self subclassResponsibility
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
SpurMemoryManager >> cheapAddressCouldBeObj: address [ 
	^(address bitAnd: self baseHeaderSize - 1) = 0
	  and: [address >= scavenger eden start
	  and: [address <= freeOldSpaceStart]]
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

{ #category : #'class table' }
SpurMemoryManager >> classAtIndex: classIndex [
	| classTablePage |
	classTablePage := self fetchPointer: classIndex >> self classTableMajorIndexShift
							ofObject: classTableRootObj.
	^self
		fetchPointer: (classIndex bitAnd: self classTableMinorIndexMask)
		ofObject: classTablePage
]

{ #category : #'header format' }
SpurMemoryManager >> classIndexMask [
	"22-bit class mask => ~ 4M classes"
	^16r3fffff
]

{ #category : #'header access' }
SpurMemoryManager >> classIndexOf: objOop [
	^self subclassResponsibility
]

{ #category : #'class table' }
SpurMemoryManager >> classIsItselfClassIndexPun [
	^4
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
	classTableFirstPage := self fetchPointer: 0 ofObject: classTableRootObj
]

{ #category : #simulation }
SpurMemoryManager >> coInterpreter: aCoInterpreter [
	<doNotGenerate>
	coInterpreter := aCoInterpreter
]

{ #category : #'object access' }
SpurMemoryManager >> compactClassIndexOf: objOop [
	^self classIndexOf: objOop
]

{ #category : #'class membership' }
SpurMemoryManager >> compactIndexOfClass: objOop [
	^self hashBitsOf: objOop
]

{ #category : #accessing }
SpurMemoryManager >> edenBytes [
	^scavenger eden limit - scavenger eden start
]

{ #category : #allocation }
SpurMemoryManager >> eeInstantiateClassIndex: knownClassIndex format: objFormat numSlots: numSlots [
	"Instantiate an instance of a compact class.  ee stands for execution engine and
	 implies that this allocation will *NOT* cause a GC.  N.B. the instantiated object
	 IS NOT FILLED and must be completed before returning it to Smalltalk. Since this
	 call is used in routines that do just that we are safe.  Break this rule and die in GC."
	<inline: true>
	self assert: (numSlots > 0 and: [knownClassIndex ~= 0]).
	self assert: (objFormat < self firstByteFormat
					ifTrue: [objFormat]
					ifFalse: [objFormat bitAnd: self byteFormatMask])
				= (self instSpecOfClass: (self knownClassAtIndex: knownClassIndex)).
	^self allocateSlots: numSlots format: objFormat classIndex: knownClassIndex
]

{ #category : #allocation }
SpurMemoryManager >> eeInstantiateMethodContextSlots: numSlots [
	<inline: true>
	^self
		allocateSlots: numSlots
		format: self indexablePointersFormat
		classIndex: ClassMethodContextCompactIndex
]

{ #category : #'class table' }
SpurMemoryManager >> ensureBehaviorHash: aBehavior [
	| newHash err |
	self assert: (self isIntegerObject: aBehavior) not.
	(newHash := self hashBitsOf: aBehavior) = 0 ifTrue:
		[(err := self enterIntoClassTable: aBehavior) ~= 0 ifTrue:
			[^err negated].
		 newHash := self hashBitsOf: aBehavior].
	^newHash
]

{ #category : #'class table' }
SpurMemoryManager >> enterIntoClassTable: aBehavior [
	"Enter aBehavior into the class table and answer 0.  Otherwise answer a primitive failure code."
	self shouldBeImplemented
]

{ #category : #'header format' }
SpurMemoryManager >> ephemeronFormat [
	^5
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
	^self classAtIndex: classIndex
]

{ #category : #'object access' }
SpurMemoryManager >> fetchLong32: fieldIndex ofObject: oop [
	"index by 32-bit units, and return a 32-bit value. Intended to replace fetchWord:ofObject:"

	^self long32At: oop + self baseHeaderSize + (fieldIndex << 2)
]

{ #category : #'object access' }
SpurMemoryManager >> fetchWordLengthOf: objOop [
	"NOTE: this gives size appropriate for fetchPointer: n, but not in general for, eg, fetchLong32, etc.
	 Unlike lengthOf: this does not adjust the length of a context
	 by the stackPointer and so can be used e.g. by cloneContext:"
	^self numSlotsOf: objOop
]

{ #category : #allocation }
SpurMemoryManager >> fillObj: objOop numSlots: numSlots with: fillValue [
	self subclassResponsibility
]

{ #category : #'header format' }
SpurMemoryManager >> firstByteFormat [
	^16
]

{ #category : #'header format' }
SpurMemoryManager >> firstCompiledMethodFormat [
	^24
]

{ #category : #'object access' }
SpurMemoryManager >> firstFixedField: objOop [
	<returnTypeC: #'void *'>
	^ self pointerForOop: objOop + self baseHeaderSize
]

{ #category : #'header format' }
SpurMemoryManager >> firstLongFormat [
	^10
]

{ #category : #'object enumeration' }
SpurMemoryManager >> firstObject [
	"Return the first object or free chunk in the heap."

	^nilObj
]

{ #category : #'header format' }
SpurMemoryManager >> firstShortFormat [
	^12
]

{ #category : #'header format' }
SpurMemoryManager >> firstStringyFakeFormat [
	"A fake format for the interpreter used to mark indexable strings in
	 the interpreter's at cache.  This is larger than any format."
	^32
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
SpurMemoryManager >> fixedFieldsOfClassFormat: classFormat [
	^classFormat bitAnd: self fixedFieldsOfClassFormatMask
]

{ #category : #'object format' }
SpurMemoryManager >> fixedFieldsOfClassFormatMask [
	^1 << self fixedFieldsFieldWidth - 1
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
	 6,7,8 unused
	 9 (?) 64-bit indexable
	 10 - 11 32-bit indexable
	 12 - 15 16-bit indexable
	 16 - 23 byte indexable
	 24 - 31 compiled method"
	^self subclassResponsibility
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

{ #category : #'garbage collection' }
SpurMemoryManager >> freeChunkLargerIndex [
	^3
]

{ #category : #'garbage collection' }
SpurMemoryManager >> freeChunkNextIndex [
	^0
]

{ #category : #'garbage collection' }
SpurMemoryManager >> freeChunkParentIndex [
	^1
]

{ #category : #'garbage collection' }
SpurMemoryManager >> freeChunkSmallerIndex [
	^2
]

{ #category : #accessing }
SpurMemoryManager >> freeStart [
	^freeStart
]

{ #category : #'object testing' }
SpurMemoryManager >> goodContextSize: oop [
	| numSlots |
	numSlots := self numSlotsOf: oop.
	^numSlots = SmallContextSlots or: [numSlots = LargeContextSlots]
]

{ #category : #'api characterization' }
SpurMemoryManager >> hasSpurMemoryManagerAPI [
	^true
]

{ #category : #'header access' }
SpurMemoryManager >> hashBitsOf: objOop [
	self flag: #endianness.
	^(self longAt: objOop + 4) bitAnd: self identityHashHalfWordMask
]

{ #category : #'header format' }
SpurMemoryManager >> headerForSlots: numSlots format: formatField classIndex: classIndex [ 
	"The header format in LSB is
	 MSB:	| 8: numSlots		| (on a byte boundary)
			| 2 bits				|
			| 22: identityHash	| (on a word boundary)
			| 3 bits				|	(msb <-> lsb = ?,?,isRemembered
			| 5: format			| (on a byte boundary)
			| 2 bits				|
			| 22: classIndex		| (on a word boundary) : LSB
	 The remaining bits (7) need to be used for
		isGrey
		isMarked
		isRemembered (bit 29)
		isPinned
		isImmutable
	 leaving 2 unused bits."
	<returnTypeC: #usqLong>
	^ (numSlots << self numSlotsFullShift)
	+ (formatField << self formatShift)
	+ classIndex
]

{ #category : #'header format' }
SpurMemoryManager >> identityHashHalfWordMask [
	^16r3fffff
]

{ #category : #'header format' }
SpurMemoryManager >> indexablePointersFormat [
	^3
]

{ #category : #'garbage collection' }
SpurMemoryManager >> initFreeChunkWithBytes: numBytes at: address [
	| numSlots |
	self assert: numBytes \\ self allocationUnit = 0.
	numSlots := numBytes >> self shiftForWord
				- (numBytes >= (self numSlotsMask << self shiftForWord)
					ifTrue: [self baseHeaderSize + self baseHeaderSize / self wordSize]
					ifFalse: [self baseHeaderSize / self wordSize]).
	^self initFreeChunkWithSlots: numSlots at: address
]

{ #category : #'garbage collection' }
SpurMemoryManager >> initFreeChunkWithSlots: numSlots at: address [ 
	^self subclassResponsibility
]

{ #category : #allocation }
SpurMemoryManager >> initSpaceForAllocationCheck: aNewSpace [
	self subclassResponsibility
]

{ #category : #initialization }
SpurMemoryManager >> initialize [
	freeLists := CArrayAccessor on: (Array new: NumFreeLists withAll: 0).
	checkForLeaks := 0.
	needGCFlag := signalLowSpace := false.
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
	"image may be at a different address; adjust oops for new location"
	self adjustAllOopsBy: bytesToShift.

	self initializeOldSpaceFirstFree: freeOldSpaceStart. "initializes endOfMemory, freeStart"

	specialObjectsOop := specialObjectsOop + bytesToShift.

	"heavily used special objects"
	nilObj		:= self splObj: NilObject.
	falseObj	:= self splObj: FalseObject.
	trueObj		:= self splObj: TrueObject.

	"rootTableCount := 0.
	rootTableOverflowed := false.
	lowSpaceThreshold := 0.
	signalLowSpace := false.
	compStart := 0.
	compEnd := 0.
	fwdTableNext := 0.
	fwdTableLast := 0.
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

{ #category : #'garbage collection' }
SpurMemoryManager >> initializeOldSpaceFirstFree: startOfFreeOldSpace [
	<var: 'startOfFreeOldSpace' type: #usqLong>
	| freeOldStart freeChunk |
	<var: 'freeOldStart' type: #usqLong>
	0 to: NumFreeLists - 1 do:
		[:i| freeLists at: i put: 0].
	freeOldStart := startOfFreeOldSpace.
	[endOfMemory - freeOldStart >= (2 raisedTo: 32)] whileTrue:
		[freeChunk := self initFreeChunkWithSlots: (2 raisedTo: 32) / self wordSize at: freeOldStart.
		self addToFreeList: freeChunk.
		freeOldStart := self addressAfter: freeChunk].
	freeChunk := self initFreeChunkWithBytes: endOfMemory - freeOldStart at: freeOldStart.
	self addToFreeList: freeChunk.
	self assert: (self addressAfter: freeChunk) = endOfMemory
]

{ #category : #simulation }
SpurMemoryManager >> initializePostBootstrap [
	"The heap has just been bootstrapped into a modified newSpace occupying all of memory above newSPace (and the codeZone).
	 Put things back to some kind of normalicy."
	freeOldSpaceStart := freeStart.
	freeStart := scavenger eden start
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

{ #category : #'interpreter access' }
SpurMemoryManager >> instanceSizeOf: classObj [
	<api>
	"Answer the number of slots in a class.  For example the instanceSizeOf: 
	 ClassPoint is 2, for the x & y slots. The instance size of non-pointer classes is 0."
	self assert: (coInterpreter addressCouldBeClassObj: classObj).

	^(self formatOfClass: classObj) bitAnd: self fixedFieldsOfClassFormatMask
]

{ #category : #allocation }
SpurMemoryManager >> instantiateClass: classObj [
	| instSpec classFormat numSlots classIndex newObj |
	classFormat := self formatOfClass: classObj.
	instSpec := self instSpecOfClassFormat: classFormat.
	(self isFixedSizePointerFormat: instSpec) ifFalse:
		[^nil].
	classIndex := self hashBitsOf: classObj.
	classIndex = 0 ifTrue:
		[(self enterIntoClassTable: classObj) ifFalse:
			[^nil].
		classIndex := self hashBitsOf: classObj].
	numSlots := self fixedFieldsOfClassFormat: classFormat.
	newObj := self allocateSlots: numSlots format: instSpec classIndex: classIndex.
	newObj ifNotNil:
		[self fillObj: newObj numSlots: numSlots with: nilObj].
	^newObj
]

{ #category : #allocation }
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
SpurMemoryManager >> integerValueOf: oop [
	^self subclassResponsibility
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
SpurMemoryManager >> isContext: oop [
	<inline: true>
	^(self isNonImmediate: oop)
	   and: [(self classIndexOf: oop) = ClassMethodContextCompactIndex]
]

{ #category : #'object testing' }
SpurMemoryManager >> isContextNonImm: oop [
	<inline: true>
	^(self classIndexOf: oop) = ClassMethodContextCompactIndex
]

{ #category : #'header format' }
SpurMemoryManager >> isFixedSizePointerFormat: format [
	^format <= self nonIndexablePointerFormat
	  or: [format = self ephemeronFormat]
]

{ #category : #'object testing' }
SpurMemoryManager >> isForwarded: objOop [
	^(self classIndexOf: objOop) = self isForwardedObjectClassIndexPun
]

{ #category : #'class table' }
SpurMemoryManager >> isForwardedObjectClassIndexPun [
	^1
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
	  and: [objOop < scavenger eden limit]
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
SpurMemoryManager >> isIndexable: objOop [
	^(self formatOf: objOop) >= self sixtyFourBitIndexableFormat
]

{ #category : #'object testing' }
SpurMemoryManager >> isIndexableFormat: format [
	^format >= self sixtyFourBitIndexableFormat
]

{ #category : #'object testing' }
SpurMemoryManager >> isIntegerObject: oop [
	"This list records the valid senders of isIntegerObject: as we replace uses of
	  isIntegerObject: by isImmediate: where appropriate."
	(#(	makeBaseFrameFor:
		quickFetchInteger:ofObject:
		frameOfMarriedContext:
		addressCouldBeClassObj:
		isMarriedOrWidowedContext:
		shortPrint:
		bytecodePrimAt
		commonAt:
		loadFloatOrIntFrom:
		positive32BitValueOf:
		primitiveExternalCall
		checkedIntegerValueOf:
		bytecodePrimAtPut
		commonAtPut:
		primitiveVMParameter) includes: thisContext sender method selector) ifFalse:
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
	(#() includes: thisContext sender method selector) ifFalse:
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
	self flag: #endianness.
	^((self longAt: objOop) >> self rememberedBitShift bitAnd: 1) ~= 0
]

{ #category : #'class table' }
SpurMemoryManager >> isSegmentSpanningFakeObjectPun [
	^3
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
SpurMemoryManager >> isYoung: objOop [
	^self oop: objOop isLessThan: newSpaceLimit
]

{ #category : #'class table' }
SpurMemoryManager >> knownClassAtIndex: classIndex [
	self assert: (classIndex between: 1 and: self classTablePageSize).
	^self fetchPointer: classIndex ofObject: classTableFirstPage
]

{ #category : #'header format' }
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
	fmt <= self lastPointerFormat ifTrue:
		[(fmt = self indexablePointersFormat
		  and: [self isContextNonImm: objOop]) ifTrue:
			["contexts end at the stack pointer"
			contextSize := coInterpreter fetchStackPointerOf: objOop.
			^CtxtTempFrameStart + contextSize * BytesPerOop].
		^(self numSlotsOf: objOop) * BytesPerOop  "all pointers"].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	numLiterals := coInterpreter literalCountOf: objOop.
	^numLiterals + LiteralStart * BytesPerOop
]

{ #category : #'debug support' }
SpurMemoryManager >> leakCheckFullGC [
	<api>
	^(checkForLeaks bitAnd: 1) ~= 0
]

{ #category : #'object access' }
SpurMemoryManager >> lengthOf: objOop [
	"Answer the number of indexable bytes or words in the given object.
	 For a CompiledMethod, the size of the method header (in bytes) should be subtracted from the result."

	<api>
	| header |
	<var: #header type: #usqLong>
	<inline: true>
	<asmLabel: false> 
	header := self baseHeader: objOop.
	^self lengthOf: objOop baseHeader: header format: (self formatOfHeader: header)
]

{ #category : #'object access' }
SpurMemoryManager >> lengthOf: objOop baseHeader: header format: fmt [ 
	<var: #header type: #usqLong>
	"Compatibility; does not really suit the Spur format.
	 Answer the number of indexable bytes or words in the given object.
	 For a CompiledMethod, the size of the method header (in bytes) should
	 be subtracted from the result of this method."
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

{ #category : #'header format' }
SpurMemoryManager >> longFormatForNumBytes: numBytes [
	^self subclassResponsibility
]

{ #category : #accessing }
SpurMemoryManager >> needGCFlag [
	^needGCFlag
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

{ #category : #'header format' }
SpurMemoryManager >> nonIndexablePointerFormat [
	^2
]

{ #category : #'object enumeration' }
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
	| halfHeader numSlots |
	self flag: #endianness.
	halfHeader := self longAt: objOop + 4.
	numSlots := halfHeader >> self numSlotsHalfShift bitAnd: self numSlotsMask.
	^numSlots = self numSlotsMask
		ifTrue: [self longAt: objOop - self baseHeaderSize] "overflow slots; (2^32)-1 slots are plenty"
		ifFalse: [numSlots]
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
	^self subclassResponsibility
]

{ #category : #'object enumeration' }
SpurMemoryManager >> objectStartingAt: address [
	"For enumerating objects find the header of the first object in a space.
	 If the object starts with an overflow size field it will start at the next allocationUnit.
	 c.f. numSlotsOf:"
	| halfHeader numSlots |
	self flag: #endianness.
	halfHeader := self longAt: address + 4.
	numSlots := halfHeader >> self numSlotsHalfShift bitAnd: self numSlotsMask.
	^numSlots = self numSlotsMask
		ifTrue: [address + self baseHeaderSize]
		ifFalse: [address]
]

{ #category : #'header format' }
SpurMemoryManager >> overflowSlotsMask [
	^self subclassResponsibility
]

{ #category : #'store check' }
SpurMemoryManager >> possibleRootStoreInto: destObj value: valueOop [
	(#(	storePointer:ofObject:withValue:) includes: thisContext sender method selector) ifFalse:
		[self halt].
	(self isRemembered: destObj) ifFalse:
		[scavenger remember: destObj.
		 self setIsRememberedOf: destObj to: true]
]

{ #category : #'debug printing' }
SpurMemoryManager >> printHeaderTypeOf: objOop [
	coInterpreter print: ((self numSlotsOf: objOop) >= self numSlotsMask
							ifTrue: ['8 byte header']
							ifFalse: ['16 byte header'])
]

{ #category : #'header format' }
SpurMemoryManager >> rememberedBitShift [
	"lsb of 3-bit field above format (little endian)"
	^29
]

{ #category : #'debug support' }
SpurMemoryManager >> scavenger [
	<doNotGenerate>
	^scavenger
]

{ #category : #'header access' }
SpurMemoryManager >> setHashBitsOf: objOop to: hash [
	self flag: #endianness.
	self assert: (hash between: 0 and: self identityHashHalfWordMask).
	self longAt: objOop + 4
		put: ((self longAt: objOop + 4) bitClear: self identityHashHalfWordMask) + hash
]

{ #category : #'header access' }
SpurMemoryManager >> setIsRememberedOf: objOop to: aBoolean [
	self flag: #endianness.
	self longAt: objOop
		put: (aBoolean
				ifTrue: [(self longAt: objOop) bitOr: 1 << self rememberedBitShift]
				ifFalse: [(self longAt: objOop) bitAnd: (1 << self rememberedBitShift) bitInvert32])
]

{ #category : #accessing }
SpurMemoryManager >> signalLowSpace [
	^signalLowSpace
]

{ #category : #'header format' }
SpurMemoryManager >> sixtyFourBitIndexableFormat [
	^9
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

{ #category : #'object access' }
SpurMemoryManager >> storeByte: byteIndex ofObject: oop withValue: valueByte [
	^self byteAt: oop + BaseHeaderSize + byteIndex put: valueByte
]

{ #category : #'object access' }
SpurMemoryManager >> storeLong32: fieldIndex ofObject: obj withValue: valueWord [
	^self long32At: obj + self baseHeaderSize + (fieldIndex << 2) put: valueWord
]

{ #category : #'object access' }
SpurMemoryManager >> storePointer: fieldIndex ofObject: oop withValue: valuePointer [
	"Note must check here for stores of young objects into old ones."
	^self subclassResponsibility
]

{ #category : #'object access' }
SpurMemoryManager >> storePointerUnchecked: fieldIndex ofObject: oop withValue: valuePointer [
	^self subclassResponsibility
]

{ #category : #allocation }
SpurMemoryManager >> sufficientSpaceToInstantiate: classObj indexableSize: indexableFields [
	self shouldNotImplement
]

{ #category : #accessing }
SpurMemoryManager >> tenuringThreshold [
	"In the scavenger the tenuring threshold is effectively a number of bytes of objects,
	 accessed as a proportion of pastSpace from 0 to 1.   In the Squeak image the tenuring
	 threshold is an object count. Marry the two notions  by multiplying the proportion by
	 the size of pastSpace and dividing by the average object size, as derived from observation."
	| averageObjectSize |
	averageObjectSize := 8 * self wordSize.
	^scavenger scavengerTenuringThreshold * (scavenger pastSpace limit - scavenger pastSpace start) // averageObjectSize
]

{ #category : #accessing }
SpurMemoryManager >> tenuringThreshold: threshold [
	"c.f. tenuringThreshold"
	scavenger scavengerTenuringThreshold:
		(threshold * 8 * self wordSize) asFloat
		/ (scavenger pastSpace limit - scavenger pastSpace start) asFloat
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

{ #category : #'class table' }
SpurMemoryManager >> weakArrayClassIndexPun [
	"Class puns are class indices not used by any class.  There is an entry
	 for the pun that refers to the notional class of objects with this class
	 index.  But because the index doesn't match the class it won't show up
	 in allInstances, hence hiding the object with a pun as its class index.
	 The puns occupy indices 16 through 31."
	^17
]

{ #category : #'header format' }
SpurMemoryManager >> weakArrayFormat [
	^4
]
