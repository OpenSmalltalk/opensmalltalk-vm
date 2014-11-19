Class {
	#name : #Spur32BitMemoryManager,
	#superclass : #SpurMemoryManager,
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #'simulation only' }
Spur32BitMemoryManager class >> isImmediate: anObject [
	^anObject class == SmallInteger
	  or: [anObject class == Character]
]

{ #category : #'simulation only' }
Spur32BitMemoryManager class >> numSmallIntegerTagBits [
	^1
]

{ #category : #'simulation only' }
Spur32BitMemoryManager class >> simulatorClass [
	^Spur32BitMMLESimulator
]

{ #category : #'word size' }
Spur32BitMemoryManager class >> wordSize [
	"Answer the manager's word size, which is the size of an oop, and which
	 is assumed to be equivalent to the underlying machine's word size."
	^4
]

{ #category : #'object enumeration' }
Spur32BitMemoryManager >> addressAfter: objOop [
	"Answer the address immediately following an object."
	| numSlots slotBytes |
	numSlots := self numSlotsOfAny: objOop.
	slotBytes := numSlots = 0
					ifTrue: [self allocationUnit]
					ifFalse: [numSlots + (numSlots bitAnd: 1) << self shiftForWord].
	^objOop + self baseHeaderSize + slotBytes
]

{ #category : #allocation }
Spur32BitMemoryManager >> allocateSlots: numSlots format: formatField classIndex: classIndex [
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
			[newObj := freeStart + self baseHeaderSize.
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
			 self longAt: freeStart put: numSlots.
			 self longAt: freeStart + 4 put: self numSlotsMask << self numSlotsHalfShift.
			 self long64At: newObj put: (self headerForSlots: self numSlotsMask format: formatField classIndex: classIndex)]
		ifFalse:
			[self long64At: newObj put: (self headerForSlots: numSlots format: formatField classIndex: classIndex)].
	self assert: numBytes \\ self allocationUnit = 0.
	self assert: newObj \\ self allocationUnit = 0.
	freeStart := freeStart + numBytes.
	^newObj
]

{ #category : #allocation }
Spur32BitMemoryManager >> allocateSlotsForPinningInOldSpace: numSlots bytes: totalBytes format: formatField classIndex: classIndex [
	"Answer the oop of a chunk of space in oldSpace with numSlots slots.  Try and
	 allocate in a segment that already includes pinned objects.  The header of the
	 result will have been filled-in but not the contents."
	<var: #totalBytes type: #usqInt>
	<inline: false>
	| chunk |
	chunk := self allocateOldSpaceChunkOfBytes: totalBytes
				   suchThat: [:f| (segmentManager segmentContainingObj: f) containsPinned].
	chunk ifNil:
		[chunk := self allocateOldSpaceChunkOfBytes: totalBytes.
		 chunk ifNotNil:
			[(segmentManager segmentContainingObj: chunk) containsPinned: true]].
	self checkFreeSpace.
	chunk ifNil:
		[^nil].
	numSlots >= self numSlotsMask ifTrue: "for header parsing we put a saturated slot count in the prepended overflow size word"
		[self flag: #endianness.
		 self longAt: chunk put: numSlots.
		 self longAt: chunk + 4 put: self numSlotsMask << self numSlotsHalfShift.
		 self long64At: chunk + self baseHeaderSize
			 put: ((self headerForSlots: self numSlotsMask format: formatField classIndex: classIndex)
					bitOr: 1 << self pinnedBitShift).
		 ^chunk + self baseHeaderSize].
	self long64At: chunk
		put: ((self headerForSlots: numSlots format: formatField classIndex: classIndex)
					bitOr: 1 << self pinnedBitShift).
	^chunk
]

{ #category : #allocation }
Spur32BitMemoryManager >> allocateSlotsInOldSpace: numSlots bytes: totalBytes format: formatField classIndex: classIndex [
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
		[self flag: #endianness.
		 self longAt: chunk put: numSlots.
		 self longAt: chunk + 4 put: self numSlotsMask << self numSlotsHalfShift.
		 self long64At: chunk + self baseHeaderSize
			put: (self headerForSlots: self numSlotsMask format: formatField classIndex: classIndex).
		 ^chunk + self baseHeaderSize].
	self long64At: chunk put: (self headerForSlots: numSlots format: formatField classIndex: classIndex).
	^chunk
]

{ #category : #'interpreter access' }
Spur32BitMemoryManager >> areIntegers: oop1 and: oop2 [
	"Test oop1 and oop2 to make sure both are SmallIntegers."
	^((oop1 bitAnd: oop2) bitAnd: 1) ~= 0
]

{ #category : #snapshot }
Spur32BitMemoryManager >> byteSwapped: w [
	"Answer the given integer with its bytes in the reverse order."
	<api>
	<returnTypeC: #sqInt>
	^  ((w bitShift: Byte3ShiftNegated) bitAnd: Byte0Mask)
	 + ((w bitShift: Byte1ShiftNegated) bitAnd: Byte1Mask)
	 + ((w bitShift: Byte1Shift             ) bitAnd: Byte2Mask)
	 + ((w bitShift: Byte3Shift             ) bitAnd: Byte3Mask)
]

{ #category : #'object enumeration' }
Spur32BitMemoryManager >> bytesInObject: objOop [
	"Answer the total number of bytes in an object including header and possible overflow size header."
	<returnTypeC: #usqInt>
	| headerNumSlots numSlots |
	headerNumSlots := self rawNumSlotsOf: objOop.
	numSlots := headerNumSlots = self numSlotsMask
					ifTrue: [self rawOverflowSlotsOf: objOop]
					ifFalse: [headerNumSlots = 0 ifTrue: [1] ifFalse: [headerNumSlots]].
	^numSlots + (numSlots bitAnd: 1) << self shiftForWord
	+ (headerNumSlots = self numSlotsMask
		ifTrue: [self baseHeaderSize + self baseHeaderSize]
		ifFalse: [self baseHeaderSize])
]

{ #category : #accessing }
Spur32BitMemoryManager >> bytesPerOop [
	^4
]

{ #category : #'interpreter access' }
Spur32BitMemoryManager >> changeClassOf: rcvr to: argClass [
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
									-> [(instBytes anyMask: 3) ifTrue: [^PrimErrBadReceiver].
										newFormat := classFormat].
								[self firstLongFormat] 		
									-> [(instBytes anyMask: 1) ifTrue: [^PrimErrBadReceiver].
										newFormat := classFormat].
								[self firstByteFormat] 		
									-> [newFormat := classFormat + (4 - instBytes bitAnd: 3)] }].
						[self firstByteFormat] ->
							[(classFormat < self sixtyFourBitIndexableFormat
							  or: [classFormat >= self firstCompiledMethodFormat]) ifTrue:
								[^PrimErrInappropriate].
							 classFormat caseOf: {
								[self sixtyFourBitIndexableFormat]
									-> [(instBytes anyMask: 7) ifTrue: [^PrimErrBadReceiver]].
								[self firstLongFormat] 		
									-> [(instBytes anyMask: 3) ifTrue: [^PrimErrBadReceiver]].
								[self firstShortFormat] 		
									-> [(instBytes anyMask: 1) ifTrue: [^PrimErrBadReceiver]] }.
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

{ #category : #'gc - global' }
Spur32BitMemoryManager >> coalesce: obj1 and: obj2 [
	| header1NumSlots header2NumSlots obj2slots newNumSlots |
	header1NumSlots := self rawNumSlotsOf: obj1.
	header2NumSlots := self rawNumSlotsOf: obj2.

	"compute total number of slots in obj2, including header"
	obj2slots := header2NumSlots = self numSlotsMask
					ifTrue: [(self longAt: obj2 - self baseHeaderSize) + (2 * self baseHeaderSize / self wordSize)]
					ifFalse: [(header2NumSlots = 0 ifTrue: [1] ifFalse: [header2NumSlots]) + (self baseHeaderSize / self wordSize)].
	obj2slots := obj2slots + (obj2slots bitAnd: 1).
	self assert: obj2slots * self wordSize = (self bytesInObject: obj2).

	"if obj1 already has a double header things are simple..."
	header1NumSlots = self numSlotsMask ifTrue:
		[self longAt: obj1  - self baseHeaderSize put: obj2slots + (self longAt: obj1 - self baseHeaderSize).
		 ^obj1].

	"compute total number of slots in obj1, excluding header"
	header1NumSlots := header1NumSlots = 0
							ifTrue: [2]
							ifFalse: [header1NumSlots + (header1NumSlots bitAnd: 1)].
	self assert: header1NumSlots * self wordSize + self baseHeaderSize = (self bytesInObject: obj1).
	newNumSlots := obj2slots + header1NumSlots.

	"if obj1 still only requires a single header things are simple..."
	newNumSlots < self numSlotsMask ifTrue:
		[self byteAt: obj1 + (self numSlotsFullShift / BitsPerByte)
			put: newNumSlots.
		 ^obj1].

	"convert from single to double header..."
	newNumSlots := newNumSlots - (self baseHeaderSize / self wordSize).
	self longAt: obj1 + self baseHeaderSize
			put: (self longAt: obj1);
		longAt: obj1 + 4 + self baseHeaderSize
			put: ((self longAt: obj1 + 4) bitOr: self numSlotsMask << self numSlotsHalfShift).
	self longAt: obj1
			put: newNumSlots.
	self longAt: obj1 + 4
			put: self numSlotsMask << self numSlotsHalfShift.
	^obj1 + self baseHeaderSize
]

{ #category : #'interpreter access' }
Spur32BitMemoryManager >> fetchClassTagOf: oop [
	| tagBits |
	(tagBits := oop bitAnd: self tagMask) ~= 0 ifTrue:
		[^(tagBits bitAnd: 1) ~= 0 ifTrue: [1] ifFalse: [tagBits]].
	^self classIndexOf: oop
]

{ #category : #instantiation }
Spur32BitMemoryManager >> fillObj: objOop numSlots: numSlots with: fillValue [
	<inline: true>
	<var: #p type: #usqInt>
	self assert: (self oop: objOop + self baseHeaderSize + (numSlots * self bytesPerOop) - 1
					isLessThan: (self addressAfter: objOop)).
	(objOop + self baseHeaderSize) asUnsignedInteger
		to: (objOop + self baseHeaderSize + (numSlots * self bytesPerOop) - 1) asUnsignedInteger
		by: self allocationUnit
		do: [:p|
			self longAt: p put: fillValue;
				longAt: p + 4 put: fillValue]
]

{ #category : #'free space' }
Spur32BitMemoryManager >> initFreeChunkWithBytes: numBytes at: address [
	<var: #numBytes type: #usqLong>
	| numSlots |
	"must have room for a header (single or double) plus the next free pointer"
	self assert: (numBytes \\ self allocationUnit = 0
				 and: [numBytes >= (self baseHeaderSize + self bytesPerOop)]).
	self flag: #endianness.
	"double header"
	numBytes >= ((self numSlotsMask << self shiftForWord) + self baseHeaderSize) ifTrue:
		[numSlots := numBytes - self baseHeaderSize - self baseHeaderSize >> self shiftForWord.
		 self longAt: address put: numSlots;
			longAt: address + 4 put: self numSlotsMask << self numSlotsHalfShift;
			longAt: address + 8 put: 0; "0's classIndex; 0 = classIndex of free chunks"
			longAt: address + 12 put: self numSlotsMask << self numSlotsHalfShift.
		^address + 8].
	"single header"
	numSlots := numBytes - self baseHeaderSize >> self shiftForWord.
	self assert: numSlots < self numSlotsMask.
	self longAt: address put: 0; "0's classIndex; 0 = classIndex of free chunks"
		longAt: address + 4 put: numSlots << self numSlotsHalfShift.
	^address
]

{ #category : #segments }
Spur32BitMemoryManager >> initSegmentBridgeWithBytes: numBytes at: address [
	<var: #numBytes type: #usqLong>
	| numSlots |
	"must have room for a double header"
	self assert: (numBytes \\ self allocationUnit = 0
				 and: [numBytes >= (self baseHeaderSize + self baseHeaderSize)]).
	numSlots := numBytes - self baseHeaderSize - self baseHeaderSize >> self shiftForWord.
	self flag: #endianness.
	numSlots = 0
		ifTrue: "short bridge for adjacent segments"
			[self longAt: address put: (1 << self pinnedBitShift)
									+ (self wordIndexableFormat << self formatShift)
									+ self segmentBridgePun;
				longAt: address + 4 put: (1 << self markedBitHalfShift)]
		ifFalse: "long bridge"
			[self longAt: address put: numSlots;
				longAt: address + 4 put: self numSlotsMask << self numSlotsHalfShift;
				longAt: address + 8 put: (1 << self pinnedBitShift)
										+ (self wordIndexableFormat << self formatShift)
										+ self segmentBridgePun;
				longAt: address + 12 put: self numSlotsMask << self numSlotsHalfShift
										+ (1 << self markedBitHalfShift)]
]

{ #category : #instantiation }
Spur32BitMemoryManager >> instantiateClass: classObj indexableSize: nElements [
	<var: #nElements type: #usqInt>
	"Allocate an instance of a variable class, excepting CompiledMethod."
	| instSpec classFormat numSlots classIndex newObj fillValue |
	classFormat := self formatOfClass: classObj.
	instSpec := self instSpecOfClassFormat: classFormat.
	fillValue := 0.
	instSpec caseOf: {
		[self arrayFormat]	->
			[nElements > self maxSlotsForAlloc ifTrue:
				[^nil].
			 numSlots := nElements.
			 fillValue := nilObj].
		[self indexablePointersFormat]	->
			[nElements > (self maxSlotsForAlloc - (self fixedFieldsOfClassFormat: classFormat)) ifTrue:
				[^nil].
			 numSlots := (self fixedFieldsOfClassFormat: classFormat) + nElements.
			 fillValue := nilObj].
		[self weakArrayFormat]	->
			[nElements > (self maxSlotsForAlloc - (self fixedFieldsOfClassFormat: classFormat)) ifTrue:
				[^nil].
			 numSlots := (self fixedFieldsOfClassFormat: classFormat) + nElements.
			 fillValue := nilObj].
		[self sixtyFourBitIndexableFormat]	->
			[nElements > (self maxSlotsForAlloc / 2) ifTrue:
				[^nil].
			 numSlots := nElements * 2].
		[self firstLongFormat]	->
			[nElements > self maxSlotsForAlloc ifTrue:
				[^nil].
			 numSlots := nElements].
		[self firstShortFormat]	->
			[numSlots := nElements + 1 // 2.
			 numSlots > self maxSlotsForAlloc ifTrue:
				[^nil].
			 instSpec := instSpec + (nElements bitAnd: 1)].
		[self firstByteFormat]	->
			[numSlots := nElements + 3 // 4.
			 numSlots > self maxSlotsForAlloc ifTrue:
				[^nil].
			 instSpec := instSpec + (4 - nElements bitAnd: 3)] }
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
		ifTrue: [newObj := self allocateSlotsInOldSpace: numSlots format: instSpec classIndex: classIndex]
		ifFalse: [newObj := self allocateSlots: numSlots format: instSpec classIndex: classIndex].
	newObj ifNotNil:
		[self fillObj: newObj numSlots: numSlots with: fillValue].
	^newObj
]

{ #category : #instantiation }
Spur32BitMemoryManager >> instantiateCompiledMethodClass: classObj indexableSize: nElements [
	<var: #nElements type: #usqInt>
	"Allocate an instance of a CompiledMethod class."
	<inline: true>
	| instSpec classFormat numSlots classIndex newObj |
	classFormat := self formatOfClass: classObj.
	instSpec := self instSpecOfClassFormat: classFormat.
	instSpec ~= self firstCompiledMethodFormat ifTrue:
		[^nil].
	numSlots := nElements + 3 // 4.
	instSpec := instSpec + (4 - nElements bitAnd: 3).
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
Spur32BitMemoryManager >> integerObjectOf: value [
	"Convert the integer value, assumed to be in SmallInteger range, into a tagged SmallInteger object.
	 In C, use a shift and an add to set the tag bit.
	 In Smalltalk we have to work harder because the simulator works with strictly positive bit patterns."
	<returnTypeC: #sqInt>
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

{ #category : #'object testing' }
Spur32BitMemoryManager >> isIntegerObject: oop [
	^(oop bitAnd: 1) ~= 0
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
Spur32BitMemoryManager >> isMarked: objOop [
	<api>
	self flag: #endianness.
	^((self longAt: objOop + 4) >> self markedBitHalfShift bitAnd: 1) ~= 0
]

{ #category : #'object testing' }
Spur32BitMemoryManager >> isNonIntegerObject: oop [
	^(oop bitAnd: 1) = 0
]

{ #category : #'object testing' }
Spur32BitMemoryManager >> isWordsNonImm: objOop [
	"Answer if the argument contains only indexable words (no oops). See comment in formatOf:"

	^(self formatOf: objOop) = self firstLongFormat
]

{ #category : #allocation }
Spur32BitMemoryManager >> largeObjectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object with an overflow header, including header bytes."
	<returnTypeC: #usqInt>
	^self baseHeaderSize + self baseHeaderSize "double header"
	+ (numSlots + (numSlots bitAnd: 1) * self bytesPerOop) "roundTo allocationUnit"
]

{ #category : #'header format' }
Spur32BitMemoryManager >> logBytesPerOop [
	^2
]

{ #category : #instantiation }
Spur32BitMemoryManager >> maxSlotsForAlloc [
	"Answer the maximum number of slots we are willing to attempt to allocate in an object.
	 Must fit in 32-bits; c.f. bytesInObject:. Chosen so that maxSlotsForAlloc * self bytesPerWord is +ve."
	^512*1024*1024-1
]

{ #category : #'interpreter access' }
Spur32BitMemoryManager >> maxSmallInteger [
	^16r3FFFFFFF
]

{ #category : #'interpreter access' }
Spur32BitMemoryManager >> methodDictionaryHash: oop mask: mask [
	<inline: true>
	^mask bitAnd: ((self isImmediate: oop)
						ifTrue: [(self isIntegerObject: oop)
									ifTrue: [self integerValueOf: oop]
									ifFalse: [self characterValueOf: oop]]
						ifFalse: [self hashBitsOf: oop])
]

{ #category : #'interpreter access' }
Spur32BitMemoryManager >> minSmallInteger [
	^-16r40000000
]

{ #category : #'free space' }
Spur32BitMemoryManager >> numFreeLists [
	"Answer the number of free lists.  We use freeListsMask, a bitmap, to avoid
	 reading empty list heads.  This should fit in a machine word to end up in a
	 register during free chunk allocation."
	^32
]

{ #category : #allocation }
Spur32BitMemoryManager >> numSlotsForShortening: objOop toIndexableSize: indexableSize [
	<inline: true>
	^(self formatOf: objOop) caseOf:
		{ [self arrayFormat]			-> [indexableSize].
		  [self firstLongFormat]		-> [self numSlotsForBytes: indexableSize * 4] }
]

{ #category : #'interpreter access' }
Spur32BitMemoryManager >> numSmallIntegerBits [
	^31
]

{ #category : #'interpreter access' }
Spur32BitMemoryManager >> numSmallIntegerTagBits [
	^1
]

{ #category : #'object access' }
Spur32BitMemoryManager >> numTagBits [
	<api>
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
	(self oop: followingWordAddress isGreaterThanOrEqualTo: limit) ifTrue:
		[^limit].
	self flag: #endianness.
	followingWord := self longAt: followingWordAddress + 4.
	^followingWord >> self numSlotsHalfShift = self numSlotsMask
		ifTrue: [followingWordAddress + self baseHeaderSize]
		ifFalse: [followingWordAddress]
]

{ #category : #'object enumeration' }
Spur32BitMemoryManager >> objectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object with the given
	 number of slots, including header and possible overflow size header."
	<returnTypeC: #usqInt>
	^(numSlots = 0
		ifTrue: [self allocationUnit] "always at least one slot for forwarding pointer"
		ifFalse: [numSlots + (numSlots bitAnd: 1) << self shiftForWord])
	+ (numSlots >= self numSlotsMask
		ifTrue: [self baseHeaderSize + self baseHeaderSize]
		ifFalse: [self baseHeaderSize])
]

{ #category : #'object access' }
Spur32BitMemoryManager >> oldRawNumSlotsOf: objOop [
	<returnTypeC: #usqInt>
	<inline: true>
	self flag: #endianness.
	^(self longAt: objOop + 4) asUnsignedInteger >> self numSlotsHalfShift
]

{ #category : #'object access' }
Spur32BitMemoryManager >> rawOverflowSlotsOf: objOop [
	<returnTypeC: #usqInt>
	<inline: true>
	self flag: #endianness.
	^self longAt: objOop - self baseHeaderSize
]

{ #category : #'object access' }
Spur32BitMemoryManager >> rawOverflowSlotsOf: objOop put: numSlots [
	<returnTypeC: #usqInt>
	<inline: true>
	self flag: #endianness.
	^self longAt: objOop - self baseHeaderSize put: numSlots
]

{ #category : #'header access' }
Spur32BitMemoryManager >> set: objOop classIndexTo: classIndex formatTo: format [
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
	self flag: #endianness.
	self longAt: objOop
		put: ((self longAt: objOop) bitAnd: (self formatMask << self formatShift + self classIndexMask) bitInvert32)
			+ (classIndex
			+  (format << self formatShift))
]

{ #category : #'header access' }
Spur32BitMemoryManager >> setClassIndexOf: objOop to: classIndex [
	self assert: (classIndex between: 0 and: self classIndexMask).
	self flag: #endianness.
	self longAt: objOop
		put: ((self longAt: objOop) bitAnd: self classIndexMask bitInvert32)
			+ classIndex
]

{ #category : #'header access' }
Spur32BitMemoryManager >> setFormatOf: objOop to: format [
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
	self flag: #endianness.
	self longAt: objOop
		put: ((self longAt: objOop) bitAnd: (self formatMask << self formatShift) bitInvert32)
			+ (format << self formatShift)
]

{ #category : #'header access' }
Spur32BitMemoryManager >> setIsGreyOf: objOop to: aBoolean [
	self flag: #endianness.
	self longAt: objOop
		put: (aBoolean
				ifTrue: [(self longAt: objOop) bitOr: 1 << self greyBitShift]
				ifFalse: [(self longAt: objOop) bitAnd: (1 << self greyBitShift) bitInvert32])
]

{ #category : #'header access' }
Spur32BitMemoryManager >> setIsImmutableOf: objOop to: aBoolean [
	self flag: #endianness.
	self longAt: objOop
		put: (aBoolean
				ifTrue: [(self longAt: objOop) bitOr: 1 << self immutableBitShift]
				ifFalse: [(self longAt: objOop) bitAnd: (1 << self immutableBitShift) bitInvert32])
]

{ #category : #'header access' }
Spur32BitMemoryManager >> setIsMarkedOf: objOop to: aBoolean [
	self assert: (self isFreeObject: objOop) not.
	self flag: #endianness.
	self longAt: objOop + 4
		put: (aBoolean
				ifTrue: [(self longAt: objOop + 4) bitOr: 1 << self markedBitHalfShift]
				ifFalse: [(self longAt: objOop + 4) bitAnd: (1 << self markedBitHalfShift) bitInvert32])
]

{ #category : #'header access' }
Spur32BitMemoryManager >> setIsPinnedOf: objOop to: aBoolean [
	self flag: #endianness.
	self longAt: objOop
		put: (aBoolean
				ifTrue: [(self longAt: objOop) bitOr: 1 << self pinnedBitShift]
				ifFalse: [(self longAt: objOop) bitAnd: (1 << self pinnedBitShift) bitInvert32])
]

{ #category : #'header access' }
Spur32BitMemoryManager >> setIsRememberedOf: objOop to: aBoolean [
	self flag: #endianness.
	self longAt: objOop
		put: (aBoolean
				ifTrue: [(self longAt: objOop) bitOr: 1 << self rememberedBitShift]
				ifFalse: [(self longAt: objOop) bitAnd: (1 << self rememberedBitShift) bitInvert32])
]

{ #category : #'word size' }
Spur32BitMemoryManager >> shiftForWord [
	<api>
	<cmacro: '() 2'>
	^2
]

{ #category : #allocation }
Spur32BitMemoryManager >> smallObjectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object without an overflow header, including header bytes."
	<api>
	<returnTypeC: #usqInt>
	^self baseHeaderSize "single header"
	+ (numSlots <= 1
		ifTrue: [self allocationUnit] "at least one slot for the forwarding pointer"
		ifFalse: [numSlots + (numSlots bitAnd: 1) * self bytesPerOop]) "round up to allocationUnit"
]

{ #category : #'word size' }
Spur32BitMemoryManager >> tagMask [
	<api>
	^3
]

{ #category : #'header formats' }
Spur32BitMemoryManager >> wordIndexableFormat [
	^self firstLongFormat
]

{ #category : #'word size' }
Spur32BitMemoryManager >> wordSize [
	"Answer the manager's word size, which is the size of an oop, and which
	 is assumed to be equivalent to the underlying machine's word size."
	<api>
	<cmacro: '() 4'>
	^4
]

{ #category : #'class table' }
Spur32BitMemoryManager >> wordSizeClassIndexPun [
	^self thirtyTwoBitLongsClassIndexPun
]
