Class {
	#name : #Spur32to64BitBootstrap,
	#superclass : #SimulatorHarness,
	#instVars : [
		'heap32',
		'heap64',
		'map',
		'reverseMap',
		'interpreter32',
		'interpreter64',
		'imageHeaderFlags',
		'savedWindowSize',
		'literalMap'
	],
	#pools : [
		'VMObjectIndices',
		'VMSqueakClassIndices'
	],
	#category : #'Cog-Bootstrapping'
}

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> alterSystem [
	self ensureSmallFloatInClassTable.
	self nilWordSize
]

{ #category : #'public access' }
Spur32to64BitBootstrap >> bootstrapImage [
	self cloneObjects.
	self fillInObjects.
	self fillInHeap.
	self alterSystem
]

{ #category : #'public access' }
Spur32to64BitBootstrap >> bootstrapImage: imageName [
	(Smalltalk classNamed: #FileReference) ifNotNil:
		[^self bootstrapImageUsingFileReference: imageName].
	(Smalltalk classNamed: #FileDirectory) ifNotNil:
		[^self bootstrapImageUsingFileDirectory: imageName].
	self error: 'at a loss as to what file system support to use'
]

{ #category : #'public access' }
Spur32to64BitBootstrap >> bootstrapImageUsingFileDirectory: imageName [
	| dirName baseName dir |
	dirName := FileDirectory dirPathFor: imageName.
	baseName := (imageName endsWith: '.image')
					ifTrue: [FileDirectory baseNameFor: imageName]
					ifFalse: [FileDirectory localNameFor: imageName].
	dir := dirName isEmpty ifTrue: [FileDirectory default] ifFalse: [FileDirectory default on: dirName].
	self on: (dir fullNameFor: baseName, '.image').
	[self bootstrapImage]
		on: Halt
		do: [:ex|
			"suppress halts from the usual suspects (development time halts)"
			(#(fullGC compactImage) includes: ex signalerContext sender selector)
				ifTrue: [ex resume]
				ifFalse: [ex pass]].
	self writeSnapshot: (dir fullNameFor: baseName, '-64.image')
		headerFlags: imageHeaderFlags
		screenSize: savedWindowSize.
	dir deleteFileNamed: baseName, '-64.changes';
		copyFileNamed: baseName, '.changes' toFileNamed: baseName, '-64.changes'
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> clone: obj32 [
	| obj64 format numSlots numBytes hash |
	format := heap32 formatOf: obj32.
	numSlots := heap32 numSlotsOf: obj32.
	format > heap32 lastPointerFormat ifTrue:
		[format < heap32 firstByteFormat
			ifTrue:
				[format = heap32 firstLongFormat
					ifTrue:
						[numSlots := heap32 numSlotsOf: obj32.
						 numSlots odd ifTrue:
							[format := format + 1].
						 numSlots := numSlots + 1 // 2]
					ifFalse: [self error: 'bad format']]
			ifFalse:
				[numBytes := heap32 numBytesOf: obj32.
				 format < heap32 firstCompiledMethodFormat
					ifTrue:
						[format := heap64 byteFormatForNumBytes: numBytes.
						 numSlots := numSlots + 1 // 2]
					ifFalse:
						[numSlots := heap32 numPointerSlotsOf: obj32.
						 numBytes := numBytes - (numSlots * heap32 bytesPerOop).
						 format := (heap64 byteFormatForNumBytes: numBytes) + heap32 firstCompiledMethodFormat - heap32 firstByteFormat.
						 numSlots := numSlots + (heap64 numSlotsForBytes: numBytes)]]].
	obj64 := heap64
				allocateSlots: numSlots
				format: format
				classIndex: (heap32 classIndexOf: obj32).
	(hash := heap32 rawHashBitsOf: obj32) ~= 0 ifTrue:
		[heap64 setHashBitsOf: obj64 to: hash].
	(heap32 isImmutable: obj32) ifTrue:
		[heap64 setIsImmutableOf: obj64 to: true].
	(heap32 isPinned: obj32) ifTrue:
		[heap64 setIsPinnedOf: obj64 to: true].
	self deny: (heap32 isRemembered: obj32).
	self deny: (heap32 isMarked: obj32).
	self deny: (heap32 isGrey: obj32).
	reverseMap at: obj64 put: obj32.
	^map at: obj32 put: obj64
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> cloneFreeLists: obj32 [
	| obj64 |
	obj64 := heap64
				allocateSlots: heap64 numFreeLists
				format: heap64 wordIndexableFormat
				classIndex: heap64 wordSizeClassIndexPun.
	reverseMap at: obj64 put: obj32.
	^map at: obj32 put: obj64
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> cloneObjects [
	"Clone all normal objects.  Of hidden objects only clone the freeLists object and
	 the classTableRoot and class table pages. In particular, dont clone objStacks.
	 The refs to the objStacks are nilled out in fillInHeap."
	| i freeListsObject |
	i := 0.
	freeListsObject := heap32 freeListsObject.
	heap32 allOldSpaceObjectsDo:
		[:obj32|
		(i := i + 1) >= 100000 ifTrue:
			[Transcript nextPut: $:; flush. i := 0].
		 obj32 = freeListsObject
			ifTrue:
				[self cloneFreeLists: obj32]
			ifFalse:
				[(self shouldClone: obj32) ifTrue:
					[self clone: obj32]]]
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> ensureSmallFloatInClassTable [
	| firstClassTablePage smallFloatClass |
	firstClassTablePage := heap64 fetchPointer: 0 ofObject: heap64 classTableRootObj.
	smallFloatClass := self smallFloatClass.
	(heap64 hashBitsOf: smallFloatClass) = heap64 smallFloatTag
		ifTrue:
			[self assert: (heap64 fetchPointer: heap64 smallFloatTag ofObject: firstClassTablePage)
						= smallFloatClass]
		ifFalse:
			[self assert: (heap64 hashBitsOf: smallFloatClass) = 0.
			 heap64
				storePointer: heap64 smallFloatTag ofObject: firstClassTablePage withValue: smallFloatClass;
				setHashBitsOf: smallFloatClass to: heap64 smallFloatTag]
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> fillInBitsObject: obj64 from: obj32 [
	0 to: (heap32 numBytesOf: obj32) - 1 do:
		[:i|
		heap64
			storeByte: i
			ofObject: obj64
			withValue: (heap32 fetchByte: i ofObject: obj32)]
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> fillInCompiledMethod: obj64 from: obj32 [
	| offset |
	"interpreter32 printOop: oop32"
	"interpreter64 printOop: oop64"
	0 to: (heap32 numPointerSlotsOf: obj32) - 1 do:
		[:i| | oop32 oop64 |
		 oop32 := heap32 fetchPointer: i ofObject: obj32.
		 oop64 := self map32BitOop: oop32.
		 heap64
			storePointerUnchecked: i
			ofObject: obj64
			withValue: oop64.
		 (heap64 isIntegerObject: oop64) ifTrue:
			[interpreter32 initPrimCall.
			 self assert: (interpreter32 signed64BitValueOf: oop32) = (heap64 integerValueOf: oop64)]].
	offset := (interpreter64 startPCOfMethod: obj64)
			- (interpreter32 startPCOfMethod: obj32).
	(interpreter32 startPCOfMethod: obj32)
		to: (heap32 numBytesOf: obj32) - 1
		do: [:j|
			heap64
				storeByte: offset + j 
				ofObject: obj64
				withValue: (heap32 fetchByte: j ofObject: obj32)]
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> fillInHeap [
	| heapEnd freeListsObj |
	heapEnd := heap64 freeStart.
	heap64
		nilObject: (map at: heap32 nilObject);
		falseObject: (map at: heap32 falseObject);
		trueObject: (map at: heap32 trueObject);
		specialObjectsOop: (map at: heap32 specialObjectsOop);
		lastHash: heap32 lastHash;
		setHiddenRootsObj: (map at: heap32 classTableRootObj).
	heap64 segmentManager
		initSegmentForInImageCompilationFrom: heap64 nilObject
		to: heapEnd + heap64 bridgeSize.
	freeListsObj := heap64 objectAfter: heap64 trueObject.
	"Nil-out the free lists."
	heap64
		fillObj: freeListsObj numSlots: (heap64 numSlotsOf: freeListsObj) with: 0;
		initializeFreeSpacePostLoad: freeListsObj;
		initializePostBootstrap;
		setEndOfMemory: (heap64 segmentManager bridgeAt: 0) + heap64 baseHeaderSize
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> fillInObjects [
	"interpreter32 printOop: obj32"
	| i |
	{heap32 markStack. heap32 weaklingStack. heap32 mournQueue} do:
		[:obj|
		obj ~= heap32 nilObject ifTrue:
			[map at: obj put: (map at: heap32 nilObject)]].
	i := 0.
	heap32 allObjectsDo:
		[:obj32|
		(i := i + 1) >= 10000 ifTrue:
			[Transcript nextPut: $.; flush. i := 0].
		(map at: obj32 ifAbsent: nil)
			ifNotNil:
				[:obj64| | format classIndex |
				(heap64 numSlotsOf: obj64) > 0 ifTrue: "filter-out filtered objStack pages"
					[format := heap32 formatOf: obj32.
					 (heap64 isPointersFormat: format)
						ifTrue:
							[((heap64 isIndexableFormat: format)
								and: [(classIndex := heap64 classIndexOf: obj64) <= ClassBlockClosureCompactIndex
								and: [classIndex >= ClassMethodContextCompactIndex]])
								ifTrue: [self fillInPointerObjectWithPC: obj64 from: obj32]
								ifFalse: [self fillInPointerObject: obj64 from: obj32]]
						ifFalse:
							[(heap64 isCompiledMethodFormat: format)
								ifTrue: [self fillInCompiledMethod: obj64 from: obj32]
								ifFalse: [self fillInBitsObject: obj64 from: obj32]]]]
			ifNil: [self assert: (self isUnmappedObject: obj32)]]
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> fillInPointerObject: obj64 from: obj32 [ 
	0 to: (heap64 numSlotsOf: obj64) - 1 do:
		[:i|
		 heap64
			storePointerUnchecked: i
			ofObject: obj64
			withValue: (self map32BitOop: (heap32 fetchPointer: i ofObject: obj32))]
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> fillInPointerObjectWithPC: obj64 from: obj32 [
	| method |
	self fillInPointerObject: obj64 from: obj32.
	(heap64 classIndexOf: obj64) = ClassBlockClosureCompactIndex ifTrue:
		[method := heap32
						fetchPointer: MethodIndex
						ofObject: (heap32
									fetchPointer: ClosureOuterContextIndex
									ofObject: obj32).
		self incrementPCField: ClosureStartPCIndex ofObject: obj64 for: method].
	(heap64 classIndexOf: obj64) = ClassMethodContextCompactIndex ifTrue:
		[method := heap32
						fetchPointer: MethodIndex
						ofObject: obj32.
		 self incrementPCField: InstructionPointerIndex ofObject: obj64 for: method]
]

{ #category : #'public access' }
Spur32to64BitBootstrap >> findSymbol: aString [
	"Find the Symbol equal to aString in oldHeap."
	| symbolClass |
	(literalMap at: aString ifAbsent: nil) ifNotNil:
		[:oop| ^oop].
	symbolClass := self symbolClass.
	heap64 allObjectsDo:
		[:obj|
		(symbolClass = (heap64 fetchClassOfNonImm: obj)
		 and: [(heap64 numBytesOf: obj) = aString size
		 and: [aString = (heap64 stringOf: obj)]]) ifTrue:
			[aString isSymbol ifTrue:
				[literalMap at: aString asSymbol put: obj].
			 ^obj]].
	Transcript cr; nextPutAll: 'Warning, could not find '; store: aString; flush.
	^nil
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> incrementPCField: fieldIndex ofObject: obj64 for: method32 [
	| value nLits |
	value := heap64 fetchPointer: fieldIndex ofObject: obj64.
	(heap64 isIntegerObject: value)
		ifTrue:
			[nLits := heap32 literalCountOf: method32.
			 heap64
				storePointerUnchecked: fieldIndex
				ofObject: obj64
				withValue: (heap64 integerObjectOf: nLits + LiteralStart * 4 + (heap64 integerValueOf: value))]
		ifFalse:
			[self assert: (reverseMap at: value) = heap32 nilObject]
]

{ #category : #'initialize-release' }
Spur32to64BitBootstrap >> initMaps [
	map := Dictionary new: heap32 memory size // 32.
	reverseMap := Dictionary new: heap32 memory size // 32.
	literalMap := IdentityDictionary new
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> isUnmappedObject: obj32 [
	"Answer if obj32 is an object that is not cloned by the bootstrap."
	^((heap32 classIndexOf: obj32)
			between: ClassLargeNegativeIntegerCompactIndex
			and: ClassFloatCompactIndex)
	  or: [obj32 = heap32 freeListsObject
	  or: [(heap32 isValidObjStackPage: obj32)]]
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> map32BitOop: obj32 [
	"interpreter32 printOop: obj32"
	^map
		at: obj32
		ifAbsent:
			[(heap32 isImmediate: obj32)
				ifTrue:
					[(heap32 isImmediateCharacter: obj32)
						ifTrue: [heap64 characterObjectOf: (heap32 characterValueOf: obj32)]
						ifFalse: [heap64 integerObjectOf: (heap32 integerValueOf: obj32)]]
				ifFalse:
					[| value |
					 self assert: (self isUnmappedObject: obj32).
					 (heap32 isFloatInstance: obj32)
						ifTrue:
							[heap64 smallFloatObjectOf: (heap32 floatValueOf: obj32)]
						ifFalse:
							[interpreter32 initPrimCall.
							 value := interpreter32 signed64BitValueOf: obj32.
							 self deny: interpreter32 failed.
							 heap64 integerObjectOf: value]]]
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> nilWordSize [
	| wordSizeSym |
	wordSizeSym := self findSymbol: #WordSize.
	heap64 allOldSpaceObjectsDo:
		[:o|
		((heap64 numSlotsOf: o) > ValueIndex
		and: [(heap64 isPointersNonImm: o)
		and: [(heap64 fetchPointer: KeyIndex ofObject: o) = wordSizeSym
		and: [(heap64 fetchPointer: ValueIndex ofObject: o) = (heap64 integerObjectOf: 4)]]]) ifTrue:
			[heap64 storePointer: ValueIndex ofObject: o withValue: heap64 nilObject]]
]

{ #category : #'public access' }
Spur32to64BitBootstrap >> on: imageName [
	(interpreter32 := StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager))
		openOn: imageName extraMemory: 0.
	heap32 := interpreter32 objectMemory.
	imageHeaderFlags := interpreter32 getImageHeaderFlags.
	savedWindowSize := interpreter32 savedWindowSize.
	interpreter64 := StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur64BitMemoryManager).
	heap64 := interpreter64 objectMemory.
	heap64
		allocateMemoryOfSize: heap32 oldSpaceSize * 2
		newSpaceSize: 8 * 1024 * 1024
		stackSize: 16 * 1024
		codeSize: 0.
	heap64 bootstrapping: true.
	self initMaps
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> shouldClone: obj32 [
	| classIndex value |
	(heap32 isValidObjStackPage: obj32) ifTrue:
		[^false].

	classIndex := heap32 classIndexOf: obj32.

	((classIndex between: ClassLargeNegativeIntegerCompactIndex and: ClassLargePositiveIntegerCompactIndex)
	 and: [interpreter32 initPrimCall.
		   value := interpreter32 signed64BitValueOf: obj32.
		   interpreter32 failed not
		   and: [heap64 isIntegerValue: value]]) ifTrue:
		[^false].

	(classIndex = ClassFloatCompactIndex
	and: [value := heap32 floatValueOf: obj32.
		heap64 isSmallFloatValue: value]) ifTrue:
		[^false].

	^true
]

{ #category : #'bootstrap image' }
Spur32to64BitBootstrap >> smallFloatClass [
	| sf64sym |
	sf64sym := self findSymbol: #SmallFloat64.
	heap64 allObjectsDo:
		[:o|
		((heap64 isPointersNonImm: o)
		 and: [(heap64 numSlotsOf: o) > interpreter32 classNameIndex
		 and: [(interpreter64 addressCouldBeClassObj: o)
		 and: [(heap64 fetchPointer: interpreter32 classNameIndex ofObject: o) = sf64sym]]]) ifTrue:
			[^o]].
	^nil
]

{ #category : #'public access' }
Spur32to64BitBootstrap >> symbolClass [
	^heap64 fetchClassOfNonImm: (heap64 splObj: SelectorDoesNotUnderstand)
]

{ #category : #snapshot }
Spur32to64BitBootstrap >> writeSnapshot: imageFileName headerFlags: headerFlags screenSize: screenSizeInteger [
	heap64
		checkFreeSpace;
		runLeakCheckerForFullGC.
	interpreter64
		setImageHeaderFlagsFrom: headerFlags;
		setDisplayForm: nil;
		setSavedWindowSize: savedWindowSize;
		imageName: imageFileName;
		writeImageFileIO.
	Transcript cr; show: 'Done!'
]
