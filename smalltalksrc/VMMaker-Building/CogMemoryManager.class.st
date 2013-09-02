"
CogMemoryManager is currently a place-holder for the design of the new Cog VM's object representation and garbage collector.  The goals for the GC are

- efficient object representation a la Eliot Miranda's VisualWorks 64-bit object representation that uses a 64-bit header, eliminating direct class references so that all objects refer to their classes indirectly.  Instead the header contains a constant class index, in a field smaller than a full pointer, These class indices are used in inline and first-level method caches, hence they do not have to be updated on GC (although they do have to be traced to be able to GC classes).  Classes are held in a sparse weak table.  The class table needs only to be indexed by an instance's class index in class hierarchy search, in the class primitive, and in tracing live objects in the heap.  The additional header space is allocated to a much expanded identity hash field, reducing hash efficiency problems in identity collections due to the extremely small (11 bit) hash field in the old Squeak GC.  The identity hash field is also a key element of the class index scheme.  A class's identity hash is its index into the class table, so to create an instance of a class one merely copies its identity hash into the class index field of the new instance.  This implies that when classes gain their identity hash they are entered into the class table and their identity hash is that of a previously unused index in the table.  It also implies that there is a maximum number of classes in the table.  At least for a few years 64k classes should be enough.  A class is entered into the class table in the following operations:
	behaviorHash
	adoptInstance
	instantiate
	become  (i.e. if an old class becomes a new class)
		if target class field's = to original's id hash
		   and replacement's id hash is zero
			enter replacement in class table
behaviorHash is a special version of identityHash that must be implemented in the image by any object that can function as a class (i.e. Behavior).

- more immediate classes.  An immediate Character class would speed up String accessing, especially for WideString, since no instatiation needs to be done on at:put: and no dereference need be done on at:.  In a 32-bit system tag checking is complex since it is thought important to retain 31-bit SmallIntegers.  Hence, as in current Squeak, the least significant bit set implies a SmallInteger, but Characters would likely have a tag pattern of xxx10.  Hence masking with 11 results in two values for SmallInteger, xxx01 and xxx11 (for details see In-line cache probe for immediates below).  30-bit characters are more than adequate for Unicode.  In a 64-bit system we can use the full three bits and usefully implement an immediate Float.  As in VisualWorks a functional representation takes three bits away from the exponent.  Rotating to put the sign bit in the least significant non-tag bit makes expanding and contracting the 8-bit exponent to the 11-bit IEEE double exponent easy ad makes comparing negative and positive zero easier (an immediate Float is zero if its unsigned 64-bits are < 16).  So the representation looks like
	| 8 bit exponent | 52 bit mantissa | sign bit | 3 tag bits |
For details see ""60-bit immediate Floats"" below.


- efficient scavenging.  The current Squeak GC uses a slow pointer-reversal collector that writes every field in live objects three times in each collection, twice in the pointer-reversing heap traversal to mark live objects and once to update the pointer to its new location.  A scavenger writes every field of live data twice in each collection, once as it does a block copy of the object when copying to to space, once as it traverses the live pointers in the to space objects.  Of course the block copy is a relatively cheap write.

- lazy become.  The JIT's use of inline cacheing provides a cheap way of avoiding scanning the heap as part of a become (which is the simple approach to implementing become in a system with direct pointers).  A becomeForward: on a (set of) non-zero-sized object(s) turns the object into a ""corpse"" or ""forwarding object"" whose first (non-header) word/slot is replaced by a pointer to the target of the becomeForward:.  The corpse's class index is set to one that identifies corpses and, because it is a hidden class index, will always fail an inline cache test.  The inline cache failure code is then responsible for following the forwarding pointer chain (these are Iliffe vectors :) ) and resolving to the actual target.  We have yet to determine exactly how this is done (e.g. change the receiver register and/or stack contents and retry the send, perhaps scanning the current activation).  See below on how we deal with becomes on objects with named inst vars.  Note that we probably don't have to worry about zero-sized objects.  These are unlikely to be passed through the FFI (there is nothing to pass :) ) and so will rarely be becommed.  If they do, they can become slowly.  Alternatively we can insist that objects are at least 16 bytes in size (see 8-byte alignment below) so that there will always be space for a forwarding pointer.  Since none of the immediate classes can have non-immediate instances and since we allocate the immediate class indices corresponding to their tag pattern (SmallInteger = 1 & 3, Character = 2, SmallFloat = 5?) we can use all the class indices from 0 to 7 for special uses, 0 = forward, and e.g. 1 = header-sized filler.

