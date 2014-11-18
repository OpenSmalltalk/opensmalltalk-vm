Class {
	#name : #SpurBootstrap32to64,
	#superclass : #SimulatorHarness,
	#instVars : [
		'heap32',
		'heap64',
		'map',
		'reverseMap',
		'interpreter32',
		'interpreter64',
		'imageHeaderFlags',
		'savedWindowSize'
	],
	#pools : [
		'VMSqueakClassIndices'
	],
	#category : #'Cog-Bootstrapping'
}

{ #category : #'public access' }
SpurBootstrap32to64 >> bootstrapImage [
	self cloneObjects.
	self fillInObjects.
	self fillInHeap
]

{ #category : #'public access' }
SpurBootstrap32to64 >> bootstrapImage: imageName [
	(Smalltalk classNamed: #FileReference) ifNotNil:
		[^self bootstrapImageUsingFileReference: imageName].
	(Smalltalk classNamed: #FileDirectory) ifNotNil:
		[^self bootstrapImageUsingFileDirectory: imageName].
	self error: 'at a loss as to what file system support to use'
]

{ #category : #'public access' }
SpurBootstrap32to64 >> bootstrapImageUsingFileDirectory: imageName [
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
SpurBootstrap32to64 >> clone: obj32 [
	| obj64 format numSlots numBytes |
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
	reverseMap at: obj64 put: obj32.
	^map at: obj32 put: obj64
]

{ #category : #'bootstrap image' }
SpurBootstrap32to64 >> cloneFreeLists: obj32 [
	| obj64 |
	obj64 := heap64
				allocateSlots: heap64 numFreeLists
				format: heap64 sixtyFourBitIndexableFormat
				classIndex: heap64 sixtyFourBitLongsClassIndexPun.
	reverseMap at: obj64 put: obj32.
	^map at: obj32 put: obj64
]

{ #category : #'bootstrap image' }
SpurBootstrap32to64 >> cloneObjects [
	| freeListsObject |
	freeListsObject := heap32 freeListsObject.
	heap32 allOldSpaceObjectsDo:
		[:obj32| | classIndex value |
		classIndex := heap32 classIndexOf: obj32.
		obj32 = freeListsObject
			ifTrue:
				[self cloneFreeLists: obj32]
			ifFalse:
				[((classIndex between: ClassLargeNegativeIntegerCompactIndex and: ClassLargePositiveIntegerCompactIndex)
				  and: [interpreter32 initPrimCall.
					value := heap32 positive64BitValueOf: obj32.
					interpreter32 failed not
				  and: [heap64 isIntegerValue: value]]) ifFalse:
					[self clone: obj32]]]
]

{ #category : #'bootstrap image' }
SpurBootstrap32to64 >> fillInBitsObject: obj64 from: obj32 [
	0 to: (heap32 numBytesOf: obj32) - 1 do:
		[:i|
		heap64
			storeByte: i
			ofObject: obj64
			withValue: (heap32 fetchByte: i ofObject: obj32)]
]

{ #category : #'bootstrap image' }
SpurBootstrap32to64 >> fillInCompiledMethod: obj64 from: obj32 [
	| offset |
	0 to: (heap32 numPointerSlotsOf: obj32) - 1 do:
		[:i|
		 heap64
			storePointerUnchecked: i
			ofObject: obj64
			withValue: (self map32BitOop: (heap32 fetchPointer: i ofObject: obj32))].
	offset := (interpreter64
					initialPCForHeader: (heap64 methodHeaderOf: obj64)
					method: obj64)
			- (interpreter32
					initialPCForHeader: (heap32 methodHeaderOf: obj32)
					method: obj32).
	(interpreter32
			initialPCForHeader: (heap32 methodHeaderOf: obj32)
			method: obj32)
		to: (heap32 numBytesOf: obj32) - 1
		do: [:i|
			heap64
				storeByte: offset + i 
				ofObject: obj64
				withValue: (heap32 fetchByte: i ofObject: obj32)]
]

{ #category : #'bootstrap image' }
SpurBootstrap32to64 >> fillInHeap [
	| heapEnd freeListsObj |
	heapEnd := heap64 freeStart.
	heap64
		nilObject: (map at: heap32 nilObject);
		falseObject: (map at: heap32 falseObject);
		trueObject: (map at: heap32 trueObject);
		specialObjectsOop: (map at: heap32 specialObjectsOop);
		lastHash: heap32 lastHash.
	heap64 segmentManager
		initSegmentForInImageCompilationFrom: heap64 nilObject
		to: heapEnd + heap64 bridgeSize.
	freeListsObj := heap64 objectAfter: heap64 trueObject.
	heap64
		fillObj: freeListsObj numSlots: (heap64 numSlotsOf: freeListsObj) with: 0;
		initializeFreeSpacePostLoad: freeListsObj;
		initializePostBootstrap;
		setEndOfMemory: (heap64 segmentManager bridgeAt: 0) + heap64 baseHeaderSize
]

{ #category : #'bootstrap image' }
SpurBootstrap32to64 >> fillInObjects [
	heap32 allObjectsDo:
		[:obj32|
		(map at: obj32 ifAbsent: nil)
			ifNotNil:
				[:obj64| | format classIndex |
				format := heap32 formatOf: obj32.
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
							ifFalse: [self fillInBitsObject: obj64 from: obj32]]]
			ifNil: [self assert: ((heap32 classIndexOf: obj32)
									between: ClassLargeNegativeIntegerCompactIndex
									and: ClassLargePositiveIntegerCompactIndex)]]
]

{ #category : #'bootstrap image' }
SpurBootstrap32to64 >> fillInPointerObject: obj64 from: obj32 [ 
	0 to: (heap64 numSlotsOf: obj64) - 1 do:
		[:i|
		 heap64
			storePointerUnchecked: i
			ofObject: obj64
			withValue: (self map32BitOop: (heap32 fetchPointer: i ofObject: obj32))]
]

{ #category : #'bootstrap image' }
SpurBootstrap32to64 >> fillInPointerObjectWithPC: obj64 from: obj32 [
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

{ #category : #'bootstrap image' }
SpurBootstrap32to64 >> incrementPCField: fieldIndex ofObject: obj64 for: method32 [
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
SpurBootstrap32to64 >> initMaps [
	map := Dictionary new: heap32 memory size // 32.
	reverseMap := Dictionary new: heap32 memory size // 32
]

{ #category : #'bootstrap image' }
SpurBootstrap32to64 >> map32BitOop: oop32 [
	^map
		at: oop32
		ifAbsent:
			[(heap32 isImmediate: oop32)
				ifTrue:
					[(heap32 isImmediateCharacter: oop32)
						ifTrue: [heap64 characterObjectOf: (heap32 characterValueOf: oop32)]
						ifFalse: [heap64 integerObjectOf: (heap32 integerValueOf: oop32)]]
				ifFalse:
					[| value |
					 self assert: ((heap32 classIndexOf: oop32)
											between: ClassLargeNegativeIntegerCompactIndex
											and: ClassLargePositiveIntegerCompactIndex).
					 interpreter32 initPrimCall.
					 value := heap32 positive64BitValueOf: oop32.
					 self deny: interpreter32 failed.
					 heap64 integerObjectOf: value]]
]

{ #category : #'public access' }
SpurBootstrap32to64 >> on: imageName [
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

{ #category : #snapshot }
SpurBootstrap32to64 >> writeSnapshot: imageFileName headerFlags: headerFlags screenSize: screenSizeInteger [
	heap64
		checkFreeSpace;
		runLeakCheckerForFullGC: true.
	interpreter64
		setImageHeaderFlagsFrom: headerFlags;
		setDisplayForm: nil;
		imageName: imageFileName;
		writeImageFileIO.
	Transcript cr; show: 'Done!'
]
