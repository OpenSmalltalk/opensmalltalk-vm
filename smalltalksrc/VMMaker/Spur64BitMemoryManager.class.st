Class {
	#name : #Spur64BitMemoryManager,
	#superclass : #SpurMemoryManager,
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #'class initialization' }
Spur64BitMemoryManager class >> initializeWithOptions: optionsDictionary [
	"SpurMemoryManager initializeWithOptions: Dictionary new"

	optionsDictionary at: #Spur64BitMemoryManager put: true.
	super initializeWithOptions: optionsDictionary
]

{ #category : #'simulation only' }
Spur64BitMemoryManager class >> isImmediate: anObject [
	self flag: 'The float range is close but probably wrong. Revisit when immediate floats are implemented'.
	^(anObject isInteger and: [anObject between: self minSmallInteger and: self maxSmallInteger])
	  or: [anObject isCharacter
	  or: [anObject isFloat and: [anObject exponent between: -126 and: 127]]]

	"1.0e-38 exponent -127
	 1.0e38 exponent 126

	 NumberParser new makeFloatFromMantissa: 1 exponent: 127 base: 2 1.7014118346046923e38
	 (NumberParser new makeFloatFromMantissa: 1 exponent: 127 base: 2) exponent 127
	 NumberParser new makeFloatFromMantissa: 1 exponent: -126 base: 2 1.1754943508222875e-38
	 (NumberParser new makeFloatFromMantissa: 1 exponent: -126 base: 2) exponent -126"
]

{ #category : #translation }
Spur64BitMemoryManager class >> maxSmallInteger [
	^16rFFFFFFFFFFFFFFF
]

{ #category : #translation }
Spur64BitMemoryManager class >> minSmallInteger [
	^-16r1000000000000000
]

{ #category : #'simulation only' }
Spur64BitMemoryManager class >> numSmallIntegerTagBits [
	^3
]

{ #category : #'simulation only' }
Spur64BitMemoryManager class >> simulatorClass [
	^ Spur64BitMMLESimulator
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
	<returnTypeC: #usqInt>
	| numSlots |
	numSlots := self rawNumSlotsOf: objOop.
	numSlots = 0 ifTrue: [^objOop + self allocationUnit + self baseHeaderSize].
	numSlots = self numSlotsMask ifTrue:
		[numSlots := self rawOverflowSlotsOf: objOop].
	^objOop + self baseHeaderSize + (numSlots bitShift: self shiftForWord)
]

{ #category : #allocation }
Spur64BitMemoryManager >> allocateSlots: numSlots format: formatField classIndex: classIndex isPinned: isPinned [
	"Allocate an object with numSlots space.  If there is room beneath scavengeThreshold
	 allocate in newSpace, otherwise alocate in oldSpace.  If there is not room in newSpace
	 and a scavenge is not already scheduled, schedule a scavenge."
	<inline: true>
	| numBytes newObj hasToScheduleScavenge |
	"Object headers are 8 bytes in length if the slot size fits in the num slots field (max implies overflow),
	 16 bytes otherwise (num slots in preceding word).
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
	
	hasToScheduleScavenge := freeStart + numBytes > scavengeThreshold.
	
	(hasToScheduleScavenge or: [isPinned]) ifTrue:
		[ hasToScheduleScavenge 
			ifTrue: [needGCFlag 	ifFalse: [self scheduleScavenge]].
		
		  isPinned 
			ifTrue: [ 
				^self 
					allocateSlotsForPinningInOldSpace: numSlots 
					bytes: numBytes format: formatField classIndex: classIndex ]
			ifFalse: [ 
				^self 
					allocateSlotsInOldSpace: numSlots 
					bytes: numBytes format: formatField classIndex: classIndex ]].
	
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
		[chunk := self allocateOldSpaceChunkOfBytes: totalBytes.
		 chunk ifNil:
			[^nil].
		 (segmentManager segmentContainingObj: chunk) containsPinned: true].
	numSlots >= self numSlotsMask ifTrue: "for header parsing we put a saturated slot count in the prepended overflow size word"
		[self longAt: chunk
			put: numSlots + (self numSlotsMask << self numSlotsFullShift).
		 self longAt: chunk + self baseHeaderSize
			put: ((self headerForSlots: self numSlotsMask format: formatField classIndex: classIndex)
					bitOr: 1 << self pinnedBitShift).
		 self checkFreeSpace: GCModeNewSpace.
		 ^chunk + self baseHeaderSize].
	self longAt: chunk
		put: ((self headerForSlots: numSlots format: formatField classIndex: classIndex)
				bitOr: 1 << self pinnedBitShift).
	self checkFreeSpace: GCModeNewSpace.
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
	chunk ifNil:
		[^nil].
	numSlots >= self numSlotsMask ifTrue: "for header parsing we put a saturated slot count in the prepended overflow size word"
		[self longAt: chunk
			put: numSlots + (self numSlotsMask << self numSlotsFullShift).
		 self longAt: chunk + self baseHeaderSize
			put: (self headerForSlots: self numSlotsMask format: formatField classIndex: classIndex).
		 self checkFreeSpace: GCModeNewSpace.
		 ^chunk + self baseHeaderSize].
	self longAt: chunk
		put: (self headerForSlots: numSlots format: formatField classIndex: classIndex).
	self checkFreeSpace: GCModeNewSpace.
	^chunk
]

{ #category : #snapshot }
Spur64BitMemoryManager >> byteSwapped: w [
	"Answer the given integer with its bytes in the reverse order."
	<api>
	<returnTypeC: #sqInt>
	^w byteSwap64
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

{ #category : #'object enumeration' }
Spur64BitMemoryManager >> bytesInObject: objOop given: rawNumSotsOfObjOop [
	"Answer the total number of bytes in an object including header and possible overflow size header, given the value of the object's numSlots field."
	<returnTypeC: #usqInt>
	<inline: true>
	| numSlots |
	numSlots := rawNumSotsOfObjOop = self numSlotsMask
					ifTrue: [self rawOverflowSlotsOf: objOop]
					ifFalse: [rawNumSotsOfObjOop = 0 ifTrue: [1] ifFalse: [rawNumSotsOfObjOop]].
	^numSlots << self shiftForWord
	+ (rawNumSotsOfObjOop = self numSlotsMask
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
	| classFormat fixedFields instFormat newFormat classIndex instSlots instBytes |
	(self isObjImmutable: rcvr) ifTrue:
		[^PrimErrNoModification].
	classFormat := self formatOfClass: argClass.
	fixedFields := self fixedFieldsOfClassFormat: classFormat.
	classFormat := self instSpecOfClassFormat: classFormat.
	instFormat := self formatOf: rcvr.

	"Fail for inability to access classIndex before making contexts snapshot-safe."
	(classIndex := self ensureBehaviorHash: argClass) < 0 ifTrue:
		[^classIndex negated].

	"Now check the instance for compatibility and compute odd bits if necessary."
	classFormat <= self lastPointerFormat
		ifTrue:
			[instFormat > self lastPointerFormat ifTrue:
				[^PrimErrInappropriate].
			 ((instSlots := self numSlotsOf: rcvr) < fixedFields
			  or: [instSlots > fixedFields and: [self isFixedSizePointerFormat: classFormat]]) ifTrue:
				[^PrimErrBadReceiver].
			 (instFormat = self indexablePointersFormat
			  and: [self isContextNonImm: rcvr]) ifTrue:
				[coInterpreter makeContextSnapshotSafe: rcvr].
			 newFormat := classFormat]
		ifFalse:
			["Fail if the class's format is somehow invalid."
			 classFormat ~= (self classFormatForInstanceFormat: classFormat) ifTrue:
				[^PrimErrBadArgument].

			 instBytes := self numBytesOf: rcvr.
			 classFormat
				caseOf: {
				[self sixtyFourBitIndexableFormat]
					-> [(instBytes anyMask: 7) ifTrue: [^PrimErrBadReceiver].
						newFormat := classFormat].
				[self firstLongFormat] 		
					-> [(instBytes anyMask: 3) ifTrue: [^PrimErrBadReceiver].
						newFormat := classFormat + (2 - (instBytes >> 2) bitAnd: 1)].
				[self firstShortFormat] 		
					-> [(instBytes anyMask: 1) ifTrue: [^PrimErrBadReceiver].
						newFormat := classFormat + (4 - (instBytes >> 1) bitAnd: 3)].
				[self firstByteFormat]
					-> [newFormat := classFormat + (8 - instBytes bitAnd: 7)].
				[self firstCompiledMethodFormat]
					-> [classFormat ~= self firstCompiledMethodFormat ifTrue:
							[^PrimErrInappropriate].
						newFormat := instFormat] }
				otherwise: "bits instances cannot be adopted by pointer-like classes..."
					[^PrimErrInappropriate]].

	self set: rcvr classIndexTo: classIndex formatTo: newFormat.

	self assert: (self numBytesOf: rcvr) = (classFormat <= self lastPointerFormat
											ifTrue: [instSlots * self bytesPerOop]
											ifFalse: [instBytes]).
	"ok"
	^0
]

{ #category : #'gc - global' }
Spur64BitMemoryManager >> coalesce: obj1 and: obj2 [
	| header1NumSlots header2NumSlots obj2slots newNumSlots |
	header1NumSlots := self rawNumSlotsOf: obj1.
	header2NumSlots := self rawNumSlotsOf: obj2.

	"compute total number of slots in obj2, including header"
	obj2slots := header2NumSlots = self numSlotsMask
					ifTrue: [(self rawOverflowSlotsOf: obj2) + (2 * self baseHeaderSize / self wordSize)]
					ifFalse: [(header2NumSlots = 0 ifTrue: [1] ifFalse: [header2NumSlots]) + (self baseHeaderSize / self wordSize)].
	self assert: obj2slots * self wordSize = (self bytesInObject: obj2).

	"if obj1 already has a double header things are simple..."
	header1NumSlots = self numSlotsMask ifTrue:
		[self rawOverflowSlotsOf: obj1 put: obj2slots + (self rawOverflowSlotsOf: obj1).
		 ^obj1].

	"compute total number of slots in obj1, excluding header"
	header1NumSlots := header1NumSlots = 0 ifTrue: [1] ifFalse: [header1NumSlots].
	self assert: header1NumSlots * self wordSize + self baseHeaderSize = (self bytesInObject: obj1).
	newNumSlots := obj2slots + header1NumSlots.

	"if obj1 still only requires a single header things are simple..."
	newNumSlots < self numSlotsMask ifTrue:
		[self rawNumSlotsOf: obj1 put: newNumSlots.
		 ^obj1].

	"convert from single to double header..."
	newNumSlots := newNumSlots - (self baseHeaderSize / self wordSize).
	self
		rawNumSlotsOf: obj1 + self baseHeaderSize put: self numSlotsMask;
		rawOverflowSlotsOf: obj1 + self baseHeaderSize put: newNumSlots.
	^obj1 + self baseHeaderSize
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> dbgFloatValueOf: oop [
	"Answer the C double precision floating point value of the argument,
	 or if it is not, answer 0."

	| result tagBits |
	<returnTypeC: #double>
	<var: #result type: #double>
	(tagBits := oop bitAnd: self tagMask) ~= 0
		ifTrue:
			[tagBits = self smallFloatTag ifTrue:
				[^self smallFloatValueOf: oop]]
		ifFalse:
			[(self classIndexOf: oop) = ClassFloatCompactIndex ifTrue:
				[self cCode: '' inSmalltalk: [result := Float new: 2].
				 self fetchFloatAt: oop + self baseHeaderSize into: result.
				 ^result]].
	^0.0
]

{ #category : #snapshot }
Spur64BitMemoryManager >> defaultEdenBytes [
	"Answer the default amount of memory to allocate for the eden space.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file.
	 The shootout tests seem to plateau at 5 or 6Mb.

	 Originally, both the 32-bit and 64-bit versions used the same 4Mb default.  Measuring
	 the simulator on image start-up, the 64-bit system's eden at the same point in start-up
	 (the first copyBits) is only 8% larger in bytes because it allocates 26% fewer objects.
	 Some 21% of the objects in the 32-bit version's eden are large integers and floats that
	 are representable as 64-bit immediates.

	 But when running benchmarks such as the computer language shootout's binary trees,
	 using the same amount of memory for the 64-bit system causes a significant slow-down
	 and a lot of compactions.  So we now use 4Mb for 32-bits and 7Mb for 64-bits."
	<inline: false>
	^7 * 1024 * 1024

	"Here are the expressions used to collect the above-mentioned figures:"
	"freeStart - self newSpaceStart"
	"| n | n := 0. self allNewSpaceObjectsDo: [:o| n := n + 1]. n"
	"| f | f := 0. self allNewSpaceObjectsDo: [:o| (self isFloatObject: o) ifTrue: [f := f + 1]]. f"
	"| l | l := 0. self allNewSpaceObjectsDo: [:o|
		(((self classIndexOf: o)
			between: ClassLargeNegativeIntegerCompactIndex
			and: ClassLargePositiveIntegerCompactIndex)
		 and: [(self numBytesOfBytes: o) <= 8
		 and: [self isIntegerValue: (coInterpreter signed64BitValueOf: o)]]) ifTrue: [l := l + 1]]. l"
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> exponentOfSmallFloat: oop [
	"Answer the exponent of the argument, a SmallFloat.
	 See section 61-bit Immediate Floats in the SpurMemoryManager class comment.
				msb                                              lsb 
				[8expsubset][52mantissa][1s][3tags]"
	| exp |
	self assert: (oop bitAnd: self tagMask) = self smallFloatTag.
	^oop asUnsignedInteger <= 15
		ifTrue: [0]
		ifFalse:
			[exp := oop asUnsignedInteger >> (self numTagBits + self smallFloatMantissaBits + 1).
			 exp + self smallFloatExponentOffset - 1022]
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> fetchClassTagOf: oop [
	<api>
	| tagBits |
	^(tagBits := oop bitAnd: self tagMask) ~= 0
		ifTrue: [tagBits]
		ifFalse: [self classIndexOf: oop]
]

{ #category : #'object access' }
Spur64BitMemoryManager >> fetchLong32: fieldIndex ofFloatObject: oop [
	"index by word size, and return a pointer as long as the word size"
	
	| bits |
	(self isImmediateFloat: oop) ifFalse:
		[^self fetchLong32: fieldIndex ofObject: oop].
	bits := self smallFloatBitsOf: oop.
	^ fieldIndex = 0
		ifTrue: [bits bitAnd: 16rFFFFFFFF]
		ifFalse: [bits >> 32]
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

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> floatObjectOf: aFloat [
	| newFloatObj |
	<inline: false>
	<var: #aFloat type: #double>
	<api>
	(self isSmallFloatValue: aFloat) ifTrue:
		[^self smallFloatObjectOf: aFloat].
	newFloatObj := self
						eeInstantiateSmallClassIndex: ClassFloatCompactIndex
						format: self firstLongFormat
						numSlots: (self sizeof: #double) / self bytesPerOop.
	self storeFloatAt: newFloatObj + self baseHeaderSize from: aFloat.
	^newFloatObj
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> floatValueOf: oop [
	"Answer the C double precision floating point value of the argument,
	 or fail if it is not a Float, and answer 0.
	 Note: May be called by translated primitive code."

	| result tagBits |
	<returnTypeC: #double>
	<var: #result type: #double>
	(tagBits := oop bitAnd: self tagMask) ~= 0
		ifTrue:
			[tagBits = self smallFloatTag ifTrue:
				[^self smallFloatValueOf: oop]]
		ifFalse:
			[(self classIndexOf: oop) = ClassFloatCompactIndex ifTrue:
				[self cCode: '' inSmalltalk: [result := Float new: 2].
				 self fetchFloatAt: oop + self baseHeaderSize into: result.
				 ^result]].
	coInterpreter primitiveFail.
	^0.0
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> hasSixtyFourBitImmediates [
	"The V3 64-bit memory manager has 64-bit oops, but its SmallIntegers only have
	 31 bits of precision.  The Spur 64-bit memory manager has 61-bit immediates."
	^true
]

{ #category : #'method access' }
Spur64BitMemoryManager >> headerIndicatesAlternateBytecodeSet: methodHeader [
	"A negative header selects the alternate bytecode set."
	<api>
	<inline: true>
	^methodHeader signedIntFromLong64 < 0
]

{ #category : #immediates }
Spur64BitMemoryManager >> imageFormatVersion [
	"Return a magic constant that changes when the image format changes.
	 Since the image reading code uses this to detect byte ordering, one
	 must avoid version numbers that are invariant under byte reversal.
	 N.B. Bit 4 (=16) is the isSpur bit"

	"^68019" "The first 64-bit Spur format, which unfortunately chose SmallFloat64's tag to be 3."
	^68021
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
Spur64BitMemoryManager >> instantiateClass: classObj indexableSize: nElements isPinned: isPinned [
	<api>
	<var: #nElements type: #usqInt>
	"Allocate an instance of a variable class, excepting CompiledMethod."
	| instSpec classFormat numSlots classIndex newObj fillValue |
	classFormat := self formatOfClass: classObj.
	instSpec := self instSpecOfClassFormat: classFormat.
	classIndex := self rawHashBitsOf: classObj.
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
			[(classIndex = ClassFloatCompactIndex and: [nElements ~= 2]) ifTrue:
				[coInterpreter primitiveFailFor: PrimErrBadReceiver.
				 ^nil].
			 numSlots := nElements + 1 // 2.
			 instSpec := instSpec + (nElements bitAnd: 1)].
		[self firstShortFormat]	->
			[numSlots := nElements + 3 // 4.
			 instSpec := instSpec + (4 - nElements bitAnd: 3)].
		[self firstByteFormat]	->
			[numSlots := nElements + 7 // 8.
			 instSpec := instSpec + (8 - nElements bitAnd: 7)] }
		otherwise: "non-indexable"
			["Some Squeak images include funky fixed subclasses of abstract variable
			  superclasses. e.g. DirectoryEntry as a subclass of ArrayedCollection.
			  The (Threaded)FFIPlugin expects to be able to instantiate ExternalData via
			  this method.
			  Hence allow fixed classes to be instantiated here iff nElements = 0."
			 (nElements ~= 0 or: [instSpec > self lastPointerFormat]) ifTrue:
				[^nil].
			 numSlots := self fixedFieldsOfClassFormat: classFormat.
			 fillValue := nilObj].
	classIndex = 0 ifTrue:
		[classIndex := self ensureBehaviorHash: classObj.
		 classIndex < 0 ifTrue:
			[coInterpreter primitiveFailFor: classIndex negated.
			 ^nil]].
	(numSlots > self maxSlotsForNewSpaceAlloc or: [isPinned])
		ifTrue:
			[numSlots > self maxSlotsForAlloc ifTrue:
				[coInterpreter primitiveFailFor: PrimErrUnsupported.
				 ^nil].
			 newObj := self 
				allocateSlotsInOldSpace: numSlots 
				format: instSpec 
				classIndex: classIndex
				isPinned: isPinned]
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
		cCode: [value asUnsignedInteger << self numTagBits + 1]
		inSmalltalk: [value << self numTagBits
					+ (value >= 0
						ifTrue: [1]
						ifFalse: [16r10000000000000001])]
]

{ #category : #immediates }
Spur64BitMemoryManager >> integerObjectOfCharacterObject: oop [
	"Immediate characters are unsigned"
	^oop - (self characterTag - self smallIntegerTag)
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

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> isFloatInstance: oop [
	<inline: true>
	| tagBits |
	^(tagBits := oop bitAnd: self tagMask) ~= 0
		ifTrue: [tagBits = self smallFloatTag]
		ifFalse: [(self classIndexOf: oop) = ClassFloatCompactIndex]
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> isFloatOrInt: anOop [
	"Answer if anOop is either a SmallInteger or a Float."

	<inline: true>
	^(self isImmediate: anOop)
		ifTrue: [(self isCharacterObject: anOop) not]
		ifFalse: [(self classIndexOf: anOop) = ClassFloatCompactIndex]
]

{ #category : #'object testing' }
Spur64BitMemoryManager >> isImmediateCharacter: oop [
	<inline: true>
	^oop anyMask: self characterTag
]

{ #category : #'object testing' }
Spur64BitMemoryManager >> isImmediateFloat: oop [
	<inline: true>
	^oop anyMask: self smallFloatTag
]

{ #category : #'object testing' }
Spur64BitMemoryManager >> isIntegerObject: oop [
	^oop anyMask: self smallIntegerTag
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> isIntegerValue: intValue [
	"Answer if the given value can be represented as a Smalltalk integer value.
	 In 64-bits we use a 3 bit tag which leaves 61 bits for 2's complement signed
	 integers. In C, use a shift add and mask to test if the top 4 bits are all the same.
	 Since 16rFFFFFFFFFFFFFFFF >> 60 = 16rF the computation intValue >> 60 + 1 bitAnd: 16rF
	 maps in-range -ve values to 0 and in-range +ve values to 1."
	<api>
	^self
		cCode: [(intValue >> 60 + 1 bitAnd: 16rF) <= 1] "N.B. (16rFFFFFFFFFFFFFFFF >> 60) + 1 = 16"
		inSmalltalk: [intValue >= self minSmallInteger and: [intValue <= self maxSmallInteger]]
]

{ #category : #'free space' }
Spur64BitMemoryManager >> isLilliputianSize: chunkBytes [
	"To have a prev pointer, which follows the next pointer, we need at least two slots."
	self assert: chunkBytes >= (self baseHeaderSize + self allocationUnit).
	^chunkBytes = (self baseHeaderSize + self allocationUnit)
]

{ #category : #'header access' }
Spur64BitMemoryManager >> isMarked: objOop [
	<api>
	^((self longAt: objOop) >> self markedBitFullShift bitAnd: 1) ~= 0
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> isNegativeSmallFloat: aSmallFloat [
	<inline: true>
	self assert: (self isImmediateFloat: aSmallFloat).
	^aSmallFloat anyMask: self smallFloatSignBit
]

{ #category : #'object testing' }
Spur64BitMemoryManager >> isNonIntegerObject: oop [
	^oop noMask: self smallIntegerTag
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> isSmallFloatValue: aFloat [
	<inline: true>
	<var: #rawFloat type: #usqLong>
	<var: #aFloat type: #double>
	| exponent rawFloat |
	self
		cCode: [self memcpy: (self addressOf: rawFloat) _: (self addressOf: aFloat) _: (self sizeof: rawFloat)]
		inSmalltalk: [rawFloat := (aFloat at: 1) << 32 + (aFloat at: 2)].
	exponent := rawFloat >> self smallFloatMantissaBits bitAnd: 16r7FF.
	^exponent > self smallFloatExponentOffset
	 	ifTrue: [exponent <= (255 + self smallFloatExponentOffset)]
		ifFalse:
			[(rawFloat bitAnd: (1 << self smallFloatMantissaBits - 1)) = 0
				ifTrue: [exponent = 0]
				ifFalse: [exponent = self smallFloatExponentOffset]]
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> isSmallFloatZero: aSmallFloat [
	<inline: #always>
	self assert: (self isImmediateFloat: aSmallFloat).
	^aSmallFloat asUnsignedInteger <= self negativeSmallFloatZero
]

{ #category : #'object testing' }
Spur64BitMemoryManager >> isWordsNonImm: objOop [
	"Answer if the argument contains only indexable words (no oops). See comment in formatOf:"

	^(self formatOf: objOop) between: self firstLongFormat and: self firstShortFormat - 1
]

{ #category : #allocation }
Spur64BitMemoryManager >> largeObjectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object with an overflow header, including header bytes."
	<returnTypeC: #usqInt>
	^self baseHeaderSize + self baseHeaderSize "double header"
	+ (numSlots * self bytesPerOop) "no rounding; bytesPerOop = allocationUnit"
]

{ #category : #'object access' }
Spur64BitMemoryManager >> lengthOf: objOop format: fmt [
	"Answer the number of indexable units in the given object.
	 For a CompiledMethod, the size of the method header (in bytes)
	 should be subtracted from the result of this method."
	| numSlots |
	<inline: true>
	numSlots := self numSlotsOfAny: objOop. "don't let forwarders freak us out..."
	fmt <= self ephemeronFormat ifTrue:
		[^numSlots].
	fmt >= self firstByteFormat ifTrue: "bytes, including CompiledMethod"
		[^numSlots << self shiftForWord - (fmt bitAnd: 7)].
	fmt >= self firstShortFormat ifTrue:
		[^numSlots << (self shiftForWord - 1) - (fmt bitAnd: 3)].
	fmt >= self firstLongFormat ifTrue:
		[^numSlots << (self shiftForWord - 2) - (fmt bitAnd: 1)].
	fmt = self sixtyFourBitIndexableFormat ifTrue:
		[^numSlots].
	"fmt = self forwardedFormat"
	^0
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> loadFloatOrIntFrom: floatOrIntOop [
	"If floatOrInt is an integer, then convert it to a C double float and return it.
	 If it is a Float, then load its value and return it.
	 Otherwise fail -- ie return with primErrorCode non-zero."

	<inline: true>
	<returnTypeC: #double>
	| result tagBits shift |
	<var: #result type: #double>

	(tagBits := floatOrIntOop bitAnd: self tagMask) ~= 0
		ifTrue:
			[tagBits = self smallFloatTag ifTrue:
				[^self smallFloatValueOf: floatOrIntOop].
			 (tagBits = self smallIntegerTag
			  and: [shift := 64 - self numTagBits - self smallFloatMantissaBits.
				(self cCode: [floatOrIntOop << shift]
						inSmalltalk: [floatOrIntOop << shift bitAnd: 1 << 64 - 1]) >>> shift = floatOrIntOop]) ifTrue:
				[^(self integerValueOf: floatOrIntOop) asFloat]]
		ifFalse:
			[(self classIndexOf: floatOrIntOop) = ClassFloatCompactIndex ifTrue:
				[self cCode: '' inSmalltalk: [result := Float new: 2].
				 self fetchFloatAt: floatOrIntOop + self baseHeaderSize into: result.
				 ^result]].
	coInterpreter primitiveFail.
	^0.0
]

{ #category : #accessing }
Spur64BitMemoryManager >> logBytesPerOop [
	^3
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> mapSignedSmallFloatToSignedSmallFloatZero: aSmallFloat [
	<inline: true>
	self assert: (self isImmediateFloat: aSmallFloat).
	^aSmallFloat bitAnd: self smallFloatSignBit + self tagMask
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> maxCInteger [
	^16rFFFFFFFFFFFFFFFF
]

{ #category : #instantiation }
Spur64BitMemoryManager >> maxSlotsForAlloc [
	"Answer the maximum number of slots we are willing to attempt to allocate in an object.
	 Must fit in 56-bits; c.f. bytesInObject:"
	^1024*1024*1024*1024
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> maxSmallInteger [
	^16rFFFFFFFFFFFFFFF
]

{ #category : #simulation }
Spur64BitMemoryManager >> memoryClass [
	"Answer the class to use for the memory inst var in simulation.
	 Answer nil if a suitable class isn't available.  This version emulates 64-bit access given a 32-bit element array."
	<doNotGenerate>
	
	^ SpurSimulatedMemory "self endianness == #little
		ifTrue: [LittleEndianBitmap]
		ifFalse: [Bitmap]"
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> methodDictionaryHash: oop mask: mask [
	<inline: true>
	^mask bitAnd: ((self isImmediate: oop)
						ifTrue: [self integerValueOf: oop] "this will fail for SmallFloat64 but we don't care"
						ifFalse: [self rawHashBitsOf: oop]) "If no hash then it isn't in the dictionary..."
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> minSmallInteger [
	^-16r1000000000000000
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> negativeSmallFloatZero [
	<inline: true>
	^self smallFloatSignBit + self smallFloatTag
]

{ #category : #simulation }
Spur64BitMemoryManager >> newInputEventAccessorOfSize: numElements [
	<doNotGenerate>
	self flag: #endianness.
	^(CPluggableAccessor on: (WordArray new: 16))
		atBlock: [:obj :idx| | v pidx2 |
				pidx2 := (idx - 1) * 2.
				v := (obj at: pidx2 + 1) + ((obj at: pidx2 + 2) << 32).
				v >> 63 > 0 ifTrue:
					[v := v - (1 << 64)].
				v]
		atPutBlock: [:obj :idx :val| |pidx2|
					pidx2 := (idx - 1) * 2.
					obj at: pidx2 + 1 put: (val bitAnd: 16rFFFFFFFF).
					obj at: pidx2 + 2 put: (val >> 32 bitAnd: 16rFFFFFFFF).
					val];
		objectSize: 8
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
Spur64BitMemoryManager >> numSmallIntegerBits [
	^61
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> numSmallIntegerTagBits [
	^3
]

{ #category : #'object access' }
Spur64BitMemoryManager >> numTagBits [
	<api>
	<cmacro>
	"4th bit reserved for object alignment, which could imply e.g. what space the object is in."
	^3
]

{ #category : #'object enumeration' }
Spur64BitMemoryManager >> objectAfter: objOop limit: limit [
	"Object parsing.
	1. all objects have at least a word following the header, for a forwarding pointer.
	2. objects with an overflow size have a preceding word with a saturated numSlots.  If the word
	   following an object doesn't have a saturated numSlots field it must be a single-header object.
	   If the word following does have a saturated numSlots it must be the overflow size word."
	<inline: true>
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
	^numSlots = 0
		ifTrue: [self allocationUnit + self baseHeaderSize] "always at least one slot for forwarding pointer"
		ifFalse:
			[numSlots << self shiftForWord
			 + (numSlots >= self numSlotsMask
					ifTrue: [self baseHeaderSize + self baseHeaderSize]
					ifFalse: [self baseHeaderSize])]
]

{ #category : #'object access' }
Spur64BitMemoryManager >> oldRawNumSlotsOf: objOop [
	<returnTypeC: #usqInt>
	<inline: true>
	^(self longAt: objOop) asUnsignedInteger >> self numSlotsFullShift
]

{ #category : #'cog jit support' }
Spur64BitMemoryManager >> oldSmallFloatTag [
	^3
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> positiveSmallFloatZero [
	<inline: true>
	^self smallFloatTag
]

{ #category : #'object access' }
Spur64BitMemoryManager >> rawOverflowSlotsOf: objOop [
	<returnTypeC: #usqLong>
	<inline: true>
	self flag: #endianness.
	^self
		cCode: [((self longAt: objOop - self baseHeaderSize) << 8) asUnsignedInteger >> 8]
		inSmalltalk: [(self longAt: objOop - self baseHeaderSize) bitAnd: 16rFFFFFFFFFFFFFF]
]

{ #category : #'object access' }
Spur64BitMemoryManager >> rawOverflowSlotsOf: objOop put: numSlots [
	<returnTypeC: #usqLong>
	<inline: true>
	self flag: #endianness.
	self longAt: objOop - self baseHeaderSize put: self numSlotsMask << 56 + numSlots.
	^numSlots
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> rotateLeft: anInteger [
	^(anInteger >> 63 bitAnd: 1) + ((self cCode: [anInteger] inSmalltalk: [anInteger bitAnd: 16r7FFFFFFFFFFFFFFF]) << 1)
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> rotateRight: anInteger [
	^(self cCode: [anInteger] inSmalltalk: [anInteger bitAnd: 1]) << 63 + (anInteger asUnsignedInteger >> 1)
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> rotatedFloatBitsOf: oop [
	"Answer the signed, but unadjusted value of a SmallFloat64, suitable for use as a hash.
	 Keeping the exponent unadjusted keeps the value in the SmallInteger range.
	 See section 61-bit Immediate Floats in the SpurMemoryManager class comment.
							msb                                             lsb 
	 Decode:				[8expsubset][52mantissa][1s][3tags] 
	 shift away tags & sign:	[   0000   ][8expsubset][52mantissa]
	 add sign:				[    ssss   ][8expsubset][52mantissa]"
	self assert: (self isImmediateFloat: oop).
	^oop asUnsignedInteger >> (self numTagBits + 1)
	 + ((oop anyMask: self smallFloatSignBit)
		ifTrue: [-1 asUnsignedInteger << (64 - self numTagBits - 1)]
		ifFalse: [0])
]

{ #category : #'header access' }
Spur64BitMemoryManager >> rtRefCountOf: obj put: refCount [
	"Set the rt reference count of obj; this is the three bit field comprised
	 of isGrey,isPinned,isRemembered.  See computeRefCountToShrinkRT."
	| header |
	self assert: (refCount between: 0 and: MaxRTRefCount).
	header := self longAt: obj.
	header := header bitAnd: (7 << self rememberedBitShift) bitInvert64.
	header := header + (refCount << self rememberedBitShift).
	self longAt: obj put: header
]

{ #category : #'image segment in/out' }
Spur64BitMemoryManager >> savedOutHashFillValue [
	<inline: true>
	^self maxIdentityHash + 1 << 32 + (self maxIdentityHash + 1)
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
	 9 64-bit indexable
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
	 9 64-bit indexable
	 10 - 11 32-bit indexable
	 12 - 15 16-bit indexable
	 16 - 23 byte indexable
	 24 - 31 compiled method"
	self assert: (format between: 0 and: self formatMask).
	self longAt: objOop
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
	<cmacro>
	^3
]

{ #category : #allocation }
Spur64BitMemoryManager >> shorten: objOop toIndexableSize: indexableSize [
	"Reduce the number of indexable fields in objOop, a pointer object, to nSlots. Convert the
	 unused residual to a free chunk. Without changes to numSlotsForShortening:toIndexableSize:
	 this only works for arrayFormat and longFormat objects.
	 Answer the number of bytes returned to free memory, which may be zero if no change
	 was possible."
	<inline: false>
	<api>
	| numSlots bytesBefore delta copy freeChunk |
	numSlots := self numSlotsForShortening: objOop toIndexableSize: indexableSize.
	numSlots = (self numSlotsOf: objOop) ifTrue:
		[^0].
	bytesBefore := self bytesInObject: objOop.
	delta := bytesBefore - (self objectBytesForSlots: numSlots).

	self flag: 'this should update format for 32-bit indexable words; too lazy today.'.

	delta = 0 ifTrue:
		[^0].

	delta <= self allocationUnit ifTrue:
		[copy := self allocateSlots: numSlots
					format: (self formatOf: objOop)
					classIndex: (self classIndexOf: objOop).
		 copy ifNil: [self error: 'shorten:toIndexableSize: attempted to shorten to allocationUnit!'].
		 0 to: numSlots - 1 do:
			[:i|
			self storePointerUnchecked: i
				ofObject: copy
				withValue: (self fetchPointer: i ofObject: objOop)].
		 (self isRemembered: objOop) ifTrue:
			[scavenger remember: copy].
		 self forward: objOop to: copy.
		 ^0].

	(self hasOverflowHeader: objOop)
		ifTrue:
			[self rawOverflowSlotsOf: objOop put: numSlots.
			 numSlots < self numSlotsMask ifTrue:
				[delta := delta - self allocationUnit]]
		ifFalse:
			[self assert: numSlots < self numSlotsMask.
			 self rawNumSlotsOf: objOop put: numSlots].

	freeChunk := self initFreeChunkWithBytes: delta at: (self addressAfter: objOop).
	self assert: (self addressAfter: freeChunk) <= endOfMemory.
	(self isInOldSpace: objOop)
		ifTrue:
			[totalFreeOldSpace := totalFreeOldSpace + delta.
			 self addToFreeList: freeChunk bytes: delta]
		ifFalse:
			[self
				setClassIndexOf: freeChunk to: self wordSizeClassIndexPun;
				setFormatOf: freeChunk to: self firstLongFormat].
	^delta
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> smallFloatBitsOf: oop [
	"Answer the ieee 754 double precision floating point bits of the argument, a SmallFloat.
	 See section 61-bit Immediate Floats in the SpurMemoryManager class comment.
							msb                                              lsb 
	 Decode:				[8expsubset][52mantissa][1s][3tags] 
	 shift away tags:		[ 000 ][8expsubset][52mantissa][1s] 
	 add exponent offset:	[     11 exponent     ][52mantissa][1s] 
	 rot sign:				[1s][     11 exponent     ][52mantissa]"
	| rot |
	<returnTypeC: #usqLong>
	<var: #rot type: #usqLong>
	self assert: (self isImmediateFloat: oop).
	rot := oop asUnsignedInteger >> self numTagBits.
	rot > 1 ifTrue: "a.k.a. ~= +/-0.0"
		[rot := rot + (self smallFloatExponentOffset << (self smallFloatMantissaBits + 1))].
	rot := self rotateRight: rot.
	^rot
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> smallFloatExponentBits [
	"SmallFloat64's have the same mantissa as IEEE single-precision floating point"
	<api>
	<cmacro>
	^8
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> smallFloatExponentOffset [
	"896 is 1023 - 127, where 1023 is the mid-point of the 11-bit double precision exponent range,
	 and 127 is the mid-point of the 8-bit SmallDouble exponent range."
	<api>
	<cmacro>
	^896
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> smallFloatMantissaBits [
	"SmallFloat64's have the same mantissa as IEEE double-precision floating point"
	<api>
	<cmacro>
	^52
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> smallFloatObjectOf: aFloat [
	"Encode the argument, aFloat in the SmallFloat range, as a tagged small float.
	 See section 61-bit Immediate Floats in the SpurMemoryManager class comment.

	 Encode:				[1s][     11 exponent     ][52mantissa] 
	 rot sign:				[     11 exponent     ][52mantissa][1s] 
	 sub exponent offset:	[ 000 ][8expsubset][52 mantissa][1s] 
	 shift:					[8expsubset][52 mantissa][1s][ 000 ] 
	 or/add tags:			[8expsubset][52mantissa][1s][3tags]"
	<inline: true>
	<returnTypeC: #sqInt>
	<var: #aFloat type: #double>
	| rawFloat rot |
	<var: #rawFloat type: #usqLong>
	<var: #rot type: #usqLong>
	self assert: (self isSmallFloatValue: aFloat).
	self
		cCode: [self memcpy: (self addressOf: rawFloat) _: (self addressOf: aFloat) _: (self sizeof: rawFloat)]
		inSmalltalk: [rawFloat := (aFloat at: 1) << 32 + (aFloat at: 2)].
	rot := self rotateLeft: rawFloat.
	rot > 1 ifTrue: "a.k.a. ~= +/-0.0"
		[rot := rot - (self smallFloatExponentOffset << (self smallFloatMantissaBits + 1)).
		 self assert: rot > 0].
	^self cCode: [rot << self numTagBits + self smallFloatTag]
		inSmalltalk: [((rot << self numTagBits) bitAnd: 16rFFFFFFFFFFFFFFFF) + self smallFloatTag]
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> smallFloatSignBit [
	<inline: true>
	^1 << self numTagBits
]

{ #category : #'cog jit support' }
Spur64BitMemoryManager >> smallFloatTag [
	<api>
	<cmacro>
	^4
]

{ #category : #'interpreter access' }
Spur64BitMemoryManager >> smallFloatValueOf: oop [
	"Answer the C double precision floating point value of the argument, a SmallFloat.
	 See section 61-bit Immediate Floats in the SpurMemoryManager class comment.
							msb                                              lsb 
	 Decode:				[8expsubset][52mantissa][1s][3tags] 
	 shift away tags:		[ 000 ][8expsubset][52mantissa][1s] 
	 add exponent offset:	[     11 exponent     ][52mantissa][1s] 
	 rot sign:				[1s][     11 exponent     ][52mantissa]"
	| bits value |
	<returnTypeC: #double>
	<var: #value type: #double>
	<var: #bits type: #usqLong>
	bits := self smallFloatBitsOf: oop.
	self cCode:
			[self memcpy: (self addressOf: value) _: (self addressOf: bits) _: (self sizeof: value).
			^value]
		inSmalltalk:
			[^(Float new: 2)
				at: 1 put: bits >> 32;
				at: 2 put: (bits bitAnd: 16rFFFFFFFF);
				* 1.0 "reduce to SmallFloat64 if possible"]
]

{ #category : #allocation }
Spur64BitMemoryManager >> smallObjectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object without an overflow header, including header bytes."
	<api>
	<returnTypeC: #usqInt>
	^self baseHeaderSize "single header"
	+ (numSlots < 1
		ifTrue: [self allocationUnit] "at least one slot for the forwarding pointer"
		ifFalse: [numSlots * self bytesPerOop])
]

{ #category : #'word size' }
Spur64BitMemoryManager >> tagMask [
	<api>
	<cmacro>
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
	<cmacro>
	^8
]

{ #category : #'class table' }
Spur64BitMemoryManager >> wordSizeClassIndexPun [
	^self sixtyFourBitLongsClassIndexPun
]
