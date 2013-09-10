Class {
	#name : #Spur32BitMemoryManager,
	#superclass : #SpurMemoryManager,
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #'word size' }
Spur32BitMemoryManager class >> wordSize [
	^4
]

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
		[freeStart + numBytes > scavenger eden limit ifTrue:
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

{ #category : #allocation }
Spur32BitMemoryManager >> fillObj: objOop numSlots: numSlots with: fillValue [
	objOop + self baseHeaderSize
		to: objOop + self baseHeaderSize + (numSlots * 4) - 1
		by: self allocationUnit
		do: [:p|
			self assert: p < (self addressAfter: objOop).
			self longAt: p put: fillValue;
				longAt: p + 4 put: fillValue]
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

{ #category : #allocation }
Spur32BitMemoryManager >> initSpaceForAllocationCheck: aNewSpace [
	CheckObjectOverwrite ifTrue:
		[aNewSpace start
			to: aNewSpace limit
			by: self wordSize
			do: [:p| self longAt: p put: p]]
]

{ #category : #allocation }
Spur32BitMemoryManager >> instantiateClass: classObj indexableSize: nElements [
	| instSpec classFormat numSlots classIndex newObj fillValue |
	classFormat := self formatOfClass: classObj.
	instSpec := self instSpecOfClassFormat: classFormat.
	fillValue := 0.
	instSpec caseOf: {
		[self arrayFormat]	->
			[numSlots := nElements.
			 fillValue := nilObj].
		[self indexablePointersFormat]	->
			[numSlots := (self fixedFieldsOfClassFormat: classFormat) + nElements.
			 fillValue := nilObj].
		[self sixtyFourBitIndexableFormat]	->
			[numSlots := nElements * 2].
		[self firstLongFormat]	->
			[numSlots := nElements].
		[self firstShortFormat]	->
			[numSlots := nElements + 1 // 2.
			 instSpec := instSpec + (nElements bitAnd: 1)].
		[self firstByteFormat]	->
			[numSlots := nElements + 3 // 4.
			 instSpec := instSpec + (nElements bitAnd: 3)].
		[self firstCompiledMethodFormat]	->
			[numSlots := nElements + 3 // 4.
			 instSpec := instSpec + (nElements bitAnd: 3)] }
		otherwise: [^nil]. "non-indexable"
	classIndex := self hashBitsOf: classObj.
	classIndex = 0 ifTrue:
		[(self enterIntoClassTable: classObj) ifFalse:
			[^nil].
		classIndex := self hashBitsOf: classObj].
	newObj := self allocateSlots: numSlots format: instSpec classIndex: classIndex.
	newObj ifNotNil:
		[self fillObj: newObj numSlots: numSlots with: fillValue].
	^newObj
]

{ #category : #immediates }
Spur32BitMemoryManager >> integerObjectOf: value [
	"Convert the integer value, assumed to be in SmallInteger range, into a tagged SmallInteger object.
	 In C, use a shift and an add to set the tag bit.
	 In Smalltalk we have to work harder because the simulator works with strictly positive bit patterns."

	^self
		cCode: [value << 1 + 1]
		inSmalltalk: [value >= 0
						ifTrue: [value << 1 + 1]
						ifFalse: [16r80000000 + value << 1 + 1]]
]

{ #category : #immediates }
Spur32BitMemoryManager >> integerValueOf: oop [
	"Translator produces 'oop >> 1'"
	^(oop bitShift: -31) = 1 "tests top bit"
		ifTrue: "negative"
			[((oop bitShift: -1) bitAnd: 16r3FFFFFFF) - 16r3FFFFFFF - 1  "Faster than -16r40000000 (a LgInt)"]
		ifFalse: "positive"
			[oop bitShift: -1]
]

{ #category : #'interpreter access' }
Spur32BitMemoryManager >> isIntegerValue: intValue [
	"Answer if the given value can be represented as a Smalltalk integer value.
	 In C, use a shift and XOR to set the sign bit if and only if the top two bits of the given
	 value are the same, then test the sign bit. Note that the top two bits are equal for
	 exactly those integers in the range that can be represented in 31-bits or 63-bits."
	<api>
	^self
		cCode: [(intValue bitXor: (intValue << 1)) >= 0]
		inSmalltalk: [intValue >= 16r-40000000 and: [intValue <= 16r3FFFFFFF]]
]

{ #category : #'header access' }
Spur32BitMemoryManager >> isWordsNonImm: objOop [
	"Answer if the argument contains only indexable words (no oops). See comment in formatOf:"

	^(self formatOf: objOop) = self firstLongFormat
]

{ #category : #'header format' }
Spur32BitMemoryManager >> longFormatForNumBytes: numBytes [
	^self firstLongFormat
]

{ #category : #'object access' }
Spur32BitMemoryManager >> numTagBits [
	^2
]

{ #category : #'object enumeration' }
Spur32BitMemoryManager >> objectAfter: objOop limit: limit [
	"Object parsing.
	1. all objects have at least a word following the header, for a forwarding pointer.
	2. objects with an overflow size have a preceeing word with a saturated numSlots.  If the word
	   following an object doesn't have a saturated numSlots field it must be a single-header object.
	   If the word following does have a saturated numSlots it must be the overflow size word."
	| followingWordAddress followingWord |
	followingWordAddress := self addressAfter: objOop.
	followingWordAddress >= limit ifTrue:
		[^limit].
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
Spur32BitMemoryManager >> storePointer: fieldIndex ofObject: objOop withValue: valuePointer [
	"Note must check here for stores of young objects into old ones."

	(self isYoung: objOop) ifFalse: "most stores into young objects"
		[(self isImmediate: valuePointer) ifFalse:
			[(self isYoung: valuePointer) ifTrue:
				[self possibleRootStoreInto: objOop value: valuePointer]]].

	^self
		longAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'object access' }
Spur32BitMemoryManager >> storePointerUnchecked: fieldIndex ofObject: oop withValue: valuePointer [
	^self
		longAt: oop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'word size' }
Spur32BitMemoryManager >> tagMask [
	^3
]

{ #category : #'word size' }
Spur32BitMemoryManager >> wordSize [
	^4
]
