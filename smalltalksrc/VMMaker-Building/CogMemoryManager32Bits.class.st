Class {
	#name : #CogMemoryManager32Bits,
	#superclass : #CogMemoryManager,
	#category : #'VMMaker-MemoryManager'
}

{ #category : #'object enumeration' }
CogMemoryManager32Bits >> addressAfter: objOop [
	"Answer the address immediately following an object."
	| rawSlotSize slotBytes |
	rawSlotSize := self baseSlotSizeOf: objOop.
	slotBytes := rawSlotSize = 0
					ifTrue: [self allocationUnit]
					ifFalse: [rawSlotSize + (rawSlotSize bitAnd: 1) << self shiftForWord].
	^objOop + self baseHeaderSize + slotBytes
]

{ #category : #initialization }
CogMemoryManager32Bits >> adjustFieldsAndClassOf: oop by: offsetBytes [ 
	"Adjust all pointers in this object by the given offset."
	| fieldAddr fieldOop |
	<inline: true>
	<asmLabel: false>
	fieldAddr := oop + (self lastPointerOf: oop).
	[self oop: fieldAddr isGreaterThanOrEqualTo: oop + self baseHeaderSize] whileTrue:
		[fieldOop := self longAt: fieldAddr.
		 (self isImmediate: fieldOop) ifFalse:
			[self longAt: fieldAddr put: fieldOop + offsetBytes].
		 fieldAddr := fieldAddr - BytesPerOop]
]

{ #category : #allocation }
CogMemoryManager32Bits >> allocateSlots: numSlots format: formatField classIndex: classIndex [
	| numBytes newObj |
	"Object headers are 8 bytes in length if the slot size fits in the slot size field (max implies overflow),
	 16 bytes otherwise (slot size in preceeding word).
	 Objects always have at least one slot, for the forwarding pointer,
	 and are multiples of 8 bytes in length."
	numSlots >= self slotSizeMask
		ifTrue:
			[newObj := freeStart + self baseHeaderSize.
			 numBytes := self baseHeaderSize + self baseHeaderSize "double header"
						+ (numSlots + (numSlots bitAnd: 1) * self bytesPerSlot)] "roundTo allocationUnit"
		ifFalse:
			[newObj := freeStart.
			 numBytes := self baseHeaderSize "single header"
						+ (numSlots <= 1
							ifTrue: [self allocationUnit] "at least one slot for the forwarding pointer"
							ifFalse: [numSlots + (numSlots bitAnd: 1) * self bytesPerSlot])]. "roundTo allocationUnit"
	self assert: numBytes \\ self allocationUnit = 0.
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
	self assert: numBytes \\ self allocationUnit = 0.
	self assert: newObj \\ self allocationUnit = 0.
	freeStart := freeStart + numBytes.
	^newObj
]

{ #category : #'header format' }
CogMemoryManager32Bits >> bytesPerSlot [
	^4
]

{ #category : #'header access' }
CogMemoryManager32Bits >> classIndexOf: objOop [
	self flag: #endianness.
	^(self longAt: objOop) bitAnd: self classIndexMask
]

{ #category : #'object access' }
CogMemoryManager32Bits >> fetchPointer: fieldIndex ofObject: objOop [
	^self longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
]

{ #category : #'object access' }
CogMemoryManager32Bits >> formatOf: objOop [
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
	self flag: #endianness.
	^(self longAt: objOop) >> self formatShift bitAnd: self formatMask
]

{ #category : #'garbage collection' }
CogMemoryManager32Bits >> initFreeChunkWithSlots: numSlots at: address [ 
	self flag: #endianness.
	self longAt: address put: numSlots;
		longAt: address + 4 put: self slotSizeMask << self slotSizeHalfShift;
		longAt: address + 8 put: 0; "0's classIndex; 0 = classIndex of free chunks"
		longAt: address + 12 put: self slotSizeMask << self slotSizeHalfShift.
	^address + 8
]

{ #category : #'object testing' }
CogMemoryManager32Bits >> isImmediate: oop [ 
	^(oop bitAnd: 3) ~= 0
]

{ #category : #'object access' }
CogMemoryManager32Bits >> numTagBits [
	^2
]

{ #category : #'object enumeration' }
CogMemoryManager32Bits >> objectAfter: objOop [
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
CogMemoryManager32Bits >> shiftForWord [
	^2
]

{ #category : #'object access' }
CogMemoryManager32Bits >> storePointer: fieldIndex ofObject: oop withValue: valuePointer [
	"Note must check here for stores of young objects into old ones."

	(self oop: oop isLessThan: newSpaceLimit) ifFalse: "most stores into young objects"
		[(self isImmediate: valuePointer) ifFalse:
			[(self oop: valuePointer isLessThan: newSpaceLimit) ifTrue:
				[self possibleRootStoreInto: oop value: valuePointer]]].

	^self
		longAt: oop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'object access' }
CogMemoryManager32Bits >> storePointerUnchecked: fieldIndex ofObject: oop withValue: valuePointer [
	^self
		longAt: oop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'word size' }
CogMemoryManager32Bits >> wordSize [
	^4
]
