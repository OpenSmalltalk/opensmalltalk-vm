Class {
	#name : #Spur64BitMemoryManager,
	#superclass : #SpurMemoryManager,
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #accessing }
Spur64BitMemoryManager class >> objectRepresentationClass [
	^CogObjectRepresentationFor64BitSpur
]

{ #category : #'word size' }
Spur64BitMemoryManager class >> wordSize [
	^8
]

{ #category : #'object enumeration' }
Spur64BitMemoryManager >> addressAfter: objOop [
	"Answer the address immediately following an object."
	| numSlots slotBytes |
	numSlots := self numSlotsOfAny: objOop.
	slotBytes := numSlots = 0
					ifTrue: [self allocationUnit]
					ifFalse: [numSlots << self shiftForWord].
	^objOop + self baseHeaderSize + slotBytes
]

{ #category : #allocation }
Spur64BitMemoryManager >> allocateNewSpaceSlots: numSlots format: formatField classIndex: classIndex [
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
		[needGCFlag ifFalse: [self scheduleScavenge].
		 freeStart + numBytes > scavenger eden limit ifTrue:
			[^self error: 'no room in eden for allocateNewSpaceSlots:format:classIndex:']].
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
		[needGCFlag ifFalse: [self scheduleScavenge].
		 freeStart + numBytes > scavenger eden limit ifTrue:
			[^self allocateSlotsInOldSpace: numSlots bytes: numBytes format: formatField classIndex: classIndex]].
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

{ #category : #allocation }
Spur64BitMemoryManager >> allocateSlotsInOldSpace: numSlots bytes: totalBytes format: formatField classIndex: classIndex [
	"Answer the oop of a chunk of space in oldSpace with numSlots slots.  The header
	 will have been filled-in but not the contents."
	| chunk |
	chunk := self allocateOldSpaceChunkOfBytes: totalBytes.
	chunk ifNil:
		[^nil].
	numSlots >= self numSlotsMask ifTrue: "for header parsing we put a saturated slot count in the prepended overflow size word"
		[self longAt: chunk
			put: numSlots + (self numSlotsMask << self numSlotsFullShift).
		 self longAt: chunk + self baseHeaderSize
			put: (self headerForSlots: self numSlotsMask format: formatField classIndex: classIndex).
		 ^chunk + self baseHeaderSize].
	self longAt: chunk
		put: (self headerForSlots: numSlots format: formatField classIndex: classIndex).
	^chunk
]

{ #category : #'object enumeration' }
Spur64BitMemoryManager >> bytesInObject: objOop [
	"Answer the total number of bytes in an object including header and possible overflow size header."
	| header headerNumSlots numSlots |
	<var: 'header' type: #usqLong>
	self flag: #endianness.
	header := self longAt: objOop.
	headerNumSlots := header >> self numSlotsFullShift.
	numSlots := headerNumSlots = self numSlotsMask
					ifTrue: [header bitAnd: 16rFFFFFFFFFFFFFF]
					ifFalse: [headerNumSlots = 0 ifTrue: [1] ifFalse: [headerNumSlots]].
	^numSlots << self shiftForWord
	+ (headerNumSlots = self numSlotsMask
		ifTrue: [self baseHeaderSize + self baseHeaderSize]
		ifFalse: [self baseHeaderSize])
]

{ #category : #'header format' }
Spur64BitMemoryManager >> bytesPerSlot [
	^8
]

{ #category : #instantiation }
Spur64BitMemoryManager >> fillObj: objOop numSlots: numSlots with: fillValue [
	self assert: (objOop + self baseHeaderSize + (numSlots * self bytesPerOop) - 1)
				< (self addressAfter: objOop).
	objOop + self baseHeaderSize
		to: objOop + self baseHeaderSize + (numSlots * self bytesPerOop) - 1
		by: self allocationUnit
		do: [:p| self longAt: p put: fillValue]
]

{ #category : #'free space' }
Spur64BitMemoryManager >> initFreeChunkWithBytes: numBytes at: address [
	<var: #numBytes type: #usqLong>
	| numSlots |
	"must have room for a header (single or double) plus the next free pointer"
	self assert: (numBytes \\ self allocationUnit = 0
				 and: [numBytes >= (self baseHeaderSize + self wordSize)]).
	"double header"
	numBytes >= (self numSlotsMask << self shiftForWord) ifTrue:
		[numSlots := numBytes - self baseHeaderSize - self baseHeaderSize >> self shiftForWord.
		 self longAt: address put: self numSlotsMask << self numSlotsFullShift + numSlots;
			longAt: address + 8 put: self numSlotsMask << self numSlotsFullShift. "0's classIndex; 0 = classIndex of free chunks"
		^address + 8].
	"single header"
	numSlots := numBytes - self baseHeaderSize >> self shiftForWord.
	self longAt: address put: numSlots << self numSlotsFullShift. "0's classIndex; 0 = classIndex of free chunks"
	^address
]

{ #category : #instantiation }
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
		[self weakArrayFormat]	->
			[numSlots := (self fixedFieldsOfClassFormat: classFormat) + nElements.
			 fillValue := nilObj].
		[self sixtyFourBitIndexableFormat]	->
			[numSlots := nElements].
		[self firstLongFormat]	->
			[numSlots := nElements + 1 // 2.
			 instSpec := instSpec + (nElements bitAnd: 1)].
		[self firstShortFormat]	->
			[numSlots := nElements + 3 // 4.
			 instSpec := instSpec + (4 - nElements bitAnd: 3)].
		[self firstByteFormat]	->
			[numSlots := nElements + 7 // 8.
			 instSpec := instSpec + (8 - nElements bitAnd: 7)].
		[self firstCompiledMethodFormat]	->
			[numSlots := nElements + 7 // 8.
			 instSpec := instSpec + (8 - nElements bitAnd: 7)] }
		otherwise: ["some Squeak images include funky fixed subclasses of abstract variable
					 superclasses. e.g. DirectoryEntry as a subclass of ArrayedCollection.
					 Allow fixed classes to be instantiated here iff nElements = 0."
					 (nElements ~= 0 or: [instSpec >= self sixtyFourBitIndexableFormat]) ifTrue:
						[^nil].
					 numSlots := self fixedFieldsOfClassFormat: classFormat]. "non-indexable"
	classIndex := self ensureBehaviorHash: classObj.
	classIndex < 0 ifTrue:
		[coInterpreter primitiveFailFor: classIndex negated.
		 ^nil].
	numSlots > self maxSlotsForNewSpaceAlloc
		ifTrue: [newObj := self allocateSlotsInOldSpace: numSlots format: instSpec classIndex: classIndex]
		ifFalse: [newObj := self allocateSlots: numSlots format: instSpec classIndex: classIndex].
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

{ #category : #'object access' }
Spur64BitMemoryManager >> numSlotsOf: objOop [
	<returnTypeC: #usqLong>
	| numSlots |
	self flag: #endianness.
	"numSlotsOf: should not be applied to free or forwarded objects."
	self assert: (self classIndexOf: objOop) > self isForwardedObjectClassIndexPun.
	numSlots := self rawNumSlotsOf: objOop..
	^numSlots = self numSlotsMask	"overflow slots; (2^56)-1 slots are plenty"
		ifTrue: [((self longAt: objOop - self baseHeaderSize) << 8) asUnsignedLong >> 8]
		ifFalse: [numSlots]
]

{ #category : #'object access' }
Spur64BitMemoryManager >> numTagBits [
	"4th bit reserved for object alignment, which could imply e.g. what space the object is in."
	^3
]

{ #category : #'object enumeration' }
Spur64BitMemoryManager >> objectAfter: objOop limit: limit [
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
	followingWord := self longAt: followingWordAddress.
	^followingWord >> self numSlotsFullShift = self numSlotsMask
		ifTrue: [followingWordAddress + self baseHeaderSize]
		ifFalse: [followingWordAddress]
]

{ #category : #'object enumeration' }
Spur64BitMemoryManager >> objectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object with the given
	 number of slots, including header and possible overflow size header."
	^(numSlots max: 1) << self shiftForWord
	+ (numSlots >= self numSlotsMask
		ifTrue: [self baseHeaderSize + self baseHeaderSize]
		ifFalse: [self baseHeaderSize])
]

{ #category : #simulation }
Spur64BitMemoryManager >> objectRepresentationClass [
	^CogObjectRepresentationFor64BitSpur
]

{ #category : #'object access' }
Spur64BitMemoryManager >> rawNumSlotsOf: objOop [
	<returnTypeC: #usqLong>
	^(self longAt: objOop) asUnsignedLong >> self numSlotsFullShift
]

{ #category : #'header access' }
Spur64BitMemoryManager >> setClassIndexOf: objOop to: classIndex [
	self assert: (classIndex between: 0 and: self classIndexMask).
	self longAt: objOop
		put: ((self longAt: objOop) bitAnd: self classIndexMask bitInvert64)
			+ classIndex
]

{ #category : #'header access' }
Spur64BitMemoryManager >> setFormatOf: objOop to: format [
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
	self assert: (format between: 0 and: self formatMask).
	objOop
		put: ((self longAt: objOop) bitAnd: (self formatMask << self formatShift) bitInvert64)
			+ (format << self formatShift)
]

{ #category : #'header access' }
Spur64BitMemoryManager >> setHashBitsOf: objOop to: hash [
	self assert: (hash between: 0 and: self identityHashFullWordMask).
	self longAt: objOop
		put: ((self longAt: objOop) bitClear: self identityHashFullWordMask) + hash
]

{ #category : #'header access' }
Spur64BitMemoryManager >> setIsPinnedOf: objOop to: aBoolean [
	self longAt: objOop
		put: (aBoolean
				ifTrue: [(self longAt: objOop) bitOr: 1 << self pinnedBitShift]
				ifFalse: [(self longAt: objOop) bitAnd: (1 << self pinnedBitShift) bitInvert64])
]

{ #category : #'header access' }
Spur64BitMemoryManager >> setIsRememberedOf: objOop to: aBoolean [
	self longAt: objOop
		put: (aBoolean
				ifTrue: [(self longAt: objOop) bitOr: 1 << self rememberedBitShift]
				ifFalse: [(self longAt: objOop) bitAnd: (1 << self rememberedBitShift) bitInvert64])
]

{ #category : #'word size' }
Spur64BitMemoryManager >> shiftForWord [
	^3
]

{ #category : #'word size' }
Spur64BitMemoryManager >> tagMask [
	^7
]

{ #category : #'word size' }
Spur64BitMemoryManager >> wordSize [
	^8
]
