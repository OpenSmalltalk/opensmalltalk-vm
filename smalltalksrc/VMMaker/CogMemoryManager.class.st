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

- efficient scavenging.  The current Squeak GC uses a slow pointer-reversal collector that writes every field in live objects three times in each collection, twice in the pointer-reversing heap traversal to mark live objects and once to update the pointer to its new location.  A scavenger writes every field of live data twice in each collection, once as it does a block copy of the object when copying to to space, once as it traverses the live pointers in the to space objects.  Of course the block copy is a relatively cheap write.

- lazy become.  The JIT's use of inline cacheing provides a cheap way of avoiding scanning the heap as part of a become (which is the simple approach to implementing become in a system with direct pointers).  A becomeForward: on a (set of) non-zero-sized object(s) turns the object into a ""corpse"" or ""forwarding object"" whose first word is replaced by a pointer to the target of the becomeForward:.  The corpse's class index is set to one that identifies corpses and, because it is a hidden class index, will always fail an inline cache test.  The inline cache failure code is then responsible for following the forwarding pointer chain (these are Iliffe vectors :) ) and resolving to the actual target.  We have yet to determine exactly how this is done (e.g. change the receiver register and/or stack contents and retry the send, perhaps scanning the current activation).  See below on how we deal with becomes on objects with named inst vars.  Note that we probably don't have to worry about zero-sized objects.  These are unlikely to be passed through the FFI (there is nothing to pass :) ) and so will rarely be becommed.  If they do, they can become slowly.

- pinning.  To support a robust and easy-to-use FFI the memory manager must support temporary pinning where individual objects can be prevented from being moved by the GC for as long as required, either by being one of an in-progress FFI call's arguments, or by having pinning asserted by a primitive (allowing objects to be passed to external code that retains a reference to the object after returning).  Pinning probably implies a per-object ""is-pinned"" bit in the object header.  Pinning will be done via lazy become; i..e an object in new space will be becommed into a pinned object in old space.  We will only support pinning in old space..

- efficient old space collection.  An incremental collector (a la Dijkstra's three colour algorithm) collects old space, e.g. via an amount of tracing being hung off scavenges and/or old space allocations at an adaptive rate that keeps full garbage collections to a minimum.  (see free space/free list below)

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

As described earlier the basic idea behind lazy become is to use corpses (forwarding objects) that are followed lazily during GC and inline cache miss.  However, a lazy scheme cannot be used on objects with named inst vars without adding checking to all inst var accesses, which we judge too expensive.  Instead, when becomming objects with named inst vars, we scan all activations in the stack zone, eagerly becomming these references, and we check for corpses when faulting in a context into the stack zone.  Essentially, the invariant is that there are no refereces to corpses from the receiver slots of stack activations.  A detail is whether we allow or forbid pinning of closure indirection vectors, or scan the entire stack of each activation.  Using a special class index pun for indirection vectors is a cheap way of preventing their becomming/pinning etc.  Although ""don't do that"" (don't attempt to pin/become indirection vectors) is also an accetabe response.


Issues:
Are class indices in inline caches strong references to classes or weak references?
If strong then they must be scanned during GC and the methodZone must be flushed on fullGC to reclaim all classes (this looks to be a bug in the V3 Cogit).
If weak then when the class table loses references, PICs containing freed classes must be freed and then sends to freed PICs or containing freed clases must be unlinked.
The second approach is faster; the common case is scanning the class table, the uncommon case is freeing classes.  The second approach is better; in-line caches do not prevent reclamation of classes.
"
Class {
	#name : #CogMemoryManager,
	#superclass : #VMClass,
	#instVars : [
		'coInterpreter'
	],
	#category : #'VMMaker-MemoryManager'
}

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
