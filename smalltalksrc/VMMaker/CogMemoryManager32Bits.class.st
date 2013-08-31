Class {
	#name : #CogMemoryManager32Bits,
	#superclass : #CogMemoryManager,
	#category : #'VMMaker-MemoryManager'
}

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
						+ numSlots + (numSlots bitAnd: 1) * self bytesPerSlot] "roundTo allocationUnit"
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
		ifTrue:
			[self longLongAt: freeStart put: numSlots.
			 self longLongAt: newObj put: (self headerForSlots: self slotSizeMask format: formatField classIndex: classIndex)]
		ifFalse:
			[self longLongAt: newObj put: (self headerForSlots: numSlots format: formatField classIndex: classIndex)].
	freeStart := freeStart + numBytes.
	^newObj
]

{ #category : #'header format' }
CogMemoryManager32Bits >> bytesPerSlot [
	^4
]

{ #category : #'object access' }
CogMemoryManager32Bits >> fetchPointer: fieldIndex ofObject: objOop [
	^self longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
]

{ #category : #'object access' }
CogMemoryManager32Bits >> formatOf: objOop [ 
	^(self longAt: objOop + self wordSize) >> self formatShift bitAnd: self formatMask
]

{ #category : #'object access' }
CogMemoryManager32Bits >> numTagBits [
	^2
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
