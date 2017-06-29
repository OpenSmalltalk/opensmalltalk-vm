"
A Spur32BitPreen is a simple image rewriter for 32-bit Spru images that eliminates free space and hence shrinks the preened image.  Use via
	Spur32BitPreen new preenImage: 'spur'
which will produce spur-preen.image and spur-preen.changes from spur.image and spur.changes.

Instance Variables
	imageHeaderFlags:		<Integer>
	map:					<Dictionary>
	newHeap:				<Spur32BitMMLESimulator>
	newInterpreter:			<StackInterpreterSimulatorLSB>
	oldHeap:				<Spur32BitMMLESimulator>
	oldInterpreter:			<StackInterpreterSimulatorLSB>
	reverseMap:			<Dictionary>
	savedWindowSize:		<Integer>

imageHeaderFlags
	- flags word in image header

map
	- map from oops in old image to oops in new image

newHeap
	- the preened heap

newInterpreter
	- the interpreter wrapping the preened heap

oldHeap
	- the heap to be preened

oldInterpreter
	- the interpreter wrapping the heap to be preened

reverseMap
	- map from oops in new image to oops in old image

savedWindowSize
	- screen size word in mage header

"
Class {
	#name : #Spur32BitPreen,
	#superclass : #SimulatorHarness,
	#instVars : [
		'oldHeap',
		'newHeap',
		'map',
		'reverseMap',
		'oldInterpreter',
		'newInterpreter',
		'imageHeaderFlags',
		'savedWindowSize',
		'writeDefaultHeader'
	],
	#pools : [
		'VMObjectIndices'
	],
	#category : #'Cog-Bootstrapping'
}

