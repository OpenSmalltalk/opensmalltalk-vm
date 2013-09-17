Class {
	#name : #Spur64BitMemoryManager,
	#superclass : #SpurMemoryManager,
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #'word size' }
Spur64BitMemoryManager class >> wordSize [
	^8
]

{ #category : #'object enumeration' }
Spur64BitMemoryManager >> addressAfter: objOop [
	"Answer the address immediately following an object."
	| numSlots slotBytes |
	numSlots := self numSlotsOf: objOop.
	slotBytes := numSlots = 0
					ifTrue: [self allocationUnit]
					ifFalse: [numSlots << self shiftForWord].
	^objOop + self baseHeaderSize + slotBytes
]

{ #category : #initialization }
Spur64BitMemoryManager >> adjustFieldsAndClassOf: oop by: offsetBytes [ 
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
Spur64BitMemoryManager >> allocateSlots: numSlots format: formatField classIndex: classIndex [
	| numBytes newObj |
	"Object headers are 8 bytes in length if the slot size fits in the num slots field (max implies overflow),
	 16 bytes otherwise (num slots in preceeding word).
	 Objects always have at least one slot, for the forwarding pointer,
	 and are multiples of 8 bytes in length."
	numSlots >= self numSlotsMask
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
		freeStart := freeStart + numBytes.
	^newObj
]

{ #category : #'object enumeration' }
Spur64BitMemoryManager >> bytesInObject: objOop [
	"Answer the total number of bytes in an object including header and possible overflow size header."
	| halfHeader headerNumSlots numSlots |
	self flag: #endianness.
	"numSlotsOf: should not be applied to free or forwarded objects."
	self assert: (self classIndexOf: objOop) > self isForwardedObjectClassIndexPun.
	halfHeader := self longAt: objOop + 4.
	headerNumSlots := halfHeader >> self numSlotsHalfShift bitAnd: self numSlotsMask.
	numSlots := headerNumSlots = self numSlotsMask
					ifTrue: [self longAt: objOop - self baseHeaderSize]
					ifFalse: [numSlots = 0 ifTrue: [1] ifFalse: [numSlots]].
	^numSlots << self shiftForWord
	+ (headerNumSlots = self numSlotsMask
		ifTrue: [self baseHeaderSize + self baseHeaderSize]
		ifFalse: [self baseHeaderSize])
]

{ #category : #'header format' }
Spur64BitMemoryManager >> bytesPerSlot [
	^8
]

{ #category : #'header access' }
Spur64BitMemoryManager >> classIndexOf: objOop [
	^(self longLongAt: objOop) bitAnd: self classIndexMask
]

{ #category : #'object access' }
Spur64BitMemoryManager >> fetchPointer: fieldIndex ofObject: objOop [
	self assert: (self isForwarded: objOop) not.
	^self longLongAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
]

{ #category : #'object access' }
Spur64BitMemoryManager >> formatOf: objOop [
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
	^(self longLongAt: objOop) >> self formatShift bitAnd: self formatMask
]

{ #category : #'garbage collection' }
Spur64BitMemoryManager >> initFreeChunkWithSlots: numSlots at: address [ 
	self flag: #endianness.
	self longAt: address put: self numSlotsMask << self numSlotsFullShift + numSlots;
		longAt: address + 8 put: self numSlotsMask << self numSlotsFullShift. "0's classIndex; 0 = classIndex of free chunks"
	^address + 8
]

{ #category : #allocation }
Spur64BitMemoryManager >> instantiateClass: classObj indexableSize: nElements [
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
			[numSlots := nElements].
		[self firstLongFormat]	->
			[numSlots := nElements + 1 // 2.
			 instSpec := instSpec + (nElements bitAnd: 1)].
		[self firstShortFormat]	->
			[numSlots := nElements + 3 // 4.
			 instSpec := instSpec + (nElements bitAnd: 3)].
		[self firstByteFormat]	->
			[numSlots := nElements + 7 // 8.
			 instSpec := instSpec + (nElements bitAnd: 7)].
		[self firstCompiledMethodFormat]	->
			[numSlots := nElements + 7 // 8.
			 instSpec := instSpec + (nElements bitAnd: 7)] }
		otherwise: [^nil]. "non-indexable"
	classIndex := self ensureBehaviorHash: classObj.
	classIndex < 0 ifTrue:
		[coInterpreter primitiveFailFor: classIndex negated.
		 ^nil].
	newObj := self allocateSlots: numSlots format: instSpec classIndex: classIndex.
	newObj ifNotNil:
		[self fillObj: newObj numSlots: numSlots with: fillValue].
	^newObj
]

{ #category : #immediates }
Spur64BitMemoryManager >> integerObjectOf: value [
	"Convert the integer value, assumed to be in SmallInteger range, into a tagged SmallInteger object.
	 In C, use a shift and an add to set the tag bit.
	 In Smalltalk we have to work harder because the simulator works with strictly positive bit patterns."

	^self
		cCode: [value << self numTagBits + 1]
		inSmalltalk: [value << self numTagBits
					+ (value >= 0
						ifTrue: [1]
						ifFalse: [16r8000000000000001])]
]

{ #category : #immediates }
Spur64BitMemoryManager >> integerValueOf: oop [
	"Translator produces 'oop >> 1'"
	^(oop bitShift: -63) = 1 "tests top bit"
		ifTrue: "negative"
			[((oop bitShift: self numTagBits negated) bitAnd: 16r3FFFFFFFFFFFFFFF) - 16r3FFFFFFFFFFFFFFF - 1  "Faster than -16r4000000000000000 (a LgInt)"]
		ifFalse: "positive"
			[oop bitShift: self numTagBits negated]
]

{ #category : #'header access' }
Spur64BitMemoryManager >> isWordsNonImm: objOop [
	"Answer if the argument contains only indexable words (no oops). See comment in formatOf:"

	^(self formatOf: objOop) between: self firstLongFormat and: self firstLongFormat + 1
]

{ #category : #'header format' }
Spur64BitMemoryManager >> longFormatForNumBytes: numBytes [
	"Answer firstLongFormat with the odd bit set if numBytes is an odd number of 4-byte units."
	^self firstLongFormat + (numBytes >> 2 bitAnd: 1)
]

{ #category : #'object access' }
Spur64BitMemoryManager >> numTagBits [
	"4th bit reserved for object alignment, which could imply e.g. what space the object is in."
	^3
]

{ #category : #'object enumeration' }
Spur64BitMemoryManager >> objectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object with the given
	 number of slots, including header and possible overflow size header."
	^numSlots << self shiftForWord
	+ (numSlots >= self numSlotsMask
		ifTrue: [self baseHeaderSize + self baseHeaderSize]
		ifFalse: [self baseHeaderSize])
]

{ #category : #'word size' }
Spur64BitMemoryManager >> shiftForWord [
	^3
]

{ #category : #'object access' }
Spur64BitMemoryManager >> storePointer: fieldIndex ofObject: objOop withValue: valuePointer [
	"Note must check here for stores of young objects into old ones."
	self assert: (self isForwarded: objOop) not.

	(self isYoung: objOop) ifFalse: "most stores into young objects"
		[(self isImmediate: valuePointer) ifFalse:
			[(self isYoung: valuePointer) ifTrue:
				[self possibleRootStoreInto: objOop]]].

	^self
		longLongAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'object access' }
Spur64BitMemoryManager >> storePointerUnchecked: fieldIndex ofObject: objOop withValue: valuePointer [
	self assert: (self isForwarded: objOop) not.
	^self
		longLongAt: objOop + self baseHeaderSize + (fieldIndex << self shiftForWord)
		put: valuePointer
]

{ #category : #'word size' }
Spur64BitMemoryManager >> tagMask [
	^7
]

{ #category : #'word size' }
Spur64BitMemoryManager >> wordSize [
	^8
]