- pinning.  To support a robust and easy-to-use FFI the memory manager must support temporary pinning where individual objects can be prevented from being moved by the GC for as long as required, either by being one of an in-progress FFI call's arguments, or by having pinning asserted by a primitive (allowing objects to be passed to external code that retains a reference to the object after returning).  Pinning probably implies a per-object ""is-pinned"" bit in the object header.  Pinning will be done via lazy become; i..e an object in new space will be becommed into a pinned object in old space.  We will only support pinning in old space.

- efficient old space collection.  An incremental collector (a la Dijkstra's three colour algorithm) collects old space, e.g. via an amount of tracing being hung off scavenges and/or old space allocations at an adaptive rate that keeps full garbage collections to a minimum.  (see free space/free list below)

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

For the moment we do not tackle the issue of heap growth and shrinkage with the ability to allocate and deallocate heap segments via memory-mapping.  This technique allows space to be released back to the OS by unmapping empty segments.  We may revisit this but it is not a key requirement for the first implementation.

The basic approach is to use a fixed size new space and a growable old space.  The new space is a classic three-space nursery a la Ungar's Generation Scavenging, a large eden for new objects and two smaller survivor spaces that exchange roles on each collection, one being the to space to which surviving objects are copied, the other being the from space of the survivors of the previous collection, i.e. the previous to space.

To provide apparent pinning in new space we rely on lazy become.  Since most pinned objects will be byte data and these do not require stack zone activation scanning, the overhead is simply an old space allocation and corpsing.

To provide pinning in old space, large objects are implicitly pinned (because it is expensive to move large objects and, because they are both large and relatively rare, they contribute little to overall fragmentation - as in aggregates, small objects can be used to fill-in the spaces between karge objects).  Hence, objects above a particular size are automatically allocated in old space, rather than new space.  Small objects are pinned as per objects in new space, by asserting the pin bit, which will be set automaticaly when allocating a large object.  As a last resort, or by programmer control (the fullGC primitive) old space is collected via mark-sweep (mark-compact) and so the mark phase must build the list of pinned objects around which the sweep/compact phase must carefully step.

Free space in old space is organized by a free list/free tree as in Eliot's VisualWorks 5i old space allocator.  There are 64 free lists, indices 1 through 63 holding blocks of space of that size, index 0 holding a semi-balanced ordered tree of free blocks, each node being the head of the list of free blocks of that size.  At the start of the mark phase the free list is thrown away and the sweep phase coallesces free space and steps over pinned objects as it proceeds.  We can reuse the forwarding pointer compaction scheme used in the old collector.  Incremental collections merely move unmarked objects to the free lists (as well as nilling weak pointers in weak arrays and scheduling them for finalization).  The occupancy of the free lists is represented by a bitmap in a 64-bit integer so that an allocation of size 63 or less can know whether there exists a free chunk of that size, but more importantly can know whether a free chunk larger than it exists in the fixed size free lists without having to search all larger free list heads.

The incremental collector (a la Dijkstra's three colour algorithm) collects old space via an amount of tracing being hung off scavenges and/or old space allocations at an adaptive rate that keeps full garbage collections to a minimum.  [N.B. Not sure how to do this yet.  The incremental collector needs to complete a pass often enough to reclaim objects, but infrequent enough not to waste time.  So some form of feedback should work.  In VisualWorks tracing is broken into quanta or work where image-level code determines the size of a quantum based on how fast the machine is, and how big the heap is.  This code could easily live in the VM, controllable through vmParameterAt:put:.  An alternative would be to use the heartbeat to bound quanta by time.  But in any case some amount of incremental collection would be done on old space allocation and scavenging, the ammount being chosen to keep pause times acceptably short, and at a rate to reclaim old space before a full GC is required, i.e. at a rate proportional to the growth in old space]. The incemental collector is a state machine, being either marking, nilling weak pointers, or freeing.  If nilling weak pointers is not done atomically then there must be a read barrier in weak array at: so that reading from an old space weak array that is holding stale un-nilled references to unmarked objects.  Tricks such as including the weak bit in bounds calculations can make this cheap for non-weak arrays.  Alternatively nilling weak pointers can be made an atomic part of incremental collection, which can be made cheaper by maintaining the set of weak arrays (e.g. on a list).

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
	#name : #CogMemoryManager,
	#superclass : #CogClass,
	#instVars : [
		'coInterpreter',
		'startOfMemory',
		'memory',
		'freeStart',
		'scavengeThreshold',
		'newSpaceLimit',
		'nilObj',
		'falseObj',
		'trueObj',
		'specialObjectsOop',
		'classTableRootObj',
		'endOfMemory',
		'freeLists',
		'freeListMask',
		'endOfOldSpace',
		'newSpaceStart'
	],
	#classVars : [
		'NumFreeLists'
	],
	#pools : [
		'VMBasicConstants',
		'VMObjectIndices',
		'VMSqueakV3BytecodeConstants'
	],
	#category : #'VMMaker-MemoryManager'
}

