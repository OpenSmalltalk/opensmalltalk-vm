Class {
	#name : #Spur64BitMMLESimulator,
	#superclass : #Spur64BitMemoryManager,
	#instVars : [
		'parent',
		'bootstrapping'
	],
	#category : #'VMMaker-SpurMemoryManagerSimulation'
}

{ #category : #accessing }
Spur64BitMMLESimulator >> bootstrapping [
	^bootstrapping
]

{ #category : #accessing }
Spur64BitMMLESimulator >> bootstrapping: aBoolean [
	bootstrapping := aBoolean.
	segmentManager initForBootstrap
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> byteAt: byteAddress [
	| lowBits long32 |
	lowBits := byteAddress bitAnd: 3.
	long32 := self long32At: byteAddress - lowBits.
	^(long32 bitShift: -8 * lowBits) bitAnd: 16rFF
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> byteAt: byteAddress put: byte [
	| lowBits long32 longAddress mask value |
	lowBits := byteAddress bitAnd: 3.
	longAddress := byteAddress - lowBits.
	long32 := self long32At: longAddress.
	mask := (16rFF bitShift: 8 * lowBits) bitInvert.
	value := byte bitShift: 8 * lowBits.
	self long32At: longAddress put: ((long32 bitAnd: mask) bitOr: value).
	^byte
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> byteAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address."

	^self byteAt: pointer
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> byteSwapped32IfBigEndian: w [
	^w bitAnd: 16rFFFFFFFF
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> byteSwapped64IfBigEndian: w [
	^w bitAnd: 16rFFFFFFFFFFFFFFFF
]

{ #category : #'debug support' }
Spur64BitMMLESimulator >> eek [
	self halt
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> endianness [
	^#little
]

{ #category : #'float primitives' }
Spur64BitMMLESimulator >> fetchFloatAt: floatBitsAddress into: aFloat [
	aFloat at: 2 put: (self long32At: floatBitsAddress).
	aFloat at: 1 put: (self long32At: floatBitsAddress+4)
]

{ #category : #'object access' }
Spur64BitMMLESimulator >> fetchPointer: fieldIndex ofObject: objOop [
	self assert: (self isForwarded: objOop) not.
	self assert: (fieldIndex >= 0 and: [fieldIndex < (self numSlotsOfAny: objOop)
				or: [fieldIndex = 0 "forwarders and free objs"]]).
	^super fetchPointer: fieldIndex ofObject: objOop
]

{ #category : #'object format' }
Spur64BitMMLESimulator >> firstIndexableField: objOop [
	"NOTE: overridden from SpurMemoryManager to add coercion to CArray, so please duplicate any changes.
	 There are only two important cases, both for objects with named inst vars, i.e. formats 2,3 & 5.
	 The first indexable field for formats 2 & 5 is the slot count (by convention, even though that's off the end
	 of the object).  For 3 we must go to the class."
	| fmt classFormat |
	<returnTypeC: #'void *'>
	fmt := self formatOf: objOop.
	fmt <= self lastPointerFormat ifTrue: "pointer; may need to delve into the class format word"
		[(fmt between: self indexablePointersFormat and: self weakArrayFormat) ifTrue:
			[classFormat := self formatOfClass: (self fetchClassOfNonImm: objOop).
			 ^self cCoerce: (self pointerForOop: objOop
												+ self baseHeaderSize
												+ ((self fixedFieldsOfClassFormat: classFormat) << self shiftForWord))
					to: #'oop *'].
		^self cCoerce: (self pointerForOop: objOop + self baseHeaderSize)
				to: #'oop *'].
	"All bit objects, and indeed CompiledMethod, though this is a no-no, start at 0"
	self assert: (fmt >= self sixtyFourBitIndexableFormat and: [fmt < self firstCompiledMethodFormat]).
	^self
		cCoerce: (self pointerForOop: objOop + self baseHeaderSize)
		to: (fmt < self firstByteFormat
				ifTrue:
					[fmt = self sixtyFourBitIndexableFormat
						ifTrue: ["64 bit field objects" #'long long *']
						ifFalse:
							[fmt < self firstShortFormat
								ifTrue: ["32 bit field objects" #'int *']
								ifFalse: ["16-bit field objects" #'short *']]]
				ifFalse: ["byte objects (including CompiledMethod" #'char *'])
]

{ #category : #'spur bootstrap' }
Spur64BitMMLESimulator >> freeLists [
	^freeLists
]

{ #category : #'gc - global' }
Spur64BitMMLESimulator >> globalGarbageCollect [
	"If we're /not/ a clone, clone the VM and push it over the cliff.
	 If it survives, destroy the clone and continue.  We should be OK until next time."
	parent ifNil:
		[coInterpreter cr; print: 'GC number '; print: statFullGCs; tab; flush.
		 coInterpreter cloneSimulation objectMemory globalGarbageCollect.
		 Smalltalk garbageCollect].
	^super globalGarbageCollect
]

{ #category : #'growing/shrinking memory' }
Spur64BitMMLESimulator >> growOldSpaceByAtLeast: minAmmount [
	"Attempt to grow memory by at least minAmmount.
	 Answer the size of the new segment, or nil if the attempt failed.
	 Override to not grow during the Spur image bootstrap."
	^bootstrapping ifFalse:
		[super growOldSpaceByAtLeast: minAmmount]
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> halfWordHighInLong32: long32 [
	"Used by Balloon"

	^long32 bitAnd: 16rFFFF
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> halfWordLowInLong32: long32 [
	"Used by Balloon"

	^long32 bitShift: -16
]

{ #category : #'header format' }
Spur64BitMMLESimulator >> headerForSlots: numSlots format: formatField classIndex: classIndex [
	"The header format in LSB is
	 MSB:	| 2 bits				|
			| 22: identityHash	|
			| 8: slotSize			|
			| 3 bits				|
			| 5: format			|
			| 2 bits				|
			| 22: classIndex		| : LSB"
	self assert: (numSlots bitAnd: self numSlotsMask) = numSlots.
	self assert: (formatField bitAnd: self formatMask) = formatField.
	self assert: (classIndex bitAnd: self classIndexMask) = classIndex.
	^super headerForSlots: numSlots format: formatField classIndex: classIndex
]

{ #category : #'debug support' }
Spur64BitMMLESimulator >> heapMapAtWord: address [
	^heapMap heapMapAtWord: address
]

{ #category : #compaction }
Spur64BitMMLESimulator >> inSortedFreeListLink: freeChunk to: nextFree given: prevFree [
	"thisContext sender selector = #sweepToCoallesceFreeSpaceForPigCompactFrom: ifTrue:
		[| pit |
			pit := [:label :thing|
					coInterpreter print: label; space; printHex: thing.
					(thing ~= 0 and: [self isFreeObject: thing]) ifTrue:
						[coInterpreter print: ' (free) ']].
			pit value: 'link ' value: freeChunk.
			pit value: ' to ' value: nextFree.
			pit value: ' from ' value: prevFree.
			coInterpreter cr]."
	"freeChunk = 16r10B0730 ifTrue:
		[self halt]."
	super inSortedFreeListLink: freeChunk to: nextFree given: prevFree
]

{ #category : #initialization }
Spur64BitMMLESimulator >> initialize [
	super initialize.
	bootstrapping := false
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> intAt: byteAddress [ 
	^self long32At: byteAddress
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> intAt: byteAddress put: a64BitValue [
	^self long32At: byteAddress put: (a64BitValue bitAnd: 16rFFFFFFFF)
]

{ #category : #'image segment in/out' }
Spur64BitMMLESimulator >> loadImageSegmentFrom: segmentWordArray outPointers: outPointerArray [
	self leakCheckImageSegments ifTrue:
		[self halt].
	^super loadImageSegmentFrom: segmentWordArray outPointers: outPointerArray
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> long32At: byteAddress [
	"Note: Adjusted for Smalltalk's 1-based array indexing."
	byteAddress \\ 4 ~= 0 ifTrue: [self unalignedAccessError].
	^memory at: byteAddress // 4 + 1
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> long32At: byteAddress put: a32BitValue [
	"Note: Adjusted for Smalltalk's 1-based array indexing."
	"(byteAddress = 16r183FB00 and: [a32BitValue = 16r3FFFFC]) ifTrue:
		[self halt]."
	"(byteAddress between: 16r33FBB8 and: 16r33FBCF) ifTrue:
		[self halt]."
	byteAddress \\ 4 ~= 0 ifTrue: [self unalignedAccessError].
	^memory at: byteAddress // 4 + 1 put: a32BitValue
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> long64At: byteAddress [
	"memory is a Bitmap, a 32-bit indexable array of bits"
	| hiWord loWord |
	byteAddress \\ 8 ~= 0 ifTrue: [self unalignedAccessError].
	loWord := memory at: byteAddress // 4 + 1.
	hiWord := memory at: byteAddress // 4 + 2.
	^hiWord = 0
		ifTrue: [loWord]
		ifFalse: [(hiWord bitShift: 32) + loWord]
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> long64At: byteAddress put: a64BitValue [
	byteAddress \\ 8 ~= 0 ifTrue: [self unalignedAccessError].
	self
		long32At: byteAddress put: (a64BitValue bitAnd: 16rffffffff);
		long32At: byteAddress + 4 put: (a64BitValue >> 32 bitAnd: 16rffffffff).
	^a64BitValue
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> longAt: byteAddress [
	"Answer the 64-bit word at byteAddress which must be 0 mod 4."

	^self long64At: byteAddress
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> longAt: byteAddress put: a64BitValue [
	"Store the 64-bit value at byteAddress which must be 0 mod 8."
	"byteAddress = 16r43C790 ifTrue: [self halt]."
	^self long64At: byteAddress put: a64BitValue
]

{ #category : #'image segment in/out' }
Spur64BitMMLESimulator >> mapOopsFrom: segStart to: segAddr outPointers: outPointerArray outHashes: savedOutHashes [
	self leakCheckImageSegments ifTrue:
		[self halt].
	^super mapOopsFrom: segStart to: segAddr outPointers: outPointerArray outHashes: savedOutHashes
]

{ #category : #'gc - global' }
Spur64BitMMLESimulator >> markAndTrace: objOop [
	"objOop = 16rB26020 ifTrue: [self halt].
	objOop = 16rB25FD8 ifTrue: [self halt].
	objOop = 16rB26010 ifTrue: [self halt]."
	^super markAndTrace: objOop
]

{ #category : #snapshot }
Spur64BitMMLESimulator >> memoryBaseForImageRead [
	"Answer the address to read the image into.  Override so that when bootstrapping,
	 the segmentManager's segments are undisturbed in adjustSegmentSwizzlesBy:"
	^bootstrapping
		ifTrue: [0] 
		ifFalse: [super memoryBaseForImageRead]
]

{ #category : #compaction }
Spur64BitMMLESimulator >> moveARunOfObjectsStartingAt: startAddress upTo: limit [
	| result |.
	"self checkTraversableSortedFreeList."
	result := super moveARunOfObjectsStartingAt: startAddress upTo: limit.
	"self checkTraversableSortedFreeList."
	^result
]

{ #category : #initialization }
Spur64BitMMLESimulator >> nextLongFrom: aStream [
	"Read a 32- or 64-bit quantity from the given (binary) stream."

	^aStream nextLittleEndianNumber: self wordSize
]

{ #category : #initialization }
Spur64BitMMLESimulator >> nextWord32From: aStream [
	"Read a 32-bit quantity from the given (binary) stream."

	^aStream nextLittleEndianNumber: 4
]

{ #category : #'spur bootstrap' }
Spur64BitMMLESimulator >> numClassTablePages [
	^numClassTablePages
]

{ #category : #accessing }
Spur64BitMMLESimulator >> parent [

	^ parent
]

{ #category : #accessing }
Spur64BitMMLESimulator >> parent: anObject [

	parent := anObject
]

{ #category : #'image segment in/out' }
Spur64BitMMLESimulator >> return: errCode restoringObjectsIn: firstArray savedFirstFields: savedFirstFields and: secondArray savedHashes: savedHashes [
	self leakCheckImageSegments ifTrue:
		[self halt: errCode printString].
	^super return: errCode restoringObjectsIn: firstArray savedFirstFields: savedFirstFields and: secondArray savedHashes: savedHashes
]

{ #category : #'debug support' }
Spur64BitMMLESimulator >> runLeakCheckerFor: gcModes excludeUnmarkedObjs: excludeUnmarkedObjs classIndicesShouldBeValid: classIndicesShouldBeValid [
	(coInterpreter displayView isNil
	 and: [gcModes anyMask: checkForLeaks]) ifTrue:
		[coInterpreter transcript nextPutAll: 'leak-checking...'; flush].
	^super
		runLeakCheckerFor: gcModes
		excludeUnmarkedObjs: excludeUnmarkedObjs
		classIndicesShouldBeValid: classIndicesShouldBeValid
]

{ #category : #'gc - global' }
Spur64BitMMLESimulator >> scavengingGCTenuringIf: tenuringCriterion [
	"If we're /not/ a clone, clone the VM and push it over the cliff.
	 If it survives, destroy the clone and continue.  We should be OK until next time."
	(self leakCheckNewSpaceGC
	 and: [parent isNil]) ifTrue:
		[coInterpreter cr; print: 'scavenge '; print: statScavenges; tab; flush.
		 coInterpreter cloneSimulation objectMemory scavengingGCTenuringIf: tenuringCriterion.
		 Smalltalk garbageCollect].
	^super scavengingGCTenuringIf: tenuringCriterion
]

{ #category : #'header access' }
Spur64BitMMLESimulator >> setIsMarkedOf: objOop to: aBoolean [
	"objOop = 16rB26020 ifTrue: [self halt]."
	"(#(16r1971D0 16r196EE0 16r197048 16r197148) includes: objOop) ifTrue:
		[self halt]."
	super setIsMarkedOf: objOop to: aBoolean.
	"(aBoolean
	 and: [(self isContextNonImm: objOop)
	 and: [(coInterpreter
			checkIsStillMarriedContext: objOop
			currentFP: coInterpreter framePointer)
	 and: [(coInterpreter stackPages stackPageFor: (coInterpreter frameOfMarriedContext: objOop)) trace = 0]]]) ifTrue:
		[self halt]"
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> shortAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	| lowBits long |
	lowBits := byteAddress bitAnd: 2.
	long := self long32At: byteAddress - lowBits.
	^ lowBits = 2
		ifTrue: [ long bitShift: -16 ]
		ifFalse: [ long bitAnd: 16rFFFF ]
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> shortAt: byteAddress put: a16BitValue [
    "Return the half-word at byteAddress which must be even."
	| lowBits long longAddress |
	lowBits := byteAddress bitAnd: 2.
	lowBits = 0
		ifTrue: "storing into LS word"
			[long := self long32At: byteAddress.
			 self long32At: byteAddress
				put: ((long bitAnd: 16rFFFF0000) bitOr: a16BitValue)]
		ifFalse: "storing into MS word"
			[longAddress := byteAddress - 2.
			long := self long32At: longAddress.
			self long32At: longAddress
				put: ((long bitAnd: 16rFFFF) bitOr: (a16BitValue bitShift: 16))].
	^a16BitValue
]

{ #category : #'float primitives' }
Spur64BitMMLESimulator >> storeFloatAt: floatBitsAddress from: aFloat [
	self long32At: floatBitsAddress put: (aFloat at: 2).
	self long32At: floatBitsAddress+4 put: (aFloat at: 1)
]

{ #category : #'image segment in/out' }
Spur64BitMMLESimulator >> storeImageSegmentInto: segmentWordArray outPointers: outPointerArray roots: arrayOfRoots [
	self leakCheckImageSegments ifTrue:
		[parent ifNil:
			[| result |
			 self halt.
			 result := coInterpreter cloneSimulation objectMemory storeImageSegmentInto: segmentWordArray outPointers: outPointerArray roots: arrayOfRoots.
			 Smalltalk garbageCollect]].
	^super storeImageSegmentInto: segmentWordArray outPointers: outPointerArray roots: arrayOfRoots
]

{ #category : #'memory access' }
Spur64BitMMLESimulator >> vmEndianness [
	"1 = big, 0 = little"
	^0
]
