Class {
	#name : #Spur64BitMemoryManager,
	#superclass : #SpurMemoryManager,
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #'simulation only' }
Spur64BitMemoryManager class >> isImmediate: anObject [
	self flag: 'The float range is close but probably wrong. Revisit when immediate floats are implemented'.
	^anObject class == SmallInteger
	  or: [anObject class == Character
	  or: [anObject class == Float and: [anObject exponent between: -128 and: 127]]]
]

{ #category : #'simulation only' }
Spur64BitMemoryManager class >> numSmallIntegerTagBits [
	^3
]

{ #category : #'simulation only' }
Spur64BitMemoryManager class >> simulatorClass [
	^Spur64BitMMLESimulator
]

{ #category : #'word size' }
Spur64BitMemoryManager class >> wordSize [
	"Answer the manager's word size, which is the size of an oop, and which
	 is assumed to be equivalent to the underlying machine's word size."
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
Spur64BitMemoryManager >> allocateSlots: numSlots format: formatField classIndex: classIndex [
	"Allocate an object with numSlots space.  If there is room beneath scavengeThreshold
	 allocate in newSpace, otherwise alocate in oldSpace.  If there is not room in newSpace
	 and a scavenge is not already scheduled, schedule a scavenge."
	<inline: true>
	| numBytes newObj |
	"Object headers are 8 bytes in length if the slot size fits in the num slots field (max implies overflow),
	 16 bytes otherwise (num slots in preceeding word).
	 Objects always have at least one slot, for the forwarding pointer,
	 and are multiples of 8 bytes in length."
	numSlots >= self numSlotsMask
		ifTrue:
			[numSlots >> 56 > 0 ifTrue:
				[^nil]. "overflow size must fit in 56-bits"
			 newObj := freeStart + self baseHeaderSize.
			 numBytes := self largeObjectBytesForSlots: numSlots]
		ifFalse:
			[newObj := freeStart.
			 numBytes := self smallObjectBytesForSlots: numSlots].
	
	freeStart + numBytes > scavengeThreshold ifTrue:
		[needGCFlag ifFalse: [self scheduleScavenge].
		 ^self allocateSlotsInOldSpace: numSlots bytes: numBytes format: formatField classIndex: classIndex].
	numSlots >= self numSlotsMask
		ifTrue: "for header parsing we put a saturated slot count in the prepended overflow size word"
			[self flag: #endianness.
			 self longAt: freeStart put: self numSlotsMask << self numSlotsFullShift + numSlots.
			 self longAt: newObj put: (self headerForSlots: self numSlotsMask format: formatField classIndex: classIndex)]
		ifFalse:
			[self longAt: newObj put: (self headerForSlots: numSlots format: formatField classIndex: classIndex)].
	self assert: numBytes \\ self allocationUnit = 0.
	self assert: newObj \\ self allocationUnit = 0.
	freeStart := freeStart + numBytes.
	^newObj
]

{ #category : #allocation }
Spur64BitMemoryManager >> allocateSlotsForPinningInOldSpace: numSlots bytes: totalBytes format: formatField classIndex: classIndex [
	"Answer the oop of a chunk of space in oldSpace with numSlots slots.  Try and
	 allocate in a segment that already includes pinned objects.  The header of the
	 result will have been filled-in but not the contents."
	<var: #totalBytes type: #usqInt>
	<inline: false>
	| chunk |
	chunk := self allocateOldSpaceChunkOfBytes: totalBytes
				   suchThat: [:f| (segmentManager segmentContainingObj: f) containsPinned].
	chunk ifNil:
		[chunk := self allocateOldSpaceChunkOfBytes: totalBytes].
	self checkFreeSpace.
	chunk ifNil:
		[^nil].
	numSlots >= self numSlotsMask ifTrue: "for header parsing we put a saturated slot count in the prepended overflow size word"
		[self longAt: chunk
			put: numSlots + (self numSlotsMask << self numSlotsFullShift).
		 self longAt: chunk + self baseHeaderSize
			put: ((self headerForSlots: self numSlotsMask format: formatField classIndex: classIndex)
					bitOr: 1 << self pinnedBitShift).
		 ^chunk + self baseHeaderSize].
	self longAt: chunk
		put: ((self headerForSlots: numSlots format: formatField classIndex: classIndex)
				bitOr: 1 << self pinnedBitShift).
	^chunk
]

{ #category : #allocation }
Spur64BitMemoryManager >> allocateSlotsInOldSpace: numSlots bytes: totalBytes format: formatField classIndex: classIndex [
	"Answer the oop of a chunk of space in oldSpace with numSlots slots.  The header
	 will have been filled-in but not the contents.  If no memory is available answer nil."
	<var: #totalBytes type: #usqInt>
	<inline: false>
	| chunk |
	chunk := self allocateOldSpaceChunkOfBytes: totalBytes.
	self checkFreeSpace.
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

{ #category : #snapshot }
Spur64BitMemoryManager >> byteSwapped: w [
	"Answer the given integer with its bytes in the reverse order."
	<api>
	<returnTypeC: #sqInt>
	^  ((w bitShift: Byte7ShiftNegated) bitAnd: Byte0Mask)
	 + ((w bitShift: Byte5ShiftNegated) bitAnd: Byte1Mask)
	 + ((w bitShift: Byte3ShiftNegated) bitAnd: Byte2Mask)
	 + ((w bitShift: Byte1ShiftNegated) bitAnd: Byte3Mask)
	 + ((w bitShift: Byte1Shift             ) bitAnd: Byte4Mask)
	 + ((w bitShift: Byte3Shift             ) bitAnd: Byte5Mask)
	 + ((w bitShift: Byte5Shift             ) bitAnd: Byte6Mask)
	 + ((w bitShift: Byte7Shift             ) bitAnd: Byte7Mask)
]

{ #category : #'object enumeration' }
Spur64BitMemoryManager >> bytesInObject: objOop [
	"Answer the total number of bytes in an object including header and possible overflow size header."
	<returnTypeC: #usqInt>
	| header headerNumSlots numSlots |
	<var: 'header' type: #usqLong>
	self flag: #endianness.
	header := self longAt: objOop.
	headerNumSlots := header >> self numSlotsFullShift.
	numSlots := headerNumSlots = self numSlotsMask
					ifTrue: [self rawOverflowSlotsOf: objOop]
					ifFalse: [headerNumSlots = 0 ifTrue: [1] ifFalse: [headerNumSlots]].
	^numSlots << self shiftForWord
	+ (headerNumSlots = self numSlotsMask
		ifTrue: [self baseHeaderSize + self baseHeaderSize]
		ifFalse: [self baseHeaderSize])
]

{ #category : #accessing }
Spur64BitMemoryManager >> bytesPerOop [
	^8
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> changeClassOf: rcvr to: argClass [
	"Attempt to change the class of the receiver to the argument given that the
	 format of the receiver matches the format of the argument.  If successful,
	 answer 0, otherwise answer an error code indicating the reason for failure. 
	 Fail if the format of the receiver is incompatible with the format of the argument,
	 or if the argument is a fixed class and the receiver's size differs from the size
	 that an instance of the argument should have."
	<inline: false>
	| classFormat fixedFields instFormat normalizedInstFormat newFormat classIndex |
	classFormat := self formatOfClass: argClass.
	fixedFields := self fixedFieldsOfClassFormat: classFormat.
	classFormat := self instSpecOfClassFormat: classFormat.
	instFormat := self formatOf: rcvr.
	normalizedInstFormat := self classFormatForInstanceFormat: instFormat.

	(normalizedInstFormat > self lastPointerFormat
	 and: [normalizedInstFormat = classFormat])
		ifTrue: [newFormat := instFormat]
		ifFalse:
			[normalizedInstFormat <= self lastPointerFormat
				ifTrue:
					[classFormat > self lastPointerFormat ifTrue:
						[^PrimErrInappropriate].
					 (self numSlotsOf: rcvr) < fixedFields ifTrue:
						[^PrimErrBadReceiver].
					 newFormat := classFormat]
				ifFalse:
					[| instBytes |
					instBytes := self numBytesOf: rcvr.
					normalizedInstFormat caseOf: {
						[self sixtyFourBitIndexableFormat] ->
							[(classFormat < self sixtyFourBitIndexableFormat
							  or: [classFormat >= self firstCompiledMethodFormat]) ifTrue:
								[^PrimErrInappropriate].
							 newFormat := classFormat].
						[self firstLongFormat] ->
							[(classFormat < self sixtyFourBitIndexableFormat
							  or: [classFormat >= self firstCompiledMethodFormat]) ifTrue:
								[^PrimErrInappropriate].
							 (classFormat = self sixtyFourBitIndexableFormat and: [instBytes anyMask: 1]) ifTrue:
								[^PrimErrBadReceiver].
							 newFormat := classFormat].
						[self firstShortFormat] ->
							[(classFormat < self sixtyFourBitIndexableFormat
							  or: [classFormat >= self firstCompiledMethodFormat]) ifTrue:
								[^PrimErrInappropriate].
							 classFormat caseOf: {
								[self sixtyFourBitIndexableFormat]
									-> [(instBytes anyMask: 7) ifTrue: [^PrimErrBadReceiver].
										newFormat := classFormat].
								[self firstLongFormat] 		
									-> [(instBytes anyMask: 3) ifTrue: [^PrimErrBadReceiver].
										newFormat := classFormat + (2 - instBytes bitAnd: 1)].
								[self firstByteFormat] 		
									-> [newFormat := classFormat + (8 - instBytes bitAnd: 7)] }].
						[self firstByteFormat] ->
							[(classFormat < self sixtyFourBitIndexableFormat
							  or: [classFormat >= self firstCompiledMethodFormat]) ifTrue:
								[^PrimErrInappropriate].
							 classFormat caseOf: {
								[self sixtyFourBitIndexableFormat]
									-> [(instBytes anyMask: 7) ifTrue: [^PrimErrBadReceiver].
										newFormat := classFormat].
								[self firstLongFormat] 		
									-> [(instBytes anyMask: 3) ifTrue: [^PrimErrBadReceiver].
										newFormat := classFormat + (2 - instBytes bitAnd: 1)].
								[self firstShortFormat] 		
									-> [(instBytes anyMask: 1) ifTrue: [^PrimErrBadReceiver].
										newFormat := classFormat + (4 - instBytes bitAnd: 3)] }.
							 newFormat := classFormat].
						[self firstCompiledMethodFormat] ->
							[classFormat ~= self firstCompiledMethodFormat ifTrue:
								[^PrimErrInappropriate].
							 newFormat := instFormat] }]].

	(classIndex := self ensureBehaviorHash: argClass) < 0 ifTrue:
		[^classIndex negated].
	self set: rcvr classIndexTo: classIndex formatTo: newFormat.
	"ok"
	^0
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> fetchClassTagOf: oop [
	| tagBits |
	^(tagBits := oop bitAnd: self tagMask) ~= 0
		ifTrue: [tagBits]
		ifFalse: [self classIndexOf: oop]
]

{ #category : #instantiation }
Spur64BitMemoryManager >> fillObj: objOop numSlots: numSlots with: fillValue [
	<inline: true>
	<var: #p type: #usqInt>
	self assert: (self oop: objOop + self baseHeaderSize + (numSlots * self bytesPerOop) - 1
					isLessThan: (self addressAfter: objOop)).
	(objOop + self baseHeaderSize) asUnsignedInteger
		to: (objOop + self baseHeaderSize + (numSlots * self bytesPerOop) - 1) asUnsignedInteger
		by: self allocationUnit
		do: [:p| self longAt: p put: fillValue]
]

{ #category : #'header access' }
Spur64BitMemoryManager >> identityHashFullWordMask [
	^16r3fffff00000000
]

{ #category : #'header access' }
Spur64BitMemoryManager >> identityHashFullWordShift [
	^32
]

{ #category : #'free space' }
Spur64BitMemoryManager >> initFreeChunkWithBytes: numBytes at: address [
	<var: #numBytes type: #usqLong>
	| numSlots |
	"must have room for a header (single or double) plus the next free pointer"
	self assert: (numBytes \\ self allocationUnit = 0
				 and: [numBytes >= (self baseHeaderSize + self bytesPerOop)]).
	"double header"
	numBytes >= ((self numSlotsMask << self shiftForWord) + self baseHeaderSize) ifTrue:
		[numSlots := numBytes - self baseHeaderSize - self baseHeaderSize >> self shiftForWord.
		 self longAt: address put: self numSlotsMask << self numSlotsFullShift + numSlots;
			longAt: address + 8 put: self numSlotsMask << self numSlotsFullShift. "0's classIndex; 0 = classIndex of free chunks"
		^address + 8].
	"single header"
	numSlots := numBytes - self baseHeaderSize >> self shiftForWord.
	self assert: numSlots < self numSlotsMask.
	self longAt: address put: numSlots << self numSlotsFullShift. "0's classIndex; 0 = classIndex of free chunks"
	^address
]

{ #category : #segments }
Spur64BitMemoryManager >> initSegmentBridgeWithBytes: numBytes at: address [
	<var: #numBytes type: #usqLong>
	| numSlots |
	"must have room for a double header"
	self assert: (numBytes \\ self allocationUnit = 0
				 and: [numBytes >= (self baseHeaderSize + self baseHeaderSize)]).
	numSlots := numBytes - self baseHeaderSize - self baseHeaderSize >> self shiftForWord.
	numSlots = 0
		ifTrue: "short bridge for adjacent segments"
			[self longAt: address
					put:    (1 << self pinnedBitShift)
						+ (1 << self markedBitFullShift)
						+ (self wordIndexableFormat << self formatShift)
						+ self segmentBridgePun]
		ifFalse: "long bridge"
			[self longAt: address
					put: self numSlotsMask << self numSlotsFullShift + numSlots;
				longAt: address + self baseHeaderSize
					put: (self numSlotsMask << self numSlotsFullShift)
						+ (1 << self pinnedBitShift)
						+ (1 << self markedBitFullShift)
						+ (self wordIndexableFormat << self formatShift)
						+ self segmentBridgePun]
]

{ #category : #instantiation }
Spur64BitMemoryManager >> instantiateClass: classObj indexableSize: nElements [
	<var: #nElements type: #usqInt>
	"Allocate an instance of a variable class, excepting CompiledMethod."
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
			 instSpec := instSpec + (8 - nElements bitAnd: 7)] }
		otherwise: ["some Squeak images include funky fixed subclasses of abstract variable
					 superclasses. e.g. DirectoryEntry as a subclass of ArrayedCollection.
					 Allow fixed classes to be instantiated here iff nElements = 0."
					 (nElements ~= 0 or: [instSpec > self lastPointerFormat]) ifTrue:
						[^nil].
					 numSlots := self fixedFieldsOfClassFormat: classFormat]. "non-indexable"
	classIndex := self ensureBehaviorHash: classObj.
	classIndex < 0 ifTrue:
		[coInterpreter primitiveFailFor: classIndex negated.
		 ^nil].
	numSlots > self maxSlotsForNewSpaceAlloc
		ifTrue:
			[numSlots > self maxSlotsForAlloc ifTrue:
				[^nil].
			 newObj := self allocateSlotsInOldSpace: numSlots format: instSpec classIndex: classIndex]
		ifFalse:
			[newObj := self allocateSlots: numSlots format: instSpec classIndex: classIndex].
	newObj ifNotNil:
		[self fillObj: newObj numSlots: numSlots with: fillValue].
	^newObj
]

{ #category : #instantiation }
Spur64BitMemoryManager >> instantiateCompiledMethodClass: classObj indexableSize: nElements [
	<var: #nElements type: #usqInt>
	"Allocate an instance of a CompiledMethod class."
	<inline: true>
	| instSpec classFormat numSlots classIndex newObj |
	classFormat := self formatOfClass: classObj.
	instSpec := self instSpecOfClassFormat: classFormat.
	instSpec ~= self firstCompiledMethodFormat ifTrue:
		[^nil].
	numSlots := nElements + 7 // 8.
	instSpec := instSpec + (8 - nElements bitAnd: 7).
	classIndex := self ensureBehaviorHash: classObj.
	classIndex < 0 ifTrue:
		[coInterpreter primitiveFailFor: classIndex negated.
		 ^nil].
	numSlots > self maxSlotsForNewSpaceAlloc
		ifTrue:
			[numSlots > self maxSlotsForAlloc ifTrue:
				[^nil].
			 newObj := self allocateSlotsInOldSpace: numSlots format: instSpec classIndex: classIndex]
		ifFalse:
			[newObj := self allocateSlots: numSlots format: instSpec classIndex: classIndex].
	newObj ifNotNil:
		[self fillObj: newObj numSlots: numSlots with: 0].
	^newObj
]

{ #category : #immediates }
Spur64BitMemoryManager >> integerObjectOf: value [
	"Convert the integer value, assumed to be in SmallInteger range, into a tagged SmallInteger object.
	 In C, use a shift and an add to set the tag bit.
	 In Smalltalk we have to work harder because the simulator works with strictly positive bit patterns."
	<returnTypeC: #sqInt>
	^self
		cCode: [value << self numTagBits + 1]
		inSmalltalk: [value << self numTagBits
					+ (value >= 0
						ifTrue: [1]
						ifFalse: [16r10000000000000001])]
]

{ #category : #immediates }
Spur64BitMemoryManager >> integerValueOf: oop [
	"Translator produces 'oop >> 3'"
	^(oop bitShift: -63) = 1 "tests top bit"
		ifTrue: "negative"
			[((oop bitShift: self numTagBits negated) bitAnd: 16r1FFFFFFFFFFFFFFF) - 16r1FFFFFFFFFFFFFFF - 1  "Faster than -16r4000000000000000 (a LgInt)"]
		ifFalse: "positive"
			[oop bitShift: self numTagBits negated]
]

{ #category : #'object testing' }
Spur64BitMemoryManager >> isIntegerObject: oop [
	^(oop bitAnd: self tagMask) = 1
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> isIntegerValue: intValue [
	"Answer if the given value can be represented as a Smalltalk integer value.
	 In 64-bits we use a 3 bit tag which leaves 61 bits for 2's complement signed
	 integers. In C, use a shift add and mask to test if the top 4 bits are all the same."
	<api>
	^self
		cCode: [(intValue >> 60 + 1 bitAnd: 16rF) <= 1]
		inSmalltalk: [intValue >= -16r1000000000000000 and: [intValue <= 16rFFFFFFFFFFFFFFF]]
]

{ #category : #'header access' }
Spur64BitMemoryManager >> isMarked: objOop [
	<api>
	^((self longAt: objOop) >> self markedBitFullShift bitAnd: 1) ~= 0
]

{ #category : #'object testing' }
Spur64BitMemoryManager >> isNonIntegerObject: oop [
	^(oop bitAnd: self tagMask) ~= 1
]

{ #category : #'object testing' }
Spur64BitMemoryManager >> isWordsNonImm: objOop [
	"Answer if the argument contains only indexable words (no oops). See comment in formatOf:"

	^(self formatOf: objOop) between: self firstLongFormat and: self firstLongFormat + 1
]

{ #category : #allocation }
Spur64BitMemoryManager >> largeObjectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object with an overflow header, including header bytes."
	<returnTypeC: #usqInt>
	^self baseHeaderSize + self baseHeaderSize "double header"
	+ (numSlots * self bytesPerOop) "no rounding; bytesPerOop = allocationUnit"
]

{ #category : #accessing }
Spur64BitMemoryManager >> logBytesPerOop [
	^3
]

{ #category : #instantiation }
Spur64BitMemoryManager >> maxSlotsForAlloc [
	"Answer the maximum number of slots we are willing to attempt to allocate in an object.
	 Must fit in 32-bits; c.f. bytesInObject:"
	^1024*1024*1024*1024
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> methodDictionaryHash: oop mask: mask [
	<inline: true>
	^mask bitAnd: ((self isImmediate: oop)
						ifTrue: [self integerValueOf: oop] "this will fail for ShortFloat but we don't care"
						ifFalse: [self hashBitsOf: oop])
]

{ #category : #'free space' }
Spur64BitMemoryManager >> numFreeLists [
	"Answer the number of free lists.  We use freeListsMask, a bitmap, to avoid
	 reading empty list heads.  This should fit in a machine word to end up in a
	 register during free chunk allocation."
	^64
]

{ #category : #allocation }
Spur64BitMemoryManager >> numSlotsForShortening: objOop toIndexableSize: indexableSize [
	<inline: true>
	^(self formatOf: objOop) caseOf:
		{ [self arrayFormat]			-> [indexableSize].
		  [self firstLongFormat]		-> [self numSlotsForBytes: indexableSize * 4].
		  [self firstLongFormat + 1]	-> [self numSlotsForBytes: indexableSize * 4] }
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> numSmallIntegerTagBits [
	^3
]

{ #category : #'object access' }
Spur64BitMemoryManager >> numTagBits [
	<api>
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
	(self oop: followingWordAddress isGreaterThanOrEqualTo: limit) ifTrue:
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
	<returnTypeC: #usqInt>
	^(numSlots max: 1) << self shiftForWord
	+ (numSlots >= self numSlotsMask
		ifTrue: [self baseHeaderSize + self baseHeaderSize]
		ifFalse: [self baseHeaderSize])
]

{ #category : #'object access' }
Spur64BitMemoryManager >> oldRawNumSlotsOf: objOop [
	<returnTypeC: #usqInt>
	<inline: true>
	^(self longAt: objOop) asUnsignedLong >> self numSlotsFullShift
]

{ #category : #'object access' }
Spur64BitMemoryManager >> rawOverflowSlotsOf: objOop [
	<returnTypeC: #usqLong>
	<inline: true>
	self flag: #endianness.
	^self
		cCode: [((self longAt: objOop - self baseHeaderSize) << 8) asUnsignedLong >> 8]
		inSmalltalk: [(self longAt: objOop - self baseHeaderSize) bitAnd: 16rFFFFFFFFFFFFFF]
]

{ #category : #'object access' }
Spur64BitMemoryManager >> rawOverflowSlotsOf: objOop put: numSlots [
	<returnTypeC: #usqLong>
	<inline: true>
	self flag: #endianness.
	self longAt: objOop - self baseHeaderSize
		put: (self byteAt: objOop - 1) << 56 + numSlots.
	^numSlots
]

{ #category : #'header access' }
Spur64BitMemoryManager >> set: objOop classIndexTo: classIndex formatTo: format [
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
	<inline: true>
	self assert: (classIndex between: 0 and: self classIndexMask).
	self assert: (format between: 0 and: self formatMask).
	self longAt: objOop
		put: ((self longAt: objOop) bitAnd: (self formatMask << self formatShift + self classIndexMask) bitInvert64)
			+ (classIndex
			+  (format << self formatShift))
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
Spur64BitMemoryManager >> setIsGreyOf: objOop to: aBoolean [
	self longAt: objOop
		put: (aBoolean
				ifTrue: [(self longAt: objOop) bitOr: 1 << self greyBitShift]
				ifFalse: [(self longAt: objOop) bitAnd: (1 << self greyBitShift) bitInvert64])
]

{ #category : #'header access' }
Spur64BitMemoryManager >> setIsImmutableOf: objOop to: aBoolean [
	self longAt: objOop
		put: (aBoolean
				ifTrue: [(self longAt: objOop) bitOr: 1 << self immutableBitShift]
				ifFalse: [(self longAt: objOop) bitAnd: (1 << self immutableBitShift) bitInvert64])
]

{ #category : #'header access' }
Spur64BitMemoryManager >> setIsMarkedOf: objOop to: aBoolean [
	self assert: (self isFreeObject: objOop) not.
	self longAt: objOop
		put: (aBoolean
				ifTrue: [(self longAt: objOop) bitOr: 1 << self markedBitFullShift]
				ifFalse: [(self longAt: objOop) bitAnd: (1 << self markedBitFullShift) bitInvert64])
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
	<api>
	<cmacro: '() 3'>
	^3
]

{ #category : #allocation }
Spur64BitMemoryManager >> smallObjectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object without an overflow header, including header bytes."
	<returnTypeC: #usqInt>
	^self baseHeaderSize "single header"
	+ (numSlots < 1
		ifTrue: [self allocationUnit] "at least one slot for the forwarding pointer"
		ifFalse: [numSlots * self bytesPerOop])
]

{ #category : #'word size' }
Spur64BitMemoryManager >> tagMask [
	<api>
	^7
]

{ #category : #'header formats' }
Spur64BitMemoryManager >> wordIndexableFormat [
	^self sixtyFourBitIndexableFormat
]

{ #category : #'word size' }
Spur64BitMemoryManager >> wordSize [
	"Answer the manager's word size, which is the size of an oop, and which
	 is assumed to be equivalent to the underlying machine's word size."
	<cmacro: '() 8'>
	^8
]

{ #category : #'class table' }
Spur64BitMemoryManager >> wordSizeClassIndexPun [
	^self sixtyFourBitLongsClassIndexPun
]