{ #category : #'bootstrap image' }
Spur32BitPreen >> clone: oldObj [
	| newObj hash |
	newObj := newHeap
				allocateSlots: (oldHeap numSlotsOf: oldObj)
				format: (oldHeap formatOf: oldObj)
				classIndex: (oldHeap classIndexOf: oldObj).
	(hash := oldHeap rawHashBitsOf: oldObj) ~= 0 ifTrue:
		[newHeap setHashBitsOf: newObj to: hash].
	(oldHeap isImmutable: oldObj) ifTrue:
		[newHeap setIsImmutableOf: newObj to: true].
	(oldHeap isPinned: oldObj) ifTrue:
		[newHeap setIsPinnedOf: newObj to: true].
	self deny: (oldHeap isRemembered: oldObj).
	self deny: (oldHeap isMarked: oldObj).
	self deny: (oldHeap isGrey: oldObj).
	reverseMap at: newObj put: oldObj.
	^map at: oldObj put: newObj
]

{ #category : #'bootstrap image' }
Spur32BitPreen >> cloneFreeLists: oldObj [
	| newObj |
	newObj := newHeap
				allocateSlots: newHeap numFreeLists
				format: newHeap wordIndexableFormat
				classIndex: newHeap wordSizeClassIndexPun.
	reverseMap at: newObj put: oldObj.
	^map at: oldObj put: newObj
]

{ #category : #'bootstrap image' }
Spur32BitPreen >> cloneObjects [
	"Clone all normal objects.  Of hidden objects only clone the freeLists object and
	 the classTableRoot and class table pages. In particular, dont clone objStacks.
	 The refs to the objStacks are nilled out in fillInHeap."
	| i freeListsObject |
	i := 0.
	freeListsObject := oldHeap freeListsObject.
	oldHeap allOldSpaceObjectsDo:
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
Spur32BitPreen >> fillInBitsObject: obj64 from: obj32 [
	0 to: (oldHeap numBytesOf: obj32) - 1 do:
		[:i|
		newHeap
			storeByte: i
			ofObject: obj64
			withValue: (oldHeap fetchByte: i ofObject: obj32)]
]

{ #category : #'bootstrap image' }
Spur32BitPreen >> fillInClassTable [
	self fillInPointerObject: (map at: oldHeap classTableRootObj) from: oldHeap classTableRootObj
]

{ #category : #'bootstrap image' }
Spur32BitPreen >> fillInCompiledMethod: newObj from: oldObj [
	"oldInterpreter printOop: oldObj"
	"newInterpreter printOop: newObj"
	0 to: (oldHeap numPointerSlotsOf: oldObj) - 1 do:
		[:i| | oldOop newOop |
		 oldOop := oldHeap fetchPointer: i ofObject: oldObj.
		 newOop := self map32BitOop: oldOop.
		 newHeap
			storePointerUnchecked: i
			ofObject: newObj
			withValue: newOop].
	(oldInterpreter startPCOfMethod: oldObj)
		to: (oldHeap numBytesOf: oldObj) - 1
		do: [:j|
			newHeap
				storeByte: j 
				ofObject: newObj
				withValue: (oldHeap fetchByte: j ofObject: oldObj)]
]

{ #category : #'bootstrap image' }
Spur32BitPreen >> fillInHeap [
	| heapEnd freeListsObj |
	heapEnd := newHeap freeStart.
	newHeap
		nilObject: (map at: oldHeap nilObject);
		falseObject: (map at: oldHeap falseObject);
		trueObject: (map at: oldHeap trueObject);
		specialObjectsOop: (map at: oldHeap specialObjectsOop);
		lastHash: oldHeap lastHash;
		setHiddenRootsObj: (map at: oldHeap classTableRootObj).
	newHeap segmentManager
		initSegmentForInImageCompilationFrom: newHeap nilObject
		to: heapEnd + newHeap bridgeSize.
	freeListsObj := newHeap objectAfter: newHeap trueObject.
	"Nil-out the free lists."
	newHeap
		fillObj: freeListsObj numSlots: (newHeap numSlotsOf: freeListsObj) with: 0;
		initializeFreeSpacePostLoad: freeListsObj;
		initializePostBootstrap;
		setEndOfMemory: (newHeap segmentManager bridgeAt: 0) + newHeap baseHeaderSize
]

{ #category : #'bootstrap image' }
Spur32BitPreen >> fillInObjects [
	"interpreter32 printOop: oldObj"
	| i |
	{oldHeap markStack. oldHeap weaklingStack. oldHeap mournQueue} do:
		[:obj|
		obj ~= oldHeap nilObject ifTrue:
			[map at: obj put: (map at: oldHeap nilObject)]].
	i := 0.
	oldHeap allObjectsDo:
		[:oldObj|
		(i := i + 1) >= 10000 ifTrue:
			[Transcript nextPut: $.; flush. i := 0].
		(map at: oldObj ifAbsent: nil)
			ifNotNil:
				[:newObj| | format |
				(newHeap numSlotsOf: newObj) > 0 ifTrue: "filter-out filtered objStack pages"
					[format := oldHeap formatOf: oldObj.
					 (newHeap isPointersFormat: format)
						ifTrue:
							[self fillInPointerObject: newObj from: oldObj]
						ifFalse:
							[(newHeap isCompiledMethodFormat: format)
								ifTrue: [self fillInCompiledMethod: newObj from: oldObj]
								ifFalse: [self fillInBitsObject: newObj from: oldObj]]]]
			ifNil: [self assert: (self isUnmappedObject: oldObj)]]
]

{ #category : #'bootstrap image' }
Spur32BitPreen >> fillInPointerObject: newObj from: oldObj [ 
	0 to: (oldHeap numSlotsOf: oldObj) - 1 do:
		[:i|
		 newHeap
			storePointerUnchecked: i
			ofObject: newObj
			withValue: (self map32BitOop: (oldHeap fetchPointer: i ofObject: oldObj))]
]

{ #category : #'bootstrap image' }
Spur32BitPreen >> incrementPCField: fieldIndex ofObject: obj64 for: method32 [
	| value nLits |
	value := newHeap fetchPointer: fieldIndex ofObject: obj64.
	(newHeap isIntegerObject: value)
		ifTrue:
			[nLits := oldHeap literalCountOf: method32.
			 newHeap
				storePointerUnchecked: fieldIndex
				ofObject: obj64
				withValue: (newHeap integerObjectOf: nLits + LiteralStart * 4 + (newHeap integerValueOf: value))]
		ifFalse:
			[self assert: (reverseMap at: value) = oldHeap nilObject]
]

{ #category : #'initialize-release' }
Spur32BitPreen >> initMaps [
	map := Dictionary new: oldHeap memory size // 32.
	reverseMap := Dictionary new: oldHeap memory size // 32
]

{ #category : #'bootstrap image' }
Spur32BitPreen >> isUnmappedObject: obj32 [
	"Answer if obj32 is an object that is not cloned by the bootstrap."
	^obj32 = oldHeap freeListsObject
	  or: [(oldHeap isValidObjStackPage: obj32)]
]

{ #category : #'bootstrap image' }
Spur32BitPreen >> map32BitOop: obj32 [
	"oldInterpreter printOop: obj32"
	^map
		at: obj32
		ifAbsent:
			[(oldHeap isImmediateCharacter: obj32)
				ifTrue: [newHeap characterObjectOf: (oldHeap characterValueOf: obj32)]
				ifFalse: [newHeap integerObjectOf: (oldHeap integerValueOf: obj32)]]
]

{ #category : #'public access' }
Spur32BitPreen >> on: imageName [
	(oldInterpreter := StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager))
		openOn: imageName extraMemory: 0.
	oldHeap := oldInterpreter objectMemory.
	imageHeaderFlags := oldInterpreter getImageHeaderFlags.
	savedWindowSize ifNil: [savedWindowSize := oldInterpreter savedWindowSize].
	newInterpreter := StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager).
	newHeap := newInterpreter objectMemory.
	newHeap
		allocateMemoryOfSize: oldHeap oldSpaceSize
		newSpaceSize: 8 * 1024 * 1024
		stackSize: 16 * 1024
		codeSize: 0.
	newHeap bootstrapping: true.
	self initMaps
]

{ #category : #'public access' }
Spur32BitPreen >> preenImage [
	self cloneObjects.
	self fillInObjects.
	self fillInClassTable.
	self fillInHeap.
	self reportSizes
]

{ #category : #'public access' }
Spur32BitPreen >> preenImage: imageName [
	(Smalltalk classNamed: #FileReference) ifNotNil:
		[^self preenImageUsingFileReference: imageName].
	(Smalltalk classNamed: #FileDirectory) ifNotNil:
		[^self preenImageUsingFileDirectory: imageName].
	self error: 'at a loss as to what file system support to use'
]

{ #category : #'public access' }
Spur32BitPreen >> preenImageUsingFileDirectory: imageName [
	| dirName baseName dir |
	dirName := FileDirectory dirPathFor: imageName.
	baseName := (imageName endsWith: '.image')
					ifTrue: [FileDirectory baseNameFor: imageName]
					ifFalse: [FileDirectory localNameFor: imageName].
	dir := dirName isEmpty ifTrue: [FileDirectory default] ifFalse: [FileDirectory default on: dirName].
	self on: (dir fullNameFor: baseName, '.image').
	[self preenImage]
		on: Halt
		do: [:ex|
			"suppress halts from the usual suspects (development time halts)"
			(#(fullGC compactImage) includes: ex signalerContext sender selector)
				ifTrue: [ex resume]
				ifFalse: [ex pass]].
	self writeSnapshot: (dir fullNameFor: baseName, '-preen.image')
		headerFlags: imageHeaderFlags
		screenSize: savedWindowSize.
	(dir fileExists: baseName, '.changes')
		ifTrue:
			[dir deleteFileNamed: baseName, '-preen.changes';
				copyFileNamed: baseName, '.changes' toFileNamed: baseName, '-preen.changes']
		ifFalse:
			[Transcript cr; show: 'could not find ', baseName, '.changes']
]

{ #category : #'bootstrap image' }
Spur32BitPreen >> reportSizes [
	| change oldHeapSize newHeapSize |
	oldHeapSize := oldHeap oldSpaceSize.
	newHeap segmentManager computeTotalHeapSizeIncludingBridges. "To avoid assert fail"
	newHeapSize := newHeap oldSpaceSize.
	change := newHeapSize - oldHeapSize / oldHeapSize.
	Transcript
		nextPutAll: 'done.'; cr;
		nextPutAll: 'old heap size: '; nextPutAll: oldHeapSize asStringWithCommas; tab;
		nextPutAll: 'initial new heap size: '; nextPutAll: newHeapSize asStringWithCommas; cr;
		nextPutAll: 'change: '; print: change * 100.0 maxDecimalPlaces: 2; nextPut: $%; cr;
		flush.
	newHeapSize := newHeap endOfMemory
					- newHeap scavenger eden limit
					- newHeap totalFreeListBytes.
	change := newHeapSize - oldHeapSize / oldHeapSize.
	Transcript
		nextPutAll: 'final new heap size: '; nextPutAll: newHeapSize asStringWithCommas; tab;
		nextPutAll: 'change: '; print: change * 100.0 maxDecimalPlaces: 2; nextPut: $%; cr;
		flush
]

{ #category : #'public access' }
Spur32BitPreen >> savedWindowSize: aPointOrInteger [
	savedWindowSize := aPointOrInteger isInteger
							ifTrue: [aPointOrInteger]
							ifFalse: [(aPointOrInteger x min: 65535) << 16 + (aPointOrInteger y min: 65535)]
]

{ #category : #'bootstrap image' }
Spur32BitPreen >> shouldClone: obj32 [
	^(oldHeap isValidObjStackPage: obj32) not
]

{ #category : #'public access' }
Spur32BitPreen >> writeDefaultHeader: aBoolean [
	writeDefaultHeader := aBoolean
]

{ #category : #snapshot }
Spur32BitPreen >> writeSnapshot: imageFileName headerFlags: headerFlags screenSize: screenSizeInteger [
	newHeap
		checkFreeSpace;
		runLeakCheckerForFullGC.
	writeDefaultHeader == true ifTrue:
		[newInterpreter
			desiredEdenBytes: 0;
			desiredNumStackPages: 0;
			setDesiredCogCodeSize: 0;
			setMaxExtSemSizeTo: 0].
	newInterpreter
		setImageHeaderFlagsFrom: headerFlags;
		setDisplayForm: nil;
		setSavedWindowSize: savedWindowSize;
		imageName: imageFileName;
		writeImageFileIO.
	Transcript cr; show: 'Done!'
]
