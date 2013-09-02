Class {
	#name : #Spur32BitMemoryManager,
	#superclass : #SpurMemoryManager,
	#category : #'VMMaker-MemoryManager'
}

{ #category : #'object enumeration' }
Spur32BitMemoryManager >> addressAfter: objOop [
	"Answer the address immediately following an object."
	| numSlots slotBytes |
	numSlots := self numSlotsOf: objOop.
	slotBytes := numSlots = 0
					ifTrue: [self allocationUnit]
					ifFalse: [numSlots + (numSlots bitAnd: 1) << self shiftForWord].
	^objOop + self baseHeaderSize + slotBytes
]

{ #category : #initialization }
Spur32BitMemoryManager >> adjustFieldsAndClassOf: oop by: offsetBytes [ 
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
Spur32BitMemoryManager >> allocateSlots: numSlots format: formatField classIndex: classIndex [
	| numBytes newObj |
	"Object headers are 8 bytes in length if the slot size fits in the num slots field (max implies overflow),
	 16 bytes otherwise (slot size in preceeding word).
	 Objects always have at least one slot, for the forwarding pointer,
	 and are multiples of 8 bytes in length."
	numSlots >= self numSlotsMask
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
	numSlots >= self numSlotsMask
		ifTrue: "for header parsing we put a saturated slot count in the prepended overflow size word"
			[self flag: #endianness.
			 self longAt: freeStart put: numSlots.
			 self longAt: freeStart + 4 put: self numSlotsMask << self numSlotsHalfShift.
			 self longLongAt: newObj put: (self headerForSlots: self numSlotsMask format: formatField classIndex: classIndex)]
		ifFalse:
			[self longLongAt: newObj put: (self headerForSlots: numSlots format: formatField classIndex: classIndex)].
	self assert: numBytes \\ self allocationUnit = 0.
	self assert: newObj \\ self allocationUnit = 0.
	freeStart := freeStart + numBytes.
	^newObj
]

{ #category : #'object enumeration' }
Spur32BitMemoryManager >> bytesInObject: objOop [
	"Answer the total number of bytes in an object including header and possible overflow size header."
	| halfHeader headerNumSlots numSlots |
	self flag: #endianness.
	halfHeader := self longAt: objOop + 4.
	headerNumSlots := halfHeader >> self numSlotsHalfShift bitAnd: self numSlotsMask.
	numSlots := headerNumSlots = self numSlotsMask
					ifTrue: [self longAt: objOop - self baseHeaderSize]
					ifFalse: [numSlots = 0 ifTrue: [1] ifFalse: [numSlots]].
	^numSlots + (numSlots bitAnd: 1) << self shiftForWord
	+ (headerNumSlots = self numSlotsMask
		ifTrue: [self baseHeaderSize + self baseHeaderSize]
		ifFalse: [self baseHeaderSize])
]

{ #category : #'header format' }
Spur32BitMemoryManager >> bytesPerSlot [
	^4
]

{ #category : #'header access' }
Spur32BitMemoryManager >> classIndexOf: objOop [
	self flag: #endianness.
	^(self longAt: objOop) bitAnd: self classIndexMask
]

{ #category : #'object access' }
Spur32BitMemoryManager >> fetchPointer: fieldIndex ofObject: objOop [
	^self longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
]

{ #category : #'object access' }
Spur32BitMemoryManager >> formatOf: objOop [
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
Spur32BitMemoryManager >> initFreeChunkWithSlots: numSlots at: address [ 
	self flag: #endianness.
	self longAt: address put: numSlots;
		longAt: address + 4 put: self numSlotsMask << self numSlotsHalfShift;
		longAt: address + 8 put: 0; "0's classIndex; 0 = classIndex of free chunks"
		longAt: address + 12 put: self numSlotsMask << self numSlotsHalfShift.
	^address + 8
]

{ #category : #'object testing' }
Spur32BitMemoryManager >> isImmediate: oop [ 
	^(oop bitAnd: 3) ~= 0
]

{ #category : #'object access' }
Spur32BitMemoryManager >> numTagBits [
	^2
]

{ #category : #'object enumeration' }
Spur32BitMemoryManager >> objectAfter: objOop [
	"Object parsing.
	1. all objects have at least a word following the header, for a forwarding pointer.
	2. objects with an overflow size have a preceeing word with a saturated numSlots.  If the word
	   following an object doesn't have a saturated numSlots field it must be a single-header object.
	   If the word following does have a saturated numSlots it must be the overflow size word."
	| followingWordAddress followingWord |
	followingWordAddress := self addressAfter: objOop.
	followingWordAddress >= freeStart ifTrue:
		[^freeStart].
	self flag: #endianness.
	followingWord := self longAt: followingWordAddress + 4.
	^followingWord >> self numSlotsHalfShift = self numSlotsMask
		ifTrue: [followingWordAddress + self baseHeaderSize]
		ifFalse: [followingWordAddress]
]

{ #category : #'word size' }
Spur32BitMemoryManager >> shiftForWord [
	^2
]

{ #category : #'object access' }
Spur32BitMemoryManager >> storePointer: fieldIndex ofObject: oop withValue: valuePointer [
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
Spur32BitMemoryManager >> storePointerUnchecked: fieldIndex ofObject: oop withValue: valuePointer [
	^self
		longAt: oop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'word size' }
Spur32BitMemoryManager >> wordSize [
	^4
]