{ #category : #'class initialization' }
CogMemoryManager class >> initialize [
	"CogObjectMemory initialize"
	NumFreeLists := 65 "One for each size up to and including 64 slots. One for sizes > 64 slots."
]

{ #category : #'object enumeration' }
CogMemoryManager >> addressAfter: objOop [
	"Answer the address immediately following an object."
	^self subclassResponsibility
]

{ #category : #initialization }
CogMemoryManager >> adjustAllOopsBy: bytesToShift [ 
	"Adjust all oop references by the given number of bytes. This 
	is done just after reading in an image when the new base 
	address of the object heap is different from the base address 
	in the image."
	"di 11/18/2000 - return number of objects found"

	| obj |
	<inline: false>
	bytesToShift ~= 0 ifTrue:
		[obj := self firstObject.
		 [self oop: obj isLessThan: freeStart] whileTrue:
			[(self isFreeObject: obj) ifFalse:
				[self adjustFieldsAndClassOf: obj by: bytesToShift].
			 obj := self objectAfter: obj]]
]

{ #category : #initialization }
CogMemoryManager >> adjustFieldsAndClassOf: oop by: offsetBytes [ 
	"Adjust all pointers in this object by the given offset."
	self subclassResponsibility
]

{ #category : #'debug support' }
CogMemoryManager >> allObjectsDo: aBlock [
	<doNotGenerate>
	| prevObj prevPrevObj objOop |
	prevPrevObj := prevObj := nil.
	objOop := self firstObject.
	[self assert: objOop \\ self allocationUnit = 0.
	 objOop < freeStart] whileTrue:
		[(self isFreeObject: objOop) ifFalse:
			[aBlock value: objOop].
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := self objectAfter: objOop].
	prevPrevObj class.
	prevObj class
]

{ #category : #simulation }
CogMemoryManager >> allocateMemoryOfSize: limit [
	<doNotGenerate>
	memory := (self endianness == #little
					ifTrue: [LittleEndianBitmap]
					ifFalse: [Bitmap]) new: (limit roundUpTo: 8).
	freeStart := startOfMemory := 0.
	scavengeThreshold := newSpaceLimit := memory size * 4 "Bitmap is a 4-byte per word array"
]

{ #category : #simulation }
CogMemoryManager >> allocateMemoryOfSize: memoryBytes newSpaceSize: newSpaceBytes codeSize: codeBytes [
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
	scavengeThreshold := memory size * 4 "Bitmap is a 4-byte per word array"
]

{ #category : #allocation }
CogMemoryManager >> allocateSlots: numSlots format: formatField classIndex: classIndex [
	self subclassResponsibility
]

{ #category : #allocation }
CogMemoryManager >> allocationUnit [
	"All objects are a multiple of 8 bytes in length"
	^8
]

{ #category : #'class table' }
CogMemoryManager >> arrayClassIndexPun [
	"Class puns are class indices not used by any class.  There is an entry
	 for the pun that refers to the notional class of objects with this class
	 index.  But because the index doesn't match the class it won't show up
	 in allInstances, hence hiding the object with a pun as its class index.
	 The puns occupy indices 16 through 31."
	^16
]

{ #category : #'header format' }
CogMemoryManager >> arrayFormat [
	^2
]

{ #category : #'header access' }
CogMemoryManager >> baseHeader: obj [
	^self longLongAt: obj
]

{ #category : #'header format' }
CogMemoryManager >> baseHeaderSize [
	"Object headers are 8 bytes in length if the slot size fits in the slot size field (max implies overflow),
	 16 bytes otherwise (slot size in preceeding word)."
	^8
]

{ #category : #'object access' }
CogMemoryManager >> baseSlotSizeOf: oop [
	<returnTypeC: #usqInt>
	| halfHeader slotSize |
	self flag: #endianness.
	halfHeader := self longAt: oop + 4.
	slotSize := halfHeader >> self slotSizeHalfShift bitAnd: self slotSizeMask.
	^slotSize = self slotSizeMask
		ifTrue: [self longAt: oop - self baseHeaderSize] "overflow slots; (2^32)-1 slots are plenty"
		ifFalse: [slotSize]
]

{ #category : #'header format' }
CogMemoryManager >> bytesPerSlot [
	^self subclassResponsibility
]

{ #category : #'object access' }
CogMemoryManager >> characterObjectOf: characterCode [ 
	^characterCode << self numTagBits + self characterTag
]

{ #category : #'object access' }
CogMemoryManager >> characterTag [
	^2
]

{ #category : #'header format' }
CogMemoryManager >> classIndexMask [
	"22-bit class mask => ~ 4M classes"
	^16r3fffff
]

{ #category : #'header access' }
CogMemoryManager >> classIndexOf: objOop [
	^self subclassResponsibility
]

{ #category : #'class table' }
CogMemoryManager >> classTableMajorIndexShift [
	"1024 entries per page (2^10); 22 bit classIndex implies 2^12 pages"
	^10
]

{ #category : #'class table' }
CogMemoryManager >> classTableMinorIndexMask [
	"1024 entries per page (2^10); 22 bit classIndex implies 2^12 pages"
	"self basicNew classTableMinorIndexMask"
	^1 << self classTableMajorIndexShift - 1
]

{ #category : #'class table' }
CogMemoryManager >> classTablePageSize [
	"1024 entries per page (2^10); 22 bit classIndex implies 2^12 pages"
	"self basicNew classTablePageSize"
	^1 << self classTableMajorIndexShift
]

{ #category : #accessing }
CogMemoryManager >> classTableRootObj [
	"For mapInterpreterOops & bootstrap"
	^classTableRootObj
]

{ #category : #accessing }
CogMemoryManager >> classTableRootObj: anOop [
	"For mapInterpreterOops"
	classTableRootObj := anOop
]

{ #category : #simulation }
CogMemoryManager >> coInterpreter: aCoInterpreter [
	<doNotGenerate>
	coInterpreter := aCoInterpreter
]

{ #category : #'class table' }
CogMemoryManager >> ensureBehaviorHash: aBehavior [
	| newHash err |
	self assert: (self isIntegerObject: aBehavior) not.
	(newHash := self hashBitsOf: aBehavior) = 0 ifTrue:
		[(err := self enterIntoClassTable: aBehavior) ~= 0 ifTrue:
			[^err negated].
		 newHash := self hashBitsOf: aBehavior].
	^newHash
]

{ #category : #'class table' }
CogMemoryManager >> enterIntoClassTable: aBehavior [
	"Enter aBehavior into the class table and answer 0.  Otherwise answer a primitive failure code."
	self shouldBeImplemented
]

{ #category : #accessing }
CogMemoryManager >> falseObject [
	^falseObj
]

{ #category : #accessing }
CogMemoryManager >> falseObject: anOop [
	"For mapInterpreterOops"
	falseObj := anOop
]

{ #category : #'object access' }
CogMemoryManager >> fetchLong32: fieldIndex ofObject: oop [
	"index by 32-bit units, and return a 32-bit value. Intended to replace fetchWord:ofObject:"

	^self long32At: oop + self baseHeaderSize + (fieldIndex << 2)
]

{ #category : #'header format' }
CogMemoryManager >> firstCompiledMethodFormat [
	^24
]

{ #category : #'object enumeration' }
CogMemoryManager >> firstObject [
	"Return the first object or free chunk in the heap."

	^nilObj
]

{ #category : #'header format' }
CogMemoryManager >> formatMask [
	^16r1f
]

{ #category : #'object access' }
CogMemoryManager >> formatOf: objOop [
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

{ #category : #'object access' }
CogMemoryManager >> formatOfHeader: header [
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
CogMemoryManager >> formatShift [
	^24
]

{ #category : #accessing }
CogMemoryManager >> freeStart [
	^freeStart
]

{ #category : #'header format' }
CogMemoryManager >> headerForSlots: numSlots format: formatField classIndex: classIndex [ 
	"The header format in LSB is
	 MSB:	| 8: slotSize			| (on a byte boundary)
			| 2 bits				|
			| 22: identityHash	| (on a word boundary)
			| 3 bits				|
			| 5: format			| (on a byte boundary)
			| 2 bits				|
			| 22: classIndex		| (on a word boundary) : LSB
	 The remaining bits (7) need to be used for
		isGrey
		isMarked
		isRemembered
		isPinned
		isImmutable
	 leaving 2 unused bits."
	^ (numSlots << self slotSizeFullShift)
	+ (formatField << self formatShift)
	+ classIndex
]

{ #category : #'header format' }
CogMemoryManager >> identityHashHalfWordMask [
	^16r3fffff
]

{ #category : #'header format' }
CogMemoryManager >> indexablePointersFormat [
	^3
]

{ #category : #'garbage collection' }
CogMemoryManager >> initFreeChunkWithSlots: numSlots at: address [ 
	^self subclassResponsibility
]

{ #category : #initialization }
CogMemoryManager >> initialize [
	freeLists := Array new: NumFreeLists. "gets an extra element in C"
]

{ #category : #initialization }
CogMemoryManager >> initializeObjectMemory: bytesToShift [
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

	self initializeOldSpaceFirstFree: endOfOldSpace. "initializes endOfMemory, freeStart"

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
CogMemoryManager >> initializeOldSpaceFirstFree: startOfFreeOldSpace [
	<var: 'startOfFreeOldSpace' type: #usqLong>
	| freeOldStart freeChunk |
	<var: 'freeOldStart' type: #usqLong>
	1 to: NumFreeLists do:
		[:i| freeLists at: i put: nil].
	freeOldStart := startOfFreeOldSpace.
	[endOfMemory - freeOldStart >= (2 raisedTo: 32)] whileTrue:
		[freeChunk := self initFreeChunkWithSlots: (2 raisedTo: 32) / self wordSize at: freeOldStart.
		self addToFreeList: freeChunk.
		freeOldStart := self addressAfter: freeChunk].
	freeChunk := self initFreeChunkWithSlots: endOfMemory - freeOldStart / self wordSize at: freeOldStart.
	self addToFreeList: freeChunk
]

{ #category : #simulation }
CogMemoryManager >> initializePostBootstrap [
	"The heap has just been bootstrapped into a modified newSpace occupying all of memory above newSPace (and the codeZone).
	 Put things back to some kind of normalicy."
	endOfOldSpace := freeStart.
	freeStart := newSpaceStart
]

{ #category : #'object testing' }
CogMemoryManager >> isCompiledMethod: objOop [
    "Answer whether the argument object is of compiled method format"
	<api>
    ^(self formatOf: objOop) >= 24
]

{ #category : #'header access' }
CogMemoryManager >> isFreeObject: objOop [
	^(self classIndexOf: objOop) = 0
]

{ #category : #'object testing' }
CogMemoryManager >> isImmediate: oop [ 
	^self subclassResponsibility
]

{ #category : #'object testing' }
CogMemoryManager >> isPointersNonImm: objOop [ 
	^(self formatOf: objOop) <= 5
]

{ #category : #'header format' }
CogMemoryManager >> lastPointerFormat [
	^5
]

{ #category : #'object enumeration' }
CogMemoryManager >> lastPointerOf: oop [ 
	"Answer the byte offset of the last pointer field of the given object.
	 Works with CompiledMethods, as well as ordinary objects."
	<api>
	<inline: true>
	<asmLabel: false>
	| fmt header contextSize numLiterals |
	<var: 'header' type: #usqLong>
	header := self baseHeader: oop.
	fmt := self formatOfHeader: header.
	fmt <= self lastPointerFormat ifTrue:
		[(fmt = self indexablePointersFormat
		  and: [self isContextHeader: header]) ifTrue:
			["contexts end at the stack pointer"
			contextSize := coInterpreter fetchStackPointerOf: oop.
			^CtxtTempFrameStart + contextSize * BytesPerOop].
		^(self baseSlotSizeOf: oop) * BytesPerOop  "all pointers"].
	fmt < self firstCompiledMethodFormat ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes"
	numLiterals := coInterpreter literalCountOf: oop.
	^numLiterals + LiteralStart * BytesPerOop
]

{ #category : #'primitive support' }
CogMemoryManager >> nilFieldsOf: obj [ 
	0 to: (self baseSlotSizeOf: obj) - 1 do:
		[:i|
		self storePointerUnchecked: i ofObject: obj withValue: nilObj]
]

{ #category : #accessing }
CogMemoryManager >> nilObject [
	^nilObj
]

{ #category : #accessing }
CogMemoryManager >> nilObject: anOop [
	"For mapInterpreterOops"
	nilObj := anOop
]

{ #category : #'object access' }
CogMemoryManager >> numTagBits [
	^self subclassResponsibility
]

{ #category : #'object enumeration' }
CogMemoryManager >> objectAfter: objOop [
	"Object parsing.
	1. all objects have at least a word following the header, for a forwarding pointer.
	2. objects with an overflow size have a preceeing word with a saturated slotSize.  If the word following
	    an object doesn't have a saturated size field it must be a single-header object.  If the word following
	   does have a saturated slotSize it must be the overflow size word."
	^self subclassResponsibility
]

{ #category : #'header format' }
CogMemoryManager >> overflowSlotsMask [
	^self subclassResponsibility
]

{ #category : #'header access' }
CogMemoryManager >> setHashBitsOf: objOop to: hash [
	self assert: (hash between: 0 and: self identityHashHalfWordMask).
	self longAt: objOop
		put: ((self longAt: objOop) bitClear: self identityHashHalfWordMask) + hash
]

{ #category : #'header format' }
CogMemoryManager >> slotSizeFullShift [
	^56
]

{ #category : #'header format' }
CogMemoryManager >> slotSizeHalfShift [
	^24
]

{ #category : #'header format' }
CogMemoryManager >> slotSizeMask [
	"8-bit slot size:
		max 64-bit small obj size 254 * 8 =  2032 bytes
		max 32-bit small obj size 254 * 4 =   1016 bytes"
	^255
]

{ #category : #accessing }
CogMemoryManager >> specialObjectsOop [
	^specialObjectsOop
]

{ #category : #accessing }
CogMemoryManager >> specialObjectsOop: anObject [
	"For mapInterpreterOops"
	specialObjectsOop := anObject
]

{ #category : #'interpreter access' }
CogMemoryManager >> splObj: index [
	<api>
	<inline: true>
	"Return one of the objects in the specialObjectsArray"
	^self fetchPointer: index ofObject: specialObjectsOop
]

{ #category : #accessing }
CogMemoryManager >> startOfMemory [
	"Return the start of object memory.  This is immediately after the native code zone.
	 N.B. the stack zone is alloca'ed. Use a macro so as not to punish the debug VM."
	<cmacro: '() heapBase'>
	<returnTypeC: #usqInt>
	^coInterpreter ifNil: [startOfMemory] ifNotNil: [coInterpreter heapBase]
]

{ #category : #simulation }
CogMemoryManager >> startOfMemory: value [
	startOfMemory := value.
	(freeStart isNil or: [freeStart < value]) ifTrue:
		[freeStart := value]
]

{ #category : #'object access' }
CogMemoryManager >> storeLong32: fieldIndex ofObject: obj withValue: valueWord [
	^self long32At: obj + self baseHeaderSize + (fieldIndex << 2) put: valueWord
]

{ #category : #'object access' }
CogMemoryManager >> storePointer: fieldIndex ofObject: oop withValue: valuePointer [
	"Note must check here for stores of young objects into old ones."
	^self subclassResponsibility
]

{ #category : #'object access' }
CogMemoryManager >> storePointerUnchecked: fieldIndex ofObject: oop withValue: valuePointer [
	^self subclassResponsibility
]

{ #category : #accessing }
CogMemoryManager >> trueObject [
	^trueObj
]

{ #category : #accessing }
CogMemoryManager >> trueObject: anOop [
	"For mapInterpreterOops"
	trueObj := anOop
]

{ #category : #'class table' }
CogMemoryManager >> weakArrayClassIndexPun [
	"Class puns are class indices not used by any class.  There is an entry
	 for the pun that refers to the notional class of objects with this class
	 index.  But because the index doesn't match the class it won't show up
	 in allInstances, hence hiding the object with a pun as its class index.
	 The puns occupy indices 16 through 31."
	^17
]

{ #category : #'header format' }
CogMemoryManager >> weakArrayFormat [
	^4
]
