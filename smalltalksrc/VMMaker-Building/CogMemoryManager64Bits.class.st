Class {
	#name : #CogMemoryManager64Bits,
	#superclass : #CogMemoryManager,
	#category : #'VMMaker-MemoryManager'
}

{ #category : #'object enumeration' }
CogMemoryManager64Bits >> addressAfter: objOop [
	"Answer the address immediately following an object."
	| rawSlotSize slotBytes |
	rawSlotSize := self baseSlotSizeOf: objOop.
	slotBytes := rawSlotSize = 0
					ifTrue: [self allocationUnit]
					ifFalse: [rawSlotSize << self shiftForWord].
	^objOop + self baseHeaderSize + slotBytes
]

{ #category : #initialization }
CogMemoryManager64Bits >> adjustFieldsAndClassOf: oop by: offsetBytes [ 
	"Adjust all pointers in this object by the given offset."
	| fieldAddr fieldOop |
	<inline: true>
	<asmLabel: false>
	fieldAddr := oop + (self lastPointerOf: oop).
	[self oop: fieldAddr isGreaterThan: oop] whileTrue:
		[fieldOop := self longAt: fieldAddr.
		 (self isIntegerObject: fieldOop) ifFalse:
			[self longLongAt: fieldAddr put: fieldOop + offsetBytes].
		 fieldAddr := fieldAddr - BytesPerWord]
]

{ #category : #allocation }
CogMemoryManager64Bits >> allocateSlots: numSlots format: formatField classIndex: classIndex [
	| numBytes newObj |
	"Object headers are 8 bytes in length if the slot size fits in the slot size field (max implies overflow),
	 16 bytes otherwise (slot size in preceeding word).
	 Objects always have at least one slot, for the forwarding pointer,
	 and are multiples of 8 bytes in length."
	numSlots >= self slotSizeMask
		ifTrue:
			[numSlots > 16rffffffff ifTrue:
				[^nil].
			 newObj := freeStart + self baseHeaderSize.
			 numBytes := (self baseHeaderSize + self baseHeaderSize) "double header"
						+ (numSlots * self bytesPerSlot)]
		ifFalse:
			[newObj := freeStart.
			 numBytes := self baseHeaderSize "single header"
						+ (numSlots < 1
							ifTrue: [self allocationUnit] "at least one slot for the forwarding pointer"
							ifFalse: [numSlots * self bytesPerSlot])].
	
	freeStart + numBytes > scavengeThreshold ifTrue:
		[freeStart + numBytes > newSpaceLimit ifTrue:
			[^self allocateSlotsInOldSpace: numSlots format: formatField classIndex: classIndex].
		 self scheduleScavenge].
	numSlots >= self slotSizeMask
		ifTrue: "for header parsing we put a saturated slot count in the prepended overflow size word"
			[self flag: #endianness.
			 self longAt: freeStart put: numSlots.
			 self longAt: freeStart + 4 put: self slotSizeMask << self slotSizeHalfShift.
			 self longLongAt: newObj put: (self headerForSlots: self slotSizeMask format: formatField classIndex: classIndex)]
		ifFalse:
			[self longLongAt: newObj put: (self headerForSlots: numSlots format: formatField classIndex: classIndex)].
		freeStart := freeStart + numBytes.
	^newObj
]

{ #category : #'header format' }
CogMemoryManager64Bits >> bytesPerSlot [
	^8
]

{ #category : #'header access' }
CogMemoryManager64Bits >> classIndexOf: objOop [
	^(self longLongAt: objOop) bitAnd: self classIndexMask
]

{ #category : #'object access' }
CogMemoryManager64Bits >> fetchPointer: fieldIndex ofObject: objOop [
	^self longLongAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
]

{ #category : #'object access' }
CogMemoryManager64Bits >> formatOf: objOop [
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
	^(self longLongAt: objOop) >> self formatShift bitAnd: self formatMask
]

{ #category : #'garbage collection' }
CogMemoryManager64Bits >> initFreeChunkWithSlots: numSlots at: address [ 
	self flag: #endianness.
	self longAt: address put: self slotSizeMask << self slotSizeFullShift + numSlots;
		longAt: address + 8 put: self slotSizeMask << self slotSizeFullShift. "0's classIndex; 0 = classIndex of free chunks"
	^address + 8
]

{ #category : #'object testing' }
CogMemoryManager64Bits >> isImmediate: oop [ 
	^(oop bitAnd: 7) ~= 0
]

{ #category : #'object access' }
CogMemoryManager64Bits >> numTagBits [
	"4th bit reserved for object alignment, which could imply e.g. what space the object is in."
	^3
]

{ #category : #'object enumeration' }
CogMemoryManager64Bits >> objectAfter: objOop [
	"Object parsing.
	1. all objects have at least a word following the header, for a forwarding pointer.
	2. objects with an overflow size have a preceeing word with a saturated slotSize.  If the word following
	    an object doesn't have a saturated size field it must be a single-header object.  If the word following
	   does have a saturated slotSize it must be the overflow size word."
	| followingWordAddress followingWord |
	followingWordAddress := self addressAfter: objOop.
	followingWordAddress >= freeStart ifTrue:
		[^freeStart].
	self flag: #endianness.
	followingWord := self longAt: followingWordAddress + 4.
	^followingWord >> self slotSizeHalfShift = self slotSizeMask
		ifTrue: [followingWordAddress + self baseHeaderSize]
		ifFalse: [followingWordAddress]
]

{ #category : #'word size' }
CogMemoryManager64Bits >> shiftForWord [
	^3
]

{ #category : #'object access' }
CogMemoryManager64Bits >> storePointer: fieldIndex ofObject: oop withValue: valuePointer [
	"Note must check here for stores of young objects into old ones."

	(self oop: oop isLessThan: newSpaceLimit) ifFalse: "most stores into young objects"
		[(self isImmediate: valuePointer) ifFalse:
			[(self oop: valuePointer isLessThan: newSpaceLimit) ifTrue:
				[self possibleRootStoreInto: oop value: valuePointer]]].

	^self
		longLongAt: oop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'object access' }
CogMemoryManager64Bits >> storePointerUnchecked: fieldIndex ofObject: oop withValue: valuePointer [
	^self
		longLongAt: oop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'word size' }
CogMemoryManager64Bits >> wordSize [
	^8
]
