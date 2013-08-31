Class {
	#name : #CogMemoryManager64Bits,
	#superclass : #CogMemoryManager,
	#category : #'VMMaker-MemoryManager'
}

{ #category : #allocation }
CogMemoryManager64Bits >> allocateSlots: numSlots format: formatField classIndex: classIndex [
	| numBytes newObj |
	"Object headers are 8 bytes in length if the slot size fits in the slot size field (max implies overflow),
	 16 bytes otherwise (slot size in preceeding word).
	 Objects always have at least one slot, for the forwarding pointer,
	 and are multiples of 8 bytes in length."
	numSlots >= self slotSizeMask
		ifTrue:
			[newObj := freeStart + self baseHeaderSize.
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
		ifTrue:
			[self longLongAt: freeStart put: numSlots.
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

{ #category : #'object access' }
CogMemoryManager64Bits >> fetchPointer: fieldIndex ofObject: objOop [
	^self longLongAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
]

{ #category : #'object access' }
CogMemoryManager64Bits >> formatOf: objOop [ 
	^(self longLongAt: objOop) >> self formatShift bitAnd: self formatMask
]

{ #category : #'object access' }
CogMemoryManager64Bits >> numTagBits [
	"4th bit reserved for object alignment, which could imply e.g. what space the object is in."
	^3
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
